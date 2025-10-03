This smart contract, `EvolvingDigitalEntities`, introduces an advanced form of dynamic NFTs, where each token represents a unique digital creature with a set of evolving attributes, a lifecycle influenced by owner interactions and external AI oracles, and meta-game mechanics like reproduction and species evolution.

The core idea moves beyond static images, creating digital entities that truly *live* and *change* on the blockchain.

---

**EvolvingDigitalEntities (EDE) Smart Contract**

**Outline:**
1.  **State Variables & Data Structures:** Defines the core EDE struct, global parameters, and configuration settings.
2.  **Events:** Declares events for tracking key actions and state changes.
3.  **Constructor & Initialization:** Sets up the ERC721 basics, initial roles, and default game parameters.
4.  **ERC721 Standard Functions:** Includes minting, `tokenURI` (dynamically generating metadata), and a function to update the base URI.
5.  **EDE Core Logic (Attribute Management, Lifecycle):** Functions to get EDE attributes (applying decay), a global time tick, reproduction, and merging of EDEs.
6.  **Owner Interaction & Nurturing:** Various actions owners can take to influence their EDE's attributes, such as nurturing, educating, socializing, healing, and feeding. Also includes appearance customization.
7.  **Oracle & AI Integration:** Functions for a designated AI Oracle to update global AI predictions and individual EDE traits, bringing external intelligence on-chain.
8.  **Resource Management (Nourishment Token):** Integrates an ERC20 token for game mechanics, allowing users to deposit/withdraw nourishment and for EDE actions to consume it.
9.  **Global & Meta-Game Mechanics:** Functions to query global AI predictions and species evolution levels, and to adjust costs and criteria for game actions.
10. **Utility & View Functions:** Helpers for clamping values and generating pseudo-randomness (for game mechanics, not security).
11. **Access Control:** Implements roles for owner, AI Oracle, and timekeeper using OpenZeppelin's Ownable.

---

**Function Summary:**

