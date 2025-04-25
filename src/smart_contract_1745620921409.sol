Okay, here is a Solidity smart contract implementing a dynamic, state-changing "Genesis Seed" ecosystem concept. It incorporates ideas around lifecycle, resource management, mutation, and user interaction, aiming for complexity beyond standard tokens or simple vaults, while avoiding direct duplication of common patterns like ERC-20 or ERC-721 (though it borrows *some* concepts like ownership and transfer, implemented customly).

It features a system where users plant digital "Seeds" by sending Ether. These Seeds have properties like Vitality and Complexity that evolve over time and with user interaction (nourishing). Seeds can reach different evolution stages, mutate to gain unique traits, and potentially "spawn" symbolic spores. The contract owner manages parameters and global traits.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SolidityGenesis - The Primordial Seed
 * @author [Your Name or Pseudonym]
 * @dev A smart contract simulating a decentralized ecosystem where users cultivate unique digital entities called "Seeds".
 * Seeds evolve through stages, mutate to gain traits, and require nourishment to thrive.
 * The contract manages the lifecycle and properties of these dynamic entities on-chain.
 */

// Outline:
// 1. Data Structures: Structs for Seed and Trait, Enum for EvolutionStage.
// 2. State Variables: Mappings for seeds, traits, user seeds; counters; configuration parameters.
// 3. Events: Signalling key lifecycle and state changes.
// 4. Modifiers: onlyOwner for administrative functions.
// 5. Constructor: Initializes owner and basic parameters.
// 6. Owner Functions: Configuration and withdrawal of funds.
// 7. User Interaction Functions: Planting, nourishing, transferring, burning seeds.
// 8. Lifecycle & Simulation Functions: Triggering evolution, applying environmental decay, mutation, spawning.
// 9. Query Functions: Retrieving contract state and seed information.
// 10. Utility Functions: Pure/view helpers for calculations.

// Function Summary:
// --- Owner Functions ---
// 1. constructor() - Initializes the contract with the owner.
// 2. addTrait(string calldata _name, uint256 _rarityFactor, uint256 _influenceMultiplier) - Adds a new global trait definition.
// 3. setEvolutionStageThresholds(uint256[] calldata _thresholds) - Sets complexity thresholds for each evolution stage.
// 4. setGrowthParameters(uint256 _vitalityDecayRatePerBlock, uint256 _complexityGrowthFactor) - Sets parameters for vitality decay and complexity gain.
// 5. setMutationParameters(uint256 _mutationChanceBasis, uint256 _maxTraitsPerSeed) - Sets parameters for mutation chance and trait limits.
// 6. setSporesParameters(uint8 _sporeSpawnStage, uint256 _sporeCountPerSpawn, uint256 _sporeSpawnCooldownBlocks) - Sets parameters for spore spawning.
// 7. setDormancyParameters(uint256 _vitalityDormantThreshold, uint256 _dormancyCheckInterval) - Sets parameters for seed dormancy.
// 8. withdrawBalance() - Allows the owner to withdraw the contract's Ether balance.
// 9. removeTrait(uint256 _traitId) - (Optional, advanced): Removes a trait definition (careful with existing seeds). Decided to omit for complexity, but added as a thought. Let's add an `updateTrait` instead.
// 9. updateTrait(uint256 _traitId, string calldata _name, uint256 _rarityFactor, uint256 _influenceMultiplier) - Updates an existing trait definition.
// --- User Interaction Functions ---
// 10. plantSeed() - Creates a new seed for the caller, costs Ether.
// 11. nourishSeed(uint256 _seedId) - Increases a seed's vitality and complexity, costs Ether.
// 12. transferSeed(address _to, uint256 _seedId) - Transfers ownership of a seed.
// 13. burnDormantSeed(uint256 _seedId) - Burns a dormant seed.
// --- Lifecycle & Simulation Functions (Publicly Triggerable) ---
// 14. evolveSeed(uint256 _seedId) - Checks and performs evolution if seed meets criteria.
// 15. applyEnvironmentalFactors(uint256 _seedId) - Applies vitality decay based on time since last update.
// 16. checkForMutation(uint256 _seedId) - Checks and applies mutation if criteria met.
// 17. spawnSpores(uint256 _seedId) - Checks and triggers spore spawning if seed meets criteria.
// 18. deactivateDormantSeeds(uint256 _seedId) - Checks and marks a seed as dormant if criteria met.
// --- Query Functions ---
// 19. getSeedInfo(uint256 _seedId) view - Retrieves detailed information about a seed.
// 20. getUserSeeds(address _user) view - Retrieves the list of seed IDs owned by a user. (Note: Can be gas-intensive for users with many seeds).
// 21. getTotalSeeds() view - Gets the total number of seeds ever planted.
// 22. getEvolutionStageThresholds() view - Gets the current complexity thresholds for stages.
// 23. getTraitCount() view - Gets the total number of defined traits.
// 24. getTraitInfo(uint256 _traitId) view - Gets information about a specific trait.
// 25. getSeedTraits(uint256 _seedId) view - Gets the list of trait IDs applied to a seed.
// 26. isSeedDormant(uint256 _seedId) view - Checks if a seed is currently dormant.
// 27. getSeedOwner(uint256 _seedId) view - Gets the owner of a specific seed.
// --- Utility Functions (Pure/View) ---
// 28. calculateSeedVitality(uint256 _seedId) view - Calculates effective vitality considering decay since last update.
// 29. calculateSeedComplexity(uint256 _seedId) view - Calculates effective complexity considering current state and traits. (Placeholder for more complex logic).

