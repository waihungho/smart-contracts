This smart contract, `GenesisForgeAGADA` (AI-Governed Adaptive Decentralized Agents), is designed to be a decentralized ecosystem for minting, evolving, and deploying intelligent, dynamic NFTs. These "Agents" are not just digital collectibles but programmable entities that can perform tasks, gain experience, and evolve based on their actions, AI oracle attestations, and community governance.

---

## GenesisForgeAGADA: AI-Governed Adaptive Decentralized Agents

**Core Concept:**
GenesisForgeAGADA introduces a novel paradigm for "AI-powered" dynamic NFTs. Users can forge (mint) unique Agents that are designed to be autonomous or semi-autonomous entities. These Agents possess mutable attributes, can be assigned on-chain tasks, evolve in form and capability, and are subject to a hybrid governance model involving AI oracle attestations and community DAO votes. The contract facilitates a market for agent deployment, experience accumulation, and adaptive resource management.

**Key Advanced Concepts & Features:**

1.  **Dynamic NFTs with State Evolution:** Agent attributes (level, capabilities, form URI) are not static but evolve based on accumulated experience (XP) and AI oracle judgments, making them truly "living" assets.
2.  **AI Oracle Integration (Simulated):** The contract defines an interface for an external AI Oracle that provides crucial services like evolution attestations, task verification, and intelligence reports. This off-chain AI computation drives on-chain state changes.
3.  **Decentralized Task Delegation & Execution:** Agents can be assigned specific on-chain tasks, effectively delegating execution rights (`_targetContract`, `_callData`). The agent owner acts as a relayer to execute these tasks, earning rewards upon successful verification.
4.  **Reputation and Skill Trees:** Agents accumulate Experience Points (XP), level up, and unlock specialized capabilities, simulating a skill tree or progression system.
5.  **Hybrid Governance:** High-level decisions, such as new Agent protocols or system-wide fee adjustments, are made via a DAO. Agent-specific evolution and task verification are often guided by AI oracle consensus, combining decentralized and intelligent oversight.
6.  **Resource Management & Economy:** Agents consume 'Energy' for actions, which can be refueled, creating an internal resource economy.
7.  **Delegated Agent Permissions:** Owners can delegate fine-grained control over their agents to other addresses, enabling collaborative management or specialized service provision.
8.  **Adaptive Fee Structures:** Forging fees and AI attestation costs can be adjusted dynamically through DAO governance.

---

### Function Summary:

1.  `forgeAgent(string memory _agentName, uint256 _initialTraitSeed)`: Mints a new Agent NFT, setting its initial name and using a seed for potential attribute generation.
2.  `setAgentDirective(uint256 _agentId, string memory _directive)`: Assigns a high-level, conceptual directive or mission statement to an agent, interpreted by off-chain AI.
3.  `requestEvolutionJudgment(uint256 _agentId, bytes32 _challengeHash)`: Triggers a request to the AI oracle to judge an agent's readiness for evolution, based on a challenge.
4.  `attestEvolution(uint256 _agentId, uint256 _newLevel, string memory _newFormURI, bytes memory _oracleSignature)`: Callback from a trusted AI oracle confirming an agent's evolution (level up, new appearance, new capabilities).
5.  `deployAgentTask(uint256 _agentId, address _targetContract, bytes memory _callData, uint256 _rewardAmount)`: Posts a new on-chain task for an agent, involving a specific function call on a target contract.
6.  `completeDelegatedTask(uint256 _agentId, uint256 _taskId, bytes memory _proofOfExecution)`: Agent owner executes the delegated task and submits proof for verification.
7.  `verifyTaskResult(uint256 _taskId, bool _success, bytes memory _verificationData, bytes memory _oracleSignature)`: AI oracle or trusted verifier confirms the task outcome, enabling reward distribution.
8.  `delegateAgentPermission(uint256 _agentId, address _delegatee, bytes4 _selector, bool _canDelegate)`: Allows an agent owner to grant/revoke specific function call permissions over their agent to another address.
9.  `claimAgentReward(uint256 _agentId, uint256 _taskId)`: Allows the agent owner to claim rewards for a successfully completed and verified task.
10. `proposeAgentProtocol(string memory _protocolURI, bytes32 _protocolHash)`: Initiates a DAO proposal for a new agent protocol (e.g., new type, behavior rules, AI model integration).
11. `voteOnProtocolProposal(uint256 _proposalId, bool _support)`: Allows community members to vote on active protocol proposals.
12. `activateProtocol(uint256 _proposalId)`: Activates a new protocol once a proposal has passed.
13. `requestAgentIntelligenceReport(uint256 _agentId, bytes32 _queryHash)`: Requests an AI oracle to generate a report on an agent's capabilities or predictions.
14. `receiveIntelligenceReport(uint256 _agentId, string memory _reportURI, bytes memory _oracleSignature)`: Callback from AI oracle with the URI of the generated intelligence report.
15. `setAgentEnergyConfig(uint256 _agentId, uint256 _energyCostPerAction, uint256 _maxEnergyCapacity)`: Configures the energy consumption and capacity for a specific agent.
16. `refuelAgentEnergy(uint256 _agentId, uint256 _amount)`: Replenishes an agent's energy, typically by consuming a native token or ERC20.
17. `registerAgentProcessor(address _processorAddress, bytes32 _processorTypeHash)`: Registers an external specialized processor (e.g., for specific computations) that agents can interface with.
18. `setAgentInteractionMode(uint256 _agentId, InteractionMode _mode)`: Sets an agent's operational mode (Autonomous, Guided, Passive), influencing its behavior.
19. `adjustAdaptiveFeeRate(uint256 _newForgingFee, uint256 _newAttestationFee)`: DAO-governed function to update system-wide fees for forging and AI services.
20. `migrateAgentToNewProtocol(uint256 _agentId, uint256 _newProtocolId)`: Allows an agent to be upgraded or migrated to a newly activated protocol.
21. `burnDefunctAgent(uint256 _agentId)`: Permanently removes an agent NFT from circulation, typically for decommissioned or failed agents.
22. `grantExperiencePoints(uint256 _agentId, uint256 _points)`: Awards experience points to an agent, triggering potential level-ups.
23. `setAIOracle(address _newOracle)`: Sets or updates the address of the trusted AI Oracle contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential fee payments or refuels

