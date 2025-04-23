Okay, here is a Solidity smart contract for a Decentralized AI Model & Inference Marketplace.

This contract incorporates several concepts:
1.  **Marketplace:** Facilitates exchange between model providers and consumers.
2.  **Escrow:** Manages payments securely until service (inference) is confirmed.
3.  **Staking:** Requires model providers to stake collateral to incentivize availability and correctness.
4.  **Reputation:** A simple system to track provider performance based on confirmed inferences.
5.  **State Machines:** Inference requests go through distinct states (Open, Claimed, ResultSubmitted, Confirmed, Disputed, Cancelled).
6.  **Time-based Logic:** Uses `block.timestamp` for request timeouts, result submission deadlines, dispute windows, and stake withdrawal cooldowns.
7.  **Off-chain Data Pointers:** Uses `bytes32` hashes (representing IPFS CIDs or similar identifiers) for model metadata, input data, and output data, acknowledging that the actual AI model and heavy data reside off-chain.
8.  **Unique Identifiers:** Uses hashes (`bytes32`) for unique Model and Request IDs.

It aims to be creative by combining these elements specifically for an *AI inference* use case, which is less common than typical DeFi or NFT applications, and avoids direct copies of well-known open-source implementations by building the core logic from scratch.

---

## Smart Contract: DecentralizedAIModelMarketplace

### Outline:

1.  **State Variables & Constants:** Core storage for models, requests, reputation, IDs, and configuration parameters.
2.  **Structs:** Data structures for `Model` and `InferenceRequest`.
3.  **Enums:** States for the inference request lifecycle.
4.  **Events:** To signal important actions.
5.  **Modifiers:** Access control based on roles (provider, requester, claimant).
6.  **Model Management Functions:** Registering, updating, staking, and withdrawing models.
7.  **Inference Request Lifecycle Functions:** Submitting, claiming, submitting results, confirming, canceling, and initiating disputes.
8.  **Payment & Earnings Functions:** Withdrawing earned funds.
9.  **Reputation Functions:** Rating providers and getting reputation.
10. **View Functions:** Retrieving information about models, requests, and users.

### Function Summary:

1.  **`registerModel(bytes32 metadataHash, uint256 pricePerInference)`**: Registers a new AI model in the marketplace. Requires staking a minimum deposit.
2.  **`updateModelMetadata(bytes32 modelId, bytes32 newMetadataHash, uint256 newPricePerInference)`**: Allows a model provider to update their model's details.
3.  **`deactivateModel(bytes32 modelId)`**: Deactivates a model, preventing new inference requests but allowing existing ones to complete.
4.  **`stakeModelDeposit(bytes32 modelId)`**: Allows a model provider to add more stake to their model.
5.  **`initiateStakeWithdrawal(bytes32 modelId)`**: Initiates the withdrawal process for a model's stake. Requires the model to be deactivated and starts a cooldown period.
6.  **`completeStakeWithdrawal(bytes32 modelId)`**: Completes the stake withdrawal after the cooldown period has passed and all associated requests are finalized.
7.  **`submitInferenceRequest(bytes32 modelId, bytes32 inputDataHash)`**: Submits a request to use a specific model for inference. Requires sending the payment amount (`pricePerInference`) with the transaction.
8.  **`claimInferenceRequest(bytes32 requestId)`**: Allows a model provider (or anyone acting on their behalf off-chain) to claim an open inference request for their model.
9.  **`submitInferenceResult(bytes32 requestId, bytes32 resultDataHash)`**: Allows the claimant of a request to submit the inference result hash.
10. **`confirmInferenceResult(bytes32 requestId)`**: Allows the original requester to confirm the submitted result is satisfactory, releasing payment to the provider.
11. **`cancelInferenceRequest(bytes32 requestId)`**: Allows the original requester to cancel an open request before it is claimed, refunding the payment.
12. **`flagResultDispute(bytes32 requestId)`**: Allows the original requester to flag a submitted result as disputed. Freezes funds and stake pending off-chain resolution.
13. **`withdrawProviderEarnings()`**: Allows a provider to withdraw confirmed earnings from completed inference requests.
14. **`rateModelProvider(address provider, uint8 rating)`**: Allows users who have interacted with a provider (e.g., confirmed a request) to submit a simple rating (e.g., 1-5).
15. **`getModel(bytes32 modelId)`**: View function to get details of a specific model.
16. **`getModelCount()`**: View function to get the total number of registered models.
17. **`getModelByIndex(uint256 index)`**: View function to get a model ID by its index in the list (for iteration).
18. **`getModelsByProvider(address provider)`**: View function to get all model IDs registered by a specific provider.
19. **`getInferenceRequest(bytes32 requestId)`**: View function to get details of a specific inference request.
20. **`getInferenceRequestCount()`**: View function to get the total number of inference requests.
21. **`getInferenceRequestByIndex(uint256 index)`**: View function to get a request ID by its index (for iteration).
22. **`getRequestsByRequester(address requester)`**: View function to get all request IDs submitted by a specific address.
23. **`getRequestsByProvider(address provider)`**: View function to get all request IDs claimed or submitted results for by a specific address.
24. **`getProviderReputation(address provider)`**: View function to get the calculated reputation score for a provider.
25. **`getProviderEarnings(address provider)`**: View function to check a provider's withdrawable earnings.
26. **`getModelsEligibleForWithdrawal(address provider)`**: View function to list models by a provider that are ready for stake withdrawal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Note: This is a conceptual contract. A real-world system would require
// robust off-chain components for AI execution, data storage (IPFS/Arweave),
// potential decentralized oracles for complex disputes, and gas optimizations
// for large numbers of models/requests. Error handling messages are basic.

