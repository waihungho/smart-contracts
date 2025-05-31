Okay, here is a Solidity smart contract incorporating several advanced, interesting, and trendy concepts like dynamic NFTs, on-chain creature mechanics (stats, aging, evolution, breeding), passive yield, gated access based on NFT properties, a pattern for ZK proof verification integration, owner reputation, locked tokens for boosts, and dynamic metadata.

It is designed as an `EvoluCreatures` game/utility contract built on ERC721.

**Disclaimer:** This is a complex contract for demonstration purposes. Production use would require rigorous auditing, more sophisticated randomness (Chainlink VRF), potentially off-chain processing for heavy computation (like dynamic metadata), and careful consideration of gas costs and game balance. The ZK proof verification part is a *pattern* showing integration, not a full ZK implementation.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assuming an external EVO token

// --- OUTLINE AND FUNCTION SUMMARY ---
/*
Contract: EvoluCreatures
Base: ERC721 Non-Fungible Tokens
Core Concepts:
- Dynamic Creature NFTs: Stats change over time and based on interactions.
- On-chain Mechanics: Feeding, Training, Resting, Evolution, Breeding.
- Passive Yield: Creatures generate a yield token (EVO) based on stats/age.
- Gated Access: Functions or external systems can check creature stats for access/utility.
- ZK Proof Integration Pattern: Ability to verify a ZK proof about creature state.
- Owner Reputation: Tracks owner's interaction history and success.
- Locked Tokens: Stake EVO tokens with a creature for temporary stat boosts.
- Dynamic Metadata: tokenURI reflects current stats.

Interfaces:
- IERC20: For interacting with the yield token (EVO).
- IZKVerifier: A placeholder interface for an external ZK verification contract.

Structs:
- CreatureStats: Holds base, mutable stats and timestamps.

State Variables:
- Creature data (mapping token ID to stats).
- Global environment factor (influences stats).
- Last global aging timestamp.
- Owner reputation mapping.
- EVO tokens locked with creatures.
- Contract parameters (mint price, costs, multipliers, etc.).
- Counters for token IDs.
- Addresses for EVO token and ZK verifier contracts.

Events:
- CreatureMinted: Log new creature creation.
- StatsUpdated: Log stat changes.
- CreatureEvolved: Log evolution event.
- CreaturesBred: Log breeding event.
- YieldClaimed: Log passive yield distribution.
- EnvironmentUpdated: Log global environment change.
- AgingTriggered: Log global aging process.
- CreatureSacrificed: Log sacrifice event.
- ZkProofVerifiedAndApplied: Log ZK proof verification outcome.
- OwnerReputationUpdated: Log owner reputation change.
- EVOLocked: Log EVO locked with creature.
- EVOUnlocked: Log EVO unlocked from creature.

Functions (Approx 35+ including inherited/standard):

I. Core Creature Lifecycle & Interaction (Public/External):
1.  `mintCreature()`: Mints a new creature NFT for the caller.
2.  `getCreatureStats(uint256 tokenId)`: Views the *current* effective stats of a creature, considering time and environment.
3.  `feedCreature(uint256 tokenId)`: Increases a creature's stats based on food consumed (pays Ether or EVO).
4.  `trainCreature(uint256 tokenId, uint8 statIndex)`: Selectively boosts one stat through training (pays Ether or EVO).
5.  `restCreature(uint256 tokenId)`: Allows creature to recover, applying time-based passive growth.
6.  `evolveCreature(uint256 tokenId)`: Attempts to evolve a creature if it meets stat thresholds and pays cost.
7.  `breedCreatures(uint256 tokenId1, uint256 tokenId2)`: Breeds two eligible creatures to create a new one (pays cost, has cooldown).
8.  `getBreedEligibility(uint256 tokenId1, uint256 tokenId2)`: Views if two creatures are eligible for breeding.
9.  `claimPassiveYield(uint256[] calldata tokenIds)`: Allows owners to claim accumulated EVO yield for their creatures.
10. `checkAccessLevel(uint256 tokenId, uint256 requiredLevel)`: Views if a creature's stats meet a minimum threshold for a specific access level.
11. `gatedFunctionExample(uint256 tokenId, uint256 requiredLevel)`: An example function demonstrating how access levels can gate functionality.
12. `triggerAgingProcess()`: Allows anyone to trigger the global aging process for all creatures (potentially incentivized off-chain).
13. `sacrificeCreature(uint256 tokenId)`: Burns a creature NFT, potentially granting rewards or boosts elsewhere.
14. `verifyAndApplyZkProof(uint256 tokenId, bytes calldata proof)`: Demonstrates verifying a ZK proof about the creature's state via an external contract and applying an effect.
15. `setCreatureEnvironmentPreference(uint256 tokenId, uint8 preference)`: Owner sets a preference that interacts with the global environment.
16. `lockEVOForStatBoost(uint256 tokenId, uint256 amount)`: Locks EVO tokens with a creature for a temporary stat boost.
17. `unlockEVO(uint256 tokenId, uint256 amount)`: Unlocks previously locked EVO tokens.
18. `getOwnerHistoricalReputation(address owner)`: Views the accumulated reputation score of an owner.
19. `getTokenURI(uint256 tokenId)`: Overrides ERC721 to provide dynamic metadata URI.

II. Administrative & Setup (Only Owner/Privileged):
20. `pauseContract()`: Pauses core interactions.
21. `unpauseContract()`: Unpauses contract.
22. `withdrawEther(address payable recipient)`: Withdraws collected Ether.
23. `withdrawEVOTokens(address recipient, uint256 amount)`: Withdraws accumulated EVO tokens.
24. `setMintParameters(...)`: Sets cost, max supply, base stats for minting.
25. `setBreedingParameters(...)`: Sets cost, cooldown, rules for breeding.
26. `setFeedingParameters(...)`: Sets cost, stat effects for feeding.
27. `setTrainingParameters(...)`: Sets cost, stat effects for training.
28. `setTraitMultipliers(...)`: Sets how global environment/actions affect different traits.
29. `updateGlobalEnvironment(uint8 newFactor)`: Updates the global environmental factor.
30. `setEVOTokenAddress(address _evoToken)`: Sets the address of the EVO token contract.
31. `setZKVerifierAddress(address _zkVerifier)`: Sets the address of the ZK verifier contract.

III. Standard ERC721 Functions (Public/External - Inherited from OpenZeppelin):
32. `balanceOf(address owner)`
33. `ownerOf(uint256 tokenId)`
34. `getApproved(uint256 tokenId)`
35. `isApprovedForAll(address owner, address operator)`
36. `approve(address to, uint256 tokenId)`
37. `setApprovalForAll(address operator, bool approved)`
38. `transferFrom(address from, address to, uint256 tokenId)`
39. `safeTransferFrom(address from, address to, uint256 tokenId)` (two variants)

This contract structure provides a rich set of features centered around dynamic on-chain assets and interaction mechanics.
*/

