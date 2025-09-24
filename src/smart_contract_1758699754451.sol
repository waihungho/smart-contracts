This smart contract, `CognitoGraph`, proposes a novel approach to building a decentralized knowledge and reputation graph specifically designed for autonomous agents and AI systems. It aims to provide a verifiable and adaptive on-chain framework for agents to:

1.  **Register and manage their identities.**
2.  **Collaboratively create and curate a structured "Knowledge Graph" (KNodes).**
3.  **Attest to their own and other agents' skills and expertise, backed by economic stakes.**
4.  **Record contributions to the knowledge base.**
5.  **Build a dynamic reputation based on validated skills, contributions, and endorsements.**
6.  **Resolve disputes regarding claims through a staking and challenge mechanism.**

This system acts as a trust layer, enabling autonomous agents to discover, verify, and interact with each other based on objective, on-chain data about their capabilities and knowledge. The concepts of staked attestations, dynamic reputation, and a structured knowledge graph for agents aim to push the boundaries beyond traditional DeFi or NFT use cases.

---

## CognitoGraph Smart Contract

**Outline:**

1.  **Contract Description:** A decentralized, adaptive knowledge and reputation graph for AI agents and autonomous systems, facilitating verifiable skill attestations, knowledge sharing, and dynamic reputation building.
2.  **Key Concepts:**
    *   **Agents:** On-chain identities for autonomous entities.
    *   **Knowledge Nodes (KNodes):** Structured, interconnected pieces of information.
    *   **Skills:** Definable capabilities that agents can possess.
    *   **Staked Attestations:** Claims about skills or expertise backed by economic collateral, subject to challenge.
    *   **Dynamic Reputation:** A constantly evolving score based on verified contributions, skills, and endorsements.
    *   **Challenge Mechanism:** A system for disputing false claims, ensuring data integrity.
3.  **Enums & Structs:** Definition of various types and data structures used throughout the contract (e.g., `KNodeScope`, `StakeStatus`, `AgentProfile`, `KNode`, `Skill`, `Stake`).
4.  **State Variables:** Mappings and counters for managing Agents, KNodes, Skills, and Stakes.
5.  **Events:** To log significant actions and state changes for off-chain monitoring.
6.  **Modifiers:** Access control and validation modifiers.
7.  **ERC20 Interface:** For interaction with the staking token.
8.  **Functions:** Categorized below.

---

**Function Summary (26 Functions):**

**A. Core System & Agent Management (6 Functions)**
1.  `constructor`: Initializes the contract, sets the owner, and specifies the ERC20 stake token.
2.  `registerAgent`: Registers a new agent profile with a name and metadata URI.
3.  `updateAgentProfile`: Allows an agent to update their registered name and metadata URI.
4.  `depositForStakes`: Allows an agent to deposit `stakeToken` into the contract, available for future staking.
5.  `withdrawAvailableFunds`: Allows an agent to withdraw their unstaked and unslashed `stakeToken` from the contract.
6.  `setChallengeWindowDuration`: Owner function to set the duration for which stakes can be challenged.

**B. Knowledge Node (KNode) Management (5 Functions)**
7.  `createKNode`: Creates a new Knowledge Node with a title, content URI, and scope (e.g., Public, Private).
8.  `updateKNodeContent`: Allows the KNode creator or a highly reputed agent to update the KNode's content URI.
9.  `updateKNodeScope`: Allows the KNode creator or a highly reputed agent to change the KNode's visibility scope.
10. `attestKNodeQuality`: Allows an agent to attest to the quality/accuracy of a KNode with a score (0-100), influencing its reputation.
11. `linkKNodes`: Establishes a directional or bi-directional link between two KNodes with a specific link type (e.g., Prerequisite, Related).

**C. Skill & Expertise Attestation (6 Functions)**
12. `defineSkill`: Allows the owner or highly reputed agents to define new skills that can be attested to.
13. `attestAgentSkill`: An agent attests to another agent's skill proficiency, backing it with a `stakeToken` amount. Returns a `stakeId`.
14. `declareAgentExpertise`: An agent declares their expertise in a specific KNode, backing the claim with `stakeToken`. Returns a `stakeId`.
15. `challengeStake`: Allows any agent to challenge an existing skill attestation or expertise declaration stake, providing a challenge URI.
16. `resolveStakeByStaker`: Allows the original staker to withdraw their stake if the challenge window has passed without a valid challenge.
17. `resolveStakeByOwner`: Allows the contract owner (as a dispute arbiter) to resolve a challenged stake, slashing or distributing funds based on the challenge outcome.

**D. Contribution & Reputation System (2 Functions)**
18. `recordContribution`: Records an agent's contribution to a specific KNode (e.g., adding content, correcting an error).
19. `endorseAgent`: Allows an agent to endorse another agent for specific qualities (e.g., Trustworthy, Expert), contributing to their reputation.