enum EvolutionStage { Seedling, Juvenile, Mature, Ethereal, Ascended }

struct Seed {
    address owner;
    uint256 plantedBlock;
    uint256 vitality; // Health/Energy - decays over time, increases with nourishment
    uint256 complexity; // Represents growth/development - increases with vitality/nourishment
    EvolutionStage stage;
    uint256 lastUpdateBlock; // Last block vitality/complexity was explicitly updated or environmental factors applied
    uint256 lastNourishBlock;
    uint256 lastSporeSpawnBlock;
    uint256 sporesSpawnedCount;
    uint256[] traitIds; // List of trait IDs applied to this seed
    bool dormant; // If vitality drops too low for too long
}

struct Trait {
    string name;
    uint256 rarityFactor; // e.g., 1000 for common, 10 for rare - lower is rarer
    uint256 influenceMultiplier; // How this trait affects vitality/complexity gain (e.g., 1000 for 1x, 1100 for 1.1x)
}

address public owner;
uint256 private nextSeedId;
uint256 private nextTraitId;

mapping(uint256 => Seed) private seeds;
mapping(uint256 => Trait) private traits;
mapping(address => uint256[]) private userSeeds; // Tracks seed IDs per user

// Configuration Parameters (set by owner)
uint256 public plantCost = 0.01 ether;
uint256 public nourishCost = 0.005 ether;
uint256 public vitalityDecayRatePerBlock = 1; // Vitality lost per block since last update
uint256 public complexityGrowthFactor = 10; // Complexity gained per unit of vitality gained from nourishment
uint256[] public evolutionStageThresholds = [100, 500, 2000, 5000]; // Complexity needed for Seedling -> Juvenile, Juvenile -> Mature, etc. Must be N-1 values for N stages.
uint256 public mutationChanceBasis = 1000; // Chance of mutation is 1 / mutationChanceBasis (e.g., 1/1000 = 0.1%)
uint256 public maxTraitsPerSeed = 3; // Max number of traits a seed can have
uint8 public sporeSpawnStage = uint8(EvolutionStage.Mature); // Stage required to spawn spores
uint256 public sporeCountPerSpawn = 1; // Number of spores spawned at once
uint256 public sporeSpawnCooldownBlocks = 100; // Blocks between spore spawns for a single seed
uint256 public vitalityDormantThreshold = 10; // Vitality below which seed becomes susceptible to dormancy
uint256 public dormancyCheckInterval = 50; // Blocks since last update to check for dormancy

