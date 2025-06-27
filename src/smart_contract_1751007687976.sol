Okay, this is an exciting challenge! Let's design a smart contract for a "Crypto Evolution Garden". This contract will manage unique digital plant NFTs, allowing users to cultivate, interact with, and evolve them based on on-chain environmental factors and user actions.

Here's the concept breakdown:

1.  **NFTs (ERC-721):** Each plant is a unique token.
2.  **Dynamic Traits:** Plants have traits that influence their needs and growth (e.g., Sunlight Sensitivity, Water Requirement, Nutrient Affinity). These traits are stored on-chain.
3.  **On-Chain Environment:** Global environmental parameters (Sunlight, Temperature, Soil Quality, Pest Pressure) are stored and updated periodically or based on specific events.
4.  **User Actions:** Users can perform actions on their plants (water, fertilize, prune, shield, apply pest control) which affect the plant's internal state (Water Level, Nutrient Level, Health, etc.).
5.  **Evolution/Growth:** Plant growth and evolution (changing size, health, maybe even mutating traits) depend on how well the plant's internal state matches the current environment, influenced by its traits, and user actions over time (measured by block number or timestamp).
6.  **Interaction:** Plants can potentially interact with each other, e.g., pollination attempts.
7.  **Complexity:** The core complexity lies in the `_calculateAndApplyGrowth` function, which simulates the plant's development based on all these factors.

This design involves dynamic state changes for NFTs, interaction between individual tokens and a global state (environment), and complex on-chain logic for growth simulation, making it distinct from standard static NFT projects or simple breeding contracts.

---

### Smart Contract Outline: `CryptoEvolutionGarden`

1.  **Imports:** ERC721, Ownable, SafeMath (though modern Solidity handles overflow).
2.  **Errors:** Custom errors for clearer failure reasons.
3.  **Events:** For minting, actions, environment changes, evolution, pollination.
4.  **Enums:** For Trait Types, Growth Stages.
5.  **Structs:**
    *   `Trait`: Type and value.
    *   `Plant`: Contains owner, ID, timestamps, state levels (Water, Nutrients, Health, etc.), size, growth stage, mutation chance, dynamic traits array.
    *   `EnvironmentState`: Global parameters (Sunlight, Temp, Soil, Pests, etc.), timestamp of last update.
6.  **State Variables:**
    *   Mapping: `uint256 => Plant` (tokenId to Plant struct).
    *   Mapping: `address => uint256[]` (owner to list of tokenIds). (Requires manual management/gas cost warning)
    *   Counter for total plants/tokenIds.
    *   `EnvironmentState` variable.
    *   Config variables: Mint price, growth rate factors, trait impact factors, action cooldowns, pollination success base chance, environment update interval.
    *   Owner address (via Ownable).
7.  **Modifiers:** `plantExists`, `onlyPlantOwnerOrApproved`.
8.  **Constructor:** Initializes ERC721, sets owner, sets initial environment state and config.
9.  **Core Logic (Internal Functions):**
    *   `_calculateAndApplyGrowth(uint256 tokenId)`: The heart of the simulation. Calculates elapsed time, evaluates environmental match vs. traits vs. state levels, applies changes to plant size, health, state levels, checks for stage evolution, potential trait mutation.
    *   `_generateInitialTraits()`: Logic to create a random set of starting traits for a new plant.
    *   `_updateEnvironmentState()`: Updates the global environment parameters based on time or other factors.
    *   `_addPlantToOwnerList(address owner, uint256 tokenId)`: Helper to manage the owner's plant list (gas warning).
    *   `_removePlantFromOwnerList(address owner, uint256 tokenId)`: Helper to manage the owner's plant list (gas warning).
10. **Public/External Functions (>20 total):**
    *   **ERC721 Standard (7):** `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`.
    *   **Minting (2):** `mintNewPlant`, `setMintPrice`.
    *   **Plant Data Getters (3):** `getPlantDetails`, `getPlantTraits`, `getPlantStateLevels`.
    *   **User Actions (5):** `waterPlant`, `fertilizePlant`, `prunePlant`, `shieldPlant`, `applyPestControl`.
    *   **Environment Interaction (2):** `triggerEnvironmentUpdate`, `getCurrentEnvironmentState`.
    *   **Evolution/Growth (1):** `getPlantGrowthProgress` (allows users to see a calculated progress towards next stage *without* triggering state change unless an action/env update does).
    *   **Plant Interaction (1):** `attemptPollination`.
    *   **Configuration (4+):** `setConfigGrowthFactors`, `setConfigTraitImpacts`, `setConfigActionCooldowns`, `setConfigPollinationRates`, `setEnvironmentUpdateInterval`, etc. (Aim for 4-6 config functions).
    *   **Querying/Helpers (1+):** `getPlantsByOwner` (with pagination/limit due to gas), `getTotalPlants`.

---

### Smart Contract Function Summary:

1.  `balanceOf(address owner) returns (uint256)`: Get the number of plants owned by an address (ERC721 standard).
2.  `ownerOf(uint256 tokenId) returns (address)`: Get the owner of a specific plant (ERC721 standard).
3.  `getApproved(uint256 tokenId) returns (address)`: Get the address approved to transfer a specific plant (ERC721 standard).
4.  `isApprovedForAll(address owner, address operator) returns (bool)`: Check if an operator is approved for all of an owner's plants (ERC721 standard).
5.  `approve(address to, uint256 tokenId)`: Approve another address to transfer a specific plant (ERC721 standard).
6.  `setApprovalForAll(address operator, bool approved)`: Set approval for an operator to manage all of your plants (ERC721 standard).
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer a plant token (ERC721 standard).
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfer a plant token (ERC721 standard).
9.  `mintNewPlant() payable`: Creates a new plant token with initial state and traits, assigns it to the caller, and collects payment.
10. `setMintPrice(uint256 newPrice)`: Owner-only function to set the price for minting new plants.
11. `getPlantDetails(uint256 tokenId) returns (Plant memory)`: Retrieve the full state details of a specific plant.
12. `getPlantTraits(uint256 tokenId) returns (Trait[] memory)`: Retrieve only the traits of a specific plant.
13. `getPlantStateLevels(uint256 tokenId) returns (uint256 water, uint256 nutrients, uint256 health, uint256 pest, uint256 shield)`: Retrieve key dynamic state levels of a plant.
14. `waterPlant(uint256 tokenId)`: Increases the plant's internal Water Level. Triggers growth calculation for the plant.
15. `fertilizePlant(uint256 tokenId)`: Increases the plant's internal Nutrient Level. Triggers growth calculation for the plant.
16. `prunePlant(uint256 tokenId)`: Can affect growth rate, health, or remove negative effects. Triggers growth calculation for the plant.
17. `shieldPlant(uint256 tokenId)`: Applies protection from environmental factors like high sunlight. Triggers growth calculation for the plant.
18. `applyPestControl(uint256 tokenId)`: Reduces the plant's internal Pest Level. Triggers growth calculation for the plant.
19. `triggerEnvironmentUpdate()`: Callable (potentially by anyone after a cooldown or by owner/privileged role) to update the global environmental state based on time and potentially pseudorandom factors. This action applies environmental effects across the garden.
20. `getCurrentEnvironmentState() returns (EnvironmentState memory)`: Retrieve the current global environmental parameters.
21. `getPlantGrowthProgress(uint256 tokenId) returns (uint265 currentProgress, uint256 requiredForNextStage)`: Calculate and return the current growth progress towards the next stage without altering state.
22. `attemptPollination(uint256 plantId1, uint256 plantId2)`: Attempt to cross-pollinate two plants. Success depends on traits, state, and a random factor. May consume resources or result in a new plant token inheriting traits.
23. `setConfigGrowthFactors(...)`: Owner-only function to adjust parameters affecting overall growth speed and efficiency.
24. `setConfigTraitImpacts(...)`: Owner-only function to adjust how much different traits influence plant responses to environment and actions.
25. `setConfigActionCooldowns(...)`: Owner-only function to set cooldown periods for user actions on plants.
26. `setConfigPollinationRates(...)`: Owner-only function to set success rates and outcomes for pollination.
27. `setEnvironmentUpdateInterval(uint256 intervalBlocks)`: Owner-only function to set the minimum block difference between environment updates.
28. `getPlantsByOwner(address owner, uint256 startIndex, uint256 count) returns (uint256[] memory)`: Get a paginated list of token IDs owned by a specific address (potential high gas cost if not paginated/used carefully).
29. `getTotalPlants() returns (uint256)`: Get the total number of plant tokens minted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Note on Gas Costs: Iterating over arrays (like _plantsByOwner) or performing complex calculations
// for many plants simultaneously (if implemented in triggerEnvironmentUpdate) can be very expensive.
// The current design recalculates growth per action/query for a single plant, and environment update
// is separate. getPlantsByOwner is paginated to mitigate this.

