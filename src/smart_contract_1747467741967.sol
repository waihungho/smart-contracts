Okay, let's create a smart contract concept that is interesting, advanced, creative, and trendy without being a direct copy of common open-source templates.

We'll design a contract called `DigitalSoulForge` that manages non-transferable (Soulbound-like) digital entities called "Souls". These Souls have dynamic traits, evolve through interactions and environmental factors, can form bonds with other Souls, and can be sacrificed for benefits.

**Core Concepts:**

1.  **Digital Souls:** Unique, non-transferable entities represented by an ID. Owned by an address.
2.  **Dynamic Traits:** Souls have numerical and boolean traits that change based on interactions, time, and environment.
3.  **Evolution:** Souls progress through different states (Seed, Adolescent, Mature, Awakened, Dormant) based on meeting certain criteria (traits, age, interactions).
4.  **Interaction:** Users can perform different types of interactions with their Souls, consuming gas but influencing traits and evolution.
5.  **Environment:** The contract has global parameters that change over time (based on block data, simulating environmental shifts) which influence trait changes and evolution conditions.
6.  **Attunement:** An owner can attune two of their Souls, creating a linked pair where interactions with one might influence the other.
7.  **Sacrifice:** A Soul can be sacrificed (burned), providing a benefit to the owner or another owned Soul, depending on the sacrificed Soul's state and traits.
8.  **Soulbound Nature:** Souls are generally non-transferable, emphasizing identity and history. (We won't implement ERC-721 transfer functions).
9.  **Pseudo-Randomness:** Initial traits and some environmental factors are influenced by block data (with awareness of its limitations for true randomness).

---

## Smart Contract Outline & Function Summary: `DigitalSoulForge.sol`

**Contract Name:** `DigitalSoulForge`

**Description:** A contract for forging, interacting with, and evolving unique, non-transferable digital entities called Souls. Souls possess dynamic traits influenced by owner interactions and environmental factors, can be attuned to each other, and can be sacrificed for various effects.

---

**State Variables:**

*   `owner`: The contract administrator address.
*   `soulCounter`: Counter for assigning unique Soul IDs.
*   `souls`: Mapping from Soul ID to Soul struct.
*   `ownerSouls`: Mapping from owner address to an array of their Soul IDs.
*   `forgingCost`: Cost in Ether to forge a new Soul.
*   `traitBaseValues`: Base values for initial trait generation.
*   `evolutionThresholds`: Requirements for Souls to evolve to the next state.
*   `environmentBaseFactor`: Base value for the dynamic environment factor.

**Structs & Enums:**

*   `SoulState`: Enum for Soul lifecycle stages (Seed, Adolescent, Mature, Awakened, Dormant, Sacrificed).
*   `InteractionType`: Enum for types of interactions (Nourish, Train, Meditate, Explore).
*   `SoulTraits`: Struct holding numerical and boolean traits (strength, intellect, affinity, purity, corruption, isAwakened).
*   `EvolutionRequirement`: Struct defining conditions for state evolution.
*   `Soul`: Struct combining all Soul data.

**Events:**

*   `SoulForged`: When a new Soul is created.
*   `SoulInteracted`: When a Soul is interacted with.
*   `SoulEvolved`: When a Soul changes state.
*   `SoulsAttuned`: When two Souls are attuned.
*   `AttunementBroken`: When attunement is broken.
*   `SoulSacrificed`: When a Soul is sacrificed.
*   `EnvironmentFactorUpdated`: When the environment factor changes (calculated internally).
*   `AdminParameterUpdated`: When an admin setting is changed.

---

**Function Summary (26 Functions):**

1.  `constructor()`: Initializes the contract with owner and initial parameters.
2.  `forgeSoul(string memory _archetype)`: *Payable.* Creates a new Soul for the caller, assigns initial traits based on input archetype, environment, and pseudo-randomness. Sets state to Seed.
3.  `getSoulDetails(uint256 _soulId)`: *View.* Retrieves the complete data struct for a given Soul ID.
4.  `getSoulTraits(uint256 _soulId)`: *View.* Retrieves only the traits struct for a given Soul ID.
5.  `getSoulState(uint256 _soulId)`: *View.* Retrieves the current state enum of a Soul.
6.  `getOwnerOfSoul(uint256 _soulId)`: *View.* Retrieves the owner address of a Soul.
7.  `getTotalSouls()`: *View.* Returns the total number of Souls forged.
8.  `getSoulsByOwner(address _owner)`: *View.* Returns an array of Soul IDs owned by a specific address.
9.  `interactWithSoul(uint256 _soulId, InteractionType _interactionType)`: Allows the owner to interact with their Soul, updating traits and checking for evolution readiness.
10. `checkEvolutionReadiness(uint256 _soulId)`: *View.* Checks if a Soul meets the *minimum* requirements to potentially evolve to the next state based on its current state, traits, and age.
11. `attuneSouls(uint256 _soulId1, uint256 _soulId2)`: Allows the owner to attune two of their Souls, creating a bond. Requires souls to be in compatible states.
12. `breakAttunement(uint256 _soulId)`: Allows the owner to break the attunement bond of one of their Souls.
13. `getAttunedPair(uint256 _soulId)`: *View.* Returns the ID of the Soul a given Soul is attuned to, or 0 if none.
14. `sacrificeSoul(uint256 _soulId, uint256 _targetSoulIdForBenefit)`: Allows the owner to sacrifice a Soul. Sets state to Sacrificed, removes from owner's list, and applies a benefit to a specified target soul based on the sacrificed soul's state/traits.
15. `getCurrentEnvironmentFactor()`: *View.* Calculates and returns the current environment factor based on internal logic (e.g., block number, timestamp).
16. `getForgingCost()`: *View.* Returns the current cost to forge a Soul.
17. `getTraitBaseValue(string memory _traitName)`: *View.* Returns the base value for a specific trait.
18. `getEvolutionThreshold(SoulState _currentState, string memory _requirementType)`: *View.* Returns a specific evolution requirement value for transitioning from a given state.
19. `performComplexRitual(uint256 _soulId)`: A more complex interaction function. Might require specific conditions (e.g., high trait values, attunement, elapsed time) and has a significant or unique effect on the Soul's state or traits.
20. `calculateSoulAge(uint256 _soulId)`: *View.* Calculates the age of a Soul in seconds based on its creation timestamp.
21. `calculateCurrentTraitValue(uint256 _soulId, string memory _traitName)`: *View.* Calculates the *effective* trait value, incorporating base value, state modifiers, and environment factor.
22. `setForgingCost(uint256 _newCost)`: *Owner Only.* Sets the cost to forge a Soul.
23. `setTraitBaseValue(string memory _traitName, uint256 _newValue)`: *Owner Only.* Sets the base value for a specific trait.
24. `setEvolutionThreshold(SoulState _currentState, string memory _requirementType, uint256 _newValue)`: *Owner Only.* Sets an evolution requirement value for a state transition.
25. `setEnvironmentBaseFactor(uint256 _newBaseFactor)`: *Owner Only.* Sets the base value for the environment factor calculation.
26. `withdrawFees()`: *Owner Only.* Allows the owner to withdraw collected Ether from forging fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Smart Contract Outline & Function Summary: DigitalSoulForge.sol ---
//
// Contract Name: DigitalSoulForge
//
// Description: A contract for forging, interacting with, and evolving unique,
//              non-transferable digital entities called Souls. Souls possess
//              dynamic traits influenced by owner interactions and environmental
//              factors, can be attuned to each other, and can be sacrificed
//              for various effects. Emphasizes dynamic state, soulbound-like
//              nature, and on-chain interactions influencing entity properties.
//
// Core Concepts:
// - Digital Souls: Non-transferable entities with unique IDs and owners.
// - Dynamic Traits: Traits change based on interactions, time, and environment.
// - Evolution: Souls progress through states (Seed, Adolescent, etc.) based on criteria.
// - Interaction: Owner actions modify Soul traits and potentially trigger evolution.
// - Environment: Global parameters influence Soul traits and evolution.
// - Attunement: Linking two Souls owned by the same address.
// - Sacrifice: Burning a Soul for benefits to another Soul or owner.
// - Soulbound Nature: Souls are not designed for trading.
//
// State Variables:
// - owner: Contract administrator.
// - soulCounter: Incremental ID for new Souls.
// - souls: Mapping ID -> Soul struct.
// - ownerSouls: Mapping owner address -> array of Soul IDs.
// - forgingCost: Cost in Ether to forge.
// - traitBaseValues: Mapping trait name -> base value.
// - evolutionThresholds: Mapping current state -> requirement type -> threshold value.
// - environmentBaseFactor: Base value for dynamic environment calculation.
//
// Structs & Enums:
// - SoulState: Lifecycle stages.
// - InteractionType: Types of owner actions.
// - SoulTraits: Soul properties (strength, intellect, affinity, purity, corruption, isAwakened).
// - EvolutionRequirement: Defines needed values for state change.
// - Soul: Main data structure for a Soul entity.
//
// Events:
// - SoulForged, SoulInteracted, SoulEvolved, SoulsAttuned, AttunementBroken,
//   SoulSacrificed, EnvironmentFactorUpdated, AdminParameterUpdated.
//
// Function Summary (26 Functions):
// 1.  constructor(): Initialize contract.
// 2.  forgeSoul(string memory _archetype): Payable. Create new Soul.
// 3.  getSoulDetails(uint256 _soulId): View. Get full Soul data.
// 4.  getSoulTraits(uint256 _soulId): View. Get Soul traits only.
// 5.  getSoulState(uint256 _soulId): View. Get Soul state only.
// 6.  getOwnerOfSoul(uint256 _soulId): View. Get Soul owner.
// 7.  getTotalSouls(): View. Get total number forged.
// 8.  getSoulsByOwner(address _owner): View. Get all Soul IDs for an owner.
// 9.  interactWithSoul(uint256 _soulId, InteractionType _interactionType): Interact with Soul, update traits, check evolution.
// 10. checkEvolutionReadiness(uint256 _soulId): View. Check if evolution criteria are met.
// 11. attuneSouls(uint256 _soulId1, uint256 _soulId2): Attune two owned Souls.
// 12. breakAttunement(uint256 _soulId): Break attunement for a Soul.
// 13. getAttunedPair(uint256 _soulId): View. Get partner ID of an attuned Soul.
// 14. sacrificeSoul(uint256 _soulId, uint256 _targetSoulIdForBenefit): Sacrifice a Soul for target Soul benefit.
// 15. getCurrentEnvironmentFactor(): View. Calculate dynamic environment factor.
// 16. getForgingCost(): View. Get current forging cost.
// 17. getTraitBaseValue(string memory _traitName): View. Get a trait's base value.
// 18. getEvolutionThreshold(SoulState _currentState, string memory _requirementType): View. Get evolution threshold for a state/type.
// 19. performComplexRitual(uint256 _soulId): Perform complex interaction with significant effects.
// 20. calculateSoulAge(uint256 _soulId): View. Calculate Soul age.
// 21. calculateCurrentTraitValue(uint256 _soulId, string memory _traitName): View. Calculate effective trait value (base + state + environment).
// 22. setForgingCost(uint256 _newCost): Owner Only. Set forging cost.
// 23. setTraitBaseValue(string memory _traitName, uint256 _newValue): Owner Only. Set trait base value.
// 24. setEvolutionThreshold(SoulState _currentState, string memory _requirementType, uint256 _newValue): Owner Only. Set evolution threshold.
// 25. setEnvironmentBaseFactor(uint256 _newBaseFactor): Owner Only. Set environment base.
// 26. withdrawFees(): Owner Only. Withdraw contract balance.
//
// --- End of Outline ---

contract DigitalSoulForge {
    address public owner;
    uint256 private soulCounter;

    enum SoulState { Seed, Adolescent, Mature, Awakened, Dormant, Sacrificed }
    enum InteractionType { Nourish, Train, Meditate, Explore }

    struct SoulTraits {
        uint256 strength;
        uint256 intellect;
        uint256 affinity;
        uint256 purity; // Represents connection to harmonious forces
        uint256 corruption; // Represents connection to chaotic forces
        bool isAwakened; // Special state unlocked via ritual/evolution
    }

    struct Soul {
        uint256 id;
        address owner;
        SoulState state;
        SoulTraits traits;
        uint64 creationTimestamp;
        uint64 lastInteractionTimestamp;
        uint256 attunedPartnerId; // ID of the soul it's attuned to (0 if none)
        string archetype; // e.g., "Guardian", "Sage", "Nomad"
    }

    // Mapping from Soul ID to Soul data
    mapping(uint256 => Soul) private souls;

    // Mapping from owner address to an array of Soul IDs they own
    // Note: Adding/removing from dynamic arrays can be gas-intensive,
    // especially removing from the middle. For simplicity here, we use it,
    // but for production, consider alternative structures or append-only + status.
    mapping(address => uint256[]) public ownerSouls;
    mapping(uint256 => bool) private soulExists; // Helper for quick existence check

    // Contract Parameters
    uint256 public forgingCost;

    // Base values for initial trait generation
    mapping(string => uint256) public traitBaseValues;

    // Requirements for Souls to evolve
    // State -> RequirementType -> Value
    mapping(SoulState => mapping(string => uint256)) public evolutionThresholds;

    // Dynamic Environment Factor
    uint256 public environmentBaseFactor;

    // --- Events ---

    event SoulForged(uint256 indexed soulId, address indexed owner, string archetype, uint256 cost);
    event SoulInteracted(uint256 indexed soulId, InteractionType interactionType, uint64 timestamp);
    event SoulEvolved(uint256 indexed soulId, SoulState oldState, SoulState newState);
    event SoulsAttuned(uint256 indexed soulId1, uint256 indexed soulId2, address indexed owner);
    event AttunementBroken(uint256 indexed soulId1, uint256 indexed soulId2, address indexed owner);
    event SoulSacrificed(uint256 indexed soulId, address indexed owner, uint256 targetSoulIdForBenefit);
    event EnvironmentFactorUpdated(uint256 newFactor, uint64 timestamp);
    event AdminParameterUpdated(string paramName, uint256 newValue); // Simplified for various param types

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier soulMustExist(uint256 _soulId) {
        require(soulExists[_soulId], "Soul does not exist");
        _;
    }

    modifier onlySoulOwner(uint256 _soulId) {
        require(soulExists[_soulId], "Soul does not exist");
        require(souls[_soulId].owner == msg.sender, "Not soul owner");
        _;
    }

    modifier soulNotInState(uint256 _soulId, SoulState _state) {
        require(soulExists[_soulId], "Soul does not exist");
        require(souls[_soulId].state != _state, string(abi.encodePacked("Soul is in state ", uint256(_state), " and cannot perform this action")));
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        soulCounter = 0;
        forgingCost = 0.01 ether; // Initial cost

        // Set some initial base values for traits (example values)
        traitBaseValues["strength"] = 10;
        traitBaseValues["intellect"] = 10;
        traitBaseValues["affinity"] = 10;
        traitBaseValues["purity"] = 5;
        traitBaseValues["corruption"] = 5;

        // Set some initial evolution thresholds (example values)
        // Seed -> Adolescent: Needs certain age and interactions
        evolutionThresholds[SoulState.Seed]["minAge"] = 1 days; // Age in seconds
        evolutionThresholds[SoulState.Seed]["minInteractions"] = 5; // Placeholder: requires tracking interactions, simplified here by time/traits
        evolutionThresholds[SoulState.Seed]["minTraitSum"] = 50; // Example: sum of str, int, aff

        // Adolescent -> Mature: Needs higher traits and maybe purity/corruption balance
        evolutionThresholds[SoulState.Adolescent]["minTraitSum"] = 100;
        evolutionThresholds[SoulState.Adolescent]["minPurity"] = 20;

        // Mature -> Awakened: Complex ritual or high purity/low corruption
        evolutionThresholds[SoulState.Mature]["minPurityForAwaken"] = 80;
        evolutionThresholds[SoulState.Mature]["maxCorruptionForAwaken"] = 10;

        // Mature -> Dormant: Low interaction over time (simplified by low trait sum)
        evolutionThresholds[SoulState.Mature]["maxTraitSumForDormant"] = 60; // Example

        environmentBaseFactor = 100; // Base influence factor
    }

    // --- Core Functions ---

    /**
     * @notice Forges a new Digital Soul for the caller.
     * @param _archetype The initial archetype string for the soul (influences base traits).
     */
    function forgeSoul(string memory _archetype) public payable soulNotInState(0, SoulState.Sacrificed) { // State check for 0 is effectively unused but demonstrates modifier usage
        require(msg.value >= forgingCost, "Insufficient Ether to forge Soul");

        soulCounter++;
        uint256 newSoulId = soulCounter;
        address currentOwner = msg.sender;
        uint64 currentTimestamp = uint64(block.timestamp);

        // Basic Pseudo-Randomness for Initial Traits (Warning: Not cryptographically secure)
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newSoulId)));

        SoulTraits memory initialTraits;
        initialTraits.strength = (traitBaseValues["strength"] + (seed % 20)) % 100; // Base + random variation
        initialTraits.intellect = (traitBaseValues["intellect"] + ((seed / 100) % 20)) % 100;
        initialTraits.affinity = (traitBaseValues["affinity"] + ((seed / 10000) % 20)) % 100;
        initialTraits.purity = (traitBaseValues["purity"] + ((seed / 1000000) % 10)) % 50;
        initialTraits.corruption = (traitBaseValues["corruption"] + ((seed / 100000000) % 10)) % 50;
        initialTraits.isAwakened = false; // Starts not awakened

        // Influence traits based on archetype (simple example)
        if (keccak256(abi.encodePacked(_archetype)) == keccak256(abi.encodePacked("Guardian"))) {
            initialTraits.strength = initialTraits.strength + 15 > 100 ? 100 : initialTraits.strength + 15;
        } else if (keccak256(abi.encodePacked(_archetype)) == keccak256(abi.encodePacked("Sage"))) {
             initialTraits.intellect = initialTraits.intellect + 15 > 100 ? 100 : initialTraits.intellect + 15;
        } // Add more archetypes and trait influences

        souls[newSoulId] = Soul({
            id: newSoulId,
            owner: currentOwner,
            state: SoulState.Seed,
            traits: initialTraits,
            creationTimestamp: currentTimestamp,
            lastInteractionTimestamp: currentTimestamp,
            attunedPartnerId: 0, // Not attuned initially
            archetype: _archetype
        });

        soulExists[newSoulId] = true;
        ownerSouls[currentOwner].push(newSoulId);

        emit SoulForged(newSoulId, currentOwner, _archetype, forgingCost);
    }

    /**
     * @notice Retrieves the full details of a Soul.
     * @param _soulId The ID of the Soul.
     * @return The Soul struct.
     */
    function getSoulDetails(uint256 _soulId) public view soulMustExist(_soulId) returns (Soul memory) {
        return souls[_soulId];
    }

     /**
     * @notice Retrieves only the traits of a Soul.
     * @param _soulId The ID of the Soul.
     * @return The SoulTraits struct.
     */
    function getSoulTraits(uint256 _soulId) public view soulMustExist(_soulId) returns (SoulTraits memory) {
        return souls[_soulId].traits;
    }

    /**
     * @notice Retrieves the current state of a Soul.
     * @param _soulId The ID of the Soul.
     * @return The SoulState enum value.
     */
    function getSoulState(uint256 _soulId) public view soulMustExist(_soulId) returns (SoulState) {
        return souls[_soulId].state;
    }

    /**
     * @notice Retrieves the owner address of a Soul.
     * @param _soulId The ID of the Soul.
     * @return The owner's address.
     */
    function getOwnerOfSoul(uint256 _soulId) public view soulMustExist(_soulId) returns (address) {
        return souls[_soulId].owner;
    }

    /**
     * @notice Returns the total number of Souls that have been forged.
     * @return The total count of Souls.
     */
    function getTotalSouls() public view returns (uint256) {
        return soulCounter;
    }

    /**
     * @notice Returns the list of Soul IDs owned by a specific address.
     * @param _owner The address to check.
     * @return An array of Soul IDs.
     */
    function getSoulsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerSouls[_owner];
    }

    // --- Interaction Functions ---

    /**
     * @notice Allows the owner to interact with their Soul, influencing its traits and evolution.
     * @param _soulId The ID of the Soul to interact with.
     * @param _interactionType The type of interaction being performed.
     */
    function interactWithSoul(uint256 _soulId, InteractionType _interactionType)
        public
        onlySoulOwner(_soulId)
        soulNotInState(_soulId, SoulState.Sacrificed)
        soulNotInState(_soulId, SoulState.Dormant) // Dormant souls might not respond to standard interaction
    {
        Soul storage soul = souls[_soulId];
        uint64 currentTimestamp = uint64(block.timestamp);

        // Apply interaction effects based on type and current state/environment
        uint256 envFactor = getCurrentEnvironmentFactor(); // Incorporate dynamic environment

        if (_interactionType == InteractionType.Nourish) {
            soul.traits.strength = (soul.traits.strength + envFactor / 10 + 5) % 101; // Add some base value + env influence
            soul.traits.affinity = (soul.traits.affinity + envFactor / 10 + 3) % 101;
            soul.traits.corruption = soul.traits.corruption > (envFactor / 20 + 1) ? soul.traits.corruption - (envFactor / 20 + 1) : 0; // Nourishing reduces corruption
        } else if (_interactionType == InteractionType.Train) {
            soul.traits.strength = (soul.traits.strength + envFactor / 15 + 7) % 101;
            soul.traits.intellect = (soul.traits.intellect + envFactor / 15 + 5) % 101;
             soul.traits.purity = soul.traits.purity > (envFactor / 20 + 1) ? soul.traits.purity - (envFactor / 20 + 1) : 0; // Training might neglect purity
        } else if (_interactionType == InteractionType.Meditate) {
            soul.traits.intellect = (soul.traits.intellect + envFactor / 10 + 6) % 101;
            soul.traits.affinity = (soul.traits.affinity + envFactor / 10 + 6) % 101;
            soul.traits.purity = (soul.traits.purity + envFactor / 15 + 3) % 101; // Meditation increases purity
        } else if (_interactionType == InteractionType.Explore) {
             // Exploration could have mixed effects, maybe randomizing a bit more
            uint256 exploreSeed = uint256(keccak256(abi.encodePacked(block.timestamp, soul.id, _interactionType)));
            if (exploreSeed % 3 == 0) soul.traits.strength = (soul.traits.strength + (exploreSeed % (envFactor/5 + 5))) % 101;
            if (exploreSeed % 3 == 1) soul.traits.intellect = (soul.traits.intellect + ((exploreSeed/100) % (envFactor/5 + 5))) % 101;
            if (exploreSeed % 3 == 2) soul.traits.affinity = (soul.traits.affinity + ((exploreSeed/10000) % (envFactor/5 + 5))) % 101;

            if (exploreSeed % 2 == 0) soul.traits.purity = (soul.traits.purity + (exploreSeed % (envFactor/10 + 2))) % 101;
            else soul.traits.corruption = (soul.traits.corruption + ((exploreSeed/1000000) % (envFactor/10 + 2))) % 101;
        }

        // Prevent spamming interaction - simple cooldown based on last interaction
        require(currentTimestamp > soul.lastInteractionTimestamp + 10, "Interaction cooldown active"); // 10 second cooldown example

        soul.lastInteractionTimestamp = currentTimestamp;

        emit SoulInteracted(_soulId, _interactionType, currentTimestamp);

        // Automatically check and trigger evolution after interaction
        _tryEvolve(_soulId);
    }

    /**
     * @notice Checks if a Soul meets the minimum requirements to potentially evolve.
     * @param _soulId The ID of the Soul.
     * @return True if eligible for evolution, false otherwise.
     */
    function checkEvolutionReadiness(uint256 _soulId) public view soulMustExist(_soulId) returns (bool) {
        Soul storage soul = souls[_soulId];
        uint256 currentAge = calculateSoulAge(_soulId);
        uint256 currentTraitSum = soul.traits.strength + soul.traits.intellect + soul.traits.affinity; // Simplified sum

        // Define evolution logic based on current state and defined thresholds
        if (soul.state == SoulState.Seed) {
            return currentAge >= evolutionThresholds[SoulState.Seed]["minAge"] &&
                   currentTraitSum >= evolutionThresholds[SoulState.Seed]["minTraitSum"];
                   // Add checks for interaction count if you implement tracking
        } else if (soul.state == SoulState.Adolescent) {
             return currentTraitSum >= evolutionThresholds[SoulState.Adolescent]["minTraitSum"] &&
                    soul.traits.purity >= evolutionThresholds[SoulState.Adolescent]["minPurity"];
        } else if (soul.state == SoulState.Mature) {
             // Mature state can evolve to Awakened or potentially Dormant
             // This function only checks for positive evolution paths here for simplicity
             return (soul.traits.purity >= evolutionThresholds[SoulState.Mature]["minPurityForAwaken"] &&
                     soul.traits.corruption <= evolutionThresholds[SoulState.Mature]["maxCorruptionForAwaken"]) ||
                    soul.traits.isAwakened; // Already awakened means ready for Awakened stage
        } else {
            // Souls in other states (Awakened, Dormant, Sacrificed) don't evolve further via standard means
            return false;
        }
    }

    // Internal function to attempt evolution after an action
    function _tryEvolve(uint256 _soulId) internal {
        if (checkEvolutionReadiness(_soulId)) {
            Soul storage soul = souls[_soulId];
            SoulState oldState = soul.state;
            SoulState newState = oldState;

            if (oldState == SoulState.Seed) {
                newState = SoulState.Adolescent;
            } else if (oldState == SoulState.Adolescent) {
                newState = SoulState.Mature;
            } else if (oldState == SoulState.Mature) {
                // Check for Awakened path specifically
                if (soul.traits.purity >= evolutionThresholds[SoulState.Mature]["minPurityForAwaken"] &&
                    soul.traits.corruption <= evolutionThresholds[SoulState.Mature]["maxCorruptionForAwaken"]) {
                    newState = SoulState.Awakened;
                    soul.traits.isAwakened = true; // Unlock awakened trait
                }
                // Dormant transition is checked separately, potentially via lack of interaction or specific condition
                // For now, simplified to only check positive path evolution here
            }

            if (newState != oldState) {
                soul.state = newState;
                emit SoulEvolved(_soulId, oldState, newState);
            }
        }
    }

    // --- Relationship Functions ---

    /**
     * @notice Allows the owner to attune two of their Souls.
     * @param _soulId1 The ID of the first Soul.
     * @param _soulId2 The ID of the second Soul.
     */
    function attuneSouls(uint256 _soulId1, uint256 _soulId2)
        public
        onlySoulOwner(_soulId1)
        onlySoulOwner(_soulId2)
        soulNotInState(_soulId1, SoulState.Sacrificed)
        soulNotInState(_soulId2, SoulState.Sacrificed)
    {
        require(_soulId1 != _soulId2, "Cannot attune a soul to itself");
        require(souls[_soulId1].attunedPartnerId == 0, "Soul 1 is already attuned");
        require(souls[_soulId2].attunedPartnerId == 0, "Soul 2 is already attuned");

        // Add conditions for compatible states or traits if desired
        // require(souls[_soulId1].state == souls[_soulId2].state, "Souls must be in the same state to attune");

        souls[_soulId1].attunedPartnerId = _soulId2;
        souls[_soulId2].attunedPartnerId = _soulId1;

        // Attunement could give a small passive trait boost or interaction synergy
        // Example: small boost to Affinity for both
        souls[_soulId1].traits.affinity = souls[_soulId1].traits.affinity + 5 > 100 ? 100 : souls[_soulId1].traits.affinity + 5;
        souls[_soulId2].traits.affinity = souls[_soulId2].traits.affinity + 5 > 100 ? 100 : souls[_soulId2].traits.affinity + 5;


        emit SoulsAttuned(_soulId1, _soulId2, msg.sender);
    }

    /**
     * @notice Allows the owner to break the attunement bond of one of their Souls.
     * @param _soulId The ID of the Soul whose attunement will be broken.
     */
    function breakAttunement(uint256 _soulId)
        public
        onlySoulOwner(_soulId)
        soulNotInState(_soulId, SoulState.Sacrificed)
    {
        Soul storage soul = souls[_soulId];
        require(soul.attunedPartnerId != 0, "Soul is not attuned");

        uint256 partnerId = soul.attunedPartnerId;
        require(soulExists[partnerId], "Attuned partner does not exist"); // Should not happen if logic is correct

        Soul storage partnerSoul = souls[partnerId];
        require(partnerSoul.attunedPartnerId == _soulId, "Attunement link mismatch"); // Sanity check

        soul.attunedPartnerId = 0;
        partnerSoul.attunedPartnerId = 0;

         // Optional: Apply a penalty or change upon breaking attunement
        soul.traits.affinity = soul.traits.affinity > 3 ? soul.traits.affinity - 3 : 0;
        partnerSoul.traits.affinity = partnerSoul.traits.affinity > 3 ? partnerSoul.traits.affinity - 3 : 0;


        emit AttunementBroken(_soulId, partnerId, msg.sender);
    }

    /**
     * @notice Returns the ID of the Soul a given Soul is attuned to.
     * @param _soulId The ID of the Soul.
     * @return The ID of the attuned partner Soul, or 0 if none.
     */
    function getAttunedPair(uint256 _soulId) public view soulMustExist(_soulId) returns (uint256) {
        return souls[_soulId].attunedPartnerId;
    }

    // --- Utility & Sacrifice Functions ---

    /**
     * @notice Allows the owner to sacrifice a Soul, applying a benefit to another owned Soul.
     * @dev The sacrificed Soul is permanently removed from the owner's list and marked as Sacrificed.
     * @param _soulId The ID of the Soul to sacrifice.
     * @param _targetSoulIdForBenefit The ID of another owned Soul to receive a benefit.
     */
    function sacrificeSoul(uint256 _soulId, uint256 _targetSoulIdForBenefit)
        public
        onlySoulOwner(_soulId)
        soulNotInState(_soulId, SoulState.Sacrificed)
        onlySoulOwner(_targetSoulIdForBenefit) // Target must also be owned by caller
        soulNotInState(_targetSoulIdForBenefit, SoulState.Sacrificed)
    {
        Soul storage sacrificedSoul = souls[_soulId];
        Soul storage targetSoul = souls[_targetSoulIdForBenefit];

        require(_soulId != _targetSoulIdForBenefit, "Cannot sacrifice a soul onto itself");
        require(sacrificedSoul.attunedPartnerId == 0, "Cannot sacrifice an attuned soul. Break attunement first.");

        // Apply benefit to target soul based on sacrificed soul's state/traits
        // Example: Boost target soul traits, maybe reduce its corruption/increase purity
        uint256 purityBoost = sacrificedSoul.traits.purity / 5;
        uint256 corruptionReduction = sacrificedSoul.traits.corruption / 5;
        uint256 generalBoost = (sacrificedSoul.traits.strength + sacrificedSoul.traits.intellect + sacrificedSoul.traits.affinity) / 30; // Average / 30

        targetSoul.traits.purity = (targetSoul.traits.purity + purityBoost) % 101;
        targetSoul.traits.corruption = targetSoul.traits.corruption > corruptionReduction ? targetSoul.traits.corruption - corruptionReduction : 0;
        targetSoul.traits.strength = (targetSoul.traits.strength + generalBoost) % 101;
        targetSoul.traits.intellect = (targetSoul.traits.intellect + generalBoost) % 101;
        targetSoul.traits.affinity = (targetSoul.traits.affinity + generalBoost) % 101;

        // Sacrifice process
        sacrificedSoul.state = SoulState.Sacrificed;
        soulExists[_soulId] = false; // Mark as non-existent for existence checks

        // Remove soulId from owner's array (gas-intensive operation)
        uint256[] storage owned = ownerSouls[msg.sender];
        for (uint i = 0; i < owned.length; i++) {
            if (owned[i] == _soulId) {
                owned[i] = owned[owned.length - 1]; // Swap with last element
                owned.pop(); // Remove last element
                break;
            }
        }

        emit SoulSacrificed(_soulId, msg.sender, _targetSoulIdForBenefit);
    }


    /**
     * @notice Calculates and returns the current environment factor.
     * @dev This is a simple calculation based on block number and base factor.
     *      Can be made more complex (e.g., time-based cycles, interaction volume).
     * @return The calculated environment factor.
     */
    function getCurrentEnvironmentFactor() public view returns (uint256) {
        // Simple example: Factor oscillates based on block number
        // A more sophisticated approach might use oracles for external data,
        // or track aggregate contract activity.
        uint256 volatility = 50; // Example: oscillates up to 50 from base
        uint256 variation = (block.number % volatility) - (volatility / 2); // Gives a value between -volatility/2 and +volatility/2

        // Ensure factor is never zero
        uint256 currentFactor = environmentBaseFactor + variation;
        return currentFactor > 0 ? currentFactor : 1;
    }


    /**
     * @notice Returns the current cost to forge a new Soul.
     * @return The forging cost in Ether.
     */
    function getForgingCost() public view returns (uint256) {
        return forgingCost;
    }

    /**
     * @notice Returns the base value for a specific trait.
     * @param _traitName The name of the trait (e.g., "strength").
     * @return The base value.
     */
    function getTraitBaseValue(string memory _traitName) public view returns (uint256) {
        return traitBaseValues[_traitName];
    }

    /**
     * @notice Returns a specific evolution requirement threshold value.
     * @param _currentState The current state the Soul is transitioning from.
     * @param _requirementType The type of requirement (e.g., "minAge", "minTraitSum").
     * @return The threshold value.
     */
    function getEvolutionThreshold(SoulState _currentState, string memory _requirementType) public view returns (uint256) {
        return evolutionThresholds[_currentState][_requirementType];
    }

    /**
     * @notice Performs a complex ritual on a Soul.
     * @dev This function can have more significant and potentially conditional effects.
     *      Example: Can force a state change if conditions are met, or drastically alter purity/corruption.
     * @param _soulId The ID of the Soul for the ritual.
     */
    function performComplexRitual(uint256 _soulId)
         public
         onlySoulOwner(_soulId)
         soulNotInState(_soulId, SoulState.Sacrificed)
     {
         Soul storage soul = souls[_soulId];
         uint256 currentTimestamp = uint256(block.timestamp);

         // Example complex condition: Requires high intellect and affinity,
         // and hasn't had a ritual recently (e.g., within 7 days).
         require(soul.traits.intellect >= 70, "Intellect too low for ritual");
         require(soul.traits.affinity >= 70, "Affinity too low for ritual");
         require(currentTimestamp > soul.lastInteractionTimestamp + 7 days, "Ritual cooldown active (7 days)"); // Use lastInteraction for cooldown

         // Example Effect: Significant boost to purity, potential to unlock Awakened state if Mature
         uint256 purityBoost = soul.traits.intellect / 5 + soul.traits.affinity / 5;
         soul.traits.purity = (soul.traits.purity + purityBoost) % 101;

         if (soul.state == SoulState.Mature && soul.traits.purity >= evolutionThresholds[SoulState.Mature]["minPurityForAwaken"]) {
              // Directly evolve to Awakened if conditions are met after ritual
              SoulState oldState = soul.state;
              soul.state = SoulState.Awakened;
              soul.traits.isAwakened = true;
              emit SoulEvolved(_soulId, oldState, SoulState.Awakened);
         }

         soul.lastInteractionTimestamp = uint64(currentTimestamp); // Update interaction time
         emit SoulInteracted(_soulId, InteractionType.Explore, uint64(currentTimestamp)); // Log as a special Explore interaction, or add RitualType enum
         // Add a specific RitualPerformed event if needed
     }


    /**
     * @notice Calculates the age of a Soul in seconds.
     * @param _soulId The ID of the Soul.
     * @return The age of the Soul in seconds.
     */
    function calculateSoulAge(uint256 _soulId) public view soulMustExist(_soulId) returns (uint256) {
        return block.timestamp - souls[_soulId].creationTimestamp;
    }


    /**
     * @notice Calculates the effective current value of a trait, considering base, state modifiers, and environment.
     * @dev This is a simplified example; trait values could have complex dependencies.
     * @param _soulId The ID of the Soul.
     * @param _traitName The name of the trait (e.g., "strength").
     * @return The calculated effective trait value.
     */
    function calculateCurrentTraitValue(uint256 _soulId, string memory _traitName) public view soulMustExist(_soulId) returns (uint256) {
        Soul storage soul = souls[_soulId];
        uint256 base = 0; // Default or look up from traitBaseValues
        uint256 rawTraitValue = 0;

        // Get raw trait value
        if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("strength"))) {
             rawTraitValue = soul.traits.strength;
             base = traitBaseValues["strength"];
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("intellect"))) {
             rawTraitValue = soul.traits.intellect;
             base = traitBaseValues["intellect"];
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("affinity"))) {
             rawTraitValue = soul.traits.affinity;
             base = traitBaseValues["affinity"];
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("purity"))) {
             rawTraitValue = soul.traits.purity;
             base = traitBaseValues["purity"];
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("corruption"))) {
             rawTraitValue = soul.traits.corruption;
             base = traitBaseValues["corruption"];
        } else {
            revert("Invalid trait name"); // Handle unknown traits
        }

        uint256 envFactor = getCurrentEnvironmentFactor();
        uint256 stateModifier = 0; // Example: Mature souls get a bonus to all positive traits

        if (soul.state == SoulState.Mature || soul.state == SoulState.Awakened) {
            if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("strength")) ||
                keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("intellect")) ||
                keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("affinity")) ||
                keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("purity"))) {
                stateModifier = 10; // Example bonus
            }
        }

        // Combine factors - simplified
        // Formula: rawTraitValue + stateModifier + (envFactor / 20) - (base / 10) // Example formula
        int256 effectiveValue = int256(rawTraitValue) + int256(stateModifier) + int256(envFactor / 20) - int256(base / 10);

        // Ensure value stays within reasonable bounds (e.g., 0-150 for effective)
        if (effectiveValue < 0) return 0;
        if (effectiveValue > 150) return 150; // Effective value can exceed raw 100

        return uint256(effectiveValue);
    }

    // --- Admin Functions ---

    /**
     * @notice Owner function to set the cost to forge a new Soul.
     * @param _newCost The new cost in Wei.
     */
    function setForgingCost(uint256 _newCost) public onlyOwner {
        forgingCost = _newCost;
        emit AdminParameterUpdated("forgingCost", _newCost);
    }

    /**
     * @notice Owner function to set the base value for a specific trait.
     * @param _traitName The name of the trait.
     * @param _newValue The new base value.
     */
    function setTraitBaseValue(string memory _traitName, uint256 _newValue) public onlyOwner {
         // Basic validation for known traits (avoid setting random strings)
        require(keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("strength")) ||
                keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("intellect")) ||
                keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("affinity")) ||
                keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("purity")) ||
                keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("corruption")), "Invalid trait name");

        traitBaseValues[_traitName] = _newValue;
         // Cannot emit string directly in value, use a combined identifier or separate events
         // emit AdminParameterUpdated(string(abi.encodePacked("traitBase_", _traitName)), _newValue); // Requires recent solidity version for string in key
         // Alternative: Emit a generic event with name and value, caller parses name string
        emit AdminParameterUpdated("TraitBaseValueUpdated", _newValue); // Simplified event
    }

    /**
     * @notice Owner function to set an evolution requirement threshold.
     * @param _currentState The current state of the Soul.
     * @param _requirementType The type of requirement (e.g., "minAge").
     * @param _newValue The new threshold value.
     */
    function setEvolutionThreshold(SoulState _currentState, string memory _requirementType, uint256 _newValue) public onlyOwner {
        // Basic validation for known requirement types
         require(keccak256(abi.encodePacked(_requirementType)) == keccak256(abi.encodePacked("minAge")) ||
                 keccak256(abi.encodePacked(_requirementType)) == keccak256(abi.encodePacked("minInteractions")) || // If implementing interaction count
                 keccak256(abi.encodePacked(_requirementType)) == keccak256(abi.encodePacked("minTraitSum")) ||
                 keccak256(abi.encodePacked(_requirementType)) == keccak256(abi.encodePacked("minPurity")) ||
                 keccak256(abi.encodePacked(_requirementType)) == keccak256(abi.encodePacked("maxCorruptionForAwaken")) ||
                 keccak256(abi.encodePacked(_requirementType)) == keccak256(abi.encodePacked("minPurityForAwaken")) ||
                 keccak256(abi.encodePacked(_requirementType)) == keccak256(abi.encodePacked("maxTraitSumForDormant")), "Invalid requirement type");


        evolutionThresholds[_currentState][_requirementType] = _newValue;
         // Simplified event
        emit AdminParameterUpdated("EvolutionThresholdUpdated", _newValue);
    }

    /**
     * @notice Owner function to set the base value for the environment factor calculation.
     * @param _newBaseFactor The new base factor value.
     */
    function setEnvironmentBaseFactor(uint256 _newBaseFactor) public onlyOwner {
        environmentBaseFactor = _newBaseFactor;
        emit AdminParameterUpdated("environmentBaseFactor", _newBaseFactor);
    }

    /**
     * @notice Allows the owner to withdraw the contract's accumulated Ether balance.
     */
    function withdrawFees() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // Fallback function to receive Ether if not sent via forgeSoul (optional, could just revert)
    // receive() external payable {}
}
```