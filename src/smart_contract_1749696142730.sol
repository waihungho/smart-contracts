Okay, let's design a complex, creative, and advanced smart contract. Instead of a standard NFT or token contract, we'll create a "Crypto Genesis Garden" simulation. Users will own plot slots and cultivate unique, dynamic "Genesis Blooms" (NFTs) that grow, decay, can be cross-pollinated, and are affected by environmental factors, consuming and yielding a special "Nectar" token (ERC20).

This contract combines:
1.  **Dynamic NFTs:** Bloom state (health, growth) changes over time and interaction. Metadata needs to be dynamic.
2.  **Resource Management:** Users manage "Nectar" (ERC20) to nourish Blooms.
3.  **Time-Based Mechanics:** Growth and decay are based on time since last interaction.
4.  **Pseudo-Generative Art/Genetics:** Blooms have genetic codes and traits that influence appearance and capabilities, combined during breeding.
5.  **Gamification:** Nourishing, harvesting, breeding, global events.
6.  **Interconnected Systems:** ERC721 (Blooms) interacts with ERC20 (Nectar) within the contract logic.

**Disclaimer:** On-chain randomness is insecure for critical game mechanics. This contract uses a basic blockhash-based pseudo-randomness *for demonstration purposes only*. For a production system, use a secure oracle like Chainlink VRF. Dynamic metadata URI generation is complex; this contract provides the *data* for an off-chain service to generate the URI.

---

### Crypto Genesis Garden Smart Contract Outline and Function Summary

This contract manages a virtual garden ecosystem where users cultivate dynamic NFT-based "Genesis Blooms" on owned "Plot Slots", using a fungible "Nectar" token as a resource.

**Outline:**

1.  **Interfaces & Libraries:** ERC721, ERC721Enumerable, ERC721URIStorage, ERC20, Ownable, Pausable.
2.  **Errors & Events:** Custom errors and events for transparency and handling issues.
3.  **Enums & Structs:** Define Bloom growth stages, Bloom attributes.
4.  **State Variables:** Contract configurations, token addresses, mappings for plots and blooms, global parameters.
5.  **Constructor:** Initializes the contract, deploys or sets Nectar token, defines initial plot slots.
6.  **Modifiers:** Access control, pausing, plot/bloom validation.
7.  **Core ERC721 (Genesis Bloom) & ERC20 (Nectar) Functions:** Overrides and standard implementations.
8.  **Plot Slot Management:** Claiming available plot slots.
9.  **Genesis Bloom Lifecycle:**
    *   Planting Blooms.
    *   Retrieving Bloom dynamic state data.
    *   Nourishing Blooms (consuming Nectar, affecting health/growth).
    *   Cross-Pollination (breeding new Blooms, consuming Nectar, combining genetics).
    *   Harvesting (yielding Nectar from mature Blooms).
    *   Checking Bloom status (helper view function).
10. **Time-Based State Advancement:** Internal function to calculate state changes based on time.
11. **Global Environmental Events:** Admin/keeper function to trigger events affecting all Blooms.
12. **Parameter Management:** Admin functions to update game parameters (costs, rates, chances).
13. **Admin/Owner Functions:** Pausing, withdrawing fees, managing initial setup.
14. **Helper/Internal Functions:** Pseudo-randomness, genetic code generation, state calculation logic, trait management.

**Function Summary (Highlighting > 20 Key Functions):**

1.  `constructor()`: Deploys/sets Nectar token, initializes contract parameters and plot slots.
2.  `claimPlotSlot(uint256 plotId)`: Allows a user to claim an unoccupied plot slot ID.
3.  `plantBloom(uint256 plotId)`: Plants a new Genesis Bloom (NFT) on a claimed plot. Requires Nectar fee. Generates initial genetics and traits.
4.  `nourishBloom(uint256 bloomId)`: Feeds a Bloom Nectar. Increases health, resets last nourished time. Requires Nectar fee.
5.  `crossPollinate(uint256 parent1Id, uint256 parent2Id, uint256 plotId)`: Attempts to breed a new Bloom on `plotId` from two parent Blooms. Requires Nectar fee, has success chance, combines genetics.
6.  `harvest(uint256 bloomId)`: Harvests Nectar from a mature Bloom. Yields Nectar based on Bloom state, potentially resets growth stage.
7.  `getBloomDynamicState(uint256 bloomId)`: *View* function. Calculates and returns the current dynamic state (health, growth stage, vitality, etc.) based on time and interactions *without* changing state.
8.  `checkBloomStatus(uint256 bloomId)`: *View* function. Provides a summary status (e.g., "Needs Nourishment", "Ready for Harvest"). Calls `getBloomDynamicState` internally.
9.  `getPlotInfo(uint256 plotId)`: *View* function. Returns owner and current Bloom ID for a given plot slot.
10. `triggerGlobalEvent(uint256 eventType, int256 eventIntensity)`: Admin function. Initiates a global event (e.g., drought, rain) affecting all Blooms' health/growth.
11. `applyEnvironmentalShield(uint256 bloomId)`: Placeholder for a function to protect a Bloom from events (could consume Nectar or a separate token).
12. `updateGrowthDecayRate(uint256 newGrowthRate, uint256 newDecayRate)`: Admin function. Updates global parameters affecting how fast Blooms grow and decay.
13. `updateNourishCostYield(uint256 newNourishCost, uint256 newHarvestYieldFactor)`: Admin function. Updates economic parameters.
14. `updatePollinationParams(uint256 newPollinateCost, uint256 newPollinateSuccessChance)`: Admin function. Updates breeding parameters.
15. `addPossibleTrait(bytes32 traitName, uint256 rarityWeight)`: Admin function. Adds new potential traits for Blooms.
16. `getTokenURI(uint256 tokenId)`: ERC721URIStorage override. Returns the metadata URI (delegates to off-chain service via base URI + token data).
17. `distributeInitialNectar(address[] recipients, uint256[] amounts)`: Admin function. Distributes initial Nectar token supply.
18. `withdrawAdminFees(address tokenAddress)`: Admin function. Allows owner to withdraw collected fees (e.g., Nectar).
19. `pause()`: Admin function. Pauses certain contract operations.
20. `unpause()`: Admin function. Unpauses the contract.
21. `getBloomGenetics(uint256 bloomId)`: *View* function. Returns the immutable genetic code and initial traits of a Bloom.
22. `getTraitInfo(bytes32 traitName)`: *View* function. Returns details about a specific trait.

