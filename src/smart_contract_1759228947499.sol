This smart contract, "OmniForge: Autonomous Skill & Reputation Matrix," envisions a decentralized ecosystem where individuals ("Agents") can mint "Agent Profile" and "Skill Credential" NFTs (acting as dynamic Soulbound Tokens) that represent their verified abilities and on-chain reputation. The system is designed to facilitate autonomous task execution, AI-driven skill assessments, and a collective intelligence framework for decision-making, all while leveraging verifiable credentials and aspiring to integrate zero-knowledge proofs for privacy.

---

## OmniForge: Autonomous Skill & Reputation Matrix

### Outline and Function Summary:

This contract serves as a comprehensive platform for decentralized identity, dynamic skill credentialing, autonomous task management, and reputation building, utilizing a unified ERC721 token standard for both Agent Profiles and Skill Credentials.

**I. Core Identity & SkillBound Tokens (SBTs with Dynamic Traits):**
1.  `registerAgentProfile(string _metadataURI)`: Registers a new agent, minting an initial "Agent Profile SBT" that serves as their core identity. Metadata links to off-chain profile details.
2.  `updateAgentProfileURI(uint256 _tokenId, string _newMetadataURI)`: Allows an agent to update their profile's metadata URI.
3.  `mintSkillCredentialNFT(address _agent, string _skillId, string _proofHash)`: Mints a unique "Skill Credential NFT" linked to an agent's profile, representing a specific skill achievement. `_proofHash` could be a ZK-proof identifier or a verifiable credential hash, to be verified externally.
4.  `attestSkillCredential(uint256 _credentialTokenId, bool _isValid, address _attesterAddress)`: A designated attester (e.g., AI oracle, DAO member, or Schelling point participant) confirms or denies the validity of a skill credential, updating its dynamic traits.
5.  `proposeSkillChallenge(uint256 _credentialTokenId, string _reasonHash)`: Allows any agent to formally challenge the validity of a minted skill credential, initiating a dispute resolution process.
6.  `delegateSkillWeight(uint256 _credentialTokenId, address _delegatee)`: Agents can delegate the "influence weight" of a specific skill credential to another agent for certain governance or task-related actions.
7.  `requestAI_SkillAssessment(uint256 _credentialTokenId, string _contextHash)`: Triggers an off-chain AI oracle request to assess a skill demonstration or context linked to a credential, with the result verified on-chain.
8.  `finalizeAI_SkillAssessment(uint256 _credentialTokenId, uint256 _assessmentScore, bytes _aiSignature)`: An authorized AI oracle submits its signed assessment score, dynamically updating the credential's traits.

**II. Decentralized Task & Contribution Management (Autonomous Agent Network):**
9.  `proposeAutonomousTask(string _taskCID, uint256 _rewardAmount, uint256[] _requiredSkillCredentialIds)`: An agent proposes a task for the autonomous network, specifying required skills (by credential ID) and a crypto reward.
10. `acceptAutonomousTask(uint256 _taskId)`: An agent accepts a proposed task, committing to its completion. Requires the agent to possess the necessary skill credentials.
11. `submitTaskCompletionProof(uint256 _taskId, string _completionProofCID)`: Agent submits verifiable proof of task completion (e.g., IPFS hash of work, ZK-proof).
12. `triggerTaskEvaluation(uint256 _taskId)`: Initiates a decentralized evaluation process for a completed task, potentially involving AI or human reviewers, based on system parameters.
13. `distributeTaskReward(uint256 _taskId)`: Distributes the reward for a successfully completed and evaluated task to the agent.
14. `reportMaliciousTaskBehavior(uint256 _taskId, address _agent, string _reasonHash)`: Allows reporting of malicious behavior related to task execution, initiating a penalty process and potentially affecting reputation.

**III. Dynamic Reputation & Collective Intelligence:**
15. `updateAgentReputationScore(address _agent, int256 _reputationDelta, string _reasonCode)`: The system updates an agent's overall reputation score based on task performance, credential attestations, and other activities. This can be AI-driven or DAO-voted.
16. `signalAgentTrust(address _targetAgent, uint256 _trustScore)`: Allows agents to explicitly signal trust levels in other agents, influencing a social graph and overall reputation, limited by their own reputation.
17. `proposeCollectiveStrategy(string _strategyCID, uint256 _quorumRequired)`: An agent proposes a collective strategy or policy for the OmniForge ecosystem, which other agents can then vote on.
18. `voteOnCollectiveStrategy(uint256 _strategyId, bool _support, uint256[] _supportingSkillCredentialIds)`: Agents vote on strategies, with their voting power potentially weighted by their held Skill Credential NFTs and reputation.

