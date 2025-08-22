Here's a Solidity smart contract for a "Synergistic Autonomous Agent Network (SAAN)", designed with advanced concepts like programmable agents, dynamic capability-based access, conditional multi-step task execution, and resource delegation, all managed by a protocol governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint to string conversion in error messages

// Outline and Function Summary:

// This contract, Synergistic Autonomous Agent Network (SAAN),
// provides a decentralized protocol for users to deploy and manage
// programmable "Autonomous Agents" (AAs). These AAs can execute
// complex, multi-step tasks on behalf of their owners, interact with
// other DApps, and participate in a decentralized network. The
// protocol features a dynamic reputation/capability system, conditional
// task execution, and resource delegation, all controlled by the protocol owner/governance.

// I. Data Structures & Core State:
//    - AutonomousAgent: Stores an agent's profile, status, owner, capabilities, and delegated resources.
//    - TaskDefinition: Defines a reusable template for tasks, including a sequence of external calls and conditions.
//    - ScheduledTask: Links an agent to a specific TaskDefinition, with unique execution parameters and rewards.
//    - ProtocolParameters: Global configuration settings for the SAAN network, adjustable by governance.
//    - AgentStatus: Enum for agent lifecycle (Active, Paused, Terminated).
//    - TaskExecutionStatus: Enum for task lifecycle (Pending, Executed, Failed, Cancelled).

// II. Agent Management (Owner/Protocol Functions):
// 1.  createAutonomousAgent(address _owner, string memory _name, string memory _description):
//     Registers a new autonomous agent for a given owner. Only callable by protocol owner.
// 2.  updateAgentProfile(uint256 _agentId, string memory _name, string memory _description):
//     Allows an agent's owner to update its metadata (name, description).
// 3.  pauseAgent(uint256 _agentId):
//     Temporarily suspends an agent, preventing task execution. Callable by agent owner.
// 4.  unpauseAgent(uint256 _agentId):
//     Resumes a paused agent, allowing it to execute tasks again. Callable by agent owner.
// 5.  terminateAgent(uint256 _agentId):
//     Permanently deactivates an agent. Revocation of resources might need manual intervention or separate calls. Callable by agent owner.
// 6.  delegateResourceToAgent(uint256 _agentId, address _tokenAddress, uint256 _amount):
//     Transfers ERC20 tokens from the `_msgSender()` to the SAAN protocol on behalf of an agent for its future use in tasks.
// 7.  delegateNFTToAgent(uint256 _agentId, address _nftAddress, uint256 _tokenId):
//     Transfers an ERC721 NFT from the `_msgSender()` to the SAAN protocol on behalf of an agent.
// 8.  revokeResourceFromAgent(uint256 _agentId, address _tokenAddress, uint256 _amount):
//     Retrieves ERC20 tokens from the SAAN protocol, previously delegated to an agent, back to the agent owner.
// 9.  revokeNFTFromAgent(uint256 _agentId, address _nftAddress, uint256 _tokenId):
//     Retrieves an ERC721 NFT from the SAAN protocol, previously delegated to an agent, back to the agent owner.
// 10. getAgentDelegatedERC20(uint256 _agentId, address _tokenAddress):
//     View function to check the ERC20 balance delegated to a specific agent.
// 11. getAgentDelegatedNFT(uint256 _agentId, address _nftAddress, uint256 _tokenId):
//     View function to check if a specific NFT is delegated to an agent.

// III. Task Definition & Scheduling (Owner/Protocol Functions):
// 12. defineAgentTask(string memory _name, string memory _description, bytes[] memory _callData, address[] memory _targets, uint256 _requiredCapability, uint256 _gasLimitPerCall):
//     Creates a new reusable task definition with a sequence of external calls and required capabilities. Only callable by protocol owner.
// 13. updateAgentTaskDefinition(uint256 _taskId, string memory _name, string memory _description, bytes[] memory _callData, address[] memory _targets, uint256 _requiredCapability, uint256 _gasLimitPerCall):
//     Modifies an existing task definition. Only callable by protocol owner or the task's original definer.
// 14. assignTaskToAgent(uint256 _agentId, uint256 _taskId, uint256 _executeAfterTimestamp, bytes memory _conditionData, uint256 _rewardAmount, address _rewardToken):
//     Schedules a defined task for a specific agent with conditions and rewards for the executor. Callable by agent owner.
// 15. cancelScheduledTask(uint256 _scheduledTaskId):
//     Removes a pending task from an agent's schedule and refunds the reward tokens to the agent owner. Callable by agent owner or protocol owner.
// 16. batchAssignTasksToAgents(uint256[] memory _agentIds, uint256[] memory _taskIds, uint256[] memory _executeAfterTimestamps, bytes[] memory _conditionDatas, uint256[] memory _rewardAmounts, address[] memory _rewardTokens):
//     Assigns multiple tasks to multiple agents in a single transaction. Each assignment must be by the respective agent's owner.

// IV. Execution & Incentivization (Public/Keeper Functions):
// 17. executeAgentTask(uint256 _scheduledTaskId):
//     The core function, callable by anyone (e.g., a keeper bot), to attempt execution of a scheduled task.
//     It verifies conditions, performs external calls on behalf of the agent, and pays a reward (minus protocol fee) to the executor.
// 18. claimTaskReward(uint256 _scheduledTaskId):
//     Allows the agent's owner to claim back reward tokens for failed or cancelled tasks.
// 19. submitAgentAttestation(uint256 _agentId, string memory _attestationType, bytes memory _attestationData):
//     An agent (via its owner or a delegated entity) submits arbitrary proof/data of an observed event or execution for future analysis or capability scoring.

