Okay, let's design an interesting, advanced, and non-standard smart contract.

**Concept:** A "Dynamic On-Chain Ecosystem" with a focus on time-phased evolution, resource synthesis (crafting tokens/NFTs), and self-adjusting parameters based on on-chain activity, potentially influenced by an oracle. We'll call it the "ChronoShift Crucible".

**Key Features:**

1.  **ERC-20 Token (`ChronoTokens`):** The primary currency.
2.  **ERC-721 NFTs (`Essence Shards`):** Collectible, synthesizable assets with dynamic properties.
3.  **Dynamic Phases:** The contract operates in discrete "Phases". Each phase has different parameters (staking rewards, crafting costs/recipes, fees, etc.). Phases advance either manually by the owner or automatically based on time/activity milestones (e.g., total tokens staked, total NFTs crafted).
4.  **Resource Synthesis (Crafting):** Users can combine `ChronoTokens` and/or `Essence Shards` to create new/different `Essence Shards` or potentially other tokens/items. Recipes are defined and potentially phase-dependent.
5.  **Staking Pool:** Users can stake `ChronoTokens` to earn more `ChronoTokens`, with rewards varying by phase.
6.  **NFT Staking:** Users can stake specific `Essence Shards` to earn passive income or grant them unique properties/abilities while staked, again potentially phase-dependent.
7.  **Dynamic Fees:** Transaction fees (e.g., on transfers or crafting) might adjust based on the current phase, oracle data (like gas price), or total contract activity.
8.  **Achievements/Quests:** Simple system to track user actions and potentially reward them (manual or triggered).
9.  **Oracle Integration (Conceptual):** A trusted oracle can update a parameter (e.g., a multiplier for dynamic fees or crafting costs) based on external data.
10. **Self-Adjustment:** Some parameters might subtly change within a phase based on real-time activity.
11. **Token/NFT Burning:** Mechanisms to burn assets for specific benefits or supply control.

This combination of dynamic phases, resource synthesis, dual staking pools, self-adjusting fees, and oracle interaction provides a non-standard set of inter-connected mechanics within a single contract, aiming for complexity and novelty.

---

**Outline and Function Summary: ChronoShiftCrucible**

**Contract Name:** `ChronoShiftCrucible`

**Inherits:** `ERC20`, `ERC721`, `ERC721Enumerable`, `Ownable`, `Pausable`, `ReentrancyGuard`

**Core Concepts:** Dynamic Phases, Token & NFT Staking, Crafting/Synthesis, Dynamic Fees, Oracle Integration, Achievements.

**State Variables:**
*   `currentTokenId`: Counter for minted Essence Shards.
*   `currentPhase`: The active phase index.
*   `phaseConfigs`: Mapping of phase index to configuration structs.
*   `stakingPool`: Struct/Mapping for token staking data.
*   `nftStakingPool`: Struct/Mapping for NFT staking data.
*   `craftingRecipes`: Mapping of recipe ID to recipe structs.
*   `dynamicFeeBasisPoints`: Current fee basis points.
*   `oracleValue`: Value provided by the trusted oracle.
*   `trustedOracle`: Address authorized to update oracle value.
*   `achievementStatus`: Mapping tracking user achievements.

**Events:**
*   `PhaseChanged(uint256 oldPhase, uint256 newPhase)`
*   `RecipeDefined(uint256 recipeId)`
*   `TokensStaked(address user, uint256 amount)`
*   `TokensUnstaked(address user, uint256 amount)`
*   `StakingRewardsClaimed(address user, uint256 amount)`
*   `EssenceShardStaked(address user, uint256 tokenId)`
*   `EssenceShardUnstaked(address user, uint256 tokenId)`
*   `EssenceShardMinted(address user, uint256 tokenId, uint256 recipeId)`
*   `TokensBurned(address user, uint256 amount)`
*   `EssenceShardBurned(address user, uint256 tokenId)`
*   `OracleValueUpdated(uint256 newValue)`
*   `DynamicFeeUpdated(uint256 newFeeBasisPoints)`
*   `AchievementGranted(address user, uint256 achievementId)`
*   `AchievementRewardClaimed(address user, uint256 achievementId)`

**Function Summary:**

**ERC-20 (ChronoTokens - $CT):**
1.  `transfer(address recipient, uint256 amount)`: Send $CT, potentially with dynamic fee.
2.  `approve(address spender, uint256 amount)`: Approve spending $CT.
3.  `transferFrom(address sender, address recipient, uint256 amount)`: Transfer $CT via approval, potentially with dynamic fee.
4.  `balanceOf(address account)`: Get $CT balance. (View)
5.  `totalSupply()`: Get total $CT supply. (View)
6.  `allowance(address owner, address spender)`: Get spender allowance. (View)
7.  `_mint(address account, uint256 amount)`: Internal function for minting $CT. (Internal)
8.  `_burn(address account, uint256 amount)`: Internal function for burning $CT. (Internal)

**ERC-721 (Essence Shards - $ES):**
9.  `ownerOf(uint256 tokenId)`: Get owner of $ES. (View)
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer $ES.
11. `transferFrom(address from, address to, uint256 tokenId)`: Transfer $ES.
12. `approve(address to, uint256 tokenId)`: Approve $ES transfer.
13. `getApproved(uint256 tokenId)`: Get approved address for $ES. (View)
14. `setApprovalForAll(address operator, bool approved)`: Set operator approval for all $ES.
15. `isApprovedForAll(address owner, address operator)`: Check operator approval. (View)
16. `tokenOfOwnerByIndex(address owner, uint256 index)`: Get token ID by owner index (from Enumerable). (View)
17. `totalSupply()`: Get total $ES supply. (View, from Enumerable)
18. `tokenByIndex(uint256 index)`: Get token ID by index (from Enumerable). (View)
19. `_safeMint(address to, uint256 tokenId)`: Internal function for minting $ES. (Internal)
20. `_burn(uint256 tokenId)`: Internal function for burning $ES. (Internal)

**Dynamic Phase System:**
21. `setPhaseConfig(uint256 phase, uint256 stakingRewardRatePerSecond, uint256 baseCraftingFeeCT, uint256 baseCraftingFeeES, uint256 dynamicFeeMultiplier)`: Owner defines phase parameters. (Owner)
22. `advancePhase()`: Owner manually advances to the next phase. (Owner)
23. `checkAndAutoAdvancePhase()`: Potentially triggered externally or internally to check if auto-advance criteria met. (Public)
24. `getCurrentPhase()`: Get current phase index. (View)
25. `getPhaseConfig(uint256 phase)`: Get configuration for a phase. (View)

**Staking (ChronoTokens):**
26. `stakeTokens(uint256 amount)`: Stake $CT into the pool. (ReentrantGuard)
27. `unstakeTokens()`: Unstake all $CT and claim rewards. (ReentrantGuard)
28. `claimStakingRewards()`: Claim accumulated $CT rewards without unstaking. (ReentrantGuard)
29. `getStakingBalance(address user)`: Get user's staked $CT amount. (View)
30. `getPendingStakingRewards(address user)`: Get user's pending $CT rewards. (View)

**Staking (Essence Shards):**
31. `stakeEssenceShard(uint256 tokenId)`: Stake an $ES NFT. (ReentrantGuard)
32. `unstakeEssenceShard(uint256 tokenId)`: Unstake an $ES NFT. (ReentrantGuard)
33. `isEssenceShardStaked(uint256 tokenId)`: Check if an $ES is staked. (View)
34. `getStakedEssenceShards(address user)`: Get list of staked $ES for a user. (View)

**Crafting/Synthesis:**
35. `defineCraftingRecipe(uint256 recipeId, address[] tokenIngredients, uint256[] tokenAmounts, uint256[] essenceShardIngredients, uint256 outputEssenceShardId)`: Owner defines a recipe using token/NFT inputs and an NFT output. (Owner)
36. `craftEssenceShard(uint256 recipeId)`: Execute a crafting recipe, consuming inputs and minting output. (ReentrantGuard, Pausable)
37. `getRecipe(uint256 recipeId)`: Get details of a crafting recipe. (View)
38. `getRecipeOutput(uint256 recipeId)`: Get the output $ES ID for a recipe. (View)

**Burning Mechanisms:**
39. `burnChronoTokens(uint256 amount)`: Burn $CT owned by the caller.
40. `burnEssenceShard(uint256 tokenId)`: Burn an $ES owned by the caller.

**Dynamic Fees:**
41. `getAppliedFee(uint256 amount)`: Calculate the dynamic fee for a given amount. (View)

**Oracle Integration:**
42. `setTrustedOracle(address oracleAddress)`: Owner sets the address of the trusted oracle. (Owner)
43. `updateOracleValue(uint256 newValue)`: Trusted oracle updates the oracle value. (OnlyTrustedOracle)
44. `getOracleValue()`: Get the current oracle value. (View)

**Achievements:**
45. `grantAchievement(address user, uint256 achievementId)`: Owner grants an achievement to a user. (Owner)
46. `hasAchievement(address user, uint256 achievementId)`: Check if a user has an achievement. (View)
47. `getUserAchievements(address user)`: Get list of achievement IDs for a user. (View)
48. `claimAchievementReward(uint256 achievementId)`: User claims reward for an achievement (requires internal logic to check if earned). (ReentrantGuard)

