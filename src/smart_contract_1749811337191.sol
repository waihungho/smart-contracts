Okay, let's design a smart contract for "Digital Lifeforms" - dynamic NFTs that can evolve, interact, and have mutable stats based on owner actions and simulated on-chain events. This incorporates dynamic state, interaction between NFTs, simulated evolution/mutation, and access delegation, which are more advanced/creative concepts than standard static NFTs.

We'll use OpenZeppelin libraries for standard interfaces (ERC721, Ownable, Pausable) to focus on the unique logic.

---

## Smart Contract: Digital Lifeforms

### Outline:

1.  **Pragma & Imports:** Define Solidity version and import necessary OpenZeppelin contracts (ERC721, Ownable, Pausable, ReentrancyGuard).
2.  **Errors:** Define custom error types for clarity and gas efficiency (Solidity 0.8+).
3.  **Structs:** Define the structure for storing Lifeform data (genes, stats, level, XP, etc.).
4.  **State Variables:** Mappings to store Lifeform data, token ownership, counters, admin settings (costs, thresholds), and delegation info.
5.  **Events:** Define events for key actions (Minting, Feeding, Evolving, Mutation, Interaction, Status changes, Delegation).
6.  **Modifiers:** Define custom modifiers (e.g., checking if caller is owner or delegate).
7.  **Constructor:** Initialize contract name, symbol, and owner.
8.  **Core Logic Functions:**
    *   Minting new Lifeforms.
    *   Actions affecting Lifeform stats/state (Feeding, Exercising).
    *   Evolution/Mutation mechanics.
    *   Interaction between two Lifeforms.
    *   Managing Status Effects.
    *   Burning Lifeforms.
9.  **Delegation Functions:** Allow Lifeform owners to delegate control for certain actions.
10. **Admin Functions:** Control contract parameters (costs, thresholds, pausing, withdrawal).
11. **Query Functions:** View Lifeform data, token URI, and other contract state.
12. **Internal Helper Functions:** Logic for calculating stats, handling state changes, simulated randomness.
13. **Standard ERC721 Functions:** Implement or override necessary functions (`tokenURI` is overridden).

### Function Summary:

1.  `constructor()`: Initializes the ERC721 contract, name, symbol, and sets the deployer as owner.
2.  `mintLifeform()`: Allows anyone to mint a new Digital Lifeform NFT for a fee. Generates initial genes and stats.
3.  `feedLifeform(uint256 tokenId)`: Allows the owner or delegate of a Lifeform to "feed" it, restoring energy/health based on time passed since last fed.
4.  `exerciseLifeform(uint256 tokenId)`: Allows the owner or delegate of a Lifeform to "exercise" it. Consumes energy, increases XP and potentially stats.
5.  `evolveLifeform(uint256 tokenId)`: Allows the owner of a Lifeform to attempt evolution if it meets level/XP requirements. May increase level and potentially change stats/genes.
6.  `mutateLifeform(uint256 tokenId, bytes32 mutationSeed)`: Allows the owner to trigger a mutation attempt using an external seed. Has a chance to randomly alter genes and stats (using simulated randomness based on the seed and token state).
7.  `triggerLifeformInteraction(uint256 tokenId1, uint256 tokenId2)`: Allows owners/delegates of two different Lifeforms to trigger an interaction. Can result in stat changes, status effects, or other defined outcomes for both participants based on their genes/stats.
8.  `applyStatusEffect(uint256 tokenId, uint8 effectType, uint64 duration)`: Admin function (or potentially triggered by interactions/mutations) to apply a temporary status effect to a Lifeform.
9.  `removeStatusEffect(uint256 tokenId, uint8 effectType)`: Admin function (or triggered by time/action) to remove a specific status effect.
10. `burnLifeform(uint256 tokenId)`: Allows the owner of a Lifeform to destroy it.
11. `delegateControl(uint256 tokenId, address delegate)`: Allows the Lifeform owner to grant another address permission to call specific action functions (`feed`, `exercise`, `triggerLifeformInteraction`) on their behalf.
12. `revokeDelegateControl(uint256 tokenId)`: Allows the Lifeform owner to remove any existing delegation for that token.
13. `getDelegateControl(uint256 tokenId)`: View function to check which address is delegated control for a specific token.
14. `getLifeformData(uint256 tokenId)`: View function returning all the core data for a Lifeform (genes, stats, level, etc.).
15. `getLifeformGenes(uint256 tokenId)`: View function returning just the genes of a Lifeform.
16. `getLifeformStats(uint256 tokenId)`: View function returning just the stats of a Lifeform.
17. `getLifeformStatusEffects(uint256 tokenId)`: View function returning the packed status effects of a Lifeform.
18. `getLifeformLevel(uint256 tokenId)`: View function returning the level of a Lifeform.
19. `getLifeformXP(uint256 tokenId)`: View function returning the XP of a Lifeform.
20. `tokenURI(uint256 tokenId)`: Overrides the ERC721 standard. Returns a dynamic URI pointing to an off-chain service that generates metadata JSON based on the Lifeform's current on-chain state.
21. `pause()`: Owner function to pause certain contract actions (minting, feeding, etc.). Inherited from Pausable.
22. `unpause()`: Owner function to unpause the contract. Inherited from Pausable.
23. `setMintCost(uint256 _mintCost)`: Owner function to set the cost of minting a new Lifeform.
24. `getMintCost()`: View function to check the current mint cost.
25. `setEvolutionThresholds(uint16 _level, uint64 _xp)`: Owner function to set the required XP for a specific level evolution. (Could use mapping `level => xp`).
26. `setBaseStats(uint16 _health, uint16 _energy, uint16 _attack, uint16 _defense, uint16 _speed)`: Owner function to set the base stats for newly minted Lifeforms.
27. `setInteractionCooldown(uint64 _cooldown)`: Owner function to set the cooldown duration between Lifeform interactions.
28. `withdrawFees()`: Owner function to withdraw accumulated contract balance from minting fees.
29. `_generateGenes()`: Internal helper (not callable externally) to create initial random-ish genes for a new Lifeform. Uses block data (insecure for high value, noted).
30. `_calculateDerivedStats(uint256 genes, uint16 level)`: Internal helper to calculate final stats based on genes and level.