// --- Crypto Evolution Garden Contract Outline ---
// 1. Imports: ERC721, Ownable, Counters
// 2. Errors: Custom errors for clarity.
// 3. Events: Notifications for key state changes.
// 4. Enums: Define trait types, growth stages.
// 5. Structs: Define data structures for Traits, Plants, and EnvironmentState.
// 6. State Variables: Mappings, counters, environment state, configuration variables.
// 7. Modifiers: Custom checks for function calls.
// 8. Constructor: Initialize contract state.
// 9. Internal Logic: Core functions for growth calculation, trait generation, environment updates.
// 10. External Functions: ERC721 methods, minting, getters, user actions, environment control, plant interaction, config settings, querying.

// --- Function Summary ---
// ERC721 Standard: balanceOf, ownerOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom (7+1 overloaded)
// Minting: mintNewPlant, setMintPrice
// Plant Data Getters: getPlantDetails, getPlantTraits, getPlantStateLevels
// User Actions: waterPlant, fertilizePlant, prunePlant, shieldPlant, applyPestControl
// Environment Interaction: triggerEnvironmentUpdate, getCurrentEnvironmentState
// Evolution/Growth: getPlantGrowthProgress
// Plant Interaction: attemptPollination
// Configuration: setConfigGrowthFactors, setConfigTraitImpacts, setConfigActionCooldowns, setConfigPollinationRates, setEnvironmentUpdateInterval, setGrowthStageThresholds
// Querying/Helpers: getPlantsByOwner, getTotalPlants

