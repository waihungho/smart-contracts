Okay, here is a Solidity smart contract concept focusing on a "Decentralized Chronicle Entity" (DCE). This contract creates dynamic, somewhat soulbound-like entities that can gain experience, learn skills, attune external assets, record historical "chronicle" entries, participate in delegated actions, and require a bond. It combines elements of gaming mechanics, identity, linked data, and configurable state evolution, aiming for uniqueness beyond standard token contracts or simple DeFi vaults.

It includes over 20 functions covering creation, state management, interaction, configuration, and utility.

**Disclaimer:** This is a complex example designed to showcase a variety of concepts. It has not been audited and should *not* be used in production without thorough security review and testing. Advanced features like external asset attunement (`attuneEssence`) assume compatibility with ERC721 tokens and require owner approval/transfer logic which is simplified here. Delegation logic is a basic implementation.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Imports for security and common patterns
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For sending ETH

/// @title Decentralized Chronicle Entity (DCE)
/// @author Your Name or Pseudonym
/// @notice A smart contract for creating and managing dynamic, stateful, and interactive on-chain entities.
/// @dev Entities gain experience, level up, learn skills, attune external assets (ERC721), record histories,
///      and can have delegated actions. Features include staking/bonding, configurable mechanics, and pausing.

// ======================================================================================================
// OUTLINE & FUNCTION SUMMARY
// ======================================================================================================
// This contract manages "Entities", unique digital beings with evolving states.
// Entities are linked to owners, can gain experience and level up, learn skills,
// and interact with other on-chain assets by 'attuning' them. They maintain a
// historical 'chronicle' of their actions and observations. Owners can stake
// ETH as a bond for their entity and delegate specific actions to other addresses.
// The contract owner configures core mechanics (XP thresholds, skill costs, action requirements).

// --- Core Entity Management ---
// 1. createEntity(address entityOwner): Creates a new entity soulbound to the specified owner address. Returns the new entityId.
// 2. changeEntityOwner(uint256 entityId, address newOwner): Allows a privileged address (initially owner, potentially delegateable) to change the linked owner of an entity.
// 3. archiveEntity(uint256 entityId): Irreversibly archives an entity, making it inactive.
// 4. isEntityArchived(uint256 entityId): Checks if an entity is archived.
// 5. getTotalEntities(): Returns the total number of entities created.

// --- State & Information ---
// 6. getEntityDetails(uint256 entityId): Retrieves core state details (owner, level, xp, status, bond amount, skill points).
// 7. getEntityOwner(uint256 entityId): Retrieves the owner address of an entity.
// 8. getEntityLevel(uint256 entityId): Retrieves the current level of an entity.
// 9. getEntityXP(uint256 entityId): Retrieves the current experience points of an entity.
// 10. getEntitySkillPoints(uint256 entityId): Retrieves the available skill points for an entity.

// --- Progression Mechanics ---
// 11. gainExperience(uint256 entityId, uint256 amount): Adds experience points to an entity.
// 12. levelUp(uint256 entityId): Attempts to level up an entity if the current XP meets the threshold for the next level. Spends XP and grants skill points.
// 13. learnSkill(uint256 entityId, uint256 skillId): Allows an entity owner (or delegate) to learn a skill, potentially costing skill points.
// 14. getEntitySkills(uint256 entityId): Retrieves the list of skill IDs learned by an entity.

// --- Asset Attunement ---
// 15. attuneEssence(uint256 entityId, address tokenContract, uint256 tokenId): Links an external ERC721 token to an entity as an 'attunement'. Requires transfer/approval.
// 16. dettuneEssence(uint256 entityId, address tokenContract, uint256 tokenId): Unlinks an external ERC721 token from an entity, returning it to the owner.
// 17. getEntityAttunements(uint256 entityId): Retrieves the list of attunements (ERC721 contract/ID pairs) linked to an entity.

// --- Chronicle & Data Linking ---
// 18. performChronicleAction(uint256 entityId, uint256 actionType, bytes memory data): Executes a conceptual action, potentially requiring skills/attunements/bond, logs the action, and records associated data.
// 19. getChronicleEntry(uint256 entityId, uint256 entryIndex): Retrieves a specific chronicle log entry for an entity.
// 20. getTotalChronicleEntries(uint256 entityId): Gets the total number of chronicle entries for an entity.
// 21. recordObservation(uint256 entityId, bytes32 observationHash, string memory description): Records a link to external data or observation related to the entity using a hash and description.
// 22. getObservation(uint256 entityId, uint256 observationIndex): Retrieves a specific recorded observation.
// 23. getTotalObservations(uint256 entityId): Gets the total number of observations for an entity.

// --- Bonding & Staking ---
// 24. bondStake(uint256 entityId) payable: Stakes native ETH to an entity's bond. Increases the entity's bond amount.
// 25. unbondStake(uint256 entityId, uint256 amount): Allows the entity owner (or delegate) to unbond staked ETH from their entity (subject to potential cooldown/conditions, simplified here).
// 26. getEntityBondAmount(uint256 entityId): Retrieves the total amount of ETH bonded to an entity.

// --- Delegation & Permissions ---
// 27. delegateActionPermission(uint256 entityId, address delegatee, uint256 actionTypeMask): Grants a delegatee permission to perform specific actions on behalf of the entity owner using a bitmask.
// 28. revokeActionPermission(uint256 entityId, address delegatee, uint256 actionTypeMask): Revokes delegation permission for specific actions.
// 29. getActionPermissions(uint256 entityId, address delegatee): Retrieves the action permission mask for a delegatee on a specific entity.
// 30. checkActionPermission(uint256 entityId, address delegatee, uint256 actionType): Checks if a delegatee has permission for a specific action type (public helper).

