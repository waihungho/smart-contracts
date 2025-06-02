Okay, here is a smart contract concept called `GenesisNexus`. It focuses on creating dynamic, evolving digital entities ("Nexus Cores") as NFTs, incorporating mechanics like interaction, mutation, non-transferable traits, configurable evolution paths, and lifecycle management, aiming for complexity beyond typical NFT or simple token contracts.

It utilizes concepts like:
1.  **Dynamic NFTs:** Core properties change based on interactions and evolution.
2.  **Evolution Mechanics:** Cores progress through levels based on accumulated internal state (`energy`, `stability`).
3.  **Interaction Effects:** Cores can interact with each other, influencing their states.
4.  **Mutation & Merge:** Destructive/combinatorial processes leading to new states or entities.
5.  **Non-Transferable Traits (SBT-like):** Cores acquire traits that cannot be transferred separately but are bound to the core.
6.  **Configurable Logic:** Owner can set parameters for evolution, stimulus effects, mutation, merge, and trait acquisition conditions, allowing for an evolving game/system design.
7.  **Cooldowns:** Prevents spamming interactions.
8.  **Migration Flagging:** A placeholder for potential future contract upgrades or data migration strategies.

**Outline & Function Summary**

**Contract:** `GenesisNexus`

**Purpose:** To manage a collection of dynamic, evolving digital entities (Nexus Cores) with complex lifecycle mechanics, configurable parameters, and soulbound-like traits.

**Inheritance:**
*   `ERC721Enumerable`: Provides standard NFT functionality (minting, transfer, ownership tracking) and enumeration.
*   `Ownable`: Provides basic access control (owner-only functions).

**Data Structures:**
*   `NexusCore`: Represents a single core with ID, owner, name, creation/interaction times, energy, stability, evolution level, parameters, and acquired traits.
*   `Trait`: Represents a non-transferable characteristic acquired by a core.
*   `EvolutionParams`: Defines energy/stability requirements and decay rates for specific evolution levels.
*   `StimulusEffect`: Defines how a specific stimulus type affects core energy, stability, and its cost.
*   `MutationEffect`: Defines how a specific mutation type affects core parameters.
*   `MergeEffect`: Defines how merging affects input cores and the resulting core.
*   `TraitCondition`: Defines the conditions required for a core to acquire a specific trait (condition logic opaque `bytes`).

**Key Mappings:**
*   `_cores`: `uint256` (coreId) -> `NexusCore`
*   `_traits`: `uint256` (traitId) -> `Trait`
*   `_coreTraits`: `uint256` (coreId) -> `uint256[]` (list of traitIds)
*   `_evolutionParams`: `uint256` (evolutionLevel) -> `EvolutionParams`
*   `_stimulusEffects`: `bytes32` (hashed stimulusType) -> `StimulusEffect`
*   `_mutationEffects`: `bytes32` (hashed mutationType) -> `MutationEffect`
*   `_mergeEffects`: `bytes32` (hashed mergeType) -> `MergeEffect`
*   `_traitConditions`: `uint256` (traitId) -> `TraitCondition`
*   `_coreSpecificCooldowns`: `uint256` (coreId) -> `uint256` (cooldown duration)
*   `_lastStimulusTime`: `uint256` (coreId) -> `uint256` (timestamp)
*   `_migrationFlagged`: `uint256` (coreId) -> `bool`

**Function Categories & Summaries:**

**Lifecycle & Core Management (mostly ERC721 + Custom):**
1.  `constructor()`: Initializes the contract and ERC721 properties.
2.  `createCore(address owner)`: Owner mints a new Genesis Core with initial state.
3.  `burnCore(uint256 coreId)`: Allows core owner to destroy a core.
4.  `flagCoreForMigration(uint256 coreId)`: Owner flags a core as ready for potential data migration to a new contract.
5.  `isCoreFlaggedForMigration(uint256 coreId)`: Checks if a core is flagged for migration.
6.  *(Inherited from ERC721Enumerable)*: `balanceOf`, `ownerOf`, `safeTransferFrom(4 args)`, `safeTransferFrom(3 args)`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `totalSupply`, `tokenOfOwnerByIndex`, `tokenByIndex`. (12 functions)

**State & Evolution:**
7.  `getCoreDetails(uint256 coreId)`: View all primary details of a core.
8.  `getCoreParameters(uint256 coreId)`: View current energy, stability, and level of a core.
9.  `stimulateCore(uint256 coreId, bytes memory stimulusData)`: Apply a stimulus (external interaction) affecting the core's state, potentially consuming resources and subject to cooldowns.
10. `evolveCore(uint256 coreId)`: Attempt to evolve the core to the next level based on its current state and configured evolution parameters.

**Interaction:**
11. `interactCores(uint256 coreId1, uint256 coreId2)`: Initiate interaction between two cores, affecting both their states and potentially leading to trait acquisition.

**Mutation & Merge:**
12. `mutateCore(uint256 coreId, bytes memory mutationData)`: Apply a mutation process to a core, altering its parameters based on configuration and potentially consuming resources.
13. `mergeCores(uint256 coreId1, uint256 coreId2, bytes memory mergeData)`: Merge two cores (burning them) to potentially create a new core or yield other results, based on configuration and ownership.

