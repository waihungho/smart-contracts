Okay, here is a Solidity smart contract concept called "MetaMorphosis: Dynamic On-Chain Entities". It combines elements of dynamic NFTs, state transitions, environmental influence, and entity interaction, aiming for something beyond a standard token contract.

It focuses on entities (represented by tokens) that change state (metamorphose) based on various factors: time, owner interaction, simulated environment parameters, and interaction with other entities.

It includes standard ERC721 functions and adds numerous custom functions to manage the entity lifecycle and interactions.

---

**Outline:**

1.  **Contract Definition:** Inherits ERC721 and Ownable.
2.  **Imports:** Standard libraries (ERC721, Ownable, Counters, Strings).
3.  **Custom Errors:** Define specific errors for clarity and gas efficiency.
4.  **Events:** Log key actions like metamorphosis, interactions, state changes.
5.  **Enums:** Define possible entity types and interaction states.
6.  **Structs:** Define the structure for an Entity's state, Global Environment, and Bond state.
7.  **State Variables:**
    *   ERC721 core state (handled by ERC721).
    *   Mapping from tokenId to EntityState.
    *   Mapping for tracking bonded entities.
    *   Mapping for tracking challenges.
    *   Global environment parameters.
    *   Counters for token IDs, bond IDs, challenge IDs.
    *   Base URI for metadata (could be dynamic too).
    *   Mapping for Entity Type configurations (growth factors, evolution paths).
8.  **Constructor:** Initialize ERC721, set owner.
9.  **ERC721 Overrides:** Implement `_baseURI`, `_update`, `_increaseBalance`, `supportsInterface`, `tokenURI`. The `tokenURI` will be dynamic.
10. **Admin Functions (OwnerOnly):**
    *   Set global environment parameters.
    *   Set entity type configurations.
    *   Set base metadata URI.
    *   Mint initial genesis entities.
    *   Emergency pause/unpause (optional but good practice).
11. **Entity Management & Info Functions:**
    *   `getEntityState`: Retrieve detailed state of an entity.
    *   `getGlobalEnvironment`: Retrieve current global environment.
    *   `getEntityTypeConfig`: Retrieve configuration for a specific type.
    *   `checkMetamorphosisCriteria`: Pure function to check if an entity can evolve.
12. **Entity Interaction & Evolution Functions:**
    *   `nurtureEntity`: Provide resources (simulate 'feeding'). Affects energy and growth points.
    *   `restEntity`: Time-based action, recovers energy based on time since last rest/interaction.
    *   `triggerMetamorphosis`: Attempt to evolve the entity based on accumulated factors.
    *   `applyEnvironmentEffect`: Apply influence of the global environment to an entity.
    *   `bondEntities`: Initiate a bond between two entities for potential interaction outcomes.
    *   `resolveBond`: Process the outcome of a completed bond (could yield new entities, shared boosts, etc.).
    *   `challengeEntity`: Initiate a challenge between two entities.
    *   `resolveChallenge`: Process the outcome of a completed challenge (could affect energy, state, etc.).
    *   `sacrificeEntity`: Burn an entity to provide a boost or effect to another.
    *   `collectStagedReward`: Claim accumulated 'rewards' or benefits stored within the entity state (e.g., generated resources, growth bursts).
13. **Query & Simulation Functions (Pure/View):**
    *   `predictMetamorphosisOutcome`: Simulate the potential outcome of triggering metamorphosis without changing state.
    *   `simulateBondOutcome`: Simulate potential outcomes of bonding two specific entities.
    *   `simulateChallengeOutcome`: Simulate potential outcomes of challenging two entities.
    *   `queryEnvironmentalImpact`: Pure function predicting how a *type* of entity would react to a specific environment.
