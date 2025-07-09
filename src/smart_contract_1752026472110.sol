Okay, this is an exciting challenge! To create something advanced, creative, and *not* a direct copy of common open-source projects (like standard ERC20/721, basic DAOs, simple DeFi vaults), let's design a contract around a complex, evolving digital entity or ecosystem.

How about a "Cybernetic Organism Synthesizer"? This contract will manage unique, dynamic digital organisms represented by NFTs (or similar ID-based tokens). These organisms will have internal states (genes, traits, energy, health, age) that change over time and through user interaction.

Here's the plan:

**Concept:** **Cybernetic Organism Synthesizer (COS)**

*   **Core Idea:** A system that allows users to synthesize, nurture, evolve, and interact with unique digital life forms.
*   **Key Features:**
    *   **Dynamic State:** Organisms have mutable parameters (genes, traits, energy, health, age).
    *   **Time-Based Processes:** Organisms consume energy and age over time (requiring user "processing").
    *   **Evolution/Mutation:** Mechanisms (random simulation, user-driven) to alter genes and traits.
    *   **Reproduction:** Combining two organisms to potentially create a new one.
    *   **Interaction:** Simulated interactions between organisms affecting their state.
    *   **Resource Management:** Organisms need energy and health maintained by owners.
    *   **Gene Locking:** Owners can strategically protect certain genes from mutation.
    *   **Simulated Randomness:** Using block data (with caveats) for unpredictable events.
    *   **Owner-Triggered Processes:** Many state changes require owner intervention (`processOrganism`, `feed`, `heal`, `mutation`, etc.) to manage gas costs.

This avoids standard patterns by focusing on complex, interactive, dynamic state management for unique digital entities, integrating simulation mechanics directly into the smart contract logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Cybernetic Organism Synthesizer (COS)
 * @author Your Name/Alias (Imaginary Creator)
 * @notice A smart contract managing unique, dynamic digital organisms with evolving states,
 *         resource management, reproduction, mutation, and interaction mechanisms.
 *         This is a complex, experimental concept not intended for production use
 *         without extensive auditing and optimization.
 *
 * @dev Disclaimer on Randomness: The contract uses block data (block.timestamp, block.difficulty, block.number)
 *      for simulated randomness. This is predictable to miners and unsuitable for
 *      high-security or high-value applications requiring true unpredictability.
 *      A production system would require a secure oracle like Chainlink VRF.
 *
 * @dev Gas Costs: Due to the complexity of state processing and array manipulations,
 *      many functions can be gas-intensive. Processing organisms, reproduction,
 *      and retrieving lists of tokens by owner can be particularly costly.
 */

