This smart contract, **ReputaSphere**, introduces a novel decentralized platform for on-chain talent and task management. It allows users to register as "Agents," build a verifiable reputation, acquire and level up skills, and engage in a task-based economy. A core innovative feature is its **Dynamic Skill Badge NFTs**, which visually and metadata-wise update as an Agent's associated skill level progresses.

The contract avoids duplicating existing open-source libraries by implementing its own minimal ERC-721-like logic for the skill badges and managing its own access control, while clearly defining interfaces for standard interactions like ERC-20.

---

## ReputaSphere: Decentralized Agent Skill & Reputation Protocol

This smart contract establishes a decentralized platform for agents to build on-chain reputation, acquire and level up skills, and engage in a task-based economy. It features a dynamic skill-badge NFT system that evolves with an agent's proficiency. The protocol aims to foster a meritocratic environment for on-chain collaboration and talent discovery.

**Key Innovative Aspects:**

*   **Dynamic Skill Badges (NFTs):** ERC-721-like tokens that visually and metadata-wise update as an agent levels up their associated skill. The `tokenURI` dynamically reflects the current skill level.
*   **Reputation-Weighted Attestations:** Reputation scores influence the impact of attestations made by agents. Higher reputation attestors have more weight.
*   **Skill-Tree Progression:** Agents gain Experience Points (XP) for specific skills by successfully completing relevant tasks, which allows them to upgrade their skill levels.
*   **Integrated Task Marketplace:** A system for posting, accepting, completing, and verifying tasks with built-in rewards, reputation adjustments, and dispute resolution.
*   **Conceptual Oracle Integration:** Placeholder for future external AI/data services to enhance sentiment analysis for attestations or sophisticated dispute resolution (e.g., using Chainlink).

**Outline and Function Summary:**

**I. Core Data Structures & State**
*   `AgentProfile`: Struct to store agent metadata URI, dynamic reputation score, mapping of skills to `AgentSkill` structs, and a list of possessed skill IDs.
*   `AgentSkill`: Struct for an agent's specific skill, tracking its level, XP, and the associated skill badge NFT ID.
*   `Skill`: Struct to define a global skill type, its name, description, base XP required for level-ups, and its active status.
*   `Task`: Struct to store all task-related information, including creator, assigned agent, required skill/level, reward, deadline, various URIs (task, proof, feedback), and current status.
*   `Attestation`: *Implicitly handled within `attestReputation` function.*

**II. Agent Management (5 functions)**
1.  `registerAgent(string calldata _profileURI)`: Allows any address to register as an agent, initializing their profile with an initial reputation.
2.  `updateAgentProfile(string calldata _newProfileURI)`: Updates an agent's off-chain profile metadata URI.
3.  `getAgentReputation(address _agent)`: Retrieves an agent's current reputation score.
4.  `getAgentSkills(address _agent)`: Returns an array of skill IDs an agent possesses.
5.  `hasSkill(address _agent, uint256 _skillId, uint256 _minLevel)`: Checks if an agent possesses a specific skill at or above a minimum required level.

**III. Skill Tree Management (Admin/DAO) (3 functions)**
6.  `addSkill(string calldata _name, string calldata _description, uint256 _baseXPForLevelUp)`: Creates a new skill type available for agents to learn. Only callable by the contract owner.
7.  `updateSkillDetails(uint256 _skillId, string calldata _newName, string calldata _newDescription)`: Modifies the name or description of an existing skill. Only callable by the contract owner.
8.  `removeSkill(uint256 _skillId)`: Deactivates a skill, preventing new acquisitions (existing skills remain for agents who already possess them). Only callable by the contract owner.

**IV. Skill Acquisition & Progression (3 functions)**
9.  `learnSkill(uint256 _skillId)`: An agent attempts to learn a new, active skill. If successful, it mints the initial dynamic skill badge NFT for that skill.
10. `gainSkillXP(address _agent, uint256 _skillId, uint256 _amount)`: Internal function to award XP for a specific skill (e.g., after successful task completion).
11. `upgradeSkillLevel(uint256 _skillId)`: An agent attempts to upgrade a skill to the next level by consuming accrued XP. This triggers an update to the dynamic skill badge NFT's metadata.

**V. Task Management (6 functions)**
12. `postTask(uint256 _skillIdRequired, uint256 _skillLevelRequired, uint256 _rewardAmount, uint256 _deadline, string calldata _taskURI)`: A creator posts a task requiring specific skills and offering a reward (in `REPUTA_TOKEN`). The reward is held in escrow by the contract.
13. `acceptTask(uint256 _taskId)`: An eligible agent accepts an open task.
14. `submitTaskCompletion(uint256 _taskId, string calldata _proofURI)`: The accepted agent submits proof of task completion.
15. `verifyTaskCompletion(uint256 _taskId, bool _isSuccessful, string calldata _feedbackURI)`: Task creator verifies the submitted completion. If successful, rewards are distributed (minus platform fees), and reputation/XP are updated. If failed, rewards are returned to the creator, and reputation is penalized.
16. `cancelTask(uint256 _taskId)`: Task creator cancels an unaccepted or uncompleted task, reclaiming the reward.
17. `disputeTask(uint256 _taskId, string calldata _reasonURI)`: An agent or creator can dispute a task's outcome, escalating it to dispute resolution.

