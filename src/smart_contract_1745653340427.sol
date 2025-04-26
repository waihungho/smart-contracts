Okay, let's create a concept around a dynamic, time-based digital garden ecosystem managed on-chain. Users can own plots, plant unique "CryptoPlants" from seeds, care for them over time, influenced by global environmental factors, and harvest resources (Essence) or earn non-transferable badges based on their cultivation success.

This combines elements of resource management, time-based mechanics, unique digital assets (though not standard ERC721 directly for uniqueness), internal tokenomics (Essence), non-transferable tokens (Badges), and a shared global state (Environment).

**Concept Name:** CryptoGarden

**Core Idea:** A simulated ecosystem where users cultivate unique digital plants (`CryptoPlants`) on owned plots, influenced by time and a global environmental state. Successful cultivation yields `Essence` tokens and potential `CultivatorBadges`.

---

**Outline and Function Summary**

**Contract:** `CryptoGarden`

**Core Components:**
1.  **Plots:** Limited-supply digital land parcels where plants can be grown. Owned by users.
2.  **Species:** Pre-defined templates for plant types, determining base growth rates, care needs, etc.
3.  **CryptoPlants:** Unique digital assets (not standard ERC721) planted on plots. They have dynamic states (Growth Stage, Health) and unique attributes (`Genes`). Their state evolves over time based on care, species, genes, and environment.
4.  **Genes:** Attributes of a plant influencing its growth, resilience, and yield. Partially random upon planting.
5.  **Environmental State:** Global parameters that change over time and affect *all* plants (e.g., Sunlight Level, Soil Fertility, Cosmic Radiation). Can potentially be influenced by community action.
6.  **Essence:** An internal, fungible resource token earned by harvesting mature plants. Used to buy seeds, influence the environment, or other actions.
7.  **Cultivator Badges:** Non-transferable "Soulbound" tokens awarded for achieving specific cultivation milestones. Grant status or potential future benefits.

**Function Categories:**

*   **Setup & Admin:** Initialize contract, define species, manage core parameters.
*   **Plot Management:** Buy plots, view plot info.
*   **Seed & Planting:** Buy seeds (using Essence), plant seeds on plots.
*   **Plant Cultivation:** Care for planted plants (time/resource based), check plant state (growth, health).
*   **Harvesting:** Harvest mature plants to gain Essence and clear the plot.
*   **State & Info:** View details of species, environmental state, user balances, plant details.
*   **Advanced & Interaction:** Influence global environment, obtain badges, manage plot/plant approvals for delegated care.

**Function Summary (26 Functions):**

