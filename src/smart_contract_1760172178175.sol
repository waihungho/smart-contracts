This smart contract, "DeScipher Protocol," proposes a decentralized platform for AI model validation and data attribution. It addresses the challenges of trust, transparency, and fair compensation in the AI/ML ecosystem by allowing data owners to register data manifests, model developers to propose models for validation against these manifests, and validators to review models. A reputation system and dispute resolution mechanism ensure accountability and quality.

The contract is designed with advanced concepts like multi-party staking, dynamic reputation, on-chain coordination for off-chain processes, and a multi-stage dispute resolution system. It aims to be unique by integrating these specific components into a cohesive system focused on scientific/AI model integrity, rather than simply asset trading or basic governance.

---

## DeScipher Protocol: Outline and Function Summary

**Project Name:** DeScipher Protocol
**Description:** A decentralized platform for AI/ML model validation, data attribution, and reputation management.

### I. Core Infrastructure & Administration

1.  **`constructor(address _tokenAddress, address _initialOwner)`**: Initializes the contract with the ERC-20 token address used for stakes/rewards and sets the initial owner.
2.  **`pause()`**: Allows the owner to pause all critical operations of the contract, useful during upgrades or emergencies.
3.  **`unpause()`**: Allows the owner to resume operations after a pause.
4.  **`setProtocolFees(uint256 _dataStewardFeeBps, uint256 _developerFeeBps, uint256 _validatorRewardBps)`**: Sets the percentage (in basis points) of rewards distributed to Data Stewards, Model Developers, and Validators upon successful task completion.
5.  **`withdrawProtocolFees(address _recipient)`**: Allows the owner to withdraw accumulated protocol fees to a specified address.

### II. Data Steward Management

6.  **`registerDataManifest(string memory _metadataURI, bytes32 _dataHash, bytes32 _termsHash, uint256 _stakeAmount)`**: Allows a Data Steward to register a new data manifest, including metadata (e.g., IPFS link), a cryptographic hash of the data, terms hash, and an initial stake.
7.  **`updateDataManifestMetadata(uint256 _manifestId, string memory _newMetadataURI)`**: Allows a Data Steward to update the metadata URI of their registered data manifest.
8.  **`revokeDataManifest(uint256 _manifestId)`**: Allows a Data Steward to revoke an inactive data manifest and retrieve their stake.
9.  **`approveDataForTask(uint256 _manifestId, uint256 _taskId)`**: Explicitly approves the use of a data manifest for a specific model validation task.
10. **`claimDataUsageRewards(uint256 _manifestId)`**: Allows a Data Steward to claim rewards accrued from the successful usage of their data manifest in completed tasks.

### III. Model Developer Management

11. **`proposeModelValidationTask(string memory _modelMetadataURI, bytes32 _modelHash, uint256[] memory _dataManifestIDs, uint256 _developerStake)`**: Allows a Model Developer to propose a new model validation task, specifying model details, selected data manifests, and staking a required amount.
12. **`cancelProposedTask(uint256 _taskId)`**: Allows a Model Developer to cancel their proposed task if it hasn't entered the validation phase, retrieving their stake.
13. **`claimModelDeveloperRewards(uint256 _taskId)`**: Allows a Model Developer to claim rewards for a model validation task that was successfully completed and deemed valid.
14. **`updateTaskModelMetadata(uint256 _taskId, string memory _newMetadataURI)`**: Allows a Model Developer to update the model metadata URI for their proposed task.

### IV. Validator Management

15. **`registerValidator(string memory _profileURI, uint256 _stakeAmount)`**: Allows an individual to register as a Validator, providing a profile URI and staking an initial amount.
16. **`updateValidatorProfile(string memory _newProfileURI)`**: Allows a Validator to update their profile URI.
17. **`deregisterValidator()`**: Allows a Validator to deregister from the system and retrieve their stake, provided they have no active tasks or disputes.
18. **`claimValidationTask(uint256 _taskId)`**: Allows a registered Validator to claim an available model validation task for review.
19. **`submitValidationResult(uint256 _taskId, string memory _metricsURI, bytes32 _reviewHash, bool _isModelValid)`**: Allows a Validator to submit their validation results for a claimed task, including metrics URI, review hash, and their verdict (valid/invalid).

### V. Dispute Resolution & Reputation

20. **`raiseDispute(uint256 _taskId, address _challengedParty, string memory _reasonURI)`**: Allows any stakeholder to raise a dispute regarding a task's outcome, specifying the challenged party and a reason URI.
21. **`assignArbitrators(uint256 _disputeId, address[] memory _arbitratorAddresses)`**: Allows the owner or a designated governance role to assign specific addresses as arbitrators for an ongoing dispute.
22. **`submitArbitratorVerdict(uint256 _disputeId, bool _isChallengerVictorious)`**: Allows an assigned Arbitrator to submit their verdict for a dispute.
23. **`finalizeDispute(uint256 _disputeId)`**: Allows the owner or a designated governance role to finalize a dispute based on arbitrator verdicts, executing the outcome and adjusting stakes/reputations.
24. **`getReputationScore(address _account)`**: A view function to retrieve the current reputation score of any account.
25. **`claimValidationRewards(uint256 _taskId)`**: Allows a Validator to claim their rewards for tasks where their validation result contributed to the consensus and was deemed correct.

### VI. View Functions (for Data Retrieval)

