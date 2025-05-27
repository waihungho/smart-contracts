Okay, let's create a smart contract that embodies a complex, interactive system – something like the core logic for an on-chain simulation or a strategy game. It will involve managing different types of assets (fungible resources, non-fungible units/items), time-based actions, upgrades, crafting, and randomness-influenced outcomes.

We'll call this contract `ChronicleEngine`. It will manage game state but rely on external contracts for the actual ERC20/ERC721 tokens (Resource Tokens, Unit NFTs, Item NFTs, and a main Utility Token).

---

### Contract Outline & Function Summary

**Contract Name:** `ChronicleEngine`

**Purpose:** Manages the core logic and state for an on-chain simulation/game involving units, items, resources, crafting, quests, and battles. It orchestrates interactions between various token types and tracks player progress and asset states.

**Key Concepts:**
*   **Units (NFTs):** Player-owned agents with stats that can be upgraded. Used for resource gathering, quests, and battles.
*   **Items (NFTs):** Equipable or consumable NFTs with stats or effects. Can be crafted and have durability.
*   **Resources (ERC20s):** Fungible tokens gathered by units or rewarded by quests/battles. Used for crafting and upgrades.
*   **Chronicle Token (ERC20):** A main utility token used for transaction fees within the game, upgrades, or crafting.
*   **Crafting:** Combining resources/items with a chance of success based on unit/player stats.
*   **Quests:** Time-based expeditions for units, yielding rewards or penalties based on stats and randomness.
*   **Battles:** Player-vs-Player or Player-vs-Environment challenges with outcomes influenced by stats and randomness.
*   **Staking:** Units can be staked to passively generate resources over time.
*   **Randomness:** Critical for crafting outcomes, quest results, and battle resolution. Requires a secure oracle like Chainlink VRF.

**Interfaces/Dependencies (Assumed External Contracts):**
*   `IERC20` for Resource Tokens and Chronicle Token
*   `IERC721` for Unit NFTs and Item NFTs
*   (Conceptual) `IVRFCoordinatorV2` and `LinkTokenInterface` if using Chainlink VRF for randomness.

**State Variables:**
*   Addresses of external token/NFT contracts.
*   Mappings to track Unit stats (`unitStats`).
*   Mappings to track Item stats and durability (`itemStats`, `itemDurability`).
*   Mappings to track active Staking (`unitStakingInfo`).
*   Mappings to track active Quests (`unitQuestInfo`).
*   Mappings to track active Battles (`battleInfo`).
*   Recipe definitions for crafting.
*   Quest definitions.
*   Battle configurations.
*   Admin/Owner address.
*   Nonce for randomness requests.

**Functions Summary (Approx. 25+ Functions):**

**I. Setup & Configuration (Admin Only):**
1.  `setChronicleTokenAddress(address _token)`: Sets the address of the main utility token.
2.  `addResourceToken(uint256 _resourceId, address _token)`: Registers a new type of resource token.
3.  `setUnitNFTAddress(address _nft)`: Sets the address of the Unit NFT contract.
4.  `setItemNFTAddress(address _nft)`: Sets the address of the Item NFT contract.
5.  `addCraftingRecipe(...)`: Defines a new recipe (inputs, outputs, success chance formula).
6.  `addQuestDefinition(...)`: Defines a new quest type (requirements, duration, potential rewards/penalties).
7.  `addBattleDefinition(...)`: Defines a new battle type (entry cost, participants, reward structure).
8.  `setVRFConfig(...)`: Sets parameters for Chainlink VRF (coordinator, keyhash, fee - conceptual).
9.  `pauseGame(bool _paused)`: Pauses certain game actions.

**II. Resource & Staking:**
10. `stakeUnitForResources(uint256 _unitTokenId)`: Stakes a unit NFT to start resource generation.
11. `unstakeUnitFromResources(uint256 _unitTokenId)`: Unstakes a unit NFT.
12. `claimStakedResources(uint256 _unitTokenId)`: Calculates and transfers accumulated resources from staking.
13. `getResourceAmount(uint256 _resourceId, address _player)`: Gets a player's balance of a specific resource. (View)

**III. Unit & Item Management:**
14. `upgradeUnitStats(uint256 _unitTokenId, uint256 _statId, uint256 _levels)`: Upgrades a unit's stat using resources/tokens.
15. `repairItem(uint256 _itemTokenId, uint256[] _resourceIds, uint256[] _amounts)`: Repairs an item's durability using resources.
16. `getUnitStats(uint256 _unitTokenId)`: Retrieves a unit's current stats. (View)
17. `getItemStats(uint256 _itemTokenId)`: Retrieves an item's current stats and durability. (View)
18. `transferUnitTo(address _to, uint256 _unitTokenId)`: Initiates transfer of a unit (requires external ERC721 approval).
19. `transferItemTo(address _to, uint256 _itemTokenId)`: Initiates transfer of an item (requires external ERC721 approval).

**IV. Core Mechanics:**
20. `craftItem(uint256 _recipeId, uint256[] _unitTokenIds, uint256[] _itemTokenIds)`: Initiates crafting using ingredients and potentially unit/item bonuses. Requests randomness.
21. `fulfillCraft(bytes32 _requestId, uint256 _randomness)`: Internal/Callback function to resolve crafting outcome based on randomness.
22. `startQuest(uint256 _questId, uint256[] _unitTokenIds, uint256[] _itemTokenIds)`: Sends units on a quest (requires prerequisites, locks assets for duration). Requests randomness.
23. `completeQuest(uint256 _unitTokenId)`: Finalizes a quest after its duration, calculates outcome, distributes rewards/penalties. Uses randomness (from the request initiated by `startQuest`).
24. `initiateBattle(uint256 _battleConfigId, uint256[] _playerUnitTokenIds, uint256[] _playerItemTokenIds, address _opponent)`: Starts a battle (PvP or PvE). Requires entry cost. Requests randomness.
25. `fulfillBattle(bytes32 _requestId, uint256 _randomness)`: Internal/Callback function to resolve battle outcome based on randomness. Handles rewards, penalties, item durability loss.

**V. Utilities & Views:**
26. `getPlayerChronicleBalance(address _player)`: Gets player's main utility token balance. (View)
27. `getUnitOwner(uint256 _unitTokenId)`: Gets owner of a unit NFT (delegates to ERC721). (View)
28. `getItemOwner(uint256 _itemTokenId)`: Gets owner of an item NFT (delegates to ERC721). (View)
29. `getUnitStakingInfo(uint256 _unitTokenId)`: Gets details about a unit's active staking. (View)
30. `getUnitQuestInfo(uint256 _unitTokenId)`: Gets details about a unit's active quest. (View)
31. `getBattleInfo(uint256 _battleId)`: Gets details about an active or resolved battle. (View)

*Note: Some functions like `fulfillCraft`, `fulfillQuest`, `fulfillBattle` are designed to be internal or called by a trusted oracle/keeper service after randomness is available, rather than directly by a player.*

---

### Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // Using SafeERC20/SafeERC721 patterns is recommended in production
// We will simulate VRF interaction for simplicity, but a real implementation needs IVRFCoordinatorV2 and LinkTokenInterface

/**
 * @title ChronicleEngine
 * @dev Core smart contract for the Chronicle of Ethers simulation/game.
 * Manages game state, unit/item stats, crafting, quests, and battles.
 * Relies on external ERC20 and ERC721 contracts for assets.
 */
