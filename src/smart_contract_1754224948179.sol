```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AetherWeaver
 * @author [Your Name/Alias]
 * @notice AetherWeaver is a decentralized protocol for orchestrating verifiable AI model inference.
 *         It functions as a trust-minimized bridge connecting "Model Providers" (who register and manage AI model
 *         descriptors as unique, mutable NFTs) with "Inferencers" (off-chain agents responsible for performing
 *         the actual AI computations). Users can request inferences, paying on-chain, and Inferencers submit
 *         results along with Zero-Knowledge Proofs (ZKPs) for on-chain verification.
 *         The protocol handles payment distribution, stake management, dispute resolution, and fosters
 *         a robust, transparent, and incentive-aligned marketplace for AI computation.
 *
 * @dev This contract leverages advanced concepts to enable a sophisticated AI compute marketplace:
 *      - **Dynamic NFTs (Internal Representation):** Each AI model is represented by a unique, mutable identifier
 *        within the contract, akin to an ERC721 NFT, allowing for metadata updates, ownership transfer, and pricing adjustments.
 *      - **Verifiable Computing with ZKPs:** Integrates with an external ZK-Snark verifier contract. Inferencers are
 *        required to submit cryptographic proofs (e.g., proving correct execution of a specific model, or privacy-preserving
 *        input processing) alongside their results. The contract verifies these proofs on-chain, ensuring trust in computation.
 *      - **Incentive Alignment & Slashing:** Inferencers stake collateral, which can be slashed for fraudulent or
 *        incorrect submissions, aligning their incentives with truthful computation. Model creators earn fees from usage.
 *      - **Decentralized Oracle-like System:** While not a generic oracle, it orchestrates specific off-chain computation
 *        (AI inference) and provides robust on-chain verification mechanisms.
 *      - **Basic Reputation System:** Allows users to attest to the quality of models and reliability of inferencers,
 *        contributing to a community-driven reputation.
 *      - **Agent Orchestration:** Provides mechanisms for automated AI agent systems to interact with the protocol
 *        efficiently, enabling batching of requests and results.
 */

// --- OUTLINE ---
// 1. Interface Definitions: External contracts (ZKP Verifier).
// 2. Error Definitions: Custom error types for specific failure conditions.
// 3. Event Definitions: Events emitted for tracking contract activities.
// 4. Struct Definitions: Data structures for Models, Inference Requests, Agents, etc.
// 5. Modifiers: Custom access control and state modifiers.
// 6. Main Contract (AetherWeaver):
//    - State Variables: Storage for contract data.
//    - Constructor: Initializes contract parameters.
//    - Function Categories:
//        I. Model Management (NFT-like)
//        II. Inference Request & Fulfillment
//        III. Reputation & Slashing (internal utilities)
//        IV. Protocol Configuration & Governance
//        V. Agent Integration

// --- FUNCTION SUMMARY ---

// I. Model Management (NFT-like)
// 1.  `registerAIModel(string memory _metadataURI, bytes32 _inputSchemaHash, bytes32 _outputSchemaHash, uint256 _basePrice)`:
//     Registers a new AI model, mints a unique model ID (NFT-like token), and sets its initial parameters.
//     Model creators receive a unique identifier for their model.
// 2.  `updateModelMetadataURI(uint256 _modelId, string memory _newMetadataURI)`:
//     Allows the model creator to update the metadata URI associated with their AI model,
//     pointing to updated off-chain details.
// 3.  `setModelInferencePrice(uint256 _modelId, uint256 _newPrice)`:
//     Enables the model creator to adjust the base price for inferences using their model.
// 4.  `retireAIModel(uint256 _modelId)`:
//     Marks an AI model as retired, preventing new inference requests from being made for it.
// 5.  `transferModelOwnership(uint256 _modelId, address _newOwner)`:
//     Transfers the ownership of an AI model's unique ID (NFT-like token) to a new address.
// 6.  `withdrawModelCreatorFees(uint256 _modelId)`:
//     Allows a model creator to withdraw the accumulated fees earned from successful inferences of their model.

// II. Inference Request & Fulfillment
// 7.  `requestInference(uint256 _modelId, bytes32 _inputDataHash, uint256 _maxGasCost, bytes memory _expectedZKPType)`:
//     Initiates an inference request for a specific AI model. The user deposits the inference fee + an optional gas allowance.
//     Specifies the hash of input data, a maximum gas cost for inferencer's proof submission, and the expected ZKP type.
// 8.  `acceptInferenceRequest(uint256 _requestId, uint256 _inferencerStake)`:
//     An off-chain "Inferencer Agent" claims an open inference request, staking collateral as a commitment.
// 9.  `submitInferenceResult(uint256 _requestId, bytes32 _outputDataHash, uint256[] memory _publicSignals, uint256[8] memory _proof)`:
//     The Inferencer submits the computed output hash and a Zero-Knowledge Proof (ZKP) to verify the correctness of computation.
// 10. `verifyAndFinalizeInference(uint256 _requestId)`:
//     Triggers the on-chain verification of the submitted ZKP. If successful, the request is finalized,
//     and payments are distributed to the inferencer and model creator.
// 11. `raiseInferenceDispute(uint256 _requestId)`:
//     Allows the requestor to raise a dispute against a submitted inference result within a cooldown period,
//     locking the inferencer's stake and the payment.
// 12. `resolveInferenceDispute(uint256 _requestId, bool _inferencerGuilty)`:
//     The protocol owner (or a DAO) resolves an active dispute, determining if the inferencer's stake should be slashed
//     or if they should receive payment.
// 13. `cancelInferenceRequest(uint256 _requestId)`:
//     Allows the requestor to cancel an unaccepted inference request, refunding their deposited funds.
// 14. `claimInferencerPayment(uint256 _requestId)`:
//     Allows the inferencer to claim their payment and unstake their collateral after successful completion.

// III. Reputation & Slashing (Direct interaction for attestation, slashing via dispute resolution)
// 15. `attestToModelQuality(uint256 _modelId, bool _isPositive)`:
//     Allows users who have used a model to provide feedback on its quality (e.g., accuracy, reliability).
// 16. `attestToInferencerReliability(address _inferencer, bool _isPositive)`:
//     Allows users to provide feedback on the reliability and performance of an inferencer.

// IV. Protocol Configuration & Governance
// 17. `setZKPVerifierAddress(address _newVerifier)`:
//     Sets the address of the external Zero-Knowledge Proof verifier contract used by AetherWeaver.
// 18. `updateProtocolFee(uint16 _newFeeBps)`:
//     Updates the protocol fee percentage (in basis points) taken from each successful inference.
// 19. `withdrawProtocolFees()`:
//     Allows the protocol owner (or DAO) to withdraw accumulated fees from the contract.

// V. Agent Integration
// 20. `registerAgentSystem(string memory _agentName, uint256 _agentBond)`:
//     Allows an autonomous agent system to register with the protocol, requiring a bond for accountability.
// 21. `agentBatchRequestInference(uint256[] memory _modelIds, bytes32[] memory _inputDataHashes, uint256[] memory _maxGasCosts, bytes[] memory _expectedZKPTypes)`:
//     Enables a registered agent to submit multiple inference requests in a single transaction, optimizing gas.
// 22. `agentBatchSubmitResults(uint256[] memory _requestIds, bytes32[] memory _outputDataHashes, uint256[][] memory _batchPublicSignals, uint256[8][] memory _batchProofs)`:
//     Allows a registered agent to submit results and proofs for multiple inference requests concurrently.

interface IZKPVerifier {
    /**
     * @notice Verifies a Zero-Knowledge Proof.
     * @param publicSignals An array of public inputs for the ZKP circuit.
     * @param proof An array representing the ZKP itself.
     * @return bool True if the proof is valid, false otherwise.
     * @dev The exact signature and type of publicSignals/proof will depend on the chosen ZKP system (e.g., Groth16, Plonk)
     *      and the specific circuit used for verifying AI inference. For this contract, we assume a generic verification endpoint.
     */
    function verifyProof(
        uint256[] calldata publicSignals,
        uint256[8] calldata proof
    ) external view returns (bool);
}

// --- Error Definitions ---
error InvalidModelId();
error ModelNotActive();
error ModelOwnershipMismatch();
error InvalidPrice();
error InsufficientFunds();
error RequestNotFound();
error RequestAlreadyAccepted();
error RequestNotAccepted();
error InferencerStakeTooLow();
error InvalidInferencer();
error ResultNotSubmitted();
error ZKPVerificationFailed();
error RequestAlreadyFinalized();
error RequestNotDisputable();
error DisputeAlreadyRaised();
error DisputeNotActive();
error InvalidDisputeResolution();
error RequestCannotBeCanceled();
error PaymentAlreadyClaimed();
error CallerNotAgent();
error AgentAlreadyRegistered();
error AgentBondTooLow();
error BatchLengthMismatch();
error UnauthorizedAccess(); // For internal functions with specific caller requirements
error ZeroAddress();
error ProtocolFeeTooHigh();


contract AetherWeaver is Ownable, ReentrancyGuard {

    // --- Struct Definitions ---

    // Represents an AI model registered on the platform (NFT-like)
    struct AIModel {
        address owner; // The creator/owner of the model
        string metadataURI; // URI pointing to off-chain model description, input/output schemas, etc.
        bytes32 inputSchemaHash; // Hash of the expected input data schema
        bytes32 outputSchemaHash; // Hash of the expected output data schema
        uint256 basePrice; // Base price for a single inference using this model
        bool active; // Is the model available for new requests?
        uint256 accumulatedCreatorFees; // Fees accumulated for the model creator
    }

    enum RequestStatus {
        Open,           // Request initiated, awaiting acceptance
        Accepted,       // Request accepted by an inferencer, awaiting result
        ResultSubmitted,// Result and ZKP submitted, awaiting verification/finalization
        Disputed,       // Result disputed, awaiting resolution
        Finalized,      // Request completed successfully, funds distributed
        Canceled,       // Request canceled by initiator
        Failed          // Request failed (e.g., ZKP failed, inferencer slashed)
    }

    // Represents an AI inference request
    struct InferenceRequest {
        uint256 modelId; // ID of the AI model to use
        address requestor; // Address of the user who requested the inference
        address inferencer; // Address of the inferencer who accepted the request
        bytes32 inputDataHash; // Hash of the input data (actual data off-chain)
        bytes32 outputDataHash; // Hash of the output data (actual data off-chain)
        uint256 totalPayment; // Total ETH paid by the requestor (model price + gas allowance + protocol fee)
        uint256 inferencerStake; // ETH staked by the inferencer
        uint256 requestTime; // Timestamp when the request was made
        uint256 acceptanceTime; // Timestamp when inferencer accepted the request
        uint256 resultSubmissionTime; // Timestamp when result was submitted
        uint256 maxGasCost; // Max gas cost the requestor is willing to pay for proof submission
        bytes expectedZKPType; // Identifier for the expected ZKP circuit/type
        RequestStatus status; // Current status of the request
        bool inferencerPaid; // True if inferencer claimed payment
        bool creatorPaid; // True if creator claimed payment
        // For ZKP verification
        uint256[] publicSignals;
        uint256[8] proof;
    }

    // Represents an automated agent system
    struct AgentSystem {
        string name;
        uint256 bond; // ETH bond required for an agent system
        address agentAddress; // The address associated with the agent system
        bool isActive;
    }

    // --- State Variables ---
    uint256 public nextModelId;
    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => address) public modelOwners; // Mapping from modelId to its owner

    uint256 public nextRequestId;
    mapping(uint256 => InferenceRequest) public inferenceRequests;

    address public zkpVerifierAddress; // Address of the external ZKP verifier contract
    uint16 public protocolFeeBps; // Protocol fee in basis points (e.g., 100 = 1%)
    uint256 public accumulatedProtocolFees;

    uint256 public constant INFERENCE_ACCEPTANCE_TIMEOUT = 1 hours; // Time for inferencer to accept
    uint256 public constant RESULT_SUBMISSION_TIMEOUT = 12 hours; // Time for inferencer to submit result after acceptance
    uint256 public constant DISPUTE_COOLDOWN_PERIOD = 24 hours; // Time for requestor to raise dispute after result submission

    // Reputation system mappings
    // (modelId => address => bool) true for positive, false for negative attestation
    mapping(uint256 => mapping(address => bool)) public modelQualityAttestations;
    // (address => address => bool) true for positive, false for negative attestation
    mapping(address => mapping(address => bool)) public inferencerReliabilityAttestations;

    mapping(address => AgentSystem) public agentSystems; // Registered agent systems

    // --- Events ---
    event ModelRegistered(uint256 indexed modelId, address indexed owner, string metadataURI, uint256 basePrice);
    event ModelMetadataUpdated(uint256 indexed modelId, string newMetadataURI);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 newPrice);
    event ModelRetired(uint256 indexed modelId);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed oldOwner, address indexed newOwner);
    event ModelCreatorFeesWithdrawn(uint256 indexed modelId, address indexed creator, uint256 amount);

    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requestor, uint256 totalPayment);
    event InferenceAccepted(uint256 indexed requestId, address indexed inferencer, uint256 inferencerStake);
    event InferenceResultSubmitted(uint256 indexed requestId, address indexed inferencer, bytes32 outputDataHash);
    event InferenceFinalized(uint256 indexed requestId, address indexed inferencer, address indexed requestor);
    event InferenceDisputeRaised(uint256 indexed requestId, address indexed requestor);
    event InferenceDisputeResolved(uint256 indexed requestId, address indexed inferencer, bool inferencerGuilty);
    event InferenceCanceled(uint256 indexed requestId);
    event InferencerPaymentClaimed(uint256 indexed requestId, address indexed inferencer, uint256 amount);

    event ZKPVerifierAddressUpdated(address oldAddress, address newAddress);
    event ProtocolFeeUpdated(uint16 oldFeeBps, uint16 newFeeBps);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    event ModelQualityAttested(uint256 indexed modelId, address indexed attester, bool isPositive);
    event InferencerReliabilityAttested(address indexed inferencer, address indexed attester, bool isPositive);
    event InferencerStakeSlashed(address indexed inferencer, uint256 amount, uint256 indexed requestId);

    event AgentRegistered(address indexed agentAddress, string agentName, uint256 bond);


    // --- Constructor ---
    constructor(address _initialZKPVerifierAddress, uint16 _initialProtocolFeeBps) Ownable(msg.sender) {
        if (_initialZKPVerifierAddress == address(0)) revert ZeroAddress();
        if (_initialProtocolFeeBps > 10000) revert ProtocolFeeTooHigh(); // Max 100%

        zkpVerifierAddress = _initialZKPVerifierAddress;
        protocolFeeBps = _initialProtocolFeeBps;
        nextModelId = 1; // Start model IDs from 1
        nextRequestId = 1; // Start request IDs from 1
    }

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _modelId) {
        if (modelOwners[_modelId] != msg.sender) revert ModelOwnershipMismatch();
        _;
    }

    modifier onlyRequestor(uint256 _requestId) {
        if (inferenceRequests[_requestId].requestor != msg.sender) revert UnauthorizedAccess();
        _;
    }

    modifier onlyInferencer(uint256 _requestId) {
        if (inferenceRequests[_requestId].inferencer != msg.sender) revert UnauthorizedAccess();
        _;
    }

    modifier onlyAgentSystem(address _agentAddress) {
        if (agentSystems[_agentAddress].agentAddress == address(0) || !agentSystems[_agentAddress].isActive)
            revert CallerNotAgent();
        _;
    }


    // --- I. Model Management (NFT-like) ---

    /**
     * @notice Registers a new AI model on the platform. Mints a unique model ID (NFT-like token) and sets its initial parameters.
     * @dev The new model is automatically owned by `msg.sender`.
     * @param _metadataURI URI pointing to off-chain model metadata (e.g., IPFS hash).
     * @param _inputSchemaHash Hash of the model's expected input data schema.
     * @param _outputSchemaHash Hash of the model's expected output data schema.
     * @param _basePrice The base price (in wei) for performing an inference with this model.
     */
    function registerAIModel(
        string memory _metadataURI,
        bytes32 _inputSchemaHash,
        bytes32 _outputSchemaHash,
        uint256 _basePrice
    ) external nonReentrant {
        if (_basePrice == 0) revert InvalidPrice();

        uint256 newModelId = nextModelId++;
        aiModels[newModelId] = AIModel({
            owner: msg.sender,
            metadataURI: _metadataURI,
            inputSchemaHash: _inputSchemaHash,
            outputSchemaHash: _outputSchemaHash,
            basePrice: _basePrice,
            active: true,
            accumulatedCreatorFees: 0
        });
        modelOwners[newModelId] = msg.sender;

        emit ModelRegistered(newModelId, msg.sender, _metadataURI, _basePrice);
    }

    /**
     * @notice Allows the model creator to update the metadata URI for their AI model.
     * @dev This enables dynamic updates to off-chain model descriptions without re-registering.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new URI for the model's metadata.
     */
    function updateModelMetadataURI(uint256 _modelId, string memory _newMetadataURI)
        external
        onlyModelOwner(_modelId)
    {
        if (aiModels[_modelId].owner == address(0)) revert InvalidModelId(); // Check if model exists

        aiModels[_modelId].metadataURI = _newMetadataURI;
        emit ModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @notice Enables the model creator to adjust the base price for inferences using their model.
     * @param _modelId The ID of the model to update.
     * @param _newPrice The new base price (in wei) for inferences.
     */
    function setModelInferencePrice(uint256 _modelId, uint256 _newPrice)
        external
        onlyModelOwner(_modelId)
    {
        if (aiModels[_modelId].owner == address(0)) revert InvalidModelId(); // Check if model exists
        if (_newPrice == 0) revert InvalidPrice();

        aiModels[_modelId].basePrice = _newPrice;
        emit ModelPriceUpdated(_modelId, _newPrice);
    }

    /**
     * @notice Marks an AI model as retired, preventing new inference requests from being made for it.
     * @dev Existing requests for a retired model can still be completed.
     * @param _modelId The ID of the model to retire.
     */
    function retireAIModel(uint256 _modelId) external onlyModelOwner(_modelId) {
        if (aiModels[_modelId].owner == address(0)) revert InvalidModelId(); // Check if model exists
        if (!aiModels[_modelId].active) revert ModelNotActive(); // Already retired

        aiModels[_modelId].active = false;
        emit ModelRetired(_modelId);
    }

    /**
     * @notice Transfers the ownership of an AI model's unique ID (NFT-like token) to a new address.
     * @param _modelId The ID of the model to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferModelOwnership(uint256 _modelId, address _newOwner)
        external
        onlyModelOwner(_modelId)
        nonReentrant
    {
        if (aiModels[_modelId].owner == address(0)) revert InvalidModelId();
        if (_newOwner == address(0)) revert ZeroAddress();

        address oldOwner = aiModels[_modelId].owner;
        aiModels[_modelId].owner = _newOwner;
        modelOwners[_modelId] = _newOwner; // Update direct mapping for easy lookup

        emit ModelOwnershipTransferred(_modelId, oldOwner, _newOwner);
    }

    /**
     * @notice Allows a model creator to withdraw the accumulated fees earned from successful inferences of their model.
     * @param _modelId The ID of the model for which to withdraw fees.
     */
    function withdrawModelCreatorFees(uint256 _modelId) external onlyModelOwner(_modelId) nonReentrant {
        if (aiModels[_modelId].owner == address(0)) revert InvalidModelId(); // Check if model exists

        uint256 amount = aiModels[_modelId].accumulatedCreatorFees;
        if (amount == 0) return; // Nothing to withdraw

        aiModels[_modelId].accumulatedCreatorFees = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            aiModels[_modelId].accumulatedCreatorFees = amount; // Refund on failure
            revert ("Withdrawal failed"); // Revert if transfer fails
        }
        emit ModelCreatorFeesWithdrawn(_modelId, msg.sender, amount);
    }

    // --- II. Inference Request & Fulfillment ---

    /**
     * @notice Initiates an inference request for a specific AI model.
     * @dev The user deposits the inference fee, which includes the model's base price, a protocol fee,
     *      and an optional `_maxGasCost` to cover the inferencer's ZKP submission gas.
     * @param _modelId The ID of the AI model to use.
     * @param _inputDataHash Hash of the off-chain input data.
     * @param _maxGasCost Maximum gas cost the requestor is willing to pay for inferencer's result submission transaction.
     * @param _expectedZKPType Identifier for the expected ZKP circuit/type (bytes for flexibility).
     */
    function requestInference(
        uint256 _modelId,
        bytes32 _inputDataHash,
        uint256 _maxGasCost,
        bytes memory _expectedZKPType
    ) external payable nonReentrant {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0) || !model.active) revert ModelNotActive();

        uint256 protocolFee = (model.basePrice * protocolFeeBps) / 10000;
        uint256 requiredPayment = model.basePrice + protocolFee + _maxGasCost;

        if (msg.value < requiredPayment) revert InsufficientFunds();

        uint256 newRequestId = nextRequestId++;
        inferenceRequests[newRequestId] = InferenceRequest({
            modelId: _modelId,
            requestor: msg.sender,
            inferencer: address(0), // No inferencer yet
            inputDataHash: _inputDataHash,
            outputDataHash: 0, // No output yet
            totalPayment: msg.value, // Store exact sent value
            inferencerStake: 0, // No stake yet
            requestTime: block.timestamp,
            acceptanceTime: 0,
            resultSubmissionTime: 0,
            maxGasCost: _maxGasCost,
            expectedZKPType: _expectedZKPType,
            status: RequestStatus.Open,
            inferencerPaid: false,
            creatorPaid: false,
            publicSignals: new uint256[](0), // Initialize empty
            proof: [0, 0, 0, 0, 0, 0, 0, 0] // Initialize empty
        });

        accumulatedProtocolFees += protocolFee; // Accumulate protocol fees
        // Excess funds (msg.value - requiredPayment) remain in contract for later refund/distribution
        // or could be immediately refunded here. For simplicity, let it stay, will be handled on completion/cancellation.

        emit InferenceRequested(newRequestId, _modelId, msg.sender, msg.value);
    }

    /**
     * @notice An off-chain "Inferencer Agent" claims an open inference request, staking collateral as a commitment.
     * @dev The `_inferencerStake` must be deposited along with this call. This stake is locked until the request is finalized.
     * @param _requestId The ID of the inference request to accept.
     * @param _inferencerStake The amount of ETH the inferencer stakes as collateral.
     */
    function acceptInferenceRequest(uint256 _requestId, uint256 _inferencerStake) external payable nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != RequestStatus.Open) revert RequestAlreadyAccepted();
        if (request.requestor == address(0)) revert RequestNotFound(); // Ensure request exists

        if (msg.value < _inferencerStake) revert InsufficientFunds();
        if (msg.value > _inferencerStake) {
            // Refund any excess ETH sent by inferencer
            (bool success, ) = msg.sender.call{value: msg.value - _inferencerStake}("");
            if (!success) {
                // This shouldn't happen if msg.sender is regular EOA, but important for contracts
                revert ("Excess fund refund failed");
            }
        }
        if (_inferencerStake == 0) revert InferencerStakeTooLow(); // Require minimum stake

        request.inferencer = msg.sender;
        request.inferencerStake = _inferencerStake;
        request.acceptanceTime = block.timestamp;
        request.status = RequestStatus.Accepted;

        emit InferenceAccepted(_requestId, msg.sender, _inferencerStake);
    }

    /**
     * @notice The Inferencer submits the computed output hash and a Zero-Knowledge Proof (ZKP) to verify the correctness of computation.
     * @dev This function only stores the result. `verifyAndFinalizeInference` will trigger actual ZKP verification.
     * @param _requestId The ID of the inference request.
     * @param _outputDataHash The hash of the off-chain output data.
     * @param _publicSignals The public inputs for the ZKP circuit.
     * @param _proof The ZKP itself.
     */
    function submitInferenceResult(
        uint256 _requestId,
        bytes32 _outputDataHash,
        uint256[] memory _publicSignals,
        uint256[8] memory _proof
    ) external onlyInferencer(_requestId) nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != RequestStatus.Accepted) revert RequestNotAccepted();
        if (block.timestamp > request.acceptanceTime + RESULT_SUBMISSION_TIMEOUT) {
            request.status = RequestStatus.Failed; // Inferencer timed out
            _slashInferencerStake(_requestId, request.inferencerStake); // Slash for timeout
            revert ("Result submission timeout");
        }

        request.outputDataHash = _outputDataHash;
        request.publicSignals = _publicSignals;
        request.proof = _proof;
        request.resultSubmissionTime = block.timestamp;
        request.status = RequestStatus.ResultSubmitted;

        emit InferenceResultSubmitted(_requestId, msg.sender, _outputDataHash);
    }

    /**
     * @notice Triggers the on-chain verification of the submitted ZKP. If successful, the request is finalized,
     *         and payments are distributed to the inferencer and model creator.
     * @dev Can be called by anyone after a result is submitted.
     * @param _requestId The ID of the inference request to finalize.
     */
    function verifyAndFinalizeInference(uint256 _requestId) external nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != RequestStatus.ResultSubmitted) revert ResultNotSubmitted();
        if (request.requestor == address(0)) revert RequestNotFound(); // Ensure request exists

        IZKPVerifier verifier = IZKPVerifier(zkpVerifierAddress);
        bool verificationSuccess = verifier.verifyProof(request.publicSignals, request.proof);

        if (!verificationSuccess) {
            request.status = RequestStatus.Failed;
            _slashInferencerStake(_requestId, request.inferencerStake); // Slash if ZKP fails
            revert ZKPVerificationFailed();
        }

        // Distribute payments
        AIModel storage model = aiModels[request.modelId];
        uint256 modelCreatorShare = model.basePrice;
        uint256 protocolFee = (model.basePrice * protocolFeeBps) / 10000;
        uint256 inferencerPayment = model.basePrice + request.maxGasCost;
        uint256 excessFunds = request.totalPayment - (modelCreatorShare + protocolFee + request.maxGasCost);

        // Send excess funds back to requestor if any
        if (excessFunds > 0) {
            (bool success, ) = request.requestor.call{value: excessFunds}("");
            if (!success) {
                // Not critical, but means requestor didn't get full refund of excess
                // For a production system, better error handling or re-attempt mechanism needed.
            }
        }

        // Accumulate model creator fees
        model.accumulatedCreatorFees += modelCreatorShare;

        request.status = RequestStatus.Finalized;
        // Inferencer still needs to claim payment manually with `claimInferencerPayment`
        // Requestor's part of funds (model price, gas cost, protocol fee) is processed here.
        // The inferencer's stake is released when they claim payment.

        emit InferenceFinalized(_requestId, request.inferencer, request.requestor);
    }

    /**
     * @notice Allows the requestor to raise a dispute against a submitted inference result within a cooldown period.
     * @dev Locks the inferencer's stake and the payment until the dispute is resolved by the protocol owner.
     * @param _requestId The ID of the inference request to dispute.
     */
    function raiseInferenceDispute(uint256 _requestId) external onlyRequestor(_requestId) nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != RequestStatus.ResultSubmitted) revert RequestNotDisputable();
        if (block.timestamp > request.resultSubmissionTime + DISPUTE_COOLDOWN_PERIOD) revert RequestNotDisputable();

        request.status = RequestStatus.Disputed;
        emit InferenceDisputeRaised(_requestId, msg.sender);
    }

    /**
     * @notice The protocol owner (or a DAO) resolves an active dispute.
     * @dev Determines if the inferencer's stake should be slashed or if they should receive payment.
     *      This implies an off-chain arbitration mechanism determines the `_inferencerGuilty` outcome.
     * @param _requestId The ID of the disputed inference request.
     * @param _inferencerGuilty True if the inferencer is found guilty (stake slashed), false otherwise (payment proceeds).
     */
    function resolveInferenceDispute(uint256 _requestId, bool _inferencerGuilty) external onlyOwner nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != RequestStatus.Disputed) revert DisputeNotActive();

        if (_inferencerGuilty) {
            _slashInferencerStake(_requestId, request.inferencerStake);
            request.status = RequestStatus.Failed; // Mark as failed due to dispute
        } else {
            // If not guilty, proceed to finalize as if ZKP passed (even if it didn't, dispute overrides)
            // This assumes the off-chain resolution considers other factors beyond ZKP.
            AIModel storage model = aiModels[request.modelId];
            uint256 modelCreatorShare = model.basePrice;
            uint256 protocolFee = (model.basePrice * protocolFeeBps) / 10000;
            uint256 excessFunds = request.totalPayment - (modelCreatorShare + protocolFee + request.maxGasCost);

            if (excessFunds > 0) {
                (bool success, ) = request.requestor.call{value: excessFunds}("");
                if (!success) {} // Handle failure gracefully
            }
            model.accumulatedCreatorFees += modelCreatorShare;
            request.status = RequestStatus.Finalized;
        }

        emit InferenceDisputeResolved(_requestId, request.inferencer, _inferencerGuilty);
    }

    /**
     * @notice Allows the requestor to cancel an unaccepted inference request.
     * @dev Refunds their deposited funds if the request has not yet been accepted by an inferencer.
     * @param _requestId The ID of the inference request to cancel.
     */
    function cancelInferenceRequest(uint256 _requestId) external onlyRequestor(_requestId) nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != RequestStatus.Open) revert RequestCannotBeCanceled();

        request.status = RequestStatus.Canceled;
        (bool success, ) = request.requestor.call{value: request.totalPayment}("");
        if (!success) revert ("Refund failed");

        emit InferenceCanceled(_requestId);
    }

    /**
     * @notice Allows the inferencer to claim their payment and unstake their collateral after successful completion.
     * @param _requestId The ID of the inference request for which to claim payment.
     */
    function claimInferencerPayment(uint256 _requestId) external onlyInferencer(_requestId) nonReentrant {
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != RequestStatus.Finalized) revert RequestNotFinalized();
        if (request.inferencerPaid) revert PaymentAlreadyClaimed();

        // Inferencer receives model price + max gas cost + their staked amount
        uint224 paymentAmount = uint224(aiModels[request.modelId].basePrice + request.maxGasCost + request.inferencerStake);
        request.inferencerPaid = true;

        (bool success, ) = request.inferencer.call{value: paymentAmount}("");
        if (!success) {
            request.inferencerPaid = false; // Revert payment claimed status
            revert ("Payment claim failed");
        }
        emit InferencerPaymentClaimed(_requestId, msg.sender, paymentAmount);
    }

    // --- III. Reputation & Slashing ---

    /**
     * @notice Allows users who have used a model to provide feedback on its quality.
     * @dev This is a basic attestation system. Can be extended with weighted attestations or SBTs.
     * @param _modelId The ID of the model being attested.
     * @param _isPositive True for a positive attestation, false for a negative one.
     */
    function attestToModelQuality(uint256 _modelId, bool _isPositive) external nonReentrant {
        if (aiModels[_modelId].owner == address(0)) revert InvalidModelId(); // Check if model exists
        // Basic check: could require having made a request for this model
        modelQualityAttestations[_modelId][msg.sender] = _isPositive;
        emit ModelQualityAttested(_modelId, msg.sender, _isPositive);
    }

    /**
     * @notice Allows users to provide feedback on the reliability and performance of an inferencer.
     * @dev Similar to model attestation, a basic system.
     * @param _inferencer The address of the inferencer being attested.
     * @param _isPositive True for a positive attestation, false for a negative one.
     */
    function attestToInferencerReliability(address _inferencer, bool _isPositive) external nonReentrant {
        if (_inferencer == address(0)) revert ZeroAddress();
        inferencerReliabilityAttestations[_inferencer][msg.sender] = _isPositive;
        emit InferencerReliabilityAttested(_inferencer, msg.sender, _isPositive);
    }

    /**
     * @notice Internal function to penalize an inferencer by seizing part or all of their stake.
     * @dev Called during dispute resolution or ZKP verification failure.
     * @param _requestId The ID of the request associated with the slashing.
     * @param _amount The amount of ETH to slash from the inferencer's stake.
     */
    function _slashInferencerStake(uint256 _requestId, uint256 _amount) internal {
        InferenceRequest storage request = inferenceRequests[_requestId];
        uint256 slashAmount = _amount; // Could be a percentage of stake, for now, entire stake.
        
        // Transfer slashed amount to protocol fees, or burn it
        accumulatedProtocolFees += slashAmount; 
        
        request.inferencerStake -= slashAmount; // Reduce inferencer's effective stake
        // The remaining stake (if not 100% slashed) would be lost or recoverable by inferencer via other means
        // In this simple example, the whole stake is "slashed" and moved to accumulatedProtocolFees.

        emit InferencerStakeSlashed(request.inferencer, slashAmount, _requestId);
    }

    // --- IV. Protocol Configuration & Governance ---

    /**
     * @notice Sets the address of the external Zero-Knowledge Proof verifier contract used by AetherWeaver.
     * @dev Only callable by the contract owner.
     * @param _newVerifier The address of the new ZKP verifier contract.
     */
    function setZKPVerifierAddress(address _newVerifier) external onlyOwner {
        if (_newVerifier == address(0)) revert ZeroAddress();
        emit ZKPVerifierAddressUpdated(zkpVerifierAddress, _newVerifier);
        zkpVerifierAddress = _newVerifier;
    }

    /**
     * @notice Updates the protocol fee percentage (in basis points) taken from each successful inference.
     * @dev Only callable by the contract owner. Fee is capped at 100% (10000 bps).
     * @param _newFeeBps The new protocol fee in basis points (e.g., 500 for 5%).
     */
    function updateProtocolFee(uint16 _newFeeBps) external onlyOwner {
        if (_newFeeBps > 10000) revert ProtocolFeeTooHigh(); // Max 100%
        emit ProtocolFeeUpdated(protocolFeeBps, _newFeeBps);
        protocolFeeBps = _newFeeBps;
    }

    /**
     * @notice Allows the protocol owner (or DAO) to withdraw accumulated fees from the contract.
     * @dev These fees include protocol fees from inferences and slashed inferencer stakes.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 amount = accumulatedProtocolFees;
        if (amount == 0) return;

        accumulatedProtocolFees = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            accumulatedProtocolFees = amount; // Refund on failure
            revert ("Protocol fee withdrawal failed");
        }
        emit ProtocolFeesWithdrawn(msg.sender, amount);
    }

    // --- V. Agent Integration ---

    /**
     * @notice Allows an autonomous agent system to register with the protocol.
     * @dev Requires a bond for accountability. This agent can then use batch functions.
     * @param _agentName A name for the agent system.
     * @param _agentBond The ETH bond required for this agent system.
     */
    function registerAgentSystem(string memory _agentName, uint256 _agentBond) external payable nonReentrant {
        if (agentSystems[msg.sender].agentAddress != address(0)) revert AgentAlreadyRegistered();
        if (_agentBond == 0 || msg.value < _agentBond) revert AgentBondTooLow();

        agentSystems[msg.sender] = AgentSystem({
            name: _agentName,
            bond: msg.value, // Store actual deposited bond
            agentAddress: msg.sender,
            isActive: true
        });

        emit AgentRegistered(msg.sender, _agentName, msg.value);
    }

    /**
     * @notice Enables a registered agent to submit multiple inference requests in a single transaction.
     * @dev Optimizes gas costs for agents managing many requests.
     * @param _modelIds Array of model IDs for each request.
     * @param _inputDataHashes Array of input data hashes.
     * @param _maxGasCosts Array of max gas costs.
     * @param _expectedZKPTypes Array of expected ZKP types.
     */
    function agentBatchRequestInference(
        uint256[] memory _modelIds,
        bytes32[] memory _inputDataHashes,
        uint256[] memory _maxGasCosts,
        bytes[] memory _expectedZKPTypes
    ) external payable onlyAgentSystem(msg.sender) nonReentrant {
        if (_modelIds.length == 0 ||
            _modelIds.length != _inputDataHashes.length ||
            _modelIds.length != _maxGasCosts.length ||
            _modelIds.length != _expectedZKPTypes.length)
        {
            revert BatchLengthMismatch();
        }

        uint256 totalRequiredPayment = 0;
        for (uint256 i = 0; i < _modelIds.length; i++) {
            AIModel storage model = aiModels[_modelIds[i]];
            if (model.owner == address(0) || !model.active) revert ModelNotActive();

            uint256 protocolFee = (model.basePrice * protocolFeeBps) / 10000;
            totalRequiredPayment += model.basePrice + protocolFee + _maxGasCosts[i];
        }

        if (msg.value < totalRequiredPayment) revert InsufficientFunds();

        for (uint256 i = 0; i < _modelIds.length; i++) {
            AIModel storage model = aiModels[_modelIds[i]];
            uint256 protocolFee = (model.basePrice * protocolFeeBps) / 10000;

            uint256 newRequestId = nextRequestId++;
            inferenceRequests[newRequestId] = InferenceRequest({
                modelId: _modelIds[i],
                requestor: msg.sender, // Agent is the requestor for batch requests
                inferencer: address(0),
                inputDataHash: _inputDataHashes[i],
                outputDataHash: 0,
                totalPayment: model.basePrice + protocolFee + _maxGasCosts[i], // Funds per request
                inferencerStake: 0,
                requestTime: block.timestamp,
                acceptanceTime: 0,
                resultSubmissionTime: 0,
                maxGasCost: _maxGasCosts[i],
                expectedZKPType: _expectedZKPTypes[i],
                status: RequestStatus.Open,
                inferencerPaid: false,
                creatorPaid: false,
                publicSignals: new uint256[](0),
                proof: [0, 0, 0, 0, 0, 0, 0, 0]
            });
            accumulatedProtocolFees += protocolFee;
            emit InferenceRequested(newRequestId, _modelIds[i], msg.sender, inferenceRequests[newRequestId].totalPayment);
        }

        // Refund any excess ETH not used by totalRequiredPayment from msg.value
        uint256 excessFunds = msg.value - totalRequiredPayment;
        if (excessFunds > 0) {
            (bool success, ) = msg.sender.call{value: excessFunds}("");
            if (!success) revert ("Excess fund refund failed in batch request");
        }
    }


    /**
     * @notice Allows a registered agent to submit results and proofs for multiple inference requests concurrently.
     * @dev This function iterates through multiple requests, validating each result and ZKP.
     *      Note: Calling `verifyProof` for many ZKPs in a single transaction can be very gas-intensive.
     *      For production, consider alternative batch verification strategies (e.g., recursive ZKPs, off-chain aggregation).
     * @param _requestIds Array of request IDs.
     * @param _outputDataHashes Array of output data hashes.
     * @param _batchPublicSignals Array of public signals, where each element is an array for a specific request.
     * @param _batchProofs Array of ZKP proofs, where each element is a fixed-size array for a specific request.
     */
    function agentBatchSubmitResults(
        uint256[] memory _requestIds,
        bytes32[] memory _outputDataHashes,
        uint256[][] memory _batchPublicSignals,
        uint256[8][] memory _batchProofs
    ) external onlyAgentSystem(msg.sender) nonReentrant {
        if (_requestIds.length == 0 ||
            _requestIds.length != _outputDataHashes.length ||
            _requestIds.length != _batchPublicSignals.length ||
            _requestIds.length != _batchProofs.length)
        {
            revert BatchLengthMismatch();
        }

        IZKPVerifier verifier = IZKPVerifier(zkpVerifierAddress);

        for (uint256 i = 0; i < _requestIds.length; i++) {
            uint256 requestId = _requestIds[i];
            InferenceRequest storage request = inferenceRequests[requestId];

            // Basic checks for each request in the batch
            if (request.status != RequestStatus.Accepted || request.inferencer != msg.sender) {
                // Skip or revert for invalid requests in batch. Skipping is more robust for batches.
                // For simplicity, we'll continue, but a real-world scenario might revert or log.
                continue; 
            }
            if (block.timestamp > request.acceptanceTime + RESULT_SUBMISSION_TIMEOUT) {
                request.status = RequestStatus.Failed;
                _slashInferencerStake(requestId, request.inferencerStake); // Slash for timeout
                continue;
            }

            // Store results
            request.outputDataHash = _outputDataHashes[i];
            request.publicSignals = _batchPublicSignals[i];
            request.proof = _batchProofs[i];
            request.resultSubmissionTime = block.timestamp;
            request.status = RequestStatus.ResultSubmitted;

            // Immediately verify and finalize for batch submission if successful
            bool verificationSuccess = verifier.verifyProof(request.publicSignals, request.proof);

            if (!verificationSuccess) {
                request.status = RequestStatus.Failed;
                _slashInferencerStake(requestId, request.inferencerStake);
                // No revert here to allow other batch items to process.
                continue;
            }

            AIModel storage model = aiModels[request.modelId];
            uint256 modelCreatorShare = model.basePrice;
            uint256 protocolFee = (model.basePrice * protocolFeeBps) / 10000;
            uint256 excessFunds = request.totalPayment - (modelCreatorShare + protocolFee + request.maxGasCost);

            if (excessFunds > 0) {
                (bool success, ) = request.requestor.call{value: excessFunds}("");
                if (!success) {} // Handle failure gracefully
            }
            model.accumulatedCreatorFees += modelCreatorShare;
            request.status = RequestStatus.Finalized;
            emit InferenceFinalized(requestId, request.inferencer, request.requestor);
        }
    }
}
```