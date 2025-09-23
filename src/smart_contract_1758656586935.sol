This smart contract outlines a "Decentralized Adaptive Agent Network" (DAAN) protocol, enabling users to deploy, manage, and interact with autonomous agents. These agents can acquire specialized skills, execute delegated tasks, and build a verifiable reputation on-chain. The protocol incorporates advanced concepts like simulated adaptive learning (via configuration updates), modular skill integration, a privacy-centric task result submission using hashes (implying off-chain ZKP or verification), agent-to-agent task delegation, and a robust data consent layer. The aim is to create a self-sovereign network where users control their agents and data.

---

## **AdaptiveAgentNetworkProtocol Smart Contract**

**Outline:**

1.  **Core Data Structures & State Variables:** Defines the fundamental structs for Agents, Skill Modules, Tasks, and Consent Records, along with their respective mappings and counters.
2.  **Events:** Declares events to signal significant state changes, aiding off-chain monitoring and indexing.
3.  **Error Handling:** Custom errors for more descriptive revert messages.
4.  **Modifiers:** Access control modifiers for administrative and ownership checks.
5.  **Admin & Protocol Governance (4 functions):** Manages protocol-level parameters and administrative actions.
6.  **Skill Module Management (4 functions):** Handles the proposal, approval, and assignment of specialized skill modules to agents.
7.  **Agent Lifecycle & Configuration (6 functions):** Covers the registration, updates, activation, deactivation, and ownership transfer of agents.
8.  **Task Delegation & Execution (8 functions):** Manages the entire lifecycle of tasks, from creation and assignment to result submission, verification, and potential disputes, including agent-to-agent delegation.
9.  **Data Consent & Privacy (3 functions):** Provides explicit on-chain consent management for agents accessing user data, enhancing privacy and user control.
10. **Agent Reputation & Staking (3 functions):** Implements a mechanism for agent owners to stake funds for reliability and for the protocol to manage reputation through slashing.

---

**Function Summary:**

**Admin & Protocol Governance:**

1.  `constructor(address _initialAdmin, address _protocolTokenAddress)`: Initializes the contract with an admin and the ERC20 token used for rewards/staking.
2.  `setProtocolAdmin(address _newAdmin)`: Transfers administrative control of the protocol.
3.  `setProtocolFee(uint256 _newFeeBasisPoints)`: Sets the percentage of task rewards taken as a protocol fee.
4.  `withdrawProtocolFees()`: Allows the protocol admin to withdraw accumulated fees.

**Skill Module Management:**

5.  `proposeSkillModule(string memory _name, string memory _description, bytes32 _verifierHash)`: Allows anyone to propose a new skill module with a unique verifier hash (e.g., a ZKP verifier address or a data schema hash).
6.  `approveSkillModule(bytes32 _skillId)`: Protocol admin approves a proposed skill, making it available for agents.
7.  `getSkillModuleDetails(bytes32 _skillId)`: Retrieves comprehensive details about a specific skill module.
8.  `assignSkillToAgent(bytes32 _agentId, bytes32 _skillId)`: Agent owner assigns an approved skill to their agent, expanding its capabilities.

**Agent Lifecycle & Configuration:**

9.  `registerAgent(string memory _name, string memory _configIPFSUri)`: Deploys a new Adaptive Agent, registering it under the `msg.sender`'s ownership. The `_configIPFSUri` can represent initial AI model parameters or operational logic.
10. `updateAgentConfig(bytes32 _agentId, string memory _newConfigIPFSUri)`: Agent owner updates their agent's configuration, simulating adaptive learning or parameter tuning based on performance.
11. `deactivateAgent(bytes32 _agentId)`: Agent owner temporarily deactivates their agent, preventing it from taking on new tasks.
12. `activateAgent(bytes32 _agentId)`: Agent owner reactivates their agent, allowing it to resume operations.
13. `transferAgentOwnership(bytes32 _agentId, address _newOwner)`: Transfers ownership of an agent to a new address.
14. `getAgentDetails(bytes32 _agentId)`: Retrieves all pertinent information about a specific agent.

**Task Delegation & Execution:**

