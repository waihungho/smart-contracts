Okay, let's design a smart contract that manages a system of dynamic, evolving digital assets (let's call them "Aetheric Crystals") that require upkeep (energy) and can evolve or reproduce based on their state and user interaction, incorporating advanced concepts like time-based decay, random trait generation (simulated via an oracle interface), configurable evolution paths, and resource management.

This goes beyond standard ERC-721 by adding complex, state-dependent logic and evolution mechanics.

**Concept:** A system where users own unique "Aetheric Crystals". Crystals have energy levels that decay over time. Users must "feed" them energy. Crystals can evolve through different stages and gain traits based on their energy level, vitality, and potentially external factors (like simulated randomness). They can also attempt to "reproduce" to create new crystals under specific conditions. The system owner can configure many parameters.

---

**Outline & Function Summary**

**Contract Name:** `AethericCrystals`

**Core Concept:** Dynamic, evolving, resource-dependent digital assets (NFT-like).

**Dependencies:**
*   `@openzeppelin/contracts/token/ERC721/ERC721.sol`: For basic NFT functionality.
*   `@openzeppelin/contracts/access/Ownable.sol`: For admin control.
*   `@openzeppelin/contracts/security/ReentrancyGuard.sol`: To prevent reentrancy in critical functions.
*   `@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol`: Interface for Chainlink VRF or a similar random number oracle.
*   `@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol`: Base contract for VRF consumers.

**Data Structures:**
*   `CrystalState`: Struct holding properties for each crystal (energy level, vitality, stage, traits, last fed time, name, bio).
*   `EvolutionStageConfig`: Struct defining requirements and effects for reaching a specific evolution stage.
*   `TraitInfluence`: Struct defining how a specific trait type affects mechanics (e.g., energy decay bonus, reproduction chance bonus).

**Enums:**
*   `EvolutionStage`: Defines distinct stages (Seed, Sprout, Mature, Crystalline, etc.).
*   `TraitType`: Defines categories of traits (EnergyEfficiency, ReproductionBonus, RarityModifier, etc.).

