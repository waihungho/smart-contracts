Here's a smart contract in Solidity that embodies several advanced, creative, and trendy concepts, focusing on a decentralized AI Agent Network for orchestrating complex tasks and user intents, complete with on-chain reputation, dispute resolution, and hints of off-chain verifiable computation.

---

## AI Agent Orchestrator: Smart Contract Outline & Function Summary

This contract, `AIAgentOrchestrator`, establishes a decentralized network for users to request complex, multi-step AI-driven tasks or high-level "intents." Agents register, stake tokens, and compete to fulfill these requests. The system incorporates on-chain reputation, modular task definition, and a robust dispute resolution mechanism, hinting at off-chain verifiable computation (e.g., ZK proofs) for result integrity.

### Outline:

1.  **Contract Core:** Imports, Custom Errors, State Variables.
2.  **Roles & Permissions:** Uses OpenZeppelin's `AccessControl` for granular permissions.
3.  **Pausability:** Emergency pause mechanism.
4.  **Data Structures:** Enums for statuses, Structs for Agents, TaskTypes, TaskRequests, and Intents.
5.  **Constructor:** Initializes core roles and dependencies.
6.  **Admin & Configuration Functions:**
    *   Setting the bounty token.
    *   Managing roles.
    *   Pausability controls.
    *   Emergency withdrawal.
7.  **Agent Management Functions:**
    *   Registration/Deregistration (with staking).
    *   Profile updates.
    *   Stake slashing for misconduct.
    *   Querying agent info.
8.  **Task Type Definition Functions:**
    *   Admin-defined templates for various AI tasks.
    *   Specification of verification mechanisms.
9.  **User Request & Intent Orchestration Functions:**
    *   Creating single task requests.
    *   Defining multi-step "intents" that link multiple tasks.
    *   Canceling pending requests.
    *   Querying task/intent status.
10. **Agent Task Execution & Verification Functions:**
    *   Assigning tasks to agents.
    *   Agent submission of off-chain results (with proof hashes).
    *   Verification decisions by designated verifiers or consensus.
11. **Dispute Resolution Functions:**
    *   Mechanism for users/agents to dispute results.
    *   Admin/governance resolution of disputes.
12. **Reward & Reputation Functions:**
    *   Agent claiming bounties.
    *   Internal reputation updates based on performance.
    *   Querying agent reputation.

### Function Summary (Total: 25 Functions):

**I. Core & Setup (Access Control, Pausability, Token)**
1.  `constructor(address initialBountyToken, address defaultAdmin)`: Initializes the contract with the ERC-20 bounty token address and sets the initial admin.
2.  `setBountyToken(address _newBountyToken)`: Admin can update the ERC-20 token used for bounties.
3.  `grantRole(bytes32 role, address account)`: Grants a specified role to an account (e.g., `VERIFIER_ROLE`, `TASK_ORCHESTRATOR_ROLE`).
4.  `revokeRole(bytes32 role, address account)`: Revokes a specified role from an account.
5.  `pauseContract()`: Admin pauses the contract, preventing most state-changing operations.
6.  `unpauseContract()`: Admin unpauses the contract.

**II. Agent Management (Staking & Profile)**
7.  `registerAgent(uint256 _stakeAmount, string calldata _profileIPFSHash)`: Allows an EOA to register as an AI agent by staking `_stakeAmount` of the bounty token and providing an IPFS hash for their capabilities/profile.
8.  `deregisterAgent()`: Allows an agent to deregister and withdraw their stake, provided they have no active or pending tasks.
9.  `updateAgentProfileHash(string calldata _newProfileIPFSHash)`: Allows a registered agent to update the IPFS hash pointing to their capabilities or profile metadata.
10. `slashAgentStake(address _agent, uint256 _amount, string calldata _reason)`: The `GOVERNOR_ROLE` or `ADMIN_ROLE` can slash an agent's stake due to severe misconduct, distributing the slashed funds to the treasury.

**III. Task Type Definition (Admin/Governance)**
11. `defineTaskType(string calldata _name, string calldata _description, VerificationMechanism _verificationMechanism, uint256 _maxBounty)`: The `ADMIN_ROLE` defines a new type of AI task (e.g., "Image Captioning", "ZK Proof Generation") specifying its name, description, how its results are verified, and the maximum allowed bounty.
12. `updateTaskTypeVerificationMechanism(uint256 _taskTypeId, VerificationMechanism _newMechanism)`: The `ADMIN_ROLE` can update the verification mechanism for an existing task type.