**E. Query & Read Functions (7 Functions)**
20. `getAgentProfile`: Retrieves the full profile details of a registered agent.
21. `getKNode`: Retrieves the details of a specific Knowledge Node.
22. `getSkill`: Retrieves the details of a defined skill.
23. `getAgentActiveSkills`: Lists the active and validated skills for a given agent.
24. `getAgentsByExpertise`: Finds agents who have declared expertise in a specific KNode above a certain minimum level.
25. `getAgentReputation`: A view function that dynamically calculates and returns an agent's current reputation score.
26. `getKNodeReputation`: A view function that dynamically calculates and returns a KNode's current quality/reputation score.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CognitoGraph
 * @dev A decentralized, adaptive knowledge and reputation graph for AI agents and autonomous systems.
 *
 * This contract provides a framework for:
 * 1. Agent Registration and Profile Management.
 * 2. Collaborative creation and curation of Knowledge Nodes (KNodes).
 * 3. Staked Attestations for agent skills and KNode expertise, enabling economic-backed claims.
 * 4. A dispute resolution mechanism for challenging claims.
 * 5. Recording contributions and endorsements to build dynamic agent reputation.
 * 6. Querying the knowledge graph and agent capabilities.
 *
 * The goal is to establish a verifiable and adaptive on-chain trust layer for autonomous entities.
 *
 * Outline:
 * - Contract Description: Decentralized, adaptive knowledge and reputation graph for AI agents.
 * - Key Concepts: Agents, Knowledge Nodes (KNodes), Skills, Staked Attestations, Dynamic Reputation, Challenge Mechanism.
 * - Enums & Structs: Definitions for various data types (KNodeScope, StakeStatus, AgentProfile, KNode, Skill, Stake, etc.).
 * - State Variables: Mappings and counters for managing all entities.
 * - Events: To log significant state changes.
 * - Modifiers: Access control and validation.
 * - IERC20 Interface: For interaction with the staking token.
 * - Functions (26 total): Categorized below for clarity.
 *
 * Function Summary:
 * A. Core System & Agent Management (6 Functions)
 *    1. constructor: Initializes contract, sets owner, and staking token.
 *    2. registerAgent: Registers a new agent profile.
 *    3. updateAgentProfile: Updates an agent's profile details.
 *    4. depositForStakes: Allows agents to deposit tokens for future staking.
 *    5. withdrawAvailableFunds: Allows agents to withdraw unstaked tokens.
 *    6. setChallengeWindowDuration: Owner sets stake challenge duration.
 *
 * B. Knowledge Node (KNode) Management (5 Functions)
 *    7. createKNode: Creates a new Knowledge Node.
 *    8. updateKNodeContent: Updates content URI of a KNode.
 *    9. updateKNodeScope: Updates visibility scope of a KNode.
 *    10. attestKNodeQuality: Agents attest to KNode quality.
 *    11. linkKNodes: Establishes relationships between KNodes.
 *
 * C. Skill & Expertise Attestation (6 Functions)
 *    12. defineSkill: Defines a new skill.
 *    13. attestAgentSkill: Agent attests to another agent's skill, with a stake.
 *    14. declareAgentExpertise: Agent declares expertise in a KNode, with a stake.
 *    15. challengeStake: Challenges a staked attestation/declaration.
 *    16. resolveStakeByStaker: Staker resolves their stake if unchallenged.
 *    17. resolveStakeByOwner: Owner resolves challenged stakes.
 *
 * D. Contribution & Reputation System (2 Functions)
 *    18. recordContribution: Records an agent's contribution to a KNode.
 *    19. endorseAgent: Agent endorses another agent.
 *
 * E. Query & Read Functions (7 Functions)
 *    20. getAgentProfile: Retrieves an agent's full profile.
 *    21. getKNode: Retrieves KNode details.
 *    22. getSkill: Retrieves skill details.
 *    23. getAgentActiveSkills: Lists an agent's active, validated skills.
 *    24. getAgentsByExpertise: Finds agents by KNode expertise.
 *    25. getAgentReputation: Calculates and returns an agent's reputation.
 *    26. getKNodeReputation: Calculates and returns a KNode's reputation.
 */
