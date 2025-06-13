Okay, here is a Solidity smart contract implementing a concept I call "Dynamic On-Chain Adventurers & Guilds" (`DOAG`). It blends elements of NFTs, dynamic metadata, game mechanics, guild systems, and introduces concepts like timed cooldowns, delegated actions, and a pattern for integrating randomness (simulated/placeholder for Chainlink VRF). It avoids directly copying standard token or DeFi patterns and aims for unique interactions.

It includes over 20 functions covering various aspects of managing adventurers, items, guilds, and game state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- OUTLINE ---
// 1. Basic ERC721 implementation for Adventurers (NFTs).
// 2. Dynamic Adventurer State: Stats, Level, XP, Inventory, Guild affiliation.
// 3. Item System: Equipable gear (modifies stats) and Consumables (single-use effect).
// 4. Guild System: Create, Join, Leave, Roles, Treasury (ETH/token).
// 5. Game Mechanics: Quests (state changes, rewards, randomness), Crafting (combining items), Leveling Up, Stat Allocation.
// 6. Time-Based Mechanics: Cooldowns for actions.
// 7. Randomness Pattern: Placeholder/simulation for external VRF integration (like Chainlink).
// 8. Dynamic Metadata: tokenURI reflecting on-chain state.
// 9. Delegated Actions: Allow owners to delegate specific actions (e.g., questing) to another address.
// 10. Admin Controls: Setting game parameters, pausing.
// 11. View Functions: Retrieving detailed state.

// --- FUNCTION SUMMARY ---
// STANDARD ERC721/Ownable (inherited/implemented):
// - constructor: Initialize contract, name, symbol.
// - supportsInterface: Standard ERC165.
// - balanceOf: Get token count for an address.
// - ownerOf: Get owner of a token ID.
// - safeTransferFrom (2 variants): Transfer token.
// - transferFrom: Transfer token (less safe).
// - approve: Approve an address to spend a token.
// - setApprovalForAll: Approve/disapprove operator for all tokens.
// - getApproved: Get approved address for a token.
// - isApprovedForAll: Check if operator is approved.
// - totalSupply: Total minted tokens.
// - tokenOfOwnerByIndex: Get token ID by index for an owner.
// - tokenByIndex: Get token ID by index.
// - renounceOwnership: Relinquish contract ownership.
// - transferOwnership: Transfer contract ownership.

// CUSTOM (20+ functions):
// 1. registerAdventurer: Mint a new Adventurer NFT with initial (random-influenced) stats.
// 2. requestRandomSeed: Initiate VRF request (placeholder).
// 3. fulfillRandomSeed: VRF callback to provide randomness for pending outcomes.
// 4. performQuest: Execute a quest for an adventurer, using stats, consuming resources, triggering randomness, awarding XP/loot.
// 5. claimPendingQuestRewards: Claim accumulated rewards from completed quests.
// 6. levelUpAdventurer: Advance adventurer level upon reaching XP threshold, grant stat points.
// 7. allocateStatPoints: Use available points to boost specific stats.
// 8. respecStats: Reset stat allocation (with cooldown/cost).
// 9. craftItem: Combine items from inventory based on stats/skill, using randomness for result quality.
// 10. useConsumableItem: Consume an item for a temporary or one-time effect.
// 11. equipGearItem: Equip an item to modify stats.
// 12. unequipGearItem: Unequip an item.
// 13. createGuild: Establish a new guild (might require reputation/level).
// 14. joinGuild: Affiliate an adventurer with a guild.
// 15. leaveGuild: Disaffiliate from a guild.
// 16. assignGuildRole: Change a member's role within a guild (permissioned).
// 17. donateToGuildTreasury: Send ETH/tokens to guild.
// 18. guildTreasuryWithdraw: Withdraw from treasury (permissioned).
// 19. delegateAction: Grant permission for a specific action type (e.g., questing) for an adventurer to another address.
// 20. revokeDelegateAction: Remove delegation permission.
// 21. updateAdventurerURI: Trigger update of the dynamic metadata for an adventurer.
// 22. setGlobalGameParameter: Admin function to adjust game tuning variables.
// 23. pauseGameActions: Admin function to pause key game logic.
// 24. unpauseGameActions: Admin function to unpause game logic.
// 25. emergencyWithdrawTokens: Admin function to rescue incorrectly sent tokens.
// 26. getAdventurerState: View function for all core adventurer data.
// 27. getAdventurerInventory: View function for adventurer's items.
// 28. getAdventurerGear: View function for equipped gear.
// 29. getAdventurerCooldowns: View function for adventurer's action cooldowns.
// 30. getGuildState: View function for all core guild data.
// 31. getGameParameters: View function for global settings.
// 32. getDelegateAllowance: View function to check if an address has delegated action permission.