*(Note: Standard ERC721 functions like `balanceOf`, `ownerOf`, `transferFrom`, `approve`, etc., are inherited/implemented by extending ERC721 and will also be part of the compiled contract, easily pushing the function count over 20 even if we only listed the custom ones above).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Smart Contract: Digital Lifeforms ---
// Outline:
// 1. Pragma & Imports
// 2. Errors
// 3. Structs
// 4. State Variables
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. Core Logic Functions (Minting, Actions, Evolution, Mutation, Interaction, Status, Burn)
// 9. Delegation Functions
// 10. Admin Functions
// 11. Query Functions (Lifeform data, Token URI)
// 12. Internal Helper Functions
// 13. Standard ERC721 Functions (Implemented/Overridden)

// Function Summary:
// 1. constructor(): Initializes ERC721, name, symbol, owner.
// 2. mintLifeform(): Mints a new Lifeform for a fee.
// 3. feedLifeform(uint256 tokenId): Restores Lifeform energy/health.
// 4. exerciseLifeform(uint256 tokenId): Gains XP/stats, consumes energy.
// 5. evolveLifeform(uint256 tokenId): Attempts evolution based on level/XP.
// 6. mutateLifeform(uint256 tokenId, bytes32 mutationSeed): Attempts random mutation using a seed.
// 7. triggerLifeformInteraction(uint256 tokenId1, uint256 tokenId2): Triggers interaction between two Lifeforms.
// 8. applyStatusEffect(uint256 tokenId, uint8 effectType, uint64 duration): Applies a status effect (Admin/Internal).
// 9. removeStatusEffect(uint256 tokenId, uint8 effectType): Removes a status effect (Admin/Internal).
// 10. burnLifeform(uint256 tokenId): Burns a Lifeform.
// 11. delegateControl(uint256 tokenId, address delegate): Delegates control for actions.
// 12. revokeDelegateControl(uint256 tokenId): Revokes control delegation.
// 13. getDelegateControl(uint256 tokenId): Gets delegate address.
// 14. getLifeformData(uint256 tokenId): Gets all Lifeform data. (View)
// 15. getLifeformGenes(uint256 tokenId): Gets Lifeform genes. (View)
// 16. getLifeformStats(uint256 tokenId): Gets Lifeform stats. (View)
// 17. getLifeformStatusEffects(uint256 tokenId): Gets Lifeform status effects. (View)
// 18. getLifeformLevel(uint256 tokenId): Gets Lifeform level. (View)
// 19. getLifeformXP(uint256 tokenId): Gets Lifeform XP. (View)
// 20. tokenURI(uint256 tokenId): Gets dynamic metadata URI. (View, Overrides ERC721)
// 21. pause(): Pauses actions. (Owner)
// 22. unpause(): Unpauses actions. (Owner)
// 23. setMintCost(uint256 _mintCost): Sets minting cost. (Owner)
// 24. getMintCost(): Gets minting cost. (View)
// 25. setEvolutionThresholds(uint16 _level, uint64 _xp): Sets XP needed for a level. (Owner)
// 26. setBaseStats(uint16 _health, uint16 _energy, uint16 _attack, uint16 _defense, uint16 _speed): Sets base stats. (Owner)
// 27. setInteractionCooldown(uint64 _cooldown): Sets interaction cooldown. (Owner)
// 28. withdrawFees(): Withdraws collected ETH. (Owner)
// 29. _generateGenes(): Internal helper for gene generation.
// 30. _calculateDerivedStats(uint256 genes, uint16 level): Internal helper for stats calculation.

