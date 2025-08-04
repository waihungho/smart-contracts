Here's a Solidity smart contract for a concept I call **SAGE-AI: Self-Amending Generative Ecosystem for AI Models**.

This protocol envisions a decentralized marketplace and governance system for AI models. It introduces dynamic NFTs whose properties can evolve based on AI outputs or model performance, a sophisticated reputation system, and a novel "self-amending" governance mechanism that can even process proposals suggested by off-chain AI models (via an oracle pattern).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Outline: SAGE-AI Protocol ---
// A Self-Amending Generative Ecosystem for AI Models.
// This protocol enables the decentralized curation, consumption, and incentivization of AI models,
// fostering a dynamic environment where AI outputs can be tokenized as mutable NFTs,
// and the protocol itself can evolve through a sophisticated governance system informed by reputation and AI insights.

// 1. Core Protocol Mechanics:
//    - Ownership & Pausability for emergency control and system stability.
//    - Treasury Management & Fee Collection to sustain the ecosystem and fund development.
//    - Configuration Parameters for flexible and adaptable protocol adjustments.

// 2. AI Model Registry & Management:
//    - Lifecycle management of AI models (registration, update, deactivation) by vetted providers.
//    - Tracking of model performance metrics (successful/failed tasks) to inform reputation.

// 3. AI Task & Request System:
//    - User-initiated AI task requests, with payment escrowed until validation.
//    - Provider submission and validator-driven validation of task results.
//    - A dispute resolution mechanism to ensure fairness and quality control.

// 4. Reputation System:
//    - A multi-faceted dynamic reputation score for participants (model providers, validators, consumers).
//    - Reputation-based access, benefits, and punitive slashing for misconduct.

// 5. Dynamic NFT System (AIP-NFTs - AI Powered NFTs):
//    - Minting of unique NFTs that represent verifiable AI outputs.
//    - Ability for metadata and attributes of these NFTs to dynamically evolve based on subsequent AI interaction, performance, or external data feeds.

// 6. Self-Amending Governance (SAGE-DAO):
//    - A decentralized proposal and voting mechanism for key protocol parameter amendments.
//    - A novel integration point for AI-suggested amendments (via oracle pattern) as a source for governance proposals, enabling an adaptive protocol.
//    - Conceptual hooks for future contract upgrades (though direct code modification is not possible).

// 7. Stake & Lockup System:
//    - Staking mechanisms for various roles (Curator, Validator) to ensure commitment, prevent Sybil attacks, and unlock governance power.
//    - Managed unstaking with defined lockup periods to maintain protocol stability.

// --- Function Summary ---

// Core Protocol Mechanics:
// 1. constructor(address _sageTokenAddress): Initializes the contract, setting up the owner, the SAGE ERC-20 token, initial fees, and the AIP-NFT collection.
// 2. pause(): Halts most core protocol operations, primarily for emergency scenarios (callable by owner).
// 3. unpause(): Resumes core protocol operations after a pause (callable by owner).
// 4. setProtocolFee(uint256 _newFeeBps): Sets the percentage-based protocol fee (in basis points) on task payments. Controllable by owner/DAO.
// 5. withdrawProtocolFees(address _recipient, uint256 _amount): Transfers accumulated protocol fees from the contract's treasury to a specified recipient (callable by owner/DAO).

// AI Model Registry & Management:
// 6. registerAIModel(string calldata _modelURI, string calldata _modelType, uint256 _baseCost, address _paymentTokenAddress): Allows a staked AI model provider (Curator) to register a new AI model, detailing its URI, type, cost, and payment token.
// 7. updateAIModel(uint256 _modelId, string calldata _newModelURI, uint256 _newBaseCost): Enables an AI model provider to modify the URI and base cost of their registered model.
// 8. deactivateAIModel(uint256 _modelId): Changes an AI model's status to inactive, preventing it from being assigned new tasks (callable by provider or DAO).
// 9. getAIModelDetails(uint256 _modelId) view: Retrieves comprehensive information about a specific registered AI model.

// AI Task & Request System:
// 10. requestAITask(uint256 _modelId, string calldata _taskInputURI, uint256 _maxGasCost, uint256 _deadline): Allows users to request an AI service, specifying the model, input data, maximum gas compensation for the provider, and a completion deadline. Escrows payment.
// 11. submitAITaskResult(uint256 _taskId, string calldata _resultURI, bytes32 _resultHash): Enables the assigned AI model provider to submit the URI and cryptographic hash of the generated AI result for a task.
// 12. validateAITaskResult(uint256 _taskId, bool _isValid): Allows a staked validator (or DAO) to confirm or reject the validity of a submitted AI task result, triggering payment release or refund and reputation updates.
// 13. raiseDispute(uint256 _taskId, string calldata _reasonURI): Permits a user or validator to initiate a dispute against a submitted task result, providing a reason and pausing task progression.

// Reputation System:
// 14. getReputationScore(address _account) view: Returns the current aggregate reputation score for a given address.
// 15. getReputationFactors(address _account) view: Provides a detailed breakdown of the components contributing to an account's reputation (e.g., successful tasks, disputes).
// 16. slashReputation(address _account, uint256 _amount, string calldata _reason): A governance (DAO) function to reduce an account's reputation score due to severe misconduct, used for protocol integrity.

// Dynamic NFT System (AIP-NFTs):
// 17. mintAIPNFT(uint256 _taskId, address _to, string calldata _initialMetadataURI): Mints a unique AIP-NFT token to represent the output of a successfully completed and validated AI task.
// 18. updateAIPNFTMetadata(uint256 _tokenId, string calldata _newMetadataURI): Allows authorized entities (NFT owner, AI model provider, or DAO) to update the metadata URI of an AIP-NFT, enabling dynamic attribute changes.
// 19. getAIPNFTAttributeScore(uint256 _tokenId) view: Calculates a dynamic "attribute score" for an AIP-NFT based on its associated AI model's performance and other conceptual attributes.

