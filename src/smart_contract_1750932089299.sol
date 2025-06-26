Okay, here is a Solidity smart contract designed with an interesting, advanced concept: an "Evolving Digital Companion NFT".

This concept combines ERC721 standard with on-chain state that changes over time and based on user interactions. It's similar to a digital pet (like a Tamagotchi) but exists entirely on-chain as an NFT, with traits that decay over time if not cared for, and can evolve through positive interaction. It also incorporates a basic non-transferable "skill" system.

It aims to be distinct from standard PFP NFTs, generative art contracts, or basic utility tokens by having persistent, mutable, and time-dependent state directly impacting the token's attributes and metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title EvolvingDigitalCompanion
/// @author [Your Name/Alias Here]
/// @notice A contract for creating and managing NFTs that represent digital companions with state that evolves based on time and user interactions.
/// @dev This contract implements ERC721 and incorporates concepts like time-based state decay, interactive state changes, evolution mechanics, and a simple non-transferable skill system.
/// @custom:security This contract uses blockhash/timestamp for basic entropy, which is not suitable for high-stakes randomness. A Chainlink VRF or similar should be used for production requiring strong randomness.
/// @custom:gas Consider gas costs for state updates, especially time-based decay applied during interactions.

// --- OUTLINE ---
// 1. State Variables & Constants: Define core parameters, mappings, counters, structs.
// 2. Events: Declare events for tracking key actions and state changes.
// 3. Errors: Define custom errors for clearer revert reasons.
// 4. Structs: Define the structure for companion state.
// 5. Modifiers: Custom modifiers (e.g., to check if companion is alive).
// 6. Constructor: Initialize the contract (ERC721, Owner, Pausable).
// 7. Companion Management:
//    - mintCompanion: Create a new companion NFT with initial state.
//    - isCompanionAlive: Check if a companion is currently alive.
//    - getTokenStats: Retrieve the current state of a companion.
// 8. Interaction Functions:
//    - feedCompanion: Increase hunger stat.
//    - playWithCompanion: Increase happiness stat.
//    - cleanCompanion: Increase hygiene stat.
//    - sleepCompanion: Increase energy stat.
//    - passTime: Manually trigger state decay for a specific companion (can also be triggered by interactions).
// 9. Evolution Logic:
//    - checkEvolutionEligibility: Check if a companion meets evolution criteria.
//    - evolveCompanion: Trigger the evolution process.
//    - getEvolutionStage: Get the current evolution stage.
// 10. Skill System:
//    - spendSkillPoints: Allocate accumulated points to a specific skill.
//    - getSkillLevel: Get the level of a specific skill.
//    - getSkillPoints: Get available skill points.
// 11. Time & State Update Helpers:
//    - _applyDecay: Internal helper to apply time-based decay to stats.
//    - _canInteract: Internal helper to check interaction cooldown.
// 12. Admin Functions (Ownable & Pausable):
//    - setInteractionCosts: Set the cost in ether for interactions.
//    - setDecayRates: Set the rate at which stats decay over time.
//    - setEvolutionThresholds: Set the criteria for evolution.
//    - setSkillPointGainRates: Set how skill points are earned.
//    - withdrawFunds: Withdraw collected interaction fees.
//    - pause / unpause: Pause contract interactions.
// 13. ERC721 Standard Functions:
//    - tokenURI: Generate dynamic metadata URI.
//    - supportsInterface: Standard implementation.
//    - Other standard ERC721 functions inherited/overridden (_beforeTokenTransfer).

