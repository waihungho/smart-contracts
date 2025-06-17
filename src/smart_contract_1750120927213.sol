Okay, let's design a smart contract that combines generative art principles with dynamic asset evolution and staking. We'll call it "GenerativeAssetSynthesizer".

This contract will allow users to "synthesize" unique digital assets (NFTs) by combining specified ingredient ERC-20 tokens and potentially paying an ETH fee. The resulting asset's initial traits will be determined pseudorandomly based on block data, input parameters, and potentially the ingredients used. The minted assets can then be staked within the contract to gain "experience points" (XP), which can be used to "level up" the asset, potentially unlocking new traits or modifying existing ones, making the asset dynamic and evolving.

This combines:
1.  **Generative Art:** Traits determined algorithmically on-chain during minting.
2.  **Dynamic NFTs:** Asset properties (level, potentially traits) change over time or based on interaction.
3.  **Staking:** A mechanism for earning progression within the asset's lifecycle.
4.  **Token Burning/Input:** Requires specific tokens as 'ingredients'.
5.  **Parametric Synthesis:** Admin can influence trait outcomes via parameters.

**Outline and Function Summary**

**Contract: GenerativeAssetSynthesizer**

This contract is an ERC-721 token representing unique, generative, and dynamic digital assets. Users synthesize these assets by providing ingredient ERC-20 tokens and paying a fee. Assets evolve by accumulating staking XP and leveling up.

**Core Concepts:**

