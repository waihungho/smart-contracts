This smart contract, `SynergyMindAI`, orchestrates a decentralized marketplace and collaborative platform for AI models. It enables users to register AI models as NFTs, contribute datasets for training, offer compute resources, and collectively train models with verifiable proofs. The platform incorporates a utility/governance token (`SYNERGY`), a reputation-like staking mechanism, and a simplified DAO for protocol parameter adjustments.

---

## Contract: `SynergyMindAI`

**Outline:**

*   **Core Infrastructure:** Handles contract ownership, pausing for emergencies, and setting up external oracle integration.
*   **Token Management (Delegated):** Interacts with `SynergyToken` (ERC-20) for utility and governance, and `AIModelNFT` (ERC-721) for representing AI models.
*   **AI Model Lifecycle:** Functions for registering new AI models as NFTs, updating their metadata, and deactivating them.
*   **AI Model Marketplace & Access:** Allows users to subscribe to AI models for recurring access or purchase one-off inference credits.
*   **Data Contribution:** Enables users to register datasets that can be used for model training, earning rewards.
*   **Compute Provisioning:** Facilitates the registration of compute nodes by providers, requiring a stake and defining hourly rates.
*   **Training Job Orchestration:** Manages the entire lifecycle of an AI model training job, from proposal and approval to completion reporting and proof verification by an oracle.
*   **Rewards & Staking:** Defines mechanisms for distributing `SYNERGY` rewards to model owners, dataset contributors, and compute providers, and manages staking/un-staking with an unbonding period.
*   **Governance (Simplified DAO):** Allows `SYNERGY` token holders to propose and vote on changes to key contract parameters.

---

**Function Summary:**

1.  **`constructor(uint256 initialSynergySupply)`**: Deploys and initializes the `SynergyToken` (ERC-20) and `AIModelNFT` (ERC-721) contracts, setting the initial `SynergyMindAI` contract owner.
2.  **`setOracleAddress(address _oracle)`**: (Owner-only) Sets the address of a trusted off-chain oracle responsible for verifying the authenticity and success of training job proofs.
3.  **`pause()`**: (Owner-only) Pauses most contract functionalities in case of an emergency, preventing new interactions.
4.  **`unpause()`**: (Owner-only) Resumes contract functionalities after being paused.
5.  **`getTokenBalance(address _user) view`**: Returns the `SYNERGY` token balance of a specified user.
6.  **`transferSynergy(address _to, uint256 _amount)`**: Initiates a standard ERC-20 `transfer` of `SYNERGY` tokens from the caller to a recipient.
7.  **`registerAIModel(string calldata _modelURI, bytes32 _modelHash, uint256 _stakeAmount, uint256 _inferencePrice, uint256 _subscriptionFee)`**: Mints a new `AIM` NFT representing an AI model. Requires the model owner to stake `SYNERGY` tokens and defines pricing for model access.
8.  **`updateAIModelMetadata(uint256 _tokenId, string calldata _newModelURI, bytes32 _newModelHash)`**: Allows the owner of an `AIM` NFT to update its associated metadata (e.g., new version, description).
9.  **`deactivateAIModel(uint256 _tokenId)`**: Marks an `AIM` NFT as inactive, preventing further subscriptions or inference purchases for that model.
10. **`subscribeToModel(uint256 _tokenId, uint256 _durationMonths)`**: Allows a user to subscribe to an AI model for a specified number of months, paying the model's monthly subscription fee in `SYNERGY`.
11. **`buyModelInference(uint256 _tokenId, uint256 _numInferences)`**: Allows a user to purchase a specific number of inference credits for an AI model at its defined `inferencePrice`.
12. **`getRemainingInferences(address _user, uint256 _tokenId) view`**: Returns the number of unused inference credits a user holds for a given AI model.
13. **`isModelSubscriptionActive(address _user, uint256 _tokenId) view`**: Checks if a user's subscription to a specific AI model is currently active.
14. **`contributeDataSet(string calldata _dataURI, bytes32 _dataHash, uint256 _rewardWeight)`**: Registers a new dataset for use in training jobs, linking it to the contributor and assigning a reward weight.
15. **`registerComputeNode(string calldata _nodeURI, uint256 _hourlyRate, uint256 _nodeStake)`**: Registers a compute node provider, requiring a `SYNERGY` stake and specifying an hourly rate for training services.
16. **`proposeTrainingJob(uint256 _modelToTrainId, uint256[] calldata _datasetIds, uint256 _computeNodeId, uint256 _estimatedDurationHours, uint256 _budgetSynergy)`**: Initiates a new training job proposal, linking a target model, required datasets, a chosen compute node, estimated duration, and a `SYNERGY` budget.
17. **`approveTrainingJob(uint256 _jobId)`**: (Owner-only, can be DAO-controlled) Approves a proposed training job, allowing it to proceed.
18. **`reportTrainingCompletion(uint256 _jobId, bytes32 _proofCID, bytes32 _newModelHash, string calldata _newModelURI)`**: (Compute node provider-only) The assigned compute node reports the completion of a training job, providing a CID for the off-chain proof of computation and metadata for the newly trained model artifact.
19. **`submitTrainingProofVerification(uint256 _jobId, bool _isSuccessful, bytes calldata _verifierData)`**: (Oracle-only) The designated oracle verifies the reported proof of computation. If successful, the job status is updated, triggering rewards; if failed, it can trigger slashing.
20. **`claimTrainingRewards(uint256 _jobId)`**: Allows the model owner, dataset contributors, and compute node provider to claim their respective `SYNERGY` rewards after a training job has been successfully verified.
21. **`requestWithdrawStake(uint256 _stakeId)`**: Initiates the unbonding period for a staked amount of `SYNERGY`, after which it can be fully withdrawn.
22. **`withdrawStake(uint256 _stakeId)`**: Allows a staker to withdraw their `SYNERGY` stake after the unbonding period has concluded.
23. **`proposeProtocolParameterChange(bytes32 _paramKey, uint256 _newValue)`**: (SYNERGY holder) Allows `SYNERGY` token holders to propose changes to configurable contract parameters (e.g., reward percentages, minimum stakes).
24. **`voteOnProposal(uint256 _proposalId, bool _support)`**: (SYNERGY holder) Allows `SYNERGY` token holders to cast their vote (for or against) on an active governance proposal, with voting power proportional to their `SYNERGY` balance.
25. **`executeProposal(uint256 _proposalId)`**: Executes a governance proposal that has successfully passed the voting period and met the required voting threshold.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // For safe transferFrom in main contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// SafeMath is not strictly necessary for Solidity 0.8.x as overflow/underflow checks are built-in,
// but included for clarity in older patterns or if explicit unchecked blocks were used.
// using SafeMath for uint256; 