**[ERC721 & Core Minting]**
1.  `constructor(string memory name, string memory symbol, string memory baseURI_)`: Initializes the ERC721 contract, sets a base URI for metadata, and designates the deployer as initial owner, AI oracle, and timekeeper.
2.  `mintEDE(address recipient, string memory initialAppearanceCode)`: Mints a new Evolving Digital Entity (EDE) to a specified recipient with an initial set of attributes and appearance.
3.  `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for a given EDE. This URI will point to a resolver that can query the EDE's on-chain attributes to generate real-time metadata.
4.  `setBaseURI(string memory newBaseURI)`: Allows the contract owner to update the base URI for metadata resolution.

**[EDE Core State & Lifecycle]**
5.  `getEDEAttributes(uint256 tokenId)`: Retrieves all current attributes (health, mood, intelligence, etc.) of a specific EDE, first applying any decay based on time elapsed since last interaction.
6.  `_applyDecayWithTokenId(uint256 tokenId, EDE storage ede)`: Internal helper to calculate and apply time-based decay to an EDE's attributes, updating its state and `lastInteractionTime`.
7.  `progressTimeTick()`: Callable by a designated `timekeeper` role to advance the global ecosystem "era." This function can be used to trigger global events or modify ecosystem parameters without iterating over all EDEs.
8.  `reproduceEDE(uint256 parent1Id, uint256 parent2Id)`: Enables two owner-controlled EDEs to reproduce, creating a new offspring EDE. Requires parents to meet specific health, mood, and energy criteria, and consumes nourishment tokens.
9.  `mergeEDEs(uint256 primaryId, uint256 secondaryId)`: Allows an owner to merge two of their EDEs. The secondary EDE is burned, and its essence boosts the attributes of the primary EDE, enhancing it.

**[Owner Interaction & Nurturing]**
10. `nurtureEDE(uint256 tokenId)`: A general interaction that improves an EDE's mood and health, costing nourishment tokens and consuming a small amount of its energy. Applies decay first.
11. `educateEDE(uint256 tokenId)`: Improves an EDE's intelligence and creativity, costing nourishment tokens and energy. Applies decay first.
12. `socializeEDE(uint256 tokenId)`: Enhances an EDE's social score and mood, costing nourishment tokens and energy. Applies decay first.
13. `healEDE(uint256 tokenId)`: Restores a significant portion of an EDE's health, costing more nourishment and energy than basic interactions. Applies decay first.
14. `feedEDE(uint256 tokenId)`: Replenishes an EDE's energy (crucial for performing other actions) and slightly improves its mood, costing nourishment tokens. Applies decay first.
15. `customizeAppearance(uint256 tokenId, string memory newAppearanceCode)`: Allows the owner to update the `appearanceCode` string of their EDE, which can be interpreted by off-chain renderers to change the NFT's visual representation.

**[Oracle & AI Integration]**
16. `setAIAgentOracle(address oracleAddress)`: Sets the address of the trusted AI agent oracle (owner-only). This oracle provides external AI insights.
17. `updateGlobalAIPrediction(uint256 predictionValue)`: Called by the AI agent oracle to update a global AI-driven environmental sentiment or event score, influencing the entire EDE ecosystem.
18. `updateIndividualAITrait(uint256 tokenId, bytes32 individualAITraitHash)`: Called by the AI agent oracle to assign a unique, AI-generated trait hash to a specific EDE. This hash can represent complex AI-evaluated characteristics.

**[Resource Management]**
19. `setNourishmentToken(address tokenAddress)`: Sets the ERC20 token address that will be used as "nourishment" for various EDE interactions (owner-only).
20. `depositNourishment(uint256 amount)`: Allows users to transfer `_nourishmentToken` from their wallet to this contract, requiring prior approval. These tokens are then used for EDE actions.
21. `withdrawNourishmentFunds(address recipient, uint256 amount)`: Enables the contract owner to withdraw accumulated nourishment tokens from the contract's balance to a specified recipient.

**[Global & Meta-Game]**
22. `getGlobalAIPrediction()`: Returns the current global AI prediction value as last set by the AI agent oracle.
23. `getSpeciesEvolutionLevel()`: Returns the current collective evolution level of all EDEs, reflecting the overall advancement of the species.
24. `evolveSpecies(uint256 increaseAmount)`: Callable by the owner or timekeeper to manually (or based on off-chain triggers) advance the global `_speciesEvolutionLevel`.
25. `setNurturingCosts(uint256 nourishmentCost, uint256 etherCost)`: Owner adjusts the resource costs (nourishment tokens and potentially future Ether) required for EDE interaction functions.
26. `setReproductionCriteria(uint256 minHealth, uint256 minMood, uint256 minEnergy, uint256 cost)`: Owner sets the minimum attribute thresholds and nourishment cost required for EDEs to reproduce.

**[Access Control & Utilities]**
27. `setTimekeeper(address timekeeperAddress)`: Sets the address authorized to call the `progressTimeTick` function (owner-only).
28. `ownerOf(uint256 tokenId)`: Inherited from ERC721, returns the owner of the EDE.
29. `balanceOf(address owner)`: Inherited from ERC721, returns the number of EDEs owned by an address.
30. `renounceOwnership()`: Inherited from Ownable, allows the current owner to relinquish ownership of the contract.
31. `transferOwnership(address newOwner)`: Inherited from Ownable, allows the current owner to transfer ownership to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion

/**
 * @title EvolvingDigitalEntities (EDE)
 * @dev A smart contract for advanced, dynamic NFTs that represent digital creatures with evolving attributes,
 *      a lifecycle, and potential AI-driven influences. Owners interact to nurture their EDEs, affecting
 *      their stats and appearance. The ecosystem can react to global AI predictions, and EDEs can reproduce or merge.
 *      The goal is to create a living, breathing digital collectible ecosystem.
 *
 * Outline:
 * 1.  State Variables & Data Structures
 * 2.  Events
 * 3.  Constructor & Initialization
 * 4.  ERC721 Standard Functions (Minting, Transfer, Approvals)
 * 5.  EDE Core Logic (Attribute Management, Lifecycle)
 * 6.  Owner Interaction & Nurturing
 * 7.  Oracle & AI Integration
 * 8.  Resource Management (Nourishment Token)
 * 9.  Global & Meta-Game Mechanics
 * 10. Utility & View Functions
 * 11. Access Control
 *
 * Function Summary:
 *
 * [ERC721 & Core Minting]
 * 1.  `constructor(string memory name, string memory symbol, string memory baseURI_)`: Initializes the ERC721 contract, sets base URI and the contract owner.
 * 2.  `mintEDE(address recipient, string memory initialAppearanceCode)`: Mints a new Evolving Digital Entity (EDE) to a recipient with an initial appearance.
 * 3.  `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for a given EDE, reflecting its current attributes. Metadata is generated on-the-fly or resolved by a base URI.
 * 4.  `setBaseURI(string memory newBaseURI)`: Allows the contract owner to update the base URI for metadata.
 *
 * [EDE Core State & Lifecycle]
 * 5.  `getEDEAttributes(uint256 tokenId)`: Returns all current attributes of a specific EDE, applying decay first.
 * 6.  `_applyDecayWithTokenId(uint256 tokenId, EDE storage ede)`: Internal helper to calculate and apply decay to an EDE's attributes based on time since last interaction.
 * 7.  `progressTimeTick()`: Callable by a designated `timekeeper` to advance the global ecosystem "era". This can trigger global events or increase mutation chances. Does not iterate over all EDEs.
 * 8.  `reproduceEDE(uint256 parent1Id, uint256 parent2Id)`: Allows two compatible EDEs to reproduce, creating a new offspring EDE. Requires meeting specific criteria and consuming nourishment.
 * 9.  `mergeEDEs(uint256 primaryId, uint256 secondaryId)`: Merges two EDEs into one, destroying the secondary and boosting primary's stats. Requires specific conditions.
 *
 * [Owner Interaction & Nurturing]
 * 10. `nurtureEDE(uint256 tokenId)`: A general interaction that improves an EDE's mood and health, costing nourishment. Applies decay first.
 * 11. `educateEDE(uint256 tokenId)`: Improves an EDE's intelligence and creativity, costing nourishment. Applies decay first.
 * 12. `socializeEDE(uint256 tokenId)`: Improves an EDE's social score, costing nourishment. Applies decay first.
 * 13. `healEDE(uint256 tokenId)`: Restores an EDE's health significantly, costing nourishment. Applies decay first.
 * 14. `feedEDE(uint256 tokenId)`: Restores an EDE's energy, crucial for other interactions, costing nourishment. Applies decay first.
 * 15. `customizeAppearance(uint256 tokenId, string memory newAppearanceCode)`: Allows the owner to change the visual representation string of their EDE.
 *
 * [Oracle & AI Integration]
 * 16. `setAIAgentOracle(address oracleAddress)`: Sets the address of the trusted AI agent oracle (owner-only).
 * 17. `updateGlobalAIPrediction(uint256 predictionValue)`: Called by the AI agent oracle to update a global AI-driven environmental sentiment or event score.
 * 18. `updateIndividualAITrait(uint256 tokenId, bytes32 individualAITraitHash)`: Called by the AI agent oracle to set a unique, AI-generated trait hash for a specific EDE.
 *
 * [Resource Management]
 * 19. `setNourishmentToken(address tokenAddress)`: Sets the ERC20 token used for nourishment costs (owner-only).
 * 20. `depositNourishment(uint256 amount)`: Users deposit nourishment tokens into the contract for their EDE interactions. Requires allowance.
 * 21. `withdrawNourishmentFunds(address recipient, uint256 amount)`: Owner can withdraw accumulated nourishment tokens.
 *
 * [Global & Meta-Game]
 * 22. `getGlobalAIPrediction()`: Returns the current global AI prediction value.
 * 23. `getSpeciesEvolutionLevel()`: Returns the current collective evolution level of all EDEs.
 * 24. `evolveSpecies(uint256 increaseAmount)`: Owner/timekeeper can advance the global species evolution level based on in-game achievements or external factors.
 * 25. `setNurturingCosts(uint256 nourishmentCost, uint256 etherCost)`: Owner adjusts the resource costs (nourishment/ether) for interaction functions.
 * 26. `setReproductionCriteria(uint256 minHealth, uint256 minMood, uint256 minEnergy, uint256 cost)`: Owner sets conditions and costs for EDE reproduction.
 *
 * [Access Control & Utilities]
 * 27. `setTimekeeper(address timekeeperAddress)`: Sets the address allowed to call `progressTimeTick` (owner-only).
 * 28. `ownerOf(uint256 tokenId)`: Returns the owner of the EDE (inherited).
 * 29. `balanceOf(address owner)`: Returns the number of EDEs owned by an address (inherited).
 * 30. `renounceOwnership()`: Relinquishes ownership of the contract (inherited).
 * 31. `transferOwnership(address newOwner)`: Transfers ownership of the contract (inherited).
 */
