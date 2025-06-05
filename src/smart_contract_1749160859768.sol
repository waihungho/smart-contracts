Okay, here is a Solidity smart contract concept called `DecentralizedArtEvolution`. This contract aims to create NFTs that have an evolving state on-chain, influenced by time, user interaction (nurturing), and simulated random mutation. The state (genome) of the art changes, which would then be interpreted off-chain to generate changing visual metadata.

It uses concepts like:
*   **Dynamic NFTs:** The core state of the NFT changes on-chain.
*   **On-chain Simulation:** Basic evolution rules and energy mechanics are enforced by the contract.
*   **Time-Based Triggers:** Evolution can occur automatically after a certain period (checked upon interaction).
*   **User-Triggered Evolution/Influence:** Owners can spend resources (Ether in this case, simulating nutrients/care) to trigger evolution or influence specific traits.
*   **Pseudo-Random Mutation:** Uses block data for simple on-chain randomness to simulate mutations.
*   **Resource Management:** Art pieces have an energy level required for evolution.

---

**Outline**

1.  **SPDX License and Pragma**
2.  **Imports:** OpenZeppelin Contracts (ERC721Enumerable, Ownable, Pausable)
3.  **Error Definitions**
4.  **Enums:** `GrowthStage`
5.  **Structs:** `ArtGenome`
6.  **State Variables:**
    *   Mapping from `tokenId` to `ArtGenome`
    *   Evolution parameters (`evolutionCooldownBlocks`, `requiredEnergyPerEvolution`, `energyRegenPerBlock`, `maxEnergy`)
    *   Admin addresses (Owner)
    *   Pausable state
    *   Base URI for metadata
    *   Trait Mapping URI (explaining how genes map to visuals)
    *   Next token ID
7.  **Events:** Mint, EvolutionTriggered, Nurtured, EnergyHarvested, Decay, ParamsUpdated, Paused/Unpaused
8.  **Constructor**
9.  **Modifiers:** `whenNotPaused`, `whenPaused`
10. **Core Logic Functions (Internal):**
    *   `_evolve`: Applies evolution rules to an `ArtGenome`.
    *   `_calculateEnergyRegen`: Calculates energy regenerated since last harvest.
    *   `_attemptEvolution`: Checks conditions and calls `_evolve`.
11. **Public/External Functions (>= 20 in total, including inherited):**
    *   **Inherited (ERC721Enumerable, Ownable, Pausable):**
        *   `balanceOf`
        *   `ownerOf`
        *   `approve`
        *   `getApproved`
        *   `setApprovalForAll`
        *   `isApprovedForAll`
        *   `transferFrom`
        *   `safeTransferFrom` (x2)
        *   `totalSupply`
        *   `tokenByIndex`
        *   `tokenOfOwnerByIndex`
        *   `owner`
        *   `renounceOwnership`
        *   `transferOwnership`
        *   `paused`
        *   `pause`
        *   `unpause`
    *   **Custom:**
        1.  `mintInitialSeed`
        2.  `getArtGenome`
        3.  `tokenURI` (Overrides ERC721 standard to point to a dynamic renderer)
        4.  `triggerEvolutionByTime`
        5.  `triggerEvolutionByNurturing` (payable)
        6.  `influenceColor` (payable)
        7.  `influenceShape` (payable)
        8.  `applyMutationBoost` (payable)
        9.  `harvestEnergy`
        10. `getEnergyLevel`
        11. `getGrowthStage`
        12. `getRequiredEnergyForEvolution`
        13. `getEvolutionCooldown`
        14. `isEvolutionReady`
        15. `forceDecay` (owner only, or maybe conditional?) - let's make it owner only for safety.
        16. `setEvolutionParams` (owner only)
        17. `withdrawFunds` (owner only)
        18. `getBaseURI`
        19. `setBaseURI` (owner only)
        20. `getTraitMappingURI`
        21. `setTraitMappingURI` (owner only)
        22. `getMutationChance`
        23. `getLastEvolvedBlock`

12. **Helper Functions (Internal/Private):** Pseudorandomness helper.

---

**Function Summary**

