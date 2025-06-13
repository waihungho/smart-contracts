Okay, let's design a smart contract that represents a unique concept: a "Digital Soul". This soul is a non-transferable (soulbound) token whose attributes ("traits" or "aura") evolve over time and based on the owner's simulated on-chain "interactions" or "experiences". It incorporates concepts like dynamic NFTs, reputation/karma, simple procedural generation, and interaction-based evolution, distinct from typical ERC-721 or ERC-1155 implementations.

**Concept:** The `DigitalSoul` contract mints unique, non-transferable tokens. Each token represents a "soul" with several quantifiable traits (e.g., Wisdom, Creativity, Empathy, Resilience, Karma). These traits are not static metadata but change dynamically based on simulated time decay/growth and explicit "experience" functions triggered by the owner. There are functions to record general interactions, specific contemplative or creative acts, even abstract concepts like "fusing" or "sacrificing" souls to influence others or gain insights.

---

**Smart Contract: DigitalSoul**

**Outline:**

1.  **Contract Definition:** `DigitalSoul`
2.  **State Variables:**
    *   Owner address for administrative functions.
    *   Mapping from tokenId to owner address.
    *   Mapping from tokenId to `SoulTraits` struct.
    *   Next available tokenId.
    *   Mapping to track if a soul is "dormant" (e.g., after fusion/sacrifice).
    *   Parameters for trait decay/growth rates and interaction impacts (owner-adjustable).
3.  **Structs:**
    *   `SoulTraits`: Holds the numerical values for each trait (wisdom, creativity, empathy, resilience, karma, last update timestamp).
4.  **Events:**
    *   `SoulMinted`: Emitted when a new soul is created.
    *   `TraitUpdated`: Emitted when a soul's traits change significantly.
    *   `InteractionRecorded`: Emitted when an interaction affects a soul.
    *   `SoulFused`: Emitted when souls are fused.
    *   `SoulSacrificed`: Emitted when a soul is sacrificed.
    *   `ParameterUpdated`: Emitted when owner changes a contract parameter.
5.  **Modifiers:**
    *   `onlyOwner`: Restricts function access to the contract owner.
    *   `onlySoulOwner`: Restricts function access to the owner of a specific soul.
    *   `notDormant`: Ensures the soul is active.
