This smart contract, `AdaptiveDigitalBeingCore`, introduces a novel concept for dynamic Non-Fungible Tokens (NFTs) that embody "Adaptive Digital Beings" (ADBs). These ADBs are designed to evolve their attributes, skills, and reputation based on on-chain interactions, community-driven AI prompts, and verifiable off-chain data. The contract integrates several advanced and trendy concepts:

*   **Dynamic NFTs:** ADBs are ERC721 tokens whose metadata (attributes, skills, reputation) changes on-chain, reflecting their unique evolution.
*   **On-chain Reputation System:** ADBs accumulate reputation, which unlocks new capabilities and influences their evolution paths. Users can delegate reputation to ADBs.
*   **AI Integration (Verifiable Off-chain):** A unique workflow allows users to propose AI prompts to influence ADB attributes. These prompts are approved by governance, executed by an off-chain AI oracle, and their verifiable results are applied on-chain.
*   **Mission System:** ADBs can undertake and complete missions (tasks) to earn rewards and further their evolution.
*   **Skill Tree:** ADBs can learn new skills, which have prerequisites and costs, enabling new functionalities.
*   **Resource Management:** ADBs consume "energy" for actions, which can be replenished by users, adding a game-theoretic or economic layer.

This contract aims to be distinct from common open-source projects by combining these elements into a cohesive, evolving digital entity framework.

---

## Contract Outline & Function Summary

**Contract Name:** `AdaptiveDigitalBeingCore`

**I. Core Data Structures & State Variables**
*   `ADB`: Struct representing a single Adaptive Digital Being (NFT), holding its ID, name, owner (via ERC721), energy, reputation, dynamic attributes, learned skills, current mission, and delegated reputation.
*   `Attribute`: Struct for an ADB's mutable characteristics (e.g., "empathy", "logic"), including name, value, category, and whether it's mutable by AI.
*   `Skill`: Struct defining a learnable capability, with name, description, energy/reputation costs, and prerequisite skills.
*   `Mission`: Struct for tasks proposed for ADBs, including rewards, requirements, and status.
*   `AIPrompt`: Struct for user-submitted natural language prompts to influence ADBs via AI, tracking proposer, target ADB, prompt text, status, and proposed attribute changes.
*   `Enums`: `MissionStatus` and `AIPromptStatus` to track the lifecycle of missions and AI prompts.

**II. Admin & Initialization Functions (7 functions)**
1.  `constructor(string memory _name, string memory _symbol)`: Deploys the contract, setting the initial owner, ERC721 name, and symbol. Initializes governance and oracle addresses to the deployer.
2.  `setGovernanceAddress(address _governanceAddress)`: (Owner-only) Sets the address authorized for governance actions (e.g., approving prompts, missions).
3.  `setOracleAddress(address _oracleAddress)`: (Owner-only) Sets the address authorized for submitting verifiable off-chain results (AI output, mission completion).
4.  `setEnergyReplenishCost(uint256 _newCost)`: (Owner-only) Adjusts the cost in ETH to replenish an ADB's energy.
5.  `setSkillLearningCost(uint256 _newCost)`: (Owner-only) Adjusts the base cost (in ETH) for an ADB to learn skills.
6.  `addInitialAttributeTemplate(string memory _name, string memory _category, bool _mutableByAI)`: (Owner-only) Defines new attribute types that ADBs can possess, setting their initial properties.
7.  `addSkillTemplate(string memory _name, string memory _description, uint256 _energyCost, uint256 _reputationCost, bytes32[] memory _prerequisiteSkills)`: (Owner-only) Defines new skill templates that ADBs can learn.

**III. ADB Creation & Management (3 functions)**
8.  `mintADB(address _to, string memory _name)`: Mints a new unique Adaptive Digital Being NFT to `_to` with an initial `_name`. Each ADB is initialized with base energy, reputation, and attributes from templates.
9.  `updateADBName(uint256 _adbId, string memory _newName)`: (ADB Owner-only) Allows an ADB owner to change their ADB's name.
10. `transferFrom(address from, address to, uint256 tokenId)` & `safeTransferFrom(...)`: (Inherited from ERC721) Standard NFT transfer functions, allowing ownership changes of ADBs.

**IV. Dynamic Evolution & Interaction (8 functions)**
11. `replenishADBEnergy(uint256 _adbId)`: Allows any user to add "energy" to a specific ADB by sending ETH.
12. `interactWithADB(uint256 _adbId, uint256 _energyCost, uint256 _reputationGain)`: A generic function for users to interact with an ADB, consuming its energy and boosting its reputation.
13. `learnSkill(uint256 _adbId, string memory _skillName)`: (ADB Owner-only) Initiates an ADB learning a new skill, requiring sufficient energy, reputation, and prerequisite skills.
14. `activateSkillEffect(uint256 _adbId, string memory _skillName)`: (ADB Owner-only) Conceptually triggers a learned skill's on-chain effect (e.g., consuming energy for a temporary boost).
15. `delegateReputation(uint256 _adbId, uint256 _amount)`: Allows a user to delegate their reputation points to an ADB, increasing its overall influence and standing.
16. `revokeReputationDelegation(uint256 _adbId, uint256 _amount)`: Allows a user to revoke previously delegated reputation from an ADB.
17. `proposeAIPrompt(uint256 _adbId, string memory _promptText, bytes32[] memory _attributeNameHashes, uint256[] memory _newValues)`: Allows any user to propose a natural language prompt for AI to influence an ADB's attributes, along with expected changes.
18. `fulfillAIPromptResult(uint256 _promptId, uint256 _adbId, bytes32[] memory _attributeNames, uint256[] memory _newValues)`: (Oracle-only) Callback function for the trusted oracle to apply AI-driven attribute changes to an ADB after computation.

