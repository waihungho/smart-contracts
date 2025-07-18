This smart contract, named `Aethermind`, establishes a decentralized marketplace for AI model training and inference. It integrates advanced concepts such as a dynamic reputation system, multi-party staking, a dispute resolution framework, and a royalty mechanism for AI models. The contract aims to foster a collaborative ecosystem where data providers, model developers, compute trainers, and model consumers can interact transparently and securely.

---

### **Aethermind: Decentralized AI Marketplace Contract**

**Outline:**

1.  **Enums & Structs:** Define states and data structures for participants, datasets, models, training requests, inference requests, disputes, and governance proposals.
2.  **State Variables:** Global contract configurations, counters, and mappings to store core data.
3.  **Events:** To log significant actions for off-chain monitoring.
4.  **Modifiers:** For access control and state validation.
5.  **Constructor:** Initializes the contract with an ERC20 token address and owner.
6.  **Core Infrastructure & Participant Management:**
    *   Participant registration, profile updates, and deregistration.
    *   Staking and unstaking mechanisms tied to participant roles.
    *   Platform fee management.
7.  **Dataset & Model Lifecycle Management:**
    *   Registration of datasets (metadata) by data providers.
    *   Verification and reporting mechanisms for datasets.
    *   Registration of model architectures by developers, including royalty settings.
    *   Updating model royalties and retiring models.
8.  **AI Training Marketplace Logic:**
    *   Developers initiating training requests for models on specific datasets.
    *   Compute trainers submitting their available resources and prices.
    *   Matching and acceptance of training requests by trainers.
    *   Submission of training results by trainers.
    *   Dispute initiation for training outcomes.
9.  **AI Inference Marketplace Logic:**
    *   Consumers requesting inference on trained models.
    *   Model hosts (trainers/developers) offering inference services.
    *   Acceptance of inference requests.
    *   Submission of inference results by model hosts.
    *   Dispute initiation for inference outcomes.
10. **Reputation & Dispute Resolution:**
    *   Functions for governance (or a designated authority) to punish or reward participants, affecting their reputation and staked funds.
    *   A generalized dispute resolution function.
    *   Mechanism for participants to claim earned funds.
11. **Governance (Simplified):**
    *   Basic proposal submission and voting mechanism for future protocol changes (e.g., fee adjustments).

---

### **Function Summary:**

**I. Core Infrastructure & Participant Management:**

1.  `constructor(address _amindTokenAddress)`: Initializes the contract, sets the `AMIND` token address, and assigns ownership.
2.  `registerParticipant(ParticipantRole _role, string memory _profileURI)`: Allows a user to register as a specific role (Data Provider, Trainer, Model Developer, Consumer, Validator) and link off-chain profile metadata. Requires a minimum stake based on role.
3.  `updateProfileURI(string memory _newURI)`: Enables a registered participant to update their associated off-chain profile URI.
4.  `deregisterParticipant()`: Allows a participant to initiate the deregistration process, which includes a cooldown period for stake withdrawal.
5.  `stake(ParticipantRole _role, uint256 _amount)`: Allows participants to stake `AMIND` tokens, which are crucial for reputation, accessing services, and demonstrating commitment. Different roles may require different minimum stakes.
6.  `unstake(uint256 _amount)`: Enables participants to withdraw staked `AMIND` tokens after a predefined cooldown period, or if they are deregistered and no disputes are pending.
7.  `setPlatformFee(uint256 _feePercentage)`: (Callable by `owner` or governance) Sets the percentage of revenue taken by the platform from successful transactions.

**II. Dataset & Model Lifecycle Management:**

8.  `submitDatasetMetadata(string memory _datasetHash, string memory _metadataURI, uint256 _sizeInBytes, uint256 _minStakeRequired)`: Data Providers register metadata (e.g., IPFS hash) about a dataset they can provide. Requires a stake to ensure availability and quality.
9.  `verifyDatasetAvailability(string memory _datasetHash)`: (Callable by `Validator` or governance) Marks a registered dataset as `Available` after verification of its existence and quality.
10. `reportDatasetIssue(string memory _datasetHash, string memory _reason)`: Allows any participant to report issues (e.g., unavailability, incorrect metadata, quality concerns) with a registered dataset, potentially triggering a dispute or review.
11. `submitModelArchitecture(string memory _archHash, string memory _metadataURI, uint256 _requiredTrainingStake, uint256 _inferenceRoyaltyPercentage)`: Model Developers register the architecture (e.g., hash of a neural network graph definition) and set their desired royalty percentage for future inference services using this model.
12. `updateModelRoyalty(string memory _archHash, uint256 _newPercentage)`: Allows the Model Developer to adjust the royalty percentage for their registered model architecture.
13. `retireModelArchitecture(string memory _archHash)`: Allows a Model Developer to mark their model architecture as retired, preventing new training or inference requests for it.

**III. AI Training Marketplace Logic:**

14. `requestModelTraining(string memory _modelArchHash, string[] memory _datasetHashes, uint256 _maxPricePerComputeUnit, uint256 _minAccuracyTarget, uint256 _maxTrainingDuration)`: Model Developers submit a request to train a specific model architecture using one or more datasets, specifying their budget and desired outcome.
15. `submitComputeOffer(uint256 _computeUnitsAvailable, uint256 _pricePerComputeUnit, uint256 _maxDuration)`: Compute Trainers declare their available compute resources and their pricing for training tasks.
16. `acceptTrainingRequest(bytes32 _requestId)`: A Compute Trainer accepts an open training request, committing to execute it. This locks the agreed funds.
17. `submitTrainingResult(bytes32 _requestId, string memory _trainedModelHash, uint256 _achievedAccuracy, uint256 _computeUnitsUsed)`: The assigned Trainer submits the hash of the trained model, the achieved accuracy, and the compute units consumed. This triggers a verification period.
18. `disputeTrainingResult(bytes32 _requestId, string memory _reason)`: The Model Developer or a Validator can dispute the submitted training result (e.g., accuracy below target, model not working), initiating the dispute resolution process.

**IV. AI Inference Marketplace Logic:**

19. `requestModelInference(string memory _trainedModelHash, string memory _inputDataHash, uint256 _maxInferencePrice)`: Consumers submit requests for inference on a specific trained model, providing input data (hash) and a maximum price they are willing to pay.
20. `submitInferenceOffer(string memory _trainedModelHash, uint256 _pricePerInference)`: Model hosts (can be Trainer or Model Developer) declare their ability to provide inference for a specific trained model at a certain price.
21. `acceptInferenceRequest(bytes32 _inferenceId)`: A Model Host accepts an open inference request, locking the required funds.
22. `submitInferenceResult(bytes32 _inferenceId, string memory _outputDataHash)`: The assigned Model Host submits the hash of the inference output.
23. `disputeInferenceResult(bytes32 _inferenceId, string memory _reason)`: The Consumer or a Validator can dispute the submitted inference result (e.g., incorrect output, non-delivery), initiating the dispute resolution process.

**V. Reputation & Dispute Resolution:**

24. `punishParticipant(address _participant, uint256 _slashAmount, string memory _reason)`: (Callable by `owner` or governance) Decreases a participant's reputation and potentially slashes their staked tokens due to misconduct, failed tasks, or resolved disputes against them.
25. `rewardParticipant(address _participant, uint256 _reputationBonus, string memory _reason)`: (Callable by `owner` or governance) Increases a participant's reputation for successful contributions, high performance, or positive dispute resolution.
26. `resolveDispute(bytes32 _disputeId, DisputeOutcome _outcome, address _winnerAddress, address _loserAddress, uint256 _penaltyAmount)`: (Callable by `owner` or governance after a voting process) Finalizes a dispute, distributing funds, applying penalties, and updating reputations based on the determined outcome.
27. `claimFunds()`: Allows any participant to claim their accumulated earnings from successfully completed tasks (training, inference) and resolved disputes.

