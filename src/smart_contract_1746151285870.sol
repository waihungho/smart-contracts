Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts beyond standard token implementations. This contract manages "Temporal Chronicle Entities," which are dynamic NFTs that can level up, undertake quests, age, fuse, and are influenced by a global "Temporal Alignment" state. It also utilizes an external ERC-20 token ("Temporal Essence") as a resource.

**Outline:**

1.  **Pragma and Imports**
2.  **Interfaces** (for ERC-20 interaction)
3.  **Errors**
4.  **Events**
5.  **Structs** (`Entity`, `QuestParameters`, `FusionParameters`)
6.  **State Variables** (Counters, Mappings, Configs, Global State)
7.  **Modifiers** (`onlyOwner`, `whenNotPaused`, `entityExists`)
8.  **Constructor**
9.  **Core Entity Management** (`mintEntity`, `burnEntity`, `getEntityDetails`, `getEntityOwner`, `getPlayerEntityCount`)
10. **Entity State Modification (Active)** (`gainExperience`, `levelUpEntity`, `undertakeTemporalQuest`, `fuseEntities`, `upgradeSkill`, `consumeEssence`)
11. **Entity State Modification (Passive/Time)** (`ageEntity`, `applyTemporalDecay`)
12. **World State Management** (`influenceTemporalAlignment`, `getCurrentTemporalAlignment`)
13. **Configuration & Admin** (`setQuestParameters`, `setFusionParameters`, `setEssenceContractAddress`, `pauseContractActions`, `unpauseContractActions`, `withdrawAdminFees`)
14. **Queries & Helpers** (`getEntityLevel`, `getEntityXP`, `getEntityTemporalIntegrity`, `getEntityAffinity`, `getEntityBirthTime`, `getEntityMetadataHash`, `getQuestParameters`, `getFusionParameters`, `getEssenceContractAddress`, `getProtocolEssenceBalance`, `isContractPaused`)

**Function Summary:**

1.  `mintEntity()`: Creates a new Temporal Chronicle Entity NFT. Requires caller to pay `TemporalEssence`. Assigns initial attributes.
2.  `burnEntity(uint256 tokenId)`: Destroys an owned Entity NFT.
3.  `getEntityDetails(uint256 tokenId)`: View function to retrieve all core attributes of an Entity.
4.  `getEntityOwner(uint256 tokenId)`: View function to get the owner of a specific Entity NFT.
5.  `getPlayerEntityCount(address owner)`: View function to get the number of Entities owned by an address.
6.  `gainExperience(uint256 tokenId, uint256 amount)`: Adds experience points to an Entity. Can trigger `levelUpEntity`.
7.  `levelUpEntity(uint256 tokenId)`: Processes accrued XP, levels up the Entity if threshold is met, and updates attributes based on level.
8.  `undertakeTemporalQuest(uint256 tokenId)`: Simulates an Entity attempting a quest. Checks entity stats, consumes Essence, calculates success based on stats and global alignment, applies results (XP, attribute changes, decay, rewards/penalties).
9.  `fuseEntities(uint256 tokenId1, uint256 tokenId2)`: Combines two owned Entities, consuming them and minting a new one with attributes derived from the source Entities. Requires Essence.
10. `upgradeSkill(uint256 tokenId, uint8 skillIndex)`: Allows owner to spend resources (XP or Essence) to specifically boost an Entity's attribute/skill.
11. `consumeEssence(uint256 tokenId, uint256 amount)`: Allows owner to spend Essence on an Entity to restore its `temporalIntegrity`.
12. `ageEntity(uint256 tokenId)`: A function to apply aging effects based on time passed since birth or last aging. Reduces `temporalIntegrity` passively.
13. `applyTemporalDecay(uint256 tokenId, uint256 amount)`: Directly reduces an Entity's `temporalIntegrity`, perhaps due to quest failure or specific events.
14. `influenceTemporalAlignment(int256 influenceAmount)`: Allows users to spend Essence or sacrifice Entity stats (not implemented fully in this example, but concept included) to slightly shift the global `temporalAlignment` state.
15. `getCurrentTemporalAlignment()`: View function to get the current global temporal alignment value.
16. `setQuestParameters(uint256 baseCost, uint256 baseXP, uint256 integrityLossOnFailure, uint256 successChanceFactor)`: Admin function to configure parameters for quests.
17. `setFusionParameters(uint256 essenceCost, uint256 integrityCostPerEntity, uint256 attributeInheritanceFactor)`: Admin function to configure parameters for entity fusion.
18. `setEssenceContractAddress(address essenceAddress)`: Admin function to set the address of the external `TemporalEssence` ERC-20 token.
19. `pauseContractActions()`: Admin function to pause core gameplay actions.
20. `unpauseContractActions()`: Admin function to unpause core gameplay actions.
21. `withdrawAdminFees()`: Admin function to withdraw accumulated `TemporalEssence` held by the contract (e.g., from minting/action costs).
22. `getEntityLevel(uint256 tokenId)`: View function to get the level of an Entity.
23. `getEntityXP(uint256 tokenId)`: View function to get the XP of an Entity.
24. `getEntityTemporalIntegrity(uint256 tokenId)`: View function to get the temporal integrity of an Entity.
25. `getEntityAffinity(uint256 tokenId)`: View function to get the affinity of an Entity.
26. `getEntityBirthTime(uint256 tokenId)`: View function to get the birth timestamp of an Entity.
27. `getEntityMetadataHash(uint256 tokenId)`: View function to get the metadata hash (for off-chain data) of an Entity.
28. `getQuestParameters()`: View function to get current quest configuration.
29. `getFusionParameters()`: View function to get current fusion configuration.
30. `getEssenceContractAddress()`: View function to get the configured Essence token address.
31. `getProtocolEssenceBalance()`: View function to get the amount of Essence held by the contract.
32. `isContractPaused()`: View function to check if the contract is paused.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For random logic

