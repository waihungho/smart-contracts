This smart contract, "SynapseAI Protocol," envisions a decentralized network for collaboratively refining AI models and curating high-quality datasets. Participants stake tokens, submit data or models, and validate/evaluate submissions. Their performance directly influences their "AI Persona NFT," a soulbound (non-transferable) token whose traits evolve on-chain, reflecting their contribution and reputation within the SynapseAI ecosystem.

The contract aims to be creative and advanced by combining:
1.  **Decentralized AI Model/Data Refinement:** Users contribute and validate raw data, and submit/evaluate AI models, creating a community-driven feedback loop for AI development.
2.  **Dynamic Soulbound NFTs:** Each participant owns a unique, non-transferable NFT whose visual and conceptual traits (e.g., "Data Curator Level," "Model Optimizer Score") evolve based on their on-chain actions and performance metrics. This acts as a decentralized identity and reputation system.
3.  **Staking & Slashing Mechanism:** Ensures accountability and quality control for submissions and validations.
4.  **On-chain Reputation System:** Aggregates user performance across various tasks to grant higher privileges and influence.
5.  **Mini-Governance:** Allows reputable participants to propose and vote on protocol parameter changes, moving towards progressive decentralization.

---

## **SynapseAI Protocol: Decentralized AI Model & Data Refinement Network**

This contract orchestrates a collaborative ecosystem for AI development. It manages the lifecycle of dataset submission/validation, AI model submission/evaluation, and dynamically updates a soulbound "AI Persona NFT" for each active participant based on their contributions and performance.

### **Outline**

1.  **Contract Overview**
2.  **State Variables & Data Structures**
3.  **Events**
4.  **Modifiers**
5.  **I. Core Protocol Management**
6.  **II. Staking & Rewards**
7.  **III. Data Workflow**
8.  **IV. Model Workflow**
9.  **V. AI Persona NFT (Soulbound)**
10. **VI. Reputation & Governance**
11. **Internal Helper Functions**

---

### **Function Summary**

**I. Core Protocol Management (5 Functions)**
1.  `constructor()`: Initializes the contract with the `SynapseToken` address, initial owner, and core parameters for the protocol.
2.  `setProtocolParameters()`: Allows the owner or DAO to update various operational parameters like staking amounts, reward multipliers, and task durations.
3.  `pauseProtocol()`: An emergency function to pause all mutable operations in the protocol, callable by the owner or DAO.
4.  `unpauseProtocol()`: Unpauses the protocol, restoring normal operations, callable by the owner or DAO.
5.  `withdrawProtocolFees(uint256 amount)`: Allows the owner or DAO to withdraw accumulated fees from the protocol.

**II. Staking & Rewards (4 Functions)**
6.  `stakeTokens(uint256 amount)`: Users stake `SynapseToken` to participate in various roles (data submitter, validator, model submitter, evaluator).
7.  `unstakeTokens(uint256 amount)`: Users request to unstake their `SynapseToken`. Funds might be subject to a cooldown period.
8.  `claimRewards()`: Allows users to claim their accumulated `SynapseToken` rewards earned from successful contributions.
9.  `getPendingRewards(address user)`: A view function to query the total `SynapseToken` rewards currently claimable by a specific user.

**III. Data Workflow (6 Functions)**
10. `submitDataset(string memory datasetHash, string memory datasetCID)`: Allows a staked user to submit a new dataset, providing its cryptographic hash and IPFS CID.
11. `registerAsDataValidator()`: Allows a staked user to register as a data validator, enabling them to claim data validation tasks.
12. `claimDataValidationTask(uint256 datasetId)`: A registered data validator claims an unvalidated dataset to review.
13. `submitDataValidationResult(uint256 taskId, bool isValid, string memory metadataCID)`: The validator submits their judgment on the dataset's quality (`isValid`) and any generated metadata (e.g., labels) CID.
14. `finalizeDatasetValidation(uint256 datasetId)`: Finalizes the validation process for a dataset based on aggregated validator results, distributing rewards/slashes and updating reputations/NFTs.
15. `requestDatasetAccess(uint256 datasetId)`: Model submitters can request access (e.g., download permission from IPFS) to a successfully validated dataset.

**IV. Model Workflow (6 Functions)**
16. `submitModel(string memory modelHash, string memory modelCID, uint256 datasetId)`: Allows a staked user to submit an AI model, providing its hash, IPFS CID, and the ID of the validated dataset it was trained on.
17. `registerAsModelEvaluator()`: Allows a staked user to register as a model evaluator, enabling them to claim model evaluation tasks.
18. `claimModelEvaluationTask(uint256 modelId)`: A registered model evaluator claims an unevaluated AI model to test.
19. `submitModelEvaluationResult(uint256 taskId, uint256 performanceScore, string memory metricsCID)`: The evaluator submits the model's performance score (e.g., accuracy) and any detailed metrics CID.
20. `finalizeModelEvaluation(uint256 modelId)`: Finalizes the evaluation process for a model based on aggregated evaluator results, distributing rewards/slashes and updating reputations/NFTs.
21. `requestModelAccess(uint256 modelId)`: Users can request access to a successfully evaluated and high-performing AI model.

**V. AI Persona NFT (Soulbound) (3 Functions)**
22. `mintAIPersonaNFT()`: Mints a unique, soulbound (non-transferable) AI Persona NFT for the caller if they don't already possess one.
23. `getAIPersonaNFTTraits(address owner)`: A view function to retrieve the current on-chain traits (e.g., levels, scores) of a user's AI Persona NFT.
24. `tokenURI(uint256 tokenId)`: Returns the URI for the NFT metadata, dynamically generating it based on the current on-chain traits of the associated user. (Inherited from ERC721 but with custom logic for dynamic traits).

**VI. Reputation & Governance (4 Functions)**
25. `getUserReputation(address user)`: A view function to query a user's current global reputation score within the protocol.
26. `proposeProtocolChange(bytes memory proposalData, string memory descriptionCID)`: Users with sufficient reputation can propose changes to protocol parameters, providing encoded proposal data and a description CID.
27. `voteOnProposal(uint256 proposalId, bool support)`: Reputable users cast their vote (support or oppose) on an active governance proposal.
28. `executeProposal(uint256 proposalId)`: Executes a proposal that has reached the required consensus and passed its voting period.

---
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit checks, though Solidity 0.8+ has overflow checks by default

/**
 * @title SynapseAIProtocol
 * @dev A decentralized protocol for collaborative AI model and data refinement.
 *      It integrates dynamic, soulbound NFTs to represent user contributions and reputation.
 */
