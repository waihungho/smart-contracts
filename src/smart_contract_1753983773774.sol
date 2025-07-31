This smart contract, "Aetherius AI Nexus," is designed to create a decentralized ecosystem for AI agent development, task execution, and on-chain reputation building. It focuses on advanced concepts like dynamic NFT metadata driven by agent progression, a robust tasking system validated by an oracle (simulating AI evaluation), and a sophisticated skill tree for agents.

---

## **Aetherius AI Nexus: Smart Contract Outline & Function Summary**

**Contract Name:** `AetheriusAINexus`

**Core Concepts:**
*   **Dynamic AI Agent NFTs (ERC721):** Agents are NFTs whose metadata (level, skills) changes on-chain based on their progression.
*   **Skill Tree Progression:** Agents acquire skills with prerequisites, contributing to their capabilities.
*   **Decentralized Tasking Network:** Users post tasks, and agents (via their owners) complete them, earning rewards and reputation.
*   **Oracle-Driven AI Validation:** Task solutions are validated by an external oracle, simulating AI's role in evaluating outcomes.
*   **On-Chain Reputation System:** Separate reputation scores for user wallets and individual AI Agents, influencing their capabilities and access.
*   **Resource Token (ERC20):** A custom ERC20 token (`AGENT_TOKEN`) is used for agent creation, skill acquisition, task bounties, and rewards.

---

### **I. Contract Setup & Core Interfaces**

*   `Ownable`: Standard access control for admin functions.
*   `ERC721Enumerable`: For manageable and iterable agent NFTs.
*   `ERC20`: For the native `AGENT_TOKEN`.
*   `IAetheriusOracle`: Interface for the external AI validation oracle.

### **II. Custom Errors**

*   `Unauthorized()`: Caller lacks required permissions.
*   `TaskNotFound(uint256 taskId)`: Specified task ID does not exist.
*   `AgentNotFound(uint256 agentId)`: Specified agent ID does not exist.
*   `SkillNotFound(uint256 skillId)`: Specified skill ID does not exist.
*   `InsufficientFunds(uint256 required, uint256 available)`: Caller doesn't have enough `AGENT_TOKEN`.
*   `InvalidAmount()`: Zero or negative amount provided where positive is required.
*   `TaskNotPending()`: Task is not in `Pending` status.
*   `TaskNotAssigned()`: Task is not in `Assigned` status.
*   `TaskAlreadyAssigned()`: Task is already assigned to an agent.
*   `TaskNotCompleted()`: Task is not in `Completed` status.
*   `TaskAlreadyCompleted()`: Task has already been completed.
*   `TaskRequiresAgent()`: Task can only be completed by an agent.
*   `AgentNotOwner()`: Caller is not the owner of the specified agent.
*   `AgentAlreadyHasSkill()`: Agent already possesses the specified skill.
*   `AgentLevelTooLow(uint256 current, uint256 required)`: Agent's level is below the requirement.
*   `MissingSkillPrerequisite(uint256 missingSkillId)`: Agent lacks a required prerequisite skill.
*   `InvalidOracleResponse()`: Oracle response is not valid.
*   `InvalidTaskStatus()`: Current task status prevents the action.
*   `TaskRequirementsNotMet()`: Agent/User does not meet task requirements.
*   `InvalidAgentIDForTask()`: Provided agent ID is not valid for the task.
*   `EmergencyPaused()`: Contract is currently paused.

### **III. Events**

*   `AgentMinted(uint256 indexed agentId, address indexed owner, string name, uint256 initialLevel)`
*   `AgentLeveledUp(uint256 indexed agentId, uint256 newLevel)`
*   `SkillDefined(uint256 indexed skillId, string name, string description, uint256[] prerequisites)`
*   `SkillAssigned(uint256 indexed agentId, uint256 indexed skillId)`
*   `TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 bounty, uint256 requiredAgentLevel)`
*   `TaskAssigned(uint256 indexed taskId, uint256 indexed agentId)`
*   `TaskSolutionSubmitted(uint256 indexed taskId, address indexed submitter, uint256 indexed agentId)`
*   `TaskCompleted(uint256 indexed taskId, address indexed resolver, uint256 indexed agentId, uint256 reputationEarned)`
*   `TaskCanceled(uint256 indexed taskId)`
*   `TaskValidationRequested(uint256 indexed taskId, uint256 indexed agentId)`
*   `UserReputationUpdated(address indexed user, int256 change, uint256 newReputation)`
*   `AgentReputationUpdated(uint256 indexed agentId, int256 change, uint256 newReputation)`
*   `EmergencyPause(address indexed caller, bool pausedState)`

### **IV. Structs & Enums**

*   `enum TaskStatus { Pending, Assigned, Validating, Completed, Canceled }`
*   `struct Agent`: `level`, `reputation`, `name`, `lastMetadataUpdateBlock`
*   `struct Skill`: `name`, `description`, `prerequisites` (array of skill IDs)
*   `struct Task`: `creator`, `title`, `description`, `bounty`, `assignedAgentId`, `assignedAgentOwner`, `requiredAgentLevel`, `requiredUserReputation`, `status`, `submittedSolutionCID`, `creationBlock`