// V. Protocol Governance & Parameter Tuning (Governance Functions):
// 20. updateAgentCapability(uint256 _agentId, int256 _capabilityChange):
//     Adjusts an agent's capability score. Only callable by the protocol owner.
// 21. setProtocolParameters(uint256 _maxActiveAgents, uint256 _maxScheduledTasksPerAgent, uint256 _minCapabilityScore, uint256 _protocolFeeBps, uint256 _minTaskRewardAmount, uint256 _maxTaskExecutionTimeBuffer):
//     Updates the global protocol parameters. Only callable by the protocol owner.
// 22. setTrustedOracle(address _oracleAddress, bool _isTrusted):
//     Whitelists/unwhitelists an address that can be used as an oracle for task conditions. Only callable by protocol owner.
// 23. registerExternalContract(address _contractAddress, bool _canInteract):
//     Whitelists/unwhitelists external contracts that agents are allowed to interact with, a crucial security measure. Only callable by protocol owner.
// 24. transferOwnership(address _newOwner):
//     Transfers protocol ownership to a new address (standard OpenZeppelin Ownable).
// 25. withdrawProtocolFees(address _tokenAddress, uint256 _amount):
//     Allows the protocol owner to withdraw collected protocol fees in a specific token.

// Disclaimer: This is a conceptual contract for demonstration.
// Production-ready implementation would require extensive security audits,
// gas optimizations, robust error handling, and a more sophisticated
// oracle and governance integration (e.g., a separate DAO contract).

interface IOracle {
    // Placeholder interface for a potential oracle integration
    function isValidCondition(bytes memory _conditionData) external view returns (bool);
    // More complex functions for data retrieval and verification could be added
}

