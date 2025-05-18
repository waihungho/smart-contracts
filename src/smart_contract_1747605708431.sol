Okay, let's design a smart contract concept that embodies interesting, advanced, creative, and trendy aspects without directly copying existing open-source patterns like standard ERC20/721 extensions, basic staking, or typical DeFi primitives.

We'll create a contract managing a dynamic, on-chain "Synthescape" – a digital ecosystem where entities (Synthetids) interact with environmental factors (Resonances) and undergo changes based on time, interactions, and potentially catalysts. This involves dynamic state, simulations, entity-to-entity interaction, and environmental effects.

**Concept: Synthescape**

A decentralized ecosystem where users can deploy and cultivate *Synthetids* (dynamic NFTs) influenced by *Resonances* (environmental factors) and *Catalysts*. Synthetids have internal states (health, energy, mutation progress) that change over time and through interactions.

**Core Components:**

1.  **Synthetids (ERC721):** Each is a unique NFT representing an entity. Their state (`health`, `energy`, `mutationProgress`, `lastStateUpdateTime`) is dynamic. They belong to specific `SynthetidType`s which define base properties and potential.
2.  **Resonances:** Represent environmental influences. Instances (`ResonanceInstance`) are deployed and can affect specific Synthetids or the overall Synthescape for a duration or amount. They belong to `ResonanceType`s defining their effects.
3.  **Catalysts:** Special items or actions that can trigger specific events like accelerated mutation, state boosts, or unique interactions. (Represented by types and functions that consume an abstract "catalyst charge" or ID).
4.  **Synthescape Parameters:** Global settings that influence decay rates, interaction outcomes, mutation probabilities, etc. Can potentially change over time (Epochs).
5.  **Time Progression:** State of Synthetids decays over time since their `lastStateUpdateTime`. Interactions and Resonance effects update this time.

**Outline:**

*   **Metadata:** SPDL-License, Solidity Version, Imports.
*   **Error Definitions:** Custom errors for clarity.
*   **State Variables:** Mappings for Synthetids, Resonances, Types, Counters, Global Parameters.
*   **Structs:** `SynthetidType`, `SynthetidInstance`, `ResonanceType`, `ResonanceInstance`, `CatalystType`.
*   **Enums:** For effect types, interaction outcomes, affinity types.
*   **Events:** For creation, state changes, interactions, mutations, etc.
*   **Modifiers:** Ownable, State checks.
*   **Constructor:** Initialize contract, set owner.
*   **Admin Functions:** Register Types, Set Global Parameters, Trigger Epochs.
*   **Core Logic Functions:** Deploy Synthetids/Resonances, Apply Resonances, Interact Synthetids, Feed/Maintain Synthetids, Trigger Mutation, Apply Catalysts.
*   **Query Functions:** Get state of entities, list entities, simulate future state, query interaction outcomes, query global parameters.
*   **Internal Helper Functions:** Calculate dynamic state, apply effects, handle interactions, generate pseudo-randomness.

**Function Summary (at least 20):**

1.  `constructor()`: Initializes the contract, ERC721, and sets the owner.
2.  `registerSynthetidType(string calldata name, uint256 baseDecayRate, uint256 baseEnergyYield, uint256 baseMutationPotential)`: (Admin) Defines a new type of Synthetid with base characteristics.
3.  `getSynthetidType(uint256 typeId) view`: Queries the parameters of a registered Synthetid type.
4.  `registerResonanceType(string calldata name, ResonanceEffectType effectType, uint256 strength, uint256 durationOrAmount, AffinityType affinity) view`: (Admin) Defines a new type of environmental Resonance.
5.  `getResonanceType(uint256 typeId) view`: Queries the parameters of a registered Resonance type.
6.  `registerCatalystType(string calldata name, CatalystEffectType effectType, uint256 strength, uint256 uses) view`: (Admin) Defines a new type of Catalyst.
7.  `getCatalystType(uint256 typeId) view`: Queries the parameters of a registered Catalyst type.
8.  `setSynthescapeParameter(bytes32 paramName, uint256 value) view`: (Admin) Sets a global parameter influencing ecosystem dynamics (e.g., global decay multiplier, interaction probability modifier).
9.  `getSynthescapeParameter(bytes32 paramName) view`: Queries a global Synthescape parameter.
10. `deploySynthetid(uint256 synthetidTypeId) payable`: Mints a new Synthetid NFT of a specific type for the caller, initializing its dynamic state. Requires payment.
11. `getSynthetidState(uint256 synthetidId) view`: Queries the *current* dynamic state (health, energy, mutation progress, etc.) of a specific Synthetid, calculating decay/effects since the last update.
12. `listUserSynthetids(address user) view`: Returns a list of Synthetid IDs owned by a specific address.
13. `deployResonance(uint256 resonanceTypeId, uint256 targetSynthetidId)`: Creates an instance of a Resonance type, potentially targeting a specific Synthetid. Requires payment.
14. `getResonanceState(uint256 resonanceId) view`: Queries the state of a specific Resonance instance (type, target, creation time, remaining duration/amount).
15. `listActiveResonances() view`: Returns a list of all currently active Resonance instance IDs.
16. `applyResonanceToSynthetid(uint256 resonanceId, uint256 synthetidId)`: Manually applies the effect of a deployed Resonance instance to a Synthetid (if not auto-applied), consuming its duration/amount and updating the Synthetid state.
17. `feedSynthetid(uint256 synthetidId, uint256 energyAmount)`: Provides "energy" to a Synthetid, increasing its energy state and updating its last state time. Requires payment or consuming a resource token (simplified to payment for this example).
18. `triggerSynthetidInteraction(uint256 synthetidId1, uint256 synthetidId2)`: Triggers an interaction between two Synthetids. The outcome depends on their types, states, active resonances, global parameters, and pseudo-randomness. Updates both Synthetids' states.
19. `queryInteractionOutcome(uint256 synthetidId1, uint256 synthetidId2) view`: Predicts the *likely* outcome of an interaction *without* changing state. Useful for users planning actions. Uses a deterministic simulation.
20. `mutateSynthetid(uint256 synthetidId, uint256 catalystTypeId)`: Attempts to mutate a Synthetid. Success probability depends on mutation progress, active resonances, catalyst type, and pseudo-randomness. A successful mutation might change its type or traits. Consumes a catalyst "charge".
21. `queryMutationPotential(uint256 synthetidId) view`: Queries the current probability and potential outcomes of mutation for a Synthetid based on its state and environment.
22. `triggerEpochTransition() view`: (Admin/Timed) Advances the Synthescape to the next epoch. This could trigger global events, change parameters, or cause global state updates/decay checks. (Simplified implementation: just updates epoch counter, actual effects triggered by interactions/queries).
23. `getCurrentEpoch() view`: Queries the current Synthescape epoch number.
24. `simulateSynthetidFutureState(uint256 synthetidId, uint256 timeDelta) view`: Projects the state of a Synthetid `timeDelta` blocks/seconds into the future, considering decay and current active resonances (but not future interactions).
25. `harvestSynthetid(uint256 synthetidId)`: Extracts a resource or value from a Synthetid. This might consume the Synthetid, reduce its state significantly, or yield a new token/value. (Simplified: yields native token and resets energy).
26. `queryEffectiveSynthetidDecayRate(uint256 synthetidId) view`: Calculates the Synthetid's current decay rate considering its type, active resonances, and global parameters.
27. `getSynthetidsByAffinity(AffinityType affinity) view`: Returns a list of Synthetids whose types have a specific affinity, potentially making them susceptible to certain resonances or interactions.
28. `querySynthescapeSummary() view`: Provides a high-level summary of the ecosystem state (total alive synthetids, number of active resonances, current epoch).
29. `updateSynthetidStateInternal(uint256 synthetidId) internal`: Internal helper to calculate and update a Synthetid's state based on elapsed time and active effects. Called by other functions before performing core logic.
30. `_pseudoRandomUint(uint256 seed) internal view`: Internal helper for generating a simple non-secure pseudo-random number based on block data and a seed. **NOTE: This is NOT cryptographically secure and should not be used for high-value outcomes in production.**

