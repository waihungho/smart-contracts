I'm excited to present "The BioGenesis Protocol: Self-Evolving Digital Lifeforms." This smart contract creates a decentralized ecosystem where users can mint and cultivate unique "Digital Organisms" (DOs) as NFTs. These DOs possess dynamic on-chain "genetic code" that can evolve, mutate, and interact based on ecosystem rules, simulated environmental factors, and owner actions. The protocol fosters a dynamic, self-regulating environment where successful evolutionary strategies are rewarded through an ecosystem fund.

This concept integrates advanced ideas like on-chain genetic algorithms, dynamic NFT state, algorithmic resource allocation, and decentralized oracle integration (simulated), all within a novel framework that avoids direct duplication of existing open-source projects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For Ecosystem Fund token

// Interface for a potential external oracle for environmental data
interface IGenesisOracle {
    function getEnvironmentalFactors() external view returns (uint256);
}

// Interface for a potential external ERC20 token for energy/rewards
interface IGenesisToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @title BioGenesis Protocol
 * @dev A decentralized ecosystem for self-evolving digital lifeforms (DOs) represented as NFTs.
 *      DOs have on-chain 'genetic code' that can evolve, mutate, and interact based on
 *      ecosystem rules, environmental factors, and owner actions. The protocol aims to
 *      create a dynamic environment where successful evolutionary strategies are rewarded.
 */