contract EvolvingDigitalEntities is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    // --- State Variables ---
    string private _baseTokenURI; // Base URI for metadata resolver (e.g., "https://api.myede.com/metadata/")
    address private _aiAgentOracle; // Address of the trusted AI agent oracle
    address private _timekeeper; // Address permitted to advance global time ticks
    address private _nourishmentToken; // ERC20 token address used for nurturing costs

    uint256 public _globalAIPrediction; // Global AI-driven sentiment/event score
    uint256 public _speciesEvolutionLevel; // Collective evolution level of EDEs
    uint256 public _currentEra; // Global time tick / era counter

    // --- EDE Attributes ---
    struct EDE {
        uint256 birthTime; // Timestamp of EDE creation
        uint256 lastInteractionTime; // Timestamp of last owner interaction
        uint256 health; // 0-100, impacts survival and reproduction
        uint256 mood; // 0-100, impacts effectiveness of nurturing
        uint256 intelligence; // 0-100, can affect quest outcomes or special abilities
        uint256 creativity; // 0-100, influences appearance changes or reproduction variations
        uint256 socialScore; // 0-100, for potential future interaction with other EDEs
        uint256 energy; // 0-100, consumed by actions, replenished by feeding
        string appearanceCode; // A string representing visual traits
        bytes32 individualAITraitHash; // A hash representing a unique AI-generated trait for this EDE
        uint256 parent1Id; // For lineage tracking
        uint256 parent2Id; // For lineage tracking
    }

    mapping(uint256 => EDE) private _edes;

    // --- Configuration Costs & Criteria ---
    struct NurturingCosts {
        uint256 nourishmentAmount; // Amount of nourishment tokens needed for basic actions
        uint256 etherAmount; // Future proof for potential ether costs (currently 0)
    }
    NurturingCosts public nurturingCosts;

    struct ReproductionCriteria {
        uint256 minHealth;
        uint256 minMood;
        uint256 minEnergy;
        uint256 nourishmentCost;
    }
    ReproductionCriteria public reproductionCriteria;

    // --- Constants ---
    uint256 public constant MAX_ATTRIBUTE_VALUE = 100;
    uint256 public constant MIN_ATTRIBUTE_VALUE = 0;
    uint256 public constant DECAY_INTERVAL_SECONDS = 1 days; // How often decay "units" pass
    uint256 public constant DECAY_AMOUNT_PER_INTERVAL = 5; // How much health, mood, energy decay per interval
    uint256 public constant SLOW_DECAY_AMOUNT_PER_INTERVAL = 2; // How much intelligence, creativity, social score decay
    uint256 public constant INITIAL_ATTRIBUTES = 75; // Starting value for most attributes

    // --- Events ---
    event EDEMinted(uint256 indexed tokenId, address indexed owner, string initialAppearanceCode);
    event EDEAttributesUpdated(uint256 indexed tokenId, uint256 health, uint256 mood, uint256 intelligence, uint256 creativity, uint256 socialScore, uint256 energy);
    event EDEAppearanceCustomized(uint256 indexed tokenId, string newAppearanceCode);
    event EDEReproduced(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event EDEMerged(uint256 indexed primaryId, uint256 indexed secondaryId, uint256 finalHealth, uint256 finalMood);
    event GlobalAIPredictionUpdated(uint256 newPrediction);
    event IndividualAITraitUpdated(uint256 indexed tokenId, bytes32 newTraitHash);
    event SpeciesEvolutionLevelIncreased(uint256 newLevel);
    event NourishmentDeposited(address indexed user, uint256 amount);
    event NourishmentWithdrawn(address indexed recipient, uint256 amount);
    event TimekeeperSet(address indexed newTimekeeper);
    event AIAgentOracleSet(address indexed newOracle);

    // --- Modifiers ---
    modifier onlyAIAgentOracle() {
        require(msg.sender == _aiAgentOracle, "EDE: Only AI agent oracle can call this function");
        _;
    }

    modifier onlyTimekeeper() {
        require(msg.sender == _timekeeper, "EDE: Only timekeeper can call this function");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI_)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI_;
        _timekeeper = msg.sender; // Owner is initial timekeeper
        _aiAgentOracle = msg.sender; // Owner is initial AI oracle
        nurturingCosts = NurturingCosts({nourishmentAmount: 5, etherAmount: 0});
        reproductionCriteria = ReproductionCriteria({minHealth: 60, minMood: 60, minEnergy: 50, nourishmentCost: 20});
        _speciesEvolutionLevel = 1;
        _currentEra = 1;
    }

    // --- ERC721 Standard Functions ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * This function constructs a URI pointing to the metadata for the given tokenId.
     * The actual metadata (e.g., JSON containing attributes) is expected to be
     * resolved by an off-chain service or frontend using this URI, using the
     * `getEDEAttributes` function for dynamic data.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    /**
     * @dev Sets the base URI for token metadata. Only callable by the owner.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    // --- EDE Core Logic ---

    /**
     * @dev Mints a new Evolving Digital Entity (EDE) to a recipient.
     * Initializes core attributes and sets birth time. Only callable by the owner.
     * @param recipient The address to receive the new EDE.
     * @param initialAppearanceCode A string defining the initial visual appearance.
     */
    function mintEDE(address recipient, string memory initialAppearanceCode) public onlyOwner {
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();

        EDE storage newEDE = _edes[newTokenId];
        newEDE.birthTime = block.timestamp;
        newEDE.lastInteractionTime = block.timestamp; // Start fresh
        newEDE.health = INITIAL_ATTRIBUTES;
        newEDE.mood = INITIAL_ATTRIBUTES;
        newEDE.intelligence = INITIAL_ATTRIBUTES;
        newEDE.creativity = INITIAL_ATTRIBUTES;
        newEDE.socialScore = INITIAL_ATTRIBUTES;
        newEDE.energy = MAX_ATTRIBUTE_VALUE; // Start with full energy
        newEDE.appearanceCode = initialAppearanceCode;
        newEDE.individualAITraitHash = bytes32(0); // No AI trait initially
        newEDE.parent1Id = 0; // No parents for initial mint
        newEDE.parent2Id = 0;

        _safeMint(recipient, newTokenId);
        emit EDEMinted(newTokenId, recipient, initialAppearanceCode);
    }

    /**
     * @dev Returns all current attributes of a specific EDE.
     * Applies decay before returning the current state. This is a view function
     * that simulates the decay without modifying the on-chain state.
     * @param tokenId The ID of the EDE.
     * @return health, mood, intelligence, creativity, socialScore, energy, appearanceCode, individualAITraitHash, lastInteractionTime, birthTime.
     */
    function getEDEAttributes(uint256 tokenId)
        public
        view
        returns (
            uint256 health,
            uint256 mood,
            uint256 intelligence,
            uint256 creativity,
            uint256 socialScore,
            uint256 energy,
            string memory appearanceCode,
            bytes32 individualAITraitHash,
            uint256 lastInteractionTime,
            uint256 birthTime,
            uint256 parent1Id,
            uint256 parent2Id
        )
    {
        _requireOwned(tokenId);
        EDE storage ede = _edes[tokenId];

        uint256 timeSinceLastInteraction = block.timestamp - ede.lastInteractionTime;
        uint256 intervalsPassed = timeSinceLastInteraction / DECAY_INTERVAL_SECONDS;

        health = _clamp(ede.health - (intervalsPassed * DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        mood = _clamp(ede.mood - (intervalsPassed * DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        energy = _clamp(ede.energy - (intervalsPassed * DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

        // Intelligence, Creativity, SocialScore decay slower
        intelligence = _clamp(ede.intelligence - (intervalsPassed * SLOW_DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        creativity = _clamp(ede.creativity - (intervalsPassed * SLOW_DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        socialScore = _clamp(ede.socialScore - (intervalsPassed * SLOW_DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

        appearanceCode = ede.appearanceCode;
        individualAITraitHash = ede.individualAITraitHash;
        lastInteractionTime = ede.lastInteractionTime;
        birthTime = ede.birthTime;
        parent1Id = ede.parent1Id;
        parent2Id = ede.parent2Id;
    }

    /**
     * @dev Internal helper to apply decay to an EDE's attributes.
     * Modifies the EDE's state directly. Called before owner interaction functions.
     * @param tokenId The ID of the EDE being processed.
     * @param ede The EDE storage struct to modify.
     */
    function _applyDecayWithTokenId(uint256 tokenId, EDE storage ede) internal {
        uint256 timeSinceLastInteraction = block.timestamp - ede.lastInteractionTime;
        uint256 intervalsPassed = timeSinceLastInteraction / DECAY_INTERVAL_SECONDS;

        if (intervalsPassed > 0) {
            ede.health = _clamp(ede.health - (intervalsPassed * DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
            ede.mood = _clamp(ede.mood - (intervalsPassed * DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
            ede.energy = _clamp(ede.energy - (intervalsPassed * DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

            ede.intelligence = _clamp(ede.intelligence - (intervalsPassed * SLOW_DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
            ede.creativity = _clamp(ede.creativity - (intervalsPassed * SLOW_DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
            ede.socialScore = _clamp(ede.socialScore - (intervalsPassed * SLOW_DECAY_AMOUNT_PER_INTERVAL), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

            ede.lastInteractionTime = block.timestamp; // Reset interaction time after applying decay
            emit EDEAttributesUpdated(
                tokenId,
                ede.health,
                ede.mood,
                ede.intelligence,
                ede.creativity,
                ede.socialScore,
                ede.energy
            );
        }
    }


    /**
     * @dev Advances the global ecosystem "era". Callable by the timekeeper.
     * This function can be used to signal global events or trigger
     * ecosystem-wide changes without iterating over all EDEs.
     */
    function progressTimeTick() public onlyTimekeeper {
        _currentEra++;
        // Potential global effects based on _currentEra or _globalAIPrediction can be integrated here.
        // E.g., increased mutation probability, environmental shifts, triggering specific AI events.
    }

    /**
     * @dev Allows two compatible EDEs to reproduce, creating a new offspring.
     * Requires the caller to own both parent EDEs, and for parents to meet reproduction criteria.
     * Consumes nourishment tokens (requiring prior approval).
     * @param parent1Id The ID of the first parent EDE.
     * @param parent2Id The ID of the second parent EDE.
     */
    function reproduceEDE(uint256 parent1Id, uint256 parent2Id) public {
        _requireOwned(parent1Id);
        _requireOwned(parent2Id);
        require(ownerOf(parent1Id) == msg.sender, "EDE: Caller must own parent1");
        require(ownerOf(parent2Id) == msg.sender, "EDE: Caller must own parent2");
        require(parent1Id != parent2Id, "EDE: Parents cannot be the same EDE");

        EDE storage p1 = _edes[parent1Id];
        EDE storage p2 = _edes[parent2Id];

        _applyDecayWithTokenId(parent1Id, p1);
        _applyDecayWithTokenId(parent2Id, p2);

        require(p1.health >= reproductionCriteria.minHealth && p2.health >= reproductionCriteria.minHealth, "EDE: Parents need sufficient health");
        require(p1.mood >= reproductionCriteria.minMood && p2.mood >= reproductionCriteria.minMood, "EDE: Parents need sufficient mood");
        require(p1.energy >= reproductionCriteria.minEnergy && p2.energy >= reproductionCriteria.minEnergy, "EDE: Parents need sufficient energy");

        _consumeNourishment(reproductionCriteria.nourishmentCost);

        _tokenIdTracker.increment();
        uint256 childId = _tokenIdTracker.current();

        // Calculate child attributes (simplified combination with a random bonus)
        EDE storage childEDE = _edes[childId];
        childEDE.birthTime = block.timestamp;
        childEDE.lastInteractionTime = block.timestamp;
        childEDE.health = _clamp((p1.health + p2.health) / 2 + _getRandomBonus(), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        childEDE.mood = _clamp((p1.mood + p2.mood) / 2 + _getRandomBonus(), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        childEDE.intelligence = _clamp((p1.intelligence + p2.intelligence) / 2 + _getRandomBonus(), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        childEDE.creativity = _clamp((p1.creativity + p2.creativity) / 2 + _getRandomBonus(), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        childEDE.socialScore = _clamp((p1.socialScore + p2.socialScore) / 2 + _getRandomBonus(), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        childEDE.energy = MAX_ATTRIBUTE_VALUE; // Child starts with full energy

        // Basic combination of appearance codes and AI traits
        childEDE.appearanceCode = string(abi.encodePacked(p1.appearanceCode, "-", p2.appearanceCode, "-", Strings.toString(childId % 100)));
        childEDE.individualAITraitHash = bytes32(uint256(keccak256(abi.encodePacked(p1.individualAITraitHash, p2.individualAITraitHash, childId))));
        childEDE.parent1Id = parent1Id;
        childEDE.parent2Id = parent2Id;

        // Reduce parents' energy after reproduction
        p1.energy = _clamp(p1.energy - (reproductionCriteria.minEnergy / 2), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        p2.energy = _clamp(p2.energy - (reproductionCriteria.minEnergy / 2), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        p1.lastInteractionTime = block.timestamp; // Update parent interaction times
        p2.lastInteractionTime = block.timestamp;

        _safeMint(msg.sender, childId);
        emit EDEReproduced(parent1Id, parent2Id, childId);
        emit EDEAttributesUpdated(parent1Id, p1.health, p1.mood, p1.intelligence, p1.creativity, p1.socialScore, p1.energy);
        emit EDEAttributesUpdated(parent2Id, p2.health, p2.mood, p2.intelligence, p2.creativity, p2.socialScore, p2.energy);
        emit EDEAttributesUpdated(childId, childEDE.health, childEDE.mood, childEDE.intelligence, childEDE.creativity, childEDE.socialScore, childEDE.energy);
    }

    /**
     * @dev Merges two EDEs into one. The secondary EDE is burned, and its essence boosts the primary.
     * Requires caller to own both EDEs.
     * @param primaryId The ID of the EDE that will be enhanced.
     * @param secondaryId The ID of the EDE that will be consumed.
     */
    function mergeEDEs(uint256 primaryId, uint256 secondaryId) public {
        _requireOwned(primaryId);
        _requireOwned(secondaryId);
        require(ownerOf(primaryId) == msg.sender, "EDE: Caller must own primary EDE");
        require(ownerOf(secondaryId) == msg.sender, "EDE: Caller must own secondary EDE");
        require(primaryId != secondaryId, "EDE: Cannot merge an EDE with itself");
        // Could add more complex merging conditions, e.g., type compatibility, cost.

        EDE storage primary = _edes[primaryId];
        EDE storage secondary = _edes[secondaryId];

        _applyDecayWithTokenId(primaryId, primary);
        _applyDecayWithTokenId(secondaryId, secondary);

        // Boost primary's stats by a percentage of secondary's stats
        primary.health = _clamp(primary.health + (secondary.health / 4), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        primary.mood = _clamp(primary.mood + (secondary.mood / 4), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        primary.intelligence = _clamp(primary.intelligence + (secondary.intelligence / 4), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        primary.creativity = _clamp(primary.creativity + (secondary.creativity / 4), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        primary.socialScore = _clamp(primary.socialScore + (secondary.socialScore / 4), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        primary.energy = _clamp(primary.energy + (secondary.energy / 2), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

        primary.lastInteractionTime = block.timestamp;

        _burn(secondaryId); // Burn the secondary EDE
        emit EDEMerged(primaryId, secondaryId, primary.health, primary.mood);
        emit EDEAttributesUpdated(primaryId, primary.health, primary.mood, primary.intelligence, primary.creativity, primary.socialScore, primary.energy);
    }

    // --- Owner Interaction & Nurturing ---

    /**
     * @dev Nurtures an EDE, improving its mood and health.
     * Requires the caller to own the EDE and consumes nourishment.
     * @param tokenId The ID of the EDE to nurture.
     */
    function nurtureEDE(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "EDE: Caller must own this EDE");
        EDE storage ede = _edes[tokenId];
        _applyDecayWithTokenId(tokenId, ede);
        require(ede.energy >= nurturingCosts.nourishmentAmount / 2, "EDE: Not enough energy to nurture"); // Ensure energy before consuming
        _consumeNourishment(nurturingCosts.nourishmentAmount);

        ede.mood = _clamp(ede.mood + 10, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.health = _clamp(ede.health + 5, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.energy = _clamp(ede.energy - (nurturingCosts.nourishmentAmount / 2), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

        ede.lastInteractionTime = block.timestamp;
        emit EDEAttributesUpdated(tokenId, ede.health, ede.mood, ede.intelligence, ede.creativity, ede.socialScore, ede.energy);
    }

    /**
     * @dev Educates an EDE, improving its intelligence and creativity.
     * Requires the caller to own the EDE and consumes nourishment.
     * @param tokenId The ID of the EDE to educate.
     */
    function educateEDE(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "EDE: Caller must own this EDE");
        EDE storage ede = _edes[tokenId];
        _applyDecayWithTokenId(tokenId, ede);
        require(ede.energy >= nurturingCosts.nourishmentAmount, "EDE: Not enough energy to educate");
        _consumeNourishment(nurturingCosts.nourishmentAmount);

        ede.intelligence = _clamp(ede.intelligence + 10, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.creativity = _clamp(ede.creativity + 5, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.energy = _clamp(ede.energy - nurturingCosts.nourishmentAmount, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

        ede.lastInteractionTime = block.timestamp;
        emit EDEAttributesUpdated(tokenId, ede.health, ede.mood, ede.intelligence, ede.creativity, ede.socialScore, ede.energy);
    }

    /**
     * @dev Socializes an EDE, improving its social score.
     * Requires the caller to own the EDE and consumes nourishment.
     * @param tokenId The ID of the EDE to socialize.
     */
    function socializeEDE(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "EDE: Caller must own this EDE");
        EDE storage ede = _edes[tokenId];
        _applyDecayWithTokenId(tokenId, ede);
        require(ede.energy >= nurturingCosts.nourishmentAmount / 2, "EDE: Not enough energy to socialize");
        _consumeNourishment(nurturingCosts.nourishmentAmount);

        ede.socialScore = _clamp(ede.socialScore + 10, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.mood = _clamp(ede.mood + 5, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.energy = _clamp(ede.energy - (nurturingCosts.nourishmentAmount / 2), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

        ede.lastInteractionTime = block.timestamp;
        emit EDEAttributesUpdated(tokenId, ede.health, ede.mood, ede.intelligence, ede.creativity, ede.socialScore, ede.energy);
    }

    /**
     * @dev Heals an EDE, restoring its health significantly.
     * Requires the caller to own the EDE and consumes nourishment.
     * @param tokenId The ID of the EDE to heal.
     */
    function healEDE(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "EDE: Caller must own this EDE");
        EDE storage ede = _edes[tokenId];
        _applyDecayWithTokenId(tokenId, ede);
        require(ede.energy >= nurturingCosts.nourishmentAmount * 2, "EDE: Not enough energy to heal"); // Healing costs more energy
        _consumeNourishment(nurturingCosts.nourishmentAmount * 2); // Healing costs more nourishment

        ede.health = _clamp(ede.health + 20, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.energy = _clamp(ede.energy - (nurturingCosts.nourishmentAmount * 2), MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);

        ede.lastInteractionTime = block.timestamp;
        emit EDEAttributesUpdated(tokenId, ede.health, ede.mood, ede.intelligence, ede.creativity, ede.socialScore, ede.energy);
    }

    /**
     * @dev Feeds an EDE, restoring its energy.
     * Requires the caller to own the EDE and consumes nourishment.
     * @param tokenId The ID of the EDE to feed.
     */
    function feedEDE(uint256 tokenId) public {
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "EDE: Caller must own this EDE");
        EDE storage ede = _edes[tokenId];
        _applyDecayWithTokenId(tokenId, ede);
        _consumeNourishment(nurturingCosts.nourishmentAmount);

        ede.energy = _clamp(ede.energy + 25, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE);
        ede.mood = _clamp(ede.mood + 5, MIN_ATTRIBUTE_VALUE, MAX_ATTRIBUTE_VALUE); // Good food, good mood!

        ede.lastInteractionTime = block.timestamp;
        emit EDEAttributesUpdated(tokenId, ede.health, ede.mood, ede.intelligence, ede.creativity, ede.socialScore, ede.energy);
    }

    /**
     * @dev Allows the owner to change the visual representation string of their EDE.
     * This string could be interpreted by a frontend to render different visuals.
     * @param tokenId The ID of the EDE to customize.
     * @param newAppearanceCode The new string representing the EDE's appearance.
     */
    function customizeAppearance(uint256 tokenId, string memory newAppearanceCode) public {
        _requireOwned(tokenId);
        require(ownerOf(tokenId) == msg.sender, "EDE: Caller must own this EDE");
        EDE storage ede = _edes[tokenId];
        // Could add a cost here, or criteria (e.g., creativity score threshold)
        ede.appearanceCode = newAppearanceCode;
        ede.lastInteractionTime = block.timestamp; // Interaction counts
        emit EDEAppearanceCustomized(tokenId, newAppearanceCode);
    }

    // --- Oracle & AI Integration ---

    /**
     * @dev Sets the address of the trusted AI agent oracle. Only callable by the owner.
     * @param oracleAddress The address of the new AI oracle.
     */
    function setAIAgentOracle(address oracleAddress) public onlyOwner {
        require(oracleAddress != address(0), "EDE: AI Oracle cannot be zero address");
        _aiAgentOracle = oracleAddress;
        emit AIAgentOracleSet(oracleAddress);
    }

    /**
     * @dev Called by the AI agent oracle to update a global AI-driven environmental sentiment or event score.
     * This value can influence all EDEs or trigger meta-events.
     * @param predictionValue The new global AI prediction value.
     */
    function updateGlobalAIPrediction(uint256 predictionValue) public onlyAIAgentOracle {
        _globalAIPrediction = predictionValue;
        emit GlobalAIPredictionUpdated(predictionValue);
    }

    /**
     * @dev Called by the AI agent oracle to set a unique, AI-generated trait hash for a specific EDE.
     * This hash is intended to be interpreted by off-chain systems to enrich metadata or logic.
     * @param tokenId The ID of the EDE to update.
     * @param individualAITraitHash The new AI-generated trait hash.
     */
    function updateIndividualAITrait(uint256 tokenId, bytes32 individualAITraitHash) public onlyAIAgentOracle {
        _requireOwned(tokenId); // EDE must exist
        _edes[tokenId].individualAITraitHash = individualAITraitHash;
        // Interaction time does not update for oracle-driven changes, as it's not owner interaction.
        emit IndividualAITraitUpdated(tokenId, individualAITraitHash);
    }

    // --- Resource Management ---

    /**
     * @dev Sets the ERC20 token address used for nourishment costs. Only callable by the owner.
     * @param tokenAddress The address of the ERC20 nourishment token.
     */
    function setNourishmentToken(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "EDE: Nourishment token cannot be zero address");
        _nourishmentToken = tokenAddress;
    }

    /**
     * @dev Users deposit nourishment tokens into the contract.
     * This requires the user to have approved this contract to spend their tokens
     * via `IERC20(_nourishmentToken).approve(address(this), amount)`.
     * Tokens are held by the contract, and then drawn upon for actions.
     * Note: For direct action costs, `_consumeNourishment` will `transferFrom` the sender directly.
     * This `depositNourishment` function could be for pre-funding a pool.
     * For this example, it simply transfers to the contract address.
     * @param amount The amount of nourishment tokens to deposit.
     */
    function depositNourishment(uint256 amount) public {
        require(_nourishmentToken != address(0), "EDE: Nourishment token not set");
        require(IERC20(_nourishmentToken).transferFrom(msg.sender, address(this), amount), "EDE: Nourishment token deposit failed");
        emit NourishmentDeposited(msg.sender, amount);
    }

    /**
     * @dev Owner can withdraw accumulated nourishment tokens from the contract.
     * @param recipient The address to send the tokens to.
     * @param amount The amount of nourishment tokens to withdraw.
     */
    function withdrawNourishmentFunds(address recipient, uint256 amount) public onlyOwner {
        require(_nourishmentToken != address(0), "EDE: Nourishment token not set");
        require(recipient != address(0), "EDE: Recipient cannot be zero address");
        require(IERC20(_nourishmentToken).transfer(recipient, amount), "EDE: Nourishment token withdrawal failed");
        emit NourishmentWithdrawn(recipient, amount);
    }

    /**
     * @dev Internal function to consume nourishment tokens for an action.
     * Requires `msg.sender` to have previously approved this contract to spend
     * the `_nourishmentToken` on their behalf.
     * @param amount The amount of nourishment to consume.
     */
    function _consumeNourishment(uint256 amount) internal {
        require(_nourishmentToken != address(0), "EDE: Nourishment token not set");
        // This transfers from the user's approved balance directly to the contract.
        require(IERC20(_nourishmentToken).transferFrom(msg.sender, address(this), amount), "EDE: Insufficient nourishment or allowance for action");
    }

    // --- Global & Meta-Game ---

    /**
     * @dev Returns the current global AI prediction value.
     */
    function getGlobalAIPrediction() public view returns (uint256) {
        return _globalAIPrediction;
    }

    /**
     * @dev Returns the current collective evolution level of all EDEs.
     */
    function getSpeciesEvolutionLevel() public view returns (uint256) {
        return _speciesEvolutionLevel;
    }

    /**
     * @dev Advances the global species evolution level. Callable by owner or timekeeper.
     * This can be based on collective achievements or milestones reached by EDEs.
     * @param increaseAmount The amount to increase the evolution level by.
     */
    function evolveSpecies(uint256 increaseAmount) public onlyTimekeeper { // Or onlyOwner, depending on desired control
        require(increaseAmount > 0, "EDE: Increase amount must be positive");
        _speciesEvolutionLevel += increaseAmount;
        emit SpeciesEvolutionLevelIncreased(_speciesEvolutionLevel);
    }

    /**
     * @dev Owner adjusts the resource costs (nourishment/ether) for interaction functions.
     * @param nourishmentCost The new nourishment token cost for basic actions.
     * @param etherCost The new ether cost for basic actions (currently 0).
     */
    function setNurturingCosts(uint256 nourishmentCost, uint256 etherCost) public onlyOwner {
        nurturingCosts = NurturingCosts({nourishmentAmount: nourishmentCost, etherAmount: etherCost});
    }

    /**
     * @dev Owner sets the conditions and costs for EDE reproduction.
     * @param minHealth The minimum health required for parents.
     * @param minMood The minimum mood required for parents.
     * @param minEnergy The minimum energy required for parents.
     * @param cost The nourishment cost for reproduction.
     */
    function setReproductionCriteria(uint256 minHealth, uint256 minMood, uint256 minEnergy, uint256 cost) public onlyOwner {
        reproductionCriteria = ReproductionCriteria({
            minHealth: minHealth,
            minMood: minMood,
            minEnergy: minEnergy,
            nourishmentCost: cost
        });
    }

    // --- Access Control & Utilities ---

    /**
     * @dev Sets the address allowed to call `progressTimeTick`. Only callable by the owner.
     * @param timekeeperAddress The address of the new timekeeper.
     */
    function setTimekeeper(address timekeeperAddress) public onlyOwner {
        require(timekeeperAddress != address(0), "EDE: Timekeeper cannot be zero address");
        _timekeeper = timekeeperAddress;
        emit TimekeeperSet(timekeeperAddress);
    }

    // --- Internal Helpers ---

    /**
     * @dev Clamps a value between a minimum and maximum.
     * @param value The value to clamp.
     * @param min The minimum allowed value.
     * @param max The maximum allowed value.
     * @return The clamped value.
     */
    function _clamp(uint256 value, uint256 min, uint256 max) internal pure returns (uint256) {
        return (value < min) ? min : ((value > max) ? max : value);
    }

    /**
     * @dev Generates a pseudo-random bonus value (0-9).
     * This is NOT cryptographically secure and should not be used for high-value randomness.
     * It's suitable for non-critical game mechanics like attribute bonuses.
     * @return A small pseudo-random bonus.
     */
    function _getRandomBonus() internal view returns (uint256) {
        // Simple pseudo-randomness based on block data, for game mechanics.
        // Do NOT use for security-sensitive operations like NFT rarity generation that must be tamper-proof.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenIdTracker.current()))) % 10;
    }
}
```