14. **ERC721 Required Functions:** `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the initial owner and ERC721 name/symbol.
2.  `setMetadataBaseURI(string memory newBaseURI)`: Admin function to update the base URI for token metadata.
3.  `setGlobalEnvironmentParams(EnvironmentParams memory params)`: Admin function to set global environmental factors influencing entities.
4.  `setEntityTypeConfig(EntityType entityType, EntityConfig memory config)`: Admin function to configure growth, evolution, and behavior parameters for different entity types.
5.  `mintGenesisEntity(address to, EntityType initialType)`: Admin function to mint initial entities into the ecosystem.
6.  `getEntityState(uint256 tokenId)`: View function to retrieve the full current state struct of an entity.
7.  `getGlobalEnvironment()`: View function to retrieve the current global environment parameters.
8.  `getEntityTypeConfig(EntityType entityType)`: View function to retrieve the configuration for a specific entity type.
9.  `nurtureEntity(uint256 tokenId, uint256 energyAmount)`: Allows an owner to interact, providing 'energy' and potentially boosting growth points.
10. `restEntity(uint256 tokenId)`: Allows an owner to trigger a 'rest' phase, recovering energy based on time passed.
11. `triggerMetamorphosis(uint256 tokenId)`: Attempts to evolve the entity to its next stage if criteria (level, energy, time, environment) are met.
12. `applyEnvironmentEffect(uint256 tokenId)`: Applies the influence of the current global environment to a specific entity, affecting its state.
13. `bondEntities(uint256 tokenId1, uint256 tokenId2)`: Initiates a bond between two owned entities, setting a state for potential interaction. Requires both owners' consent (or one owner for both).
14. `resolveBond(uint256 bondId)`: Processes the outcome of a bond once conditions (e.g., time elapsed) are met, potentially resulting in shared effects or new states.
15. `challengeEntity(uint256 challengerId, uint256 targetId)`: Initiates a challenge interaction between two owned entities. Requires both owners' consent (or one owner).
16. `resolveChallenge(uint256 challengeId)`: Processes the outcome of a challenge, affecting the state (energy, level, state) of participating entities based on their properties and potentially randomness.
17. `sacrificeEntity(uint256 sacrificedId, uint256 targetId)`: Burns the `sacrificedId` entity to provide a significant boost or unique effect to the `targetId` entity.
18. `collectStagedReward(uint256 tokenId)`: Allows the owner to claim accumulated benefits (e.g., growth points, temporary boosts) that the entity has generated over time or through actions.
19. `checkMetamorphosisCriteria(uint256 tokenId)`: Pure function checking if an entity meets the requirements to attempt metamorphosis based on its current state and the environment.
20. `predictMetamorphosisOutcome(uint256 tokenId)`: Pure function that simulates the outcome of `triggerMetamorphosis` without altering state.
21. `simulateBondOutcome(uint256 tokenId1, uint256 tokenId2)`: Pure function simulating the potential results if two entities successfully bond.
22. `simulateChallengeOutcome(uint256 challengerId, uint256 targetId)`: Pure function simulating the potential results of a challenge between two entities.
23. `queryEnvironmentalImpact(EntityType entityType, EnvironmentParams memory envParams)`: Pure function predicting how a given entity *type* would likely react to specific environmental conditions.
24. `getEntityHistory(uint256 tokenId)`: (Requires event parsing off-chain, or storing history on-chain which is gas-intensive. Simulating this function would involve emitting events and relying on off-chain tools to read them). This would return a list of major state changes logged by events. *Self-correction: Storing history on-chain is too expensive. This function summary point will be a conceptual placeholder for off-chain data retrieval via events.*
25. `tokenURI(uint256 tokenId)`: Overridden ERC721 function providing a URI to dynamic metadata reflecting the entity's current state, environment, etc.
26. `balanceOf(address owner)`: Standard ERC721.
27. `ownerOf(uint256 tokenId)`: Standard ERC721.
28. `approve(address to, uint256 tokenId)`: Standard ERC721.
29. `getApproved(uint256 tokenId)`: Standard ERC721.
30. `setApprovalForAll(address operator, bool approved)`: Standard ERC721.
31. `isApprovedForAll(address owner, address operator)`: Standard ERC721.
32. `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
33. `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
34. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Standard ERC721.
35. `name()`: Standard ERC721.
36. `symbol()`: Standard ERC721.
37. `_baseURI()`: Internal ERC721 helper.
38. `_update(address to, uint256 tokenId, address auth)`: Internal ERC721 helper, potentially overridden for logic on transfer.
39. `_increaseBalance(address account, uint128 amount)`: Internal ERC721 helper.
40. `supportsInterface(bytes4 interfaceId)`: Standard ERC165/ERC721.

*(Note: We have significantly more than 20 functions, including standard ERC721. The core custom logic is spread across ~20 functions manipulating state and interactions).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol"; // For metadata updates

// --- Outline ---
// 1. Contract Definition: Inherits ERC721, Ownable, IERC4906
// 2. Imports: OpenZeppelin standards
// 3. Custom Errors: Specific errors for clarity
// 4. Events: Log key state changes and interactions
// 5. Enums: Define entity types, interaction states
// 6. Structs: Define EntityState, EnvironmentParams, Bond/Challenge state
// 7. State Variables: Mappings for entity state, interactions, environment, type configs
// 8. Constructor: Initialize ERC721, set owner
// 9. ERC721/ERC4906 Overrides: tokenURI (dynamic), _baseURI, _update, supportsInterface
// 10. Admin Functions (OwnerOnly): Set environment, type configs, base URI, mint genesis
// 11. Entity Management & Info: Get state, environment, type configs
// 12. Entity Interaction & Evolution: Nurture, Rest, Metamorphosis, Environment Effect, Bond, Resolve Bond, Challenge, Resolve Challenge, Sacrifice, Collect Reward
// 13. Query & Simulation (Pure/View): Check criteria, Predict outcomes, Query impact
// 14. ERC721 Required Functions: balance, owner, approve, transfer etc.

// --- Function Summary ---
// 1.  constructor()
// 2.  setMetadataBaseURI(string)
// 3.  setGlobalEnvironmentParams(EnvironmentParams)
// 4.  setEntityTypeConfig(EntityType, EntityConfig)
// 5.  mintGenesisEntity(address, EntityType)
// 6.  getEntityState(uint256)
// 7.  getGlobalEnvironment()
// 8.  getEntityTypeConfig(EntityType)
// 9.  nurtureEntity(uint256, uint256)
// 10. restEntity(uint256)
// 11. triggerMetamorphosis(uint256)
// 12. applyEnvironmentEffect(uint256)
// 13. bondEntities(uint256, uint256)
// 14. resolveBond(uint256)
// 15. challengeEntity(uint256, uint256)
// 16. resolveChallenge(uint256)
// 17. sacrificeEntity(uint256, uint256)
// 18. collectStagedReward(uint256)
// 19. checkMetamorphosisCriteria(uint256) (Pure)
// 20. predictMetamorphosisOutcome(uint256) (Pure)
// 21. simulateBondOutcome(uint256, uint256) (Pure)
// 22. simulateChallengeOutcome(uint256, uint256) (Pure)
// 23. queryEnvironmentalImpact(EntityType, EnvironmentParams) (Pure)
// 24. getEntityHistory(uint256) (Conceptual - relies on events)
// 25. tokenURI(uint256) (Dynamic)
// 26-40: Standard ERC721/ERC165 functions...

contract MetaMorphosis is ERC721, Ownable, IERC4906 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Custom Errors ---
    error InvalidTokenType();
    error EntityNotFound();
    error NotOwnerOfEntity(uint256 tokenId);
    error CannotMetamorphoseYet(string reason);
    error BondInProgress(uint256 bondId);
    error BondNotFound();
    error ChallengeInProgress(uint256 challengeId);
    error ChallengeNotFound();
    error NotParticipantOfInteraction();
    error SacrificeTargetCannotBeSelf();
    error SacrificeTargetNotFound();
    error EntitiesCannotInteract();
    error InteractionNotReadyToResolve();
    error NothingToCollect();

    // --- Events ---
    event EntityMinted(uint256 indexed tokenId, address indexed owner, EntityType initialType, uint64 timestamp);
    event EntityNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 energyAdded, uint256 newEnergy);
    event EntityRested(uint256 indexed tokenId, address indexed restorer, uint256 energyRecovered, uint256 newEnergy);
    event EntityMetamorphosed(uint256 indexed tokenId, EntityType oldType, EntityType newType, uint256 newLevel, uint64 timestamp);
    event EnvironmentEffectApplied(uint256 indexed tokenId, EnvironmentParams params);
    event BondInitiated(uint256 indexed bondId, uint256 indexed entityId1, uint256 indexed entityId2, uint64 timestamp);
    event BondResolved(uint256 indexed bondId, uint256 indexed entityId1, uint256 indexed entityId2, string outcome);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed challengerId, uint256 indexed targetId, uint64 timestamp);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed challengerId, uint256 indexed targetId, string outcome);
    event EntitySacrificed(uint256 indexed sacrificedId, uint256 indexed targetId, string effect);
    event StagedRewardCollected(uint256 indexed tokenId, uint256 amount); // Generic reward for now
    event EntityParameterUpdated(uint256 indexed tokenId, string parameter, uint256 value); // For dynamic tokenURI updates

    // --- Enums ---
    enum EntityType { NONE, SEED, SAPLING, TREE, ELEMENTAL, CREATURE, MYTHIC }
    enum InteractionStatus { NONE, PENDING, RESOLVED, CANCELLED }

    // --- Structs ---
    struct EntityState {
        EntityType currentType;
        uint256 level;
        uint256 energy;
        uint256 growthPoints; // Accumulated points towards next level/evolution
        uint64 creationTime;
        uint64 lastInteractionTime; // Used for rest/time-based effects
        uint256 stagedRewards; // Rewards accumulated, waiting to be claimed
        // Add more dynamic parameters here influencing behavior/appearance
        uint256 resilience;
        uint256 mutationFactor;
    }

    struct EnvironmentParams {
        uint256 temperature; // e.g., 0-100
        uint256 humidity;    // e.g., 0-100
        uint256 radiation;   // e.g., 0-100
        // Add other global factors
    }

    struct EntityConfig {
        uint256 energyPerNurture;
        uint256 growthPointsPerNurture;
        uint256 energyRecoveryRate; // Per hour/day
        uint256 metamorphosisThresholdEnergy;
        uint256 metamorphosisThresholdGrowth;
        uint256 metamorphosisThresholdLevel;
        uint64 metamorphosisCooldown; // Time required between attempts
        EntityType[] potentialEvolutions; // Possible types it can evolve into
        // Interaction factors
        uint256 challengeBasePower;
        uint256 bondDuration; // Duration in seconds for bonding
        uint256 challengeDuration; // Duration in seconds for challenge
    }

    struct Bond {
        uint256 entityId1;
        uint224 entityId2; // Use uint224 to save space as tokenIds are likely < 2^224
        address owner1;
        address owner2;
        uint64 startTime;
        InteractionStatus status;
    }

    struct Challenge {
        uint256 challengerId;
        uint224 targetId;
        address challengerOwner;
        address targetOwner;
        uint64 startTime;
        InteractionStatus status;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIds;
    mapping(uint256 => EntityState) private _entityStates;
    string private _baseTokenURI;
    EnvironmentParams private _globalEnvironment;
    mapping(EntityType => EntityConfig) private _entityConfigs;

    Counters.Counter private _bondIds;
    mapping(uint256 => Bond) private _bonds;
    mapping(uint256 => uint256) private _entityActiveBond; // entityId => bondId (0 if none)

    Counters.Counter private _challengeIds;
    mapping(uint256 => Challenge) private _challenges;
    mapping(uint256 => uint256) private _entityActiveChallenge; // entityId => challengeId (0 if none)


    // --- Constructor ---
    constructor() ERC721("MetaMorphosisEntity", "META") Ownable(msg.sender) {
        // Set initial environment parameters (can be zero or default)
        _globalEnvironment = EnvironmentParams(0, 0, 0);

        // Basic default configs (Owner must set proper configs via setEntityTypeConfig)
        _entityConfigs[EntityType.NONE] = EntityConfig(0, 0, 0, 0, 0, 0, 0, new EntityType[](0), 0, 0, 0);
        _entityConfigs[EntityType.SEED] = EntityConfig(10, 5, 1, 50, 20, 1, 1 days, new EntityType[](1), 5, 30 minutes, 10 minutes); // Example: SEED evolves to SAPLING
        // Add more default configs...
    }

    // --- ERC721/ERC4906 Overrides ---

    /// @dev Returns the base URI for token metadata.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Sets the base URI for token metadata. Only callable by owner.
    function setMetadataBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        // No need to emit ERC4906:MetadataUpdate for base URI change per se,
        // but subsequent tokenURI calls will reflect the change.
        // If specific token metadata changes, fire ERC4906:MetadataUpdate(tokenId).
    }

    /// @dev Returns the dynamic token URI for a given token ID.
    /// Includes relevant state parameters to generate dynamic metadata off-chain.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721MetadataAbsentURI(tokenId);

        string memory base = _baseURI();
        if (bytes(base).length == 0) {
             revert ERC721MetadataAbsentURI(tokenId); // Or return empty string based on preference
        }

        EntityState storage state = _entityStates[tokenId];
        // Append token ID and key state parameters as query params or part of the path
        // Off-chain service will use these params to generate JSON metadata
        return string(abi.encodePacked(
            base,
            tokenId.toString(),
            "?type=", Strings.toString(uint256(state.currentType)),
            "&level=", state.level.toString(),
            "&energy=", state.energy.toString(),
            "&growth=", state.growthPoints.toString(),
            "&resilience=", state.resilience.toString(),
            "&mutation=", state.mutationFactor.toString()
            // Add other state parameters as needed
        ));
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC4906).interfaceId || super.supportsInterface(interfaceId);
    }

    // We override _update to emit MetadataUpdate when ownership changes,
    // as entity state/metadata is tied to the token which might imply owner interaction patterns change.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address oldOwner = ownerOf(tokenId);
        super._update(to, tokenId, auth);
        if (oldOwner != to && to != address(0)) {
            // Emit MetadataUpdate when the owner changes, as owner interaction affects state & metadata
            emit MetadataUpdate(tokenId);
        }
        return to;
    }


    // --- Admin Functions (OwnerOnly) ---

    /// @dev Sets the global environment parameters. Only callable by owner.
    /// Affects how entities behave and evolve.
    function setGlobalEnvironmentParams(EnvironmentParams memory params) public onlyOwner {
        _globalEnvironment = params;
        // No specific event for global env change, entities apply it individually.
    }

    /// @dev Sets the configuration parameters for a specific entity type. Only callable by owner.
    /// Defines growth rates, evolution paths, interaction stats etc.
    /// @param entityType The type being configured.
    /// @param config The configuration struct.
    function setEntityTypeConfig(EntityType entityType, EntityConfig memory config) public onlyOwner {
        if (entityType == EntityType.NONE) revert InvalidTokenType();
        _entityConfigs[entityType] = config;
        // No specific event, relies on external config management.
    }

     /// @dev Mints initial genesis entities. Only callable by owner.
     /// @param to The address to mint the entity to.
     /// @param initialType The initial type of the entity.
    function mintGenesisEntity(address to, EntityType initialType) public onlyOwner {
        if (initialType == EntityType.NONE) revert InvalidTokenType();
        if (_entityConfigs[initialType].metamorphosisCooldown == 0 && initialType != EntityType.SEED) {
            // Basic check: Initial types should generally have defined configs or be SEED
             revert InvalidTokenType(); // Or a more specific error
        }

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(to, newItemId);

        _entityStates[newItemId] = EntityState({
            currentType: initialType,
            level: 1,
            energy: 50, // Starting energy
            growthPoints: 0,
            creationTime: uint64(block.timestamp),
            lastInteractionTime: uint64(block.timestamp),
            stagedRewards: 0,
            resilience: 10 + (newItemId % 10), // Example unique parameter
            mutationFactor: 5 + (newItemId % 5)  // Example unique parameter
        });

        emit EntityMinted(newItemId, to, initialType, uint64(block.timestamp));
        emit MetadataUpdate(newItemId); // Signal metadata is available/updated
    }

    // --- Entity Management & Info ---

    /// @dev Retrieves the current state of a specific entity.
    /// @param tokenId The ID of the entity token.
    /// @return The EntityState struct.
    function getEntityState(uint256 tokenId) public view returns (EntityState memory) {
        if (!_exists(tokenId)) revert EntityNotFound();
        return _entityStates[tokenId];
    }

    /// @dev Retrieves the current global environment parameters.
    function getGlobalEnvironment() public view returns (EnvironmentParams memory) {
        return _globalEnvironment;
    }

    /// @dev Retrieves the configuration parameters for a specific entity type.
    /// @param entityType The type to get config for.
    function getEntityTypeConfig(EntityType entityType) public view returns (EntityConfig memory) {
        return _entityConfigs[entityType];
    }

    // --- Entity Interaction & Evolution ---

    /// @dev Allows the owner to nurture an entity, adding energy and growth points.
    /// @param tokenId The ID of the entity token.
    /// @param energyAmount The amount of energy/nurturing provided.
    function nurtureEntity(uint256 tokenId, uint256 energyAmount) public {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfEntity(tokenId);
        if (!_exists(tokenId)) revert EntityNotFound();

        EntityState storage state = _entityStates[tokenId];
        EntityConfig storage config = _entityConfigs[state.currentType];

        uint256 energyToAdd = energyAmount; // Could scale based on item/cost in future
        uint256 growthToAdd = (energyAmount * config.growthPointsPerNurture) / config.energyPerNurture;

        state.energy += energyToAdd;
        state.growthPoints += growthToAdd;
        state.lastInteractionTime = uint64(block.timestamp);

        emit EntityNurtured(tokenId, msg.sender, energyToAdd, state.energy);
        emit MetadataUpdate(tokenId); // State changed, metadata potentially updated
    }

    /// @dev Allows the owner to trigger a rest phase for an entity, recovering energy based on time passed.
    /// @param tokenId The ID of the entity token.
    function restEntity(uint256 tokenId) public {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfEntity(tokenId);
        if (!_exists(tokenId)) revert EntityNotFound();

        EntityState storage state = _entityStates[tokenId];
        EntityConfig storage config = _entityConfigs[state.currentType];

        uint64 timePassed = uint64(block.timestamp) - state.lastInteractionTime;
        uint256 energyRecovered = (uint256(timePassed) / 1 hours) * config.energyRecoveryRate; // Recover per hour

        if (energyRecovered > 0) {
             state.energy += energyRecovered;
             state.lastInteractionTime = uint64(block.timestamp); // Reset timer
             emit EntityRested(tokenId, msg.sender, energyRecovered, state.energy);
             emit MetadataUpdate(tokenId); // State changed
        } else {
            // Optionally revert or just do nothing if no energy recovered
        }
    }

    /// @dev Attempts to trigger the metamorphosis of an entity. Requires meeting criteria.
    /// @param tokenId The ID of the entity token.
    function triggerMetamorphosis(uint256 tokenId) public {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfEntity(tokenId);
        if (!_exists(tokenId)) revert EntityNotFound();

        EntityState storage state = _entityStates[tokenId];
        EntityConfig storage config = _entityConfigs[state.currentType];

        // Check Metamorphosis Criteria
        string memory failureReason = checkMetamorphosisCriteria(tokenId);
        if (bytes(failureReason).length > 0) {
            revert CannotMetamorphoseYet(failureReason);
        }

        // --- Metamorphosis Logic ---
        // This is where complex evolution paths, environment influence,
        // and randomness based on entity stats (like mutationFactor) would be applied.
        // For this example, we pick the first potential evolution if multiple exist,
        // or add more complex branching based on current state/environment.

        EntityType oldType = state.currentType;
        EntityType newType = EntityType.NONE;

        if (config.potentialEvolutions.length > 0) {
            // Simple logic: pick the first potential evolution.
            // More complex: Use mutationFactor, environment, or accumulated stats
            // to deterministically or pseudo-randomly select from potentialEvolutions.
            // e.g., based on resilience vs mutation factor, or temperature vs humidity.
            newType = config.potentialEvolutions[0]; // Simplistic
        } else {
             revert CannotMetamorphoseYet("No defined evolution path");
        }

        if (newType == EntityType.NONE) revert CannotMetamorphoseYet("Evolution path leads to invalid type");

        // Apply Metamorphosis effects
        state.currentType = newType;
        state.level += 1; // Level up on evolution
        state.energy = state.energy / 2; // Energy cost for metamorphosis
        state.growthPoints = 0; // Reset growth
        state.lastInteractionTime = uint64(block.timestamp); // Reset timer
        // Potentially adjust resilience, mutationFactor, or other stats based on newType

        // Add staged rewards for reaching new stage
        state.stagedRewards += state.level * 100; // Example reward scaling with level

        emit EntityMetamorphosed(tokenId, oldType, newType, state.level, uint64(block.timestamp));
        emit MetadataUpdate(tokenId); // State changed significantly

    }

    /// @dev Applies the influence of the current global environment to an entity.
    /// This could passively affect growth, energy, or even trigger state changes over time.
    /// This function could be called periodically off-chain, or be part of other interactions.
    /// @param tokenId The ID of the entity token.
    function applyGlobalEnvironmentEffect(uint256 tokenId) public {
        // Could restrict this caller or make it permissionless with rate limiting
        if (!_exists(tokenId)) revert EntityNotFound();

        EntityState storage state = _entityStates[tokenId];
        EntityConfig storage config = _entityConfigs[state.currentType];
        EnvironmentParams storage env = _globalEnvironment;

        // --- Environment Logic ---
        // Example: High temperature increases energy drain but boosts growthPoints slightly.
        // High radiation decreases resilience and might increase mutationFactor.
        // This logic needs to be carefully designed.

        uint64 timeSinceLastEffect = uint64(block.timestamp) - state.lastInteractionTime; // Or track a separate timer
        if (timeSinceLastEffect == 0) return; // Avoid division by zero

        // Example: Apply effects based on environment
        if (env.temperature > 70) {
            uint256 energyDrain = (state.level * uint256(timeSinceLastEffect)) / 1 hours;
            if (state.energy > energyDrain) state.energy -= energyDrain; else state.energy = 0;
            state.growthPoints += (state.level * uint256(timeSinceLastEffect)) / (1 days); // Faster growth in heat?
        }
        if (env.radiation > 50) {
             if (state.resilience > 0) state.resilience -= 1; // Decrease resilience
             state.mutationFactor += 1; // Increase mutation risk
        }

        state.lastInteractionTime = uint64(block.timestamp); // Reset timer for effect calculation

        emit EnvironmentEffectApplied(tokenId, env);
        emit MetadataUpdate(tokenId); // State potentially changed
    }


    /// @dev Initiates a bond between two entities owned by the caller.
    /// Both entities must not be involved in another interaction.
    /// @param tokenId1 The ID of the first entity.
    /// @param tokenId2 The ID of the second entity.
    function bondEntities(uint256 tokenId1, uint256 tokenId2) public {
        if (tokenId1 == tokenId2) revert EntitiesCannotInteract();
        if (ownerOf(tokenId1) != msg.sender) revert NotOwnerOfEntity(tokenId1);
        if (ownerOf(tokenId2) != msg.sender) revert NotOwnerOfEntity(tokenId2); // Assumes same owner bonding
        if (_entityActiveBond[tokenId1] != 0) revert BondInProgress(_entityActiveBond[tokenId1]);
        if (_entityActiveBond[tokenId2] != 0) revert BondInProgress(_entityActiveBond[tokenId2]);

        EntityConfig storage config1 = _entityConfigs[_entityStates[tokenId1].currentType];
        // EntityConfig storage config2 = _entityConfigs[_entityStates[tokenId2].currentType]; // Could use for compatibility checks

        _bondIds.increment();
        uint256 bondId = _bondIds.current();

        _bonds[bondId] = Bond({
            entityId1: tokenId1,
            entityId2: uint224(tokenId2),
            owner1: msg.sender,
            owner2: msg.sender, // Same owner for simplicity
            startTime: uint64(block.timestamp),
            status: InteractionStatus.PENDING
        });

        _entityActiveBond[tokenId1] = bondId;
        _entityActiveBond[tokenId2] = bondId;

        emit BondInitiated(bondId, tokenId1, tokenId2, uint64(block.timestamp));
    }

    /// @dev Resolves a bond after its required duration has passed.
    /// Outcomes could include shared growth, energy transfer, or even creating a new entity (if implemented).
    /// @param bondId The ID of the bond to resolve.
    function resolveBond(uint256 bondId) public {
        Bond storage bond = _bonds[bondId];
        if (bond.status != InteractionStatus.PENDING) revert InteractionNotReadyToResolve();
        if (msg.sender != bond.owner1 && msg.sender != bond.owner2) revert NotParticipantOfInteraction();

        EntityConfig storage config1 = _entityConfigs[_entityStates[bond.entityId1].currentType];
        // EntityConfig storage config2 = _entityConfigs[_entityStates[uint256(bond.entityId2)].currentType];

        if (uint64(block.timestamp) < bond.startTime + config1.bondDuration) {
            revert InteractionNotReadyToResolve(); // Bond duration not met
        }

        // --- Bond Resolution Logic ---
        // Example: Both entities gain growth points and energy based on duration and their types
        EntityState storage state1 = _entityStates[bond.entityId1];
        EntityState storage state2 = _entityStates[uint256(bond.entityId2)];

        uint256 sharedGrowth = (uint256(config1.bondDuration) / 60) * (state1.level + state2.level); // Growth based on bond time and levels
        state1.growthPoints += sharedGrowth;
        state2.growthPoints += sharedGrowth;

        state1.energy += sharedGrowth / 2; // Also gain some energy
        state2.energy += sharedGrowth / 2;

        string memory outcome = string(abi.encodePacked("Shared growth and energy gain: ", sharedGrowth.toString()));

        bond.status = InteractionStatus.RESOLVED;
        delete _entityActiveBond[bond.entityId1];
        delete _entityActiveBond[uint256(bond.entityId2)];

        emit BondResolved(bondId, bond.entityId1, uint256(bond.entityId2), outcome);
        emit MetadataUpdate(bond.entityId1);
        emit MetadataUpdate(uint256(bond.entityId2));
    }

    /// @dev Initiates a challenge between two entities owned by the caller.
    /// @param challengerId The ID of the challenging entity.
    /// @param targetId The ID of the target entity.
    function challengeEntity(uint256 challengerId, uint256 targetId) public {
        if (challengerId == targetId) revert EntitiesCannotInteract();
        if (ownerOf(challengerId) != msg.sender) revert NotOwnerOfEntity(challengerId);
        if (ownerOf(targetId) != msg.sender) revert NotOwnerOfEntity(targetId); // Assumes same owner challenging self
        if (_entityActiveChallenge[challengerId] != 0) revert ChallengeInProgress(_entityActiveChallenge[challengerId]);
        if (_entityActiveChallenge[targetId] != 0) revert ChallengeInProgress(_entityActiveChallenge[targetId]);

        EntityConfig storage configChallenger = _entityConfigs[_entityStates[challengerId].currentType];
        // EntityConfig storage configTarget = _entityConfigs[_entityStates[targetId].currentType];

        _challengeIds.increment();
        uint256 challengeId = _challengeIds.current();

        _challenges[challengeId] = Challenge({
            challengerId: challengerId,
            targetId: uint224(targetId),
            challengerOwner: msg.sender,
            targetOwner: msg.sender,
            startTime: uint64(block.timestamp),
            status: InteractionStatus.PENDING
        });

        _entityActiveChallenge[challengerId] = challengeId;
        _entityActiveChallenge[targetId] = challengeId;

        emit ChallengeInitiated(challengeId, challengerId, targetId, uint64(block.timestamp));
    }

    /// @dev Resolves a challenge after its required duration has passed.
    /// Outcomes affect entity states (energy, potential level changes, etc.) based on stats and luck.
    /// @param challengeId The ID of the challenge to resolve.
    function resolveChallenge(uint256 challengeId) public {
        Challenge storage challenge = _challenges[challengeId];
        if (challenge.status != InteractionStatus.PENDING) revert InteractionNotReadyToResolve();
        if (msg.sender != challenge.challengerOwner && msg.sender != challenge.targetOwner) revert NotParticipantOfInteraction();

        EntityState storage challengerState = _entityStates[challenge.challengerId];
        EntityState storage targetState = _entityStates[uint256(challenge.targetId)];
        EntityConfig storage configChallenger = _entityConfigs[challengerState.currentType];
        // EntityConfig storage configTarget = _entityConfigs[targetState.currentType]; // Use target config too

        if (uint64(block.timestamp) < challenge.startTime + configChallenger.challengeDuration) {
            revert InteractionNotReadyToResolve(); // Challenge duration not met
        }

        // --- Challenge Resolution Logic ---
        // Example: Based on levels, energy, resilience, and mutationFactor.
        // Introduce a simple pseudo-random element (block hash is NOT secure randomness).
        // A proper implementation would use Chainlink VRF or similar.
        uint256 pseudoRandomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, challenge.challengerId, challenge.targetId)));

        uint256 challengerPower = challengerState.level * configChallenger.challengeBasePower + (challengerState.energy / 10) + challengerState.mutationFactor;
        uint256 targetPower = targetState.level * configChallenger.challengeBasePower + (targetState.energy / 10) + targetState.resilience;

        string memory outcome;
        if ((challengerPower + (pseudoRandomFactor % 50)) > (targetPower + (pseudoRandomFactor % 50))) {
            // Challenger wins
            challengerState.energy += targetState.energy / 4; // Gains energy
            targetState.energy = targetState.energy / 2; // Loses energy
            // Optionally: challenger gains growth, target loses resilience
            outcome = "Challenger wins!";
        } else {
            // Target wins (or tie results in target winning for simplicity)
            targetState.energy += challengerState.energy / 4; // Gains energy
            challengerState.energy = challengerState.energy / 2; // Loses energy
            // Optionally: target gains growth, challenger loses growth
            outcome = "Target defends successfully!";
        }

        // Ensure energy doesn't go below zero (uint) - already handled by reducing
        challengerState.lastInteractionTime = uint64(block.timestamp); // Update interaction times
        targetState.lastInteractionTime = uint64(block.timestamp);

        challenge.status = InteractionStatus.RESOLVED;
        delete _entityActiveChallenge[challenge.challengerId];
        delete _entityActiveChallenge[uint256(challenge.targetId)];

        emit ChallengeResolved(challengeId, challenge.challengerId, uint256(challenge.targetId), outcome);
        emit MetadataUpdate(challenge.challengerId);
        emit MetadataUpdate(uint256(challenge.targetId));
    }


    /// @dev Allows sacrificing one entity owned by the caller to boost another owned entity.
    /// The sacrificed entity is burned.
    /// @param sacrificedId The ID of the entity to sacrifice.
    /// @param targetId The ID of the entity to boost.
    function sacrificeEntity(uint256 sacrificedId, uint256 targetId) public {
        if (sacrificedId == targetId) revert SacrificeTargetCannotBeSelf();
        if (ownerOf(sacrificedId) != msg.sender) revert NotOwnerOfEntity(sacrificedId);
        if (ownerOf(targetId) != msg.sender) revert NotOwnerOfEntity(targetId); // Assumes same owner
        if (!_exists(targetId)) revert SacrificeTargetNotFound();

        EntityState storage sacrificedState = _entityStates[sacrificedId];
        EntityState storage targetState = _entityStates[targetId];
        EntityConfig storage sacrificedConfig = _entityConfigs[sacrificedState.currentType];

        // --- Sacrifice Logic ---
        // Example: Target gains energy and growth points based on sacrificed entity's level and type.
        uint256 energyBoost = sacrificedState.energy / 2 + sacrificedState.level * 10;
        uint256 growthBoost = sacrificedState.growthPoints + sacrificedState.level * 20 + sacrificedConfig.challengeBasePower; // Use config stat

        targetState.energy += energyBoost;
        targetState.growthPoints += growthBoost;
        targetState.lastInteractionTime = uint64(block.timestamp); // Update target interaction time

        string memory effectDescription = string(abi.encodePacked("Gained energy: ", energyBoost.toString(), ", growth: ", growthBoost.toString()));

        // Burn the sacrificed entity
        _burn(sacrificedId);
        delete _entityStates[sacrificedId]; // Remove state data

        emit EntitySacrificed(sacrificedId, targetId, effectDescription);
        emit MetadataUpdate(targetId); // Target state changed
    }

    /// @dev Allows the owner to collect staged rewards accumulated by the entity.
    /// Staged rewards are cleared after collection.
    /// @param tokenId The ID of the entity.
    function collectStagedReward(uint256 tokenId) public {
        if (ownerOf(tokenId) != msg.sender) revert NotOwnerOfEntity(tokenId);
        if (!_exists(tokenId)) revert EntityNotFound();

        EntityState storage state = _entityStates[tokenId];

        if (state.stagedRewards == 0) revert NothingToCollect();

        uint256 rewardAmount = state.stagedRewards;
        state.stagedRewards = 0; // Clear staged rewards

        // In a real system, this would transfer a reward token (ERC20)
        // For this example, we just emit an event.
        emit StagedRewardCollected(tokenId, rewardAmount);
        emit MetadataUpdate(tokenId); // State changed
    }


    // --- Query & Simulation (Pure/View) ---

    /// @dev Pure function to check if an entity meets the criteria to attempt metamorphosis.
    /// Does NOT check cooldown or actual outcome, only if the thresholds are met.
    /// @param tokenId The ID of the entity.
    /// @return An empty string if criteria met, otherwise a string explaining why not.
    function checkMetamorphosisCriteria(uint256 tokenId) public view returns (string memory) {
         if (!_exists(tokenId)) return "Entity not found"; // Should be caught by caller usually
         EntityState storage state = _entityStates[tokenId];
         EntityConfig storage config = _entityConfigs[state.currentType];

         if (config.potentialEvolutions.length == 0) return "No defined evolution path for current type";
         if (state.level < config.metamorphosisThresholdLevel) return string(abi.encodePacked("Level (", state.level.toString(), ") below threshold (", config.metamorphosisThresholdLevel.toString(), ")"));
         if (state.energy < config.metamorphosisThresholdEnergy) return string(abi.encodePacked("Energy (", state.energy.toString(), ") below threshold (", config.metamorphosisThresholdEnergy.toString(), ")"));
         if (state.growthPoints < config.metamorphosisThresholdGrowth) return string(abi.encodePacked("Growth Points (", state.growthPoints.toString(), ") below threshold (", config.metamorphosisThresholdGrowth.toString(), ")"));

         // Check cooldown (using lastInteractionTime as proxy for last metamorphosis attempt)
         if (uint64(block.timestamp) < state.lastInteractionTime + config.metamorphosisCooldown) {
             return string(abi.encodePacked("Metamorphosis on cooldown. Time remaining: ", (state.lastInteractionTime + config.metamorphosisCooldown - uint64(block.timestamp)).toString(), " seconds."));
         }

        return ""; // Criteria met
    }

    /// @dev Pure function simulating the *potential* outcome of triggering metamorphosis.
    /// Does NOT change state. Useful for UI predictions.
    /// @param tokenId The ID of the entity.
    /// @return A string describing the predicted outcome (e.g., "Evolves to SAPLING", "Criteria not met").
    function predictMetamorphosisOutcome(uint256 tokenId) public view returns (string memory) {
        string memory criteriaStatus = checkMetamorphosisCriteria(tokenId);
        if (bytes(criteriaStatus).length > 0) {
            return string(abi.encodePacked("Criteria not met: ", criteriaStatus));
        }

        EntityState storage state = _entityStates[tokenId];
        EntityConfig storage config = _entityConfigs[state.currentType];

        if (config.potentialEvolutions.length == 0) return "No defined evolution path";

        // --- Simulation Logic (Mirroring triggerMetamorphosis) ---
        // This simulation should ideally use deterministic logic based *only* on input state and environment,
        // not pseudo-randomness unless a seed is provided.
        // For simplicity, we'll just report the first potential evolution.
        EntityType potentialNextType = config.potentialEvolutions[0]; // Simplistic prediction

        // In a more complex version, this would simulate the selection logic.
        // Example: uint256 outcomeIndex = (state.mutationFactor + uint256(keccak256(abi.encodePacked(tokenId, block.timestamp)))) % config.potentialEvolutions.length;
        // But pure functions can't rely on block.timestamp/difficulty for randomness.
        // A deterministic simulation based purely on state/env is possible.

        return string(abi.encodePacked("Potential Metamorphosis to Type: ", uint256(potentialNextType).toString(), " (Level ", (state.level + 1).toString(), ")"));
    }


     /// @dev Pure function simulating potential outcomes of bonding two entities.
     /// Does NOT change state. Useful for UI predictions.
     /// @param tokenId1 The ID of the first entity.
     /// @param tokenId2 The ID of the second entity.
     /// @return A string describing the potential outcome.
    function simulateBondOutcome(uint256 tokenId1, uint256 tokenId2) public view returns (string memory) {
         if (!_exists(tokenId1) || !_exists(tokenId2)) return "One or both entities not found";
         if (tokenId1 == tokenId2) return "Cannot bond entity to itself";
         if (_entityActiveBond[tokenId1] != 0 || _entityActiveBond[tokenId2] != 0) return "One or both entities currently bonded";

         EntityState storage state1 = _entityStates[tokenId1];
         EntityState storage state2 = _entityStates[tokenId2];
         EntityConfig storage config1 = _entityConfigs[state1.currentType];
         // EntityConfig storage config2 = _entityConfigs[state2.currentType];

         // Simulate the outcome logic from resolveBond
         // Assuming bond duration is met for prediction
         uint256 simulatedSharedGrowth = (uint256(config1.bondDuration) / 60) * (state1.level + state2.level);

         return string(abi.encodePacked("Potential Shared Growth: ", simulatedSharedGrowth.toString(), ", Energy Gain: ", (simulatedSharedGrowth / 2).toString()));
     }

     /// @dev Pure function simulating potential outcomes of challenging two entities.
     /// Does NOT change state. Useful for UI predictions.
     /// @param challengerId The ID of the challenging entity.
     /// @param targetId The ID of the target entity.
     /// @return A string describing the potential outcome.
    function simulateChallengeOutcome(uint256 challengerId, uint256 targetId) public view returns (string memory) {
         if (!_exists(challengerId) || !_exists(targetId)) return "One or both entities not found";
         if (challengerId == targetId) return "Cannot challenge self";
         if (_entityActiveChallenge[challengerId] != 0 || _entityActiveChallenge[targetId] != 0) return "One or both entities currently challenging";

         EntityState storage challengerState = _entityStates[challengerId];
         EntityState storage targetState = _entityStates[targetId];
         EntityConfig storage configChallenger = _entityConfigs[challengerState.currentType];
         // EntityConfig storage configTarget = _entityConfigs[targetState.currentType];

         // Simulate the outcome logic from resolveChallenge
         // Note: Pure functions cannot use block.timestamp/difficulty for realistic randomness simulation.
         // This simulation will be deterministic based purely on stats.

         uint256 challengerPower = challengerState.level * configChallenger.challengeBasePower + (challengerState.energy / 10) + challengerState.mutationFactor;
         uint256 targetPower = targetState.level * configChallenger.challengeBasePower + (targetState.energy / 10) + targetState.resilience;

         if (challengerPower > targetPower) {
             return string(abi.encodePacked("Predicted Outcome: Challenger Win (Deterministic) - Energy Gain: ", (targetState.energy / 4).toString()));
         } else if (targetPower > challengerPower) {
             return string(abi.encodePacked("Predicted Outcome: Target Win (Deterministic) - Energy Gain: ", (challengerState.energy / 4).toString()));
         } else {
              return "Predicted Outcome: Tie (Deterministic) - No significant state change";
         }
     }

     /// @dev Pure function predicting how a given entity *type* would react to specific environmental conditions.
     /// Does NOT use instance-specific state, only type config and environment params.
     /// Useful for understanding environmental effects without having an entity instance.
     /// @param entityType The type of entity to query.
     /// @param envParams Specific environment parameters to test.
     /// @return A string describing the likely impact (e.g., "Thrives in high temperature", "Weakened by radiation").
     function queryEnvironmentalImpact(EntityType entityType, EnvironmentParams memory envParams) public view returns (string memory) {
         EntityConfig storage config = _entityConfigs[entityType];
         if (config.metamorphosisCooldown == 0 && entityType != EntityType.NONE) { // Check if config exists
             return "No configuration found for this entity type.";
         }
         if (entityType == EntityType.NONE) return "Invalid entity type.";

         // --- Simulate Environmental Impact based on Type Config & Env Params ---
         string memory impact = "Impact: ";
         bool first = true;

         // Example logic (needs matching logic in applyGlobalEnvironmentEffect)
         if (envParams.temperature > 70) {
             impact = string(abi.encodePacked(impact, "High Temp: Increased Growth Potential, Energy Drain. "));
             first = false;
         } else if (envParams.temperature < 30 && envParams.temperature != 0) { // Assuming 0 means default, not cold
             if (!first) impact = string(abi.encodePacked(impact, ", "));
             impact = string(abi.encodePacked(impact, "Low Temp: Slower Growth. "));
             first = false;
         }

         if (envParams.radiation > 50) {
              if (!first) impact = string(abi.encodePacked(impact, ", "));
              impact = string(abi.encodePacked(impact, "High Radiation: Reduced Resilience, Increased Mutation Risk. "));
              first = false;
         }

         if (bytes(impact).length == bytes("Impact: ").length) {
             impact = "Impact: Neutral under these conditions.";
         }

         return impact;
     }


    /// @dev Conceptual function for retrieving historical data (via events).
    /// Storing history on-chain is prohibitively expensive for complex state.
    /// This function is a placeholder; actual history retrieval relies on off-chain indexing of events.
    /// @param tokenId The ID of the entity.
    /// @return An empty array, as history is not stored on-chain. Off-chain indexers needed.
    function getEntityHistory(uint256 tokenId) public view returns (bytes32[] memory) {
        // This is a placeholder. To get entity history, you would listen to
        // events like EntityMetamorphosed, EntityNurtured, etc., off-chain
        // and store them in a database. Querying this function would return
        // an empty array or be marked as unimplemented.
        // Adding complex history storage on-chain would make this contract prohibitively expensive.
        if (!_exists(tokenId)) revert EntityNotFound();
        return new bytes32[](0); // Return empty array as history is not stored here.
    }


    // --- ERC721 Required Functions (Inherited from OpenZeppelin ERC721) ---
    // These are automatically implemented by inheriting ERC721:
    // function balanceOf(address owner) public view virtual override returns (uint256)
    // function ownerOf(uint256 tokenId) public view virtual override returns (address)
    // function approve(address to, uint256 tokenId) public virtual override
    // function getApproved(uint256 tokenId) public view virtual override returns (address)
    // function setApprovalForAll(address operator, bool approved) public virtual override
    // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
    // function transferFrom(address from, address to, uint256 tokenId) public virtual override
    // function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override
    // function name() public view virtual override returns (string memory)
    // function symbol() public view virtual override returns (string memory)
}
```

