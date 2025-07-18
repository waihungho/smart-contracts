This Solidity smart contract, **SynapseAI**, outlines a decentralized platform for collaborative AI model creation, training, validation, and licensing. It integrates several advanced concepts such as AI Model NFTs (AIM-NFTs), a reputation system, oracle-based proof of inference, multi-party collaboration with reward distribution, and an on-chain dispute resolution mechanism.

The design aims to be creative and trendy by combining elements from DeFi (staking, reward distribution, escrow-like funding), NFTs (for digital assets representing AI models), and decentralized computing/AI (managing training jobs, data contributions, and validation).

---

## SynapseAI: Decentralized AI Model Co-creation & Licensing Platform

### Core Concept:
SynapseAI is a decentralized platform enabling collaborative AI model creation, training, validation, and licensing. It connects AI model innovators, data providers, compute providers, and validators through a transparent, blockchain-governed ecosystem. Trained and validated AI models are tokenized as unique Non-Fungible Tokens (AIM-NFTs) for secure ownership and streamlined licensing.

### Advanced Concepts Integrated:
1.  **AI Model NFTs (AIM-NFTs):** Each trained, validated AI model is minted as a unique NFT, representing ownership and licensing rights.
2.  **Decentralized AI Training Orchestration:** Manages the lifecycle of AI training jobs from definition to completion, coordinating different participant roles.
3.  **Reputation System (via Staking):** Participants stake native tokens to signal commitment and build reputation, influencing job priority, trust, and dispute outcomes.
4.  **Proof of Inference (PoI) Integration (via Oracle):** Facilitates verifiable off-chain usage tracking for licensed models, enabling fair revenue distribution based on actual utilization.
5.  **Multi-Participant Collaboration & Reward Distribution:** Designed to incentivize various roles (data providers, compute providers, validators, model owners) through bounties, rewards, and revenue sharing.
6.  **Dispute Resolution Mechanism:** An on-chain system for initiating, voting on, and resolving conflicts related to data quality, compute integrity, or model validation, potentially involving slashing staked funds.
7.  **Dynamic Licensing & Royalty Management:** AIM-NFT owners can dynamically set licensing fees, and the protocol handles the secure collection and distribution of licensing revenue.

---

### Outline & Function Summary:

**I. Core Platform Registries & Management**
1.  `registerParticipant(string calldata _role, string calldata _metadataURI)`: Allows users to register as a data provider, compute provider, or validator, providing a metadata URI for their public profile.
2.  `updateParticipantMetadata(string calldata _metadataURI)`: Enables registered participants to update their profile metadata URI.
3.  `deactivateParticipant()`: Allows a participant to deactivate their account, potentially with a cool-down period or penalty (simplified here).
4.  `stakeForReputation(uint256 _amount)`: Participants stake the native Synapse Token (`SYNA`) to boost their reputation score, influencing job priority and trust within the platform.

**II. AI Model Definition & Training Lifecycle**
5.  `defineAIModelSpec(string calldata _modelIdHash, string calldata _specURI, uint256 _dataSizeRequired, uint256 _computeTimeRequired, uint256 _baseLicensingFee, uint256 _initialFunding)`: Model owners define a new AI model's specifications, required resources (data, compute), base licensing fee, and initial funding for training bounties/rewards.
6.  `initiateTrainingJob(uint256 _modelSpecId, uint256 _dataBountyPerUnit, uint256 _computeRewardPerUnit, uint256 _validatorReward)`: Model owners initiate a training job for a defined model specification, setting per-unit bounties for data and compute, and a reward for validators.
7.  `proposeComputeJob(uint256 _trainingJobId, uint256 _estimatedComputeUnits, string calldata _resourceURI)`: Compute providers propose to execute a specific training job, detailing their estimated computational resource commitment.
8.  `acceptComputeProposal(uint256 _computeProposalId)`: The model owner accepts a specific compute provider's proposal for their training job, transitioning the job to the `IN_COMPUTE` state.
9.  `submitTrainingResult(uint256 _computeJobId, string calldata _modelArtifactHash, uint256 _actualComputeUnits, string calldata _proofURI)`: The accepted compute provider submits the verifiable hash of the trained AI model artifacts and proof of computation, moving the job to `PENDING_VALIDATION`.

**III. Data Contribution & Validation**
10. `submitDataContribution(uint256 _trainingJobId, string calldata _dataHash, uint256 _dataSize, string calldata _metadataURI)`: Data providers submit a cryptographic hash and metadata URI of their contributed dataset for a specific training job.
11. `submitValidationResult(uint256 _trainingJobId, uint256 _entityId, string calldata _validationReportHash, uint256 _performanceScore, bool _isValid, string calldata _feedbackURI)`: Validators submit their assessment of a trained model's performance and integrity (if `_entityId` is 0) or the quality of a specific data contribution (if `_entityId` is a `dataContributionId`).

**IV. AI Model NFTs (AIM-NFTs) & Licensing**
12. `mintAIM_NFT(uint256 _trainingJobId, string calldata _tokenURI)`: Initiated by the protocol after successful training and validation, this function mints a unique AIM-NFT for the AI model owner, representing the fully validated model.
13. `setAIM_NFTLicensingFee(uint256 _tokenId, uint256 _newFee)`: Allows the AIM-NFT owner to adjust the licensing fee for their model.
14. `licenseAIM_NFT(uint256 _tokenId, uint256 _durationInDays)`: Enables consumers to license an AIM-NFT for a specified duration, paying the associated fee in Synapse Tokens.
15. `submitProofOfInference(uint256 _licenseId, uint256 _inferenceCount, string calldata _proofURI)`: (Intended to be triggered by an Oracle) Allows for verifiable reporting of off-chain model usage (inference count) to track licensing revenue based on actual consumption.
16. `distributeLicenseRevenue(uint256 _licenseId)`: Distributes accumulated licensing revenue (minus protocol fees) to the AIM-NFT owner.

**V. Dispute Resolution & Slashing**
17. `initiateDispute(uint256 _entityId, DisputeType _type, string calldata _reasonURI)`: Allows participants (or relevant parties) to formally dispute data quality, compute results, or validation outcomes for a specific entity.
18. `voteOnDispute(uint256 _disputeId, bool _supportForInitiator)`: Registered validators (and potentially other governance participants) vote to resolve ongoing disputes, weighing their vote by reputation stake.
19. `resolveDispute(uint256 _disputeId)`: Executes the outcome of a dispute based on voting results, potentially involving slashing staked tokens from the responsible or malicious party, or releasing escrowed funds.