**IV. Advanced Utility & System Control:**
19. `configureSystemParameters(bytes32 _paramKey, uint256 _paramValue)`: Governance function to adjust core system parameters (e.g., reward multipliers, challenge fees, AI oracle addresses).
20. `requestCrossChainVerification(address _targetChainOracle, bytes _proofData)`: Simulates a request to a cross-chain oracle for verification of an external event or proof, integrating a pseudo-cross-chain concept. Requires an `_targetChainOracle` address (which would ideally be a CCIP-like router) and `_proofData`.
21. `setExternalServiceEndpoint(bytes32 _serviceId, string _endpointURI)`: Registers endpoints (e.g., IPFS CIDs or URLs) for off-chain services like ZK-proof verifiers or AI inference engines, managed by the contract.
22. `emergencyPauseOperations(bool _pause)`: Administrator or DAO function to pause critical operations in case of an emergency, preventing state changes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For verifying AI oracle signatures

// Custom Errors
error OmniForge__Unauthorized();
error OmniForge__InvalidTokenId();
error OmniForge__AgentAlreadyRegistered();
error OmniForge__AgentNotRegistered();
error OmniForge__SkillCredentialNotFound();
error OmniForge__SkillCredentialAlreadyValidated();
error OmniForge__SkillCredentialAlreadyChallenged();
error OmniForge__InvalidAssessmentScore();
error OmniForge__TaskNotFound();
error OmniForge__TaskAlreadyAccepted();
error OmniForge__TaskNotAccepted();
error OmniForge__TaskAlreadyCompleted();
error OmniForge__TaskNotCompleted();
error OmniForge__InsufficientFunds();
error OmniForge__NoRewardToDistribute();
error OmniForge__InvalidSkillRequirements();
error OmniForge__NotEnoughSkillWeight();
error OmniForge__ProposalNotFound();
error OmniForge__ProposalAlreadyVoted();
error OmniForge__InvalidSystemParameter();
error OmniForge__ContractPaused();