**Traits:**
14. `getCoreTraits(uint256 coreId)`: View the list of trait IDs acquired by a specific core.
15. `getTraitDetails(uint256 traitId)`: View details (name, description) of a specific trait.
16. `attemptTraitAcquisition(uint256 coreId, uint256 traitId)`: Core owner attempts to acquire a specific trait if the core meets the predefined conditions for that trait.
17. `releaseTrait(uint256 coreId, uint256 traitId)`: Allows core owner to remove a specific trait from their core, potentially with a penalty.

**Configuration (Owner Only):**
18. `setCoreName(uint256 coreId, string memory name)`: Set or update the name of a core (metadata).
19. `configureEvolutionParams(uint256 level, uint256 requiredEnergy, uint256 requiredStability, uint256 energyDecay, uint256 stabilityDecay)`: Define parameters for reaching and maintaining different evolution levels.
20. `configureStimulusEffect(bytes memory stimulusType, int256 energyDelta, int256 stabilityDelta, uint256 cost)`: Define how a specific stimulus type impacts core energy and stability, and its cost.
21. `configureMutationEffect(bytes memory mutationType, bytes memory effectData)`: Define the parameters or rules for applying a specific mutation type (effectData opaque `bytes`).
22. `configureMergeEffect(bytes memory mergeType, bytes memory effectData)`: Define the parameters or rules for merging cores (effectData opaque `bytes`).
23. `configureTraitAcquisitionCondition(uint256 traitId, string memory name, string memory description, bytes memory conditionData)`: Define a new trait and the conditions required for a core to acquire it (conditionData opaque `bytes`).
24. `setGlobalStimulusCooldown(uint256 cooldown)`: Set a minimum time required between applying stimuli to any core.
25. `setCoreSpecificCooldown(uint256 coreId, uint256 cooldown)`: Set a custom minimum time required between stimuli for a specific core (overrides global).
26. `setTraitRemovalPenalty(uint256 traitId, uint256 penaltyAmount)`: Set the cost required to remove a specific trait.

**Utility & Views:**
27. `getTimeUntilStimulusAvailable(uint256 coreId)`: Calculates and returns the remaining cooldown time for stimulating a core.
28. `_checkTraitCondition(uint256 coreId, uint256 traitId)`: Internal helper function to evaluate if a core meets the condition for acquiring a trait (placeholder logic for `bytes` interpretation).
29. `_applyMutationEffect(uint256 coreId, bytes memory effectData)`: Internal helper to apply mutation effects based on `effectData` (placeholder logic for `bytes` interpretation).
30. `_applyMergeEffect(uint256 coreId1, uint256 coreId2, bytes memory effectData)`: Internal helper to apply merge effects based on `effectData` (placeholder logic for `bytes` interpretation).
*(Note: Functions 28-30 are internal helpers, not part of the public/external function count)*.

Total Public/External functions: 12 (ERC721Enumerable) + 16 (Custom Public/External) = 28 functions. This meets the requirement of at least 20 functions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary:
// Contract: GenesisNexus
// Purpose: Manages dynamic, evolving digital entities (Nexus Cores) as NFTs with complex mechanics.
// Inheritance: ERC721Enumerable, Ownable
// Data Structures: NexusCore, Trait, EvolutionParams, StimulusEffect, MutationEffect, MergeEffect, TraitCondition
// Mappings: _cores, _traits, _coreTraits, _evolutionParams, _stimulusEffects, _mutationEffects, _mergeEffects, _traitConditions, _coreSpecificCooldowns, _lastStimulusTime, _migrationFlagged
//
// Function Categories & Summaries:
// Lifecycle & Core Management (ERC721 + Custom):
// 1. constructor(): Initializes contract & ERC721.
// 2. createCore(address owner): Owner mints new core.
// 3. burnCore(uint256 coreId): Owner burns core.
// 4. flagCoreForMigration(uint256 coreId): Owner flags core for migration.
// 5. isCoreFlaggedForMigration(uint256 coreId): Checks migration flag.
//    + 12 ERC721Enumerable functions (balanceOf, ownerOf, transferFrom, etc.)
//
// State & Evolution:
// 6. getCoreDetails(uint256 coreId): View core data.
// 7. getCoreParameters(uint256 coreId): View core state (energy, stability, level).
// 8. stimulateCore(uint256 coreId, bytes memory stimulusData): Apply stimulus affecting state.
// 9. evolveCore(uint256 coreId): Attempt to evolve core level.
//
// Interaction:
// 10. interactCores(uint256 coreId1, uint256 coreId2): Interact two cores, affecting states.
//
// Mutation & Merge:
// 11. mutateCore(uint256 coreId, bytes memory mutationData): Mutate a core.
// 12. mergeCores(uint256 coreId1, uint256 coreId2, bytes memory mergeData): Merge two cores (burn inputs, potentially mint new).
//
// Traits:
// 13. getCoreTraits(uint256 coreId): View trait IDs for a core.
// 14. getTraitDetails(uint256 traitId): View details of a trait.
// 15. attemptTraitAcquisition(uint256 coreId, uint256 traitId): User tries to acquire trait if conditions met.
// 16. releaseTrait(uint256 coreId, uint256 traitId): Owner removes trait, potentially with penalty.
//
// Configuration (Owner Only):
// 17. setCoreName(uint256 coreId, string memory name): Set core metadata name.
// 18. configureEvolutionParams(uint256 level, uint256 requiredEnergy, uint256 requiredStability, uint256 energyDecay, uint256 stabilityDecay): Configure evolution levels.
// 19. configureStimulusEffect(bytes memory stimulusType, int256 energyDelta, int256 stabilityDelta, uint256 cost): Configure stimulus effects.
// 20. configureMutationEffect(bytes memory mutationType, bytes memory effectData): Configure mutation effects (data opaque).
// 21. configureMergeEffect(bytes memory mergeType, bytes memory effectData): Configure merge effects (data opaque).
// 22. configureTraitAcquisitionCondition(uint256 traitId, string memory name, string memory description, bytes memory conditionData): Define trait & acquisition conditions (data opaque).
// 23. setGlobalStimulusCooldown(uint256 cooldown): Set global stimulus cooldown.
// 24. setCoreSpecificCooldown(uint256 coreId, uint256 cooldown): Set per-core stimulus cooldown.
// 25. setTraitRemovalPenalty(uint256 traitId, uint256 penaltyAmount): Set penalty for trait removal.
//
// Utility & Views:
// 26. getTimeUntilStimulusAvailable(uint256 coreId): View remaining stimulus cooldown.
// (+ Internal helper functions for opaque data interpretation and condition checking)