**VI. Reward & Fund Management**
20. `claimAccruedRewards()`: Allows participants to claim their earned rewards from various contributions (data bounties, compute rewards, validation rewards, licensing revenue shares).
21. `withdrawModelFunding(uint256 _modelSpecId)`: Model owners can withdraw any unused initial funding for a model specification if the training job is successfully completed under budget or cancelled.
22. `updateProtocolFee(uint256 _newFeePercentage)`: (Governance function, callable by `Ownable` owner) Updates the percentage of platform fees collected from licensing revenue.

---
**Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SynapseAI is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    IERC20 public synapseToken; // The native token for staking, payments, and rewards
    address public immutable protocolTreasury; // Address for collecting protocol fees
    uint256 public protocolFeePercentage; // Percentage of licensing fees taken by the protocol (e.g., 500 for 5%)

    // Counters for unique IDs
    Counters.Counter private _participantIds; // Not strictly needed for mapping by address but good for consistency
    Counters.Counter private _modelSpecIds;
    Counters.Counter private _trainingJobIds;
    Counters.Counter private _dataContributionIds;
    Counters.Counter private _computeProposalIds;
    Counters.Counter private _validationResultIds;
    Counters.Counter private _licenseIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _aimNFTTokenIds; // Separate counter for ERC721 tokens

    // Mappings for data storage
    mapping(address => Participant) public participants;
    mapping(address => bool) public isParticipantRegistered; // Quick lookup
    mapping(uint256 => ModelSpec) public modelSpecs;
    mapping(uint256 => TrainingJob) public trainingJobs;
    mapping(uint256 => DataContribution) public dataContributions;
    mapping(uint256 => ComputeProposal) public computeProposals;
    mapping(uint256 => ValidationResult) public validationResults;
    mapping(uint256 => AIM_NFT_License) public aimNFTLicenses;
    mapping(uint256 => Dispute) public disputes;

    // Mapping to track accumulated rewards for participants
    mapping(address => uint256) public accruedRewards;

    // Mapping to link AIM-NFT tokenId to ModelSpecId and vice-versa
    mapping(uint256 => uint256) public aimNFTToModelSpecId;
    mapping(uint256 => uint256) public modelSpecIdToAIMNFT;


    // --- Enums ---

    enum ParticipantRole { NONE, MODEL_OWNER, DATA_PROVIDER, COMPUTE_PROVIDER, VALIDATOR }
    enum JobStatus { DEFINED, PENDING_DATA_COMPUTE, IN_COMPUTE, PENDING_VALIDATION, COMPLETED, CANCELLED }
    enum DisputeType { DATA_QUALITY, COMPUTE_INTEGRITY, VALIDATION_ACCURACY }
    enum DisputeStatus { OPEN, VOTING, RESOLVED_ACCEPTED, RESOLVED_REJECTED }


    // --- Structs ---

    struct Participant {
        address walletAddress;
        ParticipantRole role;
        string metadataURI;
        bool isActive;
        uint256 reputationStake;
        // accruedRewards is managed by a separate mapping for gas efficiency
    }

    struct ModelSpec {
        uint256 id;
        address owner;
        string modelIdHash; // Verifiable hash of the abstract model ID (e.g., IPFS CID of a model hash)
        string specURI;     // URI to detailed model specification (e.g., IPFS CID)
        uint256 dataSizeRequired; // Expected data size in abstract units (e.g., MB, number of samples)
        uint256 computeTimeRequired; // Expected compute time in abstract units (e.g., CPU-hours, GPU-hours)
        uint256 baseLicensingFee; // Base fee per licensing period (in SynapseToken wei)
        uint256 initialFunding; // Funds provided by model owner for training (in SynapseToken wei)
        uint256 fundsSpent;     // Track funds used for training bounties/rewards (in SynapseToken wei)
        bool isCompleted;       // True if model has been successfully trained and validated and NFT minted
        uint256 aimNFTTokenId;  // Link to the minted AIM-NFT (0 if not minted)
    }

    struct TrainingJob {
        uint256 id;
        uint256 modelSpecId;
        address modelOwner;
        JobStatus status;
        uint256 dataBountyPerUnit; // Per unit of data (e.g., per MB)
        uint256 computeRewardPerUnit; // Per unit of compute (e.g., per CPU-hour)
        uint256 validatorReward; // Flat reward for successful validation
        uint256 totalDataUnitsContributed; // Sum of dataSizes (for tracking, not payment)
        uint256 totalComputeUnitsExecuted; // Sum of actualComputeUnits (for tracking, not payment)
        address finalModelComputeProvider; // Address of the compute provider who submitted final model
        address finalModelValidator; // Address of the validator who validated the final model
        string finalModelArtifactHash; // Hash of the final trained model
        uint256 escrowedFunds; // Funds for this job, paid out upon completion. (Simplified, funds stay in ModelSpec.initialFunding until spent)
        // mapping(uint256 => bool) acceptedDataContributions; // To track specific data contributions for this job (simplified not in use to avoid complexity)
        // mapping(uint256 => bool) validatedDataContributions; // To track specific data contributions validated (simplified not in use to avoid complexity)
    }

    struct DataContribution {
        uint256 id;
        uint256 trainingJobId;
        address contributor;
        string dataHash; // Hash of the dataset
        uint256 dataSize; // Actual size contributed
        string metadataURI; // URI to data details
        bool isApproved; // If model owner/validator approved its relevance for the job
        bool isValidated; // If validator confirmed quality
        uint256 rewardAmount; // Calculated reward for this specific contribution (accrued only upon validation)
    }

    struct ComputeProposal {
        uint256 id;
        uint256 trainingJobId;
        address provider;
        uint256 estimatedComputeUnits;
        string resourceURI; // URI to compute resource details/proof setup
        bool accepted;
        bool completed;
        string submittedModelArtifactHash; // Hash of the model after this compute
        uint256 actualComputeUnits;
        string proofURI; // URI to proof of computation
        uint256 rewardAmount; // Calculated reward for this specific compute
    }

    struct ValidationResult {
        uint256 id;
        uint256 trainingJobId;
        uint256 entityId; // Can be dataContributionId or computeProposalId (for full model validation)
        DisputeType validatedEntityType; // To know what entityId refers to
        address validator;
        string validationReportHash; // URI to detailed validation report
        uint256 performanceScore; // Numerical score, higher is better (e.g., accuracy percentage * 100)
        bool isValid; // True if validation passes minimum criteria
        string feedbackURI;
        uint256 rewardAmount; // Calculated reward for this validation (for validator)
    }

    struct AIM_NFT_License {
        uint256 id;
        uint256 aimNFTTokenId;
        address licensee;
        uint256 startTime;
        uint256 endTime;
        uint256 paidFee;
        uint256 inferenceCount; // Incremented by oracle via submitProofOfInference
        uint256 totalRevenueShareDistributed;
        bool isActive;
    }

    struct Dispute {
        uint256 id;
        uint256 entityId; // ID of the related DataContribution, ComputeProposal, or ValidationResult
        DisputeType disputeType;
        address initiator;
        string reasonURI; // URI to detailed reason for dispute
        DisputeStatus status;
        uint256 votesForInitiator;
        uint256 votesAgainstInitiator;
        uint256 totalReputationStakedFor; // Sum of reputation stakes of voting validators
        uint256 totalReputationStakedAgainst;
        mapping(address => bool) hasVoted; // Tracks if a validator has voted
        uint256 resolutionTimestamp; // Timestamp when dispute was resolved
        bool outcomeForInitiator; // True if dispute resolved in favor of initiator
    }


    // --- Events ---

    event ParticipantRegistered(address indexed walletAddress, ParticipantRole role, string metadataURI);
    event ParticipantUpdated(address indexed walletAddress, string metadataURI);
    event ParticipantDeactivated(address indexed walletAddress);
    event ReputationStaked(address indexed participant, uint256 amount, uint256 newReputation);

    event ModelSpecDefined(uint256 indexed modelSpecId, address indexed owner, string modelIdHash, uint256 initialFunding);
    event TrainingJobInitiated(uint256 indexed trainingJobId, uint256 indexed modelSpecId, address indexed modelOwner);
    event ComputeJobProposed(uint256 indexed computeProposalId, uint256 indexed trainingJobId, address indexed provider);
    event ComputeProposalAccepted(uint256 indexed computeProposalId, uint256 indexed trainingJobId, address indexed provider);
    event TrainingResultSubmitted(uint256 indexed computeJobId, address indexed provider, string modelArtifactHash);
    event ModelTrainingCompleted(uint256 indexed modelSpecId, uint256 indexed trainingJobId, string finalModelArtifactHash);

    event DataContributionSubmitted(uint256 indexed dataContributionId, uint256 indexed trainingJobId, address indexed contributor, uint256 dataSize);
    event DataQualityValidated(uint256 indexed dataContributionId, address indexed validator, bool isValid);
    event ValidationResultSubmitted(uint256 indexed validationResultId, uint256 indexed trainingJobId, address indexed validator, uint256 performanceScore, bool isValid);

    event AIM_NFT_Minted(uint256 indexed tokenId, uint256 indexed modelSpecId, address indexed modelOwner);
    event AIM_NFT_LicensingFeeUpdated(uint256 indexed tokenId, uint256 newFee);
    event AIM_NFT_Licensed(uint256 indexed licenseId, uint256 indexed tokenId, address indexed licensee, uint256 durationInDays, uint256 feePaid);
    event ProofOfInferenceSubmitted(uint256 indexed licenseId, uint256 inferenceCount);
    event LicenseRevenueDistributed(uint256 indexed licenseId, uint256 amountDistributed);

    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed entityId, DisputeType disputeType, address indexed initiator);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool supportForInitiator);
    event DisputeResolved(uint256 indexed disputeId, bool outcomeForInitiator, string resolutionURI);
    event FundsSlashing(address indexed slashedAddress, uint256 amount);

    event RewardsClaimed(address indexed claimant, uint256 amount);
    event ModelFundingWithdrawal(uint256 indexed modelSpecId, address indexed owner, uint256 amount);
    event ProtocolFeeUpdated(uint256 newFeePercentage);


    // --- Modifiers ---

    modifier onlyRole(ParticipantRole _role) {
        require(isParticipantRegistered[_msgSender()], "Caller is not a registered participant.");
        require(participants[_msgSender()].isActive, "Participant account is inactive.");
        require(participants[_msgSender()].role == _role, "Unauthorized: Incorrect role.");
        _;
    }

    modifier onlyRegisteredParticipant() {
        require(isParticipantRegistered[_msgSender()], "Caller is not a registered participant.");
        require(participants[_msgSender()].isActive, "Participant account is inactive.");
        _;
    }

    modifier onlyAIM_NFTOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "AIM-NFT does not exist.");
        require(ownerOf(_tokenId) == _msgSender(), "Caller is not the owner of this AIM-NFT.");
        _;
    }

    // --- Constructor ---

    constructor(address _synapseTokenAddress, address _protocolTreasury)
        ERC721("Synapse AI Model NFT", "AIM-NFT")
        Ownable(_msgSender())
    {
        require(_synapseTokenAddress != address(0), "Invalid Synapse Token address");
        require(_protocolTreasury != address(0), "Invalid Protocol Treasury address");
        synapseToken = IERC20(_synapseTokenAddress);
        protocolTreasury = _protocolTreasury;
        protocolFeePercentage = 500; // Default to 5% (500 basis points)
    }

    // --- I. Core Platform Registries & Management ---

    /**
     * @notice Registers a new participant with a specific role and metadata.
     * @param _role The role of the participant ("MODEL_OWNER", "DATA_PROVIDER", "COMPUTE_PROVIDER", "VALIDATOR").
     * @param _metadataURI URI pointing to off-chain metadata about the participant.
     */
    function registerParticipant(string calldata _role, string calldata _metadataURI) public nonReentrant {
        require(!isParticipantRegistered[_msgSender()], "Already registered.");
        
        ParticipantRole pRole;
        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("MODEL_OWNER"))) {
            pRole = ParticipantRole.MODEL_OWNER;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("DATA_PROVIDER"))) {
            pRole = ParticipantRole.DATA_PROVIDER;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("COMPUTE_PROVIDER"))) {
            pRole = ParticipantRole.COMPUTE_PROVIDER;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("VALIDATOR"))) {
            pRole = ParticipantRole.VALIDATOR;
        } else {
            revert("Invalid participant role.");
        }

        participants[_msgSender()] = Participant({
            walletAddress: _msgSender(),
            role: pRole,
            metadataURI: _metadataURI,
            isActive: true,
            reputationStake: 0 // Will be added via stakeForReputation
        });
        isParticipantRegistered[_msgSender()] = true;
        emit ParticipantRegistered(_msgSender(), pRole, _metadataURI);
    }

    /**
     * @notice Allows a registered participant to update their profile metadata URI.
     * @param _metadataURI New URI pointing to updated off-chain metadata.
     */
    function updateParticipantMetadata(string calldata _metadataURI) public onlyRegisteredParticipant {
        participants[_msgSender()].metadataURI = _metadataURI;
        emit ParticipantUpdated(_msgSender(), _metadataURI);
    }

    /**
     * @notice Allows a registered participant to deactivate their account.
     *         Future enhancements could include cool-down periods or penalty.
     */
    function deactivateParticipant() public onlyRegisteredParticipant {
        participants[_msgSender()].isActive = false;
        // Optionally, return staked reputation or pending rewards after a cool-down
        emit ParticipantDeactivated(_msgSender());
    }

    /**
     * @notice Participants stake Synapse Tokens to boost their reputation score.
     * @param _amount The amount of Synapse Tokens to stake.
     */
    function stakeForReputation(uint256 _amount) public onlyRegisteredParticipant nonReentrant {
        require(_amount > 0, "Stake amount must be greater than zero.");
        require(synapseToken.transferFrom(_msgSender(), address(this), _amount), "Token transfer failed. Check allowance.");

        participants[_msgSender()].reputationStake += _amount;
        emit ReputationStaked(_msgSender(), _amount, participants[_msgSender()].reputationStake);
    }

    // --- II. AI Model Definition & Training Lifecycle ---

    /**
     * @notice Model owner defines a new AI model's specifications and provides initial funding for training.
     * @param _modelIdHash Verifiable hash (e.g., IPFS CID) of the abstract model ID.
     * @param _specURI URI pointing to detailed model specification.
     * @param _dataSizeRequired Expected data size in abstract units (e.g., MB).
     * @param _computeTimeRequired Expected compute time in abstract units (e.g., CPU-hours).
     * @param _baseLicensingFee Base fee per licensing period (in SynapseToken wei).
     * @param _initialFunding Funds provided by model owner for training (in SynapseToken wei).
     */
    function defineAIModelSpec(
        string calldata _modelIdHash,
        string calldata _specURI,
        uint256 _dataSizeRequired,
        uint256 _computeTimeRequired,
        uint256 _baseLicensingFee,
        uint256 _initialFunding
    ) public onlyRole(ParticipantRole.MODEL_OWNER) nonReentrant {
        _modelSpecIds.increment();
        uint256 newModelSpecId = _modelSpecIds.current();

        require(synapseToken.transferFrom(_msgSender(), address(this), _initialFunding), "Funding transfer failed. Check allowance.");

        modelSpecs[newModelSpecId] = ModelSpec({
            id: newModelSpecId,
            owner: _msgSender(),
            modelIdHash: _modelIdHash,
            specURI: _specURI,
            dataSizeRequired: _dataSizeRequired,
            computeTimeRequired: _computeTimeRequired,
            baseLicensingFee: _baseLicensingFee,
            initialFunding: _initialFunding,
            fundsSpent: 0,
            isCompleted: false,
            aimNFTTokenId: 0
        });

        emit ModelSpecDefined(newModelSpecId, _msgSender(), _modelIdHash, _initialFunding);
    }

    /**
     * @notice Model owner initiates a training job for a defined model, setting bounties for participants.
     * @param _modelSpecId The ID of the model specification to train.
     * @param _dataBountyPerUnit Reward per unit of data contributed.
     * @param _computeRewardPerUnit Reward per unit of compute executed.
     * @param _validatorReward Reward for successful final model validation.
     */
    function initiateTrainingJob(
        uint256 _modelSpecId,
        uint256 _dataBountyPerUnit,
        uint256 _computeRewardPerUnit,
        uint256 _validatorReward
    ) public onlyRole(ParticipantRole.MODEL_OWNER) nonReentrant {
        ModelSpec storage modelSpec = modelSpecs[_modelSpecId];
        require(modelSpec.id != 0, "Model specification not found.");
        require(modelSpec.owner == _msgSender(), "Caller is not the model owner.");
        require(!modelSpec.isCompleted, "Model already completed training and minted.");

        // Simple check for sufficient funding
        uint256 estimatedMaxCost = (modelSpec.dataSizeRequired * _dataBountyPerUnit) +
                                   (modelSpec.computeTimeRequired * _computeRewardPerUnit) +
                                   _validatorReward;
        require(modelSpec.initialFunding >= modelSpec.fundsSpent + estimatedMaxCost, "Insufficient funding for job.");

        _trainingJobIds.increment();
        uint256 newTrainingJobId = _trainingJobIds.current();

        trainingJobs[newTrainingJobId] = TrainingJob({
            id: newTrainingJobId,
            modelSpecId: _modelSpecId,
            modelOwner: _msgSender(),
            status: JobStatus.PENDING_DATA_COMPUTE,
            dataBountyPerUnit: _dataBountyPerUnit,
            computeRewardPerUnit: _computeRewardPerUnit,
            validatorReward: _validatorReward,
            totalDataUnitsContributed: 0,
            totalComputeUnitsExecuted: 0,
            finalModelComputeProvider: address(0),
            finalModelValidator: address(0),
            finalModelArtifactHash: "",
            escrowedFunds: 0
        });
        // For simplicity, we link the trainingJobId to the modelSpecId directly for retrieval.
        // In a more complex system, one modelSpec might have multiple training jobs over time.
        modelSpecIdToAIMNFT[_modelSpecId] = newTrainingJobId; // Using this mapping as a proxy to link spec to its current active job

        emit TrainingJobInitiated(newTrainingJobId, _modelSpecId, _msgSender());
    }

    /**
     * @notice Compute providers propose to execute a training job, specifying estimated compute units.
     * @param _trainingJobId The ID of the training job to propose for.
     * @param _estimatedComputeUnits The compute provider's estimated units to complete the job.
     * @param _resourceURI URI to details about the compute resource/setup.
     */
    function proposeComputeJob(
        uint256 _trainingJobId,
        uint256 _estimatedComputeUnits,
        string calldata _resourceURI
    ) public onlyRole(ParticipantRole.COMPUTE_PROVIDER) nonReentrant {
        TrainingJob storage job = trainingJobs[_trainingJobId];
        require(job.id != 0, "Training job not found.");
        require(job.status == JobStatus.PENDING_DATA_COMPUTE, "Job not in pending state for compute proposals.");

        _computeProposalIds.increment();
        uint256 newComputeProposalId = _computeProposalIds.current();

        computeProposals[newComputeProposalId] = ComputeProposal({
            id: newComputeProposalId,
            trainingJobId: _trainingJobId,
            provider: _msgSender(),
            estimatedComputeUnits: _estimatedComputeUnits,
            resourceURI: _resourceURI,
            accepted: false,
            completed: false,
            submittedModelArtifactHash: "",
            actualComputeUnits: 0,
            proofURI: "",
            rewardAmount: 0
        });

        emit ComputeJobProposed(newComputeProposalId, _trainingJobId, _msgSender());
    }

    /**
     * @notice Model owner accepts a compute provider's proposal.
     *         Only one proposal can be accepted for simplicity per job.
     * @param _computeProposalId The ID of the compute proposal to accept.
     */
    function acceptComputeProposal(uint256 _computeProposalId) public onlyRole(ParticipantRole.MODEL_OWNER) nonReentrant {
        ComputeProposal storage proposal = computeProposals[_computeProposalId];
        require(proposal.id != 0, "Compute proposal not found.");
        TrainingJob storage job = trainingJobs[proposal.trainingJobId];
        require(job.id != 0, "Training job not found.");
        require(job.modelOwner == _msgSender(), "Caller is not the model owner for this job.");
        require(job.status == JobStatus.PENDING_DATA_COMPUTE, "Job is not in pending state for compute acceptance.");
        require(!proposal.accepted, "Compute proposal already accepted.");

        proposal.accepted = true;
        job.status = JobStatus.IN_COMPUTE; // Transition job status

        emit ComputeProposalAccepted(_computeProposalId, proposal.trainingJobId, proposal.provider);
    }

    /**
     * @notice Compute provider submits the result of a completed training job.
     * @param _computeProposalId The ID of the accepted compute proposal.
     * @param _modelArtifactHash Hash of the final trained AI model artifacts.
     * @param _actualComputeUnits Actual compute units consumed for the training.
     * @param _proofURI URI to proof of computation.
     */
    function submitTrainingResult(
        uint256 _computeProposalId,
        string calldata _modelArtifactHash,
        uint256 _actualComputeUnits,
        string calldata _proofURI
    ) public onlyRole(ParticipantRole.COMPUTE_PROVIDER) nonReentrant {
        ComputeProposal storage proposal = computeProposals[_computeProposalId];
        require(proposal.id != 0, "Compute proposal not found.");
        require(proposal.provider == _msgSender(), "Caller is not the compute provider for this proposal.");
        require(proposal.accepted, "Compute proposal not accepted.");
        require(!proposal.completed, "Compute proposal already completed.");

        TrainingJob storage job = trainingJobs[proposal.trainingJobId];
        require(job.id != 0, "Training job not found.");
        require(job.status == JobStatus.IN_COMPUTE, "Training job not in compute state.");

        proposal.completed = true;
        proposal.submittedModelArtifactHash = _modelArtifactHash;
        proposal.actualComputeUnits = _actualComputeUnits;
        proposal.proofURI = _proofURI;
        proposal.rewardAmount = _actualComputeUnits * job.computeRewardPerUnit;

        // Update overall job stats
        job.totalComputeUnitsExecuted += _actualComputeUnits;
        job.finalModelComputeProvider = _msgSender();
        job.finalModelArtifactHash = _modelArtifactHash;
        job.status = JobStatus.PENDING_VALIDATION; // Move to validation phase

        // Funds are spent from initial funding of the ModelSpec
        ModelSpec storage modelSpec = modelSpecs[job.modelSpecId];
        modelSpec.fundsSpent += proposal.rewardAmount;
        require(modelSpec.fundsSpent <= modelSpec.initialFunding, "Compute reward exceeds model funding.");

        // Accrue rewards for the compute provider
        accruedRewards[_msgSender()] += proposal.rewardAmount;

        emit TrainingResultSubmitted(_computeProposalId, _msgSender(), _modelArtifactHash);
        emit ModelTrainingCompleted(job.modelSpecId, job.id, _modelArtifactHash);
    }


    // --- III. Data Contribution & Validation ---

    /**
     * @notice Data providers submit a cryptographic hash and metadata URI of their contributed dataset.
     * @param _trainingJobId The ID of the training job for which data is contributed.
     * @param _dataHash Cryptographic hash of the dataset.
     * @param _dataSize Actual size of the data contributed.
     * @param _metadataURI URI to data details or manifest.
     */
    function submitDataContribution(
        uint256 _trainingJobId,
        string calldata _dataHash,
        uint256 _dataSize,
        string calldata _metadataURI
    ) public onlyRole(ParticipantRole.DATA_PROVIDER) nonReentrant {
        TrainingJob storage job = trainingJobs[_trainingJobId];
        require(job.id != 0, "Training job not found.");
        require(job.status == JobStatus.PENDING_DATA_COMPUTE, "Data contributions only accepted in pending state.");
        require(_dataSize > 0, "Data size must be positive.");

        _dataContributionIds.increment();
        uint256 newDataContributionId = _dataContributionIds.current();

        dataContributions[newDataContributionId] = DataContribution({
            id: newDataContributionId,
            trainingJobId: _trainingJobId,
            contributor: _msgSender(),
            dataHash: _dataHash,
            dataSize: _dataSize,
            metadataURI: _metadataURI,
            isApproved: false, // Model owner or validators would approve this
            isValidated: false,
            isValid: false,
            rewardAmount: _dataSize * job.dataBountyPerUnit
        });

        job.totalDataUnitsContributed += _dataSize; // Track sum of contributed data for job progress

        emit DataContributionSubmitted(newDataContributionId, _trainingJobId, _msgSender(), _dataSize);
    }

    /**
     * @notice Validators submit their assessment of a trained model's performance/integrity or data quality.
     * @param _trainingJobId The ID of the related training job.
     * @param _entityId Can be `0` for final model validation, or a `dataContributionId` for data quality validation.
     * @param _validationReportHash URI to detailed validation report.
     * @param _performanceScore Numerical score for model performance (e.g., accuracy * 100).
     * @param _isValid True if validation passes minimum criteria.
     * @param _feedbackURI URI to additional feedback.
     */
    function submitValidationResult(
        uint256 _trainingJobId,
        uint256 _entityId, // 0 for model, dataContributionId for data
        string calldata _validationReportHash,
        uint256 _performanceScore,
        bool _isValid,
        string calldata _feedbackURI
    ) public onlyRole(ParticipantRole.VALIDATOR) nonReentrant {
        TrainingJob storage job = trainingJobs[_trainingJobId];
        require(job.id != 0, "Training job not found.");
        
        _validationResultIds.increment();
        uint256 newValidationResultId = _validationResultIds.current();

        DisputeType validationType;
        uint256 rewardToAccrue = 0;

        if (_entityId == 0) { // Validation for the final trained model
            require(job.status == JobStatus.PENDING_VALIDATION, "Job not in model validation phase.");
            require(job.finalModelComputeProvider != address(0), "No final model result to validate.");
            validationType = DisputeType.COMPUTE_INTEGRITY; // Represents the overall model quality
            
            // Only one validator is assigned for the final model in this simplified example
            require(job.finalModelValidator == address(0) || job.finalModelValidator == _msgSender(), "Final model already validated or assigned.");
            job.finalModelValidator = _msgSender();

            if (_isValid) {
                rewardToAccrue = job.validatorReward;
                ModelSpec storage modelSpec = modelSpecs[job.modelSpecId];
                modelSpec.fundsSpent += rewardToAccrue;
                require(modelSpec.fundsSpent <= modelSpec.initialFunding, "Validator reward exceeds model funding.");
                accruedRewards[_msgSender()] += rewardToAccrue;
                job.status = JobStatus.COMPLETED; // Training job officially completed!
            } else {
                // If model validation fails, it can be disputed, or the model owner can decide to restart/cancel
                // For this simplified example, it stays in PENDING_VALIDATION or requires a dispute.
            }
        } else { // Validation for a specific Data Contribution
            require(job.status == JobStatus.PENDING_DATA_COMPUTE, "Data contribution validation only allowed in pending data/compute state.");
            DataContribution storage dc = dataContributions[_entityId];
            require(dc.id != 0 && dc.trainingJobId == _trainingJobId, "Data contribution not found or mismatched job.");
            require(!dc.isValidated, "Data contribution already validated.");
            validationType = DisputeType.DATA_QUALITY;

            dc.isValidated = true;
            dc.isValid = _isValid;

            if (_isValid) {
                dc.isApproved = true; // Data is approved for use in training
                rewardToAccrue = dc.rewardAmount;
                ModelSpec storage modelSpec = modelSpecs[job.modelSpecId];
                modelSpec.fundsSpent += rewardToAccrue;
                require(modelSpec.fundsSpent <= modelSpec.initialFunding, "Data reward exceeds model funding.");
                accruedRewards[dc.contributor] += rewardToAccrue;
                emit DataQualityValidated(dc.id, _msgSender(), true);
            } else {
                emit DataQualityValidated(dc.id, _msgSender(), false);
            }
        }

        validationResults[newValidationResultId] = ValidationResult({
            id: newValidationResultId,
            trainingJobId: _trainingJobId,
            entityId: _entityId,
            validatedEntityType: validationType,
            validator: _msgSender(),
            validationReportHash: _validationReportHash,
            performanceScore: _performanceScore,
            isValid: _isValid,
            feedbackURI: _feedbackURI,
            rewardAmount: rewardToAccrue // Amount received by this specific validator for this validation
        });

        emit ValidationResultSubmitted(newValidationResultId, _trainingJobId, _msgSender(), _performanceScore, _isValid);
    }


    // --- IV. AI Model NFTs (AIM-NFTs) & Licensing ---

    /**
     * @notice Mints a unique AIM-NFT for the AI model owner after successful training and validation.
     *         Callable by the model owner once the training job is in `COMPLETED` status.
     * @param _trainingJobId The ID of the completed training job.
     * @param _tokenURI URI pointing to the AIM-NFT's metadata.
     */
    function mintAIM_NFT(uint256 _trainingJobId, string calldata _tokenURI) public nonReentrant {
        TrainingJob storage job = trainingJobs[_trainingJobId];
        require(job.id != 0, "Training job not found.");
        require(job.modelOwner == _msgSender(), "Caller is not the model owner for this job.");
        require(job.status == JobStatus.COMPLETED, "Training job not completed or validated.");

        ModelSpec storage modelSpec = modelSpecs[job.modelSpecId];
        require(!modelSpec.isCompleted, "AIM-NFT already minted for this model.");
        
        _aimNFTTokenIds.increment();
        uint256 newTokenId = _aimNFTTokenIds.current();

        _safeMint(_msgSender(), newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        modelSpec.isCompleted = true;
        modelSpec.aimNFTTokenId = newTokenId;
        aimNFTToModelSpecId[newTokenId] = modelSpec.id; // Link NFT to model spec
        modelSpecIdToAIMNFT[modelSpec.id] = newTokenId; // Link model spec back to NFT

        emit AIM_NFT_Minted(newTokenId, modelSpec.id, _msgSender());
    }

    /**
     * @notice Allows the AIM-NFT owner to adjust the licensing fee for their model.
     * @param _tokenId The ID of the AIM-NFT.
     * @param _newFee The new base licensing fee in SynapseToken wei.
     */
    function setAIM_NFTLicensingFee(uint256 _tokenId, uint256 _newFee) public onlyAIM_NFTOwner(_tokenId) nonReentrant {
        uint256 modelSpecId = aimNFTToModelSpecId[_tokenId];
        require(modelSpecId != 0, "AIM-NFT not linked to a model spec.");
        ModelSpec storage modelSpec = modelSpecs[modelSpecId];
        require(modelSpec.aimNFTTokenId == _tokenId, "AIM-NFT ID mismatch in storage.");

        modelSpec.baseLicensingFee = _newFee;
        emit AIM_NFT_LicensingFeeUpdated(_tokenId, _newFee);
    }

    /**
     * @notice Enables consumers to license an AIM-NFT for a specified duration.
     * @param _tokenId The ID of the AIM-NFT to license.
     * @param _durationInDays The duration of the license in days.
     */
    function licenseAIM_NFT(uint256 _tokenId, uint256 _durationInDays) public nonReentrant {
        uint256 modelSpecId = aimNFTToModelSpecId[_tokenId];
        require(modelSpecId != 0, "AIM-NFT not found or linked.");
        ModelSpec storage modelSpec = modelSpecs[modelSpecId];
        require(modelSpec.isCompleted, "Model associated with this NFT is not fully validated or minted.");
        require(modelSpec.baseLicensingFee > 0, "Licensing fee not set or is zero.");
        require(_durationInDays > 0, "Licensing duration must be positive.");
        
        uint256 totalFee = modelSpec.baseLicensingFee * _durationInDays; // Simple daily fee structure
        require(synapseToken.transferFrom(_msgSender(), address(this), totalFee), "Licensing fee transfer failed. Check allowance.");

        _licenseIds.increment();
        uint256 newLicenseId = _licenseIds.current();

        aimNFTLicenses[newLicenseId] = AIM_NFT_License({
            id: newLicenseId,
            aimNFTTokenId: _tokenId,
            licensee: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + (_durationInDays * 1 days),
            paidFee: totalFee,
            inferenceCount: 0,
            totalRevenueShareDistributed: 0,
            isActive: true
        });

        // Protocol fee is taken immediately from the totalFee
        uint256 protocolShare = (totalFee * protocolFeePercentage) / 10000; // E.g., 500/10000 = 5%
        if (protocolShare > 0) {
            require(synapseToken.transfer(protocolTreasury, protocolShare), "Protocol fee transfer to treasury failed.");
        }

        emit AIM_NFT_Licensed(newLicenseId, _tokenId, _msgSender(), _durationInDays, totalFee);
    }

    /**
     * @notice Allows a trusted oracle to submit proof of off-chain model usage (inferences).
     * @param _licenseId The ID of the active license.
     * @param _inferenceCount The number of inferences made since last report.
     * @param _proofURI URI to the verifiable proof of inference.
     */
    function submitProofOfInference(
        uint256 _licenseId,
        uint256 _inferenceCount,
        string calldata _proofURI
    ) public nonReentrant {
        // In a production environment, this function would be restricted to an authorized oracle
        // (e.g., using `onlyOracle` modifier with a pre-configured oracle address).
        // For this example, it's public.
        
        AIM_NFT_License storage license = aimNFTLicenses[_licenseId];
        require(license.id != 0, "License not found.");
        require(license.isActive, "License is not active.");
        require(block.timestamp <= license.endTime, "License has expired.");
        
        license.inferenceCount += _inferenceCount; // Cumulative inference count
        // _proofURI would be used off-chain for auditing/verification.
        
        emit ProofOfInferenceSubmitted(_licenseId, _inferenceCount);
    }

    /**
     * @notice Distributes accumulated licensing revenue from a given license.
     *         The main portion (after protocol fee) goes to the AIM-NFT owner.
     * @param _licenseId The ID of the license for which to distribute revenue.
     */
    function distributeLicenseRevenue(uint256 _licenseId) public nonReentrant {
        AIM_NFT_License storage license = aimNFTLicenses[_licenseId];
        require(license.id != 0, "License not found.");
        
        // Calculate amount available for distribution to model owner
        uint256 totalRevenueCollected = license.paidFee;
        uint256 protocolShare = (totalRevenueCollected * protocolFeePercentage) / 10000;
        uint256 totalRevenueForModelOwner = totalRevenueCollected - protocolShare;

        // Ensure we don't double distribute
        uint256 remainingToDistribute = totalRevenueForModelOwner - license.totalRevenueShareDistributed;
        require(remainingToDistribute > 0, "No remaining revenue to distribute or already fully distributed.");
        
        uint256 modelSpecId = aimNFTToModelSpecId[license.aimNFTTokenId];
        ModelSpec storage modelSpec = modelSpecs[modelSpecId];
        
        // Accrue rewards for the model owner
        accruedRewards[modelSpec.owner] += remainingToDistribute;
        
        license.totalRevenueShareDistributed = totalRevenueForModelOwner; // Mark as fully distributed for this license
        
        emit LicenseRevenueDistributed(_licenseId, remainingToDistribute);
    }


    // --- V. Dispute Resolution & Slashing ---

    /**
     * @notice Initiates a formal dispute regarding a specific entity (data, compute, validation).
     * @param _entityId The ID of the related entity (DataContribution, ComputeProposal, ValidationResult).
     * @param _type The type of dispute (DATA_QUALITY, COMPUTE_INTEGRITY, VALIDATION_ACCURACY).
     * @param _reasonURI URI to detailed reason for the dispute.
     */
    function initiateDispute(
        uint256 _entityId,
        DisputeType _type,
        string calldata _reasonURI
    ) public onlyRegisteredParticipant nonReentrant {
        // Additional access control could be added: e.g., only affected parties or validators can initiate
        // For simplicity, any registered participant can initiate.

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            entityId: _entityId,
            disputeType: _type,
            initiator: _msgSender(),
            reasonURI: _reasonURI,
            status: DisputeStatus.OPEN,
            votesForInitiator: 0,
            votesAgainstInitiator: 0,
            totalReputationStakedFor: 0,
            totalReputationStakedAgainst: 0,
            resolutionTimestamp: 0,
            outcomeForInitiator: false // Default
        });

        emit DisputeInitiated(newDisputeId, _entityId, _type, _msgSender());
    }

    /**
     * @notice Registered validators vote on an ongoing dispute.
     * @param _disputeId The ID of the dispute to vote on.
     * @param _supportForInitiator True if the voter supports the dispute initiator's claim.
     */
    function voteOnDispute(uint256 _disputeId, bool _supportForInitiator) public onlyRole(ParticipantRole.VALIDATOR) nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute not found.");
        require(dispute.status == DisputeStatus.OPEN || dispute.status == DisputeStatus.VOTING, "Dispute not open for voting.");
        require(!dispute.hasVoted[_msgSender()], "Already voted on this dispute.");
        require(participants[_msgSender()].reputationStake > 0, "Validator needs stake to vote.");

        if (_supportForInitiator) {
            dispute.votesForInitiator++;
            dispute.totalReputationStakedFor += participants[_msgSender()].reputationStake;
        } else {
            dispute.votesAgainstInitiator++;
            dispute.totalReputationStakedAgainst += participants[_msgSender()].reputationStake;
        }
        dispute.hasVoted[_msgSender()] = true;

        // Transition to voting state if it was open
        if (dispute.status == DisputeStatus.OPEN) {
            dispute.status = DisputeStatus.VOTING;
        }

        emit DisputeVoted(_disputeId, _msgSender(), _supportForInitiator);
    }

    /**
     * @notice Resolves a dispute based on voting results and applies consequences (e.g., slashing).
     *         Callable by the contract owner for this example, but would be a DAO/governance in full DApp.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) public onlyOwner nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute not found.");
        require(dispute.status == DisputeStatus.VOTING || dispute.status == DisputeStatus.OPEN, "Dispute already resolved or invalid state.");

        bool outcomeForInitiator = false;
        if (dispute.totalReputationStakedFor > dispute.totalReputationStakedAgainst) {
            outcomeForInitiator = true;
            dispute.status = DisputeStatus.RESOLVED_ACCEPTED;
        } else {
            dispute.status = DisputeStatus.RESOLVED_REJECTED;
        }
        dispute.outcomeForInitiator = outcomeForInitiator;
        dispute.resolutionTimestamp = block.timestamp;

        // Implement slashing/reward logic based on outcome
        if (outcomeForInitiator) {
            // Dispute successful: penalize the party whose work was disputed
            address partyToPenalize = address(0);
            uint256 penalizeAmount = 0;

            if (dispute.disputeType == DisputeType.DATA_QUALITY) {
                DataContribution storage dc = dataContributions[dispute.entityId];
                if (dc.id != 0) {
                    partyToPenalize = dc.contributor;
                    penalizeAmount = participants[partyToPenalize].reputationStake / 10; // Slash 10%
                }
            } else if (dispute.disputeType == DisputeType.COMPUTE_INTEGRITY) {
                ComputeProposal storage cp = computeProposals[dispute.entityId];
                if (cp.id != 0) {
                    partyToPenalize = cp.provider;
                    penalizeAmount = participants[partyToPenalize].reputationStake / 10; // Slash 10%
                }
            } else if (dispute.disputeType == DisputeType.VALIDATION_ACCURACY) {
                ValidationResult storage vr = validationResults[dispute.entityId];
                if (vr.id != 0) {
                    partyToPenalize = vr.validator;
                    penalizeAmount = participants[partyToPenalize].reputationStake / 10; // Slash 10%
                }
            }

            if (partyToPenalize != address(0) && penalizeAmount > 0) {
                require(participants[partyToPenalize].reputationStake >= penalizeAmount, "Insufficient stake to slash.");
                participants[partyToPenalize].reputationStake -= penalizeAmount;
                require(synapseToken.transfer(protocolTreasury, penalizeAmount), "Slash transfer to treasury failed.");
                emit FundsSlashing(partyToPenalize, penalizeAmount);
            }
        } else {
            // Dispute unsuccessful: penalize the initiator for a baseless dispute
            uint256 slashAmount = participants[dispute.initiator].reputationStake / 20; // Slash 5%
            if (slashAmount > 0) {
                require(participants[dispute.initiator].reputationStake >= slashAmount, "Insufficient stake to slash initiator.");
                participants[dispute.initiator].reputationStake -= slashAmount;
                require(synapseToken.transfer(protocolTreasury, slashAmount), "Slash transfer to treasury failed.");
                emit FundsSlashing(dispute.initiator, slashAmount);
            }
        }
        
        emit DisputeResolved(_disputeId, outcomeForInitiator, dispute.reasonURI);
    }


    // --- VI. Reward & Fund Management ---

    /**
     * @notice Allows participants to claim their accrued Synapse Token rewards.
     */
    function claimAccruedRewards() public nonReentrant {
        uint256 amount = accruedRewards[_msgSender()];
        require(amount > 0, "No rewards to claim.");

        accruedRewards[_msgSender()] = 0; // Reset before transfer
        require(synapseToken.transfer(_msgSender(), amount), "Reward transfer failed.");

        emit RewardsClaimed(_msgSender(), amount);
    }

    /**
     * @notice Model owner can withdraw any unused initial funding for a model specification.
     *         Only callable if the model is completed (AIM-NFT minted) or the job is cancelled.
     * @param _modelSpecId The ID of the model specification.
     */
    function withdrawModelFunding(uint256 _modelSpecId) public onlyRole(ParticipantRole.MODEL_OWNER) nonReentrant {
        ModelSpec storage modelSpec = modelSpecs[_modelSpecId];
        require(modelSpec.id != 0, "Model specification not found.");
        require(modelSpec.owner == _msgSender(), "Caller is not the model owner.");
        
        // Ensure the job is truly finished or cancelled before allowing withdrawal.
        // Using the proxy link from modelSpecId to trainingJobId for status check.
        require(modelSpec.isCompleted || trainingJobs[modelSpecIdToAIMNFT[_modelSpecId]].status == JobStatus.CANCELLED, 
                "Model not completed or job not cancelled for withdrawal.");
        
        uint256 unusedFunds = modelSpec.initialFunding - modelSpec.fundsSpent;
        require(unusedFunds > 0, "No unused funds to withdraw.");

        modelSpec.initialFunding = modelSpec.fundsSpent; // Mark funds as withdrawn by setting initial to spent
        require(synapseToken.transfer(_msgSender(), unusedFunds), "Fund withdrawal failed.");

        emit ModelFundingWithdrawal(_modelSpecId, _msgSender(), unusedFunds);
    }

    /**
     * @notice (Governance) Updates the percentage of platform fees collected from licensing revenue.
     *         Callable only by the contract owner.
     * @param _newFeePercentage The new fee percentage in basis points (e.g., 500 for 5%). Max 10000 (100%).
     */
    function updateProtocolFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 10000, "Fee percentage cannot exceed 100% (10000 basis points).");
        protocolFeePercentage = _newFeePercentage;
        emit ProtocolFeeUpdated(_newFeePercentage);
    }
}
```