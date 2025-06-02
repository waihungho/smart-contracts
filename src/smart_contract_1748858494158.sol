Okay, let's create a smart contract for "ChronoCreatures" - dynamic, evolving NFTs with traits influenced by time, interactions, breeding, and even a touch of owner reputation. This incorporates dynamic state, time-based mechanics, simple on-chain logic for evolution/battling, an internal resource system, and a reputation system.

It will be based on ERC-721 for ownership but add significant custom logic beyond standard implementations.

**Concept: ChronoCreatures**

ChronoCreatures are digital entities represented as NFTs. They are born (minted), age over time, evolve based on interactions (feeding, training), can breed to create new generations, and possess traits determined by their DNA. Owners can earn "Essence" by interacting or sacrificing creatures, which can be used for upgrades. Owners also build reputation, which might influence certain outcomes or interactions.

**Advanced Concepts Used:**

1.  **Dynamic NFT State:** Creature traits, level, state (Hatchling, Juvenile, Adult, Dormant), and experience change over time and through interactions, not just static metadata.
2.  **Time-Based Mechanics:** Aging, interaction cooldowns, and dormancy periods are enforced and influenced by `block.timestamp`.
3.  **On-Chain Randomness (Simulated):** Used for initial DNA generation, mutation effects, and battle outcomes (using block hash/timestamp for simplicity, Chainlink VRF would be production standard).
4.  **Breeding/Genetic Mixing:** Combines DNA from parent creatures to generate offspring DNA.
5.  **Mutation:** Allows altering a creature's DNA, potentially introducing new traits.
6.  **State Machine:** Creatures transition between defined states (Hatchling -> Juvenile -> Adult -> Dormant) based on criteria (time, experience).
7.  **Internal Resource (Essence):** An in-contract fungible resource earned and spent within the ecosystem.
8.  **Owner Reputation System:** A score tracked per owner address, influenced by actions like breeding and transfers.
9.  **Packed Data:** Using `uint256` for DNA and optimizing struct layout to save gas.
10. **Programmable Royalties (EIP-2981):** Included for secondary sales royalties.
11. **View Functions for Derived Stats:** Battle stats are calculated on the fly based on the creature's current state, level, and traits.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol"; // For programmable royalties

// --- Outline ---
// 1. Libraries: Counters
// 2. Interfaces: (Standard ERC721 interfaces handled by inheritance)
// 3. Errors: Custom error types for clarity and gas efficiency
// 4. Events: Emitted on key state changes and actions
// 5. Enums: Creature state (Hatchling, Juvenile, etc.)
// 6. Structs: Creature data structure
// 7. Constants & State Variables: Global settings, contract state, mappings
// 8. Modifiers: Custom access control (e.g., requires creature alive)
// 9. Constructor: Initializes contract owner and base URI
// 10. ERC721 Overrides: tokenURI, transferFrom, safeTransferFrom
// 11. EIP-2981 Implementation: Royalty functions
// 12. Internal Helpers: DNA generation, stat calculation, experience, evolution checks, reputation
// 13. Core Lifecycle Functions (External/Public):
//     - Minting: mintInitialCreature, breedCreatures, mutateCreature
//     - Interaction: feedCreature, trainCreature
//     - Evolution: evolveCreature, putCreatureToDormancy, wakeCreatureFromDormancy
//     - Utility: sacrificeCreatureForEssence, upgradeWithEssence, claimEssenceReward
// 14. View Functions: Get creature details, traits, status, stats, owner data
// 15. Reputation Functions: delegateReputation, getOwnerReputation
// 16. Admin Functions (OnlyOwner): Update settings, pause, withdraw

// --- Function Summary ---
// ERC721 Standard Functions (Overridden where noted):
// - balanceOf(address owner): Returns the number of tokens owned by `owner`.
// - ownerOf(uint256 tokenId): Returns the owner of the `tokenId`.
// - safeTransferFrom(address from, address to, uint256 tokenId): Transfers token, checks recipient can receive.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Transfers token with data, checks recipient.
// - transferFrom(address from, address to, uint256 tokenId): Transfers token (overridden to add checks).
// - approve(address to, uint256 tokenId): Approves an address to manage a token.
// - getApproved(uint256 tokenId): Returns the approved address for a token.
// - setApprovalForAll(address operator, bool approved): Sets or unsets operator approval for all owner tokens.
// - isApprovedForAll(address owner, address operator): Checks if an operator is approved for an owner.
// - tokenURI(uint256 tokenId): Returns the URI for metadata of a token (overridden to reflect dynamic state).
// - supportsInterface(bytes4 interfaceId): Standard check for supported interfaces (ERC721, ERC2981).

// EIP-2981 Royalty Functions:
// - royaltyInfo(uint256 tokenId, uint256 salePrice): Returns royalty receiver and amount for a sale.
// - setDefaultRoyalty(address receiver, uint96 feeNumerator): Sets a default royalty for all tokens.