event SeedPlanted(uint256 indexed seedId, address indexed owner, uint256 plantedBlock);
event SeedNourished(uint256 indexed seedId, uint256 vitalityAdded, uint256 complexityAdded, uint256 newVitality, uint256 newComplexity);
event SeedEvolved(uint256 indexed seedId, EvolutionStage oldStage, EvolutionStage newStage);
event SeedMutated(uint256 indexed seedId, uint256[] newTraitIds);
event SporesSpawned(uint256 indexed parentSeedId, uint256 count);
event SeedDormant(uint256 indexed seedId);
event SeedTransferred(uint256 indexed seedId, address indexed from, address indexed to);
event SeedBurned(uint256 indexed seedId, address indexed owner);
event TraitAdded(uint256 indexed traitId, string name);
event TraitUpdated(uint256 indexed traitId, string name, uint256 rarityFactor, uint256 influenceMultiplier);

modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
}

constructor() {
    owner = msg.sender;
    nextSeedId = 1; // Start seed IDs from 1
    nextTraitId = 1; // Start trait IDs from 1
}

// --- Owner Functions ---

/// @dev Allows the owner to add a new trait definition to the ecosystem.
/// @param _name The name of the trait.
/// @param _rarityFactor A factor influencing how rare the trait is (lower is rarer).
/// @param _influenceMultiplier How the trait affects vitality/complexity growth (1000 = 1x).
function addTrait(string calldata _name, uint256 _rarityFactor, uint256 _influenceMultiplier) external onlyOwner {
    uint256 traitId = nextTraitId++;
    traits[traitId] = Trait(_name, _rarityFactor, _influenceMultiplier);
    emit TraitAdded(traitId, _name);
}

/// @dev Allows the owner to update an existing trait definition.
/// @param _traitId The ID of the trait to update.
/// @param _name The new name of the trait.
/// @param _rarityFactor The new rarity factor.
/// @param _influenceMultiplier The new influence multiplier.
function updateTrait(uint256 _traitId, string calldata _name, uint256 _rarityFactor, uint256 _influenceMultiplier) external onlyOwner {
    require(traits[_traitId].rarityFactor > 0, "Trait does not exist"); // Check if trait exists by checking a non-zero default value
    traits[_traitId].name = _name;
    traits[_traitId].rarityFactor = _rarityFactor;
    traits[_traitId].influenceMultiplier = _influenceMultiplier;
    emit TraitUpdated(_traitId, _name, _rarityFactor, _influenceMultiplier);
}


/// @dev Allows the owner to set the complexity thresholds required for each evolution stage.
/// @param _thresholds An array of complexity values. Array length must be 1 less than the number of evolution stages.
function setEvolutionStageThresholds(uint256[] calldata _thresholds) external onlyOwner {
    require(_thresholds.length == uint8(EvolutionStage.Ascended), "Incorrect number of thresholds");
    evolutionStageThresholds = _thresholds;
}

/// @dev Allows the owner to set global parameters for seed vitality decay and complexity growth.
/// @param _vitalityDecayRatePerBlock How much vitality a seed loses per block since last update.
/// @param _complexityGrowthFactor Multiplier for complexity gained from nourishment vitality.
function setGrowthParameters(uint256 _vitalityDecayRatePerBlock, uint256 _complexityGrowthFactor) external onlyOwner {
    vitalityDecayRatePerBlock = _vitalityDecayRatePerBlock;
    complexityGrowthFactor = _complexityGrowthFactor;
}

