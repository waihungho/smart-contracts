The following smart contract, "Aetheria - The Autonomous Intelligence Nexus," is designed to manage and orchestrate decentralized AI models and their inference services. It leverages advanced concepts such as dynamic reputation systems, flexible dispute resolution, and an asynchronous callback mechanism, going beyond typical open-source implementations by integrating these elements into a cohesive AI service marketplace.

## Aetheria - The Autonomous Intelligence Nexus

Aetheria is a decentralized platform where:
*   **AI Model Providers** can register their AI models, detailing their capabilities and costs.
*   **Oracles** (compute nodes) can register themselves, stake tokens, and offer to execute AI inference tasks for specific models.
*   **Users (DApps/Individuals)** can request AI inferences, paying dynamically calculated fees.
*   **Dynamic Reputation** for both models and oracles is maintained based on objective performance metrics and subjective user feedback, influencing pricing and trust.
*   A **Dispute Resolution** system ensures fair play and incentivizes honest participation.
*   An **Asynchronous Callback** mechanism allows seamless integration with other DApps, delivering inference results on-chain.

### Outline and Function Summary:

**I. Core Infrastructure & Access Control (5 functions)**
1.  `constructor()`: Initializes the contract owner, sets initial protocol fees, and default reputation parameters.
2.  `changeOwner(address newOwner)`: Transfers ownership of the contract to a new address.
3.  `addAdmin(address _admin)`: Grants administrative privileges to an address. Admins can pause the contract, set fees, and resolve disputes.
4.  `removeAdmin(address _admin)`: Revokes administrative privileges from an address.
5.  `pause()` / `unpause()`: Emergency functions to pause or unpause critical contract operations, callable by owner or admins.

**II. AI Model Management (5 functions)**
6.  `registerAIModel(...)`: Allows an AI provider to register a new model with its IPFS hash (for artifact/metadata), description, base cost, max inference time, and I/O formats.
7.  `updateAIModelDetails(...)`: Enables the model provider to update existing details of their registered AI model.
8.  `toggleModelWhitelist(bytes32 modelId, bool isWhitelisted)`: An admin-controlled function to whitelist (enable) or blacklist (disable) an AI model for active service. Only whitelisted models can be used.
9.  `submitModelPerformanceMetric(bytes32 modelId, uint256 accuracyScore, bytes32 metadataHash)`: Admins or designated reporters submit objective performance data (e.g., accuracy scores) for a model, contributing to its reputation.
10. `getAIModelDetails(bytes32 modelId)`: Retrieves comprehensive details about a registered AI model, including its dynamically calculated reputation score.

**III. Oracle/Validator Management (4 functions)**
11. `registerOracleNode(string calldata nodeUri, bytes32[] calldata supportedModelIds)`: Oracles register their compute node, staking ETH and declaring which AI models they are capable of executing.
12. `updateOracleNode(string calldata nodeUri, bytes32[] calldata supportedModelIds)`: Oracles can update their node's URI or list of supported models.
13. `slashOracleStake(address oracleAddress, uint256 amount, string calldata reason)`: An admin function to penalize an oracle by slashing a portion of their staked ETH for misconduct or failed disputes.
14. `getOracleNodeDetails(address oracleAddress)`: Retrieves details about a registered oracle node, including its dynamically calculated reputation score.

**IV. AI Request & Execution Flow (5 functions)**
15. `requestAIInference(...)`: Users request an AI inference for a specified model, paying the maximum acceptable cost. They can also provide a callback address and data for asynchronous result delivery.
16. `submitAIInferenceResult(...)`: An oracle submits the result (e.g., IPFS hash of output data) for a completed inference request, along with actual execution cost and time.
17. `disputeAIInferenceResult(bytes32 requestId, string calldata reasonHash)`: Users (requester) or other active oracles can dispute a submitted inference result within a specified window.
18. `resolveDispute(...)`: An admin function to resolve a dispute, determining the winning party and distributing funds or applying penalties accordingly.
19. `claimInferenceReward(bytes32 requestId)`: Allows an oracle to claim their earned reward for a successfully completed and undisputed (or resolved in their favor) inference.

**V. Dynamic Reputation & Treasury (6 functions)**
20. `submitUserFeedback(bytes32 requestId, uint8 rating, string calldata commentHash)`: Users provide subjective feedback (1-5 star rating) on a specific inference result, which feeds into both model and oracle reputation.
21. `getDynamicModelCost(bytes32 modelId)`: A view function that calculates the current effective cost of an AI model, dynamically adjusting its base cost based on its reputation score.
22. `withdrawProtocolFees(address recipient)`: Allows the owner or an admin to withdraw accumulated protocol fees to a specified address.
23. `setProtocolFee(uint256 newFeeBps)`: Sets the percentage of inference fees collected by the protocol, in basis points.
24. `setReputationParameters(uint256 _modelPerformanceToFeedbackRatio, uint256 _oracleDisputePenaltyPoints)`: An admin function to configure the weighting of objective performance vs. subjective user feedback for model reputation, and the penalty points for oracle disputes.
25. `depositStake()`: Allows an oracle to increase their existing stake.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Uncomment if using ERC20 for payments/staking

