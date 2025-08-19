Here's a Solidity smart contract for a "Synthetica Garden," an advanced-concept, dynamic NFT ecosystem. It avoids duplicating existing open-source projects by focusing on an integrated system of dynamic NFTs that interact, evolve, and consume resources in a simulated on-chain environment.

---

## SyntheticaGarden Smart Contract

**I. Outline:**

*   **Smart Contract Name:** `SyntheticaGarden`
*   **Core Concept:** A dynamic, self-evolving digital ecosystem where users cultivate "SynthOrganisms" (dynamic NFTs) that grow, interact, mutate, and reproduce based on on-chain "Genomes" and consume "SynthNutrients" (ERC-20 tokens).
*   **Key Features & Advanced Concepts:**
    *   **Dynamic NFTs:** Organism attributes (health, age, fertility) change over time and with interactions, reflecting a living entity.
    *   **On-Chain Ecology:** Mimics natural processes like growth, decay, reproduction, resource competition, and death, all managed by smart contract logic.
    *   **Generative Evolution:** Organisms possess a `uint256` "Genome" which can mutate during reproduction, leading to novel traits and the "discovery" of new "species."
    *   **Resource Dependency:** Organisms require `SynthNutrients` (ERC-20 tokens) to survive, grow, and reproduce, creating a crucial token sink and economic loop within the garden.
    *   **Incentivized State Transitions:** Functions like `processOrganismTick` are publicly callable and provide a minor incentive to the caller, decentralizing the maintenance and advancement of organism states.
    *   **Genome Hashing & Species Discovery:** Unique genomes can be algorithmically hashed to define distinct "species," and the first discoverer of a new species is rewarded.
    *   **Environmental Events:** The contract owner can trigger global environmental events that temporarily alter the garden's parameters, adding dynamic challenges or opportunities.

---

**II. Function Summary:**

**A. Core Setup & Administration**

1.  `constructor()`: Initializes the ERC-721 token for SynthOrganisms, the ERC-20 token for SynthNutrients, sets initial garden parameters, and mints an initial supply of nutrients.
2.  `setGardenParameter(GardenParameter param, uint256 value)`: Allows the contract owner to adjust global garden parameters (e.g., base growth rate, mutation chance, nutrient decay).
3.  `pauseGardenGrowth(bool _paused)`: Toggles a global pause/unpause for all time-based growth, decay, and environmental event mechanisms, useful for maintenance or specific events.
4.  `simulateGardenEvent(bytes32 eventHash, uint256 duration)`: Initiates a global environmental event (e.g., "drought," "abundance") that can temporarily modify organism parameters or garden rules.

**B. SynthNutrient (ERC-20) Management**

5.  `mintNutrients(address to, uint256 amount)`: Allows the owner to mint new `SynthNutrient` tokens, primarily for initial supply, ecosystem top-ups, or rewards.
6.  `burnNutrients(uint256 amount)`: Allows any user to burn their own `SynthNutrient` tokens, acting as a potential token sink.
7.  `transfer(address to, uint256 amount)`: Standard ERC-20 token transfer function.
8.  `approve(address spender, uint256 amount)`: Standard ERC-20 token approval function.
9.  `transferFrom(address from, address to, uint256 amount)`: Standard ERC-20 token transferFrom function.

**C. SynthOrganism (ERC-721) Lifecycle**

10. `plantSynthSeed(uint256 initialGenome)`: Mints a new `SynthOrganism` NFT for the caller. Requires a payment in `SynthNutrients` and provides an initial, potentially unique, genome.
11. `feedOrganism(uint256 organismId, uint256 nutrientAmount)`: Allows the owner of an organism to provide `SynthNutrients` to it, replenishing its internal health/growth pool and boosting its well-being. Includes a small fee for future `processOrganismTick` calls.
12. `processOrganismTick(uint256 organismId)`: A publicly callable function designed to advance an organism's internal clock and state. It consumes internal nutrients, updates health, age, and fertility. If health drops to zero, the organism dies. Callers receive a small reward for performing this state update.
13. `attemptReproduction(uint256 parent1Id, uint256 parent2Id)`: Allows owners of two compatible (alive, fertile) `SynthOrganisms` to attempt reproduction. This consumes nutrients from both parents and may mint a new `SynthSeed` NFT with a blended and potentially mutated genome.
14. `harvestNutrients(uint256 organismId)`: Allows the owner to extract a portion of stored `SynthNutrients` from a mature organism. This reduces the organism's health and fertility, potentially leading to its decay or death.
15. `pruneOrganism(uint256 organismId)`: Allows the owner to burn (destroy) a `SynthOrganism` NFT. This action might yield a small nutrient refund or specific "genetic material" depending on the organism's state at pruning.
16. `getOrganismDetails(uint256 organismId)`: A view function to retrieve all detailed attributes of a specific `SynthOrganism` (its genome, birth time, last growth update, current health, fertility, species hash, and alive status).
17. `getOrganismHealthStatus(uint256 organismId)`: A quick view function to check an organism's current health, last processed timestamp, and its projected decay rate.