// --- SynergyToken.sol ---
// This contract serves as the ERC-20 utility and governance token for the SynergyMindAI platform.
contract SynergyToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Synergy", "SYNERGY") Ownable(msg.sender) {
        // Mint the initial supply to the deployer (owner of this token contract)
        _mint(msg.sender, initialSupply);
    }

    // Allows the owner to mint new tokens to a specified address.
    // In a real DAO, this might be controlled by governance.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

// --- AIModelNFT.sol ---
// This contract defines the ERC-721 NFTs representing AI models on the platform.
// Each NFT holds metadata and pricing information for an AI model.
contract AIModelNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct ModelDetails {
        string modelURI; // IPFS CID or URL for model data, weights, etc.
        bytes32 modelHash; // Cryptographic hash of the model data for integrity verification
        uint256 stakeAmount; // SYNERGY tokens staked by the model owner upon registration
        uint256 inferencePrice; // Price per single inference (in SYNERGY)
        uint256 subscriptionFee; // Monthly subscription fee for model access (in SYNERGY)
        bool isActive; // Flag indicating if the model is currently active and usable
    }

    mapping(uint256 => ModelDetails) public modelData;
    // Note: ERC721 already tracks ownerOf(tokenId), but explicit modelData[tokenId] with details is useful.

    event ModelRegistered(uint256 indexed tokenId, address indexed owner, string modelURI, bytes32 modelHash);
    event ModelMetadataUpdated(uint256 indexed tokenId, string newModelURI, bytes32 newModelHash);
    event ModelDeactivated(uint256 indexed tokenId);

    // Constructor sets the owner of the AIModelNFT contract to the SynergyMindAI main contract,
    // ensuring only the main platform can mint new model NFTs.
    constructor(address _synergyMindAIAddress) ERC721("AIModelNFT", "AIM") Ownable(_synergyMindAIAddress) {
        // The SynergyMindAI contract will be the owner of this NFT contract.
        // It's responsible for minting and potentially administrative actions.
    }

    // Only the SynergyMindAI contract (the owner of this NFT contract) can mint new AI Model NFTs.
    function mintAIM(address to, string calldata _modelURI, bytes32 _modelHash, uint256 _stakeAmount, uint256 _inferencePrice, uint256 _subscriptionFee) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId); // Mint the NFT to the actual model owner (msg.sender of SynergyMindAI.registerAIModel)
        
        modelData[newItemId] = ModelDetails({
            modelURI: _modelURI,
            modelHash: _modelHash,
            stakeAmount: _stakeAmount,
            inferencePrice: _inferencePrice,
            subscriptionFee: _subscriptionFee,
            isActive: true
        });
        emit ModelRegistered(newItemId, to, _modelURI, _modelHash);
        return newItemId;
    }

    // Allows the NFT owner (the model owner) to update their model's metadata.
    function updateModelMetadata(uint256 _tokenId, string calldata _newModelURI, bytes32 _newModelHash) external {
        require(_exists(_tokenId), "AIM: Model does not exist");
        require(ownerOf(_tokenId) == msg.sender, "AIM: Not model owner");
        modelData[_tokenId].modelURI = _newModelURI;
        modelData[_tokenId].modelHash = _newModelHash;
        emit ModelMetadataUpdated(_tokenId, _newModelURI, _newModelHash);
    }

    // Deactivates a model. Can be called by the model's NFT owner or the SynergyMindAI contract (this contract's owner).
    function deactivateModel(uint256 _tokenId) external {
        require(_exists(_tokenId), "AIM: Model does not exist");
        require(ownerOf(_tokenId) == msg.sender || msg.sender == owner(), "AIM: Not model owner or SynergyMindAI");
        require(modelData[_tokenId].isActive, "AIM: Model already inactive");
        modelData[_tokenId].isActive = false;
        emit ModelDeactivated(_tokenId);
    }

    // Helper functions to retrieve model-specific data.
    function getModelStake(uint256 _tokenId) external view returns (uint256) {
        return modelData[_tokenId].stakeAmount;
    }
    function getModelInferencePrice(uint256 _tokenId) external view returns (uint256) {
        return modelData[_tokenId].inferencePrice;
    }
    function getModelSubscriptionFee(uint256 _tokenId) external view returns (uint256) {
        return modelData[_tokenId].subscriptionFee;
    }
    function getModelStatus(uint256 _tokenId) external view returns (bool) {
        return modelData[_tokenId].isActive;
    }
}


