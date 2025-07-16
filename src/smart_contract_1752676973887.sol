This smart contract, **SynapticNexus**, is a decentralized platform designed for the collaborative creation, training, monetization, and fractional ownership of AI models. It introduces several advanced concepts, focusing on how on-chain mechanics can incentivize and manage off-chain AI/ML activities without duplicating existing open-source projects.

The contract uses a modular approach, separating concerns into model management, collaborative training/annotation, monetization, and a unique fractional ownership system. It assumes the existence of off-chain oracles for submitting verified proofs of work (e.g., computational contribution, data annotation) and model performance metrics, as direct AI model execution and verification are not feasible on the blockchain.

---

## SynapticNexus: A Decentralized AI Model Co-creation & Monetization Platform

### Outline:
*   **I. Core Model Management & Lifecycle:** Handles the registration, updating, decommissioning, and basic details of AI models.
*   **II. Collaborative Training & Contribution System:** Manages tasks where community members can contribute compute resources for model training, including proof submission, verification, and dispute resolution.
*   **III. Data Curation & Annotation System:** Facilitates tasks for crowdsourced data annotation, essential for improving model datasets, with similar proof and reward mechanisms.
*   **IV. Model Monetization & Revenue Distribution:** Manages model subscriptions/access payments and the claiming of accumulated revenues and task-specific rewards.
*   **V. Fractional Ownership & Dynamic Valuation:** Implements a novel system for minting non-fungible (NFT-like) shares of AI models and updating model performance based on oracle feeds.
*   **VI. Administrative & Utility Functions:** Essential functions for contract owner and oracle management, pausing, and fund withdrawal.

### Function Summary:

#### I. Core Model Management & Lifecycle
1.  **`registerAIModel(string _metadataURI, uint256 _accessPrice)`**: Registers a new AI model, assigning it a unique ID. The deployer becomes the initial owner. `_metadataURI` points to off-chain model specifics (e.g., IPFS hash of weights/code).
2.  **`updateAIModelMetadata(uint256 _modelId, string _newMetadataURI)`**: Allows the model owner to update the URI pointing to the model's updated weights, code, or documentation, reflecting new versions or improvements.
3.  **`decommissionAIModel(uint256 _modelId)`**: Marks an AI model as inactive, preventing new subscriptions and training/annotation tasks, effectively taking it offline from the marketplace.
4.  **`setAccessPrice(uint256 _modelId, uint256 _newPrice)`**: Sets the price (in wei) required for users to subscribe to or access a specific AI model.
5.  **`getAIModelDetails(uint256 _modelId)`**: Retrieves comprehensive details about a registered AI model, including its owner, status, metadata URI, access price, current performance score, total collected revenue, and total minted shares.

#### II. Collaborative Training & Contribution System
6.  **`proposeTrainingTask(uint256 _modelId, string _taskDescriptionURI, uint256 _rewardPool, uint256 _deadline)`**: Allows a model owner to initiate a collaborative training task for an AI model, defining a reward pool (sent with the transaction) and a deadline for contributions.
7.  **`commitToTrainingTask(uint256 _taskId)`**: Enables a user to signal their intention to contribute to a specific training task, potentially reserving a slot or indicating commitment.
8.  **`submitTrainingProof(uint256 _taskId, address _contributor, bytes32 _proofHash, uint256 _contributionScore)`**: **(Oracle-fed)** Records a validated proof of a contributor's work for a training task and their assigned contribution score (e.g., based on validated compute units, data processed). This function is called by an authorized oracle after off-chain verification.
9.  **`finalizeTrainingContribution(uint256 _taskId, address _contributor)`**: Triggers the final verification check for a submitted training contribution, marking it ready for reward claiming if conditions (e.g., no dispute) are met.
10. **`disputeTrainingContribution(uint256 _taskId, address _contributor, string _reasonURI)`**: Allows participants or model owners to formally dispute a submitted training contribution, potentially freezing its reward until resolved by governance. `_reasonURI` points to detailed reasons.
11. **`resolveTrainingDispute(uint256 _taskId, address _contributor, bool _validContribution)`**: **(Admin/Governance)** Resolves a training contribution dispute, either validating the contribution and enabling reward release or invalidating it.

#### III. Data Curation & Annotation System
12. **`proposeAnnotationTask(uint256 _modelId, string _taskDescriptionURI, uint256 _rewardPool, uint256 _deadline)`**: Initiates a new task for crowdsourced data annotation, crucial for improving model datasets. Works similarly to `proposeTrainingTask`.
13. **`submitAnnotationProof(uint256 _taskId, address _annotator, bytes32 _proofHash, uint256 _annotatedItemsCount)`**: **(Oracle-fed)** Submits validated proof of data annotation work. `_annotatedItemsCount` represents the quality/quantity of annotation.
14. **`finalizeAnnotationContribution(uint256 _taskId, address _annotator)`**: Processes and validates an annotation proof, preparing rewards for claiming, similar to `finalizeTrainingContribution`.

