Okay, here is a Solidity smart contract concept called "ChronicleBadge". It's an ERC-721 token designed as a Soulbound Token (SBT) that represents a user's on-chain progress and reputation within a specific ecosystem. The token itself is dynamic, its metadata (representing visual traits or level) changes based on accrued Experience Points (XP). Users can earn XP by completing on-chain "Quests" or by staking specific tokens associated with their badge.

It incorporates concepts like:
1.  **Soulbound Tokens (SBT):** Non-transferable NFTs.
2.  **Dynamic NFTs:** Metadata changes based on on-chain state (XP/Level).
3.  **On-Chain Progression/Reputation:** XP system recorded and managed in the contract.
4.  **On-Chain Quests:** Defined tasks/achievements that grant XP.
5.  **Staking for Progression:** Staking other tokens tied to the Badge yields XP over time.
6.  **Role-Based Access Control (Simplified):** Using `onlyOwner` for administrative tasks.
7.  **Modular Design:** Structs for Quests and Staking Pools.
8.  **Events:** To track key activities.

**Outline & Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleBadge
 * @notice A Soulbound Token (SBT) representing user progression and reputation.
 * The token is non-transferable and its visual traits/level are dynamic,
 * changing based on accumulated Experience Points (XP). XP can be earned
 * by completing defined quests or staking tokens.
 */
contract ChronicleBadge {

    // --- Outline ---
    // 1. Custom Errors
    // 2. Events
    // 3. Structs
    // 4. State Variables (Core ERC721 properties are assumed/simplified for demonstration)
    // 5. Modifiers
    // 6. Constructor
    // 7. Core ERC721 Overrides (Simplified/Focused on SBT & Dynamic aspects)
    // 8. XP and Level Management
    // 9. Metadata Management
    // 10. Quest System (Admin & User interactions)
    // 11. Staking System for XP (Admin & User interactions)
    // 12. Admin Functions
    // 13. View Functions
    // 14. Internal Helper Functions

    // --- Function Summary ---

    // Core ERC721 Overrides (Simplified/Focused)
    // ownerOf(tokenId): Standard ERC721 - Returns owner of a badge.
    // tokenURI(tokenId): Standard ERC721 - Returns dynamic metadata URI based on badge state (XP).
    // supportsInterface(interfaceId): Standard ERC165 - Indicates supported interfaces (ERC721, ERC165).
    // _beforeTokenTransfer(from, to, tokenId, batchSize): Internal hook - Prevents transfers (SBT logic).

    // XP and Level Management
    // _addXPInternal(tokenId, amount): Internal - Adds XP to a badge, emits event.
    // getBadgeXP(tokenId): View - Returns current XP for a badge.
    // getBadgeLevel(tokenId): View - Calculates and returns level based on current XP.
    // setLevelXPThreshold(level, xpThreshold): Admin - Defines XP required to reach a specific level.

    // Metadata Management
    // setMetadataBaseURI(baseURI): Admin - Sets the base URI for dynamic metadata.

    // Quest System
    // defineQuest(questId, xpReward, isActive, requiredXP): Admin - Defines or updates a quest.
    // toggleQuestActiveStatus(questId, isActive): Admin - Activates or deactivates a quest.
    // completeQuest(tokenId, questId): Admin - Marks a quest as completed for a user, grants XP. (Admin-triggered for controlled progression)
    // getQuestDetails(questId): View - Returns details of a specific quest.
    // getUserCompletedQuests(tokenId): View - Returns list of quest IDs completed by a badge.

    // Staking System for XP
    // defineStakingPool(poolId, stakedToken, xpRatePerSecond, isActive): Admin - Defines or updates a staking pool.
    // toggleStakingPoolActiveStatus(poolId, isActive): Admin - Activates or deactivates a staking pool.
    // stakeTokensForXP(poolId, amount): User - Stakes tokens into a pool associated with their badge.
    // claimStakedTokens(poolId): User - Unstakes tokens from a pool.
    // claimAccruedXPFromStaking(poolId): User - Claims earned XP from staking in a pool.
    // withdrawEmergency(poolId, amount): Admin - Emergency withdrawal from a staking pool (use with caution).
    // getStakingPoolDetails(poolId): View - Returns details of a specific staking pool.
    // getUserStakedAmount(tokenId, poolId): View - Returns amount staked by a badge in a pool.
    // getAccruedXPFromStaking(tokenId, poolId): View - Calculates potential XP claim from staking.

    // Admin Functions (Ownable pattern)
    // transferOwnership(newOwner): Admin - Transfers contract ownership.
    // renounceOwnership(): Admin - Renounces contract ownership (makes it non-ownable).

    // User Interactions
    // mintBadge(): User - Mints a new, unique ChronicleBadge (only one per address).

    // --- Total Functions: 25 --- (Constructor + 24 listed above)
}
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking

// --- Custom Errors ---
error BadgeAlreadyMinted(address owner);
error BadgeDoesNotExist(uint256 tokenId);
error OnlyBadgeOwnerCanPerform();
error QuestNotFound(string questId);
error QuestNotActive(string questId);
error QuestAlreadyCompleted(uint256 tokenId, string questId);
error StakingPoolNotFound(string poolId);
error StakingPoolNotActive(string poolId);
error InsufficientStakeAmount();
error InsufficientStakedBalance();
error XPThresholdAlreadyDefined(uint256 level);
error InvalidLevel();
error InvalidXPThreshold();
error MetadataURINotSet();


