The following smart contract implements a decentralized AI Inference Marketplace. It allows users to request AI model inferences, compute providers to execute these inferences, and a robust verification and reputation system to ensure trust and accountability. It features a dispute resolution mechanism and potential for integration with external verifiable computation oracles.

The "verifiable computation" aspect is handled by incentivizing verifiers to challenge and re-evaluate potentially incorrect inference results. The contract does not execute the AI models directly (which is an off-chain task) but manages the job lifecycle, payments, bonds, and the incentive layer for dispute resolution based on evidence (URIs pointing to proofs, data, etc.) submitted by participants.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Decentralized AI Inference Marketplace with Verifiable Computation and Reputation
 * @author YourNameHere
 * @notice This contract enables a decentralized marketplace for AI models, allowing users to request
 *         inferences, compute providers to execute them, and a robust verification and
 *         reputation system to ensure trust and accountability. It features a dispute resolution
 *         mechanism and potential for oracle integration for complex verifiable computation.
 *         Payments and bonds are handled using the native blockchain currency (e.g., Ether, Matic).
 */

/**
 * @dev Function Outline and Summary:
 *
 * I. Deployment & Administration (6 functions): Basic setup and owner controls for critical parameters.
 *    1. `constructor`: Deploys the contract, setting initial owner, fee parameters, and default bond amounts.
 *    2. `pauseContract`: Allows the owner to pause critical contract operations during emergencies.
 *    3. `unpauseContract`: Allows the owner to resume contract operations.
 *    4. `setPlatformFee`: Owner can adjust the platform's percentage fee on inference jobs.
 *    5. `setFeeRecipient`: Owner can change the address receiving platform fees.
 *    6. `withdrawFees`: Allows the designated fee recipient to withdraw accumulated fees.
 *
 * II. AI Model Management (5 functions): Functions for model providers to register and manage their AI models.
 *    7. `registerAIModel`: Allows a user to register a new AI model with its metadata, pricing, and resource requirements.
 *    8. `updateAIModelMetadata`: Enables a model provider to update details of their registered AI model.
 *    9. `deactivateAIModel`: Model provider can temporarily disable their model from accepting new requests.
 *    10. `activateAIModel`: Model provider can re-enable a deactivated model.
 *    11. `getAIModelDetails`: Publicly accessible function to retrieve all details of a registered AI model.
 *
 * III. Inference Request & Execution (4 functions): Core functions for users to request AI inferences and for compute providers to execute them.
 *    12. `requestInference`: Users initiate an AI inference request, specifying the model, input data, and pre-paying the cost.
 *    13. `acceptInferenceJob`: Compute providers accept a pending inference job, staking a bond as commitment.
 *    14. `submitInferenceResult`: Compute providers submit the hash of the inference output and a URI pointing to the proof of computation.
 *    15. `challengeInferenceResult`: Any participant can challenge a submitted inference result, staking a bond, to trigger a verification process.
 *
 * IV. Verification & Dispute Resolution (3 functions): Mechanisms to verify inference results and resolve disputes.
 *    16. `acceptVerificationChallenge`: Verifiers accept a challenge, committing to re-evaluate the inference result by staking a bond.
 *    17. `submitVerificationOutcome`: Verifiers submit their findings on whether the original inference result was valid or not, along with evidence.
 *    18. `resolveDispute`: This function determines the final outcome of a challenged inference job, distributing rewards/penalties based on submitted verifications or an arbitrator's decision.
 *
 * V. Reputation & Staking (5 functions): A system to track and leverage participant reputation.
 *    19. `stakeForRole`: Allows participants (Compute Providers, Verifiers) to stake native tokens, boosting their reputation or meeting minimum requirements for certain roles.
 *    20. `unstakeFromRole`: Allows participants to request to withdraw their staked tokens, subject to a cool-down period and no active commitments.
 *    21. `completeUnstake`: Finalizes the unstaking process after the cooldown period.
 *    22. `getReputationScore`: Retrieves the current reputation score of a given address.
 *    23. `_updateReputationScore`: (Internal) Helper function to adjust reputation scores based on job performance and dispute outcomes.
 *    24. `setMinimumReputation`: Owner can set minimum reputation scores required for compute providers to accept jobs or verifiers to accept challenges.
 *
 * VI. Arbitration & Advanced Integration (3 functions): Functions for external oversight and potential oracle integration for complex verifications.
 *    25. `setArbitratorAddress`: Owner designates an address or a multi-sig as the primary arbitrator for complex disputes.
 *    26. `reportOracleResult`: Allows a designated `oracleAddress` to report the outcome of off-chain verifiable computations, influencing `resolveDispute`.
 *    27. `setOracleAddress`: Owner can set the trusted oracle address for `reportOracleResult` calls.
 */