// --- Outline ---
// 1. Pragma and Imports
// 2. Interfaces (for ERC-20 interaction)
// 3. Errors
// 4. Events
// 5. Structs (Entity, QuestParameters, FusionParameters)
// 6. State Variables (Counters, Mappings, Configs, Global State)
// 7. Modifiers (onlyOwner, whenNotPaused, entityExists)
// 8. Constructor
// 9. Core Entity Management (mintEntity, burnEntity, getEntityDetails, getEntityOwner, getPlayerEntityCount)
// 10. Entity State Modification (Active) (gainExperience, levelUpEntity, undertakeTemporalQuest, fuseEntities, upgradeSkill, consumeEssence)
// 11. Entity State Modification (Passive/Time) (ageEntity, applyTemporalDecay)
// 12. World State Management (influenceTemporalAlignment, getCurrentTemporalAlignment)
// 13. Configuration & Admin (setQuestParameters, setFusionParameters, setEssenceContractAddress, pauseContractActions, unpauseContractActions, withdrawAdminFees)
// 14. Queries & Helpers (getEntityLevel, getEntityXP, getEntityTemporalIntegrity, getEntityAffinity, getEntityBirthTime, getEntityMetadataHash, getQuestParameters, getFusionParameters, getEssenceContractAddress, getProtocolEssenceBalance, isContractPaused)


// --- Function Summary ---
// 1. mintEntity(): Creates a new Temporal Chronicle Entity NFT. Requires caller to pay TemporalEssence.
// 2. burnEntity(uint256 tokenId): Destroys an owned Entity NFT.
// 3. getEntityDetails(uint256 tokenId): Retrieves all core attributes of an Entity.
// 4. getEntityOwner(uint256 tokenId): Gets the owner of a specific Entity NFT.
// 5. getPlayerEntityCount(address owner): Gets the number of Entities owned by an address.
// 6. gainExperience(uint256 tokenId, uint256 amount): Adds experience points to an Entity.
// 7. levelUpEntity(uint256 tokenId): Processes accrued XP, levels up Entity if possible.
// 8. undertakeTemporalQuest(uint256 tokenId): Simulates a quest attempt, checks stats, consumes Essence, applies results.
// 9. fuseEntities(uint256 tokenId1, uint256 tokenId2): Combines two owned Entities, consuming them and minting a new one.
// 10. upgradeSkill(uint256 tokenId, uint8 skillIndex): Spends resources to boost an Entity's specific attribute.
// 11. consumeEssence(uint256 tokenId, uint256 amount): Spends Essence on an Entity to restore integrity.
// 12. ageEntity(uint256 tokenId): Applies aging effects based on time passed.
// 13. applyTemporalDecay(uint256 tokenId, uint256 amount): Directly reduces an Entity's temporal integrity.
// 14. influenceTemporalAlignment(int256 influenceAmount): Allows users to slightly shift the global temporalAlignment state.
// 15. getCurrentTemporalAlignment(): Gets the current global temporal alignment value.
// 16. setQuestParameters(...): Admin function to configure quest settings.
// 17. setFusionParameters(...): Admin function to configure fusion settings.
// 18. setEssenceContractAddress(address essenceAddress): Admin function to set the Essence ERC-20 address.
// 19. pauseContractActions(): Admin function to pause core gameplay actions.
// 20. unpauseContractActions(): Admin function to unpause core gameplay actions.
// 21. withdrawAdminFees(): Admin function to withdraw accumulated Essence fees.
// 22. getEntityLevel(uint256 tokenId): Gets the level of an Entity.
// 23. getEntityXP(uint256 tokenId): Gets the XP of an Entity.
// 24. getEntityTemporalIntegrity(uint256 tokenId): Gets the temporal integrity of an Entity.
// 25. getEntityAffinity(uint256 tokenId): Gets the affinity of an Entity.
// 26. getEntityBirthTime(uint256 tokenId): Gets the birth timestamp of an Entity.
// 27. getEntityMetadataHash(uint256 tokenId): Gets the metadata hash of an Entity.
// 28. getQuestParameters(): Gets current quest configuration.
// 29. getFusionParameters(): Gets current fusion configuration.
// 30. getEssenceContractAddress(): Gets the configured Essence token address.
// 31. getProtocolEssenceBalance(): Gets the amount of Essence held by the contract.
// 32. isContractPaused(): Checks if the contract is paused.