15. `createTaskRequest(bytes32 _agentId, uint256 _reward, uint256 _deadline, string memory _taskDescriptionIPFSUri)`: Initiates a task request, offering a reward to a specific, pre-selected agent for a defined task.
16. `submitTaskResultHash(bytes32 _taskId, bytes32 _resultHash, string memory _proofIPFSUri)`: The assigned agent submits a cryptographic hash of the task result and a URI pointing to off-chain proof (e.g., ZKP proof).
17. `verifyTaskResultAndPay(bytes32 _taskId, bytes32 _expectedResultHash)`: The task creator verifies the task result off-chain against the submitted hash and, upon success, triggers payment to the agent.
18. `reportTaskFailure(bytes32 _taskId, string memory _reasonIPFSUri)`: Task creator reports an agent's failure to complete a task, potentially leading to reputation penalties or stake slashing.
19. `resolveTaskDispute(bytes32 _taskId, bool _agentWasSuccessful)`: Protocol admin resolves disputes concerning task failures, impacting agent reputation and potential stake slashes/releases.
20. `delegateSubTask(bytes32 _parentTaskId, bytes32 _delegatingAgentId, bytes32 _subAgentId, uint256 _subReward, uint256 _subDeadline, string memory _subTaskDescriptionIPFSUri)`: An agent, as part of a larger task, can delegate a sub-task to another agent, fostering a network of collaborative agents.
21. `submitSubTaskResultHash(bytes32 _subTaskId, bytes32 _resultHash, string memory _proofIPFSUri)`: The sub-agent submits the result for a delegated sub-task.
22. `verifySubTaskResultAndPay(bytes32 _subTaskId, bytes32 _expectedResultHash)`: The delegating agent verifies the sub-task result and pays the sub-agent.

**Data Consent & Privacy:**

23. `recordDataConsent(address _dataOwner, bytes32 _agentId, string memory _dataScopeIPFSUri, uint256 _expirationTimestamp)`: A user grants an agent explicit consent to access specific data (defined by `_dataScopeIPFSUri`) for a limited time.
24. `revokeDataConsent(address _dataOwner, bytes32 _agentId, string memory _dataScopeIPFSUri)`: A user revokes previously granted data consent for an agent and data scope.
25. `getConsentStatus(address _dataOwner, bytes32 _agentId, string memory _dataScopeIPFSUri)`: Checks the current consent status, including expiration, for an agent regarding a specific data scope.

**Agent Reputation & Staking:**

26. `stakeForAgentReliability(bytes32 _agentId, uint256 _amount)`: Agent owner stakes `_amount` of `protocolToken` to back their agent's reliability and reputation.
27. `withdrawAgentStake(bytes32 _agentId, uint256 _amount)`: Agent owner withdraws a specified amount from their agent's staked funds.
28. `slashAgentStake(bytes32 _agentId, uint256 _amount)`: Protocol admin slashes a specified amount from an agent's stake due to severe misconduct or repeated failures, impacting its reliability.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For unique ID generation if needed

// --- Outline ---
// 1. Core Data Structures & State Variables
// 2. Events
// 3. Error Handling
// 4. Modifiers
// 5. Admin & Protocol Governance (4 functions)
// 6. Skill Module Management (4 functions)
// 7. Agent Lifecycle & Configuration (6 functions)
// 8. Task Delegation & Execution (8 functions)
// 9. Data Consent & Privacy (3 functions)
// 10. Agent Reputation & Staking (3 functions)

// --- Function Summary ---

// Admin & Protocol Governance:
// 1. constructor(address _initialAdmin, address _protocolTokenAddress): Initializes the contract with an admin and the ERC20 token used for rewards/staking.
// 2. setProtocolAdmin(address _newAdmin): Transfers administrative control of the protocol.
// 3. setProtocolFee(uint256 _newFeeBasisPoints): Sets the percentage of task rewards taken as a protocol fee.
// 4. withdrawProtocolFees(): Allows the protocol admin to withdraw accumulated fees.

// Skill Module Management:
// 5. proposeSkillModule(string memory _name, string memory _description, bytes32 _verifierHash): Allows anyone to propose a new skill module with a unique verifier hash (e.g., a ZKP verifier address or a data schema hash).
// 6. approveSkillModule(bytes32 _skillId): Protocol admin approves a proposed skill, making it available for agents.
// 7. getSkillModuleDetails(bytes32 _skillId): Retrieves comprehensive details about a specific skill module.
// 8. assignSkillToAgent(bytes32 _agentId, bytes32 _skillId): Agent owner assigns an approved skill to their agent, expanding its capabilities.

// Agent Lifecycle & Configuration:
// 9. registerAgent(string memory _name, string memory _configIPFSUri): Deploys a new Adaptive Agent, registering it under the msg.sender's ownership. The _configIPFSUri can represent initial AI model parameters or operational logic.
// 10. updateAgentConfig(bytes32 _agentId, string memory _newConfigIPFSUri): Agent owner updates their agent's configuration, simulating adaptive learning or parameter tuning based on performance.
// 11. deactivateAgent(bytes32 _agentId): Agent owner temporarily deactivates their agent, preventing it from taking on new tasks.
// 12. activateAgent(bytes32 _agentId): Agent owner reactivates their agent, allowing it to resume operations.
// 13. transferAgentOwnership(bytes32 _agentId, address _newOwner): Transfers ownership of an agent to a new address.
// 14. getAgentDetails(bytes32 _agentId): Retrieves all pertinent information about a specific agent.