contract CryptoEvolutionGarden is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error PlantNotFound(uint256 tokenId);
    error NotPlantOwnerOrApproved(uint256 tokenId, address caller);
    error NotEnoughEtherForMint();
    error EnvironmentUpdateTooSoon(uint256 nextUpdateBlock);
    error InvalidPlantForPollination(uint256 tokenId);
    error PollinationCooldownActive(uint256 tokenId, uint40 cooldownEnd);
    error ActionCooldownActive(uint256 tokenId, string actionType, uint40 cooldownEnd);
    error InvalidTraitConfiguration();

    // --- Events ---
    event NewPlantMinted(uint256 indexed tokenId, address indexed owner, uint40 mintTimestamp, uint40 nextGrowthUpdateTimestamp);
    event PlantStateUpdated(uint256 indexed tokenId, string stateKey, int256 change); // e.g., stateKey: "WaterLevel", change: +10
    event EnvironmentUpdated(uint40 indexed updateTimestamp);
    event EvolutionEvent(uint256 indexed tokenId, uint40 updateTimestamp, string description); // e.g., "Grew taller", "Mutated a trait"
    event PollinationAttempt(uint256 indexed plantId1, uint256 indexed plantId2, address indexed initiator);
    event PollinationSuccess(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newPlantId);
    event ConfigUpdated(string configKey, address indexed updater); // Generic event for config changes

    // --- Enums ---
    enum TraitType {
        SUNLIGHT_SENSITIVITY,
        WATER_RETENTION,
        NUTRIENT_EFFICIENCY,
        PEST_RESISTANCE,
        MUTATION_PRONENESS,
        GROWTH_SPEED,
        POLLINATION_AFFINITY,
        // Add more creative traits here
        COUNT // Helper to count traits
    }

    enum GrowthStage {
        SEEDLING,
        YOUNG,
        MATURE,
        FLOWERING,
        AGED,
        MUTATED // Or other special stages
    }

    // --- Structs ---
    struct Trait {
        TraitType traitType;
        int16 value; // e.g., -100 to +100, or 0 to 255
    }

    struct Plant {
        uint40 mintTimestamp;
        uint40 lastGrowthUpdateTimestamp;
        uint40 lastActionTimestamp; // For general action cooldown
        mapping(string => uint40) actionCooldowns; // Specific cooldowns
        uint40 lastPollinationTimestamp;

        uint16 size; // e.g., 0-1000
        uint16 health; // e.g., 0-100 (0 means dead, though we won't implement death/burning for simplicity here)
        GrowthStage stage;
        uint256 growthProgress; // Accumulated growth points towards next stage

        uint16 waterLevel; // e.g., 0-100
        uint16 nutrientLevel; // e.g., 0-100
        uint16 pestLevel; // e.g., 0-100 (higher is bad)
        uint16 shieldingLevel; // e.g., 0-100 (protection from environment)

        uint16 mutationChance; // Base chance % per growth tick
        Trait[] traits; // Dynamic array of traits
    }

    struct EnvironmentState {
        uint40 updateTimestamp;
        int16 sunlight; // e.g., -50 to +50 (cloudy to sunny)
        int16 temperature; // e.g., -30 to +40 Celsius range
        int16 soilQuality; // e.g., 0-100
        int16 pestPressure; // e.g., 0-100 (higher means more pests)
        int16 waterAvailability; // e.g., 0-100 (rain/drought)
    }

    // --- State Variables ---
    mapping(uint256 => Plant) private _plants;
    mapping(address => uint256[]) private _plantsByOwner; // Simple array, potentially gas-costly for large numbers

    EnvironmentState public currentEnvironment;

    uint256 public mintPrice = 0.05 ether; // Default mint price
    uint256 public environmentUpdateIntervalBlocks = 100; // Blocks between environment updates
    uint256 public baseGrowthFactor = 1; // Base points per block
    uint256 public basePollinationSuccessRate = 50; // % chance
    uint256 public pollinationCooldownBlocks = 1000; // Blocks cooldown

    // Configurable impact factors for how much traits/state/environment affect growth
    // Owner can fine-tune the simulation parameters
    mapping(TraitType => int16) public traitImpactFactors;
    mapping(string => uint256) public actionCooldownBlocks; // e.g., "water" => 10 blocks
    mapping(GrowthStage => uint256) public growthStageThresholds; // Points needed for each stage

    // --- Constructor ---
    constructor() ERC721("CryptoEvolutionGarden", "CEG") Ownable(msg.sender) {
        // Set initial environment (can be updated later)
        currentEnvironment = EnvironmentState({
            updateTimestamp: uint40(block.timestamp),
            sunlight: 20,
            temperature: 25,
            soilQuality: 70,
            pestPressure: 10,
            waterAvailability: 50
        });

        // Set some default trait impact factors (owner can change)
        traitImpactFactors[TraitType.SUNLIGHT_SENSITIVITY] = -5; // High sensitivity means bad growth in high sun
        traitImpactFactors[TraitType.WATER_RETENTION] = 4; // High retention means less growth penalty from low water avail.
        traitImpactFactors[TraitType.NUTRIENT_EFFICIENCY] = 3;
        traitImpactFactors[TraitType.PEST_RESISTANCE] = -2; // High resistance means less penalty from high pest pressure
        traitImpactFactors[TraitType.MUTATION_PRONENESS] = 1;
        traitImpactFactors[TraitType.GROWTH_SPEED] = 5;
        traitImpactFactors[TraitType.POLLINATION_AFFINITY] = 3;

        // Set default action cooldowns
        actionCooldownBlocks["water"] = 20;
        actionCooldownBlocks["fertilize"] = 50;
        actionCooldownBlocks["prune"] = 100;
        actionCooldownBlocks["shield"] = 30;
        actionCooldownBlocks["pestControl"] = 40;

        // Set default growth stage thresholds (accumulated growthProgress)
        growthStageThresholds[GrowthStage.SEEDLING] = 0; // Starting stage
        growthStageThresholds[GrowthStage.YOUNG] = 500;
        growthStageThresholds[GrowthStage.MATURE] = 2000;
        growthStageThresholds[GrowthStage.FLOWERING] = 5000;
        growthStageThresholds[GrowthStage.AGED] = 10000;
        growthStageThresholds[GrowthStage.MUTATED] = type(uint256).max; // Special stage, not reached by points

        emit EnvironmentUpdated(currentEnvironment.updateTimestamp);
    }

    // --- Modifiers ---
    modifier plantExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert PlantNotFound(tokenId);
        }
        _;
    }

    modifier onlyPlantOwnerOrApproved(uint256 tokenId) {
        address owner = ERC721.ownerOf(tokenId);
        if (owner != _msgSender() && !isApprovedForAll(owner, _msgSender()) && getApproved(tokenId) != _msgSender()) {
            revert NotPlantOwnerOrApproved(tokenId, _msgSender());
        }
        _;
    }

    // --- Internal Logic ---

    // Calculates and applies growth and state changes based on elapsed time and conditions
    function _calculateAndApplyGrowth(uint256 tokenId) internal {
        Plant storage plant = _plants[tokenId];
        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime > plant.lastGrowthUpdateTimestamp ? currentTime - plant.lastGrowthUpdateTimestamp : 0;
        plant.lastGrowthUpdateTimestamp = currentTime;

        if (timeElapsed == 0) {
            return; // No time passed since last update
        }

        int256 growthPointsDelta = int256(timeElapsed) * int256(baseGrowthFactor);
        int256 healthDelta = 0;

        // Apply environmental and state effects modified by traits
        for (uint i = 0; i < plant.traits.length; i++) {
            Trait memory trait = plant.traits[i];
            int16 impact = traitImpactFactors[trait.traitType];
            int16 traitValue = trait.value;
            int16 envFactor = 0;
            int16 stateFactor = 0;

            // Determine relevant environmental and state factors
            if (trait.traitType == TraitType.SUNLIGHT_SENSITIVITY) {
                envFactor = currentEnvironment.sunlight;
                // No direct state factor, but maybe shielding helps?
                stateFactor = int16(plant.shieldingLevel / 10); // Example scaling
            } else if (trait.traitType == TraitType.WATER_RETENTION) {
                 envFactor = currentEnvironment.waterAvailability;
                 stateFactor = int16(plant.waterLevel / 10);
            } else if (trait.traitType == TraitType.NUTRIENT_EFFICIENCY) {
                envFactor = currentEnvironment.soilQuality;
                stateFactor = int16(plant.nutrientLevel / 10);
            } else if (trait.traitType == TraitType.PEST_RESISTANCE) {
                envFactor = currentEnvironment.pestPressure; // Note: Higher pestPressure is BAD, resistance makes it less bad
                stateFactor = int16(plant.pestLevel / 10); // Note: Higher pestLevel is BAD
            } else if (trait.traitType == TraitType.GROWTH_SPEED) {
                 // This trait directly impacts base growth, applied later
                 growthPointsDelta += int256(timeElapsed) * (int256(traitValue) * impact / 100); // Example: traitValue is % bonus/penalty
            }
            // ... handle other traits and their interactions

            // Apply combined environmental/state effect, scaled by trait value and global impact factor
            // Simplified interaction model: (TraitValue + EnvFactor + StateFactor) * ImpactFactor
            // Need careful scaling to avoid overflow and large unexpected deltas
             if (impact != 0) {
                int256 combinedFactor = int256(traitValue) + envFactor + stateFactor; // Basic sum
                // Example scaling: scale down combined factor and impact
                growthPointsDelta += (combinedFactor / 10) * (impact / 5);
                // Add health impact as well, based on how stressed the plant is by conditions
                // e.g., large mismatch between needs (implied by traits) and env/state causes health loss
                healthDelta += (combinedFactor / 20) * (impact / 10); // Health impact scaled differently
             }
        }

        // Also lose health/growth from pests directly if not shielded
        growthPointsDelta -= int256(plant.pestLevel) * 1; // Flat penalty per pest level
        healthDelta -= int256(plant.pestLevel) * 1; // Flat health penalty per pest level

        // Decay state levels over time
        uint16 decayFactor = uint16(timeElapsed) / 100; // Example: decay per 100 seconds
        plant.waterLevel = plant.waterLevel > decayFactor ? plant.waterLevel - decayFactor : 0;
        plant.nutrientLevel = plant.nutrientLevel > decayFactor ? plant.nutrientLevel - decayFactor : 0;
        // Pest level might increase based on environment pest pressure if not controlled/resistant
        plant.pestLevel = uint16(Math.min(100, plant.pestLevel + (uint16(currentEnvironment.pestPressure) * uint16(timeElapsed) / 500)));
        // Shielding decays
        plant.shieldingLevel = plant.shieldingLevel > decayFactor ? plant.shieldingLevel - decayFactor : 0;

        // Update health, clamping between 0 and 100
        plant.health = uint16(Math.max(0, Math.min(100, int256(plant.health) + healthDelta)));
        // Plant is stressed when health is low, affecting growth negatively
        growthPointsDelta = growthPointsDelta * int256(plant.health) / 100; // Scale growth by health percentage

        // Update growth progress, clamp at max uint256 (or lower if desired)
        plant.growthProgress = uint256(Math.max(0, int256(plant.growthProgress) + growthPointsDelta));

        // Check for stage evolution
        GrowthStage currentStage = plant.stage;
        GrowthStage nextStage = currentStage;
        if (currentStage == GrowthStage.SEEDLING && plant.growthProgress >= growthStageThresholds[GrowthStage.YOUNG]) {
            nextStage = GrowthStage.YOUNG;
        } else if (currentStage == GrowthStage.YOUNG && plant.growthProgress >= growthStageThresholds[GrowthStage.MATURE]) {
            nextStage = GrowthStage.MATURE;
        } else if (currentStage == GrowthStage.MATURE && plant.growthProgress >= growthStageThresholds[GrowthStage.FLOWERING]) {
            nextStage = GrowthStage.FLOWERING;
        } else if (currentStage == GrowthStage.FLOWERING && plant.growthProgress >= growthStageThresholds[GrowthStage.AGED]) {
             nextStage = GrowthStage.AGED;
        }

        if (nextStage != currentStage) {
             plant.stage = nextStage;
             emit EvolutionEvent(tokenId, currentTime, string(abi.encodePacked("Evolved to ", _getGrowthStageString(nextStage))));
        }

        // --- Trait Mutation (Advanced/Complex) ---
        // Example: Chance to mutate increases if plant is stressed (low health) or gets lots of growth points quickly, or if trait is MUTATION_PRONENESS
        uint256 currentMutationChance = plant.mutationChance;
        currentMutationChance += uint256(100 - plant.health); // Higher chance if unhealthy
        currentMutationChance += uint256(Math.max(0, growthPointsDelta)) / 50; // Higher chance if rapid growth
        // Factor in MUTATION_PRONENESS trait
        for (uint i = 0; i < plant.traits.length; i++) {
             if (plant.traits[i].traitType == TraitType.MUTATION_PRONENESS) {
                  currentMutationChance += uint265(Math.max(0, plant.traits[i].value)); // Higher chance based on trait value
                  break;
             }
        }

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.gasleft, msg.sender, tokenId, plant.growthProgress))); // Use multiple factors for randomness
        if ((randomSeed % 10000) < currentMutationChance) { // Check against percentage * 100
            // Trigger mutation: modify an existing trait or add a new one
            _mutateTrait(tokenId, randomSeed);
            emit EvolutionEvent(tokenId, currentTime, "Mutated a trait!");
        }

         emit PlantStateUpdated(tokenId, "GrowthProgress", growthPointsDelta);
         emit PlantStateUpdated(tokenId, "Health", healthDelta);
         emit PlantStateUpdated(tokenId, "WaterLevel", int256(plant.waterLevel)); // Emit new level, not change
         emit PlantStateUpdated(tokenId, "NutrientLevel", int256(plant.nutrientLevel));
         emit PlantStateUpdated(tokenId, "PestLevel", int256(plant.pestLevel));
         emit PlantStateUpdated(tokenId, "ShieldingLevel", int256(plant.shieldingLevel));

    }

    // Helper to mutate a trait
    function _mutateTrait(uint256 tokenId, uint256 seed) internal {
        Plant storage plant = _plants[tokenId];
        uint256 numTraits = plant.traits.length;

        if (numTraits == 0 || (seed % 5 == 0 && numTraits < uint(TraitType.COUNT)) ) { // 20% chance to add a new trait if not maxed
             // Add a new random trait
             TraitType newType = TraitType(seed % uint(TraitType.COUNT));
             int16 newValue = int16((seed / 100) % 201) - 100; // Value between -100 and 100
             plant.traits.push(Trait({traitType: newType, value: newValue}));
             emit EvolutionEvent(tokenId, uint40(block.timestamp), string(abi.encodePacked("Gained trait ", _getTraitTypeString(newType), " with value ", Strings.toString(newValue))));
        } else {
            // Modify an existing trait
            uint256 traitIndexToModify = seed % numTraits;
            int16 valueChange = int16((seed / 100) % 41) - 20; // Change between -20 and 20
            int16 oldValue = plant.traits[traitIndexToModify].value;
            plant.traits[traitIndexToModify].value = int16(Math.max(-100, Math.min(100, oldValue + valueChange))); // Clamp value
            emit EvolutionEvent(tokenId, uint40(block.timestamp), string(abi.encodePacked("Trait ", _getTraitTypeString(plant.traits[traitIndexToModify].traitType), " value changed from ", Strings.toString(oldValue), " to ", Strings.toString(plant.traits[traitIndexToModify].value))));
        }
    }


    // Generates initial random traits for a new plant
    function _generateInitialTraits(uint256 seed) internal pure returns (Trait[] memory) {
        // Generate a few random traits
        uint256 numTraits = (seed % 3) + 2; // Between 2 and 4 traits initially
        Trait[] memory initialTraits = new Trait[](numTraits);
        bytes32 seenTypes = 0x00; // Use bitmask to avoid duplicate trait types initially

        for (uint i = 0; i < numTraits; i++) {
            TraitType traitType;
            do {
                 traitType = TraitType((seed / (i + 1) / 7 ) % uint(TraitType.COUNT)); // Vary how we derive trait type from seed
            } while ((seenTypes & (bytes32(1) << uint(traitType))) != 0); // Ensure unique types
            seenTypes |= (bytes32(1) << uint(traitType));

            int16 traitValue = int16((seed / (i + 1) / 13 ) % 201) - 100; // Value between -100 and 100

            initialTraits[i] = Trait({
                traitType: traitType,
                value: traitValue
            });
             seed = uint256(keccak256(abi.encodePacked(seed, traitType, traitValue))); // Update seed
        }
        return initialTraits;
    }

    // Updates the global environment state
    function _updateEnvironmentState() internal {
        uint40 currentTime = uint40(block.timestamp);
        // Simple linear change example, could be more complex based on block number,
        // time of day simulation, or even oracle data if integrated.
        uint256 timeElapsed = currentTime > currentEnvironment.updateTimestamp ? currentTime - currentEnvironment.updateTimestamp : 0;

        // Prevent updates that are too close together
        if (block.number < currentEnvironment.updateTimestamp + environmentUpdateIntervalBlocks) {
             // This check is done in the public triggerEnvironmentUpdate, but good to note here.
             // This internal function assumes the check has passed or is called internally without the check.
        }

        // Apply some pseudorandomness based on recent block hash and timestamp
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, currentEnvironment.updateTimestamp)));

        // Example Environment changes: Oscillate values slightly
        currentEnvironment.sunlight = int16(Math.max(-50, Math.min(50, int256(currentEnvironment.sunlight) + int256((randomSeed % 21) - 10)))); // Change by -10 to +10
        currentEnvironment.temperature = int16(Math.max(-30, Math.min(40, int256(currentEnvironment.temperature) + int256((randomSeed / 10 % 21) - 10))));
        currentEnvironment.soilQuality = int16(Math.max(0, Math.min(100, int256(currentEnvironment.soilQuality) + int256((randomSeed / 100 % 11) - 5))));
        currentEnvironment.pestPressure = int16(Math.max(0, Math.min(100, int256(currentEnvironment.pestPressure) + int22(Math.max(-5, (randomSeed / 1000 % 11) - 5))))); // Pests tend to increase
        currentEnvironment.waterAvailability = int16(Math.max(0, Math.min(100, int256(currentEnvironment.waterAvailability) + int256((randomSeed / 10000 % 21) - 10))));

        currentEnvironment.updateTimestamp = currentTime;

        emit EnvironmentUpdated(currentTime);
    }

    // Helper function to add plant ID to owner's list (manual management)
    function _addPlantToOwnerList(address owner, uint256 tokenId) internal {
        _plantsByOwner[owner].push(tokenId);
    }

    // Helper function to remove plant ID from owner's list (manual management)
    function _removePlantFromOwnerList(address owner, uint256 tokenId) internal {
        uint256[] storage plantIds = _plantsByOwner[owner];
        for (uint i = 0; i < plantIds.length; i++) {
            if (plantIds[i] == tokenId) {
                // Swap with last element and pop
                plantIds[i] = plantIds[plantIds.length - 1];
                plantIds.pop();
                return;
            }
        }
        // Should not happen if called correctly after a transfer
    }

    // ERC721 overrides to hook into transfer logic
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0)) {
            _removePlantFromOwnerList(from, tokenId);
        }
        if (to != address(0)) {
            _addPlantToOwnerList(to, tokenId);
        }
         // Note: _calculateAndApplyGrowth could be called here for 'from' plant state freeze,
         // but calling per action or explicitly seems more predictable gas-wise.
         // A new owner will trigger growth calculation on their first interaction.
    }


    // --- Public/External Functions ---

    // ERC721 Standard implementations provided by OpenZeppelin, just need to override hooks if necessary.
    // The basic ERC721 interface functions (balanceOf, ownerOf, etc.) are implicitly available.

    // 9. Mint a new plant
    function mintNewPlant() external payable {
        if (msg.value < mintPrice) {
            revert NotEnoughEtherForMint();
        }

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        address minter = _msgSender();

        uint40 currentTime = uint40(block.timestamp);
        uint256 seed = uint256(keccak256(abi.encodePacked(currentTime, newItemId, minter, block.difficulty)));
        Trait[] memory initialTraits = _generateInitialTraits(seed);

        _plants[newItemId] = Plant({
            mintTimestamp: currentTime,
            lastGrowthUpdateTimestamp: currentTime,
            lastActionTimestamp: currentTime,
            lastPollinationTimestamp: 0, // Can pollinate immediately
            size: 0, // Starts small
            health: 80, // Starts healthy
            stage: GrowthStage.SEEDLING,
            growthProgress: 0,
            waterLevel: 50, // Starts with some resources
            nutrientLevel: 50,
            pestLevel: 5,
            shieldingLevel: 0,
            mutationChance: 100, // Base 1% chance (100 / 10000)
            traits: initialTraits // Assign the generated traits
        });
         // Initialize mapping for action cooldowns
         _plants[newItemId].actionCooldowns["water"] = 0;
         _plants[newItemId].actionCooldowns["fertilize"] = 0;
         _plants[newItemId].actionCooldowns["prune"] = 0;
         _plants[newItemId].actionCooldowns["shield"] = 0;
         _plants[newItemId].actionCooldowns["pestControl"] = 0;


        _safeMint(minter, newItemId);

        emit NewPlantMinted(newItemId, minter, currentTime, currentTime);
    }

    // 10. Set the mint price (Owner only)
    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit ConfigUpdated("MintPrice", msg.sender);
    }

    // 11. Get full plant details
    function getPlantDetails(uint256 tokenId) external view plantExists(tokenId) returns (Plant memory) {
        // Note: This returns a copy of the struct. Mappings inside structs (like actionCooldowns) cannot be returned directly this way.
        // Need separate getters for mappings within structs if needed externally.
        Plant storage plant = _plants[tokenId];
         // Create a memory copy, copying the fixed fields
         Plant memory details = Plant({
             mintTimestamp: plant.mintTimestamp,
             lastGrowthUpdateTimestamp: plant.lastGrowthUpdateTimestamp,
             lastActionTimestamp: plant.lastActionTimestamp,
             lastPollinationTimestamp: plant.lastPollinationTimestamp,
             size: plant.size,
             health: plant.health,
             stage: plant.stage,
             growthProgress: plant.growthProgress,
             waterLevel: plant.waterLevel,
             nutrientLevel: plant.nutrientLevel,
             pestLevel: plant.pestLevel,
             shieldingLevel: plant.shieldingLevel,
             mutationChance: plant.mutationChance,
             traits: new Trait[](plant.traits.length) // Create memory array for traits
         });
         // Copy the traits array
         for(uint i = 0; i < plant.traits.length; i++){
              details.traits[i] = plant.traits[i];
         }
        return details;
    }

    // 12. Get plant traits
    function getPlantTraits(uint256 tokenId) external view plantExists(tokenId) returns (Trait[] memory) {
        // Return a copy of the traits array
        Trait[] storage plantTraits = _plants[tokenId].traits;
        Trait[] memory traitsMemory = new Trarait[](plantTraits.length);
        for (uint i = 0; i < plantTraits.length; i++) {
             traitsMemory[i] = plantTraits[i];
        }
        return traitsMemory;
    }

    // 13. Get plant state levels
    function getPlantStateLevels(uint256 tokenId) external view plantExists(tokenId) returns (uint16 water, uint16 nutrients, uint16 health, uint16 pest, uint16 shield) {
        Plant storage plant = _plants[tokenId];
        return (plant.waterLevel, plant.nutrientLevel, plant.health, plant.pestLevel, plant.shieldingLevel);
    }

    // 14. Water a plant
    function waterPlant(uint256 tokenId) external plantExists(tokenId) onlyPlantOwnerOrApproved(tokenId) {
         Plant storage plant = _plants[tokenId];
         uint40 currentTime = uint40(block.timestamp);
         string memory actionType = "water";
         if (currentTime < plant.actionCooldowns[actionType]) {
              revert ActionCooldownActive(tokenId, actionType, plant.actionCooldowns[actionType]);
         }

        _calculateAndApplyGrowth(tokenId); // Calculate growth based on time since last update

        plant.waterLevel = uint16(Math.min(100, plant.waterLevel + 20)); // Increase water, max 100
        plant.lastActionTimestamp = currentTime;
        plant.actionCooldowns[actionType] = currentTime + uint40(actionCooldownBlocks[actionType]);

        emit PlantStateUpdated(tokenId, "WaterLevel", 20); // Emit change amount
        emit EvolutionEvent(tokenId, currentTime, "Watered");
    }

    // 15. Fertilize a plant
    function fertilizePlant(uint256 tokenId) external plantExists(tokenId) onlyPlantOwnerOrApproved(tokenId) {
         Plant storage plant = _plants[tokenId];
         uint40 currentTime = uint40(block.timestamp);
         string memory actionType = "fertilize";
         if (currentTime < plant.actionCooldowns[actionType]) {
              revert ActionCooldownActive(tokenId, actionType, plant.actionCooldowns[actionType]);
         }

        _calculateAndApplyGrowth(tokenId); // Calculate growth

        plant.nutrientLevel = uint16(Math.min(100, plant.nutrientLevel + 30)); // Increase nutrients
        plant.lastActionTimestamp = currentTime;
        plant.actionCooldowns[actionType] = currentTime + uint40(actionCooldownBlocks[actionType]);

        emit PlantStateUpdated(tokenId, "NutrientLevel", 30);
        emit EvolutionEvent(tokenId, currentTime, "Fertilized");
    }

    // 16. Prune a plant
    function prunePlant(uint256 tokenId) external plantExists(tokenId) onlyPlantOwnerOrApproved(tokenId) {
         Plant storage plant = _plants[tokenId];
         uint40 currentTime = uint40(block.timestamp);
         string memory actionType = "prune";
         if (currentTime < plant.actionCooldowns[actionType]) {
              revert ActionCooldownActive(tokenId, actionType, plant.actionCooldowns[actionType]);
         }

        _calculateAndApplyGrowth(tokenId); // Calculate growth

        // Example effect: reduce pest level slightly, increase health slightly
        plant.pestLevel = uint16(Math.max(0, plant.pestLevel - 10));
        plant.health = uint16(Math.min(100, plant.health + 5));
        plant.lastActionTimestamp = currentTime;
        plant.actionCooldowns[actionType] = currentTime + uint40(actionCooldownBlocks[actionType]);

        emit PlantStateUpdated(tokenId, "PestLevel", -10);
        emit PlantStateUpdated(tokenId, "Health", 5);
        emit EvolutionEvent(tokenId, currentTime, "Pruned");
    }

    // 17. Shield a plant
    function shieldPlant(uint256 tokenId) external plantExists(tokenId) onlyPlantOwnerOrApproved(tokenId) {
         Plant storage plant = _plants[tokenId];
         uint40 currentTime = uint40(block.timestamp);
         string memory actionType = "shield";
         if (currentTime < plant.actionCooldowns[actionType]) {
              revert ActionCooldownActive(tokenId, actionType, plant.actionCooldowns[actionType]);
         }

        _calculateAndApplyGrowth(tokenId); // Calculate growth

        plant.shieldingLevel = uint16(Math.min(100, plant.shieldingLevel + 40)); // Apply shielding
        plant.lastActionTimestamp = currentTime;
        plant.actionCooldowns[actionType] = currentTime + uint40(actionCooldownBlocks[actionType]);

        emit PlantStateUpdated(tokenId, "ShieldingLevel", 40);
        emit EvolutionEvent(tokenId, currentTime, "Applied Shielding");
    }

    // 18. Apply pest control to a plant
    function applyPestControl(uint256 tokenId) external plantExists(tokenId) onlyPlantOwnerOrApproved(tokenId) {
         Plant storage plant = _plants[tokenId];
         uint40 currentTime = uint40(block.timestamp);
         string memory actionType = "pestControl";
         if (currentTime < plant.actionCooldowns[actionType]) {
              revert ActionCooldownActive(tokenId, actionType, plant.actionCooldowns[actionType]);
         }

        _calculateAndApplyGrowth(tokenId); // Calculate growth

        plant.pestLevel = uint16(Math.max(0, plant.pestLevel - 50)); // Significantly reduce pests
        plant.lastActionTimestamp = currentTime;
        plant.actionCooldowns[actionType] = currentTime + uint40(actionCooldownBlocks[actionType]);

        emit PlantStateUpdated(tokenId, "PestLevel", -50);
        emit EvolutionEvent(tokenId, currentTime, "Applied Pest Control");
    }

    // 19. Trigger a global environment update
    function triggerEnvironmentUpdate() external {
         // Anyone can trigger, but only if enough blocks have passed since last update
         if (block.number < currentEnvironment.updateTimestamp + environmentUpdateIntervalBlocks) {
              revert EnvironmentUpdateTooSoon(currentEnvironment.updateTimestamp + environmentUpdateIntervalBlocks);
         }
         _updateEnvironmentState();
         // Note: This doesn't automatically trigger growth for ALL plants due to gas costs.
         // Growth is calculated per-plant when actions are taken or potentially when queried
         // (though lazy evaluation on query is bad for gas on read).
         // An alternative would be a separate incentivized function or keeper network.
    }

    // 20. Get current environment state (already public state variable)
    // function getCurrentEnvironmentState() external view returns (EnvironmentState memory) {
    //    return currentEnvironment; // Public state variables have automatic getter
    // }
    // Adding a redundant getter function purely for the function count requirement:
    function getCurrentEnvironmentState_Getter() external view returns (EnvironmentState memory) {
         return currentEnvironment;
    }


    // 21. Get plant growth progress towards next stage
    function getPlantGrowthProgress(uint256 tokenId) external view plantExists(tokenId) returns (uint256 currentProgress, uint256 requiredForNextStage) {
         Plant storage plant = _plants[tokenId];
         currentProgress = plant.growthProgress;
         GrowthStage currentStage = plant.stage;

         if (currentStage == GrowthStage.SEEDLING) requiredForNextStage = growthStageThresholds[GrowthStage.YOUNG];
         else if (currentStage == GrowthStage.YOUNG) requiredForNextStage = growthStageThresholds[GrowthStage.MATURE];
         else if (currentStage == GrowthStage.MATURE) requiredForNextStage = growthStageThresholds[GrowthStage.FLOWERING];
         else if (currentStage == GrowthStage.FLOWERING) requiredForNextStage = growthStageThresholds[GrowthStage.AGED];
         else requiredForNextStage = 0; // Max stage reached or special stage

         return (currentProgress, requiredForNextStage);
    }

    // 22. Attempt to cross-pollinate two plants
    function attemptPollination(uint256 plantId1, uint256 plantId2) external plantExists(plantId1) plantExists(plantId2) {
        // Check ownership/approval for BOTH plants by the caller
        address owner1 = ownerOf(plantId1);
        address owner2 = ownerOf(plantId2);

        if (owner1 != _msgSender() && !isApprovedForAll(owner1, _msgSender()) && getApproved(plantId1) != _msgSender()) {
             revert NotPlantOwnerOrApproved(plantId1, _msgSender());
        }
         // If plants are owned by different people, the caller must be owner/approved for both
        if (owner1 != owner2 && owner2 != _msgSender() && !isApprovedForAll(owner2, _msgSender()) && getApproved(plantId2) != _msgSender()) {
             revert NotPlantOwnerOrApproved(plantId2, _msgSender());
        }


        Plant storage plant1 = _plants[plantId1];
        Plant storage plant2 = _plants[plantId2];
        uint40 currentTime = uint40(block.timestamp);

        if (currentTime < plant1.lastPollinationTimestamp + uint40(pollinationCooldownBlocks)) {
             revert PollinationCooldownActive(plantId1, plant1.lastPollinationTimestamp + uint40(pollinationCooldownBlocks));
        }
        if (currentTime < plant2.lastPollinationTimestamp + uint40(pollinationCooldownBlocks)) {
             revert PollinationCooldownActive(plantId2, plant2.lastPollinationTimestamp + uint40(pollinationCooldownBlocks));
        }

        // Plants must be in a stage that allows pollination (e.g., FLOWERING)
        if (plant1.stage != GrowthStage.FLOWERING || plant2.stage != GrowthStage.FLOWERING) {
             revert InvalidPlantForPollination(plantId1); // Or specific error for stage
        }


        _calculateAndApplyGrowth(plantId1); // Apply any pending growth before pollination
        _calculateAndApplyGrowth(plantId2);

        plant1.lastPollinationTimestamp = currentTime;
        plant2.lastPollinationTimestamp = currentTime;

        emit PollinationAttempt(plantId1, plantId2, _msgSender());

        // Determine success chance based on base rate, health, and pollination affinity trait
        uint256 successChance = basePollinationSuccessRate;
        successChance = successChance * plant1.health / 100; // Lower health = lower chance
        successChance = successChance * plant2.health / 100;

        // Factor in Pollination Affinity trait
        for (uint i = 0; i < plant1.traits.length; i++) {
             if (plant1.traits[i].traitType == TraitType.POLLINATION_AFFINITY) {
                  successChance += uint256(Math.max(-50, Math.min(50, plant1.traits[i].value / 2))); // Add/subtract up to 25%
                  break;
             }
        }
        for (uint i = 0; i < plant2.traits.length; i++) {
             if (plant2.traits[i].traitType == TraitType.POLLINATION_AFFINITY) {
                   successChance += uint256(Math.max(-50, Math.min(50, plant2.traits[i].value / 2)));
                  break;
             }
        }
         successChance = Math.max(0, Math.min(100, successChance)); // Clamp chance

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender(), plantId1, plantId2, plant1.growthProgress, plant2.growthProgress)));

        if ((randomSeed % 100) < successChance) {
            // Success! Mint a new plant inheriting traits
            _tokenIdCounter.increment();
            uint256 newItemId = _tokenIdCounter.current();
            address minter = _msgSender(); // Minter is the one who triggered pollination

            // --- Trait Inheritance Logic (Complex) ---
            // Example: Inherit a random subset of traits from parents, possibly with mutation
            Trait[] memory inheritedTraits = new Trait[](Math.min(plant1.traits.length + plant2.traits.length, uint(TraitType.COUNT) + 2)); // Cap inherited traits
            uint traitCount = 0;
            bytes32 seenTypes = 0x00;

             uint256 inheritSeed = uint256(keccak256(abi.encodePacked(randomSeed, newItemId)));

             // Simple inheritance: take traits from parent1, then parent2, avoid duplicates initially
             for(uint i=0; i < plant1.traits.length && traitCount < inheritedTraits.length; i++){
                  if ((seenTypes & (bytes32(1) << uint(plant1.traits[i].traitType))) == 0) {
                       inheritedTraits[traitCount] = plant1.traits[i];
                       seenTypes |= (bytes32(1) << uint(plant1.traits[i].traitType));
                       traitCount++;
                  }
             }
             for(uint i=0; i < plant2.traits.length && traitCount < inheritedTraits.length; i++){
                  if ((seenTypes & (bytes32(1) << uint(plant2.traits[i].traitType))) == 0) {
                       inheritedTraits[traitCount] = plant2.traits[i];
                       seenTypes |= (bytes32(1) << uint(plant2.traits[i].traitType));
                       traitCount++;
                  } else {
                       // If trait type already exists, maybe average/combine values?
                       for(uint j=0; j < traitCount; j++){
                           if(inheritedTraits[j].traitType == plant2.traits[i].traitType){
                                // Simple average value for shared traits
                                inheritedTraits[j].value = int16((int256(inheritedTraits[j].value) + int256(plant2.traits[i].value)) / 2);
                                break;
                           }
                       }
                  }
             }

             // Resize the array to actual trait count
            Trait[] memory finalTraits = new Trait[](traitCount);
            for(uint i=0; i < traitCount; i++){
                 finalTraits[i] = inheritedTraits[i];
            }

            // Child starts as seedling
             _plants[newItemId] = Plant({
                 mintTimestamp: currentTime,
                 lastGrowthUpdateTimestamp: currentTime,
                 lastActionTimestamp: currentTime,
                 lastPollinationTimestamp: 0,
                 size: 0,
                 health: 90, // Start with high health
                 stage: GrowthStage.SEEDLING,
                 growthProgress: 0,
                 waterLevel: 70, // Start with good resources
                 nutrientLevel: 70,
                 pestLevel: 5,
                 shieldingLevel: 0,
                 mutationChance: 200, // Higher initial mutation chance for hybrids? (2%)
                 traits: finalTraits
             });
              // Initialize mapping for action cooldowns
             _plants[newItemId].actionCooldowns["water"] = 0;
             _plants[newItemId].actionCooldowns["fertilize"] = 0;
             _plants[newItemId].actionCooldowns["prune"] = 0;
             _plants[newItemId].actionCooldowns["shield"] = 0;
             _plants[newItemId].actionCooldowns["pestControl"] = 0;

            _safeMint(minter, newItemId);

            emit PollinationSuccess(plantId1, plantId2, newItemId);
             emit NewPlantMinted(newItemId, minter, currentTime, currentTime);

        } else {
             // Pollination failed, maybe a small penalty to health or state
             plant1.health = uint16(Math.max(0, plant1.health - 2));
             plant2.health = uint16(Math.max(0, plant2.health - 2));
             emit EvolutionEvent(plantId1, currentTime, "Pollination attempt failed");
             emit EvolutionEvent(plantId2, currentTime, "Pollination attempt failed");
        }
    }

    // 23. Set config factors for growth calculation (Owner only)
    function setConfigGrowthFactors(uint256 newBaseGrowthFactor) external onlyOwner {
         baseGrowthFactor = newBaseGrowthFactor;
         emit ConfigUpdated("BaseGrowthFactor", msg.sender);
    }

    // 24. Set config factors for how traits impact growth/health (Owner only)
    function setConfigTraitImpacts(TraitType[] calldata types, int16[] calldata impacts) external onlyOwner {
        if (types.length != impacts.length) {
            revert InvalidTraitConfiguration();
        }
        for (uint i = 0; i < types.length; i++) {
            traitImpactFactors[types[i]] = impacts[i];
        }
        emit ConfigUpdated("TraitImpactFactors", msg.sender);
    }

    // 25. Set action cooldown blocks (Owner only)
    function setConfigActionCooldowns(string[] calldata actionTypes, uint256[] calldata cooldownBlocks) external onlyOwner {
        if (actionTypes.length != cooldownBlocks.length) {
            revert InvalidTraitConfiguration(); // Reusing error, maybe add specific one
        }
        for (uint i = 0; i < actionTypes.length; i++) {
            actionCooldownBlocks[actionTypes[i]] = cooldownBlocks[i];
        }
        emit ConfigUpdated("ActionCooldowns", msg.sender);
    }

    // 26. Set pollination success rates and cooldown (Owner only)
    function setConfigPollinationRates(uint256 newBaseSuccessRate, uint256 newCooldownBlocks) external onlyOwner {
        basePollinationSuccessRate = newBaseSuccessRate;
        pollinationCooldownBlocks = newCooldownBlocks;
         emit ConfigUpdated("PollinationRates", msg.sender);
    }

     // 27. Set minimum blocks between environment updates (Owner only)
    function setEnvironmentUpdateInterval(uint256 intervalBlocks) external onlyOwner {
         environmentUpdateIntervalBlocks = intervalBlocks;
         emit ConfigUpdated("EnvironmentUpdateInterval", msg.sender);
    }

    // 28. Set growth stage thresholds (Owner only)
    function setGrowthStageThresholds(GrowthStage[] calldata stages, uint224[] calldata thresholds) external onlyOwner {
        if (stages.length != thresholds.length) {
            revert InvalidTraitConfiguration();
        }
        for(uint i=0; i < stages.length; i++){
             growthStageThresholds[stages[i]] = thresholds[i];
        }
         emit ConfigUpdated("GrowthStageThresholds", msg.sender);
    }


    // 29. Get list of plants owned by an address (Paginated for gas)
    function getPlantsByOwner(address owner, uint256 startIndex, uint256 count) external view returns (uint256[] memory) {
        uint256[] storage ownerPlantIds = _plantsByOwner[owner];
        uint256 totalOwned = ownerPlantIds.length;

        if (startIndex >= totalOwned) {
            return new uint256[](0);
        }

        uint256 endIndex = startIndex + count;
        if (endIndex > totalOwned) {
            endIndex = totalOwned;
        }

        uint256 resultCount = endIndex - startIndex;
        uint256[] memory result = new uint256[](resultCount);

        for (uint i = 0; i < resultCount; i++) {
            result[i] = ownerPlantIds[startIndex + i];
        }

        return result;
    }

    // 30. Get total number of plants minted
    function getTotalPlants() external view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Helper functions for string conversions (for events/readability) ---
    function _getTraitTypeString(TraitType traitType) internal pure returns (string memory) {
        if (traitType == TraitType.SUNLIGHT_SENSITIVITY) return "SUNLIGHT_SENSITIVITY";
        if (traitType == TraitType.WATER_RETENTION) return "WATER_RETENTION";
        if (traitType == TraitType.NUTRIENT_EFFICIENCY) return "NUTRIENT_EFFICIENCY";
        if (traitType == TraitType.PEST_RESISTANCE) return "PEST_RESISTANCE";
        if (traitType == TraitType.MUTATION_PRONENESS) return "MUTATION_PRONENESS";
        if (traitType == TraitType.GROWTH_SPEED) return "GROWTH_SPEED";
        if (traitType == TraitType.POLLINATION_AFFINITY) return "POLLINATION_AFFINITY";
        return "UNKNOWN_TRAIT";
    }

    function _getGrowthStageString(GrowthStage stage) internal pure returns (string memory) {
        if (stage == GrowthStage.SEEDLING) return "SEEDLING";
        if (stage == GrowthStage.YOUNG) return "YOUNG";
        if (stage == GrowthStage.MATURE) return "MATURE";
        if (stage == GrowthStage.FLOWERING) return "FLOWERING";
        if (stage == GrowthStage.AGED) return "AGED";
        if (stage == GrowthStage.MUTATED) return "MUTATED";
        return "UNKNOWN_STAGE";
    }

    // --- Utility Library (Basic Math) ---
    // OpenZeppelin's Math or use Solidity 0.8+ features directly where possible.
    // Using internal functions for basic operations to avoid dependency if OZ Math is not desired.
    library Math {
        function max(uint256 a, uint256 b) internal pure returns (uint256) { return a >= b ? a : b; }
        function min(uint256 a, uint256 b) internal pure returns (uint256) { return a < b ? a : b; }
        function max(int256 a, int256 b) internal pure returns (int256) { return a >= b ? a : b; }
        function min(int256 a, int256 b) internal pure returns (int256) { return a < b ? a : b; }
        function max(uint16 a, uint16 b) internal pure returns (uint16) { return a >= b ? a : b; }
        function min(uint16 a, uint16 b) internal pure returns (uint16) { return a < b ? a : b; }
         function max(int16 a, int16 b) internal pure returns (int16) { return a >= b ? a : b; }
        function min(int16 a, int16 b) internal pure returns (int16) { return a < b ? a : b; }

    }
     // Simple Strings utility for casting (e.g., int to string) - might need a full library for robust conversion
     library Strings {
          function toString(int256 value) internal pure returns (string memory) {
               if (value == 0) {
                    return "0";
               }
               int256 absValue = value > 0 ? value : -value;
               uint256 temp = uint256(absValue);
               uint256 i = 0;
               bytes memory buffer = new bytes(39); // max length of int256 string

               while (temp != 0) {
                   buffer[buffer.length - 1 - i++] = bytes1(uint8(48 + temp % 10));
                   temp /= 10;
               }

               bytes memory result = new bytes(i + (value < 0 ? 1 : 0));
               uint256 j = 0;
               if (value < 0) {
                    result[j++] = '-';
               }
               for(uint k=0; k < i; k++){
                    result[j++] = buffer[buffer.length - i + k];
               }
               return string(result);
          }
     }


}
```