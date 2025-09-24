Okay, this is an exciting challenge! I'll create a smart contract called "CognitoNexus" that facilitates a decentralized network of autonomous AI agents. The core idea is that agents have on-chain profiles, skills, and "knowledge fragments" (verified contributions) that can evolve, allowing them to participate in a task marketplace, earn reputation, and mint dynamic "Insight NFTs" representing their expertise.

This concept integrates elements of:
*   **Decentralized AI Agents:** Managing identities and capabilities of AI bots/models.
*   **Dynamic NFTs (dNFTs):** NFTs that change based on on-chain activity and reputation.
*   **Skill Trees/Attribute Systems:** Agents have evolving skills and attributes.
*   **Knowledge Graph/Fragments:** Verified contributions become part of an agent's on-chain "memory."
*   **Decentralized Task Marketplace:** Users propose tasks, agents accept, and results are verified.
*   **Reputation System:** Agent reputation impacts rewards and task eligibility.
*   **Delegated Control:** Owners can delegate operational control of their agents.

---

## CognitoNexus Smart Contract

**Outline & Function Summary:**

This contract manages a decentralized network of AI agents, enabling them to register, develop skills, perform tasks, and build on-chain reputation through dynamic NFTs and knowledge fragments.

### **I. Core Agent Management & Identity**
*   `registerAgent`: Creates a new AI agent with a unique ID and initial profile.
*   `updateAgentProfile`: Allows an agent owner to update its descriptive metadata URI.
*   `setAgentStatus`: Changes an agent's operational status (e.g., Active, Inactive).
*   `delegateAgentControl`: Grants a trusted address permission to operate an agent on behalf of the owner.
*   `revokeAgentControl`: Revokes delegated control from an address.
*   `getAgentDetails`: Retrieves comprehensive details about a registered agent.

### **II. Agent Attributes, Skills & Learning**
*   `setAgentAttributes`: Sets core attributes like intelligence, creativity, and reliability for an agent.
*   `defineSkillCategory`: Protocol owner defines a new high-level skill category (e.g., "Natural Language Processing").
*   `addSkillNode`: Protocol owner adds a specific skill under a category (e.g., "Sentiment Analysis" under NLP).
*   `trainAgentSkill`: Allows an agent owner to increase an agent's proficiency in a specific skill (simulates training/learning, potentially costs).
*   `unlockAgentTrait`: Grants a special, non-skill-based trait to an agent (e.g., "Proactive", "Detail-Oriented").
*   `registerKnowledgeFragment`: An agent registers a verified output/claim from a task as part of its on-chain knowledge base, enhancing its profile.

### **III. Decentralized Task Marketplace**
*   `proposeTask`: A user creates a task, specifying requirements, reward, and deadline, staking the reward amount.
*   `acceptTask`: An eligible agent accepts a proposed task, signaling its intention to complete it.
*   `submitTaskResult`: The agent submits the hash or URI of its task result for verification.
*   `verifyTaskResult`: A designated oracle/verifier assesses the submitted result and marks the task as successful or failed.
*   `disputeTaskResult`: Either the task proposer or the agent can dispute the verification outcome.
*   `resolveDispute`: An arbiter addresses and resolves a disputed task outcome.
*   `claimTaskPayment`: An agent claims the reward for a successfully completed and verified task.

### **IV. Dynamic NFTs & Reputation**
*   `mintAgentInsightNFT`: An agent can mint a dynamic, non-transferable "Insight NFT" representing its accumulated expertise and achievement.
*   `updateAgentInsightNFTMetadataURI`: Updates the metadata URI of an Agent Insight NFT, allowing its appearance or content to change based on new achievements/knowledge.
*   `getAgentInsightNFTId`: Retrieves the Insight NFT ID for a given agent.

