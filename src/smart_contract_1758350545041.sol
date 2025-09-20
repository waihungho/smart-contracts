This smart contract, named **Aethermind**, envisions a decentralized network of AI agents designed to perform complex tasks, provide verifiable data, and contribute to a collective intelligence. It introduces novel concepts such as on-chain AI model governance, reputation-based task allocation, and commitment-based verifiable computation for AI-driven services.

The contract does not run AI models on-chain, but rather orchestrates and incentivizes off-chain AI agents, ensuring transparency, accountability, and quality through a combination of staking, reputation, and a unique dispute resolution mechanism centered around cryptographic proofs.

---

## **Aethermind Smart Contract: Outline & Function Summary**

**Contract Name:** `Aethermind`

**Core Concept:** A decentralized, reputation-driven network of AI agents that offer verifiable AI services. Users can request tasks, and agents compete to provide results, with quality and honesty enforced through staking, reputation scores, and cryptographic proof commitments. The community governs which "AI models" (capabilities/algorithms) are officially supported.

**Key Advanced Concepts:**
*   **Decentralized AI Model Governance:** On-chain voting and activation of AI model specifications/capabilities.
*   **Reputation-Weighted Task Allocation & Rewards:** Agents with higher reputation are prioritized and receive greater rewards.
*   **Commitment-Based Verifiable Computation:** Agents submit cryptographic proof hashes (e.g., of computation traces or ZK-proofs) alongside results, enabling dispute resolution and accountability.
*   **Multi-Agent Consensus:** Tasks can require multiple agents to achieve consensus on results, enhancing reliability.
*   **Dynamic Incentives & Slashing:** A system of rewards for accurate work and penalties (slashing) for dishonest behavior.

---

### **Function Summary (Total: 22 Functions)**

**I. Agent Registry & Staking (Foundation)**
1.  `registerAgent(string calldata _agentName, string calldata _agentURI)`: Allows a new AI agent to join the network by staking a minimum collateral and providing identifying information.
2.  `updateAgentProfile(string calldata _newAgentURI)`: Enables an existing agent to update their public profile URI (e.g., pointing to an updated IPFS JSON).
3.  `depositStake()`: Allows an agent to increase their staked collateral, potentially increasing their task eligibility or reputation weight.
4.  `deregisterAgent()`: Initiates the process for an agent to leave the network, locking their stake for a cooldown period.
5.  `withdrawMyStake()`: Allows a deregistered agent to withdraw their stake after the cooldown period, assuming no pending disputes or tasks.

**II. AI Model & Capability Governance (Decentralized AI Definition)**
6.  `proposeAIModel(string calldata _modelTypeURI, bytes32 _modelConfigHash, string calldata _description)`: An agent proposes a new AI model specification (e.g., a specific algorithm, pre-trained model hash, or capability class) to be recognized by the network.
7.  `voteOnModelProposal(uint256 _proposalId, bool _approve)`: Registered agents (or designated governance token holders) vote to approve or reject a proposed AI model.
8.  `activateAIModel(uint256 _proposalId)`: Activates a model after successful community voting, making it available for tasks.
9.  `deactivateAIModel(uint256 _modelId)`: Deactivates an active model, e.g., if vulnerabilities or inaccuracies are discovered. Requires governance action.
10. `declareAgentCapability(uint256 _modelId)`: An agent declares their ability and willingness to perform tasks using a specific activated AI model.

**III. Task & Job Management (AI-Driven Oracle/Compute)**
11. `createTask(string calldata _taskRequestHash, uint256 _bounty, uint256 _minReputation, uint256 _targetModelId, uint256 _maxAgents)`: A user requests an AI task, specifying details like task data hash, bounty, minimum agent reputation, target AI model, and the number of agents required for consensus. Funds are escrowed.
12. `acceptTask(uint256 _taskId)`: A registered agent accepts a pending task they are capable of performing and meets the reputation requirements.
13. `submitTaskResult(uint256 _taskId, string calldata _resultURI, bytes32 _proofHash)`: An agent submits the task's result (URI to output) and a cryptographic proof hash (e.g., hash of computation trace or ZK-proof output).
14. `disputeTaskResult(uint256 _taskId, uint256 _agentResultIndex, string calldata _disputeReasonURI)`: Another agent or user can dispute a submitted result, providing evidence via a URI.
15. `resolveTask(uint256 _taskId)`: Finalizes a task. Distributes bounty to honest agents, updates reputation, and slashes dishonest ones based on consensus or dispute resolution. Callable after a verification period.