// ============================================================================
// GenesisForgeAGADA: AI-Governed Adaptive Decentralized Agents (AGADA)
// ============================================================================
// Core Concept:
// GenesisForgeAGADA introduces a novel paradigm for "AI-powered" dynamic NFTs.
// Users can forge (mint) unique Agents that are designed to be autonomous or
// semi-autonomous entities. These Agents possess mutable attributes, can be
// assigned on-chain tasks, evolve in form and capability, and are subject to
// a hybrid governance model involving AI oracle attestations and community
// DAO votes. The contract facilitates a market for agent deployment,
// experience accumulation, and adaptive resource management.
//
// Key Advanced Concepts & Features:
// 1. Dynamic NFTs with State Evolution: Agent attributes (level, capabilities,
//    form URI) are not static but evolve based on accumulated experience (XP)
//    and AI oracle judgments, making them truly "living" assets.
// 2. AI Oracle Integration (Simulated): The contract defines an interface for
//    an external AI Oracle that provides crucial services like evolution
//    attestations, task verification, and intelligence reports. This off-chain
//    AI computation drives on-chain state changes.
// 3. Decentralized Task Delegation & Execution: Agents can be assigned specific
//    on-chain tasks, effectively delegating execution rights (`_targetContract`,
//    `_callData`). The agent owner acts as a relayer to execute these tasks,
//    earning rewards upon successful verification.
// 4. Reputation and Skill Trees: Agents accumulate Experience Points (XP),
//    level up, and unlock specialized capabilities, simulating a skill tree
//    or progression system.
// 5. Hybrid Governance: High-level decisions, such as new Agent protocols or
//    system-wide fee adjustments, are made via a DAO. Agent-specific evolution
//    and task verification are often guided by AI oracle consensus, combining
//    decentralized and intelligent oversight.
// 6. Resource Management & Economy: Agents consume 'Energy' for actions, which
//    can be refueled, creating an internal resource economy.
// 7. Delegated Agent Permissions: Owners can delegate fine-grained control
//    over their agents to other addresses, enabling collaborative management
//    or specialized service provision.
// 8. Adaptive Fee Structures: Forging fees and AI attestation costs can be
//    adjusted dynamically through DAO governance.
//
// Function Summary:
// 1. forgeAgent(string memory _agentName, uint256 _initialTraitSeed): Mints a new Agent NFT.
// 2. setAgentDirective(uint256 _agentId, string memory _directive): Assigns a conceptual directive to an agent.
// 3. requestEvolutionJudgment(uint256 _agentId, bytes32 _challengeHash): Triggers AI oracle for evolution judgment.
// 4. attestEvolution(uint256 _agentId, uint256 _newLevel, string memory _newFormURI, bytes memory _oracleSignature): Callback from AI oracle for agent evolution.
// 5. deployAgentTask(uint256 _agentId, address _targetContract, bytes memory _callData, uint256 _rewardAmount): Posts an on-chain task for an agent.
// 6. completeDelegatedTask(uint256 _agentId, uint256 _taskId, bytes memory _proofOfExecution): Agent owner executes and submits proof for a task.
// 7. verifyTaskResult(uint256 _taskId, bool _success, bytes memory _verificationData, bytes memory _oracleSignature): AI oracle/verifier confirms task outcome.
// 8. delegateAgentPermission(uint256 _agentId, address _delegatee, bytes4 _selector, bool _canDelegate): Grants/revokes specific function permissions for an agent.
// 9. claimAgentReward(uint256 _agentId, uint256 _taskId): Allows agent owner to claim rewards for verified tasks.
// 10. proposeAgentProtocol(string memory _protocolURI, bytes32 _protocolHash): Initiates a DAO proposal for a new agent protocol.
// 11. voteOnProtocolProposal(uint256 _proposalId, bool _support): Allows community to vote on protocol proposals.
// 12. activateProtocol(uint256 _proposalId): Activates a new protocol if a proposal passes.
// 13. requestAgentIntelligenceReport(uint256 _agentId, bytes32 _queryHash): Requests AI oracle for an intelligence report on an agent.
// 14. receiveIntelligenceReport(uint256 _agentId, string memory _reportURI, bytes memory _oracleSignature): Callback from AI oracle with report URI.
// 15. setAgentEnergyConfig(uint256 _agentId, uint256 _energyCostPerAction, uint256 _maxEnergyCapacity): Configures energy usage for an agent.
// 16. refuelAgentEnergy(uint256 _agentId, uint256 _amount): Replenishes an agent's energy.
// 17. registerAgentProcessor(address _processorAddress, bytes32 _processorTypeHash): Registers external specialized processors.
// 18. setAgentInteractionMode(uint256 _agentId, InteractionMode _mode): Sets an agent's operational mode.
// 19. adjustAdaptiveFeeRate(uint256 _newForgingFee, uint256 _newAttestationFee): DAO-governed fee adjustment.
// 20. migrateAgentToNewProtocol(uint256 _agentId, uint256 _newProtocolId): Migrates an agent to a new activated protocol.
// 21. burnDefunctAgent(uint256 _agentId): Permanently removes an agent NFT.
// 22. grantExperiencePoints(uint256 _agentId, uint256 _points): Awards XP to an agent, potentially triggering level-ups.
// 23. setAIOracle(address _newOracle): Sets or updates the trusted AI Oracle contract address.
// ============================================================================


