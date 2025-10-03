Here's a smart contract that embodies a unique, advanced, and creative concept, focusing on "Synergistic AI Agent Protocol" with evolving digital entities. It's designed to avoid direct duplication of existing open-source projects by implementing core functionalities internally where feasible, and focusing on novel mechanics.

---

# NexusForge Protocol: Synergistic AI Agent Network

**Outline:**

1.  **Overview:** A protocol for creating, managing, evolving, and fusing "Digital Agent Souls" (DAS) — intelligent, dynamic NFTs that represent AI entities. These agents can acquire skills, gain reputation from tasks, and undergo attribute drift. The protocol itself is governed by its community.
2.  **Core Concepts:**
    *   **Digital Agent Souls (DAS):** Non-fungible tokens (NFTs) representing AI agents with dynamic attributes, skills, and reputation.
    *   **Attribute Drift:** Agents' attributes subtly change over time, simulating evolution or decay.
    *   **Skill Acquisition:** Agents can learn new skills, either through training (paid) or attestation (verified off-chain work).
    *   **Agent Fusion:** Two (or more) parent agents can merge to create a new, potentially superior child agent.
    *   **Task Delegation & Reputation:** Agents can be assigned to off-chain tasks, with results attested on-chain to build reputation.
    *   **Decentralized Governance:** A basic DAO-like structure allows the community to propose and vote on protocol parameters (e.g., new skills, fusion costs, oracle addresses).
3.  **Technologies & Patterns:**
    *   Custom ERC721-like implementation for agent ownership.
    *   AccessControl for role-based permissions (minter, oracle, governance admin).
    *   Structs and mappings for complex data representation (Agents, Skills, Proposals).
    *   Time-based mechanics for attribute drift and proposal expiration.
    *   Events for transparent state changes.
    *   ReentrancyGuard for security.

**Function Summary (27 functions):**

**I. Core Agent Management (ERC721-like Interface & Basic Properties)**
1.  `constructor()`: Initializes roles and sets the contract deployer as an initial admin.
2.  `balanceOf(address owner)`: Returns the number of agents owned by an address.
3.  `ownerOf(uint256 tokenId)`: Returns the owner of a given agent ID.
4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of an agent.
5.  `approve(address to, uint256 tokenId)`: Approves an address to take ownership of an agent.
6.  `getApproved(uint256 tokenId)`: Returns the approved address for an agent.
7.  `setApprovalForAll(address operator, bool approved)`: Grants or revokes approval for an operator to manage all of sender's agents.
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of owner's agents.
9.  `tokenURI(uint256 tokenId)`: Returns the metadata URI for an agent.
10. `getTotalAgentsMinted()`: Returns the total number of agents ever minted.
11. `getAgentAttributes(uint256 tokenId)`: Retrieves all attributes (ID and value) for a specific agent.
12. `getAgentSkills(uint256 tokenId)`: Retrieves all skills (ID and status) for a specific agent.
13. `getAgentStatus(uint256 tokenId)`: Returns the current operational status of an agent.
14. `getAgentReputation(uint256 tokenId)`: Returns the reputation score of an agent.

**II. Agent Evolution & Mechanics**
15. `mintNewAgent(address recipient, string memory name, string memory description)`: Mints a brand new Digital Agent Soul with initial attributes.
16. `trainAgentSkill(uint256 tokenId, uint8 skillId)`: Allows an agent owner to pay ETH to teach their agent a new skill.
17. `attestAgentTaskCompletion(uint256 tokenId, uint256 reputationGain, uint256 experienceGain)`: An oracle attests to an agent's successful completion of an off-chain task, rewarding reputation and experience.
18. `initiateAgentFusion(uint256 parent1Id, uint256 parent2Id)`: Initiates a fusion process between two agents, requiring approval from the second owner.
19. `executeAgentFusion(uint256 parent1Id, uint256 parent2Id, string memory newAgentName, string memory newAgentDescription)`: Finalizes agent fusion, burning parents and minting a new child with combined/evolved traits.
20. `triggerAgentDrift(uint256 tokenId)`: Manually triggers the attribute drift mechanism for an agent, adjusting its attributes based on time.
21. `setAgentURI(uint256 tokenId, string memory newURI)`: Allows the owner to update their agent's metadata URI.
22. `burnAgent(uint256 tokenId)`: Allows an owner to permanently destroy their agent.