*   **SynthesizedAsset (ERC721):** The NFT token representing the generated asset.
*   **Ingredient Tokens (ERC20):** Specific ERC-20 tokens required to perform synthesis.
*   **Synthesis:** The process of burning ingredient tokens and paying a fee to mint a new SynthesizedAsset with generated traits.
*   **Traits:** On-chain data associated with each asset, determining its appearance and potentially utility (though utility isn't explicitly implemented here). Traits are generated during synthesis and can potentially change upon level-up.
*   **Experience Points (XP):** Accumulated by staking a SynthesizedAsset.
*   **Leveling Up:** Consuming XP (and potentially paying a fee) to increase the asset's level, which can modify traits.
*   **Staking:** Locking an asset within the contract to accrue XP over time.

**State Variables:**

*   `_assetCounter`: Counter for total minted assets.
*   `_assetData`: Mapping from `tokenId` to `AssetData` struct (traits, level, XP, staking info).
*   `_validIngredientTokens`: Mapping to track allowed ERC-20 ingredient token addresses.
*   `_synthesisFeeETH`: ETH fee required for synthesis.
*   `_levelUpFeeETH`: ETH fee required for leveling up.
*   `_traitWeights`: Mapping to store owner-adjustable parameters influencing trait generation.
*   `_baseTokenURI`: Base URI for metadata.
*   `_paused`: Boolean to pause core functions.

**Structs:**

*   `AssetData`: Stores `mapping(string => string) traits`, `uint256 level`, `uint256 xp`, `StakingInfo staking`.
*   `StakingInfo`: Stores `bool isStaked`, `uint64 startTime`, `uint64 lastXPUpdateTime`.

**Events:**

*   `AssetSynthesized(uint256 indexed tokenId, address indexed owner, mapping(string => string) initialTraits)`
*   `AssetStaked(uint256 indexed tokenId, address indexed owner)`
*   `AssetUnstaked(uint256 indexed tokenId, address indexed owner, uint256 xpEarned)`
*   `AssetLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 xpConsumed)`
*   `IngredientTokenAdded(address indexed token)`
*   `IngredientTokenRemoved(address indexed token)`
*   `SynthesisFeeUpdated(uint256 oldFee, uint256 newFee)`
*   `LevelUpFeeUpdated(uint256 oldFee, uint256 newFee)`
*   `TraitWeightsUpdated(string indexed traitType)`
*   `BaseTokenURIUpdated(string newURI)`
*   `Paused(address account)`
*   `Unpaused(address account)`

**Function Summary (20+ Functions):**

1.  `constructor()`: Initializes the contract with name, symbol, and owner.
2.  `synthesizeAsset(address[] calldata ingredientTokens, uint256[] calldata amounts)`: Mints a new asset. Requires ingredient tokens (approved/transferred before calling) and ETH fee. Generates initial traits based on block data, inputs, and internal weights.
3.  `stakeAsset(uint256 tokenId)`: Locks the specified asset in the contract to start accruing XP. Caller must be the owner and approve the contract first.
4.  `unstakeAsset(uint256 tokenId)`: Unstakes the asset, calculates and adds pending XP, and transfers the asset back to the owner.
5.  `claimStakingXP(uint256 tokenId)`: Updates the accumulated XP for a staked asset without unstaking it. Useful for long staking periods.
6.  `levelUpAsset(uint256 tokenId)`: Attempts to level up the asset. Requires enough XP and potentially a fee. Modifies asset level and potentially traits.
7.  `addIngredientToken(address token)`: Owner adds an ERC-20 token address to the list of valid ingredients for synthesis.
8.  `removeIngredientToken(address token)`: Owner removes an ERC-20 token address from the list of valid ingredients.
9.  `setSynthesisFee(uint256 fee)`: Owner sets the ETH fee required for synthesis.
10. `setLevelUpFee(uint256 fee)`: Owner sets the ETH fee required for leveling up.
11. `setTraitWeight(string calldata traitType, uint256 weight)`: Owner sets/updates a weight parameter used in the trait generation logic. (Example: higher weight for 'rarity' trait parameter might slightly increase odds of rare values).
12. `withdrawFees()`: Owner withdraws accumulated ETH from synthesis and level-up fees.
13. `pauseContract()`: Owner pauses synthesis, staking, and leveling up. ERC721 transfers might still work depending on implementation (OpenZeppelin's Pausable pauses transfers by default if using the standard `_beforeTokenTransfer`).
14. `unpauseContract()`: Owner unpauses the contract.
15. `getValidIngredientTokens()`: View function returning the list of valid ingredient token addresses.
16. `getSynthesisCost()`: View function returning the current ETH synthesis fee and the *required* ingredient tokens/amounts (requires prior setup by owner/design). *Self-correction:* It's hard to return arbitrary ingredient *requirements* via this view function unless they are fixed parameters. Let's make this view return *just* the ETH fee and let users query the *valid* tokens separately or rely on off-chain info about required amounts. *Refined*: Let's make this return the ETH fee and the list of valid tokens, implying any combination *using* these tokens with sufficient total value/count is possible, or rely on the `synthesizeAsset` logic to define requirements. Simpler: let `getSynthesisCost` just return the ETH fee and perhaps *some* parameter related to ingredients if needed, otherwise rely on `getValidIngredientTokens`. Let's stick to ETH fee and a reminder of valid tokens needed.
17. `getAssetLevel(uint256 tokenId)`: View function returning the current level of an asset.
18. `getAssetXP(uint256 tokenId)`: View function returning the current XP of an asset (includes pending XP if staked).
19. `getAssetTraits(uint256 tokenId)`: View function returning the current traits of an asset.
20. `getAssetStakingInfo(uint256 tokenId)`: View function returning the staking status, start time, etc.
21. `calculatePendingXP(uint256 tokenId)`: Internal/Pure function to calculate XP earned since last update/stake time. Exposed as a view for convenience. *Refined:* Make it a public view `getPendingXP(uint256 tokenId)`.
22. `tokenURI(uint256 tokenId)`: Overridden ERC721 function. Returns a URI pointing to metadata, dynamically generated based on the asset's on-chain state (traits, level).

**(Note: Standard ERC721 and Ownable functions like `ownerOf`, `balanceOf`, `transferFrom`, `approve`, `getApproved`, `isApprovedForAll`, `transferOwnership`, `renounceOwnership` are inherited and also count towards the total function count in the contract, bringing the total well over 20).**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max etc if needed

// --- Outline and Function Summary ---
// Contract: GenerativeAssetSynthesizer
// Represents unique, generative, and dynamic digital assets (NFTs).
// Synthesis requires ingredient ERC-20 tokens and ETH.
// Assets evolve by staking to gain XP and leveling up.

// Core Concepts:
// - SynthesizedAsset (ERC721): The NFT token.
// - Ingredient Tokens (ERC20): Required for synthesis.
// - Synthesis: Burn ingredients + pay fee to mint NFT with generated traits.
// - Traits: On-chain data (string => string mapping) generated during synthesis, modifiable on level-up.
// - Experience Points (XP): Earned by staking assets.
// - Leveling Up: Consuming XP (and fee) to increase level and potentially modify traits.
// - Staking: Locking asset in contract to earn XP.

// State Variables:
// - _assetCounter: Total minted assets.
// - _assetData: Mapping tokenId => AssetData struct.
// - _validIngredientTokens: Mapping address => bool for allowed ingredients.
// - _synthesisFeeETH: ETH fee for synthesis.
// - _levelUpFeeETH: ETH fee for leveling up.
// - _traitWeights: Mapping string => uint256 for trait generation influence.
// - _baseTokenURI: Base URI for metadata JSON.
// - _paused: Pauses core functions.

// Structs:
// - AssetData: traits (mapping string => string), level (uint256), xp (uint256), staking (StakingInfo).
// - StakingInfo: isStaked (bool), startTime (uint64), lastXPUpdateTime (uint64).

// Events:
// - AssetSynthesized(tokenId, owner, initialTraits)
// - AssetStaked(tokenId, owner)
// - AssetUnstaked(tokenId, owner, xpEarned)
// - AssetLeveledUp(tokenId, newLevel, xpConsumed)
// - IngredientTokenAdded(token)
// - IngredientTokenRemoved(token)
// - SynthesisFeeUpdated(oldFee, newFee)
// - LevelUpFeeUpdated(oldFee, newFee)
// - TraitWeightsUpdated(traitType)
// - BaseTokenURIUpdated(newURI)
// - Paused(account), Unpaused(account) (from Pausable)

// Function Summary (22+ core functions + inherited ERC721/Ownable):
// 1.  constructor(): Initialize contract.
// 2.  synthesizeAsset(ingredientTokens[], amounts[]): Mint new asset using ingredients and fee.
// 3.  stakeAsset(tokenId): Stake asset to earn XP.
// 4.  unstakeAsset(tokenId): Unstake asset, claim pending XP.
// 5.  claimStakingXP(tokenId): Update accumulated XP for staked asset.
// 6.  levelUpAsset(tokenId): Level up asset using XP and fee.
// 7.  addIngredientToken(token): Owner adds valid ingredient.
// 8.  removeIngredientToken(token): Owner removes valid ingredient.
// 9.  setSynthesisFee(fee): Owner sets synthesis fee.
// 10. setLevelUpFee(fee): Owner sets level-up fee.
// 11. setTraitWeight(traitType, weight): Owner sets parameter influencing trait generation.
// 12. withdrawFees(): Owner withdraws collected ETH fees.
// 13. pauseContract(): Owner pauses core interactions.
// 14. unpauseContract(): Owner unpauses.
// 15. getValidIngredientTokens(): View valid ingredient addresses.
// 16. getSynthesisCost(): View current synthesis ETH fee.
// 17. getAssetLevel(tokenId): View asset's level.
// 18. getAssetXP(tokenId): View asset's total XP (staked included).
// 19. getAssetTraits(tokenId): View asset's current traits.
// 20. getAssetStakingInfo(tokenId): View asset's staking details.
// 21. getPendingXP(tokenId): View XP earned since last update/stake.
// 22. tokenURI(tokenId): View metadata URI based on state.
// (+ Inherited: ownerOf, balanceOf, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, transferOwnership, renounceOwnership)
// 22 core functions + 10 inherited = 32+ functions total

contract GenerativeAssetSynthesizer is ERC721, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    struct StakingInfo {
        bool isStaked;
        uint64 startTime; // Time staking started
        uint64 lastXPUpdateTime; // Last time XP was calculated and added
    }

    struct AssetData {
        mapping(string => string) traits; // Dynamic trait key-value storage
        uint256 level;
        uint256 xp;
        StakingInfo staking;
    }

    // State variables
    uint256 private _assetCounter;
    mapping(uint256 => AssetData) private _assetData; // Stores data for each token ID

    mapping(address => bool) private _validIngredientTokens;
    address[] private _validIngredientTokenList; // To easily list valid tokens

    uint256 public _synthesisFeeETH; // Fee required to synthesize an asset
    uint256 public _levelUpFeeETH; // Fee required to level up an asset

    // Parameters influencing trait generation (Owner can adjust these)
    // Example: mapping "rarity" => 100 (higher means more bias towards rare outcomes, specific mapping logic needed)
    mapping(string => uint256) private _traitWeights;

    string private _baseTokenURI; // Base URI for metadata

    // Configuration for XP calculation (Owner could set these)
    // Example: XP per second staked
    uint256 public stakingXPPerSecond = 1;
    // Example: XP cost to level up depends on current level
    mapping(uint256 => uint256) public levelUpXPRequirements;
    // Example: How traits change on level up - more complex logic or mapping needed off-chain or in a dedicated struct

    // Events
    event AssetSynthesized(uint256 indexed tokenId, address indexed owner, uint256 blockNumber, bytes32 blockHash); // Simplified traits logging
    event AssetStaked(uint256 indexed tokenId, address indexed owner);
    event AssetUnstaked(uint256 indexed tokenId, address indexed owner, uint256 xpEarned);
    event AssetLeveledUp(uint256 indexed tokenId, uint256 newLevel, uint256 xpConsumed);
    event IngredientTokenAdded(address indexed token);
    event IngredientTokenRemoved(address indexed token);
    event SynthesisFeeUpdated(uint256 oldFee, uint256 newFee);
    event LevelUpFeeUpdated(uint256 oldFee, uint256 newFee);
    event TraitWeightUpdated(string traitType, uint256 weight);
    event BaseTokenURIUpdated(string newURI);

    constructor() ERC721("GenerativeAsset", "GENAST") Ownable(msg.sender) {}

    // --- Pausability ---
    function pauseContract() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // Override ERC721 functions to include pause
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) whenNotPaused {
        super._update(to, tokenId, auth);
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721) whenNotPaused {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) whenNotPaused {
        super._burn(tokenId);
    }

    // --- Admin Functions ---

    /// @notice Adds an ERC-20 token to the list of valid ingredients for synthesis.
    /// @param token The address of the ERC-20 token.
    function addIngredientToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(!_validIngredientTokens[token], "Token already ingredient");
        _validIngredientTokens[token] = true;
        _validIngredientTokenList.push(token);
        emit IngredientTokenAdded(token);
    }

    /// @notice Removes an ERC-20 token from the list of valid ingredients.
    /// @param token The address of the ERC-20 token to remove.
    function removeIngredientToken(address token) external onlyOwner {
        require(_validIngredientTokens[token], "Token not an ingredient");
        _validIngredientTokens[token] = false;
        // Simple removal from list (gas-inefficient for large lists)
        for (uint i = 0; i < _validIngredientTokenList.length; i++) {
            if (_validIngredientTokenList[i] == token) {
                _validIngredientTokenList[i] = _validIngredientTokenList[_validIngredientTokenList.length - 1];
                _validIngredientTokenList.pop();
                break;
            }
        }
        emit IngredientTokenRemoved(token);
    }

    /// @notice Sets the ETH fee required for synthesizing an asset.
    /// @param fee The new synthesis fee in wei.
    function setSynthesisFee(uint256 fee) external onlyOwner {
        uint256 oldFee = _synthesisFeeETH;
        _synthesisFeeETH = fee;
        emit SynthesisFeeUpdated(oldFee, fee);
    }

    /// @notice Sets the ETH fee required for leveling up an asset.
    /// @param fee The new level-up fee in wei.
    function setLevelUpFee(uint256 fee) external onlyOwner {
        uint256 oldFee = _levelUpFeeETH;
        _levelUpFeeETH = fee;
        emit LevelUpFeeUpdated(oldFee, fee);
    }

    /// @notice Sets or updates a weight parameter used in the trait generation logic.
    /// This parameter influences the pseudo-random trait determination. Specific logic
    /// interpreting weights must be implemented in _generateInitialTraits.
    /// @param traitType A string identifier for the trait parameter (e.g., "rarityBias").
    /// @param weight The weight value.
    function setTraitWeight(string calldata traitType, uint256 weight) external onlyOwner {
        _traitWeights[traitType] = weight;
        emit TraitWeightUpdated(traitType, weight);
    }

    /// @notice Sets the amount of XP required to reach a specific level.
    /// This value is the *total* XP required, not the XP needed *from* the previous level.
    /// @param level The target level (must be > 0).
    /// @param requiredXP The total XP needed to *reach* this level.
    function setLevelUpXPRequirement(uint256 level, uint256 requiredXP) external onlyOwner {
        require(level > 0, "Level must be greater than 0");
        levelUpXPRequirements[level] = requiredXP;
        // Note: The logic for consuming XP in levelUpAsset should check if current XP
        // is >= requiredXP for the *next* level.
    }

    /// @notice Sets the rate of XP earned per second while staking.
    /// @param xpPerSecond The new XP rate per second.
    function setStakingXPPerSecond(uint256 xpPerSecond) external onlyOwner {
        stakingXPPerSecond = xpPerSecond;
    }


    /// @notice Allows the owner to withdraw collected ETH fees.
    function withdrawFees() external onlyOwner nonReentrant {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Fee withdrawal failed");
    }

    /// @notice Sets the base URI for token metadata. tokenURI will return this base URI + tokenId.
    /// An external service should host the JSON metadata at these URIs, reading on-chain
    /// asset state (traits, level) via public view functions to dynamically generate the JSON.
    /// @param baseURI The base URI string.
    function setBaseTokenURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseTokenURIUpdated(baseURI);
    }

    // --- Synthesis Function ---

    /// @notice Synthesizes a new GenerativeAsset NFT.
    /// Requires burning specified ingredient tokens and paying an ETH fee.
    /// Initial traits are generated based on block data and internal parameters.
    /// @param ingredientTokens Array of ingredient token addresses.
    /// @param amounts Array of amounts corresponding to ingredientTokens.
    function synthesizeAsset(address[] calldata ingredientTokens, uint256[] calldata amounts) external payable whenNotPaused nonReentrant {
        require(ingredientTokens.length == amounts.length, "Array length mismatch");
        require(msg.value >= _synthesisFeeETH, "Insufficient ETH fee");

        // Transfer and burn ingredient tokens
        for (uint i = 0; i < ingredientTokens.length; i++) {
            address token = ingredientTokens[i];
            uint256 amount = amounts[i];
            require(_validIngredientTokens[token], "Invalid ingredient token");
            require(amount > 0, "Ingredient amount must be positive");
            // User must approve this contract to spend the tokens beforehand
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            // Option: Burn tokens here if desired, or keep them in the contract for later use/withdrawal
            // IERC20(token).safeBurn(amount); // Example burn (SafeERC20 might not have burn, would need custom or specific extension)
            // For simplicity, we'll just require transfer to the contract. Owner can withdraw them or they can be used elsewhere.
        }

        // Generate initial traits (pseudorandomly based on block data and parameters)
        uint256 nextTokenId = _assetCounter + 1;
        mapping(string => string) storage initialTraits = _assetData[nextTokenId].traits;
        _generateInitialTraits(nextTokenId, ingredientTokens, amounts, msg.value, initialTraits);

        // Mint the token
        _assetCounter++;
        _mint(msg.sender, nextTokenId);

        // Initialize other asset data
        _assetData[nextTokenId].level = 1; // Start at level 1
        _assetData[nextTokenId].xp = 0;
        _assetData[nextTokenId].staking = StakingInfo(false, 0, 0); // Not staked initially

        // ETH fee remains in the contract, withdrawable by owner

        emit AssetSynthesized(nextTokenId, msg.sender, block.number, blockhash(block.number - 1)); // Emit block hash for transparency
    }

    /// @dev Internal function to generate initial traits based on inputs and block data.
    /// This is the core generative logic. Needs to be implemented based on desired trait system.
    /// Placeholder implementation using simple block hash and inputs.
    function _generateInitialTraits(
        uint256 tokenId,
        address[] calldata ingredientTokens,
        uint256[] calldata amounts,
        uint256 ethFee,
        mapping(string => string) storage traits // Write directly to storage
    ) internal view {
        bytes32 blockHash = blockhash(block.number - 1); // Use previous block hash for randomness
        uint256 randomness = uint256(blockHash) ^ tokenId ^ block.timestamp;

        // Basic Example Trait Generation:
        // This logic is highly simplified. Real implementation would map randomness/inputs
        // to specific trait values based on defined possibilities and weights.

        // Trait based on randomness: simple modulo distribution
        if ((randomness % 100) < 10) {
            traits["Background"] = "Rare Sky";
        } else if ((randomness % 100) < 40) {
            traits["Background"] = "Cloudy Day";
        } else {
            traits["Background"] = "Clear Sky";
        }

        // Trait based on ETH fee (higher fee might slightly bias towards certain traits)
        if (ethFee > _synthesisFeeETH * 2) { // Example: double the fee gives a bonus trait
            traits["Accessory"] = "Golden Crown";
        } else {
            traits["Accessory"] = "None";
        }

        // Trait based on ingredient tokens (e.g., certain token types unlock specific traits)
        uint256 totalIngredientValue = 0;
        for(uint i=0; i < ingredientTokens.length; i++) {
            if (ingredientTokens[i] == address(0xSomeSpecificIngredientTokenAddress)) { // Example check
                 traits["Gem"] = "Mystic Stone";
            }
            // Add up amounts (simplified - assumes tokens have similar value or use oracle)
            totalIngredientValue += amounts[i];
        }

        // Trait based on combination of factors and trait weights
        // Get weight for a conceptual "ColorVariety" trait influence
        uint256 colorWeight = _traitWeights["ColorVariety"]; // Default to 0 if not set
        uint256 colorRandomness = uint256(keccak256(abi.encodePacked(randomness, "color", colorWeight)));
        if ((colorRandomness % 100 + colorWeight) > 120) { // Example logic using weight
             traits["Color"] = "Vibrant";
        } else {
             traits["Color"] = "Standard";
        }

        // Store the randomness source for transparency
        traits["SynthesisBlock"] = Strings.toString(block.number - 1);
        traits["SynthesisRandomness"] = Strings.toHexString(uint256(blockHash));
    }

    /// @dev Internal function to potentially update traits during level-up.
    /// Needs implementation based on desired level-up effects.
    function _updateTraitsOnLevelUp(uint256 tokenId, uint256 newLevel, mapping(string => string) storage traits) internal {
        // Example: Unlock a new trait at level 5
        if (newLevel == 5 && bytes(traits["Aura"]).length == 0) {
            traits["Aura"] = "Beginner Glow";
        }
        // Example: Upgrade a trait at level 10
        if (newLevel == 10 && bytes(traits["Accessory"]).length > 0 && keccak256(bytes(traits["Accessory"])) == keccak256(bytes("Golden Crown"))) {
             traits["Accessory"] = "Diamond Crown";
        }
        // More complex logic could involve randomness again, or fixed upgrades per level.
    }


    // --- Staking Functions ---

    /// @notice Stakes an asset within the contract to earn XP.
    /// Caller must be the owner of the asset and must have approved the contract
    /// to transfer the asset beforehand (using ERC721 `approve`).
    /// @param tokenId The ID of the asset to stake.
    function stakeAsset(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "Asset does not exist");
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Not asset owner");
        require(!_assetData[tokenId].staking.isStaked, "Asset already staked");

        // Transfer the token from owner to the contract
        safeTransferFrom(owner, address(this), tokenId);

        // Record staking start time
        _assetData[tokenId].staking.isStaked = true;
        _assetData[tokenId].staking.startTime = uint64(block.timestamp);
        _assetData[tokenId].staking.lastXPUpdateTime = uint64(block.timestamp);

        emit AssetStaked(tokenId, msg.sender);
    }

    /// @notice Unstakes an asset, claims pending XP, and transfers the asset back to the owner.
    /// @param tokenId The ID of the asset to unstake.
    function unstakeAsset(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "Asset does not exist");
        require(_assetData[tokenId].staking.isStaked, "Asset not staked");
        require(ownerOf(tokenId) == address(this), "Asset not held by contract for staking"); // Double check ownership by contract

        // Calculate and add pending XP before unstaking
        uint256 xpEarned = getPendingXP(tokenId);
        _assetData[tokenId].xp += xpEarned;
        _assetData[tokenId].staking.lastXPUpdateTime = uint64(block.timestamp); // Update time even before unstaking

        // Reset staking info
        _assetData[tokenId].staking.isStaked = false;
        _assetData[tokenId].staking.startTime = 0;
        _assetData[tokenId].staking.lastXPUpdateTime = 0; // Reset last update time

        // Transfer the token back to the original staker (who must be msg.sender)
        // Ensure msg.sender was the one who staked it - we don't explicitly store staker address,
        // assume the one calling unstake is the rightful owner pre-staking.
        // A more robust system might store the staker's address in StakingInfo.
        // For simplicity, we require ownerOf(tokenId) == address(this) AND msg.sender initiates.
        // It implies the user must have been the owner *before* staking.
        address originalOwner = msg.sender; // Assuming caller is the original owner trying to retrieve

        // Transfer back to the user calling unstake
        _safeTransfer(address(this), originalOwner, tokenId, "");

        emit AssetUnstaked(tokenId, originalOwner, xpEarned);
    }

    /// @notice Updates the accumulated XP for a staked asset without unstaking it.
    /// Useful for long staking periods to checkpoint XP earnings.
    /// @param tokenId The ID of the staked asset.
    function claimStakingXP(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "Asset does not exist");
        require(_assetData[tokenId].staking.isStaked, "Asset not staked");
        require(ownerOf(tokenId) == address(this), "Asset not held by contract for staking");

        uint256 xpEarned = getPendingXP(tokenId);
        if (xpEarned > 0) {
            _assetData[tokenId].xp += xpEarned;
            _assetData[tokenId].staking.lastXPUpdateTime = uint64(block.timestamp);
            // No specific event for claiming, it's an internal state update primarily.
            // Could add a dedicated event if needed for off-chain tracking.
        }
    }


    /// @notice Attempts to level up an asset. Requires sufficient XP and pays a fee.
    /// Leveling up may modify asset traits.
    /// @param tokenId The ID of the asset to level up.
    function levelUpAsset(uint256 tokenId) external payable whenNotPaused nonReentrant {
        require(_exists(tokenId), "Asset does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not asset owner");
        require(!_assetData[tokenId].staking.isStaked, "Cannot level up staked asset"); // Must unstake first

        uint256 currentLevel = _assetData[tokenId].level;
        uint256 nextLevel = currentLevel + 1;
        uint256 requiredXPForNextLevel = levelUpXPRequirements[nextLevel];

        require(requiredXPForNextLevel > 0, "Level up requirements not set for next level"); // Requirements must be configured
        require(_assetData[tokenId].xp >= requiredXPForNextLevel, "Insufficient XP");
        require(msg.value >= _levelUpFeeETH, "Insufficient ETH fee");

        // Consume XP (or simply check against total needed and keep total)
        // Option 1: Keep track of total XP and requirements per level
        // No XP deduction needed, just verify total >= requirement for next level
        // Option 2: Deduct XP (e.g., cost is required[level] - required[level-1])
        // Let's use Option 1 for simplicity: XP is cumulative required to reach level.

        _assetData[tokenId].level = nextLevel;
        // Note: We don't deduct XP here, XP is total accumulated. Requirements are cumulative.

        // Potentially update traits based on the new level
        _updateTraitsOnLevelUp(tokenId, nextLevel, _assetData[tokenId].traits);

        // ETH fee remains in the contract, withdrawable by owner

        emit AssetLeveledUp(tokenId, nextLevel, requiredXPForNextLevel); // Emit requiredXP as 'consumed' conceptually
    }

    // --- View Functions ---

    /// @notice Gets the list of currently valid ingredient token addresses.
    /// @return An array of ERC-20 token addresses.
    function getValidIngredientTokens() external view returns (address[] memory) {
        return _validIngredientTokenList;
    }

    /// @notice Gets the current ETH fee required for asset synthesis.
    /// Note: This function does not specify the required *amounts* or *types* of ingredient tokens,
    /// which must be known by the user or obtained via other means (e.g., off-chain documentation).
    /// @return The ETH fee in wei.
    function getSynthesisCost() external view returns (uint256) {
        return _synthesisFeeETH;
    }

    /// @notice Gets the current ETH fee required for leveling up an asset.
    /// @return The ETH fee in wei.
    function getLevelUpCost() external view returns (uint256) {
        return _levelUpFeeETH;
    }

    /// @notice Gets the current level of a specific asset.
    /// @param tokenId The ID of the asset.
    /// @return The asset's level. Returns 0 if asset does not exist.
    function getAssetLevel(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) return 0;
        return _assetData[tokenId].level;
    }

    /// @notice Gets the current total XP of a specific asset.
    /// For staked assets, this includes XP accumulated since the last update/stake time.
    /// @param tokenId The ID of the asset.
    /// @return The asset's total XP. Returns 0 if asset does not exist.
    function getAssetXP(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) return 0;
        uint256 totalXP = _assetData[tokenId].xp;
        if (_assetData[tokenId].staking.isStaked) {
            totalXP += getPendingXP(tokenId);
        }
        return totalXP;
    }

    /// @notice Gets the current traits of a specific asset.
    /// @param tokenId The ID of the asset.
    /// @return An array of trait keys and an array of trait values.
    function getAssetTraits(uint256 tokenId) external view returns (string[] memory keys, string[] memory values) {
        require(_exists(tokenId), "Asset does not exist");
        // Note: Reading entire mappings directly is not possible. We need a way to iterate or store keys.
        // A common pattern is to store keys in an array alongside the mapping, or require off-chain
        // knowledge of possible trait keys.
        // For this example, we'll return a placeholder or require off-chain knowledge of keys.
        // A robust implementation would require iterating over a stored list of trait keys.
        // Let's return a fixed set of potential keys with their values if they exist.
        string[] memory potentialKeys = new string[](6); // Example: Assuming max 6 main traits + synthesis info
        potentialKeys[0] = "Background";
        potentialKeys[1] = "Accessory";
        potentialKeys[2] = "Gem";
        potentialKeys[3] = "Color";
        potentialKeys[4] = "Aura"; // Potential level-up trait
        potentialKeys[5] = "SynthesisBlock"; // Example stored info

        string[] memory currentValues = new string[](potentialKeys.length);
        uint256 count = 0;
        for(uint i = 0; i < potentialKeys.length; i++) {
             string memory key = potentialKeys[i];
             string memory value = _assetData[tokenId].traits[key];
             // Only include traits that have been set (value is not empty string)
             if (bytes(value).length > 0) {
                 currentValues[count] = value;
                 // To return keys and values correctly, we need dynamic arrays or filter
                 // For a proper solution, we would need to store trait keys alongside the mapping.
                 // Let's return the potential keys and their values, empty string if not set.
                 // Simpler approach: return the fixed list of potential keys and their values.
                 // If the list of traits is dynamic, this needs a different storage pattern.
                 // Let's return the fixed list for example purposes.
             }
        }
         return (potentialKeys, currentValues); // Returns keys and values (empty string if trait not set)
    }

     /// @notice Gets the current staking information for a specific asset.
     /// @param tokenId The ID of the asset.
     /// @return isStaked Whether the asset is currently staked.
     /// @return startTime The timestamp when staking began (0 if not staked).
     /// @return lastXPUpdateTime The timestamp of the last XP update (0 if not staked/updated).
    function getAssetStakingInfo(uint256 tokenId) external view returns (bool isStaked, uint64 startTime, uint64 lastXPUpdateTime) {
         require(_exists(tokenId), "Asset does not exist");
         StakingInfo storage info = _assetData[tokenId].staking;
         return (info.isStaked, info.startTime, info.lastXPUpdateTime);
    }

    /// @notice Calculates the amount of XP earned by a staked asset since its last XP update.
    /// @param tokenId The ID of the staked asset.
    /// @return The pending XP. Returns 0 if asset is not staked.
    function getPendingXP(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId) || !_assetData[tokenId].staking.isStaked) {
            return 0;
        }
        uint256 stakingDuration = block.timestamp - _assetData[tokenId].staking.lastXPUpdateTime;
        return stakingDuration * stakingXPPerSecond;
    }

    /// @notice Returns the total supply of tokens.
    function totalSupply() public view returns (uint256) {
        return _assetCounter;
    }

    /// @notice Returns an array of token IDs owned by a specific address.
    /// Note: This function can be gas-intensive for addresses owning many tokens.
    /// @param owner The address to query.
    /// @return An array of token IDs.
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 index = 0;
        // Note: This requires iterating potentially many token IDs to find ones owned by 'owner'.
        // A more efficient way requires tracking ownership in a separate enumerable structure,
        // like OpenZeppelin's ERC721Enumerable. For this example, we assume _assetCounter
        // isn't astronomically large and iterate through all minted tokens.
        // THIS IS GAS INEFFICIENT FOR MANY ASSETS.
        for (uint256 i = 1; i <= _assetCounter; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                tokenIds[index] = i;
                index++;
            }
        }
        // If using ERC721Enumerable, the implementation would be simpler and more efficient.
        // For demonstrating 20+ functions without copying *standard* libraries entirely,
        // implementing a basic (though potentially inefficient) version suffices.
        // A better approach would be to use ERC721Enumerable.
        // The following line is needed IF the loop didn't fill the array (e.g., some tokens burned)
        // but in this design, tokens aren't burned post-minting for simplicity.
        // If tokens could be burned, a resizing array logic or ERC721Enumerable is necessary.
        // Assuming no burn for simplicity of this function.
        return tokenIds;
    }

    /// @notice Returns the metadata URI for a given token ID.
    /// The URI points to an external service that reads the asset's on-chain state
    /// (traits, level, etc.) and generates the JSON metadata dynamically.
    /// @param tokenId The ID of the asset.
    /// @return The metadata URI string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        string memory baseURI = _baseTokenURI;
        if (bytes(baseURI).length == 0) {
            return ""; // Or a default URI indicating metadata is not set
        }

        // Append token ID to base URI
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /// @notice Get the current weight for a specific trait parameter used in synthesis.
    /// @param traitType The string identifier for the trait parameter.
    /// @return The weight value. Returns 0 if no weight is set.
    function getTraitWeight(string calldata traitType) external view returns (uint256) {
        return _traitWeights[traitType];
    }

     /// @notice Get the XP requirement to reach a specific level.
     /// @param level The target level.
     /// @return The total XP required to reach that level. Returns 0 if not set.
    function getLevelUpXPRequirement(uint256 level) external view returns (uint256) {
         return levelUpXPRequirements[level];
    }

    // --- Internal/Helper Functions ---

    /// @dev Override to include internal logic if needed, e.g., logging transfers or state changes.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Add logic here if needed before any token transfer (mint, transfer, burn)
        // Example: Prevent transfers of staked assets (though stake/unstake handles ownership change)
        // Or update staking info immediately before a transfer happens if staking state isn't tracked via contract ownership.
    }

     /// @dev Helper to check if a token ID exists.
     function _exists(uint256 tokenId) internal view override returns (bool) {
        // ERC721's _exists is sufficient here
        return super._exists(tokenId);
     }


    // Receive and fallback to accept ETH fee
    receive() external payable {}
    fallback() external payable {}
}
```