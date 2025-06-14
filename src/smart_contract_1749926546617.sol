Okay, here is a Solidity smart contract incorporating several interesting, advanced, and creative concepts beyond standard tokens or simple NFTs. It represents a system of "Evolving On-Chain Entities" (EOEs) that possess dynamic attributes, can evolve, be staked for yield, gain soul-bound traits, and even delegate management of specific traits.

This contract aims for novelty by combining several mechanics:
1.  **Dynamic NFTs:** Attributes stored on-chain change based on interactions (`feed`, `rest`, `evolve`).
2.  **On-Chain Evolution/Mutation:** Entities can attempt to evolve or mutate, changing attributes based on internal state and simulated randomness (using `blockhash`, with necessary disclaimers).
3.  **Staking with Dynamic Yield:** Entities can be staked, and the yield they generate might depend on their attributes.
4.  **Soul-Bound Traits:** Certain milestones or actions allow permanently binding specific attributes to the owner, making them non-transferable even if the NFT is sold (requires off-chain interpretation for rendering, but the data is bound on-chain).
5.  **Trait Delegation:** Owners can delegate the ability to modify a *specific* dynamic attribute to another address.
6.  **Time-Sensitive Traits:** Attributes that decay or expire after a certain number of blocks.
7.  **On-Chain State Hashing:** Generate a unique hash representing the *current* dynamic state of an entity for verification or off-chain rendering checks.

---

**Smart Contract: EvolvingOnChainEntities (EOE)**

**Overview:**
This contract implements an ERC721 standard for unique digital entities. Unlike typical NFTs, these entities have complex state stored on-chain that changes over time and through interaction. Key features include:
*   Dynamic attributes that influence evolution, staking yield, etc.
*   Mechanisms for entities to "evolve", "feed", and "rest", consuming or gaining resources and potentially altering attributes.
*   A "catalysis" process allowing interaction between entities for potential mutations.
*   Staking functionality to earn abstract "yield" (representing in-system resources or influence).
*   Ability to bind certain attributes permanently to the owner's interaction history (soul-bound concept).
*   Management of time-sensitive traits.
*   Delegation of specific trait management rights.
*   Functions to query the complex state of entities.

**Outline:**

1.  **Imports:** ERC721 standard, Ownable.
2.  **Events:** Signaling minting, transfers, evolution, staking, trait changes, etc.
3.  **Errors:** Custom error types for clarity.
4.  **Structs & Enums:** Define data structures for entity attributes (dynamic & soul-bound), staking info, trait types.
5.  **Constants & State Variables:** Contract metadata, evolution/staking parameters, mappings for entity data.
6.  **Access Control:** Using `Ownable` for administrative functions.
7.  **ERC721 Standard Implementation:** Core NFT functions (`balanceOf`, `ownerOf`, `transferFrom`, `tokenURI`, etc.). `tokenURI` should point to dynamic metadata.
8.  **Core Entity Logic:**
    *   `_generateInitialAttributes`: Internal function to create starting attributes (uses pseudo-randomness).
    *   `mint`: Creates and initializes a new entity.
    *   `burn`: Destroys an entity.
9.  **Dynamic Interaction & Evolution Logic:**
    *   `feed`: Increases entity energy/nourishment.
    *   `rest`: Recovers entity state, potentially enabling evolution.
    *   `evolve`: Attempts to trigger evolution based on state and randomness.
    *   `catalyze`: Attempts catalysis between two entities for potential mutations/trait transfers.
    *   `_simulateEvolution`: Internal logic for attribute changes during evolution.
    *   `_simulateCatalysis`: Internal logic for catalysis outcome.
10. **Staking Logic:**
    *   `stake`: Locks an entity for staking.
    *   `unstake`: Unlocks a staked entity.
    *   `claimYield`: Claims accumulated staking yield.
    *   `_calculateYield`: Internal function to calculate yield based on attributes/time.
11. **Soul-Binding Logic:**
    *   `updateSoulBoundAttribute`: Sets a permanent soul-bound trait under specific conditions.
    *   `_canSetSoulBoundAttribute`: Internal check for soul-binding conditions.
12. **Time-Sensitive Trait Logic:**
    *   `setTimeSensitiveTrait`: Applies a temporary trait.
    *   `_isTraitActive`: Internal check if a time-sensitive trait is still active.
13. **Trait Delegation Logic:**
    *   `delegateTraitOwnership`: Allows an address to manage a specific trait.
    *   `revokeTraitOwnership`: Removes delegation.
    *   `_isTraitDelegatee`: Internal check for delegation rights.
14. **Utility & View Functions:**
    *   `getAttributes`: Retrieves all entity attributes.
    *   `getDynamicAttributes`: Retrieves only dynamic attributes.
    *   `getSoulBoundAttributes`: Retrieves only soul-bound attributes.
    *   `getStakingInfo`: Retrieves staking status and yield.
    *   `getTimeSensitiveTraits`: Retrieves active time-sensitive traits.
    *   `getTraitDelegatee`: Retrieves the delegatee for a specific trait.
    *   `getCurrentStateHash`: Generates a hash of the current dynamic state.
    *   `getVersion`: Gets the evolution version/count.
    *   `getTotalStaked`: Gets total number of currently staked entities.
    *   `getOwnerStakedTokens`: Gets the list of tokens staked by an owner.
15. **Admin Functions:**
    *   `setBaseURI`: Sets the base URI for token metadata.
    *   `updateEvolutionRules`: Modify evolution parameters.
    *   `updateCatalysisRules`: Modify catalysis parameters.
    *   `pauseEvolution`: Pause evolution attempts for a specific token.
    *   `unpauseEvolution`: Unpause evolution attempts.

**Function Summary (Total Unique + Standard ERC721: ~35+ functions):**

*   **ERC721 Standard Functions (Required & Overridden):**
    *   `constructor(string name, string symbol)`: Initializes the contract with name and symbol.
    *   `balanceOf(address owner)`: Returns the number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of a token ID.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers token ownership.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers token ownership.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership (less safe than `safeTransferFrom`).
    *   `approve(address to, uint256 tokenId)`: Grants approval to another address to transfer a specific token.
    *   `getApproved(uint256 tokenId)`: Returns the approved address for a token.
    *   `setApprovalForAll(address operator, bool approved)`: Grants or revokes approval for an operator to manage all tokens of the caller.
    *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner.
    *   `tokenURI(uint256 tokenId)`: (Overridden) Returns the URI for the token metadata, incorporating the dynamic state.
    *   `name()`: Returns the contract name.
    *   `symbol()`: Returns the contract symbol.
    *   `totalSupply()`: (Optional, but common) Returns the total number of tokens minted.