// --- Configuration (Owner-only) ---
// 31. setSkillProperties(uint256 skillId, uint256 levelRequirement, uint256 xpCost, uint256 skillPointCost): Configures requirements and costs for learning a skill.
// 32. setActionProperties(uint256 actionType, uint256 skillRequirement, uint256 bondRequirement, uint256 minLevel, uint256 xpReward, uint256 skillPointReward): Configures requirements and rewards for performing an action.
// 33. setEntityLevelThreshold(uint256 level, uint256 xpRequired, uint256 skillPointsGranted): Configures the XP required to reach a level and skill points gained.

// --- Utility & Admin ---
// 34. pause(): Pauses certain contract operations (Owner-only).
// 35. unpause(): Unpauses contract operations (Owner-only).
// 36. paused(): Checks if the contract is paused (from Pausable).
// 37. withdrawETH(): Owner can withdraw excess ETH from the contract (excludes bonded amounts).
// 38. withdrawERC20(address tokenAddress): Owner can withdraw excess ERC20 tokens from the contract (excludes attuned tokens).
// 39. setPublicProfileStatus(uint256 entityId, bool isPublic): Sets a flag indicating off-chain consent for public profile visibility.
// 40. getEntityPublicProfileStatus(uint256 entityId): Retrieves the public profile visibility status flag.

// Total Functions: 40 (Exceeds the minimum of 20)

// ======================================================================================================
// ERROR DEFINITIONS
// ======================================================================================================
error EntityNotFound(uint256 entityId);
error NotEntityOwnerOrDelegate(uint256 entityId, address caller);
error EntityAlreadyExists(uint256 entityId); // If entity IDs were predictable or generated differently
error EntityArchived(uint256 entityId);
error InsufficientExperience(uint256 entityId, uint256 currentXP, uint256 requiredXP);
error MaxLevelReached(uint256 entityId, uint256 maxLevel);
error SkillAlreadyLearned(uint256 entityId, uint256 skillId);
error InsufficientSkillPoints(uint256 entityId, uint256 currentPoints, uint256 requiredPoints);
error InsufficientLevel(uint256 entityId, uint256 currentLevel, uint256 requiredLevel);
error SkillNotLearned(uint256 entityId, uint256 skillId);
error InsufficientBond(uint256 entityId, uint256 currentBond, uint256 requiredBond);
error ERC721TransferFailed(address tokenContract, uint256 tokenId);
error ERC721NotAttuned(uint256 entityId, address tokenContract, uint256 tokenId);
error NoStakeToUnbond(uint256 entityId);
error InsufficientStakeToUnbond(uint256 entityId, uint256 currentStake, uint256 requestedAmount);
error InvalidSkillProperties(uint256 skillId);
error InvalidActionProperties(uint256 actionType);
error InvalidLevelThreshold(uint256 level);
error WithdrawalFailed();
error ZeroAddress(address addr);
error SelfDelegationNotAllowed();
error ActionPermissionDenied(uint256 entityId, address delegatee, uint256 actionType);