// Self-Amending Governance (SAGE-DAO):
// 20. proposeParameterAmendment(bytes32 _parameterKey, uint256 _newValue, string calldata _descriptionURI): Enables staked participants to propose changes to core protocol parameters, initiating a voting process.
// 21. voteOnAmendment(uint256 _proposalId, bool _support): Allows staked participants to cast their vote (for or against) on an active governance proposal, with voting power proportional to their stake.
// 22. executeAmendment(uint256 _proposalId): Finalizes a successful proposal by applying the proposed parameter changes to the protocol.
// 23. proposeAIGeneratedAmendment(bytes32 _parameterKey, uint256 _newValue, string calldata _descriptionURI, bytes calldata _oracleProof): A specialized function for proposing amendments suggested by an off-chain AI via a trusted oracle, requiring cryptographic proof.

// Stake & Lockup System:
// 24. stakeForRole(uint256 _amount, bytes32 _role): Allows users to stake SAGE tokens to qualify for specific roles (e.g., Curator, Validator), providing commitment and unlocking governance participation.
// 25. unstake(uint256 _amount): Permits users to withdraw their staked SAGE tokens after a predefined lockup period has expired.

// --- Smart Contract Code ---

// Constants & Enums for clarity and state management
enum AIModelStatus { Active, Inactive }
enum TaskStatus { Pending, Assigned, ResultSubmitted, Validated, Disputed, Completed, Failed }
enum ProposalStatus { Pending, Active, Succeeded, Defeated, Executed }
enum StakeRole { None, Curator, Validator } // None is default, Curator for model providers, Validator for result validation

// OpenZeppelin's Counters library for unique IDs
library Counters {
    using Counters for Counters.Counter;
    Counters.Counter internal _modelIds;
    Counters.Counter internal _taskIds;
    Counters.Counter internal _proposalIds;
    // ERC721._tokenIds is also a Counter from OZ, not declared here.
}

// Custom Errors for gas efficiency and clearer error messages
error InvalidModelID();
error InvalidTaskID();
error InvalidProposalID();
error UnauthorizedAction();
error ModelNotActive();
error TaskNotPending();
error TaskNotResultSubmitted();
error AlreadyDisputed();
error NoActiveDispute();
error InsufficientStake();
error NotStakedForRole();
error StakeLockupActive();
error ZeroAmount();
error InsufficientBalance();
error ProposalNotActive();
error ProposalAlreadyVoted();
error ProposalNotSucceeded();
error ProposalAlreadyExecuted();
error AIPNFTNotMinted();
error MetadataUpdateUnauthorized();

