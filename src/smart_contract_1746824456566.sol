Okay, here is a Solidity smart contract for a Decentralized AI Model Marketplace.

**Concept:**

This contract serves as a marketplace where "Model Providers" can list AI models (represented by metadata hashes pointing to off-chain resources like model files and documentation on IPFS/Arweave). "Consumers" can then pay to request inference jobs using these models. The actual AI inference is performed off-chain by trusted "Oracles" (or a network of them) who listen for requests, process the data (input data hash provided by consumer), and submit the results (output data hash) back to the contract. The contract manages payments, staking, reputation, model versioning, and a basic dispute mechanism.

This combines several advanced concepts:
*   **Off-chain Compute Integration:** Relies heavily on Oracles to bridge the gap between blockchain and off-chain AI execution.
*   **Decentralized Marketplace Logic:** Manages listings, payments, and state transitions on-chain.
*   **Staking:** Providers stake funds to ensure good behavior and qualify for listing.
*   **Reputation System:** Simple on-chain rating and reporting to build trust.
*   **Versioning:** Allows models to be updated over time.
*   **Dispute Mechanism:** A basic process for resolving issues with inference results, handled by a designated Arbitrator.
*   **IPFS/Arweave Integration:** Uses content hashes (like IPFS CIDs) to refer to off-chain data (models, input, output).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Decentralized AI Model Marketplace
 * @dev A marketplace contract for listing, requesting, and paying for AI model inferences.
 *      Relies on off-chain oracles for execution and IPFS/Arweave for data storage.
 */

// --- OUTLINE ---
// 1. State Variables: Core configurations, addresses, counters, balances.
// 2. Enums: Define possible states for models, requests, disputes.
// 3. Structs: Define data structures for models, requests, providers.
// 4. Events: Announce key actions and state changes.
// 5. Modifiers: Implement access control.
// 6. Core Marketplace Functions: Provider registration, model listing/management, inference requests, fulfillment, withdrawals.
// 7. Advanced Features Functions: Staking, reputation, versioning, disputes, arbitration.
// 8. Administration Functions: Owner controls for fees, addresses, etc.
// 9. View Functions: Public functions to read contract state.

// --- FUNCTION SUMMARY ---
// 1. constructor(): Initializes the contract owner.
// 2. setOracleAddress(address _oracle): Owner sets the trusted oracle address.
// 3. setArbitratorAddress(address _arbitrator): Owner sets the dispute arbitrator address.
// 4. setStakingRequirements(uint256 _minStake, uint256 _stakeLockDuration): Owner sets provider staking minimum and lock duration.
// 5. setModelListingFee(uint256 _fee): Owner sets the fee to list a new model.
// 6. registerProvider(): Allows a user to register as a model provider by paying the minimum stake.
// 7. stakeProvider(uint256 amount): Allows a provider to add more stake.
// 8. requestUnstakeProvider(uint256 amount): Provider requests to unstake, starts lockup period.
// 9. withdrawStake(): Provider withdraws stake after lockup period expires.
// 10. updateProviderProfile(string memory _metadataHash): Provider updates their profile metadata.
// 11. listModel(string memory _modelMetadataHash, uint256 _pricePerInference, string memory _version): Provider lists a new AI model version. Pays listing fee.
// 12. updateModelDetails(uint256 _modelId, string memory _modelMetadataHash, uint256 _pricePerInference, string memory _version): Provider updates details or submits a new version for an existing model.
// 13. setModelActiveVersion(uint256 _modelId, uint256 _versionIndex): Provider selects which listed version is currently active.
// 14. pauseModel(uint256 _modelId): Provider temporarily pauses their model.
// 15. activateModel(uint256 _modelId): Provider re-activates their paused model.
// 16. requestInference(uint256 _modelId, string memory _inputDataHash): Consumer requests an inference, pays model price upfront.
// 17. fulfillInference(uint256 _requestId, string memory _outputDataHash, bool _success): Called by Oracle to report inference result. Triggers payment or refund.
// 18. withdrawProviderEarnings(): Provider withdraws accumulated earnings from successful inferences.
// 19. withdrawConsumerRefund(): Consumer withdraws refunds from failed/cancelled inferences.
// 20. rateModel(uint256 _requestId, uint8 _rating): Consumer rates a *completed* inference request (1-5). Impacts provider reputation.
// 21. reportMaliciousProvider(uint256 _modelId, uint256 _requestId, string memory _reasonHash): Consumer reports a provider/model. Lowers reputation, potentially triggers review.
// 22. raiseDispute(uint256 _requestId, string memory _reasonHash): Consumer formally raises a dispute against a *completed* inference. Requires staking a dispute fee.
// 23. arbitrateDispute(uint256 _disputeId, bool _consumerWins): Called by Arbitrator to resolve a dispute. Determines fund distribution.
// 24. getModelDetails(uint256 _modelId): View function to get model information.
// 25. getProviderDetails(address _provider): View function to get provider information.
// 26. getInferenceRequest(uint256 _requestId): View function to get request information.
// 27. getProviderEarnings(address _provider): View function to see a provider's withdrawable balance.
// 28. getConsumerRefundBalance(address _consumer): View function to see a consumer's withdrawable balance.
// 29. getDisputeDetails(uint256 _disputeId): View function to get dispute information.
// 30. getModelActiveVersion(uint256 _modelId): View function to get the index of the currently active version.
// 31. getModelVersionDetails(uint256 _modelId, uint256 _versionIndex): View function to get details of a specific model version.

