This smart contract, named `SymbioticAI_Ecosystem`, implements a novel decentralized ecosystem of evolving digital organisms, dubbed "Symbiotes." It leverages Dynamic NFTs (DNFTs) to represent these lifeforms, whose attributes change over time based on on-chain interactions, resource consumption, and environmental factors. A unique "Discovery & Research" mechanism allows the community to act as decentralized scientists, proposing and validating new insights into the Symbiotes' behavior and genetics.

This contract aims to be distinct from existing open-source projects by combining several advanced concepts into a cohesive, interactive system that encourages ongoing engagement and on-chain "scientific" progression.

---

### Outline and Function Summary

**Project Name:** SymbioticAI_Ecosystem

**Core Concepts:**
*   **Dynamic NFTs (DNFTs):** Symbiotes are NFTs with mutable attributes (energy, health, phenotype) that evolve and change over their lifecycle.
*   **On-chain Simulation:** Basic biological processes like metabolism, evolution, and reproduction are simulated through contract logic.
*   **Resource Management:** Symbiotes require a dedicated ERC20 "EnergyToken" to survive and thrive, introducing a resource sink and utility for the token.
*   **Decentralized Discovery & Research (DeSci Aspect):** Users can propose "discoveries" about Symbiote genetics and behaviors, stake tokens, and have them voted on by validators (or a DAO). Validated discoveries are added to a public knowledge base, simulating a decentralized scientific community.
*   **Environmental Factors:** Global parameters adjustable by the owner/DAO that influence the entire ecosystem, allowing for dynamic "event" scenarios.
*   **Genetic Mechanics:** Simplified DNA mutation and crossover for offspring generation and evolution.

**Key Components:**
1.  **Symbiote NFT (ERC721):** The fundamental unit representing a digital organism.
2.  **Symbiote Attributes:** Mutable properties like energy, health, species, age, and a dynamic "phenotype" string.
3.  **Immutable DNA:** A fixed genetic string for each Symbiote, defining its inherent potential.
4.  **EnergyToken (ERC20):** The primary resource consumed by Symbiotes.
5.  **Discovery System:** A mechanism for decentralized scientific inquiry and knowledge validation.

---

### Function Summary (Total: 32 Functions)

**I. Core NFT & Ownership (ERC721-like base & Admin):**
1.  `constructor(address _energyTokenAddress)`: Initializes the contract, sets the ERC20 EnergyToken address, and defines initial ecosystem parameters.
2.  `mintGenesisSymbiote(address to, string memory initialDNA)`: Allows the contract owner to mint initial Symbiotes to seed the ecosystem (limited supply).
3.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 function for transferring Symbiote ownership.
4.  `approve(address to, uint256 tokenId)`: Standard ERC721 function for approving a third party to transfer a Symbiote.
5.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 function for approving an operator to manage all of an owner's Symbiotes.
6.  `ownerOf(uint256 tokenId)`: Standard ERC721 function to query the owner of a Symbiote.
7.  `balanceOf(address owner)`: Standard ERC721 function to query the number of Symbiotes an address owns.
8.  `pause()`: Allows the contract owner to pause most user interactions with the contract.
9.  `unpause()`: Allows the contract owner to resume interactions after pausing.

**II. Symbiote Attributes & State Queries:**
10. `getSymbioteAttributes(uint256 tokenId)`: Returns a comprehensive tuple of a Symbiote's current mutable attributes (energy, health, phenotype, etc.).
11. `getSymbioteDNA(uint256 tokenId)`: Returns the immutable genetic code (DNA) string of a Symbiote.
12. `getSymbiotePhenotype(uint256 tokenId)`: Returns the current observable characteristics (phenotype) string of a Symbiote.
13. `getSymbioteMetabolicRate(uint256 tokenId)`: Calculates the current energy consumption rate of a Symbiote, influenced by its attributes and environmental factors.
14. `getSymbioteAge(uint256 tokenId)`: Calculates the age of a Symbiote in blockchain blocks since its birth.

**III. Energy & Metabolism:**
15. `feedSymbiote(uint256 tokenId, uint256 amount)`: Allows a Symbiote owner to provide EnergyToken, increasing the Symbiote's energy and health.
16. `getEnergyTokenAddress()`: Returns the contract address of the ERC20 EnergyToken.
17. `_processMetabolism(uint256 tokenId)`: Internal helper function to simulate the continuous energy decay and potential health impact due to metabolism over time. (Automatically called during key interactions).

**IV. Evolution & Reproduction:**
18. `evolveSymbiote(uint256 tokenId)`: Attempts to trigger an evolutionary change in a Symbiote, altering its phenotype and potentially DNA, based on energy, health, age, and environmental factors.
19. `reproduceSymbiote(uint256 parent1Id, uint256 parent2Id)`: Allows two Symbiotes owned by the same address to reproduce, minting a new offspring Symbiote with combined and mutated DNA.
20. `_generateOffspringDNA(uint256 parent1Id, uint256 parent2Id)`: Internal helper for combining DNA from two parent Symbiotes to create offspring DNA.
21. `_applyMutation(string memory originalDNA)`: Internal helper for introducing small, random mutations into a DNA string.

