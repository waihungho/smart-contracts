Okay, let's design a smart contract that represents a generative, dynamic NFT ecosystem with elements of resource production, environmental factors, staking, and timed events. We'll call it "Generative NFT Kingdom".

The core idea is that NFTs (`Plot` tokens) are generated with unique traits (Biome, Rarity, Initial Resources) determined pseudo-randomly on-chain. These plots can then produce a virtual resource (`Essence`) over time. The production rate is influenced by the plot's traits, its environmental state (Pollution), whether it's staked, and global "Seasons". Owners can interact with their plots by harvesting resources, staking them, developing them (spending Essence to improve stats), or mitigating pollution. Seasons change over time, affecting the entire kingdom. Plots can potentially "mutate" under specific conditions.

This design incorporates:
1.  **Generative Traits:** Properties determined at minting via on-chain pseudo-randomness.
2.  **Dynamic NFTs:** Plot state (Resources, Pollution, Staked Status) changes over time and via user interaction.
3.  **Time-Based Mechanics:** Resource growth, pollution increase, season changes are time-dependent.
4.  **Resource Management:** A virtual resource (`Essence`) is produced and consumed within the ecosystem.
5.  **Staking:** Lock NFTs to potentially gain benefits (e.g., boosted production).
6.  **Environmental Factors:** Pollution and Seasons impact gameplay.
7.  **Potential Mutation:** Rare events can permanently change NFT traits.

It avoids direct duplication of standard ERC721 extensions like marketplaces, simple staking vaults, or basic generative art collections by integrating these complex mechanics within a single, interactive ecosystem contract.

---

**Outline & Function Summary**

**Contract:** `GenerativeNFTKingdom`

**Inherits:** ERC721, Ownable, Pausable

**Core Concepts:**
*   NFTs represent "Plots" of land.
*   Plots have generative, dynamic, and static properties.
*   Plots produce `Essence` over time.
*   Gameplay involves harvesting, staking, developing, and mitigating pollution.
*   Global "Seasons" affect gameplay mechanics.
*   Plots can potentially mutate.
*   An internal `Essence` balance is tracked for owners to use within the ecosystem (development, mitigation).

**State Variables:**
*   Plot data mapping (`plotData`).
*   Mapping for owner's claimable `Essence`.
*   Global parameters (Season, Season duration, growth rates, pollution effects, development costs, mutation chances, staking duration).
*   Counters for seasons and total supply.

**Events:**
*   `PlotMinted`: When a new plot is generated.
*   `ResourcesHarvested`: When `Essence` is harvested from a plot.
*   `PlotStaked`: When a plot is staked.
*   `PlotUnstaked`: When a plot is unstaked.
*   `PlotDeveloped`: When a plot is developed.
*   `PollutionMitigated`: When pollution on a plot is reduced.
*   `SeasonChanged`: When the season advances.
*   `PlotMutated`: When a plot's properties change permanently.
*   `EssenceClaimed`: When an owner claims their total claimable Essence.

**Modifiers:**
*   `onlyPlotOwner`: Ensures caller owns the specified plot.
*   `onlyAdminOrSeasonTime`: Restricts `triggerSeasonChange`.

**ERC721 Implementation:** (Standard functions inherited/overridden)
*   `_beforeTokenTransfer`: Hook to update internal plot state mappings on transfer.

**Admin Functions:** (Restricted via `onlyOwner`)
1.  `setBaseURI`: Set metadata base URI.
2.  `pause`: Pause sensitive actions.
3.  `unpause`: Unpause actions.
4.  `withdrawEther`: Withdraw any collected ETH (e.g., from mint fees, although not implemented in this draft).
5.  `setMinStakeDuration`: Set minimum time a plot must be staked.
6.  `setSeasonDuration`: Set the duration of each season in seconds.
7.  `setBiomeGenerationWeights`: Set probability weights for biome generation.
8.  `setResourceGrowthRates`: Set base resource growth rates per biome/rarity.
9.  `setPollutionEffects`: Set how pollution impacts growth and mutation chance.
10. `setDevelopmentCosts`: Set Essence costs for plot development actions.
11. `setMutationChanceParameters`: Set parameters for mutation chance calculation.
12. `setSeasonGrowthModifiers`: Set multipliers for resource growth during different seasons.

