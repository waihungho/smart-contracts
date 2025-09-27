```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using OpenZeppelin's IERC20 interface for token interaction.

/**
 * @title QuantumFlux AI Network - Decentralized AI Model Co-creation & Inference Platform
 * @author Your Name/AI
 * @notice This contract facilitates a decentralized ecosystem for AI model development, data contribution,
 * and inference services. Participants can earn rewards based on their contributions and the
 * quality of their work, governed by a reputation and staking mechanism.
 *
 * @dev Core Concepts:
 * - Data Providers (DAPs): Contribute data proofs and stake for data quality.
 * - Model Builders (MOBs): Develop and submit AI models, referencing contributed data.
 * - Inference Nodes (INFs): Execute AI models to provide inference services.
 * - Users (USRs): Request AI inference and provide feedback.
 * - Validators (VALs): Oversee data proof, model quality, and inference accuracy.
 * - Reputation & Staking: Ensures participant quality and deters malicious behavior.
 * - Revenue Sharing: Models can distribute inference revenue to contributing DAPs.
 * - Dispute Resolution: On-chain mechanisms for challenging contributions and results.
 * - DAO Governance: For system parameter adjustments and major decisions.
 */

// Function Summary:
//
// I. Participant Management & Identity
//    1.  registerParticipant(role, profileURI): Allows a new user to register for a specific role (Data Provider, Model Builder, Inference Node, Validator). Requires an initial stake.
//    2.  updateParticipantProfile(role, newProfileURI): Allows participants to update their profile information (e.g., IPFS hash of a description).
//    3.  deregisterParticipant(role): Initiates a process to remove a participant from a role, unbonding their stake after a period.
//    4.  getParticipantInfo(addr): Retrieves detailed information about a registered participant.
//
// II. Data Contribution & Validation (for Data Providers)
//    5.  submitDataProof(ipfsHash, minUtilityStake): DAPs submit a cryptographic proof of their dataset (e.g., IPFS hash, or a pointer to a ZK-proof). Requires staking for data utility/quality.
//    6.  challengeDataProof(proofId, reasonURI): Allows anyone to challenge the validity, uniqueness, or utility of a submitted data proof. Requires a challenger stake.
//    7.  resolveDataProofChallenge(proofId, verdict, arbitratorStake): Arbitrators or DAO vote to resolve a data proof challenge, potentially slashing or rewarding.
//    8.  getDataProofDetails(proofId): Retrieves details of a specific data proof.
//
// III. Model Submission & Quality Assurance (for Model Builders)
//    9.  submitAIModel(modelHash, dataProofIds, initialInferenceCost, revenueShareBP): MOBs submit a new AI model (IPFS hash of weights/architecture), linking it to specific data proofs used for training. Sets initial inference cost and revenue share percentage.
//    10. updateAIModel(modelId, newModelHash, newInferenceCost, newRevenueShareBP): MOBs submit an updated version of their model, or modify its parameters.
//    11. requestModelEvaluation(modelId, evaluatorStake): Initiates a formal evaluation process for a model's performance/safety, typically by validators.
//    12. submitModelEvaluationResult(modelId, evaluatorAddress, score, evaluationReportURI): Evaluators submit their assessment for a model.
//    13. setModelStatus(modelId, newStatus): DAO/Validators can change a model's operational status (e.g., 'Approved', 'UnderReview', 'Deprecated').
//    14. getAIModelDetails(modelId): Retrieves comprehensive details about an AI model.
//
// IV. Inference Marketplace (for Inference Nodes & Users)
//    15. requestInference(modelId, inputDataHash, maxPayment): Users request AI inference from a model, specifying input data and max payment. Payment is held in escrow.
//    16. submitInferenceResult(requestId, outputDataHash, inferenceNodeAddress): Inference Nodes submit the hash of the inference output and claim payment.
//    17. challengeInferenceResult(requestId, reasonURI): Users/Validators can challenge an inference result if it's incorrect, too slow, or unavailable. Requires a challenge stake.
//    18. resolveInferenceChallenge(requestId, verdict, arbitratorStake): Arbitrators/DAO resolve an inference challenge.
//    19. rateInferenceService(requestId, rating): Users provide a qualitative rating for an inference node's service.
//
// V. Ecosystem & Governance
//    20. claimModelRevenue(modelId, participantAddress): Allows MOBs, DAPs, and other stakeholders to claim their share of accrued model inference revenue.
//    21. updateSystemParameter(paramName, newValue): A DAO-governed function to update critical system parameters (e.g., minimum stakes, challenge periods).
//    22. getReputation(addr): Retrieves the current reputation score of a participant.
//    23. getTotalStaked(addr): Retrieves the total tokens staked by a participant across all roles/contributions.

contract QuantumFluxAINetwork {
    IERC20 public immutable QFT; // QuantumFlux Token (ERC20)

    // --- Enums ---
    enum Role { None, DataProvider, ModelBuilder, InferenceNode, Validator }
    enum DataProofStatus { Pending, Challenged, Approved, Rejected }
    enum ModelStatus { Pending, UnderReview, Approved, Challenged, Deprecated }
    enum InferenceRequestStatus { Requested, Assigned, ResultSubmitted, Challenged, Completed, Failed }
    enum DisputeType { DataProof, ModelQuality, InferenceResult }
    enum DisputeStatus { Open, Voting, Resolved }
    enum ProposalStatus { Active, Passed, Failed, Executed }

    // --- Structs ---

    struct Participant {
        Role role;
        bool active;
        uint256 stake; // Total stake for this specific role
        uint256 reputation; // 0-10000, higher is better
        string profileURI; // IPFS hash or URL for profile details
        uint256 registeredTime;
    }

    struct DataProof {
        address provider;
        string ipfsHash; // Hash of the data or ZK-proof reference
        uint256 utilityStake;
        DataProofStatus status;
        uint256 challengeStake; // Stake from challenger if challenged
        address challenger;
        string challengeReasonURI;
        uint256 creationTime;
        uint256 challengeDeadline; // Time until challenge can be submitted
        uint256 resolutionTime;
    }

    struct AIModel {
        address builder;
        string modelHash; // IPFS hash of model weights/architecture
        uint256[] dataProofIds; // IDs of DataProofs used for training
        uint256 inferenceCost; // Cost per inference in QFT
        uint256 revenueShareBP; // Basis Points (0-10000) for data providers from inference revenue
        ModelStatus status;
        uint256 evaluationScore; // Average score from evaluators
        uint256 totalInferenceRevenue; // Accumulated revenue before distribution
        uint256 creationTime;
    }

    struct InferenceRequest {
        address requester;
        uint256 modelId;
        string inputDataHash; // IPFS hash of input data
        uint256 paymentAmount; // Amount paid by requester
        address assignedNode; // Inference node that picked up the request
        InferenceRequestStatus status;
        string outputDataHash; // IPFS hash of output data
        uint256 requestTime;
        uint256 challengeDeadline;
        uint256 rating; // User rating 0-5
        address challenger; // If challenged
        string challengeReasonURI; // If challenged
        uint256 challengeStake; // If challenged
    }

    struct Dispute {
        address challenger;
        uint256 challengeStake;
        string reasonURI;
        uint256 disputedItemId; // ID of the item being disputed (data proof, model, inference)
        DisputeType disputeType;
        DisputeStatus status;
        bool resolutionVerdict; // true: challenger wins, false: challenged wins
        uint256 resolutionTime;
    }

    struct Proposal {
        address proposer;
        string descriptionURI;
        string parameterName; // Name of system parameter to change
        uint256 newValue; // New value for the parameter
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted;
        uint256 quorumRequired; // Percentage of total staked QFT required for a proposal to pass
        uint256 votingDeadline;
        ProposalStatus status;
    }

    // --- State Variables ---
    address public owner; // The deployer, can be transferred or replaced by DAO later.
    uint256 public totalStakedQFT; // Total QFT tokens staked in the contract

    // Mappings for Participant management
    mapping(address => Participant) public participants;
    mapping(address => bool) public isValidator; // Simplified validator role management

    // Mappings for DataProofs
    DataProof[] public dataProofs;
    uint256 public nextDataProofId = 0;

    // Mappings for AIModels
    AIModel[] public aiModels;
    uint256 public nextModelId = 0;

    // Mappings for Inference Requests
    InferenceRequest[] public inferenceRequests;
    uint256 public nextRequestId = 0;

    // Mappings for Disputes
    Dispute[] public disputes;
    uint256 public nextDisputeId = 0;

    // Mappings for DAO Proposals
    Proposal[] public proposals;
    uint256 public nextProposalId = 0;

    // System Parameters (can be updated via DAO proposals)
    uint256 public MIN_PARTICIPANT_STAKE = 100 ether; // Example: 100 QFT
    uint256 public MIN_DATA_UTILITY_STAKE = 50 ether;
    uint256 public MIN_CHALLENGE_STAKE = 20 ether;
    uint256 public UNBONDING_PERIOD = 7 days; // Time to unbond stake
    uint256 public CHALLENGE_PERIOD = 2 days; // Time window to challenge
    uint256 public EVALUATION_PERIOD = 5 days; // Time for model evaluation
    uint256 public PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public DAO_QUORUM_PERCENT = 51; // 51% of total staked QFT

    // --- Events ---
    event ParticipantRegistered(address indexed participant, Role role, string profileURI, uint256 stake);
    event ParticipantProfileUpdated(address indexed participant, Role role, string newProfileURI);
    event ParticipantDeregistered(address indexed participant, Role role);
    event DataProofSubmitted(uint256 indexed proofId, address indexed provider, string ipfsHash, uint256 utilityStake);
    event DataProofChallenged(uint256 indexed proofId, address indexed challenger, string reasonURI);
    event DataProofResolved(uint256 indexed proofId, bool verdict, uint256 resolutionTime);
    event AIModelSubmitted(uint256 indexed modelId, address indexed builder, string modelHash, uint256 inferenceCost);
    event AIModelUpdated(uint256 indexed modelId, string newModelHash, uint256 newInferenceCost);
    event ModelEvaluationRequested(uint256 indexed modelId, address indexed requester, uint256 evaluatorStake);
    event ModelEvaluationResultSubmitted(uint256 indexed modelId, address indexed evaluator, uint256 score);
    event ModelStatusChanged(uint256 indexed modelId, ModelStatus newStatus);
    event InferenceRequested(uint256 indexed requestId, uint256 indexed modelId, address indexed requester, uint256 paymentAmount);
    event InferenceResultSubmitted(uint256 indexed requestId, address indexed inferenceNode, string outputHash);
    event InferenceResultChallenged(uint256 indexed requestId, address indexed challenger, string reasonURI);
    event InferenceResultResolved(uint256 indexed requestId, bool verdict);
    event InferenceServiceRated(uint256 indexed requestId, address indexed requester, uint256 rating);
    event RevenueClaimed(uint256 indexed modelId, address indexed participant, uint256 amount);
    event SystemParameterUpdated(string paramName, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string paramName, uint256 newValue);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event StakeIncreased(address indexed participant, uint256 amount);
    event StakeDecreased(address indexed participant, uint256 amount);
    event ReputationChanged(address indexed participant, uint256 oldReputation, uint256 newReputation);

    // --- Custom Errors ---
    error InvalidRole();
    error ParticipantNotRegistered(Role role);
    error InsufficientStake(uint256 required, uint256 provided);
    error AlreadyRegistered(Role role);
    error RoleNotActive(Role role);
    error DataProofNotFound();
    error DataProofNotPending();
    error ChallengeNotPossible(string reason);
    error InvalidDataProofStatus();
    error ModelNotFound();
    error ModelNotPending();
    error OnlyModelBuilder();
    error ModelNotApproved();
    error InvalidModelStatus();
    error InferenceRequestNotFound();
    error InferenceNotRequested();
    error InferenceResultAlreadySubmitted();
    error InferenceNotAssigned();
    error OnlyAssignedNode();
    error NotEnoughRevenue();
    error InvalidShareRecipient();
    error OnlyValidator();
    error ProposalNotFound();
    error ProposalNotActive();
    error AlreadyVoted();
    error VotingPeriodExpired();
    error QuorumNotReached();
    error InvalidParameterName();
    error Unauthorized();
    error ChallengePeriodNotOver();
    error UnbondingPeriodNotOver();


    modifier onlyRole(Role _role) {
        if (participants[msg.sender].role != _role) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyValidator() {
        if (!isValidator[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address _qftTokenAddress, address[] memory _initialValidators) {
        owner = msg.sender;
        QFT = IERC20(_qftTokenAddress);

        for (uint256 i = 0; i < _initialValidators.length; i++) {
            isValidator[_initialValidators[i]] = true;
            // Optionally, register them as participants or assume they exist
            if (participants[_initialValidators[i]].role == Role.None) {
                participants[_initialValidators[i]] = Participant({
                    role: Role.Validator,
                    active: true,
                    stake: 0, // Validators might have a separate stake mechanism or just be elected
                    reputation: 10000,
                    profileURI: "",
                    registeredTime: block.timestamp
                });
            }
        }
    }

    // --- I. Participant Management & Identity ---

    /**
     * @notice Registers a new participant for a specific role and requires an initial stake.
     * @param _role The role to register for (DataProvider, ModelBuilder, InferenceNode, Validator).
     * @param _profileURI IPFS hash or URL for the participant's profile details.
     */
    function registerParticipant(Role _role, string memory _profileURI) public {
        if (_role == Role.None) {
            revert InvalidRole();
        }
        if (participants[msg.sender].role != Role.None) {
            revert AlreadyRegistered(_role);
        }
        if (_role == Role.Validator) {
             revert InvalidRole(); // Validators are set by owner initially or DAO
        }

        // Transfer stake from user to contract
        if (!QFT.transferFrom(msg.sender, address(this), MIN_PARTICIPANT_STAKE)) {
            revert InsufficientStake(MIN_PARTICIPANT_STAKE, QFT.balanceOf(msg.sender));
        }

        participants[msg.sender] = Participant({
            role: _role,
            active: true,
            stake: MIN_PARTICIPANT_STAKE,
            reputation: 5000, // Starting reputation
            profileURI: _profileURI,
            registeredTime: block.timestamp
        });
        totalStakedQFT += MIN_PARTICIPANT_STAKE;

        emit ParticipantRegistered(msg.sender, _role, _profileURI, MIN_PARTICIPANT_STAKE);
    }

    /**
     * @notice Allows participants to update their profile information.
     * @param _role The participant's role.
     * @param _newProfileURI New IPFS hash or URL for profile details.
     */
    function updateParticipantProfile(Role _role, string memory _newProfileURI) public {
        if (participants[msg.sender].role != _role) {
            revert ParticipantNotRegistered(_role);
        }
        participants[msg.sender].profileURI = _newProfileURI;
        emit ParticipantProfileUpdated(msg.sender, _role, _newProfileURI);
    }

    /**
     * @notice Initiates a process to remove a participant from a role and unbond their stake.
     *         Stake can be withdrawn after UNBONDING_PERIOD.
     * @param _role The participant's role to deregister from.
     */
    function deregisterParticipant(Role _role) public {
        if (participants[msg.sender].role != _role) {
            revert ParticipantNotRegistered(_role);
        }
        if (_role == Role.Validator) {
            revert InvalidRole(); // Validators can't deregister this way
        }

        Participant storage p = participants[msg.sender];
        p.active = false; // Mark as inactive
        // Stake remains locked for UNBONDING_PERIOD
        // A separate function would be needed to claim the stake after the period
        emit ParticipantDeregistered(msg.sender, _role);
    }

    /**
     * @notice Retrieves detailed information about a registered participant.
     * @param _addr The address of the participant.
     * @return Participant struct containing role, active status, stake, reputation, and profile URI.
     */
    function getParticipantInfo(address _addr) public view returns (Participant memory) {
        return participants[_addr];
    }

    // --- II. Data Contribution & Validation (for Data Providers) ---

    /**
     * @notice Data Providers submit a cryptographic proof of their dataset.
     *         Requires staking QFT for data utility/quality.
     * @param _ipfsHash IPFS hash of the data or a ZK-proof reference.
     * @param _minUtilityStake The minimum stake the DAP commits for this data proof's utility.
     */
    function submitDataProof(string memory _ipfsHash, uint256 _minUtilityStake) public onlyRole(Role.DataProvider) {
        if (_minUtilityStake < MIN_DATA_UTILITY_STAKE) {
            revert InsufficientStake(MIN_DATA_UTILITY_STAKE, _minUtilityStake);
        }
        if (!QFT.transferFrom(msg.sender, address(this), _minUtilityStake)) {
            revert InsufficientStake(_minUtilityStake, QFT.balanceOf(msg.sender));
        }

        dataProofs.push(DataProof({
            provider: msg.sender,
            ipfsHash: _ipfsHash,
            utilityStake: _minUtilityStake,
            status: DataProofStatus.Pending,
            challengeStake: 0,
            challenger: address(0),
            challengeReasonURI: "",
            creationTime: block.timestamp,
            challengeDeadline: block.timestamp + CHALLENGE_PERIOD,
            resolutionTime: 0
        }));
        nextDataProofId++;
        totalStakedQFT += _minUtilityStake;
        participants[msg.sender].stake += _minUtilityStake;

        emit DataProofSubmitted(nextDataProofId - 1, msg.sender, _ipfsHash, _minUtilityStake);
    }

    /**
     * @notice Allows anyone to challenge the validity, uniqueness, or utility of a submitted data proof.
     *         Requires a challenger stake.
     * @param _proofId The ID of the data proof to challenge.
     * @param _reasonURI IPFS hash or URL for the reason for the challenge.
     */
    function challengeDataProof(uint256 _proofId, string memory _reasonURI) public {
        if (_proofId >= nextDataProofId) {
            revert DataProofNotFound();
        }
        DataProof storage proof = dataProofs[_proofId];
        if (proof.status != DataProofStatus.Pending) {
            revert DataProofNotPending();
        }
        if (block.timestamp > proof.challengeDeadline) {
            revert ChallengeNotPossible("Challenge period has ended.");
        }
        if (proof.challenger != address(0)) {
            revert ChallengeNotPossible("Proof already challenged.");
        }

        if (!QFT.transferFrom(msg.sender, address(this), MIN_CHALLENGE_STAKE)) {
            revert InsufficientStake(MIN_CHALLENGE_STAKE, QFT.balanceOf(msg.sender));
        }

        proof.status = DataProofStatus.Challenged;
        proof.challenger = msg.sender;
        proof.challengeStake = MIN_CHALLENGE_STAKE;
        proof.challengeReasonURI = _reasonURI;
        totalStakedQFT += MIN_CHALLENGE_STAKE;
        // The challenger doesn't have a direct 'role' stake, it's just a challenge stake.

        // Create a new dispute entry
        disputes.push(Dispute({
            challenger: msg.sender,
            challengeStake: MIN_CHALLENGE_STAKE,
            reasonURI: _reasonURI,
            disputedItemId: _proofId,
            disputeType: DisputeType.DataProof,
            status: DisputeStatus.Open,
            resolutionVerdict: false, // Default
            resolutionTime: 0
        }));
        nextDisputeId++;

        emit DataProofChallenged(_proofId, msg.sender, _reasonURI);
    }

    /**
     * @notice Arbitrators (validators or DAO) resolve a data proof challenge.
     *         Rewards/slashes stakes based on verdict.
     * @param _proofId The ID of the data proof being challenged.
     * @param _verdict True if challenger wins (proof is invalid), false if challenged wins (proof is valid).
     * @param _arbitratorStake Optional, for arbitrators to stake on their verdict.
     */
    function resolveDataProofChallenge(uint256 _proofId, bool _verdict, uint256 _arbitratorStake) public onlyValidator {
        if (_proofId >= nextDataProofId) {
            revert DataProofNotFound();
        }
        DataProof storage proof = dataProofs[_proofId];
        if (proof.status != DataProofStatus.Challenged) {
            revert InvalidDataProofStatus();
        }
        if (block.timestamp < proof.challengeDeadline) { // Ensure challenge period is over
             revert ChallengePeriodNotOver();
        }
        if(proof.challenger == address(0)) {
            revert ChallengeNotPossible("No active challenge for this proof.");
        }

        // Transfer arbitrator stake (optional, for more complex systems)
        if (_arbitratorStake > 0) {
            if (!QFT.transferFrom(msg.sender, address(this), _arbitratorStake)) {
                revert InsufficientStake(_arbitratorStake, QFT.balanceOf(msg.sender));
            }
            totalStakedQFT += _arbitratorStake;
        }

        proof.status = _verdict ? DataProofStatus.Rejected : DataProofStatus.Approved;
        proof.resolutionTime = block.timestamp;

        // Update stakes and reputation
        if (_verdict) { // Challenger wins (proof is invalid)
            // Challenger gets their stake back + a portion of provider's utility stake
            uint256 reward = proof.utilityStake / 2; // Example: 50% of provider's stake
            if (QFT.transfer(proof.challenger, proof.challengeStake + reward)) {
                totalStakedQFT -= (proof.challengeStake + reward);
            }
            proof.challengeStake = 0; // Clear challenger stake
            proof.utilityStake -= reward; // Provider loses reward portion
            participants[proof.provider].stake -= reward;
            QFT.transfer(proof.provider, proof.utilityStake); // Return remaining utility stake to provider
            totalStakedQFT -= proof.utilityStake;
            participants[proof.provider].stake -= proof.utilityStake;
            _adjustReputation(proof.provider, false); // Decrease provider reputation
            _adjustReputation(proof.challenger, true); // Increase challenger reputation
        } else { // Challenged wins (proof is valid)
            // Provider gets utility stake back + challenger's stake
            uint256 reward = proof.challengeStake / 2; // Example: 50% of challenger's stake
            if (QFT.transfer(proof.provider, proof.utilityStake + reward)) {
                totalStakedQFT -= (proof.utilityStake + reward);
            }
            proof.utilityStake = 0; // Clear provider stake
            proof.challengeStake -= reward; // Challenger loses reward portion
            QFT.transfer(proof.challenger, proof.challengeStake); // Return remaining challenger stake
            totalStakedQFT -= proof.challengeStake;
            _adjustReputation(proof.provider, true); // Increase provider reputation
            _adjustReputation(proof.challenger, false); // Decrease challenger reputation
        }
        
        // Update the dispute status
        for(uint i=0; i<nextDisputeId; i++) {
            if(disputes[i].disputedItemId == _proofId && disputes[i].disputeType == DisputeType.DataProof && disputes[i].status == DisputeStatus.Open) {
                disputes[i].status = DisputeStatus.Resolved;
                disputes[i].resolutionVerdict = _verdict;
                disputes[i].resolutionTime = block.timestamp;
                break;
            }
        }

        emit DataProofResolved(_proofId, _verdict, block.timestamp);
    }

    /**
     * @notice Retrieves details of a specific data proof.
     * @param _proofId The ID of the data proof.
     * @return DataProof struct.
     */
    function getDataProofDetails(uint256 _proofId) public view returns (DataProof memory) {
        if (_proofId >= nextDataProofId) {
            revert DataProofNotFound();
        }
        return dataProofs[_proofId];
    }

    // --- III. Model Submission & Quality Assurance (for Model Builders) ---

    /**
     * @notice Model Builders submit a new AI model, linking it to data proofs.
     * @param _modelHash IPFS hash of model weights/architecture.
     * @param _dataProofIds Array of IDs of DataProofs used for training.
     * @param _initialInferenceCost Cost per inference in QFT.
     * @param _revenueShareBP Basis Points (0-10000) for data providers from inference revenue.
     */
    function submitAIModel(
        string memory _modelHash,
        uint256[] memory _dataProofIds,
        uint256 _initialInferenceCost,
        uint256 _revenueShareBP
    ) public onlyRole(Role.ModelBuilder) {
        if (_revenueShareBP > 10000) {
            revert InvalidShareRecipient(); // Revenue share cannot exceed 100%
        }

        // Verify data proofs are approved
        for (uint256 i = 0; i < _dataProofIds.length; i++) {
            if (_dataProofIds[i] >= nextDataProofId || dataProofs[_dataProofIds[i]].status != DataProofStatus.Approved) {
                revert InvalidDataProofStatus();
            }
        }

        aiModels.push(AIModel({
            builder: msg.sender,
            modelHash: _modelHash,
            dataProofIds: _dataProofIds,
            inferenceCost: _initialInferenceCost,
            revenueShareBP: _revenueShareBP,
            status: ModelStatus.Pending, // Awaiting evaluation
            evaluationScore: 0,
            totalInferenceRevenue: 0,
            creationTime: block.timestamp
        }));
        nextModelId++;

        emit AIModelSubmitted(nextModelId - 1, msg.sender, _modelHash, _initialInferenceCost);
    }

    /**
     * @notice Model Builders submit an updated version of their model, or modify its parameters.
     * @param _modelId The ID of the model to update.
     * @param _newModelHash New IPFS hash of model weights/architecture (can be empty if not updating hash).
     * @param _newInferenceCost New cost per inference.
     * @param _newRevenueShareBP New basis points for data providers.
     */
    function updateAIModel(
        uint256 _modelId,
        string memory _newModelHash,
        uint256 _newInferenceCost,
        uint256 _newRevenueShareBP
    ) public onlyRole(Role.ModelBuilder) {
        if (_modelId >= nextModelId) {
            revert ModelNotFound();
        }
        AIModel storage model = aiModels[_modelId];
        if (model.builder != msg.sender) {
            revert Unauthorized(); // Only model builder can update
        }
        if (_newRevenueShareBP > 10000) {
            revert InvalidShareRecipient();
        }

        if (bytes(_newModelHash).length > 0) {
            model.modelHash = _newModelHash;
        }
        model.inferenceCost = _newInferenceCost;
        model.revenueShareBP = _newRevenueShareBP;
        model.status = ModelStatus.UnderReview; // Force re-evaluation if updated
        model.evaluationScore = 0; // Reset score

        emit AIModelUpdated(_modelId, _newModelHash, _newInferenceCost);
    }

    /**
     * @notice Initiates a formal evaluation process for a model's performance/safety.
     *         Typically requested by validators or can be triggered by a DAO.
     * @param _modelId The ID of the model to evaluate.
     * @param _evaluatorStake Optional stake from the evaluator.
     */
    function requestModelEvaluation(uint256 _modelId, uint256 _evaluatorStake) public onlyValidator {
        if (_modelId >= nextModelId) {
            revert ModelNotFound();
        }
        AIModel storage model = aiModels[_modelId];
        if (model.status == ModelStatus.Approved || model.status == ModelStatus.Deprecated) {
             revert ChallengeNotPossible("Model status does not allow re-evaluation.");
        }
        
        // Transfer evaluator stake (optional)
        if (_evaluatorStake > 0) {
            if (!QFT.transferFrom(msg.sender, address(this), _evaluatorStake)) {
                revert InsufficientStake(_evaluatorStake, QFT.balanceOf(msg.sender));
            }
            totalStakedQFT += _evaluatorStake;
        }

        model.status = ModelStatus.UnderReview;
        // Logic for assigning evaluation tasks off-chain, or tracking evaluation progress
        // This function just flags it for review.
        emit ModelEvaluationRequested(_modelId, msg.sender, _evaluatorStake);
    }

    /**
     * @notice Evaluators (validators) submit their assessment for a model.
     * @param _modelId The ID of the model.
     * @param _evaluatorAddress The address of the evaluator.
     * @param _score The evaluation score (e.g., 0-100).
     * @param _evaluationReportURI IPFS hash or URL for the detailed evaluation report.
     */
    function submitModelEvaluationResult(uint256 _modelId, address _evaluatorAddress, uint256 _score, string memory _evaluationReportURI) public onlyValidator {
        // Only a registered validator can submit an evaluation
        if (!isValidator[msg.sender]) {
            revert Unauthorized();
        }

        if (_modelId >= nextModelId) {
            revert ModelNotFound();
        }
        AIModel storage model = aiModels[_modelId];
        if (model.status != ModelStatus.UnderReview) {
            revert InvalidModelStatus();
        }
        // In a real system, there would be a more complex system for multiple evaluators
        // For simplicity, we'll just set the score.
        model.evaluationScore = _score;
        // Decide status based on score, e.g., if score > threshold, then Approved
        if (_score >= 70) { // Example threshold
            model.status = ModelStatus.Approved;
        } else {
            model.status = ModelStatus.Pending; // Needs more work/review
        }

        emit ModelEvaluationResultSubmitted(_modelId, _evaluatorAddress, _score);
    }

    /**
     * @notice DAO/Validators can change a model's operational status.
     * @param _modelId The ID of the model.
     * @param _newStatus The new status for the model (e.g., Approved, Deprecated).
     */
    function setModelStatus(uint256 _modelId, ModelStatus _newStatus) public onlyValidator {
        if (_modelId >= nextModelId) {
            revert ModelNotFound();
        }
        AIModel storage model = aiModels[_modelId];
        // Restrict status changes based on current status and new status
        if (_newStatus == ModelStatus.Pending || _newStatus == ModelStatus.UnderReview) {
            revert InvalidModelStatus(); // These are internal statuses, not set directly.
        }
        model.status = _newStatus;
        emit ModelStatusChanged(_modelId, _newStatus);
    }

    /**
     * @notice Retrieves comprehensive details about an AI model.
     * @param _modelId The ID of the AI model.
     * @return AIModel struct.
     */
    function getAIModelDetails(uint256 _modelId) public view returns (AIModel memory) {
        if (_modelId >= nextModelId) {
            revert ModelNotFound();
        }
        return aiModels[_modelId];
    }

    // --- IV. Inference Marketplace (for Inference Nodes & Users) ---

    /**
     * @notice Users request AI inference from a model, specifying input data and max payment.
     *         Payment is held in escrow.
     * @param _modelId The ID of the model to use for inference.
     * @param _inputDataHash IPFS hash of the input data for inference.
     * @param _maxPayment The maximum QFT the user is willing to pay for this inference.
     */
    function requestInference(uint256 _modelId, string memory _inputDataHash, uint256 _maxPayment) public {
        if (_modelId >= nextModelId) {
            revert ModelNotFound();
        }
        AIModel storage model = aiModels[_modelId];
        if (model.status != ModelStatus.Approved) {
            revert ModelNotApproved();
        }
        if (_maxPayment < model.inferenceCost) {
            revert InsufficientStake(model.inferenceCost, _maxPayment);
        }
        if (!QFT.transferFrom(msg.sender, address(this), model.inferenceCost)) {
            revert InsufficientStake(model.inferenceCost, QFT.balanceOf(msg.sender));
        }

        inferenceRequests.push(InferenceRequest({
            requester: msg.sender,
            modelId: _modelId,
            inputDataHash: _inputDataHash,
            paymentAmount: model.inferenceCost,
            assignedNode: address(0), // No node assigned yet
            status: InferenceRequestStatus.Requested,
            outputDataHash: "",
            requestTime: block.timestamp,
            challengeDeadline: 0, // Set after result submission
            rating: 0,
            challenger: address(0),
            challengeReasonURI: "",
            challengeStake: 0
        }));
        nextRequestId++;
        totalStakedQFT += model.inferenceCost;

        emit InferenceRequested(nextRequestId - 1, _modelId, msg.sender, model.inferenceCost);
    }

    /**
     * @notice Inference Nodes submit the hash of the inference output and claim payment.
     * @param _requestId The ID of the inference request.
     * @param _outputDataHash IPFS hash of the inference output.
     * @param _inferenceNodeAddress The address of the inference node providing the result.
     */
    function submitInferenceResult(uint256 _requestId, string memory _outputDataHash, address _inferenceNodeAddress) public onlyRole(Role.InferenceNode) {
        if (_requestId >= nextRequestId) {
            revert InferenceRequestNotFound();
        }
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != InferenceRequestStatus.Requested && request.status != InferenceRequestStatus.Assigned) {
            revert InferenceNotRequested();
        }
        if (request.assignedNode != address(0) && request.assignedNode != msg.sender) {
            revert OnlyAssignedNode(); // If already assigned, only that node can submit
        }
        if (bytes(request.outputDataHash).length > 0) {
            revert InferenceResultAlreadySubmitted();
        }

        request.assignedNode = _inferenceNodeAddress;
        request.outputDataHash = _outputDataHash;
        request.status = InferenceRequestStatus.ResultSubmitted;
        request.challengeDeadline = block.timestamp + CHALLENGE_PERIOD;

        // Payment is released after challenge period or if no challenge.
        emit InferenceResultSubmitted(_requestId, _inferenceNodeAddress, _outputDataHash);
    }

    /**
     * @notice Users/Validators can challenge an inference result if it's incorrect, too slow, or unavailable.
     * @param _requestId The ID of the inference request.
     * @param _reasonURI IPFS hash or URL for the reason for the challenge.
     */
    function challengeInferenceResult(uint256 _requestId, string memory _reasonURI) public {
        if (_requestId >= nextRequestId) {
            revert InferenceRequestNotFound();
        }
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != InferenceRequestStatus.ResultSubmitted) {
            revert ChallengeNotPossible("Inference result not submitted or already resolved.");
        }
        if (block.timestamp > request.challengeDeadline) {
            revert ChallengeNotPossible("Challenge period has ended.");
        }
        if (request.challenger != address(0)) {
            revert ChallengeNotPossible("Inference result already challenged.");
        }
        
        // Challenger pays MIN_CHALLENGE_STAKE
        if (!QFT.transferFrom(msg.sender, address(this), MIN_CHALLENGE_STAKE)) {
            revert InsufficientStake(MIN_CHALLENGE_STAKE, QFT.balanceOf(msg.sender));
        }

        request.status = InferenceRequestStatus.Challenged;
        request.challenger = msg.sender;
        request.challengeReasonURI = _reasonURI;
        request.challengeStake = MIN_CHALLENGE_STAKE;
        totalStakedQFT += MIN_CHALLENGE_STAKE;

        // Create a new dispute entry
        disputes.push(Dispute({
            challenger: msg.sender,
            challengeStake: MIN_CHALLENGE_STAKE,
            reasonURI: _reasonURI,
            disputedItemId: _requestId,
            disputeType: DisputeType.InferenceResult,
            status: DisputeStatus.Open,
            resolutionVerdict: false, // Default
            resolutionTime: 0
        }));
        nextDisputeId++;

        emit InferenceResultChallenged(_requestId, msg.sender, _reasonURI);
    }

    /**
     * @notice Arbitrators/DAO resolve an inference challenge.
     * @param _requestId The ID of the inference request.
     * @param _verdict True if challenger wins (result is incorrect), false if challenged wins (result is correct).
     * @param _arbitratorStake Optional, for arbitrators to stake on their verdict.
     */
    function resolveInferenceChallenge(uint256 _requestId, bool _verdict, uint256 _arbitratorStake) public onlyValidator {
        if (_requestId >= nextRequestId) {
            revert InferenceRequestNotFound();
        }
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.status != InferenceRequestStatus.Challenged) {
            revert ChallengeNotPossible("Inference request not challenged or already resolved.");
        }
        if (block.timestamp < request.challengeDeadline) {
             revert ChallengePeriodNotOver();
        }

        // Transfer arbitrator stake (optional)
        if (_arbitratorStake > 0) {
            if (!QFT.transferFrom(msg.sender, address(this), _arbitratorStake)) {
                revert InsufficientStake(_arbitratorStake, QFT.balanceOf(msg.sender));
            }
            totalStakedQFT += _arbitratorStake;
        }

        request.status = _verdict ? InferenceRequestStatus.Failed : InferenceRequestStatus.Completed;

        // Payout logic
        if (_verdict) { // Challenger wins (inference result is incorrect)
            // Challenger gets their stake back + a portion of inference node's earnings
            uint256 reward = request.paymentAmount / 2; // Example: 50% of payment
            if (QFT.transfer(request.challenger, request.challengeStake + reward)) {
                totalStakedQFT -= (request.challengeStake + reward);
            }
            request.challengeStake = 0;
            // Inference node gets nothing, loses potential revenue.
            // Reputational impact
            _adjustReputation(request.assignedNode, false);
            _adjustReputation(request.challenger, true);
            // Return original payment to requester if result was bad
            if (QFT.transfer(request.requester, request.paymentAmount)) {
                totalStakedQFT -= request.paymentAmount;
            }
        } else { // Challenged wins (inference result is correct)
            // Inference node gets full payment + a portion of challenger's stake
            uint256 reward = request.challengeStake / 2;
            if (QFT.transfer(request.assignedNode, request.paymentAmount + reward)) {
                totalStakedQFT -= (request.paymentAmount + reward);
            }
            // Challenger loses their stake portion, gets remaining back
            request.challengeStake -= reward;
            if (QFT.transfer(request.challenger, request.challengeStake)) {
                totalStakedQFT -= request.challengeStake;
            }
            _adjustReputation(request.assignedNode, true);
            _adjustReputation(request.challenger, false);
        }
        
        // Update the dispute status
        for(uint i=0; i<nextDisputeId; i++) {
            if(disputes[i].disputedItemId == _requestId && disputes[i].disputeType == DisputeType.InferenceResult && disputes[i].status == DisputeStatus.Open) {
                disputes[i].status = DisputeStatus.Resolved;
                disputes[i].resolutionVerdict = _verdict;
                disputes[i].resolutionTime = block.timestamp;
                break;
            }
        }

        emit InferenceResultResolved(_requestId, _verdict);
    }

    /**
     * @notice Users provide a qualitative rating for an inference node's service.
     * @param _requestId The ID of the inference request.
     * @param _rating The rating (e.g., 1-5 stars).
     */
    function rateInferenceService(uint256 _requestId, uint256 _rating) public {
        if (_requestId >= nextRequestId) {
            revert InferenceRequestNotFound();
        }
        InferenceRequest storage request = inferenceRequests[_requestId];
        if (request.requester != msg.sender) {
            revert Unauthorized();
        }
        if (request.status != InferenceRequestStatus.Completed) {
            revert InferenceNotAssigned(); // Can only rate completed requests
        }
        if (request.rating != 0) {
            revert ChallengeNotPossible("Already rated.");
        }
        if (_rating == 0 || _rating > 5) {
            revert ChallengeNotPossible("Invalid rating (must be 1-5).");
        }

        request.rating = _rating;
        // Optionally, integrate rating into reputation score for inference node
        // For simplicity, we just record it here.
        emit InferenceServiceRated(_requestId, msg.sender, _rating);
    }

    // --- V. Ecosystem & Governance ---

    /**
     * @notice Allows MOBs, DAPs, and other stakeholders to claim their share of accrued model inference revenue.
     * @param _modelId The ID of the model to claim revenue from.
     * @param _participantAddress The address of the participant claiming revenue.
     */
    function claimModelRevenue(uint256 _modelId, address _participantAddress) public {
        if (_modelId >= nextModelId) {
            revert ModelNotFound();
        }
        AIModel storage model = aiModels[_modelId];
        uint256 totalRevenue = model.totalInferenceRevenue;
        uint256 shareAmount = 0;

        if (msg.sender == model.builder) {
            // Model builder claims their portion (100% - revenueShareBP)
            shareAmount = (totalRevenue * (10000 - model.revenueShareBP)) / 10000;
        } else {
            // Data provider claims their proportional share
            for (uint256 i = 0; i < model.dataProofIds.length; i++) {
                if (dataProofs[model.dataProofIds[i]].provider == msg.sender) {
                    // Simple distribution: equal share among contributing DAPs
                    uint256 dapShare = (totalRevenue * model.revenueShareBP) / (10000 * model.dataProofIds.length);
                    shareAmount += dapShare;
                }
            }
        }

        if (shareAmount == 0) {
            revert NotEnoughRevenue();
        }

        model.totalInferenceRevenue -= shareAmount; // Deduct claimed amount
        if (!QFT.transfer(msg.sender, shareAmount)) {
            revert NotEnoughRevenue(); // Should not happen if totalRevenue is tracked correctly
        }
        totalStakedQFT -= shareAmount;

        emit RevenueClaimed(_modelId, msg.sender, shareAmount);
    }
    
    /**
     * @notice A DAO-governed function to update critical system parameters.
     *         This function can only be called if a proposal has passed.
     * @param _paramName The name of the parameter to update (e.g., "MIN_PARTICIPANT_STAKE").
     * @param _newValue The new value for the parameter.
     */
    function updateSystemParameter(string memory _paramName, uint256 _newValue) public onlyOwner {
        // In a full DAO implementation, this would be callable by the `executeProposal` function
        // For now, it's `onlyOwner` or can be adapted for a simpler DAO.
        bytes32 paramHash = keccak256(abi.encodePacked(_paramName));

        if (paramHash == keccak256(abi.encodePacked("MIN_PARTICIPANT_STAKE"))) {
            MIN_PARTICIPANT_STAKE = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("MIN_DATA_UTILITY_STAKE"))) {
            MIN_DATA_UTILITY_STAKE = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("MIN_CHALLENGE_STAKE"))) {
            MIN_CHALLENGE_STAKE = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("UNBONDING_PERIOD"))) {
            UNBONDING_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("CHALLENGE_PERIOD"))) {
            CHALLENGE_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("EVALUATION_PERIOD"))) {
            EVALUATION_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("PROPOSAL_VOTING_PERIOD"))) {
            PROPOSAL_VOTING_PERIOD = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("DAO_QUORUM_PERCENT"))) {
            DAO_QUORUM_PERCENT = _newValue;
        } else {
            revert InvalidParameterName();
        }
        emit SystemParameterUpdated(_paramName, _newValue);
    }
    
    /**
     * @notice Creates a new DAO proposal to change a system parameter.
     *         Requires a proposer stake (implicitly covered by participant stake).
     * @param _descriptionURI IPFS hash or URL for detailed proposal description.
     * @param _parameterName The name of the parameter to change.
     * @param _newValue The proposed new value.
     */
    function createProposal(string memory _descriptionURI, string memory _parameterName, uint256 _newValue) public {
        // Any registered participant can propose
        if (participants[msg.sender].role == Role.None || !participants[msg.sender].active) {
            revert ParticipantNotRegistered(Role.None);
        }

        proposals.push(Proposal({
            proposer: msg.sender,
            descriptionURI: _descriptionURI,
            parameterName: _parameterName,
            newValue: _newValue,
            voteCountYes: 0,
            voteCountNo: 0,
            hasVoted: new mapping(address => bool), // Initialize empty mapping
            quorumRequired: DAO_QUORUM_PERCENT, // Use current system parameter
            votingDeadline: block.timestamp + PROPOSAL_VOTING_PERIOD,
            status: ProposalStatus.Active
        }));
        nextProposalId++;

        emit ProposalCreated(nextProposalId - 1, msg.sender, _parameterName, _newValue);
    }

    /**
     * @notice Allows participants to vote on an active DAO proposal.
     *         Vote weight is proportional to their total staked QFT.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'Yes', false for 'No'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        if (_proposalId >= nextProposalId) {
            revert ProposalNotFound();
        }
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) {
            revert ProposalNotActive();
        }
        if (block.timestamp > proposal.votingDeadline) {
            revert VotingPeriodExpired();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }
        
        // Vote weight based on total stake of the participant (sum of all stakes)
        uint256 voterStake = participants[msg.sender].stake; // Example: only role stake
        // For a more robust system, sum all specific stakes (data proofs, challenges) for this voter.

        if (_support) {
            proposal.voteCountYes += voterStake;
        } else {
            proposal.voteCountNo += voterStake;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a passed DAO proposal, updating the system parameter.
     *         Can be called by anyone after the voting period has ended and quorum is met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        if (_proposalId >= nextProposalId) {
            revert ProposalNotFound();
        }
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) {
            revert ProposalNotActive();
        }
        if (block.timestamp <= proposal.votingDeadline) {
            revert ChallengeNotPossible("Voting period not over yet.");
        }

        uint256 totalVotes = proposal.voteCountYes + proposal.voteCountNo;
        uint256 yesPercentage = (proposal.voteCountYes * 100) / totalVotes;

        // Check quorum and passing threshold
        if (totalVotes * 100 / totalStakedQFT < proposal.quorumRequired || yesPercentage < 50) { // Example: 50% approval
            proposal.status = ProposalStatus.Failed;
            revert QuorumNotReached();
        }

        proposal.status = ProposalStatus.Passed; // Mark as passed, then execute

        // Execute the parameter update (only callable by owner in this simplified version)
        // In a full DAO, this would be a direct call to updateSystemParameter.
        // For this example, let's keep it simple and just call the internal logic.
        bytes32 paramHash = keccak256(abi.encodePacked(proposal.parameterName));

        if (paramHash == keccak256(abi.encodePacked("MIN_PARTICIPANT_STAKE"))) {
            MIN_PARTICIPANT_STAKE = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("MIN_DATA_UTILITY_STAKE"))) {
            MIN_DATA_UTILITY_STAKE = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("MIN_CHALLENGE_STAKE"))) {
            MIN_CHALLENGE_STAKE = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("UNBONDING_PERIOD"))) {
            UNBONDING_PERIOD = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("CHALLENGE_PERIOD"))) {
            CHALLENGE_PERIOD = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("EVALUATION_PERIOD"))) {
            EVALUATION_PERIOD = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("PROPOSAL_VOTING_PERIOD"))) {
            PROPOSAL_VOTING_PERIOD = proposal.newValue;
        } else if (paramHash == keccak256(abi.encodePacked("DAO_QUORUM_PERCENT"))) {
            DAO_QUORUM_PERCENT = proposal.newValue;
        } else {
            revert InvalidParameterName();
        }
        proposal.status = ProposalStatus.Executed; // Mark as executed
        emit ProposalExecuted(_proposalId);
        emit SystemParameterUpdated(proposal.parameterName, proposal.newValue);
    }


    /**
     * @notice Retrieves the current reputation score of a participant.
     * @param _addr The address of the participant.
     * @return The reputation score (0-10000).
     */
    function getReputation(address _addr) public view returns (uint256) {
        return participants[_addr].reputation;
    }

    /**
     * @notice Retrieves the total tokens staked by a participant across all roles/contributions.
     *         (Currently, only tracks role stake in 'participants' struct for simplicity).
     * @param _addr The address of the participant.
     * @return The total staked amount.
     */
    function getTotalStaked(address _addr) public view returns (uint256) {
        return participants[_addr].stake; // Simplified: only includes role stake
        // In a more complex system, this would sum up all specific stakes (data proofs, challenges etc.)
    }

    // --- Internal/Private Helper Functions ---

    /**
     * @dev Adjusts a participant's reputation.
     * @param _participant The address whose reputation to adjust.
     * @param _increase True to increase reputation, false to decrease.
     */
    function _adjustReputation(address _participant, bool _increase) internal {
        Participant storage p = participants[_participant];
        uint256 oldReputation = p.reputation;
        if (_increase) {
            p.reputation = p.reputation + 100 > 10000 ? 10000 : p.reputation + 100;
        } else {
            p.reputation = p.reputation < 50 ? 0 : p.reputation - 50;
        }
        emit ReputationChanged(_participant, oldReputation, p.reputation);
    }
}
```