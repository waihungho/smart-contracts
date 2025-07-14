Okay, let's design a smart contract that implements a dynamic, time-based, and interactive system – something like a decentralized, evolving digital garden or simulation of growing unique digital entities. We'll call it **ChronosGrove**.

These "seeds" (ChronosSeeds) will be non-fungible entities (like NFTs, but with much richer, dynamic state stored directly in the contract) that evolve based on time, user interactions, and internal mechanics. The contract itself will have states (Epochs) that influence the seeds.

This avoids standard token types (ERC-20, ERC-721 for simple assets), standard DeFi primitives (Lending, Swapping), simple DAOs, or standard Oracles. It focuses on complex state management and dynamic logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronosGrove
 * @dev A smart contract simulating a decentralized, dynamic grove where unique
 * digital 'seeds' (ChronosSeeds) are planted, nurtured, and evolve over time
 * based on user interaction and global contract epochs. This contract focuses on
 * complex state management, time-based mechanics, and interactive lifecycle events.
 *
 * Outline:
 * 1. Data Structures: Structs for Seed state and Configuration.
 * 2. State Variables: Storage for seeds, ownership, global epoch, and configuration.
 * 3. Events: Announce key state changes (planting, interaction, harvest, epoch advance, etc.).
 * 4. Errors: Custom errors for clearer failure reasons.
 * 5. Access Control: Manager role for critical configuration and maintenance.
 * 6. Configuration: Manager functions to tune simulation parameters.
 * 7. Seed Lifecycle: Functions for planting, interacting, pruning, cross-pollinating, harvesting.
 * 8. Time & State Mechanics: Functions to advance global epochs and sync seed state.
 * 9. Query Functions: Retrieve seed data, owner's seeds, contract state, and calculated metrics.
 * 10. Internal Helpers: Logic for state updates, calculations, and owner seed list management.
 *
 * Function Summary:
 * --- Public/External Functions ---
 * - constructor(address initialManager): Initializes the contract with a manager.
 * - plantSeed(): Creates a new Seed entity for the caller. May require payment.
 * - interactWithSeed(uint256 seedId): User action to nurture a seed, affecting attunement & decay timer.
 * - pruneSeed(uint256 seedId): User action to refine a seed's purity, potentially affecting growth stage.
 * - crossPollinateSeeds(uint256 seed1Id, uint256 seed2Id): Interaction between two seeds, based on compatibility.
 * - harvestSeed(uint256 seedId): Attempts to harvest a mature seed for potential rewards (simulated).
 * - advanceGlobalEpoch(): Manager or timer-based call to transition the contract to the next epoch.
 * - syncSeedEpoch(uint256 seedId): Explicitly updates a seed's internal epoch state to the global one.
 * - getSeedDetails(uint256 seedId): Retrieves all details of a specific seed.
 * - getSeedsByOwner(address owner): Gets array of seed IDs owned by an address.
 * - getSeedGrowthProgress(uint256 seedId): Calculates current growth progress percentage.
 * - getSeedPotentialDecay(uint256 seedId): Calculates potential purity decay based on time since interaction.
 * - isHarvestEligible(uint256 seedId): Checks if a seed meets the basic criteria for harvesting.
 * - getCurrentGlobalEpoch(): Gets the current global contract epoch.
 * - getTotalSupply(): Gets the total number of planted seeds.
 * - getSeedCompatibilityScore(uint256 seed1Id, uint256 seed2Id): Calculates score for cross-pollination.
 * - getConfig(): Retrieves current configuration parameters.
 * - setGrowthRates(uint16 baseRate, uint16 attunementBonus): Manager sets growth speed parameters.
 * - setDecayRate(uint16 rate): Manager sets purity decay rate.
 * - setGlobalEpochDuration(uint64 duration): Manager sets time between global epoch advancements.
 * - setPlantingFee(uint256 fee): Manager sets the cost to plant a seed.
 * - blessSeed(uint256 seedId, uint16 purityBoost, uint16 attunementBoost): Manager grants a boost to a seed.
 * - curseSeed(uint256 seedId, uint16 purityPenalty): Manager applies a penalty to a seed.
 * - transferManager(address newManager): Manager transfers manager role.
 * - withdrawFees(): Manager withdraws accumulated planting fees.
 *
 * Note: Rewards for harvesting are simulated (event emission) to keep the contract
 * self-contained and avoid dependencies on external reward tokens. Decay and growth
 * are calculated dynamically when relevant actions occur, not continuously updated.
 */