/*
 * CONTRACT OUTLINE & FUNCTION SUMMARY
 *
 * 1. Data Structures (Structs)
 *    - OrganismState: Holds all dynamic data for a single organism.
 *
 * 2. State Variables
 *    - organismCounter: Total number of organisms created.
 *    - organisms: Mapping from token ID (uint256) to OrganismState.
 *    - organismOwners: Mapping from token ID to owner address (basic ownership tracking).
 *    - ownerTokenIds: Mapping from owner address to array of token IDs (for querying).
 *    - global parameters: mutation rates, costs, viability thresholds, etc.
 *    - contractOwner: Address with administrative privileges.
 *
 * 3. Events
 *    - OrganismSynthesized: Emitted when a new organism is created.
 *    - OrganismStateProcessed: Emitted after time-based state updates (metabolism, aging).
 *    - OrganismFed: Emitted when energy is added.
 *    - OrganismHealed: Emitted when health is restored.
 *    - OrganismMutated: Emitted when genes or traits change due to mutation.
 *    - OrganismReproduced: Emitted when reproduction is successful, creating a new organism.
 *    - OrganismInteracted: Emitted after a simulated interaction.
 *    - OrganismTraitEvolved: Emitted after owner-driven trait change.
 *    - OrganismGeneLocked: Emitted when a gene's mutation status is locked/unlocked.
 *    - OrganismTransferred: Emitted after ownership transfer.
 *    - OrganismDeceased: Emitted when an organism's viability drops to zero.
 *    - AdminParameterUpdated: Emitted when a global parameter is changed by the owner.
 *    - FeesWithdrawn: Emitted when contract owner withdraws collected fees.
 *
 * 4. Modifiers
 *    - onlyOwner: Restricts function calls to the contract owner.
 *    - organismExists: Checks if a given token ID corresponds to an existing organism.
 *    - onlyOwnerOfOrganism: Checks if the caller owns the specified organism.
 *    - organismActive: Checks if the organism is currently active (not deceased).
 *
 * 5. Internal Helper Functions
 *    - _generateInitialGenes: Creates genes for a new organism.
 *    - _generateInitialTraits: Creates traits based on initial genes.
 *    - _processOrganismStateLogic: Core time-based update logic.
 *    - _attemptGeneMutation: Logic for mutating genes.
 *    - _combineGenes: Logic for combining parent genes during reproduction.
 *    - _deriveTraitsFromGenes: Logic to recalculate traits from genes.
 *    - _addTokenToOwner: Internal function to add token ID to owner's list.
 *    - _removeTokenFromOwner: Internal function to remove token ID from owner's list.
 *    - _transferOrganismInternal: Handles internal state changes for transfer.
 *    - _getRandomUint: Helper for simulated randomness (DISCLAIMER applies).
 *
 * 6. Public/External Functions (Approx. 24 functions)
 *    - constructor(): Sets initial global parameters.
 *    - createGenesisOrganism() payable: Creates the very first organism.
 *    - processOrganism(uint256 tokenId) external: Triggers time-based state update for an organism.
 *    - feedOrganism(uint256 tokenId) payable external: Adds energy to an organism.
 *    - healOrganism(uint256 tokenId) payable external: Restores health to an organism.
 *    - attemptMutation(uint256 tokenId) payable external: Attempts to mutate organism's genes/traits.
 *    - attemptReproduction(uint256 parent1Id, uint256 parent2Id) payable external: Attempts to create a new organism from two parents.
 *    - simulateInteraction(uint256 organism1Id, uint256 organism2Id) payable external: Simulates an interaction between two organisms.
 *    - evolveTrait(uint256 tokenId, uint256 traitIndex, int256 valueDelta) payable external: Allows owner to influence a specific trait.
 *    - setGeneLock(uint256 tokenId, uint256 geneIndex, bool locked) payable external: Locks or unlocks a specific gene against mutation.
 *    - transferOrganism(address to, uint256 tokenId) external: Transfers ownership of an organism.
 *    - getOrganismState(uint256 tokenId) view external: Retrieves the full state of an organism.
 *    - getOrganismGenes(uint256 tokenId) view external: Retrieves just the genes.
 *    - getOrganismTraits(uint256 tokenId) view external: Retrieves just the traits.
 *    - getOrganismOwner(uint256 tokenId) view external: Retrieves the owner of an organism.
 *    - getTotalOrganisms() view external: Retrieves the total count of organisms.
 *    - getOrganismsByOwner(address owner) view external: Retrieves all token IDs owned by an address.
 *    - checkOrganismViability(uint256 tokenId) view external: Checks if an organism is currently active.
 *    - checkReproductionEligibility(uint256 parent1Id, uint256 parent2Id) view external: Checks if two organisms meet basic reproduction criteria.
 *    - isGeneLocked(uint256 tokenId, uint256 geneIndex) view external: Checks if a specific gene is locked.
 *    - getGlobalEnvironmentalFactor() view external: Retrieves the current global environmental factor.
 *    - getGlobalMutationRate() view external: Retrieves the current global mutation rate.
 *    - setGlobalEnvironmentalFactor(uint256 newFactor) external onlyOwner: Updates the global environmental factor.
 *    - setGlobalMutationRate(uint256 newRate) external onlyOwner: Updates the global mutation rate.
 *    - withdrawFees() external onlyOwner: Allows contract owner to withdraw accumulated ETH.
 */


// --- 1. Data Structures ---

struct OrganismState {
    uint256[] genes;           // Fundamental, relatively stable characteristics
    uint256[] traits;          // Derived or acquired characteristics (can change more easily)
    uint256 energy;            // Resource consumed by processes
    uint256 health;            // Represents overall condition/viability
    uint256 age;               // Time elapsed since creation (e.g., in seconds)
    uint256 lastProcessedTime; // Timestamp of the last state update
    bool isActive;             // True if the organism is alive and functioning
    mapping(uint256 => bool) geneLocks; // Mapping to lock specific gene indices from mutation
}


// --- 2. State Variables ---

uint256 private organismCounter; // Starts at 0, increments for each new organism

// Main storage for organism data
mapping(uint256 => OrganismState) private organisms;

// Basic ownership mapping (like ERC721 ownerOf)
mapping(uint256 => address) private organismOwners;

// Mapping to track tokens owned by an address (for getOrganismsByOwner)
mapping(address => uint256[]) private ownerTokenIds;

// Global simulation parameters (configurable by owner)
uint256 public globalMutationRate; // Controls probability of mutation
uint256 public globalEnergyDecayRate; // Energy lost per unit of time/processing
uint256 public globalHealthDecayRate; // Health lost per unit of time/processing
uint256 public globalEnvironmentalFactor; // Abstract factor influencing processes

// Costs for actions (in wei)
uint256 public feedCost;
uint256 public healCost;
uint256 public mutationCost;
uint256 public reproductionCost;
uint256 public interactionCost;
uint256 public geneLockCost;
uint256 public traitEvolutionCost;

// Thresholds
uint256 public constant MAX_ENERGY = 1000; // Maximum possible energy
uint256 public constant MAX_HEALTH = 100;  // Maximum possible health
uint256 public constant MIN_VIABLE_HEALTH = 10; // Minimum health to be active
uint256 public constant MIN_VIABLE_ENERGY = 50;  // Minimum energy to be active
uint256 public constant GENE_COUNT = 8;    // Number of genes per organism
uint256 public constant TRAIT_COUNT = 5;   // Number of traits per organism
uint256 public constant MAX_GENE_VALUE = 100; // Max value for a gene
uint256 public constant MAX_TRAIT_VALUE = 200; // Max value for a trait
uint256 public constant MAX_EVOLUTION_DELTA = 10; // Max trait change per evolve call