**VI. Governance (Simplified):**

28. `proposeProtocolChange(string memory _proposalURI)`: Allows a participant with sufficient stake/reputation to submit a proposal for protocol changes (e.g., adjusting fees, adding new roles). The proposal URI points to off-chain details.
29. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows staked participants to vote on active governance proposals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. Enums & Structs
// 2. State Variables
// 3. Events
// 4. Modifiers
// 5. Constructor
// 6. Core Infrastructure & Participant Management
// 7. Dataset & Model Lifecycle Management
// 8. AI Training Marketplace Logic
// 9. AI Inference Marketplace Logic
// 10. Reputation & Dispute Resolution
// 11. Governance (Simplified)

// Function Summary:
// I. Core Infrastructure & Participant Management:
// 1. constructor(address _amindTokenAddress): Initializes contract, sets AMIND token and owner.
// 2. registerParticipant(ParticipantRole _role, string memory _profileURI): Register user with role, profile URI. Requires initial stake.
// 3. updateProfileURI(string memory _newURI): Update participant's off-chain profile URI.
// 4. deregisterParticipant(): Participant initiates deregistration and stake unlock.
// 5. stake(ParticipantRole _role, uint256 _amount): Stake AMIND tokens for a specific role.
// 6. unstake(uint256 _amount): Unstake AMIND tokens after cooldown/deregistration.
// 7. setPlatformFee(uint256 _feePercentage): (Owner/Governance) Sets platform revenue share.

// II. Dataset & Model Lifecycle Management:
// 8. submitDatasetMetadata(string memory _datasetHash, string memory _metadataURI, uint256 _sizeInBytes, uint256 _minStakeRequired): Data Provider registers dataset metadata.
// 9. verifyDatasetAvailability(string memory _datasetHash): (Validator/Governance) Marks dataset as available after verification.
// 10. reportDatasetIssue(string memory _datasetHash, string memory _reason): Any participant reports issues with a dataset.
// 11. submitModelArchitecture(string memory _archHash, string memory _metadataURI, uint256 _requiredTrainingStake, uint256 _inferenceRoyaltyPercentage): Model Developer registers model architecture, sets royalty.
// 12. updateModelRoyalty(string memory _archHash, uint256 _newPercentage): Model Developer adjusts model's royalty percentage.
// 13. retireModelArchitecture(string memory _archHash): Model Developer retires a model architecture.

// III. AI Training Marketplace Logic:
// 14. requestModelTraining(string memory _modelArchHash, string[] memory _datasetHashes, uint256 _maxPricePerComputeUnit, uint256 _minAccuracyTarget, uint256 _maxTrainingDuration): Model Developer requests model training.
// 15. submitComputeOffer(uint256 _computeUnitsAvailable, uint256 _pricePerComputeUnit, uint256 _maxDuration): Trainer offers compute resources.
// 16. acceptTrainingRequest(bytes32 _requestId): Trainer accepts a training request.
// 17. submitTrainingResult(bytes32 _requestId, string memory _trainedModelHash, uint256 _achievedAccuracy, uint256 _computeUnitsUsed): Trainer submits training outcome.
// 18. disputeTrainingResult(bytes32 _requestId, string memory _reason): Developer/Validator disputes training result.

// IV. AI Inference Marketplace Logic:
// 19. requestModelInference(string memory _trainedModelHash, string memory _inputDataHash, uint256 _maxInferencePrice): Consumer requests model inference.
// 20. submitInferenceOffer(string memory _trainedModelHash, uint256 _pricePerInference): Model host offers inference for a trained model.
// 21. acceptInferenceRequest(bytes32 _inferenceId): Model host accepts an inference request.
// 22. submitInferenceResult(bytes32 _inferenceId, string memory _outputDataHash): Model host submits inference output.
// 23. disputeInferenceResult(bytes32 _inferenceId, string memory _reason): Consumer/Validator disputes inference result.

// V. Reputation & Dispute Resolution:
// 24. punishParticipant(address _participant, uint256 _slashAmount, string memory _reason): (Owner/Governance) Decreases participant reputation/slashes stake.
// 25. rewardParticipant(address _participant, uint256 _reputationBonus, string memory _reason): (Owner/Governance) Increases participant reputation.
// 26. resolveDispute(bytes32 _disputeId, DisputeOutcome _outcome, address _winnerAddress, address _loserAddress, uint256 _penaltyAmount): (Owner/Governance) Finalizes dispute, applies penalties/rewards.
// 27. claimFunds(): Participants claim accumulated earnings.

// VI. Governance (Simplified):
// 28. proposeProtocolChange(string memory _proposalURI): Participant proposes protocol changes.
// 29. voteOnProposal(uint256 _proposalId, bool _support): Staked participants vote on proposals.