/// @dev Allows the owner to set parameters for seed mutation.
/// @param _mutationChanceBasis The denominator for mutation chance (1 / basis). Lower is higher chance.
/// @param _maxTraitsPerSeed The maximum number of traits a single seed can acquire.
function setMutationParameters(uint256 _mutationChanceBasis, uint256 _maxTraitsPerSeed) external onlyOwner {
     require(_mutationChanceBasis > 0, "Chance basis must be positive");
    mutationChanceBasis = _mutationChanceBasis;
    maxTraitsPerSeed = _maxTraitsPerSeed;
}

/// @dev Allows the owner to set parameters for seed spore spawning.
/// @param _sporeSpawnStage The minimum evolution stage required to spawn spores.
/// @param _sporeCountPerSpawn The number of spores spawned in one event.
/// @param _sporeSpawnCooldownBlocks The minimum blocks between spawning events for a seed.
function setSporesParameters(uint8 _sporeSpawnStage, uint256 _sporeCountPerSpawn, uint256 _sporeSpawnCooldownBlocks) external onlyOwner {
    require(_sporeSpawnStage < uint8(EvolutionStage.Ascended), "Invalid spawn stage");
    sporeSpawnStage = _sporeSpawnStage;
    sporeCountPerSpawn = _sporeCountPerSpawn;
    sporeSpawnCooldownBlocks = _sporeSpawnCooldownBlocks;
}

/// @dev Allows the owner to set parameters for seed dormancy.
/// @param _vitalityDormantThreshold Seeds with vitality below this threshold may become dormant.
/// @param _dormancyCheckInterval Blocks since last update to check for dormancy.
function setDormancyParameters(uint256 _vitalityDormantThreshold, uint256 _dormancyCheckInterval) external onlyOwner {
    vitalityDormantThreshold = _vitalityDormantThreshold;
    dormancyCheckInterval = _dormancyCheckInterval;
}

/// @dev Allows the owner to withdraw the contract's Ether balance.
function withdrawBalance() external onlyOwner {
    (bool success, ) = owner.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
}

// --- User Interaction Functions ---

/// @dev Allows a user to plant a new seed by sending the required Ether.
function plantSeed() external payable {
    require(msg.value >= plantCost, "Insufficient Ether to plant seed");

    uint256 seedId = nextSeedId++;
    uint256 currentBlock = block.number;

    seeds[seedId] = Seed({
        owner: msg.sender,
        plantedBlock: currentBlock,
        vitality: 100, // Initial vitality
        complexity: 0,   // Starts at 0
        stage: EvolutionStage.Seedling,
        lastUpdateBlock: currentBlock,
        lastNourishBlock: currentBlock,
        lastSporeSpawnBlock: 0, // Never spawned yet
        sporesSpawnedCount: 0,
        traitIds: new uint256[](0), // Starts with no traits
        dormant: false
    });

    userSeeds[msg.sender].push(seedId);

    emit SeedPlanted(seedId, msg.sender, currentBlock);

    // Refund excess ether if any
    if (msg.value > plantCost) {
        (bool success, ) = msg.sender.call{value: msg.value - plantCost}("");
        require(success, "Ether refund failed");
    }
}

