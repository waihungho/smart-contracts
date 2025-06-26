Okay, here is a Solidity smart contract concept that focuses on creating a dynamic, interactive digital ecosystem. It incorporates ideas around dynamic NFTs, interconnected state, internal resource management, time-based mechanics, pseudo-random randomness for events, and batch operations, aiming to avoid direct duplication of standard library implementations by building custom logic.

It's a simulated "Alchemical Garden" where users cultivate plots, manage resources, and interact with potential creatures, influencing a shared global state.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title The Alchemical Garden Protocol
 * @author [Your Name/Pseudonym]
 * @notice A protocol for cultivating dynamic digital gardens, managing resources, and interacting with generated creatures,
 * influenced by a shared global state and user actions.
 *
 * Outline:
 * 1.  Errors and Events: Custom errors and events for state changes and actions.
 * 2.  Structs: Data structures for Plot NFTs and Creature NFTs.
 * 3.  Constants: Game parameters (growth times, resource rates, etc.).
 * 4.  State Variables:
 *     - Global Garden State (Fertility, Mana, Threat Levels)
 *     - User Internal Balances (Essence, Gems)
 *     - NFT Data Mappings (Plot, Creature states, owners, balances)
 *     - NFT Counters and Base URIs
 *     - Protocol Resource Balances
 *     - Price Simulation Variables (ETH to Essence/Gem)
 *     - Time Tracking (Last Garden Update)
 *     - Pseudo-Randomness Nonce
 * 5.  Internal Helper Functions:
 *     - Pseudo-random number generation (simple, for game logic only)
 *     - State calculations (yield, state decay/growth)
 *     - NFT management (minting/burning - internal logic)
 *     - Resource balance updates (internal)
 * 6.  Public/External Functions (20+ functions):
 *     - Global State Interaction/Reading
 *     - Plot NFT Management (Mint, Get State, Plant, Water, Harvest, Fertilize, Batch Operations)
 *     - Creature NFT Management (Get State, Feed, Expedition, Batch Operations)
 *     - Resource Management (Get Balances, Deposit ETH for Essence, Withdraw Gems as ETH)
 *     - NFT Standard Interface compatibility (OwnerOf, TokenURI, BalanceOf - minimal necessary implementation)
 *     - Price Reading
 *     - Configuration Reading (Growth times, etc.)
 *     - Core Game Loop Trigger (Garden Update Cycle)
 */

// --- 1. Errors and Events ---

/// @custom:error ALCH_PlotNotFound Emitted when a plot ID does not exist.
error ALCH_PlotNotFound(uint256 plotId);
/// @custom:error ALCH_CreatureNotFound Emitted when a creature ID does not exist.
error ALCH_CreatureNotFound(uint256 creatureId);
/// @custom:error ALCH_NotPlotOwner Emitted when caller is not the owner of the plot.
error ALCH_NotPlotOwner(uint256 plotId, address caller, address owner);
/// @custom:error ALCH_NotCreatureOwner Emitted when caller is not the owner of the creature.
error ALCH_NotCreatureOwner(uint256 creatureId, address caller, address owner);
/// @custom:error ALCH_InsufficientEssence Emitted when user tries to use more Essence than they have internally.
error ALCH_InsufficientEssence(address account, uint256 required, uint256 had);
/// @custom:error ALCH_InsufficientGems Emitted when user tries to use more Gems than they have internally.
error ALCH_InsufficientGems(address account, uint256 required, uint256 had);
/// @custom:error ALCH_PlotNotEmpty Emitted when trying to plant on a plot that is already planted.
error ALCH_PlotNotEmpty(uint256 plotId);
/// @custom:error ALCH_PlotNotPlanted Emitted when trying to interact with a plot that is not planted.
error ALCH_PlotNotPlanted(uint256 plotId);
/// @custom:error ALCH_PlotNotMature Emitted when trying to harvest an immature plot.
error ALCH_PlotNotMature(uint256 plotId);
/// @custom:error ALCH_NotEnoughTimeToWaterYet Emitted when watering cooldown is active.
error ALCH_NotEnoughTimeToWaterYet(uint256 plotId, uint256 timeRemaining);
/// @custom:error ALCH_NotEnoughTimeToHarvestYet Emitted when harvest cooldown is active.
error ALCH_NotEnoughTimeToHarvestYet(uint256 plotId, uint256 timeRemaining);
/// @custom:error ALCH_CreatureOnExpedition Emitted when trying to interact with a creature on expedition.
error ALCH_CreatureOnExpedition(uint256 creatureId, uint256 expeditionEndTime);
/// @custom:error ALCH_CreatureNotOnExpedition Emitted when trying to end an expedition that isn't active.
error ALCH_CreatureNotOnExpedition(uint256 creatureId);
/// @custom:error ALCH_NotEnoughTimeToUpdateYet Emitted when global garden update cooldown is active.
error ALCH_NotEnoughTimeToUpdateYet(uint256 timeRemaining);
/// @custom:error ALCH_NoGemsToWithdraw Emitted when trying to withdraw gems but balance is zero.
error ALCH_NoGemsToWithdraw(address account);
/// @custom:error ALCH_WithdrawFailed Emitted if ETH transfer fails during gem withdrawal.
error ALCH_WithdrawFailed(address account, uint256 amount);
/// @custom:error ALCH_BatchOperationFailed Emitted if any individual operation in a batch fails.
error ALCH_BatchOperationFailed(uint256 failedIndex);


