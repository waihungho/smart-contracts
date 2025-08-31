This smart contract, `AetherMindProtocol`, introduces a novel concept: **a Decentralized Autonomous Intent Execution Network powered by AI-Augmented Agents.**

Users can deploy and manage intelligent "AetherAgents" which are programmable on-chain entities. These agents execute predefined "Intents" (complex user goals) based on external data feeds (via registered oracles). The protocol features a robust reputation system for agents, dynamic service fees, and a transparent challenge mechanism, creating a self-regulating ecosystem for delegated task automation.

This design aims to be advanced, creative, and distinct from common open-source patterns by integrating:
1.  **On-chain Autonomous Agents:** Agents are concrete entities on-chain with state and capabilities.
2.  **Intent-Based Execution:** Users define high-level goals, and agents execute the steps, rather than direct transaction signing.
3.  **Dynamic Reputation System:** Agent reputation is tied directly to performance, feedback, and a dispute resolution process.
4.  **Programmable Delegation:** Users explicitly delegate capabilities and data access to agents.
5.  **Modular AI Integration:** Agent logic (AI) resides off-chain (e.g., IPFS) but is managed and triggered by on-chain state.

---

### **AetherMindProtocol: Outline and Function Summary**

**I. Agent Lifecycle & Management**
1.  `registerAetherAgent(string calldata _name, string calldata _agentURI)`: Allows a new agent contract (msg.sender) to register itself, linking to its off-chain logic/metadata.
2.  `updateAgentURI(address _agentAddress, string calldata _newAgentURI)`: Enables an agent owner to update the IPFS/Arweave URI pointing to their agent's updated logic or metadata.
3.  `setAgentStatus(address _agentAddress, bool _isActive)`: Activates or deactivates an agent, controlling its ability to execute intents.
4.  `transferAgentOwnership(address _agentAddress, address _newOwner)`: Transfers the administrative control of an agent to a new address.
5.  `getAgentDetails(address _agentAddress)`: Retrieves comprehensive data for a specified AetherAgent.

**II. Intent Definition & Delegation**
6.  `defineIntent(string calldata _intentDataURI, bool _requiresApproval)`: Creates a new user intent, linking to its off-chain specification and indicating if owner approval is needed for execution.
7.  `delegateIntentToAgent(uint256 _intentId, address _agentAddress)`: Assigns a defined intent to a specific agent, authorizing it for potential execution.
8.  `revokeIntentDelegation(uint256 _intentId)`: Removes an agent's authorization to execute a particular intent.
9.  `proposeAgentExecution(uint256 _intentId, bytes32 _executionHash)`: (Agent Callable) An agent proposes an action for an intent requiring explicit owner approval, providing a hash of the proposed transaction/logic.
10. `approveProposedExecution(uint256 _intentId)`: (Intent Owner Callable) The intent owner approves a previously proposed agent action, allowing the agent to proceed.

**III. Agent Execution & Callback**
11. `executeIntentByAgent(uint256 _intentId, bytes calldata _executionProof)`: (Agent Callable) An agent calls this to confirm successful execution of a delegated intent, potentially including cryptographic proof.
12. `getIntentStatus(uint256 _intentId)`: Provides the current status of a specific user intent (e.g., Defined, Delegated, Executed).
13. `getAgentLastExecutionTime(address _agentAddress)`: Returns the timestamp of the last successful intent execution by a given agent.

**IV. Reputation & Challenge System**
14. `submitAgentFeedback(uint256 _intentId, bool _isPositive, string calldata _feedbackURI)`: Allows an intent owner to provide feedback (positive/negative) on an agent's performance after intent execution.
15. `initiateChallenge(uint256 _intentId, string calldata _reasonURI, int256 _reputationImpactProposal)`: Enables an intent owner to challenge an agent's execution, proposing a reputation adjustment.
16. `resolveChallenge(uint256 _challengeId, bool _isApproved, int256 _finalReputationImpact)`: (Protocol Admin/DAO Callable) Resolves a pending challenge, approving or rejecting it and applying the final reputation impact.
17. `getAgentReputation(address _agentAddress)`: Retrieves the current reputation score of a specified agent.

**V. Economic & Protocol Fees**
18. `setAgentServiceFee(address _agentAddress, uint256 _feeAmount)`: An agent owner sets the fee charged by their agent for successful intent executions.
19. `payForAgentService(uint256 _intentId)`: (Intent Owner Callable) The intent owner pays the agent's service fee upon successful completion of an intent.
20. `withdrawAgentEarnings(address _agentAddress)`: An agent owner can withdraw accumulated fees earned by their agent.