**D. Advanced & Dynamic Mechanisms**

18. `getGenomeTraits(uint256 genome)`: A pure function that decodes a raw `uint256` genome into a more human-interpretable set of traits (e.g., size, color, resilience, growth modifier). This provides a structured view of the genetic data.
19. `getSpeciesHash(uint256 genome)`: A pure function that generates a unique `bytes32` hash for a given genome. This hash deterministically identifies a specific "species" based on its complete genetic makeup.
20. `registerNewSpecies(uint256 organismId)`: Allows an organism owner to register the unique genome of their organism as a newly "discovered" species within the garden. This function checks for uniqueness and rewards the first discoverer of a truly novel genetic combination.
21. `challengeSpeciesRegistration(bytes32 speciesHash)`: (Conceptual/Placeholder) Designed to allow users to challenge a registered species (e.g., if it's found not to be unique or valid). This would typically involve a staking mechanism or DAO vote for dispute resolution.
22. `getRegisteredSpeciesCount()`: A view function that returns the total count of unique `SynthOrganism` species that have been discovered and officially registered in the garden.
23. `getTopNHealthyOrganisms(uint256 n)`: A view function to retrieve a list of the IDs of the top N healthiest organisms currently alive in the garden. (Note: Can be gas-intensive for large N; typically handled off-chain for very large datasets).
24. `getOrganismsByOwner(address owner)`: A view function to retrieve all `SynthOrganism` NFT IDs currently owned by a specific address, leveraging the `ERC721Enumerable` extension.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Though solidity 0.8+ has built-in overflow checks, good practice for consistency

/// @title SyntheticaGarden
/// @notice A dynamic, self-evolving digital ecosystem where users cultivate "SynthOrganisms" (dynamic NFTs)
///         that grow, interact, mutate, and reproduce based on on-chain "Genomes" and consume "SynthNutrients" (ERC-20 tokens).
contract SyntheticaGarden is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly use SafeMath for older style, though 0.8+ handles overflow.

    // --- Events ---
    event SynthSeedPlanted(uint256 indexed organismId, address indexed owner, uint256 genome);
    event OrganismFed(uint256 indexed organismId, uint256 amount);
    event OrganismProcessed(uint256 indexed organismId, uint256 oldHealth, uint256 newHealth, uint256 healthLost, bool died);
    event ReproductionAttempted(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 newOrganismId, uint256 newGenome, bool success);
    event NutrientsHarvested(uint256 indexed organismId, uint256 amount);
    event OrganismPruned(uint256 indexed organismId);
    event NewSpeciesRegistered(bytes32 indexed speciesHash, uint256 indexed organismId, address indexed discoverer);
    event GardenParameterSet(GardenParameter indexed param, uint256 value);
    event GardenGrowthPaused(bool paused);
    event GardenEventSimulated(bytes32 indexed eventHash, uint256 duration);

    // --- State Variables ---

    // SynthOrganism ERC721 properties
    Counters.Counter private _organismIds;

    // SynthNutrient ERC20 token
    SynthNutrient public synthNutrient;

    // Mapping for Organism data
    struct Organism {
        uint256 genome;            // Packed genome data
        uint256 birthTime;         // Timestamp of creation
        uint256 lastGrowthTick;    // Last time processOrganismTick was called
        uint256 health;            // Current health (0-1000, 1000 being max)
        uint256 fertility;         // Current fertility (0-1000, 1000 being max)
        uint256 internalNutrients; // Nutrients stored within the organism for growth/survival
        bool alive;                // Is the organism still alive?
        bytes32 speciesHash;       // Cached species hash for quick lookup
    }
    mapping(uint256 => Organism) public organisms;

    // Garden Parameters (adjustable by owner)
    enum GardenParameter {
        PLANT_COST_NUTRIENTS,
        BASE_GROWTH_RATE,           // Nutrients consumed per tick (per unit health)
        BASE_HEALTH_DECAY_RATE,     // Health lost per tick (without nutrients)
        REPRODUCTION_COST_NUTRIENTS, // Nutrients required from each parent for reproduction
        MIN_REPRODUCTION_HEALTH,    // Minimum health for reproduction
        MIN_REPRODUCTION_FERTILITY, // Minimum fertility for reproduction
        MAX_ORGANISM_AGE,           // Max age in seconds before natural decay accelerates
        MUTATION_CHANCE_PERCENT,    // Chance of mutation during reproduction (e.g., 50 for 50%)
        MUTATION_SEVERITY_BITS,     // Max bits to flip/alter during mutation
        GROWTH_TICK_INCENTIVE       // Nutrients awarded to caller of processOrganismTick
    }
    mapping(GardenParameter => uint256) public gardenParameters;

    // Global garden state
    bool public gardenGrowthPaused;
    bytes32 public currentGardenEventHash;
    uint256 public currentGardenEventEndTime;

    // Species discovery
    mapping(bytes32 => bool) public isSpeciesRegistered;
    mapping(bytes32 => address) public speciesDiscoverer; // First discoverer of a species
    bytes32[] public registeredSpeciesHashes; // Array of discovered species hashes

    // --- Genome Structure & Interpretation (Conceptual) ---
    // A uint256 genome can be packed with multiple traits.
    // Example layout (32-bit segments):
    // Bits 0-31: Trait A (e.g., "Size" or "GrowthModifier")
    // Bits 32-63: Trait B (e.g., "Color" or "NutrientEfficiency")
    // Bits 64-95: Trait C (e.g., "Resilience" or "ReproductionRate")
    // Bits 96-127: Trait D (e.g., "Luminosity" or "MutationResistance")
    // ... up to 8 traits of 32 bits each.

    // Max values for organism attributes
    uint256 public constant MAX_HEALTH = 1000;
    uint256 public constant MAX_FERTILITY = 1000;
    uint256 public constant SECONDS_PER_TICK = 3600; // 1 hour for a tick

    // --- Constructor ---
    constructor(
        address initialOwner
    ) ERC721("SynthOrganism", "SYNTHO") Ownable(initialOwner) {
        synthNutrient = new SynthNutrient(address(this)); // Deploys the ERC20 token, controlled by this contract

        // Set initial garden parameters
        gardenParameters[GardenParameter.PLANT_COST_NUTRIENTS] = 100 * (10**synthNutrient.decimals());
        gardenParameters[GardenParameter.BASE_GROWTH_RATE] = 1; // Nutrients consumed per health point per tick
        gardenParameters[GardenParameter.BASE_HEALTH_DECAY_RATE] = 10; // Health points lost per tick if no nutrients
        gardenParameters[GardenParameter.REPRODUCTION_COST_NUTRIENTS] = 50 * (10**synthNutrient.decimals());
        gardenParameters[GardenParameter.MIN_REPRODUCTION_HEALTH] = 500;
        gardenParameters[GardenParameter.MIN_REPRODUCTION_FERTILITY] = 500;
        gardenParameters[GardenParameter.MAX_ORGANISM_AGE] = 30 days; // Organisms start accelerating decay after 30 days
        gardenParameters[GardenParameter.MUTATION_CHANCE_PERCENT] = 50; // 50% chance for mutation
        gardenParameters[GardenParameter.MUTATION_SEVERITY_BITS] = 2; // Up to 2 bits flipped in genome
        gardenParameters[GardenParameter.GROWTH_TICK_INCENTIVE] = 1 * (10**synthNutrient.decimals()); // 1 nutrient as reward

        // Mint initial nutrients to owner for testing/setup
        synthNutrient.mint(initialOwner, 100000 * (10**synthNutrient.decimals()));
    }

    // --- Owner-only Functions (Garden Management) ---

    /// @notice Sets a global parameter for the garden ecosystem.
    /// @param param The parameter to set (enum `GardenParameter`).
    /// @param value The new value for the parameter.
    function setGardenParameter(GardenParameter param, uint256 value) external onlyOwner {
        gardenParameters[param] = value;
        emit GardenParameterSet(param, value);
    }

    /// @notice Pauses or unpauses time-based growth and decay in the garden.
    /// @param _paused True to pause, false to unpause.
    function pauseGardenGrowth(bool _paused) external onlyOwner {
        gardenGrowthPaused = _paused;
        emit GardenGrowthPaused(_paused);
    }

    /// @notice Simulates a global environmental event that affects all organisms.
    /// @param eventHash A unique identifier for the event (e.g., keccak256("Drought")).
    /// @param duration The duration of the event in seconds.
    function simulateGardenEvent(bytes32 eventHash, uint256 duration) external onlyOwner {
        require(block.timestamp > currentGardenEventEndTime, "Previous event still active");
        currentGardenEventHash = eventHash;
        currentGardenEventEndTime = block.timestamp.add(duration);
        emit GardenEventSimulated(eventHash, duration);
    }

    // --- SynthNutrient (ERC-20) Management ---

    /// @notice Mints new SynthNutrient tokens. Only callable by the contract owner.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mintNutrients(address to, uint256 amount) external onlyOwner {
        synthNutrient.mint(to, amount);
    }

    /// @notice Allows a user to burn their own SynthNutrient tokens.
    /// @param amount The amount of tokens to burn.
    function burnNutrients(uint256 amount) external {
        synthNutrient.burn(msg.sender, amount);
    }

    // Standard ERC-20 functions are exposed via the public `synthNutrient` instance.
    // For convenience or direct calls:
    /// @notice Standard ERC-20 transfer function for SynthNutrients.
    function transfer(address to, uint256 amount) external returns (bool) {
        return synthNutrient.transfer(to, amount);
    }

    /// @notice Standard ERC-20 approve function for SynthNutrients.
    function approve(address spender, uint256 amount) external returns (bool) {
        return synthNutrient.approve(spender, amount);
    }

    /// @notice Standard ERC-20 transferFrom function for SynthNutrients.
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return synthNutrient.transferFrom(from, to, amount);
    }

    // --- SynthOrganism (ERC-721) Lifecycle ---

    /// @notice Plants a new SynthSeed, minting a new SynthOrganism NFT.
    /// @param initialGenome The initial genome for the new organism.
    function plantSynthSeed(uint256 initialGenome) external {
        uint256 plantCost = gardenParameters[GardenParameter.PLANT_COST_NUTRIENTS];
        require(synthNutrient.transferFrom(msg.sender, address(this), plantCost), "Insufficient nutrients or allowance.");

        _organismIds.increment();
        uint256 newId = _organismIds.current();

        bytes32 sHash = getSpeciesHash(initialGenome);

        organisms[newId] = Organism({
            genome: initialGenome,
            birthTime: block.timestamp,
            lastGrowthTick: block.timestamp,
            health: MAX_HEALTH,
            fertility: MAX_FERTILITY,
            internalNutrients: 0, // Starts with 0 internal nutrients, needs feeding
            alive: true,
            speciesHash: sHash
        });

        _safeMint(msg.sender, newId);
        emit SynthSeedPlanted(newId, msg.sender, initialGenome);
    }

    /// @notice Allows an organism's owner to feed it SynthNutrients to boost its health.
    /// @param organismId The ID of the organism to feed.
    /// @param nutrientAmount The amount of nutrients to provide.
    function feedOrganism(uint256 organismId, uint256 nutrientAmount) external {
        require(_isApprovedOrOwner(msg.sender, organismId), "Not organism owner or approved.");
        require(organisms[organismId].alive, "Organism is not alive.");
        require(nutrientAmount > 0, "Nutrient amount must be positive.");

        require(synthNutrient.transferFrom(msg.sender, address(this), nutrientAmount), "Insufficient nutrients or allowance.");

        // Add nutrients to organism's internal pool
        organisms[organismId].internalNutrients = organisms[organismId].internalNutrients.add(nutrientAmount);
        
        // Optionally, directly boost health or fertility slightly here based on nutrient quality/amount
        // organisms[organismId].health = Math.min(MAX_HEALTH, organisms[organismId].health.add(nutrientAmount / 10)); // Example

        emit OrganismFed(organismId, nutrientAmount);
    }

    /// @notice Publicly callable function to process an organism's state based on time elapsed.
    ///         Anyone can call this to help advance the garden's simulation, and receive a reward.
    /// @param organismId The ID of the organism to process.
    function processOrganismTick(uint256 organismId) external {
        Organism storage organism = organisms[organismId];
        require(organism.alive, "Organism is not alive.");
        require(!gardenGrowthPaused, "Garden growth is paused.");

        uint256 timeElapsed = block.timestamp.sub(organism.lastGrowthTick);
        if (timeElapsed < SECONDS_PER_TICK && timeElapsed > 0) return; // Only process if enough time passed, or if it's the very first tick

        uint256 ticks = timeElapsed.div(SECONDS_PER_TICK);
        if (ticks == 0) return; // No full ticks elapsed

        uint256 oldHealth = organism.health;
        uint256 healthLost = 0;
        bool died = false;

        // Calculate health changes based on internal nutrients and decay rates
        uint256 baseGrowthRate = gardenParameters[GardenParameter.BASE_GROWTH_RATE];
        uint256 baseHealthDecayRate = gardenParameters[GardenParameter.BASE_HEALTH_DECAY_RATE];
        uint256 maxAge = gardenParameters[GardenParameter.MAX_ORGANISM_AGE];

        uint256 effectiveDecayRate = baseHealthDecayRate;
        if (block.timestamp > organism.birthTime.add(maxAge)) {
            effectiveDecayRate = effectiveDecayRate.mul(2); // Accelerated decay for old organisms
        }
        
        // Apply environmental event effects if active
        if (block.timestamp < currentGardenEventEndTime) {
            // Example: If currentGardenEventHash is keccak256("Drought"), increase decay
            if (currentGardenEventHash == keccak256(abi.encodePacked("Drought"))) {
                effectiveDecayRate = effectiveDecayRate.mul(2);
            }
            // Example: If currentGardenEventHash is keccak256("Abundance"), decrease decay
            else if (currentGardenEventHash == keccak256(abi.encodePacked("Abundance"))) {
                effectiveDecayRate = effectiveDecayRate.div(2);
            }
        }

        uint256 requiredNutrientsPerTick = baseGrowthRate; // Simple model: 1 nutrient per health point to maintain
        uint256 healthChange = 0;

        for (uint256 i = 0; i < ticks; i++) {
            if (organism.internalNutrients >= requiredNutrientsPerTick) {
                organism.internalNutrients = organism.internalNutrients.sub(requiredNutrientsPerTick);
                // Health maintains or slowly increases
                organism.health = Math.min(MAX_HEALTH, organism.health.add(1)); // Slow growth
            } else {
                // Decay if not enough nutrients
                healthChange = effectiveDecayRate;
                if (organism.health > healthChange) {
                    organism.health = organism.health.sub(healthChange);
                } else {
                    organism.health = 0;
                }
                healthLost = healthLost.add(healthChange);
            }
        }
        
        // Adjust fertility based on health and age
        if (organism.health == 0) {
            organism.alive = false;
            organism.fertility = 0;
            died = true;
            // Transfer any remaining internal nutrients to owner or burn
            if (organism.internalNutrients > 0) {
                synthNutrient.transfer(ownerOf(organismId), organism.internalNutrients);
                organism.internalNutrients = 0;
            }
        } else {
            // Fertility naturally decays over time but can be recovered by high health / feeding
            organism.fertility = Math.max(0, organism.fertility.sub(ticks.mul(1))); // Small decay
            organism.fertility = Math.min(MAX_FERTILITY, organism.fertility.add(organism.health.div(100))); // Health correlation
        }

        organism.lastGrowthTick = organism.lastGrowthTick.add(ticks.mul(SECONDS_PER_TICK));

        // Incentivize caller
        uint256 incentive = gardenParameters[GardenParameter.GROWTH_TICK_INCENTIVE];
        if (incentive > 0) {
            synthNutrient.transfer(msg.sender, incentive);
        }
        
        emit OrganismProcessed(organismId, oldHealth, organism.health, healthLost, died);
    }

    /// @notice Attempts to reproduce two SynthOrganisms, potentially creating a new one.
    /// @param parent1Id The ID of the first parent organism.
    /// @param parent2Id The ID of the second parent organism.
    function attemptReproduction(uint256 parent1Id, uint256 parent2Id) external {
        require(_isApprovedOrOwner(msg.sender, parent1Id), "Not owner or approved for parent 1.");
        require(_isApprovedOrOwner(msg.sender, parent2Id), "Not owner or approved for parent 2.");
        require(parent1Id != parent2Id, "Cannot reproduce with self.");

        Organism storage parent1 = organisms[parent1Id];
        Organism storage parent2 = organisms[parent2Id];

        require(parent1.alive && parent2.alive, "Both parents must be alive.");
        require(parent1.health >= gardenParameters[GardenParameter.MIN_REPRODUCTION_HEALTH], "Parent 1 health too low.");
        require(parent2.health >= gardenParameters[GardenParameter.MIN_REPRODUCTION_HEALTH], "Parent 2 health too low.");
        require(parent1.fertility >= gardenParameters[GardenParameter.MIN_REPRODUCTION_FERTILITY], "Parent 1 fertility too low.");
        require(parent2.fertility >= gardenParameters[GardenParameter.MIN_REPRODUCTION_FERTILITY], "Parent 2 fertility too low.");

        uint256 reproductionCost = gardenParameters[GardenParameter.REPRODUCTION_COST_NUTRIENTS];
        require(synthNutrient.transferFrom(msg.sender, address(this), reproductionCost.mul(2)), "Insufficient nutrients or allowance for reproduction.");

        // Reduce parents' fertility and health after reproduction
        parent1.fertility = parent1.fertility.div(2); // Halve fertility
        parent2.fertility = parent2.fertility.div(2);
        parent1.health = parent1.health.div(2); // Reduce health
        parent2.health = parent2.health.div(2);

        // --- Genome Blending and Mutation ---
        uint256 newGenome = _blendGenomes(parent1.genome, parent2.genome);

        // Apply mutation chance
        if (_getRandomNumber(block.timestamp, parent1Id, parent2Id) % 100 < gardenParameters[GardenParameter.MUTATION_CHANCE_PERCENT]) {
            newGenome = _applyMutation(newGenome);
        }

        _organismIds.increment();
        uint256 newId = _organismIds.current();

        bytes32 sHash = getSpeciesHash(newGenome);

        organisms[newId] = Organism({
            genome: newGenome,
            birthTime: block.timestamp,
            lastGrowthTick: block.timestamp,
            health: MAX_HEALTH,
            fertility: MAX_FERTILITY,
            internalNutrients: 0,
            alive: true,
            speciesHash: sHash
        });

        _safeMint(msg.sender, newId);
        emit ReproductionAttempted(parent1Id, parent2Id, newId, newGenome, true);
    }

    /// @notice Allows the owner to harvest SynthNutrients from a mature organism.
    /// @param organismId The ID of the organism to harvest from.
    function harvestNutrients(uint256 organismId) external {
        require(_isApprovedOrOwner(msg.sender, organismId), "Not organism owner or approved.");
        require(organisms[organismId].alive, "Organism is not alive.");
        require(organisms[organismId].internalNutrients > 0, "No nutrients to harvest.");

        uint256 harvestedAmount = organisms[organismId].internalNutrients.div(2); // Harvest half
        organisms[organismId].internalNutrients = organisms[organismId].internalNutrients.sub(harvestedAmount);
        
        // Optionally reduce health/fertility further based on harvesting intensity
        organisms[organismId].health = organisms[organismId].health.div(2);
        organisms[organismId].fertility = organisms[organismId].fertility.div(2);

        synthNutrient.transfer(msg.sender, harvestedAmount);
        emit NutrientsHarvested(organismId, harvestedAmount);

        // Trigger decay check if health drops critically low
        if (organisms[organismId].health <= 100) {
            processOrganismTick(organismId);
        }
    }

    /// @notice Allows the owner to prune (burn) an organism.
    /// @param organismId The ID of the organism to prune.
    function pruneOrganism(uint256 organismId) external {
        require(_isApprovedOrOwner(msg.sender, organismId), "Not organism owner or approved.");
        require(organisms[organismId].alive, "Organism is already dead or pruned.");

        // Optionally, refund some nutrients or issue genetic material
        if (organisms[organismId].internalNutrients > 0) {
            synthNutrient.transfer(msg.sender, organisms[organismId].internalNutrients);
        }

        // Mark as dead and clear internal nutrients for safety
        organisms[organismId].alive = false;
        organisms[organismId].internalNutrients = 0;
        organisms[organismId].health = 0; // Explicitly set to 0

        _burn(organismId); // ERC721 burn
        emit OrganismPruned(organismId);
    }

    /// @notice Retrieves all detailed attributes of a specific SynthOrganism.
    /// @param organismId The ID of the organism.
    /// @return genome The organism's genome.
    /// @return birthTime The timestamp of its creation.
    /// @return lastGrowthTick The timestamp of its last processing tick.
    /// @return health The current health (0-MAX_HEALTH).
    /// @return fertility The current fertility (0-MAX_FERTILITY).
    /// @return internalNutrients The amount of internal nutrients.
    /// @return alive Whether the organism is currently alive.
    /// @return speciesHash The cached species hash of the organism.
    function getOrganismDetails(uint256 organismId)
        external
        view
        returns (
            uint256 genome,
            uint256 birthTime,
            uint256 lastGrowthTick,
            uint256 health,
            uint256 fertility,
            uint256 internalNutrients,
            bool alive,
            bytes32 speciesHash
        )
    {
        Organism storage organism = organisms[organismId];
        return (
            organism.genome,
            organism.birthTime,
            organism.lastGrowthTick,
            organism.health,
            organism.fertility,
            organism.internalNutrients,
            organism.alive,
            organism.speciesHash
        );
    }

    /// @notice Checks an organism's current health status and last processed tick.
    /// @param organismId The ID of the organism.
    /// @return currentHealth The organism's current health.
    /// @return lastProcessed The timestamp of the last time it was processed.
    /// @return timeSinceLastTick The time in seconds since its last processing.
    function getOrganismHealthStatus(uint256 organismId)
        external
        view
        returns (uint256 currentHealth, uint256 lastProcessed, uint256 timeSinceLastTick)
    {
        Organism storage organism = organisms[organismId];
        currentHealth = organism.health;
        lastProcessed = organism.lastGrowthTick;
        timeSinceLastTick = block.timestamp.sub(organism.lastGrowthTick);
    }

    // --- Advanced & Dynamic Mechanisms ---

    /// @notice Decodes a raw uint256 genome into its constituent traits.
    /// @param genome The raw uint256 genome.
    /// @return traits A struct containing decoded traits (example values).
    function getGenomeTraits(uint256 genome)
        public
        pure
        returns (
            uint32 size,
            uint32 color,
            uint32 resilience,
            uint32 fertilityModifier,
            uint32 growthRateModifier,
            uint32 nutrientEfficiency
        )
    {
        // Example decoding: 32 bits per trait
        size = uint32(genome & 0xFFFFFFFF);
        color = uint32((genome >> 32) & 0xFFFFFFFF);
        resilience = uint32((genome >> 64) & 0xFFFFFFFF);
        fertilityModifier = uint32((genome >> 96) & 0xFFFFFFFF);
        growthRateModifier = uint32((genome >> 128) & 0xFFFFFFFF);
        nutrientEfficiency = uint32((genome >> 160) & 0xFFFFFFFF);
    }

    /// @notice Generates a unique species hash for a given genome.
    /// @param genome The genome to hash.
    /// @return A bytes32 hash representing the species.
    function getSpeciesHash(uint256 genome) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(genome));
    }

    /// @notice Allows an organism owner to register the unique genome of their organism as a new species.
    /// @param organismId The ID of the organism whose genome is to be registered.
    function registerNewSpecies(uint256 organismId) external {
        require(_isApprovedOrOwner(msg.sender, organismId), "Not organism owner or approved.");

        bytes32 species = organisms[organismId].speciesHash;
        require(!isSpeciesRegistered[species], "Species already registered.");

        isSpeciesRegistered[species] = true;
        speciesDiscoverer[species] = msg.sender;
        registeredSpeciesHashes.push(species);

        // Optionally reward the discoverer
        synthNutrient.mint(msg.sender, 100 * (10**synthNutrient.decimals())); // Example reward

        emit NewSpeciesRegistered(species, organismId, msg.sender);
    }

    /// @notice (Conceptual Placeholder) Allows challenging a registered species if it's found not to be unique or valid.
    ///         Would require a more complex dispute resolution mechanism (e.g., staking, DAO vote).
    /// @param speciesHash The hash of the species to challenge.
    function challengeSpeciesRegistration(bytes32 speciesHash) external pure {
        // This function is a placeholder for a more complex dispute mechanism.
        // In a real dApp, this might involve:
        // - Requiring a stake from the challenger.
        // - Triggering a community vote or oracle review.
        // - Slashing stakes or rewarding correct challenges.
        revert("Challenge mechanism not fully implemented in this example.");
    }

    /// @notice Returns the total count of unique species registered in the garden.
    function getRegisteredSpeciesCount() external view returns (uint256) {
        return registeredSpeciesHashes.length;
    }

    /// @notice Retrieves a list of the top N healthiest organisms.
    /// @dev This function can be very gas-intensive for large N or many organisms.
    ///      For production, consider off-chain indexing for large queries.
    /// @param n The number of top organisms to retrieve.
    /// @return An array of organism IDs.
    function getTopNHealthyOrganisms(uint256 n) external view returns (uint256[] memory) {
        uint256 totalOrganisms = _organismIds.current();
        if (totalOrganisms == 0 || n == 0) {
            return new uint256[](0);
        }

        uint256[] memory organismHealths = new uint256[](totalOrganisms);
        uint256[] memory organismIds = new uint256[](totalOrganisms);
        uint256 currentIdx = 0;

        for (uint256 i = 1; i <= totalOrganisms; i++) {
            if (organisms[i].alive) {
                organismHealths[currentIdx] = organisms[i].health;
                organismIds[currentIdx] = i;
                currentIdx++;
            }
        }

        // Simple bubble sort for demonstration. Not efficient for large N.
        for (uint256 i = 0; i < currentIdx; i++) {
            for (uint256 j = i + 1; j < currentIdx; j++) {
                if (organismHealths[i] < organismHealths[j]) {
                    uint256 tempHealth = organismHealths[i];
                    organismHealths[i] = organismHealths[j];
                    organismHealths[j] = tempHealth;

                    uint256 tempId = organismIds[i];
                    organismIds[i] = organismIds[j];
                    organismIds[j] = tempId;
                }
            }
        }

        uint256 returnCount = n < currentIdx ? n : currentIdx;
        uint256[] memory topOrganismIds = new uint256[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            topOrganismIds[i] = organismIds[i];
        }
        return topOrganismIds;
    }

    /// @notice Returns all organism IDs owned by a specific address.
    /// @param owner The address of the owner.
    /// @return An array of organism IDs.
    function getOrganismsByOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner); // Utilizes ERC721Enumerable's internal function
    }

    // --- Internal / Pure Helper Functions ---

    /// @notice Blends two parent genomes to create a new one.
    /// @dev This is a simplified blending. More complex algorithms could be used.
    function _blendGenomes(uint256 genome1, uint256 genome2) internal pure returns (uint256) {
        // Simple blend: average of each 32-bit segment or random choice
        uint256 newGenome = 0;
        for (uint256 i = 0; i < 8; i++) { // Assuming 8 traits of 32 bits each
            uint256 mask = 0xFFFFFFFF << (i * 32);
            uint256 trait1 = (genome1 & mask);
            uint256 trait2 = (genome2 & mask);

            // Simple averaging, or coin flip for which parent's trait to inherit
            if (_getRandomNumber(i, genome1, genome2) % 2 == 0) {
                 newGenome |= trait1;
            } else {
                 newGenome |= trait2;
            }
        }
        return newGenome;
    }

    /// @notice Applies a mutation to a genome.
    /// @dev This is a simplified mutation (random bit flips within traits).
    function _applyMutation(uint256 genome) internal view returns (uint256) {
        uint256 severity = gardenParameters[GardenParameter.MUTATION_SEVERITY_BITS];
        uint256 newGenome = genome;

        for (uint256 i = 0; i < severity; i++) {
            uint256 randomBitPosition = _getRandomNumber(block.timestamp.add(i), genome, severity) % 256;
            newGenome ^= (1 << randomBitPosition); // Flip a random bit
        }
        return newGenome;
    }

    /// @notice Generates a pseudo-random number using block data and input seeds.
    /// @dev Not cryptographically secure, but sufficient for in-game randomness.
    function _getRandomNumber(uint256 seed1, uint256 seed2, uint256 seed3) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed1, seed2, seed3)));
    }
}

/// @title SynthNutrient
/// @dev An ERC-20 token used as the primary resource within the SyntheticaGarden ecosystem.
contract SynthNutrient is ERC20 {
    address public gardenContract; // Address of the SyntheticaGarden contract

    constructor(address _gardenContract) ERC20("SynthNutrient", "SYNTHN") {
        gardenContract = _gardenContract;
    }

    /// @notice Mints new SynthNutrient tokens. Only callable by the SyntheticaGarden contract.
    /// @param to The address to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public {
        require(msg.sender == gardenContract, "Only the SyntheticaGarden contract can mint.");
        _mint(to, amount);
    }

    /// @notice Burns SynthNutrient tokens from a specified address. Only callable by the SyntheticaGarden contract.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) public {
        require(msg.sender == gardenContract || from == msg.sender, "Only the SyntheticaGarden contract or token owner can burn.");
        _burn(from, amount);
    }
}
```