/// @custom:event PlotMinted Emitted when a new plot NFT is minted.
event PlotMinted(uint256 indexed plotId, address indexed owner);
/// @custom:event CreatureMinted Emitted when a new creature NFT is minted.
event CreatureMinted(uint256 indexed creatureId, address indexed owner, uint8 creatureType);
/// @custom:event EssenceDeposited Emitted when a user deposits ETH for Essence.
event EssenceDeposited(address indexed account, uint256 ethAmount, uint256 essenceReceived);
/// @custom:event GemsWithdrawn Emitted when a user withdraws Gems as ETH.
event GemsWithdrawn(address indexed account, uint256 gemAmount, uint256 ethSent);
/// @custom:event PlotStateChanged Emitted when a plot's state is updated (planted, watered, harvested, fertilized).
event PlotStateChanged(uint256 indexed plotId, uint8 newState, uint8 plantedEssenceId); // state: 0=Empty, 1=Seed, 2=Growing, 3=Mature, 4=Fertilized
/// @custom:event CreatureStateChanged Emitted when a creature's state is updated (fed, expedition).
event CreatureStateChanged(uint256 indexed creatureId, uint8 newMood, uint8 newPower);
/// @custom:event CreatureSentOnExpedition Emitted when a creature starts an expedition.
event CreatureSentOnExpedition(uint256 indexed creatureId, uint256 endTime);
/// @custom:event CreatureExpeditionCompleted Emitted when a creature expedition ends.
event CreatureExpeditionCompleted(uint256 indexed creatureId, uint256 essenceFound, uint256 gemsFound);
/// @custom:event GardenStateUpdated Emitted when the global garden state changes.
event GardenStateUpdated(uint8 newFertility, uint8 newMana, uint8 newThreat);
/// @custom:event CreatureSpawnAttempted Emitted when the update cycle attempts to spawn a creature.
event CreatureSpawnAttempted(uint256 indexed plotId, bool spawned, uint256 creatureId);
/// @custom:event EssenceBalanceChanged Emitted when a user's internal Essence balance changes.
event EssenceBalanceChanged(address indexed account, uint256 newBalance);
/// @custom:event GemBalanceChanged Emitted when a user's internal Gem balance changes.
event GemBalanceChanged(address indexed account, uint256 newBalance);


// --- 2. Structs ---

/// @dev Represents a Plot NFT state.
struct Plot {
    uint256 creationTime;
    address owner; // Store owner here for quick lookup, also tracked in _plotOwners map
    uint8 fertility; // Base fertility (0-100)
    uint8 manaCapacity; // Mana capacity (0-100)
    uint8 plantedEssenceId; // 0=Empty, >0=Essence type
    uint256 plantTime; // Timestamp when planted
    uint256 lastWateredTime; // Timestamp when last watered
    uint256 fertilityBonusEndTime; // Timestamp when fertilization bonus ends
    uint8 growthStage; // 0=Empty, 1=Seed, 2=Growing, 3=Mature, 4=Fertilized (temp state)
}

/// @dev Represents a Creature NFT state.
struct Creature {
    uint256 creationTime;
    address owner; // Store owner here for quick lookup, also tracked in _creatureOwners map
    uint8 creatureType; // ID representing the creature type
    uint8 mood; // Affects outcome (0-100)
    uint8 power; // Affects outcome (0-100)
    uint256 expeditionEndTime; // Timestamp when current expedition ends (0 if not on expedition)
    uint256 lastFedTime; // Timestamp when last fed
}


// --- 3. Constants ---

// NFT Base URIs (Assuming dynamic data served off-chain based on on-chain state)
string public constant PLOT_BASE_URI = "ipfs://YOUR_PLOT_METADATA_CID/"; // Or HTTP endpoint
string public constant CREATURE_BASE_URI = "ipfs://YOUR_CREATURE_METADATA_CID/"; // Or HTTP endpoint

// Initial Garden State
uint8 public constant INITIAL_FERTILITY = 50;
uint8 public constant INITIAL_MANA_LEVEL = 50;
uint8 public constant INITIAL_THREAT_LEVEL = 10;

// Growth/Action Times (in seconds)
uint256 public constant PLANT_TO_WATER_COOLDOWN = 1 hours; // Time before watering is possible
uint256 public constant WATER_TO_WATER_COOLDOWN = 6 hours; // Cooldown between watering
uint256 public constant GROWING_TO_MATURE_TIME = 24 hours; // Total growth time
uint256 public constant FERTILIZE_DURATION = 12 hours; // How long fertilization lasts
uint256 public constant MIN_GARDEN_UPDATE_INTERVAL = 30 minutes; // Min time between global updates
uint256 public constant CREATURE_EXPEDITION_DURATION = 8 hours; // How long expeditions last
uint256 public constant CREATURE_FEED_COOLDOWN = 4 hours; // Cooldown between feeding a creature

// Resource Costs/Yields
uint256 public constant MINT_PLOT_ETH_COST = 0.01 ether; // Cost to mint a plot
uint256 public constant ESSENCE_PER_ETH = 1000; // Exchange rate for depositing ETH
uint256 public constant PLANT_ESSENCE_COST = 10; // Essence needed to plant
uint256 public constant FERTILIZE_ESSENCE_COST = 20; // Essence needed to fertilize
uint256 public constant FEED_CREATURE_ESSENCE_COST = 5; // Essence to feed
uint256 public constant FEED_CREATURE_GEM_COST = 1; // Gems to feed
uint256 public constant BASE_HARVEST_GEM_YIELD = 50; // Base gems from harvest
uint256 public constant MAX_HARVEST_GEM_YIELD_BONUS = 100; // Max bonus yield
uint256 public constant BASE_GEM_VALUE_PER_ETH_WEI = 1 ether / 50; // Base value of 1 Gem in Wei (simulate a price feed)
uint256 public constant CREATURE_EXPEDITION_BASE_GEM_FIND = 10;
uint256 public constant CREATURE_EXPEDITION_BASE_ESSENCE_FIND = 5;

// Limits
uint256 public constant MAX_PLOTS = 10000; // Total plots available
uint256 public constant MAX_CREATURES_PER_PLOT = 1; // Limit creatures per plot (for simplicity)

// --- 4. State Variables ---

// Global Garden State
uint8 public gardenFertility; // Affects growth speed/yield
uint8 public gardenManaLevel; // Affects mana-consuming actions/creature power
uint8 public gardenThreatLevel; // Affects negative events

// User Internal Balances
mapping(address => uint256) private _essenceBalances;
mapping(address => uint256) private _gemBalances;

// NFT Data
mapping(uint256 => Plot) private _plots;
mapping(address => uint256[]) private _ownerPlots; // Simple owner mapping (not robust for transfers without full ERC721)
mapping(uint256 => address) private _plotOwners; // Standard ERC721 owner mapping
mapping(address => uint256) private _plotBalances; // Standard ERC721 balance mapping
uint256 private _plotCounter; // Next available plot ID

mapping(uint256 => Creature) private _creatures;
mapping(address => uint256[]) private _ownerCreatures; // Simple owner mapping (not robust)
mapping(uint256 => address) private _creatureOwners; // Standard ERC721 owner mapping
mapping(address => uint256) private _creatureBalances; // Standard ERC721 balance mapping
uint256 private _creatureCounter; // Next available creature ID