*   **Core Entity & Dynamic Interaction Functions:**
    *   `mint()`: Creates a new entity with randomized initial attributes and assigns it to the caller.
    *   `burn(uint256 tokenId)`: Destroys an entity (requires owner or approved).
    *   `feed(uint256 tokenId, uint8 amount)`: Increases the energy/nourishment of an entity. Caller must own or be approved/delegatee for relevant traits.
    *   `rest(uint256 tokenId)`: Allows an entity to rest, potentially recovering state and enabling evolution conditions. Caller must own or be approved.
    *   `evolve(uint256 tokenId)`: Attempts to evolve the entity based on its state (`energy`, `restStatus`, `lastEvolveTime`) and simulated randomness. Changes dynamic attributes. Caller must own or be approved.
    *   `catalyze(uint256 tokenId1, uint256 tokenId2)`: Attempts a catalytic interaction between two entities. Might transfer traits, cause mutations, or have other effects based on rules and randomness. Callers must own or be approved for *both* tokens.

*   **Staking Functions:**
    *   `stake(uint256 tokenId)`: Stakes the entity, making it non-transferable and starting yield accumulation. Caller must own the token.
    *   `unstake(uint256 tokenId)`: Unstakes the entity, making it transferable again and stopping yield accumulation. Caller must own the token.
    *   `claimYield(uint256 tokenId)`: Claims the accumulated abstract yield for a staked entity. Caller must own the token.

*   **Soul-Binding Functions:**
    *   `updateSoulBoundAttribute(uint256 tokenId, uint8 attributeType, uint8 value)`: Attempts to set a soul-bound attribute. Success depends on internal contract logic (e.g., meeting evolution level, achieving state). Can only be called by the owner and can usually only be set *once* per soul-bound attribute type.

*   **Time-Sensitive Trait Functions:**
    *   `setTimeSensitiveTrait(uint256 tokenId, uint8 traitType, uint256 durationBlocks, uint8 value)`: Applies a temporary trait to an entity that expires after `durationBlocks`. Callable by owner/approved/delegatee.
    *   `_isTraitActive(uint256 tokenId, uint8 traitType)`: (Internal/Helper) Checks if a given time-sensitive trait is currently active.

*   **Trait Delegation Functions:**
    *   `delegateTraitOwnership(uint256 tokenId, address delegatee, uint8 traitType)`: Allows the owner of `tokenId` to grant `delegatee` permission to call functions that modify `traitType` (e.g., `feed` if linked to energy).
    *   `revokeTraitOwnership(uint256 tokenId, uint8 traitType)`: Revokes a previously set trait delegation. Only callable by the owner.

*   **View & Utility Functions:**
    *   `getAttributes(uint256 tokenId)`: Returns a tuple or struct containing all dynamic and soul-bound attributes for an entity.
    *   `getDynamicAttributes(uint256 tokenId)`: Returns only the dynamic attributes.
    *   `getSoulBoundAttributes(uint256 tokenId)`: Returns only the soul-bound attributes.
    *   `getStakingInfo(uint256 tokenId)`: Returns the staking status, start time, and accumulated yield for an entity.
    *   `getTimeSensitiveTraits(uint256 tokenId)`: Returns active time-sensitive traits and their expiry blocks.
    *   `getTraitDelegatee(uint256 tokenId, uint8 traitType)`: Returns the address delegated for a specific trait type on an entity.
    *   `getCurrentStateHash(uint256 tokenId)`: Generates a unique hash summarizing the *current dynamic state* of the entity (attributes, staking status, version). Useful for verifying off-chain representations.
    *   `getVersion(uint256 tokenId)`: Returns the evolution/mutation count of an entity.
    *   `getTotalStaked()`: Returns the total number of entities currently staked across all owners.
    *   `getOwnerStakedTokens(address owner)`: Returns an array of token IDs currently staked by a specific owner.

*   **Admin Functions (Owner-Only):**
    *   `setBaseURI(string memory baseURI_)`: Sets the base URI for token metadata, allowing off-chain servers to serve dynamic metadata based on the token's state.
    *   `updateEvolutionRules(...)`: Allows the owner to adjust parameters governing the evolution process (e.g., required energy, rest duration, success chance).
    *   `updateCatalysisRules(...)`: Allows the owner to adjust parameters for the catalysis process (e.g., trait transfer chance, mutation chance).
    *   `pauseEvolution(uint256 tokenId)`: Temporarily prevents a specific entity from being evolved.
    *   `unpauseEvolution(uint256 tokenId)`: Re-enables evolution for a specific entity.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Consider using latest checked arithmetic instead

// Note: Using block.timestamp and block.difficulty/blockhash for "randomness" is INSECURE
// in real-world applications as miners can manipulate it. For true randomness,
// use Chainlink VRF or similar oracle services. This is for demonstration purposes.

/**
 * @title EvolvingOnChainEntities (EOE)
 * @dev A creative ERC721 implementation where entities have dynamic on-chain state,
 *      can evolve, be staked for dynamic yield, gain soul-bound traits,
 *      manage time-sensitive traits, and delegate trait management.
 */
