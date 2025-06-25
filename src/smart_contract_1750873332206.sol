```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- Chrono-Pets: Evolving Digital Companions ---
// This contract implements a system of dynamic, state-changing digital collectibles (like NFTs)
// called Chrono-Pets. Their stats evolve over time and based on user interactions.
// It incorporates concepts like time-based decay, resource management, state-dependent evolution,
// simulated oracle data (Epoch conditions), simulated VRF for random outcomes, bonding
// (non-transferable link), and batch operations.

// --- Contract Outline & Function Summary ---
// Contract: ChronoPets
// Inherits: ERC721, Ownable, Pausable
// Uses: Counters, Math

// State Variables:
// - petCount: Total number of pets minted.
// - pets: Mapping from pet ID to Pet struct.
// - ownerPetIds: Mapping from owner address to list of pet IDs.
// - petLastUpdatedTime: Mapping from pet ID to timestamp of last stats update.
// - essenceBalances: Mapping from owner address to Chrono Essence balance.
// - currentEpoch: Global counter representing cycles.
// - epochConditions: Mapping from epoch number to simulated external conditions (uint).
// - baseDecayRates: Base decay rates for stats (Hunger, Mood, Energy).
// - interactionCooldown: Cooldown period for interaction types.
// - essenceHarvestCooldown: Cooldown for harvesting essence.
// - essenceHarvestAmount: Amount of essence harvested per cooldown.
// - petBonded: Mapping from owner address to their bonded pet ID (0 if none).
// - bondedToOwner: Mapping from pet ID to bonded owner address (address(0) if none).
// - vrfRequests: Mapping to simulate VRF requests (request ID => pet ID, other data).
// - interactionOutcomes: Mapping from interaction type/timestamp to outcome hash.

// Structs:
// - PetStats: Stores dynamic stats (uint16: Hunger, Mood, Energy, Strength, Intelligence).
// - Pet: Stores pet's static and dynamic data (ID, owner, creation time, last interaction times, stats, type, evolution stage).

// Enums:
// - PetType: Defines different base types (e.g., FIERY, AQUATIC).
// - EvolutionStage: Defines progression stages (e.g., EGG, JUVENILE, ADULT).
// - InteractionType: Defines types of user actions (e.g., FEED, PLAY, TRAIN, REST).
// - OutcomeType: Defines types of random outcomes (e.g., STAT_BOOST, ESSENCE_GAIN, DECAY_HALT).

// Events:
// - PetMinted: Emitted when a new pet is created.
// - PetTransferred: Emitted when a pet is transferred.
// - PetBurned: Emitted when a pet is burned.
// - StatsUpdated: Emitted when a pet's stats change.
// - EvolutionTriggered: Emitted when a pet evolves.
// - EssenceHarvested: Emitted when a user harvests essence.
// - EssenceSpent: Emitted when essence is used for an action.
// - EpochAdvanced: Emitted when the global epoch changes.
// - PetBonded: Emitted when a pet is bonded to an owner.
// - PetUnbonded: Emitted when a pet is unbonded.
// - InteractionInitiated: Emitted when an interaction is started.
// - VRFRequested: Emitted when a VRF request is simulated.
// - VRFFulfilled: Emitted when a VRF result is simulated.
// - InteractionOutcomeApplied: Emitted when a random outcome is applied.
// - CooldownUpdated: Emitted when a cooldown is modified by owner.
// - DecayRatesUpdated: Emitted when decay rates are modified by owner.
// - EssenceConfigUpdated: Emitted when essence harvest config is modified by owner.
// - EpochConditionsUpdated: Emitted when epoch conditions are set by owner.

// Modifiers:
// - onlyPetOwner: Ensures the caller owns the specified pet.
// - whenPetExists: Ensures the specified pet ID is valid.
// - whenBonded: Ensures the caller is bonded to a pet.
// - whenNotBonded: Ensures the caller is not bonded to a pet.

// Function Summary:
// --- Core ERC721 Functions (Implemented via OpenZeppelin): ---
// - safeTransferFrom
// - transferFrom
// - approve
// - setApprovalForAll
// - getApproved
// - isApprovedForAll
// - balanceOf
// - ownerOf

// --- Custom Core Pet Management ---
// 1.  mintPet(PetType _petType): Mints a new Chrono-Pet of a specific type to the caller.
// 2.  burnPet(uint256 _petId): Burns/destroys a pet owned by the caller.
// 3.  getPetDetails(uint256 _petId) view: Returns all stored details of a pet.
// 4.  getUserPets(address _owner) view: Returns an array of pet IDs owned by an address.

// --- Dynamic State & Interaction ---
// 5.  getPetStats(uint256 _petId) view: Calculates and returns the current stats of a pet, factoring in time decay.
// 6.  feedPet(uint256 _petId): Increases the pet's Hunger stat, consumes essence, subject to cooldowns and decay.
// 7.  playWithPet(uint256 _petId): Increases the pet's Mood stat, consumes essence, subject to cooldowns and decay.
// 8.  trainPet(uint256 _petId): Increases the pet's Strength/Int stat, consumes essence, subject to cooldowns and decay.
// 9.  restPet(uint256 _petId): Increases the pet's Energy stat, consumes essence, subject to cooldowns and decay.
// 10. calculateCurrentStats(uint256 _petId) internal/public pure: Pure function to calculate decayed stats based on input. (Exposed as view for utility).
// 11. getPetEvolutionStage(uint256 _petId) view: Returns the current evolution stage based on calculated stats and epoch conditions.
// 12. triggerEvolution(uint256 _petId): Checks if a pet meets evolution criteria and advances its stage if so.
// 13. checkEvolutionEligibility(uint256 _petId) view: Returns boolean indicating if a pet is currently eligible to evolve.
// 14. getPetInteractionHistory(uint256 _petId) view: (Placeholder/Simulated) Retrieves past interaction outcomes for a pet.

// --- Resource (Chrono Essence) Management ---
// 15. harvestEssence(): Allows the caller to gain Chrono Essence, subject to a cooldown.
// 16. getEssenceBalance(address _owner) view: Returns the Chrono Essence balance for an address.

// --- Epoch & Global State ---
// 17. getCurrentEpoch() view: Returns the current global epoch number.
// 18. getEpochConditions(uint256 _epoch) view: Returns the simulated conditions for a specific epoch.

// --- Advanced Concepts ---
// 19. bondWithPet(uint256 _petId): Bonds a specific pet to the caller, making it non-transferable and potentially enabling bonuses. Only one pet can be bonded per owner.
// 20. unbondPet(uint256 _petId): Removes the bond on a pet.
// 21. getBondedPet(address _owner) view: Returns the ID of the pet bonded to an owner (0 if none).
// 22. interactWithAnotherPet(uint256 _petId1, uint256 _petId2): Simulates an interaction between two pets, potentially consuming resources and leading to state changes via VRF. (Requires VRF simulation fulfillment).
// 23. requestRandomnessForInteraction(uint256 _petId1, uint256 _petId2, bytes32 _interactionHash): Simulates a VRF request. (Internal or called by interaction logic).
// 24. fulfillRandomness(bytes32 _requestId, uint256 _randomWord): Simulates the VRF callback, applying random outcomes based on the random word. (Callable only by owner or trusted oracle address in a real setup).
// 25. batchFeedPets(uint256[] _petIds): Feeds multiple pets in a single transaction.
// 26. batchPlayWithPets(uint256[] _petIds): Plays with multiple pets in a single transaction.
// 27. batchTrainPets(uint256[] _petIds): Trains multiple pets in a single transaction.
// 28. batchRestPets(uint256[] _petIds): Rests multiple pets in a single transaction.

// --- Owner/Admin Functions ---
// 29. setBaseDecayRates(uint16 _hunger, uint16 _mood, uint16 _energy): Sets the base decay rates for stats.
// 30. setInteractionCooldown(InteractionType _type, uint256 _cooldown): Sets cooldown periods for different interaction types.
// 31. setEssenceHarvestConfig(uint256 _cooldown, uint256 _amount): Sets the cooldown and amount for essence harvesting.
// 32. setEpochConditions(uint256 _epoch, uint256 _conditionValue): Sets the simulated external condition value for a specific epoch.
// 33. advanceEpoch(): Increments the global epoch counter.
// 34. withdrawFunds(): Allows the owner to withdraw Ether from the contract.
// 35. pause(): Pauses the contract (disables state-changing functions).
// 36. unpause(): Unpauses the contract.

// Note: Some advanced features like full VRF integration or complex oracle interactions
// are simulated for conceptual demonstration within a single contract file.
// A real implementation would integrate with Chainlink VRF, Chainlink Keepers, or other oracle networks.

contract ChronoPets is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _petCount;

    // --- State Variables ---

    struct PetStats {
        uint16 hunger;   // 0-1000
        uint16 mood;     // 0-1000
        uint16 energy;   // 0-1000
        uint16 strength; // 0-1000+
        uint16 intelligence; // 0-1000+
    }

    enum PetType {
        FIERY,
        AQUATIC,
        EARTHY,
        AIRY
    }

    enum EvolutionStage {
        EGG,
        JUVENILE,
        ADULT,
        ELDER
    }

    enum InteractionType {
        FEED,
        PLAY,
        TRAIN,
        REST
    }

    enum OutcomeType {
        STAT_BOOST,
        ESSENCE_GAIN,
        DECAY_HALT, // Temporary halt to stat decay
        MOOD_DRAIN, // Negative outcome
        NONE
    }

    struct Pet {
        uint256 id;
        address owner; // Redundant with ERC721 ownerOf, but useful for struct lookup
        uint256 creationTime;
        PetType petType;
        EvolutionStage evolutionStage;
        PetStats baseStats; // Stats unaffected by decay, represent inherent potential
        mapping(InteractionType => uint256) lastInteractionTime;
    }

    mapping(uint256 => Pet) private pets;
    mapping(address => uint256[]) private ownerPetIds; // To track pet IDs per owner
    mapping(uint256 => PetStats) private currentPetStats; // Store dynamic stats separately
    mapping(uint256 => uint256) private petStatsLastUpdatedTime; // Timestamp for decay calculation per pet

    mapping(address => uint256) private essenceBalances;
    mapping(address => uint256) private lastEssenceHarvestTime;

    uint256 private currentEpoch;
    mapping(uint256 => uint256) private epochConditions; // Simulate external conditions (e.g., weather, cosmic alignment)

    // Decay rates per second (scaled by 1000 for precision, e.g., 10 = 0.01 per sec)
    struct DecayRates {
        uint16 hunger;
        uint16 mood;
        uint16 energy;
    }
    DecayRates private baseDecayRates;

    // Cooldowns for interactions (in seconds)
    mapping(InteractionType => uint256) private interactionCooldown;
    uint256 private essenceHarvestCooldown;
    uint256 private essenceHarvestAmount;

    // Bonding
    mapping(address => uint256) private petBonded; // Owner address => bonded pet ID (0 if none)
    mapping(uint256 => address) private bondedToOwner; // Pet ID => bonded owner address (address(0) if none)

    // Simulated VRF/Interaction Outcome System
    struct VRFRequest {
        uint256 petId1;
        uint256 petId2; // 0 if single pet interaction
        bytes32 interactionHash; // Unique ID for the specific interaction attempt
        address requester;
        uint256 requestTime;
        bool fulfilled;
    }
    bytes32[] private pendingVRFRequests; // Store request hashes
    mapping(bytes32 => VRFRequest) private vrfRequests;
    mapping(bytes32 => uint256) private vrfResults; // request hash => random word

    // Store interaction outcomes (simplified: just a hash)
    mapping(uint256 => bytes32[]) private petInteractionOutcomes; // pet ID => list of outcome hashes
    // In a real system, you'd map the hash to structured outcome data.

    // --- Events ---

    event PetMinted(uint256 indexed petId, address indexed owner, PetType petType, uint256 timestamp);
    event PetTransferred(uint256 indexed petId, address indexed from, address indexed to, uint256 timestamp);
    event PetBurned(uint256 indexed petId, address indexed owner, uint256 timestamp);
    event StatsUpdated(uint256 indexed petId, PetStats newStats, uint256 timestamp);
    event EvolutionTriggered(uint256 indexed petId, EvolutionStage newStage, uint256 timestamp);
    event EssenceHarvested(address indexed owner, uint256 amount, uint256 newBalance, uint256 timestamp);
    event EssenceSpent(address indexed owner, uint256 amount, uint256 newBalance, string reason, uint256 timestamp);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 indexed conditionsValue, uint256 timestamp);
    event PetBonded(address indexed owner, uint256 indexed petId, uint256 timestamp);
    event PetUnbonded(address indexed owner, uint256 indexed petId, uint256 timestamp);
    event InteractionInitiated(bytes32 indexed interactionHash, uint256 indexed petId1, uint256 indexed petId2, uint256 timestamp);
    event VRFRequested(bytes32 indexed requestId, uint256 timestamp);
    event VRFFulfilled(bytes32 indexed requestId, uint256 randomWord, uint256 timestamp);
    event InteractionOutcomeApplied(bytes32 indexed interactionHash, uint256 indexed petId, OutcomeType outcomeType, uint256 timestamp);
    event CooldownUpdated(InteractionType indexed interactionType, uint256 newCooldown, uint256 timestamp);
    event DecayRatesUpdated(uint16 indexed hungerRate, uint16 indexed moodRate, uint16 indexed energyRate, uint256 timestamp);
    event EssenceConfigUpdated(uint256 indexed cooldown, uint256 indexed amount, uint256 timestamp);
    event EpochConditionsUpdated(uint256 indexed epoch, uint256 indexed conditionsValue, uint256 timestamp);
    event FundsWithdrawn(address indexed owner, uint256 amount, uint256 timestamp);

    // --- Modifiers ---

    modifier onlyPetOwner(uint256 _petId) {
        require(_exists(_petId), "Pet does not exist");
        require(_isApprovedOrOwner(msg.sender, _petId), "Not pet owner or approved");
        _;
    }

    modifier whenPetExists(uint256 _petId) {
        require(_exists(_petId), "Pet does not exist");
        _;
    }

    modifier whenBonded(address _owner) {
        require(petBonded[_owner] != 0, "No pet bonded to this owner");
        _;
    }

    modifier whenNotBonded(address _owner) {
        require(petBonded[_owner] == 0, "Owner already has a bonded pet");
        _;
        require(bondedToOwner[_petId] == address(0), "Pet is already bonded to someone else"); // Added in relevant functions
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Set initial decay rates (scaled by 1000)
        baseDecayRates = DecayRates({
            hunger: 10, // 0.01 per sec
            mood: 5,    // 0.005 per sec
            energy: 8   // 0.008 per sec
        });

        // Set initial interaction cooldowns (in seconds)
        interactionCooldown[InteractionType.FEED] = 1 * 60; // 1 minute
        interactionCooldown[InteractionType.PLAY] = 5 * 60; // 5 minutes
        interactionCooldown[InteractionType.TRAIN] = 1 * 60 * 60; // 1 hour
        interactionCooldown[InteractionType.REST] = 30 * 60; // 30 minutes

        // Set initial essence harvest config
        essenceHarvestCooldown = 1 * 60 * 60; // 1 hour
        essenceHarvestAmount = 100;

        currentEpoch = 1;
        epochConditions[currentEpoch] = 100; // Default condition value

        _pause(); // Start paused until owner is ready
    }

    // --- Internal Helper Functions ---

    // Adds pet ID to owner's array (simple append, removal handled by transfer/burn)
    function _addPetToOwner(address _owner, uint256 _petId) internal {
        ownerPetIds[_owner].push(_petId);
    }

    // Removes pet ID from owner's array (simple linear search and swap-remove)
    function _removePetFromOwner(address _owner, uint256 _petId) internal {
        uint256[] storage petIds = ownerPetIds[_owner];
        for (uint256 i = 0; i < petIds.length; i++) {
            if (petIds[i] == _petId) {
                petIds[i] = petIds[petIds.length - 1];
                petIds.pop();
                return;
            }
        }
    }

    // Calculates stats after applying time decay
    function _calculateDecayedStats(uint256 _petId, uint256 _currentTime) internal view returns (PetStats memory) {
        PetStats memory stats = currentPetStats[_petId];
        uint256 lastUpdated = petStatsLastUpdatedTime[_petId];
        uint256 timeDelta = _currentTime - lastUpdated;

        // Apply decay (scaled arithmetic to avoid floating point)
        stats.hunger = Math.max(0, stats.hunger - uint16((uint256(baseDecayRates.hunger) * timeDelta) / 1000));
        stats.mood = Math.max(0, stats.mood - uint16((uint256(baseDecayRates.mood) * timeDelta) / 1000));
        stats.energy = Math.max(0, stats.energy - uint16((uint256(baseDecayRates.energy) * timeDelta) / 1000));

        // Strength and Intelligence do not decay naturally but can be affected by interactions

        return stats;
    }

    // Updates stored stats after calculation or action
    function _updatePetStats(uint256 _petId, PetStats memory _newStats) internal {
        currentPetStats[_petId] = _newStats;
        petStatsLastUpdatedTime[_petId] = block.timestamp;
        emit StatsUpdated(_petId, _newStats, block.timestamp);
    }

    // Applies interaction outcome based on VRF result
    function _applyInteractionOutcome(uint256 _petId, OutcomeType _outcomeType, uint256 _randomWord) internal {
        PetStats memory stats = _calculateDecayedStats(_petId, block.timestamp); // Get current stats

        // Apply outcome based on type and random word (simplified logic)
        if (_outcomeType == OutcomeType.STAT_BOOST) {
            uint16 boostAmount = uint16((_randomWord % 50) + 20); // Boost between 20 and 70
            // Apply boost to a random stat (excluding Energy)
            uint256 statToBoost = (_randomWord / 100) % 4; // 0: Hunger, 1: Mood, 2: Strength, 3: Intelligence
            if (statToBoost == 0) stats.hunger = uint16(Math.min(1000, stats.hunger + boostAmount));
            else if (statToBoost == 1) stats.mood = uint16(Math.min(1000, stats.mood + boostAmount));
            else if (statToBoost == 2) stats.strength += boostAmount; // Strength/Int can exceed 1000
            else stats.intelligence += boostAmount;

        } else if (_outcomeType == OutcomeType.ESSENCE_GAIN) {
            uint256 essenceGain = (_randomWord % 200) + 50; // Gain between 50 and 250
            essenceBalances[ownerOf(_petId)] += essenceGain;
            emit EssenceHarvested(ownerOf(_petId), essenceGain, essenceBalances[ownerOf(_petId)], block.timestamp); // Re-use event
        } else if (_outcomeType == OutcomeType.DECAY_HALT) {
            // In a real system, this would set a temporary flag or modifier on decay calculation
            // For this example, we'll simulate a temporary stat reset or boost instead of complex time tracking
             stats.hunger = uint16(Math.min(1000, stats.hunger + 100));
             stats.mood = uint16(Math.min(1000, stats.mood + 100));
             stats.energy = uint16(Math.min(1000, stats.energy + 100));
        } else if (_outcomeType == OutcomeType.MOOD_DRAIN) {
            uint16 drainAmount = uint16((_randomWord % 100) + 30); // Drain between 30 and 130
            stats.mood = Math.max(0, stats.mood - drainAmount);
        }
        // OutcomeType.NONE does nothing

        _updatePetStats(_petId, stats);
        emit InteractionOutcomeApplied(bytes32(0), _petId, _outcomeType, block.timestamp); // Use 0 hash if not tied to VRF hash
    }

    // Simulates determining an outcome type based on interaction hash and random word
    function _determineOutcomeType(bytes32 _interactionHash, uint256 _randomWord) internal view returns (OutcomeType) {
         // Simple pseudo-random outcome determination
         uint256 outcomeSelector = (_randomWord + uint256(_interactionHash)) % 100;

         if (outcomeSelector < 30) return OutcomeType.STAT_BOOST; // 30% chance
         if (outcomeSelector < 50) return OutcomeType.ESSENCE_GAIN; // 20% chance
         if (outcomeSelector < 60) return OutcomeType.DECAY_HALT; // 10% chance
         if (outcomeSelector < 70) return OutcomeType.MOOD_DRAIN; // 10% chance
         return OutcomeType.NONE; // 30% chance of no special outcome
    }


    // Internal function to handle state updates and checks for interactions
    function _performInteraction(uint256 _petId, InteractionType _type, uint256 _essenceCost) internal whenNotPaused onlyPetOwner(_petId) {
        require(_petId != 0, "Invalid pet ID");
        Pet storage pet = pets[_petId];
        require(block.timestamp >= pet.lastInteractionTime[_type] + interactionCooldown[_type], "Interaction on cooldown");
        require(essenceBalances[msg.sender] >= _essenceCost, "Insufficient Chrono Essence");

        // Calculate current stats before applying interaction effect
        PetStats memory currentStats = _calculateDecayedStats(_petId, block.timestamp);

        // Apply base effect of the interaction
        if (_type == InteractionType.FEED) {
            currentStats.hunger = uint16(Math.min(1000, currentStats.hunger + 200)); // Restore Hunger
            currentStats.mood = uint16(Math.min(1000, currentStats.mood + 50)); // Small mood boost
        } else if (_type == InteractionType.PLAY) {
            currentStats.mood = uint16(Math.min(1000, currentStats.mood + 300)); // Restore Mood
            currentStats.energy = uint16(Math.max(0, currentStats.energy - 50)); // Consumes energy
        } else if (_type == InteractionType.TRAIN) {
             // Training effect might be state-dependent or have random elements
            currentStats.strength += 10; // Base Strength gain
            currentStats.intelligence += 5; // Base Intelligence gain
            currentStats.energy = uint16(Math.max(0, currentStats.energy - 100)); // Consumes more energy
        } else if (_type == InteractionType.REST) {
            currentStats.energy = uint16(Math.min(1000, currentStats.energy + 400)); // Restore Energy
            currentStats.hunger = uint16(Math.max(0, currentStats.hunger - 30)); // Gets slightly hungry
        }

        // Deduct essence
        essenceBalances[msg.sender] -= _essenceCost;
        emit EssenceSpent(msg.sender, _essenceCost, essenceBalances[msg.sender], string(abi.encodePacked("InteractionType:", uint252(_type))), block.timestamp);

        // Update pet state
        pet.lastInteractionTime[_type] = block.timestamp;
        _updatePetStats(_petId, currentStats);

        // Potentially trigger VRF for a random outcome after interaction (simplified)
        // For demonstration, not every interaction triggers VRF, and the trigger logic is simple.
        // In a real game, this might depend on crit chance, specific items used, etc.
        if (_type == InteractionType.PLAY || _type == InteractionType.TRAIN) {
             bytes32 interactionHash = keccak256(abi.encodePacked(_petId, block.timestamp, _type, block.difficulty, block.coinbase)); // Unique identifier
             requestRandomnessForInteraction(_petId, 0, interactionHash); // Request VRF for this pet's interaction
        }
    }


    // --- Public/External Functions ---

    // --- Custom Core Pet Management ---

    // 1. Mint a new pet
    function mintPet(PetType _petType) external payable whenNotPaused {
        // Add minting cost logic here if needed: require(msg.value >= mintCost, "Insufficient mint cost");
        _petCount.increment();
        uint256 newItemId = _petCount.current();

        PetStats memory initialStats;
        // Initial stats can vary by pet type
        if (_petType == PetType.FIERY) {
            initialStats = PetStats(uint16(800), uint16(500), uint16(600), uint16(50), uint16(30));
        } else if (_petType == PetType.AQUATIC) {
            initialStats = PetStats(uint16(600), uint16(800), uint16(700), uint16(30), uint16(50));
        } else if (_petType == PetType.EARTHY) {
            initialStats = PetStats(uint16(700), uint16(600), uint16(800), uint16(60), uint16(20));
        } else if (_petType == PetType.AIRY) {
             initialStats = PetStats(uint16(500), uint16(700), uint16(600), uint16(20), uint16(60));
        } else {
            revert("Invalid pet type");
        }

        pets[newItemId] = Pet({
            id: newItemId,
            owner: msg.sender, // Stored here for easy lookup
            creationTime: block.timestamp,
            petType: _petType,
            evolutionStage: EvolutionStage.EGG, // Start as Egg
            baseStats: initialStats,
            lastInteractionTime: new mapping(InteractionType => uint256)() // Initialize mapping
        });

        currentPetStats[newItemId] = initialStats; // Set initial dynamic stats
        petStatsLastUpdatedTime[newItemId] = block.timestamp;

        _safeMint(msg.sender, newItemId); // Standard ERC721 mint
        _addPetToOwner(msg.sender, newItemId); // Track owner's pet IDs

        emit PetMinted(newItemId, msg.sender, _petType, block.timestamp);
    }

    // Override ERC721 transfer to check bonding status and update ownerPetIds
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);

         // Prevent transfer if bonded
         require(bondedToOwner[tokenId] == address(0) || from == address(0), "Bonded pets cannot be transferred");

         // Update ownerPetIds mapping
         if (from != address(0)) {
             _removePetFromOwner(from, tokenId);
         }
         if (to != address(0)) {
             _addPetToOwner(to, tokenId);
         }

         emit PetTransferred(tokenId, from, to, block.timestamp);
    }

    // 2. Burn a pet
    function burnPet(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
        require(bondedToOwner[_petId] == address(0), "Bonded pets cannot be burned"); // Cannot burn if bonded
        address petOwner = ownerOf(_petId);

        // Clean up state
        delete currentPetStats[_petId];
        delete petStatsLastUpdatedTime[_petId];
        // No need to delete pets[_petId] fully due to struct mapping behavior, but mark as non-existent
        // The _beforeTokenTransfer logic handles ownerPetIds removal and ERC721 burn
        delete pets[_petId]; // Mark as deleted

        _burn(_petId);

        emit PetBurned(_petId, petOwner, block.timestamp);
    }

    // 3. Get all stored details of a pet (excluding dynamic stats)
    function getPetDetails(uint256 _petId) external view whenPetExists(_petId) returns (Pet memory) {
        Pet storage pet = pets[_petId];
        // Note: This returns the *stored* Pet struct, not including calculated dynamic stats.
        // Use getPetStats for current stats.
        return pet;
    }

    // 4. Get IDs of all pets owned by an address
    function getUserPets(address _owner) external view returns (uint256[] memory) {
        return ownerPetIds[_owner];
    }

    // --- Dynamic State & Interaction ---

    // 5. Get current stats including decay
    function getPetStats(uint256 _petId) external view whenPetExists(_petId) returns (PetStats memory) {
        return _calculateDecayedStats(_petId, block.timestamp);
    }

    // 6. Feed a pet
    function feedPet(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
         uint256 essenceCost = 10; // Example cost
        _performInteraction(_petId, InteractionType.FEED, essenceCost);
    }

    // 7. Play with a pet
    function playWithPet(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
         uint256 essenceCost = 20; // Example cost
        _performInteraction(_petId, InteractionType.PLAY, essenceCost);
    }

    // 8. Train a pet
    function trainPet(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
         uint256 essenceCost = 50; // Example cost
        _performInteraction(_petId, InteractionType.TRAIN, essenceCost);
    }

    // 9. Rest a pet
    function restPet(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
         uint256 essenceCost = 15; // Example cost
        _performInteraction(_petId, InteractionType.REST, essenceCost);
    }

    // 10. Pure function to calculate decayed stats (exposed as public view)
    function calculateCurrentStats(uint256 _petId) public view whenPetExists(_petId) returns (PetStats memory) {
        return _calculateDecayedStats(_petId, block.timestamp);
    }

    // 11. Get current evolution stage
    function getPetEvolutionStage(uint256 _petId) external view whenPetExists(_petId) returns (EvolutionStage) {
        PetStats memory stats = calculateCurrentStats(_petId);
        // Evolution logic (example: based on average stat and epoch)
        uint256 averageStat = (uint256(stats.hunger) + stats.mood + stats.energy + stats.strength + stats.intelligence) / 5;
        uint256 currentConditions = epochConditions[currentEpoch]; // Factor in epoch conditions

        if (pets[_petId].evolutionStage == EvolutionStage.EGG && averageStat > 500 && currentConditions > 150) {
            return EvolutionStage.JUVENILE;
        } else if (pets[_petId].evolutionStage == EvolutionStage.JUVENILE && averageStat > 700 && stats.strength > 500 && stats.intelligence > 500 && currentConditions > 200) {
            return EvolutionStage.ADULT;
        } else if (pets[_petId].evolutionStage == EvolutionStage.ADULT && averageStat > 900 && stats.strength > 800 && stats.intelligence > 800 && currentConditions > 250) {
             return EvolutionStage.ELDER;
        }
        return pets[_petId].evolutionStage; // Return current stage if not eligible for next
    }


    // 12. Trigger evolution check and apply
    function triggerEvolution(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) {
        Pet storage pet = pets[_petId];
        EvolutionStage potentialStage = getPetEvolutionStage(_petId);

        if (potentialStage > pet.evolutionStage) {
            pet.evolutionStage = potentialStage;
            emit EvolutionTriggered(_petId, pet.evolutionStage, block.timestamp);
        }
    }

    // 13. Check eligibility for evolution
    function checkEvolutionEligibility(uint256 _petId) external view whenPetExists(_petId) returns (bool) {
         Pet storage pet = pets[_petId];
         EvolutionStage potentialStage = getPetEvolutionStage(_petId);
         return potentialStage > pet.evolutionStage;
    }

    // 14. Get pet interaction history (Simulated/Placeholder)
    function getPetInteractionHistory(uint256 _petId) external view whenPetExists(_petId) returns (bytes32[] memory) {
        // In a real system, this would retrieve structured logs or stored history
        // This is a placeholder returning simulated outcome hashes linked during VRF fulfillment
        return petInteractionOutcomes[_petId];
    }

    // --- Resource (Chrono Essence) Management ---

    // 15. Harvest Chrono Essence
    function harvestEssence() external whenNotPaused {
        require(block.timestamp >= lastEssenceHarvestTime[msg.sender] + essenceHarvestCooldown, "Essence harvest on cooldown");
        essenceBalances[msg.sender] += essenceHarvestAmount;
        lastEssenceHarvestTime[msg.sender] = block.timestamp;
        emit EssenceHarvested(msg.sender, essenceHarvestAmount, essenceBalances[msg.sender], block.timestamp);
    }

    // 16. Get Chrono Essence balance
    function getEssenceBalance(address _owner) external view returns (uint256) {
        return essenceBalances[_owner];
    }

    // --- Epoch & Global State ---

    // 17. Get current epoch
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    // 18. Get epoch conditions
    function getEpochConditions(uint256 _epoch) external view returns (uint256) {
        return epochConditions[_epoch];
    }

    // --- Advanced Concepts ---

    // 19. Bond a pet to the owner (makes it non-transferable)
    function bondWithPet(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) whenNotBonded(msg.sender) {
        require(bondedToOwner[_petId] == address(0), "Pet is already bonded to someone else");
        petBonded[msg.sender] = _petId;
        bondedToOwner[_petId] = msg.sender;
        emit PetBonded(msg.sender, _petId, block.timestamp);
    }

    // 20. Unbond a pet
    function unbondPet(uint256 _petId) external whenNotPaused onlyPetOwner(_petId) whenBonded(msg.sender) {
        require(petBonded[msg.sender] == _petId, "Pet is not bonded to caller");
        delete petBonded[msg.sender];
        delete bondedToOwner[_petId];
        emit PetUnbonded(msg.sender, _petId, block.timestamp);
    }

    // 21. Get bonded pet ID
    function getBondedPet(address _owner) external view returns (uint256) {
        return petBonded[_owner];
    }

    // 22. Simulate interaction between two pets
    function interactWithAnotherPet(uint256 _petId1, uint256 _petId2) external whenNotPaused {
        require(_exists(_petId1), "Pet 1 does not exist");
        require(_exists(_petId2), "Pet 2 does not exist");
        require(ownerOf(_petId1) == msg.sender || _isApprovedForAll(msg.sender, ownerOf(_petId1)), "Not owner or approved for Pet 1");
         // Decide if owner of Pet 2 needs to be involved or if it's just based on Pet 2's state
         // For this example, let's assume the caller can use their pet to interact *with* another pet's state
         // require(ownerOf(_petId2) == msg.sender || _isApprovedForAll(msg.sender, ownerOf(_petId2)), "Not owner or approved for Pet 2"); // Uncomment if symmetric permission needed

        uint256 essenceCost = 100; // Higher cost for inter-pet interaction
        require(essenceBalances[msg.sender] >= essenceCost, "Insufficient Chrono Essence");

        // Deduct essence
        essenceBalances[msg.sender] -= essenceCost;
        emit EssenceSpent(msg.sender, essenceCost, essenceBalances[msg.sender], "Inter-Pet Interaction", block.timestamp);

        // Simulate a complex interaction outcome based on stats and potentially epoch conditions
        // This outcome will be determined by a simulated VRF request
        bytes32 interactionHash = keccak256(abi.encodePacked(_petId1, _petId2, block.timestamp, block.difficulty, block.coinbase)); // Unique identifier

        // Request randomness for this specific interaction
        requestRandomnessForInteraction(_petId1, _petId2, interactionHash);

        emit InteractionInitiated(interactionHash, _petId1, _petId2, block.timestamp);

        // The actual outcome (stat changes, etc.) happens in fulfillRandomness later
    }

    // 23. Simulate requesting randomness (called internally by interaction logic)
    function requestRandomnessForInteraction(uint256 _petId1, uint256 _petId2, bytes32 _interactionHash) public { // Changed to public for simpler simulation calls if needed
         // In a real Chainlink VRF integration, this would call the VRF Coordinator
         // and store the request ID returned by the coordinator.
         // Here, we simulate the request ID using the interaction hash.
         bytes32 requestId = _interactionHash; // Simplified simulation

         vrfRequests[requestId] = VRFRequest({
             petId1: _petId1,
             petId2: _petId2,
             interactionHash: _interactionHash,
             requester: msg.sender,
             requestTime: block.timestamp,
             fulfilled: false
         });
         pendingVRFRequests.push(requestId); // Track pending requests

         emit VRFRequested(requestId, block.timestamp);
    }

     // 24. Simulate fulfilling randomness (called by owner or simulated oracle)
     // In a real VRF integration (e.g., Chainlink VRF v2), this would be the `fulfillRandomWords` callback
     // and it would only be callable by the VRF Coordinator address.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomWord) external onlyOwner { // Only owner can fulfill in this simulation
        VRFRequest storage req = vrfRequests[_requestId];
        require(!req.fulfilled, "VRF request already fulfilled");
        // require(req.requester != address(0), "Invalid VRF request ID"); // Check request exists

        req.fulfilled = true;
        vrfResults[_requestId] = _randomWord;

        emit VRFFulfilled(_requestId, _randomWord, block.timestamp);

        // Now apply the outcome based on the random word
        // Determine outcome type (simplified example)
        OutcomeType outcomeType1 = _determineOutcomeType(req.interactionHash, _randomWord);
        _applyInteractionOutcome(req.petId1, outcomeType1, _randomWord);
        petInteractionOutcomes[req.petId1].push(_requestId); // Store reference to outcome

        if (req.petId2 != 0) {
             // Apply potential outcome to the second pet as well
            OutcomeType outcomeType2 = _determineOutcomeType(req.interactionHash, _randomWord / 2); // Use a slightly different random derivation
            _applyInteractionOutcome(req.petId2, outcomeType2, _randomWord);
            petInteractionOutcomes[req.petId2].push(_requestId); // Store reference to outcome
        }

        // Remove from pending list (optional, for tracking)
        // In a real system, you might just rely on the 'fulfilled' flag.
        // This requires iterating the pending list, which is gas-intensive.
        // For simplicity, we'll skip removing from the array here.
    }

    // 25. Batch feed pets
    function batchFeedPets(uint256[] memory _petIds) external whenNotPaused {
        uint256 essenceCostPerPet = 10; // Same cost per pet as single feed
        uint256 totalEssenceCost = essenceCostPerPet * _petIds.length;
        require(essenceBalances[msg.sender] >= totalEssenceCost, "Insufficient Chrono Essence for batch");

        // Deduct total essence once
        essenceBalances[msg.sender] -= totalEssenceCost;
        emit EssenceSpent(msg.sender, totalEssenceCost, essenceBalances[msg.sender], "Batch Feed", block.timestamp);

        for (uint256 i = 0; i < _petIds.length; i++) {
            uint256 petId = _petIds[i];
            // Need to replicate checks from _performInteraction, but adjust cooldown check per pet
             require(_exists(petId), string(abi.encodePacked("Pet does not exist: ", Strings.toString(petId))));
             require(_isApprovedOrOwner(msg.sender, petId), string(abi.encodePacked("Not owner or approved for pet: ", Strings.toString(petId))));
             Pet storage pet = pets[petId];
             require(block.timestamp >= pet.lastInteractionTime[InteractionType.FEED] + interactionCooldown[InteractionType.FEED], string(abi.encodePacked("Pet on cooldown: ", Strings.toString(petId))));

             // Apply base effect
             PetStats memory currentStats = _calculateDecayedStats(petId, block.timestamp);
             currentStats.hunger = uint16(Math.min(1000, currentStats.hunger + 200)); // Restore Hunger
             currentStats.mood = uint16(Math.min(1000, currentStats.mood + 50)); // Small mood boost

             // Update pet state individually
             pet.lastInteractionTime[InteractionType.FEED] = block.timestamp;
             _updatePetStats(petId, currentStats);

            // Skipping VRF request for batch actions for simplicity, or would need a batch VRF system
        }
    }

    // 26. Batch play with pets
     function batchPlayWithPets(uint256[] memory _petIds) external whenNotPaused {
        uint256 essenceCostPerPet = 20; // Same cost per pet as single play
        uint256 totalEssenceCost = essenceCostPerPet * _petIds.length;
        require(essenceBalances[msg.sender] >= totalEssenceCost, "Insufficient Chrono Essence for batch");

        essenceBalances[msg.sender] -= totalEssenceCost;
        emit EssenceSpent(msg.sender, totalEssenceCost, essenceBalances[msg.sender], "Batch Play", block.timestamp);

        for (uint256 i = 0; i < _petIds.length; i++) {
            uint256 petId = _petIds[i];
             require(_exists(petId), string(abi.encodePacked("Pet does not exist: ", Strings.toString(petId))));
             require(_isApprovedOrOwner(msg.sender, petId), string(abi.encodePacked("Not owner or approved for pet: ", Strings.toString(petId))));
             Pet storage pet = pets[petId];
             require(block.timestamp >= pet.lastInteractionTime[InteractionType.PLAY] + interactionCooldown[InteractionType.PLAY], string(abi.encodePacked("Pet on cooldown: ", Strings.toString(petId))));

             PetStats memory currentStats = _calculateDecayedStats(petId, block.timestamp);
             currentStats.mood = uint16(Math.min(1000, currentStats.mood + 300));
             currentStats.energy = uint16(Math.max(0, currentStats.energy - 50));

             pet.lastInteractionTime[InteractionType.PLAY] = block.timestamp;
             _updatePetStats(petId, currentStats);
             // VRF simulation could be added here per pet, but batching VRF requests is complex.
        }
    }

     // 27. Batch train pets
     function batchTrainPets(uint256[] memory _petIds) external whenNotPaused {
        uint256 essenceCostPerPet = 50; // Same cost per pet as single train
        uint256 totalEssenceCost = essenceCostPerPet * _petIds.length;
        require(essenceBalances[msg.sender] >= totalEssenceCost, "Insufficient Chrono Essence for batch");

        essenceBalances[msg.sender] -= totalEssenceCost;
        emit EssenceSpent(msg.sender, totalEssenceCost, essenceBalances[msg.sender], "Batch Train", block.timestamp);

        for (uint256 i = 0; i < _petIds.length; i++) {
            uint256 petId = _petIds[i];
             require(_exists(petId), string(abi.encodePacked("Pet does not exist: ", Strings.toString(petId))));
             require(_isApprovedOrOwner(msg.sender, petId), string(abi.encodePacked("Not owner or approved for pet: ", Strings.toString(petId))));
             Pet storage pet = pets[petId];
             require(block.timestamp >= pet.lastInteractionTime[InteractionType.TRAIN] + interactionCooldown[InteractionType.TRAIN], string(abi.encodePacked("Pet on cooldown: ", Strings.toString(petId))));

             PetStats memory currentStats = _calculateDecayedStats(petId, block.timestamp);
             currentStats.strength += 10;
             currentStats.intelligence += 5;
             currentStats.energy = uint16(Math.max(0, currentStats.energy - 100));

             pet.lastInteractionTime[InteractionType.TRAIN] = block.timestamp;
             _updatePetStats(petId, currentStats);
        }
    }

    // 28. Batch rest pets
    function batchRestPets(uint256[] memory _petIds) external whenNotPaused {
        uint256 essenceCostPerPet = 15; // Same cost per pet as single rest
        uint256 totalEssenceCost = essenceCostPerPet * _petIds.length;
        require(essenceBalances[msg.sender] >= totalEssenceCost, "Insufficient Chrono Essence for batch");

        essenceBalances[msg.sender] -= totalEssenceCost;
        emit EssenceSpent(msg.sender, totalEssenceCost, essenceBalances[msg.sender], "Batch Rest", block.timestamp);

        for (uint256 i = 0; i < _petIds.length; i++) {
            uint256 petId = _petIds[i];
             require(_exists(petId), string(abi.encodePacked("Pet does not exist: ", Strings.toString(petId))));
             require(_isApprovedOrOwner(msg.sender, petId), string(abi.encodePacked("Not owner or approved for pet: ", Strings.toString(petId))));
             Pet storage pet = pets[petId];
             require(block.timestamp >= pet.lastInteractionTime[InteractionType.REST] + interactionCooldown[InteractionType.REST], string(abi.encodePacked("Pet on cooldown: ", Strings.toString(petId))));

             PetStats memory currentStats = _calculateDecayedStats(petId, block.timestamp);
             currentStats.energy = uint16(Math.min(1000, currentStats.energy + 400));
             currentStats.hunger = uint16(Math.max(0, currentStats.hunger - 30));

             pet.lastInteractionTime[InteractionType.REST] = block.timestamp;
             _updatePetStats(petId, currentStats);
        }
    }


    // --- Owner/Admin Functions ---

    // 29. Set base decay rates
    function setBaseDecayRates(uint16 _hunger, uint16 _mood, uint16 _energy) external onlyOwner {
        baseDecayRates = DecayRates({
            hunger: _hunger,
            mood: _mood,
            energy: _energy
        });
        emit DecayRatesUpdated(_hunger, _mood, _energy, block.timestamp);
    }

    // 30. Set interaction cooldowns
    function setInteractionCooldown(InteractionType _type, uint256 _cooldown) external onlyOwner {
        interactionCooldown[_type] = _cooldown;
        emit CooldownUpdated(_type, _cooldown, block.timestamp);
    }

    // 31. Set essence harvest config
    function setEssenceHarvestConfig(uint256 _cooldown, uint256 _amount) external onlyOwner {
        essenceHarvestCooldown = _cooldown;
        essenceHarvestAmount = _amount;
        emit EssenceConfigUpdated(_cooldown, _amount, block.timestamp);
    }

    // 32. Set simulated epoch conditions
    function setEpochConditions(uint256 _epoch, uint256 _conditionValue) external onlyOwner {
         // Ensure epoch is current or future
         require(_epoch >= currentEpoch, "Cannot set conditions for past epochs");
         epochConditions[_epoch] = _conditionValue;
         emit EpochConditionsUpdated(_epoch, _conditionValue, block.timestamp);
    }

    // 33. Advance global epoch
    function advanceEpoch() external onlyOwner {
        currentEpoch++;
         // Set a default condition value if none is explicitly set for the new epoch
         if (epochConditions[currentEpoch] == 0) {
              epochConditions[currentEpoch] = epochConditions[currentEpoch - 1]; // Inherit from previous or set a base
         }
        emit EpochAdvanced(currentEpoch, epochConditions[currentEpoch], block.timestamp);
    }

    // 34. Withdraw collected funds
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(owner(), balance, block.timestamp);
    }

    // 35. Pause the contract (from Pausable)
    function pause() external onlyOwner {
        _pause();
    }

    // 36. Unpause the contract (from Pausable)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override _update to incorporate pausing logic
    function _update(address to, uint256 tokenId, address auth) internal override whenNotPaused returns (address) {
        return super._update(to, tokenId, auth);
    }

    // Override _burn to incorporate pausing logic
    function _burn(uint256 tokenId) internal override whenNotPaused {
        super._burn(tokenId);
    }

    // Fallback function to receive Ether
    receive() external payable {}
    fallback() external payable {}
}
```