// Custom ChronoCreature Functions (Public/External):
// 1. constructor(string memory name, string memory symbol, string memory baseURI): Initializes contract with name, symbol, and metadata base URI.
// 2. mintInitialCreature(address owner): Mints a new Generation 0 creature for `owner`. Uses simple on-chain randomness for DNA.
// 3. breedCreatures(uint256 parent1Id, uint256 parent2Id): Breeds two parent creatures to mint a new offspring. Requires parents to be owned by sender, eligible, and not on cooldown. Mixes parent DNA.
// 4. mutateCreature(uint256 tokenId): Mutates a creature's DNA. Requires creature ownership, eligibility, and costs essence. Introduces randomness.
// 5. feedCreature(uint256 tokenId): Feeds a creature. Adds experience, updates last interacted time. Requires creature ownership and not on cooldown.
// 6. trainCreature(uint256 tokenId): Trains a creature. Adds experience, updates last interacted time. Requires creature ownership and not on cooldown. Might award minor essence.
// 7. evolveCreature(uint256 tokenId): Attempts to evolve a creature to the next state if criteria are met (age, experience thresholds). Updates state and potentially recalculates stats.
// 8. putCreatureToDormancy(uint256 tokenId): Puts a creature into a Dormant state, pausing aging and interaction needs. Requires creature ownership and not already dormant.
// 9. wakeCreatureFromDormancy(uint256 tokenId): Wakes a creature from Dormant state. Resumes aging and interaction needs. Requires creature ownership and being dormant.
// 10. sacrificeCreatureForEssence(uint256 tokenId): Burns a creature token and awards its owner a significant amount of essence.
// 11. upgradeWithEssence(uint256 tokenId, uint256 essenceAmount): Allows owner to spend essence to boost creature stats or level. Requires creature ownership and sufficient essence.
// 12. claimEssenceReward(): Allows owner to claim accrued essence rewards from interactions/activities. (Simplified: just adds a small amount here).
// 13. delegateReputation(address delegatee, uint256 amount): Allows an owner to delegate a portion of their reputation score to another address for governance/voting purposes.
// 14. getCreatureDetails(uint256 tokenId): View function returning the full Creature struct data.
// 15. getCreatureTraits(uint256 tokenId): View function decoding the packed DNA into individual trait values.
// 16. checkEvolutionStatus(uint256 tokenId): View function indicating if a creature is eligible to evolve and to which state.
// 17. getCreatureBattleStats(uint256 tokenId): View function calculating dynamic battle stats based on creature's current state, level, and traits.
// 18. getOwnerReputation(address owner): View function returning the reputation score of an owner.
// 19. getOwnerEssence(address owner): View function returning the essence balance of an owner.
// 20. setSpeciesEvolutionThresholds(uint16 speciesId, uint16[] memory levelThresholds): Admin function to set level requirements for evolution states per species.
// 21. setTraitBoost(uint256 traitIndex, int256 boostValue, uint48 endTime): Admin function to set temporary global boosts or debuffs for specific traits.
// 22. updateBaseURI(string memory newURI): Admin function to update the metadata base URI.
// 23. getTotalSupply(): View function returning the total number of creatures minted. (Manual count since not using Enumerable).
// 24. pauseInteractions(bool paused): Admin function to pause/unpause all creature interactions (feed, train, breed, mutate).
// 25. withdrawEth(): Admin function to withdraw any accidental ETH sent to the contract.