**VI. Oracle Integration**
21. `registerTrustedOracle(address _oracleAddress, string calldata _description)`: (Protocol Admin/DAO Callable) Registers a new trusted oracle contract for agents to potentially use.
22. `authorizeAgentOracleAccess(address _agentAddress, address _oracleAddress, bool _canAccess)`: An agent owner grants or revokes access for their agent to consume data from a specific registered oracle.
23. `checkAuthorizedOracle(address _agentAddress, address _oracleAddress)`: Checks if a given agent is authorized to access data from a particular oracle.

**VII. Protocol Governance & Utilities**
24. `setProtocolFeeRate(uint256 _newRate)`: (Protocol Admin/DAO Callable) Adjusts the percentage of agent service fees collected by the protocol.
25. `setMinimumAgentReputation(int256 _minReputation)`: (Protocol Admin/DAO Callable) Sets a minimum reputation threshold required for agents to perform certain critical actions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors for better debugging and gas efficiency
error NotAgentOwner(address caller, address agentAddress);
error NotIntentOwner(address caller, uint256 intentId);
error AgentNotFound(address agentAddress);
error IntentNotFound(uint256 intentId);
error InvalidIntentStatus(uint256 intentId, AetherMindProtocol.IntentStatus expectedStatus, AetherMindProtocol.IntentStatus currentStatus);
error AgentNotActive(address agentAddress);
error AgentNotDelegated(uint256 intentId, address agentAddress);
error AgentAlreadyDelegated(uint256 intentId);
error AgentNotAuthorized(address agentAddress, address oracleAddress);
error ChallengeNotFound(uint256 challengeId);
error OracleNotRegistered(address oracleAddress);
error InsufficientPayment(uint256 required, uint256 provided);
error NoPendingProposal(uint256 intentId);
error ReputationBelowMinimum(address agentAddress, int256 currentReputation, int256 minimumReputation);
error NoEarningsToWithdraw(address agentAddress);
error InvalidFeeRate(uint256 rate);

/**
 * @title AetherMindProtocol
 * @dev A Decentralized Autonomous Intent Execution Network for programmable, reputation-driven AetherAgents.
 * @notice This contract facilitates the registration and management of AetherAgents, the definition and delegation of user intents,
 *         a reputation and challenge system, an economic model with service fees, and integration with trusted oracles.
 *         Agents (smart contracts themselves) register with this protocol and execute intents on behalf of users.
 */