contract SynapseAIProtocol is ERC721, Ownable, Pausable {
    using SafeMath for uint256;

    IERC20 public synapseToken; // The utility and reward token for the protocol

    // --- Protocol Parameters ---
    uint256 public constant MAX_REPUTATION_SCORE = 10_000;
    uint256 public constant BASE_REPUTATION_REWARD = 10;
    uint256 public constant REPUTATION_DECAY_RATE = 1; // % per epoch/period
    uint256 public constant MIN_GOVERNANCE_REPUTATION = 500; // Min reputation to propose/vote

    uint256 public dataSubmitterStake;
    uint256 public dataValidatorStake;
    uint256 public modelSubmitterStake;
    uint256 public modelEvaluatorStake;

    uint256 public datasetValidationPeriod; // In seconds
    uint256 public modelEvaluationPeriod;   // In seconds

    uint256 public dataSubmitterRewardMultiplier; // e.g., 100 for 1x
    uint256 public dataValidatorRewardMultiplier;
    uint256 public modelSubmitterRewardMultiplier;
    uint256 public modelEvaluatorRewardMultiplier;

    uint256 public protocolFeePercentage; // e.g., 50 for 5%
    uint256 public totalProtocolFees;

    // --- Data Structures ---

    enum TaskStatus { Pending, InProgress, Resolved, Failed }

    struct DatasetProposal {
        uint256 id;
        address submitter;
        string datasetHash; // Cryptographic hash of the dataset content
        string datasetCID;  // IPFS Content Identifier
        uint256 stakedAmount;
        uint256 submissionTime;
        uint256 validationDeadline;
        TaskStatus status;
        uint256 yesVotes; // Count of 'isValid = true' from validators
        uint256 noVotes;  // Count of 'isValid = false' from validators
        mapping(address => bool) hasValidated; // Tracks if a validator has participated
        bool isFinalized; // True if validation is resolved
    }

    struct DataValidationTask {
        uint256 id;
        uint256 datasetId;
        address validator;
        uint256 claimTime;
        TaskStatus status;
        bool isValid; // Validator's judgment
        string metadataCID; // CID of generated labels/metadata
        bool submittedResult; // True if validator submitted results
    }

    struct ModelProposal {
        uint256 id;
        address submitter;
        string modelHash;   // Cryptographic hash of the model content
        string modelCID;    // IPFS Content Identifier
        uint256 datasetId;  // Dataset ID it was trained on
        uint256 stakedAmount;
        uint256 submissionTime;
        uint256 evaluationDeadline;
        TaskStatus status;
        uint256 totalPerformanceScore; // Sum of scores from evaluators
        uint256 evaluatorCount;        // Number of evaluators who submitted
        mapping(address => bool) hasEvaluated; // Tracks if an evaluator has participated
        uint256 averagePerformance; // Calculated after finalization
        bool isFinalized; // True if evaluation is resolved
    }

    struct ModelEvaluationTask {
        uint256 id;
        uint256 modelId;
        address evaluator;
        uint256 claimTime;
        TaskStatus status;
        uint256 performanceScore; // Evaluator's reported performance
        string metricsCID;        // CID of detailed metrics
        bool submittedResult; // True if evaluator submitted results
    }

    // AI Persona NFT Traits (on-chain representation)
    struct AIPersonaTraits {
        uint256 dataCuratorLevel;      // Based on validated datasets and accuracy
        uint256 modelOptimizerScore;   // Based on submitted models' performance
        uint256 validationAccuracy;    // How often their validation results match consensus (0-100)
        uint256 synapseContributionPoints; // General accumulated points
        uint256 epochParticipations;   // Number of periods participated in
        uint256 reputationLastUpdated; // Timestamp of last reputation update
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        bytes proposalData; // Encoded function call and parameters
        string descriptionCID; // IPFS CID for detailed proposal description
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Tracks if a user has voted
        bool executed;
        bool approved; // True if passed
    }

    // --- Mappings & Counters ---
    uint256 public nextDatasetId;
    uint256 public nextDataValidationTaskId;
    uint256 public nextModelId;
    uint256 public nextModelEvaluationTaskId;
    uint256 public nextProposalId;
    uint256 public nextNFTId; // For ERC721 token IDs

    mapping(uint256 => DatasetProposal) public datasetProposals;
    mapping(uint256 => DataValidationTask) public dataValidationTasks;
    mapping(uint256 => ModelProposal) public modelProposals;
    mapping(uint256 => ModelEvaluationTask) public modelEvaluationTasks;

    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public pendingRewards;
    mapping(address => uint256) public userReputation; // Global reputation score
    mapping(address => bool) public isDataValidator;
    mapping(address => bool) public isModelEvaluator;
    mapping(address => uint256) public aiPersonaNFTTokenId; // Stores the tokenId for a user's NFT
    mapping(address => AIPersonaTraits) public aiPersonaTraits;

    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---
    event SynapseTokensStaked(address indexed user, uint256 amount);
    event SynapseTokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    event DatasetSubmitted(uint256 indexed datasetId, address indexed submitter, string datasetHash, string datasetCID);
    event DataValidatorRegistered(address indexed validator);
    event DataValidationTaskClaimed(uint256 indexed taskId, uint256 indexed datasetId, address indexed validator);
    event DataValidationResultSubmitted(uint256 indexed taskId, address indexed validator, bool isValid, string metadataCID);
    event DatasetValidationFinalized(uint256 indexed datasetId, TaskStatus finalStatus, uint256 totalReward);

    event ModelSubmitted(uint256 indexed modelId, address indexed submitter, string modelHash, string modelCID, uint256 indexed datasetId);
    event ModelEvaluatorRegistered(address indexed evaluator);
    event ModelEvaluationTaskClaimed(uint256 indexed taskId, uint256 indexed modelId, address indexed evaluator);
    event ModelEvaluationResultSubmitted(uint256 indexed taskId, address indexed evaluator, uint256 performanceScore, string metricsCID);
    event ModelEvaluationFinalized(uint256 indexed modelId, TaskStatus finalStatus, uint256 averagePerformance, uint256 totalReward);

    event AIPersonaNFTMinted(address indexed owner, uint256 indexed tokenId);
    event AIPersonaNFTTraitsUpdated(address indexed owner, uint256 indexed tokenId, AIPersonaTraits newTraits);

    event ProtocolParametersUpdated(uint256 dataSubmitterStake, uint256 dataValidatorStake, uint256 modelSubmitterStake, uint256 modelEvaluatorStake, uint256 datasetValidationPeriod, uint256 modelEvaluationPeriod, uint256 dataSubmitterRewardMultiplier, uint256 dataValidatorRewardMultiplier, uint256 modelSubmitterRewardMultiplier, uint256 modelEvaluatorRewardMultiplier, uint256 protocolFeePercentage);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionCID);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Modifiers ---
    modifier onlyDataValidator() {
        require(isDataValidator[msg.sender], "SynapseAI: Caller is not a data validator");
        _;
    }

    modifier onlyModelEvaluator() {
        require(isModelEvaluator[msg.sender], "SynapseAI: Caller is not a model evaluator");
        _;
    }

    // Prevents direct transfer of NFTs, making them soulbound
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        require(from == address(0) || to == address(0), "SynapseAI: AI Persona NFTs are soulbound and cannot be transferred.");
    }

    /**
     * @dev Constructor to initialize the SynapseAI Protocol.
     * @param _synapseTokenAddress The address of the SynapseToken (ERC20).
     * @param _owner Initial owner of the contract.
     */
    constructor(address _synapseTokenAddress, address _owner) ERC721("AI Persona NFT", "AIPNA") Ownable(_owner) {
        synapseToken = IERC20(_synapseTokenAddress);

        dataSubmitterStake = 100 * (10 ** 18); // Example: 100 tokens
        dataValidatorStake = 50 * (10 ** 18);  // Example: 50 tokens
        modelSubmitterStake = 200 * (10 ** 18); // Example: 200 tokens
        modelEvaluatorStake = 100 * (10 ** 18); // Example: 100 tokens

        datasetValidationPeriod = 3 days;
        modelEvaluationPeriod = 5 days;

        dataSubmitterRewardMultiplier = 120; // 1.2x base reward
        dataValidatorRewardMultiplier = 150; // 1.5x base reward
        modelSubmitterRewardMultiplier = 180; // 1.8x base reward
        modelEvaluatorRewardMultiplier = 200; // 2.0x base reward

        protocolFeePercentage = 50; // 5% fee (50 basis points, 50/1000 = 0.05)

        nextDatasetId = 1;
        nextDataValidationTaskId = 1;
        nextModelId = 1;
        nextModelEvaluationTaskId = 1;
        nextProposalId = 1;
        nextNFTId = 1;
    }

    // --- I. Core Protocol Management ---

    /**
     * @dev Sets or updates the core protocol parameters. Callable by owner/DAO.
     * @param _dataSubmitterStake Minimum stake for data submitters.
     * @param _dataValidatorStake Minimum stake for data validators.
     * @param _modelSubmitterStake Minimum stake for model submitters.
     * @param _modelEvaluatorStake Minimum stake for model evaluators.
     * @param _datasetValidationPeriod Duration for dataset validation.
     * @param _modelEvaluationPeriod Duration for model evaluation.
     * @param _dataSubmitterRewardMultiplier Reward multiplier for data submitters.
     * @param _dataValidatorRewardMultiplier Reward multiplier for data validators.
     * @param _modelSubmitterRewardMultiplier Reward multiplier for model submitters.
     * @param _modelEvaluatorRewardMultiplier Reward multiplier for model evaluators.
     * @param _protocolFeePercentage Percentage of rewards taken as protocol fee (e.g., 50 for 5%).
     */
    function setProtocolParameters(
        uint256 _dataSubmitterStake,
        uint256 _dataValidatorStake,
        uint256 _modelSubmitterStake,
        uint256 _modelEvaluatorStake,
        uint256 _datasetValidationPeriod,
        uint256 _modelEvaluationPeriod,
        uint256 _dataSubmitterRewardMultiplier,
        uint256 _dataValidatorRewardMultiplier,
        uint256 _modelSubmitterRewardMultiplier,
        uint256 _modelEvaluatorRewardMultiplier,
        uint256 _protocolFeePercentage
    ) external onlyOwner { // In a full DAO, this would be `onlyGovernance`
        require(_protocolFeePercentage <= 1000, "SynapseAI: Fee percentage cannot exceed 100% (1000 basis points)"); // 1000 for 100%

        dataSubmitterStake = _dataSubmitterStake;
        dataValidatorStake = _dataValidatorStake;
        modelSubmitterStake = _modelSubmitterStake;
        modelEvaluatorStake = _modelEvaluatorStake;
        datasetValidationPeriod = _datasetValidationPeriod;
        modelEvaluationPeriod = _modelEvaluationPeriod;
        dataSubmitterRewardMultiplier = _dataSubmitterRewardMultiplier;
        dataValidatorRewardMultiplier = _dataValidatorRewardMultiplier;
        modelSubmitterRewardMultiplier = _modelSubmitterRewardMultiplier;
        modelEvaluatorRewardMultiplier = _modelEvaluatorRewardMultiplier;
        protocolFeePercentage = _protocolFeePercentage;

        emit ProtocolParametersUpdated(
            _dataSubmitterStake,
            _dataValidatorStake,
            _modelSubmitterStake,
            _modelEvaluatorStake,
            _datasetValidationPeriod,
            _modelEvaluationPeriod,
            _dataSubmitterRewardMultiplier,
            _dataValidatorRewardMultiplier,
            _modelSubmitterRewardMultiplier,
            _modelEvaluatorRewardMultiplier,
            _protocolFeePercentage
        );
    }

    /**
     * @dev Pauses the protocol in case of emergencies. Callable by the owner/DAO.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol. Callable by the owner/DAO.
     */
    function unpauseProtocol() external onlyOwner whenPaused {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Allows the owner/DAO to withdraw accumulated protocol fees.
     * @param amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(uint256 amount) external onlyOwner {
        require(totalProtocolFees >= amount, "SynapseAI: Insufficient accumulated fees.");
        require(synapseToken.transfer(owner(), amount), "SynapseAI: Fee withdrawal failed.");
        totalProtocolFees = totalProtocolFees.sub(amount);
        emit ProtocolFeesWithdrawn(owner(), amount);
    }

    // --- II. Staking & Rewards ---

    /**
     * @dev Allows users to stake SynapseTokens to participate in the protocol.
     * @param amount The amount of SynapseTokens to stake.
     */
    function stakeTokens(uint256 amount) external whenNotPaused {
        require(amount > 0, "SynapseAI: Stake amount must be greater than zero.");
        require(synapseToken.transferFrom(msg.sender, address(this), amount), "SynapseAI: Token transfer for staking failed.");
        userStakes[msg.sender] = userStakes[msg.sender].add(amount);
        emit SynapseTokensStaked(msg.sender, amount);
    }

    /**
     * @dev Allows users to unstake their SynapseTokens.
     *      Funds might be subject to a cooldown or lock-up depending on active tasks.
     *      For simplicity, no cooldown is implemented here, but it's a common feature.
     * @param amount The amount of SynapseTokens to unstake.
     */
    function unstakeTokens(uint256 amount) external whenNotPaused {
        require(amount > 0, "SynapseAI: Unstake amount must be greater than zero.");
        require(userStakes[msg.sender] >= amount, "SynapseAI: Insufficient staked tokens.");
        // Additional checks: ensure user is not actively participating in a task that requires this stake.
        // For simplicity, we assume the user manages their stakes.
        userStakes[msg.sender] = userStakes[msg.sender].sub(amount);
        require(synapseToken.transfer(msg.sender, amount), "SynapseAI: Token transfer for unstaking failed.");
        emit SynapseTokensUnstaked(msg.sender, amount);
    }

    /**
     * @dev Allows users to claim their accumulated SynapseToken rewards.
     */
    function claimRewards() external whenNotPaused {
        uint256 rewards = pendingRewards[msg.sender];
        require(rewards > 0, "SynapseAI: No rewards to claim.");
        pendingRewards[msg.sender] = 0;
        require(synapseToken.transfer(msg.sender, rewards), "SynapseAI: Reward transfer failed.");
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev A view function to query the total SynapseToken rewards currently claimable by a specific user.
     * @param user The address of the user.
     * @return The amount of pending rewards.
     */
    function getPendingRewards(address user) external view returns (uint256) {
        return pendingRewards[user];
    }

    // --- III. Data Workflow ---

    /**
     * @dev Allows a staked user to submit a new dataset for validation.
     * @param datasetHash Cryptographic hash of the dataset content.
     * @param datasetCID IPFS Content Identifier where the dataset is stored.
     */
    function submitDataset(string memory datasetHash, string memory datasetCID) external whenNotPaused {
        require(bytes(datasetHash).length > 0 && bytes(datasetCID).length > 0, "SynapseAI: Dataset hash and CID cannot be empty.");
        require(userStakes[msg.sender] >= dataSubmitterStake, "SynapseAI: Insufficient stake to submit dataset.");

        DatasetProposal storage newDataset = datasetProposals[nextDatasetId];
        newDataset.id = nextDatasetId;
        newDataset.submitter = msg.sender;
        newDataset.datasetHash = datasetHash;
        newDataset.datasetCID = datasetCID;
        newDataset.stakedAmount = dataSubmitterStake;
        newDataset.submissionTime = block.timestamp;
        newDataset.validationDeadline = block.timestamp.add(datasetValidationPeriod);
        newDataset.status = TaskStatus.Pending;

        // Lock stake for the task
        userStakes[msg.sender] = userStakes[msg.sender].sub(dataSubmitterStake);
        // Transfer stake to contract for management
        require(synapseToken.transferFrom(msg.sender, address(this), dataSubmitterStake), "SynapseAI: Failed to lock stake for dataset.");

        emit DatasetSubmitted(nextDatasetId, msg.sender, datasetHash, datasetCID);
        nextDatasetId = nextDatasetId.add(1);
    }

    /**
     * @dev Allows a staked user to register as a data validator.
     */
    function registerAsDataValidator() external whenNotPaused {
        require(userStakes[msg.sender] >= dataValidatorStake, "SynapseAI: Insufficient stake to register as data validator.");
        require(!isDataValidator[msg.sender], "SynapseAI: Already registered as data validator.");
        isDataValidator[msg.sender] = true;
        // Lock stake for the role
        userStakes[msg.sender] = userStakes[msg.sender].sub(dataValidatorStake);
        require(synapseToken.transferFrom(msg.sender, address(this), dataValidatorStake), "SynapseAI: Failed to lock stake for validator role.");
        emit DataValidatorRegistered(msg.sender);
    }

    /**
     * @dev Allows a registered data validator to claim an unvalidated dataset to review.
     * @param datasetId The ID of the dataset to claim.
     */
    function claimDataValidationTask(uint256 datasetId) external onlyDataValidator whenNotPaused {
        DatasetProposal storage dataset = datasetProposals[datasetId];
        require(dataset.id != 0, "SynapseAI: Dataset not found.");
        require(dataset.status == TaskStatus.Pending, "SynapseAI: Dataset not in Pending status.");
        require(!dataset.hasValidated[msg.sender], "SynapseAI: Already validated this dataset.");
        require(block.timestamp < dataset.validationDeadline, "SynapseAI: Validation period for this dataset has ended.");

        DataValidationTask storage newTask = dataValidationTasks[nextDataValidationTaskId];
        newTask.id = nextDataValidationTaskId;
        newTask.datasetId = datasetId;
        newTask.validator = msg.sender;
        newTask.claimTime = block.timestamp;
        newTask.status = TaskStatus.InProgress;

        // Mark dataset as in progress if it's the first claim (optional, could have multiple validators simultaneously)
        if (dataset.status == TaskStatus.Pending) {
            dataset.status = TaskStatus.InProgress;
        }

        emit DataValidationTaskClaimed(nextDataValidationTaskId, datasetId, msg.sender);
        nextDataValidationTaskId = nextDataValidationTaskId.add(1);
    }

    /**
     * @dev A validator submits their judgment on the dataset's quality and any generated metadata CID.
     * @param taskId The ID of the data validation task.
     * @param isValid True if the validator deems the dataset valid, false otherwise.
     * @param metadataCID IPFS CID of any generated metadata (e.g., labels).
     */
    function submitDataValidationResult(uint256 taskId, bool isValid, string memory metadataCID) external onlyDataValidator whenNotPaused {
        DataValidationTask storage task = dataValidationTasks[taskId];
        require(task.id != 0, "SynapseAI: Validation task not found.");
        require(task.validator == msg.sender, "SynapseAI: Caller is not the assigned validator for this task.");
        require(task.status == TaskStatus.InProgress, "SynapseAI: Task not in InProgress status.");
        require(!task.submittedResult, "SynapseAI: Result already submitted for this task.");

        DatasetProposal storage dataset = datasetProposals[task.datasetId];
        require(block.timestamp < dataset.validationDeadline, "SynapseAI: Validation period for this dataset has ended.");

        task.isValid = isValid;
        task.metadataCID = metadataCID;
        task.status = TaskStatus.Resolved;
        task.submittedResult = true;

        if (isValid) {
            dataset.yesVotes = dataset.yesVotes.add(1);
        } else {
            dataset.noVotes = dataset.noVotes.add(1);
        }
        dataset.hasValidated[msg.sender] = true; // Mark validator as having participated for this dataset

        emit DataValidationResultSubmitted(taskId, msg.sender, isValid, metadataCID);
    }

    /**
     * @dev Finalizes the validation process for a dataset based on aggregated validator results.
     *      Distributes rewards/slashes and updates reputations/NFTs.
     *      Can be called by anyone once the deadline is passed, or enough validators have submitted.
     * @param datasetId The ID of the dataset to finalize.
     */
    function finalizeDatasetValidation(uint256 datasetId) external whenNotPaused {
        DatasetProposal storage dataset = datasetProposals[datasetId];
        require(dataset.id != 0, "SynapseAI: Dataset not found.");
        require(!dataset.isFinalized, "SynapseAI: Dataset validation already finalized.");
        require(block.timestamp >= dataset.validationDeadline || dataset.yesVotes.add(dataset.noVotes) >= 3, // Simple majority threshold
            "SynapseAI: Validation period not over or not enough validators.");

        uint256 totalVotes = dataset.yesVotes.add(dataset.noVotes);
        require(totalVotes > 0, "SynapseAI: No validation results submitted yet.");

        // Determine consensus
        bool consensusIsValid = dataset.yesVotes >= dataset.noVotes; // Simple majority

        uint256 totalRewardPool = dataset.stakedAmount; // Initial stake acts as reward pool
        uint256 submitterReward = 0;
        uint256 validatorReward = 0;
        uint256 feeAmount = 0;

        if (consensusIsValid) {
            dataset.status = TaskStatus.Resolved;
            submitterReward = dataSubmitterStake.mul(dataSubmitterRewardMultiplier).div(100); // 100 is base multiplier
            totalRewardPool = totalRewardPool.add(submitterReward); // Add submitter's reward to pool if successful

            // Calculate fee
            feeAmount = totalRewardPool.mul(protocolFeePercentage).div(1000);
            totalProtocolFees = totalProtocolFees.add(feeAmount);
            totalRewardPool = totalRewardPool.sub(feeAmount);

            // Reward for submitter (getting back stake + reward)
            pendingRewards[dataset.submitter] = pendingRewards[dataset.submitter].add(dataset.stakedAmount.add(submitterReward));
            _updateUserReputation(dataset.submitter, BASE_REPUTATION_REWARD.mul(dataSubmitterRewardMultiplier).div(100)); // Rep gain
            _updateAIPersonaNFTTraits(dataset.submitter, 0, 1, 0, 0); // Update NFT for successful submission

            // Distribute rewards to validators who voted 'isValid = true'
            uint256 successfulValidators = dataset.yesVotes;
            if (successfulValidators > 0) {
                validatorReward = totalRewardPool.mul(dataValidatorRewardMultiplier).div(100).div(successfulValidators); // Reward per validator
                for (uint256 i = 1; i < nextDataValidationTaskId; i++) {
                    DataValidationTask storage task = dataValidationTasks[i];
                    if (task.datasetId == datasetId && task.submittedResult && task.isValid) {
                        pendingRewards[task.validator] = pendingRewards[task.validator].add(validatorReward);
                        _updateUserReputation(task.validator, BASE_REPUTATION_REWARD.mul(dataValidatorRewardMultiplier).div(100)); // Rep gain
                        _updateAIPersonaNFTTraits(task.validator, 1, 0, 10, 0); // Update NFT for correct validation
                    }
                }
            }
        } else {
            // Dataset deemed invalid, submitter stake slashed, validators who voted 'isValid = false' rewarded.
            dataset.status = TaskStatus.Failed;
            // The submitter's initial stake is implicitly lost from their balance if it was transferred to the contract
            // and not returned. We can consider it burnt or distributed. Here, it will be redistributed to correct validators.
            
            // Calculate fee from submitter's slashed stake (if any)
            feeAmount = dataset.stakedAmount.mul(protocolFeePercentage).div(1000);
            totalProtocolFees = totalProtocolFees.add(feeAmount);
            uint256 slashPool = dataset.stakedAmount.sub(feeAmount); // Remaining after fee

            _updateUserReputation(dataset.submitter, MAX_REPUTATION_SCORE.sub(BASE_REPUTATION_REWARD.mul(dataSubmitterRewardMultiplier).div(100))); // Rep loss
            _updateAIPersonaNFTTraits(dataset.submitter, 0, 0, -10, 0); // Update NFT for failed submission

            uint256 successfulValidators = dataset.noVotes;
            if (successfulValidators > 0) {
                validatorReward = slashPool.div(successfulValidators); // Reward per validator from slashed stake
                for (uint256 i = 1; i < nextDataValidationTaskId; i++) {
                    DataValidationTask storage task = dataValidationTasks[i];
                    if (task.datasetId == datasetId && task.submittedResult && !task.isValid) {
                        pendingRewards[task.validator] = pendingRewards[task.validator].add(validatorReward);
                        _updateUserReputation(task.validator, BASE_REPUTATION_REWARD.mul(dataValidatorRewardMultiplier).div(100)); // Rep gain
                        _updateAIPersonaNFTTraits(task.validator, 1, 0, 10, 0); // Update NFT for correct validation
                    }
                }
            }
        }

        dataset.isFinalized = true;
        // The contract holds the pooled funds, and they are distributed via pendingRewards.
        // Any remaining funds in the contract will be part of the totalProtocolFees or governance can decide to return/burn.

        emit DatasetValidationFinalized(datasetId, dataset.status, totalRewardPool);
    }

    /**
     * @dev Model submitters request access to validated datasets.
     *      This is purely a record-keeping function on-chain. Actual data access is off-chain (e.g., IPFS).
     * @param datasetId The ID of the validated dataset.
     */
    function requestDatasetAccess(uint256 datasetId) external whenNotPaused {
        DatasetProposal storage dataset = datasetProposals[datasetId];
        require(dataset.id != 0, "SynapseAI: Dataset not found.");
        require(dataset.isFinalized && dataset.status == TaskStatus.Resolved, "SynapseAI: Dataset not yet finalized or invalid.");
        // No fee/permissioning implemented here, could be added later.
        // This function primarily serves as an on-chain record that someone expressed interest.
        // Off-chain, this might trigger a revelation of datasetCID to the caller.
    }

    // --- IV. Model Workflow ---

    /**
     * @dev Allows a staked user to submit an AI model trained on a specific validated dataset.
     * @param modelHash Cryptographic hash of the model content.
     * @param modelCID IPFS Content Identifier where the model is stored.
     * @param datasetId The ID of the dataset the model was trained on.
     */
    function submitModel(string memory modelHash, string memory modelCID, uint256 datasetId) external whenNotPaused {
        require(bytes(modelHash).length > 0 && bytes(modelCID).length > 0, "SynapseAI: Model hash and CID cannot be empty.");
        require(datasetProposals[datasetId].id != 0 && datasetProposals[datasetId].isFinalized && datasetProposals[datasetId].status == TaskStatus.Resolved, "SynapseAI: Invalid or unvalidated dataset.");
        require(userStakes[msg.sender] >= modelSubmitterStake, "SynapseAI: Insufficient stake to submit model.");

        ModelProposal storage newModel = modelProposals[nextModelId];
        newModel.id = nextModelId;
        newModel.submitter = msg.sender;
        newModel.modelHash = modelHash;
        newModel.modelCID = modelCID;
        newModel.datasetId = datasetId;
        newModel.stakedAmount = modelSubmitterStake;
        newModel.submissionTime = block.timestamp;
        newModel.evaluationDeadline = block.timestamp.add(modelEvaluationPeriod);
        newModel.status = TaskStatus.Pending;

        // Lock stake for the task
        userStakes[msg.sender] = userStakes[msg.sender].sub(modelSubmitterStake);
        // Transfer stake to contract for management
        require(synapseToken.transferFrom(msg.sender, address(this), modelSubmitterStake), "SynapseAI: Failed to lock stake for model.");

        emit ModelSubmitted(nextModelId, msg.sender, modelHash, modelCID, datasetId);
        nextModelId = nextModelId.add(1);
    }

    /**
     * @dev Allows a staked user to register as a model evaluator.
     */
    function registerAsModelEvaluator() external whenNotPaused {
        require(userStakes[msg.sender] >= modelEvaluatorStake, "SynapseAI: Insufficient stake to register as model evaluator.");
        require(!isModelEvaluator[msg.sender], "SynapseAI: Already registered as model evaluator.");
        isModelEvaluator[msg.sender] = true;
        // Lock stake for the role
        userStakes[msg.sender] = userStakes[msg.sender].sub(modelEvaluatorStake);
        require(synapseToken.transferFrom(msg.sender, address(this), modelEvaluatorStake), "SynapseAI: Failed to lock stake for evaluator role.");
        emit ModelEvaluatorRegistered(msg.sender);
    }

    /**
     * @dev Allows a registered model evaluator to claim an unevaluated model to test.
     * @param modelId The ID of the model to claim.
     */
    function claimModelEvaluationTask(uint256 modelId) external onlyModelEvaluator whenNotPaused {
        ModelProposal storage model = modelProposals[modelId];
        require(model.id != 0, "SynapseAI: Model not found.");
        require(model.status == TaskStatus.Pending, "SynapseAI: Model not in Pending status.");
        require(!model.hasEvaluated[msg.sender], "SynapseAI: Already evaluated this model.");
        require(block.timestamp < model.evaluationDeadline, "SynapseAI: Evaluation period for this model has ended.");

        ModelEvaluationTask storage newTask = modelEvaluationTasks[nextModelEvaluationTaskId];
        newTask.id = nextModelEvaluationTaskId;
        newTask.modelId = modelId;
        newTask.evaluator = msg.sender;
        newTask.claimTime = block.timestamp;
        newTask.status = TaskStatus.InProgress;

        // Mark model as in progress if it's the first claim
        if (model.status == TaskStatus.Pending) {
            model.status = TaskStatus.InProgress;
        }

        emit ModelEvaluationTaskClaimed(nextModelEvaluationTaskId, modelId, msg.sender);
        nextModelEvaluationTaskId = nextModelEvaluationTaskId.add(1);
    }

    /**
     * @dev An evaluator submits the model's performance score and any detailed metrics CID.
     * @param taskId The ID of the model evaluation task.
     * @param performanceScore The numerical performance score (e.g., accuracy * 1000).
     * @param metricsCID IPFS CID of detailed evaluation metrics.
     */
    function submitModelEvaluationResult(uint256 taskId, uint256 performanceScore, string memory metricsCID) external onlyModelEvaluator whenNotPaused {
        ModelEvaluationTask storage task = modelEvaluationTasks[taskId];
        require(task.id != 0, "SynapseAI: Evaluation task not found.");
        require(task.evaluator == msg.sender, "SynapseAI: Caller is not the assigned evaluator for this task.");
        require(task.status == TaskStatus.InProgress, "SynapseAI: Task not in InProgress status.");
        require(!task.submittedResult, "SynapseAI: Result already submitted for this task.");

        ModelProposal storage model = modelProposals[task.modelId];
        require(block.timestamp < model.evaluationDeadline, "SynapseAI: Evaluation period for this model has ended.");

        task.performanceScore = performanceScore;
        task.metricsCID = metricsCID;
        task.status = TaskStatus.Resolved;
        task.submittedResult = true;

        model.totalPerformanceScore = model.totalPerformanceScore.add(performanceScore);
        model.evaluatorCount = model.evaluatorCount.add(1);
        model.hasEvaluated[msg.sender] = true;

        emit ModelEvaluationResultSubmitted(taskId, msg.sender, performanceScore, metricsCID);
    }

    /**
     * @dev Finalizes the evaluation process for a model based on aggregated evaluator results.
     *      Distributes rewards/slashes and updates reputations/NFTs.
     * @param modelId The ID of the model to finalize.
     */
    function finalizeModelEvaluation(uint256 modelId) external whenNotPaused {
        ModelProposal storage model = modelProposals[modelId];
        require(model.id != 0, "SynapseAI: Model not found.");
        require(!model.isFinalized, "SynapseAI: Model evaluation already finalized.");
        require(block.timestamp >= model.evaluationDeadline || model.evaluatorCount >= 3, // Simple threshold for evaluation
            "SynapseAI: Evaluation period not over or not enough evaluators.");

        require(model.evaluatorCount > 0, "SynapseAI: No evaluation results submitted yet.");

        model.averagePerformance = model.totalPerformanceScore.div(model.evaluatorCount);

        uint256 totalRewardPool = model.stakedAmount; // Initial stake acts as reward pool
        uint256 submitterReward = 0;
        uint256 evaluatorReward = 0;
        uint256 feeAmount = 0;

        // Simple logic: if average performance is above a threshold, consider it successful
        // (e.g., 70% accuracy, assuming performanceScore is accuracy * 1000, so 700)
        bool modelIsSuccessful = model.averagePerformance >= 700;

        if (modelIsSuccessful) {
            model.status = TaskStatus.Resolved;
            submitterReward = modelSubmitterStake.mul(modelSubmitterRewardMultiplier).div(100);
            totalRewardPool = totalRewardPool.add(submitterReward);

            feeAmount = totalRewardPool.mul(protocolFeePercentage).div(1000);
            totalProtocolFees = totalProtocolFees.add(feeAmount);
            totalRewardPool = totalRewardPool.sub(feeAmount);

            pendingRewards[model.submitter] = pendingRewards[model.submitter].add(model.stakedAmount.add(submitterReward));
            _updateUserReputation(model.submitter, BASE_REPUTATION_REWARD.mul(modelSubmitterRewardMultiplier).div(100)); // Rep gain
            _updateAIPersonaNFTTraits(model.submitter, 0, 1, 0, model.averagePerformance); // Update NFT for successful model

            evaluatorReward = totalRewardPool.mul(modelEvaluatorRewardMultiplier).div(100).div(model.evaluatorCount);
            for (uint256 i = 1; i < nextModelEvaluationTaskId; i++) {
                ModelEvaluationTask storage task = modelEvaluationTasks[i];
                if (task.modelId == modelId && task.submittedResult) { // All evaluators get rewarded if model is successful
                    pendingRewards[task.evaluator] = pendingRewards[task.evaluator].add(evaluatorReward);
                    _updateUserReputation(task.evaluator, BASE_REPUTATION_REWARD.mul(modelEvaluatorRewardMultiplier).div(100)); // Rep gain
                    _updateAIPersonaNFTTraits(task.evaluator, 0, 0, 0, task.performanceScore); // Update NFT for evaluation contribution
                }
            }
        } else {
            // Model failed, submitter stake slashed
            model.status = TaskStatus.Failed;

            feeAmount = model.stakedAmount.mul(protocolFeePercentage).div(1000);
            totalProtocolFees = totalProtocolFees.add(feeAmount);
            uint256 slashPool = model.stakedAmount.sub(feeAmount);

            _updateUserReputation(model.submitter, MAX_REPUTATION_SCORE.sub(BASE_REPUTATION_REWARD.mul(modelSubmitterRewardMultiplier).div(100))); // Rep loss
            _updateAIPersonaNFTTraits(model.submitter, 0, -1, 0, 0); // Update NFT for failed model

            evaluatorReward = slashPool.div(model.evaluatorCount);
            for (uint256 i = 1; i < nextModelEvaluationTaskId; i++) {
                ModelEvaluationTask storage task = modelEvaluationTasks[i];
                if (task.modelId == modelId && task.submittedResult) { // All evaluators get rewarded from slashed stake
                    pendingRewards[task.evaluator] = pendingRewards[task.evaluator].add(evaluatorReward);
                    _updateUserReputation(task.evaluator, BASE_REPUTATION_REWARD.mul(modelEvaluatorRewardMultiplier).div(100)); // Rep gain
                    _updateAIPersonaNFTTraits(task.evaluator, 0, 0, 0, task.performanceScore); // Update NFT for evaluation contribution
                }
            }
        }

        model.isFinalized = true;

        emit ModelEvaluationFinalized(modelId, model.status, model.averagePerformance, totalRewardPool);
    }

    /**
     * @dev Users request access to highly-rated models.
     *      Similar to dataset access, this is record-keeping.
     * @param modelId The ID of the highly-rated model.
     */
    function requestModelAccess(uint256 modelId) external whenNotPaused {
        ModelProposal storage model = modelProposals[modelId];
        require(model.id != 0, "SynapseAI: Model not found.");
        require(model.isFinalized && model.status == TaskStatus.Resolved && model.averagePerformance >= 800, "SynapseAI: Model not yet finalized, failed, or not high-performing."); // Example: min 80% score
        // Off-chain, this might trigger revelation of modelCID.
    }

    // --- V. AI Persona NFT (Soulbound) ---

    /**
     * @dev Mints a unique, soulbound AI Persona NFT for the caller if they don't already possess one.
     */
    function mintAIPersonaNFT() external whenNotPaused {
        require(aiPersonaNFTTokenId[msg.sender] == 0, "SynapseAI: You already own an AI Persona NFT.");

        uint256 tokenId = nextNFTId;
        _safeMint(msg.sender, tokenId);
        aiPersonaNFTTokenId[msg.sender] = tokenId;
        aiPersonaTraits[msg.sender] = AIPersonaTraits({
            dataCuratorLevel: 0,
            modelOptimizerScore: 0,
            validationAccuracy: 50, // Start at 50%
            synapseContributionPoints: 0,
            epochParticipations: 0,
            reputationLastUpdated: block.timestamp
        });

        emit AIPersonaNFTMinted(msg.sender, tokenId);
        nextNFTId = nextNFTId.add(1);
    }

    /**
     * @dev A view function to retrieve the current on-chain traits of a user's AI Persona NFT.
     * @param owner The address of the NFT owner.
     * @return AIPersonaTraits struct containing the current traits.
     */
    function getAIPersonaNFTTraits(address owner) external view returns (AIPersonaTraits memory) {
        require(aiPersonaNFTTokenId[owner] != 0, "SynapseAI: User does not own an AI Persona NFT.");
        return aiPersonaTraits[owner];
    }

    /**
     * @dev Returns the URI for the NFT metadata, dynamically generating it based on the current on-chain traits.
     *      This is an override from ERC721.
     * @param tokenId The ID of the NFT.
     * @return A data URI containing the JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address ownerOfToken = ownerOf(tokenId);
        AIPersonaTraits storage traits = aiPersonaTraits[ownerOfToken];

        // Construct dynamic JSON metadata string
        string memory json = string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name": "AI Persona #', _toString(tokenId), '",',
                        '"description": "A soulbound NFT representing contribution and reputation in the SynapseAI Protocol.",',
                        '"image": "ipfs://Qmb8Y5F3R4S9C2P1N7K6M5H0J1L2A3B4C5D6E7F8G9",', // Placeholder image
                        '"attributes": [',
                            '{"trait_type": "Data Curator Level", "value": ', _toString(traits.dataCuratorLevel), '},',
                            '{"trait_type": "Model Optimizer Score", "value": ', _toString(traits.modelOptimizerScore), '},',
                            '{"trait_type": "Validation Accuracy", "value": ', _toString(traits.validationAccuracy), '},',
                            '{"trait_type": "Contribution Points", "value": ', _toString(traits.synapseContributionPoints), '},',
                            '{"trait_type": "Epoch Participations", "value": ', _toString(traits.epochParticipations), '}',
                        ']}'
                    )
                )
            )
        ));
        return json;
    }

    // --- VI. Reputation & Governance ---

    /**
     * @dev A view function to query a user's current global reputation score.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @dev Allows users with sufficient reputation to propose changes to protocol parameters.
     *      The proposal data should be an encoded function call and its parameters.
     * @param proposalData Encoded function call (e.g., `abi.encodeWithSelector(this.setProtocolParameters.selector, ...)`)
     * @param descriptionCID IPFS CID for a detailed, human-readable description of the proposal.
     */
    function proposeProtocolChange(bytes memory proposalData, string memory descriptionCID) external whenNotPaused {
        require(userReputation[msg.sender] >= MIN_GOVERNANCE_REPUTATION, "SynapseAI: Insufficient reputation to propose.");
        require(bytes(descriptionCID).length > 0, "SynapseAI: Proposal description CID cannot be empty.");
        require(proposalData.length > 0, "SynapseAI: Proposal data cannot be empty.");

        GovernanceProposal storage newProposal = governanceProposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.proposer = msg.sender;
        newProposal.proposalData = proposalData;
        newProposal.descriptionCID = descriptionCID;
        newProposal.creationTime = block.timestamp;
        newProposal.votingDeadline = block.timestamp.add(7 days); // 7-day voting period
        
        emit GovernanceProposalCreated(nextProposalId, msg.sender, descriptionCID);
        nextProposalId = nextProposalId.add(1);
    }

    /**
     * @dev Reputable users cast their vote (support or oppose) on an active governance proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote 'yes', false to vote 'no'.
     */
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.id != 0, "SynapseAI: Proposal not found.");
        require(block.timestamp < proposal.votingDeadline, "SynapseAI: Voting period has ended.");
        require(userReputation[msg.sender] >= MIN_GOVERNANCE_REPUTATION, "SynapseAI: Insufficient reputation to vote.");
        require(!proposal.hasVoted[msg.sender], "SynapseAI: Already voted on this proposal.");

        uint256 voteWeight = userReputation[msg.sender]; // Reputation as vote weight
        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(voteWeight);
        } else {
            proposal.noVotes = proposal.noVotes.add(voteWeight);
        }
        proposal.hasVoted[msg.sender] = true;

        emit GovernanceVoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal that has reached the required consensus and passed its voting period.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.id != 0, "SynapseAI: Proposal not found.");
        require(block.timestamp >= proposal.votingDeadline, "SynapseAI: Voting period has not ended.");
        require(!proposal.executed, "SynapseAI: Proposal already executed.");

        // Simple majority vote based on reputation weight
        bool approved = proposal.yesVotes > proposal.noVotes;
        proposal.approved = approved;

        if (approved) {
            // Execute the proposal data
            (bool success,) = address(this).call(proposal.proposalData);
            require(success, "SynapseAI: Proposal execution failed.");
            proposal.executed = true;
            emit GovernanceProposalExecuted(proposalId, true);
        } else {
            proposal.executed = true; // Mark as executed even if failed to prevent re-execution
            emit GovernanceProposalExecuted(proposalId, false);
        }
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to update a user's global reputation score.
     *      Reputation decays over time; positive contributions increase it, negative decrease it.
     * @param user The address of the user.
     * @param scoreChange The amount to change the score by. Can be positive or negative.
     */
    function _updateUserReputation(address user, int256 scoreChange) internal {
        // Apply decay if enough time has passed since last update (simple epoch-based decay)
        uint256 lastUpdated = aiPersonaTraits[user].reputationLastUpdated;
        if (lastUpdated != 0 && block.timestamp > lastUpdated) {
            uint256 epochsPassed = (block.timestamp.sub(lastUpdated)).div(30 days); // Example: Decay every 30 days
            if (epochsPassed > 0) {
                uint256 currentRep = userReputation[user];
                uint256 decayAmount = currentRep.mul(REPUTATION_DECAY_RATE).div(100).mul(epochsPassed);
                userReputation[user] = currentRep.sub(decayAmount > currentRep ? currentRep : decayAmount);
            }
        }
        aiPersonaTraits[user].reputationLastUpdated = block.timestamp;

        // Apply new score change
        if (scoreChange > 0) {
            userReputation[user] = userReputation[user].add(uint256(scoreChange)).min(MAX_REPUTATION_SCORE);
        } else {
            uint256 absChange = uint256(-scoreChange);
            userReputation[user] = userReputation[user].sub(absChange > userReputation[user] ? userReputation[user] : absChange);
        }
    }

    /**
     * @dev Internal function to update the traits of a user's AI Persona NFT.
     *      If the user doesn't have an NFT, nothing happens.
     * @param user The address of the NFT owner.
     * @param dataCuratorLevelChange Amount to change Data Curator Level by.
     * @param modelOptimizerScoreChange Amount to change Model Optimizer Score by.
     * @param validationAccuracyChange Amount to change Validation Accuracy by (can be negative).
     * @param synapseContributionPointsChange Amount to change Contribution Points by.
     */
    function _updateAIPersonaNFTTraits(
        address user,
        int256 dataCuratorLevelChange,
        int256 modelOptimizerScoreChange,
        int256 validationAccuracyChange,
        int256 synapseContributionPointsChange
    ) internal {
        if (aiPersonaNFTTokenId[user] == 0) {
            // User doesn't have an NFT, cannot update traits.
            return;
        }

        AIPersonaTraits storage traits = aiPersonaTraits[user];

        // Apply changes, ensuring non-negative where applicable and bounds.
        if (dataCuratorLevelChange > 0) traits.dataCuratorLevel = traits.dataCuratorLevel.add(uint256(dataCuratorLevelChange));
        if (modelOptimizerScoreChange > 0) traits.modelOptimizerScore = traits.modelOptimizerScore.add(uint256(modelOptimizerScoreChange));
        
        // Validation Accuracy (0-100)
        if (validationAccuracyChange > 0) {
            traits.validationAccuracy = traits.validationAccuracy.add(uint256(validationAccuracyChange)).min(100);
        } else if (validationAccuracyChange < 0) {
            uint256 absChange = uint256(-validationAccuracyChange);
            traits.validationAccuracy = traits.validationAccuracy.sub(absChange > traits.validationAccuracy ? traits.validationAccuracy : absChange);
        }

        if (synapseContributionPointsChange > 0) traits.synapseContributionPoints = traits.synapseContributionPoints.add(uint256(synapseContributionPointsChange));
        
        traits.epochParticipations = traits.epochParticipations.add(1); // Increment for participation

        emit AIPersonaNFTTraitsUpdated(user, aiPersonaNFTTokenId[user], traits);
        // Note: tokenURI will reflect these changes dynamically without needing to call _setTokenURI
    }

    /**
     * @dev Converts a uint256 to a string.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// Minimal Base64 encoding for on-chain dynamic JSON metadata
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // allocate the output buffer in memory
        bytes memory buffer = new bytes(encodedLen);

        uint256 i;
        uint256 j;
        while (i < data.length) {
            uint256 b1 = data[i];
            uint256 b2 = i + 1 < data.length ? data[i + 1] : 0;
            uint256 b3 = i + 2 < data.length ? data[i + 2] : 0;

            uint256 enc1 = b1 >> 2;
            uint256 enc2 = ((b1 & 0x03) << 4) | (b2 >> 4);
            uint256 enc3 = ((b2 & 0x0F) << 2) | (b3 >> 6);
            uint256 enc4 = b3 & 0x3F;

            buffer[j] = bytes1(table[enc1]);
            buffer[j + 1] = bytes1(table[enc2]);
            buffer[j + 2] = bytes1(table[enc3]);
            buffer[j + 3] = bytes1(table[enc4]);

            i += 3;
            j += 4;
        }

        // Pad with '='
        if (data.length % 3 == 1) {
            buffer[encodedLen - 2] = '=';
            buffer[encodedLen - 1] = '=';
        } else if (data.length % 3 == 2) {
            buffer[encodedLen - 1] = '=';
        }

        return string(buffer);
    }
}