### **V. State Variables**

*   `nextAgentId`: Counter for new agent NFTs.
*   `nextSkillId`: Counter for new skills.
*   `nextTaskId`: Counter for new tasks.
*   `oracleAddress`: Address of the AI validation oracle.
*   `_agentToken`: ERC20 token contract instance.
*   `agents`: Mapping from `agentId` to `Agent` struct.
*   `skills`: Mapping from `skillId` to `Skill` struct.
*   `tasks`: Mapping from `taskId` to `Task` struct.
*   `userReputation`: Mapping from `address` to `uint256`.
*   `agentSkills`: Nested mapping from `agentId` to `skillId` to `bool` (true if agent has skill).
*   `baseURI`: Base URI for agent NFT metadata.
*   `metadataUpdateCooldown`: Cooldown period for on-chain metadata updates.
*   `paused`: Boolean to indicate emergency pause state.

### **VI. Modifiers**

*   `onlyOracle()`: Ensures caller is the designated oracle.
*   `whenNotPaused()`: Prevents execution if contract is paused.
*   `whenPaused()`: Allows execution only if contract is paused.
*   `taskExists(uint256 _taskId)`: Checks if a task exists.
*   `isTaskCreator(uint256 _taskId)`: Checks if caller is the task creator.
*   `isAgentOwner(uint256 _agentId)`: Checks if caller owns the agent.

### **VII. Functions (by Category)**

---

**A. Admin & Core Setup Functions**

1.  `constructor(address _initialOracle, address _erc20TokenAddress, string memory _baseURI)`
    *   Initializes `Ownable`, sets the initial oracle address, ERC20 token contract, and base URI for NFTs.
2.  `setOracleAddress(address _newOracle)` (Owner Only)
    *   **Summary:** Sets or updates the address of the AI validation oracle.
3.  `updateBaseURI(string memory _newBaseURI)` (Owner Only)
    *   **Summary:** Updates the base URI for agent NFT metadata.
4.  `emergencyPause()` (Owner Only)
    *   **Summary:** Pauses the contract, preventing most state-changing operations.
5.  `unpause()` (Owner Only)
    *   **Summary:** Unpauses the contract, resuming normal operations.
6.  `withdrawFunds(address _tokenAddress, uint256 _amount)` (Owner Only)
    *   **Summary:** Allows the owner to withdraw any specified ERC20 tokens stuck in the contract.
7.  `defineSkill(string memory _name, string memory _description, uint256[] memory _prerequisites)` (Owner Only)
    *   **Summary:** Creates a new skill type that agents can learn, including its prerequisites.

---

**B. Agent Management Functions (ERC721 & Progression)**

8.  `mintAgentNFT(string memory _name)`
    *   **Summary:** Mints a new AI Agent NFT to the caller. Requires `AGENT_TOKEN` fee.
9.  `levelUpAgent(uint256 _agentId)`
    *   **Summary:** Levels up an agent, increasing its capabilities. Requires `AGENT_TOKEN` fee and owner. Agent must meet reputation thresholds to level up.
10. `assignSkillToAgent(uint256 _agentId, uint256 _skillId)`
    *   **Summary:** Assigns a defined skill to a specific agent. Requires `AGENT_TOKEN` fee, agent ownership, and agent must meet skill prerequisites (level, other skills).
11. `tokenURI(uint256 _tokenId)` (View)
    *   **Summary:** Returns the URI for the given agent NFT's metadata, dynamically generated based on current level and skills.

---

**C. Task Network Functions**

12. `createTask(string memory _title, string memory _description, uint256 _bounty, uint256 _requiredAgentLevel, uint256 _requiredUserReputation)`
    *   **Summary:** Creates a new task that can be picked up by an agent. Requires locking `AGENT_TOKEN` as bounty.
13. `assignTaskToAgent(uint256 _taskId, uint256 _agentId)`
    *   **Summary:** Assigns an open task to a specific agent for completion. Checks agent level and user reputation against task requirements. Only the task creator or agent owner can assign.
14. `submitTaskSolution(uint256 _taskId, uint256 _agentId, string memory _solutionCID)`
    *   **Summary:** Submits a solution (e.g., IPFS CID of results) for an assigned task. Triggers an oracle request for validation.
15. `receiveOracleResponse(uint256 _taskId, bool _isValid, string memory _oracleFeedback)` (Oracle Only)
    *   **Summary:** Callback function for the oracle to return validation results for a task solution. If valid, completes the task and distributes rewards.
16. `cancelTask(uint256 _taskId)`
    *   **Summary:** Allows the task creator to cancel a pending or assigned task, returning the bounty if not completed.

---

**D. Reputation & Query Functions**

17. `getUserReputation(address _user)` (View)
    *   **Summary:** Returns the reputation score of a specific user wallet.
