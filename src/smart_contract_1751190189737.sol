Okay, here is a Solidity smart contract implementing an "Evolving Digital Entities" concept. This contract represents NFTs (ERC721) that have dynamic states and traits influenced by time, direct interaction from their owners, and global "environmental" parameters managed by the contract owner. It incorporates concepts like time-based state changes, parameterized evolution, probabilistic mutation, and a form of on-chain simulation/prediction.

This design avoids directly duplicating standard ERC20/ERC721 implementations beyond inheriting the basic NFT standard (using OpenZeppelin for best practice, but the core logic is custom). The novelty lies in the state management, interaction effects, and evolution mechanics.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- CONTRACT OUTLINE ---
// 1. Contract Name: ChronoSeedEntities
// 2. Description: An ERC721 contract for NFTs representing digital entities (seeds) that evolve
//    over time and through interactions. Their state is dynamic based on internal levels,
//    global environment parameters, and time elapsed.
// 3. Core Concepts: Dynamic NFTs, Time-Based State Changes, On-Chain Simulation (limited),
//    Parameterized Evolution, Probabilistic Mutation, Global Environmental Influence.
// 4. Structure:
//    - State Variables: Global environment, rates, thresholds, entity data structure, token counter.
//    - Events: Key lifecycle and state change notifications.
//    - Modifiers: Access control and validation.
//    - Entity Struct: Defines the dynamic state of each NFT.
//    - Core Logic:
//      - Minting new entities.
//      - Owner/Approved interaction functions (nourish, water, etc.).
//      - Owner-only functions (set environment, rates, thresholds).
//      - Time/Interaction triggered internal evolution/decay/mutation logic.
//      - External trigger functions for evolution cycles.
//      - Harvesting/Burning entities.
//      - Query functions for state and environment.
//      - Simulation/Prediction function.

// --- FUNCTION SUMMARY ---
// 1. constructor(): Initializes the contract, sets initial global environment, and mints the first seed (optional initial supply).
// 2. supportsInterface(bytes4 interfaceId): Standard ERC165 for ERC721/Enumerable.
// 3. tokenURI(uint256 tokenId): Returns the URI for the entity's metadata. Can be dynamic based on state.
// 4. mintNewSeed(): Mints a new ChronoSeed NFT, assigns base state, available to owner or anyone with a fee (example).
// 5. nourishEntity(uint256 tokenId): Increases nourishment level for a specific entity. Requires ownership/approval.
// 6. waterEntity(uint256 tokenId): Increases hydration level for a specific entity. Requires ownership/approval.
// 7. exposeToLight(uint256 tokenId): Increases light exposure level for a specific entity. Requires ownership/approval.
// 8. applyCatalyst(uint256 tokenId, uint8 catalystType): Applies a specific catalyst effect (e.g., boost multiple stats). Requires ownership/approval.
// 9. checkAndEvolveEntity(uint256 tokenId): External trigger to check and potentially evolve a specific entity based on its state and time. Anyone can call (pays gas).
// 10. checkAndDecayEntity(uint256 tokenId): External trigger to check and potentially decay a specific entity's levels due to neglect or environment. Anyone can call (pays gas).
// 11. checkAndMutateEntity(uint256 tokenId): External trigger to check for probabilistic mutation. Anyone can call (pays gas).
// 12. triggerGlobalEvolutionCycle(): External trigger to check and potentially evolve/decay/mutate *all* entities. Anyone can call (pays gas), expensive with many tokens.
// 13. harvestEntity(uint256 tokenId): Marks an entity as harvested and potentially burns it, recording yield. Requires ownership/approval and specific evolution stage.
// 14. burnStuntedEntity(uint256 tokenId): Allows burning an entity that has decayed beyond recovery. Requires ownership/approval and decay state condition.
// 15. setEnvironmentTemp(int16 newTemp): Owner-only function to set the global environment temperature.
// 16. setLightIntensity(uint16 newIntensity): Owner-only function to set the global light intensity.
// 17. adjustGlobalTimeRate(uint16 newRate): Owner-only function to adjust how much contract time passes per block time (e.g., speed up/slow down evolution).
// 18. setEvolutionThresholds(uint8 stage, uint16 neededNourish, uint16 neededHydration, uint16 neededLight, uint64 timeToNextStage): Owner-only function to configure the requirements for evolving between stages.
// 19. setMutationRate(uint16 newRatePermyriad): Owner-only function to set the probability of mutation (per 10,000).
// 20. setDecayRate(uint16 newRatePerUnitTime): Owner-only function to set how quickly levels decay over time.
// 21. getEntityState(uint256 tokenId): View function returning the current dynamic state of an entity.
// 22. getEntityTraits(uint256 tokenId): View function returning derived traits or properties based on state (e.g., "Hardy", "Sun-Lover").
// 23. getGlobalEnvironment(): View function returning current global environment parameters.
// 24. getEvoScore(uint256 tokenId): View function calculating a dynamic "evolution score" based on state and age.
// 25. predictEvolutionOutcome(uint256 tokenId, uint64 timeDelta): View function attempting to predict potential state changes after a given time delta under current conditions. (Simplified).
// 26. setBaseMetadataURI(string memory uri): Owner-only function to update the base URI for metadata.
// 27. getEntityBirthTime(uint256 tokenId): View function returning the entity's birth timestamp.
// 28. getEntityLastInteractionTime(uint256 tokenId): View function returning the last interaction timestamp.
// 29. getTotalHarvestedYield(): View function returning the cumulative yield from all harvested entities. (Requires yield tracking).
// 30. getHarvestedYieldForEntity(uint256 tokenId): View function returning the recorded yield for a specific harvested entity. (Requires yield tracking per entity).