*(Note: ERC721 and ERC20 standard functions like `transfer`, `balanceOf`, `approve`, etc., bring the total function count well over 20 when inherited and considered).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Use interface for external ERC20
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title CryptoGenesisGarden
 * @dev A smart contract for a dynamic, gamified garden ecosystem using NFTs and an ERC20 token.
 * Users cultivate unique 'Genesis Blooms' (ERC721 NFTs) on 'Plot Slots', managing their growth
 * and health using 'Nectar' (ERC20). Blooms evolve over time, can be cross-pollinated, harvested,
 * and are affected by global environmental events.
 *
 * Outline:
 * 1. Interfaces & Libraries (ERC721, ERC20, Ownable, Pausable, Counters, Math)
 * 2. Errors & Events
 * 3. Enums & Structs (GrowthStage, GenesisBloom, Trait)
 * 4. State Variables (Contract parameters, token addresses, mappings for plots/blooms, traits)
 * 5. Constructor
 * 6. Modifiers (Ownable, Pausable, Plot/Bloom validation)
 * 7. Core ERC721 (Genesis Bloom) Overrides & ERC20 Interface usage
 * 8. Plot Slot Management (Claiming)
 * 9. Genesis Bloom Lifecycle (Planting, State Retrieval, Nourishing, Cross-Pollination, Harvesting)
 * 10. Time-Based State Advancement (Internal helper)
 * 11. Global Environmental Events (Triggering and Application)
 * 12. Parameter Management (Admin updates for game balance)
 * 13. Admin/Owner Functions (Pause, Withdraw, Setup)
 * 14. Helper/Internal Functions (Pseudo-randomness, Genetics, State Calculation, Traits)
 *
 * Function Summary (Highlighting > 20 key interactions):
 * - constructor(): Initializes contract, sets up plots, potentially deploys/sets Nectar ERC20.
 * - claimPlotSlot(plotId): Allows user to claim an available plot.
 * - plantBloom(plotId): Mints a new Genesis Bloom NFT on a plot. Requires Nectar fee.
 * - nourishBloom(bloomId): Uses Nectar to improve a Bloom's health and growth state.
 * - crossPollinate(parent1Id, parent2Id, plotId): Breeds a new Bloom from two existing ones. Requires Nectar fee.
 * - harvest(bloomId): Extracts Nectar from a mature Bloom.
 * - getBloomDynamicState(bloomId): View function to see Bloom's current state based on time.
 * - checkBloomStatus(bloomId): View helper for user-friendly Bloom status (needs care, ready, etc.).
 * - getPlotInfo(plotId): View function for plot ownership and content.
 * - triggerGlobalEvent(eventType, intensity): Admin: Causes a global event affecting all Blooms.
 * - applyEnvironmentalShield(bloomId): (Conceptual) Protects a Bloom from events.
 * - updateGrowthDecayRate(newGrowthRate, newDecayRate): Admin: Adjusts growth/decay speed.
 * - updateNourishCostYield(newNourishCost, newHarvestYieldFactor): Admin: Adjusts Nectar economics.
 * - updatePollinationParams(newPollinateCost, newPollinateSuccessChance): Admin: Adjusts breeding params.
 * - addPossibleTrait(traitName, rarityWeight): Admin: Adds new traits for generation.
 * - getTokenURI(tokenId): ERC721 standard override for metadata.
 * - distributeInitialNectar(recipients, amounts): Admin: Distributes initial Nectar supply.
 * - withdrawAdminFees(tokenAddress): Admin: Collects Nectar fees.
 * - pause(): Admin: Pauses gameplay.
 * - unpause(): Admin: Unpauses gameplay.
 * - getBloomGenetics(bloomId): View function for static genetic data.
 * - getTraitInfo(traitName): View function for trait details.
 */