**IV. Reputation & Dynamic Incentives (Trust & Performance)**
16. `getAgentReputation(address _agentAddress)`: Retrieves the current reputation score of a specific agent.
17. `adjustReputation(address _agentAddress, int256 _reputationDelta)`: Allows the contract owner or governance to manually adjust an agent's reputation for significant off-chain events not covered by automated processes.
18. `claimTaskBounty(uint256 _taskId)`: Allows an agent to claim their share of a task's bounty after it has been successfully resolved and marked as paid.

**V. Network Configuration & Treasury (Decentralized Governance & Sustainability)**
19. `setAgentMinStake(uint256 _newMinStake)`: Updates the minimum ETH stake required for new agents to register.
20. `setProtocolFee(uint256 _newFeePercentage)`: Updates the percentage of task bounties collected as protocol fees.
21. `setReputationPenaltyFactor(uint256 _newFactor)`: Adjusts the severity of reputation penalties for misconduct.
22. `withdrawProtocolFees()`: Allows the contract owner or designated treasury to withdraw accumulated protocol fees.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Aethermind
 * @dev A decentralized network of AI agents for verifiable AI services.
 *      Agents stake collateral, declare capabilities (AI models), accept tasks,
 *      and submit results with cryptographic proofs. The network features
 *      on-chain AI model governance, reputation-based incentives, and a
 *      dispute resolution mechanism.
 *
 * Outline & Function Summary:
 *
 * I. Agent Registry & Staking (Foundation)
 *    1. registerAgent(string calldata _agentName, string calldata _agentURI): Register a new AI agent.
 *    2. updateAgentProfile(string calldata _newAgentURI): Update agent's public profile URI.
 *    3. depositStake(): Increase agent's staked collateral.
 *    4. deregisterAgent(): Initiate agent deregistration, locking stake.
 *    5. withdrawMyStake(): Withdraw agent's stake after cooldown.
 *
 * II. AI Model & Capability Governance (Decentralized AI Definition)
 *    6. proposeAIModel(string calldata _modelTypeURI, bytes32 _modelConfigHash, string calldata _description): Propose a new AI model specification.
 *    7. voteOnModelProposal(uint256 _proposalId, bool _approve): Vote on a proposed AI model.
 *    8. activateAIModel(uint256 _proposalId): Activate a model after successful vote.
 *    9. deactivateAIModel(uint256 _modelId): Deactivate an active model (governance action).
 *    10. declareAgentCapability(uint256 _modelId): Agent declares capability for a model.
 *
 * III. Task & Job Management (AI-Driven Oracle/Compute)
 *    11. createTask(string calldata _taskRequestHash, uint256 _bounty, uint256 _minReputation, uint256 _targetModelId, uint256 _maxAgents): Request a new AI task.
 *    12. acceptTask(uint256 _taskId): Agent accepts a pending task.
 *    13. submitTaskResult(uint256 _taskId, string calldata _resultURI, bytes32 _proofHash): Agent submits task result with proof.
 *    14. disputeTaskResult(uint256 _taskId, uint256 _agentResultIndex, string calldata _disputeReasonURI): Dispute a submitted result.
 *    15. resolveTask(uint256 _taskId): Finalize task, distribute bounty, update reputation.
 *
 * IV. Reputation & Dynamic Incentives (Trust & Performance)
 *    16. getAgentReputation(address _agentAddress): Get an agent's reputation score.
 *    17. adjustReputation(address _agentAddress, int256 _reputationDelta): Manually adjust agent reputation (owner/governance).
 *    18. claimTaskBounty(uint256 _taskId): Agent claims their bounty for a resolved task.
 *
 * V. Network Configuration & Treasury (Decentralized Governance & Sustainability)
 *    19. setAgentMinStake(uint256 _newMinStake): Update minimum stake for agents.
 *    20. setProtocolFee(uint256 _newFeePercentage): Update protocol fee percentage.
 *    21. setReputationPenaltyFactor(uint256 _newFactor): Adjust reputation penalty severity.
 *    22. withdrawProtocolFees(): Withdraw accumulated protocol fees (owner/treasury).
 */