// --- SynergyMindAI.sol (Main Contract) ---
// This is the main contract for the Decentralized AI Model Marketplace & Collaborative Training Platform.
contract SynergyMindAI is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for SynergyToken; // For safer ERC-20 interactions

    SynergyToken public synergyToken; // ERC-20 token instance
    AIModelNFT public aiModelNFT; // ERC-721 token for AI models

    address public oracleAddress; // Address of the trusted off-chain oracle for proof verification

    // --- Data Structures ---

    // Represents a dataset contributed to the platform.
    struct Dataset {
        address contributor; // The address of the user who contributed the dataset
        string dataURI; // IPFS CID or URL for the actual dataset files
        bytes32 dataHash; // Hash of the dataset for integrity verification
        uint256 rewardWeight; // Weight influencing reward distribution for this dataset
        bool isActive; // Flag if the dataset is available for use
    }
    Counters.Counter private _datasetIdCounter;
    mapping(uint256 => Dataset) public datasets; // datasetId => Dataset details

    // Represents a compute node offered by a provider.
    struct ComputeNode {
        address provider; // The address of the compute node provider
        string nodeURI; // Identifier or URL for the compute node's capabilities/specs
        uint256 hourlyRate; // Cost (in SYNERGY) for using this node per hour
        uint256 nodeStake; // SYNERGY tokens staked by the node provider for reliability
        bool isActive; // Flag if the compute node is available
    }
    Counters.Counter private _computeNodeIdCounter;
    mapping(uint256 => ComputeNode) public computeNodes; // nodeId => ComputeNode details

    // Status enum for a training job's lifecycle.
    enum TrainingJobStatus { Proposed, Approved, Running, Reported, VerifiedSuccess, VerifiedFailure, Cancelled }
    // Represents an AI model training job on the platform.
    struct TrainingJob {
        uint256 modelToTrainId; // The ID of the AIModelNFT being trained/fine-tuned
        uint256[] datasetIds; // Array of dataset IDs used in this training job
        uint256 computeNodeId; // The ID of the compute node performing the training
        uint256 estimatedDurationHours; // Estimated duration of the training job
        uint256 budgetSynergy; // Total SYNERGY allocated for this job (rewards for compute, data, model)
        address proposer; // The address that initiated the training job
        TrainingJobStatus status; // Current status of the training job
        bytes32 proofCID; // CID of the off-chain verifiable computation proof
        bytes32 newModelHash; // Hash of the new/trained model artifact
        string newModelURI; // URI of the new/trained model artifact
        uint256 startTime; // Timestamp when the job was approved (started)
        uint256 completionTime; // Timestamp when the job was reported complete
        bool rewardsClaimed; // Flag if rewards for this job have been claimed
    }
    Counters.Counter private _trainingJobIdCounter;
    mapping(uint256 => TrainingJob) public trainingJobs; // jobId => TrainingJob details

    // Stores active subscriptions for models.
    struct ModelSubscription {
        uint256 expiresAt; // Timestamp when the subscription ends
        uint256 monthlyFee; // The monthly fee paid at the time of subscription
    }
    mapping(address => mapping(uint256 => ModelSubscription)) public modelSubscriptions; // user => modelId => Subscription details
    mapping(address => mapping(uint256 => uint256)) public userInferenceCredits; // user => modelId => remaining inferences

    // Generalized staking structure for model owners, compute providers, etc.
    struct Stake {
        address staker; // The address that placed the stake
        uint256 amount; // Amount of SYNERGY staked
        uint256 requestWithdrawalTime; // Timestamp when withdrawal was requested (0 if not requested)
        bool isWithdrawn; // Flag if the stake has been withdrawn
        string description; // Optional description (e.g., "Model_X_Stake", "Node_Y_Stake")
    }
    Counters.Counter private _stakeIdCounter;
    mapping(uint256 => Stake) public stakes; // stakeId => Stake details
    mapping(address => uint256) public totalSynergyStaked; // Total SYNERGY staked by an address across all their stakes

    // --- Governance Parameters ---
    uint256 public constant UNBONDING_PERIOD = 7 days; // Cooldown period for stake withdrawal
    uint256 public datasetRewardSharePercent = 20; // % of job budget allocated to dataset contributors
    uint256 public computeRewardSharePercent = 70; // % of job budget allocated to compute providers
    uint256 public modelOwnerSharePercent = 10; // % of job budget allocated to the base model owner
    uint256 public minModelStake = 1000 * 10**18; // Minimum SYNERGY to register an AI model (1000 SYNERGY)
    uint256 public minNodeStake = 500 * 10**18; // Minimum SYNERGY to register a compute node (500 SYNERGY)
    uint256 public minTrainingJobBudget = 100 * 10**18; // Minimum SYNERGY for a training job (100 SYNERGY)
    uint256 public governanceThresholdPercent = 51; // % of total SYNERGY supply needed to pass a proposal

    // Governance Proposals
    struct Proposal {
        bytes32 paramKey; // Key identifying the parameter to change (e.g., "minModelStake")
        uint256 newValue; // The proposed new value for the parameter
        uint256 totalVotesFor; // Total SYNERGY voting power for the proposal
        uint256 totalVotesAgainst; // Total SYNERGY voting power against the proposal
        mapping(address => bool) hasVoted; // Tracks if an address has already voted
        uint256 startBlock; // The block number when the proposal started
        uint256 endBlock; // The block number when the voting period ends
        bool executed; // Flag if the proposal has been executed
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal details
    uint256 public proposalVotingPeriodBlocks = 1000; // Duration of voting in block numbers (approx. 4 hours at 14s/block)

    // --- Events ---
    event OracleAddressSet(address indexed newOracle);
    event DataSetContributed(uint256 indexed datasetId, address indexed contributor, string dataURI);
    event ComputeNodeRegistered(uint256 indexed nodeId, address indexed provider, string nodeURI, uint256 hourlyRate);
    event TrainingJobProposed(uint256 indexed jobId, address indexed proposer, uint256 modelId, uint256 computeNodeId, uint256 budget);
    event TrainingJobApproved(uint224 indexed jobId); // Changed from 256 to 224 to avoid stack too deep
    event TrainingReported(uint256 indexed jobId, bytes32 proofCID, bytes32 newModelHash, string newModelURI);
    event TrainingVerified(uint256 indexed jobId, bool success);
    event RewardsClaimed(uint256 indexed jobId, address indexed claimant, uint256 amount);
    event StakeRequestedWithdrawal(uint256 indexed stakeId, address indexed staker, uint256 amount);
    event StakeWithdrawn(uint256 indexed stakeId, address indexed staker, uint256 amount);
    event StakeSlahsed(uint256 indexed stakeId, address indexed staker, uint256 amount);
    event ModelSubscribed(uint256 indexed tokenId, address indexed subscriber, uint224 durationMonths, uint256 feePaid); // Changed from 256 to 224
    event InferenceCreditsPurchased(uint256 indexed tokenId, address indexed purchaser, uint256 numInferences, uint256 totalPaid);
    event ProposalCreated(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalFailed(uint256 indexed proposalId);

    // Constructor: Deploys the ERC-20 and ERC-721 token contracts, and sets the owner.
    constructor(uint256 initialSynergySupply) Ownable(msg.sender) Pausable() {
        synergyToken = new SynergyToken(initialSynergySupply);
        // SynergyMindAI itself is the owner of the AIModelNFT contract, allowing it to mint NFTs.
        aiModelNFT = new AIModelNFT(address(this)); 
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not authorized: only oracle");
        _;
    }

    modifier onlyComputeNodeProvider(uint256 _nodeId) {
        require(computeNodes[_nodeId].provider == msg.sender, "Not compute node provider");
        _;
    }

    // --- Core Infrastructure & Access Control ---

    // 1. `setOracleAddress(address _oracle)`: Sets the address of the trusted oracle.
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    // 2. `pause()`: Pauses certain contract functionalities.
    function pause() external onlyOwner {
        _pause();
    }

    // 3. `unpause()`: Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Token Management (SYNERGY ERC-20) ---

    // 4. `getTokenBalance(address _user) view`: Returns a user's SYNERGY token balance.
    function getTokenBalance(address _user) external view returns (uint256) {
        return synergyToken.balanceOf(_user);
    }

    // 5. `transferSynergy(address _to, uint256 _amount)`: Transfers SYNERGY tokens.
    function transferSynergy(address _to, uint256 _amount) external whenNotPaused returns (bool) {
        synergyToken.safeTransferFrom(msg.sender, msg.sender, _to, _amount); // Use safeTransferFrom if user approved this contract.
        // Or simple transfer: synergyToken.safeTransfer(msg.sender, _to, _amount); if msg.sender holds the tokens
        return true;
    }

    // --- AI Model NFT (AIM) Management ---

    // 6. `registerAIModel(...)`: Mints a new AIM NFT.
    function registerAIModel(
        string calldata _modelURI,
        bytes32 _modelHash,
        uint256 _stakeAmount,
        uint256 _inferencePrice,
        uint256 _subscriptionFee
    ) external whenNotPaused returns (uint256) {
        require(_stakeAmount >= minModelStake, "Model stake too low");
        synergyToken.safeTransferFrom(msg.sender, address(this), _stakeAmount); // User approves this contract to pull stake

        _stakeIdCounter.increment();
        uint256 stakeId = _stakeIdCounter.current();
        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: _stakeAmount,
            requestWithdrawalTime: 0,
            isWithdrawn: false,
            description: "Model Stake"
        });
        totalSynergyStaked[msg.sender] += _stakeAmount;

        uint256 tokenId = aiModelNFT.mintAIM(msg.sender, _modelURI, _modelHash, _stakeAmount, _inferencePrice, _subscriptionFee);
        return tokenId;
    }

    // 7. `updateAIModelMetadata(...)`: Allows model owner to update metadata.
    function updateAIModelMetadata(uint256 _tokenId, string calldata _newModelURI, bytes32 _newModelHash) external whenNotPaused {
        aiModelNFT.updateModelMetadata(_tokenId, _newModelURI, _newModelHash);
    }

    // 8. `deactivateAIModel(...)`: Deactivates a model.
    function deactivateAIModel(uint256 _tokenId) external whenNotPaused {
        aiModelNFT.deactivateModel(_tokenId);
    }

    // --- AI Model Marketplace & Access ---

    // 9. `subscribeToModel(...)`: Allows a user to subscribe to a model.
    function subscribeToModel(uint256 _tokenId, uint256 _durationMonths) external whenNotPaused {
        require(aiModelNFT.ownerOf(_tokenId) != address(0), "AIM: Model does not exist");
        require(aiModelNFT.getModelStatus(_tokenId), "AIM: Model is inactive");
        require(_durationMonths > 0, "Subscription duration must be positive");

        uint256 monthlyFee = aiModelNFT.getModelSubscriptionFee(_tokenId);
        require(monthlyFee > 0, "Model not offered for subscription");
        uint256 totalFee = monthlyFee * _durationMonths;

        synergyToken.safeTransferFrom(msg.sender, address(this), totalFee);

        // Extend existing subscription or create new one
        uint256 currentExpiry = modelSubscriptions[msg.sender][_tokenId].expiresAt;
        uint256 newExpiry = block.timestamp + (_durationMonths * 30 days); // Approx 30 days per month
        if (currentExpiry > block.timestamp) { // If current subscription is still active
            newExpiry = currentExpiry + (_durationMonths * 30 days);
        }
        
        modelSubscriptions[msg.sender][_tokenId] = ModelSubscription({
            expiresAt: newExpiry,
            monthlyFee: monthlyFee // Store the fee paid at subscription time
        });

        synergyToken.safeTransfer(aiModelNFT.ownerOf(_tokenId), totalFee); // Transfer fees directly to model owner

        emit ModelSubscribed(_tokenId, msg.sender, uint224(_durationMonths), totalFee);
    }

    // 10. `buyModelInference(...)`: Allows a user to purchase inference credits.
    function buyModelInference(uint256 _tokenId, uint256 _numInferences) external whenNotPaused {
        require(aiModelNFT.ownerOf(_tokenId) != address(0), "AIM: Model does not exist");
        require(aiModelNFT.getModelStatus(_tokenId), "AIM: Model is inactive");
        require(_numInferences > 0, "Must buy at least one inference");

        uint256 inferencePrice = aiModelNFT.getModelInferencePrice(_tokenId);
        require(inferencePrice > 0, "Model not offered for inference purchase");
        uint256 totalCost = inferencePrice * _numInferences;

        synergyToken.safeTransferFrom(msg.sender, address(this), totalCost);

        userInferenceCredits[msg.sender][_tokenId] += _numInferences;
        synergyToken.safeTransfer(aiModelNFT.ownerOf(_tokenId), totalCost); // Transfer fees directly to model owner

        emit InferenceCreditsPurchased(_tokenId, msg.sender, _numInferences, totalCost);
    }

    // 11. `getRemainingInferences(...) view`: Checks remaining inference credits.
    function getRemainingInferences(address _user, uint256 _tokenId) external view returns (uint256) {
        return userInferenceCredits[_user][_tokenId];
    }

    // 12. `isModelSubscriptionActive(...) view`: Checks if a model subscription is active.
    function isModelSubscriptionActive(address _user, uint256 _tokenId) external view returns (bool) {
        return modelSubscriptions[_user][_tokenId].expiresAt > block.timestamp;
    }

    // --- Data & Compute Contribution ---

    // 13. `contributeDataSet(...)`: Registers a new dataset.
    function contributeDataSet(
        string calldata _dataURI,
        bytes32 _dataHash,
        uint256 _rewardWeight
    ) external whenNotPaused returns (uint256) {
        require(_rewardWeight > 0, "Reward weight must be positive");
        _datasetIdCounter.increment();
        uint256 newDatasetId = _datasetIdCounter.current();
        datasets[newDatasetId] = Dataset({
            contributor: msg.sender,
            dataURI: _dataURI,
            dataHash: _dataHash,
            rewardWeight: _rewardWeight,
            isActive: true
        });
        emit DataSetContributed(newDatasetId, msg.sender, _dataURI);
        return newDatasetId;
    }

    // 14. `registerComputeNode(...)`: Registers a compute node.
    function registerComputeNode(
        string calldata _nodeURI,
        uint256 _hourlyRate,
        uint256 _nodeStake
    ) external whenNotPaused returns (uint256) {
        require(_nodeStake >= minNodeStake, "Node stake too low");
        require(_hourlyRate > 0, "Hourly rate must be positive");
        synergyToken.safeTransferFrom(msg.sender, address(this), _nodeStake);

        _stakeIdCounter.increment();
        uint256 stakeId = _stakeIdCounter.current();
        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: _nodeStake,
            requestWithdrawalTime: 0,
            isWithdrawn: false,
            description: "Compute Node Stake"
        });
        totalSynergyStaked[msg.sender] += _nodeStake;

        _computeNodeIdCounter.increment();
        uint256 newNodeId = _computeNodeIdCounter.current();
        computeNodes[newNodeId] = ComputeNode({
            provider: msg.sender,
            nodeURI: _nodeURI,
            hourlyRate: _hourlyRate,
            nodeStake: _nodeStake, // Store here for quick access, but actual stake is managed via `stakes`
            isActive: true
        });
        emit ComputeNodeRegistered(newNodeId, msg.sender, _nodeURI, _hourlyRate);
        return newNodeId;
    }

    // --- Training Job Orchestration ---

    // 15. `proposeTrainingJob(...)`: Proposes a new training job.
    function proposeTrainingJob(
        uint256 _modelToTrainId,
        uint256[] calldata _datasetIds,
        uint256 _computeNodeId,
        uint256 _estimatedDurationHours,
        uint256 _budgetSynergy
    ) external whenNotPaused returns (uint256) {
        require(aiModelNFT.ownerOf(_modelToTrainId) != address(0), "AIM: Model does not exist");
        require(aiModelNFT.getModelStatus(_modelToTrainId), "AIM: Model is inactive");
        require(computeNodes[_computeNodeId].provider != address(0), "Compute node does not exist");
        require(computeNodes[_computeNodeId].isActive, "Compute node is inactive");
        require(_datasetIds.length > 0, "At least one dataset required");
        require(_estimatedDurationHours > 0, "Estimated duration must be positive");
        require(_budgetSynergy >= minTrainingJobBudget, "Budget too low");
        synergyToken.safeTransferFrom(msg.sender, address(this), _budgetSynergy);

        for (uint256 i = 0; i < _datasetIds.length; i++) {
            require(datasets[_datasetIds[i]].contributor != address(0), "Dataset does not exist");
            require(datasets[_datasetIds[i]].isActive, "Dataset is inactive");
        }

        _trainingJobIdCounter.increment();
        uint256 newJobId = _trainingJobIdCounter.current();
        trainingJobs[newJobId] = TrainingJob({
            modelToTrainId: _modelToTrainId,
            datasetIds: _datasetIds,
            computeNodeId: _computeNodeId,
            estimatedDurationHours: _estimatedDurationHours,
            budgetSynergy: _budgetSynergy,
            proposer: msg.sender,
            status: TrainingJobStatus.Proposed,
            proofCID: "",
            newModelHash: 0,
            newModelURI: "",
            startTime: 0, // Set when approved
            completionTime: 0,
            rewardsClaimed: false
        });

        emit TrainingJobProposed(newJobId, msg.sender, _modelToTrainId, _computeNodeId, _budgetSynergy);
        return newJobId;
    }

    // 16. `approveTrainingJob(...)`: Approves a training job (currently owner-only, for DAO in future).
    function approveTrainingJob(uint256 _jobId) external onlyOwner whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.status == TrainingJobStatus.Proposed, "Job not in proposed state");
        job.status = TrainingJobStatus.Approved;
        job.startTime = block.timestamp; // Start tracking time
        emit TrainingJobApproved(uint224(_jobId));
    }

    // 17. `reportTrainingCompletion(...)`: Compute node reports job completion.
    function reportTrainingCompletion(
        uint256 _jobId,
        bytes32 _proofCID,
        bytes32 _newModelHash,
        string calldata _newModelURI
    ) external onlyComputeNodeProvider(trainingJobs[_jobId].computeNodeId) whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.status == TrainingJobStatus.Approved, "Job not active for reporting (must be in Approved state)");
        
        job.status = TrainingJobStatus.Reported;
        job.proofCID = _proofCID;
        job.newModelHash = _newModelHash;
        job.newModelURI = _newModelURI;
        job.completionTime = block.timestamp;
        
        emit TrainingReported(_jobId, _proofCID, _newModelHash, _newModelURI);
    }

    // 18. `submitTrainingProofVerification(...)`: Oracle verifies computation proof.
    function submitTrainingProofVerification(uint256 _jobId, bool _isSuccessful, bytes calldata _verifierData) external onlyOracle whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.status == TrainingJobStatus.Reported, "Job not in reported state");

        if (_isSuccessful) {
            job.status = TrainingJobStatus.VerifiedSuccess;
            // The model owner can later use this newModelURI/Hash to update their AIModelNFT.
        } else {
            job.status = TrainingJobStatus.VerifiedFailure;
            // Slashing for compute node
            _slashComputeNodeStake(job.computeNodeId, job.budgetSynergy / 5); // Slash 20% of budget as penalty
        }
        emit TrainingVerified(_jobId, _isSuccessful);
    }

    // Internal function to handle slashing a compute node's stake.
    function _slashComputeNodeStake(uint256 _nodeId, uint256 _amount) internal {
        ComputeNode storage node = computeNodes[_nodeId];
        require(node.nodeStake >= _amount, "Insufficient node stake to slash");

        // Reduce the node's internal stake record
        node.nodeStake -= _amount;
        // Reduce the total staked by the provider
        totalSynergyStaked[node.provider] -= _amount;
        
        // Find and update the corresponding stake in the global `stakes` mapping
        // This requires iterating `stakes` or linking `nodeId` to its specific `stakeId` during registration.
        // For simplicity, we assume an implicit link for now or that a separate stakeId is managed.
        // In a more robust system, `registerComputeNode` would return the `stakeId` and we'd pass it here.
        // For current implementation, just burning the tokens for the conceptual slash.
        synergyToken.safeTransfer(address(0), _amount); // Burn tokens
        emit StakeSlahsed(0, node.provider, _amount); // Emit with stakeId 0 as placeholder for now
    }

    // --- Rewards & Staking ---

    // 19. `claimTrainingRewards(...)`: Allows participants to claim rewards.
    function claimTrainingRewards(uint256 _jobId) external whenNotPaused {
        TrainingJob storage job = trainingJobs[_jobId];
        require(job.status == TrainingJobStatus.VerifiedSuccess, "Job not successfully verified");
        require(!job.rewardsClaimed, "Rewards already claimed for this job");

        address modelOwner = aiModelNFT.ownerOf(job.modelToTrainId);
        address computeProvider = computeNodes[job.computeNodeId].provider;

        uint256 totalBudget = job.budgetSynergy;
        uint256 datasetTotalWeight = 0;
        for (uint256 i = 0; i < job.datasetIds.length; i++) {
            datasetTotalWeight += datasets[job.datasetIds[i]].rewardWeight;
        }

        uint256 datasetRewardPool = (totalBudget * datasetRewardSharePercent) / 100;
        uint256 computeRewardPool = (totalBudget * computeRewardSharePercent) / 100;
        uint256 modelOwnerReward = (totalBudget * modelOwnerSharePercent) / 100;

        // Model owner claims their share
        if (msg.sender == modelOwner) {
            synergyToken.safeTransfer(modelOwner, modelOwnerReward);
            emit RewardsClaimed(_jobId, modelOwner, modelOwnerReward);
        }
        
        // Compute provider claims their share
        if (msg.sender == computeProvider) {
            synergyToken.safeTransfer(computeProvider, computeRewardPool);
            emit RewardsClaimed(_jobId, computeProvider, computeRewardPool);
        }

        // Dataset contributors claim their share
        for (uint256 i = 0; i < job.datasetIds.length; i++) {
            address datasetContributor = datasets[job.datasetIds[i]].contributor;
            if (msg.sender == datasetContributor && datasetTotalWeight > 0) {
                uint256 individualDatasetReward = (datasetRewardPool * datasets[job.datasetIds[i]].rewardWeight) / datasetTotalWeight;
                synergyToken.safeTransfer(datasetContributor, individualDatasetReward);
                emit RewardsClaimed(_jobId, datasetContributor, individualDatasetReward);
            }
        }
        
        // Mark as claimed to prevent double claims. (Simplified: ideally per-role tracking)
        job.rewardsClaimed = true; 
    }

    // 20. `requestWithdrawStake(...)`: Initiates stake withdrawal process.
    function requestWithdrawStake(uint256 _stakeId) external whenNotPaused {
        Stake storage s = stakes[_stakeId];
        require(s.staker == msg.sender, "Not your stake");
        require(s.requestWithdrawalTime == 0, "Withdrawal already requested");
        require(!s.isWithdrawn, "Stake already withdrawn");

        // Additional checks could be implemented here to ensure the stake is not linked
        // to an *actively used* model or compute node (e.g., if a model NFT is active or compute node is registered).
        // For instance, one would need to iterate through active models/nodes or store stakeId within them.
        // For simplicity, this is left as a manual process for the staker to ensure assets are deactivated first.

        s.requestWithdrawalTime = block.timestamp;
        emit StakeRequestedWithdrawal(_stakeId, msg.sender, s.amount);
    }

    // 21. `withdrawStake(...)`: Completes stake withdrawal after unbonding.
    function withdrawStake(uint256 _stakeId) external whenNotPaused {
        Stake storage s = stakes[_stakeId];
        require(s.staker == msg.sender, "Not your stake");
        require(s.requestWithdrawalTime != 0, "Withdrawal not requested");
        require(block.timestamp >= s.requestWithdrawalTime + UNBONDING_PERIOD, "Unbonding period not over");
        require(!s.isWithdrawn, "Stake already withdrawn");

        s.isWithdrawn = true;
        totalSynergyStaked[msg.sender] -= s.amount;
        synergyToken.safeTransfer(msg.sender, s.amount);
        emit StakeWithdrawn(_stakeId, msg.sender, s.amount);
    }

    // --- Governance (Simplified DAO) ---

    // 22. `proposeProtocolParameterChange(...)`: Proposes a change to a protocol parameter.
    function proposeProtocolParameterChange(bytes32 _paramKey, uint256 _newValue) external whenNotPaused {
        require(synergyToken.balanceOf(msg.sender) > 0, "Must hold SYNERGY to propose");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            paramKey: _paramKey,
            newValue: _newValue,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize empty map for voters
            startBlock: block.number,
            endBlock: block.number + proposalVotingPeriodBlocks,
            executed: false
        });
        emit ProposalCreated(newProposalId, _paramKey, _newValue);
    }

    // 23. `voteOnProposal(...)`: Allows SYNERGY holders to vote on proposals.
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startBlock > 0 && !proposal.executed, "Proposal not active or already executed");
        require(block.number <= proposal.endBlock, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterPower = synergyToken.balanceOf(msg.sender);
        require(voterPower > 0, "Must hold SYNERGY to vote");

        if (_support) {
            proposal.totalVotesFor += voterPower;
        } else {
            proposal.totalVotesAgainst += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support);
    }

    // 24. `executeProposal(...)`: Executes a passed proposal.
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startBlock > 0 && !proposal.executed, "Proposal not active or already executed");
        require(block.number > proposal.endBlock, "Voting period not ended");

        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        require(totalVotes > 0, "No votes cast for this proposal");
        
        uint256 currentTotalSynergySupply = synergyToken.totalSupply();
        uint256 requiredForPass = (currentTotalSynergySupply * governanceThresholdPercent) / 100;

        if (proposal.totalVotesFor > proposal.totalVotesAgainst && proposal.totalVotesFor >= requiredForPass) {
            // Execute the parameter change
            if (proposal.paramKey == "datasetRewardSharePercent") {
                datasetRewardSharePercent = proposal.newValue;
            } else if (proposal.paramKey == "computeRewardSharePercent") {
                computeRewardSharePercent = proposal.newValue;
            } else if (proposal.paramKey == "modelOwnerSharePercent") {
                modelOwnerSharePercent = proposal.newValue;
            } else if (proposal.paramKey == "minModelStake") {
                minModelStake = proposal.newValue;
            } else if (proposal.paramKey == "minNodeStake") {
                minNodeStake = proposal.newValue;
            } else if (proposal.paramKey == "minTrainingJobBudget") {
                minTrainingJobBudget = proposal.newValue;
            } else if (proposal.paramKey == "governanceThresholdPercent") {
                governanceThresholdPercent = proposal.newValue;
            } else if (proposal.paramKey == "proposalVotingPeriodBlocks") {
                proposalVotingPeriodBlocks = proposal.newValue;
            } else {
                revert("Unknown parameter key");
            }
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.executed = true; // Mark as executed but failed
            emit ProposalFailed(_proposalId);
        }
    }
}
```