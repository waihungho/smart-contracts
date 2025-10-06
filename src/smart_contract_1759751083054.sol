Here is a Solidity smart contract named `AetherMindHub` that implements an advanced, creative, and trendy concept: a decentralized ecosystem for AI model development, collaborative training, and a marketplace for AI model inference and usage.

This contract aims to foster innovation by rewarding contributions to models, datasets, and computational resources, ensuring quality and integrity through staking, reputation, and oracle-based validation. It integrates several advanced concepts such as:

*   **Decentralized AI Marketplace:** Users can list, discover, and license AI models.
*   **Collaborative Training:** Incentivized system for users to contribute compute and datasets to improve AI models.
*   **Verifiable Computation (via Oracle):** Leverages an off-chain oracle (simulated by an interface) to verify the integrity and success of AI training tasks, bridging the gap between on-chain logic and off-chain heavy computation.
*   **Staking & Slashing:** Participants stake tokens to ensure honest behavior, with mechanisms for slashing dishonest or failed contributions.
*   **Reputation System:** Users accrue reputation based on successful contributions, which could unlock further privileges or rewards.
*   **Dynamic NFTs/Data:** Models and datasets are represented by on-chain metadata pointing to off-chain IPFS content, with models dynamically updating versions after successful training.
*   **Tokenomics:** Utilizes a custom ERC-20 token for staking, rewards, and marketplace transactions, including platform fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for older contracts, 0.8.0+ has native overflow checks. Safe for 0.8.20 if desired, but not strictly needed.

// --- INTERFACES ---

/**
 * @title IOffchainOracle
 * @dev Interface for an off-chain oracle service that verifies AI computations.
 *      In a real scenario, this would integrate with a decentralized oracle network
 *      (e.g., Chainlink, Pyth, Redstone) or a custom network of verifiers.
 *      It requests verification for a training task and then the oracle calls back
 *      `fulfillOracleVerification` on the AetherMindHub contract.
 */
interface IOffchainOracle {
    /**
     * @dev Requests an off-chain verification for a training result.
     * @param _taskId The ID of the training task.
     * @param _modelIpfsHash IPFS hash of the base model before training.
     * @param _datasetIpfsHash IPFS hash of the dataset used for training.
     * @param _trainingResultIpfsHash IPFS hash of the resulting model after training.
     * @param _callbackContract The address of the contract to call back (AetherMindHub).
     * @param _callbackFunctionSelector The selector of the function to call on the callback contract
     *                                 (e.g., `this.fulfillOracleVerification.selector`).
     * @return requestId A unique ID to track the oracle request.
     */
    function requestVerification(
        uint256 _taskId,
        string calldata _modelIpfsHash,
        string calldata _datasetIpfsHash,
        string calldata _trainingResultIpfsHash,
        address _callbackContract,
        bytes4 _callbackFunctionSelector
    ) external returns (bytes32 requestId);
}

// --- CONTRACT ---