18. `getAgentReputation(uint256 _agentId)` (View)
    *   **Summary:** Returns the reputation score of a specific AI agent.
19. `getAgentDetails(uint256 _agentId)` (View)
    *   **Summary:** Returns comprehensive details about a specific AI agent.
20. `getAgentSkills(uint256 _agentId)` (View)
    *   **Summary:** Returns a list of skill IDs possessed by a specific agent.
21. `getSkillDetails(uint256 _skillId)` (View)
    *   **Summary:** Returns details about a specific defined skill.
22. `getTaskDetails(uint256 _taskId)` (View)
    *   **Summary:** Returns comprehensive details about a specific task.
23. `getPendingTasks()` (View)
    *   **Summary:** Returns a list of all task IDs that are currently in a `Pending` status.

---

**E. Internal Helper Functions**

*   `_updateReputation(address _entity, uint256 _id, int256 _change, bool _isAgent)`: Internal helper to update user or agent reputation.
*   `_updateAgentMetadata(uint256 _agentId)`: Internal helper to trigger metadata refresh (simulated) for an agent.
*   `_requestAIValidation(uint256 _taskId, uint256 _agentId, string memory _solutionCID)`: Internal function to simulate an oracle call for AI validation.

---

**Note on "AI" & "Dynamic NFT Metadata":**
*   **AI:** The AI functionality is simulated through an `IAetheriusOracle` interface. In a real-world scenario, this oracle would be a decentralized network like Chainlink, feeding results from off-chain AI models (e.g., evaluating solution quality, generating content, etc.).
*   **Dynamic NFT Metadata:** While the `tokenURI` points to a static base, the contract maintains the agent's internal state (level, skills). A separate off-chain service (e.g., a backend server or IPFS gateway) would listen to `AgentLeveledUp` and `SkillAssigned` events, generate new JSON metadata files based on the updated on-chain state, and upload them to IPFS, ensuring the `tokenURI` resolves to the most current representation of the NFT. The `lastMetadataUpdateBlock` is a rudimentary way to signal a potential metadata change.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- INTERFACES ---

/// @title IAetheriusOracle
/// @notice Interface for an external oracle service that provides AI validation for tasks.
interface IAetheriusOracle {
    function requestValidation(
        uint256 taskId,
        uint256 agentId,
        string calldata solutionCID,
        address callbackContract,
        bytes4 callbackSelector
    ) external;
}

// --- ERRORS ---

error Unauthorized();
error TaskNotFound(uint256 taskId);
error AgentNotFound(uint256 agentId);
error SkillNotFound(uint256 skillId);
error InsufficientFunds(uint256 required, uint256 available);
error InvalidAmount();
error TaskNotPending();
error TaskNotAssigned();
error TaskAlreadyAssigned();
error TaskNotCompleted();
error TaskAlreadyCompleted();
error TaskRequiresAgent();
error AgentNotOwner();
error AgentAlreadyHasSkill();
error AgentLevelTooLow(uint256 current, uint256 required);
error MissingSkillPrerequisite(uint256 missingSkillId);
error InvalidOracleResponse();
error InvalidTaskStatus();
error TaskRequirementsNotMet();
error InvalidAgentIDForTask();
error EmergencyPaused(); // Custom error for emergency pause/unpause.

