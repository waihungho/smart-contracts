This smart contract, `DeSciAI_ModelMarket`, is designed as a decentralized platform for AI model owners, dataset providers, and evaluators. It incorporates advanced concepts such as reputation-backed staking, on-chain evaluation orchestration (with off-chain verification), a dispute resolution mechanism, and a basic DAO for protocol governance. The aim is to create a trusted environment for AI model development and validation within the decentralized science (DeSci) paradigm.

---

# DeSciAI_ModelMarket: Smart Contract Outline and Function Summary

## Contract Name: `DeSciAI_ModelMarket`

**Description:** A decentralized marketplace and evaluation system for AI models. Model owners can submit their AI models (referenced by IPFS hashes) and request evaluations against specific datasets. Evaluators stake tokens to participate, claim evaluation tasks, run models off-chain, and submit cryptographic proofs/results hashes on-chain. The system incorporates a reputation mechanism, dispute resolution, and DAO-like governance for protocol parameter adjustments.

**Key Concepts:**
*   **Decentralized AI Model & Dataset Registry:** IPFS-based referencing for off-chain assets (AI models, datasets).
*   **Reputation-Backed Evaluation:** Evaluators stake tokens and earn reputation for accurate and timely work. Malicious behavior leads to stake slashing and reputation loss.
*   **On-chain Evaluation Orchestration:** The smart contract coordinates the lifecycle of an evaluation task, from request to completion or dispute resolution.
*   **ZKP/Proof Integration (Conceptual):** The contract provides an interface for submitting verifiable computation results (e.g., a ZKP or signed attestation) which would be verified off-chain, with the hash committed on-chain.
*   **Dispute Resolution:** A mechanism for challenging and resolving conflicting or incorrect evaluation outcomes, managed by the protocol owner/committee.
*   **DAO Governance:** Reputation-weighted voting allows stakeholders to propose and vote on changes to core protocol parameters.

---

## Function Summary (20 Functions)

### I. Core Registry & Management Functions (5 functions)

1.  **`registerEvaluator()`**
    *   **Purpose:** Allows a user to stake `minEvaluatorStake` AIToken to become a registered evaluator, enabling them to participate in model evaluations.
    *   **Access:** Anyone.
    *   **Pre-conditions:** Caller must have approved the `minEvaluatorStake` amount to the contract.
2.  **`updateEvaluatorProfile(string calldata _metadataUri)`**
    *   **Purpose:** Allows an active evaluator to update their off-chain profile metadata URI (e.g., link to their evaluation environment details, credentials).
    *   **Access:** Only registered evaluators.
3.  **`submitModel(string calldata _name, string calldata _description, string calldata _ipfsHash, string calldata _metadataUri)`**
    *   **Purpose:** Registers a new AI model on the platform with its descriptive details, an IPFS hash pointing to its weights/code, and an optional metadata URI.
    *   **Access:** Anyone.
    *   **Returns:** `modelId` (uint256) - The unique ID of the newly registered model.
4.  **`submitDataset(string calldata _name, string calldata _description, string calldata _ipfsHash, string calldata _metadataUri)`**
    *   **Purpose:** Registers a new dataset on the platform with its descriptive details, an IPFS hash pointing to its content, and an optional metadata URI.
    *   **Access:** Anyone.
    *   **Returns:** `datasetId` (uint256) - The unique ID of the newly registered dataset.
5.  **`withdrawEvaluatorStake()`**
    *   **Purpose:** Allows a registered evaluator to withdraw their staked AIToken.
    *   **Access:** Only registered evaluators.
    *   **Pre-conditions:** The evaluator must have no active evaluation tasks and a cooldown period must have passed since their last stake update.

### II. Evaluation Lifecycle Functions (6 functions)

6.  **`requestModelEvaluation(uint256 _modelId, uint256 _datasetId)`**
    *   **Purpose:** A model owner requests an evaluation for their submitted AI model against a specific dataset, paying an `evaluationFee` in AIToken.
    *   **Access:** Anyone.
    *   **Pre-conditions:** Model and dataset must exist and be active. Caller must have approved `evaluationFee` to the contract.
    *   **Returns:** `taskId` (uint256) - The unique ID of the created evaluation task.
7.  **`claimEvaluationTask(uint256 _taskId)`**
    *   **Purpose:** A registered evaluator claims a pending evaluation task, becoming responsible for performing the off-chain evaluation.
    *   **Access:** Only registered evaluators.
    *   **Pre-conditions:** The task must be in `Pending` status and the evaluator must not have too many active tasks.
8.  **`submitEvaluationResults(uint256 _taskId, bytes32 _evaluationResultsHash, bytes calldata _proofData)`**
    *   **Purpose:** The assigned evaluator submits a cryptographic hash of the off-chain evaluation results and optional proof data (e.g., a ZKP or signed attestation) to the contract.
    *   **Access:** Only the assigned evaluator for the given task.
    *   **Pre-conditions:** The task must be in `Claimed` status and `_evaluationResultsHash` cannot be zero.
9.  **`disputeEvaluationResults(uint256 _taskId)`**
    *   **Purpose:** Allows the model owner or another qualified evaluator to challenge the integrity or accuracy of submitted evaluation results.
    *   **Access:** Model owner or a registered evaluator with sufficient reputation.
    *   **Pre-conditions:** The task must be in `Submitted` status and within the `disputeWindowDuration`.
10. **`resolveDispute(uint256 _taskId, bool _evaluatorWasCorrect)`**
    *   **Purpose:** The protocol owner (or a designated committee) resolves a dispute. This function adjusts evaluator reputations, potentially slashes stakes, and finalizes reward distribution based on the resolution outcome.
    *   **Access:** Only contract owner.
    *   **Pre-conditions:** The task must be in `Disputed` status.