6.  **Functions:**
    *   **Ownership/Admin (3 functions):**
        *   `constructor`: Sets initial contract owner.
        *   `getOwner`: Returns contract owner address.
        *   `setOwner`: Transfers contract ownership.
    *   **Minting/Basic Access (4 functions):**
        *   `mintSoul`: Mints a new soul token to the caller.
        *   `getSoulOwner`: Returns the owner of a given soul.
        *   `getSoulTraits`: Returns the current traits of a soul.
        *   `getTotalSupply`: Returns the total number of souls minted.
    *   **Trait Evolution & Interaction (7 functions):**
        *   `_updateTraitsBasedOnTime`: (Internal) Updates traits based on elapsed time since last action.
        *   `recordGeneralInteraction`: Records a general interaction affecting karma and triggering time-based trait updates.
        *   `contemplate`: Simulates contemplation, boosting Wisdom and slightly affecting others.
        *   `createSomething`: Simulates a creative act, boosting Creativity and affecting others.
        *   `showEmpathy`: Simulates an empathetic act, boosting Empathy and affecting others.
        *   `faceChallenge`: Simulates facing a challenge, boosting Resilience and affecting others.
        *   `decayKarma`: Explicitly triggers karma decay (less frequent than other updates).
    *   **Advanced & Creative Concepts (8 functions):**
        *   `getPredictedTraitEvolution`: Forecasts trait changes over a future time period without changing state.
        *   `fuseSouls`: Fuses two existing souls into a *new* soul for the caller, marking the originals as dormant. Traits of the new soul are derived from the fused ones.
        *   `sacrificeSoul`: Marks a soul as dormant. Its "essence" (derived from traits) *could* be used conceptually or influences other owner souls.
        *   `queryAuraHarmony`: Calculates a single "harmony" score based on the current trait balance.
        *   `imprintMemoryHash`: Allows associating a data hash (e.g., IPFS hash of a memory) with a soul.
        *   `regenerateAura`: A costly operation to significantly re-roll or boost certain traits, potentially with negative side effects on others.
        *   `attuneToExternalFactor`: Simulates tuning the soul to an external influence, affecting traits based on an input parameter.
        *   `getDormantStatus`: Checks if a soul is marked as dormant.
    *   **Parameter Adjustment (5 functions):**
        *   `setBaseDecayRate`: Owner sets the base decay rate for traits.
        *   `setInteractionImpactFactors`: Owner sets multipliers for how different interactions affect traits.
        *   `setFusionMultiplier`: Owner sets a multiplier used in the fuseSouls calculation.
        *   `setRegenerationCostFactors`: Owner sets parameters for the regenerateAura function.
        *   `setKarmaDecayRate`: Owner sets the rate at which karma decays.

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the deployer as the owner.
2.  `getOwner() view`: Returns the address of the contract owner.
3.  `setOwner(address newOwner) onlyOwner`: Allows the contract owner to transfer ownership.
4.  `mintSoul() external`: Mints a new soul token for the message sender. Initializes traits with base values.
5.  `getSoulOwner(uint256 tokenId) view`: Returns the address that owns the specified soul token.
6.  `getSoulTraits(uint256 tokenId) view`: Returns the current `SoulTraits` struct for the specified token ID. Includes an internal call to update traits based on time before returning.
7.  `getTotalSupply() view`: Returns the total count of souls that have been minted.
8.  `_updateTraitsBasedOnTime(uint256 tokenId) internal`: Calculates elapsed time and applies passive decay or growth to traits. Updates `lastActionTimestamp`.
9.  `recordGeneralInteraction(uint256 tokenId, int256 karmaImpact) external onlySoulOwner notDormant`: Records a generic interaction. Calls `_updateTraitsBasedOnTime` and updates `karma` based on `karmaImpact`.
10. `contemplate(uint256 tokenId, uint256 duration) external onlySoulOwner notDormant`: Simulates contemplation. Calls `_updateTraitsBasedOnTime` and boosts Wisdom, with minor effects on others based on `duration`.
11. `createSomething(uint256 tokenId, uint256 effort) external onlySoulOwner notDormant`: Simulates creation. Calls `_updateTraitsBasedOnTime` and boosts Creativity, with minor effects on others based on `effort`.
12. `showEmpathy(uint256 tokenId, uint256 empathyAmount) external onlySoulOwner notDormant`: Simulates empathy. Calls `_updateTraitsBasedOnTime` and boosts Empathy, with minor effects on others based on `empathyAmount`.
13. `faceChallenge(uint256 tokenId, uint256 challengeSeverity) external onlySoulOwner notDormant`: Simulates facing a challenge. Calls `_updateTraitsBasedOnTime` and boosts Resilience, with minor effects on others based on `challengeSeverity`.
14. `decayKarma(uint256 tokenId) external onlySoulOwner notDormant`: Explicitly applies karma decay based on the configured rate.
15. `getPredictedTraitEvolution(uint256 tokenId, uint256 timeDelta) view`: Returns what the soul's traits *would* be after `timeDelta` seconds, without changing state. Simulates `_updateTraitsBasedOnTime`.
16. `fuseSouls(uint256 tokenId1, uint256 tokenId2) external onlySoulOwner notDormant`: Creates a new soul for the caller whose initial traits are derived from `tokenId1` and `tokenId2`. Marks `tokenId1` and `tokenId2` as dormant.
17. `sacrificeSoul(uint256 tokenId) external onlySoulOwner notDormant`: Marks `tokenId` as dormant. Represents sacrificing its potential; could conceptually benefit the owner or other souls (though not explicitly implemented here beyond marking dormant).
18. `queryAuraHarmony(uint256 tokenId) view`: Calculates a score representing the balance or harmony of the soul's traits. Calls `getSoulTraits` internally.
19. `imprintMemoryHash(uint256 tokenId, bytes32 memoryHash) external onlySoulOwner notDormant`: Associates a 32-byte hash (representing off-chain memory) with the soul.
20. `regenerateAura(uint256 tokenId, uint256 essenceCost) external onlySoulOwner notDormant`: Simulates regenerating the soul's aura, potentially boosting some traits significantly but with a cost (abstract `essenceCost`) and potential penalty to others. Calls `_updateTraitsBasedOnTime`.
21. `attuneToExternalFactor(uint256 tokenId, uint256 externalFactor) external onlySoulOwner notDormant`: Simulates the soul being influenced by an external factor. Calls `_updateTraitsBasedOnTime` and adjusts traits based on `externalFactor`.
22. `getDormantStatus(uint256 tokenId) view`: Returns true if the soul is dormant, false otherwise.
23. `setBaseDecayRate(uint256 rate) onlyOwner`: Sets the rate at which traits passively decay or grow over time.
24. `setInteractionImpactFactors(uint256 wisdomFactor, uint256 creativityFactor, uint256 empathyFactor, uint256 resilienceFactor) onlyOwner`: Sets multipliers for how interactions affect traits.
25. `setFusionMultiplier(uint256 multiplier) onlyOwner`: Sets a multiplier used in the `fuseSouls` calculation to determine the new soul's trait values.
26. `setRegenerationCostFactors(uint256 penaltyFactor, uint256 boostFactor) onlyOwner`: Sets parameters controlling the outcome of the `regenerateAura` function.
27. `setKarmaDecayRate(uint256 rate) onlyOwner`: Sets the rate at which karma decays during the `decayKarma` function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DigitalSoul
 * @dev A smart contract for managing dynamic, non-transferable (soulbound) tokens
 * where traits evolve based on time and owner interactions.
 *
 * Outline:
 * 1. Contract Definition: DigitalSoul
 * 2. State Variables: owner, _owners, _soulTraits, _nextTokenId, _isDormant, parameters for evolution
 * 3. Structs: SoulTraits
 * 4. Events: SoulMinted, TraitUpdated, InteractionRecorded, SoulFused, SoulSacrificed, ParameterUpdated
 * 5. Modifiers: onlyOwner, onlySoulOwner, notDormant
 * 6. Functions (27 functions):
 *    - Ownership/Admin (3): constructor, getOwner, setOwner
 *    - Minting/Basic Access (4): mintSoul, getSoulOwner, getSoulTraits, getTotalSupply
 *    - Trait Evolution & Interaction (7): _updateTraitsBasedOnTime (internal), recordGeneralInteraction, contemplate, createSomething, showEmpathy, faceChallenge, decayKarma
 *    - Advanced & Creative Concepts (8): getPredictedTraitEvolution, fuseSouls, sacrificeSoul, queryAuraHarmony, imprintMemoryHash, regenerateAura, attuneToExternalFactor, getDormantStatus
 *    - Parameter Adjustment (5): setBaseDecayRate, setInteractionImpactFactors, setFusionMultiplier, setRegenerationCostFactors, setKarmaDecayRate
 *
 * Function Summary:
 * 1. constructor(): Initializes the contract, sets deployer as owner.
 * 2. getOwner() view: Returns contract owner address.
 * 3. setOwner(address newOwner) onlyOwner: Transfers contract ownership.
 * 4. mintSoul() external: Mints a new soul token for the sender with base traits.
 * 5. getSoulOwner(uint256 tokenId) view: Returns the owner of a soul.
 * 6. getSoulTraits(uint256 tokenId) view: Returns current traits, updating based on time first.
 * 7. getTotalSupply() view: Returns total number of souls minted.
 * 8. _updateTraitsBasedOnTime(uint256 tokenId) internal: Calculates and applies time-based trait changes.
 * 9. recordGeneralInteraction(uint256 tokenId, int256 karmaImpact) external onlySoulOwner notDormant: Records interaction, affects karma & traits.
 * 10. contemplate(uint256 tokenId, uint256 duration) external onlySoulOwner notDormant: Simulates contemplation, boosts Wisdom.
 * 11. createSomething(uint256 tokenId, uint256 effort) external onlySoulOwner notDormant: Simulates creation, boosts Creativity.
 * 12. showEmpathy(uint256 tokenId, uint256 empathyAmount) external onlySoulOwner notDormant: Simulates empathy, boosts Empathy.
 * 13. faceChallenge(uint256 tokenId, uint256 challengeSeverity) external onlySoulOwner notDormant: Simulates challenge, boosts Resilience.
 * 14. decayKarma(uint256 tokenId) external onlySoulOwner notDormant: Explicitly decays karma.
 * 15. getPredictedTraitEvolution(uint256 tokenId, uint256 timeDelta) view: Forecasts trait evolution over time.
 * 16. fuseSouls(uint256 tokenId1, uint256 tokenId2) external onlySoulOwner notDormant: Fuses two souls into a new one, marking originals dormant.
 * 17. sacrificeSoul(uint256 tokenId) external onlySoulOwner notDormant: Marks a soul dormant.
 * 18. queryAuraHarmony(uint256 tokenId) view: Calculates a harmony score from traits.
 * 19. imprintMemoryHash(uint256 tokenId, bytes32 memoryHash) external onlySoulOwner notDormant: Associates a memory hash with a soul.
 * 20. regenerateAura(uint256 tokenId, uint256 essenceCost) external onlySoulOwner notDormant: Regenerates aura, adjusting traits with cost/penalty.
 * 21. attuneToExternalFactor(uint256 tokenId, uint256 externalFactor) external onlySoulOwner notDormant: Adjusts traits based on an external factor.
 * 22. getDormantStatus(uint256 tokenId) view: Checks if a soul is dormant.
 * 23. setBaseDecayRate(uint256 rate) onlyOwner: Sets the base trait decay/growth rate.
 * 24. setInteractionImpactFactors(uint256 wisdomFactor, uint256 creativityFactor, uint256 empathyFactor, uint256 resilienceFactor) onlyOwner: Sets multipliers for interaction effects.
 * 25. setFusionMultiplier(uint256 multiplier) onlyOwner: Sets multiplier for fuseSouls calculation.
 * 26. setRegenerationCostFactors(uint256 penaltyFactor, uint256 boostFactor) onlyOwner: Sets parameters for regenerateAura.
 * 27. setKarmaDecayRate(uint256 rate) onlyOwner: Sets karma decay rate.
 */