**IV. User Task Request & Intent Orchestration**
13. `createTaskRequest(uint256 _taskTypeId, string calldata _parametersIPFSHash, uint256 _bounty, uint256 _deadline)`: A user requests a specific AI task by providing the task type ID, an IPFS hash of task-specific parameters, the bounty offered, and a deadline. The bounty is transferred to the contract.
14. `createIntent(string calldata _intentDescription, uint256[] calldata _taskTypeIds, string[] calldata _parametersIPFSHashes, uint256[] calldata _bounties, uint256[] calldata _deadlines)`: A user defines a high-level "intent" (e.g., "Analyze X, then summarize Y, then translate Z") which automatically generates a sequence of linked `TaskRequest`s. This is a core advanced feature.
15. `cancelTaskRequest(uint256 _taskId)`: The creator of a task request can cancel it if it has not yet been assigned to an agent, reclaiming their bounty.

**V. Agent Task Execution & Verification**
16. `assignTaskToAgent(uint256 _taskId, address _agentAddress)`: The `TASK_ORCHESTRATOR_ROLE` or an automated system assigns an open task to a specific registered agent.
17. `submitTaskResult(uint256 _taskId, bytes32 _resultHash, bytes32 _proofHash)`: The assigned agent submits the hash of their off-chain computation result and an optional cryptographic proof hash (e.g., ZK proof commitment) for the task.
18. `submitVerificationDecision(uint256 _taskId, bool _isVerified, string calldata _reason)`: A designated `VERIFIER_ROLE` or an automated system (for `CONSENSUS_VERIFICATION`) marks a submitted task result as `VERIFIED` or `REJECTED`, updating the agent's reputation.

**VI. Dispute & Resolution**
19. `disputeTaskResult(uint256 _taskId, string calldata _reason)`: Any user, agent, or verifier can dispute a submitted task result, locking its status until resolution.
20. `resolveDispute(uint256 _taskId, DisputeOutcome _outcome, uint256 _slashedAmount, address _recipient)`: The `GOVERNOR_ROLE` or `ADMIN_ROLE` resolves a disputed task, determining the `_outcome`, potentially `_slashedAmount` from the agent's stake, and `_recipient` of the slashed funds (e.g., treasury, disputer). This impacts reputation.

**VII. Rewards & Reputation**
21. `claimTaskBounty(uint256 _taskId)`: An agent can claim their bounty after their assigned task has been successfully `VERIFIED` and all conditions met.
22. `getAgentReputation(address _agent)`: View function to query the current reputation score of a specific agent.

**VIII. View Functions (Read-only)**
23. `getAgentInfo(address _agent)`: Returns detailed information about a registered agent.
24. `getTaskRequestDetails(uint256 _taskId)`: Returns details about a specific task request, including its status and assigned agent.
25. `getIntentStatus(uint256 _intentId)`: Returns the current status of an intent, including the completion status of its constituent tasks.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AIAgentOrchestrator
 * @dev A decentralized platform for orchestrating AI agent tasks and user intents.
 *      Agents register, stake tokens, and fulfill task requests. The contract
 *      features on-chain reputation, modular task definitions, and dispute resolution.
 *      It supports complex "intents" composed of multiple linked tasks and hints
 *      at off-chain verifiable computation (e.g., ZK proofs).
 */