### **V. Protocol Governance & Utilities**
*   `registerOracle`: Protocol owner registers addresses as trusted oracles for task verification.
*   `updateProtocolFee`: Protocol owner adjusts the fee taken from task rewards.
*   `withdrawProtocolFees`: Allows the protocol owner to withdraw accumulated fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary: (See above for full details)
// This contract manages a decentralized network of AI agents, enabling them to register, develop skills, perform tasks, and build on-chain reputation through dynamic NFTs and knowledge fragments.
//
// I. Core Agent Management & Identity
//    1. registerAgent: Creates a new AI agent.
//    2. updateAgentProfile: Updates an agent's metadata URI.
//    3. setAgentStatus: Changes an agent's operational status.
//    4. delegateAgentControl: Grants control to a delegate address.
//    5. revokeAgentControl: Revokes delegated control.
//    6. getAgentDetails: Retrieves agent information.
//
// II. Agent Attributes, Skills & Learning
//    7. setAgentAttributes: Sets agent's core attributes.
//    8. defineSkillCategory: Defines a new skill category.
//    9. addSkillNode: Adds a specific skill under a category.
//    10. trainAgentSkill: Increases an agent's skill proficiency.
//    11. unlockAgentTrait: Grants a special trait to an agent.
//    12. registerKnowledgeFragment: Agent registers verified output as knowledge.
//
// III. Decentralized Task Marketplace
//    13. proposeTask: User creates a task, staking reward.
//    14. acceptTask: Agent accepts a task.
//    15. submitTaskResult: Agent submits result for verification.
//    16. verifyTaskResult: Oracle verifies task result.
//    17. disputeTaskResult: Proposer/agent disputes verification.
//    18. resolveDispute: Arbiter resolves a dispute.
//    19. claimTaskPayment: Agent claims reward for successful task.
//
// IV. Dynamic NFTs & Reputation
//    20. mintAgentInsightNFT: Agent mints a dynamic "Insight NFT".
//    21. updateAgentInsightNFTMetadataURI: Updates Insight NFT metadata.
//    22. getAgentInsightNFTId: Retrieves Insight NFT ID.
//
// V. Protocol Governance & Utilities
//    23. registerOracle: Registers a trusted oracle.
//    24. updateProtocolFee: Adjusts the protocol fee.
//    25. withdrawProtocolFees: Protocol owner withdraws fees.

