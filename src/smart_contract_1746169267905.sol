Okay, here is a Solidity smart contract designed with an interesting, advanced, and creative concept: "ChronoGene Entities". This contract manages unique digital entities (like NFTs, but with custom implementation not directly inheriting ERC721 to avoid simple duplication) that possess 'genetic' parameters. These parameters dynamically evolve over time and through user-initiated actions, influenced by simulated 'environmental' factors and requiring 'energy' resources.

It incorporates concepts like:
*   **Dynamic State:** Entity traits (`geneticParameters`), energy, and generation change over time and based on interactions.
*   **Resource Management:** Entities have 'energy' needed for actions, which regenerates over time.
*   **Time-Based Mechanics:** Actions have cooldowns; energy regeneration is time-dependent.
*   **Environmental Interaction:** Global 'environmental' parameters influence entity adaptation and mutation outcomes.
*   **On-Chain Parameters:** Core genetic and environmental data are stored and manipulated on-chain.
*   **Delegation:** Owners can delegate specific actions for their entities to other addresses.
*   **Pseudo-Randomness/Deterministic Influence:** Mutation can be influenced by a seed or environmental factors, offering deterministic paths while allowing for variability.

This design aims to provide a framework for dynamic, evolving digital collectibles or game assets, moving beyond static NFTs.

---

**Contract Outline and Function Summary**

**Contract Name:** ChronoGeneEntities

**Purpose:** To manage unique digital entities with dynamic, evolving genetic parameters, energy resources, and time-based mechanics influenced by environmental factors.

**Key Concepts:**
*   **Entity:** A unique token (`tokenId`) representing a digital lifeform or object.
*   **Genetic Parameters:** An array of `uint256` values defining the entity's traits.
*   **Energy:** A resource required to perform actions like mutation, regenerates over time.
*   **Generation:** A counter tracking how many significant mutations an entity has undergone.
*   **Environment:** Global parameters influencing entity state and adaptation.
*   **Adaptation Score:** Measures how well an entity's genes match the current environment.
*   **Delegation:** Permission granted to another address to perform specific actions on a single entity.

**Function Summary:**

**I. Core Management & Info (Similar to ERC721 but Custom)**
1.  `constructor(string memory name, string memory symbol, uint256 maxEntities, uint256 geneArraySize, uint256 initialMaxEnergy, uint256 baseEnergyRegenRate, uint256 mutationEnergyCost, uint256 randomMutationCooldown, uint256 envMutationCooldown, uint256 energyRegenCooldown)`: Initializes contract settings.
2.  `mintGenesisEntity(address recipient, uint256[] initialGenes)`: Mints the very first entity (restricted, e.g., to contract deployer).
3.  `mintEntity(address recipient, uint256[] initialGenes)`: Mints a new entity (can be restricted based on contract logic, e.g., requiring burning resources, specific conditions).
4.  `getEntityOwner(uint256 tokenId)`: Returns the owner of an entity.
5.  `transferEntity(address from, address to, uint256 tokenId)`: Transfers ownership of an entity. Includes necessary checks.
6.  `getTotalEntities()`: Returns the total number of entities minted.

**II. Entity State & View Functions**
7.  `getEntityGenes(uint256 tokenId)`: Returns the genetic parameters of an entity.
8.  `getEntityEnergy(uint256 tokenId)`: Returns the current energy level of an entity.
9.  `getEntityGeneration(uint256 tokenId)`: Returns the generation count of an entity.
10. `getEntityStats(uint256 tokenId)`: Returns a struct containing core stats (creation time, last mutation, generation, energy, adaptation).
11. `getEnergyRegenRate(uint256 tokenId)`: Returns the energy regeneration rate for an entity (can be gene-dependent).
12. `getMutationCooldownEnd(uint256 tokenId)`: Returns the timestamp when the mutation cooldown ends for an entity.
13. `getEnergyRegenCooldownEnd(uint256 tokenId)`: Returns the timestamp when the energy regeneration cooldown ends for an entity.

**III. Evolution & Interaction Functions**
14. `triggerRandomMutation(uint256 tokenId, uint256 mutationSeed)`: Initiates a random mutation of the entity's genes. Requires energy, respects cooldowns. Mutation outcome influenced by seed and potentially genes.
15. `applyEnvironmentalMutation(uint256 tokenId)`: Initiates a mutation influenced by the current global environmental parameters. Requires energy, respects cooldowns.
16. `regenerateEnergy(uint256 tokenId)`: Allows the entity owner/delegate to manually trigger energy regeneration based on elapsed time and regen rate. Respects cooldown.

