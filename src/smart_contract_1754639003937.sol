This smart contract, `ArcanumChronicles`, presents a novel ecosystem for **Evolving Digital Personas** (advanced Soulbound Tokens or SBTs) within a **Decentralized Guild System**. It combines concepts of dynamic NFTs, on-chain skill trees, reputation systems, and decentralized autonomous organizations (DAOs) to create a rich and interactive on-chain identity.

The core idea is that users mint a non-transferable "Persona" NFT which then evolves based on their actions, skill acquisition, and participation within various "Guilds." Guilds act as DAOs, proposing initiatives, defining skills, and offering "Quests" that members complete to gain experience and reputation, further influencing their Persona's attributes and dynamic metadata.

---

## ArcanumChronicles Smart Contract

**Outline:**

*   **I. Core Persona (Soulbound NFT) Management & Evolution:**
    *   Represents an evolving, non-transferable digital identity (SBT).
    *   Tracks skills, reputation, and affiliations directly on-chain.
    *   Features a dynamic URI reflecting its current state and progress.
*   **II. Guild & DAO Management:**
    *   Enables creation and management of decentralized organizations (Guilds).
    *   Guilds can define their own domains, propose initiatives, and vote on various actions.
    *   Membership is strictly tied to owning a Persona.
*   **III. Skill & Expertise System:**
    *   Defines and tracks various skills, their hierarchical levels, and prerequisites.
    *   Skill acquisition and leveling up are tied to on-chain activities (e.g., quest completion, contributions).
*   **IV. Questing & Achievements:**
    *   Provides a system for Guilds or central authority to create and manage on-chain quests/challenges.
    *   Facilitates the submission and verification of quest completion, awarding rewards that directly influence Persona evolution.
*   **V. Dynamic Reputation & Interactivity:**
    *   Tracks domain-specific reputation for Personas, allowing for nuanced influence.
    *   Introduces the concept of "Skill Influence Delegation" for expertise-weighted decisions.
    *   Enables inter-Guild alliances, affecting reputation flow and collaborative potential.

---

**Function Summary:**

**I. Core Persona (Soulbound NFT) Management & Evolution:**
1.  `mintPersona()`: Mints a unique, non-transferable Persona NFT (SBT) for the calling address. Each address is limited to one Persona.
2.  `getPersonaIdByOwner()`: Retrieves the Persona ID associated with a given wallet address.
3.  `getPersonaAttributes()`: Provides a comprehensive, current view of a Persona's on-chain attributes (e.g., total skill levels, overall reputation, primary domain).
4.  `getPersonaDynamicURI()`: Generates a dynamic metadata URI for a Persona, where the actual metadata (e.g., visual representation, detailed JSON) is rendered off-chain based on the Persona's evolving on-chain traits.
5.  `calculatePersonaWisdomScore()`: Computes a derived "Wisdom Score" for a Persona, a composite metric reflecting overall accumulated skills, reputation, and longevity within the ecosystem.
6.  `_updatePersonaTrait()`: An internal function used by other contract logic to dynamically update specific, derived traits of a Persona based on on-chain events (e.g., skill level-up, quest completion).

**II. Guild & DAO Management:**
7.  `createGuild()`: Allows a Persona holder to establish a new Guild, specifying its unique name and primary domain of focus (e.g., "Blockchain Dev Guild", "Fantasy Art Collective").
8.  `joinGuild()`: Enables a Persona holder to become a member of an existing Guild.
9.  `leaveGuild()`: Allows a Persona holder to voluntarily exit a Guild.
10. `getGuildDetails()`: Retrieves core information about a specific Guild, including its name, founder, primary domain, and member count.
11. `proposeGuildInitiative()`: Guild members can propose an action or decision within their Guild (e.g., defining a new skill, creating a quest, or deciding on treasury allocation).
12. `voteOnGuildInitiative()`: Members cast their votes on active Guild initiatives. Voting power can be weighted by the Persona's reputation or skill levels relevant to the Guild's primary domain.
13. `executeGuildInitiative()`: Triggers the execution of a Guild initiative once it has passed its voting threshold and the voting period has ended. This function integrates with the data payload of the initiative.

**III. Skill & Expertise System:**
14. `defineSkill()`: Allows the contract owner (or Guild governance via initiative) to define a new skill node, specifying its domain, any prerequisite skills, and its maximum achievable level.
15. `acquireSkillXP()`: Awards experience points (XP) to a Persona for a specific skill. This is typically invoked by a trusted entity after a verified contribution or quest completion.
16. `levelUpSkill()`: Allows a Persona holder to advance a specific skill to the next level once their Persona has accumulated sufficient XP for that skill and met all prerequisites.
17. `getPersonaSkillLevel()`: Retrieves the current level of a specified skill for a given Persona.
18. `checkSkillPrerequisites()`: Verifies if a Persona meets the necessary skill requirements (specific skills at minimum levels) for participating in certain activities or acquiring new skills.

**IV. Questing & Achievements:**
19. `createQuest()`: Enables Guild governance or a central authority to define and publish a new quest, including its name, description, required skills, and rewards (XP and reputation).
20. `submitQuestCompletion()`: Allows a Persona holder to formally submit proof (or a simple flag for on-chain verifiable tasks) that they have completed a quest.
21. `verifyAndAwardQuest()`: An authorized role (e.g., Guild council, designated oracle) verifies a submitted quest completion and awards the specified XP and reputation rewards to the Persona.
22. `getAvailableQuests()`: Provides a list of all quests that are currently active and open for participation across the ecosystem.

