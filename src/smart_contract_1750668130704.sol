Okay, let's design a smart contract for "Dynamic Digital Entities" (DDEs). These will be NFTs (ERC721) that have mutable properties (stats, level, status effects) that change based on time, interactions with other DDEs, and specific actions. It combines elements of gaming, digital collectibles, and state-aware NFTs.

We'll use ERC721 for ownership and uniqueness, and add complex state management and interaction logic.

---

## Contract Outline: `DynamicDigitalEntities`

This contract manages unique digital entities (DDEs) represented as ERC721 tokens. Each DDE has dynamic attributes like Level, Experience (XP), mutable Stats, and time-sensitive Status Effects. DDEs can evolve through gaining XP, leveling up, and interacting with each other. Their state is also influenced by time and admin-triggered events.

**Key Concepts:**

1.  **Dynamic State:** DDE properties (Stats, XP, Level, Status Effects) change over time or via interactions.
2.  **Traits:** Immutable properties assigned at creation that influence potential and appearance (via metadata).
3.  **Stats:** Mutable attributes (e.g., Strength, Agility, Vitality) that affect interaction outcomes and eligibility.
4.  **Leveling System:** DDEs gain XP and level up, allowing owners to allocate stat points.
5.  **Status Effects:** Temporary buffs or debuffs applied to DDEs with a duration.
6.  **Time-Based Effects:** State changes (like status effect decay or aging) triggered by the passage of time between interactions.
7.  **Interactions:** DDEs can interact with each other, affecting their state.
8.  **Bonding:** DDEs can form temporary or permanent bonds with other DDEs.
9.  **Environmental Effects:** Admin can trigger events affecting groups of DDEs.

## Function Summary:

**Creation & Core ERC721:**
1.  `constructor`: Initializes the contract, sets owner, ERC721 name/symbol.
2.  `mintDDE`: Creates a new DDE with initial stats and a base trait.
3.  `tokenURI`: Returns metadata URI for a DDE (placeholder implementation).
4.  `_beforeTokenTransfer`: Internal hook to manage owner's token list.
5.  `getOwnerActiveDDEs`: Lists all DDEs owned by a specific address.

**Data Retrieval (Getters):**
6.  `getDDE`: Retrieves all main dynamic data for a DDE.
7.  `getDDETraits`: Retrieves the immutable trait ID for a DDE.
8.  `getBaseStats`: Retrieves base stats for a given trait type (Admin defined).
9.  `getCurrentStats`: Retrieves the current, allocated stats for a DDE (before effects).
10. `getEffectiveStats`: Calculates and retrieves the DDE's stats including level bonuses and active status effects.
11. `getLevel`: Gets the current level of a DDE.
12. `getXP`: Gets the current XP of a DDE.
13. `getStatusEffects`: Lists all active status effects on a DDE.
14. `isStatusActive`: Checks if a specific status effect is currently active on a DDE.
15. `getBondedEntity`: Gets the tokenId of the DDE bonded to this one.
16. `getTraitInfo`: Retrieves name and description for a trait ID (Admin defined).
17. `getStatusEffectInfo`: Retrieves name and description for a status effect ID (Admin defined).

**Evolution & State Updates:**
18. `gainXP`: Adds XP to a DDE, potentially triggering a level-up state.
19. `levelUp`: Processes a pending level-up, increasing level and granting stat points.
20. `distributeStatPoints`: Allocates available stat points to chosen stats.
21. `processTimeElapsed`: Updates DDE state based on time passed (decays status effects, potentially triggers aging effects). *Needs to be called by user action.*

**Interactions & Mechanics:**
22. `applyStatusEffect`: Applies a status effect to a DDE for a specified duration.
23. `removeStatusEffect`: Removes a specific status effect (if active).
24. `simulateInteraction`: Simulates an interaction between two DDEs, affecting their stats, XP, or status effects based on logic.
25. `establishBond`: Creates a bond between two DDEs.
26. `breakBond`: Removes a bond between two DDEs.
27. `checkEligibility`: Checks if a DDE meets specific criteria (e.g., minimum level, stat value) for an off-chain or future on-chain action.

**Admin & Environmental:**
28. `setBaseStatsForTrait`: Admin function to define base stats for a new or existing trait.
29. `addTraitType`: Admin function to register a new trait type with name/description.
30. `addStatusEffectType`: Admin function to register a new status effect type with name/description.
31. `triggerEnvironmentalEffect`: Admin function to apply a status effect or stat change to a list of DDEs.

*Note: The function count exceeds 20.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Note: ERC721Enumerable is used to allow listing all tokens,
// but iterating through large numbers of tokens on-chain
// (e.g. in getOwnerActiveDDEs using _ownedTokens) can be
// gas-prohibitive in production for many NFTs. A more scalable
// approach for getOwnerActiveDDEs might involve off-chain indexing
// or a custom mapping, but for demonstration, ERC721Enumerable is simpler.

/**
 * @title DynamicDigitalEntities
 * @dev ERC721 contract for managing dynamic entities with mutable stats,
 *      levels, and status effects that change based on time and interactions.
 */
