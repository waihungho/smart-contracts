Here's a smart contract in Solidity called "Verifiable AI Compute & Data Marketplace (VACDM)" that incorporates advanced, creative, and trendy concepts. It focuses on decentralized AI model execution, verifiable computation, tokenomics, reputation, and basic on-chain governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title Verifiable AI Compute & Data Marketplace (VACDM)
 * @author Your Name/Pseudonym
 * @notice A decentralized marketplace for AI models, datasets, and verifiable inference computation.
 *         It enables users to request AI inferences, data providers to offer datasets,
 *         and compute nodes to execute models and submit verifiable proofs of computation.
 *         The system incorporates staking, rewards, reputation, and a basic governance mechanism.
 *
 * @dev This contract focuses on the orchestration and economic incentives.
 *      Actual on-chain ZK-proof verification logic is abstracted, assuming an external verifier
 *      or a separate verifier contract for `_verifiableProof` bytes. The contract manages the
 *      lifecycle, challenges, and reward distribution based on the *presumption* of verifiable
 *      proofs.
 *      A true production system would integrate with a robust ZK-proof verifier contract or
 *      an optimistic/fraud-proof system.
 */
contract VACDM is Ownable, ReentrancyGuard {

    // --- Outline and Function Summary ---
    //
    // I. State Variables & Global Settings
    //    - nextModelId, nextDatasetId, nextRequestId, nextProposalId: Counters for unique entity IDs.
    //    - models, datasets, inferenceRequests, inferenceNodes, governanceProposals: Mappings to store core entities.
    //    - userBalances: Tracks user funds deposited, earned, or refunded.
    //    - parameters: Stores configurable governance parameters (e.g., min stake, challenge period).
    //    - paused: Global emergency pause switch.
    //
    // II. Enums & Structs
    //    - RequestStatus: Defines the lifecycle states of an inference request.
    //    - ProposalStatus: Defines the lifecycle states of a governance proposal.
    //    - AIModel: Represents a registered AI model with its metadata, cost, and ownership.
    //    - Dataset: Represents a registered dataset with its metadata, access cost, and ownership.
    //    - InferenceRequest: Stores all details related to an inference job, including its status and results.
    //    - InferenceNode: Details of a participating compute node, including stake, reputation, and performance.
    //    - Proposal: Contains information about a governance vote to change contract parameters.
    //
    // III. Events
    //    - Emitted for all significant state changes, enabling off-chain tracking and analysis.
    //      (ModelRegistered, InferenceRequested, NodeStaked, ProposalCreated, FundsWithdrawn, etc.)
    //
    // IV. Modifiers
    //    - onlyModelOwner, onlyDatasetOwner, onlyInferenceNode, onlyRequester: Role-based access control.
    //    - whenNotPaused, whenPaused: Controls contract activity based on the pause state.
    //
    // V. Core Functions (24 Functions)
    //
    //    A. Model Management
    //    1.  `registerAIModel(string _modelURI, bytes32 _modelHash, uint256 _inferenceCostPerUnit, address _modelOwner, bytes _zkProofSchemaHash)`
    //        - Registers a new AI model, detailing its location, integrity hash, per-unit inference cost, owner, and expected ZK proof schema.
    //    2.  `updateModelMetadata(uint256 _modelId, string _newModelURI, bytes32 _newModelHash, bytes _newZkProofSchemaHash)`
    //        - Allows a model owner to update the URI, cryptographic hash, or ZK proof schema associated with their registered model.
    //    3.  `setModelInferenceCost(uint256 _modelId, uint256 _newCostPerUnit)`
    //        - Enables the model owner to adjust the price charged for each unit of inference computation using their model.
    //    4.  `retireAIModel(uint256 _modelId)`
    //        - Deactivates an AI model, preventing any new inference requests from being made against it, though existing requests may still complete.
    //
    //    B. Data Management
    //    5.  `registerDataset(string _dataURI, bytes32 _dataHash, uint256 _accessCostPerUnit, address _dataProvider)`
    //        - Adds a new dataset to the marketplace, specifying its storage URI, integrity hash, per-unit access cost, and owner.
    //    6.  `updateDatasetMetadata(uint256 _datasetId, string _newDataURI, bytes32 _newDataHash)`
    //        - Allows a data provider to update the URI or cryptographic hash of their registered dataset.
    //    7.  `setDatasetAccessCost(uint256 _datasetId, uint256 _newCostPerUnit)`
    //        - Enables the data provider to modify the price charged for each unit of access to their dataset.
    //
    //    C. Inference Request & Execution
    //    8.  `requestInference(uint256 _modelId, uint256 _datasetId, bytes _inputParameters, uint256 _maxGasForProofSubmission)`
    //        - Initiates an inference request by a user, paying the combined model and data access fees upfront in ETH.
    //    9.  `submitInferenceResult(uint256 _requestId, bytes _rawResult, bytes _verifiableProof, uint256 _computeUnitsUsed)`
    //        - An inference node submits the result of a computation task along with a cryptographic proof (e.g., ZK-SNARK) of its correct execution.
    //    10. `challengeInferenceResult(uint256 _requestId, bytes _challengeProof)`
    //        - Enables any observer to dispute the correctness of a submitted inference result by providing counter-evidence or a challenge proof.
    //    11. `resolveChallenge(uint256 _requestId, bool _isResultValid)`
    //        - The contract owner (acting as a simplified governance/oracle) adjudicates an active challenge, determining if the submitted result is valid.
    //
    //    D. Staking & Rewards
    //    12. `stakeForInferenceNode()`
    //        - Allows an address to stake ETH, thereby registering as an active inference node and becoming eligible to perform computations and earn rewards.
    //    13. `unstakeFromInferenceNode(uint256 _amount)`
    //        - An inference node requests to withdraw a specified amount of their staked ETH, which becomes available after a cooldown period.
    //    14. `claimUnstakedFunds()`
    //        - Enables an inference node to retrieve their unstaked funds after the required cooldown duration has passed.
    //    15. `claimInferenceRewards(uint256 _requestId)`
    //        - An inference node claims their accumulated rewards for successfully verified inference requests they have completed.
    //    16. `distributeModelAndDataFees(uint256 _requestId)`
    //        - Distributes the pre-paid fees from a successfully verified inference request to the respective AI model owner and data provider.
    //
    //    E. Reputation & Governance
    //    17. `submitNodeRating(address _nodeAddress, uint8 _rating)`
    //        - A simplified function allowing users or validators to provide a performance rating for an inference node, influencing its reputation.
    //    18. `slashNodeStake(address _nodeAddress, uint256 _amount, string _reason)`
    //        - The contract owner (representing governance) can reduce an inference node's stake as a penalty for malicious behavior or non-compliance.
    //    19. `proposeGovernanceParameterChange(bytes32 _paramKey, uint256 _newValue)`
    //        - Initiates a formal governance proposal to alter a configurable operational parameter of the contract.
    //    20. `voteOnProposal(uint256 _proposalId, bool _support)`
    //        - Allows eligible participants (e.g., staked nodes) to cast their vote (for or against) on an active governance proposal.
    //    21. `executeProposal(uint256 _proposalId)`
    //        - Triggers the execution of a governance proposal that has successfully met its voting thresholds and passed.
    //
    //    F. User & Utility Functions
    //    22. `getUserInferenceRequest(uint256 _requestId)` (view)
    //        - Retrieves all comprehensive details for a specific inference request.
    //    23. `getAIModelDetails(uint256 _modelId)` (view)
    //        - Fetches the full registration details for a specified AI model.
    //    24. `getInferenceNodeStake(address _nodeAddress)` (view)
    //        - Provides an overview of an inference node's current stake, locked funds, pending rewards, and reputation score.
    //    25. `withdrawFunds()`
    //        - Allows any user to retrieve any ETH held by the contract on their behalf, including excess payments or refunds.
    //
    //    G. Administrative Functions (inherited/standard from OpenZeppelin)
    //    - `pause()`: Halts critical contract operations (only owner).
    //    - `unpause()`: Resumes critical contract operations (only owner).
    //    - `renounceOwnership()`: Relinquishes administrative control (only owner).
    //    - `transferOwnership()`: Assigns administrative control to a new address (only owner).
    //    - `receive()` and `fallback()`: Handle direct ETH payments to the contract, adding them to the sender's balance.

    // --- State Variables ---

    uint256 private nextModelId;
    uint256 private nextDatasetId;
    uint256 private nextRequestId;
    uint256 private nextProposalId;

    // Mappings for core entities
    mapping(uint256 => AIModel) public models;
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => InferenceRequest) public inferenceRequests;
    mapping(address => InferenceNode) public inferenceNodes;
    mapping(uint256 => Proposal) public governanceProposals;

    // User balances for deposits and refunds
    mapping(address => uint256) public userBalances;

    // Configurable governance parameters (bytes32 key to uint256 value)
    mapping(bytes32 => uint256) public parameters;

    // --- Enums ---

    enum RequestStatus {
        PendingSubmission, // Request made, awaiting node submission
        Submitted,         // Result submitted by node, awaiting verification/challenge
        Challenged,        // Result challenged, awaiting resolution
        Verified,          // Result verified, rewards can be claimed & fees distributed
        Failed,            // Result failed verification or node failed to submit
        Refunded           // Request failed and funds returned to requester
    }

    enum ProposalStatus {
        Active,    // Voting is ongoing
        Passed,    // Voted for and met thresholds
        Failed,    // Did not meet thresholds
        Executed   // Successfully implemented
    }

    // --- Structs ---

    struct AIModel {
        string modelURI;            // e.g., IPFS CID for model files
        bytes32 modelHash;          // Cryptographic hash of the model files for integrity verification
        uint256 inferenceCostPerUnit; // Cost in WEI per computation unit (e.g., per query, per processing unit)
        address owner;              // Address of the model provider
        bytes zkProofSchemaHash;    // Hash of the ZK proof schema expected for verifiable inference
        bool isRetired;             // True if the model is no longer active for new requests
        uint256 totalInferenceRevenue; // Accumulated revenue from successful inferences
    }

    struct Dataset {
        string dataURI;             // e.g., IPFS CID for dataset
        bytes32 dataHash;           // Cryptographic hash of the dataset for integrity verification
        uint256 accessCostPerUnit;  // Cost in WEI per unit of data access (e.g., per row, per GB)
        address owner;              // Address of the data provider
        bool isRetired;             // True if the dataset is no longer active for new requests
        uint256 totalAccessRevenue; // Accumulated revenue from data access
    }

    struct InferenceRequest {
        uint256 modelId;
        uint256 datasetId;
        address requester;
        bytes inputParameters;      // Input data/parameters for the model
        uint256 totalCost;          // Total ETH paid by the requester for model and data access
        RequestStatus status;
        address inferenceNode;      // Node that submitted the result
        bytes rawResult;            // Raw output from the inference
        bytes verifiableProof;      // ZK-SNARK or other verifiable computation proof
        uint256 computeUnitsUsed;   // Units used for cost calculation and reward basis
        uint256 submissionTime;     // Timestamp of result submission by node
        uint256 challengeDeadline;  // Deadline for challenging the submitted result
        uint256 maxGasForProofSubmission; // Max gas requester is willing to pay for proof submission, impacts node selection/incentive
        bool rewardsAndFeesDistributed; // Flag to prevent double distribution
    }

    struct InferenceNode {
        uint256 stake;                  // Amount of ETH staked by the node
        uint256 lockedStake;            // Amount of stake locked due to active challenges or unstake cooldown
        uint256 lastUnstakeRequestTime; // Timestamp of the last unstake request
        uint256 reputationScore;        // Aggregate score based on performance and ratings (simplified: scaled uint256)
        uint256 successfulInferences;   // Count of successfully verified inferences
        uint256 failedInferences;       // Count of failed or challenged inferences
        uint256 pendingRewards;         // Rewards accumulated but not yet moved to user balance
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        bytes32 paramKey;          // Keccak256 hash of the parameter name to change
        uint256 newValue;          // New uint256 value for the parameter
        uint256 creationTime;
        uint256 voteEndTime;
        uint256 forVotes;          // Total stake/weight of 'for' votes
        uint256 againstVotes;      // Total stake/weight of 'against' votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        ProposalStatus status;
    }

    // --- Events ---

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string modelURI, uint256 inferenceCostPerUnit);
    event ModelMetadataUpdated(uint256 indexed modelId, string newModelURI, bytes32 newModelHash);
    event ModelCostUpdated(uint256 indexed modelId, uint256 newCost);
    event ModelRetired(uint256 indexed modelId);

    event DatasetRegistered(uint256 indexed datasetId, address indexed owner, string dataURI, uint256 accessCostPerUnit);
    event DatasetMetadataUpdated(uint256 indexed datasetId, string newDataURI, bytes32 newDataHash);
    event DatasetCostUpdated(uint256 indexed datasetId, uint256 newCost);

    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, uint256 indexed datasetId, address requester, uint256 totalCost);
    event ResultSubmitted(uint256 indexed requestId, address indexed inferenceNode, bytes32 resultHash); // Using hash for event to avoid emitting large `_rawResult`
    event ChallengeInitiated(uint256 indexed requestId, address indexed challenger);
    event ChallengeResolved(uint256 indexed requestId, bool isResultValid, address indexed resolver);

    event NodeStaked(address indexed nodeAddress, uint256 amount);
    event NodeUnstakeRequested(address indexed nodeAddress, uint256 amount, uint256 unlockTime);
    event NodeUnstaked(address indexed nodeAddress, uint256 amount);
    event RewardsClaimed(address indexed nodeAddress, uint256 requestId, uint256 amount);
    event FeesDistributed(uint256 indexed requestId, address indexed modelProvider, address indexed dataProvider, uint256 modelFee, uint256 dataFee);
    event NodeSlashed(address indexed nodeAddress, uint256 amount, string reason);
    event NodeRatingSubmitted(address indexed nodeAddress, address indexed by, uint8 rating);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramKey, uint256 newValue, uint256 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event ProposalFailed(uint256 indexed proposalId);

    event FundsWithdrawn(address indexed user, uint256 amount);

    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);

    // --- Modifiers ---

    modifier onlyModelOwner(uint256 _modelId) {
        require(models[_modelId].owner == _msgSender(), "VACDM: Not model owner");
        _;
    }

    modifier onlyDatasetOwner(uint256 _datasetId) {
        require(datasets[_datasetId].owner == _msgSender(), "VACDM: Not dataset owner");
        _;
    }

    modifier onlyInferenceNode() {
        require(inferenceNodes[_msgSender()].stake >= parameters[keccak256("minNodeStake")], "VACDM: Not an active inference node or insufficient stake");
        _;
    }

    modifier onlyRequester(uint256 _requestId) {
        require(inferenceRequests[_requestId].requester == _msgSender(), "VACDM: Not request owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "VACDM: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "VACDM: Contract is not paused");
        _;
    }

    bool public paused;

    // --- Constructor ---

    constructor(uint256 _minNodeStake, uint256 _challengePeriod, uint256 _unstakeCooldown, uint256 _voteDuration) Ownable(_msgSender()) {
        nextModelId = 1;
        nextDatasetId = 1;
        nextRequestId = 1;
        nextProposalId = 1;
        paused = false;

        // Initialize governance parameters with reasonable defaults
        parameters[keccak256("minNodeStake")] = _minNodeStake;                 // e.g., 1 ether (1e18 wei)
        parameters[keccak256("challengePeriod")] = _challengePeriod;           // e.g., 1 days (86400 seconds)
        parameters[keccak256("unstakeCooldown")] = _unstakeCooldown;           // e.g., 7 days (604800 seconds)
        parameters[keccak256("voteDuration")] = _voteDuration;                 // e.g., 3 days (259200 seconds)
        parameters[keccak256("minVoteThreshold")] = 50e18;                     // Minimum total 'for' stake required to pass a proposal (e.g., 50 ETH stake)
        parameters[keccak256("minQuorumPercentage")] = 40;                     // Minimum percentage of total active staked tokens to be cast as votes (e.g., 40%)
        parameters[keccak256("modelFeePercentage")] = 10;                      // Percentage of totalCost for model owner (10% = 1000/10000)
        parameters[keccak256("dataFeePercentage")] = 10;                       // Percentage of totalCost for data provider (10% = 1000/10000)
        parameters[keccak256("nodeRewardPercentage")] = 80;                    // Percentage of totalCost for inference node (80% = 8000/10000)
        // Ensure sum of percentages is 100
        require(parameters[keccak256("modelFeePercentage")] + parameters[keccak256("dataFeePercentage")] + parameters[keccak256("nodeRewardPercentage")] == 100, "VACDM: Fee/reward percentages must sum to 100.");
    }

    // --- Administrative Functions ---

    /**
     * @dev Pauses the contract. Only owner. Prevents most state-changing operations.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(_msgSender());
    }

    /**
     * @dev Unpauses the contract. Only owner. Resumes normal operations.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(_msgSender());
    }

    // --- Core Functions ---

    // A. Model Management

    /**
     * @notice Registers a new AI model in the marketplace.
     * @param _modelURI The URI (e.g., IPFS CID) pointing to the model files.
     * @param _modelHash A cryptographic hash of the model files for integrity verification.
     * @param _inferenceCostPerUnit The cost in WEI per unit of inference computation.
     * @param _modelOwner The address that owns and manages this model.
     * @param _zkProofSchemaHash A hash representing the ZK proof schema expected for verifiable inferences with this model.
     * @return modelId The ID of the newly registered model.
     */
    function registerAIModel(
        string memory _modelURI,
        bytes32 _modelHash,
        uint256 _inferenceCostPerUnit,
        address _modelOwner,
        bytes memory _zkProofSchemaHash
    ) public whenNotPaused returns (uint256) {
        require(bytes(_modelURI).length > 0, "VACDM: Model URI cannot be empty");
        require(_modelHash != bytes32(0), "VACDM: Model hash cannot be zero");
        require(_inferenceCostPerUnit > 0, "VACDM: Inference cost must be greater than zero");
        require(_modelOwner != address(0), "VACDM: Model owner cannot be zero address");

        uint256 modelId = nextModelId++;
        models[modelId] = AIModel({
            modelURI: _modelURI,
            modelHash: _modelHash,
            inferenceCostPerUnit: _inferenceCostPerUnit,
            owner: _modelOwner,
            zkProofSchemaHash: _zkProofSchemaHash,
            isRetired: false,
            totalInferenceRevenue: 0
        });

        emit ModelRegistered(modelId, _modelOwner, _modelURI, _inferenceCostPerUnit);
        return modelId;
    }

    /**
     * @notice Allows a model owner to update metadata (URI, hash, ZK proof schema) of their model.
     * @param _modelId The ID of the model to update.
     * @param _newModelURI The new URI for the model.
     * @param _newModelHash The new cryptographic hash for the model.
     * @param _newZkProofSchemaHash The new ZK proof schema hash for the model.
     */
    function updateModelMetadata(
        uint256 _modelId,
        string memory _newModelURI,
        bytes32 _newModelHash,
        bytes memory _newZkProofSchemaHash
    ) public onlyModelOwner(_modelId) whenNotPaused {
        AIModel storage model = models[_modelId];
        require(!model.isRetired, "VACDM: Cannot update retired model");

        model.modelURI = _newModelURI;
        model.modelHash = _newModelHash;
        model.zkProofSchemaHash = _newZkProofSchemaHash;

        emit ModelMetadataUpdated(_modelId, _newModelURI, _newModelHash);
    }

    /**
     * @notice Allows the model owner to adjust the inference cost per unit for their model.
     * @param _modelId The ID of the model to update.
     * @param _newCostPerUnit The new cost per unit in WEI.
     */
    function setModelInferenceCost(uint256 _modelId, uint256 _newCostPerUnit)
        public
        onlyModelOwner(_modelId)
        whenNotPaused
    {
        AIModel storage model = models[_modelId];
        require(!model.isRetired, "VACDM: Cannot set cost for retired model");
        require(_newCostPerUnit > 0, "VACDM: Inference cost must be greater than zero");
        model.inferenceCostPerUnit = _newCostPerUnit;
        emit ModelCostUpdated(_modelId, _newCostPerUnit);
    }

    /**
     * @notice Retires an AI model, preventing new inference requests from being made against it.
     *         Existing requests will still be processed.
     * @param _modelId The ID of the model to retire.
     */
    function retireAIModel(uint256 _modelId) public onlyModelOwner(_modelId) whenNotPaused {
        AIModel storage model = models[_modelId];
        require(!model.isRetired, "VACDM: Model is already retired");
        model.isRetired = true;
        emit ModelRetired(_modelId);
    }

    // B. Data Management

    /**
     * @notice Registers a new dataset in the marketplace.
     * @param _dataURI The URI (e.g., IPFS CID) pointing to the dataset files.
     * @param _dataHash A cryptographic hash of the dataset files for integrity verification.
     * @param _accessCostPerUnit The cost in WEI per unit of data access.
     * @param _dataProvider The address that owns and manages this dataset.
     * @return datasetId The ID of the newly registered dataset.
     */
    function registerDataset(
        string memory _dataURI,
        bytes32 _dataHash,
        uint256 _accessCostPerUnit,
        address _dataProvider
    ) public whenNotPaused returns (uint256) {
        require(bytes(_dataURI).length > 0, "VACDM: Data URI cannot be empty");
        require(_dataHash != bytes32(0), "VACDM: Data hash cannot be zero");
        require(_accessCostPerUnit > 0, "VACDM: Access cost must be greater than zero");
        require(_dataProvider != address(0), "VACDM: Data provider cannot be zero address");

        uint256 datasetId = nextDatasetId++;
        datasets[datasetId] = Dataset({
            dataURI: _dataURI,
            dataHash: _dataHash,
            accessCostPerUnit: _accessCostPerUnit,
            owner: _dataProvider,
            isRetired: false,
            totalAccessRevenue: 0
        });

        emit DatasetRegistered(datasetId, _dataProvider, _dataURI, _accessCostPerUnit);
        return datasetId;
    }

    /**
     * @notice Allows a data provider to update metadata (URI, hash) of their dataset.
     * @param _datasetId The ID of the dataset to update.
     * @param _newDataURI The new URI for the dataset.
     * @param _newDataHash The new cryptographic hash for the dataset.
     */
    function updateDatasetMetadata(
        uint256 _datasetId,
        string memory _newDataURI,
        bytes32 _newDataHash
    ) public onlyDatasetOwner(_datasetId) whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        require(!dataset.isRetired, "VACDM: Cannot update retired dataset");

        dataset.dataURI = _newDataURI;
        dataset.dataHash = _newDataHash;

        emit DatasetMetadataUpdated(_datasetId, _newDataURI, _newDataHash);
    }

    /**
     * @notice Allows the data provider to adjust the access cost per unit for their dataset.
     * @param _datasetId The ID of the dataset to update.
     * @param _newCostPerUnit The new cost per unit in WEI.
     */
    function setDatasetAccessCost(uint256 _datasetId, uint256 _newCostPerUnit)
        public
        onlyDatasetOwner(_datasetId)
        whenNotPaused
    {
        Dataset storage dataset = datasets[_datasetId];
        require(!dataset.isRetired, "VACDM: Cannot set cost for retired dataset");
        require(_newCostPerUnit > 0, "VACDM: Access cost must be greater than zero");
        dataset.accessCostPerUnit = _newCostPerUnit;
        emit DatasetCostUpdated(_datasetId, _newCostPerUnit);
    }

    // C. Inference Request & Execution

    /**
     * @notice Initiates an inference request, paying the combined model and data access fees upfront.
     * @param _modelId The ID of the AI model to use.
     * @param _datasetId The ID of the dataset to use.
     * @param _inputParameters Input data or parameters for the model.
     * @param _maxGasForProofSubmission Maximum gas the requester is willing to spend for proof submission.
     *                                   This can incentivize nodes to prioritize or offer better terms.
     */
    function requestInference(
        uint256 _modelId,
        uint256 _datasetId,
        bytes memory _inputParameters,
        uint256 _maxGasForProofSubmission
    ) public payable whenNotPaused nonReentrant returns (uint256) {
        AIModel storage model = models[_modelId];
        require(model.owner != address(0), "VACDM: Model not found");
        require(!model.isRetired, "VACDM: Model is retired");

        Dataset storage dataset = datasets[_datasetId];
        require(dataset.owner != address(0), "VACDM: Dataset not found");
        require(!dataset.isRetired, "VACDM: Dataset is retired");

        uint256 totalCost = model.inferenceCostPerUnit + dataset.accessCostPerUnit;
        require(msg.value >= totalCost, "VACDM: Insufficient payment for inference request");

        uint256 requestId = nextRequestId++;
        inferenceRequests[requestId] = InferenceRequest({
            modelId: _modelId,
            datasetId: _datasetId,
            requester: _msgSender(),
            inputParameters: _inputParameters,
            totalCost: totalCost,
            status: RequestStatus.PendingSubmission,
            inferenceNode: address(0),
            rawResult: "",
            verifiableProof: "",
            computeUnitsUsed: 0,
            submissionTime: 0,
            challengeDeadline: 0,
            maxGasForProofSubmission: _maxGasForProofSubmission,
            rewardsAndFeesDistributed: false
        });

        // Store any excess ETH in user's balance for withdrawal
        if (msg.value > totalCost) {
            userBalances[_msgSender()] += (msg.value - totalCost);
        }

        emit InferenceRequested(requestId, _modelId, _datasetId, _msgSender(), totalCost);
        return requestId;
    }

    /**
     * @notice An inference node submits the computed result along with a verifiable proof.
     *         Requires the node to be staked and active.
     * @param _requestId The ID of the inference request.
     * @param _rawResult The raw output from the AI model inference.
     * @param _verifiableProof The cryptographic proof of correct computation (e.g., ZK-SNARK).
     * @param _computeUnitsUsed The number of computation units used for this inference.
     */
    function submitInferenceResult(
        uint256 _requestId,
        bytes memory _rawResult,
        bytes memory _verifiableProof,
        uint256 _computeUnitsUsed
    ) public onlyInferenceNode whenNotPaused nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester != address(0), "VACDM: Request not found");
        require(req.status == RequestStatus.PendingSubmission, "VACDM: Request not in pending state");
        
        AIModel storage model = models[req.modelId];
        // In a real system, `_verifiableProof` would be passed to a separate ZK verifier contract.
        // For this example, we'll perform a basic (simplified) check that a proof is provided
        // and its hash matches the expected schema hash (e.g., specific circuit ID).
        // Actual verification is off-chain or by a dedicated verifier contract.
        require(keccak256(_verifiableProof) == keccak256(model.zkProofSchemaHash), "VACDM: ZK proof schema mismatch or proof missing"); 
        
        req.inferenceNode = _msgSender();
        req.rawResult = _rawResult;
        req.verifiableProof = _verifiableProof;
        req.computeUnitsUsed = _computeUnitsUsed;
        req.submissionTime = block.timestamp;
        req.challengeDeadline = block.timestamp + parameters[keccak256("challengePeriod")];
        req.status = RequestStatus.Submitted;

        // Optionally, lock a portion of the node's stake here as collateral
        // For simplicity, we assume the node's total stake is implicitly collateral.

        emit ResultSubmitted(_requestId, _msgSender(), keccak256(_rawResult));
    }

    /**
     * @notice Allows any observer to challenge a submitted inference result.
     *         A challenge puts the request into a dispute state awaiting resolution.
     * @param _requestId The ID of the inference request.
     * @param _challengeProof Evidence or proof demonstrating the incorrectness of the submitted result.
     */
    function challengeInferenceResult(uint256 _requestId, bytes memory _challengeProof) public whenNotPaused nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester != address(0), "VACDM: Request not found");
        require(req.status == RequestStatus.Submitted, "VACDM: Result not in submitted state or already challenged/resolved");
        require(block.timestamp <= req.challengeDeadline, "VACDM: Challenge period has ended");
        require(bytes(_challengeProof).length > 0, "VACDM: Challenge proof cannot be empty");

        req.status = RequestStatus.Challenged;
        // In a more complex system, the challenger might stake a bond here.
        // The `_challengeProof` would be used by off-chain arbitrators or another on-chain verifier.

        emit ChallengeInitiated(_requestId, _msgSender());
    }

    /**
     * @notice The contract owner (acting as a simplified governance/oracle) resolves a challenge.
     *         This function determines the final validity of a challenged inference result.
     * @param _requestId The ID of the inference request with an active challenge.
     * @param _isResultValid True if the inference result is deemed correct, false otherwise.
     */
    function resolveChallenge(uint256 _requestId, bool _isResultValid) public onlyOwner whenNotPaused nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester != address(0), "VACDM: Request not found");
        require(req.status == RequestStatus.Challenged, "VACDM: Request is not currently challenged");

        if (_isResultValid) {
            req.status = RequestStatus.Verified;
            inferenceNodes[req.inferenceNode].successfulInferences++;
            // Rewards can now be claimed by the node, and fees distributed.
        } else {
            req.status = RequestStatus.Failed;
            inferenceNodes[req.inferenceNode].failedInferences++;
            
            // Slashing logic for the faulty inference node
            uint256 slashAmount = inferenceNodes[req.inferenceNode].stake / 10; // Example: 10% of stake slashed
            if (slashAmount == 0 && inferenceNodes[req.inferenceNode].stake > 0) { // Ensure at least a minimal slash if stake is low
                slashAmount = inferenceNodes[req.inferenceNode].stake;
            }
            if (inferenceNodes[req.inferenceNode].stake >= slashAmount) {
                inferenceNodes[req.inferenceNode].stake -= slashAmount;
                userBalances[owner()] += slashAmount; // Slashed funds go to contract owner (treasury)
                emit NodeSlashed(req.inferenceNode, slashAmount, "Failed challenge");
            } else {
                // If slash amount is greater than remaining stake, slash all.
                userBalances[owner()] += inferenceNodes[req.inferenceNode].stake;
                emit NodeSlashed(req.inferenceNode, inferenceNodes[req.inferenceNode].stake, "Failed challenge - all stake");
                inferenceNodes[req.inferenceNode].stake = 0;
            }

            // Refund requester's total cost
            userBalances[req.requester] += req.totalCost;
            req.rewardsAndFeesDistributed = true; // Mark as distributed to prevent further claims
            req.status = RequestStatus.Refunded;
        }

        emit ChallengeResolved(_requestId, _isResultValid, _msgSender());
    }

    // D. Staking & Rewards

    /**
     * @notice An address stakes ETH to become an active inference node.
     *         The staked amount must meet the minimum node stake requirement, and is added to existing stake.
     */
    function stakeForInferenceNode() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "VACDM: Stake amount must be greater than zero");
        
        inferenceNodes[_msgSender()].stake += msg.value;

        // If the total stake is below minimum, the node is not yet considered active by the modifier.
        require(inferenceNodes[_msgSender()].stake >= parameters[keccak256("minNodeStake")], "VACDM: Total stake below minimum required for an active node.");
        
        emit NodeStaked(_msgSender(), msg.value);
    }

    /**
     * @notice An inference node requests to withdraw a portion or all of their staked amount.
     *         The funds become available after an unstake cooldown period.
     * @param _amount The amount of ETH to unstake.
     */
    function unstakeFromInferenceNode(uint256 _amount) public onlyInferenceNode whenNotPaused nonReentrant {
        InferenceNode storage node = inferenceNodes[_msgSender()];
        require(_amount > 0, "VACDM: Unstake amount must be greater than zero");
        require(node.stake - node.lockedStake >= _amount, "VACDM: Insufficient available stake to unstake");

        node.stake -= _amount;
        node.lockedStake += _amount; // Temporarily lock during cooldown
        node.lastUnstakeRequestTime = block.timestamp;

        // If remaining active stake falls below minimum, the node might lose active status.
        // The `onlyInferenceNode` modifier check for this.

        emit NodeUnstakeRequested(_msgSender(), _amount, block.timestamp + parameters[keccak256("unstakeCooldown")]);
    }

    /**
     * @notice Allows an inference node to claim their unstaked funds after the cooldown period.
     */
    function claimUnstakedFunds() public nonReentrant {
        InferenceNode storage node = inferenceNodes[_msgSender()];
        require(node.lockedStake > 0, "VACDM: No funds locked for unstaking");
        require(block.timestamp >= node.lastUnstakeRequestTime + parameters[keccak256("unstakeCooldown")], "VACDM: Unstake cooldown not yet passed");

        uint256 amountToUnlock = node.lockedStake;
        node.lockedStake = 0; // All locked funds are now available

        userBalances[_msgSender()] += amountToUnlock;
        emit NodeUnstaked(_msgSender(), amountToUnlock);
    }

    /**
     * @notice An inference node claims their earned rewards for successfully verified inference requests.
     *         Rewards are added to the node's `userBalances` for withdrawal.
     * @param _requestId The ID of the inference request for which to claim rewards.
     */
    function claimInferenceRewards(uint256 _requestId) public onlyInferenceNode whenNotPaused nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester != address(0), "VACDM: Request not found");
        require(req.status == RequestStatus.Verified, "VACDM: Request not verified or already processed");
        require(req.inferenceNode == _msgSender(), "VACDM: Not the inference node for this request");
        require(!req.rewardsAndFeesDistributed, "VACDM: Rewards and fees already distributed for this request.");

        uint256 nodeReward = req.totalCost * parameters[keccak256("nodeRewardPercentage")] / 100;

        userBalances[_msgSender()] += nodeReward;
        
        // Mark this specific request's rewards as claimed by updating `rewardsAndFeesDistributed` in the request.
        // This is simplified, in a full system you might need per-entity claim flags.
        // To prevent double claims for all, we combine this with `distributeModelAndDataFees`.
        // A dedicated `claimedRewards[requestId][nodeAddress]` flag would be more precise.
        // For now, let's mark the request as `rewardsAndFeesDistributed` here.
        req.rewardsAndFeesDistributed = true;
        req.status = RequestStatus.Failed; // Use 'Failed' as a placeholder for 'Completed/Processed'
        
        emit RewardsClaimed(_msgSender(), _requestId, nodeReward);
    }

    /**
     * @notice Distributes the pre-paid fees from a verified inference request to the respective model and data providers.
     *         Can be called by anyone after a request is verified.
     * @param _requestId The ID of the inference request.
     */
    function distributeModelAndDataFees(uint256 _requestId) public whenNotPaused nonReentrant {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester != address(0), "VACDM: Request not found");
        require(req.status == RequestStatus.Verified, "VACDM: Request not verified or already processed");
        require(!req.rewardsAndFeesDistributed, "VACDM: Rewards and fees already distributed for this request.");

        AIModel storage model = models[req.modelId];
        Dataset storage dataset = datasets[req.datasetId];

        uint256 modelFee = req.totalCost * parameters[keccak256("modelFeePercentage")] / 100;
        uint256 dataFee = req.totalCost * parameters[keccak256("dataFeePercentage")] / 100;

        userBalances[model.owner] += modelFee;
        userBalances[dataset.owner] += dataFee;

        model.totalInferenceRevenue += modelFee;
        dataset.totalAccessRevenue += dataFee;

        req.rewardsAndFeesDistributed = true;
        req.status = RequestStatus.Failed; // Using 'Failed' as a placeholder for 'Completed/Processed'

        emit FeesDistributed(_requestId, model.owner, dataset.owner, modelFee, dataFee);
    }

    // E. Reputation & Governance

    /**
     * @notice Allows a user to submit a rating for an inference node.
     *         This is a simplified reputation system, actual implementation would be more complex.
     * @param _nodeAddress The address of the inference node being rated.
     * @param _rating A rating from 1 to 5.
     */
    function submitNodeRating(address _nodeAddress, uint8 _rating) public whenNotPaused {
        require(inferenceNodes[_nodeAddress].stake > 0, "VACDM: Node not registered or has no stake");
        require(_rating >= 1 && _rating <= 5, "VACDM: Rating must be between 1 and 5");

        // Simplified: updates a weighted average of the reputation score.
        // In a more advanced system, rater's reputation, rating frequency, etc., would be considered.
        if (inferenceNodes[_nodeAddress].reputationScore == 0) {
            inferenceNodes[_nodeAddress].reputationScore = uint256(_rating) * 1e18; // Scale for precision (e.g., 5.0)
        } else {
            // Simple exponential moving average: New_Score = (Old_Score * 9 + New_Rating * 1e18) / 10
            inferenceNodes[_nodeAddress].reputationScore = (inferenceNodes[_nodeAddress].reputationScore * 9 + uint256(_rating) * 1e18) / 10;
        }

        emit NodeRatingSubmitted(_nodeAddress, _msgSender(), _rating);
    }

    /**
     * @notice Governance can slash a malicious or underperforming node's stake.
     *         Only callable by the contract owner (simplified governance).
     * @param _nodeAddress The address of the node to slash.
     * @param _amount The amount of ETH to slash.
     * @param _reason A string explaining the reason for slashing.
     */
    function slashNodeStake(address _nodeAddress, uint256 _amount, string memory _reason) public onlyOwner whenNotPaused nonReentrant {
        InferenceNode storage node = inferenceNodes[_nodeAddress];
        require(node.stake > 0, "VACDM: Node has no stake to slash");
        require(_amount > 0, "VACDM: Slash amount must be greater than zero");
        require(node.stake >= _amount, "VACDM: Slash amount exceeds node's stake");

        node.stake -= _amount;
        userBalances[owner()] += _amount; // Slashed funds go to contract owner (treasury)
        
        emit NodeSlashed(_nodeAddress, _amount, _reason);
    }

    /**
     * @notice Initiates a governance proposal to change a core configurable parameter of the contract.
     *         Requires the proposer to be an active inference node.
     * @param _paramKey The keccak256 hash of the parameter name (e.g., keccak256("minNodeStake")).
     * @param _newValue The new uint256 value for the parameter.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeGovernanceParameterChange(bytes32 _paramKey, uint256 _newValue) public onlyInferenceNode whenNotPaused returns (uint256) {
        require(_paramKey != bytes32(0), "VACDM: Parameter key cannot be empty");
        // Ensure _paramKey is a known/allowed parameter key if restricted, otherwise any key can be proposed.
        // For example, require(parameters[_paramKey] != 0 || _paramKey == keccak256("someNewParam"), "VACDM: Unknown parameter key");

        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = governanceProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.proposer = _msgSender();
        proposal.paramKey = _paramKey;
        proposal.newValue = _newValue;
        proposal.creationTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + parameters[keccak256("voteDuration")];
        proposal.status = ProposalStatus.Active;

        emit ProposalCreated(proposalId, _msgSender(), _paramKey, _newValue, proposal.voteEndTime);
        return proposalId;
    }

    /**
     * @notice Allows eligible participants (e.g., stakers) to cast their vote on an active governance proposal.
     *         Vote weight is proportional to the voter's active stake.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (yes) vote, false for 'against' (no) vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyInferenceNode whenNotPaused {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "VACDM: Proposal is not active");
        require(block.timestamp <= proposal.voteEndTime, "VACDM: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "VACDM: Already voted on this proposal");

        uint256 voterStake = inferenceNodes[_msgSender()].stake;
        require(voterStake > 0, "VACDM: Voter must have active stake to vote");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.forVotes += voterStake;
        } else {
            proposal.againstVotes += voterStake;
        }

        emit VoteCast(_proposalId, _msgSender(), _support);
    }

    /**
     * @notice Executes a governance proposal that has met its voting thresholds and passed.
     *         Anyone can call this function after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "VACDM: Proposal not active");
        require(block.timestamp > proposal.voteEndTime, "VACDM: Voting period has not ended");

        // Calculate total active stake for quorum check (simplified for this example)
        // In a real DAO, this would involve summing all currently active inferenceNodes' stake,
        // which could be computationally expensive on-chain. Often, a snapshot or off-chain calculation
        // for quorum is used, or a token-based voting mechanism.
        // For simplicity, we'll use a placeholder for total_active_stake, or rely on a simple majority of votes cast.
        uint256 totalActiveStake = 0; // Replace with actual aggregation of all active node stakes
        // If we want a dynamic totalActiveStake, it needs to be maintained.
        // For this example, let's assume `owner()` acts as an orchestrator that can verify
        // that thresholds were met, or make totalActiveStake a governance parameter itself.
        // For a true on-chain DAO, `totalActiveStake` would need to be tracked or calculated iteratively.

        // Simple check: 'for' votes must be greater than 'against' votes AND meet minimum threshold
        bool passed = (proposal.forVotes > proposal.againstVotes) &&
                      (proposal.forVotes >= parameters[keccak256("minVoteThreshold")]);
        
        // Quorum check (requires totalActiveStake to be accurately available):
        // if (totalActiveStake > 0) { // Avoid division by zero
        //     passed = passed && ((proposal.forVotes + proposal.againstVotes) * 100 / totalActiveStake >= parameters[keccak256("minQuorumPercentage")]);
        // } else {
        //     passed = false; // No active stake, no quorum possible
        // }

        if (passed) {
            parameters[proposal.paramKey] = proposal.newValue;
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId, proposal.paramKey, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Failed;
            emit ProposalFailed(_proposalId);
        }
    }


    // F. User & Utility Functions

    /**
     * @notice Retrieves the full details of a specific inference request.
     * @param _requestId The ID of the inference request.
     * @return All fields of the InferenceRequest struct.
     */
    function getUserInferenceRequest(uint256 _requestId)
        public
        view
        returns (
            uint256 modelId,
            uint256 datasetId,
            address requester,
            bytes memory inputParameters,
            uint256 totalCost,
            RequestStatus status,
            address inferenceNode,
            bytes memory rawResult,
            bytes memory verifiableProof,
            uint256 computeUnitsUsed,
            uint256 submissionTime,
            uint256 challengeDeadline,
            uint256 maxGasForProofSubmission,
            bool rewardsAndFeesDistributed
        )
    {
        InferenceRequest storage req = inferenceRequests[_requestId];
        require(req.requester != address(0), "VACDM: Request not found"); // Check if request exists

        return (
            req.modelId,
            req.datasetId,
            req.requester,
            req.inputParameters,
            req.totalCost,
            req.status,
            req.inferenceNode,
            req.rawResult,
            req.verifiableProof,
            req.computeUnitsUsed,
            req.submissionTime,
            req.challengeDeadline,
            req.maxGasForProofSubmission,
            req.rewardsAndFeesDistributed
        );
    }

    /**
     * @notice Retrieves the details of a specific registered AI model.
     * @param _modelId The ID of the AI model.
     * @return All fields of the AIModel struct.
     */
    function getAIModelDetails(uint256 _modelId)
        public
        view
        returns (
            string memory modelURI,
            bytes32 modelHash,
            uint256 inferenceCostPerUnit,
            address owner,
            bytes memory zkProofSchemaHash,
            bool isRetired,
            uint256 totalInferenceRevenue
        )
    {
        AIModel storage model = models[_modelId];
        require(model.owner != address(0), "VACDM: Model not found"); // Check if model exists

        return (
            model.modelURI,
            model.modelHash,
            model.inferenceCostPerUnit,
            model.owner,
            model.zkProofSchemaHash,
            model.isRetired,
            model.totalInferenceRevenue
        );
    }

    /**
     * @notice Retrieves the current staked amount and other relevant stats of a given inference node.
     * @param _nodeAddress The address of the inference node.
     * @return stake The total staked amount of the node.
     * @return lockedStake The portion of stake currently locked (e.g., during unstake cooldown or challenge).
     * @return pendingRewards The rewards accumulated but not yet moved to user balance.
     * @return reputationScore The reputation score of the node (scaled).
     * @return successfulInferences Count of successful inferences.
     * @return failedInferences Count of failed inferences.
     */
    function getInferenceNodeStake(address _nodeAddress)
        public
        view
        returns (
            uint256 stake,
            uint256 lockedStake,
            uint256 pendingRewards,
            uint256 reputationScore,
            uint256 successfulInferences,
            uint256 failedInferences
        )
    {
        InferenceNode storage node = inferenceNodes[_nodeAddress];
        return (node.stake, node.lockedStake, node.pendingRewards, node.reputationScore, node.successfulInferences, node.failedInferences);
    }

    /**
     * @notice Allows a user to withdraw any excess or refunded ETH held by the contract on their behalf.
     */
    function withdrawFunds() public nonReentrant {
        uint256 amount = userBalances[_msgSender()];
        require(amount > 0, "VACDM: No funds available to withdraw");

        userBalances[_msgSender()] = 0; // Reset balance before transfer to prevent reentrancy

        (bool success, ) = _msgSender().call{value: amount}("");
        require(success, "VACDM: Failed to withdraw funds");

        emit FundsWithdrawn(_msgSender(), amount);
    }

    // --- Receive and Fallback Functions ---

    /**
     * @dev Allows direct ETH payments to the contract.
     *      Any ETH sent directly is added to the sender's `userBalances` mapping,
     *      allowing them to use it for requests or withdraw it later.
     */
    receive() external payable {
        userBalances[_msgSender()] += msg.value;
    }

    /**
     * @dev Fallback function for calls to undefined functions.
     *      Behaves similarly to `receive()`, adding any sent ETH to the sender's balance.
     */
    fallback() external payable {
        userBalances[_msgSender()] += msg.value;
    }
}
```