**IV. Environment Management & Adaptation**
17. `updateEnvironmentalParameters(uint256[] newEnvironment)`: Admin function to update the global environmental parameters.
18. `getEnvironmentalParameters()`: Returns the current global environmental parameters.
19. `getEnvironmentalAdaptation(uint256 tokenId)`: Calculates and returns the entity's adaptation score to the current environment.

**V. Delegation**
20. `setEntityDelegate(uint256 tokenId, address delegatee)`: Sets an address authorized to perform certain actions (like mutation, regen) for a specific entity.
21. `removeEntityDelegate(uint256 tokenId)`: Removes the delegate for an entity.
22. `getEntityDelegate(uint256 tokenId)`: Returns the current delegate for an entity.
23. `isDelegateForEntity(address account, uint256 tokenId)`: Checks if an account is the authorized delegate for an entity.

**VI. Metadata & Descriptions**
24. `setBaseMetadataURI(string memory uri)`: Admin function to set the base URI for metadata.
25. `tokenURI(uint256 tokenId)`: Returns the full metadata URI for an entity (follows ERC721 standard naming for compatibility but custom logic).
26. `setGeneDescriptionMapping(uint256 geneIndex, uint256 geneValue, string memory description)`: Admin function to map specific gene index/value combinations to human-readable descriptions on-chain.
27. `getGeneDescription(uint256 geneIndex, uint256 geneValue)`: Returns the human-readable description for a specific gene index and value combination.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for admin roles

