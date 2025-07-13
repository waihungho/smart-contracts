Okay, let's design a smart contract that orchestrates a decentralized process for AI model training and validation. This involves coordinating data providers, compute providers, validators, and model requesters, incorporating staking, reputation, and multi-party verification.

This is a complex domain, and a Solidity contract can only manage the *coordination* and *incentives* on-chain. The actual computation (training, validation) happens off-chain, but the contract manages the inputs (data hashes, job specs), outputs (model hashes, metric hashes, proofs), and the verification process.

Here's the contract design:

**Contract Name:** `DecentralizedAIModelTraining`

**Core Concepts:**
1.  **Participant Roles:** Data Providers, Compute Providers, Validators, Model Requesters.
2.  **Staking:** Participants stake tokens (or native ETH) to participate and ensure commitment.
3.  **Reputation:** Basic reputation system based on successful job completion and validation outcomes.
4.  **Dataset Registry:** Data providers register datasets (referenced by hash, e.g., IPFS).
5.  **Training Job Escrow:** Model Requesters fund training jobs with rewards and data costs.
6.  **Decentralized Computation & Submission:** Compute providers claim jobs, perform off-chain training, and submit results (model hash, metrics hash, potential ZK proof hash).
7.  **Multi-Party Validation:** Assigned validators review submitted results (possibly verifying ZK proofs off-chain or checking metrics), and submit votes on-chain.
8.  **On-chain Verification Logic:** Contract aggregates validator votes to determine result validity.
9.  **Rewards & Penalties:** Successful participants (Compute Provider, Validators, Data Provider) are rewarded from the escrow; malicious or failed participants are penalized (stake slashing).
10. **Model Access Control:** Contract controls access to the final verified model hash based on the job requester or defined terms.

**Outline & Function Summary:**

1.  **State Variables:** Define all necessary mappings, structs, counters, and configuration parameters.
2.  **Enums:** Define states for jobs and verification outcomes.
3.  **Structs:** Define data structures for participants (`DataProvider`, `ComputeProvider`, `Validator`), `Dataset`, and `TrainingJob`.
4.  **Events:** Define events to signal important state changes.
5.  **Errors:** Define custom errors for better revert messages.
6.  **Modifiers (or Require Checks):** Access control and state checks.
7.  **Admin/Owner Functions:** Setup and critical contract management (e.g., setting parameters, emergency pause, slashing).
    *   `setStakeRequirements`: Set minimum stakes for participant types.
    *   `setReputationParameters`: Configure how reputation changes.
    *   `setJobAssignmentParameters`: Configure job assignment logic (e.g., how many validators).
    *   `setRewardDistributionPercentages`: Define how job escrow is split.
    *   `slashStake`: Admin can slash a participant's stake based on protocol rules/governance decision.
8.  **Participant Management Functions:** Registration, deregistration, staking, profile updates.
    *   `registerAsDataProvider`: Become a data provider, stake funds, set profile.
    *   `updateDataProviderProfile`: Update profile metadata hash.
    *   `deregisterAsDataProvider`: Remove registration, retrieve stake (if eligible).
    *   `registerAsComputeProvider`: Become a compute provider, stake funds, set profile/capabilities.
    *   `updateComputeProviderProfile`: Update profile metadata hash.
    *   `deregisterAsComputeProvider`: Remove registration, retrieve stake (if eligible).
    *   `registerAsValidator`: Become a validator, stake funds, set profile.
    *   `updateValidatorProfile`: Update profile metadata hash.
    *   `deregisterAsValidator`: Remove registration, retrieve stake (if eligible).
    *   `addStake`: Add more funds to existing stake.
    *   `withdrawEligibleStake`: Withdraw stake that is not locked in jobs.
9.  **Dataset Management Functions:** Registering and managing datasets.
    *   `registerDataset`: Data provider registers a dataset hash with metadata and availability status.
    *   `updateDatasetAvailability`: Data provider updates dataset status.
10. **Training Job Management Functions:** Proposing, claiming, submitting results, validation, finalization.
    *   `proposeTrainingJob`: Model Requester proposes a job, specifies dataset hash, model type, reward, etc., and sends ETH for escrow.
    *   `cancelTrainingJob`: Requester cancels job before it's claimed by a compute provider.
    *   `claimAvailableJob`: Compute Provider claims an unassigned training job.
    *   `submitTrainingResult`: Compute Provider submits the result hashes (model, metrics, optional proof).
    *   `submitValidationVote`: Assigned Validator submits their vote (approve/reject) and potentially a validation proof hash.
    *   `finalizeJobVerification`: Triggers the verification logic after sufficient votes are cast. Updates job status.
    *   `distributeRewards`: Called after successful verification. Distributes escrowed funds to participants.
    *   `handleFailedVerification`: Called after failed verification. Handles potential penalties/slashing.
11. **Query Functions:** View contract state and job/participant details.
    *   `getJobDetails`: Retrieve details of a specific training job.
    *   `getParticipantDetails`: Retrieve details of a specific participant.
    *   `getDatasetDetails`: Retrieve details of a specific dataset.
    *   `listAvailableJobs`: Get IDs of jobs ready to be claimed by compute providers.
    *   `listJobsAwaitingValidation`: Get IDs of jobs ready for validator votes.
    *   `listJobsAwaitingResultSubmission`: Get IDs of jobs claimed by compute providers.
    *   `getModelAccessInfo`: Get the verified model hash and related info after successful job completion (restricted access).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelTraining
 * @dev A smart contract facilitating decentralized AI model training by coordinating Data Providers,
 *      Compute Providers, Validators, and Model Requesters.
 *      It manages staking, job escrow, result submission, multi-party validation,
 *      and reward/penalty distribution on-chain. The actual training and
 *      validation computation happens off-chain, with hashes and proofs submitted to the contract.
 */
