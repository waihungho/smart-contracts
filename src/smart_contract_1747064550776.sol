Okay, this is a fun challenge! Let's design a smart contract that's a bit different from the standard tokens or simple interactions.

We'll create a concept around *Dynamic, Cultivable NFTs* - let's call them "AethelSeeds". These aren't just static images; they are digital seeds that grow, decay, and change based on user interaction, time, and simulated environmental conditions (via a placeholder for an oracle). Users can plant, nurture, prune, and cross-pollinate them, aiming to grow them into valuable "Manifestations".

This involves state transitions, time-based logic, interaction tracking, parameters, and potentially a simple reward system for successful cultivation. It combines elements of collectibles, gaming, and state-aware assets.

**Concept:** AethelSeeds are ERC-721 tokens representing unique digital seeds. They have internal state variables representing their `GrowthStage`, `Health`, `Vigor`, and timestamps of key events. Users interact with them to influence their growth. Environmental conditions (simulated or via Oracle) also play a role. Successful cultivation leads to higher growth stages and potential "Harvesting" or rewards.

**Outline:**

1.  **License and Pragma**
2.  **Error Definitions**
3.  **Events:** Signify key lifecycle events (Mint, Plant, StageChange, Nurture, Harvest, Decay, Reward).
4.  **Structs:**
    *   `SeedData`: Stores the core state and history of a specific seed NFT.
    *   `GrowthProfile`: Defines parameters for how a specific *type* of seed grows and reacts.
    *   `EnvironmentalConditions`: Placeholder for external data.
5.  **Enums:** `GrowthStage`, `SeedType` (basic example).
6.  **State Variables:** Mappings for seed data, ownership, approvals, seed type profiles, contract parameters, environmental conditions, counters. Owner address.
7.  **Internal Helper Functions:**
    *   `_calculateGrowthState`: Determines the *potential* next stage/health/vigor based on current data and time. Pure calculation.
    *   `_updateGrowthState`: Applies the calculated state changes to the seed's data.
    *   `_isApprovedOrOwner`: Helper for access control on seed actions.
8.  **Constructor:** Initializes owner and potentially some initial parameters/seed types.
9.  **ERC-721 Core Functions (Custom Implementation):**
    *   `balanceOf(address owner)`
    *   `ownerOf(uint256 seedId)`
    *   `safeTransferFrom(address from, address to, uint256 seedId)`
    *   `approve(address to, uint256 seedId)`
    *   `getApproved(uint256 seedId)`
    *   `setApprovalForAll(address operator, bool approved)`
    *   `isApprovedForAll(address owner, address operator)`
    *   `tokenURI(uint256 seedId)`
    *   `supportsInterface(bytes4 interfaceId)`
10. **Seed Management Functions:**
    *   `mintSeed(uint8 seedType)`: Creates a new Seed NFT.
    *   `plantSeed(uint256 seedId)`: Initiates the growth timer for a seed.
11. **Cultivation/Interaction Functions:**
    *   `nurtureSeed(uint256 seedId)`: Applies a positive health/vigor boost, with cooldown.
    *   `pruneSeed(uint256 seedId)`: Applies a specific growth path influence or smaller boost, with cooldown.
    *   `exposeToEnvironment(uint256 seedId)`: Incorporates current environmental data into the seed's state/growth calculation factors.
    *   `forceGrowthUpdate(uint256 seedId)`: Triggers the state transition based on time, actions, and environment. Anyone can call this to help seeds progress.
12. **Advanced Cultivation Functions:**
    *   `crossPollinate(uint256 seedId1, uint256 seedId2)`: Special action requiring two suitable seeds, potentially boosting both or influencing future traits (placeholder complexity).
    *   `harvestManifestation(uint256 seedId)`: Finalizes a Mature seed into a Harvested state, potentially enabling rewards.
13. **Reward/Utility Functions:**
    *   `claimCultivationReward(uint256 seedId)`: Allows the successful cultivator (owner or approved) to claim a reward for a Harvested seed (placeholder for reward mechanism).
14. **Configuration (Owner Only) Functions:**
    *   `addSeedTypeProfile(uint8 seedType, GrowthProfile profile)`: Defines characteristics for new seed types.
    *   `setGrowthParameter(bytes32 paramName, int256 value)`: Adjusts global growth parameters.
    *   `setEnvironmentalConditions(int256 temp, int256 humidity, int256 light)`: Manually sets environmental data (for testing/simplicity, or could be called by an Oracle keeper).
    *   `setOracleAddress(address oracle)`: Sets the address of an Oracle contract (placeholder).
    *   `withdrawFunds()`: Allows owner to withdraw any ETH sent to the contract (e.g., from minting fees, if any).
15. **View/Query Functions:**
    *   `getSeedData(uint256 seedId)`: Retrieves the full data for a seed.
    *   `getGrowthParameters()`: Retrieves current global growth parameters.
    *   `getEnvironmentalConditions()`: Retrieves current environmental data.
    *   `getSeedTypeProfile(uint8 seedType)`: Retrieves the profile for a specific seed type.
    *   `getGrowthStage(uint256 seedId)`: Gets just the current growth stage.
    *   `timeSinceLastNurture(uint256 seedId)`: Helper view for UI.
    *   `getPotentialNextStage(uint256 seedId)`: Calculates and shows the potential next stage without updating state.
    *   `getUserCultivationScore(address user)`: Placeholder for a scoring mechanism based on cultivation success.
    *   `totalSeedsMinted()`: Gets the total number of seeds created.

**Function Summary (Numbered list corresponding to outline):**