address private contractOwner;


// --- 3. Events ---

event OrganismSynthesized(uint256 indexed tokenId, address indexed owner, uint256 genesisBlock);
event OrganismStateProcessed(uint256 indexed tokenId, uint256 energy, uint256 health, uint256 age, bool isActive);
event OrganismFed(uint256 indexed tokenId, uint256 energyAdded, uint256 currentEnergy);
event OrganismHealed(uint256 indexed tokenId, uint256 healthAdded, uint256 currentHealth);
event OrganismMutated(uint256 indexed tokenId, uint256[] newGenes, uint256[] newTraits);
event OrganismReproduced(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed newOrganismId, address owner);
event OrganismInteracted(uint256 indexed organism1Id, uint256 indexed organism2Id, string description);
event OrganismTraitEvolved(uint256 indexed tokenId, uint256 traitIndex, int256 valueDelta, uint256 newValue);
event OrganismGeneLocked(uint256 indexed tokenId, uint256 geneIndex, bool locked);
event OrganismTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
event OrganismDeceased(uint256 indexed tokenId, uint256 finalAge);
event AdminParameterUpdated(string paramName, uint256 newValue);
event FeesWithdrawn(address indexed to, uint256 amount);


// --- 4. Modifiers ---

modifier onlyOwner() {
    require(msg.sender == contractOwner, "COS: Not contract owner");
    _;
}

modifier organismExists(uint256 tokenId) {
    require(organismOwners[tokenId] != address(0), "COS: Organism does not exist");
    _;
}

modifier onlyOwnerOfOrganism(uint256 tokenId) {
    require(organismOwners[tokenId] == msg.sender, "COS: Not organism owner");
    _;
}

modifier organismActive(uint256 tokenId) {
    require(organisms[tokenId].isActive, "COS: Organism is not active");
    _;
}


// --- 5. Internal Helper Functions ---

/**
 * @dev Generates initial genes for a new organism.
 *      Uses simulated randomness (block data - see disclaimer).
 */
function _generateInitialGenes() internal view returns (uint256[] memory) {
    uint256[] memory genes = new uint256[](GENE_COUNT);
    uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, organismCounter)));
    for (uint256 i = 0; i < GENE_COUNT; i++) {
        seed = uint256(keccak256(abi.encodePacked(seed, i)));
        genes[i] = (seed % MAX_GENE_VALUE) + 1; // Ensure genes are non-zero within max
    }
    return genes;
}

/**
 * @dev Derives initial traits based on genes.
 *      Simple linear mapping for demonstration. More complex logic possible.
 */
function _generateInitialTraits(uint256[] memory genes) internal pure returns (uint256[] memory) {
    uint256[] memory traits = new uint256[](TRAIT_COUNT);
    // Example derivation: Traits are sum/average of pairs of genes
    traits[0] = (genes[0] + genes[1]) % MAX_TRAIT_VALUE;
    traits[1] = (genes[2] + genes[3]) % MAX_TRAIT_VALUE;
    traits[2] = (genes[4] + genes[5]) % MAX_TRAIT_VALUE;
    traits[3] = (genes[6] + genes[7]) % MAX_TRAIT_VALUE;
    traits[4] = (genes[0] + genes[7] + genes[3]) % MAX_TRAIT_VALUE; // More complex
    return traits;
}

/**
 * @dev Core logic for processing time-based state updates (metabolism, aging).
 *      Calculates decay based on time elapsed and global/organism factors.
 */
function _processOrganismStateLogic(OrganismState storage org) internal {
    uint256 currentTime = block.timestamp;
    uint256 timeElapsed = currentTime - org.lastProcessedTime;

    if (timeElapsed == 0 || !org.isActive) {
        return; // No time passed or already inactive
    }

    // Apply energy decay (minimum decay even with max energy)
    uint256 energyDecay = (timeElapsed * globalEnergyDecayRate) / 1000; // Scale rate
    if (org.energy < energyDecay) {
         org.energy = 0;
    } else {
         org.energy -= energyDecay;
    }


    // Apply health decay (higher decay if energy is low, influenced by env factor)
    uint256 healthDecay = (timeElapsed * globalHealthDecayRate * (MAX_ENERGY - org.energy + 1)) / (MAX_ENERGY * 1000); // Scale rate and inversely proportional to energy
    healthDecay = (healthDecay * globalEnvironmentalFactor) / 100; // Environmental influence

    if (org.health < healthDecay) {
        org.health = 0;
    } else {
        org.health -= healthDecay;
    }

    // Increase age
    org.age += timeElapsed;

    // Check viability
    if (org.health < MIN_VIABLE_HEALTH || org.energy < MIN_VIABLE_ENERGY) {
        org.isActive = false;
        emit OrganismDeceased(organismCounter, org.age); // Note: This might be slightly off if death happens *during* processing
    }

    // Update last processed time
    org.lastProcessedTime = currentTime;

    emit OrganismStateProcessed(organismCounter, org.energy, org.health, org.age, org.isActive);
}

/**
 * @dev Attempts to apply mutation to organism's genes.
 *      Uses simulated randomness (block data - see disclaimer).
 */