**Administrative/Utility:**
49. `pause()`: Owner pauses contract functionality. (Owner, Pausable)
50. `unpause()`: Owner unpauses contract functionality. (Owner, Pausable)
51. `withdrawEth()`: Owner withdraws any accidental ETH sent to the contract. (Owner)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

// Outline and Function Summary: ChronoShiftCrucible
//
// Contract Name: ChronoShiftCrucible
//
// Inherits: ERC20, ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard
//
// Core Concepts: Dynamic Phases, Token & NFT Staking, Crafting/Synthesis, Dynamic Fees, Oracle Integration, Achievements.
//
// State Variables:
// * currentTokenId: Counter for minted Essence Shards.
// * currentPhase: The active phase index.
// * phaseConfigs: Mapping of phase index to configuration structs.
// * stakingPool: Struct/Mapping for token staking data.
// * nftStakingPool: Struct/Mapping for NFT staking data.
// * craftingRecipes: Mapping of recipe ID to recipe structs.
// * dynamicFeeBasisPoints: Current fee basis points.
// * oracleValue: Value provided by the trusted oracle.
// * trustedOracle: Address authorized to update oracle value.
// * achievementStatus: Mapping tracking user achievements.
// * autoPhaseAdvanceConditions: Struct/Mapping for auto phase advance criteria.
//
// Events:
// * PhaseChanged(uint256 oldPhase, uint256 newPhase)
// * RecipeDefined(uint256 recipeId)
// * TokensStaked(address user, uint256 amount)
// * TokensUnstaked(address user, uint256 amount)
// * StakingRewardsClaimed(address user, uint256 amount)
// * EssenceShardStaked(address user, uint256 tokenId)
// * EssenceShardUnstaked(uint256 tokenId)
// * EssenceShardMinted(address user, uint256 tokenId, uint256 recipeId)
// * TokensBurned(address user, uint256 amount)
// * EssenceShardBurned(uint256 tokenId)
// * OracleValueUpdated(uint256 newValue)
// * DynamicFeeUpdated(uint256 newFeeBasisPoints)
// * AchievementGranted(address user, uint256 achievementId)
// * AchievementRewardClaimed(address user, uint256 achievementId)
//
// Function Summary:
//
// ERC-20 (ChronoTokens - $CT):
// 1. transfer(address recipient, uint256 amount): Send $CT, potentially with dynamic fee.
// 2. approve(address spender, uint256 amount): Approve spending $CT.
// 3. transferFrom(address sender, address recipient, uint256 amount): Transfer $CT via approval, potentially with dynamic fee.
// 4. balanceOf(address account): Get $CT balance. (View)
// 5. totalSupply(): Get total $CT supply. (View)
// 6. allowance(address owner, address spender): Get spender allowance. (View)
// 7. _mint(address account, uint256 amount): Internal function for minting $CT. (Internal)
// 8. _burn(address account, uint256 amount): Internal function for burning $CT. (Internal)
//
// ERC-721 (Essence Shards - $ES):
// 9. ownerOf(uint256 tokenId): Get owner of $ES. (View)
// 10. safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer $ES.
// 11. transferFrom(address from, address to, uint256 tokenId): Transfer $ES.
// 12. approve(address to, uint256 tokenId): Approve $ES transfer.
// 13. getApproved(uint256 tokenId): Get approved address for $ES. (View)
// 14. setApprovalForAll(address operator, bool approved): Set operator approval for all $ES.
// 15. isApprovedForAll(address owner, address operator): Check operator approval. (View)
// 16. tokenOfOwnerByIndex(address owner, uint256 index): Get token ID by owner index (from Enumerable). (View)
// 17. totalSupply(): Get total $ES supply. (View, from Enumerable)
// 18. tokenByIndex(uint256 index): Get token ID by index (from Enumerable). (View)
// 19. _safeMint(address to, uint256 tokenId): Internal function for minting $ES. (Internal)
// 20. _burn(uint256 tokenId): Internal function for burning $ES. (Internal)
//
// Dynamic Phase System:
// 21. setPhaseConfig(uint256 phase, uint256 stakingRewardRatePerSecond, uint256 baseCraftingFeeCT, uint256 baseCraftingFeeES, uint256 dynamicFeeMultiplier, uint256 minTotalStakedForAdvance, uint256 minTotalCraftedForAdvance): Owner defines phase parameters. (Owner)
// 22. advancePhase(): Owner manually advances to the next phase. (Owner)
// 23. checkAndAutoAdvancePhase(): Potentially triggered externally or internally to check if auto-advance criteria met. (Public)
// 24. getCurrentPhase(): Get current phase index. (View)
// 25. getPhaseConfig(uint256 phase): Get configuration for a phase. (View)
//
// Staking (ChronoTokens):
// 26. stakeTokens(uint256 amount): Stake $CT into the pool. (ReentrantGuard, Pausable)
// 27. unstakeTokens(): Unstake all $CT and claim rewards. (ReentrantGuard, Pausable)
// 28. claimStakingRewards(): Claim accumulated $CT rewards without unstaking. (ReentrantGuard, Pausable)
// 29. getStakingBalance(address user): Get user's staked $CT amount. (View)
// 30. getPendingStakingRewards(address user): Get user's pending $CT rewards. (View)
// 31. getTotalStakedTokens(): Get total $CT staked across all users. (View)
//
// Staking (Essence Shards):
// 32. stakeEssenceShard(uint256 tokenId): Stake an $ES NFT. (ReentrantGuard, Pausable)
// 33. unstakeEssenceShard(uint256 tokenId): Unstake an $ES NFT. (ReentrantGuard, Pausable)
// 34. isEssenceShardStaked(uint256 tokenId): Check if an $ES is staked. (View)
// 35. getStakedEssenceShards(address user): Get list of staked $ES for a user. (View)
// 36. getEssenceShardStakingTime(uint256 tokenId): Get when an $ES was staked. (View)
//
// Crafting/Synthesis:
// 37. defineCraftingRecipe(uint256 recipeId, address[] tokenIngredients, uint256[] tokenAmounts, uint256[] essenceShardIngredients, uint256 outputEssenceShardId, bool phaseDependent): Owner defines a recipe using token/NFT inputs and an NFT output. Can be phase dependent. (Owner)
// 38. craftEssenceShard(uint256 recipeId): Execute a crafting recipe, consuming inputs and minting output, applying dynamic fees. (ReentrantGuard, Pausable)
// 39. getRecipe(uint256 recipeId): Get details of a crafting recipe. (View)
// 40. getRecipeOutput(uint256 recipeId): Get the output $ES ID for a recipe. (View)
// 41. getTotalEssenceShardsCrafted(): Get total $ES crafted across all recipes. (View)
//
// Burning Mechanisms:
// 42. burnChronoTokens(uint256 amount): Burn $CT owned by the caller.
// 43. burnEssenceShard(uint256 tokenId): Burn an $ES owned by the caller. (ReentrantGuard, Pausable)
//
// Dynamic Fees:
// 44. getAppliedFee(uint256 amount): Calculate the dynamic fee for a given amount based on current phase and oracle. (View)
// 45. getDynamicFeeBasisPoints(): Get the current dynamic fee basis points. (View)
// 46. setDynamicFeeBasisPoints(uint256 feeBasisPoints): Owner sets the base dynamic fee. (Owner)
//
// Oracle Integration:
// 47. setTrustedOracle(address oracleAddress): Owner sets the address of the trusted oracle. (Owner)
// 48. updateOracleValue(uint256 newValue): Trusted oracle updates the oracle value. (OnlyTrustedOracle)
// 49. getOracleValue(): Get the current oracle value. (View)
//
// Achievements:
// 50. grantAchievement(address user, uint256 achievementId): Owner grants an achievement to a user. (Owner)
// 51. hasAchievement(address user, uint256 achievementId): Check if a user has an achievement. (View)
// 52. getUserAchievements(address user): Get list of achievement IDs for a user. (View)
// 53. claimAchievementReward(uint256 achievementId): User claims reward for an achievement (requires internal logic to check if earned and reward). (ReentrantGuard, Pausable)
//
// Administrative/Utility:
// 54. pause(): Owner pauses contract functionality. (Owner, Pausable)
// 55. unpause(): Owner unpauses contract functionality. (Owner, Pausable)
// 56. withdrawEth(): Owner withdraws any accidental ETH sent to the contract. (Owner)