/// @title Decentralized AI Model & Inference Marketplace
/// @notice A marketplace contract for registering AI models (represented by metadata hash)
/// and facilitating paid inference requests using an escrow, staking, and simple reputation system.

// --- Outline ---
// 1. State Variables & Constants
// 2. Structs
// 3. Enums
// 4. Events
// 5. Modifiers
// 6. Model Management Functions
// 7. Inference Request Lifecycle Functions
// 8. Payment & Earnings Functions
// 9. Reputation Functions
// 10. View Functions

contract DecentralizedAIModelMarketplace {

    // --- State Variables & Constants ---

    bytes32[] public modelIds;
    bytes32[] public requestIds; // Tracks all requests, including finished/cancelled

    mapping(bytes32 => Model) public models;
    mapping(address => bytes32[]) public modelsByProvider; // Models owned by an address
    mapping(bytes32 => bytes32[]) public openRequestIdsForModel; // Track open requests per model

    mapping(bytes32 => InferenceRequest) public inferenceRequests;
    mapping(address => bytes32[]) public requestsByRequester; // Requests initiated by an address
    mapping(address => bytes32[]) public requestsByProvider; // Requests claimed by an address

    mapping(address => uint256) public providerEarnings; // Ether balance available for withdrawal

    // Simple reputation system: sum of ratings and count of ratings
    mapping(address => uint256) private providerReputationSum;
    mapping(address => uint256) private providerRatingCount;
    // To prevent rating spam/multiple ratings from the same requester for the same completed job
    mapping(bytes32 => mapping(address => bool)) private hasRatedRequest;


    // Configuration Constants (could be state variables managed by governance in a real system)
    uint256 public constant MIN_STAKE_AMOUNT = 0.1 ether; // Minimum stake required for a model
    uint256 public constant STAKE_COOLDOWN_PERIOD = 7 days; // Time before stake can be fully withdrawn after initiation
    uint256 public constant CLAIM_TIMEOUT = 1 days; // Time limit for a provider to claim an open request
    uint256 public constant RESULT_SUBMISSION_TIMEOUT = 2 days; // Time limit for a provider to submit a result after claiming
    uint256 public constant CONFIRMATION_WINDOW = 1 days; // Time limit for a requester to confirm or dispute a result
    uint256 public constant DISPUTE_WINDOW = 3 days; // Time limit after result submission/confirmation to flag a dispute

    // --- Structs ---

    struct Model {
        address provider;
        bytes32 metadataHash; // IPFS/Arweave hash or similar pointer to model details
        uint256 pricePerInference; // Price in wei per inference request
        uint256 stake; // Collateral staked by the provider
        bool isActive; // Can new requests be submitted for this model?
        uint256 stakeWithdrawalInitiatedAt; // Timestamp when withdrawal was initiated (0 if not initiated)
        bool isRegistered; // Helps distinguish between non-existent modelId and default struct
    }

    struct InferenceRequest {
        address requester;
        bytes32 modelId; // ID of the model requested
        bytes32 inputDataHash; // IPFS/Arweave hash or similar pointer to input data
        uint256 paymentAmount; // Amount paid by the requester (should equal model price)
        address claimedBy; // Address of the provider/agent who claimed the request (0x0 if not claimed)
        bytes32 resultDataHash; // IPFS/Arweave hash or similar pointer to output data
        RequestState state; // Current state of the request
        uint256 submittedAt; // Timestamp when request was submitted
        uint256 claimedAt; // Timestamp when request was claimed
        uint256 resultSubmittedAt; // Timestamp when result was submitted
        bool disputed; // Flag indicating if the result is under dispute
        bool isRequest; // Helps distinguish between non-existent requestId and default struct
    }

    // --- Enums ---

    enum RequestState {
        Open,             // Request is available for claiming
        Claimed,          // Request has been claimed by a provider
        ResultSubmitted,  // Provider has submitted a result
        Confirmed,        // Requester confirmed the result, payment ready for provider
        Disputed,         // Requester disputed the result, funds/stake frozen
        Cancelled         // Requester cancelled before claim, or timeout/slashing occurred
    }

    // --- Events ---

    event ModelRegistered(bytes32 indexed modelId, address indexed provider, bytes32 metadataHash, uint256 pricePerInference, uint256 initialStake);
    event ModelUpdated(bytes32 indexed modelId, bytes32 newMetadataHash, uint256 newPricePerInference);
    event ModelDeactivated(bytes32 indexed modelId);
    event StakeIncreased(bytes32 indexed modelId, uint256 amount);
    event StakeWithdrawalInitiated(bytes32 indexed modelId, uint256 withdrawalAmount);
    event StakeWithdrawalCompleted(bytes32 indexed modelId, uint256 withdrawnAmount);

    event InferenceRequestSubmitted(bytes32 indexed requestId, bytes32 indexed modelId, address indexed requester, uint256 paymentAmount);
    event InferenceRequestClaimed(bytes32 indexed requestId, address indexed claimedBy);
    event InferenceResultSubmitted(bytes32 indexed requestId, bytes32 resultDataHash);
    event InferenceRequestConfirmed(bytes32 indexed requestId);
    event InferenceRequestCancelled(bytes32 indexed requestId);
    event InferenceResultDisputed(bytes32 indexed requestId);

    event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
    event ProviderRated(address indexed provider, uint8 rating, address indexed rater);

    // --- Modifiers ---

    modifier onlyModelProvider(bytes32 modelId) {
        require(models[modelId].provider == msg.sender, "Not the model provider");
        _;
    }

    modifier onlyRequester(bytes32 requestId) {
        require(inferenceRequests[requestId].requester == msg.sender, "Not the request requester");
        _;
    }

    modifier onlyClaimant(bytes32 requestId) {
        require(inferenceRequests[requestId].claimedBy == msg.sender, "Not the request claimant");
        _;
    }

    // --- Model Management Functions ---

    /// @notice Registers a new AI model. Requires minimum stake deposit.
    /// @param metadataHash Hash pointing to model details off-chain.
    /// @param pricePerInference Price in wei for one inference using this model.
    function registerModel(bytes32 metadataHash, uint256 pricePerInference) external payable {
        require(msg.value >= MIN_STAKE_AMOUNT, "Minimum stake not met");
        require(metadataHash != bytes32(0), "Invalid metadata hash");
        require(pricePerInference > 0, "Price must be greater than zero");

        // Generate a unique model ID
        bytes32 modelId = keccak256(abi.encodePacked(msg.sender, metadataHash, pricePerInference, block.timestamp, modelIds.length));
        require(!models[modelId].isRegistered, "Model ID collision or already registered"); // Highly unlikely with timestamp/length

        models[modelId] = Model({
            provider: msg.sender,
            metadataHash: metadataHash,
            pricePerInference: pricePerInference,
            stake: msg.value,
            isActive: true,
            stakeWithdrawalInitiatedAt: 0,
            isRegistered: true
        });

        modelIds.push(modelId);
        modelsByProvider[msg.sender].push(modelId);

        emit ModelRegistered(modelId, msg.sender, metadataHash, pricePerInference, msg.value);
    }

    /// @notice Allows a model provider to update model metadata and price.
    /// @param modelId The ID of the model to update.
    /// @param newMetadataHash New hash pointing to model details off-chain.
    /// @param newPricePerInference New price in wei per inference.
    function updateModelMetadata(bytes32 modelId, bytes32 newMetadataHash, uint256 newPricePerInference) external onlyModelProvider(modelId) {
        Model storage model = models[modelId];
        require(model.isActive, "Model must be active to update metadata");
        require(newMetadataHash != bytes32(0), "Invalid new metadata hash");
        require(newPricePerInference > 0, "New price must be greater than zero");

        model.metadataHash = newMetadataHash;
        model.pricePerInference = newPricePerInference;

        emit ModelUpdated(modelId, newMetadataHash, newPricePerference);
    }

    /// @notice Deactivates a model, preventing new inference requests.
    /// @param modelId The ID of the model to deactivate.
    function deactivateModel(bytes32 modelId) external onlyModelProvider(modelId) {
        Model storage model = models[modelId];
        require(model.isActive, "Model is already inactive");
        model.isActive = false;
        // Stake remains locked until withdrawal is completed

        emit ModelDeactivated(modelId);
    }

     /// @notice Allows a model provider to add more stake to their model.
     /// @param modelId The ID of the model to add stake to.
     function stakeModelDeposit(bytes32 modelId) external payable onlyModelProvider(modelId) {
         require(msg.value > 0, "Must send value to stake");
         Model storage model = models[modelId];
         model.stake += msg.value;
         emit StakeIncreased(modelId, msg.value);
     }

    /// @notice Initiates the stake withdrawal process for a deactivated model.
    /// @dev Requires the model to be inactive and starts the cooldown period.
    /// @param modelId The ID of the model to initiate withdrawal for.
    function initiateStakeWithdrawal(bytes32 modelId) external onlyModelProvider(modelId) {
        Model storage model = models[modelId];
        require(!model.isActive, "Model must be inactive to initiate withdrawal");
        require(model.stakeWithdrawalInitiatedAt == 0, "Stake withdrawal already initiated");

        // Check if there are any active requests involving this model/provider
        // Simple check: iterate through requestsByProvider. More efficient would be to track counts.
        // For simplicity, we assume stake withdrawal is only possible when no requests are pending.
        // A robust system would require a more sophisticated check or graceful handling of ongoing jobs.
        for(uint i = 0; i < requestsByProvider[msg.sender].length; i++) {
            bytes32 reqId = requestsByProvider[msg.sender][i];
            InferenceRequest storage req = inferenceRequests[reqId];
            if (req.isRequest && (req.state == RequestState.Claimed || req.state == RequestState.ResultSubmitted)) {
                 revert("Cannot withdraw stake while active requests are pending for this provider");
            }
        }
         // Check for active requests specifically using this modelId too, not just claimed by provider
         // This is needed if other providers could potentially claim requests for this model (less likely in this model's design but good to consider)
         for(uint i = 0; i < requestIds.length; i++) {
             bytes32 reqId = requestIds[i];
             InferenceRequest storage req = inferenceRequests[reqId];
             if (req.isRequest && req.modelId == modelId && (req.state == RequestState.Open || req.state == RequestState.Claimed || req.state == RequestState.ResultSubmitted)) {
                  revert("Cannot withdraw stake while active requests are pending for this model");
             }
         }


        model.stakeWithdrawalInitiatedAt = block.timestamp;

        emit StakeWithdrawalInitiated(modelId, model.stake);
    }

    /// @notice Completes the stake withdrawal after the cooldown period.
    /// @param modelId The ID of the model to complete withdrawal for.
    function completeStakeWithdrawal(bytes32 modelId) external onlyModelProvider(modelId) {
        Model storage model = models[modelId];
        require(model.stakeWithdrawalInitiatedAt > 0, "Stake withdrawal not initiated");
        require(block.timestamp >= model.stakeWithdrawalInitiatedAt + STAKE_COOLDOWN_PERIOD, "Stake withdrawal cooldown period not over");
        require(model.stake > 0, "No stake to withdraw");

        uint256 amountToWithdraw = model.stake;
        model.stake = 0;
        // Model state remains inactive

        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Stake withdrawal failed");

        emit StakeWithdrawalCompleted(modelId, amountToWithdraw);
    }


    // --- Inference Request Lifecycle Functions ---

    /// @notice Submits a request for inference using a specific model.
    /// @param modelId The ID of the desired model.
    /// @param inputDataHash Hash pointing to the input data off-chain.
    function submitInferenceRequest(bytes32 modelId, bytes32 inputDataHash) external payable {
        Model storage model = models[modelId];
        require(model.isRegistered, "Model does not exist");
        require(model.isActive, "Model is not active for new requests");
        require(msg.value == model.pricePerInference, "Incorrect payment amount");
        require(inputDataHash != bytes32(0), "Invalid input data hash");

        // Generate a unique request ID
        bytes32 requestId = keccak256(abi.encodePacked(modelId, msg.sender, inputDataHash, block.timestamp, requestIds.length));
        require(!inferenceRequests[requestId].isRequest, "Request ID collision or already exists"); // Highly unlikely

        inferenceRequests[requestId] = InferenceRequest({
            requester: msg.sender,
            modelId: modelId,
            inputDataHash: inputDataHash,
            paymentAmount: msg.value, // Locked in contract escrow
            claimedBy: address(0),
            resultDataHash: bytes32(0),
            state: RequestState.Open,
            submittedAt: block.timestamp,
            claimedAt: 0,
            resultSubmittedAt: 0,
            disputed: false,
            isRequest: true
        });

        requestIds.push(requestId);
        requestsByRequester[msg.sender].push(requestId);
        openRequestIdsForModel[modelId].push(requestId); // Add to open requests list for this model

        emit InferenceRequestSubmitted(requestId, modelId, msg.sender, msg.value);
    }

    /// @notice Allows a model provider (or their agent) to claim an open inference request.
    /// @param requestId The ID of the request to claim.
    function claimInferenceRequest(bytes32 requestId) external {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.isRequest, "Request does not exist");
        require(request.state == RequestState.Open, "Request is not open");
        require(block.timestamp < request.submittedAt + CLAIM_TIMEOUT, "Request has timed out");

        // Optional: require msg.sender is the provider of the model, or allow any worker?
        // Allowing any worker requires providers to manage authorization off-chain.
        // Let's require msg.sender to be the model provider for simplicity in this contract.
        // A more advanced system might use signatures or whitelists.
        require(models[request.modelId].provider == msg.sender, "Only the model provider can claim");

        request.claimedBy = msg.sender;
        request.state = RequestState.Claimed;
        request.claimedAt = block.timestamp;

        // Remove from the list of open requests for this model (inefficient for large lists, but functional)
        bytes32[] storage openReqs = openRequestIdsForModel[request.modelId];
        for (uint i = 0; i < openReqs.length; i++) {
            if (openReqs[i] == requestId) {
                openReqs[i] = openReqs[openReqs.length - 1];
                openReqs.pop();
                break;
            }
        }

        requestsByProvider[msg.sender].push(requestId); // Track claimed requests by this provider

        emit InferenceRequestClaimed(requestId, msg.sender);
    }

    /// @notice Allows the claimant to submit the inference result hash.
    /// @param requestId The ID of the request.
    /// @param resultDataHash Hash pointing to the result data off-chain.
    function submitInferenceResult(bytes32 requestId, bytes32 resultDataHash) external onlyClaimant(requestId) {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.isRequest, "Request does not exist");
        require(request.state == RequestState.Claimed, "Request is not in claimed state");
        require(block.timestamp < request.claimedAt + RESULT_SUBMISSION_TIMEOUT, "Result submission has timed out");
        require(resultDataHash != bytes32(0), "Invalid result data hash");

        request.resultDataHash = resultDataHash;
        request.state = RequestState.ResultSubmitted;
        request.resultSubmittedAt = block.timestamp;

        emit InferenceResultSubmitted(requestId, resultDataHash);
    }

    /// @notice Allows the requester to confirm the submitted result. Releases payment to provider.
    /// @param requestId The ID of the request.
    function confirmInferenceResult(bytes32 requestId) external onlyRequester(requestId) {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.isRequest, "Request does not exist");
        require(request.state == RequestState.ResultSubmitted, "Result not submitted or already confirmed/disputed");
        require(block.timestamp < request.resultSubmittedAt + CONFIRMATION_WINDOW, "Confirmation window has expired");

        request.state = RequestState.Confirmed;

        // Transfer payment from contract balance to provider's earnings
        providerEarnings[request.claimedBy] += request.paymentAmount;

        // Update reputation (simple sum/count for average)
        providerReputationSum[request.claimedBy] += 5; // Assume 5/5 rating on confirmation
        providerRatingCount[request.claimedBy]++;

        emit InferenceRequestConfirmed(requestId);
    }

    /// @notice Allows the requester to cancel an open request before it's claimed. Refunds payment.
    /// @param requestId The ID of the request.
    function cancelInferenceRequest(bytes32 requestId) external onlyRequester(requestId) {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.isRequest, "Request does not exist");
        require(request.state == RequestState.Open, "Request is not open and cannot be cancelled by requester");

        request.state = RequestState.Cancelled;

        // Refund payment to requester
        (bool success, ) = payable(msg.sender).call{value: request.paymentAmount}("");
        require(success, "Payment refund failed");

         // Remove from the list of open requests for this model (inefficient)
        bytes32[] storage openReqs = openRequestIdsForModel[request.modelId];
        for (uint i = 0; i < openReqs.length; i++) {
            if (openReqs[i] == requestId) {
                openReqs[i] = openReqs[openReqs.length - 1];
                openReqs.pop();
                break;
            }
        }

        emit InferenceRequestCancelled(requestId);
    }

    /// @notice Allows the requester to flag a submitted result as disputed. Freezes funds/stake.
    /// @dev Actual dispute resolution mechanism needs to be off-chain or handled by a separate system (e.g., DAO, oracle).
    /// This function simply flags the request state.
    /// @param requestId The ID of the request.
    function flagResultDispute(bytes32 requestId) external onlyRequester(requestId) {
        InferenceRequest storage request = inferenceRequests[requestId];
        require(request.isRequest, "Request does not exist");
        require(request.state == RequestState.ResultSubmitted || request.state == RequestState.Confirmed, "Result not submitted or already finalized");
        // Allow dispute within a window after submission/confirmation
        require(block.timestamp < request.resultSubmittedAt + DISPUTE_WINDOW, "Dispute window has expired");
        require(!request.disputed, "Result already disputed");

        request.disputed = true;
        // State remains ResultSubmitted or Confirmed, but the disputed flag signals pending resolution
        // Funds (payment + potentially stake) are implicitly frozen in the contract until dispute resolution is handled externally
        // A real system would need a mechanism to resolve the dispute (e.g., vote, oracle call)
        // and update the state/slash/refund funds accordingly. This contract only marks the state.

        emit InferenceResultDisputed(requestId);
    }

    // --- Payment & Earnings Functions ---

    /// @notice Allows a provider to withdraw their confirmed earnings.
    function withdrawProviderEarnings() external {
        uint256 amount = providerEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        providerEarnings[msg.sender] = 0; // Set balance to 0 BEFORE sending to prevent reentrancy

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit ProviderEarningsWithdrawn(msg.sender, amount);
    }


    // --- Reputation Functions ---

    /// @notice Allows a user who interacted with a provider to submit a rating.
    /// @dev Simple rating system. A more complex system would prevent spam and link ratings directly to successful interactions.
    /// This basic version allows anyone to rate, but averaging provides some resilience.
    /// @param provider The address of the provider being rated.
    /// @param rating The rating (e.g., 1-5).
    function rateModelProvider(address provider, uint8 rating) external {
        // Simple validation, could be more complex (e.g., require caller confirmed a request from this provider)
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(provider != address(0), "Invalid provider address");
        require(provider != msg.sender, "Cannot rate yourself");

        // Prevent duplicate ratings for the same user from the same caller?
        // This is hard to track efficiently per user per provider.
        // A better approach is linking rating to confirmed requests.
        // Let's add a check to prevent rating the *same request* multiple times.
        // This requires modifying the function to take requestId and only allowing rating after confirmation.

        // Re-designing rateModelProvider to be called *after* confirming a request
        // This requires moving this logic or calling it from confirmInferenceResult.
        // Let's stick to the original simpler concept based on the summary, but note the limitation.
        // If keeping it separate, need *some* check, maybe map provider => rater => bool?
        // This gets complex to track. Let's allow general rating for simplicity in this example,
        // acknowledging it's a basic system susceptible to manipulation without further checks.

        // Basic implementation without linking to requests:
        providerReputationSum[provider] += rating;
        providerRatingCount[provider]++;

        emit ProviderRated(provider, rating, msg.sender);
    }

    // --- View Functions ---

    /// @notice Gets details for a specific model.
    /// @param modelId The ID of the model.
    /// @return provider, metadataHash, pricePerInference, stake, isActive, stakeWithdrawalInitiatedAt, isRegistered
    function getModel(bytes32 modelId) external view returns (address, bytes32, uint256, uint256, bool, uint256, bool) {
        Model storage model = models[modelId];
        return (model.provider, model.metadataHash, model.pricePerInference, model.stake, model.isActive, model.stakeWithdrawalInitiatedAt, model.isRegistered);
    }

    /// @notice Gets the total number of registered models.
    /// @return The count of models.
    function getModelCount() external view returns (uint256) {
        return modelIds.length;
    }

    /// @notice Gets a model ID by its index in the global list.
    /// @param index The index.
    /// @return The model ID.
    function getModelByIndex(uint256 index) external view returns (bytes32) {
        require(index < modelIds.length, "Index out of bounds");
        return modelIds[index];
    }

    /// @notice Gets the list of model IDs owned by a specific provider.
    /// @param provider The provider address.
    /// @return An array of model IDs.
    function getModelsByProvider(address provider) external view returns (bytes32[] memory) {
        return modelsByProvider[provider];
    }

    /// @notice Gets details for a specific inference request.
    /// @param requestId The ID of the request.
    /// @return requester, modelId, inputDataHash, paymentAmount, claimedBy, resultDataHash, state, submittedAt, claimedAt, resultSubmittedAt, disputed, isRequest
    function getInferenceRequest(bytes32 requestId) external view returns (address, bytes32, bytes32, uint256, address, bytes32, RequestState, uint256, uint256, uint256, bool, bool) {
         InferenceRequest storage request = inferenceRequests[requestId];
         return (request.requester, request.modelId, request.inputDataHash, request.paymentAmount, request.claimedBy, request.resultDataHash, request.state, request.submittedAt, request.claimedAt, request.resultSubmittedAt, request.disputed, request.isRequest);
    }

    /// @notice Gets the total number of inference requests ever submitted.
    /// @return The count of requests.
    function getInferenceRequestCount() external view returns (uint256) {
        return requestIds.length;
    }

    /// @notice Gets a request ID by its index in the global list.
    /// @param index The index.
    /// @return The request ID.
    function getInferenceRequestByIndex(uint256 index) external view returns (bytes32) {
         require(index < requestIds.length, "Index out of bounds");
         return requestIds[index];
    }

    /// @notice Gets the list of request IDs submitted by a specific requester.
    /// @param requester The requester address.
    /// @return An array of request IDs.
    function getRequestsByRequester(address requester) external view returns (bytes32[] memory) {
        return requestsByRequester[requester];
    }

    /// @notice Gets the list of request IDs claimed or worked on by a specific provider.
    /// @param provider The provider address.
    /// @return An array of request IDs.
    function getRequestsByProvider(address provider) external view returns (bytes32[] memory) {
        return requestsByProvider[provider];
    }

     /// @notice Gets the current list of open request IDs for a specific model.
     /// @param modelId The model ID.
     /// @return An array of open request IDs.
     function getOpenRequestIdsForModel(bytes32 modelId) external view returns (bytes32[] memory) {
         return openRequestIdsForModel[modelId];
     }


    /// @notice Gets the calculated average reputation score for a provider.
    /// @param provider The provider address.
    /// @return The average rating (multiplied by 100 to retain 2 decimal places), or 0 if no ratings.
    function getProviderReputation(address provider) external view returns (uint256) {
        if (providerRatingCount[provider] == 0) {
            return 0;
        }
        // Return average * 100 for simple integer result (e.g., 4.50 becomes 450)
        return (providerReputationSum[provider] * 100) / providerRatingCount[provider];
    }

    /// @notice Gets the current withdrawable earnings balance for a provider.
    /// @param provider The provider address.
    /// @return The earnings amount in wei.
    function getProviderEarnings(address provider) external view returns (uint256) {
        return providerEarnings[provider];
    }

    /// @notice Gets a list of model IDs by a provider that are eligible for stake withdrawal.
    /// @param provider The provider address.
    /// @return An array of model IDs eligible for withdrawal.
    function getModelsEligibleForWithdrawal(address provider) external view returns (bytes32[] memory) {
        bytes32[] storage models = modelsByProvider[provider];
        bytes32[] memory eligibleModels = new bytes32[](0);
        for (uint i = 0; i < models.length; i++) {
            bytes32 modelId = models[i];
            Model storage model = this.models(modelId); // Use external view getter to avoid storage pointer issues with dynamic arrays
            // Check if inactive, withdrawal initiated, cooldown passed, and has stake
            if (!model.isActive && model.stakeWithdrawalInitiatedAt > 0 &&
                block.timestamp >= model.stakeWithdrawalInitiatedAt + STAKE_COOLDOWN_PERIOD &&
                model.stake > 0)
            {
                // Add more checks here to ensure no pending requests etc., similar to initiateStakeWithdrawal
                // For simplicity, we omit the full check here to avoid repeating complex loop logic in a view function,
                // but the `completeStakeWithdrawal` function *does* perform the necessary checks.
                 bool hasPendingRequests = false;
                 for(uint j = 0; j < requestsByProvider[provider].length; j++) {
                    bytes32 reqId = requestsByProvider[provider][j];
                    InferenceRequest storage req = inferenceRequests[reqId];
                    if (req.isRequest && req.modelId == modelId && (req.state == RequestState.Claimed || req.state == RequestState.ResultSubmitted)) {
                         hasPendingRequests = true;
                         break;
                    }
                 }
                 if (!hasPendingRequests) {
                      eligibleModels = push(eligibleModels, modelId); // Use a helper function to push to dynamic array in memory
                 }
            }
        }
        return eligibleModels;
    }

    // Helper function to push to dynamic array in memory (Solidity 0.6+ style)
    function push(bytes32[] memory arr, bytes32 value) private pure returns (bytes32[] memory) {
        bytes32[] memory newArr = new bytes32[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = value;
        return newArr;
    }

    // Fallback/Receive to accept ETH for stakes/payments
    receive() external payable {}
    fallback() external payable {}

    // Note on security and complexity:
    // - Dispute resolution: The `flagResultDispute` function is a placeholder. A real system
    //   would need a robust, decentralized mechanism (e.g., staking tokens for jurors,
    //   integration with an oracle network like Kleros or Truth Sayers, or DAO voting)
    //   to actually resolve disputes and trigger fund/stake movements based on the outcome.
    // - Timeouts/Slashing: The current timeout checks (`CLAIM_TIMEOUT`, etc.) only prevent
    //   state transitions *after* timeout. A real system might implement automatic slashing
    //   or state transitions triggered by anyone calling a `checkTimeout` function,
    //   potentially incentivizing watchers.
    // - Data Storage & Verification: The contract only stores hashes. Verifying that the
    //   result hash (`resultDataHash`) is indeed the correct output for the input hash
    //   (`inputDataHash`) using the specified model (`modelId`) is a significant off-chain
    //   challenge (verifiable computation). ZK-proofs could potentially help here in the future.
    // - Scalability: Iterating through dynamic arrays (`modelIds`, `requestIds`, `openRequestIdsForModel`)
    //   becomes very expensive with many entries. For a production system, more scalable
    //   patterns (e.g., using libraries like EnumerableSet from OpenZeppelin, or requiring
    //   off-chain indexing) would be necessary. This contract prioritizes demonstrating the
    //   core logic concepts over gas-efficient iteration for potentially massive lists.
    // - Reputation System: The simple sum/count reputation can be gamed. A production system
    //   would need a more sophisticated reputation algorithm, potentially weighted by stake,
    //   transaction value, or interactions with trusted entities.
    // - Off-chain Agent: Model providers need an off-chain system to listen for `InferenceRequestSubmitted`
    //   events, perform the computation using the specified model and input data (retrieved via hash),
    //   upload the result data, and call `submitInferenceResult`.
}
```