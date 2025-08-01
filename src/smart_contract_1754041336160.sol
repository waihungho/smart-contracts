Here's a Solidity smart contract for "CognitoNet: Decentralized AI Collaborative Training & Model Marketplace". It features a robust set of functions covering advanced concepts like verifiable computation (simulated), reputation systems, and DAO governance for an AI ecosystem.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Custom Errors ---
error UnauthorizedAccess();
error ModelNotFound();
error DatasetNotFound();
error TrainingJobNotFound();
error TrainingJobNotReady();
error TrainingJobAlreadyCompleted();
error AlreadyStaked();
error InsufficientStake();
error NotOwner();
error InvalidAmount();
error InvalidStatus();
error NoEarningsToWithdraw();
error AlreadyParticipated();
error ModelNotRetirable();
error DatasetNotRetirable();
error ProofNotSubmitted();
error DisputeAlreadyActive();
error DisputeNotActive();
error ProposalNotFound();
error ProposalAlreadyExecuted();
error ProposalNotPassed();
error ProposalTimelockNotExpired();
error InsufficientReputation();
error SelfDelegationForbidden();
error TrainerMismatch();


// --- Placeholder for the CognitoNet Token (CGNT) ---
// In a real scenario, this would be a separate, pre-deployed contract.
// For this example, it's included for a self-contained demonstration.
contract CognitoNetToken is ERC20, Ownable {
    constructor() ERC20("CognitoNet Token", "CGNT") Ownable(msg.sender) {
        // Mint an initial supply to the deployer for testing
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
    }

    // Function to mint new tokens, callable only by the owner (for initial distribution or specific needs)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

/**
 * @title CognitoNet: Decentralized AI Collaborative Training & Model Marketplace
 * @dev This contract orchestrates a decentralized ecosystem for AI model training and a trustless marketplace for AI models and datasets.
 * It facilitates collaboration between data providers, model developers, and computational resource providers (trainers),
 * rewarding contributions and governing the platform through a reputation-based DAO.
 */
contract CognitoNet is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // CGNT Token instance
    IERC20 public cgntToken;

    // Global platform parameters (DAO governable)
    struct GlobalParams {
        uint256 minModelStake;         // Min CGNT required to register a model
        uint256 minTrainerStake;       // Min CGNT required to stake for a training job
        uint256 platformFeeNumerator;  // Platform fee (e.g., 50 for 5%)
        uint256 platformFeeDenominator; // Denominator for fee calculation (always 1000 for 0.1% increments)
        uint256 disputeStake;          // CGNT required to initiate a dispute
        uint256 minReputationForProposal; // Min reputation to create a governance proposal
        uint256 proposalTimelock;      // Time (in seconds) after proposal passes before execution
        uint256 proposalVoteDuration;  // Time (in seconds) for voting on a proposal
    }
    GlobalParams public globalParams;

    // Counters for unique IDs
    Counters.Counter private _modelIds;
    Counters.Counter private _datasetIds;
    Counters.Counter private _trainingJobIds;
    Counters.Counter private _proposalIds;

    // --- Data Structures ---

    enum ModelStatus { Active, Retired }
    struct Model {
        uint256 id;
        address owner;
        string name;
        string description;
        string cid;             // Content ID (e.g., IPFS hash) for model weights/metadata
        bytes32 currentModelHash; // Hash of the current model state (e.g., committed on-chain)
        uint256 accessPrice;    // Price in CGNT to gain access (e.g., for inference API key)
        ModelStatus status;
        uint256 createdAt;
        uint256 lastUpdated;
    }
    mapping(uint256 => Model) public models;
    mapping(address => uint256[]) public userModels; // Models owned by an address

    enum DatasetStatus { Active, Retired }
    struct Dataset {
        uint256 id;
        address owner;
        string name;
        string description;
        string cid;              // Content ID (e.g., IPFS hash) for dataset
        bytes32 datasetHash;     // Hash of the dataset (for integrity verification)
        uint256 rewardPerUse;    // CGNT reward per use in a training job
        DatasetStatus status;
        uint256 createdAt;
    }
    mapping(uint256 => Dataset) public datasets;
    mapping(address => uint256[]) public userDatasets; // Datasets owned by an address

    enum TrainingJobStatus { Proposed, Staked, ProofSubmitted, Completed, Disputed, Resolved }
    struct TrainingJob {
        uint256 id;
        uint256 modelId;
        address modelOwner;
        uint256[] requiredDatasetIds;
        uint256 rewardPool;         // Total CGNT rewards for this job (trainers + data providers)
        uint256 expectedProofDifficulty; // Conceptual difficulty for off-chain proof verification
        address trainer;            // The address that successfully submitted proof
        bytes32 proofHash;          // Hash of the verifiable computation proof
        bytes32 newModelHash;       // Hash of the resulting model after training
        uint256 submissionTime;     // Timestamp when proof was submitted
        uint256 computationTime;    // Reported computation time by trainer
        TrainingJobStatus status;
        address disputer;           // Address that initiated a dispute
        string disputeReason;       // Reason for dispute
        uint256 createdAt;
        bool hasDisputeBeenResolved; // To ensure dispute resolution is final
    }
    mapping(uint256 => TrainingJob) public trainingJobs;
    mapping(address => uint256[]) public userTrainingJobs; // Jobs where user is the trainer or proposer

    // --- Reputation System ---
    mapping(address => int256) public reputationScores; // Arbitrary score, can be positive/negative
    mapping(address => uint256) public totalStakedBalance; // Total CGNT staked by user across all purposes
    mapping(address => uint256) public userEarnings; // Accumulating rewards for users

    // --- Governance System ---
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        uint256 id;
        string description;         // Description of the proposal
        bytes callData;             // Calldata for the target function
        address targetContract;     // Address of the contract to call
        address proposer;
        uint256 startBlock;         // Block at which voting begins
        uint256 endBlock;           // Block at which voting ends
        uint256 forVotes;           // Votes in favor
        uint256 againstVotes;       // Votes against
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalStatus status;
        uint256 executionTimestamp; // Timestamp when proposal can be executed if successful
    }
    mapping(uint256 => GovernanceProposal) public proposals;

    // Reputation delegation
    mapping(address => address) public delegatedReputation; // address => delegatee

    // --- Events ---
    event GlobalParametersSet(uint256 minModelStake, uint256 minTrainerStake, uint256 platformFeeNumerator);
    event TreasuryFunded(address indexed sender, uint256 amount);

    event ModelRegistered(uint256 indexed modelId, address indexed owner, string name, uint256 accessPrice);
    event ModelMetadataUpdated(uint256 indexed modelId, string newName, string newCid);
    event ModelAccessPurchased(uint256 indexed modelId, address indexed buyer, uint256 pricePaid);
    event ModelRetired(uint256 indexed modelId, address indexed owner);
    event ModelAccessPriceUpdated(uint256 indexed modelId, uint256 newPrice);

    event DatasetRegistered(uint256 indexed datasetId, address indexed owner, string name, uint256 rewardPerUse);
    event DatasetAccessRequested(uint256 indexed datasetId, address indexed trainer, uint256 indexed jobId);
    event DatasetAccessGranted(uint256 indexed datasetId, address indexed trainer, uint256 indexed jobId);
    event DatasetAccessRevoked(uint256 indexed datasetId, address indexed trainer, uint256 indexed jobId);

    event TrainingJobProposed(uint256 indexed jobId, uint256 indexed modelId, address indexed modelOwner, uint256 rewardPool);
    event TrainerStaked(uint256 indexed jobId, address indexed trainer, uint256 amount);
    event TrainingProofSubmitted(uint256 indexed jobId, address indexed trainer, bytes32 proofHash, bytes32 newModelHash);
    event RewardsDistributed(uint256 indexed jobId, address indexed trainer, uint256 trainerReward, uint256 dataProviderRewards);
    event TrainingResultDisputed(uint256 indexed jobId, address indexed disputer, address indexed disputee, string reason);
    event DisputeResolved(uint256 indexed jobId, address indexed disputer, address indexed disputee, bool isValidDispute);

    event ReputationScoreUpdated(address indexed user, int256 delta, int256 newScore);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalStatus newStatus);

    event EarningsWithdrawn(address indexed user, uint256 amount);

    // --- Modifiers ---
    modifier onlyDAO() {
        // In a real DAO, this would be `onlyRole(DAO_ROLE)` or similar,
        // tied to a governance contract. For this example, Ownable acts as the DAO.
        if (msg.sender != owner()) revert UnauthorizedAccess();
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        if (models[_modelId].owner != msg.sender) revert NotOwner();
        _;
    }

    modifier onlyDatasetOwner(uint256 _datasetId) {
        if (datasets[_datasetId].owner != msg.sender) revert NotOwner();
        _;
    }

    modifier onlyTrainer(uint256 _jobId) {
        if (trainingJobs[_jobId].trainer != msg.sender) revert TrainerMismatch();
        _;
    }

    // --- Constructor ---
    constructor(address _cgntTokenAddress) Ownable(msg.sender) {
        cgntToken = IERC20(_cgntTokenAddress);

        // Set initial global parameters (can be changed by DAO later)
        globalParams = GlobalParams({
            minModelStake: 100 * 10 ** 18,        // 100 CGNT
            minTrainerStake: 50 * 10 ** 18,       // 50 CGNT
            platformFeeNumerator: 50,             // 5% (50 / 1000)
            platformFeeDenominator: 1000,
            disputeStake: 200 * 10 ** 18,         // 200 CGNT
            minReputationForProposal: 100,        // Min reputation score to propose
            proposalTimelock: 2 days,             // 2 days timelock
            proposalVoteDuration: 7 days          // 7 days for voting
        });

        // The deployer of CognitoNet is initially considered the DAO governor and has reputation
        reputationScores[msg.sender] = 1000;
        emit ReputationScoreUpdated(msg.sender, 1000, 1000);
    }

    // --- I. Core & Initialization ---

    /**
     * @dev Allows the DAO to set key platform parameters.
     * @param _minModelStake Minimum CGNT required to register a model.
     * @param _minTrainerStake Minimum CGNT required to stake for a training job.
     * @param _platformFeeNumerator Numerator for platform fee calculation (e.g., 50 for 5%).
     * @param _disputeStake CGNT required to initiate a dispute.
     * @param _minReputationForProposal Minimum reputation to create a governance proposal.
     * @param _proposalTimelock Time (in seconds) after proposal passes before execution.
     * @param _proposalVoteDuration Time (in seconds) for voting on a proposal.
     */
    function setGlobalParameters(
        uint256 _minModelStake,
        uint256 _minTrainerStake,
        uint256 _platformFeeNumerator,
        uint256 _disputeStake,
        uint256 _minReputationForProposal,
        uint256 _proposalTimelock,
        uint256 _proposalVoteDuration
    ) external onlyDAO {
        require(_platformFeeNumerator <= globalParams.platformFeeDenominator, "Fee too high");
        require(_minModelStake > 0 && _minTrainerStake > 0 && _disputeStake > 0, "Stakes must be positive");
        require(_minReputationForProposal >= 0, "Min reputation cannot be negative");

        globalParams.minModelStake = _minModelStake;
        globalParams.minTrainerStake = _minTrainerStake;
        globalParams.platformFeeNumerator = _platformFeeNumerator;
        globalParams.disputeStake = _disputeStake;
        globalParams.minReputationForProposal = _minReputationForProposal;
        globalParams.proposalTimelock = _proposalTimelock;
        globalParams.proposalVoteDuration = _proposalVoteDuration;

        emit GlobalParametersSet(_minModelStake, _minTrainerStake, _platformFeeNumerator);
    }

    /**
     * @dev Allows anyone to fund the contract's treasury with CGNT tokens.
     * Tokens are transferred from the caller to the contract.
     * Can be used for ecosystem growth, future rewards, etc.
     * @param _amount The amount of CGNT to deposit.
     */
    function fundTreasury(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be positive");
        if (!cgntToken.transferFrom(msg.sender, address(this), _amount)) {
            revert InvalidAmount(); // More specific error than "transfer failed"
        }
        emit TreasuryFunded(msg.sender, _amount);
    }

    // --- II. AI Model Management ---

    /**
     * @dev Registers a new AI model on the marketplace. Requires staking CGNT.
     * @param _name Name of the AI model.
     * @param _description Description of the AI model.
     * @param _cid IPFS CID or similar for model metadata/weights.
     * @param _accessPrice Price in CGNT to gain access (e.g., for inference API key).
     * @param _modelHash Hash of the initial model weights/state.
     */
    function registerModel(
        string calldata _name,
        string calldata _description,
        string calldata _cid,
        uint256 _accessPrice,
        bytes32 _modelHash
    ) external nonReentrant {
        require(bytes(_name).length > 0 && bytes(_cid).length > 0, "Name and CID cannot be empty");
        require(_accessPrice >= 0, "Access price cannot be negative"); // Can be 0 for free models

        // Require staking CGNT
        if (!cgntToken.transferFrom(msg.sender, address(this), globalParams.minModelStake)) {
            revert InsufficientStake();
        }
        totalStakedBalance[msg.sender] += globalParams.minModelStake;

        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        models[newModelId] = Model({
            id: newModelId,
            owner: msg.sender,
            name: _name,
            description: _description,
            cid: _cid,
            currentModelHash: _modelHash,
            accessPrice: _accessPrice,
            status: ModelStatus.Active,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp
        });
        userModels[msg.sender].push(newModelId);

        emit ModelRegistered(newModelId, msg.sender, _name, _accessPrice);
    }

    /**
     * @dev Allows the model owner to update metadata of their registered model.
     * @param _modelId The ID of the model to update.
     * @param _newName New name for the model (can be empty to keep old).
     * @param _newDescription New description for the model (can be empty to keep old).
     * @param _newCid New CID for model weights/metadata (can be empty to keep old).
     * @param _newModelHash New hash of the model state (can be zero bytes to keep old).
     */
    function updateModelMetadata(
        uint256 _modelId,
        string calldata _newName,
        string calldata _newDescription,
        string calldata _newCid,
        bytes32 _newModelHash
    ) external onlyModelOwner(_modelId) {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Model not active");

        if (bytes(_newName).length > 0) model.name = _newName;
        if (bytes(_newDescription).length > 0) model.description = _newDescription;
        if (bytes(_newCid).length > 0) model.cid = _newCid;
        if (_newModelHash != bytes32(0)) model.currentModelHash = _newModelHash;

        model.lastUpdated = block.timestamp;
        emit ModelMetadataUpdated(_modelId, model.name, model.cid);
    }

    /**
     * @dev Allows a user to purchase access rights to a specific AI model.
     * The `_accessPrice` is transferred to the model owner.
     * @param _modelId The ID of the model to purchase access for.
     */
    function buyModelAccess(uint256 _modelId) external nonReentrant {
        Model storage model = models[_modelId];
        if (model.owner == address(0)) revert ModelNotFound();
        require(model.status == ModelStatus.Active, "Model is not active");
        require(model.accessPrice > 0, "Model is free or has no price set");

        if (!cgntToken.transferFrom(msg.sender, model.owner, model.accessPrice)) {
            revert InvalidAmount();
        }

        emit ModelAccessPurchased(_modelId, msg.sender, model.accessPrice);
    }

    /**
     * @dev Allows the model owner to retire their model from the marketplace.
     * The staked CGNT for model registration is returned.
     * @param _modelId The ID of the model to retire.
     */
    function retireModel(uint256 _modelId) external onlyModelOwner(_modelId) nonReentrant {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Model already retired");

        model.status = ModelStatus.Retired;

        // Return the initial stake to the model owner
        if (!cgntToken.transfer(msg.sender, globalParams.minModelStake)) {
            revert ModelNotRetirable(); // More specific error
        }
        totalStakedBalance[msg.sender] -= globalParams.minModelStake;

        emit ModelRetired(_modelId, msg.sender);
    }

    /**
     * @dev Public view function to get detailed information about a registered AI model.
     * @param _modelId The ID of the model.
     * @return Model struct containing all model details.
     */
    function getModelInfo(uint256 _modelId) public view returns (Model memory) {
        if (models[_modelId].owner == address(0)) revert ModelNotFound();
        return models[_modelId];
    }

    /**
     * @dev Allows the model owner to adjust the access price for their model.
     * @param _modelId The ID of the model.
     * @param _newPrice The new access price in CGNT.
     */
    function setModelAccessPrice(uint256 _modelId, uint256 _newPrice) external onlyModelOwner(_modelId) {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Model not active");
        model.accessPrice = _newPrice;
        emit ModelAccessPriceUpdated(_modelId, _newPrice);
    }

    // --- III. Dataset Management ---

    /**
     * @dev Registers a new dataset on the marketplace.
     * @param _name Name of the dataset.
     * @param _description Description of the dataset.
     * @param _cid IPFS CID or similar for the dataset content.
     * @param _datasetHash Hash of the dataset (for integrity verification).
     * @param _rewardPerUse CGNT reward for each successful use of this dataset in a training job.
     */
    function registerDataset(
        string calldata _name,
        string calldata _description,
        string calldata _cid,
        bytes32 _datasetHash,
        uint256 _rewardPerUse
    ) external {
        require(bytes(_name).length > 0 && bytes(_cid).length > 0, "Name and CID cannot be empty");
        require(_rewardPerUse >= 0, "Reward per use cannot be negative");

        _datasetIds.increment();
        uint256 newDatasetId = _datasetIds.current();

        datasets[newDatasetId] = Dataset({
            id: newDatasetId,
            owner: msg.sender,
            name: _name,
            description: _description,
            cid: _cid,
            datasetHash: _datasetHash,
            rewardPerUse: _rewardPerUse,
            status: DatasetStatus.Active,
            createdAt: block.timestamp
        });
        userDatasets[msg.sender].push(newDatasetId);

        emit DatasetRegistered(newDatasetId, msg.sender, _name, _rewardPerUse);
    }

    /**
     * @dev Allows a trainer to request access to a dataset for a specific training job.
     * This implies an off-chain negotiation for decryption keys or access protocols.
     * @param _datasetId The ID of the dataset to request access for.
     * @param _trainingJobId The ID of the training job for which access is requested.
     */
    function requestDatasetAccess(uint256 _datasetId, uint256 _trainingJobId) external {
        if (datasets[_datasetId].owner == address(0)) revert DatasetNotFound();
        if (trainingJobs[_trainingJobId].modelOwner == address(0)) revert TrainingJobNotFound();
        require(datasets[_datasetId].status == DatasetStatus.Active, "Dataset not active");
        require(trainingJobs[_trainingJobId].status == TrainingJobStatus.Staked || trainingJobs[_trainingJobId].status == TrainingJobStatus.Proposed, "Training job not in valid state for access request");

        // Logic here to formally record the request if needed, or simply for event logging
        // For simplicity, this function just emits an event. Actual access granting is separate.
        emit DatasetAccessRequested(_datasetId, msg.sender, _trainingJobId);
    }

    /**
     * @dev Allows the dataset owner to grant access to a specific trainer for a training job.
     * This implies the off-chain transfer of necessary data access (e.g., decryption keys).
     * @param _datasetId The ID of the dataset.
     * @param _trainerAddress The address of the trainer to grant access to.
     * @param _trainingJobId The ID of the training job.
     */
    function grantDatasetAccess(uint256 _datasetId, address _trainerAddress, uint256 _trainingJobId) external onlyDatasetOwner(_datasetId) {
        if (datasets[_datasetId].owner == address(0)) revert DatasetNotFound();
        if (trainingJobs[_trainingJobId].modelOwner == address(0)) revert TrainingJobNotFound();
        require(datasets[_datasetId].status == DatasetStatus.Active, "Dataset not active");

        // This function primarily acts as an on-chain record for off-chain access grant.
        emit DatasetAccessGranted(_datasetId, _trainerAddress, _trainingJobId);
    }

    /**
     * @dev Allows the dataset owner to revoke access from a specific trainer for a training job.
     * @param _datasetId The ID of the dataset.
     * @param _trainerAddress The address of the trainer to revoke access from.
     * @param _trainingJobId The ID of the training job.
     */
    function revokeDatasetAccess(uint256 _datasetId, address _trainerAddress, uint256 _trainingJobId) external onlyDatasetOwner(_datasetId) {
        if (datasets[_datasetId].owner == address(0)) revert DatasetNotFound();
        if (trainingJobs[_trainingJobId].modelOwner == address(0)) revert TrainingJobNotFound();
        require(datasets[_datasetId].status == DatasetStatus.Active, "Dataset not active");

        // This function primarily acts as an on-chain record for off-chain access revocation.
        emit DatasetAccessRevoked(_datasetId, _trainerAddress, _trainingJobId);
    }

    /**
     * @dev Public view function to get detailed information about a registered Dataset.
     * @param _datasetId The ID of the dataset.
     * @return Dataset struct containing all dataset details.
     */
    function getDatasetInfo(uint256 _datasetId) public view returns (Dataset memory) {
        if (datasets[_datasetId].owner == address(0)) revert DatasetNotFound();
        return datasets[_datasetId];
    }

    // --- IV. Collaborative Training Coordination ---

    /**
     * @dev Model owner proposes a new training job for their model.
     * They define required datasets and the total reward pool for trainers and data providers.
     * @param _modelId The ID of the model to be trained.
     * @param _requiredDatasetIds An array of dataset IDs required for this training job.
     * @param _rewardPool Total CGNT to be distributed as rewards for this job.
     * @param _expectedProofDifficulty Conceptual difficulty for the verifiable computation proof.
     */
    function proposeTrainingJob(
        uint256 _modelId,
        uint256[] calldata _requiredDatasetIds,
        uint256 _rewardPool,
        uint256 _expectedProofDifficulty
    ) external onlyModelOwner(_modelId) nonReentrant {
        Model storage model = models[_modelId];
        require(model.status == ModelStatus.Active, "Model not active");
        require(_rewardPool > 0, "Reward pool must be positive");
        require(_expectedProofDifficulty > 0, "Proof difficulty must be positive");

        // Ensure all required datasets exist and are active
        for (uint256 i = 0; i < _requiredDatasetIds.length; i++) {
            require(datasets[_requiredDatasetIds[i]].owner != address(0), "Required dataset not found");
            require(datasets[_requiredDatasetIds[i]].status == DatasetStatus.Active, "Required dataset not active");
        }

        // Transfer reward pool funds to the contract
        if (!cgntToken.transferFrom(msg.sender, address(this), _rewardPool)) {
            revert InvalidAmount();
        }

        _trainingJobIds.increment();
        uint256 newJobId = _trainingJobIds.current();

        trainingJobs[newJobId] = TrainingJob({
            id: newJobId,
            modelId: _modelId,
            modelOwner: msg.sender,
            requiredDatasetIds: _requiredDatasetIds,
            rewardPool: _rewardPool,
            expectedProofDifficulty: _expectedProofDifficulty,
            trainer: address(0), // Will be set when trainer stakes
            proofHash: bytes32(0),
            newModelHash: bytes32(0),
            submissionTime: 0,
            computationTime: 0,
            status: TrainingJobStatus.Proposed,
            disputer: address(0),
            disputeReason: "",
            createdAt: block.timestamp,
            hasDisputeBeenResolved: false
        });
        userTrainingJobs[msg.sender].push(newJobId);

        emit TrainingJobProposed(newJobId, _modelId, msg.sender, _rewardPool);
    }

    /**
     * @dev Allows a trainer to stake CGNT to participate in a training job.
     * Only one trainer can stake per job at a time.
     * @param _jobId The ID of the training job to stake for.
     */
    function stakeForTrainingJob(uint256 _jobId) external nonReentrant {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.modelOwner == address(0)) revert TrainingJobNotFound();
        require(job.status == TrainingJobStatus.Proposed, "Job is not in 'Proposed' state");
        require(job.trainer == address(0), "Trainer already staked for this job"); // Only one trainer at a time

        if (!cgntToken.transferFrom(msg.sender, address(this), globalParams.minTrainerStake)) {
            revert InsufficientStake();
        }
        totalStakedBalance[msg.sender] += globalParams.minTrainerStake;

        job.trainer = msg.sender;
        job.status = TrainingJobStatus.Staked;
        userTrainingJobs[msg.sender].push(_jobId); // Trainer now linked to this job

        emit TrainerStaked(_jobId, msg.sender, globalParams.minTrainerStake);
    }

    /**
     * @dev Trainer submits the verifiable proof of computation and the new model hash.
     * This assumes off-chain computation and proof generation (e.g., ZKP, Truebit, Geth-verified WASM).
     * @param _jobId The ID of the training job.
     * @param _proofHash A hash representing the verifiable proof of computation.
     * @param _newModelHash The hash of the resulting trained model.
     * @param _computationTime The reported time taken for computation.
     */
    function submitTrainingProof(
        uint256 _jobId,
        bytes32 _proofHash,
        bytes32 _newModelHash,
        uint256 _computationTime
    ) external nonReentrant {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.modelOwner == address(0)) revert TrainingJobNotFound();
        require(job.status == TrainingJobStatus.Staked, "Job not in 'Staked' state");
        require(job.trainer == msg.sender, "Only the staked trainer can submit proof");
        require(_proofHash != bytes32(0) && _newModelHash != bytes32(0), "Proof and new model hash cannot be empty");

        job.proofHash = _proofHash;
        job.newModelHash = _newModelHash;
        job.computationTime = _computationTime;
        job.submissionTime = block.timestamp;
        job.status = TrainingJobStatus.ProofSubmitted;

        emit TrainingProofSubmitted(_jobId, msg.sender, _proofHash, _newModelHash);
    }

    /**
     * @dev Verifies the submitted proof (conceptually off-chain by an oracle or DAO)
     * and distributes rewards to the trainer and data providers.
     * Updates the model's hash with the new trained version.
     * @param _jobId The ID of the training job.
     */
    function verifyAndDistributeRewards(uint256 _jobId) external onlyDAO nonReentrant {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.modelOwner == address(0)) revert TrainingJobNotFound();
        require(job.status == TrainingJobStatus.ProofSubmitted, "Job not in 'ProofSubmitted' state");
        require(job.proofHash != bytes32(0), "No proof submitted yet");
        require(!job.hasDisputeBeenResolved, "Dispute pending or resolved for this job");

        // CONCEPTUAL: Off-chain proof verification happens here.
        // For a real system, an oracle or a decentralized verification network
        // would attest to the proof's validity via an external call or a separate mechanism.
        // Assuming verification is successful:

        // 1. Calculate rewards
        uint256 totalRewardPool = job.rewardPool;
        uint256 platformFee = (totalRewardPool * globalParams.platformFeeNumerator) / globalParams.platformFeeDenominator;
        uint256 remainingReward = totalRewardPool - platformFee;

        // Determine dataset provider share (e.g., 20% of remaining reward)
        uint256 dataProviderShare = (remainingReward * 200) / 1000; // 20%
        uint256 trainerReward = remainingReward - dataProviderShare;

        // Distribute data provider rewards
        uint256 totalDatasetReward = 0;
        uint256 datasetsUsedCount = job.requiredDatasetIds.length;
        if (datasetsUsedCount > 0) {
            uint256 rewardPerDataset = dataProviderShare / datasetsUsedCount;
            for (uint256 i = 0; i < datasetsUsedCount; i++) {
                Dataset storage dataset = datasets[job.requiredDatasetIds[i]];
                userEarnings[dataset.owner] += rewardPerDataset;
                totalDatasetReward += rewardPerDataset;
                // Add reputation for data providers
                reputationScores[dataset.owner] += 1;
                emit ReputationScoreUpdated(dataset.owner, 1, reputationScores[dataset.owner]);
            }
        }

        // Distribute trainer reward
        userEarnings[job.trainer] += trainerReward;

        // Update trainer's reputation
        reputationScores[job.trainer] += 5; // Higher reputation for successful training
        emit ReputationScoreUpdated(job.trainer, 5, reputationScores[job.trainer]);

        // Return trainer's stake
        if (!cgntToken.transfer(job.trainer, globalParams.minTrainerStake)) {
            revert InvalidAmount(); // Should not happen if stake was transferred in
        }
        totalStakedBalance[job.trainer] -= globalParams.minTrainerStake;

        // Update the model's hash to the new trained version
        models[job.modelId].currentModelHash = job.newModelHash;
        models[job.modelId].lastUpdated = block.timestamp;

        job.status = TrainingJobStatus.Completed;

        emit RewardsDistributed(_jobId, job.trainer, trainerReward, totalDatasetReward);
        emit ModelMetadataUpdated(job.modelId, models[job.modelId].name, models[job.modelId].cid); // Indicate model hash changed
    }

    /**
     * @dev Allows a user to dispute a submitted training result (proof).
     * Requires staking `disputeStake` CGNT, which is lost if the dispute is invalid.
     * @param _jobId The ID of the training job to dispute.
     * @param _reason A string describing the reason for the dispute.
     */
    function disputeTrainingResult(uint256 _jobId, string calldata _reason) external nonReentrant {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.modelOwner == address(0)) revert TrainingJobNotFound();
        require(job.status == TrainingJobStatus.ProofSubmitted, "Job not in 'ProofSubmitted' state to dispute");
        require(job.disputer == address(0), "Dispute already active for this job");
        require(msg.sender != job.trainer, "Trainer cannot dispute their own proof");

        // Require dispute stake
        if (!cgntToken.transferFrom(msg.sender, address(this), globalParams.disputeStake)) {
            revert InsufficientStake();
        }
        totalStakedBalance[msg.sender] += globalParams.disputeStake;

        job.status = TrainingJobStatus.Disputed;
        job.disputer = msg.sender;
        job.disputeReason = _reason;

        emit TrainingResultDisputed(_jobId, msg.sender, job.trainer, _reason);
    }

    /**
     * @dev DAO/Oracle resolves a dispute for a training job.
     * If valid, disputer's stake is returned and trainer is penalized.
     * If invalid, disputer's stake is burned and trainer is rewarded.
     * @param _jobId The ID of the training job with the dispute.
     * @param _isValidDispute True if the dispute is deemed valid, false otherwise.
     */
    function resolveDispute(uint256 _jobId, bool _isValidDispute) external onlyDAO nonReentrant {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.modelOwner == address(0)) revert TrainingJobNotFound();
        require(job.status == TrainingJobStatus.Disputed, "Job is not in 'Disputed' state");
        require(job.disputer != address(0), "No active dispute for this job");
        require(!job.hasDisputeBeenResolved, "Dispute has already been resolved");

        job.hasDisputeBeenResolved = true; // Mark as resolved to prevent re-resolution

        if (_isValidDispute) {
            // Dispute is valid: Trainer was wrong.
            // Return disputer's stake.
            if (!cgntToken.transfer(job.disputer, globalParams.disputeStake)) {
                revert InvalidAmount(); // Should not happen
            }
            totalStakedBalance[job.disputer] -= globalParams.disputeStake;

            // Penalize trainer (e.g., burn their stake or reduce reputation)
            // Burn trainer's stake
            cgntToken.transfer(address(0), globalParams.minTrainerStake); // Burn trainer's stake
            totalStakedBalance[job.trainer] -= globalParams.minTrainerStake;

            reputationScores[job.trainer] -= 10; // Significant reputation loss
            emit ReputationScoreUpdated(job.trainer, -10, reputationScores[job.trainer]);

            // Revert job status to Proposed, or mark as Failed
            job.status = TrainingJobStatus.Proposed; // Allow new trainer to stake
            job.trainer = address(0); // Reset trainer
            job.proofHash = bytes32(0); // Clear submitted proof
            job.newModelHash = bytes32(0);
            job.submissionTime = 0;

        } else {
            // Dispute is invalid: Disputer was wrong.
            // Disputer's stake is burned.
            cgntToken.transfer(address(0), globalParams.disputeStake); // Burn disputer's stake
            totalStakedBalance[job.disputer] -= globalParams.disputeStake;

            reputationScores[job.disputer] -= 5; // Reputation loss for invalid dispute
            emit ReputationScoreUpdated(job.disputer, -5, reputationScores[job.disputer]);

            // If dispute was invalid, proceed with reward distribution as if no dispute occurred
            // This re-enables `verifyAndDistributeRewards`
            job.status = TrainingJobStatus.ProofSubmitted;
        }

        emit DisputeResolved(_jobId, job.disputer, job.trainer, _isValidDispute);

        // Clear dispute data after resolution
        job.disputer = address(0);
        job.disputeReason = "";
    }

    // --- V. Reputation System & DAO Governance ---

    /**
     * @dev Internal function to update a user's reputation score.
     * Callable by DAO or triggered by specific contract logic.
     * @param _user The address whose reputation to update.
     * @param _delta The amount to add or subtract from the reputation score.
     */
    function updateReputationScore(address _user, int256 _delta) external onlyDAO {
        reputationScores[_user] += _delta;
        emit ReputationScoreUpdated(_user, _delta, reputationScores[_user]);
    }

    /**
     * @dev Allows a user to delegate their reputation score to another address for governance voting.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) external {
        require(msg.sender != _delegatee, "Cannot delegate to yourself");
        require(_delegatee != address(0), "Cannot delegate to zero address");

        address currentDelegatee = delegatedReputation[msg.sender];
        if (currentDelegatee != address(0)) {
            // Remove reputation from old delegatee
            reputationScores[currentDelegatee] -= reputationScores[msg.sender];
            emit ReputationScoreUpdated(currentDelegatee, -reputationScores[msg.sender], reputationScores[currentDelegatee]);
        }

        delegatedReputation[msg.sender] = _delegatee;
        // Add reputation to new delegatee
        reputationScores[_delegatee] += reputationScores[msg.sender];
        emit ReputationScoreUpdated(_delegatee, reputationScores[msg.sender], reputationScores[_delegatee]);

        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Submits a new governance proposal. Requires minimum reputation.
     * @param _description A description of the proposal.
     * @param _callData Calldata for the target function to be executed if proposal passes.
     * @param _targetContract Address of the contract to call if proposal passes.
     */
    function proposeGovernanceAction(string calldata _description, bytes calldata _callData, address _targetContract) external {
        require(reputationScores[msg.sender] >= globalParams.minReputationForProposal, "Insufficient reputation to propose");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_targetContract != address(0), "Target contract cannot be zero address");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            proposer: msg.sender,
            startBlock: block.number,
            endBlock: block.number + (globalParams.proposalVoteDuration / 12), // Assuming 12 sec/block
            forVotes: 0,
            againstVotes: 0,
            hasVoted: new mapping(address => bool),
            status: ProposalStatus.Active,
            executionTimestamp: 0 // Will be set after voting passes and timelock
        });

        emit ProposalCreated(newProposalId, msg.sender, _description);
        emit ProposalStateChanged(newProposalId, ProposalStatus.Active);
    }

    /**
     * @dev Allows users to vote on an active governance proposal. Voting power is based on reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        require(proposal.status == ProposalStatus.Active, "Proposal not active for voting");
        require(block.number >= proposal.startBlock && block.number <= proposal.endBlock, "Voting period not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterReputation = uint256(reputationScores[delegatedReputation[msg.sender] != address(0) ? delegatedReputation[msg.sender] : msg.sender]);
        require(voterReputation > 0, "Voter has no reputation");

        if (_support) {
            proposal.forVotes += voterReputation;
        } else {
            proposal.againstVotes += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);

        // Check if voting period ended and update status
        if (block.number >= proposal.endBlock) {
            if (proposal.forVotes > proposal.againstVotes) {
                proposal.status = ProposalStatus.Succeeded;
                proposal.executionTimestamp = block.timestamp + globalParams.proposalTimelock;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
            emit ProposalStateChanged(_proposalId, proposal.status);
        }
    }

    /**
     * @dev Executes a successful governance proposal after its timelock has expired.
     * Callable by anyone after the conditions are met.
     * This is a simplified execution, in a real DAO it would be handled by a governor contract.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        require(proposal.status == ProposalStatus.Succeeded, "Proposal not in 'Succeeded' state");
        require(block.timestamp >= proposal.executionTimestamp, "Proposal timelock not expired");
        require(proposal.executionTimestamp > 0, "Execution timestamp not set");

        proposal.status = ProposalStatus.Executed;

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalStatus.Executed);
    }

    // --- VI. Token & Utility ---

    /**
     * @dev Allows users to withdraw their accumulated CGNT rewards from successful training jobs or data provision.
     */
    function withdrawEarnings() external nonReentrant {
        uint256 amount = userEarnings[msg.sender];
        if (amount == 0) revert NoEarningsToWithdraw();

        userEarnings[msg.sender] = 0; // Reset earnings before transfer to prevent reentrancy issues

        if (!cgntToken.transfer(msg.sender, amount)) {
            revert InvalidAmount(); // Should not fail if balance is correct
        }
        emit EarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Public view function to check a user's total staked CGNT balance across all purposes.
     * @param _user The address of the user.
     * @return The total staked CGNT balance.
     */
    function getStakingBalance(address _user) public view returns (uint256) {
        return totalStakedBalance[_user];
    }

    /**
     * @dev Public view function to check a user's current reputation score.
     * @param _user The address of the user.
     * @return The current reputation score.
     */
    function getReputationScore(address _user) public view returns (int256) {
        return reputationScores[_user];
    }

    /**
     * @dev Public view function to get the current status of a training job.
     * @param _jobId The ID of the training job.
     * @return The status enum and the timestamp of submission if applicable.
     */
    function getTrainingJobStatus(uint256 _jobId) public view returns (TrainingJobStatus, uint256) {
        if (trainingJobs[_jobId].modelOwner == address(0)) revert TrainingJobNotFound();
        return (trainingJobs[_jobId].status, trainingJobs[_jobId].submissionTime);
    }

    /**
     * @dev Public view function to get details about a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return GovernanceProposal struct containing all proposal details.
     */
    function getProposalInfo(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        if (proposals[_proposalId].proposer == address(0)) revert ProposalNotFound();
        return proposals[_proposalId];
    }
}
```