/// @dev Allows a seed owner to nourish their seed by sending the required Ether.
/// Increases vitality and complexity. Applies environmental factors first.
/// @param _seedId The ID of the seed to nourish.
function nourishSeed(uint256 _seedId) external payable {
    require(msg.value >= nourishCost, "Insufficient Ether to nourish seed");
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist"); // Check if seed exists
    require(seed.owner == msg.sender, "Not seed owner");
    require(!seed.dormant, "Seed is dormant");

    // Apply environmental factors before nourishing
    applyEnvironmentalFactors(_seedId);

    uint252 vitalityAdded = uint252(msg.value / (nourishCost / 100)); // Simple calculation, e.g. 0.005 eth adds 100 vitality (if nourishCost=0.005)
    uint256 complexityAdded = uint256(vitalityAdded) * complexityGrowthFactor / 1000; // Apply growth factor, base 1000

    // Apply trait influence to complexity gain
    for (uint i = 0; i < seed.traitIds.length; i++) {
        uint256 traitId = seed.traitIds[i];
        if (traits[traitId].rarityFactor > 0) { // Check if trait exists
           complexityAdded = complexityAdded * traits[traitId].influenceMultiplier / 1000;
        }
    }

    uint256 oldVitality = seed.vitality;
    uint256 oldComplexity = seed.complexity;

    seed.vitality = seed.vitality + uint256(vitalityAdded);
    seed.complexity = seed.complexity + complexityAdded;
    seed.lastNourishBlock = block.number;
    seed.lastUpdateBlock = block.number; // Update last update block too

    emit SeedNourished(_seedId, uint256(vitalityAdded), complexityAdded, seed.vitality, seed.complexity);

    // Automatically try to evolve after nourishment
    evolveSeed(_seedId);

    // Refund excess ether if any
    if (msg.value > nourishCost) {
        (bool success, ) = msg.sender.call{value: msg.value - nourishCost}("");
        require(success, "Ether refund failed");
    }
}

/// @dev Allows a seed owner to transfer their seed to another address.
/// @param _to The recipient address.
/// @param _seedId The ID of the seed to transfer.
function transferSeed(address _to, uint256 _seedId) external {
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    require(seed.owner == msg.sender, "Not seed owner");
    require(_to != address(0), "Cannot transfer to zero address");

    // Remove seed from old owner's list (gas intensive for large lists)
    uint256[] storage senderSeeds = userSeeds[msg.sender];
    bool found = false;
    for (uint i = 0; i < senderSeeds.length; i++) {
        if (senderSeeds[i] == _seedId) {
            // Replace with last element and pop
            senderSeeds[i] = senderSeeds[senderSeeds.length - 1];
            senderSeeds.pop();
            found = true;
            break;
        }
    }
    // This should always be found if the seed exists and belongs to the sender,
    // but adding a check here is safer if logic errors occur.
    require(found, "Internal error: Seed not found in owner's list");


    seed.owner = _to;
    userSeeds[_to].push(_seedId);

    emit SeedTransferred(_seedId, msg.sender, _to);
}

/// @dev Allows the owner of a dormant seed (or potentially contract owner) to burn it.
/// @param _seedId The ID of the seed to burn.
function burnDormantSeed(uint256 _seedId) external {
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    require(seed.owner == msg.sender || owner == msg.sender, "Not seed owner or contract owner");
    require(seed.dormant, "Seed is not dormant");

     // Remove seed from owner's list (gas intensive for large lists)
    uint256[] storage seedOwnerSeeds = userSeeds[seed.owner];
    bool found = false;
    for (uint i = 0; i < seedOwnerSeeds.length; i++) {
        if (seedOwnerSeeds[i] == _seedId) {
            // Replace with last element and pop
            seedOwnerSeeds[i] = seedOwnerSeeds[seedOwnerSeeds.length - 1];
            seedOwnerSeeds.pop();
            found = true;
            break;
        }
    }
    require(found, "Internal error: Seed not found in owner's list");

    // Mark seed as burned (or delete if preferred, but tracking total seeds better this way)
    // Setting owner to zero address signals it's burned/non-existent from a user perspective
    address burnedOwner = seed.owner;
    delete seeds[_seedId]; // Deleting frees up storage gas

    emit SeedBurned(_seedId, burnedOwner);
}


// --- Lifecycle & Simulation Functions (Publicly Triggerable) ---
// These functions can often be called by anyone, providing a way for users
// to 'poke' the state of seeds and trigger potential changes, distributing gas costs.
// It's important that calling them costs minimal gas if no action is taken.