contract Aethermind is Ownable {
    using SafeMath for uint256;

    IERC20 public immutable AMIND_TOKEN;

    // --- Enums ---
    enum ParticipantRole {
        None,
        DataProv,    // Data Provider
        Trainer,     // Compute Provider / Trainer
        ModelDev,    // Model Developer
        Consumer,    // Model Consumer / User
        Validator    // Verifier of data/models/results
    }

    enum ParticipantStatus {
        Active,
        Deregistering,
        Deregistered
    }

    enum DatasetStatus {
        PendingApproval,
        Available,
        Unavailable,
        Deprecated,
        ReportedIssue
    }

    enum ModelArchitectureStatus {
        Active,
        Retired
    }

    enum TrainingStatus {
        Requested,
        Accepted,
        Submitted,
        Verified,
        Disputed,
        Resolved
    }

    enum InferenceStatus {
        Requested,
        Accepted,
        Submitted,
        Verified,
        Disputed,
        Resolved
    }

    enum DisputeOutcome {
        Pending,
        ResolvedInFavorOfInitiator,
        ResolvedInFavorOfDefendant,
        Cancelled
    }

    // --- Structs ---
    struct Participant {
        ParticipantRole role;
        string profileURI;
        uint256 reputation; // Score based on performance and honesty
        uint256 stakedAmount; // AMIND tokens staked
        ParticipantStatus status;
        uint256 deregisterCooldownEnd;
        uint256 fundsToClaim; // Earnings waiting to be claimed
    }

    struct Dataset {
        address owner;
        string datasetHash; // IPFS or similar hash
        string metadataURI; // URI to off-chain metadata (e.g., description, schema)
        uint256 sizeInBytes;
        uint256 minStakeRequired; // Minimum stake for data providers for this dataset
        DatasetStatus status;
    }

    struct ModelArchitecture {
        address owner;
        string archHash; // IPFS or similar hash of model architecture definition
        string metadataURI; // URI to off-chain metadata
        uint256 requiredTrainingStake; // Min stake for developers to request training
        uint256 inferenceRoyaltyPercentage; // % of inference fee developer receives (0-10000 for 0-100%)
        ModelArchitectureStatus status;
    }

    struct ComputeOffer {
        address trainer;
        uint256 computeUnitsAvailable; // E.g., GPU hours
        uint256 pricePerComputeUnit; // In AMIND
        uint256 maxDuration; // Max hours trainer commits for a single task
        bool isActive;
    }

    struct TrainingRequest {
        bytes32 requestId;
        address developer;
        string modelArchHash;
        string[] datasetHashes;
        uint256 maxPricePerComputeUnit;
        uint256 minAccuracyTarget; // E.g., 9500 for 95%
        uint256 maxTrainingDuration; // In hours
        TrainingStatus status;
        address assignedTrainer;
        uint256 agreedPrice; // Total price in AMIND
        string submittedModelHash; // Hash of the trained model
        uint256 achievedAccuracy;
        uint256 computeUnitsUsed;
        uint256 creationTimestamp;
        uint256 submissionTimestamp;
        uint256 verificationDeadline;
        uint256 totalCostToConsumer; // Max price consumer paid.
    }

    struct InferenceRequest {
        bytes32 inferenceId;
        address consumer;
        string trainedModelHash;
        string inputDataHash; // Hash of input data for inference
        uint256 maxInferencePrice; // Max price consumer is willing to pay
        InferenceStatus status;
        address assignedExecutor; // The one providing inference
        string submittedOutputHash; // Hash of inference output
        uint256 creationTimestamp;
        uint256 submissionTimestamp;
        uint256 verificationDeadline;
        uint256 agreedPrice; // Price agreed upon with executor
        uint256 royaltyAmount; // Amount paid to model developer
    }

    struct Dispute {
        bytes32 disputeId;
        bytes32 associatedId; // Either requestId or inferenceId
        bool isTrainingDispute; // true for training, false for inference
        string reason;
        DisputeOutcome outcome;
        address initiator;
        address defendant;
        uint256 creationTimestamp;
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string proposalURI; // URI to off-chain details of the proposal
        uint256 yayVotes;
        uint256 nayVotes;
        uint256 requiredStakeForVoting;
        uint256 submissionTimestamp;
        uint256 votingDeadline;
        bool executed;
    }

    // --- State Variables ---
    uint256 public nextRequestId = 1;
    uint256 public nextInferenceId = 1;
    uint256 public nextDisputeId = 1;
    uint256 public nextProposalId = 1;

    uint256 public platformFeePercentage = 500; // 5% (500 basis points) of transaction value

    // Staking configuration
    uint256 public minStake_DataProv = 100 * (10 ** 18); // 100 AMIND
    uint256 public minStake_Trainer = 200 * (10 ** 18);  // 200 AMIND
    uint256 public minStake_ModelDev = 150 * (10 ** 18); // 150 AMIND
    uint256 public minStake_Consumer = 50 * (10 ** 18);  // 50 AMIND
    uint256 public minStake_Validator = 300 * (10 ** 18); // 300 AMIND
    uint256 public constant DEREGISTER_COOLDOWN_PERIOD = 7 days; // 7 days cooldown for unstaking

    uint256 public constant VERIFICATION_PERIOD = 2 days; // 2 days for verification/dispute submission

    // Mappings
    mapping(address => Participant) public participants;
    mapping(string => Dataset) public datasets; // datasetHash -> Dataset
    mapping(string => ModelArchitecture) public modelArchitectures; // archHash -> ModelArchitecture
    mapping(address => ComputeOffer) public computeOffers; // trainerAddress -> ComputeOffer

    mapping(bytes32 => TrainingRequest) public trainingRequests; // requestId -> TrainingRequest
    mapping(bytes32 => InferenceRequest) public inferenceRequests; // inferenceId -> InferenceRequest
    mapping(bytes32 => Dispute) public disputes; // disputeId -> Dispute

    mapping(uint256 => Proposal) public proposals; // proposalId -> Proposal
    mapping(address => mapping(uint256 => bool)) public proposalVotes; // voterAddress -> proposalId -> votedTrue

    // --- Events ---
    event ParticipantRegistered(address indexed participantAddress, ParticipantRole role, string profileURI, uint256 initialStake);
    event ParticipantProfileUpdated(address indexed participantAddress, string newURI);
    event ParticipantDeregistered(address indexed participantAddress);
    event TokensStaked(address indexed participantAddress, uint256 amount, ParticipantRole role);
    event TokensUnstaked(address indexed participantAddress, uint256 amount);
    event FundsClaimed(address indexed participantAddress, uint256 amount);
    event PlatformFeeUpdated(uint256 newFeePercentage);

    event DatasetSubmitted(address indexed owner, string indexed datasetHash, string metadataURI);
    event DatasetVerified(string indexed datasetHash, DatasetStatus newStatus);
    event DatasetIssueReported(string indexed datasetHash, address indexed reporter, string reason);

    event ModelArchitectureSubmitted(address indexed owner, string indexed archHash, string metadataURI, uint256 royaltyPercentage);
    event ModelRoyaltyUpdated(string indexed archHash, uint256 newPercentage);
    event ModelArchitectureRetired(string indexed archHash);

    event TrainingRequested(bytes32 indexed requestId, address indexed developer, string modelArchHash, uint256 maxPricePerComputeUnit);
    event ComputeOfferSubmitted(address indexed trainer, uint256 computeUnitsAvailable, uint256 pricePerComputeUnit);
    event TrainingRequestAccepted(bytes32 indexed requestId, address indexed trainer, uint256 agreedPrice);
    event TrainingResultSubmitted(bytes32 indexed requestId, string trainedModelHash, uint256 achievedAccuracy);
    event TrainingResultDisputed(bytes32 indexed requestId, address indexed disputer, string reason);

    event InferenceRequested(bytes32 indexed inferenceId, address indexed consumer, string trainedModelHash, uint256 maxPrice);
    event InferenceOfferSubmitted(address indexed executor, string trainedModelHash, uint256 pricePerInference);
    event InferenceRequestAccepted(bytes32 indexed inferenceId, address indexed executor, uint256 agreedPrice);
    event InferenceResultSubmitted(bytes32 indexed inferenceId, string outputDataHash);
    event InferenceResultDisputed(bytes32 indexed inferenceId, address indexed disputer, string reason);

    event ParticipantPunished(address indexed participant, uint256 slashAmount, uint256 newReputation, string reason);
    event ParticipantRewarded(address indexed participant, uint256 reputationBonus, uint256 newReputation, string reason);
    event DisputeResolved(bytes32 indexed disputeId, DisputeOutcome outcome, address winner, address loser, uint256 penaltyAmount);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);

    // --- Modifiers ---
    modifier onlyParticipant(ParticipantRole _role) {
        require(participants[msg.sender].role == _role, "Aethermind: Caller is not a registered participant of this role.");
        require(participants[msg.sender].status == ParticipantStatus.Active, "Aethermind: Participant not active.");
        _;
    }

    modifier onlyRegistered() {
        require(participants[msg.sender].role != ParticipantRole.None, "Aethermind: Caller not a registered participant.");
        require(participants[msg.sender].status == ParticipantStatus.Active, "Aethermind: Participant not active.");
        _;
    }

    modifier onlyActiveModel(string memory _archHash) {
        require(modelArchitectures[_archHash].status == ModelArchitectureStatus.Active, "Aethermind: Model is not active.");
        _;
    }

    // --- Constructor ---
    constructor(address _amindTokenAddress) Ownable() {
        require(_amindTokenAddress != address(0), "Aethermind: AMIND token address cannot be zero.");
        AMIND_TOKEN = IERC20(_amindTokenAddress);
    }

    // --- 6. Core Infrastructure & Participant Management ---

    /**
     * @notice Allows a user to register as a specific role within the Aethermind ecosystem.
     *         Requires an initial stake based on the chosen role.
     * @param _role The desired role for the participant (DataProv, Trainer, ModelDev, Consumer, Validator).
     * @param _profileURI An IPFS or HTTP URI pointing to the participant's off-chain profile metadata.
     */
    function registerParticipant(ParticipantRole _role, string memory _profileURI) public {
        require(participants[msg.sender].role == ParticipantRole.None, "Aethermind: Already a registered participant.");
        require(_role != ParticipantRole.None, "Aethermind: Invalid role.");
        require(bytes(_profileURI).length > 0, "Aethermind: Profile URI cannot be empty.");

        uint256 minStake = 0;
        if (_role == ParticipantRole.DataProv) minStake = minStake_DataProv;
        else if (_role == ParticipantRole.Trainer) minStake = minStake_Trainer;
        else if (_role == ParticipantRole.ModelDev) minStake = minStake_ModelDev;
        else if (_role == ParticipantRole.Consumer) minStake = minStake_Consumer;
        else if (_role == ParticipantRole.Validator) minStake = minStake_Validator;

        require(minStake > 0, "Aethermind: Invalid role for staking setup.");
        require(AMIND_TOKEN.transferFrom(msg.sender, address(this), minStake), "Aethermind: AMIND transfer failed for initial stake.");

        participants[msg.sender] = Participant({
            role: _role,
            profileURI: _profileURI,
            reputation: 1000, // Starting reputation
            stakedAmount: minStake,
            status: ParticipantStatus.Active,
            deregisterCooldownEnd: 0,
            fundsToClaim: 0
        });

        emit ParticipantRegistered(msg.sender, _role, _profileURI, minStake);
    }

    /**
     * @notice Allows a registered participant to update their associated off-chain profile URI.
     * @param _newURI The new IPFS or HTTP URI for the participant's profile.
     */
    function updateProfileURI(string memory _newURI) public onlyRegistered {
        require(bytes(_newURI).length > 0, "Aethermind: New profile URI cannot be empty.");
        participants[msg.sender].profileURI = _newURI;
        emit ParticipantProfileUpdated(msg.sender, _newURI);
    }

    /**
     * @notice Allows a participant to initiate the deregistration process.
     *         Their staked funds become available after a cooldown period,
     *         provided no pending obligations (e.g., active tasks, disputes).
     */
    function deregisterParticipant() public onlyRegistered {
        require(participants[msg.sender].status == ParticipantStatus.Active, "Aethermind: Participant is already deregistering or deregistered.");
        // Implement checks for pending tasks / disputes later for production
        // For now, assume no pending tasks.

        participants[msg.sender].status = ParticipantStatus.Deregistering;
        participants[msg.sender].deregisterCooldownEnd = block.timestamp.add(DEREGISTER_COOLDOWN_PERIOD);

        emit ParticipantDeregistered(msg.sender);
    }

    /**
     * @notice Allows participants to stake additional AMIND tokens.
     *         This can improve their reputation, unlock higher tiers of service,
     *         or be a requirement for certain roles/actions.
     * @param _role The participant's current role. Used to re-validate min stake if they changed roles.
     * @param _amount The amount of AMIND tokens to stake.
     */
    function stake(ParticipantRole _role, uint256 _amount) public onlyRegistered {
        require(_amount > 0, "Aethermind: Stake amount must be greater than zero.");
        require(_role == participants[msg.sender].role, "Aethermind: Role mismatch. Ensure you specify your current role.");

        // Check if the current stake + new stake meets the minimum for their role
        uint256 currentMinStake = 0;
        if (_role == ParticipantRole.DataProv) currentMinStake = minStake_DataProv;
        else if (_role == ParticipantRole.Trainer) currentMinStake = minStake_Trainer;
        else if (_role == ParticipantRole.ModelDev) currentMinStake = minStake_ModelDev;
        else if (_role == ParticipantRole.Consumer) currentMinStake = minStake_Consumer;
        else if (_role == ParticipantRole.Validator) currentMinStake = minStake_Validator;

        require(participants[msg.sender].stakedAmount.add(_amount) >= currentMinStake, "Aethermind: Total stake below minimum for role.");
        require(AMIND_TOKEN.transferFrom(msg.sender, address(this), _amount), "Aethermind: AMIND transfer failed for staking.");

        participants[msg.sender].stakedAmount = participants[msg.sender].stakedAmount.add(_amount);

        emit TokensStaked(msg.sender, _amount, _role);
    }

    /**
     * @notice Enables participants to withdraw their staked AMIND tokens.
     *         Requires the participant to be deregistered or past the cooldown period.
     *         Cannot unstake below the minimum required for their active role.
     * @param _amount The amount of AMIND tokens to unstake.
     */
    function unstake(uint256 _amount) public onlyRegistered {
        require(_amount > 0, "Aethermind: Unstake amount must be greater than zero.");
        require(participants[msg.sender].stakedAmount >= _amount, "Aethermind: Insufficient staked amount.");

        bool canUnstake = false;
        if (participants[msg.sender].status == ParticipantStatus.Deregistered) {
            canUnstake = true; // Fully deregistered, can withdraw all
        } else if (participants[msg.sender].status == ParticipantStatus.Deregistering) {
            require(block.timestamp >= participants[msg.sender].deregisterCooldownEnd, "Aethermind: Deregistration cooldown period not over.");
            canUnstake = true;
        } else { // ParticipantStatus.Active
            uint256 minStakeForRole = 0;
            if (participants[msg.sender].role == ParticipantRole.DataProv) minStakeForRole = minStake_DataProv;
            else if (participants[msg.sender].role == ParticipantRole.Trainer) minStakeForRole = minStake_Trainer;
            else if (participants[msg.sender].role == ParticipantRole.ModelDev) minStakeForRole = minStake_ModelDev;
            else if (participants[msg.sender].role == ParticipantRole.Consumer) minStakeForRole = minStake_Consumer;
            else if (participants[msg.sender].role == ParticipantRole.Validator) minStakeForRole = minStake_Validator;

            require(participants[msg.sender].stakedAmount.sub(_amount) >= minStakeForRole, "Aethermind: Cannot unstake below minimum required for active role.");
            canUnstake = true;
        }

        require(canUnstake, "Aethermind: Cannot unstake due to status or pending cooldown.");
        require(AMIND_TOKEN.transfer(msg.sender, _amount), "Aethermind: AMIND transfer failed for unstaking.");

        participants[msg.sender].stakedAmount = participants[msg.sender].stakedAmount.sub(_amount);
        emit TokensUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Allows the contract owner (or governance) to set the platform's fee percentage.
     *         Fees are taken from successful transactions and accumulate in the contract.
     * @param _feePercentage New fee percentage (e.g., 500 for 5%). Max 10000 (100%).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 10000, "Aethermind: Fee percentage cannot exceed 10000 (100%).");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    // --- 7. Dataset & Model Lifecycle Management ---

    /**
     * @notice Data Providers register metadata about datasets they can offer.
     *         Requires a minimum stake for the dataset.
     * @param _datasetHash An IPFS or similar hash uniquely identifying the dataset content.
     * @param _metadataURI URI to off-chain metadata (description, schema, usage terms).
     * @param _sizeInBytes Size of the dataset in bytes.
     * @param _minStakeRequired Additional stake required for this specific dataset (beyond role stake).
     */
    function submitDatasetMetadata(string memory _datasetHash, string memory _metadataURI, uint256 _sizeInBytes, uint256 _minStakeRequired) public onlyParticipant(ParticipantRole.DataProv) {
        require(bytes(_datasetHash).length > 0, "Aethermind: Dataset hash cannot be empty.");
        require(datasets[_datasetHash].owner == address(0), "Aethermind: Dataset hash already registered.");
        require(bytes(_metadataURI).length > 0, "Aethermind: Metadata URI cannot be empty.");
        require(_sizeInBytes > 0, "Aethermind: Dataset size must be greater than zero.");
        
        // This is an additional stake for the dataset itself, showing commitment
        if (_minStakeRequired > 0) {
            require(AMIND_TOKEN.transferFrom(msg.sender, address(this), _minStakeRequired), "Aethermind: AMIND transfer failed for dataset stake.");
            participants[msg.sender].stakedAmount = participants[msg.sender].stakedAmount.add(_minStakeRequired);
        }

        datasets[_datasetHash] = Dataset({
            owner: msg.sender,
            datasetHash: _datasetHash,
            metadataURI: _metadataURI,
            sizeInBytes: _sizeInBytes,
            minStakeRequired: _minStakeRequired,
            status: DatasetStatus.PendingApproval
        });

        emit DatasetSubmitted(msg.sender, _datasetHash, _metadataURI);
    }

    /**
     * @notice A Validator or governance can mark a dataset as available after verifying its existence and quality.
     *         This makes the dataset usable for training requests.
     * @param _datasetHash The hash of the dataset to verify.
     */
    function verifyDatasetAvailability(string memory _datasetHash) public {
        require(participants[msg.sender].role == ParticipantRole.Validator || msg.sender == owner(), "Aethermind: Only Validators or Owner can verify datasets.");
        Dataset storage dataset = datasets[_datasetHash];
        require(dataset.owner != address(0), "Aethermind: Dataset not found.");
        require(dataset.status == DatasetStatus.PendingApproval || dataset.status == DatasetStatus.ReportedIssue, "Aethermind: Dataset is not in a verifiable state.");

        dataset.status = DatasetStatus.Available;
        // Optionally, reward validator or increase data provider's reputation
        emit DatasetVerified(_datasetHash, DatasetStatus.Available);
    }

    /**
     * @notice Allows any participant to report an issue with a registered dataset.
     *         This changes its status to ReportedIssue and might trigger a re-verification.
     * @param _datasetHash The hash of the dataset with an issue.
     * @param _reason A description of the issue.
     */
    function reportDatasetIssue(string memory _datasetHash, string memory _reason) public onlyRegistered {
        Dataset storage dataset = datasets[_datasetHash];
        require(dataset.owner != address(0), "Aethermind: Dataset not found.");
        require(dataset.status != DatasetStatus.Deprecated, "Aethermind: Cannot report issue on a deprecated dataset.");
        require(bytes(_reason).length > 0, "Aethermind: Reason cannot be empty.");

        dataset.status = DatasetStatus.ReportedIssue;
        // Potentially penalize data provider or trigger a dispute process
        emit DatasetIssueReported(_datasetHash, msg.sender, _reason);
    }

    /**
     * @notice Model Developers register their AI model architectures.
     *         They can define a royalty percentage for future inference services.
     * @param _archHash An IPFS or similar hash of the model architecture definition.
     * @param _metadataURI URI to off-chain metadata (e.g., model description, purpose).
     * @param _requiredTrainingStake Min stake required from developer to request training.
     * @param _inferenceRoyaltyPercentage Percentage (0-10000 for 0-100%) to be paid to the developer for each inference.
     */
    function submitModelArchitecture(
        string memory _archHash,
        string memory _metadataURI,
        uint256 _requiredTrainingStake,
        uint256 _inferenceRoyaltyPercentage
    ) public onlyParticipant(ParticipantRole.ModelDev) {
        require(bytes(_archHash).length > 0, "Aethermind: Architecture hash cannot be empty.");
        require(modelArchitectures[_archHash].owner == address(0), "Aethermind: Model architecture already registered.");
        require(bytes(_metadataURI).length > 0, "Aethermind: Metadata URI cannot be empty.");
        require(_inferenceRoyaltyPercentage <= 10000, "Aethermind: Royalty percentage cannot exceed 100%.");

        modelArchitectures[_archHash] = ModelArchitecture({
            owner: msg.sender,
            archHash: _archHash,
            metadataURI: _metadataURI,
            requiredTrainingStake: _requiredTrainingStake,
            inferenceRoyaltyPercentage: _inferenceRoyaltyPercentage,
            status: ModelArchitectureStatus.Active
        });

        emit ModelArchitectureSubmitted(msg.sender, _archHash, _metadataURI, _inferenceRoyaltyPercentage);
    }

    /**
     * @notice Allows the Model Developer to update the royalty percentage for their registered model.
     * @param _archHash The hash of the model architecture.
     * @param _newPercentage The new royalty percentage (0-10000).
     */
    function updateModelRoyalty(string memory _archHash, uint256 _newPercentage) public onlyParticipant(ParticipantRole.ModelDev) onlyActiveModel(_archHash) {
        require(modelArchitectures[_archHash].owner == msg.sender, "Aethermind: Only model owner can update royalty.");
        require(_newPercentage <= 10000, "Aethermind: New royalty percentage cannot exceed 100%.");

        modelArchitectures[_archHash].inferenceRoyaltyPercentage = _newPercentage;
        emit ModelRoyaltyUpdated(_archHash, _newPercentage);
    }

    /**
     * @notice Allows a Model Developer to retire their model architecture, preventing new training or inference requests.
     * @param _archHash The hash of the model architecture to retire.
     */
    function retireModelArchitecture(string memory _archHash) public onlyParticipant(ParticipantRole.ModelDev) {
        require(modelArchitectures[_archHash].owner == msg.sender, "Aethermind: Only model owner can retire.");
        require(modelArchitectures[_archHash].status == ModelArchitectureStatus.Active, "Aethermind: Model is already retired or not active.");

        modelArchitectures[_archHash].status = ModelArchitectureStatus.Retired;
        // Optionally, cancel pending requests for this model
        emit ModelArchitectureRetired(_archHash);
    }

    // --- 8. AI Training Marketplace Logic ---

    /**
     * @notice Model Developers submit requests to train a model architecture.
     *         Requires a deposit equal to `_maxPricePerComputeUnit` * some initial estimate,
     *         or `modelArchitectures[_modelArchHash].requiredTrainingStake`.
     * @param _modelArchHash The hash of the model architecture to train.
     * @param _datasetHashes An array of dataset hashes to use for training.
     * @param _maxPricePerComputeUnit The maximum price the developer is willing to pay per compute unit.
     * @param _minAccuracyTarget The minimum accuracy expected from the trained model (e.g., 9500 for 95%).
     * @param _maxTrainingDuration Maximum allowed duration for training in hours.
     */
    function requestModelTraining(
        string memory _modelArchHash,
        string[] memory _datasetHashes,
        uint256 _maxPricePerComputeUnit,
        uint256 _minAccuracyTarget,
        uint256 _maxTrainingDuration
    ) public onlyParticipant(ParticipantRole.ModelDev) onlyActiveModel(_modelArchHash) {
        require(modelArchitectures[_modelArchHash].owner == msg.sender, "Aethermind: Not owner of this model architecture.");
        require(_datasetHashes.length > 0, "Aethermind: At least one dataset is required.");
        require(_maxPricePerComputeUnit > 0, "Aethermind: Max price per compute unit must be greater than zero.");
        require(_minAccuracyTarget <= 10000, "Aethermind: Min accuracy target cannot exceed 100%.");
        require(_maxTrainingDuration > 0, "Aethermind: Max training duration must be positive.");

        // Verify all datasets exist and are available
        for (uint256 i = 0; i < _datasetHashes.length; i++) {
            require(datasets[_datasetHashes[i]].owner != address(0), "Aethermind: Dataset not found.");
            require(datasets[_datasetHashes[i]].status == DatasetStatus.Available, "Aethermind: Dataset not available.");
        }

        uint256 initialDeposit = modelArchitectures[_modelArchHash].requiredTrainingStake;
        require(AMIND_TOKEN.transferFrom(msg.sender, address(this), initialDeposit), "Aethermind: AMIND transfer failed for training deposit.");

        bytes32 currentRequestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, nextRequestId));
        trainingRequests[currentRequestId] = TrainingRequest({
            requestId: currentRequestId,
            developer: msg.sender,
            modelArchHash: _modelArchHash,
            datasetHashes: _datasetHashes,
            maxPricePerComputeUnit: _maxPricePerComputeUnit,
            minAccuracyTarget: _minAccuracyTarget,
            maxTrainingDuration: _maxTrainingDuration,
            status: TrainingStatus.Requested,
            assignedTrainer: address(0),
            agreedPrice: 0,
            submittedModelHash: "",
            achievedAccuracy: 0,
            computeUnitsUsed: 0,
            creationTimestamp: block.timestamp,
            submissionTimestamp: 0,
            verificationDeadline: 0,
            totalCostToConsumer: initialDeposit // This is the initial deposit, not final cost
        });
        nextRequestId++;

        emit TrainingRequested(currentRequestId, msg.sender, _modelArchHash, _maxPricePerComputeUnit);
    }

    /**
     * @notice Compute Trainers submit their available compute resources and pricing.
     *         This allows them to be matched with training requests.
     * @param _computeUnitsAvailable The amount of compute units the trainer has available.
     * @param _pricePerComputeUnit The price per compute unit in AMIND.
     * @param _maxDuration The maximum duration in hours for which the trainer can commit.
     */
    function submitComputeOffer(uint256 _computeUnitsAvailable, uint256 _pricePerComputeUnit, uint256 _maxDuration) public onlyParticipant(ParticipantRole.Trainer) {
        require(_computeUnitsAvailable > 0, "Aethermind: Compute units must be positive.");
        require(_pricePerComputeUnit > 0, "Aethermind: Price per compute unit must be positive.");
        require(_maxDuration > 0, "Aethermind: Max duration must be positive.");

        computeOffers[msg.sender] = ComputeOffer({
            trainer: msg.sender,
            computeUnitsAvailable: _computeUnitsAvailable,
            pricePerComputeUnit: _pricePerComputeUnit,
            maxDuration: _maxDuration,
            isActive: true
        });

        emit ComputeOfferSubmitted(msg.sender, _computeUnitsAvailable, _pricePerComputeUnit);
    }

    /**
     * @notice A Compute Trainer accepts an open training request.
     *         This requires the trainer to meet the request's criteria and locks their stake.
     * @param _requestId The ID of the training request to accept.
     */
    function acceptTrainingRequest(bytes32 _requestId) public onlyParticipant(ParticipantRole.Trainer) {
        TrainingRequest storage req = trainingRequests[_requestId];
        require(req.developer != address(0), "Aethermind: Training request not found.");
        require(req.status == TrainingStatus.Requested, "Aethermind: Request not in 'Requested' status.");

        ComputeOffer storage offer = computeOffers[msg.sender];
        require(offer.isActive, "Aethermind: Trainer has no active compute offer.");
        require(offer.pricePerComputeUnit <= req.maxPricePerComputeUnit, "Aethermind: Trainer's price too high.");
        // More complex matching logic would go here (e.g., matching dataset availability, compute unit estimation)

        req.assignedTrainer = msg.sender;
        req.agreedPrice = offer.pricePerComputeUnit; // This is per unit, actual total cost determined on submission
        req.status = TrainingStatus.Accepted;

        // Trainer's stake is implicitly tied to their commitment, no explicit escrow needed here
        // as reputation system handles penalties.

        emit TrainingRequestAccepted(_requestId, msg.sender, req.agreedPrice);
    }

    /**
     * @notice The assigned Trainer submits the results of a training task.
     *         This includes the hash of the trained model, achieved accuracy, and compute units used.
     * @param _requestId The ID of the completed training request.
     * @param _trainedModelHash The IPFS or similar hash of the resulting trained model.
     * @param _achievedAccuracy The accuracy achieved by the trained model (e.g., 9250 for 92.5%).
     * @param _computeUnitsUsed The actual compute units consumed for training.
     */
    function submitTrainingResult(bytes32 _requestId, string memory _trainedModelHash, uint256 _achievedAccuracy, uint256 _computeUnitsUsed) public onlyParticipant(ParticipantRole.Trainer) {
        TrainingRequest storage req = trainingRequests[_requestId];
        require(req.developer != address(0), "Aethermind: Training request not found.");
        require(req.assignedTrainer == msg.sender, "Aethermind: Only assigned trainer can submit results.");
        require(req.status == TrainingStatus.Accepted, "Aethermind: Request not in 'Accepted' status.");
        require(bytes(_trainedModelHash).length > 0, "Aethermind: Trained model hash cannot be empty.");
        require(_achievedAccuracy <= 10000, "Aethermind: Achieved accuracy cannot exceed 100%.");
        require(_computeUnitsUsed > 0, "Aethermind: Compute units used must be positive.");

        uint256 actualCost = req.agreedPrice.mul(_computeUnitsUsed);
        require(actualCost <= req.totalCostToConsumer, "Aethermind: Actual cost exceeds initial deposit by developer."); // Initial deposit set as max cost.

        req.submittedModelHash = _trainedModelHash;
        req.achievedAccuracy = _achievedAccuracy;
        req.computeUnitsUsed = _computeUnitsUsed;
        req.status = TrainingStatus.Submitted;
        req.submissionTimestamp = block.timestamp;
        req.verificationDeadline = block.timestamp.add(VERIFICATION_PERIOD);
        req.totalCostToConsumer = actualCost; // Update to actual cost.

        emit TrainingResultSubmitted(_requestId, _trainedModelHash, _achievedAccuracy);
    }

    /**
     * @notice The Model Developer or a Validator can dispute a submitted training result.
     *         This initiates the dispute resolution process.
     * @param _requestId The ID of the training request to dispute.
     * @param _reason A description of the reason for the dispute.
     */
    function disputeTrainingResult(bytes32 _requestId, string memory _reason) public onlyRegistered {
        TrainingRequest storage req = trainingRequests[_requestId];
        require(req.developer != address(0), "Aethermind: Training request not found.");
        require(req.status == TrainingStatus.Submitted, "Aethermind: Training result not in 'Submitted' status.");
        require(msg.sender == req.developer || participants[msg.sender].role == ParticipantRole.Validator, "Aethermind: Only developer or validator can dispute.");
        require(block.timestamp <= req.verificationDeadline, "Aethermind: Verification period has expired.");
        require(bytes(_reason).length > 0, "Aethermind: Reason for dispute cannot be empty.");

        req.status = TrainingStatus.Disputed;

        bytes32 currentDisputeId = keccak256(abi.encodePacked(block.timestamp, _requestId, nextDisputeId));
        disputes[currentDisputeId] = Dispute({
            disputeId: currentDisputeId,
            associatedId: _requestId,
            isTrainingDispute: true,
            reason: _reason,
            outcome: DisputeOutcome.Pending,
            initiator: msg.sender,
            defendant: req.assignedTrainer,
            creationTimestamp: block.timestamp
        });
        nextDisputeId++;

        emit TrainingResultDisputed(_requestId, msg.sender, _reason);
    }

    // --- 9. AI Inference Marketplace Logic ---

    /**
     * @notice Consumers submit requests for inference on a specific trained model.
     *         Requires a deposit for the maximum inference price.
     * @param _trainedModelHash The hash of the trained model to use for inference.
     * @param _inputDataHash The hash of the input data for which inference is requested.
     * @param _maxInferencePrice The maximum price the consumer is willing to pay for inference.
     */
    function requestModelInference(string memory _trainedModelHash, string memory _inputDataHash, uint256 _maxInferencePrice) public onlyParticipant(ParticipantRole.Consumer) {
        require(bytes(_trainedModelHash).length > 0, "Aethermind: Trained model hash cannot be empty.");
        require(bytes(_inputDataHash).length > 0, "Aethermind: Input data hash cannot be empty.");
        require(_maxInferencePrice > 0, "Aethermind: Max inference price must be greater than zero.");

        // For simplicity, we assume trainedModelHash corresponds to a valid model that exists.
        // In a real system, you'd verify if the model exists and is available for inference.

        require(AMIND_TOKEN.transferFrom(msg.sender, address(this), _maxInferencePrice), "Aethermind: AMIND transfer failed for inference deposit.");

        bytes32 currentInferenceId = keccak256(abi.encodePacked(block.timestamp, msg.sender, nextInferenceId));
        inferenceRequests[currentInferenceId] = InferenceRequest({
            inferenceId: currentInferenceId,
            consumer: msg.sender,
            trainedModelHash: _trainedModelHash,
            inputDataHash: _inputDataHash,
            maxInferencePrice: _maxInferencePrice,
            status: InferenceStatus.Requested,
            assignedExecutor: address(0),
            submittedOutputHash: "",
            creationTimestamp: block.timestamp,
            submissionTimestamp: 0,
            verificationDeadline: 0,
            agreedPrice: 0,
            royaltyAmount: 0
        });
        nextInferenceId++;

        emit InferenceRequested(currentInferenceId, msg.sender, _trainedModelHash, _maxInferencePrice);
    }

    /**
     * @notice Model hosts (can be Trainers or even Model Developers hosting their own trained models)
     *         declare their ability to provide inference for a specific trained model at a certain price.
     * @param _trainedModelHash The hash of the trained model they are offering inference for.
     * @param _pricePerInference The price for a single inference in AMIND.
     */
    function submitInferenceOffer(string memory _trainedModelHash, uint256 _pricePerInference) public onlyRegistered {
        // Participant could be Trainer or ModelDev or another role designated as 'ModelHost'
        require(bytes(_trainedModelHash).length > 0, "Aethermind: Trained model hash cannot be empty.");
        require(_pricePerInference > 0, "Aethermind: Price per inference must be positive.");

        // A `mapping(address => mapping(string => InferenceOffer))` would be more robust here.
        // For simplicity, we'll just log it and assume matching happens off-chain, then `acceptInferenceRequest` is called.
        // No explicit storage of inference offers per se, just an event for now.
        emit InferenceOfferSubmitted(msg.sender, _trainedModelHash, _pricePerInference);
    }

    /**
     * @notice A Model Host accepts an open inference request.
     * @param _inferenceId The ID of the inference request to accept.
     */
    function acceptInferenceRequest(bytes32 _inferenceId) public onlyRegistered {
        InferenceRequest storage req = inferenceRequests[_inferenceId];
        require(req.consumer != address(0), "Aethermind: Inference request not found.");
        require(req.status == InferenceStatus.Requested, "Aethermind: Request not in 'Requested' status.");

        // In a real scenario, this would check `submitInferenceOffer` and find a matching price/capability
        // For this example, we assume the host `msg.sender` has the capability and accepts.
        uint256 agreedPrice = req.maxInferencePrice; // Simplistic: accept at max price if no dynamic negotiation

        req.assignedExecutor = msg.sender;
        req.agreedPrice = agreedPrice;
        req.status = InferenceStatus.Accepted;

        emit InferenceRequestAccepted(_inferenceId, msg.sender, req.agreedPrice);
    }

    /**
     * @notice The assigned Model Host submits the result of an inference task.
     * @param _inferenceId The ID of the completed inference request.
     * @param _outputDataHash The IPFS or similar hash of the resulting inference output.
     */
    function submitInferenceResult(bytes32 _inferenceId, string memory _outputDataHash) public onlyRegistered {
        InferenceRequest storage req = inferenceRequests[_inferenceId];
        require(req.consumer != address(0), "Aethermind: Inference request not found.");
        require(req.assignedExecutor == msg.sender, "Aethermind: Only assigned executor can submit results.");
        require(req.status == InferenceStatus.Accepted, "Aethermind: Request not in 'Accepted' status.");
        require(bytes(_outputDataHash).length > 0, "Aethermind: Output data hash cannot be empty.");

        req.submittedOutputHash = _outputDataHash;
        req.status = InferenceStatus.Submitted;
        req.submissionTimestamp = block.timestamp;
        req.verificationDeadline = block.timestamp.add(VERIFICATION_PERIOD);

        emit InferenceResultSubmitted(_inferenceId, _outputDataHash);
    }

    /**
     * @notice The Consumer or a Validator can dispute a submitted inference result.
     *         This initiates the dispute resolution process.
     * @param _inferenceId The ID of the inference request to dispute.
     * @param _reason A description of the reason for the dispute.
     */
    function disputeInferenceResult(bytes32 _inferenceId, string memory _reason) public onlyRegistered {
        InferenceRequest storage req = inferenceRequests[_inferenceId];
        require(req.consumer != address(0), "Aethermind: Inference request not found.");
        require(req.status == InferenceStatus.Submitted, "Aethermind: Inference result not in 'Submitted' status.");
        require(msg.sender == req.consumer || participants[msg.sender].role == ParticipantRole.Validator, "Aethermind: Only consumer or validator can dispute.");
        require(block.timestamp <= req.verificationDeadline, "Aethermind: Verification period has expired.");
        require(bytes(_reason).length > 0, "Aethermind: Reason for dispute cannot be empty.");

        req.status = InferenceStatus.Disputed;

        bytes32 currentDisputeId = keccak256(abi.encodePacked(block.timestamp, _inferenceId, nextDisputeId));
        disputes[currentDisputeId] = Dispute({
            disputeId: currentDisputeId,
            associatedId: _inferenceId,
            isTrainingDispute: false,
            reason: _reason,
            outcome: DisputeOutcome.Pending,
            initiator: msg.sender,
            defendant: req.assignedExecutor,
            creationTimestamp: block.timestamp
        });
        nextDisputeId++;

        emit InferenceResultDisputed(_inferenceId, msg.sender, _reason);
    }

    // --- 10. Reputation & Dispute Resolution ---

    /**
     * @notice (Callable by owner/governance) Decreases a participant's reputation and potentially slashes their stake.
     *         Used as a penalty for misconduct or failed tasks resolved against them.
     * @param _participant The address of the participant to punish.
     * @param _slashAmount The amount of staked tokens to slash (in AMIND).
     * @param _reason A description of why the participant is being punished.
     */
    function punishParticipant(address _participant, uint256 _slashAmount, string memory _reason) public onlyOwner {
        // In a full DAO, this would be triggered by a successful governance vote.
        Participant storage p = participants[_participant];
        require(p.role != ParticipantRole.None, "Aethermind: Participant not registered.");
        require(_slashAmount <= p.stakedAmount, "Aethermind: Slash amount exceeds staked amount.");
        require(bytes(_reason).length > 0, "Aethermind: Reason for punishment cannot be empty.");

        p.stakedAmount = p.stakedAmount.sub(_slashAmount);
        // Reduce reputation (e.g., -100 reputation points per 10 AMIND slashed)
        p.reputation = p.reputation.sub(_slashAmount.div(10) > p.reputation ? p.reputation : _slashAmount.div(10));
        
        // Transfer slashed funds to a DAO treasury or burn them
        require(AMIND_TOKEN.transfer(owner(), _slashAmount), "Aethermind: Failed to transfer slashed funds.");

        emit ParticipantPunished(_participant, _slashAmount, p.reputation, _reason);
    }

    /**
     * @notice (Callable by owner/governance) Increases a participant's reputation.
     *         Used as a reward for successful contributions or positive dispute resolution.
     * @param _participant The address of the participant to reward.
     * @param _reputationBonus The amount of reputation points to add.
     * @param _reason A description of why the participant is being rewarded.
     */
    function rewardParticipant(address _participant, uint256 _reputationBonus, string memory _reason) public onlyOwner {
        // In a full DAO, this would be triggered by a successful governance vote.
        Participant storage p = participants[_participant];
        require(p.role != ParticipantRole.None, "Aethermind: Participant not registered.");
        require(_reputationBonus > 0, "Aethermind: Reputation bonus must be positive.");
        require(bytes(_reason).length > 0, "Aethermind: Reason for reward cannot be empty.");

        p.reputation = p.reputation.add(_reputationBonus);
        // Cap reputation at a max value, e.g., 2000
        if (p.reputation > 2000) p.reputation = 2000;

        emit ParticipantRewarded(_participant, _reputationBonus, p.reputation, _reason);
    }

    /**
     * @notice (Callable by owner/governance after a voting process) Resolves a dispute, distributing funds,
     *         applying penalties/rewards, and updating reputations based on the determined outcome.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _outcome The determined outcome of the dispute.
     * @param _winnerAddress The address of the party who won the dispute.
     * @param _loserAddress The address of the party who lost the dispute.
     * @param _penaltyAmount The amount of tokens to penalize the loser.
     */
    function resolveDispute(bytes32 _disputeId, DisputeOutcome _outcome, address _winnerAddress, address _loserAddress, uint256 _penaltyAmount) public onlyOwner {
        // In a full DAO, this would be triggered by a successful governance vote.
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.initiator != address(0), "Aethermind: Dispute not found.");
        require(dispute.outcome == DisputeOutcome.Pending, "Aethermind: Dispute already resolved.");
        require(_outcome != DisputeOutcome.Pending && _outcome != DisputeOutcome.Cancelled, "Aethermind: Invalid outcome for resolution.");
        require(participants[_winnerAddress].role != ParticipantRole.None, "Aethermind: Winner not a registered participant.");
        require(participants[_loserAddress].role != ParticipantRole.None, "Aethermind: Loser not a registered participant.");
        require(_penaltyAmount <= participants[_loserAddress].stakedAmount, "Aethermind: Penalty exceeds loser's stake.");

        dispute.outcome = _outcome;

        if (dispute.isTrainingDispute) {
            TrainingRequest storage req = trainingRequests[dispute.associatedId];
            if (_outcome == DisputeOutcome.ResolvedInFavorOfInitiator) { // Developer/Validator wins dispute against Trainer
                // Refund developer's initial deposit
                participants[req.developer].fundsToClaim = participants[req.developer].fundsToClaim.add(req.totalCostToConsumer);
                // Punish trainer
                punishParticipant(_loserAddress, _penaltyAmount, "Loss in training dispute.");
                req.status = TrainingStatus.Resolved; // Training deemed unsuccessful
            } else { // Trainer wins dispute against Developer/Validator
                // Pay trainer for work
                uint256 trainerPayment = req.totalCostToConsumer.sub(req.totalCostToConsumer.mul(platformFeePercentage).div(10000));
                participants[req.assignedTrainer].fundsToClaim = participants[req.assignedTrainer].fundsToClaim.add(trainerPayment);
                // Optionally, punish initiator if dispute was frivolous
                // punishParticipant(_loserAddress, _penaltyAmount, "Frivolous dispute.");
                req.status = TrainingStatus.Verified; // Training deemed successful
            }
        } else { // Inference Dispute
            InferenceRequest storage req = inferenceRequests[dispute.associatedId];
            ModelArchitecture storage modelArch = modelArchitectures[req.trainedModelHash]; // Assuming a link to original model architecture.

            if (_outcome == DisputeOutcome.ResolvedInFavorOfInitiator) { // Consumer/Validator wins dispute against Executor
                // Refund consumer
                participants[req.consumer].fundsToClaim = participants[req.consumer].fundsToClaim.add(req.maxInferencePrice);
                // Punish executor
                punishParticipant(_loserAddress, _penaltyAmount, "Loss in inference dispute.");
                req.status = InferenceStatus.Resolved; // Inference deemed unsuccessful
            } else { // Executor wins dispute against Consumer/Validator
                // Pay executor
                uint256 executorPayment = req.agreedPrice.sub(req.agreedPrice.mul(platformFeePercentage).div(10000));
                
                // Calculate and allocate royalty to Model Developer
                uint256 royaltyAmount = executorPayment.mul(modelArch.inferenceRoyaltyPercentage).div(10000);
                participants[modelArch.owner].fundsToClaim = participants[modelArch.owner].fundsToClaim.add(royaltyAmount);
                req.royaltyAmount = royaltyAmount; // Store for transparency
                
                executorPayment = executorPayment.sub(royaltyAmount); // Executor gets remaining after royalty
                participants[req.assignedExecutor].fundsToClaim = participants[req.assignedExecutor].fundsToClaim.add(executorPayment);
                
                // Optionally, punish initiator if dispute was frivolous
                // punishParticipant(_loserAddress, _penaltyAmount, "Frivolous dispute.");
                req.status = InferenceStatus.Verified; // Inference deemed successful
            }
        }

        emit DisputeResolved(_disputeId, _outcome, _winnerAddress, _loserAddress, _penaltyAmount);
    }

    /**
     * @notice Allows any participant to claim their accumulated earnings from successfully completed tasks
     *         (training, inference) and resolved disputes.
     */
    function claimFunds() public onlyRegistered {
        uint256 amount = participants[msg.sender].fundsToClaim;
        require(amount > 0, "Aethermind: No funds to claim.");

        participants[msg.sender].fundsToClaim = 0;
        require(AMIND_TOKEN.transfer(msg.sender, amount), "Aethermind: Failed to transfer funds.");

        emit FundsClaimed(msg.sender, amount);
    }

    // --- 11. Governance (Simplified) ---

    /**
     * @notice Allows a participant with sufficient stake/reputation to submit a proposal for protocol changes.
     *         The proposal URI points to off-chain details (e.g., in IPFS).
     * @param _proposalURI URI to off-chain details of the proposal.
     */
    function proposeProtocolChange(string memory _proposalURI) public onlyRegistered {
        // Implement minimum reputation/stake for proposing
        require(participants[msg.sender].reputation >= 500, "Aethermind: Not enough reputation to propose.");
        require(bytes(_proposalURI).length > 0, "Aethermind: Proposal URI cannot be empty.");

        uint256 currentProposalId = nextProposalId;
        proposals[currentProposalId] = Proposal({
            proposalId: currentProposalId,
            proposer: msg.sender,
            proposalURI: _proposalURI,
            yayVotes: 0,
            nayVotes: 0,
            requiredStakeForVoting: 100 * (10 ** 18), // Example: 100 AMIND to vote
            submissionTimestamp: block.timestamp,
            votingDeadline: block.timestamp.add(7 days), // 7 days voting period
            executed: false
        });
        nextProposalId++;

        emit ProposalSubmitted(currentProposalId, msg.sender, _proposalURI);
    }

    /**
     * @notice Allows staked participants to vote on active governance proposals.
     *         Requires a minimum stake to vote.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yay' vote, false for 'nay' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegistered {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Aethermind: Proposal not found.");
        require(block.timestamp < proposal.votingDeadline, "Aethermind: Voting period has ended.");
        require(!proposal.executed, "Aethermind: Proposal already executed.");
        require(!proposalVotes[msg.sender][_proposalId], "Aethermind: Already voted on this proposal.");
        
        // Requires a minimum stake to vote
        require(participants[msg.sender].stakedAmount >= proposal.requiredStakeForVoting, "Aethermind: Insufficient stake to vote.");

        if (_support) {
            proposal.yayVotes = proposal.yayVotes.add(1);
        } else {
            proposal.nayVotes = proposal.nayVotes.add(1);
        }
        proposalVotes[msg.sender][_proposalId] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _support);

        // Simple execution: if voting period ends and yay > nay and total votes > threshold.
        // In a real DAO, execution would be a separate function called after deadline.
    }
}
```