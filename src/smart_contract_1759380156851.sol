This smart contract, **ChronoEssenceProtocol**, introduces a unique system of adaptive digital companions (NFTs) called "Chronos." These Chronos are not static; they evolve based on user interactions, "memories" of significant on-chain events, and programmable relationships established between users or between Chronos themselves. It integrates concepts of dynamic NFTs, a multi-faceted reputation/relationship graph, and a simulated on-chain "prophecy core" for deterministic, AI-like insights.

---

## ChronoEssenceProtocol: Outline and Function Summary

**Contract Name:** `ChronoEssenceProtocol`

**Core Concepts:**
*   **Chrono (ERC721):** Unique, adaptive digital companions represented as NFTs.
*   **Essence:** Core, evolving attributes (wisdom, vitality, resonance, adaptability, mystery) that define a Chrono's nature.
*   **Memory Fragments:** On-chain records of significant interactions or events that shape a Chrono's Essence and capabilities.
*   **Temporal Relationships:** Programmable social links between addresses (user-to-user) or between Chronos (chrono-to-chrono), affecting interactions and insights.
*   **Prophecy Core:** A simulated on-chain oracle offering deterministic "insights" or "recommendations" based on a Chrono's current Essence, Memories, and Relationships.
*   **Collaborative Glyphs:** Community-driven, multi-stage on-chain projects that Chrono owners can contribute to, impacting their Chronos upon completion.
*   **Temporal Nexus:** A special pool where Chronos can be temporarily deposited to participate in global events, gaining unique memories or evolving.
*   **Whisper System:** An on-chain message board tied to specific Chronos, allowing owners to post and retrieve messages.

---

**Function Summary (26 Functions):**

**I. Core Chrono (ERC721 & Base Logic)**
1.  `constructor()`: Initializes the ERC721 contract, sets the protocol's admin, and defines initial parameters.
2.  `mintGenesisChrono()`: Mints a new Chrono NFT with a randomized initial Essence for the caller. Callable only by the admin or under specific initial conditions.
3.  `getChronoData(uint256 _tokenId)`: Retrieves all core data for a specified Chrono, including its owner, Essence, evolution stage, and last interaction time.
4.  `getChronoEssence(uint256 _tokenId)`: Returns the detailed Essence attributes (wisdom, vitality, etc.) of a Chrono.
5.  `getChronoMemories(uint256 _tokenId)`: Provides a list of all recorded Memory Fragments associated with a Chrono.
6.  `triggerChronoInteraction(uint256 _tokenId)`: Marks a Chrono as recently interacted with, updating its `lastInteractionTime` and potentially triggering minor, predefined Essence shifts.
7.  `engraveMemory(uint256 _tokenId, MemoryType _type, bytes32 _dataHash)`: Internal function to add a new Memory Fragment to a Chrono, marking a significant event.
8.  `evolveChronoEssence(uint256 _tokenId, Essence _essenceShift)`: Internal function to update a Chrono's Essence attributes by applying a specified `_essenceShift`.
9.  `updateChronoEvolutionStage(uint256 _tokenId)`: Internal function that checks and updates a Chrono's `evolutionStage` based on its accumulated Essence and Memories.

**II. Temporal Relationships**
10. `establishUserRelationship(address _target, RelationshipType _type)`: Creates or updates a relationship between `msg.sender` and another user (`_target`) with a specified type and initial strength.
11. `severUserRelationship(address _target)`: Removes an existing user-to-user relationship between `msg.sender` and `_target`.
12. `establishChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId, RelationshipType _type)`: Creates or updates a relationship between two Chronos. Requires `msg.sender` to own `_sourceChronoId`.
13. `severChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId)`: Removes an existing relationship between two Chronos.
14. `getUserRelationship(address _source, address _target)`: Retrieves the details of a relationship between two user addresses.
15. `getChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId)`: Retrieves the details of a relationship between two Chronos.

**III. Adaptive Mechanics & Prophecy Core**
16. `activateChronoAbility(uint256 _tokenId, AbilityType _ability, uint64 _duration)`: Grants a temporary, time-locked ability to a Chrono, provided certain conditions are met (e.g., specific Essence levels or memories). *This action also engraves a memory.*
17. `deactivateExpiredAbilities(uint256 _tokenId)`: Publicly callable function to clean up any expired abilities active on a Chrono.
18. `queryProphecyCore(uint256 _tokenId, EssenceDimension _focus)`: The core "AI-like" function. It deterministically calculates and returns a "prophetic" score or insight based on the Chrono's Essence, Memories, Relationships, and a specified `_focus` dimension.
19. `getRecommendedInteraction(uint256 _tokenId)`: Provides a textual recommendation for the Chrono's owner, suggesting a next action or interaction type based on the Chrono's current state (e.g., "Seek Collaboration," "Meditate for Insight").

