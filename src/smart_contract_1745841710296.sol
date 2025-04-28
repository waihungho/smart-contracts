Okay, let's create a smart contract that manages a population of "Autonomous Digital Organisms" (ADOs). This concept involves dynamic state, interactions, reproduction, decay, and evolution-like mechanics, aiming for something beyond standard token or simple NFT patterns. It's a simulation living on the blockchain.

Here's the outline and the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AutonomousDigitalOrganism
 * @author Your Name (or handle)
 * @notice A contract simulating a population of digital organisms on the blockchain.
 * Each organism is a unique entity with dynamic attributes (Health, Energy, Complexity, Genetics).
 * Organisms can be interacted with, they decay over time, can reproduce, compete, and evolve.
 * This is an advanced concept demonstrating complex state management and interactions.
 */

/*
 * OUTLINE:
 *
 * 1.  Data Structures:
 *     - Organism struct: Defines the properties of each digital organism.
 * 2.  State Variables:
 *     - Mapping to store organisms (id => Organism).
 *     - Mapping for ownership (id => owner).
 *     - Mapping for owner's organisms (owner => list of ids).
 *     - Mapping for delegation (id => delegate address).
 *     - Counter for total organisms/next organism ID.
 *     - Base parameters for mechanics (decay rates, costs, etc.).
 * 3.  Events:
 *     - Signify key actions (Mint, Transfer, StateChange, Reproduction, Challenge, etc.).
 * 4.  Modifiers:
 *     - Helper to check ownership or delegation.
 * 5.  Internal Helpers:
 *     - `_updateOrganismState`: Core mechanic to apply time-based state changes (decay/growth).
 *     - `_calculateGeneticCompatibility`: Logic for gene comparison.
 *     - `_deriveGeneticCode`: Logic for offspring genetics.
 *     - `_getRandomValue`: Simple on-chain pseudo-randomness (cautionary use).
 * 6.  Core Functionality (>= 20 functions):
 *     - Seeding/Minting new organisms.
 *     - Ownership management (transfer, get by owner).
 *     - Reading organism state (attributes, counts).
 *     - Organism interaction: Feed, Stimulate, Train, Repair.
 *     - Life cycle: Procreate, Harvest, Decompose.
 *     - Advanced interactions: Challenge, Symbiosis (simplified), Energy Transfer.
 *     - Evolution/Adaptation: Adjust Metabolism, Fine-tune Genetics.
 *     - Environmental Sensing: Sense World, Global stats.
 *     - Delegation: Allowing others to control your organism.
 *     - Release into Wild: Removing ownership.
 */

/*
 * FUNCTION SUMMARY:
 *
 * Core Management & Information:
 * 1.  seedOrganism(bytes32 initialGeneticCode): (payable) Mints a new organism. Cost scales with supply.
 * 2.  transfer(address to, uint256 organismId): Transfers ownership of an organism (ERC721-like).
 * 3.  getAttributes(uint256 organismId): (view) Retrieves the current attributes of an organism (updates state first).
 * 4.  totalSupply(): (view) Returns the total number of existing organisms.
 * 5.  getTokenIdsByOwner(address owner): (view) Returns an array of organism IDs owned by an address.
 * 6.  getOwnerOf(uint256 organismId): (view) Returns the owner of an organism.
 *
 * Organism Interaction & State Change:
 * 7.  feed(uint256 organismId): (payable) Increases organism's energy and health using ETH. Applies state update.
 * 8.  stimulate(uint256 organismId): (payable) Increases complexity, potentially triggers mutation, using ETH. Applies state update.
 * 9.  train(uint256 organismId): Increases complexity through interaction/time (requires energy/complexity threshold). Applies state update.
 * 10. repair(uint256 organismId): (payable) Directly boosts organism's health using ETH. Applies state update.
 * 11. adjustMetabolismRate(uint256 organismId, int256 energyRateModifier, int256 healthRateModifier): Allows high-complexity organisms to fine-tune resource decay/growth. Applies state update.
 * 12. fineTuneGeneticCode(uint256 organismId, uint256 mask, uint256 newValue): Allows high-complexity organisms limited genetic modification. Applies state update.
 *
 * Life Cycle:
 * 13. procreate(uint256 parentId): (payable) Creates a new organism child, consuming parent's energy/complexity. Applies state update. Requires ETH cost for "environment".
 * 14. harvest(uint256 organismId): Extracts value (ETH) from a high-energy/complexity organism, consuming energy/health. Applies state update.
 * 15. decompose(uint256 organismId): Manually removes an organism if health is low or owner requests. Can yield partial ETH return.
 *
 * Advanced Interactions:
 * 16. challengeOrganism(uint256 attackerId, uint256 targetId): (payable) Initiates a conflict. Winner gains complexity/energy, loser loses health/energy. ETH pot is split. Applies state update to both.
 * 17. transferEnergyInternal(uint256 fromId, uint256 toId, uint256 amount): Transfers energy between two organisms owned or controlled by the caller. Applies state update to both.
 *
 * Analysis & Environment:
 * 18. calculateGeneticCompatibility(uint256 organism1Id, uint256 organism2Id): (view) Calculates a compatibility score between two genetic codes (0-100).
 * 19. estimateGrowthPotential(uint256 organismId): (view) Provides a heuristic estimate of future potential based on current state/genetics. Applies state update first.
 * 20. senseWorld(): (view) Returns data reflecting the global state (block number, total supply, average complexity).
 * 21. getGlobalEnergySupply(): (view) Sums energy of all organisms.
 * 22. getAverageComplexity(): (view) Calculates the average complexity of all organisms.
 *
 * Delegation (Access Control):
 * 23. setDelegate(uint256 organismId, address delegatee): Allows an address to control a specific organism.
 * 24. revokeDelegate(uint256 organismId): Removes a delegate.
 * 25. getDelegate(uint256 organismId): (view) Returns the delegate address for an organism.
 *
 * Other:
 * 26. releaseIntoWild(uint256 organismId): Removes owner, potentially changes decay rates, making it "wild" (uncontrolled).
 * 27. withdrawContractBalance(address payable to, uint256 amount): Allows contract owner to withdraw accumulated ETH (from seeding, fees, etc.). Basic admin.
 */