// Task Delegation & Execution:
// 15. createTaskRequest(bytes32 _agentId, uint256 _reward, uint256 _deadline, string memory _taskDescriptionIPFSUri): Initiates a task request, offering a reward to a specific, pre-selected agent for a defined task.
// 16. submitTaskResultHash(bytes32 _taskId, bytes32 _resultHash, string memory _proofIPFSUri): The assigned agent submits a cryptographic hash of the task result and a URI pointing to off-chain proof (e.g., ZKP proof).
// 17. verifyTaskResultAndPay(bytes32 _taskId, bytes32 _expectedResultHash): The task creator verifies the task result off-chain against the submitted hash and, upon success, triggers payment to the agent.
// 18. reportTaskFailure(bytes32 _taskId, string memory _reasonIPFSUri): Task creator reports an agent's failure to complete a task, potentially leading to reputation penalties or stake slashing.
// 19. resolveTaskDispute(bytes32 _taskId, bool _agentWasSuccessful): Protocol admin resolves disputes concerning task failures, impacting agent reputation and potential stake slashes/releases.
// 20. delegateSubTask(bytes32 _parentTaskId, bytes32 _delegatingAgentId, bytes32 _subAgentId, uint256 _subReward, uint256 _subDeadline, string memory _subTaskDescriptionIPFSUri): An agent, as part of a larger task, can delegate a sub-task to another agent, fostering a network of collaborative agents.
// 21. submitSubTaskResultHash(bytes32 _subTaskId, bytes32 _resultHash, string memory _proofIPFSUri): The sub-agent submits the result for a delegated sub-task.
// 22. verifySubTaskResultAndPay(bytes32 _subTaskId, bytes32 _expectedResultHash): The delegating agent verifies the sub-task result and pays the sub-agent.

// Data Consent & Privacy:
// 23. recordDataConsent(address _dataOwner, bytes32 _agentId, string memory _dataScopeIPFSUri, uint256 _expirationTimestamp): A user grants an agent explicit consent to access specific data (defined by _dataScopeIPFSUri) for a limited time.
// 24. revokeDataConsent(address _dataOwner, bytes32 _agentId, string memory _dataScopeIPFSUri): A user revokes previously granted data consent for an agent and data scope.
// 25. getConsentStatus(address _dataOwner, bytes32 _agentId, string memory _dataScopeIPFSUri): Checks the current consent status, including expiration, for an agent regarding a specific data scope.

// Agent Reputation & Staking:
// 26. stakeForAgentReliability(bytes32 _agentId, uint256 _amount): Agent owner stakes _amount of protocolToken to back their agent's reliability and reputation.
// 27. withdrawAgentStake(bytes32 _agentId, uint256 _amount): Agent owner withdraws a specified amount from their agent's staked funds.
// 28. slashAgentStake(bytes32 _agentId, uint256 _amount): Protocol admin slashes a specified amount from an agent's stake due to severe misconduct or repeated failures, impacting its reliability.