contract TemporalChronicles is Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _nextTokenId;

    struct Entity {
        uint64 level; // Entity level, impacts stats
        uint66 xp; // Experience points towards next level
        uint64 temporalIntegrity; // Health/durability, decreases with aging/failure
        uint64 affinity; // A core stat affecting quest success, fusion outcome, etc.
        uint256 birthTime; // Timestamp of creation
        bytes32 metadataHash; // IPFS hash or similar for off-chain metadata
        uint256 lastAgedTimestamp; // Timestamp when ageEntity was last called
    }

    mapping(uint256 => Entity) private entities;
    mapping(uint256 => address) private entityOwner;
    mapping(address => uint256) private ownerEntityCount;

    bool public paused;

    address public essenceToken; // Address of the external Temporal Essence ERC-20 contract

    // Global state variable influencing quests, fusion, etc.
    // Could represent cosmic alignment, world mood, etc.
    int256 public temporalAlignment;

    struct QuestParameters {
        uint256 baseEssenceCost; // Cost to undertake a quest
        uint256 baseXPReward; // XP gained on success
        uint256 baseIntegrityLossOnFailure; // Integrity lost on failure
        uint256 successChanceFactor; // Multiplier for success chance calculation (e.g., affinity * factor)
    }
    QuestParameters public questParameters;

    struct FusionParameters {
        uint256 essenceCost; // Cost to fuse two entities
        uint256 integrityCostPerEntity; // Integrity requirement/cost per source entity
        uint256 attributeInheritanceFactor; // Factor determining how parent attributes contribute to new entity
    }
    FusionParameters public fusionParameters;

    uint256 public constant MAX_TEMPORAL_INTEGRITY = 1000; // Max integrity for entities
    uint256 public constant BASE_XP_TO_LEVEL = 100; // Base XP needed for level 1 -> 2

    // --- Events ---
    event EntityMinted(address indexed owner, uint256 indexed tokenId, uint256 initialLevel, uint256 birthTime);
    event EntityBurned(address indexed owner, uint256 indexed tokenId);
    event EntityLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 remainingXP);
    event TemporalQuestCompleted(uint256 indexed tokenId, bool success, uint256 xpGained, int256 integrityChange, uint256 essenceReward);
    event EntityFused(address indexed owner, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId);
    event TemporalDecayApplied(uint256 indexed tokenId, uint256 decayAmount);
    event TemporalAlignmentChanged(int256 newAlignment);
    event EssenceDeposited(address indexed user, uint256 amount); // Implicit via transferFrom
    event EssenceWithdrawn(address indexed to, uint256 amount); // Admin withdrawal
    event ContractPaused(bool status);
    event EntityAttributeUpgraded(uint256 indexed tokenId, uint8 indexed skillIndex, uint256 newValue);
    event EntityEssenceConsumed(uint256 indexed tokenId, uint256 amount, uint256 newIntegrity);
    event EntityMetadataUpdated(uint256 indexed tokenId, bytes32 metadataHash);

    // --- Errors ---
    error EntityDoesNotExist(uint256 tokenId);
    error NotEntityOwner(uint256 tokenId, address caller);
    error ContractPausedError();
    error NotPausedError();
    error InsufficientTemporalEssence(uint256 required, uint256 available);
    error InsufficientTemporalIntegrity(uint256 required, uint256 available);
    error InsufficientXP(uint256 required, uint256 available);
    error CannotFuseSameEntity();
    error InvalidSkillIndex(uint8 skillIndex);
    error EssenceContractNotSet();
    error CannotWithdrawZeroEssence();
    error FusionRequirementNotMet(string reason);

    // --- Modifiers ---
    modifier entityExists(uint256 tokenId) {
        if (entityOwner[tokenId] == address(0)) {
            revert EntityDoesNotExist(tokenId);
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert ContractPausedError();
        }
        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert NotPausedError();
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialEssenceToken) Ownable(msg.sender) {
        paused = false;
        temporalAlignment = 0; // Initial alignment state

        // Set initial default parameters (can be changed by owner)
        questParameters = QuestParameters({
            baseEssenceCost: 50 * 10**18, // Example: 50 tokens with 18 decimals
            baseXPReward: 100,
            baseIntegrityLossOnFailure: 50,
            successChanceFactor: 10 // e.g., Affinity * 10 = max chance percentage
        });

        fusionParameters = FusionParameters({
            essenceCost: 200 * 10**18, // Example: 200 tokens
            integrityCostPerEntity: 200, // Each entity must have >= 200 integrity
            attributeInheritanceFactor: 50 // 50% influence from parents, 50% new
        });

        essenceToken = initialEssenceToken;
        if (essenceToken == address(0)) {
             revert EssenceContractNotSet(); // Ensure Essence is set at deploy
        }
    }

    // --- Core Entity Management ---

    /**
     * @summary Creates a new Temporal Chronicle Entity NFT.
     * @dev Requires the caller to approve this contract to spend `questParameters.baseEssenceCost` in Essence tokens.
     * @return The ID of the newly minted entity.
     */
    function mintEntity() public whenNotPaused returns (uint256) {
        uint256 newItemId = _nextTokenId.current();

        // Require payment in Essence token
        if (essenceToken == address(0)) revert EssenceContractNotSet();
        if (IERC20(essenceToken).balanceOf(msg.sender) < questParameters.baseEssenceCost) {
             revert InsufficientTemporalEssence(questParameters.baseEssenceCost, IERC20(essenceToken).balanceOf(msg.sender));
        }
        IERC20(essenceToken).transferFrom(msg.sender, address(this), questParameters.baseEssenceCost);

        // Initial random-ish attributes (simplified using block data)
        uint64 initialLevel = 1;
        uint64 initialIntegrity = uint64(MAX_TEMPORAL_INTEGRITY);
        // Simple pseudo-randomness based on current block
        uint64 initialAffinity = uint64(uint256(keccak256(abi.encodePacked(newItemId, block.timestamp, block.difficulty))) % 100) + 1; // Affinity 1-100

        entities[newItemId] = Entity({
            level: initialLevel,
            xp: 0,
            temporalIntegrity: initialIntegrity,
            affinity: initialAffinity,
            birthTime: block.timestamp,
            metadataHash: bytes32(0), // Placeholder, update later
            lastAgedTimestamp: block.timestamp
        });

        entityOwner[newItemId] = msg.sender;
        ownerEntityCount[msg.sender]++;
        _nextTokenId.increment();

        emit EntityMinted(msg.sender, newItemId, initialLevel, block.timestamp);
        return newItemId;
    }

    /**
     * @summary Destroys an owned Entity NFT.
     * @param tokenId The ID of the entity to burn.
     */
    function burnEntity(uint256 tokenId) public whenNotPaused entityExists(tokenId) {
        if (entityOwner[tokenId] != msg.sender) {
            revert NotEntityOwner(tokenId, msg.sender);
        }

        address owner = entityOwner[tokenId];
        delete entities[tokenId];
        delete entityOwner[tokenId];
        ownerEntityCount[owner]--;

        emit EntityBurned(owner, tokenId);
    }

    /**
     * @summary Retrieves all core attributes of an Entity.
     * @param tokenId The ID of the entity.
     * @return Entity struct containing level, xp, integrity, affinity, birth time, metadata hash.
     */
    function getEntityDetails(uint256 tokenId) public view entityExists(tokenId) returns (Entity memory) {
        return entities[tokenId];
    }

    /**
     * @summary Gets the owner of a specific Entity NFT.
     * @param tokenId The ID of the entity.
     * @return The address of the entity's owner.
     */
    function getEntityOwner(uint256 tokenId) public view entityExists(tokenId) returns (address) {
        return entityOwner[tokenId];
    }

     /**
      * @summary Gets the number of Entities owned by an address.
      * @param owner The address to query.
      * @return The count of entities owned by the address.
      */
    function getPlayerEntityCount(address owner) public view returns (uint256) {
        return ownerEntityCount[owner];
    }


    // --- Entity State Modification (Active) ---

    /**
     * @summary Adds experience points to an Entity.
     * @dev Can be called by external game logic or other contracts.
     * @param tokenId The ID of the entity.
     * @param amount The amount of XP to add.
     */
    function gainExperience(uint256 tokenId, uint256 amount) public whenNotPaused entityExists(tokenId) {
        // Ensure the entity is owned by someone (should be covered by entityExists, but belts and suspenders)
         if (entityOwner[tokenId] == address(0)) revert EntityDoesNotExist(tokenId);

        Entity storage entity = entities[tokenId];
        entity.xp += uint64(amount);

        // Attempt to level up immediately if eligible
        // It's generally better to have a separate levelUp function
        // so users can decide *when* to level up (e.g., after multiple XP gains)
        // For this example, we'll keep them separate but note levelUp can be called after gainExperience
        // levelUpEntity(tokenId); // User would call this manually or it could be triggered elsewhere

        // Event for XP gain could be added if needed
    }

     /**
      * @summary Processes accrued XP, levels up the Entity if threshold is met.
      * @dev This needs to be called by the owner or allowed address after XP is gained.
      * @param tokenId The ID of the entity.
      */
    function levelUpEntity(uint256 tokenId) public whenNotPaused entityExists(tokenId) {
        if (entityOwner[tokenId] != msg.sender) {
            revert NotEntityOwner(tokenId, msg.sender);
        }

        Entity storage entity = entities[tokenId];
        uint256 xpNeeded = BASE_XP_TO_LEVEL * (entity.level + 1); // Simple linear scaling example

        while (entity.xp >= xpNeeded) {
            entity.level++;
            entity.xp -= uint64(xpNeeded); // Subtract XP needed for the level
            // Optional: Increase xpNeeded for the *next* level if scaling is non-linear
            xpNeeded = BASE_XP_TO_LEVEL * (entity.level + 1); // Update needed XP for next iteration

            // Apply attribute increases on level up (example: random increase or fixed)
            // Using minimal entropy for simple example; better randomness needed for production
            uint256 rand = uint256(keccak256(abi.encodePacked(tokenId, entity.level, block.timestamp, block.difficulty)));
            if (rand % 2 == 0) {
                 // Increase integrity slightly, capped at max
                 entity.temporalIntegrity = uint64(Math.min(entity.temporalIntegrity + (rand % 10) + 5, MAX_TEMPORAL_INTEGRITY));
            } else {
                 // Increase affinity slightly, capped
                 entity.affinity = uint64(Math.min(entity.affinity + (rand % 5) + 1, 200)); // Example max affinity 200
            }

            emit EntityLeveledUp(tokenId, entity.level, entity.xp);
        }
    }


    /**
     * @summary Simulates an Entity undertaking a temporal quest.
     * @dev Requires the caller to approve this contract to spend `questParameters.baseEssenceCost`.
     * Checks entity stats and global alignment for success chance. Applies results.
     * @param tokenId The ID of the entity undertaking the quest.
     */
    function undertakeTemporalQuest(uint256 tokenId) public whenNotPaused entityExists(tokenId) {
        if (entityOwner[tokenId] != msg.sender) {
            revert NotEntityOwner(tokenId, msg.sender);
        }
        if (essenceToken == address(0)) revert EssenceContractNotSet();

        Entity storage entity = entities[tokenId];

        // 1. Check requirements & Cost
        // Basic integrity check (e.g., must have at least 10% integrity)
        if (entity.temporalIntegrity < MAX_TEMPORAL_INTEGRITY / 10) {
             revert InsufficientTemporalIntegrity(MAX_TEMPORAL_INTEGRITY / 10, entity.temporalIntegrity);
        }

        // Pay Essence cost
        uint256 cost = questParameters.baseEssenceCost;
        if (IERC20(essenceToken).balanceOf(msg.sender) < cost) {
             revert InsufficientTemporalEssence(cost, IERC20(essenceToken).balanceOf(msg.sender));
        }
        IERC20(essenceToken).transferFrom(msg.sender, address(this), cost);

        // 2. Determine Success Chance
        // Simplified chance calculation: based on affinity and temporal alignment
        // Affinity provides base chance, alignment shifts it.
        // Randomness source: Simple block hash randomness (NOT secure for high-value outcomes)
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.difficulty, tx.origin)));
        uint256 randomRoll = randomSeed % 100; // Roll a number between 0-99

        int256 effectiveAlignmentInfluence = temporalAlignment / 100; // Each 100 alignment shifts chance by 1%
        uint256 successChancePercentage = uint256(int256(entity.affinity / 10) + effectiveAlignmentInfluence); // Example: 10 Affinity = 1% base chance. (Affinity 1-100 gives 1-10% base)
        successChancePercentage = Math.min(successChancePercentage, 95); // Cap success chance

        bool success = (randomRoll < successChancePercentage);

        // 3. Apply Results
        uint256 xpGained = 0;
        int256 integrityChange = 0;
        uint256 essenceReward = 0;

        if (success) {
            xpGained = questParameters.baseXPReward;
            entity.xp += uint64(xpGained);
            integrityChange = -int256(Math.min(entity.temporalIntegrity, questParameters.baseIntegrityLossOnFailure / 5)); // Small integrity loss even on success
             // Example reward: small chance of essence back or boost
             if (randomRoll % 10 == 0) { // 10% chance of bonus reward
                essenceReward = cost / 2; // Get half cost back
                if (IERC20(essenceToken).balance(address(this)) >= essenceReward) {
                    IERC20(essenceToken).transfer(msg.sender, essenceReward);
                } else {
                    essenceReward = 0; // Not enough essence in contract
                }
             }
        } else {
            xpGained = questParameters.baseXPReward / 2; // Gain some XP even on failure
            entity.xp += uint64(xpGained);
            integrityChange = -int256(questParameters.baseIntegrityLossOnFailure); // Significant integrity loss
            // No essence reward on failure
        }

        // Apply integrity change, clamp between 0 and MAX_TEMPORAL_INTEGRITY
        if (integrityChange < 0) {
             entity.temporalIntegrity = uint64(Math.max(int256(entity.temporalIntegrity) + integrityChange, int256(0)));
        } else {
             entity.temporalIntegrity = uint64(Math.min(int256(entity.temporalIntegrity) + integrityChange, int256(MAX_TEMPORAL_INTEGRITY)));
        }


        // Optional: Trigger level up check after gaining XP
        // levelUpEntity(tokenId); // Or require owner to call manually

        emit TemporalQuestCompleted(tokenId, success, xpGained, integrityChange, essenceReward);
    }

    /**
     * @summary Combines two owned Entities, consuming them and minting a new one.
     * @dev Requires the caller to own both entities and approve Essence transfer.
     * The source entities are burned. The new entity's attributes are derived.
     * @param tokenId1 The ID of the first entity to fuse.
     * @param tokenId2 The ID of the second entity to fuse.
     * @return The ID of the newly created entity.
     */
    function fuseEntities(uint256 tokenId1, uint256 tokenId2) public whenNotPaused entityExists(tokenId1) entityExists(tokenId2) returns (uint256) {
        if (entityOwner[tokenId1] != msg.sender || entityOwner[tokenId2] != msg.sender) {
            revert NotEntityOwner(tokenId1, msg.sender); // Will only trigger if one is not owned
        }
        if (tokenId1 == tokenId2) {
             revert CannotFuseSameEntity();
        }
        if (essenceToken == address(0)) revert EssenceContractNotSet();

        Entity storage entityA = entities[tokenId1];
        Entity storage entityB = entities[tokenId2];

        // 1. Check requirements & Cost
        if (entityA.temporalIntegrity < fusionParameters.integrityCostPerEntity || entityB.temporalIntegrity < fusionParameters.integrityCostPerEntity) {
             revert FusionRequirementNotMet("Insufficient integrity on source entities");
        }

        uint256 cost = fusionParameters.essenceCost;
        if (IERC20(essenceToken).balanceOf(msg.sender) < cost) {
             revert InsufficientTemporalEssence(cost, IERC20(essenceToken).balanceOf(msg.sender));
        }
        IERC20(essenceToken).transferFrom(msg.sender, address(this), cost);


        // 2. Determine New Entity Attributes
        // Simplified attribute calculation: weighted average + some randomness
        uint256 newItemId = _nextTokenId.current();
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(tokenId1, tokenId2, block.timestamp, block.difficulty, tx.origin)));

        uint256 factor = fusionParameters.attributeInheritanceFactor; // e.g., 50
        uint256 remainingFactor = 100 - factor; // e.g., 50

        uint64 newLevel = uint64((entityA.level * factor + entityB.level * factor) / (2 * 100) + (uint256(randomSeed % 5) + 1)); // Level average + small random bonus
        uint64 newAffinity = uint64((entityA.affinity * factor + entityB.affinity * factor) / (2 * 100) + (uint256(randomSeed % 20) + 1)); // Affinity average + random bonus

        // Clamp new stats within reasonable bounds (e.g., max affinity)
        newAffinity = uint64(Math.min(newAffinity, 200)); // Example cap


        // 3. Burn Source Entities
        burnEntity(tokenId1);
        burnEntity(tokenId2); // burnEntity handles ownership/count updates

        // 4. Mint New Entity
         entities[newItemId] = Entity({
            level: newLevel,
            xp: 0, // Starts fresh XP-wise
            temporalIntegrity: MAX_TEMPORAL_INTEGRITY, // Starts with full integrity
            affinity: newAffinity,
            birthTime: block.timestamp,
            metadataHash: bytes32(0), // Placeholder
            lastAgedTimestamp: block.timestamp
        });

        entityOwner[newItemId] = msg.sender;
        ownerEntityCount[msg.sender]++; // burnEntity decremented twice, mintEntity increments once -> Net change of -1 for the owner
        _nextTokenId.increment();

        emit EntityFused(msg.sender, tokenId1, tokenId2, newItemId);
        return newItemId;
    }

    /**
     * @summary Allows owner to spend resources to boost an Entity's specific attribute/skill.
     * @dev Example: Spend XP to increase Affinity.
     * @param tokenId The ID of the entity.
     * @param skillIndex Index representing the skill/attribute (e.g., 0 for Affinity).
     */
    function upgradeSkill(uint256 tokenId, uint8 skillIndex) public whenNotPaused entityExists(tokenId) {
        if (entityOwner[tokenId] != msg.sender) {
            revert NotEntityOwner(tokenId, msg.sender);
        }

        Entity storage entity = entities[tokenId];

        // Example: Spend 100 XP to increase Affinity by 5
        uint256 xpCost = 100;
        uint256 affinityBoost = 5;

        if (entity.xp < xpCost) {
            revert InsufficientXP(xpCost, entity.xp);
        }

        if (skillIndex == 0) { // Example: Skill Index 0 = Affinity
            entity.xp -= uint64(xpCost);
            entity.affinity = uint64(Math.min(entity.affinity + affinityBoost, 200)); // Cap affinity
             emit EntityAttributeUpgraded(tokenId, skillIndex, entity.affinity);
        } else {
            revert InvalidSkillIndex(skillIndex);
        }

         // More skill indices and resource costs (Essence, etc.) could be added here
    }

     /**
      * @summary Allows owner to spend Essence on an Entity to restore its temporal integrity.
      * @dev Requires caller to approve Essence transfer.
      * @param tokenId The ID of the entity.
      * @param amount The amount of Essence to spend.
      */
    function consumeEssence(uint256 tokenId, uint256 amount) public whenNotPaused entityExists(tokenId) {
        if (entityOwner[tokenId] != msg.sender) {
            revert NotEntityOwner(tokenId, msg.sender);
        }
        if (essenceToken == address(0)) revert EssenceContractNotSet();
        if (amount == 0) return; // No-op for 0 amount

        Entity storage entity = entities[tokenId];

        // Cap integrity restoration at MAX_TEMPORAL_INTEGRITY
        uint256 integrityRestored = amount / 10**17; // Example: 0.1 Essence restores 1 integrity
        uint256 potentialNewIntegrity = entity.temporalIntegrity + integrityRestored;
        uint256 actualIntegrityRestored = Math.min(potentialNewIntegrity, MAX_TEMPORAL_INTEGRITY) - entity.temporalIntegrity;

        if (actualIntegrityRestored == 0) {
             // Entity is already at max integrity or amount too small to restore even 1
             return; // No Essence spent if no integrity is restored
        }

        // Calculate exact essence cost for the actual integrity restored
        uint256 actualEssenceCost = actualIntegrityRestored * 10**17;

        if (IERC20(essenceToken).balanceOf(msg.sender) < actualEssenceCost) {
             revert InsufficientTemporalEssence(actualEssenceCost, IERC20(essenceToken).balanceOf(msg.sender));
        }

        IERC20(essenceToken).transferFrom(msg.sender, address(this), actualEssenceCost);
        entity.temporalIntegrity = uint64(entity.temporalIntegrity + actualIntegrityRestored);

        emit EntityEssenceConsumed(tokenId, actualEssenceCost, entity.temporalIntegrity);
    }

    // --- Entity State Modification (Passive/Time) ---

    /**
     * @summary Applies aging effects based on time passed since birth or last aging.
     * @dev This function needs to be triggered externally (e.g., by owner interaction, a keeper bot).
     * Applies a small amount of Temporal Decay based on time elapsed.
     * @param tokenId The ID of the entity to age.
     */
    function ageEntity(uint256 tokenId) public whenNotPaused entityExists(tokenId) {
        // Anyone can call this to trigger aging effects, not just the owner
        // This prevents owners from avoiding decay by never interacting.

        Entity storage entity = entities[tokenId];
        uint256 timePassed = block.timestamp - entity.lastAgedTimestamp;

        if (timePassed == 0) return; // No time passed since last aging

        // Example: 1 integrity lost per day (86400 seconds)
        uint256 decayAmount = (timePassed / 86400) * 1;

        if (decayAmount > 0) {
             applyTemporalDecay(tokenId, decayAmount); // Use the specific decay function
             entity.lastAgedTimestamp = block.timestamp; // Update last aged timestamp
        }
    }

    /**
     * @summary Directly reduces an Entity's temporal integrity.
     * @dev Can be used for passive decay (via ageEntity), quest failures, or other events.
     * @param tokenId The ID of the entity.
     * @param amount The amount of integrity to reduce.
     */
    function applyTemporalDecay(uint256 tokenId, uint256 amount) public whenNotPaused entityExists(tokenId) {
        // No owner check here, as decay can be triggered by time/events outside owner control.

        Entity storage entity = entities[tokenId];
        uint256 newIntegrity = 0;
        if (entity.temporalIntegrity > amount) {
            newIntegrity = entity.temporalIntegrity - amount;
        }

        uint256 actualDecay = entity.temporalIntegrity - newIntegrity;
        entity.temporalIntegrity = uint64(newIntegrity);

        if (actualDecay > 0) {
            emit TemporalDecayApplied(tokenId, actualDecay);
        }
    }

    // --- World State Management ---

    /**
     * @summary Allows users to influence the global temporal alignment state.
     * @dev Spends Essence. The effect scales with the amount and potentially other factors.
     * This is a mechanism for community interaction with the global state.
     * @param influenceAmount The desired influence amount (positive or negative).
     */
    function influenceTemporalAlignment(int256 influenceAmount) public whenNotPaused {
         if (essenceToken == address(0)) revert EssenceContractNotSet();
         if (influenceAmount == 0) return;

        // Example Cost: 10 Essence per 1 point of influence
        uint256 cost = uint256(Math.abs(influenceAmount)) * 10 * 10**18;

        if (IERC20(essenceToken).balanceOf(msg.sender) < cost) {
             revert InsufficientTemporalEssence(cost, IERC20(essenceToken).balanceOf(msg.sender));
        }

        IERC20(essenceToken).transferFrom(msg.sender, address(this), cost);

        // Apply influence, maybe with diminishing returns or cap
        temporalAlignment += influenceAmount;
        // Optional: Clamp alignment between min/max values
        // temporalAlignment = Math.max(temporalAlignment, -1000);
        // temporalAlignment = Math.min(temporalAlignment, 1000);


        emit TemporalAlignmentChanged(temporalAlignment);
    }

     /**
      * @summary Gets the current global temporal alignment value.
      * @return The current temporal alignment.
      */
    function getCurrentTemporalAlignment() public view returns (int256) {
        return temporalAlignment;
    }

    // --- Configuration & Admin ---

    /**
     * @summary Admin function to configure parameters for quests.
     */
    function setQuestParameters(
        uint256 baseCost,
        uint256 baseXPReward,
        uint256 integrityLossOnFailure,
        uint256 successChanceFactor
    ) public onlyOwner {
        questParameters = QuestParameters({
            baseEssenceCost: baseCost,
            baseXPReward: baseXPReward,
            baseIntegrityLossOnFailure: integrityLossOnFailure,
            successChanceFactor: successChanceFactor
        });
    }

     /**
      * @summary Admin function to configure parameters for entity fusion.
      */
    function setFusionParameters(
        uint256 essenceCost,
        uint256 integrityCostPerEntity,
        uint256 attributeInheritanceFactor
    ) public onlyOwner {
         // Basic validation
         if (attributeInheritanceFactor > 100) revert FusionRequirementNotMet("Inheritance factor > 100%");

        fusionParameters = FusionParameters({
            essenceCost: essenceCost,
            integrityCostPerEntity: integrityCostPerEntity,
            attributeInheritanceFactor: attributeInheritanceFactor
        });
    }

    /**
     * @summary Admin function to set the address of the external Temporal Essence ERC-20 token.
     * @dev Can only be set once or changed by owner if needed.
     * @param essenceAddress The address of the Essence token contract.
     */
    function setEssenceContractAddress(address essenceAddress) public onlyOwner {
        if (essenceAddress == address(0)) revert EssenceContractNotSet(); // Or use a specific error
        essenceToken = essenceAddress;
    }

    /**
     * @summary Admin function to pause core gameplay actions.
     */
    function pauseContractActions() public onlyOwner {
        paused = true;
        emit ContractPaused(true);
    }

    /**
     * @summary Admin function to unpause core gameplay actions.
     */
    function unpauseContractActions() public onlyOwner {
        paused = false;
        emit ContractPaused(false);
    }

    /**
     * @summary Admin function to withdraw accumulated TemporalEssence held by the contract.
     * @dev This is for claiming fees collected from minting, quests, fusion, etc.
     */
    function withdrawAdminFees() public onlyOwner {
        if (essenceToken == address(0)) revert EssenceContractNotSet();
        uint256 balance = IERC20(essenceToken).balanceOf(address(this));
        if (balance == 0) revert CannotWithdrawZeroEssence();

        IERC20(essenceToken).transfer(msg.sender, balance);
        emit EssenceWithdrawn(msg.sender, balance);
    }

     /**
      * @summary Admin function to link off-chain metadata (e.g., IPFS hash) to an Entity.
      * @dev Allows updating visual/descriptive data for an Entity.
      * @param tokenId The ID of the entity.
      * @param metadataHash The new metadata hash.
      */
    function setEntityMetadataHash(uint256 tokenId, bytes32 metadataHash) public whenNotPaused entityExists(tokenId) {
        if (entityOwner[tokenId] != msg.sender) {
            revert NotEntityOwner(tokenId, msg.sender);
        }
        entities[tokenId].metadataHash = metadataHash;
        emit EntityMetadataUpdated(tokenId, metadataHash);
    }


    // --- Queries & Helpers ---

     /**
      * @summary Gets the level of an Entity.
      * @param tokenId The ID of the entity.
      * @return The entity's level.
      */
    function getEntityLevel(uint256 tokenId) public view entityExists(tokenId) returns (uint64) {
        return entities[tokenId].level;
    }

     /**
      * @summary Gets the XP of an Entity.
      * @param tokenId The ID of the entity.
      * @return The entity's XP.
      */
    function getEntityXP(uint256 tokenId) public view entityExists(tokenId) returns (uint66) {
        return entities[tokenId].xp;
    }

     /**
      * @summary Gets the temporal integrity of an Entity.
      * @param tokenId The ID of the entity.
      * @return The entity's temporal integrity.
      */
    function getEntityTemporalIntegrity(uint256 tokenId) public view entityExists(tokenId) returns (uint64) {
        return entities[tokenId].temporalIntegrity;
    }

     /**
      * @summary Gets the affinity of an Entity.
      * @param tokenId The ID of the entity.
      * @return The entity's affinity.
      */
    function getEntityAffinity(uint256 tokenId) public view entityExists(tokenId) returns (uint64) {
        return entities[tokenId].affinity;
    }

     /**
      * @summary Gets the birth timestamp of an Entity.
      * @param tokenId The ID of the entity.
      * @return The entity's birth time.
      */
    function getEntityBirthTime(uint256 tokenId) public view entityExists(tokenId) returns (uint256) {
        return entities[tokenId].birthTime;
    }

     /**
      * @summary Gets the metadata hash (for off-chain data) of an Entity.
      * @param tokenId The ID of the entity.
      * @return The entity's metadata hash.
      */
    function getEntityMetadataHash(uint256 tokenId) public view entityExists(tokenId) returns (bytes32) {
        return entities[tokenId].metadataHash;
    }


     /**
      * @summary Gets current quest configuration.
      * @return QuestParameters struct.
      */
    function getQuestParameters() public view returns (QuestParameters memory) {
        return questParameters;
    }

     /**
      * @summary Gets current fusion configuration.
      * @return FusionParameters struct.
      */
    function getFusionParameters() public view returns (FusionParameters memory) {
        return fusionParameters;
    }

     /**
      * @summary Gets the configured Essence token address.
      * @return The address of the Temporal Essence ERC-20 contract.
      */
    function getEssenceContractAddress() public view returns (address) {
        return essenceToken;
    }

     /**
      * @summary Gets the amount of Essence held by the contract (fees collected).
      * @return The contract's balance of Temporal Essence.
      */
    function getProtocolEssenceBalance() public view returns (uint256) {
         if (essenceToken == address(0)) return 0; // Or revert
        return IERC20(essenceToken).balanceOf(address(this));
    }

     /**
      * @summary Checks if the contract is paused.
      * @return True if paused, false otherwise.
      */
    function isContractPaused() public view returns (bool) {
        return paused;
    }

    // Note: A full ERC-721 implementation would require adding
    // tokenURI, getApproved, isApprovedForAll, approve, setApprovalForAll,
    // transferFrom, safeTransferFrom, supportsInterface functions and emitting standard ERC721 events.
    // This example focuses on the unique game logic and state management.
    // The ownership tracking (`entityOwner`, `ownerEntityCount`) and `getEntityOwner`,
    // `getPlayerEntityCount`, `mintEntity`, `burnEntity` provide the core ownership
    // mechanics but do not fully adhere to the ERC721 interface without the other methods.
}
```

**Explanation of Concepts:**

1.  **Dynamic NFTs:** The `Entity` struct holds mutable state (`level`, `xp`, `temporalIntegrity`, `affinity`, `lastAgedTimestamp`, `metadataHash`). These properties change based on function calls (`gainExperience`, `levelUpEntity`, `undertakeTemporalQuest`, `ageEntity`, `applyTemporalDecay`, `upgradeSkill`, `consumeEssence`, `fuseEntities`) and potentially time, making the NFTs non-static.
2.  **Resource Integration (ERC-20):** The contract interacts with an external `TemporalEssence` ERC-20 token (represented by `IERC20`). This token is used as a cost for actions (`mintEntity`, `undertakeTemporalQuest`, `fuseEntities`, `influenceTemporalAlignment`, `consumeEssence`) and potentially as a reward (`undertakeTemporalQuest`). This creates an economic loop. Requires the user to `approve` this contract to spend their Essence tokens before calling functions that require payment.
3.  **Complex Interactions (Quests, Fusion):**
    *   `undertakeTemporalQuest` simulates a probabilistic outcome influenced by entity stats (`affinity`), a global state variable (`temporalAlignment`), and (simplified) pseudo-randomness from block data. It involves costs, gains (XP), and risks (integrity loss).
    *   `fuseEntities` is a burning/minting mechanic where two existing entities are destroyed to create a new one. The new entity's attributes are derived from the parents, adding a layer of strategy/breeding mechanics.
4.  **Time-Based Mechanics (`ageEntity`, `temporalIntegrity`):** Entities have `birthTime` and `lastAgedTimestamp`. The `ageEntity` function (intended to be called periodically) uses the time difference to calculate and apply `temporalDecay`, reducing the entity's integrity. This introduces a maintenance aspect – entities decay over time unless integrity is restored (`consumeEssence`).
5.  **Global State (`temporalAlignment`, `influenceTemporalAlignment`):** The `temporalAlignment` is a contract-wide variable that affects gameplay (e.g., quest success chance). Users can collectively influence this state by spending resources (`influenceTemporalAlignment`), adding a community-driven dynamic element to the game world.
6.  **Modular Configuration:** Parameters for core actions (quests, fusion) and the Essence token address are stored in state variables and can be updated by the owner, allowing for tuning of game balance without redeploying.
7.  **Pausability:** Standard `paused` mechanism implemented for emergency stops.
8.  **Admin Functions & Fee Collection:** Includes functions for the owner to configure game parameters and withdraw collected Essence tokens (`withdrawAdminFees`).
9.  **Off-chain Data Linking:** `metadataHash` field and `setEntityMetadataHash` function allow linking dynamic off-chain data (e.g., JSON metadata, images stored on IPFS) to the on-chain entity ID. The metadata can be updated as the entity's on-chain state changes.
10. **Basic Ownership Tracking:** Includes necessary mappings (`entityOwner`, `ownerEntityCount`) and helper functions (`getEntityOwner`, `getPlayerEntityCount`) to manage entity ownership, similar to how ERC-721 does, though this implementation doesn't strictly adhere to the full ERC-721 interface definition (e.g., lacks `transferFrom`, `approve`, events like `Transfer`, `Approval`). A production version would either inherit ERC721Enumerable or implement its interface fully.

This contract provides a framework for a complex digital asset with evolving properties and interactive mechanics, going significantly beyond a simple static NFT or basic token.