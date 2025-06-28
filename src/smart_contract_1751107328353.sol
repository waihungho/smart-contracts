Okay, let's create a smart contract concept around a "Crypto Cultivation" ecosystem. It will involve unique digital "Plants" (NFTs) that grow over time, require resources (managed internally), can be harvested for rewards (more NFTs), and even cross-pollinated to create new variations. This combines elements of gaming, resource management, and dynamic NFTs.

We will implement the core logic for planting, feeding, growing, harvesting, burning resources, and cross-pollination.

**Concept:** CryptoCultivator - A digital ecosystem where users cultivate unique on-chain plants (NFTs). These plants have traits, grow over time when fed, can be harvested for new seeds, and potentially cross-pollinated to breed new varieties.

**Core Mechanics:**
1.  **Seeds & Plants:** Both are ERC-721 NFTs. Seeds are initial assets, Plants are the grown form. Planting consumes a Seed and creates a Plant.
2.  **Nutrients:** An abstract resource managed within the contract, required to feed Plants and enable growth. Nutrients are obtained by burning other Seeds or Plants.
3.  **Growth:** Plants progress through stages (Germinating, Young, Growing, Mature) over time, accelerated by feeding with Nutrients.
4.  **Harvesting:** Mature Plants can be harvested to yield new Seeds. Harvesting might reset the Plant's state or consume it (we'll choose reset to a 'Harvested' state).
5.  **Cross-Pollination:** Combine two compatible Plants to potentially yield new, potentially rare, Seed types. This will consume the parent Plants.
6.  **Traits:** Plants and Seeds have traits that influence their growth, nutrient needs, yield, and compatibility for cross-pollination. Traits are determined pseudo-randomly upon Seed minting.

**NFTs:**
*   `Seed` NFT: Represents an unplanted seed with latent traits.
*   `Plant` NFT: Represents a planted, growing, or mature plant with active traits and a growth state.

**Resources:**
*   `Nutrient Balance`: Each user has an internal balance of Nutrients.

**Outline:**

1.  **Contract Setup:**
    *   Imports: ERC721, Ownable, Pausable.
    *   Enums: PlantState, PlantType, Rarity.
    *   Structs: SeedData, PlantData.
    *   State Variables: Mappings for NFTs, balances, parameters.
    *   Events: To track actions.
    *   Admin Controls: Owner-only functions for parameter tuning, pause/unpause.
2.  **NFT Management:** (Standard ERC721 functions)
    *   Minting (internal helper functions).
    *   Burning (internal helper functions).
    *   Transfer/Approval.
3.  **Core Cultivation Logic:**
    *   Buying/Minting Seeds.
    *   Planting Seeds (Seed -> Plant).
    *   Burning Items for Nutrients.
    *   Feeding Plants (Consume Nutrients, advance growth stage based on time).
    *   Checking Plant State/Readiness.
    *   Harvesting Plants (Mature Plant -> New Seeds, reset Plant state).
    *   Cross-Pollinating (Two Plants -> New Seed(s), burn Plants).
    *   Pruning Plants (Burn Plant for partial Nutrients).
4.  **Data & View Functions:**
    *   Get Nutrient Balance.
    *   Get Plant/Seed Traits.
    *   Get Plant Growth History/Status.
    *   Get User's NFTs.
    *   Total Supply.
    *   Get Current Parameters.
5.  **Admin Functions:**
    *   Set Growth Parameters.
    *   Set Rarity Parameters.
    *   Pause/Unpause.
    *   Withdraw Funds (if seeds are bought with ETH).

**Function Summary:**