**IV. Community & Event Systems**
20. `initiateCollaborativeGlyph(uint256 _glyphId, Essence _targetEffect, uint256 _contributionThreshold)`: Admin-only function to create a new collaborative Glyph project with a target Essence effect and a total contribution threshold.
21. `contributeToGlyph(uint256 _glyphId, uint256 _tokenId, uint256 _amount)`: Allows a Chrono owner to contribute to an active Glyph project. Upon completion, participating Chronos receive specific memories and Essence shifts.
22. `depositIntoTemporalNexus(uint256 _tokenId)`: Locks a Chrono into the Temporal Nexus, making it eligible for participation in global protocol events. *This action engraves a memory.*
23. `withdrawFromTemporalNexus(uint256 _tokenId)`: Allows a Chrono owner to withdraw their Chrono from the Temporal Nexus, provided no active event requires its presence.
24. `triggerNexusEventCompletion(uint256 _eventId, uint256[] calldata _participatingChronos, bytes calldata _eventOutcomeData)`: Admin-only function to process the outcome of a Temporal Nexus event, distributing rewards, memories, or Essence shifts to participating Chronos.
25. `postChronoWhisper(uint256 _tokenId, string memory _message)`: Allows the owner of a Chrono to post a public "whisper" (a short message) associated with that Chrono. *This action also engraves a memory.*
26. `retrieveChronoWhispers(uint256 _tokenId, uint256 _offset, uint256 _limit)`: Retrieves a paginated list of whispers associated with a specific Chrono.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- ChronoEssenceProtocol: Outline and Function Summary ---
//
// Contract Name: ChronoEssenceProtocol
//
// Core Concepts:
// - Chrono (ERC721): Unique, adaptive digital companions represented as NFTs.
// - Essence: Core, evolving attributes (wisdom, vitality, resonance, adaptability, mystery) that define a Chrono's nature.
// - Memory Fragments: On-chain records of significant interactions or events that shape a Chrono's Essence and capabilities.
// - Temporal Relationships: Programmable social links between addresses (user-to-user) or between Chronos (chrono-to-chrono), affecting interactions and insights.
// - Prophecy Core: A simulated on-chain oracle offering deterministic "insights" or "recommendations" based on a Chrono's current Essence, Memories, and Relationships.
// - Collaborative Glyphs: Community-driven, multi-stage on-chain projects that Chrono owners can contribute to, impacting their Chronos upon completion.
// - Temporal Nexus: A special pool where Chronos can be temporarily deposited to participate in global events, gaining unique memories or evolving.
// - Whisper System: An on-chain message board tied to specific Chronos, allowing owners to post and retrieve messages.
//
// Function Summary (26 Functions):
//
// I. Core Chrono (ERC721 & Base Logic)
// 1. constructor(): Initializes the ERC721 contract, sets the protocol's admin, and defines initial parameters.
// 2. mintGenesisChrono(): Mints a new Chrono NFT with a randomized initial Essence for the caller. Callable only by the admin or under specific initial conditions.
// 3. getChronoData(uint256 _tokenId): Retrieves all core data for a specified Chrono, including its owner, Essence, evolution stage, and last interaction time.
// 4. getChronoEssence(uint256 _tokenId): Returns the detailed Essence attributes (wisdom, vitality, etc.) of a Chrono.
// 5. getChronoMemories(uint256 _tokenId): Provides a list of all recorded Memory Fragments associated with a Chrono.
// 6. triggerChronoInteraction(uint256 _tokenId): Marks a Chrono as recently interacted with, updating its `lastInteractionTime` and potentially triggering minor, predefined Essence shifts.
// 7. engraveMemory(uint256 _tokenId, MemoryType _type, bytes32 _dataHash): Internal function to add a new Memory Fragment to a Chrono, marking a significant event.
// 8. evolveChronoEssence(uint256 _tokenId, Essence _essenceShift): Internal function to update a Chrono's Essence attributes by applying a specified `_essenceShift`.
// 9. updateChronoEvolutionStage(uint256 _tokenId): Internal function that checks and updates a Chrono's `evolutionStage` based on its accumulated Essence and Memories.
//
// II. Temporal Relationships
// 10. establishUserRelationship(address _target, RelationshipType _type): Creates or updates a relationship between `msg.sender` and another user (`_target`) with a specified type and initial strength.
// 11. severUserRelationship(address _target): Removes an existing user-to-user relationship between `msg.sender` and `_target`.
// 12. establishChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId, RelationshipType _type): Creates or updates a relationship between two Chronos. Requires `msg.sender` to own `_sourceChronoId`.
// 13. severChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId): Removes an existing relationship between two Chronos.
// 14. getUserRelationship(address _source, address _target): Retrieves the details of a relationship between two user addresses.
// 15. getChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId): Retrieves the details of a relationship between two Chronos.
//
// III. Adaptive Mechanics & Prophecy Core
// 16. activateChronoAbility(uint256 _tokenId, AbilityType _ability, uint64 _duration): Grants a temporary, time-locked ability to a Chrono, provided certain conditions are met (e.g., specific Essence levels or memories). *This action also engraves a memory.*
// 17. deactivateExpiredAbilities(uint256 _tokenId): Publicly callable function to clean up any expired abilities active on a Chrono.
// 18. queryProphecyCore(uint256 _tokenId, EssenceDimension _focus): The core "AI-like" function. It deterministically calculates and returns a "prophetic" score or insight based on the Chrono's Essence, Memories, Relationships, and a specified `_focus` dimension.
// 19. getRecommendedInteraction(uint256 _tokenId): Provides a textual recommendation for the Chrono's owner, suggesting a next action or interaction type based on the Chrono's current state (e.g., "Seek Collaboration," "Meditate for Insight").
//
// IV. Community & Event Systems
// 20. initiateCollaborativeGlyph(uint256 _glyphId, Essence _targetEffect, uint256 _contributionThreshold): Admin-only function to create a new collaborative Glyph project with a target Essence effect and a total contribution threshold.
// 21. contributeToGlyph(uint256 _glyphId, uint256 _tokenId, uint256 _amount): Allows a Chrono owner to contribute to an active Glyph project. Upon completion, participating Chronos receive specific memories and Essence shifts.
// 22. depositIntoTemporalNexus(uint256 _tokenId): Locks a Chrono into the Temporal Nexus, making it eligible for participation in global protocol events. *This action engraves a memory.*
// 23. withdrawFromTemporalNexus(uint256 _tokenId): Allows a Chrono owner to withdraw their Chrono from the Temporal Nexus, provided no active event requires its presence.
// 24. triggerNexusEventCompletion(uint256 _eventId, uint256[] calldata _participatingChronos, bytes calldata _eventOutcomeData): Admin-only function to process the outcome of a Temporal Nexus event, distributing rewards, memories, or Essence shifts to participating Chronos.
// 25. postChronoWhisper(uint256 _tokenId, string memory _message): Allows the owner of a Chrono to post a public "whisper" (a short message) associated with that Chrono. *This action also engraves a memory.*
// 26. retrieveChronoWhispers(uint256 _tokenId, uint256 _offset, uint256 _limit): Retrieves a paginated list of whispers associated with a specific Chrono.
//
// --- End of Outline and Summary ---