/**
 * @title AetherMindHub
 * @dev A decentralized ecosystem for AI model development, collaborative training,
 *      and a marketplace for AI model inference and usage.
 *      It fosters innovation by rewarding contributions to models, datasets, and
 *      computational resources, ensuring quality and integrity through staking,
 *      reputation, and oracle-based validation.
 *
 * Outline:
 *   I. Core Management & Setup
 *  II. Model Lifecycle Management
 * III. Dataset Management
 *  IV. Collaborative Training & Verification
 *   V. Marketplace & Inference
 *  VI. Staking & Reputation
 * VII. Admin & Utility
 *
 * Function Summary:
 *
 * I. Core Management & Setup (3 functions)
 * 1.  constructor(address _aiToken, address _oracleAddress, address _adminFeeRecipient): Initializes the contract with an ERC-20 AI token address, an oracle contract address, and a recipient for platform fees.
 * 2.  pause(): Allows the contract owner to pause certain functionalities in case of emergencies, preventing further state changes.
 * 3.  unpause(): Allows the contract owner to unpause functionalities after a pause, restoring normal operations.
 *
 * II. Model Lifecycle Management (5 functions)
 * 4.  registerModel(string memory _name, string memory _description, string memory _ipfsHash, uint256 _inferencePrice): Enables any user to register a new AI model, providing its metadata (name, description, IPFS hash for weights/config) and an initial inference price.
 * 5.  updateModelMetadata(uint256 _modelId, string memory _newName, string memory _newDescription, string memory _newIpfsHash): Allows the owner of a registered model to update its descriptive metadata and IPFS hash, typically reflecting an updated version.
 * 6.  transferModelOwnership(uint256 _modelId, address _newOwner): Permits a model owner to transfer the ownership of their model to another address.
 * 7.  setModelInferencePrice(uint256 _modelId, uint256 _price): Allows the model owner to adjust the per-unit price for accessing their model's inference services.
 * 8.  toggleModelPublicStatus(uint256 _modelId, bool _isPublic): Enables the model owner to control whether their model is publicly available for discovery and inference purchases.
 *
 * III. Dataset Management (3 functions)
 * 9.  registerDataset(string memory _name, string memory _description, string memory _ipfsHash, string memory _validationHash): Allows users to register a new dataset, including its name, description, IPFS hash for content, and a hash for off-chain validation.
 * 10. proposeDatasetForModel(uint256 _datasetId, uint256 _modelId): Enables a dataset owner to formally propose their dataset for association with a specific AI model, suggesting its use for training.
 * 11. approveDatasetAssociation(uint256 _modelId, uint256 _datasetId): Allows the model owner to officially approve a proposed dataset, making it available for training tasks related to their model.
 *
 * IV. Collaborative Training & Verification (4 functions)
 * 12. proposeTrainingTask(uint256 _modelId, uint256 _datasetId, uint256 _stakeAmount): A user can propose a new training task for an approved model-dataset pair, staking AI_TOKENs as an assurance of intent and quality.
 * 13. acceptTrainingTask(uint256 _taskId): Allows a "compute node" (another user) to accept a proposed training task, committing to perform the actual AI model training off-chain.
 * 14. submitTrainingResult(uint256 _taskId, string memory _resultIpfsHash): The assigned compute node submits the IPFS hash of the trained model (or results) after completing the off-chain computation, triggering an oracle verification.
 * 15. fulfillOracleVerification(uint256 _taskId, bool _isSuccess, string memory _verificationDetails): This is an `onlyOracle` callback function. The off-chain oracle calls this to report whether the submitted training result was successful. It handles reward distribution, slashing, and reputation updates based on the verification outcome.
 *
 * V. Marketplace & Inference (3 functions)
 * 16. buyModelInferenceAccess(uint256 _modelId, uint256 _durationInSeconds): Allows a user to purchase time-based access to use a specific AI model for inference. The cost is paid in AI_TOKENs, and access is granted for a specified duration.
 * 17. payForModelInference(uint256 _modelId, uint256 _numInferences): Allows a user to purchase a specific number of inference credits for a model. This provides an alternative to time-based access.
 * 18. withdrawModelEarnings(uint256 _modelId): Enables a model owner to withdraw the AI_TOKENs accumulated from inference purchases of their model.
 *
 * VI. Staking & Reputation (3 functions)
 * 19. stake(uint256 _amount): Allows users to deposit AI_TOKENs into the contract, which is required for participating in roles like proposing or accepting training tasks.
 * 20. unstake(uint256 _amount): Allows users to withdraw their staked AI_TOKENs. In a more complex system, this might involve a cooldown period or restrictions if the stake is locked in active tasks.
 * 21. claimReputationReward(): (Placeholder) A function intended for future expansion, where users could claim rewards or benefits based on their accumulated reputation score.
 *
 * VII. Admin & Utility (6 functions)
 * 22. setOracleAddress(address _newOracleAddress): Allows the contract owner to update the address of the trusted off-chain oracle contract.
 * 23. setAdminFeeRecipient(address _newRecipient): Allows the contract owner to change the address designated to receive platform fees.
 * 24. withdrawPlatformFees(): Enables the `adminFeeRecipient` to withdraw the platform fees accumulated from model inference transactions.
 * 25. getModelDetails(uint256 _modelId): A public view function to retrieve all stored information about a specific AI model.
 * 26. getTrainingTaskDetails(uint256 _taskId): A public view function to retrieve all stored information about a specific training task.
 * 27. getReputation(address _user): A public view function to query the current reputation score of any given user address.
 */