contract AetherMindProtocol is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum IntentStatus {
        Defined,        // Intent has been created by user
        Delegated,      // Intent is assigned to an agent
        Proposed,       // Agent has proposed an action (if requiresApproval=true)
        Executed,       // Intent has been successfully executed by the agent
        Challenged,     // Agent's execution is under dispute
        Resolved        // Challenge has been resolved
    }

    enum ChallengeStatus {
        Pending,        // Challenge is awaiting resolution
        Approved,       // Challenge was found valid, reputation impact applied
        Rejected        // Challenge was found invalid, no reputation impact
    }

    // --- Structs ---

    struct Agent {
        address agentAddress; // The actual contract address of the AetherAgent
        address owner;        // The human owner who deployed/manages this agent
        string name;          // User-defined name for the agent
        string agentURI;      // IPFS/Arweave URI for agent's advanced logic/metadata
        bool isActive;        // Whether the agent is currently active and can execute intents
        int256 reputationScore; // Reputation score, can be negative for poor performance
        uint256 serviceFee;   // Fee charged by the agent per successful intent execution (in wei)
        mapping(address => bool) authorizedOracles; // Mapping of oracle addresses this agent can use
        uint256 balance;      // Accumulated earnings from service fees
        uint256 lastExecutionTime; // Timestamp of the last successful execution
    }

    struct Intent {
        uint256 id;                 // Unique ID for the intent
        address owner;              // The user who defined this intent
        address delegatedAgent;     // The agent address delegated to execute this intent (0x0 if none)
        string intentDataURI;       // IPFS/Arweave URI for intent's logic/parameters
        IntentStatus status;        // Current status of the intent
        bool requiresApproval;      // If intent owner must approve agent's proposed action
        bytes32 proposedExecutionHash; // Hash of the action proposed by the agent (if requiresApproval)
        uint256 creationTime;       // Timestamp when intent was defined
        uint256 executionTime;      // Timestamp when intent was executed
        uint256 lastFeedbackTime;   // Timestamp of the last feedback/challenge
    }

    struct Oracle {
        address oracleAddress; // The actual oracle contract address
        string description;    // A brief description of the oracle feed
        bool isActive;         // Whether the oracle is currently active and trusted
    }

    struct Challenge {
        uint256 id;             // Unique ID for the challenge
        uint256 intentId;       // The intent that was challenged
        address challenger;     // The address initiating the challenge (intent owner)
        address agentAddress;   // The agent whose execution is challenged
        string reasonURI;       // IPFS/Arweave URI for detailed challenge reason/evidence
        ChallengeStatus status; // Current status of the challenge
        uint256 submissionTime; // Timestamp when challenge was submitted
        uint256 resolutionTime; // Timestamp when challenge was resolved
        int256 reputationImpact; // The reputation change applied upon resolution
    }

    // --- State Variables ---

    uint256 public nextIntentId = 1; // Counter for new intents
    uint256 public nextChallengeId = 1; // Counter for new challenges

    mapping(address => Agent) public agents;
    address[] public registeredAgentAddresses; // To retrieve all agent addresses (careful with large arrays)

    mapping(uint256 => Intent) public intents;
    mapping(uint256 => Challenge) public challenges;

    mapping(address => Oracle) public trustedOracles;
    address[] public registeredOracleAddresses; // To retrieve all oracle addresses

    uint256 public protocolFeeRate = 100; // 100 basis points = 1%
    uint256 public protocolBalance; // Funds collected by the protocol
    int256 public minimumAgentReputation = -1000; // Minimum reputation for critical actions

    // --- Events ---

    event AgentRegistered(address indexed agentAddress, address indexed owner, string name, string agentURI);
    event AgentURIUpdated(address indexed agentAddress, string newAgentURI);
    event AgentStatusChanged(address indexed agentAddress, bool isActive);
    event AgentOwnershipTransferred(address indexed agentAddress, address indexed oldOwner, address indexed newOwner);
    event AgentServiceFeeSet(address indexed agentAddress, uint256 feeAmount);
    event AgentEarningsWithdrawn(address indexed agentAddress, address indexed owner, uint256 amount);

    event IntentDefined(uint256 indexed intentId, address indexed owner, string intentDataURI, bool requiresApproval);
    event IntentDelegated(uint256 indexed intentId, address indexed owner, address indexed agentAddress);
    event IntentDelegationRevoked(uint256 indexed intentId, address indexed owner, address indexed agentAddress);
    event AgentExecutionProposed(uint256 indexed intentId, address indexed agentAddress, bytes32 executionHash);
    event ProposedExecutionApproved(uint256 indexed intentId, address indexed owner, address indexed agentAddress, bytes32 executionHash);
    event IntentExecuted(uint256 indexed intentId, address indexed agentAddress, uint256 executionTime);
    event AgentServicePaid(uint256 indexed intentId, address indexed payer, address indexed agentAddress, uint256 amount);

    event AgentFeedbackSubmitted(uint256 indexed intentId, address indexed agentAddress, bool isPositive);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed intentId, address indexed challenger, address indexed agentAddress);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed intentId, address indexed agentAddress, bool isApproved, int256 reputationImpact);
    event AgentReputationUpdated(address indexed agentAddress, int256 oldReputation, int256 newReputation);

    event OracleRegistered(address indexed oracleAddress, string description);
    event AgentOracleAccessChanged(address indexed agentAddress, address indexed oracleAddress, bool granted);

    event ProtocolFeeRateSet(uint256 oldRate, uint256 newRate);
    event MinimumAgentReputationSet(int256 oldMinReputation, int256 newMinReputation);

    // --- Modifiers ---

    modifier onlyAgentOwner(address _agentAddress) {
        if (msg.sender != agents[_agentAddress].owner) {
            revert NotAgentOwner(msg.sender, _agentAddress);
        }
        _;
    }

    modifier onlyIntentOwner(uint256 _intentId) {
        if (msg.sender != intents[_intentId].owner) {
            revert NotIntentOwner(msg.sender, _intentId);
        }
        _;
    }

    modifier onlyDelegatedAgent(uint256 _intentId) {
        if (intents[_intentId].delegatedAgent == address(0) || msg.sender != intents[_intentId].delegatedAgent) {
            revert AgentNotDelegated(_intentId, msg.sender);
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
        // Optional: Pre-register some initial trusted oracles or set initial parameters
    }

    // --- I. Agent Lifecycle & Management ---

    /**
     * @dev Allows an AetherAgent contract to register itself with the protocol.
     *      The `msg.sender` must be the actual agent contract address.
     * @param _name A human-readable name for the agent.
     * @param _agentURI IPFS/Arweave URI pointing to the agent's advanced logic or metadata.
     */
    function registerAetherAgent(
        string calldata _name,
        string calldata _agentURI
    ) external nonReentrant {
        if (agents[msg.sender].agentAddress != address(0)) {
            revert("AetherMindProtocol: Agent already registered");
        }
        
        agents[msg.sender] = Agent({
            agentAddress: msg.sender,
            owner: tx.origin, // The EOA that deployed or initiated the registration
            name: _name,
            agentURI: _agentURI,
            isActive: true,
            reputationScore: 0,
            serviceFee: 0,
            balance: 0,
            lastExecutionTime: 0
        });
        // This mapping is created implicitly when accessing authorizedOracles
        // agents[msg.sender].authorizedOracles is initialized with false for all addresses

        registeredAgentAddresses.push(msg.sender); // Add to list for iteration
        emit AgentRegistered(msg.sender, tx.origin, _name, _agentURI);
    }

    /**
     * @dev Allows an agent owner to update the IPFS/Arweave URI of their agent's logic.
     * @param _agentAddress The address of the agent to update.
     * @param _newAgentURI The new IPFS/Arweave URI.
     */
    function updateAgentURI(
        address _agentAddress,
        string calldata _newAgentURI
    ) external onlyAgentOwner(_agentAddress) nonReentrant {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        agents[_agentAddress].agentURI = _newAgentURI;
        emit AgentURIUpdated(_agentAddress, _newAgentURI);
    }

    /**
     * @dev Activates or deactivates an AetherAgent. Deactivated agents cannot execute intents.
     * @param _agentAddress The address of the agent to set status for.
     * @param _isActive The new active status (true for active, false for inactive).
     */
    function setAgentStatus(
        address _agentAddress,
        bool _isActive
    ) external onlyAgentOwner(_agentAddress) nonReentrant {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        agents[_agentAddress].isActive = _isActive;
        emit AgentStatusChanged(_agentAddress, _isActive);
    }

    /**
     * @dev Transfers ownership of an AetherAgent to a new address.
     * @param _agentAddress The address of the agent.
     * @param _newOwner The address of the new owner.
     */
    function transferAgentOwnership(
        address _agentAddress,
        address _newOwner
    ) external onlyAgentOwner(_agentAddress) nonReentrant {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        address oldOwner = agents[_agentAddress].owner;
        agents[_agentAddress].owner = _newOwner;
        emit AgentOwnershipTransferred(_agentAddress, oldOwner, _newOwner);
    }

    /**
     * @dev Retrieves comprehensive details about a specified AetherAgent.
     * @param _agentAddress The address of the agent.
     * @return A tuple containing agent details.
     */
    function getAgentDetails(address _agentAddress)
        external
        view
        returns (
            address agentAddr,
            address ownerAddr,
            string memory name,
            string memory agentURI,
            bool isActive,
            int256 reputationScore,
            uint256 serviceFee,
            uint256 balance,
            uint256 lastExecutionTime
        )
    {
        Agent storage agent = agents[_agentAddress];
        if (agent.agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        return (
            agent.agentAddress,
            agent.owner,
            agent.name,
            agent.agentURI,
            agent.isActive,
            agent.reputationScore,
            agent.serviceFee,
            agent.balance,
            agent.lastExecutionTime
        );
    }

    // --- II. Intent Definition & Delegation ---

    /**
     * @dev Allows a user to define a new intent.
     * @param _intentDataURI IPFS/Arweave URI pointing to the intent's detailed logic, parameters, and desired outcome.
     * @param _requiresApproval If true, the intent owner must explicitly approve an agent's proposed action before execution.
     * @return The ID of the newly defined intent.
     */
    function defineIntent(
        string calldata _intentDataURI,
        bool _requiresApproval
    ) external nonReentrant returns (uint256) {
        uint256 intentId = nextIntentId++;
        intents[intentId] = Intent({
            id: intentId,
            owner: msg.sender,
            delegatedAgent: address(0),
            intentDataURI: _intentDataURI,
            status: IntentStatus.Defined,
            requiresApproval: _requiresApproval,
            proposedExecutionHash: 0,
            creationTime: block.timestamp,
            executionTime: 0,
            lastFeedbackTime: 0
        });
        emit IntentDefined(intentId, msg.sender, _intentDataURI, _requiresApproval);
        return intentId;
    }

    /**
     * @dev Delegates a defined intent to a specific AetherAgent for potential execution.
     * @param _intentId The ID of the intent to delegate.
     * @param _agentAddress The address of the agent to delegate to.
     */
    function delegateIntentToAgent(
        uint256 _intentId,
        address _agentAddress
    ) external onlyIntentOwner(_intentId) nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        if (intent.status != IntentStatus.Defined) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Defined, intent.status);
        }
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        if (!agents[_agentAddress].isActive) {
            revert AgentNotActive(_agentAddress);
        }
        if (agents[_agentAddress].reputationScore < minimumAgentReputation) {
            revert ReputationBelowMinimum(_agentAddress, agents[_agentAddress].reputationScore, minimumAgentReputation);
        }
        if (intent.delegatedAgent != address(0)) {
            revert AgentAlreadyDelegated(_intentId);
        }

        intent.delegatedAgent = _agentAddress;
        intent.status = IntentStatus.Delegated;
        emit IntentDelegated(_intentId, msg.sender, _agentAddress);
    }

    /**
     * @dev Revokes an agent's delegation for a specific intent.
     * @param _intentId The ID of the intent to revoke delegation from.
     */
    function revokeIntentDelegation(
        uint256 _intentId
    ) external onlyIntentOwner(_intentId) nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        if (intent.status != IntentStatus.Delegated && intent.status != IntentStatus.Proposed) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Delegated, intent.status);
        }

        address revokedAgent = intent.delegatedAgent;
        intent.delegatedAgent = address(0);
        intent.status = IntentStatus.Defined; // Return to defined status
        intent.proposedExecutionHash = 0; // Clear any pending proposal
        emit IntentDelegationRevoked(_intentId, msg.sender, revokedAgent);
    }

    /**
     * @dev (Agent Callable) An agent proposes an action for an intent that requires explicit owner approval.
     *      The agent submits a hash of the intended action, which the owner can later approve.
     * @param _intentId The ID of the intent.
     * @param _executionHash A cryptographic hash (e.g., Keccak256) of the action the agent intends to perform.
     */
    function proposeAgentExecution(
        uint256 _intentId,
        bytes32 _executionHash
    ) external onlyDelegatedAgent(_intentId) nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        if (!intent.requiresApproval) {
            revert("AetherMindProtocol: Intent does not require approval");
        }
        if (intent.status != IntentStatus.Delegated) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Delegated, intent.status);
        }

        intent.proposedExecutionHash = _executionHash;
        intent.status = IntentStatus.Proposed;
        emit AgentExecutionProposed(_intentId, msg.sender, _executionHash);
    }

    /**
     * @dev (Intent Owner Callable) The intent owner approves a previously proposed agent action.
     *      This allows the agent to then call `executeIntentByAgent`.
     * @param _intentId The ID of the intent.
     */
    function approveProposedExecution(
        uint256 _intentId
    ) external onlyIntentOwner(_intentId) nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        if (!intent.requiresApproval) {
            revert("AetherMindProtocol: Intent does not require approval");
        }
        if (intent.status != IntentStatus.Proposed) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Proposed, intent.status);
        }
        if (intent.proposedExecutionHash == 0) {
            revert NoPendingProposal(_intentId);
        }

        // Revert to delegated, now with owner approval, agent can execute
        intent.status = IntentStatus.Delegated; 
        emit ProposedExecutionApproved(_intentId, msg.sender, intent.delegatedAgent, intent.proposedExecutionHash);
        // Note: The proposed hash is kept, the agent's actual execution should match it.
    }

    // --- III. Agent Execution & Callback ---

    /**
     * @dev (Agent Callable) An agent calls this function to signal successful execution of a delegated intent.
     *      It updates the intent status and records execution time.
     * @param _intentId The ID of the intent that was executed.
     * @param _executionProof Optional data, e.g., a hash of the executed transaction or a ZKP proof.
     */
    function executeIntentByAgent(
        uint256 _intentId,
        bytes calldata _executionProof
    ) external onlyDelegatedAgent(_intentId) nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        // If requiresApproval, status must have gone through Proposed -> Delegated after approval
        // If not requiresApproval, status must be Delegated
        if (intent.status != IntentStatus.Delegated) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Delegated, intent.status);
        }
        if (intent.requiresApproval && intent.proposedExecutionHash == 0) {
             revert("AetherMindProtocol: Intent required approval, but no proposal was approved or proposal was cleared");
        }
        // Optionally, could add a check here to ensure _executionProof or transaction details
        // match intent.proposedExecutionHash if requiresApproval. This would be more complex
        // and might require an interface for the agent to provide specific details.

        Agent storage agent = agents[msg.sender];
        agent.lastExecutionTime = block.timestamp;

        intent.status = IntentStatus.Executed;
        intent.executionTime = block.timestamp;
        emit IntentExecuted(_intentId, msg.sender, block.timestamp);
    }

    /**
     * @dev Retrieves the current status of a specific intent.
     * @param _intentId The ID of the intent.
     * @return The current status of the intent.
     */
    function getIntentStatus(uint256 _intentId)
        external
        view
        returns (IntentStatus)
    {
        if (intents[_intentId].id == 0) {
            revert IntentNotFound(_intentId);
        }
        return intents[_intentId].status;
    }

    /**
     * @dev Retrieves the timestamp of the last successful intent execution by a given agent.
     * @param _agentAddress The address of the agent.
     * @return The timestamp of the last execution.
     */
    function getAgentLastExecutionTime(address _agentAddress)
        external
        view
        returns (uint256)
    {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        return agents[_agentAddress].lastExecutionTime;
    }

    // --- IV. Reputation & Challenge System ---

    /**
     * @dev Allows an intent owner to submit feedback (positive/negative) on an agent's performance after execution.
     *      This impacts the agent's reputation.
     * @param _intentId The ID of the intent for which feedback is given.
     * @param _isPositive True for positive feedback, false for negative.
     * @param _feedbackURI IPFS/Arweave URI for detailed feedback.
     */
    function submitAgentFeedback(
        uint256 _intentId,
        bool _isPositive,
        string calldata _feedbackURI
    ) external onlyIntentOwner(_intentId) nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        if (intent.status != IntentStatus.Executed) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Executed, intent.status);
        }
        if (intent.delegatedAgent == address(0)) {
            revert("AetherMindProtocol: No agent delegated for this intent");
        }

        Agent storage agent = agents[intent.delegatedAgent];
        int256 oldReputation = agent.reputationScore;

        if (_isPositive) {
            agent.reputationScore += 10; // Example: +10 for positive feedback
        } else {
            agent.reputationScore -= 5;  // Example: -5 for negative feedback
        }
        intent.lastFeedbackTime = block.timestamp;
        emit AgentFeedbackSubmitted(_intentId, intent.delegatedAgent, _isPositive);
        emit AgentReputationUpdated(intent.delegatedAgent, oldReputation, agent.reputationScore);
    }

    /**
     * @dev Allows an intent owner to initiate a formal challenge against an agent's execution.
     *      This creates a challenge for protocol admins/DAO to resolve.
     * @param _intentId The ID of the intent whose execution is challenged.
     * @param _reasonURI IPFS/Arweave URI for detailed reasons and evidence for the challenge.
     * @param _reputationImpactProposal The proposed reputation change if the challenge is upheld.
     * @return The ID of the newly created challenge.
     */
    function initiateChallenge(
        uint256 _intentId,
        string calldata _reasonURI,
        int256 _reputationImpactProposal
    ) external onlyIntentOwner(_intentId) nonReentrant returns (uint256) {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        if (intent.status != IntentStatus.Executed) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Executed, intent.status);
        }
        if (intent.delegatedAgent == address(0)) {
            revert("AetherMindProtocol: No agent delegated for this intent to challenge");
        }

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            id: challengeId,
            intentId: _intentId,
            challenger: msg.sender,
            agentAddress: intent.delegatedAgent,
            reasonURI: _reasonURI,
            status: ChallengeStatus.Pending,
            submissionTime: block.timestamp,
            resolutionTime: 0,
            reputationImpact: _reputationImpactProposal
        });
        intent.status = IntentStatus.Challenged;
        emit ChallengeInitiated(challengeId, _intentId, msg.sender, intent.delegatedAgent);
        return challengeId;
    }

    /**
     * @dev (Protocol Admin/DAO Callable) Resolves a pending challenge.
     *      Updates challenge status and applies reputation impact to the agent.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _isApproved True if the challenge is upheld, false if rejected.
     * @param _finalReputationImpact The reputation change to apply if approved.
     */
    function resolveChallenge(
        uint256 _challengeId,
        bool _isApproved,
        int256 _finalReputationImpact
    ) external onlyOwner nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            revert ChallengeNotFound(_challengeId);
        }
        if (challenge.status != ChallengeStatus.Pending) {
            revert("AetherMindProtocol: Challenge already resolved");
        }

        Agent storage agent = agents[challenge.agentAddress];
        if (agent.agentAddress == address(0)) {
            revert AgentNotFound(challenge.agentAddress); // Agent might have been removed
        }

        int256 oldReputation = agent.reputationScore;

        challenge.status = _isApproved ? ChallengeStatus.Approved : ChallengeStatus.Rejected;
        challenge.resolutionTime = block.timestamp;
        
        if (_isApproved) {
            challenge.reputationImpact = _finalReputationImpact;
            agent.reputationScore += _finalReputationImpact;
        } else {
            // If rejected, there might be a small positive impact on agent or negative for challenger
            // For simplicity, no reputation impact on agent if rejected here.
            challenge.reputationImpact = 0; 
        }

        Intent storage intent = intents[challenge.intentId];
        intent.status = IntentStatus.Resolved;
        intent.lastFeedbackTime = block.timestamp; // Update last feedback time on intent

        emit ChallengeResolved(_challengeId, challenge.intentId, challenge.agentAddress, _isApproved, _finalReputationImpact);
        emit AgentReputationUpdated(challenge.agentAddress, oldReputation, agent.reputationScore);
    }

    /**
     * @dev Retrieves the current reputation score of a specified agent.
     * @param _agentAddress The address of the agent.
     * @return The agent's current reputation score.
     */
    function getAgentReputation(address _agentAddress)
        external
        view
        returns (int256)
    {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        return agents[_agentAddress].reputationScore;
    }

    // --- V. Economic & Protocol Fees ---

    /**
     * @dev Allows an agent owner to set the service fee charged by their agent.
     * @param _agentAddress The address of the agent.
     * @param _feeAmount The new service fee amount in wei.
     */
    function setAgentServiceFee(
        address _agentAddress,
        uint256 _feeAmount
    ) external onlyAgentOwner(_agentAddress) nonReentrant {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        agents[_agentAddress].serviceFee = _feeAmount;
        emit AgentServiceFeeSet(_agentAddress, _feeAmount);
    }

    /**
     * @dev (Intent Owner Callable) The intent owner pays the agent's service fee upon successful execution.
     *      Includes a protocol fee component.
     * @param _intentId The ID of the intent for which payment is made.
     */
    function payForAgentService(uint256 _intentId) external payable nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        if (intent.owner != msg.sender) {
            revert NotIntentOwner(msg.sender, _intentId);
        }
        if (intent.status != IntentStatus.Executed) {
            revert InvalidIntentStatus(_intentId, IntentStatus.Executed, intent.status);
        }
        if (intent.delegatedAgent == address(0)) {
            revert("AetherMindProtocol: No agent delegated for this intent to pay");
        }

        Agent storage agent = agents[intent.delegatedAgent];
        if (agent.agentAddress == address(0)) {
            revert AgentNotFound(intent.delegatedAgent);
        }
        if (agent.serviceFee == 0) {
            revert("AetherMindProtocol: Agent service fee is zero");
        }
        if (msg.value < agent.serviceFee) {
            revert InsufficientPayment(agent.serviceFee, msg.value);
        }

        uint256 protocolCut = (agent.serviceFee * protocolFeeRate) / 10000; // Assuming 10000 for 100%
        uint256 agentShare = agent.serviceFee - protocolCut;

        agent.balance += agentShare;
        protocolBalance += protocolCut;

        // Refund any excess payment
        if (msg.value > agent.serviceFee) {
            payable(msg.sender).transfer(msg.value - agent.serviceFee);
        }

        emit AgentServicePaid(_intentId, msg.sender, intent.delegatedAgent, agent.serviceFee);
    }

    /**
     * @dev Allows an agent owner to withdraw the accumulated earnings of their agent.
     * @param _agentAddress The address of the agent.
     */
    function withdrawAgentEarnings(address _agentAddress)
        external
        onlyAgentOwner(_agentAddress)
        nonReentrant
    {
        Agent storage agent = agents[_agentAddress];
        if (agent.agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        if (agent.balance == 0) {
            revert NoEarningsToWithdraw(_agentAddress);
        }

        uint256 amount = agent.balance;
        agent.balance = 0;
        payable(msg.sender).transfer(amount);
        emit AgentEarningsWithdrawn(_agentAddress, msg.sender, amount);
    }

    /**
     * @dev (Protocol Admin/DAO Callable) Allows the protocol owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 amount = protocolBalance;
        if (amount == 0) {
            revert("AetherMindProtocol: No protocol fees to withdraw");
        }
        protocolBalance = 0;
        payable(msg.sender).transfer(amount);
    }

    // --- VI. Oracle Integration ---

    /**
     * @dev (Protocol Admin/DAO Callable) Registers a trusted oracle contract with the protocol.
     *      Only registered oracles can be authorized for agent access.
     * @param _oracleAddress The address of the oracle contract.
     * @param _description A brief description of the data provided by this oracle.
     */
    function registerTrustedOracle(
        address _oracleAddress,
        string calldata _description
    ) external onlyOwner nonReentrant {
        if (_oracleAddress == address(0)) {
            revert("AetherMindProtocol: Invalid oracle address");
        }
        if (trustedOracles[_oracleAddress].oracleAddress != address(0)) {
            revert("AetherMindProtocol: Oracle already registered");
        }

        trustedOracles[_oracleAddress] = Oracle({
            oracleAddress: _oracleAddress,
            description: _description,
            isActive: true
        });
        registeredOracleAddresses.push(_oracleAddress);
        emit OracleRegistered(_oracleAddress, _description);
    }

    /**
     * @dev Allows an agent owner to grant or revoke access for their agent to a specific registered oracle.
     * @param _agentAddress The address of the agent.
     * @param _oracleAddress The address of the oracle.
     * @param _canAccess True to grant access, false to revoke.
     */
    function authorizeAgentOracleAccess(
        address _agentAddress,
        address _oracleAddress,
        bool _canAccess
    ) external onlyAgentOwner(_agentAddress) nonReentrant {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        if (trustedOracles[_oracleAddress].oracleAddress == address(0)) {
            revert OracleNotRegistered(_oracleAddress);
        }
        if (!trustedOracles[_oracleAddress].isActive) {
            revert("AetherMindProtocol: Oracle is not active");
        }

        agents[_agentAddress].authorizedOracles[_oracleAddress] = _canAccess;
        emit AgentOracleAccessChanged(_agentAddress, _oracleAddress, _canAccess);
    }

    /**
     * @dev Checks if a specific agent is authorized to use a particular oracle.
     * @param _agentAddress The address of the agent.
     * @param _oracleAddress The address of the oracle.
     * @return True if the agent is authorized, false otherwise.
     */
    function checkAuthorizedOracle(
        address _agentAddress,
        address _oracleAddress
    ) external view returns (bool) {
        if (agents[_agentAddress].agentAddress == address(0)) {
            revert AgentNotFound(_agentAddress);
        }
        if (trustedOracles[_oracleAddress].oracleAddress == address(0)) {
            revert OracleNotRegistered(_oracleAddress);
        }
        return agents[_agentAddress].authorizedOracles[_oracleAddress];
    }

    // --- VII. Protocol Governance & Utilities ---

    /**
     * @dev (Protocol Admin/DAO Callable) Adjusts the percentage of agent service fees collected by the protocol.
     * @param _newRate The new protocol fee rate in basis points (e.g., 100 for 1%, 500 for 5%). Max 10000 (100%).
     */
    function setProtocolFeeRate(uint256 _newRate) external onlyOwner nonReentrant {
        if (_newRate > 10000) { // Max 100%
            revert InvalidFeeRate(_newRate);
        }
        uint256 oldRate = protocolFeeRate;
        protocolFeeRate = _newRate;
        emit ProtocolFeeRateSet(oldRate, _newRate);
    }

    /**
     * @dev (Protocol Admin/DAO Callable) Sets a minimum reputation threshold required for agents to perform critical actions (e.g., executing intents).
     * @param _minReputation The new minimum reputation score.
     */
    function setMinimumAgentReputation(int256 _minReputation) external onlyOwner nonReentrant {
        int256 oldMinReputation = minimumAgentReputation;
        minimumAgentReputation = _minReputation;
        emit MinimumAgentReputationSet(oldMinReputation, _minReputation);
    }

    // --- View Functions for Collections (Careful with large datasets) ---

    /**
     * @dev Retrieves all registered agent addresses.
     * @return An array of all registered AetherAgent addresses.
     */
    function getRegisteredAgentAddresses() external view returns (address[] memory) {
        return registeredAgentAddresses;
    }

    /**
     * @dev Retrieves all registered oracle addresses.
     * @return An array of all registered Oracle addresses.
     */
    function getRegisteredOracleAddresses() external view returns (address[] memory) {
        return registeredOracleAddresses;
    }

    /**
     * @dev Retrieves details about a challenge.
     * @param _challengeId The ID of the challenge.
     * @return A tuple containing challenge details.
     */
    function getChallengeDetails(uint256 _challengeId)
        external
        view
        returns (
            uint256 id,
            uint256 intentId,
            address challenger,
            address agentAddress,
            string memory reasonURI,
            ChallengeStatus status,
            uint256 submissionTime,
            uint256 resolutionTime,
            int256 reputationImpact
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            revert ChallengeNotFound(_challengeId);
        }
        return (
            challenge.id,
            challenge.intentId,
            challenge.challenger,
            challenge.agentAddress,
            challenge.reasonURI,
            challenge.status,
            challenge.submissionTime,
            challenge.resolutionTime,
            challenge.reputationImpact
        );
    }

    /**
     * @dev Retrieves details about an intent.
     * @param _intentId The ID of the intent.
     * @return A tuple containing intent details.
     */
    function getIntentDetails(uint256 _intentId)
        external
        view
        returns (
            uint256 id,
            address owner,
            address delegatedAgent,
            string memory intentDataURI,
            IntentStatus status,
            bool requiresApproval,
            bytes32 proposedExecutionHash,
            uint256 creationTime,
            uint256 executionTime,
            uint256 lastFeedbackTime
        )
    {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) {
            revert IntentNotFound(_intentId);
        }
        return (
            intent.id,
            intent.owner,
            intent.delegatedAgent,
            intent.intentDataURI,
            intent.status,
            intent.requiresApproval,
            intent.proposedExecutionHash,
            intent.creationTime,
            intent.executionTime,
            intent.lastFeedbackTime
        );
    }
}
```