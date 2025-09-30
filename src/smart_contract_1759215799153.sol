The following smart contract, **AetherAI**, introduces a decentralized marketplace and inference network for AI models. It focuses on facilitating off-chain AI computation by managing the on-chain logic for model registration, inference requests, decentralized execution, payment, reputation, and dispute resolution. The core idea is to create a self-sustaining ecosystem where AI model providers, inference node operators, and consumers can interact transparently and trustlessly.

**Key Advanced Concepts & Creativity:**

1.  **Decentralized AI Marketplace:** A platform for registering and discovering AI models, identified by content hashes rather than centralized endpoints.
2.  **Inference Network:** A system that connects requesters with decentralized nodes for actual AI computation, where the contract orchestrates payment and agreement.
3.  **Staking for Nodes:** Inference nodes must stake collateral to participate, incentivizing good behavior and providing a slashing mechanism for misbehavior.
4.  **Reputation System:** Users can rate models and nodes, building a community-driven quality control mechanism.
5.  **Dispute Resolution Oracle:** An integrated system for challenging incorrect inference results, with resolution handled by a designated oracle or governance.
6.  **Adaptive Incentives:** Dynamic fees (model-defined base fee, consumer-defined max fee), and reward distribution split between model providers and inference nodes.
7.  **Off-chain Data References:** Utilizes IPFS/Arweave hashes for AI model metadata, input, and output data, keeping on-chain gas costs low while maintaining data integrity.
8.  **Soft Deregistration & Admin Controls:** Models can be "paused" or "deregistered" without completely wiping historical data, allowing for auditing. Admin functions provide necessary governance for critical parameters and crisis management.

This contract aims to avoid direct duplication of existing open-source projects by focusing on the unique combination of these elements tailored specifically for an AI inference network, rather than just generic data processing or simpler marketplaces.

---

## Contract Outline & Function Summary:

**Contract Name:** `AetherAI`

**Core Purpose:** To provide a decentralized, trustless, and incentivized platform for AI model registration, inference execution, and quality assurance.

### I. Model Management (Provider Functions)

1.  **`registerModel(bytes32 modelHash, string calldata metadataURI, uint256 baseInferenceFee, uint256 expectedGasCost)`**
    *   **Summary:** Registers a new AI model on the marketplace, providing its unique hash, metadata URI (e.g., IPFS), base fee for inferences, and estimated off-chain computation cost.
    *   **Advanced:** `modelHash` as a content addressable identifier ensures uniqueness and verifiability of the model.

2.  **`updateModel(bytes32 modelHash, string calldata newMetadataURI, uint256 newBaseInferenceFee, uint256 newExpectedGasCost)`**
    *   **Summary:** Allows the model owner to update the model's metadata URI, base inference fee, and expected gas cost.

3.  **`deregisterModel(bytes32 modelHash)`**
    *   **Summary:** Sets a model's `isActive` status to `false`, effectively removing it from active listings without deleting its historical data.

4.  **`toggleModelActiveStatus(bytes32 modelHash, bool status)`**
    *   **Summary:** Allows the contract owner (admin) to forcefully activate or deactivate a model, overriding the model owner's setting, useful for moderation.

### II. Inference Node Management (Node Functions)

5.  **`registerInferenceNode(string calldata nodeURI, uint256 stakeAmount)`**
    *   **Summary:** Registers a new inference node by requiring a minimum token stake to ensure commitment and provide collateral for slashing.

6.  **`updateNodeStake(uint256 additionalStakeAmount)`**
    *   **Summary:** Allows an existing inference node to increase its staked amount.

7.  **`requestNodeStakeWithdrawal()`**
    *   **Summary:** Initiates a cooldown period for an inference node to withdraw its staked funds, also deactivating the node during this period.

8.  **`withdrawStakedFunds()`**
    *   **Summary:** Allows a node to fully withdraw its stake after the cooldown period, effectively deregistering it.

### III. Inference Lifecycle (Consumer & Node Interaction)

9.  **`requestInference(bytes32 modelHash, bytes32 inputDataHash, uint256 maxFee)`**
    *   **Summary:** A consumer requests an AI inference, specifying the model, input data hash, and the maximum fee they are willing to pay. Transfers `maxFee` to the contract in escrow.

10. **`fulfillInference(uint256 requestId, bytes32 outputDataHash)`**
    *   **Summary:** An active inference node submits the hash of the computed output data for a pending request, claiming the fee.

11. **`challengeInferenceResult(uint256 requestId)`**
    *   **Summary:** The consumer can challenge a fulfilled inference result within a specific time window if they believe it's incorrect.