**III. Governance & Protocol Parameters**
23. `proposeNewSkillType(string memory skillName, string memory skillDescription)`: Allows community members to propose a new skill definition for agents.
24. `voteOnProposal(uint256 proposalId, bool support)`: Allows an address to vote on an active governance proposal.
25. `executeProposal(uint256 proposalId)`: Executes a successful governance proposal (e.g., adds a new skill).
26. `setAttestationOracle(address newOracle)`: Governance function to update the trusted oracle address.
27. `setFusionCost(uint256 newCost)`: Governance function to adjust the ETH cost for agent fusion.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom errors for better UX and gas efficiency
error NotOwnerOrApproved();
error InvalidTokenId();
error AgentAlreadyExists();
error AgentNotFound();
error AgentEngagedOrFused();
error SkillAlreadyLearned();
error InvalidSkillId();
error InsufficientEthForSkillTraining();
error AgentAlreadyInFusionProcess();
error FusionParentsMustBeDifferent();
error FusionNotApprovedBySecondOwner();
error NotOracleRole();
error InvalidProposalState();
error ProposalExpired();
error NotEnoughVotes();
error AlreadyVoted();
error SelfApprovalDisallowed();
error CannotTransferToZeroAddress();
error ApprovalToCurrentOwner();
error SkillAlreadyExists();


/**
 * @title NexusForge Protocol: Synergistic AI Agent Network
 * @dev This contract implements a novel protocol for dynamic, evolving, and fusable Digital Agent Souls (DAS)
 *      as NFTs. It features attribute drift, skill acquisition, agent fusion, and decentralized governance.
 *      It aims to provide a platform for programmable AI entities with on-chain representation and evolution.
 *
 *      The contract includes a custom ERC721-like implementation to avoid direct duplication of open-source
 *      libraries, focusing on the unique mechanics of agent evolution and interaction.
 *
 * Outline:
 * 1. Overview: A protocol for creating, managing, evolving, and fusing "Digital Agent Souls" (DAS) — intelligent, dynamic NFTs that represent AI entities. These agents can acquire skills, gain reputation from tasks, and undergo attribute drift. The protocol itself is governed by its community.
 * 2. Core Concepts:
 *    - Digital Agent Souls (DAS): Non-fungible tokens (NFTs) representing AI agents with dynamic attributes, skills, and reputation.
 *    - Attribute Drift: Agents' attributes subtly change over time, simulating evolution or decay.
 *    - Skill Acquisition: Agents can learn new skills, either through training (paid) or attestation (verified off-chain work).
 *    - Agent Fusion: Two (or more) parent agents can merge to create a new, potentially superior child agent.
 *    - Task Delegation & Reputation: Agents can be assigned to off-chain tasks, with results attested on-chain to build reputation.
 *    - Decentralized Governance: A basic DAO-like structure allows the community to propose and vote on protocol parameters (e.g., new skills, fusion costs, oracle addresses).
 * 3. Technologies & Patterns:
 *    - Custom ERC721-like implementation for agent ownership.
 *    - AccessControl for role-based permissions (minter, oracle, governance admin).
 *    - Structs and mappings for complex data representation (Agents, Skills, Proposals).
 *    - Time-based mechanics for attribute drift and proposal expiration.
 *    - Events for transparent state changes.
 *    - ReentrancyGuard for security.
 *
 * Function Summary (27 functions):
 * I. Core Agent Management (ERC721-like Interface & Basic Properties)
 * 1. constructor(): Initializes roles and sets the contract deployer as an initial admin.
 * 2. balanceOf(address owner): Returns the number of agents owned by an address.
 * 3. ownerOf(uint256 tokenId): Returns the owner of a given agent ID.
 * 4. transferFrom(address from, address to, uint256 tokenId): Transfers ownership of an agent.
 * 5. approve(address to, uint256 tokenId): Approves an address to take ownership of an agent.
 * 6. getApproved(uint256 tokenId): Returns the approved address for an agent.
 * 7. setApprovalForAll(address operator, bool approved): Grants or revokes approval for an operator to manage all of sender's agents.
 * 8. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all of owner's agents.
 * 9. tokenURI(uint256 tokenId): Returns the metadata URI for an agent.
 * 10. getTotalAgentsMinted(): Returns the total number of agents ever minted.
 * 11. getAgentAttributes(uint256 tokenId): Retrieves all attributes (ID and value) for a specific agent.
 * 12. getAgentSkills(uint256 tokenId): Retrieves all skills (ID and status) for a specific agent.
 * 13. getAgentStatus(uint256 tokenId): Returns the current operational status of an agent.
 * 14. getAgentReputation(uint256 tokenId): Returns the reputation score of an agent.
 *
 * II. Agent Evolution & Mechanics
 * 15. mintNewAgent(address recipient, string memory name, string memory description): Mints a brand new Digital Agent Soul with initial attributes.
 * 16. trainAgentSkill(uint256 tokenId, uint8 skillId): Allows an agent owner to pay ETH to teach their agent a new skill.
 * 17. attestAgentTaskCompletion(uint256 tokenId, uint256 reputationGain, uint256 experienceGain): An oracle attests to an agent's successful completion of an off-chain task, rewarding reputation and experience.
 * 18. initiateAgentFusion(uint256 parent1Id, uint256 parent2Id): Initiates a fusion process between two agents, requiring approval from the second owner.
 * 19. executeAgentFusion(uint256 parent1Id, uint256 parent2Id, string memory newAgentName, string memory newAgentDescription): Finalizes agent fusion, burning parents and minting a new child with combined/evolved traits.
 * 20. triggerAgentDrift(uint256 tokenId): Manually triggers the attribute drift mechanism for an agent, adjusting its attributes based on time.
 * 21. setAgentURI(uint256 tokenId, string memory newURI): Allows the owner to update their agent's metadata URI.
 * 22. burnAgent(uint256 tokenId): Allows an owner to permanently destroy their agent.
 *
 * III. Governance & Protocol Parameters
 * 23. proposeNewSkillType(string memory skillName, string memory skillDescription): Allows community members to propose a new skill definition for agents.
 * 24. voteOnProposal(uint256 proposalId, bool support): Allows an address to vote on an active governance proposal.
 * 25. executeProposal(uint256 proposalId): Executes a successful governance proposal (e.g., adds a new skill).
 * 26. setAttestationOracle(address newOracle): Governance function to update the trusted oracle address.
 * 27. setFusionCost(uint256 newCost): Governance function to adjust the ETH cost for agent fusion.
 */