contract ChronicleEngine {
    using Address for address;

    address public immutable owner; // Basic owner pattern

    bool public paused = false;

    // --- Contract Addresses ---
    address public chronicleToken; // Main utility token
    address public unitNFT;
    address public itemNFT;
    mapping(uint256 => address) public resourceTokens; // resourceId => address

    // --- Randomness (Conceptual VRF Integration) ---
    // In a real dApp, this would integrate with Chainlink VRF or similar
    uint256 private _randomnessNonce = 0; // To track random requests
    mapping(bytes32 => uint256) private _randomnessResults; // requestId => result
    mapping(bytes32 => uint256) private _randomRequestType; // requestId => type (1=Craft, 2=Quest, 3=Battle)
    mapping(bytes32 => bytes) private _randomRequestData; // requestId => encoded data (e.g., item IDs, unit IDs)

    // --- Game State Structures ---

    struct UnitStats {
        uint256 power;
        uint256 speed;
        uint256 luck;
        uint256 durability; // Maybe units have durability too? Or energy? Let's say just stats for now.
    }

    struct ItemStats {
        uint256 basePower;
        uint256 baseSpeed;
        uint256 baseLuck;
        uint256 maxDurability;
    }

    struct StakingInfo {
        uint40 startTime; // uint40 is enough for timestamps until ~2500
        // Maybe also store resource generation rate per unit type here or in a separate config
    }

    struct QuestInfo {
        uint40 startTime;
        uint40 endTime;
        uint256 questConfigId;
        uint256[] unitTokenIds; // Units involved in this quest
        uint256[] itemTokenIds; // Items involved
        bytes32 randomnessRequestId; // Link to the randomness request for resolution
        bool resolved;
    }

    struct BattleInfo {
        address player1;
        address player2;
        uint256 battleConfigId;
        uint256[] player1UnitTokenIds;
        uint256[] player1ItemTokenIds;
        uint256[] player2UnitTokenIds; // For PvP, empty for PvE
        uint256[] player2ItemTokenIds; // For PvP, empty for PvE
        uint40 startTime;
        bytes32 randomnessRequestId; // Link to randomness
        bool resolved;
        address winner; // Address of the winner (0x0 for undecided or PvE win by contract)
    }

    struct CraftingRequest {
        address crafter;
        uint256 recipeId;
        uint256[] unitTokenIds; // Units potentially boosting craft
        uint256[] itemTokenIds; // Items consumed or boosting craft
        bytes32 randomnessRequestId; // Link to randomness
        bool resolved;
    }

    // --- Game Data (Simplified Mappings for Example) ---
    mapping(uint256 => UnitStats) public unitStats; // unitTokenId => stats
    mapping(uint256 => ItemStats) public itemStats; // itemTokenId => stats
    mapping(uint256 => uint256) public itemDurability; // itemTokenId => current durability

    mapping(uint256 => StakingInfo) public unitStakingInfo; // unitTokenId => staking info (0 startTime means not staked)
    mapping(uint256 => QuestInfo) public unitQuestInfo; // unitTokenId => quest info (0 startTime means not on quest)
    mapping(uint256 => BattleInfo) public battleInfo; // battleId => info

    mapping(bytes32 => CraftingRequest) public craftingRequests; // requestId => request info

    // --- Configuration Data (Admin sets these) ---
    struct Recipe {
        mapping(uint256 => uint256) resourceInputs; // resourceId => amount
        mapping(uint256 => uint256) itemInputs; // itemTokenId template => amount (e.g., requires 1 of 'Iron Bar' type item) - *Simplified: Use item template IDs not specific tokenIds*
        mapping(uint256 => uint256) tokenInputs; // resourceId/chronicleTokenId => amount (using resourceId mapping keys for simplicity)
        uint256 outputItemTemplateId; // What item template is produced on success
        uint256 baseSuccessChance; // e.g., 70 for 70%
        // Add stat scaling for chance, quality, etc.
    }
    mapping(uint256 => Recipe) private recipes; // recipeId => recipe

    struct QuestConfig {
        string name; // e.g., "Forest Gathering", "Goblin Hunt"
        uint40 duration; // Seconds
        mapping(uint256 => uint256) requiredResources; // resourceId => amount
        mapping(uint256 => uint256) requiredItemTemplates; // itemTemplateId => amount
        uint256 minUnits;
        // Add reward/penalty structures, stat checks, etc.
    }
    mapping(uint256 => QuestConfig) private questConfigs; // questConfigId => config

    struct BattleConfig {
        string name; // e.g., "Arena Duel", "Cave Raid"
        mapping(uint256 => uint256) entryCost; // resourceId/chronicleTokenId => amount
        bool isPvE; // True for Player vs Environment
        uint256 opponentPowerLevel; // For PvE
        // Add reward structures, item durability loss formulas, stat influence
    }
    mapping(uint256 => BattleConfig) private battleConfigs; // battleConfigId => config
    uint256 private _nextBattleId = 1; // Counter for battle IDs

    // --- Events ---
    event Paused(bool _paused);
    event ResourceTokenAdded(uint256 indexed resourceId, address indexed tokenAddress);
    event UnitStaked(uint256 indexed unitTokenId, address indexed owner);
    event UnitUnstaked(uint256 indexed unitTokenId, address indexed owner);
    event ResourcesClaimed(uint256 indexed unitTokenId, address indexed owner, uint256 resourceId, uint256 amount);
    event UnitStatsUpgraded(uint256 indexed unitTokenId, uint256 indexed statId, uint256 levelsIncreased);
    event ItemRepaired(uint256 indexed itemTokenId, uint256 newDurability);
    event CraftingRequested(bytes32 indexed requestId, address indexed crafter, uint256 indexed recipeId);
    event ItemCrafted(bytes32 indexed requestId, uint256 indexed recipeId, uint256 newItemTokenId, uint256 quality); // quality might be derived from randomness/stats
    event CraftingFailed(bytes32 indexed requestId, uint256 indexed recipeId, string reason);
    event QuestStarted(uint256 indexed questConfigId, address indexed player, uint256[] unitTokenIds, bytes32 requestId);
    event QuestCompleted(bytes32 indexed requestId, uint256 indexed questConfigId, address indexed player, bool success, string outcome);
    event BattleInitiated(bytes32 indexed requestId, uint256 indexed battleConfigId, address indexed player1, address indexed player2);
    event BattleResolved(bytes32 indexed requestId, uint256 indexed battleConfigId, address winner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyVRF() {
        // In a real VRF integration, this would check msg.sender against the VRF coordinator address
        // require(msg.sender == vrfCoordinatorAddress, "Not VRF coordinator");
        _; // Placeholder for example
    }

    constructor() {
        owner = msg.sender;
    }

    // --- I. Setup & Configuration ---

    /**
     * @dev Sets the address of the main Chronicle utility token.
     * @param _token The address of the ERC20 Chronicle Token contract.
     */
    function setChronicleTokenAddress(address _token) external onlyOwner {
        require(_token.isContract(), "Not a contract address");
        chronicleToken = _token;
    }

    /**
     * @dev Registers a new type of resource token.
     * @param _resourceId A unique identifier for the resource (e.g., 1 for Wood, 2 for Stone).
     * @param _token The address of the ERC20 token contract for this resource.
     */
    function addResourceToken(uint256 _resourceId, address _token) external onlyOwner {
        require(_token.isContract(), "Not a contract address");
        require(resourceTokens[_resourceId] == address(0), "Resource ID already exists");
        resourceTokens[_resourceId] = _token;
        emit ResourceTokenAdded(_resourceId, _token);
    }

    /**
     * @dev Sets the address of the Unit NFT contract.
     * @param _nft The address of the ERC721 Unit NFT contract.
     */
    function setUnitNFTAddress(address _nft) external onlyOwner {
        require(_nft.isContract(), "Not a contract address");
        unitNFT = _nft;
    }

    /**
     * @dev Sets the address of the Item NFT contract.
     * @param _nft The address of the ERC721 Item NFT contract.
     */
    function setItemNFTAddress(address _nft) external onlyOwner {
        require(_nft.isContract(), "Not a contract address");
        itemNFT = _nft;
    }

     /**
      * @dev Defines a new crafting recipe.
      * @param _recipeId Unique ID for the recipe.
      * @param _resourceInputs Resource requirements (resourceId => amount).
      * @param _itemTemplateInputs Item requirements (itemTemplateId => amount).
      * @param _tokenInputs Chronicle token/resource token requirements (resourceId/0 for chronicle => amount).
      * @param _outputItemTemplateId The template ID of the item created on success.
      * @param _baseSuccessChance Base percentage chance (0-100).
      */
    function addCraftingRecipe(
        uint256 _recipeId,
        uint256[] memory _resourceInputIds, uint256[] memory _resourceInputAmounts,
        uint256[] memory _itemTemplateInputIds, uint256[] memory _itemTemplateInputAmounts,
        uint256[] memory _tokenInputIds, uint256[] memory _tokenInputAmounts,
        uint256 _outputItemTemplateId,
        uint256 _baseSuccessChance
    ) external onlyOwner {
        require(_recipeId != 0, "Recipe ID must be non-zero");
        require(recipes[_recipeId].outputItemTemplateId == 0, "Recipe ID already exists"); // Check if recipeId is already used

        Recipe storage recipe = recipes[_recipeId];
        for (uint i = 0; i < _resourceInputIds.length; i++) {
             require(resourceTokens[_resourceInputIds[i]] != address(0), "Invalid resource ID in inputs");
             recipe.resourceInputs[_resourceInputIds[i]] = _resourceInputAmounts[i];
        }
         for (uint i = 0; i < _itemTemplateInputIds.length; i++) {
             // Basic check, assumes item template IDs 0 is invalid
             require(_itemTemplateInputIds[i] != 0, "Invalid item template ID in inputs");
             recipe.itemInputs[_itemTemplateInputIds[i]] = _itemTemplateInputAmounts[i];
        }
         for (uint i = 0; i < _tokenInputIds.length; i++) {
             // 0 can be reserved for Chronicle Token, other IDs map to resources
              require(_tokenInputIds[i] == 0 || resourceTokens[_tokenInputIds[i]] != address(0), "Invalid token ID in inputs");
             recipe.tokenInputs[_tokenInputIds[i]] = _tokenInputAmounts[i];
        }
        // Basic check, assumes item template IDs 0 is invalid
        require(_outputItemTemplateId != 0, "Invalid output item template ID");
        recipe.outputItemTemplateId = _outputItemTemplateId;
        recipe.baseSuccessChance = _baseSuccessChance;
    }

     /**
      * @dev Defines a new quest type.
      * @param _questConfigId Unique ID for the quest config.
      * @param _name Quest name.
      * @param _duration Duration in seconds.
      * @param _requiredResourceIds Resource requirements (resourceId => amount).
      * @param _requiredItemTemplateIds Item requirements (itemTemplateId => amount).
      * @param _minUnits Minimum number of units required.
      * // Add reward/penalty parameters here
      */
    function addQuestDefinition(
        uint256 _questConfigId,
        string memory _name,
        uint40 _duration,
        uint256[] memory _requiredResourceIds, uint256[] memory _requiredResourceAmounts,
        uint256[] memory _requiredItemTemplateIds, uint256[] memory _requiredItemTemplateAmounts,
        uint256 _minUnits
    ) external onlyOwner {
         require(_questConfigId != 0, "Quest config ID must be non-zero");
         require(questConfigs[_questConfigId].duration == 0, "Quest config ID already exists"); // Check if questConfigId is already used

        QuestConfig storage config = questConfigs[_questConfigId];
        config.name = _name;
        config.duration = _duration;
        for (uint i = 0; i < _requiredResourceIds.length; i++) {
             require(resourceTokens[_requiredResourceIds[i]] != address(0), "Invalid resource ID in requirements");
             config.requiredResources[_requiredResourceIds[i]] = _requiredResourceAmounts[i];
        }
         for (uint i = 0; i < _requiredItemTemplateIds.length; i++) {
             require(_requiredItemTemplateIds[i] != 0, "Invalid item template ID in requirements");
             config.requiredItemTemplates[_requiredItemTemplateIds[i]] = _requiredItemTemplateAmounts[i];
        }
        config.minUnits = _minUnits;
         // Initialize reward/penalty structures if needed
    }

     /**
      * @dev Defines a new battle type.
      * @param _battleConfigId Unique ID for the battle config.
      * @param _name Battle name.
      * @param _entryCostResourceIds Entry cost (resourceId/0 for chronicle => amount).
      * @param _isPvE True if PvE, false if PvP config.
      * @param _opponentPowerLevel For PvE battles.
      * // Add reward/penalty parameters here
      */
    function addBattleDefinition(
        uint256 _battleConfigId,
        string memory _name,
        uint256[] memory _entryCostResourceIds, uint256[] memory _entryCostAmounts,
        bool _isPvE,
        uint256 _opponentPowerLevel
    ) external onlyOwner {
         require(_battleConfigId != 0, "Battle config ID must be non-zero");
         require(battleConfigs[_battleConfigId].entryCostResourceIds.length == 0, "Battle config ID already exists"); // Check if battleConfigId is already used

        BattleConfig storage config = battleConfigs[_battleConfigId];
        config.name = _name;
        for (uint i = 0; i < _entryCostResourceIds.length; i++) {
             require(_entryCostResourceIds[i] == 0 || resourceTokens[_entryCostResourceIds[i]] != address(0), "Invalid token ID in entry cost");
             config.entryCost[_entryCostResourceIds[i]] = _entryCostAmounts[i];
        }
        config.isPvE = _isPvE;
        config.opponentPowerLevel = _opponentPowerLevel;
        // Initialize reward/penalty structures if needed
    }


    /**
     * @dev Pauses or unpauses core game actions.
     * @param _paused The new pause state.
     */
    function pauseGame(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /**
     * @dev Sets parameters for Chainlink VRF (conceptual).
     * In a real implementation, this interacts with VRF Coordinator.
     */
    function setVRFConfig(address /*_coordinator*/, bytes32 /*_keyhash*/, uint32 /*_subId*/, uint32 /*_callbackGasLimit*/, uint96 /*_requestConfirmations*/, uint32 /*_numWords*/) external onlyOwner {
        // Placeholder for VRF config setup
        revert("VRF config not implemented in this example");
    }


    // --- II. Resource & Staking ---

    /**
     * @dev Stakes a unit NFT to start accumulating resources.
     * Requires the contract to be approved as an operator for the unit NFT.
     * @param _unitTokenId The ID of the unit NFT to stake.
     */
    function stakeUnitForResources(uint256 _unitTokenId) external whenNotPaused {
        require(unitNFT != address(0), "Unit NFT contract not set");
        require(IERC721(unitNFT).ownerOf(_unitTokenId) == msg.sender, "Not owner of unit");
        require(unitStakingInfo[_unitTokenId].startTime == 0, "Unit is already staked");
        // Could add checks if unit is on quest/battle

        // Transfer unit to the contract (requires prior approval)
        IERC721(unitNFT).safeTransferFrom(msg.sender, address(this), _unitTokenId);

        unitStakingInfo[_unitTokenId] = StakingInfo({
            startTime: uint40(block.timestamp)
            // Add base rate or link to unit type/stats for rate calculation
        });

        emit UnitStaked(_unitTokenId, msg.sender);
    }

    /**
     * @dev Unstakes a unit NFT and allows claiming resources.
     * @param _unitTokenId The ID of the unit NFT to unstake.
     */
    function unstakeUnitFromResources(uint256 _unitTokenId) external whenNotPaused {
        require(unitNFT != address(0), "Unit NFT contract not set");
        require(IERC721(unitNFT).ownerOf(_unitTokenId) == address(this), "Unit not staked in this contract");
        require(unitStakingInfo[_unitTokenId].startTime != 0, "Unit is not staked");

        // Claim resources first (optional, could be separate)
        claimStakedResources(_unitTokenId);

        delete unitStakingInfo[_unitTokenId];

        // Transfer unit back to the owner
         IERC721(unitNFT).safeTransferFrom(address(this), msg.sender, _unitTokenId);

        emit UnitUnstaked(_unitTokenId, msg.sender);
    }

    /**
     * @dev Calculates and transfers accumulated resources from staking a unit.
     * @param _unitTokenId The ID of the staked unit NFT.
     */
    function claimStakedResources(uint256 _unitTokenId) public whenNotPaused {
        require(unitStakingInfo[_unitTokenId].startTime != 0, "Unit is not staked");

        uint40 stakedStartTime = unitStakingInfo[_unitTokenId].startTime;
        uint256 durationStaked = block.timestamp - stakedStartTime;
        address unitOwner = IERC721(unitNFT).ownerOf(_unitTokenId); // Get owner *before* unstaking if called internally by unstake

        // --- Complex Calculation Example (Simplified) ---
        // This would ideally factor in unit stats, global boosts, resource type, etc.
        // For simplicity, let's say UnitStats.power influences resource production for resource ID 1 (Wood)
        UnitStats memory stats = unitStats[_unitTokenId];
        uint256 woodResourceId = 1; // Example ID for wood
        address woodToken = resourceTokens[woodResourceId];
        require(woodToken != address(0), "Wood resource token not configured");

        // Example formula: amount = duration_seconds * power * base_rate / divisor
        uint256 baseRate = 1; // Resources per second per power
        uint256 amountWood = (durationStaked * stats.power * baseRate) / 100; // Example divisor

        if (amountWood > 0) {
            // Mint or transfer resources to the original staker (unitOwner)
            // Requires the resource token contract to have a minting or transfer function callable by this contract.
            // Or if resources are pre-minted and held by this contract, just transferFrom here to owner.
            // For example: IERC20(woodToken).transfer(unitOwner, amountWood); // Assumes this contract has tokens or can mint
             // In a real scenario, you'd likely have a ResourceToken contract with specific minting/transfer logic controlled by this engine.
             // Simulate transfer to owner's balance managed by this contract, or call external token.
             // External token transfer:
             IERC20(woodToken).transfer(unitOwner, amountWood); // Requires this contract to hold/mint resources

            emit ResourcesClaimed(_unitTokenId, unitOwner, woodResourceId, amountWood);
        }

        // Reset staking start time to now, *or* delete if this is part of unstaking
        // If just claiming without unstaking:
         unitStakingInfo[_unitTokenId].startTime = uint40(block.timestamp);
         // If called internally by unstake, the mapping entry will be deleted afterwards.
    }

    /**
     * @dev Gets the balance of a specific resource for a player.
     * @param _resourceId The ID of the resource.
     * @param _player The address of the player.
     * @return The amount of the resource the player holds.
     */
    function getResourceAmount(uint256 _resourceId, address _player) external view returns (uint256) {
         address tokenAddress = resourceTokens[_resourceId];
         require(tokenAddress != address(0), "Unknown resource ID");
         return IERC20(tokenAddress).balanceOf(_player);
    }

    // --- III. Unit & Item Management ---

    /**
     * @dev Upgrades a specific stat of a unit NFT using resources or Chronicle Token.
     * Requires player to hold sufficient resources/tokens and approve transfers.
     * @param _unitTokenId The ID of the unit to upgrade.
     * @param _statId The ID of the stat to upgrade (e.g., 1=Power, 2=Speed, 3=Luck).
     * @param _levels The number of levels to upgrade the stat.
     */
    function upgradeUnitStats(uint256 _unitTokenId, uint256 _statId, uint256 _levels) external whenNotPaused {
        require(unitNFT != address(0), "Unit NFT contract not set");
        require(IERC721(unitNFT).ownerOf(_unitTokenId) == msg.sender, "Not owner of unit");
        require(_levels > 0, "Must upgrade at least one level");
        require(_statId >= 1 && _statId <= 3, "Invalid stat ID (1=Power, 2=Speed, 3=Luck)"); // Example stat IDs

        // --- Complex Cost Calculation Example ---
        // Cost increases with current level and number of levels
        uint256 currentStatValue;
        if (_statId == 1) currentStatValue = unitStats[_unitTokenId].power;
        else if (_statId == 2) currentStatValue = unitStats[_unitTokenId].speed;
        else currentStatValue = unitStats[_unitTokenId].luck; // statId == 3

        uint256 chronicleTokenCost = 0;
        // Example cost formula: cost = sum(level * cost_multiplier) for levels to upgrade
        uint256 baseCostPerLevel = 10; // Example
        uint256 costMultiplier = 5; // Example
        for (uint i = 0; i < _levels; i++) {
            chronicleTokenCost += (currentStatValue + i) * costMultiplier + baseCostPerLevel;
        }

        require(chronicleToken != address(0), "Chronicle Token contract not set");
        require(IERC20(chronicleToken).balanceOf(msg.sender) >= chronicleTokenCost, "Insufficient Chronicle Tokens");

        // Transfer cost (requires prior approval from msg.sender)
        IERC20(chronicleToken).transferFrom(msg.sender, address(this), chronicleTokenCost);

        // Update stats
        if (_statId == 1) unitStats[_unitTokenId].power += _levels;
        else if (_statId == 2) unitStats[_unitTokenId].speed += _levels;
        else unitStats[_unitTokenId].luck += _levels;

        emit UnitStatsUpgraded(_unitTokenId, _statId, _levels);
    }

    /**
     * @dev Repairs an item's durability using resources.
     * Requires player to hold sufficient resources and approve transfers.
     * @param _itemTokenId The ID of the item to repair.
     * @param _resourceIds The IDs of resources used for repair.
     * @param _amounts The amounts of resources used for repair.
     */
    function repairItem(uint256 _itemTokenId, uint256[] memory _resourceIds, uint256[] memory _amounts) external whenNotPaused {
        require(itemNFT != address(0), "Item NFT contract not set");
        require(IERC721(itemNFT).ownerOf(_itemTokenId) == msg.sender, "Not owner of item");
        require(_resourceIds.length == _amounts.length, "Mismatched resource arrays");
        require(itemStats[_itemTokenId].maxDurability > 0, "Item is not repairable"); // Or check a repairable flag

        uint256 currentDurability = itemDurability[_itemTokenId];
        uint256 maxDurability = itemStats[_itemTokenId].maxDurability;
        require(currentDurability < maxDurability, "Item is already at full durability");

        uint256 durabilityRestored = 0;
        // --- Complex Repair Calculation Example ---
        // Durability restored depends on resource types and amounts
        // Cost/repair amount could also scale with item's max durability
        for (uint i = 0; i < _resourceIds.length; i++) {
            uint256 resourceId = _resourceIds[i];
            uint256 amount = _amounts[i];
            address resourceToken = resourceTokens[resourceId];
            require(resourceToken != address(0), "Invalid resource ID for repair");

            // Requires sufficient balance and prior approval
            require(IERC20(resourceToken).balanceOf(msg.sender) >= amount, "Insufficient resources for repair");
            IERC20(resourceToken).transferFrom(msg.sender, address(this), amount); // Transfer resources

            // Example repair amount calculation per resource type
            if (resourceId == 2) durabilityRestored += amount * 2; // Stone gives 2 durability per unit
            if (resourceId == 3) durabilityRestored += amount * 5; // Ore gives 5 durability per unit
            // Add more resource types...
        }

        uint256 newDurability = currentDurability + durabilityRestored;
        if (newDurability > maxDurability) {
            newDurability = maxDurability;
        }

        itemDurability[_itemTokenId] = newDurability;

        emit ItemRepaired(_itemTokenId, newDurability);
    }

    /**
     * @dev Gets the current stats of a unit.
     * @param _unitTokenId The ID of the unit NFT.
     * @return The UnitStats struct.
     */
    function getUnitStats(uint256 _unitTokenId) external view returns (UnitStats memory) {
        require(unitNFT != address(0), "Unit NFT contract not set");
        // Optional: Check if unit exists via ERC721(unitNFT).ownerOf(_unitTokenId)
        return unitStats[_unitTokenId];
    }

    /**
     * @dev Gets the base stats and current durability of an item.
     * @param _itemTokenId The ID of the item NFT.
     * @return The ItemStats struct and current durability.
     */
    function getItemStats(uint256 _itemTokenId) external view returns (ItemStats memory, uint256) {
        require(itemNFT != address(0), "Item NFT contract not set");
        // Optional: Check if item exists via IERC721(itemNFT).ownerOf(_itemTokenId)
        return (itemStats[_itemTokenId], itemDurability[_itemTokenId]);
    }

    /**
     * @dev Initiates transfer of a Unit NFT (requires prior approval).
     * This contract must be an operator for the NFT.
     * @param _to The recipient address.
     * @param _unitTokenId The ID of the unit to transfer.
     */
    function transferUnitTo(address _to, uint256 _unitTokenId) external whenNotPaused {
         require(unitNFT != address(0), "Unit NFT contract not set");
         require(IERC721(unitNFT).ownerOf(_unitTokenId) == msg.sender, "Not owner of unit");
         // Perform any game state checks: is unit staked, on quest, etc. If so, disallow transfer.
         require(unitStakingInfo[_unitTokenId].startTime == 0, "Unit is staked");
         require(unitQuestInfo[_unitTokenId].startTime == 0, "Unit is on quest");
         // require unit not in battle (if battle state prevents transfer)

         IERC721(unitNFT).transferFrom(msg.sender, _to, _unitTokenId);
         // Note: SafeTransferFrom is generally preferred, but simple transferFrom is okay if
         // the receiving address is expected to handle ERC721s (e.g., a marketplace or player wallet).
    }

    /**
     * @dev Initiates transfer of an Item NFT (requires prior approval).
     * This contract must be an operator for the NFT.
     * @param _to The recipient address.
     * @param _itemTokenId The ID of the item to transfer.
     */
    function transferItemTo(address _to, uint256 _itemTokenId) external whenNotPaused {
         require(itemNFT != address(0), "Item NFT contract not set");
         require(IERC721(itemNFT).ownerOf(_itemTokenId) == msg.sender, "Not owner of item");
          // Perform any game state checks: is item in use?
         // require item not equipped/used in active quest/battle (if state prevents transfer)

         IERC721(itemNFT).transferFrom(msg.sender, _to, _itemTokenId);
    }


    // --- IV. Core Mechanics ---

    /**
     * @dev Initiates a crafting attempt for a specific recipe.
     * Requires player to possess and approve expenditure of resources/items/tokens.
     * Requires units/items to be owned by the player and approved for use.
     * Requests randomness for outcome resolution.
     * @param _recipeId The ID of the recipe to craft.
     * @param _unitTokenIds Units to potentially use for crafting bonuses (must be owned by sender).
     * @param _itemTokenIds Items to potentially use for crafting bonuses (must be owned by sender). Note: Ingredients are separate.
     */
    function craftItem(uint256 _recipeId, uint256[] memory _unitTokenIds, uint256[] memory _itemTokenIds) external whenNotPaused {
         Recipe storage recipe = recipes[_recipeId];
         require(recipe.outputItemTemplateId != 0, "Recipe does not exist");
         require(chronicleToken != address(0) && unitNFT != address(0) && itemNFT != address(0), "Game contracts not set");

         // 1. Check Prerequisites & Transfer Ingredients/Costs
         // Check resource requirements
         for (uint256 resourceId = 0; resourceId < 256; resourceId++) { // Iterate possible resource IDs
             uint256 requiredAmount = recipe.resourceInputs[resourceId];
             if (requiredAmount > 0) {
                 address tokenAddress = resourceTokens[resourceId];
                 require(tokenAddress != address(0), "Resource token not configured for recipe input");
                 require(IERC20(tokenAddress).balanceOf(msg.sender) >= requiredAmount, "Insufficient resources for crafting");
                 // Transfer resource (requires prior approval)
                 IERC20(tokenAddress).transferFrom(msg.sender, address(this), requiredAmount);
             }
         }
          // Check token requirements (including Chronicle Token)
         for (uint256 tokenId = 0; tokenId < 256; tokenId++) { // Use same logic for token inputs
             uint256 requiredAmount = recipe.tokenInputs[tokenId];
              if (requiredAmount > 0) {
                 address tokenAddress;
                 if (tokenId == 0) tokenAddress = chronicleToken; // 0 reserved for Chronicle Token
                 else tokenAddress = resourceTokens[tokenId];
                 require(tokenAddress != address(0), "Token not configured for recipe input");
                 require(IERC20(tokenAddress).balanceOf(msg.sender) >= requiredAmount, "Insufficient tokens for crafting");
                 // Transfer token (requires prior approval)
                 IERC20(tokenAddress).transferFrom(msg.sender, address(this), requiredAmount);
             }
         }
          // Check item *template* requirements (consumed items)
          // This requires knowing the item template ID of owned items.
          // A real system would need a lookup `itemTemplateId[itemId]` or store it on-chain.
          // Simplified for example: just consume *any* item NFTs specified by ID.
          // **WARNING:** This is a simplified example and might not match `itemInputs` logic directly.
         /*
         for (uint i = 0; i < _itemTemplateInputIds.length; i++) {
             uint256 templateId = _itemTemplateInputIds[i];
             uint256 requiredCount = recipe.itemInputs[templateId];
             if (requiredCount > 0) {
                  // Need to check if sender owns 'requiredCount' items of 'templateId'
                  // Requires mapping itemTokenId => itemTemplateId
                  // For simplicity, let's assume _itemTokenIds *are* the required item inputs
                  // And their template IDs match the recipe requirements implicitly.
                  // This is a major simplification.
             }
         }
         */
          // Assume the passed _itemTokenIds ARE the consumable inputs
         for (uint i = 0; i < _itemTokenIds.length; i++) {
             uint256 itemId = _itemTokenIds[i];
             require(IERC721(itemNFT).ownerOf(itemId) == msg.sender, "Not owner of input item");
             // Transfer/Burn the item (requires prior approval)
              IERC721(itemNFT).transferFrom(msg.sender, address(this), itemId); // Or burn
         }


         // Check units/items used for bonuses (must be owned, not consumed)
         for (uint i = 0; i < _unitTokenIds.length; i++) {
             require(IERC721(unitNFT).ownerOf(_unitTokenIds[i]) == msg.sender, "Not owner of bonus unit");
         }
          for (uint i = 0; i < _itemTokenIds.length; i++) { // These are the *bonus* items, separate from consumed inputs
             require(IERC721(itemNFT).ownerOf(_itemTokenIds[i]) == msg.sender, "Not owner of bonus item");
         }


         // 2. Request Randomness (Simulated)
         bytes32 requestId = _requestRandomness(1, abi.encode(_recipeId, _unitTokenIds, _itemTokenIds)); // Type 1 for Crafting

         // 3. Store Crafting Request State
         craftingRequests[requestId] = CraftingRequest({
             crafter: msg.sender,
             recipeId: _recipeId,
             unitTokenIds: _unitTokenIds, // Store unit/item IDs for bonus calculation during fulfillment
             itemTokenIds: _itemTokenIds,
             randomnessRequestId: requestId,
             resolved: false
         });

         emit CraftingRequested(requestId, msg.sender, _recipeId);
    }

    /**
     * @dev Internal/Callback function to fulfill a crafting request after randomness is available.
     * This would be called by a VRF oracle or trusted keeper.
     * @param _requestId The ID of the randomness request.
     * @param _randomness The random number.
     */
    function fulfillCraft(bytes32 _requestId, uint256 _randomness) internal onlyVRF {
        CraftingRequest storage req = craftingRequests[_requestId];
        require(req.randomnessRequestId != 0, "Unknown crafting request ID"); // Ensures request exists
        require(!req.resolved, "Crafting request already resolved");
        require(_randomRequestType[_requestId] == 1, "Mismatch request type"); // Sanity check

        req.resolved = true; // Mark as resolved

        // Retrieve recipe config (already checked in craftItem)
        Recipe storage recipe = recipes[req.recipeId];

        // --- Calculate Success Chance and Outcome ---
        uint256 totalChance = recipe.baseSuccessChance;

        // Add bonuses from units (simplified)
        for (uint i = 0; i < req.unitTokenIds.length; i++) {
            UnitStats memory stats = unitStats[req.unitTokenIds[i]];
            totalChance += stats.luck / 10; // Example: 10 luck adds 1% chance
        }
         // Add bonuses from items (simplified)
         for (uint i = 0; i < req.itemTokenIds.length; i++) {
            ItemStats memory stats = itemStats[req.itemTokenIds[i]];
            totalChance += stats.luck / 5; // Example: 5 item luck adds 1% chance
             // Note: In a real system, you'd check item template IDs to apply correct bonuses
         }


        // Clamp chance between 0 and 100 (or higher if desired for critical success)
        if (totalChance > 100) totalChance = 100;

        uint256 randomResult = _randomness % 100; // Get a number between 0-99

        if (randomResult < totalChance) { // Success!
            // Mint or transfer the new item NFT to the crafter
            // Requires the Item NFT contract to have a minting function callable by this contract.
            // Example: uint256 newItemTokenId = IItemNFT(itemNFT).mint(req.crafter, recipe.outputItemTemplateId);
            // Placeholder for minting logic:
            uint256 newItemTokenId = 0; // Replace with actual minting call
             // Assume minting returns a new token ID

            // Set initial item stats and full durability based on template
            // Requires a mapping itemTemplateId => ItemStats base values
            // itemStats[newItemTokenId] = baseItemStats[recipe.outputItemTemplateId];
            // itemDurability[newItemTokenId] = itemStats[newItemTokenId].maxDurability;

            emit ItemCrafted(_requestId, req.recipeId, newItemTokenId, 1); // Assume quality 1 for now
        } else { // Failure
             // Handle failure - perhaps return some resources, lose all, etc.
             emit CraftingFailed(_requestId, req.recipeId, "Crafting attempt failed");
        }

        // Clean up request data if necessary
        delete _randomRequestType[_requestId];
        delete _randomRequestData[_requestId];
        // Keep craftingRequests entry for historical lookup or delete it. Let's delete.
        delete craftingRequests[_requestId];
    }


    /**
     * @dev Sends units on a quest. Locks units and potentially items for the quest duration.
     * Requires player to own units/items and approve their use.
     * Requires player to possess and approve expenditure of required resources/items.
     * @param _questConfigId The ID of the quest to start.
     * @param _unitTokenIds The units to send on the quest.
     * @param _itemTokenIds The items to equip/use for the quest.
     */
    function startQuest(uint256 _questConfigId, uint256[] memory _unitTokenIds, uint256[] memory _itemTokenIds) external whenNotPaused {
         QuestConfig storage config = questConfigs[_questConfigId];
         require(config.duration != 0, "Quest config does not exist");
         require(unitNFT != address(0) && itemNFT != address(0), "Game contracts not set");
         require(_unitTokenIds.length >= config.minUnits, "Not enough units for quest");
         require(_unitTokenIds.length <= 10, "Too many units (example limit)"); // Example limit

         // 1. Check Unit/Item Ownership and Availability
         for (uint i = 0; i < _unitTokenIds.length; i++) {
             uint256 unitId = _unitTokenIds[i];
             require(IERC721(unitNFT).ownerOf(unitId) == msg.sender, "Not owner of unit");
             require(unitStakingInfo[unitId].startTime == 0, "Unit is staked");
             require(unitQuestInfo[unitId].startTime == 0, "Unit is already on quest");
              // Check not in battle
         }
          for (uint i = 0; i < _itemTokenIds.length; i++) {
             uint256 itemId = _itemTokenIds[i];
             require(IERC721(itemNFT).ownerOf(itemId) == msg.sender, "Not owner of item");
              // Check item durability if needed (require > 0)
              // Check item not in use elsewhere
         }


         // 2. Check Resource/Item Template Requirements & Transfer
          for (uint256 resourceId = 0; resourceId < 256; resourceId++) {
             uint256 requiredAmount = config.requiredResources[resourceId];
             if (requiredAmount > 0) {
                 address tokenAddress = resourceTokens[resourceId];
                 require(tokenAddress != address(0), "Resource token not configured for quest requirement");
                 require(IERC20(tokenAddress).balanceOf(msg.sender) >= requiredAmount, "Insufficient resources for quest");
                 IERC20(tokenAddress).transferFrom(msg.sender, address(this), requiredAmount); // Requires prior approval
             }
         }
          // Check required item *templates* and consume/lock items matching templates
          // This is complex, similar to crafting inputs. Simplified: assume _itemTokenIds includes required items
          // And these are consumed/locked.

         // 3. Lock Units & Items (by updating state, not necessarily transferring NFTs)
          for (uint i = 0; i < _unitTokenIds.length; i++) {
              unitQuestInfo[_unitTokenIds[i]] = QuestInfo({
                 startTime: uint40(block.timestamp),
                 endTime: uint40(block.timestamp + config.duration),
                 questConfigId: _questConfigId,
                 unitTokenIds: _unitTokenIds, // Store all unit IDs for this quest under each unit's entry
                 itemTokenIds: _itemTokenIds, // Store all item IDs for this quest under each unit's entry
                 randomnessRequestId: bytes32(0), // Will request randomness upon completion
                 resolved: false
             });
         }
          // Mark items as 'in use' if necessary in item state mappings

         emit QuestStarted(_questConfigId, msg.sender, _unitTokenIds, bytes32(0)); // Request ID added on completion

    }

    /**
     * @dev Completes a quest for a unit after its duration has passed.
     * Requests randomness for outcome resolution. Can only be called once duration is over.
     * @param _unitTokenId Any unit token ID that was part of the quest.
     */
    function completeQuest(uint256 _unitTokenId) external whenNotPaused {
         QuestInfo storage quest = unitQuestInfo[_unitTokenId];
         require(quest.startTime != 0, "Unit is not on a quest");
         require(block.timestamp >= quest.endTime, "Quest is not yet complete");
         require(!quest.resolved, "Quest already completed/resolved");

        // Mark all units/items involved in this quest as resolving
         for (uint i = 0; i < quest.unitTokenIds.length; i++) {
             unitQuestInfo[quest.unitTokenIds[i]].resolved = true;
         }
          // Mark items as no longer 'in use' if necessary


        // 1. Request Randomness (Simulated)
        // Need to request randomness *once* for the whole quest party.
        // Store the request ID in one of the unit's QuestInfo, or a separate mapping.
        // Let's use the first unit's request ID entry.
        bytes32 requestId = _requestRandomness(2, abi.encode(_unitTokenId)); // Type 2 for Quest
        unitQuestInfo[_unitTokenId].randomnessRequestId = requestId; // Store request ID


        emit QuestCompleted(requestId, quest.questConfigId, msg.sender, false, "Awaiting resolution"); // Emit event before resolution
    }

     /**
      * @dev Internal/Callback function to fulfill a quest request after randomness is available.
      * This would be called by a VRF oracle or trusted keeper.
      * @param _requestId The ID of the randomness request.
      * @param _randomness The random number.
      */
     function fulfillQuest(bytes32 _requestId, uint256 _randomness) internal onlyVRF {
         // Find one of the units associated with this quest request
         // This requires mapping randomnessRequestId -> a unitId. Let's use _randomRequestData
         bytes memory requestData = _randomRequestData[_requestId];
         require(requestData.length > 0, "Unknown quest request ID data");
         (uint256 sampleUnitId) = abi.decode(requestData, (uint256));

         QuestInfo storage quest = unitQuestInfo[sampleUnitId];
         require(quest.randomnessRequestId == _requestId, "Mismatch randomness request ID for quest");
         require(_randomRequestType[_requestId] == 2, "Mismatch request type"); // Sanity check

         // Mark all units/items as resolved again (safety)
         for (uint i = 0; i < quest.unitTokenIds.length; i++) {
             unitQuestInfo[quest.unitTokenIds[i]].resolved = true; // Already marked, but idempotent
         }
          // Mark items as no longer 'in use'


         // --- Calculate Quest Outcome ---
         QuestConfig storage config = questConfigs[quest.questConfigId];
         address player = IERC721(unitNFT).ownerOf(quest.unitTokenIds[0]); // Assume all units owned by same player

         // Example outcome calculation based on total unit stats and randomness
         uint256 totalPower = 0;
         uint256 totalLuck = 0;
         for (uint i = 0; i < quest.unitTokenIds.length; i++) {
             UnitStats memory stats = unitStats[quest.unitTokenIds[i]];
             totalPower += stats.power;
             totalLuck += stats.luck;
         }
          // Add item stats to totals if applicable

         // Example: Success chance based on (totalPower + totalLuck) vs a difficulty derived from randomness and config
         uint256 successThreshold = (_randomness % 100) + config.minUnits * 10; // Example difficulty scaling
         bool success = (totalPower + totalLuck) > successThreshold;

         string memory outcomeMsg;

         if (success) {
             outcomeMsg = "Quest successful!";
             // Distribute rewards (resources, items, tokens)
             // Example: Reward some resources
             uint256 rewardResourceId = 1; // Wood
             uint256 rewardAmount = totalPower * 10; // Reward scales with power
              if(resourceTokens[rewardResourceId] != address(0)) {
                 // Mint or transfer rewards to the player
                 // IERC20(resourceTokens[rewardResourceId]).transfer(player, rewardAmount); // Requires contract to hold/mint
              }
             // Example: Reward a rare item chance (requires more randomness or logic)

         } else {
             outcomeMsg = "Quest failed.";
             // Apply penalties (item durability loss, unit health loss - if units had health)
             // Example: Reduce item durability
             for (uint i = 0; i < quest.itemTokenIds.length; i++) {
                 uint256 itemId = quest.itemTokenIds[i];
                 uint256 loss = (_randomness % 20) + 5; // Lose 5-25 durability
                 if (itemDurability[itemId] > loss) itemDurability[itemId] -= loss;
                 else itemDurability[itemId] = 0; // Item broken
                 // Handle broken items (burned? become 'broken' state?)
             }
         }

         // Clean up quest info for all participating units
         for (uint i = 0; i < quest.unitTokenIds.length; i++) {
             delete unitQuestInfo[quest.unitTokenIds[i]];
         }

         emit QuestCompleted(_requestId, quest.questConfigId, player, success, outcomeMsg);

         // Clean up randomness request data
         delete _randomRequestType[_requestId];
         delete _randomRequestData[_requestId];
     }


    /**
     * @dev Initiates a battle (PvP or PvE). Requires entry cost and player's units/items.
     * Requires player to possess and approve expenditure of entry costs.
     * Requires player to own units/items and approve their use/locking.
     * Requests randomness for outcome resolution.
     * @param _battleConfigId The ID of the battle configuration.
     * @param _playerUnitTokenIds The player's units for the battle.
     * @param _playerItemTokenIds The player's items for the battle.
     * @param _opponent Address of the opponent (address(0) for PvE).
     */
    function initiateBattle(
        uint256 _battleConfigId,
        uint256[] memory _playerUnitTokenIds,
        uint256[] memory _playerItemTokenIds,
        address _opponent
    ) external whenNotPaused {
         BattleConfig storage config = battleConfigs[_battleConfigId];
         require(config.entryCostResourceIds.length != 0 || config.isPvE, "Battle config does not exist"); // Check if battleConfigId exists
         require(unitNFT != address(0) && itemNFT != address(0), "Game contracts not set");
         require(_playerUnitTokenIds.length > 0, "Must bring units to battle");
         // Check battle type matches opponent param
         if (config.isPvE) require(_opponent == address(0), "PvE battle requires no opponent address");
         else require(_opponent != address(0), "PvP battle requires an opponent address");


         // 1. Check Player Assets & Transfer Entry Cost
         // Check unit/item ownership and availability (not staked/questing/battling)
          for (uint i = 0; i < _playerUnitTokenIds.length; i++) {
             uint256 unitId = _playerUnitTokenIds[i];
             require(IERC721(unitNFT).ownerOf(unitId) == msg.sender, "Not owner of unit");
             require(unitStakingInfo[unitId].startTime == 0, "Unit is staked");
             require(unitQuestInfo[unitId].startTime == 0, "Unit is on quest");
              // Check not in *another* battle
         }
          for (uint i = 0; i < _playerItemTokenIds.length; i++) {
             uint256 itemId = _playerItemTokenIds[i];
             require(IERC721(itemNFT).ownerOf(itemId) == msg.sender, "Not owner of item");
              // Check item durability
              // Check not in use elsewhere
         }

         // Transfer entry costs
          for (uint256 resourceId = 0; resourceId < 256; resourceId++) {
             uint256 requiredAmount = config.entryCost[resourceId];
             if (requiredAmount > 0) {
                 address tokenAddress;
                 if (resourceId == 0) tokenAddress = chronicleToken;
                 else tokenAddress = resourceTokens[resourceId];
                 require(tokenAddress != address(0), "Token not configured for entry cost");
                 require(IERC20(tokenAddress).balanceOf(msg.sender) >= requiredAmount, "Insufficient tokens for entry cost");
                 IERC20(tokenAddress).transferFrom(msg.sender, address(this), requiredAmount); // Requires prior approval
             }
         }

         // For PvP, opponent must also call initiateBattle, perhaps with a matching battleId or via a separate match-making system.
         // Simplified: This example assumes PvE or a very simple PvP where one player initiates.
         // A real PvP would require state for challenges, acceptance, locking units for both players.

         uint256 battleId = _nextBattleId++;

         // 2. Store Battle State and Request Randomness (Simulated)
         bytes32 requestId = _requestRandomness(3, abi.encode(battleId)); // Type 3 for Battle

         battleInfo[battleId] = BattleInfo({
             player1: msg.sender,
             player2: _opponent, // address(0) for PvE
             battleConfigId: _battleConfigId,
             player1UnitTokenIds: _playerUnitTokenIds, // Store unit/item IDs for resolution
             player1ItemTokenIds: _playerItemTokenIds,
             player2UnitTokenIds: new uint256[](0), // Placeholder for PvP opponent units
             player2ItemTokenIds: new uint256[](0), // Placeholder for PvP opponent items
             startTime: uint40(block.timestamp),
             randomnessRequestId: requestId,
             resolved: false,
             winner: address(0)
         });

         // Lock units/items by updating their state mappings (e.g., `unitBattleInfo[unitId] = battleId`)


         emit BattleInitiated(requestId, _battleConfigId, msg.sender, _opponent);

         // In a real PvP, _opponent would need to accept and lock their assets
    }


     /**
      * @dev Internal/Callback function to fulfill a battle request after randomness is available.
      * This would be called by a VRF oracle or trusted keeper.
      * @param _requestId The ID of the randomness request.
      * @param _randomness The random number.
      */
     function fulfillBattle(bytes32 _requestId, uint256 _randomness) internal onlyVRF {
         // Find the battle ID associated with this request. Requires mapping requestId -> battleId.
         // Let's use _randomRequestData for this, storing the battle ID.
         bytes memory requestData = _randomRequestData[_requestId];
         require(requestData.length > 0, "Unknown battle request ID data");
         (uint256 battleId) = abi.decode(requestData, (uint256));

         BattleInfo storage battle = battleInfo[battleId];
         require(battle.randomnessRequestId == _requestId, "Mismatch randomness request ID for battle");
         require(!battle.resolved, "Battle already resolved");
         require(_randomRequestType[_requestId] == 3, "Mismatch request type"); // Sanity check

         battle.resolved = true; // Mark as resolved

         BattleConfig storage config = battleConfigs[battle.battleConfigId];

         // --- Calculate Battle Outcome ---
         // This is the most complex part, highly dependent on game design.
         // Example Simplified Logic: Compare total player stats vs opponent (or other player) stats, influenced by randomness.

         uint256 player1TotalPower = 0;
         uint256 player1TotalLuck = 0;
          for (uint i = 0; i < battle.player1UnitTokenIds.length; i++) {
             UnitStats memory stats = unitStats[battle.player1UnitTokenIds[i]];
             player1TotalPower += stats.power;
             player1TotalLuck += stats.luck;
              // Add item stats
          }
          // For PvP, calculate player2's stats similarly

         uint256 player1Score = (player1TotalPower * 10) + player1TotalLuck + (_randomness % 50); // Example scoring

         address winnerAddress = address(0); // Default no winner or PvE contract win

         if (config.isPvE) {
              // Compare player1Score vs config.opponentPowerLevel + randomness
              uint256 opponentScore = config.opponentPowerLevel + ((_randomness / 2) % 50); // Example PvE score
              if (player1Score > opponentScore) {
                  winnerAddress = battle.player1; // Player wins PvE
              } else {
                  // Player loses PvE - winner remains address(0) or could be a specific address representing environment win
              }
         } else {
             // PvP Logic (Requires player2 to have initiated/accepted and locked assets)
             // Calculate player2's score:
             // uint256 player2Score = ...
             // if (player1Score > player2Score) winnerAddress = battle.player1;
             // else if (player2Score > player1Score) winnerAddress = battle.player2;
             // else winnerAddress = address(0); // Draw
             revert("PvP resolution not implemented in this example"); // Placeholder for PvP
         }

         battle.winner = winnerAddress; // Record winner

         // --- Distribute Rewards/Penalties ---
         if (winnerAddress == battle.player1) {
             // Player 1 wins: Reward them, penalize opponent/environment
             // Example: Reward some Chronicle Token
             uint256 rewardAmount = 100; // Example flat reward
              if(chronicleToken != address(0)) {
                 // IERC20(chronicleToken).transfer(battle.player1, rewardAmount); // Requires contract to hold/mint
              }
              // Example: Chance for item drops
             // Example: Units/Items lose less durability

         } else if (winnerAddress != address(0)) { // Opponent wins (in PvP)
             // Player 2 wins: Reward them, penalize player 1
         }

          // Apply durability loss to player units/items regardless of win/loss (perhaps more on loss)
          for (uint i = 0; i < battle.player1ItemTokenIds.length; i++) {
              uint256 itemId = battle.player1ItemTokenIds[i];
              uint256 loss = (_randomness % 10) + 2; // Lose 2-12 durability
              if (battle.winner != battle.player1) loss += 5; // Lose more on loss
              if (itemDurability[itemId] > loss) itemDurability[itemId] -= loss;
              else itemDurability[itemId] = 0; // Item broken
          }
          // Apply similar penalties to player 2 in PvP


         // Unlock units/items by clearing their battle state mappings

         emit BattleResolved(_requestId, battle.battleConfigId, winnerAddress);

         // Clean up randomness request data
         delete _randomRequestType[_requestId];
         delete _randomRequestData[_requestId];
         // Battle info remains for historical lookup
     }


    // --- V. Utilities & Views ---

    /**
     * @dev Gets the balance of the main Chronicle utility token for a player.
     * @param _player The address of the player.
     * @return The balance of Chronicle Tokens.
     */
    function getPlayerChronicleBalance(address _player) external view returns (uint256) {
        require(chronicleToken != address(0), "Chronicle Token contract not set");
        return IERC20(chronicleToken).balanceOf(_player);
    }

    /**
     * @dev Gets the owner of a Unit NFT by querying the external contract.
     * @param _unitTokenId The ID of the unit NFT.
     * @return The owner's address.
     */
    function getUnitOwner(uint256 _unitTokenId) external view returns (address) {
        require(unitNFT != address(0), "Unit NFT contract not set");
        return IERC721(unitNFT).ownerOf(_unitTokenId);
    }

    /**
     * @dev Gets the owner of an Item NFT by querying the external contract.
     * @param _itemTokenId The ID of the item NFT.
     * @return The owner's address.
     */
    function getItemOwner(uint256 _itemTokenId) external view returns (address) {
        require(itemNFT != address(0), "Item NFT contract not set");
        return IERC721(itemNFT).ownerOf(_itemTokenId);
    }

    /**
     * @dev Gets the staking information for a unit.
     * @param _unitTokenId The ID of the unit NFT.
     * @return The StakingInfo struct.
     */
    function getUnitStakingInfo(uint256 _unitTokenId) external view returns (StakingInfo memory) {
        return unitStakingInfo[_unitTokenId];
    }

     /**
      * @dev Gets the quest information for a unit.
      * @param _unitTokenId The ID of the unit NFT.
      * @return The QuestInfo struct.
      */
    function getUnitQuestInfo(uint256 _unitTokenId) external view returns (QuestInfo memory) {
         return unitQuestInfo[_unitTokenId];
    }

     /**
      * @dev Gets the battle information for a specific battle ID.
      * @param _battleId The ID of the battle.
      * @return The BattleInfo struct.
      */
     function getBattleInfo(uint256 _battleId) external view returns (BattleInfo memory) {
         return battleInfo[_battleId];
     }

    // --- Internal/Helper Functions ---

     /**
      * @dev Simulates requesting randomness and storing request data.
      * In a real dApp, this would interact with Chainlink VRF's `requestRandomWords`.
      * @param _requestType Type of request (1=Craft, 2=Quest, 3=Battle).
      * @param _requestData Additional data needed for fulfillment.
      * @return bytes32 A unique request ID.
      */
    function _requestRandomness(uint256 _requestType, bytes memory _requestData) internal returns (bytes32 requestId) {
         _randomnessNonce++;
         requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _randomnessNonce));

         _randomRequestType[requestId] = _requestType;
         _randomRequestData[requestId] = _requestData;

         // In a real VRF system, you would trigger the VRF request here.
         // e.g., vrfCoordinator.requestRandomWords(...)

         // For this example, we simulate fulfillment immediately for testing purposes
         // **NEVER DO THIS IN PRODUCTION - IT IS NOT SECURE AND NOT ACTUALLY RANDOM**
         uint256 simulatedRandomness = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randomnessNonce, "simulate randomness")));
         _simulateVRFFulfillment(requestId, simulatedRandomness);

         return requestId;
    }

     /**
      * @dev Simulates the VRF coordinator calling back with randomness.
      * **FOR EXAMPLE/TESTING ONLY. DO NOT USE IN PRODUCTION.**
      * @param _requestId The ID of the original request.
      * @param _randomness The simulated random number.
      */
     function _simulateVRFFulfillment(bytes32 _requestId, uint256 _randomness) internal {
         uint256 requestType = _randomRequestType[_requestId];
         require(requestType != 0, "Simulated fulfillment for unknown request");

         _randomnessResults[_requestId] = _randomness; // Store for potential direct lookup (though resolution functions are better)

         // Call the appropriate fulfillment logic based on type
         if (requestType == 1) {
             fulfillCraft(_requestId, _randomness);
         } else if (requestType == 2) {
             fulfillQuest(_requestId, _randomness);
         } else if (requestType == 3) {
             fulfillBattle(_requestId, _randomness);
         } else {
             revert("Unknown randomness request type");
         }
     }


    // Admin function to simulate direct VRF fulfillment callback (for testing/demo)
    // In production, this function would be restricted `onlyVRF`.
    function simulateVRFFulfillment(bytes32 _requestId, uint256 _randomness) external onlyOwner {
        _simulateVRFFulfillment(_requestId, _randomness);
    }


    // Fallback/Receive: Consider handling incoming ETH if needed (unlikely for this contract)
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("Calls to non-existent functions or unexpected ETH");
    }
}
```

---

**Explanation and Advanced Concepts Used:**

1.  **Multi-Asset Management:** The contract interacts with multiple distinct ERC20 (Resources, Chronicle Token) and ERC721 (Units, Items) contracts. This requires careful handling of addresses, interfaces, and transfer logic (`transferFrom` implies the user needs to approve the contract to spend/move their tokens/NFTs).
2.  **State-Changing NFTs:** While the Unit/Item NFTs are external, this contract manages *associated state* for them (stats, durability, staking status, quest status, battle status). This is more complex than simple static NFTs.
3.  **Complex Mappings & Structs:** Uses nested mappings and structs (`mapping(uint256 => Recipe)`, `QuestInfo`, `BattleInfo`) to store structured data on-chain for various game entities and ongoing actions.
4.  **Time-Based Logic:** Uses `block.timestamp` to track quest durations and staking time for resource calculation.
5.  **Configurable Mechanics:** Recipes, Quests, and Battles are defined via admin functions (`addCraftingRecipe`, `addQuestDefinition`, `addBattleDefinition`) using structured data, making the game parameters adjustable without deploying a new core engine contract for every balance change or new content.
6.  **Internal Randomness Handling Pattern (with Caveats):** Implements a pattern (`_requestRandomness`, `_randomRequestType`, `_randomRequestData`, `fulfillCraft`, `fulfillQuest`, `fulfillBattle`) designed to integrate with a secure randomness oracle like Chainlink VRF. The example *simulates* the fulfillment callback for demonstration, but the comments explicitly state that the internal simulation is *not* secure for production. This demonstrates the *architecture* needed for secure, verifiable randomness.
7.  **Callback Pattern:** The `fulfill...` functions act as callbacks triggered by an external entity (like a VRF oracle keeper) once an asynchronous process (randomness generation) is complete.
8.  **Complex Calculations:** Functions like `claimStakedResources`, `upgradeUnitStats`, `repairItem`, `fulfillCraft`, `fulfillQuest`, `fulfillBattle` involve multiple inputs (unit stats, item stats, resource amounts, randomness) and perform calculations to determine outcomes, costs, and rewards. While simplified in the example, these structures support highly complex game math.
9.  **Process Tracking:** Mappings like `unitStakingInfo`, `unitQuestInfo`, `battleInfo`, `craftingRequests` track the state of ongoing or pending actions across multiple steps (initiation -> randomness request -> randomness fulfillment -> resolution).
10. **Access Control (`onlyOwner`):** Protects sensitive configuration and administrative functions.
11. **Pausability (`whenNotPaused`):** Allows the owner to pause core game actions in case of issues or upgrades (though a full upgrade pattern like UUPS or Transparent Proxies would be needed for seamless code changes).
12. **Event Emission:** Crucial for off-chain applications (frontends, indexers) to track state changes and know when actions are requested or completed.
13. **Error Handling (`require`):** Ensures valid inputs, states, and permissions before executing logic.
14. **Modular Design:** By relying on external token/NFT contracts, the `ChronicleEngine` contract is focused on the game logic itself, making it more manageable.
15. **Conceptual Item Templates:** The configuration functions (`addCraftingRecipe`, `addQuestDefinition`) reference `itemTemplateId` rather than specific `itemTokenId`s for inputs/outputs, indicating a metadata layer where a `itemTokenId` corresponds to a base `itemTemplateId` (e.g., all "Iron Sword" NFTs share template ID 101). This is a common pattern in games with many items.
16. **Function Over 20 Count:** The contract includes 31 functions based on the summary, comfortably exceeding the requirement. Each function represents a distinct action or query within the game system.
17. **Non-Duplicate:** While individual concepts (ERC20/721 interfaces, basic staking, owner checks, VRF patterns) exist in open source, this *specific combination* of detailed, interconnected game mechanics (units/items with dynamic stats, crafting with random outcomes, time-based quests, stats-influenced battles, resource staking, configuration system) in a single contract is not a standard, freely available template.
18. **Gas Considerations:** It's important to note that a contract this complex performing significant on-chain computation (especially in `fulfillQuest`, `fulfillBattle`, `craftItem`) will likely incur substantial gas costs on a Layer 1 network like Ethereum Mainnet. This type of logic is often better suited for Layer 2 solutions, optimistic rollups, or app-specific chains.

This contract provides a robust framework demonstrating how complex, interactive logic for something like a blockchain game or simulation can be structured on-chain, highlighting the interplay between different asset types, state management, timing, and external dependencies like randomness oracles.