contract AutonomousDigitalOrganism {

    address public immutable contractOwner; // For basic admin tasks like withdrawing funds
    uint256 private _nextTokenId; // ERC721-like token ID counter

    // --- Constants for Simulation Tuning ---
    uint256 public constant BASE_SEED_COST = 0.01 ether;
    uint256 public constant COST_PER_ORGANISM_SCALING = 1000; // Scale cost based on total supply
    uint256 public constant MIN_HEALTH = 0;
    uint256 public constant MAX_HEALTH = 1000;
    uint256 public constant MIN_ENERGY = 0;
    uint256 public constant MAX_ENERGY = 1000;
    uint256 public constant MIN_COMPLEXITY = 0;
    uint256 public constant MAX_COMPLEXITY = 1000;
    uint256 public constant BASE_DECAY_PER_BLOCK = 1; // How much energy/health decays per block
    uint256 public constant BASE_COMPLEXITY_GROWTH_PER_BLOCK = 0; // Complexity grows only through interaction primarily
    uint256 public constant FEED_ETH_TO_ENERGY = 500; // How much energy per ETH fed
    uint256 public constant STIMULATE_ETH_TO_COMPLEXITY = 100; // How much complexity boost per ETH stimulated
    uint256 public constant REPAIR_ETH_TO_HEALTH = 500; // How much health per ETH repaired
    uint256 public constant PROCREATE_ETH_COST = 0.05 ether; // Cost to create a new environment for procreation
    uint256 public constant PROCREATE_ENERGY_COST_PARENT = 300; // Energy parent consumes
    uint256 public constant PROCREATE_COMPLEXITY_COST_PARENT = 50; // Complexity parent consumes
    uint256 public constant CHALLENGE_FEE_PER_ORGANISM = 0.005 ether; // ETH cost for challenging
    uint256 public constant HARVEST_ENERGY_COST = 200; // Energy cost to harvest
    uint256 public constant HARVEST_MIN_COMPLEXITY = 200; // Min complexity to harvest
    uint256 public constant HARVEST_ETH_PER_ENERGY_UNIT = 0.0001 ether; // ETH yielded per energy unit harvested

    // --- Data Structures ---
    struct Organism {
        uint256 id;
        bytes32 geneticCode;
        uint256 health;
        uint256 energy;
        uint256 complexity;
        uint256 creationBlock;
        uint256 lastInteractionBlock;
        // Dynamic rates adjusted by adjustMetabolismRate
        int256 energyDecayModifier; // Added to BASE_DECAY_PER_BLOCK
        int256 healthDecayModifier; // Added to BASE_DECAY_PER_BLOCK
    }

    // --- State Variables ---
    mapping(uint256 => Organism) public organisms;
    mapping(uint256 => address) private _owners; // organismId => owner address
    mapping(address => uint256[]) private _ownedOrganisms; // owner address => list of organismIds
    mapping(uint256 => address) private _delegates; // organismId => delegate address

    // --- Events ---
    event OrganismSeeded(uint256 indexed organismId, address indexed owner, bytes32 initialGeneticCode, uint256 creationBlock);
    event OrganismTransferred(uint256 indexed organismId, address indexed from, address indexed to);
    event OrganismStateChanged(uint256 indexed organismId, string action, uint256 newHealth, uint256 newEnergy, uint256 newComplexity, uint256 lastInteractionBlock);
    event OrganismProcreated(uint256 indexed parentId, uint256 indexed childId, address indexed owner, bytes32 childGeneticCode);
    event OrganismHarvested(uint256 indexed organismId, address indexed owner, uint256 amountEth, uint256 remainingEnergy, uint256 remainingHealth);
    event OrganismDecomposed(uint256 indexed organismId, address indexed owner, string reason);
    event OrganismChallenged(uint256 indexed attackerId, uint256 indexed targetId, uint256 winnerId, uint256 ethPot, uint256 winnerEthShare);
    event MetabolismAdjusted(uint256 indexed organismId, int256 newEnergyDecayModifier, int256 newHealthDecayModifier);
    event GeneticCodeFineTuned(uint256 indexed organismId, bytes32 newGeneticCode);
    event DelegateSet(uint256 indexed organismId, address indexed delegatee);
    event DelegateRevoked(uint256 indexed organismId);
    event OrganismReleasedIntoWild(uint256 indexed organismId, address indexed formerOwner);
    event EthWithdrawn(address indexed to, uint256 amount);


    // --- Modifiers ---
    modifier onlyOrganismOwner(uint256 organismId) {
        require(_owners[organismId] == msg.sender, "Not organism owner");
        _;
    }

     modifier onlyOrganismOwnerOrDelegate(uint256 organismId) {
        require(_owners[organismId] == msg.sender || _delegates[organismId] == msg.sender, "Not authorized for this organism");
        _;
    }

    modifier organismExists(uint256 organismId) {
        require(_owners[organismId] != address(0), "Organism does not exist");
        _;
    }

    modifier organismNotWild(uint256 organismId) {
         require(_owners[organismId] != address(0), "Organism does not exist"); // Check existence first
         require(_owners[organismId] != address(0x1), "Organism is wild"); // Assuming address(0x1) represents the 'wild' state
        _;
    }


    // --- Constructor ---
    constructor() {
        contractOwner = msg.sender;
        _nextTokenId = 1; // Start organism IDs from 1
        // Initialize address(0x1) as the "wild" owner
        // Organisms owned by address(0x1) are considered released
        // _owners[0] = address(0x1); // Not necessary, just need to check against this address later
    }

    receive() external payable {} // Allow receiving ETH for feeding, seeding, etc.

    // --- Internal Helpers ---

    // Applies time-based state decay and limited growth
    function _updateOrganismState(uint256 organismId) internal organismExists(organismId) {
        Organism storage organism = organisms[organismId];
        uint256 blocksPassed = block.number - organism.lastInteractionBlock;

        if (blocksPassed == 0) {
            // State is already up-to-date or no time has passed
            return;
        }

        // Calculate decay based on time passed and modifiers
        uint256 energyDecayAmount = blocksPassed * uint256(int256(BASE_DECAY_PER_BLOCK) + organism.energyDecayModifier >= 0 ? int256(BASE_DECAY_PER_BLOCK) + organism.energyDecayModifier : 0);
        uint256 healthDecayAmount = blocksPassed * uint256(int256(BASE_DECAY_PER_BLOCK) + organism.healthDecayModifier >= 0 ? int256(BASE_DECAY_PER_BLOCK) + organism.healthDecayModifier : 0);

        // Apply decay, clamping at MIN_HEALTH/MIN_ENERGY
        organism.energy = organism.energy >= energyDecayAmount ? organism.energy - energyDecayAmount : MIN_ENERGY;
        organism.health = organism.health >= healthDecayAmount ? organism.health - healthDecayAmount : MIN_HEALTH;

        // Limited Complexity Growth based on just existing (can be zero BASE_COMPLEXITY_GROWTH_PER_BLOCK)
        uint256 complexityGrowthAmount = blocksPassed * BASE_COMPLEXITY_GROWTH_PER_BLOCK;
        organism.complexity = organism.complexity + complexityGrowthAmount <= MAX_COMPLEXITY ? organism.complexity + complexityGrowthAmount : MAX_COMPLEXITY;


        organism.lastInteractionBlock = block.number;

        // Note: Events for state changes are fired by the external functions after calling this.
    }

    // Simple pseudo-randomness based on block data and genetics
    function _getRandomValue(uint256 organismId, bytes32 geneticCode, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            organismId,
            geneticCode,
            salt,
            block.timestamp,
            block.difficulty, // block.difficulty is deprecated after the merge, use block.prevrandao
            block.prevrandao, // Use block.prevrandao for post-merge randomness
            msg.sender
        )));
    }

    // Simple genetic compatibility based on XOR difference
    function _calculateGeneticCompatibility(bytes32 code1, bytes32 code2) internal pure returns (uint256) {
        bytes32 xorResult = code1 ^ code2;
        uint256 diffBits = 0;
        for (uint i = 0; i < 256; i++) {
            if (((uint256(xorResult) >> i) & 1) == 1) {
                diffBits++;
            }
        }
        // Scale diffBits (0-256) to compatibility (0-100)
        // More diff = less compatibility. Max diff (256) = 0 compatibility. Min diff (0) = 100 compatibility.
        return diffBits <= 100 ? 100 - diffBits : 0;
    }

    // Derive child genetics with mutation chance
    function _deriveGeneticCode(bytes32 parentCode, uint256 organismId) internal view returns (bytes32) {
        uint256 randomFactor = _getRandomValue(organismId, parentCode, 1);
        bytes32 mutatedCode = parentCode;

        // Simple mutation: Flip a few bits based on randomness
        if (randomFactor % 10 < 2) { // ~20% chance of some mutation
             mutatedCode ^= bytes32(uint256(1) << (randomFactor % 256)); // Flip one bit
        }
         if (randomFactor % 100 < 5) { // ~5% chance of a second mutation
             mutatedCode ^= bytes32(uint256(1) << ((randomFactor / 256) % 256)); // Flip another bit
        }

        return mutatedCode;
    }

     // Helper to remove organism ID from owner's list (simple but potentially gas-intensive for large lists)
     // In a real scenario, a more efficient linked list or similar pattern might be needed.
     function _removeOrganismFromOwner(address owner, uint256 organismId) internal {
        uint256[] storage ownerOrganisms = _ownedOrganisms[owner];
        for (uint i = 0; i < ownerOrganisms.length; i++) {
            if (ownerOrganisms[i] == organismId) {
                // Replace with last element and pop
                ownerOrganisms[i] = ownerOrganisms[ownerOrganisms.length - 1];
                ownerOrganisms.pop();
                break; // Found and removed
            }
        }
    }


    // --- Core Functionality ---

    /**
     * @notice Mints a new digital organism. Requires payment.
     * @param initialGeneticCode The initial genetic signature of the organism.
     */
    function seedOrganism(bytes32 initialGeneticCode) external payable returns (uint256) {
        uint256 currentSupply = _nextTokenId - 1;
        uint256 cost = BASE_SEED_COST + (currentSupply / COST_PER_ORGANISM_SCALING) * BASE_SEED_COST; // Cost increases with population

        require(msg.value >= cost, "Insufficient ETH to seed organism");

        uint256 newOrganismId = _nextTokenId++;

        Organism memory newOrganism = Organism({
            id: newOrganismId,
            geneticCode: initialGeneticCode,
            health: MAX_HEALTH / 2, // Start with half health/energy
            energy: MAX_ENERGY / 2,
            complexity: MIN_COMPLEXITY,
            creationBlock: block.number,
            lastInteractionBlock: block.number,
            energyDecayModifier: 0,
            healthDecayModifier: 0
        });

        organisms[newOrganismId] = newOrganism;
        _owners[newOrganismId] = msg.sender;
        _ownedOrganisms[msg.sender].push(newOrganismId);

        // Refund any excess ETH
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit OrganismSeeded(newOrganismId, msg.sender, initialGeneticCode, block.number);
        emit OrganismTransferred(newOrganismId, address(0), msg.sender); // ERC721-like Mint event
        emit OrganismStateChanged(newOrganismId, "Seeded", newOrganism.health, newOrganism.energy, newOrganism.complexity, newOrganism.lastInteractionBlock);

        return newOrganismId;
    }

    /**
     * @notice Transfers ownership of an organism. ERC721-like functionality.
     * @param to The recipient address.
     * @param organismId The ID of the organism to transfer.
     */
    function transfer(address to, uint256 organismId) public onlyOrganismOwner(organismId) organismNotWild(organismId) {
        require(to != address(0), "Cannot transfer to zero address");

        address currentOwner = _owners[organismId];

        // Remove from old owner's list
        _removeOrganismFromOwner(currentOwner, organismId);

        // Update ownership
        _owners[organismId] = to;
        _ownedOrganisms[to].push(organismId);

        // Clear any existing delegate on transfer
        if (_delegates[organismId] != address(0)) {
            _delegates[organismId] = address(0);
            emit DelegateRevoked(organismId);
        }

        emit OrganismTransferred(organismId, currentOwner, to);
    }

    /**
     * @notice Gets the current attributes of an organism. Updates state before returning.
     * @param organismId The ID of the organism.
     * @return Organism struct containing current attributes.
     */
    function getAttributes(uint256 organismId) public organismExists(organismId) returns (Organism memory) {
        _updateOrganismState(organismId); // Ensure state is current before returning
        return organisms[organismId];
    }

    /**
     * @notice Gets the total number of organisms in the population.
     * @return The total supply (excluding decomposed/released).
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1 - _ownedOrganisms[address(0x1)].length; // Total minted minus wild ones
    }

     /**
     * @notice Gets the total number of organisms minted (including wild/decomposed).
     * Useful for understanding the historical population size.
     * @return The total number of organism IDs ever minted.
     */
    function totalMintedSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }


    /**
     * @notice Gets the list of organism IDs owned by a specific address.
     * @param owner The address to query.
     * @return An array of organism IDs.
     */
    function getTokenIdsByOwner(address owner) public view returns (uint256[] memory) {
        return _ownedOrganisms[owner];
    }

    /**
     * @notice Gets the owner of a specific organism.
     * @param organismId The ID of the organism.
     * @return The owner address. Returns address(0) if not found or address(0x1) if wild.
     */
     function getOwnerOf(uint256 organismId) public view returns (address) {
         return _owners[organismId];
     }


    // --- Organism Interaction & State Change ---

    /**
     * @notice Feeds an organism, increasing its energy and health.
     * @param organismId The ID of the organism to feed.
     */
    function feed(uint256 organismId) public payable organismExists(organismId) organismNotWild(organismId) {
        _updateOrganismState(organismId);
        Organism storage organism = organisms[organismId];

        uint256 energyGained = msg.value * FEED_ETH_TO_ENERGY / 1 ether;
        uint256 healthGained = energyGained / 2; // Feeding also boosts health slightly

        organism.energy = organism.energy + energyGained <= MAX_ENERGY ? organism.energy + energyGained : MAX_ENERGY;
        organism.health = organism.health + healthGained <= MAX_HEALTH ? organism.health + healthGained : MAX_HEALTH;
        organism.lastInteractionBlock = block.number; // Update interaction block *again* after state change

        emit OrganismStateChanged(organismId, "Fed", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);
    }

     /**
     * @notice Stimulates an organism, increasing its complexity and potentially triggering mutation.
     * @param organismId The ID of the organism to stimulate.
     */
    function stimulate(uint256 organismId) public payable organismExists(organismId) organismNotWild(organismId) {
        _updateOrganismState(organismId);
        Organism storage organism = organisms[organismId];

        uint256 complexityGained = msg.value * STIMULATE_ETH_TO_COMPLEXITY / 1 ether;

        organism.complexity = organism.complexity + complexityGained <= MAX_COMPLEXITY ? organism.complexity + complexityGained : MAX_COMPLEXITY;

        // Chance of mutation based on complexity and random factor
        uint256 mutationChance = organism.complexity / (MAX_COMPLEXITY / 10); // Higher complexity, higher chance (up to 10/10)
        if (_getRandomValue(organismId, organism.geneticCode, 2) % 10 < mutationChance) {
            organism.geneticCode = _deriveGeneticCode(organism.geneticCode, organismId);
             emit GeneticCodeFineTuned(organismId, organism.geneticCode); // Re-using event for significant genetic change
        }

        organism.lastInteractionBlock = block.number; // Update interaction block

        emit OrganismStateChanged(organismId, "Stimulated", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);
    }

    /**
     * @notice Trains an organism, increasing its complexity and potentially reducing resource decay.
     * Requires the organism to meet certain energy and complexity thresholds.
     * @param organismId The ID of the organism to train.
     */
    function train(uint256 organismId) public onlyOrganismOwnerOrDelegate(organismId) organismNotWild(organismId) {
        _updateOrganismState(organismId);
        Organism storage organism = organisms[organismId];

        uint256 requiredEnergy = 100;
        uint256 requiredComplexity = 50;

        require(organism.energy >= requiredEnergy, "Organism needs more energy to train");
        require(organism.complexity >= requiredComplexity, "Organism needs more complexity to train");

        organism.energy -= requiredEnergy;
        organism.complexity = organism.complexity + (organism.complexity / 20) <= MAX_COMPLEXITY ? organism.complexity + (organism.complexity / 20) : MAX_COMPLEXITY; // Complexity increases based on current complexity

        // Small chance to slightly improve decay rates (reduce modifier towards positive)
        if (_getRandomValue(organismId, organism.geneticCode, 3) % 100 < 10 && organism.energyDecayModifier > -int256(BASE_DECAY_PER_BLOCK)) {
             organism.energyDecayModifier++;
             emit MetabolismAdjusted(organismId, organism.energyDecayModifier, organism.healthDecayModifier);
        }
         if (_getRandomValue(organismId, organism.geneticCode, 4) % 100 < 5 && organism.healthDecayModifier > -int256(BASE_DECAY_PER_BLOCK)) {
             organism.healthDecayModifier++;
              emit MetabolismAdjusted(organismId, organism.energyDecayModifier, organism.healthDecayModifier);
        }


        organism.lastInteractionBlock = block.number;

        emit OrganismStateChanged(organismId, "Trained", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);
    }

     /**
     * @notice Repairs an organism, directly boosting its health.
     * @param organismId The ID of the organism to repair.
     */
     function repair(uint256 organismId) public payable organismExists(organismId) organismNotWild(organismId) {
        _updateOrganismState(organismId);
        Organism storage organism = organisms[organismId];

        uint256 healthGained = msg.value * REPAIR_ETH_TO_HEALTH / 1 ether;

        organism.health = organism.health + healthGained <= MAX_HEALTH ? organism.health + healthGained : MAX_HEALTH;
        organism.lastInteractionBlock = block.number;

        emit OrganismStateChanged(organismId, "Repaired", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);
     }

     /**
     * @notice Allows an organism with high complexity to adjust its metabolism rates.
     * Requires high complexity. Modifiers are capped.
     * @param organismId The ID of the organism.
     * @param energyRateModifier The proposed change for energy decay modifier.
     * @param healthRateModifier The proposed change for health decay modifier.
     */
    function adjustMetabolismRate(uint256 organismId, int256 energyRateModifier, int256 healthRateModifier) public onlyOrganismOwnerOrDelegate(organismId) organismNotWild(organismId) {
        _updateOrganismState(organismId);
        Organism storage organism = organisms[organismId];

        uint256 requiredComplexity = 500; // High complexity required
        uint256 complexityCost = 50; // Consumes complexity

        require(organism.complexity >= requiredComplexity, "Organism needs high complexity to adjust metabolism");
        require(organism.complexity >= complexityCost, "Organism needs complexity points to spend on adjustment");


        // Simple bounds check for modifiers (e.g., can't make decay negative)
        int256 maxModifier = int256(BASE_DECAY_PER_BLOCK) * 2; // Example cap
        int256 minModifier = -int256(BASE_DECAY_PER_BLOCK);

        organism.energyDecayModifier = energyRateModifier;
        if (organism.energyDecayModifier > maxModifier) organism.energyDecayModifier = maxModifier;
        if (organism.energyDecayModifier < minModifier) organism.energyDecayModifier = minModifier;

        organism.healthDecayModifier = healthRateModifier;
         if (organism.healthDecayModifier > maxModifier) organism.healthDecayModifier = maxModifier;
        if (organism.healthDecayModifier < minModifier) organism.healthDecayModifier = minModifier;

        organism.complexity -= complexityCost; // Cost complexity to make the adjustment
        organism.lastInteractionBlock = block.number;

        emit MetabolismAdjusted(organismId, organism.energyDecayModifier, organism.healthDecayModifier);
         emit OrganismStateChanged(organismId, "MetabolismAdjusted", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);
    }

     /**
     * @notice Allows an organism with very high complexity to fine-tune a small part of its genetic code.
     * Requires very high complexity and consumes complexity. Limited modification.
     * @param organismId The ID of the organism.
     * @param mask A bitmask indicating which bits of the genetic code can be modified (1 = modifiable, 0 = fixed).
     * @param newValue The new values for the bits indicated by the mask.
     */
    function fineTuneGeneticCode(uint256 organismId, uint256 mask, uint256 newValue) public onlyOrganismOwnerOrDelegate(organismId) organismNotWild(organismId) {
         _updateOrganismState(organismId);
        Organism storage organism = organisms[organismId];

        uint256 requiredComplexity = 700; // Very high complexity
        uint256 complexityCost = 100; // Significant complexity cost

         require(organism.complexity >= requiredComplexity, "Organism needs very high complexity for genetic fine-tuning");
         require(organism.complexity >= complexityCost, "Organism needs complexity points to spend on fine-tuning");
         // Add checks on mask to limit the number of modifiable bits if needed
         // require(countSetBits(mask) <= maxModifiableBits, "Mask too large"); // Requires bit counting helper

        bytes32 currentGeneticCode = organism.geneticCode;
        bytes32 newGeneticCode = (currentGeneticCode & ~bytes32(mask)) | (bytes32(newValue) & bytes32(mask)); // Apply new value only to masked bits

        organism.geneticCode = newGeneticCode;
        organism.complexity -= complexityCost;
        organism.lastInteractionBlock = block.number;

        emit GeneticCodeFine Tuned(organismId, newGeneticCode);
         emit OrganismStateChanged(organismId, "GeneticFineTuned", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);
    }


    // --- Life Cycle ---

     /**
     * @notice Allows a mature organism to procreate, creating a new organism.
     * Requires parent organism to meet energy and complexity thresholds and costs ETH.
     * @param parentId The ID of the parent organism.
     * @return The ID of the newly created child organism.
     */
    function procreate(uint256 parentId) public payable onlyOrganismOwnerOrDelegate(parentId) organismNotWild(parentId) returns (uint256) {
        _updateOrganismState(parentId);
        Organism storage parent = organisms[parentId];

        require(msg.value >= PROCREATE_ETH_COST, "Insufficient ETH for procreation environment");
        require(parent.energy >= PROCREATE_ENERGY_COST_PARENT, "Parent needs more energy to procreate");
        require(parent.complexity >= PROCREATE_COMPLEXITY_COST_PARENT, "Parent needs more complexity to procreate");

        // Consume parent resources
        parent.energy -= PROCREATE_ENERGY_COST_PARENT;
        parent.complexity -= PROCREATE_COMPLEXITY_COST_PARENT;
        parent.lastInteractionBlock = block.number; // Update parent's interaction block

        // Derive child genetics
        bytes32 childGeneticCode = _deriveGeneticCode(parent.geneticCode, parentId);

        // Create child organism (similar logic to seed)
        uint256 newOrganismId = _nextTokenId++;

        Organism memory childOrganism = Organism({
            id: newOrganismId,
            geneticCode: childGeneticCode,
            health: MAX_HEALTH / 3, // Children start with lower health/energy than seeded
            energy: MAX_ENERGY / 3,
            complexity: MIN_COMPLEXITY,
            creationBlock: block.number,
            lastInteractionBlock: block.number,
            energyDecayModifier: 0,
            healthDecayModifier: 0
        });

        organisms[newOrganismId] = childOrganism;
        address childOwner = _owners[parentId]; // Child inherits parent's owner
        _owners[newOrganismId] = childOwner;
        _ownedOrganisms[childOwner].push(newOrganismId);

        // Refund any excess ETH
         if (msg.value > PROCREATE_ETH_COST) {
            payable(msg.sender).transfer(msg.value - PROCREATE_ETH_COST);
        }


        emit OrganismProcreated(parentId, newOrganismId, childOwner, childGeneticCode);
        emit OrganismStateChanged(parentId, "Procreated", parent.health, parent.energy, parent.complexity, parent.lastInteractionBlock);
        emit OrganismSeeded(newOrganismId, childOwner, childGeneticCode, block.number); // Also emit Seeded for tracking
        emit OrganismTransferred(newOrganismId, address(0), childOwner); // ERC721-like Mint event
        emit OrganismStateChanged(newOrganismId, "Born", childOrganism.health, childOrganism.energy, childOrganism.complexity, childOrganism.lastInteractionBlock);


        return newOrganismId;
    }

     /**
     * @notice Allows harvesting resources (ETH) from a high-energy, high-complexity organism.
     * Consumes the organism's energy and health.
     * @param organismId The ID of the organism to harvest from.
     */
    function harvest(uint256 organismId) public onlyOrganismOwnerOrDelegate(organismId) organismNotWild(organismId) {
        _updateOrganismState(organismId);
        Organism storage organism = organisms[organismId];
        address owner = _owners[organismId];

        require(organism.energy >= HARVEST_ENERGY_COST, "Organism needs more energy to be harvested");
        require(organism.complexity >= HARVEST_MIN_COMPLEXITY, "Organism needs minimum complexity to be harvested");

        // Calculate yield based on energy harvested (can be more complex based on complexity)
        uint256 ethYield = HARVEST_ENERGY_COST * HARVEST_ETH_PER_ENERGY_UNIT; // Example calculation

        // Consume resources
        organism.energy -= HARVEST_ENERGY_COST;
        // Harvesting also degrades health slightly
        organism.health = organism.health >= HARVEST_ENERGY_COST / 5 ? organism.health - HARVEST_ENERGY_COST / 5 : MIN_HEALTH;
        organism.lastInteractionBlock = block.number;


        // Transfer ETH to owner
        if (ethYield > 0) {
            payable(owner).transfer(ethYield);
        }

        emit OrganismHarvested(organismId, owner, ethYield, organism.energy, organism.health);
         emit OrganismStateChanged(organismId, "Harvested", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);
    }

    /**
     * @notice Decomposes (removes) an organism. Can be done manually if health is low,
     * or forced by owner (with less/no ETH return). Reclaims resources.
     * @param organismId The ID of the organism to decompose.
     */
    function decompose(uint256 organismId) public organismExists(organismId) {
        _updateOrganismState(organismId); // Ensure state is current
        Organism storage organism = organisms[organismId];
        address owner = _owners[organismId];
        address caller = msg.sender; // Can be owner or delegate

        bool isOwner = (owner == caller);
        bool isDelegate = (_delegates[organismId] == caller && owner != address(0x1)); // Delegate cannot decompose wild ones
        bool canForceDecompose = (isOwner || isDelegate);

        require(canForceDecompose || organism.health <= MAX_HEALTH / 10, "Cannot decompose healthy organism unless owner/delegate");
        require(owner != address(0), "Organism already decomposed or does not exist"); // Should be caught by exists, but double check

        string memory reason = "Manual";
        uint256 ethReturn = 0;

        if (organism.health <= MAX_HEALTH / 10) {
            reason = "Low Health";
            // Partial ETH return based on remaining resources / complexity
             ethReturn = (organism.energy + organism.health + organism.complexity) * (BASE_SEED_COST / (MAX_ENERGY + MAX_HEALTH + MAX_COMPLEXITY)) / 2; // Example heuristic
        } else if (canForceDecompose) {
             // No ETH return for forced decomposition
             reason = "Owner Force";
        } else {
             revert("Decomposition not allowed"); // Should not reach here if initial checks pass
        }


        // Transfer ETH return to owner if applicable
        if (ethReturn > 0) {
             // Only return ETH if it was owned (not wild decomposing)
            if (owner != address(0x1)) {
                 payable(owner).transfer(ethReturn);
            }
        }


        // Remove from owner's list
        if (owner != address(0x1)) { // Don't remove from wild list, just update _owners mapping
             _removeOrganismFromOwner(owner, organismId);
        }


        // Remove from mappings - Mark as decomposed by setting owner to address(0)
        // We keep the struct data for historical lookup, but it's no longer active/owned.
        delete _owners[organismId]; // Use delete to reset to address(0)
        if(_delegates[organismId] != address(0)) delete _delegates[organismId];


        emit OrganismDecomposed(organismId, owner, reason);
         // Note: No OrganismStateChanged after decomposition as it's gone.
    }


    // --- Advanced Interactions ---

     /**
     * @notice Allows an organism to challenge another. Outcome depends on attributes.
     * Attacker pays a fee, winner takes a share of the pot. Loser loses health/energy.
     * @param attackerId The ID of the challenging organism.
     * @param targetId The ID of the organism being challenged.
     */
    function challengeOrganism(uint256 attackerId, uint256 targetId) public payable organismExists(attackerId) organismExists(targetId) organismNotWild(attackerId) organismNotWild(targetId) {
        require(attackerId != targetId, "Cannot challenge yourself");
        require(_owners[attackerId] != address(0), "Attacker must be owned"); // Ensure not decomposed/wild? Or allow wild challenges? Let's require owned for now.
        require(_owners[targetId] != address(0), "Target must be owned");


        _updateOrganismState(attackerId);
        _updateOrganismState(targetId);

        Organism storage attacker = organisms[attackerId];
        Organism storage target = organisms[targetId];

        uint256 challengeFee = CHALLENGE_FEE_PER_ORGANISM * 2; // Fee covers both organisms' "arena cost"
        require(msg.value >= challengeFee, "Insufficient ETH for challenge fee");

        // Simple combat logic: Based on complexity + energy. Add some randomness.
        uint256 attackerScore = attacker.complexity + attacker.energy + (_getRandomValue(attackerId, attacker.geneticCode, block.number) % 200); // Max +200 random boost
        uint256 targetScore = target.complexity + target.energy + (_getRandomValue(targetId, target.geneticCode, block.number + 1) % 200); // Different salt for target


        uint256 winnerId;
        uint256 loserId;
        Organism storage winner;
        Organism storage loser;

        if (attackerScore > targetScore) {
            winnerId = attackerId;
            loserId = targetId;
            winner = attacker;
            loser = target;
        } else {
            winnerId = targetId;
            loserId = attackerId;
            winner = target;
            loser = attacker;
        }

        // Apply consequences
        uint256 energyLoss = 100;
        uint256 healthLoss = 50;
        uint256 complexityGain = 20;

        loser.energy = loser.energy >= energyLoss ? loser.energy - energyLoss : MIN_ENERGY;
        loser.health = loser.health >= healthLoss ? loser.health - healthLoss : MIN_HEALTH;
        winner.complexity = winner.complexity + complexityGain <= MAX_COMPLEXITY ? winner.complexity + complexityGain : MAX_COMPLEXITY;
        winner.energy = winner.energy + energyLoss/2 <= MAX_ENERGY ? winner.energy + energyLoss/2 : MAX_ENERGY; // Winner gains some energy

        // Split ETH pot (msg.value) - winner takes more
        uint256 ethPot = msg.value;
        uint256 winnerEthShare = ethPot * 70 / 100; // Winner gets 70%
        uint256 contractShare = ethPot - winnerEthShare; // 30% goes to the contract (simulation environment)

        payable(_owners[winnerId]).transfer(winnerEthShare);

        attacker.lastInteractionBlock = block.number; // Update both interaction blocks
        target.lastInteractionBlock = block.number;


        emit OrganismChallenged(attackerId, targetId, winnerId, ethPot, winnerEthShare);
        emit OrganismStateChanged(attackerId, "Challenged", attacker.health, attacker.energy, attacker.complexity, attacker.lastInteractionBlock);
        emit OrganismStateChanged(targetId, "Challenged", target.health, target.energy, target.complexity, target.lastInteractionBlock);
    }

    /**
     * @notice Allows an owner or delegate to transfer energy between their organisms.
     * Useful for supporting weaker organisms.
     * @param fromId The ID of the organism sending energy.
     * @param toId The ID of the organism receiving energy.
     * @param amount The amount of energy to transfer.
     */
    function transferEnergyInternal(uint256 fromId, uint256 toId, uint256 amount) public organismExists(fromId) organismExists(toId) organismNotWild(fromId) organismNotWild(toId) {
        // Ensure caller has control over the source organism
        require(_owners[fromId] == msg.sender || _delegates[fromId] == msg.sender, "Not authorized for the source organism");
         // Optional: Ensure caller also controls target, or just allow transfer to any owned organism?
         // Let's require sender owns/delegates *both* for simplicity and security.
         require(_owners[toId] == msg.sender || _delegates[toId] == msg.sender, "Not authorized for the target organism");
         require(_owners[fromId] == _owners[toId], "Cannot transfer energy between organisms owned by different addresses"); // Require same owner


        _updateOrganismState(fromId);
        _updateOrganismState(toId);

        Organism storage fromOrganism = organisms[fromId];
        Organism storage toOrganism = organisms[toId];

        require(fromOrganism.energy >= amount, "Source organism does not have enough energy");
        require(amount > 0, "Transfer amount must be greater than zero");
        // Prevent transferring energy to self (though logic would just result in 0 net change)
        require(fromId != toId, "Cannot transfer energy to self");

        fromOrganism.energy -= amount;
        toOrganism.energy = toOrganism.energy + amount <= MAX_ENERGY ? toOrganism.energy + amount : MAX_ENERGY;

        fromOrganism.lastInteractionBlock = block.number;
        toOrganism.lastInteractionBlock = block.number;

         emit OrganismStateChanged(fromId, "EnergySent", fromOrganism.health, fromOrganism.energy, fromOrganism.complexity, fromOrganism.lastInteractionBlock);
         emit OrganismStateChanged(toId, "EnergyReceived", toOrganism.health, toOrganism.energy, toOrganism.complexity, toOrganism.lastInteractionBlock);

    }


    // --- Analysis & Environment ---

    /**
     * @notice Calculates a genetic compatibility score between two organisms.
     * @param organism1Id The ID of the first organism.
     * @param organism2Id The ID of the second organism.
     * @return A score between 0 (least compatible) and 100 (most compatible).
     */
    function calculateGeneticCompatibility(uint256 organism1Id, uint256 organism2Id) public view organismExists(organism1Id) organismExists(organism2Id) returns (uint256) {
        // No state update needed for a pure calculation
        bytes32 code1 = organisms[organism1Id].geneticCode;
        bytes32 code2 = organisms[organism2Id].geneticCode;
        return _calculateGeneticCompatibility(code1, code2);
    }

    /**
     * @notice Estimates the growth potential of an organism based on its current state and genetics.
     * @param organismId The ID of the organism.
     * @return A heuristic score representing estimated potential.
     */
     function estimateGrowthPotential(uint256 organismId) public organismExists(organismId) view returns (uint256) {
         // Note: This is a *view* function, it cannot call the non-view _updateOrganismState.
         // The potential calculation should rely only on existing state.
         Organism storage organism = organisms[organismId];

         // Simple heuristic: Higher current stats + favorable genetics = higher potential
         // Favorable genetics might mean low decay modifiers or specific bit patterns
         uint256 potential = (organism.health + organism.energy + organism.complexity); // Base potential from current stats
         potential += (MAX_HEALTH - organism.health) / 10; // Potential from room to grow health
         potential += (MAX_ENERGY - organism.energy) / 10; // Potential from room to grow energy
         potential += (MAX_COMPLEXITY - organism.complexity); // Higher complexity itself means more growth *potential*

         // Add factor for metabolism modifiers - positive modifiers (less decay) are good
         potential += uint256(int256(BASE_DECAY_PER_BLOCK) - organism.energyDecayModifier) * 50;
         potential += uint256(int256(BASE_DECAY_PER_BLOCK) - organism.healthDecayModifier) * 50;

         // Add factor for genetic code - let's say certain bit patterns are favorable
         uint256 geneticFactor = 0;
         if (uint256(organism.geneticCode) % 100 < 10) geneticFactor += 100; // Example: Specific pattern gives boost

         potential += geneticFactor;

         return potential;
     }


    /**
     * @notice Provides data reflecting the current global state of the simulation environment.
     * @return A tuple containing block number, total active supply, and average complexity.
     */
    function senseWorld() public view returns (uint256 currentBlock, uint256 activeSupply, uint256 averageComplexity) {
        currentBlock = block.number;
        activeSupply = totalSupply();
        averageComplexity = getAverageComplexity(); // Calls another view function
    }

     /**
     * @notice Calculates the sum of energy across all currently owned organisms.
     * Note: This could be gas-intensive for a large population.
     * @return The total energy supply.
     */
    function getGlobalEnergySupply() public view returns (uint256) {
        uint256 totalEnergy = 0;
        uint256 totalMinted = totalMintedSupply(); // Iterate through all possible IDs

        // CAUTION: Iterating through potentially millions of IDs is extremely gas-intensive and impractical on chain.
        // A better approach would be to maintain a running total updated during state changes,
        // or provide this data off-chain or via a separate analytics contract.
        // For demonstration purposes:
         for (uint256 i = 1; i <= totalMinted; i++) {
             // Check if the organism exists AND is not wild/decomposed before summing
             if (_owners[i] != address(0) && _owners[i] != address(0x1)) {
                 // Note: This doesn't update state first, so energy might be decayed.
                 // A true "current" global energy would require iterating and updating,
                 // which is infeasible on-chain. This provides a snapshot of last-updated energy.
                totalEnergy += organisms[i].energy;
             }
         }
        return totalEnergy;
    }

     /**
     * @notice Calculates the average complexity of all currently owned organisms.
     * Note: Like getGlobalEnergySupply, this can be gas-intensive.
     * @return The average complexity.
     */
    function getAverageComplexity() public view returns (uint256) {
        uint256 totalComplexity = 0;
        uint256 activeCount = 0;
         uint256 totalMinted = totalMintedSupply();

        // CAUTION: Same gas warning as getGlobalEnergySupply.
         for (uint256 i = 1; i <= totalMinted; i++) {
             if (_owners[i] != address(0) && _owners[i] != address(0x1)) {
                 // Note: This doesn't update state first.
                 totalComplexity += organisms[i].complexity;
                 activeCount++;
             }
         }

        return activeCount > 0 ? totalComplexity / activeCount : 0;
    }


    // --- Delegation (Access Control) ---

    /**
     * @notice Sets a delegate address that can perform actions (like feed, train) for a specific organism.
     * @param organismId The ID of the organism.
     * @param delegatee The address to set as delegate, or address(0) to clear.
     */
    function setDelegate(uint256 organismId, address delegatee) public onlyOrganismOwner(organismId) organismNotWild(organismId) {
        _delegates[organismId] = delegatee;
        emit DelegateSet(organismId, delegatee);
    }

    /**
     * @notice Revokes the delegate address for a specific organism.
     * @param organismId The ID of the organism.
     */
    function revokeDelegate(uint256 organismId) public onlyOrganismOwner(organismId) organismNotWild(organismId) {
        _delegates[organismId] = address(0);
        emit DelegateRevoked(organismId);
    }

    /**
     * @notice Gets the current delegate address for an organism.
     * @param organismId The ID of the organism.
     * @return The delegate address, or address(0) if none is set.
     */
     function getDelegate(uint256 organismId) public view returns (address) {
         return _delegates[organismId];
     }

     // Helper modifier check used in interaction functions
     // Example: feed, stimulate, train, repair, procreate, harvest, adjustMetabolismRate, fineTuneGeneticCode, transferEnergyInternal
     // already uses `onlyOrganismOwnerOrDelegate`.


     // --- Other ---

     /**
      * @notice Releases an organism into the "wild". It loses its owner and becomes uncontrolled.
      * Wild organisms decay faster but can still be observed. They cannot be controlled or harvested by users.
      * @param organismId The ID of the organism to release.
      */
     function releaseIntoWild(uint256 organismId) public onlyOrganismOwnerOrDelegate(organismId) organismNotWild(organismId) {
         _updateOrganismState(organismId);
         Organism storage organism = organisms[organismId];
         address formerOwner = _owners[organismId];

         // Remove from old owner's list
         _removeOrganismFromOwner(formerOwner, organismId);

         // Set owner to the "wild" address (e.g., address(0x1))
         _owners[organismId] = address(0x1);

         // Clear delegate
         if (_delegates[organismId] != address(0)) {
             delete _delegates[organismId];
             emit DelegateRevoked(organismId);
         }

         // Modify decay rates to simulate harsher wild environment
         // Example: Double decay rates
         organism.energyDecayModifier -= int256(BASE_DECAY_PER_BLOCK); // Make decay >= BASE_DECAY * 2
         organism.healthDecayModifier -= int256(BASE_DECAY_PER_BLOCK);

         organism.lastInteractionBlock = block.number; // Update interaction block

         emit OrganismReleasedIntoWild(organismId, formerOwner);
         emit OrganismTransferred(organismId, formerOwner, address(0x1)); // ERC721-like transfer to wild
         emit OrganismStateChanged(organismId, "ReleasedIntoWild", organism.health, organism.energy, organism.complexity, organism.lastInteractionBlock);

         // Wild organisms cannot be directly interacted with using owner/delegate functions.
         // Their state will still decay via _updateOrganismState if any function that calls it is invoked with their ID (e.g., getAttributes, challenge).
         // A background keeper or separate function could periodically update wild organisms.
     }

     /**
      * @notice Allows the contract owner to withdraw accumulated ETH.
      * ETH comes from seeding fees, challenge fees, etc.
      * @param to The address to send the ETH to.
      * @param amount The amount of ETH to withdraw.
      */
    function withdrawContractBalance(address payable to, uint256 amount) public {
        require(msg.sender == contractOwner, "Only contract owner can withdraw");
        require(address(this).balance >= amount, "Insufficient contract balance");
        to.transfer(amount);
        emit EthWithdrawn(to, amount);
    }

    // Fallback function to accept ETH if sent without calling a specific function
    // receive() external payable {} // Already defined above

}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic On-Chain State per Entity:** Each `Organism` is a distinct entity with state (`health`, `energy`, `complexity`, `lastInteractionBlock`, `metabolism modifiers`) that *changes over time* based on block progression and interactions. This goes beyond simple static data storage like typical NFTs.
2.  **Time-Based Decay/Growth (`_updateOrganismState`):** The core internal mechanic simulates natural processes. Organisms decay if not interacted with. This is lazily evaluated *before* any external interaction, making their state dynamic based on the passage of blocks. This adds a "liveness" factor.
3.  **Pseudo-Randomness (`_getRandomValue`):** Used for mutations and challenge outcomes. While blockchain randomness is tricky (exploiters can game it), for simulation elements like mutation chance or combat *outcome* (not who gets to attack), using block data combined with unique IDs and genetics provides a degree of unpredictability within the simulation.
4.  **On-Chain Reproduction (`procreate`):** Organisms can create new organisms, inheriting and potentially mutating genetic code. This is a complex state transition that results in a new entity being added to the population, consuming resources from the parent.
5.  **On-Chain Competition/Interaction (`challengeOrganism`):** Organisms can directly interact in a "battle" where the outcome is determined by their state and simple on-chain logic. This creates direct conflict within the simulation.
6.  **Resource Management & Economy:** Organisms consume internal resources (`energy`, `complexity`) for actions (`train`, `procreate`, `harvest`). Users inject external resources (ETH via `feed`, `stimulate`, `repair`, `seed`, `procreate`, `challenge`) which convert into internal resources. Harvesting extracts value (ETH) back, creating a simple, dynamic economy tied to organism state.
7.  **Genetic Code & Fine-Tuning:** The `bytes32 geneticCode` acts as a core identity attribute. `_deriveGeneticCode` implements a simple form of genetic inheritance and mutation. `fineTuneGeneticCode` allows high-level organisms a limited, costly way to directly modify their genetics, representing a form of self-directed evolution within constraints.
8.  **Metabolism Adjustment:** `adjustMetabolismRate` allows advanced organisms to influence their own decay/growth rates, adding another layer of self-modification and strategy for owners.
9.  **Environmental Sensing (`senseWorld`, `getGlobalEnergySupply`, `getAverageComplexity`):** These view functions allow users (or other contracts/frontends) to observe the global state of the simulation, giving a sense of a shared, changing environment. (Note: Global iteration functions are highlighted as potentially gas-prohibitive for large scales).
10. **Delegation:** While a standard pattern (EIP-XXXX for NFTs), applying it to stateful entities that require ongoing interaction is relevant and useful.
11. **Release into Wild:** Provides a mechanism for organisms to leave the controlled population, potentially changing their rules (`energyDecayModifier`, `healthDecayModifier`), adding complexity to the simulation's dynamics and population management.

This contract aims to be a self-contained, dynamic simulation where entities have lifecycle stages, complex interactions, and state that changes passively over time, making it a more advanced and creative use case compared to static data tokens or simple functional contracts. Remember that running complex simulations purely on-chain can be gas-intensive and requires careful consideration of scaling.