**V. Discovery & Research (DeSci Aspect):**
22. `proposeDiscovery(string memory description, string memory associatedDNA, uint256 stakeAmount)`: Enables any user to propose a "scientific discovery" or hypothesis about Symbiote behavior, backed by a stake of EnergyToken.
23. `voteOnDiscovery(uint256 proposalId, bool voteChoice)`: Allows designated validators (or DAO members) to cast a 'yes' or 'no' vote on a proposed discovery.
24. `finalizeDiscovery(uint256 proposalId)`: Callable by the owner (or a DAO), this function processes a discovery proposal after the voting period, validates it if it meets the threshold, adds it to the public knowledge base, and rewards the proposer.
25. `getDiscoveryDetails(uint256 proposalId)`: Retrieves all details about a specific discovery proposal, including votes and status.
26. `getValidatedDiscoveries()`: Returns a list of all descriptions for discoveries that have been successfully approved and added to the ecosystem's knowledge.
27. `withdrawStakedFunds(uint256 proposalId)`: Allows a proposer to reclaim their staked EnergyTokens if their discovery proposal was rejected.

**VI. Environmental Factors & System Parameters:**
28. `setGlobalEnvironmentalFactor(string memory factorName, uint256 value)`: Allows the contract owner to dynamically adjust global environmental parameters (e.g., "pollutionLevel", "resourceScarcity") that affect Symbiote behavior.
29. `getGlobalEnvironmentalFactors()`: Returns a list of configured global environmental factor names and their current values.
30. `setEvolutionDifficulty(uint256 newDifficulty)`: Adjusts the base difficulty/chance for Symbiotes to successfully evolve.
31. `setReproductionCooldown(uint256 newCooldown)`: Sets the minimum number of blocks required between a Symbiote's reproduction events.

**VII. System Utilities:**
32. `tokenURI(uint256 tokenId)`: ERC721 standard function that dynamically generates a Base64-encoded data URI containing JSON metadata for a given Symbiote, reflecting its current mutable attributes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256 to string conversion
import "@openzeppelin/contracts/utils/Base64.sol"; // For dataURI encoding

// Outline and Function Summary:
// This smart contract, "SymbioticAI_Ecosystem," implements a decentralized, evolving digital organism ecosystem.
// It features Dynamic NFTs (DNFTs) representing "Symbiotes" that possess mutable attributes and "DNA."
// Symbiotes consume an ERC20 "EnergyToken" to survive, evolve, and reproduce.
// A unique "Discovery & Research" mechanism allows the community to propose and validate new "genetic traits"
// or "evolutionary pathways" observed within the ecosystem, fostering decentralized scientific inquiry.
// The ecosystem is influenced by adjustable "environmental factors" and governed by the contract owner,
// with potential for DAO integration for future parameter adjustments.

// Key Concepts:
// - Dynamic NFTs (DNFTs): Symbiotes' attributes change based on interactions and time.
// - On-chain Simulation: Simple rules govern evolution, reproduction, and metabolism.
// - Resource Management: Symbiotes require a dedicated EnergyToken to thrive.
// - Decentralized Discovery: Users can propose new "scientific observations" about Symbiote behaviors.
// - Environmental Factors: Adjustable global parameters influencing the ecosystem.

// Core Components:
// 1. Symbiote NFT (ERC721): Represents individual digital organisms.
// 2. Symbiote Attributes: Mutable properties like energy, health, species, age, and a mutable "phenotype" string.
// 3. Immutable DNA: A fixed genetic string for each Symbiote, influencing potential evolutions.
// 4. EnergyToken (ERC20): The resource consumed by Symbiotes.
// 5. Discovery Mechanism: System for proposing, voting on, and validating ecosystem insights.

// --- Function Summary (Total: 32 Functions) ---

// I. Core NFT & Ownership (ERC721-like base & Admin):
// 1.  constructor(address _energyTokenAddress): Initializes contract with EnergyToken address, sets initial params.
// 2.  mintGenesisSymbiote(address to, string memory initialDNA): Mints a foundational Symbiote, typically by owner.
// 3.  transferFrom(address from, address to, uint256 tokenId): Standard ERC721 transfer.
// 4.  approve(address to, uint256 tokenId): Standard ERC721 approval.
// 5.  setApprovalForAll(address operator, bool approved): Standard ERC721 approval for all.
// 6.  ownerOf(uint256 tokenId): Standard ERC721 owner query.
// 7.  balanceOf(address owner): Standard ERC721 balance query.
// 8.  pause(): Pauses contract interactions (owner-only).
// 9.  unpause(): Unpauses contract interactions (owner-only).

// II. Symbiote Attributes & State Queries:
// 10. getSymbioteAttributes(uint256 tokenId): Returns current mutable attributes of a Symbiote.
// 11. getSymbioteDNA(uint256 tokenId): Returns the immutable DNA string of a Symbiote.
// 12. getSymbiotePhenotype(uint256 tokenId): Returns the current mutable phenotype (physical manifestation) of a Symbiote.
// 13. getSymbioteMetabolicRate(uint256 tokenId): Calculates the current metabolic rate of a Symbiote based on its attributes and environment.
// 14. getSymbioteAge(uint256 tokenId): Calculates the age of a Symbiote in blocks since creation/birth.

