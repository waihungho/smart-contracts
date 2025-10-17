Here's a smart contract written in Solidity that embodies an advanced, creative, and trendy concept: a "Decentralized AI Model Marketplace & Federated Learning Orchestrator with Reputation and Dynamic Incentive Mechanisms." This contract orchestrates the collaboration between data providers, AI model developers, and compute providers to train AI models in a privacy-preserving manner, managing reputation, payments, and governance on-chain.

It avoids duplicating common open-source projects by focusing on the unique interplay of these components for AI specific coordination.

---

## AetherMind_AI_Nexus: Decentralized AI Model & Federated Learning Orchestrator

This `AetherMind_AI_Nexus` contract orchestrates a decentralized, community-driven ecosystem for AI model development, data provision, and federated learning. It aims to empower data owners, reward computation providers, and facilitate transparent, verifiable AI model training. The contract serves as a coordination layer, managing identity, reputation, task orchestration, and token flow for off-chain AI computations and data access.

### Outline and Function Summary:

**I. Core Registry & Identity (Participants)**
1.  `registerParticipant(string _name, ParticipantType _type)`: Registers a new user with a specific role (Data Provider, Model Developer, Compute Provider). Requires a minimum stake for the chosen role.
2.  `updateParticipantProfile(string _newName, string _newDescription)`: Allows registered participants to update their public profile details.
3.  `deregisterParticipant()`: Enables a participant to voluntarily leave the system, unstaking their tokens after a cooldown or penalty.
4.  `stakeForRole(ParticipantType _type, uint256 _amount)`: Allows participants to stake `AM_Token` to gain eligibility for roles, enhance reputation, or increase voting power.
5.  `unstakeFromRole(ParticipantType _type)`: Permits participants to withdraw their staked tokens after meeting certain conditions (e.g., no active tasks, cooldown period).

**II. AI Model & Data Descriptor Management**
6.  `submitDataDescriptor(string _name, string _description, string _dataFormatURI, bytes32 _hashedSchema)`: Data providers register metadata about their datasets, including a URI for format and a hash of the schema, without revealing the raw data.
7.  `updateDataDescriptor(uint256 _descriptorId, string _newName, string _newDescription)`: Updates metadata for an existing data descriptor.
8.  `submitAIModelMetadata(string _name, string _description, string _modelArchitectureURI, bytes32 _expectedOutputSchemaHash)`: Model developers register the "blueprint" of their AI models, including architecture details and expected output schema.
9.  `updateAIModelMetadata(uint256 _modelId, string _newName, string _newDescription)`: Updates metadata for an existing AI model blueprint.
10. `setAIModelPrice(uint256 _modelId, uint256 _pricePerAccess, uint256 _pricePerDataQuery)`: Model developers set prices for accessing their trained models or for direct data queries routed through their model.

**III. Federated Learning Orchestration**
11. `requestFederatedLearningTask(uint256[] _dataDescriptorIds, uint256 _aiModelId, uint256 _epochs, uint256 _learningRate, uint256 _maxComputeProviders, uint256 _rewardPerEpoch, uint256 _challengePeriod)`: Model consumers initiate a federated learning task, defining parameters and escrowing `AM_Token` rewards.
12. `proposeComputeSolution(uint256 _taskId, bytes32 _computedGradientHash, bytes _zkProof)`: Compute providers submit a hash of their computed gradients (e.g., from a partial training round) and an optional Zero-Knowledge Proof (ZKP) for verifiable computation.
13. `challengeComputeSolution(uint256 _taskId, address _computeProvider, string _reason)`: Allows any qualified participant to challenge a submitted compute solution, staking funds against its validity during a challenge period.
14. `resolveChallenge(uint256 _taskId, address _challenger, bool _challengerWon)`: Resolves an active challenge, distributing stakes and adjusting reputations based on the outcome (often requiring off-chain verification input).
15. `aggregateGradientsAndUpdateModel(uint256 _taskId, bytes32[] _gradientHashes, address[] _computeProviders)`: (Restricted call) Aggregates validated gradient hashes to conceptually update the global model's state and version, marking the task for completion.

**IV. Reputation & Dynamic Incentives**
16. `updateReputationManually(address _targetParticipant, int256 _delta, string _reason)`: (Admin/Governance-only) Allows for direct reputation adjustments in specific scenarios (e.g., severe protocol violations discovered off-chain).
17. `claimRewards(uint256 _taskId)`: Allows participants (data providers, compute providers) to claim their earned `AM_Token` rewards from completed federated learning tasks.
18. `updateDynamicRewardParameters(RewardType _type, uint256 _newMultiplier)`: Allows governance to adjust reward multipliers for different participant types, incentivizing roles based on network needs or scarcity.

**V. Marketplace & Payments**
19. `purchaseTrainedModelAccess(uint256 _modelId, uint256 _accessDurationInSeconds)`: Consumers pay `AM_Token` to gain timed access to a fully trained AI model (or its inference API details), with funds distributed to model developers and potentially data providers.
20. `releaseFundsToParticipant(uint256 _taskId, address _recipient)`: (Restricted call, typically part of task completion) Releases escrowed funds to the designated recipient for their contribution to a task.

**VI. Governance & Upgradability**
21. `proposeProtocolParameterChange(bytes32 _paramName, uint256 _newValue)`: Enables participants to propose changes to core protocol parameters (e.g., minimum stakes, voting period).
22. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows staked participants to vote on active proposals, with their voting weight tied to their stake.
23. `executeProposal(uint256 _proposalId)`: Executes a proposal that has met its quorum and voting threshold after its voting period.
24. `setAdminAddress(address _newAdmin)`: (Owner-only, emergency or initial setup) Transfers administrative control, which would ideally move to a DAO.

**VII. Utility & Query**
25. `getParticipantInfo(address _participant)`: Retrieves detailed information about a registered participant.
26. `getTaskDetails(uint256 _taskId)`: Returns comprehensive details about a specific federated learning task.
27. `getAIModelDetails(uint256 _modelId)`: Provides metadata for a registered AI model blueprint.
28. `getDataDescriptorDetails(uint256 _descriptorId)`: Retrieves metadata for a registered data descriptor.
29. `getReputationScore(address _participant)`: Returns the current reputation score of a participant.
30. `getProposalDetails(uint256 _proposalId)`: Returns the details of a specific governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial admin, can be replaced by DAO later
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit arithmetic safety