1.  `constructor()`: Initializes contract owner and base parameters.
2.  `mintInitialSeed(uint256 quantity)`: (Admin) Mints initial Seeds to the owner.
3.  `buySeed(uint256 quantity)`: Allows users to buy Seeds with ETH.
4.  `plantSeed(uint256 seedId)`: Converts a Seed NFT into a Plant NFT for the caller. Burns the Seed.
5.  `burnItemForNutrients(uint256 itemId, bool isSeed)`: Burns a Seed or Plant NFT owned by the caller to add Nutrients to their balance.
6.  `feedPlant(uint256 plantId)`: Spends user's Nutrients to feed a specific Plant, advancing its growth based on elapsed time since last feed.
7.  `checkPlantGrowthState(uint256 plantId)`: Returns the current growth state of a Plant.
8.  `isPlantReadyToHarvest(uint256 plantId)`: Checks if a Plant is in the 'Mature' state and ready for harvesting.
9.  `harvestPlant(uint256 plantId)`: If the Plant is Mature, it yields new Seeds based on traits and parameters. The Plant's state is reset to 'Harvested', requiring re-feeding cycle.
10. `crossPollinate(uint256 plantId1, uint256 plantId2)`: Burns two eligible Plants owned by the caller and potentially mints one or more new Seeds with combined/new traits.
11. `prunePlant(uint256 plantId)`: Burns a Plant (not necessarily mature) for a reduced amount of Nutrients compared to burning for full nutrients.
12. `getPlantTraits(uint256 plantId)`: Returns the traits (type, rarity, modifiers) of a Plant.
13. `getSeedTraits(uint256 seedId)`: Returns the potential traits of a Seed (determined upon minting).
14. `getPlantStatus(uint256 plantId)`: Returns detailed status of a Plant (state, last fed time, accumulated growth points).
15. `getNutrientBalance(address user)`: Returns the Nutrient balance for a specific user.
16. `getUserPlants(address user)`: Returns a list of Plant NFT IDs owned by a user.
17. `getUserSeeds(address user)`: Returns a list of Seed NFT IDs owned by a user.
18. `setGrowthParameters(uint256[] calldata stagesDuration, uint256[] calldata stagesNutrientCost, uint256[] calldata harvestYieldBounds)`: (Admin) Sets parameters for growth stages, feeding costs, and harvest yields.
19. `setNutrientValues(uint256 seedValue, uint256 plantValue, uint256 pruneValue)`: (Admin) Sets the amount of Nutrients gained from burning Seeds, Plants, or pruning.
20. `setCrossPollinationParameters(uint256 baseSeedYield, uint256 minRarityBoostChance, uint256 maxRarityBoostChance)`: (Admin) Sets parameters for cross-pollination yield and rarity outcomes.
21. `pause()`: (Admin) Pauses contract functions (like feeding, planting, harvesting, burning).
22. `unpause()`: (Admin) Unpauses the contract.
23. `withdrawFunds()`: (Admin) Withdraws accumulated ETH from Seed sales.
24. `totalSupplySeeds()`: Returns the total number of Seed NFTs minted.
25. `totalSupplyPlants()`: Returns the total number of Plant NFTs currently active.
26. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a given NFT (standard ERC721). Note: this will be a basic implementation pointing to placeholder or a generic URI structure. Real-world would use a service or dynamic generation.
27. `supportsInterface(bytes4 interfaceId)`: (Standard ERC165) Indicates supported interfaces (ERC721, ERC165).

Let's code this up.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Contract: CryptoCultivator ---
// Concept: A digital ecosystem for on-chain plant cultivation using NFTs.
// Users collect, plant, feed, grow, harvest, and cross-pollinate unique digital plants.
//
// Core Mechanics:
// - Plants and Seeds are ERC-721 NFTs.
// - Nutrients (internal resource) are required for growth.
// - Nutrients are gained by burning Seeds or Plants.
// - Plants grow through stages (Germinating, Young, Growing, Mature) over time when fed.
// - Mature Plants yield new Seeds upon harvesting.
// - Two Plants can be cross-pollinated to yield new seeds, burning the parents.
// - Traits influence growth, nutrient needs, and yield.
//
// NFTs: ERC-721 (Seed and Plant tokens share the same contract, differentiated by state)
// Resources: Internal Nutrient balance for each user.
// Key Features: Growth simulation, harvesting cycle, burning for resources, cross-pollination mechanics.
// Access Control: Ownable pattern for admin functions.
// Pausability: OpenZeppelin Pausable for maintenance/emergencies.

// Outline:
// 1. Contract Setup (Imports, Enums, Structs, State Variables, Events)
// 2. NFT Management (ERC721 core functions, internal mint/burn)
// 3. Core Cultivation Logic (Mint/Buy Seeds, Plant, Burn, Feed, Harvest, Cross-Pollinate, Prune)
// 4. Data & View Functions (Get balances, traits, status, user assets, supply)
// 5. Admin Functions (Set parameters, Pause/Unpause, Withdraw)
// 6. ERC721 Metadata & Utility (tokenURI, supportsInterface)

// Function Summary:
// 1. constructor()
// 2. mintInitialSeed(uint256 quantity) (Admin)
// 3. buySeed(uint256 quantity) (Public, payable)
// 4. plantSeed(uint256 seedId) (Public)
// 5. burnItemForNutrients(uint256 itemId, bool isSeed) (Public)
// 6. feedPlant(uint256 plantId) (Public)
// 7. checkPlantGrowthState(uint256 plantId) (View)
// 8. isPlantReadyToHarvest(uint256 plantId) (View)
// 9. harvestPlant(uint256 plantId) (Public)
// 10. crossPollinate(uint256 plantId1, uint256 plantId2) (Public)
// 11. prunePlant(uint256 plantId) (Public)
// 12. getPlantTraits(uint256 plantId) (View)
// 13. getSeedTraits(uint256 seedId) (View)
// 14. getPlantStatus(uint256 plantId) (View)
// 15. getNutrientBalance(address user) (View)
// 16. getUserPlants(address user) (View) - Helper (uses internal tracking or iterates)
// 17. getUserSeeds(address user) (View) - Helper (uses internal tracking or iterates)
// 18. setGrowthParameters(uint256[] calldata stagesDuration, uint256[] calldata stagesNutrientCost, uint256[] calldata harvestYieldBounds) (Admin)
// 19. setNutrientValues(uint256 seedValue, uint256 plantValue, uint256 pruneValue) (Admin)
// 20. setCrossPollinationParameters(uint256 baseSeedYield, uint256 minRarityBoostChance, uint256 maxRarityBoostChance) (Admin)
// 21. pause() (Admin)
// 22. unpause() (Admin)
// 23. withdrawFunds() (Admin)
// 24. totalSupplySeeds() (View)
// 25. totalSupplyPlants() (View)
// 26. tokenURI(uint256 tokenId) (View, Override)
// 27. supportsInterface(bytes4 interfaceId) (View, Override)