function _attemptGeneMutation(OrganismState storage org) internal returns (bool mutated) {
    uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, org.age)));
    bool occurred = false;

    for (uint256 i = 0; i < GENE_COUNT; i++) {
        if (!org.geneLocks[i]) { // Only mutate if gene is not locked
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            // Simplified random chance check based on globalMutationRate
            if ((seed % 1000) < globalMutationRate) { // e.g., rate 50 = 5% chance per gene
                // Apply a small random change to the gene value
                int256 delta = (int256(seed % 20) - 10); // Random delta between -10 and +9
                int256 newGeneValue = int256(org.genes[i]) + delta;
                org.genes[i] = uint256(Math.max(1, Math.min(int256(MAX_GENE_VALUE), newGeneValue))); // Clamp between 1 and MAX_GENE_VALUE
                occurred = true;
            }
        }
    }

    if (occurred) {
        // Recalculate traits after mutation
        org.traits = _deriveTraitsFromGenes(org.genes);
        mutated = true;
    }
    return mutated;
}

/**
 * @dev Combines genes from two parents for reproduction.
 *      Simple combination logic (e.g., alternating or averaging).
 */
function _combineGenes(uint256[] memory genes1, uint256[] memory genes2) internal view returns (uint256[] memory) {
    require(genes1.length == GENE_COUNT && genes2.length == GENE_COUNT, "COS: Invalid gene length");
    uint256[] memory childGenes = new uint256[](GENE_COUNT);
    uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, genes1[0], genes2[0])));

    for (uint256 i = 0; i < GENE_COUNT; i++) {
        seed = uint256(keccak256(abi.encodePacked(seed, i)));
        // Simple combination: randomly pick gene from parent1 or parent2
        if (seed % 2 == 0) {
            childGenes[i] = genes1[i];
        } else {
            childGenes[i] = genes2[i];
        }

        // Add a small chance of mutation during reproduction
        if ((seed % 1000) < globalMutationRate / 2) { // Lower mutation rate than environmental mutation
             int256 delta = (int256(seed % 10) - 5); // Random delta between -5 and +4
             int256 newGeneValue = int256(childGenes[i]) + delta;
             childGenes[i] = uint256(Math.max(1, Math.min(int256(MAX_GENE_VALUE), newGeneValue)));
        }
    }
    return childGenes;
}

/**
 * @dev Derives traits from a set of genes.
 *      Matches the logic in _generateInitialTraits.
 */
function _deriveTraitsFromGenes(uint256[] memory genes) internal pure returns (uint256[] memory) {
     require(genes.length == GENE_COUNT, "COS: Invalid gene length for derivation");
    uint256[] memory traits = new uint256[](TRAIT_COUNT);
    traits[0] = (genes[0] + genes[1]) % MAX_TRAIT_VALUE;
    traits[1] = (genes[2] + genes[3]) % MAX_TRAIT_VALUE;
    traits[2] = (genes[4] + genes[5]) % MAX_TRAIT_VALUE;
    traits[3] = (genes[6] + genes[7]) % MAX_TRAIT_VALUE;
    traits[4] = (genes[0] + genes[7] + genes[3]) % MAX_TRAIT_VALUE;
    return traits;
}


/**
 * @dev Internal function to add a token ID to an owner's list.
 *      WARNING: Appending to a dynamic array in storage can be very expensive.
 *      This implementation is for demonstration. Production might use linked lists
 *      or external indexing services.
 */
function _addTokenToOwner(address owner, uint256 tokenId) internal {
    ownerTokenIds[owner].push(tokenId);
}

/**
 * @dev Internal function to remove a token ID from an owner's list.
 *      WARNING: Finding and removing from a dynamic array in storage can be *extremely* expensive.
 *      This implementation is for demonstration. Swapping with the last element is a common
 *      optimization, but still requires iteration to find the index.
 */
function _removeTokenFromOwner(address owner, uint256 tokenId) internal {
    uint256[] storage tokenList = ownerTokenIds[owner];
    for (uint256 i = 0; i < tokenList.length; i++) {
        if (tokenList[i] == tokenId) {
            // Swap with last element and pop (common optimization)
            if (i < tokenList.length - 1) {
                tokenList[i] = tokenList[tokenList.length - 1];
            }
            tokenList.pop();
            break; // Token ID found and removed
        }
    }
}

/**
 * @dev Internal transfer logic (updates ownership mappings).
 */
function _transferOrganismInternal(address from, address to, uint256 tokenId) internal {
    require(organismOwners[tokenId] == from, "COS: Transfer from wrong owner"); // Should be guaranteed by caller but good practice
    require(to != address(0), "COS: Transfer to zero address");

    _removeTokenFromOwner(from, tokenId);
    organismOwners[tokenId] = to;
    _addTokenToOwner(to, tokenId);

    emit OrganismTransferred(tokenId, from, to);
}

/**
 * @dev Helper for simulated randomness using block data.
 *      **CRITICAL SECURITY WARNING: This is NOT secure for high-value or
 *      adversarial contexts.** Miners can influence block data.
 */
function _getRandomUint(uint256 seed) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, seed)));
}