contract EvolvingOnChainEntities is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Structs & Enums ---

    enum TraitType {
        None,
        Energy,
        RestStatus,
        Strength,
        Agility,
        Intelligence,
        Resilience,
        // Add more dynamic traits as needed
        BoundTraitA, // Example soul-bound trait
        BoundTraitB  // Example soul-bound trait
        // Add more soul-bound traits
    }

    struct EntityAttributes {
        // Dynamic Attributes (Change over time/interaction)
        uint8 energy;       // Affects ability to perform actions, evolution chance
        uint8 restStatus;   // Affects evolution readiness, state recovery
        uint8 strength;     // Influences yield, catalysis outcomes
        uint8 agility;      // Influences yield, catalysis outcomes
        uint8 intelligence; // Influences yield, catalysis outcomes
        uint8 resilience;   // Affects resistance to negative events

        // Internal State Variables
        uint256 lastEvolveTime; // Timestamp/Block number of last evolution attempt
        uint256 lastRestTime;   // Timestamp/Block number of last rest action
        uint256 lastFeedTime;   // Timestamp/Block number of last feed action
        uint256 version;        // Counts successful evolutions/mutations
    }

    struct SoulBoundAttributes {
        uint8 boundTraitA; // Permanent trait linked to owner history/achievements
        uint8 boundTraitB; // Permanent trait linked to owner history/achievements
        // Flags indicating if soul-bound traits have been set
        bool isBoundTraitASet;
        bool isBoundTraitBSet;
    }

    struct StakingInfo {
        bool isStaked;
        uint256 stakeStartTime; // Timestamp/Block number when staked
        uint256 yieldAccumulated; // Abstract yield accumulated
    }

    struct TimeSensitiveTrait {
        uint8 value;          // Value of the temporary trait
        uint256 expiryBlock;  // Block number when the trait expires
    }

    // --- State Variables ---

    // Mappings to store entity data
    mapping(uint256 => EntityAttributes) private _entityAttributes;
    mapping(uint256 => SoulBoundAttributes) private _soulBoundAttributes;
    mapping(uint256 => StakingInfo) private _stakingInfo;
    // Mapping for time-sensitive traits: tokenId -> TraitType -> TimeSensitiveTrait
    mapping(uint256 => mapping(uint8 => TimeSensitiveTrait)) private _timeSensitiveTraits;
    // Mapping for trait delegation: tokenId -> TraitType -> Delegatee Address
    mapping(uint256 => mapping(uint8 => address)) private _traitDelegates;

    // Mapping to track staked tokens per owner for gas-efficient querying
    mapping(address => uint256[]) private _stakedTokensByOwner;
    mapping(uint256 => uint256) private _stakedTokenIndexInOwnerArray; // For removal tracking

    uint256 private _totalStaked; // Total count of staked tokens

    string private _baseTokenURI; // Base URI for dynamic metadata

    // Evolution & Catalysis Rules (Simplistic examples)
    uint8 public minEnergyForEvolution = 50;
    uint8 public minRestStatusForEvolution = 80;
    uint256 public blocksNeededSinceLastEvolution = 100;
    uint256 public blocksNeededSinceLastRest = 50;
    uint256 public yieldPerBlockBase = 1; // Abstract yield units per block

    mapping(uint256 => bool) private _isEvolutionPaused; // Per-token evolution pause

    // --- Events ---

    event EntityMinted(uint256 indexed tokenId, address indexed owner, EntityAttributes initialAttributes);
    event EntityBurned(uint256 indexed tokenId);
    event EntityFed(uint256 indexed tokenId, uint8 amount, uint8 newEnergy);
    event EntityRested(uint256 indexed tokenId, uint8 newRestStatus);
    event EntityEvolved(uint256 indexed tokenId, uint256 newVersion, EntityAttributes newAttributes);
    event CatalysisAttempt(uint256 indexed tokenId1, uint256 indexed tokenId2, bool success, string outcome);
    event EntityStaked(uint256 indexed tokenId, address indexed owner);
    event EntityUnstaked(uint256 indexed tokenId, address indexed owner, uint256 yieldClaimed);
    event YieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event SoulBoundAttributeSet(uint256 indexed tokenId, address indexed owner, TraitType indexed attributeType, uint8 value);
    event TimeSensitiveTraitSet(uint256 indexed tokenId, TraitType indexed traitType, uint8 value, uint256 expiryBlock);
    event TraitOwnershipDelegated(uint256 indexed tokenId, TraitType indexed traitType, address indexed delegatee);
    event TraitOwnershipRevoked(uint256 indexed tokenId, TraitType indexed traitType, address indexed previousDelegatee);
    event EvolutionPaused(uint256 indexed tokenId);
    event EvolutionUnpaused(uint256 indexed tokenId);

    // --- Errors ---

    error EOE_InvalidTokenId();
    error EOE_NotTokenOwnerOrApproved();
    error EOE_TokenIsStaked();
    error EOE_TokenIsNotStaked();
    error EOE_CannotEvolveYet();
    error EOE_EvolutionPaused();
    error EOE_NotEnoughEnergy();
    error EOE_NotEnoughRest();
    error EOE_CatalysisFailed();
    error EOE_SoulBoundAttributeAlreadySet();
    error EOE_CannotSetSoulBoundAttributeYet();
    error EOE_NotTraitDelegatee();
    error EOE_CannotBurnStakedToken();


    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Initial rules could be set here or via owner function later
    }

    // --- Access Control Modifiers ---

    modifier whenNotStaked(uint256 tokenId) {
        if (_stakingInfo[tokenId].isStaked) revert EOE_TokenIsStaked();
        _;
    }

    modifier whenStaked(uint256 tokenId) {
        if (!_stakingInfo[tokenId].isStaked) revert EOE_TokenIsNotStaked();
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender() && !isApprovedForAll(ownerOf(tokenId), _msgSender()) && getApproved(tokenId) != _msgSender()) {
             revert EOE_NotTokenOwnerOrApproved();
        }
        _;
    }

    modifier onlyTokenOwnerApprovedOrDelegatee(uint256 tokenId, TraitType traitType) {
         address currentOwner = ownerOf(tokenId);
         if (currentOwner != _msgSender() &&
             !isApprovedForAll(currentOwner, _msgSender()) &&
             getApproved(tokenId) != _msgSender() &&
             _traitDelegates[tokenId][uint8(traitType)] != _msgSender()
            ) {
             revert EOE_NotTokenOwnerOrApproved(); // Or a more specific delegatee error
         }
         _;
    }


    // --- ERC721 Standard Implementation (Overridden) ---

    // The rest of the standard ERC721 functions (balanceOf, ownerOf, etc.) are
    // inherited from the OpenZeppelin contract. We only override `tokenURI`
    // to make it dynamic.

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns a dynamic URI pointing to metadata that reflects the entity's current state.
     * Assumes the base URI points to a service that can handle /<tokenID> requests
     * and potentially query the contract for state.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        string memory base = _baseTokenURI;
        // If the base URI is not set, return empty string or default error URI
        if (bytes(base).length == 0) {
            return ""; // Or return a default URI indicating dynamic data
        }
        // Append token ID to the base URI
        return string(abi.encodePacked(base, _toString(tokenId)));
    }

    // --- Core Entity Logic ---

    /**
     * @dev Internal function to generate initial attributes for a new entity.
     * Uses pseudo-randomness based on block data.
     */
    function _generateInitialAttributes(uint256 tokenId) internal view returns (EntityAttributes memory) {
        // WARNING: Pseudo-randomness from block data is not secure or truly random.
        // For production, use a verifiable random function (VRF) like Chainlink VRF.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, _msgSender(), tokenId)));

        // Basic scaling based on seed for initial stats
        uint8 initialEnergy = uint8((randomSeed % 50) + 50); // 50-99
        uint8 initialRestStatus = uint8((randomSeed * 2 % 50) + 50); // 50-99
        uint8 initialStrength = uint8((randomSeed * 3 % 20) + 1);    // 1-20
        uint8 initialAgility = uint8((randomSeed * 4 % 20) + 1);     // 1-20
        uint8 initialIntelligence = uint8((randomSeed * 5 % 20) + 1); // 1-20
        uint8 initialResilience = uint8((randomSeed * 6 % 20) + 1);  // 1-20

        return EntityAttributes({
            energy: initialEnergy,
            restStatus: initialRestStatus,
            strength: initialStrength,
            agility: initialAgility,
            intelligence: initialIntelligence,
            resilience: initialResilience,
            lastEvolveTime: block.number, // Initialize to current block to prevent immediate evolution
            lastRestTime: block.number,
            lastFeedTime: block.number,
            version: 0
        });
    }

    /**
     * @dev Mints a new Evolving On-Chain Entity.
     * @return The ID of the newly minted token.
     */
    function mint() public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);

        // Generate and store initial attributes
        _entityAttributes[newItemId] = _generateInitialAttributes(newItemId);

        // Initialize soul-bound attributes (all unset)
        _soulBoundAttributes[newItemId] = SoulBoundAttributes(0, 0, false, false);

        // Initialize staking info
        _stakingInfo[newItemId] = StakingInfo(false, 0, 0);

        emit EntityMinted(newItemId, msg.sender, _entityAttributes[newItemId]);

        return newItemId;
    }

    /**
     * @dev Destroys an Evolving On-Chain Entity.
     * Requires the caller to be the token owner or approved.
     * Cannot burn staked tokens.
     */
    function burn(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        _burn(tokenId);
        // Clean up associated data (Solidity mappings don't need explicit deletion,
        // but setting to default state can be good practice for clarity/gas when complex)
        // delete _entityAttributes[tokenId]; // Data persists unless overwritten or deleted
        // delete _soulBoundAttributes[tokenId];
        // delete _stakingInfo[tokenId];
        // delete _timeSensitiveTraits[tokenId]; // Requires iterating inner map keys - complex/gas intensive
        // delete _traitDelegates[tokenId]; // Requires iterating inner map keys - complex/gas intensive

        emit EntityBurned(tokenId);
    }

    // --- Dynamic Interaction & Evolution Logic ---

    /**
     * @dev Feeds the entity, increasing its energy.
     * Caller must own or be approved, or be delegated energy trait management.
     * @param tokenId The ID of the entity.
     * @param amount The amount of energy to add (e.g., 1-10).
     */
    function feed(uint256 tokenId, uint8 amount) public onlyTokenOwnerApprovedOrDelegatee(tokenId, TraitType.Energy) whenNotStaked(tokenId) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();

        EntityAttributes storage entity = _entityAttributes[tokenId];
        entity.energy = SafeMath.min(entity.energy + amount, 100); // Cap energy at 100
        entity.lastFeedTime = block.number;

        emit EntityFed(tokenId, amount, entity.energy);
    }

     /**
     * @dev Allows the entity to rest, potentially recovering state and enabling evolution conditions.
     * Also recalculates yield if staked (handled internally by `_calculateYield`).
     * Caller must own or be approved.
     * @param tokenId The ID of the entity.
     */
    function rest(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();

        EntityAttributes storage entity = _entityAttributes[tokenId];

        // Recover rest status based on time since last rest
        uint256 blocksSinceLastRest = block.number - entity.lastRestTime;
        uint8 restRecovery = uint8(SafeMath.min(blocksSinceLastRest, 100)); // Simplified recovery

        entity.restStatus = SafeMath.min(entity.restStatus + restRecovery, 100); // Cap restStatus at 100
        entity.lastRestTime = block.number;

        // If staked, update yield before changing state that might affect future yield
        if (_stakingInfo[tokenId].isStaked) {
             _calculateYield(tokenId);
        }

        emit EntityRested(tokenId, entity.restStatus);
    }


    /**
     * @dev Attempts to trigger evolution for an entity.
     * Requires sufficient energy, rest status, and time elapsed since last attempt.
     * Outcome depends on internal state and simulated randomness.
     * Caller must own or be approved. Evolution can be paused by admin.
     * @param tokenId The ID of the entity.
     */
    function evolve(uint256 tokenId) public onlyTokenOwnerOrApproved(tokenId) whenNotStaked(tokenId) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        if (_isEvolutionPaused[tokenId]) revert EOE_EvolutionPaused();

        EntityAttributes storage entity = _entityAttributes[tokenId];

        // Check evolution conditions
        if (entity.energy < minEnergyForEvolution) revert EOE_NotEnoughEnergy();
        if (entity.restStatus < minRestStatusForEvolution) revert EOE_NotEnoughRest();
        if (block.number - entity.lastEvolveTime < blocksNeededSinceLastEvolution) revert EOE_CannotEvolveYet();

        // Consume resources
        entity.energy = SafeMath.sub(entity.energy, minEnergyForEvolution / 2); // Consume half required energy
        entity.restStatus = SafeMath.sub(entity.restStatus, minRestStatusForEvolution / 2); // Consume half required rest
        entity.lastEvolveTime = block.number; // Update last attempt time

        // --- Simulate Evolution Outcome (Uses insecure randomness) ---
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, tokenId, block.number)));
        uint256 evolutionChance = (uint256(entity.energy) + uint256(entity.restStatus) + uint256(entity.strength) + uint256(entity.agility) + uint256(entity.intelligence) + uint256(entity.resilience)) / 10; // Example: sum of stats/10% chance

        if ((randomSeed % 100) < evolutionChance) {
            // Evolution successful!
            entity.version++;
            _simulateEvolution(tokenId, randomSeed); // Apply attribute changes
            emit EntityEvolved(tokenId, entity.version, entity);
        } else {
            // Evolution failed, but resources are still consumed
            emit CatalysisAttempt(tokenId, 0, false, "Evolution attempt failed"); // Reusing event for lack of specific evolution-fail event
        }
    }

    /**
     * @dev Internal helper to simulate attribute changes during evolution.
     * Uses pseudo-randomness to slightly adjust stats.
     */
    function _simulateEvolution(uint256 tokenId, uint256 randomSeed) internal {
         EntityAttributes storage entity = _entityAttributes[tokenId];

         // Apply random stat changes (small increments/decrements)
         // Values are capped at 100 for dynamic traits
         if (randomSeed % 6 == 0) entity.energy = SafeMath.min(entity.energy + uint8(randomSeed % 5), 100);
         if (randomSeed % 6 == 1) entity.restStatus = SafeMath.min(entity.restStatus + uint8(randomSeed % 5), 100);
         if (randomSeed % 6 == 2) entity.strength = SafeMath.min(entity.strength + uint8(randomSeed % 3), 100);
         if (randomSeed % 6 == 3) entity.agility = SafeMath.min(entity.agility + uint8(randomSeed % 3), 100);
         if (randomSeed % 6 == 4) entity.intelligence = SafeMath.min(entity.intelligence + uint8(randomSeed % 3), 100);
         if (randomSeed % 6 == 5) entity.resilience = SafeMath.min(entity.resilience + uint8(randomSeed % 3), 100);

         // Some stats might decrease randomly too
         if (randomSeed % 10 < 2) entity.energy = SafeMath.max(entity.energy, uint8(randomSeed % 5)); // min 0, or some base
         if (randomSeed % 10 < 3) entity.strength = SafeMath.max(entity.strength, uint8(randomSeed % 2));
    }

    /**
     * @dev Attempts a catalytic interaction between two entities.
     * Might transfer traits, cause mutations, or have other effects.
     * Requires caller to own or be approved for *both* tokens.
     * Outcome depends on combined state and simulated randomness.
     * @param tokenId1 The ID of the first entity.
     * @param tokenId2 The ID of the second entity.
     */
    function catalyze(uint256 tokenId1, uint256 tokenId2) public {
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert EOE_InvalidTokenId();
        // Ensure caller owns/approved both
        onlyTokenOwnerOrApproved(tokenId1);
        onlyTokenOwnerOrApproved(tokenId2);
        whenNotStaked(tokenId1); // Catalysis cannot happen if staked
        whenNotStaked(tokenId2);

        // Prevent catalysis with self
        if (tokenId1 == tokenId2) revert EOE_CatalysisFailed(); // Or a specific error

        EntityAttributes storage entity1 = _entityAttributes[tokenId1];
        EntityAttributes storage entity2 = _entityAttributes[tokenId2];

        // Basic catalysis conditions (example: requires combined minimum stats)
        uint256 combinedEnergy = uint256(entity1.energy) + uint256(entity2.energy);
        uint256 combinedRest = uint256(entity1.restStatus) + uint256(entity2.restStatus);

        if (combinedEnergy < 100 || combinedRest < 100) revert EOE_CatalysisFailed();

        // Consume resources (example)
        entity1.energy = SafeMath.sub(entity1.energy, uint8(combinedEnergy / 4));
        entity2.energy = SafeMath.sub(entity2.energy, uint8(combinedEnergy / 4));
        entity1.restStatus = SafeMath.sub(entity1.restStatus, uint8(combinedRest / 4));
        entity2.restStatus = SafeMath.sub(entity2.restStatus, uint8(combinedRest / 4));

        // --- Simulate Catalysis Outcome (Uses insecure randomness) ---
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, tokenId1, tokenId2, block.number)));
        uint256 catalysisChance = (combinedEnergy + combinedRest) / 5; // Example chance calculation

        if ((randomSeed % 100) < catalysisChance) {
            // Catalysis successful!
            _simulateCatalysis(tokenId1, tokenId2, randomSeed);
            emit CatalysisAttempt(tokenId1, tokenId2, true, "Catalysis successful");
        } else {
            // Catalysis failed, resources consumed
            emit CatalysisAttempt(tokenId1, tokenId2, false, "Catalysis failed");
        }
    }

     /**
     * @dev Internal helper to simulate attribute changes during catalysis.
     * Can involve trait transfer or mutation.
     */
    function _simulateCatalysis(uint256 tokenId1, uint256 tokenId2, uint256 randomSeed) internal {
         EntityAttributes storage entity1 = _entityAttributes[tokenId1];
         EntityAttributes storage entity2 = _entityAttributes[tokenId2];

         // Example: Randomly transfer a trait from entity2 to entity1 or mutate one
         uint256 outcomeType = randomSeed % 3; // 0: Transfer, 1: Mutate 1, 2: Mutate 2

         if (outcomeType == 0) { // Trait Transfer (e.g., Agility from 2 to 1)
             entity1.agility = SafeMath.min(entity1.agility + uint8(randomSeed % (entity2.agility / 2 + 1)), 100);
             emit CatalysisAttempt(tokenId1, tokenId2, true, "Agility partial transfer");
         } else if (outcomeType == 1) { // Mutate Entity 1
             uint8 mutateAmount = uint8(randomSeed % 5);
             uint8 statIndex = uint8((randomSeed / 10) % 4); // Choose Strength, Agility, Intelligence, Resilience
             if (statIndex == 0) entity1.strength = SafeMath.min(entity1.strength + mutateAmount, 100);
             else if (statIndex == 1) entity1.agility = SafeMath.min(entity1.agility + mutateAmount, 100);
             else if (statIndex == 2) entity1.intelligence = SafeMath.min(entity1.intelligence + mutateAmount, 100);
             else if (statIndex == 3) entity1.resilience = SafeMath.min(entity1.resilience + mutateAmount, 100);
              emit CatalysisAttempt(tokenId1, tokenId2, true, "Entity 1 mutated");
         } else { // Mutate Entity 2
              uint8 mutateAmount = uint8(randomSeed % 5);
              uint8 statIndex = uint8((randomSeed / 10) % 4); // Choose Strength, Agility, Intelligence, Resilience
              if (statIndex == 0) entity2.strength = SafeMath.min(entity2.strength + mutateAmount, 100);
              else if (statIndex == 1) entity2.agility = SafeMath.min(entity2.agility + mutateAmount, 100);
              else if (statIndex == 2) entity2.intelligence = SafeMath.min(entity2.intelligence + mutateAmount, 100);
              else if (statIndex == 3) entity2.resilience = SafeMath.min(entity2.resilience + mutateAmount, 100);
               emit CatalysisAttempt(tokenId1, tokenId2, true, "Entity 2 mutated");
         }
         entity1.version++; // Both entities potentially gain a version count from interaction
         entity2.version++;
    }

    // --- Staking Logic ---

    /**
     * @dev Stakes an entity, making it non-transferable and starting yield accumulation.
     * Requires caller to be the token owner.
     * @param tokenId The ID of the entity.
     */
    function stake(uint256 tokenId) public onlyTokenOwner(tokenId) whenNotStaked(tokenId) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();

        StakingInfo storage staking = _stakingInfo[tokenId];
        staking.isStaked = true;
        staking.stakeStartTime = block.number; // Use block number for yield calculation
        staking.yieldAccumulated = 0; // Reset yield on new stake

        _totalStaked++;

        // Add token to owner's staked list for efficient querying
        _stakedTokensByOwner[msg.sender].push(tokenId);
        _stakedTokenIndexInOwnerArray[tokenId] = _stakedTokensByOwner[msg.sender].length - 1;


        // Standard ERC721 functions like transferFrom should now check `isStaked` modifier

        emit EntityStaked(tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an entity, making it transferable again and stopping yield accumulation.
     * Calculates and adds final yield before unstaking.
     * Requires caller to be the token owner.
     * @param tokenId The ID of the entity.
     */
    function unstake(uint256 tokenId) public onlyTokenOwner(tokenId) whenStaked(tokenId) {
         if (!_exists(tokenId)) revert EOE_InvalidTokenId();

        // Calculate and add pending yield
        _calculateYield(tokenId);

        StakingInfo storage staking = _stakingInfo[tokenId];
        uint256 totalYieldClaimed = staking.yieldAccumulated; // Store before resetting

        staking.isStaked = false;
        staking.stakeStartTime = 0; // Reset
        staking.yieldAccumulated = 0; // Reset yield

        _totalStaked--;

        // Remove token from owner's staked list
        uint256 lastTokenIndex = _stakedTokensByOwner[msg.sender].length - 1;
        uint256 tokenToRemoveIndex = _stakedTokenIndexInOwnerArray[tokenId];

        // Move the last token to the place of the token to remove
        if (tokenToRemoveIndex != lastTokenIndex) {
            uint256 lastTokenId = _stakedTokensByOwner[msg.sender][lastTokenIndex];
            _stakedTokensByOwner[msg.sender][tokenToRemoveIndex] = lastTokenId;
            _stakedTokenIndexInOwnerArray[lastTokenId] = tokenToRemoveIndex;
        }
        // Remove the last element
        _stakedTokensByOwner[msg.sender].pop();
        delete _stakedTokenIndexInOwnerArray[tokenId];


        // Note: This example assumes abstract yield. For a real token yield,
        // you would transfer a separate yield token here.
        // Example: externalYieldToken.transfer(msg.sender, totalYieldClaimed);

        emit EntityUnstaked(tokenId, msg.sender, totalYieldClaimed);
    }

    /**
     * @dev Claims the accumulated abstract yield for a staked entity.
     * Calculates and adds pending yield to the total accumulated.
     * Requires caller to be the token owner.
     * @param tokenId The ID of the entity.
     */
    function claimYield(uint256 tokenId) public onlyTokenOwner(tokenId) whenStaked(tokenId) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();

        uint256 yieldClaimed = _calculateYield(tokenId); // Calculate and add to accumulated

        // Note: This example assumes abstract yield that is stored and claimed.
        // For a real token yield, you would transfer the yield amount here
        // and potentially reset the accumulated yield if claimed frequently.
        // Example: externalYieldToken.transfer(msg.sender, yieldClaimed);

        emit YieldClaimed(tokenId, msg.sender, yieldClaimed);
    }

    /**
     * @dev Internal helper to calculate potential yield since last update
     * and add it to the accumulated amount. Yield is based on blocks elapsed
     * and potentially entity attributes (example: Strength + Agility).
     * @param tokenId The ID of the entity.
     * @return The amount of yield calculated and added in this call.
     */
    function _calculateYield(uint256 tokenId) internal returns (uint256) {
        StakingInfo storage staking = _stakingInfo[tokenId];
        if (!staking.isStaked || block.number <= staking.stakeStartTime) {
            return 0;
        }

        uint256 blocksElapsed = block.number - staking.stakeStartTime;
        staking.stakeStartTime = block.number; // Update stake start to current block

        EntityAttributes storage entity = _entityAttributes[tokenId];

        // Example yield calculation: base yield + bonus from stats
        uint256 yieldBonusPerBlock = (uint256(entity.strength) + uint256(entity.agility)) / 10; // Example bonus scaling
        uint256 yieldThisPeriod = blocksElapsed * (yieldPerBlockBase + yieldBonusPerBlock);

        staking.yieldAccumulated = SafeMath.add(staking.yieldAccumulated, yieldThisPeriod);

        return yieldThisPeriod;
    }

    // --- Soul-Binding Logic ---

    /**
     * @dev Attempts to set a soul-bound attribute for an entity.
     * Soul-bound attributes, once set, cannot be changed and are meant to reflect
     * the owner's interaction history or achievements with the entity.
     * The data persists with the token but is conceptually bound to the owner history.
     * Requires caller to be the token owner.
     * Success depends on internal conditions (e.g., reaching evolution level, meeting stats).
     * @param tokenId The ID of the entity.
     * @param attributeType The type of soul-bound attribute to set (e.g., TraitType.BoundTraitA).
     * @param value The value to bind.
     */
    function updateSoulBoundAttribute(uint256 tokenId, TraitType attributeType, uint8 value) public onlyTokenOwner(tokenId) whenNotStaked(tokenId) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        if (attributeType != TraitType.BoundTraitA && attributeType != TraitType.BoundTraitB) {
             revert EOE_CannotSetSoulBoundAttributeYet(); // Only allow specific soul-bound types
        }

        SoulBoundAttributes storage soulBound = _soulBoundAttributes[tokenId];
        EntityAttributes storage entity = _entityAttributes[tokenId];

        // --- Example Soul-Binding Conditions ---
        bool canSet = false;
        if (attributeType == TraitType.BoundTraitA && !soulBound.isBoundTraitASet) {
            // Example: Can set BoundTraitA if evolution version >= 3 and energy >= 80
            if (entity.version >= 3 && entity.energy >= 80) {
                soulBound.boundTraitA = value;
                soulBound.isBoundTraitASet = true;
                canSet = true;
            }
        } else if (attributeType == TraitType.BoundTraitB && !soulBound.isBoundTraitBSet) {
             // Example: Can set BoundTraitB if combined strength+agility >= 150 and has rested recently
             if (uint256(entity.strength) + uint256(entity.agility) >= 150 && (block.number - entity.lastRestTime < 100)) {
                 soulBound.boundTraitB = value;
                 soulBound.isBoundTraitBSet = true;
                 canSet = true;
             }
        } else {
             revert EOE_SoulBoundAttributeAlreadySet();
        }

        if (!canSet) {
            revert EOE_CannotSetSoulBoundAttributeYet();
        }

        emit SoulBoundAttributeSet(tokenId, msg.sender, attributeType, value);
    }

     /**
      * @dev Internal helper to check if a soul-bound attribute can be set.
      * @param tokenId The ID of the entity.
      * @param attributeType The type of soul-bound attribute.
      * @return true if the attribute can be set, false otherwise.
      */
     function _canSetSoulBoundAttribute(uint256 tokenId, TraitType attributeType) internal view returns (bool) {
         if (!_exists(tokenId)) return false;

         SoulBoundAttributes storage soulBound = _soulBoundAttributes[tokenId];
         EntityAttributes storage entity = _entityAttributes[tokenId];

         if (attributeType == TraitType.BoundTraitA && !soulBound.isBoundTraitASet) {
             return (entity.version >= 3 && entity.energy >= 80);
         } else if (attributeType == TraitType.BoundTraitB && !soulBound.isBoundTraitBSet) {
              return (uint256(entity.strength) + uint256(entity.agility) >= 150 && (block.number - entity.lastRestTime < 100));
         }
         return false; // Attribute already set or invalid type
     }


    // --- Time-Sensitive Trait Logic ---

    /**
     * @dev Sets a time-sensitive trait on an entity that expires after a number of blocks.
     * Callable by owner, approved, or delegatee for the specific trait type.
     * @param tokenId The ID of the entity.
     * @param traitType The type of trait to apply (must be a dynamic trait type).
     * @param durationBlocks The number of blocks the trait remains active.
     * @param value The temporary value for the trait.
     */
    function setTimeSensitiveTrait(uint256 tokenId, TraitType traitType, uint256 durationBlocks, uint8 value)
        public onlyTokenOwnerApprovedOrDelegatee(tokenId, traitType) whenNotStaked(tokenId)
    {
         if (!_exists(tokenId)) revert EOE_InvalidTokenId();
         // Ensure it's a dynamic trait type that makes sense to be temporary
         if (traitType == TraitType.None || traitType == TraitType.BoundTraitA || traitType == TraitType.BoundTraitB) {
             revert EOE_CannotSetSoulBoundAttributeYet(); // Reusing error, ideally more specific
         }
         if (durationBlocks == 0) revert EOE_InvalidTokenId(); // Duration must be positive

         _timeSensitiveTraits[tokenId][uint8(traitType)] = TimeSensitiveTrait(value, block.number + durationBlocks);

         emit TimeSensitiveTraitSet(tokenId, traitType, value, block.number + durationBlocks);
    }

    /**
     * @dev Internal helper to check if a time-sensitive trait is currently active.
     * @param tokenId The ID of the entity.
     * @param traitType The type of time-sensitive trait.
     * @return true if the trait is active, false otherwise.
     */
    function _isTraitActive(uint256 tokenId, TraitType traitType) internal view returns (bool) {
        TimeSensitiveTrait storage trait = _timeSensitiveTraits[tokenId][uint8(traitType)];
        return trait.expiryBlock > block.number;
    }

    // --- Trait Delegation Logic ---

     /**
      * @dev Delegates the right to call functions modifying a specific dynamic trait
      * for a given entity to another address.
      * E.g., delegate TraitType.Energy to a manager for feeding.
      * Requires caller to be the token owner.
      * @param tokenId The ID of the entity.
      * @param delegatee The address to delegate to.
      * @param traitType The specific trait type to delegate (must be dynamic).
      */
    function delegateTraitOwnership(uint256 tokenId, address delegatee, TraitType traitType) public onlyTokenOwner(tokenId) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        // Ensure it's a dynamic trait type that makes sense to delegate
        if (traitType == TraitType.None || traitType == TraitType.BoundTraitA || traitType == TraitType.BoundTraitB) {
             revert EOE_CannotSetSoulBoundAttributeYet(); // Reusing error, ideally more specific
        }
        if (delegatee == address(0)) revert OwnableInvalidOwner(address(0)); // Using Ownable error

        address previousDelegatee = _traitDelegates[tokenId][uint8(traitType)];
        _traitDelegates[tokenId][uint8(traitType)] = delegatee;

        emit TraitOwnershipDelegated(tokenId, traitType, delegatee);
    }

     /**
      * @dev Revokes trait ownership delegation for a specific trait on an entity.
      * Requires caller to be the token owner.
      * @param tokenId The ID of the entity.
      * @param traitType The specific trait type to revoke delegation for.
      */
    function revokeTraitOwnership(uint256 tokenId, TraitType traitType) public onlyTokenOwner(tokenId) {
         if (!_exists(tokenId)) revert EOE_InvalidTokenId();
         // Ensure it's a dynamic trait type
         if (traitType == TraitType.None || traitType == TraitType.BoundTraitA || traitType == TraitType.BoundTraitB) {
             revert EOE_CannotSetSoulBoundAttributeYet(); // Reusing error, ideally more specific
         }

         address previousDelegatee = _traitDelegates[tokenId][uint8(traitType)];
         delete _traitDelegates[tokenId][uint8(traitType)];

         emit TraitOwnershipRevoked(tokenId, traitType, previousDelegatee);
    }

     /**
      * @dev Internal helper to check if the caller is delegated for a specific trait.
      * @param tokenId The ID of the entity.
      * @param traitType The type of trait.
      * @return true if the caller is the delegatee, false otherwise.
      */
     function _isTraitDelegatee(uint256 tokenId, TraitType traitType) internal view returns (bool) {
         return _traitDelegates[tokenId][uint8(traitType)] == _msgSender();
     }


    // --- View & Utility Functions ---

    /**
     * @dev Returns all attributes (dynamic, soul-bound) for an entity.
     */
    function getAttributes(uint256 tokenId) public view returns (
        EntityAttributes memory dynamicAttrs,
        SoulBoundAttributes memory soulBoundAttrs,
        mapping(uint8 => TimeSensitiveTrait) storage timeSensitiveAttrs // Note: Mappings cannot be returned directly, consider alternative
    ) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        // Direct return of mapping not possible. View functions should return copies or specific values.
        // Alternative: Return dynamic, soul-bound, and a list/array of active time-sensitive trait keys.
        dynamicAttrs = _entityAttributes[tokenId];
        soulBoundAttrs = _soulBoundAttributes[tokenId];
        // Returning the storage reference directly is potentially confusing. Better to return specific values or have separate getters.
        // For demonstration, keeping it simple but acknowledge the mapping return limitation.
        // A common pattern is to return arrays of structs for known trait types.
        revert("Mapping return not supported. Use specific getters like getDynamicAttributes.");
    }

    /**
     * @dev Returns only the dynamic attributes for an entity.
     */
    function getDynamicAttributes(uint256 tokenId) public view returns (EntityAttributes memory) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        return _entityAttributes[tokenId];
    }

    /**
     * @dev Returns only the soul-bound attributes for an entity.
     */
    function getSoulBoundAttributes(uint256 tokenId) public view returns (SoulBoundAttributes memory) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        return _soulBoundAttributes[tokenId];
    }

    /**
     * @dev Returns staking information for an entity.
     */
    function getStakingInfo(uint256 tokenId) public view returns (StakingInfo memory) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        // Calculate pending yield before returning info (non-mutating view)
        StakingInfo storage staking = _stakingInfo[tokenId];
        uint256 currentYield = staking.yieldAccumulated;
        if (staking.isStaked) {
             uint256 blocksElapsed = block.number - staking.stakeStartTime;
             EntityAttributes storage entity = _entityAttributes[tokenId];
             uint256 yieldBonusPerBlock = (uint256(entity.strength) + uint256(entity.agility)) / 10;
             currentYield = SafeMath.add(currentYield, blocksElapsed * (yieldPerBlockBase + yieldBonusPerBlock));
        }
        return StakingInfo(staking.isStaked, staking.stakeStartTime, currentYield);
    }

    /**
     * @dev Returns active time-sensitive traits and their expiry blocks for an entity.
     * Note: Cannot return the entire mapping. Returns a hardcoded set of known types if active.
     * In a real contract, you might store active trait types in a list or use events.
     */
    function getTimeSensitiveTraits(uint256 tokenId) public view returns (uint8[] memory traitTypes, uint8[] memory values, uint256[] memory expiryBlocks) {
         if (!_exists(tokenId)) revert EOE_InvalidTokenId();

         // This is a simplified example. A real implementation might iterate over potential traitTypes
         // or have a separate list of active traits per token.
         TraitType[] memory potentialTypes = new TraitType[](5); // Example check for Energy, Rest, Str, Agi, Int
         potentialTypes[0] = TraitType.Energy;
         potentialTypes[1] = TraitType.RestStatus;
         potentialTypes[2] = TraitType.Strength;
         potentialTypes[3] = TraitType.Agility;
         potentialTypes[4] = TraitType.Intelligence;

         uint256 count = 0;
         for(uint i = 0; i < potentialTypes.length; i++) {
             if (_isTraitActive(tokenId, potentialTypes[i])) {
                 count++;
             }
         }

         traitTypes = new uint8[](count);
         values = new uint8[](count);
         expiryBlocks = new uint256[](count);

         uint256 index = 0;
         for(uint i = 0; i < potentialTypes.length; i++) {
              if (_isTraitActive(tokenId, potentialTypes[i])) {
                  TimeSensitiveTrait storage trait = _timeSensitiveTraits[tokenId][uint8(potentialTypes[i])];
                  traitTypes[index] = uint8(potentialTypes[i]);
                  values[index] = trait.value;
                  expiryBlocks[index] = trait.expiryBlock;
                  index++;
              }
         }

         return (traitTypes, values, expiryBlocks);
    }


    /**
     * @dev Returns the current delegatee for a specific trait type on an entity.
     * Returns address(0) if no delegatee is set.
     */
    function getTraitDelegatee(uint256 tokenId, TraitType traitType) public view returns (address) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        return _traitDelegates[tokenId][uint8(traitType)];
    }

     /**
      * @dev Generates a unique hash representing the *current dynamic state* of the entity.
      * Useful for off-chain verification or rendering checks to ensure metadata matches on-chain state.
      * Includes dynamic attributes, version, and staking status. Does NOT include soul-bound (permanent) or time-sensitive (temporary) traits in this example hash.
      */
    function getCurrentStateHash(uint256 tokenId) public view returns (bytes32) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        EntityAttributes memory entity = _entityAttributes[tokenId];
        StakingInfo memory staking = _stakingInfo[tokenId];

        // Hash incorporating key dynamic and state variables
        return keccak256(abi.encodePacked(
            entity.energy,
            entity.restStatus,
            entity.strength,
            entity.agility,
            entity.intelligence,
            entity.resilience,
            entity.version,
            staking.isStaked
            // Could also include block.number or other context if hash needs to be time-sensitive
        ));
    }

    /**
     * @dev Returns the evolution/mutation count (version) of an entity.
     */
    function getVersion(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        return _entityAttributes[tokenId].version;
    }

     /**
      * @dev Returns the total number of entities currently staked.
      */
    function getTotalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    /**
     * @dev Returns the list of token IDs currently staked by a specific owner.
     */
    function getOwnerStakedTokens(address owner) public view returns (uint256[] memory) {
        return _stakedTokensByOwner[owner];
    }

    // --- Admin Functions (Owner-Only) ---

    /**
     * @dev Allows the contract owner to set the base URI for dynamic metadata.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev Allows the contract owner to update parameters governing the evolution process.
     * @param minEnergy The new minimum energy required for evolution.
     * @param minRest The new minimum rest status required for evolution.
     * @param blocksSinceLastEvolve The new minimum blocks needed since last evolution attempt.
     */
    function updateEvolutionRules(uint8 minEnergy, uint8 minRest, uint256 blocksSinceLastEvolve) public onlyOwner {
        minEnergyForEvolution = minEnergy;
        minRestStatusForEvolution = minRest;
        blocksNeededSinceLastEvolution = blocksSinceLastEvolve;
        // Add event here
    }

     /**
      * @dev Allows the contract owner to update parameters governing the catalysis process.
      * (Parameters are internal in this example, but could be externalized)
      * @param yieldBase The new base yield per block for staking.
      */
    function updateCatalysisRules(uint256 yieldBase) public onlyOwner {
        yieldPerBlockBase = yieldBase;
        // Add event here
    }

    /**
     * @dev Allows the contract owner to pause evolution attempts for a specific token.
     * Useful for maintenance or specific scenarios.
     * @param tokenId The ID of the entity to pause.
     */
    function pauseEvolution(uint256 tokenId) public onlyOwner {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        _isEvolutionPaused[tokenId] = true;
        emit EvolutionPaused(tokenId);
    }

     /**
      * @dev Allows the contract owner to unpause evolution attempts for a specific token.
      * @param tokenId The ID of the entity to unpause.
      */
    function unpauseEvolution(uint256 tokenId) public onlyOwner {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        _isEvolutionPaused[tokenId] = false;
        emit EvolutionUnpaused(tokenId);
    }

    /**
     * @dev Checks if evolution is paused for a specific token.
     */
    function isEvolutionPaused(uint256 tokenId) public view returns (bool) {
        if (!_exists(tokenId)) revert EOE_InvalidTokenId();
        return _isEvolutionPaused[tokenId];
    }

     // --- Internal/Helper Functions ---

    /**
     * @dev Converts a uint256 to a string.
     */
     function _toString(uint256 value) internal pure returns (string memory) {
         if (value == 0) {
             return "0";
         }
         uint256 temp = value;
         uint256 digits;
         while (temp != 0) {
             digits++;
             temp /= 10;
         }
         bytes memory buffer = new bytes(digits);
         while (value != 0) {
             digits -= 1;
             buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
             value /= 10;
         }
         return string(buffer);
     }

    // The standard _beforeTokenTransfer and _afterTokenTransfer hooks
    // are handled by the OpenZeppelin ERC721 base contract.
    // We might need to override _beforeTokenTransfer if we want to
    // add specific checks (like preventing transfer if staked).
     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
         internal
         override(ERC721)
     {
         super._beforeTokenTransfer(from, to, tokenId, batchSize);

         // Prevent transfer if staked (except for minting or burning by owner/approved)
         // Note: from == address(0) for mint, to == address(0) for burn
         if (_stakingInfo[tokenId].isStaked && from != address(0) && to != address(0)) {
             revert EOE_TokenIsStaked();
         }

         // If transferring a token, remove any trait delegations as they are bound to the old owner's intent
         // Note: Deleting mapping keys dynamically is complex and gas-intensive.
         // A simpler approach is to delete specific delegations on transfer
         // or have the getter functions check if the delegatee is still the token owner's designated delegatee.
         // For this example, we'll just delete known delegation types on transfer.
         // A more robust solution might store delegations in a list or use a different mapping structure.
         if (from != address(0) && to != address(0)) { // Not during mint or burn
            delete _traitDelegates[tokenId][uint8(TraitType.Energy)];
            delete _traitDelegates[tokenId][uint8(TraitType.RestStatus)];
            delete _traitDelegates[tokenId][uint8(TraitType.Strength)];
            delete _traitDelegates[tokenId][uint8(TraitType.Agility)];
            delete _traitDelegates[tokenId][uint8(TraitType.Intelligence)];
            delete _traitDelegates[tokenId][uint8(TraitType.Resilience)];
            // Add other dynamic traits here if delegated
         }

         // If the token is staked and changing ownership (shouldn't happen if staked check works, but defensive)
         // ensure it's removed from the *old* owner's stakedTokensByOwner list IF it somehow got there while staked.
         // The primary staked check `whenNotStaked` on transfer functions prevents this scenario.
         // If _burn is called by owner/approved on a staked token (which `whenNotStaked(tokenId)` on `burn` prevents),
         // we'd need to handle removing it from the staked list here.
         // The current `burn` modifier prevents burning if staked, simplifying this hook.
     }

      function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
         internal
         override(ERC721)
      {
         super._afterTokenTransfer(from, to, tokenId, batchSize);

         // Soul-bound attributes conceptually follow the token, but their *meaning* or unlock condition
         // might be tied to the owner who achieved the binding. The data remains with the token.
         // No state change needed for soul-bound data in the _afterTokenTransfer hook itself,
         // as it lives in _soulBoundAttributes[tokenId].
      }
}
```