#### IV. Model Monetization & Revenue Distribution
15. **`subscribeToModel(uint256 _modelId) payable`**: Allows a user to pay the access price for a model, gaining access (access duration/details handled off-chain). The payment contributes to the model's total revenue.
16. **`claimModelRevenue(uint256 _modelId)`**: Enables the model owner to claim their accumulated revenue share from model subscriptions. (Note: For fractional ownership, actual revenue distribution to shareholders might happen off-chain or through a separate, more complex on-chain mechanism not detailed here for brevity).
17. **`claimTaskRewards(uint256 _taskId)`**: Allows a verified participant to claim their earned rewards from a completed training or annotation task, distributed pro-rata based on their contribution score.

#### V. Fractional Ownership & Dynamic Valuation
18. **`fractionalizeModel(uint256 _modelId, uint256 _numShares)`**: Mints a specified number of unique, non-fungible shares (NFT-like tokens with unique IDs) representing fractional ownership of a model. Only callable by the model owner, and only once per model.
19. **`transferModelShare(uint256 _modelId, uint256 _shareId, address _to)`**: Allows the current owner of a specific fractional model share (`_shareId` for `_modelId`) to transfer it to another address.
20. **`updateModelPerformanceMetric(uint256 _modelId, uint256 _newScore)`**: **(Oracle-fed)** Updates a model's performance score (e.g., accuracy, efficiency). This metric can dynamically influence its perceived value, ranking, or even future pricing suggestions, managed off-chain.

#### VI. Administrative & Utility Functions (Included for completeness, not part of the 20 core business features)
21. **`grantOracleRole(address _oracleAddress)`**: Grants an address the permission to submit oracle-fed data (e.g., proofs, performance scores).
22. **`revokeOracleRole(address _oracleAddress)`**: Revokes oracle permissions from an address.
23. **`pauseContract()`**: An emergency function to pause critical operations of the contract (e.g., subscriptions, new tasks) in case of vulnerabilities or maintenance.
24. **`unpauseContract()`**: Resumes operations after the contract has been paused.
25. **`withdrawFunds(address _recipient, uint256 _amount)`**: Allows the contract owner to withdraw accumulated fees or general funds not explicitly tied to specific reward pools.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SynapticNexus
 * @dev A Decentralized AI Model Co-creation & Monetization Platform.
 *      This contract enables the registration, collaborative training, data annotation,
 *      monetization, and fractional ownership of AI models on the blockchain.
 *      It relies on off-chain oracles for proof verification and performance metrics.
 *
 * @outline
 * I. Core Model Management & Lifecycle
 * II. Collaborative Training & Contribution System
 * III. Data Curation & Annotation System
 * IV. Model Monetization & Revenue Distribution
 * V. Fractional Ownership & Dynamic Valuation
 * VI. Administrative & Utility Functions (Added for completeness but not counted in the 20 main features)
 *
 * @function_summary
 *
 * I. Core Model Management & Lifecycle
 * 1. registerAIModel(string _metadataURI, uint256 _accessPrice): Registers a new AI model, assigning it a unique ID. The deployer becomes the initial owner.
 * 2. updateAIModelMetadata(uint256 _modelId, string _newMetadataURI): Allows the model owner to update the IPFS hash or URI pointing to the model's weights, code, or documentation.
 * 3. decommissionAIModel(uint256 _modelId): Marks an AI model as inactive, preventing new subscriptions and training/annotation tasks. Requires model owner permissions.
 * 4. setAccessPrice(uint256 _modelId, uint256 _newPrice): Sets the price (in wei) required for users to subscribe to or access a specific AI model.
 * 5. getAIModelDetails(uint256 _modelId): Retrieves comprehensive details about a registered AI model, including its owner, status, metadata URI, access price, and performance.
 *
 * II. Collaborative Training & Contribution System
 * 6. proposeTrainingTask(uint256 _modelId, string _taskDescriptionURI, uint256 _rewardPool, uint256 _deadline): Allows a model owner or designated proposer to initiate a collaborative training task for an AI model, specifying a reward pool and deadline.
 * 7. commitToTrainingTask(uint256 _taskId): Enables a user to signal their intention to contribute to a specific training task.
 * 8. submitTrainingProof(uint256 _taskId, address _contributor, bytes32 _proofHash, uint256 _contributionScore): An oracle-fed function to record a validated proof of a contributor's work for a training task and their contribution score.
 * 9. finalizeTrainingContribution(uint256 _taskId, address _contributor): Triggers the final verification and processing of a submitted training contribution, preparing rewards for claiming.
 * 10. disputeTrainingContribution(uint256 _taskId, address _contributor, string _reasonURI): Allows participants or model owners to dispute a submitted training contribution, potentially freezing its reward.
 * 11. resolveTrainingDispute(uint256 _taskId, address _contributor, bool _validContribution): An admin/governance function to resolve a training dispute, either validating the contribution and releasing rewards or invalidating it.
 *
 * III. Data Curation & Annotation System
 * 12. proposeAnnotationTask(uint256 _modelId, string _taskDescriptionURI, uint256 _rewardPool, uint256 _deadline): Initiates a new task for crowdsourced data annotation, crucial for improving model datasets.
 * 13. submitAnnotationProof(uint256 _taskId, address _annotator, bytes32 _proofHash, uint256 _annotatedItemsCount): Oracle-fed function for submitting validated proof of data annotation work.
 * 14. finalizeAnnotationContribution(uint256 _taskId, address _annotator): Processes and validates an annotation proof, preparing rewards for claiming.
 *
 * IV. Model Monetization & Revenue Distribution
 * 15. subscribeToModel(uint256 _modelId) payable: Allows a user to pay the access price for a model, granting them temporary access (duration handled off-chain).
 * 16. claimModelRevenue(uint256 _modelId): Enables a model owner or a recognized contributor to claim their accumulated revenue share from model subscriptions.
 * 17. claimTaskRewards(uint256 _taskId): Allows a verified participant to claim their earned rewards from a completed training or annotation task.
 *
 * V. Fractional Ownership & Dynamic Valuation
 * 18. fractionalizeModel(uint256 _modelId, uint256 _numShares): Mints a specified number of unique, non-fungible shares (NFT-like) representing fractional ownership of a model. Only callable by the model owner.
 * 19. transferModelShare(uint256 _modelId, uint256 _shareId, address _to): Allows the owner of a fractional model share to transfer it to another address.
 * 20. updateModelPerformanceMetric(uint256 _modelId, uint256 _newScore): An oracle-fed function to update a model's performance score, dynamically influencing its perceived value and future revenue distribution.
 *
 * VI. Administrative & Utility Functions (Not counted in the 20 main features)
 * 21. grantOracleRole(address _oracleAddress): Grants an address the permission to submit oracle-fed data.
 * 22. revokeOracleRole(address _oracleAddress): Revokes oracle permissions.
 * 23. pauseContract(): Emergency function to pause critical operations.
 * 24. unpauseContract(): Resumes operations after pausing.
 * 25. withdrawFunds(address _recipient, uint256 _amount): Allows the contract owner to withdraw accumulated fees or funds not tied to specific reward pools.
 */