contract DigitalSoul {

    address public owner;

    struct SoulTraits {
        uint256 wisdom;
        uint256 creativity;
        uint256 empathy;
        uint256 resilience;
        int256 karma; // Can be positive or negative
        uint256 lastActionTimestamp; // Timestamp of the last trait-affecting action
        bytes32 memoryHash; // Optional associated memory hash
    }

    mapping(uint256 => address) private _owners;
    mapping(uint256 => SoulTraits) private _soulTraits;
    mapping(uint256 => bool) private _isDormant; // Soul is marked dormant after fuse/sacrifice

    uint256 private _nextTokenId;
    uint256 private _totalSupply;

    // Configurable parameters (owner can adjust)
    uint256 public baseDecayRate = 1; // Affects time-based trait changes (per hour, scaled)
    uint256 public karmaDecayRate = 10; // How much karma decays per explicit decay call
    uint256 public interactionWisdomFactor = 5;
    uint256 public interactionCreativityFactor = 5;
    uint256 public interactionEmpathyFactor = 5;
    uint256 public interactionResilienceFactor = 5;
    uint256 public fusionMultiplier = 150; // Scaled by 100, so 150 = 1.5x avg traits for new soul
    uint256 public regenPenaltyFactor = 20; // Scaled by 100
    uint256 public regenBoostFactor = 150; // Scaled by 100


    // Events
    event SoulMinted(address indexed owner, uint256 indexed tokenId, uint256 timestamp);
    event TraitUpdated(uint256 indexed tokenId, uint256 wisdom, uint256 creativity, uint256 empathy, uint256 resilience, int256 karma, uint256 timestamp);
    event InteractionRecorded(uint256 indexed tokenId, string interactionType, int256 karmaChange, uint256 timestamp);
    event SoulFused(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId, address newOwner, uint256 timestamp);
    event SoulSacrificed(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event ParameterUpdated(string indexed parameterName, uint256 newValue);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlySoulOwner(uint256 tokenId) {
        require(_owners[tokenId] == msg.sender, "Not soul owner");
        _;
    }

    modifier notDormant(uint256 tokenId) {
        require(!_isDormant[tokenId], "Soul is dormant");
        _;
    }

    // --- Ownership & Admin ---

    constructor() {
        owner = msg.sender;
        _nextTokenId = 1; // Start token IDs from 1
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    // --- Minting & Basic Access ---

    function mintSoul() external returns (uint256) {
        uint256 tokenId = _nextTokenId;
        _owners[tokenId] = msg.sender;
        _soulTraits[tokenId] = SoulTraits({
            wisdom: 10, // Base initial traits
            creativity: 10,
            empathy: 10,
            resilience: 10,
            karma: 0,
            lastActionTimestamp: block.timestamp,
            memoryHash: bytes32(0)
        });
        _isDormant[tokenId] = false;
        _nextTokenId++;
        _totalSupply++;

        emit SoulMinted(msg.sender, tokenId, block.timestamp);
        emit TraitUpdated(tokenId, 10, 10, 10, 10, 0, block.timestamp);

        return tokenId;
    }

    function getSoulOwner(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Soul does not exist");
        return _owners[tokenId];
    }

    function getSoulTraits(uint256 tokenId) public view returns (SoulTraits memory) {
         require(_owners[tokenId] != address(0), "Soul does not exist");
         // Note: This view function *simulates* updating based on time
         // It doesn't change state. Use functions below to actually update state.
         SoulTraits memory currentTraits = _soulTraits[tokenId];
         uint256 timeElapsed = block.timestamp - currentTraits.lastActionTimestamp;

         // Apply simulated time-based changes
         currentTraits.wisdom = currentTraits.wisdom + (timeElapsed / (3600 / baseDecayRate)); // Example: gain wisdom over time
         currentTraits.resilience = currentTraits.resilience + (timeElapsed / (7200 / baseDecayRate)); // Gain resilience slower

         // Add other time-based effects here if needed for the view

         return currentTraits;
    }


    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // --- Trait Evolution & Interaction ---

    // Internal helper to update traits based on time elapsed
    function _updateTraitsBasedOnTime(uint256 tokenId) internal {
        SoulTraits storage soul = _soulTraits[tokenId];
        uint256 timeElapsed = block.timestamp - soul.lastActionTimestamp;

        // Apply passive decay/growth
        // Example: Wisdom grows slowly, others might decay if no action?
        // Simple example: Wisdom and Resilience grow, Creativity and Empathy decay slightly without interaction
        uint256 wisdomGrowth = (timeElapsed * baseDecayRate) / 3600; // Gain per hour
        uint256 resilienceGrowth = (timeElapsed * baseDecayRate) / 7200; // Gain per 2 hours

        uint256 decayAmount = (timeElapsed * baseDecayRate) / 10800; // Decay per 3 hours

        soul.wisdom += wisdomGrowth;
        soul.resilience += resilienceGrowth;

        if (soul.creativity > decayAmount) soul.creativity -= decayAmount; else soul.creativity = 0;
        if (soul.empathy > decayAmount) soul.empathy -= decayAmount; else soul.empathy = 0;


        // Update timestamp
        soul.lastActionTimestamp = block.timestamp;

        // Emit a general trait update event if significant change occurred? Or only on explicit actions?
        // Let's emit on explicit actions for clarity.
    }

    function recordGeneralInteraction(uint256 tokenId, int256 karmaImpact) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        soul.karma += karmaImpact; // Directly affect karma

        // Minor random-ish fluctuations based on interaction type and karma?
        // For simplicity, let's make it a direct karma change for 'general interaction'.
        // Other functions below handle specific trait changes.

        emit InteractionRecorded(tokenId, "General", karmaImpact, block.timestamp);
        emit TraitUpdated(tokenId, soul.wisdom, soul.creativity, soul.empathy, soul.resilience, soul.karma, block.timestamp);
    }

    function contemplate(uint256 tokenId, uint256 duration) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        // Boost wisdom significantly based on duration, maybe small boost to resilience
        uint256 wisdomGain = (duration * interactionWisdomFactor); // Duration could be abstract points/seconds
        uint256 resilienceGain = (duration * interactionResilienceFactor) / 10; // Smaller gain

        soul.wisdom += wisdomGain;
        soul.resilience += resilienceGain;

        // Minor karma effect? Contemplation is neutral/positive?
        soul.karma += int256(duration / 100); // Small positive karma for introspection

        emit InteractionRecorded(tokenId, "Contemplate", int256(duration / 100), block.timestamp);
        emit TraitUpdated(tokenId, soul.wisdom, soul.creativity, soul.empathy, soul.resilience, soul.karma, block.timestamp);
    }

     function createSomething(uint256 tokenId, uint256 effort) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        // Boost creativity significantly, maybe affects other traits based on karma?
        uint256 creativityGain = (effort * interactionCreativityFactor);
        int256 karmaEffect = soul.karma / 100; // Positive karma helps, negative hinders other traits slightly

        soul.creativity += creativityGain;
        if (soul.wisdom > 0 && karmaEffect < 0) soul.wisdom = uint256(int256(soul.wisdom) + karmaEffect); // If creativity is draining wisdom negatively
        if (soul.empathy > 0 && karmaEffect < 0) soul.empathy = uint256(int256(soul.empathy) + karmaEffect); // If creativity is draining empathy negatively

        emit InteractionRecorded(tokenId, "Create", 0, block.timestamp); // No direct karma change from creation itself
        emit TraitUpdated(tokenId, soul.wisdom, soul.creativity, soul.empathy, soul.resilience, soul.karma, block.timestamp);
    }

    function showEmpathy(uint256 tokenId, uint256 empathyAmount) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        // Boost empathy, positively affect karma and resilience
        uint256 empathyGain = (empathyAmount * interactionEmpathyFactor);
        uint256 resilienceGain = empathyAmount / 20; // Empathy builds resilience

        soul.empathy += empathyGain;
        soul.resilience += resilienceGain;
        soul.karma += int256(empathyAmount / 5); // Empathy is karmically positive

        emit InteractionRecorded(tokenId, "Empathy", int256(empathyAmount / 5), block.timestamp);
        emit TraitUpdated(tokenId, soul.wisdom, soul.creativity, soul.empathy, soul.resilience, soul.karma, block.timestamp);
    }

    function faceChallenge(uint256 tokenId, uint256 challengeSeverity) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        // Boost resilience significantly, might negatively affect others or karma based on outcome/severity?
        uint256 resilienceGain = (challengeSeverity * interactionResilienceFactor);
        int256 karmaEffect = int256(challengeSeverity / 10) * -1; // Challenges can be karmically neutral or slightly negative

        soul.resilience += resilienceGain;
         if (soul.wisdom > 0 && karmaEffect < 0) soul.wisdom = uint256(int256(soul.wisdom) + karmaEffect); // Challenges drain wisdom?
        if (soul.empathy > 0 && karmaEffect < 0) soul.empathy = uint256(int256(soul.empathy) + karmaEffect); // Challenges harden empathy?


        soul.karma += karmaEffect;

        emit InteractionRecorded(tokenId, "Challenge", karmaEffect, block.timestamp);
        emit TraitUpdated(tokenId, soul.wisdom, soul.creativity, soul.empathy, soul.resilience, soul.karma, block.timestamp);
    }

    function decayKarma(uint256 tokenId) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        int256 decayAmount = int256(karmaDecayRate);
        if (soul.karma > 0) {
            if (soul.karma > decayAmount) soul.karma -= decayAmount; else soul.karma = 0;
        } else if (soul.karma < 0) {
             if (soul.karma < -decayAmount) soul.karma += decayAmount; else soul.karma = 0; // Moving towards zero from negative
        }

        emit InteractionRecorded(tokenId, "Karma Decay", -decayAmount, block.timestamp);
         // Don't emit TraitUpdated here unless other traits are affected by karma decay itself
    }


    // --- Advanced & Creative Concepts ---

    function getPredictedTraitEvolution(uint256 tokenId, uint256 timeDelta) public view returns (SoulTraits memory) {
        require(_owners[tokenId] != address(0), "Soul does not exist");
        SoulTraits memory predictedTraits = _soulTraits[tokenId];

        // Simulate the _updateTraitsBasedOnTime logic
        uint256 simulatedTimeElapsed = timeDelta; // Simulate evolution over this period

        uint256 wisdomGrowth = (simulatedTimeElapsed * baseDecayRate) / 3600;
        uint256 resilienceGrowth = (simulatedTimeElapsed * baseDecayRate) / 7200;
        uint256 decayAmount = (simulatedTimeElapsed * baseDecayRate) / 10800;

        predictedTraits.wisdom += wisdomGrowth;
        predictedTraits.resilience += resilienceGrowth;

        if (predictedTraits.creativity > decayAmount) predictedTraits.creativity -= decayAmount; else predictedTraits.creativity = 0;
        if (predictedTraits.empathy > decayAmount) predictedTraits.empathy -= decayAmount; else predictedTraits.empathy = 0;

        // Note: Karma decay is not automatic time-based decay in _updateTraitsBasedOnTime,
        // it's triggered explicitly by decayKarma. So karma is not predicted here.

        return predictedTraits;
    }

    function fuseSouls(uint256 tokenId1, uint256 tokenId2) external onlySoulOwner(tokenId1) onlySoulOwner(tokenId2) notDormant(tokenId1) notDormant(tokenId2) returns (uint256 newTokenId) {
        _updateTraitsBasedOnTime(tokenId1); // Update before fusion
        _updateTraitsBasedOnTime(tokenId2);

        SoulTraits storage soul1 = _soulTraits[tokenId1];
        SoulTraits storage soul2 = _soulTraits[tokenId2];

        // Logic to derive new soul traits from the two fused souls
        // Example: Average of traits, multiplied by a fusion multiplier
        uint256 newWisdom = ((soul1.wisdom + soul2.wisdom) / 2 * fusionMultiplier) / 100;
        uint256 newCreativity = ((soul1.creativity + soul2.creativity) / 2 * fusionMultiplier) / 100;
        uint256 newEmpathy = ((soul1.empathy + soul2.empathy) / 2 * fusionMultiplier) / 100;
        uint256 newResilience = ((soul1.resilience + soul2.resilience) / 2 * fusionMultiplier) / 100;
        int256 newKarma = (soul1.karma + soul2.karma) / 2; // Average karma

        newTokenId = _nextTokenId;
        _owners[newTokenId] = msg.sender; // New soul belongs to the caller
        _soulTraits[newTokenId] = SoulTraits({
            wisdom: newWisdom,
            creativity: newCreativity,
            empathy: newEmpathy,
            resilience: newResilience,
            karma: newKarma,
            lastActionTimestamp: block.timestamp,
            memoryHash: bytes32(0) // New soul starts with no memory hash
        });
         _isDormant[newTokenId] = false;

        // Mark the original souls as dormant
        _isDormant[tokenId1] = true;
        _isDormant[tokenId2] = true;

        _nextTokenId++;
         _totalSupply++; // Fusion adds a new soul

        emit SoulFused(tokenId1, tokenId2, newTokenId, msg.sender, block.timestamp);
        emit SoulMinted(msg.sender, newTokenId, block.timestamp); // Also emit minted for the new soul
        emit TraitUpdated(newTokenId, newWisdom, newCreativity, newEmpathy, newResilience, newKarma, block.timestamp);

        // Optional: Emit event for the old souls being marked dormant
        // emit SoulSacrificed(tokenId1, msg.sender, block.timestamp); // Re-using Sacrifice event metaphorically
        // emit SoulSacrificed(tokenId2, msg.sender, block.timestamp);

        return newTokenId;
    }

    function sacrificeSoul(uint256 tokenId) external onlySoulOwner(tokenId) notDormant(tokenId) {
        // Soul is marked dormant. Its "essence" (trait value) is gone.
        // Could be used to boost *another* active soul of the owner, but keeping it simple: just mark dormant.
         _updateTraitsBasedOnTime(tokenId); // Final update before sacrifice
        _isDormant[tokenId] = true;

        // Optionally, calculate essence value before sacrifice and emit it
        // uint256 essenceValue = _calculateEssenceValue(tokenId);
        // emit SoulSacrificed(tokenId, msg.sender, essenceValue, block.timestamp); // Example with value

        emit SoulSacrificed(tokenId, msg.sender, block.timestamp);
    }

    // Internal helper to calculate a hypothetical "essence" or harmony score
    // (Can be called by queryAuraHarmony or maybe internally for sacrifice value)
     function _calculateAuraHarmony(SoulTraits memory traits) internal pure returns (uint256 harmonyScore) {
        // Simple example: Sum of positive traits, maybe penalized by absolute karma value if negative
        uint256 sumPositiveTraits = traits.wisdom + traits.creativity + traits.empathy + traits.resilience;
        if (traits.karma >= 0) {
            harmonyScore = sumPositiveTraits + uint256(traits.karma);
        } else {
             // Penalize harmony for negative karma
             // Use safe math: sum - abs(karma)
            uint256 absKarma = uint256(traits.karma * -1);
             if (sumPositiveTraits > absKarma) {
                 harmonyScore = sumPositiveTraits - absKarma;
             } else {
                 harmonyScore = 0; // Harmony goes to zero or negative if karma is too bad
             }
        }
        // Add other factors, e.g., trait balance
        // Example: Simple balance check - low harmony if one trait is extremely high and others low
        // This is a placeholder for more complex on-chain math if needed.
        return harmonyScore;
    }

    function queryAuraHarmony(uint256 tokenId) public view returns (uint256) {
        // Automatically updates traits based on time in the view function before calculating
        SoulTraits memory traits = getSoulTraits(tokenId);
        return _calculateAuraHarmony(traits);
    }

    function imprintMemoryHash(uint256 tokenId, bytes32 memoryHash) external onlySoulOwner(tokenId) notDormant(tokenId) {
         require(_owners[tokenId] != address(0), "Soul does not exist");
        _soulTraits[tokenId].memoryHash = memoryHash;
         // No trait update needed for this, just data storage
         emit InteractionRecorded(tokenId, "Imprint Memory", 0, block.timestamp); // Event to signal action
    }

    // Allows retrieving the imprinted memory hash
    function getAssociatedMemoryHash(uint256 tokenId) public view returns (bytes32) {
         require(_owners[tokenId] != address(0), "Soul does not exist");
        return _soulTraits[tokenId].memoryHash;
    }


    function regenerateAura(uint256 tokenId, uint256 essenceCost) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        // Simulate a regeneration process
        // Boost certain traits significantly, potentially reset others or apply penalties
        // essenceCost is an abstract parameter affecting the outcome

        // Example: Boost Wisdom & Resilience, maybe reduce Creativity & Empathy slightly, reset Karma towards zero
        uint256 boost = (essenceCost * regenBoostFactor) / 100;
        uint256 penalty = (essenceCost * regenPenaltyFactor) / 100;

        soul.wisdom += boost;
        soul.resilience += boost / 2; // Resilience gets half the boost

        if (soul.creativity > penalty) soul.creativity -= penalty; else soul.creativity = 0;
        if (soul.empathy > penalty) soul.empathy -= penalty; else soul.empathy = 0;

        // Move karma towards zero, faster for higher essenceCost
        int256 karmaShift = int256(essenceCost / 5); // Shift amount
        if (soul.karma > 0) {
            if (soul.karma > karmaShift) soul.karma -= karmaShift; else soul.karma = 0;
        } else if (soul.karma < 0) {
            if (soul.karma < -karmaShift) soul.karma += karmaShift; else soul.karma = 0;
        }

        soul.lastActionTimestamp = block.timestamp; // Update timestamp

        emit InteractionRecorded(tokenId, "Regenerate Aura", 0, block.timestamp);
        emit TraitUpdated(tokenId, soul.wisdom, soul.creativity, soul.empathy, soul.resilience, soul.karma, block.timestamp);
    }

    function attuneToExternalFactor(uint256 tokenId, uint256 externalFactor) external onlySoulOwner(tokenId) notDormant(tokenId) {
        _updateTraitsBasedOnTime(tokenId);
        SoulTraits storage soul = _soulTraits[tokenId];

        // Simulate influence from an external factor (represented by externalFactor)
        // Example: externalFactor modulo 4 determines which trait gets a small random-ish boost
        uint256 factorEffect = externalFactor % 100; // Keep effect bounded

        if (externalFactor % 4 == 0) {
            soul.wisdom += factorEffect;
        } else if (externalFactor % 4 == 1) {
            soul.creativity += factorEffect;
        } else if (externalFactor % 4 == 2) {
            soul.empathy += factorEffect;
        } else {
            soul.resilience += factorEffect;
        }

        // Small karma effect based on factor? Odd is negative, even positive?
         if (externalFactor % 2 == 0) soul.karma += int256(factorEffect / 10); else soul.karma -= int256(factorEffect / 10);


        soul.lastActionTimestamp = block.timestamp; // Update timestamp

        emit InteractionRecorded(tokenId, "Attune to Factor", 0, block.timestamp); // Karma change is internal effect
        emit TraitUpdated(tokenId, soul.wisdom, soul.creativity, soul.empathy, soul.resilience, soul.karma, block.timestamp);
    }

     function getDormantStatus(uint256 tokenId) public view returns (bool) {
         require(_owners[tokenId] != address(0), "Soul does not exist");
        return _isDormant[tokenId];
    }


    // --- Parameter Adjustment (Owner Only) ---

    function setBaseDecayRate(uint256 rate) external onlyOwner {
        baseDecayRate = rate;
        emit ParameterUpdated("baseDecayRate", rate);
    }

    function setInteractionImpactFactors(uint256 wisdomFactor, uint256 creativityFactor, uint256 empathyFactor, uint256 resilienceFactor) external onlyOwner {
        interactionWisdomFactor = wisdomFactor;
        interactionCreativityFactor = creativityFactor;
        interactionEmpathyFactor = empathyFactor;
        interactionResilienceFactor = resilienceFactor;
        emit ParameterUpdated("interactionFactors", 0); // Use 0 or combined value if appropriate
    }

     function setFusionMultiplier(uint256 multiplier) external onlyOwner {
         fusionMultiplier = multiplier;
         emit ParameterUpdated("fusionMultiplier", multiplier);
     }

    function setRegenerationCostFactors(uint256 penaltyFactor, uint256 boostFactor) external onlyOwner {
        regenPenaltyFactor = penaltyFactor;
        regenBoostFactor = boostFactor;
         emit ParameterUpdated("regenerationFactors", 0); // Use 0 or combined value if appropriate
    }

     function setKarmaDecayRate(uint256 rate) external onlyOwner {
        karmaDecayRate = rate;
        emit ParameterUpdated("karmaDecayRate", rate);
    }

    // Fallback function to prevent accidental ETH sends (optional but good practice)
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("Call to non-existent function or unexpected ETH");
    }
}
```