contract ChronoShiftCrucible is ERC20, ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _currentTokenId;
    uint256 public currentPhase;

    // --- Structs ---

    struct PhaseConfig {
        uint256 stakingRewardRatePerSecondCT; // Rewards per second per staked token unit
        uint256 baseCraftingFeeCT;
        uint256 baseCraftingFeeES; // Basis points of input ES value? Or fixed? Let's say fixed number of ES.
        uint256 dynamicFeeMultiplier; // Multiplier applied to the dynamic fee basis points
        uint256 minTotalStakedForAdvance; // Threshold for auto phase advance
        uint256 minTotalCraftedForAdvance; // Threshold for auto phase advance
    }

    struct StakingPositionCT {
        uint256 amount;
        uint256 rewardDebt; // Based on the cumulative reward per token when the user last interacted
        uint40 startTime;
    }

    struct StakingPositionES {
        uint40 startTime;
        address user; // Owner at time of staking
    }

    struct Recipe {
        address[] tokenIngredients;
        uint256[] tokenAmounts;
        uint256[] essenceShardIngredients; // List of ES token IDs required
        uint256 outputEssenceShardId; // The type/ID of the output ES
        bool phaseDependent; // If true, this recipe is only active in the phase it was defined for
    }

    // --- State Variables ---

    mapping(uint256 => PhaseConfig) public phaseConfigs;
    mapping(address => StakingPositionCT) private _stakingPoolCT;
    mapping(uint256 => StakingPositionES) private _nftStakingPoolES; // tokenId => Position
    mapping(address => uint256[]) private _stakedEssenceShardsByUser; // user => list of tokenIds
    mapping(uint256 => uint256) private _stakedEssenceShardToIndex; // tokenId => index in user's array

    uint256 private _cumulativeRewardPerTokenCT; // Accumulated rewards per token staked
    uint256 private _lastRewardUpdateTimeCT;
    uint256 public totalStakedTokensCT; // Total ChronoTokens staked

    mapping(uint256 => Recipe) public craftingRecipes;
    uint256 public totalEssenceShardsCrafted; // Counter for auto phase advance

    uint256 public dynamicFeeBasisPoints; // e.g., 100 = 1%
    uint256 public oracleValue; // e.g., gas price, external index
    address public trustedOracle;

    mapping(address => mapping(uint256 => bool)) public achievementStatus; // user => achievementId => earned

    uint256 public initialTokenSupply = 1_000_000 * (10**18); // Example supply

    // --- Events ---

    event PhaseChanged(uint256 oldPhase, uint256 newPhase);
    event RecipeDefined(uint256 recipeId, uint256 outputEssenceShardId);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event StakingRewardsClaimed(address indexed user, uint256 amount);
    event EssenceShardStaked(address indexed user, uint256 tokenId);
    event EssenceShardUnstaked(address indexed user, uint256 tokenId);
    event EssenceShardMinted(address indexed user, uint256 tokenId, uint256 recipeId);
    event TokensBurned(address indexed user, uint256 amount);
    event EssenceShardBurned(address indexed user, uint256 tokenId);
    event OracleValueUpdated(uint256 newValue);
    event DynamicFeeUpdated(uint256 newFeeBasisPoints);
    event AchievementGranted(address indexed user, uint256 achievementId);
    event AchievementRewardClaimed(address indexed user, uint256 achievementId);

    // --- Modifiers ---

    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracle, "CSC: Not trusted oracle");
        _;
    }

    // --- Constructor ---

    constructor()
        ERC20("ChronoTokens", "CT")
        ERC721("Essence Shard", "ES")
        Ownable(msg.sender) // Initialize Ownable with the deployer as owner
        Pausable() // Initialize Pausable
    {
        // Mint initial supply to the owner
        _mint(msg.sender, initialTokenSupply);

        // Set initial phase and default configs
        currentPhase = 1;
        _lastRewardUpdateTimeCT = uint40(block.timestamp);
        dynamicFeeBasisPoints = 50; // 0.5% default fee

        // Set initial phase 1 parameters (example values)
        phaseConfigs[1] = PhaseConfig({
            stakingRewardRatePerSecondCT: 1000, // 1000 * 1e18 rewards per sec per staked token
            baseCraftingFeeCT: 100 * (10**18), // 100 CT
            baseCraftingFeeES: 1, // 1 ES (conceptual, depends on how ES ingredients/fees are handled)
            dynamicFeeMultiplier: 1, // No multiplier initially
            minTotalStakedForAdvance: 500_000 * (10**18), // 500k CT staked
            minTotalCraftedForAdvance: 100 // 100 ES crafted
        });

        // Note: ERC721Enumerable requires overrides for _beforeTokenTransfer, _afterTokenTransfer, supportsInterface
    }

    // --- Overrides for ERC721Enumerable ---

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);

        // Handle unstaking if a staked NFT is transferred
        if (_nftStakingPoolES[tokenId].user != address(0) && from != address(0)) {
             // This should not happen if we prevent transfers of staked NFTs,
             // but adding a safeguard or adjusting design is needed if transfers of staked are allowed.
             // Let's assume transferring a staked NFT is disallowed implicitly by requiring ownership for transfer.
             // If the owner transfers it, it must first be unstaked.
             // This override is more for _mint and _burn.
             delete _nftStakingPoolES[tokenId];
             uint256 userIndex = _stakedEssenceShardToIndex[tokenId];
             uint256 lastIndex = _stakedEssenceShardsByUser[from].length - 1;
             uint256 lastTokenId = _stakedEssenceShardsByUser[from][lastIndex];
             _stakedEssenceShardsByUser[from][userIndex] = lastTokenId;
             _stakedEssenceShardsByUser[from].pop();
             delete _stakedEssenceShardToIndex[tokenId];
             emit EssenceShardUnstaked(from, tokenId); // Indicate it was unstaked
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Calculation Helpers ---

    /// @dev Updates the reward variables for the staking pool and user.
    function _updateStakingRewardsCT(address user) internal {
        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - _lastRewardUpdateTimeCT;

        if (timeElapsed > 0 && totalStakedTokensCT > 0) {
            uint256 rewards = totalStakedTokensCT * timeElapsed * phaseConfigs[currentPhase].stakingRewardRatePerSecondCT;
            _cumulativeRewardPerTokenCT += (rewards / totalStakedTokensCT);
        }
        _lastRewardUpdateTimeCT = currentTime;

        if (user != address(0)) {
            StakingPositionCT storage position = _stakingPoolCT[user];
            position.rewardDebt = (_stakingPoolCT[user].amount * _cumulativeRewardPerTokenCT) / (10**18); // Assume CT has 18 decimals
        }
    }

    /// @dev Calculates the pending staking rewards for a user.
    function _calculatePendingRewardsCT(address user) internal view returns (uint256) {
        StakingPositionCT storage position = _stakingPoolCT[user];
        uint256 currentCumulativeRewardPerToken = _cumulativeRewardPerTokenCT;
        uint40 currentTime = uint40(block.timestamp);
        uint256 timeElapsed = currentTime - _lastRewardUpdateTimeCT;

         if (timeElapsed > 0 && totalStakedTokensCT > 0) {
            uint256 rewards = totalStakedTokensCT * timeElapsed * phaseConfigs[currentPhase].stakingRewardRatePerSecondCT;
            currentCumulativeRewardPerToken += (rewards / totalStakedTokensCT);
        }

        uint256 pending = (position.amount * currentCumulativeRewardPerToken) / (10**18);
        if (pending > position.rewardDebt) {
            return pending - position.rewardDebt;
        } else {
            return 0;
        }
    }

    /// @dev Calculates the dynamic fee for a given amount.
    function _calculateDynamicFee(uint256 amount) internal view returns (uint256) {
        uint256 effectiveFeeBasisPoints = dynamicFeeBasisPoints;
        // Apply phase multiplier and oracle value (simple example)
        effectiveFeeBasisPoints = (effectiveFeeBasisPoints * phaseConfigs[currentPhase].dynamicFeeMultiplier) / 1e18; // Assuming multiplier is 1e18 scaled
        effectiveFeeBasisPoints = (effectiveFeeBasisPoints * oracleValue) / 1e18; // Assuming oracleValue is 1e18 scaled

        // Ensure fee doesn't exceed 100% (10000 basis points)
        effectiveFeeBasisPoints = effectiveFeeBasisPoints > 10000 ? 10000 : effectiveFeeBasisPoints;

        return (amount * effectiveFeeBasisPoints) / 10000; // Fee in basis points
    }

    // --- ERC-20 Overrides for Dynamic Fees ---

    // Override ERC20 transfer to potentially apply fees
    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 fee = _calculateDynamicFee(amount);
        uint256 amountToSend = amount - fee;

        _updateStakingRewardsCT(msg.sender); // Update rewards before balance changes
        _updateStakingRewardsCT(recipient); // Update rewards for recipient if they are staking

        address sender = _msgSender();
        _transfer(sender, address(this), fee); // Send fee to contract (can be burned or distributed)
        _transfer(sender, recipient, amountToSend);

        emit TokensBurned(address(0), fee); // Indicate fees are collected (or burned implicitly)

        return true;
    }

    // Override ERC20 transferFrom to potentially apply fees
    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
         uint256 fee = _calculateDynamicFee(amount);
         uint256 amountToSend = amount - fee;

        _updateStakingRewardsCT(sender); // Update rewards before balance changes
        _updateStakingRewardsCT(recipient); // Update rewards for recipient if they are staking

        _transfer(sender, address(this), fee); // Send fee to contract
        _transfer(sender, recipient, amountToSend);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        emit TokensBurned(address(0), fee); // Indicate fees are collected (or burned implicitly)

        return true;
    }

    // --- Core Dynamic Phase System Functions ---

    /// @notice Owner defines the parameters for a specific phase.
    /// @param phase The phase number (e.g., 1, 2, 3).
    /// @param stakingRewardRatePerSecond The reward rate per second per staked CT unit (scaled by 1e18).
    /// @param baseCraftingFeeCT The base CT fee for crafting in this phase.
    /// @param baseCraftingFeeES The base number of ES tokens potentially required as a fee for crafting in this phase.
    /// @param dynamicFeeMultiplier A multiplier for the dynamic fee basis points (scaled by 1e18).
    /// @param minTotalStakedForAdvance Threshold of total staked CT for auto phase advance.
    /// @param minTotalCraftedForAdvance Threshold of total crafted ES for auto phase advance.
    function setPhaseConfig(
        uint256 phase,
        uint256 stakingRewardRatePerSecond,
        uint256 baseCraftingFeeCT,
        uint256 baseCraftingFeeES,
        uint256 dynamicFeeMultiplier,
        uint256 minTotalStakedForAdvance,
        uint256 minTotalCraftedForAdvance
    ) external onlyOwner {
        require(phase > 0, "CSC: Invalid phase");
        phaseConfigs[phase] = PhaseConfig({
            stakingRewardRatePerSecondCT: stakingRewardRatePerSecond,
            baseCraftingFeeCT: baseCraftingFeeCT,
            baseCraftingFeeES: baseCraftingFeeES,
            dynamicFeeMultiplier: dynamicFeeMultiplier,
            minTotalStakedForAdvance: minTotalStakedForAdvance,
            minTotalCraftedForAdvance: minTotalCraftedForAdvance
        });
    }

    /// @notice Owner manually advances the contract to the next phase.
    /// @dev Can only advance one phase at a time.
    function advancePhase() external onlyOwner whenNotPaused {
        uint256 oldPhase = currentPhase;
        currentPhase++;
        _lastRewardUpdateTimeCT = uint40(block.timestamp); // Reset reward timer for new phase rate
        emit PhaseChanged(oldPhase, currentPhase);
    }

    /// @notice Checks if auto-advance criteria for the current phase are met and advances if so.
    /// @dev This function can be called by anyone, but only results in a phase change if conditions are met.
    function checkAndAutoAdvancePhase() public whenNotPaused {
        PhaseConfig storage config = phaseConfigs[currentPhase];
        // Check if the next phase is configured (prevents advancing past the last defined phase)
        if (phaseConfigs[currentPhase + 1].stakingRewardRatePerSecondCT == 0 && phaseConfigs[currentPhase + 1].baseCraftingFeeCT == 0) {
            // Next phase config doesn't exist, no auto-advance possible
            return;
        }

        bool stakedConditionMet = totalStakedTokensCT >= config.minTotalStakedForAdvance && config.minTotalStakedForAdvance > 0;
        bool craftedConditionMet = totalEssenceShardsCrafted >= config.minTotalCraftedForAdvance && config.minTotalCraftedForAdvance > 0;

        // Auto-advance if AT LEAST ONE condition is defined and met
        if ((config.minTotalStakedForAdvance == 0 || stakedConditionMet) && (config.minTotalCraftedForAdvance == 0 || craftedConditionMet)) {
             if (config.minTotalStakedForAdvance > 0 || config.minTotalCraftedForAdvance > 0) { // Ensure at least one condition was meant to trigger auto-advance
                uint256 oldPhase = currentPhase;
                currentPhase++;
                _lastRewardUpdateTimeCT = uint40(block.timestamp); // Reset reward timer
                emit PhaseChanged(oldPhase, currentPhase);
             }
        }
    }

    /// @notice Get the current phase index.
    function getCurrentPhase() public view returns (uint256) {
        return currentPhase;
    }

     /// @notice Get the configuration parameters for a specific phase.
     /// @param phase The phase number.
    function getPhaseConfig(uint256 phase) public view returns (PhaseConfig memory) {
        return phaseConfigs[phase];
    }


    // --- Staking (ChronoTokens) Functions ---

    /// @notice Stakes a specified amount of ChronoTokens.
    /// @param amount The amount of $CT to stake.
    function stakeTokens(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "CSC: Amount must be > 0");

        _updateStakingRewardsCT(msg.sender);

        StakingPositionCT storage position = _stakingPoolCT[msg.sender];
        if (position.amount == 0) {
             position.startTime = uint40(block.timestamp);
        }
        position.amount += amount;
        position.rewardDebt = (position.amount * _cumulativeRewardPerTokenCT) / (10**18); // Update reward debt based on new amount

        totalStakedTokensCT += amount;
        _transfer(msg.sender, address(this), amount); // Transfer tokens to contract

        emit TokensStaked(msg.sender, amount);
    }

    /// @notice Unstakes all of the caller's ChronoTokens and claims pending rewards.
    function unstakeTokens() external nonReentrant whenNotPaused {
        StakingPositionCT storage position = _stakingPoolCT[msg.sender];
        require(position.amount > 0, "CSC: No tokens staked");

        _updateStakingRewardsCT(msg.sender);

        uint256 pendingRewards = _calculatePendingRewardsCT(msg.sender);
        uint256 stakedAmount = position.amount;

        totalStakedTokensCT -= stakedAmount;
        delete _stakingPoolCT[msg.sender]; // Reset position

        _transfer(address(this), msg.sender, stakedAmount); // Return staked tokens
        if (pendingRewards > 0) {
            _mint(msg.sender, pendingRewards); // Mint and send rewards
            emit StakingRewardsClaimed(msg.sender, pendingRewards);
        }

        emit TokensUnstaked(msg.sender, stakedAmount);
    }

    /// @notice Claims pending ChronoToken staking rewards without unstaking.
    function claimStakingRewards() external nonReentrant whenNotPaused {
        StakingPositionCT storage position = _stakingPoolCT[msg.sender];
        require(position.amount > 0, "CSC: No tokens staked");

        _updateStakingRewardsCT(msg.sender);

        uint256 pendingRewards = _calculatePendingRewardsCT(msg.sender);
        if (pendingRewards > 0) {
             _mint(msg.sender, pendingRewards); // Mint and send rewards
             position.rewardDebt = (position.amount * _cumulativeRewardPerTokenCT) / (10**18); // Update reward debt after claiming
             emit StakingRewardsClaimed(msg.sender, pendingRewards);
        }
    }

    /// @notice Gets the amount of ChronoTokens staked by a user.
    /// @param user The address of the user.
    /// @return The staked amount.
    function getStakingBalance(address user) public view returns (uint256) {
        return _stakingPoolCT[user].amount;
    }

    /// @notice Gets the pending ChronoToken staking rewards for a user.
    /// @param user The address of the user.
    /// @return The pending reward amount.
    function getPendingStakingRewards(address user) public view returns (uint256) {
        return _calculatePendingRewardsCT(user);
    }

    /// @notice Gets the total amount of ChronoTokens staked across all users.
    function getTotalStakedTokens() public view returns (uint256) {
        return totalStakedTokensCT;
    }

    // --- Staking (Essence Shards) Functions ---

    /// @notice Stakes an Essence Shard NFT.
    /// @param tokenId The ID of the Essence Shard to stake.
    function stakeEssenceShard(uint256 tokenId) external nonReentrant whenNotPaused {
        require(_exists(tokenId), "CSC: ES does not exist");
        require(ownerOf(tokenId) == msg.sender, "CSC: Not owner of ES");
        require(_nftStakingPoolES[tokenId].user == address(0), "CSC: ES already staked");

        // Transfer NFT to the contract
        super.safeTransferFrom(msg.sender, address(this), tokenId);

        _nftStakingPoolES[tokenId] = StakingPositionES({
            startTime: uint40(block.timestamp),
            user: msg.sender
        });

        // Add to user's staked list
        _stakedEssenceShardsByUser[msg.sender].push(tokenId);
        _stakedEssenceShardToIndex[tokenId] = _stakedEssenceShardsByUser[msg.sender].length - 1;

        emit EssenceShardStaked(msg.sender, tokenId);
    }

    /// @notice Unstakes an Essence Shard NFT.
    /// @param tokenId The ID of the Essence Shard to unstake.
    function unstakeEssenceShard(uint256 tokenId) external nonReentrant whenNotPaused {
        StakingPositionES storage position = _nftStakingPoolES[tokenId];
        require(position.user == msg.sender, "CSC: Not staked by user");
        require(_exists(tokenId), "CSC: ES does not exist (unexpected)"); // Should exist if staked

        // Transfer NFT back to the user
        super.safeTransferFrom(address(this), msg.sender, tokenId);

        // Remove from state
        delete _nftStakingPoolES[tokenId];

        // Remove from user's staked list (efficient removal)
        uint256 userIndex = _stakedEssenceShardToIndex[tokenId];
        uint256 lastIndex = _stakedEssenceShardsByUser[msg.sender].length - 1;
        uint256 lastTokenId = _stakedEssenceShardsByUser[msg.sender][lastIndex];

        _stakedEssenceShardsByUser[msg.sender][userIndex] = lastTokenId;
        _stakedEssenceShardsByUser[msg.sender].pop();
        delete _stakedEssenceShardToIndex[tokenId];

        // Potential: Add reward logic for NFT staking here if desired
        // E.g., based on stake duration, phase, or specific NFT properties

        emit EssenceShardUnstaked(msg.sender, tokenId);
    }

     /// @notice Checks if an Essence Shard is currently staked in the contract.
     /// @param tokenId The ID of the Essence Shard.
     /// @return True if staked, false otherwise.
    function isEssenceShardStaked(uint256 tokenId) public view returns (bool) {
        return _nftStakingPoolES[tokenId].user != address(0);
    }

    /// @notice Gets the list of Essence Shard token IDs staked by a user.
    /// @param user The address of the user.
    /// @return An array of staked token IDs.
    function getStakedEssenceShards(address user) public view returns (uint256[] memory) {
        return _stakedEssenceShardsByUser[user];
    }

    /// @notice Gets the timestamp when an Essence Shard was staked.
    /// @param tokenId The ID of the Essence Shard.
    /// @return The staking start timestamp (0 if not staked).
    function getEssenceShardStakingTime(uint256 tokenId) public view returns (uint40) {
        return _nftStakingPoolES[tokenId].startTime;
    }


    // --- Crafting/Synthesis Functions ---

    /// @notice Owner defines a crafting recipe.
    /// @param recipeId A unique ID for the recipe.
    /// @param tokenIngredients Addresses of required token ingredients (e.g., CT).
    /// @param tokenAmounts Amounts of required token ingredients.
    /// @param essenceShardIngredients List of Essence Shard type IDs required (e.g., [1, 2] requires one ES type 1 and one ES type 2).
    /// @param outputEssenceShardId The type/ID of the Essence Shard produced.
    /// @param phaseDependent If true, this recipe is only available in the current phase.
    function defineCraftingRecipe(
        uint256 recipeId,
        address[] calldata tokenIngredients,
        uint256[] calldata tokenAmounts,
        uint256[] calldata essenceShardIngredients,
        uint256 outputEssenceShardId,
        bool phaseDependent
    ) external onlyOwner {
        require(recipeId > 0, "CSC: Invalid recipe ID");
        require(outputEssenceShardId > 0, "CSC: Invalid output ES ID");
        require(tokenIngredients.length == tokenAmounts.length, "CSC: Ingredients length mismatch");
        // Basic validation, more complex validation (e.g., unique recipe IDs) can be added

        craftingRecipes[recipeId] = Recipe({
            tokenIngredients: tokenIngredients,
            tokenAmounts: tokenAmounts,
            essenceShardIngredients: essenceShardIngredients,
            outputEssenceShardId: outputEssenceShardId,
            phaseDependent: phaseDependent
        });

        emit RecipeDefined(recipeId, outputEssenceShardId);
    }

    /// @notice Executes a crafting recipe, consuming ingredients and minting the output Essence Shard.
    /// @param recipeId The ID of the recipe to craft.
    function craftEssenceShard(uint256 recipeId) external nonReentrant whenNotPaused {
        Recipe storage recipe = craftingRecipes[recipeId];
        require(recipe.outputEssenceShardId > 0, "CSC: Recipe not defined"); // Check if recipe exists

        // Check phase dependency
        if (recipe.phaseDependent) {
            // We need to store which phase the recipe was defined in to check dependency
            // Let's assume a simple mapping or store phase in the recipe struct if needed.
            // For now, assume phaseDependent means "only in phase X", and X is fixed or stored.
            // A simpler interpretation: 'phaseDependent: true' means it's only available in the *current* phase it was defined.
            // This requires storing the definition phase. Let's add a mapping: recipeId => definitionPhase.
            // For this example, let's just check against currentPhase IF phaseDependent is true.
            // A robust system would need to store the definition phase. Let's skip that complexity for now
            // and simply enforce that if phaseDependent is true, the recipe must be defined for *this* phase.
            // This implies `setPhaseConfig` should be called BEFORE `defineCraftingRecipe` for phase-dependent recipes.
             // A better simple approach: phase dependent means "defined in this phase and only available in this phase".
             // This requires storing the phase the recipe was defined in. Let's quickly add that.
             // Add `mapping(uint256 => uint256) private _recipeDefinitionPhase;`
             // Update `defineCraftingRecipe`: `_recipeDefinitionPhase[recipeId] = currentPhase;`
             // Update `craftEssenceShard`: `require(!recipe.phaseDependent || _recipeDefinitionPhase[recipeId] == currentPhase, "CSC: Recipe not available in this phase");`
             // Let's implement this.

             // Added _recipeDefinitionPhase mapping and updated defineCraftingRecipe.
             require(!recipe.phaseDependent || _recipeDefinitionPhase[recipeId] == currentPhase, "CSC: Recipe not available in this phase");
        }


        // --- Consume Token Ingredients ---
        PhaseConfig storage currentConfig = phaseConfigs[currentPhase];
        uint256 ctFee = currentConfig.baseCraftingFeeCT;
        if (ctFee > 0) {
             uint256 fee = _calculateDynamicFee(ctFee);
             require(balanceOf(msg.sender) >= fee, "CSC: Insufficient CT for fee");
             _transfer(msg.sender, address(this), fee); // Collect fee
             emit TokensBurned(address(0), fee); // Indicate fee collection/burning
        }

        for (uint i = 0; i < recipe.tokenIngredients.length; i++) {
            address tokenAddress = recipe.tokenIngredients[i];
            uint256 amount = recipe.tokenAmounts[i];
            require(amount > 0, "CSC: Invalid token amount in recipe");

            // If the ingredient is ChronoTokens, handle balance check and transfer
            if (tokenAddress == address(this)) {
                require(balanceOf(msg.sender) >= amount, "CSC: Insufficient CT ingredient");
                _transfer(msg.sender, address(this), amount);
            } else {
                // Assume other ingredients are standard ERC20s
                IERC20 ingredientToken = IERC20(tokenAddress);
                require(ingredientToken.balanceOf(msg.sender) >= amount, "CSC: Insufficient ERC20 ingredient");
                ingredientToken.transferFrom(msg.sender, address(this), amount); // Requires caller to approve contract
            }
        }

        // --- Consume Essence Shard Ingredients ---
        uint256 esFee = currentConfig.baseCraftingFeeES;
        if (esFee > 0) {
             // This fee mechanism based on a count is simple.
             // A more complex one might require specific ES token IDs or types as a fee.
             // For this example, let's assume `essenceShardIngredients` lists the *types* required,
             // and `esFee` represents an *additional* number of *any* ES to burn as a fee, OR `essenceShardIngredients` *are* the fee ingredients.
             // Let's clarify: `essenceShardIngredients` ARE the specific *types* of ES required inputs.
             // `baseCraftingFeeES` could be an *additional* CT fee per ES ingredient, or maybe not used this way.
             // Let's refine the Recipe struct:
             // `struct Recipe { ... uint256[] essenceShardIngredientTypes; ... }`
             // And users provide the *actual token IDs* they want to use.
             // This means the function signature needs token IDs: `craftEssenceShard(uint256 recipeId, uint256[] calldata essenceShardTokenIds)`
             // Let's refactor the crafting function and recipe struct slightly for clarity.

             // Refactoring:
             // Recipe struct now has `essenceShardIngredientTypes`.
             // `craftEssenceShard` takes `essenceShardTokenIdsToUse`.
             // We need to validate that the provided `essenceShardTokenIdsToUse` match the required types and belong to the user.
             // The `baseCraftingFeeES` can be interpreted as a *required number of ES tokens* to burn as a fee, separate from ingredients.
             // Let's use `essenceShardIngredientTypes` for inputs that are consumed *as inputs* and an optional separate array for *fee* ES token IDs.
             // Or, simpler: just use `essenceShardIngredientTypes` as the inputs, and the CT fee is the only fee. Let's stick to that.

             // Back to logic after refactoring thought:
             // Check required ES ingredients
             require(msg.sender == tx.origin, "CSC: Crafting not allowed from contracts due to token ID consumption logic"); // Prevent simple reentrancy/complex interaction issues
             // The caller needs to OWN the required ES token IDs.
             // The recipe lists `essenceShardIngredientTypes`. How does the user provide the actual IDs?
             // Option 1: User specifies IDs in `craftEssenceShard(recipeId, uint256[] calldata essenceShardTokenIds)`. Contract verifies types and ownership.
             // Option 2: Contract automatically finds suitable ES owned by user (less flexible).
             // Option 1 is more common and safer. Let's modify `craftEssenceShard` signature.

             // Modified `craftEssenceShard` signature above.
             // Now, check provided token IDs against recipe requirements and ownership.
             // This is getting complex. Let's simplify the recipe definition and crafting slightly for this example.
             // Assume `essenceShardIngredients` lists the *number* of ES *of certain types* required.
             // Example: `essenceShardIngredients = [1, 1]` means 2 ES of type 1 are needed.
             // The user must provide the *actual token IDs* in the function call.
             // We'll need a way to check the *type* of an ES token ID. This implies ES NFTs must store their type.
             // Let's add a mapping `_essenceShardTypes: mapping(uint256 => uint256);` where key is tokenId, value is typeId.
             // This type ID is set when the ES is minted (including crafted ones).
             // When crafting, we need to verify the provided token IDs match the required types and quantities.

             // This check is getting too verbose for the summary, but the logic would be:
             // 1. User calls `craftEssenceShard(recipeId, uint256[] calldata essenceShardTokenIdsToUse)`
             // 2. Verify `essenceShardTokenIdsToUse.length` matches sum of quantities implied by `recipe.essenceShardIngredientTypes`.
             // 3. Verify each token ID in `essenceShardTokenIdsToUse` is owned by `msg.sender`.
             // 4. Verify the `_essenceShardTypes` of these tokens match the required types from `recipe.essenceShardIngredientTypes` (counting occurrences).
             // 5. Transfer/burn these ES NFTs to the contract.

             // Let's implement a simplified version: `essenceShardIngredients` is just a list of required TYPE IDs. User provides one of EACH type ID.
             // `craftEssenceShard(recipeId, uint256[] calldata essenceShardTokenIdsToUse)` where `essenceShardTokenIdsToUse.length == recipe.essenceShardIngredients.length`.

             require(recipe.essenceShardIngredients.length == essenceShardTokenIdsToUse.length, "CSC: Incorrect number of ES ingredients provided");

             // Create copies to prevent re-entrancy issues if IERC721.safeTransferFrom had unexpected side effects (though unlikely)
             uint256[] memory tokenIdsToBurn = new uint256[](essenceShardTokenIdsToUse.length);
             for(uint i=0; i < essenceShardTokenIdsToUse.length; i++) {
                 uint256 tokenId = essenceShardTokenIdsToUse[i];
                 require(ownerOf(tokenId) == msg.sender, "CSC: Caller does not own ES ingredient");
                 // Need to check type matches recipe requirement - requires _essenceShardTypes mapping
                 // require(_essenceShardTypes[tokenId] == recipe.essenceShardIngredients[i], "CSC: ES ingredient type mismatch"); // Assuming ingredientTypes is ordered

                 // Simpler implementation: Just burn the required number of *any* ES.
                 // Let's revert to the original simpler idea: `essenceShardIngredients` lists required TYPES. User provides tokens matching those types.
                 // Okay, let's stick to the original plan: `essenceShardIngredients` *are* the required *types*. User provides the *token IDs*.

                 // Let's skip the complex type matching for this example to keep it under control.
                 // Assume `essenceShardIngredients` in the recipe is just a placeholder or implies a *number* of ES needed.
                 // Let's go back to `craftEssenceShard(uint256 recipeId)`.
                 // And the recipe needs a `numEssenceShardsRequired` field.
                 // The user must have APPROVED the contract to take `numEssenceShardsRequired` from them.

                 // Let's refactor recipe struct again. Simplified ingredients.
                 // `struct Recipe { ... uint256 numEssenceShardsRequired; ... }`
                 // `craftEssenceShard(uint256 recipeId)`

                 // Check if user has approved sufficient ES for the contract to take
                 uint256 numRequiredES = recipe.numEssenceShardsRequired;
                 if (numRequiredES > 0) {
                     // This is tricky with ERC721. There's no `transferFrom` with count.
                     // A user would need to *approve* the contract for each individual NFT, or setApprovalForAll.
                     // `setApprovalForAll` is the standard way.
                     // We need to take *any* `numRequiredES` tokens from the user. This needs to be handled carefully.
                     // The user must *send* the required NFTs *to the contract* before calling `craftEssenceShard`.
                     // Or, the contract takes them using `transferFrom` after `setApprovalForAll`.

                     // Let's require `setApprovalForAll(address(this), true)` from the user and take the NFTs.
                     // We'll need to track which of the user's NFTs to take. This adds significant complexity.

                     // Alternative simpler crafting: User pays CT + burns X *any* ES NFTs.
                     // Let's use `burnEssenceShardForCrafting` as a helper called BY `craftEssenceShard`.
                     // The recipe will define `uint256 numEssenceShardsToBurn`.
                     // `craftEssenceShard(recipeId, uint256[] calldata essenceShardTokenIdsToBurn)`

                     // Let's go with: Recipe defines token ingredients + amounts, and an array of *required ES type IDs*.
                     // User provides the recipe ID and the *list of actual ES token IDs* to use as ingredients.
                     // `struct Recipe { ... uint256[] requiredEssenceShardTypes; uint256 outputEssenceShardId; }`
                     // `craftEssenceShard(uint256 recipeId, uint256[] calldata essenceShardTokenIdsToUse)`
                     // This still requires storing ES types `mapping(uint256 => uint256) private _essenceShardTypes;`

                     // Okay, adding `_essenceShardTypes` and updating crafting.
                     // Recipe struct: `uint256[] requiredEssenceShardTypes;`
                     // `craftEssenceShard` parameter: `uint256[] calldata essenceShardTokenIdsToUse`
                     // Need to ensure lengths match, check ownership, check types, then burn.

                     // Check number of ES ingredients provided
                     require(recipe.requiredEssenceShardTypes.length == essenceShardTokenIdsToUse.length, "CSC: Incorrect number of ES ingredients provided");

                     // Verify ownership and types of provided ES tokens, then burn them
                     // Using a temporary mapping to count provided types for verification
                     mapping(uint256 => uint256) private providedEsTypes;
                     for(uint i=0; i < essenceShardTokenIdsToUse.length; i++) {
                         uint256 tokenId = essenceShardTokenIdsToUse[i];
                         require(ownerOf(tokenId) == msg.sender, "CSC: Caller does not own ES ingredient");
                         require(!isEssenceShardStaked(tokenId), "CSC: Cannot use staked ES as ingredient");
                         // Burn the token
                         _burn(tokenId); // This also handles removal from ERC721Enumerable and potentially staking
                         providedEsTypes[_essenceShardTypes[tokenId]]++;
                         emit EssenceShardBurned(msg.sender, tokenId);
                     }

                     // Verify provided types match required types (counts must be equal)
                     mapping(uint256 => uint256) private requiredEsTypes;
                     for(uint i=0; i < recipe.requiredEssenceShardTypes.length; i++) {
                         requiredEsTypes[recipe.requiredEssenceShardTypes[i]]++;
                     }

                     // Compare maps - Iterate through required types and check if provided counts match
                     for (uint i = 0; i < recipe.requiredEssenceShardTypes.length; i++) {
                        uint256 requiredType = recipe.requiredEssenceShardTypes[i];
                        require(providedEsTypes[requiredType] == requiredEsTypes[requiredType], "CSC: ES ingredient type or count mismatch");
                     }
                     // Need to also check if any *extra* types were provided - iterate through providedTypes keys... complicated.
                     // Simpler: Sort both lists of types and compare element by element. Sorting on-chain is expensive.
                     // Let's assume the recipe's `requiredEssenceShardTypes` is already sorted and the user provides token IDs corresponding to that sorted list.
                     // Requires careful recipe definition and user input.

                     // Simplified check: Just check counts of required types. Does NOT prevent user adding extra *wrong* types.
                     // Let's trust the user provides exactly the expected types based on the recipe's definition order.
                     for(uint i=0; i < essenceShardTokenIdsToUse.length; i++) {
                         uint256 tokenId = essenceShardTokenIdsToUse[i];
                         require(_essenceShardTypes[tokenId] == recipe.requiredEssenceShardTypes[i], "CSC: ES ingredient type mismatch at position");
                     }
                     // This relies on the user ordering their input `essenceShardTokenIdsToUse` exactly as `recipe.requiredEssenceShardTypes` is ordered. Risky UX.

                     // FINAL SIMPLIFIED APPROACH for ingredients: Recipe needs N tokens of Type A, M tokens of Type B. User provides a LIST of token IDs.
                     // Contract verifies: user owns all provided IDs, none are staked, total count is N+M, and the count of Type A IDs matches N, count of Type B IDs matches M, etc.
                     // Then burns them.

                     // Let's go with this final approach. This means the recipe struct should store required types AND counts.
                     // `struct Recipe { ... uint256[] requiredEssenceShardTypes; uint256[] requiredEssenceShardCounts; ... }`
                     // `craftEssenceShard(uint256 recipeId, uint256[] calldata essenceShardTokenIdsToUse)`
                     // Check `requiredEssenceShardTypes.length == requiredEssenceShardCounts.length`.
                     // Check total count of `essenceShardTokenIdsToUse.length` matches sum of `requiredEssenceShardCounts`.
                     // Then check individual types and counts.

                     // Let's skip the full implementation of the complex ES ingredient logic here to keep the contract length manageable.
                     // Assume for the function summary that `craftEssenceShard` handles ingredient burning correctly based on a defined recipe.
                     // The current implementation placeholder focuses on fees and output.

                     // Minimal implementation check: check required number of ES.
                     // require(essenceShardTokenIdsToUse.length == recipe.requiredEssenceShardCounts.length, "CSC: Incorrect number of ES ingredient types"); // Check number of *types*
                     // uint totalRequiredES = 0;
                     // for(uint i=0; i < recipe.requiredEssenceShardCounts.length; i++) {
                     //    totalRequiredES += recipe.requiredEssenceShardCounts[i];
                     // }
                     // require(essenceShardTokenIdsToUse.length == totalRequiredES, "CSC: Incorrect total number of ES ingredients"); // Check total number of tokens
                     // ... then the type/count matching logic using _essenceShardTypes and provided tokenIdsToUse.

                     // Let's go back to the simplest: recipe requires CT + burns X *any* ES.
                     // Requires `struct Recipe { ... uint256 numEssenceShardsToBurn; ... }`
                     // `craftEssenceShard(uint256 recipeId, uint256[] calldata essenceShardTokenIdsToBurn)` where `essenceShardTokenIdsToBurn.length == recipe.numEssenceShardsToBurn`.

                     // Check number of ES to burn
                     require(essenceShardTokenIdsToBurn.length == recipe.numEssenceShardsToBurn, "CSC: Incorrect number of ES to burn");

                     // Burn provided ES tokens
                      for(uint i=0; i < essenceShardTokenIdsToBurn.length; i++) {
                         uint256 tokenId = essenceShardTokenIdsToBurn[i];
                         require(ownerOf(tokenId) == msg.sender, "CSC: Caller does not own ES to burn");
                         require(!isEssenceShardStaked(tokenId), "CSC: Cannot burn staked ES");
                         _burn(tokenId); // This handles removal from ERC721Enumerable and potentially staking state
                         emit EssenceShardBurned(msg.sender, tokenId);
                     }
                 }


                 // --- Mint Output Essence Shard ---
                 _currentTokenId.increment();
                 uint256 newItemId = _currentTokenId.current();
                 uint256 outputTypeId = recipe.outputEssenceShardId; // Use the recipe's output ID as the new token's type

                 _safeMint(msg.sender, newItemId);
                 _essenceShardTypes[newItemId] = outputTypeId; // Store the type of the new token

                 totalEssenceShardsCrafted++; // Increment counter for auto phase advance

                 emit EssenceShardMinted(msg.sender, newItemId, recipeId);
             }

             // Refactoring `craftEssenceShard` signature and recipe struct to include `essenceShardTokenIdsToBurn` and `numEssenceShardsToBurn`.
             // Adding `mapping(uint256 => uint256) private _essenceShardTypes;` to store type of each minted ES.
             // Need to update `defineCraftingRecipe` to set `numEssenceShardsToBurn` and `requiredEssenceShardTypes`/`requiredEssenceShardCounts` if we use that model.
             // Let's refine the recipe struct once more for simplicity:
             // `struct Recipe { address[] tokenIngredients; uint256[] tokenAmounts; uint256 numEssenceShardsToBurn; uint256 outputEssenceShardId; bool phaseDependent; }`
             // `craftEssenceShard(uint256 recipeId, uint256[] calldata essenceShardTokenIdsToBurn)`

             struct Recipe {
                address[] tokenIngredients;
                uint256[] tokenAmounts;
                uint256 numEssenceShardsToBurn; // Number of *any* ES tokens the user must burn
                uint256 outputEssenceShardId;   // The type/ID of the ES token to mint
                bool phaseDependent;            // If true, only available in the phase it was defined
             }

             // State variable to store definition phase for phase-dependent recipes
             mapping(uint256 => uint256) private _recipeDefinitionPhase;
             // State variable to store the type of each ES token
             mapping(uint256 => uint224) private _essenceShardTypes; // Use a smaller type if type IDs are small

             // --- Constructor Update ---
             // Add `_essenceShardTypes[0] = 0;` or some indicator for unassigned/zero value type if needed.

             // --- defineCraftingRecipe Update ---
             // Function signature: `defineCraftingRecipe(uint256 recipeId, address[] calldata tokenIngredients, uint256[] calldata tokenAmounts, uint256 numEssenceShardsToBurn, uint256 outputEssenceShardId, bool phaseDependent)`
             function defineCraftingRecipe(
                 uint256 recipeId,
                 address[] calldata tokenIngredients,
                 uint256[] calldata tokenAmounts,
                 uint256 numEssenceShardsToBurn, // Added parameter
                 uint256 outputEssenceShardId,
                 bool phaseDependent
             ) external onlyOwner {
                 require(recipeId > 0, "CSC: Invalid recipe ID");
                 require(outputEssenceShardId > 0, "CSC: Invalid output ES ID");
                 require(tokenIngredients.length == tokenAmounts.length, "CSC: Ingredients length mismatch");
                 // Optional: Check that outputEssenceShardId is a valid *type* ID range if types are constrained.

                 craftingRecipes[recipeId] = Recipe({
                     tokenIngredients: tokenIngredients,
                     tokenAmounts: tokenAmounts,
                     numEssenceShardsToBurn: numEssenceShardsToBurn, // Store the number to burn
                     outputEssenceShardId: outputEssenceShardId,
                     phaseDependent: phaseDependent
                 });

                 if (phaseDependent) {
                     _recipeDefinitionPhase[recipeId] = currentPhase;
                 } else {
                     delete _recipeDefinitionPhase[recipeId]; // Not phase dependent, clear any previous phase
                 }

                 emit RecipeDefined(recipeId, outputEssenceShardId);
             }

             // --- craftEssenceShard Update ---
             // Function signature: `craftEssenceShard(uint256 recipeId, uint256[] calldata essenceShardTokenIdsToBurn)`
             function craftEssenceShard(uint256 recipeId, uint256[] calldata essenceShardTokenIdsToBurn) external nonReentrant whenNotPaused {
                 Recipe storage recipe = craftingRecipes[recipeId];
                 require(recipe.outputEssenceShardId > 0, "CSC: Recipe not defined");

                 // Check phase dependency
                 if (recipe.phaseDependent) {
                      require(_recipeDefinitionPhase[recipeId] == currentPhase, "CSC: Recipe not available in this phase");
                 }

                 // Check and Burn Essence Shard Ingredients (Simple: Any ES token IDs)
                 require(essenceShardTokenIdsToBurn.length == recipe.numEssenceShardsToBurn, "CSC: Incorrect number of ES to burn");
                 for(uint i=0; i < essenceShardTokenIdsToBurn.length; i++) {
                    uint256 tokenId = essenceShardTokenIdsToBurn[i];
                    require(ownerOf(tokenId) == msg.sender, "CSC: Caller does not own ES to burn");
                    require(!isEssenceShardStaked(tokenId), "CSC: Cannot burn staked ES");
                    _burn(tokenId); // Handles removal from ERC721Enumerable and staking state
                    emit EssenceShardBurned(msg.sender, tokenId);
                 }

                 // Consume Token Ingredients and CT Fee
                 PhaseConfig storage currentConfig = phaseConfigs[currentPhase];
                 uint256 ctFee = currentConfig.baseCraftingFeeCT;
                 if (ctFee > 0) {
                      uint256 fee = _calculateDynamicFee(ctFee);
                      require(balanceOf(msg.sender) >= fee, "CSC: Insufficient CT for fee");
                      _transfer(msg.sender, address(this), fee); // Collect fee
                      emit TokensBurned(address(0), fee); // Indicate fee collection/burning
                 }

                 for (uint i = 0; i < recipe.tokenIngredients.length; i++) {
                     address tokenAddress = recipe.tokenIngredients[i];
                     uint256 amount = recipe.tokenAmounts[i];
                     require(amount > 0, "CSC: Invalid token amount in recipe");

                     // If the ingredient is ChronoTokens, handle balance check and transfer
                     if (tokenAddress == address(this)) {
                         require(balanceOf(msg.sender) >= amount, "CSC: Insufficient CT ingredient");
                         _transfer(msg.sender, address(this), amount);
                     } else {
                         // Assume other ingredients are standard ERC20s
                         IERC20 ingredientToken = IERC20(tokenAddress);
                         require(ingredientToken.balanceOf(msg.sender) >= amount, "CSC: Insufficient ERC20 ingredient");
                         // Transfer requires caller to have approved this contract!
                         ingredientToken.transferFrom(msg.sender, address(this), amount);
                     }
                 }

                 // Mint Output Essence Shard
                 _currentTokenId.increment();
                 uint256 newItemId = _currentTokenId.current();
                 uint224 outputTypeId = uint224(recipe.outputEssenceShardId); // Cast to smaller type

                 _safeMint(msg.sender, newItemId);
                 _essenceShardTypes[newItemId] = outputTypeId; // Store the type of the new token

                 totalEssenceShardsCrafted++; // Increment counter for auto phase advance

                 emit EssenceShardMinted(msg.sender, newItemId, recipeId);
             }


             /// @notice Gets the details of a crafting recipe.
             /// @param recipeId The ID of the recipe.
             /// @return A Recipe struct containing recipe details.
            function getRecipe(uint256 recipeId) public view returns (Recipe memory) {
                return craftingRecipes[recipeId];
            }

            /// @notice Gets the output Essence Shard ID (type) for a recipe.
            /// @param recipeId The ID of the recipe.
            /// @return The output ES type ID.
            function getRecipeOutput(uint256 recipeId) public view returns (uint256) {
                return craftingRecipes[recipeId].outputEssenceShardId;
            }

            /// @notice Gets the total count of Essence Shards crafted across all recipes.
            function getTotalEssenceShardsCrafted() public view returns (uint256) {
                 return totalEssenceShardsCrafted;
            }


            // --- Burning Mechanisms Functions ---

            /// @notice Burns a specified amount of ChronoTokens owned by the caller.
            /// @param amount The amount of $CT to burn.
            function burnChronoTokens(uint256 amount) external {
                require(amount > 0, "CSC: Amount must be > 0");
                _burn(msg.sender, amount);
                emit TokensBurned(msg.sender, amount);
            }

            /// @notice Burns an Essence Shard NFT owned by the caller.
            /// @param tokenId The ID of the Essence Shard to burn.
            function burnEssenceShard(uint256 tokenId) external nonReentrant whenNotPaused {
                 require(ownerOf(tokenId) == msg.sender, "CSC: Not owner of ES");
                 require(!isEssenceShardStaked(tokenId), "CSC: Cannot burn staked ES");
                 _burn(tokenId); // Handles removal from ERC721Enumerable and staking state
                 emit EssenceShardBurned(msg.sender, tokenId);
            }


            // --- Dynamic Fees Functions ---

            /// @notice Calculates the dynamic fee for a given amount based on current phase and oracle.
            /// @param amount The amount to calculate fee for.
            /// @return The calculated fee amount.
            function getAppliedFee(uint256 amount) public view returns (uint256) {
                 return _calculateDynamicFee(amount);
            }

            /// @notice Gets the current base dynamic fee basis points.
            function getDynamicFeeBasisPoints() public view returns (uint256) {
                 return dynamicFeeBasisPoints;
            }

            /// @notice Owner sets the base dynamic fee basis points.
            /// @param feeBasisPoints The new base fee in basis points (e.g., 100 for 1%).
            function setDynamicFeeBasisPoints(uint256 feeBasisPoints) external onlyOwner {
                 require(feeBasisPoints <= 10000, "CSC: Fee cannot exceed 100%");
                 dynamicFeeBasisPoints = feeBasisPoints;
                 emit DynamicFeeUpdated(feeBasisPoints);
            }


            // --- Oracle Integration Functions ---

            /// @notice Owner sets the address of the trusted oracle contract.
            /// @param oracleAddress The address of the oracle contract.
            function setTrustedOracle(address oracleAddress) external onlyOwner {
                trustedOracle = oracleAddress;
            }

            /// @notice Allows the trusted oracle to update the oracle value.
            /// @param newValue The new value provided by the oracle.
            function updateOracleValue(uint256 newValue) external onlyTrustedOracle {
                 oracleValue = newValue;
                 emit OracleValueUpdated(newValue);
            }

            /// @notice Gets the current oracle value stored in the contract.
            function getOracleValue() public view returns (uint256) {
                return oracleValue;
            }

            // --- Achievements Functions ---

            /// @notice Owner grants an achievement to a user.
            /// @param user The address of the user.
            /// @param achievementId The ID of the achievement.
            function grantAchievement(address user, uint256 achievementId) external onlyOwner {
                 require(achievementId > 0, "CSC: Invalid achievement ID");
                 require(!achievementStatus[user][achievementId], "CSC: Achievement already granted");
                 achievementStatus[user][achievementId] = true;
                 emit AchievementGranted(user, achievementId);
            }

            /// @notice Checks if a user has been granted a specific achievement.
            /// @param user The address of the user.
            /// @param achievementId The ID of the achievement.
            /// @return True if the user has the achievement, false otherwise.
            function hasAchievement(address user, uint256 achievementId) public view returns (bool) {
                return achievementStatus[user][achievementId];
            }

            /// @notice Gets a list of achievement IDs granted to a user.
            /// @dev This requires iterating through possible achievement IDs.
            /// In a real application, a separate mapping or event history might be better for listing.
            /// For simplicity here, we'll just provide the checker `hasAchievement`. Listing is omitted due to gas costs of iteration over mappings.
            /// **Note:** This function is commented out as listing achievements efficiently is complex without additional state or events.
            // function getUserAchievements(address user) public view returns (uint256[] memory) {
            //     // This is inefficient for large numbers of achievements
            //     // Requires knowing the range of possible achievement IDs
            //     // Omitted for gas efficiency and complexity
            // }

            /// @notice User claims a reward for a specific achievement.
            /// @dev The contract needs internal logic to determine if the achievement was "earned" (based on activity counters)
            /// and what the reward is. This function only handles the claiming AFTER it's been granted.
            /// A more complete system would have internal triggers to `grantAchievement`.
            /// For this example, claiming just requires the achievement to have been `grantAchievement`-ed.
            /// The reward mechanism (e.g., minting tokens) is conceptual.
            /// @param achievementId The ID of the achievement to claim reward for.
            function claimAchievementReward(uint256 achievementId) external nonReentrant whenNotPaused {
                require(hasAchievement(msg.sender, achievementId), "CSC: Achievement not granted");
                // Prevent claiming multiple times - need a state variable for claimed status
                 mapping(address => mapping(uint256 => bool)) private _achievementClaimed; // user => achievementId => claimed

                 require(!_achievementClaimed[msg.sender][achievementId], "CSC: Reward already claimed");

                 // --- Reward Logic (Conceptual) ---
                 // Example: Mint 1000 CT for achievement 1, 5000 CT for achievement 2
                 uint256 rewardAmount = 0;
                 if (achievementId == 1) {
                      rewardAmount = 1000 * (10**18);
                 } else if (achievementId == 2) {
                      rewardAmount = 5000 * (10**18);
                 }
                 // Add more rewards for other achievementIds

                 require(rewardAmount > 0, "CSC: No reward defined for this achievement");

                 _mint(msg.sender, rewardAmount); // Mint reward tokens
                 _achievementClaimed[msg.sender][achievementId] = true; // Mark as claimed

                 emit AchievementRewardClaimed(msg.sender, achievementId);
            }

            // --- Administrative/Utility Functions ---

            /// @notice Pauses the contract, preventing most interactions.
            function pause() external onlyOwner {
                 _pause();
            }

            /// @notice Unpauses the contract, allowing interactions again.
            function unpause() external onlyOwner {
                 _unpause();
            }

            /// @notice Allows the owner to withdraw any accidental ETH sent to the contract address.
            function withdrawEth() external onlyOwner {
                 (bool success, ) = payable(owner()).call{value: address(this).balance}("");
                 require(success, "CSC: ETH withdrawal failed");
            }

            // --- ERC721Enumerable Overrides (Needed for full implementation but can be complex) ---
            // The basic ones are already handled by inheriting ERC721Enumerable and overriding _before/afterTokenTransfer.
            // Additional functions like tokenOfOwnerByIndex, tokenByIndex, totalSupply are provided by the base class.

            // --- ERC20 Overrides (Needed for full implementation but can be complex) ---
            // The basic ones are handled by inheriting ERC20 and overriding transfer/transferFrom for fees.
            // Internal _mint and _burn are used by the contract logic.
            // balanceOf, totalSupply, allowance, approve are standard.

            // Adding the missing state variables and type mapping for clarity.
            // `mapping(uint256 => uint256) private _recipeDefinitionPhase;`
            // `mapping(uint256 => uint224) private _essenceShardTypes;`
            // `mapping(address => mapping(uint256 => bool)) private _achievementClaimed;`

            // All functions listed in the summary are now present (except the commented-out `getUserAchievements`).
            // Total distinct functions are 56 (excluding the commented one). This meets the >= 20 requirement.
        }

```

**Explanation of Concepts & Advanced Features:**

1.  **Dynamic Phases (`currentPhase`, `phaseConfigs`, `setPhaseConfig`, `advancePhase`, `checkAndAutoAdvancePhase`):** This is a core advanced concept. Instead of static parameters, the ecosystem changes over time or based on reaching certain milestones (`minTotalStakedForAdvance`, `minTotalCraftedForAdvance`). This allows for planned evolution of the game/financial mechanics. `checkAndAutoAdvancePhase` can be called by anyone, incentivizing community interaction to progress the ecosystem.
2.  **Combined Staking (`stakeTokens`, `unstakeTokens`, `claimStakingRewards`, `stakeEssenceShard`, `unstakeEssenceShard`):** Two distinct staking mechanisms (ERC-20 and ERC-721) operating within the same contract, each with potentially different reward structures (implicitly, though NFT rewards are conceptualized). Token staking includes standard reward calculation (`_calculatePendingRewardsCT`, `_cumulativeRewardPerTokenCT`) while NFT staking provides utility (e.g., granting temporary traits, eligibility for other actions).
3.  **Resource Synthesis (`craftEssenceShard`, `defineCraftingRecipe`, `_essenceShardTypes`):** A complex crafting system where users consume tokens and/or NFTs to create new NFTs. The implementation involves burning input NFTs and minting output NFTs with a specific "type" recorded (`_essenceShardTypes`), which could influence their utility or dynamic properties later. Requires careful handling of ingredient ownership and burning.
4.  **Dynamic Fees (`transfer`, `transferFrom`, `getAppliedFee`, `setDynamicFeeBasisPoints`, `oracleValue`, `trustedOracle`, `updateOracleValue`):** Fees on token transfers (`transfer`, `transferFrom` overrides) are not fixed but depend on a base rate, the current phase's multiplier, and an oracle value. This allows reaction to external conditions (like network congestion via a gas oracle) or internal conditions (via phase multipliers).
5.  **Oracle Integration (`trustedOracle`, `updateOracleValue`):** The contract can receive data from a designated oracle address, directly influencing parameters like dynamic fees. This connects the on-chain logic to external real-world or blockchain data.
6.  **Self-Adjustment (via Auto-Advance):** The `checkAndAutoAdvancePhase` function provides a mechanism for the contract's state (`currentPhase`) to change based on cumulative activity metrics (`totalStakedTokensCT`, `totalEssenceShardsCrafted`).
7.  **Achievements (`grantAchievement`, `hasAchievement`, `claimAchievementReward`, `_achievementClaimed`):** A simple system to track user progress or contributions and reward them. While basic here, it demonstrates on-chain gamification elements. Requires separate state (`achievementStatus`, `_achievementClaimed`) to manage.
8.  **Inheritance and Standard Compliance:** Leverages OpenZeppelin contracts for robustness (ERC20, ERC721, Enumerable, Ownable, Pausable, ReentrancyGuard) while adding custom logic through overrides and new functions.
9.  **State Management Complexity:** The contract manages interconnected state across multiple features: token balances, NFT ownership, token staking positions, NFT staking positions, crafting recipes, phase configurations, achievement status, and counters.

This contract is more than just a token or NFT; it's a miniature ecosystem with interconnected, dynamic mechanics, aiming for creativity and advanced concepts beyond typical examples. The crafting and dynamic fee logic, combined with phase-based parameters and staking, represent significant deviations from basic token or NFT contract patterns.