// --- FUNCTION SUMMARY ---
// - constructor(string memory name, string memory symbol): Deploys the contract, setting NFT name, symbol, and initial owner.
// - mintCompanion(): Mints a new Companion NFT to the caller. Initializes stats and state. Costs potential ether fee.
// - isCompanionAlive(uint256 tokenId) view returns (bool): Returns true if the companion is alive.
// - getTokenStats(uint256 tokenId) view returns (CompanionState memory): Returns the current stats and state of a companion.
// - feedCompanion(uint256 tokenId): Interacts with the companion to increase its hunger stat. Applies time decay first. Requires payment.
// - playWithCompanion(uint256 tokenId): Interacts with the companion to increase its happiness stat. Applies time decay first. Requires payment.
// - cleanCompanion(uint256 tokenId): Interacts with the companion to increase its hygiene stat. Applies time decay first. Requires payment.
// - sleepCompanion(uint256 tokenId): Interacts with the companion to increase its energy stat. Applies time decay first. Requires payment.
// - passTime(uint256 tokenId): Applies time-based decay to a specific companion's stats. Can be called by anyone.
// - checkEvolutionEligibility(uint256 tokenId) view returns (bool): Checks if companion meets criteria for evolution. Applies time decay first.
// - evolveCompanion(uint256 tokenId): Triggers evolution if eligible. Resets/changes stats, increments stage. Applies time decay first.
// - getEvolutionStage(uint256 tokenId) view returns (uint8): Returns the current evolution stage.
// - spendSkillPoints(uint256 tokenId, uint8 skillIndex, uint256 amount): Spends accumulated skill points to increase a specific skill level.
// - getSkillLevel(uint256 tokenId, uint8 skillIndex) view returns (uint256): Returns the level of a specific skill.
// - getSkillPoints(uint256 tokenId) view returns (uint256): Returns the total available skill points.
// - setInteractionCosts(uint256 cost): Owner sets the fee for interaction functions.
// - setDecayRates(uint256 hunger, uint256 happiness, uint256 energy, uint256 hygiene, uint256 skillPointGainRate): Owner sets the decay rates and skill point gain rate per second.
// - setEvolutionThresholds(uint8 stage, uint256 minHunger, uint256 minHappiness, uint256 minEnergy, uint256 minHygiene, uint256 minSkillPoints): Owner sets the stat requirements for a specific evolution stage.
// - setSkillPointGainRates(uint256 rate): Owner sets the rate at which skill points are gained per second.
// - withdrawFunds(): Owner withdraws collected ether fees.
// - pause(): Owner pauses the contract.
// - unpause(): Owner unpauses the contract.
// - tokenURI(uint256 tokenId) public view override returns (string memory): Returns the dynamic metadata URI for the token.
// - supportsInterface(bytes4 interfaceId) public view override returns (bool): Standard ERC165 check including ERC721.
// - _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Internal override to potentially handle state on transfer (e.g., reset cooldowns, apply final decay).