// Protocol Resource Balances (Accumulated unused resources, potential future use)
uint256 public protocolEssenceBalance;
uint256 public protocolGemBalance;

// Price Simulation (Can be updated via governance or external oracle in a real system)
uint256 public essencePricePerEth; // How much Essence 1 ETH buys
uint256 public gemPricePerEthWei; // How much Wei 1 Gem is worth

// Time Tracking
uint256 public lastGardenUpdateTimestamp;

// Pseudo-Randomness Nonce
uint256 private _nonceCounter;


// --- 5. Internal Helper Functions ---

/// @dev Generates a pseudo-random number for internal game logic. NOT secure for high-value outcomes.
/// @param seed Additional seed data for variability.
/// @return uint256 A pseudo-random number.
function _generatePseudoRandomUint(uint256 seed) internal returns (uint256) {
    _nonceCounter++;
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, _nonceCounter, seed)));
}

/// @dev Updates a user's internal essence balance and emits an event.
function _updateEssenceBalance(address account, uint256 amount, bool add) internal {
    if (add) {
        _essenceBalances[account] += amount;
    } else {
        if (_essenceBalances[account] < amount) {
            revert ALCH_InsufficientEssence(account, amount, _essenceBalances[account]);
        }
        _essenceBalances[account] -= amount;
    }
    emit EssenceBalanceChanged(account, _essenceBalances[account]);
}

/// @dev Updates a user's internal gem balance and emits an event.
function _updateGemBalance(address account, uint256 amount, bool add) internal {
    if (add) {
        _gemBalances[account] += amount;
    } else {
        if (_gemBalances[account] < amount) {
            revert ALCH_InsufficientGems(account, amount, _gemBalances[account]);
        }
        _gemBalances[account] -= amount;
    }
    emit GemBalanceChanged(account, _gemBalances[account]);
}

/// @dev Internal function to mint a plot NFT. Handles state and owner mappings.
function _mintPlot(address to) internal returns (uint256) {
    uint256 newPlotId = _plotCounter;
    if (newPlotId >= MAX_PLOTS) revert(); // Or custom error

    _plotCounter++;
    _plots[newPlotId] = Plot({
        creationTime: block.timestamp,
        owner: to,
        fertility: uint8(50 + (_generatePseudoRandomUint(newPlotId) % 51) - 25), // Base +/- 25 variation
        manaCapacity: uint8(50 + (_generatePseudoRandomUint(newPlotId + 1) % 51) - 25), // Base +/- 25 variation
        plantedEssenceId: 0,
        plantTime: 0,
        lastWateredTime: 0,
        fertilityBonusEndTime: 0,
        growthStage: 0
    });
    _plotOwners[newPlotId] = to;
    _plotBalances[to]++;
    _ownerPlots[to].push(newPlotId); // Simplified tracking
    emit PlotMinted(newPlotId, to);
    return newPlotId;
}

/// @dev Internal function to mint a creature NFT. Handles state and owner mappings.
function _mintCreature(address to, uint8 creatureType) internal returns (uint256) {
     // Basic check, maybe add more limits later
    if (_creatureBalances[to] >= MAX_CREATURES_PER_PLOT * _plotBalances[to]) {
         // Cannot mint creature if owner doesn't have enough plots or already maxed
         // Or perhaps creature spawning logic needs to find a plot first.
         // For now, let's assume this is called *after* a plot is identified for the creature.
         // Let's simplify: creature is minted *to* the user, not tied to a specific plot in state, only conceptually.
    }


    uint256 newCreatureId = _creatureCounter;
    _creatureCounter++;
    _creatures[newCreatureId] = Creature({
        creationTime: block.timestamp,
        owner: to,
        creatureType: creatureType,
        mood: uint8(50 + (_generatePseudoRandomUint(newCreatureId * 2) % 31) - 15), // Base +/- 15
        power: uint8(50 + (_generatePseudoRandomUint(newCreatureId * 3) % 31) - 15), // Base +/- 15
        expeditionEndTime: 0,
        lastFedTime: 0
    });
     _creatureOwners[newCreatureId] = to;
    _creatureBalances[to]++;
    _ownerCreatures[to].push(newCreatureId); // Simplified tracking
    emit CreatureMinted(newCreatureId, to, creatureType);
    return newCreatureId;
}


/// @dev Calculates the current growth stage of a plot based on time and state.
/// @param plot The plot struct.
/// @return uint8 The current growth stage (0=Empty, 1=Seed, 2=Growing, 3=Mature).
function _calculateGrowthStage(Plot storage plot) internal view returns (uint8) {
    if (plot.plantedEssenceId == 0) return 0; // Empty
    if (plot.lastWateredTime == 0) return 1; // Planted but not watered yet (Seed)

    uint256 timeSinceWatered = block.timestamp - plot.lastWateredTime;
    uint256 effectiveGrowthTime = timeSinceWatered + (plot.lastWateredTime - plot.plantTime); // Rough simplification

    // Apply fertility bonus (up to FertilizeDuration)
    if (block.timestamp < plot.fertilityBonusEndTime) {
        uint256 bonusFactor = 100 + (plot.fertility / 5); // Example: 50 fertility adds 10% growth speed
        effectiveGrowthTime = (effectiveGrowthTime * bonusFactor) / 100;
    }

    if (effectiveGrowthTime >= GROWING_TO_MATURE_TIME) {
        return 3; // Mature
    }
    return 2; // Growing
}

/// @dev Calculates the harvest yield for a mature plot based on state.
/// @param plot The plot struct.
/// @return uint256 The calculated gem yield.
function _calculateHarvestYield(Plot storage plot) internal view returns (uint256) {
    if (_calculateGrowthStage(plot) != 3) return 0;

    uint256 baseYield = BASE_HARVEST_GEM_YIELD;
    uint256 fertilityBonus = (plot.fertility * MAX_HARVEST_GEM_YIELD_BONUS) / 100; // Fertility adds up to max bonus
    uint256 gardenBonus = (gardenFertility * MAX_HARVEST_GEM_YIELD_BONUS) / 200; // Global fertility adds up to half max bonus

    uint256 totalYield = baseYield + fertilityBonus + gardenBonus;

    // Add a small random variation (+/- 10% of base)
    uint256 randomFactor = _generatePseudoRandomUint(plot.plantTime + plot.lastWateredTime) % 21; // 0 to 20
    int256 variation = int256(totalYield / 10) * (int256(randomFactor) - 10) / 10; // -10% to +10%

    unchecked {
        totalYield = totalYield + uint256(variation);
    }

    return totalYield;
}