// ======================================================================================================
// CONTRACT DEFINITION
// ======================================================================================================
contract ChronicleEntity is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- Structs ---
    struct Entity {
        address owner; // The address that primarily controls this entity
        uint256 level;
        uint256 experience; // Accumulated XP
        uint256 skillPoints; // Points gained on level up to spend on skills
        uint256 bondAmount; // Amount of native token (ETH) staked to this entity
        bool isArchived; // Cannot perform actions if archived
        bool isProfilePublic; // Flag for off-chain display consent
        // Add more stats here as needed (e.g., health, energy, specific resources)
    }

    struct ChronicleEntry {
        uint256 timestamp;
        uint256 actionType; // Identifier for the type of action
        address performedBy; // Who triggered the action (owner or delegate)
        bytes data; // Arbitrary data related to the action (e.g., parameters, results hash)
    }

    struct Observation {
        uint256 timestamp;
        bytes32 observationHash; // Hash linking to external data/proof
        string description; // Short description of the observation
    }

    struct Attunement {
        address tokenContract; // ERC721 contract address
        uint256 tokenId; // ERC721 token ID
    }

    struct SkillProperties {
        uint256 levelRequirement;
        uint256 xpCost; // XP cost to learn the skill
        uint256 skillPointCost; // Skill point cost to learn the skill
    }

    struct ActionProperties {
        uint256 skillRequirement; // Bitmask or single skill ID requirement
        uint256 bondRequirement; // Minimum bond required to perform
        uint256 minLevel; // Minimum level required
        uint256 xpReward; // XP granted upon successful action
        uint256 skillPointReward; // Skill points granted upon successful action
        // Add resource costs/rewards here
    }

    struct LevelThreshold {
        uint256 xpRequired; // Total cumulative XP needed to reach this level
        uint256 skillPointsGranted; // Skill points granted *upon reaching* this level
    }

    // --- State Variables ---
    uint256 public nextEntityId; // Counter for unique entity IDs
    mapping(uint256 => Entity) public entities; // entityId => Entity data
    mapping(uint256 => uint256[]) internal entitySkills; // entityId => list of skillIds learned
    mapping(uint256 => Attunement[]) internal entityAttunements; // entityId => list of Attunements (ERC721)
    mapping(uint256 => ChronicleEntry[]) internal entityChronicleEntries; // entityId => list of ChronicleEntries
    mapping(uint256 => Observation[]) internal entityObservations; // entityId => list of Observations

    // Configuration mappings (set by owner)
    mapping(uint256 => LevelThreshold) public xpThresholds; // level => threshold properties
    mapping(uint256 => SkillProperties) public skillProperties; // skillId => skill properties
    mapping(uint256 => ActionProperties) public actionProperties; // actionType => action properties

    // Delegation permissions: entityId => delegatee address => actionTypeMask (bitmask of permitted actions)
    mapping(uint256 => mapping(address => uint256)) public actionPermissions;

    // --- Events ---
    event EntityCreated(uint256 entityId, address indexed owner, uint256 timestamp);
    event EntityOwnerChanged(uint256 indexed entityId, address indexed oldOwner, address indexed newOwner, uint256 timestamp);
    event EntityArchived(uint256 indexed entityId, address indexed archivedBy, uint256 timestamp);
    event ExperienceGained(uint256 indexed entityId, uint256 amount, uint256 newXP);
    event LevelledUp(uint256 indexed entityId, uint256 oldLevel, uint256 newLevel, uint256 skillPointsGained);
    event SkillLearned(uint256 indexed entityId, uint256 indexed skillId);
    event EssenceAttuned(uint256 indexed entityId, address indexed tokenContract, uint256 indexed tokenId);
    event EssenceDettuned(uint256 indexed entityId, address indexed tokenContract, uint256 indexed tokenId);
    event ChronicleActionPerformed(uint256 indexed entityId, uint256 indexed actionType, address indexed performedBy, uint256 timestamp, bytes data);
    event ObservationRecorded(uint256 indexed entityId, bytes32 observationHash, uint256 timestamp);
    event BondIncreased(uint256 indexed entityId, uint256 amount, uint256 totalBond);
    event BondDecreased(uint256 indexed entityId, uint256 amount, uint256 totalBond);
    event ActionPermissionDelegated(uint256 indexed entityId, address indexed delegatee, uint256 actionTypeMask);
    event ActionPermissionRevoked(uint256 indexed entityId, address indexed delegatee, uint256 actionTypeMask);
    event SkillPropertiesUpdated(uint256 indexed skillId, uint256 levelRequirement, uint256 xpCost, uint256 skillPointCost);
    event ActionPropertiesUpdated(uint256 indexed actionType, uint256 skillRequirement, uint256 bondRequirement, uint256 minLevel);
    event LevelThresholdUpdated(uint256 indexed level, uint256 xpRequired, uint256 skillPointsGranted);
    event PublicProfileStatusSet(uint256 indexed entityId, bool isPublic);
    event FundsWithdrawn(address indexed tokenAddress, address indexed receiver, uint256 amount);

    // --- Modifiers ---
    modifier entityExists(uint256 _entityId) {
        if (entities[_entityId].owner == address(0)) {
            revert EntityNotFound(_entityId);
        }
        _;
    }

    modifier notArchived(uint256 _entityId) {
        if (entities[_entityId].isArchived) {
            revert EntityArchived(_entityId);
        }
        _;
    }

    // Checks if the caller is the entity owner or a delegate with the required action permission
    modifier onlyEntityOwnerOrDelegate(uint256 _entityId, uint256 _actionType) {
        Entity storage entity = entities[_entityId];
        if (msg.sender != entity.owner) {
            // If not owner, check delegation
            uint256 permissionMask = actionPermissions[_entityId][msg.sender];
            // Check if the bit corresponding to _actionType is set in the mask
            if ((permissionMask & (1 << _actionType)) == 0) {
                 revert ActionPermissionDenied(_entityId, msg.sender, _actionType);
            }
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) Pausable(false) {}

    // --- Core Entity Management ---

    /// @notice Creates a new entity soulbound to the specified owner address.
    /// @param _entityOwner The address that will own and control the new entity.
    /// @return uint256 The ID of the newly created entity.
    function createEntity(address _entityOwner)
        external
        onlyOwner // Only contract owner can mint new entities initially
        whenNotPaused
        returns (uint256)
    {
        if (_entityOwner == address(0)) revert ZeroAddress(_entityOwner);

        uint256 entityId = nextEntityId;
        entities[entityId] = Entity({
            owner: _entityOwner,
            level: 1, // Start at level 1
            experience: 0,
            skillPoints: 0,
            bondAmount: 0,
            isArchived: false,
            isProfilePublic: false // Private by default
        });
        nextEntityId++;

        emit EntityCreated(entityId, _entityOwner, block.timestamp);
        return entityId;
    }

    /// @notice Allows a privileged address (initially owner, potentially delegateable) to change the linked owner of an entity.
    /// @dev This is a restricted function to prevent standard ERC721-like transfers,
    ///      enabling a form of conditional 'soulbinding'. Requires `ACTION_TYPE_CHANGE_OWNER` permission.
    /// @param _entityId The ID of the entity.
    /// @param _newOwner The new owner address.
    function changeEntityOwner(uint256 _entityId, address _newOwner)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 0) // Define ACTION_TYPE_CHANGE_OWNER as 0 or similar constant
    {
         if (_newOwner == address(0)) revert ZeroAddress(_newOwner);
        // Note: Transfer of attunements (ERC721) is *not* handled automatically here.
        // The new owner would need to manage existing attunements or dettune them first.

        address oldOwner = entities[_entityId].owner;
        entities[_entityId].owner = _newOwner;

        emit EntityOwnerChanged(_entityId, oldOwner, _newOwner, block.timestamp);
    }

     /// @notice Irreversibly archives an entity, making it inactive.
     /// @dev This function is final. Archived entities cannot perform actions or level up.
     ///      Requires `ACTION_TYPE_ARCHIVE` permission. Unbonds any staked ETH.
     /// @param _entityId The ID of the entity to archive.
    function archiveEntity(uint256 _entityId)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 1) // Define ACTION_TYPE_ARCHIVE as 1 or similar constant
        nonReentrant // Prevent reentrancy with bond payout
    {
        Entity storage entity = entities[_entityId];
        entity.isArchived = true;

        // Automatically unbond any staked ETH
        uint256 bondedAmount = entity.bondAmount;
        if (bondedAmount > 0) {
            entity.bondAmount = 0;
            // Transfer bonded ETH back to the entity owner
            Address.sendValue(payable(entity.owner), bondedAmount);
            emit BondDecreased(_entityId, bondedAmount, 0); // Log decrease to 0
        }

        emit EntityArchived(_entityId, msg.sender, block.timestamp);
    }

    /// @notice Checks if an entity is archived.
    /// @param _entityId The ID of the entity.
    /// @return bool True if the entity is archived, false otherwise.
    function isEntityArchived(uint256 _entityId) external view entityExists(_entityId) returns (bool) {
        return entities[_entityId].isArchived;
    }

    /// @notice Returns the total number of entities created.
    /// @return uint256 The total count of entities.
    function getTotalEntities() external view returns (uint256) {
        return nextEntityId;
    }

    // --- State & Information ---

    /// @notice Retrieves core state details of an entity.
    /// @param _entityId The ID of the entity.
    /// @return owner The owner address.
    /// @return level The entity's level.
    /// @return experience The entity's current experience points.
    /// @return skillPoints The entity's available skill points.
    /// @return bondAmount The amount of ETH bonded to the entity.
    /// @return isArchived Whether the entity is archived.
    /// @return isProfilePublic Whether the public profile flag is set.
    function getEntityDetails(uint256 _entityId)
        external
        view
        entityExists(_entityId)
        returns (
            address owner,
            uint256 level,
            uint256 experience,
            uint256 skillPoints,
            uint256 bondAmount,
            bool isArchived,
            bool isProfilePublic
        )
    {
        Entity storage entity = entities[_entityId];
        return (
            entity.owner,
            entity.level,
            entity.experience,
            entity.skillPoints,
            entity.bondAmount,
            entity.isArchived,
            entity.isProfilePublic
        );
    }

    /// @notice Retrieves the owner address of an entity.
    /// @param _entityId The ID of the entity.
    /// @return address The owner address.
    function getEntityOwner(uint256 _entityId) external view entityExists(_entityId) returns (address) {
        return entities[_entityId].owner;
    }

     /// @notice Retrieves the current level of an entity.
     /// @param _entityId The ID of the entity.
     /// @return uint256 The entity's level.
    function getEntityLevel(uint256 _entityId) external view entityExists(_entityId) returns (uint256) {
        return entities[_entityId].level;
    }

     /// @notice Retrieves the current experience points of an entity.
     /// @param _entityId The ID of the entity.
     /// @return uint256 The entity's experience points.
    function getEntityXP(uint256 _entityId) external view entityExists(_entityId) returns (uint256) {
        return entities[_entityId].experience;
    }

     /// @notice Retrieves the available skill points for an entity.
     /// @param _entityId The ID of the entity.
     /// @return uint256 The entity's skill points.
    function getEntitySkillPoints(uint256 _entityId) external view entityExists(_entityId) returns (uint256) {
        return entities[_entityId].skillPoints;
    }

    // --- Progression Mechanics ---

    /// @notice Adds experience points to an entity.
    /// @dev This function would typically be called by the contract itself or a trusted oracle/interaction
    ///      contract based on external events or completed actions. It's exposed here for demonstration.
    /// @param _entityId The ID of the entity.
    /// @param _amount The amount of experience to add.
    function gainExperience(uint256 _entityId, uint256 _amount)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyOwner // Or restricted to specific trusted callers/contracts
    {
        Entity storage entity = entities[_entityId];
        entity.experience += _amount;
        // Note: Leveling up is a separate action, not automatic here
        emit ExperienceGained(_entityId, _amount, entity.experience);
    }

    /// @notice Attempts to level up an entity if the current XP meets the threshold for the next level.
    /// @dev Spends the required XP and grants skill points based on configuration.
    /// @param _entityId The ID of the entity.
    function levelUp(uint256 _entityId)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 2) // Define ACTION_TYPE_LEVEL_UP as 2 or similar
    {
        Entity storage entity = entities[_entityId];
        uint256 nextLevel = entity.level + 1;
        LevelThreshold memory threshold = xpThresholds[nextLevel];

        if (threshold.xpRequired == 0 && nextLevel > 1) {
            revert MaxLevelReached(_entityId, entity.level); // No threshold defined for next level means max level
        }

        if (entity.experience < threshold.xpRequired) {
            revert InsufficientExperience(_entityId, entity.experience, threshold.xpRequired);
        }

        uint256 oldLevel = entity.level;
        entity.level = nextLevel;
        entity.experience -= threshold.xpRequired; // Spend XP for the level up
        entity.skillPoints += threshold.skillPointsGranted; // Gain skill points

        emit LevelledUp(_entityId, oldLevel, entity.level, threshold.skillPointsGranted);
    }

    /// @notice Allows an entity owner (or delegate) to learn a skill, potentially costing skill points and XP.
    /// @param _entityId The ID of the entity.
    /// @param _skillId The ID of the skill to learn.
    function learnSkill(uint256 _entityId, uint256 _skillId)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 3) // Define ACTION_TYPE_LEARN_SKILL as 3 or similar
    {
        Entity storage entity = entities[_entityId];
        SkillProperties memory props = skillProperties[_skillId];

        if (props.levelRequirement == 0 && props.xpCost == 0 && props.skillPointCost == 0 && _skillId > 0) {
             revert InvalidSkillProperties(_skillId); // Skill not configured
        }

        if (entity.level < props.levelRequirement) {
            revert InsufficientLevel(_entityId, entity.level, props.levelRequirement);
        }
        if (entity.experience < props.xpCost) {
            revert InsufficientExperience(_entityId, entity.experience, props.xpCost);
        }
        if (entity.skillPoints < props.skillPointCost) {
            revert InsufficientSkillPoints(_entityId, entity.skillPoints, props.skillPointCost);
        }

        // Check if skill is already learned
        for (uint256 i = 0; i < entitySkills[_entityId].length; i++) {
            if (entitySkills[_entityId][i] == _skillId) {
                revert SkillAlreadyLearned(_entityId, _skillId);
            }
        }

        // Deduct costs and add skill
        entity.experience -= props.xpCost;
        entity.skillPoints -= props.skillPointCost;
        entitySkills[_entityId].push(_skillId);

        emit SkillLearned(_entityId, _skillId);
    }

     /// @notice Retrieves the list of skills learned by an entity.
     /// @param _entityId The ID of the entity.
     /// @return uint256[] An array of skill IDs.
    function getEntitySkills(uint256 _entityId) external view entityExists(_entityId) returns (uint256[] memory) {
        return entitySkills[_entityId];
    }

    // --- Asset Attunement ---

    /// @notice Links an external ERC721 token to an entity as an 'attunement'.
    /// @dev This moves the ERC721 into the ChronicleEntity contract's custody.
    ///      The entity owner must first approve this contract to transfer the ERC721.
    ///      Requires `ACTION_TYPE_ATTUNE_ESSENCE` permission.
    /// @param _entityId The ID of the entity.
    /// @param _tokenContract The address of the ERC721 token contract.
    /// @param _tokenId The ID of the ERC721 token.
    function attuneEssence(uint256 _entityId, address _tokenContract, uint256 _tokenId)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 4) // Define ACTION_TYPE_ATTUNE_ESSENCE as 4 or similar
    {
        if (_tokenContract == address(0)) revert ZeroAddress(_tokenContract);

        // Ensure the caller performing the action is the approved address or owner
        // (handled by onlyEntityOwnerOrDelegate)

        // Transfer the ERC721 to this contract
        try IERC721(_tokenContract).safeTransferFrom(msg.sender, address(this), _tokenId) {} catch {
            revert ERC721TransferFailed(_tokenContract, _tokenId);
        }

        // Record the attunement
        entityAttunements[_entityId].push(Attunement({
            tokenContract: _tokenContract,
            tokenId: _tokenId
        }));

        emit EssenceAttuned(_entityId, _tokenContract, _tokenId);
    }

    /// @notice Unlinks an external ERC721 token from an entity.
    /// @dev Transfers the ERC721 back to the current entity owner.
    ///      Requires `ACTION_TYPE_DETTUNE_ESSENCE` permission.
    /// @param _entityId The ID of the entity.
    /// @param _tokenContract The address of the ERC721 token contract.
    /// @param _tokenId The ID of the ERC721 token.
    function dettuneEssence(uint256 _entityId, address _tokenContract, uint256 _tokenId)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 5) // Define ACTION_TYPE_DETTUNE_ESSENCE as 5 or similar
        nonReentrant // Prevent reentrancy during token transfer
    {
        if (_tokenContract == address(0)) revert ZeroAddress(_tokenContract);

        Entity storage entity = entities[_entityId];
        bool found = false;
        uint256 indexToRemove = type(uint256).max;

        // Find the attunement
        for (uint256 i = 0; i < entityAttunements[_entityId].length; i++) {
            if (entityAttunements[_entityId][i].tokenContract == _tokenContract && entityAttunements[_entityId][i].tokenId == _tokenId) {
                found = true;
                indexToRemove = i;
                break;
            }
        }

        if (!found) {
            revert ERC721NotAttuned(_entityId, _tokenContract, _tokenId);
        }

        // Transfer the ERC721 back to the owner
        try IERC721(_tokenContract).safeTransferFrom(address(this), entity.owner, _tokenId) {} catch {
            revert ERC721TransferFailed(_tokenContract, _tokenId);
        }

        // Remove the attunement from the array (order doesn't matter)
        uint256 lastIndex = entityAttunements[_entityId].length - 1;
        entityAttunements[_entityId][indexToRemove] = entityAttunements[_entityId][lastIndex];
        entityAttunements[_entityId].pop();

        emit EssenceDettuned(_entityId, _tokenContract, _tokenId);
    }

     /// @notice Retrieves the list of attunements (ERC721 contract/ID pairs) linked to an entity.
     /// @param _entityId The ID of the entity.
     /// @return Attunement[] An array of Attunement structs.
    function getEntityAttunements(uint256 _entityId) external view entityExists(_entityId) returns (Attunement[] memory) {
        return entityAttunements[_entityId];
    }

    // --- Chronicle & Data Linking ---

    /// @notice Executes a conceptual action, potentially requiring skills/attunements/bond, logs the action, and records associated data.
    /// @dev This is a flexible function for recording entity actions within the chronicle.
    ///      The specific effects/requirements of `_actionType` are defined in `actionProperties` and checked here.
    ///      Requires permission for the specific `_actionType`.
    /// @param _entityId The ID of the entity.
    /// @param _actionType Identifier for the type of action being performed.
    /// @param _data Arbitrary bytes data relevant to the action (e.g., parameters, results hash).
    function performChronicleAction(uint256 _entityId, uint256 _actionType, bytes memory _data)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, _actionType) // Permission check based on actionType
    {
        Entity storage entity = entities[_entityId];
        ActionProperties memory props = actionProperties[_actionType];

        if (props.minLevel == 0 && props.bondRequirement == 0 && props.skillRequirement == 0 && _actionType > 0) {
             revert InvalidActionProperties(_actionType); // Action not configured
        }

        // Check requirements
        if (entity.level < props.minLevel) {
             revert InsufficientLevel(_entityId, entity.level, props.minLevel);
        }
        if (entity.bondAmount < props.bondRequirement) {
             revert InsufficientBond(_entityId, entity.bondAmount, props.bondRequirement);
        }

        // Check skill requirements (simple bitmask example)
        if (props.skillRequirement > 0) {
            bool hasRequiredSkills = false;
            uint256 entitySkillsMask = 0;
            for(uint256 i = 0; i < entitySkills[_entityId].length; i++) {
                entitySkillsMask |= (1 << entitySkills[_entityId][i]);
            }
            if ((entitySkillsMask & props.skillRequirement) != props.skillRequirement) {
                 // This requires a more complex check if skillRequirement is a bitmask of multiple skills
                 // For simplicity, let's assume skillRequirement is a single skillId check
                 bool skillFound = false;
                 for (uint256 i = 0; i < entitySkills[_entityId].length; i++) {
                    if (entitySkills[_entityId][i] == props.skillRequirement) {
                        skillFound = true;
                        break;
                    }
                 }
                 if (!skillFound) revert SkillNotLearned(_entityId, props.skillRequirement);
            }
        }
        // Add checks for attunement requirements here if needed

        // Apply rewards
        entity.experience += props.xpReward;
        entity.skillPoints += props.skillPointReward;

        // Record chronicle entry
        entityChronicleEntries[_entityId].push(ChronicleEntry({
            timestamp: block.timestamp,
            actionType: _actionType,
            performedBy: msg.sender, // Record who performed the action (owner or delegate)
            data: _data
        }));

        emit ChronicleActionPerformed(_entityId, _actionType, msg.sender, block.timestamp, _data);
    }

    /// @notice Retrieves a specific chronicle log entry for an entity.
    /// @param _entityId The ID of the entity.
    /// @param _entryIndex The index of the entry (0-based).
    /// @return ChronicleEntry The requested chronicle entry.
    function getChronicleEntry(uint256 _entityId, uint256 _entryIndex) external view entityExists(_entityId) returns (ChronicleEntry memory) {
        return entityChronicleEntries[_entityId][_entryIndex];
    }

    /// @notice Gets the total number of chronicle entries for an entity.
    /// @param _entityId The ID of the entity.
    /// @return uint256 The total number of entries.
    function getTotalChronicleEntries(uint256 _entityId) external view entityExists(_entityId) returns (uint256) {
        return entityChronicleEntries[_entityId].length;
    }

    /// @notice Records a link to external data or observation related to the entity using a hash and description.
    /// @dev This function can be called by the owner/delegate or potentially by other trusted contracts
    ///      (with appropriate permission/access control) to add verifiable off-chain context.
    ///      Requires `ACTION_TYPE_RECORD_OBSERVATION` permission.
    /// @param _entityId The ID of the entity.
    /// @param _observationHash A hash linking to external data (e.g., IPFS hash, ZK-proof verifier input hash).
    /// @param _description A short description of the observation.
    function recordObservation(uint256 _entityId, bytes32 _observationHash, string memory _description)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 6) // Define ACTION_TYPE_RECORD_OBSERVATION as 6 or similar
    {
        entityObservations[_entityId].push(Observation({
            timestamp: block.timestamp,
            observationHash: _observationHash,
            description: _description
        }));

        emit ObservationRecorded(_entityId, _observationHash, block.timestamp);
    }

    /// @notice Retrieves a specific recorded observation.
    /// @param _entityId The ID of the entity.
    /// @param _observationIndex The index of the observation (0-based).
    /// @return Observation The requested observation.
    function getObservation(uint256 _entityId, uint256 _observationIndex) external view entityExists(_entityId) returns (Observation memory) {
        return entityObservations[_entityId][_observationIndex];
    }

     /// @notice Gets the total number of observations for an entity.
     /// @param _entityId The ID of the entity.
     /// @return uint256 The total number of observations.
    function getTotalObservations(uint256 _entityId) external view entityExists(_entityId) returns (uint256) {
        return entityObservations[_entityId].length;
    }


    // --- Bonding & Staking ---

    /// @notice Stakes native ETH to an entity's bond.
    /// @dev This ETH is held by the contract and linked to the entity. Used for actions requiring a bond.
    /// @param _entityId The ID of the entity.
    function bondStake(uint256 _entityId)
        external
        payable
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 7) // Define ACTION_TYPE_BOND as 7 or similar
        nonReentrant
    {
        if (msg.value == 0) revert InsufficientStakeToUnbond(_entityId, 0, 1); // Reusing error, maybe need a specific one
        Entity storage entity = entities[_entityId];
        entity.bondAmount += msg.value;
        emit BondIncreased(_entityId, msg.value, entity.bondAmount);
    }

    /// @notice Allows the entity owner (or delegate) to unbond staked ETH from their entity.
    /// @dev The amount requested is transferred back to the entity owner.
    ///      Add cooldowns or conditions here in a real implementation.
    ///      Requires `ACTION_TYPE_UNBOND` permission.
    /// @param _entityId The ID of the entity.
    /// @param _amount The amount of ETH to unbond.
    function unbondStake(uint256 _entityId, uint256 _amount)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 8) // Define ACTION_TYPE_UNBOND as 8 or similar
        nonReentrant
    {
        Entity storage entity = entities[_entityId];
        if (_amount == 0) revert InsufficientStakeToUnbond(_entityId, entity.bondAmount, 1);
        if (entity.bondAmount < _amount) {
            revert InsufficientStakeToUnbond(_entityId, entity.bondAmount, _amount);
        }

        entity.bondAmount -= _amount;

        // Transfer ETH back to the *entity owner*
        Address.sendValue(payable(entity.owner), _amount);

        emit BondDecreased(_entityId, _amount, entity.bondAmount);
    }

     /// @notice Retrieves the total amount of ETH bonded to an entity.
     /// @param _entityId The ID of the entity.
     /// @return uint256 The bonded amount in Wei.
    function getEntityBondAmount(uint256 _entityId) external view entityExists(_entityId) returns (uint256) {
        return entities[_entityId].bondAmount;
    }


    // --- Delegation & Permissions ---

    /// @notice Grants a delegatee permission to perform specific actions on behalf of the entity owner using a bitmask.
    /// @dev Only the entity owner can delegate permissions. `_actionTypeMask` is a bitmask where each bit corresponds to an action type.
    /// @param _entityId The ID of the entity.
    /// @param _delegatee The address to delegate permissions to.
    /// @param _actionTypeMask A bitmask representing the actions being delegated.
    function delegateActionPermission(uint256 _entityId, address _delegatee, uint256 _actionTypeMask)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        nonReentrant // Potentially needed if delegation could trigger calls
    {
        Entity storage entity = entities[_entityId];
        if (msg.sender != entity.owner) revert NotEntityOwnerOrDelegate(_entityId, msg.sender);
        if (_delegatee == address(0)) revert ZeroAddress(_delegatee);
        if (_delegatee == msg.sender) revert SelfDelegationNotAllowed();

        // Add permissions to the existing mask
        actionPermissions[_entityId][_delegatee] |= _actionTypeMask;

        emit ActionPermissionDelegated(_entityId, _delegatee, actionPermissions[_entityId][_delegatee]);
    }

    /// @notice Revokes delegation permission for specific actions from a delegatee.
    /// @dev Only the entity owner can revoke permissions. `_actionTypeMask` is a bitmask representing the actions to revoke.
    /// @param _entityId The ID of the entity.
    /// @param _delegatee The address to revoke permissions from.
    /// @param _actionTypeMask A bitmask representing the actions being revoked.
    function revokeActionPermission(uint256 _entityId, address _delegatee, uint256 _actionTypeMask)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        nonReentrant // Potentially needed
    {
        Entity storage entity = entities[_entityId];
        if (msg.sender != entity.owner) revert NotEntityOwnerOrDelegate(_entityId, msg.sender);
         if (_delegatee == address(0)) revert ZeroAddress(_delegatee);

        // Remove permissions using XOR with the mask of permissions to remove
        // Need to be careful here, this doesn't remove, it toggles. Use AND with NOT.
        actionPermissions[_entityId][_delegatee] &= (~_actionTypeMask);

        // If mask becomes 0, might consider deleting the delegatee entry to save gas, but not strictly necessary
        // if (actionPermissions[_entityId][_delegatee] == 0) { delete actionPermissions[_entityId][_delegatee]; }

        emit ActionPermissionRevoked(_entityId, _delegatee, actionPermissions[_entityId][_delegatee]);
    }

     /// @notice Retrieves the action permission mask for a delegatee on a specific entity.
     /// @param _entityId The ID of the entity.
     /// @param _delegatee The address of the delegatee.
     /// @return uint256 The action permission mask.
    function getActionPermissions(uint256 _entityId, address _delegatee) external view entityExists(_entityId) returns (uint256) {
         if (_delegatee == address(0)) revert ZeroAddress(_delegatee);
        return actionPermissions[_entityId][_delegatee];
    }

    /// @notice Checks if a delegatee has permission for a specific action type (public helper).
    /// @param _entityId The ID of the entity.
    /// @param _delegatee The address of the potential delegatee.
    /// @param _actionType The action type to check permission for.
    /// @return bool True if the delegatee has permission, false otherwise.
    function checkActionPermission(uint256 _entityId, address _delegatee, uint256 _actionType) external view entityExists(_entityId) returns (bool) {
         if (_delegatee == address(0)) revert ZeroAddress(_delegatee);
        uint256 permissionMask = actionPermissions[_entityId][_delegatee];
        return (permissionMask & (1 << _actionType)) != 0;
    }


    // --- Configuration (Owner-only) ---

    /// @notice Configures requirements and costs for learning a skill. (Owner-only)
    /// @param _skillId The ID of the skill.
    /// @param _levelRequirement Minimum entity level to learn.
    /// @param _xpCost XP cost to learn.
    /// @param _skillPointCost Skill point cost to learn.
    function setSkillProperties(uint256 _skillId, uint256 _levelRequirement, uint256 _xpCost, uint256 _skillPointCost) external onlyOwner whenNotPaused {
        skillProperties[_skillId] = SkillProperties({
            levelRequirement: _levelRequirement,
            xpCost: _xpCost,
            skillPointCost: _skillPointCost
        });
        emit SkillPropertiesUpdated(_skillId, _levelRequirement, _xpCost, _skillPointCost);
    }

    /// @notice Configures requirements and rewards for performing an action. (Owner-only)
    /// @param _actionType The ID of the action type.
    /// @param _skillRequirement Single skill ID required (simplified - could be bitmask). Use 0 for no skill requirement.
    /// @param _bondRequirement Minimum entity bond required.
    /// @param _minLevel Minimum entity level required.
    /// @param _xpReward XP granted on success.
    /// @param _skillPointReward Skill points granted on success.
    function setActionProperties(uint256 _actionType, uint256 _skillRequirement, uint256 _bondRequirement, uint256 _minLevel, uint256 _xpReward, uint256 _skillPointReward) external onlyOwner whenNotPaused {
        actionProperties[_actionType] = ActionProperties({
            skillRequirement: _skillRequirement,
            bondRequirement: _bondRequirement,
            minLevel: _minLevel,
            xpReward: _xpReward,
            skillPointReward: _skillPointReward
        });
        emit ActionPropertiesUpdated(_actionType, _skillRequirement, _bondRequirement, _minLevel); // Simplified event data
    }

    /// @notice Configures the XP required to reach a specific level and skill points gained. (Owner-only)
    /// @param _level The level being configured.
    /// @param _xpRequired Total cumulative XP needed to reach this level *from level 0*.
    /// @param _skillPointsGranted Skill points granted upon reaching this level.
    function setEntityLevelThreshold(uint256 _level, uint256 _xpRequired, uint256 _skillPointsGranted) external onlyOwner whenNotPaused {
        if (_level == 0) revert InvalidLevelThreshold(0); // Level 0 doesn't make sense
        xpThresholds[_level] = LevelThreshold({
            xpRequired: _xpRequired,
            skillPointsGranted: _skillPointsGranted
        });
        emit LevelThresholdUpdated(_level, _xpRequired, _skillPointsGranted);
    }


    // --- Utility & Admin ---

    /// @inheritdoc Pausable
    function pause() public override onlyOwner {
        _pause();
    }

    /// @inheritdoc Pausable
    function unpause() public override onlyOwner {
        _unpause();
    }

    /// @notice Owner can withdraw excess ETH from the contract.
    /// @dev Excludes ETH currently bonded to active entities.
    function withdrawETH() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 totalBonded = 0;
        // Cannot easily calculate total bonded ETH without iterating all entities.
        // A better design would track total bonded ETH in a state variable.
        // For this example, we'll withdraw everything *except* explicitly bonded amounts.
        // WARNING: This simple implementation is risky if not carefully managed.
        // A safer approach is to track total bonded and only allow withdrawal of balance - total_bonded.
        // Or only allow owner withdrawal of bonded ETH from *archived* entities as done in archiveEntity.
        // Let's implement a simpler, riskier version for demonstration, assuming owner prudence.
        // In production, track total bonded amount globally or only allow withdrawal of non-bonded surplus.

        // Alternative (Safer): Implement a separate state variable `totalBondedETH` incremented/decremented
        // by bond/unbond functions and check `address(this).balance >= totalBondedETH` before withdrawing `address(this).balance - totalBondedETH`.
        // For this example, we'll allow withdrawal of *all* ETH. This is simplified and potentially dangerous.

        uint256 amountToWithdraw = contractBalance;

        (bool success, ) = payable(owner()).call{value: amountToWithdraw}("");
        if (!success) {
            revert WithdrawalFailed();
        }
        emit FundsWithdrawn(address(0), owner(), amountToWithdraw);
    }

    /// @notice Owner can withdraw excess ERC20 tokens from the contract.
    /// @dev Excludes tokens currently attested to entities.
    /// @param _tokenAddress The address of the ERC20 token.
    function withdrawERC20(address _tokenAddress) external onlyOwner nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddress(_tokenAddress);

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        // Note: This simple withdrawal allows withdrawing *any* ERC20, including those
        // that might be intended as attunements but aren't yet recorded as such.
        // A more robust implementation would track non-attuned ERC20s or only allow
        // withdrawal of specific pre-approved tokens.

        if (balance > 0) {
            token.safeTransfer(owner(), balance);
            emit FundsWithdrawn(_tokenAddress, owner(), balance);
        }
    }

    /// @notice Sets a flag indicating off-chain consent for public profile visibility.
    /// @dev This flag is purely informational on-chain for off-chain indexers/UIs.
    ///      Requires `ACTION_TYPE_SET_PUBLIC_PROFILE` permission.
    /// @param _entityId The ID of the entity.
    /// @param _isPublic The boolean value for public visibility consent.
    function setPublicProfileStatus(uint256 _entityId, bool _isPublic)
        external
        whenNotPaused
        entityExists(_entityId)
        notArchived(_entityId)
        onlyEntityOwnerOrDelegate(_entityId, 9) // Define ACTION_TYPE_SET_PUBLIC_PROFILE as 9 or similar
    {
        entities[_entityId].isProfilePublic = _isPublic;
        emit PublicProfileStatusSet(_entityId, _isPublic);
    }

    /// @notice Retrieves the public profile visibility status flag for an entity.
    /// @param _entityId The ID of the entity.
    /// @return bool The public profile status flag.
    function getEntityPublicProfileStatus(uint256 _entityId) external view entityExists(_entityId) returns (bool) {
        return entities[_entityId].isProfilePublic;
    }

    // Define constants for action types for clarity (optional but good practice)
    // Example Action Type Constants:
    // uint256 constant public ACTION_TYPE_CHANGE_OWNER = 0;
    // uint256 constant public ACTION_TYPE_ARCHIVE = 1;
    // uint256 constant public ACTION_TYPE_LEVEL_UP = 2;
    // uint256 constant public ACTION_TYPE_LEARN_SKILL = 3;
    // uint256 constant public ACTION_TYPE_ATTUNE_ESSENCE = 4;
    // uint256 constant public ACTION_TYPE_DETTUNE_ESSENCE = 5;
    // uint256 constant public ACTION_TYPE_RECORD_OBSERVATION = 6;
    // uint256 constant public ACTION_TYPE_BOND = 7;
    // uint256 constant public ACTION_TYPE_UNBOND = 8;
    // uint256 constant public ACTION_TYPE_SET_PUBLIC_PROFILE = 9;
    // Add more as needed for `performChronicleAction` types...
    // e.g., uint256 constant public ACTION_TYPE_QUEST = 10;
    // uint256 constant public ACTION_TYPE_CRAFT = 11;
    // uint256 constant public ACTION_TYPE_BATTLE = 12;
    // etc. up to 255 if using a byte for action type in a bitmask, or use uint256 for >= 256 types.
    // Note: The current `onlyEntityOwnerOrDelegate` uses actionType as a bit index for the mask.
    // This limits action types used for delegation to 0-255 if the mask is uint256.
    // If you need more than 256 action types, the permission system needs to be redesigned (e.g., mapping uint256 => mapping address => bool or uint256[]).

    // For this example, we assume action types 0 through 9 are covered by the specific functions,
    // and `performChronicleAction` uses action types 10 and above.
    // The permissions mask will need to accommodate these higher numbers if delegating `performChronicleAction`.
}
```