**V. Dynamic Reputation & Interactivity:**
23. `_updateDomainReputation()`: An internal function responsible for adjusting a Persona's reputation score within a specific domain (e.g., "Coding", "Art"). This is triggered by quest completions, contributions, or other system events.
24. `getPersonaDomainReputation()`: Retrieves a Persona's current reputation score within a specified domain.
25. `delegateSkillInfluence()`: Allows a Persona holder to temporarily delegate a portion of their skill-based influence or voting weight to another Persona for a defined duration, enabling liquid expertise delegation.
26. `revokeSkillInfluenceDelegation()`: Immediately revokes a previously granted skill influence delegation, allowing the delegator to regain their full influence.
27. `declareGuildAlliance()`: Enables a Guild to formally propose an alliance with another Guild. This requires reciprocal acceptance to be fully established.
28. `acceptGuildAlliance()`: Allows a Guild to acknowledge and finalize an alliance proposal extended by another Guild, forming a mutual alliance.
29. `breakGuildAlliance()`: Provides a mechanism for either party in an alliance to unilaterally terminate the alliance between two Guilds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// I. Core Persona (Soulbound NFT) Management & Evolution (ERC721-based SBT)
//    - Represents an evolving, non-transferable digital identity.
//    - Tracks skills, reputation, and affiliations directly on-chain.
//    - Features a dynamic URI reflecting its current state.
// II. Guild & DAO Management
//    - Enables creation and management of decentralized organizations (Guilds).
//    - Guilds can define their own domains, propose initiatives, and vote.
//    - Membership is tied to owning a Persona.
// III. Skill & Expertise System
//    - Defines and tracks various skills, their levels, and prerequisites.
//    - Skill acquisition and leveling up are tied to on-chain activities (e.g., quests).
// IV. Questing & Achievements
//    - System for Guilds or central authority to create and manage on-chain quests/challenges.
//    - Facilitates submission and verification of quest completion, awarding rewards.
// V. Dynamic Reputation & Interactivity
//    - Tracks domain-specific reputation for Personas.
//    - Allows for advanced delegation of skill influence.
//    - Enables inter-Guild alliances.

// Function Summary:

// I. Core Persona (Soulbound NFT) Management & Evolution:
//    1. mintPersona(): Mints a unique, non-transferable Persona NFT (SBT) for a new user.
//    2. getPersonaIdByOwner(): Returns the Persona ID associated with a wallet address.
//    3. getPersonaAttributes(): Retrieves a comprehensive view of a Persona's on-chain attributes.
//    4. getPersonaDynamicURI(): Generates a dynamic metadata URI for a Persona, reflecting its evolving traits.
//    5. calculatePersonaWisdomScore(): Computes a derived "Wisdom Score" based on a Persona's accumulated skills, reputation, and longevity.
//    6. _updatePersonaTrait(): Internal function to dynamically update specific traits of a Persona.

// II. Guild & DAO Management:
//    7. createGuild(): Allows a Persona holder to establish a new Guild with a defined core domain.
//    8. joinGuild(): Enables a Persona holder to join an existing Guild.
//    9. leaveGuild(): Allows a Persona holder to voluntarily exit a Guild.
//    10. getGuildDetails(): Provides detailed information about a specific Guild.
//    11. proposeGuildInitiative(): Members propose an action or decision within their Guild (e.g., new skill, quest, treasury use).
//    12. voteOnGuildInitiative(): Members cast votes on active Guild initiatives, potentially weighted by relevant Persona attributes.
//    13. executeGuildInitiative(): Executes a Guild initiative once it has passed the voting threshold.

// III. Skill & Expertise System:
//    14. defineSkill(): Central governance or Guilds define a new skill node, its domain, and any prerequisites.
//    15. acquireSkillXP(): Awards experience points (XP) to a Persona for a specific skill.
//    16. levelUpSkill(): Allows a Persona to advance a skill to the next level upon accumulating sufficient XP.
//    17. getPersonaSkillLevel(): Retrieves the current level of a specific skill for a given Persona.
//    18. checkSkillPrerequisites(): Verifies if a Persona meets the necessary skill prerequisites for an action or new skill.

// IV. Questing & Achievements:
//    19. createQuest(): Guild governance or central authority creates a new quest, outlining requirements and rewards.
//    20. submitQuestCompletion(): Allows a Persona holder to submit proof of completing a quest.
//    21. verifyAndAwardQuest(): An authorized role (e.g., Guild council, oracle) verifies quest completion and distributes rewards (XP, reputation).
//    22. getAvailableQuests(): Lists all quests currently active and open for participation.

// V. Dynamic Reputation & Interactivity:
//    23. updateDomainReputation(): Internal function to adjust a Persona's reputation score within a specific domain.
//    24. getPersonaDomainReputation(): Retrieves a Persona's current reputation score in a specified domain.
//    25. delegateSkillInfluence(): Allows a Persona to temporarily delegate a portion of their skill-based influence/vote weight to another Persona.
//    26. revokeSkillInfluenceDelegation(): Revokes a previously granted skill influence delegation.
//    27. declareGuildAlliance(): Enables Guilds to propose an alliance with another Guild.
//    28. acceptGuildAlliance(): Acknowledges and finalizes an alliance proposal from another Guild.
//    29. breakGuildAlliance(): Breaks an existing alliance between two guilds.

