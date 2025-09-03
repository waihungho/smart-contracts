Here's a Solidity smart contract that implements an advanced, creative, and trendy concept, featuring a decentralized AI model marketplace, collaborative training with reputation incentives, and a simplified DAO governance system. It has more than 20 functions as requested.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using ERC20 as the primary payment token

/**
 * @title AetherMind_AI_Nexus
 * @dev A decentralized platform for AI Model Marketplace, Collaborative Training, and Reputation-weighted Governance.
 *      This contract embodies advanced concepts by enabling a symbiotic ecosystem where:
 *      1.  **AI Model & Dataset Owners** can register their assets, linking to off-chain data (e.g., IPFS),
 *          and set their pricing and royalties.
 *      2.  **Users (Buyers)** can purchase access to approved AI models and datasets.
 *      3.  **Contributors (Trainers)** can engage in collaborative AI training jobs, providing off-chain compute
 *          and submitting verifiable proofs on-chain, earning rewards and building reputation.
 *      4.  **A Reputation System** tracks and rewards valuable contributions, influencing voting power in
 *          governance and potential higher rewards.
 *      5.  **A Simplified DAO Governance** mechanism allows high-reputation members to propose and vote
 *          on crucial platform decisions (e.g., protocol fee changes, model approvals, upgrades).
 *
 *      **Key Advanced Concepts & Creativity:**
 *      -   **Hybrid On-chain/Off-chain Interaction**: Large AI models, datasets, and complex training proofs
 *          are stored off-chain (e.g., IPFS, Arweave), with only their cryptographic hashes, URIs, and
 *          metadata recorded on-chain for verifiability and decentralized access.
 *      -   **Reputation-weighted DAO**: Governance decisions are not purely token-based but influenced by
 *          contributors' proven track record and reputation, encouraging quality and long-term engagement.
 *      -   **Collaborative AI Training Incentives**: A structured system to initiate, contribute to, and
 *          verify distributed AI model training, with dynamic reward distribution based on contribution weight
 *          and success. This is a crucial step towards decentralized AI computation.
 *      -   **Verifiable Computation (Conceptual)**: While concrete ZK-proofs or oracle integrations are complex
 *          for a single contract, the architecture allows for submission of `_proofOfContributionHash` and
 *          `_resultHash`, implying an off-chain verification layer that would validate computational integrity.
 *      -   **Dynamic Royalties & Usage Fees**: Customizable per asset, allowing creators to define their
 *          economic models.
 *      -   **Gamified Progression (Reputation)**: Users gain 'reputation' for successful activities, which
 *          unlocks higher privileges and potentially greater influence/rewards.
 *
 *      The contract uses an ERC20 token (specified by `paymentToken`) for all marketplace transactions
 *      and reward distributions. For real-world advanced verification, a robust oracle network or
 *      ZK-proof system would be integrated for `verifyAndFinalizeTrainingJob`.
 */