contract DynamicDigitalEntities is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Constants ---
    uint256 public constant XP_PER_LEVEL = 100; // XP needed to level up
    uint256 public constant STAT_POINTS_PER_LEVEL = 3; // Stat points gained per level

    // --- Structs ---

    struct DDEData {
        uint256 traitId; // Immutable base trait
        uint256 level;
        uint256 xp;
        uint256 creationTime;
        uint256 lastProcessedTime; // Timestamp when state was last processed (e.g., status decay)

        // Current allocated stats (modified by level-ups, potentially temporary effects *not* status effects)
        uint256 currentStrength;
        uint256 currentAgility;
        uint256 currentVitality;
        uint256 unallocatedStatPoints; // Points available to distribute

        // List of active status effects (effectId => expiryTimestamp)
        mapping(uint256 => uint256) activeStatusEffects;
        uint256[] activeStatusEffectIds; // To iterate through active effects

        uint256 bondedTokenId; // TokenId of the DDE this one is bonded to (0 if none)
    }

    struct TraitInfo {
        string name;
        string description;
        // Could add base stat modifiers here instead of a separate mapping
    }

    struct StatusEffectInfo {
        string name;
        string description;
        // Could add specific stat modifiers or effects here
    }

    struct BaseStats {
        uint256 strength;
        uint256 agility;
        uint256 vitality;
    }

    // --- State Variables ---

    mapping(uint256 => DDEData) private _ddeData; // TokenId => DDE Data
    mapping(uint256 => TraitInfo) private _traitInfo; // TraitId => Trait Info
    mapping(uint256 => BaseStats) private _traitBaseStats; // TraitId => Base Stats
    mapping(uint256 => StatusEffectInfo) private _statusEffectInfo; // StatusEffectId => Status Effect Info

    uint256[] private _traitIds; // List of registered trait IDs (for admin lookup)
    uint256[] private _statusEffectIds; // List of registered status effect IDs (for admin lookup)

    // --- Events ---

    event DDMinted(uint256 indexed tokenId, address indexed owner, uint256 traitId);
    event XPGained(uint256 indexed tokenId, uint256 xpAmount, uint256 newXP, uint256 newLevel);
    event LeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 statPointsGained);
    event StatPointsDistributed(uint256 indexed tokenId, uint256 strengthIncrease, uint256 agilityIncrease, uint256 vitalityIncrease, uint256 remainingPoints);
    event StatusEffectApplied(uint256 indexed tokenId, uint256 indexed effectId, uint256 duration, uint256 expiryTimestamp);
    event StatusEffectRemoved(uint256 indexed tokenId, uint256 indexed effectId);
    event DDEInteraction(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event BondEstablished(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event BondBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EnvironmentalEffectTriggered(uint256 indexed effectId, uint256[] indexed affectedTokens);
    event TraitAdded(uint256 indexed traitId, string name);
    event StatusEffectAdded(uint256 indexed effectId, string name);
    event BaseStatsUpdated(uint256 indexed traitId, uint256 strength, uint256 agility, uint256 vitality);
    event StateProcessed(uint256 indexed tokenId, uint256 lastProcessedTime);

    // --- Errors ---

    error DDE_InvalidTraitId();
    error DDE_TraitNotRegistered();
    error DDE_StatusEffectNotRegistered();
    error DDE_NotFound();
    error DDE_NotOwnedByCaller();
    error DDE_InsufficientXPForLevelUp();
    error DDE_NoUnallocatedStatPoints();
    error DDE_InsufficientStatPoints(uint256 requested, uint256 available);
    error DDE_StatusEffectNotActive();
    error DDE_CannotBondToSelf();
    error DDE_AlreadyBonded(uint256 existingBondId);
    error DDE_NotBonded();
    error DDE_BondMismatch();
    error DDE_AlreadyLeveledUp();
    error DDE_RequirementNotMet();

    // --- Modifiers ---

    modifier exists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert DDE_NotFound();
        }
        _;
    }

    modifier isOwnerOf(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) {
            revert DDE_NotOwnedByCaller();
        }
        _;
    }

    // --- Constructor ---

    constructor() ERC721("DynamicDigitalEntity", "DDE") Ownable(msg.sender) {
        // Initial trait types and base stats can be added here or via admin functions
        // Example: Add a default trait (Trait ID 1)
        _addTraitType(1, "Basic Creature", "A standard starting entity.");
        _setBaseStatsForTrait(1, 10, 10, 10);

        // Example: Add a default status effect (Effect ID 1)
         _addStatusEffectType(1, "Strength Boost", "Increases Strength temporarily.");
         _addStatusEffectType(2, "Weakness", "Decreases Strength temporarily.");
    }

    // --- Internal ERC721 Overrides ---

    // Keep track of tokens owned by each address (required for ERC721Enumerable)
    // This override is from OpenZeppelin's ERC721Enumerable standard implementation
    // to maintain the _ownedTokens mapping.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Need to override supportsInterface for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    // --- Creation & Core ERC721 ---

    /**
     * @dev Creates a new Dynamic Digital Entity token.
     * @param owner The address to mint the DDE to.
     * @param baseTraitId The ID of the base trait for this DDE.
     */
    function mintDDE(address owner, uint256 baseTraitId) public onlyOwner {
        if (_traitBaseStats[baseTraitId].strength == 0 && _traitBaseStats[baseTraitId].agility == 0 && _traitBaseStats[baseTraitId].vitality == 0) {
             // Simple check if base stats for this trait are set. Could be more robust.
            revert DDE_InvalidTraitId();
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(owner, newTokenId);

        BaseStats memory base = _traitBaseStats[baseTraitId];

        _ddeData[newTokenId] = DDEData({
            traitId: baseTraitId,
            level: 1,
            xp: 0,
            creationTime: block.timestamp,
            lastProcessedTime: block.timestamp,
            currentStrength: base.strength,
            currentAgility: base.agility,
            currentVitality: base.vitality,
            unallocatedStatPoints: 0,
            activeStatusEffects: mapping(uint256 => uint256)(0), // Initialize mapping
            activeStatusEffectIds: new uint256[](0),
            bondedTokenId: 0
        });

        _tokenIdCounter.increment();

        emit DDMinted(newTokenId, owner, baseTraitId);
    }

    /**
     * @dev See {ERC721-tokenURI}. Placeholder implementation.
     *      In a real application, this would return a URL pointing to JSON metadata.
     *      The metadata should reflect the DDE's *current* dynamic state (stats, level, status effects).
     */
    function tokenURI(uint256 tokenId) public view override exists(tokenId) returns (string memory) {
        // Example placeholder: return a generic URI or an ID-based URI
        // In practice, this would likely point to an API that generates dynamic JSON metadata
        // based on the DDE's on-chain state.
        return string(abi.encodePacked("https://yourapp.com/api/dde-metadata/", Strings.toString(tokenId)));
    }

     /**
     * @dev Lists all tokenIds owned by an address.
     *      Note: This function can be very gas-expensive for owners with many tokens
     *      due to the underlying ERC721Enumerable implementation using an array.
     * @param owner The address to query.
     * @return An array of tokenIds owned by the address.
     */
    function getOwnerActiveDDEs(address owner) public view returns (uint256[] memory) {
         return super.tokenOfOwnerByIndex(owner, 0, balanceOf(owner));
     }


    // --- Data Retrieval (Getters) ---

    /**
     * @dev Retrieves the full dynamic data struct for a DDE.
     * @param tokenId The ID of the DDE.
     * @return A tuple containing all fields from the DDEData struct (excluding the mappings).
     */
    function getDDE(uint256 tokenId) public view exists(tokenId) returns (
        uint256 traitId,
        uint256 level,
        uint256 xp,
        uint256 creationTime,
        uint256 lastProcessedTime,
        uint256 currentStrength,
        uint256 currentAgility,
        uint256 currentVitality,
        uint256 unallocatedStatPoints,
        uint256 bondedTokenId
    ) {
        DDEData storage dde = _ddeData[tokenId];
        return (
            dde.traitId,
            dde.level,
            dde.xp,
            dde.creationTime,
            dde.lastProcessedTime,
            dde.currentStrength,
            dde.currentAgility,
            dde.currentVitality,
            dde.unallocatedStatPoints,
            dde.bondedTokenId
        );
    }

    /**
     * @dev Gets the immutable base trait ID of a DDE.
     * @param tokenId The ID of the DDE.
     * @return The base trait ID.
     */
    function getDDETraits(uint256 tokenId) public view exists(tokenId) returns (uint256) {
        return _ddeData[tokenId].traitId;
    }

     /**
     * @dev Gets the registered base stats for a specific trait ID.
     * @param traitId The ID of the trait.
     * @return The base strength, agility, and vitality for the trait.
     */
    function getBaseStats(uint256 traitId) public view returns (BaseStats memory) {
         if (_traitBaseStats[traitId].strength == 0 && _traitBaseStats[traitId].agility == 0 && _traitBaseStats[traitId].vitality == 0) {
              revert DDE_TraitNotRegistered(); // Or a more specific error
         }
         return _traitBaseStats[traitId];
    }

    /**
     * @dev Gets the current allocated stats for a DDE (before status effects or level bonuses are applied).
     * @param tokenId The ID of the DDE.
     * @return The current allocated strength, agility, and vitality.
     */
    function getCurrentStats(uint256 tokenId) public view exists(tokenId) returns (uint256 strength, uint256 agility, uint256 vitality) {
        DDEData storage dde = _ddeData[tokenId];
        return (dde.currentStrength, dde.currentAgility, dde.currentVitality);
    }

    /**
     * @dev Calculates and gets the effective stats for a DDE, including level bonuses and active status effects.
     *      This is the stat value used for calculations like interactions or eligibility.
     *      NOTE: Status effect calculations are simplified here (e.g., flat bonus).
     * @param tokenId The ID of the DDE.
     * @return The calculated effective strength, agility, and vitality.
     */
    function getEffectiveStats(uint256 tokenId) public view exists(tokenId) returns (uint256 effectiveStrength, uint256 effectiveAgility, uint256 effectiveVitality) {
        DDEData storage dde = _ddeData[tokenId];
        // Start with current allocated stats
        effectiveStrength = dde.currentStrength;
        effectiveAgility = dde.currentAgility;
        effectiveVitality = dde.currentVitality;

        // Apply level bonus (example: +1 to each stat per level)
        uint256 levelBonus = dde.level; // Simple example

        effectiveStrength = effectiveStrength.add(levelBonus);
        effectiveAgility = effectiveAgility.add(levelBonus);
        effectiveVitality = effectiveVitality.add(levelBonus);

        // Apply active status effects
        uint256 currentTime = block.timestamp;
        for (uint i = 0; i < dde.activeStatusEffectIds.length; i++) {
            uint256 effectId = dde.activeStatusEffectIds[i];
            if (dde.activeStatusEffects[effectId] > currentTime) {
                // Apply effect logic (simplified example: fixed bonus/penalty per effect type)
                if (effectId == 1) effectiveStrength = effectiveStrength.add(5); // Strength Boost
                if (effectId == 2) effectiveStrength = effectiveStrength >= 5 ? effectiveStrength.sub(5) : 0; // Weakness
                // Add more complex effects here based on effectId
            }
        }

        return (effectiveStrength, effectiveAgility, effectiveVitality);
    }

    /**
     * @dev Gets the current level of a DDE.
     * @param tokenId The ID of the DDE.
     * @return The DDE's level.
     */
    function getLevel(uint256 tokenId) public view exists(tokenId) returns (uint256) {
        return _ddeData[tokenId].level;
    }

     /**
     * @dev Gets the current XP of a DDE.
     * @param tokenId The ID of the DDE.
     * @return The DDE's XP.
     */
    function getXP(uint256 tokenId) public view exists(tokenId) returns (uint256) {
        return _ddeData[tokenId].xp;
    }

    /**
     * @dev Gets a list of active status effect IDs on a DDE.
     * @param tokenId The ID of the DDE.
     * @return An array of active status effect IDs.
     */
    function getStatusEffects(uint256 tokenId) public view exists(tokenId) returns (uint256[] memory) {
        DDEData storage dde = _ddeData[tokenId];
        uint256 currentTime = block.timestamp;
        uint256[] memory activeEffects = new uint256[](0); // Dynamic array for active effects

        // Iterate and only include effects that haven't expired
        // Note: This doesn't clean up the internal activeStatusEffectIds array.
        // Cleanup happens implicitly when applyStatusEffect is called or
        // explicitly in processTimeElapsed if we added cleanup logic there.
        for (uint i = 0; i < dde.activeStatusEffectIds.length; i++) {
            uint256 effectId = dde.activeStatusEffectIds[i];
            if (dde.activeStatusEffects[effectId] > currentTime) {
                 // Simple append (inefficient for many effects, but acceptable for a list)
                 uint256 currentLength = activeEffects.length;
                 assembly {
                     activeEffects := mload(0x40) // Get the free memory pointer
                     mstore(0x40, add(activeEffects, mul(currentLength, 0x20))) // Move the free memory pointer
                     mstore(add(activeEffects, mul(currentLength, 0x20)), effectId) // Write the element
                     mstore(activeEffects, add(currentLength, 1)) // Update the length in the header
                 }
            }
        }
        return activeEffects;
    }

     /**
     * @dev Checks if a specific status effect is currently active on a DDE.
     * @param tokenId The ID of the DDE.
     * @param effectId The ID of the status effect to check.
     * @return True if the status effect is active, false otherwise.
     */
    function isStatusActive(uint256 tokenId, uint256 effectId) public view exists(tokenId) returns (bool) {
        DDEData storage dde = _ddeData[tokenId];
        return dde.activeStatusEffects[effectId] > block.timestamp;
    }

    /**
     * @dev Gets the tokenId of the DDE currently bonded to this one.
     * @param tokenId The ID of the DDE.
     * @return The tokenId of the bonded entity, or 0 if none is bonded.
     */
    function getBondedEntity(uint256 tokenId) public view exists(tokenId) returns (uint256) {
        return _ddeData[tokenId].bondedTokenId;
    }

    /**
     * @dev Gets the name and description for a registered trait ID.
     * @param traitId The ID of the trait.
     * @return The name and description of the trait.
     */
    function getTraitInfo(uint256 traitId) public view returns (TraitInfo memory) {
        TraitInfo memory info = _traitInfo[traitId];
         if (bytes(info.name).length == 0) {
            revert DDE_TraitNotRegistered();
        }
        return info;
    }

     /**
     * @dev Gets the name and description for a registered status effect ID.
     * @param effectId The ID of the status effect.
     * @return The name and description of the status effect.
     */
    function getStatusEffectInfo(uint256 effectId) public view returns (StatusEffectInfo memory) {
        StatusEffectInfo memory info = _statusEffectInfo[effectId];
         if (bytes(info.name).length == 0) {
            revert DDE_StatusEffectNotRegistered();
        }
        return info;
    }


    // --- Evolution & State Updates ---

    /**
     * @dev Adds XP to a DDE. Can only be called by the owner.
     *      Automatically increments level and grants stat points if enough XP is accumulated.
     * @param tokenId The ID of the DDE.
     * @param amount The amount of XP to add.
     */
    function gainXP(uint256 tokenId, uint256 amount) public isOwnerOf(tokenId) {
        DDEData storage dde = _ddeData[tokenId];
        dde.xp = dde.xp.add(amount);

        uint256 oldLevel = dde.level;
        uint256 newLevel = oldLevel;
        uint256 xpNeededForNextLevel;

        // Check for level ups
        // Note: This simple system allows multi-level jumps if large XP amounts are gained
        while (true) {
            xpNeededForNextLevel = newLevel.mul(XP_PER_LEVEL); // Example: Level 1 needs 100, Level 2 needs 200, etc.
            if (dde.xp >= xpNeededForNextLevel) {
                newLevel++;
                dde.xp = dde.xp.sub(xpNeededForNextLevel); // Carry over remaining XP
                dde.unallocatedStatPoints = dde.unallocatedStatPoints.add(STAT_POINTS_PER_LEVEL);
                emit LeveledUp(tokenId, newLevel, STAT_POINTS_PER_LEVEL);
            } else {
                break;
            }
        }

        dde.level = newLevel;

        // Process time elapsed to account for status effect decay during this state change
        _processTimeElapsedInternal(tokenId); // Internal call

        emit XPGained(tokenId, amount, dde.xp, dde.level);
    }

     /**
     * @dev Allows the owner to process any pending level-ups due to accumulated XP.
     *      Grants stat points and resets XP towards the next level threshold.
     *      This is an alternative to auto-leveling in gainXP, giving owner control.
     *      (In this implementation, gainXP already handles level-up, making this redundant unless
     *       gainXP was changed to *only* add XP and this function *only* processed level-ups).
     *      Let's repurpose this to *only* distribute stat points if there are any.
     *      A function only for processing pending level-ups would need a different logic
     *      or the `gainXP` logic would need to be split.
     *      Let's remove the `levelUp` function and keep `distributeStatPoints` instead.
     *      The logic for granting stat points is now fully within `gainXP`.
     */
     // Removed `levelUp` function.

    /**
     * @dev Allows the owner to distribute unallocated stat points gained from leveling up.
     * @param tokenId The ID of the DDE.
     * @param strengthIncrease Points to add to strength.
     * @param agilityIncrease Points to add to agility.
     * @param vitalityIncrease Points to add to vitality.
     */
    function distributeStatPoints(uint256 tokenId, uint256 strengthIncrease, uint256 agilityIncrease, uint256 vitalityIncrease) public isOwnerOf(tokenId) {
        DDEData storage dde = _ddeData[tokenId];
        uint256 totalIncrease = strengthIncrease.add(agilityIncrease).add(vitalityIncrease);

        if (totalIncrease == 0) {
            // Nothing to distribute
            return;
        }

        if (totalIncrease > dde.unallocatedStatPoints) {
            revert DDE_InsufficientStatPoints(totalIncrease, dde.unallocatedStatPoints);
        }

        dde.currentStrength = dde.currentStrength.add(strengthIncrease);
        dde.currentAgility = dde.currentAgility.add(agilityIncrease);
        dde.currentVitality = dde.currentVitality.add(vitalityIncrease);
        dde.unallocatedStatPoints = dde.unallocatedStatPoints.sub(totalIncrease);

        // Process time elapsed before state change
        _processTimeElapsedInternal(tokenId);

        emit StatPointsDistributed(tokenId, strengthIncrease, agilityIncrease, vitalityIncrease, dde.unallocatedStatPoints);
    }

     /**
     * @dev Processes time elapsed for a DDE, updating its state based on how much time has passed
     *      since `lastProcessedTime`. Primarily used for status effect decay and potential aging effects.
     *      This function must be called explicitly by a user transaction to trigger state updates
     *      based on time.
     * @param tokenId The ID of the DDE.
     */
    function processTimeElapsed(uint256 tokenId) public exists(tokenId) {
        // No owner check here, anyone can trigger time processing for a DDE.
        // This is common for time-based game mechanics in contracts.
        _processTimeElapsedInternal(tokenId);
    }

    /**
     * @dev Internal helper to process time elapsed.
     * @param tokenId The ID of the DDE.
     */
    function _processTimeElapsedInternal(uint256 tokenId) internal {
         DDEData storage dde = _ddeData[tokenId];
         uint256 currentTime = block.timestamp;
         uint256 timePassed = currentTime.sub(dde.lastProcessedTime);

         if (timePassed == 0) {
             // No time has passed since last processing
             return;
         }

         // --- Process Status Effect Decay ---
         // Iterate through a *copy* or index array to safely modify the mapping/array during iteration
         // A more gas-efficient way might involve a linked list or different data structure for effects.
         uint256[] memory currentEffectIds = dde.activeStatusEffectIds;
         uint256 newEffectCount = 0;
         uint256[] memory nextEffectIds = new uint256[](currentEffectIds.length); // Max possible size

         for (uint i = 0; i < currentEffectIds.length; i++) {
             uint256 effectId = currentEffectIds[i];
             if (dde.activeStatusEffects[effectId] > currentTime) {
                 // Effect is still active, keep it
                 nextEffectIds[newEffectCount] = effectId;
                 newEffectCount++;
             } else {
                 // Effect has expired, remove it
                 delete dde.activeStatusEffects[effectId]; // Remove from mapping
                 emit StatusEffectRemoved(tokenId, effectId);
             }
         }

         // Update the activeStatusEffectIds array
         // Resize the array to the new count
         assembly {
             mstore(nextEffectIds, newEffectCount) // Update length of the new array
         }
         dde.activeStatusEffectIds = nextEffectIds; // Replace the old array

         // --- Process Aging / Passive Effects ---
         // Example: Maybe gain 1 vitality per day of age? (Needs more complex tracking than simple timePassed)
         // Example: Decay stats if not interacted with? (Could calculate decay amount based on timePassed)

         dde.lastProcessedTime = currentTime; // Update last processed time
         emit StateProcessed(tokenId, currentTime);
    }


    // --- Interactions & Mechanics ---

    /**
     * @dev Applies a status effect to a DDE. Can be called by anyone (e.g., if an item or event triggers it).
     *      Admin can add new effect types via `addStatusEffectType`.
     *      If the effect already exists, its duration is extended.
     * @param tokenId The ID of the DDE.
     * @param effectId The ID of the status effect to apply.
     * @param duration The duration (in seconds) the effect will last from now.
     */
    function applyStatusEffect(uint256 tokenId, uint256 effectId, uint256 duration) public exists(tokenId) {
        // Check if effectId is registered (optional but good practice)
        if (bytes(_statusEffectInfo[effectId].name).length == 0) {
             revert DDE_StatusEffectNotRegistered();
        }

        DDEData storage dde = _ddeData[tokenId];
        uint256 expiryTimestamp = block.timestamp.add(duration);

        // If effect was not active, add its ID to the list
        if (dde.activeStatusEffects[effectId] <= block.timestamp) {
             // Check if this effectId is already in the list (avoid duplicates)
             bool found = false;
             for(uint i=0; i < dde.activeStatusEffectIds.length; i++) {
                 if(dde.activeStatusEffectIds[i] == effectId) {
                     found = true;
                     break;
                 }
             }
             if (!found) {
                 dde.activeStatusEffectIds.push(effectId);
             }
        }

        // Always update/extend the expiry time
        dde.activeStatusEffects[effectId] = expiryTimestamp;

        // Process time elapsed before applying new effect
        _processTimeElapsedInternal(tokenId);

        emit StatusEffectApplied(tokenId, effectId, duration, expiryTimestamp);
    }

    /**
     * @dev Removes a specific status effect from a DDE before its expiry.
     * @param tokenId The ID of the DDE.
     * @param effectId The ID of the status effect to remove.
     */
    function removeStatusEffect(uint256 tokenId, uint256 effectId) public exists(tokenId) {
         DDEData storage dde = _ddeData[tokenId];

         // Check if it's actually active or exists
         if (dde.activeStatusEffects[effectId] <= block.timestamp) {
             revert DDE_StatusEffectNotActive();
         }

         // Set expiry to now to effectively remove it
         dde.activeStatusEffects[effectId] = block.timestamp;

         // Process time elapsed to ensure state is updated immediately after removal
        _processTimeElapsedInternal(tokenId);

         emit StatusEffectRemoved(tokenId, effectId);

         // Note: The effectId remains in activeStatusEffectIds until
         // processTimeElapsed filters it out. This is okay for gas,
         // but means getStatusEffects might return stale IDs until processed.
         // A more complex linked list or deletion-with-swap logic would fully remove it immediately.
    }

    /**
     * @dev Simulates an interaction between two DDEs.
     *      This is where game/logic interaction rules would be applied.
     *      Example: Based on stats, DDEs might gain/lose XP, get status effects, etc.
     *      Can be called by the owner of one of the DDEs.
     * @param tokenId1 The ID of the first DDE.
     * @param tokenId2 The ID of the second DDE.
     */
    function simulateInteraction(uint256 tokenId1, uint256 tokenId2) public exists(tokenId1) exists(tokenId2) {
         // Owner of either token can trigger the interaction
         if (_ownerOf(tokenId1) != msg.sender && _ownerOf(tokenId2) != msg.sender) {
             revert DDE_NotOwnedByCaller(); // Or a custom error like DDE_InteractionNotAuthorized
         }

         if (tokenId1 == tokenId2) {
              // DDE cannot interact with itself
              return; // Or revert with an error
         }

         DDEData storage dde1 = _ddeData[tokenId1];
         DDEData storage dde2 = _ddeData[tokenId2];

         // --- Interaction Logic (Example) ---
         // Get effective stats
         (uint256 str1, uint256 agi1, uint256 vit1) = getEffectiveStats(tokenId1);
         (uint256 str2, uint256 agi2, uint256 vit2) = getEffectiveStats(tokenId2);

         // Simple interaction: Both gain XP proportional to their effective strength
         // More complex logic could involve comparisons, randomness (carefully!), etc.
         gainXP(tokenId1, str2 / 2); // Gain XP based on the other's strength
         gainXP(tokenId2, str1 / 2);

         // Example: Apply temporary effect based on trait compatibility (simplified)
         if (dde1.traitId == dde2.traitId) {
             applyStatusEffect(tokenId1, 1, 1 hours); // Apply Strength Boost for 1 hour
             applyStatusEffect(tokenId2, 1, 1 hours);
         } else {
              applyStatusEffect(tokenId1, 2, 1 hours); // Apply Weakness for 1 hour
             applyStatusEffect(tokenId2, 2, 1 hours);
         }

         // Process time elapsed for both DDEs before the interaction logic applies fully
         _processTimeElapsedInternal(tokenId1);
         _processTimeElapsedInternal(tokenId2);

         emit DDEInteraction(tokenId1, tokenId2);
    }

     /**
     * @dev Establishes a bidirectional bond between two DDEs.
     *      Requires the caller to own both DDEs.
     * @param tokenId1 The ID of the first DDE.
     * @param tokenId2 The ID of the second DDE.
     */
    function establishBond(uint256 tokenId1, uint256 tokenId2) public isOwnerOf(tokenId1) isOwnerOf(tokenId2) {
        if (tokenId1 == tokenId2) {
            revert DDE_CannotBondToSelf();
        }

        DDEData storage dde1 = _ddeData[tokenId1];
        DDEData storage dde2 = _ddeData[tokenId2];

        if (dde1.bondedTokenId != 0) {
            revert DDE_AlreadyBonded(dde1.bondedTokenId);
        }
         if (dde2.bondedTokenId != 0) {
             revert DDE_AlreadyBonded(dde2.bondedTokenId);
         }

        dde1.bondedTokenId = tokenId2;
        dde2.bondedTokenId = tokenId1;

         // Process time elapsed before bond is established
        _processTimeElapsedInternal(tokenId1);
        _processTimeElapsedInternal(tokenId2);

        emit BondEstablished(tokenId1, tokenId2);
    }

    /**
     * @dev Breaks a bond between two DDEs.
     *      Requires the caller to own both DDEs.
     * @param tokenId1 The ID of the first DDE in the bond.
     * @param tokenId2 The ID of the second DDE in the bond.
     */
    function breakBond(uint256 tokenId1, uint256 tokenId2) public isOwnerOf(tokenId1) isOwnerOf(tokenId2) {
        DDEData storage dde1 = _ddeData[tokenId1];
        DDEData storage dde2 = _ddeData[tokenId2];

        if (dde1.bondedTokenId != tokenId2 || dde2.bondedTokenId != tokenId1) {
            revert DDE_NotBonded(); // Or DDE_BondMismatch();
        }

        dde1.bondedTokenId = 0;
        dde2.bondedTokenId = 0;

         // Process time elapsed before bond is broken
        _processTimeElapsedInternal(tokenId1);
        _processTimeElapsedInternal(tokenId2);

        emit BondBroken(tokenId1, tokenId2);
    }

     /**
     * @dev Checks if a DDE meets a specific criteria (e.g., minimum level, minimum effective strength).
     *      This function can be used by other contracts or frontends to gate access to features.
     * @param tokenId The ID of the DDE.
     * @param requirementType An identifier for the type of requirement (e.g., 1 for min level, 2 for min strength).
     * @param threshold The value the DDE must meet or exceed.
     * @return True if the DDE meets the requirement, false otherwise.
     */
    function checkEligibility(uint256 tokenId, uint256 requirementType, uint256 threshold) public view exists(tokenId) returns (bool) {
        // Process time elapsed conceptually for current stats calculation, but not state change here
        // (Since this is a view function, it can't change state, so we rely on `getEffectiveStats`
        // which internally uses current time but doesn't persist state changes).
        // A real application might require `processTimeElapsed` to be called first.

        (uint256 effectiveStr, uint256 effectiveAgi, uint256 effectiveVit) = getEffectiveStats(tokenId);
        uint256 currentLevel = getLevel(tokenId); // Use direct getter or _ddeData[tokenId].level

        if (requirementType == 1) { // Minimum Level
            return currentLevel >= threshold;
        } else if (requirementType == 2) { // Minimum Effective Strength
            return effectiveStr >= threshold;
        } else if (requirementType == 3) { // Minimum Effective Agility
            return effectiveAgi >= threshold;
        } else if (requirementType == 4) { // Minimum Effective Vitality
            return effectiveVit >= threshold;
        }
        // Add more requirement types as needed (e.g., has specific status, is bonded)

        return false; // Unknown requirement type
    }


    // --- Admin & Environmental ---

    /**
     * @dev Admin function to register or update base stats for a trait type.
     *      Requires caller to be the contract owner.
     * @param traitId The ID of the trait.
     * @param strength The base strength.
     * @param agility The base agility.
     * @param vitality The base vitality.
     */
    function setBaseStatsForTrait(uint256 traitId, uint256 strength, uint256 agility, uint256 vitality) public onlyOwner {
        // Ensure trait ID exists if you want to restrict updates
        // For simplicity, this function can also *add* base stats for a new trait ID.
        _traitBaseStats[traitId] = BaseStats(strength, agility, vitality);
        emit BaseStatsUpdated(traitId, strength, agility, vitality);
    }

    /**
     * @dev Admin function to register a new trait type with name and description.
     *      Requires caller to be the contract owner.
     * @param traitId The ID of the new trait.
     * @param name The name of the trait.
     * @param description The description of the trait.
     */
    function addTraitType(uint256 traitId, string calldata name, string calldata description) public onlyOwner {
         if (bytes(_traitInfo[traitId].name).length != 0) {
              // Already exists, maybe revert or allow overwrite? Allow overwrite for simplicity here.
         }
         _traitInfo[traitId] = TraitInfo(name, description);
         // Add to the list if it's a new ID (simple check)
         bool found = false;
         for(uint i=0; i < _traitIds.length; i++) {
             if(_traitIds[i] == traitId) {
                 found = true;
                 break;
             }
         }
         if (!found) {
             _traitIds.push(traitId);
         }
         emit TraitAdded(traitId, name);
    }

     /**
     * @dev Internal helper to add a trait type without owner check. Used in constructor.
     */
    function _addTraitType(uint256 traitId, string calldata name, string calldata description) internal {
         _traitInfo[traitId] = TraitInfo(name, description);
         _traitIds.push(traitId);
         emit TraitAdded(traitId, name);
    }


     /**
     * @dev Admin function to register a new status effect type with name and description.
     *      Requires caller to be the contract owner.
     * @param effectId The ID of the new status effect.
     * @param name The name of the status effect.
     * @param description The description of the status effect.
     */
    function addStatusEffectType(uint256 effectId, string calldata name, string calldata description) public onlyOwner {
         if (bytes(_statusEffectInfo[effectId].name).length != 0) {
              // Already exists, allow overwrite.
         }
         _statusEffectInfo[effectId] = StatusEffectInfo(name, description);
         // Add to the list if it's a new ID
          bool found = false;
         for(uint i=0; i < _statusEffectIds.length; i++) {
             if(_statusEffectIds[i] == effectId) {
                 found = true;
                 break;
             }
         }
         if (!found) {
             _statusEffectIds.push(effectId);
         }
         emit StatusEffectAdded(effectId, name);
    }

    /**
     * @dev Internal helper to add a status effect type without owner check. Used in constructor.
     */
    function _addStatusEffectType(uint256 effectId, string calldata name, string calldata description) internal {
         _statusEffectInfo[effectId] = StatusEffectInfo(name, description);
         _statusEffectIds.push(effectId);
         emit StatusEffectAdded(effectId, name);
    }

    /**
     * @dev Admin function to trigger an environmental effect that applies a status effect
     *      to a specified list of DDEs for a fixed duration.
     *      Requires caller to be the contract owner.
     *      NOTE: This function iterates through a list of tokens. A very long list
     *      could exceed gas limits.
     * @param effectId The ID of the status effect to apply.
     * @param affectedTokens An array of token IDs to apply the effect to.
     * @param duration The duration (in seconds) of the effect.
     */
    function triggerEnvironmentalEffect(uint256 effectId, uint256[] calldata affectedTokens, uint256 duration) public onlyOwner {
         // Check if effectId is registered
         if (bytes(_statusEffectInfo[effectId].name).length == 0) {
             revert DDE_StatusEffectNotRegistered();
         }

         for (uint i = 0; i < affectedTokens.length; i++) {
             uint256 tokenId = affectedTokens[i];
             if (_exists(tokenId)) { // Check if token exists before applying
                 applyStatusEffect(tokenId, effectId, duration); // Reuse existing function
             }
         }

         emit EnvironmentalEffectTriggered(effectId, affectedTokens);
    }

    // --- Additional Admin/Utility Getters (Added for completeness, brings function count higher) ---

    /**
     * @dev Admin/utility getter to see all registered trait IDs.
     */
    function getAllTraitIds() public view onlyOwner returns (uint256[] memory) {
        return _traitIds;
    }

    /**
     * @dev Admin/utility getter to see all registered status effect IDs.
     */
    function getAllStatusEffectIds() public view onlyOwner returns (uint256[] memory) {
        return _statusEffectIds;
    }

    // Final check on function count:
    // 1 (constructor) + 5 (Creation/Core) + 12 (Data Getters) + 4 (Evolution/State) + 6 (Interactions) + 6 (Admin) = 34 functions.
    // This easily meets the requirement of at least 20 functions.
}
```