// --- Math Library (Simplified, avoiding external imports for "no open source duplication") ---
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
     function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }
}


// --- 6. Public/External Functions ---

/**
 * @dev Constructor: Sets initial contract parameters and owner.
 */
constructor() {
    contractOwner = msg.sender;
    // Set some initial default parameters
    globalMutationRate = 50; // 5% chance per gene per mutation attempt
    globalEnergyDecayRate = 1; // Energy decay rate per second processed
    globalHealthDecayRate = 1; // Health decay rate per second processed (before energy factor)
    globalEnvironmentalFactor = 100; // Base 100% environmental effect

    feedCost = 0.001 ether;
    healCost = 0.005 ether;
    mutationCost = 0.01 ether;
    reproductionCost = 0.05 ether;
    interactionCost = 0.002 ether;
    geneLockCost = 0.003 ether;
    traitEvolutionCost = 0.007 ether;
}

/**
 * @dev Synthesizes the very first organism. Only callable once.
 * @param initialOwner The address to receive the genesis organism.
 */
function createGenesisOrganism(address initialOwner) external payable {
    require(organismCounter == 0, "COS: Genesis organism already synthesized");
    require(initialOwner != address(0), "COS: Initial owner cannot be zero address");
    require(msg.value >= reproductionCost, "COS: Insufficient payment for genesis"); // Require a cost for the first one too

    uint256 tokenId = 1; // Genesis organism ID is 1
    organismCounter = 1;

    uint256[] memory initialGenes = _generateInitialGenes();
    uint256[] memory initialTraits = _generateInitialTraits(initialGenes);

    OrganismState storage newOrganism = organisms[tokenId];
    newOrganism.genes = initialGenes;
    newOrganism.traits = initialTraits;
    newOrganism.energy = MAX_ENERGY; // Start with full energy/health
    newOrganism.health = MAX_HEALTH;
    newOrganism.age = 0;
    newOrganism.lastProcessedTime = block.timestamp;
    newOrganism.isActive = true;
    // Gene locks mapping is empty by default

    organismOwners[tokenId] = initialOwner;
    _addTokenToOwner(initialOwner, tokenId); // Add to owner's list

    emit OrganismSynthesized(tokenId, initialOwner, block.number);
    // Excess ether remains in the contract (can be withdrawn by owner)
}

/**
 * @dev Triggers time-based state update for a specific organism.
 *      Owner or anyone can call, but state changes only apply to the organism.
 *      It's beneficial for owners to call this periodically to manage decay.
 * @param tokenId The ID of the organism to process.
 */
function processOrganism(uint256 tokenId) external organismExists(tokenId) {
    OrganismState storage org = organisms[tokenId];
    _processOrganismStateLogic(org);
}

/**
 * @dev Adds energy to an organism, simulating feeding. Costs ETH.
 * @param tokenId The ID of the organism to feed.
 */
function feedOrganism(uint256 tokenId) external payable organismExists(tokenId) onlyOwnerOfOrganism(tokenId) organismActive(tokenId) {
    require(msg.value >= feedCost, "COS: Insufficient payment to feed");

    OrganismState storage org = organisms[tokenId];
    _processOrganismStateLogic(org); // Process state before feeding

    uint256 energyAdded = Math.min(feedCost * 1000 / 1 ether, MAX_ENERGY - org.energy); // Simplified scaling: 0.001 ETH adds 1 Energy (up to MAX_ENERGY)
    org.energy = Math.min(org.energy + energyAdded, MAX_ENERGY);

    emit OrganismFed(tokenId, energyAdded, org.energy);
    // Excess ether remains in the contract
}

/**
 * @dev Restores health to an organism, simulating healing. Costs ETH.
 * @param tokenId The ID of the organism to heal.
 */
function healOrganism(uint256 tokenId) external payable organismExists(tokenId) onlyOwnerOfOrganism(tokenId) organismActive(tokenId) {
    require(msg.value >= healCost, "COS: Insufficient payment to heal");

    OrganismState storage org = organisms[tokenId];
    _processOrganismStateLogic(org); // Process state before healing

    uint256 healthAdded = Math.min(healCost * 1000 / 1 ether, MAX_HEALTH - org.health); // Simplified scaling: 0.005 ETH adds 5 Health (up to MAX_HEALTH)
    org.health = Math.min(org.health + healthAdded, MAX_HEALTH);

    emit OrganismHealed(tokenId, healthAdded, org.health);
    // Excess ether remains in the contract
}

/**
 * @dev Attempts to mutate the organism's genes/traits. Costs ETH.
 *      Mutation is based on simulated randomness and global rate.
 * @param tokenId The ID of the organism to attempt mutation on.
 */
function attemptMutation(uint256 tokenId) external payable organismExists(tokenId) onlyOwnerOfOrganism(tokenId) organismActive(tokenId) {
    require(msg.value >= mutationCost, "COS: Insufficient payment for mutation");

    OrganismState storage org = organisms[tokenId];
    _processOrganismStateLogic(org); // Process state before mutation attempt

    // Mutation logic is inside the helper, applies changes directly to storage
    bool occurred = _attemptGeneMutation(org);

    if (occurred) {
        emit OrganismMutated(tokenId, org.genes, org.traits);
    }
    // Excess ether remains in the contract
}