contract CognitoGraph is Ownable {
    IERC20 public immutable stakeToken;
    uint256 public challengeWindowDuration; // Duration in seconds for stakes to be challenged

    // --- Enums ---
    enum KNodeScope { Public, Private, Restricted }
    enum KNodeLinkType { Prerequisite, Related, Refutes, ExpandsOn, ExampleOf, DependsOn }
    enum ContributionType { AddedContent, CorrectedError, Translated, VerifiedData, ProposedLink }
    enum EndorsementType { Trustworthy, Expert, ReliableCollaborator, Innovative }
    enum StakeStatus { Active, Resolved, Challenged, Withdrawn, Slashed }
    enum StakeType { SkillAttestation, AgentExpertise }

    // --- Structs ---

    struct AgentProfile {
        string name;
        string metadataURI; // IPFS hash or similar for richer profile info
        uint256 registeredAt;
        bool exists; // To check if address is registered
    }

    struct KNode {
        string title;
        string contentURI;
        address creator;
        uint256 createdAt;
        KNodeScope scope;
        uint256 cumulativeQualityScore; // Sum of attestations * weight
        uint256 numQualityAttestations;
        bool exists;
    }

    struct Skill {
        string name;
        string descriptionURI;
        address creator; // Who defined the skill
        bool exists;
    }

    struct Stake {
        address staker;
        uint256 amount;
        uint256 createdAt;
        StakeStatus status;
        uint256 challengeWindowEnd;
        uint256 targetId; // ID of the SkillAttestation or AgentExpertise it refers to
        StakeType sType;
        string challengeURI; // URI for the challenge proof if challenged
        address challenger; // Address of the challenger
    }

    struct SkillAttestation {
        address attester; // Who attested
        address subjectAgent; // Who the skill is for
        uint256 skillId;
        uint8 proficiency; // 0-100
        uint256 stakeId; // Link to the associated stake
        uint256 attestedAt;
        string attestationURI; // Proof/context URI
        bool exists;
    }

    struct AgentExpertise {
        address declarer;
        uint256 kNodeId;
        uint8 level; // e.g., 1-5
        uint256 stakeId; // Link to the associated stake
        uint256 declaredAt;
        bool exists;
    }

    struct KNodeLink {
        uint256 kNodeId1;
        uint256 kNodeId2;
        KNodeLinkType linkType;
        address proposer;
        uint256 proposedAt;
        string descriptionURI;
        bool exists;
    }

    struct Contribution {
        uint256 kNodeId;
        address contributor;
        ContributionType cType;
        uint256 contributedAt;
        string proofURI;
        bool exists;
    }

    struct Endorsement {
        address endorser;
        address endorsedAgent;
        EndorsementType eType;
        uint256 endorsedAt;
        string endorsementURI;
        bool exists;
    }

    // --- State Variables ---

    uint256 private _nextKNodeId = 1;
    uint256 private _nextSkillId = 1;
    uint256 private _nextStakeId = 1;
    uint256 private _nextSkillAttestationId = 1;
    uint256 private _nextAgentExpertiseId = 1;
    uint256 private _nextKNodeLinkId = 1;
    uint256 private _nextContributionId = 1;
    uint256 private _nextEndorsementId = 1;

    mapping(address => AgentProfile) public agents;
    mapping(uint256 => KNode) public kNodes;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Stake) public stakes;
    mapping(uint256 => SkillAttestation) public skillAttestations;
    mapping(uint256 => AgentExpertise) public agentExpertiseDeclarations;
    mapping(uint256 => KNodeLink) public kNodeLinks;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => Endorsement) public endorsements;

    // Agent's available (not staked/slashed) funds within the contract
    mapping(address => uint256) public agentDeposits;

    // To track agent's active skill attestations
    mapping(address => uint256[]) public agentToSkillAttestations;
    // To track agent's active expertise declarations
    mapping(address => uint256[]) public agentToExpertiseDeclarations;
    // To track KNode's outgoing links
    mapping(uint256 => uint256[]) public kNodeToOutgoingLinks;
    // To track agent's contributions
    mapping(address => uint256[]) public agentToContributions;

    // --- Events ---
    event AgentRegistered(address indexed agentAddress, string name, string metadataURI, uint256 registeredAt);
    event AgentProfileUpdated(address indexed agentAddress, string newName, string newMetadataURI);
    event FundsDeposited(address indexed agentAddress, uint255 amount);
    event FundsWithdrawn(address indexed agentAddress, uint255 amount);
    event KNodeCreated(uint256 indexed kNodeId, string title, address indexed creator, KNodeScope scope, uint256 createdAt);
    event KNodeContentUpdated(uint256 indexed kNodeId, string newContentURI);
    event KNodeScopeUpdated(uint256 indexed kNodeId, KNodeScope newScope);
    event KNodeQualityAttested(uint256 indexed kNodeId, address indexed attester, uint8 score, string attestationURI);
    event KNodeLinked(uint256 indexed linkId, uint256 indexed kNodeId1, uint256 indexed kNodeId2, KNodeLinkType linkType);
    event SkillDefined(uint256 indexed skillId, string name, string descriptionURI);
    event SkillAttested(uint256 indexed attestationId, uint256 indexed stakeId, address indexed subjectAgent, uint256 skillId, uint8 proficiency);
    event ExpertiseDeclared(uint256 indexed expertiseId, uint256 indexed stakeId, address indexed declarer, uint256 kNodeId, uint8 level);
    event StakeChallenged(uint256 indexed stakeId, address indexed challenger, string challengeURI);
    event StakeResolved(uint256 indexed stakeId, StakeStatus status, uint256 amount);
    event ContributionRecorded(uint256 indexed contributionId, uint256 indexed kNodeId, address indexed contributor, ContributionType cType);
    event AgentEndorsed(uint256 indexed endorsementId, address indexed endorser, address indexed endorsedAgent, EndorsementType eType);
    event ChallengeWindowDurationSet(uint256 newDuration);

    // --- Modifiers ---
    modifier onlyAgentExists(address _agent) {
        require(agents[_agent].exists, "Agent: Not registered");
        _;
    }

    modifier onlyKNodeExists(uint256 _kNodeId) {
        require(kNodes[_kNodeId].exists, "KNode: Not found");
        _;
    }

    modifier onlySkillExists(uint256 _skillId) {
        require(skills[_skillId].exists, "Skill: Not found");
        _;
    }

    modifier onlyStakeExists(uint256 _stakeId) {
        require(stakes[_stakeId].exists, "Stake: Not found");
        _;
    }

    modifier onlyActiveStake(uint256 _stakeId) {
        require(stakes[_stakeId].status == StakeStatus.Active, "Stake: Not active");
        _;
    }

    modifier onlyKNodeCreatorOrHighReputation(uint256 _kNodeId) {
        // For simplicity, only creator can update for now. Full reputation system would be more complex.
        require(kNodes[_kNodeId].creator == msg.sender, "KNode: Only creator can perform this action");
        // A more advanced version would check getAgentReputation(msg.sender) > MIN_REPUTATION_FOR_CURATION
        _;
    }

    modifier onlySkillCreatorOrOwner() {
        // For simplicity, only owner can define skills for now. Advanced would check reputation or DAO vote.
        require(owner() == msg.sender, "Skill: Only owner can define skills");
        _;
    }

    // --- Constructor ---

    constructor(address _stakeToken, uint256 _challengeWindowDuration) Ownable(msg.sender) {
        require(_stakeToken != address(0), "Stake token cannot be zero address");
        stakeToken = IERC20(_stakeToken);
        challengeWindowDuration = _challengeWindowDuration; // e.g., 3 days = 3 * 24 * 60 * 60
        emit ChallengeWindowDurationSet(_challengeWindowDuration);
    }

    // --- A. Core System & Agent Management ---

    /**
     * @dev Registers a new agent profile.
     * @param _name The agent's chosen name.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS hash of a richer profile).
     */
    function registerAgent(string calldata _name, string calldata _metadataURI) external {
        require(!agents[msg.sender].exists, "Agent: Already registered");
        require(bytes(_name).length > 0, "Agent: Name cannot be empty");

        agents[msg.sender] = AgentProfile({
            name: _name,
            metadataURI: _metadataURI,
            registeredAt: block.timestamp,
            exists: true
        });
        emit AgentRegistered(msg.sender, _name, _metadataURI, block.timestamp);
    }

    /**
     * @dev Updates an agent's registered name and metadata URI.
     * @param _newName The new name for the agent.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateAgentProfile(string calldata _newName, string calldata _newMetadataURI) external onlyAgentExists(msg.sender) {
        require(bytes(_newName).length > 0, "Agent: Name cannot be empty");

        AgentProfile storage agent = agents[msg.sender];
        agent.name = _newName;
        agent.metadataURI = _newMetadataURI;
        emit AgentProfileUpdated(msg.sender, _newName, _newMetadataURI);
    }

    /**
     * @dev Allows an agent to deposit `stakeToken` into the contract for future staking.
     * @param _amount The amount of `stakeToken` to deposit.
     */
    function depositForStakes(uint256 _amount) external onlyAgentExists(msg.sender) {
        require(_amount > 0, "Deposit: Amount must be greater than 0");
        require(stakeToken.transferFrom(msg.sender, address(this), _amount), "Deposit: Token transfer failed");

        agentDeposits[msg.sender] += _amount;
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows an agent to withdraw their available (unstaked, unslashed) `stakeToken` from the contract.
     */
    function withdrawAvailableFunds() external onlyAgentExists(msg.sender) {
        uint256 available = agentDeposits[msg.sender];
        require(available > 0, "Withdraw: No funds available to withdraw");

        agentDeposits[msg.sender] = 0;
        require(stakeToken.transfer(msg.sender, available), "Withdraw: Token transfer failed");
        emit FundsWithdrawn(msg.sender, available);
    }

    /**
     * @dev Owner function to set the duration for which stakes can be challenged.
     * @param _newDuration The new challenge window duration in seconds.
     */
    function setChallengeWindowDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "Challenge window duration must be greater than 0");
        challengeWindowDuration = _newDuration;
        emit ChallengeWindowDurationSet(_newDuration);
    }

    // --- B. Knowledge Node (KNode) Management ---

    /**
     * @dev Creates a new Knowledge Node.
     * @param _title The title of the KNode.
     * @param _contentURI URI pointing to the KNode's content (e.g., IPFS hash of a document).
     * @param _scope The visibility scope of the KNode (Public, Private, Restricted).
     * @return The ID of the newly created KNode.
     */
    function createKNode(string calldata _title, string calldata _contentURI, KNodeScope _scope) external onlyAgentExists(msg.sender) returns (uint256) {
        require(bytes(_title).length > 0, "KNode: Title cannot be empty");
        require(bytes(_contentURI).length > 0, "KNode: Content URI cannot be empty");

        uint256 kNodeId = _nextKNodeId++;
        kNodes[kNodeId] = KNode({
            title: _title,
            contentURI: _contentURI,
            creator: msg.sender,
            createdAt: block.timestamp,
            scope: _scope,
            cumulativeQualityScore: 0,
            numQualityAttestations: 0,
            exists: true
        });
        emit KNodeCreated(kNodeId, _title, msg.sender, _scope, block.timestamp);
        return kNodeId;
    }

    /**
     * @dev Updates the content URI of an existing KNode. Only the creator or a highly reputed agent can update.
     * @param _kNodeId The ID of the KNode to update.
     * @param _newContentURI The new content URI.
     */
    function updateKNodeContent(uint256 _kNodeId, string calldata _newContentURI) external onlyKNodeExists(_kNodeId) onlyKNodeCreatorOrHighReputation(_kNodeId) {
        require(bytes(_newContentURI).length > 0, "KNode: New content URI cannot be empty");
        kNodes[_kNodeId].contentURI = _newContentURI;
        emit KNodeContentUpdated(_kNodeId, _newContentURI);
    }

    /**
     * @dev Updates the scope of an existing KNode. Only the creator or a highly reputed agent can update.
     * @param _kNodeId The ID of the KNode to update.
     * @param _newScope The new visibility scope.
     */
    function updateKNodeScope(uint256 _kNodeId, KNodeScope _newScope) external onlyKNodeExists(_kNodeId) onlyKNodeCreatorOrHighReputation(_kNodeId) {
        kNodes[_kNodeId].scope = _newScope;
        emit KNodeScopeUpdated(_kNodeId, _newScope);
    }

    /**
     * @dev Allows an agent to attest to the quality/accuracy of a KNode.
     * This contributes to the KNode's cumulative quality score and the attester's reputation.
     * @param _kNodeId The ID of the KNode to attest.
     * @param _score The quality score (0-100).
     * @param _attestationURI URI for proof or explanation of the attestation.
     */
    function attestKNodeQuality(uint256 _kNodeId, uint8 _score, string calldata _attestationURI) external onlyAgentExists(msg.sender) onlyKNodeExists(_kNodeId) {
        require(_score <= 100, "KNode: Score must be between 0 and 100");
        // Prevent self-attestation or too frequent attestations - could add more checks
        require(kNodes[_kNodeId].creator != msg.sender, "KNode: Creator cannot attest own KNode quality");

        KNode storage kNode = kNodes[_kNodeId];
        kNode.cumulativeQualityScore += _score; // Simple sum, could be weighted by attester reputation
        kNode.numQualityAttestations++;
        // This implicitly boosts msg.sender's reputation by demonstrating participation and judgment.

        emit KNodeQualityAttested(_kNodeId, msg.sender, _score, _attestationURI);
    }

    /**
     * @dev Establishes a relationship (link) between two KNodes.
     * @param _kNodeId1 The ID of the first KNode.
     * @param _kNodeId2 The ID of the second KNode.
     * @param _linkType The type of relationship (e.g., Prerequisite, Related).
     * @param _descriptionURI URI for details about this link.
     * @return The ID of the newly created KNode link.
     */
    function linkKNodes(uint256 _kNodeId1, uint256 _kNodeId2, KNodeLinkType _linkType, string calldata _descriptionURI) external onlyAgentExists(msg.sender) onlyKNodeExists(_kNodeId1) onlyKNodeExists(_kNodeId2) returns (uint256) {
        require(_kNodeId1 != _kNodeId2, "KNode: Cannot link a KNode to itself");

        uint256 linkId = _nextKNodeLinkId++;
        kNodeLinks[linkId] = KNodeLink({
            kNodeId1: _kNodeId1,
            kNodeId2: _kNodeId2,
            linkType: _linkType,
            proposer: msg.sender,
            proposedAt: block.timestamp,
            descriptionURI: _descriptionURI,
            exists: true
        });
        kNodeToOutgoingLinks[_kNodeId1].push(linkId); // Store outgoing link
        emit KNodeLinked(linkId, _kNodeId1, _kNodeId2, _linkType);
        return linkId;
    }

    // --- C. Skill & Expertise Attestation ---

    /**
     * @dev Defines a new skill that agents can possess. Only the owner can define skills for now.
     * @param _skillName The name of the skill.
     * @param _descriptionURI URI pointing to a description of the skill.
     * @return The ID of the newly defined skill.
     */
    function defineSkill(string calldata _skillName, string calldata _descriptionURI) external onlySkillCreatorOrOwner returns (uint256) {
        require(bytes(_skillName).length > 0, "Skill: Name cannot be empty");

        uint256 skillId = _nextSkillId++;
        skills[skillId] = Skill({
            name: _skillName,
            descriptionURI: _descriptionURI,
            creator: msg.sender,
            exists: true
        });
        emit SkillDefined(skillId, _skillName, _descriptionURI);
        return skillId;
    }

    /**
     * @dev An agent attests to another agent's skill proficiency, backing it with a stake.
     * This creates a SkillAttestation and an associated Stake.
     * @param _subjectAgent The address of the agent whose skill is being attested.
     * @param _skillId The ID of the skill being attested.
     * @param _proficiency The proficiency level (0-100).
     * @param _stakeAmount The amount of `stakeToken` to stake on this attestation.
     * @param _attestationURI URI pointing to proof or context for the attestation.
     * @return The ID of the created stake.
     */
    function attestAgentSkill(address _subjectAgent, uint256 _skillId, uint8 _proficiency, uint256 _stakeAmount, string calldata _attestationURI) external onlyAgentExists(msg.sender) onlyAgentExists(_subjectAgent) onlySkillExists(_skillId) returns (uint256) {
        require(msg.sender != _subjectAgent, "Attest: Cannot attest your own skill");
        require(_proficiency <= 100, "Attest: Proficiency must be between 0 and 100");
        require(_stakeAmount > 0, "Attest: Stake amount must be greater than 0");
        require(agentDeposits[msg.sender] >= _stakeAmount, "Attest: Insufficient deposited funds for stake");

        agentDeposits[msg.sender] -= _stakeAmount;

        uint256 stakeId = _nextStakeId++;
        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: _stakeAmount,
            createdAt: block.timestamp,
            status: StakeStatus.Active,
            challengeWindowEnd: block.timestamp + challengeWindowDuration,
            targetId: _nextSkillAttestationId, // Target the ID of the soon-to-be-created SkillAttestation
            sType: StakeType.SkillAttestation,
            challengeURI: "",
            challenger: address(0),
            exists: true
        });

        uint256 attestationId = _nextSkillAttestationId++;
        skillAttestations[attestationId] = SkillAttestation({
            attester: msg.sender,
            subjectAgent: _subjectAgent,
            skillId: _skillId,
            proficiency: _proficiency,
            stakeId: stakeId,
            attestedAt: block.timestamp,
            attestationURI: _attestationURI,
            exists: true
        });

        agentToSkillAttestations[_subjectAgent].push(attestationId); // Track active attestations for the agent
        emit SkillAttested(attestationId, stakeId, _subjectAgent, _skillId, _proficiency);
        return stakeId;
    }

    /**
     * @dev An agent declares their expertise in a specific KNode, backing the claim with a stake.
     * This creates an AgentExpertise declaration and an associated Stake.
     * @param _kNodeId The ID of the KNode in which expertise is declared.
     * @param _level The expertise level (e.g., 1-5).
     * @param _stakeAmount The amount of `stakeToken` to stake on this declaration.
     * @return The ID of the created stake.
     */
    function declareAgentExpertise(uint256 _kNodeId, uint8 _level, uint256 _stakeAmount) external onlyAgentExists(msg.sender) onlyKNodeExists(_kNodeId) returns (uint256) {
        require(_level >= 1 && _level <= 5, "Expertise: Level must be between 1 and 5");
        require(_stakeAmount > 0, "Expertise: Stake amount must be greater than 0");
        require(agentDeposits[msg.sender] >= _stakeAmount, "Expertise: Insufficient deposited funds for stake");

        // Check if agent already declared expertise in this KNode (optional, for simple unique declaration)
        // More complex would allow multiple declarations, maybe overriding earlier ones.

        agentDeposits[msg.sender] -= _stakeAmount;

        uint256 stakeId = _nextStakeId++;
        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: _stakeAmount,
            createdAt: block.timestamp,
            status: StakeStatus.Active,
            challengeWindowEnd: block.timestamp + challengeWindowDuration,
            targetId: _nextAgentExpertiseId, // Target the ID of the soon-to-be-created AgentExpertise
            sType: StakeType.AgentExpertise,
            challengeURI: "",
            challenger: address(0),
            exists: true
        });

        uint256 expertiseId = _nextAgentExpertiseId++;
        agentExpertiseDeclarations[expertiseId] = AgentExpertise({
            declarer: msg.sender,
            kNodeId: _kNodeId,
            level: _level,
            stakeId: stakeId,
            declaredAt: block.timestamp,
            exists: true
        });

        agentToExpertiseDeclarations[msg.sender].push(expertiseId); // Track active expertise for the agent
        emit ExpertiseDeclared(expertiseId, stakeId, msg.sender, _kNodeId, _level);
        return stakeId;
    }

    /**
     * @dev Allows any agent to challenge an existing staked attestation or declaration.
     * @param _stakeId The ID of the stake to challenge.
     * @param _challengeURI URI pointing to proof or context for the challenge.
     */
    function challengeStake(uint256 _stakeId, string calldata _challengeURI) external onlyAgentExists(msg.sender) onlyStakeExists(_stakeId) onlyActiveStake(_stakeId) {
        Stake storage stake = stakes[_stakeId];
        require(block.timestamp <= stake.challengeWindowEnd, "Challenge: Challenge window has closed");
        require(msg.sender != stake.staker, "Challenge: Cannot challenge your own stake");
        require(bytes(_challengeURI).length > 0, "Challenge: Challenge URI cannot be empty");

        stake.status = StakeStatus.Challenged;
        stake.challengeURI = _challengeURI;
        stake.challenger = msg.sender;
        emit StakeChallenged(_stakeId, msg.sender, _challengeURI);
    }

    /**
     * @dev Allows the original staker to resolve their stake and claim funds if the challenge window has passed without a valid challenge.
     * @param _stakeId The ID of the stake to resolve.
     */
    function resolveStakeByStaker(uint256 _stakeId) external onlyStakeExists(_stakeId) {
        Stake storage stake = stakes[_stakeId];
        require(stake.staker == msg.sender, "Resolve: Only the staker can resolve this stake");
        require(stake.status == StakeStatus.Active, "Resolve: Stake is not active (might be challenged or already resolved)");
        require(block.timestamp > stake.challengeWindowEnd, "Resolve: Challenge window is still open");

        stake.status = StakeStatus.Resolved;
        agentDeposits[msg.sender] += stake.amount; // Return staked amount to staker's deposits
        emit StakeResolved(_stakeId, StakeStatus.Resolved, stake.amount);
    }

    /**
     * @dev Allows the contract owner (acting as a dispute arbiter) to resolve a challenged stake.
     * Funds are either returned to the staker or distributed (partially/fully) to the challenger.
     * @param _stakeId The ID of the stake to resolve.
     * @param _isChallengerCorrect True if the challenger's claim is valid, false otherwise.
     */
    function resolveStakeByOwner(uint256 _stakeId, bool _isChallengerCorrect) external onlyOwner onlyStakeExists(_stakeId) {
        Stake storage stake = stakes[_stakeId];
        require(stake.status == StakeStatus.Challenged, "Resolve: Stake is not currently challenged");

        if (_isChallengerCorrect) {
            stake.status = StakeStatus.Slashed;
            // For simplicity, slashed amount goes to challenger. More complex: split, burn, governance.
            agentDeposits[stake.challenger] += stake.amount;
            // Invalidate the underlying attestation/expertise
            if (stake.sType == StakeType.SkillAttestation) {
                skillAttestations[stake.targetId].exists = false;
            } else if (stake.sType == StakeType.AgentExpertise) {
                agentExpertiseDeclarations[stake.targetId].exists = false;
            }
            emit StakeResolved(_stakeId, StakeStatus.Slashed, stake.amount);
        } else {
            stake.status = StakeStatus.Resolved;
            agentDeposits[stake.staker] += stake.amount;
            emit StakeResolved(_stakeId, StakeStatus.Resolved, stake.amount);
        }
    }

    // --- D. Contribution & Reputation System ---

    /**
     * @dev Records an agent's contribution to a specific KNode.
     * This positively influences the contributor's reputation.
     * @param _kNodeId The ID of the KNode to which the contribution was made.
     * @param _type The type of contribution (e.g., AddedContent, CorrectedError).
     * @param _proofURI URI pointing to proof of the contribution.
     * @return The ID of the recorded contribution.
     */
    function recordContribution(uint256 _kNodeId, ContributionType _type, string calldata _proofURI) external onlyAgentExists(msg.sender) onlyKNodeExists(_kNodeId) returns (uint256) {
        require(bytes(_proofURI).length > 0, "Contribution: Proof URI cannot be empty");

        uint256 contributionId = _nextContributionId++;
        contributions[contributionId] = Contribution({
            kNodeId: _kNodeId,
            contributor: msg.sender,
            cType: _type,
            contributedAt: block.timestamp,
            proofURI: _proofURI,
            exists: true
        });
        agentToContributions[msg.sender].push(contributionId); // Track contributions for the agent
        emit ContributionRecorded(contributionId, _kNodeId, msg.sender, _type);
        return contributionId;
    }

    /**
     * @dev Allows an agent to endorse another agent for specific qualities.
     * This positively influences the endorsed agent's reputation.
     * @param _agentToEndorse The address of the agent being endorsed.
     * @param _eType The type of endorsement (e.g., Trustworthy, Expert).
     * @param _endorsementURI URI pointing to context or explanation for the endorsement.
     * @return The ID of the recorded endorsement.
     */
    function endorseAgent(address _agentToEndorse, EndorsementType _eType, string calldata _endorsementURI) external onlyAgentExists(msg.sender) onlyAgentExists(_agentToEndorse) returns (uint256) {
        require(msg.sender != _agentToEndorse, "Endorse: Cannot endorse yourself");
        // Potentially add a cooldown or limit on endorsements to prevent spam.

        uint256 endorsementId = _nextEndorsementId++;
        endorsements[endorsementId] = Endorsement({
            endorser: msg.sender,
            endorsedAgent: _agentToEndorse,
            eType: _eType,
            endorsedAt: block.timestamp,
            endorsementURI: _endorsementURI,
            exists: true
        });
        emit AgentEndorsed(endorsementId, msg.sender, _agentToEndorse, _eType);
        return endorsementId;
    }

    // --- E. Query & Read Functions ---

    /**
     * @dev Retrieves the full profile details of a registered agent.
     * @param _agent The address of the agent.
     * @return AgentProfile struct containing name, metadataURI, registeredAt, and exists status.
     */
    function getAgentProfile(address _agent) external view returns (AgentProfile memory) {
        return agents[_agent];
    }

    /**
     * @dev Retrieves the details of a specific Knowledge Node.
     * @param _kNodeId The ID of the KNode.
     * @return KNode struct containing title, contentURI, creator, createdAt, scope, cumulativeQualityScore, numQualityAttestations, and exists status.
     */
    function getKNode(uint256 _kNodeId) external view returns (KNode memory) {
        return kNodes[_kNodeId];
    }

    /**
     * @dev Retrieves the details of a defined skill.
     * @param _skillId The ID of the skill.
     * @return Skill struct containing name, descriptionURI, creator, and exists status.
     */
    function getSkill(uint256 _skillId) external view returns (Skill memory) {
        return skills[_skillId];
    }

    /**
     * @dev Lists all active and validated skill attestations for a given agent.
     * @param _agent The address of the agent.
     * @return An array of `SkillAttestation` structs.
     */
    function getAgentActiveSkills(address _agent) external view onlyAgentExists(_agent) returns (SkillAttestation[] memory) {
        uint256[] storage attestationIds = agentToSkillAttestations[_agent];
        SkillAttestation[] memory activeSkills = new SkillAttestation[](attestationIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < attestationIds.length; i++) {
            SkillAttestation storage sa = skillAttestations[attestationIds[i]];
            if (sa.exists && stakes[sa.stakeId].status == StakeStatus.Resolved) {
                activeSkills[count] = sa;
                count++;
            }
        }
        // Resize array to actual count if needed
        SkillAttestation[] memory result = new SkillAttestation[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeSkills[i];
        }
        return result;
    }

    /**
     * @dev Finds agents who have declared expertise in a specific KNode above a certain minimum level.
     * @param _kNodeId The ID of the KNode.
     * @param _minLevel The minimum expertise level to filter by (1-5).
     * @return An array of agent addresses.
     */
    function getAgentsByExpertise(uint256 _kNodeId, uint8 _minLevel) external view onlyKNodeExists(_kNodeId) returns (address[] memory) {
        require(_minLevel >= 1 && _minLevel <= 5, "Expertise: Min level must be between 1 and 5");

        address[] memory expertAgents = new address[](_nextAgentExpertiseId); // Max possible size
        uint256 count = 0;

        // Iterate through all expertise declarations (can be optimized with a dedicated mapping for KNode to expert agents)
        for (uint256 i = 1; i < _nextAgentExpertiseId; i++) {
            AgentExpertise storage ae = agentExpertiseDeclarations[i];
            if (ae.exists && ae.kNodeId == _kNodeId && ae.level >= _minLevel && stakes[ae.stakeId].status == StakeStatus.Resolved) {
                expertAgents[count] = ae.declarer;
                count++;
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = expertAgents[i];
        }
        return result;
    }

    /**
     * @dev Dynamically calculates an agent's current reputation score.
     * This is a simplified calculation for on-chain. A true reputation system would be more complex,
     * involving graph algorithms, time decay, weighted endorsements, and verified contributions.
     * For this contract, it aggregates scores from resolved skill attestations, expertise declarations,
     * and a simple count of contributions and endorsements.
     * @param _agent The address of the agent.
     * @return The calculated reputation score.
     */
    function getAgentReputation(address _agent) public view onlyAgentExists(_agent) returns (uint256) {
        uint256 reputation = 0;
        uint256 currentTimestamp = block.timestamp;

        // Factor 1: Skill Attestations
        for (uint256 i = 0; i < agentToSkillAttestations[_agent].length; i++) {
            SkillAttestation storage sa = skillAttestations[agentToSkillAttestations[_agent][i]];
            Stake storage stake = stakes[sa.stakeId];
            if (sa.exists && stake.status == StakeStatus.Resolved) {
                // Proficiency * a constant weight. Add decay over time.
                uint256 timeFactor = (currentTimestamp - sa.attestedAt < 365 days) ? 100 : 50; // Simple decay: halved after 1 year
                reputation += (sa.proficiency * timeFactor) / 100;
            }
        }

        // Factor 2: Expertise Declarations
        for (uint256 i = 0; i < agentToExpertiseDeclarations[_agent].length; i++) {
            AgentExpertise storage ae = agentExpertiseDeclarations[_agent][i];
            Stake storage stake = stakes[ae.stakeId];
            if (ae.exists && stake.status == StakeStatus.Resolved) {
                uint256 timeFactor = (currentTimestamp - ae.declaredAt < 365 days) ? 100 : 50;
                reputation += (ae.level * 20 * timeFactor) / 100; // Expertise level 1-5, scale it up
            }
        }

        // Factor 3: Contributions
        reputation += agentToContributions[_agent].length * 5; // Each contribution adds 5 points

        // Factor 4: Endorsements (can be refined to be weighted by endorser's reputation)
        // This would require iterating through all endorsements, checking if _agent is endorsed
        // For simplicity, let's just do a dummy fixed bonus for being endorsed X times (requires another mapping or iterating all endorsements)
        // Let's iterate all endorsements to count them, inefficient but illustrative
        uint256 endorsementCount = 0;
        for (uint256 i = 1; i < _nextEndorsementId; i++) {
            Endorsement storage ed = endorsements[i];
            if (ed.exists && ed.endorsedAgent == _agent) {
                endorsementCount++;
            }
        }
        reputation += endorsementCount * 10;

        return reputation;
    }

    /**
     * @dev Dynamically calculates a KNode's current quality/reputation score.
     * Aggregates quality attestations. Could also factor in creator reputation, link quality, etc.
     * @param _kNodeId The ID of the KNode.
     * @return The calculated KNode quality score.
     */
    function getKNodeReputation(uint256 _kNodeId) public view onlyKNodeExists(_kNodeId) returns (uint256) {
        KNode storage kNode = kNodes[_kNodeId];
        if (kNode.numQualityAttestations == 0) {
            return 0;
        }
        return kNode.cumulativeQualityScore / kNode.numQualityAttestations; // Simple average
    }

    /**
     * @dev Retrieves details of a specific stake.
     * @param _stakeId The ID of the stake.
     * @return Stake struct containing all details.
     */
    function getStakeDetails(uint256 _stakeId) external view returns (Stake memory) {
        return stakes[_stakeId];
    }
}
```