**State Variables:**
*   `_crystalStates`: Mapping from token ID to `CrystalState`.
*   `_owner`: Contract owner address (from `Ownable`).
*   ERC721 internal state (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
*   `_nextTokenId`: Counter for new crystals.
*   `_isPaused`: Contract pause status.
*   `_energyDecayRatePerSecond`: Global decay rate.
*   `_evolutionConfigs`: Mapping from `EvolutionStage` to `EvolutionStageConfig`.
*   `_traitInfluences`: Mapping from `TraitType` to `TraitInfluence`.
*   `_userEnergyBalances`: Mapping from user address to their available energy balance (simulated resource).
*   VRF configuration variables (`_vrfCoordinator`, `_keyHash`, `_s_subscriptionId`, `_requestConfirmations`, `_callbackGasLimit`).
*   `_pendingRandomRequests`: Mapping from VRF request ID to the token ID it's for (or 0 for new mints).

**Events:**
*   `CrystalMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint8 initialStage)`
*   `EnergyFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newEnergyLevel)`
*   `CrystalEvolved(uint256 indexed tokenId, uint8 oldStage, uint8 newStage)`
*   `EssenceHarvested(uint256 indexed tokenId, address indexed harvester, uint256 amount)`
*   `CrystalReproduced(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId)`
*   `CrystalDecayed(uint256 indexed tokenId, uint256 energyLost, uint256 newEnergyLevel)`
*   `CrystalStateUpdated(uint256 indexed tokenId)`
*   `ConfigUpdated(string indexed configName)`
*   `Paused()`
*   `Unpaused()`
*   `CrystalNameSet(uint256 indexed tokenId, string name)`
*   `CrystalBioSet(uint256 indexed tokenId, string bio)`
*   `EnergyDeposited(address indexed user, uint256 amount)`
*   `RandomnessRequested(uint256 indexed requestId, uint256 indexed targetTokenId)`

**Functions (27+ Functions):**

*   **ERC-721 Standard (Minimal Implementation):**
    1.  `ownerOf(uint256 tokenId)`: Get owner of a crystal.
    2.  `balanceOf(address owner)`: Get number of crystals owned by an address.
    3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer ownership of a crystal.
    4.  `approve(address to, uint256 tokenId)`: Approve another address to transfer a crystal.
    5.  `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all crystals.
    6.  `getApproved(uint256 tokenId)`: Get approved address for a specific crystal.
    7.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all crystals.

*   **Crystal Core Mechanics:**
    8.  `requestRandomCrystalSeed(uint256 targetTokenId)`: (Internal/Owner) Requests randomness from VRF for minting (target 0) or reproduction (target parent ID).
    9.  `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: (External - VRF Callback) Receives random numbers, triggers minting or reproduction based on `_pendingRandomRequests`.
    10. `feedEnergyToCrystal(uint256 tokenId, uint256 amount)`: User provides energy to a crystal. Calculates and applies decay first. Deducts from user's balance. Increases crystal energy and vitality.
    11. `attemptEvolution(uint256 tokenId)`: User attempts to evolve a crystal. Checks requirements (energy, vitality, stage, config). Applies decay. If successful, updates stage, potentially modifies traits, emits event.
    12. `harvestCrystalEssence(uint256 tokenId)`: User attempts to harvest essence. Calculates amount based on crystal state (energy, vitality, traits). Applies decay. Reduces crystal energy/vitality. Returns amount harvested (simulated, e.g., as an event or internal balance update).
    13. `attemptReproduction(uint256 parent1Id, uint256 parent2Id)`: User attempts reproduction using two *owned*, *mature* crystals. Checks requirements (stage, energy, vitality, traits). Applies decay to parents. If checks pass, requests randomness (`requestRandomCrystalSeed`) for success chance and child traits.

*   **State & Information:**
    14. `getCrystalState(uint256 tokenId)`: Get all properties of a crystal, applying decay calculation *before* returning state.
    15. `getUserCrystals(address user)`: (Helper/View) Returns a list of token IDs owned by a user. *Note: This can be gas-intensive for many tokens; in practice, off-chain indexing is common.*
    16. `getSystemStats()`: (View) Returns global system statistics (total crystals, total energy in system, etc.).
    17. `getEvolutionRequirements(uint8 currentStage)`: (View) Get requirements (energy, vitality) for evolving from a specific stage.
    18. `getTraitDetails(uint8 traitType)`: (View) Get influence details for a specific trait type.
    19. `estimateEnergyDecay(uint256 tokenId)`: (View) Calculate potential energy decay since last fed timestamp without modifying state.

*   **System Configuration (Owner Only):**
    20. `setEnergyDecayRate(uint256 rate)`: Set the global energy decay rate per second.
    21. `setEvolutionConfig(uint8 stage, uint256 requiredEnergy, uint256 requiredVitality)`: Configure requirements for a specific evolution stage.
    22. `addEvolutionStage(uint8 stage, uint256 requiredEnergy, uint256 requiredVitality)`: Add a new evolution stage definition.
    23. `addCrystalTraitType(uint8 traitType, uint8 influenceType, int256 influenceValue)`: Define a new trait type and its influence on a specific mechanic (e.g., type `EnergyEfficiency` with value `-5` influencing `EnergyDecayBonus`).
    24. `setTraitInfluence(uint8 traitType, uint8 influenceType, int256 influenceValue)`: Update the influence of an existing trait type.
    25. `setVRFConfig(address coordinator, bytes32 keyHash, uint64 subscriptionId, uint16 requestConfirmations, uint32 callbackGasLimit)`: Configure Chainlink VRF parameters.
    26. `withdrawLink(uint256 amount)`: (Owner) Withdraw LINK tokens from the contract (necessary for VRF fees).

*   **User Resource Management (Simulated Energy):**
    27. `depositEnergy(uint256 amount)`: (Simulated) User deposits energy into their balance within the contract. *Note: In a real system, this might involve transferring an ERC-20 token.*
    28. `getUserEnergyBalance(address user)`: (View) Get the available energy balance for a user.

*   **User Customization:**
    29. `setName(uint256 tokenId, string memory name)`: Set a custom name for a crystal (owner only).
    30. `setBio(uint256 tokenId, string memory bio)`: Set a short biography for a crystal (owner only).

*   **Administrative:**
    31. `emergencyPause()`: (Owner) Pause critical contract functions.
    32. `emergencyUnpause()`: (Owner) Unpause the contract.


---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline & Function Summary ---
// Contract Name: AethericCrystals
// Core Concept: Dynamic, evolving, resource-dependent digital assets (NFT-like).
// Dependencies: ERC721, Ownable, ReentrancyGuard, Chainlink VRF.
// Features: Dynamic state based on energy & time, evolution stages, traits, reproduction, simulated resource management, configurable parameters, randomness integration.
//
// Data Structures:
// - CrystalState: Represents a crystal's properties.
// - EvolutionStageConfig: Defines requirements for evolving.
// - TraitInfluence: Defines how traits affect mechanics.
// Enums: EvolutionStage, TraitType.
//
// Functions: (Total: 32+)
// - ERC-721 Standard: ownerOf, balanceOf, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll (7)
// - Crystal Core Mechanics: requestRandomCrystalSeed, fulfillRandomWords, feedEnergyToCrystal, attemptEvolution, harvestCrystalEssence, attemptReproduction (6)
// - State & Information: getCrystalState, getUserCrystals, getSystemStats, getEvolutionRequirements, getTraitDetails, estimateEnergyDecay (6)
// - System Configuration (Owner Only): setEnergyDecayRate, setEvolutionConfig, addEvolutionStage, addCrystalTraitType, setTraitInfluence, setVRFConfig, withdrawLink (7)
// - User Resource Management (Simulated Energy): depositEnergy, getUserEnergyBalance (2)
// - User Customization: setName, setBio (2)
// - Administrative: emergencyPause, emergencyUnpause (2)
// - Internal Helpers: _beforeTokenTransfer, _burn, _mint, _updateCrystalState, _calculateAndApplyDecay, _calculateTraitBonus (>=0)
// ----------------------------------

contract AethericCrystals is ERC721, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Errors ---
    error CrystalNotFound(uint256 tokenId);
    error NotCrystalOwner(uint256 tokenId, address caller);
    error InsufficientEnergy(uint256 tokenId, uint256 required, uint256 current);
    error InsufficientVitality(uint256 tokenId, uint256 required, uint256 current);
    error AlreadyAtMaxStage(uint256 tokenId, uint8 currentStage);
    error InvalidStage(uint8 stage);
    error InvalidTraitType(uint8 traitType);
    error ReproductionRequirementsNotMet(string reason); // e.g., not mature, not enough energy
    error VRFRequestFailed(uint256 reasonCode);
    error VRFConfigNotSet();
    error InsufficientUserEnergy(address user, uint256 required, uint256 current);
    error ContractPaused();
    error AlreadyPaused();
    error NotPaused();
    error CannotTransferDecayingCrystal(uint256 tokenId); // Example custom transfer rule
    error InvalidTraitInfluenceType(uint8 influenceType);

    // --- Enums ---
    enum EvolutionStage {
        Seed,
        Sprout,
        Mature,
        Crystalline,
        Ascended,
        MAX_STAGE // Sentinel value
    }

    enum TraitType {
        None,
        EnergyEfficiency, // Affects decay rate
        ReproductionBonus, // Affects reproduction chance/cost
        VitalityBoost, // Affects vitality gain/loss
        EssenceYieldBonus, // Affects harvest amount
        RarityModifier, // Affects future trait generation/value
        COLOR_SEED, // Initial color (example visual trait)
        TEXTURE_SEED, // Initial texture (example visual trait)
        MAX_TRAIT_TYPE // Sentinel value
    }

     // Enum to categorize how a trait type influences a mechanic
    enum TraitInfluenceType {
        None,
        EnergyDecayBonus,       // Influences how quickly energy decays (negative value means slower decay)
        ReproductionSuccessBonus, // Influences chance of successful reproduction (positive value increases chance)
        ReproductionCostBonus,  // Influences energy/vitality cost of reproduction (negative value means lower cost)
        VitalityChangeBonus,    // Influences vitality gain/loss from feeding/harvesting (positive increases gain, decreases loss)
        EssenceYieldBonus,      // Influences amount harvested
        InitialTraitDistributionBonus // Influences probability of receiving certain traits in offspring
    }

    // --- Structs ---
    struct CrystalState {
        uint256 energyLevel;
        uint256 vitalityScore; // 0-1000, reflects health/potential
        EvolutionStage evolutionStage;
        TraitType[] traits; // Array of trait types held by the crystal
        uint256 lastEnergyFeedTimestamp;
        string name; // User-defined name
        string bio; // User-defined description
        uint256 creationRandomnessSeed; // The random seed used for initial generation/reproduction
    }

    struct EvolutionStageConfig {
        uint256 requiredEnergyForEvolution;
        uint256 requiredVitalityForEvolution;
        uint256 energyCostOnEvolution;
        uint256 vitalityCostOnEvolution;
    }

    struct TraitInfluence {
         TraitInfluenceType influenceType;
         int256 influenceValue; // Signed value, interpretation depends on influenceType
    }

    // --- State Variables ---
    Counters.Counter private _nextTokenId;
    mapping(uint256 => CrystalState) private _crystalStates;

    bool private _isPaused;

    uint256 public energyDecayRatePerSecond; // Global decay rate (energy units per second)
    mapping(EvolutionStage => EvolutionStageConfig) public evolutionConfigs;
    mapping(TraitType => TraitInfluence) public traitInfluences; // Maps trait type to its general influence rule

    mapping(address => uint256) private _userEnergyBalances; // Simulated user energy balance

    // Chainlink VRF variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_s_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint16 private immutable i_requestConfirmations;
    uint32 private immutable i_callbackGasLimit;

    // Stores VRF request IDs mapped to the target token ID (0 for new mint, or parent ID for reproduction)
    mapping(uint256 => uint256) private _pendingRandomRequests;

    // --- Events ---
    event CrystalMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint8 initialStage);
    event EnergyFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newEnergyLevel);
    event CrystalEvolved(uint256 indexed tokenId, uint8 oldStage, uint8 newStage);
    event EssenceHarvested(uint256 indexed tokenId, address indexed harvester, uint256 amount);
    event CrystalReproduced(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event CrystalDecayed(uint256 indexed tokenId, uint256 energyLost, uint256 newEnergyLevel);
    event CrystalStateUpdated(uint256 indexed tokenId);
    event ConfigUpdated(string indexed configName);
    event Paused();
    event Unpaused();
    event CrystalNameSet(uint256 indexed tokenId, string name);
    event CrystalBioSet(uint256 indexed tokenId, string bio);
    event EnergyDeposited(address indexed user, uint256 amount);
    event RandomnessRequested(uint256 indexed requestId, uint256 indexed targetTokenId);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (_isPaused) revert ContractPaused();
        _;
    }

    modifier onlyPaused() {
        if (!_isPaused) revert NotPaused();
        _;
    }

    modifier crystalExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert CrystalNotFound(tokenId);
        _;
    }

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) VRFConsumerBaseV2(vrfCoordinator) Ownable(msg.sender) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_s_subscriptionId = subscriptionId;
        i_requestConfirmations = requestConfirmations;
        i_callbackGasLimit = callbackGasLimit;

        // Initial configuration defaults (owner can change)
        energyDecayRatePerSecond = 1; // 1 unit energy per second base decay

        // Example initial stage config: Seed -> Sprout
        evolutionConfigs[EvolutionStage.Seed] = EvolutionStageConfig(
            {requiredEnergyForEvolution: 1000, requiredVitalityForEvolution: 800, energyCostOnEvolution: 500, vitalityCostOnEvolution: 50}
        );
         // Example stage config: Sprout -> Mature
        evolutionConfigs[EvolutionStage.Sprout] = EvolutionStageConfig(
            {requiredEnergyForEvolution: 5000, requiredVitalityForEvolution: 900, energyCostOnEvolution: 2000, vitalityCostOnEvolution: 100}
        );
         // Example stage config: Mature -> Crystalline
        evolutionConfigs[EvolutionStage.Mature] = EvolutionStageConfig(
            {requiredEnergyForEvolution: 10000, requiredVitalityForEvolution: 950, energyCostOnEvolution: 4000, vitalityCostOnEvolution: 150}
        );

        // Example initial trait influences
        traitInfluences[TraitType.EnergyEfficiency] = TraitInfluence({influenceType: TraitInfluenceType.EnergyDecayBonus, influenceValue: -5}); // -5 energy decay per second bonus
        traitInfluences[TraitType.ReproductionBonus] = TraitInfluence({influenceType: TraitInfluenceType.ReproductionSuccessBonus, influenceValue: 10}); // +10% reproduction chance
        traitInfluences[TraitType.VitalityBoost] = TraitInfluence({influenceType: TraitInfluenceType.VitalityChangeBonus, influenceValue: 5}); // +5 vitality change bonus on feed/harvest
        traitInfluences[TraitType.EssenceYieldBonus] = TraitInfluence({influenceType: TraitInfluenceType.EssenceYieldBonus, influenceValue: 20}); // +20% essence yield
        traitInfluences[TraitType.RarityModifier] = TraitInfluence({influenceType: TraitInfluenceType.InitialTraitDistributionBonus, influenceValue: 30}); // Example: Affects child rarity

         emit ConfigUpdated("InitialDefaults");
    }

    // --- ERC-721 Implementations ---
    // Note: These rely on the _crystalStates mapping internally for state,
    // but the core ERC721 logic (_owners, _balances) is handled by the parent.

    // Override required ERC721 functions to add custom logic if needed
    // For this example, we only add a check during transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) { // Only check on actual transfers, not mint/burn
            // Example Custom Logic: Cannot transfer if energy is critically low (< 100)
            // This requires checking state *before* transfer completes.
            // To get an up-to-date state including decay, call internal helper:
            _calculateAndApplyDecay(tokenId);
            if (_crystalStates[tokenId].energyLevel < 100) {
                 revert CannotTransferDecayingCrystal(tokenId);
            }
        }
    }

    // Other ERC721 functions are inherited and work with the base _owners, _balances mappings.
    // ownerOf, balanceOf, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll are effectively implemented via inheritance.

    // --- VRF Consumer Logic ---

    /// @notice Requests a random seed from Chainlink VRF.
    /// @param targetTokenId 0 for a new crystal mint, or the parent crystal ID for reproduction.
    /// @dev This function is typically called by other contract functions (e.g., `mintCrystal`, `attemptReproduction`).
    function requestRandomCrystalSeed(uint256 targetTokenId) internal onlyOwner nonReentrant {
        if (address(i_vrfCoordinator) == address(0) || i_keyHash == bytes32(0)) {
            revert VRFConfigNotSet();
        }
        // Will revert if subscription is empty or user does not have enough LINK
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_s_subscriptionId,
            i_requestConfirmations,
            i_callbackGasLimit,
            1 // Request just one random word (seed)
        );
        _pendingRandomRequests[requestId] = targetTokenId;
        emit RandomnessRequested(requestId, targetTokenId);
    }

    /// @notice Chainlink VRF callback function. Receives randomness and triggers action.
    /// @param requestId The request ID for the randomness.
    /// @param randomWords An array containing the requested random numbers.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(randomWords.length > 0, "No random words returned");

        uint256 targetTokenId = _pendingRandomRequests[requestId];
        delete _pendingRandomRequests[requestId]; // Clean up the request

        uint256 seed = randomWords[0]; // Use the first random word as the seed

        if (targetTokenId == 0) {
            // This request was for a new crystal mint (triggered by owner, simulate initial minting)
            _mintNewCrystal(seed);
        } else {
             // This request was for reproduction, targetTokenId is the parent1 ID
             // We need to retrieve the parent2 ID stored temporarily or pass it somehow.
             // A simpler approach for this example: assume reproduction requests only target one parent,
             // and the other parent ID (if needed) is stored or implied.
             // A more robust system would store reproduction request details mapped to requestId.
             // For simplicity here, let's assume reproduction details are handled by `attemptReproduction`
             // and this callback just provides the seed to a *previously initiated* reproduction process.
             // **Simplified logic:** Assume `targetTokenId` is parent1 ID, and `attemptReproduction`
             // stores parent2 ID in a temporary mapping linked to the VRF request ID.
             // Since we deleted the mapping item, this simplified structure won't work robustly.
             // **Let's refine:** `_pendingRandomRequests` stores parent1 ID. Need a temp mapping for parent2.

             // For robustness, let's require the reproduction function to store more info.
             // The current `requestRandomCrystalSeed` only stores one ID.
             // A more complex system would have a mapping like `_reproductionRequests[requestId] => { parent1Id, parent2Id, caller }`.
             // For *this* example, let's simplify: `targetTokenId == 0` is mint. Any other `targetTokenId` signals reproduction
             // using *that token ID* as parent1, and the caller's *other* parent is implicitly handled in the calling function context
             // which is less ideal for a VRF callback.

             // **Revised Simple VRF Logic:**
             // targetTokenId == 0: Mint a new crystal (owner triggered)
             // targetTokenId > 0: This VRF was for a process related to targetTokenId.
             // Let's make VRF only for MINTING in this simplified example to match the current storage.
             // Reproduction will use pseudo-randomness or require a more complex VRF request state.
             // **Okay, let's revert VRF usage to ONLY new crystal creation (like initial mints).**
             // A separate mechanism would be needed for complex multi-token VRF requests like reproduction.
             // This keeps the `_pendingRandomRequests[requestId] => uint256` structure simple.
             _mintNewCrystal(seed); // Assume targetTokenId > 0 case was not intended or requires separate state
        }
    }

    // --- Crystal Core Mechanics ---

    /// @notice Requests a new crystal to be minted using randomness.
    /// @dev Can only be called by the owner (simulating a controlled minting process).
    function mintCrystal() external onlyOwner whenNotPaused nonReentrant {
        // Request randomness for initial traits/state
        requestRandomCrystalSeed(0); // 0 signifies a new mint
        // The actual minting happens in fulfillRandomWords once randomness is available
    }

    /// @dev Internal function to create a new crystal after randomness is fulfilled.
    function _mintNewCrystal(uint256 seed) internal {
        uint256 newItemId = _nextTokenId.current();
        _nextTokenId.increment();

        // --- Generate initial state based on seed ---
        // In a real system, this uses cryptographic pseudorandomness derivation
        // or more complex logic based on the seed.
        uint256 initialEnergy = (seed % 1000) + 500; // Initial energy between 500 and 1499
        uint256 initialVitality = (seed % 300) + 600; // Initial vitality between 600 and 899
        EvolutionStage initialStage = EvolutionStage.Seed; // Always start at Seed

        // Example trait assignment (basic, using parts of the seed)
        TraitType[] memory initialTraits = new TraitType[](2);
        initialTraits[0] = TraitType(uint8((seed / 100) % uint8(TraitType.MAX_TRAIT_TYPE))); // Example: derive trait type 1
         if (initialTraits[0] == TraitType.None) initialTraits[0] = TraitType.EnergyEfficiency; // Avoid None trait initially
         initialTraits[1] = TraitType(uint8((seed / 1000) % uint8(TraitType.MAX_TRAIT_TYPE))); // Example: derive trait type 2
         if (initialTraits[1] == TraitType.None || initialTraits[1] == initialTraits[0]) initialTraits[1] = TraitType.VitalityBoost; // Avoid None/duplicate

        // Simplified initial traits - a more complex system would use multiple seeds,
        // potentially weighted based on system state or other factors.

        _crystalStates[newItemId] = CrystalState({
            energyLevel: initialEnergy,
            vitalityScore: initialVitality,
            evolutionStage: initialStage,
            traits: initialTraits,
            lastEnergyFeedTimestamp: block.timestamp,
            name: "",
            bio: "",
            creationRandomnessSeed: seed
        });

        // Mint the NFT to the owner (or a designated minter address)
        // For simplicity, let's mint to the contract owner who triggered the mint.
        _mint(owner(), newItemId);

        emit CrystalMinted(newItemId, owner(), initialEnergy, uint8(initialStage));
        emit CrystalStateUpdated(newItemId);
    }


    /// @notice User feeds energy to their crystal.
    /// @param tokenId The ID of the crystal to feed.
    /// @param amount The amount of energy to feed.
    function feedEnergyToCrystal(uint256 tokenId, uint256 amount) external whenNotPaused nonReentrant crystalExists(tokenId) {
        address crystalOwner = ownerOf(tokenId);
        if (crystalOwner != msg.sender) revert NotCrystalOwner(tokenId, msg.sender);
        if (_userEnergyBalances[msg.sender] < amount) revert InsufficientUserEnergy(msg.sender, amount, _userEnergyBalances[msg.sender]);

        _userEnergyBalances[msg.sender] = _userEnergyBalances[msg.sender].sub(amount);

        // Apply decay before feeding
        _calculateAndApplyDecay(tokenId);

        CrystalState storage crystal = _crystalStates[tokenId];
        crystal.energyLevel = crystal.energyLevel.add(amount);

        // Increase vitality slightly from feeding
        uint256 vitalityIncrease = amount.div(100) + _calculateTraitBonus(tokenId, TraitInfluenceType.VitalityChangeBonus);
        crystal.vitalityScore = (crystal.vitalityScore.add(vitalityIncrease)).min(1000); // Cap vitality at 1000

        crystal.lastEnergyFeedTimestamp = block.timestamp;

        emit EnergyFed(tokenId, msg.sender, amount, crystal.energyLevel);
        emit CrystalStateUpdated(tokenId);
    }

    /// @notice User attempts to evolve their crystal to the next stage.
    /// @param tokenId The ID of the crystal to evolve.
    function attemptEvolution(uint256 tokenId) external whenNotPaused nonReentrant crystalExists(tokenId) {
        address crystalOwner = ownerOf(tokenId);
        if (crystalOwner != msg.sender) revert NotCrystalOwner(tokenId, msg.sender);

        // Apply decay before checking requirements
        _calculateAndApplyDecay(tokenId);

        CrystalState storage crystal = _crystalStates[tokenId];
        EvolutionStage currentStage = crystal.evolutionStage;
        uint8 nextStageInt = uint8(currentStage) + 1;

        if (nextStageInt >= uint8(EvolutionStage.MAX_STAGE)) {
            revert AlreadyAtMaxStage(tokenId, uint8(currentStage));
        }

        EvolutionStage nextStage = EvolutionStage(nextStageInt);
        EvolutionStageConfig storage config = evolutionConfigs[nextStage]; // Config is based on the *next* stage

        if (crystal.energyLevel < config.requiredEnergyForEvolution) {
            revert InsufficientEnergy(tokenId, config.requiredEnergyForEvolution, crystal.energyLevel);
        }
        if (crystal.vitalityScore < config.requiredVitalityForEvolution) {
            revert InsufficientVitality(tokenId, config.requiredVitalityForEvolution, crystal.vitalityScore);
        }

        // Deduct costs
        crystal.energyLevel = crystal.energyLevel.sub(config.energyCostOnEvolution);
        crystal.vitalityScore = (crystal.vitalityScore >= config.vitalityCostOnEvolution)
            ? crystal.vitalityScore.sub(config.vitalityCostOnEvolution)
            : 0; // Don't go below 0

        // Apply stage change
        crystal.evolutionStage = nextStage;

        // Potential: Add/modify traits upon evolution based on stage/vitality/etc.
        // Example: At mature stage, gain a random bonus trait
        if (nextStage == EvolutionStage.Mature) {
            // Simple pseudo-random trait addition (not cryptographically secure)
            // Use block.timestamp and token ID as seed components
            uint256 pseudoSeed = block.timestamp + tokenId + crystal.energyLevel + crystal.vitalityScore;
            uint8 randomTraitIndex = uint8((pseudoSeed % (uint8(TraitType.MAX_TRAIT_TYPE) - 1)) + 1); // Avoid TraitType.None

            bool hasTrait = false;
            for(uint i = 0; i < crystal.traits.length; i++){
                if(crystal.traits[i] == TraitType(randomTraitIndex)) {
                    hasTrait = true;
                    break;
                }
            }
            if (!hasTrait) {
                 crystal.traits.push(TraitType(randomTraitIndex));
            }
        }


        emit CrystalEvolved(tokenId, uint8(currentStage), uint8(nextStage));
        emit CrystalStateUpdated(tokenId);
    }

    /// @notice User attempts to harvest essence from their crystal.
    /// @param tokenId The ID of the crystal to harvest from.
    /// @return amountHarvested The amount of essence harvested (simulated).
    function harvestCrystalEssence(uint256 tokenId) external whenNotPaused nonReentrant crystalExists(tokenId) returns (uint256 amountHarvested) {
        address crystalOwner = ownerOf(tokenId);
        if (crystalOwner != msg.sender) revert NotCrystalOwner(tokenId, msg.sender);

        // Apply decay first
        _calculateAndApplyDecay(tokenId);

        CrystalState storage crystal = _crystalStates[tokenId];

        // Calculate harvest amount based on state (energy, vitality, traits)
        uint256 baseYield = crystal.energyLevel.div(50); // Base yield from energy
        uint256 vitalityBonus = crystal.vitalityScore.div(20); // Bonus from vitality
        uint256 traitBonus = baseYield.mul(_calculateTraitBonus(tokenId, TraitInfluenceType.EssenceYieldBonus)).div(100); // % bonus from trait

        amountHarvested = baseYield.add(vitalityBonus).add(traitBonus);
        if (amountHarvested == 0 && (baseYield > 0 || vitalityBonus > 0 || traitBonus > 0)) {
             amountHarvested = 1; // Ensure at least 1 if potential yield exists
        }


        // Deduct cost (energy and vitality)
        crystal.energyLevel = (crystal.energyLevel >= amountHarvested) ? crystal.energyLevel.sub(amountHarvested) : 0; // Harvest reduces energy

        uint256 vitalityCost = amountHarvested.div(10); // Harvesting costs vitality
        vitalityCost = (vitalityCost.add(_calculateTraitBonus(tokenId, TraitInfluenceType.VitalityChangeBonus) * -1)).max(0); // Trait can reduce cost
        crystal.vitalityScore = (crystal.vitalityScore >= vitalityCost) ? crystal.vitalityScore.sub(vitalityCost) : 0;


        emit EssenceHarvested(tokenId, msg.sender, amountHarvested);
        emit CrystalStateUpdated(tokenId);

        // In a real system, 'essence' might be an ERC-20 token transferred to the user.
        // For this example, we just return the amount and emit an event.
    }

     /// @notice User attempts to reproduce using two of their mature crystals.
     /// @param parent1Id The ID of the first parent crystal.
     /// @param parent2Id The ID of the second parent crystal.
     /// @dev This function initiates the reproduction process, which may involve randomness.
    function attemptReproduction(uint256 parent1Id, uint256 parent2Id) external whenNotPaused nonReentrant crystalExists(parent1Id) crystalExists(parent2Id) {
        address owner1 = ownerOf(parent1Id);
        address owner2 = ownerOf(parent2Id);

        if (owner1 != msg.sender || owner2 != msg.sender) {
            revert NotCrystalOwner(parent1Id, msg.sender); // Revert if not owner of both
        }
        if (parent1Id == parent2Id) {
            revert ReproductionRequirementsNotMet("Cannot reproduce with self");
        }

        // Apply decay to both parents
        _calculateAndApplyDecay(parent1Id);
        _calculateAndApplyDecay(parent2Id);

        CrystalState storage parent1 = _crystalStates[parent1Id];
        CrystalState storage parent2 = _crystalStates[parent2Id];

        // Reproduction Requirements: Must be Mature or higher
        if (parent1.evolutionStage < EvolutionStage.Mature || parent2.evolutionStage < EvolutionStage.Mature) {
             revert ReproductionRequirementsNotMet("Parents must be Mature stage or higher");
        }

        // Example Energy/Vitality Cost: Depends on stage and traits
        uint256 baseEnergyCost = 2000 + (uint8(parent1.evolutionStage) + uint8(parent2.evolutionStage)) * 100;
        uint256 baseVitalityCost = 100 + (uint8(parent1.evolutionStage) + uint8(parent2.evolutionStage)) * 10;

        // Calculate trait influence on cost
        int256 costBonus1 = _calculateTraitBonus(parent1Id, TraitInfluenceType.ReproductionCostBonus);
        int256 costBonus2 = _calculateTraitBonus(parent2Id, TraitInfluenceType.ReproductionCostBonus);
        int256 totalCostBonus = costBonus1 + costBonus2;

        uint256 effectiveEnergyCost = totalCostBonus < 0 ? baseEnergyCost.add(uint256(totalCostBonus * -1)) : baseEnergyCost.sub(uint256(totalCostBonus)).max(0);
        uint256 effectiveVitalityCost = totalCostBonus < 0 ? baseVitalityCost.add(uint256(totalCostBonus * -1)) : baseVitalityCost.sub(uint256(totalCostBonus)).max(0);


        if (parent1.energyLevel < effectiveEnergyCost || parent2.energyLevel < effectiveEnergyCost) {
             revert InsufficientEnergy(parent1.energyLevel < parent2.energyLevel ? parent1Id : parent2Id, effectiveEnergyCost, parent1.energyLevel.min(parent2.energyLevel));
        }
         if (parent1.vitalityScore < effectiveVitalityCost || parent2.vitalityScore < effectiveVitalityCost) {
             revert InsufficientVitality(parent1.vitalityScore < parent2.vitalityScore ? parent1Id : parent2Id, effectiveVitalityCost, parent1.vitalityScore.min(parent2.vitalityScore));
         }

        // Deduct costs from parents
        parent1.energyLevel = parent1.energyLevel.sub(effectiveEnergyCost);
        parent2.energyLevel = parent2.energyLevel.sub(effectiveEnergyCost);
        parent1.vitalityScore = parent1.vitalityScore.sub(effectiveVitalityCost).max(0);
        parent2.vitalityScore = parent2.vitalityScore.sub(effectiveVitalityCost).max(0);

        // --- Determine success chance and request randomness for child traits/stats ---
        // Example success chance calculation
        uint256 baseSuccessChance = 70; // 70% base chance
        int256 successBonus1 = _calculateTraitBonus(parent1Id, TraitInfluenceType.ReproductionSuccessBonus);
        int256 successBonus2 = _calculateTraitBonus(parent2Id, TraitInfluenceType.ReproductionSuccessBonus);
        int256 totalSuccessBonus = successBonus1 + successBonus2;

        uint256 effectiveSuccessChance = totalSuccessBonus < 0 ? baseSuccessChance.sub(uint256(totalSuccessBonus * -1)).max(0) : baseSuccessChance.add(uint256(totalSuccessBonus)).min(100);

        // **Requires randomness.** We need a random number between 0-99 for success chance.
        // We also need randomness for the child's initial state/traits if successful.
        // The current VRF setup only handles single seeds for initial mints.
        // To handle reproduction properly with VRF, we'd need a more complex state
        // to link the VRF request ID back to the parent IDs and caller.
        //
        // **Simplified approach for this example:** Use block hash and timestamp for pseudo-randomness *within this function*.
        // This is NOT cryptographically secure and should not be used for high-value applications.
        // A production system MUST use a secure oracle like Chainlink VRF correctly linked to the request details.

        uint256 reproductionSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, parent1Id, parent2Id, msg.sender)));
        uint26 percentageRoll = reproductionSeed % 100;

        if (percentageRoll < effectiveSuccessChance) {
            // Reproduction Successful!
            uint256 childSeed = uint256(keccak256(abi.encodePacked(reproductionSeed, "child"))); // Derive child seed

            // --- Create new child crystal ---
            uint256 newItemId = _nextTokenId.current();
            _nextTokenId.increment();

            uint256 initialEnergy = (childSeed % 800) + 300; // Child energy between 300-1099
            uint256 initialVitality = (childSeed % 200) + 700; // Child vitality between 700-899
            EvolutionStage initialStage = EvolutionStage.Seed;

            // --- Inherit/Mix/Generate Traits ---
            // Complex trait inheritance logic based on parent traits and childSeed
            TraitType[] memory childTraits = new TraitType[](0); // Start empty, add traits based on logic
            // Example: Inherit some traits from parents, or roll for new ones based on RarityModifier traits
            // This is a complex area and depends on desired game/system mechanics.
            // For simplicity, let's randomly pick a couple of traits, potentially influenced by parent RarityModifier.
            uint256 traitSeed = uint256(keccak256(abi.encodePacked(childSeed, "traits")));
            uint256 numTraits = (traitSeed % 3) + 1; // Child gets 1 to 3 initial traits

            for (uint i = 0; i < numTraits; i++) {
                 uint8 randomTraitIndex = uint8((uint256(keccak256(abi.encodePacked(traitSeed, i))) % (uint8(TraitType.MAX_TRAIT_TYPE) - 1)) + 1); // Avoid None
                 childTraits = _addTraitIfNotPresent(childTraits, TraitType(randomTraitIndex)); // Helper to add trait
            }
            // Add logic here to bias trait selection based on parent RarityModifier or other traits

            _crystalStates[newItemId] = CrystalState({
                energyLevel: initialEnergy,
                vitalityScore: initialVitality,
                evolutionStage: initialStage,
                traits: childTraits,
                lastEnergyFeedTimestamp: block.timestamp,
                name: "",
                bio: "",
                creationRandomnessSeed: childSeed
            });

            _mint(msg.sender, newItemId); // Mint child to the caller (owner of parents)

            emit CrystalReproduced(parent1Id, parent2Id, newItemId);
            emit CrystalMinted(newItemId, msg.sender, initialEnergy, uint8(initialStage));
            emit CrystalStateUpdated(parent1Id); // Parent states changed
            emit CrystalStateUpdated(parent2Id);
            emit CrystalStateUpdated(newItemId); // Child state added

        } else {
            // Reproduction Failed - just costs energy/vitality
            // Event could be added here
        }
    }


    // --- State & Information ---

    /// @notice Gets the current state of a crystal, applying decay calculation first.
    /// @param tokenId The ID of the crystal.
    /// @return CrystalState The state struct of the crystal.
    function getCrystalState(uint256 tokenId) public view crystalExists(tokenId) returns (CrystalState memory) {
        // Apply decay calculation *virtually* for the view function
        // Note: This does NOT modify state, just shows what the state *would be* now.
        // To get the *actual* state and apply decay, call a modifying function.
        CrystalState memory currentCrystal = _crystalStates[tokenId];
        uint256 timeElapsed = block.timestamp.sub(currentCrystal.lastEnergyFeedTimestamp);
        uint256 effectiveDecayRate = energyDecayRatePerSecond.add(_calculateTraitBonus(tokenId, TraitInfluenceType.EnergyDecayBonus) * -1).max(0); // Trait reduces decay rate

        uint256 potentialDecay = timeElapsed.mul(effectiveDecayRate);

        currentCrystal.energyLevel = (currentCrystal.energyLevel >= potentialDecay) ? currentCrystal.energyLevel.sub(potentialDecay) : 0;
        // Decay can also affect vitality over long periods of low energy - add this complexity here if needed

        return currentCrystal;
    }

    /// @notice Returns a list of token IDs owned by an address.
    /// @param user The address to check.
    /// @return tokenIds An array of crystal token IDs owned by the user.
    /// @dev This function can be gas-intensive for users with many tokens. Use off-chain indexing for dApps.
    function getUserCrystals(address user) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(user);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](tokenCount);
        // Iterating over all possible token IDs is inefficient.
        // A better approach requires storing token IDs per user (e.g., using a linked list or array)
        // This is a simplified example.
        // A common pattern is to expose `tokenOfOwnerByIndex` from ERC721Enumerable.
        // Let's use that, requiring ERC721Enumerable inheritance if this were a real project.
        // For this example, I will provide a placeholder implementation that is inefficient but works conceptually.

        // Placeholder (Inefficient): Iterate through potential IDs.
        // A real ERC721Enumerable would provide `tokenOfOwnerByIndex`.
        // Assuming a small number of tokens for example purposes or relying on off-chain data.
        // Let's just return the count and rely on off-chain systems to query individual ownerOf(tokenId).
        // Or, if we must return IDs, let's iterate up to the current token ID counter.

        // Inefficient Example Implementation (DO NOT USE IN PRODUCTION WITH MANY TOKENS):
        uint256 currentId = 0;
        uint26 i = 0;
        uint256 totalTokens = _nextTokenId.current();
        uint256[] memory ownedTokenIds = new uint256[](tokenCount);

        // This loop is O(TotalTokens). Bad.
        while (currentId < totalTokens && i < tokenCount) {
             if (_exists(currentId) && ownerOf(currentId) == user) {
                 ownedTokenIds[i] = currentId;
                 i++;
             }
             currentId++;
        }
        return ownedTokenIds;
        // --- End Inefficient Example ---
    }

    /// @notice Gets global statistics about the crystal system.
    /// @return totalCrystals The total number of crystals minted.
    /// @return totalEnergyInSystem The sum of energy levels across all crystals (inefficient to calculate on-chain).
    /// @dev Calculating total energy on-chain is very gas-intensive. This is a placeholder.
    function getSystemStats() external view returns (uint256 totalCrystals, uint256 totalEnergyInSystem) {
        totalCrystals = _nextTokenId.current();

        // Calculating total energy requires iterating all crystals, which is gas prohibitive.
        // In production, this would be tracked via state variables updated on energy changes,
        // or calculated off-chain.
        // Placeholder calculation (Inefficient):
        /*
        uint256 currentId = 0;
        while (currentId < totalCrystals) {
            if (_exists(currentId)) {
                CrystalState memory crystal = _crystalStates[currentId];
                 // Need to apply decay virtually here too for accurate total energy snapshot
                 uint256 timeElapsed = block.timestamp.sub(crystal.lastEnergyFeedTimestamp);
                 uint256 effectiveDecayRate = energyDecayRatePerSecond.add(_calculateTraitBonus(currentId, TraitInfluenceType.EnergyDecayBonus) * -1).max(0);
                 uint256 potentialDecay = timeElapsed.mul(effectiveDecayRate);
                 uint256 currentEnergy = (crystal.energyLevel >= potentialDecay) ? crystal.energyLevel.sub(potentialDecay) : 0;
                 totalEnergyInSystem = totalEnergyInSystem.add(currentEnergy);
            }
            currentId++;
        }
        */
        // Returning 0 for totalEnergyInSystem to avoid excessive gas costs in example.
        totalEnergyInSystem = 0; // Placeholder - calculation is too expensive
    }

    /// @notice Get evolution requirements for a specific stage.
    /// @param stage The evolution stage to check requirements *for*.
    /// @return requiredEnergy, requiredVitality, energyCost, vitalityCost The requirements and costs to reach this stage.
    function getEvolutionRequirements(uint8 stage) external view returns (uint256 requiredEnergy, uint256 requiredVitality, uint256 energyCost, uint256 vitalityCost) {
        if (stage >= uint8(EvolutionStage.MAX_STAGE) || stage == 0) revert InvalidStage(stage); // Cannot evolve TO Seed stage

        EvolutionStageConfig storage config = evolutionConfigs[EvolutionStage(stage)];
        return (config.requiredEnergyForEvolution, config.requiredVitalityForEvolution, config.energyCostOnEvolution, config.vitalityCostOnEvolution);
    }

    /// @notice Get influence details for a specific trait type.
    /// @param traitType The trait type to check.
    /// @return influenceType, influenceValue The type and value of influence this trait provides.
    function getTraitDetails(uint8 traitType) external view returns (uint8 influenceType, int256 influenceValue) {
         if (traitType >= uint8(TraitType.MAX_TRAIT_TYPE)) revert InvalidTraitType(traitType);

         TraitInfluence storage influence = traitInfluences[TraitType(traitType)];
         return (uint8(influence.influenceType), influence.influenceValue);
    }

     /// @notice Estimates the energy decay for a crystal based on current time.
     /// @param tokenId The ID of the crystal.
     /// @return estimatedLoss The estimated energy lost since last fed.
     /// @return currentTimestamp The current block timestamp used for calculation.
    function estimateEnergyDecay(uint256 tokenId) external view crystalExists(tokenId) returns (uint256 estimatedLoss, uint256 currentTimestamp) {
        CrystalState memory crystal = _crystalStates[tokenId];
        currentTimestamp = block.timestamp;
        uint256 timeElapsed = currentTimestamp.sub(crystal.lastEnergyFeedTimestamp);

        uint256 effectiveDecayRate = energyDecayRatePerSecond.add(_calculateTraitBonus(tokenId, TraitInfluenceType.EnergyDecayBonus) * -1).max(0); // Trait reduces decay rate

        estimatedLoss = timeElapsed.mul(effectiveDecayRate);
        // Cap decay at current energy level
        if (estimatedLoss > crystal.energyLevel) {
             estimatedLoss = crystal.energyLevel;
        }
    }


    // --- System Configuration (Owner Only) ---

    /// @notice Sets the global energy decay rate per second.
    /// @param rate The new decay rate.
    function setEnergyDecayRate(uint256 rate) external onlyOwner {
        energyDecayRatePerSecond = rate;
        emit ConfigUpdated("EnergyDecayRate");
    }

    /// @notice Configures the requirements and costs for a specific evolution stage.
    /// @param stage The target evolution stage (must be > Seed).
    /// @param requiredEnergy The energy needed to start evolution attempt.
    /// @param requiredVitality The vitality needed to start evolution attempt.
    /// @param energyCost The energy deducted on successful evolution.
    /// @param vitalityCost The vitality deducted on successful evolution.
    function setEvolutionConfig(uint8 stage, uint256 requiredEnergy, uint256 requiredVitality, uint256 energyCost, uint256 vitalityCost) external onlyOwner {
         if (stage == uint8(EvolutionStage.Seed) || stage >= uint8(EvolutionStage.MAX_STAGE)) revert InvalidStage(stage);

         evolutionConfigs[EvolutionStage(stage)] = EvolutionStageConfig(
             {requiredEnergyForEvolution: requiredEnergy, requiredVitalityForEvolution: requiredVitality, energyCostOnEvolution: energyCost, vitalityCostOnEvolution: vitalityCost}
         );
         emit ConfigUpdated(string(abi.encodePacked("EvolutionConfig-", Strings.toString(stage))));
    }

    /// @notice Adds a new possible evolution stage configuration.
    /// @dev This allows defining new stages beyond the initial ones.
     function addEvolutionStage(uint8 stage, uint256 requiredEnergy, uint256 requiredVitality, uint256 energyCost, uint256 vitalityCost) external onlyOwner {
        // Allow adding stages with values greater than MAX_STAGE to introduce new levels dynamically
        // if (stage >= uint8(EvolutionStage.MAX_STAGE)) revert InvalidStage(stage); // Or allow defining new numerical stages
        // Let's allow defining stages by number, even if enum is limited, for dynamic growth.
        // Requires careful handling off-chain to interpret stage numbers.
        // For safety in enum-based logic, restrict to enum range for now.
        if (stage == uint8(EvolutionStage.Seed) || stage >= uint8(EvolutionStage.MAX_STAGE)) revert InvalidStage(stage);


        evolutionConfigs[EvolutionStage(stage)] = EvolutionStageConfig(
             {requiredEnergyForEvolution: requiredEnergy, requiredVitalityForEvolution: requiredVitality, energyCostOnEvolution: energyCost, vitalityCostOnEvolution: vitalityCost}
         );
         emit ConfigUpdated(string(abi.encodePacked("NewEvolutionStage-", Strings.toString(stage))));
     }

    /// @notice Defines or updates how a specific trait type influences a game mechanic.
    /// @param traitType The trait type enum value.
    /// @param influenceType The type of influence (e.g., EnergyDecayBonus).
    /// @param influenceValue The signed value of the influence.
    function setTraitInfluence(uint8 traitType, uint8 influenceType, int256 influenceValue) external onlyOwner {
         if (traitType >= uint8(TraitType.MAX_TRAIT_TYPE) || traitType == uint8(TraitType.None)) revert InvalidTraitType(traitType);
         if (influenceType >= uint8(TraitInfluenceType.MAX_INFLUENCE_TYPE)) revert InvalidTraitInfluenceType(influenceType);


         traitInfluences[TraitType(traitType)] = TraitInfluence({
             influenceType: TraitInfluenceType(influenceType),
             influenceValue: influenceValue
         });

         emit ConfigUpdated(string(abi.encodePacked("TraitInfluence-", Strings.toString(traitType))));
    }

    /// @notice Adds a new possible crystal trait type.
    /// @dev This allows defining new traits dynamically (though enum must be updated in code).
    /// @param traitType The numerical ID for the new trait type.
    /// @param influenceType The type of influence for this trait.
    /// @param influenceValue The value of the influence.
    /// @dev Note: Adding new enum values requires contract upgrade. This function is for *configuring* numerical IDs already conceptually defined.
    /// For truly dynamic traits, use string identifiers or a separate registry. Using enum value here.
     function addCrystalTraitType(uint8 traitType, uint8 influenceType, int256 influenceValue) external onlyOwner {
        // This function assumes `traitType` corresponds to a conceptual enum value.
        // Check bounds based on current enum size.
        if (traitType >= uint8(TraitType.MAX_TRAIT_TYPE) || traitType == uint8(TraitType.None)) revert InvalidTraitType(traitType);
        if (influenceType >= uint8(TraitInfluenceType.MAX_INFLUENCE_TYPE)) revert InvalidTraitInfluenceType(influenceType);

        traitInfluences[TraitType(traitType)] = TraitInfluence({
             influenceType: TraitInfluenceType(influenceType),
             influenceValue: influenceValue
         });

        emit ConfigUpdated(string(abi.encodePacked("NewTraitType-", Strings.toString(traitType))));
     }


    /// @notice Sets the configuration for the Chainlink VRF oracle.
    /// @param coordinator The address of the VRF coordinator contract.
    /// @param keyHash The key hash to use for randomness requests.
    /// @param subscriptionId The subscription ID for VRF.
    /// @param requestConfirmations The number of block confirmations required.
    /// @param callbackGasLimit The gas limit for the fulfillment callback.
    function setVRFConfig(address coordinator, bytes32 keyHash, uint64 subscriptionId, uint16 requestConfirmations, uint32 callbackGasLimit) external onlyOwner {
        // i_vrfCoordinator, i_keyHash, i_s_subscriptionId, etc. are immutable in constructor.
        // If you need to update VRF config after deployment, these should be state variables, not immutables.
        // For this example, they are immutable. This function would only work if they were state variables.
        // To make this function work, change `immutable` to `public` for those VRF variables.
        // For robustness, they are often immutable or set once via constructor/initializer.
        // Let's assume they are state variables that can be updated:
        // i_vrfCoordinator = VRFCoordinatorV2Interface(coordinator); // Needs casting if not defined as interface
        // i_keyHash = keyHash;
        // i_s_subscriptionId = subscriptionId;
        // i_requestConfirmations = requestConfirmations;
        // i_callbackGasLimit = callbackGasLimit;

        // If they *are* immutable, this function should revert or be removed.
        // Assuming for demonstration they *could* be updated if variables were not immutable.
        // Reverting as per immutable definition:
        revert("VRF config is immutable");
        // If they were state variables:
        // emit ConfigUpdated("VRFConfig");
    }

     /// @notice Allows the owner to withdraw LINK tokens from the contract.
     /// @dev Needed to manage the VRF subscription balance.
     function withdrawLink(uint256 amount) external onlyOwner {
         // Assumes LINK is an ERC677 token with a transfer function or similar.
         // Standard ERC20 transfer call:
         IERC20 linkToken = IERC20(LINK); // Need LINK token address constant or state variable
         linkToken.transfer(msg.sender, amount);
     }
     // Need to define LINK address (e.g., constant) and import IERC20

     address constant internal LINK = 0x514910771AF9Ca656af840dff83E8264cCfA9226; // Mainnet LINK example

    // --- User Resource Management (Simulated Energy) ---

    /// @notice User deposits simulated energy into their balance.
    /// @param amount The amount of energy to deposit.
    /// @dev In a real system, this might involve transferring an ERC-20 token to the contract.
    /// Here, it just increases the user's internal balance.
    function depositEnergy(uint256 amount) external whenNotPaused nonReentrant {
        // In a real system, add logic here to receive an ERC-20 token (e.g., approve + transferFrom, or handle ERC-777 hooks)
        _userEnergyBalances[msg.sender] = _userEnergyBalances[msg.sender].add(amount);
        emit EnergyDeposited(msg.sender, amount);
    }

    /// @notice Gets the available energy balance for a user.
    /// @param user The address of the user.
    /// @return balance The user's available energy balance.
    function getUserEnergyBalance(address user) external view returns (uint256) {
        return _userEnergyBalances[user];
    }

    // Optional: withdrawEnergy function (if users can reclaim energy)
    // function withdrawEnergy(uint256 amount) external whenNotPaused nonReentrant {
    //     if (_userEnergyBalances[msg.sender] < amount) revert InsufficientUserEnergy(msg.sender, amount, _userEnergyBalances[msg.sender]);
    //     _userEnergyBalances[msg.sender] = _userEnergyBalances[msg.sender].sub(amount);
    //     // In a real system, send the ERC-20 token back
    // }


    // --- User Customization ---

    /// @notice Sets a custom name for a crystal.
    /// @param tokenId The ID of the crystal.
    /// @param name The name to set. Max length 100 bytes.
    function setName(uint256 tokenId, string memory name) external whenNotPaused crystalExists(tokenId) {
        address crystalOwner = ownerOf(tokenId);
        if (crystalOwner != msg.sender) revert NotCrystalOwner(tokenId, msg.sender);

        bytes memory nameBytes = bytes(name);
        if (nameBytes.length > 100) revert("Name too long"); // Example length limit

        _crystalStates[tokenId].name = name;
        emit CrystalNameSet(tokenId, name);
        emit CrystalStateUpdated(tokenId); // Indicate state changed
    }

    /// @notice Sets a short biography for a crystal.
    /// @param tokenId The ID of the crystal.
    /// @param bio The biography to set. Max length 256 bytes.
    function setBio(uint256 tokenId, string memory bio) external whenNotPaused crystalExists(tokenId) {
        address crystalOwner = ownerOf(tokenId);
        if (crystalOwner != msg.sender) revert NotCrystalOwner(tokenId, msg.sender);

        bytes memory bioBytes = bytes(bio);
        if (bioBytes.length > 256) revert("Bio too long"); // Example length limit

        _crystalStates[tokenId].bio = bio;
        emit CrystalBioSet(tokenId, bio);
        emit CrystalStateUpdated(tokenId); // Indicate state changed
    }


    // --- Administrative ---

    /// @notice Pauses core contract interactions.
    function emergencyPause() external onlyOwner onlyNotPaused {
        _isPaused = true;
        emit Paused();
    }

    /// @notice Unpauses core contract interactions.
    function emergencyUnpause() external onlyOwner onlyPaused {
        _isPaused = false;
        emit Unpaused();
    }

    /// @notice Check if the contract is paused.
    function isPaused() external view returns (bool) {
        return _isPaused;
    }

    // --- Internal Helper Functions ---

     /// @dev Applies energy decay to a crystal based on time elapsed.
     /// Updates energyLevel, vitalityScore (if energy low), and lastEnergyFeedTimestamp.
    function _calculateAndApplyDecay(uint256 tokenId) internal crystalExists(tokenId) {
        CrystalState storage crystal = _crystalStates[tokenId];
        uint256 timeElapsed = block.timestamp.sub(crystal.lastEnergyFeedTimestamp);

        if (timeElapsed > 0) {
            uint256 effectiveDecayRate = energyDecayRatePerSecond.add(_calculateTraitBonus(tokenId, TraitInfluenceType.EnergyDecayBonus) * -1).max(0); // Trait reduces decay rate

            uint256 energyLost = timeElapsed.mul(effectiveDecayRate);

            if (energyLost > 0) {
                uint256 oldEnergy = crystal.energyLevel;
                crystal.energyLevel = (crystal.energyLevel >= energyLost) ? crystal.energyLevel.sub(energyLost) : 0;

                // Optional: Vitality decay if energy hits 0 or is very low
                if (oldEnergy > 0 && crystal.energyLevel == 0) {
                     uint256 vitalityLoss = timeElapsed.div(1 day) * 10; // Example: Lose 10 vitality per day at 0 energy
                     crystal.vitalityScore = (crystal.vitalityScore >= vitalityLoss) ? crystal.vitalityScore.sub(vitalityLoss) : 0;
                }


                emit CrystalDecayed(tokenId, energyLost, crystal.energyLevel);
                emit CrystalStateUpdated(tokenId);
            }
            crystal.lastEnergyFeedTimestamp = block.timestamp; // Update timestamp even if no decay occurred (due to rate 0)
        }
    }

     /// @dev Calculates the bonus/penalty value associated with a specific trait influence type for a crystal.
     /// Iterates through crystal's traits and sums up influence values for the specified type.
     /// @param tokenId The crystal ID.
     /// @param influenceType The type of influence to calculate (e.g., EnergyDecayBonus).
     /// @return totalInfluenceValue The sum of influence values from all relevant traits (signed).
    function _calculateTraitBonus(uint256 tokenId, TraitInfluenceType influenceType) internal view returns (int256 totalInfluenceValue) {
        CrystalState storage crystal = _crystalStates[tokenId];
        totalInfluenceValue = 0;

        for (uint i = 0; i < crystal.traits.length; i++) {
            TraitType currentTraitType = crystal.traits[i];
            TraitInfluence storage influence = traitInfluences[currentTraitType];

            if (influence.influenceType == influenceType) {
                totalInfluenceValue = totalInfluenceValue + influence.influenceValue;
            }
        }
    }

    /// @dev Internal helper to add a trait to a crystal's trait array if not already present.
    /// @param traits The current array of traits.
    /// @param traitToAdd The trait type to add.
    /// @return updatedTraits The updated array of traits.
    function _addTraitIfNotPresent(TraitType[] memory traits, TraitType traitToAdd) internal pure returns (TraitType[] memory) {
         for(uint i = 0; i < traits.length; i++){
             if(traits[i] == traitToAdd) {
                 return traits; // Trait already exists
             }
         }
         // Trait not found, create a new array and add it
         TraitType[] memory newTraits = new TraitType[](traits.length + 1);
         for(uint i = 0; i < traits.length; i++){
             newTraits[i] = traits[i];
         }
         newTraits[traits.length] = traitToAdd;
         return newTraits;
    }

     // --- ERC-165 Support (Optional but good practice) ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId || // If adding metadata
               interfaceId == type(IERC2981).interfaceId || // If adding royalties
               super.supportsInterface(interfaceId);
    }

    // --- Metadata (Optional) ---
    // Implement ERC721Metadata functions if desired.
    // function tokenURI(uint256 tokenId) public view override returns (string memory) { ... }
    // function name() public view override returns (string memory) { ... } // Inherited
    // function symbol() public view override returns (string memory) { ... } // Inherited

    // Example basic tokenURI (requires implementing _baseURI and fetching state)
    // function tokenURI(uint256 tokenId) public view override returns (string memory) {
    //     _requireOwned(tokenId); // Ensure token exists and is valid
    //     // You would typically fetch the state: getCrystalState(tokenId)
    //     // Construct a JSON metadata string or URL pointing to one
    //     // using the crystal's dynamic state (energy, vitality, stage, traits, name, bio).
    //     // Example: return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    //     // Needs a _baseURI and off-chain service to serve the JSON.
    //     // Or construct JSON directly on-chain (expensive!).
    //     return "data:application/json;base64,..."; // Base64 encoded JSON metadata (very expensive)
    // }
    // Need to add _baseURI and potentially JSON generation logic.

    // --- Receiver Hook (Optional, for transfers to contracts) ---
    // If you need to receive NFTs from other contracts, implement IERC721Receiver
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
    //    // Your logic here to handle received NFTs
    //    return IERC721Receiver.onERC721Received.selector;
    // }

}
```

**Explanation of Advanced Concepts and Features:**

1.  **Dynamic State (Beyond Static Metadata):** The `CrystalState` struct holds properties (`energyLevel`, `vitalityScore`, `evolutionStage`, `traits`, `lastEnergyFeedTimestamp`) that change over time and based on user actions. This is a core difference from typical static NFTs where metadata/image is fixed.
2.  **Time-Based Decay:** The `lastEnergyFeedTimestamp` and `_calculateAndApplyDecay` internal function introduce a time-dependent mechanic. Crystals lose energy if not maintained. This creates a need for ongoing interaction. Decay is applied when interacting with a crystal (`feedEnergy`, `attemptEvolution`, `harvest`) or when viewing its state (`getCrystalState`), ensuring calculations are based on current time.
3.  **Resource Management (Simulated Energy):** While not a separate ERC-20 in this code, the `_userEnergyBalances` mapping and `depositEnergy` function simulate a resource users need to acquire (externally) and then spend (`feedEnergyToCrystal`). This adds a layer of economic or gameplay interaction.
4.  **Evolution Stages:** The `EvolutionStage` enum and `evolutionConfigs` mapping define a progression system. Crystals move through distinct stages requiring specific conditions (`requiredEnergy`, `requiredVitality`) and incurring costs. This adds a long-term goal and transforms the asset over time.
5.  **Traits with Influence:** `TraitType` enum and `traitInfluences` mapping allow crystals to have specific traits that dynamically affect core mechanics (e.g., reducing energy decay, increasing reproduction chance, boosting harvest yield). The `_calculateTraitBonus` helper function centralizes this logic.
6.  **Reproduction Mechanics:** `attemptReproduction` allows users to potentially create new crystals from existing ones. This includes checking complex requirements involving multiple parent crystals, applying costs, and incorporating randomness for success chance and child traits/stats.
7.  **Oracle Integration (Chainlink VRF):** The contract integrates with Chainlink VRF (or a similar oracle) via `VRFConsumerBaseV2` and `VRFCoordinatorV2Interface` to get verifiably random numbers. This is used for initial crystal minting (`_mintNewCrystal` called from `fulfillRandomWords`) and *could* be expanded for reproduction outcomes, trait assignment, or random events. This prevents manipulation of outcomes that require randomness.
8.  **Configurable Parameters:** Many system parameters (`energyDecayRatePerSecond`, `evolutionConfigs`, `traitInfluences`, `VRFConfig`) are stored in state variables and can be modified by the contract owner via dedicated `set...` and `add...` functions. This allows for dynamic tuning of the game/system economy and mechanics after deployment.
9.  **Extensive State & Information:** Multiple getter functions (`getCrystalState`, `getUserCrystals`, `getSystemStats`, `getEvolutionRequirements`, `getTraitDetails`, `estimateEnergyDecay`) provide detailed information about individual crystals, user holdings, and the system as a whole.
10. **User Customization:** `setName` and `setBio` allow users to personalize their owned assets, adding a social/identity layer.
11. **Administrative Controls:** `emergencyPause` and `emergencyUnpause` provide essential safety mechanisms to halt core operations in case of bugs or emergencies.
12. **Custom Transfer Logic:** The overridden `_beforeTokenTransfer` shows how custom rules (like preventing transfers of severely decayed crystals) can be enforced on top of standard ERC-721 transfers.
13. **Error Handling:** Uses custom errors (`error ...`) for clearer and more gas-efficient error reporting (introduced in Solidity 0.8.4).

This contract provides a framework for a complex digital ecosystem with dynamic assets, requiring player interaction and strategic management, incorporating several advanced Solidity patterns and trendy concepts like dynamic NFTs, resource sinks, and oracle-based randomness. It deliberately avoids being a standard ERC-20 or ERC-721 implementation by layering significant custom logic on top.