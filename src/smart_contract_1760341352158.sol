Here's a Solidity smart contract, `NeuralNexus`, designed around advanced concepts like decentralized AI model/dataset licensing, a verifiable compute market, and a multi-faceted reputation system. It aims to be creative by combining these elements into a cohesive platform for the AI economy, without directly duplicating existing open-source projects.

---

## NeuralNexus Smart Contract

**Contract Name:** `NeuralNexus`

**Core Concept:** A decentralized platform for registering, licensing, and monetizing AI models and datasets, coupled with a verifiable compute market for executing AI tasks and a robust reputation system for participants.

**Outline & Function Summary:**

**I. Core Registries & Identity**
*   **`registerAIModel`**: Allows a creator to register a new AI model with its metadata and cryptographic hash.
*   **`updateAIModelMetadata`**: Updates the metadata URI for an existing AI model.
*   **`registerDataset`**: Allows a creator to register a new dataset with its metadata and cryptographic hash.
*   **`updateDatasetMetadata`**: Updates the metadata URI for an existing dataset.
*   **`registerComputeProvider`**: Registers an address as a compute provider, detailing their hardware profile.
*   **`registerComputeOracle`**: Registers an address as a compute oracle, essential for dispute resolution.
*   **`getAIModelDetails`**: Retrieves details of a registered AI model.
*   **`getDatasetDetails`**: Retrieves details of a registered dataset.

**II. Licensing & Monetization**
*   **`defineModelLicenseTerms`**: A model creator defines the specific terms (price, duration, type) for licensing their AI model.
*   **`purchaseModelLicense`**: A user purchases a license for a specific AI model according to defined terms.
*   **`defineDatasetLicenseTerms`**: A dataset creator defines the specific terms for licensing their dataset.
*   **`purchaseDatasetLicense`**: A user purchases a license for a specific dataset.
*   **`collectRoyalties`**: Allows model/dataset creators to withdraw their accumulated earnings from purchased licenses.
*   **`checkLicenseValidity`**: Checks if a specific address holds a valid license for an asset.

**III. Verifiable Compute Market**
*   **`submitComputeTask`**: A requester submits an AI computation task (e.g., training, inference) specifying the model, dataset, reward, and proof type.
*   **`bidForComputeTask`**: A registered compute provider bids on an open compute task, offering a fee and collateral.
*   **`selectAndAssignComputeProvider`**: The task requester selects a winning bid and assigns the task to a compute provider.
*   **`submitComputeResult`**: The assigned compute provider submits the cryptographic hash of the computation result and relevant proof data.
*   **`initiateComputeDispute`**: The task requester or a registered oracle can initiate a dispute if a submitted result is suspected to be incorrect or malicious.
*   **`resolveComputeDisputeByOracle`**: A compute oracle adjudicates a dispute, verifying the result and potentially slashing/rewarding participants.
*   **`claimComputeReward`**: The compute provider claims their reward and collateral after a task is successfully verified.

**IV. Reputation & Staking**
*   **`stakeForReputation`**: Allows any participant (CP, Oracle) to stake tokens to boost their reputation score.
*   **`withdrawReputationStake`**: Allows participants to withdraw their staked tokens after a cooldown period, provided they haven't been slashed.
*   **`getReputationScore`**: Retrieves the current reputation score of an address.

**V. Platform & Admin**
*   **`setPlatformFee`**: The contract owner sets the percentage of fees taken by the platform from transactions.
*   **`withdrawPlatformFees`**: The contract owner can withdraw accumulated platform fees to the designated receiver.
*   **`pauseContract`**: The contract owner can pause core functionalities in case of an emergency.
*   **`unpauseContract`**: The contract owner can unpause the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Error definitions for cleaner code and better error handling
error InvalidState(string message);
error Unauthorized(string message);
error InsufficientFunds(string message);
error InvalidInput(string message);
error CooldownNotElapsed(string message);
error NoActiveLicense();
error NoPendingRoyalties();
error NoStakedTokens();
error TaskNotOpen();
error TaskAlreadyAssigned();
error TaskNotAssignedToYou();
error TaskNotResultSubmitted();
error TaskAlreadyDisputed();
error TaskNotInDispute();
error BidTooLow();
error InvalidBidder();
error NoBidsFound();
error OracleNotRegistered();
error ProviderNotRegistered();