contract SAANProtocol is Context, Ownable {
    using Address for address; // Utility library for address operations (e.g., .call)

    // --- Enums ---
    enum AgentStatus { Active, Paused, Terminated }
    enum TaskExecutionStatus { Pending, Executed, Failed, Cancelled }

    // --- Structs ---

    struct AutonomousAgent {
        address owner;
        string name;
        string description;
        AgentStatus status;
        uint256 capabilityScore; // Influences what tasks an agent can perform
        uint256 createdAt;
        // Delegated ERC20 balances: SAANProtocol holds the tokens on behalf of the agent
        mapping(address => uint256) delegatedERC20;
        // Delegated ERC721s: SAANProtocol holds the NFTs on behalf of the agent
        mapping(address => mapping(uint256 => bool)) delegatedERC721;
    }

    struct TaskDefinition {
        address definer; // Who defined this task (protocol owner or a specific role)
        string name;
        string description;
        bytes[] callData; // Array of calldata for multi-step execution
        address[] targets; // Array of target addresses for each callData entry
        uint256 requiredCapability; // Minimum capability score for an agent to execute this task
        uint256 gasLimitPerCall; // Max gas allowed for each individual sub-call within the task
        bool isActive; // Can this task definition be used?
    }

    struct ScheduledTask {
        uint256 agentId;
        uint256 taskId; // Reference to TaskDefinition
        uint256 assignedAt;
        uint256 executeAfterTimestamp; // Task can only be executed after this timestamp
        bytes conditionData; // Data for an oracle or internal logic for conditional execution
        TaskExecutionStatus status;
        address rewardToken;
        uint256 rewardAmount; // Reward for the executor (keeper)
        address executor; // Who executed the task (for rewards/auditing)
        uint256 executedAt;
        uint256 estimatedGasCost; // Estimated gas cost of execution to help keepers decide
        string failureReason; // If failed
    }

    struct ProtocolParameters {
        uint256 maxActiveAgents; // Max agents an owner can create
        uint256 maxScheduledTasksPerAgent; // Max pending tasks per agent
        uint256 minCapabilityScore; // Base capability score, new agents start with this.
        uint256 protocolFeeBps; // Basis points (e.g., 100 = 1%) charged on task rewards
        uint256 minTaskRewardAmount; // Minimum reward amount for a task
        uint256 maxTaskExecutionTimeBuffer; // How long after executeAfterTimestamp can it still be executed
        uint256 defaultGasLimitPerCall; // Default gas limit if not specified in task definition
    }

    // --- State Variables ---

    uint256 private _nextAgentId;
    mapping(uint256 => AutonomousAgent) public agents;
    mapping(address => uint256[]) public ownerAgents; // Track agents by owner

    uint256 private _nextTaskId;
    mapping(uint256 => TaskDefinition) public taskDefinitions;

    uint256 private _nextScheduledTaskId;
    mapping(uint256 => ScheduledTask) public scheduledTasks;
    mapping(uint256 => uint256[]) public agentScheduledTasks; // Track scheduled tasks by agent

    mapping(address => bool) public trustedOracles; // Whitelisted oracles for condition checks
    mapping(address => bool) public whitelistedExternalContracts; // Contracts agents can interact with

    ProtocolParameters public protocolParameters;
    mapping(address => uint256) public protocolFeesCollected; // Fees collected in different tokens

    // --- Events ---
    event AgentCreated(uint256 indexed agentId, address indexed owner, string name);
    event AgentProfileUpdated(uint256 indexed agentId, string name, string description);
    event AgentStatusUpdated(uint256 indexed agentId, AgentStatus newStatus);
    event ResourceDelegated(uint256 indexed agentId, address indexed tokenAddress, uint256 amountOrId, bool isERC721);
    event ResourceRevoked(uint256 indexed agentId, address indexed tokenAddress, uint256 amountOrId, bool isERC721);

    event TaskDefinitionCreated(uint256 indexed taskId, address indexed definer, string name);
    event TaskDefinitionUpdated(uint256 indexed taskId, string name);
    event TaskScheduled(uint256 indexed scheduledTaskId, uint256 indexed agentId, uint256 indexed taskId, uint256 executeAfter);
    event TaskExecutionAttempted(uint256 indexed scheduledTaskId, uint256 indexed agentId, address executor);
    event TaskExecuted(uint256 indexed scheduledTaskId, uint256 indexed agentId, address executor, uint256 rewardAmount);
    event TaskExecutionFailed(uint256 indexed scheduledTaskId, uint256 indexed agentId, address executor, string reason);
    event TaskCancelled(uint256 indexed scheduledTaskId, uint256 indexed agentId);
    event TaskRewardClaimed(uint256 indexed scheduledTaskId, address indexed claimant, uint256 amount, address token);

    event AgentCapabilityUpdated(uint256 indexed agentId, uint256 oldScore, uint256 newScore);
    event AgentAttestationSubmitted(uint256 indexed agentId, string attestationType, bytes attestationData);

    event ProtocolParametersUpdated(ProtocolParameters newParams);
    event TrustedOracleStatusUpdated(address indexed oracleAddress, bool isTrusted);
    event ExternalContractWhitelisted(address indexed contractAddress, bool canInteract);
    event ProtocolFeesWithdrawn(address indexed tokenAddress, uint256 amount);

    // --- Constructor ---
    constructor(address _initialOwner) Ownable(_initialOwner) {
        _nextAgentId = 1;
        _nextTaskId = 1;
        _nextScheduledTaskId = 1;

        protocolParameters = ProtocolParameters({
            maxActiveAgents: 10000,
            maxScheduledTasksPerAgent: 100,
            minCapabilityScore: 100,
            protocolFeeBps: 100, // 1%
            minTaskRewardAmount: 1, // Minimum 1 unit of reward token
            maxTaskExecutionTimeBuffer: 1 days, // Tasks can be executed up to 1 day after executeAfterTimestamp
            defaultGasLimitPerCall: 300000 // Default gas limit for sub-calls if not specified
        });

        // Whitelist self for agents to potentially interact with (e.g. for internal management tasks)
        whitelistedExternalContracts[address(this)] = true;
    }

    // --- Modifiers ---
    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].owner == _msgSender(), "SAAN: Not agent owner");
        _;
    }

    modifier onlyAgentActive(uint256 _agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "SAAN: Agent not active");
        _;
    }

    modifier onlyTaskDefinerOrOwner(uint256 _taskId) {
        require(taskDefinitions[_taskId].definer == _msgSender() || owner() == _msgSender(), "SAAN: Not task definer or protocol owner");
        _;
    }

    modifier onlyTrustedOracle(address _oracle) {
        require(trustedOracles[_oracle], "SAAN: Not a trusted oracle");
        _;
    }

    // --- II. Agent Management Functions ---

    /**
     * @notice Registers a new autonomous agent for a given owner.
     * @dev Only callable by the protocol owner.
     * @param _owner The address that will own the new agent.
     * @param _name The name of the agent.
     * @param _description A description of the agent's purpose.
     * @return The ID of the newly created agent.
     */
    function createAutonomousAgent(
        address _owner,
        string memory _name,
        string memory _description
    ) public onlyOwner returns (uint256) {
        require(_owner != address(0), "SAAN: Invalid owner address");
        // Check current ownerAgents[_owner].length if a cap applies per owner, not global.
        // For now, assuming maxActiveAgents is global.
        // This check would ensure total active agents don't exceed a protocol limit.
        // If it means per owner, the mapping `ownerAgents` would need to be `mapping(address => uint256) public activeAgentCountByOwner;`
        // For simplicity, `maxActiveAgents` is total for the protocol, so no specific check needed here beyond the generic limit.

        uint256 agentId = _nextAgentId++;
        agents[agentId] = AutonomousAgent({
            owner: _owner,
            name: _name,
            description: _description,
            status: AgentStatus.Active,
            capabilityScore: protocolParameters.minCapabilityScore,
            createdAt: block.timestamp
        });
        ownerAgents[_owner].push(agentId); // Keep track of agents by owner

        emit AgentCreated(agentId, _owner, _name);
        return agentId;
    }

    /**
     * @notice Allows an agent's owner to update its metadata.
     * @param _agentId The ID of the agent to update.
     * @param _name The new name for the agent.
     * @param _description The new description for the agent.
     */
    function updateAgentProfile(
        uint256 _agentId,
        string memory _name,
        string memory _description
    ) public onlyAgentOwner(_agentId) {
        require(agents[_agentId].status != AgentStatus.Terminated, "SAAN: Cannot update terminated agent");
        agents[_agentId].name = _name;
        agents[_agentId].description = _description;
        emit AgentProfileUpdated(_agentId, _name, _description);
    }

    /**
     * @notice Temporarily suspends an agent, preventing task execution.
     * @param _agentId The ID of the agent to pause.
     */
    function pauseAgent(uint256 _agentId) public onlyAgentOwner(_agentId) {
        require(agents[_agentId].status == AgentStatus.Active, "SAAN: Agent is not active");
        agents[_agentId].status = AgentStatus.Paused;
        emit AgentStatusUpdated(_agentId, AgentStatus.Paused);
    }

    /**
     * @notice Resumes a paused agent, allowing it to execute tasks again.
     * @param _agentId The ID of the agent to unpause.
     */
    function unpauseAgent(uint256 _agentId) public onlyAgentOwner(_agentId) {
        require(agents[_agentId].status == AgentStatus.Paused, "SAAN: Agent is not paused");
        agents[_agentId].status = AgentStatus.Active;
        emit AgentStatusUpdated(_agentId, AgentStatus.Active);
    }

    /**
     * @notice Permanently deactivates an agent.
     * @dev Note: This function only updates status. Actual resource retrieval would need explicit `revokeResource` calls.
     * @param _agentId The ID of the agent to terminate.
     */
    function terminateAgent(uint256 _agentId) public onlyAgentOwner(_agentId) {
        require(agents[_agentId].status != AgentStatus.Terminated, "SAAN: Agent already terminated");
        // In a real system, you might want to automatically revoke all delegated resources here.
        // For this example, we'll rely on explicit revoke calls.
        agents[_agentId].status = AgentStatus.Terminated;
        emit AgentStatusUpdated(_agentId, AgentStatus.Terminated);
    }

    /**
     * @notice Transfers ERC20 tokens to the SAAN protocol on behalf of an agent for its use.
     *         The `_msgSender()` must have approved the SAANProtocol contract beforehand.
     * @param _agentId The ID of the agent.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to delegate.
     */
    function delegateResourceToAgent(
        uint256 _agentId,
        address _tokenAddress,
        uint256 _amount
    ) public onlyAgentOwner(_agentId) onlyAgentActive(_agentId) {
        require(_tokenAddress != address(0), "SAAN: Invalid token address");
        require(_amount > 0, "SAAN: Amount must be positive");
        
        // Transfer from sender to this contract
        IERC20(_tokenAddress).transferFrom(_msgSender(), address(this), _amount);

        agents[_agentId].delegatedERC20[_tokenAddress] += _amount;
        emit ResourceDelegated(_agentId, _tokenAddress, _amount, false);
    }

    /**
     * @notice Transfers an ERC721 NFT to the SAAN protocol on behalf of an agent for its use.
     *         The `_msgSender()` must have approved the SAANProtocol contract beforehand.
     * @param _agentId The ID of the agent.
     * @param _nftAddress The address of the ERC721 NFT contract.
     * @param _tokenId The ID of the NFT.
     */
    function delegateNFTToAgent(
        uint256 _agentId,
        address _nftAddress,
        uint256 _tokenId
    ) public onlyAgentOwner(_agentId) onlyAgentActive(_agentId) {
        require(_nftAddress != address(0), "SAAN: Invalid NFT address");
        require(!agents[_agentId].delegatedERC721[_nftAddress][_tokenId], "SAAN: NFT already delegated");
        
        // Transfer from sender to this contract
        IERC721(_nftAddress).transferFrom(_msgSender(), address(this), _tokenId);

        agents[_agentId].delegatedERC721[_nftAddress][_tokenId] = true;
        emit ResourceDelegated(_agentId, _nftAddress, _tokenId, true);
    }

    /**
     * @notice Retrieves ERC20 tokens from the SAAN protocol, previously delegated to an agent, back to the agent owner.
     * @param _agentId The ID of the agent.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to revoke.
     */
    function revokeResourceFromAgent(
        uint256 _agentId,
        address _tokenAddress,
        uint256 _amount
    ) public onlyAgentOwner(_agentId) {
        require(_tokenAddress != address(0), "SAAN: Invalid token address");
        require(_amount > 0, "SAAN: Amount must be positive");
        require(agents[_agentId].delegatedERC20[_tokenAddress] >= _amount, "SAAN: Insufficient delegated amount");

        agents[_agentId].delegatedERC20[_tokenAddress] -= _amount;
        // Transfer from this contract back to agent owner
        IERC20(_tokenAddress).transfer(agents[_agentId].owner, _amount);
        emit ResourceRevoked(_agentId, _tokenAddress, _amount, false);
    }

    /**
     * @notice Retrieves an ERC721 NFT from the SAAN protocol, previously delegated to an agent, back to the agent owner.
     * @param _agentId The ID of the agent.
     * @param _nftAddress The address of the ERC721 NFT contract.
     * @param _tokenId The ID of the NFT.
     */
    function revokeNFTFromAgent(
        uint256 _agentId,
        address _nftAddress,
        uint256 _tokenId
    ) public onlyAgentOwner(_agentId) {
        require(_nftAddress != address(0), "SAAN: Invalid NFT address");
        require(agents[_agentId].delegatedERC721[_nftAddress][_tokenId], "SAAN: NFT not delegated to this agent");

        agents[_agentId].delegatedERC721[_nftAddress][_tokenId] = false;
        // Transfer from this contract back to agent owner
        IERC721(_nftAddress).transferFrom(address(this), agents[_agentId].owner, _tokenId);
        emit ResourceRevoked(_agentId, _nftAddress, _tokenId, true);
    }

    /**
     * @notice View function to check ERC20 balance delegated to an agent.
     * @param _agentId The ID of the agent.
     * @param _tokenAddress The address of the ERC20 token.
     * @return The delegated amount.
     */
    function getAgentDelegatedERC20(uint256 _agentId, address _tokenAddress) public view returns (uint256) {
        return agents[_agentId].delegatedERC20[_tokenAddress];
    }

    /**
     * @notice View function to check if an NFT is delegated to an agent.
     * @param _agentId The ID of the agent.
     * @param _nftAddress The address of the ERC721 NFT contract.
     * @param _tokenId The ID of the NFT.
     * @return True if delegated, false otherwise.
     */
    function getAgentDelegatedNFT(uint256 _agentId, address _nftAddress, uint256 _tokenId) public view returns (bool) {
        return agents[_agentId].delegatedERC721[_nftAddress][_tokenId];
    }

    // --- III. Task Definition & Scheduling Functions ---

    /**
     * @notice Creates a new reusable task definition with a sequence of external calls and required capabilities.
     * @dev Only callable by the protocol owner.
     * @param _name The name of the task.
     * @param _description A description of the task's actions.
     * @param _callData Array of calldata for each external call in the task sequence.
     * @param _targets Array of target addresses for each corresponding calldata.
     * @param _requiredCapability Minimum capability score an agent needs to execute this task.
     * @param _gasLimitPerCall Maximum gas allowed for each individual sub-call within the task. If 0, uses default.
     * @return The ID of the newly defined task.
     */
    function defineAgentTask(
        string memory _name,
        string memory _description,
        bytes[] memory _callData,
        address[] memory _targets,
        uint256 _requiredCapability,
        uint256 _gasLimitPerCall
    ) public onlyOwner returns (uint256) {
        require(_callData.length > 0, "SAAN: Task must have at least one call");
        require(_callData.length == _targets.length, "SAAN: callData and targets length mismatch");
        require(_requiredCapability >= protocolParameters.minCapabilityScore, "SAAN: Required capability too low");

        for (uint256 i = 0; i < _targets.length; i++) {
            require(whitelistedExternalContracts[_targets[i]], "SAAN: Target contract not whitelisted");
        }

        uint256 taskId = _nextTaskId++;
        taskDefinitions[taskId] = TaskDefinition({
            definer: _msgSender(), // Protocol owner defines the task
            name: _name,
            description: _description,
            callData: _callData,
            targets: _targets,
            requiredCapability: _requiredCapability,
            gasLimitPerCall: _gasLimitPerCall == 0 ? protocolParameters.defaultGasLimitPerCall : _gasLimitPerCall,
            isActive: true
        });

        emit TaskDefinitionCreated(taskId, _msgSender(), _name);
        return taskId;
    }

    /**
     * @notice Modifies an existing task definition.
     * @dev Only callable by the task's original definer or the protocol owner.
     * @param _taskId The ID of the task definition to update.
     * @param _name The new name for the task.
     * @param _description The new description.
     * @param _callData New array of calldata.
     * @param _targets New array of target addresses.
     * @param _requiredCapability New minimum required capability.
     * @param _gasLimitPerCall New maximum gas per call. If 0, uses default.
     */
    function updateAgentTaskDefinition(
        uint256 _taskId,
        string memory _name,
        string memory _description,
        bytes[] memory _callData,
        address[] memory _targets,
        uint256 _requiredCapability,
        uint256 _gasLimitPerCall
    ) public onlyTaskDefinerOrOwner(_taskId) {
        TaskDefinition storage task = taskDefinitions[_taskId];
        require(task.isActive, "SAAN: Task definition not active");
        require(_callData.length > 0, "SAAN: Task must have at least one call");
        require(_callData.length == _targets.length, "SAAN: callData and targets length mismatch");
        require(_requiredCapability >= protocolParameters.minCapabilityScore, "SAAN: Required capability too low");

        for (uint256 i = 0; i < _targets.length; i++) {
            require(whitelistedExternalContracts[_targets[i]], "SAAN: Target contract not whitelisted");
        }

        task.name = _name;
        task.description = _description;
        task.callData = _callData;
        task.targets = _targets;
        task.requiredCapability = _requiredCapability;
        task.gasLimitPerCall = _gasLimitPerCall == 0 ? protocolParameters.defaultGasLimitPerCall : _gasLimitPerCall;

        emit TaskDefinitionUpdated(_taskId, _name);
    }

    /**
     * @notice Schedules a defined task for a specific agent with conditions and rewards for the executor.
     *         Requires the `_rewardAmount` in `_rewardToken` to be approved to the SAANProtocol by `_msgSender()`.
     * @param _agentId The ID of the agent.
     * @param _taskId The ID of the TaskDefinition to schedule.
     * @param _executeAfterTimestamp The earliest timestamp the task can be executed.
     * @param _conditionData Optional data for an oracle to check for additional conditions.
     * @param _rewardAmount The reward for successful task execution (for the keeper).
     * @param _rewardToken The address of the ERC20 token for the reward.
     * @return The ID of the newly scheduled task.
     */
    function assignTaskToAgent(
        uint256 _agentId,
        uint256 _taskId,
        uint256 _executeAfterTimestamp,
        bytes memory _conditionData,
        uint256 _rewardAmount,
        address _rewardToken
    ) public onlyAgentOwner(_agentId) onlyAgentActive(_agentId) returns (uint256) {
        require(taskDefinitions[_taskId].isActive, "SAAN: Task definition is not active");
        require(agents[_agentId].capabilityScore >= taskDefinitions[_taskId].requiredCapability, "SAAN: Agent capability too low");
        require(agentScheduledTasks[_agentId].length < protocolParameters.maxScheduledTasksPerAgent, "SAAN: Agent reached max scheduled tasks");
        require(_rewardAmount >= protocolParameters.minTaskRewardAmount, "SAAN: Reward amount too low");
        require(_executeAfterTimestamp >= block.timestamp, "SAAN: Execution timestamp must be in the future");

        // Transfer reward tokens from the sender to the SAANProtocol (held as escrow)
        IERC20(_rewardToken).transferFrom(_msgSender(), address(this), _rewardAmount);

        uint256 scheduledId = _nextScheduledTaskId++;
        scheduledTasks[scheduledId] = ScheduledTask({
            agentId: _agentId,
            taskId: _taskId,
            assignedAt: block.timestamp,
            executeAfterTimestamp: _executeAfterTimestamp,
            conditionData: _conditionData,
            status: TaskExecutionStatus.Pending,
            rewardToken: _rewardToken,
            rewardAmount: _rewardAmount,
            executor: address(0),
            executedAt: 0,
            estimatedGasCost: 0, // This could be estimated better off-chain or by calling a dry-run
            failureReason: ""
        });
        agentScheduledTasks[_agentId].push(scheduledId);

        emit TaskScheduled(scheduledId, _agentId, _taskId, _executeAfterTimestamp);
        return scheduledId;
    }

    /**
     * @notice Removes a pending task from an agent's schedule and refunds reward tokens to the agent owner.
     * @param _scheduledTaskId The ID of the scheduled task to cancel.
     */
    function cancelScheduledTask(uint256 _scheduledTaskId) public {
        ScheduledTask storage scheduledTask = scheduledTasks[_scheduledTaskId];
        require(scheduledTask.status == TaskExecutionStatus.Pending, "SAAN: Task is not pending");
        require(agents[scheduledTask.agentId].owner == _msgSender() || owner() == _msgSender(), "SAAN: Not agent owner or protocol owner");

        scheduledTask.status = TaskExecutionStatus.Cancelled;

        // Refund reward token to the agent's owner
        if (scheduledTask.rewardAmount > 0) {
            IERC20(scheduledTask.rewardToken).transfer(agents[scheduledTask.agentId].owner, scheduledTask.rewardAmount);
            scheduledTask.rewardAmount = 0; // Clear reward to prevent double claim/refund
        }

        emit TaskCancelled(_scheduledTaskId, scheduledTask.agentId);
    }

    /**
     * @notice Assigns multiple tasks to multiple agents in a single transaction.
     *         Each assignment requires the `_msgSender()` to be the respective agent's owner.
     *         Requires reward amounts for all tasks to be approved to the SAANProtocol by `_msgSender()`.
     * @param _agentIds Array of agent IDs.
     * @param _taskIds Array of task definition IDs.
     * @param _executeAfterTimestamps Array of execution timestamps.
     * @param _conditionDatas Array of condition data bytes.
     * @param _rewardAmounts Array of reward amounts.
     * @param _rewardTokens Array of reward token addresses.
     */
    function batchAssignTasksToAgents(
        uint256[] memory _agentIds,
        uint256[] memory _taskIds,
        uint256[] memory _executeAfterTimestamps,
        bytes[] memory _conditionDatas,
        uint256[] memory _rewardAmounts,
        address[] memory _rewardTokens
    ) public {
        require(_agentIds.length > 0, "SAAN: No tasks to batch assign");
        require(_agentIds.length == _taskIds.length &&
                _taskIds.length == _executeAfterTimestamps.length &&
                _executeAfterTimestamps.length == _conditionDatas.length &&
                _conditionDatas.length == _rewardAmounts.length &&
                _rewardAmounts.length == _rewardTokens.length, "SAAN: Array lengths mismatch");

        for (uint256 i = 0; i < _agentIds.length; i++) {
            // Re-use assignTaskToAgent's internal logic and its access control.
            // This ensures `_msgSender()` is the owner for each agent being assigned a task.
            assignTaskToAgent(
                _agentIds[i],
                _taskIds[i],
                _executeAfterTimestamps[i],
                _conditionDatas[i],
                _rewardAmounts[i],
                _rewardTokens[i]
            );
        }
    }

    // --- IV. Execution & Incentivization Functions ---

    /**
     * @notice The core function, called by anyone (e.g., a keeper bot), to attempt execution of a scheduled task.
     *         Performs external calls on behalf of the agent if all conditions are met.
     *         Pays out a reward (minus protocol fee) to the successful executor.
     * @param _scheduledTaskId The ID of the scheduled task to execute.
     */
    function executeAgentTask(uint256 _scheduledTaskId) public {
        ScheduledTask storage scheduledTask = scheduledTasks[_scheduledTaskId];
        require(scheduledTask.status == TaskExecutionStatus.Pending, "SAAN: Task is not pending or already executed");

        AutonomousAgent storage agent = agents[scheduledTask.agentId];
        require(agent.status == AgentStatus.Active, "SAAN: Agent not active for execution");
        require(agent.capabilityScore >= taskDefinitions[scheduledTask.taskId].requiredCapability, "SAAN: Agent capability too low for this task");

        // Check time condition
        require(block.timestamp >= scheduledTask.executeAfterTimestamp, "SAAN: Task not yet due");
        require(block.timestamp <= scheduledTask.executeAfterTimestamp + protocolParameters.maxTaskExecutionTimeBuffer, "SAAN: Task execution window expired");

        // Check external condition via oracle if specified
        if (scheduledTask.conditionData.length > 0) {
            bool conditionMet = false;
            // Iterate over trusted oracles to find one that can validate the condition.
            // This is a simplified example; a real system might specify which oracle to use in conditionData.
            for (address oracleAddr : trustedOracles.keys()) { // `keys()` is not natively supported by mappings, this is conceptual.
                                                              // In practice, an array of oracle addresses would be maintained.
                if (trustedOracles[oracleAddr] && IOracle(oracleAddr).isValidCondition(scheduledTask.conditionData)) {
                    conditionMet = true;
                    break;
                }
            }
            require(conditionMet, "SAAN: External condition not met via trusted oracle");
        }

        TaskDefinition storage task = taskDefinitions[scheduledTask.taskId];
        require(task.isActive, "SAAN: Task definition inactive");

        // Attempt to execute all calls in the task definition
        uint256 startGas = gasleft();
        bool success = true;
        for (uint256 i = 0; i < task.callData.length; i++) {
            require(whitelistedExternalContracts[task.targets[i]], "SAAN: Target contract not whitelisted during execution");

            (bool callSuccess, bytes memory returnData) = task.targets[i].call{gas: task.gasLimitPerCall}(task.callData[i]);
            if (!callSuccess) {
                success = false;
                // Capture more specific error from returnData if possible
                string memory reason = returnData.length > 0 ? abi.decode(returnData, (string)) : "Unknown reason";
                scheduledTask.failureReason = string(abi.encodePacked("Sub-call ", Strings.toString(i), " failed: ", reason));
                break;
            }
        }
        uint256 endGas = gasleft();
        scheduledTask.estimatedGasCost = startGas - endGas; // Approximated gas cost for the internal transaction part

        if (success) {
            scheduledTask.status = TaskExecutionStatus.Executed;
            scheduledTask.executor = _msgSender();
            scheduledTask.executedAt = block.timestamp;

            // Pay reward to executor (keeper)
            uint256 rewardToExecutor = scheduledTask.rewardAmount;
            uint256 protocolFee = (rewardToExecutor * protocolParameters.protocolFeeBps) / 10000;
            rewardToExecutor -= protocolFee;

            protocolFeesCollected[scheduledTask.rewardToken] += protocolFee;

            IERC20(scheduledTask.rewardToken).transfer(_msgSender(), rewardToExecutor);

            emit TaskExecuted(_scheduledTaskId, scheduledTask.agentId, _msgSender(), rewardToExecutor);
        } else {
            scheduledTask.status = TaskExecutionStatus.Failed;
            emit TaskExecutionFailed(_scheduledTaskId, scheduledTask.agentId, _msgSender(), scheduledTask.failureReason);
        }
    }

    /**
     * @notice Allows the agent's owner to claim back reward tokens for failed or cancelled tasks.
     *         Reward tokens from successfully executed tasks are sent directly to the executor.
     * @param _scheduledTaskId The ID of the scheduled task.
     */
    function claimTaskReward(uint256 _scheduledTaskId) public onlyAgentOwner(scheduledTasks[_scheduledTaskId].agentId) {
        ScheduledTask storage scheduledTask = scheduledTasks[_scheduledTaskId];
        require(scheduledTask.rewardAmount > 0, "SAAN: No reward for this task or already claimed");
        require(scheduledTask.status == TaskExecutionStatus.Failed || scheduledTask.status == TaskExecutionStatus.Cancelled, "SAAN: Reward only claimable for failed/cancelled tasks by owner");

        address agentOwner = agents[scheduledTask.agentId].owner;
        uint256 amountToClaim = scheduledTask.rewardAmount;

        // Reset reward to prevent double claims
        scheduledTask.rewardAmount = 0;

        // Transfer funds from protocol (which holds the original reward) to agent owner
        IERC20(scheduledTask.rewardToken).transfer(agentOwner, amountToClaim);
        emit TaskRewardClaimed(_scheduledTaskId, agentOwner, amountToClaim, scheduledTask.rewardToken);
    }

    /**
     * @notice An agent (via its owner or a delegated entity) submits proof/data of an observed event or execution.
     *         This attestation can later influence its capability score, be used for auditing, or trigger other logic.
     * @param _agentId The ID of the agent submitting the attestation.
     * @param _attestationType A string describing the type of attestation (e.g., "Observation", "Verification", "ProofOfWork").
     * @param _attestationData The raw data of the attestation.
     */
    function submitAgentAttestation(
        uint256 _agentId,
        string memory _attestationType,
        bytes memory _attestationData
    ) public onlyAgentOwner(_agentId) onlyAgentActive(_agentId) {
        // This function simply records the attestation event.
        // The actual validation and capability score adjustment would typically happen
        // off-chain or via a separate governance process triggered by this event.
        emit AgentAttestationSubmitted(_agentId, _attestationType, _attestationData);
    }

    // --- V. Protocol Governance & Parameter Tuning Functions ---

    /**
     * @notice Adjusts an agent's capability score. This can be based on performance, attestations, or direct governance vote.
     * @dev Only callable by the protocol owner (governance).
     * @param _agentId The ID of the agent whose capability to update.
     * @param _capabilityChange The amount to add or subtract from the current capability score (can be negative).
     */
    function updateAgentCapability(uint256 _agentId, int256 _capabilityChange) public onlyOwner {
        require(agents[_agentId].status != AgentStatus.Terminated, "SAAN: Cannot update terminated agent's capability");
        uint256 oldScore = agents[_agentId].capabilityScore;
        int256 newScoreInt = int256(oldScore) + _capabilityChange;
        require(newScoreInt >= 0, "SAAN: Capability score cannot be negative");

        agents[_agentId].capabilityScore = uint256(newScoreInt);
        emit AgentCapabilityUpdated(_agentId, oldScore, agents[_agentId].capabilityScore);
    }

    /**
     * @notice Updates the global protocol parameters.
     * @dev Only callable by the protocol owner (governance).
     * @param _maxActiveAgents New maximum number of active agents an owner can have. (Currently not used, global cap)
     * @param _maxScheduledTasksPerAgent New maximum scheduled tasks per agent.
     * @param _minCapabilityScore New minimum capability score for new agents.
     * @param _protocolFeeBps New protocol fee in basis points.
     * @param _minTaskRewardAmount New minimum reward amount for a task.
     * @param _maxTaskExecutionTimeBuffer New maximum time buffer for task execution.
     */
    function setProtocolParameters(
        uint256 _maxActiveAgents,
        uint256 _maxScheduledTasksPerAgent,
        uint256 _minCapabilityScore,
        uint256 _protocolFeeBps,
        uint256 _minTaskRewardAmount,
        uint256 _maxTaskExecutionTimeBuffer
    ) public onlyOwner {
        require(_maxActiveAgents > 0, "SAAN: Max active agents must be positive");
        require(_maxScheduledTasksPerAgent > 0, "SAAN: Max scheduled tasks per agent must be positive");
        require(_protocolFeeBps <= 10000, "SAAN: Protocol fee cannot exceed 100%"); // 10000 bps = 100%

        protocolParameters = ProtocolParameters({
            maxActiveAgents: _maxActiveAgents,
            maxScheduledTasksPerAgent: _maxScheduledTasksPerAgent,
            minCapabilityScore: _minCapabilityScore,
            protocolFeeBps: _protocolFeeBps,
            minTaskRewardAmount: _minTaskRewardAmount,
            maxTaskExecutionTimeBuffer: _maxTaskExecutionTimeBuffer,
            defaultGasLimitPerCall: protocolParameters.defaultGasLimitPerCall // Retain old value if not updated via separate function
        });

        emit ProtocolParametersUpdated(protocolParameters);
    }

    /**
     * @notice Whitelists/unwhitelists an address that can provide external data for task conditions.
     * @dev Only callable by the protocol owner (governance).
     * @param _oracleAddress The address of the oracle.
     * @param _isTrusted Whether to trust or untrust the oracle.
     */
    function setTrustedOracle(address _oracleAddress, bool _isTrusted) public onlyOwner {
        require(_oracleAddress != address(0), "SAAN: Invalid oracle address");
        trustedOracles[_oracleAddress] = _isTrusted;
        emit TrustedOracleStatusUpdated(_oracleAddress, _isTrusted);
    }

    /**
     * @notice Whitelists/unwhitelists external contracts that agents are allowed to interact with.
     *         This is a security measure to prevent agents from calling malicious contracts.
     * @dev Only callable by the protocol owner (governance).
     * @param _contractAddress The address of the external contract.
     * @param _canInteract Whether agents can interact with this contract.
     */
    function registerExternalContract(address _contractAddress, bool _canInteract) public onlyOwner {
        require(_contractAddress != address(0), "SAAN: Invalid contract address");
        // Prevent accidental removal of `this` from the whitelist, though it's set in constructor.
        require(_contractAddress != address(this), "SAAN: Cannot modify status of protocol contract itself");
        whitelistedExternalContracts[_contractAddress] = _canInteract;
        emit ExternalContractWhitelisted(_contractAddress, _canInteract);
    }

    /**
     * @notice Allows the protocol owner/governance to withdraw collected protocol fees.
     * @dev Only callable by the protocol owner (governance).
     * @param _tokenAddress The address of the token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawProtocolFees(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(_tokenAddress != address(0), "SAAN: Invalid token address");
        require(protocolFeesCollected[_tokenAddress] >= _amount, "SAAN: Insufficient collected fees");
        
        protocolFeesCollected[_tokenAddress] -= _amount;
        IERC20(_tokenAddress).transfer(_msgSender(), _amount);
        emit ProtocolFeesWithdrawn(_tokenAddress, _amount);
    }
    
    // --- Fallback and Receive Functions for ETH Handling ---
    receive() external payable {}
    fallback() external payable {}
}
```