**V. Mission System (5 functions)**
19. `proposeMission(string memory _description, uint256 _rewardEnergy, uint256 _rewardReputation, bytes32[] memory _requiredSkills)`: Allows users or DAOs to propose new missions for ADBs to undertake.
20. `approveMission(uint256 _missionId)`: (Governance-only) Approves a proposed mission, making it available for ADBs to accept.
21. `acceptMission(uint256 _adbId, uint256 _missionId)`: (ADB Owner-only) Allows an ADB owner to accept an approved mission for their ADB, provided it meets skill requirements.
22. `completeMission(uint256 _missionId, uint256 _adbId)`: (Oracle-only) Confirms mission completion by an ADB and awards the specified rewards (energy, reputation).
23. `abandonMission(uint256 _adbId, uint256 _missionId)`: (ADB Owner-only) Allows an ADB owner to abandon an active mission.

**VI. Reputation & Governance Hooks / View Functions (6 functions)**
24. `getADBDetails(uint256 _adbId)`: Retrieves core details of an ADB: name, owner, birth time, energy, reputation, and current mission ID.
25. `getADBAttributes(uint256 _adbId)`: Retrieves all dynamic attributes (name, value, category, AI mutability) of a specific ADB.
26. `getADBReputation(uint256 _adbId)`: Returns the total reputation score of an ADB.
27. `getADBLearnedSkills(uint256 _adbId, string[] memory _skillNames)`: Checks and returns which of the provided skills an ADB has learned.
28. `getMissionDetails(uint256 _missionId)`: Retrieves comprehensive details about a specific mission.
29. `getAIPromptDetails(uint256 _promptId)`: Retrieves comprehensive details about a specific AI prompt.
30. `tokenURI(uint256 tokenId)`: (Inherited from ERC721, overridden) Dynamically generates the JSON metadata URI for an ADB based on its current on-chain state, enabling dynamic NFT visuals/descriptions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AdaptiveDigitalBeingCore
 * @dev A novel smart contract that manages unique, dynamic, and evolving non-fungible digital beings (ADBs).
 *      ADBs are NFTs whose attributes, skills, and reputation dynamically evolve based on on-chain interactions,
 *      community-driven AI prompts, and verifiable off-chain data.
 *      It integrates concepts of dynamic NFTs, on-chain reputation, AI coordination, and mission systems.
 *      This contract is designed to be an advanced, creative, and non-duplicated solution in the blockchain space.
 */