/**
 * @title Aetheria - The Autonomous Intelligence Nexus
 * @dev Aetheria is a decentralized platform for managing and orchestrating AI models and their inference services.
 *      It allows AI service providers (models) to register, oracles to execute inferences, and users to request
 *      and pay for AI tasks. It incorporates dynamic pricing based on a reputation system derived from
 *      performance metrics and user feedback, along with a dispute resolution mechanism and a callback system
 *      for asynchronous results.
 *
 * Outline and Function Summary:
 *
 * I. Core Infrastructure & Access Control (5 functions)
 *    1.  constructor(): Initializes contract owner and sets initial protocol fees and reputation parameters.
 *    2.  changeOwner(address newOwner): Transfers ownership of the contract.
 *    3.  addAdmin(address _admin): Grants administrative privileges to an address.
 *    4.  removeAdmin(address _admin): Revokes administrative privileges from an address.
 *    5.  pause() / unpause(): Emergency functions to pause or unpause contract operations.
 *
 * II. AI Model Management (5 functions)
 *    6.  registerAIModel(...): Registers a new AI model with its identifier, IPFS hash, description, cost, and I/O specifications.
 *    7.  updateAIModelDetails(...): Allows model providers to update details of their registered AI model.
 *    8.  toggleModelWhitelist(bytes32 modelId, bool isWhitelisted): Governance function to whitelist or blacklist an AI model for service.
 *    9.  submitModelPerformanceMetric(...): Admins or designated reporters submit objective performance data for models.
 *    10. getAIModelDetails(bytes32 modelId): Retrieves comprehensive details about a specific registered AI model.
 *
 * III. Oracle/Validator Management (4 functions)
 *    11. registerOracleNode(...): Oracles register their compute node, stake tokens, and declare models they can execute.
 *    12. updateOracleNode(...): Oracles update their node details and supported models.
 *    13. slashOracleStake(...): Governance or dispute resolution slashes an oracle's stake for misconduct.
 *    14. getOracleNodeDetails(address oracleAddress): Retrieves details about a specific registered oracle node.
 *
 * IV. AI Request & Execution Flow (5 functions)
 *    15. requestAIInference(...): Users request an AI inference, pay the max cost, and specify a callback for result delivery.
 *    16. submitAIInferenceResult(...): An oracle submits the result of a completed AI inference request.
 *    17. disputeAIInferenceResult(...): Users or other oracles can dispute a submitted result.
 *    18. resolveDispute(...): Governance/Dispute Resolver determines the outcome of a dispute, distributing funds/penalties.
 *    19. claimInferenceReward(...): Oracles claim their earned reward for a successfully completed and undisputed inference.
 *
 * V. Dynamic Reputation & Treasury (6 functions)
 *    20. submitUserFeedback(...): Users provide subjective feedback (rating) on an inference result.
 *    21. getDynamicModelCost(bytes32 modelId): A view function that calculates the current effective cost of an AI model, integrating its base cost with its reputation and demand.
 *    22. withdrawProtocolFees(address recipient): Allows the owner/admin to withdraw accumulated protocol fees.
 *    23. setProtocolFee(uint256 newFeeBps): Sets the protocol fee in basis points.
 *    24. setReputationParameters(...): Governance function to adjust the influence of feedback/metrics on reputation scores, impacting dynamic pricing and oracle selection.
 *    25. depositStake(): Allows an oracle to increase their existing stake.
 */