contract ChronoSeedEntities is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- State Variables ---

    // Global Environment Parameters
    int16 public environmentTemp = 25; // Celsius
    uint16 public lightIntensity = 500; // Lux-like unit
    uint16 public globalTimeRate = 1; // How many 'contract time' units pass per block second

    // Rates and Thresholds
    uint16 public mutationRatePermyriad = 5; // 5 in 10,000 chance per check cycle
    uint16 public decayRatePerUnitTime = 1; // How much a level decays per unit of contract time without interaction

    // Struct defining the dynamic state of an entity
    struct Entity {
        uint64 birthTime; // Block timestamp when minted
        uint64 lastInteractionTime; // Timestamp of the last successful interaction (nourish, water, light, catalyst)
        uint64 lastEvolutionCheckTime; // Timestamp of the last time evolution was checked

        uint16 nourishmentLevel;
        uint16 hydrationLevel;
        uint16 lightExposureLevel;

        uint8 evolutionStage; // 0: Seed, 1: Sprout, 2: Juvenile, 3: Mature, 4: Elder (example stages)
        uint16 generation; // Starts at 1, increases upon harvest/replanting (if implemented)

        uint8 mutations; // Count of beneficial/neutral mutations
        bool isStunted; // Flag if entity health levels are critically low
        bool isHarvested; // Flag if entity has been harvested

        // Store yield upon harvest
        uint256 harvestedYield;
    }

    // Mapping from token ID to entity state
    mapping(uint256 => Entity) private _entities;

    // Evolution thresholds and requirements per stage
    struct EvolutionThresholds {
        uint16 neededNourish;
        uint16 neededHydration;
        uint16 neededLight;
        uint64 timeToNextStage; // Minimum time since birth or last stage change
    }

    // Mapping from current stage to requirements for next stage
    // stage 0 -> requires for stage 1, stage 1 -> requires for stage 2, etc.
    mapping(uint8 => EvolutionThresholds) public evolutionStageRequirements;

    // Base URI for metadata
    string private _baseMetadataURI = "";

    // Cumulative yield from all harvested entities
    uint256 public totalHarvestedYield = 0;

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, uint64 birthTime);
    event EntityStateUpdated(uint256 indexed tokenId, string stateChangeType, int16 amount, uint64 updatedTime);
    event EntityEvolved(uint256 indexed tokenId, uint8 newStage, uint64 evolutionTime);
    event EntityDecayed(uint256 indexed tokenId, string levelType, uint16 newLevel, uint64 decayTime);
    event EntityMutated(uint256 indexed tokenId, uint8 currentMutationCount, uint64 mutationTime);
    event EntityHarvested(uint256 indexed tokenId, address indexed owner, uint256 yieldAmount, uint64 harvestTime);
    event EntityBurned(uint256 indexed tokenId, address indexed owner, string reason, uint64 burnTime);
    event GlobalEnvironmentUpdated(string param, int16 valueInt, uint16 valueUint);
    event EvolutionThresholdsUpdated(uint8 stage, uint16 neededNourish, uint16 neededHydration, uint16 neededLight, uint64 timeToNextStage);
    event RateUpdated(string rateType, uint16 value);

    // --- Modifiers ---
    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not token owner or approved");
        _;
    }

    modifier entityExists(uint256 tokenId) {
        require(_exists(tokenId), "Entity does not exist");
        _;
    }

    modifier entityNotHarvested(uint256 tokenId) {
        require(!_entities[tokenId].isHarvested, "Entity is already harvested");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Set initial evolution requirements (example values)
        evolutionStageRequirements[0] = EvolutionThresholds({ // Seed -> Sprout
            neededNourish: 50,
            neededHydration: 50,
            neededLight: 50,
            timeToNextStage: 3600 // 1 hour
        });
        evolutionStageRequirements[1] = EvolutionThresholds({ // Sprout -> Juvenile
            neededNourish: 100,
            neededHydration: 100,
            neededLight: 100,
            timeToNextStage: 86400 // 1 day
        });
        evolutionStageRequirements[2] = EvolutionThresholds({ // Juvenile -> Mature
            neededNourish: 150,
            neededHydration: 150,
            neededLight: 150,
            timeToNextStage: 604800 // 1 week
        });
        // Mature (stage 3) and beyond might not have explicit evolution requirements,
        // or evolve based on different factors (e.g., age, mutations).

        // Optional: Mint a few initial seeds
        // _mintNewSeed(msg.sender);
        // _mintNewSeed(msg.sender);
    }

    // --- Core ERC721 Overrides ---
    // The basic ERC721/Enumerable/Ownable functions are inherited.
    // We only override what's necessary or adds custom logic.

    function tokenURI(uint256 tokenId) public view override entityExists(tokenId) returns (string memory) {
        require(!_entities[tokenId].isHarvested, "Harvested entities have no active URI");
        // This is where you'd generate a dynamic URI pointing to JSON metadata.
        // The metadata API should read the on-chain state of the entity (using getEntityState)
        // and generate attributes/image based on nourishment, stage, mutations, etc.
        string memory base = _baseMetadataURI;
        if (bytes(base).length == 0) {
            return ""; // Or a default placeholder URI
        }
        return string(abi.encodePacked(base, _toString(tokenId)));
    }

    // --- Custom Functions ---

    /// @notice Mints a new ChronoSeed NFT.
    /// @dev Can be restricted or require payment/conditions. Basic version: Owner can mint.
    function mintNewSeed() public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        uint64 currentTime = uint64(block.timestamp);

        _entities[newItemId] = Entity({
            birthTime: currentTime,
            lastInteractionTime: currentTime,
            lastEvolutionCheckTime: currentTime,
            nourishmentLevel: 10, // Starting levels
            hydrationLevel: 10,
            lightExposureLevel: 10,
            evolutionStage: 0, // Start at Seed stage
            generation: 1,
            mutations: 0,
            isStunted: false,
            isHarvested: false,
            harvestedYield: 0
        });

        _safeMint(msg.sender, newItemId);

        emit EntityMinted(newItemId, msg.sender, currentTime);
        return newItemId;
    }

    /// @notice Increases the nourishment level of an entity.
    function nourishEntity(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) entityNotHarvested(tokenId) {
        Entity storage entity = _entities[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        // Prevent excessive spamming? Or just cap levels.
        // Cap at 255 for uint16 to avoid overflow issues if levels could go higher,
        // but let's cap at a reasonable value like 200 for game balance.
        entity.nourishmentLevel = uint16(Math.min(entity.nourishmentLevel + 20, 200));
        entity.lastInteractionTime = currentTime;

        emit EntityStateUpdated(tokenId, "Nourishment", 20, currentTime);
    }

    /// @notice Increases the hydration level of an entity.
    function waterEntity(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) entityNotHarvested(tokenId) {
        Entity storage entity = _entities[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        entity.hydrationLevel = uint16(Math.min(entity.hydrationLevel + 25, 200));
        entity.lastInteractionTime = currentTime;

        emit EntityStateUpdated(tokenId, "Hydration", 25, currentTime);
    }

    /// @notice Increases the light exposure level of an entity.
    function exposeToLight(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) entityNotHarvested(tokenId) {
        Entity storage entity = _entities[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        entity.lightExposureLevel = uint16(Math.min(entity.lightExposureLevel + 15, 200));
        entity.lastInteractionTime = currentTime;

        emit EntityStateUpdated(tokenId, "Light Exposure", 15, currentTime);
    }

    /// @notice Applies a catalyst effect to an entity. Example: boosts multiple stats slightly.
    function applyCatalyst(uint256 tokenId, uint8 catalystType) public onlyTokenOwnerOrApproved(tokenId) entityNotHarvested(tokenId) {
        Entity storage entity = _entities[tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Example catalyst types
        if (catalystType == 1) { // Basic Growth Catalyst
            entity.nourishmentLevel = uint16(Math.min(entity.nourishmentLevel + 10, 200));
            entity.hydrationLevel = uint16(Math.min(entity.hydrationLevel + 10, 200));
            entity.lightExposureLevel = uint16(Math.min(entity.lightExposureLevel + 10, 200));
            // Maybe trigger an immediate check for evolution/mutation?
             _checkAndEvolveEntity(tokenId, currentTime); // Internal call
             _checkAndMutateEntity(tokenId, currentTime); // Internal call
        }
        // Add more catalyst types here...

        entity.lastInteractionTime = currentTime;
        emit EntityStateUpdated(tokenId, string(abi.encodePacked("Catalyst ", _toString(catalystType))), 0, currentTime); // Amount 0 as it's multi-stat
    }

    /// @notice External trigger to check for evolution and decay for a specific entity.
    /// Anyone can call this, but the caller pays the gas.
    function checkAndEvolveEntity(uint256 tokenId) public entityExists(tokenId) entityNotHarvested(tokenId) {
        uint64 currentTime = uint64(block.timestamp);
        _checkAndDecayEntity(tokenId, currentTime); // Always check decay before evolution
        _checkAndEvolveEntity(tokenId, currentTime);
        _checkAndMutateEntity(tokenId, currentTime); // Check mutation after potential evolution
    }

    /// @notice External trigger to run evolution/decay/mutation checks for ALL active entities.
    /// Can be very gas-intensive if there are many tokens. Anyone can call (pays gas).
    function triggerGlobalEvolutionCycle() public {
        uint64 currentTime = uint64(block.timestamp);
        uint256 totalTokens = totalSupply();
        for (uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = tokenByIndex(i); // Requires ERC721Enumerable
            // Check if entity exists and is not harvested
            if (_exists(tokenId) && !_entities[tokenId].isHarvested) {
                 _checkAndDecayEntity(tokenId, currentTime);
                 _checkAndEvolveEntity(tokenId, currentTime);
                 _checkAndMutateEntity(tokenId, currentTime);
            }
        }
        // No explicit event for the global cycle itself, rely on individual entity events.
    }

    /// @notice Marks an entity as harvested, recording yield and potentially burning the token.
    /// Requires the entity to be at a mature stage or higher.
    function harvestEntity(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) entityNotHarvested(tokenId) {
        Entity storage entity = _entities[tokenId];
        require(entity.evolutionStage >= 3, "Entity is not mature enough to harvest"); // Example: Must be stage 3 (Mature) or higher

        uint64 currentTime = uint64(block.timestamp);
        entity.isHarvested = true;

        // Calculate yield based on final state (example calculation)
        uint256 yieldAmount = (uint256(entity.nourishmentLevel) + uint256(entity.hydrationLevel) + uint256(entity.lightExposureLevel)) * entity.evolutionStage / (10 - entity.mutations);
        if (entity.isStunted) { // Stunted entities yield less
            yieldAmount = yieldAmount / 2;
        }
        yieldAmount = Math.min(yieldAmount, 1000); // Cap yield for game balance
        entity.harvestedYield = yieldAmount;
        totalHarvestedYield += yieldAmount; // Update global yield

        // Option 1: Burn the token after harvest
        _burn(tokenId);
        emit EntityBurned(tokenId, msg.sender, "Harvested", currentTime);

        // Option 2: Don't burn, just mark as harvested (if harvested NFTs still have value/history)
        // _entities[tokenId].isHarvested = true; // Already set above
        // require(_ownerOf[tokenId] == msg.sender, "Harvested entity must be owned by caller to record yield"); // Or require approval
        // emit EntityHarvested(tokenId, msg.sender, yieldAmount, currentTime);


        emit EntityHarvested(tokenId, msg.sender, yieldAmount, currentTime); // Emit even if burned
    }

     /// @notice Allows burning an entity that has decayed beyond recovery (stunted).
    function burnStuntedEntity(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) entityExists(tokenId) entityNotHarvested(tokenId) {
        Entity storage entity = _entities[tokenId];
        require(entity.isStunted, "Entity is not in a stunted state");
        require(entity.evolutionStage < 3, "Cannot burn mature/elder stunted entities this way"); // Maybe different rules for higher stages

        uint64 currentTime = uint64(block.timestamp);

        // No yield for stunted entities
        _burn(tokenId);

        emit EntityBurned(tokenId, msg.sender, "Stunted", currentTime);
    }


    // --- Owner-only Configuration Functions ---

    /// @notice Sets the global environment temperature.
    function setEnvironmentTemp(int16 newTemp) public onlyOwner {
        environmentTemp = newTemp;
        emit GlobalEnvironmentUpdated("EnvironmentTemp", newTemp, 0);
    }

    /// @notice Sets the global light intensity.
    function setLightIntensity(uint16 newIntensity) public onlyOwner {
        lightIntensity = newIntensity;
        emit GlobalEnvironmentUpdated("LightIntensity", 0, newIntensity);
    }

    /// @notice Adjusts the rate at which contract time passes relative to block time.
    /// Higher rate speeds up time-based evolution/decay.
    function adjustGlobalTimeRate(uint16 newRate) public onlyOwner {
        require(newRate > 0, "Time rate must be positive");
        globalTimeRate = newRate;
        emit RateUpdated("GlobalTimeRate", newRate);
    }

    /// @notice Sets the requirements for an entity to evolve from one stage to the next.
    /// @param stage The current evolution stage (e.g., 0 for Seed, 1 for Sprout).
    /// @param neededNourish Minimum nourishment required.
    /// @param neededHydration Minimum hydration required.
    /// @param neededLight Minimum light exposure required.
    /// @param timeToNextStage Minimum time (in contract time units) since birth or last stage change.
    function setEvolutionThresholds(uint8 stage, uint16 neededNourish, uint16 neededHydration, uint16 neededLight, uint64 timeToNextStage) public onlyOwner {
        // Basic validation, prevent setting requirements for stages beyond a reasonable limit
        require(stage < 10, "Stage number too high"); // Example limit
        evolutionStageRequirements[stage] = EvolutionThresholds({
            neededNourish: neededNourish,
            neededHydration: neededHydration,
            neededLight: neededLight,
            timeToNextStage: timeToNextStage
        });
        emit EvolutionThresholdsUpdated(stage, neededNourish, neededHydration, neededLight, timeToNextStage);
    }

    /// @notice Sets the probabilistic mutation rate (per 10,000 chance).
    function setMutationRate(uint16 newRatePermyriad) public onlyOwner {
        require(newRatePermyriad <= 10000, "Rate cannot exceed 10000 (100%)");
        mutationRatePermyriad = newRatePermyriad;
        emit RateUpdated("MutationRatePermyriad", newRatePermyriad);
    }

    /// @notice Sets the rate at which entity levels decay over time.
    function setDecayRate(uint16 newRatePerUnitTime) public onlyOwner {
        decayRatePerUnitTime = newRatePerUnitTime;
        emit RateUpdated("DecayRatePerUnitTime", newRatePerUnitTime);
    }

    /// @notice Sets the base URI for token metadata.
    function setBaseMetadataURI(string memory uri) public onlyOwner {
        _baseMetadataURI = uri;
        // No specific event for URI update needed typically.
    }

     /// @notice Allows owner to set the stunted status of an entity (e.g., for manual intervention/correction).
    /// @dev Use with caution, can override natural game state.
    function setEntityStuntedStatus(uint256 tokenId, bool status) public onlyOwner entityExists(tokenId) entityNotHarvested(tokenId) {
        Entity storage entity = _entities[tokenId];
        entity.isStunted = status;
        emit EntityStateUpdated(tokenId, "StuntedStatus", status ? 1 : 0, uint64(block.timestamp));
    }


    // --- Internal Evolution, Decay, Mutation Logic ---
    // These are typically called by the external check functions.

    /// @dev Calculates the 'contract time' elapsed since a specific timestamp.
    /// Accounts for the globalTimeRate.
    function _getContractTimeElapsed(uint64 startTime, uint64 currentTime) internal view returns (uint64) {
        if (currentTime <= startTime) return 0;
        // Be cautious with large numbers - potentially simplify or cap time delta if needed.
        // Assuming block.timestamp and globalTimeRate fit within uint64 multiplication result for a reasonable period.
        // For very long running contracts or high rates, this might need refinement (e.g., using a fixed point library).
        return (currentTime - startTime) * globalTimeRate;
    }

    /// @dev Internal function to check and apply decay to an entity's levels.
    function _checkAndDecayEntity(uint256 tokenId, uint64 currentTime) internal {
        Entity storage entity = _entities[tokenId];
        uint64 contractTimeElapsed = _getContractTimeElapsed(entity.lastEvolutionCheckTime, currentTime);

        if (contractTimeElapsed > 0) {
            uint16 decayAmount = decayRatePerUnitTime * uint16(contractTimeElapsed); // Simple linear decay

            // Apply decay, minimum level is 0
            entity.nourishmentLevel = entity.nourishmentLevel > decayAmount ? entity.nourishmentLevel - decayAmount : 0;
            entity.hydrationLevel = entity.hydrationLevel > decayAmount ? entity.hydrationLevel - decayAmount : 0;
            entity.lightExposureLevel = entity.lightExposureLevel > decayAmount ? entity.lightExposureLevel - decayAmount : 0;

            // Check for stunted status
            if (entity.evolutionStage < 3 && (entity.nourishmentLevel == 0 || entity.hydrationLevel == 0 || entity.lightExposureLevel == 0)) {
                 if (!entity.isStunted) {
                    entity.isStunted = true;
                    emit EntityStateUpdated(tokenId, "IsStunted", 1, currentTime);
                 }
            } else if (entity.isStunted && entity.nourishmentLevel > 0 && entity.hydrationLevel > 0 && entity.lightExposureLevel > 0) {
                 // Potentially remove stunted status if levels recover above zero
                 entity.isStunted = false;
                 emit EntityStateUpdated(tokenId, "IsStunted", 0, currentTime);
            }


            emit EntityDecayed(tokenId, "Levels", Math.min(decayAmount, entity.nourishmentLevel + decayAmount), currentTime); // Emit how much was attempted to decay
            entity.lastEvolutionCheckTime = currentTime; // Update check time after decay
        }
    }

    /// @dev Internal function to check and apply evolution to an entity.
    function _checkAndEvolveEntity(uint256 tokenId, uint64 currentTime) internal {
        Entity storage entity = _entities[tokenId];
        uint8 currentStage = entity.evolutionStage;
        uint8 nextStage = currentStage + 1;

        // No more evolution stages defined
        if (evolutionStageRequirements[currentStage].timeToNextStage == 0 && currentStage > 0) {
             // Assumes stage 0 has non-zero requirement if it can evolve
             // And higher stages without defined requirements don't evolve further this way
             return;
        }

        EvolutionThresholds memory req = evolutionStageRequirements[currentStage];

        // Check minimum time elapsed since birth or last stage change
        uint64 timeSinceLastEvolutionOrBirth = _getContractTimeElapsed(entity.birthTime > entity.lastEvolutionCheckTime ? entity.birthTime : entity.lastEvolutionCheckTime, currentTime);
        if (timeSinceLastEvolutionOrBirth < req.timeToNextStage) {
            return; // Not enough time has passed
        }

        // Check if all requirements are met
        bool requirementsMet = (entity.nourishmentLevel >= req.neededNourish) &&
                               (entity.hydrationLevel >= req.neededHydration) &&
                               (entity.lightExposureLevel >= req.neededLight);

        // Environmental influence (example: warmer temp helps evolution)
        bool environmentFavorable = (environmentTemp >= 20); // Simple condition

        if (requirementsMet && environmentFavorable) {
            entity.evolutionStage = nextStage;
            entity.lastEvolutionCheckTime = currentTime; // Reset evolution timer
            // Levels might reset, reduce, or be consumed upon evolution (depends on game design)
            // For now, let's just reduce them slightly as 'cost' of evolving
            entity.nourishmentLevel = uint16(Math.max(0, int16(entity.nourishmentLevel) - 20));
            entity.hydrationLevel = uint16(Math.max(0, int16(entity.hydrationLevel) - 20));
            entity.lightExposureLevel = uint16(Math.max(0, int16(entity.lightExposureLevel) - 20));

            emit EntityEvolved(tokenId, nextStage, currentTime);
        }
    }

    /// @dev Internal function to check for probabilistic mutation.
    /// Can trigger based on time, stage, environment, etc. Simple version: random chance per check.
    function _checkAndMutateEntity(uint256 tokenId, uint64 currentTime) internal {
        // Use a block property for a simple pseudo-randomness source (caution: exploitable if critical)
        // For better randomness, use Chainlink VRF or similar. This is just illustrative.
        uint256 randomness = uint256(keccak256(abi.encodePacked(tokenId, currentTime, block.number, block.difficulty, block.timestamp)));
        // Scale randomness to 10,000
        uint16 randomPermyriad = uint16(randomness % 10000);

        if (randomPermyriad < mutationRatePermyriad) {
            // Mutation occurs!
            Entity storage entity = _entities[tokenId];
            entity.mutations++;
            // Mutation could also alter stats, traits, or future requirements/effects
            // For simplicity here, it just increments a counter.

            emit EntityMutated(tokenId, entity.mutations, currentTime);
        }
    }

    // --- Query Functions ---

    /// @notice Returns the current dynamic state of an entity.
    function getEntityState(uint256 tokenId) public view entityExists(tokenId) returns (Entity memory) {
        return _entities[tokenId];
    }

    /// @notice Returns derived traits or properties based on an entity's state.
    /// This is a simplified example; a real implementation would have more complex logic.
    function getEntityTraits(uint256 tokenId) public view entityExists(tokenId) returns (string[] memory) {
        Entity storage entity = _entities[tokenId];
        string[] memory traits = new string[](5); // Max 5 traits in this example

        uint8 traitCount = 0;

        if (entity.evolutionStage >= 3) {
            traits[traitCount++] = "Mature";
        } else if (entity.evolutionStage >= 1) {
            traits[traitCount++] = "Young";
        } else {
            traits[traitCount++] = "Seedling";
        }

        if (entity.mutations > 0) {
            traits[traitCount++] = string(abi.encodePacked("Mutated (", _toString(entity.mutations), ")"));
        }

        if (entity.isStunted) {
            traits[traitCount++] = "Stunted";
        }

        if (entity.nourishmentLevel > 180 && entity.hydrationLevel > 180 && entity.lightExposureLevel > 180) {
             traits[traitCount++] = "Thriving";
        } else if (entity.nourishmentLevel < 20 || entity.hydrationLevel < 20 || entity.lightExposureLevel < 20) {
             traits[traitCount++] = "Struggling";
        }

        if (entity.isHarvested) {
             traits[traitCount++] = "Harvested";
        }


        // Return only the filled slots
        string[] memory finalTraits = new string[](traitCount);
        for (uint i = 0; i < traitCount; i++) {
            finalTraits[i] = traits[i];
        }
        return finalTraits;
    }

    /// @notice Returns current global environment parameters.
    function getGlobalEnvironment() public view returns (int16 temp, uint16 light, uint16 timeRate) {
        return (environmentTemp, lightIntensity, globalTimeRate);
    }

    /// @notice Calculates a dynamic "evolution score" based on an entity's state and age.
    function getEvoScore(uint256 tokenId) public view entityExists(tokenId) returns (uint256) {
        Entity storage entity = _entities[tokenId];
        if (entity.isHarvested || !_exists(tokenId)) return 0;

        uint256 score = 0;
        // Base score from stage
        score += entity.evolutionStage * 100; // Higher stage = higher base score

        // Add points based on current levels (diminishing returns or cap)
        score += entity.nourishmentLevel;
        score += entity.hydrationLevel;
        score += entity.lightExposureLevel;

        // Add points for mutations
        score += entity.mutations * 50;

        // Add points for age (time since birth), maybe capped
        uint64 age = uint64(block.timestamp) - entity.birthTime;
        score += age / 1000; // Example: 1 point per 1000 seconds of real time, capped?
        // score = Math.min(score, 1000); // Example score cap

        // Penalty for stunted status
        if (entity.isStunted) {
            score = score > 100 ? score - 100 : 0; // Example penalty
        }

        return score;
    }

    /// @notice Attempts to predict potential state changes after a given time delta.
    /// @dev This is a *highly simplified* prediction. A real simulation is complex and gas-intensive.
    /// This version returns the *potential* next stage and how much more 'contract time' is needed.
    function predictEvolutionOutcome(uint256 tokenId, uint64 timeDelta) public view entityExists(tokenId) returns (uint8 currentStage, uint8 potentialNextStage, uint64 contractTimeNeededForNextStage) {
        Entity storage entity = _entities[tokenId];
        currentStage = entity.evolutionStage;
        potentialNextStage = currentStage; // Default: no change

        // Cannot predict for harvested/stunted beyond simple state
        if (entity.isHarvested || entity.isStunted) {
            return (currentStage, currentStage, type(uint64).max); // Indicate no further evolution likely
        }

        uint8 checkStage = currentStage;
        uint64 totalSimulatedTimeElapsed = _getContractTimeElapsed(0, uint64(block.timestamp) + timeDelta); // Simulate time passed from epoch + delta

        // Check requirements for the next stage
        EvolutionThresholds memory req = evolutionStageRequirements[checkStage];

        // Check if requirements are met *assuming* levels don't decay
        // This simplified prediction *ignores* decay and assumes optimal conditions + time
        bool potentialRequirementsMet = (entity.nourishmentLevel >= req.neededNourish) &&
                                       (entity.hydrationLevel >= req.neededHydration) &&
                                       (entity.lightExposureLevel >= req.neededLight);

        // Check if enough *total* simulated time has passed since birth for the *next* stage
        uint64 totalTimeToNextStageRequired = _getContractTimeElapsed(0, entity.birthTime) + req.timeToNextStage;

        if (potentialRequirementsMet && totalSimulatedTimeElapsed >= totalTimeToNextStageRequired) {
             potentialNextStage = checkStage + 1;
             contractTimeNeededForNextStage = 0; // Requirements met, time passed
        } else {
             // Calculate remaining time needed if requirements *are* met but time is insufficient
             if (potentialRequirementsMet) {
                contractTimeNeededForNextStage = totalTimeToNextStageRequired - totalSimulatedTimeElapsed;
             } else {
                contractTimeNeededForNextStage = type(uint64).max; // Requirements not met, time is irrelevant
             }
        }

        // Note: A true simulation would need to factor in decay, environment, interaction timing, etc.
        // This is a very basic projection based on current state and future time.
        return (currentStage, potentialNextStage, contractTimeNeededForNextStage);
    }

    /// @notice Returns the birth timestamp of an entity.
    function getEntityBirthTime(uint256 tokenId) public view entityExists(tokenId) returns (uint64) {
        return _entities[tokenId].birthTime;
    }

    /// @notice Returns the last interaction timestamp of an entity.
    function getEntityLastInteractionTime(uint256 tokenId) public view entityExists(tokenId) returns (uint64) {
        return _entities[tokenId].lastInteractionTime;
    }

     /// @notice Returns the recorded yield for a specific harvested entity.
     function getHarvestedYieldForEntity(uint256 tokenId) public view entityExists(tokenId) returns (uint256) {
         require(_entities[tokenId].isHarvested, "Entity has not been harvested");
         return _entities[tokenId].harvestedYield;
     }


    // --- Utility Functions ---
    // Inherited ERC721Enumerable functions provide:
    // totalSupply()
    // tokenByIndex(uint256 index)
    // tokenOfOwnerByIndex(address owner, uint256 index)

    // Helper function to convert uint256 to string (from OpenZeppelin)
    function _toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Helper function for min/max (Solidity 0.8 doesn't have built-in Math.min/max for all types easily)
    library Math {
        function min(uint16 a, uint16 b) internal pure returns (uint16) {
            return a < b ? a : b;
        }
         function max(int16 a, int16 b) internal pure returns (int16) {
            return a > b ? a : b;
        }
    }
}
```

**Explanation of Advanced Concepts and Features:**

1.  **Dynamic State & Traits (dNFTs):** The `Entity` struct holds mutable data (`nourishmentLevel`, `evolutionStage`, `mutations`, etc.). The `tokenURI` function *conceptually* relies on an off-chain service that would read this on-chain state via `getEntityState` and generate metadata/images reflecting the current condition of the entity. `getEntityTraits` provides an on-chain example of deriving human-readable traits from this state.
2.  **Time-Based Logic:** Evolution and decay are explicitly linked to time elapsed since birth or the last check/interaction (`birthTime`, `lastInteractionTime`, `lastEvolutionCheckTime`). The `_getContractTimeElapsed` helper scales real `block.timestamp` time by `globalTimeRate`, allowing the contract owner to speed up or slow down the "in-game" clock.
3.  **Parameterized Evolution:** The `evolutionStageRequirements` mapping allows the contract owner to configure the specific conditions (level thresholds, time elapsed) needed for an entity to advance from one stage to the next. This makes the evolution mechanic tunable.
4.  **Probabilistic Mutation:** The `_checkAndMutateEntity` function introduces randomness (though using `block.timestamp`/`blockhash`/etc. is pseudo-random and potentially exploitable; a real application would use Chainlink VRF or similar) to trigger mutations based on the `mutationRatePermyriad`. This adds unpredictability and unique variations.
5.  **On-Chain Simulation (Basic):** `predictEvolutionOutcome` provides a limited view function that tries to project the state. A full, accurate simulation in Solidity is difficult and gas-prohibitive, but this function demonstrates the *concept* of exposing logic that could be used for prediction or analysis off-chain.
6.  **Global Environmental Influence:** `environmentTemp` and `lightIntensity` are contract-wide variables set by the owner that can influence entity behavior (e.g., checked in `_checkAndEvolveEntity` or `_checkAndDecayEntity`). This adds a layer of global state impacting individual NFTs.
7.  **External Triggers (Pull Pattern):** Functions like `checkAndEvolveEntity` and `triggerGlobalEvolutionCycle` follow a common Web3 pattern where complex, recurring operations are triggered by *anyone*. The caller pays the gas, incentivizing community members or bots to maintain the state of entities, rather than relying solely on the owner or having the contract push state updates (which is not possible).
8.  **Lifecycle Management:** Beyond standard mint/transfer, the contract includes `harvestEntity` and `burnStuntedEntity`, providing specific end-states or phase changes for the NFTs based on their evolved or decayed condition. `harvestEntity` also introduces a simple concept of "yield" recorded on-chain.
9.  **Clear Separation of Concerns:** Internal functions (`_checkAndEvolveEntity`, etc.) handle the core logic, while public/external functions provide the interface for users and automated systems to interact with the contract and trigger those internal processes.
10. **Owner Configurability:** Many parameters (`environmentTemp`, `globalTimeRate`, `evolutionStageRequirements`, `mutationRatePermyriad`, `decayRatePerUnitTime`) are owner-set, allowing for balancing and evolution of the "game" mechanics over time.

This contract provides a foundation for a complex, interactive NFT collection where the value and appearance of the tokens are not static but are actively influenced by on-chain factors and user engagement.