contract CognitoNexus is Ownable {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum AgentStatus { Active, Inactive, Suspended }
    enum TaskStatus { Proposed, Accepted, ResultSubmitted, VerifiedSuccessful, VerifiedFailed, Disputed, ResolvedSuccessful, ResolvedFailed, Canceled }

    // --- Structs ---

    struct Agent {
        uint256 id;
        address owner;
        address delegatedController; // Address that can operate the agent, if delegated
        string name;
        string profileURI; // IPFS hash or URL for agent's detailed profile metadata
        AgentStatus status;
        uint256 registeredTimestamp;
        uint256 reputationScore;
        // Core attributes (0-100 scale, subjective for now, but can influence task matching)
        uint8 intelligence;
        uint8 creativity;
        uint8 reliability;
        uint256 insightNFTId; // ID of the associated AgentInsightNFT, 0 if not minted
    }

    struct SkillCategory {
        uint256 id;
        string name;
        uint256[] skillNodes; // IDs of skill nodes within this category
    }

    struct SkillNode {
        uint256 id;
        uint256 categoryId;
        string name;
    }

    struct AgentSkill {
        uint256 skillNodeId;
        uint8 level; // 0-100, proficiency
        uint256 lastTrained;
    }

    struct AgentTrait {
        string name;
        uint256 unlockedTimestamp;
    }

    struct KnowledgeFragment {
        uint256 id;
        uint256 agentId;
        string fragmentHashOrURI; // Hash of a verified output, or URI to external data
        string context; // Short description of the knowledge
        uint256[] relatedSkills; // SkillNode IDs this fragment relates to
        uint256 timestamp;
    }

    struct Task {
        uint256 id;
        address proposer;
        uint256 agentId; // 0 if not yet accepted
        string description;
        uint256 rewardAmount; // In Wei
        uint256 protocolFee; // Fee collected by the protocol
        uint256[] requiredSkills; // SkillNode IDs required for the task
        uint256 deadline;
        TaskStatus status;
        string resultHashOrURI; // Submitted by agent
        bool verificationSuccessful; // Result of oracle verification
        address currentVerifier; // Who verified or is verifying
        uint256 createdTimestamp;
        uint256 acceptedTimestamp;
        uint256 resultSubmittedTimestamp;
        uint256 verifiedTimestamp;
        uint256 disputeDeadline;
        uint256 disputeInitiator; // 0: no dispute, 1: proposer, 2: agent
        address arbiter; // Address selected for dispute resolution
    }

    // --- State Variables ---

    Counters.Counter private _agentIdCounter;
    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) public ownerAgents; // owner => list of agent IDs
    mapping(uint256 => mapping(uint256 => AgentSkill)) public agentSkills; // agentId => skillNodeId => AgentSkill
    mapping(uint256 => mapping(string => AgentTrait)) public agentTraits; // agentId => traitName => AgentTrait
    mapping(uint256 => uint256[]) public agentKnowledgeFragments; // agentId => array of KnowledgeFragment IDs

    Counters.Counter private _skillCategoryIdCounter;
    mapping(uint256 => SkillCategory) public skillCategories;
    mapping(string => uint256) public skillCategoryNames; // name => id

    Counters.Counter private _skillNodeIdCounter;
    mapping(uint256 => SkillNode) public skillNodes;
    mapping(uint256 => mapping(string => uint256)) public skillNodeNamesInCategory; // categoryId => name => id

    Counters.Counter private _knowledgeFragmentIdCounter;
    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;

    Counters.Counter private _taskIdCounter;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public proposerTasks; // proposer => list of task IDs
    mapping(uint256 => uint256[]) public agentAcceptedTasks; // agentId => list of task IDs

    mapping(address => bool) public isOracle; // Address => true if trusted oracle
    mapping(address => bool) public isArbiter; // Address => true if trusted arbiter

    uint256 public protocolFeeBasisPoints; // e.g., 500 for 5%
    uint256 public totalProtocolFeesCollected;
    uint256 public disputePeriodSeconds; // Time window for disputes

    // --- Events ---

    event AgentRegistered(uint256 indexed agentId, address indexed owner, string name, string profileURI);
    event AgentProfileUpdated(uint256 indexed agentId, string newProfileURI);
    event AgentStatusChanged(uint256 indexed agentId, AgentStatus newStatus);
    event AgentControlDelegated(uint256 indexed agentId, address indexed owner, address indexed delegatee);
    event AgentControlRevoked(uint256 indexed agentId, address indexed owner, address indexed delegatee);
    event AgentAttributesSet(uint256 indexed agentId, uint8 intelligence, uint8 creativity, uint8 reliability);

    event SkillCategoryDefined(uint256 indexed categoryId, string name);
    event SkillNodeAdded(uint256 indexed skillNodeId, uint256 indexed categoryId, string name);
    event AgentSkillTrained(uint256 indexed agentId, uint256 indexed skillNodeId, uint8 newLevel);
    event AgentTraitUnlocked(uint256 indexed agentId, string traitName);
    event KnowledgeFragmentRegistered(uint256 indexed fragmentId, uint256 indexed agentId, string fragmentHashOrURI, string context);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, uint256 deadline);
    event TaskAccepted(uint256 indexed taskId, uint256 indexed agentId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, string resultHashOrURI);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool successful);
    event TaskDisputed(uint256 indexed taskId, uint256 disputeInitiator);
    event TaskDisputeResolved(uint256 indexed taskId, address indexed arbiter, bool agentWins);
    event TaskPaymentClaimed(uint256 indexed taskId, uint256 indexed agentId, uint256 amount);

    event InsightNFTMinted(uint256 indexed agentId, uint256 indexed tokenId, string metadataURI);
    event InsightNFTMetadataUpdated(uint256 indexed agentId, uint256 indexed tokenId, string newMetadataURI);

    event OracleRegistered(address indexed oracleAddress);
    event ProtocolFeeUpdated(uint256 newFeeBasisPoints);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // --- AgentInsightNFT (Internal ERC721) ---
    // A soulbound-like, dynamic NFT representing an agent's on-chain expertise and achievements.
    // It's dynamic because its metadata URI can be updated as the agent gains knowledge/skills.
    // It's not strictly soulbound as the agent itself is a transferrable entity. The NFT represents the agent's "soul".
    // Owners can transfer their agent, and the NFT goes with it (via the `agentId` reference).
    // The NFT metadata URI will reference off-chain data that's dynamically generated based on agent's on-chain state.
    contract AgentInsightNFT is ERC721 {
        CognitoNexus public cognitoNexus;

        constructor(address _cognitoNexusAddress) ERC721("AgentInsightNFT", "AINFT") {
            cognitoNexus = CognitoNexus(_cognitoNexusAddress);
        }

        // Override _authorizeUpgrade to allow CognitoNexus contract to mint/update on behalf of owner
        function _authorizeUpgrade(address newImplementation) internal override pure {}

        // Custom minting function, only callable by CognitoNexus
        function _mint(address to, uint256 tokenId, string memory tokenURI) internal {
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, tokenURI);
        }

        // Custom update token URI function, only callable by CognitoNexus
        function _updateTokenURI(uint256 tokenId, string memory newTokenURI) internal {
            require(_exists(tokenId), "AINFT: Token does not exist");
            _setTokenURI(tokenId, newTokenURI);
        }

        // Standard tokenURI override.
        function tokenURI(uint256 tokenId) public view override returns (string memory) {
            return _tokenURIs[tokenId];
        }

        // Prevent direct transfers of the NFT, it's tied to the agent.
        // Transferring an agent means the new owner takes responsibility for its associated AINFT.
        function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
            require(from == address(0) || to == address(0), "AINFT: Insight NFTs are non-transferable directly.");
            super._beforeTokenTransfer(from, to, tokenId, batchSize);
        }
    }

    AgentInsightNFT public agentInsightNFT;

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        protocolFeeBasisPoints = 500; // 5%
        disputePeriodSeconds = 2 days;
        agentInsightNFT = new AgentInsightNFT(address(this));
    }

    // --- Modifiers ---

    modifier onlyAgentOwnerOrDelegate(uint256 _agentId) {
        require(agents[_agentId].owner == _msgSender() || agents[_agentId].delegatedController == _msgSender(), "Caller is not agent owner or delegate");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[_msgSender()], "Caller is not a registered oracle");
        _;
    }

    modifier onlyArbiter() {
        require(isArbiter[_msgSender()], "Caller is not a registered arbiter");
        _;
    }

    // --- I. Core Agent Management & Identity ---

    /**
     * @notice Registers a new AI agent with a unique ID.
     * @param _name The human-readable name of the agent.
     * @param _profileURI IPFS hash or URL for the agent's detailed metadata.
     * @return The ID of the newly registered agent.
     */
    function registerAgent(string calldata _name, string calldata _profileURI)
        external
        returns (uint256)
    {
        _agentIdCounter.increment();
        uint256 newAgentId = _agentIdCounter.current();

        agents[newAgentId] = Agent({
            id: newAgentId,
            owner: _msgSender(),
            delegatedController: address(0),
            name: _name,
            profileURI: _profileURI,
            status: AgentStatus.Active,
            registeredTimestamp: block.timestamp,
            reputationScore: 0,
            intelligence: 0,
            creativity: 0,
            reliability: 0,
            insightNFTId: 0
        });

        ownerAgents[_msgSender()].push(newAgentId);

        emit AgentRegistered(newAgentId, _msgSender(), _name, _profileURI);
        return newAgentId;
    }

    /**
     * @notice Allows an agent's owner or delegate to update its profile URI.
     * @param _agentId The ID of the agent to update.
     * @param _newProfileURI The new IPFS hash or URL for the agent's detailed metadata.
     */
    function updateAgentProfile(uint256 _agentId, string calldata _newProfileURI)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        agents[_agentId].profileURI = _newProfileURI;
        emit AgentProfileUpdated(_agentId, _newProfileURI);
    }

    /**
     * @notice Allows an agent's owner or delegate to change its operational status.
     * @param _agentId The ID of the agent.
     * @param _status The new status for the agent (Active, Inactive, Suspended).
     */
    function setAgentStatus(uint256 _agentId, AgentStatus _status)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        agents[_agentId].status = _status;
        emit AgentStatusChanged(_agentId, _status);
    }

    /**
     * @notice Allows an agent's owner to delegate operational control to another address.
     * @param _agentId The ID of the agent.
     * @param _delegatee The address to delegate control to.
     */
    function delegateAgentControl(uint256 _agentId, address _delegatee)
        external
    {
        require(agents[_agentId].owner == _msgSender(), "Caller is not agent owner");
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        agents[_agentId].delegatedController = _delegatee;
        emit AgentControlDelegated(_agentId, _msgSender(), _delegatee);
    }

    /**
     * @notice Allows an agent's owner to revoke delegated control from an address.
     * @param _agentId The ID of the agent.
     */
    function revokeAgentControl(uint256 _agentId)
        external
    {
        require(agents[_agentId].owner == _msgSender(), "Caller is not agent owner");
        address delegatee = agents[_agentId].delegatedController;
        require(delegatee != address(0), "No delegatee to revoke");
        agents[_agentId].delegatedController = address(0);
        emit AgentControlRevoked(_agentId, _msgSender(), delegatee);
    }

    /**
     * @notice Retrieves the full details of an agent.
     * @param _agentId The ID of the agent.
     * @return Agent struct containing all details.
     */
    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (Agent memory)
    {
        return agents[_agentId];
    }

    // --- II. Agent Attributes, Skills & Learning ---

    /**
     * @notice Allows an agent's owner or delegate to set core attributes.
     *         These attributes are subjective but can influence task matching or future AI models.
     * @param _agentId The ID of the agent.
     * @param _intelligence An integer representing intelligence (0-100).
     * @param _creativity An integer representing creativity (0-100).
     * @param _reliability An integer representing reliability (0-100).
     */
    function setAgentAttributes(uint256 _agentId, uint8 _intelligence, uint8 _creativity, uint8 _reliability)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        require(_intelligence <= 100 && _creativity <= 100 && _reliability <= 100, "Attributes must be between 0 and 100");
        agents[_agentId].intelligence = _intelligence;
        agents[_agentId].creativity = _creativity;
        agents[_agentId].reliability = _reliability;
        emit AgentAttributesSet(_agentId, _intelligence, _creativity, _reliability);
    }

    /**
     * @notice Defines a new high-level skill category. Only callable by the owner of the contract.
     * @param _categoryName The name of the new skill category (e.g., "Natural Language Processing").
     * @return The ID of the new skill category.
     */
    function defineSkillCategory(string calldata _categoryName)
        external
        onlyOwner
        returns (uint256)
    {
        require(skillCategoryNames[_categoryName] == 0, "Skill category already exists");
        _skillCategoryIdCounter.increment();
        uint256 newCategoryId = _skillCategoryIdCounter.current();

        skillCategories[newCategoryId] = SkillCategory({
            id: newCategoryId,
            name: _categoryName,
            skillNodes: new uint256[](0)
        });
        skillCategoryNames[_categoryName] = newCategoryId;

        emit SkillCategoryDefined(newCategoryId, _categoryName);
        return newCategoryId;
    }

    /**
     * @notice Adds a specific skill node under an existing skill category. Only callable by the owner of the contract.
     * @param _categoryId The ID of the parent skill category.
     * @param _skillName The name of the new skill node (e.g., "Sentiment Analysis").
     * @return The ID of the new skill node.
     */
    function addSkillNode(uint256 _categoryId, string calldata _skillName)
        external
        onlyOwner
        returns (uint256)
    {
        require(skillCategories[_categoryId].id != 0, "Skill category does not exist");
        require(skillNodeNamesInCategory[_categoryId][_skillName] == 0, "Skill node already exists in this category");

        _skillNodeIdCounter.increment();
        uint256 newSkillNodeId = _skillNodeIdCounter.current();

        skillNodes[newSkillNodeId] = SkillNode({
            id: newSkillNodeId,
            categoryId: _categoryId,
            name: _skillName
        });
        skillCategories[_categoryId].skillNodes.push(newSkillNodeId);
        skillNodeNamesInCategory[_categoryId][_skillName] = newSkillNodeId;

        emit SkillNodeAdded(newSkillNodeId, _categoryId, _skillName);
        return newSkillNodeId;
    }

    /**
     * @notice Allows an agent's owner or delegate to increase the agent's proficiency in a skill.
     *         This can simulate training, and might have a cost or require proof off-chain.
     * @param _agentId The ID of the agent.
     * @param _skillNodeId The ID of the skill node to train.
     * @param _level The new proficiency level for the skill (0-100).
     */
    function trainAgentSkill(uint256 _agentId, uint256 _skillNodeId, uint8 _level)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        require(skillNodes[_skillNodeId].id != 0, "Skill node does not exist");
        require(_level <= 100, "Skill level must be between 0 and 100");
        require(_level > agentSkills[_agentId][_skillNodeId].level, "New skill level must be higher than current");

        agentSkills[_agentId][_skillNodeId].skillNodeId = _skillNodeId;
        agentSkills[_agentId][_skillNodeId].level = _level;
        agentSkills[_agentId][_skillNodeId].lastTrained = block.timestamp;

        emit AgentSkillTrained(_agentId, _skillNodeId, _level);
    }

    /**
     * @notice Grants a special, non-skill-based trait to an agent. Can represent unique characteristics.
     * @param _agentId The ID of the agent.
     * @param _traitName The name of the trait to unlock (e.g., "Proactive", "Detail-Oriented").
     */
    function unlockAgentTrait(uint256 _agentId, string calldata _traitName)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        require(agentTraits[_agentId][_traitName].unlockedTimestamp == 0, "Agent already has this trait");

        agentTraits[_agentId][_traitName] = AgentTrait({
            name: _traitName,
            unlockedTimestamp: block.timestamp
        });

        emit AgentTraitUnlocked(_agentId, _traitName);
    }

    /**
     * @notice An agent registers a verified output/claim from a task as part of its on-chain knowledge base.
     *         This helps build its profile and can influence future task assignments.
     * @param _agentId The ID of the agent registering the fragment.
     * @param _fragmentHashOrURI The hash of the data or a URI pointing to the data/proof.
     * @param _context A short description of the knowledge fragment.
     * @param _relatedSkills An array of skill node IDs related to this knowledge.
     */
    function registerKnowledgeFragment(uint256 _agentId, string calldata _fragmentHashOrURI, string calldata _context, uint256[] calldata _relatedSkills)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        _knowledgeFragmentIdCounter.increment();
        uint256 newFragmentId = _knowledgeFragmentIdCounter.current();

        knowledgeFragments[newFragmentId] = KnowledgeFragment({
            id: newFragmentId,
            agentId: _agentId,
            fragmentHashOrURI: _fragmentHashOrURI,
            context: _context,
            relatedSkills: _relatedSkills,
            timestamp: block.timestamp
        });

        agentKnowledgeFragments[_agentId].push(newFragmentId);
        emit KnowledgeFragmentRegistered(newFragmentId, _agentId, _fragmentHashOrURI, _context);
    }

    // --- III. Decentralized Task Marketplace ---

    /**
     * @notice Proposes a new task for agents to complete. The reward is staked.
     * @param _description A detailed description of the task.
     * @param _rewardAmount The amount of Wei to reward the agent.
     * @param _requiredSkills An array of skill node IDs required for this task.
     * @param _deadline The timestamp by which the task must be completed.
     * @return The ID of the newly proposed task.
     */
    function proposeTask(string calldata _description, uint256 _rewardAmount, uint256[] calldata _requiredSkills, uint256 _deadline)
        external
        payable
        returns (uint256)
    {
        require(_rewardAmount > 0, "Reward must be greater than zero");
        require(msg.value == _rewardAmount, "Staked amount must match reward");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_requiredSkills.length > 0, "Task must require at least one skill");

        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            require(skillNodes[_requiredSkills[i]].id != 0, "Required skill node does not exist");
        }

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            proposer: _msgSender(),
            agentId: 0, // Not yet accepted
            description: _description,
            rewardAmount: _rewardAmount,
            protocolFee: 0, // Calculated on claim
            requiredSkills: _requiredSkills,
            deadline: _deadline,
            status: TaskStatus.Proposed,
            resultHashOrURI: "",
            verificationSuccessful: false,
            currentVerifier: address(0),
            createdTimestamp: block.timestamp,
            acceptedTimestamp: 0,
            resultSubmittedTimestamp: 0,
            verifiedTimestamp: 0,
            disputeDeadline: 0,
            disputeInitiator: 0,
            arbiter: address(0)
        });

        proposerTasks[_msgSender()].push(newTaskId);
        emit TaskProposed(newTaskId, _msgSender(), _rewardAmount, _deadline);
        return newTaskId;
    }

    /**
     * @notice Allows an eligible agent (owner or delegate) to accept a proposed task.
     *         Requires the agent to possess the necessary skills.
     * @param _taskId The ID of the task to accept.
     * @param _agentId The ID of the agent accepting the task.
     */
    function acceptTask(uint256 _taskId, uint256 _agentId)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Proposed, "Task is not in Proposed state");
        require(task.deadline > block.timestamp, "Task deadline has passed");
        require(task.agentId == 0, "Task already accepted by another agent");

        // Check if agent has required skills
        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            uint256 requiredSkillId = task.requiredSkills[i];
            require(agentSkills[_agentId][requiredSkillId].level > 0, "Agent lacks required skill proficiency");
        }

        task.agentId = _agentId;
        task.status = TaskStatus.Accepted;
        task.acceptedTimestamp = block.timestamp;
        agentAcceptedTasks[_agentId].push(_taskId);

        emit TaskAccepted(_taskId, _agentId);
    }

    /**
     * @notice Allows the assigned agent (owner or delegate) to submit the result of a task.
     * @param _taskId The ID of the task.
     * @param _resultHashOrURI The hash of the result or a URI pointing to it.
     */
    function submitTaskResult(uint256 _taskId, string calldata _resultHashOrURI)
        external
        onlyAgentOwnerOrDelegate(tasks[_taskId].agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Accepted, "Task is not in Accepted state");
        require(task.deadline > block.timestamp, "Task submission deadline has passed");
        require(bytes(_resultHashOrURI).length > 0, "Result cannot be empty");

        task.resultHashOrURI = _resultHashOrURI;
        task.status = TaskStatus.ResultSubmitted;
        task.resultSubmittedTimestamp = block.timestamp;

        emit TaskResultSubmitted(_taskId, task.agentId, _resultHashOrURI);
    }

    /**
     * @notice A registered oracle verifies the submitted task result.
     * @param _taskId The ID of the task.
     * @param _isSuccessful True if the task was successfully completed, false otherwise.
     */
    function verifyTaskResult(uint256 _taskId, bool _isSuccessful)
        external
        onlyOracle
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.ResultSubmitted, "Task is not awaiting verification");
        require(task.resultSubmittedTimestamp + disputePeriodSeconds > block.timestamp, "Verification period has expired"); // Allow dispute period for verification

        task.verificationSuccessful = _isSuccessful;
        task.status = _isSuccessful ? TaskStatus.VerifiedSuccessful : TaskStatus.VerifiedFailed;
        task.verifiedTimestamp = block.timestamp;
        task.currentVerifier = _msgSender();
        task.disputeDeadline = block.timestamp + disputePeriodSeconds; // Set dispute deadline

        // Update agent reputation (simplified)
        if (_isSuccessful) {
            agents[task.agentId].reputationScore += 1;
        } else {
            agents[task.agentId].reputationScore = (agents[task.agentId].reputationScore > 0) ? agents[task.agentId].reputationScore - 1 : 0;
        }

        emit TaskVerified(_taskId, _msgSender(), _isSuccessful);
    }

    /**
     * @notice Initiates a dispute for a verified task. Can be called by proposer or agent.
     * @param _taskId The ID of the task to dispute.
     */
    function disputeTaskResult(uint256 _taskId)
        external
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.VerifiedSuccessful || task.status == TaskStatus.VerifiedFailed, "Task is not in a verifiable state");
        require(task.disputeDeadline > block.timestamp, "Dispute period has passed");
        require(task.proposer == _msgSender() || task.agentId == agents[_msgSender()].id || agents[task.agentId].owner == _msgSender() || agents[task.agentId].delegatedController == _msgSender(), "Caller is not proposer or agent owner/delegate");
        require(task.disputeInitiator == 0, "Dispute already initiated");

        task.status = TaskStatus.Disputed;
        task.disputeInitiator = (task.proposer == _msgSender()) ? 1 : 2; // 1 for proposer, 2 for agent
        // A more advanced system would allow selecting an arbiter or voting on one.
        // For simplicity, we'll assume an arbiter is assigned or picked by owner.
        task.arbiter = owner(); // Placeholder for a more complex arbiter selection
        require(isArbiter[task.arbiter], "No valid arbiter assigned");

        emit TaskDisputed(_taskId, task.disputeInitiator);
    }

    /**
     * @notice An arbiter resolves a disputed task.
     * @param _taskId The ID of the task.
     * @param _agentWins True if the arbiter rules in favor of the agent, false for the proposer/oracle.
     */
    function resolveDispute(uint256 _taskId, bool _agentWins)
        external
        onlyArbiter
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Disputed, "Task is not in Disputed state");
        require(task.arbiter == _msgSender(), "Caller is not the assigned arbiter");

        task.status = _agentWins ? TaskStatus.ResolvedSuccessful : TaskStatus.ResolvedFailed;
        task.verificationSuccessful = _agentWins; // Update final verification status

        // Update agent reputation based on dispute outcome
        if (_agentWins) {
            agents[task.agentId].reputationScore += 2; // Higher boost for winning dispute
        } else {
            agents[task.agentId].reputationScore = (agents[task.agentId].reputationScore >= 2) ? agents[task.agentId].reputationScore - 2 : 0;
        }

        emit TaskDisputeResolved(_taskId, _msgSender(), _agentWins);
    }

    /**
     * @notice Allows an agent (owner or delegate) to claim payment for a successfully verified task.
     *         Includes a protocol fee.
     * @param _taskId The ID of the task.
     */
    function claimTaskPayment(uint256 _taskId)
        external
        onlyAgentOwnerOrDelegate(tasks[_taskId].agentId)
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.agentId == agents[_msgSender()].id || agents[task.agentId].owner == _msgSender() || agents[task.agentId].delegatedController == _msgSender(), "Caller is not the agent owner or delegate for this task");
        require(task.status == TaskStatus.VerifiedSuccessful || task.status == TaskStatus.ResolvedSuccessful, "Task is not successfully completed");

        uint256 agentReward = task.rewardAmount;
        uint256 fee = (agentReward * protocolFeeBasisPoints) / 10000;
        uint256 netAgentReward = agentReward - fee;

        task.protocolFee = fee;
        totalProtocolFeesCollected += fee;

        // Mark task as paid
        task.status = TaskStatus.Canceled; // Using Canceled to signify closed/paid, could add a 'Paid' status

        // Transfer funds to agent
        payable(agents[task.agentId].owner).transfer(netAgentReward);

        emit TaskPaymentClaimed(_taskId, task.agentId, netAgentReward);
    }

    // --- IV. Dynamic NFTs & Reputation ---

    /**
     * @notice Allows an agent's owner or delegate to mint a dynamic "Insight NFT" for the agent.
     *         This NFT represents the agent's accumulated expertise and achievements.
     *         It is non-transferable directly, but tied to the agent's identity.
     * @param _agentId The ID of the agent.
     * @param _metadataURI The initial metadata URI for the Insight NFT. This URI can be updated.
     */
    function mintAgentInsightNFT(uint256 _agentId, string calldata _metadataURI)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        Agent storage agent = agents[_agentId];
        require(agent.insightNFTId == 0, "Agent already has an Insight NFT");

        uint256 newInsightNFTId = agentInsightNFT.totalSupply() + 1; // Simple ID generation for the NFT

        agentInsightNFT._mint(agent.owner, newInsightNFTId, _metadataURI);
        agent.insightNFTId = newInsightNFTId;

        emit InsightNFTMinted(_agentId, newInsightNFTId, _metadataURI);
    }

    /**
     * @notice Allows an agent's owner or delegate to update the metadata URI of its Insight NFT.
     *         This allows the NFT's appearance or content to change dynamically based on agent's progress.
     * @param _agentId The ID of the agent.
     * @param _newMetadataURI The new metadata URI for the Insight NFT.
     */
    function updateAgentInsightNFTMetadataURI(uint256 _agentId, string calldata _newMetadataURI)
        external
        onlyAgentOwnerOrDelegate(_agentId)
    {
        Agent storage agent = agents[_agentId];
        require(agent.insightNFTId != 0, "Agent does not have an Insight NFT minted yet");

        agentInsightNFT._updateTokenURI(agent.insightNFTId, _newMetadataURI);

        emit InsightNFTMetadataUpdated(_agentId, agent.insightNFTId, _newMetadataURI);
    }

    /**
     * @notice Retrieves the Insight NFT ID associated with an agent.
     * @param _agentId The ID of the agent.
     * @return The Insight NFT ID, or 0 if none is minted.
     */
    function getAgentInsightNFTId(uint256 _agentId)
        public
        view
        returns (uint256)
    {
        return agents[_agentId].insightNFTId;
    }

    // --- V. Protocol Governance & Utilities ---

    /**
     * @notice Registers an address as a trusted oracle for task verification. Only callable by the owner of the contract.
     * @param _oracleAddress The address to register as an oracle.
     */
    function registerOracle(address _oracleAddress)
        external
        onlyOwner
    {
        isOracle[_oracleAddress] = true;
        emit OracleRegistered(_oracleAddress);
    }

    /**
     * @notice Registers an address as a trusted arbiter for dispute resolution. Only callable by the owner of the contract.
     * @param _arbiterAddress The address to register as an arbiter.
     */
    function registerArbiter(address _arbiterAddress)
        external
        onlyOwner
    {
        isArbiter[_arbiterAddress] = true;
    }

    /**
     * @notice Updates the protocol fee percentage. Only callable by the owner of the contract.
     * @param _newFeeBasisPoints The new fee in basis points (e.g., 500 for 5%). Max 10000 (100%).
     */
    function updateProtocolFee(uint256 _newFeeBasisPoints)
        external
        onlyOwner
    {
        require(_newFeeBasisPoints <= 10000, "Fee basis points cannot exceed 10000 (100%)");
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeUpdated(_newFeeBasisPoints);
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated protocol fees.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(address _to)
        external
        onlyOwner
    {
        require(totalProtocolFeesCollected > 0, "No fees to withdraw");
        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        payable(_to).transfer(amount);
        emit ProtocolFeesWithdrawn(_to, amount);
    }

    // --- Helper Functions (View) ---

    function getAgentSkillLevel(uint256 _agentId, uint256 _skillNodeId)
        public
        view
        returns (uint8)
    {
        return agentSkills[_agentId][_skillNodeId].level;
    }

    function getAgentKnowledgeFragmentIds(uint256 _agentId)
        public
        view
        returns (uint256[] memory)
    {
        return agentKnowledgeFragments[_agentId];
    }

    function getSkillCategoryNodeIds(uint256 _categoryId)
        public
        view
        returns (uint256[] memory)
    {
        return skillCategories[_categoryId].skillNodes;
    }

    function getOwnedAgentIds(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return ownerAgents[_owner];
    }
}
```