contract ChronosGrove {

    // --- Errors ---
    error SeedNotFound(uint256 seedId);
    error NotSeedOwner(uint256 seedId, address caller);
    error NotManager(address caller);
    error AlreadyMaxGrowth(uint256 seedId);
    error NotHarvestEligible(uint256 seedId);
    error InsufficientFunds(uint256 required, uint256 provided);
    error InvalidSeedCompatibility(uint16 compatibilityScore);
    error SeedAlreadyHarvested(uint256 seedId);
    error SeedCannotBeZeroAddress(); // For manager transfer
    error InvalidSeedIdsForPollination(); // If same ID passed twice


    // --- Events ---
    event SeedPlanted(uint256 indexed seedId, address indexed owner, uint64 plantTime, uint256 cost);
    event SeedInteracted(uint256 indexed seedId, uint16 newAttunement, uint64 interactionTime);
    event SeedGrowthStageAdvanced(uint256 indexed seedId, uint8 oldStage, uint8 newStage);
    event SeedPruned(uint256 indexed seedId, uint16 oldPurity, uint16 newPurity);
    event SeedsCrossPollinated(uint256 indexed seed1Id, uint256 indexed seed2Id, uint16 compatibilityScore, uint16 seed1NewAttunement, uint16 seed2NewAttunement);
    event SeedHarvested(uint256 indexed seedId, address indexed owner, uint8 finalGrowthStage, uint16 finalPurity);
    event GlobalEpochAdvanced(uint8 oldEpoch, uint8 newEpoch, uint64 advanceTime);
    event SeedEpochSynced(uint256 indexed seedId, uint8 oldEpoch, uint8 newEpoch);
    event SeedBlessed(uint256 indexed seedId, uint16 purityBoost, uint16 attunementBoost);
    event SeedCursed(uint256 indexed seedId, uint16 purityPenalty);
    event ManagerTransferred(address indexed oldManager, address indexed newManager);
    event FeesWithdrawn(address indexed receiver, uint256 amount);
    event ConfigUpdated(); // Generic event for configuration changes


    // --- Data Structures ---
    struct Seed {
        uint256 id;
        address owner;
        uint8 epoch; // Epoch when planted or last significantly synced
        uint8 growthStage; // 0-100, represents how 'mature' it is within its epoch
        uint16 purity; // 0-1000, affects outcomes and decay resistance
        uint16 attunement; // 0-1000, increases growth speed
        uint64 plantTime;
        uint64 lastInteractionTime;
        bool harvested; // Flag to mark if seed has been harvested
    }

    struct Config {
        uint16 baseGrowthRate; // Base points of growth per day
        uint16 attunementGrowthBonus; // Bonus growth points per 100 attunement per day
        uint16 decayRate; // Purity decay points per day if neglected
        uint64 globalEpochDuration; // Duration in seconds for each global epoch
        uint8 maxGrowthStage; // Maximum possible growth stage
        uint16 maxPurity; // Maximum possible purity
        uint16 maxAttunement; // Maximum possible attunement
        uint256 plantingFee; // Fee required to plant a seed
    }


    // --- State Variables ---
    uint256 private _seedCounter; // Counter for unique seed IDs
    uint256 private _totalSupply; // Total number of active (not harvested) seeds

    // Mapping from seed ID to Seed struct
    mapping(uint256 => Seed) private _seeds;

    // Mapping from owner address to array of their seed IDs
    mapping(address => uint256[] private _ownerSeeds);
    // Helper mapping to quickly find index in _ownerSeeds array (for removal)
    mapping(uint256 => uint256) private _seedIndexInOwner;

    // Global contract epoch and start time
    uint8 private _currentGlobalEpoch;
    uint64 private _globalEpochStartTime;

    // Configuration parameters
    Config public config;

    // Access control
    address private _manager;


    // --- Modifiers ---
    modifier onlyManager() {
        if (msg.sender != _manager) revert NotManager(msg.sender);
        _;
    }

    modifier seedExists(uint256 seedId) {
        if (_seeds[seedId].id == 0 && seedId != 0) revert SeedNotFound(seedId); // Check id != 0 because default struct has id 0
        if (_seeds[seedId].harvested) revert SeedAlreadyHarvested(seedId);
        _;
    }

    modifier isSeedOwner(uint256 seedId) {
         if (_seeds[seedId].owner != msg.sender) revert NotSeedOwner(seedId, msg.sender);
        _;
    }


    // --- Constructor ---
    constructor(address initialManager) {
        if (initialManager == address(0)) revert SeedCannotBeZeroAddress();
        _manager = initialManager;
        _globalEpochStartTime = uint64(block.timestamp);

        // Set initial default configuration
        config = Config({
            baseGrowthRate: 50, // 5% per day
            attunementGrowthBonus: 10, // +1% per 100 attunement per day
            decayRate: 20, // -2% purity per day
            globalEpochDuration: 30 days, // Approximately 1 month
            maxGrowthStage: 100,
            maxPurity: 1000,
            maxAttunement: 1000,
            plantingFee: 0 // Free initially
        });
        emit ConfigUpdated();
    }


    // --- Seed Lifecycle Functions ---

    /**
     * @dev Creates a new Chronos Seed for the caller.
     * Requires the planting fee if set.
     */
    function plantSeed() external payable {
        if (msg.value < config.plantingFee) revert InsufficientFunds(config.plantingFee, msg.value);

        _seedCounter++;
        uint256 newSeedId = _seedCounter;
        uint64 currentTime = uint64(block.timestamp);

        Seed storage newSeed = _seeds[newSeedId];
        newSeed.id = newSeedId;
        newSeed.owner = msg.sender;
        newSeed.epoch = _currentGlobalEpoch; // Seed starts in the current global epoch
        newSeed.growthStage = 0;
        newSeed.purity = config.maxPurity / 2; // Start with half purity
        newSeed.attunement = 0;
        newSeed.plantTime = currentTime;
        newSeed.lastInteractionTime = currentTime;
        newSeed.harvested = false;

        _totalSupply++;
        _addSeedToOwner(msg.sender, newSeedId);

        emit SeedPlanted(newSeedId, msg.sender, currentTime, config.plantingFee);
    }

    /**
     * @dev User interacts with their seed to increase attunement and reset decay timer.
     * @param seedId The ID of the seed to interact with.
     */
    function interactWithSeed(uint256 seedId) external seedExists(seedId) isSeedOwner(seedId) {
        Seed storage seed = _seeds[seedId];

        // Apply decay BEFORE applying new interaction effects
        _applyDecay(seed);

        // Increase attunement, capped at max
        seed.attunement = uint16(Math.min(uint256(seed.attunement) + 50, config.maxAttunement)); // Gain 50 attunement per interaction
        seed.lastInteractionTime = uint64(block.timestamp);

        emit SeedInteracted(seedId, seed.attunement, seed.lastInteractionTime);
    }

    /**
     * @dev User prunes their seed to improve purity at a potential cost to growth stage.
     * @param seedId The ID of the seed to prune.
     */
    function pruneSeed(uint256 seedId) external seedExists(seedId) isSeedOwner(seedId) {
        Seed storage seed = _seeds[seedId];

        // Apply decay BEFORE pruning
        _applyDecay(seed);

        uint16 oldPurity = seed.purity;
        uint8 oldGrowthStage = seed.growthStage;

        // Increase purity, capped at max
        seed.purity = uint16(Math.min(uint256(seed.purity) + 100, config.maxPurity)); // Gain 100 purity
        seed.lastInteractionTime = uint64(block.timestamp); // Pruning is also an interaction

        // Small chance or fixed reduction in growth stage? Let's do fixed reduction
        if (seed.growthStage > 10) { // Only reduce if already past initial stage
             seed.growthStage = uint8(Math.max(uint256(seed.growthStage) - 10, 0));
             emit SeedGrowthStageAdvanced(seedId, oldGrowthStage, seed.growthStage); // Or a specific PruneGrowthPenalty event
        }


        emit SeedPruned(seedId, oldPurity, seed.purity);
    }

    /**
     * @dev Attempts to cross-pollinate two seeds.
     * Success depends on compatibility and boosts attunement of both seeds.
     * @param seed1Id The ID of the first seed.
     * @param seed2Id The ID of the second seed.
     */
    function crossPollinateSeeds(uint256 seed1Id, uint256 seed2Id) external seedExists(seed1Id) seedExists(seed2Id) {
        // Ensure caller owns both or make it a permissioned action (keeping it owner of *both* for simplicity)
        if (_seeds[seed1Id].owner != msg.sender || _seeds[seed2Id].owner != msg.sender) {
            revert NotSeedOwner(seed1Id, msg.sender); // Using seed1Id here, could specify both
        }
        if (seed1Id == seed2Id) revert InvalidSeedIdsForPollination();

        Seed storage seed1 = _seeds[seed1Id];
        Seed storage seed2 = _seeds[seed2Id];

         // Apply decay before pollination logic
        _applyDecay(seed1);
        _applyDecay(seed2);

        // Calculate compatibility - Example: based on combined purity, attunement, and epoch difference
        uint16 compatibility = _calculateCompatibilityScore(seed1, seed2);

        // Define a threshold for successful cross-pollination
        uint16 minCompatibilityForEffect = 800; // Example threshold

        uint16 oldAttunement1 = seed1.attunement;
        uint16 oldAttunement2 = seed2.attunement;

        if (compatibility >= minCompatibilityForEffect) {
            // Boost attunement for both seeds based on compatibility
            uint16 attunementBoost = compatibility / 10; // Example: 800 comp gives 80 attunement boost
            seed1.attunement = uint16(Math.min(uint256(seed1.attunement) + attunementBoost, config.maxAttunement));
            seed2.attunement = uint16(Math.min(uint256(seed2.attunement) + attunementBoost, config.maxAttunement));

            // Update interaction time for both
            uint64 currentTime = uint64(block.timestamp);
            seed1.lastInteractionTime = currentTime;
            seed2.lastInteractionTime = currentTime;

             emit SeedsCrossPollinated(seed1Id, seed2Id, compatibility, seed1.attunement, seed2.attunement);
        } else {
             // No boost, but maybe still log the attempt and score
             emit SeedsCrossPollinated(seed1Id, seed2Id, compatibility, oldAttunement1, oldAttunement2); // Emit without attunement change
             // Optionally revert or add a penalty for low compatibility
             // revert InvalidSeedCompatibility(compatibility); // Could revert if compatibility is too low
        }
    }

    /**
     * @dev Attempts to harvest a seed. Requires the seed to be eligible (mature enough).
     * Emits an event indicating success and potential rewards. Removes the seed.
     * @param seedId The ID of the seed to harvest.
     */
    function harvestSeed(uint256 seedId) external seedExists(seedId) isSeedOwner(seedId) {
        Seed storage seed = _seeds[seedId];

        // Apply decay and growth calculations one last time before checking eligibility
        _applyDecay(seed);
        _applyGrowth(seed);

        if (!isHarvestEligible(seedId)) {
            revert NotHarvestEligible(seedId);
        }

        // Mark as harvested and remove from active tracking
        seed.harvested = true;
        _totalSupply--;
        _removeSeedFromOwner(msg.sender, seedId);

        // Emit event signaling successful harvest and final state (for reward calculation off-chain or in another contract)
        emit SeedHarvested(seedId, msg.sender, seed.growthStage, seed.purity);

        // The seed struct remains in storage but marked as harvested, effectively removing it from the game logic.
    }


    // --- Time & State Mechanics ---

    /**
     * @dev Advances the global contract epoch. Can only be called by the manager
     * or if the minimum epoch duration has passed.
     */
    function advanceGlobalEpoch() external {
        // Check if caller is manager OR if enough time has passed since last epoch advance
        bool canAdvance = msg.sender == _manager || block.timestamp >= _globalEpochStartTime + config.globalEpochDuration;

        if (!canAdvance) revert NotManager(msg.sender); // Revert specifically if not manager AND time hasn't passed

        uint8 oldEpoch = _currentGlobalEpoch;
        _currentGlobalEpoch++;
        _globalEpochStartTime = uint64(block.timestamp); // Reset timer for the new epoch

        emit GlobalEpochAdvanced(oldEpoch, _currentGlobalEpoch, _globalEpochStartTime);

        // Note: Seeds do NOT automatically advance epoch here. Users/system must sync them.
    }

    /**
     * @dev Allows a user to sync their seed's epoch state to the current global epoch.
     * This might be necessary for future interactions or eligibility criteria.
     * @param seedId The ID of the seed to sync.
     */
    function syncSeedEpoch(uint256 seedId) external seedExists(seedId) isSeedOwner(seedId) {
        Seed storage seed = _seeds[seedId];

        if (seed.epoch < _currentGlobalEpoch) {
            uint8 oldEpoch = seed.epoch;
            seed.epoch = _currentGlobalEpoch;
            // Syncing might affect growth rate or other properties depending on future rules
            emit SeedEpochSynced(seedId, oldEpoch, seed.epoch);
        }
        // If seed.epoch >= _currentGlobalEpoch, no action needed.
    }


    // --- Query Functions ---

    /**
     * @dev Gets the full details of a seed struct.
     * @param seedId The ID of the seed.
     * @return Seed struct containing all details.
     */
    function getSeedDetails(uint256 seedId) external view seedExists(seedId) returns (Seed memory) {
        // Return a memory copy of the storage struct
        Seed storage seed = _seeds[seedId];
        return seed;
    }

    /**
     * @dev Gets an array of seed IDs owned by a specific address.
     * @param owner The address to query.
     * @return An array of seed IDs.
     */
    function getSeedsByOwner(address owner) external view returns (uint256[] memory) {
        // Return a memory copy of the storage array
        return _ownerSeeds[owner];
    }

     /**
     * @dev Calculates the current growth progress percentage for a seed based on time and attunement.
     * @param seedId The ID of the seed.
     * @return Growth progress as a percentage (0-100).
     */
    function getSeedGrowthProgress(uint256 seedId) public view seedExists(seedId) returns (uint256 percentage) {
        Seed storage seed = _seeds[seedId];
        uint256 pointsEarned = _calculateGrowthPoints(seed);
        uint256 totalPointsNeeded = config.maxGrowthStage * 100; // Assuming 100 points per stage for simplicity

        if (totalPointsNeeded == 0) return 0; // Prevent division by zero

        // Add points earned to current stage, calculate overall percentage
        uint256 currentPoints = uint256(seed.growthStage) * 100;
        uint256 totalProgress = Math.min(currentPoints + pointsEarned, totalPointsNeeded);

        return (totalProgress * 100) / totalPointsNeeded;
    }

    /**
     * @dev Calculates the potential purity decay for a seed based on time since last interaction.
     * Does not modify state.
     * @param seedId The ID of the seed.
     * @return Potential purity decay points.
     */
    function getSeedPotentialDecay(uint256 seedId) public view seedExists(seedId) returns (uint16 decayPoints) {
        Seed storage seed = _seeds[seedId];
        uint64 timeSinceInteraction = uint64(block.timestamp) - seed.lastInteractionTime;
        uint256 daysSinceInteraction = timeSinceInteraction / 1 days; // Integer division

        return uint16(daysSinceInteraction * config.decayRate);
    }

    /**
     * @dev Checks if a seed is eligible for harvesting.
     * Current criteria: must be at max growth stage and purity above a threshold.
     * @param seedId The ID of the seed.
     * @return True if eligible, false otherwise.
     */
    function isHarvestEligible(uint256 seedId) public view seedExists(seedId) returns (bool) {
        Seed storage seed = _seeds[seedId];

        // Check based on 'potential' state if growth/decay were applied now
        uint8 currentGrowth = seed.growthStage; // Growth is applied before harvest check internally
        uint16 potentialPurity = uint16(Math.max(0, int256(seed.purity) - int256(getSeedPotentialDecay(seedId))));

        return currentGrowth >= config.maxGrowthStage && potentialPurity > (config.maxPurity / 4); // Example: must have > 25% purity
    }

    /**
     * @dev Gets the current global contract epoch.
     * @return The current epoch number.
     */
    function getCurrentGlobalEpoch() external view returns (uint8) {
        return _currentGlobalEpoch;
    }

    /**
     * @dev Gets the total number of actively planted seeds.
     * @return The total supply of non-harvested seeds.
     */
    function getTotalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Calculates a compatibility score between two seeds for cross-pollination.
     * Example calculation: based on inverse epoch difference, average purity, and average attunement.
     * @param seed1Id The ID of the first seed.
     * @param seed2Id The ID of the second seed.
     * @return A compatibility score (higher is better).
     */
    function getSeedCompatibilityScore(uint256 seed1Id, uint256 seed2Id) public view seedExists(seed1Id) seedExists(seed2Id) returns (uint16 compatibilityScore) {
         if (seed1Id == seed2Id) revert InvalidSeedIdsForPollination();

        Seed storage seed1 = _seeds[seed1Id];
        Seed storage seed2 = _seeds[seed2Id];

        // Example Compatibility Logic:
        // - Inverse relationship with epoch difference (closer epochs = higher score)
        // - Direct relationship with average purity
        // - Direct relationship with average attunement

        uint256 epochDifference = uint256(seed1.epoch > seed2.epoch ? seed1.epoch - seed2.epoch : seed2.epoch - seed1.epoch);
        uint256 epochFactor = epochDifference == 0 ? 500 : (1000 / (1 + epochDifference)); // Max 1000 if same epoch, drops off

        uint256 averagePurity = (uint256(seed1.purity) + uint256(seed2.purity)) / 2; // Max 1000
        uint256 averageAttunement = (uint256(seed1.attunement) + uint256(seed2.attunement)) / 2; // Max 1000

        // Combine factors (example weighting)
        uint256 totalScore = (epochFactor / 2) + (averagePurity / 4) + (averageAttunement / 4);

        // Cap the score
        return uint16(Math.min(totalScore, uint256(config.maxPurity))); // Use maxPurity as max score limit (1000)
    }

     /**
     * @dev Gets the current contract configuration parameters.
     * @return A Config struct containing all current parameters.
     */
    function getConfig() external view returns (Config memory) {
        return config;
    }


    // --- Manager Functions ---

    /**
     * @dev Manager sets the base growth rate and attunement growth bonus.
     */
    function setGrowthRates(uint16 baseRate, uint16 attunementBonus) external onlyManager {
        config.baseGrowthRate = baseRate;
        config.attunementGrowthBonus = attunementBonus;
        emit ConfigUpdated();
    }

    /**
     * @dev Manager sets the purity decay rate.
     */
    function setDecayRate(uint16 rate) external onlyManager {
        config.decayRate = rate;
        emit ConfigUpdated();
    }

    /**
     * @dev Manager sets the duration for each global epoch.
     */
    function setGlobalEpochDuration(uint64 duration) external onlyManager {
        config.globalEpochDuration = duration;
        emit ConfigUpdated();
    }

    /**
     * @dev Manager sets the fee required to plant a new seed.
     */
    function setPlantingFee(uint256 fee) external onlyManager {
        config.plantingFee = fee;
        emit ConfigUpdated();
    }

     /**
     * @dev Manager applies a positive boost to a seed's purity and attunement.
     * @param seedId The ID of the seed to bless.
     * @param purityBoost Amount to add to purity.
     * @param attunementBoost Amount to add to attunement.
     */
    function blessSeed(uint256 seedId, uint16 purityBoost, uint16 attunementBoost) external onlyManager seedExists(seedId) {
        Seed storage seed = _seeds[seedId];

        seed.purity = uint16(Math.min(uint256(seed.purity) + purityBoost, config.maxPurity));
        seed.attunement = uint16(Math.min(uint256(seed.attunement) + attunementBoost, config.maxAttunement));
        seed.lastInteractionTime = uint64(block.timestamp); // Blessing counts as interaction

        emit SeedBlessed(seedId, purityBoost, attunementBoost);
    }

    /**
     * @dev Manager applies a negative penalty to a seed's purity.
     * @param seedId The ID of the seed to curse.
     * @param purityPenalty Amount to subtract from purity.
     */
    function curseSeed(uint256 seedId, uint16 purityPenalty) external onlyManager seedExists(seedId) {
        Seed storage seed = _seeds[seedId];

        seed.purity = uint16(Math.max(0, int256(seed.purity) - int256(purityPenalty))); // Use int256 to handle potential negative result before capping at 0
        seed.lastInteractionTime = uint64(block.timestamp); // Cursing counts as interaction

        emit SeedCursed(seedId, purityPenalty);
    }

    /**
     * @dev Transfers manager role to a new address.
     * @param newManager The address of the new manager.
     */
    function transferManager(address newManager) external onlyManager {
        if (newManager == address(0)) revert SeedCannotBeZeroAddress(); // Re-use error
        address oldManager = _manager;
        _manager = newManager;
        emit ManagerTransferred(oldManager, newManager);
    }

    /**
     * @dev Allows the manager to withdraw accumulated planting fees.
     */
    function withdrawFees() external onlyManager {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
            emit FeesWithdrawn(msg.sender, balance);
        }
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to add a seed ID to the owner's list.
     * @param owner The owner's address.
     * @param seedId The ID of the seed.
     */
    function _addSeedToOwner(address owner, uint256 seedId) internal {
        _ownerSeeds[owner].push(seedId);
        _seedIndexInOwner[seedId] = _ownerSeeds[owner].length - 1;
    }

    /**
     * @dev Internal function to remove a seed ID from the owner's list efficiently.
     * Uses swap-and-pop.
     * @param owner The owner's address.
     * @param seedId The ID of the seed to remove.
     */
    function _removeSeedFromOwner(address owner, uint256 seedId) internal {
        uint256 seedIndex = _seedIndexInOwner[seedId];
        uint256 lastIndex = _ownerSeeds[owner].length - 1;

        // If the seed is not the last one, swap it with the last one
        if (seedIndex != lastIndex) {
            uint256 lastSeedId = _ownerSeeds[owner][lastIndex];
            _ownerSeeds[owner][seedIndex] = lastSeedId;
            _seedIndexInOwner[lastSeedId] = seedIndex;
        }

        // Remove the last element (which is now either the seed or the moved element)
        _ownerSeeds[owner].pop();

        // Clean up the index mapping for the removed seed
        delete _seedIndexInOwner[seedId];
    }

    /**
     * @dev Internal function to calculate and apply purity decay based on time since last interaction.
     * Updates the seed's purity state.
     * @param seed The seed struct (storage pointer).
     */
    function _applyDecay(Seed storage seed) internal {
        uint64 timeSinceInteraction = uint64(block.timestamp) - seed.lastInteractionTime;
        uint256 daysSinceInteraction = timeSinceInteraction / 1 days; // Integer division

        uint16 decayAmount = uint16(daysSinceInteraction * config.decayRate);

        if (decayAmount > 0) {
             uint16 oldPurity = seed.purity;
            seed.purity = uint16(Math.max(0, int256(seed.purity) - int256(decayAmount)));
            // Optional: Add event for decay if desired, but could be noisy
            // emit SeedDecayed(seed.id, oldPurity, seed.purity);
        }
        // Reset last interaction time? No, only user interaction/bless/curse resets it.
    }

    /**
     * @dev Internal function to calculate growth points earned since last interaction.
     * Does NOT apply growth to seed state here, just calculates.
     * Growth application (_applyGrowth) happens *before* actions that depend on growth.
     * @param seed The seed struct (storage pointer).
     * @return Growth points earned.
     */
    function _calculateGrowthPoints(Seed storage seed) internal view returns (uint256) {
         // Calculate time elapsed since last relevant state check/update (plant time or last interaction?)
         // Let's use time since last interaction for simplicity, assuming interaction implies check/update
        uint64 timeElapsed = uint64(block.timestamp) - seed.lastInteractionTime;
        uint256 daysElapsed = timeElapsed / 1 days; // Integer division for days

        // Growth Rate = baseRate + (attunement / 100) * attunementBonus
        uint256 currentAttunement = seed.attunement;
        uint256 effectiveGrowthRate = uint256(config.baseGrowthRate) + (currentAttunement * config.attunementGrowthBonus / 1000); // attunementBonus is per 100 attunement, so divide attunement by 1000

        uint256 growthPoints = daysElapsed * effectiveGrowthRate;

        return growthPoints;
    }

     /**
     * @dev Internal function to calculate and apply growth to the seed's growth stage.
     * Updates the seed's growthStage state based on time and attunement.
     * This should be called before checking growth-dependent conditions (e.g., harvest).
     * @param seed The seed struct (storage pointer).
     */
    function _applyGrowth(Seed storage seed) internal {
         if (seed.growthStage >= config.maxGrowthStage) return; // Already maxed out

        uint256 pointsEarned = _calculateGrowthPoints(seed);
        uint256 pointsPerStage = 100; // Example: 100 points needed to advance one growth stage

        // Add points to the seed's current 'accumulated' points (conceptually, not stored)
        // And calculate how many stages this new total corresponds to
        // Since we only store the stage, we need to track points gained since the last stage change.
        // A simpler model: Just advance stages based on total time / attunement since plant time.
        // Or, track points directly. Let's add a 'growthPointsAccumulated' field.

        // --- Revised Growth Logic (Requires adding growthPointsAccumulated to Seed struct) ---
        // *Self-correction:* Adding `growthPointsAccumulated` adds complexity and storage cost.
        // Alternative: Only apply stage advances when triggered by interaction or sync.
        // Let's stick to the original plan: Calculate points based on time since *last interaction*,
        // and update the stage based on how many *new* stages have been completed since the last interaction time.
        // This requires tracking the growth stage *at* the last interaction time or recalculating.

        // Simpler approach for this example: Calculate total theoretical stage based on elapsed time and attunement,
        // capped by max stage and only allowing forward progress. Update last interaction time IF growth was applied.
        uint64 timeElapsed = uint64(block.timestamp) - seed.lastInteractionTime;
        uint256 daysElapsed = timeElapsed / 1 days;

        if (daysElapsed == 0) return; // No time passed, no growth

        uint256 currentAttunement = seed.attunement;
        uint256 effectiveGrowthRate = uint256(config.baseGrowthRate) + (currentAttunement * config.attunementGrowthBonus / 1000);
        uint256 pointsGainedPerDay = effectiveGrowthRate;
        uint256 totalPointsSinceLastInteraction = daysElapsed * pointsGainedPerDay;

        uint256 pointsPerStage = 100; // How many points needed to advance one stage
        uint256 stagesGained = totalPointsSinceLastInteraction / pointsPerStage;

        if (stagesGained > 0) {
             uint8 oldGrowthStage = seed.growthStage;
             // Advance stage, capped at max
             seed.growthStage = uint8(Math.min(uint252(oldGrowthStage) + stagesGained, uint256(config.maxGrowthStage))); // Use uint252 to match uint8 safely
             seed.lastInteractionTime = uint64(block.timestamp); // Reset timer after applying growth

             if (seed.growthStage != oldGrowthStage) {
                emit SeedGrowthStageAdvanced(seed.id, oldGrowthStage, seed.growthStage);
             }
        }
        // If stagesGained is 0, lastInteractionTime is *not* updated by growth check. It's updated by user interaction/bless/curse.
    }


    /**
     * @dev Internal function to calculate compatibility score between two seeds.
     * Called by crossPollinateSeeds.
     * @param seed1 The first seed struct (storage pointer).
     * @param seed2 The second seed struct (storage pointer).
     * @return A compatibility score.
     */
     function _calculateCompatibilityScore(Seed storage seed1, Seed storage seed2) internal view returns (uint16 compatibilityScore) {
        // Same logic as the public view function, just internal.
        uint256 epochDifference = uint256(seed1.epoch > seed2.epoch ? seed1.epoch - seed2.epoch : seed2.epoch - seed1.epoch);
        uint256 epochFactor = epochDifference == 0 ? 500 : (1000 / (1 + epochDifference));

        uint256 averagePurity = (uint256(seed1.purity) + uint256(seed2.purity)) / 2;
        uint256 averageAttunement = (uint256(seed1.attunement) + uint256(seed2.attunement)) / 2;

        uint256 totalScore = (epochFactor / 2) + (averagePurity / 4) + (averageAttunement / 4);

        return uint16(Math.min(totalScore, uint256(config.maxPurity))); // Cap at maxPurity (1000)
    }

    // --- Utility Library ---
    // Basic Math functions often useful
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }

         function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }

         function max(int256 a, int256 b) internal pure returns (int256) {
            return a > b ? a : b;
        }
    }
}
```