contract SynapticNexus is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _modelIds; // Counter for unique AI model IDs
    Counters.Counter private _taskIds;  // Counter for unique task IDs (training or annotation)
    Counters.Counter private _shareCounter; // Counter for unique fractional share IDs across all models

    // Enums for clarity and state management
    enum ModelStatus { Active, Decommissioned }
    enum TaskStatus { Proposed, Active, Completed, Disputed, Resolved }
    enum TaskType { Training, Annotation }

    // Structs defining the core data entities
    struct AIModel {
        address owner; // Address of the original model creator/owner
        string metadataURI; // URI (e.g., IPFS hash) to off-chain model weights, code, and documentation
        uint256 accessPrice; // Price in wei for a single subscription/access
        ModelStatus status; // Current operational status of the model
        uint256 performanceScore; // A quantitative score reflecting model quality, updated by oracles
        uint256 totalRevenueCollected; // Accumulative revenue generated from subscriptions
        uint256 lastPerformanceUpdate; // Timestamp of the last performance score update
        uint256 totalShares; // Total number of fractional shares minted for this model (0 if not fractionalized)
    }

    struct Task {
        uint256 modelId; // The ID of the AI model this task is associated with
        address proposer; // The address that proposed this task (usually model owner)
        string descriptionURI; // URI to detailed task instructions
        uint256 rewardPool; // Total reward (in wei) allocated for this task
        uint256 deadline; // Timestamp by which contributions must be submitted
        TaskStatus status; // Current status of the task
        TaskType taskType; // Type of task (Training or Annotation)
        uint256 totalContributionScore; // Sum of all verified contribution scores for this task
    }

    struct Contribution {
        uint256 taskId; // The ID of the task this contribution is for
        address contributor; // The address of the individual who contributed
        bytes32 proofHash; // Hash representing the verified off-chain proof of contribution
        uint256 score; // Numerical score representing the quality/quantity of contribution
        bool isVerified; // True if the contribution has been verified by an oracle
        bool isDisputed; // True if the contribution is currently under dispute
        bool hasClaimedReward; // True if the contributor has already claimed their reward
        uint256 timestamp; // Timestamp when the contribution proof was submitted
    }

    // --- Mappings ---
    mapping(uint256 => AIModel) public aiModels; // Maps model ID to AIModel struct
    mapping(uint256 => Task) public tasks; // Maps task ID to Task struct
    mapping(uint256 => mapping(address => Contribution)) public contributions; // taskId => contributor address => Contribution struct
    mapping(uint256 => mapping(uint256 => address)) public modelShares; // modelId => shareId => owner address (for fractional shares)
    mapping(address => bool) public isOracle; // Whitelist for addresses authorized to submit oracle data

    // --- Events ---
    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string metadataURI, uint256 accessPrice);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newMetadataURI);
    event AIModelDecommissioned(uint256 indexed modelId);
    event AccessPriceUpdated(uint256 indexed modelId, uint256 newPrice);
    event ModelSubscribed(uint256 indexed modelId, address indexed subscriber, uint256 amountPaid);
    event ModelRevenueClaimed(uint256 indexed modelId, address indexed claimant, uint256 amount);
    event ModelPerformanceUpdated(uint256 indexed modelId, uint256 newScore, uint256 timestamp);

    event TrainingTaskProposed(uint256 indexed taskId, uint256 indexed modelId, address proposer, uint256 rewardPool, uint256 deadline);
    event ContributorCommitted(uint256 indexed taskId, address indexed contributor);
    event TrainingProofSubmitted(uint256 indexed taskId, address indexed contributor, bytes32 proofHash, uint256 score);
    event TrainingContributionFinalized(uint256 indexed taskId, address indexed contributor, uint256 score); // Score, as reward calculated at claim
    event TrainingContributionDisputed(uint256 indexed taskId, address indexed contributor, string reasonURI);
    event TrainingDisputeResolved(uint256 indexed taskId, address indexed contributor, bool isValid);
    event TaskRewardsClaimed(uint256 indexed taskId, address indexed claimant, uint256 amount);

    event AnnotationTaskProposed(uint256 indexed taskId, uint256 indexed modelId, address proposer, uint256 rewardPool, uint256 deadline);
    event AnnotationProofSubmitted(uint256 indexed taskId, address indexed annotator, bytes32 proofHash, uint256 annotatedItemsCount);
    event AnnotationContributionFinalized(uint256 indexed taskId, address indexed annotator, uint256 score); // Score, as reward calculated at claim

    event ModelSharesMinted(uint256 indexed modelId, address indexed owner, uint256 numShares);
    event ModelShareTransferred(uint256 indexed modelId, uint256 indexed shareId, address indexed from, address to);
    event OracleRoleGranted(address indexed oracle);
    event OracleRoleRevoked(address indexed oracle);

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _modelId) {
        require(aiModels[_modelId].owner == msg.sender, "SynapticNexus: Not model owner");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender], "SynapticNexus: Not an authorized oracle");
        _;
    }

    modifier modelExists(uint256 _modelId) {
        require(_modelId > 0 && aiModels[_modelId].owner != address(0), "SynapticNexus: Model does not exist");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && tasks[_taskId].proposer != address(0), "SynapticNexus: Task does not exist");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {} // Initial contract owner is the deployer

    // --- I. Core Model Management & Lifecycle (5 functions) ---

    /**
     * @dev Registers a new AI model with initial metadata and access price.
     * The deployer of the model becomes its initial owner.
     * @param _metadataURI URI pointing to the model's weights, code, or documentation (e.g., IPFS hash).
     * @param _accessPrice The price in wei for a single subscription/access.
     * @return modelId The unique ID of the newly registered model.
     */
    function registerAIModel(string memory _metadataURI, uint256 _accessPrice)
        public
        whenNotPaused
        returns (uint256)
    {
        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        aiModels[newModelId] = AIModel({
            owner: msg.sender,
            metadataURI: _metadataURI,
            accessPrice: _accessPrice,
            status: ModelStatus.Active,
            performanceScore: 0, // Initial score, to be updated by oracle
            totalRevenueCollected: 0,
            lastPerformanceUpdate: block.timestamp,
            totalShares: 0 // No shares minted initially
        });

        emit AIModelRegistered(newModelId, msg.sender, _metadataURI, _accessPrice);
        return newModelId;
    }

    /**
     * @dev Updates an existing model's metadata URI (e.g., new version, documentation).
     * Callable only by the model's owner.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new URI for the model's metadata.
     */
    function updateAIModelMetadata(uint256 _modelId, string memory _newMetadataURI)
        public
        whenNotPaused
        modelExists(_modelId)
        onlyModelOwner(_modelId)
    {
        require(aiModels[_modelId].status == ModelStatus.Active, "SynapticNexus: Model is decommissioned");
        aiModels[_modelId].metadataURI = _newMetadataURI;
        emit AIModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @dev Marks an AI model as inactive, preventing further interactions (new subscriptions, new tasks).
     * Callable only by the model's owner.
     * @param _modelId The ID of the model to decommission.
     */
    function decommissionAIModel(uint256 _modelId)
        public
        whenNotPaused
        modelExists(_modelId)
        onlyModelOwner(_modelId)
    {
        require(aiModels[_modelId].status == ModelStatus.Active, "SynapticNexus: Model already decommissioned");
        aiModels[_modelId].status = ModelStatus.Decommissioned;
        emit AIModelDecommissioned(_modelId);
    }

    /**
     * @dev Adjusts the subscription price for a specific model.
     * Callable only by the model's owner.
     * @param _modelId The ID of the model.
     * @param _newPrice The new price in wei.
     */
    function setAccessPrice(uint256 _modelId, uint256 _newPrice)
        public
        whenNotPaused
        modelExists(_modelId)
        onlyModelOwner(_modelId)
    {
        require(aiModels[_modelId].status == ModelStatus.Active, "SynapticNexus: Model is decommissioned");
        aiModels[_modelId].accessPrice = _newPrice;
        emit AccessPriceUpdated(_modelId, _newPrice);
    }

    /**
     * @dev Retrieves comprehensive details about a registered AI model.
     * @param _modelId The ID of the model.
     * @return owner_ The model's owner.
     * @return metadataURI_ The URI to the model's metadata.
     * @return accessPrice_ The current access price.
     * @return status_ The current status of the model (Active/Decommissioned).
     * @return performanceScore_ The latest performance score.
     * @return totalRevenueCollected_ The total revenue collected by this model.
     * @return totalShares_ The total number of shares minted for this model.
     */
    function getAIModelDetails(uint256 _modelId)
        public
        view
        modelExists(_modelId)
        returns (address owner_, string memory metadataURI_, uint256 accessPrice_, ModelStatus status_, uint256 performanceScore_, uint256 totalRevenueCollected_, uint256 totalShares_)
    {
        AIModel storage model = aiModels[_modelId];
        return (
            model.owner,
            model.metadataURI,
            model.accessPrice,
            model.status,
            model.performanceScore,
            model.totalRevenueCollected,
            model.totalShares
        );
    }

    // --- II. Collaborative Training & Contribution System (6 functions) ---

    /**
     * @dev Initiates a new task for model training, defining goals, reward, and deadline.
     * Callable only by the model owner. The `_rewardPool` amount must be sent with the transaction.
     * @param _modelId The ID of the model for which the task is created.
     * @param _taskDescriptionURI URI pointing to the detailed task description.
     * @param _rewardPool The total reward (in wei) for completing this task.
     * @param _deadline The timestamp by which contributions must be submitted.
     * @return taskId The unique ID of the newly proposed task.
     */
    function proposeTrainingTask(
        uint256 _modelId,
        string memory _taskDescriptionURI,
        uint256 _rewardPool,
        uint256 _deadline
    ) public payable whenNotPaused modelExists(_modelId) onlyModelOwner(_modelId) returns (uint256) {
        require(aiModels[_modelId].status == ModelStatus.Active, "SynapticNexus: Model is decommissioned");
        require(msg.value == _rewardPool, "SynapticNexus: Sent ETH must match rewardPool");
        require(_deadline > block.timestamp, "SynapticNexus: Deadline must be in the future");
        require(_rewardPool > 0, "SynapticNexus: Reward pool must be greater than zero");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            modelId: _modelId,
            proposer: msg.sender,
            descriptionURI: _taskDescriptionURI,
            rewardPool: _rewardPool,
            deadline: _deadline,
            status: TaskStatus.Active,
            taskType: TaskType.Training,
            totalContributionScore: 0
        });

        emit TrainingTaskProposed(newTaskId, _modelId, msg.sender, _rewardPool, _deadline);
        return newTaskId;
    }

    /**
     * @dev Allows a participant to signal their intention to contribute to a specific training task.
     * This function serves as an 'opt-in' or commitment step before submitting actual work proof.
     * @param _taskId The ID of the training task to commit to.
     */
    function commitToTrainingTask(uint256 _taskId) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.taskType == TaskType.Training, "SynapticNexus: Not a training task");
        require(task.status == TaskStatus.Active, "SynapticNexus: Task not active");
        require(block.timestamp <= task.deadline, "SynapticNexus: Task deadline passed");
        // Additional logic could include a small stake for commitment,
        // or a check to prevent duplicate commitments from the same address.
        emit ContributorCommitted(_taskId, msg.sender);
    }

    /**
     * @dev Oracle-fed function to record a validated proof of a contributor's work for a training task.
     * This function is expected to be called by an authorized oracle after off-chain verification
     * of the contributor's computational work.
     * @param _taskId The ID of the training task.
     * @param _contributor The address of the contributor.
     * @param _proofHash A hash representing the verified proof of contribution.
     * @param _contributionScore A numerical score representing the quality/quantity of contribution.
     */
    function submitTrainingProof(
        uint256 _taskId,
        address _contributor,
        bytes32 _proofHash,
        uint256 _contributionScore
    ) public onlyOracle whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.taskType == TaskType.Training, "SynapticNexus: Not a training task");
        require(task.status == TaskStatus.Active, "SynapticNexus: Task not active");
        require(block.timestamp <= task.deadline, "SynapticNexus: Task deadline passed for proof submission");
        require(contributions[_taskId][_contributor].contributor == address(0), "SynapticNexus: Proof already submitted by this contributor for this task");
        require(_contributionScore > 0, "SynapticNexus: Contribution score must be positive");

        contributions[_taskId][_contributor] = Contribution({
            taskId: _taskId,
            contributor: _contributor,
            proofHash: _proofHash,
            score: _contributionScore,
            isVerified: true, // Oracle submission implies initial verification
            isDisputed: false,
            hasClaimedReward: false,
            timestamp: block.timestamp
        });
        task.totalContributionScore += _contributionScore;
        emit TrainingProofSubmitted(_taskId, _contributor, _proofHash, _contributionScore);
    }

    /**
     * @dev Triggers the final verification and processing of a submitted training contribution,
     * calculating and preparing rewards for claiming. This can be called by anyone after the deadline.
     * This function essentially validates the state of the contribution (verified, not disputed).
     * @param _taskId The ID of the training task.
     * @param _contributor The address of the contributor whose contribution is being finalized.
     */
    function finalizeTrainingContribution(uint256 _taskId, address _contributor)
        public
        whenNotPaused
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        Contribution storage contribution = contributions[_taskId][_contributor];

        require(task.taskType == TaskType.Training, "SynapticNexus: Not a training task");
        require(contribution.contributor != address(0), "SynapticNexus: Contribution not found");
        require(contribution.isVerified, "SynapticNexus: Contribution not verified by oracle");
        require(!contribution.isDisputed, "SynapticNexus: Contribution is disputed");
        require(block.timestamp > task.deadline, "SynapticNexus: Task deadline has not passed yet"); // Finalization after deadline
        
        // This function primarily confirms the state. Actual reward calculation happens at claim.
        // A more complex system might transition task status here based on all contributions submitted.
        emit TrainingContributionFinalized(_taskId, _contributor, contribution.score);
    }

    /**
     * @dev Allows participants or model owners to formally dispute a submitted training contribution,
     * potentially freezing its reward until resolved by contract governance.
     * @param _taskId The ID of the training task.
     * @param _contributor The address of the contributor whose work is disputed.
     * @param _reasonURI URI pointing to the detailed reason for the dispute.
     */
    function disputeTrainingContribution(uint256 _taskId, address _contributor, string memory _reasonURI)
        public
        whenNotPaused
        taskExists(_taskId)
    {
        Contribution storage contribution = contributions[_taskId][_contributor];
        require(contribution.contributor != address(0), "SynapticNexus: Contribution not found");
        require(contribution.isVerified, "SynapticNexus: Only verified contributions can be disputed");
        require(!contribution.isDisputed, "SynapticNexus: Contribution already disputed");
        require(!contribution.hasClaimedReward, "SynapticNexus: Reward already claimed");

        contribution.isDisputed = true;
        // In a more advanced system, this would trigger a decentralized dispute resolution process (e.g., Kleros).
        // For simplicity, it marks the contribution disputed and requires `onlyOwner` to resolve.
        emit TrainingContributionDisputed(_taskId, _contributor, _reasonURI);
    }

    /**
     * @dev An admin/governance function to resolve a training dispute.
     * It sets whether the contribution is valid or invalid and releases its status.
     * Callable only by the contract owner.
     * @param _taskId The ID of the training task.
     * @param _contributor The address of the contributor.
     * @param _validContribution True if the contribution is deemed valid, false if invalid.
     */
    function resolveTrainingDispute(uint256 _taskId, address _contributor, bool _validContribution)
        public
        onlyOwner // Or a DAO governance role
        whenNotPaused
        taskExists(_taskId)
    {
        Contribution storage contribution = contributions[_taskId][_contributor];
        require(contribution.contributor != address(0), "SynapticNexus: Contribution not found");
        require(contribution.isDisputed, "SynapticNexus: Contribution is not currently disputed");

        contribution.isDisputed = false;
        contribution.isVerified = _validContribution; // Update verification status based on resolution

        if (!_validContribution) {
            // If invalid, remove contribution score from total, effectively nullifying it
            tasks[_taskId].totalContributionScore -= contribution.score;
            contribution.score = 0; // Nullify score
        }
        emit TrainingDisputeResolved(_taskId, _contributor, _validContribution);
    }

    // --- III. Data Curation & Annotation System (3 functions) ---

    /**
     * @dev Initiates a new task for crowdsourced data annotation for a model's dataset.
     * Callable only by the model owner. The `_rewardPool` amount must be sent with the transaction.
     * Works similarly to `proposeTrainingTask`.
     * @param _modelId The ID of the model for which the annotation task is created.
     * @param _taskDescriptionURI URI pointing to the detailed annotation task description.
     * @param _rewardPool The total reward (in wei) for completing this task.
     * @param _deadline The timestamp by which annotations must be submitted.
     * @return taskId The unique ID of the newly proposed annotation task.
     */
    function proposeAnnotationTask(
        uint256 _modelId,
        string memory _taskDescriptionURI,
        uint256 _rewardPool,
        uint256 _deadline
    ) public payable whenNotPaused modelExists(_modelId) onlyModelOwner(_modelId) returns (uint256) {
        require(aiModels[_modelId].status == ModelStatus.Active, "SynapticNexus: Model is decommissioned");
        require(msg.value == _rewardPool, "SynapticNexus: Sent ETH must match rewardPool");
        require(_deadline > block.timestamp, "SynapticNexus: Deadline must be in the future");
        require(_rewardPool > 0, "SynapticNexus: Reward pool must be greater than zero");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            modelId: _modelId,
            proposer: msg.sender,
            descriptionURI: _taskDescriptionURI,
            rewardPool: _rewardPool,
            deadline: _deadline,
            status: TaskStatus.Active,
            taskType: TaskType.Annotation,
            totalContributionScore: 0
        });

        emit AnnotationTaskProposed(newTaskId, _modelId, msg.sender, _rewardPool, _deadline);
        return newTaskId;
    }

    /**
     * @dev Oracle-fed function for submitting validated proof of data annotation work.
     * Similar to `submitTrainingProof` but for annotation tasks.
     * @param _taskId The ID of the annotation task.
     * @param _annotator The address of the annotator.
     * @param _proofHash A hash representing the verified proof of annotation.
     * @param _annotatedItemsCount The number of items successfully annotated (contribution score).
     */
    function submitAnnotationProof(
        uint256 _taskId,
        address _annotator,
        bytes32 _proofHash,
        uint256 _annotatedItemsCount
    ) public onlyOracle whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.taskType == TaskType.Annotation, "SynapticNexus: Not an annotation task");
        require(task.status == TaskStatus.Active, "SynapticNexus: Task not active");
        require(block.timestamp <= task.deadline, "SynapticNexus: Task deadline passed for proof submission");
        require(contributions[_taskId][_annotator].contributor == address(0), "SynapticNexus: Proof already submitted by this annotator for this task");
        require(_annotatedItemsCount > 0, "SynapticNexus: Annotated items count must be positive");

        contributions[_taskId][_annotator] = Contribution({
            taskId: _taskId,
            contributor: _annotator,
            proofHash: _proofHash,
            score: _annotatedItemsCount,
            isVerified: true, // Oracle submission implies verification
            isDisputed: false,
            hasClaimedReward: false,
            timestamp: block.timestamp
        });
        task.totalContributionScore += _annotatedItemsCount;
        emit AnnotationProofSubmitted(_taskId, _annotator, _proofHash, _annotatedItemsCount);
    }

    /**
     * @dev Processes and validates an annotation proof, preparing rewards for claiming.
     * Similar to `finalizeTrainingContribution`. This can be called by anyone after the deadline.
     * @param _taskId The ID of the annotation task.
     * @param _annotator The address of the annotator whose contribution is being finalized.
     */
    function finalizeAnnotationContribution(uint256 _taskId, address _annotator)
        public
        whenNotPaused
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        Contribution storage contribution = contributions[_taskId][_annotator];

        require(task.taskType == TaskType.Annotation, "SynapticNexus: Not an annotation task");
        require(contribution.contributor != address(0), "SynapticNexus: Contribution not found");
        require(contribution.isVerified, "SynapticNexus: Contribution not verified by oracle");
        require(!contribution.isDisputed, "SynapticNexus: Contribution is disputed");
        require(block.timestamp > task.deadline, "SynapticNexus: Task deadline has not passed yet");

        emit AnnotationContributionFinalized(_taskId, _annotator, contribution.score);
    }

    // --- IV. Model Monetization & Revenue Distribution (3 functions) ---

    /**
     * @dev Allows a user to pay the access price for a model, granting them temporary access.
     * The duration of access is typically handled off-chain by integrating services checking payment status.
     * Any excess ETH sent above `accessPrice` is refunded.
     * @param _modelId The ID of the model to subscribe to.
     */
    function subscribeToModel(uint256 _modelId) public payable whenNotPaused modelExists(_modelId) {
        AIModel storage model = aiModels[_modelId];
        require(model.status == ModelStatus.Active, "SynapticNexus: Model is decommissioned");
        require(msg.value >= model.accessPrice, "SynapticNexus: Insufficient payment for model access");
        require(model.accessPrice > 0, "SynapticNexus: Model access price is zero");

        model.totalRevenueCollected += model.accessPrice; // Only collect the set access price

        // Refunds any excess payment
        if (msg.value > model.accessPrice) {
            payable(msg.sender).transfer(msg.value - model.accessPrice);
        }

        emit ModelSubscribed(_modelId, msg.sender, model.accessPrice);
    }

    /**
     * @dev Enables the model owner to claim their accumulated revenue share from model subscriptions.
     * For simplicity, this function transfers all accumulated `totalRevenueCollected` to the model owner.
     * In a full fractional ownership system, this would be a more complex function distributing to all share holders.
     * @param _modelId The ID of the model to claim revenue from.
     */
    function claimModelRevenue(uint256 _modelId) public whenNotPaused modelExists(_modelId) onlyModelOwner(_modelId) {
        AIModel storage model = aiModels[_modelId];
        uint256 amountToClaim = model.totalRevenueCollected;
        require(amountToClaim > 0, "SynapticNexus: No revenue to claim");

        model.totalRevenueCollected = 0; // Reset balance after claiming

        // Transfer funds
        payable(msg.sender).transfer(amountToClaim);
        emit ModelRevenueClaimed(_modelId, msg.sender, amountToClaim);
    }

    /**
     * @dev Allows a verified participant to claim their earned rewards from a completed training or annotation task.
     * Rewards are distributed pro-rata based on their contribution score relative to the total score for the task.
     * @param _taskId The ID of the task.
     */
    function claimTaskRewards(uint256 _taskId) public whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        Contribution storage contribution = contributions[_taskId][msg.sender];

        require(contribution.contributor != address(0), "SynapticNexus: No contribution found for sender");
        require(block.timestamp > task.deadline, "SynapticNexus: Task deadline not passed yet");
        require(contribution.isVerified, "SynapticNexus: Contribution not verified");
        require(!contribution.isDisputed, "SynapticNexus: Contribution is disputed");
        require(!contribution.hasClaimedReward, "SynapticNexus: Reward already claimed");
        require(task.totalContributionScore > 0, "SynapticNexus: Total contribution score is zero, no rewards to distribute");

        uint256 rewardAmount = (task.rewardPool * contribution.score) / task.totalContributionScore;
        require(rewardAmount > 0, "SynapticNexus: Calculated reward is zero");

        contribution.hasClaimedReward = true;
        // Transfer funds from the task's reward pool (which is held by the contract)
        payable(msg.sender).transfer(rewardAmount);
        emit TaskRewardsClaimed(_taskId, msg.sender, rewardAmount);
    }

    // --- V. Fractional Ownership & Dynamic Valuation (3 functions) ---

    /**
     * @dev Mints a specified number of unique, non-fungible shares (NFT-like)
     * representing fractional ownership of a model. Each share has a unique ID within the model.
     * Callable only by the model owner, and only if the model has not been fractionalized yet.
     * @param _modelId The ID of the model to fractionalize.
     * @param _numShares The number of shares to mint.
     */
    function fractionalizeModel(uint256 _modelId, uint256 _numShares)
        public
        whenNotPaused
        modelExists(_modelId)
        onlyModelOwner(_modelId)
    {
        AIModel storage model = aiModels[_modelId];
        require(model.totalShares == 0, "SynapticNexus: Model already fractionalized");
        require(_numShares > 0, "SynapticNexus: Number of shares must be greater than zero");

        for (uint256 i = 0; i < _numShares; i++) {
            _shareCounter.increment(); // Increments global share counter
            uint256 shareId = _shareCounter.current(); // Unique ID for each share
            modelShares[_modelId][shareId] = msg.sender; // Assign share ownership to model creator initially
        }
        model.totalShares = _numShares;
        emit ModelSharesMinted(_modelId, msg.sender, _numShares);
    }

    /**
     * @dev Allows the owner of a specific fractional model share to transfer it to another address.
     * This mimics basic ERC-721 transfer functionality for a single, unique share.
     * @param _modelId The ID of the model to which the share belongs.
     * @param _shareId The unique ID of the specific share to transfer.
     * @param _to The recipient address of the share.
     */
    function transferModelShare(uint256 _modelId, uint256 _shareId, address _to)
        public
        whenNotPaused
        modelExists(_modelId)
    {
        require(aiModels[_modelId].totalShares > 0, "SynapticNexus: Model is not fractionalized");
        require(modelShares[_modelId][_shareId] == msg.sender, "SynapticNexus: Not owner of this share");
        require(_to != address(0), "SynapticNexus: Cannot transfer to zero address");
        require(modelShares[_modelId][_shareId] != address(0), "SynapticNexus: Share does not exist");

        modelShares[_modelId][_shareId] = _to;
        emit ModelShareTransferred(_modelId, _shareId, msg.sender, _to);
    }

    /**
     * @dev Oracle-fed function to update a model's performance score.
     * This score can dynamically influence its perceived value, ranking, or internal pricing mechanisms.
     * This function is expected to be called by an authorized oracle after external evaluation.
     * @param _modelId The ID of the model whose performance is being updated.
     * @param _newScore The new performance score (e.g., accuracy, speed, F1-score, scaled appropriately).
     */
    function updateModelPerformanceMetric(uint256 _modelId, uint256 _newScore)
        public
        onlyOracle
        whenNotPaused
        modelExists(_modelId)
    {
        aiModels[_modelId].performanceScore = _newScore;
        aiModels[_modelId].lastPerformanceUpdate = block.timestamp;
        emit ModelPerformanceUpdated(_modelId, _newScore, block.timestamp);
    }

    // --- VI. Administrative & Utility Functions ---

    /**
     * @dev Grants an address the permission to submit oracle-fed data (e.g., proofs, performance scores).
     * Only callable by the contract owner.
     * @param _oracleAddress The address to grant oracle role.
     */
    function grantOracleRole(address _oracleAddress) public onlyOwner {
        isOracle[_oracleAddress] = true;
        emit OracleRoleGranted(_oracleAddress);
    }

    /**
     * @dev Revokes oracle permissions from an address.
     * Only callable by the contract owner.
     * @param _oracleAddress The address to revoke oracle role from.
     */
    function revokeOracleRole(address _oracleAddress) public onlyOwner {
        isOracle[_oracleAddress] = false;
        emit OracleRoleRevoked(_oracleAddress);
    }

    /**
     * @dev Pauses the contract, halting most state-changing operations.
     * Useful in emergency situations (e.g., discovering a critical bug).
     * Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming normal operations.
     * Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated fees or general funds
     * that are not specifically allocated to task reward pools or model revenues.
     * This ensures the contract doesn't trap funds.
     * @param _recipient The address to send funds to.
     * @param _amount The amount to withdraw in wei.
     */
    function withdrawFunds(address _recipient, uint256 _amount) public onlyOwner {
        require(_amount > 0, "SynapticNexus: Amount must be greater than zero");
        require(address(this).balance >= _amount, "SynapticNexus: Insufficient contract balance");
        payable(_recipient).transfer(_amount);
    }

    // --- Public Getter for Share Ownership ---
    /**
     * @dev Returns the current owner of a specific fractional model share.
     * @param _modelId The ID of the model.
     * @param _shareId The unique ID of the share.
     * @return The address of the share owner.
     */
    function getModelShareOwner(uint256 _modelId, uint256 _shareId) public view returns (address) {
        return modelShares[_modelId][_shareId];
    }
}
```