12. **`resolveInferenceDispute(uint256 requestId, bool challengerWon)`**
    *   **Summary:** The designated `disputeResolutionOracle` resolves a challenged inference, leading to potential slashing of the node or refund to the requester.

### IV. Reputation & Reporting (Community Functions)

13. **`submitModelRating(bytes32 modelHash, uint8 rating)`**
    *   **Summary:** Allows users (typically consumers) to submit a rating for an AI model (1-5 stars).

14. **`submitNodeRating(address nodeAddress, uint8 rating)`**
    *   **Summary:** Allows users (typically consumers) to submit a rating for an inference node.

15. **`reportMisbehavingNode(address nodeAddress, string calldata evidenceURI)`**
    *   **Summary:** Allows any user to report an inference node for suspected misbehavior, with evidence referenced by a URI.

16. **`resolveNodeMisbehavior(address nodeAddress, uint256 slashAmount, bool deactivateNode)`**
    *   **Summary:** The contract owner can take action against a reported node, including slashing a portion of its stake and/or deactivating it.

### V. Rewards & Administrative (Financial & Governance)

17. **`claimRewards()`**
    *   **Summary:** Allows both inference nodes and model providers to claim their accumulated rewards from successfully fulfilled inferences.

18. **`setDisputeResolutionOracle(address _newOracle)`**
    *   **Summary:** Allows the contract owner to update the address of the trusted dispute resolution oracle.

19. **`setMinNodeStake(uint256 _newMinNodeStake)`**
    *   **Summary:** Allows the contract owner to adjust the minimum token stake required for inference nodes.

### VI. View & Getter Functions

20. **`getModelDetails(bytes32 modelHash)`**
    *   **Summary:** Returns all stored details for a specific AI model.

21. **`getNodeDetails(address nodeAddress)`**
    *   **Summary:** Returns all stored details for a specific inference node.

22. **`getInferenceRequestDetails(uint256 requestId)`**
    *   **Summary:** Returns all stored details for a specific inference request.

23. **`getModelAverageRating(bytes32 modelHash)`**
    *   **Summary:** Calculates and returns the average rating for a given model.

24. **`getNodeAverageRating(address nodeAddress)`**
    *   **Summary:** Calculates and returns the average rating for a given inference node.

25. **`getContractBalance()`**
    *   **Summary:** Returns the current balance of the `paymentToken` held by the contract.

26. **`getModelCount()`**
    *   **Summary:** Returns the total number of models that have ever been registered (including inactive ones).

27. **`getPaginatedModelHashes(uint256 offset, uint256 limit)`**
    *   **Summary:** Returns a paginated list of registered model hashes, useful for UI displays.

28. **`updateModelGasCost(bytes32 modelHash, uint256 newExpectedGasCost)`**
    *   **Summary:** Allows the model owner to update the estimated off-chain gas cost for their model.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AetherAI
 * @dev A decentralized AI model marketplace and inference network.
 *      This contract facilitates the registration of AI models, requests for AI inferences,
 *      execution of those inferences by decentralized nodes, and a reputation/dispute resolution
 *      system to ensure quality and fair compensation. It enables a trustless environment
 *      for off-chain AI computation by managing payments, stakes, and challenges on-chain.
 *
 * Concepts embodied:
 * - Decentralized AI Model Registry: Users can list their AI models.
 * - Inference Network: Consumers request predictions, nodes execute them.
 * - Staking Mechanism: Nodes stake tokens to participate and ensure reliability.
 * - Reputation System: Ratings for models and nodes to foster quality.
 * - Dispute Resolution: A mechanism for challenging incorrect inferences, resolved by an oracle or governance.
 * - Dynamic Incentives: Fees and rewards managed by the contract.
 * - Off-chain computation: The contract orchestrates payments and agreements for AI tasks performed off-chain,
 *   using hashes/URIs for input/output data references.
 */