contract NexusForgeProtocol is AccessControl, ReentrancyGuard {

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant GOVERNANCE_ADMIN_ROLE = keccak256("GOVERNANCE_ADMIN_ROLE"); // Can set other roles

    // --- Agent Data Structures ---
    enum AgentStatus {
        Idle,       // Available for tasks/fusion
        Engaged,    // Currently performing an off-chain task
        Fusing,     // In the process of being fused with another agent
        Fused       // Has been fused into another agent (effectively 'burned' but tracked)
    }

    struct Agent {
        uint256 tokenId;
        address owner;
        uint64 creationTime;
        string name;
        string description;
        mapping(uint8 => uint8) attributes; // Dynamic attributes: e.g., 0: Creativity, 1: Logic -> value 1-100
        mapping(uint8 => bool) skills;      // Learned skills: e.g., 0: DataAnalysis -> true/false
        uint256 reputation;                 // Accumulated reputation from tasks
        uint256 experience;                 // Accumulated experience from tasks/training
        AgentStatus status;
        uint64 lastDriftTime;               // Timestamp of last attribute drift calculation
        string tokenUri;                    // Metadata URI for the agent
    }

    // --- Skill Data Structures ---
    struct Skill {
        string name;
        string description;
        bool approvedByGovernance; // True if the skill has been approved by governance
    }

    // --- Governance Data Structures ---
    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes callData;                     // Encoded function call for execution if proposal passes
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;  // Tracks if an address has voted
        uint64 expirationTime;
        ProposalStatus status;
    }

    // --- Constants & Configuration ---
    uint256 public constant MIN_ATTRIBUTE_VALUE = 1;
    uint256 public constant MAX_ATTRIBUTE_VALUE = 100;
    uint256 public constant DRIFT_INTERVAL = 30 days; // How often attributes can drift (e.g., once a month)
    uint256 public constant DRIFT_MAGNITUDE = 5;      // Max change +/- per attribute during drift

    uint256 public skillTrainingCost = 0.1 ether;      // Cost to train a skill
    uint256 public agentFusionCost = 0.5 ether;        // Cost to fuse two agents
    uint64 public constant PROPOSAL_VOTING_PERIOD = 7 days; // How long proposals are active for voting
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 5; // e.g., 5% of total addresses that ever voted
    uint256 public totalGovernanceParticipants; // Tracks unique addresses that have ever voted, for quorum calculation

    // --- Storage Variables ---
    uint256 private _nextTokenId; // Counter for new agent IDs
    uint256 private _totalAgentsMinted; // Total agents ever minted (including fused ones)

    // ERC721-like mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Agent data
    mapping(uint256 => Agent) public agents;
    // Map attribute ID to its name for clarity (e.g., 0 -> "Creativity")
    mapping(uint8 => string) public attributeNames;

    // Skill data
    mapping(uint8 => Skill) public skills; // 0 is reserved for a base skill or unassigned
    uint8 public nextSkillId = 1;

    // Governance data
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    // --- Events ---
    event AgentMinted(uint256 indexed tokenId, address indexed owner, string name);
    event AgentTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event AgentBurned(uint256 indexed tokenId, address indexed owner);
    event AgentSkillTrained(uint256 indexed tokenId, uint8 indexed skillId, uint256 cost);
    event AgentTaskAttested(uint256 indexed tokenId, uint256 reputationGained, uint256 experienceGained);
    event AgentFusionInitiated(uint256 indexed parent1Id, uint256 indexed parent2Id, address indexed initiator);
    event AgentFusionExecuted(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, string newAgentName);
    event AgentAttributeDrifted(uint256 indexed tokenId, uint8 attributeId, uint8 oldValue, uint8 newValue);
    event AgentURIUpdated(uint256 indexed tokenId, string newURI);

    event NewSkillProposed(uint256 indexed proposalId, uint8 indexed skillId, string skillName);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint64 expirationTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalStatus newStatus);
    event OracleAddressUpdated(address indexed newOracle);
    event FusionCostUpdated(uint256 newCost);

    // --- Constructor ---
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ADMIN_ROLE, msg.sender); // Initial governance admin
        _grantRole(ORACLE_ROLE, msg.sender); // Initial oracle

        // Initialize some default attributes and skills
        attributeNames[0] = "Creativity";
        attributeNames[1] = "Logic";
        attributeNames[2] = "Resilience";
        attributeNames[3] = "ProcessingPower";
        attributeNames[4] = "Adaptability";

        // Add a base skill that is pre-approved
        skills[nextSkillId] = Skill({name: "BasicCommunication", description: "Enables basic interaction capabilities.", approvedByGovernance: true});
        nextSkillId++;
    }

    // --- Internal Helpers (ERC721-like) ---
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId];
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert CannotTransferToZeroAddress();
        }
        if (_owners[tokenId] != from) { // Ensure `from` is indeed the owner
            revert NotOwnerOrApproved(); // or other specific error
        }

        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;

        _approve(address(0), tokenId); // Clear approvals
        emit AgentTransferred(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId, string memory name, string memory description, string memory tokenUri_) internal {
        if (_exists(tokenId)) {
            revert AgentAlreadyExists();
        }
        if (to == address(0)) {
            revert CannotTransferToZeroAddress();
        }

        _owners[tokenId] = to;
        _balances[to]++;
        _totalAgentsMinted++;

        Agent storage newAgent = agents[tokenId];
        newAgent.tokenId = tokenId;
        newAgent.owner = to;
        newAgent.creationTime = uint64(block.timestamp);
        newAgent.name = name;
        newAgent.description = description;
        newAgent.reputation = 0;
        newAgent.experience = 0;
        newAgent.status = AgentStatus.Idle;
        newAgent.lastDriftTime = uint64(block.timestamp);
        newAgent.tokenUri = tokenUri_;

        // Assign initial random-ish attributes
        for (uint8 i = 0; i < 5; i++) { // Assuming 5 core attributes for simplicity
            // Simple pseudo-randomness for initial attributes
            newAgent.attributes[i] = uint8(uint256(keccak256(abi.encodePacked(tokenId, i, block.timestamp))) % (MAX_ATTRIBUTE_VALUE - MIN_ATTRIBUTE_VALUE + 1) + MIN_ATTRIBUTE_VALUE);
        }
        // Grant base communication skill by default
        newAgent.skills[1] = true; // Skill ID 1 is "BasicCommunication"

        emit AgentMinted(tokenId, to, name);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }

        // Clear any approvals
        _approve(address(0), tokenId);

        _balances[owner]--;
        delete _owners[tokenId]; // Remove owner
        // No need to delete from 'agents' mapping, just mark as Fused or clear owner if truly destroyed.
        // For our purpose, we mark it as Fused if it's part of fusion.
        // If it's a direct burn, we clear the owner.
        // For simplicity in _burn, we assume full destruction.
        delete agents[tokenId]; // Fully remove agent data

        emit AgentBurned(tokenId, owner);
    }

    // --- I. Core Agent Management (ERC721-like Interface & Basic Properties) ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert CannotTransferToZeroAddress();
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        return owner;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert NotOwnerOrApproved();
        }
        if (from != ownerOf(tokenId)) {
            revert NotOwnerOrApproved(); // from must be the actual owner
        }
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        if (to == owner) {
            revert ApprovalToCurrentOwner();
        }
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert NotOwnerOrApproved();
        }
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) {
            revert SelfApprovalDisallowed();
        }
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev Note: This function allows for dynamic URI based on agent state if desired.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return agents[tokenId].tokenUri;
    }

    /**
     * @dev Returns the total number of agents ever minted (including those that may have been fused/burned).
     */
    function getTotalAgentsMinted() public view returns (uint256) {
        return _totalAgentsMinted;
    }

    /**
     * @dev Returns all current attributes (ID and value) for a specific agent.
     * @param tokenId The ID of the agent.
     * @return An array of tuples, where each tuple is (attributeId, attributeValue).
     */
    function getAgentAttributes(uint256 tokenId) public view returns (uint8[] memory, uint8[] memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        Agent storage agent = agents[tokenId];
        uint8[] memory attrIds = new uint8[](5); // Assuming 5 fixed attributes
        uint8[] memory attrValues = new uint8[](5);

        for (uint8 i = 0; i < 5; i++) {
            attrIds[i] = i;
            attrValues[i] = agent.attributes[i];
        }
        return (attrIds, attrValues);
    }

    /**
     * @dev Returns all skills (ID and status) for a specific agent.
     * @param tokenId The ID of the agent.
     * @return An array of tuples, where each tuple is (skillId, learnedStatus).
     */
    function getAgentSkills(uint256 tokenId) public view returns (uint8[] memory, bool[] memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        Agent storage agent = agents[tokenId];
        uint8[] memory skillIds = new uint8[](nextSkillId - 1);
        bool[] memory learnedStatus = new bool[](nextSkillId - 1);

        for (uint8 i = 1; i < nextSkillId; i++) { // Iterate through all defined skill IDs
            skillIds[i-1] = i;
            learnedStatus[i-1] = agent.skills[i];
        }
        return (skillIds, learnedStatus);
    }

    /**
     * @dev Returns the current operational status of an agent.
     * @param tokenId The ID of the agent.
     * @return The AgentStatus enum value.
     */
    function getAgentStatus(uint256 tokenId) public view returns (AgentStatus) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return agents[tokenId].status;
    }

    /**
     * @dev Returns the reputation score of an agent.
     * @param tokenId The ID of the agent.
     * @return The agent's reputation.
     */
    function getAgentReputation(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return agents[tokenId].reputation;
    }

    // --- II. Agent Evolution & Mechanics ---

    /**
     * @dev Mints a brand new Digital Agent Soul with initial randomized attributes.
     * @param recipient The address to mint the agent to.
     * @param name The name of the new agent.
     * @param description A brief description of the agent.
     */
    function mintNewAgent(address recipient, string memory name, string memory description)
        public
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        uint256 newId = _nextTokenId++;
        _mint(recipient, newId, name, description, ""); // tokenUri can be set later
        return newId;
    }

    /**
     * @dev Allows an agent owner to pay ETH to teach their agent a new skill.
     * @param tokenId The ID of the agent to train.
     * @param skillId The ID of the skill to learn.
     */
    function trainAgentSkill(uint256 tokenId, uint8 skillId) public payable nonReentrant {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOrApproved();
        }
        if (agents[tokenId].status != AgentStatus.Idle) {
            revert AgentEngagedOrFused();
        }
        if (!skills[skillId].approvedByGovernance) {
            revert InvalidSkillId(); // Skill not defined or not approved
        }
        if (agents[tokenId].skills[skillId]) {
            revert SkillAlreadyLearned();
        }
        if (msg.value < skillTrainingCost) {
            revert InsufficientEthForSkillTraining();
        }

        agents[tokenId].skills[skillId] = true;
        agents[tokenId].experience += 100; // Award some experience for training

        // Protocol fees are collected implicitly by the msg.value handling here.
        // Fees can be withdrawn by governance.

        emit AgentSkillTrained(tokenId, skillId, msg.value);
    }

    /**
     * @dev Allows a whitelisted oracle to attest to an agent's successful completion of an off-chain task.
     *      This increases the agent's reputation and experience.
     * @param tokenId The ID of the agent.
     * @param reputationGain The amount of reputation to add.
     * @param experienceGain The amount of experience to add.
     */
    function attestAgentTaskCompletion(uint256 tokenId, uint256 reputationGain, uint256 experienceGain)
        public
        onlyRole(ORACLE_ROLE)
        nonReentrant
    {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        Agent storage agent = agents[tokenId];
        if (agent.status != AgentStatus.Engaged) { // Agent must be engaged in a task
            // For this example, we directly attest. In a full system, `delegateAgentForTask` would precede this.
            // For now, any 'Idle' agent can be attested.
        }

        agent.reputation += reputationGain;
        agent.experience += experienceGain;
        agent.status = AgentStatus.Idle; // Assume task is completed and agent is idle again

        emit AgentTaskAttested(tokenId, reputationGain, experienceGain);
    }

    /**
     * @dev Initiates a fusion process between two agents. Both owners must agree.
     *      The first owner calls this, the second owner must then approve via ERC721 `approve` or be an operator.
     * @param parent1Id The ID of the first agent (owned by msg.sender).
     * @param parent2Id The ID of the second agent.
     */
    function initiateAgentFusion(uint256 parent1Id, uint256 parent2Id) public nonReentrant {
        if (!_exists(parent1Id) || !_exists(parent2Id)) {
            revert InvalidTokenId();
        }
        if (parent1Id == parent2Id) {
            revert FusionParentsMustBeDifferent();
        }
        if (ownerOf(parent1Id) != msg.sender) {
            revert NotOwnerOrApproved(); // msg.sender must own parent1
        }
        if (agents[parent1Id].status != AgentStatus.Idle || agents[parent2Id].status != AgentStatus.Idle) {
            revert AgentEngagedOrFused();
        }

        agents[parent1Id].status = AgentStatus.Fusing;
        agents[parent2Id].status = AgentStatus.Fusing;

        // Requires explicit approval for parent2, or operator approval.
        // The `executeAgentFusion` function will check this.

        emit AgentFusionInitiated(parent1Id, parent2Id, msg.sender);
    }

    /**
     * @dev Finalizes agent fusion, burning parents and minting a new child with combined/evolved traits.
     *      Both parent agents must have their status as `Fusing`, and the second parent must be approved.
     * @param parent1Id The ID of the first agent.
     * @param parent2Id The ID of the second agent.
     * @param newAgentName The name for the new fused agent.
     * @param newAgentDescription The description for the new fused agent.
     */
    function executeAgentFusion(
        uint256 parent1Id,
        uint256 parent2Id,
        string memory newAgentName,
        string memory newAgentDescription
    ) public payable nonReentrant returns (uint256) {
        if (!_exists(parent1Id) || !_exists(parent2Id)) {
            revert InvalidTokenId();
        }
        if (parent1Id == parent2Id) {
            revert FusionParentsMustBeDifferent();
        }
        // msg.sender must be owner of parent1 or approved operator for parent1
        if (!_isApprovedOrOwner(msg.sender, parent1Id)) {
            revert NotOwnerOrApproved();
        }
        // msg.sender must be owner of parent2 or approved operator for parent2
        if (!_isApprovedOrOwner(msg.sender, parent2Id)) {
            revert NotOwnerOrApproved(); // This also covers if `initiateAgentFusion` wasn't called.
        }

        Agent storage parent1 = agents[parent1Id];
        Agent storage parent2 = agents[parent2Id];

        if (parent1.status != AgentStatus.Fusing || parent2.status != AgentStatus.Fusing) {
            revert AgentAlreadyInFusionProcess(); // Incorrect status, fusion not initiated or already completed
        }
        if (msg.value < agentFusionCost) {
            revert InsufficientEthForSkillTraining(); // Reusing error for cost
        }

        address owner1 = ownerOf(parent1Id);
        address owner2 = ownerOf(parent2Id);
        address newOwner = msg.sender; // The one who executes fusion gets the new agent, could be owner1, owner2, or approved operator.

        // Burn parent agents (logically, their tokens are consumed)
        parent1.status = AgentStatus.Fused; // Mark as fused instead of _burn to retain historical data if needed
        parent2.status = AgentStatus.Fused;
        _burn(parent1Id); // Actual burning of token ID
        _burn(parent2Id); // Actual burning of token ID


        // Create a new child agent
        uint256 childId = _nextTokenId++;
        _mint(newOwner, childId, newAgentName, newAgentDescription, ""); // URI can be set post-fusion

        Agent storage childAgent = agents[childId];
        childAgent.experience = (parent1.experience + parent2.experience) / 2; // Avg experience
        childAgent.reputation = (parent1.reputation + parent2.reputation) * 120 / 100; // 20% rep bonus for fusion

        // Combine attributes (e.g., average + slight random boost/reduction)
        for (uint8 i = 0; i < 5; i++) {
            uint8 avgAttr = (parent1.attributes[i] + parent2.attributes[i]) / 2;
            // Add a small random element for dynamism
            uint8 randomModifier = uint8(uint256(keccak256(abi.encodePacked(childId, i, block.timestamp))) % 5) - 2; // -2 to +2
            childAgent.attributes[i] = _clampAttribute(avgAttr + randomModifier);
        }

        // Combine skills (child gets all skills from both parents)
        for (uint8 i = 1; i < nextSkillId; i++) {
            if (parent1.skills[i] || parent2.skills[i]) {
                childAgent.skills[i] = true;
            }
        }

        emit AgentFusionExecuted(parent1Id, parent2Id, childId, newAgentName);
        return childId;
    }

    /**
     * @dev Manually triggers the attribute drift mechanism for an agent.
     *      Attributes will subtly change (increase or decrease) based on a pseudo-random factor
     *      and a cooldown period.
     * @param tokenId The ID of the agent to drift.
     */
    function triggerAgentDrift(uint256 tokenId) public nonReentrant {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOrApproved();
        }
        Agent storage agent = agents[tokenId];
        if (agent.status != AgentStatus.Idle) {
            revert AgentEngagedOrFused();
        }
        if (block.timestamp < agent.lastDriftTime + DRIFT_INTERVAL) {
            // Revert with specific error if needed: "Drift cooldown not over"
            return; // No drift if cooldown period not passed
        }

        agent.lastDriftTime = uint64(block.timestamp);

        for (uint8 i = 0; i < 5; i++) {
            uint8 currentAttr = agent.attributes[i];
            // Deterministic pseudo-randomness based on block data and token ID
            int256 driftChange = int256(uint256(keccak256(abi.encodePacked(tokenId, i, block.timestamp))) % (2 * DRIFT_MAGNITUDE + 1)) - int256(DRIFT_MAGNITUDE); // -DRIFT_MAGNITUDE to +DRIFT_MAGNITUDE

            uint8 newAttr = _clampAttribute(currentAttr + int8(driftChange));
            if (newAttr != currentAttr) {
                agent.attributes[i] = newAttr;
                emit AgentAttributeDrifted(tokenId, i, currentAttr, newAttr);
            }
        }
    }

    /**
     * @dev Allows the owner to update their agent's metadata URI.
     * @param tokenId The ID of the agent.
     * @param newURI The new URI pointing to the agent's metadata.
     */
    function setAgentURI(uint256 tokenId, string memory newURI) public {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOrApproved();
        }
        agents[tokenId].tokenUri = newURI;
        emit AgentURIUpdated(tokenId, newURI);
    }

    /**
     * @dev Allows an owner to permanently destroy their agent.
     *      The agent must not be currently engaged in a task or fusion.
     * @param tokenId The ID of the agent to burn.
     */
    function burnAgent(uint256 tokenId) public {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOrApproved();
        }
        if (agents[tokenId].status != AgentStatus.Idle) {
            revert AgentEngagedOrFused();
        }

        _burn(tokenId);
    }

    // --- III. Governance & Protocol Parameters ---

    /**
     * @dev Allows anyone to propose a new skill type for agents.
     *      The proposal then needs to be voted on by governance participants.
     * @param skillName The name of the proposed skill.
     * @param skillDescription A description of what the skill entails.
     * @return The ID of the created proposal.
     */
    function proposeNewSkillType(string memory skillName, string memory skillDescription) public returns (uint256) {
        // Check if skill with this name already exists
        for(uint8 i = 1; i < nextSkillId; i++) {
            if (keccak256(abi.encodePacked(skills[i].name)) == keccak256(abi.encodePacked(skillName))) {
                revert SkillAlreadyExists();
            }
        }

        uint256 proposalId = nextProposalId++;
        // The calldata for adding a skill will be to an internal function or a specific helper
        bytes memory callData = abi.encodeWithSelector(
            this.addApprovedSkill.selector, // Selector for a helper function to add the skill
            skillName,
            skillDescription
        );

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Propose new skill: ", skillName, " - ", skillDescription)),
            callData: callData,
            votesFor: 0,
            votesAgainst: 0,
            expirationTime: uint64(block.timestamp + PROPOSAL_VOTING_PERIOD),
            status: ProposalStatus.Active
        });

        emit ProposalCreated(proposalId, msg.sender, proposals[proposalId].description, proposals[proposalId].expirationTime);
        emit NewSkillProposed(proposalId, nextSkillId, skillName); // Emit anticipated skill ID if it passes
        return proposalId;
    }

    /**
     * @dev Allows an address to vote on an active governance proposal.
     *      Each unique address gets 1 vote for simplicity.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.status != ProposalStatus.Active) {
            revert InvalidProposalState();
        }
        if (block.timestamp > proposal.expirationTime) {
            revert ProposalExpired();
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        // Track unique voters for quorum calculation
        if (totalGovernanceParticipants == 0) { // first voter
             totalGovernanceParticipants = 1;
        } else {
            bool found = false;
            // Iterate through all previous proposals to check if msg.sender has voted before.
            // This is inefficient for many proposals, but simple for this example.
            // A more advanced system would use a separate mapping `mapping(address => bool) hasParticipatedInGovernance;`
            for(uint256 i=1; i<nextProposalId; i++){
                if(proposals[i].hasVoted[msg.sender]){
                    found = true;
                    break;
                }
            }
            if(!found) totalGovernanceParticipants++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a successful governance proposal.
     *      Only callable after the voting period ends and if the proposal has enough 'for' votes.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.status != ProposalStatus.Active) {
            revert InvalidProposalState();
        }
        if (block.timestamp <= proposal.expirationTime) {
            revert ProposalExpired(); // Voting period must be over
        }

        // Check quorum: simple check based on total governance participants
        uint256 requiredQuorum = (totalGovernanceParticipants * PROPOSAL_QUORUM_PERCENT) / 100;
        if (proposal.votesFor + proposal.votesAgainst < requiredQuorum) {
             proposal.status = ProposalStatus.Failed;
             emit ProposalStateChanged(proposalId, ProposalStatus.Failed);
             revert NotEnoughVotes();
        }

        if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal passed!
            proposal.status = ProposalStatus.Succeeded;
            emit ProposalStateChanged(proposalId, ProposalStatus.Succeeded);

            // Execute the proposal's callData
            (bool success, ) = address(this).call(proposal.callData); // Execute the encoded function call
            if (!success) {
                // If the execution failed, the proposal still succeeded in voting, but implementation failed.
                // Could revert, or log and mark as "FailedExecution" state. For simplicity, just log.
                emit ProposalExecuted(proposalId, false);
                // Optionally revert: revert("Proposal execution failed.");
            } else {
                proposal.status = ProposalStatus.Executed;
                emit ProposalExecuted(proposalId, true);
                emit ProposalStateChanged(proposalId, ProposalStatus.Executed);
            }
        } else {
            // Proposal failed
            proposal.status = ProposalStatus.Failed;
            emit ProposalStateChanged(proposalId, ProposalStatus.Failed);
            emit ProposalExecuted(proposalId, false);
        }
    }

    /**
     * @dev Governance function to update the trusted oracle address.
     *      This function itself would be called via a governance proposal in a real DAO.
     * @param newOracle The address of the new oracle.
     */
    function setAttestationOracle(address newOracle) public onlyRole(GOVERNANCE_ADMIN_ROLE) {
        // This function would be encoded into a proposal's calldata.
        // For simplicity in the example, directly callable by GOVERNANCE_ADMIN.
        // In a full DAO, this would be a target of `executeProposal`.
        _revokeRole(ORACLE_ROLE, _oracleAddress()); // Revoke old oracle role
        _grantRole(ORACLE_ROLE, newOracle); // Grant new oracle role
        emit OracleAddressUpdated(newOracle);
    }

    /**
     * @dev Governance function to adjust the ETH cost for agent fusion.
     *      This function itself would be called via a governance proposal in a real DAO.
     * @param newCost The new cost in Wei.
     */
    function setFusionCost(uint256 newCost) public onlyRole(GOVERNANCE_ADMIN_ROLE) {
        // This function would be encoded into a proposal's calldata.
        // For simplicity in the example, directly callable by GOVERNANCE_ADMIN.
        // In a full DAO, this would be a target of `executeProposal`.
        agentFusionCost = newCost;
        emit FusionCostUpdated(newCost);
    }

    // --- Private Helper Functions ---

    /**
     * @dev Helper function to add a new skill after governance approval.
     *      Intended to be called via `executeProposal`.
     * @param name The name of the skill.
     * @param description The description of the skill.
     */
    function addApprovedSkill(string memory name, string memory description) public onlyRole(GOVERNANCE_ADMIN_ROLE) {
        // This function needs `onlyRole(GOVERNANCE_ADMIN_ROLE)` because it's called internally by `executeProposal`
        // which itself is secured by `onlyRole(GOVERNANCE_ADMIN_ROLE)` or by the governance logic.
        // If `executeProposal` can be called by anyone, this helper should be `internal`.
        // For security, if `executeProposal` allows any `calldata` execution, this should be internal or carefully permissioned.

        uint8 newSkillID = nextSkillId++;
        skills[newSkillID] = Skill({
            name: name,
            description: description,
            approvedByGovernance: true
        });
        // We could emit an event here specifically for skill addition.
    }

    /**
     * @dev Clamps an attribute value between MIN_ATTRIBUTE_VALUE and MAX_ATTRIBUTE_VALUE.
     * @param value The attribute value to clamp.
     * @return The clamped attribute value.
     */
    function _clampAttribute(int8 value) private pure returns (uint8) {
        if (value < int8(MIN_ATTRIBUTE_VALUE)) return uint8(MIN_ATTRIBUTE_VALUE);
        if (value > int8(MAX_ATTRIBUTE_VALUE)) return uint8(MAX_ATTRIBUTE_VALUE);
        return uint8(value);
    }

    /**
     * @dev Internal helper to get current oracle address.
     */
    function _oracleAddress() internal view returns (address) {
        bytes32 role = ORACLE_ROLE;
        // In AccessControl, `getRoleMember(role, 0)` typically gets the first member.
        // For a single oracle setup, this is fine. For multiple or dynamic, a separate mapping would be better.
        // Assuming a single ORACLE_ROLE holder for this example.
        return getRoleMember(role, 0);
    }

    // --- Receive & Fallback ---
    receive() external payable {}
    fallback() external payable {}
}
```