**Explanation of Advanced/Creative Concepts Used:**

1.  **Dynamic NFTs:** The `tokenURI` function is overridden to include state parameters (`type`, `level`, `energy`, etc.) in the URI. An off-chain service or gateway would read these parameters and generate the appropriate JSON metadata and potentially the image or representation dynamically based on the entity's current state. This is more advanced than static metadata.
2.  **On-Chain State Transition/Metamorphosis:** Entities have internal states (`EntityState` struct) that change. The `triggerMetamorphosis` function allows an entity to evolve to a new `EntityType` based on accumulated `level`, `energy`, `growthPoints`, and potentially environmental factors (though direct env influence is in `applyGlobalEnvironmentEffect`). This creates a lifecycle and progression for the digital asset.
3.  **Multiple State-Influencing Factors:** Entity state isn't static. It's affected by:
    *   **Owner Interaction:** `nurtureEntity` (direct resource input), `restEntity` (time-based recovery).
    *   **Time:** Used implicitly in `restEntity` and could be a factor in `applyGlobalEnvironmentEffect` and metamorphosis cooldown.
    *   **Global Environment:** `setGlobalEnvironmentParams` (admin) and `applyGlobalEnvironmentEffect` (applies influence). This introduces a shared external factor affecting all entities.
    *   **Entity-Specific Traits:** `resilience` and `mutationFactor` are per-entity parameters influencing interactions and potentially evolution paths.
