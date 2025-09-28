The following smart contract, `DeVAiN_CognitoNexus`, establishes a Decentralized Verifiable AI Agent Network (DeVAiN). It's designed to be an advanced, creative, and trendy platform for AI computation, leveraging several cutting-edge blockchain concepts.

---

**Contract: `DeVAiN_CognitoNexus`**

This smart contract establishes a Decentralized Verifiable AI Agent Network (DeVAiN). It orchestrates a marketplace for AI computation, where users can request tasks, and various providers (AI models, compute providers, data providers) collaborate to execute them. A core tenet is the verifiable integrity of computation through ZK/optimistic proofs, alongside a reputation system, staking mechanisms, and decentralized governance.

**I. Registry Management**
    *   `registerAIModel`: Registers a new AI model, specifying its capabilities and resource requirements. Models are the "agents" available for tasks.
    *   `updateAIModelCapabilities`: Allows the owner of an AI model to update its described capabilities, enabling dynamic agent evolution.
    *   `deregisterAIModel`: Initiates the process to remove an AI model from the network, subject to governance or cooldown.
    *   `registerComputeProvider`: Onboards a new compute provider, requiring an initial stake and declaration of available resources.
    *   `updateComputeProviderResources`: Lets a compute provider declare changes in their available compute capacity or memory.
    *   `deregisterComputeProvider`: Removes a compute provider, potentially slashing their stake based on active tasks or reputation.
    *   `registerDataProvider`: Registers a data provider with details about their dataset, required access fees, and an initial stake.
    *   `updateDataProviderDetails`: Updates a data provider's dataset description or access fee structure.
    *   `deregisterDataProvider`: Removes a data provider from the network, with potential stake implications.

**II. Task Orchestration & Execution**
    *   `requestAITask`: Initiates an AI computation task, specifying the desired model, input parameters (hash), and maximum budget for compute and data. Funds are escrowed.
    *   `proposeTaskAssignment`: (Internal/Privileged) Proposes a specific compute provider and data provider to execute a `Requested` task based on matching algorithms or bidding.
    *   `acceptTaskAssignment`: Compute and Data providers confirm their acceptance of a proposed task assignment.
    *   `submitTaskProof`: The assigned compute provider submits the task's output hash and an accompanying cryptographic proof (e.g., ZK-SNARK, ZK-STARK) of correct execution.
    *   `verifyTaskProof`: Triggers the on-chain verification of the submitted proof using a pre-registered verifier contract corresponding to the `ProofType`.
    *   `settleTask`: Finalizes a task after successful proof verification, distributing rewards to providers and returning unused funds to the requester. Automatically adjusts reputation.

**III. Reputation & Staking Mechanics**
    *   `stakeFunds`: Allows any registered provider (compute, data) to increase their staked collateral, enhancing their reputation and potential for task assignments.
    *   `unstakeFunds`: Initiates the withdrawal of staked funds, subject to a network-defined cooldown period to ensure accountability.
    *   `_slashStake`: (Internal) Penalizes a provider by reducing their stake due to failed proofs, non-compliance, or malicious behavior.
    *   `_evaluateAndAdjustReputation`: (Internal) Adjusts a provider's reputation score based on task performance, proof success rates, and other metrics.

**IV. Decentralized Governance & Parameters**
    *   `proposeSystemParameterChange`: Allows authorized entities to propose changes to critical contract parameters (e.g., fee percentages, cooldown periods).
    *   `voteOnProposal`: Enables eligible token holders or governance members to cast votes on active proposals.
    *   `executeProposal`: Executes a proposal that has met the required voting threshold and passed its timelock.
    *   `setProofVerifierContract`: Sets or updates the address of a specific verifier contract for a given `ProofType`. This is crucial for modular proof systems.
    *   `upgradeImplementation`: Facilitates contract upgradability by pointing to a new logic contract (requires a proxy pattern, assumed here).

**V. Funding & Tokenomics**
    *   `depositFunds`: Allows users to deposit native currency (e.g., ETH) into the contract, primarily for funding task requests.
    *   `withdrawUserFunds`: Enables users to withdraw their unspent deposited funds.
    *   `withdrawProviderEarnings`: Allows compute and data providers to claim their accumulated rewards from completed tasks.

**VI. Advanced Discovery & Management**
    *   `addModelSemanticTag`: Attaches descriptive, searchable semantic tags to AI models, enhancing discovery for complex task requests.
    *   `addDataSemanticTag`: Attaches semantic tags to datasets, aiding in intelligent matching of data to AI models.
    *   `getModelsByTag`: (View) Retrieves a list of AI models that possess a specific semantic tag.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title DeVAiN_CognitoNexus
 * @dev This smart contract establishes a Decentralized Verifiable AI Agent Network (DeVAiN).
 *      It orchestrates a marketplace for AI computation, where users can request tasks, and various providers
 *      (AI models, compute providers, data providers) collaborate to execute them.
 *      A core tenet is the verifiable integrity of computation through ZK/optimistic proofs,
 *      alongside a reputation system, staking mechanisms, and decentralized governance.
 *
 *      This contract incorporates advanced concepts like:
 *      - Modular ZK/Optimistic Proof Verification
 *      - On-chain Reputation & Staking for various provider types
 *      - Decentralized Governance for system parameters and critical actions
 *      - Semantic Tagging for AI model and dataset discovery
 *      - UUPS Proxy Pattern for Upgradability (requiring an external proxy contract)
 *      - Complex Task Orchestration involving multiple roles (requester, model, compute, data)
 */
