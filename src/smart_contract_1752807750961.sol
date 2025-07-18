Here's a Solidity smart contract named `NexusAI` that incorporates advanced concepts like decentralized AI inference validation, a dynamic reputation system, data provenance attestation, and a basic on-chain governance structure. It aims to avoid direct duplication of common open-source contracts by focusing on the unique combination of these functionalities.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial deployment/setup before DAO takes over
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though Solidity 0.8+ has built-in overflow checks

/*
 * @title NexusAI: Decentralized AI Inference Validation & Reputation Network
 * @author [Your Name/Alias, e.g., "AI Architects DAO"]
 * @notice This contract facilitates a decentralized network for AI model registration,
 *         inference validation, data provenance attestation, and a reputation system.
 *         It aims to provide verifiable AI outputs and trusted data, governed by a DAO.
 *
 * @dev This contract does not run AI models on-chain. Instead, it provides a framework
 *      for off-chain AI model inference to be validated by a network of validators,
 *      incentivizing accuracy and penalizing incorrect submissions through staking
 *      and a dynamic reputation system.
 *      It integrates a basic governance mechanism for protocol evolution.
 *      Note: Iterating over mappings is not directly possible in Solidity. For a production
 *      system, `_getConsensusOutput` and `_getParticipatingValidators` would require
 *      additional data structures (e.g., dynamic arrays of addresses) to function correctly.
 *      These are conceptual in this example.
 */

/*
 * OUTLINE:
 * 1.  Enums & Structs: Define data structures for models, validators, inference jobs, attestations, and governance proposals.
 * 2.  Errors: Custom error types for clearer feedback and gas efficiency.
 * 3.  Events: Emit events for significant state changes.
 * 4.  State Variables: Mappings and arrays to store contract state and configuration.
 * 5.  Modifiers: Access control and state-checking modifiers.
 * 6.  Constructor: Initializes the contract with the Nexus Token address and default parameters.
 * 7.  Core Registries & Lifecycle Management (6 functions):
 *     Functions for registering, updating, and deactivating AI models and validators, including their staking requirements.
 * 8.  Decentralized Inference Validation & Dispute Resolution (7 functions):
 *     Functions to request, submit, and challenge AI inference jobs. Includes mechanisms for job finalization
 *     and dispute management (with governance integration for resolution).
 * 9.  Reputation & Staking Mechanics (5 functions):
 *     Functions for staking and unstaking the native NEXUS_TOKEN, claiming accumulated rewards,
 *     and querying reputation scores of models and validators.
 * 10. Data Attestation & Provenance (2 functions):
 *     Functions to attest to the origin and integrity of datasets, linking them to specific AI models.
 * 11. Protocol Governance & Utilities (5 functions):
 *     Functions enabling decentralized governance through proposal submission, voting, and execution.
 *     Includes the ability to adjust protocol fees and withdraw from the treasury via governance.
 * 12. Internal Helper Functions: Auxiliary functions for token transfers, reputation updates, and reward management.
 */

/*
 * FUNCTION SUMMARY:
 *
 * I. Core Registries & Lifecycle Management
 * 1.  registerAIModel(string calldata _ipfsHash, string calldata _modelName, string calldata _description):
 *     Registers a new AI model with its metadata and an initial staking deposit. Requires `MIN_MODEL_STAKE`.
 * 2.  updateAIModelDetails(uint256 _modelId, string calldata _newIpfsHash, string calldata _newDescription):
 *     Allows a model owner to update the metadata (IPFS hash, description) of their registered model.
 * 3.  deactivateAIModel(uint256 _modelId):
 *     Marks an AI model as inactive. Its stake remains locked for a cooldown period (`MODEL_DEACTIVATION_COOLDOWN`).
 * 4.  registerValidator(string calldata _validatorName):
 *     Registers a new participant as an AI inference validator, requiring an initial staking deposit (`MIN_VALIDATOR_STAKE`).
 * 5.  toggleValidatorActiveStatus(bool _isActive):
 *     Allows a validator to toggle their active participation status for new validation jobs (active/inactive).
 * 6.  deregisterValidator():
 *     Initiates the process of a validator exiting the network, locking their stake for a cooldown period (`VALIDATOR_DEREGISTER_COOLDOWN`).
 *
 * II. Decentralized Inference Validation & Dispute Resolution
 * 7.  requestInferenceValidation(uint256 _modelId, bytes32 _inputDataHash, uint256 _paymentAmount):
 *     Initiates a validation job for a given AI model's inference. Requester pays a fee (`baseInferenceFee`).
 * 8.  submitInferenceResult(uint256 _jobId, bytes32 _outputDataHash):
 *     Allows registered and active validators to submit their computed/validated output hash for an open inference job.
 * 9.  challengeInferenceResult(uint256 _jobId, bytes32 _challengerOutputHash):
 *     A user or validator can challenge an inference job's results by providing an alternative output. Requires a challenge fee (`challengeFee`).
 * 10. finalizeInferenceJob(uint256 _jobId):
 *     Finalizes an inference job (if not challenged) once the submission window closes. Determines consensus output and distributes rewards.
 * 11. proposeDisputeResolution(uint256 _jobId, bytes32 _correctOutputHash, address[] calldata _winningValidators):
 *     (Conceptual - typically part of `executeGovernanceProposal` for a specific dispute proposal) Proposes the correct output for a challenged job and identifies winning validators.
 * 12. voteOnDisputeResolution(uint256 _disputeId, bool _support):
 *     (Conceptual - directs to `voteOnGovernanceProposal`) Allows DAO members to vote on dispute resolution proposals.
 * 13. executeDisputeResolution(uint256 _disputeId):
 *     (Conceptual - directs to `executeGovernanceProposal`) Executes a passed dispute resolution.
 *
 * III. Reputation & Staking Mechanics
 * 14. stake(uint256 _amount, uint256 _entityId, EntityType _entityType):
 *     Generic function for models or validators to stake NEXUS_TOKEN.
 * 15. unstake(uint256 _amount, uint256 _entityId, EntityType _entityType):
 *     Generic function for models or validators to unstake NEXUS_TOKEN, subject to cooldowns and minimum stake.
 * 16. claimRewards():
 *     Allows models and validators to claim accumulated rewards from successful validations/disputes and protocol incentives.
 * 17. getReputationScore(address _account):
 *     Retrieves the current reputation score of a validator or the owner of a model.
 * 18. getAvailableRewards(address _account):
 *     Checks the amount of rewards an account can claim.
 *
 * IV. Data Attestation & Provenance
 * 19. attestDataProvenance(bytes32 _dataHash, string calldata _description, uint256[] calldata _linkedModelIds):
 *     Allows data providers to officially attest to the provenance and integrity of a dataset, linking it to AI models.
 * 20. getAttestationDetails(uint256 _attestationId):
 *     Retrieves the details of a specific data attestation.
 *
 * V. Protocol Governance & Utilities
 * 21. submitGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _calldata):
 *     Allows users with sufficient voting power to propose changes to contract parameters or logic.
 * 22. voteOnGovernanceProposal(uint256 _proposalId, bool _support):
 *     Allows DAO members to vote on active governance proposals.
 * 23. executeGovernanceProposal(uint256 _proposalId):
 *     Executes a governance proposal that has met the required voting threshold and quorum.
 * 24. setProtocolFees(uint256 _inferenceFee, uint256 _challengeFee, uint256 _validatorRewardRate, uint256 _disputeResolutionFee):
 *     Governance-controlled function to adjust the protocol's fee structure.
 * 25. withdrawProtocolTreasury(uint256 _amount):
 *     Allows the DAO treasury to withdraw accumulated protocol fees.
 */

