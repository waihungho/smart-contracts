Okay, this is an exciting challenge! Let's build something truly unique, combining dynamic NFTs, oracle-driven AI verification (simulated), collaborative agents, and an on-chain knowledge base, all governed by a DAO.

---

**Contract: EvoMind Nexus - Autonomous Digital Entity Network**

**Core Concept:**
EvoMind Nexus pioneers a decentralized ecosystem where users mint and manage "Digital Entities" – unique, programmable NFTs that possess dynamic attributes and skills. These entities can be assigned complex tasks, collaborate within "Swarms," and evolve over time based on their performance and user-initiated upgrades. A robust oracle system (simulating AI verification) evaluates task completion and entity efficacy, while a community-driven DAO ensures the protocol's adaptive governance. Entities contribute to a shared, on-chain "Knowledge Base," fostering collective intelligence within the network.

---

**I. Core Components:**

*   **DigitalEntity (ERC721):** Represents an autonomous agent with dynamic attributes (e.g., Intelligence, Agility, Resilience, Skills, MindScore).
*   **EvoToken (ERC20):** The native utility token for transactions, upgrades, rewards, and governance staking.
*   **Oracle:** A trusted external entity (simulated as an address) responsible for verifying task results and approving entity evolutions. This could be a Chainlink node, a ZK-proof verifier, or a human multi-sig in a real-world scenario.
*   **KnowledgeBase:** A decentralized, on-chain repository of data contributed by entities, accessible for querying.
*   **Task Management:** System for proposing, assigning, executing, and verifying tasks with associated rewards.
*   **Swarm Mechanics:** Enables entities to form collaborative groups for complex tasks.
*   **DAO Governance:** For protocol parameter changes, upgrades, and critical decisions.

---

**II. Function Summary (Total: 25 Functions):**