contract DecentralizedAIModelMarketplace {

    address public owner;
    address public oracleAddress; // Address authorized to fulfill inference requests
    address public arbitratorAddress; // Address authorized to arbitrate disputes

    uint256 public minProviderStake;
    uint256 public stakeLockDuration; // Duration in seconds for stake lockup
    uint256 public modelListingFee;
    uint256 public disputeFee; // Fee required to raise a dispute

    uint256 private modelCounter;
    uint256 private requestCounter;
    uint256 private disputeCounter;

    enum ModelState {
        Pending,    // Waiting for initial review/activation (optional, not implemented fully here)
        Active,     // Available for requests
        Paused,     // Temporarily unavailable
        Delisted    // Permanently removed
    }

    enum RequestStatus {
        Pending,    // Waiting for Oracle to pick up
        Processing, // Oracle is working on it (off-chain)
        Completed,  // Oracle submitted result
        Failed,     // Oracle reported failure
        Cancelled,  // Request cancelled (e.g., due to model pause)
        Disputed    // Result is under dispute
    }

    enum DisputeStatus {
        Open,       // Dispute raised, awaiting arbitration
        Resolved    // Dispute has been arbitrated
    }

    struct ModelVersion {
        string metadataHash;      // IPFS/Arweave hash of model files, documentation, etc.
        string version;           // Semantic version string (e.g., "1.0.0")
        uint256 pricePerInference;
        uint256 listedTimestamp;
    }

    struct Model {
        uint256 id;
        address provider;
        string latestMetadataHash; // Hash of the current active version
        uint256 currentPrice;      // Price of the current active version
        ModelState state;
        uint256 activeVersionIndex; // Index in the versions array
        ModelVersion[] versions;   // Array of past and current versions
        uint256 reputationScore;   // Simple score based on ratings and reports
        uint256 creationTimestamp;
    }

    struct InferenceRequest {
        uint256 id;
        uint256 modelId;
        address consumer;
        string inputDataHash;   // IPFS/Arweave hash of consumer input data
        string outputDataHash;  // IPFS/Arweave hash of inference result data (set by Oracle)
        uint256 pricePaid;
        RequestStatus status;
        uint256 requestTimestamp;
        uint256 fulfillmentTimestamp; // When Oracle fulfilled
        uint256 rating;             // Consumer rating (0 if not rated)
    }

     struct Provider {
        address providerAddress;
        string profileMetadataHash; // IPFS/Arweave hash for provider info
        uint256 stakedAmount;
        uint256 unstakeRequestAmount; // Amount requested to unstake
        uint256 unstakeRequestTimestamp; // Timestamp of unstake request
        bool isRegistered;
        int256 reputation; // Simple score based on ratings, reports, disputes
    }

    struct Dispute {
        uint256 id;
        uint256 requestId;
        address consumer; // Address who raised the dispute
        address provider; // Provider of the model
        string reasonHash; // IPFS/Arweave hash of dispute reason/evidence
        uint256 disputeFeePaid;
        DisputeStatus status;
        bool consumerWon; // Result of arbitration
        uint256 raiseTimestamp;
        uint256 resolutionTimestamp;
    }

    // State mappings
    mapping(uint256 => Model) public models;
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    mapping(address => Provider) public providers;
    mapping(uint256 => Dispute) public disputes;

    // Internal balances (withdrawal pattern)
    mapping(address => uint256) public providerEarnings; // Earnings per provider
    mapping(address => uint256) public consumerRefunds;  // Refunds per consumer
    mapping(uint256 => uint256) public disputeFeesEscrow; // Fees held during dispute

    // --- EVENTS ---
    event OracleAddressUpdated(address indexed newOracle);
    event ArbitratorAddressUpdated(address indexed newArbitrator);
    event StakingRequirementsUpdated(uint256 minStake, uint256 lockDuration);
    event ModelListingFeeUpdated(uint256 fee);
    event DisputeFeeUpdated(uint256 fee);

    event ProviderRegistered(address indexed provider);
    event ProviderStaked(address indexed provider, uint256 amount);
    event ProviderUnstakeRequested(address indexed provider, uint256 amount, uint256 unlockTimestamp);
    event ProviderStakeWithdrawn(address indexed provider, uint256 amount);
    event ProviderProfileUpdated(address indexed provider, string metadataHash);

    event ModelListed(uint256 indexed modelId, address indexed provider, string metadataHash, uint256 price, string version);
    event ModelDetailsUpdated(uint256 indexed modelId, string metadataHash, uint256 price, string version);
    event ModelActiveVersionSet(uint256 indexed modelId, uint256 indexed versionIndex, string version);
    event ModelStateChanged(uint256 indexed modelId, ModelState newState);

    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed consumer, string inputHash, uint256 pricePaid);
    event InferenceFulfilled(uint256 indexed requestId, string outputHash, bool success);
    event InferenceRated(uint256 indexed requestId, uint8 rating, int256 providerReputationChange);

    event ProviderReported(address indexed reporter, uint256 indexed provider, uint256 indexed modelId, string reasonHash);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed requestId, address indexed consumer, string reasonHash);
    event DisputeArbitrated(uint256 indexed disputeId, bool consumerWon);

    event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
    event ConsumerRefundWithdrawn(address indexed consumer, uint256 amount);

    // --- MODIFIERS ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Only oracle can call this function");
        _;
    }

     modifier onlyArbitrator() {
        require(msg.sender == arbitratorAddress, "Only arbitrator can call this function");
        _;
    }

    modifier onlyRegisteredProvider() {
        require(providers[msg.sender].isRegistered, "Caller is not a registered provider");
        _;
    }

    modifier isModelProvider(uint256 _modelId) {
        require(models[_modelId].provider == msg.sender, "Caller is not the model provider");
        _;
    }

    // --- STATE CONFIGURATION (OWNER) ---

    constructor() payable {
        owner = msg.sender;
        // Set default values (can be updated by owner)
        minProviderStake = 1 ether; // Example minimum stake
        stakeLockDuration = 7 days; // Example lock duration
        modelListingFee = 0.01 ether; // Example listing fee
        disputeFee = 0.05 ether; // Example dispute fee
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        oracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    function setArbitratorAddress(address _arbitrator) external onlyOwner {
        require(_arbitrator != address(0), "Invalid arbitrator address");
        arbitratorAddress = _arbitrator;
        emit ArbitratorAddressUpdated(_arbitrator);
    }

    function setStakingRequirements(uint256 _minStake, uint256 _stakeLockDuration) external onlyOwner {
        require(_minStake >= 0, "Min stake cannot be negative"); // Redundant check for uint256 but good practice
        require(_stakeLockDuration >= 0, "Lock duration cannot be negative");
        minProviderStake = _minStake;
        stakeLockDuration = _stakeLockDuration;
        emit StakingRequirementsUpdated(_minStake, _stakeLockDuration);
    }

    function setModelListingFee(uint256 _fee) external onlyOwner {
        modelListingFee = _fee;
        emit ModelListingFeeUpdated(_fee);
    }

    function setDisputeFee(uint256 _fee) external onlyOwner {
        disputeFee = _fee;
        emit DisputeFeeUpdated(_fee);
    }

    // --- PROVIDER MANAGEMENT ---

    function registerProvider() external payable {
        Provider storage provider = providers[msg.sender];
        require(!provider.isRegistered, "Provider is already registered");
        require(msg.value >= minProviderStake, "Insufficient stake provided");

        provider.providerAddress = msg.sender;
        provider.stakedAmount = msg.value;
        provider.isRegistered = true;
        // reputation starts at 0

        emit ProviderRegistered(msg.sender);
        emit ProviderStaked(msg.sender, msg.value);
    }

    function stakeProvider(uint256 amount) external payable onlyRegisteredProvider {
        Provider storage provider = providers[msg.sender];
        require(msg.value == amount, "Sent amount does not match specified amount");

        provider.stakedAmount += amount;
        emit ProviderStaked(msg.sender, amount);
    }

    function requestUnstakeProvider(uint256 amount) external onlyRegisteredProvider {
        Provider storage provider = providers[msg.sender];
        require(amount > 0, "Unstake amount must be greater than 0");
        require(provider.stakedAmount >= amount, "Insufficient staked amount");
        require(provider.unstakeRequestAmount == 0, "Pending unstake request already exists");
        require(provider.stakedAmount - amount >= minProviderStake, "Cannot unstake below minimum stake");

        provider.unstakeRequestAmount = amount;
        provider.unstakeRequestTimestamp = block.timestamp;

        emit ProviderUnstakeRequested(msg.sender, amount, block.timestamp + stakeLockDuration);
    }

     function withdrawStake() external onlyRegisteredProvider {
        Provider storage provider = providers[msg.sender];
        require(provider.unstakeRequestAmount > 0, "No pending unstake request");
        require(block.timestamp >= provider.unstakeRequestTimestamp + stakeLockDuration, "Stake is still locked");

        uint256 amountToWithdraw = provider.unstakeRequestAmount;
        provider.stakedAmount -= amountToWithdraw;
        provider.unstakeRequestAmount = 0;
        provider.unstakeRequestTimestamp = 0;

        // Direct transfer is okay here as it's the withdrawal pattern
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Stake withdrawal failed");

        emit ProviderStakeWithdrawn(msg.sender, amountToWithdraw);
    }


    function updateProviderProfile(string memory _profileMetadataHash) external onlyRegisteredProvider {
        Provider storage provider = providers[msg.sender];
        provider.profileMetadataHash = _profileMetadataHash;
        emit ProviderProfileUpdated(msg.sender, _profileMetadataHash);
    }

    // --- MODEL MANAGEMENT ---

    function listModel(string memory _modelMetadataHash, uint256 _pricePerInference, string memory _version) external payable onlyRegisteredProvider {
        require(msg.value >= modelListingFee, "Insufficient listing fee");
        require(_pricePerInference > 0, "Price per inference must be greater than zero");
        // Minimal validation on hashes, assumes off-chain verification occurs before listing
        require(bytes(_modelMetadataHash).length > 0, "Model metadata hash cannot be empty");
        require(bytes(_version).length > 0, "Version string cannot be empty");

        Provider storage provider = providers[msg.sender];
        require(provider.stakedAmount >= minProviderStake, "Provider stake is below minimum");

        modelCounter++;
        uint256 newModelId = modelCounter;

        ModelVersion memory firstVersion = ModelVersion({
            metadataHash: _modelMetadataHash,
            version: _version,
            pricePerInference: _pricePerInference,
            listedTimestamp: block.timestamp
        });

        Model storage newModel = models[newModelId];
        newModel.id = newModelId;
        newModel.provider = msg.sender;
        newModel.latestMetadataHash = _modelMetadataHash;
        newModel.currentPrice = _pricePerInference;
        newModel.state = ModelState.Active;
        newModel.activeVersionIndex = 0; // First version is active by default
        newModel.versions.push(firstVersion);
        newModel.reputationScore = 0; // Initial reputation
        newModel.creationTimestamp = block.timestamp;

        // Listing fee goes to contract balance (owner can withdraw later)
        // msg.value was already transferred on call

        emit ModelListed(newModelId, msg.sender, _modelMetadataHash, _pricePerInference, _version);
    }

    function updateModelDetails(uint256 _modelId, string memory _modelMetadataHash, uint256 _pricePerInference, string memory _version) external isModelProvider(_modelId) {
        Model storage model = models[_modelId];
        require(model.state != ModelState.Delisted, "Model is delisted");
        require(bytes(_modelMetadataHash).length > 0, "Model metadata hash cannot be empty");
        require(bytes(_version).length > 0, "Version string cannot be empty");
        require(_pricePerInference > 0, "Price per inference must be greater than zero");

        // Add new version to history
        ModelVersion memory newVersion = ModelVersion({
            metadataHash: _modelMetadataHash,
            version: _version,
            pricePerInference: _pricePerInference,
            listedTimestamp: block.timestamp
        });
        model.versions.push(newVersion);

        // Automatically set the new version as active
        model.activeVersionIndex = model.versions.length - 1;
        model.latestMetadataHash = _modelMetadataHash;
        model.currentPrice = _pricePerInference;

        emit ModelDetailsUpdated(_modelId, _modelMetadataHash, _pricePerInference, _version);
        emit ModelActiveVersionSet(_modelId, model.activeVersionIndex, _version);
    }

    function setModelActiveVersion(uint256 _modelId, uint256 _versionIndex) external isModelProvider(_modelId) {
        Model storage model = models[_modelId];
        require(_versionIndex < model.versions.length, "Invalid version index");
        require(model.state != ModelState.Delisted, "Model is delisted");

        model.activeVersionIndex = _versionIndex;
        model.latestMetadataHash = model.versions[_versionIndex].metadataHash;
        model.currentPrice = model.versions[_versionIndex].pricePerInference;

        emit ModelActiveVersionSet(_modelId, _versionIndex, model.versions[_versionIndex].version);
    }

    function pauseModel(uint256 _modelId) external isModelProvider(_modelId) {
        Model storage model = models[_modelId];
        require(model.state == ModelState.Active, "Model is not active");
        model.state = ModelState.Paused;
        emit ModelStateChanged(_modelId, ModelState.Paused);
    }

    function activateModel(uint256 _modelId) external isModelProvider(_modelId) {
        Model storage model = models[_modelId];
        require(model.state == ModelState.Paused, "Model is not paused");
        Provider storage provider = providers[model.provider];
        require(provider.stakedAmount >= minProviderStake, "Provider stake is below minimum to reactivate");

        model.state = ModelState.Active;
        emit ModelStateChanged(_modelId, ModelState.Active);
    }

    // Delist model? Could add this, might involve slashing stake or reputation penalty. (Keeping under 20 functions for clarity initially, this would be >20)

    // --- INFERENCE REQUESTS ---

    function requestInference(uint256 _modelId, string memory _inputDataHash) external payable {
        Model storage model = models[_modelId];
        require(model.state == ModelState.Active, "Model is not available for inference");
        require(msg.value >= model.currentPrice, "Insufficient payment for inference");
        require(bytes(_inputDataHash).length > 0, "Input data hash cannot be empty");

        requestCounter++;
        uint256 newRequestId = requestCounter;

        // Refund any excess payment
        if (msg.value > model.currentPrice) {
            uint256 refundAmount = msg.value - model.currentPrice;
            consumerRefunds[msg.sender] += refundAmount;
            emit ConsumerRefundWithdrawn(msg.sender, refundAmount); // Signify refund is available
        }

        InferenceRequest storage newRequest = inferenceRequests[newRequestId];
        newRequest.id = newRequestId;
        newRequest.modelId = _modelId;
        newRequest.consumer = msg.sender;
        newRequest.inputDataHash = _inputDataHash;
        newRequest.pricePaid = model.currentPrice;
        newRequest.status = RequestStatus.Pending;
        newRequest.requestTimestamp = block.timestamp;

        emit InferenceRequested(newRequestId, _modelId, msg.sender, _inputDataHash, model.currentPrice);
    }

    function fulfillInference(uint256 _requestId, string memory _outputDataHash, bool _success) external onlyOracle {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.status == RequestStatus.Pending || request.status == RequestStatus.Processing, "Request not in pending or processing state");

        request.fulfillmentTimestamp = block.timestamp;
        request.outputDataHash = _outputDataHash;

        if (_success) {
            request.status = RequestStatus.Completed;
            // Transfer payment from contract to provider's earnings balance (withdrawal pattern)
            providerEarnings[request.modelId == 0 ? address(0) : models[request.modelId].provider] += request.pricePaid; // Use models[request.modelId].provider safely
        } else {
            request.status = RequestStatus.Failed;
            // Refund consumer (withdrawal pattern)
            consumerRefunds[request.consumer] += request.pricePaid;
        }

        emit InferenceFulfilled(_requestId, _outputDataHash, _success);
    }

    // --- WITHDRAWALS ---

    function withdrawProviderEarnings() external onlyRegisteredProvider {
        uint256 amount = providerEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        providerEarnings[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Earnings withdrawal failed");

        emit ProviderEarningsWithdrawn(msg.sender, amount);
    }

    function withdrawConsumerRefund() external {
        uint256 amount = consumerRefunds[msg.sender];
        require(amount > 0, "No refunds to withdraw");

        consumerRefunds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund withdrawal failed");

        emit ConsumerRefundWithdrawn(msg.sender, amount);
    }

    // --- REPUTATION AND DISPUTES ---

    function rateModel(uint256 _requestId, uint8 _rating) external {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.consumer == msg.sender, "Only the consumer can rate this request");
        require(request.status == RequestStatus.Completed, "Request must be completed to be rated");
        require(request.rating == 0, "Request has already been rated");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        request.rating = _rating;

        Model storage model = models[request.modelId];
        // Simple linear reputation scoring (can be made more complex)
        int256 reputationChange = 0;
        if (_rating >= 4) {
            reputationChange = int256(_rating) - 3; // +1 or +2 for good ratings
        } else if (_rating <= 2) {
             reputationChange = int256(_rating) - 3; // -1 or -2 for bad ratings
        }
        // No change for rating 3

        model.reputationScore = model.reputationScore + uint256(reputationChange > 0 ? reputationChange : 0); // Simple example: only positive score accumulation
        Provider storage provider = providers[model.provider];
        provider.reputation = provider.reputation + reputationChange;


        emit InferenceRated(_requestId, _rating, reputationChange);
    }

    function reportMaliciousProvider(uint256 _modelId, uint256 _requestId, string memory _reasonHash) external {
        // Simple report mechanism, doesn't automatically trigger slashing, just records and affects reputation
        // A more advanced system might require staking a report fee or linking to governance
        Model storage model = models[_modelId];
        require(model.state != ModelState.Delisted, "Model is delisted");
        require(inferenceRequests[_requestId].consumer == msg.sender, "Only the consumer involved can report for this request"); // Allow reporting even if not involved in the request, or restrict? Restrict for now.

        Provider storage provider = providers[model.provider];
        // Penalize reputation slightly for a report
        provider.reputation -= 1; // Example penalty

        emit ProviderReported(msg.sender, model.provider, _modelId, _reasonHash);
        // Potentially add reports to a list or queue for review by Arbitrator/DAO off-chain
    }

    function raiseDispute(uint256 _requestId, string memory _reasonHash) external payable {
        InferenceRequest storage request = inferenceRequests[_requestId];
        require(request.consumer == msg.sender, "Only the consumer can dispute this request");
        require(request.status == RequestStatus.Completed || request.status == RequestStatus.Failed, "Can only dispute completed or failed requests");
        require(msg.value >= disputeFee, "Insufficient dispute fee");
        require(bytes(_reasonHash).length > 0, "Dispute reason hash cannot be empty");

        // Prevent raising multiple disputes for the same request (simplified)
        // A more complex system might track disputes per request
        require(request.status != RequestStatus.Disputed, "Request is already under dispute");

        disputeCounter++;
        uint256 newDisputeId = disputeCounter;

        Dispute storage newDispute = disputes[newDisputeId];
        newDispute.id = newDisputeId;
        newDispute.requestId = _requestId;
        newDispute.consumer = msg.sender;
        newDispute.provider = models[request.modelId].provider;
        newDispute.reasonHash = _reasonHash;
        newDispute.disputeFeePaid = msg.value; // Can be > fee, excess refunded? Let's keep it simple and require exact fee.
        require(msg.value == disputeFee, "Exact dispute fee required");
        newDispute.status = DisputeStatus.Open;
        newDispute.raiseTimestamp = block.timestamp;

        // Escrow the dispute fee
        disputeFeesEscrow[newDisputeId] = msg.value;

        // Mark the request as disputed
        request.status = RequestStatus.Disputed;

        emit DisputeRaised(newDisputeId, _requestId, msg.sender, _reasonHash);
    }

    function arbitrateDispute(uint256 _disputeId, bool _consumerWins) external onlyArbitrator {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");

        InferenceRequest storage request = inferenceRequests[dispute.requestId];
        Provider storage provider = providers[dispute.provider];

        dispute.consumerWon = _consumerWins;
        dispute.status = DisputeStatus.Resolved;
        dispute.resolutionTimestamp = block.timestamp;

        uint256 totalFundsInvolved = request.pricePaid + dispute.disputeFeePaid; // Price paid + consumer's dispute fee
        uint256 disputeFee = dispute.disputeFeePaid; // Store fee before zeroing escrow
        disputeFeesEscrow[_disputeId] = 0; // Clear escrow

        if (_consumerWins) {
            // Consumer wins:
            // - Consumer gets back inference price paid + their dispute fee
            // - Provider may get reputation slashed
            // - Provider stake may be slashed (optional, add complexity)
            // - Oracle may get reputation slashed (optional)

            consumerRefunds[dispute.consumer] += totalFundsInvolved; // Refund consumer everything they paid for this request/dispute
            provider.reputation -= 5; // Example slashing

        } else {
            // Provider wins:
            // - Provider gets the inference price paid
            // - Provider gets the consumer's dispute fee
            // - Consumer may get reputation slashed (optional)
            // - Consumer does *not* get their dispute fee back

            providerEarnings[dispute.provider] += request.pricePaid; // Provider gets the original payment
            providerEarnings[dispute.provider] += disputeFee;        // Provider also gets the consumer's dispute fee
            // Consumer gets nothing back
        }

        // Mark the request as completed (regardless of who won the dispute, the outcome is decided)
        // Or maybe keep it as Disputed/Resolved? Let's keep it Disputed state but resolved outcome.
        // request.status remains Disputed

        emit DisputeArbitrated(_disputeId, _consumerWins);
    }

    // --- VIEW FUNCTIONS ---

    function getModelDetails(uint256 _modelId) external view returns (
        uint256 id,
        address provider,
        string memory latestMetadataHash,
        uint256 currentPrice,
        ModelState state,
        uint256 activeVersionIndex,
        uint256 versionCount, // Return count instead of array to avoid stack too deep
        uint256 reputationScore,
        uint256 creationTimestamp
    ) {
        Model storage model = models[_modelId];
        require(model.id != 0, "Model does not exist"); // Check if model is initialized

        return (
            model.id,
            model.provider,
            model.latestMetadataHash,
            model.currentPrice,
            model.state,
            model.activeVersionIndex,
            model.versions.length,
            model.reputationScore,
            model.creationTimestamp
        );
    }

     function getProviderDetails(address _provider) external view returns (
        address providerAddress,
        string memory profileMetadataHash,
        uint256 stakedAmount,
        uint256 unstakeRequestAmount,
        uint256 unstakeRequestTimestamp,
        bool isRegistered,
        int256 reputation
     ) {
        Provider storage provider = providers[_provider];
        require(provider.isRegistered, "Provider not registered");

        return (
            provider.providerAddress,
            provider.profileMetadataHash,
            provider.stakedAmount,
            provider.unstakeRequestAmount,
            provider.unstakeRequestTimestamp,
            provider.isRegistered,
            provider.reputation
        );
     }


    function getInferenceRequest(uint256 _requestId) external view returns (
        uint256 id,
        uint256 modelId,
        address consumer,
        string memory inputDataHash,
        string memory outputDataHash,
        uint256 pricePaid,
        RequestStatus status,
        uint256 requestTimestamp,
        uint256 fulfillmentTimestamp,
        uint256 rating
    ) {
        InferenceRequest storage request = inferenceRequests[_requestId];
         require(request.id != 0, "Request does not exist"); // Check if request is initialized

        return (
            request.id,
            request.modelId,
            request.consumer,
            request.inputDataHash,
            request.outputDataHash,
            request.pricePaid,
            request.status,
            request.requestTimestamp,
            request.fulfillmentTimestamp,
            request.rating
        );
    }

    function getProviderEarnings(address _provider) external view returns (uint256) {
        return providerEarnings[_provider];
    }

    function getConsumerRefundBalance(address _consumer) external view returns (uint256) {
        return consumerRefunds[_consumer];
    }

    function getDisputeDetails(uint256 _disputeId) external view returns (
        uint256 id,
        uint256 requestId,
        address consumer,
        address provider,
        string memory reasonHash,
        uint256 disputeFeePaid,
        DisputeStatus status,
        bool consumerWon,
        uint256 raiseTimestamp,
        uint256 resolutionTimestamp
    ) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist"); // Check if dispute is initialized

        return (
            dispute.id,
            dispute.requestId,
            dispute.consumer,
            dispute.provider,
            dispute.reasonHash,
            dispute.disputeFeePaid,
            dispute.status,
            dispute.consumerWon,
            dispute.raiseTimestamp,
            dispute.resolutionTimestamp
        );
    }

     function getModelActiveVersion(uint256 _modelId) external view returns (uint256 versionIndex) {
        Model storage model = models[_modelId];
        require(model.id != 0, "Model does not exist");
        return model.activeVersionIndex;
    }

    function getModelVersionDetails(uint256 _modelId, uint256 _versionIndex) external view returns (
        string memory metadataHash,
        string memory version,
        uint256 pricePerInference,
        uint256 listedTimestamp
    ) {
         Model storage model = models[_modelId];
         require(model.id != 0, "Model does not exist");
         require(_versionIndex < model.versions.length, "Invalid version index");
         ModelVersion storage modelVersion = model.versions[_versionIndex];
         return (
             modelVersion.metadataHash,
             modelVersion.version,
             modelVersion.pricePerInference,
             modelVersion.listedTimestamp
         );
    }

    function getTotalModelCount() external view returns (uint256) {
        return modelCounter;
    }
}
```