26. **`getDataManifest(uint256 _manifestId)`**: Retrieves all details of a specific data manifest.
27. **`getModelValidationTask(uint256 _taskId)`**: Retrieves all details of a specific model validation task.
28. **`getValidator(address _validatorAddress)`**: Retrieves the profile details of a specific validator.
29. **`getDispute(uint256 _disputeId)`**: Retrieves all details of a specific dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title DeScipher Protocol
 * @dev A decentralized platform for AI/ML model validation, data attribution, and reputation management.
 *      It enables Data Stewards to register data manifests, Model Developers to propose models for validation
 *      against these manifests, and Validators to review models. A reputation system and dispute resolution
 *      mechanism ensure accountability and quality in the AI/ML ecosystem.
 *
 * Outline and Function Summary:
 *
 * I. Core Infrastructure & Administration
 * 1. constructor(address _tokenAddress, address _initialOwner): Initializes the contract.
 * 2. pause(): Pauses critical contract operations.
 * 3. unpause(): Resumes contract operations.
 * 4. setProtocolFees(uint256 _dataStewardFeeBps, uint256 _developerFeeBps, uint256 _validatorRewardBps): Sets reward/fee percentages.
 * 5. withdrawProtocolFees(address _recipient): Allows owner to withdraw accumulated protocol fees.
 *
 * II. Data Steward Management
 * 6. registerDataManifest(string memory _metadataURI, bytes32 _dataHash, bytes32 _termsHash, uint256 _stakeAmount): Registers a new data manifest.
 * 7. updateDataManifestMetadata(uint256 _manifestId, string memory _newMetadataURI): Updates metadata for an owned manifest.
 * 8. revokeDataManifest(uint256 _manifestId): Allows steward to revoke an unused/unapproved manifest, retrieving stake.
 * 9. approveDataForTask(uint256 _manifestId, uint256 _taskId): Explicitly approves data manifest for a specific task.
 * 10. claimDataUsageRewards(uint256 _manifestId): Claims rewards for data usage in completed tasks.
 *
 * III. Model Developer Management
 * 11. proposeModelValidationTask(string memory _modelMetadataURI, bytes32 _modelHash, uint256[] memory _dataManifestIDs, uint256 _developerStake): Proposes a model for validation.
 * 12. cancelProposedTask(uint256 _taskId): Developer cancels a task before validation starts.
 * 13. claimModelDeveloperRewards(uint256 _taskId): Claims rewards for a successfully validated model task.
 * 14. updateTaskModelMetadata(uint256 _taskId, string memory _newMetadataURI): Updates model metadata for an owned task.
 *
 * IV. Validator Management
 * 15. registerValidator(string memory _profileURI, uint256 _stakeAmount): Registers as a validator.
 * 16. updateValidatorProfile(string memory _newProfileURI): Updates validator's profile URI.
 * 17. deregisterValidator(): Allows validator to remove themselves and retrieve stake.
 * 18. claimValidationTask(uint256 _taskId): Validator claims an available task to review.
 * 19. submitValidationResult(uint256 _taskId, string memory _metricsURI, bytes32 _reviewHash, bool _isModelValid): Submits validation result.
 *
 * V. Dispute Resolution & Reputation
 * 20. raiseDispute(uint256 _taskId, address _challengedParty, string memory _reasonURI): Raises a dispute on a task outcome.
 * 21. assignArbitrators(uint256 _disputeId, address[] memory _arbitratorAddresses): Owner/Governance assigns arbitrators.
 * 22. submitArbitratorVerdict(uint256 _disputeId, bool _isChallengerVictorious): Arbitrator submits their verdict.
 * 23. finalizeDispute(uint256 _disputeId): Owner/Governance finalizes dispute based on verdicts.
 * 24. getReputationScore(address _account): Views an account's reputation score.
 * 25. claimValidationRewards(uint256 _taskId): Allows a Validator to claim rewards for correct validation.
 *
 * VI. View Functions (for Data Retrieval)
 * 26. getDataManifest(uint256 _manifestId): Retrieves data manifest details.
 * 27. getModelValidationTask(uint256 _taskId): Retrieves model validation task details.
 * 28. getValidator(address _validatorAddress): Retrieves validator profile.
 * 29. getDispute(uint256 _disputeId): Retrieves dispute details.
 */