contract NexusAI is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public immutable NEXUS_TOKEN; // The ERC20 token used for staking and payments

    // --- Enums ---
    enum ModelStatus { Active, Inactive, Disputed }
    enum ValidatorStatus { Active, Inactive, Deregistering }
    enum InferenceJobStatus { Pending, Validating, Challenged, Finalized, DisputeResolved }
    enum EntityType { Model, Validator }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---
    struct AIModel {
        address owner;
        string ipfsHash;
        string name;
        string description;
        uint256 registrationTime;
        ModelStatus status;
        uint256 totalInferences;
        uint256 successfulInferences;
        uint256 disputesWon;
        uint256 disputesLost;
        uint256 reputationScore;
        uint256 stakedAmount; // Total staked by model owner for this model
        uint256 lastActivityTime; // For cooldown tracking after deactivation
    }

    struct Validator {
        string name;
        ValidatorStatus status;
        uint256 registrationTime;
        uint256 reputationScore;
        uint256 stakedAmount; // Total staked by this validator
        uint256 validatedJobs;
        uint256 successfulValidations;
        uint256 disputesWon;
        uint256 disputesLost;
        uint256 lastActiveTime; // For reputation decay, activity tracking
        uint256 deregisterCooldownEnd; // Timestamp when validator can fully withdraw after deregistering
    }

    struct InferenceJob {
        uint256 modelId;
        address requester;
        bytes32 inputDataHash;
        InferenceJobStatus status;
        uint256 requestTime;
        uint256 submissionDeadline;
        uint256 challengeDeadline;
        uint256 finalizationTime;
        bytes32 consensusOutputHash; // Final output after validation/dispute
        uint256 totalSubmissions;
        mapping(address => bytes32) validatorSubmissions; // validator => outputHash
        mapping(address => bool) hasSubmitted; // validator => bool
        mapping(bytes32 => uint256) outputVoteCounts; // outputHash => count of validators agreeing
        address[] participatingValidators; // Array to iterate through submissions (conceptual for mappings)
        uint256 disputeProposalId; // Link to a governance proposal if challenged
    }

    struct DataAttestation {
        address attestor;
        bytes32 dataHash;
        string description;
        uint256[] linkedModelIds; // IDs of models trained/used with this data
        uint256 timestamp;
    }

    struct GovernanceProposal {
        string description;
        address targetContract;
        bytes callData;
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter => hasVoted
        ProposalState state;
        bool executed;
    }

    struct FeeParameters {
        uint256 baseInferenceFee;
        uint256 challengeFee;
        uint256 validatorRewardRate; // Per successful validation
        uint256 disputeResolutionFee; // Paid by challenger/dispute loser (goes to treasury)
    }

    // --- Errors ---
    error InvalidEntityId();
    error NotModelOwner(uint256 _modelId, address _caller);
    error NotValidator(address _caller);
    error ModelNotActive(uint256 _modelId);
    error ValidatorNotActive(address _validator);
    error InvalidStakingAmount();
    error InsufficientStake(uint256 _required, uint256 _available);
    error UnstakeCooldownActive(uint256 _remainingTime);
    error NoRewardsAvailable();
    error InvalidJobStatus();
    error NotEnoughSubmissions();
    error JobAlreadyFinalized();
    error InvalidOutputHash();
    error AlreadySubmitted();
    error ChallengeTooLate();
    error InDispute();
    error AlreadyChallenged();
    error NotDisputeResolver(); // For proposeDisputeResolution access control (conceptual)
    error InvalidVote();
    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error TransferFailed();
    error NotEnoughBalance(uint256 _required, uint256 _available);
    error MinimumStakeNotMet(uint256 _required, uint256 _current);
    error AlreadyRegisteredModel();
    error AlreadyRegisteredValidator();
    error StatusAlreadySet();
    error SubmissionWindowClosed();
    error ChallengerOutputHashInvalid();
    error VotingPeriodNotEnded();
    error InsufficientVotingPower();


    // --- Events ---
    event AIModelRegistered(uint256 indexed modelId, address indexed owner, string ipfsHash, string name);
    event AIModelUpdated(uint256 indexed modelId, string newIpfsHash, string newDescription);
    event AIModelDeactivated(uint256 indexed modelId, address indexed owner);
    event ValidatorRegistered(address indexed validatorAddress, string name);
    event ValidatorStatusToggled(address indexed validatorAddress, bool isActive);
    event ValidatorDeregistered(address indexed validatorAddress);

    event InferenceValidationRequested(uint256 indexed jobId, uint256 indexed modelId, address indexed requester, bytes32 inputDataHash, uint256 fee);
    event InferenceResultSubmitted(uint256 indexed jobId, address indexed validator, bytes32 outputDataHash);
    event InferenceChallenged(uint256 indexed jobId, address indexed challenger, bytes32 challengerOutputHash);
    event InferenceJobFinalized(uint256 indexed jobId, bytes32 consensusOutputHash, uint256 totalValidators, uint256 rewardsDistributed);
    event DisputeResolutionProposed(uint256 indexed disputeId, uint256 indexed jobId, bytes32 correctOutputHash);
    event DisputeResolutionVoted(uint256 indexed disputeId, address indexed voter, bool support);
    event DisputeResolutionExecuted(uint256 indexed disputeId, uint256 indexed jobId, bytes32 finalOutput);

    event Staked(address indexed account, uint256 amount, uint256 indexed entityId, EntityType entityType);
    event Unstaked(address indexed account, uint256 amount, uint256 indexed entityId, EntityType entityType);
    event RewardsClaimed(address indexed account, uint256 amount);
    event ReputationUpdated(address indexed account, uint256 newReputation);

    event DataAttested(uint256 indexed attestationId, address indexed attestor, bytes32 dataHash);

    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ProtocolFeesSet(uint256 inferenceFee, uint256 challengeFee, uint256 validatorRewardRate, uint256 disputeResolutionFee);
    event ProtocolTreasuryWithdrawn(address indexed recipient, uint256 amount);


    // --- State Variables ---
    uint256 public nextModelId;
    mapping(uint256 => AIModel) public aiModels;
    mapping(address => uint256) public modelIdByOwner; // For quick lookup of a single model per owner (simplification)
    mapping(address => bool) public isModelOwnerRegistered; // To track if an address owns a registered model

    mapping(address => Validator) public validators;
    mapping(address => bool) public isValidatorRegistered;

    uint256 public nextInferenceJobId;
    mapping(uint256 => InferenceJob) public inferenceJobs;

    uint256 public nextAttestationId;
    mapping(uint256 => DataAttestation) public dataAttestations;

    uint256 public nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    // Map addresses to their voting power (derived from staked NEXUS_TOKEN, reputation, etc.)
    mapping(address => uint256) public governanceVotingPower;
    uint256 public totalGovernanceVotingPower; // Sum of all active voting power

    // Protocol parameters
    FeeParameters public feeParams;
    uint256 public constant MIN_MODEL_STAKE = 1000 * 10**18; // Example: 1000 Nexus Tokens (assuming 18 decimals)
    uint256 public constant MIN_VALIDATOR_STAKE = 500 * 10**18; // Example: 500 Nexus Tokens
    uint256 public constant MODEL_DEACTIVATION_COOLDOWN = 7 days; // Duration model's stake is locked after deactivation
    uint256 public constant VALIDATOR_DEREGISTER_COOLDOWN = 14 days; // Duration validator's stake is locked after deregistering
    uint256 public constant INFERENCE_SUBMISSION_WINDOW = 3 hours; // Time for validators to submit results
    uint256 public constant INFERENCE_CHALLENGE_WINDOW = 1 hours; // Time to challenge after submission window (post-submission deadline)
    uint256 public constant DEFAULT_REPUTATION = 1000; // Starting reputation score
    uint256 public constant GOVERNANCE_PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant GOVERNANCE_QUORUM_PERCENTAGE = 40; // 40% of total voting power needed for quorum
    uint256 public constant GOVERNANCE_MAJORITY_PERCENTAGE = 51; // 51% of votes must be 'for' to pass

    uint256 public totalProtocolFees; // Accumulated fees in NEXUS_TOKEN in the contract's balance
    mapping(address => uint256) private pendingRewards; // Tracks rewards claimable by address

    // --- Modifiers ---
    modifier onlyModelOwner(uint256 _modelId) {
        if (aiModels[_modelId].owner != msg.sender) {
            revert NotModelOwner(_modelId, msg.sender);
        }
        _;
    }

    modifier onlyValidator() {
        if (!isValidatorRegistered[msg.sender]) {
            revert NotValidator(msg.sender);
        }
        _;
    }

    modifier onlyActiveValidator() {
        if (!isValidatorRegistered[msg.sender] || validators[msg.sender].status != ValidatorStatus.Active) {
            revert ValidatorNotActive(msg.sender);
        }
        _;
    }

    // --- Constructor ---
    constructor(address _nexusTokenAddress) Ownable(msg.sender) {
        NEXUS_TOKEN = IERC20(_nexusTokenAddress);

        feeParams = FeeParameters({
            baseInferenceFee: 10 * 10**18,       // 10 NEXUS_TOKEN
            challengeFee: 50 * 10**18,           // 50 NEXUS_TOKEN
            validatorRewardRate: 1 * 10**18,     // 1 NEXUS_TOKEN per successful validation
            disputeResolutionFee: 20 * 10**18    // 20 NEXUS_TOKEN paid by challenger/loser
        });

        // Initialize total voting power with a base (e.g., owner's initial stake or fixed base)
        // In a real DAO, this would be tied to the NEXUS_TOKEN's total supply or specific governance tokens.
        // For simplicity, let's assume deployer gets some initial voting power to bootstrap.
        governanceVotingPower[msg.sender] = 1000 * 10**18;
        totalGovernanceVotingPower = 1000 * 10**18;
    }


    // --- I. Core Registries & Lifecycle Management ---

    /// @notice Registers a new AI model with its metadata and an initial staking deposit.
    /// @param _ipfsHash IPFS hash pointing to the model's details/binary.
    /// @param _modelName Name of the AI model.
    /// @param _description Description of the AI model.
    function registerAIModel(string calldata _ipfsHash, string calldata _modelName, string calldata _description)
        external
        nonReentrant
    {
        if (isModelOwnerRegistered[msg.sender]) {
            revert AlreadyRegisteredModel();
        }

        uint256 modelId = nextModelId++;
        aiModels[modelId] = AIModel({
            owner: msg.sender,
            ipfsHash: _ipfsHash,
            name: _modelName,
            description: _description,
            registrationTime: block.timestamp,
            status: ModelStatus.Active,
            totalInferences: 0,
            successfulInferences: 0,
            disputesWon: 0,
            disputesLost: 0,
            reputationScore: DEFAULT_REPUTATION,
            stakedAmount: 0,
            lastActivityTime: block.timestamp
        });
        modelIdByOwner[msg.sender] = modelId;
        isModelOwnerRegistered[msg.sender] = true;

        // Automatically stake minimum required amount
        _stake(msg.sender, MIN_MODEL_STAKE, modelId, EntityType.Model);
        
        emit AIModelRegistered(modelId, msg.sender, _ipfsHash, _modelName);
    }

    /// @notice Allows a model owner to update the metadata (IPFS hash, description) of their registered model.
    /// @param _modelId The ID of the model to update.
    /// @param _newIpfsHash The new IPFS hash for the model.
    /// @param _newDescription The new description for the model.
    function updateAIModelDetails(uint256 _modelId, string calldata _newIpfsHash, string calldata _newDescription)
        external
        onlyModelOwner(_modelId)
    {
        AIModel storage model = aiModels[_modelId];
        model.ipfsHash = _newIpfsHash;
        model.description = _newDescription;
        emit AIModelUpdated(_modelId, _newIpfsHash, _newDescription);
    }

    /// @notice Marks an AI model as inactive. Its stake remains locked for a cooldown period.
    /// @param _modelId The ID of the model to deactivate.
    function deactivateAIModel(uint256 _modelId)
        external
        onlyModelOwner(_modelId)
        nonReentrant
    {
        AIModel storage model = aiModels[_modelId];
        if (model.status != ModelStatus.Active) revert StatusAlreadySet();
        model.status = ModelStatus.Inactive;
        model.lastActivityTime = block.timestamp; // Cooldown starts now
        emit AIModelDeactivated(_modelId, msg.sender);
    }

    /// @notice Registers a new participant as an AI inference validator, requiring an initial staking deposit.
    /// @param _validatorName Name of the validator.
    function registerValidator(string calldata _validatorName)
        external
        nonReentrant
    {
        if (isValidatorRegistered[msg.sender]) {
            revert AlreadyRegisteredValidator();
        }

        validators[msg.sender] = Validator({
            name: _validatorName,
            status: ValidatorStatus.Active,
            registrationTime: block.timestamp,
            reputationScore: DEFAULT_REPUTATION,
            stakedAmount: 0,
            validatedJobs: 0,
            successfulValidations: 0,
            disputesWon: 0,
            disputesLost: 0,
            lastActiveTime: block.timestamp,
            deregisterCooldownEnd: 0
        });
        isValidatorRegistered[msg.sender] = true;

        // Automatically stake minimum required amount
        _stake(msg.sender, MIN_VALIDATOR_STAKE, 0, EntityType.Validator); // 0 is placeholder entityId for validator
        
        emit ValidatorRegistered(msg.sender, _validatorName);
    }

    /// @notice Allows a validator to toggle their active participation status for new validation jobs.
    /// @param _isActive True to activate, false to deactivate.
    function toggleValidatorActiveStatus(bool _isActive)
        external
        onlyValidator()
    {
        Validator storage validator = validators[msg.sender];
        if (_isActive && validator.status != ValidatorStatus.Active) {
            validator.status = ValidatorStatus.Active;
        } else if (!_isActive && validator.status == ValidatorStatus.Active) {
            validator.status = ValidatorStatus.Inactive;
        } else {
            revert StatusAlreadySet();
        }
        emit ValidatorStatusToggled(msg.sender, _isActive);
    }

    /// @notice Initiates the process of a validator exiting the network, locking their stake for a cooldown period.
    function deregisterValidator()
        external
        onlyValidator()
        nonReentrant
    {
        Validator storage validator = validators[msg.sender];
        if (validator.status == ValidatorStatus.Deregistering) revert StatusAlreadySet();
        validator.status = ValidatorStatus.Deregistering;
        validator.deregisterCooldownEnd = block.timestamp + VALIDATOR_DEREGISTER_COOLDOWN;
        emit ValidatorDeregistered(msg.sender);
    }


    // --- II. Decentralized Inference Validation & Dispute Resolution ---

    /// @notice Initiates a validation job for a given AI model's inference on specific input data. Requester pays a fee.
    /// @param _modelId The ID of the AI model to validate.
    /// @param _inputDataHash Hash of the input data used for inference.
    /// @param _paymentAmount The amount of NEXUS_TOKEN paid by the requester (must be at least feeParams.baseInferenceFee).
    function requestInferenceValidation(uint256 _modelId, bytes32 _inputDataHash, uint256 _paymentAmount)
        external
        nonReentrant
    {
        AIModel storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert InvalidEntityId();
        if (model.status != ModelStatus.Active) revert ModelNotActive(_modelId);
        if (_paymentAmount < feeParams.baseInferenceFee) revert InsufficientBalance(feeParams.baseInferenceFee, _paymentAmount);

        _transferFromSenderToProtocol(feeParams.baseInferenceFee);

        uint256 jobId = nextInferenceJobId++;
        inferenceJobs[jobId] = InferenceJob({
            modelId: _modelId,
            requester: msg.sender,
            inputDataHash: _inputDataHash,
            status: InferenceJobStatus.Pending,
            requestTime: block.timestamp,
            submissionDeadline: block.timestamp + INFERENCE_SUBMISSION_WINDOW,
            challengeDeadline: 0, // Set after initial submissions
            finalizationTime: 0,
            consensusOutputHash: bytes32(0),
            totalSubmissions: 0,
            validatorSubmissions: new mapping(address => bytes32),
            hasSubmitted: new mapping(address => bool),
            outputVoteCounts: new mapping(bytes32 => uint256),
            participatingValidators: new address[](0), // Initialize empty dynamic array
            disputeProposalId: 0
        });

        model.totalInferences = model.totalInferences.add(1);
        emit InferenceValidationRequested(jobId, _modelId, msg.sender, _inputDataHash, feeParams.baseInferenceFee);
    }

    /// @notice Allows registered and active validators to submit their computed/validated output hash for an open inference job.
    /// @param _jobId The ID of the inference job.
    /// @param _outputDataHash The hash of the validated output data.
    function submitInferenceResult(uint256 _jobId, bytes32 _outputDataHash)
        external
        onlyActiveValidator()
        nonReentrant
    {
        InferenceJob storage job = inferenceJobs[_jobId];
        if (job.status != InferenceJobStatus.Pending) revert InvalidJobStatus();
        if (block.timestamp > job.submissionDeadline) revert SubmissionWindowClosed();
        if (job.hasSubmitted[msg.sender]) revert AlreadySubmitted();
        if (_outputDataHash == bytes32(0)) revert InvalidOutputHash();

        job.validatorSubmissions[msg.sender] = _outputDataHash;
        job.hasSubmitted[msg.sender] = true;
        job.outputVoteCounts[_outputDataHash] = job.outputVoteCounts[_outputDataHash].add(1);
        job.totalSubmissions = job.totalSubmissions.add(1);
        job.participatingValidators.push(msg.sender); // Keep track for iteration

        validators[msg.sender].lastActiveTime = block.timestamp;
        
        emit InferenceResultSubmitted(_jobId, msg.sender, _outputDataHash);
    }

    /// @notice A user or validator can challenge the existing consensus (or a specific submission) for an inference job by providing an alternative output. Requires a challenge fee.
    /// @param _jobId The ID of the inference job to challenge.
    /// @param _challengerOutputHash The challenger's proposed correct output hash.
    function challengeInferenceResult(uint256 _jobId, bytes32 _challengerOutputHash)
        external
        nonReentrant
    {
        InferenceJob storage job = inferenceJobs[_jobId];
        if (job.status == InferenceJobStatus.Challenged || job.status == InferenceJobStatus.Finalized || job.status == InferenceJobStatus.DisputeResolved) {
            revert AlreadyChallenged();
        }
        if (block.timestamp <= job.submissionDeadline) { // Must be after submission window but before challenge window ends
            revert("Cannot challenge during submission window.");
        }
        if (block.timestamp > job.submissionDeadline.add(INFERENCE_CHALLENGE_WINDOW)) {
            revert ChallengeTooLate();
        }
        if (_challengerOutputHash == bytes32(0)) revert ChallengerOutputHashInvalid();

        _transferFromSenderToProtocol(feeParams.challengeFee);

        job.status = InferenceJobStatus.Challenged;
        // The challenger's hash can be stored for context, but dispute is resolved by governance
        // A governance proposal ID will link to this dispute.
        
        emit InferenceChallenged(_jobId, msg.sender, _challengerOutputHash);
    }

    /// @notice Finalizes an inference job once enough submissions are received and consensus is reached or timeout occurs. Distributes rewards.
    /// @param _jobId The ID of the inference job to finalize.
    function finalizeInferenceJob(uint256 _jobId)
        external
        nonReentrant
    {
        InferenceJob storage job = inferenceJobs[_jobId];
        if (job.status == InferenceJobStatus.Finalized || job.status == InferenceJobStatus.DisputeResolved) {
            revert JobAlreadyFinalized();
        }
        if (job.status == InferenceJobStatus.Challenged) {
            revert InDispute(); // Job is challenged, needs dispute resolution
        }
        if (block.timestamp < job.submissionDeadline) {
            revert SubmissionWindowClosed(); // Too early to finalize
        }
        if (job.totalSubmissions == 0) {
            revert NotEnoughSubmissions(); // No validator submitted, job might need cancellation or re-request
        }

        bytes32 highestVotedOutput = _getConsensusOutput(job);
        
        job.consensusOutputHash = highestVotedOutput;
        job.finalizationTime = block.timestamp;
        job.status = InferenceJobStatus.Finalized;

        uint256 totalRewards = 0;
        for (uint256 i = 0; i < job.participatingValidators.length; i++) {
            address validatorAddress = job.participatingValidators[i];
            if (job.validatorSubmissions[validatorAddress] == highestVotedOutput) {
                _distributeReward(validatorAddress, feeParams.validatorRewardRate);
                validators[validatorAddress].successfulValidations = validators[validatorAddress].successfulValidations.add(1);
                _updateReputation(validatorAddress, true); // True for positive update
                totalRewards = totalRewards.add(feeParams.validatorRewardRate);
            } else {
                _updateReputation(validatorAddress, false); // False for negative update
            }
            validators[validatorAddress].validatedJobs = validators[validatorAddress].validatedJobs.add(1);
        }

        aiModels[job.modelId].successfulInferences = aiModels[job.modelId].successfulInferences.add(1);
        
        emit InferenceJobFinalized(_jobId, highestVotedOutput, job.totalSubmissions, totalRewards);
    }
    
    /// @notice Governance or designated dispute resolvers propose the definitive correct output for a challenged job and identify validators who aligned with it.
    /// This function should ideally be called via a successful governance proposal as part of its `callData`.
    /// @param _jobId The ID of the inference job in dispute.
    /// @param _correctOutputHash The definitively correct output hash.
    /// @param _winningValidators Addresses of validators whose submissions matched the correct output.
    function proposeDisputeResolution(uint256 _jobId, bytes32 _correctOutputHash, address[] calldata _winningValidators)
        external
        onlyOwner // Temporarily onlyOwner; in a real system, only executable via governance
    {
        InferenceJob storage job = inferenceJobs[_jobId];
        if (job.status != InferenceJobStatus.Challenged) revert InDispute();

        job.consensusOutputHash = _correctOutputHash;
        job.finalizationTime = block.timestamp;
        job.status = InferenceJobStatus.DisputeResolved;

        uint256 totalRewards = 0;
        for (address validatorAddress : _winningValidators) {
            // Ensure validator exists and participated in this job
            if (isValidatorRegistered[validatorAddress] && job.hasSubmitted[validatorAddress]) {
                _distributeReward(validatorAddress, feeParams.validatorRewardRate.mul(2)); // Double reward for dispute win
                validators[validatorAddress].disputesWon = validators[validatorAddress].disputesWon.add(1);
                _updateReputation(validatorAddress, true);
                totalRewards = totalRewards.add(feeParams.validatorRewardRate.mul(2));
            }
        }

        // Penalize validators who submitted incorrect output and those not in _winningValidators
        for (uint224 i = 0; i < job.participatingValidators.length; i++) {
            address validatorAddress = job.participatingValidators[i];
            bool isWinner = false;
            for (uint j = 0; j < _winningValidators.length; j++) {
                if (validatorAddress == _winningValidators[j]) {
                    isWinner = true;
                    break;
                }
            }
            if (!isWinner && job.hasSubmitted[validatorAddress]) {
                _penalizeStake(validatorAddress, feeParams.validatorRewardRate); // Example penalty
                validators[validatorAddress].disputesLost = validators[validatorAddress].disputesLost.add(1);
                _updateReputation(validatorAddress, false);
            }
        }
        
        // Penalize the model owner if model output was definitively wrong
        // (This would be if the model's actual output didn't match the _correctOutputHash)
        // This requires storing the model's initial output for this specific job, or inferring.
        // For simplicity, we just increment dispute count and reduce reputation for the model.
        if (aiModels[job.modelId].owner != address(0) && aiModels[job.modelId].status == ModelStatus.Active) {
            aiModels[job.modelId].disputesLost = aiModels[job.modelId].disputesLost.add(1);
            _updateModelReputation(job.modelId, false);
        }

        emit DisputeResolutionProposed(0, _jobId, _correctOutputHash); // Dispute ID needs to be linked to a proposal system
    }

    /// @notice Allows DAO members to vote on a proposed dispute resolution.
    /// This function conceptually points to `voteOnGovernanceProposal`.
    /// @param _disputeId The ID of the dispute resolution proposal.
    /// @param _support True to vote for, false to vote against.
    function voteOnDisputeResolution(uint256 _disputeId, bool _support)
        external
    {
        revert("Use voteOnGovernanceProposal for dispute resolutions submitted as proposals.");
    }

    /// @notice Executes a passed dispute resolution.
    /// This function conceptually points to `executeGovernanceProposal`.
    /// @param _disputeId The ID of the dispute resolution proposal.
    function executeDisputeResolution(uint256 _disputeId)
        external
    {
        revert("Dispute resolution execution handled by executeGovernanceProposal.");
    }


    // --- III. Reputation & Staking Mechanics ---

    /// @notice Generic staking function for models or validators.
    /// @param _amount The amount of NEXUS_TOKEN to stake.
    /// @param _entityId The ID of the model (if EntityType.Model) or 0 (if EntityType.Validator).
    /// @param _entityType The type of entity staking (Model or Validator).
    function stake(uint256 _amount, uint256 _entityId, EntityType _entityType)
        public
        nonReentrant
    {
        _stake(msg.sender, _amount, _entityId, _entityType);
    }

    /// @notice Generic unstaking function, subject to lockup periods and reputation.
    /// @param _amount The amount of NEXUS_TOKEN to unstake.
    /// @param _entityId The ID of the model (if EntityType.Model) or 0 (if EntityType.Validator).
    /// @param _entityType The type of entity unstaking (Model or Validator).
    function unstake(uint256 _amount, uint256 _entityId, EntityType _entityType)
        public
        nonReentrant
    {
        if (_amount == 0) revert InvalidStakingAmount();
        
        if (_entityType == EntityType.Model) {
            AIModel storage model = aiModels[_entityId];
            if (model.owner != msg.sender) revert NotModelOwner(_entityId, msg.sender);
            if (model.stakedAmount < _amount) revert InsufficientStake(_amount, model.stakedAmount);
            if (model.status == ModelStatus.Active && model.stakedAmount.sub(_amount) < MIN_MODEL_STAKE) {
                revert MinimumStakeNotMet(MIN_MODEL_STAKE, model.stakedAmount.sub(_amount));
            }
            if (model.status == ModelStatus.Inactive && block.timestamp < model.lastActivityTime.add(MODEL_DEACTIVATION_COOLDOWN)) {
                revert UnstakeCooldownActive(model.lastActivityTime.add(MODEL_DEACTIVATION_COOLDOWN).sub(block.timestamp));
            }
            
            model.stakedAmount = model.stakedAmount.sub(_amount);
        } else if (_entityType == EntityType.Validator) {
            Validator storage validator = validators[msg.sender];
            if (validator.stakedAmount < _amount) revert InsufficientStake(_amount, validator.stakedAmount);
            if (validator.status == ValidatorStatus.Active && validator.stakedAmount.sub(_amount) < MIN_VALIDATOR_STAKE) {
                revert MinimumStakeNotMet(MIN_VALIDATOR_STAKE, validator.stakedAmount.sub(_amount));
            }
            if (validator.status == ValidatorStatus.Deregistering && block.timestamp < validator.deregisterCooldownEnd) {
                revert UnstakeCooldownActive(validator.deregisterCooldownEnd.sub(block.timestamp));
            }

            validator.stakedAmount = validator.stakedAmount.sub(_amount);
            governanceVotingPower[msg.sender] = governanceVotingPower[msg.sender].sub(_amount);
            totalGovernanceVotingPower = totalGovernanceVotingPower.sub(_amount);

            if (validator.status == ValidatorStatus.Deregistering && validator.stakedAmount == 0) {
                // Fully deregistered and stake withdrawn
                isValidatorRegistered[msg.sender] = false;
                delete validators[msg.sender]; // Clear validator data
            }
        } else {
            revert InvalidEntityId();
        }

        _transferProtocolToSender(_amount);
        emit Unstaked(msg.sender, _amount, _entityId, _entityType);
    }

    /// @notice Allows models and validators to claim accumulated rewards from successful validations/disputes and protocol fees.
    function claimRewards()
        external
        nonReentrant
    {
        uint256 availableRewards = pendingRewards[msg.sender];
        if (availableRewards == 0) revert NoRewardsAvailable();

        pendingRewards[msg.sender] = 0; // Reset rewards
        _transferProtocolToSender(availableRewards);
        
        emit RewardsClaimed(msg.sender, availableRewards);
    }

    /// @notice Retrieves the current reputation score of a validator or the owner of a model.
    /// @param _account The address of the validator or model owner.
    /// @return The reputation score.
    function getReputationScore(address _account)
        external
        view
        returns (uint256)
    {
        if (isValidatorRegistered[_account]) {
            return validators[_account].reputationScore;
        }
        if (isModelOwnerRegistered[_account]) {
            return aiModels[modelIdByOwner[_account]].reputationScore;
        }
        return 0; // Not a registered entity
    }

    /// @notice Checks the amount of rewards an account can claim.
    /// @param _account The address to check rewards for.
    /// @return The amount of claimable rewards.
    function getAvailableRewards(address _account)
        external
        view
        returns (uint256)
    {
        return pendingRewards[_account];
    }

    // --- IV. Data Attestation & Provenance ---

    /// @notice Allows data providers to officially attest to the provenance and integrity of a dataset, linking it to specific AI models that used or were trained on it.
    /// @param _dataHash Cryptographic hash of the dataset.
    /// @param _description Description of the dataset and its provenance.
    /// @param _linkedModelIds Array of model IDs that used or were trained on this data.
    function attestDataProvenance(bytes32 _dataHash, string calldata _description, uint256[] calldata _linkedModelIds)
        external
    {
        // Basic validation for linked models existence
        for (uint256 i = 0; i < _linkedModelIds.length; i++) {
            if (aiModels[_linkedModelIds[i]].owner == address(0)) {
                revert InvalidEntityId();
            }
        }

        uint256 attestationId = nextAttestationId++;
        dataAttestations[attestationId] = DataAttestation({
            attestor: msg.sender,
            dataHash: _dataHash,
            description: _description,
            linkedModelIds: _linkedModelIds,
            timestamp: block.timestamp
        });
        emit DataAttested(attestationId, msg.sender, _dataHash);
    }

    /// @notice Retrieves the details of a specific data attestation.
    /// @param _attestationId The ID of the attestation.
    /// @return The attestation details.
    function getAttestationDetails(uint256 _attestationId)
        external
        view
        returns (DataAttestation memory)
    {
        return dataAttestations[_attestationId];
    }


    // --- V. Protocol Governance & Utilities ---

    /// @notice Allows users with sufficient reputation/stake to propose changes to contract parameters or logic.
    /// @param _description A description of the proposal.
    /// @param _targetContract The address of the contract the proposal targets (often `address(this)` for self-governance).
    /// @param _calldata The encoded function call to be executed if the proposal passes.
    function submitGovernanceProposal(string calldata _description, address _targetContract, bytes calldata _calldata)
        external
    {
        // Require a minimum voting power to submit proposals to prevent spam
        if (governanceVotingPower[msg.sender] == 0) revert InsufficientVotingPower(); // Or a higher threshold

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            description: _description,
            targetContract: _targetContract,
            callData: _calldata,
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + GOVERNANCE_PROPOSAL_VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            state: ProposalState.Active,
            executed: false
        });
        emit GovernanceProposalSubmitted(proposalId, msg.sender, _description);
    }

    /// @notice Allows DAO members to vote on active governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote for, false to vote against.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support)
        external
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.creationTime == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.timestamp > proposal.votingDeadline) {
            revert VotingPeriodNotEnded(); // Voting period ended, proposal needs to be evaluated/executed
        }
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();
        
        uint256 voterPower = governanceVotingPower[msg.sender];
        if (voterPower == 0) revert InsufficientVotingPower();

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterPower);
        }
        proposal.hasVoted[msg.sender] = true;
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal that has met the required voting threshold and quorum.
    /// @param _proposalId The ID of the proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId)
        external
        nonReentrant
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.creationTime == 0) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp <= proposal.votingDeadline) revert VotingPeriodNotEnded();
        
        // Final evaluation of the proposal state
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes == 0) { // No votes cast, proposal fails
            proposal.state = ProposalState.Failed;
            revert ProposalNotSucceeded();
        }

        uint256 currentTotalVotingPower = totalGovernanceVotingPower; // Use cached value or calculate dynamically
        
        if (totalVotes.mul(100) < currentTotalVotingPower.mul(GOVERNANCE_QUORUM_PERCENTAGE).div(100) ||
            proposal.votesFor.mul(100) < totalVotes.mul(GOVERNANCE_MAJORITY_PERCENTAGE).div(100)) {
            proposal.state = ProposalState.Failed;
            revert ProposalNotSucceeded();
        }
        
        proposal.state = ProposalState.Succeeded;

        (bool success, ) = proposal.targetContract.call(proposal.callData);
        if (!success) revert("Proposal execution failed.");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Governance function to adjust the protocol's fee structure.
    /// This function should only be callable via a successful governance proposal.
    /// @param _inferenceFee New base inference fee.
    /// @param _challengeFee New challenge fee.
    /// @param _validatorRewardRate New reward rate per successful validation.
    /// @param _disputeResolutionFee New dispute resolution fee.
    function setProtocolFees(uint256 _inferenceFee, uint256 _challengeFee, uint256 _validatorRewardRate, uint256 _disputeResolutionFee)
        external
        onlyOwner // Temporarily onlyOwner; intended to be called by `executeGovernanceProposal`
    {
        feeParams = FeeParameters({
            baseInferenceFee: _inferenceFee,
            challengeFee: _challengeFee,
            validatorRewardRate: _validatorRewardRate,
            disputeResolutionFee: _disputeResolutionFee
        });
        emit ProtocolFeesSet(_inferenceFee, _challengeFee, _validatorRewardRate, _disputeResolutionFee);
    }

    /// @notice Allows the DAO treasury to withdraw accumulated protocol fees.
    /// This function should only be callable via a successful governance proposal.
    /// @param _amount The amount of fees to withdraw.
    function withdrawProtocolTreasury(uint256 _amount)
        external
        onlyOwner // Temporarily onlyOwner; intended to be called by `executeGovernanceProposal`
        nonReentrant
    {
        if (_amount == 0) revert InvalidStakingAmount();
        if (totalProtocolFees < _amount) revert NotEnoughBalance(_amount, totalProtocolFees);
        
        totalProtocolFees = totalProtocolFees.sub(_amount);
        _transferProtocolToSender(_amount);
        emit ProtocolTreasuryWithdrawn(msg.sender, _amount);
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to handle staking logic.
    function _stake(address _staker, uint256 _amount, uint256 _entityId, EntityType _entityType)
        internal
    {
        if (_amount == 0) revert InvalidStakingAmount();
        
        // Transfer tokens from staker to contract
        bool success = NEXUS_TOKEN.transferFrom(_staker, address(this), _amount);
        if (!success) revert TransferFailed();
        totalProtocolFees = totalProtocolFees.add(_amount); // Funds initially accrue here

        if (_entityType == EntityType.Model) {
            AIModel storage model = aiModels[_entityId];
            model.stakedAmount = model.stakedAmount.add(_amount);
            if (model.stakedAmount < MIN_MODEL_STAKE) {
                revert MinimumStakeNotMet(MIN_MODEL_STAKE, model.stakedAmount);
            }
        } else if (_entityType == EntityType.Validator) {
            Validator storage validator = validators[_staker];
            validator.stakedAmount = validator.stakedAmount.add(_amount);
            if (validator.stakedAmount < MIN_VALIDATOR_STAKE) {
                revert MinimumStakeNotMet(MIN_VALIDATOR_STAKE, validator.stakedAmount);
            }
            governanceVotingPower[_staker] = governanceVotingPower[_staker].add(_amount); // Stake contributes to voting power
            totalGovernanceVotingPower = totalGovernanceVotingPower.add(_amount);
        } else {
            revert InvalidEntityId();
        }
        
        emit Staked(_staker, _amount, _entityId, _entityType);
    }

    /// @dev Internal function to transfer tokens from protocol treasury to an address.
    function _transferProtocolToSender(uint256 _amount) internal {
        if (totalProtocolFees < _amount) revert NotEnoughBalance(_amount, totalProtocolFees); // Should not happen if callers check
        totalProtocolFees = totalProtocolFees.sub(_amount);
        bool success = NEXUS_TOKEN.transfer(msg.sender, _amount);
        if (!success) revert TransferFailed();
    }

    /// @dev Internal function to transfer tokens from sender to protocol treasury (e.g., for fees).
    function _transferFromSenderToProtocol(uint256 _amount) internal {
        bool success = NEXUS_TOKEN.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TransferFailed();
        totalProtocolFees = totalProtocolFees.add(_amount);
    }

    /// @dev Internal function to update a validator's reputation.
    function _updateReputation(address _validatorAddress, bool _isPositive) internal {
        Validator storage validator = validators[_validatorAddress];
        if (_isPositive) {
            validator.reputationScore = validator.reputationScore.add(10); // Example: +10 for success
        } else {
            if (validator.reputationScore > 5) { // Prevent score from going too low
                validator.reputationScore = validator.reputationScore.sub(5); // Example: -5 for failure
            } else {
                validator.reputationScore = 0; // Cap at 0
            }
        }
        emit ReputationUpdated(_validatorAddress, validator.reputationScore);
    }

    /// @dev Internal function to update a model's reputation.
    function _updateModelReputation(uint256 _modelId, bool _isPositive) internal {
        AIModel storage model = aiModels[_modelId];
        if (_isPositive) {
            model.reputationScore = model.reputationScore.add(5);
        } else {
            if (model.reputationScore > 2) {
                model.reputationScore = model.reputationScore.sub(2);
            } else {
                model.reputationScore = 0;
            }
        }
        emit ReputationUpdated(model.owner, model.reputationScore); // Emit for model owner's reputation
    }

    /// @dev Internal function to add rewards to a validator's pending rewards.
    function _distributeReward(address _validatorAddress, uint256 _amount) internal {
        pendingRewards[_validatorAddress] = pendingRewards[_validatorAddress].add(_amount);
    }

    /// @dev Internal function to penalize a validator's stake.
    function _penalizeStake(address _validatorAddress, uint256 _amount) internal {
        Validator storage validator = validators[_validatorAddress];
        uint256 penalty = _amount;
        if (validator.stakedAmount < penalty) {
            penalty = validator.stakedAmount; // Can't penalize more than staked
        }
        validator.stakedAmount = validator.stakedAmount.sub(penalty);
        totalProtocolFees = totalProtocolFees.add(penalty); // Penalized amount goes to protocol treasury
        governanceVotingPower[_validatorAddress] = governanceVotingPower[_validatorAddress].sub(penalty); // Reduce voting power
        totalGovernanceVotingPower = totalGovernanceVotingPower.sub(penalty);
    }

    /// @dev Internal helper to determine the consensus output from submissions.
    /// This is a simplified implementation. A robust one might handle ties differently (e.g., oldest winning, or requiring more votes).
    function _getConsensusOutput(InferenceJob storage job) internal view returns (bytes32) {
        bytes32 consensus = bytes32(0);
        uint256 maxVotes = 0;
        
        // Iterate through unique output hashes that received votes
        // Note: Iterating mappings directly is not possible. For a real system,
        // you would need to store all unique hashes submitted in a dynamic array
        // to iterate here, or use a more complex majority voting logic.
        // For this example, we assume `job.participatingValidators` combined with `job.validatorSubmissions`
        // allows for this logical iteration.
        
        // A more realistic approach would involve iterating through `job.participatingValidators`
        // and then checking their submission via `job.validatorSubmissions[validatorAddress]`
        // and incrementing counts in a temporary local map.
        
        // Example simplified logic (not efficient or fully correct for mapping iteration):
        if (job.participatingValidators.length > 0) {
            mapping(bytes32 => uint256) memory tempOutputVoteCounts;
            for (uint i = 0; i < job.participatingValidators.length; i++) {
                address validatorAddr = job.participatingValidators[i];
                bytes32 submittedHash = job.validatorSubmissions[validatorAddr];
                tempOutputVoteCounts[submittedHash]++;
                if (tempOutputVoteCounts[submittedHash] > maxVotes) {
                    maxVotes = tempOutputVoteCounts[submittedHash];
                    consensus = submittedHash;
                }
            }
        }
        return consensus;
    }
}

```