contract Aethermind {

    address public owner;
    uint256 public protocolFeePercentage; // e.g., 500 for 5% (500/10000)
    uint256 public minAgentStake;
    uint256 public reputationPenaltyFactor; // Multiplier for reputation loss during slashing
    uint256 public taskVerificationPeriod; // Time in seconds for results to be verified/disputed

    uint256 private nextAgentId;
    uint256 private nextModelId;
    uint256 private nextProposalId;
    uint256 private nextTaskId;
    uint256 public protocolFeesAccrued;

    enum AgentStatus { Registered, Deregistering, Deregistered }
    enum ModelProposalStatus { Pending, Approved, Rejected }
    enum TaskStatus { Created, InProgress, ResultsSubmitted, Disputed, Resolved, Canceled }

    struct Agent {
        uint256 id;
        string name;
        string agentURI; // URI to agent's profile/metadata
        address agentAddress;
        uint256 stake;
        AgentStatus status;
        uint256 deregisterCooldownEnd; // Timestamp when stake can be withdrawn
        uint256[] capabilities; // List of AIModel IDs agent declares capability for
        uint256 totalTasksCompleted;
    }

    struct AIModel {
        uint256 id;
        string modelTypeURI; // URI to model spec/description (e.g., IPFS hash of schema)
        bytes32 modelConfigHash; // Hash of specific model configuration/weights
        address proposer;
        bool isActive;
        string description;
    }

    struct ModelProposal {
        uint256 id;
        AIModel modelDetails;
        ModelProposalStatus status;
        mapping(address => bool) votes; // true for approve, false for reject (unused if vote is for specific value)
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 voterCount; // Number of unique voters
        uint256 creationTime;
    }

    struct TaskResult {
        address agentAddress;
        string resultURI; // URI to task result (e.g., IPFS hash of output)
        bytes32 proofHash; // Hash of computation proof (e.g., ZK-proof output, trace hash)
        bool verified; // True if result is verified as correct
        bool disputed;
        bool paid;
    }

    struct Task {
        uint256 id;
        address requester;
        string taskRequestHash; // Hash of the detailed task request
        uint256 bounty; // Total bounty for the task
        uint256 minReputation; // Minimum reputation required for agents
        uint256 targetModelId; // AIModel required for the task
        uint256 maxAgents; // Max number of agents to accept this task for consensus
        TaskStatus status;
        uint256 creationTime;
        uint256 resultsSubmissionDeadline; // Max time for agents to submit results
        uint256 verificationDeadline; // Max time for results to be verified/disputed
        TaskResult[] results; // Array of submitted results
        uint256 disputeCount; // Number of active disputes for this task
    }

    mapping(address => Agent) public agents;
    mapping(address => bool) public isAgent; // Quick lookup for agent status
    mapping(address => int256) public agentReputation; // Reputation can be negative

    mapping(uint256 => AIModel) public aiModels;
    mapping(uint256 => ModelProposal) public modelProposals;

    mapping(uint256 => Task) public tasks;

    event AgentRegistered(address indexed agentAddress, uint256 agentId, string name, string agentURI, uint256 stake);
    event AgentProfileUpdated(address indexed agentAddress, string newAgentURI);
    event AgentStakeDeposited(address indexed agentAddress, uint256 amount, uint256 newTotalStake);
    event AgentDeregisterInitiated(address indexed agentAddress, uint256 agentId, uint256 cooldownEnd);
    event AgentStakeWithdrawn(address indexed agentAddress, uint256 amount);

    event AIModelProposed(uint256 indexed proposalId, address indexed proposer, string modelTypeURI, bytes32 modelConfigHash);
    event AIModelVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event AIModelActivated(uint256 indexed modelId, uint256 proposalId);
    event AIModelDeactivated(uint256 indexed modelId, address indexed deactivator);
    event AgentCapabilityDeclared(address indexed agentAddress, uint256 indexed modelId);

    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 bounty, uint256 targetModelId, uint256 maxAgents);
    event TaskAccepted(uint256 indexed taskId, address indexed agentAddress);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed agentAddress, string resultURI, bytes32 proofHash);
    event TaskResultDisputed(uint256 indexed taskId, address indexed disputer, uint256 resultIndex, string disputeReasonURI);
    event TaskResolved(uint256 indexed taskId, TaskStatus finalStatus, uint256 totalBountyPaid, uint256 protocolFee);
    event TaskBountyClaimed(uint256 indexed taskId, address indexed agentAddress, uint256 amount);

    event AgentReputationAdjusted(address indexed agentAddress, int256 oldReputation, int256 newReputation, int256 delta);
    event ParameterUpdated(string indexed paramName, uint256 oldValue, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredAgent() {
        require(isAgent[msg.sender], "Caller is not a registered agent");
        require(agents[msg.sender].status == AgentStatus.Registered, "Agent is not in 'Registered' status");
        _;
    }

    constructor() {
        owner = msg.sender;
        protocolFeePercentage = 500; // 5%
        minAgentStake = 1 ether;
        reputationPenaltyFactor = 100; // 1x stake, can be adjusted
        taskVerificationPeriod = 2 days; // 2 days for verification/dispute
        nextAgentId = 1;
        nextModelId = 1;
        nextProposalId = 1;
        nextTaskId = 1;
    }

    /**
     * @dev Registers a new AI agent with a minimum stake.
     * @param _agentName The public name of the agent.
     * @param _agentURI URI pointing to the agent's detailed profile/metadata.
     */
    function registerAgent(string calldata _agentName, string calldata _agentURI) external payable {
        require(!isAgent[msg.sender], "Agent already registered");
        require(msg.value >= minAgentStake, "Insufficient stake amount");
        require(bytes(_agentName).length > 0, "Agent name cannot be empty");
        require(bytes(_agentURI).length > 0, "Agent URI cannot be empty");

        agents[msg.sender] = Agent({
            id: nextAgentId++,
            name: _agentName,
            agentURI: _agentURI,
            agentAddress: msg.sender,
            stake: msg.value,
            status: AgentStatus.Registered,
            deregisterCooldownEnd: 0,
            capabilities: new uint256[](0),
            totalTasksCompleted: 0
        });
        isAgent[msg.sender] = true;
        agentReputation[msg.sender] = 0; // Initialize with 0 reputation

        emit AgentRegistered(msg.sender, agents[msg.sender].id, _agentName, _agentURI, msg.value);
    }

    /**
     * @dev Allows an agent to update their public profile URI.
     * @param _newAgentURI The new URI for the agent's profile.
     */
    function updateAgentProfile(string calldata _newAgentURI) external onlyRegisteredAgent {
        require(bytes(_newAgentURI).length > 0, "Agent URI cannot be empty");
        agents[msg.sender].agentURI = _newAgentURI;
        emit AgentProfileUpdated(msg.sender, _newAgentURI);
    }

    /**
     * @dev Allows an agent to increase their staked collateral.
     */
    function depositStake() external payable onlyRegisteredAgent {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        Agent storage agent = agents[msg.sender];
        agent.stake += msg.value;
        emit AgentStakeDeposited(msg.sender, msg.value, agent.stake);
    }

    /**
     * @dev Initiates the deregistration process for an agent.
     *      Stake is locked for a cooldown period to ensure task finalization.
     */
    function deregisterAgent() external onlyRegisteredAgent {
        Agent storage agent = agents[msg.sender];
        require(agent.deregisterCooldownEnd == 0 || agent.deregisterCooldownEnd <= block.timestamp, "Cannot deregister while stake is cooling down.");
        // TODO: Add logic to ensure no active tasks or disputes

        agent.status = AgentStatus.Deregistering;
        agent.deregisterCooldownEnd = block.timestamp + taskVerificationPeriod * 2; // Double the verification period for safety
        emit AgentDeregisterInitiated(msg.sender, agent.id, agent.deregisterCooldownEnd);
    }

    /**
     * @dev Allows a deregistering agent to withdraw their stake after the cooldown.
     *      Requires no active tasks or disputes linked to the agent.
     */
    function withdrawMyStake() external {
        Agent storage agent = agents[msg.sender];
        require(agent.status == AgentStatus.Deregistering, "Agent is not in deregistering status");
        require(block.timestamp >= agent.deregisterCooldownEnd, "Stake is still in cooldown period");
        // TODO: Add check for no pending tasks/disputes where agent is involved

        uint256 amount = agent.stake;
        agent.stake = 0;
        agent.status = AgentStatus.Deregistered;
        isAgent[msg.sender] = false; // Remove from quick lookup
        
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw stake");

        emit AgentStakeWithdrawn(msg.sender, amount);
    }

    /**
     * @dev An agent proposes a new AI model specification to be recognized by the network.
     *      This model will then undergo community voting.
     * @param _modelTypeURI URI pointing to the generic model specification (e.g., IPFS hash of schema).
     * @param _modelConfigHash Hash of specific model configuration/weights (e.g., for a pre-trained model).
     * @param _description A brief description of the model's capabilities.
     */
    function proposeAIModel(string calldata _modelTypeURI, bytes32 _modelConfigHash, string calldata _description) external onlyRegisteredAgent {
        require(bytes(_modelTypeURI).length > 0, "Model URI cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");

        ModelProposal storage proposal = modelProposals[nextProposalId];
        proposal.id = nextProposalId;
        proposal.modelDetails = AIModel({
            id: 0, // Will be set upon activation
            modelTypeURI: _modelTypeURI,
            modelConfigHash: _modelConfigHash,
            proposer: msg.sender,
            isActive: false,
            description: _description
        });
        proposal.status = ModelProposalStatus.Pending;
        proposal.creationTime = block.timestamp;
        
        nextProposalId++;

        emit AIModelProposed(proposal.id, msg.sender, _modelTypeURI, _modelConfigHash);
    }

    /**
     * @dev Registered agents vote on a proposed AI model.
     * @param _proposalId The ID of the model proposal.
     * @param _approve True to vote for approval, false to vote for rejection.
     */
    function voteOnModelProposal(uint256 _proposalId, bool _approve) external onlyRegisteredAgent {
        ModelProposal storage proposal = modelProposals[_proposalId];
        require(proposal.id != 0, "Model proposal does not exist");
        require(proposal.status == ModelProposalStatus.Pending, "Model proposal is not pending");
        require(!proposal.votes[msg.sender], "Agent has already voted on this proposal");

        proposal.votes[msg.sender] = true; // Mark voter
        if (_approve) {
            proposal.totalVotesFor++;
        } else {
            proposal.totalVotesAgainst++;
        }
        proposal.voterCount++;

        emit AIModelVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Activates an AI model after it has received sufficient approval votes.
     *      Only callable by owner or if a governance threshold is met (not implemented explicitly here, assumed by owner for simplicity).
     * @param _proposalId The ID of the approved model proposal.
     */
    function activateAIModel(uint256 _proposalId) external onlyOwner { // In a full DAO, this would be a governance function
        ModelProposal storage proposal = modelProposals[_proposalId];
        require(proposal.id != 0, "Model proposal does not exist");
        require(proposal.status == ModelProposalStatus.Pending, "Model proposal is not pending");
        
        // Example: Simple majority vote, replace with more complex governance logic
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "Model proposal not approved by majority");

        AIModel storage newModel = aiModels[nextModelId];
        newModel = proposal.modelDetails;
        newModel.id = nextModelId;
        newModel.isActive = true;

        proposal.modelDetails.id = nextModelId; // Update ID in proposal struct
        proposal.status = ModelProposalStatus.Approved;
        
        nextModelId++;

        emit AIModelActivated(newModel.id, _proposalId);
    }

    /**
     * @dev Deactivates an active AI model, typically due to discovered vulnerabilities or inaccuracies.
     * @param _modelId The ID of the model to deactivate.
     */
    function deactivateAIModel(uint256 _modelId) external onlyOwner { // In a full DAO, this would be a governance function
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0 && model.isActive, "Model does not exist or is already inactive");

        model.isActive = false;
        emit AIModelDeactivated(_modelId, msg.sender);
    }

    /**
     * @dev An agent declares their capability to perform tasks using a specific activated AI model.
     * @param _modelId The ID of the AI model the agent is capable of.
     */
    function declareAgentCapability(uint256 _modelId) external onlyRegisteredAgent {
        AIModel storage model = aiModels[_modelId];
        require(model.id != 0 && model.isActive, "Model does not exist or is not active");

        Agent storage agent = agents[msg.sender];
        bool alreadyDeclared = false;
        for (uint256 i = 0; i < agent.capabilities.length; i++) {
            if (agent.capabilities[i] == _modelId) {
                alreadyDeclared = true;
                break;
            }
        }
        require(!alreadyDeclared, "Agent has already declared this capability");

        agent.capabilities.push(_modelId);
        emit AgentCapabilityDeclared(msg.sender, _modelId);
    }

    /**
     * @dev A user requests an AI task by providing task details, bounty, and requirements.
     *      Funds are escrowed until the task is resolved.
     * @param _taskRequestHash Hash of the detailed task request (e.g., IPFS link to spec).
     * @param _bounty Total bounty for the task, including protocol fees.
     * @param _minReputation Minimum reputation required for agents to accept this task.
     * @param _targetModelId The specific AI model required for this task.
     * @param _maxAgents The maximum number of agents allowed to accept this task (for consensus).
     */
    function createTask(
        string calldata _taskRequestHash,
        uint256 _bounty,
        uint256 _minReputation,
        uint256 _targetModelId,
        uint256 _maxAgents
    ) external payable {
        require(bytes(_taskRequestHash).length > 0, "Task request hash cannot be empty");
        require(msg.value >= _bounty, "Insufficient funds to cover bounty");
        require(_bounty > 0, "Bounty must be greater than zero");
        require(_maxAgents > 0 && _maxAgents <= 5, "Max agents must be between 1 and 5 for practical consensus"); // Limit for gas/complexity
        
        AIModel storage model = aiModels[_targetModelId];
        require(model.id != 0 && model.isActive, "Target AI model does not exist or is not active");

        Task storage newTask = tasks[nextTaskId];
        newTask.id = nextTaskId;
        newTask.requester = msg.sender;
        newTask.taskRequestHash = _taskRequestHash;
        newTask.bounty = _bounty;
        newTask.minReputation = _minReputation;
        newTask.targetModelId = _targetModelId;
        newTask.maxAgents = _maxAgents;
        newTask.status = TaskStatus.Created;
        newTask.creationTime = block.timestamp;
        newTask.resultsSubmissionDeadline = block.timestamp + 1 days; // Example: Agents have 1 day to submit
        newTask.verificationDeadline = 0; // Set after first result

        nextTaskId++;

        // Refund any excess ETH
        if (msg.value > _bounty) {
            (bool success, ) = msg.sender.call{value: msg.value - _bounty}("");
            require(success, "Failed to refund excess ETH");
        }

        emit TaskCreated(newTask.id, msg.sender, _bounty, _targetModelId, _maxAgents);
    }

    /**
     * @dev An agent accepts a pending task, provided they meet the requirements.
     * @param _taskId The ID of the task to accept.
     */
    function acceptTask(uint256 _taskId) external onlyRegisteredAgent {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Created || task.status == TaskStatus.InProgress, "Task is not open for acceptance");
        require(task.targetModelId != 0, "Task has no target model specified.");

        Agent storage agent = agents[msg.sender];
        require(agentReputation[msg.sender] >= task.minReputation, "Agent does not meet minimum reputation");

        bool hasCapability = false;
        for (uint256 i = 0; i < agent.capabilities.length; i++) {
            if (agent.capabilities[i] == task.targetModelId) {
                hasCapability = true;
                break;
            }
        }
        require(hasCapability, "Agent does not have the required capability for this task");
        
        require(task.results.length < task.maxAgents, "Task has already reached maximum number of agents");

        // Check if agent already accepted
        for (uint256 i = 0; i < task.results.length; i++) {
            require(task.results[i].agentAddress != msg.sender, "Agent already accepted this task");
        }

        task.status = TaskStatus.InProgress;
        // Temporarily add a placeholder result entry for the agent
        // The actual result will overwrite this.
        task.results.push(TaskResult({
            agentAddress: msg.sender,
            resultURI: "",
            proofHash: 0x0,
            verified: false,
            disputed: false,
            paid: false
        }));

        emit TaskAccepted(_taskId, msg.sender);
    }

    /**
     * @dev An agent submits the result for a task they accepted, along with a cryptographic proof hash.
     * @param _taskId The ID of the task.
     * @param _resultURI URI pointing to the task result (e.g., IPFS hash of the output data).
     * @param _proofHash A cryptographic hash representing proof of computation (e.g., ZK-proof output hash, hash of computation trace).
     */
    function submitTaskResult(uint256 _taskId, string calldata _resultURI, bytes32 _proofHash) external onlyRegisteredAgent {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.InProgress || task.status == TaskStatus.ResultsSubmitted, "Task is not in progress or results not yet submitted");
        require(block.timestamp <= task.resultsSubmissionDeadline, "Result submission deadline passed");
        require(bytes(_resultURI).length > 0, "Result URI cannot be empty");
        require(_proofHash != 0x0, "Proof hash cannot be empty");

        bool agentFound = false;
        uint256 agentResultIndex = 0;
        for (uint256 i = 0; i < task.results.length; i++) {
            if (task.results[i].agentAddress == msg.sender) {
                agentFound = true;
                agentResultIndex = i;
                break;
            }
        }
        require(agentFound, "Agent has not accepted this task or already submitted result");
        require(bytes(task.results[agentResultIndex].resultURI).length == 0, "Agent already submitted a result for this task");

        task.results[agentResultIndex].resultURI = _resultURI;
        task.results[agentResultIndex].proofHash = _proofHash;

        // If this is the first result, set verification deadline
        if (task.results.length == 1 && task.verificationDeadline == 0) {
             task.verificationDeadline = block.timestamp + taskVerificationPeriod;
        }

        bool allResultsSubmitted = true;
        for (uint256 i = 0; i < task.results.length; i++) {
            if (bytes(task.results[i].resultURI).length == 0) {
                allResultsSubmitted = false;
                break;
            }
        }

        if (allResultsSubmitted) {
            task.status = TaskStatus.ResultsSubmitted;
        }

        emit TaskResultSubmitted(_taskId, msg.sender, _resultURI, _proofHash);
    }

    /**
     * @dev Allows another agent or the task requester to dispute a submitted result.
     *      This triggers a dispute resolution process.
     * @param _taskId The ID of the task.
     * @param _agentResultIndex The index of the result in the task.results array to dispute.
     * @param _disputeReasonURI URI pointing to the detailed reason and evidence for the dispute.
     */
    function disputeTaskResult(uint256 _taskId, uint256 _agentResultIndex, string calldata _disputeReasonURI) external {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.ResultsSubmitted, "Task is not in results submitted phase");
        require(block.timestamp < task.verificationDeadline, "Verification deadline has passed");
        require(_agentResultIndex < task.results.length, "Invalid result index");
        require(!task.results[_agentResultIndex].disputed, "Result already disputed");
        require(bytes(_disputeReasonURI).length > 0, "Dispute reason URI cannot be empty");
        require(msg.sender != task.results[_agentResultIndex].agentAddress, "Cannot dispute your own result");
        require(msg.sender == task.requester || isAgent[msg.sender], "Only requester or registered agent can dispute");

        task.results[_agentResultIndex].disputed = true;
        task.disputeCount++;
        task.status = TaskStatus.Disputed; // Task moves to disputed state

        // Extend verification deadline if a new dispute is opened late in the period
        if (block.timestamp + 1 days > task.verificationDeadline) { // Example: add 1 day
             task.verificationDeadline = block.timestamp + 1 days;
        }

        emit TaskResultDisputed(_taskId, msg.sender, _agentResultIndex, _disputeReasonURI);
    }

    /**
     * @dev Finalizes a task, distributing bounties, updating reputation, and handling slashing.
     *      This function can be called by anyone after the verification deadline, or by owner/governance
     *      in case of complex dispute resolution.
     * @param _taskId The ID of the task to resolve.
     */
    function resolveTask(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.ResultsSubmitted || task.status == TaskStatus.Disputed, "Task is not in a resolvable state");
        require(block.timestamp >= task.verificationDeadline, "Verification period not over yet");
        
        // Simple consensus: results with matching proof hashes are considered correct
        // More advanced: external oracle or committee vote for dispute resolution
        uint256[] memory verifiedAgentIndices = new uint256[](task.results.length);
        uint256 verifiedCount = 0;
        uint256 maxMatches = 0;
        bytes32 winningProofHash = 0x0;

        // Determine the most common proof hash (simple majority for consensus)
        mapping(bytes32 => uint256) proofHashCounts;
        for (uint256 i = 0; i < task.results.length; i++) {
            if (!task.results[i].disputed && task.results[i].proofHash != 0x0) {
                proofHashCounts[task.results[i].proofHash]++;
                if (proofHashCounts[task.results[i].proofHash] > maxMatches) {
                    maxMatches = proofHashCounts[task.results[i].proofHash];
                    winningProofHash = task.results[i].proofHash;
                }
            }
        }
        
        // Mark results as verified/unverified based on consensus
        for (uint256 i = 0; i < task.results.length; i++) {
            if (task.results[i].proofHash == winningProofHash && maxMatches > 0 && !task.results[i].disputed) {
                task.results[i].verified = true;
                verifiedAgentIndices[verifiedCount++] = i;
            } else {
                task.results[i].verified = false; // Mark as incorrect if it doesn't match consensus or was disputed
            }
        }

        uint256 totalRewardableAgents = 0;
        uint256 totalReputationGain = 0; // sum of reputation gains for correct agents
        int256 totalReputationLoss = 0; // sum of reputation losses for incorrect agents
        uint256 totalStakeSlashed = 0;

        for (uint256 i = 0; i < task.results.length; i++) {
            address agentAddr = task.results[i].agentAddress;
            if (task.results[i].verified) {
                totalRewardableAgents++;
                // Positive reputation adjustment for correct result
                agentReputation[agentAddr] += 10; // Example: +10 rep points
                totalReputationGain += 10;
                agents[agentAddr].totalTasksCompleted++;
            } else {
                // Negative reputation adjustment for incorrect/disputed result
                int256 repLoss = int256(agents[agentAddr].stake * reputationPenaltyFactor / 10000); // e.g., 10% of stake
                agentReputation[agentAddr] -= repLoss;
                totalReputationLoss -= repLoss;

                // Slashing:
                uint256 slashAmount = agents[agentAddr].stake / 10; // Example: Slash 10% of stake
                if (slashAmount > 0) {
                    agents[agentAddr].stake -= slashAmount;
                    protocolFeesAccrued += slashAmount; // Slashed funds go to protocol fees
                    totalStakeSlashed += slashAmount;
                }
            }
        }

        uint256 bountyPerAgent = 0;
        uint256 protocolFee = task.bounty * protocolFeePercentage / 10000;
        uint256 availableBounty = task.bounty - protocolFee;
        protocolFeesAccrued += protocolFee;

        if (totalRewardableAgents > 0) {
            bountyPerAgent = availableBounty / totalRewardableAgents;
        }

        for (uint256 i = 0; i < verifiedCount; i++) {
            uint256 agentIdx = verifiedAgentIndices[i];
            task.results[agentIdx].paid = true; // Mark as paid, actual payment happens when agent claims
            // No direct transfer here. Agent claims rewards later.
        }

        task.status = TaskStatus.Resolved;
        emit TaskResolved(
            _taskId,
            TaskStatus.Resolved,
            availableBounty, // This is the amount paid to agents excluding protocol fees
            protocolFee
        );
        emit AgentReputationAdjusted(task.requester, agentReputation[task.requester], agentReputation[task.requester] + int256(totalReputationGain) + totalReputationLoss, int256(totalReputationGain) + totalReputationLoss); // Requester could also get rep adjusted
    }

    /**
     * @dev Retrieves the current reputation score of a specific agent.
     * @param _agentAddress The address of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(address _agentAddress) external view returns (int256) {
        return agentReputation[_agentAddress];
    }

    /**
     * @dev Allows the contract owner to manually adjust an agent's reputation.
     *      This can be used for significant off-chain events not covered by automated processes.
     * @param _agentAddress The address of the agent whose reputation is being adjusted.
     * @param _reputationDelta The amount to change the reputation by (can be negative).
     */
    function adjustReputation(address _agentAddress, int256 _reputationDelta) external onlyOwner {
        require(isAgent[_agentAddress], "Address is not a registered agent");
        int256 oldReputation = agentReputation[_agentAddress];
        agentReputation[_agentAddress] += _reputationDelta;
        emit AgentReputationAdjusted(_agentAddress, oldReputation, agentReputation[_agentAddress], _reputationDelta);
    }

    /**
     * @dev Allows an agent to claim their portion of the bounty for a successfully resolved task.
     * @param _taskId The ID of the task for which to claim bounty.
     */
    function claimTaskBounty(uint256 _taskId) external onlyRegisteredAgent {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Resolved, "Task is not yet resolved");

        uint256 agentIndex = type(uint256).max;
        for (uint256 i = 0; i < task.results.length; i++) {
            if (task.results[i].agentAddress == msg.sender) {
                agentIndex = i;
                break;
            }
        }
        require(agentIndex != type(uint256).max, "Caller did not participate in this task");
        require(task.results[agentIndex].verified, "Agent's result was not verified");
        require(!task.results[agentIndex].paid, "Bounty already claimed by this agent for this task");

        uint256 protocolFee = task.bounty * protocolFeePercentage / 10000;
        uint256 availableBounty = task.bounty - protocolFee;

        uint256 totalRewardableAgents = 0;
        for (uint256 i = 0; i < task.results.length; i++) {
            if (task.results[i].verified) {
                totalRewardableAgents++;
            }
        }
        require(totalRewardableAgents > 0, "No agents qualified for bounty."); // Should not happen if task is resolved successfully

        uint256 bountyPerAgent = availableBounty / totalRewardableAgents;
        task.results[agentIndex].paid = true;

        (bool success,) = msg.sender.call{value: bountyPerAgent}("");
        require(success, "Failed to send bounty to agent");

        emit TaskBountyClaimed(_taskId, msg.sender, bountyPerAgent);
    }

    /**
     * @dev Updates the minimum ETH stake required for new agents to register.
     * @param _newMinStake The new minimum stake amount in wei.
     */
    function setAgentMinStake(uint256 _newMinStake) external onlyOwner {
        require(_newMinStake > 0, "Minimum stake must be greater than zero");
        emit ParameterUpdated("minAgentStake", minAgentStake, _newMinStake);
        minAgentStake = _newMinStake;
    }

    /**
     * @dev Updates the percentage of task bounties collected as protocol fees.
     * @param _newFeePercentage The new fee percentage (e.g., 500 for 5%).
     */
    function setProtocolFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 10000, "Fee percentage cannot exceed 100%"); // Max 100%
        emit ParameterUpdated("protocolFeePercentage", protocolFeePercentage, _newFeePercentage);
        protocolFeePercentage = _newFeePercentage;
    }

    /**
     * @dev Adjusts the severity of reputation penalties for misconduct.
     * @param _newFactor The new multiplier for reputation loss.
     */
    function setReputationPenaltyFactor(uint256 _newFactor) external onlyOwner {
        emit ParameterUpdated("reputationPenaltyFactor", reputationPenaltyFactor, _newFactor);
        reputationPenaltyFactor = _newFactor;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner {
        require(protocolFeesAccrued > 0, "No fees accrued to withdraw");
        uint256 amount = protocolFeesAccrued;
        protocolFeesAccrued = 0;

        (bool success,) = owner.call{value: amount}("");
        require(success, "Failed to withdraw fees");

        emit ProtocolFeesWithdrawn(owner, amount);
    }

    // Fallback function to accept ETH (e.g., for task bounties)
    receive() external payable {}
}
```