/// @dev Checks if a seed is ready to evolve to the next stage and performs the evolution.
/// Can be called by anyone to trigger evolution for a seed.
/// @param _seedId The ID of the seed to check/evolve.
function evolveSeed(uint256 _seedId) public { // Made public so anyone can trigger
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    require(!seed.dormant, "Seed is dormant");

    uint8 currentStageIndex = uint8(seed.stage);

    // Only evolve if not already at the final stage
    if (currentStageIndex < uint8(EvolutionStage.Ascended)) {
         // Apply environmental factors before checking complexity
        applyEnvironmentalFactors(_seedId); // Ensure complexity is up-to-date

        uint256 requiredComplexity = evolutionStageThresholds[currentStageIndex];

        if (seed.complexity >= requiredComplexity) {
            seed.stage = EvolutionStage(currentStageIndex + 1);
            emit SeedEvolved(_seedId, EvolutionStage(currentStageIndex), seed.stage);

            // Try to mutate after evolution
            checkForMutation(_seedId);
        }
    }
}

/// @dev Applies vitality decay to a seed based on the number of blocks since its last update.
/// Can be called by anyone.
/// @param _seedId The ID of the seed to update.
function applyEnvironmentalFactors(uint256 _seedId) public { // Made public
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    // Don't apply factors to dormant seeds, their state is static until burned
    require(!seed.dormant, "Seed is dormant");

    uint256 currentBlock = block.number;
    uint256 blocksSinceLastUpdate = currentBlock - seed.lastUpdateBlock;

    if (blocksSinceLastUpdate > 0) {
        uint256 decayAmount = blocksSinceLastUpdate * vitalityDecayRatePerBlock;

        if (seed.vitality <= decayAmount) {
            seed.vitality = 0;
        } else {
            seed.vitality -= decayAmount;
        }

        seed.lastUpdateBlock = currentBlock;

        // Check if seed becomes dormant after decay
        if (seed.vitality < vitalityDormantThreshold && blocksSinceLastUpdate >= dormancyCheckInterval) {
             deactivateDormantSeeds(_seedId); // Trigger dormancy check
        }
         // Note: Complexity doesn't decay naturally in this model, only Vitality.
    }
}


/// @dev Checks if a seed mutates based on chance and applies a random trait if it does.
/// Can be called by anyone. Requires traits to be added by the owner.
/// @param _seedId The ID of the seed to check.
function checkForMutation(uint256 _seedId) public { // Made public
     Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    require(!seed.dormant, "Seed is dormant");
    require(seed.traitIds.length < maxTraitsPerSeed, "Seed already has max traits");
    require(nextTraitId > 1, "No traits defined to mutate"); // nextTraitId starts at 1, so traits exist if > 1

    // Simple pseudo-randomness using blockhash (limited and predictable)
    // A more robust solution would use Chainlink VRF or similar oracles.
    uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, seed.plantedBlock, seed.complexity, seed.vitality, _seedId)));
    // Use block.difficulty or block.coinbase depending on chain/fork consideration for better entropy, but block.timestamp+number is simplest for example.
    // BE AWARE: This is NOT secure or truly random. Miners can influence blockhash.

    // Check for mutation chance
    if (mutationChanceBasis > 0 && (randomValue % mutationChanceBasis == 0)) {
        // Mutation triggered! Select a random trait that the seed doesn't already have

        uint256 traitIndex = (randomValue / mutationChanceBasis) % (nextTraitId - 1) + 1; // Get random trait ID (1 to nextTraitId-1)
        uint256 traitIdToApply = 0;
        uint256 attempts = 0;
        uint256 maxAttempts = (nextTraitId - 1) * 2; // Prevent infinite loops if seed has all traits

        // Find a valid trait ID that exists and isn't already on the seed
        while(attempts < maxAttempts) {
            uint256 currentTraitId = (traitIndex + attempts) % (nextTraitId - 1) + 1; // Cycle through trait IDs
            if (traits[currentTraitId].rarityFactor > 0) { // Check if trait exists
                bool hasTrait = false;
                for (uint i = 0; i < seed.traitIds.length; i++) {
                    if (seed.traitIds[i] == currentTraitId) {
                        hasTrait = true;
                        break;
                    }
                }
                if (!hasTrait) {
                    traitIdToApply = currentTraitId;
                    break;
                }
            }
            attempts++;
        }


        if (traitIdToApply > 0) {
            seed.traitIds.push(traitIdToApply);
            emit SeedMutated(_seedId, seed.traitIds);
        }
         // If traitIdToApply is still 0 after attempts, it means all available traits are already on the seed or no traits exist.
    }
}