/// @dev Attempts to spawn a creature on a plot based on garden conditions and randomness.
/// Called during garden update cycle.
/// @param plotId The ID of the plot to check.
/// @return bool True if a creature was spawned.
function _attemptCreatureSpawnOnPlot(uint256 plotId) internal returns (bool) {
    Plot storage plot = _plots[plotId];
    if (plot.owner == address(0)) return false; // Plot doesn't exist

    // Creature spawn conditions (example logic)
    // More likely to spawn if garden mana is high and threat is low, and plot fertility is high.
    uint256 spawnChance = (gardenManaLevel + (100 - gardenThreatLevel) + plot.fertility) / 3; // Avg of factors
    spawnChance = spawnChance > 100 ? 100 : spawnChance < 0 ? 0 : spawnChance; // Clamp 0-100

    // Add some randomness
    uint256 randomRoll = _generatePseudoRandomUint(plotId * block.timestamp) % 100; // Roll 0-99

    if (randomRoll < spawnChance / 5) { // e.g., 20% of the chance value
         // Prevent spawning if owner already has max creatures per plot
         if (_creatureBalances[plot.owner] >= MAX_CREATURES_PER_PLOT * _plotBalances[plot.owner]) {
             emit CreatureSpawnAttempted(plotId, false, 0);
             return false;
         }

        // Spawn a creature!
        uint8 creatureType = uint8(_generatePseudoRandomUint(plotId * 2) % 5) + 1; // Example: 5 types
        uint256 newCreatureId = _mintCreature(plot.owner, creatureType);
        emit CreatureSpawnAttempted(plotId, true, newCreatureId);
        return true;
    }

    emit CreatureSpawnAttempted(plotId, false, 0);
    return false;
}

/// @dev Internal helper to safely send Ether.
/// @param recipient The address to send Ether to.
/// @param amount The amount of Ether to send (in wei).
function _safeTransferETH(address recipient, uint256 amount) internal {
    (bool success, ) = recipient.call{value: amount}("");
    if (!success) {
        revert ALCH_WithdrawFailed(recipient, amount);
    }
}


// --- 6. Public/External Functions ---

// --- Global State ---

/// @notice Triggers an update cycle for the global garden state and attempts random events.
/// Can be called by anyone, but has a minimum time interval.
function triggerGardenUpdateCycle() external {
    if (block.timestamp < lastGardenUpdateTimestamp + MIN_GARDEN_UPDATE_INTERVAL) {
        revert ALCH_NotEnoughTimeToUpdateYet(lastGardenUpdateTimestamp + MIN_GARDEN_UPDATE_INTERVAL - block.timestamp);
    }

    lastGardenUpdateTimestamp = block.timestamp;

    // Simulate global state changes based on activity, time, etc. (Simplified example)
    // Decay Mana over time, Increase Threat if no actions, Increase Fertility with actions?

    // Example Decay/Growth:
    if (gardenManaLevel > 0) gardenManaLevel = gardenManaLevel > 5 ? gardenManaLevel - 5 : 0;
    if (gardenThreatLevel < 100) gardenThreatLevel = gardenThreatLevel + 1;
    // Fertility could increase slightly if many plots are fertilized recently (requires more complex tracking)

    // Clamp values
    if (gardenFertility > 100) gardenFertility = 100;
    if (gardenManaLevel > 100) gardenManaLevel = 100;
    if (gardenThreatLevel > 100) gardenThreatLevel = 100;

    emit GardenStateUpdated(gardenFertility, gardenManaLevel, gardenThreatLevel);

    // Attempt to spawn creatures on random plots (gas considerations: don't iterate all plots)
    // For a large number of plots, this needs optimization (e.g., random sample, or external trigger).
    // For this example, let's attempt on a few recent plots or owners.
    // Simplified: Attempt on a few random plot IDs
     uint256 totalPlots = _plotCounter;
     if (totalPlots > 0) {
         uint256 plotsToCheck = totalPlots > 20 ? 20 : totalPlots; // Check up to 20 plots per update
         for(uint i = 0; i < plotsToCheck; i++) {
             uint256 randomPlotId = _generatePseudoRandomUint(block.timestamp + i) % totalPlots;
             _attemptCreatureSpawnOnPlot(randomPlotId);
         }
     }

}

/// @notice Gets the current global garden fertility level.
/// @return uint8 The fertility level (0-100).
function getGardenFertility() external view returns (uint8) {
    return gardenFertility;
}

/// @notice Gets the current global garden mana level.
/// @return uint8 The mana level (0-100).
function getGardenManaLevel() external view returns (uint8) {
    return gardenManaLevel;
}

/// @notice Gets the current global garden threat level.
/// @return uint8 The threat level (0-100).
function getThreatLevel() external view returns (uint8) {
    return gardenThreatLevel;
}

/// @notice Gets the timestamp of the last global garden update.
/// @return uint256 Timestamp in seconds.
function getTimeSinceLastUpdate() external view returns (uint256) {
    return block.timestamp - lastGardenUpdateTimestamp;
}

// --- Plot NFT Management ---

/// @notice Mints a new plot NFT for the caller. Requires sending ETH.
/// @dev Limited by MAX_PLOTS.
/// @return uint256 The ID of the newly minted plot.
function mintPlot() external payable returns (uint256) {
    if (msg.value < MINT_PLOT_ETH_COST) revert(); // Or custom error: ALCH_InsufficientPayment(MINT_PLOT_ETH_COST, msg.value)
    if (_plotCounter >= MAX_PLOTS) revert(); // Or custom error: ALCH_MaxPlotsReached(MAX_PLOTS)

    uint256 newPlotId = _mintPlot(msg.sender);

    // Send excess ETH back if any
    if (msg.value > MINT_PLOT_ETH_COST) {
        _safeTransferETH(msg.sender, msg.value - MINT_PLOT_ETH_COST);
    }

    return newPlotId;
}