contract DeVAiN_CognitoNexus is Initializable, Ownable, UUPSUpgradeable {

    // --- Enums and Structs ---

    /**
     * @dev Defines the types of entities participating in the network.
     */
    enum EntityType {
        Model,
        ComputeProvider,
        DataProvider
    }

    /**
     * @dev Statuses for an AI computation task.
     */
    enum TaskStatus {
        Requested,          // Task initiated by a user, awaiting assignment.
        Assigned,           // Compute and Data providers have been assigned and accepted.
        ProofSubmitted,     // Compute provider has submitted results and proof.
        ProofVerified,      // Proof was successfully verified on-chain.
        ProofFailed,        // Proof failed on-chain verification.
        Succeeded,          // Task successfully completed and rewards distributed.
        Failed              // Task failed (e.g., due to failed proof or timeout).
    }

    /**
     * @dev Supported proof types for verifiable computation.
     */
    enum ProofType {
        ZK_SNARK,
        ZK_STARK,
        Optimistic
    }

    /**
     * @dev Represents an AI model registered in the network.
     */
    struct AIModel {
        address owner;                      // Owner of the AI model.
        string name;                        // Human-readable name of the model.
        bytes32 capabilityHash;             // IPFS/Arweave hash pointing to model capabilities/description.
        uint256 requiredComputeUnits;       // Estimated compute units required for typical inference.
        uint256 requiredMemoryGB;           // Estimated memory in GB required for typical inference.
        uint256 reputationScore;            // Reputation score of the model (can influence task assignment).
        bool active;                        // Whether the model is currently active and available.
        string[] semanticTags;              // Tags for semantic search (e.g., "ImageRecognition", "NLP", "Forecasting").
    }

    /**
     * @dev Represents a compute provider.
     */
    struct ComputeProvider {
        address owner;                      // Address of the compute provider.
        string name;                        // Human-readable name.
        uint256 availableComputeUnits;      // Total compute units offered.
        uint256 availableMemoryGB;          // Total memory in GB offered.
        uint256 stakedAmount;               // Amount of collateral staked.
        uint256 reputationScore;            // Reputation score (higher for reliable providers).
        uint256 lastUnstakeRequestTime;     // Timestamp of last unstake request.
        uint256 activeTaskCount;            // Number of tasks currently assigned to this provider.
        bool active;                        // Whether the provider is active.
    }

    /**
     * @dev Represents a data provider.
     */
    struct DataProvider {
        address owner;                      // Address of the data provider.
        string name;                        // Human-readable name.
        bytes32 datasetHash;                // IPFS/Arweave hash pointing to dataset metadata/access info.
        string description;                 // Short description of the dataset.
        uint256 accessFeePerUnit;           // Fee per unit of data accessed (e.g., per GB).
        uint256 stakedAmount;               // Amount of collateral staked.
        uint256 reputationScore;            // Reputation score.
        uint256 lastUnstakeRequestTime;     // Timestamp of last unstake request.
        bool active;                        // Whether the provider is active.
        string[] semanticTags;              // Tags for semantic search (e.g., "FinancialData", "MedicalImages").
    }

    /**
     * @dev Represents an AI task requested by a user.
     */
    struct AITask {
        uint256 taskId;                     // Unique identifier for the task.
        address requester;                  // Address of the task requester.
        uint256 modelId;                    // ID of the AI model to be used.
        uint256 computeProviderId;          // ID of the assigned compute provider.
        uint256 dataProviderId;             // ID of the assigned data provider.
        bytes32 inputDataHash;              // Hash of the input data for the task.
        bytes32 outputDataHash;             // Hash of the output data after computation.
        uint256 maxComputeCost;             // Maximum budget allocated for compute.
        uint256 maxDataCost;                // Maximum budget allocated for data access.
        uint256 agreedComputeCost;          // Actual agreed cost for compute.
        uint256 agreedDataCost;             // Actual agreed cost for data.
        uint256 escrowedAmount;             // Total funds escrowed for this task.
        TaskStatus status;                  // Current status of the task.
        uint256 requestTime;                // Timestamp when the task was requested.
        uint256 assignmentTime;             // Timestamp when the task was assigned.
        uint256 proofSubmissionTime;        // Timestamp when proof was submitted.
        bytes proofData;                    // Raw proof data submitted by compute provider.
        ProofType proofType;                // Type of cryptographic proof used.
    }

    /**
     * @dev Represents a governance proposal.
     *      Simplified for demonstration; a real DAO might include more details like vote weight, snapshot blocks.
     */
    struct Proposal {
        uint256 proposalId;                 // Unique ID for the proposal.
        bytes32 paramNameHash;              // Hashed name of the parameter to change (e.g., keccak256("GOVERNANCE_THRESHOLD")).
        uint256 newValue;                   // New value for the parameter.
        address proposer;                   // Address that proposed the change.
        uint256 voteStartTime;              // Timestamp when voting starts.
        uint256 voteEndTime;                // Timestamp when voting ends.
        uint256 votesFor;                   // Total votes in favor.
        uint256 votesAgainst;               // Total votes against.
        bool executed;                      // True if the proposal has been executed.
        mapping(address => bool) hasVoted;  // To prevent double voting for simplicity.
    }

    // --- State Variables ---

    uint256 public nextModelId;
    uint256 public nextComputeProviderId;
    uint256 public nextDataProviderId;
    uint256 public nextTaskId;
    uint256 public nextProposalId;

    mapping(uint256 => AIModel) public models;
    mapping(uint256 => ComputeProvider) public computeProviders;
    mapping(uint256 => DataProvider) public dataProviders;
    mapping(uint256 => AITask) public tasks;
    mapping(uint256 => Proposal) public proposals;

    // Mapping for user funds deposited for tasks
    mapping(address => uint256) public userBalances;
    // Mapping for provider earnings
    mapping(address => uint256) public providerEarnings;

    // Governance parameters (can be changed by proposals)
    uint256 public minStakeComputeProvider;
    uint256 public minStakeDataProvider;
    uint256 public reputationBonusForSuccess;
    uint256 public reputationPenaltyForFailure;
    uint256 public stakeSlashPercentFailedProof; // Percentage, e.g., 5 for 5%
    uint256 public stakeSlashPercentDeregisterWithActiveTasks; // Percentage, e.g., 10 for 10%
    uint256 public unstakeCooldownPeriod; // In seconds
    uint256 public taskAssignmentTimeout; // In seconds, time for providers to accept assignment
    uint256 public proofSubmissionDeadline; // In seconds, time for compute provider to submit proof
    uint256 public proposalVotingPeriod; // In seconds
    uint256 public proposalExecutionDelay; // In seconds, time between vote end and execution
    uint256 public governanceThresholdPercentage; // E.g., 51 for 51% of votes needed

    // Mapping for proof verifier contracts: ProofType -> IVerifier
    mapping(ProofType => address) public proofVerifiers;

    // --- Events ---
    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string name, bytes32 capabilityHash);
    event AIModelUpdated(uint256 indexed modelId, string newName, bytes32 newCapabilityHash);
    event AIModelDeregistered(uint256 indexed modelId);

    event ComputeProviderRegistered(uint256 indexed providerId, address indexed owner, string name, uint256 stakedAmount);
    event ComputeProviderResourcesUpdated(uint256 indexed providerId, uint256 availableComputeUnits, uint256 availableMemoryGB);
    event ComputeProviderDeregistered(uint256 indexed providerId);

    event DataProviderRegistered(uint256 indexed providerId, address indexed owner, string name, bytes32 datasetHash, uint256 stakedAmount);
    event DataProviderDetailsUpdated(uint256 indexed providerId, string newDescription, uint256 newAccessFeePerUnit);
    event DataProviderDeregistered(uint256 indexed providerId);

    event AITaskRequested(uint256 indexed taskId, address indexed requester, uint256 modelId, bytes32 inputDataHash, uint256 escrowedAmount);
    event TaskAssignmentProposed(uint256 indexed taskId, uint256 indexed computeProviderId, uint256 indexed dataProviderId, uint256 agreedComputeCost, uint256 agreedDataCost);
    event TaskAssignmentAccepted(uint256 indexed taskId, address indexed provider);
    event TaskProofSubmitted(uint256 indexed taskId, bytes32 outputDataHash, ProofType proofType);
    event TaskProofVerified(uint256 indexed taskId, bool success);
    event TaskSettled(uint256 indexed taskId, TaskStatus finalStatus, uint256 rewardsDistributed, uint256 fundsReturned);

    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
    event StakeIncreased(address indexed provider, uint256 newStake);
    event UnstakeRequested(address indexed provider, uint256 amount, uint256 cooldownEnds);
    event FundsUnstaked(address indexed provider, uint256 amount);
    event StakeSlashed(address indexed provider, uint256 amount, string reason);
    event ReputationAdjusted(EntityType indexed entityType, uint256 indexed entityId, int256 change, uint256 newScore);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramNameHash, uint256 newValue, uint256 voteEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramNameHash, uint256 newValue);
    event ProofVerifierSet(ProofType indexed proofType, address verifierAddress);
    // Upgraded event is inherited from UUPSUpgradeable

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _modelId) {
        require(models[_modelId].owner == _msgSender(), "Model owner only");
        _;
    }

    modifier onlyComputeProviderOwner(uint256 _providerId) {
        require(computeProviders[_providerId].owner == _msgSender(), "Compute provider owner only");
        _;
    }

    modifier onlyDataProviderOwner(uint256 _providerId) {
        require(dataProviders[_providerId].owner == _msgSender(), "Data provider owner only");
        _;
    }

    modifier onlyTaskRequester(uint256 _taskId) {
        require(tasks[_taskId].requester == _msgSender(), "Task requester only");
        _;
    }

    modifier onlyAssignedComputeProvider(uint256 _taskId) {
        require(tasks[_taskId].computeProviderId > 0, "Task not assigned");
        require(computeProviders[tasks[_taskId].computeProviderId].owner == _msgSender(), "Assigned compute provider only");
        _;
    }

    modifier onlyAssignedDataProvider(uint256 _taskId) {
        require(tasks[_taskId].dataProviderId > 0, "Task not assigned");
        require(dataProviders[tasks[_taskId].dataProviderId].owner == _msgSender(), "Assigned data provider only");
        _;
    }

    // --- Constructor & Initializer (for UUPS proxy) ---

    /// @dev Initializes the contract. Can only be called once.
    /// @param _initialOwner The address that will be the initial owner of the contract.
    function initialize(address _initialOwner) public initializer {
        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();

        // Initialize dynamic governance parameters with default values
        minStakeComputeProvider = 10 ether; // Example value
        minStakeDataProvider = 5 ether;    // Example value
        reputationBonusForSuccess = 10;
        reputationPenaltyForFailure = 20;
        stakeSlashPercentFailedProof = 5; // 5%
        stakeSlashPercentDeregisterWithActiveTasks = 10; // 10%
        unstakeCooldownPeriod = 7 days;
        taskAssignmentTimeout = 1 days;
        proofSubmissionDeadline = 2 days;
        proposalVotingPeriod = 3 days;
        proposalExecutionDelay = 1 days;
        governanceThresholdPercentage = 51; // 51%

        // Set initial IDs
        nextModelId = 1;
        nextComputeProviderId = 1;
        nextDataProviderId = 1;
        nextTaskId = 1;
        nextProposalId = 1;
    }

    // UUPS Proxy specific override
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- I. Registry Management ---

    /**
     * @dev Registers a new AI model, specifying its capabilities and resource requirements.
     *      Models are the "agents" available for tasks.
     * @param _name Human-readable name of the model.
     * @param _capabilityHash IPFS/Arweave hash pointing to model capabilities/description.
     * @param _requiredComputeUnits Estimated compute units required for typical inference.
     * @param _requiredMemoryGB Estimated memory in GB required for typical inference.
     */
    function registerAIModel(
        string memory _name,
        bytes32 _capabilityHash,
        uint256 _requiredComputeUnits,
        uint256 _requiredMemoryGB
    ) public {
        uint256 modelId = nextModelId++;
        models[modelId] = AIModel({
            owner: _msgSender(),
            name: _name,
            capabilityHash: _capabilityHash,
            requiredComputeUnits: _requiredComputeUnits,
            requiredMemoryGB: _requiredMemoryGB,
            reputationScore: 0, // Initial reputation
            active: true,
            semanticTags: new string[](0)
        });
        emit AIModelRegistered(modelId, _msgSender(), _name, _capabilityHash);
    }

    /**
     * @dev Allows the owner of an AI model to update its described capabilities, enabling dynamic agent evolution.
     * @param _modelId The ID of the model to update.
     * @param _newName New human-readable name for the model.
     * @param _newCapabilityHash New IPFS/Arweave hash for model capabilities.
     * @param _newRequiredComputeUnits New estimated compute units.
     * @param _newRequiredMemoryGB New estimated memory.
     */
    function updateAIModelCapabilities(
        uint256 _modelId,
        string memory _newName,
        bytes32 _newCapabilityHash,
        uint256 _newRequiredComputeUnits,
        uint256 _newRequiredMemoryGB
    ) public onlyModelOwner(_modelId) {
        AIModel storage model = models[_modelId];
        require(model.active, "Model is inactive");
        model.name = _newName;
        model.capabilityHash = _newCapabilityHash;
        model.requiredComputeUnits = _newRequiredComputeUnits;
        model.requiredMemoryGB = _newRequiredMemoryGB;
        emit AIModelUpdated(_modelId, _newName, _newCapabilityHash);
    }

    /**
     * @dev Initiates the process to remove an AI model from the network.
     *      For simplicity, it just deactivates it. A real system might require a governance vote or cooldown.
     * @param _modelId The ID of the model to deregister.
     */
    function deregisterAIModel(uint256 _modelId) public onlyModelOwner(_modelId) {
        require(models[_modelId].active, "Model already inactive");
        models[_modelId].active = false;
        // In a more complex system, this might trigger a governance vote or escrow period for associated tasks.
        emit AIModelDeregistered(_modelId);
    }

    /**
     * @dev Onboards a new compute provider, requiring an initial stake and declaration of available resources.
     * @param _name Human-readable name for the provider.
     * @param _availableComputeUnits Total compute units offered.
     * @param _availableMemoryGB Total memory in GB offered.
     */
    function registerComputeProvider(
        string memory _name,
        uint256 _availableComputeUnits,
        uint256 _availableMemoryGB
    ) public payable {
        require(msg.value >= minStakeComputeProvider, "Initial stake too low");

        uint256 providerId = nextComputeProviderId++;
        computeProviders[providerId] = ComputeProvider({
            owner: _msgSender(),
            name: _name,
            availableComputeUnits: _availableComputeUnits,
            availableMemoryGB: _availableMemoryGB,
            stakedAmount: msg.value,
            reputationScore: 0,
            lastUnstakeRequestTime: 0,
            activeTaskCount: 0,
            active: true
        });
        emit ComputeProviderRegistered(providerId, _msgSender(), _name, msg.value);
    }

    /**
     * @dev Lets a compute provider declare changes in their available compute capacity or memory.
     * @param _providerId The ID of the compute provider.
     * @param _newAvailableComputeUnits New total compute units.
     * @param _newAvailableMemoryGB New total memory in GB.
     */
    function updateComputeProviderResources(
        uint256 _providerId,
        uint256 _newAvailableComputeUnits,
        uint256 _newAvailableMemoryGB
    ) public onlyComputeProviderOwner(_providerId) {
        ComputeProvider storage provider = computeProviders[_providerId];
        require(provider.active, "Provider is inactive");
        provider.availableComputeUnits = _newAvailableComputeUnits;
        provider.availableMemoryGB = _newAvailableMemoryGB;
        emit ComputeProviderResourcesUpdated(_providerId, _newAvailableComputeUnits, _newAvailableMemoryGB);
    }

    /**
     * @dev Removes a compute provider, potentially slashing their stake based on active tasks.
     *      A provider cannot deregister if they have active tasks.
     * @param _providerId The ID of the compute provider to deregister.
     */
    function deregisterComputeProvider(uint256 _providerId) public onlyComputeProviderOwner(_providerId) {
        ComputeProvider storage provider = computeProviders[_providerId];
        require(provider.active, "Provider already inactive");
        require(provider.activeTaskCount == 0, "Cannot deregister with active tasks");

        provider.active = false;
        // In a more complex system, this might trigger stake slashing based on reputation
        // or a governance decision, and put remaining stake in a withdrawable state.
        emit ComputeProviderDeregistered(_providerId);
    }

    /**
     * @dev Registers a data provider with details about their dataset, required access fees, and an initial stake.
     * @param _name Human-readable name.
     * @param _datasetHash IPFS/Arweave hash pointing to dataset metadata/access info.
     * @param _description Short description of the dataset.
     * @param _accessFeePerUnit Fee per unit of data accessed (e.g., per GB).
     */
    function registerDataProvider(
        string memory _name,
        bytes32 _datasetHash,
        string memory _description,
        uint256 _accessFeePerUnit
    ) public payable {
        require(msg.value >= minStakeDataProvider, "Initial stake too low");

        uint256 providerId = nextDataProviderId++;
        dataProviders[providerId] = DataProvider({
            owner: _msgSender(),
            name: _name,
            datasetHash: _datasetHash,
            description: _description,
            accessFeePerUnit: _accessFeePerUnit,
            stakedAmount: msg.value,
            reputationScore: 0,
            lastUnstakeRequestTime: 0,
            active: true,
            semanticTags: new string[](0)
        });
        emit DataProviderRegistered(providerId, _msgSender(), _name, _datasetHash, msg.value);
    }

    /**
     * @dev Updates a data provider's dataset description or access fee structure.
     * @param _providerId The ID of the data provider.
     * @param _newDescription New short description of the dataset.
     * @param _newAccessFeePerUnit New fee per unit of data accessed.
     */
    function updateDataProviderDetails(
        uint256 _providerId,
        string memory _newDescription,
        uint256 _newAccessFeePerUnit
    ) public onlyDataProviderOwner(_providerId) {
        DataProvider storage provider = dataProviders[_providerId];
        require(provider.active, "Provider is inactive");
        provider.description = _newDescription;
        provider.accessFeePerUnit = _newAccessFeePerUnit;
        emit DataProviderDetailsUpdated(_providerId, _newDescription, _newAccessFeePerUnit);
    }

    /**
     * @dev Removes a data provider from the network.
     * @param _providerId The ID of the data provider to deregister.
     */
    function deregisterDataProvider(uint256 _providerId) public onlyDataProviderOwner(_providerId) {
        require(dataProviders[_providerId].active, "Provider already inactive");
        // For simplicity, assuming no direct "active tasks" count for data providers,
        // but a real system might check if their data is currently referenced by ongoing tasks.
        dataProviders[_providerId].active = false;
        emit DataProviderDeregistered(_providerId);
    }

    // --- II. Task Orchestration & Execution ---

    /**
     * @dev Initiates an AI computation task, specifying the desired model, input parameters (hash),
     *      and maximum budget for compute and data. Funds are escrowed.
     * @param _modelId The ID of the AI model to be used.
     * @param _inputDataHash Hash of the input data.
     * @param _maxComputeCost Maximum budget for compute provider.
     * @param _maxDataCost Maximum budget for data provider.
     */
    function requestAITask(
        uint256 _modelId,
        bytes32 _inputDataHash,
        uint256 _maxComputeCost,
        uint256 _maxDataCost
    ) public payable {
        require(models[_modelId].active, "AI Model not active");
        uint256 totalEscrow = _maxComputeCost + _maxDataCost;
        require(msg.value >= totalEscrow, "Insufficient funds provided for task budget");

        uint256 taskId = nextTaskId++;
        tasks[taskId] = AITask({
            taskId: taskId,
            requester: _msgSender(),
            modelId: _modelId,
            computeProviderId: 0, // To be assigned
            dataProviderId: 0,    // To be assigned
            inputDataHash: _inputDataHash,
            outputDataHash: 0,
            maxComputeCost: _maxComputeCost,
            maxDataCost: _maxDataCost,
            agreedComputeCost: 0,
            agreedDataCost: 0,
            escrowedAmount: totalEscrow,
            status: TaskStatus.Requested,
            requestTime: block.timestamp,
            assignmentTime: 0,
            proofSubmissionTime: 0,
            proofData: "",
            proofType: ProofType.ZK_SNARK // Default proof type, can be dynamic
        });
        // Return excess funds to the user if msg.value was greater than strictly required
        if (msg.value > totalEscrow) {
            payable(_msgSender()).transfer(msg.value - totalEscrow);
        }
        emit AITaskRequested(taskId, _msgSender(), _modelId, _inputDataHash, totalEscrow);
    }

    /**
     * @dev (Internal/Privileged) Proposes a specific compute provider and data provider to execute a `Requested` task.
     *      This function would typically be called by an off-chain matching service or a designated governance role.
     * @param _taskId The ID of the task to assign.
     * @param _computeProviderId The ID of the chosen compute provider.
     * @param _dataProviderId The ID of the chosen data provider.
     * @param _agreedComputeCost The actual agreed cost for the compute provider.
     * @param _agreedDataCost The actual agreed cost for the data provider.
     */
    function proposeTaskAssignment(
        uint256 _taskId,
        uint256 _computeProviderId,
        uint256 _dataProviderId,
        uint256 _agreedComputeCost,
        uint256 _agreedDataCost
    ) public onlyOwner { // Simplified to onlyOwner for now, can be a dedicated role or matching engine.
        AITask storage task = tasks[_taskId];
        require(task.status == TaskStatus.Requested, "Task not in Requested status");
        require(computeProviders[_computeProviderId].active, "Compute provider not active");
        require(dataProviders[_dataProviderId].active, "Data provider not active");
        require(_agreedComputeCost <= task.maxComputeCost, "Agreed compute cost exceeds max budget");
        require(_agreedDataCost <= task.maxDataCost, "Agreed data cost exceeds max budget");
        require(_agreedComputeCost + _agreedDataCost <= task.escrowedAmount, "Agreed costs exceed escrowed amount");

        task.computeProviderId = _computeProviderId;
        task.dataProviderId = _dataProviderId;
        task.agreedComputeCost = _agreedComputeCost;
        task.agreedDataCost = _agreedDataCost;
        task.status = TaskStatus.Assigned;
        task.assignmentTime = block.timestamp;

        computeProviders[_computeProviderId].activeTaskCount++;

        emit TaskAssignmentProposed(_taskId, _computeProviderId, _dataProviderId, _agreedComputeCost, _agreedDataCost);
    }

    /**
     * @dev Compute and Data providers confirm their acceptance of a proposed task assignment.
     *      This function can be called by either provider to signal acceptance.
     *      For simplicity, both are assumed to accept upon assignment for now. In a real system,
     *      this would be a two-step acceptance, and the `acceptTaskAssignment` would be explicit for each.
     *      For now, `proposeTaskAssignment` sets status to Assigned, implying acceptance.
     *      Keeping this function for conceptual completeness, but it's simplified.
     * @param _taskId The ID of the task.
     */
    function acceptTaskAssignment(uint256 _taskId) public {
        AITask storage task = tasks[_taskId];
        require(task.status == TaskStatus.Assigned, "Task not in Assigned status or already accepted");
        require(task.assignmentTime + taskAssignmentTimeout > block.timestamp, "Assignment timed out, cannot accept");

        // In a more complex system, this would be a specific acceptance for each provider type.
        // For now, if called by an assigned provider, it implicitly confirms acceptance.
        // No explicit state change on task.status in this simplified model, as 'Assigned' implies readiness.
        require(_msgSender() == computeProviders[task.computeProviderId].owner || _msgSender() == dataProviders[task.dataProviderId].owner, "Not an assigned provider for this task");
        emit TaskAssignmentAccepted(_taskId, _msgSender());
    }

    // @dev Interface for ZK verifier contracts. Actual verifier logic would be in separate contracts.
    interface IVerifier {
        function verifyProof(bytes memory _proof, bytes memory _publicInputs) external view returns (bool);
    }

    /**
     * @dev The assigned compute provider submits the task's output hash and an accompanying cryptographic proof
     *      (e.g., ZK-SNARK, ZK-STARK) of correct execution.
     * @param _taskId The ID of the task.
     * @param _outputDataHash The hash of the computed output data.
     * @param _proofData The raw cryptographic proof (e.g., ZK-SNARK proof bytes).
     * @param _proofType The type of proof submitted.
     */
    function submitTaskProof(
        uint256 _taskId,
        bytes32 _outputDataHash,
        bytes memory _proofData,
        ProofType _proofType
    ) public onlyAssignedComputeProvider(_taskId) {
        AITask storage task = tasks[_taskId];
        require(task.status == TaskStatus.Assigned, "Task not in Assigned status");
        require(task.assignmentTime + proofSubmissionDeadline > block.timestamp, "Proof submission deadline passed");
        require(_proofData.length > 0, "Proof data cannot be empty");

        task.outputDataHash = _outputDataHash;
        task.proofData = _proofData;
        task.proofType = _proofType;
        task.proofSubmissionTime = block.timestamp;
        task.status = TaskStatus.ProofSubmitted;
        emit TaskProofSubmitted(_taskId, _outputDataHash, _proofType);
    }

    /**
     * @dev Triggers the on-chain verification of the submitted proof using a pre-registered verifier contract
     *      corresponding to the `ProofType`. Can be called by anyone after proof submission.
     * @param _taskId The ID of the task.
     */
    function verifyTaskProof(uint256 _taskId) public {
        AITask storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofSubmitted, "Task proof not submitted or already verified");

        address verifierAddress = proofVerifiers[task.proofType];
        require(verifierAddress != address(0), "No verifier registered for this proof type");

        IVerifier verifier = IVerifier(verifierAddress);
        // The public inputs for the ZK proof would typically include task.inputDataHash, task.modelId,
        // and task.outputDataHash, along with other execution context.
        // For simplicity, we concatenate them here. A real ZK circuit would define a precise structure.
        bytes memory publicInputs = abi.encodePacked(
            task.inputDataHash,
            uint256(task.modelId), // Convert to uint256 for consistent encoding
            task.outputDataHash
        );
        bool proofSuccess = verifier.verifyProof(task.proofData, publicInputs);

        if (proofSuccess) {
            task.status = TaskStatus.ProofVerified;
        } else {
            task.status = TaskStatus.ProofFailed;
            _slashStake(task.computeProviderId, stakeSlashPercentFailedProof, "Proof verification failed");
        }
        emit TaskProofVerified(_taskId, proofSuccess);
    }

    /**
     * @dev Finalizes a task after successful proof verification, distributing rewards to providers
     *      and returning unused funds to the requester. Automatically adjusts reputation.
     * @param _taskId The ID of the task to settle.
     */
    function settleTask(uint256 _taskId) public {
        AITask storage task = tasks[_taskId];
        require(task.status == TaskStatus.ProofVerified || task.status == TaskStatus.ProofFailed, "Task not ready for settlement");
        require(task.computeProviderId != 0 && task.dataProviderId != 0, "Task not fully assigned");

        computeProviders[task.computeProviderId].activeTaskCount--;

        if (task.status == TaskStatus.ProofVerified) {
            // Distribute rewards
            providerEarnings[computeProviders[task.computeProviderId].owner] += task.agreedComputeCost;
            providerEarnings[dataProviders[task.dataProviderId].owner] += task.agreedDataCost;

            // Update reputation
            _evaluateAndAdjustReputation(EntityType.ComputeProvider, task.computeProviderId, int256(reputationBonusForSuccess));
            _evaluateAndAdjustReputation(EntityType.DataProvider, task.dataProviderId, int256(reputationBonusForSuccess));
            _evaluateAndAdjustReputation(EntityType.Model, task.modelId, int256(reputationBonusForSuccess));

            // Return unused funds to requester
            uint256 totalCost = task.agreedComputeCost + task.agreedDataCost;
            uint256 refundAmount = task.escrowedAmount - totalCost;
            if (refundAmount > 0) {
                payable(task.requester).transfer(refundAmount);
            }
            task.status = TaskStatus.Succeeded;
            emit TaskSettled(_taskId, TaskStatus.Succeeded, totalCost, refundAmount);

        } else if (task.status == TaskStatus.ProofFailed) {
            // Funds returned to requester (minus potential slash that goes to community treasury from `_slashStake`)
            payable(task.requester).transfer(task.escrowedAmount);
            _evaluateAndAdjustReputation(EntityType.ComputeProvider, task.computeProviderId, -int256(reputationPenaltyForFailure));
            _evaluateAndAdjustReputation(EntityType.DataProvider, task.dataProviderId, -int256(reputationPenaltyForFailure)); // Data provider might also be penalized if data was faulty
            _evaluateAndAdjustReputation(EntityType.Model, task.modelId, -int256(reputationPenaltyForFailure)); // Model might be penalized if it produced bad results
            task.status = TaskStatus.Failed;
            emit TaskSettled(_taskId, TaskStatus.Failed, 0, task.escrowedAmount);
        }
    }

    // --- III. Reputation & Staking Mechanics ---

    /**
     * @dev Allows any registered provider (compute, data) to increase their staked collateral,
     *      enhancing their reputation and potential for task assignments.
     * @param _amount The amount of ETH to stake.
     */
    function stakeFunds(uint256 _amount) public payable {
        require(msg.value == _amount, "Msg.value must match stake amount");

        bool foundProvider = false;
        // Check if sender is a compute provider
        for (uint256 i = 1; i < nextComputeProviderId; i++) {
            if (computeProviders[i].owner == _msgSender() && computeProviders[i].active) {
                computeProviders[i].stakedAmount += _amount;
                foundProvider = true;
                break;
            }
        }

        // Check if sender is a data provider
        if (!foundProvider) {
            for (uint256 i = 1; i < nextDataProviderId; i++) {
                if (dataProviders[i].owner == _msgSender() && dataProviders[i].active) {
                    dataProviders[i].stakedAmount += _amount;
                    foundProvider = true;
                    break;
                }
            }
        }
        require(foundProvider, "Sender is not an active provider to stake funds");
        emit StakeIncreased(_msgSender(), _amount);
    }

    /**
     * @dev Initiates the withdrawal of staked funds, subject to a network-defined cooldown period to ensure accountability.
     *      This function immediately marks funds for withdrawal and deducts from staked amount.
     *      Actual transfer happens after cooldown.
     * @param _amount The amount to unstake.
     */
    function unstakeFunds(uint256 _amount) public {
        bool foundProvider = false;
        address providerAddress = _msgSender();

        // Check if sender is a compute provider
        for (uint256 i = 1; i < nextComputeProviderId; i++) {
            if (computeProviders[i].owner == providerAddress && computeProviders[i].active) {
                require(computeProviders[i].stakedAmount >= _amount, "Insufficient staked funds");
                require(block.timestamp >= computeProviders[i].lastUnstakeRequestTime + unstakeCooldownPeriod, "Unstake cooldown period active");
                computeProviders[i].stakedAmount -= _amount;
                computeProviders[i].lastUnstakeRequestTime = block.timestamp;
                foundProvider = true;
                break;
            }
        }

        // Check if sender is a data provider
        if (!foundProvider) {
            for (uint256 i = 1; i < nextDataProviderId; i++) {
                if (dataProviders[i].owner == providerAddress && dataProviders[i].active) {
                    require(dataProviders[i].stakedAmount >= _amount, "Insufficient staked funds");
                    require(block.timestamp >= dataProviders[i].lastUnstakeRequestTime + unstakeCooldownPeriod, "Unstake cooldown period active");
                    dataProviders[i].stakedAmount -= _amount;
                    dataProviders[i].lastUnstakeRequestTime = block.timestamp;
                    foundProvider = true;
                    break;
                }
            }
        }
        require(foundProvider, "Sender is not an active provider to unstake funds");

        // Transfer funds after cooldown (simplified here for direct transfer)
        // In a real system, a separate `claimUnstakedFunds` would be needed after `lastUnstakeRequestTime + unstakeCooldownPeriod`
        payable(providerAddress).transfer(_amount);
        emit FundsUnstaked(providerAddress, _amount);
        emit UnstakeRequested(providerAddress, _amount, block.timestamp + unstakeCooldownPeriod);
    }

    /**
     * @dev (Internal/Automated) Penalizes a provider by reducing their stake due to failed proofs, non-compliance, etc.
     *      Funds from slashing are retained by the contract (e.g., for a community treasury).
     * @param _providerId The ID of the provider to slash.
     * @param _slashPercentage The percentage of their stake to slash (e.g., 5 for 5%).
     * @param _reason Description for the slash.
     */
    function _slashStake(uint256 _providerId, uint256 _slashPercentage, string memory _reason) internal {
        ComputeProvider storage cp = computeProviders[_providerId];
        require(cp.owner != address(0), "Provider not found"); // Check if it's a compute provider

        uint256 slashAmount = (cp.stakedAmount * _slashPercentage) / 100;
        cp.stakedAmount -= slashAmount;
        // Funds are effectively 'burnt' or held by contract for treasury
        emit StakeSlashed(cp.owner, slashAmount, _reason);
    }

    /**
     * @dev (Internal/Privileged) Adjusts a provider's reputation score based on task performance, proof success rates, and other metrics.
     * @param _entityType The type of entity (Model, ComputeProvider, DataProvider).
     * @param _entityId The ID of the entity.
     * @param _change The amount to change the reputation by (can be negative).
     */
    function _evaluateAndAdjustReputation(EntityType _entityType, uint256 _entityId, int256 _change) internal {
        if (_entityType == EntityType.Model) {
            AIModel storage model = models[_entityId];
            uint256 currentScore = model.reputationScore;
            if (_change > 0) {
                model.reputationScore = currentScore + uint256(_change);
            } else if (currentScore >= uint256(-_change)) {
                model.reputationScore = currentScore - uint256(-_change);
            } else {
                model.reputationScore = 0;
            }
            emit ReputationAdjusted(_entityType, _entityId, _change, model.reputationScore);
        } else if (_entityType == EntityType.ComputeProvider) {
            ComputeProvider storage provider = computeProviders[_entityId];
            uint256 currentScore = provider.reputationScore;
            if (_change > 0) {
                provider.reputationScore = currentScore + uint256(_change);
            } else if (currentScore >= uint256(-_change)) {
                provider.reputationScore = currentScore - uint256(-_change);
            } else {
                provider.reputationScore = 0;
            }
            emit ReputationAdjusted(_entityType, _entityId, _change, provider.reputationScore);
        } else if (_entityType == EntityType.DataProvider) {
            DataProvider storage provider = dataProviders[_entityId];
            uint256 currentScore = provider.reputationScore;
            if (_change > 0) {
                provider.reputationScore = currentScore + uint256(_change);
            } else if (currentScore >= uint256(-_change)) {
                provider.reputationScore = currentScore - uint256(-_change);
            } else {
                provider.reputationScore = 0;
            }
            emit ReputationAdjusted(_entityType, _entityId, _change, provider.reputationScore);
        }
    }

    // --- IV. Decentralized Governance & Parameters ---

    /**
     * @dev Allows authorized entities (e.g., specific token holders or current owner) to propose changes
     *      to critical contract parameters.
     * @param _paramNameHash Hashed name of the parameter (e.g., keccak256("UNSTAKE_COOLDOWN_PERIOD")).
     * @param _newValue The new value for the parameter.
     */
    function proposeSystemParameterChange(bytes32 _paramNameHash, uint256 _newValue) public onlyOwner { // Simplified to onlyOwner
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            paramNameHash: _paramNameHash,
            newValue: _newValue,
            proposer: _msgSender(),
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool)() // Initialize empty mapping
        });
        // A real DAO would require token-based voting, not just owner.
        emit ProposalCreated(proposalId, _msgSender(), _paramNameHash, _newValue, proposals[proposalId].voteEndTime);
    }

    /**
     * @dev Enables eligible token holders or governance members to cast votes on active proposals.
     *      Simplified for this contract; in a real DAO, it would involve token balance snapshots.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting is not active");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.hasVoted[_msgSender()], "Already voted on this proposal");

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[_msgSender()] = true;
        emit VoteCast(_proposalId, _msgSender(), _approve);
    }

    /**
     * @dev Executes a proposal that has met the required voting threshold and passed its timelock.
     *      Can be called by anyone after the voting period ends and execution delay passes.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp > proposal.voteEndTime + proposalExecutionDelay, "Execution delay not passed");

        // Check voting threshold (simplified: total votes > 0, and votesFor > threshold)
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast for this proposal");
        require((proposal.votesFor * 100) / totalVotes >= governanceThresholdPercentage, "Proposal did not meet threshold");

        // Execute the parameter change based on the hashed parameter name
        bytes32 paramHash = proposal.paramNameHash;
        uint256 newValue = proposal.newValue;

        if (paramHash == keccak256("MIN_STAKE_COMPUTE_PROVIDER")) {
            minStakeComputeProvider = newValue;
        } else if (paramHash == keccak256("MIN_STAKE_DATA_PROVIDER")) {
            minStakeDataProvider = newValue;
        } else if (paramHash == keccak256("REPUTATION_BONUS_FOR_SUCCESS")) {
            reputationBonusForSuccess = newValue;
        } else if (paramHash == keccak256("REPUTATION_PENALTY_FOR_FAILURE")) {
            reputationPenaltyForFailure = newValue;
        } else if (paramHash == keccak256("STAKE_SLASH_PERCENT_FAILED_PROOF")) {
            require(newValue <= 100, "Slash percentage must be <= 100");
            stakeSlashPercentFailedProof = newValue;
        } else if (paramHash == keccak256("STAKE_SLASH_PERCENT_DEREGISTER_WITH_ACTIVE_TASKS")) {
            require(newValue <= 100, "Slash percentage must be <= 100");
            stakeSlashPercentDeregisterWithActiveTasks = newValue;
        } else if (paramHash == keccak256("UNSTAKE_COOLDOWN_PERIOD")) {
            unstakeCooldownPeriod = newValue;
        } else if (paramHash == keccak256("TASK_ASSIGNMENT_TIMEOUT")) {
            taskAssignmentTimeout = newValue;
        } else if (paramHash == keccak256("PROOF_SUBMISSION_DEADLINE")) {
            proofSubmissionDeadline = newValue;
        } else if (paramHash == keccak256("PROPOSAL_VOTING_PERIOD")) {
            proposalVotingPeriod = newValue;
        } else if (paramHash == keccak256("PROPOSAL_EXECUTION_DELAY")) {
            proposalExecutionDelay = newValue;
        } else if (paramHash == keccak256("GOVERNANCE_THRESHOLD_PERCENTAGE")) {
            require(newValue <= 100, "Threshold percentage must be <= 100");
            governanceThresholdPercentage = newValue;
        } else {
            revert("Unknown parameter or parameter cannot be changed via governance");
        }

        proposal.executed = true;
        emit ProposalExecuted(_proposalId, paramHash, newValue);
    }

    /**
     * @dev Sets or updates the address of a specific verifier contract for a given `ProofType`.
     *      This is crucial for modular proof systems, allowing new proof types or upgraded verifiers.
     * @param _proofType The type of proof (e.g., ZK_SNARK).
     * @param _verifierContract The address of the IVerifier implementation contract.
     */
    function setProofVerifierContract(ProofType _proofType, address _verifierContract) public onlyOwner {
        require(_verifierContract != address(0), "Verifier address cannot be zero");
        proofVerifiers[_proofType] = _verifierContract;
        emit ProofVerifierSet(_proofType, _verifierContract);
    }

    /**
     * @dev Facilitates contract upgradability by pointing to a new logic contract.
     *      Requires the contract to be deployed behind a UUPS proxy.
     *      Only callable by the owner of the proxy (which in this context means the owner of this contract).
     * @param _newImplementation The address of the new logic contract.
     */
    function upgradeImplementation(address _newImplementation) public onlyOwner {
        _upgradeToAndCall(_newImplementation, bytes(""));
    }

    // --- V. Funding & Tokenomics ---

    /**
     * @dev Allows users to deposit native currency (e.g., ETH) into the contract, primarily for funding task requests.
     */
    function depositFunds() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        userBalances[_msgSender()] += msg.value;
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Enables users to withdraw their unspent deposited funds.
     * @param _amount The amount to withdraw.
     */
    function withdrawUserFunds(uint256 _amount) public {
        require(userBalances[_msgSender()] >= _amount, "Insufficient balance");
        userBalances[_msgSender()] -= _amount;
        payable(_msgSender()).transfer(_amount);
        emit FundsWithdrawn(_msgSender(), _amount);
    }

    /**
     * @dev Allows compute and data providers to claim their accumulated rewards from completed tasks.
     */
    function withdrawProviderEarnings() public {
        uint256 amount = providerEarnings[_msgSender()];
        require(amount > 0, "No earnings to withdraw");
        providerEarnings[_msgSender()] = 0;
        payable(_msgSender()).transfer(amount);
        emit ProviderEarningsWithdrawn(_msgSender(), amount);
    }

    // --- VI. Advanced Discovery & Management ---

    /**
     * @dev Attaches descriptive, searchable semantic tags to AI models, enhancing discovery for complex task requests.
     * @param _modelId The ID of the AI model.
     * @param _tag The semantic tag to add (e.g., "ImageRecognition", "MedicalDiagnosis").
     */
    function addModelSemanticTag(uint256 _modelId, string memory _tag) public onlyModelOwner(_modelId) {
        require(models[_modelId].active, "Model is inactive");
        models[_modelId].semanticTags.push(_tag);
        // Event for tag added could be useful, e.g., event TagAdded(EntityType.Model, _modelId, _tag);
    }

    /**
     * @dev Attaches semantic tags to datasets, aiding in intelligent matching of data to AI models.
     * @param _dataProviderId The ID of the data provider.
     * @param _tag The semantic tag to add (e.g., "FinancialData", "Time-Series").
     */
    function addDataSemanticTag(uint256 _dataProviderId, string memory _tag) public onlyDataProviderOwner(_dataProviderId) {
        require(dataProviders[_dataProviderId].active, "Data provider is inactive");
        dataProviders[_dataProviderId].semanticTags.push(_tag);
        // Event for tag added could be useful, e.g., event TagAdded(EntityType.DataProvider, _dataProviderId, _tag);
    }

    /**
     * @dev Retrieves a list of AI models that possess a specific semantic tag.
     *      This is a view function for off-chain discovery.
     * @param _capabilityTag The tag to search for.
     * @return An array of model IDs that match the tag.
     */
    function getModelsByTag(string memory _capabilityTag) public view returns (uint256[] memory) {
        uint256[] memory tempMatchingModelIds = new uint256[](nextModelId); // Max possible size
        uint256 count = 0;
        bytes32 searchTagHash = keccak256(abi.encodePacked(_capabilityTag));

        for (uint256 i = 1; i < nextModelId; i++) {
            if (models[i].owner != address(0) && models[i].active) { // Ensure model exists and is active
                for (uint256 j = 0; j < models[i].semanticTags.length; j++) {
                    if (keccak256(abi.encodePacked(models[i].semanticTags[j])) == searchTagHash) {
                        tempMatchingModelIds[count++] = i;
                        break; // Found tag, move to next model
                    }
                }
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempMatchingModelIds[i];
        }
        return result;
    }

    // --- Utility View Functions ---
    // These functions are for reading state and are not counted in the 20+ advanced functions.

    function getAIModel(uint256 _modelId) public view returns (AIModel memory) {
        return models[_modelId];
    }

    function getComputeProvider(uint256 _providerId) public view returns (ComputeProvider memory) {
        return computeProviders[_providerId];
    }

    function getDataProvider(uint256 _providerId) public view returns (DataProvider memory) {
        return dataProviders[_providerId];
    }

    function getAITask(uint256 _taskId) public view returns (AITask memory) {
        return tasks[_taskId];
    }

    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getUserBalance(address _user) public view returns (uint256) {
        return userBalances[_user];
    }

    function getProviderEarnings(address _provider) public view returns (uint256) {
        return providerEarnings[_provider];
    }
}
```