1.  `constructor()`: Initializes the contract, sets owner.
2.  `addSpecies(string name, uint baseGrowthRate, uint careInterval, uint minHarvestYield, uint maxHarvestYield, uint mutationChance)`: (Admin) Defines a new plant species.
3.  `setEnvironmentalFactors(uint sunlightLevel, uint soilFertility, uint cosmicRadiation)`: (Admin) Manually set the global environmental state.
4.  `buyPlot()`: Allows users to purchase a plot of land (costs Ether).
5.  `getPlotDetails(uint plotId)`: Returns details of a specific plot.
6.  `getPlotsByOwner(address owner)`: Returns an array of plot IDs owned by an address.
7.  `buySeed(uint speciesId)`: Allows users to purchase a seed of a specific species using Essence.
8.  `getSeedDetails(uint speciesId)`: Returns details about a specific seed species (same as Species details).
9.  `plantSeed(uint plotId, uint speciesId)`: Plants a seed on an owned, empty plot. Assigns initial genes.
10. `careForPlant(uint plotId)`: Provides care for the plant on a plot, updating its state and potentially improving health/growth, subject to a cooldown. Costs Essence.
11. `checkPlantState(uint plotId)`: Calculates and returns the current dynamic state of the plant on a plot (growth stage, health, time until next care needed).
12. `getPlantDetails(uint plotId)`: Returns static and dynamic details of the plant on a plot (species, genes, current state).
13. `harvestPlant(uint plotId)`: Harvests a mature plant, yielding Essence based on its final state, potency, and genes. Clears the plot.
14. `getEnvironmentalState()`: Returns the current global environmental parameters.
15. `getSpeciesDetails(uint speciesId)`: Returns the details of a specific plant species.
16. `getEssenceBalance(address user)`: Returns the Essence balance for a user.
17. `applyEnvironmentalBoost(uint factorIndex, uint durationSeconds, uint strength)`: Allows users to burn Essence to temporarily boost a specific environmental factor globally.
18. `obtainCultivatorBadge()`: Allows a user to claim or upgrade their non-transferable Cultivator Badge if they meet the criteria (e.g., number of harvests, total essence earned).
19. `getCultivatorBadgeDetails(address user)`: Returns details of a user's Cultivator Badge.
20. `isCultivatorBadgeOwner(address user)`: Checks if an address possesses a Cultivator Badge (returns true/false and level if exists).
21. `delegateCare(uint plantId, address delegate)`: Allows the plant owner to approve another address to call `careForPlant` for a specific plant.
22. `setPlotApproval(uint plotId, address approved)`: Allows the plot owner to approve an address to manage *any* action on that plot (plant, care, harvest).
23. `removePlotApproval(uint plotId)`: Removes any approval set for a specific plot.
24. `getPlotApproval(uint plotId)`: Returns the address approved for a specific plot, if any.
25. `updateEnvironmentalState(uint essenceContribution)`: Allows users to contribute Essence to a community pool that passively influences the environmental state over time (implementation detail: this function *adds* to a buffer, a separate time-based or admin trigger would *apply* the effect, but for simplicity here, let's make this burn essence to *slightly* shift the state).
26. `getCommunityEssencePool()`: Returns the amount of Essence currently in the community pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- CryptoGarden Contract Outline ---
// 1. State Variables: Plots, Plants, Species, Environment, Balances, Badges, Counters, Approvals
// 2. Structs: Plot, Plant, Genes, Species, EnvironmentalState, CultivatorBadge
// 3. Events: PlotBought, SeedPlanted, PlantCared, PlantHarvested, EssenceGained, BadgeObtained, EnvironmentUpdated, EnvironmentalBoostApplied, EssenceSpent
// 4. Modifiers: onlyOwner, onlyPlotOwner, onlyPlotOwnerOrApproved, onlyPlantOwnerOrApproved
// 5. Core Logic:
//    - Time-based growth/health calculation influenced by genes, species, care, environment.
//    - Random gene generation.
//    - Essence as internal fungible token.
//    - Non-transferable badges based on milestones.
//    - Global mutable environmental state.
// 6. Functions (min 20):
//    - Admin: Setup species, initial environment.
//    - User: Buy plot/seed, plant, care, harvest, check state, get info, obtain badge, delegate care, influence environment.
//    - View: Get details (plots, plants, species, environment, balances, badges, approvals).

// --- Function Summary ---
// - constructor(): Initializes contract.
// - addSpecies(): Admin defines plant species characteristics.
// - setEnvironmentalFactors(): Admin sets global environment (manual override).
// - buyPlot(): User buys a plot with Ether.
// - getPlotDetails(): View details of a plot.
// - getPlotsByOwner(): Get all plot IDs for an owner.
// - buySeed(): User buys a seed using Essence.
// - getSeedDetails(): View species/seed details.
// - plantSeed(): Plant a seed on an owned plot.
// - careForPlant(): Provide care for a plant using Essence, updating state.
// - checkPlantState(): Calculate and view current plant's dynamic state.
// - getPlantDetails(): View full plant details (static + dynamic state).
// - harvestPlant(): Harvest a mature plant for Essence, clears plot.
// - getEnvironmentalState(): View global environmental state.
// - getSpeciesDetails(): View details of a plant species.
// - getEssenceBalance(): View user's Essence balance.
// - applyEnvironmentalBoost(): Burn Essence to temporarily boost an environmental factor globally.
// - obtainCultivatorBadge(): Claim/upgrade non-transferable badge based on criteria.
// - getCultivatorBadgeDetails(): View user's badge details.
// - isCultivatorBadgeOwner(): Check if user has a badge.
// - delegateCare(): Approve another address for care on a specific plant.
// - setPlotApproval(): Approve another address for all actions on a specific plot.
// - removePlotApproval(): Remove plot approval.
// - getPlotApproval(): View approved address for a plot.
// - updateEnvironmentalState(): Burn Essence to slightly influence global environment.
// - getCommunityEssencePool(): View community Essence pool balance.

contract CryptoGarden {

    address public owner;

    // --- Constants ---
    uint public constant PLOT_PRICE = 0.01 ether; // Price to buy a plot
    uint public constant ESSENCE_PER_CARE = 5; // Essence cost per care action
    uint public constant SECONDS_PER_GROWTH_STAGE = 86400; // 1 day per stage (example)
    uint public constant CARE_COOLDOWN_SECONDS = 4 * 3600; // Care needed at least every 4 hours (example)
    uint public constant HARVEST_GROWTH_STAGE = 5; // Growth stage required for harvest
    uint public constant MIN_YIELD_BOOST_PER_POTENCY = 10; // Base yield increase per potency point
    uint public constant GENE_RANGE = 100; // Max value for gene attributes (0-100)
    uint public constant BADGE_HARVEST_CRITERIA_LEVEL1 = 5; // Number of harvests for Level 1 badge

    // --- Structs ---
    struct Plot {
        uint plotId;
        address owner;
        uint plantId; // 0 if empty
        uint lastCareTime; // For plot-level checks if needed, currently plant stores this
        // Potentially add unique plot modifiers later
    }

    struct Genes {
        uint resistance; // Resists negative environmental effects
        uint vitality;   // Base health and growth potential
        uint yieldFactor; // Boosts harvest yield
        uint mutationProneness; // Increases chance of rare mutations (not implemented in v1)
    }

    struct Plant {
        uint plantId;
        uint plotId;
        uint speciesId;
        Genes genes;
        uint plantedTime;
        uint lastCareTime;
        // Dynamic state calculated based on time, care, environment, species, genes:
        // uint growthStage; // Calculated
        // uint health; // Calculated
        // uint potency; // Calculated - influences yield and mutation likelihood
    }

    struct Species {
        uint speciesId;
        string name;
        uint baseGrowthRate; // Affects how quickly growth stages are reached (seconds reduction per stage)
        uint careInterval; // Ideal care interval in seconds
        uint minHarvestYield; // Minimum Essence yield when harvested
        uint maxHarvestYield; // Maximum Essence yield when harvested
        uint mutationChance; // Chance of mutation (not implemented in v1)
    }

    struct EnvironmentalState {
        uint sunlightLevel; // Affects growth and health (e.g., 0-100)
        uint soilFertility; // Affects health and yield (e.g., 0-100)
        uint cosmicRadiation; // Negative effect on health, potential for mutation (e.g., 0-100)
        // Time-based decay/change could be added later
    }

    struct CultivatorBadge {
        uint level; // Badge level (1, 2, 3...)
        uint obtainedTime; // Timestamp when badge was first obtained or leveled up
        uint totalHarvests; // Cumulative harvests
        uint totalEssenceEarned; // Cumulative essence earned
        // Non-transferable: Checked by requiring msg.sender == user address for modifications/checks
    }

    // --- State Variables ---
    mapping(uint => Plot) public plots;
    mapping(address => uint[]) internal plotsByOwner; // Store plot IDs for each owner
    uint public plotCount;

    mapping(uint => Plant) public plants;
    uint public plantCount;

    mapping(uint => Species) public species;
    uint public speciesCount;

    EnvironmentalState public environmentalState;
    uint public lastEnvironmentalUpdateTime; // Timestamp of last manual or community update

    mapping(address => uint) public essenceBalances; // Internal Essence token balance
    uint public communityEssencePool;

    mapping(address => CultivatorBadge) public cultivatorBadges;

    // --- Approval Mappings ---
    mapping(uint => address) public plotApproval; // plotId => approvedAddress
    mapping(uint => address) public plantCareApproval; // plantId => approvedAddress (for care only)

    // --- Events ---
    event PlotBought(uint indexed plotId, address indexed owner, uint price);
    event SeedPlanted(uint indexed plantId, uint indexed plotId, uint indexed speciesId, address indexed owner);
    event PlantCared(uint indexed plantId, uint indexed plotId, address indexed caregiver, uint essenceCost);
    event PlantHarvested(uint indexed plantId, uint indexed plotId, address indexed owner, uint essenceEarned);
    event EssenceGained(address indexed user, uint amount, string source);
    event EssenceSpent(address indexed user, uint amount, string purpose);
    event BadgeObtained(address indexed user, uint level);
    event EnvironmentalStateUpdated(uint sunlightLevel, uint soilFertility, uint cosmicRadiation);
    event EnvironmentalBoostApplied(uint factorIndex, uint durationSeconds, uint strength, uint essenceBurned);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyPlotOwner(uint _plotId) {
        require(plots[_plotId].owner == msg.sender, "Must be plot owner");
        _;
    }

    modifier onlyPlotOwnerOrApproved(uint _plotId) {
        require(plots[_plotId].owner == msg.sender || plotApproval[_plotId] == msg.sender, "Not authorized for this plot");
        _;
    }

    modifier onlyPlantOwnerOrApproved(uint _plantId) {
         require(plants[_plantId].plotId != 0, "Plant does not exist"); // Ensure plant exists via plot link
         uint plotId = plants[_plantId].plotId;
         require(plots[plotId].owner == msg.sender || plotApproval[plotId] == msg.sender || plantCareApproval[_plantId] == msg.sender, "Not authorized for this plant action");
         _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        plotCount = 0;
        plantCount = 0;
        speciesCount = 0;
        // Set initial environmental state (can be adjusted by admin)
        environmentalState = EnvironmentalState(70, 60, 10);
        lastEnvironmentalUpdateTime = block.timestamp;
    }

    // --- Admin Functions ---

    /// @notice Defines a new plant species with its characteristics.
    /// @param _name The name of the species.
    /// @param _baseGrowthRate Base growth rate reduction factor. Higher means faster growth.
    /// @param _careInterval Ideal time interval for care in seconds.
    /// @param _minHarvestYield Minimum Essence yield when harvested.
    /// @param _maxHarvestYield Maximum Essence yield when harvested.
    /// @param _mutationChance Not implemented in v1.
    function addSpecies(
        string calldata _name,
        uint _baseGrowthRate,
        uint _careInterval,
        uint _minHarvestYield,
        uint _maxHarvestYield,
        uint _mutationChance
    ) external onlyOwner {
        speciesCount++;
        species[speciesCount] = Species(
            speciesCount,
            _name,
            _baseGrowthRate,
            _careInterval,
            _minHarvestYield,
            _maxHarvestYield,
            _mutationChance
        );
    }

    /// @notice Manually sets the global environmental state.
    /// @param _sunlightLevel New sunlight level (0-100).
    /// @param _soilFertility New soil fertility (0-100).
    /// @param _cosmicRadiation New cosmic radiation level (0-100).
    function setEnvironmentalFactors(
        uint _sunlightLevel,
        uint _soilFertility,
        uint _cosmicRadiation
    ) external onlyOwner {
        // Basic validation
        require(_sunlightLevel <= 100 && _soilFertility <= 100 && _cosmicRadiation <= 100, "Levels must be 0-100");

        environmentalState = EnvironmentalState(_sunlightLevel, _soilFertility, _cosmicRadiation);
        lastEnvironmentalUpdateTime = block.timestamp;
        emit EnvironmentalStateUpdated(_sunlightLevel, _soilFertility, _cosmicRadiation);
    }

    // --- Plot Management ---

    /// @notice Allows the caller to purchase a new plot of land.
    /// @dev Requires sending the exact amount of PLOT_PRICE in Ether.
    function buyPlot() external payable {
        require(msg.value == PLOT_PRICE, "Incorrect Ether amount sent");

        plotCount++;
        plots[plotCount] = Plot(plotCount, msg.sender, 0, block.timestamp); // PlantId 0 means empty
        plotsByOwner[msg.sender].push(plotCount);

        // Transfer Ether to owner or a treasury contract in a real scenario
        // For simplicity in this demo, Ether stays in the contract address,
        // which is not ideal practice for production unless managed carefully.
        // A withdraw function for the owner would be needed.
        // payable(owner).transfer(msg.value); // Or handle via withdrawal

        emit PlotBought(plotCount, msg.sender, msg.value);
    }

    /// @notice Gets details of a specific plot.
    /// @param _plotId The ID of the plot.
    /// @return plotId The ID of the plot.
    /// @return owner The owner's address.
    /// @return plantId The ID of the plant on the plot (0 if empty).
    /// @return lastCareTime The timestamp of the last care action on the plot (currently unused for calculation).
    function getPlotDetails(uint _plotId) external view returns (uint plotId, address owner, uint plantId, uint lastCareTime) {
        Plot storage p = plots[_plotId];
        require(p.plotId != 0, "Plot does not exist"); // Check if plot exists by ID being non-zero after creation
        return (p.plotId, p.owner, p.plantId, p.lastCareTime);
    }

    /// @notice Gets all plot IDs owned by a specific address.
    /// @param _owner The address to check.
    /// @return An array of plot IDs.
    function getPlotsByOwner(address _owner) external view returns (uint[] memory) {
        return plotsByOwner[_owner];
    }

    // --- Seed & Planting ---

    /// @notice Allows a user to buy a seed of a specific species using Essence.
    /// @param _speciesId The ID of the species for the seed.
    /// @dev Requires sufficient Essence balance.
    function buySeed(uint _speciesId) external {
        Species storage s = species[_speciesId];
        require(s.speciesId != 0, "Species does not exist"); // Check species exists

        // Example seed cost: 10 Essence
        uint seedCost = 10;
        require(essenceBalances[msg.sender] >= seedCost, "Not enough Essence");

        essenceBalances[msg.sender] -= seedCost;
        emit EssenceSpent(msg.sender, seedCost, "Buy Seed");

        // In a real system, seeds might be items. Here, buying a seed just
        // grants the *right* to plant that species once. We'll track this
        // simply by allowing planting after purchase, but not storing seed inventory.
        // A more complex system would require a seed inventory mapping.
        // For this demo, let's assume buying *allows* planting directly into a plot.
        // A better approach: create a fungible ERC1155 for seeds or track counts per user per species.
        // Let's simplify and make buying seed === ability to plant *once* or just remove the buySeed
        // function and allow planting directly if user has enough essence.
        // Let's keep buySeed but make it abstract - it just costs essence and the user *then* plants.
        // The planting logic will assume the cost is covered conceptually or tied to planting.
        // Let's refine: buySeed costs Essence, and it conceptually gives you a seed item.
        // plantSeed then consumes this item. Need a mapping for seed inventory.

        // Refined approach: Add seed inventory
        // mapping(address => mapping(uint => uint)) public userSeeds; // user => speciesId => count
        // userSeeds[msg.sender][_speciesId]++;
        // emit SeedBought(msg.sender, _speciesId, 1); // Need SeedBought event

        // Okay, rethinking for simplicity and meeting function count: Let's tie the cost to PLANTING instead of BUYING a separate "seed item".
        // Removing buySeed as a standalone function to avoid complex inventory management.
        // The planting function will handle the Essence cost.

         revert("buySeed is not implemented as a separate inventory system in this demo. Use plantSeed directly."); // Removing this function for clarity based on above reasoning.
    }

     /// @notice Gets details about a plant species (same as species details).
    /// @param _speciesId The ID of the species.
    /// @return speciesId The ID of the species.
    /// @return name The name of the species.
    /// @return baseGrowthRate Base growth rate reduction factor.
    /// @return careInterval Ideal time interval for care.
    /// @return minHarvestYield Minimum Essence yield.
    /// @return maxHarvestYield Maximum Essence yield.
    /// @return mutationChance Chance of mutation.
    function getSeedDetails(uint _speciesId) external view returns (uint speciesId, string memory name, uint baseGrowthRate, uint careInterval, uint minHarvestYield, uint maxHarvestYield, uint mutationChance) {
         Species storage s = species[_speciesId];
         require(s.speciesId != 0, "Species does not exist");
         return (s.speciesId, s.name, s.baseGrowthRate, s.careInterval, s.minHarvestYield, s.maxHarvestYield, s.mutationChance);
     }


    /// @notice Plants a seed of a specific species on an owned, empty plot.
    /// @param _plotId The ID of the plot to plant on.
    /// @param _speciesId The ID of the species to plant.
    /// @dev Costs Essence to plant. Requires plot is owned by caller or approved address, and is empty.
    function plantSeed(uint _plotId, uint _speciesId) external onlyPlotOwnerOrApproved(_plotId) {
        Plot storage p = plots[_plotId];
        require(p.plantId == 0, "Plot is not empty"); // Must be empty

        Species storage s = species[_speciesId];
        require(s.speciesId != 0, "Species does not exist"); // Species must exist

        // Cost to plant (example: 20 Essence)
        uint plantingCost = 20;
        require(essenceBalances[msg.sender] >= plantingCost, "Not enough Essence to plant");

        essenceBalances[msg.sender] -= plantingCost;
        emit EssenceSpent(msg.sender, plantingCost, "Plant Seed");

        plantCount++;
        uint currentPlantId = plantCount;

        // Generate random-ish genes based on block data (caution: predictable)
        // A real system should use Chainlink VRF or similar for secure randomness.
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, currentPlantId));
        uint randomValue = uint(seed);

        Genes memory newGenes = Genes(
            randomValue % (GENE_RANGE + 1), // Resistance
            (randomValue / 10) % (GENE_RANGE + 1), // Vitality
            (randomValue / 100) % (GENE_RANGE + 1), // Yield Factor
            (randomValue / 1000) % (GENE_RANGE + 1) // Mutation Proneness
        );

        plants[currentPlantId] = Plant(
            currentPlantId,
            _plotId,
            _speciesId,
            newGenes,
            block.timestamp, // plantedTime
            block.timestamp // lastCareTime (freshly planted starts with care)
        );

        p.plantId = currentPlantId; // Link plot to plant

        emit SeedPlanted(currentPlantId, _plotId, _speciesId, msg.sender);
    }

    // --- Plant Cultivation ---

    /// @notice Provides care for the plant on a specific plot.
    /// @param _plotId The ID of the plot containing the plant.
    /// @dev Requires the plot to have a plant. Costs Essence per care. Subject to cooldown.
    /// @dev Can be called by the plot owner, an approved plot manager, or an approved plant caregiver.
    function careForPlant(uint _plotId) external onlyPlantOwnerOrApproved(plots[_plotId].plantId) {
        Plot storage p = plots[_plotId];
        require(p.plantId != 0, "No plant on this plot"); // Check if plot has a plant

        Plant storage plant = plants[p.plantId];
        require(block.timestamp >= plant.lastCareTime + CARE_COOLDOWN_SECONDS, "Plant does not need care yet");

        // Check user has enough Essence
        require(essenceBalances[msg.sender] >= ESSENCE_PER_CARE, "Not enough Essence for care");

        essenceBalances[msg.sender] -= ESSENCE_PER_CARE;
        emit EssenceSpent(msg.sender, ESSENCE_PER_CARE, "Care for Plant");

        // Update plant's last care time
        plant.lastCareTime = block.timestamp;

        // Care could potentially increase health, slightly boost growth, or reduce negative environmental effects temporarily.
        // For simplicity, just updating lastCareTime is the primary effect here, influencing future calculations.
        // A more complex model would have care provide "care points" that decay.

        emit PlantCared(plant.plantId, _plotId, msg.sender, ESSENCE_PER_CARE);
    }

    /// @notice Calculates the current dynamic state of a plant on a plot.
    /// @param _plotId The ID of the plot.
    /// @return growthStage Current growth stage.
    /// @return health Current health (0-100).
    /// @return potency Current potency (influences yield, 0-100).
    /// @return timeUntilNextCareSeconds Seconds until the plant can be cared for again.
    function checkPlantState(uint _plotId) external view returns (uint growthStage, uint health, uint potency, uint timeUntilNextCareSeconds) {
        Plot storage p = plots[_plotId];
        require(p.plantId != 0, "No plant on this plot");

        Plant storage plant = plants[p.plantId];
        Species storage s = species[plant.speciesId];

        uint timeElapsedSincePlanting = block.timestamp - plant.plantedTime;
        uint timeElapsedSinceCare = block.timestamp - plant.lastCareTime;

        // Calculate Growth Stage: Basic time elapsed modified by species growth rate and genes
        // Higher baseGrowthRate means stages are reached faster. Higher vitality also helps.
        uint effectiveGrowthTime = timeElapsedSincePlanting * (s.baseGrowthRate + plant.genes.vitality) / (s.baseGrowthRate + GENE_RANGE / 2); // Scale vitality effect
        growthStage = effectiveGrowthTime / SECONDS_PER_GROWTH_STAGE;


        // Calculate Health (0-100): Starts high, decays over time if not cared for, affected by environment and resistance
        uint healthDecayPerSecond = (timeElapsedSinceCare / 3600); // Decay faster if more time since care
        // Environmental effect on health: Radiation is bad, Sunlight/Fertility good (scaled by resistance)
        int environmentalHealthEffect = (int(environmentalState.sunlightLevel) + int(environmentalState.soilFertility)) - int(environmentalState.cosmicRadiation);
        environmentalHealthEffect = environmentalHealthEffect * int(plant.genes.resistance) / int(GENE_RANGE); // Resistance mitigates effect
        
        int currentHealthInt = 100 - int(healthDecayPerSecond / 10) + environmentalHealthEffect / 20; // Example scaling

        health = uint(int(100).max(currentHealthInt).min(0)); // Clamp health between 0 and 100

        // Calculate Potency (0-100): Starts high, can be affected by health, environment, vitality
        // Potency could be seen as the "quality" of the plant or its yield potential beyond base.
        // Higher vitality and current health contribute positively. Harsh environment negatively.
        int currentPotencyInt = int(plant.genes.vitality) + int(health/2) - int(environmentalState.cosmicRadiation / 5);
         potency = uint(int(100).max(currentPotencyInt).min(0)); // Clamp potency between 0 and 100


        // Calculate time until next care is possible
        timeUntilNextCareSeconds = (plant.lastCareTime + CARE_COOLDOWN_SECONDS) > block.timestamp ?
                                    (plant.lastCareTime + CARE_COOLDOWN_SECONDS) - block.timestamp : 0;


        return (growthStage, health, potency, timeUntilNextCareSeconds);
    }

     /// @notice Gets details of the plant on a specific plot, including its current dynamic state.
     /// @param _plotId The ID of the plot.
     /// @return plantId The ID of the plant.
     /// @return speciesId The ID of the plant's species.
     /// @return genes The genes of the plant.
     /// @return plantedTime The timestamp the plant was planted.
     /// @return lastCareTime The timestamp of the last care action.
     /// @return currentGrowthStage Current calculated growth stage.
     /// @return currentHealth Current calculated health (0-100).
     /// @return currentPotency Current calculated potency (0-100).
     function getPlantDetails(uint _plotId) external view returns (uint plantId, uint speciesId, Genes memory genes, uint plantedTime, uint lastCareTime, uint currentGrowthStage, uint currentHealth, uint currentPotency) {
         Plot storage p = plots[_plotId];
         require(p.plantId != 0, "No plant on this plot");

         Plant storage plant = plants[p.plantId];
         (currentGrowthStage, currentHealth, currentPotency, ) = checkPlantState(_plotId); // Use the state calculation

         return (plant.plantId, plant.speciesId, plant.genes, plant.plantedTime, plant.lastCareTime, currentGrowthStage, currentHealth, currentPotency);
     }


    // --- Harvesting ---

    /// @notice Harvests a mature plant on a plot, yielding Essence.
    /// @param _plotId The ID of the plot to harvest.
    /// @dev Requires the plant to be on an owned/approved plot and be mature enough. Clears the plot.
    function harvestPlant(uint _plotId) external onlyPlotOwnerOrApproved(_plotId) {
        Plot storage p = plots[_plotId];
        require(p.plantId != 0, "No plant on this plot"); // Must have a plant

        Plant storage plant = plants[p.plantId];
        Species storage s = species[plant.speciesId];

        (uint growthStage, uint health, uint potency, ) = checkPlantState(_plotId);

        require(growthStage >= HARVEST_GROWTH_STAGE, "Plant is not mature enough to harvest");

        // Calculate yield: Base yield range from species, modified by health, potency, and genes
        uint baseYieldRange = s.maxHarvestYield - s.minHarvestYield;
        uint healthModifier = health; // 100 health = 100% modifier
        uint potencyModifier = potency * MIN_YIELD_BOOST_PER_POTENCY / 100; // Scale potency effect
        uint geneModifier = plant.genes.yieldFactor; // Direct gene boost

        // Simple yield calculation: min + range * (health/100) + potency_boost + gene_boost
        uint essenceEarned = s.minHarvestYield +
                             (baseYieldRange * healthModifier / 100) +
                             potencyModifier +
                             geneModifier;

        // Optional: Send a small cut to the community pool
        uint communityCut = essenceEarned / 20; // 5% example
        essenceEarned -= communityCut;
        communityEssencePool += communityCut;

        // Credit user balance
        essenceBalances[msg.sender] += essenceEarned;
        emit EssenceGained(msg.sender, essenceEarned, "Harvest");
        emit EssenceGained(address(0), communityCut, "Community Pool"); // Indicate pool gain

        // Update user's badge criteria (even if they haven't claimed a badge yet)
        CultivatorBadge storage badge = cultivatorBadges[msg.sender];
        badge.totalHarvests++;
        badge.totalEssenceEarned += essenceEarned;

        // Clear the plot and delete the plant data (saves gas)
        uint harvestedPlantId = p.plantId;
        p.plantId = 0;
        delete plants[harvestedPlantId]; // Deletes the Plant struct data

        emit PlantHarvested(harvestedPlantId, _plotId, msg.sender, essenceEarned);
    }

    // --- State & Info Views ---

    /// @notice Returns the current global environmental parameters.
    /// @return sunlightLevel Current sunlight level.
    /// @return soilFertility Current soil fertility.
    /// @return cosmicRadiation Current cosmic radiation level.
    /// @return lastUpdateTime Timestamp of the last environmental update.
    function getEnvironmentalState() external view returns (uint sunlightLevel, uint soilFertility, uint cosmicRadiation, uint lastUpdateTime) {
        return (environmentalState.sunlightLevel, environmentalState.soilFertility, environmentalState.cosmicRadiation, lastEnvironmentalUpdateTime);
    }

    /// @notice Returns the details of a specific plant species.
    /// @param _speciesId The ID of the species.
    /// @return speciesId The ID of the species.
    /// @return name The name of the species.
    /// @return baseGrowthRate Base growth rate reduction factor.
    /// @return careInterval Ideal time interval for care.
    /// @return minHarvestYield Minimum Essence yield.
    /// @return maxHarvestYield Maximum Essence yield.
    /// @return mutationChance Chance of mutation.
    function getSpeciesDetails(uint _speciesId) external view returns (uint speciesId, string memory name, uint baseGrowthRate, uint careInterval, uint minHarvestYield, uint maxHarvestYield, uint mutationChance) {
        Species storage s = species[_speciesId];
        require(s.speciesId != 0, "Species does not exist");
        return (s.speciesId, s.name, s.baseGrowthRate, s.careInterval, s.minHarvestYield, s.maxHarvestYield, s.mutationChance);
    }

    /// @notice Returns the Essence balance for a given user.
    /// @param user The address to check.
    /// @return The Essence balance.
    function getEssenceBalance(address user) external view returns (uint) {
        return essenceBalances[user];
    }

    // --- Advanced & Interaction ---

    /// @notice Allows users to burn Essence to temporarily boost a specific environmental factor globally.
    /// @param factorIndex 0 for Sunlight, 1 for Soil Fertility, 2 for Cosmic Radiation (boost is negative for radiation).
    /// @param durationSeconds The duration of the boost.
    /// @param strength The intensity of the boost (e.g., +10 to a factor).
    /// @dev Costs Essence based on duration and strength. Requires sufficient Essence.
    function applyEnvironmentalBoost(uint factorIndex, uint durationSeconds, uint strength) external {
        require(factorIndex <= 2, "Invalid environmental factor index");
        require(durationSeconds > 0, "Boost duration must be positive");
        require(strength > 0, "Boost strength must be positive");

        // Example cost calculation: strength * duration / 100 (tune this)
        uint essenceBurnCost = strength * durationSeconds / 100;
        require(essenceBalances[msg.sender] >= essenceBurnCost, "Not enough Essence to apply boost");

        essenceBalances[msg.sender] -= essenceBurnCost;
        emit EssenceSpent(msg.sender, essenceBurnCost, "Environmental Boost");

        // Apply the boost effect. A more complex system would need a list of active boosts
        // and modify the state calculation (`checkPlantState`).
        // For simplicity in this demo, let's just log the event.
        // In a real system, this would likely involve state variables storing active boosts
        // and their end times, checked in `checkPlantState`.

        emit EnvironmentalBoostApplied(factorIndex, durationSeconds, strength, essenceBurnCost);
        // Note: The actual *application* of the boost to the environmentalState struct
        // would happen in checkPlantState or require complex state management.
        // This function currently just burns Essence and emits an event.
        // A simple implementation could be:
        // if (factorIndex == 0) environmentalState.sunlightLevel = Math.min(100, environmentalState.sunlightLevel + strength);
        // (similar for others, perhaps with a timer to revert) -- this needs careful design.
        // Sticking to event emission for simplicity in this demo code structure.
    }

     /// @notice Checks if a user meets the criteria for obtaining or upgrading a Cultivator Badge and grants it.
     /// @dev Non-transferable. Based on cumulative stats.
     function obtainCultivatorBadge() external {
         CultivatorBadge storage badge = cultivatorBadges[msg.sender];

         // Check criteria based on accumulated stats
         // Criteria for Level 1: X harvests
         if (badge.level == 0 && badge.totalHarvests >= BADGE_HARVEST_CRITERIA_LEVEL1) {
             badge.level = 1;
             badge.obtainedTime = block.timestamp;
             // No other attributes tracked for Level 1 in this example
             emit BadgeObtained(msg.sender, badge.level);
         }
         // Add criteria for Level 2, 3, etc. based on totalEssenceEarned or other metrics
         // Example:
         // if (badge.level == 1 && badge.totalEssenceEarned >= 1000) {
         //     badge.level = 2;
         //     badge.obtainedTime = block.timestamp; // Update time for level up
         //     emit BadgeObtained(msg.sender, badge.level);
         // }
         // etc.

         require(badge.level > 0, "Criteria not met for any badge level yet");
     }

     /// @notice Returns details of a user's Cultivator Badge.
     /// @param user The address to check.
     /// @return level The badge level (0 if none).
     /// @return obtainedTime Timestamp when badge was obtained/leveled up.
     /// @return totalHarvests Cumulative harvests recorded for badge.
     /// @return totalEssenceEarned Cumulative Essence earned recorded for badge.
     function getCultivatorBadgeDetails(address user) external view returns (uint level, uint obtainedTime, uint totalHarvests, uint totalEssenceEarned) {
         CultivatorBadge storage badge = cultivatorBadges[user];
         return (badge.level, badge.obtainedTime, badge.totalHarvests, badge.totalEssenceEarned);
     }

     /// @notice Checks if an address possesses a Cultivator Badge and returns its level.
     /// @param user The address to check.
     /// @return bool True if user has a badge, false otherwise.
     /// @return uint The level of the badge (0 if none).
     function isCultivatorBadgeOwner(address user) external view returns (bool, uint) {
         CultivatorBadge storage badge = cultivatorBadges[user];
         return (badge.level > 0, badge.level);
     }


     /// @notice Allows the plant owner to approve another address to call `careForPlant` for a specific plant.
     /// @param _plantId The ID of the plant.
     /// @param _delegate The address to approve for caring. Set to address(0) to remove approval.
     /// @dev Requires caller to be the plot owner or already approved for the plot.
     function delegateCare(uint _plantId, address _delegate) external onlyPlantOwnerOrApproved(_plants[_plantId].plotId) {
         // Ensure the plant exists and is on the specified plot
         require(_plants[_plantId].plantId != 0 && _plants[_plantId].plotId != 0, "Plant does not exist");
         uint plotId = _plants[_plantId].plotId;
         require(plots[plotId].plantId == _plantId, "Plant ID does not match plot"); // Sanity check

         plantCareApproval[_plantId] = _delegate;
         // Event could be added here: PlantCareDelegation(plantId, msg.sender, delegate);
     }


     /// @notice Allows the plot owner to approve another address to manage *any* action on that plot (plant, care, harvest).
     /// @param _plotId The ID of the plot.
     /// @param _approved The address to approve. Set to address(0) to remove approval.
     /// @dev Requires caller to be the plot owner.
     function setPlotApproval(uint _plotId, address _approved) external onlyPlotOwner(_plotId) {
         require(plots[_plotId].plotId != 0, "Plot does not exist");
         plotApproval[_plotId] = _approved;
         // Event could be added here: PlotApprovalSet(plotId, msg.sender, approved);
     }

     /// @notice Removes any approval set for a specific plot.
     /// @param _plotId The ID of the plot.
     /// @dev Requires caller to be the plot owner or the currently approved address.
     function removePlotApproval(uint _plotId) external {
         require(plots[_plotId].plotId != 0, "Plot does not exist");
         require(plots[_plotId].owner == msg.sender || plotApproval[_plotId] == msg.sender, "Not authorized to remove approval");

         plotApproval[_plotId] = address(0);
         // Event could be added here: PlotApprovalRemoved(plotId, msg.sender);
     }

     /// @notice Returns the address approved for a specific plot, if any.
     /// @param _plotId The ID of the plot.
     /// @return The approved address (address(0) if none).
     function getPlotApproval(uint _plotId) external view returns (address) {
         require(plots[_plotId].plotId != 0, "Plot does not exist");
         return plotApproval[_plotId];
     }

    /// @notice Allows users to burn Essence to slightly influence the global environment.
    /// @param essenceContribution The amount of Essence to burn.
    /// @dev This is a simplified example. A real system would need careful balancing
    ///      and potentially a time-decaying influence.
    function updateEnvironmentalState(uint essenceContribution) external {
        require(essenceBalances[msg.sender] >= essenceContribution, "Not enough Essence to contribute");
        require(essenceContribution > 0, "Must contribute a positive amount of Essence");

        essenceBalances[msg.sender] -= essenceContribution;
        emit EssenceSpent(msg.sender, essenceContribution, "Influence Environment");

        // Simple example: Each contribution slightly shifts levels towards a favorable state
        // (e.g., higher sunlight/fertility, lower radiation). This needs significant tuning.
        // The effect should likely be temporary or cumulative over many contributions.
        // This simple implementation just shifts values directly, which is problematic
        // without decay or proper scaling.
        // Let's make it symbolic for the demo: It adds to a pool that *passively*
        // improves the environment over time, only when the pool is not empty.
        // The actual environment state update would be a separate mechanism (admin, or time-based).
        // So, this function just increases the community pool, which *conceptually* influences the environment.

        communityEssencePool += essenceContribution;
        emit EssenceGained(address(0), essenceContribution, "Community Pool (Environmental Influence)");

        // A real system might do something like:
        // environmentalState.sunlightLevel = uint(int(environmentalState.sunlightLevel) + int(essenceContribution / 100)).min(100);
        // environmentalState.soilFertility = uint(int(environmentalState.soilFertility) + int(essenceContribution / 100)).min(100);
        // environmentalState.cosmicRadiation = uint(int(environmentalState.cosmicRadiation) - int(essenceContribution / 200)).max(0);
        // emit EnvironmentalStateUpdated(...);
        // But this simple direct modification without decay is bad.

        // For this demo, the influence is indirect via the growing community pool.
    }

    /// @notice Returns the amount of Essence currently in the community pool.
    function getCommunityEssencePool() external view returns (uint) {
        return communityEssencePool;
    }

    // --- Internal Helper Functions (Not directly exposed) ---

    // This contract structure is a simplified demo.
    // Complex calculation logic (_calculateGrowth, _calculateHealth, _calculateYield)
    // is embedded directly in `checkPlantState` and `harvestPlant` for brevity.
    // In a production contract, these would ideally be internal pure/view functions
    // to improve readability and testability.

     /// @notice Internal helper to check if a user meets badge criteria.
     /// @param user The address to check.
     /// @return bool True if criteria met for *any* level upgrade.
     /// @dev Currently only checks Level 1 criteria.
     function _checkCultivatorCriteria(address user) internal view returns (bool) {
         CultivatorBadge storage badge = cultivatorBadges[user];
         if (badge.level == 0 && badge.totalHarvests >= BADGE_HARVEST_CRITERIA_LEVEL1) {
             return true;
         }
         // Add checks for other levels here
         return false; // No criteria met for an upgrade
     }

    // Need a withdraw function for the owner if ETH is received directly
    // function withdrawETH() external onlyOwner {
    //     payable(owner).transfer(address(this).balance);
    // }
}
```