This set includes administrative, core logic, query/simulation, and internal functions, exceeding the 20-function requirement and covering the outlined concepts.

```solidity
// SPDX-License-Identifier: SPDL-License
// This smart contract is provided under the SPDL-License, a custom non-standard license.
// Please consult the SPDL-License file or SPDX-License-Identifier definition for details.
// Generally, it permits non-commercial use with attribution, and requires separate licensing
// for commercial applications. This is a creative license choice for a creative contract.

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline ---
// 1. Metadata (License, Pragma, Imports)
// 2. Error Definitions
// 3. Enums
// 4. Structs (SynthetidType, SynthetidInstance, ResonanceType, ResonanceInstance, CatalystType)
// 5. State Variables (Counters, Mappings, Global Params, Epoch)
// 6. Events
// 7. Modifiers
// 8. Constructor
// 9. Internal Helper Functions (State calculation, Randomness - UNSAFE)
// 10. Admin Functions (Register Types, Set Global Params, Trigger Epoch)
// 11. Core Logic Functions (Deploy, Interact, Feed, Mutate, Apply, Harvest)
// 12. Query Functions (Get state, list, simulate, predict)
// 13. Inherited ERC721 Functions (implicit)

// --- Function Summary ---
// - constructor(): Initializes contract, ERC721, owner.
// - registerSynthetidType(params): Admin: Defines a new Synthetid type.
// - getSynthetidType(typeId): Query: Gets Synthetid type details.
// - registerResonanceType(params): Admin: Defines a new Resonance type.
// - getResonanceType(typeId): Query: Gets Resonance type details.
// - registerCatalystType(params): Admin: Defines a new Catalyst type.
// - getCatalystType(typeId): Query: Gets Catalyst type details.
// - setSynthescapeParameter(name, value): Admin: Sets global ecosystem parameter.
// - getSynthescapeParameter(name): Query: Gets global parameter value.
// - deploySynthetid(typeId): Core: Mints a new Synthetid NFT for msg.sender.
// - getSynthetidState(synthetidId): Query: Gets the *current* dynamic state of a Synthetid (calculating decay/effects).
// - listUserSynthetids(user): Query: Lists Synthetids owned by an address.
// - deployResonance(typeId, targetId): Core: Creates a Resonance instance, potentially targeting a Synthetid.
// - getResonanceState(resonanceId): Query: Gets the state of a Resonance instance.
// - listActiveResonances(): Query: Lists all active Resonance instance IDs.
// - applyResonanceToSynthetid(resonanceId, synthetidId): Core: Manually applies a Resonance effect to a Synthetid.
// - feedSynthetid(synthetidId, energyAmount): Core: Adds energy to a Synthetid.
// - triggerSynthetidInteraction(id1, id2): Core: Executes interaction between two Synthetids.
// - queryInteractionOutcome(id1, id2): Query: Predicts interaction outcome without state change.
// - mutateSynthetid(synthetidId, catalystTypeId): Core: Attempts to mutate a Synthetid using a Catalyst.
// - queryMutationPotential(synthetidId): Query: Checks mutation probability/outcomes for a Synthetid.
// - triggerEpochTransition(): Admin/System: Advances the Synthescape epoch.
// - getCurrentEpoch(): Query: Gets the current epoch number.
// - simulateSynthetidFutureState(id, timeDelta): Query: Projects a Synthetid's state into the future.
// - harvestSynthetid(synthetidId): Core: Extracts value/resource from a Synthetid.
// - queryEffectiveSynthetidDecayRate(synthetidId): Query: Calculates current decay rate with effects.
// - getSynthetidsByAffinity(affinity): Query: Finds Synthetids by affinity type.
// - querySynthescapeSummary(): Query: Provides high-level ecosystem summary.
// - updateSynthetidStateInternal(id): Internal: Helper to calculate and update state based on time/effects.
// - _pseudoRandomUint(seed): Internal: Helper for insecure pseudo-randomness.
// - Plus standard ERC721 functions (transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, balanceOf, ownerOf, totalSupply, tokenURI).

contract Synthescape is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Error Definitions ---
    error Synthescape__SynthetidNotFound(uint256 synthetidId);
    error Synthescape__ResonanceNotFound(uint256 resonanceId);
    error Synthescape__SynthetidTypeNotFound(uint256 typeId);
    error Synthescape__ResonanceTypeNotFound(uint256 typeId);
    error Synthescape__CatalystTypeNotFound(uint256 typeId);
    error Synthescape__SynthetidNotOwned(uint256 synthetidId);
    error Synthescape__NotActiveResonance(uint256 resonanceId);
    error Synthescape__ResonanceExpired(uint256 resonanceId);
    error Synthescape__SynthetidNotAlive(uint256 synthetidId);
    error Synthescape__InteractionConditionsNotMet();
    error Synthescape__MutationConditionsNotMet();
    error Synthescape__InsufficientCatalystCharge(uint256 catalystTypeId);
    error Synthescape__InvalidTargetForResonance();
    error Synthescape__HarvestConditionsNotMet();
    error Synthescape__PaymentRequired();
    error Synthescape__InvalidParameterName();
    error Synthescape__OnlyOwnerAllowed(); // Inherited from Ownable, but good to list.

    // --- Enums ---
    enum AffinityType { None, Water, Fire, Earth, Air, Light, Shadow } // Example affinities
    enum ResonanceEffectType { BoostHealth, BoostEnergy, AccelerateDecay, SlowDecay, BoostMutationProgress, HaltMutationProgress, ChangeAffinity }
    enum CatalystEffectType { BoostMutationChance, GuaranteedMutation, BoostEnergy, RestoreHealth, RemoveDebuffs }
    enum InteractionOutcome { NoEffect, BoostSelf, BoostOther, DegradeSelf, DegradeOther, MutualBoost, MutualDegrade, MutationTrigger }

    // --- Structs ---
    struct SynthetidType {
        string name;
        uint256 baseDecayRatePerBlock; // How much health/energy decays per block
        uint256 baseEnergyYieldOnFeed; // How much energy feeding typically gives
        uint256 baseMutationPotential; // Base chance/progress multiplier for mutation
        AffinityType affinity; // Base affinity type
        uint256 interactionAffinityMultiplier; // Modifier for interaction outcomes based on affinity match
        uint256 resourceYieldRate; // How much resource harvested
        bool exists; // Flag to check if typeId is registered
    }

    struct SynthetidInstance {
        uint256 typeId;
        uint256 health;
        uint256 energy;
        uint256 mutationProgress; // 0-10000 representing 0-100%
        uint256 lastStateUpdateTime; // Block timestamp or number of last state update
        uint256 lastInteractionTime; // Block timestamp or number of last interaction involving this synthetid
        uint256[] activeResonances; // List of Resonance instance IDs affecting this Synthetid
        bool isAlive; // Cached state
    }

    struct ResonanceType {
        string name;
        ResonanceEffectType effectType;
        uint256 strength; // Amount or percentage
        uint256 durationOrAmount; // Duration in blocks/seconds or amount of uses
        AffinityType affinity; // Affinity this resonance is related to
        bool exists; // Flag to check if typeId is registered
    }

    struct ResonanceInstance {
        uint256 typeId;
        uint256 creationTime; // Block timestamp
        uint256 durationRemaining; // Remaining duration in blocks/seconds
        uint256 usesRemaining; // Remaining uses
        uint256 targetSynthetidId; // 0 if not targeting a specific Synthetid
        bool isActive; // Flag if the resonance is currently active/available
    }

     struct CatalystType {
        string name;
        CatalystEffectType effectType;
        uint256 strength; // Amount or percentage of effect
        uint256 baseUses; // Number of uses per catalyst item/charge
        bool exists; // Flag to check if typeId is registered
    }

    // --- State Variables ---
    Counters.Counter private _synthetidIds;
    Counters.Counter private _resonanceIds;
    Counters.Counter private _synthetidTypeIds;
    Counters.Counter private _resonanceTypeIds;
    Counters.Counter private _catalystTypeIds;
    uint256 private _currentEpoch = 1;

    mapping(uint256 => SynthetidInstance) private _synthetids;
    mapping(uint256 => ResonanceInstance) private _resonances;
    mapping(uint256 => SynthetidType) private _synthetidTypes;
    mapping(uint256 => ResonanceType) private _resonanceTypes;
    mapping(uint256 => CatalystType) private _catalystTypes;

    mapping(bytes32 => uint256) private _synthescapeParameters;

    // Minimal state tracking for pseudo-randomness (DO NOT rely on this for security)
    bytes32 private _randomnessSeed;

    // --- Events ---
    event SynthetidDeployed(uint256 indexed synthetidId, uint256 indexed typeId, address indexed owner);
    event SynthetidStateUpdated(uint256 indexed synthetidId, uint256 health, uint256 energy, uint256 mutationProgress);
    event SynthetidFed(uint256 indexed synthetidId, uint256 energyAmount);
    event ResonanceDeployed(uint256 indexed resonanceId, uint256 indexed typeId, address indexed deployer, uint256 indexed targetSynthetidId);
    event ResonanceApplied(uint256 indexed resonanceId, uint256 indexed synthetidId, uint256 remainingUsesOrDuration);
    event SynthetidInteraction(uint256 indexed synthetidId1, uint256 indexed synthetidId2, InteractionOutcome outcome);
    event SynthetidMutated(uint256 indexed synthetidId, uint256 indexed newTypeId, uint256 catalystTypeId);
    event SynthetidHarvested(uint256 indexed synthetidId, address indexed owner, uint256 amountYielded);
    event EpochTransitioned(uint256 indexed newEpoch);
    event SynthescapeParameterSet(bytes32 indexed paramName, uint256 value);

    // --- Modifiers ---
    modifier whenSynthetidExists(uint256 synthetidId) {
        if (!_exists(synthetidId)) revert Synthescape__SynthetidNotFound(synthetidId);
        _;
    }

    modifier whenResonanceExists(uint256 resonanceId) {
        if (!_resonances[resonanceId].isActive) revert Synthescape__ResonanceNotFound(resonanceId); // isActive check implies existence for active ones
        _;
    }

    modifier whenSynthetidTypeExists(uint256 typeId) {
        if (!_synthetidTypes[typeId].exists) revert Synthescape__SynthetidTypeNotFound(typeId);
        _;
    }

     modifier whenResonanceTypeExists(uint256 typeId) {
        if (!_resonanceTypes[typeId].exists) revert Synthescape__ResonanceTypeNotFound(typeId);
        _;
    }

    modifier whenCatalystTypeExists(uint256 typeId) {
        if (!_catalystTypes[typeId].exists) revert Synthescape__CatalystTypeNotFound(typeId);
        _;
    }

    modifier whenSynthetidIsAlive(uint256 synthetidId) {
         if (!_exists(synthetidId)) revert Synthescape__SynthetidNotFound(synthetidId);
         _updateSynthetidStateInternal(synthetidId); // Ensure state is up-to-date
         if (!_synthetids[synthetidId].isAlive) revert Synthescape__SynthetidNotAlive(synthetidId);
        _;
    }

    // --- Constructor ---
    constructor() ERC721("SynthescapeSynthetid", "SYNTH") Ownable(msg.sender) {
        _randomnessSeed = blockhash(block.number - 1); // Simple initial seed
    }

    // --- Internal Helper Functions ---

    // NOTE: This is a highly simplified and INSECURE pseudo-random number generator.
    // For production use, integrate with Chainlink VRF or a similar secure oracle.
    function _pseudoRandomUint(uint256 seed) internal view returns (uint256) {
        uint256 blockNumber = block.number;
        uint256 timestamp = block.timestamp;
        bytes32 blockHash = blockhash(blockNumber - 1); // Use a previous blockhash for slight unpredictability
        // Combine block data, seed, and current state variables for variability
        bytes32 hash = keccak256(abi.encodePacked(blockHash, timestamp, blockNumber, seed, msg.sender, _randomnessSeed, uint256(keccak256(abi.encodePacked(block.coinbase, block.difficulty)))));
        return uint256(hash);
    }

    // Internal function to calculate elapsed time since last update
    function _getElapsedTime(uint256 lastUpdateTime) internal view returns (uint256) {
        // Use block.timestamp for time-based decay, or block.number for block-based decay
        // block.timestamp is generally better for representing real time passing
        return block.timestamp.sub(lastUpdateTime);
    }

    // Internal function to calculate current state based on decay and active effects
    function _calculateCurrentState(uint256 synthetidId) internal view returns (uint256 health, uint256 energy, uint256 mutationProgress, bool isAlive) {
        SynthetidInstance storage s = _synthetids[synthetidId];
        SynthetidType storage sType = _synthetidTypes[s.typeId];

        uint256 elapsedTime = _getElapsedTime(s.lastStateUpdateTime);

        // Calculate effective decay rate considering Resonance effects
        uint256 effectiveDecayRate = sType.baseDecayRatePerBlock;
        for (uint i = 0; i < s.activeResonances.length; i++) {
             uint256 resId = s.activeResonances[i];
             if (_resonances[resId].isActive) {
                 ResonanceInstance storage res = _resonances[resId];
                 ResonanceType storage resType = _resonanceTypes[res.typeId];
                 if (resType.effectType == ResonanceEffectType.AccelerateDecay) {
                     effectiveDecayRate = effectiveDecayRate.add(resType.strength);
                 } else if (resType.effectType == ResonanceEffectType.SlowDecay) {
                     effectiveDecayRate = effectiveDecayRate.sub(resType.strength > effectiveDecayRate ? effectiveDecayRate : resType.strength); // Prevent underflow
                 }
                 // Decay duration of time-based resonances
                 if (res.durationRemaining > 0) {
                     res.durationRemaining = res.durationRemaining.sub(elapsedTime > res.durationRemaining ? res.durationRemaining : elapsedTime);
                     if (res.durationRemaining == 0 && res.usesRemaining == 0) {
                          res.isActive = false; // Deactivate if duration runs out
                     }
                 }
             }
        }

        // Calculate decay amount
        uint256 decayAmount = effectiveDecayRate.mul(elapsedTime);

        // Apply decay to health and energy
        health = s.health.sub(decayAmount > s.health ? s.health : decayAmount);
        energy = s.energy.sub(decayAmount > s.energy ? s.energy : decayAmount);

        // Apply other Resonance effects (e.g., mutation progress changes)
        mutationProgress = s.mutationProgress;
         for (uint i = 0; i < s.activeResonances.length; i++) {
             uint256 resId = s.activeResonances[i];
             if (_resonances[resId].isActive) {
                 ResonanceInstance storage res = _resonances[resId];
                 ResonanceType storage resType = _resonanceTypes[res.typeId];
                 if (resType.effectType == ResonanceEffectType.BoostMutationProgress) {
                     mutationProgress = mutationProgress.add(resType.strength.mul(elapsedTime)); // Boost based on strength over time
                     if (mutationProgress > 10000) mutationProgress = 10000;
                 } else if (resType.effectType == ResonanceEffectType.HaltMutationProgress) {
                     // Mutation progress doesn't increase/decrease while this is active
                 }
                 // Other effects like ChangeAffinity would need more complex state representation
             }
         }


        isAlive = (health > 0 || energy > 0); // Synthetid is alive if either health or energy is > 0
        return (health, energy, mutationProgress, isAlive);
    }

    // Internal function to update the stored state of a Synthetid
    function _updateSynthetidStateInternal(uint256 synthetidId) internal whenSynthetidExists(synthetidId) {
        SynthetidInstance storage s = _synthetids[synthetidId];

        // Calculate current state
        (uint256 health, uint256 energy, uint256 mutationProgress, bool isAlive) = _calculateCurrentState(synthetidId);

        // Apply state changes
        s.health = health;
        s.energy = energy;
        s.mutationProgress = mutationProgress;
        s.isAlive = isAlive;
        s.lastStateUpdateTime = block.timestamp; // Update the last update time

        // Clean up inactive resonances from the list (simplified: re-add active ones)
        uint256[] memory activeResList;
        uint256 activeCount = 0;
        for (uint i = 0; i < s.activeResonances.length; i++) {
            if (_resonances[s.activeResonances[i]].isActive) {
                 activeCount++;
            }
        }
        activeResList = new uint256[](activeCount);
        activeCount = 0; // Reset counter for population
         for (uint i = 0; i < s.activeResonances.length; i++) {
            if (_resonances[s.activeResonances[i]].isActive) {
                 activeResList[activeCount] = s.activeResonances[i];
                 activeCount++;
            }
        }
        s.activeResonances = activeResList;


        emit SynthetidStateUpdated(synthetidId, s.health, s.energy, s.mutationProgress);

        // If it died, handle death (e.g., burn the NFT)
        if (!s.isAlive && _exists(synthetidId)) {
             _burn(synthetidId);
        }
    }


    // --- Admin Functions (Only Owner) ---

    function registerSynthetidType(
        string calldata name,
        uint256 baseDecayRatePerBlock,
        uint256 baseEnergyYieldOnFeed,
        uint256 baseMutationPotential,
        AffinityType affinity,
        uint256 interactionAffinityMultiplier,
        uint256 resourceYieldRate
    ) external onlyOwner {
        _synthetidTypeIds.increment();
        uint256 typeId = _synthetidTypeIds.current();
        _synthetidTypes[typeId] = SynthetidType({
            name: name,
            baseDecayRatePerBlock: baseDecayRatePerBlock,
            baseEnergyYieldOnFeed: baseEnergyYieldOnFeed,
            baseMutationPotential: baseMutationPotential,
            affinity: affinity,
            interactionAffinityMultiplier: interactionAffinityMultiplier,
            resourceYieldRate: resourceYieldRate,
            exists: true
        });
    }

    function registerResonanceType(
        string calldata name,
        ResonanceEffectType effectType,
        uint256 strength,
        uint256 durationOrAmount,
        AffinityType affinity
    ) external onlyOwner {
         _resonanceTypeIds.increment();
        uint256 typeId = _resonanceTypeIds.current();
        _resonanceTypes[typeId] = ResonanceType({
            name: name,
            effectType: effectType,
            strength: strength,
            durationOrAmount: durationOrAmount,
            affinity: affinity,
            exists: true
        });
    }

     function registerCatalystType(
        string calldata name,
        CatalystEffectType effectType,
        uint256 strength,
        uint256 baseUses
    ) external onlyOwner {
        _catalystTypeIds.increment();
        uint256 typeId = _catalystTypeIds.current();
        _catalystTypes[typeId] = CatalystType({
            name: name,
            effectType: effectType,
            strength: strength,
            baseUses: baseUses,
            exists: true
        });
    }


    function setSynthescapeParameter(bytes32 paramName, uint256 value) external onlyOwner {
        _synthescapeParameters[paramName] = value;
        emit SynthescapeParameterSet(paramName, value);
    }

    // Simplified epoch transition - in a real system, this might be triggered by time or a DAO vote
    function triggerEpochTransition() external onlyOwner {
        _currentEpoch++;
        // In a real system, this could trigger global effects, parameter changes, etc.
        emit EpochTransitioned(_currentEpoch);
    }


    // --- Core Logic Functions ---

    function deploySynthetid(uint256 synthetidTypeId) external payable whenSynthetidTypeExists(synthetidTypeId) {
        // Example: Require payment to deploy a Synthetid
        uint256 deployCost = _synthescapeParameters[keccak256("DeployCost")];
        if (msg.value < deployCost) revert Synthescape__PaymentRequired();

        _synthetidIds.increment();
        uint256 newId = _synthetidIds.current();

        // Initial state (could depend on type or other factors)
        _synthetids[newId] = SynthetidInstance({
            typeId: synthetidTypeId,
            health: 1000, // Example initial values
            energy: 1000,
            mutationProgress: 0,
            lastStateUpdateTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            activeResonances: new uint256[](0), // Start with no active resonances
            isAlive: true // Starts alive
        });

        _safeMint(msg.sender, newId);

        emit SynthetidDeployed(newId, synthetidTypeId, msg.sender);
        emit SynthetidStateUpdated(newId, _synthetids[newId].health, _synthetids[newId].energy, _synthetids[newId].mutationProgress); // Initial state update event
    }

    function deployResonance(uint256 resonanceTypeId, uint256 targetSynthetidId) external payable whenResonanceTypeExists(resonanceTypeId) {
        // Example: Require payment to deploy a Resonance
        uint256 deployCost = _synthescapeParameters[keccak256("ResonanceDeployCost")];
        if (msg.value < deployCost) revert Synthescape__PaymentRequired();

         if (targetSynthetidId != 0) {
            if (!_exists(targetSynthetidId)) revert Synthescape__SynthetidNotFound(targetSynthetidId);
            _updateSynthetidStateInternal(targetSynthetidId); // Update target state before applying
             if (!_synthetids[targetSynthetidId].isAlive) revert Synthescape__SynthetidNotAlive(targetSynthetidId);
         }

        _resonanceIds.increment();
        uint256 newId = _resonanceIds.current();
        ResonanceType storage resType = _resonanceTypes[resonanceTypeId];

        _resonances[newId] = ResonanceInstance({
            typeId: resonanceTypeId,
            creationTime: block.timestamp,
            durationRemaining: resType.durationOrAmount, // If duration-based
            usesRemaining: resType.durationOrAmount, // If uses-based
            targetSynthetidId: targetSynthetidId, // 0 if not targeting
            isActive: true // Starts active
        });

        // If it's a targeted resonance, potentially apply it immediately
         if (targetSynthetidId != 0) {
             _applyResonanceInternal(newId, targetSynthetidId);
         }

        emit ResonanceDeployed(newId, resonanceTypeId, msg.sender, targetSynthetidId);
    }

     // Allows applying an active resonance instance to a Synthetid
    function applyResonanceToSynthetid(uint256 resonanceId, uint256 synthetidId) external
        whenResonanceExists(resonanceId)
        whenSynthetidIsAlive(synthetidId) // Automatically updates Synthetid state
    {
         ResonanceInstance storage res = _resonances[resonanceId];
         ResonanceType storage resType = _resonanceTypes[res.typeId];

         // Prevent applying targeted resonances to wrong targets or non-targeted to specific targets (optional rule)
         if (res.targetSynthetidId != 0 && res.targetSynthetidId != synthetidId) revert Synthescape__InvalidTargetForResonance();
         // If it's a non-targeted resonance type, maybe it *can* be applied manually? Or maybe only certain resonance types can be manually applied. Add rules here.

         _applyResonanceInternal(resonanceId, synthetidId);
    }

    // Internal helper to apply resonance effects and manage instance state
    function _applyResonanceInternal(uint256 resonanceId, uint256 synthetidId) internal {
        ResonanceInstance storage res = _resonances[resonanceId];
        ResonanceType storage resType = _resonanceTypes[res.typeId];
        SynthetidInstance storage s = _synthetids[synthetidId]; // State is already updated by caller modifier

        // Add resonance ID to the synthetid's active list if not already there
        bool alreadyActive = false;
        for(uint i=0; i < s.activeResonances.length; i++) {
            if (s.activeResonances[i] == resonanceId) {
                alreadyActive = true;
                break;
            }
        }
        if (!alreadyActive) {
            s.activeResonances.push(resonanceId);
        }

        // Apply immediate effects if any (decay/mutation progress are handled by _calculateCurrentState over time)
        if (resType.effectType == ResonanceEffectType.BoostHealth) {
            s.health = s.health.add(resType.strength);
            // Cap health? E.g., s.health = s.health > 2000 ? 2000 : s.health;
        } else if (resType.effectType == ResonanceEffectType.BoostEnergy) {
             s.energy = s.energy.add(resType.strength);
             // Cap energy?
        }
        // Other immediate effects could be added

        // Consume charge/duration if uses-based
        if (res.usesRemaining > 0) {
             res.usesRemaining--;
             if (res.usesRemaining == 0 && res.durationRemaining == 0) {
                 res.isActive = false; // Deactivate if uses run out
             }
        }


        emit ResonanceApplied(resonanceId, synthetidId, res.usesRemaining > 0 ? res.usesRemaining : res.durationRemaining);
        emit SynthetidStateUpdated(synthetidId, s.health, s.energy, s.mutationProgress); // State might have changed due to immediate effects
    }


    function feedSynthetid(uint256 synthetidId, uint256 energyAmount) external payable whenSynthetidIsAlive(synthetidId) {
        SynthetidInstance storage s = _synthetids[synthetidId];
        // Example: Require payment for feeding
        uint256 feedCost = _synthescapeParameters[keccak256("FeedCost")]; // Cost per unit of energy
        if (msg.value < feedCost.mul(energyAmount)) revert Synthescape__PaymentRequired();

        s.energy = s.energy.add(energyAmount);
        // Cap energy?
        s.lastStateUpdateTime = block.timestamp; // Feeding updates state time

        emit SynthetidFed(synthetidId, energyAmount);
        emit SynthetidStateUpdated(synthetidId, s.health, s.energy, s.mutationProgress);
    }

    function triggerSynthetidInteraction(uint256 synthetidId1, uint256 synthetidId2) external
        whenSynthetidIsAlive(synthetidId1) // Updates state 1
        whenSynthetidIsAlive(synthetidId2) // Updates state 2
    {
        if (synthetidId1 == synthetidId2) revert Synthescape__InteractionConditionsNotMet(); // Cannot interact with self

        SynthetidInstance storage s1 = _synthetids[synthetidId1];
        SynthetidInstance storage s2 = _synthetids[synthetidId2];
        SynthetidType storage t1 = _synthetidTypes[s1.typeId];
        SynthetidType storage t2 = _synthetidTypes[s2.typeId];

        // Interaction logic: simplified example based on affinity and pseudo-randomness
        uint256 interactionSeed = _pseudoRandomUint(synthetidId1.add(synthetidId2).add(block.timestamp));
        InteractionOutcome outcome;

        // Determine outcome based on affinity, global parameters, and randomness
        uint256 affinityMatchScore = 0;
        if (t1.affinity == t2.affinity && t1.affinity != AffinityType.None) {
            affinityMatchScore = t1.interactionAffinityMultiplier.add(t2.interactionAffinityMultiplier);
        } // More complex affinity rules could apply (e.g., Fire vs Water)

        uint256 baseOutcomeChance = _synthescapeParameters[keccak256("BaseInteractionSuccessChance")]; // e.g., 5000 for 50%
        uint256 totalChance = baseOutcomeChance.add(affinityMatchScore); // Affinity boosts chance

        if (interactionSeed % 10000 < totalChance) { // Roll the dice
            // Success - mutual boost or mutation trigger chance
             if (interactionSeed % 10000 < _synthescapeParameters[keccak256("MutationTriggerChance")]) {
                  outcome = InteractionOutcome.MutationTrigger;
                  s1.mutationProgress = s1.mutationProgress.add(_synthescapeParameters[keccak256("InteractionMutationBoost")]);
                  s2.mutationProgress = s2.mutationProgress.add(_synthescapeParameters[keccak256("InteractionMutationBoost")]);
                  if (s1.mutationProgress > 10000) s1.mutationProgress = 10000;
                  if (s2.mutationProgress > 10000) s2.mutationProgress = 10000;

             } else {
                 outcome = InteractionOutcome.MutualBoost;
                 s1.health = s1.health.add(_synthescapeParameters[keccak256("InteractionBoostAmount")]);
                 s2.health = s2.health.add(_synthescapeParameters[keccak256("InteractionBoostAmount")]);
                  // Cap health?
             }
        } else {
            // Failure - mutual degrade
            outcome = InteractionOutcome.MutualDegrade;
            uint256 degradeAmount = _synthescapeParameters[keccak256("InteractionDegradeAmount")];
            s1.health = s1.health.sub(degradeAmount > s1.health ? s1.health : degradeAmount);
            s2.health = s2.health.sub(degradeAmount > s2.health ? s2.health : degradeAmount);
             // Check for death? _updateSynthetidStateInternal handles this implicitly on next update/query
        }

        s1.lastInteractionTime = block.timestamp;
        s2.lastInteractionTime = block.timestamp;
        s1.lastStateUpdateTime = block.timestamp; // Interaction updates state time
        s2.lastStateUpdateTime = block.timestamp;

        emit SynthetidInteraction(synthetidId1, synthetidId2, outcome);
        emit SynthetidStateUpdated(synthetidId1, s1.health, s1.energy, s1.mutationProgress);
        emit SynthetidStateUpdated(synthetidId2, s2.health, s2.energy, s2.mutationProgress);
    }

     function mutateSynthetid(uint256 synthetidId, uint256 catalystTypeId) external
        whenSynthetidIsAlive(synthetidId) // Updates state
        whenCatalystTypeExists(catalystTypeId)
    {
        SynthetidInstance storage s = _synthetids[synthetidId];
        SynthetidType storage t = _synthetidTypes[s.typeId];
        CatalystType storage cat = _catalystTypes[catalystTypeId];

        // Check if mutation conditions are met (e.g., sufficient mutation progress)
        uint256 requiredMutationProgress = _synthescapeParameters[keccak256("RequiredMutationProgress")];
        if (s.mutationProgress < requiredMutationProgress) revert Synthescape__MutationConditionsNotMet();

        // Mutation success chance based on progress, type potential, catalyst, and randomness
        uint256 baseChance = s.mutationProgress.mul(t.baseMutationPotential).div(10000); // Progress contributes to chance
        uint256 catalystBonus = (cat.effectType == CatalystEffectType.BoostMutationChance || cat.effectType == CatalystEffectType.GuaranteedMutation) ? cat.strength : 0;
        uint256 totalMutationChance = baseChance.add(catalystBonus);

        uint256 mutationSeed = _pseudoRandomUint(synthetidId.add(block.timestamp).add(catalystTypeId));

        bool mutationSuccess = false;
        if (cat.effectType == CatalystEffectType.GuaranteedMutation) {
            mutationSuccess = true;
        } else if (mutationSeed % 10000 < totalMutationChance) {
            mutationSuccess = true;
        }

        if (mutationSuccess) {
            // Logic for determining the new Synthetid type or traits
            // This could be complex: based on current type, resonances, catalysts, randomness, epoch, etc.
            // For simplification, let's just pick a random new type among registered types.
            uint256 totalTypes = _synthetidTypeIds.current();
            uint256 newTypeId = (mutationSeed % totalTypes) + 1; // Get a random ID within range

            // Ensure the new type actually exists (in case types were unregistered, though our system doesn't support unregistering)
            while(!_synthetidTypes[newTypeId].exists) {
                 newTypeId = (newTypeId % totalTypes) + 1; // Simple re-roll if doesn't exist
            }

            // Apply mutation: change type, reset state, consume catalyst uses
            s.typeId = newTypeId;
            s.health = _synthescapeParameters[keccak256("PostMutationHealth")]; // Reset state
            s.energy = _synthescapeParameters[keccak256("PostMutationEnergy")];
            s.mutationProgress = 0; // Reset mutation progress
            s.activeResonances = new uint256[](0); // Remove active resonances (or some logic to keep compatible ones)
            s.lastStateUpdateTime = block.timestamp; // Update state time

            // Consume catalyst use - need a way to track catalyst uses per user/system
            // Simplified: Assume catalyst is consumed on use, this needs a proper inventory system
            // For now, let's just emit that a catalyst was used abstractly
            // In a real contract, this function would decrement a user's balance of a catalyst token (ERC1155 or similar)
            // This example doesn't implement catalyst token logic, just the concept.

            emit SynthetidMutated(synthetidId, newTypeId, catalystTypeId);
            emit SynthetidStateUpdated(synthetidId, s.health, s.energy, s.mutationProgress);

        } else {
            // Mutation failed: reduce mutation progress, potentially damage synthetid, consume catalyst use
             uint256 failurePenalty = _synthescapeParameters[keccak256("MutationFailurePenalty")];
             s.mutationProgress = s.mutationProgress.sub(failurePenalty > s.mutationProgress ? s.mutationProgress : failurePenalty);
             s.health = s.health.sub(_synthescapeParameters[keccak256("MutationFailureDamage")] > s.health ? s.health : _synthescapeParameters[keccak256("MutationFailureDamage")]);
             s.lastStateUpdateTime = block.timestamp; // Update state time
             emit SynthetidStateUpdated(synthetidId, s.health, s.energy, s.mutationProgress);

             // Still consume catalyst use as it was attempted
        }
    }

    // Harvest a resource from a Synthetid - could kill it or just deplete it
    function harvestSynthetid(uint256 synthetidId) external whenSynthetidIsAlive(synthetidId) {
         SynthetidInstance storage s = _synthetids[synthetidId];
         SynthetidType storage t = _synthetidTypes[s.typeId];
         address owner = ownerOf(synthetidId);
         if (msg.sender != owner) revert Synthescape__SynthetidNotOwned(synthetidId);

         // Define conditions for harvesting (e.g., requires minimum energy/health)
         uint256 minEnergyToHarvest = _synthescapeParameters[keccak256("MinEnergyToHarvest")];
         if (s.energy < minEnergyToHarvest) revert Synthescape__HarvestConditionsNotMet();

         uint256 yieldAmount = t.resourceYieldRate; // Yield based on type

         // Harvesting effect: deplete energy and potentially kill or reset state
         s.energy = 0;
         s.health = s.health.sub(_synthescapeParameters[keccak256("HarvestHealthCost")] > s.health ? s.health : _synthescapeParameters[keccak256("HarvestHealthCost")]);
         s.lastStateUpdateTime = block.timestamp; // Update state time

         _updateSynthetidStateInternal(synthetidId); // Re-calculate and handle potential death

         // Transfer yielded resource (e.g., native token, or call another ERC20 contract)
         // Simple example: transfer native token
         payable(owner).transfer(yieldAmount);

         emit SynthetidHarvested(synthetidId, owner, yieldAmount);
         emit SynthetidStateUpdated(synthetidId, s.health, s.energy, s.mutationProgress); // State updated after harvest and internal update
    }

     // Function to apply a catalyst effect (assuming caller has the catalyst resource)
     // This requires a separate system for managing catalyst "items" or "charges".
     // This function represents the effect application assuming the cost/ownership is handled elsewhere.
     function applyCatalystToSynthetid(uint256 synthetidId, uint256 catalystTypeId) external
        whenSynthetidIsAlive(synthetidId) // Updates state
        whenCatalystTypeExists(catalystTypeId)
     {
        // --- !!! IMPORTANT !!! ---
        // In a real dApp, THIS IS WHERE YOU INTEGRATE WITH AN ERC1155 OR SIMILAR
        // CONTRACT TO BURN/TRANSFER A CATALYST TOKEN FROM msg.sender.
        // This example ASSUMES this check happens elsewhere or the catalyst is free/abstract.
        // For demonstration, we'll just proceed with applying the effect.
        // require(hasCatalyst(msg.sender, catalystTypeId, 1), "Insufficient catalyst");
        // burnCatalyst(msg.sender, catalystTypeId, 1);
        // --- !!! IMPORTANT !!! ---

        SynthetidInstance storage s = _synthetids[synthetidId];
        CatalystType storage cat = _catalystTypes[catalystTypeId];

        if (cat.effectType == CatalystEffectType.BoostEnergy) {
            s.energy = s.energy.add(cat.strength);
        } else if (cat.effectType == CatalystEffectType.RestoreHealth) {
             s.health = s.health.add(cat.strength);
        } else if (cat.effectType == CatalystEffectType.RemoveDebuffs) {
             // Logic to remove negative resonances or reset specific negative states
             uint256[] memory newActiveResonances;
             uint256 keepCount = 0;
             for(uint i=0; i < s.activeResonances.length; i++) {
                 uint256 resId = s.activeResonances[i];
                 if (_resonances[resId].isActive) {
                     ResonanceType storage resType = _resonanceTypes[_resonances[resId].typeId];
                     // Example: Remove decay-accelerating or energy-draining effects
                     if (resType.effectType != ResonanceEffectType.AccelerateDecay /* add other negative types */) {
                         keepCount++;
                     } else {
                         _resonances[resId].isActive = false; // Deactivate the removed resonance
                     }
                 }
             }
            newActiveResonances = new uint256[](keepCount);
            keepCount = 0;
            for(uint i=0; i < s.activeResonances.length; i++) {
                 uint256 resId = s.activeResonances[i];
                 if (_resonances[resId].isActive) {
                     newActiveResonances[keepCount] = resId;
                     keepCount++;
                 }
            }
             s.activeResonances = newActiveResonances;

        }
        // BoostMutationChance and GuaranteedMutation are handled in mutateSynthetid function itself

        s.lastStateUpdateTime = block.timestamp; // Catalyst use updates state time
        emit SynthetidStateUpdated(synthetidId, s.health, s.energy, s.mutationProgress);

        // Emit a general event for catalyst use (could be more specific)
        // event CatalystUsed(uint256 indexed synthetidId, uint256 indexed catalystTypeId, address indexed user);
        // emit CatalystUsed(synthetidId, catalystTypeId, msg.sender);
    }


    // --- Query Functions ---

    function getSynthetidState(uint256 synthetidId) public view whenSynthetidExists(synthetidId) returns (SynthetidInstance memory) {
         // Calculate the *current* state without modifying storage
         (uint256 health, uint256 energy, uint256 mutationProgress, bool isAlive) = _calculateCurrentState(synthetidId);

         // Return a memory struct with the calculated current state
         SynthetidInstance storage s = _synthetids[synthetidId];
         return SynthetidInstance({
             typeId: s.typeId,
             health: health,
             energy: energy,
             mutationProgress: mutationProgress,
             lastStateUpdateTime: s.lastStateUpdateTime, // Return stored time
             lastInteractionTime: s.lastInteractionTime,
             activeResonances: s.activeResonances, // Return stored list (may contain inactive ones if not updated)
             isAlive: isAlive
         });
    }

    function listUserSynthetids(address user) public view returns (uint256[] memory) {
        uint256 total = totalSupply();
        uint256[] memory userTokens = new uint256[](total); // Max possible size
        uint256 count = 0;
        // Iterate through token IDs (inefficient for large numbers of tokens)
        // A more efficient way would involve tracking token IDs by owner during mint/transfer
        // For this example, we iterate.
        for (uint256 i = 1; i <= total; i++) { // Assuming IDs start from 1
            if (_exists(i) && ownerOf(i) == user) {
                userTokens[count] = i;
                count++;
            }
        }
        // Copy to a new array of exact size
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userTokens[i];
        }
        return result;
    }

    function getResonanceState(uint256 resonanceId) public view returns (ResonanceInstance memory) {
        ResonanceInstance storage res = _resonances[resonanceId];
        if (!res.isActive) revert Synthescape__ResonanceNotFound(resonanceId); // Check existence via isActive

        // Calculate remaining duration based on current time
        uint256 elapsedTime = _getElapsedTime(res.creationTime);
        uint256 durationRemaining = res.durationRemaining > 0 ? res.durationRemaining.sub(elapsedTime > res.durationRemaining ? res.durationRemaining : elapsedTime) : 0;


        return ResonanceInstance({
            typeId: res.typeId,
            creationTime: res.creationTime,
            durationRemaining: durationRemaining, // Return calculated remaining duration
            usesRemaining: res.usesRemaining, // Return stored uses
            targetSynthetidId: res.targetSynthetidId,
            isActive: res.isActive // Should be true by modifier, but for completeness
        });
    }

     function listActiveResonances() public view returns (uint256[] memory) {
        uint256 total = _resonanceIds.current();
        uint256[] memory activeRes = new uint256[](total); // Max possible size
        uint256 count = 0;
         for (uint256 i = 1; i <= total; i++) { // Assuming IDs start from 1
             if (_resonances[i].isActive) {
                // Could add check here to see if time-based resonances have expired *in the query*,
                // but isActive flag is the source of truth updated during state transitions/updates.
                // For simplicity, we just check the flag.
                 activeRes[count] = i;
                 count++;
             }
         }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeRes[i];
        }
        return result;
    }


     function queryInteractionOutcome(uint256 synthetidId1, uint256 synthetidId2) public view
        whenSynthetidIsAlive(synthetidId1) // Implicitly updates state 1 for view calculation
        whenSynthetidIsAlive(synthetidId2) // Implicitly updates state 2 for view calculation
        returns (InteractionOutcome outcome, uint256 health1After, uint256 energy1After, uint256 mutation1After, uint256 health2After, uint256 energy2After, uint256 mutation2After)
    {
         if (synthetidId1 == synthetidId2) revert Synthescape__InteractionConditionsNotMet();

        // Get *current* state (calculated by modifier)
        SynthetidInstance memory s1 = getSynthetidState(synthetidId1); // Use the view function to get current state
        SynthetidInstance memory s2 = getSynthetidState(synthetidId2);
        SynthetidType memory t1 = _synthetidTypes[s1.typeId];
        SynthetidType memory t2 = _synthetidTypes[s2.typeId];

        // This simulation needs a DETERMINISTIC seed for the view function.
        // It should NOT use block.timestamp or blockhash directly, as these change.
        // A simple deterministic seed could be based on the input IDs and current epoch/global state.
        // However, mimicking the actual interaction logic's randomness makes the prediction non-deterministic.
        // This demonstrates the *concept* of prediction, but a truly useful prediction market/system
        // would need deterministic rules or oracle interaction for randomness.
        // For this example, we use a simple deterministic hash of inputs.
        uint256 deterministicSeed = uint256(keccak256(abi.encodePacked(synthetidId1, synthetidId2, _currentEpoch)));

        InteractionOutcome simulatedOutcome;
         uint256 affinityMatchScore = 0;
        if (t1.affinity == t2.affinity && t1.affinity != AffinityType.None) {
            affinityMatchScore = t1.interactionAffinityMultiplier.add(t2.interactionAffinityMultiplier);
        }

        uint256 baseOutcomeChance = _synthescapeParameters[keccak256("BaseInteractionSuccessChance")];
        uint256 totalChance = baseOutcomeChance.add(affinityMatchScore);

        uint256 simulatedRandom = deterministicSeed % 10000; // Simulate randomness deterministically

        uint256 tempHealth1 = s1.health;
        uint256 tempEnergy1 = s1.energy;
        uint256 tempMutation1 = s1.mutationProgress;
        uint256 tempHealth2 = s2.health;
        uint256 tempEnergy2 = s2.energy;
        uint256 tempMutation2 = s2.mutationProgress;


        if (simulatedRandom < totalChance) {
             uint256 mutationTriggerRoll = deterministicSeed / 10000; // Use a different part of the hash
             if (mutationTriggerRoll % 10000 < _synthescapeParameters[keccak256("MutationTriggerChance")]) {
                  simulatedOutcome = InteractionOutcome.MutationTrigger;
                  tempMutation1 = tempMutation1.add(_synthescapeParameters[keccak256("InteractionMutationBoost")]);
                  tempMutation2 = tempMutation2.add(_synthescapeParameters[keccak256("InteractionMutationBoost")]);
                   if (tempMutation1 > 10000) tempMutation1 = 10000;
                   if (tempMutation2 > 10000) tempMutation2 = 10000;
             } else {
                 simulatedOutcome = InteractionOutcome.MutualBoost;
                 tempHealth1 = tempHealth1.add(_synthescapeParameters[keccak256("InteractionBoostAmount")]);
                 tempHealth2 = tempHealth2.add(_synthescapeParameters[keccak256("InteractionBoostAmount")]);
             }
        } else {
            simulatedOutcome = InteractionOutcome.MutualDegrade;
            uint256 degradeAmount = _synthescapeParameters[keccak256("InteractionDegradeAmount")];
            tempHealth1 = tempHealth1.sub(degradeAmount > tempHealth1 ? tempHealth1 : degradeAmount);
            tempHealth2 = tempHealth2.sub(degradeAmount > tempHealth2 ? tempHealth2 : degradeAmount);
        }

        return (simulatedOutcome, tempHealth1, tempEnergy1, tempMutation1, tempHealth2, tempEnergy2, tempMutation2);
    }


    function queryMutationPotential(uint256 synthetidId) public view whenSynthetidIsAlive(synthetidId) returns (uint256 mutationChancePercent, uint256 potentialNewTypeId) {
        SynthetidInstance memory s = getSynthetidState(synthetidId); // Get current state
        SynthetidType memory t = _synthetidTypes[s.typeId];

        uint256 requiredMutationProgress = _synthescapeParameters[keccak256("RequiredMutationProgress")];
        if (s.mutationProgress < requiredMutationProgress) {
            return (0, 0); // No chance if progress too low
        }

        uint256 baseChance = s.mutationProgress.mul(t.baseMutationPotential).div(10000); // Progress contributes to chance
        // This query doesn't consider catalysts the user *might* use, only inherent potential.
        // Could modify this to take a catalyst typeId as input.

        uint256 potentialNewTypeSeed = uint256(keccak256(abi.encodePacked(synthetidId, _currentEpoch, s.mutationProgress))); // Deterministic for view
        uint256 totalTypes = _synthetidTypeIds.current();
        uint256 simulatedNewTypeId = (potentialNewTypeSeed % totalTypes) + 1;
        while(!_synthetidTypes[simulatedNewTypeId].exists) {
             simulatedNewTypeId = (simulatedNewTypeId % totalTypes) + 1;
        }

        // Return chance out of 100 (approximately)
        return (baseChance.mul(100).div(10000), simulatedNewTypeId);
    }

     function simulateSynthetidFutureState(uint256 synthetidId, uint256 timeDelta) public view whenSynthetidExists(synthetidId) returns (uint256 health, uint256 energy, uint256 mutationProgress, bool isAlive) {
        SynthetidInstance storage s = _synthetids[synthetidId];
        SynthetidType storage sType = _synthetidTypes[s.typeId];

         // Calculate effective decay rate considering Resonance effects
        uint256 effectiveDecayRate = sType.baseDecayRatePerBlock;
        for (uint i = 0; i < s.activeResonances.length; i++) {
             uint256 resId = s.activeResonances[i];
             ResonanceInstance storage res = _resonances[resId];
             // Only consider active resonances that won't expire within timeDelta for long-term simulation accuracy
             if (res.isActive && (res.durationRemaining == 0 || res.durationRemaining >= timeDelta) ) {
                 ResonanceType storage resType = _resonanceTypes[res.typeId];
                 if (resType.effectType == ResonanceEffectType.AccelerateDecay) {
                     effectiveDecayRate = effectiveDecayRate.add(resType.strength);
                 } else if (resType.effectType == ResonanceEffectType.SlowDecay) {
                     effectiveDecayRate = effectiveDecayRate.sub(resType.strength > effectiveDecayRate ? effectiveDecayRate : resType.strength);
                 }
             }
        }


        // Calculate decay amount over the timeDelta
        uint256 decayAmount = effectiveDecayRate.mul(timeDelta);

        // Apply decay to health and energy (starting from CURRENT calculated state)
        (uint256 currentHealth, uint256 currentEnergy, uint256 currentMutation, bool currentAlive) = _calculateCurrentState(synthetidId);

        health = currentHealth.sub(decayAmount > currentHealth ? currentHealth : decayAmount);
        energy = currentEnergy.sub(decayAmount > currentEnergy ? currentEnergy : decayAmount);

        // Calculate mutation progress change over timeDelta
        mutationProgress = currentMutation;
         for (uint i = 0; i < s.activeResonances.length; i++) {
             uint256 resId = s.activeResonances[i];
              if (_resonances[resId].isActive && (_resonances[resId].durationRemaining == 0 || _resonances[resId].durationRemaining >= timeDelta)) {
                 ResonanceType storage resType = _resonanceTypes[_resonances[resId].typeId];
                 if (resType.effectType == ResonanceEffectType.BoostMutationProgress) {
                     mutationProgress = mutationProgress.add(resType.strength.mul(timeDelta));
                     if (mutationProgress > 10000) mutationProgress = 10000;
                 } else if (resType.effectType == ResonanceEffectType.HaltMutationProgress) {
                     // Mutation progress doesn't increase/decrease
                 }
             }
         }


        isAlive = (health > 0 || energy > 0);
        return (health, energy, mutationProgress, isAlive);
     }


    function queryEffectiveSynthetidDecayRate(uint256 synthetidId) public view whenSynthetidExists(synthetidId) returns (uint256) {
        SynthetidInstance storage s = _synthetids[synthetidId];
        SynthetidType storage sType = _synthetidTypes[s.typeId];

        uint256 effectiveDecayRate = sType.baseDecayRatePerBlock;
         for (uint i = 0; i < s.activeResonances.length; i++) {
             uint256 resId = s.activeResonances[i];
             ResonanceInstance storage res = _resonances[resId];
             // Only consider currently active resonances
             if (res.isActive) {
                 ResonanceType storage resType = _resonanceTypes[res.typeId];
                 if (resType.effectType == ResonanceEffectType.AccelerateDecay) {
                     effectiveDecayRate = effectiveDecayRate.add(resType.strength);
                 } else if (resType.effectType == ResonanceEffectType.SlowDecay) {
                     effectiveDecayRate = effectiveDecayRate.sub(resType.strength > effectiveDecayRate ? effectiveDecayRate : resType.strength);
                 }
             }
         }
         return effectiveDecayRate;
    }

    // Example of a query that involves filtering based on type properties
    function getSynthetidsByAffinity(AffinityType affinity) public view returns (uint256[] memory) {
        uint256 total = _synthetidIds.current();
        uint256[] memory filteredIds = new uint256[](total);
        uint256 count = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (_exists(i)) { // Only consider existing tokens (not burned)
                SynthetidInstance storage s = _synthetids[i];
                SynthetidType storage t = _synthetidTypes[s.typeId];
                 // Check current state to only return alive ones? Or all? Let's return all existing.
                 if (t.affinity == affinity) {
                     filteredIds[count] = i;
                     count++;
                 }
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filteredIds[i];
        }
        return result;
    }

    function querySynthescapeSummary() public view returns (uint256 totalSynthetids, uint256 aliveSynthetids, uint256 activeResonances, uint256 currentEpoch) {
        uint256 totalSyn = _synthetidIds.current();
        uint256 aliveSynCount = 0;
         for (uint256 i = 1; i <= totalSyn; i++) {
            if (_exists(i)) {
                 // Need to calculate current state to check aliveness reliably
                 (,,,, bool isAlive) = _calculateCurrentState(i);
                 if (isAlive) {
                     aliveSynCount++;
                 }
            }
         }

        uint256 totalRes = _resonanceIds.current();
        uint256 activeResCount = 0;
         for (uint256 i = 1; i <= totalRes; i++) {
             if (_resonances[i].isActive) { // Check isActive flag
                 activeResCount++;
             }
         }

         return (totalSyn, aliveSynCount, activeResCount, _currentEpoch);
    }

     // --- ERC721 Overrides ---
     // Need to override burn to also update our internal state mapping
     // (or ensure functions that check `_exists` also cross-reference `isAlive`)
     // Standard ERC721 burn removes from owner mapping and reduces supply,
     // but doesn't clear the struct data. We need to mark it explicitly or remove.
     // For simplicity, our `_updateSynthetidStateInternal` calls `_burn`.
     // We might need to explicitly handle the struct removal if not burning:
     // e.g., setting an `isBurned` flag or using `delete`. Let's stick to burning for simplicity.


    // The following are standard ERC721 functions implicitly available or overridden:
    // - transferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    // - approve(address to, uint256 tokenId)
    // - setApprovalForAll(address operator, bool approved)
    // - getApproved(uint256 tokenId) view
    // - isApprovedForAll(address owner, address operator) view
    // - balanceOf(address owner) view
    // - ownerOf(uint256 tokenId) view
    // - supportsInterface(bytes4 interfaceId) view
    // - name() view
    // - symbol() view
    // - tokenURI(uint256 tokenId) view // Needs implementation if metadata is off-chain


    // Example tokenURI implementation (basic)
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        // In a real dApp, this would return a URI pointing to JSON metadata
        // e.g., ipfs://<hash>/<tokenId>.json
        // This metadata would include the Synthetid's dynamic properties and type info.
        return string(abi.encodePacked("ipfs://your_metadata_base_uri/", Strings.toString(tokenId), ".json"));
    }

    // Example fallback/receive to handle payments
    receive() external payable {}
    fallback() external payable {}
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Dynamic NFT State:** Synthetid properties (`health`, `energy`, `mutationProgress`) are not static metadata but change on-chain over time and through interactions. This is more complex than typical static or revealing NFTs.
2.  **Time-Based Decay:** Synthetids' state automatically degrades based on elapsed time (represented by block timestamps). This introduces maintenance mechanics.
3.  **Environmental Influence (Resonances):** Separate entities (`ResonanceInstance`) exist on-chain and can apply effects (`ResonanceEffectType`) to Synthetids, modifying their decay rates, mutation potential, etc. This creates an interactive environment layer.
4.  **Entity-to-Entity Interaction:** The `triggerSynthetidInteraction` function allows two NFTs to interact, with outcomes affecting both based on their states, types, and the environment.
5.  **On-Chain Mutation:** Synthetids can undergo mutation, potentially changing their `SynthetidType` based on their `mutationProgress`, environmental factors (Resonances), Catalysts, and a pseudo-random outcome. This allows for evolution.
6.  **Catalysts:** An abstract concept introduced to show how special items/actions (`CatalystType`) can influence specific processes like mutation or state recovery.
7.  **Lazy State Calculation:** The actual state (`health`, `energy`, etc.) is calculated based on the last update time when queried (`getSynthetidState`, `_calculateCurrentState`) or when an action affecting state is performed (`_updateSynthetidStateInternal`). This avoids needing a constant background process to update every Synthetid every block.
8.  **Parameterization:** Global `SynthescapeParameter`s stored in a mapping allow the owner (or future DAO) to tune the ecosystem's rules (decay rates, interaction effects, etc.) dynamically.
9.  **Epochs:** The concept of `Epoch` transitions allows for potential global shifts in rules, events, or available types over time, adding a temporal dimension to the ecosystem.
10. **Simulation/Prediction Queries:** Functions like `queryInteractionOutcome` and `simulateSynthetidFutureState` allow users to query potential future states or outcomes based on the current on-chain state, adding strategic depth.
11. **Resource Harvesting:** The `harvestSynthetid` function introduces a mechanism to extract value or resources from an entity, potentially at a cost to the entity's state or lifespan.
12. **Affinity System:** Synthetid and Resonance types have `AffinityType`s, introducing a basic elemental or categorical system that influences interactions and effects.
13. **Custom Licensing (SPDL-License):** As requested, the license is non-standard, adding a creative/unique touch (though requires defining the license itself).

**Security Notes:**

*   **Pseudo-randomness:** The `_pseudoRandomUint` function is **NOT** cryptographically secure. It's suitable for demonstrating concepts but easily exploitable in a production system where outcomes have value. A secure VRF (like Chainlink VRF) is necessary for critical random outcomes.
*   **State Updates:** The lazy state update relies on functions being called. If a Synthetid is never interacted with or queried, its stored state becomes outdated, though `_calculateCurrentState` handles this upon query/action.
*   **Complexity:** The interaction and effect logic can become complex. Thorough testing is needed to ensure state transitions are handled correctly and no edge cases lead to unintended behavior.
*   **Gas Costs:** Complex state calculations and array manipulations (like `activeResonances`) can become expensive with many active resonances or complex interaction rules.

This contract provides a framework for a dynamic on-chain world, going beyond simple token ownership or transfers to involve complex state management and interactions driven by time and environmental factors.