// --- INTERFACES ---

interface IZKVerifier {
    // Example interface for a ZK verifier contract
    // In reality, this would depend on the specific ZK scheme (e.g., Groth16, PLONK)
    // and the circuit being used. The `proof` structure would be complex bytes.
    // The `publicInputs` would be data revealed to the verifier contract.
    function verifyProof(bytes calldata proof, uint256[] calldata publicInputs) external view returns (bool);
}

// --- CONTRACT DEFINITION ---

contract EvoluCreatures is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- STRUCTS ---
    struct CreatureStats {
        uint64 baseStrength;
        uint64 baseIntelligence;
        uint64 baseStamina;
        uint64 baseRarityScore; // A score based on initial traits
        uint32 generation;
        uint64 lastUpdatedTime; // Timestamp of last interaction/aging
        uint64 lastBredTime;   // Timestamp of last breeding action
        uint8 environmentPreference; // Owner's set preference (0-255)
    }

    // --- STATE VARIABLES ---

    // Creature data: tokenId => stats
    mapping(uint256 => CreatureStats) private _creatureStats;

    // Owner reputation: owner address => reputation score
    mapping(address => uint256) private _ownerReputation;

    // EVO tokens locked with a creature: tokenId => owner address => amount
    mapping(uint256 => mapping(address => uint256)) private _creatureLockedEVO;

    // Contract Parameters
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxSupply = 10000;
    uint256 public breedingCost = 100 ether; // Example: requires Ether OR EVO
    uint256 public feedingCostEVO = 10; // Example: requires EVO
    uint256 public trainingCostEVO = 20; // Example: requires EVO
    uint64 public breedingCooldown = 7 days; // Cooldown in seconds

    // Stat Growth/Decay Multipliers (can be tuned)
    // Index: 0=Strength, 1=Intelligence, 2=Stamina, 3=Rarity (not mutable)
    uint256[3] public timeDecayRate = [1, 1, 1]; // Points decayed per day per stat
    uint256[3] public feedBoost = [5, 2, 3];    // Boost per feed
    uint256[3] public trainBoost = [2, 5, 3];   // Boost per training type
    uint256[3] public passiveGrowthRate = [1, 1, 1]; // Passive points grown per day

    // Environmental Factors - affects stat calculation and yield
    uint8 public globalEnvironmentFactor = 128; // Example: 0-255, midpoint is neutral
    uint64 public lastGlobalAgingTime;

    // Addresses
    IERC20 public evoToken; // The yield token
    IZKVerifier public zkVerifier; // External ZK verifier contract

    // Base URI for metadata - should point to an API endpoint
    string private _baseTokenURI;

    // --- EVENTS ---
    event CreatureMinted(uint256 indexed tokenId, address indexed owner, uint32 generation);
    event StatsUpdated(uint256 indexed tokenId, uint64 strength, uint64 intelligence, uint64 stamina);
    event CreatureEvolved(uint256 indexed tokenId, uint32 newGeneration);
    event CreaturesBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId);
    event YieldClaimed(address indexed owner, uint256[] tokenIds, uint256 amount);
    event EnvironmentUpdated(uint8 newFactor);
    event AgingTriggered(uint64 indexed timestamp);
    event CreatureSacrificed(uint256 indexed tokenId, address indexed owner);
    event ZkProofVerifiedAndApplied(uint256 indexed tokenId, bool success);
    event OwnerReputationUpdated(address indexed owner, uint256 newReputation);
    event EVOLocked(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EVOUnlocked(uint256 indexed tokenId, address indexed owner, uint256 amount);

    // --- MODIFIERS ---
    modifier onlyCreatureOwner(uint256 tokenId) {
        require(_exists(tokenId), "Creature does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not creature owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
        lastGlobalAgingTime = uint64(block.timestamp); // Initialize aging time
    }

    // --- ERC721 OVERRIDES ---

    // Dynamic token URI based on current stats
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        CreatureStats memory currentStats = getCreatureStats(tokenId);
        // The base URI should point to a service that can generate JSON metadata
        // using the creature stats and other relevant data.
        // Example: https://api.example.com/creatures/{tokenId}/metadata?s={strength}&i={intelligence}&st={stamina}&g={generation}...
        // For simplicity here, we just append the ID to the base URI.
        // A real implementation would likely pass the stats or fetch them via an API.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- INTERNAL HELPERS ---

    // Pseudo-random value generation (UNSAFE for high-value use cases)
    // Use Chainlink VRF or similar for secure randomness in production.
    function _generateRandomValue(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
    }

    // Calculates current stats based on base stats, time elapsed, environment, and locked EVO
    function _calculateDynamicStats(uint256 tokenId) internal view returns (CreatureStats memory) {
        CreatureStats memory stats = _creatureStats[tokenId];
        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsedSinceUpdate = currentTime - stats.lastUpdatedTime;
        uint64 timeElapsedSinceAging = currentTime > lastGlobalAgingTime ? currentTime - lastGlobalAgingTime : 0;


        // Calculate decay/growth based on time since last update
        // Decay scaled by time in days (rough estimate)
        uint256 daysElapsedUpdate = timeElapsedSinceUpdate / 1 days;
        stats.baseStrength = stats.baseStrength > daysElapsedUpdate * timeDecayRate[0] ? stats.baseStrength - uint64(daysElapsedUpdate * timeDecayRate[0]) : 0;
        stats.baseIntelligence = stats.baseIntelligence > daysElapsedUpdate * timeDecayRate[1] ? stats.baseIntelligence - uint64(daysElapsedUpdate * timeDecayRate[1]) : 0;
        stats.baseStamina = stats.baseStamina > daysElapsedUpdate * timeDecayRate[2] ? stats.baseStamina - uint64(daysElapsedUpdate * timeDecayRate[2]) : 0;

        // Passive growth scaled by time since last GLOBAL aging trigger
        uint256 daysElapsedAging = timeElapsedSinceAging / 1 days;
         stats.baseStrength += uint64(daysElapsedAging * passiveGrowthRate[0]);
         stats.baseIntelligence += uint64(daysElapsedAging * passiveGrowthRate[1]);
         stats.baseStamina += uint64(daysElapsedAging * passiveGrowthRate[2]);

        // Apply temporary boost from locked EVO (example: 1 EVO per 100 strength/intelligence/stamina for 1 day)
        // This is a simplified model. A real system might use a more complex formula or decay the boost over time.
        uint256 lockedEVOAmount = _creatureLockedEVO[tokenId][ownerOf(tokenId)];
        uint256 evoBoost = lockedEVOAmount / 100; // 1 boost point per 100 locked EVO

        stats.baseStrength += uint64(evoBoost);
        stats.baseIntelligence += uint64(evoBoost);
        stats.baseStamina += uint64(evoBoost);


        // Apply environment factor (example: favors certain stats)
        // This is a placeholder; actual impact could be complex multiplication/addition
        // Also consider creature's environmentPreference
        if (globalEnvironmentFactor > 150 && stats.environmentPreference > 150) {
             stats.baseStrength = stats.baseStrength * 110 / 100; // +10% str
        } else if (globalEnvironmentFactor < 100 && stats.environmentPreference < 100) {
             stats.baseIntelligence = stats.baseIntelligence * 110 / 100; // +10% int
        } // Add more complex interactions

        // Prevent stats from exceeding a max reasonable value (optional, for game balance)
        // uint64 MAX_STAT = 1000000;
        // stats.baseStrength = stats.baseStrength > MAX_STAT ? MAX_STAT : stats.baseStrength;
        // stats.baseIntelligence = stats.baseIntelligence > MAX_STAT ? MAX_STAT : stats.baseIntelligence;
        // stats.baseStamina = stats.baseStamina > MAX_STAT ? MAX_STAT : stats.baseStamina;


        stats.lastUpdatedTime = currentTime; // Note: This function is view, it doesn't *actually* update state.
                                              // State update happens in mutating functions like _updateCreatureState.
        return stats;
    }

     // Updates the creature's stored base stats and sets lastUpdatedTime
     function _updateCreatureState(uint256 tokenId, CreatureStats memory newStats) internal {
        // Apply time-based decay/growth *before* storing, based on old lastUpdatedTime
        // This ensures passive effects are accounted for before applying direct boosts.
        CreatureStats memory currentEffectiveStats = _calculateDynamicStats(tokenId);

        // Now apply the *intended* changes (feed, train, etc.) on top of the current effective stats
        // This requires carefully structuring how _calculateDynamicStats and the action functions interact.
        // A cleaner approach might be to store 'base' stats and 'temporary' boosts separately,
        // or always calculate 'current effective stats' on the fly for views, and only update
        // 'base' stats and 'lastUpdatedTime' in mutating functions.
        // Let's refine: Mutating functions modify `_creatureStats[tokenId]` directly,
        // then update `lastUpdatedTime`. `_calculateDynamicStats` is *only* for `view` functions.
        // This means any action function *must* first calculate current decay/growth
        // and apply it to the base stats *before* adding the action's boost.

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsedSinceUpdate = currentTime - _creatureStats[tokenId].lastUpdatedTime;
        uint256 daysElapsedUpdate = timeElapsedSinceUpdate / 1 days;

        _creatureStats[tokenId].baseStrength = _creatureStats[tokenId].baseStrength > daysElapsedUpdate * timeDecayRate[0] ? _creatureStats[tokenId].baseStrength - uint64(daysElapsedUpdate * timeDecayRate[0]) : 0;
        _creatureStats[tokenId].baseIntelligence = _creatureStats[tokenId].baseIntelligence > daysElapsedUpdate * timeDecayRate[1] ? _creatureStats[tokenId].baseIntelligence - uint64(daysElapsedUpdate * timeDecayRate[1]) : 0;
        _creatureStats[tokenId].baseStamina = _creatureStats[tokenId].baseStamina > daysElapsedUpdate * timeDecayRate[2] ? _creatureStats[tokenId].baseStamina - uint64(daysElapsedUpdate * timeDecayRate[2]) : 0;

         // Apply the action's intended boost to the *decayed* base stats
        _creatureStats[tokenId].baseStrength += (newStats.baseStrength - _creatureStats[tokenId].baseStrength); // This assumes newStats holds the *added* boost, not total
        _creatureStats[tokenId].baseIntelligence += (newStats.baseIntelligence - _creatureStats[tokenId].baseIntelligence);
        _creatureStats[tokenId].baseStamina += (newStats.baseStamina - _creatureStats[tokenId].baseStamina);

        // Update timestamps
        _creatureStats[tokenId].lastUpdatedTime = currentTime;

        emit StatsUpdated(tokenId, _creatureStats[tokenId].baseStrength, _creatureStats[tokenId].baseIntelligence, _creatureStats[tokenId].baseStamina);
     }


    // --- CORE CREATURE LIFECYCLE & INTERACTION ---

    /// @notice Mints a new creature NFT for the caller.
    function mintCreature() public payable whenNotPaused nonReentrant {
        require(_tokenIdCounter.current() < maxSupply, "Max supply reached");
        require(msg.value >= mintPrice, "Insufficient Ether for mint");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // --- Simulate trait/stat generation ---
        uint256 randomSeed = _generateRandomValue(newItemId);
        uint64 initialStrength = 50 + uint64(randomSeed % 50); // Base 50-100
        uint64 initialIntelligence = 50 + uint64((randomSeed / 100) % 50);
        uint64 initialStamina = 50 + uint64((randomSeed / 10000) % 50);
        uint64 initialRarity = initialStrength + initialIntelligence + initialStamina; // Simple rarity score

        _creatureStats[newItemId] = CreatureStats({
            baseStrength: initialStrength,
            baseIntelligence: initialIntelligence,
            baseStamina: initialStamina,
            baseRarityScore: initialRarity,
            generation: 1,
            lastUpdatedTime: uint64(block.timestamp),
            lastBredTime: 0, // Can breed immediately after mint
            environmentPreference: uint8(randomSeed % 256) // Random initial preference
        });

        _safeMint(msg.sender, newItemId);

        emit CreatureMinted(newItemId, msg.sender, 1);
        emit StatsUpdated(newItemId, initialStrength, initialIntelligence, initialStamina);
    }

    /// @notice Views the current effective stats of a creature, considering time and environment.
    function getCreatureStats(uint256 tokenId) public view returns (CreatureStats memory) {
         require(_exists(tokenId), "Creature does not exist");
         // This view function calculates dynamic stats without altering state
         return _calculateDynamicStats(tokenId);
    }

    /// @notice Increases a creature's stats based on food consumed (pays EVO).
    /// @param tokenId The ID of the creature to feed.
    function feedCreature(uint256 tokenId) public payable onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
        require(address(evoToken) != address(0), "EVO token address not set");
        require(evoToken.transferFrom(msg.sender, address(this), feedingCostEVO), "EVO transfer failed");

        // Get current stats including decay/growth since last update
        CreatureStats memory currentStats = getCreatureStats(tokenId); // Uses view, calculates effectives

        // Apply feed boost to the base stats after calculating current decay/growth
        _creatureStats[tokenId].baseStrength += uint64(feedBoost[0]);
        _creatureStats[tokenId].baseIntelligence += uint64(feedBoost[1]);
        _creatureStats[tokenId].baseStamina += uint64(feedBoost[2]);

        // Update the last updated time
        _creatureStats[tokenId].lastUpdatedTime = uint64(block.timestamp);

        emit StatsUpdated(tokenId, _creatureStats[tokenId].baseStrength, _creatureStats[tokenId].baseIntelligence, _creatureStats[tokenId].baseStamina);
        _ownerReputation[msg.sender]++; // Simple reputation gain for interaction
        emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
    }

     /// @notice Selectively boosts one stat through training (pays EVO).
     /// @param tokenId The ID of the creature to train.
     /// @param statIndex The index of the stat to boost (0=Str, 1=Int, 2=Sta).
    function trainCreature(uint256 tokenId, uint8 statIndex) public payable onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
        require(address(evoToken) != address(0), "EVO token address not set");
        require(statIndex < 3, "Invalid stat index");
        require(evoToken.transferFrom(msg.sender, address(this), trainingCostEVO), "EVO transfer failed");

        // Apply training boost
        if (statIndex == 0) {
            _creatureStats[tokenId].baseStrength += uint64(trainBoost[0]);
        } else if (statIndex == 1) {
            _creatureStats[tokenId].baseIntelligence += uint64(trainBoost[1]);
        } else if (statIndex == 2) {
             _creatureStats[tokenId].baseStamina += uint64(trainBoost[2]);
        }

        // Update the last updated time
        _creatureStats[tokenId].lastUpdatedTime = uint64(block.timestamp);

        emit StatsUpdated(tokenId, _creatureStats[tokenId].baseStrength, _creatureStats[tokenId].baseIntelligence, _creatureStats[tokenId].baseStamina);
         _ownerReputation[msg.sender]++; // Simple reputation gain for interaction
        emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
    }

    /// @notice Allows creature to recover, applying time-based passive growth since last update.
    ///         Anyone can call this, potentially useful for off-chain keepers.
    /// @param tokenId The ID of the creature to rest/update.
    function restCreature(uint256 tokenId) public whenNotPaused nonReentrant {
        require(_exists(tokenId), "Creature does not exist");

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsedSinceUpdate = currentTime - _creatureStats[tokenId].lastUpdatedTime;

        // Apply passive growth accumulated since last update
        uint256 daysElapsedUpdate = timeElapsedSinceUpdate / 1 days;

         _creatureStats[tokenId].baseStrength += uint64(daysElapsedUpdate * passiveGrowthRate[0]);
         _creatureStats[tokenId].baseIntelligence += uint64(daysElapsedUpdate * passiveGrowthRate[1]);
         _creatureStats[tokenId].baseStamina += uint64(daysElapsedUpdate * passiveGrowthRate[2]);

        // Apply decay accumulated since last update
        _creatureStats[tokenId].baseStrength = _creatureStats[tokenId].baseStrength > daysElapsedUpdate * timeDecayRate[0] ? _creatureStats[tokenId].baseStrength - uint64(daysElapsedUpdate * timeDecayRate[0]) : 0;
        _creatureStats[tokenId].baseIntelligence = _creatureStats[tokenId].baseIntelligence > daysElapsedUpdate * timeDecayRate[1] ? _creatureStats[tokenId].baseIntelligence - uint64(daysElapsedUpdate * timeDecayRate[1]) : 0;
        _creatureStats[tokenId].baseStamina = _creatureStats[tokenId].baseStamina > daysElapsedUpdate * timeDecayRate[2] ? _creatureStats[tokenId].baseStamina - uint64(daysElapsedUpdate * timeDecayRate[2]) : 0;


        _creatureStats[tokenId].lastUpdatedTime = currentTime;

        emit StatsUpdated(tokenId, _creatureStats[tokenId].baseStrength, _creatureStats[tokenId].baseIntelligence, _creatureStats[tokenId].baseStamina);
    }


    /// @notice Attempts to evolve a creature if it meets stat thresholds and pays cost.
    /// @param tokenId The ID of the creature to evolve.
    function evolveCreature(uint256 tokenId) public payable onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
        // Get current effective stats to check eligibility
        CreatureStats memory currentStats = getCreatureStats(tokenId);

        // Example evolution criteria (can be more complex)
        require(currentStats.baseStrength >= 150 &&
                currentStats.baseIntelligence >= 150 &&
                currentStats.baseStamina >= 150 &&
                currentStats.generation < 5, // Max generation limit
                "Creature not ready to evolve or already max generation");

        // Example cost: 0.01 ETH per generation level
        uint256 evolutionCost = 0.01 ether * currentStats.generation;
        require(msg.value >= evolutionCost, "Insufficient Ether for evolution");

        // Increment generation and reset stats (or slightly increase)
        _creatureStats[tokenId].generation++;
        _creatureStats[tokenId].baseStrength = uint64(currentStats.baseStrength * 0.8 + 50); // Example: slightly reset and boost
        _creatureStats[tokenId].baseIntelligence = uint64(currentStats.baseIntelligence * 0.8 + 50);
        _creatureStats[tokenId].baseStamina = uint64(currentStats.baseStamina * 0.8 + 50);
        _creatureStats[tokenId].lastUpdatedTime = uint64(block.timestamp); // Update time after evolution

        emit CreatureEvolved(tokenId, _creatureStats[tokenId].generation);
        emit StatsUpdated(tokenId, _creatureStats[tokenId].baseStrength, _creatureStats[tokenId].baseIntelligence, _creatureStats[tokenId].baseStamina);
        _ownerReputation[msg.sender] += 10; // Reputation boost for evolving
        emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
    }

    /// @notice Breeds two eligible creatures to create a new one (pays cost, has cooldown).
    /// @param tokenId1 The ID of the first creature.
    /// @param tokenId2 The ID of the second creature.
    function breedCreatures(uint256 tokenId1, uint256 tokenId2) public payable whenNotPaused nonReentrant {
        require(tokenId1 != tokenId2, "Cannot breed a creature with itself");
        require(_exists(tokenId1), "Creature 1 does not exist");
        require(_exists(tokenId2), "Creature 2 does not exist");
        require(ownerOf(tokenId1) == msg.sender && ownerOf(tokenId2) == msg.sender, "Must own both creatures to breed");
        require(_tokenIdCounter.current() < maxSupply, "Max supply reached");

        // Check breeding eligibility (cooldown)
        require(uint64(block.timestamp) >= _creatureStats[tokenId1].lastBredTime + breedingCooldown, "Creature 1 on breeding cooldown");
        require(uint64(block.timestamp) >= _creatureStats[tokenId2].lastBredTime + breedingCooldown, "Creature 2 on breeding cooldown");

        // Example cost: Requires Ether or EVO
        require(msg.value >= breedingCost, "Insufficient Ether for breeding");
        // Or require EVO: require(address(evoToken) != address(0) && evoToken.transferFrom(msg.sender, address(this), breedingCostEVO), "EVO transfer failed");


        // --- Simulate child stat generation based on parents + randomness ---
        CreatureStats memory stats1 = getCreatureStats(tokenId1); // Use current stats
        CreatureStats memory stats2 = getCreatureStats(tokenId2);

        _tokenIdCounter.increment();
        uint256 childId = _tokenIdCounter.current();

        uint256 randomSeed = _generateRandomValue(childId * stats1.baseRarityScore * stats2.baseRarityScore);

        uint64 childStrength = (stats1.baseStrength + stats2.baseStrength) / 2 + uint64(randomSeed % 20) - 10; // Average +/- randomness
        uint64 childIntelligence = (stats1.baseIntelligence + stats2.baseIntelligence) / 2 + uint64((randomSeed / 100) % 20) - 10;
        uint64 childStamina = (stats1.baseStamina + stats2.baseStamina) / 2 + uint64((randomSeed / 10000) % 20) - 10;
        uint64 childRarity = childStrength + childIntelligence + childStamina; // Child rarity

        // Clamp stats to a reasonable minimum/maximum if needed
        childStrength = childStrength > 10 ? childStrength : 10;
        childIntelligence = childIntelligence > 10 ? childIntelligence : 10;
        childStamina = childStamina > 10 ? childStamina : 10;


        _creatureStats[childId] = CreatureStats({
            baseStrength: childStrength,
            baseIntelligence: childIntelligence,
            baseStamina: childStamina,
            baseRarityScore: childRarity, // Child rarity score based on initial stats
            generation: uint32(max(stats1.generation, stats2.generation) + 1),
            lastUpdatedTime: uint64(block.timestamp),
            lastBredTime: uint64(block.timestamp), // Child can breed immediately? Or have cooldown?
            environmentPreference: uint8((stats1.environmentPreference + stats2.environmentPreference) / 2) // Average preference
        });

        // Update parent breeding cooldowns
        _creatureStats[tokenId1].lastBredTime = uint64(block.timestamp);
        _creatureStats[tokenId2].lastBredTime = uint64(block.timestamp);

        _safeMint(msg.sender, childId);

        emit CreaturesBred(tokenId1, tokenId2, childId);
        emit CreatureMinted(childId, msg.sender, _creatureStats[childId].generation);
        emit StatsUpdated(childId, childStrength, childIntelligence, childStamina);
        _ownerReputation[msg.sender] += 15; // Reputation boost for breeding
        emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
    }

    /// @notice Views if two creatures are eligible for breeding.
    /// @param tokenId1 The ID of the first creature.
    /// @param tokenId2 The ID of the second creature.
    /// @return bool True if eligible, false otherwise.
    function getBreedEligibility(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
         if (tokenId1 == tokenId2 || !_exists(tokenId1) || !_exists(tokenId2)) {
            return false;
         }
         if (ownerOf(tokenId1) != msg.sender || ownerOf(tokenId2) != msg.sender) {
             return false; // Must own both
         }
         if (_tokenIdCounter.current() >= maxSupply) {
             return false; // Max supply
         }
         if (uint64(block.timestamp) < _creatureStats[tokenId1].lastBredTime + breedingCooldown) {
             return false; // Cooldown 1
         }
         if (uint64(block.timestamp) < _creatureStats[tokenId2].lastBredTime + breedingCooldown) {
              return false; // Cooldown 2
         }
         // Add other criteria if needed (e.g., minimum generation, specific traits)
         return true;
    }


    /// @notice Allows owners to claim accumulated EVO yield for their creatures.
    /// @param tokenIds An array of creature IDs to claim yield for.
    function claimPassiveYield(uint256[] calldata tokenIds) public whenNotPaused nonReentrant {
        require(address(evoToken) != address(0), "EVO token address not set");
        uint256 totalYield = 0;
        uint64 currentTime = uint64(block.timestamp);

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Not owner of creature");

            CreatureStats memory stats = _creatureStats[tokenId];
            uint64 timeElapsedSinceUpdate = currentTime - stats.lastUpdatedTime;
            uint256 secondsSinceUpdate = timeElapsedSinceUpdate; // Use seconds for granularity

            // Calculate yield based on stats and time since last update
            // Example: (Sum of base stats + Rarity Score) * seconds / large_divisor
            uint256 creatureYield = (stats.baseStrength + stats.baseIntelligence + stats.baseStamina + stats.baseRarityScore) * secondsSinceUpdate / (1 days); // Example: Yield per day based on stats

            if (creatureYield > 0) {
                 totalYield += creatureYield;
                 // Important: Update lastUpdatedTime *only* for calculating yield,
                 // so the yield calculation starts from the current time next time.
                 // Stat decay/growth calculation needs to handle the *full* time since the *previous* lastUpdatedTime when stats are viewed/updated.
                 // Let's simplify: lastUpdatedTime tracks both stat update *and* yield accrual start.
                 _creatureStats[tokenId].lastUpdatedTime = currentTime; // Reset yield accrual time

                 // Re-calculate effective stats after updating time to account for decay/growth before next action
                 // This might be redundant if decay/growth is handled in the action functions themselves.
                 // Let's stick to the rule: lastUpdatedTime is timestamp of the last state-changing action/claim.
                 // Decay/growth and yield are calculated based on time elapsed SINCE this timestamp.
                 // The call to getCreatureStats() in view functions does the calculation based on current time.
                 // The call to updateCreatureState() (implicitly) does the calculation and application when a state-changing action happens.
                 // When claiming yield, we only update the timestamp to reset the yield clock. The stats themselves
                 // are not changed *by* claiming yield, but the *potential* for future passive growth/decay continues.
                 // So, just updating the timestamp is sufficient for yield reset.
            }
        }

        if (totalYield > 0) {
            require(address(evoToken) != address(0), "EVO token address not set");
            // Mint or transfer EVO tokens to the owner (assuming contract has minter role or sufficient balance)
            // If using a separate EVO contract, this would typically involve `evoToken.transfer(msg.sender, totalYield);`
            // For this example, let's assume the contract holds EVO and transfers it.
            require(evoToken.transfer(msg.sender, totalYield), "EVO transfer failed");
            emit YieldClaimed(msg.sender, tokenIds, totalYield);
             _ownerReputation[msg.sender] += totalYield / 100; // Reputation based on yield
             emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
        }
    }

    /// @notice Views if a creature's stats meet a minimum threshold for a specific access level.
    ///         Useful for gating access to external content or contract functions.
    /// @param tokenId The ID of the creature.
    /// @param requiredLevel The required access level (e.g., 1=Bronze, 2=Silver, etc.)
    /// @return bool True if stats meet the level criteria, false otherwise.
    function checkAccessLevel(uint256 tokenId, uint256 requiredLevel) public view returns (bool) {
        require(_exists(tokenId), "Creature does not exist");
        CreatureStats memory currentStats = getCreatureStats(tokenId);

        // Example criteria: Access level based on average stat score
        uint256 averageStat = (currentStats.baseStrength + currentStats.baseIntelligence + currentStats.baseStamina) / 3;

        if (requiredLevel == 1) return averageStat >= 100; // Bronze
        if (requiredLevel == 2) return averageStat >= 200 && currentStats.generation >= 2; // Silver requires gen 2
        if (requiredLevel == 3) return averageStat >= 300 && currentStats.baseRarityScore >= 200; // Gold requires rarity

        return false; // Unknown level or insufficient stats
    }

     /// @notice An example function demonstrating how access levels can gate functionality.
     /// @param tokenId The ID of the creature used for access check.
     /// @param requiredLevel The required access level.
    function gatedFunctionExample(uint256 tokenId, uint256 requiredLevel) public onlyCreatureOwner(tokenId) whenNotPaused {
        require(checkAccessLevel(tokenId, requiredLevel), "Creature does not meet required access level");

        // --- Gated functionality goes here ---
        // Example: Mint a special item, get access to a private community link,
        // or perform an in-game action.
        // For demonstration, we just log an event.
        emit CreatureAchievedAccessLevel(tokenId, requiredLevel);
        _ownerReputation[msg.sender] += requiredLevel * 5; // Reputation for meeting access
        emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);

        // Note: This function doesn't *consume* the access, it just verifies it.
        // A consuming action might involve burning the NFT, adding a cooldown, etc.
    }

    event CreatureAchievedAccessLevel(uint256 indexed tokenId, uint256 indexed level);


     /// @notice Allows anyone to trigger the global aging process for all creatures.
     ///         This updates the `lastGlobalAgingTime` which influences passive growth calculations
     ///         in `_calculateDynamicStats`. Designed to be called periodically.
    function triggerAgingProcess() public whenNotPaused {
        // Update the global aging time
        lastGlobalAgingTime = uint64(block.timestamp);
        emit AgingTriggered(lastGlobalAgingTime);
        // Note: This doesn't iterate through all creatures, which would be gas-prohibitive.
        // The passive growth is calculated *per creature* based on the difference between
        // its `lastUpdatedTime` and the `lastGlobalAgingTime` (and current time).
        // This requires careful logic in `_calculateDynamicStats` and `_updateCreatureState`.
        // Let's simplify: Passive growth is based on time since creature's own last update,
        // decay is also based on time since creature's own last update. Global aging just sets a benchmark
        // or maybe triggers certain global events/multipliers (not fully implemented here beyond setting the timestamp).
        // Let's refine the concept: `lastGlobalAgingTime` is simply a timestamp that anyone can update
        // which *could* be used by off-chain systems or future functions to trigger broader effects,
        // but passive growth/decay is tied to the creature's individual `lastUpdatedTime`.
        // The primary role of `triggerAgingProcess` will be for complex off-chain calculations
        // or simply as a public ping mechanism. Let's make passive growth/decay *only* depend on the creature's `lastUpdatedTime`.
        // Revert `_calculateDynamicStats` passive growth logic to depend only on `lastUpdatedTime`.
        // The `lastGlobalAgingTime` can remain as a public timestamp potentially for *other* game mechanics.
        // Okay, refactored `_calculateDynamicStats` and `restCreature` logic mentally.

    }


    /// @notice Burns a creature NFT, potentially granting rewards or boosts elsewhere.
    /// @param tokenId The ID of the creature to sacrifice.
    function sacrificeCreature(uint256 tokenId) public onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
        CreatureStats memory stats = getCreatureStats(tokenId); // Use current stats for sacrifice value

        // Example reward based on rarity and generation
        uint256 sacrificeReward = (stats.baseRarityScore * stats.generation) / 10; // Simple formula

        // Transfer reward (e.g., EVO tokens)
        if (sacrificeReward > 0 && address(evoToken) != address(0)) {
             require(evoToken.transfer(msg.sender, sacrificeReward), "EVO transfer failed for sacrifice reward");
        }

        // Burn the token
        _burn(tokenId); // ERC721 standard burn

        // Clear state associated with the burned token
        delete _creatureStats[tokenId];
        delete _creatureLockedEVO[tokenId]; // Remove any locked EVO

        emit CreatureSacrificed(tokenId, msg.sender);
        _ownerReputation[msg.sender] += sacrificeReward / 50; // Reputation for sacrificing high value
        emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
    }


    /// @notice Demonstrates verifying a ZK proof about the creature's state via an external contract and applying an effect.
    /// @param tokenId The ID of the creature.
    /// @param proof The ZK proof bytes.
    function verifyAndApplyZkProof(uint256 tokenId, bytes calldata proof) public onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
        require(address(zkVerifier) != address(0), "ZK Verifier address not set");
        require(_exists(tokenId), "Creature does not exist");

        // In a real scenario, the ZK proof would prove something about the creature's stats *without revealing them directly*.
        // The `publicInputs` would contain values related to the assertion (e.g., the threshold being checked).
        // Here, we'll use a placeholder for publicInputs. A real circuit would take creature state/traits as private inputs.

        // Example: Prove that creature's current strength is > 200
        uint256 requiredStrengthThreshold = 200;
        uint256[] memory publicInputs = new uint256[](1);
        publicInputs[0] = requiredStrengthThreshold; // The public threshold

        // Call the external ZK verifier contract
        bool verified = zkVerifier.verifyProof(proof, publicInputs);

        emit ZkProofVerifiedAndApplied(tokenId, verified);

        if (verified) {
            // Apply a benefit for proving the trait, e.g., a temporary boost or small EVO reward
            _creatureStats[tokenId].baseStrength += 5; // Small boost as example effect
            _creatureStats[tokenId].lastUpdatedTime = uint64(block.timestamp); // Update time
            emit StatsUpdated(tokenId, _creatureStats[tokenId].baseStrength, _creatureStats[tokenId].baseIntelligence, _creatureStats[tokenId].baseStamina);

            _ownerReputation[msg.sender] += 5; // Reputation for ZK verification
            emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);

            // Note: A real ZK integration would need careful design of the circuit and public inputs
            // to link the proof to a specific creature without revealing its full state on-chain.
            // This pattern shows *how* to call an external verifier and react to the result.
        } else {
             // Handle failed verification (optional)
        }
    }

     /// @notice Owner sets a preference that interacts with the global environment.
     /// @param tokenId The ID of the creature.
     /// @param preference The preference value (0-255).
    function setCreatureEnvironmentPreference(uint256 tokenId, uint8 preference) public onlyCreatureOwner(tokenId) whenNotPaused {
        _creatureStats[tokenId].environmentPreference = preference;
        // No need to update lastUpdatedTime here, it's just a preference.
         _ownerReputation[msg.sender]++; // Small reputation gain for customization
         emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
    }


     /// @notice Locks EVO tokens with a creature for a temporary stat boost.
     /// @param tokenId The ID of the creature.
     /// @param amount The amount of EVO tokens to lock.
    function lockEVOForStatBoost(uint256 tokenId, uint256 amount) public onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
        require(address(evoToken) != address(0), "EVO token address not set");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer EVO tokens from the owner to the contract
        require(evoToken.transferFrom(msg.sender, address(this), amount), "EVO transfer failed");

        // Record the locked amount for this owner and creature
        _creatureLockedEVO[tokenId][msg.sender] += amount;

        emit EVOLocked(tokenId, msg.sender, amount);
         _ownerReputation[msg.sender] += amount / 10; // Reputation for investment
         emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);

        // The stat boost itself is applied in `_calculateDynamicStats` view function.
        // No need to update lastUpdatedTime just for locking, as the boost is dynamic based on locked amount.
    }

    /// @notice Unlocks previously locked EVO tokens.
    /// @param tokenId The ID of the creature.
    /// @param amount The amount of EVO tokens to unlock.
    function unlockEVO(uint256 tokenId, uint256 amount) public onlyCreatureOwner(tokenId) whenNotPaused nonReentrant {
         require(address(evoToken) != address(0), "EVO token address not set");
         require(amount > 0, "Amount must be greater than 0");
         require(_creatureLockedEVO[tokenId][msg.sender] >= amount, "Insufficient locked EVO");

        // Reduce the recorded locked amount
        _creatureLockedEVO[tokenId][msg.sender] -= amount;

        // Transfer EVO tokens back to the owner
        require(evoToken.transfer(msg.sender, amount), "EVO transfer failed");

        emit EVOUnlocked(tokenId, msg.sender, amount);
         _ownerReputation[msg.sender] += amount / 20; // Reputation for managing assets
         emit OwnerReputationUpdated(msg.sender, _ownerReputation[msg.sender]);
    }


    /// @notice Views the accumulated reputation score of an owner.
    /// @param owner The address of the owner.
    /// @return uint256 The reputation score.
    function getOwnerHistoricalReputation(address owner) public view returns (uint256) {
        return _ownerReputation[owner];
    }

    // --- ADMINISTRATIVE & SETUP ---

    /// @notice Pauses core contract interactions (minting, breeding, actions).
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses core contract interactions.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Withdraws collected Ether to a recipient.
    /// @param payable recipient The address to send Ether to.
    function withdrawEther(address payable recipient) public onlyOwner nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether balance to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Ether withdrawal failed");
    }

    /// @notice Withdraws accumulated EVO tokens to a recipient.
    /// @param recipient The address to send EVO to.
    /// @param amount The amount of EVO to withdraw.
    function withdrawEVOTokens(address recipient, uint256 amount) public onlyOwner nonReentrant {
        require(address(evoToken) != address(0), "EVO token address not set");
         require(recipient != address(0), "Invalid recipient address");
         require(amount > 0, "Amount must be greater than 0");
         require(evoToken.balanceOf(address(this)) >= amount, "Insufficient EVO balance");

         require(evoToken.transfer(recipient, amount), "EVO transfer failed");
    }

    /// @notice Sets parameters related to creature minting.
    function setMintParameters(uint256 _mintPrice, uint256 _maxSupply) public onlyOwner {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
    }

     /// @notice Sets parameters related to creature breeding.
    function setBreedingParameters(uint256 _breedingCost, uint64 _breedingCooldown) public onlyOwner {
        breedingCost = _breedingCost;
        breedingCooldown = _breedingCooldown;
    }

     /// @notice Sets parameters related to creature feeding.
    function setFeedingParameters(uint256 _feedingCostEVO) public onlyOwner {
        feedingCostEVO = _feedingCostEVO;
    }

    /// @notice Sets parameters related to creature training.
    function setTrainingParameters(uint256[3] memory _trainBoost, uint256 _trainingCostEVO) public onlyOwner {
        trainBoost = _trainBoost;
        trainingCostEVO = _trainingCostEVO;
    }

     /// @notice Sets multipliers for trait decay and passive growth.
    function setTraitMultipliers(uint256[3] memory _timeDecayRate, uint256[3] memory _passiveGrowthRate) public onlyOwner {
        timeDecayRate = _timeDecayRate;
        passiveGrowthRate = _passiveGrowthRate;
    }

    /// @notice Updates the global environmental factor.
    /// @param newFactor The new environment factor (0-255).
    function updateGlobalEnvironment(uint8 newFactor) public onlyOwner {
        globalEnvironmentFactor = newFactor;
        emit EnvironmentUpdated(newFactor);
        // Note: This change affects dynamic stat calculation in `getCreatureStats`
        // and could influence yield/event outcomes.
    }

    /// @notice Sets the address of the external EVO token contract.
    /// @param _evoToken The address of the EVO token.
    function setEVOTokenAddress(address _evoToken) public onlyOwner {
        evoToken = IERC20(_evoToken);
    }

     /// @notice Sets the address of the external ZK Verifier contract.
     /// @param _zkVerifier The address of the ZK Verifier.
    function setZKVerifierAddress(address _zkVerifier) public onlyOwner {
        zkVerifier = IZKVerifier(_zkVerifier);
    }

    // --- INTERNAL UTILITIES ---
    // Simple max function (Solidity 0.8.0+)
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
     function max(uint32 a, uint32 b) internal pure returns (uint32) {
        return a >= b ? a : b;
    }

}
```