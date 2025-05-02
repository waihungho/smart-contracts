Okay, let's design a smart contract around a dynamic, evolving entity concept, influenced by simulated AI parameters and environmental factors. We'll call it "AIRealmEvo". This concept allows for interesting mechanics like on-chain evolution based on state, probabilistic outcomes, interactions between entities, and potentially admin-triggered global events.

We will leverage standard patterns like ERC721 for ownership, Ownable for admin control, Pausable for safety, and use OpenZeppelin libraries for robustness. The "advanced" part comes from the complex state transitions, simulated AI parameters, dynamic traits, and interaction mechanics.

---

**Outline and Function Summary: AIRealmEvo Smart Contract**

This contract implements a dynamic, evolving Non-Fungible Token (NFT) ecosystem. Each token represents a unique creature or entity within the AI Realm. Creatures possess dynamic traits, energy, stage, and simulated AI parameters. They can evolve, interact (combat, gathering), rest, mutate, and merge, affecting their on-chain state.

**Core Concepts:**

1.  **Dynamic NFTs:** Creature traits, energy, stage, and AI parameters are stored directly on-chain and can change.
2.  **Simulated AI:** Entities have numerical parameters influencing their actions and outcomes (e.g., Aggression, Adaptability).
3.  **Evolution:** Creatures can attempt to evolve to a higher stage based on energy, traits, AI parameters, and probabilistic checks.
4.  **Interactions:** Creatures can engage in simulated combat or resource gathering, affecting their state and potentially triggering evolution conditions.
5.  **Energy System:** Actions consume energy, which can be regained over time or by resting/recharging.
6.  **Mutations & Abilities:** Users can initiate processes that might probabilistically grant mutations (trait influences) or discover new abilities.
7.  **Merging:** Two creatures can be merged to create a new one, combining aspects of the parents.
8.  **Global Events:** An admin can trigger events affecting all creatures or introducing temporary rules.

**Function Summary (Public/External):**