contract ArcanumChronicles is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- I. Core Persona (Soulbound NFT) Management & Evolution ---

    Counters.Counter private _personaIds;
    string public basePersonaURI; // Base URI for Persona metadata, e.g., IPFS gateway

    struct Persona {
        uint256 id;
        address owner; // Owner is essentially the holder of the SBT
        uint256 creationTime;
        // Core Attributes (can be dynamic)
        mapping(string => uint256) skillsXP; // skillName => XP
        mapping(string => uint256) skillsLevel; // skillName => level
        mapping(string => int256) domainReputation; // domainName => reputation score (can be negative)
        // Dynamic Traits (simplified, for URI generation)
        string primaryDomain; // The domain where Persona has most reputation/skill
        uint256 totalSkillLevels; // Sum of all skill levels
        int256 totalReputationScore; // Sum of all domain reputations
    }

    mapping(uint256 => Persona) public personas; // personaId => Persona details
    mapping(address => uint256) public ownerToPersonaId; // ownerAddress => personaId (one persona per address)

    // Event for Persona minting
    event PersonaMinted(uint256 indexed personaId, address indexed owner, uint256 creationTime);
    // Event for Persona trait update
    event PersonaTraitUpdated(uint256 indexed personaId, string traitName, string newValue);
    // Event for Skill Level Up
    event SkillLeveledUp(uint256 indexed personaId, string skillName, uint256 newLevel);

    // --- II. Guild & DAO Management ---

    Counters.Counter private _guildIds;

    struct Guild {
        uint256 id;
        string name;
        address founder;
        string primaryDomain; // e.g., "Coding", "Art", "Research"
        uint256[] memberPersonaIds; // List of Persona IDs that are members
        mapping(uint256 => bool) isMember; // personaId => true if member
        // Simplified DAO for initiatives
        uint256 initiativeCounter;
        mapping(uint256 => Initiative) initiatives; // initiativeId => Initiative
        // Alliances
        mapping(uint256 => bool) alliedGuilds; // guildId => true if allied
    }

    struct Initiative {
        uint256 id;
        string description;
        address proposer;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(uint256 => bool) hasVoted; // personaId => true
        bool executed;
        bytes data; // Arbitrary data for the proposal (e.g., function call data)
        InitiativeType initiativeType;
    }

    enum InitiativeType {
        GENERIC,
        NEW_SKILL_DEFINITION,
        NEW_QUEST,
        TREASURY_ALLOCATION,
        ALLIANCE_PROPOSAL
    }

    mapping(uint256 => Guild) public guilds; // guildId => Guild details

    // Event for Guild creation
    event GuildCreated(uint256 indexed guildId, string name, address indexed founder);
    // Event for Guild membership changes
    event GuildMembershipChanged(uint256 indexed guildId, uint256 indexed personaId, bool joined);
    // Event for Guild Initiative
    event GuildInitiativeProposed(uint256 indexed guildId, uint256 indexed initiativeId, string description);
    event GuildInitiativeVoted(uint256 indexed guildId, uint256 indexed initiativeId, uint256 indexed personaId, bool vote);
    event GuildInitiativeExecuted(uint256 indexed guildId, uint256 indexed initiativeId);
    event GuildAllianceDeclared(uint256 indexed guildId1, uint256 indexed guildId2);
    event GuildAllianceBroken(uint256 indexed guildId1, uint256 indexed guildId2);

    // --- III. Skill & Expertise System ---

    struct Skill {
        string name;
        string domain;
        string[] prerequisites; // Array of skill names that are prerequisites
        uint256 maxLevel;
        mapping(uint256 => uint256) xpRequiredForLevel; // level => XP needed for that level
    }

    mapping(string => Skill) public skills; // skillName => Skill definition
    string[] public allSkillNames; // To iterate through all defined skills

    // Event for Skill definition
    event SkillDefined(string indexed skillName, string domain);
    // Event for XP acquisition
    event SkillXPAcquired(uint256 indexed personaId, string skillName, uint256 amount);

    // --- IV. Questing & Achievements ---

    Counters.Counter private _questIds;

    struct Quest {
        uint256 id;
        string name;
        string description;
        uint256 guildId; // 0 for global quest, otherwise associated guild
        string requiredSkillName; // Skill required to attempt/complete
        uint256 requiredSkillLevel;
        uint256 rewardXP; // XP reward for the requiredSkillName
        int256 rewardReputation; // Reputation reward for the guild's primary domain
        bool active; // Is the quest currently available?
        address verifier; // Address authorized to verify completion (e.g., Guild multisig, oracle)
    }

    mapping(uint256 => Quest) public quests; // questId => Quest details
    mapping(uint256 => mapping(uint256 => bool)) public personaQuestCompletion; // personaId => questId => completed (indicates submitted for verification)

    // Event for Quest creation
    event QuestCreated(uint256 indexed questId, string name, uint256 indexed guildId);
    // Event for Quest completion
    event QuestCompleted(uint256 indexed questId, uint256 indexed personaId);

    // --- V. Dynamic Reputation & Interactivity ---

    struct Delegation {
        uint256 delegatorPersonaId;
        uint256 amount; // Percentage or fixed amount of influence/weight
        uint256 expirationTime;
    }

    // personaId => delegateePersonaId => Delegation details
    mapping(uint256 => mapping(uint256 => Delegation)) public skillDelegations;

    // Default XP needed per level (can be customized per skill)
    uint256 public constant DEFAULT_XP_PER_LEVEL = 100;
    // Default max skill level
    uint256 public constant DEFAULT_MAX_SKILL_LEVEL = 10;
    // Base reputation decay rate (per day)
    uint256 public reputationDecayRateBasisPoints = 1; // 0.01% per day (10000 basis points = 100%)

    // Initializer for Ownable (constructor cannot be inherited directly by some tools)
    constructor(string memory _name, string memory _symbol, string memory _basePersonaURI) ERC721(_name, _symbol) Ownable(msg.sender) {
        basePersonaURI = _basePersonaURI;
    }

    // The _baseURI for ERC721, overridden to support dynamic URIs for personas.
    function _baseURI() internal view override returns (string memory) {
        return basePersonaURI;
    }

    // --- I. Core Persona (Soulbound NFT) Management & Evolution Functions ---

    /**
     * @dev mintPersona()
     * Mints a unique, non-transferable Soulbound Persona NFT (SBT) for the caller.
     * Each address can only mint one Persona.
     */
    function mintPersona() public {
        require(ownerToPersonaId[msg.sender] == 0, "Arcanum: Caller already has a Persona.");

        _personaIds.increment();
        uint256 newPersonaId = _personaIds.current();

        Persona storage newPersona = personas[newPersonaId];
        newPersona.id = newPersonaId;
        newPersona.owner = msg.sender;
        newPersona.creationTime = block.timestamp;
        newPersona.primaryDomain = "Unassigned"; // Default

        ownerToPersonaId[msg.sender] = newPersonaId;

        // ERC721 minting (SBT implies _transfer is restricted later)
        _mint(msg.sender, newPersonaId);

        emit PersonaMinted(newPersonaId, msg.sender, block.timestamp);
    }

    /**
     * @dev getPersonaIdByOwner()
     * @param _owner The address of the Persona owner.
     * @return The Persona ID associated with the given owner address.
     */
    function getPersonaIdByOwner(address _owner) public view returns (uint256) {
        return ownerToPersonaId[_owner];
    }

    /**
     * @dev getPersonaAttributes()
     * @param _personaId The ID of the Persona.
     * @return A tuple containing comprehensive attributes of the Persona.
     * Note: Mappings cannot be directly returned, so this is a simplified view.
     * For full skill/reputation details, use `getPersonaSkillLevel` and `getPersonaDomainReputation`.
     */
    function getPersonaAttributes(uint256 _personaId)
        public
        view
        returns (
            uint256 id,
            address owner,
            uint256 creationTime,
            string memory primaryDomain,
            uint256 totalSkillLevels,
            int256 totalReputationScore
        )
    {
        Persona storage p = personas[_personaId];
        require(p.owner != address(0), "Arcanum: Persona does not exist.");

        // Recalculate dynamic attributes for up-to-date values
        (p.totalSkillLevels, p.totalReputationScore) = _calculatePersonaAggregateScores(_personaId);
        p.primaryDomain = _determinePrimaryDomain(_personaId); // Update based on current state

        return (
            p.id,
            p.owner,
            p.creationTime,
            p.primaryDomain,
            p.totalSkillLevels,
            p.totalReputationScore
        );
    }

    /**
     * @dev getPersonaDynamicURI()
     * Generates a dynamic metadata URI for a Persona based on its evolving traits.
     * This method constructs a URI that points to an off-chain metadata server
     * (or IPFS path) that can render Persona attributes dynamically.
     * The URI format might be `basePersonaURI/api/persona/{personaId}.json`
     * where the server generates JSON based on on-chain data.
     */
    function getPersonaDynamicURI(uint256 _personaId) public view returns (string memory) {
        Persona storage p = personas[_personaId];
        require(p.owner != address(0), "Arcanum: Persona does not exist.");

        // Calculate dynamic attributes to include in the URI generation logic
        // These values are often used by off-chain renderers to create dynamic images/JSON
        // (uint256 currentTotalSkillLevels, int256 currentTotalReputationScore) = _calculatePersonaAggregateScores(_personaId);
        // string memory currentPrimaryDomain = _determinePrimaryDomain(_personaId);

        // Example: Base URI + Persona ID + a hash of key attributes for caching/versioning
        // In a real scenario, the off-chain renderer would query on-chain data directly.
        // For simplicity, we just append the ID.
        return string.concat(basePersonaURI, Strings.toString(_personaId));
    }

    /**
     * @dev calculatePersonaWisdomScore()
     * Computes a derived "Wisdom Score" based on a Persona's accumulated skills, reputation, and longevity.
     * This is a composite metric showing overall influence/experience.
     * @param _personaId The ID of the Persona.
     * @return The calculated Wisdom Score.
     */
    function calculatePersonaWisdomScore(uint256 _personaId) public view returns (uint256) {
        Persona storage p = personas[_personaId];
        require(p.owner != address(0), "Arcanum: Persona does not exist.");

        (uint256 currentTotalSkillLevels, int256 currentTotalReputationScore) = _calculatePersonaAggregateScores(_personaId);

        uint256 longevityFactor = (block.timestamp - p.creationTime) / (30 days); // +1 point per month
        uint256 skillFactor = currentTotalSkillLevels;
        uint256 reputationFactor = currentTotalReputationScore > 0 ? uint256(currentTotalReputationScore) : 0; // Only positive reputation contributes

        // Example calculation: weighted sum
        // Weights can be adjusted by governance
        uint256 wisdomScore = (skillFactor * 5) + (reputationFactor / 100) + (longevityFactor * 2);

        return wisdomScore;
    }

    /**
     * @dev _updatePersonaTrait()
     * Internal function to dynamically update specific traits of a Persona.
     * This is called by other functions upon certain events (e.g., skill level up, quest completion).
     * @param _personaId The ID of the Persona to update.
     * @param _traitName The name of the trait to update (e.g., "primaryDomain").
     * @param _newValue The new value for the trait (as a string).
     */
    function _updatePersonaTrait(uint256 _personaId, string memory _traitName, string memory _newValue) internal {
        Persona storage p = personas[_personaId];
        if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("primaryDomain"))) {
            p.primaryDomain = _newValue;
        }
        // Additional traits can be added here based on future needs
        emit PersonaTraitUpdated(_personaId, _traitName, _newValue);
    }

    // Internal helper to calculate total skill levels and total reputation
    function _calculatePersonaAggregateScores(uint256 _personaId)
        internal
        view
        returns (uint256 totalSkillLevels, int256 totalReputationScore)
    {
        Persona storage p = personas[_personaId];
        totalSkillLevels = 0;
        for (uint i = 0; i < allSkillNames.length; i++) {
            totalSkillLevels += p.skillsLevel[allSkillNames[i]];
        }

        // Apply decay to reputation (simplified for this example; real decay needs more granular timestamps per domain)
        totalReputationScore = 0;
        // To accurately iterate over domains for reputation calculation,
        // we'd need a way to store all unique domain names.
        // For now, we sum reputation from domains associated with defined skills.
        string[] memory uniqueDomains = new string[](0);
        for (uint i = 0; i < allSkillNames.length; i++) {
            string memory currentSkillDomain = skills[allSkillNames[i]].domain;
            bool found = false;
            for (uint j = 0; j < uniqueDomains.length; j++) {
                if (keccak256(abi.encodePacked(uniqueDomains[j])) == keccak256(abi.encodePacked(currentSkillDomain))) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                uniqueDomains = _pushString(uniqueDomains, currentSkillDomain);
            }
        }
        
        for (uint i = 0; i < uniqueDomains.length; i++) {
            totalReputationScore += p.domainReputation[uniqueDomains[i]];
        }
        
        return (totalSkillLevels, totalReputationScore);
    }

    // Helper to dynamically add string to array
    function _pushString(string[] memory _array, string memory _value) internal pure returns (string[] memory) {
        string[] memory newArray = new string[](_array.length + 1);
        for (uint i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }

    // Internal helper to determine primary domain based on reputation
    function _determinePrimaryDomain(uint256 _personaId) internal view returns (string memory) {
        Persona storage p = personas[_personaId];
        string memory highestDomain = "Unassigned";
        int256 highestRep = -1; // Reputation can be negative

        string[] memory domainsChecked = new string[](0);
        for (uint i = 0; i < allSkillNames.length; i++) {
            string memory currentDomain = skills[allSkillNames[i]].domain;
            bool alreadyChecked = false;
            for(uint j=0; j < domainsChecked.length; j++){
                if(keccak256(abi.encodePacked(domainsChecked[j])) == keccak256(abi.encodePacked(currentDomain))){
                    alreadyChecked = true;
                    break;
                }
            }
            if(!alreadyChecked){
                domainsChecked = _pushString(domainsChecked, currentDomain);
                int256 rep = p.domainReputation[currentDomain];
                if (rep > highestRep) {
                    highestRep = rep;
                    highestDomain = currentDomain;
                }
            }
        }
        return highestDomain;
    }

    // ERC721 non-transferable override
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Ensure only minting (from address(0)) or burning (to address(0)) is allowed.
        require(from == address(0) || to == address(0), "Arcanum: Persona NFTs are soulbound and cannot be transferred.");
    }

    // --- II. Guild & DAO Management Functions ---

    /**
     * @dev createGuild()
     * Allows a Persona holder to establish a new Guild.
     * @param _name The name of the new Guild.
     * @param _primaryDomain The primary domain of focus for the Guild (e.g., "Solidity Development", "Concept Art").
     */
    function createGuild(string memory _name, string memory _primaryDomain) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona to create a Guild.");

        _guildIds.increment();
        uint256 newGuildId = _guildIds.current();

        Guild storage newGuild = guilds[newGuildId];
        newGuild.id = newGuildId;
        newGuild.name = _name;
        newGuild.founder = msg.sender;
        newGuild.primaryDomain = _primaryDomain;

        // Automatically join the founder
        newGuild.memberPersonaIds.push(personaId);
        newGuild.isMember[personaId] = true;

        emit GuildCreated(newGuildId, _name, msg.sender);
        emit GuildMembershipChanged(newGuildId, personaId, true);
    }

    /**
     * @dev joinGuild()
     * Allows a Persona holder to join an existing Guild.
     * @param _guildId The ID of the Guild to join.
     */
    function joinGuild(uint256 _guildId) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona to join a Guild.");
        require(guilds[_guildId].id != 0, "Arcanum: Guild does not exist.");
        require(!guilds[_guildId].isMember[personaId], "Arcanum: Persona is already a member of this Guild.");

        guilds[_guildId].memberPersonaIds.push(personaId);
        guilds[_guildId].isMember[personaId] = true;

        emit GuildMembershipChanged(_guildId, personaId, true);
    }

    /**
     * @dev leaveGuild()
     * Allows a Persona holder to voluntarily leave a Guild.
     * @param _guildId The ID of the Guild to leave.
     */
    function leaveGuild(uint256 _guildId) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona.");
        require(guilds[_guildId].id != 0, "Arcanum: Guild does not exist.");
        require(guilds[_guildId].isMember[personaId], "Arcanum: Persona is not a member of this Guild.");
        require(guilds[_guildId].founder != msg.sender, "Arcanum: Guild founder cannot leave the guild without transferring ownership or dissolving it."); // Simplified for now

        Guild storage guild = guilds[_guildId];
        guild.isMember[personaId] = false;

        // Remove from memberPersonaIds array (costly for large arrays)
        // For production, consider linked lists or just relying on `isMember` mapping.
        for (uint i = 0; i < guild.memberPersonaIds.length; i++) {
            if (guild.memberPersonaIds[i] == personaId) {
                guild.memberPersonaIds[i] = guild.memberPersonaIds[guild.memberPersonaIds.length - 1];
                guild.memberPersonaIds.pop();
                break;
            }
        }

        emit GuildMembershipChanged(_guildId, personaId, false);
    }

    /**
     * @dev getGuildDetails()
     * Retrieves core information about a specific Guild.
     * @param _guildId The ID of the Guild.
     * @return A tuple containing Guild details.
     */
    function getGuildDetails(uint256 _guildId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            address founder,
            string memory primaryDomain,
            uint256 memberCount
        )
    {
        Guild storage g = guilds[_guildId];
        require(g.id != 0, "Arcanum: Guild does not exist.");
        return (g.id, g.name, g.founder, g.primaryDomain, g.memberPersonaIds.length);
    }

    /**
     * @dev proposeGuildInitiative()
     * Members propose an initiative within their Guild.
     * @param _guildId The ID of the Guild.
     * @param _description A description of the initiative.
     * @param _votingDuration The duration in seconds for voting.
     * @param _data Arbitrary data associated with the proposal (e.g., function call data for execution).
     * @param _initiativeType The type of initiative.
     */
    function proposeGuildInitiative(
        uint256 _guildId,
        string memory _description,
        uint256 _votingDuration,
        bytes memory _data,
        InitiativeType _initiativeType
    ) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona.");
        require(guilds[_guildId].isMember[personaId], "Arcanum: Caller is not a member of this Guild.");
        require(_votingDuration > 0, "Arcanum: Voting duration must be positive.");

        Guild storage guild = guilds[_guildId];
        guild.initiativeCounter.increment();
        uint256 newInitiativeId = guild.initiativeCounter.current();

        Initiative storage newInitiative = guild.initiatives[newInitiativeId];
        newInitiative.id = newInitiativeId;
        newInitiative.description = _description;
        newInitiative.proposer = msg.sender;
        newInitiative.votingDeadline = block.timestamp + _votingDuration;
        newInitiative.data = _data;
        newInitiative.initiativeType = _initiativeType;

        emit GuildInitiativeProposed(_guildId, newInitiativeId, _description);
    }

    /**
     * @dev voteOnGuildInitiative()
     * Members cast votes on active Guild initiatives. Votes might be weighted by relevant Persona attributes.
     * @param _guildId The ID of the Guild.
     * @param _initiativeId The ID of the initiative to vote on.
     * @param _vote True for 'yes', false for 'no'.
     */
    function voteOnGuildInitiative(uint256 _guildId, uint256 _initiativeId, bool _vote) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona.");
        require(guilds[_guildId].isMember[personaId], "Arcanum: Caller is not a member of this Guild.");

        Guild storage guild = guilds[_guildId];
        Initiative storage initiative = guild.initiatives[_initiativeId];
        require(initiative.proposer != address(0), "Arcanum: Initiative does not exist.");
        require(block.timestamp < initiative.votingDeadline, "Arcanum: Voting has ended for this initiative.");
        require(!initiative.hasVoted[personaId], "Arcanum: Persona has already voted on this initiative.");

        // Voting weight based on Persona's reputation in the Guild's primary domain
        // Or specific skill levels relevant to the initiative's type
        int256 votingWeight = getPersonaDomainReputation(personaId, guild.primaryDomain);
        if (votingWeight < 0) votingWeight = 0; // Negative reputation doesn't subtract votes, just gives 0.

        // Add a base vote to prevent 0-weight issues
        uint256 effectiveVoteWeight = 1 + uint256(votingWeight) / 10; // 1 base vote + 0.1 for every reputation point

        if (_vote) {
            initiative.yesVotes += effectiveVoteWeight;
        } else {
            initiative.noVotes += effectiveVoteWeight;
        }
        initiative.hasVoted[personaId] = true;

        emit GuildInitiativeVoted(_guildId, _initiativeId, personaId, _vote);
    }

    /**
     * @dev executeGuildInitiative()
     * Executes a Guild initiative once it has passed the voting threshold.
     * This function would typically be called by any member after the voting deadline.
     * Requires a predefined "passing threshold" (e.g., simple majority of total votes).
     * The `_data` payload would contain instructions for what to execute.
     */
    function executeGuildInitiative(uint256 _guildId, uint256 _initiativeId) public {
        Guild storage guild = guilds[_guildId];
        Initiative storage initiative = guild.initiatives[_initiativeId];
        require(initiative.proposer != address(0), "Arcanum: Initiative does not exist.");
        require(block.timestamp >= initiative.votingDeadline, "Arcanum: Voting is still active for this initiative.");
        require(!initiative.executed, "Arcanum: Initiative has already been executed.");

        uint256 totalVotes = initiative.yesVotes + initiative.noVotes;
        require(totalVotes > 0, "Arcanum: No votes cast for this initiative.");

        // Simple majority rule for passing
        bool passed = initiative.yesVotes > initiative.noVotes;
        require(passed, "Arcanum: Initiative did not pass.");

        initiative.executed = true;

        // In a full DAO, this would use a delegatecall or call to another contract
        // based on the `initiative.data` and `initiative.initiativeType`.
        // For this example, we'll just emit an event.
        // Example: if (initiative.initiativeType == InitiativeType.NEW_SKILL_DEFINITION) { ... call defineSkill with initiative.data }

        emit GuildInitiativeExecuted(_guildId, _initiativeId);
    }

    // --- III. Skill & Expertise System Functions ---

    /**
     * @dev defineSkill()
     * Defines a new skill node, its domain, prerequisites, and max level.
     * Only callable by the contract owner (or via Guild Initiative if governance-controlled).
     * @param _skillName The unique name of the skill.
     * @param _domain The domain this skill belongs to (e.g., "Programming", "Artistry").
     * @param _prerequisites Array of skill names that must be mastered before this skill.
     * @param _maxLevel The maximum level this skill can reach.
     */
    function defineSkill(
        string memory _skillName,
        string memory _domain,
        string[] memory _prerequisites,
        uint256 _maxLevel
    ) public onlyOwner {
        require(skills[_skillName].maxLevel == 0, "Arcanum: Skill with this name already exists.");
        require(_maxLevel > 0, "Arcanum: Max level must be greater than zero.");

        skills[_skillName].name = _skillName;
        skills[_skillName].domain = _domain;
        skills[_skillName].prerequisites = _prerequisites;
        skills[_skillName].maxLevel = _maxLevel;

        for (uint i = 1; i <= _maxLevel; i++) {
            skills[_skillName].xpRequiredForLevel[i] = DEFAULT_XP_PER_LEVEL * i; // Linear XP scaling
        }

        allSkillNames = _pushString(allSkillNames, _skillName);

        emit SkillDefined(_skillName, _domain);
    }

    /**
     * @dev acquireSkillXP()
     * Awards experience points (XP) to a Persona for a specific skill.
     * This function would typically be called by a trusted oracle or after quest verification.
     * @param _personaId The ID of the Persona to award XP to.
     * @param _skillName The name of the skill to award XP for.
     * @param _amount The amount of XP to award.
     */
    function acquireSkillXP(uint256 _personaId, string memory _skillName, uint256 _amount) public onlyOwner {
        // Can be restricted to specific roles, e.g., Guild verifier via executeGuildInitiative
        Persona storage p = personas[_personaId];
        require(p.owner != address(0), "Arcanum: Persona does not exist.");
        require(skills[_skillName].maxLevel > 0, "Arcanum: Skill does not exist.");

        p.skillsXP[_skillName] += _amount;
        emit SkillXPAcquired(_personaId, _skillName, _amount);
    }

    /**
     * @dev levelUpSkill()
     * Allows a Persona to advance a skill to the next level upon accumulating sufficient XP.
     * Must meet prerequisites and have enough XP.
     * @param _personaId The ID of the Persona.
     * @param _skillName The name of the skill to level up.
     */
    function levelUpSkill(uint256 _personaId, string memory _skillName) public {
        require(ownerToPersonaId[msg.sender] == _personaId, "Arcanum: Only Persona owner can level up their skills.");

        Persona storage p = personas[_personaId];
        Skill storage s = skills[_skillName];
        require(s.maxLevel > 0, "Arcanum: Skill does not exist.");

        uint256 currentLevel = p.skillsLevel[_skillName];
        require(currentLevel < s.maxLevel, "Arcanum: Skill is already at max level.");

        // Check prerequisites
        for (uint i = 0; i < s.prerequisites.length; i++) {
            require(p.skillsLevel[s.prerequisites[i]] > 0, string.concat("Arcanum: Prerequisite skill not met: ", s.prerequisites[i]));
        }

        uint256 xpNeeded = s.xpRequiredForLevel[currentLevel + 1];
        require(p.skillsXP[_skillName] >= xpNeeded, "Arcanum: Not enough XP to level up.");

        p.skillsLevel[_skillName] += 1;
        p.skillsXP[_skillName] -= xpNeeded; // Consume XP

        // Update Persona traits derived from skills
        (p.totalSkillLevels, p.totalReputationScore) = _calculatePersonaAggregateScores(_personaId);
        _updatePersonaTrait(_personaId, "primaryDomain", _determinePrimaryDomain(_personaId));

        emit SkillLeveledUp(_personaId, _skillName, p.skillsLevel[_skillName]);
    }

    /**
     * @dev getPersonaSkillLevel()
     * Retrieves the current level of a specific skill for a given Persona.
     * @param _personaId The ID of the Persona.
     * @param _skillName The name of the skill.
     * @return The current level of the skill.
     */
    function getPersonaSkillLevel(uint256 _personaId, string memory _skillName) public view returns (uint256) {
        Persona storage p = personas[_personaId];
        require(p.owner != address(0), "Arcanum: Persona does not exist.");
        return p.skillsLevel[_skillName];
    }

    /**
     * @dev checkSkillPrerequisites()
     * Verifies if a Persona meets the necessary skill prerequisites for a particular action or new skill.
     * @param _personaId The ID of the Persona.
     * @param _requiredSkills Array of skill names to check.
     * @param _requiredLevels Array of corresponding minimum levels for each skill.
     * @return True if all prerequisites are met, false otherwise.
     */
    function checkSkillPrerequisites(
        uint256 _personaId,
        string[] memory _requiredSkills,
        uint256[] memory _requiredLevels
    ) public view returns (bool) {
        Persona storage p = personas[_personaId];
        require(p.owner != address(0), "Arcanum: Persona does not exist.");
        require(_requiredSkills.length == _requiredLevels.length, "Arcanum: Mismatched skill and level arrays.");

        for (uint i = 0; i < _requiredSkills.length; i++) {
            if (p.skillsLevel[_requiredSkills[i]] < _requiredLevels[i]) {
                return false;
            }
        }
        return true;
    }

    // --- IV. Questing & Achievements Functions ---

    /**
     * @dev createQuest()
     * Guild governance or central authority creates a new quest with specific requirements and rewards.
     * Can be called by owner or via Guild Initiative.
     * @param _name The name of the quest.
     * @param _description A detailed description of the quest.
     * @param _guildId The ID of the guild creating the quest (0 for global quests).
     * @param _requiredSkillName The skill required to attempt/complete the quest.
     * @param _requiredSkillLevel The minimum level for the required skill.
     * @param _rewardXP The XP reward for completing the quest.
     * @param _rewardReputation The reputation reward for the quest's domain.
     * @param _verifier The address authorized to verify completion (e.g., a Guild multisig, an oracle).
     */
    function createQuest(
        string memory _name,
        string memory _description,
        uint256 _guildId,
        string memory _requiredSkillName,
        uint256 _requiredSkillLevel,
        uint256 _rewardXP,
        int256 _rewardReputation,
        address _verifier
    ) public onlyOwner { // Simplified to onlyOwner, could be Guild governance via initiative
        require(skills[_requiredSkillName].maxLevel > 0, "Arcanum: Required skill does not exist.");
        if (_guildId != 0) {
            require(guilds[_guildId].id != 0, "Arcanum: Guild for quest does not exist.");
        }
        require(_verifier != address(0), "Arcanum: Verifier address cannot be zero.");

        _questIds.increment();
        uint256 newQuestId = _questIds.current();

        Quest storage newQuest = quests[newQuestId];
        newQuest.id = newQuestId;
        newQuest.name = _name;
        newQuest.description = _description;
        newQuest.guildId = _guildId;
        newQuest.requiredSkillName = _requiredSkillName;
        newQuest.requiredSkillLevel = _requiredSkillLevel;
        newQuest.rewardXP = _rewardXP;
        newQuest.rewardReputation = _rewardReputation;
        newQuest.active = true;
        newQuest.verifier = _verifier;

        emit QuestCreated(newQuestId, _name, _guildId);
    }

    /**
     * @dev submitQuestCompletion()
     * Allows a Persona holder to submit proof of completing a quest.
     * This could be a simple flag for on-chain verifiable tasks, or a hash for off-chain work.
     * Actual rewards are given upon `verifyAndAwardQuest`.
     * @param _personaId The ID of the Persona submitting.
     * @param _questId The ID of the quest completed.
     */
    function submitQuestCompletion(uint256 _personaId, uint256 _questId) public {
        require(ownerToPersonaId[msg.sender] == _personaId, "Arcanum: Only Persona owner can submit completions.");
        Persona storage p = personas[_personaId];
        Quest storage q = quests[_questId];
        require(q.id != 0, "Arcanum: Quest does not exist.");
        require(q.active, "Arcanum: Quest is not active.");
        require(!personaQuestCompletion[_personaId][_questId], "Arcanum: Quest already submitted by this Persona.");
        require(p.skillsLevel[q.requiredSkillName] >= q.requiredSkillLevel, "Arcanum: Persona does not meet skill requirements for this quest.");

        // For this example, submission is just marking for verification.
        // In a real system, this might take a `proof` parameter.
        personaQuestCompletion[_personaId][_questId] = true; // Mark as submitted for verification
        // emit QuestSubmission(questId, personaId, proofHash); // More detailed event needed
    }

    /**
     * @dev verifyAndAwardQuest()
     * An authorized role (e.g., Guild council, oracle) verifies quest completion and distributes rewards.
     * @param _personaId The ID of the Persona who completed the quest.
     * @param _questId The ID of the quest.
     */
    function verifyAndAwardQuest(uint256 _personaId, uint256 _questId) public {
        Quest storage q = quests[_questId];
        require(q.id != 0, "Arcanum: Quest does not exist.");
        require(msg.sender == q.verifier, "Arcanum: Caller is not authorized to verify this quest.");
        require(personaQuestCompletion[_personaId][_questId], "Arcanum: Quest not submitted by this Persona for verification.");

        Persona storage p = personas[_personaId];

        // Award XP
        acquireSkillXP(_personaId, q.requiredSkillName, q.rewardXP);

        // Update domain reputation
        string memory domainToUpdate = (q.guildId != 0) ? guilds[q.guildId].primaryDomain : skills[q.requiredSkillName].domain;
        _updateDomainReputation(_personaId, domainToUpdate, q.rewardReputation);

        // Mark as truly completed (can't resubmit/re-award)
        // For scenarios where quests are repeatable, this flag would need to be different
        personaQuestCompletion[_personaId][_questId] = false; // Reset for potential re-submission in repeatable quests
                                                              // or use a separate mapping for 'awarded' status.
                                                              // For now, marking submission to false, as it's a one-time verification.

        emit QuestCompleted(_questId, _personaId);
    }

    /**
     * @dev getAvailableQuests()
     * Lists all quests currently active and open for participation.
     * @return An array of active Quest IDs.
     */
    function getAvailableQuests() public view returns (uint256[] memory) {
        uint256[] memory activeQuests = new uint256[](_questIds.current()); // Max possible size
        uint256 counter = 0;
        for (uint256 i = 1; i <= _questIds.current(); i++) {
            if (quests[i].active) {
                activeQuests[counter] = i;
                counter++;
            }
        }
        // Resize the array to actual count
        uint256[] memory result = new uint256[](counter);
        for (uint i = 0; i < counter; i++) {
            result[i] = activeQuests[i];
        }
        return result;
    }

    // --- V. Dynamic Reputation & Interactivity Functions ---

    /**
     * @dev _updateDomainReputation()
     * Internal function to adjust a Persona's reputation score within a specific domain.
     * This is called by other functions like `verifyAndAwardQuest`.
     * @param _personaId The ID of the Persona.
     * @param _domainName The name of the domain for which reputation is updated.
     * @param _amount The amount to add/subtract from reputation.
     */
    function _updateDomainReputation(uint256 _personaId, string memory _domainName, int256 _amount) internal {
        Persona storage p = personas[_personaId];
        p.domainReputation[_domainName] += _amount;
        // Optionally, recalculate overall reputation and primary domain for dynamic URI
        (p.totalSkillLevels, p.totalReputationScore) = _calculatePersonaAggregateScores(_personaId);
        _updatePersonaTrait(_personaId, "primaryDomain", _determinePrimaryDomain(_personaId));
    }

    /**
     * @dev getPersonaDomainReputation()
     * Retrieves a Persona's current reputation score in a specified domain.
     * @param _personaId The ID of the Persona.
     * @param _domainName The name of the domain.
     * @return The current reputation score.
     */
    function getPersonaDomainReputation(uint256 _personaId, string memory _domainName) public view returns (int256) {
        Persona storage p = personas[_personaId];
        require(p.owner != address(0), "Arcanum: Persona does not exist.");
        // Consider decay logic here if reputation is purely time-decaying
        return p.domainReputation[_domainName];
    }

    /**
     * @dev delegateSkillInfluence()
     * Allows a Persona to temporarily delegate a portion of their skill-based influence/vote weight to another Persona.
     * Useful for liquid democracy or task-specific delegation of expertise.
     * @param _delegatorPersonaId The Persona ID of the delegator.
     * @param _delegateePersonaId The Persona ID of the delegatee.
     * @param _amount The amount of influence to delegate (e.g., as basis points or raw value).
     * @param _durationSeconds The duration for which the delegation is valid, in seconds.
     */
    function delegateSkillInfluence(
        uint256 _delegatorPersonaId,
        uint256 _delegateePersonaId,
        uint256 _amount,
        uint256 _durationSeconds
    ) public {
        require(ownerToPersonaId[msg.sender] == _delegatorPersonaId, "Arcanum: Only delegator can initiate this.");
        require(personas[_delegateePersonaId].owner != address(0), "Arcanum: Delegatee Persona does not exist.");
        require(_delegatorPersonaId != _delegateePersonaId, "Arcanum: Cannot delegate to self.");
        require(_amount > 0, "Arcanum: Delegation amount must be positive.");
        require(_durationSeconds > 0, "Arcanum: Delegation duration must be positive.");

        Delegation storage delegation = skillDelegations[_delegatorPersonaId][_delegateePersonaId];
        delegation.delegatorPersonaId = _delegatorPersonaId;
        delegation.amount = _amount; // Can define units (e.g. 100 for 100% of applicable influence)
        delegation.expirationTime = block.timestamp + _durationSeconds;
    }

    /**
     * @dev revokeSkillInfluenceDelegation()
     * Revokes a previously granted skill influence delegation immediately.
     * @param _delegatorPersonaId The Persona ID of the delegator.
     * @param _delegateePersonaId The Persona ID of the delegatee whose delegation is being revoked.
     */
    function revokeSkillInfluenceDelegation(
        uint256 _delegatorPersonaId,
        uint256 _delegateePersonaId
    ) public {
        require(ownerToPersonaId[msg.sender] == _delegatorPersonaId, "Arcanum: Only delegator can revoke.");
        require(skillDelegations[_delegatorPersonaId][_delegateePersonaId].delegatorPersonaId != 0, "Arcanum: No active delegation found.");

        delete skillDelegations[_delegatorPersonaId][_delegateePersonaId];
    }

    /**
     * @dev declareGuildAlliance()
     * Allows a Guild to propose an alliance with another Guild. Requires reciprocal acceptance.
     * Only callable by the founder of the proposing guild (or via Guild Initiative).
     * @param _proposingGuildId The ID of the Guild proposing the alliance.
     * @param _targetGuildId The ID of the Guild being proposed to.
     */
    function declareGuildAlliance(uint256 _proposingGuildId, uint256 _targetGuildId) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona.");
        require(guilds[_proposingGuildId].founder == msg.sender, "Arcanum: Only Guild founder can propose alliance."); // Simplified
        require(guilds[_targetGuildId].id != 0, "Arcanum: Target Guild does not exist.");
        require(_proposingGuildId != _targetGuildId, "Arcanum: Cannot ally with self.");
        require(!guilds[_proposingGuildId].alliedGuilds[_targetGuildId], "Arcanum: Alliance already exists.");

        // For simplicity, we directly set alliance. In a real system, this would be a pending state
        // and require a vote/acceptance from the target guild.
        // For now, it sets a one-way 'proposed' status.
        guilds[_proposingGuildId].alliedGuilds[_targetGuildId] = true;
        // The other guild needs to call acceptGuildAlliance()

        emit GuildAllianceDeclared(_proposingGuildId, _targetGuildId);
    }

    /**
     * @dev acceptGuildAlliance()
     * Acknowledges and finalizes an alliance proposal from another Guild.
     * Callable by the founder of the accepting guild (or via Guild Initiative).
     * @param _acceptingGuildId The ID of the Guild accepting the alliance.
     * @param _proposingGuildId The ID of the Guild that proposed the alliance.
     */
    function acceptGuildAlliance(uint256 _acceptingGuildId, uint256 _proposingGuildId) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona.");
        require(guilds[_acceptingGuildId].founder == msg.sender, "Arcanum: Only Guild founder can accept alliance."); // Simplified
        require(guilds[_proposingGuildId].id != 0, "Arcanum: Proposing Guild does not exist.");
        require(_acceptingGuildId != _proposingGuildId, "Arcanum: Cannot ally with self.");
        require(guilds[_proposingGuildId].alliedGuilds[_acceptingGuildId], "Arcanum: No alliance proposal from this Guild."); // Check if the other guild proposed
        require(!guilds[_acceptingGuildId].alliedGuilds[_proposingGuildId], "Arcanum: Alliance already exists.");

        guilds[_acceptingGuildId].alliedGuilds[_proposingGuildId] = true;

        emit GuildAllianceDeclared(_acceptingGuildId, _proposingGuildId);
    }

    /**
     * @dev breakGuildAlliance()
     * Breaks an existing alliance between two guilds.
     * Callable by the founder of either guild in the alliance (or via Guild Initiative).
     * @param _guildId1 The ID of the first guild in the alliance.
     * @param _guildId2 The ID of the second guild in the alliance.
     */
    function breakGuildAlliance(uint256 _guildId1, uint256 _guildId2) public {
        uint256 personaId = ownerToPersonaId[msg.sender];
        require(personaId != 0, "Arcanum: Caller must have a Persona.");
        require(guilds[_guildId1].founder == msg.sender || guilds[_guildId2].founder == msg.sender, "Arcanum: Only a founder of an allied guild can break alliance.");
        require(guilds[_guildId1].id != 0 && guilds[_guildId2].id != 0, "Arcanum: One or both guilds do not exist.");
        require(_guildId1 != _guildId2, "Arcanum: Cannot break alliance with self.");
        require(guilds[_guildId1].alliedGuilds[_guildId2] || guilds[_guildId2].alliedGuilds[_guildId1], "Arcanum: No active alliance between these guilds.");

        // Break alliance bi-directionally
        delete guilds[_guildId1].alliedGuilds[_guildId2];
        delete guilds[_guildId2].alliedGuilds[_guildId1];

        emit GuildAllianceBroken(_guildId1, _guildId2);
    }

    // Fallback for security (optional, but good practice if no payable functions are intended)
    receive() external payable {
        revert("Arcanum: This contract does not accept direct Ether transfers.");
    }

    fallback() external payable {
        revert("Arcanum: Invalid function call.");
    }
}
```