contract CryptoGenesisGarden is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Math for uint256;

    IERC20 public nectarToken;

    Counters.Counter private _bloomCounter;
    uint256 public constant TOTAL_PLOT_SLOTS = 1000; // Fixed number of garden plots

    // --- Structs ---

    enum GrowthStage { Seed, Sprout, Bud, Bloom, Mature, Withered }

    struct GenesisBloom {
        uint256 plotId; // Which plot slot this bloom is on
        address owner; // Redundant with ERC721, but useful for struct
        uint64 creationTime; // When it was planted
        uint64 lastNourishedTime; // Last time nourishment was applied
        uint64 lastStateUpdateTime; // Last time state decay/growth was calculated
        bytes32 geneticCode; // Unique hash representing base genetics
        uint256 vitality; // Affects resource consumption/yield (0-100)
        uint256 purity; // Affects breeding outcomes (0-100)
        uint256 parentId1; // For lineage tracking (0 if genesis)
        uint256 parentId2; // For lineage tracking (0 if genesis)
        // Note: Health and GrowthStage are dynamic and calculated.
        // Traits are stored separately or derivable from geneticCode
    }

    struct Trait {
        bytes32 name; // e.g., "PetalColor", "LeafShape", "AuraType"
        uint256 rarityWeight; // For generation probability
        // Could add min/max value ranges or effects here
    }

    // --- State Variables ---

    mapping(uint256 => address) private _plotSlotOwner; // plotId => owner address (0x0 if unclaimed)
    mapping(uint256 => uint256) private _plotSlotBloom; // plotId => bloomId (0 if empty)
    mapping(uint256 => GenesisBloom) private _blooms; // bloomId => GenesisBloom struct
    mapping(uint256 => uint256[]) private _bloomTraits; // bloomId => list of trait indices applied

    Trait[] public possibleTraits; // List of all potential traits

    // Game Parameters (Can be updated by owner)
    uint256 public GROWTH_RATE_PER_HOUR = 5; // How much growth increases per hour (scaled)
    uint256 public HEALTH_DECAY_PER_HOUR = 10; // How much health decreases per hour without nourishment
    uint256 public NOURISH_HEALTH_BOOST = 40; // How much health nourishment gives
    uint256 public NOURISH_GROWTH_BOOST = 10; // How much growth nourishment gives
    uint256 public PLANT_FEE_NECTAR = 100;
    uint256 public NOURISH_FEE_NECTAR = 10;
    uint256 public CROSS_POLLINATE_FEE_NECTAR = 200;
    uint256 public CROSS_POLLINATE_SUCCESS_CHANCE = 70; // Percentage 0-100
    uint256 public HARVEST_NECTAR_FACTOR = 50; // Nectar yield per unit of vitality/health
    uint256 public MATURITY_THRESHOLD_GROWTH = 90; // Growth needed to reach Mature stage

    // --- Errors ---

    error InvalidPlotId(uint256 plotId);
    error PlotAlreadyClaimed(uint256 plotId);
    error PlotNotClaimed(uint256 plotId);
    error PlotNotEmpty(uint256 plotId);
    error PlotEmpty(uint256 plotId);
    error NotPlotOwner(uint256 plotId);
    error InvalidBloomId(uint256 bloomId);
    error NotBloomOwner(uint256 bloomId);
    error InsufficientNectar(uint256 requiredAmount);
    error BloomNotReadyFor(string action, GrowthStage currentStage);
    error PollinationFailed(string reason);
    error InvalidTraitIndex(uint256 traitIndex);

    // --- Events ---

    event PlotSlotClaimed(uint256 indexed plotId, address indexed owner);
    event BloomPlanted(uint256 indexed bloomId, uint256 indexed plotId, address indexed owner, bytes32 geneticCode);
    event BloomNourished(uint256 indexed bloomId, uint256 healthBoost, uint256 growthBoost);
    event BloomCrossPollinated(uint256 indexed newBloomId, uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed plotId);
    event BloomHarvested(uint256 indexed bloomId, uint256 nectarYield);
    event GlobalEventTriggered(uint256 eventType, int256 eventIntensity);
    event BloomStateUpdated(uint256 indexed bloomId, uint256 currentHealth, uint256 currentGrowth, GrowthStage newStage);
    event ParameterUpdated(string paramName, uint256 newValue);

    // --- Constructor ---

    constructor(address _nectarTokenAddress, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        nectarToken = IERC20(_nectarTokenAddress);
        // Optionally, could deploy Nectar token here if this contract manages its lifecycle
    }

    // --- Modifiers ---

    modifier onlyPlotOwner(uint256 plotId) {
        if (_plotSlotOwner[plotId] == address(0)) revert PlotNotClaimed(plotId);
        if (_plotSlotOwner[plotId] != _msgSender()) revert NotPlotOwner(plotId);
        _;
    }

    modifier onlyBloomOwner(uint256 bloomId) {
        if (!_exists(bloomId)) revert InvalidBloomId(bloomId);
        if (ownerOf(bloomId) != _msgSender()) revert NotBloomOwner(bloomId);
        _;
    }

    modifier checkBloomState(uint256 bloomId) {
        // This modifier *only* checks existence, the actual state calculation is done inside functions
        if (!_exists(bloomId)) revert InvalidBloomId(bloomId);
        _;
    }

    // --- ERC721 Overrides ---

    // The following overrides are required by Solidity for ERC721, ERC721Enumerable, ERC721URIStorage
    // and ensure the standard functions work correctly with our _tokens counter.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        // ERC721URIStorage requires a base URI + token ID for default.
        // For dynamic metadata, the off-chain service specified by baseURI needs
        // to calculate the JSON based on the current state of the bloom.
        // We return the standard tokenURI, and expect the metadata service
        // to call `getBloomDynamicState(tokenId)` and `getBloomGenetics(tokenId)`
        // or have indexed this data to generate the dynamic JSON.
        if (!_exists(tokenId)) revert InvalidBloomId(tokenId);

        string memory base = _baseURI();
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    // --- Plot Slot Management ---

    /**
     * @dev Allows a user to claim an available plot slot.
     * @param plotId The ID of the plot slot to claim (0 to TOTAL_PLOT_SLOTS - 1).
     */
    function claimPlotSlot(uint256 plotId) external whenNotPaused {
        if (plotId >= TOTAL_PLOT_SLOTS) revert InvalidPlotId(plotId);
        if (_plotSlotOwner[plotId] != address(0)) revert PlotAlreadyClaimed(plotId);

        _plotSlotOwner[plotId] = _msgSender();
        emit PlotSlotClaimed(plotId, _msgSender());
    }

    /**
     * @dev Gets the owner and current bloom ID for a plot slot.
     * @param plotId The ID of the plot slot.
     * @return owner The address of the plot owner (0x0 if unclaimed).
     * @return bloomId The ID of the bloom on the plot (0 if empty).
     */
    function getPlotInfo(uint256 plotId) public view returns (address owner, uint256 bloomId) {
         if (plotId >= TOTAL_PLOT_SLOTS) revert InvalidPlotId(plotId);
         return (_plotSlotOwner[plotId], _plotSlotBloom[plotId]);
    }

    // --- Genesis Bloom Lifecycle ---

    /**
     * @dev Plants a new Genesis Bloom on an owned, empty plot slot.
     * Requires Nectar payment. Generates initial genetics and traits.
     * @param plotId The ID of the plot slot to plant on.
     */
    function plantBloom(uint256 plotId) external whenNotPaused onlyPlotOwner(plotId) {
        if (_plotSlotBloom[plotId] != 0) revert PlotNotEmpty(plotId);

        // Charge Nectar fee
        if (nectarToken.balanceOf(_msgSender()) < PLANT_FEE_NECTAR) revert InsufficientNectar(PLANT_FEE_NECTAR);
        _payoutFee(_msgSender(), PLANT_FEE_NECTAR);

        _bloomCounter.increment();
        uint256 newBloomId = _bloomCounter.current();

        // Generate initial genetic code and traits (genesis bloom)
        bytes32 geneticCode = _generateGeneticCode(0, 0);
        uint256[] memory initialTraits = _generateInitialTraits(geneticCode);

        _blooms[newBloomId] = GenesisBloom({
            plotId: plotId,
            owner: _msgSender(),
            creationTime: uint64(block.timestamp),
            lastNourishedTime: uint64(block.timestamp),
            lastStateUpdateTime: uint64(block.timestamp),
            geneticCode: geneticCode,
            vitality: _calculateInitialVitality(initialTraits), // Vitality based on traits
            purity: _calculateInitialPurity(initialTraits), // Purity based on traits
            parentId1: 0,
            parentId2: 0
        });

        _bloomTraits[newBloomId] = initialTraits;

        _safeMint(_msgSender(), newBloomId);
        _plotSlotBloom[plotId] = newBloomId; // Link plot to bloom

        emit BloomPlanted(newBloomId, plotId, _msgSender(), geneticCode);
    }

    /**
     * @dev Nourishes a Bloom with Nectar, improving health and growth.
     * @param bloomId The ID of the Bloom to nourish.
     */
    function nourishBloom(uint256 bloomId) external whenNotPaused onlyBloomOwner(bloomId) checkBloomState(bloomId) {
        GenesisBloom storage bloom = _blooms[bloomId];

        // Update state based on time passed
        _advanceTimeState(bloomId);

        // Check if bloom is withered
        BloomDynamicState memory currentState = _calculateDynamicState(bloom);
        if (currentState.growthStage == GrowthStage.Withered) revert BloomNotReadyFor("nourishment", currentState.growthStage);

        // Charge Nectar fee
        if (nectarToken.balanceOf(_msgSender()) < NOURISH_FEE_NECTAR) revert InsufficientNectar(NOURISH_FEE_NECTAR);
        _payoutFee(_msgSender(), NOURISH_FEE_NECTAR);

        // Apply nourishment effects
        uint256 newHealth = Math.min(currentState.health + NOURISH_HEALTH_BOOST, 100);
        uint256 newGrowth = Math.min(currentState.growth + NOURISH_GROWTH_BOOST, 100);

        // Apply state update retroactively before setting times
        bloom.lastStateUpdateTime = uint64(block.timestamp); // Update decay/growth basis
        bloom.lastNourishedTime = uint64(block.timestamp);

        // Update vitality/purity slightly based on nourishment success? Optional complexity.

        // Recalculate and emit event for new state
        BloomDynamicState memory updatedState = _calculateDynamicState(bloom); // Recalc with new times
        emit BloomNourished(bloomId, NOURISH_HEALTH_BOOST, NOURISH_GROWTH_BOOST);
        emit BloomStateUpdated(bloomId, updatedState.health, updatedState.growth, updatedState.growthStage);
    }

    /**
     * @dev Attempts to cross-pollinate two Blooms on owned plots to create a new Bloom.
     * Requires Nectar payment and a success chance roll. Combines genetics.
     * @param parent1Id The ID of the first parent Bloom.
     * @param parent2Id The ID of the second parent Bloom.
     * @param plotId The ID of the empty plot slot to plant the new Bloom on.
     */
    function crossPollinate(uint256 parent1Id, uint256 parent2Id, uint256 plotId)
        external
        whenNotPaused
        onlyBloomOwner(parent1Id)
        onlyBloomOwner(parent2Id)
        onlyPlotOwner(plotId)
    {
        if (parent1Id == parent2Id) revert PollinationFailed("Cannot pollinate a bloom with itself");
        if (_plotSlotBloom[plotId] != 0) revert PlotNotEmpty(plotId);
        if (nectarToken.balanceOf(_msgSender()) < CROSS_POLLINATE_FEE_NECTAR) revert InsufficientNectar(CROSS_POLLINATE_FEE_NECTAR);

        GenesisBloom storage parent1 = _blooms[parent1Id];
        GenesisBloom storage parent2 = _blooms[parent2Id];

        // Update parent states based on time passed
        _advanceTimeState(parent1Id);
        _advanceTimeState(parent2Id);

        // Check if parents are ready for pollination (e.g., Mature stage and healthy enough)
        BloomDynamicState memory state1 = _calculateDynamicState(parent1);
        BloomDynamicState memory state2 = _calculateDynamicState(parent2);

        if (!_canCrossPollinate(state1.growthStage, state1.health) || !_canCrossPollinate(state2.growthStage, state2.health)) {
             revert BloomNotReadyFor("pollination", state1.growthStage < state2.growthStage ? state1.growthStage : state2.growthStage);
        }

        // Charge Nectar fee regardless of success chance
        _payoutFee(_msgSender(), CROSS_POLLINATE_FEE_NECTAR);

        // Determine success based on chance and potentially parent purity
        uint256 successChance = CROSS_POLLINATE_SUCCESS_CHANCE;
        // Add purity influence: e.g., Higher average purity increases chance
        successChance = Math.min(successChance + ((parent1.purity + parent2.purity) / 20), 100); // Example influence

        uint256 randomNumber = _getUint256Pseudorandom(block.timestamp, tx.origin, msg.sender, block.number);

        if (randomNumber % 100 >= successChance) {
            // Pollination Failed
            emit PollinationFailed("Random chance failed");
            // Optionally, add a small health/vitality cost to parents on failure
            return;
        }

        // Pollination Success!
        _bloomCounter.increment();
        uint256 newBloomId = _bloomCounter.current();

        // Generate genetic code and traits from parents
        bytes32 newGeneticCode = _generateGeneticCode(parent1.geneticCode, parent2.geneticCode);
        uint256[] memory newTraits = _generateTraitsFromParents(_bloomTraits[parent1Id], _bloomTraits[parent2Id]);

        _blooms[newBloomId] = GenesisBloom({
            plotId: plotId,
            owner: _msgSender(),
            creationTime: uint64(block.timestamp),
            lastNourishedTime: uint64(block.timestamp),
            lastStateUpdateTime: uint64(block.timestamp),
            geneticCode: newGeneticCode,
            vitality: _calculateVitalityFromParents(parent1.vitality, parent2.vitality), // Vitality from parents
            purity: _calculatePurityFromParents(parent1.purity, parent2.purity), // Purity from parents
            parentId1: parent1Id,
            parentId2: parent2Id
        });
         _bloomTraits[newBloomId] = newTraits;

        _safeMint(_msgSender(), newBloomId);
        _plotSlotBloom[plotId] = newBloomId; // Link plot to new bloom

        emit BloomCrossPollinated(newBloomId, parent1Id, parent2Id, plotId);

        // Optionally, add a cooldown or cost to parents after successful pollination
    }

    /**
     * @dev Harvests Nectar from a Mature Bloom.
     * Yield depends on Bloom's vitality and current state. Resets Bloom state.
     * @param bloomId The ID of the Bloom to harvest.
     */
    function harvest(uint256 bloomId) external whenNotPaused onlyBloomOwner(bloomId) checkBloomState(bloomId) {
        GenesisBloom storage bloom = _blooms[bloomId];

        // Update state based on time passed
        _advanceTimeState(bloomId);

        BloomDynamicState memory currentState = _calculateDynamicState(bloom);
        if (currentState.growthStage != GrowthStage.Mature) revert BloomNotReadyFor("harvest", currentState.growthStage);
        if (currentState.health < 50) revert BloomNotReadyFor("harvest (insufficient health)", currentState.health); // Needs good health

        // Calculate harvest yield based on vitality, health, etc.
        uint256 nectarYield = (bloom.vitality * currentState.health * HARVEST_NECTAR_FACTOR) / 10000; // Scale calculation

        // Ensure yield is non-zero if conditions met
        if (nectarYield == 0) nectarYield = HARVEST_NECTAR_FACTOR; // Minimum yield

        // Mint/Transfer Nectar to the owner
        // Assuming this contract has minting permissions for the Nectar token, or Nectar is pre-minted.
        // For an external ERC20, this would require a pre-approved allowance for the garden contract
        // or a minting function on the Nectar token callable by the garden contract.
        // Let's assume the garden contract *is* the minter for this example.
        // IMPORTANT: If using a separate ERC20 contract, ensure the garden contract address
        // has the MINTER_ROLE or similar permissions on the Nectar contract.
        // A safer approach is to pre-mint all Nectar and have users 'earn' transfers *from* the garden's balance.
        // Let's simulate transfer from the garden's theoretical balance (requires garden to hold Nectar).
        // A production system needs careful Nectar tokenomics and integration.
        bool success = nectarToken.transfer(_msgSender(), nectarYield);
        require(success, "Nectar transfer failed");

        // Reset bloom state after harvest
        bloom.creationTime = uint64(block.timestamp); // Reset lifecycle timer
        bloom.lastNourishedTime = uint64(block.timestamp); // Reset nourishment timer
        bloom.lastStateUpdateTime = uint64(block.timestamp); // Reset decay timer
        // Reset growth/health conceptually - state calculation handles this
        // Could slightly reduce vitality/purity after strenuous harvest - optional

        // Recalculate and emit event for new state
        BloomDynamicState memory newState = _calculateDynamicState(bloom); // Should be Seed/Sprout based on time=0
         emit BloomHarvested(bloomId, nectarYield);
        emit BloomStateUpdated(bloomId, newState.health, newState.growth, newState.growthStage);
    }

    /**
     * @dev Gets the current dynamic state of a Bloom (health, growth, stage).
     * This function is pure view and does not modify state.
     * @param bloomId The ID of the Bloom.
     * @return BloomDynamicState struct containing calculated state.
     */
    function getBloomDynamicState(uint256 bloomId)
        public
        view
        checkBloomState(bloomId)
        returns (BloomDynamicState memory)
    {
        return _calculateDynamicState(_blooms[bloomId]);
    }

     /**
      * @dev Provides a human-readable status summary for a Bloom.
      * @param bloomId The ID of the Bloom.
      * @return status A string indicating the Bloom's state (e.g., "Healthy & Growing", "Needs Nourishment", "Ready for Harvest").
      */
    function checkBloomStatus(uint256 bloomId) public view checkBloomState(bloomId) returns (string memory status) {
        BloomDynamicState memory state = getBloomDynamicState(bloomId);

        if (state.growthStage == GrowthStage.Withered) return "Withered";
        if (state.health < 30) return "Critically Low Health! Needs immediate nourishment.";
        if (state.health < 60) return "Needs Nourishment";

        if (state.growthStage == GrowthStage.Mature) return "Ready for Harvest!";
        if (state.growthStage == GrowthStage.Bloom && state.health >= 80) return "Ready for Cross-Pollination!";

        if (state.growthStage == GrowthStage.Seed) return "Just Planted";
        if (state.growthStage < GrowthStage.Mature) {
            uint256 timeSinceNourish = block.timestamp - _blooms[bloomId].lastNourishedTime;
             if (timeSinceNourish > 24 * 3600) return "Growing, but consider nourishment soon."; // Needs nourishment after 24 hours
             return "Healthy & Growing";
        }


        return "Unknown Status"; // Should not reach here
    }

    /**
     * @dev Gets the immutable genetic code and initial traits of a Bloom.
     * @param bloomId The ID of the Bloom.
     * @return geneticCode The unique genetic identifier.
     * @return traitIndices An array of indices referencing `possibleTraits`.
     */
    function getBloomGenetics(uint256 bloomId) public view checkBloomState(bloomId) returns (bytes32 geneticCode, uint256[] memory traitIndices) {
        return (_blooms[bloomId].geneticCode, _bloomTraits[bloomId]);
    }


    // --- Time-Based State Advancement (Internal) ---

    /**
     * @dev Internal helper to update a Bloom's state based on time passed since last update.
     * Calculates health decay and growth progression.
     * @param bloomId The ID of the Bloom to update.
     */
    function _advanceTimeState(uint256 bloomId) internal {
        GenesisBloom storage bloom = _blooms[bloomId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timePassedSinceUpdate = currentTime - bloom.lastStateUpdateTime;

        // Only process if time has actually passed
        if (timePassedSinceUpdate == 0) return;

        BloomDynamicState memory currentState = _calculateDynamicState(bloom); // Calculate current state *before* decay/growth

        // Calculate health decay
        uint256 decayAmount = (timePassedSinceUpdate * HEALTH_DECAY_PER_HOUR) / 3600; // Decay per second
        uint256 newHealth = currentState.health > decayAmount ? currentState.health - decayAmount : 0;

        // Calculate growth
        uint256 growthAmount = (timePassedSinceUpdate * GROWTH_RATE_PER_HOUR) / 3600; // Growth per second
        uint256 newGrowth = Math.min(currentState.growth + growthAmount, 100);

        // Note: We don't *store* health/growth directly in the struct,
        // but _calculateDynamicState reads the *current* time and lastStateUpdateTime
        // to figure out elapsed time and apply decay/growth to a baseline (last known "full" state).
        // A more complex system could store last calculated values and delta.
        // For simplicity here, _calculateDynamicState re-calculates from time stamps.
        // The key is updating lastStateUpdateTime.

        bloom.lastStateUpdateTime = currentTime;

        // Emit state update event (health/growth are recalculated in getBloomDynamicState)
        // We need to recalculate *again* after updating lastStateUpdateTime to get the true new state.
        BloomDynamicState memory updatedState = _calculateDynamicState(bloom);
        emit BloomStateUpdated(bloomId, updatedState.health, updatedState.growth, updatedState.growthStage);
    }

    /**
     * @dev Calculates the dynamic state of a Bloom (health, growth, stage) based on time.
     * This is a pure calculation function, reading bloom data and current time.
     * @param bloom The GenesisBloom struct.
     * @return A struct containing the calculated dynamic state.
     */
    function _calculateDynamicState(GenesisBloom memory bloom) internal view returns (BloomDynamicState memory) {
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeSinceNourishment = currentTime - bloom.lastNourishedTime;
        uint64 timeSinceLastUpdate = currentTime - bloom.lastStateUpdateTime; // Time since health/growth was last 'anchored' by interaction

        // Initial state upon planting is 100 health, 0 growth (Seed)
        uint256 effectiveHealth = 100; // Starting point for calculation
        uint256 effectiveGrowth = 0;   // Starting point for calculation

        // Recalculate health based on decay since last *nourishment* (or creation if no nourishment)
        // Health decays steadily from the point of last full nourishment.
        uint256 decayAmount = (timeSinceNourishment * HEALTH_DECAY_PER_HOUR) / 3600;
        effectiveHealth = 100 > decayAmount ? 100 - decayAmount : 0; // Health based on decay from full

        // Recalculate growth based on total time since *creation*
        // Growth progresses steadily since planting, potentially boosted by nourishment
        uint256 totalGrowthTime = currentTime - bloom.creationTime;
        uint256 baseGrowth = (totalGrowthTime * GROWTH_RATE_PER_HOUR) / 3600;
        // Add growth boosts from nourishment events (more complex - requires tracking boosts or recalculating)
        // For simplicity, let's just use elapsed time since creation + initial boost.
        // A better model would track total growth *boosts* applied.
        // Let's simplify and say growth just increases over time. Nourishment primarily impacts health.
        effectiveGrowth = Math.min(baseGrowth, 100);

        // Apply health boosts from nourishments retroactively? No, nourishing updates lastNourishedTime.
        // The current calculation makes nourishment restore health to 100 and reset the decay timer.
        // Growth just happens over time.

        GrowthStage growthStage;
        if (effectiveHealth == 0) {
            growthStage = GrowthStage.Withered;
        } else if (effectiveGrowth < 20) {
            growthStage = GrowthStage.Seed;
        } else if (effectiveGrowth < 40) {
            growthStage = GrowthStage.Sprout;
        } else if (effectiveGrowth < 60) {
            growthStage = GrowthStage.Bud;
        } else if (effectiveGrowth < MATURITY_THRESHOLD_GROWTH) {
            growthStage = GrowthStage.Bloom;
        } else {
            growthStage = GrowthStage.Mature;
        }

        return BloomDynamicState({
            health: effectiveHealth,
            growth: effectiveGrowth,
            growthStage: growthStage
        });
    }

    // Struct to return dynamic state data
    struct BloomDynamicState {
        uint256 health; // 0-100
        uint256 growth; // 0-100
        GrowthStage growthStage;
    }

    // --- Global Environmental Events ---

    /**
     * @dev Allows owner/admin to trigger a global event affecting all Blooms.
     * Event types and effects are predefined or passed in.
     * @param eventType An identifier for the type of event (e.g., 0=Sun Scorch, 1=Fertile Rain).
     * @param eventIntensity A value influencing the magnitude of the effect.
     */
    function triggerGlobalEvent(uint256 eventType, int256 eventIntensity) external onlyOwner whenNotPaused {
        // This is a simplified application. A real system might iterate through
        // all *active* blooms (not withered) and apply effects.
        // Iterating over all tokens (`_allTokens`) is gas-intensive with large numbers.
        // A better approach might store active bloom IDs in an iterable data structure
        // or use an off-chain process to identify blooms and call helper functions
        // with batches of bloom IDs.
        // For demonstration, we'll just emit the event. The effect application
        // could happen implicitly in _advanceTimeState based on a global event state variable,
        // or explicitly by calling a batch processing function.

        // Let's add a state variable for the active event
        // bytes32 public currentGlobalEventHash; // Stores a hash of the current event state/params

        // Apply effects implicitly in _calculateDynamicState or _advanceTimeState
        // based on the active event hash.
        // This requires _calculateDynamicState to check `currentGlobalEventHash`.

        // For this example, we just emit the event. Actual effects need implementation.
        // Example:
        // if (currentGlobalEventHash != bytes32(0)) {
        //    (eventType, eventIntensity) = decodeEventHash(currentGlobalEventHash);
        //    if (eventType == 0) { // Sun Scorch
        //       decayAmount = decayAmount + (timePassed * eventIntensity / 3600);
        //    } else if (eventType == 1) { // Fertile Rain
        //       growthAmount = growthAmount + (timePassed * eventIntensity / 3600);
        //    }
        // }
        // This makes state calculation more complex.

        // Let's stick to emitting the event for this example's complexity budget.
        emit GlobalEventTriggered(eventType, eventIntensity);
    }

    /**
     * @dev (Conceptual) Allows a user to use a shield item/Nectar to protect a Bloom.
     * Implementation would involve tracking shields per Bloom and checking in event application logic.
     * @param bloomId The ID of the Bloom to shield.
     */
    function applyEnvironmentalShield(uint256 bloomId) external whenNotPaused onlyBloomOwner(bloomId) checkBloomState(bloomId) {
        // TODO: Implement shield logic (e.g., consume Nectar, add a timestamp/duration shield state to Bloom struct)
        revert("Shielding not yet implemented");
    }

    // --- Parameter Management (Admin) ---

    /**
     * @dev Updates the rates for Bloom growth and health decay. Only callable by owner.
     */
    function updateGrowthDecayRate(uint256 newGrowthRate, uint256 newDecayRate) external onlyOwner {
        GROWTH_RATE_PER_HOUR = newGrowthRate;
        HEALTH_DECAY_PER_HOUR = newDecayRate;
        emit ParameterUpdated("GROWTH_RATE_PER_HOUR", newGrowthRate);
        emit ParameterUpdated("HEALTH_DECAY_PER_HOUR", newDecayRate);
    }

    /**
     * @dev Updates the Nectar cost for nourishment and the factor for harvest yield. Only callable by owner.
     */
    function updateNourishCostYield(uint256 newNourishCost, uint256 newHarvestYieldFactor) external onlyOwner {
        NOURISH_FEE_NECTAR = newNourishCost;
        HARVEST_NECTAR_FACTOR = newHarvestYieldFactor;
        emit ParameterUpdated("NOURISH_FEE_NECTAR", newNourishCost);
        emit ParameterUpdated("HARVEST_NECTAR_FACTOR", newHarvestYieldFactor);
    }

    /**
     * @dev Updates the Nectar cost and success chance for cross-pollination. Only callable by owner.
     */
    function updatePollinationParams(uint256 newPollinateCost, uint256 newPollinateSuccessChance) external onlyOwner {
        CROSS_POLLINATE_FEE_NECTAR = newPollinateCost;
        CROSS_POLLINATE_SUCCESS_CHANCE = newPollinateSuccessChance;
        emit ParameterUpdated("CROSS_POLLINATE_FEE_NECTAR", newPollinateCost);
        emit ParameterUpdated("CROSS_POLLINATE_SUCCESS_CHANCE", newPollinateSuccessChance);
    }

    /**
     * @dev Adds a new possible trait definition to the list. Only callable by owner.
     * Trait names should be unique.
     */
    function addPossibleTrait(bytes32 traitName, uint256 rarityWeight) external onlyOwner {
        // Basic check for uniqueness (can be improved)
        for(uint i = 0; i < possibleTraits.length; i++) {
            if (possibleTraits[i].name == traitName) revert("Trait name already exists");
        }
        possibleTraits.push(Trait({name: traitName, rarityWeight: rarityWeight}));
        // No specific event for trait added for simplicity, but could add one.
    }

     /**
      * @dev Gets information about a specific trait by its index.
      * @param traitIndex The index of the trait in the `possibleTraits` array.
      */
     function getTraitInfo(uint256 traitIndex) public view returns (bytes32 name, uint256 rarityWeight) {
         if (traitIndex >= possibleTraits.length) revert InvalidTraitIndex(traitIndex);
         Trait storage trait = possibleTraits[traitIndex];
         return (trait.name, trait.rarityWeight);
     }


    // --- Admin/Owner Functions ---

    /**
     * @dev Allows owner to distribute initial Nectar supply to users.
     * Call this once after contract deployment and Nectar token setup.
     * @param recipients Array of addresses to receive Nectar.
     * @param amounts Array of amounts corresponding to recipients.
     */
    function distributeInitialNectar(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
         require(recipients.length == amounts.length, "Recipient and amount arrays must match length");
         // Assumes this contract has MINTER_ROLE or sufficient balance on Nectar token
         // If not, this function needs to be called *from* the Nectar token contract
         // or have a pre-approved allowance to transfer from owner's balance.
         // For simplicity here, we simulate transferring from the garden's balance.
         for(uint i = 0; i < recipients.length; i++) {
             bool success = nectarToken.transfer(recipients[i], amounts[i]);
             require(success, "Nectar transfer failed during distribution");
         }
    }

    /**
     * @dev Allows the owner to withdraw collected Nectar fees from the contract.
     * @param tokenAddress The address of the token to withdraw (should be Nectar or other approved tokens).
     */
    function withdrawAdminFees(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            bool success = token.transfer(owner(), balance);
            require(success, "Fee withdrawal failed");
        }
    }

    /**
     * @dev Pauses the contract. Only owner can call.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Helper/Internal Functions ---

    /**
     * @dev Internal function to handle fee payment by transferring Nectar from sender to contract.
     * @param payer The address paying the fee.
     * @param amount The amount of Nectar to pay.
     */
    function _payoutFee(address payer, uint256 amount) internal {
        // Nectar token must be approved by the payer to allow transferFrom
        // OR the contract must have a direct transfer function with explicit user interaction
        // We'll use transferFrom assuming approval for simplicity in this example.
        // In production, consider alternatives if transferFrom UX is undesirable.
        bool success = nectarToken.transferFrom(payer, address(this), amount);
        require(success, "Fee payment failed");
    }


    /**
     * @dev Generates a pseudorandom uint256 based on block and transaction data.
     * WARNING: This is NOT cryptographically secure and is vulnerable to front-running.
     * Do NOT use for high-stakes scenarios. Replace with Chainlink VRF or similar for production.
     * @param entropy Mix in various sources of entropy.
     * @return A pseudorandom uint256.
     */
    function _getUint256Pseudorandom(uint256 e1, uint256 e2, uint256 e3, uint256 e4) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Use block.basefee instead on PoS chains
            block.number,
            e1, e2, e3, e4,
            msg.sender,
            tx.origin
        )));
    }

    /**
     * @dev Generates a genetic code (bytes32) for a new Bloom.
     * For genesis blooms (parentIds 0), it's purely random. For bred blooms,
     * it combines parent genetics pseudorandomly.
     * @param parent1GeneticCode Genetic code of parent 1 (0 for genesis).
     * @param parent2GeneticCode Genetic code of parent 2 (0 for genesis).
     * @return The generated genetic code.
     */
    function _generateGeneticCode(bytes32 parent1GeneticCode, bytes32 parent2GeneticCode) internal view returns (bytes32) {
         if (parent1GeneticCode == bytes32(0) && parent2GeneticCode == bytes32(0)) {
             // Genesis Bloom: purely random genetic code (pseudo)
             uint256 randomEntropy = _getUint256Pseudorandom(0, 0, 0, 0);
             return bytes32(keccak256(abi.encodePacked(randomEntropy, block.timestamp, block.number)));
         } else {
             // Bred Bloom: combine parent genetics
             // Simple combination: XOR or mix bytes based on randomness
             uint256 randomSeed = _getUint256Pseudorandom(uint256(parent1GeneticCode), uint256(parent2GeneticCode), 0, 0);
             bytes32 combinedCode = bytes32(uint256(parent1GeneticCode) ^ uint256(parent2GeneticCode) ^ randomSeed);
             // More complex: Pick bytes from either parent based on random coin flips
             // For simplicity, we'll use a basic hash mix.
             return bytes32(keccak256(abi.encodePacked(parent1GeneticCode, parent2GeneticCode, randomSeed)));
         }
    }

    /**
     * @dev Generates initial traits for a genesis Bloom based on its genetic code.
     * Selects traits pseudorandomly weighted by rarity.
     * @param geneticCode The genetic code of the bloom.
     * @return An array of trait indices.
     */
    function _generateInitialTraits(bytes32 geneticCode) internal view returns (uint256[] memory) {
        uint256 totalWeight = 0;
        for(uint i = 0; i < possibleTraits.length; i++) {
            totalWeight += possibleTraits[i].rarityWeight;
        }

        if (totalWeight == 0 || possibleTraits.length == 0) return new uint256[](0); // No traits configured

        // Determine number of traits (e.g., fixed number or random)
        uint256 numberOfTraitsToAssign = Math.min(uint256(3), possibleTraits.length); // Assign up to 3 traits

        uint256[] memory assignedTraitIndices = new uint256[](numberOfTraitsToAssign);
        bool[] memory usedIndices = new bool[](possibleTraits.length); // Avoid duplicate traits

        bytes32 currentSeed = geneticCode;

        for(uint i = 0; i < numberOfTraitsToAssign; i++) {
            uint256 randomValue = uint256(keccak256(abi.encodePacked(currentSeed, i))); // Use a derived seed for each trait slot
            uint256 weightRoll = randomValue % totalWeight;

            uint256 cumulativeWeight = 0;
            uint256 selectedIndex = 0;
            bool found = false;

            for(uint j = 0; j < possibleTraits.length; j++) {
                cumulativeWeight += possibleTraits[j].rarityWeight;
                if (weightRoll < cumulativeWeight && !usedIndices[j]) {
                    selectedIndex = j;
                    found = true;
                    break;
                }
                 // If already used, keep rolling through weights until an unused one is found or loop ends
                 if (j == possibleTraits.length - 1 && !found) {
                      // If loop finished without finding an unused trait (e.g., all traits used), wrap around or skip
                      // For simplicity, let's just pick the first unused one found from the start
                      for (uint k = 0; k < possibleTraits.length; k++) {
                           if (!usedIndices[k]) {
                               selectedIndex = k;
                               found = true;
                               break;
                           }
                      }
                      if (!found) {
                        // Handle case where all possible traits are assigned multiple times
                        // Or just break this inner loop and potentially assign fewer traits than numberOfTraitsToAssign
                        break; // Assign fewer traits if no unique ones left
                      }
                 }
            }

            if (found) {
                assignedTraitIndices[i] = selectedIndex;
                usedIndices[selectedIndex] = true;
                 currentSeed = keccak256(abi.encodePacked(currentSeed, selectedIndex)); // Update seed for next trait selection
            } else {
                // Handle edge case where fewer than numberOfTraitsToAssign unique traits exist
                 assembly { mstore(assignedTraitIndices, sub(mload(assignedTraitIndices), 1)) } // Shrink array size by 1
                 break;
            }
        }

        return assignedTraitIndices;
    }


    /**
     * @dev Generates traits for a bred Bloom by combining traits from parents.
     * Can inherit traits, introduce new mutations based on purity, etc.
     * @param parent1Traits Array of trait indices for parent 1.
     * @param parent2Traits Array of trait indices for parent 2.
     * @return An array of trait indices for the new Bloom.
     */
    function _generateTraitsFromParents(uint256[] memory parent1Traits, uint256[] memory parent2Traits) internal view returns (uint256[] memory) {
         // TODO: Implement complex genetic inheritance logic.
         // Example: 50/50 chance to inherit a trait from either parent if both have it.
         // Chance of mutation (picking a new random trait) based on purity.
         // Combine trait lists, remove duplicates, apply randomness.

         // For simplicity now, let's just return a copy of parent1's traits. This is NOT a real genetic mix.
         uint256[] memory newTraits = new uint256[](parent1Traits.length);
         for(uint i = 0; i < parent1Traits.length; i++) {
             newTraits[i] = parent1Traits[i];
         }
         // Real implementation requires significant logic based on `_getUint256Pseudorandom`
         // and potentially `_generateInitialTraits` logic for mutations.
         return newTraits;
    }

    /**
     * @dev Calculates initial vitality based on assigned traits.
     * Traits could have modifiers for vitality.
     * @param assignedTraits Array of trait indices.
     * @return Initial vitality (0-100).
     */
    function _calculateInitialVitality(uint256[] memory assignedTraits) internal view returns (uint256) {
        // TODO: Implement vitality calculation based on trait properties.
        // For simplicity, return a base value + small random variation.
        uint256 baseVitality = 50;
        uint256 randomModifier = _getUint256Pseudorandom(assignedTraits.length, 0, 0, 0) % 21 - 10; // -10 to +10
        int256 calculatedVitality = int256(baseVitality) + int256(randomModifier);
        return uint256(Math.max(0, calculatedVitality));
    }

    /**
     * @dev Calculates initial purity based on assigned traits and parents.
     * Traits or parent purity could influence this.
     * @param assignedTraits Array of trait indices.
     * @return Initial purity (0-100).
     */
    function _calculateInitialPurity(uint256[] memory assignedTraits) internal view returns (uint256) {
        // TODO: Implement purity calculation. For genesis, based on random/traits.
        // For bred blooms, a mix of parents + potential loss from mutations.
        uint256 basePurity = 70;
        uint256 randomModifier = _getUint256Pseudorandom(0, assignedTraits.length, 0, 0) % 31 - 15; // -15 to +15
        int256 calculatedPurity = int256(basePurity) + int256(randomModifier);
        return uint256(Math.max(0, calculatedPurity));
    }

    /**
     * @dev Calculates vitality for a bred Bloom based on parents' vitality.
     * @param parent1Vitality Vitality of parent 1.
     * @param parent2Vitality Vitality of parent 2.
     * @return New vitality (0-100).
     */
    function _calculateVitalityFromParents(uint256 parent1Vitality, uint256 parent2Vitality) internal view returns (uint256) {
         // Simple average + random variation
         uint256 averageVitality = (parent1Vitality + parent2Vitality) / 2;
         uint256 randomModifier = _getUint256Pseudorandom(parent1Vitality, parent2Vitality, 1, 0) % 11 - 5; // -5 to +5
         int256 calculatedVitality = int256(averageVitality) + int256(randomModifier);
         return uint256(Math.max(0, calculatedVitality));
    }

     /**
      * @dev Calculates purity for a bred Bloom based on parents' purity.
      * Purity might decrease slightly with each generation or mutation.
      * @param parent1Purity Purity of parent 1.
      * @param parent2Purity Purity of parent 2.
      * @return New purity (0-100).
      */
     function _calculatePurityFromParents(uint256 parent1Purity, uint256 parent2Purity) internal view returns (uint256) {
         // Simple average, possibly with a small reduction
         uint256 averagePurity = (parent1Purity + parent2Purity) / 2;
         uint256 randomModifier = _getUint256Pseudorandom(parent1Purity, parent2Purity, 2, 0) % 11 - 5; // -5 to +5
         int256 calculatedPurity = int256(averagePurity) + int256(randomModifier);
         // Could add a fixed generational purity loss: calculatedPurity = calculatedPurity - 1; // Example
         return uint256(Math.max(0, Math.min(100, calculatedPurity)));
     }


    /**
     * @dev Checks if a Bloom's state is suitable for cross-pollination.
     * @param stage The current growth stage.
     * @param health The current health (0-100).
     * @return True if pollination is possible, false otherwise.
     */
    function _canCrossPollinate(GrowthStage stage, uint256 health) internal pure returns (bool) {
        return stage >= GrowthStage.Bloom && health >= 70; // Requires Bloom stage or Mature and good health
    }
}
```