contract SAGEAIProtocol is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using Counters for Counters.Counter; // Use Counters library functions

    // --- State Variables ---

    // Core Protocol Settings
    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 100 = 1%)
    address public treasuryAddress; // Address where accumulated protocol fees are held
    uint256 public minStakeCurator; // Minimum SAGE_TOKEN stake required for a Curator role
    uint256 public minStakeValidator; // Minimum SAGE_TOKEN stake required for a Validator role
    uint256 public stakeLockupDuration; // Duration in seconds for staked tokens to be locked
    uint256 public proposalVotingPeriod; // Duration in seconds for governance proposals to be voted on

    IERC20 public immutable SAGE_TOKEN; // The ERC-20 token used for staking and payments

    // AI Model Registry
    struct AIModel {
        uint256 id;
        address provider; // Address of the AI model provider
        string modelURI; // URI to off-chain model description, API endpoint, or detailed specs (e.g., IPFS CID)
        string modelType; // Categorization of the AI model (e.g., "image_generation", "text_summary", "data_analysis")
        uint256 baseCost; // Base cost in SAGE_TOKEN for using this model per task
        address paymentTokenAddress; // The ERC20 token address accepted for payments to this model
        AIModelStatus status; // Current status of the model (active/inactive)
        uint256 successfulTasks; // Count of tasks successfully completed by this model
        uint256 failedTasks; // Count of tasks failed by this model
    }
    mapping(uint256 => AIModel) public aiModels; // Maps model ID to AIModel struct
    mapping(address => uint224[]) public providerModels; // Maps provider address to an array of their model IDs (using uint224 for ID to save space, assuming IDs won't exceed)
    Counters.Counter private _modelIds; // Internal counter for unique AI model IDs

    // AI Task System
    struct AITask {
        uint256 id;
        uint256 modelId; // ID of the AI model used for this task
        address requester; // Address of the user who requested the task
        address assignedProvider; // The AI model provider who accepted/submitted results for this task
        string taskInputURI; // URI to the input data for the AI task (e.g., IPFS CID)
        string resultURI; // URI to the AI generated result (e.g., IPFS CID)
        bytes32 resultHash; // Cryptographic hash of the result to verify integrity off-chain
        uint256 paymentAmount; // Total amount paid for the task by the requester (includes base cost + gas compensation)
        address paymentTokenAddress; // ERC20 token used for this task's payment
        uint256 deadline; // Timestamp by which the task result must be submitted
        TaskStatus status; // Current status of the AI task
        bool disputed; // True if the task result is currently under dispute
        address disputer; // Address of the party who raised the dispute
        address currentDisputeValidator; // (Optional) Validator assigned to resolve the dispute, for future expansion
        uint256 mintedAIPNFTId; // The ID of the AIP-NFT minted from this task, 0 if none
    }
    mapping(uint256 => AITask) public aiTasks; // Maps task ID to AITask struct
    Counters.Counter private _taskIds; // Internal counter for unique AI task IDs
    mapping(address => uint224[]) public requesterTasks; // Maps requester address to their task IDs
    mapping(address => uint224[]) public providerAssignedTasks; // Maps provider address to tasks they are assigned to

    // Reputation System
    struct Reputation {
        uint256 score; // The primary reputation score
        uint256 successfulTasks; // Number of tasks successfully contributed to (as provider or validator)
        uint256 disputesRaised; // Number of valid disputes successfully raised
        uint256 disputesResolved; // Number of disputes successfully resolved as a validator
        uint256 penalties; // Accumulated penalty points from reputation slashing
    }
    mapping(address => Reputation) public reputations; // Maps address to Reputation struct

    // Stake & Role Management
    struct StakeInfo {
        uint256 amount; // Amount of SAGE_TOKEN staked
        uint256 lockupEnd; // Timestamp when the staked amount can be unstaked
        StakeRole role; // The role the user has staked for (e.g., Curator, Validator)
    }
    mapping(address => StakeInfo) public stakes; // Maps user address to their StakeInfo

    // Self-Amending Governance (SAGE-DAO)
    struct Proposal {
        uint256 id;
        bytes32 parameterKey; // Key of the protocol parameter to be changed (e.g., keccak256("protocolFeeBps"))
        uint256 newValue; // The proposed new value for the parameter
        string descriptionURI; // URI to detailed proposal description (e.g., IPFS link to governance document)
        address proposer; // Address of the proposer
        uint256 votingDeadline; // Timestamp when voting for this proposal ends
        uint256 votesFor; // Total voting power for the proposal
        uint256 votesAgainst; // Total voting power against the proposal
        mapping(address => bool) hasVoted; // Tracks if an address has already voted on this proposal
        ProposalStatus status; // Current status of the proposal
        bytes oracleProof; // Placeholder for cryptographic proof from an AI oracle for AI-generated proposals
    }
    mapping(uint256 => Proposal) public proposals; // Maps proposal ID to Proposal struct
    Counters.Counter private _proposalIds; // Internal counter for unique proposal IDs

    // AIP-NFT (Dynamic NFT) related
    // The base ERC721 contract (inherited) handles token ownership and metadata URI.
    // This mapping links an AIP-NFT token ID back to the AI task that generated it.
    mapping(uint256 => uint256) public aipNFTTaskMapping; // AIP-NFT ID => Task ID

    // --- Events ---
    event ProtocolFeeSet(uint256 newFeeBps); // Emitted when the protocol fee is updated
    event FeesWithdrawn(address indexed recipient, uint224 amount); // Emitted when fees are withdrawn from treasury (using uint224 to save bytes, assuming amount won't exceed)
    event AIModelRegistered(uint256 indexed modelId, address indexed provider, string modelURI, string modelType); // Emitted when a new AI model is registered
    event AIModelUpdated(uint256 indexed modelId, string newModelURI, uint256 newBaseCost); // Emitted when an AI model's details are updated
    event AIModelDeactivated(uint256 indexed modelId); // Emitted when an AI model is deactivated
    event AITaskRequested(uint256 indexed taskId, uint256 indexed modelId, address indexed requester, uint256 paymentAmount); // Emitted when a new AI task is requested
    event AITaskResultSubmitted(uint256 indexed taskId, address indexed provider, string resultURI); // Emitted when an AI task result is submitted
    event AITaskValidated(uint256 indexed taskId, address indexed validator, bool isValid); // Emitted when an AI task result is validated
    event DisputeRaised(uint256 indexed taskId, address indexed disputer, string reasonURI); // Emitted when a dispute is raised for a task
    event ReputationUpdated(address indexed account, uint256 newScore); // Emitted when an account's reputation score changes
    event ReputationSlashed(address indexed account, uint200 amount, string reason); // Emitted when an account's reputation is slashed (using uint200 for amount to save bytes)
    event AIPNFTMinted(uint256 indexed tokenId, uint256 indexed taskId, address indexed to); // Emitted when a new AIP-NFT is minted
    event AIPNFTMetadataUpdated(uint256 indexed tokenId, string newMetadataURI); // Emitted when an AIP-NFT's metadata is updated
    event ParameterAmendmentProposed(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue, address indexed proposer); // Emitted when a new governance proposal is made
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support); // Emitted when a vote is cast on a proposal
    event AmendmentExecuted(uint256 indexed proposalId); // Emitted when a governance proposal is successfully executed
    event Staked(address indexed account, uint256 amount, bytes32 role); // Emitted when tokens are staked for a role
    event Unstaked(address indexed account, uint256 amount); // Emitted when tokens are unstaked

    // Constructor: Initializes the contract upon deployment
    /// @param _sageTokenAddress The address of the SAGE ERC-20 token contract.
    constructor(address _sageTokenAddress) ERC721("AI Powered Protocol NFT", "AIP-NFT") Ownable(msg.sender) {
        require(_sageTokenAddress != address(0), "SAGE token address cannot be zero");
        SAGE_TOKEN = IERC20(_sageTokenAddress);

        protocolFeeBps = 500; // 5% initial fee (500 basis points)
        treasuryAddress = msg.sender; // Owner is initially the treasury address, can be changed by DAO
        minStakeCurator = 1000 * (10 ** SAGE_TOKEN.decimals()); // Example: 1000 SAGE tokens
        minStakeValidator = 2000 * (10 ** SAGE_TOKEN.decimals()); // Example: 2000 SAGE tokens
        stakeLockupDuration = 30 days; // 30 days lockup period for staked tokens
        proposalVotingPeriod = 7 days; // 7 days for governance proposals to be voted on
    }

    // --- Internal / Helper Modifiers & Functions for DAO ---
    // DAO_ROLE is a constant representing the governance role. In a full system,
    // this would be managed by an OpenZeppelin AccessControl contract and a Governor.
    // Here, `onlyRoleOrOwner` simulates DAO control, allowing either the contract owner
    // or an address granted the `DAO_ROLE` to perform certain actions.
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    /// @notice Modifier that restricts access to functions to either the contract owner or an address with the DAO_ROLE.
    modifier onlyRoleOrOwner(bytes32 role) {
        require(hasRole(role, msg.sender) || owner() == msg.sender, "Caller is not DAO or Owner");
        _;
    }

    // For simplicity, the `owner()` can grant/revoke the DAO_ROLE directly.
    // In a production system, a separate Governor contract would manage roles.
    /// @notice Grants the DAO_ROLE to a specified account. Only callable by the contract owner.
    /// @param _account The address to grant the DAO_ROLE to.
    function grantDAORole(address _account) public onlyOwner {
        _grantRole(DAO_ROLE, _account);
    }

    /// @notice Revokes the DAO_ROLE from a specified account. Only callable by the contract owner.
    /// @param _account The address to revoke the DAO_ROLE from.
    function revokeDAORole(address _account) public onlyOwner {
        _revokeRole(DAO_ROLE, _account);
    }

    // Overriding the _approve and _setTokenURI functions from ERC721
    // to include the Pausable check, as they modify state.
    function _approve(address to, uint256 tokenId) internal override whenNotPaused {
        super._approve(to, tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override whenNotPaused {
        super._setTokenURI(tokenId, _tokenURI);
    }

    // --- Core Protocol Mechanics ---

    /// @notice Pauses core operations of the contract. Prevents most state-changing functions from being called.
    /// Only callable by the contract owner. Essential for emergency situations (e.g., critical bug, market anomaly).
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses core operations of the contract, allowing all functions to resume.
    /// Only callable by the contract owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the protocol fee applied to AI task payments.
    /// The fee is specified in basis points (e.g., 100 = 1%, 500 = 5%). Maximum is 10000 (100%).
    /// Can be updated by the owner or by a successful DAO proposal.
    /// @param _newFeeBps The new protocol fee in basis points.
    function setProtocolFee(uint256 _newFeeBps) public virtual onlyRoleOrOwner(DAO_ROLE) {
        require(_newFeeBps <= 10000, "Fee cannot exceed 100%");
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeSet(_newFeeBps);
    }

    /// @notice Allows the owner or DAO to withdraw accumulated protocol fees from the contract's treasury.
    /// Fees are held in SAGE_TOKEN.
    /// @param _recipient The address to which the collected fees will be sent.
    /// @param _amount The specific amount of SAGE_TOKEN to withdraw.
    function withdrawProtocolFees(address _recipient, uint256 _amount) public onlyRoleOrOwner(DAO_ROLE) nonReentrant {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(_amount > 0, "Amount must be greater than zero");
        uint256 treasuryBalance = SAGE_TOKEN.balanceOf(address(this));
        require(treasuryBalance >= _amount, "Insufficient treasury balance");

        SAGE_TOKEN.transfer(_recipient, _amount);
        emit FeesWithdrawn(_recipient, uint224(_amount));
    }

    // --- AI Model Registry & Management ---

    /// @notice Allows an AI model provider to register a new AI model with the protocol.
    /// The caller must have an active stake as a `Curator` to be eligible.
    /// @param _modelURI URI (e.g., IPFS CID) pointing to a description or API endpoint of the AI model.
    /// @param _modelType A string categorizing the AI model's functionality (e.g., "image_generation", "NLP").
    /// @param _baseCost The base cost in SAGE_TOKEN that users must pay per task using this model.
    /// @param _paymentTokenAddress The address of the ERC20 token that this model accepts for task payments.
    /// @return The unique ID of the newly registered model.
    function registerAIModel(
        string calldata _modelURI,
        string calldata _modelType,
        uint256 _baseCost,
        address _paymentTokenAddress
    ) public whenNotPaused returns (uint256) {
        require(bytes(_modelURI).length > 0, "Model URI cannot be empty");
        require(bytes(_modelType).length > 0, "Model type cannot be empty");
        require(_baseCost > 0, "Base cost must be greater than zero");
        require(_paymentTokenAddress != address(0), "Payment token address cannot be zero");
        require(stakes[msg.sender].role == StakeRole.Curator, "Must be staked as a Curator to register a model");

        _modelIds.increment();
        uint256 newModelId = _modelIds.current();

        aiModels[newModelId] = AIModel({
            id: newModelId,
            provider: msg.sender,
            modelURI: _modelURI,
            modelType: _modelType,
            baseCost: _baseCost,
            paymentTokenAddress: _paymentTokenAddress,
            status: AIModelStatus.Active,
            successfulTasks: 0,
            failedTasks: 0
        });
        providerModels[msg.sender].push(uint224(newModelId));

        emit AIModelRegistered(newModelId, msg.sender, _modelURI, _modelType);
        return newModelId;
    }

    /// @notice Allows an AI model provider to update the details of their registered model.
    /// Only the original provider of the model can perform this action.
    /// @param _modelId The ID of the model to be updated.
    /// @param _newModelURI The new URI for the model's description or endpoint.
    /// @param _newBaseCost The new base cost for using this model.
    function updateAIModel(
        uint256 _modelId,
        string calldata _newModelURI,
        uint256 _newBaseCost
    ) public whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.id == 0) revert InvalidModelID();
        if (model.provider != msg.sender) revert UnauthorizedAction();

        require(bytes(_newModelURI).length > 0, "New Model URI cannot be empty");
        require(_newBaseCost > 0, "New base cost must be greater than zero");

        model.modelURI = _newModelURI;
        model.baseCost = _newBaseCost;

        emit AIModelUpdated(_modelId, _newModelURI, _newBaseCost);
    }

    /// @notice Deactivates an AI model, preventing it from being used for new tasks.
    /// Existing tasks assigned to the model will still proceed.
    /// Can be called by the model's provider or by an address with the DAO_ROLE.
    /// @param _modelId The ID of the model to deactivate.
    function deactivateAIModel(uint256 _modelId) public whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.id == 0) revert InvalidModelID();
        if (model.provider != msg.sender && !hasRole(DAO_ROLE, msg.sender)) revert UnauthorizedAction();

        model.status = AIModelStatus.Inactive;
        emit AIModelDeactivated(_modelId);
    }

    /// @notice Retrieves comprehensive details about a specific registered AI model.
    /// @param _modelId The ID of the model to query.
    /// @return A tuple containing all stored information about the AI model.
    function getAIModelDetails(
        uint256 _modelId
    )
        public
        view
        returns (
            uint256 id,
            address provider,
            string memory modelURI,
            string memory modelType,
            uint256 baseCost,
            address paymentTokenAddress,
            AIModelStatus status,
            uint256 successfulTasks,
            uint256 failedTasks
        )
    {
        AIModel storage model = aiModels[_modelId];
        if (model.id == 0) revert InvalidModelID();
        return (
            model.id,
            model.provider,
            model.modelURI,
            model.modelType,
            model.baseCost,
            model.paymentTokenAddress,
            model.status,
            model.successfulTasks,
            model.failedTasks
        );
    }

    // --- AI Task & Request System ---

    /// @notice Allows users to request an AI task by specifying a registered AI model.
    /// The total payment (model's base cost + estimated gas compensation) is transferred from the requester
    /// to the contract as escrow and held until the task is validated.
    /// @param _modelId The ID of the AI model to be used for the task.
    /// @param _taskInputURI URI (e.g., IPFS CID) pointing to the input data required for the AI task.
    /// @param _maxGasCost An estimated maximum amount of SAGE_TOKEN to compensate the AI provider for transaction gas fees related to submitting the result.
    /// @param _deadline A Unix timestamp by which the AI task must be completed and its result submitted.
    /// @return The unique ID of the newly created task.
    function requestAITask(
        uint256 _modelId,
        string calldata _taskInputURI,
        uint256 _maxGasCost,
        uint256 _deadline
    ) public whenNotPaused nonReentrant returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        if (model.id == 0) revert InvalidModelID();
        if (model.status != AIModelStatus.Active) revert ModelNotActive();
        require(bytes(_taskInputURI).length > 0, "Task input URI cannot be empty");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        uint256 totalCost = model.baseCost + _maxGasCost; // Base cost for model + gas compensation
        IERC20 paymentToken = IERC20(model.paymentTokenAddress); // The specific payment token for this model
        require(paymentToken.balanceOf(msg.sender) >= totalCost, "Insufficient payment token balance");
        require(paymentToken.allowance(msg.sender, address(this)) >= totalCost, "Insufficient token allowance");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        // Transfer payment to contract (held in escrow until task validation)
        paymentToken.transferFrom(msg.sender, address(this), totalCost);

        aiTasks[newTaskId] = AITask({
            id: newTaskId,
            modelId: _modelId,
            requester: msg.sender,
            assignedProvider: address(0), // Provider is assigned when they submit the result
            taskInputURI: _taskInputURI,
            resultURI: "",
            resultHash: bytes32(0),
            paymentAmount: totalCost,
            paymentTokenAddress: model.paymentTokenAddress,
            deadline: _deadline,
            status: TaskStatus.Pending,
            disputed: false,
            disputer: address(0),
            currentDisputeValidator: address(0),
            mintedAIPNFTId: 0
        });

        requesterTasks[msg.sender].push(uint224(newTaskId));
        emit AITaskRequested(newTaskId, _modelId, msg.sender, totalCost);
        return newTaskId;
    }

    /// @notice Allows an AI model provider to submit the result for a pending AI task.
    /// The first provider to call this function for a `Pending` task implicitly claims the task.
    /// Subsequent calls by other providers for the same `Pending` task will revert.
    /// @param _taskId The ID of the task for which the result is being submitted.
    /// @param _resultURI URI (e.g., IPFS CID) pointing to the AI-generated output.
    /// @param _resultHash A cryptographic hash (e.g., Keccak256) of the result data, for off-chain integrity verification.
    function submitAITaskResult(
        uint256 _taskId,
        string calldata _resultURI,
        bytes32 _resultHash
    ) public whenNotPaused nonReentrant {
        AITask storage task = aiTasks[_taskId];
        if (task.id == 0) revert InvalidTaskID();
        if (task.status != TaskStatus.Pending && task.assignedProvider != msg.sender) revert TaskNotPending(); // If not pending, then must be assigned to sender
        require(bytes(_resultURI).length > 0, "Result URI cannot be empty");
        require(_resultHash != bytes32(0), "Result hash cannot be zero");
        require(block.timestamp <= task.deadline, "Task deadline passed");

        if (task.assignedProvider == address(0)) { // If task is pending, the current sender claims it
            task.assignedProvider = msg.sender;
            providerAssignedTasks[msg.sender].push(uint224(_taskId));
        } else {
            require(task.assignedProvider == msg.sender, "Task already assigned to another provider");
        }

        task.resultURI = _resultURI;
        task.resultHash = _resultHash;
        task.status = TaskStatus.ResultSubmitted;

        emit AITaskResultSubmitted(_taskId, msg.sender, _resultURI);
    }

    /// @notice Allows a validator (or DAO) to confirm or reject a submitted AI task result.
    /// The caller must have an active stake as a `Validator`.
    /// If valid, the AI provider is paid (minus protocol fees), and their reputation is boosted.
    /// If invalid, the requester is refunded, and the provider's reputation is penalized.
    /// @param _taskId The ID of the task to validate.
    /// @param _isValid True if the result is deemed valid, false if invalid.
    function validateAITaskResult(uint256 _taskId, bool _isValid) public whenNotPaused nonReentrant {
        AITask storage task = aiTasks[_taskId];
        if (task.id == 0) revert InvalidTaskID();
        if (task.status != TaskStatus.ResultSubmitted && task.status != TaskStatus.Disputed) revert TaskNotResultSubmitted();
        require(stakes[msg.sender].role == StakeRole.Validator, "Must be staked as a Validator to validate");

        AIModel storage model = aiModels[task.modelId];
        address provider = task.assignedProvider;
        uint256 paymentAmount = task.paymentAmount;
        IERC20 paymentToken = IERC20(task.paymentTokenAddress);

        if (_isValid) {
            task.status = TaskStatus.Completed;
            _updateReputation(provider, true); // Provider gains reputation
            model.successfulTasks++; // Model's success count increases

            // Calculate fees and provider's share
            uint256 protocolShare = (paymentAmount * protocolFeeBps) / 10000;
            uint256 providerShare = paymentAmount - protocolShare;

            // Fees are implicitly held in the contract for later withdrawal by DAO
            if (providerShare > 0) {
                paymentToken.transfer(provider, providerShare); // Pay provider
            }
        } else {
            task.status = TaskStatus.Failed;
            _updateReputation(provider, false); // Provider loses reputation
            model.failedTasks++; // Model's failure count increases
            // Refund the requester the full escrowed amount (minus any dispute penalties in a more complex system)
            paymentToken.transfer(task.requester, paymentAmount);
        }
        // Update validator's reputation
        _updateReputation(msg.sender, true); // Validator gains reputation for validating

        emit AITaskValidated(_taskId, msg.sender, _isValid);
    }

    /// @notice Allows any user or a validator to raise a dispute against a submitted AI task result.
    /// This changes the task status to `Disputed` and prevents further action until the dispute is resolved.
    /// @param _taskId The ID of the task to dispute.
    /// @param _reasonURI URI (e.g., IPFS CID) pointing to the detailed reason and evidence for the dispute.
    function raiseDispute(uint256 _taskId, string calldata _reasonURI) public whenNotPaused {
        AITask storage task = aiTasks[_taskId];
        if (task.id == 0) revert InvalidTaskID();
        if (task.status != TaskStatus.ResultSubmitted) revert TaskNotResultSubmitted(); // Can only dispute submitted results
        if (task.disputed) revert AlreadyDisputed(); // Cannot dispute an already disputed task
        require(bytes(_reasonURI).length > 0, "Reason URI cannot be empty");

        task.disputed = true;
        task.disputer = msg.sender;
        task.status = TaskStatus.Disputed; // Task remains in disputed state until re-validated

        // In a more complex dispute system, this would trigger:
        // 1. Assignment of a neutral dispute validator (or panel).
        // 2. A specific voting process for resolution.
        // For this example, re-calling `validateAITaskResult` by a validator (potentially a new one) resolves it.

        emit DisputeRaised(_taskId, msg.sender, _reasonURI);
    }

    // --- Reputation System ---

    /// @notice Internal function to update the reputation score of an account.
    /// Called automatically after successful task completions, validations, or failures.
    /// @param _account The address whose reputation is being updated.
    /// @param _success A boolean indicating if the action (e.g., task completion, validation) was successful.
    function _updateReputation(address _account, bool _success) internal {
        Reputation storage rep = reputations[_account];
        if (_success) {
            rep.score += 10; // Positive reputation for successful actions
            rep.successfulTasks++;
        } else {
            if (rep.score >= 5) {
                rep.score -= 5; // Negative reputation for failures
            } else {
                rep.score = 0; // Score cannot go below zero
            }
            // `failedTasks` is not explicitly tracked in Reputation struct, but derived from context or task-specific metrics.
        }
        emit ReputationUpdated(_account, rep.score);
    }

    /// @notice Retrieves the current overall reputation score for a specific account.
    /// @param _account The address to query.
    /// @return The current reputation score.
    function getReputationScore(address _account) public view returns (uint256) {
        return reputations[_account].score;
    }

    /// @notice Retrieves a detailed breakdown of factors contributing to an account's reputation.
    /// Provides transparency into how the reputation score is derived.
    /// @param _account The address to query.
    /// @return A tuple containing the total score and specific contributing metrics.
    function getReputationFactors(
        address _account
    )
        public
        view
        returns (
            uint256 score,
            uint256 successfulTasks,
            uint256 disputesRaised,
            uint256 disputesResolved,
            uint256 penalties
        )
    {
        Reputation storage rep = reputations[_account];
        return (rep.score, rep.successfulTasks, rep.disputesRaised, rep.disputesResolved, rep.penalties);
    }

    /// @notice Allows the DAO to deduct reputation points from an account due to severe misconduct or protocol violations.
    /// This is a critical governance function to maintain protocol integrity.
    /// @param _account The address whose reputation will be slashed.
    /// @param _amount The amount of reputation points to deduct.
    /// @param _reason A string or URI explaining the reason for the slashing.
    function slashReputation(address _account, uint256 _amount, string calldata _reason) public onlyRoleOrOwner(DAO_ROLE) {
        Reputation storage rep = reputations[_account];
        require(_amount > 0, "Slash amount must be positive");

        if (rep.score >= _amount) {
            rep.score -= _amount;
        } else {
            rep.score = 0; // Reputation cannot go negative
        }
        rep.penalties += _amount; // Keep track of total penalties
        emit ReputationSlashed(_account, uint200(_amount), _reason);
        emit ReputationUpdated(_account, rep.score);
    }

    // --- Dynamic NFT System (AIP-NFTs) ---

    /// @notice Mints a new AIP-NFT (AI Powered NFT) representing the output of a completed AI task.
    /// This function can only be called for tasks that have reached `Completed` status.
    /// The NFT's initial metadata URI typically points to the AI task's result.
    /// @param _taskId The ID of the successfully completed AI task.
    /// @param _to The address to which the new AIP-NFT will be minted.
    /// @param _initialMetadataURI The initial metadata URI (e.g., IPFS CID) for the NFT, often linking to the AI result.
    /// @return The unique ID of the newly minted AIP-NFT.
    function mintAIPNFT(uint256 _taskId, address _to, string calldata _initialMetadataURI) public whenNotPaused returns (uint256) {
        AITask storage task = aiTasks[_taskId];
        if (task.id == 0) revert InvalidTaskID();
        require(task.status == TaskStatus.Completed, "Task must be completed to mint NFT");
        require(task.mintedAIPNFTId == 0, "AIP-NFT already minted for this task"); // Prevent duplicate mints
        // Only the requester or DAO can mint the NFT for their task
        require(msg.sender == task.requester || hasRole(DAO_ROLE, msg.sender), "Only requester or DAO can mint NFT");

        // Use ERC721's internal counter for new token IDs
        uint256 newTokenId = ERC721._tokenIds.current();
        ERC721._tokenIds.increment();

        _mint(_to, newTokenId); // Mints the ERC721 token
        _setTokenURI(newTokenId, _initialMetadataURI); // Sets its initial metadata

        task.mintedAIPNFTId = newTokenId; // Link task to minted NFT
        aipNFTTaskMapping[newTokenId] = _taskId; // Link NFT to original task

        emit AIPNFTMinted(newTokenId, _taskId, _to);
        return newTokenId;
    }

    /// @notice Allows authorized entities to update the metadata URI of an existing AIP-NFT.
    /// This enables the "dynamic" aspect, where the NFT's properties can evolve over time based on new data or AI interactions.
    /// Authorized entities include the NFT owner, the original AI model provider associated with the task, or the DAO.
    /// @param _tokenId The ID of the AIP-NFT to update.
    /// @param _newMetadataURI The new metadata URI (e.g., an updated IPFS CID reflecting new attributes).
    function updateAIPNFTMetadata(uint256 _tokenId, string calldata _newMetadataURI) public whenNotPaused {
        require(_exists(_tokenId), "AIP-NFT does not exist");
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty");

        uint256 taskId = aipNFTTaskMapping[_tokenId];
        if (taskId == 0) revert AIPNFTNotMinted(); // Ensure NFT is linked to a task

        AITask storage task = aiTasks[taskId];
        AIModel storage model = aiModels[task.modelId];

        // Authorization check: NFT owner, original AI model provider, or DAO
        require(
            _isApprovedOrOwner(msg.sender, _tokenId) || // OpenZeppelin's check for owner or approved address
            msg.sender == model.provider ||
            hasRole(DAO_ROLE, msg.sender),
            "Unauthorized to update AIP-NFT metadata"
        );

        _setTokenURI(_tokenId, _newMetadataURI); // Updates the ERC721 token's URI
        emit AIPNFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /// @notice Calculates a dynamic "attribute score" for an AIP-NFT.
    /// This score can reflect the quality, rarity, or performance of the AI model that created it,
    /// or other attributes derived from its metadata. This is a conceptual example;
    /// real-world implementation might involve complex on-chain logic or oracle calls.
    /// @param _tokenId The ID of the AIP-NFT for which to calculate the score.
    /// @return The calculated dynamic attribute score.
    function getAIPNFTAttributeScore(uint252 _tokenId) public view returns (uint252) {
        require(_exists(_tokenId), "AIP-NFT does not exist");
        uint256 taskId = aipNFTTaskMapping[_tokenId];
        if (taskId == 0) revert AIPNFTNotMinted();

        AITask storage task = aiTasks[taskId];
        AIModel storage model = aiModels[task.modelId];

        uint256 score = 0;
        // Example scoring logic (can be expanded with more complex factors):
        // 1. Base score derived from the associated AI Model's historical success rate.
        if (model.successfulTasks + model.failedTasks > 0) {
            score += (model.successfulTasks * 100) / (model.successfulTasks + model.failedTasks);
        }
        // 2. Additional points if the AI task was completed successfully (no disputes).
        if (task.status == TaskStatus.Completed) {
            score += 50;
        }
        // 3. Placeholder for metadata-derived rarity or quality (would require parsing metadata off-chain or via oracle).
        score += 10; // Constant added as a conceptual placeholder.

        // Cap the score or introduce more nuanced weighting as needed for specific use cases.
        return uint252(score); // Cast to uint252 for consistency, assuming score fits
    }


    // --- Self-Amending Governance (SAGE-DAO) ---

    /// @notice Allows any staked participant to propose an amendment to a core protocol parameter.
    /// A proposal enters an active voting period, during which staked participants can vote.
    /// @param _parameterKey A `bytes32` identifier for the parameter to be changed (e.g., `keccak256("protocolFeeBps")`).
    /// @param _newValue The proposed new `uint256` value for the parameter.
    /// @param _descriptionURI URI (e.g., IPFS CID) pointing to a detailed explanation and rationale for the proposal.
    /// @return The unique ID of the newly created governance proposal.
    function proposeParameterAmendment(
        bytes32 _parameterKey,
        uint256 _newValue,
        string calldata _descriptionURI
    ) public whenNotPaused returns (uint256) {
        require(stakes[msg.sender].amount > 0, "Must be staked to propose an amendment");
        require(bytes(_descriptionURI).length > 0, "Description URI cannot be empty");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            parameterKey: _parameterKey,
            newValue: _newValue,
            descriptionURI: _descriptionURI,
            proposer: msg.sender,
            votingDeadline: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool), // Initialize empty mapping for votes
            oracleProof: "" // No oracle proof for standard proposals
        });

        emit ParameterAmendmentProposed(newProposalId, _parameterKey, _newValue, msg.sender);
        return newProposalId;
    }

    /// @notice Allows staked participants to cast their vote on an active governance proposal.
    /// Voting power is proportional to the amount of SAGE_TOKEN staked by the voter.
    /// A participant can only vote once per proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support A boolean indicating support (`true` for 'for', `false` for 'against').
    function voteOnAmendment(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalID();
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive(); // Can only vote on active proposals
        if (block.timestamp > proposal.votingDeadline) { // If voting period is over, update status and revert
            _updateProposalStatus(_proposalId); // Finalize the status of the proposal
            revert ProposalNotActive(); // Re-check status after update, if still not active, revert.
        }
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted(); // Prevent double voting
        require(stakes[msg.sender].amount > 0, "Must have active stake to vote"); // Require active stake

        uint256 votingPower = stakes[msg.sender].amount; // Simple: 1 token = 1 vote
        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true; // Mark voter as having voted
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal if it has passed its voting period and succeeded.
    /// This function applies the proposed parameter changes to the protocol's state.
    /// @param _proposalId The ID of the proposal to execute.
    function executeAmendment(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalID();
        if (block.timestamp <= proposal.votingDeadline) revert ProposalNotActive(); // Voting period must be over
        if (proposal.status == ProposalStatus.Executed) revert ProposalAlreadyExecuted(); // Prevent re-execution

        _updateProposalStatus(_proposalId); // Ensure proposal status is finalized based on votes

        if (proposal.status != ProposalStatus.Succeeded) revert ProposalNotSucceeded(); // Only succeeded proposals can be executed

        // Apply the amendment based on the `parameterKey`
        if (proposal.parameterKey == keccak256("protocolFeeBps")) {
            setProtocolFee(proposal.newValue); // Calls the internal function to update the fee
        } else if (proposal.parameterKey == keccak256("minStakeCurator")) {
            minStakeCurator = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("minStakeValidator")) {
            minStakeValidator = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("stakeLockupDuration")) {
            stakeLockupDuration = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("proposalVotingPeriod")) {
            proposalVotingPeriod = proposal.newValue;
        } else if (proposal.parameterKey == keccak256("treasuryAddress")) {
            require(proposal.newValue != 0, "New treasury address cannot be zero");
            treasuryAddress = address(uint160(proposal.newValue)); // Cast to address, assuming 0 value is invalid
        }
        // Expand this section with `else if` statements for any other parameters that can be amended

        proposal.status = ProposalStatus.Executed; // Mark proposal as executed
        emit AmendmentExecuted(_proposalId);
    }

    /// @notice Allows the DAO (or a trusted oracle controller) to propose an amendment suggested by an off-chain AI.
    /// This function includes a `_oracleProof` parameter, conceptually representing cryptographic evidence
    /// or a verifiable signature from a trusted AI oracle system (e.g., Chainlink External Adapters for AI).
    /// This enables the protocol to "self-amend" based on AI-driven insights.
    /// @param _parameterKey A `bytes32` identifier for the parameter to be changed.
    /// @param _newValue The proposed new `uint256` value for the parameter.
    /// @param _descriptionURI URI pointing to the detailed description, rationale, and AI analysis for the proposal.
    /// @param _oracleProof Placeholder for cryptographic proof verifying the AI's suggestion.
    /// @return The unique ID of the newly created AI-generated governance proposal.
    function proposeAIGeneratedAmendment(
        bytes32 _parameterKey,
        uint256 _newValue,
        string calldata _descriptionURI,
        bytes calldata _oracleProof
    ) public whenNotPaused onlyRoleOrOwner(DAO_ROLE) returns (uint256) {
        // In a real-world scenario, the `_oracleProof` would be rigorously validated
        // against a pre-defined oracle contract or a set of trusted oracles.
        // For this example, `onlyRoleOrOwner(DAO_ROLE)` is sufficient for concept demonstration.
        require(bytes(_oracleProof).length > 0, "Oracle proof cannot be empty");
        require(bytes(_descriptionURI).length > 0, "Description URI cannot be empty");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            parameterKey: _parameterKey,
            newValue: _newValue,
            descriptionURI: _descriptionURI,
            proposer: address(this), // Proposer could be a specific oracle contract address
            votingDeadline: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool),
            oracleProof: _oracleProof // Store the proof for auditing
        });

        emit ParameterAmendmentProposed(newProposalId, _parameterKey, _newValue, address(this));
        return newProposalId;
    }

    /// @notice Internal helper function to update a proposal's status after its voting deadline has passed.
    /// Determines if the proposal `Succeeded` or `Defeated` based on vote counts.
    /// @param _proposalId The ID of the proposal to update.
    function _updateProposalStatus(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        // Only update if currently active and voting period is over
        if (proposal.status != ProposalStatus.Active || block.timestamp <= proposal.votingDeadline) {
            return;
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // A simple majority rule: 'for' votes must be greater than 'against' votes and total votes must be positive.
        // More sophisticated DAOs might implement quorum requirements (minimum total votes) here.
        if (proposal.votesFor > proposal.votesAgainst && totalVotes > 0) {
            proposal.status = ProposalStatus.Succeeded;
        } else {
            proposal.status = ProposalStatus.Defeated;
        }
    }

    // --- Stake & Lockup System ---

    /// @notice Allows users to stake SAGE_TOKEN to participate in specific roles within the protocol (e.g., Curator, Validator).
    /// Staked tokens are locked for a predefined `stakeLockupDuration`, providing commitment and security.
    /// Each role requires a minimum stake amount.
    /// @param _amount The amount of SAGE_TOKEN to stake.
    /// @param _role A `bytes32` representation of the role to stake for (e.g., `keccak256("Curator")` or `keccak256("Validator")`).
    function stakeForRole(uint256 _amount, bytes32 _role) public whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot stake zero amount");
        // Validate the role string
        require(_role == keccak256("Curator") || _role == keccak256("Validator"), "Invalid role for staking");

        // Check minimum stake requirements for the chosen role
        if (_role == keccak256("Curator")) {
            require(_amount >= minStakeCurator, "Insufficient stake for Curator role");
        } else if (_role == keccak256("Validator")) {
            require(_amount >= minStakeValidator, "Insufficient stake for Validator role");
        }

        // Current implementation only allows staking once. For adding to stake, a more complex logic would be needed.
        require(stakes[msg.sender].amount == 0, "Already staked for a role. Unstake first to change/add.");

        // Transfer SAGE_TOKEN from sender to the contract
        require(SAGE_TOKEN.balanceOf(msg.sender) >= _amount, "Insufficient SAGE token balance");
        require(SAGE_TOKEN.allowance(msg.sender, address(this)) >= _amount, "Insufficient SAGE token allowance");
        SAGE_TOKEN.transferFrom(msg.sender, address(this), _amount);

        // Store stake information
        StakeInfo storage newStake = stakes[msg.sender];
        newStake.amount = _amount;
        newStake.lockupEnd = block.timestamp + stakeLockupDuration;
        // Assign the correct enum value based on the bytes32 input
        if (_role == keccak256("Curator")) {
            newStake.role = StakeRole.Curator;
        } else { // Must be "Validator"
            newStake.role = StakeRole.Validator;
        }

        emit Staked(msg.sender, _amount, _role);
    }

    /// @notice Allows a user to unstake their SAGE_TOKEN after the `stakeLockupDuration` has passed.
    /// Users can unstake partially or fully. If fully unstaked, their role is reset.
    /// @param _amount The amount of SAGE_TOKEN to unstake.
    function unstake(uint256 _amount) public whenNotPaused nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        require(stake.amount > 0, "No active stake found for this account");
        require(_amount > 0, "Cannot unstake zero amount");
        require(_amount <= stake.amount, "Unstake amount exceeds staked amount");
        require(block.timestamp >= stake.lockupEnd, "Stake is still locked up. Cannot unstake yet.");

        stake.amount -= _amount; // Deduct amount from staked balance
        SAGE_TOKEN.transfer(msg.sender, _amount); // Transfer tokens back to user

        if (stake.amount == 0) {
            // If all tokens are unstaked, clear the stake information and role
            delete stakes[msg.sender];
        } else {
            // If partial unstake, the existing lockup continues for the remaining amount.
            // A more complex system might reset the lockup for remaining stake, or have multiple lockups.
        }

        emit Unstaked(msg.sender, _amount);
    }

    // --- External / View Functions (for convenience and data retrieval) ---

    /// @notice Returns the address of the SAGE ERC-20 token used by the protocol.
    function getSageTokenAddress() public view returns (address) {
        return address(SAGE_TOKEN);
    }

    /// @notice Returns the total number of AI models registered in the protocol.
    function getTotalAIModels() public view returns (uint256) {
        return _modelIds.current();
    }

    /// @notice Returns the total number of AI tasks created within the protocol.
    function getTotalAITasks() public view returns (uint256) {
        return _taskIds.current();
    }

    /// @notice Returns the total number of governance proposals submitted to the DAO.
    function getTotalProposals() public view returns (uint256) {
        return _proposalIds.current();
    }

    /// @notice Retrieves the current staking information for a specific account.
    /// @param _account The address to query.
    /// @return A tuple containing the staked amount, lockup end timestamp, and the role staked for.
    function getStakeInfo(address _account) public view returns (uint256 amount, uint256 lockupEnd, StakeRole role) {
        StakeInfo storage stake = stakes[_account];
        return (stake.amount, stake.lockupEnd, stake.role);
    }
}
```