contract AetherMindHub is Ownable, Pausable {
    using SafeMath for uint256; // Explicitly use SafeMath for clarity, though 0.8.0+ has default overflow checks.

    // --- State Variables ---
    IERC20 public immutable AI_TOKEN; // The ERC-20 token used for staking, rewards, and payments.
    IOffchainOracle public oracle;     // Interface to the off-chain oracle for verification.
    address public adminFeeRecipient;  // Address designated to receive platform fees.

    uint256 public modelIdCounter;        // Counter for unique model IDs.
    uint256 public datasetIdCounter;      // Counter for unique dataset IDs.
    uint256 public trainingTaskIdCounter; // Counter for unique training task IDs.

    uint256 public constant MIN_STAKE_AMOUNT = 1 ether; // Example minimum stake requirement for participation.
    uint256 public constant PLATFORM_FEE_PERCENT = 5;   // 5% fee on model inference revenue.
    uint256 public constant INFERENCE_ACCESS_GRANULARITY_SECONDS = 3600; // 1 hour increments for access duration.

    mapping(address => int256) public reputation; // Tracks user reputation. Can be negative if heavily slashed.
    mapping(address => uint256) public totalStaked; // Total tokens staked by a user.

    // --- Structs ---

    // Enum to represent the current status of a training task.
    enum TrainingTaskStatus {
        Proposed,          // Task is proposed, awaiting compute node.
        InProgress,        // Task accepted by compute node, training off-chain.
        Submitted,         // Compute node submitted results, awaiting oracle verification.
        VerifiedSuccess,   // Oracle verified results as successful.
        VerifiedFailed,    // Oracle verified results as failed/malicious.
        Cancelled          // Task was cancelled (e.g., by proposer before acceptance).
    }

    // Structure to store details of an AI model.
    struct Model {
        address owner;             // Address of the model owner.
        string name;               // Name of the model.
        string description;        // Description of the model.
        string ipfsHash;           // IPFS hash for model metadata/weights.
        uint256 version;           // Incremental version number for the model.
        bool isPublic;             // True if the model is publicly listed and usable.
        uint256 inferencePricePerUnit; // Price (in AI_TOKEN) for one unit of inference or access.
        uint256 lastUpdatedBlock;  // Block number when the model was last updated.
        uint256[] associatedDatasets; // IDs of datasets approved for training this model.
    }

    // Structure to store details of a dataset.
    struct Dataset {
        address owner;             // Address of the dataset owner.
        string name;               // Name of the dataset.
        string description;        // Description of the dataset.
        string ipfsHash;           // IPFS hash for dataset content.
        string validationHash;     // Hash or metadata for off-chain dataset validation.
        // For simplicity, `isApproved` by platform admin is removed, model owner approves association.
        uint256[] associatedModels; // IDs of models this dataset is associated with.
    }

    // Structure to store details of a training task.
    struct TrainingTask {
        uint256 modelId;           // ID of the model to be trained.
        uint256 datasetId;         // ID of the dataset to use for training.
        address proposer;          // Address of the user who proposed the task.
        address computeNode;       // Address of the compute node performing the training.
        uint256 stakeAmount;       // Amount of AI_TOKENs staked by the proposer.
        TrainingTaskStatus status; // Current status of the task.
        string resultIpfsHash;     // IPFS hash for the trained model weights/results.
        uint256 proposedBlock;     // Block number when the task was proposed.
        bytes32 verificationRequestId; // ID from oracle for tracking the verification request.
    }

    // --- Mappings ---
    mapping(uint256 => Model) public models;           // Maps model ID to Model struct.
    mapping(uint256 => Dataset) public datasets;       // Maps dataset ID to Dataset struct.
    mapping(uint256 => TrainingTask) public trainingTasks; // Maps training task ID to TrainingTask struct.

    mapping(uint256 => uint256) public modelEarnings; // Accumulated earnings for each model owner.
    uint256 public platformFees;                      // Accumulated fees for the platform admin.

    // Tracks inference access: user => modelId => accessEndTime (timestamp)
    mapping(address => mapping(uint256 => uint256)) public modelInferenceAccessExpiry;
    // Tracks inference credits: user => modelId => remainingCredits
    mapping(address => mapping(uint256 => uint256)) public modelInferenceCredits;


    // --- Events ---
    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, string ipfsHash, uint256 inferencePrice);
    event ModelUpdated(uint256 indexed modelId, address indexed owner, string newIpfsHash, uint256 newVersion);
    event ModelOwnershipTransferred(uint256 indexed modelId, address indexed oldOwner, address indexed newOwner);
    event ModelInferencePriceSet(uint256 indexed modelId, uint256 newPrice);
    event ModelPublicStatusToggled(uint256 indexed modelId, bool isPublic);

    event DatasetRegistered(uint256 indexed datasetId, address indexed owner, string name, string ipfsHash);
    event DatasetProposedForModel(uint256 indexed datasetId, uint256 indexed modelId, address indexed proposer);
    event DatasetApprovedForModel(uint256 indexed datasetId, uint256 indexed modelId, address indexed approver);

    event TrainingTaskProposed(uint256 indexed taskId, uint256 indexed modelId, uint256 indexed datasetId, address proposer, uint256 stakeAmount);
    event TrainingTaskAccepted(uint256 indexed taskId, address indexed computeNode);
    event TrainingResultSubmitted(uint256 indexed taskId, address indexed computeNode, string resultIpfsHash);
    event TrainingTaskVerified(uint256 indexed taskId, bool success, string details);
    event TrainingTaskStatusUpdated(uint256 indexed taskId, TrainingTaskStatus newStatus);

    event InferenceAccessGranted(address indexed buyer, uint256 indexed modelId, uint256 duration);
    event InferenceCreditsGranted(address indexed buyer, uint256 indexed modelId, uint256 numCredits);
    event ModelEarningsWithdrawn(uint256 indexed modelId, address indexed owner, uint256 amount);

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, int256 newReputation);

    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _modelId) {
        require(models[_modelId].owner == _msgSender(), "AMH: Not model owner");
        _;
    }

    modifier onlyDatasetOwner(uint256 _datasetId) {
        require(datasets[_datasetId].owner == _msgSender(), "AMH: Not dataset owner");
        _;
    }

    modifier onlyOracle() {
        require(address(oracle) == _msgSender(), "AMH: Only oracle can call");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the AetherMindHub contract.
     * @param _aiToken The address of the ERC-20 token used within the ecosystem.
     * @param _oracleAddress The address of the `IOffchainOracle` contract.
     * @param _adminFeeRecipient The address that will receive platform fees.
     */
    constructor(address _aiToken, address _oracleAddress, address _adminFeeRecipient) Ownable(_msgSender()) {
        require(_aiToken != address(0), "AMH: AI Token address cannot be zero");
        require(_oracleAddress != address(0), "AMH: Oracle address cannot be zero");
        require(_adminFeeRecipient != address(0), "AMH: Admin fee recipient cannot be zero");

        AI_TOKEN = IERC20(_aiToken);
        oracle = IOffchainOracle(_oracleAddress);
        adminFeeRecipient = _adminFeeRecipient;
    }

    // --- I. Core Management & Setup ---

    /**
     * @dev Pauses core contract functionalities. Callable only by the owner.
     *      Prevents most state-changing operations during emergencies.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
        emit Paused(_msgSender());
    }

    /**
     * @dev Unpauses core contract functionalities. Callable only by the owner.
     *      Restores normal operations after an emergency pause.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
        emit Unpaused(_msgSender());
    }

    // --- II. Model Lifecycle Management ---

    /**
     * @dev Registers a new AI model with its initial metadata and inference price.
     * @param _name Name of the model.
     * @param _description Description of the model.
     * @param _ipfsHash IPFS hash pointing to model metadata or initial weights.
     * @param _inferencePrice Initial price for model inference (per unit).
     */
    function registerModel(
        string memory _name,
        string memory _description,
        string memory _ipfsHash,
        uint256 _inferencePrice
    ) public whenNotPaused {
        require(bytes(_name).length > 0, "AMH: Model name cannot be empty");
        require(bytes(_ipfsHash).length > 0, "AMH: Model IPFS hash cannot be empty");
        require(_inferencePrice > 0, "AMH: Inference price must be positive");

        modelIdCounter++;
        models[modelIdCounter] = Model({
            owner: _msgSender(),
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            version: 1, // Initial version
            isPublic: true,
            inferencePricePerUnit: _inferencePrice,
            lastUpdatedBlock: block.number,
            associatedDatasets: new uint256[](0)
        });

        emit ModelRegistered(modelIdCounter, _msgSender(), _name, _ipfsHash, _inferencePrice);
    }

    /**
     * @dev Updates existing model metadata (name, description, IPFS hash).
     *      Only callable by the model owner. Increments the model version.
     * @param _modelId The ID of the model to update.
     * @param _newName New name for the model.
     * @param _newDescription New description for the model.
     * @param _newIpfsHash New IPFS hash for model metadata/weights.
     */
    function updateModelMetadata(
        uint256 _modelId,
        string memory _newName,
        string memory _newDescription,
        string memory _newIpfsHash
    ) public whenNotPaused onlyModelOwner(_modelId) {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");
        require(bytes(_newName).length > 0, "AMH: Model name cannot be empty");
        require(bytes(_newIpfsHash).length > 0, "AMH: Model IPFS hash cannot be empty");

        Model storage model = models[_modelId];
        model.name = _newName;
        model.description = _newDescription;
        model.ipfsHash = _newIpfsHash;
        model.version++;
        model.lastUpdatedBlock = block.number;

        emit ModelUpdated(_modelId, _msgSender(), _newIpfsHash, model.version);
    }

    /**
     * @dev Transfers ownership of a model to a new address.
     *      Only callable by the current model owner.
     * @param _modelId The ID of the model to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferModelOwnership(uint256 _modelId, address _newOwner) public whenNotPaused onlyModelOwner(_modelId) {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");
        require(_newOwner != address(0), "AMH: New owner cannot be zero address");
        require(_newOwner != models[_modelId].owner, "AMH: New owner is already the current owner");

        address oldOwner = models[_modelId].owner;
        models[_modelId].owner = _newOwner;

        emit ModelOwnershipTransferred(_modelId, oldOwner, _newOwner);
    }

    /**
     * @dev Sets the inference price for a model.
     *      Only callable by the model owner.
     * @param _modelId The ID of the model.
     * @param _price The new inference price (per unit of inference/access).
     */
    function setModelInferencePrice(uint256 _modelId, uint256 _price) public whenNotPaused onlyModelOwner(_modelId) {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");
        require(_price > 0, "AMH: Inference price must be positive");

        models[_modelId].inferencePricePerUnit = _price;

        emit ModelInferencePriceSet(_modelId, _price);
    }

    /**
     * @dev Toggles the public status of a model.
     *      If public, it can be listed and used for inference by other users.
     *      Only callable by the model owner.
     * @param _modelId The ID of the model.
     * @param _isPublic New public status (true for public, false for private).
     */
    function toggleModelPublicStatus(uint256 _modelId, bool _isPublic) public whenNotPaused onlyModelOwner(_modelId) {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");

        models[_modelId].isPublic = _isPublic;

        emit ModelPublicStatusToggled(_modelId, _isPublic);
    }

    // --- III. Dataset Management ---

    /**
     * @dev Registers a new dataset.
     * @param _name Name of the dataset.
     * @param _description Description of the dataset.
     * @param _ipfsHash IPFS hash pointing to dataset content.
     * @param _validationHash Hash or metadata for off-chain dataset validation.
     */
    function registerDataset(
        string memory _name,
        string memory _description,
        string memory _ipfsHash,
        string memory _validationHash
    ) public whenNotPaused {
        require(bytes(_name).length > 0, "AMH: Dataset name cannot be empty");
        require(bytes(_ipfsHash).length > 0, "AMH: Dataset IPFS hash cannot be empty");
        require(bytes(_validationHash).length > 0, "AMH: Dataset validation hash cannot be empty");

        datasetIdCounter++;
        datasets[datasetIdCounter] = Dataset({
            owner: _msgSender(),
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            validationHash: _validationHash,
            associatedModels: new uint256[](0)
        });

        emit DatasetRegistered(datasetIdCounter, _msgSender(), _name, _ipfsHash);
    }

    /**
     * @dev Proposes a dataset to be associated with a specific model for training.
     *      Only callable by the dataset owner. The model owner must then approve.
     * @param _datasetId The ID of the dataset to propose.
     * @param _modelId The ID of the model to associate with.
     */
    function proposeDatasetForModel(uint256 _datasetId, uint256 _modelId) public whenNotPaused onlyDatasetOwner(_datasetId) {
        require(_datasetId > 0 && _datasetId <= datasetIdCounter, "AMH: Invalid dataset ID");
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");

        // Check if dataset is already associated with this model
        Model storage model = models[_modelId];
        for (uint256 i = 0; i < model.associatedDatasets.length; i++) {
            if (model.associatedDatasets[i] == _datasetId) {
                revert("AMH: Dataset already associated with this model");
            }
        }
        // No direct `associatedModels.push` here; it's added upon approval.

        emit DatasetProposedForModel(_datasetId, _modelId, _msgSender());
    }

    /**
     * @dev Approves a proposed dataset to be used for training a specific model.
     *      Only callable by the model owner. This establishes the official association.
     * @param _modelId The ID of the model.
     * @param _datasetId The ID of the dataset to approve.
     */
    function approveDatasetAssociation(uint256 _modelId, uint256 _datasetId) public whenNotPaused onlyModelOwner(_modelId) {
        require(_datasetId > 0 && _datasetId <= datasetIdCounter, "AMH: Invalid dataset ID");
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");

        Model storage model = models[_modelId];
        Dataset storage dataset = datasets[_datasetId];

        // Ensure dataset is not already associated
        bool alreadyAssociated = false;
        for (uint256 i = 0; i < model.associatedDatasets.length; i++) {
            if (model.associatedDatasets[i] == _datasetId) {
                alreadyAssociated = true;
                break;
            }
        }
        require(!alreadyAssociated, "AMH: Dataset already approved for this model");

        // Add to associated lists bidirectionally
        model.associatedDatasets.push(_datasetId);
        dataset.associatedModels.push(_modelId);

        emit DatasetApprovedForModel(_datasetId, _modelId, _msgSender());
    }

    // --- IV. Collaborative Training & Verification ---

    /**
     * @dev Proposes a training task for a specific model and an approved dataset.
     *      Requires the proposer to stake AI_TOKENs as commitment.
     * @param _modelId The ID of the model to be trained.
     * @param _datasetId The ID of the dataset to use for training.
     * @param _stakeAmount The amount of AI_TOKENs to stake for this task.
     */
    function proposeTrainingTask(uint256 _modelId, uint256 _datasetId, uint256 _stakeAmount) public whenNotPaused {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");
        require(_datasetId > 0 && _datasetId <= datasetIdCounter, "AMH: Invalid dataset ID");
        require(_stakeAmount >= MIN_STAKE_AMOUNT, "AMH: Stake amount too low");
        require(totalStaked[_msgSender()] >= _stakeAmount, "AMH: Insufficient staked tokens");

        Model storage model = models[_modelId];
        Dataset storage dataset = datasets[_datasetId];

        // Check if dataset is approved for this model
        bool isApproved = false;
        for (uint256 i = 0; i < model.associatedDatasets.length; i++) {
            if (model.associatedDatasets[i] == _datasetId) {
                isApproved = true;
                break;
            }
        }
        require(isApproved, "AMH: Dataset not approved for this model");

        // Tokens are conceptually "allocated" from totalStaked, but not physically moved for simplicity.
        // A more complex system would `totalStaked[_msgSender()] = totalStaked[_msgSender()].sub(_stakeAmount);`
        // and move `_stakeAmount` to a task-specific escrow within the contract.

        trainingTaskIdCounter++;
        trainingTasks[trainingTaskIdCounter] = TrainingTask({
            modelId: _modelId,
            datasetId: _datasetId,
            proposer: _msgSender(),
            computeNode: address(0), // No compute node yet
            stakeAmount: _stakeAmount,
            status: TrainingTaskStatus.Proposed,
            resultIpfsHash: "",
            proposedBlock: block.number,
            verificationRequestId: bytes32(0)
        });

        emit TrainingTaskProposed(trainingTaskIdCounter, _modelId, _datasetId, _msgSender(), _stakeAmount);
    }

    /**
     * @dev Allows a compute node to accept a proposed training task.
     *      Requires the compute node to have a minimum stake.
     * @param _taskId The ID of the training task to accept.
     */
    function acceptTrainingTask(uint256 _taskId) public whenNotPaused {
        require(_taskId > 0 && _taskId <= trainingTaskIdCounter, "AMH: Invalid training task ID");
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TrainingTaskStatus.Proposed, "AMH: Task is not in Proposed status");
        require(task.proposer != _msgSender(), "AMH: Proposer cannot be the compute node");
        require(totalStaked[_msgSender()] >= MIN_STAKE_AMOUNT, "AMH: Compute node must have minimum stake");
        // Additional checks could include reputation score: `require(reputation[_msgSender()] >= MIN_REPUTATION, "AMH: Insufficient reputation");`

        task.computeNode = _msgSender();
        task.status = TrainingTaskStatus.InProgress;

        emit TrainingTaskAccepted(_taskId, _msgSender());
        emit TrainingTaskStatusUpdated(_taskId, TrainingTaskStatus.InProgress);
    }

    /**
     * @dev Allows the assigned compute node to submit the training result (e.g., updated model weights IPFS hash).
     *      This action triggers an off-chain oracle verification request.
     * @param _taskId The ID of the training task.
     * @param _resultIpfsHash IPFS hash pointing to the updated model weights or training log.
     */
    function submitTrainingResult(uint256 _taskId, string memory _resultIpfsHash) public whenNotPaused {
        require(_taskId > 0 && _taskId <= trainingTaskIdCounter, "AMH: Invalid training task ID");
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TrainingTaskStatus.InProgress, "AMH: Task is not In Progress");
        require(task.computeNode == _msgSender(), "AMH: Only assigned compute node can submit result");
        require(bytes(_resultIpfsHash).length > 0, "AMH: Result IPFS hash cannot be empty");

        task.resultIpfsHash = _resultIpfsHash;
        task.status = TrainingTaskStatus.Submitted;

        // Trigger oracle verification via the IOffchainOracle interface
        string memory modelIpfsHash = models[task.modelId].ipfsHash;
        string memory datasetIpfsHash = datasets[task.datasetId].ipfsHash;
        bytes4 callbackSelector = this.fulfillOracleVerification.selector; // Selector for the callback function

        bytes32 requestId = oracle.requestVerification(
            _taskId,
            modelIpfsHash,
            datasetIpfsHash,
            _resultIpfsHash,
            address(this),
            callbackSelector
        );
        task.verificationRequestId = requestId;

        emit TrainingResultSubmitted(_taskId, _msgSender(), _resultIpfsHash);
        emit TrainingTaskStatusUpdated(_taskId, TrainingTaskStatus.Submitted);
    }

    /**
     * @dev Callback function for the off-chain oracle to report verification results.
     *      This function is called by the `oracleAddress` after completing its off-chain verification.
     *      It handles reward distribution, slashing, and reputation updates based on the verification outcome.
     * @param _taskId The ID of the training task.
     * @param _isSuccess True if verification passed, false otherwise.
     * @param _verificationDetails Details from the oracle (e.g., error messages).
     */
    function fulfillOracleVerification(uint256 _taskId, bool _isSuccess, string memory _verificationDetails) public onlyOracle {
        require(_taskId > 0 && _taskId <= trainingTaskIdCounter, "AMH: Invalid training task ID");
        TrainingTask storage task = trainingTasks[_taskId];
        require(task.status == TrainingTaskStatus.Submitted, "AMH: Task is not in Submitted status");

        address proposer = task.proposer;
        address computeNode = task.computeNode;
        uint256 stakeAmount = task.stakeAmount;

        if (_isSuccess) {
            task.status = TrainingTaskStatus.VerifiedSuccess;
            // Update the model to its new, trained version
            models[task.modelId].ipfsHash = task.resultIpfsHash;
            models[task.modelId].version++;

            // Reward distribution and reputation increase
            // Proposer's stake is conceptually returned/released.
            // Compute node receives a reward (e.g., 50% of the stake as a bounty)
            uint256 computeNodeReward = stakeAmount.div(2); // Example reward logic

            // Transfer reward to compute node from general contract funds
            // In a full system, `stakeAmount` for the proposer would be released from lock,
            // and `computeNodeReward` would be paid from a platform incentive pool or a portion of proposer's stake.
            // For this example, let's assume `stakeAmount` is a "risk" factor and `computeNodeReward` is new token generation
            // or paid from a general contract fund that holds fees.
            // For now, only reputation is updated.
            // A realistic implementation would involve `AI_TOKEN.transfer(computeNode, computeNodeReward);`

            reputation[proposer] = reputation[proposer].add(10); // Proposer gets reputation for successful task
            reputation[computeNode] = reputation[computeNode].add(20); // Compute node gets more for execution

            emit TrainingTaskVerified(_taskId, true, _verificationDetails);
            emit ReputationUpdated(proposer, reputation[proposer]);
            emit ReputationUpdated(computeNode, reputation[computeNode]);

        } else {
            task.status = TrainingTaskStatus.VerifiedFailed;
            // Slashing and reputation decrease
            // In a full system, the party responsible for failure (e.g., compute node for bad training,
            // or proposer for bad data) would have their stake slashed.
            // For simplicity, let's say the compute node's reputation is penalized.
            
            reputation[computeNode] = reputation[computeNode].sub(15);
            // Ensure reputation doesn't go below a certain threshold (or zero)
            if (reputation[computeNode] < -100) reputation[computeNode] = -100; // Example floor

            emit TrainingTaskVerified(_taskId, false, _verificationDetails);
            emit ReputationUpdated(computeNode, reputation[computeNode]);
        }
        emit TrainingTaskStatusUpdated(_taskId, task.status);
    }

    // --- V. Marketplace & Inference ---

    /**
     * @dev Allows a user to purchase time-based access to use a specific AI model for inference.
     *      Payment is made in AI_TOKENs. Access duration is rounded to predefined granularity.
     * @param _modelId The ID of the model to buy access for.
     * @param _durationInSeconds The desired duration of access in seconds.
     */
    function buyModelInferenceAccess(uint256 _modelId, uint256 _durationInSeconds) public whenNotPaused {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");
        Model storage model = models[_modelId];
        require(model.isPublic, "AMH: Model is not public for inference");
        require(model.inferencePricePerUnit > 0, "AMH: Model has no inference price set");
        require(_durationInSeconds > 0, "AMH: Duration must be positive");

        // Calculate cost based on duration units, rounded up.
        uint256 durationUnits = (_durationInSeconds + INFERENCE_ACCESS_GRANULARITY_SECONDS - 1) / INFERENCE_ACCESS_GRANULARITY_SECONDS;
        uint256 totalCost = model.inferencePricePerUnit.mul(durationUnits);

        // Transfer tokens from buyer to contract.
        require(AI_TOKEN.transferFrom(_msgSender(), address(this), totalCost), "AMH: Token transfer failed");

        // Distribute fees: platform fee and model owner's share.
        uint256 platformFee = totalCost.mul(PLATFORM_FEE_PERCENT).div(100);
        uint256 modelOwnerShare = totalCost.sub(platformFee);

        platformFees = platformFees.add(platformFee);
        modelEarnings[model.owner] = modelEarnings[model.owner].add(modelOwnerShare);

        // Update user's access expiry for this model.
        uint256 currentExpiry = modelInferenceAccessExpiry[_msgSender()][_modelId];
        uint256 newAccessStart = block.timestamp;
        if (currentExpiry > block.timestamp) { // If user already has active access, extend it from current expiry.
            newAccessStart = currentExpiry;
        }
        modelInferenceAccessExpiry[_msgSender()][_modelId] = newAccessStart.add(_durationInSeconds);

        emit InferenceAccessGranted(_msgSender(), _modelId, _durationInSeconds);
    }

    /**
     * @dev Allows a user to pay for a specific number of inferences (credits) for a model.
     *      This is an alternative or complementary method to time-based access.
     * @param _modelId The ID of the model to buy credits for.
     * @param _numInferences The number of inference credits to buy.
     */
    function payForModelInference(uint256 _modelId, uint256 _numInferences) public whenNotPaused {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");
        Model storage model = models[_modelId];
        require(model.isPublic, "AMH: Model is not public for inference");
        require(model.inferencePricePerUnit > 0, "AMH: Model has no inference price set");
        require(_numInferences > 0, "AMH: Number of inferences must be positive");

        uint256 totalCost = model.inferencePricePerUnit.mul(_numInferences);

        // Transfer tokens from buyer to contract.
        require(AI_TOKEN.transferFrom(_msgSender(), address(this), totalCost), "AMH: Token transfer failed");

        // Distribute fees.
        uint256 platformFee = totalCost.mul(PLATFORM_FEE_PERCENT).div(100);
        uint256 modelOwnerShare = totalCost.sub(platformFee);

        platformFees = platformFees.add(platformFee);
        modelEarnings[model.owner] = modelEarnings[model.owner].add(modelOwnerShare);

        // Add inference credits to the user's balance for this model.
        modelInferenceCredits[_msgSender()][_modelId] = modelInferenceCredits[_msgSender()][_modelId].add(_numInferences);

        emit InferenceCreditsGranted(_msgSender(), _modelId, _numInferences);
    }

    /**
     * @dev Allows the model owner to withdraw their accumulated earnings from model inference usage.
     *      Only callable by the model owner.
     * @param _modelId The ID of the model whose earnings are to be withdrawn.
     */
    function withdrawModelEarnings(uint256 _modelId) public whenNotPaused onlyModelOwner(_modelId) {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");

        uint256 amount = modelEarnings[_modelId];
        require(amount > 0, "AMH: No earnings to withdraw");

        modelEarnings[_modelId] = 0; // Reset earnings *before* transfer to prevent reentrancy issues.
        require(AI_TOKEN.transfer(_msgSender(), amount), "AMH: Token withdrawal failed");

        emit ModelEarningsWithdrawn(_modelId, _msgSender(), amount);
    }

    // --- VI. Staking & Reputation ---

    /**
     * @dev Allows users to stake AI_TOKENs into the platform.
     *      Staked tokens are required for participation in certain roles (e.g., proposing/accepting training tasks).
     * @param _amount The amount of AI_TOKENs to stake.
     */
    function stake(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AMH: Stake amount must be positive");
        // Transfer tokens from user to contract.
        require(AI_TOKEN.transferFrom(_msgSender(), address(this), _amount), "AMH: Staking token transfer failed");
        totalStaked[_msgSender()] = totalStaked[_msgSender()].add(_amount);

        emit Staked(_msgSender(), _amount);
    }

    /**
     * @dev Allows users to unstake their AI_TOKENs.
     *      Note: In a more complex system, this would typically involve cooldown periods,
     *      or checks for active tasks/challenges that lock the stake.
     *      For this simplified version, it assumes no locks.
     * @param _amount The amount of AI_TOKENs to unstake.
     */
    function unstake(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "AMH: Unstake amount must be positive");
        require(totalStaked[_msgSender()] >= _amount, "AMH: Insufficient staked tokens to unstake");

        // In a more robust system, a user's staked balance might be locked if they have
        // active training tasks or pending oracle verifications. This simple version
        // does not implement such locking mechanisms.

        totalStaked[_msgSender()] = totalStaked[_msgSender()].sub(_amount);
        // Transfer tokens from contract back to user.
        require(AI_TOKEN.transfer(_msgSender(), _amount), "AMH: Unstaking token transfer failed");

        emit Unstaked(_msgSender(), _amount);
    }

    /**
     * @dev Placeholder function for claiming reputation rewards.
     *      In the current implementation, reputation is updated internally and serves as
     *      a metric. This function is reserved for future extensions, such as enabling
     *      users to claim specific rewards (e.g., exclusive NFTs, token airdrops)
     *      based on their reputation score or tier.
     */
    function claimReputationReward() public pure {
        revert("AMH: Reputation rewards are not yet implemented for claiming.");
    }

    // --- VII. Admin & Utility ---

    /**
     * @dev Allows the contract owner to update the address of the off-chain oracle contract.
     *      This is useful for upgrading the oracle or switching to a new provider.
     * @param _newOracleAddress The new address for the oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "AMH: New oracle address cannot be zero");
        oracle = IOffchainOracle(_newOracleAddress);
    }

    /**
     * @dev Allows the contract owner to change the address designated to receive platform fees.
     * @param _newRecipient The new address for the admin fee recipient.
     */
    function setAdminFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "AMH: New recipient cannot be zero address");
        adminFeeRecipient = _newRecipient;
    }

    /**
     * @dev Allows the `adminFeeRecipient` to withdraw the collected platform fees.
     */
    function withdrawPlatformFees() public whenNotPaused {
        require(_msgSender() == adminFeeRecipient, "AMH: Only admin fee recipient can withdraw");
        uint256 amount = platformFees;
        require(amount > 0, "AMH: No platform fees to withdraw");

        platformFees = 0; // Reset fees before transfer.
        require(AI_TOKEN.transfer(adminFeeRecipient, amount), "AMH: Platform fee withdrawal failed");

        emit PlatformFeesWithdrawn(adminFeeRecipient, amount);
    }

    /**
     * @dev Retrieves all stored details for a specific AI model.
     * @param _modelId The ID of the model.
     * @return Model struct containing all model details.
     */
    function getModelDetails(uint256 _modelId) public view returns (Model memory) {
        require(_modelId > 0 && _modelId <= modelIdCounter, "AMH: Invalid model ID");
        return models[_modelId];
    }

    /**
     * @dev Retrieves all stored details for a specific training task.
     * @param _taskId The ID of the training task.
     * @return TrainingTask struct containing all task details.
     */
    function getTrainingTaskDetails(uint256 _taskId) public view returns (TrainingTask memory) {
        require(_taskId > 0 && _taskId <= trainingTaskIdCounter, "AMH: Invalid training task ID");
        return trainingTasks[_taskId];
    }

    /**
     * @dev Queries the current reputation score of a given user address.
     * @param _user The address of the user.
     * @return The reputation score (int256) of the user.
     */
    function getReputation(address _user) public view returns (int256) {
        return reputation[_user];
    }

    /**
     * @dev Returns the timestamp when a user's model inference access expires for a given model.
     * @param _user The address of the user.
     * @param _modelId The ID of the model.
     * @return The expiry timestamp.
     */
    function getModelInferenceAccessExpiry(address _user, uint256 _modelId) public view returns (uint256) {
        return modelInferenceAccessExpiry[_user][_modelId];
    }

    /**
     * @dev Returns the remaining inference credits a user has for a given model.
     * @param _user The address of the user.
     * @param _modelId The ID of the model.
     * @return The number of remaining inference credits.
     */
    function getModelInferenceCredits(address _user, uint256 _modelId) public view returns (uint256) {
        return modelInferenceCredits[_user][_modelId];
    }
}
```