11. **`cancelEvaluationTask(uint256 _taskId)`**
    *   **Purpose:** Allows the original requester to cancel an evaluation task that is still in `Pending` (unclaimed) status, refunding their `evaluationFee`.
    *   **Access:** Only the requester of the task.
    *   **Pre-conditions:** The task must be in `Pending` status.

### III. Reputation & Incentives Functions (4 functions)

12. **`updateReputationScore(address _target, int256 _change)`**
    *   **Purpose:** An administrative function to manually adjust the reputation score of a specified address. This can be used for specific penalties or bonuses outside the automated dispute resolution system.
    *   **Access:** Only contract owner.
    *   **Pre-conditions:** The target address must be an active evaluator.
13. **`claimRewards()`**
    *   **Purpose:** Allows any user (evaluator or dataset owner) to claim their accrued AIToken rewards from successful evaluations.
    *   **Access:** Anyone.
    *   **Pre-conditions:** Caller must have `claimableRewards`.
14. **`delegateReputation(address _delegatee)`**
    *   **Purpose:** Allows an active evaluator to delegate their reputation points (and thus their voting power in governance) to another address.
    *   **Access:** Only active evaluators.
    *   **Pre-conditions:** Cannot delegate to self.
15. **`slashEvaluatorStake(address _evaluator, uint256 _amount)`**
    *   **Purpose:** An administrative function to slash a portion of an evaluator's staked AIToken. This is typically used as a penalty for proven malicious activity or severe misconduct.
    *   **Access:** Only contract owner.
    *   **Pre-conditions:** The target evaluator must be active and have sufficient stake.

### IV. Query & Discovery Functions (3 functions)

16. **`getModelDetails(uint256 _modelId)`**
    *   **Purpose:** Retrieves all registered details about a specific AI model.
    *   **Access:** Anyone (view function).
    *   **Pre-conditions:** Model with `_modelId` must exist.
    *   **Returns:** `Model` struct containing comprehensive details.
17. **`getEvaluatorReputation(address _evaluator)`**
    *   **Purpose:** Returns the current reputation score of a given evaluator.
    *   **Access:** Anyone (view function).
    *   **Returns:** `reputationScore` (uint256) - The scaled reputation score of the evaluator.
18. **`getTopNModels(uint256 _n)`**
    *   **Purpose:** Returns a list of the top `N` highest-ranked AI models based on their aggregated evaluation scores.
    *   **Access:** Anyone (view function).
    *   **Note:** For very large numbers of models, this function's gas cost might be high due to on-chain sorting. In such cases, off-chain indexing would be more efficient, or a more sophisticated on-chain data structure. This implementation provides a basic illustrative sorting mechanism.
    *   **Returns:** `Model[]` (array of `Model` structs), sorted by `averageScore` in descending order.

### V. Governance & Admin Functions (2 functions)

19. **`proposeProtocolChange(string calldata _description, uint256 _newEvaluatorStakeMin, uint256 _newEvaluationFee, uint256 _newDatasetOwnerRewardShare, uint256 _newProtocolFeeShare)`**
    *   **Purpose:** Allows eligible users to propose changes to core protocol parameters (e.g., minimum evaluator stake, evaluation fee, reward distribution percentages).
    *   **Access:** Only active evaluators with a `reputationScore` above `evaluatorReputationThresholdForProposal`.
    *   **Returns:** `proposalId` (uint256) - The unique ID of the newly created proposal.
20. **`voteOnProposal(uint256 _proposalId, bool _support)`**
    *   **Purpose:** Allows users with reputation (or their delegates) to vote on active proposals. Voting power is proportional to their `reputationScore`.
    *   **Access:** Anyone with reputation (or delegated reputation).
    *   **Pre-conditions:** The proposal must be `Active` and within its voting period. Caller or their delegate must not have voted already.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary
//
// Contract Name: DeSciAI_ModelMarket
// Description: A decentralized marketplace and evaluation system for AI models.
//              Model owners can submit their AI models (referenced by IPFS hashes)
//              and request evaluations against specific datasets. Evaluators stake
//              tokens to participate, claim evaluation tasks, run models off-chain,
//              and submit cryptographic proofs/results hashes on-chain.
//              The system incorporates a reputation mechanism, dispute resolution,
//              and DAO-like governance for protocol parameter adjustments.
//
// Key Concepts:
// - Decentralized AI Model & Dataset Registry: IPFS-based referencing for off-chain assets.
// - Reputation-Backed Evaluation: Evaluators stake tokens and earn reputation for accurate work.
// - On-chain Evaluation Orchestration: Smart contract coordinates off-chain evaluation tasks.
// - ZKP/Proof Integration (Conceptual): Interface for submitting verifiable computation results.
// - Dispute Resolution: Mechanism for challenging and resolving conflicting evaluation outcomes.
// - DAO Governance: Token/reputation-weighted voting for protocol upgrades and parameters.
//
// I. Core Registry & Management Functions (5 functions)
//    1.  `registerEvaluator()`: Allows a user to stake AIToken to become a registered evaluator.
//    2.  `updateEvaluatorProfile(string calldata _metadataUri)`: Updates an evaluator's off-chain profile metadata URI.
//    3.  `submitModel(string calldata _name, string calldata _description, string calldata _ipfsHash, string calldata _metadataUri)`: Registers a new AI model with its details and IPFS hash.
//    4.  `submitDataset(string calldata _name, string calldata _description, string calldata _ipfsHash, string calldata _metadataUri)`: Registers a new dataset with its details and IPFS hash.
//    5.  `withdrawEvaluatorStake()`: Allows a registered evaluator to withdraw their staked AIToken after a cooldown period and no active tasks.
//
// II. Evaluation Lifecycle Functions (6 functions)
//    6.  `requestModelEvaluation(uint256 _modelId, uint256 _datasetId)`: Model owner requests an evaluation for their model against a specific dataset, paying an AIToken fee.
//    7.  `claimEvaluationTask(uint256 _taskId)`: A registered evaluator claims a pending evaluation task.
//    8.  `submitEvaluationResults(uint256 _taskId, bytes32 _evaluationResultsHash, bytes calldata _proofData)`: Evaluator submits the hash of off-chain evaluation results and optional proof data.
//    9.  `disputeEvaluationResults(uint256 _taskId)`: Allows a model owner or another qualified evaluator to dispute submitted evaluation results.
//    10. `resolveDispute(uint256 _taskId, bool _evaluatorWasCorrect)`: The protocol owner/committee resolves a dispute, adjusting reputations and stakes accordingly.
//    11. `cancelEvaluationTask(uint256 _taskId)`: Allows the requester to cancel a pending (unclaimed) evaluation task, refunding the fee.
//
// III. Reputation & Incentives Functions (4 functions)
//    12. `updateReputationScore(address _target, int256 _change)`: Admin function to manually adjust the reputation score of an address (e.g., for penalties or bonuses).
//    13. `claimRewards()`: Allows an evaluator or dataset owner to claim their accrued AIToken rewards.
//    14. `delegateReputation(address _delegatee)`: Allows an evaluator to delegate their voting power (based on reputation) to another address.
//    15. `slashEvaluatorStake(address _evaluator, uint256 _amount)`: Admin function to slash a portion of an evaluator's stake, typically due to proven malicious activity.
//
// IV. Query & Discovery Functions (3 functions)
//    16. `getModelDetails(uint256 _modelId)`: Retrieves comprehensive details about a specific registered AI model.
//    17. `getEvaluatorReputation(address _evaluator)`: Returns the current reputation score of a given evaluator.
//    18. `getTopNModels(uint256 _n)`: Returns a list of the top N highest-ranked models based on aggregated evaluation scores.
//
// V. Governance & Admin Functions (2 functions)
//    19. `proposeProtocolChange(string calldata _description, uint256 _newEvaluatorStakeMin, uint256 _newEvaluationFee, uint256 _newDatasetOwnerRewardShare, uint256 _newProtocolFeeShare)`: Allows eligible users to propose changes to core protocol parameters.
//    20. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with reputation to vote on active proposals.
//
// --- End of Outline and Summary ---