// III. Energy & Metabolism:
// 15. feedSymbiote(uint256 tokenId, uint256 amount): Allows Symbiote owner to feed EnergyToken, boosting energy and health.
// 16. getEnergyTokenAddress(): Returns the address of the ERC20 EnergyToken.
// 17. _processMetabolism(uint256 tokenId): Internal helper to simulate energy decay and potential health impact over time. (Called by other interactions)

// IV. Evolution & Reproduction:
// 18. evolveSymbiote(uint256 tokenId): Attempts to evolve a Symbiote if conditions (energy, age, environment) are met.
// 19. reproduceSymbiote(uint256 parent1Id, uint256 parent2Id): Allows two Symbiotes (owned by same address) to reproduce, minting an offspring.
// 20. _generateOffspringDNA(uint256 parent1Id, uint256 parent2Id): Internal helper to combine and mutate DNA for a new Symbiote.
// 21. _applyMutation(string memory originalDNA): Internal helper to apply a slight mutation to DNA.

// V. Discovery & Research (DeSci Aspect):
// 22. proposeDiscovery(string memory description, string memory associatedDNA, uint256 stakeAmount): User proposes a new insight with stake.
// 23. voteOnDiscovery(uint256 proposalId, bool voteChoice): Allows pre-defined validators/DAO members to vote on proposals.
// 24. finalizeDiscovery(uint256 proposalId): Owner/DAO finalizes a discovery if it passes vote threshold, adding it to knowledge base and rewarding proposer.
// 25. getDiscoveryDetails(uint256 proposalId): Returns details of a specific discovery proposal.
// 26. getValidatedDiscoveries(): Returns a list of all accepted discoveries.
// 27. withdrawStakedFunds(uint256 proposalId): Allows proposer to withdraw stake if proposal failed validation.

// VI. Environmental Factors & System Parameters:
// 28. setGlobalEnvironmentalFactor(string memory factorName, uint256 value): Owner/DAO adjusts an environmental factor.
// 29. getGlobalEnvironmentalFactors(): Returns all current global environmental factors.
// 30. setEvolutionDifficulty(uint256 newDifficulty): Owner/DAO adjusts the difficulty for Symbiote evolution.
// 31. setReproductionCooldown(uint256 newCooldown): Owner/DAO adjusts the cooldown period for reproduction.

// VII. System Utilities:
// 32. tokenURI(uint256 tokenId): Returns the URI for Symbiote metadata.