contract AIAgentOrchestrator is AccessControl, Pausable, ReentrancyGuard {

    // --- Custom Errors ---
    error InvalidBountyAmount();
    error AgentAlreadyRegistered();
    error AgentNotRegistered();
    error AgentHasActiveTasks();
    error TaskTypeNotFound();
    error TaskRequestNotFound();
    error TaskNotPending();
    error TaskAlreadyAssigned();
    error TaskNotAssignedToAgent();
    error TaskAlreadyResultSubmitted();
    error TaskResultNotSubmitted();
    error TaskAlreadyVerified();
    error TaskAlreadyDisputed();
    error TaskNotDisputed();
    error DeadlinePassed();
    error InsufficientStake();
    error UnauthorizedAction();
    error InvalidVerificationMechanism();
    error IntentCreationMismatch();
    error InvalidDisputeOutcome();

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // For dispute resolution, parameter changes
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE"); // Can submit verification decisions
    bytes32 public constant TASK_ORCHESTRATOR_ROLE = keccak256("TASK_ORCHESTRATOR_ROLE"); // Can assign tasks to agents

    // --- State Variables ---
    IERC20 public bountyToken; // The ERC-20 token used for bounties and staking

    uint256 private nextAgentId = 1;
    uint256 private nextTaskTypeId = 1;
    uint256 private nextTaskId = 1;
    uint256 private nextIntentId = 1;

    // --- Enums ---
    enum TaskStatus {
        PENDING,       // Task requested, awaiting assignment
        ASSIGNED,      // Task assigned to an agent
        RESULT_SUBMITTED, // Agent submitted result, awaiting verification
        VERIFIED,      // Result verified, agent can claim bounty
        REJECTED,      // Result rejected, agent penalized
        DISPUTED,      // Result disputed, awaiting resolution
        RESOLVED,      // Dispute resolved
        CANCELLED      // Task cancelled by requester
    }

    enum VerificationMechanism {
        MANUAL_VERIFICATION,    // Requires a VERIFIER_ROLE to approve/reject
        CONSENSUS_VERIFICATION, // Requires multiple VERIFIER_ROLEs or other agents to reach consensus (simplified here)
        ZK_PROOF_VERIFICATION   // Expects a ZK proof hash that can be verified off-chain
    }

    enum DisputeOutcome {
        INVALID_DISPUTE_CLAIM, // Dispute was unfounded
        AGENT_GUILTY,          // Agent found guilty, penalize
        AGENT_INNOCENT         // Agent found innocent, reward
    }

    // --- Structs ---

    struct Agent {
        uint256 id;
        uint256 stake;             // Amount of bountyToken staked
        string profileIPFSHash;    // IPFS hash pointing to agent's capabilities/metadata
        uint256 reputationScore;   // On-chain reputation score
        bool isActive;             // True if registered and active
        uint256[] assignedTasks;   // List of task IDs assigned to this agent
    }

    struct TaskType {
        uint256 id;
        string name;
        string description;
        VerificationMechanism verificationMechanism;
        uint256 maxBounty;
        bool exists; // To check if a task type ID is valid
    }

    struct TaskRequest {
        uint256 id;
        uint256 taskTypeId;
        address requester;
        address assignedAgent;     // 0x0 if not assigned
        uint256 bounty;
        uint256 creationTime;
        uint256 deadline;
        string parametersIPFSHash; // IPFS hash for task-specific input parameters
        bytes32 resultHash;        // Hash of the off-chain result submitted by agent
        bytes32 proofHash;         // Optional hash of a ZK proof or other cryptographic proof
        TaskStatus status;
        uint256 intentId;          // 0 if not part of an intent
    }

    struct Intent {
        uint256 id;
        address creator;
        string description;
        uint256[] taskIds;         // List of TaskRequest IDs that comprise this intent
        uint256 creationTime;
        uint256 completedTasksCount; // How many constituent tasks are completed
        bool isCompleted;
    }

    // --- Mappings ---
    mapping(address => Agent) public agents;
    mapping(uint256 => TaskType) public taskTypes;
    mapping(uint256 => TaskRequest) public taskRequests;
    mapping(uint256 => Intent) public intents;
    mapping(address => uint256) public agentAddressToId; // For quick lookup of agent ID

    // --- Events ---
    event AgentRegistered(address indexed agentAddress, uint256 agentId, uint256 stakeAmount);
    event AgentDeregistered(address indexed agentAddress, uint256 agentId, uint256 returnedStake);
    event AgentProfileUpdated(address indexed agentAddress, uint256 agentId, string newProfileIPFSHash);
    event AgentStakeSlashed(address indexed agentAddress, uint256 agentId, uint256 amount, string reason);
    event TaskTypeDefined(uint256 indexed taskTypeId, string name, VerificationMechanism verificationMechanism, uint256 maxBounty);
    event TaskTypeVerificationMechanismUpdated(uint256 indexed taskTypeId, VerificationMechanism newMechanism);
    event TaskRequestCreated(uint256 indexed taskId, uint256 taskTypeId, address indexed requester, uint256 bounty, uint256 deadline);
    event IntentCreated(uint256 indexed intentId, address indexed creator, string description, uint256[] taskIds);
    event TaskRequestCancelled(uint256 indexed taskId, address indexed requester);
    event TaskAssigned(uint256 indexed taskId, uint256 taskTypeId, address indexed agentAddress);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed agentAddress, bytes32 resultHash, bytes32 proofHash);
    event TaskVerificationDecision(uint256 indexed taskId, bool isVerified, address indexed decisionMaker, string reason);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, string reason);
    event DisputeResolved(uint256 indexed taskId, DisputeOutcome outcome, uint256 slashedAmount, address indexed recipient);
    event BountyClaimed(uint256 indexed taskId, address indexed agentAddress, uint256 amount);
    event AgentReputationUpdated(address indexed agentAddress, uint256 newReputation);

    // --- Constructor ---
    /**
     * @dev Constructor to initialize the contract with the bounty token and set the initial admin.
     * @param initialBountyToken The address of the ERC-20 token used for bounties and staking.
     * @param defaultAdmin The address of the initial administrator.
     */
    constructor(address initialBountyToken, address defaultAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(ADMIN_ROLE, defaultAdmin); // Grant specific ADMIN_ROLE
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(GOVERNOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(VERIFIER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(TASK_ORCHESTRATOR_ROLE, ADMIN_ROLE);
        bountyToken = IERC20(initialBountyToken);
    }

    // --- Admin & Configuration Functions ---

    /**
     * @dev Admin can update the ERC-20 token used for bounties and staking.
     * @param _newBountyToken The address of the new ERC-20 token.
     */
    function setBountyToken(address _newBountyToken) public onlyRole(ADMIN_ROLE) {
        bountyToken = IERC20(_newBountyToken);
    }

    /**
     * @dev Grants a specified role to an account.
     * @param role The role to grant (e.g., VERIFIER_ROLE, TASK_ORCHESTRATOR_ROLE).
     * @param account The address to grant the role to.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    /**
     * @dev Revokes a specified role from an account.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    /**
     * @dev Admin pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Admin unpauses the contract.
     */
    function unpauseContract() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Admin can withdraw excess ETH from the contract.
     *      No ETH is expected, but good for safety.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawEther(uint256 _amount) public onlyRole(ADMIN_ROLE) {
        if (_amount == 0) revert InvalidBountyAmount(); // Reusing error
        payable(msg.sender).transfer(_amount);
    }

    // --- Agent Management Functions ---

    /**
     * @dev Allows an EOA to register as an AI agent by staking bounty tokens and providing an IPFS hash for their capabilities.
     * @param _stakeAmount The amount of bountyToken to stake.
     * @param _profileIPFSHash IPFS hash pointing to agent's capabilities/metadata.
     */
    function registerAgent(uint256 _stakeAmount, string calldata _profileIPFSHash) public whenNotPaused {
        if (agents[msg.sender].isActive) revert AgentAlreadyRegistered();
        if (_stakeAmount == 0) revert InvalidBountyAmount();

        // Transfer stake from agent to contract
        bool success = bountyToken.transferFrom(msg.sender, address(this), _stakeAmount);
        if (!success) revert InsufficientStake();

        agents[msg.sender] = Agent({
            id: nextAgentId,
            stake: _stakeAmount,
            profileIPFSHash: _profileIPFSHash,
            reputationScore: 100, // Initial reputation
            isActive: true,
            assignedTasks: new uint256[](0)
        });
        agentAddressToId[msg.sender] = nextAgentId;
        nextAgentId++;

        emit AgentRegistered(msg.sender, agents[msg.sender].id, _stakeAmount);
    }

    /**
     * @dev Allows an agent to deregister and withdraw their stake, provided they have no active or pending tasks.
     */
    function deregisterAgent() public whenNotPaused nonReentrant {
        Agent storage agent = agents[msg.sender];
        if (!agent.isActive) revert AgentNotRegistered();
        if (agent.assignedTasks.length > 0) revert AgentHasActiveTasks(); // For simplicity, no pending tasks

        uint256 stakeToReturn = agent.stake;
        agent.stake = 0;
        agent.isActive = false;
        agent.reputationScore = 0; // Reset reputation
        delete agentAddressToId[msg.sender]; // Remove mapping entry

        bool success = bountyToken.transfer(msg.sender, stakeToReturn);
        if (!success) revert InsufficientStake(); // Should not happen if stake is there

        emit AgentDeregistered(msg.sender, agent.id, stakeToReturn);
    }

    /**
     * @dev Allows a registered agent to update the IPFS hash pointing to their capabilities or profile metadata.
     * @param _newProfileIPFSHash The new IPFS hash for the agent's profile.
     */
    function updateAgentProfileHash(string calldata _newProfileIPFSHash) public whenNotPaused {
        Agent storage agent = agents[msg.sender];
        if (!agent.isActive) revert AgentNotRegistered();

        agent.profileIPFSHash = _newProfileIPFSHash;
        emit AgentProfileUpdated(msg.sender, agent.id, _newProfileIPFSHash);
    }

    /**
     * @dev The GOVERNOR_ROLE or ADMIN_ROLE can slash an agent's stake due to severe misconduct.
     *      Slashed funds are kept in the contract (e.g., for treasury or redistribution).
     * @param _agent The address of the agent whose stake is to be slashed.
     * @param _amount The amount of bountyToken to slash from the agent's stake.
     * @param _reason A description for why the stake was slashed.
     */
    function slashAgentStake(address _agent, uint256 _amount, string calldata _reason) public onlyRole(GOVERNOR_ROLE) whenNotPaused {
        Agent storage agent = agents[_agent];
        if (!agent.isActive) revert AgentNotRegistered();
        if (agent.stake < _amount) revert InsufficientStake();

        agent.stake -= _amount;
        // Optionally decrease reputation significantly
        if (agent.reputationScore >= 50) { // Ensure it doesn't underflow
            agent.reputationScore -= 50;
        } else {
            agent.reputationScore = 0;
        }
        emit AgentReputationUpdated(_agent, agent.reputationScore);
        emit AgentStakeSlashed(_agent, agent.id, _amount, _reason);
    }

    // --- Task Type Definition Functions ---

    /**
     * @dev The ADMIN_ROLE defines a new type of AI task, specifying its name, description,
     *      how its results are verified, and the maximum allowed bounty.
     * @param _name Name of the task type (e.g., "Image Classification").
     * @param _description Description of the task type.
     * @param _verificationMechanism The method used to verify task results.
     * @param _maxBounty The maximum bounty allowed for this task type.
     */
    function defineTaskType(
        string calldata _name,
        string calldata _description,
        VerificationMechanism _verificationMechanism,
        uint256 _maxBounty
    ) public onlyRole(ADMIN_ROLE) whenNotPaused {
        taskTypes[nextTaskTypeId] = TaskType({
            id: nextTaskTypeId,
            name: _name,
            description: _description,
            verificationMechanism: _verificationMechanism,
            maxBounty: _maxBounty,
            exists: true
        });
        emit TaskTypeDefined(nextTaskTypeId, _name, _verificationMechanism, _maxBounty);
        nextTaskTypeId++;
    }

    /**
     * @dev The ADMIN_ROLE can update the verification mechanism for an existing task type.
     * @param _taskTypeId The ID of the task type to update.
     * @param _newMechanism The new verification mechanism.
     */
    function updateTaskTypeVerificationMechanism(uint256 _taskTypeId, VerificationMechanism _newMechanism) public onlyRole(ADMIN_ROLE) whenNotPaused {
        TaskType storage taskType = taskTypes[_taskTypeId];
        if (!taskType.exists) revert TaskTypeNotFound();

        taskType.verificationMechanism = _newMechanism;
        emit TaskTypeVerificationMechanismUpdated(_taskTypeId, _newMechanism);
    }

    // --- User Request & Intent Orchestration Functions ---

    /**
     * @dev A user requests a specific AI task, providing parameters (IPFS hash), bounty, and a deadline.
     *      The bounty is transferred from the user to the contract.
     * @param _taskTypeId The ID of the predefined task type.
     * @param _parametersIPFSHash IPFS hash for task-specific input parameters.
     * @param _bounty The amount of bountyToken offered for this task.
     * @param _deadline Unix timestamp for the task completion deadline.
     */
    function createTaskRequest(
        uint256 _taskTypeId,
        string calldata _parametersIPFSHash,
        uint256 _bounty,
        uint256 _deadline
    ) public whenNotPaused {
        TaskType storage taskType = taskTypes[_taskTypeId];
        if (!taskType.exists) revert TaskTypeNotFound();
        if (_bounty == 0 || _bounty > taskType.maxBounty) revert InvalidBountyAmount();
        if (_deadline <= block.timestamp) revert DeadlinePassed();

        // Transfer bounty from requester to contract
        bool success = bountyToken.transferFrom(msg.sender, address(this), _bounty);
        if (!success) revert InsufficientStake(); // Reusing error for transfer failure

        taskRequests[nextTaskId] = TaskRequest({
            id: nextTaskId,
            taskTypeId: _taskTypeId,
            requester: msg.sender,
            assignedAgent: address(0),
            bounty: _bounty,
            creationTime: block.timestamp,
            deadline: _deadline,
            parametersIPFSHash: _parametersIPFSHash,
            resultHash: bytes32(0),
            proofHash: bytes32(0),
            status: TaskStatus.PENDING,
            intentId: 0
        });

        emit TaskRequestCreated(nextTaskId, _taskTypeId, msg.sender, _bounty, _deadline);
        nextTaskId++;
    }

    /**
     * @dev A user defines a high-level "intent" which automatically generates a sequence of linked TaskRequests.
     *      This is a core advanced feature for multi-step AI orchestration.
     * @param _intentDescription A general description of the intent.
     * @param _taskTypeIds An array of task type IDs for the sequence.
     * @param _parametersIPFSHashes An array of IPFS hashes for parameters for each task.
     * @param _bounties An array of bounties for each task.
     * @param _deadlines An array of deadlines for each task.
     */
    function createIntent(
        string calldata _intentDescription,
        uint256[] calldata _taskTypeIds,
        string[] calldata _parametersIPFSHashes,
        uint256[] calldata _bounties,
        uint256[] calldata _deadlines
    ) public whenNotPaused {
        if (_taskTypeIds.length == 0 ||
            _taskTypeIds.length != _parametersIPFSHashes.length ||
            _taskTypeIds.length != _bounties.length ||
            _taskTypeIds.length != _deadlines.length) {
            revert IntentCreationMismatch();
        }

        uint256 currentIntentId = nextIntentId++;
        uint256[] memory newTasksIds = new uint256[](_taskTypeIds.length);
        uint256 totalBounty = 0;

        for (uint i = 0; i < _taskTypeIds.length; i++) {
            TaskType storage taskType = taskTypes[_taskTypeIds[i]];
            if (!taskType.exists) revert TaskTypeNotFound();
            if (_bounties[i] == 0 || _bounties[i] > taskType.maxBounty) revert InvalidBountyAmount();
            if (_deadlines[i] <= block.timestamp) revert DeadlinePassed();

            totalBounty += _bounties[i];

            taskRequests[nextTaskId] = TaskRequest({
                id: nextTaskId,
                taskTypeId: _taskTypeIds[i],
                requester: msg.sender,
                assignedAgent: address(0),
                bounty: _bounties[i],
                creationTime: block.timestamp,
                deadline: _deadlines[i],
                parametersIPFSHash: _parametersIPFSHashes[i],
                resultHash: bytes32(0),
                proofHash: bytes32(0),
                status: TaskStatus.PENDING,
                intentId: currentIntentId
            });
            newTasksIds[i] = nextTaskId;
            nextTaskId++;
        }

        // Transfer total bounty for all tasks in the intent
        bool success = bountyToken.transferFrom(msg.sender, address(this), totalBounty);
        if (!success) revert InsufficientStake();

        intents[currentIntentId] = Intent({
            id: currentIntentId,
            creator: msg.sender,
            description: _intentDescription,
            taskIds: newTasksIds,
            creationTime: block.timestamp,
            completedTasksCount: 0,
            isCompleted: false
        });

        emit IntentCreated(currentIntentId, msg.sender, _intentDescription, newTasksIds);
    }

    /**
     * @dev The creator of a task request can cancel it if it has not yet been assigned to an agent,
     *      reclaiming their bounty.
     * @param _taskId The ID of the task request to cancel.
     */
    function cancelTaskRequest(uint256 _taskId) public whenNotPaused nonReentrant {
        TaskRequest storage task = taskRequests[_taskId];
        if (task.requester != msg.sender) revert UnauthorizedAction();
        if (task.status != TaskStatus.PENDING) revert TaskNotPending();
        if (task.deadline <= block.timestamp) revert DeadlinePassed(); // Only allow cancellation before deadline

        task.status = TaskStatus.CANCELLED;
        // Return bounty to requester
        bool success = bountyToken.transfer(task.requester, task.bounty);
        if (!success) revert InsufficientStake(); // Should not happen if bounty is held

        emit TaskRequestCancelled(_taskId, msg.sender);
    }

    // --- Agent Task Execution & Verification Functions ---

    /**
     * @dev The TASK_ORCHESTRATOR_ROLE (or an automated system) assigns an open task to a specific registered agent.
     * @param _taskId The ID of the task request to assign.
     * @param _agentAddress The address of the agent to assign the task to.
     */
    function assignTaskToAgent(uint256 _taskId, address _agentAddress) public onlyRole(TASK_ORCHESTRATOR_ROLE) whenNotPaused {
        TaskRequest storage task = taskRequests[_taskId];
        if (task.id == 0) revert TaskRequestNotFound();
        if (task.status != TaskStatus.PENDING) revert TaskNotPending();
        if (task.deadline <= block.timestamp) revert DeadlinePassed();

        Agent storage agent = agents[_agentAddress];
        if (!agent.isActive) revert AgentNotRegistered();
        if (task.assignedAgent != address(0)) revert TaskAlreadyAssigned();

        task.assignedAgent = _agentAddress;
        task.status = TaskStatus.ASSIGNED;
        agent.assignedTasks.push(_taskId);

        emit TaskAssigned(_taskId, task.taskTypeId, _agentAddress);
    }

    /**
     * @dev The assigned agent submits the hash of their off-chain computation result and an optional
     *      cryptographic proof hash (e.g., ZK proof commitment) for the task.
     * @param _taskId The ID of the task.
     * @param _resultHash The hash of the off-chain result.
     * @param _proofHash An optional hash of a ZK proof or other cryptographic proof.
     */
    function submitTaskResult(uint256 _taskId, bytes32 _resultHash, bytes32 _proofHash) public whenNotPaused {
        TaskRequest storage task = taskRequests[_taskId];
        if (task.id == 0) revert TaskRequestNotFound();
        if (task.assignedAgent != msg.sender) revert TaskNotAssignedToAgent();
        if (task.status != TaskStatus.ASSIGNED) revert TaskAlreadyResultSubmitted(); // Check for correct status
        if (task.deadline <= block.timestamp) revert DeadlinePassed();

        task.resultHash = _resultHash;
        task.proofHash = _proofHash; // Can be 0 if no proof is expected
        task.status = TaskStatus.RESULT_SUBMITTED;

        emit TaskResultSubmitted(_taskId, msg.sender, _resultHash, _proofHash);
    }

    /**
     * @dev A designated VERIFIER_ROLE or an automated system marks a submitted task result as VERIFIED or REJECTED.
     *      This updates the agent's reputation.
     * @param _taskId The ID of the task to verify.
     * @param _isVerified True if the result is verified, false if rejected.
     * @param _reason A string describing the verification outcome.
     */
    function submitVerificationDecision(uint256 _taskId, bool _isVerified, string calldata _reason) public onlyRole(VERIFIER_ROLE) whenNotPaused {
        TaskRequest storage task = taskRequests[_taskId];
        if (task.id == 0) revert TaskRequestNotFound();
        if (task.status != TaskStatus.RESULT_SUBMITTED) revert TaskResultNotSubmitted();
        if (task.deadline <= block.timestamp) revert DeadlinePassed(); // Should be verified before or shortly after deadline

        address agentAddress = task.assignedAgent;
        Agent storage agent = agents[agentAddress];

        task.status = _isVerified ? TaskStatus.VERIFIED : TaskStatus.REJECTED;

        // Update agent reputation based on verification
        _updateAgentReputation(agentAddress, _isVerified);

        // If part of an intent, update intent status
        if (task.intentId != 0) {
            Intent storage intent = intents[task.intentId];
            if (_isVerified) {
                intent.completedTasksCount++;
                if (intent.completedTasksCount == intent.taskIds.length) {
                    intent.isCompleted = true;
                }
            } else {
                // If any task in an intent is rejected, the whole intent might be considered failed
                // Or require re-assignment. For simplicity, we just mark task rejected.
            }
        }

        emit TaskVerificationDecision(_taskId, _isVerified, msg.sender, _reason);
    }

    // --- Dispute & Resolution Functions ---

    /**
     * @dev Any user, agent, or verifier can dispute a submitted task result, locking its status until resolution.
     * @param _taskId The ID of the task to dispute.
     * @param _reason A description for why the result is being disputed.
     */
    function disputeTaskResult(uint256 _taskId, string calldata _reason) public whenNotPaused {
        TaskRequest storage task = taskRequests[_taskId];
        if (task.id == 0) revert TaskRequestNotFound();
        if (task.status != TaskStatus.RESULT_SUBMITTED) revert TaskResultNotSubmitted(); // Can only dispute submitted results
        if (task.status == TaskStatus.DISPUTED) revert TaskAlreadyDisputed();
        if (msg.sender == task.assignedAgent) revert UnauthorizedAction(); // Agent cannot dispute their own task

        task.status = TaskStatus.DISPUTED;
        // Potentially lock agent's stake or part of it here to cover potential penalties

        emit TaskDisputed(_taskId, msg.sender, _reason);
    }

    /**
     * @dev The GOVERNOR_ROLE or ADMIN_ROLE resolves a disputed task, determining the outcome,
     *      potentially slashing an amount from the agent's stake, and specifying the recipient
     *      of any slashed funds (e.g., treasury, disputer).
     * @param _taskId The ID of the disputed task.
     * @param _outcome The outcome of the dispute (e.g., AGENT_GUILTY, AGENT_INNOCENT).
     * @param _slashedAmount The amount of bountyToken to slash from the agent's stake (0 if none).
     * @param _recipient The address to send the slashed funds to (address(0) if to contract treasury).
     */
    function resolveDispute(
        uint256 _taskId,
        DisputeOutcome _outcome,
        uint256 _slashedAmount,
        address _recipient
    ) public onlyRole(GOVERNOR_ROLE) whenNotPaused nonReentrant {
        TaskRequest storage task = taskRequests[_taskId];
        if (task.id == 0) revert TaskRequestNotFound();
        if (task.status != TaskStatus.DISPUTED) revert TaskNotDisputed();

        address agentAddress = task.assignedAgent;
        Agent storage agent = agents[agentAddress];

        if (_outcome == DisputeOutcome.AGENT_GUILTY) {
            task.status = TaskStatus.REJECTED;
            _updateAgentReputation(agentAddress, false); // Agent's reputation decreases

            if (_slashedAmount > 0) {
                if (agent.stake < _slashedAmount) revert InsufficientStake();
                agent.stake -= _slashedAmount;

                if (_recipient != address(0)) {
                    bool success = bountyToken.transfer(_recipient, _slashedAmount);
                    if (!success) revert InsufficientStake(); // Should not happen
                } else {
                    // Slashed funds remain in contract treasury
                }
            }
            // Bounty funds remain in contract (not released to agent)
        } else if (_outcome == DisputeOutcome.AGENT_INNOCENT || _outcome == DisputeOutcome.INVALID_DISPUTE_CLAIM) {
            task.status = TaskStatus.VERIFIED;
            _updateAgentReputation(agentAddress, true); // Agent's reputation potentially increases
            // Bounty funds become claimable by agent
        } else {
            revert InvalidDisputeOutcome();
        }

        // If part of an intent, update intent status
        if (task.intentId != 0) {
            Intent storage intent = intents[task.intentId];
            if (task.status == TaskStatus.VERIFIED) {
                intent.completedTasksCount++;
                if (intent.completedTasksCount == intent.taskIds.length) {
                    intent.isCompleted = true;
                }
            }
        }

        emit DisputeResolved(_taskId, _outcome, _slashedAmount, _recipient);
    }

    // --- Reward & Reputation Functions ---

    /**
     * @dev An agent can claim their earned bounty after their assigned task has been successfully VERIFIED.
     * @param _taskId The ID of the task for which to claim bounty.
     */
    function claimTaskBounty(uint256 _taskId) public whenNotPaused nonReentrant {
        TaskRequest storage task = taskRequests[_taskId];
        if (task.id == 0) revert TaskRequestNotFound();
        if (task.assignedAgent != msg.sender) revert TaskNotAssignedToAgent();
        if (task.status != TaskStatus.VERIFIED) revert TaskAlreadyVerified(); // Already claimed or not verified yet

        task.status = TaskStatus.RESOLVED; // Mark as resolved after bounty claimed
        bool success = bountyToken.transfer(msg.sender, task.bounty);
        if (!success) revert InsufficientStake(); // Should not happen if bounty is held

        emit BountyClaimed(_taskId, msg.sender, task.bounty);
    }

    /**
     * @dev Internal function to update an agent's reputation score based on task outcomes.
     * @param _agentAddress The address of the agent.
     * @param _isSuccess True if the outcome was successful (verified), false if rejected/guilty.
     */
    function _updateAgentReputation(address _agentAddress, bool _isSuccess) internal {
        Agent storage agent = agents[_agentAddress];
        if (!agent.isActive) return;

        if (_isSuccess) {
            agent.reputationScore = agent.reputationScore + 10 > 200 ? 200 : agent.reputationScore + 10; // Max reputation 200
        } else {
            agent.reputationScore = agent.reputationScore > 20 ? agent.reputationScore - 20 : 0; // Min reputation 0
        }
        emit AgentReputationUpdated(_agentAddress, agent.reputationScore);
    }

    /**
     * @dev View function to query the current reputation score of a specific agent.
     * @param _agent The address of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(address _agent) public view returns (uint256) {
        return agents[_agent].reputationScore;
    }

    // --- View Functions (Read-only) ---

    /**
     * @dev Returns detailed information about a registered agent.
     * @param _agent The address of the agent.
     * @return Agent struct details.
     */
    function getAgentInfo(address _agent) public view returns (Agent memory) {
        return agents[_agent];
    }

    /**
     * @dev Returns details about a specific task request, including its status and assigned agent.
     * @param _taskId The ID of the task request.
     * @return TaskRequest struct details.
     */
    function getTaskRequestDetails(uint256 _taskId) public view returns (TaskRequest memory) {
        return taskRequests[_taskId];
    }

    /**
     * @dev Returns the current status of an intent, including the completion status of its constituent tasks.
     * @param _intentId The ID of the intent.
     * @return Intent struct details.
     */
    function getIntentStatus(uint256 _intentId) public view returns (Intent memory) {
        return intents[_intentId];
    }
}
```