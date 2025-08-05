This smart contract, `AuraBoundCompanions`, envisions a new class of non-fungible tokens (NFTs) that are not static collectibles but dynamic, evolving digital companions. These companions possess unique, immutable "Essence" at minting and evolve through user interactions, on-chain events, and external oracle data. They gain "Aura Points," develop "Affinity" with their owner, and can advance through different "Form Levels," unlocking unique "Abilities." A core innovative concept is the integration of "Reflections" (user-submitted shared experiences) and "Whispers" (ephemeral, pseudo-AI generated insights by the companion), influencing and being influenced by its state.

---

## AuraBoundCompanions: A Blueprint for Evolving Digital Companions

### **Contract Outline:**

1.  **Overview**: Introduction to the concept of evolving NFTs.
2.  **Core Components**:
    *   **ERC721 Standard**: Foundation for unique digital ownership.
    *   **Pausable & Ownable**: Standard OpenZeppelin features for safety and control.
    *   **Chainlink Client**: For secure, decentralized oracle interaction.
3.  **Key Concepts & Data Structures**:
    *   `Companion`: The main struct holding all dynamic attributes of an NFT.
        *   `essenceHash`: Immutable core identity.
        *   `auraPoints`: Accumulative experience/energy.
        *   `affinityLevel`: Bond strength with owner.
        *   `formLevel`: Current evolutionary stage.
        *   `elementalAttunement`: Dynamic alignment to elements (Fire, Water, Air, Earth, Spirit).
        *   `unlockedAbilities`: Bitmask or array of unlocked special traits.
        *   `lastInteractionTime`: Timestamp of last significant interaction.
        *   `currentWhisper`: Ephemeral insight from the companion.
    *   `FormDetails`: Defines requirements and effects for each evolution stage.
    *   `AbilityDetails`: Defines requirements and effects for each unlockable ability.
    *   `ReflectionPool`: A global and companion-specific registry for curated data/experiences.
    *   `AuraNexus`: A conceptual global pool of collective energy.
4.  **Evolution & Interaction Mechanics**:
    *   **Bonding**: Initiating connection.
    *   **Meditating**: Regular interaction to gain Aura.
    *   **Enlightening**: Accelerating progress via payment.
    *   **Sharing Experiences (Reflections)**: Users submit verifiable (conceptually off-chain or future ZKP) data influencing companions.
    *   **Form Evolution**: Advancing through stages upon meeting Aura/Affinity thresholds.
    *   **Ability Unlocking**: Gaining new powers.
    *   **Elemental Attunement**: Dynamic stat influenced by external data via Chainlink.
    *   **Whisper Manifestation**: Companion generating unique insights.
5.  **Economic & Governance Aspects**:
    *   Configurable costs for interactions.
    *   Owner-controlled parameters.
6.  **Advanced Features**:
    *   **Dynamic Metadata (`tokenURI`)**: On-chain generation of NFT metadata (SVG/JSON).
    *   **Chainlink Oracle Integration**: For external data feeds influencing companion states.
    *   **Pseudo-AI "Whispers"**: Simple on-chain deterministic "insights" based on state.
    *   **"Reflection Pool"**: A unique mechanism for decentralized, curated data sharing.

---

### **Function Summary (At least 20 Functions):**

**I. Core ERC721 & Base Functions:**