/// @title AetheriusAINexus
/// @notice A decentralized ecosystem for AI agent development, task execution, and on-chain reputation building.
/// @dev This contract implements dynamic NFT metadata (via off-chain service), oracle-driven task validation,
///      and a comprehensive skill and reputation system for AI agents.
contract AetheriusAINexus is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- STATE VARIABLES ---

    Counters.Counter private _nextAgentId;
    Counters.Counter private _nextSkillId;
    Counters.Counter private _nextTaskId;

    address public oracleAddress; // Address of the AI validation oracle
    ERC20 private _agentToken;    // ERC20 token for payments and rewards

    string private _baseURI;      // Base URI for agent NFT metadata (dynamic via off-chain logic)
    uint256 public metadataUpdateCooldown; // Cooldown period for on-chain metadata updates (simulated)

    // --- ENUMS ---

    enum TaskStatus {
        Pending,   // Task created, awaiting assignment
        Assigned,  // Task assigned to an agent/user
        Validating, // Solution submitted, awaiting oracle validation
        Completed, // Task successfully validated and rewards distributed
        Canceled   // Task canceled by creator
    }

    // --- STRUCTS ---

    /// @dev Represents an AI Agent as an NFT.
    struct Agent {
        uint256 level;
        uint256 reputation;
        string name;
        uint256 lastMetadataUpdateBlock; // Tracks block of last significant update for metadata refresh
    }

    /// @dev Defines a specific skill an agent can learn.
    struct Skill {
        string name;
        string description;
        uint256[] prerequisites; // Skill IDs that must be learned before this one
    }

    /// @dev Represents a task to be completed within the network.
    struct Task {
        address creator;
        string title;
        string description;
        uint256 bounty; // Amount of AGENT_TOKEN locked for the task
        uint256 assignedAgentId; // 0 if not assigned, agentId if assigned
        address assignedAgentOwner; // Owner of the assigned agent
        uint256 requiredAgentLevel;
        uint256 requiredUserReputation;
        TaskStatus status;
        string submittedSolutionCID; // IPFS CID of the solution
        uint256 creationBlock;
    }

    // --- MAPPINGS ---

    mapping(uint256 => Agent) public agents;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256) public userReputation; // Reputation for user wallets
    mapping(uint256 => mapping(uint256 => bool)) public agentSkills; // agentId => skillId => hasSkill

    // --- EVENTS ---

    event AgentMinted(uint256 indexed agentId, address indexed owner, string name, uint256 initialLevel);
    event AgentLeveledUp(uint256 indexed agentId, uint256 newLevel);
    event SkillDefined(uint256 indexed skillId, string name, string description, uint256[] prerequisites);
    event SkillAssigned(uint256 indexed agentId, uint256 indexed skillId);
    event TaskCreated(uint256 indexed taskId, address indexed creator, string title, uint256 bounty, uint256 requiredAgentLevel);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed agentId);
    event TaskSolutionSubmitted(uint256 indexed taskId, address indexed submitter, uint256 indexed agentId);
    event TaskCompleted(uint256 indexed taskId, address indexed resolver, uint256 indexed agentId, uint256 reputationEarned);
    event TaskCanceled(uint256 indexed taskId);
    event TaskValidationRequested(uint256 indexed taskId, uint256 indexed agentId);
    event UserReputationUpdated(address indexed user, int256 change, uint256 newReputation);
    event AgentReputationUpdated(uint256 indexed agentId, int256 change, uint256 newReputation);
    event EmergencyPause(address indexed caller, bool pausedState);

    // --- MODIFIERS ---

    /// @dev Ensures the caller is the designated oracle.
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Checks if a task exists.
    modifier taskExists(uint256 _taskId) {
        if (_taskId == 0 || tasks[_taskId].creator == address(0)) {
            revert TaskNotFound(_taskId);
        }
        _;
    }

    /// @dev Checks if the caller is the creator of the task.
    modifier isTaskCreator(uint256 _taskId) {
        if (tasks[_taskId].creator != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Checks if the caller is the owner of the specified agent.
    modifier isAgentOwner(uint256 _agentId) {
        if (ownerOf(_agentId) != msg.sender) {
            revert AgentNotOwner();
        }
        _;
    }

    // --- CONSTRUCTOR ---

    /// @dev Constructs the AetheriusAINexus contract.
    /// @param _initialOracle The initial address of the AI validation oracle.
    /// @param _erc20TokenAddress The address of the AGENT_TOKEN ERC20 contract.
    /// @param _baseURI_ The base URI for agent NFT metadata.
    constructor(address _initialOracle, address _erc20TokenAddress, string memory _baseURI_) ERC721Enumerable("Aetherius AI Agent", "AIA") Ownable(msg.sender) {
        if (_initialOracle == address(0) || _erc20TokenAddress == address(0)) {
            revert InvalidAmount(); // Reusing error for null addresses
        }
        oracleAddress = _initialOracle;
        _agentToken = ERC20(_erc20TokenAddress);
        _baseURI = _baseURI_;
        metadataUpdateCooldown = 1 days; // Example: can only trigger metadata update every 24 hours
    }

    // --- ADMIN & CORE SETUP FUNCTIONS ---

    /// @notice Sets or updates the address of the AI validation oracle.
    /// @dev Can only be called by the contract owner.
    /// @param _newOracle The new address for the oracle.
    function setOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) {
            revert InvalidAmount();
        }
        oracleAddress = _newOracle;
    }

    /// @notice Updates the base URI for agent NFT metadata.
    /// @dev An off-chain service is expected to generate dynamic metadata based on on-chain state.
    /// @param _newBaseURI The new base URI.
    function updateBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURI = _newBaseURI;
    }

    /// @notice Pauses the contract in case of emergency or maintenance.
    /// @dev Prevents most state-changing operations. Only callable by owner.
    function emergencyPause() external onlyOwner whenNotPaused {
        _pause();
        emit EmergencyPause(msg.sender, true);
    }

    /// @notice Unpauses the contract after an emergency or maintenance.
    /// @dev Only callable by owner.
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit EmergencyPause(msg.sender, false);
    }

    /// @notice Allows the owner to withdraw any specified ERC20 tokens stuck in the contract.
    /// @dev This is a safeguard for accidental token transfers.
    /// @param _tokenAddress The address of the ERC20 token to withdraw.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawFunds(address _tokenAddress, uint256 _amount) external onlyOwner {
        if (_tokenAddress == address(0) || _amount == 0) {
            revert InvalidAmount();
        }
        if (ERC20(_tokenAddress).balanceOf(address(this)) < _amount) {
            revert InsufficientFunds(
                _amount,
                ERC20(_tokenAddress).balanceOf(address(this))
            );
        }
        ERC20(_tokenAddress).transfer(owner(), _amount);
    }

    /// @notice Defines a new skill type that agents can learn.
    /// @dev Only callable by the contract owner.
    /// @param _name The name of the skill.
    /// @param _description A brief description of the skill.
    /// @param _prerequisites An array of skill IDs that must be learned before this one.
    function defineSkill(string memory _name, string memory _description, uint256[] memory _prerequisites) external onlyOwner {
        _nextSkillId.increment();
        uint256 skillId = _nextSkillId.current();

        for (uint256 i = 0; i < _prerequisites.length; i++) {
            if (_prerequisites[i] == 0 || skills[_prerequisites[i]].name == "") {
                revert SkillNotFound(_prerequisites[i]);
            }
        }

        skills[skillId] = Skill({
            name: _name,
            description: _description,
            prerequisites: _prerequisites
        });

        emit SkillDefined(skillId, _name, _description, _prerequisites);
    }

    // --- AGENT MANAGEMENT FUNCTIONS ---

    /// @notice Mints a new AI Agent NFT to the caller.
    /// @dev Requires a fee in AGENT_TOKEN.
    /// @param _name The desired name for the new agent.
    function mintAgentNFT(string memory _name) external nonReentrant whenNotPaused {
        uint256 mintCost = 100 * (10**_agentToken.decimals()); // Example cost
        if (_agentToken.balanceOf(msg.sender) < mintCost) {
            revert InsufficientFunds(mintCost, _agentToken.balanceOf(msg.sender));
        }

        _nextAgentId.increment();
        uint256 newAgentId = _nextAgentId.current();

        _agentToken.transferFrom(msg.sender, address(this), mintCost);

        agents[newAgentId] = Agent({
            level: 1,
            reputation: 0,
            name: _name,
            lastMetadataUpdateBlock: block.number
        });

        _mint(msg.sender, newAgentId);
        emit AgentMinted(newAgentId, msg.sender, _name, 1);
        _updateReputation(msg.sender, 0, 10, false); // Initial user reputation boost
    }

    /// @notice Levels up an agent, increasing its capabilities.
    /// @dev Requires AGENT_TOKEN fee, agent ownership, and minimum reputation.
    /// @param _agentId The ID of the agent to level up.
    function levelUpAgent(uint256 _agentId) external nonReentrant whenNotPaused isAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        if (agent.name == "") {
            revert AgentNotFound(_agentId);
        }

        uint256 currentLevel = agent.level;
        uint256 nextLevel = currentLevel + 1;
        uint256 levelUpCost = nextLevel * 50 * (10**_agentToken.decimals()); // Cost scales with level
        uint256 requiredAgentReputation = nextLevel * 10; // Reputation requirement scales

        if (_agentToken.balanceOf(msg.sender) < levelUpCost) {
            revert InsufficientFunds(levelUpCost, _agentToken.balanceOf(msg.sender));
        }
        if (agent.reputation < requiredAgentReputation) {
            revert AgentLevelTooLow(agent.reputation, requiredAgentReputation); // Reusing for reputation check
        }

        _agentToken.transferFrom(msg.sender, address(this), levelUpCost);
        agent.level = nextLevel;
        agent.lastMetadataUpdateBlock = block.number; // Signal metadata update

        emit AgentLeveledUp(_agentId, nextLevel);
        _updateReputation(msg.sender, _agentId, 5, true); // Agent reputation boost
        _updateReputation(msg.sender, 0, 2, false); // User reputation boost
    }

    /// @notice Assigns a defined skill to a specific agent.
    /// @dev Requires AGENT_TOKEN fee, agent ownership, and agent must meet skill prerequisites.
    /// @param _agentId The ID of the agent.
    /// @param _skillId The ID of the skill to assign.
    function assignSkillToAgent(uint256 _agentId, uint256 _skillId) external nonReentrant whenNotPaused isAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        Skill storage skill = skills[_skillId];

        if (agent.name == "") {
            revert AgentNotFound(_agentId);
        }
        if (skill.name == "") {
            revert SkillNotFound(_skillId);
        }
        if (agentSkills[_agentId][_skillId]) {
            revert AgentAlreadyHasSkill();
        }

        // Check prerequisites
        for (uint224 i = 0; i < skill.prerequisites.length; i++) {
            if (!agentSkills[_agentId][skill.prerequisites[i]]) {
                revert MissingSkillPrerequisite(skill.prerequisites[i]);
            }
        }

        // Skill acquisition cost
        uint256 skillCost = 200 * (10**_agentToken.decimals());
        if (_agentToken.balanceOf(msg.sender) < skillCost) {
            revert InsufficientFunds(skillCost, _agentToken.balanceOf(msg.sender));
        }

        _agentToken.transferFrom(msg.sender, address(this), skillCost);
        agentSkills[_agentId][_skillId] = true;
        agent.lastMetadataUpdateBlock = block.number; // Signal metadata update

        emit SkillAssigned(_agentId, _skillId);
        _updateReputation(msg.sender, _agentId, 10, true); // Agent reputation boost
        _updateReputation(msg.sender, 0, 5, false); // User reputation boost
    }

    /// @notice Returns the URI for the given agent NFT's metadata.
    /// @dev The URI is dynamically generated off-chain based on the agent's current state.
    /// @param _tokenId The ID of the agent NFT.
    /// @return string The URI pointing to the agent's metadata.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert ERC721NonexistentToken(_tokenId);
        }
        // In a real scenario, this would trigger an off-chain service to update
        // the metadata file on IPFS/Arweave when agent state changes.
        // For this example, we just append agent details to the baseURI for demonstration.
        // The actual dynamic metadata generation happens by an off-chain service
        // listening to AgentLeveledUp and SkillAssigned events.
        // The `lastMetadataUpdateBlock` can be used as a hint for the off-chain service.

        return string(abi.encodePacked(_baseURI, Strings.toString(_tokenId)));
    }

    // --- TASK NETWORK FUNCTIONS ---

    /// @notice Creates a new task that can be picked up by an agent.
    /// @dev Requires locking AGENT_TOKEN as bounty.
    /// @param _title The title of the task.
    /// @param _description A detailed description of the task.
    /// @param _bounty The amount of AGENT_TOKEN rewarded upon successful completion.
    /// @param _requiredAgentLevel The minimum agent level required for this task.
    /// @param _requiredUserReputation The minimum user reputation required to assign an agent to this task.
    function createTask(
        string memory _title,
        string memory _description,
        uint256 _bounty,
        uint256 _requiredAgentLevel,
        uint256 _requiredUserReputation
    ) external nonReentrant whenNotPaused {
        if (_bounty == 0 || bytes(_title).length == 0 || bytes(_description).length == 0) {
            revert InvalidAmount();
        }
        if (_agentToken.balanceOf(msg.sender) < _bounty) {
            revert InsufficientFunds(_bounty, _agentToken.balanceOf(msg.sender));
        }

        _agentToken.transferFrom(msg.sender, address(this), _bounty);

        _nextTaskId.increment();
        uint256 newTaskId = _nextTaskId.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            title: _title,
            description: _description,
            bounty: _bounty,
            assignedAgentId: 0,
            assignedAgentOwner: address(0),
            requiredAgentLevel: _requiredAgentLevel,
            requiredUserReputation: _requiredUserReputation,
            status: TaskStatus.Pending,
            submittedSolutionCID: "",
            creationBlock: block.number
        });

        emit TaskCreated(newTaskId, msg.sender, _title, _bounty, _requiredAgentLevel);
    }

    /// @notice Assigns an open task to a specific agent for completion.
    /// @dev Checks agent level and user reputation against task requirements.
    /// @param _taskId The ID of the task to assign.
    /// @param _agentId The ID of the agent to assign the task to.
    function assignTaskToAgent(uint256 _taskId, uint256 _agentId) external nonReentrant whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        if (agent.name == "") {
            revert AgentNotFound(_agentId);
        }
        if (ownerOf(_agentId) != msg.sender) { // Check if sender owns the agent
            revert AgentNotOwner();
        }
        if (task.status != TaskStatus.Pending) {
            revert TaskAlreadyAssigned(); // Also covers other non-pending states
        }
        if (agent.level < task.requiredAgentLevel || userReputation[msg.sender] < task.requiredUserReputation) {
            revert TaskRequirementsNotMet();
        }

        task.assignedAgentId = _agentId;
        task.assignedAgentOwner = msg.sender;
        task.status = TaskStatus.Assigned;

        emit TaskAssigned(_taskId, _agentId);
    }

    /// @notice Submits a solution for an assigned task.
    /// @dev Triggers an oracle request for validation. Can only be called by the assigned agent's owner.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the agent that completed the task.
    /// @param _solutionCID The IPFS CID of the solution details.
    function submitTaskSolution(uint256 _taskId, uint256 _agentId, string memory _solutionCID) external nonReentrant whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];

        if (task.status != TaskStatus.Assigned) {
            revert InvalidTaskStatus();
        }
        if (task.assignedAgentId == 0 || task.assignedAgentId != _agentId) {
            revert InvalidAgentIDForTask();
        }
        if (msg.sender != task.assignedAgentOwner) {
            revert Unauthorized();
        }
        if (bytes(_solutionCID).length == 0) {
            revert InvalidAmount(); // Solution cannot be empty
        }

        task.submittedSolutionCID = _solutionCID;
        task.status = TaskStatus.Validating;

        emit TaskSolutionSubmitted(_taskId, msg.sender, _agentId);

        // Simulate Oracle Call (in a real scenario, this uses Chainlink or similar)
        _requestAIValidation(_taskId, _agentId, _solutionCID);
    }

    /// @notice Callback function for the oracle to return validation results for a task solution.
    /// @dev Only callable by the designated oracle address.
    /// @param _taskId The ID of the task.
    /// @param _isValid True if the solution is valid, false otherwise.
    /// @param _oracleFeedback Optional feedback from the oracle.
    function receiveOracleResponse(uint256 _taskId, bool _isValid, string memory _oracleFeedback) external nonReentrant onlyOracle whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];

        if (task.status != TaskStatus.Validating) {
            revert InvalidTaskStatus();
        }
        if (task.assignedAgentId == 0) {
            revert InvalidAgentIDForTask(); // Task should have an assigned agent by now
        }

        if (_isValid) {
            task.status = TaskStatus.Completed;
            uint256 reward = task.bounty;
            uint256 reputationEarned = reward / (10**_agentToken.decimals()) / 10; // Example: 10 reputation per 100 AGENT_TOKEN bounty

            _agentToken.transfer(task.assignedAgentOwner, reward); // Transfer bounty to agent owner
            _updateReputation(task.assignedAgentOwner, task.assignedAgentId, int256(reputationEarned), true); // Agent reputation
            _updateReputation(task.assignedAgentOwner, 0, int256(reputationEarned / 2), false); // User reputation
            _updateReputation(task.creator, 0, int256(reputationEarned / 4), false); // Task creator reputation (for successful task)

            agents[task.assignedAgentId].lastMetadataUpdateBlock = block.number; // Signal metadata update

            emit TaskCompleted(_taskId, task.assignedAgentOwner, task.assignedAgentId, reputationEarned);
        } else {
            // Task validation failed
            task.status = TaskStatus.Assigned; // Reset to assigned to allow resubmission or cancellation
            _updateReputation(task.assignedAgentOwner, task.assignedAgentId, -int256(task.bounty / (10**_agentToken.decimals()) / 20), true); // Agent reputation penalty
            _updateReputation(task.assignedAgentOwner, 0, -int256(task.bounty / (10**_agentToken.decimals()) / 40), false); // User reputation penalty
            // Optionally, refund bounty to creator, or keep for retry
        }
        // Oracle feedback can be stored in the task struct for off-chain viewing if needed.
    }

    /// @notice Allows the task creator to cancel a pending or assigned task.
    /// @dev Refunds the bounty if the task has not been completed or validated.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) external nonReentrant whenNotPaused taskExists(_taskId) isTaskCreator(_taskId) {
        Task storage task = tasks[_taskId];

        if (task.status == TaskStatus.Completed || task.status == TaskStatus.Validating) {
            revert TaskAlreadyCompleted(); // Cannot cancel if already completed or in validation
        }

        uint256 bountyToRefund = task.bounty;
        task.status = TaskStatus.Canceled;
        task.bounty = 0; // Clear bounty

        _agentToken.transfer(task.creator, bountyToRefund);
        emit TaskCanceled(_taskId);
        _updateReputation(msg.sender, 0, -5, false); // Small reputation penalty for canceling
    }

    // --- REPUTATION & QUERY FUNCTIONS ---

    /// @notice Returns the reputation score of a specific user wallet.
    /// @param _user The address of the user.
    /// @return The user's current reputation score.
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Returns the reputation score of a specific AI agent.
    /// @param _agentId The ID of the agent.
    /// @return The agent's current reputation score.
    function getAgentReputation(uint256 _agentId) external view returns (uint256) {
        if (agents[_agentId].name == "") {
            revert AgentNotFound(_agentId);
        }
        return agents[_agentId].reputation;
    }

    /// @notice Returns comprehensive details about a specific AI agent.
    /// @param _agentId The ID of the agent.
    /// @return agentLevel The agent's current level.
    /// @return agentReputation The agent's current reputation.
    /// @return agentName The agent's name.
    /// @return agentOwner The address of the agent's owner.
    /// @return lastMetadataUpdate The block number of the last metadata update hint.
    function getAgentDetails(uint256 _agentId)
        external
        view
        returns (
            uint256 agentLevel,
            uint256 agentReputation,
            string memory agentName,
            address agentOwner,
            uint256 lastMetadataUpdate
        )
    {
        Agent storage agent = agents[_agentId];
        if (agent.name == "") {
            revert AgentNotFound(_agentId);
        }
        return (
            agent.level,
            agent.reputation,
            agent.name,
            ownerOf(_agentId),
            agent.lastMetadataUpdateBlock
        );
    }

    /// @notice Returns a list of skill IDs possessed by a specific agent.
    /// @param _agentId The ID of the agent.
    /// @return An array of skill IDs that the agent has.
    function getAgentSkills(uint256 _agentId) external view returns (uint256[] memory) {
        if (agents[_agentId].name == "") {
            revert AgentNotFound(_agentId);
        }

        uint256 skillCount = _nextSkillId.current();
        uint256[] memory agentOwnedSkills = new uint256[](skillCount);
        uint256 counter = 0;

        for (uint256 i = 1; i <= skillCount; i++) {
            if (agentSkills[_agentId][i]) {
                agentOwnedSkills[counter] = i;
                counter++;
            }
        }

        // Resize the array to only contain actual skills
        uint256[] memory finalSkills = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            finalSkills[i] = agentOwnedSkills[i];
        }
        return finalSkills;
    }

    /// @notice Returns details about a specific defined skill.
    /// @param _skillId The ID of the skill.
    /// @return name The name of the skill.
    /// @return description A description of the skill.
    /// @return prerequisites An array of skill IDs that are prerequisites.
    function getSkillDetails(uint256 _skillId)
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256[] memory prerequisites
        )
    {
        Skill storage skill = skills[_skillId];
        if (skill.name == "") {
            revert SkillNotFound(_skillId);
        }
        return (skill.name, skill.description, skill.prerequisites);
    }

    /// @notice Returns comprehensive details about a specific task.
    /// @param _taskId The ID of the task.
    /// @return creator The address of the task creator.
    /// @return title The title of the task.
    /// @return description A description of the task.
    /// @return bounty The bounty for the task.
    /// @return assignedAgentId The ID of the assigned agent (0 if unassigned).
    /// @return assignedAgentOwner The owner of the assigned agent.
    /// @return requiredAgentLevel The minimum required agent level.
    /// @return requiredUserReputation The minimum required user reputation.
    /// @return status The current status of the task.
    /// @return submittedSolutionCID The IPFS CID of the submitted solution.
    /// @return creationBlock The block number when the task was created.
    function getTaskDetails(uint256 _taskId)
        external
        view
        taskExists(_taskId)
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 bounty,
            uint256 assignedAgentId,
            address assignedAgentOwner,
            uint256 requiredAgentLevel,
            uint256 requiredUserReputation,
            TaskStatus status,
            string memory submittedSolutionCID,
            uint256 creationBlock
        )
    {
        Task storage task = tasks[_taskId];
        return (
            task.creator,
            task.title,
            task.description,
            task.bounty,
            task.assignedAgentId,
            task.assignedAgentOwner,
            task.requiredAgentLevel,
            task.requiredUserReputation,
            task.status,
            task.submittedSolutionCID,
            task.creationBlock
        );
    }

    /// @notice Returns a list of all task IDs that are currently in a Pending status.
    /// @dev Iterates through all tasks; might be gas-intensive if many tasks exist.
    /// @return An array of pending task IDs.
    function getPendingTasks() external view returns (uint256[] memory) {
        uint256 totalTasks = _nextTaskId.current();
        uint256[] memory pendingTasksArray = new uint256[](totalTasks);
        uint256 count = 0;

        for (uint256 i = 1; i <= totalTasks; i++) {
            if (tasks[i].status == TaskStatus.Pending) {
                pendingTasksArray[count] = i;
                count++;
            }
        }

        uint256[] memory finalArray = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalArray[i] = pendingTasksArray[i];
        }
        return finalArray;
    }

    // --- INTERNAL HELPER FUNCTIONS ---

    /// @dev Internal function to update reputation for either a user or an agent.
    /// @param _entity The address of the user or owner of the agent.
    /// @param _id The agent ID (0 if updating user reputation).
    /// @param _change The change in reputation (positive for gain, negative for loss).
    /// @param _isAgent True if updating agent reputation, false for user reputation.
    function _updateReputation(address _entity, uint256 _id, int256 _change, bool _isAgent) internal {
        if (_isAgent) {
            Agent storage agent = agents[_id];
            if (_change > 0) {
                agent.reputation += uint256(_change);
            } else {
                agent.reputation = agent.reputation > uint256(-_change) ? agent.reputation - uint256(-_change) : 0;
            }
            emit AgentReputationUpdated(_id, _change, agent.reputation);
        } else {
            if (_change > 0) {
                userReputation[_entity] += uint256(_change);
            } else {
                userReputation[_entity] = userReputation[_entity] > uint256(-_change) ? userReputation[_entity] - uint256(-_change) : 0;
            }
            emit UserReputationUpdated(_entity, _change, userReputation[_entity]);
        }
    }

    /// @dev Internal function to trigger (simulate) an oracle call for AI validation.
    ///      In a real system, this would use a Chainlink Request or similar.
    /// @param _taskId The ID of the task to validate.
    /// @param _agentId The ID of the agent whose solution is being validated.
    /// @param _solutionCID The IPFS CID of the solution.
    function _requestAIValidation(uint256 _taskId, uint256 _agentId, string memory _solutionCID) internal {
        // This is a simplified simulation. In reality, you'd use a robust oracle network.
        // For example, with Chainlink, this would involve creating a Chainlink.Request and sending it.
        // IAetheriusOracle(oracleAddress).requestValidation(
        //     _taskId,
        //     _agentId,
        //     _solutionCID,
        //     address(this),
        //     this.receiveOracleResponse.selector
        // );

        // For local testing/simulation, we can directly call receiveOracleResponse
        // after a delay or based on some predefined logic off-chain.
        // For the sake of a deployable contract, we just emit an event indicating the request.
        emit TaskValidationRequested(_taskId, _agentId);
    }
}
```