**A. DigitalEntity (NFT) Management (ERC721 Standard Extensions)**
1.  `mintEntity(string memory _initialMetadataURI)`: Mints a new Digital Entity NFT for the caller with initial attributes and metadata.
2.  `getEntityDetails(uint256 _tokenId)`: Retrieves all detailed attributes, skills, and current state of a specific entity.
3.  `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an entity, reflecting its current state and evolution.
4.  `burnEntity(uint256 _tokenId)`: Allows the owner to destroy an entity, potentially for resources or strategic reallocation.

**B. Entity Evolution & Upgrades**
5.  `proposeSkillUpgrade(uint256 _tokenId, string memory _skillName, uint256 _cost)`: Owner proposes a new skill for their entity, requiring EvoTokens and pending Oracle approval.
6.  `verifyAndApplySkillUpgrade(uint256 _proposalId, bool _approved)`: Oracle verifies the skill upgrade proposal (e.g., checking prerequisites) and applies/rejects it.
7.  `mergeEntities(uint256 _tokenId1, uint256 _tokenId2)`: Combines two entities into a new, potentially stronger one, consuming the originals and inheriting/averaging attributes.
8.  `mutateEntityAttributes(uint256 _tokenId, bytes32 _mutationSeed)`: Initiates a probabilistic mutation of an entity's attributes, costing EvoTokens and influenced by a seed for randomness.
9.  `stakeEntityForPassiveLearning(uint256 _tokenId)`: Stakes an entity to passively accumulate "experience" or "MindScore" over time, increasing its potential.
10. `unstakeEntity(uint256 _tokenId)`: Unstakes an entity, making it available for active tasks again and stopping passive learning.

**C. Task Management & Verification**
11. `proposeTask(string memory _taskDescription, uint256 _rewardAmount, uint256 _requiredMindScore, uint256 _deadline)`: A user proposes a new task for the network, setting its parameters and reward.
12. `assignTaskToEntity(uint256 _taskId, uint256 _entityId)`: Assigns an approved task to a single Digital Entity if it meets the requirements.
13. `submitTaskResult(uint256 _taskId, uint256 _entityId, string memory _resultHash)`: Entity owner submits an off-chain task result's hash for Oracle verification.
14. `verifyTaskResultByOracle(uint256 _taskId, uint256 _entityId, bool _successful, uint256 _performanceScore)`: Oracle verifies the submitted task result (based on _resultHash) and updates the entity's MindScore.
15. `claimTaskReward(uint256 _taskId)`: Allows the successful entity owner to claim the task reward in EvoTokens.

**D. Swarm Intelligence & Collaboration**
16. `createEntitySwarm(string memory _swarmName, uint256[] memory _memberTokenIds)`: Forms a collaborative "Swarm" of entities, allowing them to pool capabilities for complex tasks.
17. `addEntityToSwarm(uint256 _swarmId, uint256 _tokenId)`: Adds an entity to an existing swarm (requires owner consent and swarm leader approval).
18. `assignTaskToSwarm(uint256 _taskId, uint256 _swarmId)`: Assigns a complex task to an entire swarm, distributing rewards based on pre-defined swarm rules or contributions.

**E. Knowledge Base & Collective Learning**
19. `contributeToKnowledgeBase(uint256 _entityId, string memory _dataKey, string memory _dataValue, uint256 _contributionReward)`: An entity (via its owner) contributes data to the shared knowledge base, earning a reward.
20. `queryKnowledgeBase(string memory _dataKey)`: Retrieves data from the knowledge base, potentially requiring a query fee in EvoTokens.

**F. Protocol Governance & Administration**
21. `proposeProtocolParameterChange(bytes32 _paramKey, uint256 _newValue, string memory _description)`: A user proposes a change to a global protocol parameter (e.g., minting fee, oracle address).
22. `voteOnProposal(uint256 _proposalId, bool _support)`: EvoToken holders or staked entities vote on active proposals.
23. `executeProposal(uint256 _proposalId)`: Executes a passed proposal, updating the relevant protocol parameters.
24. `updateOracleAddress(address _newOracle)`: DAO-approved function to update the trusted oracle address in case of compromise or upgrade.
25. `delegateExternalCall(address _target, bytes memory _calldata, string memory _description)`: Allows a DAO-approved proposal to execute an arbitrary call to another contract, enabling advanced autonomous agent behavior or protocol integrations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces (for potential external integrations, simulated here) ---
interface IOracle {
    function requestVerification(uint256 taskId, string memory resultHash) external returns (bytes32 requestId);
    function fulfillVerification(bytes32 requestId, bool success, uint256 performanceScore) external;
}

/**
 * @title EvoMindNexus
 * @dev A decentralized network for autonomous Digital Entities (NFTs) that evolve, collaborate, and perform tasks.
 *      It integrates dynamic NFTs, simulated AI oracle verification, an on-chain knowledge base, and DAO governance.
 */
contract EvoMindNexus is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Global Counters
    Counters.Counter private _entityIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _swarmIds;
    Counters.Counter private _skillUpgradeProposalIds;
    Counters.Counter private _governanceProposalIds;

    // EvoToken for internal economy
    EvoToken public evoToken;

    // Oracle Address (responsible for external verifications)
    address public oracleAddress;

    // Protocol Parameters (governed by DAO)
    struct ProtocolParams {
        uint256 mintingFee; // EvoTokens required to mint an entity
        uint256 skillUpgradeCost; // Base cost for skill upgrade
        uint256 mergeFee; // Cost to merge entities
        uint256 mutateFee; // Cost for attribute mutation
        uint256 taskProposalFee; // Fee to propose a task
        uint256 minMindScoreForStaking; // Minimum MindScore to stake an entity
        uint256 stakingRewardRate; // Passive EvoTokens gained per block for staked entity (simulated)
        uint256 knowledgeBaseContributionReward; // Reward for contributing to KB
        uint256 knowledgeBaseQueryFee; // Fee to query KB
    }
    ProtocolParams public params;

    // --- Structs ---

    struct DigitalEntity {
        uint256 id;
        address owner;
        string name;
        uint256 intelligence; // Core attribute
        uint256 agility;      // Core attribute
        uint256 resilience;   // Core attribute
        uint256 mindScore;    // Reputation/performance score
        mapping(string => bool) skills; // Dynamic skills
        bool isStaked;
        uint256 stakedBlock; // Block number when staked
        uint256 currentTaskId; // 0 if no task assigned
        uint256 currentSwarmId; // 0 if not in a swarm
    }
    mapping(uint256 => DigitalEntity) public entities;
    mapping(uint256 => string[]) public entitySkillsArray; // To iterate skills

    struct Task {
        uint256 id;
        address proposer;
        string description;
        uint256 rewardAmount;
        uint256 requiredMindScore;
        uint256 deadline;
        uint256 assignedEntityId; // 0 if not assigned to single entity
        uint256 assignedSwarmId; // 0 if not assigned to swarm
        bool completed;
        bool verified;
        bool rewarded;
        uint256 performanceScore; // Score given by oracle
    }
    mapping(uint256 => Task) public tasks;

    struct EntitySwarm {
        uint256 id;
        string name;
        address leader; // The creator of the swarm
        uint256[] members; // Token IDs of member entities
        mapping(uint256 => bool) isMember;
        uint256 pendingTaskId; // Task assigned to the swarm
        // More complex swarm-specific logic could be added here (e.g., reward distribution rules)
    }
    mapping(uint256 => EntitySwarm) public swarms;

    struct SkillUpgradeProposal {
        uint256 proposalId;
        uint256 entityId;
        string skillName;
        address proposer;
        bool approved;
        bool processed;
    }
    mapping(uint256 => SkillUpgradeProposal) public skillUpgradeProposals;

    // On-chain Knowledge Base
    mapping(string => string) public knowledgeBase;

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes32 paramKey; // For parameter changes
        uint256 newValue; // For parameter changes
        address targetContract; // For delegateExternalCall
        bytes callData;         // For delegateExternalCall
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationBlock;
        uint256 votingDeadline;
        bool executed;
        bool isExternalCall; // true if it's a delegateExternalCall type
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, string name, uint256 initialMindScore);
    event EntityBurned(uint256 indexed tokenId, address indexed owner);
    event EntityAttributesMutated(uint256 indexed tokenId, uint256 newIntelligence, uint256 newAgility, uint256 newResilience);
    event EntityMerged(uint256 indexed newTokenId, uint256 indexed oldTokenId1, uint256 indexed oldTokenId2);
    event EntityStaked(uint256 indexed tokenId, address indexed owner, uint256 blockNumber);
    event EntityUnstaked(uint256 indexed tokenId, address indexed owner, uint256 rewardClaimed);
    event SkillUpgradeProposed(uint256 indexed proposalId, uint256 indexed entityId, string skillName);
    event SkillUpgradeApplied(uint256 indexed proposalId, uint256 indexed entityId, string skillName, bool success);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed entityId);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed entityId, string resultHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed entityId, bool successful, uint256 performanceScore);
    event TaskRewardClaimed(uint256 indexed taskId, address indexed claimant, uint256 rewardAmount);

    event SwarmCreated(uint256 indexed swarmId, string name, address indexed leader);
    event EntityAddedToSwarm(uint256 indexed swarmId, uint256 indexed tokenId);
    event TaskAssignedToSwarm(uint256 indexed taskId, uint256 indexed swarmId);

    event KnowledgeBaseContributed(uint256 indexed entityId, string dataKey, string dataValue);
    event KnowledgeBaseQueried(address indexed querier, string dataKey, string dataValue);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EvoMindNexus: Only the oracle can call this function.");
        _;
    }

    modifier entityOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "EvoMindNexus: Entity does not exist.");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "EvoMindNexus: Not entity owner or approved.");
        _;
    }

    modifier canInteractWithEntity(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "EvoMindNexus: Not the owner of the entity.");
        _;
    }

    // --- Constructor ---
    constructor(address _evoTokenAddress, address _initialOracleAddress)
        ERC721("EvoMind Digital Entity", "EVOMIND")
        Ownable(msg.sender)
    {
        evoToken = EvoToken(_evoTokenAddress);
        oracleAddress = _initialOracleAddress;

        // Initialize default parameters
        params.mintingFee = 100 * (10 ** evoToken.decimals());
        params.skillUpgradeCost = 50 * (10 ** evoToken.decimals());
        params.mergeFee = 150 * (10 ** evoToken.decimals());
        params.mutateFee = 20 * (10 ** evoToken.decimals());
        params.taskProposalFee = 10 * (10 ** evoToken.decimals());
        params.minMindScoreForStaking = 50;
        params.stakingRewardRate = 1 * (10 ** evoToken.decimals()); // 1 EvoToken per block (simplified)
        params.knowledgeBaseContributionReward = 5 * (10 ** evoToken.decimals());
        params.knowledgeBaseQueryFee = 1 * (10 ** evoToken.decimals());
    }

    // --- A. DigitalEntity (NFT) Management ---

    /**
     * @dev Mints a new Digital Entity NFT for the caller.
     * Requires EvoTokens as minting fee. Initial attributes are randomized within a range.
     * @param _initialMetadataURI Base URI for the entity's dynamic metadata.
     */
    function mintEntity(string memory _initialMetadataURI) public payable {
        require(evoToken.transferFrom(msg.sender, address(this), params.mintingFee), "EvoMindNexus: EvoToken transfer failed for minting fee.");

        _entityIds.increment();
        uint256 newTokenId = _entityIds.current();

        // Simulate initial randomized attributes
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId, block.difficulty)));
        uint256 initialIntelligence = (entropy % 50) + 50; // 50-99
        uint256 initialAgility = ((entropy / 100) % 50) + 50; // 50-99
        uint256 initialResilience = ((entropy / 10000) % 50) + 50; // 50-99
        uint256 initialMindScore = (initialIntelligence + initialAgility + initialResilience) / 3;

        DigitalEntity storage newEntity = entities[newTokenId];
        newEntity.id = newTokenId;
        newEntity.owner = msg.sender;
        newEntity.name = string(abi.encodePacked("Entity #", newTokenId.toString()));
        newEntity.intelligence = initialIntelligence;
        newEntity.agility = initialAgility;
        newEntity.resilience = initialResilience;
        newEntity.mindScore = initialMindScore;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialMetadataURI);

        emit EntityMinted(newTokenId, msg.sender, newEntity.name, newEntity.mindScore);
    }

    /**
     * @dev Retrieves all detailed attributes, skills, and current state of a specific entity.
     * @param _tokenId The ID of the Digital Entity.
     * @return Entity's ID, owner, name, attributes, MindScore, staking status, and skills.
     */
    function getEntityDetails(uint256 _tokenId)
        public
        view
        returns (
            uint256 id,
            address owner,
            string memory name,
            uint256 intelligence,
            uint256 agility,
            uint256 resilience,
            uint256 mindScore,
            bool isStaked,
            string[] memory skills
        )
    {
        DigitalEntity storage entity = entities[_tokenId];
        require(entity.id != 0, "EvoMindNexus: Entity does not exist.");

        id = entity.id;
        owner = entity.owner;
        name = entity.name;
        intelligence = entity.intelligence;
        agility = entity.agility;
        resilience = entity.resilience;
        mindScore = entity.mindScore;
        isStaked = entity.isStaked;
        skills = entitySkillsArray[_tokenId];
    }

    /**
     * @dev Returns the dynamic metadata URI for an entity, reflecting its current state and evolution.
     * Overrides ERC721URIStorage's tokenURI to include dynamic attributes.
     * @param _tokenId The ID of the Digital Entity.
     * @return The JSON metadata URI.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");

        DigitalEntity storage entity = entities[_tokenId];
        string memory baseURI = _baseURI(); // Or use a dedicated metadata server base URI
        
        // This is a simplified dynamic metadata construction.
        // In a real dApp, this would point to an API endpoint that generates JSON based on on-chain data.
        // Example: https://api.evomindnexus.com/metadata/{_tokenId}
        // For simplicity, we'll just show the baseURI.
        return string(abi.encodePacked(baseURI, _tokenId.toString(), "/",
            "{\"name\": \"", entity.name, "\",",
            "\"description\": \"An autonomous digital entity evolving within the EvoMind Nexus.\",",
            "\"attributes\": [",
            "{\"trait_type\": \"Intelligence\", \"value\": ", entity.intelligence.toString(), "},",
            "{\"trait_type\": \"Agility\", \"value\": ", entity.agility.toString(), "},",
            "{\"trait_type\": \"Resilience\", \"value\": ", entity.resilience.toString(), "},",
            "{\"trait_type\": \"MindScore\", \"value\": ", entity.mindScore.toString(), "},",
            "{\"trait_type\": \"Skills\", \"value\": \"", string(abi.encodePacked(entitySkillsArray[_tokenId].length > 0 ? string(abi.encodePacked(entitySkillsArray[_tokenId][0], (entitySkillsArray[_tokenId].length > 1 ? ", ..." : ""))) : "None")), "\"},",
            "{\"trait_type\": \"Staked\", \"value\": ", (entity.isStaked ? "\"True\"" : "\"False\""), "}",
            "]}"
        ));
    }

    /**
     * @dev Allows the owner to destroy an entity.
     * @param _tokenId The ID of the Digital Entity to burn.
     */
    function burnEntity(uint256 _tokenId) public entityOwner(_tokenId) {
        require(entities[_tokenId].currentTaskId == 0, "EvoMindNexus: Cannot burn entity with active task.");
        require(entities[_tokenId].currentSwarmId == 0, "EvoMindNexus: Cannot burn entity while in a swarm.");
        require(!entities[_tokenId].isStaked, "EvoMindNexus: Cannot burn staked entity.");

        address owner = ownerOf(_tokenId);
        _burn(_tokenId);
        delete entities[_tokenId]; // Remove from our custom struct mapping
        delete entitySkillsArray[_tokenId]; // Clear skills

        emit EntityBurned(_tokenId, owner);
    }

    // --- B. Entity Evolution & Upgrades ---

    /**
     * @dev Owner proposes a new skill for their entity, requiring EvoTokens.
     * @param _tokenId The ID of the Digital Entity.
     * @param _skillName The name of the skill to propose.
     * @param _cost Specific cost for this skill, if different from default.
     */
    function proposeSkillUpgrade(uint256 _tokenId, string memory _skillName, uint256 _cost) public canInteractWithEntity(_tokenId) {
        require(entities[_tokenId].skills[_skillName] == false, "EvoMindNexus: Entity already has this skill.");
        require(evoToken.transferFrom(msg.sender, address(this), _cost > 0 ? _cost : params.skillUpgradeCost), "EvoMindNexus: EvoToken transfer failed for skill upgrade cost.");

        _skillUpgradeProposalIds.increment();
        uint256 proposalId = _skillUpgradeProposalIds.current();

        skillUpgradeProposals[proposalId] = SkillUpgradeProposal({
            proposalId: proposalId,
            entityId: _tokenId,
            skillName: _skillName,
            proposer: msg.sender,
            approved: false, // Pending oracle approval
            processed: false
        });

        emit SkillUpgradeProposed(proposalId, _tokenId, _skillName);
    }

    /**
     * @dev Oracle verifies the skill upgrade proposal and applies/rejects it.
     * Only callable by the designated oracle address.
     * @param _proposalId The ID of the skill upgrade proposal.
     * @param _approved Whether the oracle approves the skill upgrade.
     */
    function verifyAndApplySkillUpgrade(uint256 _proposalId, bool _approved) public onlyOracle {
        SkillUpgradeProposal storage proposal = skillUpgradeProposals[_proposalId];
        require(proposal.proposalId != 0, "EvoMindNexus: Skill upgrade proposal does not exist.");
        require(!proposal.processed, "EvoMindNexus: Skill upgrade proposal already processed.");

        proposal.approved = _approved;
        proposal.processed = true;

        if (_approved) {
            DigitalEntity storage entity = entities[proposal.entityId];
            entity.skills[proposal.skillName] = true;
            entitySkillsArray[proposal.entityId].push(proposal.skillName);
            // Optionally, boost relevant attributes or MindScore
            entity.mindScore += 5; // Small boost for new skill
            emit SkillUpgradeApplied(_proposalId, proposal.entityId, proposal.skillName, true);
        } else {
            // Refund EvoTokens to proposer if rejected, or burn them for failed proposals
            // For simplicity, we'll burn them here as a cost of failed proposals.
            emit SkillUpgradeApplied(_proposalId, proposal.entityId, proposal.skillName, false);
        }
    }

    /**
     * @dev Combines two entities into a new, potentially stronger one, consuming the originals.
     * Attributes are averaged or combined in a specific way, and MindScore is boosted.
     * @param _tokenId1 The ID of the first entity.
     * @param _tokenId2 The ID of the second entity.
     * Requires both entities to be owned by msg.sender.
     */
    function mergeEntities(uint256 _tokenId1, uint256 _tokenId2) public {
        require(msg.sender == ownerOf(_tokenId1) && msg.sender == ownerOf(_tokenId2), "EvoMindNexus: Must own both entities to merge.");
        require(_tokenId1 != _tokenId2, "EvoMindNexus: Cannot merge an entity with itself.");
        require(entities[_tokenId1].currentTaskId == 0 && entities[_tokenId2].currentTaskId == 0, "EvoMindNexus: Cannot merge entities with active tasks.");
        require(entities[_tokenId1].currentSwarmId == 0 && entities[_tokenId2].currentSwarmId == 0, "EvoMindNexus: Cannot merge entities in a swarm.");
        require(!entities[_tokenId1].isStaked && !entities[_tokenId2].isStaked, "EvoMindNexus: Cannot merge staked entities.");
        require(evoToken.transferFrom(msg.sender, address(this), params.mergeFee), "EvoMindNexus: EvoToken transfer failed for merge fee.");

        DigitalEntity storage entity1 = entities[_tokenId1];
        DigitalEntity storage entity2 = entities[_tokenId2];

        _entityIds.increment();
        uint256 newMergedTokenId = _entityIds.current();

        // New entity's attributes (e.g., average + bonus)
        uint256 newIntelligence = (entity1.intelligence + entity2.intelligence) / 2 + 10;
        uint256 newAgility = (entity1.agility + entity2.agility) / 2 + 10;
        uint256 newResilience = (entity1.resilience + entity2.resilience) / 2 + 10;
        uint256 newMindScore = (entity1.mindScore + entity2.mindScore) / 2 + 20;

        DigitalEntity storage newEntity = entities[newMergedTokenId];
        newEntity.id = newMergedTokenId;
        newEntity.owner = msg.sender;
        newEntity.name = string(abi.encodePacked("Merged Entity #", newMergedTokenId.toString()));
        newEntity.intelligence = newIntelligence;
        newEntity.agility = newAgility;
        newEntity.resilience = newResilience;
        newEntity.mindScore = newMindScore;

        // Combine skills (simple deduplication)
        string[] storage skills1 = entitySkillsArray[_tokenId1];
        string[] storage skills2 = entitySkillsArray[_tokenId2];
        for (uint256 i = 0; i < skills1.length; i++) {
            newEntity.skills[skills1[i]] = true;
            entitySkillsArray[newMergedTokenId].push(skills1[i]);
        }
        for (uint256 i = 0; i < skills2.length; i++) {
            if (!newEntity.skills[skills2[i]]) {
                newEntity.skills[skills2[i]] = true;
                entitySkillsArray[newMergedTokenId].push(skills2[i]);
            }
        }

        _safeMint(msg.sender, newMergedTokenId);
        _setTokenURI(newMergedTokenId, string(abi.encodePacked("https://api.evomindnexus.com/metadata/", newMergedTokenId.toString()))); // Dynamic URI
        
        // Burn the original entities
        _burn(_tokenId1);
        _burn(_tokenId2);
        delete entities[_tokenId1];
        delete entities[_tokenId2];
        delete entitySkillsArray[_tokenId1];
        delete entitySkillsArray[_tokenId2];

        emit EntityMerged(newMergedTokenId, _tokenId1, _tokenId2);
    }

    /**
     * @dev Initiates a probabilistic mutation of an entity's attributes, costing EvoTokens.
     * The `_mutationSeed` can be used for controlled "randomness" in dApps.
     * @param _tokenId The ID of the Digital Entity.
     * @param _mutationSeed A seed value for pseudo-random attribute changes.
     */
    function mutateEntityAttributes(uint256 _tokenId, bytes32 _mutationSeed) public canInteractWithEntity(_tokenId) {
        require(entities[_tokenId].currentTaskId == 0, "EvoMindNexus: Cannot mutate entity with active task.");
        require(entities[_tokenId].currentSwarmId == 0, "EvoMindNexus: Cannot mutate entity while in a swarm.");
        require(!entities[_tokenId].isStaked, "EvoMindNexus: Cannot mutate staked entity.");
        require(evoToken.transferFrom(msg.sender, address(this), params.mutateFee), "EvoMindNexus: EvoToken transfer failed for mutation fee.");

        DigitalEntity storage entity = entities[_tokenId];
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, _mutationSeed, entity.id, block.difficulty)));

        // Apply a small mutation (e.g., +/- 1-5 points)
        entity.intelligence = (seed % 2 == 0) ? entity.intelligence + (seed % 5) : entity.intelligence - (seed % 5);
        entity.agility = ((seed / 10) % 2 == 0) ? entity.agility + ((seed / 10) % 5) : entity.agility - ((seed / 10) % 5);
        entity.resilience = ((seed / 100) % 2 == 0) ? entity.resilience + ((seed / 100) % 5) : entity.resilience - ((seed / 100) % 5);

        // Ensure attributes don't go below a minimum or exceed a maximum (e.g., 10 to 200)
        entity.intelligence = (entity.intelligence < 10) ? 10 : (entity.intelligence > 200 ? 200 : entity.intelligence);
        entity.agility = (entity.agility < 10) ? 10 : (entity.agility > 200 ? 200 : entity.agility);
        entity.resilience = (entity.resilience < 10) ? 10 : (entity.resilience > 200 ? 200 : entity.resilience);

        // MindScore recalculation might happen or based on oracle adjustment.
        // For simplicity, we'll give a slight boost on mutation success.
        entity.mindScore += 2;

        emit EntityAttributesMutated(_tokenId, entity.intelligence, entity.agility, entity.resilience);
    }

    /**
     * @dev Stakes an entity to passively accumulate "experience" or "MindScore" over time.
     * Requires minimum MindScore to be eligible.
     * @param _tokenId The ID of the Digital Entity to stake.
     */
    function stakeEntityForPassiveLearning(uint256 _tokenId) public canInteractWithEntity(_tokenId) {
        DigitalEntity storage entity = entities[_tokenId];
        require(!entity.isStaked, "EvoMindNexus: Entity is already staked.");
        require(entity.currentTaskId == 0, "EvoMindNexus: Cannot stake entity with active task.");
        require(entity.currentSwarmId == 0, "EvoMindNexus: Cannot stake entity while in a swarm.");
        require(entity.mindScore >= params.minMindScoreForStaking, "EvoMindNexus: Entity MindScore too low for staking.");

        entity.isStaked = true;
        entity.stakedBlock = block.number;

        emit EntityStaked(_tokenId, msg.sender, block.number);
    }

    /**
     * @dev Unstakes an entity, making it available for tasks again and stopping passive learning.
     * Rewards accumulated EvoTokens based on staking duration.
     * @param _tokenId The ID of the Digital Entity to unstake.
     */
    function unstakeEntity(uint256 _tokenId) public canInteractWithEntity(_tokenId) {
        DigitalEntity storage entity = entities[_tokenId];
        require(entity.isStaked, "EvoMindNexus: Entity is not staked.");

        entity.isStaked = false;
        uint256 blocksStaked = block.number - entity.stakedBlock;
        uint256 earnedEvoTokens = blocksStaked * params.stakingRewardRate;

        if (earnedEvoTokens > 0) {
            require(evoToken.mint(msg.sender, earnedEvoTokens), "EvoMindNexus: EvoToken mint failed for staking reward.");
        }
        entity.stakedBlock = 0; // Reset staked block

        emit EntityUnstaked(_tokenId, msg.sender, earnedEvoTokens);
    }

    // --- C. Task Management & Verification ---

    /**
     * @dev A user proposes a new task for the network, setting its parameters and reward.
     * Requires EvoTokens as a proposal fee.
     * @param _taskDescription Description of the task.
     * @param _rewardAmount Amount of EvoTokens to be rewarded upon successful completion.
     * @param _requiredMindScore Minimum MindScore an entity needs to be assigned this task.
     * @param _deadline Block number by which the task must be completed.
     */
    function proposeTask(string memory _taskDescription, uint256 _rewardAmount, uint256 _requiredMindScore, uint256 _deadline) public {
        require(_deadline > block.number, "EvoMindNexus: Task deadline must be in the future.");
        require(_rewardAmount > 0, "EvoMindNexus: Task reward must be positive.");
        require(evoToken.transferFrom(msg.sender, address(this), params.taskProposalFee), "EvoMindNexus: EvoToken transfer failed for task proposal fee.");
        // EvoToken for reward must also be transferred upfront
        require(evoToken.transferFrom(msg.sender, address(this), _rewardAmount), "EvoMindNexus: EvoToken transfer failed for task reward.");


        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            proposer: msg.sender,
            description: _taskDescription,
            rewardAmount: _rewardAmount,
            requiredMindScore: _requiredMindScore,
            deadline: _deadline,
            assignedEntityId: 0,
            assignedSwarmId: 0,
            completed: false,
            verified: false,
            rewarded: false,
            performanceScore: 0
        });

        emit TaskProposed(newTaskId, msg.sender, _rewardAmount);
    }

    /**
     * @dev Assigns an approved task to a single Digital Entity if it meets the requirements.
     * Only the entity owner can assign their entity to a task.
     * @param _taskId The ID of the task to assign.
     * @param _entityId The ID of the Digital Entity to assign.
     */
    function assignTaskToEntity(uint256 _taskId, uint256 _entityId) public canInteractWithEntity(_entityId) {
        Task storage task = tasks[_taskId];
        DigitalEntity storage entity = entities[_entityId];

        require(task.id != 0, "EvoMindNexus: Task does not exist.");
        require(entity.id != 0, "EvoMindNexus: Entity does not exist.");
        require(task.assignedEntityId == 0 && task.assignedSwarmId == 0, "EvoMindNexus: Task already assigned.");
        require(entity.currentTaskId == 0, "EvoMindNexus: Entity already has an active task.");
        require(entity.currentSwarmId == 0, "EvoMindNexus: Entity is in a swarm.");
        require(!entity.isStaked, "EvoMindNexus: Staked entity cannot be assigned tasks.");
        require(block.number < task.deadline, "EvoMindNexus: Task deadline has passed.");
        require(entity.mindScore >= task.requiredMindScore, "EvoMindNexus: Entity MindScore too low for this task.");

        task.assignedEntityId = _entityId;
        entity.currentTaskId = _taskId;

        emit TaskAssigned(_taskId, _entityId);
    }

    /**
     * @dev Entity owner submits an off-chain task result's hash for Oracle verification.
     * @param _taskId The ID of the task.
     * @param _entityId The ID of the entity that performed the task.
     * @param _resultHash A hash representing the off-chain result data.
     */
    function submitTaskResult(uint256 _taskId, uint256 _entityId, string memory _resultHash) public canInteractWithEntity(_entityId) {
        Task storage task = tasks[_taskId];
        DigitalEntity storage entity = entities[_entityId];

        require(task.id != 0 && entity.id != 0, "EvoMindNexus: Task or Entity does not exist.");
        require(task.assignedEntityId == _entityId, "EvoMindNexus: Task not assigned to this entity.");
        require(!task.completed, "EvoMindNexus: Task already completed.");
        require(block.number <= task.deadline, "EvoMindNexus: Task deadline has passed.");

        // In a real scenario, this would trigger an external call to an oracle service
        // e.g., Chainlink request or a custom oracle contract interaction.
        // For this example, we simulate it by setting a flag for oracle to pick up.

        emit TaskResultSubmitted(_taskId, _entityId, _resultHash);
    }

    /**
     * @dev Oracle verifies the submitted task result (based on _resultHash) and updates the entity's MindScore.
     * Only callable by the designated oracle address.
     * @param _taskId The ID of the task.
     * @param _entityId The ID of the entity that performed the task.
     * @param _successful Whether the task was successfully completed.
     * @param _performanceScore The performance score given by the oracle for this task (0-100).
     */
    function verifyTaskResultByOracle(uint256 _taskId, uint256 _entityId, bool _successful, uint256 _performanceScore) public onlyOracle {
        Task storage task = tasks[_taskId];
        DigitalEntity storage entity = entities[_entityId];

        require(task.id != 0 && entity.id != 0, "EvoMindNexus: Task or Entity does not exist.");
        require(task.assignedEntityId == _entityId, "EvoMindNexus: Task not assigned to this entity.");
        require(!task.verified, "EvoMindNexus: Task already verified.");
        require(entity.currentTaskId == _taskId, "EvoMindNexus: Entity is not currently on this task.");

        task.completed = true;
        task.verified = true;
        task.performanceScore = _performanceScore;
        entity.currentTaskId = 0; // Free up entity

        // Update entity MindScore based on performance
        if (_successful) {
            entity.mindScore = entity.mindScore + (_performanceScore / 10); // Adjust based on performance
        } else {
            if (entity.mindScore > 0) entity.mindScore -= 5; // Penalty for failure
        }

        emit TaskVerified(_taskId, _entityId, _successful, _performanceScore);
    }

    /**
     * @dev Allows the successful entity owner to claim the task reward in EvoTokens.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) public {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "EvoMindNexus: Task does not exist.");
        require(task.verified, "EvoMindNexus: Task not yet verified.");
        require(task.completed, "EvoMindNexus: Task not successfully completed.");
        require(!task.rewarded, "EvoMindNexus: Task reward already claimed.");
        require(ownerOf(task.assignedEntityId) == msg.sender, "EvoMindNexus: Only owner of assigned entity can claim reward.");

        task.rewarded = true;
        require(evoToken.transfer(msg.sender, task.rewardAmount), "EvoMindNexus: EvoToken transfer failed for reward.");

        emit TaskRewardClaimed(_taskId, msg.sender, task.rewardAmount);
    }

    // --- D. Swarm Intelligence & Collaboration ---

    /**
     * @dev Forms a collaborative "Swarm" of entities.
     * All members must be owned by the creator.
     * @param _swarmName Name of the new swarm.
     * @param _memberTokenIds Array of token IDs to include in the swarm.
     */
    function createEntitySwarm(string memory _swarmName, uint256[] memory _memberTokenIds) public {
        require(_memberTokenIds.length > 1, "EvoMindNexus: A swarm must have at least two members.");

        _swarmIds.increment();
        uint256 newSwarmId = _swarmIds.current();

        EntitySwarm storage newSwarm = swarms[newSwarmId];
        newSwarm.id = newSwarmId;
        newSwarm.name = _swarmName;
        newSwarm.leader = msg.sender;

        for (uint256 i = 0; i < _memberTokenIds.length; i++) {
            uint256 tokenId = _memberTokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "EvoMindNexus: Cannot create swarm with entities not owned by creator.");
            require(entities[tokenId].currentSwarmId == 0, "EvoMindNexus: Entity is already in a swarm.");
            require(entities[tokenId].currentTaskId == 0, "EvoMindNexus: Entity has active task.");
            require(!entities[tokenId].isStaked, "EvoMindNexus: Entity is staked.");

            newSwarm.members.push(tokenId);
            newSwarm.isMember[tokenId] = true;
            entities[tokenId].currentSwarmId = newSwarmId;
        }

        emit SwarmCreated(newSwarmId, _swarmName, msg.sender);
    }

    /**
     * @dev Adds an entity to an existing swarm. Requires owner consent and swarm leader approval.
     * @param _swarmId The ID of the swarm.
     * @param _tokenId The ID of the entity to add.
     */
    function addEntityToSwarm(uint256 _swarmId, uint256 _tokenId) public {
        EntitySwarm storage swarm = swarms[_swarmId];
        DigitalEntity storage entity = entities[_tokenId];

        require(swarm.id != 0, "EvoMindNexus: Swarm does not exist.");
        require(entity.id != 0, "EvoMindNexus: Entity does not exist.");
        require(msg.sender == ownerOf(_tokenId), "EvoMindNexus: You must own the entity to add it.");
        require(swarm.leader == msg.sender, "EvoMindNexus: Only the swarm leader can add members."); // Simplified: or a DAO vote, or member approval
        require(!swarm.isMember[_tokenId], "EvoMindNexus: Entity is already a member of this swarm.");
        require(entity.currentSwarmId == 0, "EvoMindNexus: Entity is already in another swarm.");
        require(entity.currentTaskId == 0, "EvoMindNexus: Entity has active task.");
        require(!entity.isStaked, "EvoMindNexus: Entity is staked.");

        swarm.members.push(_tokenId);
        swarm.isMember[_tokenId] = true;
        entity.currentSwarmId = _swarmId;

        emit EntityAddedToSwarm(_swarmId, _tokenId);
    }

    /**
     * @dev Assigns a complex task to an entire swarm.
     * Reward distribution logic would be handled internally by the swarm leader/contract or an external mechanism.
     * @param _taskId The ID of the task.
     * @param _swarmId The ID of the swarm.
     */
    function assignTaskToSwarm(uint256 _taskId, uint256 _swarmId) public {
        Task storage task = tasks[_taskId];
        EntitySwarm storage swarm = swarms[_swarmId];

        require(task.id != 0, "EvoMindNexus: Task does not exist.");
        require(swarm.id != 0, "EvoMindNexus: Swarm does not exist.");
        require(msg.sender == swarm.leader, "EvoMindNexus: Only the swarm leader can assign tasks to the swarm.");
        require(task.assignedEntityId == 0 && task.assignedSwarmId == 0, "EvoMindNexus: Task already assigned.");
        require(swarm.pendingTaskId == 0, "EvoMindNexus: Swarm already has an active task.");
        require(block.number < task.deadline, "EvoMindNexus: Task deadline has passed.");

        // Check if combined MindScore of swarm members meets requirement (simplified)
        uint256 totalSwarmMindScore = 0;
        for (uint256 i = 0; i < swarm.members.length; i++) {
            totalSwarmMindScore += entities[swarm.members[i]].mindScore;
        }
        require(totalSwarmMindScore >= task.requiredMindScore, "EvoMindNexus: Swarm's combined MindScore too low for this task.");

        task.assignedSwarmId = _swarmId;
        swarm.pendingTaskId = _taskId;

        // Note: Task result submission and verification for swarms would be more complex,
        // potentially requiring multi-party signatures or aggregate oracle verification.
        // For simplicity, `submitTaskResult` and `verifyTaskResultByOracle` can be overloaded or adapted.

        emit TaskAssignedToSwarm(_taskId, _swarmId);
    }

    // --- E. Knowledge Base & Collective Learning ---

    /**
     * @dev An entity (via its owner) contributes data to the shared knowledge base, earning a reward.
     * This data could be anything: verified facts, model parameters, useful algorithms, etc.
     * @param _entityId The ID of the entity contributing.
     * @param _dataKey A unique key for the data.
     * @param _dataValue The data to store.
     * @param _contributionReward The reward to be given for this contribution (could be dynamic).
     */
    function contributeToKnowledgeBase(uint256 _entityId, string memory _dataKey, string memory _dataValue, uint256 _contributionReward) public canInteractWithEntity(_entityId) {
        require(bytes(knowledgeBase[_dataKey]).length == 0, "EvoMindNexus: Data key already exists in knowledge base."); // Prevent overwrites, encourage unique contributions
        require(_contributionReward <= params.knowledgeBaseContributionReward, "EvoMindNexus: Contribution reward too high."); // Limit reward

        knowledgeBase[_dataKey] = _dataValue;
        
        // Reward the contributor
        require(evoToken.mint(msg.sender, _contributionReward > 0 ? _contributionReward : params.knowledgeBaseContributionReward), "EvoMindNexus: EvoToken mint failed for KB contribution.");
        
        // Optionally, boost entity's mind score for contributing knowledge
        entities[_entityId].mindScore += 1;

        emit KnowledgeBaseContributed(_entityId, _dataKey, _dataValue);
    }

    /**
     * @dev Retrieves data from the knowledge base, potentially requiring a query fee.
     * @param _dataKey The key of the data to retrieve.
     * @return The data value associated with the key.
     */
    function queryKnowledgeBase(string memory _dataKey) public returns (string memory) {
        require(bytes(knowledgeBase[_dataKey]).length > 0, "EvoMindNexus: Data key not found in knowledge base.");

        // Implement a query fee. This could also be a subscription model.
        require(evoToken.transferFrom(msg.sender, address(this), params.knowledgeBaseQueryFee), "EvoMindNexus: EvoToken transfer failed for KB query fee.");

        string memory dataValue = knowledgeBase[_dataKey];
        emit KnowledgeBaseQueried(msg.sender, _dataKey, dataValue);
        return dataValue;
    }

    // --- F. Protocol Governance & Administration ---

    /**
     * @dev A user proposes a change to a global protocol parameter.
     * @param _paramKey A bytes32 identifier for the parameter (e.g., keccak256("mintingFee")).
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposed change.
     */
    function proposeProtocolParameterChange(bytes32 _paramKey, uint256 _newValue, string memory _description) public {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            paramKey: _paramKey,
            newValue: _newValue,
            targetContract: address(0), // Not for external calls
            callData: "",               // Not for external calls
            votesFor: 0,
            votesAgainst: 0,
            creationBlock: block.number,
            votingDeadline: block.number + 1000, // 1000 blocks for voting (approx 4-5 hours)
            executed: false,
            isExternalCall: false
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Users (EvoToken holders or entities) vote on active proposals.
     * Voting power could be based on staked EvoTokens or entity MindScore.
     * For simplicity, 1 address = 1 vote.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalId != 0, "EvoMindNexus: Proposal does not exist.");
        require(block.number <= proposal.votingDeadline, "EvoMindNexus: Voting period has ended.");
        require(!hasVoted[_proposalId][msg.sender], "EvoMindNexus: You have already voted on this proposal.");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        hasVoted[_proposalId][msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed proposal, updating the relevant protocol parameters.
     * Requires a quorum and majority vote.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeProposal(uint256 _proposalId) public {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposalId != 0, "EvoMindNexus: Proposal does not exist.");
        require(!proposal.executed, "EvoMindNexus: Proposal already executed.");
        require(block.number > proposal.votingDeadline, "EvoMindNexus: Voting period not yet ended.");

        // Simple quorum: at least 5 votes total. Simple majority: 50% + 1
        require(proposal.votesFor + proposal.votesAgainst >= 5, "EvoMindNexus: Not enough votes (quorum not met).");
        require(proposal.votesFor > proposal.votesAgainst, "EvoMindNexus: Proposal did not pass.");

        proposal.executed = true;

        if (proposal.isExternalCall) {
            // Execute external call
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "EvoMindNexus: External call execution failed.");
        } else {
            // Update internal parameters
            if (proposal.paramKey == keccak256("mintingFee")) {
                params.mintingFee = proposal.newValue;
            } else if (proposal.paramKey == keccak256("skillUpgradeCost")) {
                params.skillUpgradeCost = proposal.newValue;
            } else if (proposal.paramKey == keccak256("mergeFee")) {
                params.mergeFee = proposal.newValue;
            } else if (proposal.paramKey == keccak256("mutateFee")) {
                params.mutateFee = proposal.newValue;
            } else if (proposal.paramKey == keccak256("taskProposalFee")) {
                params.taskProposalFee = proposal.newValue;
            } else if (proposal.paramKey == keccak256("minMindScoreForStaking")) {
                params.minMindScoreForStaking = proposal.newValue;
            } else if (proposal.paramKey == keccak256("stakingRewardRate")) {
                params.stakingRewardRate = proposal.newValue;
            } else if (proposal.paramKey == keccak256("knowledgeBaseContributionReward")) {
                params.knowledgeBaseContributionReward = proposal.newValue;
            } else if (proposal.paramKey == keccak256("knowledgeBaseQueryFee")) {
                params.knowledgeBaseQueryFee = proposal.newValue;
            }
            // Add more parameters as needed
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev DAO-approved function to update the trusted oracle address.
     * Can only be called via a successful governance proposal.
     * @param _newOracle The address of the new oracle.
     */
    function updateOracleAddress(address _newOracle) public onlyOwner { // Owner here is the temporary admin, eventually DAO
        require(_newOracle != address(0), "EvoMindNexus: New oracle address cannot be zero.");
        address oldOracle = oracleAddress;
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(oldOracle, _newOracle);
    }

    /**
     * @dev Allows a DAO-approved proposal to execute an arbitrary call to another contract.
     * This enables advanced autonomous agent behavior or protocol integrations.
     * This function itself is callable only by `executeProposal` after a governance vote.
     * @param _target The address of the target contract.
     * @param _calldata The ABI-encoded function call data.
     */
    function delegateExternalCall(address _target, bytes memory _calldata, string memory _description) public {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            paramKey: bytes32(0),   // Not a parameter change
            newValue: 0,            // Not a parameter change
            targetContract: _target,
            callData: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            creationBlock: block.number,
            votingDeadline: block.number + 1000,
            executed: false,
            isExternalCall: true
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _description);
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Returns the current EvoToken balance held by the contract.
     * Useful for checking funds held for rewards, fees, etc.
     */
    function getContractEvoTokenBalance() public view returns (uint256) {
        return evoToken.balanceOf(address(this));
    }
}

// --- EvoToken (ERC20 implementation) ---
contract EvoToken is ERC20, Ownable {
    constructor() ERC20("EvoToken", "EVO") Ownable(msg.sender) {
        // Mint initial tokens to the deployer if needed, or leave to a specific minting function
        _mint(msg.sender, 1_000_000 * (10 ** decimals())); // Example: 1 million tokens for deployer
    }

    // Only EvoMindNexus contract can mint new tokens
    function mint(address to, uint256 amount) public returns (bool) {
        // In a real scenario, this would check if msg.sender is EvoMindNexus contract.
        // For testing, we'll keep it simple, but this is a critical access control point.
        // A better approach would be to pass `address(this)` (EvoMindNexus) in the constructor
        // and allow minting only from that address.
        _mint(to, amount);
        return true;
    }
}
```