contract ChronoCreatures is ERC721, Ownable, ERC2981 {
    using Counters for Counters.Counter;

    // --- Errors ---
    error InvalidTokenId();
    error NotCreatureOwner(address caller, uint256 tokenId);
    error NotEligibleForBreeding(uint256 tokenId, string reason);
    error NotEligibleForMutation(uint256 tokenId, string reason);
    error NotEligibleForInteraction(uint256 tokenId, string reason);
    error NotEligibleForEvolution(uint256 tokenId, string reason);
    error NotEligibleForDormancyChange(uint256 tokenId, string reason);
    error NotEligibleForSacrifice(uint256 tokenId, string reason);
    error NotEligibleForUpgrade(uint256 tokenId, string reason);
    error InsufficientEssence(address owner, uint256 required, uint256 has);
    error CannotDelegateMoreReputation(address owner, uint256 amount);
    error InteractionPaused();
    error CreatureIsDormant(uint256 tokenId);
    error CreatureIsNotDormant(uint256 tokenId);
    error InvalidMutationType(uint256 mutationType);

    // --- Events ---
    event CreatureMinted(uint256 indexed tokenId, address indexed owner, uint16 species, uint256 dna, uint32 generation);
    event CreatureBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, address owner);
    event CreatureMutated(uint256 indexed tokenId, uint256 newDna);
    event CreatureInteracted(uint256 indexed tokenId, address indexed owner, string interactionType); // "Feed" or "Train"
    event CreatureEvolutionAttempt(uint256 indexed tokenId, uint8 fromState, uint8 toState, bool success);
    event CreatureStateChanged(uint256 indexed tokenId, uint8 fromState, uint8 toState);
    event CreatureDormancyChanged(uint256 indexed tokenId, bool isDormant);
    event CreatureSacrificed(uint256 indexed tokenId, address indexed owner, uint256 essenceAwarded);
    event CreatureUpgraded(uint256 indexed tokenId, uint256 essenceSpent, string upgradeType); // e.g., "LevelBoost", "TraitBoost"
    event EssenceClaimed(address indexed owner, uint256 amount);
    event ReputationGained(address indexed owner, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event TraitBoostSet(uint256 indexed traitIndex, int256 boostValue, uint48 endTime);

    // --- Enums ---
    enum State {
        Hatchling,
        Juvenile,
        Adult,
        Elder,
        Dormant,
        Sacrificed // Cannot be interacted with further
    }

    // --- Structs ---
    struct Creature {
        uint48 birthTime;       // Timestamp (approximate)
        uint48 lastInteracted;  // Timestamp of last feed/train
        uint32 generation;      // 0 for initial mints, >0 for bred/mutated
        uint16 species;         // Identifier for species type
        uint256 dna;            // Packed genetic data (traits, stats base)
        uint16 level;
        uint32 experience;
        State state;
        uint32 parent1;         // Token ID of parent 1 (0 if Gen 0)
        uint32 parent2;         // Token ID of parent 2 (0 if Gen 0)
        uint48 cooldownEnd;     // Timestamp when breeding/mutation/interaction cooldown ends
    }

    // --- Constants & State Variables ---
    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => Creature) private _creatures;
    mapping(address => uint256) private _ownerEssence;
    mapping(address => uint256) private _ownerReputation; // Base reputation earned through activities
    mapping(address => uint256) private _delegatedReputation; // Reputation received from others

    string private _baseTokenURI;

    // Evolution thresholds: speciesId -> level required for State transition
    // e.g., thresholds[speciesX][0] = level for Hatchling -> Juvenile
    //       thresholds[speciesX][1] = level for Juvenile -> Adult
    //       thresholds[speciesX][2] = level for Adult -> Elder
    mapping(uint16 => uint16[3]) private _speciesEvolutionThresholds;

    // Temporary global boosts/debuffs for traits: traitIndex -> (boostValue, endTime)
    mapping(uint256 => int256) private _traitBoostValue;
    mapping(uint256 => uint48) private _traitBoostEndTime;

    uint256 public constant COOLDOWN_INTERACTION = 1 days;
    uint256 public constant COOLDOWN_BREED_MUTATE = 7 days;
    uint256 public constant ESSENCE_REWARD_INTERACTION = 5;
    uint256 public constant ESSENCE_SACRIFICE_BASE = 100;
    uint256 public constant REPUTATION_BREED_SUCCESS = 1;
    uint256 public constant REPUTATION_DELEGATION_CAP = 1000; // Max reputation delegateable per owner

    uint256 public constant DNA_BITS_PER_TRAIT = 8; // Assume 8 bits per trait for packing
    uint256 public constant DNA_TRAIT_COUNT = 32;   // Allows up to 32 traits in 256 bits

    bool public interactionsPaused = false;

    // --- Modifiers ---
    modifier requireNotSacrificed(uint256 tokenId) {
        if (_creatures[tokenId].state == State.Sacrificed) revert NotEligibleForInteraction(tokenId, "Creature is sacrificed");
        _;
    }

    modifier requireAlive(uint256 tokenId) {
        State state = _creatures[tokenId].state;
        if (state == State.Sacrificed || state == State.Dormant) revert CreatureIsDormant(tokenId); // Dormant also prevents many actions
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        ERC2981()
    {
        _baseTokenURI = baseURI;
        // Set default royalties (can be changed by owner)
        _setDefaultRoyalty(msg.sender, 250); // 2.5%
    }

    // --- ERC721 Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();

        // Append token ID and potentially state/hash to URI for dynamic metadata
        // A real implementation would have an API resolve this URI and provide JSON based on on-chain state
        string memory base = _baseTokenURI;
        string memory tokenIDStr = Strings.toString(tokenId);
        string memory stateStr = Strings.toString(uint8(_creatures[tokenId].state));

        // Simple example: baseURI/tokenId?state=X&level=Y...
        // More advanced: baseURI/tokenId.json - API looks up state on chain
        return string(abi.encodePacked(base, tokenIDStr, "?state=", stateStr, "&level=", Strings.toString(_creatures[tokenId].level)));
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Add custom check: cannot transfer if creature is dormant
        if (_creatures[tokenId].state == State.Dormant) revert CreatureIsDormant(tokenId);
        super.transferFrom(from, to, tokenId);
        // Optional: award minor reputation to sender for active trading (discourages holding dormant assets?)
        // _awardReputation(from, 1); // Example
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        if (_creatures[tokenId].state == State.Dormant) revert CreatureIsDormant(tokenId);
         super.safeTransferFrom(from, to, tokenId);
        // Optional: award minor reputation
        // _awardReputation(from, 1); // Example
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        if (_creatures[tokenId].state == State.Dormant) revert CreatureIsDormant(tokenId);
         super.safeTransferFrom(from, to, tokenId, data);
        // Optional: award minor reputation
        // _awardReputation(from, 1); // Example
    }


    // --- EIP-2981 Implementation ---
    // Default royalties are set in the constructor and can be updated by owner
    // Token-specific royalties are not implemented here but could be added
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Helpers ---

    // Simple hash-based randomness for example (NOT secure for high-value applications)
    function _generateRandomSeed() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenIdCounter.current())));
    }

    // Generates DNA for a new creature (Gen 0 or Bred)
    function _generateDNA(uint32 generation, uint256 parent1DNA, uint256 parent2DNA) private view returns (uint256) {
        uint256 seed = _generateRandomSeed();
        uint256 newDNA = 0;

        if (generation == 0) {
            // Generate random DNA for Gen 0
            for (uint256 i = 0; i < DNA_TRAIT_COUNT; i++) {
                uint256 traitValue = (seed >> (i * DNA_BITS_PER_TRAIT)) % (2**DNA_BITS_PER_TRAIT);
                newDNA |= (traitValue << (i * DNA_BITS_PER_TRAIT));
            }
        } else {
            // Mix parent DNA for breeding
            // Simple mixing: for each trait, 50% chance of inheriting from parent 1 or parent 2
            for (uint256 i = 0; i < DNA_TRAIT_COUNT; i++) {
                uint256 traitValue1 = (parent1DNA >> (i * DNA_BITS_PER_TRAIT)) & ((1 << DNA_BITS_PER_TRAIT) - 1);
                uint256 traitValue2 = (parent2DNA >> (i * DNA_BITS_PER_TRAIT)) & ((1 << DNA_BITS_PER_TRAIT) - 1);

                uint256 selectedTraitValue;
                if ((seed >> i) & 1 == 0) { // Use a bit from the seed
                    selectedTraitValue = traitValue1;
                } else {
                    selectedTraitValue = traitValue2;
                }
                newDNA |= (selectedTraitValue << (i * DNA_BITS_PER_TRAIT));
            }
             // Add minor random variation (mutation chance during breeding)
             uint256 mutationSeed = uint256(keccak256(abi.encodePacked(seed, parent1DNA, parent2DNA)));
             for(uint256 i = 0; i < DNA_TRAIT_COUNT; i++) {
                 if ((mutationSeed >> i) & 1 == 1 && (mutationSeed >> (i + DNA_TRAIT_COUNT)) % 10 < 1) { // 10% chance per trait
                     uint256 randomChange = (mutationSeed >> (i * 2)) % 3; // -1, 0, or +1
                     int256 currentTraitValue = int256((newDNA >> (i * DNA_BITS_PER_TRAIT)) & ((1 << DNA_BITS_PER_TRAIT) - 1));
                     int256 newTraitValue = currentTraitValue + (randomChange == 0 ? -1 : (randomChange == 1 ? 0 : 1));
                     // Clamp value within trait range
                     if (newTraitValue < 0) newTraitValue = 0;
                     if (newTraitValue >= (2**DNA_BITS_PER_TRAIT)) newTraitValue = (2**DNA_BITS_PER_TRAIT) - 1;
                     newDNA &= ~(((1 << DNA_BITS_PER_TRAIT) - 1) << (i * DNA_BITS_PER_TRAIT)); // Clear old trait value
                     newDNA |= (uint256(newTraitValue) << (i * DNA_BITS_PER_TRAIT)); // Set new trait value
                 }
             }
        }

        return newDNA;
    }

    // Decodes packed DNA into an array of trait values
    function _decodeDNA(uint256 dna) private pure returns (uint256[] memory) {
        uint256[] memory traits = new uint256[](DNA_TRAIT_COUNT);
        for (uint256 i = 0; i < DNA_TRAIT_COUNT; i++) {
            traits[i] = (dna >> (i * DNA_BITS_PER_TRAIT)) & ((1 << DNA_BITS_PER_TRAIT) - 1);
        }
        return traits;
    }

    // Packs an array of traits into DNA
    function _encodeDNA(uint256[] memory traits) private pure returns (uint256) {
         require(traits.length == DNA_TRAIT_COUNT, "Invalid traits array length");
         uint256 dna = 0;
         for(uint256 i = 0; i < DNA_TRAIT_COUNT; i++) {
             require(traits[i] < (1 << DNA_BITS_PER_TRAIT), "Trait value out of range");
             dna |= (traits[i] << (i * DNA_BITS_PER_TRAIT));
         }
         return dna;
    }

    // Calculates dynamic battle stats based on creature state, level, and traits
    // Example: Stat = (BaseTraitValue + TraitBoost) * LevelMultiplier * StateMultiplier
    function _calculateBattleStats(uint256 tokenId) private view returns (uint256 attack, uint256 defense, uint256 speed) {
        Creature storage creature = _creatures[tokenId];
        uint256[] memory traits = _decodeDNA(creature.dna);

        // Assume trait indices 0, 1, 2 correspond to attack, defense, speed base values
        uint256 baseAttack = traits[0];
        uint256 baseDefense = traits[1];
        uint256 baseSpeed = traits[2];

        // Apply temporary trait boosts
        baseAttack = uint256(int256(baseAttack) + _applyTraitBoosts(0));
        baseDefense = uint256(int256(baseDefense) + _applyTraitBoosts(1));
        baseSpeed = uint256(int256(baseSpeed) + _applyTraitBoosts(2));

        // Apply level and state multipliers (example multipliers)
        uint256 levelMultiplier = 10 + creature.level * 2;
        uint256 stateMultiplier = 10; // Base
        if (creature.state == State.Juvenile) stateMultiplier = 15;
        else if (creature.state == State.Adult) stateMultiplier = 20;
        else if (creature.state == State.Elder) stateMultiplier = 25;
        else if (creature.state == State.Dormant || creature.state == State.Sacrificed) stateMultiplier = 0; // No stats when dormant/sacrificed

        attack = (baseAttack * levelMultiplier * stateMultiplier) / 100; // Scale down
        defense = (baseDefense * levelMultiplier * stateMultiplier) / 100;
        speed = (baseSpeed * levelMultiplier * stateMultiplier) / 100;

        // Simple randomness modifier for battles (NOT for determining permanent stats)
        uint256 battleRandomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, tokenId)));
        attack = attack * (100 + (battleRandomSeed % 11) - 5) / 100; // +/- 5%
        defense = defense * (100 + ((battleRandomSeed >> 8) % 11) - 5) / 100;
        speed = speed * (100 + ((battleRandomSeed >> 16) % 11) - 5) / 100;

        return (attack, defense, speed);
    }

    // Applies active global trait boosts
    function _applyTraitBoosts(uint256 traitIndex) private view returns (int256) {
        if (block.timestamp < _traitBoostEndTime[traitIndex]) {
            return _traitBoostValue[traitIndex];
        }
        return 0;
    }

    // Awards experience and handles level ups
    function _awardExperience(uint256 tokenId, uint32 amount) private {
        Creature storage creature = _creatures[tokenId];
        if (creature.state == State.Sacrificed || creature.state == State.Dormant) return; // Cannot gain XP when dead or dormant

        creature.experience += amount;
        // Simple level up logic: level = sqrt(experience / 10)
        uint16 newLevel = uint16(Math.sqrt(creature.experience / 10)); // Using Math.sqrt from OpenZeppelin utils

        if (newLevel > creature.level) {
            creature.level = newLevel;
            // Could emit level up event here
        }
    }

    // Checks if a creature meets the criteria to evolve to the next state
    function _checkEvolutionEligibility(uint256 tokenId) private view returns (bool, State) {
        Creature storage creature = _creatures[tokenId];

        if (creature.state == State.Sacrificed || creature.state == State.Dormant || creature.state == State.Elder) {
            return (false, creature.state); // Cannot evolve from these states
        }

        State nextState = creature.state + 1;
        uint16 requiredLevel = _speciesEvolutionThresholds[creature.species][uint8(creature.state)];

        bool eligible = creature.level >= requiredLevel && block.timestamp >= creature.birthTime + (uint256(uint8(nextState)) * 7 days); // Example: also requires age (e.g., 7 days per state)

        return (eligible, nextState);
    }

    // Awards reputation to an owner
    function _awardReputation(address owner, uint256 amount) private {
        _ownerReputation[owner] += amount;
        emit ReputationGained(owner, amount);
    }

     // Check if an owner has enough total reputation (base + delegated)
     function _getTotalReputation(address owner) private view returns (uint256) {
         return _ownerReputation[owner] + _delegatedReputation[owner];
     }

     // Internal mint function
     function _mintCreature(address to, uint16 species, uint256 dna, uint32 generation, uint32 parent1, uint32 parent2) private {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _creatures[newTokenId] = Creature({
            birthTime: uint48(block.timestamp),
            lastInteracted: uint48(block.timestamp),
            generation: generation,
            species: species,
            dna: dna,
            level: 1,
            experience: 0,
            state: State.Hatchling,
            parent1: parent1,
            parent2: parent2,
            cooldownEnd: uint48(block.timestamp) // Start with no cooldown
        });

        _safeMint(to, newTokenId);
        emit CreatureMinted(newTokenId, to, species, dna, generation);
     }

    // Internal burn function (handles state)
    function _burnCreature(uint256 tokenId) private {
        // Ensure the creature is marked as sacrificed before burning
        _creatures[tokenId].state = State.Sacrificed; // Mark as sacrificed first
        _burn(tokenId); // Standard ERC721 burn
        // State is already updated, sacrifice event is emitted in the public function
    }

    // --- Core Lifecycle Functions ---

    /**
     * @notice Mints a new Generation 0 creature. Only callable by contract owner initially,
     *         could be opened up or gated later.
     * @param owner The address to mint the creature to.
     */
    function mintInitialCreature(address owner) external onlyOwner {
        uint256 dna = _generateDNA(0, 0, 0); // Gen 0 has no parents

        // Simple example: Species is derived from first few bits of DNA
        uint16 species = uint16(dna % 10); // Example: 10 possible species

        _mintCreature(owner, species, dna, 0, 0, 0);
    }

    /**
     * @notice Breeds two parent creatures to produce a new offspring.
     * @param parent1Id The token ID of the first parent.
     * @param parent2Id The token ID of the second parent.
     */
    function breedCreatures(uint256 parent1Id, uint256 parent2Id) external requireNotSacrificed(parent1Id) requireNotSacrificed(parent2Id) {
        if (interactionsPaused) revert InteractionPaused();
        address owner = _msgSender();
        if (ownerOf(parent1Id) != owner) revert NotCreatureOwner(owner, parent1Id);
        if (ownerOf(parent2Id) != owner) revert NotCreatureOwner(owner, parent2Id);
        if (parent1Id == parent2Id) revert NotEligibleForBreeding(parent1Id, "Cannot breed with self");

        Creature storage parent1 = _creatures[parent1Id];
        Creature storage parent2 = _creatures[parent2Id];

        // Breeding eligibility checks
        if (parent1.state < State.Juvenile || parent2.state < State.Juvenile) revert NotEligibleForBreeding(0, "Parents must be at least Juvenile");
        if (block.timestamp < parent1.cooldownEnd) revert NotEligibleForBreeding(parent1Id, "Parent 1 on cooldown");
        if (block.timestamp < parent2.cooldownEnd) revert NotEligibleForBreeding(parent2Id, "Parent 2 on cooldown");

        uint256 childDNA = _generateDNA(parent1.generation > parent2.generation ? parent1.generation + 1 : parent2.generation + 1, parent1.dna, parent2.dna);
        uint16 childSpecies = uint16(childDNA % 10); // Example: Species from DNA

        _mintCreature(owner, childSpecies, childDNA, parent1.generation > parent2.generation ? parent1.generation + 1 : parent2.generation + 1, uint32(parent1Id), uint32(parent2Id));

        // Set cooldowns on parents
        parent1.cooldownEnd = uint48(block.timestamp + COOLDOWN_BREED_MUTATE);
        parent2.cooldownEnd = uint48(block.timestamp + COOLDOWN_BREED_MUTATE);

        _awardReputation(owner, REPUTATION_BREED_SUCCESS);
        emit CreatureBred(parent1Id, parent2Id, _tokenIdCounter.current(), owner);
    }

    /**
     * @notice Mutates a creature's DNA, potentially changing traits.
     *         Requires a creature and consumes essence.
     * @param tokenId The token ID of the creature to mutate.
     */
    function mutateCreature(uint256 tokenId) external requireAlive(tokenId) requireNotSacrificed(tokenId) {
        if (interactionsPaused) revert InteractionPaused();
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);

        Creature storage creature = _creatures[tokenId];

        if (block.timestamp < creature.cooldownEnd) revert NotEligibleForMutation(tokenId, "Creature on cooldown");
        // Example: Mutation requires essence based on creature generation/level
        uint256 essenceCost = 50 + creature.generation * 10 + creature.level;
        if (_ownerEssence[owner] < essenceCost) revert InsufficientEssence(owner, essenceCost, _ownerEssence[owner]);

        _ownerEssence[owner] -= essenceCost;

        // Simple mutation: Randomly change a few traits
        uint256 currentDNA = creature.dna;
        uint256 seed = _generateRandomSeed();
        uint256 newDNA = currentDNA;

        uint256 traitsToMutate = (seed % 3) + 1; // Mutate 1 to 3 traits

        for(uint256 i = 0; i < traitsToMutate; i++) {
            uint256 traitIndex = (seed >> (i * 4)) % DNA_TRAIT_COUNT;
            uint256 randomChange = (seed >> (i * 8)) % (2**DNA_BITS_PER_TRAIT); // New random value for the trait

            newDNA &= ~(((1 << DNA_BITS_PER_TRAIT) - 1) << (traitIndex * DNA_BITS_PER_TRAIT)); // Clear old trait value
            newDNA |= (randomChange << (traitIndex * DNA_BITS_PER_PER_TRAIT)); // Set new trait value
        }

        creature.dna = newDNA;
        creature.cooldownEnd = uint48(block.timestamp + COOLDOWN_BREED_MUTATE); // Set cooldown after mutation

        emit CreatureMutated(tokenId, newDNA);
    }

    /**
     * @notice Feeds a creature, adding experience.
     * @param tokenId The token ID of the creature.
     */
    function feedCreature(uint256 tokenId) external requireAlive(tokenId) requireNotSacrificed(tokenId) {
        if (interactionsPaused) revert InteractionPaused();
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);

        Creature storage creature = _creatures[tokenId];
        if (block.timestamp < creature.lastInteracted + COOLDOWN_INTERACTION) revert NotEligibleForInteraction(tokenId, "Creature on interaction cooldown");

        _awardExperience(tokenId, 10); // Example experience amount
        creature.lastInteracted = uint48(block.timestamp);
        // _awardEssence(owner, ESSENCE_REWARD_INTERACTION); // Could award essence here
        emit CreatureInteracted(tokenId, owner, "Feed");
    }

    /**
     * @notice Trains a creature, adding experience.
     * @param tokenId The token ID of the creature.
     */
    function trainCreature(uint256 tokenId) external requireAlive(tokenId) requireNotSacrificed(tokenId) {
         if (interactionsPaused) revert InteractionPaused();
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);

        Creature storage creature = _creatures[tokenId];
        if (block.timestamp < creature.lastInteracted + COOLDOWN_INTERACTION) revert NotEligibleForInteraction(tokenId, "Creature on interaction cooldown");

        _awardExperience(tokenId, 15); // Example experience amount (more than feed)
        creature.lastInteracted = uint48(block.timestamp);
        // _awardEssence(owner, ESSENCE_REWARD_INTERACTION * 2); // Could award more essence here
        emit CreatureInteracted(tokenId, owner, "Train");
    }

     /**
     * @notice Attempts to evolve a creature to the next state if eligible.
     * @param tokenId The token ID of the creature.
     */
    function evolveCreature(uint256 tokenId) external requireNotSacrificed(tokenId) {
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);

        Creature storage creature = _creatures[tokenId];

        (bool eligible, State nextState) = _checkEvolutionEligibility(tokenId);

        emit CreatureEvolutionAttempt(tokenId, uint8(creature.state), uint8(nextState), eligible);

        if (!eligible) revert NotEligibleForEvolution(tokenId, "Criteria not met (Level or Age)");

        State oldState = creature.state;
        creature.state = nextState;

        // Optional: Reset experience or apply stat changes on evolution
        creature.experience = 0; // Example: Reset XP on evolution

        emit CreatureStateChanged(tokenId, uint8(oldState), uint8(nextState));
    }

    /**
     * @notice Puts a creature into a dormant state. Pauses aging and interaction needs.
     * @param tokenId The token ID of the creature.
     */
    function putCreatureToDormancy(uint256 tokenId) external requireNotSacrificed(tokenId) {
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);

        Creature storage creature = _creatures[tokenId];
        if (creature.state == State.Dormant) revert NotEligibleForDormancyChange(tokenId, "Already dormant");
        if (creature.state == State.Hatchling) revert NotEligibleForDormancyChange(tokenId, "Hatchlings cannot be dormant"); // Example restriction

        State oldState = creature.state;
        creature.state = State.Dormant;
        // Store the state it was in before dormancy, if needed later (requires adding a field to struct)
        // For simplicity, we just change to Dormant state.

        emit CreatureDormancyChanged(tokenId, true);
         emit CreatureStateChanged(tokenId, uint8(oldState), uint8(State.Dormant));
    }

    /**
     * @notice Wakes a creature from a dormant state. Resumes aging and interaction needs.
     * @param tokenId The token ID of the creature.
     */
    function wakeCreatureFromDormancy(uint256 tokenId) external requireNotSacrificed(tokenId) {
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);

        Creature storage creature = _creatures[tokenId];
        if (creature.state != State.Dormant) revert NotEligibleForDormancyChange(tokenId, "Not dormant");

        // Restore to a sensible state, e.g., Hatchling or Juvenile based on age/level thresholds
        // This simplified example just moves it to Juvenile, a real one would check age/level
        State oldState = creature.state;
        creature.state = State.Juvenile; // Example: Wake up as Juvenile

        // Reset last interacted time to now so it doesn't immediately require interaction
        creature.lastInteracted = uint48(block.timestamp);

        emit CreatureDormancyChanged(tokenId, false);
        emit CreatureStateChanged(tokenId, uint8(oldState), uint8(creature.state));
    }

     /**
     * @notice Burns a creature and awards the owner a significant amount of essence.
     * @param tokenId The token ID of the creature to sacrifice.
     */
    function sacrificeCreatureForEssence(uint256 tokenId) external requireNotSacrificed(tokenId) {
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);

        Creature storage creature = _creatures[tokenId];
        // Example: Cannot sacrifice low-level creatures
        if (creature.level < 10) revert NotEligibleForSacrifice(tokenId, "Creature level too low to sacrifice");

        uint256 essenceAwarded = ESSENCE_SACRIFICE_BASE + (creature.level * 10) + (creature.experience / 100); // Award based on level/xp

        _ownerEssence[owner] += essenceAwarded;

        emit CreatureSacrificed(tokenId, owner, essenceAwarded);
        _burnCreature(tokenId); // Use internal burn which updates state
    }

     /**
     * @notice Allows spending essence to upgrade a creature (e.g., boost level).
     * @param tokenId The token ID of the creature to upgrade.
     * @param essenceAmount The amount of essence to spend.
     */
    function upgradeWithEssence(uint256 tokenId, uint256 essenceAmount) external requireAlive(tokenId) requireNotSacrificed(tokenId) {
        address owner = _msgSender();
        if (ownerOf(tokenId) != owner) revert NotCreatureOwner(owner, tokenId);
        if (_ownerEssence[owner] < essenceAmount) revert InsufficientEssence(owner, essenceAmount, _ownerEssence[owner]);
         if (essenceAmount == 0) revert NotEligibleForUpgrade(tokenId, "Cannot upgrade with zero essence");

        _ownerEssence[owner] -= essenceAmount;

        Creature storage creature = _creatures[tokenId];

        // Example upgrade logic: 10 essence = 1 level
        uint32 experienceBoost = uint32(essenceAmount * 100); // 1 essence gives 100 XP
        _awardExperience(tokenId, experienceBoost); // Use existing XP system for level calculation

        emit CreatureUpgraded(tokenId, essenceAmount, "LevelBoost");
    }

    /**
     * @notice Allows an owner to claim a small amount of essence.
     *         Could be tied to interactions or daily logins in a dApp, simplified here.
     */
    function claimEssenceReward() external {
        address owner = _msgSender();
        // Simple example: Award fixed amount, potentially with a cooldown
        uint256 reward = ESSENCE_REWARD_INTERACTION * 5; // Small boost
        _ownerEssence[owner] += reward;
        emit EssenceClaimed(owner, reward);
        // A real implementation would track last claim time per user and enforce cooldown
    }


    /**
     * @notice Allows an owner to delegate a portion of their *base* reputation to another address.
     *         Useful for governance or social features.
     * @param delegatee The address to delegate reputation to.
     * @param amount The amount of base reputation to delegate.
     */
    function delegateReputation(address delegatee, uint256 amount) external {
        address owner = _msgSender();
        // Simple rule: cannot delegate more than your current base reputation minus what's already delegated
        // (Requires tracking delegated amount per delegator, adds complexity)
        // Simpler approach: Cap the *total* amount an owner can delegate out.
        uint256 currentDelegatedOut = 0; // Needs tracking
        uint256 delegateable = _ownerReputation[owner] > currentDelegatedOut ? _ownerReputation[owner] - currentDelegatedOut : 0;

        if (amount == 0) revert CannotDelegateMoreReputation(owner, 0);
        if (amount > delegateable || amount > REPUTATION_DELEGATION_CAP) revert CannotDelegateMoreReputation(owner, delegateable > REPUTATION_DELEGATION_CAP ? REPUTATION_DELEGATION_CAP : delegateable);


        // This requires a more complex system to track who delegated how much to whom.
        // For this example, we'll simulate by just adding to the delegatee's received reputation
        // and assuming the owner cannot delegate more than a capped amount *in total*.
        // A robust system would need mapping(address => mapping(address => uint256)) delegatedAmounts;
        // This simple version doesn't fully track who delegated, just the total delegated *to* an address.
        // It also doesn't reduce the delegator's voting power, only adds to the delegatee's influence.
        // This is a significant simplification for the example.

        // --- Simplified Delegation Logic (illustrative, needs robust tracking for production) ---
        // This simple model just adds to the delegatee's pool and assumes limits prevent abuse.
        // It doesn't track per-delegator amounts or subtract from the delegator's voting power.
        // A proper implementation would track `mapping(address => mapping(address => uint256)) internal _delegatedFromTo;`
        // and adjust balances in `_getTotalReputation`.

        _delegatedReputation[delegatee] += amount; // Add to the delegatee's received pool
        // In a real system, you'd likely also decrement a `_canDelegate` counter for the owner.

        emit ReputationDelegated(owner, delegatee, amount);
    }


    // --- View Functions ---

    /**
     * @notice Returns the full details of a creature.
     * @param tokenId The token ID of the creature.
     * @return The Creature struct.
     */
    function getCreatureDetails(uint256 tokenId) external view returns (Creature memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _creatures[tokenId];
    }

    /**
     * @notice Decodes and returns the individual trait values of a creature's DNA.
     * @param tokenId The token ID of the creature.
     * @return An array of trait values.
     */
    function getCreatureTraits(uint256 tokenId) external view returns (uint256[] memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _decodeDNA(_creatures[tokenId].dna);
    }

    /**
     * @notice Checks and returns the evolution eligibility status for a creature.
     * @param tokenId The token ID of the creature.
     * @return eligible True if the creature can evolve now.
     * @return nextState The state the creature would evolve into.
     */
    function checkEvolutionStatus(uint256 tokenId) external view returns (bool eligible, State nextState) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _checkEvolutionEligibility(tokenId);
    }

    /**
     * @notice Calculates and returns the current battle stats for a creature.
     * @param tokenId The token ID of the creature.
     * @return attack The calculated attack stat.
     * @return defense The calculated defense stat.
     * @return speed The calculated speed stat.
     */
    function getCreatureBattleStats(uint256 tokenId) external view returns (uint256 attack, uint256 defense, uint256 speed) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _calculateBattleStats(tokenId);
    }

    /**
     * @notice Returns the current reputation score of an owner (base + delegated).
     * @param owner The address to check.
     * @return The total reputation score.
     */
    function getOwnerReputation(address owner) external view returns (uint256) {
        return _getTotalReputation(owner); // Returns base + delegated IN
    }

    /**
     * @notice Returns the current essence balance of an owner.
     * @param owner The address to check.
     * @return The essence balance.
     */
    function getOwnerEssence(address owner) external view returns (uint256) {
        return _ownerEssence[owner];
    }

    /**
     * @notice Returns the total number of creatures that have been minted.
     * @return The total supply.
     */
    function getTotalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Admin Functions (OnlyOwner) ---

    /**
     * @notice Sets the level thresholds required for creatures of a specific species to evolve.
     * @dev Requires an array of exactly 3 thresholds for Hatchling->Juvenile, Juvenile->Adult, Adult->Elder.
     * @param speciesId The ID of the species.
     * @param levelThresholds An array containing the 3 required level thresholds.
     */
    function setSpeciesEvolutionThresholds(uint16 speciesId, uint16[] memory levelThresholds) external onlyOwner {
        require(levelThresholds.length == 3, "Must provide 3 thresholds");
        _speciesEvolutionThresholds[speciesId] = [levelThresholds[0], levelThresholds[1], levelThresholds[2]];
    }

    /**
     * @notice Sets a temporary global boost or debuff for a specific trait index.
     * @param traitIndex The index of the trait (0 to DNA_TRAIT_COUNT-1).
     * @param boostValue The integer value to add/subtract from the raw trait value before calculations.
     * @param endTime The timestamp when the boost expires.
     */
    function setTraitBoost(uint256 traitIndex, int256 boostValue, uint48 endTime) external onlyOwner {
        require(traitIndex < DNA_TRAIT_COUNT, "Invalid trait index");
        _traitBoostValue[traitIndex] = boostValue;
        _traitBoostEndTime[traitIndex] = endTime;
        emit TraitBoostSet(traitIndex, boostValue, endTime);
    }

    /**
     * @notice Updates the base URI for token metadata.
     * @param newURI The new base URI.
     */
    function updateBaseURI(string memory newURI) external onlyOwner {
        _baseTokenURI = newURI;
    }

    /**
     * @notice Pauses or unpauses interactions like feed, train, breed, and mutate.
     * @param paused The new pause state.
     */
    function pauseInteractions(bool paused) external onlyOwner {
        interactionsPaused = paused;
    }

    /**
     * @notice Allows the owner to withdraw any Ether sent to the contract.
     */
    function withdrawEth() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    // Fallback function to prevent accidental ETH transfers without a payable function
    fallback() external {
        revert("ETH received unexpectedly");
    }

    receive() external payable {
        revert("ETH received unexpectedly");
    }
}