contract AdaptiveAgentNetworkProtocol is Ownable {
    // --- 1. Core Data Structures & State Variables ---

    IERC20 public immutable protocolToken; // The ERC20 token used for rewards and staking

    // Enum for Task Status
    enum TaskStatus {
        Pending, // Task requested but not yet assigned
        Executing, // Agent assigned and working
        ResultSubmitted, // Agent submitted result hash
        Verified, // Result verified, agent paid
        Failed, // Task failed by agent
        Disputed // Task failure reported, under dispute
    }

    // Struct for an Adaptive Agent
    struct Agent {
        address owner;
        string name;
        string configIPFSUri; // URI to agent's configuration/logic (simulated adaptive learning)
        bool isActive;
        int256 reputationScore; // Can be positive or negative
        uint256 stakedAmount; // Amount of protocolToken staked
        mapping(bytes32 => bool) assignedSkills; // Mapping of skillId to bool
        uint256 totalTasksCompleted;
        uint256 totalTasksFailed;
    }

    // Struct for a Skill Module
    struct SkillModule {
        string name;
        string description;
        bytes32 verifierHash; // Hash or address for off-chain verification logic/ZK-proof circuit
        bool isApproved; // Only approved skills can be assigned
        address proposer;
    }

    // Struct for a Task
    struct Task {
        address creator;
        bytes32 agentId;
        uint256 reward; // In protocolToken
        uint256 deadline;
        string descriptionIPFSUri; // URI to task description
        bytes32 resultHash; // Hash of the task result (privacy-preserving)
        string proofIPFSUri; // URI to off-chain proof (e.g., ZKP proof)
        TaskStatus status;
        bytes32 parentTaskId; // If this is a sub-task, points to its parent
        bytes32 subTaskId; // If this is a parent task, points to its sub-task (if delegated)
        bool isDisputed; // True if a failure was reported and admin needs to intervene
    }

    // Struct for Data Consent
    struct ConsentRecord {
        bytes32 agentId;
        string dataScopeIPFSUri; // URI describing the scope of data access
        uint256 expirationTimestamp;
        bool revoked;
    }

    // Mappings
    mapping(bytes32 => Agent) public agents;
    mapping(address => bytes32[]) public ownerAgents; // Track agents by owner
    uint256 private _agentNonce; // For unique agent IDs

    mapping(bytes32 => SkillModule) public skillModules;
    uint256 private _skillNonce; // For unique skill IDs

    mapping(bytes32 => Task) public tasks;
    uint256 private _taskNonce; // For unique task IDs

    // consentRecords[dataOwner][agentId][dataScopeIPFSUri hash] => ConsentRecord
    mapping(address => mapping(bytes32 => mapping(bytes32 => ConsentRecord)))
        public consentRecords;

    address public protocolAdmin; // Can be the same as Ownable owner, or a separate role
    uint256 public protocolFeeBasisPoints; // e.g., 500 for 5%
    uint256 public totalProtocolFees; // Accumulated fees

    // --- 2. Events ---
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event ProtocolFeeSet(uint256 newFeeBasisPoints);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    event AgentRegistered(bytes32 indexed agentId, address indexed owner, string name, string configIPFSUri);
    event AgentConfigUpdated(bytes32 indexed agentId, string newConfigIPFSUri);
    event AgentActivated(bytes32 indexed agentId);
    event AgentDeactivated(bytes32 indexed agentId);
    event AgentOwnershipTransferred(bytes32 indexed agentId, address indexed oldOwner, address indexed newOwner);
    event AgentReputationUpdated(bytes32 indexed agentId, int256 newReputation);
    event AgentStaked(bytes32 indexed agentId, uint256 amount);
    event AgentStakeWithdrawn(bytes32 indexed agentId, uint256 amount);
    event AgentStakeSlashed(bytes32 indexed agentId, uint256 amount, string reason);

    event SkillModuleProposed(bytes32 indexed skillId, string name, string description, address indexed proposer);
    event SkillModuleApproved(bytes32 indexed skillId);
    event SkillAssignedToAgent(bytes32 indexed agentId, bytes32 indexed skillId);

    event TaskRequestCreated(bytes32 indexed taskId, address indexed creator, bytes32 indexed agentId, uint256 reward, uint256 deadline);
    event TaskResultSubmitted(bytes32 indexed taskId, bytes32 indexed agentId, bytes32 resultHash, string proofIPFSUri);
    event TaskVerifiedAndPaid(bytes32 indexed taskId, bytes32 indexed agentId, uint256 amountPaid);
    event TaskFailureReported(bytes32 indexed taskId, bytes32 indexed agentId, string reasonIPFSUri);
    event TaskDisputeResolved(bytes32 indexed taskId, bytes32 indexed agentId, bool agentWasSuccessful);
    event SubTaskDelegated(bytes32 indexed parentTaskId, bytes32 indexed delegatingAgentId, bytes32 indexed subTaskId, bytes32 indexed subAgentId);

    event DataConsentRecorded(address indexed dataOwner, bytes32 indexed agentId, bytes32 indexed dataScopeHash, uint256 expirationTimestamp);
    event DataConsentRevoked(address indexed dataOwner, bytes32 indexed agentId, bytes32 indexed dataScopeHash);

    // --- 3. Error Handling ---
    error InvalidAgentId();
    error AgentNotActive();
    error AgentOwnerMismatch();
    error AgentAlreadyHasSkill();
    error SkillNotApproved();
    error InvalidSkillId();
    error InvalidTaskId();
    error TaskCreatorMismatch();
    error TaskAgentMismatch();
    error TaskStatusInvalid();
    error TaskNotCompleted();
    error TaskAlreadyDisputed();
    error InvalidRewardAmount();
    error InvalidDeadline();
    error InsufficientFunds();
    error FundsTransferFailed();
    error InsufficientStake();
    error InvalidStakeAmount();
    error AgentNotEligibleForTask(); // More specific task-matching could go here
    error ConsentExpiredOrRevoked();
    error ConsentNotGranted();
    error ProtocolAdminOnly();
    error InvalidFeeBasisPoints();

    // --- 4. Modifiers ---
    modifier onlyProtocolAdmin() {
        if (_msgSender() != protocolAdmin) revert ProtocolAdminOnly();
        _;
    }

    modifier onlyAgentOwner(bytes32 _agentId) {
        if (agents[_agentId].owner != _msgSender()) revert AgentOwnerMismatch();
        _;
    }

    modifier onlyAgent(bytes32 _agentId) {
        if (!agents[_agentId].isActive) revert AgentNotActive();
        // A more robust check could ensure msg.sender is the agent itself if agents were contracts,
        // but here msg.sender is the owner or delegating agent owner.
        _;
    }

    // --- 5. Admin & Protocol Governance ---

    constructor(address _initialAdmin, address _protocolTokenAddress) Ownable(address(0)) {
        // Ownable is used for initial deployment, then admin is transferred to a specific role.
        // The `owner` of this contract can be set to a DAO or a multisig.
        // `protocolAdmin` is a specific role managed by this contract.
        _transferOwnership(_initialAdmin); // Set initial `owner` of the contract (OpenZeppelin Ownable)
        protocolAdmin = _initialAdmin;    // Set initial `protocolAdmin` for this specific role
        protocolToken = IERC20(_protocolTokenAddress);
        protocolFeeBasisPoints = 0; // Default to no fees
    }

    function setProtocolAdmin(address _newAdmin) public onlyOwner {
        address oldAdmin = protocolAdmin;
        protocolAdmin = _newAdmin;
        emit AdminTransferred(oldAdmin, _newAdmin);
    }

    function setProtocolFee(uint256 _newFeeBasisPoints) public onlyProtocolAdmin {
        if (_newFeeBasisPoints > 10000) revert InvalidFeeBasisPoints(); // Max 100%
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeSet(_newFeeBasisPoints);
    }

    function withdrawProtocolFees() public onlyProtocolAdmin {
        if (totalProtocolFees == 0) return;
        uint256 amount = totalProtocolFees;
        totalProtocolFees = 0;
        bool success = protocolToken.transfer(protocolAdmin, amount);
        if (!success) revert FundsTransferFailed();
        emit ProtocolFeesWithdrawn(protocolAdmin, amount);
    }

    // --- 6. Skill Module Management ---

    function proposeSkillModule(
        string memory _name,
        string memory _description,
        bytes32 _verifierHash
    ) public returns (bytes32 skillId) {
        _skillNonce++;
        skillId = keccak256(abi.encodePacked(_skillNonce, _msgSender(), block.timestamp));
        skillModules[skillId] = SkillModule({
            name: _name,
            description: _description,
            verifierHash: _verifierHash,
            isApproved: false,
            proposer: _msgSender()
        });
        emit SkillModuleProposed(skillId, _name, _description, _msgSender());
    }

    function approveSkillModule(bytes32 _skillId) public onlyProtocolAdmin {
        SkillModule storage skill = skillModules[_skillId];
        if (bytes(skill.name).length == 0) revert InvalidSkillId(); // Check if skill exists
        if (skill.isApproved) return; // Already approved

        skill.isApproved = true;
        emit SkillModuleApproved(_skillId);
    }

    function getSkillModuleDetails(bytes32 _skillId)
        public
        view
        returns (
            string memory name,
            string memory description,
            bytes32 verifierHash,
            bool isApproved,
            address proposer
        )
    {
        SkillModule storage skill = skillModules[_skillId];
        return (skill.name, skill.description, skill.verifierHash, skill.isApproved, skill.proposer);
    }

    function assignSkillToAgent(bytes32 _agentId, bytes32 _skillId) public onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        SkillModule storage skill = skillModules[_skillId];

        if (bytes(skill.name).length == 0 || !skill.isApproved) revert SkillNotApproved();
        if (agent.assignedSkills[_skillId]) revert AgentAlreadyHasSkill();

        agent.assignedSkills[_skillId] = true;
        emit SkillAssignedToAgent(_agentId, _skillId);
    }

    // --- 7. Agent Lifecycle & Configuration ---

    function registerAgent(string memory _name, string memory _configIPFSUri)
        public
        returns (bytes32 agentId)
    {
        _agentNonce++;
        agentId = keccak256(abi.encodePacked(_agentNonce, _msgSender(), block.timestamp));
        agents[agentId] = Agent({
            owner: _msgSender(),
            name: _name,
            configIPFSUri: _configIPFSUri,
            isActive: true,
            reputationScore: 0,
            stakedAmount: 0,
            totalTasksCompleted: 0,
            totalTasksFailed: 0
        });
        ownerAgents[_msgSender()].push(agentId);
        emit AgentRegistered(agentId, _msgSender(), _name, _configIPFSUri);
    }

    function updateAgentConfig(bytes32 _agentId, string memory _newConfigIPFSUri)
        public
        onlyAgentOwner(_agentId)
    {
        agents[_agentId].configIPFSUri = _newConfigIPFSUri;
        emit AgentConfigUpdated(_agentId, _newConfigIPFSUri);
    }

    function deactivateAgent(bytes32 _agentId) public onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (!agent.isActive) return;
        agent.isActive = false;
        emit AgentDeactivated(_agentId);
    }

    function activateAgent(bytes32 _agentId) public onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.isActive) return;
        agent.isActive = true;
        emit AgentActivated(_agentId);
    }

    function transferAgentOwnership(bytes32 _agentId, address _newOwner)
        public
        onlyAgentOwner(_agentId)
    {
        Agent storage agent = agents[_agentId];
        address oldOwner = agent.owner;
        agent.owner = _newOwner;

        // Remove from old owner's list (simplified, in a real scenario, this would involve more complex array management or removal of elements)
        // For simplicity, we are not directly modifying the ownerAgents array here.
        // A more robust solution would involve iterating and removing or a linked list implementation for efficiency.
        // For now, assume this is handled off-chain or by allowing sparse arrays.

        ownerAgents[_newOwner].push(_agentId); // Add to new owner's list

        emit AgentOwnershipTransferred(_agentId, oldOwner, _newOwner);
    }

    function getAgentDetails(bytes32 _agentId)
        public
        view
        returns (
            address owner,
            string memory name,
            string memory configIPFSUri,
            bool isActive,
            int256 reputationScore,
            uint256 stakedAmount,
            uint256 totalTasksCompleted,
            uint256 totalTasksFailed
        )
    {
        Agent storage agent = agents[_agentId];
        if (bytes(agent.name).length == 0) revert InvalidAgentId();

        return (
            agent.owner,
            agent.name,
            agent.configIPFSUri,
            agent.isActive,
            agent.reputationScore,
            agent.stakedAmount,
            agent.totalTasksCompleted,
            agent.totalTasksFailed
        );
    }

    // --- 8. Task Delegation & Execution ---

    function createTaskRequest(
        bytes32 _agentId,
        uint256 _reward,
        uint256 _deadline,
        string memory _taskDescriptionIPFSUri
    ) public {
        Agent storage agent = agents[_agentId];
        if (bytes(agent.name).length == 0 || !agent.isActive) revert InvalidAgentId();
        if (_reward == 0) revert InvalidRewardAmount();
        if (_deadline <= block.timestamp) revert InvalidDeadline();

        // Ensure task creator has approved tokens for transfer
        bool approved = protocolToken.transferFrom(_msgSender(), address(this), _reward);
        if (!approved) revert InsufficientFunds();

        _taskNonce++;
        bytes32 taskId = keccak256(abi.encodePacked(_taskNonce, _msgSender(), block.timestamp));

        tasks[taskId] = Task({
            creator: _msgSender(),
            agentId: _agentId,
            reward: _reward,
            deadline: _deadline,
            descriptionIPFSUri: _taskDescriptionIPFSUri,
            resultHash: bytes32(0),
            proofIPFSUri: "",
            status: TaskStatus.Executing, // Directly assigned to agent
            parentTaskId: bytes32(0),
            subTaskId: bytes32(0),
            isDisputed: false
        });

        emit TaskRequestCreated(taskId, _msgSender(), _agentId, _reward, _deadline);
    }

    function submitTaskResultHash(
        bytes32 _taskId,
        bytes32 _resultHash,
        string memory _proofIPFSUri
    ) public onlyAgentOwner(tasks[_taskId].agentId) {
        Task storage task = tasks[_taskId];
        if (bytes(task.descriptionIPFSUri).length == 0) revert InvalidTaskId();
        if (task.status != TaskStatus.Executing) revert TaskStatusInvalid();
        if (block.timestamp > task.deadline) revert TaskStatusInvalid(); // Past deadline

        task.resultHash = _resultHash;
        task.proofIPFSUri = _proofIPFSUri;
        task.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(_taskId, task.agentId, _resultHash, _proofIPFSUri);
    }

    function verifyTaskResultAndPay(bytes32 _taskId, bytes32 _expectedResultHash) public {
        Task storage task = tasks[_taskId];
        if (bytes(task.descriptionIPFSUri).length == 0) revert InvalidTaskId();
        if (task.creator != _msgSender()) revert TaskCreatorMismatch();
        if (task.status != TaskStatus.ResultSubmitted) revert TaskStatusInvalid();
        if (task.resultHash != _expectedResultHash) revert TaskNotCompleted();

        Agent storage agent = agents[task.agentId];

        // Calculate protocol fee
        uint256 feeAmount = (task.reward * protocolFeeBasisPoints) / 10000;
        uint256 agentPayment = task.reward - feeAmount;

        // Transfer fee to protocol
        if (feeAmount > 0) {
            bool feeTransferred = protocolToken.transfer(address(this), feeAmount);
            if (!feeTransferred) revert FundsTransferFailed();
            totalProtocolFees += feeAmount;
        }

        // Pay agent
        bool paid = protocolToken.transfer(agent.owner, agentPayment);
        if (!paid) revert FundsTransferFailed();

        task.status = TaskStatus.Verified;
        agent.reputationScore += 10; // Reward good performance
        agent.totalTasksCompleted += 1;
        emit TaskVerifiedAndPaid(_taskId, task.agentId, agentPayment);
        emit AgentReputationUpdated(task.agentId, agent.reputationScore);
    }

    function reportTaskFailure(bytes32 _taskId, string memory _reasonIPFSUri) public {
        Task storage task = tasks[_taskId];
        if (bytes(task.descriptionIPFSUri).length == 0) revert InvalidTaskId();
        if (task.creator != _msgSender()) revert TaskCreatorMismatch();
        if (task.status == TaskStatus.Verified || task.status == TaskStatus.Failed || task.isDisputed)
            revert TaskStatusInvalid();

        task.isDisputed = true;
        task.status = TaskStatus.Disputed;
        emit TaskFailureReported(_taskId, task.agentId, _reasonIPFSUri);
    }

    function resolveTaskDispute(bytes32 _taskId, bool _agentWasSuccessful) public onlyProtocolAdmin {
        Task storage task = tasks[_taskId];
        if (bytes(task.descriptionIPFSUri).length == 0) revert InvalidTaskId();
        if (!task.isDisputed) revert TaskStatusInvalid();

        Agent storage agent = agents[task.agentId];

        if (_agentWasSuccessful) {
            // Agent was successful, task creator's report was false/misleading
            task.status = TaskStatus.Verified;
            agent.reputationScore += 5; // Small reputation boost for wrongful accusation
            // Transfer reward to agent, no fee applied since task creator was wrong.
            bool paid = protocolToken.transfer(agent.owner, task.reward);
            if (!paid) revert FundsTransferFailed();
            agent.totalTasksCompleted += 1;
        } else {
            // Agent failed the task
            task.status = TaskStatus.Failed;
            agent.reputationScore -= 15; // Penalize failure
            agent.totalTasksFailed += 1;
            // Optionally slash stake or refund creator (task reward is held by contract)
            // For now, task reward remains in contract if agent failed (potential future refund to creator logic)
        }
        task.isDisputed = false;
        emit TaskDisputeResolved(_taskId, task.agentId, _agentWasSuccessful);
        emit AgentReputationUpdated(task.agentId, agent.reputationScore);
    }

    function delegateSubTask(
        bytes32 _parentTaskId,
        bytes32 _delegatingAgentId,
        bytes32 _subAgentId,
        uint256 _subReward,
        uint256 _subDeadline,
        string memory _subTaskDescriptionIPFSUri
    ) public onlyAgentOwner(_delegatingAgentId) {
        Task storage parentTask = tasks[_parentTaskId];
        if (bytes(parentTask.descriptionIPFSUri).length == 0 || parentTask.agentId != _delegatingAgentId)
            revert InvalidTaskId(); // Ensure parent task exists and is owned by delegating agent's owner
        if (parentTask.status != TaskStatus.Executing) revert TaskStatusInvalid();
        if (_subAgentId == _delegatingAgentId) revert AgentNotEligibleForTask(); // Cannot delegate to self

        // Ensure sub-agent exists and is active
        Agent storage subAgent = agents[_subAgentId];
        if (bytes(subAgent.name).length == 0 || !subAgent.isActive) revert InvalidAgentId();

        // The delegating agent's owner needs to stake for the sub-task or ensure funds
        // This means the delegating agent's owner pays the sub-agent.
        bool approved = protocolToken.transferFrom(_msgSender(), address(this), _subReward);
        if (!approved) revert InsufficientFunds();

        _taskNonce++;
        bytes32 subTaskId = keccak256(abi.encodePacked(_taskNonce, _msgSender(), block.timestamp));

        tasks[subTaskId] = Task({
            creator: _msgSender(), // Creator is the delegating agent's owner
            agentId: _subAgentId,
            reward: _subReward,
            deadline: _subDeadline,
            descriptionIPFSUri: _subTaskDescriptionIPFSUri,
            resultHash: bytes32(0),
            proofIPFSUri: "",
            status: TaskStatus.Executing,
            parentTaskId: _parentTaskId,
            subTaskId: bytes32(0), // No further delegation in this simplified model
            isDisputed: false
        });

        // Link parent task to sub-task
        parentTask.subTaskId = subTaskId; // Assuming only one sub-task for simplicity

        emit SubTaskDelegated(_parentTaskId, _delegatingAgentId, subTaskId, _subAgentId);
        emit TaskRequestCreated(subTaskId, _msgSender(), _subAgentId, _subReward, _subDeadline);
    }

    function submitSubTaskResultHash(
        bytes32 _subTaskId,
        bytes32 _resultHash,
        string memory _proofIPFSUri
    ) public onlyAgentOwner(tasks[_subTaskId].agentId) {
        Task storage subTask = tasks[_subTaskId];
        if (bytes(subTask.descriptionIPFSUri).length == 0 || subTask.parentTaskId == bytes32(0))
            revert InvalidTaskId(); // Ensure it's a valid sub-task
        if (subTask.status != TaskStatus.Executing) revert TaskStatusInvalid();
        if (block.timestamp > subTask.deadline) revert TaskStatusInvalid();

        subTask.resultHash = _resultHash;
        subTask.proofIPFSUri = _proofIPFSUri;
        subTask.status = TaskStatus.ResultSubmitted;

        emit TaskResultSubmitted(_subTaskId, subTask.agentId, _resultHash, _proofIPFSUri);
    }

    function verifySubTaskResultAndPay(bytes32 _subTaskId, bytes32 _expectedResultHash) public {
        Task storage subTask = tasks[_subTaskId];
        if (bytes(subTask.descriptionIPFSUri).length == 0 || subTask.parentTaskId == bytes32(0))
            revert InvalidTaskId();
        if (subTask.creator != _msgSender()) revert TaskCreatorMismatch(); // Creator is the delegating agent's owner
        if (subTask.status != TaskStatus.ResultSubmitted) revert TaskStatusInvalid();
        if (subTask.resultHash != _expectedResultHash) revert TaskNotCompleted();

        Agent storage subAgent = agents[subTask.agentId];

        // No protocol fee on sub-tasks as it's an internal agent transaction.
        bool paid = protocolToken.transfer(subAgent.owner, subTask.reward);
        if (!paid) revert FundsTransferFailed();

        subTask.status = TaskStatus.Verified;
        subAgent.reputationScore += 5; // Smaller reputation boost for sub-tasks
        subAgent.totalTasksCompleted += 1;
        emit TaskVerifiedAndPaid(_subTaskId, subTask.agentId, subTask.reward);
        emit AgentReputationUpdated(subTask.agentId, subAgent.reputationScore);
    }

    // --- 9. Data Consent & Privacy ---

    function recordDataConsent(
        address _dataOwner,
        bytes32 _agentId,
        string memory _dataScopeIPFSUri,
        uint256 _expirationTimestamp
    ) public {
        // Only the data owner can grant consent for their data
        if (_dataOwner != _msgSender()) revert TaskCreatorMismatch(); // Reusing the error, could be more specific

        // Ensure agent exists
        if (bytes(agents[_agentId].name).length == 0) revert InvalidAgentId();

        bytes32 dataScopeHash = keccak256(abi.encodePacked(_dataScopeIPFSUri));
        consentRecords[_dataOwner][_agentId][dataScopeHash] = ConsentRecord({
            agentId: _agentId,
            dataScopeIPFSUri: _dataScopeIPFSUri,
            expirationTimestamp: _expirationTimestamp,
            revoked: false
        });
        emit DataConsentRecorded(_dataOwner, _agentId, dataScopeHash, _expirationTimestamp);
    }

    function revokeDataConsent(
        address _dataOwner,
        bytes32 _agentId,
        string memory _dataScopeIPFSUri
    ) public {
        if (_dataOwner != _msgSender()) revert TaskCreatorMismatch();

        bytes32 dataScopeHash = keccak256(abi.encodePacked(_dataScopeIPFSUri));
        ConsentRecord storage consent = consentRecords[_dataOwner][_agentId][dataScopeHash];

        if (bytes(consent.dataScopeIPFSUri).length == 0 || consent.revoked)
            revert ConsentNotGranted(); // No active consent found or already revoked

        consent.revoked = true;
        emit DataConsentRevoked(_dataOwner, _agentId, dataScopeHash);
    }

    function getConsentStatus(
        address _dataOwner,
        bytes32 _agentId,
        string memory _dataScopeIPFSUri
    ) public view returns (bool granted, bool active, uint256 expiration) {
        bytes32 dataScopeHash = keccak256(abi.encodePacked(_dataScopeIPFSUri));
        ConsentRecord storage consent = consentRecords[_dataOwner][_agentId][dataScopeHash];

        if (bytes(consent.dataScopeIPFSUri).length == 0 || consent.revoked) {
            return (false, false, 0);
        }

        if (consent.expirationTimestamp > block.timestamp) {
            return (true, true, consent.expirationTimestamp);
        } else {
            return (true, false, consent.expirationTimestamp); // Granted but expired
        }
    }

    // --- 10. Agent Reputation & Staking ---

    function stakeForAgentReliability(bytes32 _agentId, uint256 _amount)
        public
        onlyAgentOwner(_agentId)
    {
        if (_amount == 0) revert InvalidStakeAmount();
        Agent storage agent = agents[_agentId];

        bool approved = protocolToken.transferFrom(_msgSender(), address(this), _amount);
        if (!approved) revert InsufficientFunds();

        agent.stakedAmount += _amount;
        emit AgentStaked(_agentId, _amount);
    }

    function withdrawAgentStake(bytes32 _agentId, uint256 _amount)
        public
        onlyAgentOwner(_agentId)
    {
        Agent storage agent = agents[_agentId];
        if (_amount == 0 || agent.stakedAmount < _amount) revert InsufficientStake();

        agent.stakedAmount -= _amount;
        bool success = protocolToken.transfer(_msgSender(), _amount);
        if (!success) revert FundsTransferFailed();
        emit AgentStakeWithdrawn(_agentId, _amount);
    }

    function slashAgentStake(bytes32 _agentId, uint256 _amount) public onlyProtocolAdmin {
        Agent storage agent = agents[_agentId];
        if (_amount == 0 || agent.stakedAmount < _amount) revert InsufficientStake();

        agent.stakedAmount -= _amount;
        totalProtocolFees += _amount; // Slashed stake goes to protocol fees
        emit AgentStakeSlashed(_agentId, _amount, "Protocol Admin Slash");
    }
}
```