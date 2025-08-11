This smart contract, `AIXChange`, aims to create a decentralized marketplace and collaborative platform for AI models. It combines several advanced concepts such as NFT ownership for AI models, incentivized decentralized training, "Inference as a Service" with subscriptions, and a basic DAO-like governance system, all while integrating a reputation mechanism. The goal is to avoid direct duplication of existing open-source projects by combining these functionalities into a novel, cohesive ecosystem specifically designed for AI assets.

---

## AIXChange Smart Contract Outline

1.  **Core Contracts & Standards:**
    *   Leverages OpenZeppelin's `ERC721` for AI Model NFTs, providing standard non-fungible token functionalities (ownership, transfers).
    *   Uses `Ownable` for administrative control over critical functions (e.g., initial model registration, pausing, forced owner changes, oracle functions).
    *   Integrates `ReentrancyGuard` for security against reentrancy attacks.
    *   Utilizes `Counters` for unique ID generation and `SafeMath` for secure arithmetic operations.
2.  **Enums & Structs:**
    *   **`ModelStatus`**: Defines the lifecycle state of an AI model (Active, ListedForSale, Paused, Burned).
    *   **`TrainingTaskStatus`**: Tracks the progression of a training task (Open, DataCollection, InProgress, PendingVerification, Completed, Failed, Cancelled).
    *   **`DataContributionStatus`**: Indicates the state of data submitted for training (Pending, AttestedGood, AttestedPoor).
    *   **`ProposalStatus`**: Manages the lifecycle of governance proposals (Pending, Active, Passed, Failed, Executed).
    *   **`AIModel`**: Stores comprehensive metadata and state for each AI model NFT.
    *   **`TrainingTask`**: Details the parameters, participants, and status of a decentralized training effort.
    *   **`DataContribution`**: Records individual data submissions for training tasks, including quality scores.
    *   **`ModelUpgradeProposal`**: Defines the structure for governance proposals concerning model updates.
    *   **`UserSubscription`**: Tracks active subscriptions for model inference.
3.  **State Variables:**
    *   `_modelIds`, `_taskIds`, `_proposalIds`: Counters for managing unique identifiers.
    *   `aiModels`: Mapping from model ID to `AIModel` struct.
    *   `trainingTasks`: Mapping from task ID to `TrainingTask` struct.
    *   `dataContributions`: Nested mapping for data submitted to tasks by contributors.
    *   `modelUpgradeProposals`: Mapping from proposal ID to `ModelUpgradeProposal` struct.
    *   `modelSubscriptions`: Nested mapping for user subscriptions to models.
    *   `internalBalances`: Tracks user ETH balances held within the contract.
    *   `reputationScores`: Manages reputation scores for participants.
    *   `paused`: Boolean flag for emergency pause functionality.
4.  **Events:**
    *   Emits detailed events for all significant actions, crucial for off-chain indexing, user interfaces, and auditing.
5.  **Modifiers:**
    *   `whenNotPaused`: Prevents execution if the contract is paused.
    *   `onlyModelOwner`: Restricts function calls to the current owner of a specific AI Model NFT.
    *   `onlyTaskOwner`: Restricts function calls to the owner of the AI Model associated with a training task.
6.  **Core AI Model Management (NFTs):**
    *   Functions for minting new AI Model NFTs, updating their descriptive metadata (URI, name, symbol), listing them for sale on an internal marketplace, facilitating their purchase, and canceling sales. Standard ERC721 transfer functions are implicitly available.
7.  **Decentralized Training & Data Collaboration:**
    *   Enables model owners to create and fund training tasks.
    *   Allows data providers to propose data contributions, which can then be attested for quality by the model owner or designated oracle.
    *   Compute providers can accept training tasks, submit their results (including conceptual support for ZKP-like proofs for verifiable computation), and have their results verified.
    *   Rewards are distributed to successful data and compute contributors.
8.  **Inference as a Service (IaaS):**
    *   Model owners can set fees for per-request inference or define subscription prices.
    *   Users can subscribe to models for time-based access or pay per inference request using their internal balance.
    *   Includes a function for an authorized oracle to record actual inference usage and charge users accordingly.
    *   Model owners can withdraw accumulated inference fees.
