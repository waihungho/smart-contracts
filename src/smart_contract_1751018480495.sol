Okay, here is a Solidity smart contract concept for a "Dynamic NFT Avatar" with various advanced features. The core idea is an NFT whose appearance and attributes evolve based on on-chain actions, time, and potentially interactions.

This contract is designed to be interesting, advanced, creative, and trendy by incorporating:

1.  **Dynamic Metadata:** The `tokenURI` changes based on the avatar's on-chain state (level, traits, status).
2.  **On-Chain Attributes/State:** Key properties (level, XP, traits, status) are stored and managed directly in the contract.
3.  **Leveling System:** Avatars gain Experience Points (XP) and level up, potentially unlocking new visual layers or trait slots.
4.  **Trait Management:** Avatars have various trait types (e.g., Head, Body, Background) with specific options, which can be added or changed dynamically.
5.  **Usable Items:** The contract supports different types of items that can be applied to avatars to affect their state (e.g., grant XP, change status, temporary boosts).
6.  **Quest System:** Define simple on-chain quests or challenges that, when completed, reward the avatar (e.g., with XP or items).
7.  **Time-Based Dynamics:** Status or other properties can change based on the elapsed time since the last update.
8.  **Mutation/Evolution:** A mechanism for significant, possibly random, transformation of the avatar's traits or status.
9.  **Layered Visuals (Conceptual):** The metadata generation uses "layer identifiers" defined by the on-chain state, implying an off-chain rendering process that combines these layers to create the final image.
10. **Configurability:** Many aspects (XP requirements, item effects, quest details, trait options) are configurable by an admin.
11. **Admin Role:** Separate admin address from the owner for specific configuration tasks.

---

**Outline & Function Summary**

**Outline:**