/**
 * @title ChronicleBadge
 * @notice A Soulbound Token (SBT) representing user progression and reputation.
 * The token is non-transferable and its visual traits/level are dynamic,
 * changing based on accumulated Experience Points (XP). XP can be earned
 * by completing defined quests or staking tokens.
 *
 * Note: This contract assumes a minimal ERC721 implementation underneath or
 * relies on inheriting a full ERC721 base for standard functions like
 * balanceOf, getApproved, setApprovalForAll, etc.
 * The focus here is on the SBT, Dynamic, XP, Quest, and Staking features.
 */
contract ChronicleBadge is ERC165, Ownable, IERC721, IERC721Metadata {

    // --- Events ---
    event BadgeMinted(address indexed owner, uint256 indexed tokenId);
    event XPIncreased(uint256 indexed tokenId, uint256 oldXP, uint256 newXP);
    event LevelIncreased(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event MetadataBaseURISet(string baseURI);
    event QuestDefined(string indexed questId, uint256 xpReward, bool isActive, uint256 requiredXP);
    event QuestActiveStatusToggled(string indexed questId, bool isActive);
    event QuestCompleted(uint256 indexed tokenId, string indexed questId, uint256 xpEarned);
    event StakingPoolDefined(string indexed poolId, address indexed stakedToken, uint256 xpRatePerSecond, bool isActive);
    event StakingPoolActiveStatusToggled(string indexed poolId, bool isActive);
    event TokensStakedForXP(uint256 indexed tokenId, string indexed poolId, uint256 amount);
    event StakedTokensClaimed(uint256 indexed tokenId, string indexed poolId, uint256 amount);
    event AccruedXPClaimed(uint256 indexed tokenId, string indexed poolId, uint256 xpAmount);
    event EmergencyWithdrawal(string indexed poolId, address indexed recipient, uint256 amount);
    event LevelXPThresholdSet(uint256 indexed level, uint256 xpThreshold);

    // --- Structs ---
    struct Quest {
        uint256 xpReward;
        bool isActive;
        uint256 requiredXP; // Optional: Minimum XP badge needs to attempt/complete quest
    }

    struct StakingPool {
        IERC20 stakedToken;
        uint256 xpRatePerSecond; // How much XP per second per staked token
        bool isActive;
        uint256 totalStaked; // Total tokens staked in this pool across all badges
    }

    // --- State Variables ---

    // Basic ERC721 state (simplified - typically handled by base contract)
    mapping(uint256 => address) private _owners; // TokenId to Owner address
    mapping(address => uint256) private _balances; // Owner address to Balance (should be 1 for SBT)
    string public name;
    string public symbol;
    uint256 private _badgeCounter; // Counter for unique token IDs

    // ChronicleBadge specific state
    mapping(uint256 => uint256) private _badgeXP; // TokenId to Experience Points
    mapping(uint256 => mapping(string => bool)) private _userCompletedQuests; // tokenId => questId => completed
    mapping(string => Quest) private _quests; // questId => Quest details
    string[] private _questIds; // Keep track of defined quest IDs (for listing)

    mapping(string => StakingPool) private _stakingPools; // poolId => StakingPool details
    string[] private _stakingPoolIds; // Keep track of defined pool IDs (for listing)
    mapping(uint256 => mapping(string => uint256)) private _userStakes; // tokenId => poolId => staked amount
    mapping(uint256 => mapping(string => uint256)) private _lastStakingXPClaimTime; // tokenId => poolId => timestamp

    string private _metadataBaseURI; // Base URI for token metadata JSON
    mapping(uint256 => uint256) private _levelXPThresholds; // level => minimum XP to reach level
    uint256 private _maxLevelDefined; // Highest level for which threshold is defined


    // --- Modifiers ---
    modifier onlyBadgeOwner(uint256 tokenId) {
        if (_owners[tokenId] != msg.sender) {
            revert OnlyBadgeOwnerCanPerform();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
        _badgeCounter = 0;
         // Define Level 0 threshold (start)
        _levelXPThresholds[0] = 0;
        _maxLevelDefined = 0;
    }

    // --- Core ERC721 Overrides (Simplified/Focused) ---

    /**
     * @dev See {IERC721-ownerOf}.
     * Simplified implementation assuming tokens are minted sequentially.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
            revert BadgeDoesNotExist(tokenId);
        }
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns a dynamic URI based on the badge's current XP.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
        }
        if (bytes(_metadataBaseURI).length == 0) {
             revert MetadataURINotSet();
        }
        // Append token ID and potentially XP/Level as query params or path segments
        // The off-chain metadata server will use this info to generate metadata dynamically.
        // Example: base/tokenId?xp=1234&level=5
        return string(abi.encodePacked(_metadataBaseURI, Strings.toString(tokenId), "?xp=", Strings.toString(_badgeXP[tokenId]), "&level=", Strings.toString(getBadgeLevel(tokenId))));
    }

     /**
     * @dev See {ERC165-supportsInterface}.
     * Supports ERC721 and ERC721Metadata interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-\_beforeTokenTransfer}.
     * This hook is called before any token transfer.
     * We prevent all transfers to make the token Soulbound.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent any transfers if the token is being moved *from* an owner address
        if (from != address(0)) {
            revert("SBT: Token is non-transferable");
        }
        // Allow minting (from address(0)) and burning (to address(0)) if needed,
        // but prevent transfer between non-zero addresses.
        // The above check `if (from != address(0))` is sufficient to block all transfers.
    }

    // --- XP and Level Management ---

    /**
     * @notice Internal function to add XP and emit events.
     * @param tokenId The ID of the badge.
     * @param amount The amount of XP to add.
     */
    function _addXPInternal(uint256 tokenId, uint256 amount) internal {
        if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
        }
        uint256 oldXP = _badgeXP[tokenId];
        uint256 oldLevel = getBadgeLevel(tokenId);
        _badgeXP[tokenId] += amount;
        uint256 newXP = _badgeXP[tokenId];
        uint256 newLevel = getBadgeLevel(tokenId);

        emit XPIncreased(tokenId, oldXP, newXP);
        if (newLevel > oldLevel) {
            emit LevelIncreased(tokenId, oldLevel, newLevel);
        }
    }

    /**
     * @notice Returns the current XP for a badge.
     * @param tokenId The ID of the badge.
     * @return The current experience points.
     */
    function getBadgeXP(uint256 tokenId) public view returns (uint256) {
         if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
         }
        return _badgeXP[tokenId];
    }

    /**
     * @notice Calculates and returns the current level for a badge based on XP thresholds.
     * @param tokenId The ID of the badge.
     * @return The calculated level.
     */
    function getBadgeLevel(uint256 tokenId) public view returns (uint256) {
        uint256 currentXP = getBadgeXP(tokenId);
        uint256 level = 0;
        // Iterate through defined levels to find the highest level reached
        // Note: This linear scan is okay for a reasonable number of levels (<100)
        // For many levels, a more efficient data structure might be needed.
        for (uint256 i = 0; i <= _maxLevelDefined; i++) {
            if (_levelXPThresholds[i] <= currentXP) {
                level = i;
            } else {
                break; // XP is less than the threshold for level i, so level i-1 is the current level
            }
        }
        return level;
    }

    /**
     * @notice Admin function to define the XP required to reach a specific level.
     * Levels must be defined in increasing order of XP.
     * @param level The level number (must be >= 0).
     * @param xpThreshold The minimum XP required for this level.
     */
    function setLevelXPThreshold(uint256 level, uint256 xpThreshold) public onlyOwner {
        if (level > 0 && xpThreshold <= _levelXPThresholds[level - 1]) {
            revert InvalidXPThreshold(); // Ensure thresholds are increasing
        }
         if (level > _maxLevelDefined + 1) {
            revert InvalidLevel(); // Levels should be set sequentially
        }
        _levelXPThresholds[level] = xpThreshold;
        if (level > _maxLevelDefined) {
            _maxLevelDefined = level;
        }
        emit LevelXPThresholdSet(level, xpThreshold);
    }


    // --- Metadata Management ---

    /**
     * @notice Admin function to set the base URI for token metadata.
     * The full URI will be baseURI/tokenId?xp=...&level=...
     * @param baseURI The base URI string.
     */
    function setMetadataBaseURI(string memory baseURI) public onlyOwner {
        _metadataBaseURI = baseURI;
        emit MetadataBaseURISet(baseURI);
    }

    // --- Quest System ---

    /**
     * @notice Admin function to define or update a quest.
     * @param questId Unique identifier for the quest.
     * @param xpReward The amount of XP granted upon completion.
     * @param isActive Whether the quest is currently active and completable.
     * @param requiredXP Optional minimum XP the badge needs to attempt/complete.
     */
    function defineQuest(string memory questId, uint256 xpReward, bool isActive, uint256 requiredXP) public onlyOwner {
        // Add questId to list if new
        bool found = false;
        for (uint i = 0; i < _questIds.length; i++) {
            if (keccak256(bytes(_questIds[i])) == keccak256(bytes(questId))) {
                found = true;
                break;
            }
        }
        if (!found) {
            _questIds.push(questId);
        }

        _quests[questId] = Quest(xpReward, isActive, requiredXP);
        emit QuestDefined(questId, xpReward, isActive, requiredXP);
    }

    /**
     * @notice Admin function to toggle the active status of a quest.
     * @param questId Unique identifier for the quest.
     * @param isActive New active status.
     */
    function toggleQuestActiveStatus(string memory questId, bool isActive) public onlyOwner {
        Quest storage quest = _quests[questId];
        if (quest.xpReward == 0 && !quest.isActive) { // Check if quest exists based on default values
             bool exists = false;
             for(uint i = 0; i < _questIds.length; i++){
                 if(keccak256(bytes(_questIds[i])) == keccak256(bytes(questId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert QuestNotFound(questId);
        }
        quest.isActive = isActive;
        emit QuestActiveStatusToggled(questId, isActive);
    }


    /**
     * @notice Admin function to mark a quest as completed for a specific badge and grant XP.
     * This is an admin-controlled function to ensure quest criteria are met off-chain or by a trusted oracle.
     * @param tokenId The ID of the badge that completed the quest.
     * @param questId Unique identifier for the quest.
     */
    function completeQuest(uint256 tokenId, string memory questId) public onlyOwner {
        if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
        }
        Quest storage quest = _quests[questId];
        if (quest.xpReward == 0 && !quest.isActive) { // Check if quest exists
             bool exists = false;
             for(uint i = 0; i < _questIds.length; i++){
                 if(keccak256(bytes(_questIds[i])) == keccak256(bytes(questId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert QuestNotFound(questId);
        }
        if (!quest.isActive) {
            revert QuestNotActive(questId);
        }
        if (_userCompletedQuests[tokenId][questId]) {
            revert QuestAlreadyCompleted(tokenId, questId);
        }
        if (getBadgeXP(tokenId) < quest.requiredXP) {
             revert("Quest: Insufficient badge XP");
        }

        _userCompletedQuests[tokenId][questId] = true;
        _addXPInternal(tokenId, quest.xpReward);

        emit QuestCompleted(tokenId, questId, quest.xpReward);
    }

    /**
     * @notice Returns details of a specific quest.
     * @param questId Unique identifier for the quest.
     * @return xpReward, isActive, requiredXP
     */
    function getQuestDetails(string memory questId) public view returns (uint256 xpReward, bool isActive, uint256 requiredXP) {
         Quest storage quest = _quests[questId];
         // Check if quest exists (basic check based on default values)
         bool exists = false;
         for(uint i = 0; i < _questIds.length; i++){
             if(keccak256(bytes(_questIds[i])) == keccak256(bytes(questId))){
                 exists = true;
                 break;
             }
         }
         if(!exists) revert QuestNotFound(questId);

        return (quest.xpReward, quest.isActive, quest.requiredXP);
    }

    /**
     * @notice Returns a list of quest IDs completed by a specific badge.
     * Note: This iterates through all defined quests, which might be gas-intensive
     * if there are many quests. Caching or a different storage pattern might be needed for scale.
     * @param tokenId The ID of the badge.
     * @return An array of completed quest IDs.
     */
    function getUserCompletedQuests(uint256 tokenId) public view returns (string[] memory) {
        if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
        }
        string[] memory completed; // dynamic array
        uint256 count = 0;
        // First pass to count
        for (uint i = 0; i < _questIds.length; i++) {
            if (_userCompletedQuests[tokenId][_questIds[i]]) {
                count++;
            }
        }
        // Second pass to populate
        completed = new string[](count);
        count = 0; // Reset counter
        for (uint i = 0; i < _questIds.length; i++) {
            if (_userCompletedQuests[tokenId][_questIds[i]]) {
                completed[count] = _questIds[i];
                count++;
            }
        }
        return completed;
    }


    // --- Staking System for XP ---

    /**
     * @notice Admin function to define or update a staking pool.
     * Users can stake the specified token to earn XP for their badge.
     * @param poolId Unique identifier for the staking pool.
     * @param stakedToken The address of the ERC20 token to stake.
     * @param xpRatePerSecond The amount of XP earned per second per staked token.
     * @param isActive Whether the staking pool is currently active.
     */
    function defineStakingPool(string memory poolId, address stakedToken, uint256 xpRatePerSecond, bool isActive) public onlyOwner {
         // Add poolId to list if new
        bool found = false;
        for (uint i = 0; i < _stakingPoolIds.length; i++) {
            if (keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))) {
                found = true;
                break;
            }
        }
        if (!found) {
            _stakingPoolIds.push(poolId);
        }

        _stakingPools[poolId] = StakingPool(IERC20(stakedToken), xpRatePerSecond, isActive, _stakingPools[poolId].totalStaked); // Preserve totalStaked if updating
        emit StakingPoolDefined(poolId, stakedToken, xpRatePerSecond, isActive);
    }

    /**
     * @notice Admin function to toggle the active status of a staking pool.
     * @param poolId Unique identifier for the staking pool.
     * @param isActive New active status.
     */
    function toggleStakingPoolActiveStatus(string memory poolId, bool isActive) public onlyOwner {
         StakingPool storage pool = _stakingPools[poolId];
         if (address(pool.stakedToken) == address(0) && !pool.isActive) { // Check if pool exists
             bool exists = false;
             for(uint i = 0; i < _stakingPoolIds.length; i++){
                 if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert StakingPoolNotFound(poolId);
         }
         pool.isActive = isActive;
         emit StakingPoolActiveStatusToggled(poolId, isActive);
    }

    /**
     * @notice Stakes tokens into a pool associated with the caller's badge.
     * Requires the caller to own a badge and have approved this contract to spend the tokens.
     * @param poolId Unique identifier for the staking pool.
     * @param amount The amount of tokens to stake.
     */
    function stakeTokensForXP(string memory poolId, uint256 amount) public {
        // Find the caller's badge (assuming they own only one)
        uint256 tokenId = 0;
        // This iteration is inefficient if there are many tokens.
        // A mapping from address to tokenId would be better if only one badge per user.
        // For this example, we'll just check the owner's balance (should be 1) and assume the single token is the badge.
        if (_balances[msg.sender] == 0) {
             revert("Staking: Caller does not own a badge.");
        }
        // Assuming single badge per owner, find their tokenId (inefficient lookup)
         bool found = false;
         // A more optimized version would store address => tokenId mapping if 1:1
        for(uint256 i = 1; i <= _badgeCounter; i++) { // Iterate through minted tokens
            if (_owners[i] == msg.sender) {
                tokenId = i;
                found = true;
                break;
            }
        }
        if (!found) revert("Staking: Could not find caller's badge.");


        StakingPool storage pool = _stakingPools[poolId];
        if (address(pool.stakedToken) == address(0)) { // Check if pool exists
             bool exists = false;
             for(uint i = 0; i < _stakingPoolIds.length; i++){
                 if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert StakingPoolNotFound(poolId);
        }
        if (!pool.isActive) {
            revert StakingPoolNotActive(poolId);
        }
        if (amount == 0) {
            revert InsufficientStakeAmount();
        }

        // Claim any pending XP before staking more
        uint256 accruedXP = _calculateStakingXP(tokenId, poolId);
        if (accruedXP > 0) {
            _addXPInternal(tokenId, accruedXP);
            _lastStakingXPClaimTime[tokenId][poolId] = block.timestamp; // Reset timer
            emit AccruedXPClaimed(tokenId, poolId, accruedXP);
        } else {
             // If no XP was accrued (e.g., first stake or claimed recently), just update timer
             // unless it's the very first stake for this pool/badge combo.
             if (_userStakes[tokenId][poolId] == 0) {
                _lastStakingXPClaimTime[tokenId][poolId] = block.timestamp;
             }
        }


        // Transfer tokens to this contract
        pool.stakedToken.transferFrom(msg.sender, address(this), amount);

        _userStakes[tokenId][poolId] += amount;
        pool.totalStaked += amount;

        emit TokensStakedForXP(tokenId, poolId, amount);
    }

     /**
     * @notice Claims staked tokens from a pool.
     * Requires the caller to own a badge and have tokens staked in the pool.
     * @param poolId Unique identifier for the staking pool.
     */
    function claimStakedTokens(string memory poolId) public {
        // Find the caller's badge (assuming they own only one)
        uint256 tokenId = 0;
        if (_balances[msg.sender] == 0) {
             revert("Staking: Caller does not own a badge.");
        }
         bool found = false;
        for(uint256 i = 1; i <= _badgeCounter; i++) { // Iterate through minted tokens
            if (_owners[i] == msg.sender) {
                tokenId = i;
                found = true;
                break;
            }
        }
        if (!found) revert("Staking: Could not find caller's badge.");

        StakingPool storage pool = _stakingPools[poolId];
         if (address(pool.stakedToken) == address(0)) { // Check if pool exists
             bool exists = false;
             for(uint i = 0; i < _stakingPoolIds.length; i++){
                 if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert StakingPoolNotFound(poolId);
         }

        uint256 stakedAmount = _userStakes[tokenId][poolId];
        if (stakedAmount == 0) {
            revert InsufficientStakedBalance();
        }

        // Claim any pending XP before unstaking
        uint256 accruedXP = _calculateStakingXP(tokenId, poolId);
        if (accruedXP > 0) {
            _addXPInternal(tokenId, accruedXP);
            _lastStakingXPClaimTime[tokenId][poolId] = block.timestamp; // Reset timer
            emit AccruedXPClaimed(tokenId, poolId, accruedXP);
        } else {
             // If no XP earned since last claim, update timer anyway if there was a stake
            if (_userStakes[tokenId][poolId] > 0) {
                 _lastStakingXPClaimTime[tokenId][poolId] = block.timestamp;
            }
        }


        _userStakes[tokenId][poolId] = 0;
        pool.totalStaked -= stakedAmount;

        // Transfer tokens back to the user
        pool.stakedToken.transfer(msg.sender, stakedAmount);

        emit StakedTokensClaimed(tokenId, poolId, stakedAmount);
    }

     /**
     * @notice Claims accrued XP from staking in a specific pool.
     * Requires the caller to own a badge and have tokens staked in the pool.
     * @param poolId Unique identifier for the staking pool.
     */
    function claimAccruedXPFromStaking(string memory poolId) public {
        // Find the caller's badge (assuming they own only one)
        uint256 tokenId = 0;
         if (_balances[msg.sender] == 0) {
             revert("Staking: Caller does not own a badge.");
         }
         bool found = false;
        for(uint256 i = 1; i <= _badgeCounter; i++) { // Iterate through minted tokens
            if (_owners[i] == msg.sender) {
                tokenId = i;
                found = true;
                break;
            }
        }
        if (!found) revert("Staking: Could not find caller's badge.");


        StakingPool storage pool = _stakingPools[poolId];
         if (address(pool.stakedToken) == address(0)) { // Check if pool exists
             bool exists = false;
             for(uint i = 0; i < _stakingPoolIds.length; i++){
                 if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert StakingPoolNotFound(poolId);
         }

        uint256 accruedXP = _calculateStakingXP(tokenId, poolId);

        if (accruedXP > 0) {
            _addXPInternal(tokenId, accruedXP);
            _lastStakingXPClaimTime[tokenId][poolId] = block.timestamp; // Reset timer
            emit AccruedXPClaimed(tokenId, poolId, accruedXP);
        }
        // No revert if accruedXP is 0, user just gets 0 XP.
    }


    /**
     * @notice Admin function for emergency withdrawal of tokens from a pool.
     * Use with extreme caution. Intended for scenarios like token deprecation.
     * @param poolId Unique identifier for the staking pool.
     * @param amount The amount to withdraw.
     */
    function withdrawEmergency(string memory poolId, uint256 amount) public onlyOwner {
         StakingPool storage pool = _stakingPools[poolId];
         if (address(pool.stakedToken) == address(0)) { // Check if pool exists
              bool exists = false;
             for(uint i = 0; i < _stakingPoolIds.length; i++){
                 if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert StakingPoolNotFound(poolId);
         }
        if (amount == 0) {
            revert InsufficientStakeAmount(); // Using this error message loosely
        }
        if (amount > pool.stakedToken.balanceOf(address(this))) {
             revert InsufficientStakedBalance(); // Contract doesn't hold enough
        }

        // Note: This bypasses user staking records (_userStakes).
        // Admin should manually update user stakes or handle this situation carefully.
        // This is why emergency withdrawals are risky.
        pool.totalStaked -= amount; // Decrease total tracked stake, but user stakes might still show balance

        pool.stakedToken.transfer(msg.sender, amount);

        emit EmergencyWithdrawal(poolId, msg.sender, amount);
    }

    /**
     * @notice Returns details of a specific staking pool.
     * @param poolId Unique identifier for the staking pool.
     * @return stakedToken, xpRatePerSecond, isActive, totalStaked
     */
    function getStakingPoolDetails(string memory poolId) public view returns (address stakedToken, uint256 xpRatePerSecond, bool isActive, uint256 totalStaked) {
         StakingPool storage pool = _stakingPools[poolId];
         if (address(pool.stakedToken) == address(0) && !pool.isActive) { // Check if pool exists
              bool exists = false;
             for(uint i = 0; i < _stakingPoolIds.length; i++){
                 if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                     exists = true;
                     break;
                 }
             }
             if(!exists) revert StakingPoolNotFound(poolId);
         }
        return (address(pool.stakedToken), pool.xpRatePerSecond, pool.isActive, pool.totalStaked);
    }

    /**
     * @notice Returns the amount of tokens staked by a badge in a pool.
     * @param tokenId The ID of the badge.
     * @param poolId Unique identifier for the staking pool.
     * @return The staked amount.
     */
    function getUserStakedAmount(uint256 tokenId, string memory poolId) public view returns (uint256) {
         if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
         }
         // Check if pool exists (basic check)
         bool exists = false;
         for(uint i = 0; i < _stakingPoolIds.length; i++){
             if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                 exists = true;
                 break;
             }
         }
         if(!exists) revert StakingPoolNotFound(poolId);
        return _userStakes[tokenId][poolId];
    }

     /**
     * @notice Calculates the accrued XP from staking for a specific badge and pool.
     * This is the XP earned since the last claim or stake event.
     * @param tokenId The ID of the badge.
     * @param poolId Unique identifier for the staking pool.
     * @return The accrued XP.
     */
    function getAccruedXPFromStaking(uint256 tokenId, string memory poolId) public view returns (uint256) {
         if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
         }
          // Check if pool exists (basic check)
         bool exists = false;
         for(uint i = 0; i < _stakingPoolIds.length; i++){
             if(keccak256(bytes(_stakingPoolIds[i])) == keccak256(bytes(poolId))){
                 exists = true;
                 break;
             }
         }
         if(!exists) revert StakingPoolNotFound(poolId);

        return _calculateStakingXP(tokenId, poolId);
    }


    // --- User Interactions ---

    /**
     * @notice Allows a user to mint their unique ChronicleBadge.
     * Each address can only mint one badge.
     */
    function mintBadge() public {
        if (_balances[msg.sender] > 0) {
            revert BadgeAlreadyMinted(msg.sender);
        }

        _badgeCounter++;
        uint256 newTokenId = _badgeCounter;

        _owners[newTokenId] = msg.sender;
        _balances[msg.sender]++;
        _badgeXP[newTokenId] = 0; // Start with 0 XP

        // _beforeTokenTransfer hook is called internally by _mint
        // In a real ERC721, we'd use _mint(msg.sender, newTokenId);
        // For this simplified example, we set state directly.

        emit BadgeMinted(msg.sender, newTokenId);
        // Standard ERC721 Transfer event (from 0x0 to msg.sender) is also needed
        emit Transfer(address(0), msg.sender, newTokenId);
    }

    // --- Internal Helper Functions ---

    /**
     * @notice Calculates the amount of XP earned from staking since the last claim/stake.
     * @param tokenId The ID of the badge.
     * @param poolId Unique identifier for the staking pool.
     * @return The calculated XP amount.
     */
    function _calculateStakingXP(uint256 tokenId, string memory poolId) internal view returns (uint256) {
        uint256 stakedAmount = _userStakes[tokenId][poolId];
        uint256 lastClaimTime = _lastStakingXPClaimTime[tokenId][poolId];

        if (stakedAmount == 0 || lastClaimTime == 0) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastClaimTime;
        StakingPool storage pool = _stakingPools[poolId];
        uint256 xpRate = pool.xpRatePerSecond;

        // Calculate XP: stakedAmount * timeElapsed * xpRatePerSecond
        // Use standard ERC20 decimals assumption (18), adjust if needed for specific tokens.
        // This calculation assumes xpRatePerSecond is scaled appropriately (e.g., per token).
        // If xpRate is per unit of the staked token's smallest denomination, adjust division.
        // Example: For DAI (18 decimals), xpRate is per 10^18 DAI. If xpRate is per 1 unit (10^0), divide amount by 10^18.
        // Assuming xpRatePerSecond is scaled per 10^18 units of the staked token:
        // xp = (stakedAmount * timeElapsed * xpRate) / 1e18 // This division is needed if xpRate is large
        // Let's simplify and assume xpRate is per 1 unit of staked token, and stakedAmount is in units.
        // A more robust solution would handle decimals explicitly.
        // For now, simple multiplication assuming stakedAmount is already scaled if needed by the caller.
        // Let's assume stakedAmount is in token units, and xpRate is XP per token unit per second.
        uint256 accrued = stakedAmount * timeElapsed * xpRate;

        return accrued;
    }


    // --- Simplified ERC721 functions needed by external calls or logic ---
    // In a real contract, you would inherit from OpenZeppelin's ERC721
    // and use _safeMint, _burn, etc. instead of manual state updates.
    // These functions are included here for completeness of the interface,
    // but rely on the simplified state defined above.

    /**
     * @dev See {IERC721-balanceOf}.
     * Simplified implementation.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) {
            revert IERC721.ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

     /**
     * @dev See {IERC721-getApproved}. Not applicable for Soulbound Tokens.
     * Always returns address(0).
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
        }
        return address(0); // Approvals not possible for SBT
    }

    /**
     * @dev See {IERC721-isApprovedForAll}. Not applicable for Soulbound Tokens.
     * Always returns false.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
         // Check owner validity (optional, but good practice)
        if (owner == address(0)) {
            revert IERC721.ERC721InvalidOwner(address(0));
        }
        return false; // Operators not possible for SBT
    }

    // The following ERC721 transfer functions (`transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`)
    // are intentionally omitted or will revert due to the `_beforeTokenTransfer` hook.
    // A full implementation inheriting ERC721 would have these, but the hook
    // would make them non-functional for token transfers between users.
    // Let's add minimal reverting versions to satisfy the interface just in case.

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert("SBT: Token is non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
         revert("SBT: Token is non-transferable");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
         revert("SBT: Token is non-transferable");
     }

    function approve(address to, uint256 tokenId) public virtual override {
         if (_owners[tokenId] == address(0)) {
             revert BadgeDoesNotExist(tokenId);
         }
        // No-op for SBT, or revert if strict adherence to non-transferability is needed
        revert("SBT: Token cannot be approved for transfer");
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
         // No-op for SBT, or revert
         revert("SBT: Token cannot be approved for transfer");
    }


    // --- Admin Functions (Inherited from Ownable) ---
    // transferOwnership(newOwner) and renounceOwnership() are provided by Ownable.

    // Example of adding direct XP as an admin function
    function addXP(uint256 tokenId, uint256 amount) public onlyOwner {
        _addXPInternal(tokenId, amount);
    }


    // --- View Functions ---

    /**
     * @notice Returns the address of the badge owner.
     * Alias for ownerOf.
     * @param tokenId The ID of the badge.
     * @return The owner's address.
     */
    function getBadgeOwner(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    /**
     * @notice Returns the current badge counter (total number of badges minted).
     * Note: Token IDs are 1-based sequential numbers up to this counter.
     * @return The total number of badges minted.
     */
    function getTotalMintedBadges() public view returns (uint256) {
        return _badgeCounter;
    }

     /**
     * @notice Returns a list of all defined quest IDs.
     * Note: Gas cost increases with the number of quests.
     * @return An array of quest IDs.
     */
    function getAllQuestIds() public view returns (string[] memory) {
        return _questIds;
    }

     /**
     * @notice Returns a list of all defined staking pool IDs.
     * Note: Gas cost increases with the number of pools.
     * @return An array of staking pool IDs.
     */
    function getAllStakingPoolIds() public view returns (string[] memory) {
        return _stakingPoolIds;
    }

    /**
     * @notice Returns the maximum level for which an XP threshold is defined.
     * Levels are 0 to _maxLevelDefined.
     * @return The maximum defined level.
     */
    function getMaxLevelDefined() public view returns (uint256) {
        return _maxLevelDefined;
    }

    /**
     * @notice Returns the XP threshold required for a specific level.
     * @param level The level number.
     * @return The required XP threshold.
     */
    function getLevelXPThreshold(uint256 level) public view returns (uint256) {
        return _levelXPThresholds[level];
    }


    // Include OpenZeppelin's SafeMath for basic uint256 operations if not using 0.8+ default overflow checks.
    // For Solidity 0.8+, arithmetic operations checked by default.

    // Need a basic Strings library for toString in tokenURI
    library Strings {
        bytes16 private constant _SYMBOLS = "0123456789abcdef";

        function toString(uint256 value) internal pure returns (string memory) {
            unchecked {
                uint256 length = uint256(足够的长度); // Placeholder for length calculation
                uint256 temp = value;
                assembly {
                    length := 0
                    if iszero(temp) { length := 1 }
                    for { let temp2 := temp } iszero(iszero(temp2)) { temp2 := div(temp2, 10) } { length := add(length, 1) }
                }
                bytes memory buffer = new bytes(length);
                assembly {
                    let ptr := add(buffer, add(32, length))
                    for { } value { } {
                        ptr := sub(ptr, 1)
                        mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                        value := div(value, 10)
                    }
                     // Handle zero case
                    if iszero(length) {
                        ptr := sub(ptr, 1)
                        mstore8(ptr, byte(0, _SYMBOLS))
                    }
                }
                return string(buffer);
            }
        }
    }
}

```
**Explanation of Advanced Concepts:**

1.  **Soulbound Nature (`_beforeTokenTransfer`):** The contract overrides the internal `_beforeTokenTransfer` hook (a standard ERC-721 extension point). By checking `if (from != address(0))`, it prevents any transfer of the token *from* an existing owner, effectively making it non-transferable like a Soulbound Token (SBT). Transfers *to* or *from* the zero address (minting/burning) are typically still allowed by ERC-721 conventions, but the core non-transferability between users is enforced.
2.  **Dynamic Metadata (`tokenURI`):** The `tokenURI` function, responsible for linking the token to its metadata (like an image, description, and traits), is implemented to include the badge's current XP and calculated level in the URI itself (e.g., `/path/tokenId?xp=1234&level=5`). An off-chain metadata server would receive this URI, query the contract's `getBadgeXP` and `getBadgeLevel` functions (or parse the URL params if efficient), and dynamically generate a JSON metadata response reflecting the badge's current state. This makes the NFT's appearance or traits evolve based on on-chain activity.
3.  **On-Chain Progression (`_badgeXP`, `_levelXPThresholds`, `getBadgeLevel`):** The core `_badgeXP` mapping stores a simple integer value representing progress. `_levelXPThresholds` allows the administrator to define arbitrary levels and the XP required to reach them. `getBadgeLevel` provides the on-chain logic to calculate the current level from XP. This fully on-chain state for progression is a key feature.
4.  **On-Chain Quests (`_quests`, `_userCompletedQuests`, `defineQuest`, `completeQuest`):** The contract defines a structured `Quest` type and stores quests in a mapping. It tracks which badges have completed which quests. The `completeQuest` function, designed to be called by the contract owner (or a trusted oracle/system), grants XP upon completion. This provides a framework for verifiable, on-chain achievements. Making `completeQuest` `onlyOwner` is a common pattern where the complex criteria for a quest are verified off-chain, but the final reward is issued on-chain by a trusted entity.
5.  **Staking for Progression (`_stakingPools`, `_userStakes`, `_lastStakingXPClaimTime`, `stakeTokensForXP`, `claimStakedTokens`, `claimAccruedXPFromStaking`, `_calculateStakingXP`):** Users can stake standard ERC-20 tokens into defined pools linked to their badge. The contract tracks staked amounts and the time since the last XP claim. The `_calculateStakingXP` internal function calculates earned XP based on the staked amount, the pool's configured XP rate, and the time elapsed. Users can then claim this accrued XP or trigger a claim implicitly when staking/unstaking. This links financial/asset commitment (staking) directly to reputation/progress (XP).
6.  **ERC-165 Support:** Implemented `supportsInterface` to declare support for the ERC-721 and ERC-721Metadata standards, allowing marketplaces and wallets to correctly interpret the token type.
7.  **Ownable Pattern:** Standard OpenZeppelin `Ownable` is used for basic administrative access control, ensuring only the deployer can define quests, pools, levels, set metadata URI, or grant XP directly.
8.  **Custom Errors:** Using Solidity 0.8+ `error` definitions for more gas-efficient and informative error handling compared to `require` with strings.
9.  **Events:** Comprehensive events are included for tracking all significant actions (minting, XP gain, level changes, quest actions, staking actions), which are crucial for off-chain applications, indexers, and user interfaces to monitor contract activity.

This contract combines several concepts to create a rich, dynamic, and unique on-chain identity/progression system tied to a Soulbound NFT. Note that a production-ready contract would likely inherit from a battle-tested library like OpenZeppelin for the full ERC-721 implementation and `Ownable`, and potentially use more sophisticated access control (like AccessControl.sol) or a proxy pattern for upgradeability, especially given the complexity. The `Strings` library is included as a minimal version needed for `toString` in `tokenURI`. The staking token lookup for a user's badge assumes a 1:1 mapping (one badge per address) and uses an inefficient loop; for a real application, a mapping `address => uint256` would be required to store the badge ID for quick lookup if this assumption holds.