contract AetherMind_AI_Nexus is Ownable, Pausable, ReentrancyGuard {

    // --- Outline and Function Summary ---

    // A. Core Platform Management (Owner/Admin roles)
    // 1.  constructor(address _paymentTokenAddress, address _feeCollector): Initializes the contract, sets up roles (Owner, Moderator, FeeCollector), and the payment token.
    // 2.  pauseContract(): Pauses all critical contract functionalities for emergencies.
    // 3.  unpauseContract(): Resumes contract operations.
    // 4.  setProtocolFee(uint256 _newFeeBps): Sets the platform's percentage fee for transactions (in basis points).
    // 5.  withdrawProtocolFees(): Allows the designated FeeCollector to withdraw accumulated platform fees.
    // 6.  addModerator(address _moderator): Grants moderator role, allowing for model/dataset approvals and training job finalization.
    // 7.  removeModerator(address _moderator): Revokes moderator role.

    // B. AI Model & Dataset Registry
    // 8.  registerAIModel(string calldata _ipfsHash, string calldata _metadataUri, uint256 _price, uint256 _royaltyBps): Registers a new AI model, linking to its off-chain data and defining its marketplace parameters.
    // 9.  updateAIModelMetadata(uint256 _modelId, string calldata _newMetadataUri): Model owner updates the descriptive metadata URI of their registered AI model.
    // 10. updateAIModelPricing(uint256 _modelId, uint256 _newPrice, uint256 _newRoyaltyBps): Model owner updates the price and royalty percentage for their AI model.
    // 11. registerDataset(string calldata _ipfsHash, string calldata _metadataUri, uint256 _price, uint256 _usageRightsBps): Registers a new dataset, linking to its off-chain data and defining its marketplace parameters.
    // 12. updateDatasetMetadata(uint256 _datasetId, string calldata _newMetadataUri): Dataset owner updates the descriptive metadata URI of their registered dataset.
    // 13. updateDatasetPricing(uint256 _datasetId, uint256 _newPrice, uint256 _newUsageRightsBps): Dataset owner updates the price and usage rights percentage for their dataset.

    // C. Marketplace Operations
    // 14. purchaseAIModel(uint256 _modelId): Allows users to purchase access to an approved AI model.
    // 15. purchaseDatasetAccess(uint256 _datasetId): Allows users to purchase access rights to an approved dataset.

    // D. Collaborative AI Training & Reputation
    // 16. initiateTrainingJob(uint256 _modelId, uint256 _datasetId, uint256 _rewardPool, string calldata _requirementsHash): Initiates a new collaborative training task, specifying the target model, dataset, reward pool, and off-chain requirements.
    // 17. contributeToTrainingJob(uint256 _jobId, string calldata _proofOfContributionHash): Users submit proof (hash) of their off-chain computational or data contribution to an active training job.
    // 18. submitTrainingCompletionProof(uint256 _jobId, string calldata _resultHash): The designated lead contributor submits the final proof (hash) of job completion and results.
    // 19. verifyAndFinalizeTrainingJob(uint256 _jobId, bool _isSuccessful): Moderator (or DAO via proposal) verifies the job's outcome, distributes rewards, and updates asset/contributor reputation.
    // 20. claimTrainingRewards(uint256 _jobId): Contributors claim their portion of the reward pool after a job is successfully finalized.
    // 21. getContributorReputation(address _contributor) (view): Retrieves the current reputation score of a specific contributor.

    // E. Decentralized Governance (Simplified DAO)
    // 22. createGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _callData, uint256 _value): Allows high-reputation users to propose a governance action, defining target contract, call data, and optional value.
    // 23. voteOnProposal(uint256 _proposalId, bool _for): Users with sufficient reputation vote "for" or "against" an active proposal, with their voting power weighted by their reputation score.
    // 24. executeProposal(uint256 _proposalId): Executes a passed governance proposal after its voting period has concluded.

    // --- Custom Errors ---
    error InvalidFeePercentage();
    error NotModerator();
    error ModelNotFound(uint256 modelId);
    error DatasetNotFound(uint256 datasetId);
    error NotModelOwner(uint256 modelId);
    error NotDatasetOwner(uint256 datasetId);
    error ModelNotApproved(uint256 modelId);
    error DatasetNotApproved(uint256 datasetId);
    error InsufficientFunds(uint256 required, uint256 available);
    error TransferFailed();
    error AlreadyPurchased();
    error UnauthorizedAccess(); // Generic for initiator not having model/dataset access
    error TrainingJobNotFound(uint256 jobId);
    error NotTrainingJobInitiator(uint256 jobId); // Specific error not currently used, but good to have
    error TrainingJobNotActive(uint256 jobId);
    error TrainingJobAlreadyCompleted(uint256 jobId); // Specific error not currently used
    error AlreadyContributedToJob(uint256 jobId);
    error NoOutstandingRewards(uint256 jobId);
    error NotJobContributor(uint256 jobId);
    error ProofAlreadySubmitted();
    error CannotVerifyActiveJob();
    error TrainingJobNotVerified();
    error ProposalNotFound(uint256 proposalId);
    error InsufficientReputationForProposal(uint256 required, uint256 current);
    error AlreadyVoted(uint256 proposalId);
    error VotingPeriodNotOver(uint256 proposalId);
    error ProposalNotApproved(uint256 proposalId); // For proposals that failed voting
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalExecutionFailed();
    error InsufficientReputationForVote(uint256 required, uint256 current);
    error ModeratorCannotBeRemoved(address moderatorAddress);
    error ZeroRewardPool();

    // --- State Variables ---

    IERC20 public immutable paymentToken;
    address public feeCollector; // Address to collect protocol fees
    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 200 = 2%)
    uint256 public constant MAX_BPS = 10000; // Represents 100% for basis point calculations

    // Roles: Owner (from Ownable), FeeCollector, and Moderators
    mapping(address => bool) public moderators;

    // AI Models Registry
    struct AIModel {
        address owner;
        string ipfsHash;        // IPFS hash of the actual model weights/binaries
        string metadataUri;     // URI to descriptive metadata (e.g., JSON on IPFS)
        uint256 price;          // Price in paymentToken
        uint256 royaltyBps;     // Royalty percentage (in basis points) for future secondary sales/usage if applicable
        bool approved;          // Approved by moderators/DAO to be visible/purchasable
        uint256 reputationScore; // Quality/usefulness score, updated after successful training jobs
        uint256 version;        // Model version, incremented on significant updates/successful retraining
        uint256 createdAt;
    }
    uint256 public nextModelId;
    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => mapping(address => bool)) public modelPurchasers; // modelId => purchaserAddress => hasAccess

    // Datasets Registry
    struct Dataset {
        address owner;
        string ipfsHash;        // IPFS hash of the actual dataset files
        string metadataUri;     // URI to descriptive metadata (e.g., JSON on IPFS)
        uint256 price;          // Price in paymentToken for access rights
        uint256 usageRightsBps; // Percentage (in basis points) paid to dataset owner for its usage in training jobs
        bool approved;          // Approved by moderators/DAO to be visible/purchasable
        uint256 reputationScore; // Quality/usefulness score, updated after successful training jobs
        uint256 createdAt;
    }
    uint256 public nextDatasetId;
    mapping(uint256 => Dataset) public datasets;
    mapping(uint256 => mapping(address => bool)) public datasetAccessHolders; // datasetId => purchaserAddress => hasAccess

    // Contributors & Reputation System
    struct Contributor {
        uint256 reputation; // Overall reputation score, influencing voting power and rewards
        uint256 lastActivity; // Timestamp of last significant contribution/action
    }
    mapping(address => Contributor) public contributors;
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 1000; // Reputation required to create a governance proposal
    uint256 public constant MIN_REPUTATION_FOR_VOTE = 100;     // Reputation required to vote on proposals

    // Collaborative Training Jobs
    enum TrainingJobStatus { Active, Completed, Failed, Verified }
    struct TrainingJob {
        address initiator;          // Address of the user who initiated the training job
        uint256 modelId;            // ID of the AI model being trained
        uint256 datasetId;          // ID of the dataset used for training
        uint256 rewardPool;         // Total reward in paymentToken for contributors
        string requirementsHash;    // IPFS hash of detailed job requirements (e.g., compute spec, metrics)
        TrainingJobStatus status;
        uint256 createdAt;
        uint256 completionTimestamp; // Timestamp when completion proof was submitted
        string resultHash;          // IPFS hash of the verified training result (e.g., new model weights, metrics)
        mapping(address => uint256) contributions; // Contributor address => their contributed weight/score
        address[] contributorsList; // To efficiently iterate over contributors for reward distribution
        address leadContributor;    // The contributor who submitted the final training result
        uint256 totalContributionWeight; // Sum of all contributions for reward distribution
    }
    uint256 public nextTrainingJobId;
    mapping(uint256 => TrainingJob) public trainingJobs;

    // Mapping to store unclaimed rewards for each job and contributor (pull mechanism)
    mapping(uint256 => mapping(address => uint256)) private _unclaimedTrainingRewards; // jobId => contributor => amount

    // Governance Proposals (Simplified DAO)
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        address proposer;
        string description;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        uint256 forVotes;          // Total reputation-weighted votes for the proposal
        uint256 againstVotes;      // Total reputation-weighted votes against the proposal
        bool executed;
        address target;            // Target contract address for the proposal's execution
        bytes callData;            // Encoded function call data for the target contract
        uint256 value;             // ETH value (native currency) to send with the call, if any
        ProposalState state;
        mapping(address => bool) hasVoted; // User => hasVoted (to prevent double-voting)
    }
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant VOTING_PERIOD = 3 days; // Example voting period duration

    // --- Events ---
    event ProtocolFeeSet(uint256 newFeeBps);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);
    event ModeratorAdded(address indexed moderator);
    event ModeratorRemoved(address indexed moderator);

    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string ipfsHash, uint256 price);
    event AIModelMetadataUpdated(uint256 indexed modelId, string newMetadataUri);
    event AIModelPricingUpdated(uint252 indexed modelId, uint256 newPrice, uint256 newRoyaltyBps);
    event AIModelPurchased(uint256 indexed modelId, address indexed buyer, uint256 amount);
    event AIModelApprovalSet(uint256 indexed modelId, bool approved);

    event DatasetRegistered(uint256 indexed datasetId, address indexed owner, string ipfsHash, uint256 price);
    event DatasetMetadataUpdated(uint256 indexed datasetId, string newMetadataUri);
    event DatasetPricingUpdated(uint256 indexed datasetId, uint256 newPrice, uint256 newUsageRightsBps);
    event DatasetAccessPurchased(uint256 indexed datasetId, address indexed buyer, uint256 amount);
    event DatasetApprovalSet(uint256 indexed datasetId, bool approved);

    event TrainingJobInitiated(uint256 indexed jobId, address indexed initiator, uint256 modelId, uint256 datasetId, uint256 rewardPool);
    event ContributionSubmitted(uint256 indexed jobId, address indexed contributor, uint256 weight);
    event TrainingCompletionProofSubmitted(uint256 indexed jobId, address indexed leadContributor, string resultHash);
    event TrainingJobFinalized(uint256 indexed jobId, bool successful, string resultHash);
    event RewardsClaimed(uint256 indexed jobId, address indexed contributor, uint256 amount);
    event ReputationUpdated(address indexed contributor, uint256 newReputation);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool _for, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- Modifiers ---
    modifier onlyModerator() {
        if (!moderators[msg.sender]) revert NotModerator();
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        if (aiModels[_modelId].owner == address(0)) revert ModelNotFound(_modelId);
        if (aiModels[_modelId].owner != msg.sender) revert NotModelOwner(_modelId);
        _;
    }

    modifier onlyDatasetOwner(uint256 _datasetId) {
        if (datasets[_datasetId].owner == address(0)) revert DatasetNotFound(_datasetId);
        if (datasets[_datasetId].owner != msg.sender) revert NotDatasetOwner(_datasetId);
        _;
    }

    // --- Constructor ---
    constructor(address _paymentTokenAddress, address _feeCollector) Ownable(msg.sender) {
        if (_paymentTokenAddress == address(0) || _feeCollector == address(0)) {
            revert OwnableInvalidOwner(address(0)); // Reusing Ownable error for 0x0 address
        }
        paymentToken = IERC20(_paymentTokenAddress);
        feeCollector = _feeCollector;
        protocolFeeBps = 200; // 2% initial protocol fee
        moderators[msg.sender] = true; // Owner is initially a moderator
    }

    // --- A. Core Platform Management ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     * Prevents most state-changing operations during emergencies.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     * Resumes normal operations.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the protocol fee percentage in basis points (BPS).
     * @param _newFeeBps The new fee percentage (e.g., 200 for 2%). Must be <= MAX_BPS.
     * Callable by owner or via governance.
     */
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        if (_newFeeBps > MAX_BPS) revert InvalidFeePercentage();
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeSet(_newFeeBps);
    }

    /**
     * @dev Allows the designated fee collector to withdraw accumulated protocol fees.
     * Fees are collected from marketplace transactions.
     */
    function withdrawProtocolFees() external nonReentrant {
        if (msg.sender != feeCollector) revert("AetherMind: Only fee collector can withdraw fees.");

        uint256 accumulatedFees = paymentToken.balanceOf(address(this)) - _totalLockedForRewards();
        
        if (accumulatedFees == 0) return;

        if (!paymentToken.transfer(feeCollector, accumulatedFees)) revert TransferFailed();
        emit ProtocolFeesWithdrawn(feeCollector, accumulatedFees);
    }

    /**
     * @dev Internal helper to calculate total tokens locked in active or completed training job reward pools.
     * This prevents fees from accidentally withdrawing funds earmarked for rewards.
     */
    function _totalLockedForRewards() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= nextTrainingJobId; i++) {
            TrainingJob storage job = trainingJobs[i];
            if (job.status == TrainingJobStatus.Active || job.status == TrainingJobStatus.Completed) {
                total += job.rewardPool;
            }
        }
        return total;
    }

    /**
     * @dev Grants the moderator role to an address. Only callable by the owner.
     * Moderators can approve models/datasets and finalize training jobs (a simplified DAO mechanism).
     * @param _moderator The address to grant moderator role.
     */
    function addModerator(address _moderator) external onlyOwner {
        moderators[_moderator] = true;
        emit ModeratorAdded(_moderator);
    }

    /**
     * @dev Revokes the moderator role from an address. Only callable by the owner.
     * The contract owner cannot remove themselves from the moderator role.
     * @param _moderator The address to revoke moderator role.
     */
    function removeModerator(address _moderator) external onlyOwner {
        if (_moderator == owner()) revert ModeratorCannotBeRemoved(_moderator); // Owner is always a moderator implicitly
        moderators[_moderator] = false;
        emit ModeratorRemoved(_moderator);
    }

    // --- B. AI Model & Dataset Registry ---

    /**
     * @dev Registers a new AI model on the platform.
     * The model is initially unapproved and not available for purchase.
     * Requires linking to off-chain data via IPFS hash and metadata URI.
     * @param _ipfsHash IPFS hash of the actual model weights/binaries.
     * @param _metadataUri URI to descriptive metadata (e.g., JSON on IPFS with details, usage instructions).
     * @param _price Price of the model in paymentToken.
     * @param _royaltyBps Royalty percentage (in basis points) for future secondary sales/usage.
     */
    function registerAIModel(
        string calldata _ipfsHash,
        string calldata _metadataUri,
        uint256 _price,
        uint256 _royaltyBps
    ) external whenNotPaused {
        if (_royaltyBps > MAX_BPS) revert InvalidFeePercentage();
        nextModelId++;
        aiModels[nextModelId] = AIModel({
            owner: msg.sender,
            ipfsHash: _ipfsHash,
            metadataUri: _metadataUri,
            price: _price,
            royaltyBps: _royaltyBps,
            approved: false, // Requires moderator/DAO approval before becoming active
            reputationScore: 0,
            version: 1,
            createdAt: block.timestamp
        });
        emit AIModelRegistered(nextModelId, msg.sender, _ipfsHash, _price);
    }

    /**
     * @dev Updates the metadata URI for an existing AI model.
     * Only callable by the model owner.
     * @param _modelId The ID of the model to update.
     * @param _newMetadataUri The new URI for descriptive metadata.
     */
    function updateAIModelMetadata(uint256 _modelId, string calldata _newMetadataUri)
        external
        whenNotPaused
        onlyModelOwner(_modelId)
    {
        aiModels[_modelId].metadataUri = _newMetadataUri;
        emit AIModelMetadataUpdated(_modelId, _newMetadataUri);
    }

    /**
     * @dev Updates the price and royalty percentage for an existing AI model.
     * Only callable by the model owner.
     * @param _modelId The ID of the model to update.
     * @param _newPrice The new price in paymentToken.
     * @param _newRoyaltyBps The new royalty percentage in basis points.
     */
    function updateAIModelPricing(uint256 _modelId, uint256 _newPrice, uint256 _newRoyaltyBps)
        external
        whenNotPaused
        onlyModelOwner(_modelId)
    {
        if (_newRoyaltyBps > MAX_BPS) revert InvalidFeePercentage();
        aiModels[_modelId].price = _newPrice;
        aiModels[_modelId].royaltyBps = _newRoyaltyBps;
        emit AIModelPricingUpdated(_modelId, _newPrice, _newRoyaltyBps);
    }

    /**
     * @dev Registers a new dataset on the platform.
     * The dataset is initially unapproved.
     * Requires linking to off-chain data via IPFS hash and metadata URI.
     * @param _ipfsHash IPFS hash of the actual dataset files.
     * @param _metadataUri URI to descriptive metadata.
     * @param _price Price of the dataset access in paymentToken.
     * @param _usageRightsBps Percentage (in basis points) paid to dataset owner for its usage in training jobs.
     */
    function registerDataset(
        string calldata _ipfsHash,
        string calldata _metadataUri,
        uint256 _price,
        uint256 _usageRightsBps
    ) external whenNotPaused {
        if (_usageRightsBps > MAX_BPS) revert InvalidFeePercentage();
        nextDatasetId++;
        datasets[nextDatasetId] = Dataset({
            owner: msg.sender,
            ipfsHash: _ipfsHash,
            metadataUri: _metadataUri,
            price: _price,
            usageRightsBps: _usageRightsBps,
            approved: false, // Requires moderator/DAO approval before becoming active
            reputationScore: 0,
            createdAt: block.timestamp
        });
        emit DatasetRegistered(nextDatasetId, msg.sender, _ipfsHash, _price);
    }

    /**
     * @dev Updates the metadata URI for an existing dataset.
     * Only callable by the dataset owner.
     * @param _datasetId The ID of the dataset to update.
     * @param _newMetadataUri The new URI for descriptive metadata.
     */
    function updateDatasetMetadata(uint256 _datasetId, string calldata _newMetadataUri)
        external
        whenNotPaused
        onlyDatasetOwner(_datasetId)
    {
        datasets[_datasetId].metadataUri = _newMetadataUri;
        emit DatasetMetadataUpdated(_datasetId, _newMetadataUri);
    }

    /**
     * @dev Updates the price and usage rights percentage for an existing dataset.
     * Only callable by the dataset owner.
     * @param _datasetId The ID of the dataset to update.
     * @param _newPrice The new price in paymentToken.
     * @param _newUsageRightsBps The new usage rights percentage in basis points.
     */
    function updateDatasetPricing(uint256 _datasetId, uint256 _newPrice, uint256 _newUsageRightsBps)
        external
        whenNotPaused
        onlyDatasetOwner(_datasetId)
    {
        if (_newUsageRightsBps > MAX_BPS) revert InvalidFeePercentage();
        datasets[_datasetId].price = _newPrice;
        datasets[_datasetId].usageRightsBps = _newUsageRightsBps;
        emit DatasetPricingUpdated(_datasetId, _newPrice, _newUsageRightsBps);
    }

    // --- C. Marketplace Operations ---

    /**
     * @dev Allows a user to purchase an approved AI model.
     * Transfers tokens from buyer to the contract. Model owner and protocol fees
     * are distributed from the contract's balance.
     * @param _modelId The ID of the AI model to purchase.
     */
    function purchaseAIModel(uint256 _modelId) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(_modelId);
        if (!model.approved) revert ModelNotApproved(_modelId);
        if (modelPurchasers[_modelId][msg.sender]) revert AlreadyPurchased();

        uint256 totalPrice = model.price;
        uint256 fee = (totalPrice * protocolFeeBps) / MAX_BPS;
        uint256 ownerShare = totalPrice - fee;

        if (paymentToken.balanceOf(msg.sender) < totalPrice) revert InsufficientFunds(totalPrice, paymentToken.balanceOf(msg.sender));
        // Transfer tokens from buyer to the contract first
        if (!paymentToken.transferFrom(msg.sender, address(this), totalPrice)) revert TransferFailed();

        // Transfer owner's share. Protocol fees remain in contract until `withdrawProtocolFees` is called.
        if (!paymentToken.transfer(model.owner, ownerShare)) revert TransferFailed();

        modelPurchasers[_modelId][msg.sender] = true;
        emit AIModelPurchased(_modelId, msg.sender, totalPrice);
    }

    /**
     * @dev Allows a user to purchase access rights to an approved dataset.
     * Transfers tokens from buyer to the contract. Dataset owner and protocol fees
     * are distributed from the contract's balance.
     * @param _datasetId The ID of the dataset to purchase access for.
     */
    function purchaseDatasetAccess(uint256 _datasetId) external whenNotPaused nonReentrant {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0)) revert DatasetNotFound(_datasetId);
        if (!dataset.approved) revert DatasetNotApproved(_datasetId);
        if (datasetAccessHolders[_datasetId][msg.sender]) revert AlreadyPurchased();

        uint256 totalPrice = dataset.price;
        uint256 fee = (totalPrice * protocolFeeBps) / MAX_BPS;
        uint256 ownerShare = totalPrice - fee;

        if (paymentToken.balanceOf(msg.sender) < totalPrice) revert InsufficientFunds(totalPrice, paymentToken.balanceOf(msg.sender));
        // Transfer tokens from buyer to the contract first
        if (!paymentToken.transferFrom(msg.sender, address(this), totalPrice)) revert TransferFailed();

        // Transfer owner's share. Protocol fees remain in contract until `withdrawProtocolFees` is called.
        if (!paymentToken.transfer(dataset.owner, ownerShare)) revert TransferFailed();

        datasetAccessHolders[_datasetId][msg.sender] = true;
        emit DatasetAccessPurchased(_datasetId, msg.sender, totalPrice);
    }

    // --- D. Collaborative AI Training & Reputation ---

    /**
     * @dev Initiates a new collaborative training job.
     * The initiator must either own or have purchased access to both the model and the dataset.
     * The `_rewardPool` amount is transferred to the contract from the initiator as an incentive.
     * @param _modelId The AI model to be trained.
     * @param _datasetId The dataset to be used for training.
     * @param _rewardPool The total reward in paymentToken for contributors upon successful completion.
     * @param _requirementsHash IPFS hash detailing job requirements (e.g., specific algorithms, compute resources, evaluation metrics).
     */
    function initiateTrainingJob(
        uint256 _modelId,
        uint256 _datasetId,
        uint256 _rewardPool,
        string calldata _requirementsHash
    ) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        Dataset storage dataset = datasets[_datasetId];

        if (model.owner == address(0)) revert ModelNotFound(_modelId);
        if (dataset.owner == address(0)) revert DatasetNotFound(_datasetId);
        if (!model.approved) revert ModelNotApproved(_modelId);
        if (!dataset.approved) revert DatasetNotApproved(_datasetId);

        // Initiator must own or have purchased access to both assets
        bool hasModelAccess = (model.owner == msg.sender || modelPurchasers[_modelId][msg.sender]);
        bool hasDatasetAccess = (dataset.owner == msg.sender || datasetAccessHolders[_datasetId][msg.sender]);

        if (!hasModelAccess || !hasDatasetAccess) {
             revert UnauthorizedAccess();
        }

        if (_rewardPool == 0) revert ZeroRewardPool();

        // Transfer reward tokens to the contract
        if (paymentToken.balanceOf(msg.sender) < _rewardPool) revert InsufficientFunds(_rewardPool, paymentToken.balanceOf(msg.sender));
        if (!paymentToken.transferFrom(msg.sender, address(this), _rewardPool)) revert TransferFailed();

        nextTrainingJobId++;
        trainingJobs[nextTrainingJobId] = TrainingJob({
            initiator: msg.sender,
            modelId: _modelId,
            datasetId: _datasetId,
            rewardPool: _rewardPool,
            requirementsHash: _requirementsHash,
            status: TrainingJobStatus.Active,
            createdAt: block.timestamp,
            completionTimestamp: 0,
            resultHash: "",
            contributorsList: new address[](0),
            leadContributor: address(0),
            totalContributionWeight: 0
        });

        emit TrainingJobInitiated(nextTrainingJobId, msg.sender, _modelId, _datasetId, _rewardPool);
    }

    /**
     * @dev Allows a user to contribute computational power or data to an active training job.
     * The `_proofOfContributionHash` is an IPFS hash of verifiable evidence of work (e.g., ZK-proof, attestations).
     * This function only records the intent and proof hash; actual off-chain work is expected.
     * Reputation is updated upon successful contribution.
     * @param _jobId The ID of the training job.
     * @param _proofOfContributionHash IPFS hash of the proof of contribution.
     */
    function contributeToTrainingJob(uint256 _jobId, string calldata _proofOfContributionHash)
        external
        whenNotPaused
    {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.initiator == address(0)) revert TrainingJobNotFound(_jobId);
        if (job.status != TrainingJobStatus.Active) revert TrainingJobNotActive(_jobId);
        if (job.contributions[msg.sender] > 0) revert AlreadyContributedToJob(_jobId); // Each user can contribute once per job

        // In a real system, the contribution 'weight' would be derived from the proof or a complex metric.
        // For simplicity, we assign a base contribution weight and add a reputation bonus.
        // A more advanced system would likely use a verifiable computation oracle or ZKP to attest to this.
        uint256 contributionWeight = 100 + (contributors[msg.sender].reputation / 100); // Base 100 + 1 point per 100 rep

        job.contributions[msg.sender] = contributionWeight;
        job.contributorsList.push(msg.sender);
        job.totalContributionWeight += contributionWeight;

        // Small immediate reputation boost for contributing
        contributors[msg.sender].reputation += 10;
        contributors[msg.sender].lastActivity = block.timestamp;
        emit ReputationUpdated(msg.sender, contributors[msg.sender].reputation);
        emit ContributionSubmitted(_jobId, msg.sender, contributionWeight);
    }

    /**
     * @dev Submits the final proof of training completion for a job.
     * This is typically done by the contributor who aggregated results or completed the final step.
     * The `_resultHash` would be an IPFS hash to the new model weights or an evaluation report.
     * Only one lead contributor can submit the completion proof per job.
     * @param _jobId The ID of the training job.
     * @param _resultHash IPFS hash of the final training results.
     */
    function submitTrainingCompletionProof(uint256 _jobId, string calldata _resultHash)
        external
        whenNotPaused
    {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.initiator == address(0)) revert TrainingJobNotFound(_jobId);
        if (job.status != TrainingJobStatus.Active) revert TrainingJobNotActive(_jobId);
        if (job.leadContributor != address(0)) revert ProofAlreadySubmitted();
        // Only the initiator or a registered contributor can submit the final proof
        if (job.contributions[msg.sender] == 0 && job.initiator != msg.sender) revert NotJobContributor(_jobId);

        job.leadContributor = msg.sender;
        job.resultHash = _resultHash;
        job.status = TrainingJobStatus.Completed; // Move to completed, awaiting verification
        job.completionTimestamp = block.timestamp;

        // Increase reputation for submitting the completion proof
        contributors[msg.sender].reputation += 50;
        contributors[msg.sender].lastActivity = block.timestamp;
        emit ReputationUpdated(msg.sender, contributors[msg.sender].reputation);
        emit TrainingCompletionProofSubmitted(_jobId, msg.sender, _resultHash);
    }

    /**
     * @dev Verifies the outcome of a training job and finalizes reward distribution.
     * This function would ideally be called by a decentralized oracle network or a DAO vote.
     * For simplicity, it's currently restricted to a Moderator.
     * If successful, rewards are distributed to contributors; if not, the reward pool is returned to the initiator.
     * Updates model/dataset reputation based on job outcome.
     * @param _jobId The ID of the training job to verify.
     * @param _isSuccessful True if the training was successful, false otherwise.
     */
    function verifyAndFinalizeTrainingJob(uint256 _jobId, bool _isSuccessful)
        external
        whenNotPaused
        onlyModerator // Simplified: A real system might use a DAO vote or oracle
        nonReentrant
    {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.initiator == address(0)) revert TrainingJobNotFound(_jobId);
        if (job.status != TrainingJobStatus.Completed) revert CannotVerifyActiveJob();

        job.status = TrainingJobStatus.Verified; // Mark as verified

        AIModel storage model = aiModels[job.modelId];
        Dataset storage dataset = datasets[job.datasetId];

        if (_isSuccessful) {
            // Update model and dataset reputation
            model.reputationScore += 100; // Significant boost for the model
            model.version++; // Increment model version upon successful training and update
            dataset.reputationScore += 20; // Dataset also gets a small boost for being used in successful training

            uint256 totalRewardForDistribution = job.rewardPool;
            
            // Deduct dataset owner's share (usage rights) first
            uint256 datasetUsageFee = (totalRewardForDistribution * dataset.usageRightsBps) / MAX_BPS;
            if (datasetUsageFee > 0) {
                if (!paymentToken.transfer(dataset.owner, datasetUsageFee)) revert TransferFailed();
                totalRewardForDistribution -= datasetUsageFee;
            }

            // Distribute remaining rewards to contributors based on their weight
            if (job.totalContributionWeight > 0) {
                for (uint256 i = 0; i < job.contributorsList.length; i++) {
                    address contributor = job.contributorsList[i];
                    uint256 contributorWeight = job.contributions[contributor];
                    uint256 share = (totalRewardForDistribution * contributorWeight) / job.totalContributionWeight;
                    
                    _unclaimedTrainingRewards[_jobId][contributor] += share; // Store for pull mechanism

                    // Add significant reputation for successful contribution
                    contributors[contributor].reputation += 100;
                    contributors[contributor].lastActivity = block.timestamp;
                    emit ReputationUpdated(contributor, contributors[contributor].reputation);
                }
            }

            // Also give a reputation boost to the job initiator for a successful job
            contributors[job.initiator].reputation += 75;
            contributors[job.initiator].lastActivity = block.timestamp;
            emit ReputationUpdated(job.initiator, contributors[job.initiator].reputation);

        } else {
            // Training failed, return the full reward pool to the initiator
            if (!paymentToken.transfer(job.initiator, job.rewardPool)) revert TransferFailed();
            
            // Penalize reputation for the lead contributor if failure was due to their poor work
            if (job.leadContributor != address(0)) {
                contributors[job.leadContributor].reputation = contributors[job.leadContributor].reputation >= 100 ? contributors[job.leadContributor].reputation - 100 : 0;
                emit ReputationUpdated(job.leadContributor, contributors[job.leadContributor].reputation);
            }
        }
        emit TrainingJobFinalized(_jobId, _isSuccessful, job.resultHash);
    }

    /**
     * @dev Allows a contributor to claim their portion of the reward pool for a finalized training job.
     * Uses a pull mechanism for security.
     * @param _jobId The ID of the training job.
     */
    function claimTrainingRewards(uint256 _jobId) external whenNotPaused nonReentrant {
        TrainingJob storage job = trainingJobs[_jobId];
        if (job.initiator == address(0)) revert TrainingJobNotFound(_jobId);
        if (job.status != TrainingJobStatus.Verified) revert TrainingJobNotVerified();

        uint256 amount = _unclaimedTrainingRewards[_jobId][msg.sender];
        if (amount == 0) revert NoOutstandingRewards(_jobId);

        _unclaimedTrainingRewards[_jobId][msg.sender] = 0; // Reset claimed amount
        if (!paymentToken.transfer(msg.sender, amount)) revert TransferFailed();

        emit RewardsClaimed(_jobId, msg.sender, amount);
    }

    /**
     * @dev Retrieves the current reputation score for a given contributor.
     * @param _contributor The address of the contributor.
     * @return The reputation score.
     */
    function getContributorReputation(address _contributor) external view returns (uint256) {
        return contributors[_contributor].reputation;
    }

    // --- E. Decentralized Governance (Simplified DAO) ---

    /**
     * @dev Creates a new governance proposal.
     * Only users with sufficient reputation can propose.
     * @param _description A description of the proposal.
     * @param _targetContract The address of the contract to call if the proposal passes (e.g., this contract for internal changes).
     * @param _callData The encoded function call data for the target contract.
     * @param _value The value (native currency, e.g., ETH) to send with the call, if applicable.
     * @return The ID of the newly created proposal.
     */
    function createGovernanceProposal(
        string calldata _description,
        address _targetContract,
        bytes calldata _callData,
        uint256 _value
    ) external whenNotPaused returns (uint256) {
        if (contributors[msg.sender].reputation < MIN_REPUTATION_FOR_PROPOSAL) {
            revert InsufficientReputationForProposal(MIN_REPUTATION_FOR_PROPOSAL, contributors[msg.sender].reputation);
        }

        nextProposalId++;
        proposals[nextProposalId] = Proposal({
            proposer: msg.sender,
            description: _description,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + VOTING_PERIOD,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            target: _targetContract,
            callData: _callData,
            value: _value,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool)() // Initialize empty mapping
        });

        emit GovernanceProposalCreated(nextProposalId, msg.sender, _description);
        return nextProposalId;
    }

    /**
     * @dev Allows a user to vote on an active governance proposal.
     * Voting power is weighted by the user's current reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True to vote "for" the proposal, false to vote "against".
     */
    function voteOnProposal(uint256 _proposalId, bool _for) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId); // Check if proposal exists
        if (proposal.state != ProposalState.Active) revert("AetherMind: Proposal not active for voting.");
        if (block.timestamp >= proposal.votingPeriodEnd) revert VotingPeriodNotOver(_proposalId);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(_proposalId);
        if (contributors[msg.sender].reputation < MIN_REPUTATION_FOR_VOTE) {
            revert InsufficientReputationForVote(MIN_REPUTATION_FOR_VOTE, contributors[msg.sender].reputation);
        }

        uint256 voteWeight = contributors[msg.sender].reputation;

        if (_for) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _for, voteWeight);
    }

    /**
     * @dev Executes a governance proposal if it has passed its voting period and gathered enough "for" votes.
     * Only callable after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound(_proposalId);
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted(_proposalId);
        if (block.timestamp < proposal.votingPeriodEnd) revert VotingPeriodNotOver(_proposalId);

        // Determine outcome based on reputation-weighted votes
        if (proposal.forVotes > proposal.againstVotes) { // Simple majority for now
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
        }

        if (proposal.state != ProposalState.Succeeded) revert ProposalNotApproved(_proposalId);

        // Execute the proposal's call to the target contract
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        if (!success) revert ProposalExecutionFailed();

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    // --- Internal/Helper Functions for DAO/Moderator Actions (targets for proposals) ---

    /**
     * @dev Approves or unapproves an AI model, making it available/unavailable for purchase.
     * Intended to be called by a moderator or via a passed governance proposal.
     * @param _modelId The ID of the model to approve/unapprove.
     * @param _approve True to approve, false to unapprove (deprecate).
     */
    function _setAIModelApproval(uint256 _modelId, bool _approve) external onlyModerator {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert ModelNotFound(_modelId);
        model.approved = _approve;
        emit AIModelApprovalSet(_modelId, _approve);
    }

    /**
     * @dev Approves or unapproves a dataset, making it available/unavailable for purchase/usage.
     * Intended to be called by a moderator or via a passed governance proposal.
     * @param _datasetId The ID of the dataset to approve/unapprove.
     * @param _approve True to approve, false to unapprove (deprecate).
     */
    function _setDatasetApproval(uint256 _datasetId, bool _approve) external onlyModerator {
        Dataset storage dataset = datasets[_datasetId];
        if (dataset.owner == address(0)) revert DatasetNotFound(_datasetId);
        dataset.approved = _approve;
        emit DatasetApprovalSet(_datasetId, _approve);
    }
}
```