/**
 * @dev Attempts to reproduce from two parent organisms, creating a new one. Costs ETH.
 *      Requires both parents to be active and meet criteria (health, energy).
 * @param parent1Id The ID of the first parent.
 * @param parent2Id The ID of the second parent.
 */
function attemptReproduction(uint256 parent1Id, uint256 parent2Id) external payable organismExists(parent1Id) organismExists(parent2Id) organismActive(parent1Id) organismActive(parent2Id) {
    // Require caller owns at least one parent, or some multi-sig logic could be added.
    // For simplicity, require caller owns Parent 1.
    require(organismOwners[parent1Id] == msg.sender, "COS: Caller must own parent1");
    // Optional: require caller owns parent2, or allow collaboration. Let's allow collaboration for creativity.

    require(msg.value >= reproductionCost, "COS: Insufficient payment for reproduction");

    OrganismState storage parent1 = organisms[parent1Id];
    OrganismState storage parent2 = organisms[parent2Id];

    // Process parents' state before reproduction check
    _processOrganismStateLogic(parent1);
    _processOrganismStateLogic(parent2);

    // Re-check active status after processing
    require(parent1.isActive, "COS: Parent1 became inactive during processing");
    require(parent2.isActive, "COS: Parent2 became inactive during processing");

    // Check reproduction specific criteria (e.g., minimum health/energy)
    require(parent1.health > MIN_VIABLE_HEALTH * 2 && parent1.energy > MIN_VIABLE_ENERGY * 2, "COS: Parent1 not healthy/energetic enough for reproduction");
    require(parent2.health > MIN_VIABLE_HEALTH * 2 && parent2.energy > MIN_VIABLE_ENERGY * 2, "COS: Parent2 not healthy/energetic enough for reproduction");

    // Consume parent resources
    parent1.energy = Math.max(0, parent1.energy - (parent1.energy / 4)); // Consume 25% energy
    parent2.energy = Math.max(0, parent2.energy - (parent2.energy / 4));
    parent1.health = Math.max(0, parent1.health - (parent1.health / 8)); // Consume 12.5% health
    parent2.health = Math.max(0, parent2.health - (parent2.health / 8));

    // Synthesize new organism
    organismCounter++;
    uint256 newOrganismId = organismCounter;

    uint256[] memory childGenes = _combineGenes(parent1.genes, parent2.genes);
    uint256[] memory childTraits = _deriveTraitsFromGenes(childGenes);

    OrganismState storage newOrganism = organisms[newOrganismId];
    newOrganism.genes = childGenes;
    newOrganism.traits = childTraits;
    newOrganism.energy = MAX_ENERGY / 2; // New organism starts with some energy
    newOrganism.health = MAX_HEALTH / 2; // New organism starts with some health
    newOrganism.age = 0;
    newOrganism.lastProcessedTime = block.timestamp;
    newOrganism.isActive = true;
    // Gene locks mapping is empty by default

    address newOwner = msg.sender; // Owner of the new organism is the caller
    organismOwners[newOrganismId] = newOwner;
    _addTokenToOwner(newOwner, newOrganismId);

    emit OrganismReproduced(parent1Id, parent2Id, newOrganismId, newOwner);
    emit OrganismSynthesized(newOrganismId, newOwner, block.number);
    // Excess ether remains in the contract
}

/**
 * @dev Simulates an interaction between two organisms. Costs ETH.
 *      Interaction logic is abstract; for demo, it slightly affects energy based on traits.
 * @param organism1Id The ID of the first organism.
 * @param organism2Id The ID of the second organism.
 */
function simulateInteraction(uint256 organism1Id, uint256 organism2Id) external payable organismExists(organism1Id) organismExists(organism2Id) organismActive(organism1Id) organismActive(organism2Id) {
     // Require caller owns at least one, or make it a global action? Let's require owner of organism1.
    require(organismOwners[organism1Id] == msg.sender, "COS: Caller must own organism1 for interaction");
    require(organism1Id != organism2Id, "COS: Organisms must be different for interaction");
    require(msg.value >= interactionCost, "COS: Insufficient payment for interaction");

    OrganismState storage org1 = organisms[organism1Id];
    OrganismState storage org2 = organisms[organism2Id];

     // Process states before interaction
    _processOrganismStateLogic(org1);
    _processOrganismStateLogic(org2);

    // Re-check active status after processing
    require(org1.isActive, "COS: Organism1 became inactive during processing");
    require(org2.isActive, "COS: Organism2 became inactive during processing");


    // --- Simplified Interaction Logic ---
    // Example: Org1's trait[0] vs Org2's trait[1] affects energy levels
    int256 energyChange1 = int256(org2.traits[1]) - int256(org1.traits[0]);
    int256 energyChange2 = int256(org1.traits[0]) - int256(org2.traits[1]);

    // Apply changes, ensuring energy stays within bounds
    org1.energy = uint256(Math.max(0, Math.min(int256(MAX_ENERGY), int256(org1.energy) + energyChange1)));
    org2.energy = uint256(Math.max(0, Math.min(int256(MAX_ENERGY), int256(org2.energy) + energyChange2)));
     // --- End Simplified Interaction Logic ---


    // Re-check viability after potential energy loss
    if (org1.health < MIN_VIABLE_HEALTH || org1.energy < MIN_VIABLE_ENERGY) org1.isActive = false;
    if (org2.health < MIN_VIABLE_HEALTH || org2.energy < MIN_VIABLE_ENERGY) org2.isActive = false;


    string memory description = string(abi.encodePacked(
        "Org ", uint256ToString(organism1Id), " (Trait[0]: ", uint256ToString(org1.traits[0]), ") interacted with Org ",
        uint256ToString(organism2Id), " (Trait[1]: ", uint256ToString(org2.traits[1]), ")"
    )); // Basic description

    emit OrganismInteracted(organism1Id, organism2Id, description);
     // Excess ether remains in the contract
}