contract CryptoCultivator is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables & Data Structures ---

    Counters.Counter private _tokenIds;
    Counters.Counter private _seedSupply;
    Counters.Counter private _plantSupply;

    // Enums for Plant states and traits
    enum PlantState { Seed, Germinating, Young, Growing, Mature, Harvested, Dormant } // Dormant state after harvesting

    enum PlantType { Basic, Hybrid, Exotic, RareVariety } // Examples
    enum Rarity { Common, Rare, Epic, Legendary }

    // Struct for Seed data (minimal, traits determined on mint)
    struct SeedData {
        uint256 mintedAt;
        PlantType plantType;
        Rarity rarity;
        // Add other trait modifiers if needed
    }

    // Struct for Plant data
    struct PlantData {
        PlantState state;
        uint256 plantedAt;
        uint256 lastFedAt; // Timestamp of the last feeding
        uint256 lastStateChangeAt; // Timestamp when state last changed
        uint256 growthPoints; // Accumulated points towards next stage (optional, or rely on time)
        PlantType plantType; // Traits inherited from seed
        Rarity rarity;
        // Add other active trait modifiers if needed
    }

    // Mappings
    mapping(uint256 => SeedData) private _seeds;
    mapping(uint256 => PlantData) private _plants;
    mapping(address => uint256) private _nutrientBalances; // User's nutrient balance

    // Parameters (Admin configurable)
    uint256 public seedPrice = 0.01 ether; // Price to buy a seed
    uint256[] public stagesDuration; // Duration (in seconds) for each growth stage (excluding Seed, starts from Germinating)
    uint256[] public stagesNutrientCost; // Nutrient cost per feed for each growth stage
    uint256[] public harvestYieldBounds; // [minYield, maxYield] seeds upon harvesting Mature plant
    uint256 public nutrientValueSeed; // Nutrients gained from burning a Seed
    uint256 public nutrientValuePlant; // Nutrients gained from burning a Plant
    uint256 public nutrientValuePrune; // Nutrients gained from pruning a Plant

    uint256 public crossPollinationBaseSeedYield; // Base number of seeds from cross-pollination
    uint256 public crossPollinationMinRarityBoostChance; // % chance for rarity boost in cross-pollination
    uint256 public crossPollinationMaxRarityBoostChance; // % chance for better rarity boost

    // Mapping to track active Plant IDs per owner (for faster lookup, optional but helpful)
    mapping(address => uint256[]) private _userPlants;
    mapping(address => uint256[]) private _userSeeds;
    // Helper mapping for reverse lookup to remove from dynamic array
    mapping(uint256 => uint256) private _plantIndexInUserArray;
    mapping(uint256 => uint256) private _seedIndexInUserArray;


    // --- Events ---
    event SeedMinted(uint256 indexed seedId, address indexed owner, PlantType plantType, Rarity rarity);
    event Planted(uint256 indexed plantId, address indexed owner);
    event ItemBurnedForNutrients(uint256 indexed itemId, address indexed owner, uint256 nutrientsGained, bool wasSeed);
    event PlantFed(uint256 indexed plantId, address indexed owner, uint256 nutrientsUsed, PlantState newState);
    event PlantStateChanged(uint256 indexed plantId, PlantState oldState, PlantState newState);
    event PlantHarvested(uint256 indexed plantId, address indexed owner, uint256 seedsYielded);
    event CrossPollinated(uint256 indexed plantId1, uint256 indexed plantId2, address indexed owner, uint256 seedsYielded);
    event PlantPruned(uint256 indexed plantId, address indexed owner, uint256 nutrientsGained);
    event ParametersUpdated();

    // --- Constructor ---
    constructor() ERC721("CryptoCultivator NFT", "CULTI") Ownable(msg.sender) Pausable(false) {
        // Set initial parameters (can be updated by owner later)
        // stageDuration: Germinating, Young, Growing, Mature (examples)
        stagesDuration = [600, 3600, 86400, 259200]; // Example: 10min, 1hr, 1day, 3days
        // stagesNutrientCost: Cost per feed for each stage
        stagesNutrientCost = [10, 50, 100, 200]; // Example costs
        harvestYieldBounds = [1, 3]; // Example: Yield 1 to 3 seeds
        nutrientValueSeed = 50; // Burning a seed gives 50 nutrients
        nutrientValuePlant = 150; // Burning a plant gives 150 nutrients
        nutrientValuePrune = 75; // Pruning gives 75 nutrients

        crossPollinationBaseSeedYield = 2; // Base yield 2 seeds
        crossPollinationMinRarityBoostChance = 30; // 30% chance of rarity boost
        crossPollinationMaxRarityBoostChance = 60; // Up to 60% for better boost based on parent rarity
    }

    // --- Internal NFT Management Helpers ---
    // Override _update and _increaseBalance for user array tracking
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        address from = ownerOf(tokenId);
        super._update(to, tokenId, auth);

        if (from != address(0)) {
             if (_seeds[tokenId].mintedAt != 0) { // It was a Seed
                _removeSeedFromUserArray(from, tokenId);
             } else if (_plants[tokenId].plantedAt != 0) { // It was a Plant
                 _removePlantFromUserArray(from, tokenId);
             }
        }
         if (to != address(0)) {
             if (_seeds[tokenId].mintedAt != 0) { // It is now a Seed
                _addSeedToUserArray(to, tokenId);
             } else if (_plants[tokenId].plantedAt != 0) { // It is now a Plant
                 _addPlantToUserArray(to, tokenId);
             }
        }
        return to;
    }

     // Override _burn for user array tracking and clearing data
    function _burn(uint256 tokenId) internal override(ERC721) {
        address owner = ownerOf(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        if (_seeds[tokenId].mintedAt != 0) { // Burning a Seed
            _removeSeedFromUserArray(owner, tokenId);
             delete _seeds[tokenId]; // Clear seed data
             _seedSupply.decrement();
        } else if (_plants[tokenId].plantedAt != 0) { // Burning a Plant
             _removePlantFromUserArray(owner, tokenId);
             delete _plants[tokenId]; // Clear plant data
             _plantSupply.decrement();
        } else {
            revert("CryptoCultivator: Cannot burn token with no state (neither Seed nor Plant)");
        }

        super._burn(tokenId);
    }

    // Internal function to mint a new Seed
    function _mintSeed(address to, PlantType plantType, Rarity rarity) internal {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _seedSupply.increment();

        _seeds[newItemId] = SeedData({
            mintedAt: block.timestamp,
            plantType: plantType,
            rarity: rarity
        });

        _safeMint(to, newItemId);
        emit SeedMinted(newItemId, to, plantType, rarity);
    }

    // Internal function to mint a new Plant (happens on planting a seed)
    function _mintPlantFromSeed(address to, uint256 seedId, SeedData memory seedData) internal {
         // Assume seedId is already minted and owned by 'to'
         // Assume seedId is being burned shortly after this call

        _plantSupply.increment();
        // A Plant keeps the same token ID as the Seed it originated from
        uint256 plantId = seedId;

        _plants[plantId] = PlantData({
            state: PlantState.Germinating,
            plantedAt: block.timestamp,
            lastFedAt: block.timestamp, // Just planted counts as first "feed" for timer
            lastStateChangeAt: block.timestamp,
            growthPoints: 0, // Not used in this time-based model
            plantType: seedData.plantType,
            rarity: seedData.rarity
        });

        emit Planted(plantId, to);
        emit PlantStateChanged(plantId, PlantState.Seed, PlantState.Germinating);
    }

    // Helper functions to manage user's arrays of token IDs (more gas efficient than iterating all tokens)
     function _addPlantToUserArray(address user, uint256 plantId) internal {
        _userPlants[user].push(plantId);
        _plantIndexInUserArray[plantId] = _userPlants[user].length - 1;
    }

    function _removePlantFromUserArray(address user, uint256 plantId) internal {
        uint256 index = _plantIndexInUserArray[plantId];
        uint256 lastIndex = _userPlants[user].length - 1;
        uint256 lastPlantId = _userPlants[user][lastIndex];

        _userPlants[user][index] = lastPlantId;
        _plantIndexInUserArray[lastPlantId] = index;

        _userPlants[user].pop();
        delete _plantIndexInUserArray[plantId];
    }

     function _addSeedToUserArray(address user, uint256 seedId) internal {
        _userSeeds[user].push(seedId);
        _seedIndexInUserArray[seedId] = _userSeeds[user].length - 1;
    }

    function _removeSeedFromUserArray(address user, uint256 seedId) internal {
        uint256 index = _seedIndexInUserArray[seedId];
        uint256 lastIndex = _userSeeds[user].length - 1;
        uint256 lastSeedId = _userSeeds[user][lastIndex];

        _userSeeds[user][index] = lastSeedId;
        _seedIndexInUserArray[lastSeedId] = index;

        _userSeeds[user].pop();
        delete _seedIndexInUserArray[seedId];
    }

    // --- Core Cultivation Logic ---

    /// @notice Mints initial Seeds for the contract owner.
    /// @param quantity The number of initial seeds to mint.
    function mintInitialSeed(uint256 quantity) public onlyOwner {
        require(quantity > 0, "Quantity must be > 0");
        for (uint i = 0; i < quantity; i++) {
            // Simple pseudo-random trait generation based on block timestamp and iteration
            PlantType plantType = PlantType(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % uint(PlantType.RareVariety + 1));
            Rarity rarity = Rarity(uint256(keccak256(abi.encodePacked(block.timestamp, i, msg.sender))) % uint(Rarity.Legendary + 1));
            _mintSeed(msg.sender, plantType, rarity);
        }
    }

    /// @notice Allows a user to buy seeds using ETH.
    /// @param quantity The number of seeds to buy.
    function buySeed(uint256 quantity) public payable whenNotPaused {
        require(quantity > 0, "Quantity must be > 0");
        uint256 totalCost = seedPrice.mul(quantity);
        require(msg.value >= totalCost, "Insufficient ETH");

        // Refund excess ETH
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        for (uint i = 0; i < quantity; i++) {
             // Simple pseudo-random trait generation based on block timestamp and tx origin/value
            PlantType plantType = PlantType(uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, msg.value, i))) % uint(PlantType.RareVariety + 1));
            Rarity rarity = Rarity(uint256(keccak256(abi.encodePacked(block.timestamp, msg.value, tx.origin, i))) % uint(Rarity.Legendary + 1));
            _mintSeed(msg.sender, plantType, rarity);
        }
    }

    /// @notice Plants a Seed NFT, consuming the Seed and creating a Plant NFT.
    /// @param seedId The ID of the seed NFT to plant.
    function plantSeed(uint256 seedId) public whenNotPaused {
        require(ownerOf(seedId) == msg.sender, "Not your seed");
        require(_seeds[seedId].mintedAt != 0, "Not a valid seed token"); // Check it's a seed token

        SeedData memory seedData = _seeds[seedId];

        // Burn the seed token
        _burn(seedId);

        // Create the plant data for the same token ID
        _mintPlantFromSeed(msg.sender, seedId, seedData);
    }

    /// @notice Burns a Seed or Plant owned by the caller to gain Nutrients.
    /// @param itemId The ID of the Seed or Plant NFT to burn.
    /// @param isSeed True if burning a Seed, False if burning a Plant.
    function burnItemForNutrients(uint256 itemId, bool isSeed) public whenNotPaused {
        require(ownerOf(itemId) == msg.sender, "Not your item");

        uint256 nutrientsGained;
        if (isSeed) {
             require(_seeds[itemId].mintedAt != 0, "Not a valid seed token");
             nutrientsGained = nutrientValueSeed;
        } else {
             require(_plants[itemId].plantedAt != 0, "Not a valid plant token");
             nutrientsGained = nutrientValuePlant;
        }

        _burn(itemId);
        _nutrientBalances[msg.sender] = _nutrientBalances[msg.sender].add(nutrientsGained);

        emit ItemBurnedForNutrients(itemId, msg.sender, nutrientsGained, isSeed);
    }

    /// @notice Spends nutrients to feed a Plant, potentially advancing its growth state.
    /// Growth state advancement depends on time elapsed since last state change and feeding.
    /// @param plantId The ID of the Plant NFT to feed.
    function feedPlant(uint256 plantId) public whenNotPaused {
        require(ownerOf(plantId) == msg.sender, "Not your plant");
        PlantData storage plant = _plants[plantId];
        require(plant.plantedAt != 0, "Not a valid plant token");
        require(plant.state > PlantState.Seed && plant.state < PlantState.Mature, "Plant cannot be fed in this state"); // Cannot feed Seed, Mature, Harvested, Dormant

        uint256 currentStateIndex = uint256(plant.state) - 1; // 0 for Germinating, 1 for Young, etc.
        require(currentStateIndex < stagesNutrientCost.length, "Invalid plant state for feeding cost");

        uint256 requiredNutrients = stagesNutrientCost[currentStateIndex];
        require(_nutrientBalances[msg.sender] >= requiredNutrients, "Insufficient nutrients");

        // Calculate potential state advancement based on time and feeding
        uint256 timeElapsedSinceLastFeed = block.timestamp - plant.lastFedAt;
        uint256 timeNeededForNextStage = 0;
        if (currentStateIndex < stagesDuration.length) {
             timeNeededForNextStage = stagesDuration[currentStateIndex];
        } else {
             // Should not happen if parameters are set correctly, but good to have a fallback
             revert("CryptoCultivator: Invalid stage duration parameter");
        }

        _nutrientBalances[msg.sender] = _nutrientBalances[msg.sender].sub(requiredNutrients);
        plant.lastFedAt = block.timestamp; // Update last fed time

        // Simple model: Feed enables growth if enough time has passed since last state change
        if (timeElapsedSinceLastFeed >= timeNeededForNextStage && currentStateIndex < stagesDuration.length) {
             PlantState oldState = plant.state;
             plant.state = PlantState(currentStateIndex + 2); // Advance to the next stage (e.g., Germinating (1) -> Young (2))
             plant.lastStateChangeAt = block.timestamp; // Reset state change timer
             emit PlantStateChanged(plantId, oldState, plant.state);
        }

        emit PlantFed(plantId, msg.sender, requiredNutrients, plant.state);
    }

    /// @notice Returns the current growth state of a Plant.
    /// @param plantId The ID of the Plant NFT.
    /// @return The PlantState enum value.
    function checkPlantGrowthState(uint256 plantId) public view returns (PlantState) {
        require(_plants[plantId].plantedAt != 0, "Not a valid plant token");
        return _plants[plantId].state;
    }

    /// @notice Checks if a Plant is in the 'Mature' state and ready for harvesting.
    /// @param plantId The ID of the Plant NFT.
    /// @return True if the plant is Mature, False otherwise.
    function isPlantReadyToHarvest(uint256 plantId) public view returns (bool) {
        require(_plants[plantId].plantedAt != 0, "Not a valid plant token");
        return _plants[plantId].state == PlantState.Mature;
    }

    /// @notice If the Plant is Mature, harvests it, yielding new Seeds and resetting the Plant's state.
    /// @param plantId The ID of the Plant NFT to harvest.
    function harvestPlant(uint256 plantId) public whenNotPaused {
        require(ownerOf(plantId) == msg.sender, "Not your plant");
        PlantData storage plant = _plants[plantId];
        require(plant.plantedAt != 0, "Not a valid plant token");
        require(plant.state == PlantState.Mature, "Plant is not mature for harvesting");

        // Calculate yield based on traits and parameters, add randomness
        uint256 minYield = harvestYieldBounds[0];
        uint256 maxYield = harvestYieldBounds[1];
        uint256 yieldQuantity = minYield.add(uint256(keccak256(abi.encodePacked(block.timestamp, plantId, block.difficulty, msg.sender))) % (maxYield - minYield + 1));

        // Adjust yield based on rarity (Example: Legendary yields more)
         if (plant.rarity == Rarity.Rare) yieldQuantity = yieldQuantity.add(1);
         if (plant.rarity == Rarity.Epic) yieldQuantity = yieldQuantity.add(2);
         if (plant.rarity == Rarity.Legendary) yieldQuantity = yieldQuantity.add(3);

        // Ensure minimum yield regardless of randomness/traits if desired
        yieldQuantity = yieldQuantity > 0 ? yieldQuantity : 1;


        // Mint new seeds to the owner
        for (uint i = 0; i < yieldQuantity; i++) {
             // Inherit or generate new traits for harvested seeds (example: 50% chance to inherit parent type, 50% new random type)
             PlantType harvestedSeedType = (uint256(keccak256(abi.encodePacked(block.timestamp, plantId, msg.sender, i))) % 100) < 50 ? plant.plantType : PlantType(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i, plantId))) % uint(PlantType.RareVariety + 1));
             Rarity harvestedSeedRarity = (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i, plant.rarity))) % 100) < 70 ? plant.rarity : Rarity(uint256(keccak256(abi.encodePacked(block.timestamp, i, plant.rarity, msg.sender))) % uint(Rarity.Legendary + 1));

            _mintSeed(msg.sender, harvestedSeedType, harvestedSeedRarity);
        }

        // Reset Plant state to Harvested (or Dormant)
        PlantState oldState = plant.state;
        plant.state = PlantState.Harvested; // Or Dormant
        // Optionally reset lastFedAt or plantedAt to require full growth cycle again
        plant.lastStateChangeAt = block.timestamp; // Mark when it was harvested

        emit PlantHarvested(plantId, msg.sender, yieldQuantity);
        emit PlantStateChanged(plantId, oldState, plant.state);
    }

    /// @notice Combines two eligible Plants owned by the caller to potentially yield new Seeds. Burns parent Plants.
    /// Eligibility could be based on state (e.g., Mature) or Type compatibility.
    /// @param plantId1 The ID of the first Plant.
    /// @param plantId2 The ID of the second Plant.
    function crossPollinate(uint256 plantId1, uint256 plantId2) public whenNotPaused {
        require(plantId1 != plantId2, "Cannot cross-pollinate a plant with itself");
        require(ownerOf(plantId1) == msg.sender, "Not your plant 1");
        require(ownerOf(plantId2) == msg.sender, "Not your plant 2");

        PlantData storage plant1 = _plants[plantId1];
        PlantData storage plant2 = _plants[plantId2];

        require(plant1.plantedAt != 0 && plant2.plantedAt != 0, "Invalid plant tokens");
        // Example eligibility: Both must be Mature
        require(plant1.state == PlantState.Mature && plant2.state == PlantState.Mature, "Both plants must be mature for cross-pollination");

        // --- Cross-Pollination Logic ---
        // Determine traits for new seeds based on parents and randomness.
        // Combine traits, potentially create new types, boost rarity.

        uint256 totalRarity = uint256(plant1.rarity) + uint256(plant2.rarity); // Higher is better

        uint256 seedsYielded = crossPollinationBaseSeedYield;
        // Add randomness to yield
        seedsYielded = seedsYielded.add(uint256(keccak256(abi.encodePacked(block.timestamp, plantId1, plantId2, msg.sender))) % 2); // Maybe 0 or 1 extra seed

        // Mint new seeds
        for (uint i = 0; i < seedsYielded; i++) {
            // Determine new seed type and rarity
            // Simple logic: New type is a hybrid of parents, or a new rare type based on rarity
            PlantType newPlantType;
            if (plant1.plantType == plant2.plantType) {
                 // Same type parents, potentially rare variety of that type
                 newPlantType = PlantType.RareVariety; // Example
            } else {
                 // Different types, potentially a Hybrid
                 newPlantType = PlantType.Hybrid; // Example
            }
             // Add randomness for type
             if (uint256(keccak256(abi.encodePacked(block.timestamp, plantId1, plantId2, msg.sender, i))) % 100 < 20) { // 20% chance of a completely new random type
                 newPlantType = PlantType(uint256(keccak256(abi.encodePacked(block.timestamp, plantId1, plantId2, msg.sender, i))) % uint(PlantType.RareVariety + 1));
             }


            Rarity newRarity = Rarity(totalRarity / 2); // Average parent rarity
            // Add rarity boost chance based on parent rarity
            uint256 rarityBoostRoll = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, plantId1, plantId2, i))) % 100;
            uint256 rarityBoostChance = crossPollinationMinRarityBoostChance.add((crossPollinationMaxRarityBoostChance.sub(crossPollinationMinRarityBoostChance)).mul(totalRarity).div(uint256(Rarity.Legendary).mul(2))); // Scale chance based on combined rarity

            if (rarityBoostRoll < rarityBoostChance && uint256(newRarity) < uint256(Rarity.Legendary)) {
                 newRarity = Rarity(uint256(newRarity) + 1); // Boost rarity
            }


            _mintSeed(msg.sender, newPlantType, newRarity);
        }

        // Burn the parent plants
        _burn(plantId1);
        _burn(plantId2);

        emit CrossPollinated(plantId1, plantId2, msg.sender, seedsYielded);
    }

     /// @notice Burns a Plant prematurely (not Mature state) for a reduced amount of Nutrients.
     /// @param plantId The ID of the Plant NFT to prune.
    function prunePlant(uint256 plantId) public whenNotPaused {
        require(ownerOf(plantId) == msg.sender, "Not your plant");
        PlantData storage plant = _plants[plantId];
        require(plant.plantedAt != 0, "Not a valid plant token");
        require(plant.state < PlantState.Mature, "Plant is too mature to prune"); // Can only prune before Mature

        uint256 nutrientsGained = nutrientValuePrune;

        _burn(plantId);
        _nutrientBalances[msg.sender] = _nutrientBalances[msg.sender].add(nutrientsGained);

        emit PlantPruned(plantId, msg.sender, nutrientsGained);
    }


    // --- Data & View Functions ---

    /// @notice Returns the Nutrient balance for a specific user.
    /// @param user The address of the user.
    /// @return The user's nutrient balance.
    function getNutrientBalance(address user) public view returns (uint256) {
        return _nutrientBalances[user];
    }

    /// @notice Returns the traits of a Plant.
    /// @param plantId The ID of the Plant NFT.
    /// @return plantType, rarity The plant's type and rarity.
    function getPlantTraits(uint256 plantId) public view returns (PlantType plantType, Rarity rarity) {
        require(_plants[plantId].plantedAt != 0, "Not a valid plant token");
        PlantData storage plant = _plants[plantId];
        return (plant.plantType, plant.rarity);
    }

    /// @notice Returns the traits of a Seed.
    /// @param seedId The ID of the Seed NFT.
    /// @return plantType, rarity The seed's type and rarity.
    function getSeedTraits(uint256 seedId) public view returns (PlantType plantType, Rarity rarity) {
         require(_seeds[seedId].mintedAt != 0, "Not a valid seed token");
         SeedData storage seed = _seeds[seedId];
         return (seed.plantType, seed.rarity);
    }

    /// @notice Returns detailed status information for a Plant.
    /// @param plantId The ID of the Plant NFT.
    /// @return state, plantedAt, lastFedAt, lastStateChangeAt, plantType, rarity
    function getPlantStatus(uint256 plantId) public view returns (PlantState state, uint256 plantedAt, uint256 lastFedAt, uint256 lastStateChangeAt, PlantType plantType, Rarity rarity) {
        require(_plants[plantId].plantedAt != 0, "Not a valid plant token");
        PlantData storage plant = _plants[plantId];
        return (plant.state, plant.plantedAt, plant.lastFedAt, plant.lastStateChangeAt, plant.plantType, plant.rarity);
    }

     /// @notice Gets all Plant token IDs owned by a user.
     /// @param user The address of the user.
     /// @return An array of Plant token IDs.
    function getUserPlants(address user) public view returns (uint256[] memory) {
        return _userPlants[user];
    }

     /// @notice Gets all Seed token IDs owned by a user.
     /// @param user The address of the user.
     /// @return An array of Seed token IDs.
    function getUserSeeds(address user) public view returns (uint256[] memory) {
        return _userSeeds[user];
    }

    /// @notice Returns the total number of Seed NFTs minted.
    function totalSupplySeeds() public view returns (uint256) {
        return _seedSupply.current();
    }

    /// @notice Returns the total number of Plant NFTs currently active.
    function totalSupplyPlants() public view returns (uint256) {
        return _plantSupply.current();
    }

    // --- Admin Functions ---

    /// @notice Sets parameters related to plant growth stages, costs, and harvest yields.
    /// @param _stagesDuration Array of durations for stages (Germinating, Young, Growing, Mature).
    /// @param _stagesNutrientCost Array of nutrient costs for stages.
    /// @param _harvestYieldBounds Array [minYield, maxYield] for mature plant harvest.
    function setGrowthParameters(uint256[] calldata _stagesDuration, uint256[] calldata _stagesNutrientCost, uint256[] calldata _harvestYieldBounds) public onlyOwner {
        require(_stagesDuration.length == 4, "Stages duration must have 4 elements"); // Corresponds to Germinating, Young, Growing, Mature stages
        require(_stagesNutrientCost.length == 4, "Stages nutrient cost must have 4 elements"); // Corresponds to Germinating, Young, Growing, Mature
        require(_harvestYieldBounds.length == 2, "Harvest yield bounds must have 2 elements [min, max]");
        require(_harvestYieldBounds[0] <= _harvestYieldBounds[1], "Min yield cannot exceed max yield");

        stagesDuration = _stagesDuration;
        stagesNutrientCost = _stagesNutrientCost;
        harvestYieldBounds = _harvestYieldBounds;

        emit ParametersUpdated();
    }

    /// @notice Sets the nutrient value gained from burning different item types.
    /// @param seedValue_ Nutrients from burning a Seed.
    /// @param plantValue_ Nutrients from burning a Plant.
    /// @param pruneValue_ Nutrients from pruning a Plant.
    function setNutrientValues(uint256 seedValue_, uint256 plantValue_, uint256 pruneValue_) public onlyOwner {
        nutrientValueSeed = seedValue_;
        nutrientValuePlant = plantValue_;
        nutrientValuePrune = pruneValue_;
        emit ParametersUpdated();
    }

    /// @notice Sets parameters for the cross-pollination mechanic.
    /// @param baseSeedYield_ Base number of seeds produced.
    /// @param minRarityBoostChance_ Minimum % chance for a rarity boost.
    /// @param maxRarityBoostChance_ Maximum % chance for a rarity boost (scales with parent rarity).
    function setCrossPollinationParameters(uint256 baseSeedYield_, uint256 minRarityBoostChance_, uint256 maxRarityBoostChance_) public onlyOwner {
        crossPollinationBaseSeedYield = baseSeedYield_;
        require(minRarityBoostChance_ <= 100 && maxRarityBoostChance_ <= 100, "Chance must be <= 100");
        require(minRarityBoostChance_ <= maxRarityBoostChance_, "Min chance cannot exceed max chance");
        crossPollinationMinRarityBoostChance = minRarityBoostChance_;
        crossPollinationMaxRarityBoostChance = maxRarityBoostChance_;
        emit ParametersUpdated();
    }

    /// @notice Pauses core contract functionalities.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses core contract functionalities.
    function unpause() public onlyOwner {
        _unpause();
    }

     /// @notice Allows the owner to withdraw accumulated ETH from seed sales.
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }


    // --- ERC721 Metadata & Utility ---

    /// @notice Returns the metadata URI for a given token ID.
    /// Note: This is a placeholder. A real implementation would point to dynamic metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Basic placeholder metadata - ideally this would point to a service
        // or a more complex on-chain function generating dynamic attributes.
        string memory baseURI = "ipfs://YOUR_BASE_METADATA_URI/"; // Example base URI

        // You could differentiate metadata based on whether it's a Seed or Plant
         if (_seeds[tokenId].mintedAt != 0) {
             return string(abi.encodePacked(baseURI, "seed/", Strings.toString(tokenId)));
         } else if (_plants[tokenId].plantedAt != 0) {
             return string(abi.encodePacked(baseURI, "plant/", Strings.toString(tokenId)));
         } else {
             return string(abi.encodePacked(baseURI, "unknown/", Strings.toString(tokenId)));
         }
    }

    /// @notice Indicates which interfaces are supported.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(IOwnable).interfaceId ||
               interfaceId == type(IPausable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Internal/Helper Functions (Optional but Good Practice) ---
    // Functions like _addPlantToUserArray, _removePlantFromUserArray are already internal helpers.
    // Could add functions to calculate growth progress, estimate harvest yield etc.
}
```