contract ChronoGeneEntities is Ownable {

    // --- Structs ---
    struct Entity {
        uint256 creationTime;
        uint256 lastMutationTime;
        uint256 generation;
        uint256 energy;
        uint256[] geneticParameters;
    }

    // --- State Variables ---

    // Core Entity Data
    mapping(uint256 => Entity) private _entities;
    mapping(uint256 => address) private _owners;
    uint256 private _entityCount; // Acts as the next tokenId

    // Configuration
    string private _name;
    string private _symbol;
    uint256 public MAX_ENTITIES;
    uint256 public GENE_ARRAY_SIZE;
    uint256 public INITIAL_MAX_ENERGY; // Max energy capacity
    uint256 public BASE_ENERGY_REGEN_RATE; // Energy gained per second during regeneration
    uint256 public MUTATION_ENERGY_COST;
    uint256 public RANDOM_MUTATION_COOLDOWN; // Cooldown in seconds for random mutation
    uint256 public ENV_MUTATION_COOLDOWN; // Cooldown in seconds for environmental mutation
    uint256 public ENERGY_REGEN_COOLDOWN; // Cooldown in seconds for triggering regen

    // Dynamic State
    mapping(uint256 => uint256) private _mutationCooldownEnds; // tokenId => timestamp
    mapping(uint256 => uint256) private _energyRegenCooldownEnds; // tokenId => timestamp
    uint256[] public environmentalParameters; // Global parameters affecting entities

    // Delegation
    mapping(uint256 => address) private _delegates; // tokenId => authorized delegate

    // Metadata & Descriptions
    string private _baseMetadataURI;
    mapping(uint256 => mapping(uint256 => string)) private _geneDescriptions; // geneIndex => geneValue => description

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint256[] initialGenes);
    event EntityTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event EntityMutated(uint256 indexed tokenId, uint256 generation, uint256[] newGenes, uint256 energySpent);
    event EnergyRegenerated(uint256 indexed tokenId, uint256 newEnergy);
    event DelegateSet(uint256 indexed tokenId, address indexed delegatee);
    event EnvironmentalParametersUpdated(uint256[] newParameters);
    event GeneDescriptionSet(uint256 indexed geneIndex, uint256 indexed geneValue, string description);

    // --- Modifiers ---
    modifier onlyEntityOwnerOrDelegate(uint256 tokenId) {
        require(_owners[tokenId] == _msgSender() || _delegates[tokenId] == _msgSender(), "Not entity owner or delegate");
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxEntities,
        uint256 geneArraySize,
        uint256 initialMaxEnergy,
        uint256 baseEnergyRegenRate,
        uint256 mutationEnergyCost,
        uint256 randomMutationCooldown,
        uint256 envMutationCooldown,
        uint256 energyRegenCooldown
    ) Ownable(msg.sender) {
        _name = name;
        _symbol = symbol;
        MAX_ENTITIES = maxEntities;
        GENE_ARRAY_SIZE = geneArraySize;
        INITIAL_MAX_ENERGY = initialMaxEnergy;
        BASE_ENERGY_REGEN_RATE = baseEnergyRegenRate;
        MUTATION_ENERGY_COST = mutationEnergyCost;
        RANDOM_MUTATION_COOLDOWN = randomMutationCooldown;
        ENV_MUTATION_COOLDOWN = envMutationCooldown;
        ENERGY_REGEN_COOLDOWN = energyRegenCooldown;

        // Initialize environmental parameters with default values (can be updated later)
        environmentalParameters = new uint256[](geneArraySize);
        for(uint i = 0; i < geneArraySize; i++) {
             environmentalParameters[i] = 50; // Default neutral environment
        }
    }

    // --- I. Core Management & Info ---

    /**
     * @notice Mints the very first entity. Restricted to the contract deployer.
     * @param recipient The address to mint the entity to.
     * @param initialGenes The initial genetic parameters for the entity.
     */
    function mintGenesisEntity(address recipient, uint256[] memory initialGenes) external onlyOwner {
        require(_entityCount == 0, "Genesis entity already minted");
        require(initialGenes.length == GENE_ARRAY_SIZE, "Invalid initial gene count");
        _mint(recipient, initialGenes);
    }

    /**
     * @notice Mints a new entity. Can be restricted by contract logic.
     * @param recipient The address to mint the entity to.
     * @param initialGenes The initial genetic parameters for the entity.
     */
    function mintEntity(address recipient, uint256[] memory initialGenes) external {
        // Add custom restrictions here if needed (e.g., require payment, specific conditions)
        // require(msg.sender == <some condition>, "Minting restricted");
        require(_entityCount < MAX_ENTITIES, "Max entities minted");
        require(initialGenes.length == GENE_ARRAY_SIZE, "Invalid initial gene count");

        _mint(recipient, initialGenes);
    }

    /**
     * @notice Internal minting function.
     */
    function _mint(address recipient, uint256[] memory initialGenes) internal {
        uint256 tokenId = _entityCount;
        uint256 currentTime = block.timestamp;

        _entities[tokenId] = Entity({
            creationTime: currentTime,
            lastMutationTime: currentTime, // Initially same as creation
            generation: 1, // Starts at generation 1
            energy: INITIAL_MAX_ENERGY, // Starts with full energy
            geneticParameters: initialGenes
        });
        _owners[tokenId] = recipient;
        _entityCount++;

        // Initialize cooldowns
        _mutationCooldownEnds[tokenId] = currentTime;
        _energyRegenCooldownEnds[tokenId] = currentTime;

        emit EntityMinted(tokenId, recipient, initialGenes);
    }

    /**
     * @notice Returns the owner of the entity.
     * @param tokenId The ID of the entity.
     * @return The owner's address.
     */
    function getEntityOwner(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Entity does not exist");
        return _owners[tokenId];
    }

    /**
     * @notice Transfers ownership of an entity.
     * @param from The current owner.
     * @param to The new owner.
     * @param tokenId The ID of the entity to transfer.
     */
    function transferEntity(address from, address to, uint256 tokenId) public {
        require(_exists(tokenId), "Entity does not exist");
        require(getEntityOwner(tokenId) == from, "Transfer: sender is not owner");
        require(to != address(0), "Transfer: transfer to the zero address");

        // Check if the caller is the owner or the delegate
        require(_owners[tokenId] == _msgSender() || _delegates[tokenId] == _msgSender(), "Transfer: caller is not owner or delegate");

        _owners[tokenId] = to;
        // Delegation is reset upon transfer
        delete _delegates[tokenId];

        emit EntityTransferred(tokenId, from, to);
    }

    /**
     * @notice Checks if an entity exists.
     * @param tokenId The ID of the entity.
     * @return True if the entity exists, false otherwise.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _entityCount && _owners[tokenId] != address(0);
    }

    /**
     * @notice Returns the total number of entities minted.
     */
    function getTotalEntities() public view returns (uint256) {
        return _entityCount;
    }

    // --- II. Entity State & View Functions ---

    /**
     * @notice Returns the genetic parameters of an entity.
     * @param tokenId The ID of the entity.
     * @return An array of uint256 representing the genes.
     */
    function getEntityGenes(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "Entity does not exist");
        return _entities[tokenId].geneticParameters;
    }

    /**
     * @notice Returns the current energy level of an entity.
     * @param tokenId The ID of the entity.
     * @return The current energy level.
     */
    function getEntityEnergy(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Entity does not exist");
        return _entities[tokenId].energy;
    }

    /**
     * @notice Returns the generation count of an entity.
     * @param tokenId The ID of the entity.
     * @return The generation count.
     */
    function getEntityGeneration(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Entity does not exist");
        return _entities[tokenId].generation;
    }

    /**
     * @notice Returns a summary struct of the entity's core statistics.
     * @param tokenId The ID of the entity.
     * @return An Entity struct containing core stats.
     */
    function getEntityStats(uint256 tokenId) public view returns (Entity memory) {
         require(_exists(tokenId), "Entity does not exist");
         // Note: Returns the stored struct, adaptation score needs separate calculation
         return _entities[tokenId];
    }


    /**
     * @notice Returns the energy regeneration rate for an entity.
     * @param tokenId The ID of the entity.
     * @return The regeneration rate per second.
     */
    function getEnergyRegenRate(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Entity does not exist");
        // Example: Regen rate could be based on BASE_ENERGY_REGEN_RATE plus gene bonuses
        // For simplicity, let's just return the base rate for now, but this is where gene influence would go.
        return BASE_ENERGY_REGEN_RATE;
    }

    /**
     * @notice Returns the timestamp when the random mutation cooldown ends for an entity.
     * @param tokenId The ID of the entity.
     * @return The cooldown end timestamp.
     */
    function getMutationCooldownEnd(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Entity does not exist");
        return _mutationCooldownEnds[tokenId];
    }

     /**
     * @notice Returns the timestamp when the energy regeneration cooldown ends for an entity.
     * @param tokenId The ID of the entity.
     * @return The cooldown end timestamp.
     */
    function getEnergyRegenCooldownEnd(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Entity does not exist");
        return _energyRegenCooldownEnds[tokenId];
    }


    // --- III. Evolution & Interaction Functions ---

    /**
     * @notice Triggers a random mutation for an entity's genes.
     * Requires energy and respects the mutation cooldown.
     * @param tokenId The ID of the entity.
     * @param mutationSeed A seed value to influence the mutation (e.g., block.timestamp, block.difficulty, user input).
     */
    function triggerRandomMutation(uint256 tokenId, uint256 mutationSeed) public onlyEntityOwnerOrDelegate(tokenId) {
        require(_exists(tokenId), "Entity does not exist");
        Entity storage entity = _entities[tokenId];
        require(entity.energy >= MUTATION_ENERGY_COST, "Insufficient energy for mutation");
        require(block.timestamp >= _mutationCooldownEnds[tokenId], "Mutation is on cooldown");

        entity.energy -= MUTATION_ENERGY_COST;
        uint256 currentTime = block.timestamp;
        _mutationCooldownEnds[tokenId] = currentTime + RANDOM_MUTATION_COOLDOWN;

        // --- Mutation Logic (Example) ---
        // This is a simplified example. Advanced logic could use the seed, current genes,
        // and other factors to deterministically (or pseudo-randomly) derive new genes.
        // Using keccak256 for simple pseudo-randomness based on inputs.
        uint256 randomValue = uint256(keccak256(abi.encodePacked(
            tokenId,
            currentTime,
            mutationSeed,
            block.prevrandao, // Use block.prevrandao in place of block.difficulty for modern Solidity
            _owners[tokenId]
        )));

        uint256 geneIndexToMutate = randomValue % GENE_ARRAY_SIZE;
        // Simple mutation: add/subtract a small random value, clamped within a range (e.g., 0-100)
        uint256 mutationAmount = (randomValue % 20) - 10; // Random value between -10 and +9
        int256 currentGene = int256(entity.geneticParameters[geneIndexToMutate]);
        int256 newGene = currentGene + mutationAmount;

        // Clamp gene value (example range 0 to 100)
        if (newGene < 0) newGene = 0;
        if (newGene > 100) newGene = 100;

        entity.geneticParameters[geneIndexToMutate] = uint256(newGene);
        entity.lastMutationTime = currentTime;
        entity.generation++;
        // --- End Mutation Logic ---

        emit EntityMutated(tokenId, entity.generation, entity.geneticParameters, MUTATION_ENERGY_COST);
    }

     /**
     * @notice Triggers a mutation influenced by the current global environmental parameters.
     * Requires energy and respects the environment mutation cooldown.
     * @param tokenId The ID of the entity.
     */
    function applyEnvironmentalMutation(uint256 tokenId) public onlyEntityOwnerOrDelegate(tokenId) {
        require(_exists(tokenId), "Entity does not exist");
        Entity storage entity = _entities[tokenId];
        require(entity.energy >= MUTATION_ENERGY_COST, "Insufficient energy for mutation"); // Could have different cost
        require(block.timestamp >= _mutationCooldownEnds[tokenId], "Environment mutation is on cooldown"); // Could have different cooldown

        entity.energy -= MUTATION_ENERGY_COST;
        uint256 currentTime = block.timestamp;
        _mutationCooldownEnds[tokenId] = currentTime + ENV_MUTATION_COOLDOWN; // Sets the cooldown for ANY mutation type

        // --- Environmental Mutation Logic (Example) ---
        // Genes drift towards the environmental parameters based on adaptation score?
        // Or specific genes shift based on env value?
        // Example: Each gene shifts slightly towards the corresponding environmental parameter
        require(environmentalParameters.length == GENE_ARRAY_SIZE, "Environmental parameters size mismatch");

        for(uint i = 0; i < GENE_ARRAY_SIZE; i++) {
            uint256 currentGene = entity.geneticParameters[i];
            uint256 envGene = environmentalParameters[i];

            // Simple drift: move gene 1 unit towards the env parameter
            if (currentGene < envGene) {
                entity.geneticParameters[i]++;
            } else if (currentGene > envGene) {
                entity.geneticParameters[i]--;
            }
            // Clamp gene value (example range 0 to 100)
            if (entity.geneticParameters[i] > 100) entity.geneticParameters[i] = 100;
            if (entity.geneticParameters[i] < 0) entity.geneticParameters[i] = 0; // Will wrap around for uint, need int logic if clamping below 0 is needed
        }

        entity.lastMutationTime = currentTime;
        entity.generation++;
        // --- End Environmental Mutation Logic ---

        emit EntityMutated(tokenId, entity.generation, entity.geneticParameters, MUTATION_ENERGY_COST);
    }


    /**
     * @notice Manually triggers energy regeneration for an entity.
     * Energy regenerates based on time elapsed since last regen/creation and regen rate.
     * Respects the energy regeneration cooldown.
     * @param tokenId The ID of the entity.
     */
    function regenerateEnergy(uint256 tokenId) public onlyEntityOwnerOrDelegate(tokenId) {
        require(_exists(tokenId), "Entity does not exist");
        Entity storage entity = _entities[tokenId];
        uint256 currentTime = block.timestamp;

        require(currentTime >= _energyRegenCooldownEnds[tokenId], "Energy regeneration is on cooldown");

        uint256 timeElapsed = currentTime - _energyRegenCooldownEnds[tokenId]; // Time since last regen trigger
        uint256 energyGained = timeElapsed * getEnergyRegenRate(tokenId); // Uses the entity's regen rate

        entity.energy += energyGained;
        if (entity.energy > INITIAL_MAX_ENERGY) { // Cap energy at max
            entity.energy = INITIAL_MAX_ENERGY;
        }

        _energyRegenCooldownEnds[tokenId] = currentTime + ENERGY_REGEN_COOLDOWN; // Set new cooldown

        emit EnergyRegenerated(tokenId, entity.energy);
    }


    // --- IV. Environment Management & Adaptation ---

    /**
     * @notice Updates the global environmental parameters. Only callable by the owner.
     * @param newEnvironment The new array of environmental parameters.
     */
    function updateEnvironmentalParameters(uint256[] memory newEnvironment) public onlyOwner {
        require(newEnvironment.length == GENE_ARRAY_SIZE, "Invalid environmental parameter count");
        environmentalParameters = newEnvironment;
        emit EnvironmentalParametersUpdated(newEnvironment);
    }

    /**
     * @notice Calculates and returns the entity's adaptation score to the current environment.
     * This is a view function and does not change state.
     * @param tokenId The ID of the entity.
     * @return The calculated adaptation score (higher is better adaptation).
     */
    function getEnvironmentalAdaptation(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Entity does not exist");
        require(environmentalParameters.length == GENE_ARRAY_SIZE, "Environmental parameters size mismatch");

        uint256[] memory genes = _entities[tokenId].geneticParameters;
        uint256 score = 0;
        uint256 maxPossibleDifference = 100 * GENE_ARRAY_SIZE; // Assuming genes are 0-100

        for(uint i = 0; i < GENE_ARRAY_SIZE; i++) {
            // Calculate difference between gene and environmental parameter
            uint256 difference;
            if (genes[i] > environmentalParameters[i]) {
                difference = genes[i] - environmentalParameters[i];
            } else {
                difference = environmentalParameters[i] - genes[i];
            }
            // Sum up differences (lower sum = better adaptation)
            score += difference;
        }

        // Invert the score so higher means better adaptation (max diff becomes 0 adaptation, 0 diff becomes max adaptation)
        return maxPossibleDifference > score ? maxPossibleDifference - score : 0;
    }

    // --- V. Delegation ---

    /**
     * @notice Sets an authorized delegate address for a specific entity.
     * The delegate can perform certain actions (like mutation, regen) on behalf of the owner.
     * @param tokenId The ID of the entity.
     * @param delegatee The address to authorize as delegate. Use address(0) to remove.
     */
    function setEntityDelegate(uint256 tokenId, address delegatee) public onlyEntityOwnerOrDelegate(tokenId) {
         require(_exists(tokenId), "Entity does not exist");
         require(_owners[tokenId] == _msgSender(), "Must be entity owner to set delegate"); // Only owner can set/change delegate
         _delegates[tokenId] = delegatee;
         emit DelegateSet(tokenId, delegatee);
    }

    /**
     * @notice Removes the authorized delegate for a specific entity.
     * @param tokenId The ID of the entity.
     */
    function removeEntityDelegate(uint256 tokenId) public onlyEntityOwnerOrDelegate(tokenId) {
        require(_exists(tokenId), "Entity does not exist");
        require(_owners[tokenId] == _msgSender(), "Must be entity owner to remove delegate"); // Only owner can remove delegate
        delete _delegates[tokenId];
        emit DelegateSet(tokenId, address(0));
    }

    /**
     * @notice Returns the authorized delegate address for an entity.
     * @param tokenId The ID of the entity.
     * @return The delegate address, or address(0) if none is set.
     */
    function getEntityDelegate(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Entity does not exist");
        return _delegates[tokenId];
    }

    /**
     * @notice Checks if an account is the authorized delegate for a specific entity.
     * @param account The address to check.
     * @param tokenId The ID of the entity.
     * @return True if the account is the delegate, false otherwise.
     */
    function isDelegateForEntity(address account, uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Entity does not exist");
        return _delegates[tokenId] == account;
    }


    // --- VI. Metadata & Descriptions ---

    /**
     * @notice Sets the base URI for entity metadata. Only callable by the owner.
     * The final token URI will be baseURI + tokenId.
     * @param uri The base URI string.
     */
    function setBaseMetadataURI(string memory uri) public onlyOwner {
        _baseMetadataURI = uri;
    }

    /**
     * @notice Returns the metadata URI for a specific entity.
     * Follows ERC721 naming convention for potential compatibility.
     * @param tokenId The ID of the entity.
     * @return The full metadata URI.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Entity does not exist");
        if (bytes(_baseMetadataURI).length == 0) {
            return "";
        }
        return string(abi.encodePacked(_baseMetadataURI, Strings.toString(tokenId)));
    }

    /**
     * @notice Sets a human-readable description for a specific gene index and value combination.
     * This allows mapping numerical genes to descriptive traits (e.g., gene 0, value 80 = "Strong Legs").
     * Only callable by the owner.
     * @param geneIndex The index of the gene (0 to GENE_ARRAY_SIZE-1).
     * @param geneValue The specific value of the gene.
     * @param description The human-readable description string.
     */
    function setGeneDescriptionMapping(uint256 geneIndex, uint256 geneValue, string memory description) public onlyOwner {
        require(geneIndex < GENE_ARRAY_SIZE, "Invalid gene index");
        // Add validation for geneValue range if needed (e.g., 0-100)
        _geneDescriptions[geneIndex][geneValue] = description;
        emit GeneDescriptionSet(geneIndex, geneValue, description);
    }

    /**
     * @notice Returns the human-readable description for a specific gene index and value.
     * @param geneIndex The index of the gene.
     * @param geneValue The value of the gene.
     * @return The description string, or an empty string if no description is set.
     */
    function getGeneDescription(uint256 geneIndex, uint256 geneValue) public view returns (string memory) {
         require(geneIndex < GENE_ARRAY_SIZE, "Invalid gene index");
         return _geneDescriptions[geneIndex][geneValue];
    }

    // --- Helper Functions (for potential compatibility or internal use) ---
    // (These are not counted in the 20+ function requirement but included for completeness)

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Using OpenZeppelin's Strings library for toString() in tokenURI
    library Strings {
        bytes16 private constant _HEX_TABLE = "0123456789abcdef";
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 length = 0;
            while (temp != 0) {
                length++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(length);
            while (value != 0) {
                length -= 1;
                buffer[length] = _HEX_TABLE[value % 10];
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```

**Explanation of Advanced/Creative Concepts in the Code:**

1.  **Dynamic State (`Entity` struct and related mappings):** The core idea isn't just owning a static token, but managing a token whose properties (`geneticParameters`, `energy`, `generation`) change over time and interaction.
2.  **Energy System:** The `energy` variable and the `regenerateEnergy` function introduce a resource management layer. Actions aren't free; they consume a depletable resource that requires active regeneration (or waiting for cooldown). This adds strategic depth.
3.  **Time-Based Mechanics (`_mutationCooldownEnds`, `_energyRegenCooldownEnds`):** Actions like mutating or regenerating energy are gated by cooldowns calculated using `block.timestamp`. This prevents spamming actions and introduces temporal dynamics.
4.  **Environmental Influence (`environmentalParameters`, `applyEnvironmentalMutation`, `getEnvironmentalAdaptation`):** The contract has a global state (`environmentalParameters`) that affects individual entities. `applyEnvironmentalMutation` demonstrates how this environment can drive specific types of evolution, and `getEnvironmentalAdaptation` provides a metric based on the environmental fit. This allows for simulation of external factors impacting digital life.
5.  **On-Chain Genes & Mutation (`geneticParameters`, `triggerRandomMutation`, `applyEnvironmentalMutation`):** While actual generative art would happen off-chain using these parameters, storing and mutating the `geneticParameters` on-chain makes the evolution process transparent, verifiable, and programmable. The mutation logic itself (`triggerRandomMutation`, `applyEnvironmentalMutation`) provides two distinct ways entities can change, one based on a pseudo-random seed and the other steered by the environment.
6.  **Delegation (`_delegates`, `setEntityDelegate`, `removeEntityDelegate`):** This allows an owner to grant limited control (specifically for actions like mutation and regeneration, as defined by the `onlyEntityOwnerOrDelegate` modifier) over a single entity to another address, without transferring ownership. This is more granular than ERC721's `setApprovalForAll`.
7.  **On-Chain Gene Descriptions (`_geneDescriptions`, `setGeneDescriptionMapping`, `getGeneDescription`):** While complex metadata often lives off-chain, mapping specific numerical gene values to human-readable descriptions *on-chain* provides a verifiable, decentralized way to add context to the gene data, reducing reliance on off-chain services for basic interpretation.
8.  **Custom Implementation (instead of inheriting ERC721):** By implementing ownership (`_owners`, `getEntityOwner`, `transferEntity`), existence checks (`_exists`), and metadata URI (`_baseMetadataURI`, `tokenURI`) manually, the contract avoids being a direct duplicate of the standard OpenZeppelin ERC721 contract, fulfilling that requirement while still providing token-like functionality tailored to its specific logic (e.g., delegation works differently, transfer resets delegate).

This contract provides a foundation for a complex system where digital entities live and evolve based on programmed rules, player interaction, and simulated environmental conditions, going well beyond standard token or NFT functionalities.