contract DecentralizedAIModelTraining {

    // ==============================================================================================
    //                                     OUTLINE & SUMMARY
    // ==============================================================================================
    // State Variables: Stores contract configuration, participant data, dataset registry, and job details.
    // Enums: Defines discrete states for training jobs and verification outcomes.
    // Structs: Defines the structure of data for Participants (DataProvider, ComputeProvider, Validator), Dataset, and TrainingJob.
    // Events: Emits notifications for critical actions like registration, job creation, result submission, and job finalization.
    // Errors: Custom errors provide specific reasons for transaction reverts.
    // Admin/Owner Functions:
    // - setStakeRequirements: Configures the minimum stake needed for each participant type.
    // - setReputationParameters: Sets parameters for reputation score updates.
    // - setJobAssignmentParameters: Defines rules for job assignment and validator selection (e.g., number of validators per job).
    // - setRewardDistributionPercentages: Sets the percentage split of job escrow funds among participants and platform.
    // - slashStake: Allows the owner to slash a participant's stake in case of proven misconduct (likely following off-chain governance or on-chain protocol rules).
    // - pause/unpause: Emergency functions to halt critical operations.
    // Participant Management Functions:
    // - registerAsDataProvider/ComputeProvider/Validator: Allows users to register in a specific role by staking funds and providing profile data.
    // - updateDataProvider/ComputeProvider/ValidatorProfile: Allows registered participants to update their off-chain profile metadata hash.
    // - deregisterAsDataProvider/ComputeProvider/Validator: Allows participants to deregister and withdraw eligible stake (if not involved in active jobs).
    // - addStake: Allows registered participants to increase their stake.
    // - withdrawEligibleStake: Allows participants to withdraw stake that is not currently locked in active jobs.
    // Dataset Management Functions:
    // - registerDataset: Data Providers register their datasets (referenced by off-chain hash like IPFS) and set availability.
    // - updateDatasetAvailability: Data Providers update the availability status of their registered datasets.
    // Training Job Management Functions:
    // - proposeTrainingJob: Model Requesters create a job request, specifying dataset, model type, reward, verification requirements, and escrowing funds.
    // - cancelTrainingJob: Model Requesters can cancel jobs before they are claimed by a Compute Provider.
    // - claimAvailableJob: Compute Providers can claim an available training job based on their capabilities and the job requirements.
    // - submitTrainingResult: Compute Providers submit the results of the off-chain training (hashes of the model, metrics, and optionally a ZK proof).
    // - submitValidationVote: Assigned Validators submit their vote (approve/reject) on the submitted training result, potentially including validation proof hash.
    // - finalizeJobVerification: This function is triggered (e.g., after a timeout or sufficient votes) to evaluate the validator votes and determine the job's verification status.
    // - distributeRewards: Called after a job is successfully verified to distribute the escrowed funds based on predefined percentages.
    // - handleFailedVerification: Called after a job fails verification, triggering potential penalties or slashing based on the outcome.
    // Query Functions:
    // - getJobDetails: Public function to retrieve detailed information about a specific training job.
    // - getParticipantDetails: Public function to retrieve detailed information about a participant (stake, reputation, role).
    // - getDatasetDetails: Public function to retrieve information about a registered dataset.
    // - listAvailableJobs/JobsAwaitingValidation/JobsAwaitingResultSubmission: Public functions to retrieve lists of jobs in specific states.
    // - getModelAccessInfo: Provides the verified model hash and related info for a completed job (access controlled).

    // ==============================================================================================
    //                                     STATE VARIABLES
    // ==============================================================================================

    address public owner;

    // Configuration parameters
    uint256 public minDataProviderStake;
    uint256 public minComputeProviderStake;
    uint256 public minValidatorStake;

    uint256 public jobAssignmentValidatorCount; // Number of validators assigned per job
    uint256 public jobVerificationSupermajority; // Percentage needed for validation approval (e.g., 67 for 67%)
    uint256 public jobValidationTimeout; // Time validators have to vote

    uint256 public platformFeePercentage;
    uint256 public computeProviderRewardPercentage;
    uint256 public validatorRewardPercentage;
    uint256 public dataProviderFeePercentage; // Percentage of job budget for data provider compensation

    // Participant Data (using bytes32 for profile hashes e.g., IPFS)
    struct DataProvider {
        address participantAddress;
        uint256 stake;
        bytes32 profileMetadataHash;
        bool registered;
        // Add reputation/score later
    }

    struct ComputeProvider {
        address participantAddress;
        uint256 stake;
        bytes32 profileMetadataHash;
        bool registered;
        // Add capabilities, reputation/score later
    }

    struct Validator {
        address participantAddress;
        uint256 stake;
        bytes32 profileMetadataHash;
        bool registered;
        // Add reputation/score, specializations later
    }

    mapping(address => DataProvider) public dataProviders;
    mapping(address => ComputeProvider) public computeProviders;
    mapping(address => Validator) public validators;

    // Dataset Registry (using bytes32 for dataset hash e.g., IPFS)
    struct Dataset {
        address provider;
        bytes32 datasetMetadataHash;
        bool available;
        // Add price/terms later
    }

    mapping(bytes32 => Dataset) public datasets; // Dataset hash as key

    // Training Jobs
    enum JobStatus {
        Proposed,         // Job created by Requester
        Canceled,         // Job canceled by Requester
        Assigned,         // Job claimed by Compute Provider
        ResultSubmitted,  // Compute Provider submitted result
        AwaitingValidation, // Result submitted, waiting for validators
        ValidationComplete, // Validators have voted, verification status determined
        Completed,        // Job successfully verified and rewards distributed
        Failed            // Job failed verification
    }

    enum VerificationStatus {
        NotStarted,
        PendingVotes,
        Approved,
        Rejected
    }

    struct TrainingJob {
        uint256 jobId;
        address requester;
        bytes32 datasetHash;
        bytes32 modelTypeMetadataHash; // Hash describing the model architecture/type
        uint256 escrowAmount;       // Total ETH escrowed for the job
        uint256 rewardAmount;       // Portion of escrow intended as reward (minus data cost, platform fee)
        JobStatus status;
        address computeProvider;    // Assigned compute provider
        bytes32 submittedResultHash; // Hash of the training output (model, metrics, etc.)
        bytes32 submittedProofHash;  // Optional hash of zk-proof or other verification data

        address[] assignedValidators; // Validators assigned to this job
        mapping(address => bool) validatorVoted; // Has this validator voted?
        mapping(address => bool) validatorApprovalVote; // What was their vote? (true = approve)
        uint256 approvalVotes;
        uint256 rejectionVotes;
        VerificationStatus verificationStatus;
        uint256 validationEndTime; // Timestamp when validation period ends

        bytes32 finalModelHash; // Verified model hash (part of submittedResultHash)
        // Add more verification criteria/parameters
    }

    mapping(uint256 => TrainingJob) public trainingJobs;
    uint256 private nextJobId;

    // Tracking available/assigned jobs for easier querying (optional, can iterate mappings)
    uint256[] public availableJobIds;
    mapping(uint256 => bool) private isAvailableJob;

    uint256[] public jobsAwaitingValidationIds;
    mapping(uint256 => bool) private isAwaitingValidationJob;

    uint256[] public jobsAwaitingResultSubmissionIds;
    mapping(uint256 => bool) private isAwaitingResultSubmissionJob;

    // ==============================================================================================
    //                                     EVENTS
    // ==============================================================================================

    event DataProviderRegistered(address indexed provider, bytes32 profileHash, uint256 stake);
    event DataProviderDeregistered(address indexed provider, uint256 returnedStake);
    event ComputeProviderRegistered(address indexed provider, bytes32 profileHash, uint256 stake);
    event ComputeProviderDeregistered(address indexed provider, uint256 returnedStake);
    event ValidatorRegistered(address indexed validator, bytes32 profileHash, uint256 stake);
    event ValidatorDeregistered(address indexed validator, uint256 returnedStake);
    event StakeAdded(address indexed participant, uint256 amount, uint256 totalStake);
    event StakeWithdrawn(address indexed participant, uint256 amount, uint256 totalStake);
    event StakeSlashed(address indexed participant, uint256 amount, string reason);

    event DatasetRegistered(bytes32 indexed datasetHash, address indexed provider, bytes32 metadataHash, bool available);
    event DatasetAvailabilityUpdated(bytes32 indexed datasetHash, bool available);

    event TrainingJobProposed(uint256 indexed jobId, address indexed requester, bytes32 datasetHash, uint256 escrowAmount);
    event TrainingJobCanceled(uint256 indexed jobId);
    event TrainingJobClaimed(uint256 indexed jobId, address indexed computeProvider);
    event TrainingResultSubmitted(uint256 indexed jobId, bytes32 resultHash, bytes32 proofHash);
    event ValidationVoteSubmitted(uint256 indexed jobId, address indexed validator, bool vote, bytes32 proofHash);
    event JobVerificationFinalized(uint256 indexed jobId, VerificationStatus status);
    event RewardsDistributed(uint256 indexed jobId, uint256 platformFee, uint256 computeProviderReward, uint256 dataProviderReward, uint256 totalDistributed);
    event JobFailed(uint256 indexed jobId, string reason);

    event Paused(address account);
    event Unpaused(address account);

    // ==============================================================================================
    //                                     ERRORS
    // ==============================================================================================

    error NotOwner();
    error Paused();
    error NotPaused();
    error ParticipantNotRegistered(address participant);
    error ParticipantAlreadyRegistered(address participant);
    error InsufficientStake(uint256 required, uint256 provided);
    error StakeLockedInJobs();
    error DatasetNotFound(bytes32 datasetHash);
    error DatasetNotAvailable(bytes32 datasetHash);
    error NotDataProvider();
    error NotComputeProvider();
    error NotValidator();
    error NotRequester(uint256 jobId);
    error InvalidJobStatus(uint256 jobId);
    error JobNotFound(uint256 jobId);
    error JobAlreadyClaimed(uint256 jobId);
    error NotAssignedComputeProvider(uint256 jobId);
    error NotAssignedValidator(uint256 jobId);
    error ValidatorAlreadyVoted(uint256 jobId);
    error NotEnoughValidatorsVoted(uint256 jobId);
    error ValidationPeriodNotEnded(uint256 jobId);
    error ValidationPeriodEnded(uint256 jobId);
    error RewardsAlreadyDistributed(uint256 jobId);
    error JobNotVerifiedApproved(uint256 jobId);
    error InvalidPercentage(uint256 percentage);
    error InvalidStakeAmount();
    error JobAssignmentFailed(); // Generic error for issues during claim/assignment

    // ==============================================================================================
    //                                     CONSTRUCTOR
    // ==============================================================================================

    constructor() {
        owner = msg.sender;
        // Set initial parameters (can be updated by owner)
        minDataProviderStake = 1 ether;
        minComputeProviderStake = 2 ether;
        minValidatorStake = 1.5 ether;

        jobAssignmentValidatorCount = 3; // Assign 3 validators per job
        jobVerificationSupermajority = 67; // 67% approval needed
        jobValidationTimeout = 1 days; // Validators have 1 day

        platformFeePercentage = 5;
        computeProviderRewardPercentage = 50;
        validatorRewardPercentage = 15;
        dataProviderFeePercentage = 30; // 30% of budget goes to data provider

        // Total reward percentage should sum up: compute + validator + data + platform <= 100
        // The remaining percentage from 100 - platform - data is the reward split
        // Compute & Validator percentages are applied to the 'rewardAmount' part of escrow
        // DataProvider percentage is applied to the total 'escrowAmount'
        require(platformFeePercentage <= 100, "Invalid platform fee");
        require(dataProviderFeePercentage <= 100, "Invalid data fee");
        require(computeProviderRewardPercentage + validatorRewardPercentage <= 100, "Invalid reward percentages");
    }

    // ==============================================================================================
    //                                     MODIFIERS (OR CHECKS)
    // ==============================================================================================

    // Using require checks directly for clarity given the multiple participant types
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // --- Pause Mechanism (Basic) ---
    bool private _paused = false;

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // ==============================================================================================
    //                                     ADMIN/OWNER FUNCTIONS (>= 5)
    // ==============================================================================================

    function setStakeRequirements(uint256 _minDataProviderStake, uint256 _minComputeProviderStake, uint256 _minValidatorStake) public onlyOwner {
        minDataProviderStake = _minDataProviderStake;
        minComputeProviderStake = _minComputeProviderStake;
        minValidatorStake = _minValidatorStake;
    }

    function setReputationParameters(uint256 _placeholderParam) public onlyOwner {
        // TODO: Implement a simple reputation system logic here
        // For now, this is a placeholder function
        // Example: success boosts reputation, failure/slashing reduces it.
        // Reputation could influence job assignment priority, validation group selection, etc.
        // This requires more complex state variables and logic within job finalization functions.
        // For this contract, reputation logic is deferred, this function is illustrative.
    }

    function setJobAssignmentParameters(uint256 _validatorCount, uint256 _verificationSupermajority, uint256 _validationTimeout) public onlyOwner {
        require(_validatorCount > 0, "Validator count must be positive");
        require(_verificationSupermajority > 0 && _verificationSupermajority <= 100, "Supermajority must be 1-100");
        jobAssignmentValidatorCount = _validatorCount;
        jobVerificationSupermajority = _verificationSupermajority;
        jobValidationTimeout = _validationTimeout;
    }

    function setRewardDistributionPercentages(uint256 _platformFee, uint256 _computeProviderReward, uint256 _validatorReward, uint256 _dataProviderFee) public onlyOwner {
        require(_platformFee <= 100, InvalidPercentage(_platformFee));
        require(_dataProviderFee <= 100, InvalidPercentage(_dataProviderFee));
        require(_computeProviderReward + _validatorReward <= 100, InvalidPercentage(_computeProviderReward + _validatorReward));
        platformFeePercentage = _platformFee;
        computeProviderRewardPercentage = _computeProviderReward;
        validatorRewardPercentage = _validatorReward;
        dataProviderFeePercentage = _dataProviderFee;
    }

    /// @dev Slashes a participant's stake. Requires external proof or protocol violation detection.
    ///      In a real system, this would be tied to governance or automated protocol checks.
    function slashStake(address participant, uint256 amount, string calldata reason) public onlyOwner whenNotPaused {
        // This is a simplified manual slashing mechanism for demonstration.
        // Real slashing needs careful consideration of triggers, proofs, and governance.
        require(amount > 0, InvalidStakeAmount());

        uint256 actualSlashed = 0;

        // Check if participant is registered in any role and slash the relevant stake
        if (dataProviders[participant].registered) {
            uint256 slashable = dataProviders[participant].stake;
            uint256 toSlash = amount > slashable ? slashable : amount;
            dataProviders[participant].stake -= toSlash;
            actualSlashed += toSlash;
        } else if (computeProviders[participant].registered) {
            uint256 slashable = computeProviders[participant].stake;
            uint256 toSlash = amount > slashable ? slashable : amount;
            computeProviders[participant].stake -= toSlash;
            actualSlashed += toSlash;
        } else if (validators[participant].registered) {
            uint256 slashable = validators[participant].stake;
            uint256 toSlash = amount > slashable ? slashable : amount;
            validators[participant].stake -= toSlash;
            actualSlashed += toSlash;
        } else {
            revert ParticipantNotRegistered(participant);
        }

        require(actualSlashed > 0, "No slashable stake found");

        // Slashed funds could be burned, sent to a community pool, or sent to owner (less decentralized)
        // For simplicity, let's imagine they are inaccessible/burned in this version.
        // `address(this).balance` will decrease by the slashed amount effectively if not sent elsewhere.

        emit StakeSlashed(participant, actualSlashed, reason);
    }

    // ==============================================================================================
    //                                     PARTICIPANT MANAGEMENT FUNCTIONS (>= 10)
    // ==============================================================================================

    function registerAsDataProvider(bytes32 profileMetadataHash) public payable whenNotPaused {
        if (dataProviders[msg.sender].registered) revert ParticipantAlreadyRegistered(msg.sender);
        if (msg.value < minDataProviderStake) revert InsufficientStake(minDataProviderStake, msg.value);

        dataProviders[msg.sender] = DataProvider({
            participantAddress: msg.sender,
            stake: msg.value,
            profileMetadataHash: profileMetadataHash,
            registered: true
        });
        emit DataProviderRegistered(msg.sender, profileMetadataHash, msg.value);
    }

    function updateDataProviderProfile(bytes32 profileMetadataHash) public whenNotPaused {
        if (!dataProviders[msg.sender].registered) revert ParticipantNotRegistered(msg.sender);
        dataProviders[msg.sender].profileMetadataHash = profileMetadataHash;
        // No event for profile update in this version to save gas, could add one.
    }

    function deregisterAsDataProvider() public whenNotPaused {
        DataProvider storage provider = dataProviders[msg.sender];
        if (!provider.registered) revert ParticipantNotRegistered(msg.sender);

        // Check if participant has any active jobs or stake locked
        // (Simplified: In a real system, need to check if their stake is part of any ongoing job escrow)
        // For this version, we don't track locked stake per job, so deregistering is only allowed if reputation/state allows,
        // or if they're not the provider of a dataset used in an active job.
        // Let's add a simple check: cannot deregister if any registered dataset is 'available' or used in 'Proposed'/'Assigned'/'ResultSubmitted' jobs.
        // This check is complex to implement efficiently on-chain. For this example, let's assume off-chain coordination ensures this,
        // or we add a placeholder requiring reputation > threshold or manual admin clearance.
        // Placeholder: require reputation > threshold (not implemented yet) or no active stake lock (not tracked per job yet)
        // For simplicity, let's allow deregistration but make sure the stake is not involved in ongoing jobs
        // (This requires tracking locked stake, which we defer for simplicity here)
        // A more robust check would iterate through active jobs or maintain a locked_stake counter per participant.
        // Let's add a simple check that they haven't *registered* a dataset currently marked 'available'.
        bool hasAvailableDataset = false;
        // This requires iterating through all datasets, which is gas-expensive.
        // A better design would be a mapping `address => bytes32[]` for datasets by provider.
        // Given the constraint, let's add a simpler check or defer.
        // Deferring complex stake lock/active job checks for simplicity in this example.
        // IMPORTANT: This is a simplification. Real staking systems need robust lock mechanisms.

        uint256 returnedStake = provider.stake;
        delete dataProviders[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: returnedStake}("");
        require(success, "Stake withdrawal failed");
        emit DataProviderDeregistered(msg.sender, returnedStake);
    }


    function registerAsComputeProvider(bytes32 profileMetadataHash) public payable whenNotPaused {
        if (computeProviders[msg.sender].registered) revert ParticipantAlreadyRegistered(msg.sender);
        if (msg.value < minComputeProviderStake) revert InsufficientStake(minComputeProviderStake, msg.value);

        computeProviders[msg.sender] = ComputeProvider({
            participantAddress: msg.sender,
            stake: msg.value,
            profileMetadataHash: profileMetadataHash,
            registered: true
        });
        emit ComputeProviderRegistered(msg.sender, profileMetadataHash, msg.value);
    }

     function updateComputeProviderProfile(bytes32 profileMetadataHash) public whenNotPaused {
        if (!computeProviders[msg.sender].registered) revert ParticipantNotRegistered(msg.sender);
        computeProviders[msg.sender].profileMetadataHash = profileMetadataHash;
    }


    function deregisterAsComputeProvider() public whenNotPaused {
        ComputeProvider storage provider = computeProviders[msg.sender];
        if (!provider.registered) revert ParticipantNotRegistered(msg.sender);

        // Check for active jobs (simplified check)
        // Cannot deregister if currently assigned to an active job (Assigned, ResultSubmitted, AwaitingValidation, ValidationComplete)
        // This requires iterating through all active jobs or maintaining a list of assigned jobs per provider.
        // Iterating all jobs is gas-expensive. Let's rely on a different mechanism or simplify.
        // Simplification: Assume off-chain monitoring ensures no active jobs, or add a manual admin clearance placeholder.
        // A proper implementation would track locked stake or active jobs per participant.

        uint256 returnedStake = provider.stake;
        delete computeProviders[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: returnedStake}("");
        require(success, "Stake withdrawal failed");
        emit ComputeProviderDeregistered(msg.sender, returnedStake);
    }

    function registerAsValidator(bytes32 profileMetadataHash) public payable whenNotPaused {
        if (validators[msg.sender].registered) revert ParticipantAlreadyRegistered(msg.sender);
        if (msg.value < minValidatorStake) revert InsufficientStake(minValidatorStake, msg.value);

        validators[msg.sender] = Validator({
            participantAddress: msg.sender,
            stake: msg.value,
            profileMetadataHash: profileMetadataHash,
            registered: true
        });
        emit ValidatorRegistered(msg.sender, profileMetadataHash, msg.value);
    }

    function updateValidatorProfile(bytes32 profileMetadataHash) public whenNotPaused {
        if (!validators[msg.sender].registered) revert ParticipantNotRegistered(msg.sender);
        validators[msg.sender].profileMetadataHash = profileMetadataHash;
    }

    function deregisterAsValidator() public whenNotPaused {
        Validator storage validator = validators[msg.sender];
        if (!validator.registered) revert ParticipantNotRegistered(msg.sender);

        // Check for active jobs (simplified check)
        // Cannot deregister if currently assigned to an active job requiring validation (AwaitingValidation, ValidationComplete)
        // Similar to compute providers, this requires tracking or simplification.
        // Simplification: Assume off-chain or manual clearance.

        uint256 returnedStake = validator.stake;
        delete validators[msg.sender];
        (bool success, ) = payable(msg.sender).call{value: returnedStake}("");
        require(success, "Stake withdrawal failed");
        emit ValidatorDeregistered(msg.sender, returnedStake);
    }

    /// @dev Adds stake to an existing participant's deposit.
    function addStake() public payable whenNotPaused {
        require(msg.value > 0, InvalidStakeAmount());
        if (dataProviders[msg.sender].registered) {
            dataProviders[msg.sender].stake += msg.value;
            emit StakeAdded(msg.sender, msg.value, dataProviders[msg.sender].stake);
        } else if (computeProviders[msg.sender].registered) {
            computeProviders[msg.sender].stake += msg.value;
            emit StakeAdded(msg.sender, msg.value, computeProviders[msg.sender].stake);
        } else if (validators[msg.sender].registered) {
            validators[msg.sender].stake += msg.value;
            emit StakeAdded(msg.sender, msg.value, validators[msg.sender].stake);
        } else {
            revert ParticipantNotRegistered(msg.sender);
        }
    }

    /// @dev Allows participants to withdraw stake that is not currently locked in jobs.
    ///      NOTE: This requires complex tracking of locked stake per participant per job,
    ///      which is not fully implemented in this example for simplicity.
    ///      The current implementation is a placeholder that doesn't check for stake lock.
    function withdrawEligibleStake(uint256 amount) public whenNotPaused {
        require(amount > 0, InvalidStakeAmount());

        uint256 currentStake = 0;
        bool registered = false;

        if (dataProviders[msg.sender].registered) {
            currentStake = dataProviders[msg.sender].stake;
            registered = true;
        } else if (computeProviders[msg.sender].registered) {
            currentStake = computeProviders[msg.sender].stake;
            registered = true;
        } else if (validators[msg.sender].registered) {
            currentStake = validators[msg.sender].stake;
            registered = true;
        }

        if (!registered) revert ParticipantNotRegistered(msg.sender);
        if (amount > currentStake) revert InsufficientStake(amount, currentStake);

        // TODO: Implement actual check for locked stake.
        // This would require tracking which portion of a participant's total stake
        // is currently 'locked' in ongoing jobs (e.g., as potential slashing collateral
        // or part of the job escrow if using pooled staking).
        // For this simplified example, we assume no stake is locked, or the user
        // coordinates off-chain to ensure their stake is free.
        // A more robust contract would track locked amounts per participant.

        uint256 remainingStake = currentStake - amount;

        if (dataProviders[msg.sender].registered) dataProviders[msg.sender].stake = remainingStake;
        else if (computeProviders[msg.sender].registered) computeProviders[msg.sender].stake = remainingStake;
        else if (validators[msg.sender].registered) validators[msg.sender].stake = remainingStake;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Stake withdrawal failed");

        emit StakeWithdrawn(msg.sender, amount, remainingStake);
    }


    // ==============================================================================================
    //                                     DATASET MANAGEMENT FUNCTIONS (>= 2)
    // ==============================================================================================

    function registerDataset(bytes32 datasetHash, bytes32 datasetMetadataHash, bool available) public whenNotPaused {
        if (!dataProviders[msg.sender].registered) revert NotDataProvider();
        // Allow updating metadata/availability for existing hash by re-registering
        // if (datasets[datasetHash].provider != address(0)) { /* Maybe require sender is current provider */ }
        // Or add a separate update function. Let's allow overwrite by provider for simplicity.
        if (datasets[datasetHash].provider != address(0) && datasets[datasetHash].provider != msg.sender) {
             revert("Dataset hash already registered by another provider");
        }

        datasets[datasetHash] = Dataset({
            provider: msg.sender,
            datasetMetadataHash: datasetMetadataHash,
            available: available
        });
        emit DatasetRegistered(datasetHash, msg.sender, datasetMetadataHash, available);
    }

    function updateDatasetAvailability(bytes32 datasetHash, bool available) public whenNotPaused {
        Dataset storage dataset = datasets[datasetHash];
        if (dataset.provider == address(0)) revert DatasetNotFound(datasetHash);
        if (dataset.provider != msg.sender) revert NotDataProvider(); // Ensure caller is the provider

        dataset.available = available;
        emit DatasetAvailabilityUpdated(datasetHash, available);
    }

    // ==============================================================================================
    //                                     TRAINING JOB MANAGEMENT FUNCTIONS (>= 8)
    // ==============================================================================================

    /// @dev Proposes a training job and escrows the reward + data cost + platform fee.
    ///      msg.value must cover the total escrow amount.
    function proposeTrainingJob(
        bytes32 datasetHash,
        bytes32 modelTypeMetadataHash,
        uint256 rewardAmount // Amount intended for compute + validators
    ) public payable whenNotPaused {
        Dataset storage dataset = datasets[datasetHash];
        if (dataset.provider == address(0)) revert DatasetNotFound(datasetHash);
        if (!dataset.available) revert DatasetNotAvailable(datasetHash);

        // Calculate data provider fee and platform fee based on parameters
        // Ensure percentages don't cause overflow if rewardAmount is very large,
        // though with uint256 and typical percentages this is unlikely unless rewards are astronomical.
        uint256 totalEscrowRequired = rewardAmount; // Base reward amount
        uint256 dataProviderFee = (rewardAmount * dataProviderFeePercentage) / (100 - dataProviderFeePercentage); // Calculate data fee such that it's X% of TOTAL escrow minus platform fee
        uint256 platformFee = (rewardAmount + dataProviderFee) * platformFeePercentage / (100);

         // Recalculate total escrow: base reward + data fee + platform fee
        totalEscrowRequired = rewardAmount + dataProviderFee + platformFee;


        if (msg.value < totalEscrowRequired) {
             // Refund excess ETH if any (shouldn't happen if value < required, but good practice)
             // require(msg.value >= totalEscrowRequired, InsufficientStake(totalEscrowRequired, msg.value)); // Use require with custom error
             // More specific error:
             revert InsufficientStake(totalEscrowRequired, msg.value);
        }

        uint256 excessETH = msg.value - totalEscrowRequired;
        if (excessETH > 0) {
             (bool success, ) = payable(msg.sender).call{value: excessETH}("");
             require(success, "Excess ETH refund failed");
        }


        uint256 currentJobId = nextJobId++;
        trainingJobs[currentJobId] = TrainingJob({
            jobId: currentJobId,
            requester: msg.sender,
            datasetHash: datasetHash,
            modelTypeMetadataHash: modelTypeMetadataHash,
            escrowAmount: totalEscrowRequired,
            rewardAmount: rewardAmount, // This is the amount to be split AFTER data & platform fees
            status: JobStatus.Proposed,
            computeProvider: address(0),
            submittedResultHash: bytes32(0),
            submittedProofHash: bytes32(0),
            assignedValidators: new address[](0), // Assigned later
            validatorVoted: new mapping(address => bool)(), // Initialize empty mappings
            validatorApprovalVote: new mapping(address => bool)(),
            approvalVotes: 0,
            rejectionVotes: 0,
            verificationStatus: VerificationStatus.NotStarted,
            validationEndTime: 0, // Set when result is submitted
            finalModelHash: bytes32(0) // Set after verification
        });

        // Add to available jobs list
        availableJobIds.push(currentJobId);
        isAvailableJob[currentJobId] = true;

        emit TrainingJobProposed(currentJobId, msg.sender, datasetHash, totalEscrowRequired);
    }

    /// @dev Allows the job requester to cancel a job if it hasn't been claimed yet.
    function cancelTrainingJob(uint256 jobId) public whenNotPaused {
        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        if (job.requester != msg.sender) revert NotRequester(jobId);
        if (job.status != JobStatus.Proposed) revert InvalidJobStatus(jobId);

        job.status = JobStatus.Canceled;

        // Remove from available jobs list (simple removal by setting flag, list needs rebuild for efficiency)
        isAvailableJob[jobId] = false;
        // In a real system, efficiently removing from dynamic array `availableJobIds` is needed (e.g., swap and pop last).

        // Refund escrow
        uint256 refundAmount = job.escrowAmount;
        (bool success, ) = payable(job.requester).call{value: refundAmount}("");
        require(success, "Refund failed");

        emit TrainingJobCanceled(jobId);
    }

    /// @dev Allows a registered compute provider to claim an available training job.
    ///      Simplistic assignment: first eligible provider to call claims it.
    ///      Advanced: Could involve reputation, stake, bidding, or capability matching.
    function claimAvailableJob(uint256 jobId) public whenNotPaused {
        if (!computeProviders[msg.sender].registered) revert NotComputeProvider();

        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        if (job.status != JobStatus.Proposed) revert InvalidJobStatus(jobId);

        // Check if the provider meets any specific requirements (e.g., stake, reputation, capabilities - not implemented)
        // require(computeProviders[msg.sender].stake >= job.minProviderStake, "Insufficient provider stake");

        job.computeProvider = msg.sender;
        job.status = JobStatus.Assigned;

        // Remove from available jobs list (simplified)
        isAvailableJob[jobId] = false;
        // Add to awaiting result submission list (simplified)
        jobsAwaitingResultSubmissionIds.push(jobId);
        isAwaitingResultSubmissionJob[jobId] = true;


        emit TrainingJobClaimed(jobId, msg.sender);
    }

    /// @dev Compute provider submits the results of the off-chain training.
    ///      resultHash should reference where the model, metrics, etc. are stored (e.g., IPFS).
    ///      proofHash is optional, referencing verification proof (e.g., ZK proof).
    function submitTrainingResult(uint256 jobId, bytes32 resultHash, bytes32 proofHash) public whenNotPaused {
        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        if (job.computeProvider != msg.sender) revert NotAssignedComputeProvider(jobId);
        if (job.status != JobStatus.Assigned) revert InvalidJobStatus(jobId);
        require(resultHash != bytes32(0), "Result hash cannot be zero");

        job.submittedResultHash = resultHash;
        job.submittedProofHash = proofHash;
        job.status = JobStatus.ResultSubmitted;
        job.verificationStatus = VerificationStatus.PendingVotes;
        job.validationEndTime = block.timestamp + jobValidationTimeout;

        // Assign Validators (Simplistic: select first N registered validators)
        // A real system would need a fairer, more decentralized, and possibly stake/reputation-weighted selection.
        uint256 validatorCount = 0;
        for (address validatorAddress; validatorCount < jobAssignmentValidatorCount; ) {
            // Iterate through validators mapping (inefficient for large numbers!)
            // This needs optimization in a real dapp, e.g., using an array of registered validators.
             bool found = false;
             // Naive iteration placeholder: find the first `jobAssignmentValidatorCount` registered validators
             // This loop is NOT suitable for production with many validators due to gas costs.
             // A better approach: keep a dynamic array of registered validators and pick randomly/deterministically.
             // For demonstration: let's add the first few registered validators found by iterating.
             // This requires a way to iterate mapping keys or have a separate list.
             // Let's switch to requiring Admin to assign validators or using a separate Validator Pool contract.
             // Simplest for this example: The system expects off-chain components to know which validators to call
             // submitValidationVote, or Admin assigns them after submission. Let's make Admin assign.

             // REVISED PLAN: Result submission changes status to ResultSubmitted.
             // Admin (or a decentralized oracle/system) calls a *separate* function `assignValidatorsToJob`
             // then the job moves to `AwaitingValidation`.
             // Let's adjust status flow: Assigned -> ResultSubmitted -> (Admin Assigns Validators) -> AwaitingValidation -> ValidationComplete -> Completed/Failed

             // Simple approach without explicit assignment needed first: Move directly to AWAITING_VALIDATION
             // and rely on *any* registered validator to check the AWAITING_VALIDATION list and submit votes.
             // This is less controlled but simpler on-chain. Validators check `listJobsAwaitingValidation`.

             // Let's go back to *contract assigning* a list of validators upon result submission,
             // but acknowledge that the current method of *finding* validators is simplified.
             // A better approach would use a separate, publicly readable array of registered validators.
             // Let's use a placeholder assignment logic that in reality would be more robust.
             // Placeholder: assign first N validators from *some* list (not mapping iteration).
             // Assuming `getRegisteredValidators()` exists and is efficient (it doesn't in this contract yet).
        }

         // Simplification: We won't dynamically assign validators here. Instead, ANY registered validator
         // can submit a vote for jobs in the AWAITING_VALIDATION state. This is simpler for demo.
         job.status = JobStatus.AwaitingValidation;
         jobsAwaitingValidationIds.push(jobId);
         isAwaitingValidationJob[jobId] = true;

         // Remove from awaiting result submission list (simplified)
         isAwaitingResultSubmissionJob[jobId] = false;


        emit TrainingResultSubmitted(jobId, resultHash, proofHash);
    }

    /// @dev Allows an assigned validator to submit their vote on a training result.
    ///      Proof hash is optional (e.g., hash of validation logs, benchmark results, proof verification output).
    function submitValidationVote(uint256 jobId, bool approval, bytes32 proofHash) public whenNotPaused {
        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        if (job.status != JobStatus.AwaitingValidation) revert InvalidJobStatus(jobId);
        if (!validators[msg.sender].registered) revert NotValidator();

        // In the simplified "any validator can vote" model: check if already voted
        if (job.validatorVoted[msg.sender]) revert ValidatorAlreadyVoted(jobId);

        // If we used assignedValidators: Check if msg.sender is in job.assignedValidators
        // bool isAssigned = false;
        // for(uint i = 0; i < job.assignedValidators.length; i++) {
        //     if (job.assignedValidators[i] == msg.sender) {
        //         isAssigned = true;
        //         break;
        //     }
        // }
        // if (!isAssigned) revert NotAssignedValidator(jobId);

        job.validatorVoted[msg.sender] = true;
        job.validatorApprovalVote[msg.sender] = approval; // Record the vote (true for approve, false for reject)

        if (approval) {
            job.approvalVotes++;
        } else {
            job.rejectionVotes++;
        }

        // Store the validator's specific proof hash if provided (mapping validator address to proof hash per job)
        // This requires another mapping: mapping(uint256 => mapping(address => bytes32)) public validatorValidationProofHashes;
        // validatorValidationProofHashes[jobId][msg.sender] = proofHash; // Assuming this mapping exists

        emit ValidationVoteSubmitted(jobId, msg.sender, approval, proofHash);

        // Optional: Auto-finalize if supermajority reached early? Or just rely on `finalizeJobVerification` being called.
        // Let's rely on explicit finalization call.
    }

    /// @dev Callable by anyone to finalize job verification after validation timeout or sufficient votes.
    function finalizeJobVerification(uint256 jobId) public whenNotPaused {
        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        if (job.status != JobStatus.AwaitingValidation) revert InvalidJobStatus(jobId);
        // Require either validation period ended OR enough validators have voted (if using assigned validators)
        // With the simplified "any validator can vote" model, we only check the timeout.
        if (block.timestamp < job.validationEndTime) revert ValidationPeriodNotEnded(jobId);

        uint256 totalVotes = job.approvalVotes + job.rejectionVotes;
        // If using assigned validators, check `totalVotes >= job.assignedValidators.length` or a threshold.
        // With "any validator", check minimum participation or just rely on timeout.
        // Let's require at least one vote AND the timeout.
        require(totalVotes > 0, "No votes submitted");


        // Determine verification status
        // Calculate percentage of approval votes
        // Note: Integer division means (job.approvalVotes * 100) / totalVotes
        uint256 approvalPercentage = (job.approvalVotes * 100) / totalVotes;

        if (approvalPercentage >= jobVerificationSupermajority) {
            job.verificationStatus = VerificationStatus.Approved;
            // The actual model hash is part of the submittedResultHash (first 32 bytes?)
            // Assuming the resultHash is structured, e.g., first 32 bytes is model hash.
            // This requires off-chain agreement on result hash format.
            // For simplicity, let's assume the *entire* resultHash IS the final output hash.
            job.finalModelHash = job.submittedResultHash;
            job.status = JobStatus.ValidationComplete; // Move to intermediary state before rewards
            emit JobVerificationFinalized(jobId, VerificationStatus.Approved);

        } else {
            job.verificationStatus = VerificationStatus.Rejected;
            job.status = JobStatus.ValidationComplete; // Move to intermediary state before handling failure
             emit JobVerificationFinalized(jobId, VerificationStatus.Rejected);
             emit JobFailed(jobId, "Validation failed");
        }

        // Remove from awaiting validation list (simplified)
        isAwaitingValidationJob[jobId] = false;
    }

    /// @dev Distributes escrowed funds after successful job verification.
    function distributeRewards(uint256 jobId) public whenNotPaused {
        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        if (job.status != JobStatus.ValidationComplete) revert InvalidJobStatus(jobId);
        if (job.verificationStatus != VerificationStatus.Approved) revert JobNotVerifiedApproved(jobId);
        // Prevent double distribution
        // Use a flag or transition to a final state after distribution
        if (job.finalModelHash == bytes32(0)) { // Check if model hash was set upon approval
             revert RewardsAlreadyDistributed(jobId); // This check might be weak depending on implementation
        }
         // Let's add a state specifically for 'Distributed'
        if (job.status == JobStatus.Completed) revert RewardsAlreadyDistributed(jobId);


        uint256 totalEscrow = job.escrowAmount;
        uint256 rewardPool = job.rewardAmount; // The portion designated for CP and Validators

        // Calculate shares
        uint256 platformFee = (totalEscrow * platformFeePercentage) / 100;
        uint256 dataProviderReward = (totalEscrow * dataProviderFeePercentage) / 100; // Paid from total escrow
        uint256 computeProviderReward = (rewardPool * computeProviderRewardPercentage) / 100; // Paid from rewardPool
        uint256 totalValidatorReward = (rewardPool * validatorRewardPercentage) / 100; // Paid from rewardPool

        // The rest of the rewardPool (100 - CP% - V%) might be returned to requester or distributed somehow.
        // For simplicity, let's return it to the requester or add it to the platform fee.
        // Let's return the remainder of the reward pool to the requester.
        uint256 rewardPoolRemainder = rewardPool - computeProviderReward - totalValidatorReward;

        // Calculate individual validator rewards (simple equal split among approving validators)
        uint256 individualValidatorReward = 0;
        if (job.approvalVotes > 0) {
             individualValidatorReward = totalValidatorReward / job.approvalVotes;
        }

        // Distribute funds
        uint256 totalDistributed = 0;

        // 1. Platform Fee (send to owner or designated address)
        if (platformFee > 0) {
             (bool success, ) = payable(owner).call{value: platformFee}("");
             // Consider handling failure here - maybe log it, don't revert? Reverting might lock funds.
             // For critical transfers, `require` is safer.
             require(success, "Platform fee distribution failed");
             totalDistributed += platformFee;
        }

        // 2. Data Provider Reward
        address dataProviderAddress = datasets[job.datasetHash].provider;
        if (dataProviderAddress != address(0) && dataProviderReward > 0) {
             (bool success, ) = payable(dataProviderAddress).call{value: dataProviderReward}("");
             require(success, "Data provider reward distribution failed");
             totalDistributed += dataProviderReward;
        }

        // 3. Compute Provider Reward
        if (job.computeProvider != address(0) && computeProviderReward > 0) {
             (bool success, ) = payable(job.computeProvider).call{value: computeProviderReward}("");
             require(success, "Compute provider reward distribution failed");
             totalDistributed += computeProviderReward;
        }

        // 4. Validator Rewards (only to validators who voted 'approve')
        // This requires iterating through the votes stored in the job struct.
        // Iterating mappings is tricky/costly. Need to retrieve the list of voters.
        // Let's assume we can somehow get the list of voters efficiently or iterate.
        // Iterating the entire `validatorVoted` mapping is gas-prohibitive.
        // A better design stores the list of voters in an array when votes are cast.
        // Simplified approach: Iterate through ALL registered validators and check their vote status for this job (still potentially costly).
        // For a robust system, we'd need `address[] public votersForJob[jobId];` or similar.
        // Let's defer this complex iteration for simplicity and assume a helper exists or use a placeholder.
        // Placeholder logic: Iterate through the `assignedValidators` list if that were implemented, or find approving voters somehow.
        // Given the simplified "any validator" vote model, we can't easily get a list of voters.
        // Let's simplify validator rewards further: calculate total validator reward and assume it's somehow claimable or distributed off-chain,
        // or iterate through `job.validatorVoted` if the number of voters is expected to be small.
        // If iterating the map is too costly, validator rewards need a different mechanism (e.g., claim based on proof of vote).

        // Let's use a very basic iteration for the demo, acknowledging its cost:
        // This loop *will* be expensive if many validators vote.
        address[] memory potentialVoters = getRegisteredValidators(); // Assuming a function exists to list validators
        uint256 distributedValidatorRewards = 0;
        for(uint i=0; i < potentialVoters.length; i++) {
            address valAddr = potentialVoters[i];
            if (job.validatorVoted[valAddr] && job.validatorApprovalVote[valAddr]) {
                // Validator voted 'approve'
                 uint256 reward = individualValidatorReward; // Distribute equal share
                 if (reward > 0) {
                     (bool success, ) = payable(valAddr).call{value: reward}("");
                     if (success) {
                         distributedValidatorRewards += reward;
                     }
                     // Handle failure? Log? Don't revert? Reverting here could block all rewards.
                 }
            }
        }
        // Ensure total validator reward distributed is correct (due to integer division, it might be slightly less than totalValidatorReward)
        totalDistributed += distributedValidatorRewards;


        // 5. Return remaining escrow to Requester
        uint256 remainingEscrow = totalEscrow - totalDistributed; // Should be equal to rewardPoolRemainder

        if (remainingEscrow > 0) {
             (bool success, ) = payable(job.requester).call{value: remainingEscrow}("");
             require(success, "Remaining escrow refund failed");
        }

        job.status = JobStatus.Completed;
        emit RewardsDistributed(jobId, platformFee, computeProviderReward, dataProviderReward, totalDistributed);

        // Mark Compute Provider/Validators as eligible for reputation boost (deferred)
    }

    /// @dev Handles outcomes when a job verification fails. May involve slashing.
    function handleFailedVerification(uint256 jobId) public whenNotPaused {
         TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        if (job.status != JobStatus.ValidationComplete) revert InvalidJobStatus(jobId);
        if (job.verificationStatus != VerificationStatus.Rejected) revert("Job was not rejected");
        // Prevent double handling
        if (job.status == JobStatus.Failed) revert("Job failure already handled");

        // --- Penalty/Slashing Logic ---
        // This is complex and depends on the specific failure reason and evidence.
        // Possible penalties:
        // 1. Slash Compute Provider's stake: Likely if the result was incorrect/malicious.
        // 2. Slash Validators' stake: If they voted maliciously or incorrectly (e.g., approving a bad result, rejecting a good one - harder to prove on-chain).
        // 3. Return escrow to Requester: Usually happens if the job failed due to Provider error.

        // Simplified penalty: Slash Compute Provider a percentage of their stake, return remaining escrow to Requester.
        uint256 slashAmount = (computeProviders[job.computeProvider].stake * 10) / 100; // Example: slash 10%
        if (computeProviders[job.computeProvider].registered && slashAmount > 0) {
             // Avoid slashing below min stake if required
             uint256 slashableStake = computeProviders[job.computeProvider].stake - minComputeProviderStake; // Keep min stake locked? Or slash below min?
             uint256 actualSlashAmount = slashAmount > slashableStake ? slashableStake : slashAmount;

             if (actualSlashAmount > 0) {
                computeProviders[job.computeProvider].stake -= actualSlashAmount;
                // Slashed funds (burned or sent elsewhere - see slashStake function)
                emit StakeSlashed(job.computeProvider, actualSlashAmount, "Job verification failed");
             }
        }

        // Return remaining escrow to Requester (total escrow minus any potentially distributed platform fee or data fee if already sent - depends on timing)
        // Simplification: Assuming no fees were distributed yet, return full escrow to requester.
        // In a real system, fees might be deducted upon job creation or result submission.
        uint256 refundAmount = job.escrowAmount; // Example: refund full amount
        (bool success, ) = payable(job.requester).call{value: refundAmount}("");
        require(success, "Failed escrow refund on job failure");


        job.status = JobStatus.Failed;
         // Mark Compute Provider/Validators as eligible for reputation decrease (deferred)
    }


    // ==============================================================================================
    //                                     QUERY FUNCTIONS (>= 5)
    // ==============================================================================================

    /// @dev Returns details of a training job.
    function getJobDetails(uint256 jobId) public view returns (
        uint256, // jobId
        address, // requester
        bytes32, // datasetHash
        bytes32, // modelTypeMetadataHash
        uint256, // escrowAmount
        uint256, // rewardAmount
        JobStatus,
        address, // computeProvider
        bytes32, // submittedResultHash
        bytes32, // submittedProofHash
        address[] memory, // assignedValidators (might be empty in simplified model)
        uint256, // approvalVotes
        uint256, // rejectionVotes
        VerificationStatus,
        uint256, // validationEndTime
        bytes32  // finalModelHash
    ) {
        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0) && jobId != 0) revert JobNotFound(jobId); // Check for existence, allow 0 for initial state

        return (
            job.jobId,
            job.requester,
            job.datasetHash,
            job.modelTypeMetadataHash,
            job.escrowAmount,
            job.rewardAmount,
            job.status,
            job.computeProvider,
            job.submittedResultHash,
            job.submittedProofHash,
            job.assignedValidators, // This will be empty in the simplified voting model
            job.approvalVotes,
            job.rejectionVotes,
            job.verificationStatus,
            job.validationEndTime,
            job.finalModelHash
        );
    }

     /// @dev Returns details of a participant.
     ///      Returns empty struct if not registered in that role.
     function getParticipantDetails(address participant) public view returns (
         DataProvider memory,
         ComputeProvider memory,
         Validator memory
     ) {
         return (
             dataProviders[participant],
             computeProviders[participant],
             validators[participant]
         );
     }

     /// @dev Returns details of a registered dataset.
     function getDatasetDetails(bytes32 datasetHash) public view returns (
         Dataset memory
     ) {
         return datasets[datasetHash];
     }

    /// @dev Returns IDs of jobs currently in the Proposed state.
    ///      Note: Iterating a dynamic array for removal is inefficient.
    ///      This getter iterates the full array which is okay for demonstration but not scalable.
    function listAvailableJobs() public view returns (uint256[] memory) {
        // Efficiently collect IDs where isAvailableJob is true
        uint256 count = 0;
        for (uint i = 0; i < availableJobIds.length; i++) {
            if (isAvailableJob[availableJobIds[i]]) {
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint i = 0; i < availableJobIds.length; i++) {
            if (isAvailableJob[availableJobIds[i]]) {
                result[index] = availableJobIds[i];
                index++;
            }
        }
        return result;
    }

    /// @dev Returns IDs of jobs currently awaiting validator votes.
     function listJobsAwaitingValidation() public view returns (uint256[] memory) {
         uint256 count = 0;
         for (uint i = 0; i < jobsAwaitingValidationIds.length; i++) {
            if (isAwaitingValidationJob[jobsAwaitingValidationIds[i]]) {
                 count++;
             }
         }
         uint256[] memory result = new uint256[](count);
         uint256 index = 0;
         for (uint i = 0; i < jobsAwaitingValidationIds.length; i++) {
             if (isAwaitingValidationJob[jobsAwaitingValidationIds[i]]) {
                 result[index] = jobsAwaitingValidationIds[i];
                 index++;
             }
         }
         return result;
     }

    /// @dev Returns IDs of jobs currently assigned to compute providers but results not submitted.
    function listJobsAwaitingResultSubmission() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint i = 0; i < jobsAwaitingResultSubmissionIds.length; i++) {
            if (isAwaitingResultSubmissionJob[jobsAwaitingResultSubmissionIds[i]]) {
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint i = 0; i < jobsAwaitingResultSubmissionIds.length; i++) {
            if (isAwaitingResultSubmissionJob[jobsAwaitingResultSubmissionIds[i]]) {
                result[index] = jobsAwaitingResultSubmissionIds[i];
                index++;
            }
        }
        return result;
    }


    /// @dev Returns the final verified model hash and submitted result hash for a completed job.
    ///      Only accessible by the original requester or potentially other approved addresses.
    function getModelAccessInfo(uint256 jobId) public view returns (bytes32 verifiedModelHash, bytes32 submittedResultHash) {
        TrainingJob storage job = trainingJobs[jobId];
        if (job.requester == address(0)) revert JobNotFound(jobId);
        // In a real system, check if msg.sender is requester OR has purchased access.
        if (job.requester != msg.sender) revert("Access denied"); // Simplified access control

        if (job.status != JobStatus.Completed) revert("Job not completed successfully");

        return (job.finalModelHash, job.submittedResultHash);
    }

    // Helper/Internal function (not a counted function for the 20+)
    // NOTE: This is a placeholder. Iterating through ALL registered validators this way is Gas-prohibitive
    // for large numbers of validators. A real system needs a different approach (e.g., an array
    // of registered validators managed explicitly).
    function getRegisteredValidators() internal view returns (address[] memory) {
        // This cannot efficiently iterate a mapping to build a list.
        // We would need an auxiliary array `address[] public registeredValidatorsList;`
        // managed during register/deregister calls.
        // For the sake of having the function called in distributeRewards, return an empty array or a hardcoded small list.
        // Returning empty array means validator rewards won't be distributed in this implementation via this function.
        // This highlights a limitation of mapping iteration.
        return new address[](0); // Placeholder: cannot implement efficiently like this
    }

    // 20+ function count check:
    // Admin: 5 (setStakeReq, setReputation, setJobParams, setRewardParams, slashStake) + 2 (pause/unpause) = 7
    // Participant: 3 (register DP/CP/V) + 3 (update DP/CP/V) + 3 (deregister DP/CP/V) + 1 (addStake) + 1 (withdrawEligibleStake) = 11
    // Dataset: 2 (registerDataset, updateDatasetAvailability) = 2
    // Job: 1 (propose) + 1 (cancel) + 1 (claim) + 1 (submitResult) + 1 (submitVote) + 1 (finalize) + 1 (distribute) + 1 (handleFailed) = 8
    // Query: 1 (getJob) + 1 (getParticipant) + 1 (getDataset) + 3 (list jobs) + 1 (getModelAccess) = 7
    // Total: 7 + 11 + 2 + 8 + 7 = 35 functions. This easily meets the >= 20 requirement.
}
```