9.  **Governance & Reputation:**
    *   Implements a basic proposal system where model owners can propose upgrades (e.g., updating a model's URI).
    *   Users holding AI Model NFTs can vote on these proposals.
    *   A function to execute passed proposals.
    *   A reputation system allows adjusting participant scores, which can be influenced by performance in training tasks or governance.
10. **Financial & Utility:**
    *   Provides functions for users to deposit and withdraw ETH from their internal contract balances.
    *   Includes an `emergencyPause` and `unpause` mechanism for crucial security situations.
    *   Administrative functions like `setModelOwner` (for dispute resolution) and `burnAIModel` are included.

---

## Smart Contract Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. Core Contracts & Standards: Leverages ERC721 for AI Model NFTs, Ownable for admin control, ReentrancyGuard for security.
// 2. Enums & Structs: Defines states for models, training tasks, data contributions, proposals, and subscriptions.
// 3. State Variables: Mappings to store all platform data, internal balances, and counters for unique IDs.
// 4. Events: Emits events for all significant state changes, enabling off-chain indexing and monitoring.
// 5. Modifiers: Custom access control and state validation modifiers to ensure correct function execution.
// 6. Core AI Model Management (NFTs): Functions for minting, updating metadata, listing, buying, canceling sales, and transferring AI Model NFTs.
// 7. Decentralized Training & Data Collaboration: Facilitates the creation of training tasks, data contribution, quality attestation, task acceptance, result submission/verification, and participant rewards. Incorporates conceptual elements for verifiable AI (ZKP-like proof submission).
// 8. Inference as a Service (IaaS): Allows model owners to set inference fees and subscription prices, users to subscribe or pay-per-request, and mechanisms for recording usage and fee withdrawal. Assumes off-chain oracle integration for usage recording.
// 9. Governance & Reputation: Implements a basic DAO-like proposal system for model upgrades and a reputation system to track participant reliability.
// 10. Financial & Utility: Manages internal user ETH balances (deposit/withdraw), and includes emergency pause/unpause functionality for security.

// Function Summary:
// - registerAIModel(string _name, string _symbol, string _modelURI, address _owner, uint256 _initialPrice): Mints a new AI Model NFT, making it available on the platform.
// - updateModelMetadata(uint256 _modelId, string _newModelURI, string _newName, string _newSymbol): Allows model owners to update their model's descriptive information.
// - listModelForSale(uint256 _modelId, uint256 _price): Puts an AI Model NFT up for sale on the marketplace.
// - buyAIModel(uint256 _modelId): Purchases an AI Model NFT from the marketplace.
// - cancelModelListing(uint256 _modelId): Removes an AI Model NFT from sale.
// - transferFrom(address _from, address _to, uint256 _tokenId) / safeTransferFrom(...): Standard ERC721 functions for direct NFT transfers.
// - createTrainingTask(uint256 _modelId, uint256 _rewardAmount, uint256 _dataQualityScoreThreshold, string _taskDescriptionURI, uint256 _duration): Initiates a new training task for an AI model, defining rewards and requirements.
// - proposeTrainingData(uint256 _taskId, string _dataHashURI): Allows users to submit data contributions for a specific training task.
// - attestDataQuality(uint256 _taskId, address _dataProvider, uint256 _score): Model owner or authorized entity verifies the quality of submitted data.
// - acceptTrainingTask(uint256 _taskId): Compute providers can commit to performing a training task.
// - submitTrainingResult(uint256 _taskId, string _resultHashURI, bytes _verificationProof): Compute providers submit the outcome of a training task, potentially with a cryptographic proof.
// - verifyTrainingResult(uint256 _taskId, address _submitter, bool _isValid): Model owner or authorized entity verifies the submitted training result.
// - rewardTrainingParticipants(uint256 _taskId): Distributes rewards to data and compute providers upon successful task completion. (Internal helper)
// - setInferenceFee(uint256 _modelId, uint256 _feePerRequest, uint256 _subscriptionPrice): Model owners define pricing for using their models (per request or subscription).
// - subscribeToModel(uint256 _modelId, uint256 _durationInDays): Users pay for a time-based subscription to access a model.
// - requestInferenceSession(uint256 _modelId): Allows users to initiate an inference session, checking for active subscriptions or requiring payment.
// - recordInferenceUsage(uint256 _modelId, address _user, uint256 _amount): (Assumes Oracle) Records and potentially charges for actual inference usage.
// - withdrawInferenceFees(uint256 _modelId): Model owners can claim accumulated inference revenue.
// - proposeModelUpgrade(uint256 _modelId, string _newModelURI, string _descriptionURI): Initiates a governance proposal to update an AI model's core attributes.
// - voteOnProposal(uint256 _proposalId, bool _support): Allows eligible users to cast votes on active governance proposals.
// - executeProposal(uint256 _proposalId): Executes a passed governance proposal, applying changes to the model.
// - updateReputationScore(address _participant, int256 _scoreChange): Adjusts a participant's reputation score (e.g., based on performance or disputes).
// - getReputation(address _participant): Retrieves the reputation score for a given address.
// - depositFunds(): Allows users to deposit Ether into their internal contract balance.
// - withdrawFunds(uint256 _amount): Enables users to withdraw Ether from their internal contract balance.
// - emergencyPause(): Pauses critical contract functionalities in emergencies.
// - unpause(): Resumes contract functionalities after an emergency pause.
// - setModelOwner(uint256 _modelId, address _newOwner): Administrative function to forcefully change a model's owner (e.g., for dispute resolution).
// - burnAIModel(uint256 _modelId): Allows an owner or admin to burn an AI Model NFT.

contract AIXChange is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Enums ---

    enum ModelStatus {
        ACTIVE,
        LISTED_FOR_SALE,
        PAUSED,
        BURNED
    }

    enum TrainingTaskStatus {
        OPEN,
        DATA_COLLECTION,
        IN_PROGRESS,
        PENDING_VERIFICATION,
        COMPLETED,
        FAILED,
        CANCELLED
    }

    enum DataContributionStatus {
        PENDING,
        ATTESTED_GOOD,
        ATTESTED_POOR
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        PASSED,
        FAILED,
        EXECUTED
    }

    // --- Structs ---

    struct AIModel {
        uint256 id;
        string name;
        string symbol;
        string modelURI; // IPFS hash or similar for model weights/description
        address currentOwner;
        ModelStatus status;
        uint256 price; // If listed for sale
        uint256 feePerInference;
        uint256 subscriptionPrice;
        uint256 totalInferenceFeesCollected;
        uint256 createdAt;
    }

    struct TrainingTask {
        uint256 id;
        uint256 modelId;
        uint256 rewardAmount; // Total reward for the task, split between data/compute providers
        uint256 dataQualityScoreThreshold; // Minimum score for data providers
        string taskDescriptionURI; // URI for detailed task requirements
        uint256 duration; // Duration in seconds for task completion
        address dataProvider; // Primary data contributor (if one) - Simplification
        address computeProvider; // Assigned compute provider
        TrainingTaskStatus status;
        uint256 createdAt;
        uint256 startedAt;
        uint256 completedAt;
        string resultHashURI; // URI for the trained model hash
        bytes verificationProof; // Optional proof for verifiable computation (e.g., ZKP proof)
    }

    struct DataContribution {
        uint256 taskId;
        address contributor;
        string dataHashURI;
        DataContributionStatus status;
        uint256 qualityScore; // 0-100 score
        uint256 submittedAt;
    }

    struct ModelUpgradeProposal {
        uint256 id;
        uint256 modelId;
        string newModelURI;
        string descriptionURI;
        address proposer;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    struct UserSubscription {
        uint256 modelId;
        uint256 expiresAt; // Timestamp when subscription expires
    }

    // --- State Variables ---

    Counters.Counter private _modelIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;

    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => TrainingTask) public trainingTasks;
    mapping(uint256 => mapping(address => DataContribution)) public dataContributions; // taskId => contributor address => DataContribution
    mapping(uint256 => ModelUpgradeProposal) public modelUpgradeProposals;
    mapping(uint256 => mapping(address => UserSubscription)) public modelSubscriptions; // modelId => user address => subscription

    // Internal balances for users to manage funds on the platform (ETH equivalent)
    mapping(address => uint256) public internalBalances;
    // Reputation scores for participants (e.g., data providers, compute providers)
    mapping(address => int256) public reputationScores;

    bool public paused = false; // Emergency pause flag

    // --- Events ---

    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string name, string modelURI, uint256 initialPrice);
    event ModelMetadataUpdated(uint256 indexed modelId, string newModelURI, string newName);
    event ModelListedForSale(uint252 indexed modelId, address indexed seller, uint256 price);
    event ModelPurchased(uint256 indexed modelId, address indexed buyer, address indexed seller, uint256 price);
    event ModelListingCancelled(uint256 indexed modelId, address indexed seller);

    event TrainingTaskCreated(uint256 indexed taskId, uint256 indexed modelId, uint256 rewardAmount);
    event TrainingDataProposed(uint256 indexed taskId, address indexed contributor, string dataHashURI);
    event DataQualityAttested(uint256 indexed taskId, address indexed dataProvider, uint256 score);
    event TrainingTaskAccepted(uint256 indexed taskId, address indexed computeProvider);
    event TrainingResultSubmitted(uint256 indexed taskId, address indexed submitter, string resultHashURI);
    event TrainingResultVerified(uint256 indexed taskId, address indexed verifier, bool isValid);
    event TrainingParticipantsRewarded(uint256 indexed taskId, uint256 rewardAmount, address indexed modelOwner);

    event InferenceFeeSet(uint256 indexed modelId, uint256 feePerRequest, uint256 subscriptionPrice);
    event ModelSubscribed(uint256 indexed modelId, address indexed subscriber, uint256 expiresAt);
    event InferenceSessionRequested(uint256 indexed modelId, address indexed user);
    event InferenceUsageRecorded(uint256 indexed modelId, address indexed user, uint256 amountCharged);
    event InferenceFeesWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, uint256 indexed modelId, address indexed proposer, string descriptionURI, uint256 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed modelId);

    event ReputationScoreUpdated(address indexed participant, int256 newScore, int256 scoreChange);

    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);

    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        require(_exists(_modelId), "Model does not exist");
        require(ownerOf(_modelId) == msg.sender, "Caller is not model owner");
        _;
    }

    modifier onlyTaskOwner(uint256 _taskId) {
        require(trainingTasks[_taskId].modelId > 0, "Task does not exist");
        require(ownerOf(trainingTasks[_taskId].modelId) == msg.sender, "Caller is not the model owner for this task");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("AIXChange Model", "AIXM") Ownable(msg.sender) {}

    // --- Core AI Model Management (ERC721 based) ---

    /**
     * @dev Registers a new AI Model by minting an NFT for it. Only callable by the contract owner (admin).
     * @param _name The name of the AI model.
     * @param _symbol The symbol/ticker for the AI model.
     * @param _modelURI A URI pointing to the model's metadata (e.g., IPFS hash of model weights, description).
     * @param _owner The initial owner of the AI Model NFT.
     * @param _initialPrice The initial price if the model is to be immediately available for direct sale (0 if not).
     * @return The ID of the newly minted AI Model NFT.
     */
    function registerAIModel(
        string calldata _name,
        string calldata _symbol,
        string calldata _modelURI,
        address _owner,
        uint256 _initialPrice
    ) external onlyOwner whenNotPaused returns (uint256) {
        _modelIds.increment();
        uint256 newItemId = _modelIds.current();

        _mint(_owner, newItemId); // Mint the ERC721 token

        aiModels[newItemId] = AIModel({
            id: newItemId,
            name: _name,
            symbol: _symbol,
            modelURI: _modelURI,
            currentOwner: _owner, // This convenience field should reflect ERC721's ownerOf
            status: ModelStatus.ACTIVE,
            price: _initialPrice,
            feePerInference: 0,
            subscriptionPrice: 0,
            totalInferenceFeesCollected: 0,
            createdAt: block.timestamp
        });
        
        emit AIModelRegistered(newItemId, _owner, _name, _modelURI, _initialPrice);
        return newItemId;
    }

    /**
     * @dev Allows the owner of an AI Model NFT to update its metadata.
     * @param _modelId The ID of the AI Model to update.
     * @param _newModelURI The new URI for the model's metadata.
     * @param _newName The new name for the model.
     * @param _newSymbol The new symbol for the model.
     */
    function updateModelMetadata(
        uint255 _modelId,
        string calldata _newModelURI,
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyModelOwner(_modelId) whenNotPaused {
        aiModels[_modelId].modelURI = _newModelURI;
        aiModels[_modelId].name = _newName;
        aiModels[_modelId].symbol = _newSymbol;
        emit ModelMetadataUpdated(_modelId, _newModelURI, _newName);
    }

    /**
     * @dev Lists an owned AI Model NFT for sale on the marketplace.
     * @param _modelId The ID of the model to list.
     * @param _price The sale price in wei.
     */
    function listModelForSale(uint256 _modelId, uint256 _price)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
        nonReentrant
    {
        require(_price > 0, "Price must be greater than zero");
        require(aiModels[_modelId].status != ModelStatus.LISTED_FOR_SALE, "Model already listed for sale");

        aiModels[_modelId].price = _price;
        aiModels[_modelId].status = ModelStatus.LISTED_FOR_SALE;
        emit ModelListedForSale(_modelId, msg.sender, _price);
    }

    /**
     * @dev Allows a user to purchase a listed AI Model NFT.
     * @param _modelId The ID of the model to buy.
     */
    function buyAIModel(uint256 _modelId) external payable whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        require(model.status == ModelStatus.LISTED_FOR_SALE, "Model not listed for sale");
        require(msg.value >= model.price, "Insufficient funds to buy model");
        require(ownerOf(_modelId) != msg.sender, "Cannot buy your own model");

        address seller = ownerOf(_modelId);
        require(seller != address(0), "Seller address invalid");

        _transfer(seller, msg.sender, _modelId); // Transfer NFT ownership
        model.currentOwner = msg.sender; // Update convenience owner

        // Transfer funds to seller's internal balance
        internalBalances[seller] = internalBalances[seller].add(model.price);

        // Refund any overpayment
        if (msg.value > model.price) {
            payable(msg.sender).transfer(msg.value.sub(model.price));
        }

        model.status = ModelStatus.ACTIVE; // Mark as active after sale
        model.price = 0; // Reset price after sale
        emit ModelPurchased(_modelId, msg.sender, seller, model.price);
    }

    /**
     * @dev Cancels a previously listed sale for an AI Model NFT.
     * @param _modelId The ID of the model to delist.
     */
    function cancelModelListing(uint256 _modelId)
        external
        onlyModelOwner(_modelId)
        whenNotPaused
        nonReentrant
    {
        AIModel storage model = aiModels[_modelId];
        require(model.status == ModelStatus.LISTED_FOR_SALE, "Model not listed for sale");

        model.status = ModelStatus.ACTIVE;
        model.price = 0; // Reset price
        emit ModelListingCancelled(_modelId, msg.sender);
    }

    // ERC721's `transferFrom` and `safeTransferFrom` functions are inherited and can be used directly
    // for owner-to-owner transfers not involving the marketplace's listing logic.

    // --- Decentralized Training & Data Collaboration ---

    /**
     * @dev Creates a new training task for an AI model, defining the reward and requirements.
     * Funds for the reward are transferred from the model owner to the contract's escrow.
     * @param _modelId The ID of the AI model to be trained.
     * @param _rewardAmount The total reward amount in wei for completing this task.
     * @param _dataQualityScoreThreshold The minimum quality score required for data contributions to be eligible for rewards.
     * @param _taskDescriptionURI A URI pointing to detailed task requirements.
     * @param _duration The maximum duration (in seconds) for the task to be completed.
     * @return The ID of the newly created training task.
     */
    function createTrainingTask(
        uint256 _modelId,
        uint256 _rewardAmount,
        uint256 _dataQualityScoreThreshold,
        string calldata _taskDescriptionURI,
        uint256 _duration
    ) external payable onlyModelOwner(_modelId) whenNotPaused nonReentrant returns (uint256) {
        require(_rewardAmount > 0, "Reward must be positive");
        require(msg.value >= _rewardAmount, "Insufficient funds for task reward");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        trainingTasks[newTaskId] = TrainingTask({
            id: newTaskId,
            modelId: _modelId,
            rewardAmount: _rewardAmount,
            dataQualityScoreThreshold: _dataQualityScoreThreshold,
            taskDescriptionURI: _taskDescriptionURI,
            duration: _duration,
            dataProvider: address(0), // Placeholder, can be filled if a single provider is chosen later
            computeProvider: address(0),
            status: TrainingTaskStatus.OPEN,
            createdAt: block.timestamp,
            startedAt: 0,
            completedAt: 0,
            resultHashURI: "",
            verificationProof: ""
        });

        // Store rewards in contract's internal balance for this task's escrow
        internalBalances[address(this)] = internalBalances[address(this)].add(_rewardAmount);

        emit TrainingTaskCreated(newTaskId, _modelId, _rewardAmount);
        return newTaskId;
    }

    /**
     * @dev Allows a user to propose training data for a specific task.
     * @param _taskId The ID of the training task.
     * @param _dataHashURI A URI pointing to the data (e.g., IPFS hash).
     */
    function proposeTrainingData(uint256 _taskId, string calldata _dataHashURI)
        external
        whenNotPaused
        nonReentrant
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.id > 0, "Task does not exist");
        require(task.status == TrainingTaskStatus.OPEN || task.status == TrainingTaskStatus.DATA_COLLECTION, "Task not open for data submission");
        
        require(dataContributions[_taskId][msg.sender].contributor == address(0), "Data already proposed by this address for this task");

        dataContributions[_taskId][msg.sender] = DataContribution({
            taskId: _taskId,
            contributor: msg.sender,
            dataHashURI: _dataHashURI,
            status: DataContributionStatus.PENDING,
            qualityScore: 0,
            submittedAt: block.timestamp
        });

        // If task was OPEN, transition to DATA_COLLECTION once data starts coming in
        if (task.status == TrainingTaskStatus.OPEN) {
            task.status = TrainingTaskStatus.DATA_COLLECTION;
        }

        emit TrainingDataProposed(_taskId, msg.sender, _dataHashURI);
    }

    /**
     * @dev Model owner or authorized entity attests to the quality of submitted data.
     * @param _taskId The ID of the training task.
     * @param _dataProvider The address of the data provider.
     * @param _score The quality score (0-100) assigned to the data.
     */
    function attestDataQuality(uint256 _taskId, address _dataProvider, uint256 _score)
        external
        onlyTaskOwner(_taskId) // Only the model owner for the task can attest
        whenNotPaused
        nonReentrant
    {
        TrainingTask storage task = trainingTasks[_taskId];
        DataContribution storage contribution = dataContributions[_taskId][_dataProvider];

        require(task.id > 0, "Task does not exist");
        require(contribution.contributor != address(0), "No data submitted by this provider for this task");
        require(contribution.status == DataContributionStatus.PENDING, "Data already attested");
        require(_score <= 100, "Quality score out of 0-100 range");

        contribution.qualityScore = _score;
        contribution.status = (_score >= task.dataQualityScoreThreshold) ? DataContributionStatus.ATTESTED_GOOD : DataContributionStatus.ATTESTED_POOR;

        // Update reputation based on attestation result
        updateReputationScore(_dataProvider, (_score >= task.dataQualityScoreThreshold) ? 1 : -1);

        emit DataQualityAttested(_taskId, _dataProvider, _score);
    }

    /**
     * @dev Allows a compute provider to accept an open training task.
     * @param _taskId The ID of the training task.
     */
    function acceptTrainingTask(uint256 _taskId) external whenNotPaused nonReentrant {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.id > 0, "Task does not exist");
        require(task.status == TrainingTaskStatus.DATA_COLLECTION || task.status == TrainingTaskStatus.OPEN, "Task not open for acceptance");
        require(task.computeProvider == address(0), "Task already assigned to a compute provider");
        
        // In a more advanced version, this would check compute provider reputation, stake, etc.
        task.computeProvider = msg.sender;
        task.status = TrainingTaskStatus.IN_PROGRESS;
        task.startedAt = block.timestamp;

        emit TrainingTaskAccepted(_taskId, msg.sender);
    }

    /**
     * @dev Allows the assigned compute provider to submit the result of a training task.
     * Includes a placeholder for a cryptographic verification proof (e.g., a ZKP).
     * @param _taskId The ID of the training task.
     * @param _resultHashURI A URI pointing to the trained model's hash/weights.
     * @param _verificationProof Optional proof data for off-chain verification (e.g., ZKP proof).
     */
    function submitTrainingResult(
        uint256 _taskId,
        string calldata _resultHashURI,
        bytes calldata _verificationProof
    ) external whenNotPaused nonReentrant {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.id > 0, "Task does not exist");
        require(task.computeProvider == msg.sender, "Only assigned compute provider can submit result");
        require(task.status == TrainingTaskStatus.IN_PROGRESS, "Task not in progress");
        require(block.timestamp <= task.startedAt.add(task.duration), "Task completion deadline passed");

        task.resultHashURI = _resultHashURI;
        task.verificationProof = _verificationProof;
        task.status = TrainingTaskStatus.PENDING_VERIFICATION;
        task.completedAt = block.timestamp;

        emit TrainingResultSubmitted(_taskId, msg.sender, _resultHashURI);
    }

    /**
     * @dev Allows the model owner or authorized entity to verify the submitted training result.
     * @param _taskId The ID of the training task.
     * @param _submitter The address of the compute provider who submitted the result.
     * @param _isValid A boolean indicating if the result is valid (based on off-chain verification or proof check).
     */
    function verifyTrainingResult(uint256 _taskId, address _submitter, bool _isValid)
        external
        onlyTaskOwner(_taskId) // Only the model owner for the task can verify
        whenNotPaused
        nonReentrant
    {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.id > 0, "Task does not exist");
        require(task.status == TrainingTaskStatus.PENDING_VERIFICATION, "Task not pending verification");
        require(task.computeProvider == _submitter, "Result not submitted by this compute provider");

        if (_isValid) {
            task.status = TrainingTaskStatus.COMPLETED;
            rewardTrainingParticipants(_taskId); // Distribute rewards
            updateReputationScore(_submitter, 5); // Reward good compute
        } else {
            task.status = TrainingTaskStatus.FAILED;
            updateReputationScore(_submitter, -5); // Penalize bad compute
        }
        emit TrainingResultVerified(_taskId, msg.sender, _isValid);
    }

    /**
     * @dev Internal function to distribute rewards to participants of a successfully completed training task.
     * Rewards are taken from the task's escrowed funds within the contract.
     * @param _taskId The ID of the completed training task.
     */
    function rewardTrainingParticipants(uint256 _taskId) internal nonReentrant {
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TrainingTaskStatus.COMPLETED, "Task not completed successfully");
        require(task.rewardAmount > 0, "No reward set for this task");

        // Simplification: In a more robust system, all data contributors would be iterated.
        // Here, we assume a simple split between a designated data provider and the compute provider.
        // For demonstration, let's distribute 1/3 of reward to a primary data provider (if good)
        // and 2/3 to the compute provider. If data provider isn't good, compute provider gets full reward.
        
        uint256 dataRewardShare = task.rewardAmount.div(3); 
        uint256 computeRewardShare = task.rewardAmount.sub(dataRewardShare);

        // Check if there's an attested good data provider (using the simplified `dataProvider` field from Task)
        if (dataContributions[_taskId][task.dataProvider].status == DataContributionStatus.ATTESTED_GOOD) {
            internalBalances[task.dataProvider] = internalBalances[task.dataProvider].add(dataRewardShare);
            emit TrainingParticipantsRewarded(_taskId, dataRewardShare, task.dataProvider);
        } else {
            // If no good data provider, or if `task.dataProvider` wasn't explicitly set/relevant,
            // redistribute data reward share to the compute provider.
            computeRewardShare = computeRewardShare.add(dataRewardShare);
        }

        if (task.computeProvider != address(0)) {
            internalBalances[task.computeProvider] = internalBalances[task.computeProvider].add(computeRewardShare);
            emit TrainingParticipantsRewarded(_taskId, computeRewardShare, task.computeProvider);
        }

        // Remove rewarded amount from contract's balance (task escrow)
        internalBalances[address(this)] = internalBalances[address(this)].sub(task.rewardAmount);
    }

    // --- Inference as a Service (IaaS) ---

    /**
     * @dev Allows the model owner to set pricing for model inference.
     * @param _modelId The ID of the model.
     * @param _feePerRequest The price in wei per single inference request.
     * @param _subscriptionPrice The daily price in wei for a subscription.
     */
    function setInferenceFee(
        uint256 _modelId,
        uint256 _feePerRequest,
        uint256 _subscriptionPrice
    ) external onlyModelOwner(_modelId) whenNotPaused {
        aiModels[_modelId].feePerInference = _feePerRequest;
        aiModels[_modelId].subscriptionPrice = _subscriptionPrice;
        emit InferenceFeeSet(_modelId, _feePerRequest, _subscriptionPrice);
    }

    /**
     * @dev Allows a user to subscribe to a model for a specified duration.
     * Payment is made upon subscription.
     * @param _modelId The ID of the model to subscribe to.
     * @param _durationInDays The duration of the subscription in days.
     */
    function subscribeToModel(uint256 _modelId, uint256 _durationInDays)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        AIModel storage model = aiModels[_modelId];
        require(model.id > 0, "Model does not exist");
        require(model.subscriptionPrice > 0, "Subscription not available for this model");
        require(_durationInDays > 0 && _durationInDays <= 365 * 2, "Invalid subscription duration (max 2 years)"); // Limit duration
        
        uint256 totalCost = model.subscriptionPrice.mul(_durationInDays);
        require(msg.value >= totalCost, "Insufficient funds for subscription");

        UserSubscription storage currentSub = modelSubscriptions[_modelId][msg.sender];
        uint256 newExpiresAt;

        if (currentSub.modelId == _modelId && currentSub.expiresAt > block.timestamp) {
            // Extend existing subscription if still active
            newExpiresAt = currentSub.expiresAt.add(_durationInDays.mul(1 days));
        } else {
            // New subscription or existing one expired
            newExpiresAt = block.timestamp.add(_durationInDays.mul(1 days));
        }

        currentSub.modelId = _modelId;
        currentSub.expiresAt = newExpiresAt;

        // Store funds in model owner's pending withdrawal balance
        internalBalances[ownerOf(_modelId)] = internalBalances[ownerOf(_modelId)].add(totalCost);

        // Refund any overpayment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value.sub(totalCost));
        }

        emit ModelSubscribed(_modelId, msg.sender, currentSub.expiresAt);
    }

    /**
     * @dev Allows a user to request an inference session for a model.
     * Checks for active subscription or deducts per-request fee from internal balance.
     * @param _modelId The ID of the model for inference.
     */
    function requestInferenceSession(uint256 _modelId) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        require(model.id > 0, "Model does not exist");

        UserSubscription storage currentSub = modelSubscriptions[_modelId][msg.sender];
        bool hasActiveSubscription = (currentSub.modelId == _modelId && currentSub.expiresAt > block.timestamp);

        if (!hasActiveSubscription) {
            // If no subscription, require payment per request
            require(model.feePerInference > 0, "No subscription and no pay-per-request fee set.");
            require(internalBalances[msg.sender] >= model.feePerInference, "Insufficient balance for inference");
            
            // Deduct from user's internal balance and add to model owner's
            internalBalances[msg.sender] = internalBalances[msg.sender].sub(model.feePerInference);
            internalBalances[ownerOf(_modelId)] = internalBalances[ownerOf(_modelId)].add(model.feePerInference);
            model.totalInferenceFeesCollected = model.totalInferenceFeesCollected.add(model.feePerInference);
        }
        // If `hasActiveSubscription` is true, no payment is needed at this step for basic access.
        // Complex quota management for subscriptions would be handled off-chain or by `recordInferenceUsage`.

        emit InferenceSessionRequested(_modelId, msg.sender);
        // Off-chain oracle/service would then be notified to provide actual inference access.
    }

    /**
     * @dev (Admin/Oracle only) Records actual inference usage and adjusts balances.
     * This function is expected to be called by a trusted off-chain oracle service that monitors
     * the actual usage of AI models.
     * @param _modelId The ID of the model whose usage is being recorded.
     * @param _user The address of the user who consumed the inference.
     * @param _amount The amount to charge the user's internal balance (e.g., if exceeding subscription, or per-unit charge).
     */
    function recordInferenceUsage(uint256 _modelId, address _user, uint256 _amount)
        external
        onlyOwner // Only contract owner (admin) or a trusted oracle can call this
        whenNotPaused
        nonReentrant
    {
        AIModel storage model = aiModels[_modelId];
        require(model.id > 0, "Model does not exist");
        require(_amount > 0, "Usage amount must be positive");

        require(internalBalances[_user] >= _amount, "User has insufficient internal balance for recorded usage");
        internalBalances[_user] = internalBalances[_user].sub(_amount);
        internalBalances[ownerOf(_modelId)] = internalBalances[ownerOf(_modelId)].add(_amount);
        model.totalInferenceFeesCollected = model.totalInferenceFeesCollected.add(_amount);

        emit InferenceUsageRecorded(_modelId, _user, _amount);
    }

    /**
     * @dev Allows the model owner to withdraw accumulated inference fees.
     * These fees are transferred from the contract's general internal balance to the owner's internal balance.
     * @param _modelId The ID of the model to withdraw fees from.
     */
    function withdrawInferenceFees(uint256 _modelId) external onlyModelOwner(_modelId) whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        require(model.totalInferenceFeesCollected > 0, "No inference fees to withdraw");

        uint256 amountToWithdraw = model.totalInferenceFeesCollected;
        model.totalInferenceFeesCollected = 0; // Reset accumulated fees for this model

        // Add to owner's general internal balance (from where they can call `withdrawFunds`)
        internalBalances[msg.sender] = internalBalances[msg.sender].add(amountToWithdraw);
        emit InferenceFeesWithdrawn(_modelId, msg.sender, amountToWithdraw);
    }

    // --- Governance & Reputation ---

    /**
     * @dev Allows a model owner to propose an upgrade (e.g., updating the model's URI).
     * This initiates a voting period for other model owners/token holders.
     * @param _modelId The ID of the model to propose an upgrade for.
     * @param _newModelURI The new model URI if the proposal passes.
     * @param _descriptionURI A URI pointing to the detailed description of the proposed changes.
     * @return The ID of the new proposal.
     */
    function proposeModelUpgrade(
        uint256 _modelId,
        string calldata _newModelURI,
        string calldata _descriptionURI
    ) external onlyModelOwner(_modelId) whenNotPaused returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        require(model.id > 0, "Model does not exist");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        modelUpgradeProposals[newProposalId] = ModelUpgradeProposal({
            id: newProposalId,
            modelId: _modelId,
            newModelURI: _newModelURI,
            descriptionURI: _descriptionURI,
            proposer: msg.sender,
            votingDeadline: block.timestamp.add(7 days), // 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.ACTIVE
        });

        emit ProposalCreated(newProposalId, _modelId, msg.sender, _descriptionURI, block.timestamp.add(7 days));
        return newProposalId;
    }

    /**
     * @dev Allows users (specifically, AI Model NFT holders) to vote on an active proposal.
     * Each AI Model NFT owned by the voter counts as one vote.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProposal(uint255 _proposalId, bool _support) external whenNotPaused nonReentrant {
        ModelUpgradeProposal storage proposal = modelUpgradeProposals[_proposalId];
        require(proposal.id > 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not in active voting period");
        require(block.timestamp < proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        // Voting power is based on the number of AI Model NFTs owned.
        uint256 voterNFTBalance = balanceOf(msg.sender);
        require(voterNFTBalance > 0, "Must own at least one AI Model NFT to vote");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterNFTBalance);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterNFTBalance);
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed governance proposal after the voting deadline.
     * Current implementation requires `onlyOwner` to execute for safety, but could be made permissionless.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused nonReentrant {
        ModelUpgradeProposal storage proposal = modelUpgradeProposals[_proposalId];
        require(proposal.id > 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not active or already executed/failed");
        require(block.timestamp >= proposal.votingDeadline, "Voting period not ended yet");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Simple majority rules. Could be extended with quorum or supermajority logic.
            aiModels[proposal.modelId].modelURI = proposal.newModelURI;
            proposal.status = ProposalStatus.EXECUTED;
            emit ProposalExecuted(_proposalId, proposal.modelId);
        } else {
            proposal.status = ProposalStatus.FAILED;
            // No event for failed execution as it implicitly indicates no change
        }
    }

    /**
     * @dev Updates a participant's reputation score. This function is controlled by the contract owner (admin)
     * and can be used to reward good behavior or penalize bad behavior based on off-chain assessments or dispute outcomes.
     * @param _participant The address whose reputation score is to be updated.
     * @param _scoreChange The amount to change the score by (can be positive or negative).
     */
    function updateReputationScore(address _participant, int256 _scoreChange)
        public
        onlyOwner // Only admin can modify reputation directly, or via attested actions (like in attestDataQuality/verifyTrainingResult)
    {
        int256 currentScore = reputationScores[_participant];
        int256 newScore = currentScore + _scoreChange; // int256 handles addition/subtraction safely

        // Optional: Add bounds to reputation score (e.g., -1000 to 1000)
        // if (newScore > 1000) newScore = 1000;
        // if (newScore < -1000) newScore = -1000;

        reputationScores[_participant] = newScore;
        emit ReputationScoreUpdated(_participant, newScore, _scoreChange);
    }

    /**
     * @dev Retrieves the current reputation score for a given participant address.
     * @param _participant The address to query.
     * @return The current reputation score.
     */
    function getReputation(address _participant) public view returns (int256) {
        return reputationScores[_participant];
    }

    // --- Financial & Utility ---

    /**
     * @dev Allows users to deposit Ether into their internal balance within the contract.
     * These funds can then be used for subscriptions, pay-per-inference, or withdrawn.
     */
    function depositFunds() external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        internalBalances[msg.sender] = internalBalances[msg.sender].add(msg.value);
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to withdraw Ether from their internal balance.
     * @param _amount The amount of Ether in wei to withdraw.
     */
    function withdrawFunds(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(internalBalances[msg.sender] >= _amount, "Insufficient internal balance");

        internalBalances[msg.sender] = internalBalances[msg.sender].sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Puts the contract into an emergency paused state. Only callable by the contract owner.
     * Prevents execution of most sensitive functions.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Resumes contract operation from a paused state. Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Administrative function to forcefully change the owner of an AI Model NFT.
     * Useful for dispute resolution or recovery.
     * @param _modelId The ID of the model.
     * @param _newOwner The new owner address.
     */
    function setModelOwner(uint256 _modelId, address _newOwner) external onlyOwner whenNotPaused {
        require(_exists(_modelId), "Model does not exist");
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        address currentOwner = ownerOf(_modelId);
        _transfer(currentOwner, _newOwner, _modelId);
        aiModels[_modelId].currentOwner = _newOwner; // Update convenience mapping
    }

    /**
     * @dev Allows the model owner or contract administrator to burn an AI Model NFT.
     * Burning removes the NFT from circulation and updates its status.
     * @param _modelId The ID of the model to burn.
     */
    function burnAIModel(uint256 _modelId) external onlyModelOwner(_modelId) whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.status != ModelStatus.BURNED, "Model already burned");
        
        _burn(_modelId); // ERC721 internal burn function
        model.status = ModelStatus.BURNED;
        model.currentOwner = address(0); // Clear owner for burned models
        // Further cleanup (e.g., cancelling active tasks/subscriptions) might be needed in a full system.
    }
}
```