contract DeScipherProtocol {
    using SafeERC20 for IERC20;

    // --- Custom Errors ---
    error NotOwner();
    error ContractPaused();
    error ContractNotPaused();
    error InvalidStakeAmount();
    error AlreadyRegistered();
    error NotRegistered();
    error ManifestNotFound();
    error NotDataSteward();
    error ManifestNotActive();
    error ManifestInUse();
    error TaskNotFound();
    error NotModelDeveloper();
    error TaskNotInProposedStatus();
    error TaskNotInValidationStatus();
    error TaskAlreadyClaimed();
    error TaskNotClaimedByCaller();
    error TaskAlreadyCompleted();
    error TaskRewardsAlreadyClaimed();
    error ValidatorNotFound();
    error NotValidator();
    error NoActiveTasksForDeregistration();
    error DataNotApprovedForTask();
    error DisputeNotFound();
    error NotArbitrator();
    error ArbitratorAlreadyVoted();
    error DisputeNotArbitrationPhase();
    error DisputeAlreadyFinalized();
    error NoConsensusYet();
    error InsufficientBalanceForStake();
    error InsufficientBalanceForWithdrawal();
    error InvalidFeePercentage();
    error DataManifestIDsRequired();
    error NoValidatorsYet();
    error CannotClaimBeforeConsensus();
    error NotEligibleForRewards();
    error CallerIsNotChallengedParty();
    error InvalidChallengedParty();
    error TaskNotInCorrectStatusForDispute();
    error ValidatorAlreadySubmittedResult();

    // --- Enums ---
    enum TaskStatus { Proposed, DataApprovalPending, InValidation, AwaitingConsensus, Completed, Disputed, Cancelled }
    enum DisputeStatus { Open, AwaitingArbitration, Arbitrated, Resolved }

    // --- Structs ---

    struct DataManifest {
        address steward;
        string metadataURI; // IPFS hash or similar for data description
        bytes32 dataHash; // Cryptographic hash of the data itself
        bytes32 termsHash; // Hash of licensing/usage terms
        uint256 stakeAmount;
        bool isActive; // Can be revoked by steward if not in use
        uint256 approvedTaskCount; // How many tasks have approved this data
        uint256 rewardsAccumulated; // Accumulated rewards for this manifest
        mapping(uint256 => bool) approvedTasks; // taskId => approved status
    }

    struct ModelValidationTask {
        address developer;
        string modelMetadataURI; // IPFS hash or similar for model description
        bytes32 modelHash; // Cryptographic hash of the model artifact
        uint256[] dataManifestIDs; // IDs of data manifests used
        uint256 developerStake;
        TaskStatus status;
        uint256 proposedTimestamp;
        uint256 completionTimestamp;
        bool developerRewardsClaimed;
        mapping(address => ValidationResult) validationResults; // validator address -> result
        address[] activeValidators; // List of validators who claimed this task
        uint256 validVotes; // Count of 'isModelValid == true' votes
        uint256 invalidVotes; // Count of 'isModelValid == false' votes
        uint256 totalValidationReward; // Total reward for validators for this task
    }

    struct ValidationResult {
        bool hasSubmitted;
        bool isModelValid; // Validator's verdict
        string metricsURI; // IPFS hash for detailed metrics
        bytes32 reviewHash; // Hash of the detailed review text
        uint256 submissionTimestamp;
        bool rewardsClaimed;
    }

    struct ValidatorProfile {
        string profileURI; // IPFS hash for validator's expertise/bio
        uint256 stakeAmount;
        int256 reputationScore; // Can be negative
        bool isActive;
        uint256 activeTaskCount; // Tasks currently claimed by this validator
        uint256 disputeCount; // How many disputes this validator is involved in
    }

    struct Dispute {
        uint256 taskId;
        address challenger; // Who raised the dispute
        address challengedParty; // The address of the party being challenged (developer or validator)
        string reasonURI; // IPFS hash for detailed reason
        DisputeStatus status;
        address[] arbitrators;
        mapping(address => bool) arbitratorVerdict; // arbitrator address -> true if challenger wins, false if challenged wins
        uint256 votesForChallenger;
        uint256 votesForChallenged;
        bool finalVerdictChallengerWins; // True if challenger won, False if challenged won
        bool isFinalized;
    }

    // --- State Variables ---
    IERC20 public immutable token;
    address public owner;
    bool public paused;

    uint256 public nextManifestId;
    uint256 public nextTaskId;
    uint256 public nextDisputeId;

    mapping(uint256 => DataManifest) public dataManifests;
    mapping(uint256 => ModelValidationTask) public modelValidationTasks;
    mapping(address => ValidatorProfile) public validators;
    mapping(uint256 => Dispute) public disputes;

    // Reputation scores (separate mapping for direct access)
    mapping(address => int256) public reputationScores;

    // Protocol Fees (in basis points, e.g., 100 = 1%)
    uint256 public dataStewardFeeBps; // % of total task reward allocated to data stewards
    uint256 public developerFeeBps;   // % of total task reward allocated to model developers
    uint256 public validatorRewardBps; // % of total task reward allocated to validators
    uint256 public constant TOTAL_BPS = 10000; // 100%

    uint256 public protocolFeesAccumulated; // Accumulated fees from stakes for the protocol owner

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event FeesSet(uint256 dataStewardBps, uint256 developerBps, uint256 validatorBps);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    event DataManifestRegistered(uint256 indexed manifestId, address indexed steward, uint256 stakeAmount);
    event DataManifestMetadataUpdated(uint256 indexed manifestId, string newMetadataURI);
    event DataManifestRevoked(uint256 indexed manifestId, address indexed steward, uint256 stakeReturned);
    event DataApprovedForTask(uint256 indexed manifestId, uint256 indexed taskId);
    event DataUsageRewardsClaimed(uint256 indexed manifestId, address indexed steward, uint256 amount);

    event ModelValidationTaskProposed(uint256 indexed taskId, address indexed developer, uint256 developerStake);
    event ModelValidationTaskCancelled(uint256 indexed taskId, address indexed developer, uint256 stakeReturned);
    event ModelDeveloperRewardsClaimed(uint256 indexed taskId, address indexed developer, uint256 amount);
    event TaskModelMetadataUpdated(uint256 indexed taskId, string newMetadataURI);

    event ValidatorRegistered(address indexed validator, uint256 stakeAmount);
    event ValidatorProfileUpdated(address indexed validator, string newProfileURI);
    event ValidatorDeregistered(address indexed validator, uint256 stakeReturned);
    event ValidationTaskClaimed(uint256 indexed taskId, address indexed validator);
    event ValidationResultSubmitted(uint256 indexed taskId, address indexed validator, bool isModelValid);
    event TaskConsensusReached(uint256 indexed taskId, bool isModelValid);
    event ValidatorRewardsClaimed(uint256 indexed taskId, address indexed validator, uint256 amount);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed taskId, address indexed challenger, address challengedParty);
    event ArbitratorsAssigned(uint256 indexed disputeId, address[] arbitrators);
    event ArbitratorVerdictSubmitted(uint256 indexed disputeId, address indexed arbitrator, bool isChallengerVictorious);
    event DisputeFinalized(uint256 indexed disputeId, bool challengerWins);
    event ReputationUpdated(address indexed account, int256 newScore, int256 change);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert ContractNotPaused();
        _;
    }

    // Prevents reentrant calls to functions that transfer funds or update balances
    bool internal locked;
    modifier nonReentrant() {
        if (locked) revert ("ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // --- Constructor ---
    constructor(address _tokenAddress, address _initialOwner) {
        if (_tokenAddress == address(0)) revert ("Invalid token address");
        if (_initialOwner == address(0)) revert ("Invalid owner address");

        token = IERC20(_tokenAddress);
        owner = _initialOwner;
        paused = false;

        // Set initial (example) fee structure
        dataStewardFeeBps = 1000; // 10%
        developerFeeBps = 4000;   // 40%
        validatorRewardBps = 5000; // 50%

        if (dataStewardFeeBps + developerFeeBps + validatorRewardBps != TOTAL_BPS) revert ("Initial fees must sum to 100%");

        emit OwnershipTransferred(address(0), owner);
    }

    // --- Core Infrastructure & Administration ---

    /**
     * @dev Transfers ownership of the contract to a new account.
     *      Can only be called by the current owner.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        if (_newOwner == address(0)) revert ("New owner is zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Pauses the contract.
     *      Can only be called by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     *      Can only be called by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Sets the distribution percentages for data stewards, developers, and validators.
     *      The sum of all percentages must equal TOTAL_BPS (10000).
     *      Can only be called by the owner.
     * @param _dataStewardFeeBps Basis points for data steward rewards.
     * @param _developerFeeBps Basis points for model developer rewards.
     * @param _validatorRewardBps Basis points for validator rewards.
     */
    function setProtocolFees(uint256 _dataStewardFeeBps, uint256 _developerFeeBps, uint256 _validatorRewardBps) public onlyOwner {
        if (_dataStewardFeeBps + _developerFeeBps + _validatorRewardBps != TOTAL_BPS) {
            revert InvalidFeePercentage();
        }
        dataStewardFeeBps = _dataStewardFeeBps;
        developerFeeBps = _developerFeeBps;
        validatorRewardBps = _validatorRewardBps;
        emit FeesSet(_dataStewardFeeBps, _developerFeeBps, _validatorRewardBps);
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     * @param _recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address _recipient) public onlyOwner nonReentrant {
        if (_recipient == address(0)) revert ("Invalid recipient address");
        uint256 amount = protocolFeesAccumulated;
        if (amount == 0) revert InsufficientBalanceForWithdrawal();
        protocolFeesAccumulated = 0;
        token.safeTransfer(_recipient, amount);
        emit ProtocolFeesWithdrawn(_recipient, amount);
    }

    // --- Data Steward Management ---

    /**
     * @dev Allows a Data Steward to register a new data manifest.
     *      Requires staking an ERC20 token amount.
     * @param _metadataURI IPFS hash or similar for data description metadata.
     * @param _dataHash Cryptographic hash of the data itself (off-chain).
     * @param _termsHash Hash of licensing/usage terms (off-chain).
     * @param _stakeAmount The amount of ERC20 token to stake for this manifest.
     */
    function registerDataManifest(string memory _metadataURI, bytes32 _dataHash, bytes32 _termsHash, uint256 _stakeAmount) public whenNotPaused {
        if (_stakeAmount == 0) revert InvalidStakeAmount();
        if (token.balanceOf(msg.sender) < _stakeAmount) revert InsufficientBalanceForStake();

        uint256 id = nextManifestId++;
        dataManifests[id] = DataManifest({
            steward: msg.sender,
            metadataURI: _metadataURI,
            dataHash: _dataHash,
            termsHash: _termsHash,
            stakeAmount: _stakeAmount,
            isActive: true,
            approvedTaskCount: 0,
            rewardsAccumulated: 0
        });

        token.safeTransferFrom(msg.sender, address(this), _stakeAmount);
        emit DataManifestRegistered(id, msg.sender, _stakeAmount);
    }

    /**
     * @dev Allows a Data Steward to update the metadata URI of their registered data manifest.
     * @param _manifestId The ID of the data manifest to update.
     * @param _newMetadataURI The new IPFS hash or similar for data description metadata.
     */
    function updateDataManifestMetadata(uint256 _manifestId, string memory _newMetadataURI) public whenNotPaused {
        DataManifest storage manifest = dataManifests[_manifestId];
        if (manifest.steward == address(0)) revert ManifestNotFound();
        if (manifest.steward != msg.sender) revert NotDataSteward();

        manifest.metadataURI = _newMetadataURI;
        emit DataManifestMetadataUpdated(_manifestId, _newMetadataURI);
    }

    /**
     * @dev Allows a Data Steward to revoke an inactive data manifest and retrieve their stake.
     *      Can only be revoked if not currently approved for any active tasks.
     * @param _manifestId The ID of the data manifest to revoke.
     */
    function revokeDataManifest(uint256 _manifestId) public whenNotPaused nonReentrant {
        DataManifest storage manifest = dataManifests[_manifestId];
        if (manifest.steward == address(0)) revert ManifestNotFound();
        if (manifest.steward != msg.sender) revert NotDataSteward();
        if (manifest.approvedTaskCount > 0) revert ManifestInUse();

        manifest.isActive = false;
        uint256 stake = manifest.stakeAmount;
        manifest.stakeAmount = 0; // Clear stake

        token.safeTransfer(msg.sender, stake);
        emit DataManifestRevoked(_manifestId, msg.sender, stake);
    }

    /**
     * @dev Explicitly approves the use of a data manifest for a specific model validation task.
     *      This is a necessary step before a task can proceed to validation.
     * @param _manifestId The ID of the data manifest to approve.
     * @param _taskId The ID of the model validation task for which the data is approved.
     */
    function approveDataForTask(uint256 _manifestId, uint256 _taskId) public whenNotPaused {
        DataManifest storage manifest = dataManifests[_manifestId];
        if (manifest.steward == address(0)) revert ManifestNotFound();
        if (manifest.steward != msg.sender) revert NotDataSteward();
        if (!manifest.isActive) revert ManifestNotActive();

        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.DataApprovalPending) revert TaskNotInProposedStatus();

        bool found = false;
        for (uint256 i = 0; i < task.dataManifestIDs.length; i++) {
            if (task.dataManifestIDs[i] == _manifestId) {
                found = true;
                break;
            }
        }
        if (!found) revert ("Data manifest not requested by this task");

        if (manifest.approvedTasks[_taskId]) revert ("Data already approved for this task");

        manifest.approvedTasks[_taskId] = true;
        manifest.approvedTaskCount++;

        // Check if all data manifests for the task are now approved
        _checkAllDataApprovedForTask(_taskId);

        emit DataApprovedForTask(_manifestId, _taskId);
    }

    /**
     * @dev Claims rewards for a Data Steward based on the usage of their data manifest in completed tasks.
     * @param _manifestId The ID of the data manifest.
     */
    function claimDataUsageRewards(uint256 _manifestId) public whenNotPaused nonReentrant {
        DataManifest storage manifest = dataManifests[_manifestId];
        if (manifest.steward == address(0)) revert ManifestNotFound();
        if (manifest.steward != msg.sender) revert NotDataSteward();
        if (manifest.rewardsAccumulated == 0) revert ("No accumulated rewards to claim");

        uint256 amount = manifest.rewardsAccumulated;
        manifest.rewardsAccumulated = 0;

        token.safeTransfer(msg.sender, amount);
        emit DataUsageRewardsClaimed(_manifestId, msg.sender, amount);
    }

    // --- Model Developer Management ---

    /**
     * @dev Allows a Model Developer to propose a new model validation task.
     *      Requires staking an ERC20 token amount and specifying data manifests to use.
     * @param _modelMetadataURI IPFS hash or similar for model description metadata.
     * @param _modelHash Cryptographic hash of the model artifact.
     * @param _dataManifestIDs Array of IDs of data manifests the model intends to use.
     * @param _developerStake The amount of ERC20 token to stake for this task.
     */
    function proposeModelValidationTask(
        string memory _modelMetadataURI,
        bytes32 _modelHash,
        uint256[] memory _dataManifestIDs,
        uint256 _developerStake
    ) public whenNotPaused {
        if (_developerStake == 0) revert InvalidStakeAmount();
        if (_dataManifestIDs.length == 0) revert DataManifestIDsRequired();
        if (token.balanceOf(msg.sender) < _developerStake) revert InsufficientBalanceForStake();

        uint256 id = nextTaskId++;
        modelValidationTasks[id] = ModelValidationTask({
            developer: msg.sender,
            modelMetadataURI: _modelMetadataURI,
            modelHash: _modelHash,
            dataManifestIDs: _dataManifestIDs,
            developerStake: _developerStake,
            status: TaskStatus.DataApprovalPending, // Initially awaiting data steward approvals
            proposedTimestamp: block.timestamp,
            completionTimestamp: 0,
            developerRewardsClaimed: false,
            validVotes: 0,
            invalidVotes: 0,
            activeValidators: new address[](0),
            totalValidationReward: 0
        });

        token.safeTransferFrom(msg.sender, address(this), _developerStake);
        emit ModelValidationTaskProposed(id, msg.sender, _developerStake);
    }

    /**
     * @dev Allows a Model Developer to cancel their proposed task.
     *      Can only be cancelled if it's in `Proposed` or `DataApprovalPending` status.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelProposedTask(uint256 _taskId) public whenNotPaused nonReentrant {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.developer != msg.sender) revert NotModelDeveloper();
        if (task.status != TaskStatus.Proposed && task.status != TaskStatus.DataApprovalPending) {
            revert TaskNotInProposedStatus();
        }

        task.status = TaskStatus.Cancelled;
        uint256 stake = task.developerStake;
        task.developerStake = 0;

        // Decrease approvedTaskCount for any manifests that approved this task
        for (uint256 i = 0; i < task.dataManifestIDs.length; i++) {
            DataManifest storage manifest = dataManifests[task.dataManifestIDs[i]];
            if (manifest.approvedTasks[_taskId]) {
                manifest.approvedTasks[_taskId] = false;
                if (manifest.approvedTaskCount > 0) manifest.approvedTaskCount--;
            }
        }

        token.safeTransfer(msg.sender, stake);
        emit ModelValidationTaskCancelled(_taskId, msg.sender, stake);
    }

    /**
     * @dev Allows a Model Developer to claim rewards for a successfully validated model task.
     *      Requires the task to be completed and the model deemed valid.
     * @param _taskId The ID of the task to claim rewards for.
     */
    function claimModelDeveloperRewards(uint256 _taskId) public whenNotPaused nonReentrant {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.developer != msg.sender) revert NotModelDeveloper();
        if (task.status != TaskStatus.Completed) revert ("Task not completed");
        if (task.developerRewardsClaimed) revert TaskRewardsAlreadyClaimed();
        if (task.validVotes <= task.invalidVotes) revert ("Model was not deemed valid by consensus"); // Developer only gets rewards if model is valid

        uint256 developerReward = (task.developerStake * developerFeeBps) / TOTAL_BPS; // Example calculation, could be more complex
        
        // Protocol fee from developer's stake
        uint256 protocolShare = task.developerStake - developerReward;
        protocolFeesAccumulated += protocolShare;

        task.developerRewardsClaimed = true;
        _updateReputation(msg.sender, 50); // Positive reputation for successful model

        token.safeTransfer(msg.sender, developerReward);
        emit ModelDeveloperRewardsClaimed(_taskId, msg.sender, developerReward);
    }

    /**
     * @dev Allows a Model Developer to update the model metadata URI for their proposed task.
     *      Can only be done if the task is in `Proposed` or `DataApprovalPending` status.
     * @param _taskId The ID of the task to update.
     * @param _newMetadataURI The new IPFS hash or similar for model description metadata.
     */
    function updateTaskModelMetadata(uint256 _taskId, string memory _newMetadataURI) public whenNotPaused {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.developer != msg.sender) revert NotModelDeveloper();
        if (task.status != TaskStatus.Proposed && task.status != TaskStatus.DataApprovalPending) {
            revert TaskNotInProposedStatus();
        }

        task.modelMetadataURI = _newMetadataURI;
        emit TaskModelMetadataUpdated(_taskId, _newMetadataURI);
    }

    // --- Validator Management ---

    /**
     * @dev Allows an individual to register as a Validator.
     *      Requires staking an ERC20 token amount and providing a profile URI.
     * @param _profileURI IPFS hash or similar for validator's expertise/bio.
     * @param _stakeAmount The amount of ERC20 token to stake as a validator.
     */
    function registerValidator(string memory _profileURI, uint256 _stakeAmount) public whenNotPaused {
        if (validators[msg.sender].isActive) revert AlreadyRegistered();
        if (_stakeAmount == 0) revert InvalidStakeAmount();
        if (token.balanceOf(msg.sender) < _stakeAmount) revert InsufficientBalanceForStake();

        validators[msg.sender] = ValidatorProfile({
            profileURI: _profileURI,
            stakeAmount: _stakeAmount,
            reputationScore: 0,
            isActive: true,
            activeTaskCount: 0,
            disputeCount: 0
        });

        reputationScores[msg.sender] = 0; // Initialize reputation

        token.safeTransferFrom(msg.sender, address(this), _stakeAmount);
        emit ValidatorRegistered(msg.sender, _stakeAmount);
    }

    /**
     * @dev Allows a Validator to update their profile URI.
     * @param _newProfileURI The new IPFS hash for the validator's profile.
     */
    function updateValidatorProfile(string memory _newProfileURI) public whenNotPaused {
        ValidatorProfile storage validator = validators[msg.sender];
        if (!validator.isActive) revert NotValidator();

        validator.profileURI = _newProfileURI;
        emit ValidatorProfileUpdated(msg.sender, _newProfileURI);
    }

    /**
     * @dev Allows a Validator to deregister from the system and retrieve their stake.
     *      Can only deregister if no active tasks or disputes are pending.
     */
    function deregisterValidator() public whenNotPaused nonReentrant {
        ValidatorProfile storage validator = validators[msg.sender];
        if (!validator.isActive) revert NotValidator();
        if (validator.activeTaskCount > 0 || validator.disputeCount > 0) revert NoActiveTasksForDeregistration();

        validator.isActive = false;
        uint256 stake = validator.stakeAmount;
        validator.stakeAmount = 0; // Clear stake

        token.safeTransfer(msg.sender, stake);
        emit ValidatorDeregistered(msg.sender, stake);
    }

    /**
     * @dev Allows a registered Validator to claim an available model validation task for review.
     * @param _taskId The ID of the task to claim.
     */
    function claimValidationTask(uint256 _taskId) public whenNotPaused {
        ValidatorProfile storage validator = validators[msg.sender];
        if (!validator.isActive) revert NotValidator();

        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.InValidation) revert TaskNotInValidationStatus();
        if (task.validationResults[msg.sender].hasSubmitted) revert TaskAlreadyClaimed(); // Validator can only claim once

        task.validationResults[msg.sender].hasSubmitted = false; // Mark as claimed but not submitted
        task.activeValidators.push(msg.sender);
        validator.activeTaskCount++;

        emit ValidationTaskClaimed(_taskId, msg.sender);
    }

    /**
     * @dev Allows a Validator to submit their validation results for a claimed task.
     *      Includes metrics URI, review hash, and their verdict (isModelValid).
     * @param _taskId The ID of the task.
     * @param _metricsURI IPFS hash for detailed metrics.
     * @param _reviewHash Hash of the detailed review text.
     * @param _isModelValid The validator's verdict: true if the model is valid, false otherwise.
     */
    function submitValidationResult(uint256 _taskId, string memory _metricsURI, bytes32 _reviewHash, bool _isModelValid) public whenNotPaused {
        ValidatorProfile storage validator = validators[msg.sender];
        if (!validator.isActive) revert NotValidator();

        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.InValidation) revert TaskNotInValidationStatus();
        if (!task.validationResults[msg.sender].hasSubmitted && !contains(task.activeValidators, msg.sender)) revert TaskNotClaimedByCaller();
        if (task.validationResults[msg.sender].hasSubmitted) revert ValidatorAlreadySubmittedResult();

        task.validationResults[msg.sender] = ValidationResult({
            hasSubmitted: true,
            isModelValid: _isModelValid,
            metricsURI: _metricsURI,
            reviewHash: _reviewHash,
            submissionTimestamp: block.timestamp,
            rewardsClaimed: false
        });

        if (_isModelValid) {
            task.validVotes++;
        } else {
            task.invalidVotes++;
        }

        validator.activeTaskCount--; // No longer active for this task, result submitted

        emit ValidationResultSubmitted(_taskId, msg.sender, _isModelValid);

        _checkTaskConsensus(_taskId);
    }

    /**
     * @dev Allows a Validator to claim their rewards for tasks where their validation result
     *      contributed to the consensus and was deemed correct.
     * @param _taskId The ID of the task.
     */
    function claimValidationRewards(uint256 _taskId) public whenNotPaused nonReentrant {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Completed) revert CannotClaimBeforeConsensus();

        ValidationResult storage result = task.validationResults[msg.sender];
        if (!result.hasSubmitted) revert NotEligibleForRewards();
        if (result.rewardsClaimed) revert TaskRewardsAlreadyClaimed();

        bool taskWasValid = task.validVotes > task.invalidVotes;
        if (taskWasValid != result.isModelValid) revert NotEligibleForRewards(); // Only reward if validator's verdict matched consensus

        uint256 rewardPerValidator = 0;
        if (task.activeValidators.length > 0) {
            rewardPerValidator = task.totalValidationReward / task.activeValidators.length;
        }

        result.rewardsClaimed = true;
        _updateReputation(msg.sender, 25); // Positive reputation for correct validation

        token.safeTransfer(msg.sender, rewardPerValidator);
        emit ValidatorRewardsClaimed(_taskId, msg.sender, rewardPerValidator);
    }

    // --- Dispute Resolution & Reputation ---

    /**
     * @dev Allows any stakeholder to raise a dispute regarding a task's outcome or a party's action.
     *      Challenges either the Model Developer or a specific Validator.
     * @param _taskId The ID of the task related to the dispute.
     * @param _challengedParty The address of the party being challenged (Developer or Validator).
     * @param _reasonURI IPFS hash for detailed reason for the dispute.
     */
    function raiseDispute(uint256 _taskId, address _challengedParty, string memory _reasonURI) public whenNotPaused {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        if (task.status == TaskStatus.Disputed) revert ("Task already in dispute");
        if (task.status != TaskStatus.Completed && task.status != TaskStatus.AwaitingConsensus) revert TaskNotInCorrectStatusForDispute();
        if (_challengedParty == address(0)) revert InvalidChallengedParty();
        if (_challengedParty != task.developer && !validators[_challengedParty].isActive) revert InvalidChallengedParty();

        uint256 id = nextDisputeId++;
        disputes[id] = Dispute({
            taskId: _taskId,
            challenger: msg.sender,
            challengedParty: _challengedParty,
            reasonURI: _reasonURI,
            status: DisputeStatus.Open,
            arbitrators: new address[](0),
            votesForChallenger: 0,
            votesForChallenged: 0,
            finalVerdictChallengerWins: false,
            isFinalized: false
        });

        task.status = TaskStatus.Disputed;
        if (validators[_challengedParty].isActive) validators[_challengedParty].disputeCount++;

        emit DisputeRaised(id, _taskId, msg.sender, _challengedParty);
    }

    /**
     * @dev Allows the owner or a designated governance role to assign specific addresses as arbitrators for an ongoing dispute.
     * @param _disputeId The ID of the dispute.
     * @param _arbitratorAddresses An array of addresses to assign as arbitrators.
     */
    function assignArbitrators(uint256 _disputeId, address[] memory _arbitratorAddresses) public onlyOwner whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.challenger == address(0)) revert DisputeNotFound();
        if (dispute.status != DisputeStatus.Open) revert ("Dispute not in open status");

        dispute.arbitrators = _arbitratorAddresses;
        dispute.status = DisputeStatus.AwaitingArbitration;

        emit ArbitratorsAssigned(_disputeId, _arbitratorAddresses);
    }

    /**
     * @dev Allows an assigned Arbitrator to submit their verdict for a dispute.
     * @param _disputeId The ID of the dispute.
     * @param _isChallengerVictorious True if the arbitrator rules in favor of the challenger, false otherwise.
     */
    function submitArbitratorVerdict(uint256 _disputeId, bool _isChallengerVictorious) public whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.challenger == address(0)) revert DisputeNotFound();
        if (dispute.status != DisputeStatus.AwaitingArbitration) revert DisputeNotArbitrationPhase();

        bool isArbitrator = false;
        for (uint256 i = 0; i < dispute.arbitrators.length; i++) {
            if (dispute.arbitrators[i] == msg.sender) {
                isArbitrator = true;
                break;
            }
        }
        if (!isArbitrator) revert NotArbitrator();
        if (dispute.arbitratorVerdict[msg.sender]) revert ArbitratorAlreadyVoted();

        dispute.arbitratorVerdict[msg.sender] = true; // Mark as voted
        if (_isChallengerVictorious) {
            dispute.votesForChallenger++;
        } else {
            dispute.votesForChallenged++;
        }

        emit ArbitratorVerdictSubmitted(_disputeId, msg.sender, _isChallengerVictorious);
    }

    /**
     * @dev Allows the owner or a designated governance role to finalize a dispute based on arbitrator verdicts.
     *      Executes the outcome and adjusts stakes/reputations.
     * @param _disputeId The ID of the dispute to finalize.
     */
    function finalizeDispute(uint256 _disputeId) public onlyOwner whenNotPaused nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.challenger == address(0)) revert DisputeNotFound();
        if (dispute.status != DisputeStatus.AwaitingArbitration && dispute.status != DisputeStatus.Arbitrated) revert DisputeNotArbitrationPhase();
        if (dispute.isFinalized) revert DisputeAlreadyFinalized();
        if (dispute.votesForChallenger + dispute.votesForChallenged < dispute.arbitrators.length / 2 + 1) revert NoConsensusYet(); // Simple majority

        dispute.status = DisputeStatus.Resolved;
        dispute.isFinalized = true;

        bool challengerWins = dispute.votesForChallenger > dispute.votesForChallenged;
        dispute.finalVerdictChallengerWins = challengerWins;

        ModelValidationTask storage task = modelValidationTasks[dispute.taskId];
        if (validators[dispute.challengedParty].isActive) validators[dispute.challengedParty].disputeCount--;

        // Apply consequences based on verdict
        if (challengerWins) {
            // Challenged party loses stake and reputation
            if (dispute.challengedParty == task.developer) {
                // Developer was challenged and lost
                _punishDeveloper(dispute.taskId, task.developerStake / 2); // Example punishment
                _updateReputation(task.developer, -100);
            } else {
                // Validator was challenged and lost
                _punishValidator(dispute.challengedParty, validators[dispute.challengedParty].stakeAmount / 2); // Example punishment
                _updateReputation(dispute.challengedParty, -100);
            }
            // Challenger gains reputation
            _updateReputation(dispute.challenger, 50);
        } else {
            // Challenger loses reputation and potentially a small stake (implicit for simplicity here, could be added)
            _updateReputation(dispute.challenger, -50);
            // Challenged party gains reputation
            _updateReputation(dispute.challengedParty, 25);
        }

        // Revert task status if dispute was about a completed task being overturned
        if (challengerWins && dispute.challengedParty == task.developer && task.validVotes > task.invalidVotes) {
            task.status = TaskStatus.Disputed; // Effectively "invalidated"
        } else if (!challengerWins && dispute.challengedParty == task.developer && task.validVotes <= task.invalidVotes) {
            task.status = TaskStatus.Disputed; // Effectively "validated"
        } else {
            task.status = TaskStatus.Completed; // Otherwise, resolve task to completed
        }

        emit DisputeFinalized(_disputeId, challengerWins);
    }

    /**
     * @dev Retrieves the current reputation score of an account.
     * @param _account The address of the account.
     * @return The reputation score.
     */
    function getReputationScore(address _account) public view returns (int256) {
        return reputationScores[_account];
    }

    // --- View Functions (for Data Retrieval) ---

    /**
     * @dev Retrieves all details of a specific data manifest.
     * @param _manifestId The ID of the data manifest.
     * @return DataManifest struct containing all details.
     */
    function getDataManifest(uint256 _manifestId) public view returns (
        address steward,
        string memory metadataURI,
        bytes32 dataHash,
        bytes32 termsHash,
        uint256 stakeAmount,
        bool isActive,
        uint256 approvedTaskCount,
        uint256 rewardsAccumulated
    ) {
        DataManifest storage manifest = dataManifests[_manifestId];
        if (manifest.steward == address(0)) revert ManifestNotFound();
        return (
            manifest.steward,
            manifest.metadataURI,
            manifest.dataHash,
            manifest.termsHash,
            manifest.stakeAmount,
            manifest.isActive,
            manifest.approvedTaskCount,
            manifest.rewardsAccumulated
        );
    }

    /**
     * @dev Retrieves all details of a specific model validation task.
     * @param _taskId The ID of the model validation task.
     * @return ModelValidationTask struct containing all details (excluding detailed validator results).
     */
    function getModelValidationTask(uint256 _taskId) public view returns (
        address developer,
        string memory modelMetadataURI,
        bytes32 modelHash,
        uint256[] memory dataManifestIDs,
        uint256 developerStake,
        TaskStatus status,
        uint256 proposedTimestamp,
        uint256 completionTimestamp,
        bool developerRewardsClaimed,
        uint256 validVotes,
        uint256 invalidVotes,
        address[] memory activeValidators,
        uint256 totalValidationReward
    ) {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developer == address(0)) revert TaskNotFound();
        return (
            task.developer,
            task.modelMetadataURI,
            task.modelHash,
            task.dataManifestIDs,
            task.developerStake,
            task.status,
            task.proposedTimestamp,
            task.completionTimestamp,
            task.developerRewardsClaimed,
            task.validVotes,
            task.invalidVotes,
            task.activeValidators,
            task.totalValidationReward
        );
    }

    /**
     * @dev Retrieves the profile details of a specific validator.
     * @param _validatorAddress The address of the validator.
     * @return ValidatorProfile struct containing all details.
     */
    function getValidator(address _validatorAddress) public view returns (
        string memory profileURI,
        uint256 stakeAmount,
        int256 reputationScore,
        bool isActive,
        uint256 activeTaskCount,
        uint256 disputeCount
    ) {
        ValidatorProfile storage validator = validators[_validatorAddress];
        if (!validator.isActive) revert ValidatorNotFound();
        return (
            validator.profileURI,
            validator.stakeAmount,
            validator.reputationScore,
            validator.isActive,
            validator.activeTaskCount,
            validator.disputeCount
        );
    }

    /**
     * @dev Retrieves all details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute struct containing all details.
     */
    function getDispute(uint256 _disputeId) public view returns (
        uint256 taskId,
        address challenger,
        address challengedParty,
        string memory reasonURI,
        DisputeStatus status,
        address[] memory arbitrators,
        uint256 votesForChallenger,
        uint256 votesForChallenged,
        bool finalVerdictChallengerWins,
        bool isFinalized
    ) {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.challenger == address(0)) revert DisputeNotFound();
        return (
            dispute.taskId,
            dispute.challenger,
            dispute.challengedParty,
            dispute.reasonURI,
            dispute.status,
            dispute.arbitrators,
            dispute.votesForChallenger,
            dispute.votesForChallenged,
            dispute.finalVerdictChallengerWins,
            dispute.isFinalized
        );
    }

    // --- Internal / Private Helper Functions ---

    /**
     * @dev Checks if all data manifests required for a task have been approved.
     *      If so, moves the task to `InValidation` status.
     * @param _taskId The ID of the task to check.
     */
    function _checkAllDataApprovedForTask(uint256 _taskId) internal {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.status != TaskStatus.DataApprovalPending) return;

        bool allApproved = true;
        for (uint256 i = 0; i < task.dataManifestIDs.length; i++) {
            DataManifest storage manifest = dataManifests[task.dataManifestIDs[i]];
            if (!manifest.approvedTasks[_taskId]) {
                allApproved = false;
                break;
            }
        }

        if (allApproved) {
            task.status = TaskStatus.InValidation;
            // Potentially mint a "TaskReady" NFT or signal off-chain for validators
        }
    }

    /**
     * @dev Checks if enough validators have submitted results to reach consensus for a task.
     *      If so, finalizes the task, distributes rewards, and updates reputations.
     * @param _taskId The ID of the task to check.
     */
    function _checkTaskConsensus(uint256 _taskId) internal {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.status != TaskStatus.InValidation) return;

        uint256 submittedValidatorsCount = task.validVotes + task.invalidVotes;
        if (submittedValidatorsCount == 0) return; // No validators submitted yet

        // Simple majority consensus: if more than 50% of active validators have submitted, and there's a clear majority
        if (submittedValidatorsCount < task.activeValidators.length / 2 + 1) return; // Not enough submissions for majority consensus

        task.status = TaskStatus.AwaitingConsensus; // Mark as awaiting finalization

        if (task.validVotes == task.invalidVotes) {
            // Tie-breaker or more validators needed, for simplicity let's say it stays AwaitingConsensus
            // A dispute mechanism could be triggered here automatically
            return;
        }

        bool modelIsValid = task.validVotes > task.invalidVotes;
        task.status = TaskStatus.Completed;
        task.completionTimestamp = block.timestamp;
        emit TaskConsensusReached(_taskId, modelIsValid);

        // Distribute rewards and update reputations based on consensus
        _distributeTaskRewards(_taskId, modelIsValid);
    }

    /**
     * @dev Distributes rewards for a completed task to data stewards, developers, and validators.
     *      Also updates reputations based on the outcome.
     * @param _taskId The ID of the completed task.
     * @param _modelIsValid The final consensus verdict for the model.
     */
    function _distributeTaskRewards(uint256 _taskId, bool _modelIsValid) internal {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        uint256 totalStake = task.developerStake;
        uint256 totalRewardsPool = totalStake; // For simplicity, developer stake forms the reward pool

        uint256 dataStewardShare = (totalRewardsPool * dataStewardFeeBps) / TOTAL_BPS;
        uint256 developerShare = (totalRewardsPool * developerFeeBps) / TOTAL_BPS; // This is if developer gets a share of other stakes, here it's their own
        uint256 validatorShare = (totalRewardsPool * validatorRewardBps) / TOTAL_BPS;

        // If model is invalid, developer stake is lost / mostly lost to protocol/validators
        if (!_modelIsValid) {
            // For simplicity, if model is invalid, developer loses entire stake to validators and protocol
            validatorShare = (totalStake * validatorRewardBps) / TOTAL_BPS;
            protocolFeesAccumulated += totalStake - validatorShare;
            developerShare = 0; // No reward for invalid model
        } else {
            // Data steward rewards
            for (uint256 i = 0; i < task.dataManifestIDs.length; i++) {
                DataManifest storage manifest = dataManifests[task.dataManifestIDs[i]];
                uint256 individualDataStewardReward = dataStewardShare / task.dataManifestIDs.length; // Even split
                manifest.rewardsAccumulated += individualDataStewardReward;
            }
            // Developer has separate claim function, but reputation is updated here
            _updateReputation(task.developer, 75); // Reward for valid model
        }

        // Validators rewards (claimed separately, but distributed here)
        task.totalValidationReward = validatorShare; // Store for individual validator claims
        // Reputations for validators updated in `claimValidationRewards`
    }

    /**
     * @dev Updates the reputation score of an account.
     * @param _account The address of the account to update.
     * @param _scoreChange The amount to change the reputation by (can be positive or negative).
     */
    function _updateReputation(address _account, int256 _scoreChange) internal {
        reputationScores[_account] += _scoreChange;
        emit ReputationUpdated(_account, reputationScores[_account], _scoreChange);
    }

    /**
     * @dev Punishes a developer by transferring a portion of their stake to the protocol.
     * @param _taskId The ID of the task associated with the developer.
     * @param _amount The amount to seize from the developer's stake.
     */
    function _punishDeveloper(uint256 _taskId, uint256 _amount) internal {
        ModelValidationTask storage task = modelValidationTasks[_taskId];
        if (task.developerStake < _amount) _amount = task.developerStake;
        task.developerStake -= _amount;
        protocolFeesAccumulated += _amount;
    }

    /**
     * @dev Punishes a validator by transferring a portion of their stake to the protocol.
     * @param _validatorAddress The address of the validator to punish.
     * @param _amount The amount to seize from the validator's stake.
     */
    function _punishValidator(address _validatorAddress, uint256 _amount) internal {
        ValidatorProfile storage validator = validators[_validatorAddress];
        if (validator.stakeAmount < _amount) _amount = validator.stakeAmount;
        validator.stakeAmount -= _amount;
        protocolFeesAccumulated += _amount;
    }

    /**
     * @dev Helper function to check if an address is in an array of addresses.
     * @param _array The array of addresses.
     * @param _addr The address to search for.
     * @return True if the address is found, false otherwise.
     */
    function contains(address[] memory _array, address _addr) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == _addr) {
                return true;
            }
        }
        return false;
    }
}
```