**Core Gameplay & Plot Management:**
13. `mintPlot`: Creates a new NFT with pseudo-randomly generated properties (Biome, Rarity, Initial Resources). Requires payment or is free based on contract config (design choice, here it's free for simplicity).
14. `harvestResources`: Calculates accumulated `Essence` on a specific plot since the last harvest, adds it to the plot's unharvested balance, and updates the last harvest timestamp.
15. `claimPlotEssence`: Moves `Essence` harvested on a *specific plot* from the plot's unharvested balance to the owner's global claimable balance.
16. `stakePlot`: Marks a plot as staked and records the staking start time.
17. `unstakePlot`: Marks a plot as unstaked. May enforce a minimum stake duration and/or calculate staking bonuses (bonus integrated into growth calculation for simplicity).
18. `developPlot`: Allows the owner to spend claimed `Essence` to permanently improve a plot's attributes (e.g., reduce pollution sensitivity, increase base growth). Requires sufficient claimed `Essence`.
19. `mitigatePollution`: Allows the owner to spend claimed `Essence` to reduce the current pollution level on a plot. Requires sufficient claimed `Essence`.
20. `triggerSeasonChange`: Advances the global season counter if the season duration has passed. Applies global season effects and can trigger checks for plot mutations.

**Resource Claiming:**
21. `claimTotalEssence`: Allows an owner to claim all `Essence` they have moved to their global claimable balance from all their plots. (Note: In a real scenario, this Essence would likely be minted into an ERC20 token here).

**View Functions:**
22. `getPlotDetails`: Returns all storable data for a specific plot ID.
23. `checkPlotGrowth`: Calculates the amount of `Essence` a plot has accumulated since its `lastHarvestTime` without harvesting it.
24. `getClaimableEssence`: Returns the total `Essence` balance an owner has moved to their global claimable balance, ready to be claimed (function 21).
25. `calculateEcosystemHealth`: A conceptual view function (potentially gas-heavy for many plots) that could calculate a health score based on average pollution, resource levels, etc. (Simplified implementation here).
26. `getCurrentSeason`: Returns the current global season.
27. `simulateMutationCheck`: Allows viewing the *likelihood* of a specific plot mutating under current conditions without triggering it.

**Standard ERC721 View Functions:**
28. `balanceOf`: Returns number of plots owned by an address.
29. `ownerOf`: Returns owner of a plot.
30. `getApproved`: Returns approved address for a plot.
31. `isApprovedForAll`: Returns if an operator is approved for an owner.
32. `supportsInterface`: Standard ERC165.

*(Note: This list already exceeds 20 custom and standard functions)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline & Function Summary Above

contract GenerativeNFTKingdom is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Enums ---
    enum Biome { Forest, Desert, Aquatic, Mountain, Swamp }
    enum Rarity { Common, Uncommon, Rare, Epic, Legendary }
    enum Season { Spring, Summer, Autumn, Winter }

    // --- Structs ---
    struct PlotData {
        Biome biome;
        Rarity rarity;
        uint256 generationSeed; // Seed used for initial property generation
        uint256 initialResources; // Base resources generated at mint
        uint256 pollutionLevel; // 0-100 scale
        uint256 developedLevel; // Level of development, impacts stats
        uint256 lastHarvestTime; // Timestamp of last harvest or mint
        uint256 unharvestedEssence; // Essence accumulated on the plot since last harvest
        bool isStaked;
        uint256 stakeStartTime; // Timestamp when staked
    }

    struct PlotParameters {
        uint16 biomeWeightsForest; // Weights for pseudo-random generation (sum should be 10000)
        uint16 biomeWeightsDesert;
        uint16 biomeWeightsAquatic;
        uint16 biomeWeightsMountain;
        uint16 biomeWeightsSwamp;

        uint256 baseGrowthRatePerTick; // Base essence per unit of time (e.g., second)
        uint256 rarityGrowthMultiplierUncommon; // Multiplier for Uncommon plots
        uint256 rarityGrowthMultiplierRare;
        uint256 rarityGrowthMultiplierEpic;
        uint256 rarityGrowthMultiplierLegendary;
        uint256 biomeGrowthModifierForest; // Modifier for specific biomes (add/subtract from base)
        uint256 biomeGrowthModifierDesert;
        uint256 biomeGrowthModifierAquatic;
        uint256 biomeGrowthModifierMountain;
        uint256 biomeGrowthModifierSwamp;
        uint256 stakedGrowthBonus; // Bonus multiplier when staked
        uint256 pollutionGrowthPenaltyFactor; // Factor by which pollution reduces growth

        uint256 developmentCostEssence; // Cost to develop a plot
        uint256 developmentGrowthBoost; // Boost applied per development level
        uint256 mitigatePollutionCostEssence; // Cost to reduce pollution
        uint256 mitigatePollutionAmount; // Amount pollution is reduced by
        uint256 passivePollutionIncreasePerTick; // Pollution increase per unit of time if not mitigated/developed

        uint256 mutationChanceBase; // Base chance (e.g., per season)
        uint256 mutationChancePollutionFactor; // How pollution increases mutation chance
        uint256 mutationChanceStakedBonus; // Bonus chance when staked
        uint256 mutationEffectMinRarityChange; // Min rarity change on mutation
        uint256 mutationEffectMaxRarityChange; // Max rarity change on mutation

        uint256 minStakeDuration; // Minimum time plots must be staked (in seconds)
        uint256 seasonDuration; // Duration of each season (in seconds)
        uint256 lastSeasonChangeTime; // Timestamp of the last season change
    }

    // --- State Variables ---
    mapping(uint256 => PlotData) public plotData; // Token ID to PlotData
    mapping(address => uint256) public claimableEssence; // Owner address to total Essence claimable

    PlotParameters public plotParameters;
    Season public currentSeason;

    // --- Events ---
    event PlotMinted(uint256 indexed tokenId, address indexed owner, Biome biome, Rarity rarity, uint256 initialResources);
    event ResourcesHarvested(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event PlotStaked(uint256 indexed tokenId, address indexed owner, uint256 stakeTime);
    event PlotUnstaked(uint256 indexed tokenId, address indexed owner, uint256 unstakeTime);
    event PlotDeveloped(uint256 indexed tokenId, address indexed owner, uint256 newDevelopedLevel);
    event PollutionMitigated(uint256 indexed tokenId, address indexed owner, uint256 newPollutionLevel);
    event SeasonChanged(Season indexed newSeason, uint256 seasonNumber);
    event PlotMutated(uint256 indexed tokenId, Biome oldBiome, Biome newBiome, Rarity oldRarity, Rarity newRarity);
    event EssenceClaimed(address indexed owner, uint256 amount);

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        // Set initial default parameters - THESE SHOULD BE CAREFULLY CONFIGURED
        plotParameters = PlotParameters({
            biomeWeightsForest: 2500,
            biomeWeightsDesert: 2000,
            biomeWeightsAquatic: 2000,
            biomeWeightsMountain: 2000,
            biomeWeightsSwamp: 1500, // Total 10000

            baseGrowthRatePerTick: 1e10, // 10 Gwei per second (example unit)
            rarityGrowthMultiplierUncommon: 110, // 110%
            rarityGrowthMultiplierRare: 130,
            rarityGrowthMultiplierEpic: 160,
            rarityGrowthMultiplierLegendary: 200,
            biomeGrowthModifierForest: 1e9, // Add 1 Gwei/sec
            biomeGrowthModifierDesert: 0,
            biomeGrowthModifierAquatic: 5e8, // Add 0.5 Gwei/sec
            biomeGrowthModifierMountain: 0,
            biomeGrowthModifierSwamp: -5e8, // Subtract 0.5 Gwei/sec
            stakedGrowthBonus: 125, // 125% (multiplied by base rate)
            pollutionGrowthPenaltyFactor: 1e16, // Example: pollution * factor = deduction (100 pollution * 1e16 = 1e18 or 1 unit reduction per tick)

            developmentCostEssence: 1e18, // 1 Essence token (example)
            developmentGrowthBoost: 2e9, // Add 2 Gwei/sec per level
            mitigatePollutionCostEssence: 5e17, // 0.5 Essence
            mitigatePollutionAmount: 20, // Reduce pollution by 20
            passivePollutionIncreasePerTick: 10, // Increase pollution by 10 units per day (example: 10 / 86400 per second) -> adjust units accordingly, let's use larger ticks or redefine unit

            mutationChanceBase: 10, // 0.1% chance
            mutationChancePollutionFactor: 5, // Adds 0.05% per pollution point
            mutationChanceStakedBonus: 20, // Adds 0.2% when staked
            mutationEffectMinRarityChange: 0, // Can change rarity by 0 to +2 levels
            mutationEffectMaxRarityChange: 2,

            minStakeDuration: 7 days, // 7 days
            seasonDuration: 30 days, // 30 days
            lastSeasonChangeTime: block.timestamp // Start season 0 now
        });
        currentSeason = Season.Spring;
    }

    // --- Modifiers ---
    modifier onlyPlotOwner(uint256 tokenId) {
        require(_exists(tokenId), "Plot does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not plot owner");
        _;
    }

     modifier onlyAdminOrSeasonTime() {
        require(owner() == msg.sender || block.timestamp >= plotParameters.lastSeasonChangeTime + plotParameters.seasonDuration,
            "Not admin or season duration not passed");
        _;
    }

    // --- ERC721 Overrides ---
    // _beforeTokenTransfer is a useful hook to manage associated data
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If transferring a staked plot, unstake it first
        if (from != address(0) && to != from) {
             if (plotData[tokenId].isStaked) {
                 // Auto-unstake on transfer
                 // Note: This could be a penalty - losing staking time/bonus
                 // For simplicity here, just unstake without penalty calculation on transfer
                 plotData[tokenId].isStaked = false;
                 plotData[tokenId].stakeStartTime = 0;
                 emit PlotUnstaked(tokenId, from, block.timestamp);
             }
             // Ensure unharvested essence is zeroed or transferred to owner's claimable balance
             // Simple: Add to sender's claimable balance
             if(plotData[tokenId].unharvestedEssence > 0) {
                 claimableEssence[from] = claimableEssence[from].add(plotData[tokenId].unharvestedEssence);
                 plotData[tokenId].unharvestedEssence = 0; // Reset plot's unharvested
                 // No explicit event here, happens implicitly before transfer
             }
             // Note: Pollution and Development levels persist with the plot
        }
    }

    // --- Admin Functions (12) ---
    // 1. setBaseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    // 2. pause
    function pause() public onlyOwner {
        _pause();
    }

    // 3. unpause
    function unpause() public onlyOwner {
        _unpause();
    }

    // 4. withdrawEther (Example, assuming ETH could be sent for minting or other reasons)
    function withdrawEther(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether balance");
        (bool success, ) = to.call{value: balance}("");
        require(success, "Ether withdrawal failed");
    }

    // 5. setMinStakeDuration
    function setMinStakeDuration(uint256 duration) public onlyOwner {
        plotParameters.minStakeDuration = duration;
    }

    // 6. setSeasonDuration
    function setSeasonDuration(uint256 duration) public onlyOwner {
        plotParameters.seasonDuration = duration;
    }

    // 7. setBiomeGenerationWeights (Requires weights summing to 10000)
    function setBiomeGenerationWeights(uint16 forest, uint16 desert, uint16 aquatic, uint16 mountain, uint16 swamp) public onlyOwner {
        require(forest + desert + aquatic + mountain + swamp == 10000, "Weights must sum to 10000");
        plotParameters.biomeWeightsForest = forest;
        plotParameters.biomeWeightsDesert = desert;
        plotParameters.biomeWeightsAquatic = aquatic;
        plotParameters.biomeWeightsMountain = mountain;
        plotParameters.biomeWeightsSwamp = swamp;
    }

    // 8. setResourceGrowthRates
    function setResourceGrowthRates(
        uint256 baseRate,
        uint256 rarityUncommon, uint256 rarityRare, uint256 rarityEpic, uint256 rarityLegendary, // Multipliers (e.g., 110 for 110%)
        int256 biomeForest, int256 biomeDesert, int256 biomeAquatic, int256 biomeMountain, int256 biomeSwamp, // Modifiers (signed)
        uint256 stakedBonus, // Multiplier
        uint256 pollutionPenaltyFactor // Factor
    ) public onlyOwner {
        require(rarityUncommon >= 100 && rarityRare >= 100 && rarityEpic >= 100 && rarityLegendary >= 100, "Rarity multipliers must be >= 100%");
        require(stakedBonus >= 100, "Staked bonus must be >= 100%");

        plotParameters.baseGrowthRatePerTick = baseRate;
        plotParameters.rarityGrowthMultiplierUncommon = rarityUncommon;
        plotParameters.rarityGrowthMultiplierRare = rarityRare;
        plotParameters.rarityGrowthMultiplierEpic = rarityEpic;
        plotParameters.rarityGrowthMultiplierLegendary = rarityLegendary;
        plotParameters.biomeGrowthModifierForest = uint256(int256(0).add(biomeForest)); // Convert signed to unsigned safely
        plotParameters.biomeGrowthModifierDesert = uint256(int256(0).add(biomeDesert));
        plotParameters.biomeGrowthModifierAquatic = uint256(int256(0).add(biomeAquatic));
        plotParameters.biomeGrowthModifierMountain = uint256(int256(0).add(biomeMountain));
        plotParameters.biomeGrowthModifierSwamp = uint256(int256(0).add(biomeSwamp));
        plotParameters.stakedGrowthBonus = stakedBonus;
        plotParameters.pollutionGrowthPenaltyFactor = pollutionPenaltyFactor;
    }

    // 9. setPollutionEffects
    function setPollutionEffects(uint256 passiveIncreasePerTick, uint26 pollutionPenaltyFactor) public onlyOwner {
        plotParameters.passivePollutionIncreasePerTick = passiveIncreasePerTick;
        // plotParameters.pollutionGrowthPenaltyFactor is already in setResourceGrowthRates, avoid redundancy
        // Let's add mutation effect factor here too
        plotParameters.mutationChancePollutionFactor = pollutionPenaltyFactor; // Assuming this is the factor for chance
    }

    // 10. setDevelopmentCosts
    function setDevelopmentCosts(uint256 costEssence, uint256 growthBoost) public onlyOwner {
        plotParameters.developmentCostEssence = costEssence;
        plotParameters.developmentGrowthBoost = growthBoost;
    }

    // 11. setMutationChanceParameters
    function setMutationChanceParameters(
        uint256 baseChance, // per 10000, e.g. 10 for 0.1%
        uint256 pollutionFactor, // per 10000 per pollution point, e.g. 5 for 0.05% increase per pollution
        uint256 stakedBonus, // per 10000, e.g. 20 for 0.2% bonus
        uint26 minRarityChange, uint26 maxRarityChange
    ) public onlyOwner {
        plotParameters.mutationChanceBase = baseChance;
        plotParameters.mutationChancePollutionFactor = pollutionFactor;
        plotParameters.mutationChanceStakedBonus = stakedBonus;
        require(maxRarityChange < 5, "Max rarity change cannot exceed rarity enum size"); // Max 4 levels up
        plotParameters.mutationEffectMinRarityChange = minRarityChange;
        plotParameters.mutationEffectMaxRarityChange = maxRarityChange;
    }

    // 12. setSeasonGrowthModifiers (Example: Multipliers for growth rate during seasons)
    // Stored separately or integrated into param struct. Let's add multipliers to the struct
    struct SeasonModifiers {
        uint256 springGrowthMultiplier; // Multiplier for base growth rate during spring
        uint256 summerGrowthMultiplier;
        uint256 autumnGrowthMultiplier;
        uint26 winterGrowthMultiplier;
    }
    SeasonModifiers public seasonModifiers;

    function setSeasonGrowthModifiers(uint256 spring, uint256 summer, uint22 autumn, uint26 winter) public onlyOwner {
        seasonModifiers.springGrowthMultiplier = spring; // e.g. 120 for 120%
        seasonModifiers.summerGrowthMultiplier = summer; // e.g. 150 for 150%
        seasonModifiers.autumnGrowthMultiplier = autumn; // e.g. 100 for 100%
        seasonModifiers.winterGrowthMultiplier = winter; // e.g. 80 for 80%
    }


    // --- Internal Helper Functions ---

    // Pseudo-random generation based on block data, sender, and token ID
    function _generatePlotProperties(uint256 tokenId) internal view returns (Biome, Rarity, uint256 initialResources, uint256 generationSeed) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            tokenId,
            tx.origin // tx.origin should be used cautiously, but acceptable for non-security critical randomness here
        )));

        generationSeed = seed;

        // Determine Biome
        uint256 biomeRoll = seed % 10000;
        Biome generatedBiome;
        if (biomeRoll < plotParameters.biomeWeightsForest) {
            generatedBiome = Biome.Forest;
        } else if (biomeRoll < plotParameters.biomeWeightsForest + plotParameters.biomeWeightsDesert) {
            generatedBiome = Biome.Desert;
        } else if (biomeRoll < plotParameters.biomeWeightsForest + plotParameters.biomeWeightsDesert + plotParameters.biomeWeightsAquatic) {
            generatedBiome = Biome.Aquatic;
        } else if (biomeRoll < plotParameters.biomeWeightsForest + plotParameters.biomeWeightsDesert + plotParameters.biomeWeightsAquatic + plotParameters.biomeWeightsMountain) {
            generatedBiome = Biome.Mountain;
        } else {
            generatedBiome = Biome.Swamp;
        }

        // Determine Rarity (simplified, could be biome-dependent)
        uint256 rarityRoll = uint256(keccak256(abi.encodePacked(seed, "rarity"))) % 10000;
        Rarity generatedRarity;
        // Example rarity distribution (adjust weights as needed)
        if (rarityRoll < 5000) generatedRarity = Rarity.Common; // 50%
        else if (rarityRoll < 8000) generatedRarity = Rarity.Uncommon; // 30%
        else if (rarityRoll < 9500) generatedRarity = Rarity.Rare; // 15%
        else if (rarityRoll < 9900) generatedRarity = Rarity.Epic; // 4%
        else generatedRarity = Rarity.Legendary; // 1%


        // Determine Initial Resources (simplified, could be rarity/biome-dependent)
        uint256 initialResourcesAmount = uint256(keccak256(abi.encodePacked(seed, "initial"))) % 1000 * (1e18 / 1000); // Example: 0 to 1 Essence token

        return (generatedBiome, generatedRarity, initialResourcesAmount, generationSeed);
    }

    // Calculate accrued essence since a given time, considering modifiers
    function _calculateEssenceGrowth(uint256 tokenId, uint256 fromTime, uint256 toTime) internal view returns (uint256) {
        if (fromTime >= toTime) {
            return 0;
        }

        PlotData storage plot = plotData[tokenId];
        uint256 timeDelta = toTime - fromTime;

        // Base Growth Rate
        uint256 currentBaseRate = plotParameters.baseGrowthRatePerTick;

        // Apply Rarity Multiplier
        uint256 rarityMultiplier;
        if (plot.rarity == Rarity.Uncommon) rarityMultiplier = plotParameters.rarityGrowthMultiplierUncommon;
        else if (plot.rarity == Rarity.Rare) rarityMultiplier = plotParameters.rarityGrowthMultiplierRare;
        else if (plot.rarity == Rarity.Epic) rarityMultiplier = plotParameters.rarityGrowthMultiplierEpic;
        else if (plot.rarity == Rarity.Legendary) rarityMultiplier = plotParameters.rarityGrowthMultiplierLegendary;
        else rarityMultiplier = 100; // Common

        currentBaseRate = currentBaseRate.mul(rarityMultiplier).div(100);

        // Apply Biome Modifier
        int256 biomeModifier;
        if (plot.biome == Biome.Forest) biomeModifier = int256(plotParameters.biomeGrowthModifierForest);
        else if (plot.biome == Biome.Desert) biomeModifier = int256(plotParameters.biomeGrowthModifierDesert);
        else if (plot.biome == Biome.Aquatic) biomeModifier = int256(plotParameters.biomeGrowthModifierAquatic);
        else if (plot.biome == Biome.Mountain) biomeModifier = int256(plotParameters.biomeGrowthModifierMountain);
        else if (plot.biome == Biome.Swamp) biomeModifier = int256(plotParameters.biomeGrowthModifierSwamp);
        else biomeModifier = 0;

        if (biomeModifier >= 0) {
            currentBaseRate = currentBaseRate.add(uint256(biomeModifier));
        } else {
             currentBaseRate = currentBaseRate > uint256(-biomeModifier) ? currentBaseRate.sub(uint256(-biomeModifier)) : 0;
        }

        // Apply Staking Bonus
        if (plot.isStaked) {
             currentBaseRate = currentBaseRate.mul(plotParameters.stakedGrowthBonus).div(100);
        }

        // Apply Development Boost
        currentBaseRate = currentBaseRate.add(plot.developedLevel.mul(plotParameters.developmentGrowthBoost));

        // Apply Season Multiplier
        uint22 seasonMultiplier;
        if (currentSeason == Season.Spring) seasonMultiplier = seasonModifiers.springGrowthMultiplier;
        else if (currentSeason == Season.Summer) seasonMultiplier = seasonModifiers.summerGrowthMultiplier;
        else if (currentSeason == Season.Autumn) seasonMultiplier = seasonModifiers.autumnGrowthMultiplier;
        else seasonMultiplier = seasonModifiers.winterGrowthMultiplier;

        currentBaseRate = currentBaseRate.mul(seasonMultiplier).div(100);


        // Apply Pollution Penalty
        uint256 pollutionPenalty = plot.pollutionLevel.mul(plotParameters.pollutionGrowthPenaltyFactor); // Example: pollution points * factor = deduction per tick
        currentBaseRate = currentBaseRate > pollutionPenalty ? currentBaseRate.sub(pollutionPenalty) : 0;

        // Total Essence = Rate * Time
        return currentBaseRate.mul(timeDelta);
    }

    // Calculate passive pollution increase and apply it
    function _applyPassivePollution(uint256 tokenId) internal {
         PlotData storage plot = plotData[tokenId];
         uint256 timeDelta = block.timestamp.sub(plot.lastHarvestTime); // Use lastHarvestTime as the reference for pollution tick

         uint256 pollutionIncrease = timeDelta.mul(plotParameters.passivePollutionIncreasePerTick);
         plot.pollutionLevel = Math.min(plot.pollutionLevel.add(pollutionIncrease), 100); // Max pollution is 100
         // Update last harvest time here too, as pollution tick is linked to it
         plot.lastHarvestTime = block.timestamp;
    }

    // Check if a plot mutates (internal, called from season change)
    function _checkAndMutatePlot(uint256 tokenId) internal returns (bool mutated) {
        PlotData storage plot = plotData[tokenId];

        // Pseudo-random roll for mutation chance
        uint256 mutationRoll = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            tokenId,
            plot.generationSeed, // Include original seed for deterministic check based on plot
            currentSeason
        ))) % 10000; // Roll between 0 and 9999

        // Calculate chance (out of 10000)
        uint256 mutationChance = plotParameters.mutationChanceBase;
        mutationChance = mutationChance.add(plot.pollutionLevel.mul(plotParameters.mutationChancePollutionFactor));
        if (plot.isStaked) {
            mutationChance = mutationChance.add(plotParameters.mutationChanceStakedBonus);
        }
        // Cap chance at 100% (10000)
        mutationChance = Math.min(mutationChance, 10000);


        if (mutationRoll < mutationChance) {
            // Mutation occurs!
            mutated = true;

            Biome oldBiome = plot.biome;
            Rarity oldRarity = plot.rarity;

            // Determine new properties (simplified: maybe change biome or rarity)
            uint256 mutationEffectRoll = uint256(keccak256(abi.encodePacked(mutationRoll, block.number))) % 100;

            if (mutationEffectRoll < 50) { // 50% chance to change biome
                 uint256 biomeChangeRoll = uint256(keccak256(abi.encodePacked(mutationEffectRoll, plot.generationSeed, "biome"))) % 5;
                 plot.biome = Biome(biomeChangeRoll); // Change to a random biome
            } else { // 50% chance to change rarity
                 int256 rarityChangeAmount = int256(uint256(keccak256(abi.encodePacked(mutationEffectRoll, plot.generationSeed, "rarity"))) % (plotParameters.mutationEffectMaxRarityChange - plotParameters.mutationEffectMinRarityChange + 1)) + int256(plotParameters.mutationEffectMinRarityChange);

                 int256 currentRarityInt = int256(uint8(plot.rarity));
                 int26 newRarityInt = currentRarityInt.add(rarityChangeAmount);

                 // Clamp rarity between 0 (Common) and 4 (Legendary)
                 newRarityInt = Math.max(newRarityInt, 0);
                 newRarityInt = Math.min(newRarityInt, 4);

                 plot.rarity = Rarity(uint8(newRarityInt));
            }

            emit PlotMutated(tokenId, oldBiome, plot.biome, oldRarity, plot.rarity);
        } else {
            mutated = false;
        }
    }


    // --- Core Gameplay Functions (8) ---

    // 13. mintPlot (Generative)
    function mintPlot(address to) public payable whenNotPaused returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        (Biome biome, Rarity rarity, uint256 initialResources, uint256 generationSeed) = _generatePlotProperties(tokenId);

        plotData[tokenId] = PlotData({
            biome: biome,
            rarity: rarity,
            generationSeed: generationSeed,
            initialResources: initialResources,
            pollutionLevel: 0,
            developedLevel: 0,
            lastHarvestTime: block.timestamp,
            unharvestedEssence: initialResources, // Start with initial resources
            isStaked: false,
            stakeStartTime: 0
        });

        _safeMint(to, tokenId);

        emit PlotMinted(tokenId, to, biome, rarity, initialResources);
    }

    // 14. harvestResources
    function harvestResources(uint256 tokenId) public whenNotPaused onlyPlotOwner(tokenId) {
        PlotData storage plot = plotData[tokenId];

        // Apply passive pollution increase first based on time elapsed
        _applyPassivePollution(tokenId);

        // Calculate accrued essence
        uint256 accrued = _calculateEssenceGrowth(tokenId, plot.lastHarvestTime, block.timestamp);

        // Add to plot's unharvested balance
        plot.unharvestedEssence = plot.unharvestedEssence.add(accrued);

        // Update last harvest time
        plot.lastHarvestTime = block.timestamp;

        // No essence is transferred out yet, only accrued on the plot
        emit ResourcesHarvested(tokenId, msg.sender, accrued);
    }

    // 15. claimPlotEssence - Moves unharvested essence from plot to owner's claimable balance
    function claimPlotEssence(uint256 tokenId) public whenNotPaused onlyPlotOwner(tokenId) {
         PlotData storage plot = plotData[tokenId];

         // Ensure any pending growth is calculated before claiming
         // Apply passive pollution first based on time elapsed
         _applyPassivePollution(tokenId);
         uint256 accrued = _calculateEssenceGrowth(tokenId, plot.lastHarvestTime, block.timestamp);
         plot.unharvestedEssence = plot.unharvestedEssence.add(accrued);
         plot.lastHarvestTime = block.timestamp; // Update time after calculation

         uint256 amountToClaim = plot.unharvestedEssence;
         require(amountToClaim > 0, "No essence to claim from this plot");

         claimableEssence[msg.sender] = claimableEssence[msg.sender].add(amountToClaim);
         plot.unharvestedEssence = 0; // Reset plot's unharvested balance

         // Note: EssenceClaimed event will be emitted by claimTotalEssence when funds are withdrawn
         // This function just moves internally
         emit ResourcesHarvested(tokenId, msg.sender, amountToClaim); // Re-use event to indicate internal transfer
    }


    // 16. stakePlot
    function stakePlot(uint256 tokenId) public whenNotPaused onlyPlotOwner(tokenId) {
        PlotData storage plot = plotData[tokenId];
        require(!plot.isStaked, "Plot is already staked");

        plot.isStaked = true;
        plot.stakeStartTime = block.timestamp;

        emit PlotStaked(tokenId, msg.sender, block.timestamp);
    }

    // 17. unstakePlot
    function unstakePlot(uint256 tokenId) public whenNotPaused onlyPlotOwner(tokenId) {
        PlotData storage plot = plotData[tokenId];
        require(plot.isStaked, "Plot is not staked");
        require(block.timestamp >= plot.stakeStartTime.add(plotParameters.minStakeDuration), "Minimum stake duration not met");

        plot.isStaked = false;
        plot.stakeStartTime = 0; // Reset stake time

        // Note: Staking bonus is calculated during harvest, not here on unstake
        emit PlotUnstaked(tokenId, msg.sender, block.timestamp);
    }

    // 18. developPlot
    function developPlot(uint256 tokenId) public whenNotPaused onlyPlotOwner(tokenId) {
        PlotData storage plot = plotData[tokenId];
        uint256 cost = plotParameters.developmentCostEssence;
        require(claimableEssence[msg.sender] >= cost, "Insufficient claimable essence");

        // Consume essence
        claimableEssence[msg.sender] = claimableEssence[msg.sender].sub(cost);

        // Apply development effect
        plot.developedLevel = plot.developedLevel.add(1); // Increase development level

        emit PlotDeveloped(tokenId, msg.sender, plot.developedLevel);
    }

    // 19. mitigatePollution
    function mitigatePollution(uint256 tokenId) public whenNotPaused onlyPlotOwner(tokenId) {
         PlotData storage plot = plotData[tokenId];
         uint256 cost = plotParameters.mitigatePollutionCostEssence;
         require(claimableEssence[msg.sender] >= cost, "Insufficient claimable essence");
         require(plot.pollutionLevel > 0, "Plot has no pollution");

         // Consume essence
         claimableEssence[msg.sender] = claimableEssence[msg.sender].sub(cost);

         // Reduce pollution
         uint256 reduction = plotParameters.mitigatePollutionAmount;
         plot.pollutionLevel = plot.pollutionLevel > reduction ? plot.pollutionLevel.sub(reduction) : 0;

         emit PollutionMitigated(tokenId, msg.sender, plot.pollutionLevel);
    }

    // 20. triggerSeasonChange
    function triggerSeasonChange() public whenNotPaused onlyAdminOrSeasonTime {
        // Calculate time since last season change
        uint256 timeSinceLastChange = block.timestamp.sub(plotParameters.lastSeasonChangeTime);
        require(timeSinceLastChange >= plotParameters.seasonDuration || msg.sender == owner(), "Season duration has not passed");

        // Determine how many seasons to advance
        uint256 seasonsToAdvance = timeSinceLastChange.div(plotParameters.seasonDuration);
        if (msg.sender == owner()) {
             seasonsToAdvance = 1; // Admin can force advance one season
        } else {
            // Only advance if duration passed
             require(seasonsToAdvance > 0, "Season duration has not passed");
        }


        // Advance season(s)
        uint8 currentSeasonInt = uint8(currentSeason);
        uint8 newSeasonInt = uint8((uint256(currentSeasonInt).add(seasonsToAdvance)) % 4); // Assuming 4 seasons
        currentSeason = Season(newSeasonInt);
        plotParameters.lastSeasonChangeTime = block.timestamp; // Update last change time

        // ** Mutation Check (potential gas cost if many plots)**
        // This loop could be very expensive with many NFTs.
        // A more scalable approach might be:
        // A) Require users to call a function like `checkPlotForMutation(tokenId)` themselves (user pays gas).
        // B) Implement a system where a subset of plots is checked per block/transaction via keeper/bot.
        // For this example, we'll include the loop as a conceptual demonstration.
        uint26 totalPlots = _tokenIdCounter.current();
        for (uint256 i = 1; i <= totalPlots; i++) {
             // Check if plot i exists and check for mutation
             if (_exists(i)) {
                 _checkAndMutatePlot(i);
             }
        }


        emit SeasonChanged(currentSeason, block.timestamp.div(plotParameters.seasonDuration)); // Example season number based on duration
    }


    // --- Resource Claiming (1) ---

    // 21. claimTotalEssence - Allows owner to withdraw their total claimable balance
    // In a real system, this would likely mint/transfer an ERC20 token
    // Here, it just conceptually makes it 'available' to the owner.
    // If Essence was meant to be used *within* the contract only (for develop/mitigate),
    // this function wouldn't be needed. If it's meant to be an external token,
    // this function would interact with an external ERC20 contract.
    // For this example, we'll make it interact with an *assumed* external ERC20 `EssenceToken`.
    // NOTE: This requires an ERC20 interface and address. Adding placeholder.
    // address public essenceTokenAddress;
    // interface IEssenceToken { function transfer(address to, uint256 amount) external returns (bool); }

    // function setEssenceTokenAddress(address _tokenAddress) public onlyOwner { essenceTokenAddress = _tokenAddress; }

    // function claimTotalEssence() public whenNotPaused {
    //     uint256 amount = claimableEssence[msg.sender];
    //     require(amount > 0, "No essence to claim");
    //     require(essenceTokenAddress != address(0), "Essence token address not set");

    //     claimableEssence[msg.sender] = 0; // Reset balance

    //     // Transfer essence token
    //     IEssenceToken essenceToken = IEssenceToken(essenceTokenAddress);
    //     require(essenceToken.transfer(msg.sender, amount), "Essence token transfer failed");

    //     emit EssenceClaimed(msg.sender, amount);
    // }

    // *Self-correction:* The prompt asks for a *single* smart contract, ideally avoiding external dependencies unless crucial. Let's simplify: `claimTotalEssence` just zeros the internal balance and emits an event. The "use" of Essence (develop/mitigate) happens *against* this internal balance. This keeps the contract self-contained.

    function claimTotalEssence() public whenNotPaused {
        uint256 amount = claimableEssence[msg.sender];
        require(amount > 0, "No essence to claim");

        claimableEssence[msg.sender] = 0; // Reset balance

        // Conceptually claimed. Emit event.
        // This implies the user's "Essence balance" within the game/ecosystem is now zeroed
        // and they need to earn more by harvesting/claiming again.
        // Any external representation (like an ERC20 token) would be managed externally
        // or via a different contract interacting with this one.
        emit EssenceClaimed(msg.sender, amount);
    }


    // --- View Functions (6 Custom + 5 Standard ERC721) ---

    // 22. getPlotDetails
    function getPlotDetails(uint256 tokenId) public view returns (
        Biome biome,
        Rarity rarity,
        uint256 pollutionLevel,
        uint256 developedLevel,
        uint26 unharvestedEssence,
        bool isStaked,
        uint256 stakeStartTime,
        uint256 lastHarvestTime
    ) {
        PlotData storage plot = plotData[tokenId];
        require(_exists(tokenId), "Plot does not exist"); // More explicit check

        return (
            plot.biome,
            plot.rarity,
            plot.pollutionLevel,
            plot.developedLevel,
            plot.unharvestedEssence,
            plot.isStaked,
            plot.stakeStartTime,
            plot.lastHarvestTime
        );
    }

    // 23. checkPlotGrowth - Calculates potential accrued essence *without* applying pollution or harvesting
    function checkPlotGrowth(uint256 tokenId) public view returns (uint256 accruedEssence) {
         require(_exists(tokenId), "Plot does not exist");
         PlotData storage plot = plotData[tokenId];

         // Calculate based on current time vs last harvest time
         accruedEssence = _calculateEssenceGrowth(tokenId, plot.lastHarvestTime, block.timestamp);
    }


    // 24. getClaimableEssence
    function getClaimableEssence(address ownerAddress) public view returns (uint256) {
        return claimableEssence[ownerAddress];
    }

    // 25. calculateEcosystemHealth (Simplified)
    // NOTE: Iterating over all plots in a view function can be gas-prohibitive
    // on large collections. This is a conceptual example.
    function calculateEcosystemHealth() public view returns (uint256 healthScore) {
        uint256 totalPlots = _tokenIdCounter.current();
        if (totalPlots == 0) return 100; // Default health if no plots

        uint256 totalPollution = 0;
        uint256 totalEssencePotential = 0; // Example: sum of unharvested + growth potential
        uint256 activePlots = 0;

        for (uint256 i = 1; i <= totalPlots; i++) {
            if (_exists(i)) {
                PlotData storage plot = plotData[i];
                totalPollution = totalPollution.add(plot.pollutionLevel);
                totalEssencePotential = totalEssencePotential.add(plot.unharvestedEssence).add(checkPlotGrowth(i));
                activePlots++;
            }
        }

        if (activePlots == 0) return 100;

        uint256 averagePollution = totalPollution.div(activePlots);
        // Simple health score: Higher essence potential, lower pollution = higher health
        // Score = (Essence Potential Factor - Pollution Factor) + Base
        // Need to scale properly. This is highly conceptual.
        // Let's just return average pollution as a simple health indicator (lower is better)
        return 100 > averagePollution ? 100 - averagePollution : 0; // Score 0-100, 100 is best (0 pollution)
    }

     // 26. getCurrentSeason
    function getCurrentSeason() public view returns (Season) {
        return currentSeason;
    }

    // 27. simulateMutationCheck - Allows seeing the chance without triggering (calls internal _checkAndMutatePlot logic without state change)
     function simulateMutationCheck(uint256 tokenId) public view returns (uint256 mutationChancePercent, bool likelyToMutate) {
        require(_exists(tokenId), "Plot does not exist");
        PlotData storage plot = plotData[tokenId];

        // Calculate chance (out of 10000) - same logic as _checkAndMutatePlot
        uint256 mutationChance = plotParameters.mutationChanceBase;
        mutationChance = mutationChance.add(plot.pollutionLevel.mul(plotParameters.mutationChancePollutionFactor));
        if (plot.isStaked) {
            mutationChance = mutationChance.add(plotParameters.mutationChanceStakedBonus);
        }
        mutationChance = Math.min(mutationChance, 10000); // Cap at 100%

        mutationChancePercent = mutationChance.mul(100).div(10000); // Convert to percentage (0-100)

        // Cannot truly simulate the roll itself, but can show the calculated chance
        // Returning a boolean based on a threshold is illustrative, but the actual roll is non-deterministic outside the tx
        likelyToMutate = mutationChance > 500; // Example threshold: >5% chance

        return (mutationChancePercent, likelyToMutate);
    }


    // --- Standard ERC721 View Functions (5) ---
    // 28. balanceOf
    // 29. ownerOf
    // 30. getApproved
    // 31. isApprovedForAll
    // 32. supportsInterface
    // These are provided by the ERC721 inheritance.
    // Total functions >= 12 (Admin) + 8 (Gameplay) + 1 (Claim) + 6 (Custom View) + 5 (Standard View) = 32+ functions.
}
```

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **On-Chain Generative Traits:** `_generatePlotProperties` uses block data and token ID as seeds for basic pseudo-randomness to determine Biome, Rarity, and initial resources upon minting. This ties the NFT's initial properties directly to the on-chain minting event.
2.  **Dynamic & State-Changing NFTs:** The `PlotData` struct within the contract directly stores mutable properties like `pollutionLevel`, `developedLevel`, `lastHarvestTime`, `unharvestedEssence`, `isStaked`, and `stakeStartTime`. These are updated by user actions (`harvestResources`, `developPlot`, `mitigatePollution`, `stakePlot`, `unstakePlot`) and potentially by the passage of time (`_applyPassivePollution` called within harvesting).
3.  **Time-Based Resource Production:** `_calculateEssenceGrowth` calculates resource accrual based on the time elapsed since the last check, modified by various dynamic and static factors (Biome, Rarity, Pollution, Staking, Development, Season). `harvestResources` makes this accrued resource claimable.
4.  **Internal Resource Ecosystem (`Essence`):** The contract manages a virtual resource (`Essence`) internally. Plots produce it, and owners accumulate it (`unharvestedEssence`, `claimableEssence`). This resource is then used as a cost for other interactions (`developPlot`, `mitigatePollution`), creating a self-contained economic loop within the contract. While `claimTotalEssence` is included, it's simplified to avoid external ERC20 complexity in this example.
5.  **Environmental Cycles (`Season`):** `triggerSeasonChange` introduces a global time-based state change. Seasons affect resource growth rates globally (`seasonModifiers`). This adds a layer of dynamic, kingdom-wide strategy.
6.  **Environmental Degradation & Mitigation (`Pollution`):** Plots passively accumulate pollution over time (`_applyPassivePollution`). Pollution negatively impacts resource growth (`_calculateEssenceGrowth`). Owners must spend `Essence` to reduce pollution (`mitigatePollution`), creating a cost for neglecting plots and a use case for the internal resource.
7.  **Development/Upgrading:** `developPlot` allows spending `Essence` for permanent improvements (like growth boosts), providing another use case for the resource and a long-term progression path for NFTs.
8.  **NFT Staking with Effects:** `stakePlot` and `unstakePlot` manage staking state. Being staked provides a boost to resource production (`_calculateEssenceGrowth`), tying the staking mechanic directly into the core gameplay loop.
9.  **Probabilistic Mutation:** `_checkAndMutatePlot` (triggered by season change) introduces a rare chance for a plot's core generative traits (Biome, Rarity) to change based on factors like pollution and staking status, adding an unpredictable, evolving element to the NFTs.
10. **Complex Interdependencies:** The mechanics are interconnected: time affects pollution and growth; pollution affects growth and mutation chance; staking affects growth and mutation chance; development affects growth; seasons affect growth; Essence is needed for development and mitigation, and produced by growth.

This contract provides a framework for a complex, interactive NFT ecosystem where NFTs are not just static images but dynamic elements within a simulated world governed by on-chain rules and timers. The function count exceeds 20, covering administrative controls, core NFT lifecycle, complex gameplay interactions, resource management, and view functions.