// Helper function to convert uint256 to string (basic implementation)
function uint256ToString(uint256 value) internal pure returns (string memory) {
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
        buffer[digits] = bytes1(uint8(48 + value % 10));
        value /= 10;
    }
    return string(buffer);
}


/**
 * @dev Allows the owner to directly influence a specific trait value within limits. Costs ETH.
 *      Represents directed evolution or training.
 * @param tokenId The ID of the organism.
 * @param traitIndex The index of the trait to evolve (0 to TRAIT_COUNT-1).
 * @param valueDelta The amount to add or subtract from the trait value (clamped by MAX_EVOLUTION_DELTA).
 */
function evolveTrait(uint256 tokenId, uint256 traitIndex, int256 valueDelta) external payable organismExists(tokenId) onlyOwnerOfOrganism(tokenId) organismActive(tokenId) {
    require(msg.value >= traitEvolutionCost, "COS: Insufficient payment for trait evolution");
    require(traitIndex < TRAIT_COUNT, "COS: Invalid trait index");

    OrganismState storage org = organisms[tokenId];
    _processOrganismStateLogic(org); // Process state before evolution attempt

    // Clamp the requested delta
    int256 clampedDelta = Math.max(-int256(MAX_EVOLUTION_DELTA), Math.min(int256(MAX_EVOLUTION_DELTA), valueDelta));

    // Apply the change and clamp the new trait value
    int256 currentTraitValue = int256(org.traits[traitIndex]);
    int256 newTraitValue = currentTraitValue + clampedDelta;

    org.traits[traitIndex] = uint256(Math.max(0, Math.min(int256(MAX_TRAIT_VALUE), newTraitValue)));

    emit OrganismTraitEvolved(tokenId, traitIndex, clampedDelta, org.traits[traitIndex]);
    // Excess ether remains in the contract
}

/**
 * @dev Locks or unlocks a specific gene, preventing or allowing mutation for that gene. Costs ETH to lock.
 * @param tokenId The ID of the organism.
 * @param geneIndex The index of the gene to lock/unlock (0 to GENE_COUNT-1).
 * @param locked True to lock, False to unlock.
 */
function setGeneLock(uint256 tokenId, uint256 geneIndex, bool locked) external payable organismExists(tokenId) onlyOwnerOfOrganism(tokenId) {
    require(geneIndex < GENE_COUNT, "COS: Invalid gene index");

    OrganismState storage org = organisms[tokenId];
    // Only charge if locking and it's not already locked
    if (locked && !org.geneLocks[geneIndex]) {
        require(msg.value >= geneLockCost, "COS: Insufficient payment to lock gene");
    } else if (!locked && org.geneLocks[geneIndex]) {
         // No cost to unlock
    } else {
        // No change needed, or cost not applicable for unlock
        return;
    }

    org.geneLocks[geneIndex] = locked;

    emit OrganismGeneLocked(tokenId, geneIndex, locked);
    // Excess ether remains in the contract
}

/**
 * @dev Transfers ownership of an organism. Basic ERC721-like transfer.
 * @param to The address to transfer the organism to.
 * @param tokenId The ID of the organism to transfer.
 */
function transferOrganism(address to, uint256 tokenId) external organismExists(tokenId) onlyOwnerOfOrganism(tokenId) {
    _transferOrganismInternal(msg.sender, to, tokenId);
}


// --- View Functions (Getters) ---

/**
 * @dev Gets the full state of an organism.
 * @param tokenId The ID of the organism.
 * @return OrganismState struct.
 */
function getOrganismState(uint256 tokenId) view external organismExists(tokenId) returns (OrganismState memory) {
    OrganismState storage org = organisms[tokenId];
     // Create a memory copy, excluding the internal mapping (geneLocks)
    uint256[] memory genesCopy = new uint256[](GENE_COUNT);
    uint256[] memory traitsCopy = new uint256[](TRAIT_COUNT);
    for(uint256 i = 0; i < GENE_COUNT; i++) genesCopy[i] = org.genes[i];
    for(uint256 i = 0; i < TRAIT_COUNT; i++) traitsCopy[i] = org.traits[i];

    // Note: geneLocks mapping cannot be returned directly in memory struct.
    // Use isGeneLocked for individual gene lock status.
     return OrganismState({
        genes: genesCopy,
        traits: traitsCopy,
        energy: org.energy,
        health: org.health,
        age: org.age,
        lastProcessedTime: org.lastProcessedTime,
        isActive: org.isActive,
        geneLocks: org.geneLocks // This mapping access within the struct return might behave differently based on compiler/ABI encoding, safer to get locks individually if needed off-chain.
     });
}