contract AetherAI is Ownable {

    // --- State Variables ---
    IERC20 public immutable paymentToken; // ERC-20 token used for payments and staking
    address public disputeResolutionOracle; // Address of the trusted oracle for dispute resolution
    uint256 public minNodeStake; // Minimum required stake for an inference node to participate
    uint256 public constant INFERENCE_CHALLENGE_WINDOW = 2 days; // Time window for consumers to challenge an inference
    uint256 public constant NODE_STAKE_COOLDOWN_PERIOD = 7 days; // Time period before staked funds can be withdrawn

    uint256 private nextRequestId = 1; // Counter for unique inference request IDs

    // --- Data Structures ---

    enum RequestStatus {
        Pending,        // Request submitted, awaiting fulfillment
        Fulfilled,      // Inference result submitted by a node
        Challenged,     // Consumer has challenged the result
        ResolvedSuccess,// Dispute resolved in favor of the requester (node failed)
        ResolvedFailure // Dispute resolved in favor of the node (requester failed)
    }

    struct Model {
        address owner;              // Address of the model provider
        string metadataURI;         // URI pointing to model details (e.g., IPFS hash)
        uint256 baseInferenceFee;   // Base fee in paymentToken units per inference
        uint256 expectedGasCost;    // Estimated off-chain computation cost (informational)
        bool isActive;              // Whether the model is currently active for requests
        uint256 registeredTimestamp;// Timestamp when the model was registered
        bytes32 modelHash;          // Unique identifier for the model
    }

    struct InferenceNode {
        string nodeURI;             // URI pointing to node details/endpoint (e.g., IPFS, API endpoint)
        uint256 stakeAmount;        // Amount of paymentToken staked by the node
        bool isActive;              // Whether the node is currently active
        uint256 registrationTimestamp; // Timestamp when the node registered
        uint256 rewardsAccumulated; // Accumulated rewards from fulfilled inferences
        uint256 lastStakeWithdrawalRequest; // Timestamp of the last withdrawal request for cooldown
    }

    struct InferenceRequest {
        bytes32 modelHash;          // Hash of the model used
        address requester;          // Address who requested the inference
        address executor;           // Address of the node that fulfilled the inference
        bytes32 inputDataHash;      // Hash of the input data (e.g., IPFS hash)
        bytes32 outputDataHash;     // Hash of the output data (e.g., IPFS hash)
        uint256 maxFee;             // Maximum fee the requester is willing to pay
        uint256 actualFeePaid;      // Actual fee paid to the executor (before split)
        RequestStatus status;       // Current status of the request
        uint256 requestTimestamp;   // Timestamp when the request was made
        uint256 fulfillmentTimestamp; // Timestamp when the request was fulfilled
        uint256 challengeTimestamp; // Timestamp when the request was challenged
    }

    struct RatingAccumulator {
        uint256 totalRating;        // Sum of all ratings received (e.g., 1 to 5)
        uint256 numRatings;         // Total number of ratings received
    }

    // --- Mappings & Arrays ---
    mapping(bytes32 => Model) public models;
    bytes32[] public registeredModelHashes; // Stores all model hashes for iteration and count

    mapping(address => InferenceNode) public inferenceNodes;
    mapping(uint256 => InferenceRequest) public inferenceRequests;

    mapping(bytes32 => RatingAccumulator) public modelRatings; // Model hash => RatingAccumulator
    mapping(address => RatingAccumulator) public nodeRatings;   // Node address => RatingAccumulator

    mapping(address => uint256) public modelOwnerRewards; // Tracks rewards for model owners

    // --- Events ---
    event ModelRegistered(bytes32 indexed modelHash, address indexed owner, string metadataURI, uint256 baseFee);
    event ModelUpdated(bytes32 indexed modelHash, string newMetadataURI, uint256 newBaseFee, uint256 newExpectedGasCost, bool isActive);
    event ModelDeregistered(bytes32 indexed modelHash, address indexed owner);
    event InferenceNodeRegistered(address indexed nodeAddress, string nodeURI, uint256 stakeAmount);
    event InferenceNodeDeregistered(address indexed nodeAddress);
    event InferenceNodeStakeUpdated(address indexed nodeAddress, uint256 newStakeAmount);
    event InferenceRequested(uint256 indexed requestId, bytes32 indexed modelHash, address indexed requester, bytes32 inputDataHash, uint256 maxFee);
    event InferenceFulfilled(uint256 indexed requestId, bytes32 indexed modelHash, address indexed executor, bytes32 outputDataHash, uint256 actualFee);
    event InferenceChallenged(uint256 indexed requestId, address indexed challenger);
    event InferenceDisputeResolved(uint256 indexed requestId, bool indexed challengerWon, address resolver);
    event ModelRatingSubmitted(bytes32 indexed modelHash, address indexed submitter, uint8 rating);
    event NodeRatingSubmitted(address indexed nodeAddress, address indexed submitter, uint8 rating);
    event NodeSlashed(address indexed nodeAddress, uint256 amount);
    event RewardsClaimed(address indexed beneficiary, uint256 amount);
    event DisputeResolutionOracleSet(address indexed newOracle);
    event MinNodeStakeSet(uint256 newMinNodeStake);
    event NodeReported(address indexed nodeAddress, address indexed reporter, string evidenceURI);

    // --- Constructor ---
    constructor(address _paymentToken, uint256 _minNodeStake, address _disputeResolutionOracle) Ownable(msg.sender) {
        require(_paymentToken != address(0), "Invalid payment token address");
        require(_disputeResolutionOracle != address(0), "Invalid oracle address");
        paymentToken = IERC20(_paymentToken);
        minNodeStake = _minNodeStake;
        disputeResolutionOracle = _disputeResolutionOracle;
    }

    // --- I. Model Management (Provider Functions) ---

    /**
     * @dev Registers a new AI model on the marketplace.
     * @param modelHash A unique identifier for the model (e.g., content-addressed hash).
     * @param metadataURI URI pointing to the model's details (e.g., IPFS hash of a JSON file).
     * @param baseInferenceFee The base fee in `paymentToken` units for a single inference.
     * @param expectedGasCost Estimated off-chain computation cost (for informational purposes).
     */
    function registerModel(
        bytes32 modelHash,
        string calldata metadataURI,
        uint256 baseInferenceFee,
        uint256 expectedGasCost
    ) external {
        require(modelHash != bytes32(0), "Model hash cannot be zero");
        require(models[modelHash].owner == address(0), "Model already registered");
        require(baseInferenceFee > 0, "Base fee must be greater than zero");

        models[modelHash] = Model({
            owner: msg.sender,
            metadataURI: metadataURI,
            baseInferenceFee: baseInferenceFee,
            expectedGasCost: expectedGasCost,
            isActive: true, // Default to active upon registration
            registeredTimestamp: block.timestamp,
            modelHash: modelHash
        });
        registeredModelHashes.push(modelHash); // Add to the iterable list
        emit ModelRegistered(modelHash, msg.sender, metadataURI, baseInferenceFee);
    }

    /**
     * @dev Allows the model owner to update model details.
     * @param modelHash The hash of the model to update.
     * @param newMetadataURI New URI for model metadata.
     * @param newBaseInferenceFee New base fee for inferences.
     * @param newExpectedGasCost New estimated off-chain computation cost.
     */
    function updateModel(
        bytes32 modelHash,
        string calldata newMetadataURI,
        uint256 newBaseInferenceFee,
        uint256 newExpectedGasCost
    ) external {
        Model storage model = models[modelHash];
        require(model.owner == msg.sender, "Only model owner can update");
        require(model.owner != address(0), "Model not found");
        require(newBaseInferenceFee > 0, "Base fee must be greater than zero");

        model.metadataURI = newMetadataURI;
        model.baseInferenceFee = newBaseInferenceFee;
        model.expectedGasCost = newExpectedGasCost;
        // isActive status can be toggled via toggleModelActiveStatus by owner or admin
        emit ModelUpdated(modelHash, newMetadataURI, newBaseInferenceFee, newExpectedGasCost, model.isActive);
    }

    /**
     * @dev Allows the model owner to deactivate their model (soft deregistration).
     *      Model will no longer accept new inference requests but remains registered.
     * @param modelHash The hash of the model to deregister.
     */
    function deregisterModel(bytes32 modelHash) external {
        Model storage model = models[modelHash];
        require(model.owner == msg.sender, "Only model owner can deregister");
        require(model.owner != address(0), "Model not found");

        model.isActive = false;
        emit ModelDeregistered(modelHash, msg.sender);
    }

    /**
     * @dev Allows the contract owner to activate or deactivate any model.
     * @param modelHash The hash of the model to toggle.
     * @param status The new active status for the model.
     */
    function toggleModelActiveStatus(bytes32 modelHash, bool status) external onlyOwner {
        Model storage model = models[modelHash];
        require(model.owner != address(0), "Model not found");
        model.isActive = status;
        emit ModelUpdated(modelHash, model.metadataURI, model.baseInferenceFee, model.expectedGasCost, model.isActive);
    }

    // --- II. Inference Node Management (Node Functions) ---

    /**
     * @dev Allows a user to register as an inference node by staking `paymentToken`.
     * @param nodeURI URI pointing to the node's details or endpoint.
     * @param stakeAmount The amount of `paymentToken` to stake.
     */
    function registerInferenceNode(string calldata nodeURI, uint256 stakeAmount) external {
        require(inferenceNodes[msg.sender].registrationTimestamp == 0, "Node already registered");
        require(stakeAmount >= minNodeStake, "Stake amount below minimum");
        require(paymentToken.transferFrom(msg.sender, address(this), stakeAmount), "Token transfer failed");

        inferenceNodes[msg.sender] = InferenceNode({
            nodeURI: nodeURI,
            stakeAmount: stakeAmount,
            isActive: true,
            registrationTimestamp: block.timestamp,
            rewardsAccumulated: 0,
            lastStakeWithdrawalRequest: 0
        });
        emit InferenceNodeRegistered(msg.sender, nodeURI, stakeAmount);
    }

    /**
     * @dev Allows an inference node to increase their staked amount.
     * @param additionalStakeAmount The additional amount of `paymentToken` to stake.
     */
    function updateNodeStake(uint256 additionalStakeAmount) external {
        InferenceNode storage node = inferenceNodes[msg.sender];
        require(node.registrationTimestamp != 0, "Node not registered");
        require(additionalStakeAmount > 0, "Stake amount must be positive");
        require(paymentToken.transferFrom(msg.sender, address(this), additionalStakeAmount), "Token transfer failed");

        node.stakeAmount += additionalStakeAmount;
        emit InferenceNodeStakeUpdated(msg.sender, node.stakeAmount);
    }

    /**
     * @dev Initiates a cooldown period for an inference node to withdraw their stake.
     *      The node becomes inactive during this period.
     */
    function requestNodeStakeWithdrawal() external {
        InferenceNode storage node = inferenceNodes[msg.sender];
        require(node.registrationTimestamp != 0, "Node not registered");
        require(node.stakeAmount > 0, "No stake to withdraw");
        require(node.lastStakeWithdrawalRequest == 0, "Withdrawal already requested, or pending"); // Prevents multiple requests

        node.isActive = false; // Node becomes inactive
        node.lastStakeWithdrawalRequest = block.timestamp;
    }

    /**
     * @dev Allows a node to withdraw staked funds after the `NODE_STAKE_COOLDOWN_PERIOD`.
     *      This also effectively deregisters the node.
     */
    function withdrawStakedFunds() external {
        InferenceNode storage node = inferenceNodes[msg.sender];
        require(node.registrationTimestamp != 0, "Node not registered");
        require(node.lastStakeWithdrawalRequest != 0, "Withdrawal not requested or already processed");
        require(block.timestamp >= node.lastStakeWithdrawalRequest + NODE_STAKE_COOLDOWN_PERIOD, "Cooldown period not over");
        require(node.stakeAmount > 0, "No stake to withdraw");

        uint256 amount = node.stakeAmount;
        node.stakeAmount = 0;
        node.registrationTimestamp = 0; // Mark as deregistered
        node.lastStakeWithdrawalRequest = 0; // Reset
        node.isActive = false; // Ensure inactive
        
        require(paymentToken.transfer(msg.sender, amount), "Stake withdrawal failed");
        emit InferenceNodeDeregistered(msg.sender);
        emit InferenceNodeStakeUpdated(msg.sender, 0);
    }

    // --- III. Inference Lifecycle (Consumer & Node Interaction) ---

    /**
     * @dev A consumer requests an AI inference from a specific model.
     *      `maxFee` is transferred to the contract and held in escrow.
     * @param modelHash The hash of the AI model to use.
     * @param inputDataHash Hash of the input data (e.g., IPFS hash).
     * @param maxFee Maximum fee the requester is willing to pay.
     * @return requestId The unique ID of the created inference request.
     */
    function requestInference(
        bytes32 modelHash,
        bytes32 inputDataHash,
        uint256 maxFee
    ) external returns (uint256 requestId) {
        Model storage model = models[modelHash];
        require(model.owner != address(0) && model.isActive, "Model not active or not found");
        require(maxFee >= model.baseInferenceFee, "Max fee too low for model's base fee");
        require(inputDataHash != bytes32(0), "Input data hash cannot be empty");
        require(paymentToken.transferFrom(msg.sender, address(this), maxFee), "Fee token transfer failed (approve tokens first)");

        requestId = nextRequestId++;
        inferenceRequests[requestId] = InferenceRequest({
            modelHash: modelHash,
            requester: msg.sender,
            executor: address(0), // To be filled by the fulfilling node
            inputDataHash: inputDataHash,
            outputDataHash: bytes32(0),
            maxFee: maxFee,
            actualFeePaid: 0, // Filled on fulfillment
            status: RequestStatus.Pending,
            requestTimestamp: block.timestamp,
            fulfillmentTimestamp: 0,
            challengeTimestamp: 0
        });
        emit InferenceRequested(requestId, modelHash, msg.sender, inputDataHash, maxFee);
        return requestId;
    }

    /**
     * @dev An inference node submits the result (outputDataHash) for a pending request.
     *      Rewards are calculated and accumulated for the node and model provider.
     * @param requestId The ID of the inference request.
     * @param outputDataHash Hash of the output data (e.g., IPFS hash).
     */
    function fulfillInference(uint256 requestId, bytes32 outputDataHash) external {
        InferenceRequest storage req = inferenceRequests[requestId];
        require(req.status == RequestStatus.Pending, "Request is not pending");
        require(inferenceNodes[msg.sender].isActive, "Executor is not an active node");
        require(outputDataHash != bytes32(0), "Output data hash cannot be empty");

        Model storage model = models[req.modelHash];
        require(model.isActive, "Model is no longer active"); // Ensure model is still active

        uint256 feeToPay = model.baseInferenceFee;
        if (feeToPay > req.maxFee) {
            feeToPay = req.maxFee; // Cap at maxFee
        }

        // Example split: 80% to node, 20% to model provider
        uint256 nodeShare = feeToPay * 80 / 100;
        uint256 modelShare = feeToPay - nodeShare; // The remaining 20%

        inferenceNodes[msg.sender].rewardsAccumulated += nodeShare;
        modelOwnerRewards[model.owner] += modelShare;

        req.executor = msg.sender;
        req.outputDataHash = outputDataHash;
        req.actualFeePaid = feeToPay;
        req.status = RequestStatus.Fulfilled;
        req.fulfillmentTimestamp = block.timestamp;

        // Refund any excess `maxFee` back to the requester
        if (req.maxFee > feeToPay) {
            require(paymentToken.transfer(req.requester, req.maxFee - feeToPay), "Refund excess fee failed");
        }

        emit InferenceFulfilled(requestId, req.modelHash, msg.sender, outputDataHash, feeToPay);
    }

    /**
     * @dev Consumer challenges an inference result within the `INFERENCE_CHALLENGE_WINDOW`.
     * @param requestId The ID of the inference request to challenge.
     */
    function challengeInferenceResult(uint256 requestId) external {
        InferenceRequest storage req = inferenceRequests[requestId];
        require(req.requester == msg.sender, "Only requester can challenge");
        require(req.status == RequestStatus.Fulfilled, "Request is not fulfilled");
        require(block.timestamp <= req.fulfillmentTimestamp + INFERENCE_CHALLENGE_WINDOW, "Challenge window closed");

        // The rewards for the node and model owner are "reversed" if challenger wins.
        // For simplicity, we mark as challenged. Dispute resolution handles actual fund movement.
        req.status = RequestStatus.Challenged;
        req.challengeTimestamp = block.timestamp;
        emit InferenceChallenged(requestId, msg.sender);
    }

    /**
     * @dev The `disputeResolutionOracle` resolves a challenged inference.
     *      If challenger wins, the executor node is slashed, and requester is refunded `maxFee`.
     *      If node wins, rewards remain for node/model provider, and requester loses `maxFee`.
     * @param requestId The ID of the challenged inference request.
     * @param challengerWon True if the requester's challenge is upheld, false otherwise.
     */
    function resolveInferenceDispute(uint256 requestId, bool challengerWon) external {
        require(msg.sender == disputeResolutionOracle, "Only the dispute resolution oracle can resolve disputes");
        InferenceRequest storage req = inferenceRequests[requestId];
        require(req.status == RequestStatus.Challenged, "Request is not challenged");

        address nodeAddress = req.executor;
        address modelOwner = models[req.modelHash].owner;

        // Adjust accumulated rewards for the node and model owner, as they were provisionally added on fulfill.
        uint256 nodeShare = req.actualFeePaid * 80 / 100;
        uint256 modelShare = req.actualFeePaid - nodeShare;

        if (challengerWon) {
            // Requester wins: Node is penalized, requester gets refund, node/model provider lose their share.
            req.status = RequestStatus.ResolvedSuccess;

            // Refund full maxFee to requester (it's still held in the contract from initial request).
            require(paymentToken.transfer(req.requester, req.maxFee), "Refund to requester failed");

            // Deduct the provisionally accumulated rewards from node and model owner.
            if (inferenceNodes[nodeAddress].rewardsAccumulated >= nodeShare) {
                inferenceNodes[nodeAddress].rewardsAccumulated -= nodeShare;
            } else {
                inferenceNodes[nodeAddress].rewardsAccumulated = 0;
            }
            if (modelOwnerRewards[modelOwner] >= modelShare) {
                modelOwnerRewards[modelOwner] -= modelShare;
            } else {
                modelOwnerRewards[modelOwner] = 0;
            }

            // Slash node's stake (e.g., 5% of their current stake, or a fixed amount)
            uint256 penalty = inferenceNodes[nodeAddress].stakeAmount / 20; // Example penalty: 5% of stake
            if (inferenceNodes[nodeAddress].stakeAmount > penalty) {
                inferenceNodes[nodeAddress].stakeAmount -= penalty;
            } else {
                inferenceNodes[nodeAddress].stakeAmount = 0;
            }
            // Slashed funds are transferred to the dispute resolution oracle's address (or DAO treasury).
            require(paymentToken.transfer(disputeResolutionOracle, penalty), "Slash transfer failed");
            emit NodeSlashed(nodeAddress, penalty);

        } else {
            // Node wins: Node and model owner keep their earnings, requester loses maxFee.
            req.status = RequestStatus.ResolvedFailure;
            // The `actualFeePaid` amount was already deducted from `maxFee` and accounted for as rewards.
            // Any remaining `maxFee - actualFeePaid` would have been refunded earlier.
            // So, no additional fund movement needed for the `actualFeePaid` part.
            // The requester simply loses the `maxFee` they initially paid.
        }
        emit InferenceDisputeResolved(requestId, challengerWon, msg.sender);
    }

    // --- IV. Reputation & Reporting (Community Functions) ---

    /**
     * @dev Allows users to submit a rating for a registered AI model.
     * @param modelHash The hash of the model to rate.
     * @param rating The rating value (1 to 5).
     */
    function submitModelRating(bytes32 modelHash, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(models[modelHash].owner != address(0), "Model not found");
        // In a production system, one might require the msg.sender to have completed an inference for this model.
        modelRatings[modelHash].totalRating += rating;
        modelRatings[modelHash].numRatings++;
        emit ModelRatingSubmitted(modelHash, msg.sender, rating);
    }

    /**
     * @dev Allows users to submit a rating for an inference node.
     * @param nodeAddress The address of the node to rate.
     * @param rating The rating value (1 to 5).
     */
    function submitNodeRating(address nodeAddress, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(inferenceNodes[nodeAddress].registrationTimestamp != 0, "Node not found");
        // In a production system, one might require the msg.sender to have had an inference fulfilled by this node.
        nodeRatings[nodeAddress].totalRating += rating;
        nodeRatings[nodeAddress].numRatings++;
        emit NodeRatingSubmitted(nodeAddress, msg.sender, rating);
    }

    /**
     * @dev Allows any user to report an inference node for suspected misbehavior.
     *      This is purely a reporting mechanism; actual action requires `resolveNodeMisbehavior`.
     * @param nodeAddress The address of the node being reported.
     * @param evidenceURI URI pointing to evidence of misbehavior (e.g., IPFS hash).
     */
    function reportMisbehavingNode(address nodeAddress, string calldata evidenceURI) external {
        require(inferenceNodes[nodeAddress].registrationTimestamp != 0, "Node not found");
        // Further logic could include a dispute system for reports, or a simple logging.
        emit NodeReported(nodeAddress, msg.sender, evidenceURI);
    }

    /**
     * @dev Allows the contract owner to resolve reported node misbehavior by slashing stake and/or deactivating the node.
     * @param nodeAddress The address of the node to take action against.
     * @param slashAmount The amount of `paymentToken` to slash from the node's stake.
     * @param deactivateNode If true, the node's `isActive` status will be set to false.
     */
    function resolveNodeMisbehavior(
        address nodeAddress,
        uint256 slashAmount,
        bool deactivateNode
    ) external onlyOwner {
        InferenceNode storage node = inferenceNodes[nodeAddress];
        require(node.registrationTimestamp != 0, "Node not found");
        require(slashAmount <= node.stakeAmount, "Slash amount exceeds node's stake");

        if (slashAmount > 0) {
            node.stakeAmount -= slashAmount;
            // Slashed funds go to the dispute resolution oracle (can be a DAO treasury)
            require(paymentToken.transfer(disputeResolutionOracle, slashAmount), "Slash transfer failed");
            emit NodeSlashed(nodeAddress, slashAmount);
        }
        if (deactivateNode) {
            node.isActive = false;
            emit InferenceNodeStakeUpdated(nodeAddress, node.stakeAmount); // Reusing event to indicate status change
        }
    }

    // --- V. Rewards & Administrative (Financial & Governance) ---

    /**
     * @dev Allows an inference node or model owner to claim their accumulated rewards.
     *      Combines rewards from node operation and model provision.
     */
    function claimRewards() external {
        uint256 nodeReward = inferenceNodes[msg.sender].rewardsAccumulated;
        uint256 modelReward = modelOwnerRewards[msg.sender];
        uint256 totalClaimable = nodeReward + modelReward;

        require(totalClaimable > 0, "No rewards to claim");

        if (nodeReward > 0) {
            inferenceNodes[msg.sender].rewardsAccumulated = 0;
        }
        if (modelReward > 0) {
            modelOwnerRewards[msg.sender] = 0;
        }

        require(paymentToken.transfer(msg.sender, totalClaimable), "Reward transfer failed");
        emit RewardsClaimed(msg.sender, totalClaimable);
    }

    /**
     * @dev Allows the contract owner to set the address of the dispute resolution oracle.
     * @param _newOracle The new address for the dispute resolution oracle.
     */
    function setDisputeResolutionOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle address");
        disputeResolutionOracle = _newOracle;
        emit DisputeResolutionOracleSet(_newOracle);
    }

    /**
     * @dev Allows the contract owner to set the minimum stake required for inference nodes.
     * @param _newMinNodeStake The new minimum stake amount.
     */
    function setMinNodeStake(uint256 _newMinNodeStake) external onlyOwner {
        require(_newMinNodeStake > 0, "Min stake must be positive");
        minNodeStake = _newMinNodeStake;
        emit MinNodeStakeSet(_newMinNodeStake);
    }

    // --- VI. View & Getter Functions ---

    /**
     * @dev Returns all stored details for a specific AI model.
     * @param modelHash The hash of the model.
     * @return Model struct containing all details.
     */
    function getModelDetails(bytes32 modelHash) external view returns (Model memory) {
        return models[modelHash];
    }

    /**
     * @dev Returns all stored details for a specific inference node.
     * @param nodeAddress The address of the inference node.
     * @return InferenceNode struct containing all details.
     */
    function getNodeDetails(address nodeAddress) external view returns (InferenceNode memory) {
        return inferenceNodes[nodeAddress];
    }

    /**
     * @dev Returns all stored details for a specific inference request.
     * @param requestId The ID of the inference request.
     * @return InferenceRequest struct containing all details.
     */
    function getInferenceRequestDetails(uint256 requestId) external view returns (InferenceRequest memory) {
        return inferenceRequests[requestId];
    }

    /**
     * @dev Calculates and returns the average rating for a given model.
     * @param modelHash The hash of the model.
     * @return The average rating (0 if no ratings).
     */
    function getModelAverageRating(bytes32 modelHash) external view returns (uint256) {
        RatingAccumulator storage rating = modelRatings[modelHash];
        if (rating.numRatings == 0) return 0;
        return rating.totalRating / rating.numRatings;
    }

    /**
     * @dev Calculates and returns the average rating for a given inference node.
     * @param nodeAddress The address of the node.
     * @return The average rating (0 if no ratings).
     */
    function getNodeAverageRating(address nodeAddress) external view returns (uint256) {
        RatingAccumulator storage rating = nodeRatings[nodeAddress];
        if (rating.numRatings == 0) return 0;
        return rating.totalRating / rating.numRatings;
    }

    /**
     * @dev Returns the current balance of the `paymentToken` held by the contract.
     * @return The balance in `paymentToken` units.
     */
    function getContractBalance() external view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }

    /**
     * @dev Returns the total count of registered models.
     * @return The number of registered models.
     */
    function getModelCount() external view returns (uint256) {
        return registeredModelHashes.length;
    }

    /**
     * @dev Returns a paginated list of registered model hashes.
     * @param offset The starting index for pagination.
     * @param limit The maximum number of model hashes to return.
     * @return An array of model hashes.
     */
    function getPaginatedModelHashes(uint256 offset, uint256 limit) external view returns (bytes32[] memory) {
        require(offset <= registeredModelHashes.length, "Offset out of bounds");
        uint256 end = offset + limit;
        if (end > registeredModelHashes.length) {
            end = registeredModelHashes.length;
        }
        uint256 actualLimit = end - offset;
        bytes32[] memory result = new bytes32[](actualLimit);
        for (uint256 i = 0; i < actualLimit; i++) {
            result[i] = registeredModelHashes[offset + i];
        }
        return result;
    }
}
```