4.  **On-Chain Interaction Simulation:**
    *   **Bonding:** `bondEntities` and `resolveBond` simulate a cooperative interaction over time, potentially leading to shared benefits.
    *   **Challenging:** `challengeEntity` and `resolveChallenge` simulate a competitive interaction with outcomes based on entity stats (and potentially randomness - though pure on-chain randomness is tricky).
5.  **Sacrifice Mechanism:** `sacrificeEntity` introduces a burning mechanism where one asset is destroyed to power up another, adding a strategic element.
6.  **Staged/Accumulated Rewards:** `collectStagedReward` simulates entities generating or accumulating benefits over time or through actions, which can be claimed later.
7.  **Predictive/Query Functions (Pure/View):** Functions like `predictMetamorphosisOutcome`, `simulateBondOutcome`, `simulateChallengeOutcome`, and `queryEnvironmentalImpact` allow users to query the *potential* outcomes or effects without performing the actual state-changing transaction. This enhances user experience by providing foresight, though deterministic pure functions limit the complexity of truly probabilistic simulations.
8.  **Modular Configuration:** `setEntityTypeConfig` allows the owner (or a DAO in a more decentralized version) to define the rules and parameters for each entity type, making the ecosystem extensible and tweakable without contract upgrades (for configuration logic).
9.  **ERC4906 Metadata Update Standard:** Emitting `MetadataUpdate` when an entity's state changes (like metamorphosis, interaction outcome, nurturing) signals to marketplaces and indexers that the token's metadata needs to be refreshed, supporting the dynamic nature.

This contract design goes beyond basic token functionality by giving the tokens internal state, a lifecycle, rules for interaction, and external influences, creating a more complex and dynamic digital asset ecosystem. The `tokenURI` part is crucial for reflecting this dynamic state to the user interface. Remember that this is a complex contract and deploying it requires careful gas optimization and security audits. The randomness in `resolveChallenge` is placeholder and should be replaced by a secure VRF in production.