contract OmniForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _taskIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- System Configuration ---
    address public immutable GOVERNANCE_ADDRESS; // Can be a multi-sig or DAO
    address public immutable AI_ORACLE_ADDRESS; // Address of the trusted AI oracle signer
    uint256 public constant MIN_REPUTATION_FOR_TASK_PROPOSAL = 100;
    uint256 public constant MIN_SKILL_CREDENTIALS_FOR_DELEGATION = 1;
    uint256 public constant CHALLENGE_FEE = 0.01 ether; // Example fee

    // --- Pausability ---
    bool public paused = false;

    // --- Enums ---
    enum TokenType {
        AgentProfile,
        SkillCredential
    }

    enum TaskStatus {
        Open,
        Accepted,
        Submitted,
        Evaluated,
        Completed, // Reward distributed
        Disputed,
        Cancelled
    }

    enum ProposalStatus {
        Pending,
        Approved,
        Rejected,
        Executed
    }

    // --- Structs ---
    struct AgentProfile {
        uint256 tokenId;
        address owner;
        string metadataURI; // IPFS CID or URL for agent profile details
        bool isActive;
    }

    struct SkillCredential {
        uint256 tokenId;
        address owner; // The agent who owns this credential
        string skillId; // Unique identifier for the skill (e.g., "solidity_dev_expert")
        string proofHash; // Hash of the ZK-proof or verifiable credential for external verification
        bool isValidated; // Set true after successful external verification/attestation
        address attester; // Address of the entity that validated/attested
        uint256 assessmentScore; // Dynamic trait: AI-driven assessment score (0-100)
        bool isChallenged; // True if a challenge is pending/active
        address delegatedTo; // Address to whom skill weight is delegated
    }

    struct AutonomousTask {
        uint256 taskId;
        address proposer;
        uint256 rewardAmount;
        uint256[] requiredSkillCredentialIds; // List of SkillCredential tokenIds required
        TaskStatus status;
        address acceptedBy;
        string completionProofCID; // IPFS CID of the submitted work/proof
        address evaluator; // The entity that performed the evaluation
        bool hasBeenEvaluated;
        bool rewardDistributed;
    }

    struct CollectiveStrategy {
        uint256 strategyId;
        address proposer;
        string strategyCID; // IPFS CID of the detailed strategy proposal
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks who has voted
        uint256 yesWeightedVotes;
        uint256 noWeightedVotes;
        uint256 quorumRequired; // Percentage (e.g., 5100 for 51%)
        uint256 votingEndsAt;
    }

    // --- State Variables ---
    mapping(address => AgentProfile) public agentProfiles;
    mapping(uint256 => SkillCredential) public skillCredentials;
    mapping(uint256 => TokenType) public tokenCategory; // Differentiates AgentProfile from SkillCredential NFTs

    mapping(uint256 => AutonomousTask) public autonomousTasks;
    mapping(address => int256) public agentReputation; // Global reputation score for agents
    mapping(address => mapping(address => uint256)) public agentTrustSignals; // agent => targetAgent => trustScore

    mapping(uint256 => CollectiveStrategy) public collectiveStrategies;

    mapping(bytes32 => uint256) public systemParameters; // Configurable system parameters
    mapping(bytes32 => string) public externalServiceEndpoints; // e.g., "ZK_VERIFIER_API" => "https://zk-verifier.example.com"

    // --- Events ---
    event AgentProfileRegistered(address indexed owner, uint256 tokenId, string metadataURI);
    event AgentProfileUpdated(address indexed owner, uint256 tokenId, string newMetadataURI);
    event SkillCredentialMinted(address indexed agent, uint256 tokenId, string skillId, string proofHash);
    event SkillCredentialAttested(uint256 indexed tokenId, bool isValid, address indexed attester);
    event SkillChallengeProposed(uint256 indexed tokenId, address indexed challenger, string reasonHash);
    event SkillWeightDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event AISkillAssessmentRequested(uint256 indexed tokenId, string contextHash);
    event AISkillAssessmentFinalized(uint256 indexed tokenId, uint256 assessmentScore, address indexed aiOracle);

    event AutonomousTaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, string taskCID);
    event AutonomousTaskAccepted(uint256 indexed taskId, address indexed acceptedBy);
    event TaskCompletionProofSubmitted(uint256 indexed taskId, address indexed agent, string completionProofCID);
    event TaskEvaluationTriggered(uint256 indexed taskId, address indexed evaluator);
    event TaskRewardDistributed(uint256 indexed taskId, address indexed recipient, uint256 amount);
    event MaliciousTaskBehaviorReported(uint256 indexed taskId, address indexed reporter, address indexed agent, string reasonHash);

    event AgentReputationUpdated(address indexed agent, int256 newReputation, string reasonCode);
    event AgentTrustSignaled(address indexed signaler, address indexed target, uint256 score);
    event CollectiveStrategyProposed(uint256 indexed strategyId, address indexed proposer, string strategyCID);
    event CollectiveStrategyVoted(uint256 indexed strategyId, address indexed voter, bool support, uint256 weightedVote);
    event CollectiveStrategyStatusChanged(uint256 indexed strategyId, ProposalStatus newStatus);

    event SystemParametersConfigured(bytes32 indexed paramKey, uint256 paramValue);
    event CrossChainVerificationRequested(address indexed targetChainOracle, bytes proofData);
    event ExternalServiceEndpointSet(bytes32 indexed serviceId, string endpointURI);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---
    modifier onlyGovernance() {
        if (msg.sender != GOVERNANCE_ADDRESS && msg.sender != owner()) {
            revert OmniForge__Unauthorized();
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert OmniForge__ContractPaused();
        _;
    }

    modifier onlyAgent(address _agent) {
        if (agentProfiles[_agent].tokenId == 0) revert OmniForge__AgentNotRegistered();
        _;
    }

    modifier onlyAttester(address _attester) {
        if (_attester != AI_ORACLE_ADDRESS && _attester != GOVERNANCE_ADDRESS) {
            revert OmniForge__Unauthorized(); // Placeholder, actual attester logic would be more complex (e.g., specific role)
        }
        _;
    }

    // --- Constructor ---
    constructor(address _governanceAddress, address _aiOracleAddress) ERC721("OmniForge Agent Profile & Skill Credential", "OFASC") Ownable(msg.sender) {
        require(_governanceAddress != address(0), "Governance address cannot be zero");
        require(_aiOracleAddress != address(0), "AI Oracle address cannot be zero");
        GOVERNANCE_ADDRESS = _governanceAddress;
        AI_ORACLE_ADDRESS = _aiOracleAddress;

        // Initialize some default system parameters
        systemParameters[keccak256("TASK_EVALUATION_FEE")] = 0.001 ether;
        systemParameters[keccak256("REPUTATION_PENALTY_MALICIOUS_TASK")] = 100;
        systemParameters[keccak256("REPUTATION_BONUS_TASK_COMPLETION")] = 20;
    }

    // --- Core Identity & SkillBound Tokens (SBTs with Dynamic Traits) ---

    /**
     * @notice Registers a new agent, minting an initial "Agent Profile SBT" that serves as their core identity.
     * @param _metadataURI IPFS CID or URL for agent profile details.
     */
    function registerAgentProfile(string calldata _metadataURI) external whenNotPaused {
        if (agentProfiles[msg.sender].tokenId != 0) {
            revert OmniForge__AgentAlreadyRegistered();
        }
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        agentProfiles[msg.sender] = AgentProfile(newTokenId, msg.sender, _metadataURI, true);
        tokenCategory[newTokenId] = TokenType.AgentProfile;

        // Initialize agent reputation
        agentReputation[msg.sender] = 0;

        emit AgentProfileRegistered(msg.sender, newTokenId, _metadataURI);
    }

    /**
     * @notice Allows an agent to update their profile's metadata URI.
     * @param _tokenId The token ID of the agent's profile NFT.
     * @param _newMetadataURI New IPFS CID or URL for agent profile details.
     */
    function updateAgentProfileURI(uint256 _tokenId, string calldata _newMetadataURI) external whenNotPaused onlyAgent(msg.sender) {
        if (agentProfiles[msg.sender].tokenId != _tokenId || tokenCategory[_tokenId] != TokenType.AgentProfile) {
            revert OmniForge__InvalidTokenId();
        }
        agentProfiles[msg.sender].metadataURI = _newMetadataURI;
        emit AgentProfileUpdated(msg.sender, _tokenId, _newMetadataURI);
    }

    /**
     * @notice Mints a unique "Skill Credential NFT" linked to an agent's profile, representing a specific skill achievement.
     * @param _agent The address of the agent for whom the credential is being minted.
     * @param _skillId Unique identifier for the skill (e.g., "solidity_dev_expert").
     * @param _proofHash Hash of the ZK-proof or verifiable credential for external verification.
     */
    function mintSkillCredentialNFT(address _agent, string calldata _skillId, string calldata _proofHash) external whenNotPaused onlyAgent(_agent) {
        // This function could be restricted to governance, authorized attesters, or even self-minted with external proof.
        // For this example, let's allow an authorized entity (e.g., governance or AI_ORACLE) to mint it.
        if (msg.sender != GOVERNANCE_ADDRESS && msg.sender != AI_ORACLE_ADDRESS) {
            revert OmniForge__Unauthorized();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_agent, newTokenId);
        skillCredentials[newTokenId] = SkillCredential({
            tokenId: newTokenId,
            owner: _agent,
            skillId: _skillId,
            proofHash: _proofHash,
            isValidated: false,
            attester: address(0),
            assessmentScore: 0,
            isChallenged: false,
            delegatedTo: address(0)
        });
        tokenCategory[newTokenId] = TokenType.SkillCredential;

        emit SkillCredentialMinted(_agent, newTokenId, _skillId, _proofHash);
    }

    /**
     * @notice A designated attester confirms or denies the validity of a skill credential, updating its dynamic traits.
     * @param _credentialTokenId The token ID of the Skill Credential NFT.
     * @param _isValid True if the credential is valid, false otherwise.
     * @param _attesterAddress The address of the entity performing the attestation.
     */
    function attestSkillCredential(uint256 _credentialTokenId, bool _isValid, address _attesterAddress) external whenNotPaused onlyAttester(msg.sender) {
        if (tokenCategory[_credentialTokenId] != TokenType.SkillCredential) revert OmniForge__InvalidTokenId();
        SkillCredential storage credential = skillCredentials[_credentialTokenId];
        if (credential.tokenId == 0) revert OmniForge__SkillCredentialNotFound();
        if (credential.isValidated) revert OmniForge__SkillCredentialAlreadyValidated();

        credential.isValidated = _isValid;
        credential.attester = _attesterAddress;

        // Optionally update reputation based on validation
        if (_isValid) {
            _updateReputation(credential.owner, 10, "SkillValidated");
        } else {
            _updateReputation(credential.owner, -5, "SkillValidationFailed");
        }

        emit SkillCredentialAttested(_credentialTokenId, _isValid, _attesterAddress);
    }

    /**
     * @notice Allows any agent to formally challenge the validity of a minted skill credential, initiating a dispute resolution process.
     * @param _credentialTokenId The token ID of the Skill Credential NFT.
     * @param _reasonHash IPFS CID or hash of the reason for the challenge.
     */
    function proposeSkillChallenge(uint256 _credentialTokenId, string calldata _reasonHash) external payable whenNotPaused onlyAgent(msg.sender) {
        if (tokenCategory[_credentialTokenId] != TokenType.SkillCredential) revert OmniForge__InvalidTokenId();
        SkillCredential storage credential = skillCredentials[_credentialTokenId];
        if (credential.tokenId == 0) revert OmniForge__SkillCredentialNotFound();
        if (credential.isChallenged) revert OmniForge__SkillCredentialAlreadyChallenged();
        if (msg.value < CHALLENGE_FEE) revert OmniForge__InsufficientFunds();

        credential.isChallenged = true;
        // In a real system, this would trigger a dispute resolution mechanism (e.g., Kleros, DAO vote)
        // For simplicity, we just mark it as challenged.

        emit SkillChallengeProposed(_credentialTokenId, msg.sender, _reasonHash);
    }

    /**
     * @notice Agents can delegate the "influence weight" of a specific skill credential to another agent for certain governance or task-related actions.
     * @param _credentialTokenId The token ID of the Skill Credential NFT to delegate.
     * @param _delegatee The address of the agent to whom the skill weight is delegated.
     */
    function delegateSkillWeight(uint256 _credentialTokenId, address _delegatee) external whenNotPaused onlyAgent(msg.sender) {
        if (tokenCategory[_credentialTokenId] != TokenType.SkillCredential || skillCredentials[_credentialTokenId].owner != msg.sender) {
            revert OmniForge__InvalidTokenId();
        }
        if (agentProfiles[_delegatee].tokenId == 0) revert OmniForge__AgentNotRegistered();
        if (_delegatee == msg.sender) revert OmniForge__InvalidTokenId(); // Cannot delegate to self

        skillCredentials[_credentialTokenId].delegatedTo = _delegatee;
        emit SkillWeightDelegated(_credentialTokenId, msg.sender, _delegatee);
    }

    /**
     * @notice Triggers an off-chain AI oracle request to assess a skill demonstration or context linked to a credential.
     * @dev The actual AI assessment happens off-chain, and the result is submitted via `finalizeAI_SkillAssessment`.
     * @param _credentialTokenId The token ID of the Skill Credential NFT.
     * @param _contextHash IPFS CID or hash of the context/demonstration for AI assessment.
     */
    function requestAI_SkillAssessment(uint256 _credentialTokenId, string calldata _contextHash) external whenNotPaused onlyAgent(msg.sender) {
        if (tokenCategory[_credentialTokenId] != TokenType.SkillCredential || skillCredentials[_credentialTokenId].owner != msg.sender) {
            revert OmniForge__InvalidTokenId();
        }
        // In a real system, this would emit an event that an off-chain oracle service listens to.
        // For this contract, it simply records the request.
        emit AISkillAssessmentRequested(_credentialTokenId, _contextHash);
    }

    /**
     * @notice An authorized AI oracle submits its signed assessment score, dynamically updating the credential's traits.
     * @param _credentialTokenId The token ID of the Skill Credential NFT.
     * @param _assessmentScore The score provided by the AI oracle (e.g., 0-100).
     * @param _aiSignature Cryptographic signature from the AI_ORACLE_ADDRESS verifying the assessment.
     */
    function finalizeAI_SkillAssessment(uint256 _credentialTokenId, uint256 _assessmentScore, bytes calldata _aiSignature) external whenNotPaused {
        if (tokenCategory[_credentialTokenId] != TokenType.SkillCredential) revert OmniForge__InvalidTokenId();
        SkillCredential storage credential = skillCredentials[_credentialTokenId];
        if (credential.tokenId == 0) revert OmniForge__SkillCredentialNotFound();
        if (_assessmentScore > 100) revert OmniForge__InvalidAssessmentScore();

        // Verify the AI oracle's signature
        bytes32 messageHash = keccak256(abi.encodePacked(_credentialTokenId, _assessmentScore));
        bytes32 signedHash = messageHash.toEthSignedMessageHash();

        if (signedHash.recover(_aiSignature) != AI_ORACLE_ADDRESS) {
            revert OmniForge__Unauthorized(); // Invalid AI oracle signature
        }

        credential.assessmentScore = _assessmentScore;
        // Potentially update reputation based on assessment score
        _updateReputation(credential.owner, int256(_assessmentScore / 10), "AISkillAssessment");

        emit AISkillAssessmentFinalized(_credentialTokenId, _assessmentScore, AI_ORACLE_ADDRESS);
    }

    // --- Decentralized Task & Contribution Management (Autonomous Agent Network) ---

    /**
     * @notice An agent proposes a task for the autonomous network, specifying required skills and a crypto reward.
     * @param _taskCID IPFS CID of the detailed task description.
     * @param _rewardAmount The amount of native token (ETH) to reward for task completion.
     * @param _requiredSkillCredentialIds List of SkillCredential token IDs that are required to accept this task.
     */
    function proposeAutonomousTask(string calldata _taskCID, uint256 _rewardAmount, uint256[] calldata _requiredSkillCredentialIds) external payable whenNotPaused onlyAgent(msg.sender) {
        if (agentReputation[msg.sender] < int256(MIN_REPUTATION_FOR_TASK_PROPOSAL)) {
            revert OmniForge__Unauthorized(); // Not enough reputation to propose tasks
        }
        if (msg.value < _rewardAmount) {
            revert OmniForge__InsufficientFunds();
        }

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        autonomousTasks[newTaskId] = AutonomousTask({
            taskId: newTaskId,
            proposer: msg.sender,
            rewardAmount: _rewardAmount,
            requiredSkillCredentialIds: _requiredSkillCredentialIds,
            status: TaskStatus.Open,
            acceptedBy: address(0),
            completionProofCID: "",
            evaluator: address(0),
            hasBeenEvaluated: false,
            rewardDistributed: false
        });

        emit AutonomousTaskProposed(newTaskId, msg.sender, _rewardAmount, _taskCID);
    }

    /**
     * @notice An agent accepts a proposed task, committing to its completion.
     * @dev Requires the agent to possess the necessary skill credentials (either directly or via delegation).
     * @param _taskId The ID of the task to accept.
     */
    function acceptAutonomousTask(uint256 _taskId) external whenNotPaused onlyAgent(msg.sender) {
        AutonomousTask storage task = autonomousTasks[_taskId];
        if (task.taskId == 0) revert OmniForge__TaskNotFound();
        if (task.status != TaskStatus.Open) revert OmniForge__TaskAlreadyAccepted();

        // Verify agent possesses required skills
        for (uint256 i = 0; i < task.requiredSkillCredentialIds.length; i++) {
            uint256 requiredSkillId = task.requiredSkillCredentialIds[i];
            SkillCredential storage skill = skillCredentials[requiredSkillId];

            if (skill.tokenId == 0 || !skill.isValidated || skill.assessmentScore < 50) { // Example threshold
                revert OmniForge__InvalidSkillRequirements();
            }

            // Check if agent owns the skill or it's delegated to them
            if (skill.owner != msg.sender && skill.delegatedTo != msg.sender) {
                revert OmniForge__InvalidSkillRequirements();
            }
        }

        task.acceptedBy = msg.sender;
        task.status = TaskStatus.Accepted;

        emit AutonomousTaskAccepted(_taskId, msg.sender);
    }

    /**
     * @notice Agent submits verifiable proof of task completion.
     * @param _taskId The ID of the task.
     * @param _completionProofCID IPFS CID of the submitted work/proof.
     */
    function submitTaskCompletionProof(uint256 _taskId, string calldata _completionProofCID) external whenNotPaused onlyAgent(msg.sender) {
        AutonomousTask storage task = autonomousTasks[_taskId];
        if (task.taskId == 0) revert OmniForge__TaskNotFound();
        if (task.acceptedBy != msg.sender) revert OmniForge__TaskNotAccepted();
        if (task.status != TaskStatus.Accepted) revert OmniForge__TaskAlreadyCompleted(); // Or submitted

        task.completionProofCID = _completionProofCID;
        task.status = TaskStatus.Submitted;

        emit TaskCompletionProofSubmitted(_taskId, msg.sender, _completionProofCID);
    }

    /**
     * @notice Initiates a decentralized evaluation process for a completed task.
     * @dev This would typically be triggered by governance or an automated system.
     * @param _taskId The ID of the task to evaluate.
     */
    function triggerTaskEvaluation(uint256 _taskId) external whenNotPaused onlyGovernance {
        AutonomousTask storage task = autonomousTasks[_taskId];
        if (task.taskId == 0) revert OmniForge__TaskNotFound();
        if (task.status != TaskStatus.Submitted) revert OmniForge__TaskNotCompleted();
        if (task.hasBeenEvaluated) revert OmniForge__TaskAlreadyCompleted();

        // In a complex system, this would initiate a DAO vote, AI evaluation, or Schelling game.
        // For simplicity, we just mark it as evaluated by the governance.
        task.evaluator = msg.sender;
        task.hasBeenEvaluated = true;
        task.status = TaskStatus.Evaluated;

        emit TaskEvaluationTriggered(_taskId, msg.sender);
    }

    /**
     * @notice Distributes the reward for a successfully completed and evaluated task to the agent.
     * @param _taskId The ID of the task.
     */
    function distributeTaskReward(uint256 _taskId) external whenNotPaused onlyGovernance {
        AutonomousTask storage task = autonomousTasks[_taskId];
        if (task.taskId == 0) revert OmniForge__TaskNotFound();
        if (task.status != TaskStatus.Evaluated) revert OmniForge__TaskNotCompleted();
        if (task.rewardDistributed) revert OmniForge__NoRewardToDistribute();
        if (address(this).balance < task.rewardAmount) revert OmniForge__InsufficientFunds();

        task.rewardDistributed = true;
        task.status = TaskStatus.Completed;

        payable(task.acceptedBy).transfer(task.rewardAmount);
        _updateReputation(task.acceptedBy, int256(systemParameters[keccak256("REPUTATION_BONUS_TASK_COMPLETION")]), "TaskCompletion");

        emit TaskRewardDistributed(_taskId, task.acceptedBy, task.rewardAmount);
    }

    /**
     * @notice Allows reporting of malicious behavior related to task execution, initiating a penalty process.
     * @param _taskId The ID of the task.
     * @param _agent The address of the agent suspected of malicious behavior.
     * @param _reasonHash IPFS CID or hash of the reason for the report.
     */
    function reportMaliciousTaskBehavior(uint256 _taskId, address _agent, string calldata _reasonHash) external whenNotPaused onlyAgent(msg.sender) {
        AutonomousTask storage task = autonomousTasks[_taskId];
        if (task.taskId == 0) revert OmniForge__TaskNotFound();

        // This would typically trigger a dispute system, but for now, we'll log and allow governance to act.
        if (_agent != msg.sender) { // Prevents self-reporting (unless specific mechanism)
            // Trigger governance review
            _updateReputation(_agent, -1 * int256(systemParameters[keccak256("REPUTATION_PENALTY_MALICIOUS_TASK")]), "MaliciousBehaviorReported");
            task.status = TaskStatus.Disputed; // Mark task as disputed

            emit MaliciousTaskBehaviorReported(_taskId, msg.sender, _agent, _reasonHash);
        }
    }

    // --- Dynamic Reputation & Collective Intelligence ---

    /**
     * @notice The system updates an agent's overall reputation score based on various activities.
     * @dev This is an internal helper, but could be exposed for specific governance actions.
     * @param _agent The address of the agent whose reputation is being updated.
     * @param _reputationDelta The change in reputation score (can be positive or negative).
     * @param _reasonCode A string identifier for why the reputation was updated.
     */
    function _updateReputation(address _agent, int256 _reputationDelta, string memory _reasonCode) internal {
        // Ensure agent is registered before updating reputation
        if (agentProfiles[_agent].tokenId == 0) return;

        agentReputation[_agent] = agentReputation[_agent] + _reputationDelta;
        emit AgentReputationUpdated(_agent, agentReputation[_agent], _reasonCode);
    }

    /**
     * @notice Allows agents to explicitly signal trust levels in other agents, influencing a social graph and overall reputation.
     * @param _targetAgent The address of the agent being signaled trust.
     * @param _trustScore The score representing the level of trust (e.g., 1-10, weighted by signaler's reputation).
     */
    function signalAgentTrust(address _targetAgent, uint256 _trustScore) external whenNotPaused onlyAgent(msg.sender) {
        if (_targetAgent == msg.sender) revert OmniForge__InvalidTokenId(); // Cannot trust self
        if (agentProfiles[_targetAgent].tokenId == 0) revert OmniForge__AgentNotRegistered();
        if (_trustScore == 0 || _trustScore > 10) revert OmniForge__InvalidAssessmentScore(); // Example range for trust score

        // Weight the trust signal by the signaler's reputation
        uint256 weightedScore = _trustScore.mul(uint256(agentReputation[msg.sender] > 0 ? uint256(agentReputation[msg.sender]) : 1)); // Prevent 0 or negative
        agentTrustSignals[msg.sender][_targetAgent] = weightedScore;

        // Directly apply a reputation boost (or penalty) for signaling trust.
        // A more advanced system would aggregate trust signals over time.
        _updateReputation(_targetAgent, int256(weightedScore / 100), "TrustSignal"); // Example calculation

        emit AgentTrustSignaled(msg.sender, _targetAgent, weightedScore);
    }

    /**
     * @notice An agent proposes a collective strategy or policy for the OmniForge ecosystem.
     * @param _strategyCID IPFS CID of the detailed strategy proposal.
     * @param _quorumRequired Percentage (e.g., 5100 for 51%) of total weighted votes required for approval.
     */
    function proposeCollectiveStrategy(string calldata _strategyCID, uint256 _quorumRequired) external whenNotPaused onlyAgent(msg.sender) {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        collectiveStrategies[newProposalId] = CollectiveStrategy({
            strategyId: newProposalId,
            proposer: msg.sender,
            strategyCID: _strategyCID,
            status: ProposalStatus.Pending,
            yesWeightedVotes: 0,
            noWeightedVotes: 0,
            quorumRequired: _quorumRequired,
            votingEndsAt: block.timestamp + 7 days // Example: 7 days voting period
        });

        emit CollectiveStrategyProposed(newProposalId, msg.sender, _strategyCID);
    }

    /**
     * @notice Agents vote on strategies, with their voting power potentially weighted by their held Skill Credential NFTs and reputation.
     * @param _strategyId The ID of the strategy proposal.
     * @param _support True for 'yes', false for 'no'.
     * @param _supportingSkillCredentialIds Array of SkillCredential token IDs the agent uses to weight their vote.
     */
    function voteOnCollectiveStrategy(uint256 _strategyId, bool _support, uint256[] calldata _supportingSkillCredentialIds) external whenNotPaused onlyAgent(msg.sender) {
        CollectiveStrategy storage proposal = collectiveStrategies[_strategyId];
        if (proposal.strategyId == 0) revert OmniForge__ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending || block.timestamp > proposal.votingEndsAt) {
            revert OmniForge__ProposalAlreadyVoted(); // Or voting period ended
        }
        if (proposal.hasVoted[msg.sender]) revert OmniForge__ProposalAlreadyVoted();

        uint256 weightedVote = 0;
        // Base vote from reputation
        weightedVote = weightedVote.add(uint256(agentReputation[msg.sender] > 0 ? uint256(agentReputation[msg.sender]) : 0));

        // Add weight from supporting skill credentials
        for (uint256 i = 0; i < _supportingSkillCredentialIds.length; i++) {
            uint256 skillId = _supportingSkillCredentialIds[i];
            SkillCredential storage skill = skillCredentials[skillId];

            // Ensure the skill belongs to the voter or is delegated to them
            if (skill.tokenId != 0 && skill.isValidated && (skill.owner == msg.sender || skill.delegatedTo == msg.sender)) {
                weightedVote = weightedVote.add(skill.assessmentScore); // Use assessment score as weight
            }
        }

        if (weightedVote == 0) revert OmniForge__NotEnoughSkillWeight(); // Need some voting power

        if (_support) {
            proposal.yesWeightedVotes = proposal.yesWeightedVotes.add(weightedVote);
        } else {
            proposal.noWeightedVotes = proposal.noWeightedVotes.add(weightedVote);
        }
        proposal.hasVoted[msg.sender] = true;

        emit CollectiveStrategyVoted(_strategyId, msg.sender, _support, weightedVote);

        // Check if quorum is reached and update status
        uint256 totalWeightedVotes = proposal.yesWeightedVotes.add(proposal.noWeightedVotes);
        if (totalWeightedVotes > 0 && proposal.yesWeightedVotes.mul(10000).div(totalWeightedVotes) >= proposal.quorumRequired) {
            proposal.status = ProposalStatus.Approved;
            emit CollectiveStrategyStatusChanged(_strategyId, ProposalStatus.Approved);
            // In a real system, this would trigger an execution of the strategy or a governance call
        } else if (block.timestamp > proposal.votingEndsAt) {
            proposal.status = ProposalStatus.Rejected;
            emit CollectiveStrategyStatusChanged(_strategyId, ProposalStatus.Rejected);
        }
    }

    // --- Advanced Utility & System Control ---

    /**
     * @notice Governance function to adjust core system parameters (e.g., reward multipliers, challenge fees, AI oracle addresses).
     * @param _paramKey A bytes32 identifier for the parameter (e.g., keccak256("CHALLENGE_FEE")).
     * @param _paramValue The new uint256 value for the parameter.
     */
    function configureSystemParameters(bytes32 _paramKey, uint256 _paramValue) external whenNotPaused onlyGovernance {
        systemParameters[_paramKey] = _paramValue;
        emit SystemParametersConfigured(_paramKey, _paramValue);
    }

    /**
     * @notice Simulates a request to a cross-chain oracle for verification of an external event or proof.
     * @dev This function is illustrative and would interface with a more complex cross-chain interoperability protocol (e.g., Chainlink CCIP).
     * @param _targetChainOracle The address of the oracle/router on the target chain.
     * @param _proofData The data representing the proof or request for verification.
     */
    function requestCrossChainVerification(address _targetChainOracle, bytes calldata _proofData) external whenNotPaused {
        // In a real scenario, this would involve sending a message via a cross-chain messaging protocol.
        // For demonstration, it just emits an event. The result would be received via an inbound message.
        // Example: CCIP could call back a specific handler function in this contract.
        require(_targetChainOracle != address(0), "Target Chain Oracle cannot be zero address");
        // A more robust implementation would include specific CCIP interface calls.
        emit CrossChainVerificationRequested(_targetChainOracle, _proofData);
    }

    /**
     * @notice Registers endpoints for off-chain services like ZK-proof verifiers or AI inference engines, managed by the contract.
     * @param _serviceId A bytes32 identifier for the service (e.g., keccak256("ZK_VERIFIER_API")).
     * @param _endpointURI The URI or IPFS CID of the service endpoint.
     */
    function setExternalServiceEndpoint(bytes32 _serviceId, string calldata _endpointURI) external whenNotPaused onlyGovernance {
        externalServiceEndpoints[_serviceId] = _endpointURI;
        emit ExternalServiceEndpointSet(_serviceId, _endpointURI);
    }

    /**
     * @notice Administrator or DAO function to pause critical operations in case of an emergency.
     * @param _pause True to pause, false to unpause.
     */
    function emergencyPauseOperations(bool _pause) external onlyGovernance {
        if (_pause == paused) return;
        paused = _pause;
        if (paused) {
            emit Paused(msg.sender);
        } else {
            emit Unpaused(msg.sender);
        }
    }

    // --- View Functions ---

    function getAgentProfile(address _agent) public view returns (uint256 tokenId, string memory metadataURI, bool isActive, int256 reputation) {
        AgentProfile storage profile = agentProfiles[_agent];
        return (profile.tokenId, profile.metadataURI, profile.isActive, agentReputation[_agent]);
    }

    function getSkillCredential(uint256 _credentialTokenId) public view returns (uint256 tokenId, address owner, string memory skillId, string memory proofHash, bool isValidated, address attester, uint256 assessmentScore, bool isChallenged, address delegatedTo) {
        SkillCredential storage credential = skillCredentials[_credentialTokenId];
        return (credential.tokenId, credential.owner, credential.skillId, credential.proofHash, credential.isValidated, credential.attester, credential.assessmentScore, credential.isChallenged, credential.delegatedTo);
    }

    function getAutonomousTask(uint256 _taskId) public view returns (uint256 taskId, address proposer, uint256 rewardAmount, uint256[] memory requiredSkillCredentialIds, TaskStatus status, address acceptedBy, string memory completionProofCID, bool hasBeenEvaluated, bool rewardDistributed) {
        AutonomousTask storage task = autonomousTasks[_taskId];
        return (task.taskId, task.proposer, task.rewardAmount, task.requiredSkillCredentialIds, task.status, task.acceptedBy, task.completionProofCID, task.hasBeenEvaluated, task.rewardDistributed);
    }

    function getCollectiveStrategy(uint256 _strategyId) public view returns (uint256 strategyId, address proposer, string memory strategyCID, ProposalStatus status, uint256 yesWeightedVotes, uint256 noWeightedVotes, uint256 quorumRequired, uint256 votingEndsAt) {
        CollectiveStrategy storage proposal = collectiveStrategies[_strategyId];
        return (proposal.strategyId, proposal.proposer, proposal.strategyCID, proposal.status, proposal.yesWeightedVotes, proposal.noWeightedVotes, proposal.quorumRequired, proposal.votingEndsAt);
    }

    function getSystemParameter(bytes32 _paramKey) public view returns (uint256) {
        return systemParameters[_paramKey];
    }

    function getExternalServiceEndpoint(bytes32 _serviceId) public view returns (string memory) {
        return externalServiceEndpoints[_serviceId];
    }

    function getAgentReputation(address _agent) public view returns (int256) {
        return agentReputation[_agent];
    }
}
```