1.  `constructor()`: Initializes the contract, setting up owner and Chainlink dependencies.
2.  `mintCompanion(string calldata _essenceHash)`: Mints a new AuraBound Companion NFT, assigning it a unique, immutable essence.
3.  `tokenURI(uint256 tokenId)`: **Advanced/Dynamic:** Generates a base64 encoded JSON metadata URI with embedded SVG for the NFT, reflecting its current dynamic state (Aura, Form, Elements, Abilities).
4.  `supportsInterface(bytes4 interfaceId)`: Standard ERC721 support.
5.  `ownerOf(uint256 tokenId)`: Standard ERC721 query.
6.  `balanceOf(address owner)`: Standard ERC721 query.
7.  `getApproved(uint256 tokenId)`: Standard ERC721 query.
8.  `isApprovedForAll(address owner, address operator)`: Standard ERC721 query.
9.  `approve(address to, uint256 tokenId)`: Standard ERC721 transfer approval.
10. `setApprovalForAll(address operator, bool approved)`: Standard ERC721 operator approval.
11. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer.
12. `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 safe transfer.
13. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Standard ERC721 safe transfer with data.

**II. Companion State & Query Functions:**

14. `getCompanionDetails(uint256 tokenId)`: Retrieves all core dynamic attributes of a specific companion.
15. `getCompanionAbilities(uint256 tokenId)`: Returns an array of strings representing the unlocked abilities of a companion.
16. `getCompanionReflections(uint256 tokenId)`: Fetches the list of experience hashes specifically associated with a companion.
17. `getCurrentWhisper(uint256 tokenId)`: Returns the companion's current ephemeral "whisper."

**III. Interaction & Evolution Functions:**

18. `bondWithCompanion(uint256 tokenId)`: Initiates the bonding process, setting initial affinity and preparing the companion for interaction.
19. `meditateWithCompanion(uint256 tokenId)`: Allows the owner to meditate with their companion, increasing Aura Points and Affinity over time. (Cooldown applied)
20. `shareExperience(uint256 tokenId, string calldata experienceHash)`: Allows an owner to submit a hash representing a unique experience associated with their companion, potentially influencing its Aura or Elemental Attunement (conceptually, validation occurs off-chain or via future ZKP).
21. `enlightenCompanion(uint256 tokenId) payable`: A premium interaction that significantly boosts a companion's Aura Points and Affinity in exchange for ETH.
22. `catalyzeFormEvolution(uint256 tokenId)`: Triggers an attempt to evolve the companion's form level if sufficient Aura Points and Affinity are met.
23. `unlockAbility(uint256 tokenId, uint8 abilityIndex)`: Allows an owner to unlock a specific ability for their companion, provided the companion meets the Form Level and Aura requirements.
24. `requestElementalAttunementUpdate(uint256 tokenId)`: **Advanced/Oracle:** Initiates a Chainlink request to fetch external data (e.g., market sentiment, environmental data) that will influence the companion's elemental attunement.
25. `fulfillElementalAttunementUpdate(bytes32 requestId, uint256 response)`: **Advanced/Oracle:** Chainlink callback function to receive and process the external data, updating the companion's elemental attunement.
26. `manifestWhisper(uint256 tokenId)`: Triggers the companion to generate a new deterministic "whisper" based on its current state and environmental factors (simulated).

**IV. Community & Global Mechanics Functions:**

27. `submitGlobalReflection(string calldata reflectionHash)`: Allows any user to contribute a general experience hash to the contract's global Reflection Pool.
28. `getGlobalReflections()`: Retrieves the list of globally shared experience hashes.
29. `contributeToAuraNexus() payable`: Allows users to contribute ETH to a global "Aura Nexus," conceptually powering collective companion evolution or future features.
30. `getAuraNexusState()`: Returns the current ETH balance of the Aura Nexus.

**V. Admin & Configuration Functions (Owner-only):**

31. `pause()`: Pauses core contract functions, preventing interactions.
32. `unpause()`: Unpauses the contract.
33. `setLinkTokenAddress(address _link)`: Sets the Chainlink LINK token address.
34. `setOracleAddress(address _oracle)`: Sets the Chainlink oracle address.
35. `setJobId(bytes32 _jobId)`: Sets the Chainlink job ID for external requests.
36. `setBaseAuraCost(uint256 _cost)`: Sets the cost for `enlightenCompanion` interaction.
37. `setFormEvolutionThreshold(uint8 _formLevel, uint256 _auraRequired, uint256 _affinityRequired)`: Configures the requirements for evolving a companion's form.
38. `setAbilityUnlockRequirements(uint8 _abilityIndex, uint8 _formRequired, uint256 _auraRequired)`: Configures the requirements for unlocking a specific ability.
39. `withdrawLink(address recipient)`: Allows the owner to withdraw LINK tokens from the contract.
40. `withdrawEth(address recipient)`: Allows the owner to withdraw ETH from the contract (e.g., from enlightenment fees or Aura Nexus contributions).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title AuraBoundCompanions
 * @dev An ERC721 contract for dynamic, evolving digital companions.
 *      Companions gain Aura Points, develop Affinity, evolve Forms, unlock Abilities,
 *      and are influenced by external data via Chainlink. They also generate
 *      ephemeral 'Whispers' and participate in a shared 'ReflectionPool'.
 */
contract AuraBoundCompanions is ERC721, Ownable, Pausable, ChainlinkClient {
    using Strings for uint256;

    // --- Events ---
    event CompanionMinted(uint256 indexed tokenId, address indexed owner, string essenceHash);
    event AuraGained(uint256 indexed tokenId, uint256 auraPoints);
    event AffinityIncreased(uint256 indexed tokenId, uint256 affinityLevel);
    event FormEvolved(uint256 indexed tokenId, uint8 newFormLevel);
    event AbilityUnlocked(uint256 indexed tokenId, uint8 abilityIndex);
    event ElementalAttunementUpdated(uint256 indexed tokenId, uint8 fire, uint8 water, uint8 air, uint8 earth, uint8 spirit);
    event WhisperManifested(uint256 indexed tokenId, string whisper);
    event ExperienceShared(uint256 indexed tokenId, string experienceHash, bool isGlobal);
    event AuraNexusContributed(address indexed contributor, uint256 amount);

    // --- Enums ---
    enum FormLevel { Seed, Sprout, Bloom, Zenith, Transcendence }

    // Represents different types of abilities a companion can unlock
    enum AbilityType { Fortitude, Insight, Empathy, Resilience, Adaptability, Serenity, Foresight, Harmony }

    // Represents elemental attunements
    struct ElementalAttunement {
        uint8 fire;   // Represents passion, energy, action
        uint8 water;  // Represents emotion, intuition, flow
        uint8 air;    // Represents intellect, communication, freedom
        uint8 earth;  // Represents stability, grounding, growth
        uint8 spirit; // Represents connection, wisdom, transcendence
    }

    // --- Structs ---

    // @dev Main data structure for each AuraBound Companion
    struct Companion {
        string essenceHash;           // Immutable unique identifier (e.g., keccak256 hash of initial traits)
        uint256 auraPoints;           // Accumulated experience/energy
        uint256 affinityLevel;        // Bond strength with owner
        FormLevel formLevel;          // Current evolutionary stage
        ElementalAttunement elementalAttunement; // Current elemental balance
        uint256 unlockedAbilities;    // Bitmask for unlocked abilities (up to 256)
        uint64 lastInteractionTime;   // Timestamp of last meditation/enlightenment
        string currentWhisper;        // Ephemeral insight generated by the companion
        uint64 lastWhisperTime;       // Timestamp of last whisper manifestation
    }

    // @dev Defines requirements for each form evolution
    struct FormDetails {
        uint256 auraRequired;
        uint256 affinityRequired;
        string name; // Name of the form (e.g., "Seedling", "Blooming Spirit")
    }

    // @dev Defines requirements for each ability unlock
    struct AbilityDetails {
        FormLevel formRequired;
        uint256 auraRequired;
        string name; // Name of the ability (e.g., "Aura Shield", "Empathic Resonance")
    }

    // --- State Variables ---

    // Mappings for companion data
    mapping(uint256 => Companion) public companions;
    uint256 private _nextTokenId; // Counter for next available token ID

    // Configuration for interactions and evolution
    uint256 public meditationCooldownDuration = 1 days; // Cooldown for meditation
    uint256 public baseEnlightenmentCost = 0.05 ether; // Cost in ETH for enlightenment
    uint256 public whisperCooldownDuration = 7 days; // Cooldown for manifesting a whisper

    // Form evolution requirements
    mapping(uint8 => FormDetails) public formEvolutionRequirements;

    // Ability unlock requirements
    mapping(uint8 => AbilityDetails) public abilityUnlockRequirements;

    // Reflection Pools
    string[] public globalReflectionHashes; // Shared experiences for all companions
    mapping(uint256 => string[]) public companionReflectionHashes; // Experiences unique to a companion

    // Aura Nexus (conceptual global energy pool)
    uint256 public auraNexusContributionCount;

    // Chainlink configuration
    bytes32 public elementalAttunementJobId;
    uint256 public chainlinkFee = 0.1 * 10**18; // 0.1 LINK (example)

    // --- Constructor ---
    constructor(address _link, address _oracle, bytes32 _jobId)
        ERC721("AuraBound Companion", "ABC")
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
        ChainlinkClient() // Initialize ChainlinkClient
    {
        set                 LinkToken(_link);
        setOracle(_oracle);
        elementalAttunementJobId = _jobId;

        // Initialize Form Evolution Requirements
        formEvolutionRequirements[uint8(FormLevel.Seed)] = FormDetails(0, 0, "Seed"); // Base form
        formEvolutionRequirements[uint8(FormLevel.Sprout)] = FormDetails(100, 50, "Sprout");
        formEvolutionRequirements[uint8(FormLevel.Bloom)] = FormDetails(500, 200, "Bloom");
        formEvolutionRequirements[uint8(FormLevel.Zenith)] = FormDetails(2000, 800, "Zenith");
        formEvolutionRequirements[uint8(FormLevel.Transcendence)] = FormDetails(5000, 2000, "Transcendence");

        // Initialize Ability Unlock Requirements (example abilities)
        abilityUnlockRequirements[uint8(AbilityType.Fortitude)] = AbilityDetails(FormLevel.Sprout, 50);
        abilityUnlockRequirements[uint8(AbilityType.Insight)] = AbilityDetails(FormLevel.Sprout, 75);
        abilityUnlockRequirements[uint8(AbilityType.Empathy)] = AbilityDetails(FormLevel.Bloom, 200);
        abilityUnlockRequirements[uint8(AbilityType.Resilience)] = AbilityDetails(FormLevel.Bloom, 300);
        abilityUnlockRequirements[uint8(AbilityType.Adaptability)] = AbilityDetails(FormLevel.Zenith, 1000);
        abilityUnlockRequirements[uint8(AbilityType.Serenity)] = AbilityDetails(FormLevel.Zenith, 1500);
        abilityUnlockRequirements[uint8(AbilityType.Foresight)] = AbilityDetails(FormLevel.Transcendence, 3000);
        abilityUnlockRequirements[uint8(AbilityType.Harmony)] = AbilityDetails(FormLevel.Transcendence, 4000);
    }

    // --- Core ERC721 & Base Functions ---

    /**
     * @dev Mints a new AuraBound Companion NFT.
     * @param _essenceHash A unique hash representing the companion's immutable core essence.
     *        This could be a hash of initial traits, a seed, or a conceptual "soul print".
     */
    function mintCompanion(string calldata _essenceHash) public whenNotPaused returns (uint256) {
        require(bytes(_essenceHash).length > 0, "Essence hash cannot be empty");
        uint256 newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId);

        companions[newTokenId] = Companion({
            essenceHash: _essenceHash,
            auraPoints: 0,
            affinityLevel: 0,
            formLevel: FormLevel.Seed,
            elementalAttunement: ElementalAttunement(0, 0, 0, 0, 0),
            unlockedAbilities: 0,
            lastInteractionTime: 0,
            currentWhisper: "",
            lastWhisperTime: 0
        });

        emit CompanionMinted(newTokenId, msg.sender, _essenceHash);
        return newTokenId;
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata.
     *      Generates a base64 encoded JSON string with an embedded SVG image,
     *      reflecting the companion's current dynamic state.
     *      This is a gas-intensive operation for complex SVGs, but demonstrates a key advanced concept.
     * @param tokenId The ID of the companion.
     * @return A data URI containing the JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Companion storage c = companions[tokenId];

        string memory name = string(abi.encodePacked("AuraBound Companion #", tokenId.toString()));
        string memory description = string(abi.encodePacked(
            "An evolving digital companion. Current Form: ", formEvolutionRequirements[uint8(c.formLevel)].name,
            ". Aura: ", c.auraPoints.toString(),
            ". Affinity: ", c.affinityLevel.toString(),
            ". Essence: ", c.essenceHash,
            ". Elemental Attunement (F/W/A/E/S): ",
            c.elementalAttunement.fire.toString(), "/",
            c.elementalAttunement.water.toString(), "/",
            c.elementalAttunement.air.toString(), "/",
            c.elementalAttunement.earth.toString(), "/",
            c.elementalAttunement.spirit.toString(),
            ". Current Whisper: ", c.currentWhisper
        ));

        // Construct SVG based on companion's state (simplified for example)
        // In a real scenario, this would be much more complex, potentially involving off-chain rendering or a library.
        string memory svg = string(abi.encodePacked(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 350 350'>",
            "<style>.base { fill: white; font-family: monospace; font-size: 14px; }</style>",
            "<rect width='100%' height='100%' fill='#",
            _getFormColor(c.formLevel), "'/>", // Dynamic background color
            "<text x='50%' y='20%' dominant-baseline='middle' text-anchor='middle' class='base'>", name, "</text>",
            "<text x='50%' y='40%' dominant-baseline='middle' text-anchor='middle' class='base'>Form: ", formEvolutionRequirements[uint8(c.formLevel)].name, "</text>",
            "<text x='50%' y='55%' dominant-baseline='middle' text-anchor='middle' class='base'>Aura: ", c.auraPoints.toString(), "</text>",
            "<text x='50%' y='70%' dominant-baseline='middle' text-anchor='middle' class='base'>Affinity: ", c.affinityLevel.toString(), "</text>",
            "<text x='50%' y='85%' dominant-baseline='middle' text-anchor='middle' class='base'>Whisper: ", c.currentWhisper, "</text>",
            "</svg>"
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '", "description": "', description, '", "image": "data:image/svg+xml;base64,',
            _encodeBase64(bytes(svg)),
            '", "attributes": [',
            '{"trait_type": "Form Level", "value": "', formEvolutionRequirements[uint8(c.formLevel)].name, '"},',
            '{"trait_type": "Aura Points", "value": ', c.auraPoints.toString(), '},',
            '{"trait_type": "Affinity Level", "value": ', c.affinityLevel.toString(), '},',
            '{"trait_type": "Fire Attunement", "value": ', c.elementalAttunement.fire.toString(), '},',
            '{"trait_type": "Water Attunement", "value": ', c.elementalAttunement.water.toString(), '},',
            '{"trait_type": "Air Attunement", "value": ', c.elementalAttunement.air.toString(), '},',
            '{"trait_type": "Earth Attunement", "value": ', c.elementalAttunement.earth.toString(), '},',
            '{"trait_type": "Spirit Attunement", "value": ', c.elementalAttunement.spirit.toString(), '}',
            _getAbilitiesJson(c.unlockedAbilities), // Add unlocked abilities as attributes
            ']}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", _encodeBase64(bytes(json))));
    }

    // --- Companion State & Query Functions ---

    /**
     * @dev Retrieves all core dynamic attributes of a specific companion.
     * @param tokenId The ID of the companion.
     * @return A tuple containing all Companion struct fields.
     */
    function getCompanionDetails(uint256 tokenId)
        public view
        returns (
            string memory essenceHash,
            uint256 auraPoints,
            uint256 affinityLevel,
            FormLevel formLevel,
            ElementalAttunement memory elementalAttunement,
            uint256 unlockedAbilities,
            uint64 lastInteractionTime,
            string memory currentWhisper,
            uint64 lastWhisperTime
        )
    {
        require(_exists(tokenId), "AuraBound: Companion does not exist.");
        Companion storage c = companions[tokenId];
        return (
            c.essenceHash,
            c.auraPoints,
            c.affinityLevel,
            c.formLevel,
            c.elementalAttunement,
            c.unlockedAbilities,
            c.lastInteractionTime,
            c.currentWhisper,
            c.lastWhisperTime
        );
    }

    /**
     * @dev Returns an array of strings representing the unlocked abilities of a companion.
     * @param tokenId The ID of the companion.
     * @return An array of strings, each being the name of an unlocked ability.
     */
    function getCompanionAbilities(uint256 tokenId) public view returns (string[] memory) {
        require(_exists(tokenId), "AuraBound: Companion does not exist.");
        Companion storage c = companions[tokenId];
        string[] memory abilities = new string[](0);
        for (uint8 i = 0; i < uint8(AbilityType.Harmony) + 1; i++) {
            if ((c.unlockedAbilities >> i) & 1 == 1) {
                abilities = _appendString(abilities, abilityUnlockRequirements[i].name);
            }
        }
        return abilities;
    }

    /**
     * @dev Fetches the list of experience hashes specifically associated with a companion.
     * @param tokenId The ID of the companion.
     * @return An array of strings, each an experience hash.
     */
    function getCompanionReflections(uint256 tokenId) public view returns (string[] memory) {
        require(_exists(tokenId), "AuraBound: Companion does not exist.");
        return companionReflectionHashes[tokenId];
    }

    /**
     * @dev Returns the companion's current ephemeral "whisper."
     * @param tokenId The ID of the companion.
     * @return The current whisper string.
     */
    function getCurrentWhisper(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "AuraBound: Companion does not exist.");
        return companions[tokenId].currentWhisper;
    }

    // --- Interaction & Evolution Functions ---

    /**
     * @dev Initiates the bonding process with a newly minted companion.
     *      Can only be called once per companion by its owner.
     * @param tokenId The ID of the companion to bond with.
     */
    function bondWithCompanion(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        Companion storage c = companions[tokenId];
        require(c.lastInteractionTime == 0, "AuraBound: Companion is already bonded.");

        c.lastInteractionTime = uint64(block.timestamp);
        c.auraPoints = 10; // Initial aura
        c.affinityLevel = 1; // Initial affinity
        emit AuraGained(tokenId, 10);
        emit AffinityIncreased(tokenId, 1);
    }

    /**
     * @dev Allows the owner to meditate with their companion, increasing Aura Points and Affinity.
     *      Subject to a cooldown period.
     * @param tokenId The ID of the companion to meditate with.
     */
    function meditateWithCompanion(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        Companion storage c = companions[tokenId];
        require(c.lastInteractionTime > 0, "AuraBound: Companion not bonded yet.");
        require(block.timestamp >= c.lastInteractionTime + meditationCooldownDuration, "AuraBound: Meditation on cooldown.");

        uint256 auraIncrease = 5 + (uint256(c.formLevel) * 2); // Aura increases with form
        uint256 affinityIncrease = 1 + (uint256(c.formLevel) / 2); // Affinity increases slower

        c.auraPoints += auraIncrease;
        c.affinityLevel += affinityIncrease;
        c.lastInteractionTime = uint64(block.timestamp);

        emit AuraGained(tokenId, auraIncrease);
        emit AffinityIncreased(tokenId, affinityIncrease);
    }

    /**
     * @dev Allows an owner to submit a hash representing a unique experience associated with their companion.
     *      This `experienceHash` is conceptually verifiable off-chain (e.g., a hash of a blog post, a game event, a real-world photo).
     *      In a more advanced setup, this could trigger ZKP verification.
     * @param tokenId The ID of the companion.
     * @param experienceHash The hash of the off-chain experience data.
     */
    function shareExperience(uint256 tokenId, string calldata experienceHash) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        require(bytes(experienceHash).length > 0, "Experience hash cannot be empty.");

        companionReflectionHashes[tokenId].push(experienceHash);
        // Optionally, gaining a small amount of Aura/Affinity for sharing experiences
        Companion storage c = companions[tokenId];
        c.auraPoints += 2;
        c.affinityLevel += 1;
        emit AuraGained(tokenId, 2);
        emit AffinityIncreased(tokenId, 1);
        emit ExperienceShared(tokenId, experienceHash, false);
    }

    /**
     * @dev A premium interaction to significantly boost a companion's Aura Points and Affinity.
     * @param tokenId The ID of the companion.
     */
    function enlightenCompanion(uint256 tokenId) public payable whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        require(msg.value >= baseEnlightenmentCost, "AuraBound: Insufficient ETH for enlightenment.");
        Companion storage c = companions[tokenId];

        uint256 auraBoost = 50 + (uint256(c.formLevel) * 10);
        uint256 affinityBoost = 10 + (uint256(c.formLevel) * 2);

        c.auraPoints += auraBoost;
        c.affinityLevel += affinityBoost;
        c.lastInteractionTime = uint64(block.timestamp); // Reset cooldown

        emit AuraGained(tokenId, auraBoost);
        emit AffinityIncreased(tokenId, affinityBoost);
    }

    /**
     * @dev Triggers an attempt to evolve the companion's form level.
     *      Requires meeting specific Aura Points and Affinity Level thresholds for the next form.
     *      Resets some Aura/Affinity upon successful evolution.
     * @param tokenId The ID of the companion to evolve.
     */
    function catalyzeFormEvolution(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        Companion storage c = companions[tokenId];

        uint8 nextFormLevel = uint8(c.formLevel) + 1;
        require(nextFormLevel <= uint8(FormLevel.Transcendence), "AuraBound: Companion is already at max form.");

        FormDetails memory nextFormReqs = formEvolutionRequirements[nextFormLevel];
        require(c.auraPoints >= nextFormReqs.auraRequired, "AuraBound: Not enough Aura Points for evolution.");
        require(c.affinityLevel >= nextFormReqs.affinityRequired, "AuraBound: Not enough Affinity for evolution.");

        c.formLevel = FormLevel(nextFormLevel);
        c.auraPoints = c.auraPoints / 2; // Reset some aura for new growth phase
        c.affinityLevel = c.affinityLevel / 2; // Reset some affinity for new bond
        
        emit FormEvolved(tokenId, nextFormLevel);
    }

    /**
     * @dev Allows an owner to unlock a specific ability for their companion.
     *      Requires the companion to meet specific Form Level and Aura requirements.
     * @param tokenId The ID of the companion.
     * @param abilityIndex The index of the ability to unlock (corresponding to `AbilityType` enum).
     */
    function unlockAbility(uint256 tokenId, uint8 abilityIndex) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        require(abilityIndex <= uint8(AbilityType.Harmony), "AuraBound: Invalid ability index.");
        Companion storage c = companions[tokenId];

        // Check if ability is already unlocked
        require(!_isAbilityUnlocked(c.unlockedAbilities, abilityIndex), "AuraBound: Ability already unlocked.");

        AbilityDetails memory reqs = abilityUnlockRequirements[abilityIndex];
        require(c.formLevel >= reqs.formRequired, "AuraBound: Companion's form is not high enough for this ability.");
        require(c.auraPoints >= reqs.auraRequired, "AuraBound: Not enough Aura Points to unlock this ability.");

        c.unlockedAbilities |= (1 << abilityIndex); // Set the bit for the unlocked ability
        c.auraPoints -= reqs.auraRequired; // Consume aura for unlocking

        emit AbilityUnlocked(tokenId, abilityIndex);
    }

    /**
     * @dev Initiates a Chainlink request to fetch external data (e.g., market sentiment, environmental data).
     *      This data will influence the companion's elemental attunement.
     * @param tokenId The ID of the companion for which to update attunement.
     */
    function requestElementalAttunementUpdate(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        Chainlink.Request memory req = buildChainlinkRequest(elementalAttunementJobId, address(this), this.fulfillElementalAttunementUpdate.selector);
        // Example: Add a specific external adapter parameter, e.g., "get": "https://api.example.com/data"
        // In a real scenario, the adapter would fetch and process data relevant to elemental attunement.
        // For simplicity, we'll simulate a single integer response.
        req.addUint("tokenId", tokenId); // Pass tokenId to the oracle
        sendChainlinkRequest(req, chainlinkFee);
    }

    /**
     * @dev Chainlink callback function to receive and process the external data.
     *      This function is called by the Chainlink oracle when the request is fulfilled.
     *      The `response` value (uint256) is then used to update the companion's elemental attunement.
     *      For simplicity, `response` is mapped to elemental values.
     * @param requestId The ID of the Chainlink request.
     * @param response The data returned by the oracle.
     */
    function fulfillElementalAttunementUpdate(bytes32 requestId, uint256 response)
        public
        recordChainlinkFulfillment(requestId)
    {
        uint256 tokenId = getUint(requestId, "tokenId"); // Retrieve the tokenId from the request
        require(_exists(tokenId), "AuraBound: Target companion does not exist for fulfillment.");
        Companion storage c = companions[tokenId];

        // Simple mapping from response to elemental attunements (example logic)
        // In a real scenario, `response` might be a more complex structure or a hash
        // that the contract then interprets based on a specific algorithm.
        c.elementalAttunement.fire = uint8((response >> 24) & 0xFF);
        c.elementalAttunement.water = uint8((response >> 16) & 0xFF);
        c.elementalAttunement.air = uint8((response >> 8) & 0xFF);
        c.elementalAttunement.earth = uint8(response & 0xFF);
        c.elementalAttunement.spirit = uint8((response >> 32) & 0xFF); // Or another part of the response

        emit ElementalAttunementUpdated(
            tokenId,
            c.elementalAttunement.fire,
            c.elementalAttunement.water,
            c.elementalAttunement.air,
            c.elementalAttunement.earth,
            c.elementalAttunement.spirit
        );
    }

    /**
     * @dev Triggers the companion to generate a new deterministic "whisper" based on its current state.
     *      Whispers are ephemeral insights and change periodically.
     * @param tokenId The ID of the companion.
     */
    function manifestWhisper(uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AuraBound: Caller is not owner or approved.");
        Companion storage c = companions[tokenId];
        require(block.timestamp >= c.lastWhisperTime + whisperCooldownDuration, "AuraBound: Whisper on cooldown.");

        string memory whisperText = _generateWhisper(c);
        c.currentWhisper = whisperText;
        c.lastWhisperTime = uint64(block.timestamp);

        emit WhisperManifested(tokenId, whisperText);
    }

    // --- Community & Global Mechanics Functions ---

    /**
     * @dev Allows any user to contribute a general experience hash to the contract's global Reflection Pool.
     *      These are shared insights or data that might collectively influence all companions.
     * @param reflectionHash The hash of the off-chain reflection data.
     */
    function submitGlobalReflection(string calldata reflectionHash) public whenNotPaused {
        require(bytes(reflectionHash).length > 0, "Reflection hash cannot be empty.");
        globalReflectionHashes.push(reflectionHash);
        emit ExperienceShared(0, reflectionHash, true); // tokenId 0 for global events
    }

    /**
     * @dev Retrieves the list of globally shared experience hashes.
     * @return An array of strings, each a global reflection hash.
     */
    function getGlobalReflections() public view returns (string[] memory) {
        return globalReflectionHashes;
    }

    /**
     * @dev Allows users to contribute ETH to a global "Aura Nexus," conceptually powering
     *      collective companion evolution or future features (e.g., funding a DAO that
     *      builds tools for companions, or providing shared "energy" for events).
     */
    function contributeToAuraNexus() public payable whenNotPaused {
        require(msg.value > 0, "AuraBound: Must send ETH to contribute to Aura Nexus.");
        auraNexusContributionCount++; // Simple counter for conceptual tracking
        emit AuraNexusContributed(msg.sender, msg.value);
    }

    /**
     * @dev Returns the current ETH balance of the Aura Nexus (the contract's balance).
     * @return The current ETH balance.
     */
    function getAuraNexusState() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Admin & Configuration Functions (Owner-only) ---

    /**
     * @dev Pauses core contract functions.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the Chainlink LINK token address.
     * @param _link The address of the LINK token contract.
     */
    function setLinkTokenAddress(address _link) public onlyOwner {
        setLinkToken(_link);
    }

    /**
     * @dev Sets the Chainlink oracle address.
     * @param _oracle The address of the Chainlink oracle.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        setOracle(_oracle);
    }

    /**
     * @dev Sets the Chainlink job ID for external data requests.
     * @param _jobId The Chainlink job ID.
     */
    function setJobId(bytes32 _jobId) public onlyOwner {
        elementalAttunementJobId = _jobId;
    }

    /**
     * @dev Sets the base cost in ETH for the `enlightenCompanion` function.
     * @param _cost The new base enlightenment cost in wei.
     */
    function setBaseAuraCost(uint256 _cost) public onlyOwner {
        baseEnlightenmentCost = _cost;
    }

    /**
     * @dev Configures the requirements for evolving a companion's form.
     * @param _formLevel The target form level (e.g., 1 for Sprout).
     * @param _auraRequired The Aura Points required for this form.
     * @param _affinityRequired The Affinity Level required for this form.
     */
    function setFormEvolutionThreshold(uint8 _formLevel, uint256 _auraRequired, uint256 _affinityRequired) public onlyOwner {
        require(_formLevel > 0 && _formLevel <= uint8(FormLevel.Transcendence), "AuraBound: Invalid form level.");
        formEvolutionRequirements[_formLevel] = FormDetails(_auraRequired, _affinityRequired, formEvolutionRequirements[_formLevel].name); // Keep name, update values
    }

    /**
     * @dev Configures the requirements for unlocking a specific ability.
     * @param _abilityIndex The index of the ability (from `AbilityType` enum).
     * @param _formRequired The minimum Form Level required.
     * @param _auraRequired The Aura Points required.
     */
    function setAbilityUnlockRequirements(uint8 _abilityIndex, uint8 _formRequired, uint256 _auraRequired) public onlyOwner {
        require(_abilityIndex <= uint8(AbilityType.Harmony), "AuraBound: Invalid ability index.");
        require(_formRequired <= uint8(FormLevel.Transcendence), "AuraBound: Invalid form required.");
        abilityUnlockRequirements[_abilityIndex] = AbilityDetails(FormLevel(_formRequired), _auraRequired, abilityUnlockRequirements[_abilityIndex].name); // Keep name, update values
    }

    /**
     * @dev Allows the owner to withdraw LINK tokens from the contract.
     * @param recipient The address to send LINK to.
     */
    function withdrawLink(address recipient) public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(recipient, link.balanceOf(address(this))), "Unable to transfer LINK");
    }

    /**
     * @dev Allows the owner to withdraw ETH from the contract (e.g., enlightenment fees, Aura Nexus contributions).
     * @param recipient The address to send ETH to.
     */
    function withdrawEth(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "AuraBound: No ETH to withdraw.");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Failed to withdraw ETH.");
    }

    // --- Internal/Pure Helper Functions ---

    /**
     * @dev Checks if a specific ability is unlocked based on the bitmask.
     * @param unlockedAbilitiesBitmask The bitmask representing unlocked abilities.
     * @param abilityIndex The index of the ability to check.
     * @return True if the ability is unlocked, false otherwise.
     */
    function _isAbilityUnlocked(uint256 unlockedAbilitiesBitmask, uint8 abilityIndex) internal pure returns (bool) {
        return (unlockedAbilitiesBitmask >> abilityIndex) & 1 == 1;
    }

    /**
     * @dev Generates a simplified SVG background color based on form level.
     * @param form The companion's current form level.
     * @return A hexadecimal color string.
     */
    function _getFormColor(FormLevel form) internal pure returns (string memory) {
        if (form == FormLevel.Seed) return "6B8E23"; // OliveGreen
        if (form == FormLevel.Sprout) return "3CB371"; // MediumSeaGreen
        if (form == FormLevel.Bloom) return "FF69B4"; // HotPink
        if (form == FormLevel.Zenith) return "8A2BE2"; // BlueViolet
        if (form == FormLevel.Transcendence) return "ADD8E6"; // LightBlue (ethereal)
        return "FFFFFF"; // Default
    }

    /**
     * @dev Appends a string to a dynamic array of strings.
     * @param arr The original array.
     * @param str The string to append.
     * @return A new array with the string appended.
     */
    function _appendString(string[] memory arr, string memory str) internal pure returns (string[] memory) {
        string[] memory newArr = new string[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = str;
        return newArr;
    }

    /**
     * @dev Generates the JSON part for unlocked abilities.
     * @param unlockedAbilities The bitmask of unlocked abilities.
     * @return A comma-separated string of JSON ability attributes.
     */
    function _getAbilitiesJson(uint256 unlockedAbilities) internal view returns (string memory) {
        string memory abilitiesJson = "";
        bool first = true;
        for (uint8 i = 0; i < uint8(AbilityType.Harmony) + 1; i++) {
            if (_isAbilityUnlocked(unlockedAbilities, i)) {
                if (!first) {
                    abilitiesJson = string(abi.encodePacked(abilitiesJson, ","));
                }
                abilitiesJson = string(abi.encodePacked(abilitiesJson, '{"trait_type": "Ability", "value": "', abilityUnlockRequirements[i].name, '"}'));
                first = false;
            }
        }
        return abilitiesJson.length > 0 ? string(abi.encodePacked(",", abilitiesJson)) : "";
    }

    /**
     * @dev Simplistic whisper generation based on companion state.
     *      More complex logic (e.g., using a PRNG with block hashes, or off-chain AI) could be used here.
     * @param c The companion struct.
     * @return A randomly (deterministically) generated whisper.
     */
    function _generateWhisper(Companion storage c) internal view returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(c.auraPoints, c.affinityLevel, c.formLevel, block.timestamp, c.essenceHash)));
        
        // Example deterministic "AI" logic
        if (c.auraPoints > 1000 && c.formLevel >= FormLevel.Zenith) {
            return "The cosmos unfolds within me...";
        } else if (c.affinityLevel > 500) {
            return "Your presence illuminates my path.";
        } else if (c.elementalAttunement.spirit > 80) {
            return "Seek harmony in the unseen.";
        } else if (seed % 5 == 0) {
            return "A new dawn beckons.";
        } else if (seed % 5 == 1) {
            return "Listen to the silent whispers of the wind.";
        } else if (seed % 5 == 2) {
            return "Growth begins in stillness.";
        } else if (seed % 5 == 3) {
            return "Embrace the flow.";
        } else {
            return "I feel a shift in the ether.";
        }
    }

    // --- Base64 Encoding (From OpenZeppelin's ERC721URIStorage) ---
    string private constant _BASE64_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function _encodeBase64(bytes memory data) private pure returns (string memory) {
        /// @solidity memory-safe-assembly
        assembly {
            // Load the alphabet and input data
            let alphabet := mload(add(_BASE64_ALPHABET, 32))
            let dataLength := mload(data)

            // Allocate output buffer: 3 bytes of data will become 4 bytes in base64.
            // +2 for padding (max 2 bytes), +1 for trailing zero.
            let outputLength := mul(add(dataLength, 2), 4) // (dataLength + 2) / 3 * 4 -> simplified
            outputLength := div(outputLength, 3)
            let output := mload(0x40) // Current free memory pointer
            mstore(0x40, add(output, add(outputLength, 32))) // Update free memory pointer

            // Encode data
            let i := 0
            let j := output // Pointer to current position in output buffer
            for { } lt(i, dataLength) { } {
                let bytesLeft := sub(dataLength, i)
                let chunk := mload(add(data, add(i, 32))) // Load 3 bytes
                
                // If 3 bytes are available
                if gt(bytesLeft, 2) {
                    mstore8(j, mload(add(alphabet, and(shr(18, chunk), 0x3F)))) // First char
                    mstore8(add(j, 1), mload(add(alphabet, and(shr(12, chunk), 0x3F)))) // Second char
                    mstore8(add(j, 2), mload(add(alphabet, and(shr(6, chunk), 0x3F)))) // Third char
                    mstore8(add(j, 3), mload(add(alphabet, and(chunk, 0x3F)))) // Fourth char
                    i := add(i, 3)
                    j := add(j, 4)
                }
                // If 2 bytes are available
                else if eq(bytesLeft, 2) {
                    mstore8(j, mload(add(alphabet, and(shr(10, chunk), 0x3F))))
                    mstore8(add(j, 1), mload(add(alphabet, and(shr(4, chunk), 0x3F))))
                    mstore8(add(j, 2), mload(add(alphabet, and(shl(2, chunk), 0x3F))))
                    mstore8(add(j, 3), 0x3D) // '=' padding
                    i := add(i, 2)
                    j := add(j, 4)
                }
                // If 1 byte is available
                else {
                    mstore8(j, mload(add(alphabet, and(shr(2, chunk), 0x3F))))
                    mstore8(add(j, 1), mload(add(alphabet, and(shl(4, chunk), 0x3F))))
                    mstore8(add(j, 2), 0x3D) // '=' padding
                    mstore8(add(j, 3), 0x3D) // '=' padding
                    i := add(i, 1)
                    j := add(j, 4)
                }
            }

            // Store length and return string
            mstore(output, outputLength)
            return(output, add(outputLength, 32))
        }
    }
}
```