*   **ERC721 Standard Functions (8):**
    *   `balanceOf(address owner)`: Get number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a specific token.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer token ownership.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks receiver support).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
    *   `approve(address to, uint256 tokenId)`: Approve an address to spend a token.
    *   `setApprovalForAll(address operator, bool approved)`: Approve/disapprove an operator for all tokens.
    *   `getApproved(uint256 tokenId)`: Get approved address for a token.
    *   `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all tokens of an owner.
*   **Core Creature Management (7):**
    *   `mintInitialCreature()`: Mints a new creature for the caller (initial supply limit).
    *   `getCreatureTraits(uint256 tokenId)`: View creature's core trait values.
    *   `getCreatureAIParameters(uint256 tokenId)`: View creature's simulated AI parameters.
    *   `getCreatureState(uint256 tokenId)`: View creature's stage, energy, status, and last action time.
    *   `getCreatureName(uint256 tokenId)`: View creature's name.
    *   `renameCreature(uint256 tokenId, string memory newName)`: Change creature's name (costs energy).
    *   `tokensOfOwner(address owner)`: Get list of token IDs owned by an address.
*   **Interaction & Evolution (6):**
    *   `triggerEvolutionAttempt(uint256 tokenId)`: Attempt to evolve the creature (costs energy, probabilistic).
    *   `simulateCombatEncounter(uint256 tokenId1, uint256 tokenId2)`: Simulate combat (costs energy for both, affects energy, traits).
    *   `simulateResourceGathering(uint256 tokenId)`: Simulate gathering (costs energy, potentially gains energy/resources).
    *   `runAISimulationCycle(uint256 tokenId)`: Run a simulation cycle for creature's AI (costs energy, affects AI params).
    *   `influenceTraitDevelopment(uint256 tokenId, uint8 traitIndex)`: Spend energy/resources to focus trait development.
    *   `queryEvolutionPotential(uint256 tokenId)`: View function showing probabilistic chances for evolution based on current state.
*   **Energy & Status Management (2):**
    *   `rechargeEnergy(uint256 tokenId)`: Pay a fee to instantly recharge creature energy.
    *   `restCreature(uint256 tokenId)`: Set creature to resting status for faster natural energy recovery (cannot perform actions while resting).
*   **Advanced Mechanics (3):**
    *   `initiateMutationProcess(uint256 tokenId)`: Start a probabilistic process for a future mutation (costs resources, might affect future evolution/trait gain).
    *   `discoverNewAbility(uint256 tokenId)`: Attempt to discover a new ability (costs energy, probabilistic based on state).
    *   `mergeCreatures(uint256 tokenId1, uint256 tokenId2)`: Merge two creatures into a new one (burns parents, mints new, complex trait/stage logic).
*   **Admin Functions (6):**
    *   `setBaseURI(string memory baseURI_)`: Set the base URI for metadata.
    *   `setConfigParameter(uint8 paramType, uint256 value)`: Set various configurable parameters (e.g., evolution cost, energy decay rate multiplier).
    *   `triggerGlobalEvent(uint8 eventType, uint256 eventValue, uint40 duration)`: Trigger a temporary global event affecting gameplay.
    *   `pause()`: Pause contract actions (except admin functions).
    *   `unpause()`: Unpause the contract.
    *   `withdrawFunds()`: Withdraw accumulated contract funds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Needed for tokensOfOwner
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary provided above the contract code.

contract AIRealmEvo is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Creature Data Structure
    struct Creature {
        uint8 stage; // Evolution stage (e.g., 1 to 5)
        uint256 energy; // Current energy points
        uint40 lastActionTime; // Timestamp of the last significant action (packed)
        uint8 status; // 0: Active, 1: Resting, 2: Recovering (after combat/merge)
        string name; // Creature's name
        uint256[5] traits; // e.g., [Attack, Defense, Speed, Intellect, Adaptability] (values 0-1000)
        uint256[3] aiParameters; // e.g., [Aggression, Curiosity, Efficiency] (values 0-1000)
        int256[5] mutationInfluence; // Modifier for future trait growth (can be negative)
        uint256 abilityFlags; // Bitmask for discovered abilities (e.g., bit 0 for ability 1, bit 1 for ability 2)
    }

    // Mappings to store creature data by token ID
    mapping(uint256 => Creature) private _creatures;

    // Configuration Parameters (Admin controllable)
    mapping(uint8 => uint256) private _configParams;
    uint8 constant CONFIG_EVOLUTION_BASE_COST = 0;
    uint8 constant CONFIG_COMBAT_BASE_COST = 1;
    uint8 constant CONFIG_GATHERING_BASE_COST = 2;
    uint8 constant CONFIG_AI_CYCLE_BASE_COST = 3;
    uint8 constant CONFIG_TRAIT_DEV_BASE_COST = 4;
    uint8 constant CONFIG_RECHARGE_FEE = 5;
    uint8 constant CONFIG_MUTATION_INIT_COST = 6;
    uint8 constant CONFIG_ABILITY_DISCOVERY_COST = 7;
    uint8 constant CONFIG_MERGE_BASE_COST = 8;
    uint8 constant CONFIG_ENERGY_DECAY_RATE_MULTIPLIER = 9; // Higher = faster decay
    uint8 constant CONFIG_REST_ENERGY_BOOST = 10; // % boost while resting
    uint8 constant CONFIG_RENAME_COST = 11;

    uint256 constant MAX_ENERGY = 1000;
    uint256 constant INITIAL_ENERGY = 500;
    uint256 constant MAX_TRAIT_VALUE = 1000;
    uint256 constant MAX_AI_PARAM_VALUE = 1000;
    uint8 constant MAX_STAGE = 5;

    // Global Event System
    struct GlobalEvent {
        uint8 eventType;
        uint256 eventValue; // Parameter for the event
        uint40 endTime; // Timestamp when event ends
    }
    GlobalEvent private _currentGlobalEvent;
    uint8 constant EVENT_NONE = 0;
    uint8 constant EVENT_ENERGY_BOOST = 1; // Energy cost reduced by eventValue %
    uint8 constant EVENT_TRAIT_GROWTH_BOOST = 2; // Trait gain potential increased by eventValue %
    uint8 constant EVENT_EVOLUTION_BOOST = 3; // Evolution chance increased by eventValue %

    // Initial Minting Cap
    uint256 public maxInitialSupply = 1000; // Example cap
    uint256 public initialMintedCount = 0;

    // --- Events ---

    event CreatureMinted(uint256 indexed tokenId, address indexed owner, string name, uint8 initialStage);
    event CreatureRenamed(uint256 indexed tokenId, string newName);
    event CreatureStateUpdated(uint256 indexed tokenId, uint8 stage, uint256 energy, uint8 status);
    event CreatureTraitsUpdated(uint256 indexed tokenId, uint256[5] traits, int256[5] mutationInfluence);
    event CreatureAIParametersUpdated(uint256 indexed tokenId, uint256[3] aiParameters);
    event EvolutionAttempted(uint256 indexed tokenId, bool success, uint8 newStage);
    event CombatSimulated(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 winnerTokenId);
    event ResourceGathered(uint256 indexed tokenId, uint256 energyGained, uint256 resourcesGained); // resourcesGained is symbolic here
    event MutationInitiated(uint256 indexed tokenId, bool success, int256[5] resultingInfluence);
    event AbilityDiscovered(uint256 indexed tokenId, uint256 abilityFlags);
    event CreaturesMerged(uint256 indexed parent1TokenId, uint256 indexed parent2TokenId, uint256 indexed newTokenId);
    event GlobalEventTriggered(uint8 eventType, uint256 eventValue, uint40 duration);
    event ConfigParameterUpdated(uint8 paramType, uint256 value);

    // --- Constructor ---

    constructor(string memory name, string memory symbol, uint256 initialMaxSupply) ERC721(name, symbol) Ownable(msg.sender) {
        maxInitialSupply = initialMaxSupply;

        // Set some default config parameters (can be changed by owner later)
        _configParams[CONFIG_EVOLUTION_BASE_COST] = 100;
        _configParams[CONFIG_COMBAT_BASE_COST] = 50;
        _configParams[CONFIG_GATHERING_BASE_COST] = 30;
        _configParams[CONFIG_AI_CYCLE_BASE_COST] = 20;
        _configParams[CONFIG_TRAIT_DEV_BASE_COST] = 40;
        _configParams[CONFIG_RECHARGE_FEE] = 0.01 ether; // Example fee
        _configParams[CONFIG_MUTATION_INIT_COST] = 50;
        _configParams[CONFIG_ABILITY_DISCOVERY_COST] = 60;
        _configParams[CONFIG_MERGE_BASE_COST] = 200;
        _configParams[CONFIG_ENERGY_DECAY_RATE_MULTIPLIER] = 1; // 1 unit of decay per second (simplified)
        _configParams[CONFIG_REST_ENERGY_BOOST] = 50; // 50% faster recovery
        _configParams[CONFIG_RENAME_COST] = 10;
    }

    // --- Modifiers ---

    modifier onlyCreatureOwner(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyCreatureActive(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(_creatures[tokenId].status == 0, "Creature is not Active");
        _;
    }

    // --- Internal Helpers ---

    /// @dev Internal function to apply time-based energy decay.
    function _applyEnergyDecay(uint256 tokenId) internal {
        Creature storage creature = _creatures[tokenId];
        uint40 currentTime = uint40(block.timestamp);
        if (creature.lastActionTime < currentTime) {
            uint256 timeElapsed = currentTime - creature.lastActionTime;
            uint256 decayRate = _configParams[CONFIG_ENERGY_DECAY_RATE_MULTIPLIER];
            uint256 decayAmount = timeElapsed * decayRate; // Simplified decay model

            if (creature.status == 1) { // Resting status
                 decayAmount = (decayAmount * 100) / (100 + _configParams[CONFIG_REST_ENERGY_BOOST]); // Resting reduces decay rate effectively
            }

            if (decayAmount > 0) {
                 if (creature.energy > decayAmount) {
                    creature.energy -= decayAmount;
                } else {
                    creature.energy = 0;
                }
                 // Energy decay is passive, doesn't count as a new action for lastActionTime
            }
        }
         creature.lastActionTime = currentTime; // Update time for next decay check
    }

    /// @dev Internal function to check energy and apply decay before an action.
    function _checkAndPrepareForAction(uint256 tokenId, uint256 energyCost) internal onlyCreatureActive(tokenId) {
        _applyEnergyDecay(tokenId); // Apply decay first
        require(_creatures[tokenId].energy >= energyCost, "Not enough energy");
        _creatures[tokenId].energy -= energyCost;
        _creatures[tokenId].lastActionTime = uint40(block.timestamp); // Update last action time
        emit CreatureStateUpdated(tokenId, _creatures[tokenId].stage, _creatures[tokenId].energy, _creatures[tokenId].status);
    }


    /// @dev Internal probabilistic outcome based on state and randomness source.
    /// @param baseChance Base probability (0-10000, representing 0-100%)
    /// @param modifiers Trait/AI param modifiers (e.g., high Intellect boosts discovery chance)
    /// @return bool success
    function _getProbabilisticOutcome(uint256 baseChance, uint256[] memory modifiers) internal view returns (bool) {
        // Basic randomness source - not truly secure, but sufficient for example game logic
        // For production, use Chainlink VRF or similar
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, block.difficulty)));

        uint256 modifiedChance = baseChance;
        // Apply modifiers (simple additive example)
        for(uint i = 0; i < modifiers.length; i++) {
            modifiedChance += modifiers[i];
        }

        // Add global event influence if applicable
        if (_currentGlobalEvent.endTime > block.timestamp) {
             if (_currentGlobalEvent.eventType == EVENT_EVOLUTION_BOOST && baseChance == _configParams[CONFIG_EVOLUTION_BASE_COST]) {
                 modifiedChance = (modifiedChance * (100 + _currentGlobalEvent.eventValue)) / 100;
             }
             // Could add other event types affecting different chances
        }


        // Cap chance at 100% (10000)
        if (modifiedChance > 10000) {
            modifiedChance = 10000;
        }

        return (entropy % 10001) < modifiedChance; // Compare entropy outcome to chance
    }

    /// @dev Internal function to generate initial random traits and AI parameters.
    function _generateInitialStats() internal view returns (uint256[5] memory traits, uint256[3] memory aiParams) {
        // Basic randomness for initial stats - again, not secure, for example only
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, initialMintedCount)));

        for (uint i = 0; i < 5; i++) {
            traits[i] = (entropy % 201) + 50; // Initial traits between 50 and 250
            entropy = uint256(keccak256(abi.encodePacked(entropy, i))); // Simple way to get new entropy
        }
        for (uint i = 0; i < 3; i++) {
             aiParams[i] = (entropy % 201) + 50; // Initial AI params between 50 and 250
             entropy = uint256(keccak256(abi.encodePacked(entropy, i + 5)));
        }
    }

    // --- ERC721 Overrides ---

    function _baseURI() internal view override returns (string memory) {
        // This should point to an API endpoint that returns JSON metadata
        // based on the on-chain state (traits, stage, name, etc.)
        // Example: "https://your-api.com/metadata/"
        // The API would need to read creature data using view functions like getCreatureTraits, etc.
        return "ipfs://YOUR_METADATA_BASE_URI/"; // Replace with your actual base URI
    }

     function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        // If using a dynamic API, the structure might be baseURI/tokenId
        // If using IPFS, you might store the *initial* hash and update it via an event
        // Here, we assume the base URI + tokenId forms the lookup for the API
        return string(abi.encodePacked(base, tokenId.toString()));
     }


    // --- Public / External Functions (>= 20 total required) ---

    // ERC721 Standard Functions are inherited and count towards the total (8 functions)
    // balanceOf, ownerOf, transferFrom, safeTransferFrom (x2), approve, setApprovalForAll, getApproved, isApprovedForAll

    /// @notice Mints a new initial creature for the caller.
    /// @dev Limited by the maxInitialSupply.
    function mintInitialCreature() external nonReentrant whenNotPaused {
        require(initialMintedCount < maxInitialSupply, "Initial supply cap reached");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        uint256[5] memory initialTraits;
        uint256[3] memory initialAIParams;
        (initialTraits, initialAIParams) = _generateInitialStats();

        _creatures[newItemId] = Creature({
            stage: 1,
            energy: INITIAL_ENERGY,
            lastActionTime: uint40(block.timestamp),
            status: 0, // Active
            name: string(abi.encodePacked("Creature #", newItemId.toString())), // Default name
            traits: initialTraits,
            aiParameters: initialAIParams,
            mutationInfluence: [int256(0), int256(0), int256(0), int256(0), int256(0)],
            abilityFlags: 0
        });

        _safeMint(msg.sender, newItemId);
        initialMintedCount++;

        emit CreatureMinted(newItemId, msg.sender, _creatures[newItemId].name, _creatures[newItemId].stage);
        emit CreatureTraitsUpdated(newItemId, initialTraits, _creatures[newItemId].mutationInfluence);
        emit CreatureAIParametersUpdated(newItemId, initialAIParams);
    }

    /// @notice Gets the core trait values of a creature.
    /// @param tokenId The ID of the creature token.
    /// @return traits Array of trait values.
    function getCreatureTraits(uint256 tokenId) external view returns (uint256[5] memory traits) {
        require(_exists(tokenId), "Token does not exist");
        return _creatures[tokenId].traits;
    }

     /// @notice Gets the simulated AI parameters of a creature.
    /// @param tokenId The ID of the creature token.
    /// @return aiParams Array of AI parameter values.
    function getCreatureAIParameters(uint256 tokenId) external view returns (uint256[3] memory aiParams) {
        require(_exists(tokenId), "Token does not exist");
        return _creatures[tokenId].aiParameters;
    }

    /// @notice Gets the current state (stage, energy, status, last action time) of a creature.
    /// @param tokenId The ID of the creature token.
    /// @return stage The evolution stage.
    /// @return energy The current energy points.
    /// @return status The creature's status (0: Active, 1: Resting, 2: Recovering).
    /// @return lastActionTime The timestamp of the last significant action.
    function getCreatureState(uint256 tokenId) external view returns (uint8 stage, uint256 energy, uint8 status, uint40 lastActionTime) {
        require(_exists(tokenId), "Token does not exist");
        Creature storage creature = _creatures[tokenId];
        // Note: The energy returned here might not reflect decay since last interaction unless _applyEnergyDecay is called first.
        // A read-only function cannot modify state, so decay isn't applied here.
        // Consider adding a helper view function if a "real-time" energy estimate including potential decay is needed off-chain.
        return (creature.stage, creature.energy, creature.status, creature.lastActionTime);
    }

     /// @notice Gets the name of a creature.
    /// @param tokenId The ID of the creature token.
    /// @return name The creature's name.
    function getCreatureName(uint256 tokenId) external view returns (string memory name) {
        require(_exists(tokenId), "Token does not exist");
        return _creatures[tokenId].name;
    }

     /// @notice Changes the name of a creature.
    /// @param tokenId The ID of the creature token.
    /// @param newName The desired new name.
    function renameCreature(uint256 tokenId, string memory newName) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
         require(bytes(newName).length > 0, "Name cannot be empty");
         require(bytes(newName).length <= 32, "Name too long"); // Example length limit

        _checkAndPrepareForAction(tokenId, _configParams[CONFIG_RENAME_COST]);
        _creatures[tokenId].name = newName;
        emit CreatureRenamed(tokenId, newName);
    }

    /// @notice Lists all token IDs owned by an address.
    /// @dev This function uses the ERC721Enumerable extension.
    /// @param owner The address to query.
    /// @return tokenIds An array of token IDs.
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return ERC721Enumerable.tokenOfOwnerAll(owner);
    }

    /// @notice Attempts to evolve a creature to the next stage.
    /// @dev Requires energy and is probabilistic based on current state.
    /// @param tokenId The ID of the creature token.
    function triggerEvolutionAttempt(uint256 tokenId) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
        Creature storage creature = _creatures[tokenId];
        require(creature.stage < MAX_STAGE, "Creature is already at max stage");

        uint256 evolutionCost = _configParams[CONFIG_EVOLUTION_BASE_COST];
        _checkAndPrepareForAction(tokenId, evolutionCost);

        // Calculate chance based on traits and AI parameters
        uint256 baseChance = 1000 + (creature.stage * 500); // Example: Chance increases slightly per stage
        uint256[] memory modifiers = new uint256[](2);
        modifiers[0] = creature.traits[4]; // Adaptability trait influences evolution chance
        modifiers[1] = creature.aiParameters[2]; // Efficiency AI param influences evolution chance (simulated)

        bool success = _getProbabilisticOutcome(baseChance, modifiers);

        uint8 oldStage = creature.stage;
        if (success) {
            creature.stage += 1;
             // Apply mutation influence to traits upon successful evolution
            for(uint i = 0; i < 5; i++) {
                 int256 influence = creature.mutationInfluence[i];
                 if (influence != 0) {
                      // Apply influence, ensuring trait stays within bounds
                      if (influence > 0) {
                         creature.traits[i] = (creature.traits[i] + uint256(influence) > MAX_TRAIT_VALUE) ? MAX_TRAIT_VALUE : creature.traits[i] + uint256(influence);
                      } else {
                         uint256 absInfluence = uint256(-influence);
                         creature.traits[i] = (creature.traits[i] < absInfluence) ? 0 : creature.traits[i] - absInfluence;
                      }
                      creature.mutationInfluence[i] = 0; // Consume influence after applying
                 }
            }
             emit CreatureTraitsUpdated(tokenId, creature.traits, creature.mutationInfluence);

        } else {
            // Maybe a penalty or partial gain on failure? For simplicity, just consume energy.
        }

        emit EvolutionAttempted(tokenId, success, creature.stage);
        emit CreatureStateUpdated(tokenId, creature.stage, creature.energy, creature.status);
    }

    /// @notice Simulates a combat encounter between two creatures.
    /// @dev Requires energy for both creatures, affects energy and traits probabilistically.
    /// @param tokenId1 The ID of the first creature.
    /// @param tokenId2 The ID of the second creature.
    function simulateCombatEncounter(uint256 tokenId1, uint256 tokenId2) external nonReentrant whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot simulate combat with self");
        require(_exists(tokenId1), "Token 1 does not exist");
        require(_exists(tokenId2), "Token 2 does not exist");
        require(ownerOf(tokenId1) == msg.sender || ownerOf(tokenId2) == msg.sender, "Caller must own at least one creature");

        Creature storage creature1 = _creatures[tokenId1];
        Creature storage creature2 = _creures[tokenId2];

        require(creature1.status == 0 && creature2.status == 0, "Both creatures must be Active");

        uint256 combatCost = _configParams[CONFIG_COMBAT_BASE_COST];
        require(creature1.energy >= combatCost && creature2.energy >= combatCost, "Not enough energy for combat");

        // Apply energy decay before action costs
        _applyEnergyDecay(tokenId1);
        _applyEnergyDecay(tokenId2);

        creature1.energy -= combatCost;
        creature2.energy -= combatCost;
        creature1.lastActionTime = uint40(block.timestamp);
        creature2.lastActionTime = uint40(block.timestamp);

        // Simplified Combat Logic: Higher Attack + Speed vs. Defense + Speed
        uint256 score1 = creature1.traits[0] + creature1.traits[2] + creature1.aiParameters[0]; // Attack + Speed + Aggression
        uint256 score2 = creature2.traits[0] + creature2.traits[2] + creature2.aiParameters[0];

        uint256 winnerTokenId;
        uint256 loserTokenId;

        // Add some randomness to combat outcome
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId1, tokenId2, block.number)));
        uint256 randomFactor = entropy % 200; // +- 100 influence

        int256 diff = int256(score1) - int256(score2);
        int256 finalScoreDiff = diff + int256(randomFactor) - 100; // Apply random factor symmetrically

        if (finalScoreDiff > 0) {
            winnerTokenId = tokenId1;
            loserTokenId = tokenId2;
        } else if (finalScoreDiff < 0) {
            winnerTokenId = tokenId2;
            loserTokenId = tokenId1;
        } else {
            // Draw: reduce energy, maybe small trait changes for both
            // For simplicity, let's say tokenId1 wins on a perfect tie
            winnerTokenId = tokenId1;
            loserTokenId = tokenId2;
        }

        Creature storage winner = _creatures[winnerTokenId];
        Creature storage loser = _creatures[loserTokenId];

        // Apply combat outcomes
        // Winner gains small amount of energy/trait experience, loser loses energy/trait experience
        uint256 energyGain = combatCost / 2; // Example: winner recovers half cost
        if (winner.energy + energyGain > MAX_ENERGY) {
            winner.energy = MAX_ENERGY;
        } else {
            winner.energy += energyGain;
        }

        uint256 energyLoss = combatCost; // Loser loses full cost + penalty
        if (loser.energy >= energyLoss) {
            loser.energy -= energyLoss;
        } else {
            loser.energy = 0;
        }

        // Simplified trait impact: Winner might gain some Attack/Speed, loser might lose some
        uint256 traitChange = 5 + (entropy % 10); // Small random change
        uint8 winnerAttack = 0; uint8 winnerSpeed = 2;
        uint8 loserDefense = 1; uint8 loserSpeed = 2;

        winner.traits[winnerAttack] = (winner.traits[winnerAttack] + traitChange > MAX_TRAIT_VALUE) ? MAX_TRAIT_VALUE : winner.traits[winnerAttack] + traitChange;
        winner.traits[winnerSpeed] = (winner.traits[winnerSpeed] + traitChange > MAX_TRAIT_VALUE) ? MAX_TRAIT_VALUE : winner.traits[winnerSpeed] + traitChange;

        if (loser.traits[loserDefense] >= traitChange) loser.traits[loserDefense] -= traitChange; else loser.traits[loserDefense] = 0;
        if (loser.traits[loserSpeed] >= traitChange) loser.traits[loserSpeed] -= traitChange; else loser.traits[loserSpeed] = 0;

        loser.status = 2; // Set loser to Recovering status
        winner.status = 0; // Ensure winner is Active

        // Emit events for state changes
        emit CombatSimulated(tokenId1, tokenId2, winnerTokenId);
        emit CreatureStateUpdated(tokenId1, creature1.stage, creature1.energy, creature1.status);
        emit CreatureStateUpdated(tokenId2, creature2.stage, creature2.energy, creature2.status);
        emit CreatureTraitsUpdated(tokenId1, creature1.traits, creature1.mutationInfluence);
        emit CreatureTraitsUpdated(tokenId2, creature2.traits, creature2.mutationInfluence);
    }

    /// @notice Simulates resource gathering for a creature.
    /// @dev Costs energy, potentially gains energy/resources (symbolic).
    /// @param tokenId The ID of the creature token.
    function simulateResourceGathering(uint256 tokenId) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
         Creature storage creature = _creatures[tokenId];
         uint256 gatheringCost = _configParams[CONFIG_GATHERING_BASE_COST];
         _checkAndPrepareForAction(tokenId, gatheringCost);

         // Simplified Gathering Logic: Intellect + Adaptability influences yield
         uint256 yieldPotential = creature.traits[3] + creature.traits[4]; // Intellect + Adaptability

         uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, block.number)));
         uint256 randomFactor = entropy % 50; // +- 25 influence

         uint256 energyGained = (gatheringCost / 3) + (yieldPotential / 50) + randomFactor - 25; // Example calculation
         uint256 resourcesGained = yieldPotential / 20 + (entropy % 30); // Symbolic resource gain

         if (creature.energy + energyGained > MAX_ENERGY) {
             creature.energy = MAX_ENERGY;
         } else {
             creature.energy += energyGained;
         }

         // No trait change for gathering in this simple example

         emit ResourceGathered(tokenId, energyGained, resourcesGained);
         emit CreatureStateUpdated(tokenId, creature.stage, creature.energy, creature.status);
    }

    /// @notice Runs a simulation cycle for a creature's AI parameters.
    /// @dev Costs energy, probabilistic changes to AI parameters based on traits/stage.
    /// @param tokenId The ID of the creature token.
    function runAISimulationCycle(uint256 tokenId) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
        Creature storage creature = _creatures[tokenId];
        uint256 aiCost = _configParams[CONFIG_AI_CYCLE_BASE_COST];
        _checkAndPrepareForAction(tokenId, aiCost);

        // Simplified AI Simulation: Intellect influences AI parameter change potential
        uint256 intellect = creature.traits[3];
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, block.number, block.difficulty)));

        // Probabilistically adjust AI parameters
        for (uint i = 0; i < 3; i++) {
            uint256 chanceToChange = 1000 + (intellect * 10); // Base + Intellect influence
            if (_getProbabilisticOutcome(chanceToChange, new uint256[](0))) { // Check if parameter changes
                int256 changeAmount = int256((entropy % 50) - 25); // Change is between -25 and +25

                // Apply change, ensuring parameter stays within bounds [0, MAX_AI_PARAM_VALUE]
                if (changeAmount > 0) {
                    creature.aiParameters[i] = (creature.aiParameters[i] + uint256(changeAmount) > MAX_AI_PARAM_VALUE) ? MAX_AI_PARAM_VALUE : creature.aiParameters[i] + uint256(changeAmount);
                } else {
                    uint256 absChange = uint256(-changeAmount);
                    creature.aiParameters[i] = (creature.aiParameters[i] < absChange) ? 0 : creature.aiParameters[i] - absChange;
                }
                entropy = uint256(keccak256(abi.encodePacked(entropy, i, block.number))); // Update entropy
            }
        }

        emit CreatureAIParametersUpdated(tokenId, creature.aiParameters);
    }

    /// @notice Allows the owner to spend energy/resources to influence the development of a specific trait.
    /// @dev Costs energy/resources, boosts the chance or amount a trait grows in future actions (like evolution).
    /// @param tokenId The ID of the creature token.
    /// @param traitIndex The index of the trait to influence (0-4).
    function influenceTraitDevelopment(uint256 tokenId, uint8 traitIndex) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
        require(traitIndex < 5, "Invalid trait index");
        Creature storage creature = _creatures[tokenId];
        uint256 devCost = _configParams[CONFIG_TRAIT_DEV_BASE_COST];
        _checkAndPrepareForAction(tokenId, devCost);

        // Simple influence: Add a small positive modifier to the mutationInfluence for this trait
        // This influence will be consumed upon the next successful evolution or other specific events
        int256 influenceBoost = int256(10 + (creature.traits[traitIndex] / 100)); // Base + influenced by current trait value
        creature.mutationInfluence[traitIndex] += influenceBoost;

        emit CreatureTraitsUpdated(tokenId, creature.traits, creature.mutationInfluence);
    }

     /// @notice Queries the potential for evolution based on current state.
    /// @dev This is a view function and does not apply decay or consume energy.
    /// @param tokenId The ID of the creature token.
    /// @return evolutionChance Estiamted chance of successful evolution (0-10000).
    function queryEvolutionPotential(uint256 tokenId) external view returns (uint256 evolutionChance) {
         require(_exists(tokenId), "Token does not exist");
         Creature storage creature = _creatures[tokenId];
         require(creature.stage < MAX_STAGE, "Creature is already at max stage");
         // Need enough energy for the action, but we don't check it here as it's read-only.
         // Off-chain UI should check energy >= _configParams[CONFIG_EVOLUTION_BASE_COST]

         uint256 baseChance = 1000 + (creature.stage * 500); // Example: Chance increases slightly per stage
         uint256[] memory modifiers = new uint256[](2);
         modifiers[0] = creature.traits[4]; // Adaptability trait influences evolution chance
         modifiers[1] = creature.aiParameters[2]; // Efficiency AI param influences evolution chance (simulated)

         uint256 modifiedChance = baseChance;
         for(uint i = 0; i < modifiers.length; i++) {
            modifiedChance += modifiers[i];
         }

          // Add global event influence if applicable (read-only check)
        if (_currentGlobalEvent.endTime > block.timestamp) {
             if (_currentGlobalEvent.eventType == EVENT_EVOLUTION_BOOST && baseChance == _configParams[CONFIG_EVOLUTION_BASE_COST]) {
                 modifiedChance = (modifiedChance * (100 + _currentGlobalEvent.eventValue)) / 100;
             }
        }

        return (modifiedChance > 10000) ? 10000 : modifiedChance; // Cap at 100%
    }


    /// @notice Pays a fee to instantly recharge creature energy.
    /// @param tokenId The ID of the creature token.
    function rechargeEnergy(uint256 tokenId) external payable nonReentrant whenNotPaused onlyCreatureOwner(tokenId) {
        Creature storage creature = _creatures[tokenId];
        require(msg.value >= _configParams[CONFIG_RECHARGE_FEE], "Insufficient payment");

        // Apply decay before recharging to ensure accurate state update
        _applyEnergyDecay(tokenId);

        creature.energy = MAX_ENERGY; // Recharge to full
        creature.lastActionTime = uint40(block.timestamp); // New action time
        creature.status = 0; // Ensure status is Active after recharge

        emit CreatureStateUpdated(tokenId, creature.stage, creature.energy, creature.status);
    }

    /// @notice Sets creature to resting status for faster natural energy recovery.
    /// @dev Creature cannot perform actions while resting.
    /// @param tokenId The ID of the creature token.
    function restCreature(uint256 tokenId) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
        Creature storage creature = _creatures[tokenId];
         // Apply decay before changing status
        _applyEnergyDecay(tokenId);

        creature.status = 1; // Set status to Resting
         creature.lastActionTime = uint40(block.timestamp); // New action time starts faster recovery clock

        emit CreatureStateUpdated(tokenId, creature.stage, creature.energy, creature.status);
    }

    /// @notice Initiates a probabilistic process for a future mutation.
    /// @dev Costs resources, might add positive or negative influence to mutationInfluence array.
    /// @param tokenId The ID of the creature token.
    function initiateMutationProcess(uint256 tokenId) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
        Creature storage creature = _creatures[tokenId];
        uint256 mutationCost = _configParams[CONFIG_MUTATION_INIT_COST];
         _checkAndPrepareForAction(tokenId, mutationCost);

        // Simplified Mutation Logic: Adaptability and Intellect influence chance/outcome
        uint256 baseChance = 2000 + (creature.traits[4] * 5) + (creature.traits[3] * 5); // Base + Adaptability + Intellect

        uint256[] memory modifiers = new uint256[](0); // No external modifiers in this example
        bool success = _getProbabilisticOutcome(baseChance, modifiers);

        int256[5] memory resultingInfluence = creature.mutationInfluence; // Start with current influence
        if (success) {
            uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, block.number, success)));
            uint8 randomTraitIndex = uint8(entropy % 5);
            int256 influenceAmount = int256((entropy % 100) - 30); // Influence between -30 and 70

            resultingInfluence[randomTraitIndex] += influenceAmount;
            creature.mutationInfluence[randomTraitIndex] = resultingInfluence[randomTraitIndex];

        } // else: No mutation influence change on failure

        emit MutationInitiated(tokenId, success, creature.mutationInfluence);
        emit CreatureTraitsUpdated(tokenId, creature.traits, creature.mutationInfluence); // Emit traits updated event as influence is part of traits mapping conceptually
    }

    /// @notice Attempts to discover a new ability for the creature.
    /// @dev Costs energy, probabilistic based on stage, traits, and AI parameters.
    /// @param tokenId The ID of the creature token.
    function discoverNewAbility(uint256 tokenId) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) onlyCreatureActive(tokenId) {
        Creature storage creature = _creatures[tokenId];
        uint256 abilityCost = _configParams[CONFIG_ABILITY_DISCOVERY_COST];
        _checkAndPrepareForAction(tokenId, abilityCost);

        // Simplified Ability Discovery Logic: Stage + Intellect + Curiosity influences chance
        uint256 baseChance = 500 + (creature.stage * 300); // Base + Stage influence
        uint256[] memory modifiers = new uint256[](2);
        modifiers[0] = creature.traits[3] * 5; // Intellect influence
        modifiers[1] = creature.aiParameters[1] * 5; // Curiosity AI param influence

        bool success = _getProbabilisticOutcome(baseChance, modifiers);

        if (success) {
            // Discover a new ability - simple implementation: set a random bit in abilityFlags
             uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, block.number, success)));
             uint8 randomAbilityIndex = uint8(entropy % 10); // Example: Up to 10 different abilities (bits 0-9)

             uint256 abilityBit = 1 << randomAbilityIndex;

            // Only set if not already discovered
            if ((creature.abilityFlags & abilityBit) == 0) {
                creature.abilityFlags |= abilityBit;
                 emit AbilityDiscovered(tokenId, creature.abilityFlags);
            } else {
                // If ability already discovered, maybe give a small energy refund or trait boost instead?
                // For simplicity, just consume energy and emit failure implicitly (success=true but no new bit)
                // Or re-roll? Let's re-roll index up to 3 times.
                bool foundNew = false;
                for(uint i = 0; i < 3; i++) {
                    randomAbilityIndex = uint8(uint256(keccak256(abi.encodePacked(entropy, i))) % 10);
                    abilityBit = 1 << randomAbilityIndex;
                     if ((creature.abilityFlags & abilityBit) == 0) {
                        creature.abilityFlags |= abilityBit;
                        foundNew = true;
                        emit AbilityDiscovered(tokenId, creature.abilityFlags);
                        break;
                    }
                }
                if (!foundNew) {
                     // Still no new ability after re-rolls, perhaps a minor energy refund?
                     uint256 refund = abilityCost / 4;
                     if (creature.energy + refund > MAX_ENERGY) creature.energy = MAX_ENERGY; else creature.energy += refund;
                      emit CreatureStateUpdated(tokenId, creature.stage, creature.energy, creature.status);
                }
            }
        } // else: Energy consumed, no ability discovered
    }

     /// @notice Merges two creatures into a new one.
    /// @dev Burns the two parent tokens and mints a new one with combined characteristics.
    /// @param tokenId1 The ID of the first creature to merge.
    /// @param tokenId2 The ID of the second creature to merge.
    function mergeCreatures(uint256 tokenId1, uint256 tokenId2) external nonReentrant whenNotPaused {
        require(tokenId1 != tokenId2, "Cannot merge creature with itself");
        require(_exists(tokenId1), "Token 1 does not exist");
        require(_exists(tokenId2), "Token 2 does not exist");
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "Caller must own both creatures");

         Creature storage creature1 = _creatures[tokenId1];
         Creature storage creature2 = _creatures[tokenId2];

        require(creature1.status == 0 && creature2.status == 0, "Both creatures must be Active");
        require(creature1.stage > 0 && creature2.stage > 0, "Cannot merge uninitialized creatures"); // Should be true after minting

        uint256 mergeCost = _configParams[CONFIG_MERGE_BASE_COST];
        require(creature1.energy >= mergeCost && creature2.energy >= mergeCost, "Not enough energy for merging");

        // Apply energy decay before action costs
        _applyEnergyDecay(tokenId1);
        _applyEnergyDecay(tokenId2);

        creature1.energy -= mergeCost;
        creature2.energy -= mergeCost;
        creature1.lastActionTime = uint40(block.timestamp);
        creature2.lastActionTime = uint40(block.timestamp);

        // --- Merge Logic ---
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        uint256[5] memory mergedTraits;
        uint256[3] memory mergedAIParams;
        int256[5] memory mergedMutationInfluence;
        uint256 mergedAbilityFlags;
        uint8 mergedStage;
        uint256 mergedEnergy;

        // Basic Trait Merging: Average + potential bonus
        uint265 entropy = uint256(keccak265(abi.encodePacked(block.timestamp, tokenId1, tokenId2, block.number)));
        for(uint i = 0; i < 5; i++) {
            uint256 avgTrait = (creature1.traits[i] + creature2.traits[i]) / 2;
            uint256 bonus = (entropy % 50); // Random bonus 0-49
            mergedTraits[i] = (avgTrait + bonus > MAX_TRAIT_VALUE) ? MAX_TRAIT_VALUE : avgTrait + bonus;
            entropy = uint256(keccak256(abi.encodePacked(entropy, i))); // Update entropy
        }

        // Basic AI Param Merging: Average
        for(uint i = 0; i < 3; i++) {
            mergedAIParams[i] = (creature1.aiParameters[i] + creature2.aiParameters[i]) / 2;
        }

        // Mutation Influence: Summing influences (can be positive or negative)
        for(uint i = 0; i < 5; i++) {
            mergedMutationInfluence[i] = creature1.mutationInfluence[i] + creature2.mutationInfluence[i];
            // Optional: Cap influence? For simplicity, let it potentially grow large.
        }

        // Ability Flags: Combine using bitwise OR
        mergedAbilityFlags = creature1.abilityFlags | creature2.abilityFlags;

        // Stage: Higher of the two parents, maybe with a chance to increase?
        mergedStage = (creature1.stage > creature2.stage) ? creature1.stage : creature2.stage;
        uint256 stageBoostChance = 1000 + (mergedStage * 200) + ((creature1.stage + creature2.stage) * 50); // Higher stage parents increase chance
         if (_getProbabilisticOutcome(stageBoostChance, new uint256[](0)) && mergedStage < MAX_STAGE) {
             mergedStage += 1; // Chance to gain an extra stage
         }

        // Energy: Average of remaining energy + a bonus?
        mergedEnergy = ((creature1.energy + creature2.energy) / 2) + (entropy % 100);
         if (mergedEnergy > MAX_ENERGY) mergedEnergy = MAX_ENERGY;


        _creatures[newTokenId] = Creature({
            stage: mergedStage,
            energy: mergedEnergy,
            lastActionTime: uint40(block.timestamp),
            status: 0, // New creature starts Active
            name: string(abi.encodePacked("Merged #", newTokenId.toString())), // Default name
            traits: mergedTraits,
            aiParameters: mergedAIParams,
            mutationInfluence: mergedMutationInfluence,
            abilityFlags: mergedAbilityFlags
        });


        // Burn parent tokens
        _burn(tokenId1);
        _burn(tokenId2);

        // Mint new token to the caller (owner of both parents)
        _safeMint(msg.sender, newTokenId);

        emit CreaturesMerged(tokenId1, tokenId2, newTokenId);
         // Emit events for the new creature
        emit CreatureMinted(newTokenId, msg.sender, _creatures[newTokenId].name, _creatures[newTokenId].stage);
        emit CreatureStateUpdated(newTokenId, _creatures[newTokenId].stage, _creatures[newTokenId].energy, _creatures[newTokenId].status);
        emit CreatureTraitsUpdated(newTokenId, _creatures[newTokenId].traits, _creatures[newTokenId].mutationInfluence);
        emit CreatureAIParametersUpdated(newTokenId, _creatures[newTokenId].aiParameters);
    }


    /// @notice Sets creature status to Active, allowing actions.
    /// @dev Can be called to end Resting/Recovering status. Costs a tiny bit of energy?
    /// @param tokenId The ID of the creature token.
    function activateCreature(uint256 tokenId) external nonReentrant whenNotPaused onlyCreatureOwner(tokenId) {
        Creature storage creature = _creatures[tokenId];
         if (creature.status != 0) {
            // Apply decay accumulated during inactive state
             _applyEnergyDecay(tokenId); // Apply decay before changing status

            creature.status = 0; // Set status to Active
            creature.lastActionTime = uint40(block.timestamp); // Update last action time

            // Maybe a small energy penalty for forcing active? Or just the decay is enough.
            emit CreatureStateUpdated(tokenId, creature.stage, creature.energy, creature.status);
         }
        // If already active, do nothing.
    }


    // --- Admin Functions ---

    /// @notice Admin function to set the base URI for token metadata.
    /// @param baseURI_ The new base URI string.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice Admin function to set various configurable parameters.
    /// @param paramType The type of parameter to set (use CONFIG_ constants).
    /// @param value The new value for the parameter.
    function setConfigParameter(uint8 paramType, uint256 value) external onlyOwner {
        require(paramType <= CONFIG_RENAME_COST, "Invalid config parameter type");
        _configParams[paramType] = value;
        emit ConfigParameterUpdated(paramType, value);
    }

    /// @notice Admin function to trigger a temporary global event.
    /// @param eventType The type of event (use EVENT_ constants).
    /// @param eventValue The parameter value for the event (e.g., percentage boost).
    /// @param duration The duration of the event in seconds.
    function triggerGlobalEvent(uint8 eventType, uint256 eventValue, uint40 duration) external onlyOwner {
        require(eventType >= EVENT_NONE && eventType <= EVENT_EVOLUTION_BOOST, "Invalid event type");
        _currentGlobalEvent = GlobalEvent({
            eventType: eventType,
            eventValue: eventValue,
            endTime: uint40(block.timestamp) + duration
        });
        emit GlobalEventTriggered(eventType, eventValue, duration);
    }

    /// @notice Admin function to pause the contract.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Admin function to unpause the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Admin function to withdraw accumulated contract funds (e.g., from recharge fees).
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    // --- Overrides for ERC721Enumerable ---
    // These are required by ERC721Enumerable to keep track of token IDs
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint252 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

---

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **Dynamic On-Chain State:** Instead of just linking to an IPFS hash, key aspects like `stage`, `energy`, `traits`, `aiParameters`, `status`, and `mutationInfluence` are stored directly in contract state (`_creatures` mapping). This allows these values to change over time through contract interactions. The `tokenURI` function would typically be implemented to point to an off-chain API that reads this *on-chain* data to generate the dynamic metadata JSON.
2.  **Simulated AI Parameters (`aiParameters`):** This adds a layer of complexity beyond simple traits. Parameters like `Aggression`, `Curiosity`, `Efficiency` influence the *behavior* and *outcomes* of actions like combat, gathering, and evolution (`_getProbabilisticOutcome`, `runAISimulationCycle`). The `runAISimulationCycle` function allows users to potentially nudge these parameters.
3.  **Complex State Transitions:**
    *   **Evolution (`triggerEvolutionAttempt`):** Not a simple level-up. It's a probabilistic attempt requiring energy, influenced by specific traits/AI params (`Adaptability`, `Efficiency`), and progresses the `stage`. Success can also be influenced by prior `mutationInfluence`.
    *   **Combat (`simulateCombatEncounter`):** A function simulating interaction between two NFTs. It consumes energy for both, calculates an outcome based on combined traits/AI params and randomness, and modifies the energy, status, and traits of *both* participants. This creates direct interaction between tokens.
    *   **Merging (`mergeCreatures`):** A destructive process where two parent tokens are burned, and a new token is minted. The new token's traits, AI parameters, influence, abilities, and stage are derived from the parents using a defined logic (averaging, summation, probabilistic boost). This is a creative way to manage supply and create potentially stronger entities.
4.  **Probabilistic Outcomes (`_getProbabilisticOutcome`):** Many actions (evolution, mutations, ability discovery) have outcomes determined by chance, modified by the creature's on-chain stats. While the randomness source (`block.timestamp`, `block.number`, `msg.sender`) is basic and predictable for sophisticated attackers, it's sufficient for demonstrating the concept in an example contract. For a real game, Chainlink VRF or similar verifiable randomness is recommended.
5.  **Energy System with Decay:** Actions cost energy (`_checkAndPrepareForAction`). Energy naturally decays over time (`_applyEnergyDecay`, checked at the start of actions). The `restCreature` function adds a status that changes the decay/recovery rate, adding a strategic choice for the owner. `rechargeEnergy` provides a paid shortcut.
6.  **Mutation Influence (`mutationInfluence`, `initiateMutationProcess`):** `initiateMutationProcess` allows a user to spend resources for a chance to add *future* influence (positive or negative) on specific traits. This influence is then applied when a creature successfully evolves (`triggerEvolutionAttempt`), decoupling the influence action from its effect and adding a strategic planning element.
7.  **Ability Discovery (`abilityFlags`, `discoverNewAbility`):** Creatures can probabilistically discover abilities, represented by a bitmask (`abilityFlags`). `discoverNewAbility` consumes energy and adds a new bit if successful and the ability hasn't been found yet, adding permanent boosts or modifiers (though the contract doesn't implement the *effect* of these abilities, only their discovery and on-chain record).
8.  **Global Events (`GlobalEvent`, `triggerGlobalEvent`):** The owner can trigger temporary events that modify gameplay mechanics (e.g., boost evolution chance, reduce energy costs). This adds dynamic environmental factors managed by a central authority.
9.  **ERC721Enumerable:** Included to easily list all tokens owned by a specific address (`tokensOfOwner`), which is a common utility needed for interacting with NFT collections.

This contract goes significantly beyond standard static NFTs or basic game contracts by incorporating dynamic state, simulated AI, complex interactions, probabilistic mechanics, and layered systems like mutation influence and energy decay.