**VI. Reputation & Attestation System (3 functions)**
18. `attestReputation(address _targetAgent, bool _isPositive, string calldata _reasonURI)`: An agent attests to another's reputation, affecting their score. The impact is weighted by the attester's own reputation.
19. `getPendingDisputes(address _agent)`: Retrieves task IDs that are currently under dispute and involve the specified agent.
20. `resolveDispute(uint256 _taskId, bool _creatorWins, string calldata _resolutionURI)`: (Admin/Oracle/DAO) Resolves a disputed task, adjusting reputation for both parties and distributing rewards based on the resolution outcome.

**VII. Dynamic Skill Badges (ERC-721-like Implementation) (5 functions)**
21. `_mintSkillBadge(address _to, uint256 _skillId, uint256 _level)`: Internal function to mint a new ERC-721 skill badge when an agent first acquires a skill.
22. `_updateSkillBadgeLevel(uint256 _tokenId, uint256 _newLevel)`: Internal function to update the metadata of an existing skill badge NFT to reflect a higher skill level.
23. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a given skill badge NFT. This URI dynamically generates a path based on the badge's current skill level, pointing to external metadata that can reflect the progression.
24. `balanceOf(address _owner)`: Standard ERC-721 function: Returns the number of skill badge NFTs an address owns.
25. `ownerOf(uint256 _tokenId)`: Standard ERC-721 function: Returns the owner of a specific skill badge NFT.

**VIII. Platform & Governance (Basic) (5 functions)**
26. `setReputaToken(address _tokenAddress)`: Sets the address of the ERC-20 `REPUTA_TOKEN` used for rewards and fees. Only callable by the contract owner.
27. `setOracleAddress(address _newOracle)`: Sets the address of an authorized oracle for potential external data integration (e.g., sentiment analysis, advanced dispute resolution). Only callable by the contract owner.
28. `receiveOracleData(uint256 _requestId, bytes32 _data)`: A callback function for an authorized oracle to deliver data back to the contract. (Conceptual for external data/AI integration).
29. `withdrawPlatformFees(address _to, uint256 _amount)`: Allows the contract owner to withdraw accumulated platform fees from ReputaToken.
30. `getPlatformFeeRate()`: Returns the current platform fee percentage set for the platform.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ReputaSphere: Decentralized Agent Skill & Reputation Protocol
 * @dev This smart contract establishes a decentralized platform for agents to build on-chain reputation,
 *      acquire and level up skills, and engage in a task-based economy. It features a dynamic
 *      skill-badge NFT system that evolves with an agent's proficiency. The protocol aims to
 *      foster a meritocratic environment for on-chain collaboration and talent discovery.
 *
 *      Key innovative aspects include:
 *      - **Dynamic Skill Badges (NFTs):** ERC-721-like tokens that visually and metadata-wise update
 *        as an agent levels up their associated skill. The `tokenURI` dynamically reflects the current skill level.
 *      - **Reputation-Weighted Attestations:** Reputation scores influence the impact of
 *        attestations made by agents. Higher reputation attestors have more weight.
 *      - **Skill-Tree Progression:** Agents gain XP for skills by completing relevant tasks,
 *        which allows them to upgrade skill levels. XP required scales with level.
 *      - **Integrated Task Marketplace:** A system for posting, accepting, completing, and
 *        verifying tasks with built-in rewards, reputation adjustments, and dispute resolution.
 *      - **Conceptual Oracle Integration:** Placeholder for future external AI/data services
 *        to enhance sentiment analysis for attestations or sophisticated dispute resolution.
 *
 *      This contract implements its own minimal ERC-721-like functionality for Skill Badges
 *      to avoid direct duplication of widely used open-source ERC-721 libraries, focusing
 *      instead on the unique application logic. It interacts with an external ERC-20 token
 *      (ReputaToken) for rewards and fees.
 */

// --- INTERFACES ---