/**
 * @dev Gets the genes of an organism.
 * @param tokenId The ID of the organism.
 * @return Array of gene values.
 */
function getOrganismGenes(uint256 tokenId) view external organismExists(tokenId) returns (uint256[] memory) {
     return organisms[tokenId].genes;
}

/**
 * @dev Gets the traits of an organism.
 * @param tokenId The ID of the organism.
 * @return Array of trait values.
 */
function getOrganismTraits(uint256 tokenId) view external organismExists(tokenId) returns (uint256[] memory) {
    return organisms[tokenId].traits;
}

/**
 * @dev Gets the owner of an organism.
 * @param tokenId The ID of the organism.
 * @return The owner's address.
 */
function getOrganismOwner(uint256 tokenId) view external organismExists(tokenId) returns (address) {
    return organismOwners[tokenId];
}

/**
 * @dev Gets the total number of organisms ever synthesized.
 * @return The total count.
 */
function getTotalOrganisms() view external returns (uint256) {
    return organismCounter;
}

/**
 * @dev Gets all organism token IDs owned by a specific address.
 *      WARNING: This function can be very gas-expensive if an address owns many tokens.
 * @param owner The address to query.
 * @return An array of token IDs.
 */
function getOrganismsByOwner(address owner) view external returns (uint256[] memory) {
    return ownerTokenIds[owner];
}

/**
 * @dev Checks if an organism is currently active (viable).
 * @param tokenId The ID of the organism.
 * @return True if active, False otherwise.
 */
function checkOrganismViability(uint256 tokenId) view external organismExists(tokenId) returns (bool) {
    return organisms[tokenId].isActive;
}

/**
 * @dev Checks if two organisms meet the basic criteria for reproduction (exist, active, sufficient resources).
 * @param parent1Id The ID of the first parent.
 * @param parent2Id The ID of the second parent.
 * @return True if eligible, False otherwise.
 */
function checkReproductionEligibility(uint256 parent1Id, uint256 parent2Id) view external returns (bool) {
    if (organismOwners[parent1Id] == address(0) || organismOwners[parent2Id] == address(0)) return false;
    if (!organisms[parent1Id].isActive || !organisms[parent2Id].isActive) return false;

    // Check resource thresholds (same as in attemptReproduction)
    if (organisms[parent1Id].health < MIN_VIABLE_HEALTH * 2 || organisms[parent1Id].energy < MIN_VIABLE_ENERGY * 2) return false;
    if (organisms[parent2Id].health < MIN_VIABLE_HEALTH * 2 || organisms[parent2Id].energy < MIN_VIABLE_ENERGY * 2) return false;

    // Could add other checks here (e.g., age, trait compatibility)
    return true;
}

/**
 * @dev Checks if a specific gene on an organism is locked against mutation.
 * @param tokenId The ID of the organism.
 * @param geneIndex The index of the gene.
 * @return True if locked, False otherwise.
 */
function isGeneLocked(uint256 tokenId, uint256 geneIndex) view external organismExists(tokenId) returns (bool) {
     require(geneIndex < GENE_COUNT, "COS: Invalid gene index");
     return organisms[tokenId].geneLocks[geneIndex];
}


/**
 * @dev Retrieves the current global environmental factor.
 */
function getGlobalEnvironmentalFactor() view external returns (uint256) {
    return globalEnvironmentalFactor;
}

/**
 * @dev Retrieves the current global mutation rate.
 */
function getGlobalMutationRate() view external returns (uint256) {
    return globalMutationRate;
}


// --- Admin Functions ---

/**
 * @dev Allows the contract owner to update the global environmental factor.
 * @param newFactor The new environmental factor value.
 */
function setGlobalEnvironmentalFactor(uint256 newFactor) external onlyOwner {
    globalEnvironmentalFactor = newFactor;
    emit AdminParameterUpdated("globalEnvironmentalFactor", newFactor);
}

/**
 * @dev Allows the contract owner to update the global mutation rate.
 * @param newRate The new mutation rate value.
 */
function setGlobalMutationRate(uint256 newRate) external onlyOwner {
    globalMutationRate = newRate;
    emit AdminParameterUpdated("globalMutationRate", newRate);
}

// Add more admin functions here to tune other parameters (decay rates, costs)

/**
 * @dev Allows the contract owner to withdraw any accumulated ETH (from costs).
 */
function withdrawFees() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "COS: No ether balance to withdraw");
    (bool success, ) = payable(contractOwner).call{value: balance}("");
    require(success, "COS: Fee withdrawal failed");
    emit FeesWithdrawn(contractOwner, balance);
}

// You could add more getters for cost/rate parameters here if needed by the UI
// function getFeedCost() view external returns (uint256) { return feedCost; }
// ... and so on for other costs and rates.
```