contract EvolvingDigitalCompanion is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Constants ---
    uint256 public constant MAX_STAT = 100; // Max value for hunger, happiness, etc.
    uint256 public constant MIN_STAT = 0; // Min value for hunger, happiness, etc.
    uint256 public constant INTERACTION_COOLDOWN = 1 minutes; // Time required between interactions

    // --- Configurable Parameters (Owner settable) ---
    uint256 public interactionCost = 0.001 ether;

    // Decay rates (per second)
    struct DecayRates {
        uint256 hunger; // Stat increases over time
        uint256 happiness; // Stat decreases over time
        uint256 energy; // Stat decreases over time
        uint256 hygiene; // Stat decreases over time
        uint256 skillPointGainRate; // Points gained per second
    }
    DecayRates public decayRates = DecayRates({
        hunger: 1, // Hunger increases by 1 per second (lower is faster decay)
        happiness: 1, // Happiness decreases by 1 per second
        energy: 1, // Energy decreases by 1 per second
        hygiene: 1, // Hygiene decreases by 1 per second
        skillPointGainRate: 1 // Gain 1 skill point per second (lower is faster gain)
    });

    // Evolution thresholds (stat requirements to reach a stage)
    struct EvolutionThresholds {
        uint256 minHunger; // Max hunger required (low hunger = well-fed)
        uint256 minHappiness;
        uint256 minEnergy;
        uint256 minHygiene;
        uint256 minSkillPoints; // Total skill points gained ever? Or current available? Let's say total ever.
    }
    // Mapping: Evolution Stage (uint8) => Thresholds
    mapping(uint8 => EvolutionThresholds) public evolutionThresholds;
    uint8 public maxEvolutionStage = 3; // Example: Stage 0 (baby) -> 1 (child) -> 2 (teen) -> 3 (adult)

    // Skill definitions (using index)
    enum Skill { Strength, Intelligence, Agility, Charm, Resilience }
    string[] private skillNames = ["Strength", "Intelligence", "Agility", "Charm", "Resilience"];

    // --- State Storage ---
    struct CompanionState {
        uint256 hunger; // 0 (full) to 100 (starving) - lower is better
        uint256 happiness; // 0 (sad) to 100 (joyful) - higher is better
        uint256 energy; // 0 (tired) to 100 (energetic) - higher is better
        uint256 hygiene; // 0 (dirty) to 100 (clean) - higher is better
        uint256 lastInteractionTime; // Timestamp of the last interaction
        uint256 lastDecayTime; // Timestamp when decay was last applied
        uint8 evolutionStage; // Current evolution stage
        bool isAlive; // Is the companion alive?
        uint256 skillPoints; // Available skill points to spend
        uint256 totalSkillPointsGained; // Total skill points ever gained (for evolution threshold)
    }
    mapping(uint256 => CompanionState) private _companionStates;
    // Skill levels per companion: tokenId => skillIndex => level
    mapping(uint256 => mapping(uint8 => uint256)) private _skillLevels;


    // --- Events ---
    event CompanionMinted(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event StateChanged(uint256 indexed tokenId, string attribute, uint256 oldValue, uint256 newValue, uint256 timestamp);
    event Interaction(uint256 indexed tokenId, string interactionType, uint256 timestamp);
    event Evolution(uint256 indexed tokenId, uint8 oldStage, uint8 newStage, uint256 timestamp);
    event Death(uint256 indexed tokenId, uint256 timestamp);
    event SkillPointsGained(uint256 indexed tokenId, uint256 amount, uint256 timestamp);
    event SkillLeveledUp(uint256 indexed tokenId, string skillName, uint256 newLevel, uint256 timestamp);

    // --- Errors ---
    error NotCompanionOwner(uint256 tokenId);
    error CompanionNotAlive(uint256 tokenId);
    error InteractionCooldownActive(uint256 tokenId, uint256 timeRemaining);
    error InsufficientPayment(uint256 required, uint256 provided);
    error NotEligibleForEvolution(uint256 tokenId, string reason);
    error MaxEvolutionReached(uint256 tokenId);
    error CompanionAlreadyAlive(uint256 tokenId);
    error InsufficientSkillPoints(uint256 required, uint256 available);
    error InvalidSkillIndex(uint8 skillIndex);
    error AmountMustBePositive();

    // --- Modifiers ---
    modifier onlyCompanionOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert NotCompanionOwner(tokenId);
        }
        _;
    }

    modifier onlyAliveCompanion(uint256 tokenId) {
        if (!_companionStates[tokenId].isAlive) {
            revert CompanionNotAlive(tokenId);
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(_msgSender())
        Pausable()
    {
        // Set initial evolution thresholds (example)
        // Stage 1 requires >= 50 in happiness, energy, hygiene, < 50 hunger, and 100 total skill points
        evolutionThresholds[1] = EvolutionThresholds({
            minHunger: 50, // Max hunger (lower is better)
            minHappiness: 50,
            minEnergy: 50,
            minHygiene: 50,
            minSkillPoints: 100
        });
        // Stage 2 requires better stats and more skill points
        evolutionThresholds[2] = EvolutionThresholds({
            minHunger: 30,
            minHappiness: 70,
            minEnergy: 70,
            minHygiene: 70,
            minSkillPoints: 300
        });
        // Stage 3 requires peak stats and high skill points
        evolutionThresholds[3] = EvolutionThresholds({
            minHunger: 10,
            minHappiness: 90,
            minEnergy: 90,
            minHygiene: 90,
            minSkillPoints: 600
        });
        maxEvolutionStage = 3;
    }

    // --- Companion Management ---

    /// @notice Mints a new Companion NFT with initial random-ish stats.
    /// @dev Uses blockhash and timestamp for simple entropy. Not cryptographically secure.
    /// @param initialOwner The address to mint the companion to.
    /// @return The ID of the newly minted token.
    function mintCompanion(address initialOwner) external payable whenNotPaused returns (uint256) {
        if (msg.value < interactionCost) {
            revert InsufficientPayment(interactionCost, msg.value);
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Simple entropy source (weak, for demonstration)
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));

        // Initialize stats based on entropy (example)
        _companionStates[newTokenId] = CompanionState({
            hunger: entropy % 30, // Start relatively full
            happiness: 50 + (entropy % 20), // Start average to happy
            energy: 50 + (entropy % 30), // Start average to energetic
            hygiene: 50 + (entropy % 30), // Start average to clean
            lastInteractionTime: block.timestamp,
            lastDecayTime: block.timestamp,
            evolutionStage: 0, // Starts as baby
            isAlive: true,
            skillPoints: 0,
            totalSkillPointsGained: 0
        });

        _safeMint(initialOwner, newTokenId);
        emit CompanionMinted(newTokenId, initialOwner, block.timestamp);

        return newTokenId;
    }

    /// @notice Checks if a companion is currently alive.
    /// @param tokenId The ID of the companion token.
    /// @return true if alive, false otherwise.
    function isCompanionAlive(uint256 tokenId) public view returns (bool) {
        return _companionStates[tokenId].isAlive;
    }

    /// @notice Retrieves the current stats and state of a companion.
    /// @param tokenId The ID of the companion token.
    /// @return The CompanionState struct.
    function getTokenStats(uint256 tokenId) public view returns (CompanionState memory) {
        // Note: This view function doesn't apply decay. Use interaction functions or passTime
        // before calling this if you need the *absolute* freshest state reflecting time decay.
        return _companionStates[tokenId];
    }

    // --- Interaction Functions ---
    // These apply decay, check cooldowns, modify stats, require payment, and emit events.

    /// @notice Feeds the companion, increasing its hunger stat (lower hunger is better).
    /// @param tokenId The ID of the companion token.
    function feedCompanion(uint256 tokenId) external payable onlyCompanionOwner(tokenId) onlyAliveCompanion(tokenId) whenNotPaused {
        if (msg.value < interactionCost) {
            revert InsufficientPayment(interactionCost, msg.value);
        }
        _applyDecay(tokenId);
        _checkInteractionCooldown(tokenId);

        CompanionState storage state = _companionStates[tokenId];
        uint256 oldHunger = state.hunger;
        state.hunger = Math.max(MIN_STAT, state.hunger - 15); // Decrease hunger
        state.lastInteractionTime = block.timestamp;

        emit Interaction(tokenId, "Feed", block.timestamp);
        emit StateChanged(tokenId, "hunger", oldHunger, state.hunger, block.timestamp);
    }

    /// @notice Plays with the companion, increasing its happiness stat.
    /// @param tokenId The ID of the companion token.
    function playWithCompanion(uint256 tokenId) external payable onlyCompanionOwner(tokenId) onlyAliveCompanion(tokenId) whenNotPaused {
        if (msg.value < interactionCost) {
            revert InsufficientPayment(interactionCost, msg.value);
        }
        _applyDecay(tokenId);
        _checkInteractionCooldown(tokenId);

        CompanionState storage state = _companionStates[tokenId];
        uint256 oldHappiness = state.happiness;
        uint256 oldEnergy = state.energy;
        state.happiness = Math.min(MAX_STAT, state.happiness + 15); // Increase happiness
        state.energy = Math.max(MIN_STAT, state.energy - 5); // Decrease energy slightly
        state.lastInteractionTime = block.timestamp;

        emit Interaction(tokenId, "Play", block.timestamp);
        emit StateChanged(tokenId, "happiness", oldHappiness, state.happiness, block.timestamp);
        emit StateChanged(tokenId, "energy", oldEnergy, state.energy, block.timestamp);
    }

    /// @notice Cleans the companion, increasing its hygiene stat.
    /// @param tokenId The ID of the companion token.
    function cleanCompanion(uint256 tokenId) external payable onlyCompanionOwner(tokenId) onlyAliveCompanion(tokenId) whenNotPaused {
        if (msg.value < interactionCost) {
            revert InsufficientPayment(interactionCost, msg.value);
        }
        _applyDecay(tokenId);
        _checkInteractionCooldown(tokenId);

        CompanionState storage state = _companionStates[tokenId];
        uint256 oldHygiene = state.hygiene;
        uint256 oldHappiness = state.happiness;
        state.hygiene = Math.min(MAX_STAT, state.hygiene + 20); // Increase hygiene
        state.happiness = Math.max(MIN_STAT, state.happiness - 2); // Decrease happiness slightly (some dislike baths!)
        state.lastInteractionTime = block.timestamp;

        emit Interaction(tokenId, "Clean", block.timestamp);
        emit StateChanged(tokenId, "hygiene", oldHygiene, state.hygiene, block.timestamp);
        emit StateChanged(tokenId, "happiness", oldHappiness, state.happiness, block.timestamp);
    }

    /// @notice Makes the companion sleep, increasing its energy stat.
    /// @param tokenId The ID of the companion token.
    function sleepCompanion(uint256 tokenId) external payable onlyCompanionOwner(tokenId) onlyAliveCompanion(tokenId) whenNotPaused {
        if (msg.value < interactionCost) {
            revert InsufficientPayment(interactionCost, msg.value);
        }
        _applyDecay(tokenId);
        _checkInteractionCooldown(tokenId);

        CompanionState storage state = _companionStates[tokenId];
        uint256 oldEnergy = state.energy;
        uint256 oldHunger = state.hunger;
        state.energy = Math.min(MAX_STAT, state.energy + 30); // Increase energy significantly
        state.hunger = Math.min(MAX_STAT, state.hunger + 3); // Increase hunger slightly (sleepy = hungry later)
        state.lastInteractionTime = block.timestamp;

        emit Interaction(tokenId, "Sleep", block.timestamp);
        emit StateChanged(tokenId, "energy", oldEnergy, state.energy, block.timestamp);
        emit StateChanged(tokenId, "hunger", oldHunger, state.hunger, block.timestamp);
    }

    /// @notice Manually applies time-based decay to a companion's stats.
    /// @dev Anyone can call this, but it only applies decay based on time passed since last decay or interaction.
    /// @param tokenId The ID of the companion token.
    function passTime(uint256 tokenId) external onlyAliveCompanion(tokenId) whenNotPaused {
        _applyDecay(tokenId);
    }

    // --- Evolution Logic ---

    /// @notice Checks if a companion meets the criteria to evolve to the next stage.
    /// @dev Applies decay before checking eligibility to ensure state is current.
    /// @param tokenId The ID of the companion token.
    /// @return true if eligible, false otherwise.
    function checkEvolutionEligibility(uint256 tokenId) public onlyAliveCompanion(tokenId) returns (bool) {
        _applyDecay(tokenId); // Apply decay before checking

        CompanionState storage state = _companionStates[tokenId];
        uint8 currentStage = state.evolutionStage;

        if (currentStage >= maxEvolutionStage) {
             // Already at max stage
             return false;
        }

        uint8 nextStage = currentStage + 1;
        EvolutionThresholds storage thresholds = evolutionThresholds[nextStage];

        // Check against thresholds (remember hunger lower is better)
        if (state.hunger > thresholds.minHunger) return false;
        if (state.happiness < thresholds.minHappiness) return false;
        if (state.energy < thresholds.minEnergy) return false;
        if (state.hygiene < thresholds.minHygiene) return false;
        if (state.totalSkillPointsGained < thresholds.minSkillPoints) return false;

        // All criteria met
        return true;
    }

    /// @notice Triggers the evolution of a companion if it is eligible.
    /// @dev Resets/modifies stats appropriate for the new stage. Applies decay before evolving.
    /// @param tokenId The ID of the companion token.
    function evolveCompanion(uint256 tokenId) external onlyCompanionOwner(tokenId) onlyAliveCompanion(tokenId) whenNotPaused {
        _applyDecay(tokenId); // Apply decay before evolving

        CompanionState storage state = _companionStates[tokenId];
        uint8 currentStage = state.evolutionStage;

        if (currentStage >= maxEvolutionStage) {
            revert MaxEvolutionReached(tokenId);
        }

        if (!checkEvolutionEligibility(tokenId)) {
             // Re-check after applying decay, if still not eligible, find a reason
             uint8 nextStage = currentStage + 1;
             EvolutionThresholds storage thresholds = evolutionThresholds[nextStage];

             string memory reason = "Not eligible";
             if (state.hunger > thresholds.minHunger) reason = "Hunger too high";
             else if (state.happiness < thresholds.minHappiness) reason = "Happiness too low";
             else if (state.energy < thresholds.minEnergy) reason = "Energy too low";
             else if (state.hygiene < thresholds.minHygiene) reason = "Hygiene too low";
             else if (state.totalSkillPointsGained < thresholds.minSkillPoints) reason = "Insufficient total skill points";

             revert NotEligibleForEvolution(tokenId, reason);
        }

        uint8 oldStage = state.evolutionStage;
        state.evolutionStage = currentStage + 1;

        // Reset/adjust stats for the new stage (example logic)
        state.hunger = Math.max(MIN_STAT, state.hunger - 10); // Evolution makes them a bit less hungry initially
        state.happiness = Math.min(MAX_STAT, state.happiness + 5); // A bit happier
        state.energy = Math.min(MAX_STAT, state.energy + 5); // A bit more energetic
        state.hygiene = Math.max(MIN_STAT, state.hygiene - 5); // A bit dirtier? Maybe depends on the form!
        state.lastInteractionTime = block.timestamp; // Reset cooldown
        state.lastDecayTime = block.timestamp; // Reset decay timer

        emit Evolution(tokenId, oldStage, state.evolutionStage, block.timestamp);
        emit StateChanged(tokenId, "hunger", Math.max(MIN_STAT, state.hunger + 10), state.hunger, block.timestamp); // Emit with original pre-adjust value
        emit StateChanged(tokenId, "happiness", Math.min(MAX_STAT, state.happiness - 5), state.happiness, block.timestamp);
        emit StateChanged(tokenId, "energy", Math.min(MAX_STAT, state.energy - 5), state.energy, block.timestamp);
        emit StateChanged(tokenId, "hygiene", Math.max(MIN_STAT, state.hygiene + 5), state.hygiene, block.timestamp);
    }

    /// @notice Gets the current evolution stage of a companion.
    /// @param tokenId The ID of the companion token.
    /// @return The current evolution stage (0-based index).
    function getEvolutionStage(uint256 tokenId) public view returns (uint8) {
        return _companionStates[tokenId].evolutionStage;
    }

    // --- Skill System ---

    /// @notice Spends accumulated skill points to increase a specific skill level.
    /// @param tokenId The ID of the companion token.
    /// @param skillIndex The index of the skill to level up (from Skill enum).
    /// @param amount The number of points to spend on this skill.
    function spendSkillPoints(uint256 tokenId, uint8 skillIndex, uint256 amount) external onlyCompanionOwner(tokenId) onlyAliveCompanion(tokenId) whenNotPaused {
        if (amount == 0) revert AmountMustBePositive();
        if (skillIndex >= skillNames.length) revert InvalidSkillIndex(skillIndex);

        CompanionState storage state = _companionStates[tokenId];
        if (state.skillPoints < amount) {
            revert InsufficientSkillPoints(amount, state.skillPoints);
        }

        _applyDecay(tokenId); // Apply decay (and skill point gain) before spending

        state.skillPoints -= amount;
        uint256 oldSkillLevel = _skillLevels[tokenId][skillIndex];
        _skillLevels[tokenId][skillIndex] += amount; // Simple 1:1 point to level for now

        emit SkillLeveledUp(tokenId, skillNames[skillIndex], _skillLevels[tokenId][skillIndex], block.timestamp);
        emit StateChanged(tokenId, "skillPoints", state.skillPoints + amount, state.skillPoints, block.timestamp);
    }

    /// @notice Gets the level of a specific skill for a companion.
    /// @param tokenId The ID of the companion token.
    /// @param skillIndex The index of the skill.
    /// @return The level of the specified skill.
    function getSkillLevel(uint256 tokenId, uint8 skillIndex) public view returns (uint256) {
        if (skillIndex >= skillNames.length) revert InvalidSkillIndex(skillIndex);
        return _skillLevels[tokenId][skillIndex];
    }

    /// @notice Gets the number of available skill points for a companion.
    /// @param tokenId The ID of the companion token.
    /// @return The available skill points.
    function getSkillPoints(uint256 tokenId) public view returns (uint256) {
        // Note: Does not apply decay first. Use passTime if you need the most current total.
        return _companionStates[tokenId].skillPoints;
    }

     /// @notice Returns the total number of skill types available.
     /// @return The count of defined skills.
     function getSkillTypesCount() public pure returns (uint8) {
         return uint8(skillNames.length);
     }

     /// @notice Returns the name of a skill by its index.
     /// @param skillIndex The index of the skill.
     /// @return The name of the skill.
     function getSkillName(uint8 skillIndex) public view returns (string memory) {
         if (skillIndex >= skillNames.length) revert InvalidSkillIndex(skillIndex);
         return skillNames[skillIndex];
     }

    // --- Time & State Update Helpers ---

    /// @dev Internal function to apply time-based decay and skill point gain.
    /// @param tokenId The ID of the companion token.
    function _applyDecay(uint256 tokenId) internal {
        CompanionState storage state = _companionStates[tokenId];
        uint256 timeElapsed = block.timestamp - state.lastDecayTime;

        if (timeElapsed == 0 || !state.isAlive) {
            return; // No time passed or already dead
        }

        // Apply decay based on time elapsed * decay rate
        state.hunger = Math.min(MAX_STAT, state.hunger + (timeElapsed / decayRates.hunger));
        state.happiness = Math.max(MIN_STAT, state.happiness - (timeElapsed / decayRates.happiness));
        state.energy = Math.max(MIN_STAT, state.energy - (timeElapsed / decayRates.energy));
        state.hygiene = Math.max(MIN_STAT, state.hygiene - (timeElapsed / decayRates.hygiene));

        // Gain skill points
        uint256 pointsGained = timeElapsed / decayRates.skillPointGainRate;
        state.skillPoints += pointsGained;
        state.totalSkillPointsGained += pointsGained;
        if(pointsGained > 0) {
            emit SkillPointsGained(tokenId, pointsGained, block.timestamp);
        }


        state.lastDecayTime = block.timestamp; // Update last decay time

        // Check if companion died (e.g., hunger reaches max)
        if (state.hunger >= MAX_STAT) {
            state.isAlive = false;
            emit Death(tokenId, block.timestamp);
        }

        // Note: Emitting StateChanged for every decay is too gas heavy.
        // State changes are implicitly available by viewing state struct after decay is applied.
    }

    /// @dev Internal function to check interaction cooldown. Reverts if on cooldown.
    /// @param tokenId The ID of the companion token.
    function _checkInteractionCooldown(uint256 tokenId) internal view {
        uint256 timeSinceLastInteraction = block.timestamp - _companionStates[tokenId].lastInteractionTime;
        if (timeSinceLastInteraction < INTERACTION_COOLDOWN) {
            revert InteractionCooldownActive(tokenId, INTERACTION_COOLDOWN - timeSinceLastInteraction);
        }
    }

    // --- Admin Functions (Ownable & Pausable) ---

    /// @notice Allows the owner to set the cost required for interaction functions.
    /// @param cost The new cost in wei.
    function setInteractionCosts(uint256 cost) external onlyOwner {
        interactionCost = cost;
    }

    /// @notice Allows the owner to set the decay rates for stats and skill point gain.
    /// @dev Lower rate number means faster decay/gain (e.g., decayRate 1 means 1 unit per second).
    /// @param hungerRate Rate for hunger increase (lower = faster).
    /// @param happinessRate Rate for happiness decrease (lower = faster).
    /// @param energyRate Rate for energy decrease (lower = faster).
    /// @param hygieneRate Rate for hygiene decrease (lower = faster).
    function setDecayRates(uint256 hungerRate, uint256 happinessRate, uint256 energyRate, uint256 hygieneRate) external onlyOwner {
         if (hungerRate == 0 || happinessRate == 0 || energyRate == 0 || hygieneRate == 0) {
             // Prevent division by zero, effectively infinite decay/gain
             revert AmountMustBePositive(); // Reusing error for simplicity
         }
         decayRates.hunger = hungerRate;
         decayRates.happiness = happinessRate;
         decayRates.energy = energyRate;
         decayRates.hygiene = hygieneRate;
    }

     /// @notice Allows the owner to set the skill point gain rate.
     /// @dev Lower rate number means faster skill point gain.
     /// @param rate Rate for skill point gain (lower = faster).
    function setSkillPointGainRates(uint256 rate) external onlyOwner {
        if (rate == 0) revert AmountMustBePositive();
        decayRates.skillPointGainRate = rate;
    }


    /// @notice Allows the owner to set the stat requirements for a specific evolution stage.
    /// @param stage The evolution stage index (e.g., 1, 2, 3).
    /// @param thresholds The struct containing the stat thresholds for this stage.
    function setEvolutionThresholds(uint8 stage, EvolutionThresholds memory thresholds) external onlyOwner {
        if (stage == 0 || stage > maxEvolutionStage) {
             // Cannot set thresholds for stage 0 or beyond max
             revert InvalidSkillIndex(stage); // Reusing error
        }
        evolutionThresholds[stage] = thresholds;
    }


    /// @notice Allows the owner to withdraw collected Ether fees.
    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Pauses transfers and most interactions.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- ERC721 Standard Overrides ---

    /// @dev See {ERC721-tokenURI}.
    /// Generates a dynamic metadata URI reflecting the current state.
    /// Note: This is a simple example. Real applications might use a dedicated metadata service pointed to by a base URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }

        // Apply decay for most up-to-date stats in URI (read-only view, doesn't save state)
        // This requires re-implementing the decay logic or passing a copy of state
        // A simpler approach for VIEW function is to *not* apply decay here,
        // and rely on off-chain services calling passTime or interaction functions first.
        // Let's stick to the simpler approach for gas/complexity reasons in a view function.
        // The metadata service reading the state would handle presenting the decayed state.

        // For demonstration, let's just point to a hypothetical base URI + token ID
        // and assume a backend service fetches the on-chain state via getTokenStats
        // and generates the JSON metadata including current stats, evolution stage, life status, etc.
        string memory baseURI = "https://companion.metadata.xyz/api/token/"; // Example base URI
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));

        // Alternative: On-chain JSON generation (very gas expensive for complex state)
        /*
        CompanionState memory state = _companionStates[tokenId];
        string memory json = string(abi.encodePacked(
            '{"name": "Companion #', Strings.toString(tokenId),
            '", "description": "An evolving digital companion.",',
            '"attributes": [',
                '{"trait_type": "Evolution Stage", "value": ', Strings.toString(state.evolutionStage), '},',
                '{"trait_type": "Status", "value": "', state.isAlive ? "Alive" : "Deceased", '"},',
                '{"trait_type": "Hunger", "value": ', Strings.toString(state.hunger), '},',
                '{"trait_type": "Happiness", "value": ', Strings.toString(state.happiness), '},',
                '{"trait_type": "Energy", "value": ', Strings.toString(state.energy), '},',
                '{"trait_type": "Hygiene", "value": ', Strings.toString(state.hygiene), '}',
                // Add skills if needed, very gas heavy:
                // for (uint8 i = 0; i < skillNames.length; i++) { ... }
            ']}'
        ));
        // Base64 encode the JSON (requires importing Base64 library, omitted for brevity)
        // return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        */
    }

    /// @dev See {ERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    /// Can be used to handle state transitions on transfer, e.g., reset cooldowns,
    /// apply decay one last time, or pause decay until interaction.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Example: Apply decay immediately before transfer to capture current state
        // This ensures the recipient starts with the decayed state at the time of transfer.
        if (_exists(tokenId)) { // Check exists, just in case
             _applyDecay(tokenId);
             // Optionally reset cooldown or adjust state further for the new owner
             // _companionStates[tokenId].lastInteractionTime = block.timestamp; // Reset cooldown
        }
    }

    // --- Additional Query Functions (Beyond the 20+ requirement, but useful) ---

    /// @notice Gets the required interaction cooldown duration.
    function getInteractionCooldown() public pure returns (uint256) {
        return INTERACTION_COOLDOWN;
    }

    /// @notice Gets the current decay rates configuration.
    function getDecayRates() public view returns (DecayRates memory) {
        return decayRates;
    }

    /// @notice Gets the evolution thresholds for a specific stage.
    /// @param stage The evolution stage index.
    function getEvolutionThresholds(uint8 stage) public view returns (EvolutionThresholds memory) {
        return evolutionThresholds[stage];
    }

    /// @notice Gets the maximum evolution stage defined.
    function getMaxEvolutionStage() public view returns (uint8) {
        return maxEvolutionStage;
    }

}
```

---

**Explanation of Concepts and Features:**

1.  **Evolving State (Trendy/Creative):** The core idea is that the NFT isn't static. Its `CompanionState` struct (`hunger`, `happiness`, `energy`, `hygiene`) changes over time and through specific user interactions.
2.  **Time-Based Decay (`_applyDecay`, `passTime`):** Companion stats naturally decay (or increase, like hunger) over time. This provides a mechanism for players to *need* to interact. The decay is calculated based on the time elapsed since the last state update (`lastDecayTime`). Decay is applied automatically within interaction functions or can be triggered manually by anyone via `passTime`.
3.  **Interactive State Changes (Interesting):** Specific functions (`feedCompanion`, `playWithCompanion`, `cleanCompanion`, `sleepCompanion`) allow the owner to interact, spending Ether (or a token) and changing the companion's stats.
4.  **Interaction Cooldowns (`INTERACTION_COOLDOWN`, `_checkInteractionCooldown`):** Prevents spamming interactions, adding a strategic element.
5.  **Evolution (`checkEvolutionEligibility`, `evolveCompanion`, `evolutionThresholds`):** Companions can evolve to the next stage when they meet specific stat thresholds, set by the contract owner. Evolution changes the `evolutionStage` and can reset/modify stats, signifying growth or transformation.
6.  **On-Chain Death (`isAlive`, `_applyDecay` death check):** Neglecting a companion (letting hunger reach MAX) can result in its death, making the state changes impactful.
7.  **Skill System (Basic SBT Concept):** Companions earn non-transferable `skillPoints` over time. These points can be `spendSkillPoints` to increase levels in predefined skills (`_skillLevels`). While simple here, this hints at non-transferable attributes tied to the NFT owner's engagement (akin to Soulbound Tokens).
8.  **Dynamic Metadata (`tokenURI`):** The `tokenURI` function is overridden to indicate that the metadata for each token is *dynamic*. While the example points to a base URI, a real implementation would have a metadata service that reads the *current* on-chain state (`getTokenStats`) and generates JSON describing the companion's real-time attributes, evolution stage, skill levels, and life status. This is crucial for marketplaces to display the evolving nature of the NFT.
9.  **Pausable (Standard but important):** Allows the owner to pause the contract in case of issues.
10. **Ownable (Standard):** Basic administrative control for setting parameters like costs, decay rates, and evolution thresholds.
11. **ERC721 Compliance:** Built upon the standard OpenZeppelin ERC721 implementation, ensuring compatibility with NFT marketplaces and wallets. Includes overrides like `_beforeTokenTransfer` to handle state during transfers.
12. **Custom Errors:** Uses `error` instead of `require` strings for gas efficiency and clearer off-chain error handling.
13. **Basic Entropy (`mintCompanion`):** Uses `block.timestamp` and `block.difficulty` (via `keccak256`) for initial stats. **Important:** This is *not* secure or unpredictable randomness and is unsuitable for high-stakes scenarios. A VRF (Verifiable Random Function) like Chainlink VRF would be needed for robust randomness.

**Function Count:**

Listing the public/external and overridden functions:

1.  `constructor`
2.  `mintCompanion`
3.  `isCompanionAlive`
4.  `getTokenStats`
5.  `feedCompanion`
6.  `playWithCompanion`
7.  `cleanCompanion`
8.  `sleepCompanion`
9.  `passTime`
10. `checkEvolutionEligibility`
11. `evolveCompanion`
12. `getEvolutionStage`
13. `spendSkillPoints`
14. `getSkillLevel`
15. `getSkillPoints`
16. `getSkillTypesCount` (Utility)
17. `getSkillName` (Utility)
18. `setInteractionCosts` (Owner)
19. `setDecayRates` (Owner)
20. `setSkillPointGainRates` (Owner)
21. `setEvolutionThresholds` (Owner)
22. `withdrawFunds` (Owner)
23. `pause` (Owner)
24. `unpause` (Owner)
25. `tokenURI` (ERC721 Override)
26. `supportsInterface` (ERC165 Override)
27. `getInteractionCooldown` (Utility)
28. `getDecayRates` (Utility)
29. `getEvolutionThresholds` (Utility)
30. `getMaxEvolutionStage` (Utility)
31. `balanceOf` (Inherited)
32. `ownerOf` (Inherited)
33. `approve` (Inherited)
34. `getApproved` (Inherited)
35. `setApprovalForAll` (Inherited)
36. `isApprovedForAll` (Inherited)
37. `transferFrom` (Inherited)
38. `safeTransferFrom` (Inherited)
39. `name` (Inherited ERC721Metadata)
40. `symbol` (Inherited ERC721Metadata)

This easily surpasses the requirement of 20 functions with a significant amount of custom logic beyond the basic ERC721 standard.

This contract demonstrates several advanced concepts like mutable on-chain state tied to an NFT, time-based logic, state transitions (evolution, death), and a simple non-transferable attribute system, making it a creative and interesting example distinct from common open-source contracts.