/// @notice Gets the detailed state of a specific plot NFT.
/// @param plotId The ID of the plot.
/// @return Plot The plot struct.
function getPlotState(uint256 plotId) external view returns (Plot memory) {
    Plot storage plot = _plots[plotId];
    if (plot.owner == address(0)) revert ALCH_PlotNotFound(plotId);
    return plot;
}

/// @notice Plants a specific type of Essence on a plot. Consumes internal Essence.
/// @param plotId The ID of the plot.
/// @param essenceId The ID of the essence type to plant (e.g., 1=Water, 2=Fire, etc.) - basic type check omitted for brevity.
function plantEssence(uint256 plotId, uint8 essenceId) external {
    Plot storage plot = _plots[plotId];
    if (plot.owner == address(0)) revert ALCH_PlotNotFound(plotId);
    if (plot.owner != msg.sender) revert ALCH_NotPlotOwner(plotId, msg.sender, plot.owner);
    if (plot.plantedEssenceId != 0) revert ALCH_PlotNotEmpty(plotId);
    if (essenceId == 0) revert(); // Cannot plant empty essence

    _updateEssenceBalance(msg.sender, PLANT_ESSENCE_COST, false); // Consume essence

    plot.plantedEssenceId = essenceId;
    plot.plantTime = block.timestamp;
    plot.lastWateredTime = 0; // Reset watering time
    plot.growthStage = 1; // Seed stage

    emit PlotStateChanged(plotId, plot.growthStage, plot.plantedEssenceId);
}

/// @notice Waters a planted plot to advance its growth. Time-gated.
/// @param plotId The ID of the plot.
function waterPlot(uint256 plotId) external {
    Plot storage plot = _plots[plotId];
    if (plot.owner == address(0)) revert ALCH_PlotNotFound(plotId);
    if (plot.owner != msg.sender) revert ALCH_NotPlotOwner(plotId, msg.sender, plot.owner);
    if (plot.plantedEssenceId == 0) revert ALCH_PlotNotPlanted(plotId);

    uint256 minWaterTime = (plot.lastWateredTime == 0) ? plot.plantTime + PLANT_TO_WATER_COOLDOWN : plot.lastWateredTime + WATER_TO_WATER_COOLDOWN;

    if (block.timestamp < minWaterTime) {
        revert ALCH_NotEnoughTimeToWaterYet(plotId, minWaterTime - block.timestamp);
    }

    plot.lastWateredTime = block.timestamp;
    plot.growthStage = _calculateGrowthStage(plot); // Recalculate stage

    // Simulate mana consumption (optional, could use global mana)
    // if (gardenManaLevel < 1) revert ALCH_InsufficientGardenMana();
    // gardenManaLevel--; // Example effect

    emit PlotStateChanged(plotId, plot.growthStage, plot.plantedEssenceId);
}

/// @notice Harvests a mature plot, yielding internal Gems and resetting the plot. Time-gated since last water/plant.
/// @param plotId The ID of the plot.
function harvestPlot(uint256 plotId) external {
    Plot storage plot = _plots[plotId];
    if (plot.owner == address(0)) revert ALCH_PlotNotFound(plotId);
    if (plot.owner != msg.sender) revert ALCH_NotPlotOwner(plotId, msg.sender, plot.owner);
    if (plot.plantedEssenceId == 0) revert ALCH_PlotNotPlanted(plotId);

    uint8 currentStage = _calculateGrowthStage(plot);
    if (currentStage != 3) revert ALCH_PlotNotMature(plotId);

    // Calculate yield
    uint256 gemYield = _calculateHarvestYield(plot);

    // Add gems to user's internal balance
    _updateGemBalance(msg.sender, gemYield, true);

    // Reset plot state
    plot.plantedEssenceId = 0;
    plot.plantTime = 0;
    plot.lastWateredTime = 0;
    plot.fertilityBonusEndTime = 0; // Reset bonus
    plot.growthStage = 0;

    emit PlotStateChanged(plotId, plot.growthStage, 0); // 0 for empty EssenceId
}

/// @notice Fertilizes a plot, consuming Essence and boosting fertility temporarily.
/// @param plotId The ID of the plot.
function fertilizePlot(uint256 plotId) external {
    Plot storage plot = _plots[plotId];
    if (plot.owner == address(0)) revert ALCH_PlotNotFound(plotId);
    if (plot.owner != msg.sender) revert ALCH_NotPlotOwner(plotId, msg.sender, plot.owner);
    // Fertilization can be done even if not planted, maybe? Let's allow it.

    _updateEssenceBalance(msg.sender, FERTILIZE_ESSENCE_COST, false); // Consume essence

    plot.fertilityBonusEndTime = block.timestamp + FERTILIZE_DURATION;
    plot.growthStage = 4; // Indicate fertilized state visually/in metadata

    emit PlotStateChanged(plotId, plot.growthStage, plot.plantedEssenceId);
}

// --- Batch Plot Operations ---

/// @notice Waters multiple plots owned by the caller in a single transaction.
/// @dev Fails fast if any plot cannot be watered (e.g., not owned, on cooldown).
/// @param plotIds An array of plot IDs to water.
function batchWaterPlots(uint256[] calldata plotIds) external {
    for (uint256 i = 0; i < plotIds.length; i++) {
        waterPlot(plotIds[i]); // Reuse single function logic
    }
}

/// @notice Harvests multiple mature plots owned by the caller in a single transaction.
/// @dev Fails fast if any plot cannot be harvested.
/// @param plotIds An array of plot IDs to harvest.
function batchHarvestPlots(uint256[] calldata plotIds) external {
     for (uint256 i = 0; i < plotIds.length; i++) {
        harvestPlot(plotIds[i]); // Reuse single function logic
    }
}

// --- Creature NFT Management ---