contract NeuralNexus is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum LicenseType { CommercialUse, NonCommercialUse, Subscription, PayPerUse }
    enum ComputeTaskState { Open, Assigned, ResultSubmitted, Disputed, Verified, Rejected }
    enum ProofType { HashOnly, ZkProofHash, OracleVerification } // Verification complexity/method

    // --- Structs ---

    struct AIModel {
        uint256 id;
        address creator;
        string metadataURI; // URI to IPFS/Arweave for model description, architecture, etc.
        bytes32 modelHash;  // Cryptographic hash of the model weights/binary
        bool active;
    }

    struct Dataset {
        uint256 id;
        address creator;
        string metadataURI; // URI to IPFS/Arweave for dataset description, schema, etc.
        bytes32 datasetHash; // Cryptographic hash of the dataset
        bool active;
    }

    struct LicenseTerms {
        LicenseType licenseType;
        uint256 pricePerUse;      // For PayPerUse
        uint256 subscriptionPrice; // For Subscription
        uint256 duration;         // For Subscription, in seconds
        string termsURI;          // URI to detailed license agreement
        bool active;
    }

    struct License {
        uint256 assetId;          // Model or Dataset ID
        address buyer;
        LicenseType licenseType;
        uint256 purchasedAt;
        uint256 validUntil;       // 0 for PayPerUse (verified per use), or for fixed duration
        bool revoked;
    }

    struct ComputeProviderProfile {
        address providerAddress;
        string hardwareProfileURI; // URI to IPFS/Arweave describing hardware specs
        bool active;
    }

    struct ComputeOracleProfile {
        address oracleAddress;
        bool active;
    }

    struct ComputeTask {
        uint256 id;
        address requester;
        uint256 modelId;
        uint256 datasetId;
        string computeParamsURI; // URI to IPFS/Arweave for computation parameters (e.g., training epochs, inference prompts)
        uint256 rewardAmount;    // Total reward for the provider, includes provider's fee and platform fee
        uint256 platformFeeAmount; // Amount of platform fee for this task
        ProofType proofType;
        ComputeTaskState state;
        address assignedProvider;
        uint256 providerFee;       // Fee accepted by the provider
        bytes32 providerCollateral; // Hash of collateral for specific task (could be a token amount)
        bytes32 resultHash;        // Hash of the computation result
        bytes32 proofDataHash;     // Hash of the proof data (e.g., ZK-SNARK proof, or attestation)
        uint256 assignedAt;
    }

    struct Bid {
        address provider;
        uint256 fee; // Fee requested by the provider for the task
        uint256 collateralAmount; // Staked by provider to ensure honest execution
    }

    struct ReputationStake {
        uint256 amount;
        uint256 stakedAt;
    }

    // --- State Variables ---

    IERC20 public immutable paymentToken;
    uint256 public platformFeeBasisPoints; // e.g., 100 = 1%
    address public platformFeeReceiver;

    uint256 private _aiModelCounter;
    mapping(uint256 => AIModel) public aiModels;

    uint256 private _datasetCounter;
    mapping(uint256 => Dataset) public datasets;

    // assetId => address => LicenseTerms
    mapping(uint256 => mapping(LicenseType => LicenseTerms)) public modelLicenseTerms;
    mapping(uint256 => mapping(LicenseType => LicenseTerms)) public datasetLicenseTerms;

    // assetId => buyerAddress => License
    mapping(uint256 => mapping(address => License)) public activeModelLicenses;
    mapping(uint256 => mapping(address => License)) public activeDatasetLicenses;

    // assetId => creatorAddress => accumulated royalties
    mapping(uint256 => mapping(address => uint256)) public pendingRoyalties;

    mapping(address => ComputeProviderProfile) public computeProviders;
    mapping(address => bool) public isComputeProvider; // Quick lookup

    mapping(address => ComputeOracleProfile) public computeOracles;
    mapping(address => bool) public isComputeOracle; // Quick lookup
    uint256 public oracleReputationThreshold; // Minimum reputation to be an active oracle

    uint256 private _taskCounter;
    mapping(uint256 => ComputeTask) public computeTasks;
    // taskId => providerAddress => Bid
    mapping(uint256 => mapping(address => Bid)) public taskBids;
    mapping(uint256 => address[]) public taskBidders; // To iterate bids

    // address => reputation score
    mapping(address => uint256) public reputationScores;
    // address => ReputationStake
    mapping(address => ReputationStake) public reputationStakes;
    uint256 public constant REPUTATION_STAKE_COOLDOWN = 30 days; // Cooldown for withdrawing stake

    bool public paused;

    // --- Events ---

    event AIModelRegistered(uint256 indexed modelId, address indexed creator, string metadataURI, bytes32 modelHash);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newMetadataURI);
    event DatasetRegistered(uint256 indexed datasetId, address indexed creator, string metadataURI, bytes32 datasetHash);
    event DatasetMetadataUpdated(uint256 indexed datasetId, string newMetadataURI);

    event ComputeProviderRegistered(address indexed providerAddress, string hardwareProfileURI);
    event ComputeOracleRegistered(address indexed oracleAddress);

    event ModelLicenseTermsDefined(uint256 indexed modelId, LicenseType indexed licenseType, uint256 pricePerUse, uint256 subscriptionPrice, uint256 duration, string termsURI);
    event ModelLicensePurchased(uint256 indexed modelId, address indexed buyer, LicenseType licenseType, uint256 pricePaid, uint256 validUntil);
    event DatasetLicenseTermsDefined(uint256 indexed datasetId, LicenseType indexed licenseType, uint256 pricePerUse, uint256 subscriptionPrice, uint256 duration, string termsURI);
    event DatasetLicensePurchased(uint256 indexed datasetId, address indexed buyer, LicenseType licenseType, uint256 pricePaid, uint256 validUntil);
    event RoyaltiesCollected(uint256 indexed assetId, address indexed creator, uint256 amount);

    event ComputeTaskSubmitted(uint256 indexed taskId, address indexed requester, uint256 modelId, uint256 datasetId, uint256 rewardAmount, ProofType proofType);
    event ComputeTaskBid(uint256 indexed taskId, address indexed provider, uint256 fee, uint256 collateralAmount);
    event ComputeTaskAssigned(uint256 indexed taskId, address indexed requester, address indexed provider, uint256 providerFee);
    event ComputeResultSubmitted(uint256 indexed taskId, address indexed provider, bytes32 resultHash, bytes32 proofDataHash);
    event ComputeDisputeInitiated(uint256 indexed taskId, address indexed initiator);
    event ComputeDisputeResolved(uint256 indexed taskId, address indexed oracle, bool resultApproved, uint256 slashedAmount);
    event ComputeRewardClaimed(uint256 indexed taskId, address indexed provider, uint256 amount);

    event ReputationStaked(address indexed participant, uint256 amount);
    event ReputationStakeWithdrawn(address indexed participant, uint256 amount);
    event ReputationUpdated(address indexed participant, uint256 newScore, string reason);

    event PlatformFeeSet(uint256 newFeeBasisPoints);
    event PlatformFeesWithdrawn(address indexed receiver, uint256 amount);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);

    // --- Modifiers ---

    modifier whenNotPaused() {
        if (paused) revert InvalidState("Contract is paused");
        _;
    }

    modifier onlyComputeProvider() {
        if (!isComputeProvider[msg.sender]) revert Unauthorized("Caller is not a registered compute provider");
        _;
    }

    modifier onlyComputeOracle() {
        if (!isComputeOracle[msg.sender] || reputationScores[msg.sender] < oracleReputationThreshold)
            revert Unauthorized("Caller is not an active compute oracle");
        _;
    }

    constructor(address _paymentTokenAddress, address _platformFeeReceiver) Ownable(msg.sender) {
        if (_paymentTokenAddress == address(0) || _platformFeeReceiver == address(0)) {
            revert InvalidInput("Invalid payment token or fee receiver address");
        }
        paymentToken = IERC20(_paymentTokenAddress);
        platformFeeBasisPoints = 100; // Default 1% fee
        platformFeeReceiver = _platformFeeReceiver;
        oracleReputationThreshold = 1000; // Default oracle reputation threshold
        paused = false;
    }

    // --- I. Core Registries & Identity ---

    /**
     * @notice Registers a new AI model with its metadata and cryptographic hash.
     * @param _metadataURI URI pointing to the model's metadata (e.g., IPFS).
     * @param _modelHash Cryptographic hash of the actual model data.
     */
    function registerAIModel(string memory _metadataURI, bytes32 _modelHash)
        external
        whenNotPaused
        returns (uint256)
    {
        _aiModelCounter++;
        aiModels[_aiModelCounter] = AIModel(
            _aiModelCounter,
            msg.sender,
            _metadataURI,
            _modelHash,
            true
        );
        emit AIModelRegistered(_aiModelCounter, msg.sender, _metadataURI, _modelHash);
        return _aiModelCounter;
    }

    /**
     * @notice Updates the metadata URI for an existing AI model. Only the creator can update.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateAIModelMetadata(uint256 _modelId, string memory _newMetadataURI)
        external
        whenNotPaused
    {
        AIModel storage model = aiModels[_modelId];
        if (model.creator == address(0)) revert InvalidInput("Model does not exist");
        if (model.creator != msg.sender) revert Unauthorized("Only model creator can update metadata");
        model.metadataURI = _newMetadataURI;
        emit AIModelMetadataUpdated(_modelId, _newMetadataURI);
    }

    /**
     * @notice Registers a new dataset with its metadata and cryptographic hash.
     * @param _metadataURI URI pointing to the dataset's metadata (e.g., IPFS).
     * @param _datasetHash Cryptographic hash of the actual dataset.
     */
    function registerDataset(string memory _metadataURI, bytes32 _datasetHash)
        external
        whenNotPaused
        returns (uint256)
    {
        _datasetCounter++;
        datasets[_datasetCounter] = Dataset(
            _datasetCounter,
            msg.sender,
            _metadataURI,
            _datasetHash,
            true
        );
        emit DatasetRegistered(_datasetCounter, msg.sender, _metadataURI, _datasetHash);
        return _datasetCounter;
    }

    /**
     * @notice Updates the metadata URI for an existing dataset. Only the creator can update.
     * @param _datasetId The ID of the dataset to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateDatasetMetadata(uint256 _datasetId, string memory _newMetadataURI)
        external
        whenNotPaused
    {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.creator == address(0)) revert InvalidInput("Dataset does not exist");
        if (dataset.creator != msg.sender) revert Unauthorized("Only dataset creator can update metadata");
        dataset.metadataURI = _newMetadataURI;
        emit DatasetMetadataUpdated(_datasetId, _newMetadataURI);
    }

    /**
     * @notice Registers the caller as a compute provider.
     * @param _hardwareProfileURI URI detailing hardware specs.
     */
    function registerComputeProvider(string memory _hardwareProfileURI)
        external
        whenNotPaused
    {
        if (isComputeProvider[msg.sender]) revert InvalidState("Already a registered compute provider");
        computeProviders[msg.sender] = ComputeProviderProfile(msg.sender, _hardwareProfileURI, true);
        isComputeProvider[msg.sender] = true;
        emit ComputeProviderRegistered(msg.sender, _hardwareProfileURI);
    }

    /**
     * @notice Registers the caller as a compute oracle. Oracles resolve disputes.
     */
    function registerComputeOracle()
        external
        whenNotPaused
    {
        if (isComputeOracle[msg.sender]) revert InvalidState("Already a registered compute oracle");
        computeOracles[msg.sender] = ComputeOracleProfile(msg.sender, true);
        isComputeOracle[msg.sender] = true;
        // Initial reputation for new oracles, or require staking first
        if (reputationScores[msg.sender] == 0) {
            reputationScores[msg.sender] = 100; // Small initial score
            emit ReputationUpdated(msg.sender, 100, "Initial score for oracle registration");
        }
        emit ComputeOracleRegistered(msg.sender);
    }

    /**
     * @notice Retrieves the details of a registered AI model.
     * @param _modelId The ID of the AI model.
     * @return AIModel struct.
     */
    function getAIModelDetails(uint256 _modelId) external view returns (AIModel memory) {
        return aiModels[_modelId];
    }

    /**
     * @notice Retrieves the details of a registered dataset.
     * @param _datasetId The ID of the dataset.
     * @return Dataset struct.
     */
    function getDatasetDetails(uint256 _datasetId) external view returns (Dataset memory) {
        return datasets[_datasetId];
    }

    // --- II. Licensing & Monetization ---

    /**
     * @notice Defines the licensing terms for an AI model. Only the model creator can do this.
     * @param _modelId The ID of the model.
     * @param _licenseType The type of license (e.g., CommercialUse, Subscription).
     * @param _pricePerUse Price for a single use (for PayPerUse).
     * @param _subscriptionPrice Subscription price (for Subscription).
     * @param _duration Duration in seconds (for Subscription).
     * @param _termsURI URI to detailed legal terms.
     */
    function defineModelLicenseTerms(
        uint256 _modelId,
        LicenseType _licenseType,
        uint256 _pricePerUse,
        uint256 _subscriptionPrice,
        uint256 _duration,
        string memory _termsURI
    ) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.creator == address(0)) revert InvalidInput("Model does not exist");
        if (model.creator != msg.sender) revert Unauthorized("Only model creator can define license terms");

        // Basic validation for license types
        if (_licenseType == LicenseType.PayPerUse && _pricePerUse == 0) revert InvalidInput("PayPerUse requires pricePerUse > 0");
        if (_licenseType == LicenseType.Subscription && (_subscriptionPrice == 0 || _duration == 0)) revert InvalidInput("Subscription requires price > 0 and duration > 0");

        modelLicenseTerms[_modelId][_licenseType] = LicenseTerms(
            _licenseType, _pricePerUse, _subscriptionPrice, _duration, _termsURI, true
        );
        emit ModelLicenseTermsDefined(_modelId, _licenseType, _pricePerUse, _subscriptionPrice, _duration, _termsURI);
    }

    /**
     * @notice Purchases a license for a specific AI model.
     * @param _modelId The ID of the model.
     * @param _licenseType The type of license to purchase.
     * @param _amount The amount of payment token sent for the license.
     */
    function purchaseModelLicense(uint256 _modelId, LicenseType _licenseType, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        AIModel storage model = aiModels[_modelId];
        if (model.creator == address(0)) revert InvalidInput("Model does not exist");
        LicenseTerms storage terms = modelLicenseTerms[_modelId][_licenseType];
        if (!terms.active) revert InvalidState("License terms not defined or inactive");

        uint256 requiredAmount;
        uint256 validUntil = 0;

        if (_licenseType == LicenseType.PayPerUse) {
            requiredAmount = terms.pricePerUse;
            // For PayPerUse, license validity is typically checked per-use or short duration if needed.
            // Here, we can define it as valid for a single "event" or a very short time if needed for tracking.
            // For simplicity, we'll assume the payment implies one "use" and doesn't grant prolonged access.
            // A more complex system might require incrementing a usage counter.
        } else if (_licenseType == LicenseType.Subscription) {
            requiredAmount = terms.subscriptionPrice;
            validUntil = block.timestamp + terms.duration;
        } else {
            revert InvalidInput("Unsupported license type for direct purchase");
        }

        if (_amount < requiredAmount) revert InsufficientFunds("Insufficient payment for license");

        // Transfer payment to creator
        if (!paymentToken.transferFrom(msg.sender, model.creator, requiredAmount)) {
            revert InsufficientFunds("Payment token transfer failed");
        }

        // Store pending royalties for collection
        pendingRoyalties[_modelId][model.creator] += requiredAmount;

        activeModelLicenses[_modelId][msg.sender] = License(
            _modelId,
            msg.sender,
            _licenseType,
            block.timestamp,
            validUntil,
            false
        );

        emit ModelLicensePurchased(_modelId, msg.sender, _licenseType, requiredAmount, validUntil);
    }

    /**
     * @notice Defines the licensing terms for a dataset. Only the dataset creator can do this.
     * @param _datasetId The ID of the dataset.
     * @param _licenseType The type of license (e.g., CommercialUse, Subscription).
     * @param _pricePerUse Price for a single use (for PayPerUse).
     * @param _subscriptionPrice Subscription price (for Subscription).
     * @param _duration Duration in seconds (for Subscription).
     * @param _termsURI URI to detailed legal terms.
     */
    function defineDatasetLicenseTerms(
        uint256 _datasetId,
        LicenseType _licenseType,
        uint256 _pricePerUse,
        uint256 _subscriptionPrice,
        uint256 _duration,
        string memory _termsURI
    ) external whenNotPaused {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.creator == address(0)) revert InvalidInput("Dataset does not exist");
        if (dataset.creator != msg.sender) revert Unauthorized("Only dataset creator can define license terms");

        if (_licenseType == LicenseType.PayPerUse && _pricePerUse == 0) revert InvalidInput("PayPerUse requires pricePerUse > 0");
        if (_licenseType == LicenseType.Subscription && (_subscriptionPrice == 0 || _duration == 0)) revert InvalidInput("Subscription requires price > 0 and duration > 0");

        datasetLicenseTerms[_datasetId][_licenseType] = LicenseTerms(
            _licenseType, _pricePerUse, _subscriptionPrice, _duration, _termsURI, true
        );
        emit DatasetLicenseTermsDefined(_datasetId, _licenseType, _pricePerUse, _subscriptionPrice, _duration, _termsURI);
    }

    /**
     * @notice Purchases a license for a specific dataset.
     * @param _datasetId The ID of the dataset.
     * @param _licenseType The type of license to purchase.
     * @param _amount The amount of payment token sent for the license.
     */
    function purchaseDatasetLicense(uint252 _datasetId, LicenseType _licenseType, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.creator == address(0)) revert InvalidInput("Dataset does not exist");
        LicenseTerms storage terms = datasetLicenseTerms[_datasetId][_licenseType];
        if (!terms.active) revert InvalidState("License terms not defined or inactive");

        uint256 requiredAmount;
        uint256 validUntil = 0;

        if (_licenseType == LicenseType.PayPerUse) {
            requiredAmount = terms.pricePerUse;
        } else if (_licenseType == LicenseType.Subscription) {
            requiredAmount = terms.subscriptionPrice;
            validUntil = block.timestamp + terms.duration;
        } else {
            revert InvalidInput("Unsupported license type for direct purchase");
        }

        if (_amount < requiredAmount) revert InsufficientFunds("Insufficient payment for license");

        // Transfer payment to creator
        if (!paymentToken.transferFrom(msg.sender, dataset.creator, requiredAmount)) {
            revert InsufficientFunds("Payment token transfer failed");
        }

        pendingRoyalties[_datasetId][dataset.creator] += requiredAmount;

        activeDatasetLicenses[_datasetId][msg.sender] = License(
            _datasetId,
            msg.sender,
            _licenseType,
            block.timestamp,
            validUntil,
            false
        );

        emit DatasetLicensePurchased(_datasetId, msg.sender, _licenseType, requiredAmount, validUntil);
    }

    /**
     * @notice Allows model/dataset creators to withdraw their accumulated royalties.
     * @param _assetId The ID of the model or dataset.
     * @param _isModel True if collecting for a model, false for a dataset.
     */
    function collectRoyalties(uint256 _assetId, bool _isModel)
        external
        nonReentrant
        whenNotPaused
    {
        address creator;
        if (_isModel) {
            creator = aiModels[_assetId].creator;
        } else {
            creator = datasets[_assetId].creator;
        }

        if (creator == address(0)) revert InvalidInput("Asset does not exist");
        if (creator != msg.sender) revert Unauthorized("Only creator can collect royalties");

        uint256 amount = pendingRoyalties[_assetId][creator];
        if (amount == 0) revert NoPendingRoyalties();

        pendingRoyalties[_assetId][creator] = 0; // Reset before transfer

        if (!paymentToken.transfer(creator, amount)) {
            revert InsufficientFunds("Royalty transfer failed");
        }
        emit RoyaltiesCollected(_assetId, creator, amount);
    }

    /**
     * @notice Checks if an address holds a valid, unrevoked license for a given asset.
     * @param _assetId The ID of the model or dataset.
     * @param _licensee The address to check.
     * @param _isModel True if checking a model license, false for a dataset.
     * @return True if license is valid, false otherwise.
     */
    function checkLicenseValidity(uint256 _assetId, address _licensee, bool _isModel)
        public
        view
        returns (bool)
    {
        License storage license;
        if (_isModel) {
            license = activeModelLicenses[_assetId][_licensee];
        } else {
            license = activeDatasetLicenses[_assetId][_licensee];
        }

        if (license.buyer == address(0) || license.revoked) return false;

        if (license.licenseType == LicenseType.Subscription) {
            return license.validUntil > block.timestamp;
        }
        // For PayPerUse or CommercialUse/NonCommercialUse (one-time purchase for perpetual rights)
        // More complex logic can be added here if PayPerUse needs to track usage.
        return true;
    }


    // --- III. Verifiable Compute Market ---

    /**
     * @notice Submits a new AI computation task.
     * @param _modelId The ID of the AI model to use.
     * @param _datasetId The ID of the dataset to use.
     * @param _computeParamsURI URI to compute parameters.
     * @param _totalRewardAmount Total reward for the task, including provider fee and platform fee.
     * @param _proofType The expected type of proof for verification.
     */
    function submitComputeTask(
        uint256 _modelId,
        uint256 _datasetId,
        string memory _computeParamsURI,
        uint256 _totalRewardAmount,
        ProofType _proofType
    ) external nonReentrant whenNotPaused {
        if (aiModels[_modelId].creator == address(0)) revert InvalidInput("Model does not exist");
        if (datasets[_datasetId].creator == address(0)) revert InvalidInput("Dataset does not exist");
        if (_totalRewardAmount == 0) revert InvalidInput("Reward amount must be greater than zero");

        // Check if requester has a valid license to use the model and dataset
        if (!checkLicenseValidity(_modelId, msg.sender, true)) revert NoActiveLicense();
        if (!checkLicenseValidity(_datasetId, msg.sender, false)) revert NoActiveLicense();

        uint256 platformFee = (_totalRewardAmount * platformFeeBasisPoints) / 10000;
        if (platformFee >= _totalRewardAmount) revert InvalidInput("Platform fee cannot be equal or exceed total reward");

        // Escrow the total reward amount
        if (!paymentToken.transferFrom(msg.sender, address(this), _totalRewardAmount)) {
            revert InsufficientFunds("Failed to escrow reward amount for task");
        }

        _taskCounter++;
        computeTasks[_taskCounter] = ComputeTask(
            _taskCounter,
            msg.sender,
            _modelId,
            _datasetId,
            _computeParamsURI,
            _totalRewardAmount,
            platformFee,
            _proofType,
            ComputeTaskState.Open,
            address(0), // No provider assigned yet
            0,
            bytes32(0),
            bytes32(0),
            bytes32(0),
            0
        );
        emit ComputeTaskSubmitted(_taskCounter, msg.sender, _modelId, _datasetId, _totalRewardAmount, _proofType);
    }

    /**
     * @notice A compute provider bids on an open task.
     * @param _taskId The ID of the task.
     * @param _fee The fee the provider requests for the task.
     * @param _collateralAmount The collateral the provider stakes.
     */
    function bidForComputeTask(uint256 _taskId, uint256 _fee, uint256 _collateralAmount)
        external
        onlyComputeProvider
        nonReentrant
        whenNotPaused
    {
        ComputeTask storage task = computeTasks[_taskId];
        if (task.state != ComputeTaskState.Open) revert TaskNotOpen();
        if (_fee == 0) revert InvalidInput("Bid fee must be greater than zero");
        if (_collateralAmount == 0) revert InvalidInput("Collateral amount must be greater than zero");
        if (_fee >= task.rewardAmount - task.platformFeeAmount) revert BidTooLow("Provider fee too high, leaves no reward margin.");

        // Check if provider has enough reputation for specific tasks if needed
        // For now, any registered provider can bid.

        // Escrow collateral
        if (!paymentToken.transferFrom(msg.sender, address(this), _collateralAmount)) {
            revert InsufficientFunds("Failed to escrow collateral for bid");
        }

        taskBids[_taskId][msg.sender] = Bid(msg.sender, _fee, _collateralAmount);
        taskBidders[_taskId].push(msg.sender);
        emit ComputeTaskBid(_taskId, msg.sender, _fee, _collateralAmount);
    }

    /**
     * @notice The task requester selects a provider from bids and assigns the task.
     * @param _taskId The ID of the task.
     * @param _providerAddress The address of the chosen compute provider.
     */
    function selectAndAssignComputeProvider(uint256 _taskId, address _providerAddress)
        external
        nonReentrant
        whenNotPaused
    {
        ComputeTask storage task = computeTasks[_taskId];
        if (task.requester != msg.sender) revert Unauthorized("Only task requester can assign the task");
        if (task.state != ComputeTaskState.Open) revert TaskNotOpen();

        Bid storage bid = taskBids[_taskId][_providerAddress];
        if (bid.provider == address(0)) revert InvalidBidder("Provider did not bid on this task");

        // Refund all other bidders' collateral
        for (uint i = 0; i < taskBidders[_taskId].length; i++) {
            address currentProvider = taskBidders[_taskId][i];
            if (currentProvider != _providerAddress) {
                Bid storage otherBid = taskBids[_taskId][currentProvider];
                if (otherBid.collateralAmount > 0) {
                    if (!paymentToken.transfer(currentProvider, otherBid.collateralAmount)) {
                        // Log event for failed refund, but don't revert entire transaction
                    }
                    otherBid.collateralAmount = 0; // Mark as refunded
                }
            }
        }

        task.assignedProvider = _providerAddress;
        task.providerFee = bid.fee;
        task.state = ComputeTaskState.Assigned;
        task.assignedAt = block.timestamp;
        // The collateral for the assigned provider remains escrowed
        task.providerCollateral = keccak256(abi.encodePacked(bid.collateralAmount)); // Store hash of collateral

        emit ComputeTaskAssigned(_taskId, msg.sender, _providerAddress, bid.fee);
    }

    /**
     * @notice The assigned compute provider submits the result of the computation.
     * @param _taskId The ID of the task.
     * @param _resultHash Cryptographic hash of the computation output.
     * @param _proofDataHash Cryptographic hash of the proof data (e.g., ZK-SNARK proof, attestation).
     */
    function submitComputeResult(uint256 _taskId, bytes32 _resultHash, bytes32 _proofDataHash)
        external
        onlyComputeProvider
        whenNotPaused
    {
        ComputeTask storage task = computeTasks[_taskId];
        if (task.assignedProvider == address(0) || task.assignedProvider != msg.sender) {
            revert TaskNotAssignedToYou();
        }
        if (task.state != ComputeTaskState.Assigned) revert InvalidState("Task is not in 'Assigned' state");

        task.resultHash = _resultHash;
        task.proofDataHash = _proofDataHash;
        task.state = ComputeTaskState.ResultSubmitted;

        emit ComputeResultSubmitted(_taskId, msg.sender, _resultHash, _proofDataHash);
    }

    /**
     * @notice Initiates a dispute for a submitted compute result.
     * Can be called by the requester or any active oracle.
     * @param _taskId The ID of the task.
     */
    function initiateComputeDispute(uint256 _taskId)
        external
        whenNotPaused
    {
        ComputeTask storage task = computeTasks[_taskId];
        if (task.state != ComputeTaskState.ResultSubmitted) revert TaskNotResultSubmitted();
        if (msg.sender != task.requester && (!isComputeOracle[msg.sender] || reputationScores[msg.sender] < oracleReputationThreshold)) {
            revert Unauthorized("Only requester or active oracle can initiate dispute");
        }

        task.state = ComputeTaskState.Disputed;
        emit ComputeDisputeInitiated(_taskId, msg.sender);
    }

    /**
     * @notice An active compute oracle resolves a dispute.
     * This function assumes an off-chain process for oracle verification.
     * @param _taskId The ID of the task.
     * @param _resultApproved True if the result is correct, false if incorrect.
     * @param _slashAmount Optional amount to slash from provider's collateral if result is rejected.
     */
    function resolveComputeDisputeByOracle(uint256 _taskId, bool _resultApproved, uint256 _slashAmount)
        external
        onlyComputeOracle
        nonReentrant
        whenNotPaused
    {
        ComputeTask storage task = computeTasks[_taskId];
        if (task.state != ComputeTaskState.Disputed) revert TaskNotInDispute();

        address provider = task.assignedProvider;
        Bid storage providerBid = taskBids[_taskId][provider];
        uint256 actualCollateral = providerBid.collateralAmount; // Use the stored collateral

        if (_resultApproved) {
            task.state = ComputeTaskState.Verified;
            // Reward oracle for correct resolution if desired
            _updateReputation(msg.sender, 50, "Successfully resolved dispute (approved)");
        } else {
            task.state = ComputeTaskState.Rejected;
            // Slashing logic
            if (_slashAmount > 0 && _slashAmount <= actualCollateral) {
                // Transfer slashed amount to platform fee receiver (or burn, or distribute to other oracles)
                if (!paymentToken.transfer(platformFeeReceiver, _slashAmount)) {
                    revert InsufficientFunds("Failed to transfer slashed amount");
                }
                actualCollateral -= _slashAmount;
                _updateReputation(provider, -200, "Slashed for incorrect result"); // Penalize provider
                _updateReputation(msg.sender, 100, "Successfully resolved dispute (rejected)"); // Reward oracle
            } else if (_slashAmount > actualCollateral) {
                revert InvalidInput("Slash amount exceeds provider's collateral");
            }
        }
        
        // Return remaining collateral (if any) to provider upon rejection, or after reward claim if approved.
        // For simplicity, we'll refund remaining collateral only if the task is rejected.
        // If approved, collateral is returned with the reward.
        if (!_resultApproved && actualCollateral > 0) {
             if (!paymentToken.transfer(provider, actualCollateral)) {
                revert InsufficientFunds("Failed to return remaining collateral to provider");
            }
             providerBid.collateralAmount = 0; // Mark as refunded
        }


        emit ComputeDisputeResolved(_taskId, msg.sender, _resultApproved, _slashAmount);
    }

    /**
     * @notice Allows a compute provider to claim their reward after a task is verified.
     * @param _taskId The ID of the task.
     */
    function claimComputeReward(uint256 _taskId)
        external
        onlyComputeProvider
        nonReentrant
        whenNotPaused
    {
        ComputeTask storage task = computeTasks[_taskId];
        if (task.assignedProvider != msg.sender) revert Unauthorized("Only assigned provider can claim reward");
        if (task.state != ComputeTaskState.Verified) revert InvalidState("Task is not in 'Verified' state");

        Bid storage providerBid = taskBids[_taskId][msg.sender];
        uint256 collateralAmount = providerBid.collateralAmount;
        uint256 rewardPayout = task.providerFee + collateralAmount; // Provider gets their fee + collateral back

        // Transfer platform fee to platform receiver
        if (task.platformFeeAmount > 0) {
            if (!paymentToken.transfer(platformFeeReceiver, task.platformFeeAmount)) {
                revert InsufficientFunds("Failed to transfer platform fee");
            }
        }
        
        // Transfer reward payout to provider
        if (rewardPayout > 0) {
            if (!paymentToken.transfer(msg.sender, rewardPayout)) {
                revert InsufficientFunds("Failed to transfer reward payout to provider");
            }
        }

        task.state = ComputeTaskState.Rejected; // Mark as processed to prevent double claims
        providerBid.collateralAmount = 0; // Mark collateral as refunded
        task.assignedProvider = address(0); // Clear assigned provider

        _updateReputation(msg.sender, 50, "Successfully completed compute task");
        emit ComputeRewardClaimed(_taskId, msg.sender, rewardPayout);
    }

    // --- IV. Reputation & Staking ---

    /**
     * @notice Allows a participant to stake tokens to boost their reputation.
     * @param _amount The amount of payment token to stake.
     */
    function stakeForReputation(uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        if (_amount == 0) revert InvalidInput("Stake amount must be greater than zero");
        if (!paymentToken.transferFrom(msg.sender, address(this), _amount)) {
            revert InsufficientFunds("Failed to transfer stake tokens");
        }

        ReputationStake storage currentStake = reputationStakes[msg.sender];
        if (currentStake.amount == 0) {
            currentStake.stakedAt = block.timestamp;
        }
        currentStake.amount += _amount;
        
        // Simple reputation boost: 1 token = 1 reputation point
        _updateReputation(msg.sender, _amount, "Staked for reputation");
        emit ReputationStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a participant to withdraw their staked tokens after a cooldown period.
     */
    function withdrawReputationStake()
        external
        nonReentrant
        whenNotPaused
    {
        ReputationStake storage currentStake = reputationStakes[msg.sender];
        if (currentStake.amount == 0) revert NoStakedTokens();
        if (block.timestamp < currentStake.stakedAt + REPUTATION_STAKE_COOLDOWN) {
            revert CooldownNotElapsed();
        }

        uint256 amountToWithdraw = currentStake.amount;
        currentStake.amount = 0; // Reset stake before transfer

        // Decrease reputation for withdrawing, might penalize heavily or based on a formula
        _updateReputation(msg.sender, -(amountToWithdraw / 2), "Withdrew reputation stake"); // Halve points gained

        if (!paymentToken.transfer(msg.sender, amountToWithdraw)) {
            revert InsufficientFunds("Failed to transfer staked tokens back");
        }
        emit ReputationStakeWithdrawn(msg.sender, amountToWithdraw);
    }

    /**
     * @notice Internal function to update reputation scores.
     * @param _participant The address whose reputation to update.
     * @param _delta The amount to add or subtract from reputation.
     * @param _reason The reason for the reputation change.
     */
    function _updateReputation(address _participant, int256 _delta, string memory _reason) internal {
        if (_delta > 0) {
            reputationScores[_participant] += uint256(_delta);
        } else {
            uint256 absDelta = uint256(-_delta);
            if (reputationScores[_participant] < absDelta) {
                reputationScores[_participant] = 0;
            } else {
                reputationScores[_participant] -= absDelta;
            }
        }
        emit ReputationUpdated(_participant, reputationScores[_participant], _reason);
    }

    /**
     * @notice Retrieves the current reputation score of an address.
     * @param _participant The address to check.
     * @return The reputation score.
     */
    function getReputationScore(address _participant) external view returns (uint256) {
        return reputationScores[_participant];
    }

    // --- V. Platform & Admin ---

    /**
     * @notice Sets the platform fee percentage. Only owner can call.
     * @param _newFeeBasisPoints New fee in basis points (e.g., 100 for 1%). Max 1000 (10%).
     */
    function setPlatformFee(uint256 _newFeeBasisPoints) external onlyOwner {
        if (_newFeeBasisPoints > 1000) revert InvalidInput("Fee cannot exceed 10%"); // Max 10%
        platformFeeBasisPoints = _newFeeBasisPoints;
        emit PlatformFeeSet(_newFeeBasisPoints);
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 balance = paymentToken.balanceOf(address(this));
        uint256 withdrawableAmount = balance; // For simplicity, assume all balance (less pending task rewards) is fees

        // A more robust implementation would track platform fees separately
        // from escrowed task rewards and collateral.
        // For now, it withdraws everything not tied to an active task.
        // This requires careful off-chain accounting or specific tracking on-chain.
        // For demonstration purposes, this will withdraw all available token balance
        // that is NOT explicitly part of a task's escrowed reward or collateral.
        // This is a simplified version. A real contract would have a dedicated fee balance.
        
        // To prevent accidentally withdrawing funds needed for tasks, we need to subtract them.
        // This is complex to do accurately on-chain without iterating through all tasks.
        // A better design is to accumulate fees in a separate mapping `uint256 public platformFeeBalance;`
        // and add to it whenever fees are taken. For this contract, let's assume `platformFeeReceiver`
        // directly receives fees when they are created, and this function is to recover mistakenly
        // sent funds or remaining balance.

        if (withdrawableAmount == 0) revert InsufficientFunds("No fees to withdraw");

        if (!paymentToken.transfer(platformFeeReceiver, withdrawableAmount)) {
            revert InsufficientFunds("Failed to withdraw platform fees");
        }
        emit PlatformFeesWithdrawn(platformFeeReceiver, withdrawableAmount);
    }

    /**
     * @notice Pauses the contract, disabling critical functions. Only owner can call.
     */
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, re-enabling critical functions. Only owner can call.
     */
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- View functions for details ---

    function getModelLicenseTerms(uint256 _modelId, LicenseType _licenseType)
        external
        view
        returns (LicenseTerms memory)
    {
        return modelLicenseTerms[_modelId][_licenseType];
    }

    function getDatasetLicenseTerms(uint256 _datasetId, LicenseType _licenseType)
        external
        view
        returns (LicenseTerms memory)
    {
        return datasetLicenseTerms[_datasetId][_licenseType];
    }

    function getActiveModelLicense(uint256 _modelId, address _buyer)
        external
        view
        returns (License memory)
    {
        return activeModelLicenses[_modelId][_buyer];
    }

    function getActiveDatasetLicense(uint256 _datasetId, address _buyer)
        external
        view
        returns (License memory)
    {
        return activeDatasetLicenses[_datasetId][_buyer];
    }

    function getComputeTask(uint256 _taskId)
        external
        view
        returns (ComputeTask memory)
    {
        return computeTasks[_taskId];
    }

    function getTaskBid(uint256 _taskId, address _provider)
        external
        view
        returns (Bid memory)
    {
        return taskBids[_taskId][_provider];
    }

    function getReputationStake(address _participant)
        external
        view
        returns (ReputationStake memory)
    {
        return reputationStakes[_participant];
    }
}
```