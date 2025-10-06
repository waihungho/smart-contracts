```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol"; // For Soulbound NFT metadata
import "@openzeppelin/contracts/utils/Strings.sol"; // For token URI formatting

/**
 * @title SynergyNetAI
 * @author YourName (or Anonymous)
 * @notice A decentralized platform for collaborative AI model development, verifiable contribution tracking,
 *         dynamic model evolution, and the deployment of "Cognitive Agents" (Soulbound AI instances).
 *         It aims to foster trust, transparency, and reputation within a community building and utilizing AI.
 *
 * @dev This contract relies heavily on off-chain computation and storage (e.g., IPFS/Filecoin) for large
 *      data/model files and intensive AI processing. On-chain state stores hashes, CIDs, and metadata for
 *      verification, coordination, and governance. It uses a placeholder IERC20 token for staking/rewards.
 *      Cognitive Agents are implemented as Soulbound Tokens (SBTs) and are non-transferable.
 *      Gas efficiency for iteration-heavy functions (e.g., reward distribution) might be a concern
 *      with a very large number of contributors, and would require further optimization in a production environment.
 */

// --- OUTLINE ---
// 1. Core Data Structures: Defines structs for intents, proposals, contributions, groups, agents, and challenges.
// 2. State Variables: Mappings and counters for all core entities, roles, and governance parameters.
// 3. Events: To log critical actions and state changes for off-chain monitoring.
// 4. Modifiers: For granular access control based on roles and entity ownership/delegation.
// 5. Constructor: Initializes core roles (admin, governance), sets up the payment token, and defines ERC721 metadata.
// 6. ERC721Metadata Interface Implementation: Custom implementation for Soulbound Tokens, preventing transfers.
// 7. Intent Management Functions: For proposing new AI model development goals and querying their status.
// 8. Contribution & Collaboration Functions: For users to contribute data/model components, join groups, and verify contributions.
// 9. Model Evolution & Governance Functions: For proposing, voting on, and finalizing new versions of AI models.
// 10. Cognitive Agent (SBT) Management Functions: For minting Soulbound AI instances, delegating their interaction capabilities, and managing their logs.
// 11. Agent Challenge & Reputation Functions: For initiating performance challenges against agents, resolving them, and updating agent reputation.
// 12. Agent Service Functions: For requesting and confirming off-chain data processing services from agents.
// 13. Compute Provider & Resource Management Functions: For registering compute providers and managing their staked resources.
// 14. System & Governance Configuration Functions: For distributing rewards, updating governance parameters, and managing external agent gateways.
// 15. Access Control Utility: Functions for granting, revoking, and renouncing roles.

// --- FUNCTION SUMMARY ---
// 1.  proposeModelIntent: Initiates a new AI model development goal with detailed specifications.
// 2.  joinModelIntentGroup: Allows a user to join a collaborative group for a specific model intent.
// 3.  contributeDataSlice: Submits a hash of verifiable training data, along with metadata and designated verifiers, to an intent.
// 4.  verifyDataSlice: Designated verifiers confirm the integrity and validity of a contributed data slice.
// 5.  contributeModelComponent: Adds a verifiable AI model component (e.g., a neural network layer) with its dependencies to an intent.
// 6.  proposeModelEvolution: Proposes an updated version of a model, linking contributing components and explaining changes.
// 7.  voteOnModelEvolution: Group members vote to approve or reject a proposed model evolution.
// 8.  finalizeModelEvolution: Finalizes an approved model evolution, making it the active model for an intent and potentially triggering reward distribution.
// 9.  mintCognitiveAgent: Mints a non-transferable (Soulbound) NFT representing a specific, deployed AI model instance.
// 10. delegateAgentInteractionCapability: Allows a Cognitive Agent's owner to temporarily delegate interaction rights to another address.
// 11. revokeAgentInteractionCapability: Revokes previously delegated interaction capabilities from an address for a Cognitive Agent.
// 12. challengeAgentPerformance: Initiates an on-chain performance challenge for a Cognitive Agent, requiring external verification and staking.
// 13. resolveAgentChallenge: An authorized adjudicator resolves an agent performance challenge, distributing stakes and updating agent/challenger reputation.
// 14. updateAgentInteractionLog: Allows a Cognitive Agent (or its delegatee) to update its on-chain interaction log summary with an IPFS CID.
// 15. requestAgentDataProcessing: Requests off-chain data processing from a Cognitive Agent with an attached payment.
// 16. confirmAgentDataProcessing: The Cognitive Agent confirms completed data processing and provides a hash to the output and a proof, receiving payment.
// 17. registerComputeProvider: Allows an entity to register as a compute provider for training or inference tasks.
// 18. stakeForComputeResources: Allows a registered compute provider to stake tokens, signalling availability and commitment.
// 19. distributeContributionRewards: Distributes rewards from a pool to data and component contributors for a successfully finalized model.
// 20. updateAgentReputation: Allows authorized roles to adjust an agent's reputation score based on complex, potentially off-chain, metrics.
// 21. configureGovernanceParameter: Enables governance to update key system parameters (e.g., voting thresholds, challenge fees).
// 22. deployModelGateway: Associates an external gateway contract with a Cognitive Agent, allowing other contracts to interact with it.
// 23. getTokenURI: Returns the URI for a Cognitive Agent's metadata, adhering to ERC721Metadata standards.
// 24. getIntentStatus: Retrieves the current active model hash and high-level status for a specific intent.

contract SynergyNetAI is AccessControl, IERC721Metadata {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- 1. Core Data Structures ---

    struct ModelIntent {
        string name;
        string descriptionCID; // IPFS CID for detailed description
        string expectedInputsCID;
        string expectedOutputsCID;
        string performanceMetricsCID; // How to measure success
        bytes32 currentActiveModelHash; // Hash of the actively deployed model for this intent
        uint256 createdAt;
        address proposer;
        uint256 intentId; // Internal ID
        uint256 activeGroupCount; // Number of active synergy groups
        mapping(bytes32 => ModelEvolutionProposal) evolutionProposals;
        mapping(bytes32 => SynergyGroup) synergyGroups; // GroupId => SynergyGroup
    }

    struct ModelEvolutionProposal {
        bytes32 modelHash; // Hash of the proposed model
        string evolutionNotesCID; // IPFS CID for notes on changes/improvements
        uint256[] contributingComponentIds; // IDs of components used
        uint256 proposedAt;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Check if an address has voted
        bool isFinalized;
    }

    struct DataSlice {
        bytes32 dataHash; // Hash of the data content
        string metadataCID; // IPFS CID for metadata (e.g., source, labels)
        address contributor;
        uint256 contributedAt;
        uint256 verifiedCount; // Number of verifiers confirming validity
        mapping(address => bool) isVerifiedBy; // Map of verifier addresses to their verification status
        address[] verifiersNeeded; // List of addresses designated to verify
        uint256 associatedIntentId;
    }

    struct ModelComponent {
        bytes32 componentHash; // Hash of the component code/weights
        string metadataCID; // IPFS CID for metadata (e.g., architecture, training details)
        address contributor;
        uint256 contributedAt;
        uint256[] dependencies; // IDs of other components this one depends on
        uint256 componentId; // Internal ID
        uint256 associatedIntentId;
    }

    struct SynergyGroup {
        bytes32 groupId; // Unique identifier for the group (e.g., hash of members or a chosen name)
        uint256 intentId; // The intent this group is working on
        mapping(address => bool) members; // Group members
        uint256 memberCount;
        // Future: add group-specific stake, reputation, etc.
    }

    struct CognitiveAgent {
        uint256 agentId; // Token ID
        uint256 intentId; // The intent it originated from
        bytes32 modelHash; // The specific model hash it represents
        string name;
        string descriptionCID;
        address owner; // The address that minted it (cannot be transferred)
        uint256 mintedAt;
        int256 reputationScore; // Dynamic reputation
        string currentInteractionLogCID; // IPFS CID for latest interaction log summary
        mapping(address => uint256) delegatedInteractionUntil; // Delegatee => timestamp (0 if no delegation or expired)
        address gatewayContract; // Optional: an external contract acting as its interface
        Counters.Counter nextRequestId; // For data processing requests
        mapping(uint256 => AgentProcessingRequest) processingRequests; // For data processing requests
    }

    struct AgentProcessingRequest {
        uint256 requestId;
        address requester;
        string inputDataCID;
        uint256 paymentAmount;
        string outputDataCID; // Set upon confirmation
        bytes32 proofHash; // Set upon confirmation
        bool isCompleted;
        uint256 requestedAt;
        uint256 completedAt;
    }

    struct AgentChallenge {
        uint256 challengeId;
        uint256 agentId;
        address challenger;
        address adjudicator; // Address responsible for resolving
        uint256 challengerStake;
        uint256 agentStake; // Stake put up by the agent's owner
        string challengeInputCID;
        string expectedOutputCID;
        string resolutionProofCID;
        bool isResolved;
        bool isSuccessful; // Was the agent successful in the challenge?
        uint256 challengedAt;
        uint256 resolvedAt;
    }

    struct ComputeProvider {
        string providerProfileCID; // IPFS CID for details about compute capabilities
        uint256 stakedAmount; // Tokens staked by the provider
        bool isRegistered;
        uint256 registeredAt;
    }

    // --- 2. State Variables ---

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant ADJUDICATOR_ROLE = keccak256("ADJUDICATOR_ROLE");

    Counters.Counter private _nextIntentId;
    Counters.Counter private _nextDataSliceId;
    Counters.Counter private _nextModelComponentId;
    Counters.Counter private _nextAgentId;
    Counters.Counter private _nextChallengeId;

    mapping(uint256 => ModelIntent) public modelIntents;
    mapping(uint256 => DataSlice) public dataSlices; // ID to DataSlice struct
    mapping(uint256 => ModelComponent) public modelComponents; // ID to ModelComponent struct
    mapping(uint256 => CognitiveAgent) public cognitiveAgents; // agentId => CognitiveAgent
    mapping(uint256 => AgentChallenge) public agentChallenges; // challengeId => AgentChallenge
    mapping(address => ComputeProvider) public computeProviders; // providerAddress => ComputeProvider

    mapping(address => int256) public contributorReputation; // For users contributing data/components

    // Governance parameters (e.g., for voting thresholds, challenge fees)
    mapping(bytes32 => uint256) public governanceParameters;

    IERC20 public paymentToken; // The ERC20 token used for payments, stakes, and rewards

    string private _name;
    string private _symbol;
    string private _baseTokenURI; // Base URI for Cognitive Agent metadata

    // --- 3. Events ---

    event ModelIntentProposed(uint256 indexed intentId, address indexed proposer, string name, string descriptionCID);
    event SynergyGroupJoined(uint256 indexed intentId, bytes32 indexed groupId, address indexed member);
    event DataSliceContributed(uint256 indexed intentId, uint256 indexed dataSliceId, bytes32 dataHash, address indexed contributor);
    event DataSliceVerified(uint256 indexed dataSliceId, address indexed verifier, bool isValid);
    event ModelComponentContributed(uint256 indexed intentId, uint256 indexed componentId, bytes32 componentHash, address indexed contributor);
    event ModelEvolutionProposed(uint256 indexed intentId, bytes32 indexed proposedModelHash, address indexed proposer);
    event ModelEvolutionVoted(uint256 indexed intentId, bytes32 indexed proposedModelHash, address indexed voter, bool approved);
    event ModelEvolutionFinalized(uint256 indexed intentId, bytes32 indexed newActiveModelHash);
    event CognitiveAgentMinted(uint256 indexed agentId, uint256 indexed intentId, bytes32 modelHash, address indexed owner);
    event AgentInteractionDelegated(uint256 indexed agentId, address indexed delegatee, uint256 until);
    event AgentInteractionRevoked(uint256 indexed agentId, address indexed delegatee);
    event AgentChallengeInitiated(uint256 indexed challengeId, uint256 indexed agentId, address indexed challenger, uint256 challengerStake, uint256 agentStake);
    event AgentChallengeResolved(uint256 indexed challengeId, uint256 indexed agentId, bool isSuccessful);
    event AgentInteractionLogUpdated(uint256 indexed agentId, string newLogCID);
    event AgentDataProcessingRequested(uint256 indexed agentId, uint256 indexed requestId, address indexed requester, uint256 paymentAmount);
    event AgentDataProcessingConfirmed(uint256 indexed agentId, uint256 indexed requestId, string outputDataCID);
    event ComputeProviderRegistered(address indexed providerAddress, string profileCID);
    event ComputeProviderStaked(address indexed providerAddress, uint256 amount);
    event ContributionRewardsDistributed(uint256 indexed intentId, bytes32 indexed modelHash, address indexed recipient, uint256 amount);
    event AgentReputationUpdated(uint256 indexed agentId, int256 delta, string reasonCID);
    event GovernanceParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event ModelGatewayDeployed(uint256 indexed agentId, address indexed gatewayContractAddress);

    // --- 4. Modifiers ---

    modifier onlyAgentOwnerOrDelegate(uint256 _agentId) {
        require(cognitiveAgents[_agentId].owner != address(0), "SynergyNetAI: Agent does not exist");
        require(
            cognitiveAgents[_agentId].owner == msg.sender ||
            (cognitiveAgents[_agentId].delegatedInteractionUntil[msg.sender] > block.timestamp &&
            cognitiveAgents[_agentId].delegatedInteractionUntil[msg.sender] != 0), // Explicit check for non-zero to differentiate revoked from non-set
            "SynergyNetAI: Not agent owner or valid delegatee"
        );
        _;
    }

    modifier onlySynergyGroupMember(uint256 _intentId, bytes32 _groupId) {
        require(modelIntents[_intentId].proposer != address(0), "SynergyNetAI: Intent does not exist");
        require(modelIntents[_intentId].synergyGroups[_groupId].members[msg.sender], "SynergyNetAI: Not a member of this synergy group");
        _;
    }

    // --- 5. Constructor ---

    constructor(address _initialGovernance, address _paymentTokenAddress, string memory _baseURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer is admin
        _grantRole(GOVERNANCE_ROLE, _initialGovernance);

        paymentToken = IERC20(_paymentTokenAddress);

        _name = "CognitiveAgent"; // ERC721 metadata name
        _symbol = "CGA";        // ERC721 metadata symbol
        _baseTokenURI = _baseURI;

        // Initialize default governance parameters
        governanceParameters[keccak256("MIN_VERIFIERS_FOR_DATA")] = 3;
        governanceParameters[keccak256("MIN_VOTES_FOR_EVOLUTION")] = 5; // Minimum votes to pass a proposal
        governanceParameters[keccak256("VOTE_DURATION_SECONDS")] = 7 * 24 * 60 * 60; // 7 days
        governanceParameters[keccak256("CHALLENGE_FEE")] = 1 ether; // Example: 1 token for challenge
        governanceParameters[keccak256("REPUTATION_BOOST_ON_SUCCESS")] = 10;
        governanceParameters[keccak256("REPUTATION_PENALTY_ON_FAILURE")] = -15;
        governanceParameters[keccak256("MIN_CONTRIBUTION_REWARD_POOL")] = 10 * 10**uint256(paymentToken.decimals()); // Min reward pool if balance is low (for demo)
    }

    // --- 6. ERC721Metadata Interface Implementation (for Soulbound Tokens) ---
    // Note: This contract does not fully implement ERC721 as Agents are non-transferable (Soulbound).
    // It provides `name()`, `symbol()`, `tokenURI()`, and `ownerOf()`, but not `transferFrom`, `approve`, etc.

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // Custom internal _exists for Soulbound Token
    function _exists(uint256 tokenId) internal view returns (bool) {
        return cognitiveAgents[tokenId].owner != address(0);
    }

    // Custom ownerOf for Soulbound Token
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return cognitiveAgents[tokenId].owner;
    }

    // Disallow standard ERC721 functions as Cognitive Agents are Soulbound and non-transferable
    function approve(address, uint256) public pure override { revert("SynergyNetAI: Cognitive Agents are Soulbound and non-transferable."); }
    function getApproved(uint256) public pure override returns (address) { revert("SynergyNetAI: Cognitive Agents are Soulbound and non-transferable."); }
    function setApprovalForAll(address, bool) public pure override { revert("SynergyNetAI: Cognitive Agents are Soulbound and non-transferable."); }
    function isApprovedForAll(address, address) public pure override returns (bool) { revert("SynergyNetAI: Cognitive Agents are Soulbound and non-transferable."); }
    function transferFrom(address, address, uint256) public pure override { revert("SynergyNetAI: Cognitive Agents are Soulbound and non-transferable."); }
    function safeTransferFrom(address, address, uint256) public pure override { revert("SynergyNetAI: Cognitive Agents are Soulbound and non-transferable."); }
    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override { revert("SynergyNetAI: Cognitive Agents are Soulbound and non-transferable."); }


    // --- 7. Intent Management Functions ---

    /**
     * @notice Proposes a new AI model development intent.
     * @param _name A human-readable name for the intent.
     * @param _descriptionCID IPFS CID for a detailed description of the AI model's goal.
     * @param _expectedInputsCID IPFS CID for expected input data format.
     * @param _expectedOutputsCID IPFS CID for expected output data format.
     * @param _performanceMetricsCID IPFS CID for detailed performance evaluation metrics.
     */
    function proposeModelIntent(
        string calldata _name,
        string calldata _descriptionCID,
        string calldata _expectedInputsCID,
        string calldata _expectedOutputsCID,
        string calldata _performanceMetricsCID
    ) external {
        _nextIntentId.increment();
        uint256 newIntentId = _nextIntentId.current();

        ModelIntent storage newIntent = modelIntents[newIntentId];
        newIntent.intentId = newIntentId;
        newIntent.name = _name;
        newIntent.descriptionCID = _descriptionCID;
        newIntent.expectedInputsCID = _expectedInputsCID;
        newIntent.expectedOutputsCID = _expectedOutputsCID;
        newIntent.performanceMetricsCID = _performanceMetricsCID;
        newIntent.createdAt = block.timestamp;
        newIntent.proposer = msg.sender;

        emit ModelIntentProposed(newIntentId, msg.sender, _name, _descriptionCID);
    }

    /**
     * @notice Retrieves the current status and active model hash for a specific intent.
     * @param _intentId The ID of the model intent.
     * @return name The intent's name.
     * @return descriptionCID The IPFS CID for the intent's description.
     * @return currentActiveModelHash The hash of the currently active model for this intent.
     * @return activeGroupCount The number of active synergy groups for this intent.
     */
    function getIntentStatus(uint256 _intentId)
        external
        view
        returns (
            string memory name,
            string memory descriptionCID,
            bytes32 currentActiveModelHash,
            uint256 activeGroupCount
        )
    {
        ModelIntent storage intent = modelIntents[_intentId];
        require(intent.proposer != address(0), "SynergyNetAI: Intent does not exist");
        return (intent.name, intent.descriptionCID, intent.currentActiveModelHash, intent.activeGroupCount);
    }

    // --- 8. Contribution & Collaboration Functions ---

    /**
     * @notice Allows a user to join a collaborative group for a specific model intent.
     *         A group ID is provided, which could be generated off-chain (e.g., hash of members, chat room ID).
     * @param _intentId The ID of the model intent.
     * @param _groupId A unique identifier for the synergy group.
     */
    function joinModelIntentGroup(uint256 _intentId, bytes32 _groupId) external {
        ModelIntent storage intent = modelIntents[_intentId];
        require(intent.proposer != address(0), "SynergyNetAI: Intent does not exist");

        SynergyGroup storage group = intent.synergyGroups[_groupId];
        if (!group.members[msg.sender]) {
            group.members[msg.sender] = true;
            group.memberCount++;
            if (group.intentId == 0) { // First member, initialize group
                group.intentId = _intentId;
                group.groupId = _groupId;
                intent.activeGroupCount++;
            }
            emit SynergyGroupJoined(_intentId, _groupId, msg.sender);
        }
    }

    /**
     * @notice Submits a hash of verifiable training data to an intent.
     * @param _intentId The ID of the model intent.
     * @param _dataHash A cryptographic hash of the data content (e.g., SHA256).
     * @param _metadataCID IPFS CID for metadata related to the data slice (e.g., licensing, labels, source).
     * @param _verifiers An array of addresses designated to verify the data slice.
     */
    function contributeDataSlice(
        uint256 _intentId,
        bytes32 _dataHash,
        string calldata _metadataCID,
        address[] calldata _verifiers
    ) external {
        require(modelIntents[_intentId].proposer != address(0), "SynergyNetAI: Intent does not exist");
        require(_verifiers.length > 0, "SynergyNetAI: At least one verifier required");

        _nextDataSliceId.increment();
        uint256 newDataSliceId = _nextDataSliceId.current();

        DataSlice storage newDataSlice = dataSlices[newDataSliceId];
        newDataSlice.dataHash = _dataHash;
        newDataSlice.metadataCID = _metadataCID;
        newDataSlice.contributor = msg.sender;
        newDataSlice.contributedAt = block.timestamp;
        newDataSlice.verifiersNeeded = _verifiers;
        newDataSlice.associatedIntentId = _intentId;

        contributorReputation[msg.sender] += 1; // Basic reputation for initial contribution

        emit DataSliceContributed(_intentId, newDataSliceId, _dataHash, msg.sender);
    }

    /**
     * @notice Designated verifiers confirm the integrity and validity of a data slice.
     * @dev Only addresses in `verifiersNeeded` array for the data slice can call this.
     * @param _dataSliceId The ID of the data slice to verify.
     * @param _isValid True if the data slice is valid, false otherwise.
     */
    function verifyDataSlice(uint256 _dataSliceId, bool _isValid) external {
        DataSlice storage dataSlice = dataSlices[_dataSliceId];
        require(dataSlice.contributor != address(0), "SynergyNetAI: Data slice does not exist");
        require(!dataSlice.isVerifiedBy[msg.sender], "SynergyNetAI: Already verified this data slice");

        bool isDesignatedVerifier = false;
        for (uint256 i = 0; i < dataSlice.verifiersNeeded.length; i++) {
            if (dataSlice.verifiersNeeded[i] == msg.sender) {
                isDesignatedVerifier = true;
                break;
            }
        }
        require(isDesignatedVerifier, "SynergyNetAI: Not a designated verifier for this slice");

        dataSlice.isVerifiedBy[msg.sender] = true;
        if (_isValid) {
            dataSlice.verifiedCount++;
            contributorReputation[msg.sender] += 1;
        } else {
            contributorReputation[dataSlice.contributor] -= 2; // Penalize contributor for invalid data
        }

        emit DataSliceVerified(_dataSliceId, msg.sender, _isValid);
    }

    /**
     * @notice Adds a verifiable AI model component (e.g., a neural network layer or algorithm) to an intent.
     * @param _intentId The ID of the model intent.
     * @param _componentHash A cryptographic hash of the component's code/weights.
     * @param _metadataCID IPFS CID for metadata (e.g., architecture, training details, licenses).
     * @param _dependencies An array of IDs of other model components this one depends on.
     */
    function contributeModelComponent(
        uint256 _intentId,
        bytes32 _componentHash,
        string calldata _metadataCID,
        uint256[] calldata _dependencies
    ) external {
        require(modelIntents[_intentId].proposer != address(0), "SynergyNetAI: Intent does not exist");

        _nextModelComponentId.increment();
        uint256 newComponentId = _nextModelComponentId.current();

        ModelComponent storage newComponent = modelComponents[newComponentId];
        newComponent.componentHash = _componentHash;
        newComponent.metadataCID = _metadataCID;
        newComponent.contributor = msg.sender;
        newComponent.contributedAt = block.timestamp;
        newComponent.dependencies = _dependencies;
        newComponent.associatedIntentId = _intentId;

        contributorReputation[msg.sender] += 2; // Higher reputation for components

        emit ModelComponentContributed(_intentId, newComponentId, _componentHash, msg.sender);
    }

    // --- 9. Model Evolution & Governance Functions ---

    /**
     * @notice Proposes an updated version of a model, linking contributing components and explaining changes.
     *         Requires the proposer to be a contributor to the system (has positive reputation).
     * @param _intentId The ID of the model intent.
     * @param _proposedModelHash The cryptographic hash of the new, proposed model.
     * @param _evolutionNotesCID IPFS CID for detailed notes on the model's evolution, improvements, or changes.
     * @param _contributingComponentIds An array of IDs of model components that are part of this new model.
     */
    function proposeModelEvolution(
        uint256 _intentId,
        bytes32 _proposedModelHash,
        string calldata _evolutionNotesCID,
        uint256[] calldata _contributingComponentIds
    ) external {
        ModelIntent storage intent = modelIntents[_intentId];
        require(intent.proposer != address(0), "SynergyNetAI: Intent does not exist");
        require(contributorReputation[msg.sender] > 0, "SynergyNetAI: Only contributors can propose evolution"); // Basic contributor check

        // Ensure this model hash hasn't been proposed before for this intent
        require(intent.evolutionProposals[_proposedModelHash].proposer == address(0), "SynergyNetAI: Model evolution already proposed");

        ModelEvolutionProposal storage newProposal = intent.evolutionProposals[_proposedModelHash];
        newProposal.modelHash = _proposedModelHash;
        newProposal.evolutionNotesCID = _evolutionNotesCID;
        newProposal.contributingComponentIds = _contributingComponentIds;
        newProposal.proposedAt = block.timestamp;
        newProposal.proposer = msg.sender;

        emit ModelEvolutionProposed(_intentId, _proposedModelHash, msg.sender);
    }

    /**
     * @notice Group members vote to approve or reject a proposed model evolution.
     *         Requires the voter to be a contributor to the system.
     * @param _intentId The ID of the model intent.
     * @param _proposedModelHash The hash of the model evolution proposal.
     * @param _approve True to vote for approval, false to vote for rejection.
     */
    function voteOnModelEvolution(uint256 _intentId, bytes32 _proposedModelHash, bool _approve) external {
        ModelIntent storage intent = modelIntents[_intentId];
        require(intent.proposer != address(0), "SynergyNetAI: Intent does not exist");
        ModelEvolutionProposal storage proposal = intent.evolutionProposals[_proposedModelHash];
        require(proposal.proposer != address(0), "SynergyNetAI: Proposal does not exist");
        require(!proposal.isFinalized, "SynergyNetAI: Proposal already finalized");
        require(block.timestamp <= proposal.proposedAt + governanceParameters[keccak256("VOTE_DURATION_SECONDS")], "SynergyNetAI: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "SynergyNetAI: Already voted on this proposal");

        require(contributorReputation[msg.sender] > 0 || msg.sender == intent.proposer, "SynergyNetAI: Only contributors or intent proposer can vote");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ModelEvolutionVoted(_intentId, _proposedModelHash, msg.sender, _approve);
    }

    /**
     * @notice Finalizes an approved model evolution, making it the active model for an intent.
     * @dev Callable by GOVERNANCE_ROLE or by anyone if the voting threshold is met.
     * @param _intentId The ID of the model intent.
     * @param _modelHash The hash of the model evolution proposal to finalize.
     */
    function finalizeModelEvolution(uint256 _intentId, bytes32 _modelHash) external {
        ModelIntent storage intent = modelIntents[_intentId];
        require(intent.proposer != address(0), "SynergyNetAI: Intent does not exist");
        ModelEvolutionProposal storage proposal = intent.evolutionProposals[_modelHash];
        require(proposal.proposer != address(0), "SynergyNetAI: Proposal does not exist");
        require(!proposal.isFinalized, "SynergyNetAI: Proposal already finalized");

        uint256 minVotes = governanceParameters[keccak256("MIN_VOTES_FOR_EVOLUTION")];
        bool hasEnoughVotes = proposal.votesFor >= minVotes && proposal.votesFor > proposal.votesAgainst;
        bool canFinalize = hasRole(GOVERNANCE_ROLE, msg.sender) || hasEnoughVotes;

        require(canFinalize, "SynergyNetAI: Not enough votes or not authorized to finalize");

        proposal.isFinalized = true;
        intent.currentActiveModelHash = _modelHash;

        // Optionally, distribute rewards here. Call `distributeContributionRewards` with GOVERNANCE_ROLE later.

        emit ModelEvolutionFinalized(_intentId, _modelHash);
    }

    // --- 10. Cognitive Agent (SBT) Management Functions ---

    /**
     * @notice Mints a non-transferable (Soulbound) NFT representing a specific, deployed AI model instance.
     * @dev Only the proposer of the model evolution or a GOVERNANCE_ROLE can mint.
     * @param _intentId The ID of the model intent this agent is based on.
     * @param _modelHash The hash of the finalized model this agent embodies.
     * @param _agentName A human-readable name for the cognitive agent.
     * @param _agentDescriptionCID IPFS CID for a detailed description of this specific agent instance.
     */
    function mintCognitiveAgent(
        uint256 _intentId,
        bytes32 _modelHash,
        string calldata _agentName,
        string calldata _agentDescriptionCID
    ) external {
        ModelIntent storage intent = modelIntents[_intentId];
        require(intent.proposer != address(0), "SynergyNetAI: Intent does not exist");
        require(intent.currentActiveModelHash == _modelHash, "SynergyNetAI: Provided model hash is not the active model for this intent");
        require(intent.evolutionProposals[_modelHash].isFinalized, "SynergyNetAI: Model not finalized");
        require(hasRole(GOVERNANCE_ROLE, msg.sender) || intent.evolutionProposals[_modelHash].proposer == msg.sender, "SynergyNetAI: Not authorized to mint agent");

        _nextAgentId.increment();
        uint256 newAgentId = _nextAgentId.current();

        CognitiveAgent storage newAgent = cognitiveAgents[newAgentId];
        newAgent.agentId = newAgentId;
        newAgent.intentId = _intentId;
        newAgent.modelHash = _modelHash;
        newAgent.name = _agentName;
        newAgent.descriptionCID = _agentDescriptionCID;
        newAgent.owner = msg.sender;
        newAgent.mintedAt = block.timestamp;
        newAgent.reputationScore = 0; // Start with neutral reputation

        emit CognitiveAgentMinted(newAgentId, _intentId, _modelHash, msg.sender);
    }

    /**
     * @notice Allows a Cognitive Agent's owner to temporarily delegate interaction rights to another address.
     * @param _agentId The ID of the Cognitive Agent.
     * @param _delegatee The address to delegate interaction rights to.
     * @param _durationSeconds The duration in seconds for which the delegation is valid.
     */
    function delegateAgentInteractionCapability(uint256 _agentId, address _delegatee, uint256 _durationSeconds) external {
        require(cognitiveAgents[_agentId].owner == msg.sender, "SynergyNetAI: Only agent owner can delegate");
        require(_delegatee != address(0), "SynergyNetAI: Invalid delegatee address");
        require(_durationSeconds > 0, "SynergyNetAI: Delegation duration must be positive");

        uint256 delegationEndTime = block.timestamp + _durationSeconds;
        cognitiveAgents[_agentId].delegatedInteractionUntil[_delegatee] = delegationEndTime;

        emit AgentInteractionDelegated(_agentId, _delegatee, delegationEndTime);
    }

    /**
     * @notice Revokes delegated interaction capabilities for a Cognitive Agent.
     * @param _agentId The ID of the Cognitive Agent.
     * @param _delegatee The address whose interaction rights are to be revoked.
     */
    function revokeAgentInteractionCapability(uint256 _agentId, address _delegatee) external {
        require(cognitiveAgents[_agentId].owner == msg.sender, "SynergyNetAI: Only agent owner can revoke delegation");
        require(cognitiveAgents[_agentId].delegatedInteractionUntil[_delegatee] != 0, "SynergyNetAI: Delegatee does not have active delegation");

        cognitiveAgents[_agentId].delegatedInteractionUntil[_delegatee] = 0; // Set to 0 to invalidate

        emit AgentInteractionRevoked(_agentId, _delegatee);
    }

    // --- 11. Agent Challenge & Reputation Functions ---

    /**
     * @notice Initiates an on-chain performance challenge for a Cognitive Agent.
     * @dev Challenger stakes tokens. Agent owner must also stake an equal amount. An adjudicator (ADJUDICATOR_ROLE) will resolve.
     * @param _agentId The ID of the Cognitive Agent to challenge.
     * @param _challengeInputCID IPFS CID for the input data used for the challenge.
     * @param _expectedOutputCID IPFS CID for the expected output of the challenge.
     */
    function challengeAgentPerformance(
        uint256 _agentId,
        string calldata _challengeInputCID,
        string calldata _expectedOutputCID
    ) external {
        CognitiveAgent storage agent = cognitiveAgents[_agentId];
        require(agent.owner != address(0), "SynergyNetAI: Agent does not exist");
        require(agent.owner != msg.sender, "SynergyNetAI: Agent owner cannot challenge their own agent");

        uint256 challengeFee = governanceParameters[keccak256("CHALLENGE_FEE")];
        require(challengeFee > 0, "SynergyNetAI: Challenge fee not configured");

        require(paymentToken.transferFrom(msg.sender, address(this), challengeFee), "SynergyNetAI: Token transfer failed for challenger stake");
        require(paymentToken.transferFrom(agent.owner, address(this), challengeFee), "SynergyNetAI: Agent owner failed to stake for challenge defense");

        _nextChallengeId.increment();
        uint256 newChallengeId = _nextChallengeId.current();

        AgentChallenge storage newChallenge = agentChallenges[newChallengeId];
        newChallenge.challengeId = newChallengeId;
        newChallenge.agentId = _agentId;
        newChallenge.challenger = msg.sender;
        newChallenge.challengerStake = challengeFee;
        newChallenge.agentStake = challengeFee;
        newChallenge.challengeInputCID = _challengeInputCID;
        newChallenge.expectedOutputCID = _expectedOutputCID;
        newChallenge.challengedAt = block.timestamp;

        emit AgentChallengeInitiated(newChallengeId, _agentId, msg.sender, challengeFee, challengeFee);
    }

    /**
     * @notice Resolves an agent performance challenge, updating the agent's reputation based on the outcome.
     * @dev Only ADJUDICATOR_ROLE can call this.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isSuccessful True if the agent successfully met the challenge, false otherwise.
     * @param _proofCID IPFS CID for the proof/evidence of the challenge resolution.
     */
    function resolveAgentChallenge(uint256 _challengeId, bool _isSuccessful, string calldata _proofCID) external onlyRole(ADJUDICATOR_ROLE) {
        AgentChallenge storage challenge = agentChallenges[_challengeId];
        require(challenge.agentId != 0, "SynergyNetAI: Challenge does not exist");
        require(!challenge.isResolved, "SynergyNetAI: Challenge already resolved");

        challenge.isResolved = true;
        challenge.isSuccessful = _isSuccessful;
        challenge.resolutionProofCID = _proofCID;
        challenge.resolvedAt = block.timestamp;
        challenge.adjudicator = msg.sender;

        CognitiveAgent storage agent = cognitiveAgents[challenge.agentId];

        int256 reputationBoost = int256(governanceParameters[keccak256("REPUTATION_BOOST_ON_SUCCESS")]);
        int256 reputationPenalty = int256(governanceParameters[keccak256("REPUTATION_PENALTY_ON_FAILURE")]);

        if (_isSuccessful) {
            // Agent wins: Challenger's stake goes to agent owner, agent's stake returned.
            // Agent's reputation increases. Challenger's reputation decreases.
            require(paymentToken.transfer(agent.owner, challenge.challengerStake + challenge.agentStake), "SynergyNetAI: Reward transfer failed for agent owner");
            agent.reputationScore += reputationBoost;
            contributorReputation[challenge.challenger] -= (reputationBoost / 2); // Penalize challenger
        } else {
            // Agent fails: Agent's stake goes to challenger, challenger's stake returned.
            // Agent's reputation decreases. Challenger's reputation increases.
            require(paymentToken.transfer(challenge.challenger, challenge.challengerStake + challenge.agentStake), "SynergyNetAI: Reward transfer failed for challenger");
            agent.reputationScore += reputationPenalty;
            contributorReputation[challenge.challenger] += (reputationBoost / 2); // Reward challenger
        }

        emit AgentChallengeResolved(_challengeId, challenge.agentId, _isSuccessful);
        emit AgentReputationUpdated(challenge.agentId, _isSuccessful ? reputationBoost : reputationPenalty, _proofCID);
    }

    /**
     * @notice Allows a Cognitive Agent (or its delegatee) to update its on-chain interaction log summary with an IPFS CID.
     * @param _agentId The ID of the Cognitive Agent.
     * @param _interactionLogCID IPFS CID for the latest summary or proof of the agent's interactions.
     */
    function updateAgentInteractionLog(uint256 _agentId, string calldata _interactionLogCID) external onlyAgentOwnerOrDelegate(_agentId) {
        CognitiveAgent storage agent = cognitiveAgents[_agentId];
        agent.currentInteractionLogCID = _interactionLogCID;
        emit AgentInteractionLogUpdated(_agentId, _interactionLogCID);
    }

    // --- 12. Agent Service Functions ---

    /**
     * @notice Requests off-chain data processing from a Cognitive Agent, with an attached payment.
     * @dev The actual processing is off-chain. The agent must later confirm using `confirmAgentDataProcessing`.
     * @param _agentId The ID of the Cognitive Agent to request processing from.
     * @param _inputDataCID IPFS CID for the input data to be processed.
     * @param _paymentAmount The amount of paymentToken for the processing.
     * @return requestId The unique ID of the processing request.
     */
    function requestAgentDataProcessing(uint256 _agentId, string calldata _inputDataCID, uint256 _paymentAmount) external returns (uint256) {
        CognitiveAgent storage agent = cognitiveAgents[_agentId];
        require(agent.owner != address(0), "SynergyNetAI: Agent does not exist");
        require(_paymentAmount > 0, "SynergyNetAI: Payment amount must be greater than zero");
        require(paymentToken.transferFrom(msg.sender, address(this), _paymentAmount), "SynergyNetAI: Token transfer failed for processing request");

        agent.nextRequestId.increment();
        uint256 newRequestId = agent.nextRequestId.current();

        AgentProcessingRequest storage request = agent.processingRequests[newRequestId];
        request.requestId = newRequestId;
        request.requester = msg.sender;
        request.inputDataCID = _inputDataCID;
        request.paymentAmount = _paymentAmount;
        request.requestedAt = block.timestamp;

        emit AgentDataProcessingRequested(_agentId, newRequestId, msg.sender, _paymentAmount);
        return newRequestId;
    }

    /**
     * @notice The Cognitive Agent (or its delegatee) confirms completed data processing and provides a hash to the output and a proof.
     * @dev Transfers the payment to the agent's owner upon successful confirmation.
     * @param _agentId The ID of the Cognitive Agent.
     * @param _requestId The ID of the processing request.
     * @param _outputDataCID IPFS CID for the processed output data.
     * @param _proofHash A cryptographic hash of the proof of processing (e.g., zk-proof, attestation).
     */
    function confirmAgentDataProcessing(uint256 _agentId, uint256 _requestId, string calldata _outputDataCID, bytes32 _proofHash) external onlyAgentOwnerOrDelegate(_agentId) {
        CognitiveAgent storage agent = cognitiveAgents[_agentId];
        AgentProcessingRequest storage request = agent.processingRequests[_requestId];
        require(request.requester != address(0), "SynergyNetAI: Processing request does not exist");
        require(!request.isCompleted, "SynergyNetAI: Request already completed");

        request.outputDataCID = _outputDataCID;
        request.proofHash = _proofHash;
        request.isCompleted = true;
        request.completedAt = block.timestamp;

        // Transfer payment to agent owner
        require(paymentToken.transfer(agent.owner, request.paymentAmount), "SynergyNetAI: Failed to transfer payment to agent owner");

        agent.reputationScore += 1; // Boost reputation for successful processing

        emit AgentDataProcessingConfirmed(_agentId, _requestId, _outputDataCID);
    }

    // --- 13. Compute Provider & Resource Management Functions ---

    /**
     * @notice Allows an entity to register as a compute provider for training or inference tasks.
     * @param _providerProfileCID IPFS CID for a detailed profile of the provider's compute capabilities.
     */
    function registerComputeProvider(string calldata _providerProfileCID) external {
        require(!computeProviders[msg.sender].isRegistered, "SynergyNetAI: Already a registered compute provider");

        computeProviders[msg.sender].providerProfileCID = _providerProfileCID;
        computeProviders[msg.sender].isRegistered = true;
        computeProviders[msg.sender].registeredAt = block.timestamp;

        emit ComputeProviderRegistered(msg.sender, _providerProfileCID);
    }

    /**
     * @notice Allows a registered compute provider to stake tokens, signalling availability and commitment.
     * @param _amount The amount of paymentToken to stake.
     */
    function stakeForComputeResources(uint256 _amount) external {
        require(computeProviders[msg.sender].isRegistered, "SynergyNetAI: Not a registered compute provider");
        require(_amount > 0, "SynergyNetAI: Stake amount must be greater than zero");
        require(paymentToken.transferFrom(msg.sender, address(this), _amount), "SynergyNetAI: Token transfer failed for staking");

        computeProviders[msg.sender].stakedAmount += _amount;

        emit ComputeProviderStaked(msg.sender, _amount);
    }

    // --- 14. System & Governance Configuration Functions ---

    /**
     * @notice Distributes rewards to data and component contributors for a successfully finalized model.
     * @dev Only GOVERNANCE_ROLE can call this. This is a simplified distribution. A real system would have
     *      a more complex reward allocation based on impact, stake, etc., and a funded reward pool.
     * @param _intentId The ID of the model intent.
     * @param _modelHash The hash of the finalized model.
     */
    function distributeContributionRewards(uint256 _intentId, bytes32 _modelHash) external onlyRole(GOVERNANCE_ROLE) {
        ModelIntent storage intent = modelIntents[_intentId];
        require(intent.proposer != address(0), "SynergyNetAI: Intent does not exist");
        require(intent.evolutionProposals[_modelHash].isFinalized, "SynergyNetAI: Model not finalized");

        mapping(address => uint256) tempRewardPoints;
        address[] memory uniqueContributorsArr = new address[](0);

        // Collect unique contributors for the components of this model
        for (uint256 i = 0; i < intent.evolutionProposals[_modelHash].contributingComponentIds.length; i++) {
            uint256 componentId = intent.evolutionProposals[_modelHash].contributingComponentIds[i];
            ModelComponent storage component = modelComponents[componentId];
            if (component.contributor != address(0) && component.associatedIntentId == _intentId) { // Double check intent match
                if (tempRewardPoints[component.contributor] == 0) {
                    uniqueContributorsArr = _appendAddress(uniqueContributorsArr, component.contributor);
                }
                tempRewardPoints[component.contributor] += 5; // Example reward points
            }
        }

        // Collect unique contributors for verified data slices for this intent
        uint256 minVerifiers = governanceParameters[keccak256("MIN_VERIFIERS_FOR_DATA")];
        for (uint256 dsId = 1; dsId <= _nextDataSliceId.current(); dsId++) {
            DataSlice storage dataSlice = dataSlices[dsId];
            if (dataSlice.contributor != address(0) && dataSlice.associatedIntentId == _intentId && dataSlice.verifiedCount >= minVerifiers) {
                if (tempRewardPoints[dataSlice.contributor] == 0) {
                    uniqueContributorsArr = _appendAddress(uniqueContributorsArr, dataSlice.contributor);
                }
                tempRewardPoints[dataSlice.contributor] += 2; // Example reward points
            }
        }

        uint256 totalRewardPoints = 0;
        for (uint256 i = 0; i < uniqueContributorsArr.length; i++) {
            totalRewardPoints += tempRewardPoints[uniqueContributorsArr[i]];
        }

        require(totalRewardPoints > 0, "SynergyNetAI: No eligible contributors or reward points calculated");

        uint256 rewardPool = paymentToken.balanceOf(address(this));
        // Ensure there's a minimum pool, or fallback if contract balance is too low
        if (rewardPool < governanceParameters[keccak256("MIN_CONTRIBUTION_REWARD_POOL")]) {
            rewardPool = governanceParameters[keccak256("MIN_CONTRIBUTION_REWARD_POOL")]; // For demonstration, assume this can be magically funded
        } else {
             rewardPool = rewardPool / 2; // Distribute half of current contract balance
        }

        require(rewardPool > 0, "SynergyNetAI: Reward pool is empty");

        for (uint256 i = 0; i < uniqueContributorsArr.length; i++) {
            address contributor = uniqueContributorsArr[i];
            uint256 rewardAmount = (tempRewardPoints[contributor] * rewardPool) / totalRewardPoints;
            if (rewardAmount > 0) {
                require(paymentToken.transfer(contributor, rewardAmount), "SynergyNetAI: Reward transfer failed");
                emit ContributionRewardsDistributed(_intentId, _modelHash, contributor, rewardAmount);
            }
        }
    }

    // Helper to append address to dynamic array (note: this is gas inefficient for large arrays, consider a Set or more specific tracking for large scale)
    function _appendAddress(address[] memory arr, address element) private pure returns (address[] memory) {
        address[] memory newArr = new address[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = element;
        return newArr;
    }

    /**
     * @notice Allows authorized roles to adjust an agent's reputation score based on complex, potentially off-chain, metrics.
     * @dev Only GOVERNANCE_ROLE can call this.
     * @param _agentId The ID of the Cognitive Agent.
     * @param _reputationDelta The amount to add or subtract from the agent's reputation.
     * @param _reasonCID IPFS CID for documentation explaining the reputation change.
     */
    function updateAgentReputation(uint256 _agentId, int256 _reputationDelta, string calldata _reasonCID) external onlyRole(GOVERNANCE_ROLE) {
        CognitiveAgent storage agent = cognitiveAgents[_agentId];
        require(agent.owner != address(0), "SynergyNetAI: Agent does not exist");

        agent.reputationScore += _reputationDelta;

        emit AgentReputationUpdated(_agentId, _reputationDelta, _reasonCID);
    }

    /**
     * @notice Enables governance to update key system parameters.
     * @dev Only GOVERNANCE_ROLE can call this.
     * @param _paramKey A keccak256 hash of the parameter name (e.g., `keccak256("MIN_VOTES_FOR_EVOLUTION")`).
     * @param _newValue The new value for the parameter.
     */
    function configureGovernanceParameter(bytes32 _paramKey, uint256 _newValue) external onlyRole(GOVERNANCE_ROLE) {
        governanceParameters[_paramKey] = _newValue;
        emit GovernanceParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @notice Associates an external gateway contract with a Cognitive Agent, allowing other contracts to interact with it.
     * @dev Only the agent owner or GOVERNANCE_ROLE can set this.
     * @param _agentId The ID of the Cognitive Agent.
     * @param _gatewayContractAddress The address of the external gateway contract.
     */
    function deployModelGateway(uint256 _agentId, address _gatewayContractAddress) external onlyAgentOwnerOrDelegate(_agentId) {
        CognitiveAgent storage agent = cognitiveAgents[_agentId];
        require(_gatewayContractAddress != address(0), "SynergyNetAI: Gateway address cannot be zero");

        agent.gatewayContract = _gatewayContractAddress;

        emit ModelGatewayDeployed(_agentId, _gatewayContractAddress);
    }

    // --- 15. Access Control Utility (for setting roles) ---

    /**
     * @notice Grants a role to an address.
     * @dev Only DEFAULT_ADMIN_ROLE can call this.
     * @param role The role to grant (e.g., `GOVERNANCE_ROLE`, `VERIFIER_ROLE`).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes a role from an address.
     * @dev Only DEFAULT_ADMIN_ROLE can call this.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @notice Renounces a role.
     * @dev Can be called by the account itself to remove its own role.
     * @param role The role to renounce.
     * @param account The account renouncing the role (must be `msg.sender`).
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        _renounceRole(role, account);
    }
}
```