/// @notice Gets the detailed state of a specific creature NFT.
/// @param creatureId The ID of the creature.
/// @return Creature The creature struct.
function getCreatureState(uint256 creatureId) external view returns (Creature memory) {
    Creature storage creature = _creatures[creatureId];
     if (creature.owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    return creature;
}

/// @notice Feeds a creature using either internal Essence or Gems to boost mood/power. Time-gated.
/// @param creatureId The ID of the creature.
/// @param useEssence True to use Essence, false to use Gems.
function feedCreature(uint256 creatureId, bool useEssence) external {
    Creature storage creature = _creatures[creatureId];
    if (creature.owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    if (creature.owner != msg.sender) revert ALCH_NotCreatureOwner(creatureId, msg.sender, creature.owner);
    if (creature.expeditionEndTime > block.timestamp) revert ALCH_CreatureOnExpedition(creatureId, creature.expeditionEndTime);

    if (block.timestamp < creature.lastFedTime + CREATURE_FEED_COOLDOWN) revert(); // Or custom error

    if (useEssence) {
        _updateEssenceBalance(msg.sender, FEED_CREATURE_ESSENCE_COST, false);
        creature.mood = creature.mood + 10 > 100 ? 100 : creature.mood + 10; // Example boost
    } else {
        _updateGemBalance(msg.sender, FEED_CREATURE_GEM_COST, false);
        creature.power = creature.power + 5 > 100 ? 100 : creature.power + 5; // Example boost
    }

    creature.lastFedTime = block.timestamp;

    emit CreatureStateChanged(creatureId, creature.mood, creature.power);
}

/// @notice Sends a creature on an expedition to potentially find resources. Time-gated.
/// @param creatureId The ID of the creature.
function sendCreatureOnExpedition(uint256 creatureId) external {
    Creature storage creature = _creatures[creatureId];
    if (creature.owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    if (creature.owner != msg.sender) revert ALCH_NotCreatureOwner(creatureId, msg.sender, creature.owner);
    if (creature.expeditionEndTime > block.timestamp) revert ALCH_CreatureOnExpedition(creatureId, creature.expeditionEndTime);

    creature.expeditionEndTime = block.timestamp + CREATURE_EXPEDITION_DURATION;

    emit CreatureSentOnExpedition(creatureId, creature.expeditionEndTime);
}

/// @notice Ends a creature's expedition and claims rewards based on success chance.
/// @param creatureId The ID of the creature.
function endCreatureExpedition(uint256 creatureId) external {
     Creature storage creature = _creatures[creatureId];
    if (creature.owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    if (creature.owner != msg.sender) revert ALCH_NotCreatureOwner(creatureId, msg.sender, creature.owner);
    if (creature.expeditionEndTime == 0 || creature.expeditionEndTime > block.timestamp) revert ALCH_CreatureNotOnExpedition(creatureId);

    creature.expeditionEndTime = 0; // Reset expedition state

    // Calculate success chance based on creature state and garden state (example logic)
    uint256 successChance = (creature.power + creature.mood + (100 - gardenThreatLevel)) / 3; // Avg of factors
     successChance = successChance > 100 ? 100 : successChance < 0 ? 0 : successChance; // Clamp 0-100

    uint256 randomRoll = _generatePseudoRandomUint(creatureId * block.timestamp * 2) % 100; // Roll 0-99

    uint256 gemsFound = 0;
    uint256 essenceFound = 0;

    if (randomRoll < successChance) {
        // Expedition success! Calculate rewards.
        gemsFound = CREATURE_EXPEDITION_BASE_GEM_FIND + (creature.power / 10); // Power adds to gems
        essenceFound = CREATURE_EXPEDITION_BASE_ESSENCE_FIND + (creature.mood / 10); // Mood adds to essence

        _updateGemBalance(msg.sender, gemsFound, true);
        _updateEssenceBalance(msg.sender, essenceFound, true);
    }

    emit CreatureExpeditionCompleted(creatureId, essenceFound, gemsFound);
}

// --- Batch Creature Operations ---

/// @notice Feeds multiple creatures owned by the caller in a single transaction.
/// @dev Fails fast if any creature cannot be fed.
/// @param creatureIds An array of creature IDs to feed.
/// @param useEssence True to use Essence, false to use Gems for all creatures in the batch.
function batchFeedCreatures(uint256[] calldata creatureIds, bool useEssence) external {
    for (uint256 i = 0; i < creatureIds.length; i++) {
        feedCreature(creatureIds[i], useEssence); // Reuse single function logic
    }
}

/// @notice Sends multiple creatures owned by the caller on expeditions.
/// @dev Fails fast if any creature cannot be sent.
/// @param creatureIds An array of creature IDs to send.
function batchSendCreaturesOnExpedition(uint256[] calldata creatureIds) external {
     for (uint256 i = 0; i < creatureIds.length; i++) {
        sendCreatureOnExpedition(creatureIds[i]); // Reuse single function logic
    }
}


// --- Resource Management ---

/// @notice Gets the internal Essence balance for an account.
/// @param account The address to check.
/// @return uint256 The Essence balance.
function getEssenceBalance(address account) external view returns (uint256) {
    return _essenceBalances[account];
}

/// @notice Gets the internal Gem balance for an account.
/// @param account The address to check.
/// @return uint256 The Gem balance.
function getGemBalance(address account) external view returns (uint256) {
    return _gemBalances[account];
}

/// @notice Deposits Ether to receive internal Essence tokens.
function depositEtherForEssence() external payable {
    if (msg.value == 0) revert(); // Or custom error
    uint256 essenceReceived = (msg.value * essencePricePerEth) / 1 ether; // Calculate essence based on price

    if (essenceReceived == 0) {
        // Return ETH if calculated essence is zero due to low amount or high price
        _safeTransferETH(msg.sender, msg.value);
        return;
    }

    _updateEssenceBalance(msg.sender, essenceReceived, true);

    // Any dust ETH remaining is kept by the protocol
    protocolEssenceBalance += msg.value % (1 ether / essencePricePerEth); // Accumulate dust ETH value *in terms of Essence*

    emit EssenceDeposited(msg.sender, msg.value, essenceReceived);

    // --- Simulate Price Impact (Basic Example) ---
    // Large deposits could slightly decrease the price per ETH
    if (essencePricePerEth > 1 && msg.value > 1 ether) { // Only adjust if price > 1 and deposit > 1 ETH
        essencePricePerEth = essencePricePerEth > 5 ? essencePricePerEth - (msg.value / (1 ether * 10)) : 1; // Decrease slightly
    }
     if (essencePricePerEth < 1) essencePricePerEth = 1; // Minimum price
    // --- End Simulate Price Impact ---
}

/// @notice Withdraws internal Gem balance by converting it to Ether and sending it.
/// @dev Conversion uses the current simulated Gem price.
function withdrawGemsAsEther() external {
    uint256 gemBalance = _gemBalances[msg.sender];
    if (gemBalance == 0) revert ALCH_NoGemsToWithdraw(msg.sender);

    uint256 ethAmount = (gemBalance * gemPricePerEthWei) / 1 ether; // Calculate ETH based on price

    if (ethAmount == 0) {
        // If conversion results in 0 ETH (due to low gem amount or low price),
        // don't attempt transfer, maybe leave gems or burn them? Let's burn dust.
        _gemBalances[msg.sender] = 0; // Burn the dust gems
         emit GemBalanceChanged(msg.sender, 0);
        return;
    }

    _updateGemBalance(msg.sender, gemBalance, false); // Deduct gems

    _safeTransferETH(msg.sender, ethAmount);

    // Any dust Gems remaining from conversion are kept by the protocol
    protocolGemBalance += gemBalance % (1 ether / gemPricePerEthWei); // Accumulate dust Gem value *in terms of Gems*


    emit GemsWithdrawn(msg.sender, gemBalance, ethAmount);

    // --- Simulate Price Impact (Basic Example) ---
    // Large withdrawals could slightly increase the price per Gem
     if (gemPricePerEthWei > 1 && ethAmount > 1 ether) { // Only adjust if price > 1 wei/gem and withdrawal > 1 ETH
        gemPricePerEthWei = gemPricePerEthWei + (ethAmount / (1 ether * 10)); // Increase slightly
    }
    // --- End Simulate Price Impact ---
}


// --- NFT Standard Interface Compatibility (Minimal Implementation) ---
// Required for basic wallet compatibility and marketplaces to identify/display assets.
// Full ERC721Enumerable/Transfer logic is NOT implemented here to meet the "don't duplicate" constraint.

/// @notice Returns the owner of the plot NFT.
/// @param plotId The ID of the plot.
/// @return address The owner's address.
function ownerOfPlot(uint256 plotId) external view returns (address) {
    address owner = _plotOwners[plotId];
    if (owner == address(0)) revert ALCH_PlotNotFound(plotId);
    return owner;
}

/// @notice Returns a URI for the plot NFT metadata.
/// @dev This points to off-chain metadata that should reflect the on-chain state.
/// @param plotId The ID of the plot.
/// @return string The metadata URI.
function tokenURIPlot(uint256 plotId) external view returns (string memory) {
    // Check if plot exists before returning URI
    if (_plots[plotId].owner == address(0)) revert ALCH_PlotNotFound(plotId);
    // Return base URI + token ID. Off-chain service will get state via contract read calls.
    return string(abi.encodePacked(PLOT_BASE_URI, Strings.toString(plotId)));
}

/// @notice Returns the number of plots owned by an account.
/// @param owner The address to check.
/// @return uint256 The balance of plots.
function balanceOfPlots(address owner) external view returns (uint256) {
    if (owner == address(0)) revert(); // Zero address check
    return _plotBalances[owner];
}

/// @notice Returns the owner of the creature NFT.
/// @param creatureId The ID of the creature.
/// @return address The owner's address.
function ownerOfCreature(uint256 creatureId) external view returns (address) {
    address owner = _creatureOwners[creatureId];
    if (owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    return owner;
}

/// @notice Returns a URI for the creature NFT metadata.
/// @dev This points to off-chain metadata that should reflect the on-chain state.
/// @param creatureId The ID of the creature.
/// @return string The metadata URI.
function tokenURICreature(uint256 creatureId) external view returns (string memory) {
     // Check if creature exists before returning URI
    if (_creatures[creatureId].owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    // Return base URI + token ID. Off-chain service will get state via contract read calls.
    return string(abi.encodePacked(CREATURE_BASE_URI, Strings.toString(creatureId)));
}

/// @notice Returns the number of creatures owned by an account.
/// @param owner The address to check.
/// @return uint256 The balance of creatures.
function balanceOfCreatures(address owner) external view returns (uint256) {
     if (owner == address(0)) revert(); // Zero address check
    return _creatureBalances[owner];
}

// --- Price Reading ---

/// @notice Gets the current simulated price for converting ETH to Essence.
/// @return uint256 The amount of Essence received per 1 ETH.
function getEssencePricePerEth() external view returns (uint256) {
    return essencePricePerEth;
}

/// @notice Gets the current simulated price for converting Gems to ETH.
/// @return uint256 The amount of Wei received per 1 Gem.
function getGemPricePerEthWei() external view returns (uint256) {
    return gemPricePerEthWei;
}


// --- Configuration Reading ---

/// @notice Gets the required time in seconds for a planted plot to become mature.
/// @return uint256 Time in seconds.
function getPlotGrowthTime() external pure returns (uint256) {
    return GROWING_TO_MATURE_TIME;
}

/// @notice Gets the duration in seconds for a creature expedition.
/// @return uint256 Time in seconds.
function getExpeditionDuration() external pure returns (uint256) {
    return CREATURE_EXPEDITION_DURATION;
}

/// @notice Gets the minimum time interval in seconds between global garden updates.
/// @return uint256 Time in seconds.
function getMinGardenUpdateInterval() external pure returns (uint256) {
    return MIN_GARDEN_UPDATE_INTERVAL;
}

/// @notice Gets the time a specific plot was created.
/// @param plotId The ID of the plot.
/// @return uint256 Timestamp in seconds.
function getPlotCreationTime(uint256 plotId) external view returns (uint256) {
     if (_plots[plotId].owner == address(0)) revert ALCH_PlotNotFound(plotId);
    return _plots[plotId].creationTime;
}

/// @notice Gets the time a specific creature was last fed.
/// @param creatureId The ID of the creature.
/// @return uint256 Timestamp in seconds.
function getCreatureLastFedTime(uint256 creatureId) external view returns (uint256) {
     if (_creatures[creatureId].owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    return _creatures[creatureId].lastFedTime;
}

/// @notice Gets the time a specific creature's expedition ends.
/// @param creatureId The ID of the creature.
/// @return uint256 Timestamp in seconds (0 if not on expedition).
function getCreatureExpeditionEndTime(uint256 creatureId) external view returns (uint256) {
     if (_creatures[creatureId].owner == address(0)) revert ALCH_CreatureNotFound(creatureId);
    return _creatures[creatureId].expeditionEndTime;
}

/// @notice Gets the time a specific plot was planted.
/// @param plotId The ID of the plot.
/// @return uint256 Timestamp in seconds (0 if not planted).
function getPlotPlantTime(uint256 plotId) external view returns (uint256) {
    if (_plots[plotId].owner == address(0)) revert ALCH_PlotNotFound(plotId);
    return _plots[plotId].plantTime;
}

/// @notice Gets the time a specific plot was last watered.
/// @param plotId The ID of the plot.
/// @return uint256 Timestamp in seconds (0 if not watered).
function getPlotLastWateredTime(uint256 plotId) external view returns (uint256) {
     if (_plots[plotId].owner == address(0)) revert ALCH_PlotNotFound(plotId);
    return _plots[plotId].lastWateredTime;
}

/// @notice Gets the time a specific plot's fertilization bonus ends.
/// @param plotId The ID of the plot.
/// @return uint256 Timestamp in seconds (0 if no bonus active).
function getPlotFertilityBonusEndTime(uint256 plotId) external view returns (uint256) {
     if (_plots[plotId].owner == address(0)) revert ALCH_PlotNotFound(plotId);
    return _plots[plotId].fertilityBonusEndTime;
}


// Utility library for toString (commonly used, minimal duplication risk)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


// Add a receive function to accept Ether for depositEtherForEssence
receive() external payable {
    // Function body is empty as depositEtherForEssence is called directly
    // or handles the value sent in the receive function itself if no data is sent.
    // For clarity, forcing calls to depositEtherForEssence is better.
    // Adding this function just allows the contract to receive ETH.
}


// Constructor
constructor() {
    gardenFertility = INITIAL_FERTILITY;
    gardenManaLevel = INITIAL_MANA_LEVEL;
    gardenThreatLevel = INITIAL_THREAT_LEVEL;
    lastGardenUpdateTimestamp = block.timestamp;
    essencePricePerEth = ESSENCE_PER_ETH; // Initial simulated price
    gemPricePerEthWei = BASE_GEM_VALUE_PER_ETH_WEI; // Initial simulated price
     _plotCounter = 0; // Start plot IDs from 0 or 1
    _creatureCounter = 0; // Start creature IDs from 0 or 1
    _nonceCounter = 0; // Initialize nonce for pseudo-randomness
}

}
```

**Explanation of Concepts and How it Avoids Duplication:**

1.  **Dynamic NFTs:** The `Plot` and `Creature` structs store mutable state on-chain (`growthStage`, `plantedEssenceId`, `fertilityBonusEndTime` for plots; `mood`, `power`, `expeditionEndTime` for creatures). The `tokenURI` functions point to off-chain metadata, but the *actual data* served from those URIs should be generated dynamically by a backend service that reads the on-chain state using functions like `getPlotState` and `getCreatureState`. This is a common, trendy pattern for dynamic NFTs. We don't duplicate a standard dynamic NFT *library*, but implement the mechanism.
2.  **Interconnected State:** User actions on individual plots (`waterPlot`, `fertilizePlot`, `harvestPlot`) contribute to the game loop's potential to alter global state (not fully implemented in detail, but the `triggerGardenUpdateCycle` is the hook for this) and trigger events like creature spawning (`_attemptCreatureSpawnOnPlot`). The global state (`gardenFertility`, `gardenManaLevel`, `gardenThreatLevel`) in turn affects the outcomes of individual actions (harvest yield, creature expedition success).
3.  **Internal Resource Management:** Instead of implementing full ERC-20 tokens for Essence and Gems that can be transferred anywhere, these are primarily managed *within* the contract using internal balance mappings (`_essenceBalances`, `_gemBalances`). Users interact with these resources by depositing ETH (`depositEtherForEssence`) to get Essence internally, using Essence/Gems for actions (`plantEssence`, `fertilizePlot`, `feedCreature`), and withdrawing Gems by converting them back to ETH (`withdrawGemsAsEther`). This creates a self-contained economy within the protocol and avoids needing separate ERC-20 contracts or duplicating standard ERC-20 transfer/approval logic.
4.  **Time-Based Mechanics:** Actions like watering, harvesting, creature expeditions, and the global garden update cycle are gated by `block.timestamp`. This introduces time progression as a core game mechanic.
5.  **Pseudo-Random Events:** Creature spawning and expedition outcomes are influenced by a simple, on-chain pseudo-random number generator (`_generatePseudoRandomUint`) using block data and a nonce. This adds variability. *Disclaimer:* This is explicitly noted as *not* cryptographically secure and unsuitable for high-value, adversarial randomness needs, but serves the purpose of simulating randomness for game state in a single contract.
6.  **Batch Operations:** Functions like `batchWaterPlots`, `batchHarvestPlots`, `batchFeedCreatures`, and `batchSendCreaturesOnExpedition` allow users to perform multiple identical actions in a single transaction, saving gas costs compared to individual calls. This is a practical gas optimization technique.
7.  **Minimal Standard Implementation:** We implement only the absolute minimum functions (`ownerOf`, `balanceOf`, `tokenURI`) necessary for external platforms (like wallets or marketplaces) to recognize and display the NFTs. We *do not* implement `transferFrom`, `approve`, `getApproved`, `isApprovedForAll`, or the full event set of the ERC-721 standard libraries (like OpenZeppelin). The *internal* minting/tracking logic is custom (`_plotOwners`, `_plotBalances`, `_ownerPlots` mappings and the `_mintPlot` helper), distinct from standard library implementations. The resource system is even further from standard tokens.
8.  **Simulated Price Feed:** The `essencePricePerEth` and `gemPricePerEthWei` are simple state variables that change based on transaction volume (`depositEtherForEssence`, `withdrawGemsAsEther`). This simulates a basic bonding curve or AMM-like price feedback mechanism entirely within the contract, without relying on external oracles or duplicating complex AMM math.
9.  **Custom Logic:** The core game loops, state transitions, yield calculations, and creature interactions are all custom logic specific to the "Alchemical Garden" concept, not derived from standard DeFi or gaming protocol templates.

This contract provides a rich, interconnected on-chain system with over 30 public/external functions, demonstrating advanced concepts like dynamic state managed directly in the contract, internal economies, and time-based mechanics, while making a genuine effort to build the core logic from scratch rather than inheriting or copying standard open-source implementations beyond the absolute minimum interface compatibility needed for NFTs.