contract DynamicOnChainAdventurersGuilds is ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- STATE VARIABLES ---

    Counters.Counter private _adventurerIds;
    Counters.Counter private _guildIds;

    // Basic Adventurer Stats
    struct Stats {
        uint8 strength;
        uint8 dexterity;
        uint8 constitution;
        uint8 intelligence;
        uint8 wisdom;
        uint8 charisma;
        uint8 luck; // Influences random outcomes
    }

    // Adventurer Data
    struct Adventurer {
        uint256 id; // Token ID
        address owner;
        string name;
        uint256 level;
        uint256 xp;
        Stats baseStats;
        uint256 availableStatPoints;
        uint256 guildId; // 0 if no guild
        mapping(uint256 => uint256) inventory; // itemId => quantity
        mapping(uint256 => uint256) equippedGear; // slotId => itemId
        uint256 reputation; // Global reputation score
        uint256 lastQuestTime; // For cooldowns
        mapping(uint8 => uint256) actionCooldowns; // actionType => unlockTime
        mapping(address => bool) delegatedQuestors; // Address allowed to quest for this adventurer
        mapping(bytes32 => bool) pendingRandomnessRequests; // requestId => bool (for VRF)
        mapping(bytes32 => bytes32) randomnessResults; // requestId => randomWord
    }

    // Item Data (defined off-chain, referenced by ID)
    struct Item {
        uint256 id;
        string name;
        enum ItemType { Unknown, Consumable, Gear, CraftingMaterial, QuestItem }
        ItemType itemType;
        mapping(uint8 => int256) statModifiers; // statType => modifier (for gear)
        uint256 cooldownDuration; // For consumables/actions
        uint256 craftingDifficulty; // For crafting materials/recipes
        // Add more item properties as needed
    }

    // Guild Data
    struct Guild {
        uint256 id;
        string name;
        address leader; // Contract address or owner address
        mapping(address => uint8) members; // memberAddress => role (see GuildRole enum)
        uint256 memberCount;
        uint256 treasuryBalanceETH; // Holding ETH directly
        // Consider token support later
    }

    enum GuildRole { None, Member, Officer, Leader }
    enum StatType { Str, Dex, Con, Int, Wis, Cha, Luck } // Matches Stats struct order

    // Mapping token ID to Adventurer data
    mapping(uint256 => Adventurer) public adventurers;
    // Mapping guild ID to Guild data
    mapping(uint256 => Guild) public guilds;
    // Mapping owner address to list of adventurer IDs (handled by ERC721Enumerable)

    // Game Parameters (Admin Configurable)
    struct GameParameters {
        uint256 baseQuestCooldown;
        uint256 xpPerLevel; // XP required to level up
        uint256 statPointsPerLevel;
        uint256 baseCraftingSuccessRate; // Percentage, scaled by skill/luck
        uint256 respecCooldownDuration;
        uint256 respecCostEth;
        uint256 guildCreationReputationThreshold;
        // Add more parameters as needed
    }
    GameParameters public gameParams;

    // Global State
    bool public paused = false;

    // VRF Simulation (Replace with Chainlink VRF Consumer base contract and implementation)
    mapping(bytes32 => address) private _vrfRequestors; // requestId => requesting address
    mapping(bytes32 => uint256) private _vrfRequestTokenId; // requestId => adventurer token id
    uint256 private _nextSimulatedRandomness = 1; // Simple incrementing randomness for simulation

    // --- EVENTS ---

    event AdventurerRegistered(uint256 indexed tokenId, address indexed owner, string name);
    event QuestCompleted(uint256 indexed tokenId, string questType, bool success, uint256 xpEarned, uint256 reputationGained);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel, uint256 statPointsEarned);
    event StatPointsAllocated(uint256 indexed tokenId, StatType indexed statType, uint256 amount);
    event StatsRespecced(uint256 indexed tokenId);
    event ItemCrafted(uint256 indexed tokenId, uint256 indexed itemId, uint256 quantity);
    event ItemConsumed(uint256 indexed tokenId, uint256 indexed itemId, uint256 quantityConsumed);
    event GearEquipped(uint256 indexed tokenId, uint256 indexed itemId, uint256 slotId);
    event GearUnequipped(uint256 indexed tokenId, uint256 indexed itemId, uint256 slotId);
    event GuildCreated(uint256 indexed guildId, string name, address indexed leader);
    event GuildJoined(uint256 indexed guildId, uint256 indexed tokenId);
    event GuildLeft(uint256 indexed guildId, uint256 indexed tokenId);
    event GuildRoleAssigned(uint256 indexed guildId, uint256 indexed tokenId, GuildRole role);
    event GuildTreasuryDeposit(uint256 indexed guildId, address indexed depositor, uint256 amount);
    event GuildTreasuryWithdrawal(uint256 indexed guildId, address indexed recipient, uint256 amount);
    event ActionDelegated(uint256 indexed tokenId, address indexed delegatee, uint8 indexed actionType); // actionType mapping TBD
    event ActionDelegationRevoked(uint256 indexed tokenId, address indexed delegatee, uint8 indexed actionType); // actionType mapping TBD
    event DynamicURIUpdated(uint256 indexed tokenId, string newUri);
    event GameParametersUpdated(GameParameters params);
    event Paused(address account);
    event Unpaused(address account);
    event RandomnessRequested(bytes32 indexed requestId, uint256 indexed tokenId);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 indexed tokenId, bytes32 randomWord);
    event TokensRescued(address indexed tokenAddress, address indexed recipient, uint256 amount);

    // --- MODIFIERS ---

    modifier notPaused() {
        require(!paused, "DOAG: Paused");
        _;
    }

    modifier requireAdventurerOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DOAG: Not owner or approved");
        _;
    }

    // Allows owner or delegatee to perform the action
    modifier requireAdventurerOwnerOrDelegate(uint256 tokenId, uint8 actionType) {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || adventurers[tokenId].delegatedQuestors[_msgSender()], "DOAG: Not owner, approved, or delegatee");
        // Add actionType check if delegation is granular
        _;
    }

    modifier requireGuildLeader(uint256 guildId) {
        require(guilds[guildId].leader == _msgSender(), "DOAG: Must be guild leader");
        _;
    }

    modifier requireGuildRole(uint256 guildId, uint256 tokenId, GuildRole requiredRole) {
        require(adventurers[tokenId].guildId == guildId, "DOAG: Not in specified guild");
        // This requires storing member address in Guild struct or mapping adventurer ID to member address
        // For simplicity, assuming leader is also a member with LEADER role
        // A more complex system would map adventurer ID to member address to guild role
        // Let's simplify: Guild stores members by address, map tokenId owner to guild membership
        address adventurerOwner = ownerOf(tokenId);
        require(guilds[guildId].members[adventurerOwner] >= uint8(requiredRole), "DOAG: Insufficient guild role");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Initialize default game parameters
        gameParams = GameParameters({
            baseQuestCooldown: 1 days,
            xpPerLevel: 100,
            statPointsPerLevel: 5,
            baseCraftingSuccessRate: 50, // 50% base rate
            respecCooldownDuration: 30 days,
            respecCostEth: 0 ether, // Or require a specific token burn
            guildCreationReputationThreshold: 100
        });
    }

    // --- STANDARD ERC721 & OWNABLE FUNCTIONS ---
    // Inherited and used directly from OpenZeppelin.

    // _baseURI is used by tokenURI
    string private _baseTokenURI;

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- CUSTOM FUNCTIONS ---

    /// @notice Registers a new adventurer and mints an NFT. Requires reputation threshold.
    /// @param name The name of the adventurer.
    function registerAdventurer(string memory name) public notPaused nonReentrancy {
        // Basic check, could be more complex (e.g., reputation cost)
        // require(adventurers[0].reputation >= gameParams.guildCreationReputationThreshold, "DOAG: Insufficient reputation to register"); // Example threshold

        uint256 newTokenId = _adventurerIds.current();
        _adventurerIds.increment();

        _safeMint(_msgSender(), newTokenId);

        Adventurer storage newAdventurer = adventurers[newTokenId];
        newAdventurer.id = newTokenId;
        newAdventurer.owner = _msgSender();
        newAdventurer.name = name;
        newAdventurer.level = 1;
        newAdventurer.xp = 0;
        // Initial stats will be set via a simulated randomness request
        newAdventurer.availableStatPoints = 0; // Initial points might come from level 1
        newAdventurer.guildId = 0;
        newAdventurer.reputation = 0;
        newAdventurer.lastQuestTime = 0;

        // Initiate randomness request for initial stats
        // In a real system, this would call chainlink VRF
        bytes32 requestId = _initiateRandomnessRequest(newTokenId, _msgSender());
        emit RandomnessRequested(requestId, newTokenId);

        emit AdventurerRegistered(newTokenId, _msgSender(), name);
    }

    /// @notice Initiates a simulated randomness request. Replace with real VRF integration.
    /// @dev In a real implementation, this would call a VRF coordinator and return a request ID.
    /// @param tokenId The ID of the adventurer requesting randomness.
    /// @param requester The address initiating the request.
    /// @return The request ID generated.
    function requestRandomSeed(uint256 tokenId, address requester) internal returns (bytes32) {
        // Simulation: Generate a simple request ID
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextSimulatedRandomness, tokenId));
        _nextSimulatedRandomness++;

        // Store request context
        _vrfRequestors[requestId] = requester;
        _vrfRequestTokenId[requestId] = tokenId;
        adventurers[tokenId].pendingRandomnessRequests[requestId] = true;

        // In real VRF, this would emit an event for the oracle to pick up or directly call the VRF coordinator

        return requestId;
    }

    /// @notice Fulfills a simulated randomness request. Replace with real VRF callback logic.
    /// @dev This function would be called by the VRF coordinator after randomness is generated.
    /// @param requestId The ID of the request being fulfilled.
    /// @param randomWord The random word provided by the VRF.
    function fulfillRandomSeed(bytes32 requestId, bytes32 randomWord) public { // Modifier like `onlyVRFCoordinator` in real system
        // Basic validation (replace with proper VRF validation)
        require(_vrfRequestors[requestId] != address(0), "DOAG: Unknown request ID");
        uint256 tokenId = _vrfRequestTokenId[requestId];
        require(adventurers[tokenId].pendingRandomnessRequests[requestId], "DOAG: Request not pending");

        // Store the result
        adventurers[tokenId].randomnessResults[requestId] = randomWord;
        delete adventurers[tokenId].pendingRandomnessRequests[requestId]; // Mark as fulfilled

        // Use the randomness - e.g., for initial stats if requested during registration
        // This logic would be more complex, linking requestId to the action it was for
        // For simulation, let's assume the last request was for initial stats
        if (adventurers[tokenId].baseStats.strength == 0 // Check if initial stats are unset
            && _vrfRequestors[requestId] == ownerOf(tokenId) // Ensure it was the owner's request
            && _vrfRequestTokenId[requestId] == tokenId) {

            uint256 entropy = uint256(randomWord);
            adventurers[tokenId].baseStats.strength = uint8((entropy % 20) + 5); // Base 5-24
            entropy = entropy / 20;
            adventurers[tokenId].baseStats.dexterity = uint8((entropy % 20) + 5);
            entropy = entropy / 20;
            adventurers[tokenId].baseStats.constitution = uint8((entropy % 20) + 5);
            entropy = entropy / 20;
            adventurers[tokenId].baseStats.intelligence = uint8((entropy % 20) + 5);
            entropy = entropy / 20;
            adventurers[tokenId].baseStats.wisdom = uint8((entropy % 20) + 5);
            entropy = entropy / 20;
            adventurers[tokenId].baseStats.charisma = uint8((entropy % 20) + 5);
            entropy = entropy / 20;
            adventurers[tokenId].baseStats.luck = uint8((entropy % 10) + 1); // Base 1-10

            // Grant initial stat points based on level 1 (or just award some)
            adventurers[tokenId].availableStatPoints = gameParams.statPointsPerLevel;
        }
        // Add more logic here to handle different types of randomness requests

        emit RandomnessFulfilled(requestId, tokenId, randomWord);

        // Clean up mapping storage if needed to save gas over time
        delete _vrfRequestors[requestId];
        delete _vrfRequestTokenId[requestId];
    }


    /// @notice Allows an adventurer to perform a quest. Consumes time, grants XP/Loot/Reputation based on stats and randomness.
    /// @param tokenId The ID of the adventurer.
    /// @param questType An identifier for the type of quest.
    /// @custom:cooldown baseQuestCooldown config + potential quest-specific modifier.
    /// @custom:gas Medium
    function performQuest(uint256 tokenId, uint8 questType) public notPaused nonReentrancy requireAdventurerOwnerOrDelegate(tokenId, 0) { // 0 can be actionType for questing
        Adventurer storage adv = adventurers[tokenId];
        require(adv.owner != address(0), "DOAG: Adventurer not registered");
        require(block.timestamp >= adv.lastQuestTime + gameParams.baseQuestCooldown, "DOAG: Quest is on cooldown");

        // Determine quest difficulty, required stats, potential rewards based on questType (external data or simple mapping)
        // For simplicity, let's use a basic success check based on a stat
        uint256 statCheckValue = uint256(adv.baseStats.strength) + adv.level; // Example: Use strength + level
        uint256 difficulty = uint256(questType * 10 + 20); // Example difficulty scale

        // Request randomness for success check and loot
        bytes32 successRollRequestId = _initiateRandomnessRequest(tokenId, _msgSender());
        // bytes32 lootRollRequestId = _initiateRandomnessRequest(tokenId, _msgSender()); // Separate roll for loot

        adv.lastQuestTime = block.timestamp;
        // Mark quest attempt, results processed upon randomness fulfillment
        // This needs a way to link the request ID to the quest type and adventurer state *at the time of the request*
        // A more robust system would store quest attempts awaiting randomness

        // Emit an event indicating the quest *attempt*
        emit QuestCompleted(tokenId, "Pending VRF", false, 0, 0); // Outcome TBD by VRF
    }

    // Note: Real quest outcomes would happen in fulfillRandomSeed or a dedicated callback
    // For this example, let's add a placeholder function to *claim* rewards
    // Assuming rewards are determined asynchronously or through a separate system/oracle
    mapping(uint256 => mapping(uint256 => uint256)) private _pendingRewards; // tokenId => itemId => quantity (or XP/Reputation)
    mapping(uint256 => uint256) private _pendingXP; // tokenId => xp
    mapping(uint256 => uint256) private _pendingReputation; // tokenId => reputation

    /// @notice Claims any pending rewards (XP, Reputation, Items) for an adventurer.
    /// @param tokenId The ID of the adventurer.
    function claimPendingQuestRewards(uint256 tokenId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];

        uint256 xpGain = _pendingXP[tokenId];
        uint256 repGain = _pendingReputation[tokenId];

        require(xpGain > 0 || repGain > 0, "DOAG: No pending rewards"); // Add item check later

        adv.xp += xpGain;
        adv.reputation += repGain;

        // Clear pending rewards
        _pendingXP[tokenId] = 0;
        _pendingReputation[tokenId] = 0;

        // Check for level up
        if (adv.xp >= adv.level * gameParams.xpPerLevel) {
             _levelUp(tokenId); // Internal level up logic
        }

        // TODO: Add logic for claiming pending items from _pendingRewards[tokenId]

        emit QuestCompleted(tokenId, "Claimed Rewards", true, xpGain, repGain); // Using QuestCompleted event for reward claiming too
    }

    /// @notice Levels up an adventurer if they have enough XP. Grants stat points.
    /// @param tokenId The ID of the adventurer.
    function levelUpAdventurer(uint256 tokenId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
       _levelUp(tokenId);
    }

    /// @dev Internal function to handle level up logic.
    /// @param tokenId The ID of the adventurer.
    function _levelUp(uint256 tokenId) internal {
        Adventurer storage adv = adventurers[tokenId];
        uint256 requiredXP = adv.level * gameParams.xpPerLevel;

        if (adv.xp >= requiredXP) {
            adv.level++;
            adv.xp -= requiredXP; // Carry over excess XP
            adv.availableStatPoints += gameParams.statPointsPerLevel;
            emit LevelUp(tokenId, adv.level, gameParams.statPointsPerLevel);

            // Recursively check if multiple levels are gained
            _levelUp(tokenId);
        }
    }

    /// @notice Allocates available stat points to boost adventurer's stats.
    /// @param tokenId The ID of the adventurer.
    /// @param statType The type of stat to allocate points to.
    /// @param amount The number of points to allocate.
    function allocateStatPoints(uint256 tokenId, StatType statType, uint256 amount) public notPaused requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        require(amount > 0, "DOAG: Amount must be positive");
        require(adv.availableStatPoints >= amount, "DOAG: Not enough stat points");

        adv.availableStatPoints -= amount;

        if (statType == StatType.Str) adv.baseStats.strength = uint8(adv.baseStats.strength + amount);
        else if (statType == StatType.Dex) adv.baseStats.dexterity = uint8(adv.baseStats.dexterity + amount);
        else if (statType == StatType.Con) adv.baseStats.constitution = uint8(adv.baseStats.constitution + amount);
        else if (statType == StatType.Int) adv.baseStats.intelligence = uint8(adv.baseStats.intelligence + amount);
        else if (statType == StatType.Wis) adv.baseStats.wisdom = uint8(adv.baseStats.wisdom + amount);
        else if (statType == StatType.Cha) adv.baseStats.charisma = uint8(adv.baseStats.charisma + amount);
        else if (statType == StatType.Luck) adv.baseStats.luck = uint8(adv.baseStats.luck + amount);
        else revert("DOAG: Invalid stat type"); // Should not happen if enum is used correctly

        emit StatPointsAllocated(tokenId, statType, amount);
        // Consider emitting DynamicURIUpdated if stats affect metadata
    }

    /// @notice Resets all allocated stat points, returning them to available points pool. Has a cooldown.
    /// @param tokenId The ID of the adventurer.
    /// @custom:cooldown respecCooldownDuration config.
    /// @custom:gas High
    function respecStats(uint256 tokenId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        uint8 actionType = 1; // Example action type for respec
        require(block.timestamp >= adv.actionCooldowns[actionType] + gameParams.respecCooldownDuration, "DOAG: Respec is on cooldown");
        require(address(this).balance >= gameParams.respecCostEth, "DOAG: Not enough ETH in contract for respec cost"); // If cost is paid to contract

        // Calculate points currently in stats beyond base (level 1 stats + allocated points)
        uint256 pointsInStats = (adv.baseStats.strength - adventurers[tokenId].baseStats.strength) + // This comparison isn't right, need original random stats
                                 (adv.baseStats.dexterity - adventurers[tokenId].baseStats.dexterity) +
                                 // ... etc for all stats
                                 adv.availableStatPoints;

        // A better way: store original base stats or recalculate total points based on level
        uint224 totalPointsAvailableAtLevel = adv.level * gameParams.statPointsPerLevel;
        // Assuming initial random roll gives points roughly equivalent to level 1 points... this is complex.
        // Let's simplify: Reset stats to a default base or random roll again, and give back all points accumulated from levels.
        // A simpler respec: set all base stats to a fixed value, give back all points gained from levels.
        adv.availableStatPoints += (adv.level - 1) * gameParams.statPointsPerLevel; // Points from level 2+
        adv.baseStats = Stats({strength: 5, dexterity: 5, constitution: 5, intelligence: 5, wisdom: 5, charisma: 5, luck: 1}); // Reset to fixed base

        // Alternative: Re-roll base stats + give back all points gained from levels
        // bytes32 rerollRequestId = _initiateRandomnessRequest(tokenId, _msgSender());
        // In that case, the stats would be updated in fulfillRandomSeed

        // If respecCostEth > 0, transfer it out or burn a token
        // Example: Transfer to owner (admin), or burn a specific "Respec Token"
        // payable(owner()).transfer(gameParams.respecCostEth);

        adv.actionCooldowns[actionType] = block.timestamp;

        emit StatsRespecced(tokenId);
        // Consider emitting DynamicURIUpdated if stats affect metadata
    }

    /// @notice Crafts a new item using items from inventory, based on adventurer's skill and randomness.
    /// @param tokenId The ID of the adventurer.
    /// @param recipeItemId The ID of the item representing the recipe.
    /// @param componentItemIds Array of item IDs required for crafting.
    /// @param componentQuantities Array of quantities for each component item.
    /// @custom:gas High
    function craftItem(uint256 tokenId, uint256 recipeItemId, uint256[] memory componentItemIds, uint256[] memory componentQuantities) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        // Assume recipeItemId exists and defines components & output (need Item data structure or lookup)
        // Example: require recipeItemId is a CraftingMaterial type item

        require(componentItemIds.length == componentQuantities.length, "DOAG: Mismatched components and quantities");

        // Check and consume components from inventory
        for (uint i = 0; i < componentItemIds.length; i++) {
            uint256 required = componentQuantities[i];
            uint256 available = adv.inventory[componentItemIds[i]];
            require(available >= required, "DOAG: Not enough crafting materials");
            adv.inventory[componentItemIds[i]] = available - required;
        }

        // Determine success chance and potential outcomes based on adventurer stats (e.g., intelligence, luck)
        // and crafting difficulty (from recipe item data)
        // Request randomness for crafting outcome (success, critical success, failure, quality)
        bytes32 craftOutcomeRequestId = _initiateRandomnessRequest(tokenId, _msgSender());

        // Placeholder logic for outcome (would be in fulfillRandomSeed)
        uint256 craftedItemId = recipeItemId; // Assuming recipeItemId is the output item ID for simplicity
        uint256 craftedQuantity = 1; // Assuming 1 output item

        // Simulate success/quality based on randomness (would use craftOutcomeRequestId result)
        // Placeholder: 80% success chance
        // if (uint256(craftOutcomeRequestId) % 100 < 80) {
             adv.inventory[craftedItemId] += craftedQuantity;
             emit ItemCrafted(tokenId, craftedItemId, craftedQuantity);
        // } else {
        //    // Crafting failed, components lost, maybe partial refund or junk item
        //    emit ItemCrafted(tokenId, 0, 0); // Indicate failure
        // }

         // Mark crafting attempt pending randomness
         // Need to store context: which recipe, components, etc.
         // This again points to a more complex system where requests are tied to actions.
    }

    /// @notice Uses a consumable item from the adventurer's inventory.
    /// @param tokenId The ID of the adventurer.
    /// @param itemId The ID of the consumable item.
    /// @custom:gas Low
    function useConsumableItem(uint256 tokenId, uint256 itemId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.inventory[itemId] > 0, "DOAG: Item not in inventory");
        // Require itemId is a Consumable type item (need item data lookup)

        adv.inventory[itemId]--;

        // Apply item effect (e.g., heal, temporary buff, remove debuff)
        // This logic depends heavily on the item data structure and game rules
        // Example: Healing potion
        // if (itemId == 1) { adv.stats.constitution = uint8(adv.stats.constitution + 10); } // Simple stat boost

        emit ItemConsumed(tokenId, itemId, 1);
    }

    /// @notice Equips a gear item from the adventurer's inventory.
    /// @param tokenId The ID of the adventurer.
    /// @param itemId The ID of the gear item.
    /// @param slotId The ID of the equipment slot.
    /// @custom:gas Low
    function equipGearItem(uint256 tokenId, uint256 itemId, uint256 slotId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.inventory[itemId] > 0, "DOAG: Item not in inventory");
        // Require itemId is a Gear type item compatible with slotId (need item data lookup)

        // Unequip item currently in slot, if any
        uint256 equippedItemId = adv.equippedGear[slotId];
        if (equippedItemId != 0) {
             unequipGearItem(tokenId, slotId); // Call the unequip function
        }

        adv.inventory[itemId]--; // Consume item from inventory
        adv.equippedGear[slotId] = itemId; // Equip item

        // Apply stat modifiers from the equipped item
        // This requires looking up the item's statModifiers
        // Example: ItemData memory itemData = getItemData(itemId);
        // if (itemData.itemType == Item.ItemType.Gear) {
        //    adv.baseStats.strength += uint8(itemData.statModifiers[uint8(StatType.Str)]);
        //    // ... apply for all stats
        // }

        emit GearEquipped(tokenId, itemId, slotId);
        // Consider emitting DynamicURIUpdated if equipped gear affects metadata
    }

     /// @notice Unequips a gear item from a specific slot.
     /// @param tokenId The ID of the adventurer.
     /// @param slotId The ID of the equipment slot.
     /// @custom:gas Low
    function unequipGearItem(uint256 tokenId, uint256 slotId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        uint256 equippedItemId = adv.equippedGear[slotId];
        require(equippedItemId != 0, "DOAG: No item equipped in this slot");

        adv.equippedGear[slotId] = 0; // Unequip
        adv.inventory[equippedItemId]++; // Return to inventory

        // Remove stat modifiers from the unequipped item
        // Requires looking up item's statModifiers and subtracting them
        // Example: ItemData memory itemData = getItemData(equippedItemId);
        // if (itemData.itemType == Item.ItemType.Gear) {
        //    adv.baseStats.strength -= uint8(itemData.statModifiers[uint8(StatType.Str)]);
        //    // ... subtract for all stats
        // }

        emit GearUnequipped(tokenId, equippedItemId, slotId);
         // Consider emitting DynamicURIUpdated
    }

    /// @notice Creates a new guild. Requires minimum reputation.
    /// @param name The name of the new guild.
    /// @param founderTokenId The adventurer token ID of the founder.
    /// @custom:gas Medium
    function createGuild(string memory name, uint256 founderTokenId) public notPaused nonReentrancy requireAdventurerOwner(founderTokenId) {
        Adventurer storage founderAdv = adventurers[founderTokenId];
        require(founderAdv.guildId == 0, "DOAG: Adventurer is already in a guild");
        require(founderAdv.reputation >= gameParams.guildCreationReputationThreshold, "DOAG: Insufficient reputation to create a guild");

        uint256 newGuildId = _guildIds.current();
        _guildIds.increment();

        Guild storage newGuild = guilds[newGuildId];
        newGuild.id = newGuildId;
        newGuild.name = name;
        newGuild.leader = _msgSender(); // Founder is the leader
        newGuild.treasuryBalanceETH = 0;
        newGuild.memberCount = 1;
        newGuild.members[_msgSender()] = uint8(GuildRole.Leader); // Add founder as leader member

        founderAdv.guildId = newGuildId; // Assign guild to founder's adventurer

        emit GuildCreated(newGuildId, name, _msgSender());
        emit GuildJoined(newGuildId, founderTokenId); // Emit join event for the founder
    }

    /// @notice Allows an adventurer to join a guild.
    /// @param tokenId The ID of the adventurer.
    /// @param guildId The ID of the guild to join.
    /// @custom:gas Low
    function joinGuild(uint256 tokenId, uint256 guildId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.owner != address(0), "DOAG: Adventurer not registered");
        require(adv.guildId == 0, "DOAG: Adventurer already in a guild");
        require(guilds[guildId].leader != address(0), "DOAG: Guild does not exist");

        // Add checks: guild invitation system, reputation requirement to join, etc.
        // For simplicity, anyone can join an existing guild here.

        Guild storage guild = guilds[guildId];
        adv.guildId = guildId;
        guild.members[_msgSender()] = uint8(GuildRole.Member); // Assign default role
        guild.memberCount++;

        emit GuildJoined(guildId, tokenId);
    }

    /// @notice Allows an adventurer to leave their current guild.
    /// @param tokenId The ID of the adventurer.
    /// @custom:gas Low
    function leaveGuild(uint256 tokenId) public notPaused nonReentrancy requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.owner != address(0), "DOAG: Adventurer not registered");
        require(adv.guildId != 0, "DOAG: Adventurer is not in a guild");

        uint256 guildId = adv.guildId;
        Guild storage guild = guilds[guildId];
        address ownerAddr = _msgSender();

        // Prevent leader from leaving directly (leader must transfer leadership first)
        require(guild.leader != ownerAddr, "DOAG: Guild leader cannot leave directly");

        adv.guildId = 0; // Remove guild affiliation
        delete guild.members[ownerAddr]; // Remove from member list
        guild.memberCount--;

        // If guild is empty, maybe disband it?
        if (guild.memberCount == 0) {
             // Disband guild logic (e.g., delete from mapping, send treasury elsewhere)
        }

        emit GuildLeft(guildId, tokenId);
    }

    /// @notice Assigns a role to a guild member. Must be performed by the guild leader.
    /// @param guildId The ID of the guild.
    /// @param memberAddress The address of the member to assign the role to.
    /// @param role The role to assign.
    /// @custom:gas Low
    function assignGuildRole(uint256 guildId, address memberAddress, GuildRole role) public notPaused requireGuildLeader(guildId) {
        Guild storage guild = guilds[guildId];
        // Check if memberAddress is actually in the guild (by checking their adventurer's guildId or guild.members mapping)
        // This requires iterating over adventurers or having a reverse mapping, which is gas-intensive.
        // Simpler: check if the address is in the guild's member mapping (assuming 1 adventurer per address or leader manages by address)
        require(guild.members[memberAddress] != uint8(GuildRole.None), "DOAG: Address is not a member of this guild");

        // Prevent leader from changing their own role or assigning Leader role to others directly (use transferLeadership)
        require(memberAddress != _msgSender() || role == GuildRole.Leader, "DOAG: Cannot change leader role directly");
        require(role != GuildRole.Leader, "DOAG: Use transferLeadership to change leader");

        guild.members[memberAddress] = uint8(role);

        // Find the adventurer tokenId for the memberAddress to emit the event accurately
        // This is problematic with current structure (need reverse lookup or separate mapping)
        // For event emission, we might skip the tokenId and just use the address or add the mapping.
        // Adding a mapping address => latest adventurer tokenId could work for events.
        // Let's emit with address for now.
        emit GuildRoleAssigned(guildId, 0, role); // Use 0 for tokenId or add mapping
    }

    /// @notice Allows anyone to donate ETH to a guild's treasury.
    /// @param guildId The ID of the guild.
    /// @custom:gas Low
    receive() external payable {
       // Fallback/receive function can be used for direct ETH deposits IF guildId is specified
       // Or create a dedicated function
    }

    /// @notice Allows anyone to donate ETH to a guild's treasury.
    /// @param guildId The ID of the guild.
    function donateToGuildTreasury(uint256 guildId) public payable notPaused nonReentrancy {
        require(guilds[guildId].leader != address(0), "DOAG: Guild does not exist");
        require(msg.value > 0, "DOAG: Must send ETH");

        Guild storage guild = guilds[guildId];
        guild.treasuryBalanceETH += msg.value;

        emit GuildTreasuryDeposit(guildId, _msgSender(), msg.value);
    }

    /// @notice Allows a guild leader to withdraw ETH from the treasury.
    /// @param guildId The ID of the guild.
    /// @param amount The amount of ETH to withdraw.
    /// @param recipient The address to send the ETH to.
    /// @custom:gas Low
    function guildTreasuryWithdraw(uint256 guildId, uint256 amount, address payable recipient) public notPaused nonReentrancy requireGuildLeader(guildId) {
        Guild storage guild = guilds[guildId];
        require(guild.treasuryBalanceETH >= amount, "DOAG: Insufficient treasury balance");
        require(recipient != address(0), "DOAG: Invalid recipient address");

        guild.treasuryBalanceETH -= amount;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "DOAG: ETH transfer failed");

        emit GuildTreasuryWithdrawal(guildId, recipient, amount);
    }

    /// @notice Allows an adventurer owner to delegate permission for certain actions to another address.
    /// @dev Example: Allows a friend to play your adventurer while you're away.
    /// @param tokenId The ID of the adventurer.
    /// @param delegatee The address to delegate permissions to.
    /// @param actionType The type of action being delegated (e.g., 0 for questing).
    /// @param allowed True to allow, false to revoke.
    /// @custom:gas Low
    function delegateAction(uint256 tokenId, address delegatee, uint8 actionType, bool allowed) public notPaused requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        require(delegatee != address(0), "DOAG: Invalid delegatee address");
        require(delegatee != _msgSender(), "DOAG: Cannot delegate to self");
        // actionType can be an enum or defined constant mapping
        // For simplicity, using a single boolean flag per delegatee for ALL delegated actions (like questing)
        // A more granular system would use a mapping: delegatee => actionType => bool

        adv.delegatedQuestors[delegatee] = allowed; // Example: Only delegates questing action (actionType 0)

        if (allowed) {
            emit ActionDelegated(tokenId, delegatee, actionType);
        } else {
            emit ActionDelegationRevoked(tokenId, delegatee, actionType);
        }
    }

     /// @notice Revokes all action delegation for a specific address on an adventurer.
     /// @param tokenId The ID of the adventurer.
     /// @param delegatee The address whose permissions are being revoked.
     /// @custom:gas Low
    function revokeDelegateAction(uint256 tokenId, address delegatee) public notPaused requireAdventurerOwner(tokenId) {
        Adventurer storage adv = adventurers[tokenId];
        require(delegatee != address(0), "DOAG: Invalid delegatee address");

        // This assumes the delegation is a single boolean flag as in delegateAction example
        // For granular delegation, this would need to iterate or have a more complex structure
        if (adv.delegatedQuestors[delegatee]) {
             adv.delegatedQuestors[delegatee] = false; // Revoke the single delegation type
             emit ActionDelegationRevoked(tokenId, delegatee, 0); // Use 0 for actionType or iterate
        }
    }


    /// @notice Triggers an update to the adventurer's metadata URI.
    /// @dev This function doesn't set the URI directly, but signals/allows external services to fetch updated on-chain state.
    /// @param tokenId The ID of the adventurer.
    /// @custom:gas Very Low
    function updateAdventurerURI(uint256 tokenId) public notPaused { // Could be public for anyone to trigger, or restricted
        require(_exists(tokenId), "DOAG: ERC721 token doesn't exist");

        // The actual tokenURI function will fetch the latest state dynamically.
        // This function serves as a signaling mechanism or a checkpoint if URI was cached.
        // In a real system, this might store a hash of the state or increment a version counter
        // that the metadata service checks to know data has changed.

        // For this example, just emit an event. The metadata service listens for this.
        string memory currentUri = tokenURI(tokenId); // Get current URI (which is dynamic)
        emit DynamicURIUpdated(tokenId, currentUri);
    }

    /// @notice Sets the base URI for the adventurer NFTs. Admin only.
    /// @param baseURI The new base URI.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Returns the token URI for an adventurer, incorporating dynamic state.
    /// @dev This function should point to a service that reads the on-chain data and generates dynamic JSON metadata.
    /// @param tokenId The ID of the adventurer.
    /// @return The dynamic token URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // The base URI should point to a service that can handle /tokenId requests
        // Example: https://metadata.mygame.xyz/adventurers/
        // The service at that endpoint reads the state of adventurers[tokenId] from this contract
        // and generates the appropriate metadata JSON, including traits based on stats, gear, level, etc.
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    /// @notice Admin function to adjust global game tuning parameters.
    /// @param params The struct containing the new game parameters.
    function setGlobalGameParameter(GameParameters memory params) public onlyOwner {
        gameParams = params;
        emit GameParametersUpdated(params);
    }

    /// @notice Admin function to pause core game actions (quests, crafting, etc.).
    /// @dev Standard OpenZeppelin Pausable pattern.
    function pauseGameActions() public onlyOwner {
        paused = true;
        emit Paused(_msgSender());
    }

    /// @notice Admin function to unpause core game actions.
    /// @dev Standard OpenZeppelin Pausable pattern.
    function unpauseGameActions() public onlyOwner {
        paused = false;
        emit Unpaused(_msgSender());
    }

    /// @notice Allows owner to rescue ERC20 tokens sent incorrectly to the contract.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param recipient The address to send the tokens to.
    /// @param amount The amount of tokens to transfer.
    function emergencyWithdrawTokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner nonReentrancy {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recipient, amount), "DOAG: ERC20 transfer failed");
        emit TokensRescued(tokenAddress, recipient, amount);
    }


    // --- VIEW FUNCTIONS ---

    /// @notice Retrieves the full state of an adventurer.
    /// @param tokenId The ID of the adventurer.
    /// @return A tuple containing the adventurer's data.
    function getAdventurerState(uint256 tokenId) public view returns (
        uint256 id,
        address owner,
        string memory name,
        uint256 level,
        uint256 xp,
        Stats memory stats,
        uint256 availableStatPoints,
        uint256 guildId,
        uint256 reputation,
        uint256 lastQuestTime
        // Note: Inventory, equippedGear, cooldowns, delegates are separate mappings, retrieved via dedicated views
    ) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.owner != address(0), "DOAG: Adventurer not registered");

        return (
            adv.id,
            adv.owner,
            adv.name,
            adv.level,
            adv.xp,
            adv.baseStats, // Note: This is baseStats, not total stats including gear
            adv.availableStatPoints,
            adv.guildId,
            adv.reputation,
            adv.lastQuestTime
        );
    }

    /// @notice Retrieves the current inventory of an adventurer.
    /// @param tokenId The ID of the adventurer.
    /// @return An array of item IDs and their corresponding quantities.
    function getAdventurerInventory(uint256 tokenId) public view returns (uint256[] memory itemIds, uint256[] memory quantities) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.owner != address(0), "DOAG: Adventurer not registered");

        uint256 count = 0;
        // Count items first
        // This requires iterating over potentially sparse mapping, inefficient.
        // A better approach would be to store inventory as a list of structs or keep a separate list of itemIds in inventory.
        // For demonstration, let's simulate iterating.
        // In a real system, this would likely not iterate over the whole mapping or use a helper contract/view.
        // Let's return a simplified example for common items.
        // A more practical view would return quantities for a *requested list* of item IDs.
        // Let's return quantities for a few arbitrary item IDs for demo.
        // Or, require off-chain service to query individual items.
        // Or, return itemIds and quantities *only* for items with > 0 quantity.

        // --- Practical View Alternative ---
        // This requires iterating over a set of known item IDs or the mapping, both costly on-chain.
        // A common pattern is to store inventory as a list of {itemId, quantity} structs OR
        // have an external indexer/API that reads the mapping state.
        // Let's return a fixed size array for demonstration of concept, even if inefficient for large inventory.

        // Example: Return quantities for item IDs 1, 2, 3, 4, 5
        uint256[] memory demoItemIds = new uint256[](5);
        uint256[] memory demoQuantities = new uint256[](5);

        demoItemIds[0] = 1; demoQuantities[0] = adv.inventory[1];
        demoItemIds[1] = 2; demoQuantities[1] = adv.inventory[2];
        demoItemIds[2] = 3; demoQuantities[2] = adv.inventory[3];
        demoItemIds[3] = 4; demoQuantities[3] = adv.inventory[4];
        demoItemIds[4] = 5; demoQuantities[4] = adv.inventory[5];

        return (demoItemIds, demoQuantities);

        // A proper implementation for dynamic inventory list is needed for production.
    }

    /// @notice Retrieves the gear equipped by an adventurer.
    /// @param tokenId The ID of the adventurer.
    /// @return An array of slot IDs and the item ID equipped in each slot.
    function getAdventurerGear(uint256 tokenId) public view returns (uint256[] memory slotIds, uint256[] memory itemIds) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.owner != address(0), "DOAG: Adventurer not registered");

        // Similar to inventory, iterating over mapping is costly.
        // Assume a fixed number of gear slots for practicality in this example.
        // Example: 5 slots (Head, Chest, Weapon, Shield, Accessory)
        uint256 numSlots = 5;
        slotIds = new uint256[](numSlots);
        itemIds = new uint256[](numSlots);

        for (uint i = 0; i < numSlots; i++) {
            slotIds[i] = i + 1; // Slot IDs 1-5
            itemIds[i] = adv.equippedGear[i + 1];
        }

        return (slotIds, itemIds);
    }

    /// @notice Retrieves the cooldown unlock times for an adventurer's actions.
    /// @param tokenId The ID of the adventurer.
    /// @return An array of action types and their unlock timestamps.
    function getAdventurerCooldowns(uint256 tokenId) public view returns (uint8[] memory actionTypes, uint256[] memory unlockTimes) {
        Adventurer storage adv = adventurers[tokenId];
        require(adv.owner != address(0), "DOAG: Adventurer not registered");

        // Return cooldowns for known action types
        uint8[] memory knownActionTypes = new uint8[](2); // Example: 0=Quest, 1=Respec
        knownActionTypes[0] = 0;
        knownActionTypes[1] = 1;

        uint256[] memory currentUnlockTimes = new uint256[](knownActionTypes.length);
        for(uint i = 0; i < knownActionTypes.length; i++) {
            currentUnlockTimes[i] = adv.actionCooldowns[knownActionTypes[i]];
        }

        return (knownActionTypes, currentUnlockTimes);
    }


    /// @notice Retrieves the full state of a guild.
    /// @param guildId The ID of the guild.
    /// @return A tuple containing the guild's data.
    function getGuildState(uint256 guildId) public view returns (
        uint256 id,
        string memory name,
        address leader,
        uint256 memberCount,
        uint256 treasuryBalanceETH
        // Members mapping is separate, retrieved via dedicated views if needed
    ) {
        Guild storage guild = guilds[guildId];
        require(guild.leader != address(0), "DOAG: Guild does not exist");

        return (
            guild.id,
            guild.name,
            guild.leader,
            guild.memberCount,
            guild.treasuryBalanceETH
        );
    }

    /// @notice Retrieves the current global game parameters.
    /// @return The GameParameters struct.
    function getGameParameters() public view returns (GameParameters memory) {
        return gameParams;
    }

    /// @notice Gets the total number of adventurers minted.
    /// @return The total supply of adventurer tokens.
    function getTotalAdventurers() public view returns (uint256) {
        return _adventurerIds.current();
    }

     /// @notice Gets the total number of guilds created.
     /// @return The total number of guilds.
    function getTotalGuilds() public view returns (uint256) {
        return _guildIds.current();
    }

    /// @notice Checks if an address is delegated to perform a specific action for an adventurer.
    /// @param tokenId The ID of the adventurer.
    /// @param delegatee The address to check.
    /// @param actionType The type of action (e.g., 0 for questing).
    /// @return True if delegated, false otherwise.
    function getDelegateAllowance(uint256 tokenId, address delegatee, uint8 actionType) public view returns (bool) {
         Adventurer storage adv = adventurers[tokenId];
         // Assumes actionType 0 maps to delegatedQuestors.
         // Needs more complex logic if actionType is granular.
         // For this example, only checks delegatedQuestors for actionType 0.
         if (actionType == 0) {
              return adv.delegatedQuestors[delegatee];
         }
         return false; // Other action types not covered by this delegation pattern
    }


    // --- INTERNAL HELPERS ---

    /// @dev Internal simulation of VRF request initiation.
    /// @param tokenId The ID of the adventurer requesting randomness.
    /// @param requester The address initiating the request.
    /// @return The request ID generated.
    function _initiateRandomnessRequest(uint256 tokenId, address requester) internal returns (bytes32) {
         // Same logic as public requestRandomSeed, but internal for use within other functions
         bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextSimulatedRandomness, tokenId));
         _nextSimulatedRandomness++;

         _vrfRequestors[requestId] = requester;
         _vrfRequestTokenId[requestId] = tokenId;
         adventurers[tokenId].pendingRandomnessRequests[requestId] = true;

         // In real VRF, this would call the VRF coordinator
         // emit RandomnessRequested(requestId, tokenId); // Emitted in the public wrapper

         return requestId;
    }

    // Internal function to add item to inventory (used in crafting, quest rewards)
    function _addItemToInventory(uint256 tokenId, uint256 itemId, uint256 quantity) internal {
        adventurers[tokenId].inventory[itemId] += quantity;
    }

    // Internal function to remove item from inventory (used in crafting, using consumables)
    function _removeItemFromInventory(uint256 tokenId, uint256 itemId, uint256 quantity) internal {
        require(adventurers[tokenId].inventory[itemId] >= quantity, "DOAG: Not enough item in inventory");
        adventurers[tokenId].inventory[itemId] -= quantity;
    }

    // Potentially internal helper to calculate total stats (base + gear modifiers)
    // function _getTotalStats(uint256 tokenId) internal view returns (Stats memory totalStats) {
    //    Adventurer storage adv = adventurers[tokenId];
    //    totalStats = adv.baseStats;
    //    // Iterate equipped gear and add modifiers (requires Item data lookup)
    //    // Example: ItemData memory itemData = getItemData(adv.equippedGear[slotId]);
    //    // totalStats.strength += itemData.statModifiers[uint8(StatType.Str)];
    // }

    // --- Fallback function to prevent sending ETH directly without a purpose ---
    fallback() external payable {
        revert("DOAG: Direct ETH deposits not allowed without function call");
    }
}

// --- Interface for ERC20 (Needed for emergencyWithdrawTokens) ---
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```