contract SymbioticAI_Ecosystem is ERC721, Ownable, Pausable {
    using Strings for uint256;
    using Base64 for bytes;

    // --- State Variables ---

    IERC20 public immutable energyToken;
    uint256 private _nextTokenId;

    // Symbiote Attributes Structure
    struct SymbioteAttributes {
        uint256 birthBlock;
        uint256 lastFedBlock;
        uint256 lastReproducedBlock;
        uint256 energy; // Current energy level (0 to MAX_ENERGY)
        uint256 health; // Current health (0 to MAX_HEALTH)
        uint256 speciesId; // A simple identifier for species/type
        string dna; // Immutable genetic code, acts as the blueprint
        string phenotype; // Mutable physical manifestation string (e.g., "Red_Furred_Fast")
    }

    mapping(uint256 => SymbioteAttributes) public symbiotes;

    // Discovery Mechanism Structures
    struct DiscoveryProposal {
        address proposer;
        string description;
        string associatedDNA; // The DNA sequence this discovery pertains to (optional)
        uint256 stakeAmount;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256 yesVotes;
        uint256 noVotes;
        uint256 submissionBlock;
        bool finalized;
        bool approved;
        bool stakeWithdrawn; // Flag to check if stake has been withdrawn
    }

    uint256 public nextDiscoveryId;
    mapping(uint256 => DiscoveryProposal) public discoveryProposals;
    uint256 public discoveryVoteThreshold; // Percentage (e.g., 5100 for 51%)
    uint256 public discoveryVotingPeriodBlocks; // How many blocks for voting

    // For simplicity, `owner()` is the only validator by default.
    // For a real DAO, this would be integrated with a governance module or a list of trusted validators.
    mapping(address => bool) public isDiscoveryValidator;

    string[] public validatedDiscoveries; // A list of approved discovery descriptions

    // Environmental Factors
    mapping(string => uint256) public globalEnvironmentalFactors;
    uint256 public constant MAX_HEALTH = 100;
    uint256 public constant MAX_ENERGY = 1000;
    uint256 public constant BASE_METABOLIC_RATE = 1; // Energy consumed per block
    uint256 public evolutionDifficulty; // Higher value means harder to evolve (e.g., 1-99)
    uint256 public reproductionCooldownBlocks; // Cooldown between reproductions for a symbiote

    // --- Events ---
    event SymbioteMinted(uint256 tokenId, address indexed owner, string dna, uint256 birthBlock);
    event SymbioteFed(uint256 indexed tokenId, uint256 amount, uint256 newEnergy, uint256 newHealth);
    event SymbioteEvolved(uint256 indexed tokenId, string oldPhenotype, string newPhenotype, string newDNA);
    event SymbioteReproduced(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 offspringId, string offspringDNA);
    event DiscoveryProposed(uint256 indexed proposalId, address indexed proposer, string description, uint256 stakeAmount);
    event DiscoveryVoted(uint256 indexed proposalId, address indexed voter, bool voteChoice);
    event DiscoveryFinalized(uint256 indexed proposalId, bool approved, string description);
    event EnvironmentalFactorUpdated(string indexed factorName, uint256 value);
    event EvolutionDifficultyUpdated(uint256 newDifficulty);
    event ReproductionCooldownUpdated(uint256 newCooldown);

    // --- Constructor ---
    constructor(address _energyTokenAddress) ERC721("SymbioteAI", "SYM_AI") Ownable(msg.sender) {
        energyToken = IERC20(_energyTokenAddress);
        _nextTokenId = 1; // Start token IDs from 1

        // Initialize default environmental factors
        globalEnvironmentalFactors["pollutionLevel"] = 10; // Affects health/metabolism
        globalEnvironmentalFactors["resourceScarcity"] = 5; // Affects energy gain
        evolutionDifficulty = 50; // Base difficulty (higher is harder, 1-99)
        reproductionCooldownBlocks = 100; // 100 blocks cooldown (approx 25 mins on Ethereum)

        // Discovery system defaults
        nextDiscoveryId = 1;
        discoveryVoteThreshold = 5100; // 51% (51.00)
        discoveryVotingPeriodBlocks = 200; // Approx 50 minutes for voting
        isDiscoveryValidator[msg.sender] = true; // Owner is a validator by default
    }

    // --- I. Core NFT & Ownership ---

    /**
     * @notice Mints a genesis Symbiote. Only callable by the contract owner.
     * @dev Initial Symbiotes created to seed the ecosystem. Max 99 genesis Symbiotes.
     * @param to The address to mint the Symbiote to.
     * @param initialDNA The immutable DNA string for the genesis Symbiote.
     */
    function mintGenesisSymbiote(address to, string memory initialDNA) public onlyOwner whenNotPaused {
        require(_nextTokenId < 100, "Max genesis symbiotes reached (limited to 99)");
        _safeMint(to, _nextTokenId);
        symbiotes[_nextTokenId] = SymbioteAttributes({
            birthBlock: block.number,
            lastFedBlock: block.number,
            lastReproducedBlock: 0, // No prior reproduction
            energy: MAX_ENERGY,
            health: MAX_HEALTH,
            speciesId: 1, // Default species for genesis Symbiotes
            dna: initialDNA,
            phenotype: "Genesis" // Initial phenotype
        });
        emit SymbioteMinted(_nextTokenId, to, initialDNA, block.number);
        _nextTokenId++;
    }

    // Standard ERC721 functions (transferFrom, approve, setApprovalForAll, ownerOf, balanceOf) are inherited.

    /**
     * @notice Pauses contract functionality, preventing most interactions.
     * @dev Only callable by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract functionality, allowing interactions to resume.
     * @dev Only callable by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- II. Symbiote Attributes & State Queries ---

    /**
     * @notice Returns the mutable attributes of a specific Symbiote.
     * @param tokenId The ID of the Symbiote.
     * @return A tuple containing the Symbiote's attributes.
     */
    function getSymbioteAttributes(uint256 tokenId) public view returns (
        uint256 birthBlock,
        uint256 lastFedBlock,
        uint256 lastReproducedBlock,
        uint256 energy,
        uint256 health,
        uint256 speciesId,
        string memory dna,
        string memory phenotype
    ) {
        SymbioteAttributes storage s = symbiotes[tokenId];
        return (
            s.birthBlock,
            s.lastFedBlock,
            s.lastReproducedBlock,
            s.energy,
            s.health,
            s.speciesId,
            s.dna,
            s.phenotype
        );
    }

    /**
     * @notice Returns the immutable DNA string of a Symbiote.
     * @param tokenId The ID of the Symbiote.
     * @return The DNA string.
     */
    function getSymbioteDNA(uint256 tokenId) public view returns (string memory) {
        return symbiotes[tokenId].dna;
    }

    /**
     * @notice Returns the current mutable phenotype (physical manifestation) of a Symbiote.
     * @param tokenId The ID of the Symbiote.
     * @return The phenotype string.
     */
    function getSymbiotePhenotype(uint256 tokenId) public view returns (string memory) {
        return symbiotes[tokenId].phenotype;
    }

    /**
     * @notice Calculates the current metabolic rate of a Symbiote, adjusted by environmental factors.
     * @param tokenId The ID of the Symbiote.
     * @return The metabolic rate (energy consumed per block).
     */
    function getSymbioteMetabolicRate(uint256 tokenId) public view returns (uint256) {
        SymbioteAttributes storage s = symbiotes[tokenId];
        uint256 rate = BASE_METABOLIC_RATE;
        // Example: pollution increases metabolic rate
        rate += globalEnvironmentalFactors["pollutionLevel"] / 10;
        // Example: specific species might have different base rates (simplified logic)
        if (s.speciesId == 2) rate += 1;
        return rate;
    }

    /**
     * @notice Calculates the age of a Symbiote in blocks since its birth.
     * @param tokenId The ID of the Symbiote.
     * @return The age in blocks.
     */
    function getSymbioteAge(uint256 tokenId) public view returns (uint256) {
        return block.number - symbiotes[tokenId].birthBlock;
    }

    // --- III. Energy & Metabolism ---

    /**
     * @notice Allows the Symbiote owner to feed EnergyToken, boosting energy and health.
     * @dev Calls _processMetabolism before and after feeding to account for time elapsed.
     * @param tokenId The ID of the Symbiote to feed.
     * @param amount The amount of EnergyToken to feed.
     */
    function feedSymbiote(uint256 tokenId, uint256 amount) public whenNotPaused {
        require(_exists(tokenId), "Symbiote does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not Symbiote owner or approved");
        require(amount > 0, "Feed amount must be positive");

        _processMetabolism(tokenId); // Process metabolism before feeding

        SymbioteAttributes storage s = symbiotes[tokenId];
        require(energyToken.transferFrom(msg.sender, address(this), amount), "EnergyToken transfer failed");

        // Energy gain calculation: inversely proportional to resource scarcity
        uint256 energyGain = amount / (globalEnvironmentalFactors["resourceScarcity"] > 0 ? globalEnvironmentalFactors["resourceScarcity"] : 1);
        s.energy = (s.energy + energyGain) > MAX_ENERGY ? MAX_ENERGY : (s.energy + energyGain);

        // Health gain: feeding also boosts health, but less directly than energy
        s.health = (s.health + (amount / 10)) > MAX_HEALTH ? MAX_HEALTH : (s.health + (amount / 10));

        s.lastFedBlock = block.number;
        emit SymbioteFed(tokenId, amount, s.energy, s.health);
    }

    /**
     * @notice Returns the address of the ERC20 EnergyToken used in the ecosystem.
     */
    function getEnergyTokenAddress() public view returns (address) {
        return address(energyToken);
    }

    /**
     * @dev Internal function to simulate energy decay and potential health impact over time.
     * Called by any function that interacts with a Symbiote's state (e.g., feed, evolve, reproduce).
     * @param tokenId The ID of the Symbiote.
     */
    function _processMetabolism(uint256 tokenId) internal view {
        SymbioteAttributes storage s = symbiotes[tokenId];
        uint256 blocksSinceLastUpdate = block.number - s.lastFedBlock;
        if (blocksSinceLastUpdate == 0) return; // No time has passed

        uint256 metabolicRate = getSymbioteMetabolicRate(tokenId);
        uint256 energyLoss = blocksSinceLastUpdate * metabolicRate;

        if (s.energy > energyLoss) {
            s.energy -= energyLoss;
        } else {
            // If energy drops below 0, health starts to deplete
            uint256 deficit = energyLoss - s.energy;
            s.energy = 0;
            s.health = s.health > deficit / 10 ? s.health - (deficit / 10) : 0; // Health depletes slower than energy
        }
        // Note: `s.lastFedBlock = block.number;` must be done in the calling function,
        // as this is a `view` function for calculation. Or, make this a non-view function.
        // For efficiency, it's a `view` for calculation, the caller updates `lastFedBlock`.
        // This is a common pattern to avoid storage writes in helper functions if not strictly necessary.
    }

    // --- IV. Evolution & Reproduction ---

    /**
     * @notice Attempts to evolve a Symbiote if conditions (energy, health, age, environment) are met.
     * @dev Evolution can change the Symbiote's phenotype and potentially DNA/speciesId based on internal rules.
     * @param tokenId The ID of the Symbiote to evolve.
     */
    function evolveSymbiote(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Symbiote does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not Symbiote owner or approved");
        
        // Update Symbiote's state based on metabolism before checking conditions
        SymbioteAttributes memory currentAttributes = symbiotes[tokenId];
        _processMetabolism(tokenId); // Perform calculation
        symbiotes[tokenId].lastFedBlock = block.number; // Update storage after calculation

        SymbioteAttributes storage s = symbiotes[tokenId]; // Re-fetch storage reference after update

        // Check evolution conditions
        require(s.energy >= MAX_ENERGY / 2, "Symbiote needs more energy to evolve");
        require(s.health >= MAX_HEALTH / 2, "Symbiote needs better health to evolve");
        require(getSymbioteAge(tokenId) >= 50, "Symbiote is too young to evolve (min 50 blocks)");

        // Simple on-chain pseudo-randomness for evolution chance
        uint256 roll = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, evolutionDifficulty, s.energy, s.health)));
        require(roll % 100 < (100 - evolutionDifficulty), "Evolution failed (too difficult or unlucky)"); // e.g., if difficulty is 50, 50% chance

        // Apply evolution changes
        string memory oldPhenotype = s.phenotype;
        string memory oldDNA = s.dna;

        // Simplified evolution logic:
        s.phenotype = string(abi.encodePacked("Evolved_", s.phenotype, "_", (block.timestamp % 10).toString()));
        s.energy /= 2; // Evolution consumes energy

        // Apply a mutation to DNA, then potentially change speciesId based on simple DNA property
        s.dna = _applyMutation(s.dna);
        if (bytes(s.dna).length % 2 == 0) { // Example rule: even length DNA might lead to species 2
            s.speciesId = 2;
        } else {
            s.speciesId = 1; // Revert to species 1 or other default
        }

        emit SymbioteEvolved(tokenId, oldPhenotype, s.phenotype, s.dna);
    }

    /**
     * @notice Allows two Symbiotes (owned by the same address) to reproduce, minting an offspring.
     * @dev Reproduction consumes energy from parents and has a cooldown.
     * @param parent1Id The ID of the first parent Symbiote.
     * @param parent2Id The ID of the second parent Symbiote.
     */
    function reproduceSymbiote(uint256 parent1Id, uint256 parent2Id) public whenNotPaused {
        require(_exists(parent1Id), "Parent1 does not exist");
        require(_exists(parent2Id), "Parent2 does not exist");
        require(_isApprovedOrOwner(msg.sender, parent1Id), "Not owner of parent1");
        require(_isApprovedOrOwner(msg.sender, parent2Id), "Not owner of parent2");
        require(parent1Id != parent2Id, "Cannot reproduce with self");

        // Process metabolism for both parents
        _processMetabolism(parent1Id);
        _processMetabolism(parent2Id);
        symbiotes[parent1Id].lastFedBlock = block.number;
        symbiotes[parent2Id].lastFedBlock = block.number;

        SymbioteAttributes storage p1 = symbiotes[parent1Id];
        SymbioteAttributes storage p2 = symbiotes[parent2Id];

        // Check reproduction conditions
        require(p1.energy >= MAX_ENERGY / 4 && p2.energy >= MAX_ENERGY / 4, "Parents need more energy to reproduce");
        require(p1.health >= MAX_HEALTH / 2 && p2.health >= MAX_HEALTH / 2, "Parents need better health to reproduce");
        require(getSymbioteAge(parent1Id) >= 100 && getSymbioteAge(parent2Id) >= 100, "Parents are too young (min 100 blocks)");
        require(block.number - p1.lastReproducedBlock >= reproductionCooldownBlocks, "Parent1 on reproduction cooldown");
        require(block.number - p2.lastReproducedBlock >= reproductionCooldownBlocks, "Parent2 on reproduction cooldown");

        // Simulate reproduction cost and update cooldown
        p1.energy /= 2;
        p2.energy /= 2;
        p1.lastReproducedBlock = block.number;
        p2.lastReproducedBlock = block.number;

        // Generate offspring DNA and mint new Symbiote
        string memory offspringDNA = _generateOffspringDNA(parent1Id, parent2Id);
        
        uint256 newOffspringId = _nextTokenId++;
        _safeMint(msg.sender, newOffspringId);
        symbiotes[newOffspringId] = SymbioteAttributes({
            birthBlock: block.number,
            lastFedBlock: block.number,
            lastReproducedBlock: 0,
            energy: MAX_ENERGY / 4, // Offspring starts with some energy
            health: MAX_HEALTH,
            speciesId: p1.speciesId == p2.speciesId ? p1.speciesId : 3, // New species if parents differ (simplified)
            dna: offspringDNA,
            phenotype: "Offspring" // Initial phenotype for offspring
        });

        emit SymbioteReproduced(parent1Id, parent2Id, newOffspringId, offspringDNA);
    }

    /**
     * @dev Internal helper to combine and mutate DNA for a new Symbiote offspring.
     * A very simplified genetic algorithm, concatenating and potentially altering parts.
     * @param parent1Id The ID of the first parent.
     * @param parent2Id The ID of the second parent.
     * @return The DNA string for the offspring.
     */
    function _generateOffspringDNA(uint256 parent1Id, uint256 parent2Id) internal view returns (string memory) {
        string memory dna1 = symbiotes[parent1Id].dna;
        string memory dna2 = symbiotes[parent2Id].dna;

        // Simple crossover: take first half of dna1, second half of dna2
        bytes memory b1 = bytes(dna1);
        bytes memory b2 = bytes(dna2);

        uint256 crossoverPoint = b1.length / 2;
        if (crossoverPoint == 0) crossoverPoint = 1; // Ensure it's not zero for short DNA

        bytes memory newDNABytes = new bytes(b1.length > b2.length ? b1.length : b2.length); // Offspring DNA length depends on longer parent

        for (uint256 i = 0; i < crossoverPoint; i++) {
            if (i < b1.length) {
                newDNABytes[i] = b1[i];
            }
        }
        for (uint256 i = crossoverPoint; i < newDNABytes.length; i++) {
            if (i < b2.length) { // Ensure b2 has enough length
                newDNABytes[i] = b2[i];
            } else if (i < b1.length) { // If b2 is shorter, use b1's remainder
                newDNABytes[i] = b1[i];
            }
        }

        string memory offspringDNA = string(newDNABytes);
        return _applyMutation(offspringDNA); // Apply a final mutation
    }

    /**
     * @dev Internal helper to apply a slight mutation to a DNA string.
     * Very basic: changes a single character randomly within a set of allowed characters.
     * @param originalDNA The DNA string to mutate.
     * @return The mutated DNA string.
     */
    function _applyMutation(string memory originalDNA) internal view returns (string memory) {
        bytes memory dnaBytes = bytes(originalDNA);
        if (dnaBytes.length == 0) return originalDNA;

        // Simple pseudo-randomness for mutation chance and position
        uint256 mutationRoll = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, dnaBytes, "mutationRoll"))) % 100;
        if (mutationRoll < 15) { // 15% chance of mutation
            uint256 index = (uint256(keccak256(abi.encodePacked(block.timestamp, block.number, dnaBytes, "mutationIndex")))) % dnaBytes.length;
            bytes memory possibleChars = "ACGT"; // Example DNA bases (can be extended)
            uint224 charIndex = uint224(uint256(keccak256(abi.encodePacked(block.timestamp, block.number, dnaBytes, "charIndex")))) % possibleChars.length;
            dnaBytes[index] = possibleChars[charIndex];
        }
        return string(dnaBytes);
    }

    // --- V. Discovery & Research (DeSci Aspect) ---

    /**
     * @notice Allows a user to propose a new "discovery" about Symbiote behavior, requiring a stake.
     * @dev This simulates decentralized scientific observation and hypothesis.
     * @param description A text description of the discovery (e.g., "DNA pattern 'AGTC' results in higher energy retention").
     * @param associatedDNA A specific DNA sequence associated with the discovery (can be empty string if general).
     * @param stakeAmount The amount of EnergyToken to stake for the proposal.
     * @return The ID of the newly created discovery proposal.
     */
    function proposeDiscovery(
        string memory description,
        string memory associatedDNA,
        uint256 stakeAmount
    ) public whenNotPaused returns (uint256 proposalId) {
        require(stakeAmount > 0, "Stake amount must be positive");
        require(energyToken.transferFrom(msg.sender, address(this), stakeAmount), "EnergyToken transfer failed for stake");

        proposalId = nextDiscoveryId++;
        DiscoveryProposal storage proposal = discoveryProposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.associatedDNA = associatedDNA;
        proposal.stakeAmount = stakeAmount;
        proposal.submissionBlock = block.number;
        proposal.finalized = false;
        proposal.approved = false;
        proposal.stakeWithdrawn = false;

        emit DiscoveryProposed(proposalId, msg.sender, description, stakeAmount);
        return proposalId;
    }

    /**
     * @notice Allows designated validators (or DAO members) to vote on a discovery proposal.
     * @dev For a real DAO, this would be integrated with a more robust voting system.
     * @param proposalId The ID of the discovery proposal.
     * @param voteChoice True for 'yes', False for 'no'.
     */
    function voteOnDiscovery(uint256 proposalId, bool voteChoice) public whenNotPaused {
        require(isDiscoveryValidator[msg.sender], "Caller is not a discovery validator");
        DiscoveryProposal storage proposal = discoveryProposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist"); // Check if proposal exists
        require(!proposal.finalized, "Proposal already finalized");
        require(block.number <= proposal.submissionBlock + discoveryVotingPeriodBlocks, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true; // Mark voter to prevent double voting
        if (voteChoice) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit DiscoveryVoted(proposalId, msg.sender, voteChoice);
    }

    /**
     * @notice Finalizes a discovery proposal. If approved, adds it to the validated knowledge base and rewards proposer.
     * @dev Only callable by the contract owner (or DAO). Checks vote threshold.
     * @param proposalId The ID of the discovery proposal to finalize.
     */
    function finalizeDiscovery(uint256 proposalId) public onlyOwner whenNotPaused {
        DiscoveryProposal storage proposal = discoveryProposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.finalized, "Proposal already finalized");
        require(block.number > proposal.submissionBlock + discoveryVotingPeriodBlocks, "Voting period not yet ended");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        if (totalVotes == 0) { // No votes, automatically reject if no one bothered to vote
            proposal.finalized = true;
            proposal.approved = false;
            emit DiscoveryFinalized(proposalId, false, proposal.description);
            return;
        }

        uint256 yesVotePercentage = (proposal.yesVotes * 10000) / totalVotes; // Multiply by 10000 for percentage with 2 decimal places

        if (yesVotePercentage >= discoveryVoteThreshold) {
            proposal.approved = true;
            validatedDiscoveries.push(proposal.description); // Add to validated knowledge
            // Reward proposer: return stake + a small bonus (e.g., 10% of stake)
            uint256 rewardAmount = proposal.stakeAmount + (proposal.stakeAmount / 10);
            require(energyToken.transfer(proposal.proposer, rewardAmount), "Failed to return stake and bonus to proposer");
            proposal.stakeWithdrawn = true;
        } else {
            proposal.approved = false;
        }
        proposal.finalized = true;
        emit DiscoveryFinalized(proposalId, proposal.approved, proposal.description);
    }

    /**
     * @notice Returns the details of a specific discovery proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getDiscoveryDetails(uint256 proposalId) public view returns (
        address proposer,
        string memory description,
        string memory associatedDNA,
        uint256 stakeAmount,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 submissionBlock,
        bool finalized,
        bool approved,
        bool stakeWithdrawn
    ) {
        DiscoveryProposal storage proposal = discoveryProposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (
            proposal.proposer,
            proposal.description,
            proposal.associatedDNA,
            proposal.stakeAmount,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.submissionBlock,
            proposal.finalized,
            proposal.approved,
            proposal.stakeWithdrawn
        );
    }

    /**
     * @notice Returns the list of all descriptions for accepted (validated) discoveries.
     * @return An array of strings, each being a description of a validated discovery.
     */
    function getValidatedDiscoveries() public view returns (string[] memory) {
        return validatedDiscoveries;
    }

    /**
     * @notice Allows a proposer to withdraw their staked funds if their discovery proposal was rejected.
     * @param proposalId The ID of the proposal.
     */
    function withdrawStakedFunds(uint256 proposalId) public whenNotPaused {
        DiscoveryProposal storage proposal = discoveryProposals[proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(msg.sender == proposal.proposer, "Only the proposer can withdraw");
        require(proposal.finalized, "Proposal not yet finalized");
        require(!proposal.approved, "Cannot withdraw stake from an approved proposal");
        require(!proposal.stakeWithdrawn, "Funds already withdrawn");

        require(energyToken.transfer(proposal.proposer, proposal.stakeAmount), "Failed to transfer staked funds back");
        proposal.stakeWithdrawn = true;
    }

    // --- VI. Environmental Factors & System Parameters ---

    /**
     * @notice Sets a global environmental factor, influencing Symbiote behavior.
     * @dev Only callable by the contract owner. Can be used to introduce "events" in the ecosystem.
     * @param factorName The name of the environmental factor (e.g., "pollutionLevel", "resourceScarcity").
     * @param value The new value for the factor.
     */
    function setGlobalEnvironmentalFactor(string memory factorName, uint256 value) public onlyOwner {
        globalEnvironmentalFactors[factorName] = value;
        emit EnvironmentalFactorUpdated(factorName, value);
    }

    /**
     * @notice Returns all current global environmental factors.
     * @dev This returns hardcoded factors for demonstration. A more dynamic system would manage factor names in an array.
     * @return An array of environmental factor names and their corresponding values.
     */
    function getGlobalEnvironmentalFactors() public view returns (string[] memory names, uint256[] memory values) {
        // As retrieving all keys from a mapping is not directly possible,
        // we return values for the known factors initialized in the constructor.
        names = new string[](2);
        values = new uint256[](2);

        names[0] = "pollutionLevel";
        values[0] = globalEnvironmentalFactors["pollutionLevel"];

        names[1] = "resourceScarcity";
        values[1] = globalEnvironmentalFactors["resourceScarcity"];

        return (names, values);
    }

    /**
     * @notice Adjusts the difficulty level for Symbiote evolution.
     * @dev Higher values make evolution less likely to succeed.
     * @param newDifficulty A value (e.g., 1-99) representing the difficulty.
     */
    function setEvolutionDifficulty(uint256 newDifficulty) public onlyOwner {
        require(newDifficulty > 0 && newDifficulty < 100, "Difficulty must be between 1 and 99");
        evolutionDifficulty = newDifficulty;
        emit EvolutionDifficultyUpdated(newDifficulty);
    }

    /**
     * @notice Adjusts the cooldown period (in blocks) before a Symbiote can reproduce again.
     * @dev Prevents spamming reproduction and balances ecosystem growth.
     * @param newCooldown The new cooldown period in blocks.
     */
    function setReproductionCooldown(uint256 newCooldown) public onlyOwner {
        reproductionCooldownBlocks = newCooldown;
        emit ReproductionCooldownUpdated(newCooldown);
    }

    // --- VII. System Utilities ---

    /**
     * @notice Standard ERC721 tokenURI function. Generates metadata URI for a Symbiote.
     * @dev Dynamically generates Base64-encoded JSON metadata based on the Symbiote's current state.
     * @param tokenId The ID of the Symbiote.
     * @return The data URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        // Temporarily process metabolism to get updated values for metadata, without writing to storage
        SymbioteAttributes memory s = symbiotes[tokenId];
        uint256 blocksSinceLastUpdate = block.number - s.lastFedBlock;
        if (blocksSinceLastUpdate > 0) {
            uint256 metabolicRate = getSymbioteMetabolicRate(tokenId);
            uint256 energyLoss = blocksSinceLastUpdate * metabolicRate;

            if (s.energy > energyLoss) {
                s.energy -= energyLoss;
            } else {
                uint256 deficit = energyLoss - s.energy;
                s.energy = 0;
                s.health = s.health > deficit / 10 ? s.health - (deficit / 10) : 0;
            }
        }
        
        string memory name = string(abi.encodePacked("Symbiote #", tokenId.toString(), " (", s.phenotype, ")"));
        string memory description = "An evolving digital organism living on the blockchain.";
        // The image could also be dynamically generated SVG based on DNA/Phenotype
        string memory image = "https://ipfs.io/ipfs/QmT78zH7K..."; // Placeholder IPFS image for example

        // Construct attributes array in JSON format
        string memory attributes = string(abi.encodePacked(
            '[{"trait_type": "Phenotype", "value": "', s.phenotype, '"},',
            '{"trait_type": "Species ID", "value": "', s.speciesId.toString(), '"},',
            '{"trait_type": "Energy", "value": "', s.energy.toString(), '"},',
            '{"trait_type": "Health", "value": "', s.health.toString(), '"},',
            '{"trait_type": "Age (Blocks)", "value": "', getSymbioteAge(tokenId).toString(), '"},',
            '{"trait_type": "DNA Hash", "value": "', Strings.toHexString(uint256(keccak256(abi.encodePacked(s.dna))), 32), '"}' // Hash of DNA for privacy/shortness
            ']'
        ));

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', image, '",',
            '"attributes": ', attributes, '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", bytes(json).encode()));
    }
}

// Minimal ERC20 interface for the EnergyToken
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint255);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint252 value);
}

// Note: For testing or deployment, you would need to deploy a simple ERC20 token
// (e.g., from OpenZeppelin's ERC20 contract) and pass its address to the SymbioticAI_Ecosystem constructor.
// Example Dummy Energy Token for local testing:
/*
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract DummyEnergyToken is ERC20 {
    constructor() ERC20("Energy Token", "NRG") {
        _mint(msg.sender, 1_000_000 * 10**18); // Mint initial supply to deployer
    }
}
*/
```