contract DeSciAI_ModelMarket is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---
    IERC20 public aitoken; // The ERC20 token used for staking and rewards
    address public protocolTreasury; // Address where protocol fees are collected

    // Configuration Parameters
    uint256 public minEvaluatorStake;
    uint256 public evaluationFee;
    uint256 public rewardPerEvaluation;
    uint256 public datasetOwnerRewardShare; // Percentage of fee for dataset owner (e.g., 20 for 20%)
    uint256 public protocolFeeShare;      // Percentage of fee for protocol treasury (e.g., 10 for 10%)
    uint256 public evaluatorReputationThresholdForProposal;
    uint256 public disputeWindowDuration;
    uint256 public evaluatorCooldownPeriod; // For stake withdrawal
    uint256 public proposalVotingDuration;
    uint256 public constant REPUTATION_SCALE = 100; // Multiplier for reputation calculation to allow decimals in integer math

    // IDs counters
    uint256 public nextModelId;
    uint256 public nextDatasetId;
    uint256 public nextTaskId;
    uint256 public nextProposalId;

    // --- Structs ---

    struct Model {
        address owner;
        string name;
        string description;
        string ipfsHash; // IPFS hash of model weights/code
        string metadataUri; // URI for more detailed off-chain metadata (e.g., performance reports, licenses)
        uint256 submittedTimestamp;
        uint256 totalEvaluations;
        uint256 averageScore; // Aggregated score from evaluations (scaled by REPUTATION_SCALE)
        bool isActive;
    }

    struct Dataset {
        address owner;
        string name;
        string description;
        string ipfsHash; // IPFS hash of the dataset
        string metadataUri; // URI for more detailed off-chain metadata
        uint256 submittedTimestamp;
        bool isActive;
    }

    struct EvaluatorProfile {
        uint256 stake; // AIToken amount staked
        uint256 reputationScore; // Scaled by REPUTATION_SCALE
        uint256 activeTasksCount;
        uint256 lastStakeUpdate; // Timestamp for cooldown purposes
        string metadataUri; // URI for evaluator's off-chain profile/environment
        address delegatedTo; // Address to which reputation/voting power is delegated
        bool isActive;
    }

    enum EvaluationStatus {
        Pending,     // Requested but not claimed
        Claimed,     // Claimed by an evaluator
        Submitted,   // Results submitted by evaluator
        Disputed,    // Results disputed
        Resolved,    // Dispute resolved
        Completed,   // Evaluation finished and settled
        Cancelled    // Task cancelled
    }

    struct EvaluationTask {
        uint256 modelId;
        uint256 datasetId;
        address requester;
        address evaluator; // Address of the evaluator who claimed the task
        uint256 requestTimestamp;
        uint256 submissionTimestamp; // Timestamp when results were submitted
        bytes32 evaluationResultsHash; // Hash of the evaluation results (or a ZKP output hash)
        bytes proofData; // Optional: raw ZKP proof data or attestation signature (for off-chain verification)
        EvaluationStatus status;
        uint256 rewardAmount; // Reward locked for this task (initially holds the full fee)
        uint256 disputeDeadline; // Deadline for dispute submission
        bool disputeResolvedByEvaluatorCorrect; // True if evaluator was correct, false if disproved
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 creationTimestamp;
        uint256 endTimestamp;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Voter tracking
        ProposalStatus status;
        // Parameters that can be changed
        uint256 newMinEvaluatorStake;
        uint256 newEvaluationFee;
        uint256 newDatasetOwnerRewardShare;
        uint256 newProtocolFeeShare;
    }

    // --- Mappings ---
    mapping(uint256 => Model) public models;
    mapping(uint256 => Dataset) public datasets;
    mapping(address => EvaluatorProfile) public evaluatorProfiles;
    mapping(uint256 => EvaluationTask) public evaluationTasks;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public claimableRewards; // Rewards claimable by evaluators and dataset owners

    // A list of model IDs for `getTopNModels`.
    // For a realistic implementation with many models, off-chain indexing or a more complex
    // on-chain data structure (e.g., a merkelized heap) would be necessary to efficiently
    // retrieve top N models without exceeding gas limits. This implementation provides
    // a basic, illustrative sorting mechanism that may not scale.
    uint256[] public allModelIds;

    // --- Events ---
    event EvaluatorRegistered(address indexed evaluator, uint256 stake);
    event EvaluatorProfileUpdated(address indexed evaluator, string metadataUri);
    event EvaluatorStakeWithdrawn(address indexed evaluator, uint256 amount);
    event ModelSubmitted(uint256 indexed modelId, address indexed owner, string name, string ipfsHash);
    event DatasetSubmitted(uint256 indexed datasetId, address indexed owner, string name, string ipfsHash);
    event EvaluationRequested(uint256 indexed taskId, uint256 indexed modelId, uint256 indexed datasetId, address requester, uint256 fee);
    event EvaluationClaimed(uint256 indexed taskId, address indexed evaluator);
    event EvaluationResultsSubmitted(uint256 indexed taskId, address indexed evaluator, bytes32 resultsHash);
    event EvaluationDisputed(uint256 indexed taskId, address indexed disputer);
    event EvaluationDisputeResolved(uint256 indexed taskId, address indexed resolver, bool evaluatorWasCorrect);
    event EvaluationCancelled(uint256 indexed taskId, address indexed requester);
    event ReputationUpdated(address indexed target, int256 change, uint256 newScore); // Change can be negative
    event RewardsClaimed(address indexed receiver, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event EvaluatorStakeSlashed(address indexed evaluator, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyEvaluator() {
        require(evaluatorProfiles[msg.sender].isActive, "Caller is not a registered evaluator.");
        _;
    }

    modifier notRegisteredEvaluator() {
        require(!evaluatorProfiles[msg.sender].isActive, "Caller is already a registered evaluator.");
        _;
    }

    modifier onlyModelOwner(uint256 _modelId) {
        require(models[_modelId].owner == msg.sender, "Only model owner can perform this action.");
        _;
    }

    modifier onlyRequester(uint256 _taskId) {
        require(evaluationTasks[_taskId].requester == msg.sender, "Only task requester can perform this action.");
        _;
    }

    modifier onlyEvaluatorOfTask(uint256 _taskId) {
        require(evaluationTasks[_taskId].evaluator == msg.sender, "Only assigned evaluator can perform this action.");
        _;
    }

    // --- Constructor ---
    constructor(
        address _aitokenAddress,
        address _protocolTreasury,
        uint256 _minEvaluatorStake,
        uint256 _evaluationFee,
        uint256 _rewardPerEvaluation,
        uint256 _datasetOwnerRewardShare,
        uint256 _protocolFeeShare,
        uint256 _evaluatorReputationThresholdForProposal,
        uint256 _disputeWindowDuration,
        uint256 _evaluatorCooldownPeriod,
        uint256 _proposalVotingDuration
    ) Ownable(msg.sender) {
        require(_aitokenAddress != address(0), "AIToken address cannot be zero.");
        require(_protocolTreasury != address(0), "Protocol treasury address cannot be zero.");
        require(_minEvaluatorStake > 0, "Min evaluator stake must be greater than zero.");
        require(_evaluationFee > 0, "Evaluation fee must be greater than zero.");
        require(_rewardPerEvaluation < _evaluationFee, "Reward per evaluation should be less than the fee.");
        require(_datasetOwnerRewardShare + _protocolFeeShare <= 100, "Total shares exceed 100%");

        aitoken = IERC20(_aitokenAddress);
        protocolTreasury = _protocolTreasury;

        minEvaluatorStake = _minEvaluatorStake;
        evaluationFee = _evaluationFee;
        rewardPerEvaluation = _rewardPerEvaluation;
        datasetOwnerRewardShare = _datasetOwnerRewardShare;
        protocolFeeShare = _protocolFeeShare;
        evaluatorReputationThresholdForProposal = _evaluatorReputationThresholdForProposal;
        disputeWindowDuration = _disputeWindowDuration;
        evaluatorCooldownPeriod = _evaluatorCooldownPeriod;
        proposalVotingDuration = _proposalVotingDuration;

        nextModelId = 1;
        nextDatasetId = 1;
        nextTaskId = 1;
        nextProposalId = 1;
    }

    // --- I. Core Registry & Management Functions ---

    /**
     * @notice Allows a user to stake AIToken to become a registered evaluator.
     * @dev Requires caller to approve `minEvaluatorStake` AIToken to this contract beforehand.
     */
    function registerEvaluator() external nonReentrant notRegisteredEvaluator {
        require(aitoken.transferFrom(msg.sender, address(this), minEvaluatorStake), "Token transfer failed.");
        
        evaluatorProfiles[msg.sender] = EvaluatorProfile({
            stake: minEvaluatorStake,
            reputationScore: 0, // Start with 0 reputation
            activeTasksCount: 0,
            lastStakeUpdate: block.timestamp,
            metadataUri: "",
            delegatedTo: address(0),
            isActive: true
        });
        emit EvaluatorRegistered(msg.sender, minEvaluatorStake);
    }

    /**
     * @notice Allows an evaluator to update their off-chain profile metadata URI.
     * @param _metadataUri A URI pointing to off-chain metadata (e.g., evaluator's credentials, preferred environment).
     */
    function updateEvaluatorProfile(string calldata _metadataUri) external onlyEvaluator {
        evaluatorProfiles[msg.sender].metadataUri = _metadataUri;
        emit EvaluatorProfileUpdated(msg.sender, _metadataUri);
    }

    /**
     * @notice Registers a new AI model with its details and IPFS hash.
     * @param _name The name of the AI model.
     * @param _description A brief description of the model.
     * @param _ipfsHash The IPFS hash pointing to the model's weights/code.
     * @param _metadataUri A URI for more detailed off-chain metadata about the model.
     * @return modelId The unique ID of the newly registered model.
     */
    function submitModel(
        string calldata _name,
        string calldata _description,
        string calldata _ipfsHash,
        string calldata _metadataUri
    ) external returns (uint256 modelId) {
        modelId = nextModelId++;
        models[modelId] = Model({
            owner: msg.sender,
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            metadataUri: _metadataUri,
            submittedTimestamp: block.timestamp,
            totalEvaluations: 0,
            averageScore: 0,
            isActive: true
        });
        allModelIds.push(modelId); // For getTopNModels
        emit ModelSubmitted(modelId, msg.sender, _name, _ipfsHash);
    }

    /**
     * @notice Registers a new dataset with its details and IPFS hash.
     * @param _name The name of the dataset.
     * @param _description A brief description of the dataset.
     * @param _ipfsHash The IPFS hash pointing to the dataset's content.
     * @param _metadataUri A URI for more detailed off-chain metadata about the dataset.
     * @return datasetId The unique ID of the newly registered dataset.
     */
    function submitDataset(
        string calldata _name,
        string calldata _description,
        string calldata _ipfsHash,
        string calldata _metadataUri
    ) external returns (uint256 datasetId) {
        datasetId = nextDatasetId++;
        datasets[datasetId] = Dataset({
            owner: msg.sender,
            name: _name,
            description: _description,
            ipfsHash: _ipfsHash,
            metadataUri: _metadataUri,
            submittedTimestamp: block.timestamp,
            isActive: true
        });
        emit DatasetSubmitted(datasetId, msg.sender, _name, _ipfsHash);
    }

    /**
     * @notice Allows a registered evaluator to withdraw their staked AIToken.
     * @dev Requires no active tasks and a cooldown period to have passed since last stake update.
     */
    function withdrawEvaluatorStake() external nonReentrant onlyEvaluator {
        EvaluatorProfile storage profile = evaluatorProfiles[msg.sender];
        require(profile.activeTasksCount == 0, "Cannot withdraw stake with active tasks.");
        require(block.timestamp >= profile.lastStakeUpdate.add(evaluatorCooldownPeriod), "Stake withdrawal is in cooldown.");
        require(profile.stake > 0, "No stake to withdraw.");

        uint256 amountToWithdraw = profile.stake;
        profile.stake = 0;
        profile.isActive = false; // Deactivate evaluator profile
        profile.reputationScore = 0; // Reset reputation
        profile.delegatedTo = address(0); // Clear delegation

        require(aitoken.transfer(msg.sender, amountToWithdraw), "Token transfer failed.");
        emit EvaluatorStakeWithdrawn(msg.sender, amountToWithdraw);
    }

    // --- II. Evaluation Lifecycle Functions ---

    /**
     * @notice Model owner requests an evaluation for their model against a specific dataset.
     * @param _modelId The ID of the model to be evaluated.
     * @param _datasetId The ID of the dataset to evaluate against.
     * @return taskId The unique ID of the created evaluation task.
     */
    function requestModelEvaluation(uint256 _modelId, uint256 _datasetId) external nonReentrant returns (uint256 taskId) {
        require(models[_modelId].isActive, "Model not active or does not exist.");
        require(datasets[_datasetId].isActive, "Dataset not active or does not exist.");
        require(aitoken.transferFrom(msg.sender, address(this), evaluationFee), "Fee payment failed. Ensure sufficient allowance.");

        taskId = nextTaskId++;
        evaluationTasks[taskId] = EvaluationTask({
            modelId: _modelId,
            datasetId: _datasetId,
            requester: msg.sender,
            evaluator: address(0), // Not yet claimed
            requestTimestamp: block.timestamp,
            submissionTimestamp: 0,
            evaluationResultsHash: bytes32(0),
            proofData: "",
            status: EvaluationStatus.Pending,
            rewardAmount: evaluationFee, // Temporarily hold the full fee
            disputeDeadline: 0,
            disputeResolvedByEvaluatorCorrect: false
        });
        emit EvaluationRequested(taskId, _modelId, _datasetId, msg.sender, evaluationFee);
    }

    /**
     * @notice A registered evaluator claims a pending evaluation task.
     * @param _taskId The ID of the evaluation task to claim.
     */
    function claimEvaluationTask(uint256 _taskId) external nonReentrant onlyEvaluator {
        EvaluationTask storage task = evaluationTasks[_taskId];
        require(task.status == EvaluationStatus.Pending, "Task is not pending or does not exist.");
        require(evaluatorProfiles[msg.sender].activeTasksCount < 5, "Evaluator has too many active tasks (max 5)."); // Limit active tasks

        task.evaluator = msg.sender;
        task.status = EvaluationStatus.Claimed;
        evaluatorProfiles[msg.sender].activeTasksCount++;
        emit EvaluationClaimed(_taskId, msg.sender);
    }

    /**
     * @notice Evaluator submits the hash of off-chain evaluation results and optional proof data.
     * @dev The `_proofData` can be a ZKP, signed attestation, or other verifiable data. Its verification is off-chain.
     * @param _taskId The ID of the completed evaluation task.
     * @param _evaluationResultsHash A cryptographic hash of the evaluation results.
     * @param _proofData Optional raw proof data for off-chain verification.
     */
    function submitEvaluationResults(
        uint256 _taskId,
        bytes32 _evaluationResultsHash,
        bytes calldata _proofData
    ) external nonReentrant onlyEvaluatorOfTask(_taskId) {
        EvaluationTask storage task = evaluationTasks[_taskId];
        require(task.status == EvaluationStatus.Claimed, "Task is not in 'Claimed' status.");
        require(_evaluationResultsHash != bytes32(0), "Results hash cannot be zero.");

        task.evaluationResultsHash = _evaluationResultsHash;
        task.proofData = _proofData;
        task.submissionTimestamp = block.timestamp;
        task.status = EvaluationStatus.Submitted;
        task.disputeDeadline = block.timestamp.add(disputeWindowDuration);
        emit EvaluationResultsSubmitted(_taskId, msg.sender, _evaluationResultsHash);
    }

    /**
     * @notice Allows a model owner or another qualified evaluator to dispute submitted evaluation results.
     * @dev A model owner can dispute their own model's evaluation. Another evaluator must have minimum reputation.
     *      For simplicity, a 'qualified evaluator' is defined as having a stake >= `minEvaluatorStake`.
     * @param _taskId The ID of the task to dispute.
     */
    function disputeEvaluationResults(uint256 _taskId) external nonReentrant {
        EvaluationTask storage task = evaluationTasks[_taskId];
        require(task.status == EvaluationStatus.Submitted, "Task is not in 'Submitted' status.");
        require(block.timestamp <= task.disputeDeadline, "Dispute window has closed.");

        bool isModelOwner = (models[task.modelId].owner == msg.sender);
        bool isQualifiedEvaluator = (evaluatorProfiles[msg.sender].isActive && evaluatorProfiles[msg.sender].stake >= minEvaluatorStake); // Example criteria

        require(isModelOwner || isQualifiedEvaluator, "Only model owner or a qualified evaluator can dispute.");
        require(task.evaluator != msg.sender, "Evaluator cannot dispute their own submission.");
        
        task.status = EvaluationStatus.Disputed;
        emit EvaluationDisputed(_taskId, msg.sender);
    }

    /**
     * @notice The protocol owner/committee resolves a dispute, adjusting reputations and stakes accordingly.
     * @dev This function is intended to be called by a trusted entity (e.g., the contract owner or a DAO committee).
     * @param _taskId The ID of the task where a dispute needs resolution.
     * @param _evaluatorWasCorrect True if the original evaluator's submission was deemed correct, false otherwise.
     */
    function resolveDispute(uint256 _taskId, bool _evaluatorWasCorrect) external onlyOwner nonReentrant {
        EvaluationTask storage task = evaluationTasks[_taskId];
        require(task.status == EvaluationStatus.Disputed, "Task is not in 'Disputed' status.");
        
        task.disputeResolvedByEvaluatorCorrect = _evaluatorWasCorrect;
        task.resolutionTimestamp = block.timestamp;

        address evaluator = task.evaluator;
        address requester = task.requester;
        address datasetOwner = datasets[task.datasetId].owner;
        
        evaluatorProfiles[evaluator].activeTasksCount--;

        if (_evaluatorWasCorrect) {
            // Evaluator was correct: Reward evaluator, increase reputation
            _distributeRewards(task.rewardAmount, evaluator, datasetOwner);
            _updateReputationScore(evaluator, 10 * REPUTATION_SCALE); // Increase reputation
        } else {
            // Evaluator was incorrect: Refund requester, slash evaluator's stake, decrease reputation
            claimableRewards[requester] = claimableRewards[requester].add(task.rewardAmount); // Refund requester's fee
            _updateReputationScore(evaluator, -20 * REPUTATION_SCALE); // Decrease reputation more significantly
            // Slash 10% of stake for incorrect evaluation
            uint256 slashAmount = evaluatorProfiles[evaluator].stake.div(10); 
            if (slashAmount > 0) _slashEvaluatorStake(evaluator, slashAmount); 
        }
        
        _finalizeModelEvaluation(_taskId, _evaluatorWasCorrect);

        emit EvaluationDisputeResolved(_taskId, msg.sender, _evaluatorWasCorrect);
    }

    /**
     * @notice Allows the requester to cancel a pending (unclaimed) evaluation task, refunding the fee.
     * @param _taskId The ID of the evaluation task to cancel.
     */
    function cancelEvaluationTask(uint256 _taskId) external nonReentrant onlyRequester(_taskId) {
        EvaluationTask storage task = evaluationTasks[_taskId];
        require(task.status == EvaluationStatus.Pending, "Task is not pending and cannot be cancelled.");

        task.status = EvaluationStatus.Cancelled;
        // Refund the fee to the requester
        claimableRewards[msg.sender] = claimableRewards[msg.sender].add(task.rewardAmount);
        emit EvaluationCancelled(_taskId, msg.sender);
    }

    // --- III. Reputation & Incentives Functions ---

    /**
     * @notice Admin function to manually adjust the reputation score of an address.
     * @dev Can be used for penalties or bonuses outside of the automated system in specific edge cases.
     * @param _target The address whose reputation score is to be adjusted.
     * @param _change The amount to change the reputation score by (can be negative).
     */
    function updateReputationScore(address _target, int256 _change) external onlyOwner {
        require(evaluatorProfiles[_target].isActive, "Target is not an active evaluator.");
        _updateReputationScore(_target, _change);
        emit ReputationUpdated(_target, _change, evaluatorProfiles[_target].reputationScore);
    }

    /**
     * @notice Allows an evaluator or dataset owner to claim their accrued AIToken rewards.
     */
    function claimRewards() external nonReentrant {
        uint256 amount = claimableRewards[msg.sender];
        require(amount > 0, "No rewards to claim.");

        claimableRewards[msg.sender] = 0;
        require(aitoken.transfer(msg.sender, amount), "Reward transfer failed.");
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @notice Allows an evaluator to delegate their voting power (based on reputation) to another address.
     * @param _delegatee The address to which reputation/voting power is delegated.
     */
    function delegateReputation(address _delegatee) external onlyEvaluator {
        require(_delegatee != msg.sender, "Cannot delegate reputation to self.");
        evaluatorProfiles[msg.sender].delegatedTo = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Admin function to slash a portion of an evaluator's stake.
     * @dev Typically used due to proven malicious activity or repeated poor performance.
     * @param _evaluator The address of the evaluator whose stake will be slashed.
     * @param _amount The amount of AIToken to slash from their stake.
     */
    function slashEvaluatorStake(address _evaluator, uint256 _amount) external onlyOwner nonReentrant {
        _slashEvaluatorStake(_evaluator, _amount);
        // Event already emitted by internal helper
    }

    // --- IV. Query & Discovery Functions ---

    /**
     * @notice Retrieves comprehensive details about a specific registered AI model.
     * @param _modelId The ID of the model to query.
     * @return model The Model struct containing all its details.
     */
    function getModelDetails(uint256 _modelId) external view returns (Model memory) {
        require(models[_modelId].owner != address(0), "Model does not exist.");
        return models[_modelId];
    }

    /**
     * @notice Returns the current reputation score of a given evaluator.
     * @param _evaluator The address of the evaluator.
     * @return reputationScore The reputation score (scaled by REPUTATION_SCALE).
     */
    function getEvaluatorReputation(address _evaluator) external view returns (uint256 reputationScore) {
        return evaluatorProfiles[_evaluator].reputationScore;
    }

    /**
     * @notice Returns a list of the top N highest-ranked models based on aggregated evaluation scores.
     * @dev This function iterates through `allModelIds` and sorts them by `averageScore`.
     *      For large numbers of models, off-chain indexing or a more advanced on-chain
     *      data structure (e.g., a skip list or merkelized heap, which are gas-intensive) would be needed.
     *      This implementation assumes `allModelIds` is manageable in terms of gas for iteration.
     * @param _n The number of top models to return.
     * @return topModels An array of Model structs, sorted by average score descending.
     */
    function getTopNModels(uint256 _n) external view returns (Model[] memory topModels) {
        uint256 totalModels = allModelIds.length;
        if (totalModels == 0) {
            return new Model[](0);
        }

        // Copy active models to a temporary array for sorting
        // Filter out inactive models
        Model[] memory activeTempModels = new Model[](totalModels); // Max possible size
        uint256 activeCount = 0;
        for (uint256 i = 0; i < totalModels; i++) {
            if (models[allModelIds[i]].isActive) {
                activeTempModels[activeCount] = models[allModelIds[i]];
                activeCount++;
            }
        }

        // Adjust temporary array size to actual active count
        Model[] memory sortedModels = new Model[](activeCount);
        for(uint256 i = 0; i < activeCount; i++) {
            sortedModels[i] = activeTempModels[i];
        }

        // Simple bubble sort for demonstration. Not efficient for large N, but illustrative.
        // For production, this should ideally be handled by an off-chain indexer or a more complex on-chain structure.
        for (uint256 i = 0; i < activeCount; i++) {
            for (uint256 j = i + 1; j < activeCount; j++) {
                if (sortedModels[i].averageScore < sortedModels[j].averageScore) {
                    Model memory temp = sortedModels[i];
                    sortedModels[i] = sortedModels[j];
                    sortedModels[j] = temp;
                }
            }
        }

        // Return top N
        uint256 numToReturn = _n > activeCount ? activeCount : _n;
        topModels = new Model[](numToReturn);
        for (uint256 i = 0; i < numToReturn; i++) {
            topModels[i] = sortedModels[i];
        }
        return topModels;
    }

    // --- V. Governance & Admin Functions ---

    /**
     * @notice Allows eligible users to propose changes to core protocol parameters.
     * @dev Requires the proposer to be an active evaluator with a reputation score above a threshold.
     * @param _description A description of the proposed change.
     * @param _newEvaluatorStakeMin The proposed new minimum stake for evaluators.
     * @param _newEvaluationFee The proposed new fee for model evaluations.
     * @param _newDatasetOwnerRewardShare The proposed new percentage for dataset owner's reward.
     * @param _newProtocolFeeShare The proposed new percentage for the protocol treasury.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeProtocolChange(
        string calldata _description,
        uint256 _newEvaluatorStakeMin,
        uint256 _newEvaluationFee,
        uint256 _newDatasetOwnerRewardShare,
        uint256 _newProtocolFeeShare
    ) external returns (uint256 proposalId) {
        EvaluatorProfile storage proposerProfile = evaluatorProfiles[msg.sender];
        require(proposerProfile.isActive, "Proposer is not an active evaluator.");
        require(proposerProfile.reputationScore >= evaluatorReputationThresholdForProposal, "Not enough reputation to propose.");
        require(_newDatasetOwnerRewardShare + _newProtocolFeeShare <= 100, "Total shares exceed 100%");

        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(proposalVotingDuration),
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Active,
            newMinEvaluatorStake: _newEvaluatorStakeMin,
            newEvaluationFee: _newEvaluationFee,
            newDatasetOwnerRewardShare: _newDatasetOwnerRewardShare,
            newProtocolFeeShare: _newProtocolFeeShare
        });
        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @notice Allows users with reputation to vote on active proposals.
     * @dev Voting power is based on the caller's (or their delegatee's) current reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'Yes' vote, false for a 'No' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        require(block.timestamp <= proposal.endTimestamp, "Voting period has ended.");

        // Determine effective voter (caller or their delegate)
        address effectiveVoter = msg.sender;
        if (evaluatorProfiles[msg.sender].delegatedTo != address(0)) {
            effectiveVoter = evaluatorProfiles[msg.sender].delegatedTo;
        }
        
        require(!proposal.hasVoted[effectiveVoter], "Already voted on this proposal.");

        uint256 votingPower = evaluatorProfiles[effectiveVoter].reputationScore;
        require(votingPower > 0, "Caller or delegatee has no reputation to vote.");

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }
        proposal.hasVoted[effectiveVoter] = true;
        emit Voted(_proposalId, msg.sender, _support);

        // Optional: Automatically execute if voting period ends and passes threshold
        // This check would normally be done in a separate `executeProposal` function
        // to save gas on voting, but for demonstration, it's inline.
        // A more robust system would require a minimum number of votes or a quorum.
        if (block.timestamp > proposal.endTimestamp) {
            _executeProposal(_proposalId);
        }
    }
    
    // --- Internal/Private Helper Functions ---

    /**
     * @dev Internal function to update a model's average score and total evaluations.
     * @param _taskId The ID of the evaluation task.
     * @param _evaluatorWasCorrect Flag indicating if the evaluator's submission was correct.
     */
    function _finalizeModelEvaluation(uint256 _taskId, bool _evaluatorWasCorrect) internal {
        EvaluationTask storage task = evaluationTasks[_taskId];
        Model storage model = models[task.modelId];
        
        // Only update model score if the evaluator was correct (implies a valid evaluation)
        if (_evaluatorWasCorrect) {
            // Simple model scoring: Add evaluator's reputation to model's total score
            // For a more robust system, evaluation results would include an actual performance score.
            // For now, we use evaluator's reputation as a proxy for the quality of evaluation/model.
            uint256 evaluatorRep = evaluatorProfiles[task.evaluator].reputationScore;
            
            // Calculate new average score
            // new_avg = (old_avg * old_total + new_score) / (old_total + 1)
            model.averageScore = (model.averageScore.mul(model.totalEvaluations).add(evaluatorRep)).div(model.totalEvaluations.add(1));
            model.totalEvaluations++;
        }
        task.status = EvaluationStatus.Completed; // Mark as completed after dispute resolution or simple submission
    }

    /**
     * @dev Internal function to distribute rewards among evaluator, dataset owner, and treasury.
     * @param _totalAmount The total amount of AIToken to distribute from the task.
     * @param _evaluator The address of the evaluator.
     * @param _datasetOwner The address of the dataset owner.
     */
    function _distributeRewards(uint256 _totalAmount, address _evaluator, address _datasetOwner) internal {
        uint256 evaluatorReward = rewardPerEvaluation;
        uint256 datasetReward = _totalAmount.mul(datasetOwnerRewardShare).div(100);
        uint256 treasuryShare = _totalAmount.mul(protocolFeeShare).div(100);

        // Ensure we don't over-distribute
        require(evaluatorReward.add(datasetReward).add(treasuryShare) <= _totalAmount, "Reward distribution error.");

        // Add to claimable rewards
        claimableRewards[_evaluator] = claimableRewards[_evaluator].add(evaluatorReward);
        claimableRewards[_datasetOwner] = claimableRewards[_datasetOwner].add(datasetReward);
        
        // Transfer treasury share directly
        if (treasuryShare > 0) {
            require(aitoken.transfer(protocolTreasury, treasuryShare), "Treasury share transfer failed.");
        }

        // Any remaining amount from _totalAmount - (evaluatorReward + datasetReward + treasuryShare)
        // could be burned or also sent to treasury. For simplicity, remaining goes to treasury.
        uint256 remaining = _totalAmount.sub(evaluatorReward).sub(datasetReward).sub(treasuryShare);
        if (remaining > 0) {
            require(aitoken.transfer(protocolTreasury, remaining), "Remaining fee transfer failed.");
        }
    }

    /**
     * @dev Internal function to adjust reputation score. Used by other functions.
     * @param _target The address whose reputation is being updated.
     * @param _change The amount to change reputation by (can be negative).
     */
    function _updateReputationScore(address _target, int256 _change) internal {
        EvaluatorProfile storage profile = evaluatorProfiles[_target];
        if (!profile.isActive) return; // Only active evaluators can have reputation

        uint256 currentScore = profile.reputationScore;
        if (_change > 0) {
            profile.reputationScore = currentScore.add(uint256(_change));
        } else if (_change < 0) {
            uint256 absChange = uint256(-_change);
            if (currentScore < absChange) {
                profile.reputationScore = 0; // Cannot go below zero
            } else {
                profile.reputationScore = currentScore.sub(absChange);
            }
        }
    }

    /**
     * @dev Internal helper to slash evaluator stake. Called by `resolveDispute` or `slashEvaluatorStake`.
     * @param _evaluator The evaluator's address.
     * @param _amount The amount to slash.
     */
    function _slashEvaluatorStake(address _evaluator, uint256 _amount) internal {
        EvaluatorProfile storage profile = evaluatorProfiles[_evaluator];
        require(profile.isActive, "Evaluator is not active.");
        require(profile.stake >= _amount, "Slash amount exceeds evaluator's stake.");

        profile.stake = profile.stake.sub(_amount);
        require(aitoken.transfer(protocolTreasury, _amount), "Slashed stake transfer failed."); // Transfer to treasury or burn
        
        if (profile.stake < minEvaluatorStake) {
            profile.isActive = false;
            profile.reputationScore = 0; // Reset reputation if deactivated
            profile.delegatedTo = address(0); // Clear delegation
        }
        emit EvaluatorStakeSlashed(_evaluator, _amount);
    }

    /**
     * @dev Internal function to execute a proposal if it has succeeded.
     *      This would typically be a separate, callable function with additional checks for a production DAO.
     * @param _proposalId The ID of the proposal to execute.
     */
    function _executeProposal(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active.");
        require(block.timestamp > proposal.endTimestamp, "Voting period not ended yet.");
        
        // Simple majority for success
        if (proposal.yesVotes > proposal.noVotes) {
            // Proposal succeeded, apply changes
            minEvaluatorStake = proposal.newMinEvaluatorStake;
            evaluationFee = proposal.newEvaluationFee;
            datasetOwnerRewardShare = proposal.newDatasetOwnerRewardShare;
            protocolFeeShare = proposal.newProtocolFeeShare;
            proposal.status = ProposalStatus.Executed;
        } else {
            proposal.status = ProposalStatus.Defeated;
        }
        emit ProposalExecuted(_proposalId);
    }
}
```