*   **`balanceOf(address owner)`:** Returns the number of tokens owned by an address. (Inherited)
*   **`ownerOf(uint256 tokenId)`:** Returns the owner of a specific token. (Inherited)
*   **`approve(address to, uint256 tokenId)`:** Approves an address to spend a specific token. (Inherited)
*   **`getApproved(uint256 tokenId)`:** Gets the approved address for a specific token. (Inherited)
*   **`setApprovalForAll(address operator, bool approved)`:** Approves or revokes approval for an operator for all tokens of the caller. (Inherited)
*   **`isApprovedForAll(address owner, address operator)`:** Checks if an address is an approved operator for another address. (Inherited)
*   **`transferFrom(address from, address to, uint256 tokenId)`:** Transfers a token (standard, less safe). (Inherited)
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`:** Transfers a token (safe, checks receiver). (Inherited)
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`:** Transfers a token (safe, checks receiver with data). (Inherited)
*   **`totalSupply()`:** Returns the total number of tokens minted. (Inherited)
*   **`tokenByIndex(uint256 index)`:** Returns the token ID at a given index. (Inherited)
*   **`tokenOfOwnerByIndex(address owner, uint256 index)`:** Returns the token ID at a given index for a specific owner. (Inherited)
*   **`owner()`:** Returns the address of the contract owner. (Inherited)
*   **`renounceOwnership()`:** Relinquishes ownership of the contract. (Inherited)
*   **`transferOwnership(address newOwner)`:** Transfers ownership of the contract to a new address. (Inherited)
*   **`paused()`:** Returns the current pause state. (Inherited)
*   **`pause()`:** Pauses the contract (owner only). (Inherited)
*   **`unpause()`:** Unpauses the contract (owner only). (Inherited)
*   **`mintInitialSeed()`:** Mints a new NFT with an initial "seed" genome state (only owner).
*   **`getArtGenome(uint256 tokenId)`:** Returns the full on-chain ArtGenome state for a token.
*   **`tokenURI(uint256 tokenId)`:** Returns the URI for the token's metadata, incorporating the base URI and token ID. This URI is expected to point to a service that dynamically generates metadata based on the on-chain genome data.
*   **`triggerEvolutionByTime(uint256 tokenId)`:** Attempts to evolve the art piece if the required time (`evolutionCooldownBlocks`) has passed since the last evolution and the art has enough energy.
*   **`triggerEvolutionByNurturing(uint256 tokenId)`:** Allows the owner to pay Ether to trigger evolution instantly, bypassing the time cooldown but still requiring energy. Ether contributes to contract funds.
*   **`influenceColor(uint256 tokenId)`:** Allows the owner to pay Ether to slightly nudge the color genes towards a more "vibrant" state (simplified example). Requires energy.
*   **`influenceShape(uint256 tokenId)`:** Allows the owner to pay Ether to slightly nudge the shape genes towards a more "complex" state (simplified example). Requires energy.
*   **`applyMutationBoost(uint256 tokenId)`:** Allows the owner to pay Ether to temporarily increase the mutation factor for the next evolution. Requires energy.
*   **`harvestEnergy(uint256 tokenId)`:** Calculates energy regenerated since the last harvest based on blocks passed and adds it to the art's energy level. Can be called by anyone.
*   **`getEnergyLevel(uint256 tokenId)`:** Returns the current energy level of the art piece.
*   **`getGrowthStage(uint256 tokenId)`:** Returns the current growth stage (Seed, Sprout, etc.) based on its genome.
*   **`getRequiredEnergyForEvolution()`:** Returns the contract's configured required energy per evolution.
*   **`getEvolutionCooldown()`:** Returns the contract's configured evolution cooldown in blocks.
*   **`isEvolutionReady(uint256 tokenId)`:** Checks if the time-based evolution cooldown has passed and if the art has enough energy for a standard evolution.
*   **`forceDecay(uint256 tokenId)`:** (Owner only) Forces the art piece into a decay state, potentially irreversible (example function, can be complex).
*   **`setEvolutionParams(...)`:** (Owner only) Allows updating parameters like cooldown, energy requirements, and regeneration rates.
*   **`withdrawFunds()`:** (Owner only) Allows the owner to withdraw collected Ether from nurturing/influence fees.
*   **`getBaseURI()`:** Returns the base URI for token metadata.
*   **`setBaseURI(string memory newBaseURI)`:** (Owner only) Sets the base URI for token metadata.
*   **`getTraitMappingURI()`:** Returns the URI explaining how genes map to visuals.
*   **`setTraitMappingURI(string memory newTraitMappingURI)`:** (Owner only) Sets the URI explaining how genes map to visuals.
*   **`getMutationChance(uint256 tokenId)`:** Calculates and returns the current chance of a significant mutation occurring based on the genome state.
*   **`getLastEvolvedBlock(uint256 tokenId)`:** Returns the block number when the art piece last evolved.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title DecentralizedArtEvolution
/// @author YourName (or a placeholder)
/// @notice A smart contract for managing dynamic NFTs that evolve based on time, user interaction, and simulated random mutations.
/// The art's state (genome) is stored on-chain and changes over time or through nurturing actions.
/// Metadata URIs point to a service that interprets the on-chain genome to render the visual art.
contract DecentralizedArtEvolution is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Errors ---
    error NotOwnerOfToken(uint256 tokenId);
    error EvolutionOnCooldown(uint256 tokenId, uint256 blocksLeft);
    error InsufficientEnergy(uint256 tokenId, uint256 currentEnergy, uint256 requiredEnergy);
    error EvolutionNotReady(uint256 tokenId);
    error InvalidGrowthStage(uint256 tokenId, GrowthStage currentStage);
    error AlreadyInDecay(uint256 tokenId);
    error DecayNotPossible(uint256 tokenId);
    error NurtureCostTooLow(uint256 requiredCost);

    // --- Enums ---
    enum GrowthStage { Seed, Sprout, Bloom, Mature, Declining, Decay, Rebirth } // Example stages

    // --- Structs ---
    /// @dev Represents the evolving state (genome) of a piece of art.
    struct ArtGenome {
        uint256 generation;         // How many evolution cycles it has gone through
        uint256 energyLevel;        // Resource required for evolution and actions
        uint256 mutationFactor;     // Higher number means higher chance of mutation
        GrowthStage growthStage;    // Current stage of development
        uint256 colorGenes;         // Simplified example genes (e.g., packed RGB or indices)
        uint256 shapeGenes;         // Simplified example genes (e.g., indices or parameters)
        uint256 lastEvolvedBlock;   // Block number of the last evolution
        uint256 lastEnergyHarvestBlock; // Block number of the last energy harvest
        uint256 mutationBoostEndTime; // Block number until mutation boost is active
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => ArtGenome) private _artGenomes;

    // Evolution Parameters (Owner configurable)
    uint256 public evolutionCooldownBlocks = 10; // Blocks required between time-based evolutions
    uint256 public requiredEnergyPerEvolution = 100; // Energy cost for a standard evolution
    uint256 public energyRegenPerBlock = 5; // Energy points regenerated per block since last harvest
    uint256 public maxEnergy = 500; // Maximum energy an art piece can hold
    uint256 public nurturingCost = 0.01 ether; // Cost to trigger nurturing evolution/influence

    string private _baseTokenURI; // Base URI for metadata server endpoint
    string private _traitMappingURI; // URI explaining how genes map to visuals

    // --- Events ---
    event ArtMinted(uint256 indexed tokenId, address indexed owner);
    event EvolutionTriggered(uint256 indexed tokenId, uint256 generation, GrowthStage newStage);
    event Nurtured(uint256 indexed tokenId, uint256 energyUsed);
    event EnergyHarvested(uint256 indexed tokenId, uint256 energyAdded, uint256 newEnergyLevel);
    event ArtDecayed(uint256 indexed tokenId);
    event EvolutionParamsUpdated(uint256 cooldown, uint256 requiredEnergy, uint256 regenRate, uint256 maxEnergy, uint256 nurtureCost);
    // Paused/Unpaused events inherited from Pausable

    // --- Constructor ---
    /// @notice Constructs the DecentralizedArtEvolution contract.
    /// @param name_ The name of the NFT collection.
    /// @param symbol_ The symbol of the NFT collection.
    /// @param baseURI_ The base URI for the metadata service.
    /// @param traitMappingURI_ The URI explaining the gene mapping.
    constructor(string memory name_, string memory symbol_, string memory baseURI_, string memory traitMappingURI_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI_;
        _traitMappingURI = traitMappingURI_;
    }

    // --- Standard ERC721 & Enumerable Overrides ---
    // (Implicitly inherited and available: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom variants, totalSupply, tokenByIndex, tokenOfOwnerByIndex)

    /// @notice Returns the URI for the token's metadata.
    /// @dev This URI should point to a service that dynamically generates metadata based on the on-chain ArtGenome state.
    /// @param tokenId The ID of the token.
    /// @return string The metadata URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned

        // The metadata server at baseURI_ + tokenIdString should query the contract
        // for the art genome and use _traitMappingURI information
        // to generate the visual metadata JSON.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // --- Core Art Evolution & Interaction Functions ---

    /// @notice Mints a new "seed" art piece. Only callable by the contract owner.
    /// @return uint256 The ID of the newly minted token.
    function mintInitialSeed() external onlyOwner whenNotPaused returns (uint256) {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Initial Genome State (can be randomized slightly here if desired)
        _artGenomes[newTokenId] = ArtGenome({
            generation: 0,
            energyLevel: maxEnergy / 2, // Start with some energy
            mutationFactor: 10,
            growthStage: GrowthStage.Seed,
            colorGenes: 100, // Example initial value
            shapeGenes: 100, // Example initial value
            lastEvolvedBlock: block.number,
            lastEnergyHarvestBlock: block.number,
            mutationBoostEndTime: 0 // No boost initially
        });

        _safeMint(msg.sender, newTokenId);

        emit ArtMinted(newTokenId, msg.sender);
        return newTokenId;
    }

    /// @notice Attempts to evolve the art piece based on time elapsed.
    /// @dev Checks if enough blocks have passed since the last evolution and if energy is sufficient.
    /// @param tokenId The ID of the token to evolve.
    function triggerEvolutionByTime(uint256 tokenId) external whenNotPaused {
        _requireOwned(tokenId);
        ArtGenome storage genome = _artGenomes[tokenId];

        uint256 blocksSinceLastEvolution = block.number - genome.lastEvolvedBlock;
        if (blocksSinceLastEvolution < evolutionCooldownBlocks) {
            revert EvolutionOnCooldown(tokenId, evolutionCooldownBlocks - blocksSinceLastEvolution);
        }

        // Ensure enough energy (harvest first if needed)
        harvestEnergy(tokenId);
        if (genome.energyLevel < requiredEnergyPerEvolution) {
            revert InsufficientEnergy(tokenId, genome.energyLevel, requiredEnergyPerEvolution);
        }

        _attemptEvolution(tokenId, genome);
    }

    /// @notice Allows the owner to pay Ether to trigger evolution immediately.
    /// @dev Bypasses the time cooldown but still requires energy. Ether contributes to contract balance.
    /// @param tokenId The ID of the token to nurture and evolve.
    function triggerEvolutionByNurturing(uint256 tokenId) external payable whenNotPaused {
        _requireOwned(tokenId);
        if (msg.value < nurturingCost) {
            revert NurtureCostTooLow(nurturingCost);
        }

        ArtGenome storage genome = _artGenomes[tokenId];

        // Ensure enough energy (harvest first if needed)
        harvestEnergy(tokenId);
        if (genome.energyLevel < requiredEnergyPerEvolution) {
             revert InsufficientEnergy(tokenId, genome.energyLevel, requiredEnergyPerEvolution);
        }

        // Pay ether cost (already checked by payable and msg.value)
        // Ether stays in contract for owner withdrawal

        _attemptEvolution(tokenId, genome);
        emit Nurtured(tokenId, requiredEnergyPerEvolution);
    }

     /// @notice Allows the owner to pay Ether to influence the art's color genes.
     /// @dev Requires energy and pays Ether. Simplified example: increases color genes slightly.
     /// @param tokenId The ID of the token to influence.
    function influenceColor(uint256 tokenId) external payable whenNotPaused {
        _requireOwned(tokenId);
        if (msg.value < nurturingCost) {
            revert NurtureCostTooLow(nurturingCost);
        }

        ArtGenome storage genome = _artGenomes[tokenId];

        // Example cost: half the evolution energy cost
        uint256 influenceEnergyCost = requiredEnergyPerEvolution / 2;
         harvestEnergy(tokenId);
        if (genome.energyLevel < influenceEnergyCost) {
             revert InsufficientEnergy(tokenId, genome.energyLevel, influenceEnergyCost);
        }

        genome.energyLevel -= influenceEnergyCost;

        // Simplified influence: slightly increase color genes
        genome.colorGenes += (genome.colorGenes / 20) + 5; // Increase by ~5% + a small base amount
        if (genome.colorGenes > 1000) genome.colorGenes = 1000; // Cap example gene value

        emit Nurtured(tokenId, influenceEnergyCost);
    }

    /// @notice Allows the owner to pay Ether to influence the art's shape genes.
    /// @dev Requires energy and pays Ether. Simplified example: increases shape genes slightly.
    /// @param tokenId The ID of the token to influence.
    function influenceShape(uint256 tokenId) external payable whenNotPaused {
        _requireOwned(tokenId);
         if (msg.value < nurturingCost) {
            revert NurtureCostTooLow(nurturingCost);
        }

        ArtGenome storage genome = _artGenomes[tokenId];

         // Example cost: half the evolution energy cost
        uint256 influenceEnergyCost = requiredEnergyPerEvolution / 2;
         harvestEnergy(tokenId);
        if (genome.energyLevel < influenceEnergyCost) {
             revert InsufficientEnergy(tokenId, genome.energyLevel, influenceEnergyCost);
        }

        genome.energyLevel -= influenceEnergyCost;

        // Simplified influence: slightly increase shape genes
        genome.shapeGenes += (genome.shapeGenes / 20) + 5; // Increase by ~5% + a small base amount
         if (genome.shapeGenes > 1000) genome.shapeGenes = 1000; // Cap example gene value

        emit Nurtured(tokenId, influenceEnergyCost);
    }

     /// @notice Allows the owner to pay Ether to apply a temporary mutation boost.
     /// @dev Increases the chance of mutation for subsequent evolutions for a number of blocks.
     /// @param tokenId The ID of the token to boost.
    function applyMutationBoost(uint256 tokenId) external payable whenNotPaused {
         _requireOwned(tokenId);
         if (msg.value < nurturingCost) {
            revert NurtureCostTooLow(nurturingCost);
        }

        ArtGenome storage genome = _artGenomes[tokenId];

         // Example cost: half the evolution energy cost
        uint256 boostEnergyCost = requiredEnergyPerEvolution / 2;
        harvestEnergy(tokenId);
        if (genome.energyLevel < boostEnergyCost) {
             revert InsufficientEnergy(tokenId, genome.energyLevel, boostEnergyCost);
        }

        genome.energyLevel -= boostEnergyCost;
        genome.mutationBoostEndTime = block.number + 50; // Boost lasts for 50 blocks (example)

        emit Nurtured(tokenId, boostEnergyCost);
    }


    /// @notice Calculates and adds regenerated energy to an art piece. Can be called by anyone.
    /// @param tokenId The ID of the token to harvest energy for.
    function harvestEnergy(uint256 tokenId) public whenNotPaused {
         // Does not need to be owned, anyone can help "regenerate" energy by calling
         // but only the owner benefits from spending it.
        _requireMinted(tokenId); // Ensure token exists

        ArtGenome storage genome = _artGenomes[tokenId];
        uint256 blocksSinceLastHarvest = block.number - genome.lastEnergyHarvestBlock;

        uint256 regenerated = blocksSinceLastHarvest * energyRegenPerBlock;
        if (regenerated == 0) {
             // No energy to harvest yet
            return;
        }

        uint256 energyToAdd = maxEnergy - genome.energyLevel; // Don't exceed max
        if (energyToAdd > regenerated) {
            energyToAdd = regenerated;
        }

        if (energyToAdd > 0) {
             genome.energyLevel += energyToAdd;
             genome.lastEnergyHarvestBlock = block.number;
            emit EnergyHarvested(tokenId, energyToAdd, genome.energyLevel);
        }
    }

     /// @notice Forces the art piece into a decay state.
     /// @dev Can only be called by the owner. Decay is often a permanent state in such systems.
     /// @param tokenId The ID of the token to force decay.
    function forceDecay(uint256 tokenId) external onlyOwner whenNotPaused {
        _requireOwned(tokenId);
        ArtGenome storage genome = _artGenomes[tokenId];

        if (genome.growthStage == GrowthStage.Decay) {
            revert AlreadyInDecay(tokenId);
        }
         if (genome.growthStage == GrowthStage.Seed || genome.growthStage == GrowthStage.Rebirth) {
             revert DecayNotPossible(tokenId); // Cannot decay Seeds or Rebirths (example rule)
         }


        genome.growthStage = GrowthStage.Decay;
        // Optionally reduce genes, mutation factor, energy etc. upon decay
        genome.energyLevel = 0;
        genome.mutationFactor = 0;
        genome.colorGenes /= 2;
        genome.shapeGenes /= 2;

        emit ArtDecayed(tokenId);
    }


    // --- View Functions ---

    /// @notice Returns the full on-chain ArtGenome state for a token.
    /// @param tokenId The ID of the token.
    /// @return ArtGenome The art's current genome state.
    function getArtGenome(uint256 tokenId) public view returns (ArtGenome memory) {
        _requireMinted(tokenId); // Ensure token exists
        return _artGenomes[tokenId];
    }

     /// @notice Returns the current energy level of the art piece.
     /// @param tokenId The ID of the token.
     /// @return uint256 The current energy level.
    function getEnergyLevel(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        // Note: This doesn't account for energy regenerated since the last harvest
        // unless harvestEnergy is called first. getArtGenome is the direct state view.
        return _artGenomes[tokenId].energyLevel;
    }

    /// @notice Returns the current growth stage of the art piece.
    /// @param tokenId The ID of the token.
    /// @return GrowthStage The current growth stage.
    function getGrowthStage(uint256 tokenId) public view returns (GrowthStage) {
        _requireMinted(tokenId);
        return _artGenomes[tokenId].growthStage;
    }

     /// @notice Returns the contract's configured required energy per evolution.
    function getRequiredEnergyForEvolution() public view returns (uint256) {
        return requiredEnergyPerEvolution;
    }

    /// @notice Returns the contract's configured evolution cooldown in blocks.
    function getEvolutionCooldown() public view returns (uint256) {
        return evolutionCooldownBlocks;
    }

     /// @notice Returns the number of blocks left until time-based evolution is possible.
     /// @param tokenId The ID of the token.
     /// @return uint256 Blocks remaining until cooldown finishes. Returns 0 if already ready.
    function getEvolutionCooldown(uint256 tokenId) public view returns (uint256) {
         _requireMinted(tokenId);
         uint256 lastEvolved = _artGenomes[tokenId].lastEvolvedBlock;
         if (block.number < lastEvolved + evolutionCooldownBlocks) {
             return (lastEvolved + evolutionCooldownBlocks) - block.number;
         }
         return 0;
    }


     /// @notice Checks if the art piece is ready for time-based evolution (cooldown passed and sufficient energy).
     /// @param tokenId The ID of the token.
     /// @return bool True if time evolution is possible.
    function isEvolutionReady(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        ArtGenome storage genome = _artGenomes[tokenId];

        bool cooldownPassed = block.number >= genome.lastEvolvedBlock + evolutionCooldownBlocks;
        // Need to estimate energy including potential regen since last harvest
        uint256 blocksSinceLastHarvest = block.number - genome.lastEnergyHarvestBlock;
        uint256 estimatedEnergy = genome.energyLevel + (blocksSinceLastHarvest * energyRegenPerBlock);
        if (estimatedEnergy > maxEnergy) estimatedEnergy = maxEnergy; // Cap estimate

        bool hasEnergy = estimatedEnergy >= requiredEnergyPerEvolution;

        return cooldownPassed && hasEnergy && genome.growthStage != GrowthStage.Decay; // Cannot evolve if decayed
    }

     /// @notice Returns the base URI for token metadata.
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

     /// @notice Returns the URI explaining how genes map to visuals.
    function getTraitMappingURI() public view returns (string memory) {
        return _traitMappingURI;
    }

    /// @notice Calculates and returns the current chance of a significant mutation occurring.
    /// @dev Simplified calculation based on mutationFactor and potentially growth stage.
    /// @param tokenId The ID of the token.
    /// @return uint256 Chance represented as a percentage (0-100).
    function getMutationChance(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        ArtGenome storage genome = _artGenomes[tokenId];

        uint256 baseChance = genome.mutationFactor; // Use mutationFactor directly as base %
        if (block.number < genome.mutationBoostEndTime) {
            baseChance += 20; // Add extra chance during boost (example)
        }

        // Further adjustments based on stage (example)
        if (genome.growthStage == GrowthStage.Seed) baseChance += 10;
        if (genome.growthStage == GrowthStage.Declining) baseChance += 15; // Decay has high chance? Or 0? Depends on desired logic. Let's say Declining increases it.
        if (genome.growthStage == GrowthStage.Decay) return 0; // Cannot mutate if decayed

        // Cap chance at 100%
        if (baseChance > 100) baseChance = 100;

        return baseChance;
    }

     /// @notice Returns the block number when the art piece last evolved.
     /// @param tokenId The ID of the token.
     /// @return uint256 The block number of the last evolution.
    function getLastEvolvedBlock(uint256 tokenId) public view returns (uint256) {
         _requireMinted(tokenId);
         return _artGenomes[tokenId].lastEvolvedBlock;
    }


    // --- Admin Functions (Owner Only) ---

    /// @notice Updates evolution parameters.
    /// @param _evolutionCooldownBlocks Blocks required between time-based evolutions.
    /// @param _requiredEnergyPerEvolution Energy cost for a standard evolution.
    /// @param _energyRegenPerBlock Energy points regenerated per block since last harvest.
    /// @param _maxEnergy Maximum energy an art piece can hold.
    /// @param _nurturingCost Cost to trigger nurturing evolution/influence in Wei.
    function setEvolutionParams(
        uint256 _evolutionCooldownBlocks,
        uint256 _requiredEnergyPerEvolution,
        uint256 _energyRegenPerBlock,
        uint256 _maxEnergy,
        uint256 _nurturingCost
    ) external onlyOwner {
        evolutionCooldownBlocks = _evolutionCooldownBlocks;
        requiredEnergyPerEvolution = _requiredEnergyPerEvolution;
        energyRegenPerBlock = _energyRegenPerBlock;
        maxEnergy = _maxEnergy;
        nurturingCost = _nurturingCost;

        emit EvolutionParamsUpdated(evolutionCooldownBlocks, requiredEnergyPerEvolution, energyRegenPerBlock, maxEnergy, nurturingCost);
    }

     /// @notice Sets the base URI for token metadata.
     /// @param newBaseURI The new base URI.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

     /// @notice Sets the URI explaining how genes map to visuals.
     /// @param newTraitMappingURI The new trait mapping URI.
    function setTraitMappingURI(string memory newTraitMappingURI) external onlyOwner {
        _traitMappingURI = newTraitMappingURI;
    }

     /// @notice Allows the owner to withdraw gathered Ether from nurturing/influence actions.
    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Internal/Private Helper Functions ---

    /// @dev Applies the core evolution logic to an art piece's genome.
    /// This is where the dynamic state change happens.
    /// @param tokenId The ID of the token being evolved.
    /// @param genome The genome struct to modify.
    function _evolve(uint256 tokenId, ArtGenome storage genome) internal {
        // Consume energy
        genome.energyLevel = genome.energyLevel > requiredEnergyPerEvolution ? genome.energyLevel - requiredEnergyPerEvolution : 0;

        // Increment generation
        genome.generation++;

        // Update last evolved block
        genome.lastEvolvedBlock = block.number;

        // Determine if mutation occurs using simplified pseudorandomness
        uint256 mutationRoll = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, genome.generation))) % 100;
        bool mutated = mutationRoll < getMutationChance(tokenId); // Use the calculated chance

        // Apply Evolution Rules based on Stage and Mutation
        GrowthStage currentStage = genome.growthStage;
        GrowthStage nextStage = currentStage; // Default: stay in stage or move linearly

        if (currentStage == GrowthStage.Seed && genome.generation >= 1) nextStage = GrowthStage.Sprout;
        else if (currentStage == GrowthStage.Sprout && genome.generation >= 5) nextStage = GrowthStage.Bloom;
        else if (currentStage == GrowthStage.Bloom && genome.generation >= 10) nextStage = GrowthStage.Mature;
        else if (currentStage == GrowthStage.Mature && genome.energyLevel < requiredEnergyPerEvolution / 2) nextStage = GrowthStage.Declining; // Decline if low energy
         else if (currentStage == GrowthStage.Declining && genome.energyLevel == 0) nextStage = GrowthStage.Decay; // Decay if out of energy

        if (mutated) {
            // Apply significant mutation effect
            // Example: Randomly shift color/shape genes more drastically
            uint256 geneShift = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, genome.generation, "mutation_shift"))) % 50 + 10; // Shift by 10-60
            if (uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, "color")))%2 == 0) {
                 if (genome.colorGenes + geneShift > 1000) genome.colorGenes = 1000; else genome.colorGenes += geneShift;
            } else {
                 if (genome.colorGenes < geneShift) genome.colorGenes = 0; else genome.colorGenes -= geneShift;
            }
             if (uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, "shape")))%2 == 0) {
                 if (genome.shapeGenes + geneShift > 1000) genome.shapeGenes = 1000; else genome.shapeGenes += geneShift;
             } else {
                 if (genome.shapeGenes < geneShift) genome.shapeGenes = 0; else genome.shapeGenes -= geneShift;
             }
             genome.mutationFactor += 5; // Mutation makes it slightly more prone to future mutations
             if (genome.mutationFactor > 200) genome.mutationFactor = 200;

            // Mutation could also potentially shift stages randomly or unlock special stages
             // uint256 stageRoll = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tokenId, "stage_roll"))) % 100;
             // if (mutated && stageRoll < 20 && currentStage != GrowthStage.Decay) { // 20% chance of random stage jump on mutation
             //    nextStage = GrowthStage(stageRoll % uint(GrowthStage.Rebirth + 1)); // Example: Jump to a random stage
             // }
        } else {
            // Standard, less drastic evolution based on stage
            // Example: Slightly increase color/shape genes over time
            genome.colorGenes += 1;
            if (genome.colorGenes > 1000) genome.colorGenes = 1000;
            genome.shapeGenes += 1;
             if (genome.shapeGenes > 1000) genome.shapeGenes = 1000;
        }

         // Handle potential state transitions like Rebirth from Decay (complex, omitted for brevity but possible)
         // if (currentStage == GrowthStage.Decay && (new conditions met)) { nextStage = GrowthStage.Rebirth; ... reset genes ... }

        genome.growthStage = nextStage;

        emit EvolutionTriggered(tokenId, genome.generation, genome.growthStage);
    }

    /// @dev Attempts to trigger evolution, checks required conditions and calls _evolve.
    /// @param tokenId The ID of the token to evolve.
    /// @param genome The genome struct to modify.
    function _attemptEvolution(uint256 tokenId, ArtGenome storage genome) internal {
         // Harvest energy first to get accurate current level for conditions
        harvestEnergy(tokenId); // Ensures lastEnergyHarvestBlock and energyLevel are up to date

         if (genome.energyLevel < requiredEnergyPerEvolution) {
             revert InsufficientEnergy(tokenId, genome.energyLevel, requiredEnergyPerEvolution);
         }
         if (genome.growthStage == GrowthStage.Decay) {
             revert InvalidGrowthStage(tokenId, genome.growthStage);
         }

         // Consume energy before evolving
        genome.energyLevel -= requiredEnergyPerEvolution;

        // Perform the actual evolution logic
        _evolve(tokenId, genome);
    }


    /// @dev Helper to ensure token exists and is not zero address.
    function _requireMinted(uint256 tokenId) internal view {
        require(_exists(tokenId), "Token does not exist");
    }

     /// @dev Helper to ensure caller owns the token.
     function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "Token does not exist");
        require(_msgSender() == ownerOf(tokenId), "Caller is not token owner");
    }

     // The Pausable standard already has _beforeTokenTransfer which we might need to hook into
     // if transfers should affect evolution (e.g., reset cooldown on transfer)
     // For this example, we won't add complex transfer side-effects.

     /// @dev See {ERC721-_beforeTokenTransfer}.
     // We override this to enforce pausable state before transfers.
     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
         internal
         override(ERC721Enumerable)
     {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);

         if (from == address(0)) {
             // Minting - OK
         } else if (to == address(0)) {
             // Burning - OK
         } else {
             // Transferring
              require(!paused(), "Contract is paused"); // Prevent transfers while paused
         }
     }
}
```

---

**Notes:**

1.  **Off-Chain Metadata:** The `tokenURI` function returns a URI pointing to a hypothetical external service (like an API or a serverless function). This service is responsible for:
    *   Receiving the `tokenId`.
    *   Calling the smart contract's `getArtGenome(tokenId)` function to fetch the *current* on-chain state.
    *   Using the rules defined implicitly by the `_traitMappingURI` (or internal logic) to generate a JSON file conforming to the ERC721 metadata standard (name, description, image, attributes).
    *   The "image" attribute in the JSON would then point to an actual image file (SVG, PNG, etc.) *also* generated dynamically based on the genome, or pre-rendered assets combined based on the genome. This is the "dynamic" part - the image and attributes change as the on-chain state changes.
2.  **On-Chain Randomness:** The `keccak256` method using block variables and `msg.sender` provides *pseudorandomness*. It is *not* truly random and can potentially be front-run (a miner could choose not to include a block if the outcome isn't favorable, or a user could see the outcome of a transaction in the mempool and cancel it). For a simple art evolution simulation, this is often acceptable, but for high-stakes randomness (like distributing rare items), Chainlink VRF or similar oracles are required.
3.  **Evolution Complexity:** The `_evolve` function's logic is a simplified example. In a real application, this would contain more intricate rules for how genes change, how stages transition, interactions between genes, environmental factors (maybe using limited on-chain data like price feeds if relevant to the art concept), etc. This is the core creative part you'd expand upon.
4.  **Energy Management:** The energy regeneration is simple (linear per block). More complex models could involve caps on regeneration, different rates based on stage, or external factors.
5.  **Gas Costs:** Storing complex genomes on-chain and modifying them frequently incurs significant gas costs. This design assumes these costs are acceptable for the value proposition of the evolving art.
6.  **Scalability:** For a massive number of tokens, the `ERC721Enumerable` adds gas cost overhead to transfers. Depending on the intended scale, a standard ERC721 might be preferred, relying on off-chain indexing services to list tokens.
7.  **Trait Mapping URI:** The `_traitMappingURI` is conceptual. It wouldn't typically be used *by the contract* but serves as a public link or identifier that tells external services (like marketplaces or the metadata server) *how* to interpret the raw numbers in the `ArtGenome` struct to generate visual traits. E.g., "if colorGenes is between 0-100, it's red; 101-200, it's blue", etc.