/// @dev Checks if a seed is ready to spawn spores and triggers the event.
/// Can be called by anyone.
/// @param _seedId The ID of the seed to check.
function spawnSpores(uint256 _seedId) public { // Made public
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    require(!seed.dormant, "Seed is dormant");
    require(uint8(seed.stage) >= sporeSpawnStage, "Seed not mature enough to spawn spores");
    require(block.number >= seed.lastSporeSpawnBlock + sporeSpawnCooldownBlocks, "Spore spawn cooldown in effect");

    // Apply environmental factors before checking vitality/complexity
    applyEnvironmentalFactors(_seedId); // Ensure vitality/complexity are up-to-date

    // Require minimum vitality/complexity to spawn (add your own logic here)
    require(seed.vitality > vitalityDormantThreshold, "Vitality too low to spawn spores");
    require(seed.complexity > evolutionStageThresholds[uint8(seed.stage) -1] / 2, "Complexity too low to spawn spores"); // Example: must be at least halfway to next stage

    seed.sporesSpawnedCount += sporeCountPerSpawn;
    seed.lastSporeSpawnBlock = block.number;

    // Spawning spores could potentially cost vitality/complexity
    // Example: seed.vitality = seed.vitality < 10 ? 0 : seed.vitality - 10;

    emit SporesSpawned(_seedId, sporeCountPerSpawn);
}

/// @dev Checks if a seed meets dormancy criteria and marks it as dormant.
/// Can be called by anyone. Dormant seeds stop decaying and cannot be nourished or evolve.
/// @param _seedId The ID of the seed to check.
function deactivateDormantSeeds(uint256 _seedId) public { // Made public
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    require(!seed.dormant, "Seed is already dormant");

    uint256 currentBlock = block.number;
    uint256 blocksSinceLastUpdate = currentBlock - seed.lastUpdateBlock;

    // Apply factors first to get current vitality
    applyEnvironmentalFactors(_seedId);

    if (seed.vitality < vitalityDormantThreshold && blocksSinceLastUpdate >= dormancyCheckInterval) {
        seed.dormant = true;
        // Vitality is fixed at its current (low) value once dormant
        seed.lastUpdateBlock = currentBlock; // Reset update block to stop further decay calculations while dormant
        emit SeedDormant(_seedId);
    }
}


// --- Query Functions ---

/// @dev Retrieves all stored information about a specific seed.
/// @param _seedId The ID of the seed to query.
/// @return A tuple containing all seed properties.
function getSeedInfo(uint256 _seedId) public view returns (
    address owner,
    uint256 plantedBlock,
    uint256 vitality,
    uint256 complexity,
    EvolutionStage stage,
    uint256 lastUpdateBlock,
    uint256 lastNourishBlock,
    uint256 lastSporeSpawnBlock,
    uint256 sporesSpawnedCount,
    uint256[] memory traitIds,
    bool dormant
) {
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist"); // Check if seed exists

    return (
        seed.owner,
        seed.plantedBlock,
        seed.vitality,
        seed.complexity,
        seed.stage,
        seed.lastUpdateBlock,
        seed.lastNourishBlock,
        seed.lastSporeSpawnBlock,
        seed.sporesSpawnedCount,
        seed.traitIds,
        seed.dormant
    );
}