1.  N/A
2.  N/A
3.  `SeedMinted`, `SeedPlanted`, `SeedStageChanged`, `SeedNurtured`, `SeedPruned`, `SeedExposedToEnvironment`, `SeedCrossPollinated`, `SeedHarvested`, `SeedDecayed`, `CultivationRewardClaimed`, `GrowthParameterSet`, `EnvironmentalConditionsSet`, `SeedTypeProfileAdded`.
4.  N/A
5.  N/A
6.  N/A
7.  `_calculateGrowthState` (internal view), `_updateGrowthState` (internal), `_isApprovedOrOwner` (internal view).
8.  `constructor`: Sets owner.
9.  `balanceOf`, `ownerOf`, `safeTransferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `tokenURI`, `supportsInterface`. (9 functions)
10. `mintSeed`, `plantSeed`. (2 functions)
11. `nurtureSeed`, `pruneSeed`, `exposeToEnvironment`, `forceGrowthUpdate`. (4 functions)
12. `crossPollinate`, `harvestManifestation`. (2 functions)
13. `claimCultivationReward`. (1 function)
14. `addSeedTypeProfile`, `setGrowthParameter`, `setEnvironmentalConditions`, `setOracleAddress`, `withdrawFunds`. (5 functions)
15. `getSeedData`, `getGrowthParameters`, `getEnvironmentalConditions`, `getSeedTypeProfile`, `getGrowthStage`, `timeSinceLastNurture`, `getPotentialNextStage`, `getUserCultivationScore`, `totalSeedsMinted`. (9 functions)

**Total Public/External Functions:** 9 + 2 + 4 + 2 + 1 + 5 + 9 = **32 functions**. This easily exceeds the requirement of 20 and provides a rich interaction model.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. License and Pragma
// 2. Error Definitions
// 3. Events: Signify key lifecycle events.
// 4. Structs: SeedData, GrowthProfile, EnvironmentalConditions.
// 5. Enums: GrowthStage, SeedType.
// 6. State Variables: Mappings for data, ownership, approvals, parameters, counters, owner address.
// 7. Internal Helper Functions: _calculateGrowthState, _updateGrowthState, _isApprovedOrOwner.
// 8. Constructor: Initializes owner and basic state.
// 9. ERC-721 Core Functions (Custom Implementation): Standard NFT functions.
// 10. Seed Management Functions: mint, plant.
// 11. Cultivation/Interaction Functions: nurture, prune, exposeToEnvironment, forceGrowthUpdate.
// 12. Advanced Cultivation Functions: crossPollinate, harvestManifestation.
// 13. Reward/Utility Functions: claimCultivationReward.
// 14. Configuration (Owner Only) Functions: add seed type, set parameters, set environment, set oracle, withdraw.
// 15. View/Query Functions: get data, get parameters, calculate projected state, etc.

// Function Summary:
// - balanceOf(address owner): Get the number of seeds owned by an address.
// - ownerOf(uint256 seedId): Get the owner of a specific seed.
// - safeTransferFrom(address from, address to, uint256 seedId): Transfer a seed, checking ownership.
// - approve(address to, uint256 seedId): Approve another address to transfer a specific seed.
// - getApproved(uint256 seedId): Get the approved address for a seed.
// - setApprovalForAll(address operator, bool approved): Set approval for an operator for all of sender's seeds.
// - isApprovedForAll(address owner, address operator): Check if an operator is approved for all seeds of an owner.
// - tokenURI(uint256 seedId): Get the metadata URI for a seed. (Placeholder implementation)
// - supportsInterface(bytes4 interfaceId): Check if the contract supports an interface (ERC-721).
// - mintSeed(uint8 seedType): Create and mint a new AethelSeed NFT of a specific type.
// - plantSeed(uint256 seedId): Mark a seed as planted, starting its growth timer. Requires ownership/approval.
// - nurtureSeed(uint256 seedId): Perform a nurturing action on a seed, boosting health/vigor. Requires ownership/approval. Has a cooldown.
// - pruneSeed(uint256 seedId): Perform a pruning action, potentially influencing growth path or vigor. Requires ownership/approval. Has a cooldown.
// - exposeToEnvironment(uint256 seedId): Updates the seed's state based on current environmental conditions. Requires ownership/approval. Has a cooldown.
// - forceGrowthUpdate(uint256 seedId): Triggers a state transition for the seed based on elapsed time, actions, and environment. Can be called by anyone.
// - crossPollinate(uint256 seedId1, uint256 seedId2): Special action for two compatible seeds, potentially boosting both. Requires ownership/approval for both.
// - harvestManifestation(uint256 seedId): Transition a Mature seed to the Harvested stage. Requires ownership/approval.
// - claimCultivationReward(uint256 seedId): Claim potential rewards for a Harvested seed. Requires ownership/approval or being the approved cultivator.
// - addSeedTypeProfile(uint8 seedType, GrowthProfile profile): Owner-only function to define parameters for a new seed type.
// - setGrowthParameter(bytes32 paramName, int256 value): Owner-only function to adjust global growth parameters.
// - setEnvironmentalConditions(int256 temp, int256 humidity, int256 light): Owner-only or Oracle-called function to set current environmental factors.
// - setOracleAddress(address oracle): Owner-only function to set the address of an external Oracle.
// - withdrawFunds(): Owner-only function to withdraw ETH from the contract.
// - getSeedData(uint256 seedId): View function to retrieve all data for a seed.
// - getGrowthParameters(): View function to retrieve current global growth parameters.
// - getEnvironmentalConditions(): View function to retrieve current environmental data.
// - getSeedTypeProfile(uint8 seedType): View function to retrieve the profile for a seed type.
// - getGrowthStage(uint256 seedId): View function to get just the current growth stage of a seed.
// - timeSinceLastNurture(uint256 seedId): View function to get time elapsed since last nurture.
// - getPotentialNextStage(uint256 seedId): View function to calculate and return the potential next stage without updating state.
// - getUserCultivationScore(address user): View function for a placeholder cultivation score.
// - totalSeedsMinted(): View function to get the total number of seeds minted.

contract AethelSeeds {

    // 2. Error Definitions
    error NotOwner();
    error NotOwnerOrApproved();
    error InvalidSeedId();
    error SeedAlreadyMinted(uint256 seedId); // Should not happen with counter
    error SeedNotPlanted();
    error SeedNotReadyForAction(string action);
    error SeedNotInCorrectStage(GrowthStage requiredStage);
    error InvalidSeedType();
    error NoRewardsAvailable();
    error InvalidParameterName();
    error BothSeedsMustBeDifferent();
    error SeedsNotCompatibleForCrossPollination();
    error WithdrawFailed();

    // 3. Events
    event SeedMinted(uint256 seedId, uint8 seedType, address indexed owner);
    event SeedPlanted(uint256 seedId, address indexed owner, uint256 plantedTime);
    event SeedStageChanged(uint256 seedId, GrowthStage oldStage, GrowthStage newStage, string reason);
    event SeedNurtured(uint256 seedId, address indexed cultivator, uint256 healthBoost, uint256 vigorBoost);
    event SeedPruned(uint256 seedId, address indexed cultivator, uint256 vigorBoost, uint256 healthBoost);
    event SeedExposedToEnvironment(uint256 seedId, int256 temp, int256 humidity, int256 light);
    event SeedCrossPollinated(uint256 seedId1, uint256 seedId2, address indexed pollinator);
    event SeedHarvested(uint256 seedId, address indexed owner);
    event SeedDecayed(uint256 seedId, address indexed owner);
    event CultivationRewardClaimed(uint256 seedId, address indexed cultivator, uint256 amount); // Amount is placeholder
    event GrowthParameterSet(bytes32 paramName, int256 value);
    event EnvironmentalConditionsSet(int256 temp, int256 humidity, int256 light);
    event SeedTypeProfileAdded(uint8 seedType, GrowthProfile profile);
    event OracleAddressSet(address oracle);

    // 5. Enums
    enum GrowthStage { Seed, Sprout, Sapling, Mature, Decayed, Harvested }
    // Example Seed Types - can be expanded
    enum SeedType { Basic, Hardy, Fragile }

    // 4. Structs
    struct SeedData {
        uint256 seedId;
        uint8 seedTypeId;
        address owner;
        address approved; // ERC-721 single approval
        uint256 mintTime;
        uint256 plantedTime;
        uint256 lastNurtureTime;
        uint256 lastPruneTime;
        uint256 lastEnvironmentCheckTime;
        int256 health; // Range, e.g., 0-100
        int256 vigor; // Range, e.g., 0-100
        GrowthStage currentStage;
        bool harvested; // Use a flag for terminal state
        bool decayed; // Use a flag for terminal state
        bool cultivationRewardClaimed;
        // Future: traits, history log, etc.
    }

    struct GrowthProfile {
        string name;
        uint256 minPlantTime; // min time needed to reach Sprout
        uint256 nurtureCooldown;
        uint256 pruneCooldown;
        uint256 environmentCooldown;
        int256 nurtureHealthBoost;
        int256 nurtureVigorBoost;
        int256 pruneHealthEffect; // Can be positive or negative
        int256 pruneVigorEffect;
        int256 healthDecayRate; // per second decay if neglected/bad env
        int256 vigorDecayRate; // per second decay if neglected/bad env
        mapping(GrowthStage => uint256) stageDuration; // time needed in a stage
        mapping(GrowthStage => int256) healthThresholds; // health needed to advance stage
        // Mapping environmental factors to effects could go here for complexity
        // e.g., mapping(uint8 conditionId => int256 effectMultiplier);
    }

    struct EnvironmentalConditions {
        int256 temperature; // Example: -20 to 40
        int256 humidity;    // Example: 0 to 100
        int256 light;       // Example: 0 to 100
        uint256 lastUpdated;
    }

    // 6. State Variables
    address private immutable i_owner;

    uint256 private _tokenIdCounter;
    mapping(uint256 => SeedData) private _seeds;

    // ERC721 State
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals; // Single token approval
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Operator approval for all tokens

    // Seed Type Definitions
    mapping(uint8 => GrowthProfile) private _seedTypeProfiles;
    uint8[] private _availableSeedTypes; // To query available types

    // Global Growth Parameters (adjustable by owner)
    mapping(bytes32 => int256) private _growthParameters;
    // Example parameters: minHealth, maxHealth, minVigor, maxVigor, decayMultiplier, envEffectMultiplier etc.

    // Environmental Data
    EnvironmentalConditions private _currentEnvironment;
    address private _oracleAddress; // Placeholder for Oracle interaction

    // Placeholder for Cultivation Score (more complex implementation would use a separate mapping)
    mapping(address => uint256) private _cultivationScores;

    // ERC165 Interface ID for ERC-721
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x804f1371; // Corrected ERC721 ID + Metadata extension

    // 7. Internal Helper Functions
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    // Helper to check if sender is owner or approved for the seed
    function _isApprovedOrOwner(uint256 seedId) internal view returns (bool) {
        address seedOwner = _seeds[seedId].owner;
        if (msg.sender == seedOwner) {
            return true;
        }
        if (_tokenApprovals[seedId] == msg.sender) {
            return true;
        }
        if (_operatorApprovals[seedOwner][msg.sender]) {
            return true;
        }
        return false;
    }

    // Core logic: Calculate potential new state without changing storage
    function _calculateGrowthState(uint256 seedId, SeedData memory seed)
        internal
        view
        returns (
            GrowthStage newStage,
            int256 newHealth,
            int256 newVigor
        )
    {
        if (seed.plantedTime == 0 || seed.currentStage == GrowthStage.Decayed || seed.currentStage == GrowthStage.Harvested) {
            return (seed.currentStage, seed.health, seed.vigor); // No growth for unplanted, decayed, or harvested seeds
        }

        GrowthProfile storage profile = _seedTypeProfiles[seed.seedTypeId];
        uint256 currentTime = block.timestamp;

        // Start with current stats
        newHealth = seed.health;
        newVigor = seed.vigor;
        newStage = seed.currentStage;

        // --- Apply Time-Based Decay ---
        uint256 timeSinceLastUpdate = currentTime - seed.lastEnvironmentCheckTime; // Use env check time as a general update point
        if (timeSinceLastUpdate > 0) {
            // Simple linear decay based on time and decay rates
            newHealth -= int256(timeSinceLastUpdate) * (profile.healthDecayRate > 0 ? profile.healthDecayRate : 0);
            newVigor -= int256(timeSinceLastUpdate) * (profile.vigorDecayRate > 0 ? profile.vigorDecayRate : 0);

            // Clamp health/vigor within reasonable bounds (e.g., 0-100)
            int256 minHealth = _growthParameters[bytes32("minHealth")];
            int256 maxHealth = _growthParameters[bytes32("maxHealth")];
             int256 minVigor = _growthParameters[bytes32("minVigor")];
            int256 maxVigor = _growthParameters[bytes32("maxVigor")];

            newHealth = newHealth < minHealth ? minHealth : (newHealth > maxHealth ? maxHealth : newHealth);
            newVigor = newVigor < minVigor ? minVigor : (newVigor > maxVigor ? maxVigor : newVigor);
        }

        // --- Apply Environmental Effects (Placeholder) ---
        // This is where Oracle data/environmental conditions would influence growth/decay
        // Example: If temp is too low, health might decay faster, etc.
        // Using _currentEnvironment for this example
        if (_currentEnvironment.temperature < 10 || _currentEnvironment.humidity < 30) {
             // Example: Bad environment causes extra decay
             int256 envDecayFactor = _growthParameters[bytes32("envDecayFactor")]; // e.g., 1
             newHealth -= envDecayFactor * (timeSinceLastUpdate / 3600); // hourly decay example
        }
        // More complex logic based on seed type profile and environment...

        // Clamp again after env effects
         int256 minHealth = _growthParameters[bytes32("minHealth")];
            int256 maxHealth = _growthParameters[bytes32("maxHealth")];
             int256 minVigor = _growthParameters[bytes32("minVigor")];
            int256 maxVigor = _growthParameters[bytes32("maxVigor")];
        newHealth = newHealth < minHealth ? minHealth : (newHealth > maxHealth ? maxHealth : newHealth);
        newVigor = newVigor < minVigor ? minVigor : (newVigor > maxVigor ? maxVigor : newVigor);


        // --- Check for Stage Progression ---
        uint256 timeInCurrentStage = currentTime - seed.lastEnvironmentCheckTime; // Simplified: time since last update
        uint256 requiredDuration = profile.stageDuration[seed.currentStage]; // Duration needed in THIS stage

        if (seed.currentStage == GrowthStage.Seed) {
            // Initial planting stage requires minPlantTime
            if (currentTime - seed.plantedTime >= profile.minPlantTime && newHealth >= profile.healthThresholds[GrowthStage.Sprout]) {
                newStage = GrowthStage.Sprout;
            }
        } else if (seed.currentStage < GrowthStage.Mature) {
            // For Sprout, Sapling stages
            if (timeInCurrentStage >= requiredDuration && newHealth >= profile.healthThresholds[seed.currentStage + 1]) {
                newStage = GrowthStage(uint8(seed.currentStage) + 1);
            }
        } else if (seed.currentStage == GrowthStage.Mature) {
             // Mature seeds can be harvested or potentially decay if conditions worsen significantly
             // Decay logic can be triggered if health/vigor drops too low *after* reaching mature
             int256 decayThresholdHealth = _growthParameters[bytes32("decayThresholdHealth")]; // e.g., 20
             if (newHealth < decayThresholdHealth) {
                 newStage = GrowthStage.Decayed;
             }
        }


        // --- Check for Decay (Can happen at any stage if health is critical) ---
        int256 criticalHealth = _growthParameters[bytes32("criticalHealth")]; // e.g., 10
         if (newStage != GrowthStage.Decayed && newHealth < criticalHealth) {
             newStage = GrowthStage.Decayed;
         }


        return (newStage, newHealth, newVigor);
    }

    // Apply calculated state changes to storage
    function _updateGrowthState(uint256 seedId, SeedData storage seed) internal {
        (GrowthStage potentialNewStage, int256 newHealth, int256 newVigor) = _calculateGrowthState(seedId, seed);

        seed.health = newHealth;
        seed.vigor = newVigor;
        seed.lastEnvironmentCheckTime = block.timestamp; // Update the general check time

        if (potentialNewStage != seed.currentStage) {
            GrowthStage oldStage = seed.currentStage;
            seed.currentStage = potentialNewStage;
            string memory reason = "TimeAndConditions"; // More complex reasons could be passed

            if (potentialNewStage == GrowthStage.Decayed) seed.decayed = true;
            if (potentialNewStage == GrowthStage.Harvested) seed.harvested = true; // Should only happen via harvest function

            emit SeedStageChanged(seedId, oldStage, potentialNewStage, reason);
        }
    }

    // 8. Constructor
    constructor() {
        i_owner = msg.sender;
        _tokenIdCounter = 0; // Token IDs start from 1

        // Set some default growth parameters
        _growthParameters[bytes32("minHealth")] = 0;
        _growthParameters[bytes32("maxHealth")] = 100;
        _growthParameters[bytes32("minVigor")] = 0;
        _growthParameters[bytes32("maxVigor")] = 100;
        _growthParameters[bytes32("nurtureCooldown")] = 4 hours; // Default cooldowns
        _growthParameters[bytes32("pruneCooldown")] = 6 hours;
        _growthParameters[bytes32("environmentCooldown")] = 1 hours;
        _growthParameters[bytes32("criticalHealth")] = 10; // Health below this -> decay
        _growthParameters[bytes32("decayThresholdHealth")] = 20; // Health below this -> decay (mature)
        _growthParameters[bytes32("envDecayFactor")] = 1; // How much environment affects decay
        _growthParameters[bytes32("crossPollinateCooldown")] = 24 hours; // Cooldown for cross-pollination

        // Set some default seed type profiles (Owner can override/add later)
        // Basic Seed
        GrowthProfile memory basicProfile;
        basicProfile.name = "Basic Seed";
        basicProfile.minPlantTime = 1 days; // Needs 1 day planted to sprout
        basicProfile.nurtureCooldown = 4 hours;
        basicProfile.pruneCooldown = 6 hours;
        basicProfile.environmentCooldown = 1 hours;
        basicProfile.nurtureHealthBoost = 15;
        basicProfile.nurtureVigorBoost = 10;
        basicProfile.pruneHealthEffect = 5; // Small health boost
        basicProfile.pruneVigorEffect = 15; // Good vigor boost
        basicProfile.healthDecayRate = 1; // Decay 1 health per day if no interaction
        basicProfile.vigorDecayRate = 1; // Decay 1 vigor per day
        basicProfile.stageDuration[GrowthStage.Sprout] = 3 days; // Sprout needs 3 days to become Sapling
        basicProfile.stageDuration[GrowthStage.Sapling] = 5 days; // Sapling needs 5 days to become Mature
        basicProfile.stageDuration[GrowthStage.Mature] = 0; // Mature has no time limit for stage advancement (but can decay)
        basicProfile.healthThresholds[GrowthStage.Sprout] = 30; // Need 30 health to sprout
        basicProfile.healthThresholds[GrowthStage.Sapling] = 50; // Need 50 health to become Sapling
        basicProfile.healthThresholds[GrowthStage.Mature] = 70; // Need 70 health to become Mature
        _seedTypeProfiles[uint8(SeedType.Basic)] = basicProfile;
        _availableSeedTypes.push(uint8(SeedType.Basic));

        // Add more seed types here... (Hardy, Fragile, etc.)

        // Set initial environment (placeholder)
        _currentEnvironment.temperature = 25;
        _currentEnvironment.humidity = 60;
        _currentEnvironment.light = 80;
        _currentEnvironment.lastUpdated = block.timestamp;
    }

    // 9. ERC-721 Core Functions (Custom Implementation)
    // Note: A full ERC721 implementation requires ERC165 supportsInterface,
    // _mint, _transfer, etc., which are implemented below using internal logic.

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint255 seedId) public view returns (address) {
        address owner = _seeds[seedId].owner;
        if (owner == address(0)) revert InvalidSeedId();
        return owner;
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint255 seedId) public {
        // Basic safety checks
        require(_isApprovedOrOwner(seedId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(seedId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, seedId);
    }

     /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint255 seedId, bytes memory data) public {
         safeTransferFrom(from, to, seedId); // Ignoring data for this implementation
    }


    /// @inheritdoc IERC721
    function approve(address to, uint255 seedId) public {
         address seedOwner = ownerOf(seedId); // Will revert if seedId is invalid
         require(msg.sender == seedOwner || isApprovedForAll(seedOwner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
         _approve(to, seedId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint255 seedId) public view returns (address) {
         if (_seeds[seedId].owner == address(0)) revert InvalidSeedId();
         return _tokenApprovals[seedId];
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) public {
         _operatorApprovals[msg.sender][operator] = approved;
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
         return _operatorApprovals[owner][operator];
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint255 seedId) public view returns (string memory) {
        // Placeholder: In a real dApp, this would return a URL pointing to metadata (JSON file)
        // describing the NFT's properties, image, etc. based on its current state.
        // Example: return string(abi.encodePacked("ipfs://your-base-uri/", Strings.toString(seedId), ".json"));
        // For this example, we just return a placeholder.
        if (_seeds[seedId].owner == address(0)) revert InvalidSeedId();
        // You would build the URI dynamically based on seed data (stage, health, vigor, type)
        return string(abi.encodePacked("https://aethelseeds.xyz/metadata/", uint256(seedId), ".json"));
    }

     /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        // ERC-721 standard interfaces: ERC721 (0x804f1371), ERC721Metadata (0x5b5e139f), ERC721Enumerable (0x780e9d63)
        // We are implementing ERC721 and a basic Metadata URI. Not full Enumerable.
        return interfaceId == type(IERC721).interfaceId || interfaceId == _INTERFACE_ID_ERC721 || interfaceId == type(IERC721Metadata).interfaceId || interfaceId == 0x01ffc9a7; // ERC165 self-support
    }


    // Internal ERC721 helpers
    function _approve(address to, uint256 seedId) internal {
        _tokenApprovals[seedId] = to;
    }

    function _transfer(address from, address to, uint256 seedId) internal {
         require(ownerOf(seedId) == from, "ERC721: transfer of token that is not own"); // Double check owner
         require(to != address(0), "ERC721: transfer to the zero address");

         _beforeTokenTransfer(from, to, seedId);

        _balances[from]--;
        _balances[to]++;
        _seeds[seedId].owner = to;

        // Clear approvals on transfer
        _approve(address(0), seedId);

        _afterTokenTransfer(from, to, seedId);
    }

    // Hooks for custom logic before/after transfer (e.g., pausing, tracking)
    function _beforeTokenTransfer(address from, address to, uint256 seedId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 seedId) internal virtual {}


    // 10. Seed Management Functions

    /// @notice Mints a new AethelSeed NFT.
    /// @param seedType The type of seed to mint (references a GrowthProfile).
    function mintSeed(uint8 seedType) public {
        if (_seedTypeProfiles[seedType].minPlantTime == 0 && seedType != uint8(SeedType.Basic)) { // Basic check if type exists
             revert InvalidSeedType();
        }

        _tokenIdCounter++;
        uint256 newItemId = _tokenIdCounter;
        address receiver = msg.sender;

        _seeds[newItemId] = SeedData({
            seedId: newItemId,
            seedTypeId: seedType,
            owner: receiver,
            approved: address(0),
            mintTime: block.timestamp,
            plantedTime: 0, // Not planted yet
            lastNurtureTime: 0,
            lastPruneTime: 0,
            lastEnvironmentCheckTime: block.timestamp, // Initialize check time
            health: 50, // Initial health
            vigor: 50, // Initial vigor
            currentStage: GrowthStage.Seed,
            harvested: false,
            decayed: false,
            cultivationRewardClaimed: false
        });

        _balances[receiver]++;

        emit SeedMinted(newItemId, seedType, receiver);
    }

     /// @notice Marks a seed as planted, starting its growth timer.
    /// @param seedId The ID of the seed to plant.
    function plantSeed(uint256 seedId) public {
        SeedData storage seed = _seeds[seedId];
        if (seed.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId)) revert NotOwnerOrApproved();
        if (seed.plantedTime != 0) revert SeedNotReadyForAction("already planted");

        seed.plantedTime = block.timestamp;
        // Initial growth state check after planting
        _updateGrowthState(seedId, seed);

        emit SeedPlanted(seedId, msg.sender, seed.plantedTime);
    }


    // 11. Cultivation/Interaction Functions

    /// @notice Nurtures a seed, boosting health and vigor. Has a cooldown.
    /// @param seedId The ID of the seed to nurture.
    function nurtureSeed(uint256 seedId) public {
        SeedData storage seed = _seeds[seedId];
         if (seed.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId)) revert NotOwnerOrApproved();
        if (seed.plantedTime == 0) revert SeedNotPlanted();
        if (seed.currentStage >= GrowthStage.Decayed) revert SeedNotInCorrectStage(seed.currentStage); // Cannot nurture decayed/harvested

        GrowthProfile storage profile = _seedTypeProfiles[seed.seedTypeId];
        uint256 nurtureCooldown = profile.nurtureCooldown > 0 ? profile.nurtureCooldown : uint256(_growthParameters[bytes32("nurtureCooldown")]);
        if (block.timestamp < seed.lastNurtureTime + nurtureCooldown) {
             revert SeedNotReadyForAction("nurture cooldown");
        }

        // Apply boosts (within max limits)
        int256 healthBoost = profile.nurtureHealthBoost;
        int256 vigorBoost = profile.nurtureVigorBoost;
        int256 maxHealth = _growthParameters[bytes32("maxHealth")];
        int256 maxVigor = _growthParameters[bytes32("maxVigor")];

        seed.health = seed.health + healthBoost > maxHealth ? maxHealth : seed.health + healthBoost;
        seed.vigor = seed.vigor + vigorBoost > maxVigor ? maxVigor : seed.vigor + vigorBoost;
        seed.lastNurtureTime = block.timestamp;

         // Update growth state after action
        _updateGrowthState(seedId, seed);

        emit SeedNurtured(seedId, msg.sender, uint256(healthBoost), uint256(vigorBoost));
    }

     /// @notice Prunes a seed, influencing vigor and health. Has a cooldown.
    /// @param seedId The ID of the seed to prune.
    function pruneSeed(uint256 seedId) public {
         SeedData storage seed = _seeds[seedId];
         if (seed.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId)) revert NotOwnerOrApproved();
         if (seed.plantedTime == 0) revert SeedNotPlanted();
        if (seed.currentStage >= GrowthStage.Decayed) revert SeedNotInCorrectStage(seed.currentStage);

        GrowthProfile storage profile = _seedTypeProfiles[seed.seedTypeId];
        uint256 pruneCooldown = profile.pruneCooldown > 0 ? profile.pruneCooldown : uint256(_growthParameters[bytes32("pruneCooldown")]);
        if (block.timestamp < seed.lastPruneTime + pruneCooldown) {
             revert SeedNotReadyForAction("prune cooldown");
        }

         // Apply effects (within min/max limits)
        int256 healthEffect = profile.pruneHealthEffect;
        int256 vigorEffect = profile.pruneVigorEffect;
        int256 minHealth = _growthParameters[bytes32("minHealth")];
        int256 maxHealth = _growthParameters[bytes32("maxHealth")];
         int256 minVigor = _growthParameters[bytes32("minVigor")];
        int256 maxVigor = _growthParameters[bytes32("maxVigor")];

        seed.health = seed.health + healthEffect < minHealth ? minHealth : (seed.health + healthEffect > maxHealth ? maxHealth : seed.health + healthEffect);
        seed.vigor = seed.vigor + vigorEffect < minVigor ? minVigor : (seed.vigor + vigorEffect > maxVigor ? maxVigor : seed.vigor + vigorEffect);
        seed.lastPruneTime = block.timestamp;

         // Update growth state after action
        _updateGrowthState(seedId, seed);

        emit SeedPruned(seedId, msg.sender, uint256(vigorEffect), uint256(healthEffect));
    }

     /// @notice Exposes a seed to current environmental conditions, influencing its growth calculation. Has a cooldown.
    /// @param seedId The ID of the seed.
    function exposeToEnvironment(uint256 seedId) public {
         SeedData storage seed = _seeds[seedId];
         if (seed.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId)) revert NotOwnerOrApproved();
         if (seed.plantedTime == 0) revert SeedNotPlanted();
        if (seed.currentStage >= GrowthStage.Decayed) revert SeedNotInCorrectStage(seed.currentStage);

         GrowthProfile storage profile = _seedTypeProfiles[seed.seedTypeId];
        uint256 environmentCooldown = profile.environmentCooldown > 0 ? profile.environmentCooldown : uint256(_growthParameters[bytes32("environmentCooldown")]);
        if (block.timestamp < seed.lastEnvironmentCheckTime + environmentCooldown) {
             revert SeedNotReadyForAction("environment cooldown");
        }

        // In a real scenario, this would trigger an Oracle call or use fresh data.
        // For this example, we just use the stored environmental data.
        seed.lastEnvironmentCheckTime = block.timestamp;

         // Update growth state after action
        _updateGrowthState(seedId, seed);

        emit SeedExposedToEnvironment(seedId, _currentEnvironment.temperature, _currentEnvironment.humidity, _currentEnvironment.light);
    }


    /// @notice Forces an update to the seed's growth stage based on elapsed time, actions, and environment. Can be called by anyone.
    /// @param seedId The ID of the seed to update.
    function forceGrowthUpdate(uint256 seedId) public {
        SeedData storage seed = _seeds[seedId];
         if (seed.owner == address(0)) revert InvalidSeedId();
         if (seed.plantedTime == 0) return; // Cannot update unplanted seeds
        if (seed.currentStage >= GrowthStage.Decayed) return; // Cannot update terminal states

        // Anyone can trigger an update to help seeds progress (or decay)
        _updateGrowthState(seedId, seed);
    }


    // 12. Advanced Cultivation Functions

     /// @notice Attempts to cross-pollinate two compatible seeds, potentially boosting their vigor or health.
    /// @param seedId1 The ID of the first seed.
    /// @param seedId2 The ID of the second seed.
    function crossPollinate(uint256 seedId1, uint256 seedId2) public {
         if (seedId1 == seedId2) revert BothSeedsMustBeDifferent();

        SeedData storage seed1 = _seeds[seedId1];
         if (seed1.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId1)) revert NotOwnerOrApproved();

        SeedData storage seed2 = _seeds[seedId2];
         if (seed2.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId2)) revert NotOwnerOrApproved();

         if (seed1.plantedTime == 0 || seed2.plantedTime == 0) revert SeedNotPlanted();
        if (seed1.currentStage < GrowthStage.Sapling || seed2.currentStage < GrowthStage.Sapling) revert SeedNotInCorrectStage(GrowthStage.Sapling); // Example: Requires at least Sapling
         if (seed1.currentStage >= GrowthStage.Decayed || seed2.currentStage >= GrowthStage.Decayed) revert SeedNotInCorrectStage(seed1.currentStage); // Cannot pollinate decayed/harvested

         uint256 crossPollinateCooldown = uint256(_growthParameters[bytes32("crossPollinateCooldown")]);
        if (block.timestamp < seed1.lastNurtureTime + crossPollinateCooldown || block.timestamp < seed2.lastNurtureTime + crossPollinateCooldown) {
             revert SeedNotReadyForAction("cross-pollination cooldown"); // Using nurture time for cooldown example
        }

        // --- Cross-Pollination Logic (Placeholder) ---
        // This is where complex compatibility or trait-mixing logic would go.
        // For this example, we just check if seed types are "compatible" (e.g., basic with basic)
        if (seed1.seedTypeId != seed2.seedTypeId) {
             // More complex logic needed for cross-type compatibility
             revert SeedsNotCompatibleForCrossPollination();
        }

        // Example Effect: Significant vigor boost for both
        int256 crossPollinateVigorBoost = 25; // Example value
        int256 maxVigor = _growthParameters[bytes32("maxVigor")];

        seed1.vigor = seed1.vigor + crossPollinateVigorBoost > maxVigor ? maxVigor : seed1.vigor + crossPollinateVigorBoost;
        seed2.vigor = seed2.vigor + crossPollinateVigorBoost > maxVigor ? maxVigor : seed2.vigor + crossPollinateVigorBoost;

        // Update timestamps (optional, maybe use a dedicated lastPollinateTime)
        seed1.lastNurtureTime = block.timestamp; // Using nurture time as placeholder
        seed2.lastNurtureTime = block.timestamp; // Using nurture time as placeholder

        // Update growth states
         _updateGrowthState(seedId1, seed1);
         _updateGrowthState(seedId2, seed2);


        emit SeedCrossPollinated(seedId1, seedId2, msg.sender);
    }

    /// @notice Transitions a Mature seed to the Harvested stage.
    /// @param seedId The ID of the seed to harvest.
    function harvestManifestation(uint256 seedId) public {
        SeedData storage seed = _seeds[seedId];
         if (seed.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId)) revert NotOwnerOrApproved();
        if (seed.currentStage != GrowthStage.Mature) revert SeedNotInCorrectStage(GrowthStage.Mature);
        if (seed.harvested) revert SeedNotReadyForAction("already harvested");

        seed.currentStage = GrowthStage.Harvested;
        seed.harvested = true;
        // Potentially record data needed for reward calculation

        emit SeedHarvested(seedId, msg.sender);
        emit SeedStageChanged(seedId, GrowthStage.Mature, GrowthStage.Harvested, "Harvested");
    }


     /// @notice Allows the cultivator to claim rewards for a successfully harvested seed.
    /// @param seedId The ID of the seed.
    function claimCultivationReward(uint256 seedId) public {
         SeedData storage seed = _seeds[seedId];
         if (seed.owner == address(0)) revert InvalidSeedId();
        if (!_isApprovedOrOwner(seedId)) revert NotOwnerOrApproved(); // Owner or approved cultivator can claim
        if (seed.currentStage != GrowthStage.Harvested) revert SeedNotInCorrectStage(GrowthStage.Harvested);
        if (seed.cultivationRewardClaimed) revert NoRewardsAvailable();

        // --- Reward Logic (Placeholder) ---
        // This is where you'd calculate a reward amount based on seed stats, type, etc.
        // For this example, we'll just set a flag and emit an event.
        uint256 rewardAmount = 0; // Placeholder amount (could be ETH, ERC-20, etc.)
        // Example: if seed.health > 80, rewardAmount = 0.1 ether;

        // Reward goes to the approved cultivator if one exists and is different from owner
        address rewardRecipient = msg.sender; // Default to sender (who must be owner or approved)
        // More complex logic could check who did most cultivation actions etc.

        seed.cultivationRewardClaimed = true;

        // In a real contract with rewards, you would transfer tokens or ETH here.
        // Example: payable(rewardRecipient).transfer(rewardAmount); // If rewarding ETH
        // Example: IERC20(rewardTokenAddress).transfer(rewardRecipient, rewardAmount); // If rewarding ERC-20

        emit CultivationRewardClaimed(seedId, rewardRecipient, rewardAmount);
    }


    // 14. Configuration (Owner Only) Functions

    /// @notice Owner-only: Defines or updates a GrowthProfile for a seed type.
    /// @param seedType The identifier for the seed type.
    /// @param profile The GrowthProfile struct containing parameters.
    function addSeedTypeProfile(uint8 seedType, GrowthProfile memory profile) public onlyOwner {
        bool isNewType = (_seedTypeProfiles[seedType].minPlantTime == 0);
        _seedTypeProfiles[seedType] = profile;
        if (isNewType) {
             _availableSeedTypes.push(seedType);
        }
        emit SeedTypeProfileAdded(seedType, profile);
    }

    /// @notice Owner-only: Sets a global growth parameter.
    /// @param paramName The name of the parameter (e.g., "minHealth", "nurtureCooldown").
    /// @param value The value to set.
    function setGrowthParameter(bytes32 paramName, int256 value) public onlyOwner {
         // Basic validation for known parameters could be added here
        _growthParameters[paramName] = value;
        emit GrowthParameterSet(paramName, value);
    }

     /// @notice Owner-only or Oracle-called: Sets the current environmental conditions.
    /// @param temp Temperature value.
    /// @param humidity Humidity value.
    /// @param light Light value.
    function setEnvironmentalConditions(int256 temp, int256 humidity, int256 light) public {
         // In a real Oracle integration, this function might be called by the Oracle contract itself
         // using require(msg.sender == _oracleAddress, "Not Oracle");
        if (msg.sender != i_owner && msg.sender != _oracleAddress) revert NotOwnerOrApproved(); // Allow owner or oracle to call

        _currentEnvironment = EnvironmentalConditions({
            temperature: temp,
            humidity: humidity,
            light: light,
            lastUpdated: block.timestamp
        });
        emit EnvironmentalConditionsSet(temp, humidity, light);
    }

     /// @notice Owner-only: Sets the address of the trusted Oracle contract.
    /// @param oracle The address of the Oracle contract.
    function setOracleAddress(address oracle) public onlyOwner {
         _oracleAddress = oracle;
        emit OracleAddressSet(oracle);
    }

     /// @notice Owner-only: Withdraws any ETH held by the contract.
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(i_owner).call{value: balance}("");
            if (!success) revert WithdrawFailed();
        }
    }

    // 15. View/Query Functions

    /// @notice Gets all data for a specific seed.
    /// @param seedId The ID of the seed.
    /// @return The SeedData struct.
    function getSeedData(uint256 seedId) public view returns (SeedData memory) {
        if (_seeds[seedId].owner == address(0)) revert InvalidSeedId();
        return _seeds[seedId];
    }

    /// @notice Gets the current global growth parameters.
    /// @return A tuple of parameter names and values.
    // Note: Returning a mapping is not possible. Returning a fixed set or requiring paramName lookup.
    // Let's return the most common ones.
    function getGrowthParameters()
        public
        view
        returns (
            int256 minHealth, int256 maxHealth, int256 minVigor, int256 maxVigor,
            uint256 nurtureCooldown, uint256 pruneCooldown, uint256 environmentCooldown,
            int256 criticalHealth, int256 decayThresholdHealth, int256 envDecayFactor, uint256 crossPollinateCooldown
        )
    {
        minHealth = _growthParameters[bytes32("minHealth")];
        maxHealth = _growthParameters[bytes32("maxHealth")];
        minVigor = _growthParameters[bytes32("minVigor")];
        maxVigor = _growthParameters[bytes32("maxVigor")];
        nurtureCooldown = uint256(_growthParameters[bytes32("nurtureCooldown")]);
        pruneCooldown = uint256(_growthParameters[bytes32("pruneCooldown")]);
        environmentCooldown = uint256(_growthParameters[bytes32("environmentCooldown")]);
        criticalHealth = _growthParameters[bytes32("criticalHealth")];
        decayThresholdHealth = _growthParameters[bytes32("decayThresholdHealth")];
        envDecayFactor = _growthParameters[bytes32("envDecayFactor")];
        crossPollinateCooldown = uint256(_growthParameters[bytes32("crossPollinateCooldown")]);

        return (
            minHealth, maxHealth, minVigor, maxVigor,
            nurtureCooldown, pruneCooldown, environmentCooldown,
            criticalHealth, decayThresholdHealth, envDecayFactor, crossPollinateCooldown
        );
    }

     /// @notice Gets the current environmental conditions.
    function getEnvironmentalConditions() public view returns (EnvironmentalConditions memory) {
        return _currentEnvironment;
    }

     /// @notice Gets the growth profile for a specific seed type.
    /// @param seedType The identifier for the seed type.
    /// @return The GrowthProfile struct.
    function getSeedTypeProfile(uint8 seedType) public view returns (GrowthProfile memory) {
        if (_seedTypeProfiles[seedType].minPlantTime == 0 && seedType != uint8(SeedType.Basic)) revert InvalidSeedType(); // Basic check
        return _seedTypeProfiles[seedType];
    }

     /// @notice Gets the current growth stage of a seed.
    /// @param seedId The ID of the seed.
    /// @return The current GrowthStage.
    function getGrowthStage(uint256 seedId) public view returns (GrowthStage) {
         if (_seeds[seedId].owner == address(0)) revert InvalidSeedId();
         return _seeds[seedId].currentStage;
    }

     /// @notice Calculates time elapsed since the last nurture action for a seed.
    /// @param seedId The ID of the seed.
    /// @return Time in seconds. Returns 0 if never nurtured or not planted.
    function timeSinceLastNurture(uint256 seedId) public view returns (uint256) {
        SeedData storage seed = _seeds[seedId];
        if (seed.plantedTime == 0 || seed.lastNurtureTime == 0) return 0;
        return block.timestamp - seed.lastNurtureTime;
    }

     /// @notice Calculates the potential next stage for a seed based on current state and time, without modifying state.
    /// @param seedId The ID of the seed.
    /// @return The potential next GrowthStage.
    function getPotentialNextStage(uint256 seedId) public view returns (GrowthStage) {
         SeedData storage seed = _seeds[seedId];
         if (seed.owner == address(0)) revert InvalidSeedId(); // Needs to exist
         if (seed.plantedTime == 0) return seed.currentStage; // Unplanted doesn't grow

        (GrowthStage potentialNext, , ) = _calculateGrowthState(seedId, seed);
        return potentialNext;
    }

     /// @notice Placeholder function to get a user's cultivation score.
    /// @param user The address of the user.
    /// @return The cultivation score.
    function getUserCultivationScore(address user) public view returns (uint256) {
         // In a real implementation, this would track successes, failures, etc.
         return _cultivationScores[user]; // Currently just returns 0
    }

    /// @notice Gets the total number of seeds that have been minted.
    /// @return The total count of seeds.
    function totalSeedsMinted() public view returns (uint256) {
        return _tokenIdCounter;
    }


     // Needed to satisfy ERC721 interface requirements (even with custom impl)
    interface IERC721 {
        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

        function balanceOf(address owner) external view returns (uint256 balance);
        function ownerOf(uint256 tokenId) external view returns (address owner);
        function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
        function safeTransferFrom(address from, address to, uint256 tokenId) external;
        function transferFrom(address from, address to, uint256 tokenId) external; // Not implemented for safety
        function approve(address to, uint256 tokenId) external;
        function getApproved(uint256 tokenId) external view returns (address operator);
        function setApprovalForAll(address operator, bool _approved) external;
        function isApprovedForAll(address owner, address operator) external view returns (bool);
    }

    interface IERC721Metadata {
        function name() external view returns (string memory); // Not implemented in contract
        function symbol() external view returns (string memory); // Not implemented in contract
        function tokenURI(uint256 tokenId) external view returns (string memory);
    }

     interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }
}
```