// Custom Errors (for gas efficiency and clarity)
error NotParticipant();
error ParticipantAlreadyRegistered();
error InvalidParticipantType();
error ParticipantNotFound();
error DataDescriptorNotFound();
error AIModelNotFound();
error TaskNotFound();
error NotAuthorized();
error InvalidTaskStatus();
error NotEnoughStake();
error NotEnoughFunds();
error ChallengePeriodNotOver();
error ChallengePeriodActive();
error NoActiveChallenge();
error InvalidProposalState();
error ProposalNotFound();
error VotingPeriodNotOver();
error NotEnoughVotes();
error RewardNotClaimable();
error NoRewardsAvailable();
error NothingToUnstake();
error InvalidAmount();
error InsufficientBalance();
error TransferFailed();
error InvalidAccessDuration();
error TaskNotReadyForAggregation();
error ProposalNotExecutable();

contract AetherMind_AI_Nexus is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // IERC20 token for payments and staking
    IERC20 public immutable AM_Token; // AetherMind Token

    // --- Enums ---
    enum ParticipantType { None, DataProvider, ModelDeveloper, ComputeProvider }
    enum TaskStatus { Created, DataSelected, ComputeProposed, Computing, Challenged, Aggregated, Completed, Failed }
    enum RewardType { DataProvider, ComputeProvider, ModelDeveloper, Validator }
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    // --- Structs ---
    struct Participant {
        string name;
        string description;
        ParticipantType participantType;
        int256 reputationScore; // Can be positive/negative
        uint256 stakeAmount; // Amount of AM_Token staked
        uint256 joinedTimestamp;
        uint256 lastActivityTimestamp;
        uint256 cooldownEnds; // Timestamp for unstaking cooldown
    }

    struct DataDescriptor {
        address owner;
        string name;
        string description;
        string dataFormatURI; // URI to detailed data format/schema (e.g., IPFS CID)
        bytes32 hashedSchema; // Hash of the actual data schema for verification
        uint256 submissionTimestamp;
        bool isActive;
        uint256 pricePerQuery; // Optional: price for direct data queries/access
    }

    struct AIModelMetadata {
        address owner;
        string name;
        string description;
        string modelArchitectureURI; // URI to model architecture description (e.g., config file on IPFS)
        bytes32 expectedOutputSchemaHash; // Hash of expected output schema
        uint256 currentVersion; // Tracks model updates
        uint256 submissionTimestamp;
        uint256 pricePerAccess; // Price for consumers to access the trained model
        uint256 currentReputation; // Reputation of the model itself (derived from task success)
    }

    struct FederatedLearningTask {
        address consumer;
        uint256 aiModelId; // ID of the base model metadata
        uint256[] dataDescriptorIds; // IDs of data descriptors to use
        uint256 epochs;
        uint256 learningRate; // Multiplied by 1e18 for precision, e.g., 0.01 -> 1e16
        uint256 maxComputeProviders;
        uint256 rewardPerEpochPerComputeProvider;
        uint256 totalRewardEscrowed;
        uint256 challengePeriodEnd; // Timestamp
        TaskStatus status;
        mapping(address => bytes32) proposedSolutions; // ComputeProvider => computedGradientHash
        address[] computeProvidersParticipating; // Addresses that proposed solutions
        uint256 acceptedSolutionsCount; // Count of valid (or unchallenged) solutions
        address activeChallenger; // Address of the current challenger, if any
        uint256 challengeStake; // Stake for the current challenge
        uint256 creationTimestamp;
        uint256 completionTimestamp;
        uint256 modelVersionAfterTraining; // The version of the model after this task completes
    }

    struct Proposal {
        uint256 id;
        bytes32 paramName; // Hashed string of the parameter name
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalStakedWeight; // Sum of AM_Token staked by participants
        mapping(address => bool) hasVoted;
        ProposalState state;
        uint256 deadline;
        address proposer;
    }

    // --- State Variables ---
    uint256 public nextDataDescriptorId = 1;
    uint256 public nextAIModelId = 1;
    uint256 public nextTaskId = 1;
    uint256 public nextProposalId = 1;

    // Mappings
    mapping(address => Participant) public participants;
    mapping(uint256 => DataDescriptor) public dataDescriptors;
    mapping(uint256 => AIModelMetadata) public aiModels;
    mapping(uint256 => FederatedLearningTask) public tasks;
    mapping(uint256 => Proposal) public proposals;

    // Participant => TaskId => accumulated_rewards
    mapping(address => mapping(uint256 => uint256)) public participantTaskRewards;
    
    // Total accumulated rewards per participant, claimable across all tasks
    mapping(address => uint256) public totalClaimableRewards;

    // Reward multipliers for different participant types
    mapping(RewardType => uint256) public rewardMultipliers;
    // Minimum staking requirements for different participant types
    mapping(ParticipantType => uint256) public minimumStakes;

    // Governance parameters
    uint256 public proposalQuorumPercentage = 500; // 5% (500 basis points) of total staked AM_Token required to pass
    uint256 public votingPeriodDuration = 3 days;
    uint256 public defaultChallengePeriod = 1 days;
    uint256 public unstakeCooldownDuration = 7 days;

    uint256 public totalProtocolStake; // Total AM_Token staked across all participants

    // --- Events ---
    event ParticipantRegistered(address indexed participantAddress, ParticipantType participantType, string name);
    event ParticipantProfileUpdated(address indexed participantAddress, string newName, string newDescription);
    event DataDescriptorSubmitted(uint256 indexed descriptorId, address indexed owner, string name, string dataFormatURI);
    event AIModelMetadataSubmitted(uint256 indexed modelId, address indexed owner, string name, string modelArchitectureURI);
    event FederatedLearningTaskRequested(uint256 indexed taskId, address indexed consumer, uint256 aiModelId, uint256 totalRewardEscrowed);
    event ComputeSolutionProposed(uint256 indexed taskId, address indexed computeProvider, bytes32 computedGradientHash);
    event ChallengeInitiated(uint256 indexed taskId, address indexed challenger, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed taskId, address indexed challenger, bool challengerWon);
    event GradientsAggregated(uint256 indexed taskId, uint256 aiModelId, uint256 newModelVersion);
    event ReputationUpdated(address indexed participantAddress, int256 delta, string reason);
    event RewardsClaimed(address indexed participantAddress, uint256 amount);
    event StakeChanged(address indexed participantAddress, ParticipantType participantType, uint256 newStakeAmount);
    event UnstakeInitiated(address indexed participantAddress, uint256 amount, uint256 cooldownEnds);
    event UnstakeCompleted(address indexed participantAddress, uint256 amount);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 newPricePerAccess, uint256 newPricePerDataQuery);
    event ProtocolParameterChanged(bytes32 indexed paramName, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, bytes32 paramName, uint256 newValue, uint256 deadline, address proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsReleased(uint256 indexed taskId, address indexed recipient, uint256 amount);
    event AccessPurchased(uint256 indexed modelId, address indexed buyer, uint256 duration, uint256 amountPaid);

    // --- Constructor ---
    constructor(address _amTokenAddress) Ownable(msg.sender) {
        if (_amTokenAddress == address(0)) revert InvalidAmount();
        AM_Token = IERC20(_amTokenAddress);

        // Set initial minimum stakes (example values, can be changed via governance)
        minimumStakes[ParticipantType.DataProvider] = 100 * 10**18; // 100 tokens
        minimumStakes[ParticipantType.ModelDeveloper] = 200 * 10**18; // 200 tokens
        minimumStakes[ParticipantType.ComputeProvider] = 50 * 10**18; // 50 tokens

        // Set initial reward multipliers (100 = 1x, 150 = 1.5x)
        rewardMultipliers[RewardType.DataProvider] = 100;
        rewardMultipliers[RewardType.ComputeProvider] = 100;
        rewardMultipliers[RewardType.ModelDeveloper] = 100;
        rewardMultipliers[RewardType.Validator] = 150; // Validators get a bonus
    }

    // --- Modifiers ---
    modifier onlyParticipant(ParticipantType _requiredType) {
        if (participants[msg.sender].participantType == ParticipantType.None) revert NotParticipant();
        if (_requiredType != ParticipantType.None && participants[msg.sender].participantType != _requiredType) revert NotAuthorized();
        _;
    }

    modifier onlyStaked(ParticipantType _requiredType) {
        if (participants[msg.sender].participantType == ParticipantType.None || participants[msg.sender].stakeAmount < minimumStakes[_requiredType]) {
            revert NotEnoughStake();
        }
        _;
    }

    // --- Internal Helpers ---
    function _updateReputation(address _participant, int256 _delta, string memory _reason) internal {
        participants[_participant].reputationScore += _delta;
        emit ReputationUpdated(_participant, _delta, _reason);
    }

    function _transferTokens(address _from, address _to, uint256 _amount) internal {
        if (_from == address(this)) {
            if (!AM_Token.transfer(_to, _amount)) revert TransferFailed();
        } else {
            if (!AM_Token.transferFrom(_from, _to, _amount)) revert TransferFailed();
        }
    }

    // --- I. Core Registry & Identity (Participants) ---

    /// @notice Registers a new participant with a specified role. Requires staking a minimum amount.
    /// @param _name The participant's chosen name.
    /// @param _type The type of participant (DataProvider, ModelDeveloper, ComputeProvider).
    function registerParticipant(string calldata _name, ParticipantType _type) external {
        if (participants[msg.sender].participantType != ParticipantType.None) revert ParticipantAlreadyRegistered();
        if (_type == ParticipantType.None) revert InvalidParticipantType();
        if (AM_Token.balanceOf(msg.sender) < minimumStakes[_type]) revert InsufficientBalance(); // Check balance before approval/transfer

        // Approve and transfer the stake
        _transferTokens(msg.sender, address(this), minimumStakes[_type]);

        participants[msg.sender] = Participant({
            name: _name,
            description: "",
            participantType: _type,
            reputationScore: 0,
            stakeAmount: minimumStakes[_type],
            joinedTimestamp: block.timestamp,
            lastActivityTimestamp: block.timestamp,
            cooldownEnds: 0
        });
        totalProtocolStake = totalProtocolStake.add(minimumStakes[_type]);
        emit ParticipantRegistered(msg.sender, _type, _name);
        emit StakeChanged(msg.sender, _type, minimumStakes[_type]);
    }

    /// @notice Updates the profile details for a registered participant.
    /// @param _newName The new name.
    /// @param _newDescription The new description.
    function updateParticipantProfile(string calldata _newName, string calldata _newDescription) external onlyParticipant(ParticipantType.None) {
        participants[msg.sender].name = _newName;
        participants[msg.sender].description = _newDescription;
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ParticipantProfileUpdated(msg.sender, _newName, _newDescription);
    }

    /// @notice Initiates the process to deregister a participant and unstake tokens.
    /// @dev Tokens are placed in a cooldown period before they can be fully withdrawn.
    function deregisterParticipant() external onlyParticipant(ParticipantType.None) {
        Participant storage p = participants[msg.sender];
        if (p.stakeAmount == 0) revert NothingToUnstake(); // No stake to unstake

        p.cooldownEnds = block.timestamp.add(unstakeCooldownDuration);
        // Clear participant type immediately, but funds are locked.
        p.participantType = ParticipantType.None;
        emit UnstakeInitiated(msg.sender, p.stakeAmount, p.cooldownEnds);
    }

    /// @notice Completes the unstaking process after the cooldown period.
    function completeUnstake() external {
        Participant storage p = participants[msg.sender];
        if (p.cooldownEnds == 0) revert NothingToUnstake();
        if (block.timestamp < p.cooldownEnds) revert ChallengePeriodActive(); // Re-using error for cooldown, implies "not over"
        if (p.stakeAmount == 0) revert NothingToUnstake();

        uint256 amountToUnstake = p.stakeAmount;
        p.stakeAmount = 0;
        p.cooldownEnds = 0;
        totalProtocolStake = totalProtocolStake.sub(amountToUnstake);
        _transferTokens(address(this), msg.sender, amountToUnstake);
        emit UnstakeCompleted(msg.sender, amountToUnstake);
    }

    /// @notice Allows participants to stake additional AM_Token for a specific role.
    /// @param _type The participant type associated with the stake (can be None for general staking).
    /// @param _amount The amount of tokens to stake.
    function stakeForRole(ParticipantType _type, uint256 _amount) external {
        if (_amount == 0) revert InvalidAmount();
        if (participants[msg.sender].participantType == ParticipantType.None && _type != ParticipantType.None) {
             revert NotParticipant(); // Must register first if staking for a specific role
        }

        _transferTokens(msg.sender, address(this), _amount);
        participants[msg.sender].stakeAmount = participants[msg.sender].stakeAmount.add(_amount);
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        totalProtocolStake = totalProtocolStake.add(_amount);
        emit StakeChanged(msg.sender, _type, participants[msg.sender].stakeAmount);
    }

    /// @notice Permits participants to withdraw their staked tokens after meeting certain conditions.
    /// @param _type The participant type associated with the stake being withdrawn.
    /// @dev This function currently assumes the full staked amount is desired for unstake;
    ///      more granular unstaking would require additional logic.
    function unstakeFromRole(ParticipantType _type) external onlyParticipant(_type) {
        Participant storage p = participants[msg.sender];
        if (p.stakeAmount == 0 || p.stakeAmount < minimumStakes[_type]) revert NothingToUnstake(); // Can only unstake if above min_stake
        if (block.timestamp < p.cooldownEnds) revert ChallengePeriodActive(); // Cooldown

        // A participant cannot unstake if they are involved in an active task/challenge.
        // This check would require iterating through all active tasks, which is gas-intensive.
        // A more practical approach would be to enforce this off-chain or by a participant
        // calling a `canUnstake()` view function that checks task participation status.
        // For simplicity here, we assume the participant manages their task involvement.

        uint256 amountToUnstake = p.stakeAmount.sub(minimumStakes[_type]); // Allow unstaking excess stake
        if (amountToUnstake == 0) revert NothingToUnstake();

        p.stakeAmount = p.stakeAmount.sub(amountToUnstake);
        totalProtocolStake = totalProtocolStake.sub(amountToUnstake);
        _transferTokens(address(this), msg.sender, amountToUnstake);
        emit StakeChanged(msg.sender, _type, p.stakeAmount);
        emit UnstakeCompleted(msg.sender, amountToUnstake);
    }

    // --- II. AI Model & Data Descriptor Management ---

    /// @notice Data providers register metadata about their datasets.
    /// @param _name The name of the dataset.
    /// @param _description A brief description of the dataset.
    /// @param _dataFormatURI URI pointing to detailed data format/schema (e.g., IPFS CID).
    /// @param _hashedSchema Hash of the actual data schema for off-chain verification.
    function submitDataDescriptor(string calldata _name, string calldata _description, string calldata _dataFormatURI, bytes32 _hashedSchema)
        external
        onlyStaked(ParticipantType.DataProvider)
    {
        uint256 id = nextDataDescriptorId++;
        dataDescriptors[id] = DataDescriptor({
            owner: msg.sender,
            name: _name,
            description: _description,
            dataFormatURI: _dataFormatURI,
            hashedSchema: _hashedSchema,
            submissionTimestamp: block.timestamp,
            isActive: true,
            pricePerQuery: 0 // Default, can be set later
        });
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit DataDescriptorSubmitted(id, msg.sender, _name, _dataFormatURI);
    }

    /// @notice Updates metadata for an existing data descriptor.
    /// @param _descriptorId The ID of the data descriptor to update.
    /// @param _newName The new name for the descriptor.
    /// @param _newDescription The new description for the descriptor.
    function updateDataDescriptor(uint256 _descriptorId, string calldata _newName, string calldata _newDescription)
        external
        onlyStaked(ParticipantType.DataProvider)
    {
        DataDescriptor storage descriptor = dataDescriptors[_descriptorId];
        if (descriptor.owner != msg.sender) revert NotAuthorized();
        if (descriptor.owner == address(0)) revert DataDescriptorNotFound();

        descriptor.name = _newName;
        descriptor.description = _newDescription;
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        // Optionally allow updating URI/schema, but might require more complex versioning/validation
        // descriptor.dataFormatURI = _newURI;
        // descriptor.hashedSchema = _newSchemaHash;
    }

    /// @notice Model developers register the "blueprint" of their AI models.
    /// @param _name The name of the AI model.
    /// @param _description A description of the model.
    /// @param _modelArchitectureURI URI pointing to model architecture description.
    /// @param _expectedOutputSchemaHash Hash of the expected output schema.
    function submitAIModelMetadata(string calldata _name, string calldata _description, string calldata _modelArchitectureURI, bytes32 _expectedOutputSchemaHash)
        external
        onlyStaked(ParticipantType.ModelDeveloper)
    {
        uint256 id = nextAIModelId++;
        aiModels[id] = AIModelMetadata({
            owner: msg.sender,
            name: _name,
            description: _description,
            modelArchitectureURI: _modelArchitectureURI,
            expectedOutputSchemaHash: _expectedOutputSchemaHash,
            currentVersion: 1,
            submissionTimestamp: block.timestamp,
            pricePerAccess: 0,
            pricePerDataQuery: 0,
            currentReputation: 0
        });
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit AIModelMetadataSubmitted(id, msg.sender, _name, _modelArchitectureURI);
    }

    /// @notice Updates metadata for an existing AI model blueprint.
    /// @param _modelId The ID of the AI model to update.
    /// @param _newName The new name for the model.
    /// @param _newDescription The new description for the model.
    function updateAIModelMetadata(uint256 _modelId, string calldata _newName, string calldata _newDescription)
        external
        onlyStaked(ParticipantType.ModelDeveloper)
    {
        AIModelMetadata storage model = aiModels[_modelId];
        if (model.owner != msg.sender) revert NotAuthorized();
        if (model.owner == address(0)) revert AIModelNotFound();

        model.name = _newName;
        model.description = _newDescription;
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        // Optionally, update URI and schema hash, potentially incrementing version
        // model.modelArchitectureURI = _newURI;
        // model.expectedOutputSchemaHash = _newSchemaHash;
        // model.currentVersion++;
    }

    /// @notice Model developers set prices for their models or data queries through their model.
    /// @param _modelId The ID of the AI model.
    /// @param _pricePerAccess Price for consumers to access the trained model.
    /// @param _pricePerDataQuery Price for direct data queries routed through this model.
    function setAIModelPrice(uint256 _modelId, uint256 _pricePerAccess, uint256 _pricePerDataQuery)
        external
        onlyStaked(ParticipantType.ModelDeveloper)
    {
        AIModelMetadata storage model = aiModels[_modelId];
        if (model.owner != msg.sender) revert NotAuthorized();
        if (model.owner == address(0)) revert AIModelNotFound();

        model.pricePerAccess = _pricePerAccess;
        model.pricePerDataQuery = _pricePerDataQuery;
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ModelPriceUpdated(_modelId, _pricePerAccess, _pricePerDataQuery);
    }

    // --- III. Federated Learning Orchestration ---

    /// @notice Model consumers initiate a federated learning task.
    /// @param _dataDescriptorIds IDs of data descriptors to use for training.
    /// @param _aiModelId ID of the base model metadata.
    /// @param _epochs Number of training epochs.
    /// @param _learningRate Learning rate for training (scaled by 1e18).
    /// @param _maxComputeProviders Maximum number of compute providers for this task.
    /// @param _rewardPerEpoch Reward for each compute provider per epoch.
    /// @param _challengePeriod Duration of the challenge period in seconds.
    function requestFederatedLearningTask(
        uint256[] calldata _dataDescriptorIds,
        uint256 _aiModelId,
        uint256 _epochs,
        uint256 _learningRate,
        uint256 _maxComputeProviders,
        uint256 _rewardPerEpoch,
        uint256 _challengePeriod
    ) external nonReentrant {
        if (aiModels[_aiModelId].owner == address(0)) revert AIModelNotFound();
        if (_dataDescriptorIds.length == 0) revert InvalidAmount();
        for (uint256 i = 0; i < _dataDescriptorIds.length; i++) {
            if (dataDescriptors[_dataDescriptorIds[i]].owner == address(0)) revert DataDescriptorNotFound();
        }
        if (_epochs == 0 || _maxComputeProviders == 0 || _rewardPerEpoch == 0) revert InvalidAmount();

        uint256 totalReward = _rewardPerEpoch.mul(_epochs).mul(_maxComputeProviders);
        if (AM_Token.balanceOf(msg.sender) < totalReward) revert InsufficientBalance();
        _transferTokens(msg.sender, address(this), totalReward);

        uint256 id = nextTaskId++;
        tasks[id] = FederatedLearningTask({
            consumer: msg.sender,
            aiModelId: _aiModelId,
            dataDescriptorIds: _dataDescriptorIds,
            epochs: _epochs,
            learningRate: _learningRate,
            maxComputeProviders: _maxComputeProviders,
            rewardPerEpochPerComputeProvider: _rewardPerEpoch,
            totalRewardEscrowed: totalReward,
            challengePeriodEnd: 0, // Set after compute solution is proposed
            status: TaskStatus.Created,
            computeProvidersParticipating: new address[](0),
            proposedSolutions: new mapping(address => bytes32)(), // Initialize mapping
            acceptedSolutionsCount: 0,
            activeChallenger: address(0),
            challengeStake: 0,
            creationTimestamp: block.timestamp,
            completionTimestamp: 0,
            modelVersionAfterTraining: 0
        });

        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit FederatedLearningTaskRequested(id, msg.sender, _aiModelId, totalReward);
    }

    /// @notice Compute providers submit a hash of their computed gradients.
    /// @param _taskId The ID of the federated learning task.
    /// @param _computedGradientHash Hash of the computed gradients.
    /// @param _zkProof Optional Zero-Knowledge Proof for verifiable computation.
    /// @dev The ZK Proof itself would be verified off-chain, the hash and proof bytes are stored for reference.
    function proposeComputeSolution(uint256 _taskId, bytes32 _computedGradientHash, bytes calldata _zkProof)
        external
        onlyStaked(ParticipantType.ComputeProvider)
    {
        FederatedLearningTask storage task = tasks[_taskId];
        if (task.consumer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Created && task.status != TaskStatus.ComputeProposed) revert InvalidTaskStatus();
        if (task.computeProvidersParticipating.length >= task.maxComputeProviders) revert NotAuthorized(); // Max providers reached

        // Ensure this provider hasn't already submitted for this task
        for (uint256 i = 0; i < task.computeProvidersParticipating.length; i++) {
            if (task.computeProvidersParticipating[i] == msg.sender) {
                revert ParticipantAlreadyRegistered(); // Re-using error, means "already submitted"
            }
        }

        task.computeProvidersParticipating.push(msg.sender);
        task.proposedSolutions[msg.sender] = _computedGradientHash;
        task.status = TaskStatus.ComputeProposed; // Transition status

        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ComputeSolutionProposed(_taskId, msg.sender, _computedGradientHash);
    }

    /// @notice Allows any qualified participant to challenge a submitted compute solution.
    /// @param _taskId The ID of the federated learning task.
    /// @param _computeProvider The address of the compute provider whose solution is being challenged.
    /// @param _reason A description for the challenge.
    /// @dev Requires the challenger to stake funds, which are at risk.
    function challengeComputeSolution(uint256 _taskId, address _computeProvider, string calldata _reason)
        external
        onlyParticipant(ParticipantType.None) // Any participant can challenge
        nonReentrant
    {
        FederatedLearningTask storage task = tasks[_taskId];
        if (task.consumer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.ComputeProposed && task.status != TaskStatus.Computing) revert InvalidTaskStatus();
        if (task.challengePeriodEnd != 0 && block.timestamp >= task.challengePeriodEnd) revert ChallengePeriodNotOver(); // Challenge period for previous proposals is over
        if (task.activeChallenger != address(0)) revert ChallengePeriodActive(); // Already an active challenge

        // Check if _computeProvider actually participated
        bool found = false;
        for(uint i=0; i < task.computeProvidersParticipating.length; i++){
            if(task.computeProvidersParticipating[i] == _computeProvider){
                found = true;
                break;
            }
        }
        if(!found) revert ParticipantNotFound(); // Compute provider not found in this task

        // Challenger stakes a sum (e.g., equal to expected reward of the challenged solution)
        uint256 challengeStakeAmount = task.rewardPerEpochPerComputeProvider.mul(task.epochs);
        if (AM_Token.balanceOf(msg.sender) < challengeStakeAmount) revert InsufficientBalance();
        _transferTokens(msg.sender, address(this), challengeStakeAmount);

        task.activeChallenger = msg.sender;
        task.challengeStake = challengeStakeAmount;
        task.challengePeriodEnd = block.timestamp.add(defaultChallengePeriod); // Start new challenge period
        task.status = TaskStatus.Challenged;

        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        _updateReputation(msg.sender, 5, "Initiated challenge"); // Small positive rep for active participation
        emit ChallengeInitiated(_taskId, msg.sender, challengeStakeAmount);
    }

    /// @notice Resolves an active challenge.
    /// @param _taskId The ID of the federated learning task.
    /// @param _challenger The address of the challenger.
    /// @param _challengerWon Boolean indicating if the challenger won the dispute.
    /// @dev This function would typically be called by an oracle, a trusted third party, or a DAO vote after off-chain verification.
    function resolveChallenge(uint256 _taskId, address _challenger, bool _challengerWon) external onlyOwner nonReentrant {
        FederatedLearningTask storage task = tasks[_taskId];
        if (task.consumer == address(0)) revert TaskNotFound();
        if (task.activeChallenger != _challenger) revert NoActiveChallenge();
        if (block.timestamp < task.challengePeriodEnd) revert ChallengePeriodActive(); // Challenge period must be over

        uint256 totalChallengeStake = task.challengeStake;
        task.challengeStake = 0;
        task.activeChallenger = address(0); // Reset challenger

        if (_challengerWon) {
            // Challenger wins: rewards distributed, compute provider penalized
            _updateReputation(_challenger, 50, "Won compute challenge");
            _updateReputation(msg.sender, -20, "Solution successfully challenged"); // The challenged party
            // Challenger gets their stake back + a portion of the challenged party's stake (if applicable)
            // For simplicity, challenger gets their full stake back for now, and a bonus.
            _transferTokens(address(this), _challenger, totalChallengeStake.add(totalChallengeStake.div(10))); // Challenger gets 10% bonus
            // The compute provider who was challenged might lose their original reward for this task
            // and potentially a portion of their stake.
            // Further logic needed for complex penalties.

        } else {
            // Challenger loses: loses stake, compute provider's reputation increased.
            _updateReputation(_challenger, -50, "Lost compute challenge");
            _updateReputation(msg.sender, 20, "Solution defended against challenge"); // The challenged party
            // Challenger's stake is split: a portion goes to the challenged party, a portion to the protocol.
            _transferTokens(address(this), msg.sender, totalChallengeStake.div(2)); // Challenged party gets half
            // Remaining half of stake (totalChallengeStake.div(2)) stays in contract or sent to DAO treasury.
        }

        task.status = TaskStatus.ComputeProposed; // Revert to proposed state for further aggregation or re-challenge
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ChallengeResolved(_taskId, _challenger, _challengerWon);
    }

    /// @notice Aggregates validated gradient hashes to conceptually update the global model's state and version.
    /// @param _taskId The ID of the federated learning task.
    /// @param _gradientHashes Array of validated gradient hashes.
    /// @param _computeProviders Array of compute providers corresponding to the gradient hashes.
    /// @dev This is a restricted function, typically called by the task consumer or an oracle/aggregator.
    function aggregateGradientsAndUpdateModel(uint256 _taskId, bytes32[] calldata _gradientHashes, address[] calldata _computeProviders)
        external
        onlyOwner // For simplicity, owner acts as aggregator. In reality, this would be an elected aggregator or DAO.
        nonReentrant
    {
        FederatedLearningTask storage task = tasks[_taskId];
        if (task.consumer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.ComputeProposed) revert TaskNotReadyForAggregation();
        if (_gradientHashes.length != _computeProviders.length || _gradientHashes.length == 0) revert InvalidAmount();
        if (block.timestamp < task.challengePeriodEnd && task.challengePeriodEnd != 0) revert ChallengePeriodActive(); // Ensure challenge period is over if one was set.

        // In a real scenario, this function would:
        // 1. Verify ZK-proofs or off-chain consensus for each _gradientHashes
        // 2. Ensure each _computeProvider is valid and submitted a solution
        // 3. Aggregate these into a "global model update" hash
        // Here, we simply accept the provided list as validated.

        AIModelMetadata storage model = aiModels[task.aiModelId];
        model.currentVersion = model.currentVersion.add(1); // Increment model version

        // Distribute rewards to compute providers
        uint256 rewardPerProvider = task.rewardPerEpochPerComputeProvider.mul(task.epochs);
        for (uint256 i = 0; i < _computeProviders.length; i++) {
            totalClaimableRewards[_computeProviders[i]] = totalClaimableRewards[_computeProviders[i]].add(rewardPerProvider.mul(rewardMultipliers[RewardType.ComputeProvider]).div(100));
            _updateReputation(_computeProviders[i], 10, "Successfully contributed to federated learning task");
        }

        // Distribute rewards to Data Providers (e.g., a fixed percentage of task reward, or per-query model)
        uint256 dataProviderRewardShare = task.totalRewardEscrowed.div(10); // Example: 10%
        uint256 rewardPerDataProvider = dataProviderRewardShare.div(task.dataDescriptorIds.length);
        for (uint256 i = 0; i < task.dataDescriptorIds.length; i++) {
            address dp = dataDescriptors[task.dataDescriptorIds[i]].owner;
            totalClaimableRewards[dp] = totalClaimableRewards[dp].add(rewardPerDataProvider.mul(rewardMultipliers[RewardType.DataProvider]).div(100));
            _updateReputation(dp, 5, "Data utilized in federated learning task");
        }

        // The remaining funds go to the model developer, less what was paid to data providers.
        uint256 modelDeveloperReward = task.totalRewardEscrowed.sub(rewardPerProvider.mul(_computeProviders.length)).sub(dataProviderRewardShare);
        totalClaimableRewards[model.owner] = totalClaimableRewards[model.owner].add(modelDeveloperReward.mul(rewardMultipliers[RewardType.ModelDeveloper]).div(100));
        _updateReputation(model.owner, 15, "Model successfully trained via federated learning");

        // Refund any excess escrowed funds to the consumer (if maxComputeProviders was not fully utilized or less data providers)
        uint256 unspentFunds = task.totalRewardEscrowed.sub(totalClaimableRewards[model.owner]).sub(dataProviderRewardShare).sub(rewardPerProvider.mul(_computeProviders.length));
        if (unspentFunds > 0) {
            _transferTokens(address(this), task.consumer, unspentFunds);
            emit FundsReleased(_taskId, task.consumer, unspentFunds);
        }

        task.status = TaskStatus.Aggregated;
        task.completionTimestamp = block.timestamp;
        task.modelVersionAfterTraining = model.currentVersion;
        participants[msg.sender].lastActivityTimestamp = block.timestamp;

        emit GradientsAggregated(_taskId, task.aiModelId, model.currentVersion);
        emit FundsReleased(_taskId, task.consumer, unspentFunds); // In case of excess funds
    }

    // --- IV. Reputation & Dynamic Incentives ---

    /// @notice Allows for direct reputation adjustments in specific scenarios.
    /// @dev This function is `onlyOwner` for simplicity, but in a real DAO, it would be governed.
    /// @param _targetParticipant The address of the participant whose reputation is being adjusted.
    /// @param _delta The change in reputation score (can be positive or negative).
    /// @param _reason The reason for the reputation adjustment.
    function updateReputationManually(address _targetParticipant, int256 _delta, string calldata _reason) external onlyOwner {
        if (participants[_targetParticipant].participantType == ParticipantType.None) revert ParticipantNotFound();
        _updateReputation(_targetParticipant, _delta, _reason);
    }

    /// @notice Allows participants to claim their earned AM_Token rewards.
    /// @param _taskId The ID of the task for which rewards are being claimed.
    function claimRewards(uint256 _taskId) external nonReentrant {
        FederatedLearningTask storage task = tasks[_taskId];
        if (task.consumer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Aggregated && task.status != TaskStatus.Completed) revert RewardNotClaimable();

        uint256 rewards = participantTaskRewards[msg.sender][_taskId];
        if (rewards == 0) {
            rewards = totalClaimableRewards[msg.sender]; // General pool for this participant
        }

        if (rewards == 0) revert NoRewardsAvailable();

        totalClaimableRewards[msg.sender] = totalClaimableRewards[msg.sender].sub(rewards);
        _transferTokens(address(this), msg.sender, rewards);
        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Allows governance to adjust reward multipliers for different participant types.
    /// @dev This is `onlyOwner` for simplicity, but would be part of DAO governance.
    /// @param _type The type of reward to adjust (DataProvider, ComputeProvider, ModelDeveloper, Validator).
    /// @param _newMultiplier The new multiplier (e.g., 100 for 1x, 150 for 1.5x).
    function updateDynamicRewardParameters(RewardType _type, uint256 _newMultiplier) external onlyOwner {
        rewardMultipliers[_type] = _newMultiplier;
        // Emit an event to reflect this change
        emit ProtocolParameterChanged(bytes32(abi.encodePacked("RewardMultiplier_", uint256(_type))), _newMultiplier);
    }

    // --- V. Marketplace & Payments ---

    /// @notice Consumers pay AM_Token to gain timed access to a fully trained AI model.
    /// @param _modelId The ID of the AI model.
    /// @param _accessDurationInSeconds The duration of access requested in seconds.
    function purchaseTrainedModelAccess(uint256 _modelId, uint256 _accessDurationInSeconds) external nonReentrant {
        AIModelMetadata storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert AIModelNotFound();
        if (model.pricePerAccess == 0) revert InvalidAmount(); // Model not for sale or price not set
        if (_accessDurationInSeconds == 0) revert InvalidAccessDuration();

        uint256 totalPrice = model.pricePerAccess.mul(_accessDurationInSeconds).div(1 days); // Example: per day pricing
        if (AM_Token.balanceOf(msg.sender) < totalPrice) revert InsufficientBalance();
        _transferTokens(msg.sender, address(this), totalPrice);

        // Distribute payment: X% to model owner, Y% to data providers (if model was trained via FL), Z% to protocol
        uint256 modelOwnerShare = totalPrice.mul(70).div(100); // Example 70%
        uint256 protocolShare = totalPrice.mul(10).div(100); // Example 10%
        uint256 dataProviderShare = totalPrice.sub(modelOwnerShare).sub(protocolShare); // Remaining 20%

        totalClaimableRewards[model.owner] = totalClaimableRewards[model.owner].add(modelOwnerShare);
        // Distribute dataProviderShare to data providers from the latest successful FL task for this model,
        // or based on a historical contribution record. This is a complex off-chain calculation.
        // For simplicity, let's say the dataProviderShare goes to a general pool or specific data provider
        // for now. Or, it could be factored into `releaseFundsToParticipant` of the task.
        // `totalClaimableRewards[someDataProvider]` += dataProviderShare;

        // Protocol share is effectively held by the contract or transferred to a DAO treasury
        // `_transferTokens(address(this), DAO_TREASURY, protocolShare);`

        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit AccessPurchased(_modelId, msg.sender, _accessDurationInSeconds, totalPrice);
    }

    /// @notice Releases escrowed funds to a designated recipient for their contribution to a task.
    /// @dev This function would typically be called internally by `aggregateGradientsAndUpdateModel`
    ///      or by an authorized oracle upon task completion. Exposed as `onlyOwner` for demonstration.
    /// @param _taskId The ID of the federated learning task.
    /// @param _recipient The address of the recipient.
    function releaseFundsToParticipant(uint256 _taskId, address _recipient) external onlyOwner nonReentrant {
        FederatedLearningTask storage task = tasks[_taskId];
        if (task.consumer == address(0)) revert TaskNotFound();
        if (task.status != TaskStatus.Completed && task.status != TaskStatus.Aggregated) revert InvalidTaskStatus();

        uint256 amount = totalClaimableRewards[_recipient]; // For the purpose of this demo, claiming from general pool
        if (amount == 0) revert NoRewardsAvailable();

        totalClaimableRewards[_recipient] = 0;
        _transferTokens(address(this), _recipient, amount);
        emit FundsReleased(_taskId, _recipient, amount);
    }

    // --- VI. Governance & Upgradability ---

    /// @notice Enables participants to propose changes to core protocol parameters.
    /// @param _paramName The hashed string of the parameter name (e.g., `keccak256("minimumStakes_DataProvider")`).
    /// @param _newValue The new value for the parameter.
    function proposeProtocolParameterChange(bytes32 _paramName, uint256 _newValue) external onlyParticipant(ParticipantType.None) {
        if (participants[msg.sender].stakeAmount == 0) revert NotEnoughStake(); // Only staked participants can propose

        uint256 id = nextProposalId++;
        proposals[id].id = id;
        proposals[id].paramName = _paramName;
        proposals[id].newValue = _newValue;
        proposals[id].state = ProposalState.Active;
        proposals[id].deadline = block.timestamp.add(votingPeriodDuration);
        proposals[id].proposer = msg.sender;

        emit ProposalCreated(id, _paramName, _newValue, proposals[id].deadline, msg.sender);
    }

    /// @notice Allows staked participants to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for "yes" vote, false for "no" vote.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyParticipant(ParticipantType.None) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp >= proposal.deadline) revert VotingPeriodNotOver();
        if (proposal.hasVoted[msg.sender]) revert ParticipantAlreadyRegistered(); // Re-using error, means "already voted"
        if (participants[msg.sender].stakeAmount == 0) revert NotEnoughStake();

        proposal.hasVoted[msg.sender] = true;
        uint256 votingWeight = participants[msg.sender].stakeAmount; // Stake as voting weight
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingWeight);
        }
        proposal.totalStakedWeight = proposal.totalStakedWeight.add(votingWeight);

        participants[msg.sender].lastActivityTimestamp = block.timestamp;
        emit VoteCast(_proposalId, msg.sender, _support, votingWeight);
    }

    /// @notice Executes a proposal that has met its quorum and voting threshold after its voting period.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner nonReentrant { // Can be changed to allow anyone after period
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp < proposal.deadline) revert VotingPeriodNotOver();

        // Check quorum: total votes must exceed a percentage of totalProtocolStake
        uint256 quorumThreshold = totalProtocolStake.mul(proposalQuorumPercentage).div(10000); // 10000 for basis points
        if (proposal.totalStakedWeight < quorumThreshold) {
            proposal.state = ProposalState.Defeated;
            revert NotEnoughVotes();
        }

        // Check majority: votesFor must be greater than votesAgainst
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.state = ProposalState.Defeated;
            revert ProposalNotExecutable();
        }

        // Execute the parameter change
        bytes32 paramName = proposal.paramName;
        uint256 newValue = proposal.newValue;

        // This switch statement maps `bytes32` param names to state variables
        if (paramName == keccak256("proposalQuorumPercentage")) {
            proposalQuorumPercentage = newValue;
        } else if (paramName == keccak256("votingPeriodDuration")) {
            votingPeriodDuration = newValue;
        } else if (paramName == keccak256("defaultChallengePeriod")) {
            defaultChallengePeriod = newValue;
        } else if (paramName == keccak256("unstakeCooldownDuration")) {
            unstakeCooldownDuration = newValue;
        } else if (paramName == keccak256("minimumStakes_DataProvider")) {
            minimumStakes[ParticipantType.DataProvider] = newValue;
        } else if (paramName == keccak256("minimumStakes_ModelDeveloper")) {
            minimumStakes[ParticipantType.ModelDeveloper] = newValue;
        } else if (paramName == keccak256("minimumStakes_ComputeProvider")) {
            minimumStakes[ParticipantType.ComputeProvider] = newValue;
        } else {
             // Handle reward multipliers, can be more granular
             // e.g., if (paramName == keccak256("rewardMultipliers_DataProvider"))
             revert InvalidProposalState(); // Unknown parameter to change
        }

        proposal.state = ProposalState.Succeeded; // Mark as succeeded after parameter change logic
        emit ProposalExecuted(_proposalId);
        emit ProtocolParameterChanged(paramName, newValue);
    }

    /// @notice Transfers administrative control of the contract.
    /// @dev This function is `onlyOwner` and should be used with extreme caution.
    ///      Ideally, ownership is transferred to a DAO or multi-sig.
    /// @param _newAdmin The address of the new administrator.
    function setAdminAddress(address _newAdmin) external onlyOwner {
        if (_newAdmin == address(0)) revert InvalidAmount();
        transferOwnership(_newAdmin); // Uses OpenZeppelin's Ownable transferOwnership
    }

    // --- VII. Utility & Query ---

    /// @notice Retrieves detailed information about a registered participant.
    /// @param _participant The address of the participant.
    /// @return Participant struct details.
    function getParticipantInfo(address _participant)
        external
        view
        returns (string memory name, string memory description, ParticipantType participantType, int256 reputationScore, uint256 stakeAmount, uint256 joinedTimestamp, uint256 lastActivityTimestamp, uint256 cooldownEnds)
    {
        Participant storage p = participants[_participant];
        return (p.name, p.description, p.participantType, p.reputationScore, p.stakeAmount, p.joinedTimestamp, p.lastActivityTimestamp, p.cooldownEnds);
    }

    /// @notice Returns comprehensive details about a specific federated learning task.
    /// @param _taskId The ID of the federated learning task.
    /// @return FederatedLearningTask struct details.
    function getTaskDetails(uint256 _taskId)
        external
        view
        returns (address consumer, uint256 aiModelId, uint256[] memory dataDescriptorIds, uint256 epochs, uint256 learningRate, uint256 maxComputeProviders, uint256 rewardPerEpochPerComputeProvider, uint256 totalRewardEscrowed, uint256 challengePeriodEnd, TaskStatus status, address[] memory computeProvidersParticipating, address activeChallenger, uint256 challengeStake, uint256 creationTimestamp, uint256 completionTimestamp, uint256 modelVersionAfterTraining)
    {
        FederatedLearningTask storage task = tasks[_taskId];
        if (task.consumer == address(0)) revert TaskNotFound();
        return (task.consumer, task.aiModelId, task.dataDescriptorIds, task.epochs, task.learningRate, task.maxComputeProviders, task.rewardPerEpochPerComputeProvider, task.totalRewardEscrowed, task.challengePeriodEnd, task.status, task.computeProvidersParticipating, task.activeChallenger, task.challengeStake, task.creationTimestamp, task.completionTimestamp, task.modelVersionAfterTraining);
    }

    /// @notice Provides metadata for a registered AI model blueprint.
    /// @param _modelId The ID of the AI model.
    /// @return AIModelMetadata struct details.
    function getAIModelDetails(uint256 _modelId)
        external
        view
        returns (address owner, string memory name, string memory description, string memory modelArchitectureURI, bytes32 expectedOutputSchemaHash, uint256 currentVersion, uint256 submissionTimestamp, uint256 pricePerAccess, uint256 pricePerDataQuery, uint256 currentReputation)
    {
        AIModelMetadata storage model = aiModels[_modelId];
        if (model.owner == address(0)) revert AIModelNotFound();
        return (model.owner, model.name, model.description, model.modelArchitectureURI, model.expectedOutputSchemaHash, model.currentVersion, model.submissionTimestamp, model.pricePerAccess, model.pricePerDataQuery, model.currentReputation);
    }

    /// @notice Retrieves metadata for a registered data descriptor.
    /// @param _descriptorId The ID of the data descriptor.
    /// @return DataDescriptor struct details.
    function getDataDescriptorDetails(uint256 _descriptorId)
        external
        view
        returns (address owner, string memory name, string memory description, string memory dataFormatURI, bytes32 hashedSchema, uint256 submissionTimestamp, bool isActive, uint256 pricePerQuery)
    {
        DataDescriptor storage descriptor = dataDescriptors[_descriptorId];
        if (descriptor.owner == address(0)) revert DataDescriptorNotFound();
        return (descriptor.owner, descriptor.name, descriptor.description, descriptor.dataFormatURI, descriptor.hashedSchema, descriptor.submissionTimestamp, descriptor.isActive, descriptor.pricePerQuery);
    }

    /// @notice Returns the current reputation score of a participant.
    /// @param _participant The address of the participant.
    /// @return The reputation score.
    function getReputationScore(address _participant) external view returns (int256) {
        if (participants[_participant].participantType == ParticipantType.None) revert ParticipantNotFound();
        return participants[_participant].reputationScore;
    }

    /// @notice Returns the details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct details.
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (uint256 id, bytes32 paramName, uint256 newValue, uint256 votesFor, uint256 votesAgainst, uint256 totalStakedWeight, ProposalState state, uint256 deadline, address proposer)
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalNotFound();
        return (proposal.id, proposal.paramName, proposal.newValue, proposal.votesFor, proposal.votesAgainst, proposal.totalStakedWeight, proposal.state, proposal.deadline, proposal.proposer);
    }

    /// @notice Returns the total claimable rewards for a specific participant.
    /// @param _participant The address of the participant.
    /// @return The total claimable rewards.
    function getClaimableRewards(address _participant) external view returns (uint256) {
        return totalClaimableRewards[_participant];
    }
}
```