/**
 * @dev Interface for an ERC-20 token, used for ReputaToken.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// --- MAIN CONTRACT ---

contract ReputaSphere {
    address public owner;
    address public reputaTokenAddress; // Address of the ERC-20 token used for rewards/fees
    address public oracleAddress;       // Address of an authorized oracle for external data

    uint256 public nextSkillId = 1;
    uint256 public nextTaskId = 1;
    uint256 public nextBadgeTokenId = 1; // For dynamic skill badge NFTs

    uint256 public constant INITIAL_REPUTATION = 1000;
    uint256 public constant MIN_REPUTATION_FOR_ATTESTATION = 500;
    uint256 public constant REPUTATION_BONUS_TASK_SUCCESS = 50;
    uint256 public constant REPUTATION_PENALTY_TASK_FAIL = 100;
    uint256 public constant REPUTATION_ATT_POS_BASE = 10;
    uint256 public constant REPUTATION_ATT_NEG_BASE = 20;
    uint256 public constant BASE_XP_PER_REWARD_UNIT = 1; // How much XP per 1 unit of ReputaToken reward

    // Platform fees (e.g., 0.5% = 5 / 1000)
    uint256 public platformFeeNumerator = 5;
    uint256 public constant platformFeeDenominator = 1000;

    // --- ENUMS ---
    enum TaskStatus {
        Open,
        Accepted,
        Submitted,
        VerifiedSuccess,
        VerifiedFailure,
        Disputed,
        Cancelled
    }

    // --- STRUCTS ---

    struct AgentProfile {
        string profileURI; // IPFS hash or URL for agent's detailed profile
        int256 reputation;
        mapping(uint256 => AgentSkill) skills; // skillId => AgentSkill
        uint256[] possessedSkillIds; // To iterate over skills
        bool isRegistered;
    }

    struct AgentSkill {
        uint256 level;
        uint256 xp; // Experience points for this skill
        uint256 badgeTokenId; // The tokenId of the dynamic NFT representing this skill (0 if not minted)
    }

    struct Skill {
        string name;
        string description;
        uint256 baseXPForLevelUp; // Base XP needed for level 1 -> 2, scales for higher levels
        bool isActive; // Can new agents learn this skill?
    }

    struct Task {
        address creator;
        address agent; // Agent who accepted the task (address(0) if not accepted)
        uint256 skillIdRequired;
        uint256 skillLevelRequired;
        uint256 rewardAmount; // In ReputaToken
        uint256 deadline;
        string taskURI; // IPFS hash or URL for task details
        string proofURI; // IPFS hash or URL for agent's proof of completion
        string feedbackURI; // IPFS hash or URL for creator's feedback
        TaskStatus status;
        bool disputedByCreator;
        bool disputedByAgent;
    }

    // --- MAPPINGS ---
    mapping(address => AgentProfile) public agents;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Task) public tasks;

    // Dynamic Skill Badge NFT specific mappings (minimal ERC-721 implementation)
    mapping(uint256 => address) private _tokenOwners; // tokenId => owner
    mapping(address => uint256) private _balanceOf;   // owner => count of NFTs
    mapping(uint256 => uint256) private _badgeSkillId; // tokenId => skillId
    mapping(uint256 => uint256) private _badgeSkillLevel; // tokenId => skillLevel

    // For oracle callbacks
    mapping(uint256 => address) public oracleRequestCallbackSender; // requestId => original caller
    mapping(uint256 => uint256) public oracleRequestTaskId;         // requestId => relevant taskId

    // --- EVENTS ---
    event AgentRegistered(address indexed agent, string profileURI, int256 initialReputation);
    event AgentProfileUpdated(address indexed agent, string newProfileURI);
    event SkillAdded(uint256 indexed skillId, string name, string description);
    event SkillUpdated(uint256 indexed skillId, string newName, string newDescription);
    event SkillLearned(address indexed agent, uint256 indexed skillId, uint256 badgeTokenId);
    event SkillXPChanged(address indexed agent, uint256 indexed skillId, uint256 newXP);
    event SkillLevelUp(address indexed agent, uint256 indexed skillId, uint256 newLevel, uint256 badgeTokenId);
    event TaskPosted(uint256 indexed taskId, address indexed creator, uint256 skillIdRequired, uint256 rewardAmount);
    event TaskAccepted(uint256 indexed taskId, address indexed agent);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed agent, string proofURI);
    event TaskVerified(uint256 indexed taskId, address indexed creator, address indexed agent, bool successful, int256 reputationChange);
    event TaskCancelled(uint256 indexed taskId, address indexed creator);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, string reasonURI);
    event DisputeResolved(uint256 indexed taskId, bool creatorWins, int256 creatorRepChange, int256 agentRepChange);
    event ReputationAttested(address indexed attester, address indexed target, bool isPositive, int256 reputationChange);
    event SkillBadgeMinted(address indexed to, uint256 indexed tokenId, uint256 skillId, uint256 level);
    event SkillBadgeMetadataUpdated(uint256 indexed tokenId, uint256 newLevel);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event ReputaTokenAddressSet(address indexed oldAddress, address indexed newAddress);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event PlatformFeeUpdated(uint256 newNumerator);
    event OracleDataReceived(address indexed originalSender, uint256 indexed taskId, bytes32 data);

    // --- MODIFIERS ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAgent() {
        require(agents[msg.sender].isRegistered, "ReputaSphere: caller is not a registered agent");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ReputaSphere: caller is not the authorized oracle");
        _;
    }

    // --- CONSTRUCTOR ---
    constructor() {
        owner = msg.sender;
    }

    // --- AGENT MANAGEMENT (5 functions) ---

    /**
     * @dev Allows any address to register as an agent, initializing their profile.
     *      An agent starts with an initial reputation score.
     * @param _profileURI IPFS hash or URL for agent's detailed profile metadata.
     */
    function registerAgent(string calldata _profileURI) external {
        require(!agents[msg.sender].isRegistered, "ReputaSphere: Agent already registered");
        agents[msg.sender].isRegistered = true;
        agents[msg.sender].profileURI = _profileURI;
        agents[msg.sender].reputation = INITIAL_REPUTATION;
        emit AgentRegistered(msg.sender, _profileURI, INITIAL_REPUTATION);
    }

    /**
     * @dev Updates an agent's off-chain profile metadata URI.
     * @param _newProfileURI The new IPFS hash or URL for agent's profile.
     */
    function updateAgentProfile(string calldata _newProfileURI) external onlyAgent {
        agents[msg.sender].profileURI = _newProfileURI;
        emit AgentProfileUpdated(msg.sender, _newProfileURI);
    }

    /**
     * @dev Retrieves an agent's current reputation score.
     * @param _agent The address of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(address _agent) external view returns (int256) {
        require(agents[_agent].isRegistered, "ReputaSphere: Agent not registered");
        return agents[_agent].reputation;
    }

    /**
     * @dev Returns an array of skill IDs an agent possesses.
     * @param _agent The address of the agent.
     * @return An array of skill IDs.
     */
    function getAgentSkills(address _agent) external view returns (uint256[] memory) {
        require(agents[_agent].isRegistered, "ReputaSphere: Agent not registered");
        return agents[_agent].possessedSkillIds;
    }

    /**
     * @dev Checks if an agent possesses a specific skill and optionally checks for minimum level.
     * @param _agent The address of the agent.
     * @param _skillId The ID of the skill to check.
     * @param _minLevel The minimum required level for the skill.
     * @return True if the agent has the skill at or above the minimum level, false otherwise.
     */
    function hasSkill(address _agent, uint256 _skillId, uint256 _minLevel) external view returns (bool) {
        require(agents[_agent].isRegistered, "ReputaSphere: Agent not registered");
        require(skills[_skillId].isActive, "ReputaSphere: Skill does not exist or is inactive");
        return agents[_agent].skills[_skillId].level >= _minLevel;
    }

    // --- SKILL TREE MANAGEMENT (Admin/DAO) (3 functions) ---

    /**
     * @dev Creates a new skill type available for agents to learn. Only owner can add skills.
     * @param _name The name of the skill (e.g., "Solidity Development").
     * @param _description A description of the skill.
     * @param _baseXPForLevelUp Base XP required to level up from 1 to 2. XP for higher levels scales: baseXP * currentLevel.
     */
    function addSkill(string calldata _name, string calldata _description, uint256 _baseXPForLevelUp) external onlyOwner {
        require(bytes(_name).length > 0, "ReputaSphere: Skill name cannot be empty");
        uint256 skillId = nextSkillId++;
        skills[skillId] = Skill({
            name: _name,
            description: _description,
            baseXPForLevelUp: _baseXPForLevelUp,
            isActive: true
        });
        emit SkillAdded(skillId, _name, _description);
    }

    /**
     * @dev Modifies the name or description of an existing skill. Only owner can update skills.
     * @param _skillId The ID of the skill to update.
     * @param _newName The new name for the skill.
     * @param _newDescription The new description for the skill.
     */
    function updateSkillDetails(uint256 _skillId, string calldata _newName, string calldata _newDescription) external onlyOwner {
        require(skills[_skillId].isActive, "ReputaSphere: Skill does not exist or is inactive");
        require(bytes(_newName).length > 0, "ReputaSphere: Skill name cannot be empty");
        skills[_skillId].name = _newName;
        skills[_skillId].description = _newDescription;
        emit SkillUpdated(_skillId, _newName, _newDescription);
    }

    /**
     * @dev Deactivates a skill, preventing new agents from learning it. Existing skills remain active for agents who already possess them.
     *      Only owner can remove skills.
     * @param _skillId The ID of the skill to deactivate.
     */
    function removeSkill(uint256 _skillId) external onlyOwner {
        require(skills[_skillId].isActive, "ReputaSphere: Skill does not exist or is already inactive");
        skills[_skillId].isActive = false;
        // Optionally, could burn all associated skill badge NFTs, but deactivation is sufficient.
    }

    // --- SKILL ACQUISITION & PROGRESSION (3 functions) ---

    /**
     * @dev Agent attempts to learn a new skill. The agent must be registered, and the skill must be active.
     *      This also mints the initial dynamic skill badge NFT for the agent.
     * @param _skillId The ID of the skill to learn.
     */
    function learnSkill(uint256 _skillId) external onlyAgent {
        require(skills[_skillId].isActive, "ReputaSphere: Skill does not exist or is inactive");
        require(agents[msg.sender].skills[_skillId].level == 0, "ReputaSphere: Agent already knows this skill");

        agents[msg.sender].skills[_skillId].level = 1;
        agents[msg.sender].skills[_skillId].xp = 0; // Starts at 0 XP for level 1
        agents[msg.sender].possessedSkillIds.push(_skillId);

        // Mint a dynamic skill badge NFT
        uint256 badgeTokenId = _mintSkillBadge(msg.sender, _skillId, 1);
        agents[msg.sender].skills[_skillId].badgeTokenId = badgeTokenId;

        emit SkillLearned(msg.sender, _skillId, badgeTokenId);
    }

    /**
     * @dev Internal function to award XP for a specific skill. Used after successful task completion.
     * @param _agent The agent receiving XP.
     * @param _skillId The ID of the skill for which XP is awarded.
     * @param _amount The amount of XP to award.
     */
    function gainSkillXP(address _agent, uint256 _skillId, uint256 _amount) internal {
        require(agents[_agent].isRegistered, "ReputaSphere: Agent not registered");
        require(agents[_agent].skills[_skillId].level > 0, "ReputaSphere: Agent does not know this skill");

        agents[_agent].skills[_skillId].xp += _amount;
        emit SkillXPChanged(_agent, _skillId, agents[_agent].skills[_skillId].xp);
    }

    /**
     * @dev Agent attempts to upgrade a skill to the next level by consuming accrued XP.
     *      XP requirement scales: `baseXPForLevelUp * currentLevel`.
     *      This triggers an update to the dynamic skill badge NFT.
     * @param _skillId The ID of the skill to upgrade.
     */
    function upgradeSkillLevel(uint256 _skillId) external onlyAgent {
        AgentProfile storage agent = agents[msg.sender];
        require(agent.skills[_skillId].level > 0, "ReputaSphere: Agent does not know this skill");
        Skill storage skillDef = skills[_skillId];

        uint256 currentLevel = agent.skills[_skillId].level;
        uint256 xpRequired = skillDef.baseXPForLevelUp * currentLevel; // Scaled XP requirement

        require(agent.skills[_skillId].xp >= xpRequired, "ReputaSphere: Not enough XP to level up");

        agent.skills[_skillId].xp -= xpRequired;
        agent.skills[_skillId].level += 1;

        // Update the dynamic skill badge NFT
        uint256 badgeTokenId = agent.skills[_skillId].badgeTokenId;
        _updateSkillBadgeLevel(badgeTokenId, agent.skills[_skillId].level);

        emit SkillLevelUp(msg.sender, _skillId, agent.skills[_skillId].level, badgeTokenId);
    }

    // --- TASK MANAGEMENT (6 functions) ---

    /**
     * @dev Creator posts a task requiring specific skills and offering a reward in ReputaToken.
     *      The reward amount is transferred from the creator to the contract's custody.
     * @param _skillIdRequired The ID of the skill required for this task.
     * @param _skillLevelRequired The minimum level required for the skill.
     * @param _rewardAmount The reward in ReputaToken for completing the task.
     * @param _deadline Unix timestamp by which the task must be completed.
     * @param _taskURI IPFS hash or URL for detailed task description.
     */
    function postTask(
        uint256 _skillIdRequired,
        uint256 _skillLevelRequired,
        uint256 _rewardAmount,
        uint256 _deadline,
        string calldata _taskURI
    ) external onlyAgent {
        require(reputaTokenAddress != address(0), "ReputaSphere: ReputaToken address not set");
        require(skills[_skillIdRequired].isActive, "ReputaSphere: Required skill does not exist or is inactive");
        require(_rewardAmount > 0, "ReputaSphere: Reward must be positive");
        require(_deadline > block.timestamp, "ReputaSphere: Deadline must be in the future");

        // Transfer reward from creator to contract
        require(IERC20(reputaTokenAddress).transferFrom(msg.sender, address(this), _rewardAmount), "ReputaSphere: ReputaToken transfer failed");

        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            creator: msg.sender,
            agent: address(0), // No agent yet
            skillIdRequired: _skillIdRequired,
            skillLevelRequired: _skillLevelRequired,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            taskURI: _taskURI,
            proofURI: "",
            feedbackURI: "",
            status: TaskStatus.Open,
            disputedByCreator: false,
            disputedByAgent: false
        });
        emit TaskPosted(taskId, msg.sender, _skillIdRequired, _rewardAmount);
    }

    /**
     * @dev An eligible agent accepts an open task.
     * @param _taskId The ID of the task to accept.
     */
    function acceptTask(uint256 _taskId) external onlyAgent {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "ReputaSphere: Task not open for acceptance");
        require(task.deadline > block.timestamp, "ReputaSphere: Task deadline has passed");
        require(task.creator != msg.sender, "ReputaSphere: Creator cannot accept their own task");
        
        // Check if agent has the required skill and level
        require(
            agents[msg.sender].skills[task.skillIdRequired].level >= task.skillLevelRequired,
            "ReputaSphere: Agent does not meet skill level requirements"
        );

        task.agent = msg.sender;
        task.status = TaskStatus.Accepted;
        emit TaskAccepted(_taskId, msg.sender);
    }

    /**
     * @dev The accepted agent submits proof of task completion.
     * @param _taskId The ID of the task.
     * @param _proofURI IPFS hash or URL for the proof of completion.
     */
    function submitTaskCompletion(uint256 _taskId, string calldata _proofURI) external onlyAgent {
        Task storage task = tasks[_taskId];
        require(task.agent == msg.sender, "ReputaSphere: Caller is not the agent for this task");
        require(task.status == TaskStatus.Accepted, "ReputaSphere: Task not in accepted status");
        require(task.deadline > block.timestamp, "ReputaSphere: Task deadline has passed");
        require(bytes(_proofURI).length > 0, "ReputaSphere: Proof URI cannot be empty");

        task.proofURI = _proofURI;
        task.status = TaskStatus.Submitted;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _proofURI);
    }

    /**
     * @dev Task creator verifies the submitted completion, distributing rewards and affecting reputation/XP.
     *      A platform fee is deducted from the reward.
     * @param _taskId The ID of the task.
     * @param _isSuccessful True if the task was completed successfully, false otherwise.
     * @param _feedbackURI IPFS hash or URL for the creator's feedback.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _isSuccessful, string calldata _feedbackURI) external {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "ReputaSphere: Caller is not the creator of this task");
        require(task.status == TaskStatus.Submitted, "ReputaSphere: Task not in submitted status");
        require(bytes(_feedbackURI).length > 0, "ReputaSphere: Feedback URI cannot be empty");
        
        task.feedbackURI = _feedbackURI;
        int256 reputationChange = 0;
        uint256 actualReward = task.rewardAmount;

        if (_isSuccessful) {
            task.status = TaskStatus.VerifiedSuccess;
            reputationChange = REPUTATION_BONUS_TASK_SUCCESS;
            
            // Apply platform fee
            uint256 platformFee = (task.rewardAmount * platformFeeNumerator) / platformFeeDenominator;
            actualReward = task.rewardAmount - platformFee;

            // Transfer actual reward to agent
            require(IERC20(reputaTokenAddress).transfer(task.agent, actualReward), "ReputaSphere: Reward transfer failed");
            
            // Award XP to agent for the required skill
            gainSkillXP(task.agent, task.skillIdRequired, task.rewardAmount * BASE_XP_PER_REWARD_UNIT); // Example XP calculation
        } else {
            task.status = TaskStatus.VerifiedFailure;
            reputationChange = -REPUTATION_PENALTY_TASK_FAIL;
            // Return reward to creator if task failed
            require(IERC20(reputaTokenAddress).transfer(task.creator, task.rewardAmount), "ReputaSphere: Reward return failed");
        }

        agents[task.agent].reputation += reputationChange;
        emit TaskVerified(_taskId, msg.sender, task.agent, _isSuccessful, reputationChange);
    }

    /**
     * @dev Task creator cancels an unaccepted or uncompleted task, reclaiming the reward.
     *      A task cannot be cancelled if it's already submitted for completion, unless the deadline has passed.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.creator == msg.sender, "ReputaSphere: Caller is not the creator of this task");
        
        require(
            task.status == TaskStatus.Open ||
            (task.status == TaskStatus.Accepted && task.deadline <= block.timestamp), // Accepted but overdue
            "ReputaSphere: Task cannot be cancelled in current status or if agent is working on it within deadline"
        );

        task.status = TaskStatus.Cancelled;
        // Return reward to creator
        require(IERC20(reputaTokenAddress).transfer(task.creator, task.rewardAmount), "ReputaSphere: Reward return failed on cancel");
        emit TaskCancelled(_taskId, msg.sender);
    }

    /**
     * @dev Agent or creator can dispute a task's outcome, escalating to dispute resolution.
     * @param _taskId The ID of the task to dispute.
     * @param _reasonURI IPFS hash or URL for the reason of dispute.
     */
    function disputeTask(uint256 _taskId, string calldata _reasonURI) external onlyAgent {
        Task storage task = tasks[_taskId];
        require(
            task.status == TaskStatus.Submitted ||
            task.status == TaskStatus.VerifiedSuccess ||
            task.status == TaskStatus.VerifiedFailure ||
            (task.status == TaskStatus.Accepted && task.deadline <= block.timestamp), // Agent can dispute if task overdue
            "ReputaSphere: Task not in a disputable state"
        );
        require(bytes(_reasonURI).length > 0, "ReputaSphere: Reason URI cannot be empty");

        if (msg.sender == task.creator) {
            require(!task.disputedByCreator, "ReputaSphere: Creator already disputed this task");
            task.disputedByCreator = true;
        } else if (msg.sender == task.agent) {
            require(!task.disputedByAgent, "ReputaSphere: Agent already disputed this task");
            task.disputedByAgent = true;
        } else {
            revert("ReputaSphere: Only creator or agent can dispute this task");
        }

        task.status = TaskStatus.Disputed;
        // In a real system, this would ideally trigger an external arbitration process (e.g., via oracle request).
        emit TaskDisputed(_taskId, msg.sender, _reasonURI);
    }


    // --- REPUTATION & ATTESTATION SYSTEM (3 functions) ---

    /**
     * @dev An agent attests to another's reputation, affecting their score.
     *      The impact of the attestation is weighted by the attester's own reputation.
     * @param _targetAgent The address of the agent being attested.
     * @param _isPositive True for a positive attestation, false for negative.
     * @param _reasonURI IPFS hash or URL for the reason/evidence of attestation.
     */
    function attestReputation(address _targetAgent, bool _isPositive, string calldata _reasonURI) external onlyAgent {
        require(msg.sender != _targetAgent, "ReputaSphere: Cannot attest your own reputation");
        require(agents[_targetAgent].isRegistered, "ReputaSphere: Target agent not registered");
        require(agents[msg.sender].reputation >= MIN_REPUTATION_FOR_ATTESTATION, "ReputaSphere: Attester reputation too low");
        require(bytes(_reasonURI).length > 0, "ReputaSphere: Reason URI cannot be empty");

        int256 reputationChange;
        // Scale reputation change by attester's reputation (e.g., higher rep attester has more impact)
        // Simplified scaling: (attester_reputation / INITIAL_REPUTATION) * base_change
        // This provides a linear scaling based on current reputation relative to initial.
        uint256 attesterWeightFactor = uint256(agents[msg.sender].reputation) / (INITIAL_REPUTATION / 10); // Example: 1000 rep -> factor 10, 2000 rep -> factor 20

        if (_isPositive) {
            reputationChange = int256(REPUTATION_ATT_POS_BASE + attesterWeightFactor);
        } else {
            reputationChange = -int256(REPUTATION_ATT_NEG_BASE + attesterWeightFactor);
        }

        agents[_targetAgent].reputation += reputationChange;
        emit ReputationAttested(msg.sender, _targetAgent, _isPositive, reputationChange);
    }

    /**
     * @dev Retrieves tasks that are currently under dispute and involve the specified agent.
     *      (Simplified: returns a list of task IDs that are in 'Disputed' status and involve the agent).
     * @param _agent The address of the agent.
     * @return An array of task IDs that are currently disputed and involve the agent.
     */
    function getPendingDisputes(address _agent) external view returns (uint256[] memory) {
        // In a real system, this would involve more complex data structures for disputes.
        // For simplicity, we iterate through existing tasks.
        uint256[] memory disputedTaskIds = new uint256[](nextTaskId - 1); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i < nextTaskId; i++) {
            if (tasks[i].status == TaskStatus.Disputed && (tasks[i].creator == _agent || tasks[i].agent == _agent)) {
                disputedTaskIds[count++] = i;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = disputedTaskIds[i];
        }
        return result;
    }

    /**
     * @dev (Admin/Oracle/DAO) Resolves a disputed task, adjusting reputation, distributing rewards,
     *      and penalizing the losing party.
     * @param _taskId The ID of the disputed task.
     * @param _creatorWins True if the creator's side wins the dispute, false if agent's side wins.
     * @param _resolutionURI IPFS hash or URL for the dispute resolution details.
     */
    function resolveDispute(uint256 _taskId, bool _creatorWins, string calldata _resolutionURI) external onlyOwner {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Disputed, "ReputaSphere: Task not currently disputed");
        require(bytes(_resolutionURI).length > 0, "ReputaSphere: Resolution URI cannot be empty");

        int256 creatorReputationChange = 0;
        int256 agentReputationChange = 0;
        uint256 rewardToDistribute = task.rewardAmount;

        if (_creatorWins) {
            // Creator wins: task deemed failed by agent or successfully proven by creator
            task.status = TaskStatus.VerifiedFailure;
            agentReputationChange = -REPUTATION_PENALTY_TASK_FAIL * 2; // Double penalty for losing dispute
            creatorReputationChange = REPUTATION_BONUS_TASK_SUCCESS / 2; // Small bonus for winning dispute
            
            // Return reward to creator
            require(IERC20(reputaTokenAddress).transfer(task.creator, rewardToDistribute), "ReputaSphere: Reward return to creator failed");
        } else {
            // Agent wins: task deemed successfully completed by agent
            task.status = TaskStatus.VerifiedSuccess;
            creatorReputationChange = -REPUTATION_PENALTY_TASK_FAIL * 2; // Double penalty for losing dispute
            agentReputationChange = REPUTATION_BONUS_TASK_SUCCESS * 2; // Double bonus for winning dispute

            // Apply platform fee
            uint256 platformFee = (rewardToDistribute * platformFeeNumerator) / platformFeeDenominator;
            uint256 actualReward = rewardToDistribute - platformFee;
            
            // Transfer actual reward to agent
            require(IERC20(reputaTokenAddress).transfer(task.agent, actualReward), "ReputaSphere: Reward transfer to agent failed");
            
            // Award XP to agent for the required skill (higher XP for winning dispute)
            gainSkillXP(task.agent, task.skillIdRequired, task.rewardAmount * BASE_XP_PER_REWARD_UNIT * 2);
        }

        agents[task.creator].reputation += creatorReputationChange;
        agents[task.agent].reputation += agentReputationChange;
        
        emit DisputeResolved(_taskId, _creatorWins, creatorReputationChange, agentReputationChange);
    }

    // --- DYNAMIC SKILL BADGES (ERC-721-like implementation) (5 functions) ---

    // Minimal ERC-721 compliance methods for name and symbol
    function name() public pure returns (string memory) { return "ReputaSphere Skill Badge"; }
    function symbol() public pure returns (string memory) { return "RSSB"; }

    /**
     * @dev Returns the number of skill badge NFTs an address owns.
     * @param _owner The address to query the balance of.
     * @return The number of NFTs owned by `_owner`.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        return _balanceOf[_owner];
    }

    /**
     * @dev Returns the owner of a specific skill badge NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the owner.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddress = _tokenOwners[_tokenId];
        require(ownerAddress != address(0), "ERC721: owner query for nonexistent token");
        return ownerAddress;
    }

    /**
     * @dev Internal function to mint a new ERC-721 skill badge when an agent first acquires a skill.
     * @param _to The address to mint the badge to.
     * @param _skillId The ID of the skill this badge represents.
     * @param _level The initial level of the skill.
     * @return The tokenId of the newly minted badge.
     */
    function _mintSkillBadge(address _to, uint256 _skillId, uint256 _level) internal returns (uint256) {
        uint256 tokenId = nextBadgeTokenId++;
        require(_to != address(0), "ERC721: mint to the zero address");
        require(_tokenOwners[tokenId] == address(0), "ERC721: token already minted");

        _tokenOwners[tokenId] = _to;
        _balanceOf[_to]++;
        _badgeSkillId[tokenId] = _skillId;
        _badgeSkillLevel[tokenId] = _level;

        emit SkillBadgeMinted(_to, tokenId, _skillId, _level);
        return tokenId;
    }

    /**
     * @dev Internal function to update the metadata of an existing skill badge NFT to reflect a higher skill level.
     *      This effectively changes the `tokenURI` for the badge.
     * @param _tokenId The ID of the skill badge NFT.
     * @param _newLevel The new level to set for the skill.
     */
    function _updateSkillBadgeLevel(uint256 _tokenId, uint256 _newLevel) internal {
        require(_tokenOwners[_tokenId] != address(0), "ERC721: token does not exist");
        _badgeSkillLevel[_tokenId] = _newLevel;
        emit SkillBadgeMetadataUpdated(_tokenId, _newLevel);
    }

    /**
     * @dev Returns the metadata URI for a given skill badge NFT, dynamically reflecting its current level.
     *      This URI should point to an API endpoint or IPFS gateway that serves dynamic JSON based on
     *      the skillId and current level, allowing the NFT's image and attributes to change with progression.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_tokenOwners[_tokenId] != address(0), "ERC721: URI query for nonexistent token");

        uint256 skillId = _badgeSkillId[_tokenId];
        uint256 level = _badgeSkillLevel[_tokenId];
        // string memory skillName = skills[skillId].name; // Can use this in the URI if desired

        // The URI is constructed to point to a hypothetical dynamic endpoint or IPFS structure.
        // Example: ipfs://[BASE_CID]/skill-[skillId]/level-[level]/[tokenId].json
        // A real dApp would host an API or use IPFS with sub-folders to serve dynamic JSON.
        return string(abi.encodePacked(
            "ipfs://QmbadgeMetadata/", // Base URI (e.g., your Dapp's IPFS gateway)
            "skill-", uint2str(skillId), "/",
            "level-", uint2str(level), "/",
            uint2str(_tokenId), ".json" // Unique JSON for each badge instance
        ));
    }

    // --- Internal / Helper Functions ---

    /**
     * @dev Converts a uint256 to its string representation.
     *      Used for constructing dynamic token URIs.
     */
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // --- PLATFORM & GOVERNANCE (BASIC) (5 functions) ---

    /**
     * @dev Sets the address of the ERC-20 ReputaToken used for rewards and fees.
     * @param _tokenAddress The address of the ReputaToken contract.
     */
    function setReputaToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "ReputaSphere: Token address cannot be zero");
        emit ReputaTokenAddressSet(reputaTokenAddress, _tokenAddress);
        reputaTokenAddress = _tokenAddress;
    }

    /**
     * @dev Sets the address of an authorized oracle for certain operations.
     *      (e.g., sentiment analysis for attestations, dispute resolution external input).
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "ReputaSphere: Oracle address cannot be zero");
        emit OracleAddressSet(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /**
     * @dev A callback function for an authorized oracle to deliver data back to the contract.
     *      This is a conceptual integration; the actual data processing logic would be
     *      dependent on the specific oracle service and data format.
     *      Example: Oracle could provide a sentiment score for a task feedback URI.
     * @param _requestId A unique identifier for the oracle request.
     * @param _data The data delivered by the oracle (e.g., bytes32 hash, int, etc.).
     */
    function receiveOracleData(uint256 _requestId, bytes32 _data) external onlyOracle {
        // Example: Process oracle data for a specific task dispute or sentiment analysis.
        address originalSender = oracleRequestCallbackSender[_requestId];
        uint256 taskId = oracleRequestTaskId[_requestId];

        if (originalSender != address(0) && taskId != 0) {
            // Further logic would be implemented here to use _data (e.g., call resolveDispute based on oracle input)
            // For now, just log that data was received.
            emit OracleDataReceived(originalSender, taskId, _data); 
        }
        delete oracleRequestCallbackSender[_requestId];
        delete oracleRequestTaskId[_requestId];
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees from ReputaToken.
     *      In this simplified model, any ReputaToken balance in the contract *not* held for active tasks
     *      or in escrow for task rewards is considered withdrawable fees. A more robust system would
     *      track fees explicitly.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawPlatformFees(address _to, uint256 _amount) external onlyOwner {
        require(reputaTokenAddress != address(0), "ReputaSphere: ReputaToken address not set");
        require(_to != address(0), "ReputaSphere: Target address cannot be zero");
        
        // This is a simplified check. A production system would track specific accumulated fees.
        // For this example, we'll assume any balance not currently locked in tasks is withdrawable.
        // This requires the owner to be careful not to withdraw funds needed for pending task rewards.
        require(IERC20(reputaTokenAddress).balanceOf(address(this)) >= _amount, "ReputaSphere: Not enough ReputaToken balance for withdrawal");
        
        require(IERC20(reputaTokenAddress).transfer(_to, _amount), "ReputaSphere: Fee withdrawal failed");
        emit FeesWithdrawn(_to, _amount);
    }

    /**
     * @dev Returns the current platform fee rate as a percentage.
     *      E.g., if numerator=5 and denominator=1000, returns 0.5 (%).
     * @return The platform fee rate as a value (e.g., 50 for 0.5%).
     */
    function getPlatformFeeRate() external view returns (uint256) {
        return (platformFeeNumerator * 10000) / platformFeeDenominator; // Returns rate as Basis Points (e.g., 50 for 0.5%)
    }

    /**
     * @dev Updates the platform fee numerator. The new fee rate is (newNumerator / platformFeeDenominator).
     *      E.g., to set 1% fee, set newNumerator to 10 if denominator is 1000.
     * @param _newNumerator The new numerator for the platform fee.
     */
    function updatePlatformFee(uint256 _newNumerator) external onlyOwner {
        require(_newNumerator < platformFeeDenominator, "ReputaSphere: Fee numerator cannot be greater than or equal to denominator");
        platformFeeNumerator = _newNumerator;
        emit PlatformFeeUpdated(_newNumerator);
    }
}
```