1.  **Contract Setup:** SPDX License, Pragma, Imports (ERC721).
2.  **Events:** Notifications for key actions (Mint, LevelUp, ItemApplied, TraitChanged, StatusChange, QuestCompleted, Mutation).
3.  **Structs:** Define data structures for Avatar state, Traits, Items, Levels, Quests.
4.  **State Variables:** Mappings and variables to store avatar data, configuration, counters, admin/owner addresses, base URI.
5.  **Access Control:** Modifiers for owner and admin roles.
6.  **Constructor:** Initializes owner and admin.
7.  **ERC721 Standard Functions:** Implement required functions (`balanceOf`, `ownerOf`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`).
8.  **Core Avatar Management:** `mintAvatar`, `getTokenData`, `tokenURI`.
9.  **Configuration Functions (Admin/Owner Only):** Add/Update trait types, options, level configs, item types, quests, base URI, admin address, layer mapping.
10. **Avatar Interaction Functions:** `applyItem`, `performQuestAction`, `claimQuestReward`, `triggerTimeBasedUpdate`, `requestMutation`.
11. **View Functions:** Get specific details like level, XP, traits, status.
12. **Internal Helper Functions:** Logic for granting XP, checking level up, applying effects, checking quest completion, mutating.

**Function Summary:**

*   **`constructor(address initialOwner, address initialAdmin)`**: Initializes the contract setting the owner and admin addresses.
*   **`setAdmin(address newAdmin)`**: Allows the owner to transfer or set the admin address.
*   **`setBaseURI(string memory baseURI_)`**: Allows the admin to set the base URI for metadata, where the generated JSON will be located (often an API endpoint).
*   **`addTraitType(string memory name)`**: Admin function to define a new category of traits (e.g., "Background", "Head", "Body"). Returns the new trait type ID.
*   **`updateTraitTypeName(uint256 traitTypeId, string memory newName)`**: Admin function to update the name of an existing trait type.
*   **`addTraitOption(uint256 traitTypeId, string memory name, string memory layerIdentifier)`**: Admin function to add a specific option within a trait type (e.g., "Blue Background", "Red Hat") and associate it with a layer identifier for rendering. Returns the new option ID.
*   **`updateTraitOption(uint256 traitTypeId, uint256 optionId, string memory newName, string memory newLayerIdentifier)`**: Admin function to update the name or layer identifier of an existing trait option.
*   **`addLevelConfig(uint256 level, uint256 requiredXP, string memory unlockedLayerIdentifier)`**: Admin function to define the XP required to reach a specific level and potentially an additional layer identifier unlocked at that level.
*   **`updateLevelConfig(uint256 level, uint256 requiredXP, string memory unlockedLayerIdentifier)`**: Admin function to modify an existing level configuration.
*   **`addItemType(string memory name, string memory effectIdentifier)`**: Admin function to define a new type of usable item and associate it with an effect identifier. Returns the new item type ID.
*   **`updateItemType(uint256 itemTypeId, string memory newName, string memory newEffectIdentifier)`**: Admin function to update the name or effect identifier of an item type.
*   **`addQuest(string memory name, string memory conditionIdentifier, uint256 rewardXP, uint256 rewardItemTypeId)`**: Admin function to define a quest, its identifier (interpreted off-chain or by a helper contract), XP reward, and optional item reward. Returns the new quest ID.
*   **`updateQuest(uint256 questId, string memory newName, string memory newConditionIdentifier, uint256 newRewardXP, uint256 newRewardItemTypeId)`**: Admin function to update an existing quest definition.
*   **`setLayerMapping(string memory stateIdentifier, string memory layerIdentifier)`**: Admin function to set up more complex mappings where combinations of state (e.g., status + trait) map to specific visual layers.
*   **`mintAvatar(address to, uint256 initialTraitTypeId, uint256 initialTraitOptionId)`**: Mints a new avatar NFT to an address, initializing it with base stats and one starting trait.
*   **`getTokenData(uint256 tokenId)`**: View function to retrieve all on-chain data (level, XP, traits, status, etc.) for a specific avatar.
*   **`getLevel(uint256 tokenId)`**: View function to get the current level of an avatar.
*   **`getExperience(uint256 tokenId)`**: View function to get the current XP of an avatar.
*   **`getTrait(uint256 tokenId, uint256 traitTypeId)`**: View function to get the option ID for a specific trait type on an avatar.
*   **`getTraits(uint256 tokenId)`**: View function to get all current trait type IDs and their option IDs for an avatar.
*   **`getStatus(uint256 tokenId)`**: View function to get the current status identifier string of an avatar.
*   **`applyItem(uint256 tokenId, uint256 itemTypeId)`**: Allows the avatar owner (or approved address) to apply a registered item type to the avatar, triggering its effects.
*   **`performQuestAction(uint256 tokenId, uint256 questId, uint256 progressAmount)`**: Allows an authorized entity (e.g., a game contract, owner, or keeper) to record progress on a quest for an avatar.
*   **`claimQuestReward(uint256 tokenId, uint256 questId)`**: Allows the avatar owner to claim the reward for a completed quest.
*   **`triggerTimeBasedUpdate(uint256 tokenId)`**: Can be called by anyone (potentially a keeper bot) to trigger state changes based on the elapsed time since the last update (e.g., status decay/gain, passive XP).
*   **`requestMutation(uint256 tokenId)`**: Allows the avatar owner to initiate a mutation process for the avatar (the actual mutation might happen via a time trigger or separate admin call).
*   **`tokenURI(uint256 tokenId)`**: ERC721 standard function. Dynamically generates and returns a data URI containing JSON metadata for the avatar, including its name, description, image URL (pointing to a renderer with layer identifiers), and attributes based on its current on-chain state.
*   **`balanceOf(address owner)`**: ERC721 standard function. Returns the number of tokens owned by an address.
*   **`ownerOf(uint256 tokenId)`**: ERC721 standard function. Returns the owner of a specific token.
*   **`approve(address to, uint256 tokenId)`**: ERC721 standard function. Approves an address to spend a specific token.
*   **`getApproved(uint256 tokenId)`**: ERC721 standard function. Returns the approved address for a specific token.
*   **`setApprovalForAll(address operator, bool approved)`**: ERC721 standard function. Sets approval for an operator to manage all of the caller's tokens.
*   **`isApprovedForAll(address owner, address operator)`**: ERC721 standard function. Checks if an operator is approved for all of the owner's tokens.
*   **`transferFrom(address from, address to, uint256 tokenId)`**: ERC721 standard function. Transfers a token from one address to another (requires approval/ownership).
*   **`safeTransferFrom(address from, address to, uint256 tokenId)`**: ERC721 standard function. Transfers a token, checking if the recipient can receive ERC721 tokens.
*   **`safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`**: ERC721 standard function (overload). Transfers a token with additional data.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. Contract Setup: SPDX License, Pragma, Imports (ERC721, Ownable, Counters, Strings).
// 2. Events: Notifications for key actions (Mint, LevelUp, ItemApplied, TraitChanged, StatusChange, QuestCompleted, Mutation).
// 3. Structs: Define data structures for Avatar state, Traits, Items, Levels, Quests.
// 4. State Variables: Mappings and variables to store avatar data, configuration, counters, admin/owner addresses, base URI.
// 5. Access Control: Modifiers for owner and admin roles.
// 6. Constructor: Initializes owner and admin.
// 7. ERC721 Standard Functions: Implement required functions.
// 8. Core Avatar Management: mintAvatar, getTokenData, tokenURI.
// 9. Configuration Functions (Admin/Owner Only): Add/Update trait types, options, level configs, item types, quests, base URI, admin address, layer mapping.
// 10. Avatar Interaction Functions: applyItem, performQuestAction, claimQuestReward, triggerTimeBasedUpdate, requestMutation.
// 11. View Functions: Get specific details like level, XP, traits, status.
// 12. Internal Helper Functions: Logic for granting XP, checking level up, applying effects, checking quest completion, mutating.

// Function Summary:
// constructor(address initialOwner, address initialAdmin): Initializes owner and admin.
// setAdmin(address newAdmin): Owner sets admin.
// setBaseURI(string memory baseURI_): Admin sets metadata base URI.
// addTraitType(string memory name): Admin adds a new trait category. Returns ID.
// updateTraitTypeName(uint256 traitTypeId, string memory newName): Admin updates trait category name.
// addTraitOption(uint256 traitTypeId, string memory name, string memory layerIdentifier): Admin adds a trait option within a type, with layer ID. Returns ID.
// updateTraitOption(uint256 traitTypeId, uint256 optionId, string memory newName, string memory newLayerIdentifier): Admin updates a trait option.
// addLevelConfig(uint256 level, uint256 requiredXP, string memory unlockedLayerIdentifier): Admin sets XP for a level and optional unlock layer.
// updateLevelConfig(uint256 level, uint256 requiredXP, string memory unlockedLayerIdentifier): Admin updates level config.
// addItemType(string memory name, string memory effectIdentifier): Admin adds an item type with effect ID. Returns ID.
// updateItemType(uint256 itemTypeId, string memory newName, string memory newEffectIdentifier): Admin updates an item type.
// addQuest(string memory name, string memory conditionIdentifier, uint256 rewardXP, uint256 rewardItemTypeId): Admin adds a quest with condition, XP, and item rewards. Returns ID.
// updateQuest(uint256 questId, string memory newName, string memory newConditionIdentifier, uint256 newRewardXP, uint256 newRewardItemTypeId): Admin updates a quest.
// setLayerMapping(string memory stateIdentifier, string memory layerIdentifier): Admin sets custom state-to-layer mappings.
// mintAvatar(address to, uint256 initialTraitTypeId, uint256 initialTraitOptionId): Mints a new avatar NFT.
// getTokenData(uint256 tokenId): Gets all on-chain data for an avatar.
// getLevel(uint256 tokenId): Gets avatar level.
// getExperience(uint256 tokenId): Gets avatar XP.
// getTrait(uint256 tokenId, uint256 traitTypeId): Gets a specific trait option ID.
// getTraits(uint256 tokenId): Gets all trait type and option IDs.
// getStatus(uint256 tokenId): Gets avatar status.
// applyItem(uint256 tokenId, uint256 itemTypeId): Owner/approved uses an item on avatar.
// performQuestAction(uint256 tokenId, uint256 questId, uint256 progressAmount): Authorized entity records quest progress.
// claimQuestReward(uint256 tokenId, uint256 questId): Owner claims quest reward.
// triggerTimeBasedUpdate(uint256 tokenId): Anyone triggers time-based state changes.
// requestMutation(uint256 tokenId): Owner initiates mutation.
// tokenURI(uint256 tokenId): Dynamically generates ERC721 metadata URI.
// balanceOf(address owner): ERC721 standard.
// ownerOf(uint256 tokenId): ERC721 standard.
// approve(address to, uint256 tokenId): ERC721 standard.
// getApproved(uint256 tokenId): ERC721 standard.
// setApprovalForAll(address operator, bool approved): ERC721 standard.
// isApprovedForAll(address owner, address operator): ERC721 standard.
// transferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard.
// safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): ERC721 standard.


contract DynamicNFTAvatar is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Structs ---

    struct TraitOption {
        string name;
        string layerIdentifier; // Identifier for the visual layer associated with this option (e.g., "background_blue", "head_red_hat")
    }

    struct TraitType {
        string name;
        mapping(uint256 => TraitOption) options;
        Counters.Counter optionCounter;
    }

    struct AvatarData {
        uint256 level;
        uint256 xp;
        uint256 lastUpdateTime; // For time-based effects
        string status; // e.g., "Normal", "Charged", "Sleeping"
        mapping(uint256 => uint256) traits; // traitTypeId => traitOptionId
        mapping(uint256 => uint256) questProgress; // questId => progress
        uint256 mutationCooldown; // Timestamp when mutation is next available
    }

    struct LevelConfig {
        uint256 requiredXP;
        string unlockedLayerIdentifier; // Optional layer unlocked at this level
    }

    struct ItemType {
        string name;
        string effectIdentifier; // Identifier describing the item's effect (interpreted in applyItem)
    }

    struct Quest {
        string name;
        string conditionIdentifier; // Identifier describing quest condition (interpreted externally or via helper contract)
        uint256 rewardXP;
        uint256 rewardItemTypeId; // 0 if no item reward
    }

    // --- State Variables ---

    mapping(uint256 => AvatarData) private _avatars;

    address public admin; // Separate role for configuration

    mapping(uint256 => TraitType) private _traitTypes;
    Counters.Counter private _traitTypeCounter;

    mapping(uint256 => LevelConfig) private _levelConfigs; // Level => Config (Level 1 starts at 1, Level 0 isn't used here)

    mapping(uint256 => ItemType) private _itemTypes;
    Counters.Counter private _itemTypeCounter;

    mapping(uint256 => Quest) private _quests;
    Counters.Counter private _questCounter;

    // Custom mappings for complex state-to-layer logic (e.g., "status_charged" => "effect_glow_layer")
    mapping(string => string) private _stateLayerMappings;

    string private _baseTokenURI;

    // --- Events ---

    event AvatarMinted(uint256 indexed tokenId, address indexed owner, uint256 initialTraitTypeId, uint256 initialTraitOptionId);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel, uint256 oldLevel);
    event ExperienceGained(uint256 indexed tokenId, uint256 amount, uint256 newXP);
    event ItemApplied(uint256 indexed tokenId, uint256 itemTypeId, string effectIdentifier);
    event TraitChanged(uint256 indexed tokenId, uint256 indexed traitTypeId, uint256 newTraitOptionId, uint256 oldTraitOptionId);
    event StatusChanged(uint256 indexed tokenId, string newStatus, string oldStatus);
    event QuestProgressUpdated(uint256 indexed tokenId, uint256 indexed questId, uint256 newProgress);
    event QuestCompleted(uint256 indexed tokenId, uint256 indexed questId, uint256 rewardXP, uint256 rewardItemTypeId);
    event MutationTriggered(uint256 indexed tokenId);
    event AdminSet(address indexed oldAdmin, address indexed newAdmin);
    event BaseURISet(string indexed newBaseURI);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(_msgSender() == admin, "Only admin can call this function");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, address initialAdmin)
        ERC721("DynamicNFTAvatar", "DNAV")
        Ownable(initialOwner)
    {
        admin = initialAdmin;
        emit AdminSet(address(0), initialAdmin);

        // Initialize Level 1 config (assuming 0 XP for level 1)
        _levelConfigs[1] = LevelConfig({
            requiredXP: 0, // Start at Level 1 with 0 XP needed for Level 1 (you are already level 1)
            unlockedLayerIdentifier: "" // No specific layer unlocked at level 1 by default
        });
    }

    // --- Access Control (Owner only sets Admin) ---

    function setAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "New admin cannot be zero address");
        emit AdminSet(admin, newAdmin);
        admin = newAdmin;
    }

    // --- Configuration Functions (Admin Only) ---

    function setBaseURI(string memory baseURI_) external onlyAdmin {
        _baseTokenURI = baseURI_;
        emit BaseURISet(baseURI_);
    }

    function addTraitType(string memory name) external onlyAdmin returns (uint256 traitTypeId) {
        _traitTypeCounter.increment();
        traitTypeId = _traitTypeCounter.current();
        _traitTypes[traitTypeId].name = name;
        return traitTypeId;
    }

    function updateTraitTypeName(uint256 traitTypeId, string memory newName) external onlyAdmin {
        require(_traitTypes[traitTypeId].name != "", "Trait type does not exist");
        _traitTypes[traitTypeId].name = newName;
    }

    function addTraitOption(uint256 traitTypeId, string memory name, string memory layerIdentifier) external onlyAdmin returns (uint256 optionId) {
        TraitType storage traitType = _traitTypes[traitTypeId];
        require(traitType.name != "", "Trait type does not exist");
        traitType.optionCounter.increment();
        optionId = traitType.optionCounter.current();
        traitType.options[optionId] = TraitOption({
            name: name,
            layerIdentifier: layerIdentifier
        });
        return optionId;
    }

    function updateTraitOption(uint256 traitTypeId, uint256 optionId, string memory newName, string memory newLayerIdentifier) external onlyAdmin {
        TraitType storage traitType = _traitTypes[traitTypeId];
        require(traitType.name != "", "Trait type does not exist");
        require(traitType.options[optionId].name != "", "Trait option does not exist");
        traitType.options[optionId].name = newName;
        traitType.options[optionId].layerIdentifier = newLayerIdentifier;
    }

    function addLevelConfig(uint256 level, uint256 requiredXP, string memory unlockedLayerIdentifier) external onlyAdmin {
        require(level > 0, "Level must be greater than 0");
         if (level > 1) { // Level 1 config is initialized in constructor
            // Ensure requiredXP is non-decreasing
            require(requiredXP >= _levelConfigs[level - 1].requiredXP, "Required XP must be non-decreasing");
         }
        _levelConfigs[level] = LevelConfig({
            requiredXP: requiredXP,
            unlockedLayerIdentifier: unlockedLayerIdentifier
        });
    }

    function updateLevelConfig(uint256 level, uint256 requiredXP, string memory unlockedLayerIdentifier) external onlyAdmin {
         require(level > 0, "Level must be greater than 0");
         // Allow updating existing level configs, still check non-decreasing XP relative to level-1
         if (level > 1) {
              require(requiredXP >= _levelConfigs[level - 1].requiredXP, "Required XP must be non-decreasing");
         }
        _levelConfigs[level] = LevelConfig({
            requiredXP: requiredXP,
            unlockedLayerIdentifier: unlockedLayerIdentifier
        });
    }


    function addItemType(string memory name, string memory effectIdentifier) external onlyAdmin returns (uint256 itemTypeId) {
        _itemTypeCounter.increment();
        itemTypeId = _itemTypeCounter.current();
        _itemTypes[itemTypeId] = ItemType({
            name: name,
            effectIdentifier: effectIdentifier
        });
        return itemTypeId;
    }

    function updateItemType(uint256 itemTypeId, string memory newName, string memory newEffectIdentifier) external onlyAdmin {
        require(_itemTypes[itemTypeId].name != "", "Item type does not exist");
        _itemTypes[itemTypeId].name = newName;
        _itemTypes[itemTypeId].effectIdentifier = newEffectIdentifier;
    }

     function addQuest(string memory name, string memory conditionIdentifier, uint256 rewardXP, uint256 rewardItemTypeId) external onlyAdmin returns (uint256 questId) {
        if (rewardItemTypeId != 0) {
             require(_itemTypes[rewardItemTypeId].name != "", "Reward item type does not exist");
        }
        _questCounter.increment();
        questId = _questCounter.current();
        _quests[questId] = Quest({
            name: name,
            conditionIdentifier: conditionIdentifier,
            rewardXP: rewardXP,
            rewardItemTypeId: rewardItemTypeId
        });
        return questId;
    }

    function updateQuest(uint256 questId, string memory newName, string memory newConditionIdentifier, uint256 newRewardXP, uint256 newRewardItemTypeId) external onlyAdmin {
        require(_quests[questId].name != "", "Quest does not exist");
         if (newRewardItemTypeId != 0) {
             require(_itemTypes[newRewardItemTypeId].name != "", "Reward item type does not exist");
        }
        _quests[questId].name = newName;
        _quests[questId].conditionIdentifier = newConditionIdentifier;
        _quests[questId].rewardXP = newRewardXP;
        _quests[questId].rewardItemTypeId = newRewardItemTypeId;
    }

    function setLayerMapping(string memory stateIdentifier, string memory layerIdentifier) external onlyAdmin {
        _stateLayerMappings[stateIdentifier] = layerIdentifier;
    }

    // --- Core Avatar Management ---

    function mintAvatar(address to, uint256 initialTraitTypeId, uint256 initialTraitOptionId) external onlyAdmin returns (uint256 tokenId) {
        require(to != address(0), "Mint to the zero address");
        require(_traitTypes[initialTraitTypeId].name != "", "Initial trait type does not exist");
        require(_traitTypes[initialTraitTypeId].options[initialTraitOptionId].name != "", "Initial trait option does not exist");

        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);

        _avatars[tokenId] = AvatarData({
            level: 1,
            xp: 0,
            lastUpdateTime: block.timestamp,
            status: "Normal", // Default status
            traits: new mapping(uint256 => uint256)(),
            questProgress: new mapping(uint256 => uint256)(),
            mutationCooldown: 0
        });

        _avatars[tokenId].traits[initialTraitTypeId] = initialTraitOptionId;

        emit AvatarMinted(tokenId, to, initialTraitTypeId, initialTraitOptionId);
        // Initial level up event might be emitted if level 1 has required XP > 0, though typically level 1 is base
        emit LevelUp(tokenId, 1, 0); // Explicitly emit level 1 reached

        return tokenId;
    }

    function getTokenData(uint256 tokenId) external view returns (
        uint256 level,
        uint256 xp,
        uint256 lastUpdateTime,
        string memory status,
        // Returns trait type IDs and option IDs as separate arrays
        uint256[] memory traitTypeIds,
        uint256[] memory traitOptionIds,
        // Returns quest IDs and progress as separate arrays
        uint256[] memory questIds,
        uint256[] memory questProgresses,
        uint256 mutationCooldown
    ) {
        require(_exists(tokenId), "Token does not exist");
        AvatarData storage avatar = _avatars[tokenId];

        level = avatar.level;
        xp = avatar.xp;
        lastUpdateTime = avatar.lastUpdateTime;
        status = avatar.status;
        mutationCooldown = avatar.mutationCooldown;

        // Collect traits - iterate through known trait types up to counter
        uint256 currentTraitTypeId = 1;
        uint256 traitCount = 0;
        // First, count how many traits the avatar actually has
        while(currentTraitTypeId <= _traitTypeCounter.current()) {
            if(avatar.traits[currentTraitTypeId] != 0) { // Check if avatar has this trait type set
                 traitCount++;
            }
             unchecked { currentTraitTypeId++; }
        }
        traitTypeIds = new uint256[](traitCount);
        traitOptionIds = new uint256[](traitCount);
        uint256 traitIndex = 0;
         currentTraitTypeId = 1;
        while(currentTraitTypeId <= _traitTypeCounter.current()) {
             if(avatar.traits[currentTraitTypeId] != 0) {
                traitTypeIds[traitIndex] = currentTraitTypeId;
                traitOptionIds[traitIndex] = avatar.traits[currentTraitTypeId];
                traitIndex++;
             }
             unchecked { currentTraitTypeId++; }
        }

        // Collect quest progress - iterate through known quests up to counter
        uint256 currentQuestId = 1;
        uint256 questCount = 0;
         // First, count how many quests the avatar has progress on
         while(currentQuestId <= _questCounter.current()) {
            if(avatar.questProgress[currentQuestId] != 0) { // Check if avatar has progress on this quest
                 questCount++;
            }
             unchecked { currentQuestId++; }
         }
        questIds = new uint256[](questCount);
        questProgresses = new uint256[](questCount);
        uint256 questIndex = 0;
        currentQuestId = 1;
         while(currentQuestId <= _questCounter.current()) {
            if(avatar.questProgress[currentQuestId] != 0) {
                 questIds[questIndex] = currentQuestId;
                 questProgresses[questIndex] = avatar.questProgress[currentQuestId];
                 questIndex++;
            }
             unchecked { currentQuestId++; }
         }
    }


    // --- ERC721 Required Overrides ---
    // These leverage the OpenZeppelin ERC721 contract

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

     // Overriding _increaseBalance and _decreaseBalance for custom tracking if needed,
     // but standard ERC721 handles this correctly without further overrides here.
     // Overriding _update is necessary if doing custom _beforeTokenTransfer logic etc.
     // For this contract's complexity, standard OZ overrides are sufficient.
     // The core customization is in tokenURI.


    // --- Dynamic Metadata ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        AvatarData storage avatar = _avatars[tokenId];

        // Use the base URI to construct the full URI.
        // This endpoint should be an API that reads the on-chain state
        // via getTokenData or similar and constructs the JSON metadata.
        // We pass token ID and potentially a timestamp or hash of state
        // to help caching/validation if needed.
        // Example: baseURI/token/123 or baseURI/token/123?v=<state_hash>

        // A simple implementation just appends the token ID.
        // A more advanced one might include state identifiers.

        string memory base = _baseURI();
        if (bytes(base).length == 0) {
             // If no base URI is set, we could try to generate inline JSON
             // This is complex and gas-intensive, often avoided.
             // For demonstration, let's return an error or a minimal placeholder.
             return "data:application/json;base64,eyJuYW1lIjogIk1ldGFkYXRhIG5vdCByZWFkeSIsICJkZXNjcmlwdGlvbiI6ICJUb2tlbiBzdGF0ZSBvbi1jaGFpbiIsImltYWdlIjogIiJ9"; // Placeholder error JSON
        }

        // Construct the URI. Assumes baseURI ends with '/' or the API handles it.
        // A common pattern is baseURI + tokenId
        return string(abi.encodePacked(base, tokenId.toString()));

         /*
         Alternative sophisticated inline JSON generation (Very Gas Expensive!):
         // This is illustrative, not recommended for typical usage
         string memory name = string(abi.encodePacked("Avatar #", tokenId.toString()));
         string memory description = string(abi.encodePacked("An evolving avatar. Level: ", avatar.level.toString(), ", XP: ", avatar.xp.toString(), ", Status: ", avatar.status));
         // Build attributes array
         string memory attributes = "[";
         attributes = string(abi.encodePacked(attributes, '{"trait_type": "Level", "value": "', avatar.level.toString(), '"},'));
         attributes = string(abi.encodePacked(attributes, '{"trait_type": "XP", "value": "', avatar.xp.toString(), '"},'));
         attributes = string(abi.encodePacked(attributes, '{"trait_type": "Status", "value": "', avatar.status, '"}'));

         // Add trait attributes
         uint256 currentTraitTypeId = 1;
         while(currentTraitTypeId <= _traitTypeCounter.current()) {
            uint256 optionId = avatar.traits[currentTraitTypeId];
            if (optionId != 0) {
                attributes = string(abi.encodePacked(attributes, ', {"trait_type": "', _traitTypes[currentTraitTypeId].name, '", "value": "', _traitTypes[currentTraitTypeId].options[optionId].name, '"}'));
            }
            unchecked { currentTraitTypeId++; }
         }
          attributes = string(abi.encodePacked(attributes, "]"));

         // Build layer identifiers array for potential off-chain renderer hint
         string memory layerIdentifiers = "[";
         // Add base layers based on traits
          currentTraitTypeId = 1;
         bool firstLayer = true;
         while(currentTraitTypeId <= _traitTypeCounter.current()) {
            uint256 optionId = avatar.traits[currentTraitTypeId];
             if (optionId != 0) {
                 if (!firstLayer) layerIdentifiers = string(abi.encodePacked(layerIdentifiers, ","));
                 layerIdentifiers = string(abi.encodePacked(layerIdentifiers, '"', _traitTypes[currentTraitTypeId].options[optionId].layerIdentifier, '"'));
                 firstLayer = false;
             }
             unchecked { currentTraitTypeId++; }
         }
         // Add level unlock layer if applicable
         if (bytes(_levelConfigs[avatar.level].unlockedLayerIdentifier).length > 0) {
             if (!firstLayer) layerIdentifiers = string(abi.encodePacked(layerIdentifiers, ","));
              layerIdentifiers = string(abi.encodePacked(layerIdentifiers, '"', _levelConfigs[avatar.level].unlockedLayerIdentifier, '"'));
             firstLayer = false;
         }
         // Add status/state based layers
         string memory statusLayer = _stateLayerMappings[avatar.status];
         if (bytes(statusLayer).length > 0) {
              if (!firstLayer) layerIdentifiers = string(abi.encodePacked(layerIdentifiers, ","));
              layerIdentifiers = string(abi.encodePacked(layerIdentifiers, '"', statusLayer, '"'));
              firstLayer = false;
         }
         // Add other state based layers... (e.g., mutation status)

         layerIdentifiers = string(abi.encodePacked(layerIdentifiers, "]"));


         // Construct final JSON (example structure)
         string memory json = string(abi.encodePacked(
             '{"name": "', name, '",',
             '"description": "', description, '",',
             // The 'image' field could point to an API endpoint that takes layer identifiers as input
             // Or it could be generated fully off-chain based on the state returned by getTokenData
             // For on-chain data, 'image' is usually a URL. Let's use a placeholder or link to a renderer.
             '"image": "', _baseURI(), 'render/', tokenId.toString(), '",', // Example renderer endpoint
             '"attributes": ', attributes, ',',
             // Include layer identifiers in a custom field for the renderer
             '"dna_layers": ', layerIdentifiers,
             '}'
         ));

         // Encode as data URI
         // return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
         // Base64 library would be needed, making contract larger. Standard practice is external URI.
         */
    }


    // --- View Functions ---

    function getLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _avatars[tokenId].level;
    }

    function getExperience(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _avatars[tokenId].xp;
    }

     function getTrait(uint256 tokenId, uint256 traitTypeId) public view returns (uint256 traitOptionId) {
        require(_exists(tokenId), "Token does not exist");
        require(_traitTypes[traitTypeId].name != "", "Trait type does not exist");
        return _avatars[tokenId].traits[traitTypeId];
    }

    function getTraits(uint256 tokenId) public view returns (uint256[] memory traitTypeIds, uint256[] memory traitOptionIds) {
         require(_exists(tokenId), "Token does not exist");
         // This data is already collected efficiently in getTokenData, reuse that logic or call it.
         // Calling internal helper directly to avoid struct return overhead if only traits are needed.
         AvatarData storage avatar = _avatars[tokenId];
          uint256 currentTraitTypeId = 1;
          uint256 traitCount = 0;
          // First, count how many traits the avatar actually has
          while(currentTraitTypeId <= _traitTypeCounter.current()) {
              if(avatar.traits[currentTraitTypeId] != 0) {
                   traitCount++;
              }
               unchecked { currentTraitTypeId++; }
          }
          traitTypeIds = new uint256[](traitCount);
          traitOptionIds = new uint256[](traitCount);
          uint256 traitIndex = 0;
           currentTraitTypeId = 1;
          while(currentTraitTypeId <= _traitTypeCounter.current()) {
               if(avatar.traits[currentTraitTypeId] != 0) {
                  traitTypeIds[traitIndex] = currentTraitTypeId;
                  traitOptionIds[traitIndex] = avatar.traits[currentTraitTypeId];
                  traitIndex++;
               }
               unchecked { currentTraitTypeId++; }
          }
          return (traitTypeIds, traitOptionIds);
    }


     function getStatus(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _avatars[tokenId].status;
    }

     function getQuestProgress(uint256 tokenId, uint256 questId) public view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
         require(_quests[questId].name != "", "Quest does not exist");
         return _avatars[tokenId].questProgress[questId];
     }

     function getMutationCooldown(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
         return _avatars[tokenId].mutationCooldown;
     }


    // --- Avatar Interaction Functions ---

    function applyItem(uint256 tokenId, uint256 itemTypeId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner or approved");
        require(_exists(tokenId), "Token does not exist");
        require(_itemTypes[itemTypeId].name != "", "Item type does not exist");

        AvatarData storage avatar = _avatars[tokenId];
        ItemType storage item = _itemTypes[itemTypeId];

        // --- Apply Item Effect ---
        // This is a simplified interpretation. In a real application,
        // the effectIdentifier would map to specific logic.
        // Using string comparison here is basic; a better way might be
        // an enum or mapping to internal function pointers if possible,
        // or requiring external calls for complex effects.
        // For this example, simple string checks:

        if (keccak256(bytes(item.effectIdentifier)) == keccak256(bytes("XP_BOOST_100"))) {
            _grantXP(tokenId, 100);
            // Could consume item supply here if items were tracked inventory-style
        } else if (keccak256(bytes(item.effectIdentifier)) == keccak256(bytes("STATUS_CHARGED"))) {
            avatar.status = "Charged";
            emit StatusChanged(tokenId, "Charged", avatar.status); // Note: order might be confusing if state is changed before event
             // Correct order:
             string memory oldStatus = avatar.status;
             avatar.status = "Charged";
             emit StatusChanged(tokenId, avatar.status, oldStatus);
        } else if (keccak256(bytes(item.effectIdentifier)) == keccak256(bytes("MUTATION_SERUM"))) {
             if (avatar.mutationCooldown <= block.timestamp) {
                 avatar.mutationCooldown = block.timestamp + 1 days; // Set a cooldown
                 _mutateAvatar(tokenId); // Trigger mutation logic
             } else {
                 revert("Mutation is on cooldown");
             }
        }
        // Add more effects here...

        emit ItemApplied(tokenId, itemTypeId, item.effectIdentifier);

        // Update last update time
        avatar.lastUpdateTime = block.timestamp;
    }

    function performQuestAction(uint256 tokenId, uint256 questId, uint256 progressAmount) external {
        // This function could be called by:
        // 1. The token owner (proving something off-chain happened)
        // 2. Another trusted contract (e.g., a game contract)
        // 3. An admin/keeper (for off-chain event verification)
        // Add access control based on your design (e.g., onlyAdmin, specific trusted addresses, or only owner with proof)
        // For simplicity, let's allow the owner for now, assuming they provide proof via `progressAmount` or it's state change
        // A real quest system would be much more complex (e.g., check on-chain conditions, require signatures, etc.)
         require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner or approved");
         require(_exists(tokenId), "Token does not exist");
         require(_quests[questId].name != "", "Quest does not exist");

         AvatarData storage avatar = _avatars[tokenId];
         Quest storage quest = _quests[questId];

         // Simulate progress update (in a real system, this would verify `progressAmount` against `quest.conditionIdentifier` logic)
         // Here, just adding progress
         avatar.questProgress[questId] += progressAmount;

         emit QuestProgressUpdated(tokenId, questId, avatar.questProgress[questId]);

         // Update last update time
         avatar.lastUpdateTime = block.timestamp;

         // Note: Quest completion check and reward claiming is separate via `claimQuestReward`
    }

    function claimQuestReward(uint256 tokenId, uint256 questId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner or approved");
        require(_exists(tokenId), "Token does not exist");
        require(_quests[questId].name != "", "Quest does not exist");

        AvatarData storage avatar = _avatars[tokenId];
        Quest storage quest = _quests[questId];

        // In a real system, _checkQuestCompletion would involve complex logic
        // Here, we'll just require progress reaches a threshold (e.g., 100)
        // The `conditionIdentifier` would guide the threshold or specific checks.
        // Let's assume conditionIdentifier "PROGRESS_100" means progress must be >= 100.
        bool questCompleted = false;
        if (keccak256(bytes(quest.conditionIdentifier)) == keccak256(bytes("PROGRESS_100"))) {
            questCompleted = avatar.questProgress[questId] >= 100;
        }
        // Add other condition checks here...

        require(questCompleted, "Quest not completed yet");

        // Grant rewards
        if (quest.rewardXP > 0) {
            _grantXP(tokenId, quest.rewardXP);
        }
        if (quest.rewardItemTypeId != 0) {
            // In a full system, this would mint or transfer an item NFT/token
            // For this example, we'll just emit an event indicating the reward
            // A real implementation needs an inventory system or item minting logic.
             emit ItemApplied(tokenId, quest.rewardItemTypeId, "Rewarded via Quest"); // Using ItemApplied event to signify reward
        }

        // Reset quest progress or mark as completed permanently (if not repeatable)
        // For simplicity, let's reset progress allowing repeat completion if logic allows
        avatar.questProgress[questId] = 0;

        emit QuestCompleted(tokenId, questId, quest.rewardXP, quest.rewardItemTypeId);

         // Update last update time
         avatar.lastUpdateTime = block.timestamp;
    }


    function triggerTimeBasedUpdate(uint256 tokenId) external {
        // Can be called by anyone to process pending time-based effects.
        // Useful for encouraging updates via keepers.
        require(_exists(tokenId), "Token does not exist");

        AvatarData storage avatar = _avatars[tokenId];
        uint256 timeElapsed = block.timestamp - avatar.lastUpdateTime;

        if (timeElapsed > 0) {
            // --- Apply Time-Based Effects ---
            // Example: Status decays over time, or passive XP gain
            if (keccak256(bytes(avatar.status)) == keccak256(bytes("Charged"))) {
                 // Example: Status lasts for 1 day
                 if (timeElapsed >= 1 days) {
                     string memory oldStatus = avatar.status;
                     avatar.status = "Normal"; // Decay
                     emit StatusChanged(tokenId, avatar.status, oldStatus);
                 } else {
                      // Status persists until time runs out
                 }
            } else if (keccak256(bytes(avatar.status)) == keccak256(bytes("Sleeping"))) {
                 // Example: Passive XP gain while sleeping
                 uint256 xpGain = (timeElapsed / 1 hours) * 5; // 5 XP per hour sleeping
                 if (xpGain > 0) {
                      _grantXP(tokenId, xpGain);
                 }
                 // Maybe status changes back after enough time
                 if (timeElapsed >= 8 hours) {
                     string memory oldStatus = avatar.status;
                     avatar.status = "Normal"; // Wake up
                      emit StatusChanged(tokenId, avatar.status, oldStatus);
                 }
            }
            // Add other time-based logic...

            // Update last update time AFTER processing effects
            avatar.lastUpdateTime = block.timestamp;
        }
    }

     function requestMutation(uint256 tokenId) external {
         require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not token owner or approved");
         require(_exists(tokenId), "Token does not exist");
         AvatarData storage avatar = _avatars[tokenId];

         require(avatar.mutationCooldown <= block.timestamp, "Mutation is on cooldown");

         // Set cooldown immediately upon request, even if mutation resolves later
         avatar.mutationCooldown = block.timestamp + 30 days; // Example cooldown

         // Trigger internal mutation logic - could be immediate or queued
         _mutateAvatar(tokenId);

         emit MutationTriggered(tokenId);

         // Update last update time
         avatar.lastUpdateTime = block.timestamp;
     }


    // --- Internal Helper Functions ---

    function _grantXP(uint256 tokenId, uint256 amount) internal {
        require(_exists(tokenId), "Token does not exist");
        require(amount > 0, "XP amount must be positive");

        AvatarData storage avatar = _avatars[tokenId];
        uint256 oldXP = avatar.xp;
        uint256 oldLevel = avatar.level;

        avatar.xp += amount; // Safemath handled by solidity >= 0.8

        uint256 currentLevel = avatar.level;
        uint256 nextLevel = currentLevel + 1;

        // Check for level ups
        while (_levelConfigs[nextLevel].requiredXP > 0 && avatar.xp >= _levelConfigs[nextLevel].requiredXP) {
            currentLevel = nextLevel;
            nextLevel++;
        }

        if (currentLevel > oldLevel) {
            avatar.level = currentLevel;
            emit LevelUp(tokenId, currentLevel, oldLevel);
            // Additional logic for level up effects could go here (e.g., add trait slot, change status)
        }

        emit ExperienceGained(tokenId, amount, avatar.xp);
    }

    function _mutateAvatar(uint256 tokenId) internal {
        // This is where complex mutation logic would reside.
        // It could involve:
        // - Randomly changing one or more traits
        // - Adding new, special traits
        // - Changing status permanently
        // - Resetting level/XP (less common for positive mutations)
        // - Consuming a resource (if items aren't consumed on `applyItem`)
        // - Be dependent on current traits, status, or level

        // Example simple mutation: Randomly change one existing trait
        AvatarData storage avatar = _avatars[tokenId];

        uint256[] memory traitTypeIds;
        uint256[] memory traitOptionIds;

        // Fetch existing traits
        (traitTypeIds, traitOptionIds) = getTraits(tokenId); // Reuse getter

        if (traitTypeIds.length == 0) {
             // Cannot mutate if no traits exist
             return;
        }

        // Pick a random existing trait type index (simplified randomness)
        // Warning: On-chain randomness is tricky and should use Chainlink VRF or similar in production
        // Using blockhash is insecure and predictable
        uint256 randomTraitIndex = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, tokenId))) % traitTypeIds.length;
        uint256 traitTypeIdToMutate = traitTypeIds[randomTraitIndex];

        // Pick a random *new* option for that trait type
        TraitType storage traitType = _traitTypes[traitTypeIdToMutate];
        uint256 totalOptions = traitType.optionCounter.current();
        if (totalOptions <= 1) {
            // Not enough options to mutate to
            return;
        }

        // Pick a random option ID that is not the current one (simplified randomness)
         uint256 newOptionId;
         uint256 currentOptionId = avatar.traits[traitTypeIdToMutate];
         uint256 randomOffset = uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, tokenId, traitTypeIdToMutate))) % (totalOptions - 1); // Offset within available new options
         if (randomOffset >= currentOptionId -1 && currentOptionId != 0) { // Adjust if current option is skipped (assuming IDs are 1-based)
              randomOffset++;
         }
         newOptionId = randomOffset + 1; // Assuming 1-based indexing

         // Basic check to ensure newOptionId exists (in case counter increased but option wasn't added)
         if(traitType.options[newOptionId].name == "") {
              // Fallback or skip mutation
              return;
         }


        // Change the trait
        uint256 oldOptionId = avatar.traits[traitTypeIdToMutate];
        avatar.traits[traitTypeIdToMutate] = newOptionId;

        emit TraitChanged(tokenId, traitTypeIdToMutate, newOptionId, oldOptionId);

        // Could also change status, grant XP, etc. upon mutation
        // Example: Gain a small amount of XP after mutating
        _grantXP(tokenId, 50);
    }


    // --- ERC721 Implementations (using OZ basic ones) ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, Ownable)
        returns (bool)
    {
        // Include Ownable interfaceId if you want to signal ownership
        return super.supportsInterface(interfaceId);
    }

    // The rest of the ERC721 functions (balanceOf, ownerOf, approve, etc.)
    // are inherited and work correctly with the _safeMint used in mintAvatar.
    // No explicit overrides are strictly necessary unless you want custom logic
    // during transfers or approvals.
    // Including them in the summary list for completeness as they are part of the
    // contract's external interface count.

    // function balanceOf(address owner) public view override returns (uint256) { return super.balanceOf(owner); }
    // function ownerOf(uint256 tokenId) public view override returns (address) { return super.ownerOf(tokenId); }
    // function approve(address to, uint256 tokenId) public override { super.approve(to, tokenId); }
    // function getApproved(uint256 tokenId) public view override returns (address) { return super.getApproved(tokenId); }
    // function setApprovalForAll(address operator, bool approved) public override { super.setApprovalForAll(operator, approved); }
    // function isApprovedForAll(address owner, address operator) public view override returns (bool) { return super.isApprovedForAll(owner, operator); }
    // function transferFrom(address from, address to, uint256 tokenId) public override { super.transferFrom(from, to, tokenId); }
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override { super.safeTransferFrom(from, to, tokenId); }
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override { super.safeTransferFrom(from, to, tokenId, data); }
}
```

**Explanation and Considerations:**

1.  **Complexity:** This contract is significantly more complex than a standard static NFT. It manages intricate state and configuration.
2.  **Gas Costs:** State changes (leveling, applying items, quests, mutations) will incur gas costs. The `tokenURI` function, while crucial, is designed here to point to an *external* API endpoint that retrieves the on-chain state (`getTokenData`) and renders the image/JSON. Generating the full JSON on-chain with all details and layers is possible but extremely gas-intensive and often impractical.
3.  **Off-Chain Components:** A real-world implementation requires:
    *   An API endpoint at the `_baseTokenURI` to receive `tokenId`, query the contract's state (`getTokenData`), and dynamically generate the ERC721 JSON metadata (including assembling the image from layers based on the layer identifiers).
    *   A system to host/render the visual layers (`layerIdentifier`s). These could be SVG parts, PNG layers, etc.
    *   Potentially a keeper bot or external system to call `triggerTimeBasedUpdate` and `performQuestAction` (if quests aren't purely on-chain or owner-triggered).
4.  **Randomness:** The mutation logic uses a basic form of on-chain pseudo-randomness (`keccak256(abi.encodePacked(block.timestamp, tx.origin, ...))`). **This is NOT secure for features requiring unpredictable outcomes in a high-value context.** A production system would use Chainlink VRF or a similar decentralized oracle for secure randomness.
5.  **Extensibility:** The use of string identifiers (`effectIdentifier`, `conditionIdentifier`, `layerIdentifier`, `status`) allows for extending logic and off-chain interpretation without changing the core contract significantly, but it pushes complexity off-chain. A more on-chain heavy design would involve mapping these to function calls or enums.
6.  **Item and Quest Logic:** The `applyItem` and `claimQuestReward` functions contain simplified logic. Real-world systems would involve detailed effect implementations and robust quest completion verification. Item application could also involve burning or transferring item tokens if items were separate NFTs or fungible tokens.
7.  **Scalability:** Storing extensive historical data or complex per-avatar logs on-chain would increase costs. This design keeps the core current state on-chain.

This contract provides a framework for a dynamic NFT system where the NFTs are living, evolving digital entities with on-chain characteristics that influence their appearance and capabilities.