contract GenesisNexus is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _coreIdCounter;
    Counters.Counter private _traitIdCounter;

    struct NexusCore {
        uint256 id;
        address owner;
        string name;
        uint256 creationTime;
        uint256 lastInteractionTime; // Tracks any significant interaction/stimulus
        int256 energy;
        int256 stability;
        uint256 evolutionLevel;
        // Add more parameters if needed
        mapping(uint256 => bool) acquiredTraits; // Using mapping for faster lookup
        uint256[] traitIds; // Store list for enumeration
    }

    struct Trait {
        uint256 id;
        string name;
        string description;
        uint256 acquisitionTime;
        // Traits are bound to the core, not owned directly
    }

    struct EvolutionParams {
        uint256 requiredEnergy;
        uint256 requiredStability;
        uint256 energyDecayPerBlock; // Example decay mechanic
        uint256 stabilityDecayPerBlock;
    }

    struct StimulusEffect {
        int256 energyDelta;
        int256 stabilityDelta;
        uint256 cost; // Cost in native currency (ETH)
    }

    // Opaque bytes for complex, potentially evolving logic or off-chain interpretation
    struct MutationEffect {
        bytes effectData; // Data defining mutation outcome
    }

    // Opaque bytes for complex merge outcomes
    struct MergeEffect {
        bytes effectData; // Data defining merge outcome
    }

    struct TraitCondition {
        string name;
        string description;
        bytes conditionData; // Data defining acquisition conditions (opaque bytes)
    }

    mapping(uint256 => NexusCore) private _cores;
    mapping(uint256 => Trait) private _traits;
    mapping(uint256 => uint256[]) private _coreTraitList; // Separate list to support getCoreTraits view

    mapping(uint256 => EvolutionParams) private _evolutionParams;
    mapping(bytes32 => StimulusEffect) private _stimulusEffects; // Hash stimulus type for mapping key
    mapping(bytes32 => MutationEffect) private _mutationEffects;
    mapping(bytes32 => MergeEffect) private _mergeEffects;
    mapping(uint256 => TraitCondition) private _traitConditions;

    mapping(uint256 => uint256) private _coreSpecificCooldowns; // Per core override
    uint256 private _globalStimulusCooldown;
    mapping(uint256 => uint256) private _lastStimulusTime; // Last time stimulated (any stimulus)

    mapping(uint256 => bool) private _migrationFlagged;

    mapping(uint256 => uint256) private _traitRemovalPenalties; // Penalty in native currency

    // Events
    event CoreCreated(uint256 indexed coreId, address indexed owner, string name);
    event CoreStimulated(uint256 indexed coreId, bytes stimulusType, int256 energyDelta, int256 stabilityDelta);
    event CoreEvolved(uint256 indexed coreId, uint256 oldLevel, uint256 newLevel);
    event CoresInteracted(uint256 indexed coreId1, uint256 indexed coreId2);
    event CoreMutated(uint256 indexed coreId, bytes mutationType);
    event CoresMerged(uint256 indexed coreId1, uint256 indexed coreId2, uint256 indexed newCoreId);
    event TraitAcquired(uint256 indexed coreId, uint256 indexed traitId);
    event TraitReleased(uint256 indexed coreId, uint256 indexed traitId);
    event CoreNameUpdated(uint256 indexed coreId, string newName);
    event CoreBurned(uint256 indexed coreId, address indexed owner);
    event CoreFlaggedForMigration(uint256 indexed coreId);
    event StimulusCooldownSet(uint256 indexed coreId, uint256 cooldown, bool isGlobal);
    event TraitRemovalPenaltySet(uint256 indexed traitId, uint256 penaltyAmount);

    constructor() ERC721Enumerable("Genesis Nexus", "GNX") Ownable(msg.sender) {
        _globalStimulusCooldown = 0; // Default no global cooldown
    }

    // --- Lifecycle & Core Management ---

    /// @notice Creates a new Genesis Core, minting an NFT to the owner. Owner only.
    /// @param owner The address to mint the core to.
    function createCore(address owner) public onlyOwner {
        _coreIdCounter.increment();
        uint256 newCoreId = _coreIdCounter.current();

        _cores[newCoreId] = NexusCore({
            id: newCoreId,
            owner: owner,
            name: string(abi.encodePacked("Genesis Core #", newCoreId.toString())),
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            energy: 0, // Initial state
            stability: 0, // Initial state
            evolutionLevel: 0, // Initial level
            acquiredTraits: new mapping(uint256 => bool)(),
            traitIds: new uint256[](0)
        });

        _mint(owner, newCoreId);

        emit CoreCreated(newCoreId, owner, _cores[newCoreId].name);
    }

    /// @notice Allows a core owner to burn (destroy) their core.
    /// @param coreId The ID of the core to burn.
    function burnCore(uint256 coreId) public {
        require(_exists(coreId), "Core does not exist");
        require(_isApprovedOrOwner(msg.sender, coreId), "Not authorized to burn core");

        address owner = ownerOf(coreId);

        // Optional: Add logic to distribute resources, penalties, etc.
        // e.g., refund some creation cost, or impose a penalty

        _burn(coreId);
        delete _cores[coreId];
        delete _coreTraitList[coreId]; // Clean up trait list mapping

        emit CoreBurned(coreId, owner);
    }

    /// @notice Allows the owner to flag a core, indicating it's ready for potential data migration.
    /// This doesn't move data, just flags it in this contract.
    /// @param coreId The ID of the core to flag.
    function flagCoreForMigration(uint256 coreId) public onlyOwner {
        require(_exists(coreId), "Core does not exist");
        _migrationFlagged[coreId] = true;
        emit CoreFlaggedForMigration(coreId);
    }

    /// @notice Checks if a core has been flagged for migration.
    /// @param coreId The ID of the core.
    /// @return True if the core is flagged for migration, false otherwise.
    function isCoreFlaggedForMigration(uint256 coreId) public view returns (bool) {
        return _migrationFlagged[coreId];
    }

    // --- State & Evolution ---

    /// @notice Gets all primary details for a given core.
    /// @param coreId The ID of the core.
    /// @return coreDetails A tuple containing all core information.
    function getCoreDetails(uint256 coreId) public view returns (
        uint256 id,
        address owner,
        string memory name,
        uint256 creationTime,
        uint256 lastInteractionTime,
        int256 energy,
        int256 stability,
        uint256 evolutionLevel
    ) {
        require(_exists(coreId), "Core does not exist");
        NexusCore storage core = _cores[coreId];
        return (
            core.id,
            core.owner, // Note: owner is dynamic via ERC721
            core.name,
            core.creationTime,
            core.lastInteractionTime,
            core.energy,
            core.stability,
            core.evolutionLevel
        );
    }

    /// @notice Gets just the current state parameters (energy, stability, level) for a core.
    /// @param coreId The ID of the core.
    /// @return energy The current energy.
    /// @return stability The current stability.
    /// @return evolutionLevel The current evolution level.
    function getCoreParameters(uint256 coreId) public view returns (int256 energy, int256 stability, uint256 evolutionLevel) {
         require(_exists(coreId), "Core does not exist");
         NexusCore storage core = _cores[coreId];
         return (core.energy, core.stability, core.evolutionLevel);
    }


    /// @notice Applies a stimulus to a core, changing its state based on configuration and paying a cost.
    /// Subject to cooldowns.
    /// @param coreId The ID of the core to stimulate.
    /// @param stimulusData Data identifying the type and perhaps intensity of the stimulus (opaque bytes).
    function stimulateCore(uint256 coreId, bytes memory stimulusData) public payable {
        require(_exists(coreId), "Core does not exist");

        // Cooldown check
        uint256 coreCooldown = _coreSpecificCooldowns[coreId];
        uint256 effectiveCooldown = coreCooldown > 0 ? coreCooldown : _globalStimulusCooldown;
        require(block.timestamp >= _lastStimulusTime[coreId] + effectiveCooldown, "Stimulus cooldown active");

        bytes32 stimulusTypeHash = keccak256(stimulusData);
        StimulusEffect storage effect = _stimulusEffects[stimulusTypeHash];
        require(effect.cost > 0 || msg.value == 0, "Stimulus type not configured or cost mismatch"); // Ensure stimulus type is configured (cost != 0 implies configured)
        require(msg.value >= effect.cost, "Insufficient payment for stimulus");

        // Send payment to owner
        if (effect.cost > 0) {
            (bool success, ) = owner().call{value: effect.cost}("");
            require(success, "Payment transfer failed");
        }

        NexusCore storage core = _cores[coreId];

        // Apply effects
        core.energy += effect.energyDelta;
        core.stability += effect.stabilityDelta;

        // Optional: Clamp parameters within bounds
        // core.energy = max(min(core.energy, MAX_ENERGY), MIN_ENERGY);
        // core.stability = max(min(core.stability, MAX_STABILITY), MIN_STABILITY);

        core.lastInteractionTime = block.timestamp;
        _lastStimulusTime[coreId] = block.timestamp;

        emit CoreStimulated(coreId, stimulusData, effect.energyDelta, effect.stabilityDelta);
    }

    /// @notice Attempts to evolve a core to the next evolution level.
    /// Requires meeting energy and stability thresholds defined in evolution parameters. Consumes state.
    /// @param coreId The ID of the core to evolve.
    function evolveCore(uint256 coreId) public {
        require(_isApprovedOrOwner(msg.sender, coreId), "Not authorized to evolve core");

        NexusCore storage core = _cores[coreId];
        uint256 currentLevel = core.evolutionLevel;
        uint256 nextLevel = currentLevel + 1;

        EvolutionParams storage params = _evolutionParams[nextLevel];
        require(params.requiredEnergy > 0 || params.requiredStability > 0, "Evolution params not configured for next level"); // Check if next level is configured

        // Apply decay based on time since last interaction (example mechanic)
        uint256 blocksPassed = (block.timestamp - core.lastInteractionTime) / 12; // Approx blocks per second
        core.energy -= int256(blocksPassed * params.energyDecayPerBlock);
        core.stability -= int256(blocksPassed * params.stabilityDecayPerBlock);
        core.lastInteractionTime = block.timestamp; // Reset interaction time after decay calculation

        require(uint256(core.energy) >= params.requiredEnergy && uint256(core.stability) >= params.requiredStability, "Core does not meet evolution requirements");

        // Consume state for evolution (example)
        core.energy -= int256(params.requiredEnergy);
        core.stability -= int256(params.requiredStability);

        core.evolutionLevel = nextLevel;

        emit CoreEvolved(coreId, currentLevel, nextLevel);
    }

    // --- Interaction ---

    /// @notice Initiates interaction between two cores. Affects their states and may trigger other effects.
    /// Requires ownership or approval for both cores.
    /// @param coreId1 The ID of the first core.
    /// @param coreId2 The ID of the second core.
    function interactCores(uint256 coreId1, uint256 coreId2) public {
        require(_exists(coreId1), "Core 1 does not exist");
        require(_exists(coreId2), "Core 2 does not exist");
        require(coreId1 != coreId2, "Cannot interact a core with itself");
        require(_isApprovedOrOwner(msg.sender, coreId1), "Not authorized for core 1");
        require(_isApprovedOrOwner(msg.sender, coreId2), "Not authorized for core 2");
        // Add more complex interaction rules (e.g., range, compatibility based on state)

        NexusCore storage core1 = _cores[coreId1];
        NexusCore storage core2 = _cores[coreId2];

        // Example interaction effect: exchange some state
        int256 energyTransfer = core1.energy / 10;
        int256 stabilityTransfer = core2.stability / 10;

        core1.energy -= energyTransfer;
        core2.energy += energyTransfer;

        core2.stability -= stabilityTransfer;
        core1.stability += stabilityTransfer;

        core1.lastInteractionTime = block.timestamp;
        core2.lastInteractionTime = block.timestamp;

        // Optional: Trigger trait acquisition based on interaction outcome/state
        // _attemptAcquireTraitInternal(coreId1, ...);
        // _attemptAcquireTraitInternal(coreId2, ...);

        emit CoresInteracted(coreId1, coreId2);
    }

    // --- Mutation & Merge ---

    /// @notice Applies a mutation process to a core, drastically altering its parameters based on configuration.
    /// Requires ownership/approval and potentially resources.
    /// @param coreId The ID of the core to mutate.
    /// @param mutationData Data identifying the type of mutation and its parameters (opaque bytes).
    function mutateCore(uint256 coreId, bytes memory mutationData) public payable {
        require(_isApprovedOrOwner(msg.sender, coreId), "Not authorized to mutate core");
        require(_exists(coreId), "Core does not exist");

        bytes32 mutationTypeHash = keccak256(mutationData);
        MutationEffect storage effect = _mutationEffects[mutationTypeHash];
        require(effect.effectData.length > 0, "Mutation type not configured"); // Check if mutation type is configured

        // Optional: Add cost requirement like stimulateCore
        // require(msg.value >= effect.cost, "Insufficient payment for mutation");
        // (bool success, ) = owner().call{value: effect.cost}(""); require(success, "Payment transfer failed");

        _applyMutationEffect(coreId, effect.effectData); // Apply the effect (implementation depends on effectData structure)

        _cores[coreId].lastInteractionTime = block.timestamp;

        emit CoreMutated(coreId, mutationData);
    }

    /// @notice Merges two cores into potentially a new entity. Burns the original cores.
    /// Requires ownership/approval of both cores. Outcome based on configuration.
    /// @param coreId1 The ID of the first core to merge.
    /// @param coreId2 The ID of the second core to merge.
    /// @param mergeData Data identifying the type of merge and its parameters (opaque bytes).
    /// @return newCoreId The ID of the newly created core, or 0 if merge results in no new core.
    function mergeCores(uint256 coreId1, uint256 coreId2, bytes memory mergeData) public returns (uint256 newCoreId) {
        require(_exists(coreId1), "Core 1 does not exist");
        require(_exists(coreId2), "Core 2 does not exist");
        require(coreId1 != coreId2, "Cannot merge a core with itself");
        require(_isApprovedOrOwner(msg.sender, coreId1), "Not authorized for core 1");
        require(_isApprovedOrOwner(msg.sender, coreId2), "Not authorized for core 2");

        bytes32 mergeTypeHash = keccak256(mergeData);
        MergeEffect storage effect = _mergeEffects[mergeTypeHash];
        require(effect.effectData.length > 0, "Merge type not configured"); // Check if merge type is configured

        address originalOwner = ownerOf(coreId1); // Assuming same owner for both for simplicity, or require ownerOf(coreId1) == ownerOf(coreId2)

        // Burn the original cores
        _burn(coreId1);
        _burn(coreId2);
        delete _cores[coreId1];
        delete _cores[coreId2];
        delete _coreTraitList[coreId1];
        delete _coreTraitList[coreId2];

        // Apply merge effect - this might create a new core
        newCoreId = _applyMergeEffect(coreId1, coreId2, effect.effectData); // Apply the effect (implementation depends on effectData)

        emit CoresMerged(coreId1, coreId2, newCoreId);
        return newCoreId;
    }


    // --- Traits (Soulbound-like) ---

    /// @notice Gets the list of trait IDs acquired by a specific core.
    /// @param coreId The ID of the core.
    /// @return An array of trait IDs.
    function getCoreTraits(uint256 coreId) public view returns (uint256[] memory) {
        require(_exists(coreId), "Core does not exist");
        return _coreTraitList[coreId];
    }

    /// @notice Gets the details of a specific trait.
    /// @param traitId The ID of the trait.
    /// @return name The trait's name.
    /// @return description The trait's description.
    function getTraitDetails(uint256 traitId) public view returns (string memory name, string memory description) {
        require(_traits[traitId].id != 0, "Trait does not exist");
        Trait storage trait = _traits[traitId];
        return (trait.name, trait.description);
    }

    /// @notice Allows the core owner to attempt to acquire a trait if the core meets the conditions.
    /// @param coreId The ID of the core.
    /// @param traitId The ID of the trait to acquire.
    function attemptTraitAcquisition(uint256 coreId, uint256 traitId) public {
        require(_isApprovedOrOwner(msg.sender, coreId), "Not authorized for core");
        require(_exists(coreId), "Core does not exist");
        require(_traitConditions[traitId].conditionData.length > 0, "Trait condition not configured"); // Check if trait exists and has condition

        NexusCore storage core = _cores[coreId];
        require(!core.acquiredTraits[traitId], "Core already has this trait");

        require(_checkTraitCondition(coreId, traitId), "Core does not meet trait acquisition conditions");

        _acquireTrait(coreId, traitId); // Internal function to add the trait
    }

    /// @notice Allows the core owner to release (remove) a trait from their core.
    /// May require payment of a penalty.
    /// @param coreId The ID of the core.
    /// @param traitId The ID of the trait to release.
    function releaseTrait(uint256 coreId, uint256 traitId) public payable {
        require(_isApprovedOrOwner(msg.sender, coreId), "Not authorized for core");
        require(_exists(coreId), "Core does not exist");
        NexusCore storage core = _cores[coreId];
        require(core.acquiredTraits[traitId], "Core does not have this trait");

        uint256 penalty = _traitRemovalPenalties[traitId];
        require(msg.value >= penalty, "Insufficient payment for trait removal");

        // Send penalty to owner
        if (penalty > 0) {
             (bool success, ) = owner().call{value: penalty}("");
             require(success, "Penalty payment transfer failed");
        }

        // Remove trait from core
        core.acquiredTraits[traitId] = false;

        // Find and remove from the traitIds list
        uint256[] storage traitList = _coreTraitList[coreId];
        for (uint256 i = 0; i < traitList.length; i++) {
            if (traitList[i] == traitId) {
                // Replace with last element and pop
                traitList[i] = traitList[traitList.length - 1];
                traitList.pop();
                break; // Assuming trait can only be acquired once
            }
        }

        emit TraitReleased(coreId, traitId);
    }

    /// @dev Internal function to add a trait to a core.
    /// @param coreId The ID of the core.
    /// @param traitId The ID of the trait.
    function _acquireTrait(uint256 coreId, uint256 traitId) internal {
        require(_exists(coreId), "Core does not exist");
        require(_traitConditions[traitId].conditionData.length > 0, "Trait does not exist"); // Check if trait exists
        NexusCore storage core = _cores[coreId];
        require(!core.acquiredTraits[traitId], "Core already has this trait");

        core.acquiredTraits[traitId] = true;
        _coreTraitList[coreId].push(traitId); // Add to list for enumeration

        // Update trait acquisition time if needed (trait struct currently doesn't track this per core)
        // If needed, Trait struct would need to map coreId to acquisition time, or store per core.
        // For simplicity, Trait struct stores global definition, not core-specific instance data.

        emit TraitAcquired(coreId, traitId);
    }


    // --- Configuration (Owner Only) ---

    /// @notice Sets the name metadata for a specific core. Owner only.
    /// @param coreId The ID of the core.
    /// @param name The new name for the core.
    function setCoreName(uint256 coreId, string memory name) public onlyOwner {
        require(_exists(coreId), "Core does not exist");
        _cores[coreId].name = name;
        emit CoreNameUpdated(coreId, name);
    }

    /// @notice Configures the parameters required for a core to reach a specific evolution level. Owner only.
    /// @param level The evolution level being configured.
    /// @param requiredEnergy The minimum energy required for this level.
    /// @param requiredStability The minimum stability required for this level.
    /// @param energyDecayPerBlock The rate at which energy decays per approx block at this level.
    /// @param stabilityDecayPerBlock The rate at which stability decays per approx block at this level.
    function configureEvolutionParams(uint256 level, uint256 requiredEnergy, uint256 requiredStability, uint256 energyDecayPerBlock, uint256 stabilityDecayPerBlock) public onlyOwner {
        _evolutionParams[level] = EvolutionParams({
            requiredEnergy: requiredEnergy,
            requiredStability: requiredStability,
            energyDecayPerBlock: energyDecayPerBlock,
            stabilityDecayPerBlock: stabilityDecayPerBlock
        });
    }

    /// @notice Configures the effect of a specific stimulus type on core parameters and its cost. Owner only.
    /// @param stimulusType Opaque bytes identifying the stimulus type.
    /// @param energyDelta Change in energy.
    /// @param stabilityDelta Change in stability.
    /// @param cost Cost in native currency to apply this stimulus.
    function configureStimulusEffect(bytes memory stimulusType, int256 energyDelta, int256 stabilityDelta, uint256 cost) public onlyOwner {
         bytes32 stimulusTypeHash = keccak256(stimulusType);
        _stimulusEffects[stimulusTypeHash] = StimulusEffect({
            energyDelta: energyDelta,
            stabilityDelta: stabilityDelta,
            cost: cost
        });
    }

    /// @notice Configures the effect of a specific mutation type. Owner only.
    /// @param mutationType Opaque bytes identifying the mutation type.
    /// @param effectData Opaque bytes defining the mutation outcome (interpreted by _applyMutationEffect).
    function configureMutationEffect(bytes memory mutationType, bytes memory effectData) public onlyOwner {
        bytes32 mutationTypeHash = keccak256(mutationType);
        _mutationEffects[mutationTypeHash] = MutationEffect({
            effectData: effectData
        });
    }

    /// @notice Configures the effect of a specific merge type. Owner only.
    /// @param mergeType Opaque bytes identifying the merge type.
    /// @param effectData Opaque bytes defining the merge outcome (interpreted by _applyMergeEffect).
    function configureMergeEffect(bytes memory mergeType, bytes memory effectData) public onlyOwner {
        bytes32 mergeTypeHash = keccak256(mergeType);
        _mergeEffects[mergeTypeHash] = MergeEffect({
            effectData: effectData
        });
    }

    /// @notice Defines a new trait and the conditions required for a core to acquire it. Owner only.
    /// @param traitId The ID for the new trait.
    /// @param name The name of the trait.
    /// @param description The description of the trait.
    /// @param conditionData Opaque bytes defining the acquisition conditions (interpreted by _checkTraitCondition).
    function configureTraitAcquisitionCondition(uint256 traitId, string memory name, string memory description, bytes memory conditionData) public onlyOwner {
         // Ensure traitId is higher than last auto-assigned ID if using counter elsewhere for traits
        if (_traits[traitId].id != 0) {
             // Update existing trait
        } else {
            // Create new trait definition
             _traits[traitId] = Trait({
                id: traitId,
                name: name,
                description: description,
                acquisitionTime: 0 // This field is unused here as Traits are global definitions
             });
        }

        _traitConditions[traitId] = TraitCondition({
            name: name, // Redundant storage, but convenient
            description: description, // Redundant storage, but convenient
            conditionData: conditionData
        });
    }

    /// @notice Sets the global minimum cooldown period between stimulating any core. Owner only.
    /// @param cooldown The new global cooldown duration in seconds.
    function setGlobalStimulusCooldown(uint256 cooldown) public onlyOwner {
        _globalStimulusCooldown = cooldown;
        emit StimulusCooldownSet(0, cooldown, true); // Core ID 0 for global
    }

    /// @notice Sets a specific minimum cooldown period between stimulating a particular core. Owner only.
    /// Overrides the global cooldown for this core. Set to 0 to revert to global.
    /// @param coreId The ID of the core.
    /// @param cooldown The new specific cooldown duration in seconds (0 to use global).
    function setCoreSpecificCooldown(uint256 coreId, uint256 cooldown) public onlyOwner {
        require(_exists(coreId), "Core does not exist");
        _coreSpecificCooldowns[coreId] = cooldown;
        emit StimulusCooldownSet(coreId, cooldown, false);
    }

    /// @notice Sets the cost required to remove a specific trait from a core. Owner only.
    /// @param traitId The ID of the trait.
    /// @param penaltyAmount The cost in native currency to remove the trait.
    function setTraitRemovalPenalty(uint256 traitId, uint256 penaltyAmount) public onlyOwner {
        _traitRemovalPenalties[traitId] = penaltyAmount;
        emit TraitRemovalPenaltySet(traitId, penaltyAmount);
    }


    // --- Utility & Views ---

    /// @notice Calculates the time remaining until a core can be stimulated again.
    /// Returns 0 if no cooldown is active or time has passed.
    /// @param coreId The ID of the core.
    /// @return The remaining cooldown time in seconds.
    function getTimeUntilStimulusAvailable(uint256 coreId) public view returns (uint256) {
        // No require _exists for potential future/burned cores having last stimulus data
        uint256 lastTime = _lastStimulusTime[coreId];
        if (lastTime == 0) {
            return 0; // Never stimulated or data cleared
        }
        uint256 coreCooldown = _coreSpecificCooldowns[coreId];
        uint256 effectiveCooldown = coreCooldown > 0 ? coreCooldown : _globalStimulusCooldown;
        uint256 nextAvailableTime = lastTime + effectiveCooldown;

        if (block.timestamp >= nextAvailableTime) {
            return 0; // Cooldown expired
        } else {
            return nextAvailableTime - block.timestamp;
        }
    }

    // --- Internal Helpers for Opaque Logic ---

    /// @dev Internal helper to check if a core meets the conditions for acquiring a trait.
    /// The implementation here is a placeholder. Real logic would interpret `conditionData`.
    /// Example: `conditionData` could encode minimum level or minimum energy.
    /// @param coreId The ID of the core.
    /// @param traitId The ID of the trait.
    /// @return True if the conditions are met, false otherwise.
    function _checkTraitCondition(uint256 coreId, uint256 traitId) internal view returns (bool) {
        TraitCondition storage condition = _traitConditions[traitId];
        // Example placeholder logic: conditionData is a simple check for min level encoded as bytes(uint256)
        if (condition.conditionData.length == 32) {
             uint256 requiredLevel = abi.decode(condition.conditionData, (uint256));
             return _cores[coreId].evolutionLevel >= requiredLevel;
        }
        // Default: conditions not met if data is not understood or empty
        return false;
    }

    /// @dev Internal helper to apply mutation effects to a core.
    /// The implementation here is a placeholder. Real logic would interpret `effectData`.
    /// Example: `effectData` could encode a random parameter roll within a range.
    /// @param coreId The ID of the core.
    /// @param effectData Opaque bytes defining the mutation outcome.
    function _applyMutationEffect(uint256 coreId, bytes memory effectData) internal {
        NexusCore storage core = _cores[coreId];
        // Example placeholder logic: effectData adds a fixed amount to energy and stability
        if (effectData.length == 64) { // abi.encode(int256, int256)
            (int256 energyChange, int256 stabilityChange) = abi.decode(effectData, (int256, int256));
            core.energy += energyChange;
            core.stability += stabilityChange;
        }
        // Add more complex interpretation logic here...
    }

     /// @dev Internal helper to apply merge effects and potentially create a new core.
     /// The implementation here is a placeholder. Real logic would interpret `effectData`.
     /// Example: `effectData` could define how parameters from core1 and core2 combine into a new core.
     /// @param coreId1 The ID of the first merged core (already burned).
     /// @param coreId2 The ID of the second merged core (already burned).
     /// @param effectData Opaque bytes defining the merge outcome.
     /// @return The ID of the newly created core, or 0 if no core is created.
    function _applyMergeEffect(uint256 coreId1, uint256 coreId2, bytes memory effectData) internal returns (uint256 newCoreId) {
        // Placeholder: Example logic to create a new core with averaged parameters
        // This needs access to the *burned* core data if it's not already in memory or deleted.
        // For a real implementation, you'd need to read state *before* burning, or pass relevant data.
        // As `_cores[coreId]` is deleted, this example assumes `effectData` contains sufficient info
        // or this function is called BEFORE deleting state, or state is read from a temporary store.

        // Let's assume effectData somehow encodes params for the new core based on the inputs.
        // Example: effectData = abi.encode(initialEnergy, initialStability, initialLevel, ownerAddress)

        if (effectData.length > 0) {
             // Placeholder - decode and create new core.
             // In reality, this logic is complex and depends heavily on the game design.
             // This could be a factory pattern calling another contract, or internal minting.

             // Example: Basic new core creation
            _coreIdCounter.increment();
            newCoreId = _coreIdCounter.current();
            address newOwner = msg.sender; // Or derive from mergeData

            _cores[newCoreId] = NexusCore({
                id: newCoreId,
                owner: newOwner,
                name: string(abi.encodePacked("Merged Core #", newCoreId.toString())),
                creationTime: block.timestamp,
                lastInteractionTime: block.timestamp,
                energy: 100, // Example derived initial value
                stability: 100, // Example derived initial value
                evolutionLevel: 1, // Example derived initial level
                acquiredTraits: new mapping(uint256 => bool)(),
                traitIds: new uint256[](0)
            });

             _mint(newOwner, newCoreId);
             emit CoreCreated(newCoreId, newOwner, _cores[newCoreId].name);

            return newCoreId;
        }

        return 0; // No new core created by this merge effect
    }

    // The following functions are overrides required by Solidity.
    // They simply delegate to the internal _cores mapping for ERC721 functionality.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        // Update the owner in our custom struct during transfers/mints/burns
        if (_cores[tokenId].id != 0) { // Check if core exists (it won't for burning or before minting)
             _cores[tokenId].owner = to;
        }
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

     function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```