contract ChronoEssenceProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---
    Counters.Counter private _tokenIds;

    // --- Enums & Structs ---

    enum EvolutionStage { Hatchling, Adolescent, Evolved, Prime, Transcendental }
    enum MemoryType {
        Genesis, Interaction, RelationshipFormed, RelationshipSevered,
        AbilityActivated, GlyphContribution, GlyphCompletion, NexusDeposit,
        NexusEventOutcome, WhisperPosted, CustomEvent
    }
    enum RelationshipType { Mentor, Collaborator, Ally, Rival, Sync, Echo, Mirror }
    enum AbilityType { FortitudeBoost, ResonanceShield, InsightGlimpse, SwiftTraversal }
    enum EssenceDimension { Wisdom, Vitality, Resonance, Adaptability, Mystery, Overall }

    struct Essence {
        uint16 wisdom;       // Cognitive ability, knowledge acquisition
        uint16 vitality;     // Health, endurance, resilience
        uint16 resonance;    // Connection to others, magical affinity
        uint16 adaptability; // Ability to change, learn new skills
        uint16 mystery;      // Hidden potential, unpredictable traits
    }

    struct MemoryFragment {
        MemoryType fragmentType;
        uint64 timestamp;
        bytes32 dataHash; // Hash of off-chain data or specific on-chain event details
    }

    struct RelationshipData {
        RelationshipType relationshipType;
        uint16 strength; // 0-100, strength of the bond
        uint64 establishedTime;
        uint64 lastUpdatedTime;
    }

    struct ChronoData {
        Essence essence;
        EvolutionStage evolutionStage;
        uint64 lastInteractionTime;
        mapping(AbilityType => uint64) activeAbilities; // AbilityType => expiryTimestamp
        uint256 memoryCount; // To track dynamic array length for memories
        bool isInTemporalNexus; // True if deposited in Nexus
    }

    struct GlyphData {
        Essence targetEssenceEffect;
        uint256 contributionThreshold;
        uint256 currentContribution;
        uint256 contributorCount;
        bool isCompleted;
        mapping(uint256 => uint256) chronoContributions; // tokenId => amount
        uint256[] contributors; // List of tokenIds that contributed
    }

    struct NexusDepositData {
        uint64 depositTime;
        address originalOwner;
        uint256 targetEventId; // If deposited for a specific event
    }

    struct ChronoWhisper {
        uint256 chronoId;
        address sender;
        uint64 timestamp;
        string message;
    }

    // --- Mappings ---
    mapping(uint255 => ChronoData) public chronos;
    mapping(uint255 => MemoryFragment[]) public chronoMemories; // Dynamically sized array for memories
    mapping(address => mapping(address => RelationshipData)) public userRelationships;
    mapping(uint256 => mapping(uint256 => RelationshipData)) public chronoRelationships;
    mapping(uint256 => GlyphData) public glyphs; // glyphId => GlyphData
    mapping(uint256 => NexusDepositData) public nexusDeposits; // tokenId => NexusDepositData
    mapping(uint256 => ChronoWhisper[]) public chronoWhispers; // tokenId => ChronoWhisper[]

    uint256 private _currentProphecyNonce; // Used for pseudo-randomness in prophecy
    uint256 public nextGlyphId = 1;

    // --- Events ---
    event ChronoMinted(uint256 indexed tokenId, address indexed owner, Essence initialEssence);
    event ChronoEssenceEvolved(uint256 indexed tokenId, Essence newEssence);
    event ChronoMemoryEngraved(uint256 indexed tokenId, MemoryType memoryType, bytes32 dataHash);
    event ChronoEvolutionStageUpdated(uint256 indexed tokenId, EvolutionStage newStage);
    event RelationshipEstablished(address indexed source, address indexed target, RelationshipType rType, uint16 strength);
    event ChronoRelationshipEstablished(uint256 indexed sourceChronoId, uint256 indexed targetChronoId, RelationshipType rType, uint16 strength);
    event AbilityActivated(uint256 indexed tokenId, AbilityType ability, uint64 expiryTime);
    event GlyphInitiated(uint256 indexed glyphId, Essence targetEffect, uint256 contributionThreshold);
    event GlyphContribution(uint256 indexed glyphId, uint256 indexed tokenId, uint256 amount);
    event GlyphCompleted(uint256 indexed glyphId, Essence finalEffect);
    event ChronoDepositedInNexus(uint256 indexed tokenId, address indexed owner);
    event ChronoWithdrawnFromNexus(uint256 indexed tokenId, address indexed owner);
    event NexusEventProcessed(uint256 indexed eventId, uint256[] participatingChronos, bytes outcomeData);
    event ChronoWhisperPosted(uint256 indexed tokenId, address indexed sender, string message);
    event ProphecyQueried(uint256 indexed tokenId, EssenceDimension focus, uint256 prophecyResult);


    // --- Constructor ---
    constructor() ERC721("Chrono Essence Protocol", "CHRONO") Ownable(msg.sender) {
        _currentProphecyNonce = block.timestamp;
    }

    // --- Modifiers ---
    modifier onlyChronoOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "Chrono does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of this Chrono");
        _;
    }

    modifier onlyChronoExists(uint256 _tokenId) {
        require(_exists(_tokenId), "Chrono does not exist");
        _;
    }

    modifier notInNexus(uint256 _tokenId) {
        require(!chronos[_tokenId].isInTemporalNexus, "Chrono is currently in Temporal Nexus");
        _;
    }

    modifier inNexus(uint256 _tokenId) {
        require(chronos[_tokenId].isInTemporalNexus, "Chrono is not in Temporal Nexus");
        _;
    }

    // --- I. Core Chrono (ERC721 & Base Logic) ---

    /**
     * @notice Mints a new Chrono NFT with a randomized initial Essence for the caller.
     * @dev Callable only by the admin or under specific initial conditions (e.g., initial public mint window).
     * For this example, only owner can mint.
     */
    function mintGenesisChrono() external onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        // Simple pseudo-random initial Essence for demonstration
        bytes32 randomness = keccak256(abi.encodePacked(block.timestamp, newItemId, msg.sender, block.difficulty));
        Essence memory initialEssence = Essence({
            wisdom: uint16(uint256(randomness) % 10 + 1),        // 1-10
            vitality: uint16(uint256(randomness >> 16) % 10 + 1), // 1-10
            resonance: uint16(uint256(randomness >> 32) % 10 + 1), // 1-10
            adaptability: uint16(uint256(randomness >> 48) % 10 + 1), // 1-10
            mystery: uint16(uint256(randomness >> 64) % 5 + 1)    // 1-5
        });

        _safeMint(msg.sender, newItemId);
        chronos[newItemId].essence = initialEssence;
        chronos[newItemId].evolutionStage = EvolutionStage.Hatchling;
        chronos[newItemId].lastInteractionTime = uint64(block.timestamp);
        chronos[newItemId].memoryCount = 0; // Initialize memory count
        
        _engraveMemory(newItemId, MemoryType.Genesis, keccak256(abi.encodePacked(initialEssence.wisdom, initialEssence.vitality)));

        emit ChronoMinted(newItemId, msg.sender, initialEssence);
    }

    /**
     * @notice Retrieves all core data for a specified Chrono.
     * @param _tokenId The ID of the Chrono.
     * @return ChronoData struct containing essence, stage, last interaction, and nexus status.
     */
    function getChronoData(uint256 _tokenId) public view onlyChronoExists(_tokenId) returns (
        Essence memory essence,
        EvolutionStage evolutionStage,
        uint64 lastInteractionTime,
        bool isInTemporalNexus
    ) {
        ChronoData storage chrono = chronos[_tokenId];
        essence = chrono.essence;
        evolutionStage = chrono.evolutionStage;
        lastInteractionTime = chrono.lastInteractionTime;
        isInTemporalNexus = chrono.isInTemporalNexus;
    }

    /**
     * @notice Returns the current Essence attributes of a Chrono.
     * @param _tokenId The ID of the Chrono.
     * @return Essence struct.
     */
    function getChronoEssence(uint256 _tokenId) public view onlyChronoExists(_tokenId) returns (Essence memory) {
        return chronos[_tokenId].essence;
    }

    /**
     * @notice Provides a list of all recorded Memory Fragments associated with a Chrono.
     * @param _tokenId The ID of the Chrono.
     * @return An array of MemoryFragment structs.
     */
    function getChronoMemories(uint256 _tokenId) public view onlyChronoExists(_tokenId) returns (MemoryFragment[] memory) {
        return chronoMemories[_tokenId];
    }

    /**
     * @notice Marks a Chrono as recently interacted with, updating its `lastInteractionTime` and potentially triggering minor Essence shifts.
     * @param _tokenId The ID of the Chrono.
     */
    function triggerChronoInteraction(uint256 _tokenId) external onlyChronoOwner(_tokenId) {
        ChronoData storage chrono = chronos[_tokenId];
        chrono.lastInteractionTime = uint64(block.timestamp);

        // Minor essence shift on interaction (e.g., small adaptability boost)
        Essence memory shift = Essence({
            wisdom: 0, vitality: 0, resonance: 0, adaptability: 1, mystery: 0
        });
        _evolveChronoEssence(_tokenId, shift);
        _engraveMemory(_tokenId, MemoryType.Interaction, keccak256(abi.encodePacked("UserInteraction")));

        // Check for evolution stage update
        _updateChronoEvolutionStage(_tokenId);
    }

    /**
     * @dev Internal function to add a new Memory Fragment to a Chrono.
     * @param _tokenId The ID of the Chrono.
     * @param _type The type of memory fragment.
     * @param _dataHash A hash representing associated data (e.g., IPFS hash, event ID).
     */
    function _engraveMemory(uint256 _tokenId, MemoryType _type, bytes32 _dataHash) internal onlyChronoExists(_tokenId) {
        chronoMemories[_tokenId].push(MemoryFragment({
            fragmentType: _type,
            timestamp: uint64(block.timestamp),
            dataHash: _dataHash
        }));
        chronos[_tokenId].memoryCount++;
        emit ChronoMemoryEngraved(_tokenId, _type, _dataHash);
    }

    /**
     * @dev Internal function to update a Chrono's Essence attributes.
     * Caps attributes at 100 for simplicity.
     * @param _tokenId The ID of the Chrono.
     * @param _essenceShift The Essence struct containing values to add to current essence.
     */
    function _evolveChronoEssence(uint256 _tokenId, Essence memory _essenceShift) internal onlyChronoExists(_tokenId) {
        ChronoData storage chrono = chronos[_tokenId];
        chrono.essence.wisdom = uint16(SafeMath.min(chrono.essence.wisdom.add(_essenceShift.wisdom), 100));
        chrono.essence.vitality = uint16(SafeMath.min(chrono.essence.vitality.add(_essenceShift.vitality), 100));
        chrono.essence.resonance = uint16(SafeMath.min(chrono.essence.resonance.add(_essenceShift.resonance), 100));
        chrono.essence.adaptability = uint16(SafeMath.min(chrono.essence.adaptability.add(_essenceShift.adaptability), 100));
        chrono.essence.mystery = uint16(SafeMath.min(chrono.essence.mystery.add(_essenceShift.mystery), 50)); // Mystery might have a lower cap
        emit ChronoEssenceEvolved(_tokenId, chrono.essence);
    }

    /**
     * @dev Internal function that checks and updates a Chrono's `evolutionStage` based on its accumulated Essence and Memories.
     */
    function _updateChronoEvolutionStage(uint256 _tokenId) internal {
        ChronoData storage chrono = chronos[_tokenId];
        EvolutionStage currentStage = chrono.evolutionStage;
        EvolutionStage newStage = currentStage;

        uint256 totalEssence = chrono.essence.wisdom.add(chrono.essence.vitality).add(chrono.essence.resonance).add(chrono.essence.adaptability).add(chrono.essence.mystery);
        uint256 memoryCount = chronos[_tokenId].memoryCount;

        if (totalEssence >= 200 && memoryCount >= 10 && currentStage < EvolutionStage.Transcendental) {
            newStage = EvolutionStage.Transcendental;
        } else if (totalEssence >= 150 && memoryCount >= 7 && currentStage < EvolutionStage.Prime) {
            newStage = EvolutionStage.Prime;
        } else if (totalEssence >= 100 && memoryCount >= 5 && currentStage < EvolutionStage.Evolved) {
            newStage = EvolutionStage.Evolved;
        } else if (totalEssence >= 50 && memoryCount >= 3 && currentStage < EvolutionStage.Adolescent) {
            newStage = EvolutionStage.Adolescent;
        }

        if (newStage != currentStage) {
            chrono.evolutionStage = newStage;
            emit ChronoEvolutionStageUpdated(_tokenId, newStage);
        }
    }

    // --- II. Temporal Relationships ---

    /**
     * @notice Creates or updates a relationship between `msg.sender` and another user (`_target`).
     * @param _target The address of the target user.
     * @param _type The type of relationship to establish.
     */
    function establishUserRelationship(address _target, RelationshipType _type) external {
        require(msg.sender != _target, "Cannot establish relationship with self");
        
        RelationshipData storage rel = userRelationships[msg.sender][_target];
        if (rel.establishedTime == 0) {
            rel.establishedTime = uint64(block.timestamp);
            rel.strength = 10; // Initial strength
            _engraveMemory(
                _tokenIds.current(), // Assuming current highest ID as a proxy or use a default Chrono if no user Chrono
                MemoryType.RelationshipFormed,
                keccak256(abi.encodePacked(_target, _type))
            );
        }
        rel.relationshipType = _type;
        rel.strength = uint16(SafeMath.min(rel.strength.add(5), 100)); // Increase strength slightly
        rel.lastUpdatedTime = uint64(block.timestamp);

        emit RelationshipEstablished(msg.sender, _target, _type, rel.strength);
    }

    /**
     * @notice Removes an existing user-to-user relationship between `msg.sender` and `_target`.
     * @param _target The address of the target user.
     */
    function severUserRelationship(address _target) external {
        require(userRelationships[msg.sender][_target].establishedTime != 0, "No existing relationship to sever.");
        delete userRelationships[msg.sender][_target];
        // Mirror for _target's perspective if symmetric relationship
        delete userRelationships[_target][msg.sender];
        _engraveMemory(
            _tokenIds.current(), // Proxy Chrono ID
            MemoryType.RelationshipSevered,
            keccak256(abi.encodePacked(_target, "UserRelationship"))
        );
        emit RelationshipEstablished(msg.sender, _target, RelationshipType(0), 0); // Emit with 0 strength to indicate severance
    }

    /**
     * @notice Creates or updates a relationship between two Chronos. Requires `msg.sender` to own `_sourceChronoId`.
     * @param _sourceChronoId The ID of the Chrono owned by `msg.sender`.
     * @param _targetChronoId The ID of the target Chrono.
     * @param _type The type of relationship.
     */
    function establishChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId, RelationshipType _type)
        external
        onlyChronoOwner(_sourceChronoId)
        onlyChronoExists(_targetChronoId)
    {
        require(_sourceChronoId != _targetChronoId, "Cannot establish relationship with self Chrono.");

        RelationshipData storage rel = chronoRelationships[_sourceChronoId][_targetChronoId];
        if (rel.establishedTime == 0) {
            rel.establishedTime = uint64(block.timestamp);
            rel.strength = 20; // Initial strength for Chrono relationships
            _engraveMemory(_sourceChronoId, MemoryType.RelationshipFormed, keccak256(abi.encodePacked(_targetChronoId, _type)));
        }
        rel.relationshipType = _type;
        rel.strength = uint16(SafeMath.min(rel.strength.add(10), 100));
        rel.lastUpdatedTime = uint64(block.timestamp);

        emit ChronoRelationshipEstablished(_sourceChronoId, _targetChronoId, _type, rel.strength);
    }

    /**
     * @notice Removes an existing relationship between two Chronos.
     * @param _sourceChronoId The ID of the Chrono owned by `msg.sender`.
     * @param _targetChronoId The ID of the target Chrono.
     */
    function severChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId)
        external
        onlyChronoOwner(_sourceChronoId)
    {
        require(chronoRelationships[_sourceChronoId][_targetChronoId].establishedTime != 0, "No existing Chrono relationship to sever.");
        delete chronoRelationships[_sourceChronoId][_targetChronoId];
        // If chrono relationships are symmetric, mirror the deletion
        if (ownerOf(_targetChronoId) == msg.sender) { // Only delete symmetric if owner also controls target
             delete chronoRelationships[_targetChronoId][_sourceChronoId];
        }
        _engraveMemory(_sourceChronoId, MemoryType.RelationshipSevered, keccak256(abi.encodePacked(_targetChronoId, "ChronoRelationship")));
        emit ChronoRelationshipEstablished(_sourceChronoId, _targetChronoId, RelationshipType(0), 0);
    }

    /**
     * @notice Retrieves the details of a relationship between two user addresses.
     * @param _source The address of the source user.
     * @param _target The address of the target user.
     * @return RelationshipData struct.
     */
    function getUserRelationship(address _source, address _target) external view returns (RelationshipData memory) {
        return userRelationships[_source][_target];
    }

    /**
     * @notice Retrieves the details of a relationship between two Chronos.
     * @param _sourceChronoId The ID of the source Chrono.
     * @param _targetChronoId The ID of the target Chrono.
     * @return RelationshipData struct.
     */
    function getChronoRelationship(uint256 _sourceChronoId, uint256 _targetChronoId) external view returns (RelationshipData memory) {
        return chronoRelationships[_sourceChronoId][_targetChronoId];
    }

    // --- III. Adaptive Mechanics & Prophecy Core ---

    /**
     * @notice Grants a temporary, time-locked ability to a Chrono.
     * @dev Requires specific conditions (e.g., certain Essence levels, presence of memories).
     * @param _tokenId The ID of the Chrono.
     * @param _ability The type of ability to activate.
     * @param _duration The duration in seconds for which the ability is active.
     */
    function activateChronoAbility(uint256 _tokenId, AbilityType _ability, uint64 _duration)
        external
        onlyChronoOwner(_tokenId)
    {
        ChronoData storage chrono = chronos[_tokenId];
        
        // Example condition: FortitudeBoost requires high vitality
        if (_ability == AbilityType.FortitudeBoost) {
            require(chrono.essence.vitality >= 50, "Not enough vitality for FortitudeBoost");
        }
        // Add more conditions for other abilities

        uint64 expiryTime = uint64(block.timestamp + _duration);
        chrono.activeAbilities[_ability] = expiryTime;
        _engraveMemory(_tokenId, MemoryType.AbilityActivated, keccak256(abi.encodePacked(uint8(_ability), expiryTime)));

        emit AbilityActivated(_tokenId, _ability, expiryTime);
    }

    /**
     * @notice Publicly callable function to clean up any expired abilities active on a Chrono.
     * @param _tokenId The ID of the Chrono.
     */
    function deactivateExpiredAbilities(uint256 _tokenId) external onlyChronoOwner(_tokenId) {
        ChronoData storage chrono = chronos[_tokenId];
        bool deactivatedAny = false;

        // Iterate through possible ability types (could be optimized with a list of active abilities)
        if (chrono.activeAbilities[AbilityType.FortitudeBoost] != 0 && chrono.activeAbilities[AbilityType.FortitudeBoost] < block.timestamp) {
            delete chrono.activeAbilities[AbilityType.FortitudeBoost];
            deactivatedAny = true;
        }
        if (chrono.activeAbilities[AbilityType.ResonanceShield] != 0 && chrono.activeAbilities[AbilityType.ResonanceShield] < block.timestamp) {
            delete chrono.activeAbilities[AbilityType.ResonanceShield];
            deactivatedAny = true;
        }
        if (chrono.activeAbilities[AbilityType.InsightGlimpse] != 0 && chrono.activeAbilities[AbilityType.InsightGlimpse] < block.timestamp) {
            delete chrono.activeAbilities[AbilityType.InsightGlimpse];
            deactivatedAny = true;
        }
        if (chrono.activeAbilities[AbilityType.SwiftTraversal] != 0 && chrono.activeAbilities[AbilityType.SwiftTraversal] < block.timestamp) {
            delete chrono.activeAbilities[AbilityType.SwiftTraversal];
            deactivatedAny = true;
        }

        if (!deactivatedAny) {
            revert("No expired abilities to deactivate.");
        }
    }

    /**
     * @notice The core "AI-like" function. It deterministically calculates and returns a "prophetic" score or insight
     * based on the Chrono's Essence, Memories, Relationships, and a specified `_focus` dimension.
     * @dev This is a *simulated* oracle; all calculations are on-chain and deterministic.
     * @param _tokenId The ID of the Chrono to query.
     * @param _focus The Essence dimension to focus the prophecy on.
     * @return A uint256 representing a calculated "prophetic" score.
     */
    function queryProphecyCore(uint256 _tokenId, EssenceDimension _focus) public returns (uint256) {
        ChronoData storage chrono = chronos[_tokenId];
        Essence memory currentEssence = chrono.essence;
        uint256 totalEssence = currentEssence.wisdom.add(currentEssence.vitality).add(currentEssence.resonance).add(currentEssence.adaptability).add(currentEssence.mystery);
        
        uint256 prophecyScore = 0;

        // Base score from focused Essence attribute
        if (_focus == EssenceDimension.Wisdom) prophecyScore = currentEssence.wisdom;
        else if (_focus == EssenceDimension.Vitality) prophecyScore = currentEssence.vitality;
        else if (_focus == EssenceDimension.Resonance) prophecyScore = currentEssence.resonance;
        else if (_focus == EssenceDimension.Adaptability) prophecyScore = currentEssence.adaptability;
        else if (_focus == EssenceDimension.Mystery) prophecyScore = currentEssence.mystery;
        else if (_focus == EssenceDimension.Overall) prophecyScore = totalEssence;

        // Influence from memories (e.g., each memory adds a small bonus)
        prophecyScore = prophecyScore.add(chronoMemories[_tokenId].length.mul(5));

        // Influence from Chrono relationships
        // (Iterating over mappings is not direct in Solidity, this is a conceptual sum)
        // In a real scenario, this would involve more complex lookup or pre-calculated metrics.
        // For demonstration, we'll use a simplified hash-based pseudo-random factor.
        _currentProphecyNonce = uint256(keccak256(abi.encodePacked(_currentProphecyNonce, _tokenId, block.timestamp, block.difficulty)));
        prophecyScore = prophecyScore.add(uint256(_currentProphecyNonce % 20)); // Add a small "relationship" random factor

        // Factor in Evolution Stage
        prophecyScore = prophecyScore.add(uint256(chrono.evolutionStage).mul(10));

        emit ProphecyQueried(_tokenId, _focus, prophecyScore);
        return prophecyScore;
    }

    /**
     * @notice Provides a textual recommendation for the Chrono's owner, suggesting a next action or interaction type
     * based on the Chrono's current state (e.g., "Seek Collaboration," "Meditate for Insight").
     * @param _tokenId The ID of the Chrono.
     * @return A string containing the recommendation.
     */
    function getRecommendedInteraction(uint256 _tokenId) public view onlyChronoExists(_tokenId) returns (string memory) {
        ChronoData storage chrono = chronos[_tokenId];
        Essence memory e = chrono.essence;

        // Prioritize low stats or recent inactivity
        if (block.timestamp - chrono.lastInteractionTime > 7 days) {
            return "Your Chrono seeks connection. Consider interacting with it more frequently.";
        }
        if (e.wisdom < 20) return "Meditate for Insight: Focus on wisdom-enhancing activities.";
        if (e.vitality < 20) return "Seek Resilience: Engage in activities that boost vitality.";
        if (e.resonance < 20) return "Forge Bonds: Explore relationships with other Chronos or users.";
        if (e.adaptability < 20) return "Embrace Change: Challenge your Chrono with new experiences.";
        if (e.mystery < 10) return "Unravel Secrets: Delve into unknown aspects of its being.";

        // Recommendations based on combination or stage
        if (chrono.evolutionStage < EvolutionStage.Evolved && chronoMemories[_tokenId].length < 5) {
            return "Seek Growth: Contribute to a Glyph to gain new memories.";
        }
        if (chrono.isInTemporalNexus) {
            return "Participate in Nexus: Your Chrono is ready for collective events.";
        }
        
        return "Maintain Balance: Continue exploring various interactions and relationships.";
    }

    // --- IV. Community & Event Systems ---

    /**
     * @notice Admin-only function to create a new collaborative Glyph project.
     * @param _glyphId A unique ID for the Glyph.
     * @param _targetEffect The Essence effect applied to Chronos upon glyph completion.
     * @param _contributionThreshold The total amount of contribution needed to complete the Glyph.
     */
    function initiateCollaborativeGlyph(uint256 _glyphId, Essence memory _targetEffect, uint256 _contributionThreshold) external onlyOwner {
        require(glyphs[_glyphId].contributionThreshold == 0, "Glyph with this ID already exists.");
        glyphs[_glyphId] = GlyphData({
            targetEssenceEffect: _targetEffect,
            contributionThreshold: _contributionThreshold,
            currentContribution: 0,
            contributorCount: 0,
            isCompleted: false,
            contributors: new uint256[](0) // Initialize an empty array
        });
        nextGlyphId = _glyphId.add(1); // Increment for next suggested ID
        emit GlyphInitiated(_glyphId, _targetEffect, _contributionThreshold);
    }

    /**
     * @notice Allows a Chrono owner to contribute to an active Glyph project.
     * Upon completion, participating Chronos receive specific memories and Essence shifts.
     * @param _glyphId The ID of the Glyph to contribute to.
     * @param _tokenId The ID of the Chrono making the contribution.
     * @param _amount The amount of contribution (e.g., a token, or simply a unit of 'effort').
     */
    function contributeToGlyph(uint256 _glyphId, uint256 _tokenId, uint256 _amount)
        external
        onlyChronoOwner(_tokenId)
    {
        GlyphData storage glyph = glyphs[_glyphId];
        require(glyph.contributionThreshold > 0, "Glyph does not exist or not initiated.");
        require(!glyph.isCompleted, "Glyph is already completed.");
        require(_amount > 0, "Contribution amount must be positive.");

        glyph.currentContribution = glyph.currentContribution.add(_amount);
        
        if (glyph.chronoContributions[_tokenId] == 0) {
            glyph.contributors.push(_tokenId);
            glyph.contributorCount++;
        }
        glyph.chronoContributions[_tokenId] = glyph.chronoContributions[_tokenId].add(_amount);

        _engraveMemory(_tokenId, MemoryType.GlyphContribution, keccak256(abi.encodePacked(_glyphId, _amount)));
        emit GlyphContribution(_glyphId, _tokenId, _amount);

        if (glyph.currentContribution >= glyph.contributionThreshold) {
            glyph.isCompleted = true;
            // Distribute effects to all contributors
            for (uint256 i = 0; i < glyph.contributors.length; i++) {
                uint256 contributorChronoId = glyph.contributors[i];
                _evolveChronoEssence(contributorChronoId, glyph.targetEssenceEffect);
                _engraveMemory(contributorChronoId, MemoryType.GlyphCompletion, keccak256(abi.encodePacked(_glyphId, glyph.targetEssenceEffect.wisdom)));
                _updateChronoEvolutionStage(contributorChronoId);
            }
            emit GlyphCompleted(_glyphId, glyph.targetEssenceEffect);
        }
    }

    /**
     * @notice Locks a Chrono into the Temporal Nexus, making it eligible for participation in global protocol events.
     * @param _tokenId The ID of the Chrono to deposit.
     */
    function depositIntoTemporalNexus(uint256 _tokenId) external onlyChronoOwner(_tokenId) notInNexus(_tokenId) {
        chronos[_tokenId].isInTemporalNexus = true;
        nexusDeposits[_tokenId] = NexusDepositData({
            depositTime: uint64(block.timestamp),
            originalOwner: msg.sender,
            targetEventId: 0 // Can be set if for a specific event
        });
        _engraveMemory(_tokenId, MemoryType.NexusDeposit, keccak256(abi.encodePacked(block.timestamp, "Deposit")));
        emit ChronoDepositedInNexus(_tokenId, msg.sender);
    }

    /**
     * @notice Allows a Chrono owner to withdraw their Chrono from the Temporal Nexus.
     * @dev Currently, no checks for active events that might prevent withdrawal.
     * @param _tokenId The ID of the Chrono to withdraw.
     */
    function withdrawFromTemporalNexus(uint256 _tokenId) external onlyChronoOwner(_tokenId) inNexus(_tokenId) {
        // Add checks here if Chrono is participating in an active event.
        // For simplicity, it's always withdrawable if it's in the Nexus.
        chronos[_tokenId].isInTemporalNexus = false;
        delete nexusDeposits[_tokenId];
        _engraveMemory(_tokenId, MemoryType.CustomEvent, keccak256(abi.encodePacked(block.timestamp, "NexusWithdrawal")));
        emit ChronoWithdrawnFromNexus(_tokenId, msg.sender);
    }

    /**
     * @notice Admin-only function to process the outcome of a Temporal Nexus event.
     * Distributes rewards, memories, or Essence shifts to participating Chronos.
     * @param _eventId A unique ID for the Nexus event.
     * @param _participatingChronos An array of Chrono IDs that participated in the event.
     * @param _eventOutcomeData Arbitrary bytes data describing the event outcome.
     */
    function triggerNexusEventCompletion(uint256 _eventId, uint256[] calldata _participatingChronos, bytes calldata _eventOutcomeData) external onlyOwner {
        require(_participatingChronos.length > 0, "No participating Chronos for event.");
        
        for (uint256 i = 0; i < _participatingChronos.length; i++) {
            uint256 chronoId = _participatingChronos[i];
            require(chronos[chronoId].isInTemporalNexus, "Chrono not in Nexus for this event.");

            // Example outcome: boost vitality and add a NexusEventOutcome memory
            Essence memory outcomeEffect = Essence({
                wisdom: 0, vitality: 5, resonance: 0, adaptability: 2, mystery: 0
            });
            _evolveChronoEssence(chronoId, outcomeEffect);
            _engraveMemory(chronoId, MemoryType.NexusEventOutcome, keccak256(abi.encodePacked(_eventId, _eventOutcomeData)));
            _updateChronoEvolutionStage(chronoId);
            
            // Optionally, withdraw Chrono from Nexus after event
            chronos[chronoId].isInTemporalNexus = false;
            delete nexusDeposits[chronoId];
            emit ChronoWithdrawnFromNexus(chronoId, ownerOf(chronoId));
        }
        emit NexusEventProcessed(_eventId, _participatingChronos, _eventOutcomeData);
    }

    /**
     * @notice Allows the owner of a Chrono to post a public "whisper" (a short message) associated with that Chrono.
     * @param _tokenId The ID of the Chrono.
     * @param _message The message to post (max 256 characters).
     */
    function postChronoWhisper(uint256 _tokenId, string memory _message) external onlyChronoOwner(_tokenId) {
        require(bytes(_message).length > 0 && bytes(_message).length <= 256, "Whisper must be between 1 and 256 characters.");

        chronoWhispers[_tokenId].push(ChronoWhisper({
            chronoId: _tokenId,
            sender: msg.sender,
            timestamp: uint64(block.timestamp),
            message: _message
        }));

        _engraveMemory(_tokenId, MemoryType.WhisperPosted, keccak256(abi.encodePacked(_message)));
        emit ChronoWhisperPosted(_tokenId, msg.sender, _message);
    }

    /**
     * @notice Retrieves a paginated list of whispers associated with a specific Chrono.
     * @param _tokenId The ID of the Chrono.
     * @param _offset The starting index for retrieval.
     * @param _limit The maximum number of whispers to retrieve.
     * @return An array of ChronoWhisper structs.
     */
    function retrieveChronoWhispers(uint256 _tokenId, uint256 _offset, uint256 _limit) external view onlyChronoExists(_tokenId) returns (ChronoWhisper[] memory) {
        ChronoWhisper[] storage whispers = chronoWhispers[_tokenId];
        uint256 total = whispers.length;
        if (_offset >= total) {
            return new ChronoWhisper[](0);
        }

        uint256 end = _offset.add(_limit);
        if (end > total) {
            end = total;
        }

        uint256 count = end.sub(_offset);
        ChronoWhisper[] memory result = new ChronoWhisper[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = whispers[_offset.add(i)];
        }
        return result;
    }

    // --- ERC721 Overrides (Standard, not counted in 20+) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Additional logic could be added here, e.g., pause Chrono abilities on transfer
        if (from != address(0) && chronos[tokenId].isInTemporalNexus) {
            revert("Cannot transfer Chrono while it is in the Temporal Nexus.");
        }
    }
}
```