contract Aetheria is Ownable, ReentrancyGuard, Pausable {

    // --- State Variables & Data Structures ---

    // Constants
    uint256 public constant MIN_ORACLE_STAKE = 1 ether; // Minimum ETH stake for an oracle
    uint256 public constant MAX_PROTOCOL_FEE_BPS = 1000; // Max 10% protocol fee

    // Protocol Fee
    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 100 for 1%)
    uint256 public totalProtocolFeesCollected;

    // Reputation Parameters
    uint256 public modelPerformanceToFeedbackRatio; // 0-100. X means X% from performance metrics, (100-X)% from user feedback for models.
    uint256 public oracleDisputePenaltyPoints;      // Points deducted from an oracle's reputation for each dispute lost.

    // Access control
    mapping(address => bool) public isAdmin;

    // AI Model Registry
    struct AIModel {
        string ipfsHash;            // IPFS hash pointing to model artifact/metadata
        string description;         // Human-readable description
        uint256 baseCost;           // Base cost for inference in wei
        uint256 maxInferenceTimeSeconds; // Max allowed time for an oracle to return result
        bytes32[] acceptedInputFormats; // Hashes representing accepted input data schemas
        bytes32[] outputFormats;    // Hashes representing possible output data schemas
        address provider;           // Address of the model provider
        bool isWhitelisted;         // Whether model is approved by governance for service
        uint256 lastUpdated;        // Timestamp of last update

        // Reputation metrics
        uint256 totalPerformanceScore; // Sum of accuracy scores from submitModelPerformanceMetric (0-100 per submission)
        uint256 performanceSubmissions; // Count of submitModelPerformanceMetric
        uint256 totalUserRating;    // Sum of user ratings from submitUserFeedback (1-5 per submission)
        uint256 userFeedbackCount;  // Count of user feedback submissions
    }
    mapping(bytes32 => AIModel) public aiModels; // modelId => AIModel

    // Oracle Node Registry
    struct OracleNode {
        string nodeUri;             // URI for the oracle's API endpoint / contact info
        uint256 stake;              // ETH staked by the oracle
        bytes32[] supportedModelIds; // List of model IDs this oracle claims to support
        bool isActive;              // Whether the oracle node is active
        uint256 lastHeartbeat;      // Timestamp of last activity/heartbeat (for future liveness checks)

        // Reputation metrics
        uint256 totalInferenceCount; // Total successful inferences
        uint256 totalDisputesLost;  // Count of disputes lost
        uint256 totalUserRating;    // Sum of user ratings for this oracle's inferences (1-5 per submission)
        uint256 userFeedbackCount;  // Count of user feedback submissions
    }
    mapping(address => OracleNode) public oracleNodes; // oracleAddress => OracleNode

    // Inference Requests
    enum RequestStatus { Pending, Executed, Disputed, Resolved, Completed, Failed }
    struct InferenceRequest {
        bytes32 modelId;
        bytes32 inputDataHash;      // IPFS hash or similar for input data
        bytes32 expectedOutputFormat; // Expected output schema
        address requester;          // Address of the user who made the request
        uint256 paymentAmount;      // Total amount charged by the protocol (dynamicCost)
        uint256 oracleReward;       // Amount allocated for the oracle
        uint256 protocolFee;        // Amount allocated for protocol fee
        address oracleExecutor;     // Address of the oracle who took the job
        bytes32 outputDataHash;     // IPFS hash or similar for output data
        uint256 submissionTime;     // Timestamp when result was submitted
        uint256 actualCost;         // Actual cost oracle reported (for tracking/future adjustments)
        RequestStatus status;
        uint256 callbackGasLimit;   // Gas limit for callback function
        address callbackAddress;    // Address to call back
        bytes callbackData;         // Data to pass to the callback
        uint256 disputeDeadline;    // Timestamp by which results can be disputed (or oracle must submit)
    }
    mapping(bytes32 => InferenceRequest) public inferenceRequests; // requestId => InferenceRequest

    // Dispute Resolution
    struct Dispute {
        bytes32 requestId;
        address disputer;
        string reasonHash;          // IPFS hash of the dispute reason
        bool isResolved;
        address winningParty;       // 0x0 if not resolved yet, or address of winner (requester/oracle)
        uint256 resolutionTimestamp;
        bytes32 resolutionHash;     // IPFS hash of the resolution details
    }
    mapping(bytes32 => Dispute) public disputes; // requestId => Dispute

    // Track if feedback has been submitted for a request to prevent multiple submissions
    mapping(bytes32 => bool) public hasFeedbackSubmitted;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ProtocolFeeSet(uint256 newFeeBps);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Paused(address account);
    event Unpaused(address account);

    event AIModelRegistered(bytes32 indexed modelId, address indexed provider, string ipfsHash, uint256 baseCost);
    event AIModelUpdated(bytes32 indexed modelId, string ipfsHash);
    event ModelWhitelistToggled(bytes32 indexed modelId, bool isWhitelisted);
    event ModelPerformanceMetricSubmitted(bytes32 indexed modelId, address indexed submitter, uint256 accuracyScore);

    event OracleNodeRegistered(address indexed oracleAddress, string nodeUri, uint256 stake);
    event OracleNodeUpdated(address indexed oracleAddress, string nodeUri);
    event OracleStakeSlashed(address indexed oracleAddress, uint256 amount, string reason);
    event OracleStakeDeposited(address indexed oracleAddress, uint256 amount);

    event InferenceRequested(bytes32 indexed requestId, bytes32 indexed modelId, address indexed requester, uint256 paymentAmount);
    event InferenceResultSubmitted(bytes32 indexed requestId, address indexed oracleExecutor, bytes32 outputDataHash, uint256 actualCost);
    event InferenceRewardClaimed(bytes32 indexed requestId, address indexed oracleExecutor, uint256 rewardAmount);
    event InferenceFailed(bytes32 indexed requestId, string reason); // For failed callbacks

    event InferenceDisputed(bytes32 indexed requestId, address indexed disputer, string reasonHash);
    event DisputeResolved(bytes32 indexed requestId, address indexed winningParty, uint256 penaltyToLoser, bytes32 resolutionHash);

    event UserFeedbackSubmitted(bytes32 indexed requestId, address indexed sender, uint8 rating);
    event ReputationParametersSet(uint256 modelPerformanceToFeedbackRatio, uint256 oracleDisputePenaltyPoints);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || owner() == msg.sender, "Aetheria: Caller is not an admin");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        protocolFeeBps = 100; // 1% default fee
        modelPerformanceToFeedbackRatio = 70; // 70% performance, 30% user feedback for models
        oracleDisputePenaltyPoints = 15; // 15 points deducted for each lost oracle dispute
        isAdmin[msg.sender] = true; // Owner is also an admin
        
        emit AdminAdded(msg.sender);
        emit ProtocolFeeSet(protocolFeeBps);
        emit ReputationParametersSet(modelPerformanceToFeedbackRatio, oracleDisputePenaltyPoints);
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Transfers ownership of the contract. Only the current owner can call this.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner); // Use Ownable's transferOwnership
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /**
     * @dev Adds an address to the list of contract administrators.
     * @param _admin The address to grant admin privileges.
     */
    function addAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "Aetheria: Invalid admin address");
        require(!isAdmin[_admin], "Aetheria: Address is already an admin");
        isAdmin[_admin] = true;
        emit AdminAdded(_admin);
    }

    /**
     * @dev Removes an address from the list of contract administrators.
     * @param _admin The address to revoke admin privileges from.
     */
    function removeAdmin(address _admin) public onlyOwner {
        require(_admin != address(0), "Aetheria: Invalid admin address");
        require(isAdmin[_admin], "Aetheria: Address is not an admin");
        require(_admin != owner(), "Aetheria: Cannot remove owner as admin"); // Owner is always an admin
        isAdmin[_admin] = false;
        emit AdminRemoved(_admin);
    }

    /**
     * @dev Pauses the contract. Only the owner or an admin can call this.
     */
    function pause() public onlyAdmin whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only the owner or an admin can call this.
     */
    function unpause() public onlyAdmin whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- II. AI Model Management ---

    /**
     * @dev Registers a new AI model provider.
     * @param modelId Unique identifier for the model (e.g., keccak256 of model name/URI).
     * @param ipfsHash IPFS hash pointing to the model artifact or detailed metadata.
     * @param description Human-readable description of the model.
     * @param baseCost Base cost in wei for a single inference using this model.
     * @param maxInferenceTimeSeconds Maximum time an oracle has to return a result for this model.
     * @param acceptedInputFormats Hashes representing accepted input data schemas.
     * @param outputFormats Hashes representing possible output data schemas.
     */
    function registerAIModel(
        bytes32 modelId,
        string calldata ipfsHash,
        string calldata description,
        uint256 baseCost,
        uint256 maxInferenceTimeSeconds,
        bytes32[] calldata acceptedInputFormats,
        bytes32[] calldata outputFormats
    ) public whenNotPaused {
        require(modelId != bytes32(0), "Aetheria: Invalid model ID");
        require(aiModels[modelId].provider == address(0), "Aetheria: Model ID already registered");
        require(bytes(ipfsHash).length > 0, "Aetheria: IPFS hash cannot be empty");
        require(baseCost > 0, "Aetheria: Base cost must be greater than zero");
        require(maxInferenceTimeSeconds > 0, "Aetheria: Max inference time must be greater than zero");
        require(acceptedInputFormats.length > 0, "Aetheria: Must specify accepted input formats");
        require(outputFormats.length > 0, "Aetheria: Must specify output formats");

        aiModels[modelId] = AIModel({
            ipfsHash: ipfsHash,
            description: description,
            baseCost: baseCost,
            maxInferenceTimeSeconds: maxInferenceTimeSeconds,
            acceptedInputFormats: acceptedInputFormats,
            outputFormats: outputFormats,
            provider: msg.sender,
            isWhitelisted: false, // Requires governance approval
            lastUpdated: block.timestamp,
            totalPerformanceScore: 0,
            performanceSubmissions: 0,
            totalUserRating: 0,
            userFeedbackCount: 0
        });

        emit AIModelRegistered(modelId, msg.sender, ipfsHash, baseCost);
    }

    /**
     * @dev Allows the model provider to update details of their registered AI model.
     * @param modelId The ID of the model to update.
     * @param ipfsHash New IPFS hash.
     * @param description New description.
     * @param baseCost New base cost.
     * @param maxInferenceTimeSeconds New max inference time.
     */
    function updateAIModelDetails(
        bytes32 modelId,
        string calldata ipfsHash,
        string calldata description,
        uint256 baseCost,
        uint256 maxInferenceTimeSeconds
    ) public whenNotPaused {
        AIModel storage model = aiModels[modelId];
        require(model.provider == msg.sender, "Aetheria: Not the model provider");
        require(bytes(ipfsHash).length > 0, "Aetheria: IPFS hash cannot be empty");
        require(baseCost > 0, "Aetheria: Base cost must be greater than zero");
        require(maxInferenceTimeSeconds > 0, "Aetheria: Max inference time must be greater than zero");

        model.ipfsHash = ipfsHash;
        model.description = description;
        model.baseCost = baseCost;
        model.maxInferenceTimeSeconds = maxInferenceTimeSeconds;
        model.lastUpdated = block.timestamp;

        emit AIModelUpdated(modelId, ipfsHash);
    }

    /**
     * @dev Governance function to whitelist or blacklist an AI model for active service.
     *      Only whitelisted models can be used for inferences.
     * @param modelId The ID of the model to toggle.
     * @param isWhitelisted True to whitelist, false to blacklist.
     */
    function toggleModelWhitelist(bytes32 modelId, bool isWhitelisted) public onlyAdmin whenNotPaused {
        AIModel storage model = aiModels[modelId];
        require(model.provider != address(0), "Aetheria: Model not registered");
        require(model.isWhitelisted != isWhitelisted, "Aetheria: Model whitelist status already as requested");

        model.isWhitelisted = isWhitelisted;
        emit ModelWhitelistToggled(modelId, isWhitelisted);
    }

    /**
     * @dev Admins or designated reporters submit objective performance metrics for a model.
     *      This data contributes to the model's reputation score.
     * @param modelId The ID of the model being evaluated.
     * @param accuracyScore A score representing the model's accuracy (e.g., 0-100).
     * @param metadataHash IPFS hash of detailed performance report metadata (optional).
     */
    function submitModelPerformanceMetric(
        bytes32 modelId,
        uint256 accuracyScore,
        bytes32 metadataHash // For off-chain details
    ) public onlyAdmin whenNotPaused { // Restricting to admin for objective reporting for now, could be designated "data providers"
        AIModel storage model = aiModels[modelId];
        require(model.provider != address(0), "Aetheria: Model not registered");
        require(accuracyScore <= 100, "Aetheria: Accuracy score must be 0-100");

        model.totalPerformanceScore += accuracyScore;
        model.performanceSubmissions++;

        emit ModelPerformanceMetricSubmitted(modelId, msg.sender, accuracyScore);
    }

    /**
     * @dev Retrieves comprehensive details about a specific registered AI model.
     * @param modelId The ID of the model to retrieve.
     * @return tuple of model details.
     */
    function getAIModelDetails(bytes32 modelId)
        public
        view
        returns (
            string memory ipfsHash,
            string memory description,
            uint256 baseCost,
            uint256 maxInferenceTimeSeconds,
            bytes32[] memory acceptedInputFormats,
            bytes32[] memory outputFormats,
            address provider,
            bool isWhitelisted,
            uint256 lastUpdated,
            uint256 currentReputationScore // Calculated reputation (0-100 scale)
        )
    {
        AIModel storage model = aiModels[modelId];
        require(model.provider != address(0), "Aetheria: Model not registered");

        uint256 repScore = 0;
        uint256 weightedPerformance = 0;
        if (model.performanceSubmissions > 0) {
            weightedPerformance = (model.totalPerformanceScore * modelPerformanceToFeedbackRatio) / model.performanceSubmissions;
        }
        uint256 weightedUserFeedback = 0;
        if (model.userFeedbackCount > 0) {
            weightedUserFeedback = ((model.totalUserRating * 20) * (100 - modelPerformanceToFeedbackRatio)) / model.userFeedbackCount; // Scale 1-5 to 0-100
        }
        
        if (model.performanceSubmissions > 0 || model.userFeedbackCount > 0) {
            // Divide by 100 to scale the combined weighted sum (max 100*100) to 0-100
            repScore = (weightedPerformance + weightedUserFeedback) / 100;
        }

        return (
            model.ipfsHash,
            model.description,
            model.baseCost,
            model.maxInferenceTimeSeconds,
            model.acceptedInputFormats,
            model.outputFormats,
            model.provider,
            model.isWhitelisted,
            model.lastUpdated,
            repScore
        );
    }

    // --- III. Oracle/Validator Management ---

    /**
     * @dev Oracles register their compute node to perform AI inferences.
     *      Requires a minimum stake of ETH.
     * @param nodeUri URI for the oracle's API endpoint or contact info.
     * @param supportedModelIds List of model IDs this oracle claims to support.
     */
    function registerOracleNode(
        string calldata nodeUri,
        bytes32[] calldata supportedModelIds
    ) public payable whenNotPaused {
        require(oracleNodes[msg.sender].isActive == false, "Aetheria: Oracle already registered");
        require(msg.value >= MIN_ORACLE_STAKE, "Aetheria: Insufficient stake");
        require(bytes(nodeUri).length > 0, "Aetheria: Node URI cannot be empty");
        require(supportedModelIds.length > 0, "Aetheria: Must support at least one model");

        oracleNodes[msg.sender] = OracleNode({
            nodeUri: nodeUri,
            stake: msg.value,
            supportedModelIds: supportedModelIds,
            isActive: true,
            lastHeartbeat: block.timestamp,
            totalInferenceCount: 0,
            totalDisputesLost: 0,
            totalUserRating: 0,
            userFeedbackCount: 0
        });

        emit OracleNodeRegistered(msg.sender, nodeUri, msg.value);
    }

    /**
     * @dev Allows an existing oracle to update their node details and supported models.
     * @param nodeUri New URI for the oracle's API endpoint.
     * @param supportedModelIds New list of model IDs this oracle supports.
     */
    function updateOracleNode(
        string calldata nodeUri,
        bytes32[] calldata supportedModelIds
    ) public whenNotPaused {
        OracleNode storage oracle = oracleNodes[msg.sender];
        require(oracle.isActive, "Aetheria: Oracle not registered or inactive");
        require(bytes(nodeUri).length > 0, "Aetheria: Node URI cannot be empty");
        require(supportedModelIds.length > 0, "Aetheria: Must support at least one model");

        oracle.nodeUri = nodeUri;
        oracle.supportedModelIds = supportedModelIds;
        oracle.lastHeartbeat = block.timestamp;

        emit OracleNodeUpdated(msg.sender, nodeUri);
    }

    /**
     * @dev Allows an oracle to increase their existing stake.
     */
    function depositStake() public payable whenNotPaused {
        OracleNode storage oracle = oracleNodes[msg.sender];
        require(oracle.isActive, "Aetheria: Oracle not registered or inactive");
        require(msg.value > 0, "Aetheria: Deposit amount must be greater than zero");

        oracle.stake += msg.value;
        emit OracleStakeDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Governance or dispute resolution slashes an oracle's stake for misconduct.
     *      The slashed amount is added to totalProtocolFeesCollected.
     * @param oracleAddress The address of the oracle whose stake is to be slashed.
     * @param amount The amount of ETH to slash from their stake.
     * @param reason Human-readable reason for the slashing (or IPFS hash).
     */
    function slashOracleStake(address oracleAddress, uint256 amount, string calldata reason) public onlyAdmin whenNotPaused {
        OracleNode storage oracle = oracleNodes[oracleAddress];
        require(oracle.isActive, "Aetheria: Oracle not registered or inactive");
        require(oracle.stake >= amount, "Aetheria: Slash amount exceeds oracle's stake");
        require(amount > 0, "Aetheria: Slash amount must be greater than zero");

        oracle.stake -= amount;
        totalProtocolFeesCollected += amount;

        // If stake drops below MIN_ORACLE_STAKE, deactivate
        if (oracle.stake < MIN_ORACLE_STAKE) {
            oracle.isActive = false;
        }

        emit OracleStakeSlashed(oracleAddress, amount, reason);
    }

    /**
     * @dev Retrieves details about a specific registered oracle node.
     * @param oracleAddress The address of the oracle node.
     * @return tuple of oracle node details.
     */
    function getOracleNodeDetails(address oracleAddress)
        public
        view
        returns (
            string memory nodeUri,
            uint256 stake,
            bytes32[] memory supportedModelIds,
            bool isActive,
            uint256 lastHeartbeat,
            uint256 currentReputationScore // Calculated reputation (0-100 scale)
        )
    {
        OracleNode storage oracle = oracleNodes[oracleAddress];
        require(oracle.isActive, "Aetheria: Oracle not registered or inactive");

        uint256 repScore = 0;
        uint256 feedbackScore = 0;
        if (oracle.userFeedbackCount > 0) {
            feedbackScore = (oracle.totalUserRating * 20) / oracle.userFeedbackCount; // Scale 1-5 rating to 0-100
        }
        
        uint256 disputePenalty = oracle.totalDisputesLost * oracleDisputePenaltyPoints;

        if (oracle.userFeedbackCount > 0) { // If there's feedback, it's the primary driver
            repScore = feedbackScore;
            repScore = repScore > disputePenalty ? repScore - disputePenalty : 0;
        } else if (oracle.totalInferenceCount > 0) { // If no feedback, base on success rate
            uint256 successfulInferences = oracle.totalInferenceCount > oracle.totalDisputesLost ? oracle.totalInferenceCount - oracle.totalDisputesLost : 0;
            repScore = (successfulInferences * 100) / oracle.totalInferenceCount;
            repScore = repScore > disputePenalty ? repScore - disputePenalty : 0; // Still apply penalty
        }
        // Ensure score doesn't exceed 100
        if (repScore > 100) repScore = 100;

        return (
            oracle.nodeUri,
            oracle.stake,
            oracle.supportedModelIds,
            oracle.isActive,
            oracle.lastHeartbeat,
            repScore
        );
    }

    // --- IV. AI Request & Execution Flow ---

    /**
     * @dev Users request an AI inference. They pay the maximum acceptable cost,
     *      and specify a callback for asynchronous result delivery.
     * @param modelId The ID of the AI model to use.
     * @param inputDataHash IPFS hash or similar for the input data.
     * @param expectedOutputFormat Expected output data schema hash.
     * @param maxCost Maximum cost (in wei) the requester is willing to pay.
     * @param callbackGasLimit Gas limit for the callback function execution.
     * @param callbackAddress Address to call back with the result.
     * @param callbackData Data to be included in the callback function call.
     * @return requestId The unique ID of the created inference request.
     */
    function requestAIInference(
        bytes32 modelId,
        bytes32 inputDataHash,
        bytes32 expectedOutputFormat,
        uint256 maxCost,
        uint256 callbackGasLimit,
        address callbackAddress,
        bytes calldata callbackData
    ) public payable nonReentrant whenNotPaused returns (bytes32 requestId) {
        AIModel storage model = aiModels[modelId];
        require(model.provider != address(0), "Aetheria: Model not registered");
        require(model.isWhitelisted, "Aetheria: Model is not whitelisted for service");
        require(msg.value >= maxCost, "Aetheria: Insufficient payment provided for max cost");
        require(maxCost > 0, "Aetheria: Max cost must be greater than zero");
        require(inputDataHash != bytes32(0), "Aetheria: Invalid input data hash");

        uint256 dynamicCost = getDynamicModelCost(modelId);
        require(dynamicCost <= maxCost, "Aetheria: Dynamic cost exceeds max cost specified by requester");
        require(dynamicCost > 0, "Aetheria: Dynamic cost must be greater than zero");

        // Calculate fees
        uint256 currentProtocolFee = (dynamicCost * protocolFeeBps) / 10000;
        uint256 oracleRewardAmount = dynamicCost - currentProtocolFee;

        // Generate unique request ID
        requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, modelId, inputDataHash, block.number));
        // Check for (extremely unlikely) collision for the new request ID
        require(inferenceRequests[requestId].status == RequestStatus.Pending, "Aetheria: Request ID collision, please retry"); 

        inferenceRequests[requestId] = InferenceRequest({
            modelId: modelId,
            inputDataHash: inputDataHash,
            expectedOutputFormat: expectedOutputFormat,
            requester: msg.sender,
            paymentAmount: dynamicCost, // Actual amount charged based on dynamic cost
            oracleReward: oracleRewardAmount,
            protocolFee: currentProtocolFee,
            oracleExecutor: address(0), // To be filled by oracle
            outputDataHash: bytes32(0),
            submissionTime: 0,
            actualCost: 0,
            status: RequestStatus.Pending,
            callbackGasLimit: callbackGasLimit,
            callbackAddress: callbackAddress,
            callbackData: callbackData,
            disputeDeadline: block.timestamp + model.maxInferenceTimeSeconds // Deadline for oracle to submit result
        });

        totalProtocolFeesCollected += currentProtocolFee; // Immediately add protocol fees to collected

        // Refund any excess ETH
        if (msg.value > dynamicCost) {
            payable(msg.sender).transfer(msg.value - dynamicCost);
        }

        emit InferenceRequested(requestId, modelId, msg.sender, dynamicCost);
        return requestId;
    }

    /**
     * @dev An oracle submits the result for a specific inference request.
     * @param requestId The ID of the inference request.
     * @param outputDataHash IPFS hash or similar for the output data.
     * @param modelId The model ID that was executed (for verification).
     * @param inputDataHash The input data hash (for verification).
     * @param executionTimeMs The time taken for the inference in milliseconds (for performance tracking).
     * @param actualCost The actual cost incurred by the oracle (for tracking/future dynamic adjustments, cannot exceed paymentAmount).
     */
    function submitAIInferenceResult(
        bytes32 requestId,
        bytes32 outputDataHash,
        bytes32 modelId, // Redundant but good for sanity check
        bytes32 inputDataHash, // Redundant but good for sanity check
        uint256 executionTimeMs, // For performance tracking
        uint256 actualCost // Oracle's reported cost, for future dynamic adjustments
    ) public nonReentrant whenNotPaused {
        InferenceRequest storage req = inferenceRequests[requestId];
        OracleNode storage oracle = oracleNodes[msg.sender];
        
        require(oracle.isActive, "Aetheria: Caller is not an active oracle");
        require(req.status == RequestStatus.Pending, "Aetheria: Request not in pending status or already handled");
        require(req.modelId == modelId, "Aetheria: Mismatched model ID for request");
        require(req.inputDataHash == inputDataHash, "Aetheria: Mismatched input data hash for request");
        require(block.timestamp <= req.disputeDeadline, "Aetheria: Submission deadline passed for oracle");
        require(outputDataHash != bytes32(0), "Aetheria: Output data hash cannot be empty");
        require(actualCost <= req.paymentAmount, "Aetheria: Actual cost cannot exceed payment amount");

        // Check if the oracle actually supports this model
        bool supportsModel = false;
        for (uint i = 0; i < oracle.supportedModelIds.length; i++) {
            if (oracle.supportedModelIds[i] == modelId) {
                supportsModel = true;
                break;
            }
        }
        require(supportsModel, "Aetheria: Oracle does not support this model");

        req.oracleExecutor = msg.sender;
        req.outputDataHash = outputDataHash;
        req.submissionTime = block.timestamp;
        req.actualCost = actualCost;
        req.status = RequestStatus.Executed;
        req.disputeDeadline = block.timestamp + (2 days); // Set dispute window after execution, typically longer than oracle submission deadline

        // Update oracle metrics
        oracle.totalInferenceCount++;

        emit InferenceResultSubmitted(requestId, msg.sender, outputDataHash, actualCost);

        // Perform callback if specified
        if (req.callbackAddress != address(0)) {
            // It's a best-effort call. If it fails, the main transaction should not revert.
            (bool success,) = req.callbackAddress.call{gas: req.callbackGasLimit}(
                abi.encodePacked(requestId, outputDataHash, req.callbackData)
            );
            if (!success) {
                emit InferenceFailed(requestId, "Callback execution failed");
            }
        }
    }

    /**
     * @dev Allows a user (requester) or another oracle to dispute a submitted inference result.
     *      Requires the request to be in 'Executed' status and within the dispute window.
     * @param requestId The ID of the inference request to dispute.
     * @param reasonHash IPFS hash of the detailed reason for the dispute.
     */
    function disputeAIInferenceResult(bytes32 requestId, string calldata reasonHash) public whenNotPaused {
        InferenceRequest storage req = inferenceRequests[requestId];
        require(req.status == RequestStatus.Executed, "Aetheria: Request not in executed status");
        require(block.timestamp <= req.disputeDeadline, "Aetheria: Dispute deadline passed");
        require(msg.sender == req.requester || oracleNodes[msg.sender].isActive, "Aetheria: Only requester or active oracle can dispute");
        require(disputes[requestId].requestId == bytes32(0), "Aetheria: Request already disputed");

        disputes[requestId] = Dispute({
            requestId: requestId,
            disputer: msg.sender,
            reasonHash: reasonHash,
            isResolved: false,
            winningParty: address(0),
            resolutionTimestamp: 0,
            resolutionHash: bytes32(0)
        });

        req.status = RequestStatus.Disputed;
        emit InferenceDisputed(requestId, msg.sender, reasonHash);
    }

    /**
     * @dev Governance/Dispute Resolver determines the outcome of a dispute.
     *      Distributes funds/penalties based on the resolution.
     * @param requestId The ID of the disputed inference request.
     * @param winningParty The address of the party who won the dispute (requester or oracle).
     * @param penaltyToLoser Amount to penalize the losing party (e.g., slash oracle stake).
     * @param resolutionHash IPFS hash of the detailed resolution statement.
     */
    function resolveDispute(
        bytes32 requestId,
        address winningParty,
        uint256 penaltyToLoser,
        bytes32 resolutionHash
    ) public onlyAdmin nonReentrant whenNotPaused {
        InferenceRequest storage req = inferenceRequests[requestId];
        Dispute storage dispute = disputes[requestId];

        require(req.status == RequestStatus.Disputed, "Aetheria: Request is not in disputed status");
        require(!dispute.isResolved, "Aetheria: Dispute already resolved");
        require(winningParty == req.requester || winningParty == req.oracleExecutor, "Aetheria: Invalid winning party (must be requester or oracleExecutor)");

        dispute.isResolved = true;
        dispute.winningParty = winningParty;
        dispute.resolutionTimestamp = block.timestamp;
        dispute.resolutionHash = resolutionHash;

        if (winningParty == req.requester) {
            // Requester wins: refund requester, penalize oracle
            payable(req.requester).transfer(req.paymentAmount); // Refund full payment (for now)
            
            OracleNode storage oracle = oracleNodes[req.oracleExecutor];
            if (oracle.stake >= penaltyToLoser) { 
                oracle.stake -= penaltyToLoser; // Slash from stake
                totalProtocolFeesCollected += penaltyToLoser; // Slashed amount goes to protocol
            } else { // If penalty exceeds stake, slash all stake
                totalProtocolFeesCollected += oracle.stake;
                oracle.stake = 0;
            }
            oracle.totalDisputesLost++;
            req.oracleReward = 0; // Oracle forfeits reward
            req.status = RequestStatus.Resolved; // Oracle fails, requester refunded
        } else { // Oracle wins (winningParty == req.oracleExecutor)
            // Oracle wins: oracle is eligible to claim reward. Requester's payment is finalized (not refunded).
            // PenaltyToLoser here would apply to the disputer, if not the requester.
            // For simplicity, if requester disputed and lost, they simply don't get a refund and oracle claims.
            req.status = RequestStatus.Resolved; // Requester loses, oracle still needs to claim.
        }

        emit DisputeResolved(requestId, winningParty, penaltyToLoser, resolutionHash);
    }

    /**
     * @dev Oracles claim their earned reward for a successfully completed and undisputed inference.
     * @param requestId The ID of the inference request.
     */
    function claimInferenceReward(bytes32 requestId) public nonReentrant whenNotPaused {
        InferenceRequest storage req = inferenceRequests[requestId];
        require(req.oracleExecutor == msg.sender, "Aetheria: Not the executor of this request");
        require(req.status != RequestStatus.Pending && req.status != RequestStatus.Disputed && req.status != RequestStatus.Completed, "Aetheria: Request not in eligible status for claim");
        
        // Check if dispute window has passed for 'Executed' requests
        if (req.status == RequestStatus.Executed) {
            require(block.timestamp > req.disputeDeadline, "Aetheria: Dispute window is still open");
        }
        // If dispute was resolved in favor of oracle, it's claimable
        if (req.status == RequestStatus.Resolved) {
            require(disputes[requestId].winningParty == msg.sender, "Aetheria: Dispute not resolved in favor of this oracle");
        }
        
        uint256 rewardAmount = req.oracleReward;
        req.oracleReward = 0; // Prevent double claim
        req.status = RequestStatus.Completed; // Mark as fully completed

        payable(msg.sender).transfer(rewardAmount);
        emit InferenceRewardClaimed(requestId, msg.sender, rewardAmount);
    }

    // --- V. Dynamic Reputation & Treasury ---

    /**
     * @dev Users provide subjective feedback (rating 1-5) on the quality of a specific inference result.
     *      This feedback contributes to both the model's and the oracle's reputation.
     * @param requestId The ID of the inference request for which feedback is provided.
     * @param rating User's rating (1-5).
     * @param commentHash IPFS hash of a detailed comment/review (optional).
     */
    function submitUserFeedback(
        bytes32 requestId,
        uint8 rating,
        string calldata commentHash // For off-chain detailed feedback
    ) public whenNotPaused {
        InferenceRequest storage req = inferenceRequests[requestId];
        require(req.requester == msg.sender, "Aetheria: Only the requester can submit feedback");
        require(req.status == RequestStatus.Completed || req.status == RequestStatus.Executed, "Aetheria: Request not completed or executed");
        require(rating >= 1 && rating <= 5, "Aetheria: Rating must be between 1 and 5");
        require(!hasFeedbackSubmitted[requestId], "Aetheria: Feedback already submitted for this request");

        AIModel storage model = aiModels[req.modelId];
        model.totalUserRating += rating;
        model.userFeedbackCount++;

        OracleNode storage oracle = oracleNodes[req.oracleExecutor];
        oracle.totalUserRating += rating;
        oracle.userFeedbackCount++;
        
        hasFeedbackSubmitted[requestId] = true;

        emit UserFeedbackSubmitted(requestId, msg.sender, rating);
    }

    /**
     * @dev Calculates the current effective cost for an AI model, factoring in its base cost,
     *      reputation, and potentially demand (though demand is not implemented in this version).
     *      Higher reputation could lead to a premium, lower reputation could impose a discount.
     * @param modelId The ID of the AI model.
     * @return The dynamic cost in wei.
     */
    function getDynamicModelCost(bytes32 modelId) public view returns (uint256) {
        AIModel storage model = aiModels[modelId];
        require(model.provider != address(0), "Aetheria: Model not registered");

        uint256 baseCost = model.baseCost;
        uint256 currentReputation = getAIModelDetails(modelId).currentReputationScore; // This calls a view function that recalculates reputation

        // Example dynamic pricing logic:
        if (currentReputation >= 80) {
            return (baseCost * 105) / 100; // 5% premium for high reputation
        } else if (currentReputation <= 40) {
            return (baseCost * 90) / 100; // 10% discount for low reputation
        } else {
            return baseCost; // No change for average reputation
        }
    }

    /**
     * @dev Allows the owner/admin to withdraw accumulated protocol fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) public onlyAdmin nonReentrant {
        require(recipient != address(0), "Aetheria: Invalid recipient address");
        require(totalProtocolFeesCollected > 0, "Aetheria: No fees to withdraw");

        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;

        payable(recipient).transfer(amount);
        emit ProtocolFeesWithdrawn(recipient, amount);
    }

    /**
     * @dev Sets the protocol fee in basis points (e.g., 100 for 1%).
     * @param newFeeBps The new fee in basis points. Must be <= MAX_PROTOCOL_FEE_BPS.
     */
    function setProtocolFee(uint256 newFeeBps) public onlyAdmin whenNotPaused {
        require(newFeeBps <= MAX_PROTOCOL_FEE_BPS, "Aetheria: Fee exceeds max allowed");
        protocolFeeBps = newFeeBps;
        emit ProtocolFeeSet(newFeeBps);
    }

    /**
     * @dev Governance function to adjust reputation calculation parameters.
     * @param _modelPerformanceToFeedbackRatio How much objective performance metrics weigh (0-100)
     *        vs. subjective user feedback for a model's reputation (100 - this value).
     * @param _oracleDisputePenaltyPoints Points deducted from an oracle's reputation for each dispute lost.
     */
    function setReputationParameters(
        uint256 _modelPerformanceToFeedbackRatio,
        uint256 _oracleDisputePenaltyPoints
    ) public onlyAdmin whenNotPaused {
        require(_modelPerformanceToFeedbackRatio <= 100, "Aetheria: Performance ratio must be 0-100");
        modelPerformanceToFeedbackRatio = _modelPerformanceToFeedbackRatio;
        oracleDisputePenaltyPoints = _oracleDisputePenaltyPoints;

        emit ReputationParametersSet(modelPerformanceToFeedbackRatio, oracleDisputePenaltyPoints);
    }
}
```