// --- Interfaces ---

interface IAIOracle {
    function requestAttestation(bytes32 _requestHash) external returns (uint256 requestId);
    function submitAttestation(uint256 _requestId, bytes memory _data, bytes memory _signature) external; // Simplified for this contract
}

// Interface for a generic "Processor" that Agents might interact with
interface IAgentProcessor {
    function process(uint256 _agentId, bytes memory _inputData) external returns (bytes memory _outputData);
}

// --- Custom Errors ---
error Unauthorized();
error AgentNotFound();
error TaskNotFound();
error TaskNotAssignedToAgent();
error TaskNotCompleted();
error TaskAlreadyVerified();
error TaskNotPendingVerification();
error NotEnoughFunds();
error ProtocolNotFound();
error ProtocolNotActive();
error ProtocolProposalNotReadyForActivation();
error AgentEnergyInsufficient();
error InvalidAgentInteractionMode();
error AgentAlreadyExists();
error InvalidSignature(); // For AI Oracle attestations
error InsufficientExperienceForLevelUp();
error ForgingFeeNotMet();
error AttestationFeeNotMet();
error AgentAlreadyRetired();
error TransferNotAllowed();
error DelegationInvalid();
error NoActiveProposal();
error ProposalAlreadyVoted();


contract GenesisForgeAGADA {

    // --- State Variables (Minimal ERC721-like implementation) ---
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Enums ---
    enum AgentStatus { Active, Paused, Retired }
    enum InteractionMode { Autonomous, Guided, Passive } // How agent behaves / can be controlled
    enum ProposalStatus { Pending, Active, Passed, Failed }
    enum TaskStatus { Pending, InProgress, Completed, Verified, Failed }

    // --- Structs ---
    struct Agent {
        uint256 id;
        address owner;
        string name;
        string currentFormURI; // IPFS URI for visual representation
        uint256 protocolId;   // Link to the protocol it's running on
        uint256 experiencePoints;
        uint256 level;
        AgentStatus status;
        InteractionMode interactionMode;
        uint256 energy;
        uint256 maxEnergyCapacity;
        uint256 energyCostPerAction;
        string directive; // A high-level, AI-interpretable goal
        mapping(bytes4 => bool) delegatedPermissions; // Selector -> canDelegate for `msg.sender` for this agent
        mapping(address => mapping(bytes4 => bool)) delegatedTo; // delegatee -> selector -> canDelegate
        uint256 lastEvolutionRequestId; // Link to an AI oracle request for evolution
        uint256 lastReportRequestId;    // Link to an AI oracle request for intelligence report
    }

    struct Task {
        uint256 id;
        uint256 agentId;
        address proposer; // Who deployed the task
        address targetContract; // Contract to interact with
        bytes callData;         // Data for the function call
        uint256 rewardAmount;
        TaskStatus status;
        bytes32 verificationHash; // Hash of data to be verified by oracle
        uint256 verificationRequestId; // Link to an AI oracle request for verification
        uint256 completionTimestamp;
    }

    struct AgentProtocol {
        uint256 id;
        string protocolURI; // IPFS URI for protocol specifications (e.g., AI model config)
        bytes32 protocolHash; // Hash of the protocol content for integrity check
        bool isActive;
        address proposer;
    }

    struct ProtocolProposal {
        uint256 id;
        uint256 protocolId; // The protocol being proposed
        uint256 creationTime;
        uint256 expirationTime;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
    }

    // --- Mappings & Arrays ---
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => AgentProtocol) public protocols;
    mapping(uint256 => ProtocolProposal) public protocolProposals;
    mapping(address => uint256[]) public agentIdsByOwner; // For efficient lookup

    uint256 public totalAgents;
    uint256 public totalTasks;
    uint256 public totalProtocols;
    uint256 public totalProtocolProposals;

    address public immutable _contractOwner; // For core administrative tasks
    address public AI_ORACLE_ADDRESS;
    address public PAYMENT_TOKEN_ADDRESS; // ERC20 token for fees/refuels
    address public DAO_TREASURY_ADDRESS; // Where fees go

    uint256 public forgingFee = 0.01 ether; // Default fee to forge an agent
    uint256 public aiAttestationFee = 0.005 ether; // Fee for AI oracle services
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Voting duration for protocols
    uint256 public constant BASE_XP_FOR_LEVEL_UP = 100; // Base XP required for level 1 -> 2

    // Registered external processors
    mapping(address => bytes32) public registeredProcessors;

    // --- Events ---
    event AgentForged(uint256 indexed agentId, address indexed owner, string name, uint256 protocolId);
    event AgentDirectiveSet(uint256 indexed agentId, string directive);
    event EvolutionJudgmentRequested(uint256 indexed agentId, uint256 indexed requestId, bytes32 challengeHash);
    event AgentEvolved(uint256 indexed agentId, uint256 newLevel, string newFormURI);
    event TaskDeployed(uint256 indexed taskId, uint256 indexed agentId, address indexed proposer, uint256 rewardAmount);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed agentId, bytes proofOfExecution);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bool success);
    event AgentRewardClaimed(uint256 indexed taskId, uint256 indexed agentId, address indexed claimant, uint256 amount);
    event PermissionDelegated(uint256 indexed agentId, address indexed delegatee, bytes4 selector, bool canDelegate);
    event ProtocolProposed(uint256 indexed proposalId, uint256 indexed protocolId, string protocolURI);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProtocolActivated(uint256 indexed protocolId, uint256 indexed proposalId);
    event IntelligenceReportRequested(uint256 indexed agentId, uint256 indexed requestId, bytes32 queryHash);
    event IntelligenceReportReceived(uint256 indexed agentId, string reportURI);
    event AgentEnergyConfigured(uint256 indexed agentId, uint256 energyCost, uint256 maxCapacity);
    event AgentEnergyRefueled(uint256 indexed agentId, uint256 amount);
    event AgentProcessorRegistered(address indexed processorAddress, bytes32 processorTypeHash);
    event AgentInteractionModeSet(uint256 indexed agentId, InteractionMode mode);
    event FeesAdjusted(uint256 newForgingFee, uint256 newAttestationFee);
    event AgentMigrated(uint256 indexed agentId, uint256 oldProtocolId, uint256 newProtocolId);
    event AgentBurned(uint256 indexed agentId);
    event ExperienceGranted(uint256 indexed agentId, uint256 amount, uint256 newLevel);
    event AIOracleAddressSet(address indexed oldOracle, address indexed newOracle);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _contractOwner) revert Unauthorized();
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        if (agents[_agentId].owner != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != AI_ORACLE_ADDRESS) revert Unauthorized();
        _;
    }

    modifier onlyProtocolProposer(uint256 _proposalId) {
        if (protocolProposals[_proposalId].proposer != msg.sender) revert Unauthorized();
        _;
    }

    // Checks if the sender has direct ownership or delegated permission for a specific selector
    modifier canControlAgent(uint256 _agentId, bytes4 _selector) {
        Agent storage agent = agents[_agentId];
        if (agent.owner != msg.sender && !agent.delegatedTo[msg.sender][_selector]) revert Unauthorized();
        _;
    }

    // --- Constructor ---
    constructor(address _aiOracle, address _paymentToken, address _daoTreasury) {
        _contractOwner = msg.sender;
        AI_ORACLE_ADDRESS = _aiOracle;
        PAYMENT_TOKEN_ADDRESS = _paymentToken;
        DAO_TREASURY_ADDRESS = _daoTreasury;
        _nextTokenId = 1; // Agent IDs start from 1
    }

    // --- DAO & System Management Functions ---

    /**
     * @notice Allows the contract owner to set the AI Oracle address.
     * @param _newOracle The address of the new AI Oracle contract.
     */
    function setAIOracle(address _newOracle) external onlyOwner {
        address oldOracle = AI_ORACLE_ADDRESS;
        AI_ORACLE_ADDRESS = _newOracle;
        emit AIOracleAddressSet(oldOracle, _newOracle);
    }

    /**
     * @notice Proposes a new Agent Protocol through DAO governance.
     * @dev Anyone can propose a protocol, but it needs community votes to be activated.
     * @param _protocolURI IPFS or similar URI pointing to the full protocol specifications.
     * @param _protocolHash Hash of the protocol content to ensure integrity.
     */
    function proposeAgentProtocol(string memory _protocolURI, bytes32 _protocolHash) external {
        totalProtocols++;
        protocols[totalProtocols] = AgentProtocol({
            id: totalProtocols,
            protocolURI: _protocolURI,
            protocolHash: _protocolHash,
            isActive: false,
            proposer: msg.sender
        });

        totalProtocolProposals++;
        protocolProposals[totalProtocolProposals] = ProtocolProposal({
            id: totalProtocolProposals,
            protocolId: totalProtocols,
            creationTime: block.timestamp,
            expirationTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            status: ProposalStatus.Active,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool) // Initialize empty map
        });
        emit ProtocolProposed(totalProtocolProposals, totalProtocols, _protocolURI);
    }

    /**
     * @notice Allows a user to vote on an active protocol proposal.
     * @param _proposalId The ID of the protocol proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProtocolProposal(uint256 _proposalId, bool _support) external {
        ProtocolProposal storage proposal = protocolProposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) revert NoActiveProposal();
        if (proposal.expirationTime < block.timestamp) {
            // Automatically close the proposal if expired
            if (proposal.votesFor > proposal.votesAgainst) {
                proposal.status = ProposalStatus.Passed;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
            revert NoActiveProposal(); // Revert after updating status, as it's no longer active
        }
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Activates a protocol if its associated proposal has passed and the voting period is over.
     * @param _proposalId The ID of the protocol proposal to activate.
     */
    function activateProtocol(uint256 _proposalId) external {
        ProtocolProposal storage proposal = protocolProposals[_proposalId];
        if (proposal.status == ProposalStatus.Pending && proposal.expirationTime >= block.timestamp) revert ProposalProposalNotReadyForActivation();
        if (proposal.status == ProposalStatus.Passed) revert ProtocolProposalNotReadyForActivation(); // Already passed
        if (proposal.status == ProposalStatus.Failed) revert ProtocolProposalNotReadyForActivation(); // Already failed

        // Check if voting period is over
        if (block.timestamp < proposal.expirationTime) revert ProtocolProposalNotReadyForActivation();

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Passed;
            protocols[proposal.protocolId].isActive = true;
            emit ProtocolActivated(proposal.protocolId, _proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            revert ProtocolProposalNotReadyForActivation(); // Failed to activate
        }
    }

    /**
     * @notice Adjusts the fees for forging new agents and AI oracle attestations.
     * @dev This function is typically called through a DAO proposal and vote, not directly by owner.
     * @param _newForgingFee The new fee (in PAYMENT_TOKEN) for forging an agent.
     * @param _newAttestationFee The new fee (in PAYMENT_TOKEN) for AI oracle attestations.
     */
    function adjustAdaptiveFeeRate(uint256 _newForgingFee, uint256 _newAttestationFee) external {
        // In a full DAO, this would be guarded by a 'onlyDAOExecutor' modifier
        // For this example, we'll allow `_contractOwner` to simulate DAO execution.
        if (msg.sender != _contractOwner) revert Unauthorized(); // Simplified DAO execution

        forgingFee = _newForgingFee;
        aiAttestationFee = _newAttestationFee;
        emit FeesAdjusted(_newForgingFee, _newAttestationFee);
    }

    // --- Agent Management Functions ---

    /**
     * @notice Mints a new Agent NFT. Requires a forging fee.
     * @param _agentName The desired name for the new agent.
     * @param _initialTraitSeed A seed value used to influence initial agent traits (e.g., via VRF on oracle).
     */
    function forgeAgent(string memory _agentName, uint256 _initialTraitSeed) external payable {
        if (msg.value < forgingFee) revert ForgingFeeNotMet();

        // Send forging fee to DAO treasury
        (bool success, ) = DAO_TREASURY_ADDRESS.call{value: forgingFee}("");
        if (!success) revert NotEnoughFunds(); // Should not happen if msg.value >= fee

        uint256 agentId = _nextTokenId++;
        Agent storage newAgent = agents[agentId];
        newAgent.id = agentId;
        newAgent.owner = msg.sender;
        newAgent.name = _agentName;
        newAgent.currentFormURI = "ipfs://initial-agent-form"; // Default initial URI
        newAgent.protocolId = 0; // Starts without an active protocol, owner can migrate later
        newAgent.experiencePoints = 0;
        newAgent.level = 1;
        newAgent.status = AgentStatus.Active;
        newAgent.interactionMode = InteractionMode.Passive;
        newAgent.energy = newAgent.maxEnergyCapacity; // Starts with full energy
        newAgent.maxEnergyCapacity = 100; // Default
        newAgent.energyCostPerAction = 10; // Default
        newAgent.directive = "Explore and Learn"; // Default directive

        _owners[agentId] = msg.sender;
        _balances[msg.sender]++;
        agentIdsByOwner[msg.sender].push(agentId);
        totalAgents++;

        emit AgentForged(agentId, msg.sender, _agentName, 0);
    }

    /**
     * @notice Sets a high-level directive or goal for an agent. This is interpreted by off-chain AI.
     * @param _agentId The ID of the agent.
     * @param _directive The new directive string.
     */
    function setAgentDirective(uint256 _agentId, string memory _directive) external canControlAgent(_agentId, this.setAgentDirective.selector) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        agent.directive = _directive;
        emit AgentDirectiveSet(_agentId, _directive);
    }

    /**
     * @notice Requests an AI oracle to judge an agent's readiness for evolution based on a challenge.
     * @dev Requires an AI attestation fee. The oracle will eventually call `attestEvolution`.
     * @param _agentId The ID of the agent.
     * @param _challengeHash A hash representing the challenge or context for evolution judgment.
     */
    function requestEvolutionJudgment(uint256 _agentId, bytes32 _challengeHash) external payable canControlAgent(_agentId, this.requestEvolutionJudgment.selector) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (msg.value < aiAttestationFee) revert AttestationFeeNotMet();

        // Transfer fee to DAO treasury
        (bool success, ) = DAO_TREASURY_ADDRESS.call{value: aiAttestationFee}("");
        if (!success) revert NotEnoughFunds();

        // Simplified oracle interaction: just store request ID, actual request would be via IAIOracle.requestAttestation
        // For a real system, you'd use Chainlink or similar oracles.
        uint256 requestId = block.timestamp; // Placeholder for actual oracle request ID
        agent.lastEvolutionRequestId = requestId;

        // IAIOracle(AI_ORACLE_ADDRESS).requestAttestation(abi.encodePacked("EvolutionJudgment", _agentId, _challengeHash));
        emit EvolutionJudgmentRequested(_agentId, requestId, _challengeHash);
    }

    /**
     * @notice Callback function for the AI oracle to attest an agent's evolution.
     * @dev Only callable by the trusted AI Oracle address.
     * @param _agentId The ID of the agent that evolved.
     * @param _newLevel The new level of the agent.
     * @param _newFormURI The new IPFS URI for the agent's evolved form.
     * @param _oracleSignature A cryptographic signature from the oracle for verification.
     */
    function attestEvolution(uint256 _agentId, uint256 _newLevel, string memory _newFormURI, bytes memory _oracleSignature) external onlyAIOracle {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        // Here, a real oracle implementation would verify _oracleSignature against known oracle public key
        // For this example, we trust onlyAIOracle modifier.

        if (_newLevel <= agent.level) revert InsufficientExperienceForLevelUp();

        agent.level = _newLevel;
        agent.currentFormURI = _newFormURI;
        // Potentially unlock new capabilities based on level here
        emit AgentEvolved(_agentId, _newLevel, _newFormURI);
    }

    /**
     * @notice Allows an agent to be migrated to a new, active protocol.
     * @dev The new protocol must have been approved and activated by DAO governance.
     * @param _agentId The ID of the agent to migrate.
     * @param _newProtocolId The ID of the new protocol.
     */
    function migrateAgentToNewProtocol(uint256 _agentId, uint256 _newProtocolId) external canControlAgent(_agentId, this.migrateAgentToNewProtocol.selector) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (!protocols[_newProtocolId].isActive) revert ProtocolNotActive();

        uint256 oldProtocolId = agent.protocolId;
        agent.protocolId = _newProtocolId;
        emit AgentMigrated(_agentId, oldProtocolId, _newProtocolId);
    }

    /**
     * @notice Awards experience points to an agent. Can trigger level-ups.
     * @dev Could be called by a trusted verifier or upon successful task completion.
     * @param _agentId The ID of the agent.
     * @param _points The amount of experience points to grant.
     */
    function grantExperiencePoints(uint256 _agentId, uint256 _points) external {
        // This could be restricted to `onlyVerifier` or `onlyAIOracle` in a real setup.
        // For this example, we'll allow `_contractOwner` to simulate this.
        if (msg.sender != _contractOwner && msg.sender != AI_ORACLE_ADDRESS) revert Unauthorized();

        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        agent.experiencePoints += _points;

        // Simple level-up logic: XP for next level scales with current level
        uint256 xpForNextLevel = BASE_XP_FOR_LEVEL_UP * (agent.level * agent.level);
        while (agent.experiencePoints >= xpForNextLevel) {
            agent.level++;
            // Optionally request evolution judgment here
            xpForNextLevel = BASE_XP_FOR_LEVEL_UP * (agent.level * agent.level); // Update for next iteration
        }
        emit ExperienceGranted(_agentId, _points, agent.level);
    }

    /**
     * @notice Configures the energy cost per action and max energy capacity for an agent.
     * @param _agentId The ID of the agent.
     * @param _energyCostPerAction The energy consumed for each action.
     * @param _maxEnergyCapacity The maximum energy the agent can hold.
     */
    function setAgentEnergyConfig(uint252 _agentId, uint256 _energyCostPerAction, uint256 _maxEnergyCapacity) external canControlAgent(_agentId, this.setAgentEnergyConfig.selector) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        agent.energyCostPerAction = _energyCostPerAction;
        agent.maxEnergyCapacity = _maxEnergyCapacity;
        // Cap current energy if new max is lower
        if (agent.energy > _maxEnergyCapacity) {
            agent.energy = _maxEnergyCapacity;
        }
        emit AgentEnergyConfigured(_agentId, _energyCostPerAction, _maxEnergyCapacity);
    }

    /**
     * @notice Replenishes an agent's energy by converting PAYMENT_TOKEN.
     * @param _agentId The ID of the agent.
     * @param _amount The amount of energy to add (converts from PAYMENT_TOKEN).
     */
    function refuelAgentEnergy(uint256 _agentId, uint256 _amount) external payable canControlAgent(_agentId, this.refuelAgentEnergy.selector) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (_amount == 0) return;

        // In a real scenario, this would involve PAYMENT_TOKEN_ADDRESS ERC20 transfer,
        // or msg.value if using native ETH.
        // For simplicity, we assume msg.value is sent and used.
        if (msg.value < _amount) revert NotEnoughFunds();

        // Send payment to DAO treasury
        (bool success, ) = DAO_TREASURY_ADDRESS.call{value: _amount}("");
        if (!success) revert NotEnoughFunds();

        agent.energy = agent.energy + _amount > agent.maxEnergyCapacity ? agent.maxEnergyCapacity : agent.energy + _amount;
        emit AgentEnergyRefueled(_agentId, _amount);
    }

    /**
     * @notice Sets the interaction mode for an agent (Autonomous, Guided, Passive).
     * @param _agentId The ID of the agent.
     * @param _mode The new InteractionMode.
     */
    function setAgentInteractionMode(uint256 _agentId, InteractionMode _mode) external canControlAgent(_agentId, this.setAgentInteractionMode.selector) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (uint8(_mode) > uint8(InteractionMode.Passive)) revert InvalidAgentInteractionMode();
        agent.interactionMode = _mode;
        emit AgentInteractionModeSet(_agentId, _mode);
    }

    /**
     * @notice Permanently removes (burns) an agent NFT. This action is irreversible.
     * @dev Only the agent owner can burn their agent.
     * @param _agentId The ID of the agent to burn.
     */
    function burnDefunctAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();

        // Perform ERC721-like burning steps
        address agentOwner = agent.owner;
        _balances[agentOwner]--;
        delete _owners[_agentId];
        delete _tokenApprovals[_agentId];

        // Mark as retired
        agent.status = AgentStatus.Retired;
        agent.owner = address(0); // Clear ownership

        // Remove from owner's agent list (inefficient for large arrays, but simple for example)
        uint256[] storage ownerAgents = agentIdsByOwner[agentOwner];
        for (uint256 i = 0; i < ownerAgents.length; i++) {
            if (ownerAgents[i] == _agentId) {
                ownerAgents[i] = ownerAgents[ownerAgents.length - 1];
                ownerAgents.pop();
                break;
            }
        }
        totalAgents--;
        emit AgentBurned(_agentId);
    }

    // --- Task & Reward Functions ---

    /**
     * @notice Deploys a new on-chain task for a specific agent to perform.
     * @param _agentId The ID of the agent to assign the task to.
     * @param _targetContract The address of the contract the agent needs to interact with.
     * @param _callData The encoded function call data for the target contract.
     * @param _rewardAmount The reward (in native token) for completing this task.
     */
    function deployAgentTask(uint256 _agentId, address _targetContract, bytes memory _callData, uint256 _rewardAmount) external payable {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (msg.value < _rewardAmount) revert NotEnoughFunds();

        totalTasks++;
        tasks[totalTasks] = Task({
            id: totalTasks,
            agentId: _agentId,
            proposer: msg.sender,
            targetContract: _targetContract,
            callData: _callData,
            rewardAmount: _rewardAmount,
            status: TaskStatus.Pending,
            verificationHash: bytes32(0), // Set when verification is requested
            verificationRequestId: 0,
            completionTimestamp: 0
        });

        // Funds for reward are held in this contract
        emit TaskDeployed(totalTasks, _agentId, msg.sender, _rewardAmount);
    }

    /**
     * @notice Allows an agent owner to complete a delegated on-chain task.
     * @dev The owner acts as a relayer, paying gas for the actual execution on `_targetContract`.
     * @param _agentId The ID of the agent that performed the task.
     * @param _taskId The ID of the task.
     * @param _proofOfExecution Optional, a proof of execution (e.g., tx hash or receipt root).
     */
    function completeDelegatedTask(uint256 _agentId, uint256 _taskId, bytes memory _proofOfExecution) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        Task storage task = tasks[_taskId];

        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (task.agentId != _agentId) revert TaskNotAssignedToAgent();
        if (task.status != TaskStatus.Pending) revert TaskNotPendingVerification();
        if (agent.energy < agent.energyCostPerAction) revert AgentEnergyInsufficient();

        // In a real system, `_proofOfExecution` might be used for direct on-chain verification
        // or sent to an AI oracle for validation.
        // For this example, we proceed directly to pending verification.

        agent.energy -= agent.energyCostPerAction;
        task.status = TaskStatus.InProgress; // Changed from pending to in-progress when `completeDelegatedTask` is called
        task.completionTimestamp = block.timestamp;
        task.verificationHash = keccak256(abi.encodePacked(_agentId, _taskId, _proofOfExecution)); // Data to be verified

        // Request AI oracle to verify result (simulated)
        // IAIOracle(AI_ORACLE_ADDRESS).requestAttestation(task.verificationHash);
        task.verificationRequestId = block.timestamp; // Placeholder request ID

        emit TaskCompleted(_taskId, _agentId, _proofOfExecution);
    }

    /**
     * @notice Callback from the AI Oracle or trusted verifier to attest the result of a task.
     * @dev Only callable by the trusted AI Oracle address.
     * @param _taskId The ID of the task being verified.
     * @param _success True if the task was successfully completed, false otherwise.
     * @param _verificationData Additional data from the oracle.
     * @param _oracleSignature A cryptographic signature from the oracle.
     */
    function verifyTaskResult(uint256 _taskId, bool _success, bytes memory _verificationData, bytes memory _oracleSignature) external onlyAIOracle {
        Task storage task = tasks[_taskId];
        if (task.status == TaskStatus.Verified || task.status == TaskStatus.Failed) revert TaskAlreadyVerified();
        if (task.status != TaskStatus.InProgress) revert TaskNotPendingVerification();

        // Verify _oracleSignature here in a real scenario
        // For example, using ecrecover with a known oracle public key.

        if (_success) {
            task.status = TaskStatus.Verified;
            // Grant XP to the agent upon successful verification
            grantExperiencePoints(task.agentId, task.rewardAmount / 1 ether); // 1 ETH reward = 1 XP (example)
        } else {
            task.status = TaskStatus.Failed;
            // Optionally refund the proposer
            (bool success, ) = payable(task.proposer).call{value: task.rewardAmount}("");
            if (!success) {
                // Handle refund failure, e.g., log it or put funds in a rescue queue
            }
        }
        emit TaskVerified(_taskId, task.agentId, _success);
    }

    /**
     * @notice Allows the agent owner to claim the reward for a successfully verified task.
     * @param _agentId The ID of the agent.
     * @param _taskId The ID of the task.
     */
    function claimAgentReward(uint256 _agentId, uint256 _taskId) external onlyAgentOwner(_agentId) {
        Task storage task = tasks[_taskId];
        if (task.agentId != _agentId) revert TaskNotAssignedToAgent();
        if (task.status != TaskStatus.Verified) revert TaskNotCompleted();

        task.status = TaskStatus.Failed; // Mark as claimed/no longer available

        (bool success, ) = payable(msg.sender).call{value: task.rewardAmount}("");
        if (!success) revert NotEnoughFunds(); // Should not happen if funds were held and transfer is clean

        emit AgentRewardClaimed(_taskId, _agentId, msg.sender, task.rewardAmount);
    }

    // --- Delegation & Permissions ---

    /**
     * @notice Allows an agent owner to delegate specific function call permissions for their agent to another address.
     * @param _agentId The ID of the agent.
     * @param _delegatee The address to whom permissions are being delegated.
     * @param _selector The function selector (bytes4) representing the permission.
     * @param _canDelegate True to grant, false to revoke.
     */
    function delegateAgentPermission(uint256 _agentId, address _delegatee, bytes4 _selector, bool _canDelegate) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (_delegatee == address(0)) revert DelegationInvalid();

        agent.delegatedTo[_delegatee][_selector] = _canDelegate;
        emit PermissionDelegated(_agentId, _delegatee, _selector, _canDelegate);
    }

    // --- AI Oracle & Reporting Functions ---

    /**
     * @notice Requests an AI oracle to generate an intelligence report on an agent.
     * @dev Requires an AI attestation fee. The oracle will eventually call `receiveIntelligenceReport`.
     * @param _agentId The ID of the agent.
     * @param _queryHash A hash representing the specific query or context for the report.
     */
    function requestAgentIntelligenceReport(uint256 _agentId, bytes32 _queryHash) external payable {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        if (msg.value < aiAttestationFee) revert AttestationFeeNotMet();

        (bool success, ) = DAO_TREASURY_ADDRESS.call{value: aiAttestationFee}("");
        if (!success) revert NotEnoughFunds();

        // Simplified oracle interaction
        uint256 requestId = block.timestamp; // Placeholder
        agent.lastReportRequestId = requestId;

        // IAIOracle(AI_ORACLE_ADDRESS).requestAttestation(abi.encodePacked("IntelligenceReport", _agentId, _queryHash));
        emit IntelligenceReportRequested(_agentId, requestId, _queryHash);
    }

    /**
     * @notice Callback from the AI oracle to deliver an intelligence report URI.
     * @dev Only callable by the trusted AI Oracle address.
     * @param _agentId The ID of the agent the report is about.
     * @param _reportURI IPFS or similar URI pointing to the intelligence report.
     * @param _oracleSignature A cryptographic signature from the oracle.
     */
    function receiveIntelligenceReport(uint256 _agentId, string memory _reportURI, bytes memory _oracleSignature) external onlyAIOracle {
        Agent storage agent = agents[_agentId];
        if (agent.status == AgentStatus.Retired) revert AgentAlreadyRetired();
        // Verify _oracleSignature in a real scenario

        // Store the report URI or trigger further actions based on the report.
        // For this example, we just emit an event.
        emit IntelligenceReportReceived(_agentId, _reportURI);
    }

    // --- External Processor Management ---

    /**
     * @notice Registers an external specialized processor that agents can interface with.
     * @dev This allows the ecosystem to integrate various off-chain computation services.
     * @param _processorAddress The address of the IAgentProcessor contract.
     * @param _processorTypeHash A hash identifying the type or function of the processor.
     */
    function registerAgentProcessor(address _processorAddress, bytes32 _processorTypeHash) external onlyOwner {
        registeredProcessors[_processorAddress] = _processorTypeHash;
        emit AgentProcessorRegistered(_processorAddress, _processorTypeHash);
    }

    // --- View Functions (ERC721-like & Custom) ---

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 agentId) public view returns (address) {
        address owner = _owners[agentId];
        if (owner == address(0)) revert AgentNotFound();
        return owner;
    }

    function getAgentDetails(uint256 _agentId)
        public view
        returns (
            uint256 id,
            address owner,
            string memory name,
            string memory currentFormURI,
            uint256 protocolId,
            uint256 experiencePoints,
            uint256 level,
            AgentStatus status,
            InteractionMode interactionMode,
            uint256 energy,
            uint256 maxEnergyCapacity,
            uint256 energyCostPerAction,
            string memory directive
        )
    {
        Agent storage agent = agents[_agentId];
        if (agent.owner == address(0) && agent.status != AgentStatus.Retired) revert AgentNotFound(); // Retired agents exist, but owner is 0x0

        return (
            agent.id,
            agent.owner,
            agent.name,
            agent.currentFormURI,
            agent.protocolId,
            agent.experiencePoints,
            agent.level,
            agent.status,
            agent.interactionMode,
            agent.energy,
            agent.maxEnergyCapacity,
            agent.energyCostPerAction,
            agent.directive
        );
    }

    function getTaskDetails(uint256 _taskId)
        public view
        returns (
            uint256 id,
            uint256 agentId,
            address proposer,
            address targetContract,
            bytes memory callData,
            uint256 rewardAmount,
            TaskStatus status,
            uint256 completionTimestamp
        )
    {
        Task storage task = tasks[_taskId];
        if (task.agentId == 0) revert TaskNotFound(); // TaskId 0 is invalid
        return (
            task.id,
            task.agentId,
            task.proposer,
            task.targetContract,
            task.callData,
            task.rewardAmount,
            task.status,
            task.completionTimestamp
        );
    }

    function getProtocolDetails(uint256 _protocolId)
        public view
        returns (
            uint256 id,
            string memory protocolURI,
            bytes32 protocolHash,
            bool isActive,
            address proposer
        )
    {
        AgentProtocol storage protocol = protocols[_protocolId];
        if (protocol.id == 0) revert ProtocolNotFound();
        return (protocol.id, protocol.protocolURI, protocol.protocolHash, protocol.isActive, protocol.proposer);
    }

    function getProtocolProposalDetails(uint256 _proposalId)
        public view
        returns (
            uint256 id,
            uint256 protocolId,
            uint256 creationTime,
            uint256 expirationTime,
            ProposalStatus status,
            uint256 votesFor,
            uint256 votesAgainst
        )
    {
        ProtocolProposal storage proposal = protocolProposals[_proposalId];
        if (proposal.id == 0) revert NoActiveProposal(); // Using this error for "not found"
        return (
            proposal.id,
            proposal.protocolId,
            proposal.creationTime,
            proposal.expirationTime,
            proposal.status,
            proposal.votesFor,
            proposal.votesAgainst
        );
    }

    // Simplified ERC721 `transferFrom` for ownership transfers
    function transferFrom(address from, address to, uint256 agentId) public {
        if (!(_isApprovedOrOwner(msg.sender, agentId) || _operatorApprovals[from][msg.sender])) revert TransferNotAllowed();
        if (_owners[agentId] != from) revert Unauthorized(); // Not the current owner
        if (agents[agentId].status == AgentStatus.Retired) revert AgentAlreadyRetired();

        _transfer(from, to, agentId);
        _approve(address(0), agentId); // Clear any previous approval
    }

    // --- Internal/Private Helper Functions (Minimal ERC721-like implementation) ---

    function _transfer(address from, address to, uint256 agentId) internal {
        _balances[from]--;
        _balances[to]++;
        _owners[agentId] = to;

        // Remove from 'from' agent list and add to 'to' agent list
        _removeAgentIdFromOwner(from, agentId);
        agentIdsByOwner[to].push(agentId);

        // Optionally emit Transfer event if strictly following ERC721
        // emit Transfer(from, to, agentId);
    }

    function _approve(address to, uint256 agentId) internal {
        _tokenApprovals[agentId] = to;
        // Optionally emit Approval event
        // emit Approval(ownerOf(agentId), to, agentId);
    }

    function _isApprovedOrOwner(address spender, uint256 agentId) internal view returns (bool) {
        address owner = _owners[agentId];
        return (spender == owner || spender == _tokenApprovals[agentId] || _operatorApprovals[owner][spender]);
    }

    function _removeAgentIdFromOwner(address owner, uint256 agentId) private {
        uint256[] storage ownerAgents = agentIdsByOwner[owner];
        for (uint256 i = 0; i < ownerAgents.length; i++) {
            if (ownerAgents[i] == agentId) {
                ownerAgents[i] = ownerAgents[ownerAgents.length - 1]; // Replace with last element
                ownerAgents.pop(); // Remove last element
                break;
            }
        }
    }

    // Fallback function to receive Ether for tasks or fees
    receive() external payable {}
}
```