contract DigitalLifeforms is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Errors ---
    error CallerNotLifeformOwnerOrDelegate();
    error InsufficientFunds();
    error TokenDoesNotExist();
    error NotEnoughEnergy();
    error CannotEvolveYet(uint16 requiredLevel, uint64 requiredXP);
    error EvolutionFailed(); // For internal evolution logic failure
    error MutationFailed(); // For internal mutation logic failure
    error InteractionOnCooldown(uint64 timeRemaining);
    error CannotInteractWithSelf();
    error DelegationAlreadyExists();
    error NotLifeformOwner();
    error InvalidStatusEffect();
    error LifeformStillHasStatusEffect();
    error FeeWithdrawFailed();

    // --- Structs ---
    struct LifeformStats {
        uint16 health; // Current health
        uint16 maxHealth; // Max health (derived from genes/level)
        uint16 energy; // Current energy
        uint16 maxEnergy; // Max energy (derived from genes/level)
        uint16 attack; // Derived from genes/level
        uint16 defense; // Derived from genes/level
        uint16 speed; // Derived from genes/level
    }

    struct LifeformData {
        uint256 genes; // Packed genetic data (e.g., trait identifiers)
        LifeformStats stats; // Dynamic stats
        uint16 level;
        uint64 xp;
        uint64 lastFedTimestamp;
        uint64 lastExercisedTimestamp;
        uint64 lastInteractionTimestamp;
        uint32 statusEffects; // Bit flags for various effects (e.g., 1=Poisoned, 2=Buffed, 4=Debuffed)
    }

    // --- State Variables ---
    mapping(uint256 => LifeformData) private _lifeformData;
    mapping(uint256 => address) private _delegates; // tokenId => delegateAddress

    uint256 public mintCost = 0.01 ether; // Default mint cost
    string private _baseTokenURI; // Base URI for metadata service

    // Evolution thresholds: mapping level => required XP
    mapping(uint16 => uint64) public evolutionXPThresholds;

    LifeformStats public baseStatsForNewLifeforms; // Base stats before gene/level modifiers

    uint64 public interactionCooldown = 1 days; // Cooldown for interactions in seconds
    uint64 public feedCooldown = 1 hours; // Cooldown for feeding in seconds
    uint64 public exerciseCooldown = 4 hours; // Cooldown for exercising in seconds

    // --- Events ---
    event LifeformMinted(uint256 indexed tokenId, address indexed owner, uint256 genes);
    event LifeformFed(uint256 indexed tokenId, uint16 energyRestored);
    event LifeformExercised(uint256 indexed tokenId, uint64 xpGained, uint16 energyConsumed);
    event LifeformEvolved(uint256 indexed tokenId, uint16 newLevel, uint256 newGenes);
    event LifeformMutated(uint256 indexed tokenId, uint256 newGenes, string mutationDescription); // Simplified description
    event LifeformInteracted(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event StatusEffectApplied(uint256 indexed tokenId, uint8 effectType, uint64 duration);
    event StatusEffectRemoved(uint256 indexed tokenId, uint8 effectType);
    event LifeformBurned(uint256 indexed tokenId);
    event ControlDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event ControlRevoked(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyLifeformOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) revert NotLifeformOwner();
        _;
    }

    modifier onlyLifeformOwnerOrDelegate(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender() && _delegates[tokenId] != _msgSender()) {
            revert CallerNotLifeformOwnerOrDelegate();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI;
        // Set initial base stats for new lifeforms
        baseStatsForNewLifeforms = LifeformStats({
            health: 100,
            maxHealth: 100,
            energy: 100,
            maxEnergy: 100,
            attack: 10,
            defense: 10,
            speed: 10
        });
        // Set some default evolution thresholds (Level 1 to 2 requires 100 XP, etc.)
        evolutionXPThresholds[1] = 100;
        evolutionXPThresholds[2] = 300; // Total XP
        evolutionXPThresholds[3] = 600; // Total XP
        // Add more levels as needed...
    }

    // --- Core Logic Functions ---

    /**
     * @notice Mints a new Digital Lifeform NFT. Requires payment of `mintCost`.
     */
    function mintLifeform() public payable whenNotPaused nonReentrant {
        if (msg.value < mintCost) revert InsufficientFunds();

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        uint256 newGenes = _generateGenes(newItemId); // Generate initial random genes
        LifeformStats initialStats = baseStatsForNewLifeforms;
        // Adjust initial stats slightly based on genes
        initialStats.maxHealth = initialStats.maxHealth + uint16((newGenes % 10) * 2);
        initialStats.health = initialStats.maxHealth;
        initialStats.maxEnergy = initialStats.maxEnergy + uint16(((newGenes >> 4) % 10) * 2);
        initialStats.energy = initialStats.maxEnergy;
        initialStats.attack = initialStats.attack + uint16(((newGenes >> 8) % 5));
        initialStats.defense = initialStats.defense + uint16(((newGenes >> 12) % 5));
        initialStats.speed = initialStats.speed + uint16(((newGenes >> 16) % 3));


        _lifeformData[newItemId] = LifeformData({
            genes: newGenes,
            stats: initialStats,
            level: 1,
            xp: 0,
            lastFedTimestamp: uint64(block.timestamp),
            lastExercisedTimestamp: uint64(block.timestamp),
            lastInteractionTimestamp: 0, // Can interact immediately
            statusEffects: 0
        });

        _safeMint(msg.sender, newItemId);

        emit LifeformMinted(newItemId, msg.sender, newGenes);
    }

    /**
     * @notice Allows owner or delegate to feed a Lifeform, restoring energy/health.
     * @param tokenId The ID of the Lifeform.
     */
    function feedLifeform(uint256 tokenId) public whenNotPaused nonReentrant onlyLifeformOwnerOrDelegate(tokenId) {
        LifeformData storage lifeform = _lifeformData[tokenId];
        if (_exists(tokenId) == false) revert TokenDoesNotExist();

        uint64 timePassed = uint64(block.timestamp) - lifeform.lastFedTimestamp;
        uint16 energyRestored = 0;
        uint16 healthRestored = 0;

        if (timePassed >= feedCooldown) {
            // Restore full energy and some health after cooldown
            energyRestored = lifeform.stats.maxEnergy - lifeform.stats.energy;
            healthRestored = (lifeform.stats.maxHealth - lifeform.stats.health) / 4; // Restore 25% missing health
        } else {
             // Minor restoration based on time passed within cooldown (optional)
             energyRestored = uint16(timePassed * lifeform.stats.maxEnergy / feedCooldown / 5); // 20% restoration over cooldown
             healthRestored = uint16(timePassed * lifeform.stats.maxHealth / feedCooldown / 20); // 5% restoration over cooldown
        }

        // Prevent exceeding max
        lifeform.stats.energy = lifeform.stats.energy + energyRestored > lifeform.stats.maxEnergy ? lifeform.stats.maxEnergy : lifeform.stats.energy + energyRestored;
        lifeform.stats.health = lifeform.stats.health + healthRestored > lifeform.stats.maxHealth ? lifeform.stats.maxHealth : lifeform.stats.health + healthRestored;


        lifeform.lastFedTimestamp = uint64(block.timestamp);

        emit LifeformFed(tokenId, energyRestored);
    }

     /**
     * @notice Allows owner or delegate to exercise a Lifeform, gaining XP and potentially stats.
     * @param tokenId The ID of the Lifeform.
     */
    function exerciseLifeform(uint256 tokenId) public whenNotPaused nonReentrant onlyLifeformOwnerOrDelegate(tokenId) {
        LifeformData storage lifeform = _lifeformData[tokenId];
        if (_exists(tokenId) == false) revert TokenDoesNotExist();

        uint64 timePassed = uint64(block.timestamp) - lifeform.lastExercisedTimestamp;
        if (timePassed < exerciseCooldown) {
            // Optional: Allow minor exercise within cooldown at reduced efficiency
             // revert ExerciseOnCooldown(exerciseCooldown - timePassed);
        }


        uint16 energyCost = 10; // Fixed energy cost per exercise
        if (lifeform.stats.energy < energyCost) revert NotEnoughEnergy();

        lifeform.stats.energy -= energyCost;
        lifeform.lastExercisedTimestamp = uint64(block.timestamp);

        uint64 xpGained = 10 + (lifeform.stats.speed / 5); // Base XP + bonus from speed
        lifeform.xp += xpGained;

        // Small chance for stat gain on exercise
        if ((uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, lifeform.xp, block.difficulty))) % 100) < 15) { // 15% chance
             uint8 statIndex = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, lifeform.xp, block.difficulty))) % 3); // Which stat? 0=Attack, 1=Defense, 2=Speed
             if (statIndex == 0) lifeform.stats.attack++;
             else if (statIndex == 1) lifeform.stats.defense++;
             else lifeform.stats.speed++;
             // Emit event for stat gain? Depends on desired verbosity.
        }


        // Check for evolution possibility after gaining XP
        _checkAndEvolve(tokenId);

        emit LifeformExercised(tokenId, xpGained, energyCost);
    }

    /**
     * @notice Attempts to evolve a Lifeform if it meets the XP threshold for the next level.
     * @param tokenId The ID of the Lifeform.
     */
    function evolveLifeform(uint256 tokenId) public whenNotPaused nonReentrant onlyLifeformOwner(tokenId) {
        _checkAndEvolve(tokenId); // This internal function handles the core logic
    }

    /**
     * @notice Allows the owner to attempt to trigger a mutation event for a Lifeform.
     * Uses an external seed for unpredictability, combined with on-chain data.
     * Note: Relying solely on block data + seed can still be manipulated if the seed source is predictable or front-runnable.
     * For production, consider Chainlink VRF or similar truly random oracles.
     * @param tokenId The ID of the Lifeform.
     * @param mutationSeed An external seed provided by the caller.
     */
    function mutateLifeform(uint256 tokenId, bytes32 mutationSeed) public whenNotPaused nonReentrant onlyLifeformOwner(tokenId) {
        LifeformData storage lifeform = _lifeformData[tokenId];
         if (_exists(tokenId) == false) revert TokenDoesNotExist();

        // Combine seed with internal state for 'randomness'
        bytes32 combinedSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, tokenId, lifeform.genes, mutationSeed));
        uint256 rand = uint256(combinedSeed);

        // Determine mutation outcome based on rand
        if (rand % 100 < 30) { // 30% chance to mutate (example)
            uint256 oldGenes = lifeform.genes;
            uint256 newGenes = oldGenes;
            string memory description = "Minor change";

            // Example mutation logic: Flip a random bit in genes
            uint8 bitIndex = uint8(rand % 256);
            newGenes = newGenes ^ (1 << bitIndex);

            // Apply effect based on rand result
            uint8 mutationType = uint8((rand >> 8) % 3); // 0=Stats boost, 1=Status effect, 2=Appearance shift (simulated by gene change)
            if (mutationType == 0) {
                 // Stat boost: increase a random stat
                 uint8 statIndex = uint8((rand >> 16) % 5); // 0-4: health, energy, attack, defense, speed
                 if (statIndex == 0) lifeform.stats.maxHealth += 5; lifeform.stats.health = lifeform.stats.maxHealth;
                 else if (statIndex == 1) lifeform.stats.maxEnergy += 5; lifeform.stats.energy = lifeform.stats.maxEnergy;
                 else if (statIndex == 2) lifeform.stats.attack += 2;
                 else if (statIndex == 3) lifeform.stats.defense += 2;
                 else lifeform.stats.speed += 2;
                 description = "Statistical boost mutation!";
            } else if (mutationType == 1) {
                 // Apply a random negative status effect
                 uint8 negativeEffect = uint8((rand >> 24) % 3) + 1; // Example: 1=Weakness, 2=Slowed, 3=Debuff
                 _applyStatusEffect(tokenId, negativeEffect, uint64(block.timestamp) + 1 days); // Apply for 1 day
                 description = "Status effect mutation!";
            } else {
                 // Primary effect is gene change (impacting appearance/derived stats)
                 description = "Gene-altering mutation!";
            }

            lifeform.genes = newGenes;
            // Recalculate derived stats based on new genes
            LifeformStats memory derivedStats = _calculateDerivedStats(lifeform.genes, lifeform.level);
            lifeform.stats.maxHealth = derivedStats.maxHealth;
            lifeform.stats.maxEnergy = derivedStats.maxEnergy;
            lifeform.stats.attack = derivedStats.attack;
            lifeform.stats.defense = derivedStats.defense;
            lifeform.stats.speed = derivedStats.speed;
            // Ensure current stats don't exceed new max
            if(lifeform.stats.health > lifeform.stats.maxHealth) lifeform.stats.health = lifeform.stats.maxHealth;
            if(lifeform.stats.energy > lifeform.stats.maxEnergy) lifeform.stats.energy = lifeform.stats.maxEnergy;


            emit LifeformMutated(tokenId, newGenes, description);
        } else {
            // No mutation happened
             // Optional: emit an event indicating failed mutation attempt
             revert MutationFailed(); // Or just let it pass silently
        }
    }

    /**
     * @notice Triggers an interaction between two different Lifeforms.
     * Requires calling address to be owner or delegate of BOTH tokens.
     * @param tokenId1 The ID of the first Lifeform.
     * @param tokenId2 The ID of the second Lifeform.
     */
    function triggerLifeformInteraction(uint256 tokenId1, uint256 tokenId2) public whenNotPaused nonReentrant {
        if (_exists(tokenId1) == false || _exists(tokenId2) == false) revert TokenDoesNotExist();
        if (tokenId1 == tokenId2) revert CannotInteractWithSelf();

        // Check if caller owns/delegates both tokens
        if (ownerOf(tokenId1) != _msgSender() && _delegates[tokenId1] != _msgSender()) revert CallerNotLifeformOwnerOrDelegate();
        if (ownerOf(tokenId2) != _msgSender() && _delegates[tokenId2] != _msgSender()) revert CallerNotLifeformOwnerOrDelegate();

        LifeformData storage lifeform1 = _lifeformData[tokenId1];
        LifeformData storage lifeform2 = _lifeformData[tokenId2];

        // Check cooldown for both
        uint64 timeSinceLastInteraction1 = uint64(block.timestamp) - lifeform1.lastInteractionTimestamp;
        uint64 timeSinceLastInteraction2 = uint64(block.timestamp) - lifeform2.lastInteractionTimestamp;

        if (timeSinceLastInteraction1 < interactionCooldown) revert InteractionOnCooldown(interactionCooldown - timeSinceLastInteraction1);
        if (timeSinceLastInteraction2 < interactionCooldown) revert InteractionOnCooldown(interactionCooldown - timeSinceLastInteraction2);

        // --- Complex Interaction Logic (Example) ---
        // Based on stats, genes, and potentially block data

        uint256 interactionHash = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId1, tokenId2, lifeform1.genes, lifeform2.genes)));

        // Example 1: Stat comparison based outcome
        if (lifeform1.stats.attack + lifeform1.stats.speed > lifeform2.stats.defense + lifeform2.stats.speed) {
            // Lifeform 1 'wins' the interaction slightly
            lifeform1.xp += 5; // Minor XP gain
            lifeform2.stats.health = lifeform2.stats.health > 5 ? lifeform2.stats.health - 5 : 0; // Minor health loss for Lifeform 2
             // Small chance for status effect on loser
             if (interactionHash % 100 < 20) {
                  _applyStatusEffect(tokenId2, 1, uint64(block.timestamp) + 1 hours); // Apply 'Weakness' (type 1)
             }
        } else if (lifeform2.stats.attack + lifeform2.stats.speed > lifeform1.stats.defense + lifeform1.stats.speed) {
            // Lifeform 2 'wins'
            lifeform2.xp += 5;
            lifeform1.stats.health = lifeform1.stats.health > 5 ? lifeform1.stats.health - 5 : 0;
             if (interactionHash % 100 < 20) {
                 _applyStatusEffect(tokenId1, 1, uint64(block.timestamp) + 1 hours); // Apply 'Weakness' (type 1)
             }
        } else {
            // Draw / Mutual interaction
            lifeform1.xp += 2; // Small XP gain for both
            lifeform2.xp += 2;
        }

        // Example 2: Gene-based compatibility/outcome
        // Check if genes are 'compatible' for a positive outcome chance
        uint256 geneMatchScore = ~(lifeform1.genes ^ lifeform2.genes); // Higher score means more similar bits set
        if (geneMatchScore > (2**256 / 2) && (interactionHash % 100 < 10)) { // If genes are very similar and a random chance hits
             // Positive outcome: minor stats boost for both
             lifeform1.stats.energy = lifeform1.stats.energy + 5 > lifeform1.stats.maxEnergy ? lifeform1.stats.maxEnergy : lifeform1.stats.energy + 5;
             lifeform2.stats.energy = lifeform2.stats.energy + 5 > lifeform2.stats.maxEnergy ? lifeform2.stats.maxEnergy : lifeform2.stats.energy + 5;
        }

        // Update interaction timestamps
        lifeform1.lastInteractionTimestamp = uint64(block.timestamp);
        lifeform2.lastInteractionTimestamp = uint64(block.timestamp);

        // Check for evolution possibilities
        _checkAndEvolve(tokenId1);
        _checkAndEvolve(tokenId2);

        emit LifeformInteracted(tokenId1, tokenId2);
    }

    /**
     * @notice Internal or admin function to apply a status effect.
     * Status effects are bit flags in a uint32.
     * @param tokenId The ID of the Lifeform.
     * @param effectType The type of status effect (1-32).
     * @param duration Timestamp when the effect expires.
     */
    function applyStatusEffect(uint256 tokenId, uint8 effectType, uint64 duration) public onlyOwner {
        _applyStatusEffect(tokenId, effectType, duration);
    }

    /**
     * @notice Internal or admin function to remove a status effect.
     * @param tokenId The ID of the Lifeform.
     * @param effectType The type of status effect (1-32).
     */
    function removeStatusEffect(uint256 tokenId, uint8 effectType) public onlyOwner {
        _removeStatusEffect(tokenId, effectType);
    }


    /**
     * @notice Allows the owner to burn (destroy) their Lifeform.
     * @param tokenId The ID of the Lifeform.
     */
    function burnLifeform(uint256 tokenId) public whenNotPaused nonReentrant onlyLifeformOwner(tokenId) {
        if (_lifeformData[tokenId].statusEffects != 0) {
            // Prevent burning if the Lifeform has active status effects (optional game mechanic)
            revert LifeformStillHasStatusEffect();
        }
        // Clean up data associated with the token
        delete _lifeformData[tokenId];
        delete _delegates[tokenId]; // Remove any delegation

        _burn(tokenId); // Standard ERC721 burn

        emit LifeformBurned(tokenId);
    }


    // --- Delegation Functions ---

    /**
     * @notice Allows the Lifeform owner to delegate control of actions (feed, exercise, interact)
     * to another address.
     * @param tokenId The ID of the Lifeform.
     * @param delegate The address to delegate control to. Address(0) removes delegation.
     */
    function delegateControl(uint256 tokenId, address delegate) public whenNotPaused nonReentrant onlyLifeformOwner(tokenId) {
         if (_delegates[tokenId] != address(0) && delegate != address(0)) {
             revert DelegationAlreadyExists();
         }
         address currentDelegate = _delegates[tokenId];
        _delegates[tokenId] = delegate;
         if (delegate == address(0)) {
             emit ControlRevoked(tokenId, _msgSender(), currentDelegate);
         } else {
             emit ControlDelegated(tokenId, _msgSender(), delegate);
         }
    }

    /**
     * @notice Allows the Lifeform owner to revoke control delegation for a specific token.
     * @param tokenId The ID of the Lifeform.
     */
    function revokeDelegateControl(uint256 tokenId) public whenNotPaused nonReentrant onlyLifeformOwner(tokenId) {
        delegateControl(tokenId, address(0)); // Reuse delegateControl to remove
    }

    /**
     * @notice Returns the address currently delegated control for a Lifeform.
     * @param tokenId The ID of the Lifeform.
     * @return The delegated address, or address(0) if none.
     */
    function getDelegateControl(uint256 tokenId) public view returns (address) {
        return _delegates[tokenId];
    }


    // --- Admin Functions ---

    /**
     * @notice Sets the cost to mint a new Lifeform.
     * @param _mintCost The new mint cost in Wei.
     */
    function setMintCost(uint256 _mintCost) public onlyOwner {
        mintCost = _mintCost;
    }

    /**
     * @notice Gets the current mint cost.
     */
    function getMintCost() public view returns (uint256) {
        return mintCost;
    }

    /**
     * @notice Sets the required XP threshold for a specific level evolution.
     * Total cumulative XP is required.
     * @param _level The target level (e.g., 2 for evolving from 1 to 2).
     * @param _xp The total XP required to reach this level.
     */
    function setEvolutionThresholds(uint16 _level, uint64 _xp) public onlyOwner {
        evolutionXPThresholds[_level] = _xp;
    }

    /**
     * @notice Sets the base stats applied to newly minted Lifeforms.
     * @param _health Base health.
     * @param _energy Base energy.
     * @param _attack Base attack.
     * @param _defense Base defense.
     * @param _speed Base speed.
     */
    function setBaseStats(uint16 _health, uint16 _energy, uint16 _attack, uint16 _defense, uint16 _speed) public onlyOwner {
        baseStatsForNewLifeforms = LifeformStats({
            health: _health,
            maxHealth: _health,
            energy: _energy,
            maxEnergy: _energy,
            attack: _attack,
            defense: _defense,
            speed: _speed
        });
    }

    /**
     * @notice Sets the cooldown duration between Lifeform interactions.
     * @param _cooldown The cooldown in seconds.
     */
    function setInteractionCooldown(uint64 _cooldown) public onlyOwner {
        interactionCooldown = _cooldown;
    }

    /**
     * @notice Allows the owner to withdraw collected ETH from minting fees.
     */
    function withdrawFees() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) return;

        (bool success, ) = payable(owner()).call{value: balance}("");
        if (!success) {
            // Revert or handle failure - reverting is safer in most cases
             revert FeeWithdrawFailed();
        }
        emit FeesWithdrawn(owner(), balance);
    }

    // Override inherited pause/unpause to add Ownable check
    function pause() public override onlyOwner {
        _pause();
    }

    function unpause() public override onlyOwner {
        _unpause();
    }

    // --- Query Functions ---

    /**
     * @notice Gets all stored data for a specific Lifeform.
     * @param tokenId The ID of the Lifeform.
     * @return The LifeformData struct.
     */
    function getLifeformData(uint256 tokenId) public view returns (LifeformData memory) {
        if (_exists(tokenId) == false) revert TokenDoesNotExist();
        return _lifeformData[tokenId];
    }

    /**
     * @notice Gets the genes of a specific Lifeform.
     * @param tokenId The ID of the Lifeform.
     * @return The genes uint256.
     */
    function getLifeformGenes(uint256 tokenId) public view returns (uint256) {
         if (_exists(tokenId) == false) revert TokenDoesNotExist();
         return _lifeformData[tokenId].genes;
    }

    /**
     * @notice Gets the current stats of a specific Lifeform.
     * @param tokenId The ID of the Lifeform.
     * @return The LifeformStats struct.
     */
    function getLifeformStats(uint256 tokenId) public view returns (LifeformStats memory) {
         if (_exists(tokenId) == false) revert TokenDoesNotExist();
         return _lifeformData[tokenId].stats;
    }

    /**
     * @notice Gets the packed status effects of a specific Lifeform.
     * @param tokenId The ID of the Lifeform.
     * @return The statusEffects uint32.
     */
    function getLifeformStatusEffects(uint256 tokenId) public view returns (uint32) {
         if (_exists(tokenId) == false) revert TokenDoesNotExist();
         return _lifeformData[tokenId].statusEffects;
    }

    /**
     * @notice Gets the current level of a specific Lifeform.
     * @param tokenId The ID of the Lifeform.
     * @return The level uint16.
     */
    function getLifeformLevel(uint256 tokenId) public view returns (uint16) {
         if (_exists(tokenId) == false) revert TokenDoesNotExist();
         return _lifeformData[tokenId].level;
    }

    /**
     * @notice Gets the current XP of a specific Lifeform.
     * @param tokenId The ID of the Lifeform.
     * @return The xp uint64.
     */
    function getLifeformXP(uint256 tokenId) public view returns (uint64) {
         if (_exists(tokenId) == false) revert TokenDoesNotExist();
         return _lifeformData[tokenId].xp;
    }


    /**
     * @notice Gets the dynamic metadata URI for a Lifeform.
     * This points to an external service that reads the on-chain state
     * and generates the JSON metadata (image, attributes, etc.).
     * @param tokenId The ID of the Lifeform.
     * @return The token URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_exists(tokenId) == false) revert TokenDoesNotExist();
        // Base URI + tokenId will typically hit an API endpoint
        // e.g., https://my-api.com/lifeforms/123
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }


    // --- Internal Helper Functions ---

    /**
     * @notice Internal function to generate initial genes for a new Lifeform.
     * Note: This uses block hash and timestamp which are subject to miner manipulation/front-running.
     * For truly unpredictable outcomes, use a VRF (Verifiable Random Function) oracle like Chainlink VRF.
     * @param tokenId The ID of the new Lifeform.
     * @return A uint256 representing the Lifeform's genes.
     */
    function _generateGenes(uint256 tokenId) internal view returns (uint256) {
        // Simple pseudo-random gene generation
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, tx.origin)));
        // Example: First 64 bits for color, next 64 for shape, etc. (Conceptually packed)
        return seed;
    }

    /**
     * @notice Internal function to recalculate a Lifeform's derived stats based on genes and level.
     * Note: In a real system, this would involve more complex calculations based on different gene segments.
     * @param genes The Lifeform's genes.
     * @param level The Lifeform's level.
     * @return The derived LifeformStats.
     */
    function _calculateDerivedStats(uint256 genes, uint16 level) internal pure returns (LifeformStats memory) {
         // Simple example: stats increase with level and are modified by genes
         // For a real game, genes would influence growth rates or base values differently.
         uint16 levelBonus = level * 2;
         uint16 geneModifier = uint16((genes % 100) / 10); // Example simple modifier from genes

         return LifeformStats({
            health: 0, // Current health isn't derived
            maxHealth: 100 + levelBonus * 5 + geneModifier * 10, // Max health increases with level and genes
            energy: 0, // Current energy isn't derived
            maxEnergy: 100 + levelBonus * 4 + geneModifier * 8, // Max energy increases with level and genes
            attack: 10 + levelBonus + uint16((genes >> 64) % 15), // Attack influenced by level and a different part of genes
            defense: 10 + levelBonus + uint16((genes >> 128) % 15), // Defense influenced by level and genes
            speed: 10 + levelBonus + uint16((genes >> 192) % 10) // Speed influenced by level and genes
         });
    }

    /**
     * @notice Internal function to check if a Lifeform is ready to evolve and perform evolution if so.
     * @param tokenId The ID of the Lifeform.
     */
    function _checkAndEvolve(uint256 tokenId) internal {
         LifeformData storage lifeform = _lifeformData[tokenId];
         uint16 nextLevel = lifeform.level + 1;
         uint64 requiredXP = evolutionXPThresholds[nextLevel];

         // Check if threshold is set and if lifeform meets it
         if (requiredXP > 0 && lifeform.xp >= requiredXP) {
             lifeform.level = nextLevel;

             // Recalculate stats based on new level and existing genes
             LifeformStats memory evolvedStats = _calculateDerivedStats(lifeform.genes, lifeform.level);
             lifeform.stats.maxHealth = evolvedStats.maxHealth;
             lifeform.stats.health = evolvedStats.maxHealth; // Fully heal on evolution
             lifeform.stats.maxEnergy = evolvedStats.maxEnergy;
             lifeform.stats.energy = evolvedStats.maxEnergy; // Fully restore energy on evolution
             lifeform.stats.attack = evolvedStats.attack;
             lifeform.stats.defense = evolvedStats.defense;
             lifeform.stats.speed = evolvedStats.speed;

             // Optionally, genes could slightly mutate or shift upon evolution
             // uint256 oldGenes = lifeform.genes;
             // lifeform.genes = oldGenes ^ (1 << (lifeform.level % 256)); // Example: flip a bit based on level

             emit LifeformEvolved(tokenId, lifeform.level, lifeform.genes);

             // Recursively check if it can evolve multiple levels at once
             _checkAndEvolve(tokenId);

         } else if (requiredXP == 0 && lifeform.level > 1) {
             // If no threshold is set for the next level, maybe it's max level?
             // Or just doesn't evolve yet.
             // No-op if no next evolution is defined.
         } else {
             // Not ready to evolve yet
             // If explicitly called via evolveLifeform, might revert or just do nothing.
             // Reverting provides feedback if the user expected evolution.
             // If requiredXP is 0, it means no threshold is set for the next level.
             if (requiredXP > 0) {
                  // If called externally via evolveLifeform, revert with details
                  if (msg.sender == ownerOf(tokenId)) { // Check if the external function path was used
                      revert CannotEvolveYet(nextLevel, requiredXP);
                  }
             }
         }
    }

     /**
     * @notice Internal function to apply a status effect (bit flag).
     * Duration sets a timestamp. Off-chain indexer or future contract interaction
     * needs to check block.timestamp against this to determine if effect is active.
     * @param tokenId The ID of the Lifeform.
     * @param effectType The type of status effect (1-32, corresponds to bit position).
     * @param duration Timestamp when the effect expires.
     */
    function _applyStatusEffect(uint256 tokenId, uint8 effectType, uint64 duration) internal {
         LifeformData storage lifeform = _lifeformData[tokenId];
         if (_exists(tokenId) == false) revert TokenDoesNotExist();
         if (effectType == 0 || effectType > 32) revert InvalidStatusEffect();

         uint32 effectBit = 1 << (effectType - 1);
         lifeform.statusEffects |= effectBit; // Set the bit

         // Store duration separately if needed, perhaps in a mapping.
         // For simplicity here, we just set the bit. A real system might need expiry timestamps per effect.
         // mapping(uint256 => mapping(uint8 => uint64)) internal _statusEffectExpiries;
         // _statusEffectExpiries[tokenId][effectType] = duration;

         emit StatusEffectApplied(tokenId, effectType, duration);
    }

     /**
     * @notice Internal function to remove a status effect (clear bit flag).
     * @param tokenId The ID of the Lifeform.
     * @param effectType The type of status effect (1-32, corresponds to bit position).
     */
    function _removeStatusEffect(uint256 tokenId, uint8 effectType) internal {
        LifeformData storage lifeform = _lifeformData[tokenId];
        if (_exists(tokenId) == false) revert TokenDoesNotExist();
        if (effectType == 0 || effectType > 32) revert InvalidStatusEffect();

        uint32 effectBit = 1 << (effectType - 1);
        lifeform.statusEffects &= ~effectBit; // Clear the bit

        // delete _statusEffectExpiries[tokenId][effectType]; // If using expiry mapping

        emit StatusEffectRemoved(tokenId, effectType);
    }

    // --- Standard ERC721 Overrides ---
    // Standard functions like ownerOf, balanceOf, approve, setApprovalForAll,
    // getApproved, isApprovedForAll, transferFrom, safeTransferFrom are
    // inherited and available automatically through OpenZeppelin's ERC721.
    // We only override tokenURI and add necessary checks in core logic functions.

    // The default _exists check is sufficient for most cases via OpenZeppelin.

    // We already overrode tokenURI above.

    // The total function count includes all public/external/view/pure functions
    // defined here plus the standard ERC721 interface functions that are
    // implemented by the OpenZeppelin base contract and exposed publicly.
    // The custom functions listed in the summary are well over 20, and
    // the standard ERC721 functions (balanceOf, ownerOf, approve, getApproved,
    // setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom,
    // supportsInterface) add another 9+ callable functions, meeting the requirement.
}
```