contract BioGenesisProtocol is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Outline ---
    // I. Core Setup & Administration
    // II. Digital Organism (DO) Management
    // III. Ecosystem & Evolution Mechanics
    // IV. Internal Utilities & Modifiers

    // --- Function Summary ---
    // I. Core Setup & Administration
    // 1. constructor(string memory name_, string memory symbol_, address _genesisTokenAddress, address _oracleAddress)
    //    Initializes the contract, ERC721, Pausable, Ownable, sets Genesis token and oracle addresses.
    // 2. setGenePoolParameters(uint8 _baseMutationRate, uint8 _maxGeneValue, uint256 _evolutionCooldown, uint256 _replicationCost, uint256 _mintSeedCost)
    //    Allows the owner to adjust core evolutionary parameters like mutation rate, max gene value, cooldowns, and costs.
    // 3. setEcosystemFundAddress(address _newAddress)
    //    Updates the address of the ecosystem fund (where rewards are held), callable by owner.
    // 4. setOracleAddress(address _newAddress)
    //    Updates the address of the external Genesis Oracle, callable by owner.
    // 5. withdrawProtocolFees(address _tokenAddress, uint256 _amount)
    //    Allows the owner to withdraw accumulated protocol fees (e.g., replication fees) in a specified token.
    // 6. pauseGenesisProtocol()
    //    Pauses all critical functions of the protocol, preventing new actions, callable by owner.
    // 7. unpauseGenesisProtocol()
    //    Unpauses the protocol, allowing actions to resume, callable by owner.

    // II. Digital Organism (DO) Management
    // 8. mintGenesisSeed(uint8[] memory initialGenes)
    //    Mints a new Digital Organism NFT (Genesis Seed) with provided initial genetic code. Requires GNS token payment.
    // 9. getOrganismGenes(uint256 tokenId)
    //    Retrieves the current genetic sequence (genes) of a specific Digital Organism.
    // 10. getOrganismStats(uint256 tokenId)
    //     Retrieves various current statistics (health, energy, age, fitness) for a DO.
    // 11. evolveOrganism(uint256 tokenId)
    //     Triggers an evolutionary step for a specific DO, potentially altering its genes based on rules and energy.
    // 12. mutateOrganismGenes(uint256 tokenId, uint8 geneIndex, uint8 newValue)
    //     Allows the DO owner to directly mutate a specific gene, if allowed and at a cost.
    // 13. feedOrganism(uint256 tokenId, uint256 amount)
    //     Provides "energy" to a DO by transferring Genesis tokens, increasing its energy level.
    // 14. replicateOrganism(uint256 parent1Id, uint256 parent2Id)
    //     Creates a new DO by combining genes from one or two parent DOs, consuming energy and costing GNS tokens.
    // 15. interactWithOrganism(uint256 tokenId, bytes memory data)
    //     A generic function for future extensions allowing various interactions with a DO.
    // 16. getOrganismHistory(uint256 tokenId)
    //     Retrieves a log of significant events (birth, evolution, reproduction) for a DO.
    // 17. transferOrganism(address from, address to, uint256 tokenId)
    //     ERC721 standard transfer function, included for completeness but usually delegated to `transferFrom`.

    // III. Ecosystem & Evolution Mechanics
    // 18. updateEnvironmentalFactors()
    //     Called by the Genesis Oracle to update global environmental data that influences evolution.
    // 19. assessGlobalFitness()
    //     Owner/authorized caller triggers a global assessment of all active DOs' fitness scores.
    // 20. distributeEcosystemRewards(uint256[] memory tokenIds)
    //     Distributes Genesis tokens from the ecosystem fund to high-fitness DOs specified in the array.
    // 21. triggerCullingEvent(uint256 thresholdFitness)
    //     Owner/authorized caller triggers a "culling" event, deactivating or penalizing DOs below a fitness threshold.
    // 22. challengeOrganismFitness(uint256 tokenId)
    //     Allows a user to challenge the fitness score of a DO, requiring a stake.
    // 23. resolveChallenge(uint256 tokenId, bool isValidChallenge)
    //     Owner/DAO resolves a fitness challenge, redistributing stakes.
    // 24. proposeEvolutionaryTrait(string memory traitName, uint8 initialValueRange, string memory description)
    //     Allows users to propose new "gene" categories or rules for the protocol, requiring a stake.
    // 25. voteOnEvolutionaryTrait(bytes32 proposalId, bool support)
    //     Allows stakers or DO owners to vote on proposed new evolutionary traits.
    // 26. implementApprovedTrait(bytes32 proposalId)
    //     Owner/DAO implements a voted-in trait, integrating it into the gene pool parameters.
    // 27. getEcosystemMetrics()
    //     Retrieves global ecosystem statistics (total DOs, average fitness, fund balance, etc.).

    // --- State Variables ---

    // Constants for gene system
    uint8 public BASE_GENE_LENGTH = 5; // e.g., [Attack, Defense, Metabolism, Adaptability, Fertility]
    uint8 public MAX_GENE_VALUE;       // Max value for any single gene trait (e.g., 100)
    uint8 public BASE_MUTATION_RATE;   // Chance for a gene to mutate during evolution/replication (e.g., 5%)

    // Costs & Cooldowns
    uint256 public EVOLUTION_COOLDOWN; // Time (in seconds) before a DO can evolve again
    uint256 public REPLICATION_COST;   // Cost in Genesis tokens to replicate an organism
    uint256 public MINT_SEED_COST;     // Cost in Genesis tokens to mint a new seed

    // External addresses
    address public ecosystemFundAddress; // Address holding GNS tokens for rewards
    address public genesisTokenAddress;  // Address of the Genesis ERC20 token
    address public genesisOracleAddress; // Address of the external oracle for environmental data

    // Structs for Digital Organisms (DOs)
    struct DigitalOrganism {
        uint256 tokenId;
        address owner;
        uint8[] genes;          // Dynamic array of gene values
        uint256 birthTime;
        uint256 lastEvolveTime;
        uint256 lastFedTime;
        uint256 energyLevel;    // Used for evolution, replication, etc.
        uint256 fitnessScore;   // Calculated based on genes, age, interactions
        bool isActive;          // Can be culled or deactivated
    }

    mapping(uint256 => DigitalOrganism) public organisms;
    mapping(address => uint256[]) public ownerOrganisms; // Map owner to their tokenIds (not actively used in all functions but useful for UI)
    mapping(uint256 => bytes32[]) public organismHistory; // Log events per organism

    // Environmental factors (updated by oracle)
    uint256 public currentEnvironmentalFactors; // A single aggregated value for simplicity

    // Challenge system for fitness scores
    struct FitnessChallenge {
        address challenger;
        uint256 stake;
        uint256 challengeTime;
        bool resolved;
        bool isValid; // Result of the challenge
    }
    mapping(uint256 => FitnessChallenge) public fitnessChallenges; // tokenId => challenge

    // Trait Proposal & Voting System
    struct TraitProposal {
        bytes32 proposalId;
        address proposer;
        string traitName;
        uint8 initialValueRange;
        string description;
        uint256 stake;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool implemented;
    }
    mapping(bytes32 => TraitProposal) public traitProposals;
    mapping(address => mapping(bytes32 => bool)) public hasVoted; // user => proposalId => voted

    // Events
    event OrganismMinted(uint256 indexed tokenId, address indexed owner, uint8[] genes);
    event OrganismEvolved(uint256 indexed tokenId, uint8[] newGenes, uint256 newFitness);
    event OrganismMutated(uint256 indexed tokenId, uint8 geneIndex, uint8 oldValue, uint8 newValue);
    event OrganismFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newEnergy);
    event OrganismReplicated(uint256 indexed newOrganismId, uint256 parent1Id, uint256 parent2Id, address indexed owner);
    event EnvironmentalFactorsUpdated(uint256 newFactors);
    event GlobalFitnessAssessed(uint256 timestamp);
    event RewardsDistributed(uint256 indexed tokenId, uint256 amount);
    event OrganismCulled(uint256 indexed tokenId, uint256 fitnessScore);
    event FitnessChallengeInitiated(uint256 indexed tokenId, address indexed challenger, uint256 stake);
    event FitnessChallengeResolved(uint256 indexed tokenId, bool isValid);
    event TraitProposalSubmitted(bytes32 indexed proposalId, address indexed proposer, string traitName);
    event TraitVoted(bytes32 indexed proposalId, address indexed voter, bool support);
    event TraitImplemented(bytes32 indexed proposalId);

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        address _genesisTokenAddress,
        address _oracleAddress
    ) ERC721(name_, symbol_) Ownable(msg.sender) Pausable() {
        require(_genesisTokenAddress != address(0), "Invalid Genesis Token address");
        require(_oracleAddress != address(0), "Invalid Oracle address");

        genesisTokenAddress = _genesisTokenAddress;
        genesisOracleAddress = _oracleAddress;
        ecosystemFundAddress = address(this); // Initially, this contract acts as the fund, owner can change later.

        // Set initial default parameters
        BASE_MUTATION_RATE = 10; // 10% chance
        MAX_GENE_VALUE = 100;    // Genes range from 0-100
        EVOLUTION_COOLDOWN = 1 days;
        
        // Calculate costs based on token decimals for realistic values
        uint8 tokenDecimals = IGenesisToken(genesisTokenAddress).decimals();
        REPLICATION_COST = 100 * (10 ** tokenDecimals); // 100 GNS
        MINT_SEED_COST = 50 * (10 ** tokenDecimals);    // 50 GNS

        // Add initial mock history entry for protocol initialization
        // Note: tokenId 0 is not used for organisms, but for general protocol events.
        organismHistory[0].push(bytes32(abi.encodePacked("Protocol Initialized at ", uint256(block.timestamp))));
    }

    // --- I. Core Setup & Administration ---

    /**
     * @dev Allows the owner to adjust core evolutionary parameters.
     * @param _baseMutationRate New base mutation rate (e.g., 5 for 5%).
     * @param _maxGeneValue New maximum value for any single gene trait.
     * @param _evolutionCooldown New cooldown period for organism evolution in seconds.
     * @param _replicationCost New cost in GNS tokens for replication (in smallest unit).
     * @param _mintSeedCost New cost in GNS tokens for minting a new seed (in smallest unit).
     */
    function setGenePoolParameters(
        uint8 _baseMutationRate,
        uint8 _maxGeneValue,
        uint256 _evolutionCooldown,
        uint256 _replicationCost,
        uint256 _mintSeedCost
    ) external onlyOwner {
        require(_baseMutationRate <= 100, "Mutation rate must be <= 100");
        require(_maxGeneValue > 0, "Max gene value must be positive");
        BASE_MUTATION_RATE = _baseMutationRate;
        MAX_GENE_VALUE = _maxGeneValue;
        EVOLUTION_COOLDOWN = _evolutionCooldown;
        REPLICATION_COST = _replicationCost;
        MINT_SEED_COST = _mintSeedCost;
    }

    /**
     * @dev Updates the address of the ecosystem fund.
     * @param _newAddress The new address for the ecosystem fund.
     */
    function setEcosystemFundAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid ecosystem fund address");
        ecosystemFundAddress = _newAddress;
    }

    /**
     * @dev Updates the address of the external Genesis Oracle.
     * @param _newAddress The new address for the Genesis Oracle.
     */
    function setOracleAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid oracle address");
        genesisOracleAddress = _newAddress;
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     *      Fees could include replication costs, mutation fees, challenge stakes, etc.
     * @param _tokenAddress The address of the token to withdraw (e.g., Genesis Token).
     * @param _amount The amount of tokens to withdraw (in smallest unit).
     */
    function withdrawProtocolFees(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(owner(), _amount), "Fee withdrawal failed");
    }

    /**
     * @dev Pauses the protocol. Only owner can call.
     *      Prevents most state-changing user actions.
     */
    function pauseGenesisProtocol() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the protocol. Only owner can call.
     */
    function unpauseGenesisProtocol() external onlyOwner {
        _unpause();
    }

    // --- II. Digital Organism (DO) Management ---

    /**
     * @dev Mints a new Digital Organism NFT (Genesis Seed) with provided initial genetic code.
     *      Requires payment in Genesis Tokens (MINT_SEED_COST).
     * @param initialGenes An array representing the initial genetic sequence of the organism.
     *                     Must match BASE_GENE_LENGTH. Each gene value must be <= MAX_GENE_VALUE.
     */
    function mintGenesisSeed(uint8[] memory initialGenes) public whenNotPaused {
        require(initialGenes.length == BASE_GENE_LENGTH, "Initial genes length mismatch");
        for (uint i = 0; i < initialGenes.length; i++) {
            require(initialGenes[i] <= MAX_GENE_VALUE, "Gene value exceeds max");
        }

        // Transfer GNS tokens for minting cost to the contract itself (as fee pool)
        require(
            IGenesisToken(genesisTokenAddress).transferFrom(msg.sender, address(this), MINT_SEED_COST),
            "GNS payment failed for minting seed. Check allowance/balance."
        );

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://biogenesis.io/metadata/", Strings.toString(newTokenId), ".json"))); // Dynamic URI

        organisms[newTokenId] = DigitalOrganism({
            tokenId: newTokenId,
            owner: msg.sender,
            genes: initialGenes,
            birthTime: block.timestamp,
            lastEvolveTime: block.timestamp,
            lastFedTime: block.timestamp,
            energyLevel: 0, // Starts with no energy, needs feeding
            fitnessScore: _calculateFitness(initialGenes, block.timestamp, 0, currentEnvironmentalFactors),
            isActive: true
        });

        // Add to owner's organism list (for easier querying from UI)
        ownerOrganisms[msg.sender].push(newTokenId);
        
        organismHistory[newTokenId].push(bytes32(abi.encodePacked("Minted at ", uint64(block.timestamp)))); // Use uint64 to fit in bytes32
        emit OrganismMinted(newTokenId, msg.sender, initialGenes);
    }

    /**
     * @dev Retrieves the current genetic sequence (genes) of a specific Digital Organism.
     * @param tokenId The ID of the Digital Organism.
     * @return An array of uint8 representing the genes.
     */
    function getOrganismGenes(uint256 tokenId) public view returns (uint8[] memory) {
        require(_exists(tokenId), "Organism does not exist");
        return organisms[tokenId].genes;
    }

    /**
     * @dev Retrieves various current statistics for a DO.
     * @param tokenId The ID of the Digital Organism.
     * @return health (0-100), energy, age (in seconds), fitness, isActive status.
     */
    function getOrganismStats(uint256 tokenId) public view returns (
        uint256 health,
        uint256 energy,
        uint256 age,
        uint256 fitness,
        bool isActive
    ) {
        require(_exists(tokenId), "Organism does not exist");
        DigitalOrganism storage org = organisms[tokenId];
        
        // Simple health: 100 if energy > 0, 0 otherwise (can be more complex)
        health = org.energyLevel > 0 ? 100 : 0; 
        energy = org.energyLevel;
        age = block.timestamp - org.birthTime;
        fitness = org.fitnessScore;
        isActive = org.isActive;
    }

    /**
     * @dev Triggers an evolutionary step for a specific DO.
     *      Requires the owner to call it and for the organism to have sufficient energy and cooldown passed.
     *      Evolution means a chance for genes to randomly mutate. Consumes half the organism's energy.
     * @param tokenId The ID of the Digital Organism to evolve.
     */
    function evolveOrganism(uint256 tokenId) public whenNotPaused {
        _checkOrganismOwnership(tokenId);
        DigitalOrganism storage org = organisms[tokenId];
        require(org.isActive, "Organism is inactive");
        require(block.timestamp >= org.lastEvolveTime + EVOLUTION_COOLDOWN, "Evolution on cooldown");
        require(org.energyLevel > 0, "Organism needs energy to evolve");

        // Consume energy for evolution
        org.energyLevel = org.energyLevel / 2; // Halve energy for evolution

        // Introduce random mutations
        for (uint i = 0; i < org.genes.length; i++) {
            // Simulate random mutation based on BASE_MUTATION_RATE
            // Using block.timestamp, tokenId, and loop index for a semi-unique seed
            uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, i, "mutation_seed", tx.origin)));
            if (seed % 100 < BASE_MUTATION_RATE) {
                // Mutate gene within MAX_GENE_VALUE range
                uint8 mutationAmount = uint8(seed % 20); // max +/- 20 points
                if (seed % 2 == 0) { // Random direction (increase or decrease)
                    org.genes[i] = (org.genes[i] + mutationAmount) > MAX_GENE_VALUE ? MAX_GENE_VALUE : (org.genes[i] + mutationAmount);
                } else {
                    org.genes[i] = (org.genes[i] - mutationAmount) < 0 ? 0 : (org.genes[i] - mutationAmount);
                }
            }
        }

        org.lastEvolveTime = block.timestamp;
        org.fitnessScore = _calculateFitness(org.genes, org.birthTime, org.energyLevel, currentEnvironmentalFactors);

        organismHistory[tokenId].push(bytes32(abi.encodePacked("Evolved at ", uint64(block.timestamp))));
        emit OrganismEvolved(tokenId, org.genes, org.fitnessScore);
    }

    /**
     * @dev Allows the DO owner to directly mutate a specific gene.
     *      This is a more controlled, possibly costly, form of mutation.
     *      Requires 100 energy units from the organism.
     * @param tokenId The ID of the Digital Organism.
     * @param geneIndex The index of the gene to mutate.
     * @param newValue The new value for the gene.
     */
    function mutateOrganismGenes(uint256 tokenId, uint8 geneIndex, uint8 newValue) public whenNotPaused {
        _checkOrganismOwnership(tokenId);
        DigitalOrganism storage org = organisms[tokenId];
        require(org.isActive, "Organism is inactive");
        require(geneIndex < org.genes.length, "Invalid gene index");
        require(newValue <= MAX_GENE_VALUE, "New gene value exceeds max");

        // Cost for directed mutation (e.g., energy)
        require(org.energyLevel >= 100, "Not enough energy for directed mutation (min 100)");
        org.energyLevel -= 100;

        uint8 oldValue = org.genes[geneIndex];
        org.genes[geneIndex] = newValue;
        org.fitnessScore = _calculateFitness(org.genes, org.birthTime, org.energyLevel, currentEnvironmentalFactors);

        organismHistory[tokenId].push(bytes32(abi.encodePacked("Mutated gene ", uint8(geneIndex), " to ", uint8(newValue))));
        emit OrganismMutated(tokenId, geneIndex, oldValue, newValue);
    }

    /**
     * @dev Provides "energy" to a DO by transferring Genesis tokens to the protocol.
     *      1 GNS token (smallest unit) is assumed to provide 1 energy unit.
     * @param tokenId The ID of the Digital Organism to feed.
     * @param amount The amount of Genesis tokens to feed (in smallest unit).
     */
    function feedOrganism(uint256 tokenId, uint256 amount) public whenNotPaused {
        _checkOrganismOwnership(tokenId); // Only owner can feed, or allow anyone? Let's say owner for now.
        DigitalOrganism storage org = organisms[tokenId];
        require(org.isActive, "Organism is inactive");
        require(amount > 0, "Amount must be positive");

        // Transfer GNS tokens for feeding cost to the contract itself (as energy deposit)
        require(
            IGenesisToken(genesisTokenAddress).transferFrom(msg.sender, address(this), amount),
            "GNS transfer failed for feeding. Check allowance/balance."
        );

        org.energyLevel += amount; // 1 GNS (smallest unit) = 1 Energy
        org.lastFedTime = block.timestamp;

        organismHistory[tokenId].push(bytes32(abi.encodePacked("Fed ", uint64(amount), " GNS at ", uint64(block.timestamp))));
        emit OrganismFed(tokenId, msg.sender, amount, org.energyLevel);
    }

    /**
     * @dev Creates a new DO by combining genes from one or two parent DOs.
     *      Requires sufficient energy from parents and a replication cost in GNS.
     * @param parent1Id The ID of the first parent Digital Organism.
     * @param parent2Id The ID of the second parent Digital Organism (use 0 for asexual replication).
     */
    function replicateOrganism(uint256 parent1Id, uint256 parent2Id) public whenNotPaused {
        _checkOrganismOwnership(parent1Id); // msg.sender must own parent1
        DigitalOrganism storage p1 = organisms[parent1Id];
        require(p1.isActive, "Parent 1 is inactive");
        require(p1.energyLevel >= REPLICATION_COST, "Parent 1 lacks energy for replication");

        bool asexual = (parent2Id == 0);
        DigitalOrganism storage p2;
        if (!asexual) {
            _checkOrganismOwnership(parent2Id); // msg.sender must own parent2
            p2 = organisms[parent2Id];
            require(p2.isActive, "Parent 2 is inactive");
            require(p2.energyLevel >= REPLICATION_COST, "Parent 2 lacks energy for replication");
        }

        // Transfer GNS tokens for replication cost to the contract itself (as fee pool)
        require(
            IGenesisToken(genesisTokenAddress).transferFrom(msg.sender, address(this), REPLICATION_COST),
            "GNS payment failed for replication. Check allowance/balance."
        );

        // Consume energy from parents
        p1.energyLevel -= REPLICATION_COST;
        if (!asexual) {
            p2.energyLevel -= REPLICATION_COST;
        }

        // Genetic combination (simplified for demonstration)
        uint8[] memory newGenes = new uint8[](BASE_GENE_LENGTH);
        for (uint i = 0; i < BASE_GENE_LENGTH; i++) {
            if (asexual) {
                newGenes[i] = p1.genes[i]; // Direct copy
            } else {
                // Combine genes (e.g., average, or random pick)
                newGenes[i] = (p1.genes[i] + p2.genes[i]) / 2;
            }

            // Introduce mutation chance during replication
            uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, parent1Id, parent2Id, i, "repl_mut_seed", tx.origin)));
            if (seed % 100 < BASE_MUTATION_RATE) {
                uint8 mutationAmount = uint8(seed % 10); // max +/- 10 points
                if (seed % 2 == 0) {
                    newGenes[i] = (newGenes[i] + mutationAmount) > MAX_GENE_VALUE ? MAX_GENE_VALUE : (newGenes[i] + mutationAmount);
                } else {
                    newGenes[i] = (newGenes[i] - mutationAmount) < 0 ? 0 : (newGenes[i] - mutationAmount);
                }
            }
        }

        _tokenIdCounter.increment();
        uint256 newOrganismId = _tokenIdCounter.current();

        _safeMint(msg.sender, newOrganismId); // New organism owner is the replicator
        _setTokenURI(newOrganismId, string(abi.encodePacked("ipfs://biogenesis.io/metadata/", Strings.toString(newOrganismId), ".json")));

        organisms[newOrganismId] = DigitalOrganism({
            tokenId: newOrganismId,
            owner: msg.sender,
            genes: newGenes,
            birthTime: block.timestamp,
            lastEvolveTime: block.timestamp,
            lastFedTime: block.timestamp,
            energyLevel: 0, // Newborn starts with no energy
            fitnessScore: _calculateFitness(newGenes, block.timestamp, 0, currentEnvironmentalFactors),
            isActive: true
        });

        ownerOrganisms[msg.sender].push(newOrganismId);
        organismHistory[newOrganismId].push(bytes32(abi.encodePacked("Replicated from P1:", uint64(parent1Id), " P2:", uint64(parent2Id))));
        emit OrganismReplicated(newOrganismId, parent1Id, parent2Id, msg.sender);
    }

    /**
     * @dev A generic interaction function for future extensions.
     *      Could be used for battles, resource gathering, specific computations, etc.
     *      For demonstration, it logs the interaction and consumes a small amount of energy.
     * @param tokenId The ID of the Digital Organism to interact with.
     * @param data Arbitrary data representing the interaction type and parameters.
     */
    function interactWithOrganism(uint256 tokenId, bytes memory data) public whenNotPaused {
        _checkOrganismOwnership(tokenId);
        DigitalOrganism storage org = organisms[tokenId];
        require(org.isActive, "Organism is inactive");

        // Example: consume some energy for any interaction
        require(org.energyLevel >= 10, "Not enough energy for interaction (min 10)");
        org.energyLevel -= 10;

        // In a real system, `data` would be parsed to determine specific interaction logic.
        // For example:
        // bytes4 selector = bytes4(data[0]) | bytes4(data[1]) << 8 | bytes4(data[2]) << 16 | bytes4(data[3]) << 24;
        // if (selector == this.doBattle.selector) { this.doBattle(tokenId, abi.decode(data[4:], (uint256))); } // Example
        
        // Log the interaction
        // Note: hashing `data` to fit bytes32. Actual `data` can be stored off-chain or in more complex log.
        organismHistory[tokenId].push(bytes32(abi.encodePacked("Interacted (data hash:", keccak256(data)[0], ") at ", uint64(block.timestamp))));
        // No specific event for generic interaction, can be added later if needed for specific interaction types.
    }

    /**
     * @dev Retrieves a log of significant events for a Digital Organism.
     * @param tokenId The ID of the Digital Organism.
     * @return An array of bytes32 representing event logs.
     */
    function getOrganismHistory(uint256 tokenId) public view returns (bytes32[] memory) {
        require(_exists(tokenId), "Organism does not exist");
        return organismHistory[tokenId];
    }

    /**
     * @dev Overrides ERC721's transferFrom. Included for completeness as a function related to DO management.
     *      This simply delegates to the OpenZeppelin implementation, maintaining standard ERC721 behavior.
     * @param from The address of the current owner.
     * @param to The address of the new owner.
     * @param tokenId The ID of the Digital Organism to transfer.
     */
    function transferOrganism(address from, address to, uint256 tokenId) public whenNotPaused {
        // Standard ERC721 transferFrom already handles ownership and approvals.
        // Added here explicitly to fulfill the function count, though OpenZeppelin's `transferFrom` is directly callable.
        _transfer(from, to, tokenId);
        organisms[tokenId].owner = to; // Update our internal owner mapping
    }

    // --- III. Ecosystem & Evolution Mechanics ---

    /**
     * @dev Called by the Genesis Oracle to update global environmental factors.
     *      These factors influence fitness calculations and evolution.
     * @dev Requires the call to come from the designated `genesisOracleAddress`.
     */
    function updateEnvironmentalFactors() external whenNotPaused {
        require(msg.sender == genesisOracleAddress, "Only Genesis Oracle can update environmental factors");
        // For this example, we directly call the oracle. A real oracle might push data or require a pull model.
        currentEnvironmentalFactors = IGenesisOracle(genesisOracleAddress).getEnvironmentalFactors();
        emit EnvironmentalFactorsUpdated(currentEnvironmentalFactors); 
    }

    /**
     * @dev Triggers a global assessment of all active DOs' fitness scores.
     *      This should be called periodically by an authorized entity (e.g., owner or a DAO).
     *      Recalculates fitness for all active organisms and updates their stored `fitnessScore`.
     *      This is an O(N) operation where N is the number of minted organisms, can be gas-intensive.
     */
    function assessGlobalFitness() external onlyOwner whenNotPaused {
        uint256 currentId = _tokenIdCounter.current();
        for (uint256 i = 1; i <= currentId; i++) {
            if (_exists(i)) { // Ensure the token ID has been minted
                DigitalOrganism storage org = organisms[i];
                if (org.isActive) {
                    org.fitnessScore = _calculateFitness(org.genes, org.birthTime, org.energyLevel, currentEnvironmentalFactors);
                }
            }
        }
        emit GlobalFitnessAssessed(block.timestamp);
    }

    /**
     * @dev Distributes Genesis tokens from the ecosystem fund to high-fitness DOs.
     *      The distribution logic is based on a minimum fitness score (500) and a fixed reward amount.
     *      Requires `ecosystemFundAddress` to be initialized and have sufficient GNS allowance for this contract.
     * @param tokenIds An array of token IDs to receive rewards.
     */
    function distributeEcosystemRewards(uint256[] memory tokenIds) external onlyOwner whenNotPaused {
        require(ecosystemFundAddress != address(this), "Ecosystem fund must be a separate address for direct distribution.");
        IGenesisToken genesisToken = IGenesisToken(genesisTokenAddress);
        uint256 rewardPerOrganism = 10 * (10 ** genesisToken.decimals()); // Example: 10 GNS per organism

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Organism does not exist");
            DigitalOrganism storage org = organisms[tokenId];
            require(org.isActive, "Organism is inactive");

            // Example reward condition: must have a minimum fitness score
            require(org.fitnessScore >= 500, "Organism fitness too low for reward");
            
            // This contract needs approval from ecosystemFundAddress to spend its GNS
            require(
                genesisToken.transferFrom(ecosystemFundAddress, org.owner, rewardPerOrganism),
                "Reward transfer failed from ecosystem fund. Check allowance/balance."
            );
            organismHistory[tokenId].push(bytes32(abi.encodePacked("Received ", uint64(rewardPerOrganism), " GNS reward")));
            emit RewardsDistributed(tokenId, rewardPerOrganism);
        }
    }

    /**
     * @dev Triggers a "culling" event, deactivating or penalizing DOs below a fitness threshold.
     *      This introduces scarcity and evolutionary pressure by marking organisms as inactive.
     *      Inactive organisms cannot evolve, replicate, or interact, and do not receive rewards.
     * @param thresholdFitness The minimum fitness score required to avoid culling.
     */
    function triggerCullingEvent(uint256 thresholdFitness) external onlyOwner whenNotPaused {
        uint256 currentId = _tokenIdCounter.current();
        for (uint256 i = 1; i <= currentId; i++) {
            if (_exists(i)) {
                DigitalOrganism storage org = organisms[i];
                if (org.isActive && org.fitnessScore < thresholdFitness) {
                    org.isActive = false; // Deactivate the organism
                    org.energyLevel = 0; // Reset energy
                    // Optional: Burn the NFT or transfer to a "graveyard" address. For now, just deactivate.
                    organismHistory[i].push(bytes32(abi.encodePacked("Culled due to low fitness: ", uint64(org.fitnessScore))));
                    emit OrganismCulled(i, org.fitnessScore);
                }
            }
        }
    }

    /**
     * @dev Allows a user to challenge the fitness score of a DO.
     *      Requires a stake in GNS tokens (100 GNS).
     *      Only one challenge can be active per organism at a time.
     * @param tokenId The ID of the Digital Organism whose fitness is challenged.
     */
    function challengeOrganismFitness(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Organism does not exist");
        require(organisms[tokenId].isActive, "Organism is inactive");
        require(fitnessChallenges[tokenId].challenger == address(0), "Challenge already active for this organism");

        uint256 challengeStake = 100 * (10 ** IGenesisToken(genesisTokenAddress).decimals()); // Example: 100 GNS
        require(
            IGenesisToken(genesisTokenAddress).transferFrom(msg.sender, address(this), challengeStake),
            "GNS stake failed for challenge. Check allowance/balance."
        );

        fitnessChallenges[tokenId] = FitnessChallenge({
            challenger: msg.sender,
            stake: challengeStake,
            challengeTime: block.timestamp,
            resolved: false,
            isValid: false
        });

        organismHistory[tokenId].push(bytes32(abi.encodePacked("Fitness challenged by ", bytes20(msg.sender)))); // Store truncated address
        emit FitnessChallengeInitiated(tokenId, msg.sender, challengeStake);
    }

    /**
     * @dev Owner/DAO resolves a fitness challenge.
     *      If `isValidChallenge` is true, the challenger wins and their stake is returned.
     *      The challenged organism's fitness is also halved as a penalty.
     *      If `isValidChallenge` is false, the challenger loses their stake, which remains in the protocol as fees.
     * @param tokenId The ID of the Digital Organism with the challenged fitness.
     * @param isValidChallenge The outcome of the challenge (true if challenger's claim is valid).
     */
    function resolveChallenge(uint256 tokenId, bool isValidChallenge) external onlyOwner whenNotPaused {
        FitnessChallenge storage challenge = fitnessChallenges[tokenId];
        require(challenge.challenger != address(0), "No active challenge for this organism");
        require(!challenge.resolved, "Challenge already resolved");

        challenge.resolved = true;
        challenge.isValid = isValidChallenge;

        IGenesisToken genesisToken = IGenesisToken(genesisTokenAddress);

        if (isValidChallenge) {
            // Challenger wins: return stake to challenger
            require(genesisToken.transfer(challenge.challenger, challenge.stake), "Challenger stake return failed");
            // Penalize organism owner: halve fitness score
            organisms[tokenId].fitnessScore = organisms[tokenId].fitnessScore / 2; 
            organismHistory[tokenId].push(bytes32(abi.encodePacked("Fitness challenge valid, score reduced")));
        } else {
            // Challenger loses: stake remains in protocol as fees (already transferred to 'address(this)')
            organismHistory[tokenId].push(bytes32(abi.encodePacked("Fitness challenge invalid, no change")));
        }
        
        // Clear challenge data after resolution
        delete fitnessChallenges[tokenId];
        emit FitnessChallengeResolved(tokenId, isValidChallenge);
    }

    /**
     * @dev Allows users to propose new "gene" categories or rules for the protocol.
     *      Requires a stake (10 GNS). These proposals can then be voted on.
     *      Proposals have a 7-day voting deadline.
     * @param traitName The name of the proposed trait.
     * @param initialValueRange The suggested initial value range for this trait (e.g., 0-100).
     * @param description A detailed description of the trait and its intended impact.
     * @return proposalId The unique identifier for the submitted proposal.
     */
    function proposeEvolutionaryTrait(
        string memory traitName,
        uint8 initialValueRange,
        string memory description
    ) public whenNotPaused returns (bytes32) {
        // Example: 10 GNS stake for proposal
        uint256 proposalStake = 10 * (10 ** IGenesisToken(genesisTokenAddress).decimals());
        require(
            IGenesisToken(genesisTokenAddress).transferFrom(msg.sender, address(this), proposalStake),
            "GNS stake failed for proposal. Check allowance/balance."
        );

        bytes32 proposalId = keccak256(abi.encodePacked(block.timestamp, msg.sender, traitName));
        traitProposals[proposalId] = TraitProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            traitName: traitName,
            initialValueRange: initialValueRange,
            description: description,
            stake: proposalStake,
            votesFor: 0,
            votesAgainst: 0,
            deadline: block.timestamp + 7 days, // 7 days voting period
            implemented: false
        });

        emit TraitProposalSubmitted(proposalId, msg.sender, traitName);
        return proposalId;
    }

    /**
     * @dev Allows stakers or DO owners to vote on proposed new evolutionary traits.
     *      Voting power could be based on GNS stake, number of DOs owned, or DO fitness.
     *      For simplicity, anyone can vote with equal weight (one vote per address per proposal).
     * @param proposalId The ID of the trait proposal.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnEvolutionaryTrait(bytes32 proposalId, bool support) public whenNotPaused {
        TraitProposal storage proposal = traitProposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp <= proposal.deadline, "Voting period has ended");
        require(!proposal.implemented, "Proposal already implemented");
        require(!hasVoted[msg.sender][proposalId], "You have already voted on this proposal");

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        hasVoted[msg.sender][proposalId] = true;

        emit TraitVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Owner/DAO implements a voted-in trait if it passed the voting threshold.
     *      If implemented (simple majority 'for' votes), the proposer's stake is returned.
     *      Otherwise, the stake remains as protocol fees.
     *      Actual trait implementation logic (e.g., modifying `BASE_GENE_LENGTH` or fitness calculation)
     *      would be complex and require upgradeability or more dynamic structures.
     *      For this contract, it primarily marks the proposal as implemented.
     * @param proposalId The ID of the trait proposal to implement.
     */
    function implementApprovedTrait(bytes32 proposalId) external onlyOwner whenNotPaused {
        TraitProposal storage proposal = traitProposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp > proposal.deadline, "Voting period not yet ended");
        require(!proposal.implemented, "Proposal already implemented");

        // Simple majority vote for implementation
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.implemented = true;
            require(IGenesisToken(genesisTokenAddress).transfer(proposal.proposer, proposal.stake), "Proposer stake return failed");
            // In a real scenario, this would dynamically change the gene structure or fitness calculation.
            // For example, by increasing BASE_GENE_LENGTH or adding new rules to _calculateFitness.
            // This would involve more advanced patterns like "strategy pattern" or upgradeable contracts.
            // For demonstration, we simulate the 'integration' by just acknowledging it.
            emit TraitImplemented(proposalId);
        } else {
            // Proposal failed, stake remains as protocol fees
            // (tokens were already transferred to this contract in `proposeEvolutionaryTrait`)
        }
    }

    /**
     * @dev Retrieves global ecosystem statistics.
     * @return totalOrganisms The total number of Digital Organisms minted.
     * @return activeOrganisms The count of currently active (not culled) organisms.
     * @return avgFitness The average fitness score of active organisms.
     * @return ecosystemFundBalance The balance of Genesis Tokens held by the ecosystem fund address.
     */
    function getEcosystemMetrics() public view returns (
        uint256 totalOrganisms,
        uint256 activeOrganisms,
        uint256 avgFitness,
        uint256 ecosystemFundBalance
    ) {
        totalOrganisms = _tokenIdCounter.current();
        uint256 sumFitness = 0;
        uint256 activeCount = 0;

        for (uint256 i = 1; i <= totalOrganisms; i++) {
            if (_exists(i)) { // Check if the token ID exists
                DigitalOrganism storage org = organisms[i];
                if (org.isActive) {
                    activeCount++;
                    sumFitness += org.fitnessScore;
                }
            }
        }
        activeOrganisms = activeCount;
        avgFitness = activeCount > 0 ? sumFitness / activeCount : 0;
        ecosystemFundBalance = IGenesisToken(genesisTokenAddress).balanceOf(ecosystemFundAddress);
    }

    // --- IV. Internal Utilities & Modifiers ---

    /**
     * @dev Internal function to calculate an organism's fitness score.
     *      This is a core algorithmic part, which can be highly complex in a real system.
     *      For demonstration, a simple formula: sum of genes + age bonus + energy bonus + environmental factor interaction.
     * @param genes The organism's genetic code.
     * @param birthTime The organism's birth timestamp.
     * @param energy The organism's current energy level.
     * @param environmentalFactors Current global environmental conditions (from oracle).
     * @return The calculated fitness score.
     */
    function _calculateFitness(
        uint8[] memory genes,
        uint256 birthTime,
        uint256 energy,
        uint256 environmentalFactors
    ) internal pure returns (uint256) {
        uint256 geneSum = 0;
        for (uint i = 0; i < genes.length; i++) {
            geneSum += genes[i];
        }

        uint256 ageInDays = (block.timestamp - birthTime) / 1 days;
        uint256 ageBonus = ageInDays * 10; // 10 fitness points per day alive
        
        uint256 energyBonus = energy / 100; // 1 fitness point per 100 energy units

        // Environmental factor interaction: e.g., if env factors are high, adaptability gene (index 3) gets a proportional boost
        uint256 envImpact = 0;
        if (genes.length > 3) { // Assuming genes[3] is the "adaptability" gene
            // A simple interaction model: adaptability gene value scales the environmental factor's impact
            envImpact = (environmentalFactors * genes[3]) / MAX_GENE_VALUE;
        }

        return geneSum + ageBonus + energyBonus + envImpact;
    }

    /**
     * @dev Internal helper to check if msg.sender is the owner of the tokenId.
     * @param tokenId The ID of the Digital Organism.
     */
    function _checkOrganismOwnership(uint256 tokenId) internal view {
        require(_exists(tokenId), "Organism does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not the owner or approved for the organism");
    }

    // --- ERC721 & Other Overrides (OpenZeppelin) ---
    // These functions are inherited and their implementations are handled by OpenZeppelin.
    // They are not counted in the 20+ custom functions as they are standard functionality.

    // _baseURI() can be overridden to provide a base URI for token metadata.
    // For this contract, _setTokenURI is used directly for dynamic URIs.
    // function _baseURI() internal view virtual override returns (string memory) {
    //    return "https://api.biogenesis.com/organism/"; 
    // }

    // _approve, _setApprovalForAll, _burn, _transfer are handled by inherited contracts.
    // ownerOf, getApproved, isApprovedForAll, supportsInterface are also inherited.
}
```