contract AdaptiveDigitalBeingCore is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /* ========== OUTLINE & FUNCTION SUMMARY ========== */

    // I. Core Data Structures & State Variables
    //    - ADB: Represents a single Adaptive Digital Being (NFT).
    //    - Attribute: A mutable characteristic of an ADB.
    //    - Skill: A learnable capability for an ADB.
    //    - Mission: A task proposed for ADBs to complete.
    //    - AIPrompt: A user-submitted instruction for AI to influence an ADB.
    //    - Enums: Status indicators for missions and AI prompts.

    // II. Admin & Initialization Functions (7 functions)
    //    - constructor: Deploys the contract, setting initial owner and name.
    //    - setGovernanceAddress: Sets the address authorized for governance actions (e.g., approving prompts/missions).
    //    - setOracleAddress: Sets the address authorized for submitting verifiable off-chain results (AI output, mission completion).
    //    - setEnergyReplenishCost: Adjusts the cost to replenish an ADB's energy.
    //    - setSkillLearningCost: Adjusts the cost (in energy/reputation) to learn skills.
    //    - addInitialAttributeTemplate: Defines new attribute types that ADBs can possess.
    //    - addSkillTemplate: Defines new skills that ADBs can learn.

    // III. ADB Creation & Management (3 functions)
    //    - mintADB: Mints a new unique Adaptive Digital Being NFT.
    //    - updateADBName: Allows an ADB owner to change their ADB's name (limited).
    //    - transferFrom / safeTransferFrom: Standard ERC721 transfers (inherits from ERC721).

    // IV. Dynamic Evolution & Interaction (8 functions)
    //    - replenishADBEnergy: Allows any user to add "energy" to a specific ADB.
    //    - interactWithADB: A generic interaction that consumes energy and grants reputation.
    //    - learnSkill: Allows an ADB owner to initiate their ADB learning a new skill.
    //    - activateSkillEffect: Triggers a skill's on-chain effect (conceptual, requires specific skill logic).
    //    - delegateReputation: Allows users to delegate their reputation points to an ADB, boosting its influence.
    //    - revokeReputationDelegation: Allows users to revoke previously delegated reputation.
    //    - proposeAIPrompt: Users submit natural language prompts for AI to influence an ADB's attributes.
    //    - fulfillAIPromptResult: Oracle callback to apply AI-driven attribute changes to an ADB.

    // V. Mission System (5 functions)
    //    - proposeMission: Users or DAOs can propose new missions for ADBs.
    //    - approveMission: Governance approves a mission, making it available.
    //    - acceptMission: An ADB owner accepts an approved mission for their ADB.
    //    - completeMission: Oracle confirms mission completion, rewards ADB.
    //    - abandonMission: An ADB owner can abandon an active mission.

    // VI. Reputation & Governance Hooks / View Functions (6 functions)
    //    - getADBDetails: Retrieves all core details of an ADB.
    //    - getADBAttributes: Retrieves all dynamic attributes of an ADB.
    //    - getADBReputation: Gets the total reputation of an ADB.
    //    - getADBLearnedSkills: Checks if an ADB has learned specific skills.
    //    - getMissionDetails: Retrieves details of a specific mission.
    //    - getAIPromptDetails: Retrieves details of a specific AI prompt.
    //    - tokenURI: Overridden function to dynamically generate NFT metadata.

    /* ========== STATE VARIABLES ========== */

    // Counters for unique IDs
    Counters.Counter private _adbIds;
    Counters.Counter private _missionIds;
    Counters.Counter private _aiPromptIds;

    // Address for governance actions (e.g., DAO or multisig)
    address public governanceAddress;
    // Address for oracle submissions (e.g., Chainlink, custom off-chain relayer)
    address public oracleAddress;

    // --- ADB Specifics ---
    struct ADB {
        uint256 id;
        string name;
        uint256 birthTime; // Timestamp of minting
        uint256 energy; // Resource consumed for actions
        uint256 reputation; // Accumulated standing/influence
        mapping(bytes32 => Attribute) attributes; // Dynamic traits, e.g., "empathy", "logic"
        bytes32[] attributeHashes; // To allow iteration of attributes
        mapping(bytes32 => bool) learnedSkills; // Skills acquired by the ADB
        uint256 currentMissionId; // 0 if no active mission
        mapping(uint256 => bool) completedMissions; // Tracks completed missions
        mapping(address => uint256) delegatedReputation; // Amount of reputation delegated by a user to this ADB
    }
    mapping(uint256 => ADB) public adbs; // ADB storage by ID

    struct Attribute {
        string name;
        uint256 value; // Typically 0-100 scale
        string category; // e.g., "Cognitive", "Social", "Physical"
        bool mutableByAI; // Can this attribute be directly influenced by AI prompts?
    }
    // No direct mapping for attribute templates; they are added directly to ADBs on minting for simplicity.
    // For `addInitialAttributeTemplate` to be useful, it implies there's a global registry to pull from.
    // Let's refine this: `attributeTemplates` should store global templates that `mintADB` can pull from.
    mapping(bytes32 => Attribute) public globalAttributeTemplates; // Templates for base attributes (attrNameHash => Attribute)

    struct Skill {
        bytes32 id; // keccak256(name)
        string name;
        string description;
        uint256 energyCost; // Cost to learn this skill
        uint256 reputationCost; // Reputation required to learn
        bytes32[] prerequisiteSkills; // Other skills required before learning this one
    }
    mapping(bytes32 => Skill) public skillTemplates; // Templates for skills (skillNameHash => Skill)

    // --- Mission Specifics ---
    struct Mission {
        uint256 id;
        address proposer;
        string description;
        uint256 rewardEnergy;
        uint256 rewardReputation;
        bytes32[] requiredSkills; // Skills an ADB needs to accept this mission
        MissionStatus status;
    }
    mapping(uint252 => Mission) public missions; // Mission storage by ID

    enum MissionStatus { Proposed, Approved, Active, Completed, Abandoned }

    // --- AI Prompt Specifics ---
    struct AIPrompt {
        uint256 id;
        address proposer;
        uint256 adbId; // The ADB targeted by this prompt
        string promptText; // Natural language prompt for the AI
        AIPromptStatus status;
        uint256 submissionTime;
        // Mapping of attributeNameHash => newValue is for the proposer's expectation/governance review.
        // The oracle's output will be authoritative.
    }
    mapping(uint256 => AIPrompt) public aiPrompts; // AI Prompt storage by ID

    enum AIPromptStatus { Proposed, Approved, Executed, Rejected }

    // --- Economic Parameters ---
    uint256 public energyReplenishCost = 0.01 ether; // Cost in ETH to replenish 100 energy (example)
    uint256 public skillLearningBaseCost = 0.05 ether; // Base cost for learning a skill in ETH

    /* ========== EVENTS ========== */

    event ADBMinted(uint256 indexed adbId, address indexed owner, string name, uint256 birthTime);
    event ADBEnergyReplenished(uint256 indexed adbId, address indexed replenisher, uint256 amount);
    event ADBInteracted(uint256 indexed adbId, address indexed interactor, uint256 energyConsumed, uint256 reputationGained);
    event ADBSkillLearned(uint256 indexed adbId, bytes32 indexed skillId);
    event ReputationDelegated(uint256 indexed adbId, address indexed delegator, uint256 amount);
    event ReputationDelegationRevoked(uint256 indexed adbId, address indexed delegator, uint256 amount);
    event AIPromptProposed(uint256 indexed promptId, uint256 indexed adbId, address indexed proposer, string promptText);
    event AIPromptApproved(uint256 indexed promptId, address indexed approver);
    event AIPromptExecutedDetailed(uint256 indexed promptId, uint256 indexed adbId, bytes32[] attributeNames, uint256[] newValues);
    event MissionProposed(uint256 indexed missionId, address indexed proposer, string description);
    event MissionApproved(uint256 indexed missionId, address indexed approver);
    event MissionAccepted(uint256 indexed missionId, uint256 indexed adbId);
    event MissionCompleted(uint256 indexed missionId, uint256 indexed adbId, uint256 rewardEnergy, uint256 rewardReputation);
    event MissionAbandoned(uint274 indexed missionId, uint256 indexed adbId);
    event ADBNameUpdated(uint256 indexed adbId, string newName);

    /* ========== MODIFIERS ========== */

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "ADB: Not governance address");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ADB: Not oracle address");
        _;
    }

    modifier onlyADBOwner(uint256 _adbId) {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(ownerOf(_adbId) == msg.sender, "ADB: Not ADB owner");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Initially set governance and oracle to deployer, can be changed later
        governanceAddress = msg.sender;
        oracleAddress = msg.sender;
    }

    /* ========== ADMIN & INITIALIZATION FUNCTIONS ========== */

    /**
     * @dev Sets the address designated for governance actions.
     * @param _governanceAddress The new governance address.
     */
    function setGovernanceAddress(address _governanceAddress) public onlyOwner {
        require(_governanceAddress != address(0), "ADB: Zero address for governance");
        governanceAddress = _governanceAddress;
    }

    /**
     * @dev Sets the address designated for oracle submissions (e.g., AI results, mission completions).
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ADB: Zero address for oracle");
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Adjusts the cost in ETH to replenish an ADB's energy.
     * @param _newCost The new cost in wei.
     */
    function setEnergyReplenishCost(uint256 _newCost) public onlyOwner {
        energyReplenishCost = _newCost;
    }

    /**
     * @dev Adjusts the base cost in ETH for an ADB to learn a new skill.
     * @param _newCost The new base cost in wei.
     */
    function setSkillLearningCost(uint256 _newCost) public onlyOwner {
        skillLearningBaseCost = _newCost;
    }

    /**
     * @dev Adds a new attribute template that ADBs can possess globally.
     *      ADBs minted thereafter can inherit these attributes.
     * @param _name The name of the attribute (e.g., "Empathy").
     * @param _category The category of the attribute (e.g., "Cognitive").
     * @param _mutableByAI Whether this attribute can be directly influenced by AI prompts.
     */
    function addInitialAttributeTemplate(string memory _name, string memory _category, bool _mutableByAI) public onlyOwner {
        bytes32 attrHash = keccak256(abi.encodePacked(_name));
        require(globalAttributeTemplates[attrHash].name.length == 0, "ADB: Attribute template already exists");
        globalAttributeTemplates[attrHash] = Attribute(_name, 0, _category, _mutableByAI); // Initial value in template is 0
    }

    /**
     * @dev Adds a new skill template that ADBs can learn.
     *      Only callable by the contract owner.
     * @param _name The name of the skill.
     * @param _description A description of the skill.
     * @param _energyCost The energy required to learn this skill.
     * @param _reputationCost The reputation required to learn this skill.
     * @param _prerequisiteSkills Array of hashes of skills that must be learned first.
     */
    function addSkillTemplate(
        string memory _name,
        string memory _description,
        uint256 _energyCost,
        uint256 _reputationCost,
        bytes32[] memory _prerequisiteSkills
    ) public onlyOwner {
        bytes32 skillHash = keccak256(abi.encodePacked(_name));
        require(skillTemplates[skillHash].name.length == 0, "ADB: Skill template already exists");
        skillTemplates[skillHash] = Skill(skillHash, _name, _description, _energyCost, _reputationCost, _prerequisiteSkills);
    }

    /* ========== ADB CREATION & MANAGEMENT FUNCTIONS ========== */

    /**
     * @dev Mints a new Adaptive Digital Being (ADB) NFT.
     *      Each ADB comes with initial energy and reputation.
     *      Initial attributes are copied from globally defined templates.
     * @param _to The address to mint the ADB to.
     * @param _name The initial name of the ADB.
     */
    function mintADB(address _to, string memory _name) public {
        _adbIds.increment();
        uint256 newId = _adbIds.current();

        _safeMint(_to, newId);

        ADB storage newADB = adbs[newId];
        newADB.id = newId;
        newADB.name = _name;
        newADB.birthTime = block.timestamp;
        newADB.energy = 100; // Initial energy
        newADB.reputation = 0; // Initial reputation

        // Initialize attributes from templates (iterates global templates and copies to ADB)
        // In a production system, this may need optimization if there are many templates.
        bytes32[] memory templateKeys = new bytes32[](0); // This would typically be a dynamic array of known keys or a helper function.
        // For this example, let's assume we previously called `addInitialAttributeTemplate` for "Empathy", "Logic", "Creativity".
        // To iterate over `globalAttributeTemplates` for *all* attributes, a separate list of keys would be needed.
        // For demonstration, we'll manually add common ones as if they were globally defined and then assigned.

        bytes32 empathyHash = keccak256(abi.encodePacked("Empathy"));
        if (globalAttributeTemplates[empathyHash].name.length > 0) {
            newADB.attributes[empathyHash] = globalAttributeTemplates[empathyHash];
            newADB.attributes[empathyHash].value = 50; // Set initial value for new ADB
            newADB.attributeHashes.push(empathyHash);
        }
        bytes32 logicHash = keccak256(abi.encodePacked("Logic"));
        if (globalAttributeTemplates[logicHash].name.length > 0) {
            newADB.attributes[logicHash] = globalAttributeTemplates[logicHash];
            newADB.attributes[logicHash].value = 50;
            newADB.attributeHashes.push(logicHash);
        }
        bytes32 creativityHash = keccak256(abi.encodePacked("Creativity"));
        if (globalAttributeTemplates[creativityHash].name.length > 0) {
            newADB.attributes[creativityHash] = globalAttributeTemplates[creativityHash];
            newADB.attributes[creativityHash].value = 50;
            newADB.attributeHashes.push(creativityHash);
        }
        bytes32 agilityHash = keccak256(abi.encodePacked("Agility"));
        if (globalAttributeTemplates[agilityHash].name.length > 0) {
            newADB.attributes[agilityHash] = globalAttributeTemplates[agilityHash];
            newADB.attributes[agilityHash].value = 50;
            newADB.attributeHashes.push(agilityHash);
        }

        emit ADBMinted(newId, _to, _name, block.timestamp);
    }

    /**
     * @dev Allows the ADB owner to update their ADB's name.
     * @param _adbId The ID of the ADB.
     * @param _newName The new name for the ADB.
     */
    function updateADBName(uint256 _adbId, string memory _newName) public onlyADBOwner(_adbId) {
        require(bytes(_newName).length > 0, "ADB: Name cannot be empty");
        adbs[_adbId].name = _newName;
        emit ADBNameUpdated(_adbId, _newName);
    }

    /* ========== DYNAMIC EVOLUTION & INTERACTION FUNCTIONS ========== */

    /**
     * @dev Allows any user to replenish an ADB's energy by sending ETH.
     * @param _adbId The ID of the ADB to replenish.
     */
    function replenishADBEnergy(uint256 _adbId) public payable {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(msg.value >= energyReplenishCost, "ADB: Insufficient ETH to replenish energy");

        uint256 amount = (msg.value / energyReplenishCost) * 100; // 100 energy per unit cost
        adbs[_adbId].energy += amount;

        // Transfer ETH to contract owner or designated treasury
        payable(owner()).transfer(msg.value);

        emit ADBEnergyReplenished(_adbId, msg.sender, amount);
    }

    /**
     * @dev Generic interaction with an ADB, consuming energy and potentially boosting reputation.
     *      Can be used for daily check-ins, light activities, etc.
     * @param _adbId The ID of the ADB to interact with.
     * @param _energyCost The energy consumed by this interaction.
     * @param _reputationGain The reputation gained from this interaction.
     */
    function interactWithADB(uint256 _adbId, uint256 _energyCost, uint256 _reputationGain) public {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(adbs[_adbId].energy >= _energyCost, "ADB: Not enough energy for interaction");

        adbs[_adbId].energy -= _energyCost;
        adbs[_adbId].reputation += _reputationGain;

        emit ADBInteracted(_adbId, msg.sender, _energyCost, _reputationGain);
    }

    /**
     * @dev Allows an ADB owner to initiate their ADB learning a new skill.
     *      Requires sufficient energy, reputation, and prerequisite skills.
     * @param _adbId The ID of the ADB.
     * @param _skillName The name of the skill to learn.
     */
    function learnSkill(uint256 _adbId, string memory _skillName) public onlyADBOwner(_adbId) {
        bytes32 skillHash = keccak256(abi.encodePacked(_skillName));
        Skill storage skillTemplate = skillTemplates[skillHash];
        require(skillTemplate.name.length > 0, "ADB: Skill does not exist");
        require(!adbs[_adbId].learnedSkills[skillHash], "ADB: Skill already learned");
        require(adbs[_adbId].energy >= skillTemplate.energyCost, "ADB: Not enough energy to learn skill");
        require(adbs[_adbId].reputation >= skillTemplate.reputationCost, "ADB: Not enough reputation to learn skill");

        // Check prerequisites
        for (uint256 i = 0; i < skillTemplate.prerequisiteSkills.length; i++) {
            require(adbs[_adbId].learnedSkills[skillTemplate.prerequisiteSkills[i]], "ADB: Prerequisite skill not learned");
        }

        adbs[_adbId].energy -= skillTemplate.energyCost;
        adbs[_adbId].learnedSkills[skillHash] = true;

        // A small ETH cost to learn skill, transferred to contract owner
        payable(owner()).transfer(skillLearningBaseCost);

        emit ADBSkillLearned(_adbId, skillHash);
    }

    /**
     * @dev Conceptually activates a skill's effect.
     *      The actual "effect" might involve complex logic, interactions with other contracts,
     *      or simply consume more energy/reputation for a temporary buff/ability.
     *      This is a placeholder for future complex skill integrations.
     * @param _adbId The ID of the ADB.
     * @param _skillName The name of the skill to activate.
     */
    function activateSkillEffect(uint256 _adbId, string memory _skillName) public onlyADBOwner(_adbId) {
        bytes32 skillHash = keccak256(abi.encodePacked(_skillName));
        require(adbs[_adbId].learnedSkills[skillHash], "ADB: Skill not learned by this ADB");
        Skill storage skillTemplate = skillTemplates[skillHash];

        // Example: Activating a skill consumes extra energy
        uint256 activationEnergyCost = skillTemplate.energyCost / 2; // Half the learning cost
        require(adbs[_adbId].energy >= activationEnergyCost, "ADB: Not enough energy to activate skill");
        adbs[_adbId].energy -= activationEnergyCost;

        // Implement specific skill effects here. This could trigger external contract calls,
        // temporary attribute boosts, or other game-theoretic outcomes.
        // For this example, we'll just log the activation.
        // e.g., adbs[_adbId].attributes[keccak256(abi.encodePacked("Agility"))].value += 10; (temporary boost)

        emit ADBInteracted(_adbId, msg.sender, activationEnergyCost, 0); // Reusing event for energy consumption
    }

    /**
     * @dev Allows a user to delegate their reputation points to an ADB, increasing its influence.
     *      This is a form of liquid democracy or indirect support.
     * @param _adbId The ID of the ADB to delegate reputation to.
     * @param _amount The amount of reputation to delegate.
     */
    function delegateReputation(uint256 _adbId, uint256 _amount) public {
        require(_exists(_adbId), "ADB: ADB does not exist");
        // In a more complete system, the delegator would need to have reputation points.
        // For simplicity here, we assume reputation is generated or comes from an external source.
        adbs[_adbId].reputation += _amount;
        adbs[_adbId].delegatedReputation[msg.sender] += _amount;

        emit ReputationDelegated(_adbId, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to revoke previously delegated reputation from an ADB.
     * @param _adbId The ID of the ADB.
     * @param _amount The amount of reputation to revoke.
     */
    function revokeReputationDelegation(uint256 _adbId, uint256 _amount) public {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(adbs[_adbId].delegatedReputation[msg.sender] >= _amount, "ADB: Not enough delegated reputation to revoke");

        adbs[_adbId].reputation -= _amount;
        adbs[_adbId].delegatedReputation[msg.sender] -= _amount;

        emit ReputationDelegationRevoked(_adbId, msg.sender, _amount);
    }

    /**
     * @dev Allows any user to propose an AI prompt to influence an ADB's attributes.
     *      These prompts need to be approved by governance before off-chain execution.
     * @param _adbId The ID of the targeted ADB.
     * @param _promptText The natural language prompt for the AI.
     * @param _attributeNameHashes A list of (attributeNameHash, newValue) pairs the prompt aims to affect.
     *      This is for tracking and governance review; the oracle's output will be authoritative.
     * @param _newValues The corresponding new values for the attributes mentioned in _attributeNameHashes.
     */
    function proposeAIPrompt(
        uint256 _adbId,
        string memory _promptText,
        bytes32[] memory _attributeNameHashes,
        uint256[] memory _newValues
    ) public {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(bytes(_promptText).length > 0, "ADB: Prompt text cannot be empty");
        require(_attributeNameHashes.length == _newValues.length, "ADB: Mismatched attribute changes");

        _aiPromptIds.increment();
        uint256 newPromptId = _aiPromptIds.current();

        AIPrompt storage newPrompt = aiPrompts[newPromptId];
        newPrompt.id = newPromptId;
        newPrompt.proposer = msg.sender;
        newPrompt.adbId = _adbId;
        newPrompt.promptText = _promptText;
        newPrompt.status = AIPromptStatus.Proposed;
        newPrompt.submissionTime = block.timestamp;

        // Note: The `proposedAttributeChanges` mapping is not directly stored in the struct
        // due to mapping-in-struct limitations for public visibility. If needed for on-chain
        // tracking/governance, this would be refactored to an external mapping or skipped.
        // For this example, we just store the prompt text and let the oracle return the actual changes.
        for (uint256 i = 0; i < _attributeNameHashes.length; i++) {
            // Validate that the attribute template exists, but don't store values directly in prompt
            require(globalAttributeTemplates[_attributeNameHashes[i]].name.length > 0, "ADB: Invalid attribute hash in proposed changes");
        }


        emit AIPromptProposed(newPromptId, _adbId, msg.sender, _promptText);
    }

    /**
     * @dev Governance approves a proposed AI prompt, making it eligible for off-chain execution.
     * @param _promptId The ID of the AI prompt to approve.
     */
    function approveAIPrompt(uint256 _promptId) public onlyGovernance {
        require(aiPrompts[_promptId].id != 0, "ADB: Prompt does not exist");
        require(aiPrompts[_promptId].status == AIPromptStatus.Proposed, "ADB: Prompt not in Proposed status");
        aiPrompts[_promptId].status = AIPromptStatus.Approved;
        emit AIPromptApproved(_promptId, msg.sender);
        // At this point, an off-chain oracle service would pick up the approved prompt
        // and execute the AI model, then call `fulfillAIPromptResult`.
    }

    /**
     * @dev Oracle callback to fulfill an AI prompt and update an ADB's attributes.
     *      This function is called by the trusted oracle after AI computation.
     * @param _promptId The ID of the prompt being fulfilled.
     * @param _adbId The ID of the ADB whose attributes are being updated.
     * @param _attributeNames Hashes of attributes being changed.
     * @param _newValues New values for the corresponding attributes.
     */
    function fulfillAIPromptResult(
        uint256 _promptId,
        uint256 _adbId,
        bytes32[] memory _attributeNames,
        uint256[] memory _newValues
    ) public onlyOracle {
        AIPrompt storage prompt = aiPrompts[_promptId];
        require(prompt.id != 0, "ADB: Prompt does not exist");
        require(prompt.status == AIPromptStatus.Approved, "ADB: Prompt not approved for execution");
        require(prompt.adbId == _adbId, "ADB: Prompt ADB ID mismatch");
        require(_attributeNames.length == _newValues.length, "ADB: Mismatched attribute data");

        ADB storage targetADB = adbs[_adbId];
        bytes32[] memory changedNames = new bytes32[](_attributeNames.length);
        uint256[] memory changedValues = new uint256[](_newValues.length);

        for (uint256 i = 0; i < _attributeNames.length; i++) {
            bytes32 attrHash = _attributeNames[i];
            uint256 newValue = _newValues[i];

            require(targetADB.attributes[attrHash].name.length > 0, "ADB: Invalid attribute name provided by oracle");
            require(targetADB.attributes[attrHash].mutableByAI, "ADB: Attribute not mutable by AI");

            // Cap value to 100
            targetADB.attributes[attrHash].value = newValue > 100 ? 100 : newValue;
            changedNames[i] = attrHash;
            changedValues[i] = targetADB.attributes[attrHash].value; // Store actual applied value
        }

        prompt.status = AIPromptStatus.Executed;
        emit AIPromptExecutedDetailed(_promptId, _adbId, changedNames, changedValues);
    }

    /* ========== MISSION SYSTEM FUNCTIONS ========== */

    /**
     * @dev Allows users or DAOs to propose new missions for ADBs to undertake.
     * @param _description Description of the mission.
     * @param _rewardEnergy Energy awarded upon completion.
     * @param _rewardReputation Reputation awarded upon completion.
     * @param _requiredSkills Skills an ADB must have to accept this mission.
     */
    function proposeMission(
        string memory _description,
        uint256 _rewardEnergy,
        uint256 _rewardReputation,
        bytes32[] memory _requiredSkills
    ) public {
        _missionIds.increment();
        uint256 newMissionId = _missionIds.current();

        Mission storage newMission = missions[newMissionId];
        newMission.id = newMissionId;
        newMission.proposer = msg.sender;
        newMission.description = _description;
        newMission.rewardEnergy = _rewardEnergy;
        newMission.rewardReputation = _rewardReputation;
        newMission.requiredSkills = _requiredSkills; // Storing the list of required skill hashes
        newMission.status = MissionStatus.Proposed;

        emit MissionProposed(newMissionId, msg.sender, _description);
    }

    /**
     * @dev Governance approves a proposed mission, making it available for ADBs to accept.
     * @param _missionId The ID of the mission to approve.
     */
    function approveMission(uint256 _missionId) public onlyGovernance {
        require(missions[_missionId].id != 0, "ADB: Mission does not exist");
        require(missions[_missionId].status == MissionStatus.Proposed, "ADB: Mission not in Proposed status");
        missions[_missionId].status = MissionStatus.Approved;
        emit MissionApproved(_missionId, msg.sender);
    }

    /**
     * @dev Allows an ADB owner to accept an approved mission for their ADB.
     *      An ADB can only have one active mission at a time.
     * @param _adbId The ID of the ADB.
     * @param _missionId The ID of the mission to accept.
     */
    function acceptMission(uint256 _adbId, uint256 _missionId) public onlyADBOwner(_adbId) {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(missions[_missionId].id != 0, "ADB: Mission does not exist");
        require(missions[_missionId].status == MissionStatus.Approved, "ADB: Mission not approved");
        require(adbs[_adbId].currentMissionId == 0, "ADB: ADB already has an active mission");

        // Check if ADB has all required skills for the mission
        for (uint256 i = 0; i < missions[_missionId].requiredSkills.length; i++) {
            require(adbs[_adbId].learnedSkills[missions[_missionId].requiredSkills[i]], "ADB: Missing required skill for mission");
        }

        adbs[_adbId].currentMissionId = _missionId;
        missions[_missionId].status = MissionStatus.Active;
        emit MissionAccepted(_missionId, _adbId);
    }

    /**
     * @dev Oracle callback to confirm mission completion and award rewards to the ADB.
     * @param _missionId The ID of the mission completed.
     * @param _adbId The ID of the ADB that completed the mission.
     */
    function completeMission(uint256 _missionId, uint256 _adbId) public onlyOracle {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(missions[_missionId].id != 0, "ADB: Mission does not exist");
        require(missions[_missionId].status == MissionStatus.Active, "ADB: Mission not active");
        require(adbs[_adbId].currentMissionId == _missionId, "ADB: ADB is not on this mission");

        adbs[_adbId].energy += missions[_missionId].rewardEnergy;
        adbs[_adbId].reputation += missions[_missionId].rewardReputation;
        adbs[_adbId].currentMissionId = 0; // Clear active mission
        adbs[_adbId].completedMissions[_missionId] = true;
        missions[_missionId].status = MissionStatus.Completed;

        emit MissionCompleted(_missionId, _adbId, missions[_missionId].rewardEnergy, missions[_missionId].rewardReputation);
    }

    /**
     * @dev Allows an ADB owner to abandon an active mission.
     * @param _adbId The ID of the ADB.
     * @param _missionId The ID of the mission to abandon.
     */
    function abandonMission(uint256 _adbId, uint256 _missionId) public onlyADBOwner(_adbId) {
        require(_exists(_adbId), "ADB: ADB does not exist");
        require(adbs[_adbId].currentMissionId == _missionId, "ADB: ADB is not on this mission");
        require(missions[_missionId].status == MissionStatus.Active, "ADB: Mission not active");

        adbs[_adbId].currentMissionId = 0; // Clear active mission
        missions[_missionId].status = MissionStatus.Abandoned;

        emit MissionAbandoned(_missionId, _adbId);
    }

    /* ========== REPUTATION & GOVERNANCE HOOKS / VIEW FUNCTIONS ========== */

    /**
     * @dev Retrieves core details of an Adaptive Digital Being.
     * @param _adbId The ID of the ADB.
     * @return name The name of the ADB.
     * @return owner The owner address of the ADB.
     * @return birthTime The timestamp of minting.
     * @return energy Current energy level.
     * @return reputation Current reputation score.
     * @return currentMissionId The ID of the currently active mission (0 if none).
     */
    function getADBDetails(uint256 _adbId) public view returns (
        string memory name,
        address adbOwner,
        uint256 birthTime,
        uint256 energy,
        uint256 reputation,
        uint256 currentMissionId
    ) {
        require(_exists(_adbId), "ADB: ADB does not exist");
        ADB storage adb = adbs[_adbId];
        return (adb.name, ownerOf(_adbId), adb.birthTime, adb.energy, adb.reputation, adb.currentMissionId);
    }

    /**
     * @dev Retrieves all dynamic attributes of an ADB.
     *      Due to mapping iteration limitations, this relies on `attributeHashes` array.
     * @param _adbId The ID of the ADB.
     * @return attributeNames Array of attribute names.
     * @return attributeValues Array of attribute values.
     * @return attributeCategories Array of attribute categories.
     * @return attributeMutableByAI Array indicating if attribute is mutable by AI.
     */
    function getADBAttributes(uint256 _adbId) public view returns (
        string[] memory attributeNames,
        uint256[] memory attributeValues,
        string[] memory attributeCategories,
        bool[] memory attributeMutableByAI
    ) {
        require(_exists(_adbId), "ADB: ADB does not exist");
        ADB storage adb = adbs[_adbId];

        uint256 count = adb.attributeHashes.length;
        attributeNames = new string[](count);
        attributeValues = new uint256[](count);
        attributeCategories = new string[](count);
        attributeMutableByAI = new bool[](count);

        for (uint256 i = 0; i < count; i++) {
            bytes32 attrHash = adb.attributeHashes[i];
            Attribute storage attr = adb.attributes[attrHash];
            attributeNames[i] = attr.name;
            attributeValues[i] = attr.value;
            attributeCategories[i] = attr.category;
            attributeMutableByAI[i] = attr.mutableByAI;
        }
        return (attributeNames, attributeValues, attributeCategories, attributeMutableByAI);
    }

    /**
     * @dev Gets the total reputation of an ADB.
     * @param _adbId The ID of the ADB.
     * @return The total reputation score.
     */
    function getADBReputation(uint256 _adbId) public view returns (uint256) {
        require(_exists(_adbId), "ADB: ADB does not exist");
        return adbs[_adbId].reputation;
    }

    /**
     * @dev Checks if an ADB has learned specific skills.
     * @param _adbId The ID of the ADB.
     * @param _skillNames Array of skill names to check.
     * @return Array of booleans, true if the ADB has learned the corresponding skill.
     */
    function getADBLearnedSkills(uint256 _adbId, string[] memory _skillNames) public view returns (bool[] memory) {
        require(_exists(_adbId), "ADB: ADB does not exist");
        bool[] memory learned = new bool[](_skillNames.length);
        for (uint256 i = 0; i < _skillNames.length; i++) {
            learned[i] = adbs[_adbId].learnedSkills[keccak256(abi.encodePacked(_skillNames[i]))];
        }
        return learned;
    }

    /**
     * @dev Retrieves details of a specific mission.
     * @param _missionId The ID of the mission.
     * @return proposer Address of the mission proposer.
     * @return description Mission description.
     * @return rewardEnergy Energy reward.
     * @return rewardReputation Reputation reward.
     * @return status Current status of the mission.
     * @return requiredSkillsHashes Hashes of skills required to accept this mission.
     */
    function getMissionDetails(uint256 _missionId) public view returns (
        address proposer,
        string memory description,
        uint256 rewardEnergy,
        uint256 rewardReputation,
        MissionStatus status,
        bytes32[] memory requiredSkillsHashes
    ) {
        require(missions[_missionId].id != 0, "ADB: Mission does not exist");
        Mission storage mission = missions[_missionId];
        return (
            mission.proposer,
            mission.description,
            mission.rewardEnergy,
            mission.rewardReputation,
            mission.status,
            mission.requiredSkills
        );
    }

    /**
     * @dev Retrieves details of a specific AI prompt.
     * @param _promptId The ID of the AI prompt.
     * @return proposer Address of the prompt proposer.
     * @return adbId The ID of the targeted ADB.
     * @return promptText The natural language prompt.
     * @return status Current status of the prompt.
     * @return submissionTime Timestamp of prompt submission.
     */
    function getAIPromptDetails(uint256 _promptId) public view returns (
        address proposer,
        uint256 adbId,
        string memory promptText,
        AIPromptStatus status,
        uint256 submissionTime
    ) {
        require(aiPrompts[_promptId].id != 0, "ADB: AI Prompt does not exist");
        AIPrompt storage prompt = aiPrompts[_promptId];
        return (
            prompt.proposer,
            prompt.adbId,
            prompt.promptText,
            prompt.status,
            prompt.submissionTime
        );
    }

    /**
     * @dev Overridden function to dynamically generate the JSON metadata URI for an ADB.
     *      This is a crucial part of Dynamic NFTs, reflecting on-chain state changes.
     *      Note: Building complex JSON on-chain can be gas-intensive. For production,
     *      a dedicated off-chain metadata service or IPFS-backed data URI is often preferred,
     *      where the contract only stores the base URI and the service assembles the full JSON.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        ADB storage adb = adbs[tokenId];

        string memory name = adb.name;
        string memory description = string.concat(
            "An Adaptive Digital Being (ADB) with evolving attributes and skills. Birth Time: ",
            adb.birthTime.toString(),
            ", Current Mission: ",
            adb.currentMissionId > 0 ? adb.currentMissionId.toString() : "None"
        );

        // Placeholder for image, could dynamically change based on attributes or learned skills
        string memory image = "ipfs://QmbzT3vKx.../default_adb.png"; // Replace with actual IPFS CID

        string memory attributesJson = "";
        for (uint256 i = 0; i < adb.attributeHashes.length; i++) {
            bytes32 attrHash = adb.attributeHashes[i];
            Attribute storage attr = adb.attributes[attrHash];
            attributesJson = string.concat(attributesJson,
                '{"trait_type": "', attr.name, '", "value": ', attr.value.toString(), '},'
            );
        }
        // Add core stats as attributes too
        attributesJson = string.concat(attributesJson,
            '{"trait_type": "Energy", "value": ', adb.energy.toString(), '},',
            '{"trait_type": "Reputation", "value": ', adb.reputation.toString(), '}'
        );
        // Remove trailing comma if any (simple approach for this example)
        if (bytes(attributesJson).length > 0 && attributesJson[bytes(attributesJson).length - 1] == ',') {
            attributesJson = attributesJson[0:bytes(attributesJson).length - 1];
        }

        string memory json = string(
            abi.encodePacked(
                '{"name":"', name,
                '", "description":"', description,
                '", "image":"', image,
                '", "attributes": [', attributesJson, ']}'
            )
        );

        // Encode to Base64 for data URI
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
    }
}

// Minimal Base64 library for data URI. Not suitable for very large strings due to gas.
// For dynamic NFTs, usually an off-chain server or Chainlink Functions would serve the metadata.
library Base64 {
    string internal constant ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen);
        bytes memory table = bytes(ALPHABET);

        uint256 dataIdx = 0;
        uint256 resultIdx = 0;
        while (dataIdx < data.length) {
            uint256 val = 0;
            uint256 numBytes = 0;
            for (uint256 i = 0; i < 3; i++) {
                if (dataIdx < data.length) {
                    val = (val << 8) | uint8(data[dataIdx]);
                    numBytes++;
                    dataIdx++;
                } else {
                    val <<= 8;
                }
            }

            result[resultIdx++] = table[(val >> 18) & 0x3F];
            result[resultIdx++] = table[(val >> 12) & 0x3F];
            result[resultIdx++] = table[(val >> 6) & 0x3F];
            result[resultIdx++] = table[val & 0x3F];
        }

        // Pad with '=' if necessary
        if (numBytes == 1) {
            result[result.length - 2] = '=';
            result[result.length - 1] = '=';
        } else if (numBytes == 2) {
            result[result.length - 1] = '=';
        }

        return result;
    }
}

```