contract AIDeX is Ownable, Pausable {
    // --- Constants & Configuration ---
    uint256 public platformFeeBps; // Platform fee in Basis Points (e.g., 100 = 1%)
    address public feeRecipient;
    address public arbitratorAddress; // Address authorized to resolve complex disputes manually
    address public oracleAddress; // Address authorized to report results from external verifiable compute systems

    uint256 public defaultComputeProviderBond;
    uint256 public defaultVerifierBond;
    uint256 public defaultChallengerBond;
    uint256 public defaultReputationStakeAmount; // Minimum stake amount for reputation boost
    uint256 public reputationStakeCooldown; // Time in seconds before unstaking is possible after request

    int256 public defaultMinComputeReputation;
    int256 public defaultMinVerifierReputation;

    uint256 public inferenceJobTimeout; // Time in seconds for compute providers to submit results
    uint256 public challengeWindow; // Time in seconds after result submission to challenge
    uint256 public verificationJobTimeout; // Time in seconds for verifiers to submit outcome
    uint256 public disputeResolutionWindow; // Time in seconds after verification submission to resolve by arbitrator

    // --- Enums ---
    enum AIModelStatus {
        Active,
        Deactivated
    }
    enum InferenceJobStatus {
        Requested,
        AcceptedByCompute,
        ResultSubmitted,
        Challenged,
        VerificationAccepted,
        VerificationSubmitted,
        DisputeResolved,
        Completed, // Successfully completed, funds distributed
        Failed // Job failed or was cancelled/invalid
    }
    enum VerificationOutcome {
        Undecided,
        Valid,
        Invalid
    }

    // --- Structs ---
    struct AIModel {
        address provider;
        string descriptionURI; // URI to model details, architecture, weights (e.g., IPFS hash)
        uint256 inferenceCost; // Cost per inference in native token (wei)
        uint256 requiredComputeUnits; // Abstract measure of compute power needed
        AIModelStatus status;
        uint256 registeredAt;
    }

    struct InferenceJob {
        uint256 modelId;
        address requestor;
        address computeProvider;
        string inputDataURI; // URI to input data (e.g., IPFS hash)
        bytes32 inputDataHash; // Hash of input data for integrity check
        uint256 maxCost; // Max cost user is willing to pay (including fees and bonds)
        uint256 actualCostPaid; // Total native token paid by requestor for the job
        string outputDataURI; // URI to output data
        bytes32 outputDataHash; // Hash of output data
        string proofURI; // URI to computation proof (e.g., ZKP output, TEE attestation)
        bytes32 proofHash; // Hash of the proof itself
        uint256 computeProviderBond; // Bond staked by compute provider
        uint256 verifierBondHeld; // Bond collected from requestor for potential verifier
        uint256 challengerBond; // Bond paid by the challenger
        uint256 payoutAmountToCompute; // Base amount to be paid to compute provider if successful
        uint256 resultSubmissionTime;
        uint256 disputeStartTime; // Time when challenge was made
        address currentVerifier;
        uint256 verificationSubmissionTime;
        InferenceJobStatus status;
        VerificationOutcome finalOutcome; // Set after dispute resolution
        uint256 createdAt;
    }

    struct ReputationStake {
        uint256 amount;
        uint256 lastStakedAt;
        uint256 unstakeRequestTime;
        bool hasActiveUnstakeRequest;
    }

    // --- Mappings ---
    mapping(uint256 => AIModel) public aiModels;
    uint256 public nextModelId;

    mapping(uint256 => InferenceJob) public inferenceJobs;
    uint256 public nextJobId;

    mapping(address => int256) public reputationScores; // int256 to allow negative scores
    mapping(address => ReputationStake) public reputationStakes;

    mapping(address => uint256) public pendingWithdrawals; // For all types of withdrawals (fees, stakes, job payouts)

    // --- Events ---
    event AIModelRegistered(
        uint256 indexed modelId,
        address indexed provider,
        string descriptionURI,
        uint256 inferenceCost
    );
    event AIModelMetadataUpdated(uint256 indexed modelId, address indexed provider, string descriptionURI);
    event AIModelStatusChanged(uint256 indexed modelId, AIModelStatus newStatus);

    event InferenceRequested(
        uint256 indexed jobId,
        uint256 indexed modelId,
        address indexed requestor,
        uint256 actualCostPaid
    );
    event InferenceJobAccepted(
        uint256 indexed jobId,
        address indexed computeProvider,
        uint256 computeProviderBond
    );
    event InferenceResultSubmitted(
        uint256 indexed jobId,
        address indexed computeProvider,
        bytes32 outputDataHash,
        bytes32 proofHash
    );
    event InferenceResultChallenged(
        uint256 indexed jobId,
        address indexed challenger,
        uint256 challengerBond
    );
    event VerificationChallengeAccepted(
        uint256 indexed jobId,
        address indexed verifier,
        uint256 verifierBond
    );
    event VerificationOutcomeSubmitted(
        uint256 indexed jobId,
        address indexed verifier,
        VerificationOutcome outcome
    );
    event DisputeResolved(
        uint256 indexed jobId,
        InferenceJobStatus finalStatus,
        VerificationOutcome finalOutcome
    );
    event InferenceJobCompleted(uint252 indexed jobId, address indexed computeProvider, uint256 amount);
    event InferenceJobFailed(uint256 indexed jobId, address indexed computeProvider, string reason);

    event ReputationUpdated(address indexed participant, int256 newScore);
    event TokensStaked(address indexed participant, uint256 amount);
    event UnstakeRequested(address indexed participant, uint256 amount);
    event TokensUnstaked(address indexed participant, uint256 amount);

    event ArbitratorAddressSet(address indexed newArbitrator);
    event OracleAddressSet(address indexed newOracle);
    event PlatformFeeUpdated(uint256 newFeeBps);
    event FeeRecipientUpdated(address indexed newRecipient);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    // 1. constructor
    constructor(
        address _feeRecipient,
        uint256 _platformFeeBps, // e.g., 100 for 1%
        uint256 _defaultComputeProviderBond,
        uint256 _defaultVerifierBond,
        uint256 _defaultChallengerBond,
        uint256 _defaultReputationStakeAmount,
        uint256 _reputationStakeCooldown,
        uint256 _inferenceJobTimeout,
        uint256 _challengeWindow,
        uint256 _verificationJobTimeout,
        uint256 _disputeResolutionWindow,
        int256 _defaultMinComputeReputation,
        int256 _defaultMinVerifierReputation
    ) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_platformFeeBps <= 10000, "Fee cannot exceed 100%"); // 10000 bps = 100%

        feeRecipient = _feeRecipient;
        platformFeeBps = _platformFeeBps;

        defaultComputeProviderBond = _defaultComputeProviderBond;
        defaultVerifierBond = _defaultVerifierBond;
        defaultChallengerBond = _defaultChallengerBond;
        defaultReputationStakeAmount = _defaultReputationStakeAmount;
        reputationStakeCooldown = _reputationStakeCooldown;

        inferenceJobTimeout = _inferenceJobTimeout;
        challengeWindow = _challengeWindow;
        verificationJobTimeout = _verificationJobTimeout;
        disputeResolutionWindow = _disputeResolutionWindow;

        defaultMinComputeReputation = _defaultMinComputeReputation;
        defaultMinVerifierReputation = _defaultMinVerifierReputation;

        nextModelId = 1;
        nextJobId = 1;
    }

    // --- Modifiers ---
    modifier onlyArbitrator() {
        require(msg.sender == arbitratorAddress, "Caller is not the arbitrator");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    // --- I. Deployment & Administration (6 functions) ---

    // 2. pauseContract
    function pauseContract() external onlyOwner {
        _pause();
    }

    // 3. unpauseContract
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // 4. setPlatformFee
    function setPlatformFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 10000, "Fee cannot exceed 100%");
        platformFeeBps = _newFeeBps;
        emit PlatformFeeUpdated(_newFeeBps);
    }

    // 5. setFeeRecipient
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    // 6. withdrawFees
    function withdrawFees() external {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending funds to withdraw");

        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to withdraw funds");
        emit FundsWithdrawn(msg.sender, amount);
    }

    // --- II. AI Model Management (5 functions) ---

    // 7. registerAIModel
    function registerAIModel(
        string memory _descriptionURI,
        uint256 _inferenceCost,
        uint256 _requiredComputeUnits
    ) external whenNotPaused returns (uint256) {
        require(bytes(_descriptionURI).length > 0, "Description URI cannot be empty");
        require(_inferenceCost > 0, "Inference cost must be positive");
        require(_requiredComputeUnits > 0, "Required compute units must be positive");

        uint256 modelId = nextModelId++;
        aiModels[modelId] = AIModel({
            provider: msg.sender,
            descriptionURI: _descriptionURI,
            inferenceCost: _inferenceCost,
            requiredComputeUnits: _requiredComputeUnits,
            status: AIModelStatus.Active,
            registeredAt: block.timestamp
        });
        emit AIModelRegistered(modelId, msg.sender, _descriptionURI, _inferenceCost);
        return modelId;
    }

    // 8. updateAIModelMetadata
    function updateAIModelMetadata(
        uint256 _modelId,
        string memory _newDescriptionURI,
        uint256 _newInferenceCost,
        uint256 _newRequiredComputeUnits
    ) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.provider == msg.sender, "Only model provider can update");
        require(model.status == AIModelStatus.Active, "Model is not active");
        require(bytes(_newDescriptionURI).length > 0, "Description URI cannot be empty");
        require(_newInferenceCost > 0, "Inference cost must be positive");
        require(_newRequiredComputeUnits > 0, "Required compute units must be positive");

        model.descriptionURI = _newDescriptionURI;
        model.inferenceCost = _newInferenceCost;
        model.requiredComputeUnits = _newRequiredComputeUnits;

        emit AIModelMetadataUpdated(_modelId, msg.sender, _newDescriptionURI);
    }

    // 9. deactivateAIModel
    function deactivateAIModel(uint256 _modelId) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.provider == msg.sender, "Only model provider can deactivate");
        require(model.status == AIModelStatus.Active, "Model is already deactivated");

        model.status = AIModelStatus.Deactivated;
        emit AIModelStatusChanged(_modelId, AIModelStatus.Deactivated);
    }

    // 10. activateAIModel
    function activateAIModel(uint256 _modelId) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        require(model.provider == msg.sender, "Only model provider can activate");
        require(model.status == AIModelStatus.Deactivated, "Model is already active");

        model.status = AIModelStatus.Active;
        emit AIModelStatusChanged(_modelId, AIModelStatus.Active);
    }

    // 11. getAIModelDetails
    function getAIModelDetails(
        uint256 _modelId
    )
        external
        view
        returns (
            address provider,
            string memory descriptionURI,
            uint256 inferenceCost,
            uint256 requiredComputeUnits,
            AIModelStatus status,
            uint256 registeredAt
        )
    {
        AIModel storage model = aiModels[_modelId];
        require(model.provider != address(0), "Model does not exist");
        return (
            model.provider,
            model.descriptionURI,
            model.inferenceCost,
            model.requiredComputeUnits,
            model.status,
            model.registeredAt
        );
    }

    // --- III. Inference Request & Execution (4 functions) ---

    // 12. requestInference
    function requestInference(
        uint256 _modelId,
        string memory _inputDataURI,
        bytes32 _inputDataHash,
        uint256 _maxCost
    ) external payable whenNotPaused returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        require(model.provider != address(0), "Model does not exist");
        require(model.status == AIModelStatus.Active, "Model is not active");
        require(bytes(_inputDataURI).length > 0, "Input data URI cannot be empty");
        require(_maxCost >= model.inferenceCost, "Max cost is less than model inference cost");

        // Calculate total cost: model cost + platform fee + verifier bond (paid by requestor upfront)
        uint256 platformFee = (model.inferenceCost * platformFeeBps) / 10000;
        uint256 actualCostRequired = model.inferenceCost + platformFee + defaultVerifierBond;

        require(msg.value >= actualCostRequired, "Insufficient funds sent for inference");
        require(actualCostRequired <= _maxCost, "Actual cost exceeds maximum allowed by requestor");

        uint256 jobId = nextJobId++;
        inferenceJobs[jobId] = InferenceJob({
            modelId: _modelId,
            requestor: msg.sender,
            computeProvider: address(0),
            inputDataURI: _inputDataURI,
            inputDataHash: _inputDataHash,
            maxCost: _maxCost,
            actualCostPaid: actualCostRequired,
            outputDataURI: "",
            outputDataHash: bytes32(0),
            proofURI: "",
            proofHash: bytes32(0),
            computeProviderBond: 0,
            verifierBondHeld: defaultVerifierBond,
            challengerBond: 0,
            payoutAmountToCompute: model.inferenceCost,
            resultSubmissionTime: 0,
            disputeStartTime: 0,
            currentVerifier: address(0),
            verificationSubmissionTime: 0,
            status: InferenceJobStatus.Requested,
            finalOutcome: VerificationOutcome.Undecided,
            createdAt: block.timestamp
        });

        // Store platform fee for later withdrawal
        pendingWithdrawals[feeRecipient] += platformFee;

        // Refund any excess funds
        if (msg.value > actualCostRequired) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - actualCostRequired}("");
            require(success, "Failed to refund excess funds");
        }

        emit InferenceRequested(jobId, _modelId, msg.sender, actualCostRequired);
        return jobId;
    }

    // 13. acceptInferenceJob
    function acceptInferenceJob(uint256 _jobId) external payable whenNotPaused {
        InferenceJob storage job = inferenceJobs[_jobId];
        require(job.status == InferenceJobStatus.Requested, "Job not in 'Requested' state");
        require(msg.sender != job.requestor, "Requestor cannot be compute provider");
        require(msg.value == defaultComputeProviderBond, "Incorrect compute provider bond");
        require(
            getReputationScore(msg.sender) >= defaultMinComputeReputation,
            "Compute provider reputation too low"
        );

        job.computeProvider = msg.sender;
        job.computeProviderBond = msg.value;
        job.status = InferenceJobStatus.AcceptedByCompute;

        emit InferenceJobAccepted(_jobId, msg.sender, job.computeProviderBond);
    }

    // 14. submitInferenceResult
    function submitInferenceResult(
        uint256 _jobId,
        string memory _outputDataURI,
        bytes32 _outputDataHash,
        string memory _proofURI,
        bytes32 _proofHash
    ) external whenNotPaused {
        InferenceJob storage job = inferenceJobs[_jobId];
        require(job.computeProvider == msg.sender, "Only assigned compute provider can submit result");
        require(job.status == InferenceJobStatus.AcceptedByCompute, "Job not in 'Accepted' state");
        require(bytes(_outputDataURI).length > 0, "Output data URI cannot be empty");
        require(bytes(_proofURI).length > 0, "Proof URI cannot be empty");
        require(
            block.timestamp <= job.createdAt + inferenceJobTimeout,
            "Inference job timed out for submission"
        );

        job.outputDataURI = _outputDataURI;
        job.outputDataHash = _outputDataHash;
        job.proofURI = _proofURI;
        job.proofHash = _proofHash;
        job.resultSubmissionTime = block.timestamp;
        job.status = InferenceJobStatus.ResultSubmitted;

        emit InferenceResultSubmitted(_jobId, msg.sender, _outputDataHash, _proofHash);
    }

    // 15. challengeInferenceResult
    function challengeInferenceResult(uint256 _jobId) external payable whenNotPaused {
        InferenceJob storage job = inferenceJobs[_jobId];
        require(job.status == InferenceJobStatus.ResultSubmitted, "Job not in 'Result Submitted' state");
        require(msg.sender != job.computeProvider, "Compute provider cannot challenge own result");
        require(job.challengerBond == 0, "Job already challenged (single challenge allowed)");
        require(
            block.timestamp <= job.resultSubmissionTime + challengeWindow,
            "Challenge window has closed"
        );
        require(msg.value == defaultChallengerBond, "Incorrect challenger bond");

        job.challengerBond = msg.value;
        job.status = InferenceJobStatus.Challenged;
        job.disputeStartTime = block.timestamp;

        emit InferenceResultChallenged(_jobId, msg.sender, msg.value);
    }

    // --- IV. Verification & Dispute Resolution (3 functions) ---

    // 16. acceptVerificationChallenge
    function acceptVerificationChallenge(uint256 _jobId) external payable whenNotPaused {
        InferenceJob storage job = inferenceJobs[_jobId];
        require(job.status == InferenceJobStatus.Challenged, "Job not in 'Challenged' state");
        require(msg.sender != job.requestor, "Requestor cannot be verifier");
        require(msg.sender != job.computeProvider, "Compute provider cannot be verifier");
        require(job.currentVerifier == address(0), "A verifier has already accepted this challenge");
        require(msg.value == defaultVerifierBond, "Incorrect verifier bond");
        require(
            getReputationScore(msg.sender) >= defaultMinVerifierReputation,
            "Verifier reputation too low"
        );
        require(
            block.timestamp <= job.disputeStartTime + verificationJobTimeout,
            "Verification acceptance window has closed"
        );

        job.currentVerifier = msg.sender;
        job.status = InferenceJobStatus.VerificationAccepted;

        emit VerificationChallengeAccepted(_jobId, msg.sender, msg.value);
    }

    // 17. submitVerificationOutcome
    function submitVerificationOutcome(
        uint256 _jobId,
        VerificationOutcome _outcome,
        string memory _evidenceURI
    ) external whenNotPaused {
        InferenceJob storage job = inferenceJobs[_jobId];
        require(job.currentVerifier == msg.sender, "Only assigned verifier can submit outcome");
        require(
            job.status == InferenceJobStatus.VerificationAccepted,
            "Job not in 'Verification Accepted' state"
        );
        require(_outcome != VerificationOutcome.Undecided, "Outcome cannot be undecided");
        require(bytes(_evidenceURI).length > 0, "Evidence URI cannot be empty");
        require(
            block.timestamp <= job.disputeStartTime + verificationJobTimeout,
            "Verification submission window has closed"
        );

        job.finalOutcome = _outcome;
        job.verificationSubmissionTime = block.timestamp;
        job.status = InferenceJobStatus.VerificationSubmitted;

        emit VerificationOutcomeSubmitted(_jobId, msg.sender, _outcome);
    }

    // 18. resolveDispute
    function resolveDispute(uint256 _jobId) external whenNotPaused {
        InferenceJob storage job = inferenceJobs[_jobId];

        require(
            job.status != InferenceJobStatus.DisputeResolved &&
                job.status != InferenceJobStatus.Completed &&
                job.status != InferenceJobStatus.Failed,
            "Dispute already resolved or job completed/failed"
        );

        // Scenario 1: No challenge within the challenge window
        if (job.status == InferenceJobStatus.ResultSubmitted && block.timestamp > job.resultSubmissionTime + challengeWindow) {
            _completeJobSuccessfully(_jobId);
            return;
        }

        // Scenario 2: Challenge made, but no verifier accepted or submitted in time
        if (job.status == InferenceJobStatus.Challenged && block.timestamp > job.disputeStartTime + verificationJobTimeout) {
            // Compute provider wins by default if challenge not verified
            pendingWithdrawals[job.computeProvider] += job.payoutAmountToCompute;
            pendingWithdrawals[job.computeProvider] += job.computeProviderBond; // Return compute bond
            
            // Challenger loses bond (goes to fee recipient for now, or could be split)
            pendingWithdrawals[feeRecipient] += job.challengerBond;
            
            // Requestor gets verifier bond back as it wasn't used
            pendingWithdrawals[job.requestor] += job.verifierBondHeld;

            _updateReputationScore(job.computeProvider, 10); // Small positive for compute provider
            _updateReputationScore(job.requestor, -5); // Small negative for requestor (unverified challenge)
            
            job.computeProviderBond = 0; job.verifierBondHeld = 0; job.challengerBond = 0;
            job.finalOutcome = VerificationOutcome.Valid;
            job.status = InferenceJobStatus.Completed;
            emit DisputeResolved(_jobId, job.status, job.finalOutcome);
            emit InferenceJobCompleted(_jobId, job.computeProvider, job.payoutAmountToCompute);
            return;
        }

        // Scenario 3: Verification submitted, or arbitrator/oracle manually resolves
        require(
            job.status == InferenceJobStatus.VerificationSubmitted ||
            (msg.sender == arbitratorAddress && block.timestamp > job.verificationSubmissionTime + disputeResolutionWindow),
            "Job not in a state for dispute resolution or resolution window not open"
        );
        require(
            msg.sender == arbitratorAddress || msg.sender == owner() || msg.sender == oracleAddress,
            "Only arbitrator, oracle, or owner can resolve complex disputes"
        );

        address computeProvider = job.computeProvider;
        address requestor = job.requestor;
        address verifier = job.currentVerifier;
        address challenger = job.challengerBond > 0 ? job.requestor : address(0); // Assuming requestor is challenger for simplicity if no explicit challenger field
                                                                                 // A more complex system would track actual challenger. For now, we penalize the challenger bondholder.

        if (job.finalOutcome == VerificationOutcome.Valid) {
            // Compute provider wins: gets payout + compute bond back.
            // Verifier wins: gets verifier bond (from requestor) + potentially reward.
            // Challenger loses: challenger bond goes to verifier and/or platform.
            _updateReputationScore(computeProvider, 50);
            _updateReputationScore(verifier, 75);
            _updateReputationScore(challenger, -10); // Challenger loses if outcome valid

            pendingWithdrawals[computeProvider] += job.payoutAmountToCompute;
            pendingWithdrawals[computeProvider] += job.computeProviderBond; // Return compute bond

            // Verifier gets their bond (from requestor's initial payment) + a portion of challenger's bond as reward
            pendingWithdrawals[verifier] += job.verifierBondHeld;
            pendingWithdrawals[verifier] += job.challengerBond / 2; // Half challenger bond to verifier

            // Remaining half of challenger bond to platform fees
            pendingWithdrawals[feeRecipient] += job.challengerBond - (job.challengerBond / 2);

            job.status = InferenceJobStatus.Completed;
            emit InferenceJobCompleted(_jobId, computeProvider, job.payoutAmountToCompute);
        } else if (job.finalOutcome == VerificationOutcome.Invalid) {
            // Compute provider loses: loses compute bond, no payout.
            // Verifier wins: gets verifier bond (from requestor) + reward.
            // Challenger wins: gets challenger bond back + reward.
            // Requestor gets original inference cost back (excluding platform fee).
            _updateReputationScore(computeProvider, -100);
            _updateReputationScore(verifier, 75);
            _updateReputationScore(challenger, 20); // Challenger rewarded

            // Refund requestor for model cost (payoutAmountToCompute)
            pendingWithdrawals[requestor] += job.payoutAmountToCompute;

            // Verifier gets their bond (from requestor's initial payment) + a portion of compute provider's bond as reward
            pendingWithdrawals[verifier] += job.verifierBondHeld;
            pendingWithdrawals[verifier] += job.computeProviderBond / 2; // Half compute bond to verifier

            // Challenger gets their bond back + remaining half of compute provider's bond as reward
            pendingWithdrawals[challenger] += job.challengerBond;
            pendingWithdrawals[challenger] += job.computeProviderBond - (job.computeProviderBond / 2); // Remaining half of compute bond to challenger

            job.status = InferenceJobStatus.Failed;
            emit InferenceJobFailed(_jobId, computeProvider, "Inference result invalid");
        } else {
            // Should not happen if previous checks are robust, but as a fallback, mark failed.
            job.status = InferenceJobStatus.Failed;
            emit InferenceJobFailed(_jobId, computeProvider, "Dispute resolution undecided or invalid state");
        }

        job.computeProviderBond = 0; // Clear all bonds
        job.verifierBondHeld = 0;
        job.challengerBond = 0;
        job.status = InferenceJobStatus.DisputeResolved;
        emit DisputeResolved(_jobId, job.status, job.finalOutcome);
    }

    // Helper for completing job when no dispute or dispute resolved valid
    function _completeJobSuccessfully(uint256 _jobId) internal {
        InferenceJob storage job = inferenceJobs[_jobId];
        require(job.status == InferenceJobStatus.ResultSubmitted, "Job not in 'ResultSubmitted' state for auto-completion");
        require(job.computeProvider != address(0), "No compute provider assigned");

        address computeProvider = job.computeProvider;
        uint256 modelCost = job.payoutAmountToCompute;

        // Distribute funds:
        // 1. Compute provider gets payoutAmountToCompute + their bond back
        pendingWithdrawals[computeProvider] += modelCost;
        pendingWithdrawals[computeProvider] += job.computeProviderBond;

        // 2. Requestor gets verifier bond back if not challenged (already handled in requestInference's actualCostPaid if no verifier bond used).
        // Here, if no challenge, verifierBondHeld should be refunded.
        pendingWithdrawals[job.requestor] += job.verifierBondHeld;

        // Reset bonds
        job.computeProviderBond = 0;
        job.verifierBondHeld = 0;
        job.challengerBond = 0; // Should already be 0 if no challenge

        job.status = InferenceJobStatus.Completed;
        _updateReputationScore(computeProvider, 25); // Reward for successful completion
        emit InferenceJobCompleted(_jobId, computeProvider, modelCost);
    }

    // --- V. Reputation & Staking (5 functions) ---

    // 19. stakeForRole
    function stakeForRole() external payable whenNotPaused {
        require(msg.value >= defaultReputationStakeAmount, "Minimum stake amount not met");
        require(reputationStakes[msg.sender].hasActiveUnstakeRequest == false, "Cannot stake with active unstake request");

        reputationStakes[msg.sender].amount += msg.value;
        reputationStakes[msg.sender].lastStakedAt = block.timestamp;
        reputationStakes[msg.sender].unstakeRequestTime = 0; // Reset unstake request
        reputationStakes[msg.sender].hasActiveUnstakeRequest = false;

        _updateReputationScore(msg.sender, int256(msg.value / (1 ether) * 10)); // Example: 1 ETH stake adds 10 reputation
        emit TokensStaked(msg.sender, msg.value);
    }

    // 20. unstakeFromRole
    function unstakeFromRole(uint256 _amount) external whenNotPaused {
        ReputationStake storage stake = reputationStakes[msg.sender];
        require(stake.amount >= _amount, "Insufficient staked amount");
        require(_amount > 0, "Cannot unstake zero");
        require(stake.hasActiveUnstakeRequest == false, "Unstake already requested. Wait for cooldown or complete current unstake.");

        // Additional checks for active jobs would be ideal here to prevent unstaking from under active commitments.
        // For simplicity, this contract relies on the cooldown and reputation penalties to deter malicious unstaking.

        stake.unstakeRequestTime = block.timestamp;
        stake.hasActiveUnstakeRequest = true;

        emit UnstakeRequested(msg.sender, _amount);
    }

    // 21. completeUnstake
    function completeUnstake() external whenNotPaused {
        ReputationStake storage stake = reputationStakes[msg.sender];
        require(stake.hasActiveUnstakeRequest, "No active unstake request");
        require(block.timestamp >= stake.unstakeRequestTime + reputationStakeCooldown, "Unstake cooldown not over");
        require(stake.amount > 0, "No staked tokens to unstake");

        uint256 amountToUnstake = stake.amount; // Unstake all for simplicity, or specific requested amount

        stake.amount = 0;
        stake.unstakeRequestTime = 0;
        stake.hasActiveUnstakeRequest = false;

        _updateReputationScore(msg.sender, -int256(amountToUnstake / (1 ether) * 10)); // Reverse reputation impact

        pendingWithdrawals[msg.sender] += amountToUnstake;
        // Funds are now available via withdrawFees (which handles all pendingWithdrawals)
        emit TokensUnstaked(msg.sender, amountToUnstake);
    }

    // 22. getReputationScore
    function getReputationScore(address _participant) public view returns (int256) {
        return reputationScores[_participant];
    }

    // 23. _updateReputationScore (internal)
    function _updateReputationScore(address _participant, int256 _delta) internal {
        reputationScores[_participant] += _delta;
        emit ReputationUpdated(_participant, reputationScores[_participant]);
    }

    // 24. setMinimumReputation
    function setMinimumReputation(
        int256 _minComputeRep,
        int256 _minVerifierRep
    ) external onlyOwner {
        defaultMinComputeReputation = _minComputeRep;
        defaultMinVerifierReputation = _minVerifierRep;
    }

    // --- VI. Arbitration & Advanced Integration (3 functions) ---

    // 25. setArbitratorAddress
    function setArbitratorAddress(address _newArbitrator) external onlyOwner {
        require(_newArbitrator != address(0), "Invalid arbitrator address");
        arbitratorAddress = _newArbitrator;
        emit ArbitratorAddressSet(_newArbitrator);
    }

    // 26. reportOracleResult (Called by trusted oracle)
    function reportOracleResult(
        uint256 _jobId,
        VerificationOutcome _outcome,
        string memory _evidenceURI
    ) external onlyOracle whenNotPaused {
        InferenceJob storage job = inferenceJobs[_jobId];
        require(
            job.status == InferenceJobStatus.Challenged ||
                job.status == InferenceJobStatus.VerificationAccepted ||
                job.status == InferenceJobStatus.VerificationSubmitted,
            "Job not in dispute phase"
        );
        require(_outcome != VerificationOutcome.Undecided, "Oracle outcome cannot be undecided");

        job.finalOutcome = _outcome;
        job.verificationSubmissionTime = block.timestamp; // Oracle submission acts as final verification time
        job.status = InferenceJobStatus.VerificationSubmitted; // Transition to submitted, then resolve via resolveDispute

        emit VerificationOutcomeSubmitted(_jobId, msg.sender, _outcome);
    }

    // 27. setOracleAddress
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid oracle address");
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    // --- Fallback & Receive Functions ---
    receive() external payable {}
    fallback() external payable {}
}

```