/// @dev Retrieves the list of seed IDs owned by a specific address.
/// @param _user The address to query.
/// @return An array of seed IDs. Note: This function can be gas-intensive for users with many seeds.
function getUserSeeds(address _user) external view returns (uint256[] memory) {
    return userSeeds[_user];
}

/// @dev Gets the total number of seeds ever planted in the ecosystem.
/// @return The total seed count.
function getTotalSeeds() external view returns (uint256) {
    return nextSeedId - 1;
}

/// @dev Gets the current complexity thresholds for each evolution stage.
/// @return An array of thresholds.
function getEvolutionStageThresholds() external view returns (uint256[] memory) {
    return evolutionStageThresholds;
}

/// @dev Gets the total number of trait definitions.
/// @return The total trait count.
function getTraitCount() external view returns (uint256) {
    return nextTraitId - 1;
}

/// @dev Gets information about a specific trait.
/// @param _traitId The ID of the trait to query.
/// @return A tuple containing the trait's name, rarity factor, and influence multiplier.
function getTraitInfo(uint256 _traitId) external view returns (string memory name, uint256 rarityFactor, uint256 influenceMultiplier) {
     require(traits[_traitId].rarityFactor > 0 || _traitId == 0, "Trait does not exist"); // Check if trait exists (or is ID 0, which isn't used)
     Trait storage trait = traits[_traitId];
     return (trait.name, trait.rarityFactor, trait.influenceMultiplier);
}

/// @dev Gets the list of trait IDs currently applied to a seed.
/// @param _seedId The ID of the seed to query.
/// @return An array of trait IDs.
function getSeedTraits(uint256 _seedId) external view returns (uint256[] memory) {
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    return seed.traitIds;
}

/// @dev Checks if a seed is currently marked as dormant.
/// @param _seedId The ID of the seed to check.
/// @return True if the seed is dormant, false otherwise.
function isSeedDormant(uint256 _seedId) external view returns (bool) {
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    return seed.dormant;
}

/// @dev Gets the owner address of a specific seed.
/// @param _seedId The ID of the seed to query.
/// @return The owner's address.
function getSeedOwner(uint256 _seedId) external view returns (address) {
     Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    return seed.owner;
}


// --- Utility Functions (Pure/View) ---
// These calculate values based on current state but don't modify state.

/// @dev Calculates the effective vitality of a seed considering decay since last update.
/// Does not modify seed state.
/// @param _seedId The ID of the seed.
/// @return The calculated current vitality.
function calculateSeedVitality(uint256 _seedId) public view returns (uint256) { // Made public for internal use
    Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");

    if (seed.dormant) {
        return seed.vitality; // Dormant seeds have static vitality
    }

    uint256 currentBlock = block.number;
    uint256 blocksSinceLastUpdate = currentBlock - seed.lastUpdateBlock;
    uint256 decayAmount = blocksSinceLastUpdate * vitalityDecayRatePerBlock;

    if (seed.vitality <= decayAmount) {
        return 0;
    } else {
        return seed.vitality - decayAmount;
    }
}

/// @dev Calculates the effective complexity of a seed, potentially applying trait influences (currently only applied on gain).
/// Note: This function is currently a placeholder and just returns the stored complexity,
/// but could be extended for complex on-the-fly calculations based on traits or global state.
/// @param _seedId The ID of the seed.
/// @return The stored complexity (no dynamic calculation in this version).
function calculateSeedComplexity(uint256 _seedId) public view returns (uint256) { // Made public for internal use
     Seed storage seed = seeds[_seedId];
    require(seed.owner != address(0), "Seed does not exist");
    // In this version, complexity is only updated when nourished.
    // A more complex version could have traits dynamically influence effective complexity here.
    return seed.complexity;
}

// Fallback function to reject direct Ether transfers without calling a function
receive() external payable {
    revert("Direct Ether transfers not allowed, use plantSeed or nourishSeed");
}

fallback() external payable {
    revert("Calls to non-existent functions or direct Ether transfers not allowed");
}

}
```