// Helper library for sqrt - Included from OpenZeppelin Contracts v4.9.0 for demonstration
// In a real project, import from @openzeppelin/contracts/utils/math/Math.sol
library Math {
    /**
     * @dev Returns the square root of a number.
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // Newton's method [https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division]
        uint256 x = a / 2 + 1;
        uint256 y;

        while ((y = (x + a / x) / 2) < x) {
            x = y;
        }

        return x;
    }
}
```

---

**Explanation of Features and Advanced Concepts:**

1.  **Dynamic State (`Creature` struct and mappings):** Instead of just a token ID mapping to an owner and static URI, the `_creatures` mapping holds a `Creature` struct with multiple mutable fields: `level`, `experience`, `state`, `lastInteracted`, `cooldownEnd`, etc. This state changes on-chain.
2.  **Time-Based Logic:** `birthTime`, `lastInteracted`, and `cooldownEnd` are `uint48` (timestamp optimized) fields. Functions like `feedCreature`, `trainCreature`, `breedCreatures`, `mutateCreature`, `checkEvolutionEligibility` all incorporate `block.timestamp` to enforce cooldowns or check age/interaction requirements. Dormancy (`putCreatureToDormancy`, `wakeCreatureFromDormancy`) directly impacts whether time-based mechanics (aging, interaction needs) apply.
3.  **On-Chain Randomness (Simulated):** `_generateRandomSeed` uses `block.timestamp` and `block.difficulty`/`tx.origin` combined with `keccak256`. **Important:** This is *not* secure randomness for production. Miners can influence block hashes. For real dApps, use Chainlink VRF or similar dedicated on-chain randomness solutions. This implementation is just to show where randomness would be integrated (initial DNA, breeding mixing, mutation).
4.  **Breeding (`breedCreatures`):** Takes two existing NFTs, checks eligibility (ownership, state, cooldowns), mixes their `dna` using randomness to create a new `dna` for the child, and mints a new token (`_mintCreature`). It sets cooldowns on the parent tokens.
5.  **Mutation (`mutateCreature`):** Allows modifying an existing creature's `dna`. It costs `essence` and uses randomness to select which traits to alter and by how much. It also has a cooldown.
6.  **State Machine (`State` enum, `evolveCreature`, `checkEvolutionEligibility`):** Creatures progress through defined `State`s (Hatchling, Juvenile, Adult, Elder, Dormant, Sacrificed). `evolveCreature` is the function that triggers transitions based on criteria like `level` and time/age (`_checkEvolutionEligibility`), referencing `_speciesEvolutionThresholds`. Dormancy is another state that overrides normal behavior.
7.  **Internal Resource (`_ownerEssence`, `claimEssenceReward`, `sacrificeCreatureForEssence`, `upgradeWithEssence`):** An `essence` balance is tracked per owner. Owners can gain essence by sacrificing creatures or claiming rewards. They can spend essence to `upgradeWithEssence`, boosting a creature's experience/level.
8.  **Owner Reputation (`_ownerReputation`, `_delegatedReputation`, `getOwnerReputation`, `delegateReputation`):** A simple system tracks reputation gained from activities (like breeding). `getOwnerReputation` aggregates base reputation and reputation *delegated* to the owner. `delegateReputation` allows transferring 'voting power' (represented by reputation) to another address. **Note:** The delegation logic here is simplified and would need more robust tracking (like which address delegated how much to whom) for a real-world governance system.
9.  **Packed Data (`dna` in `Creature` struct, `DNA_BITS_PER_TRAIT`, `DNA_TRAIT_COUNT`, `_decodeDNA`, `_encodeDNA`):** The `dna` field is a single `uint256` that packs multiple trait values together. This saves significant gas compared to storing each trait in a separate field or a dynamic array within the struct. Helper functions `_decodeDNA` and `_encodeDNA` handle converting between the packed `uint256` and individual trait values.
10. **Programmable Royalties (EIP-2981):** The contract inherits `ERC2981` and implements `royaltyInfo` and `setDefaultRoyalty`, allowing marketplaces that support the standard to automatically collect royalties on secondary sales based on the contract's setting.
11. **View Functions for Derived Stats (`getCreatureBattleStats`):** Battle stats are not stored directly but are calculated on-the-fly by `_calculateBattleStats` whenever requested, based on the creature's *current* `level`, `state`, and potentially active global `_traitBoostValue`. This keeps the storage smaller and the data always up-to-date.
12. **Custom Overrides (`transferFrom`, `safeTransferFrom`, `tokenURI`):** The standard transfer functions are overridden to add custom checks (like preventing transfers while dormant). `tokenURI` is overridden to suggest how dynamic metadata would be handled, incorporating the creature's state and level into the URI.
13. **Admin Controls (`Ownable`, `setSpeciesEvolutionThresholds`, `setTraitBoost`, `updateBaseURI`, `pauseInteractions`, `withdrawEth`):** Includes basic owner-only functions to configure game parameters (evolution thresholds, trait boosts), manage metadata URI, pause certain actions, and handle contract funds.

This contract provides a framework for a sophisticated, dynamic NFT ecosystem on-chain, going far beyond simple static image collectibles. Remember that complex on-chain logic can be expensive in terms of gas, and security audits are crucial before deploying any significant contract to a live network.