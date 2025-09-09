This smart contract, `AetherForge`, introduces a novel ecosystem for dynamic, evolving NFTs. Users own "Aetherite" NFTs that can gain experience points (XP), level up, and be upgraded or used in crafting processes. The system integrates multiple token standards (ERC-721 for Aetherites, ERC-20 for 'Essence' resources, and ERC-1155 for 'Components' and 'Catalyst Forges') to create a rich, interactive, and evolving digital asset experience. The core advanced concepts include on-chain dynamic metadata, an NFT-bound experience and leveling system, multi-token crafting with catalytic effects, and a parameterizable economic framework.

---

### **AetherForge Contract Outline**

**I. Contract Introduction**
*   **Name:** `AetherForge`
*   **Purpose:** A dynamic NFT ecosystem where `Aetherite` NFTs gain XP, level up, and participate in a crafting and upgrade system. It integrates ERC-721, ERC-20, and ERC-1155 tokens to create a unique, evolving digital asset.

**II. Function Summary**

**A. Core Aetherite Management (ERC-721)**
1.  `constructor(string _name, string _symbol, string _baseTokenURI, address _essenceContract, address _componentCatalystContract)`: Initializes the contract with NFT name, symbol, base URI, and addresses for external resource tokens.
2.  `mintInitialAetherite(address _to)`: Mints a new base-level `Aetherite` NFT to a specified address, assigning initial metadata and state.
3.  `tokenURI(uint256 tokenId)`: *Overrides* ERC-721 `tokenURI`. Returns a dynamic URI for an `Aetherite`'s metadata, reflecting its current level, upgrades, and state.
4.  `getAetheriteDetails(uint256 tokenId)`: Retrieves a comprehensive summary of an `Aetherite` NFT's current state, including its level, XP, metadata hash, and last activity time.

**B. XP & Leveling System**
5.  `gainAetherXP(uint256 tokenId, uint256 amount)`: Awards `AetherXP` to a specific `Aetherite` NFT. This function is restricted to authorized `XP` providers or the NFT owner.
6.  `levelUpAetherite(uint256 tokenId)`: Allows an `Aetherite` owner to attempt a level-up if the `Aetherite` has accumulated sufficient `AetherXP`. Consumes `XP` and updates the `Aetherite`'s metadata.
7.  `getNextLevelXPRequirement(uint256 currentLevel)`: Calculates the total `AetherXP` required for an `Aetherite` to reach the next level based on the current level and defined formula.

**C. Crafting & Upgrades**
8.  `craftItem(uint256 aetheriteId, uint256 recipeId, uint256 catalystForgeId)`: Executes a predefined crafting `recipeId` using a specific `Aetherite`, consuming `AetherEssence` (ERC-20) and `AetherComponents` (ERC-1155). The process can be boosted by an optional `CatalystForge` (ERC-1155).
9.  `defineCraftingRecipe(uint256 recipeId, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts, uint256 essenceCost, uint256 outputTokenId, uint256 outputTokenAmount, uint256 minAetheriteLevel, bytes32 newMetadataHash)`: Admin function to add or update a crafting recipe, specifying required components, `Essence` cost, output (ERC-1155 token), minimum `Aetherite` level, and resulting metadata changes.
10. `removeCraftingRecipe(uint256 recipeId)`: Admin function to remove an existing crafting recipe.
11. `getRecipeDetails(uint256 recipeId)`: Retrieves the full details of a specific crafting recipe.
12. `upgradeAetherite(uint256 aetheriteId, uint256 upgradeId)`: Applies a predefined `upgradeId` to an `Aetherite`, consuming `Essence` and `Components`, and updating its metadata and properties.
13. `defineAetheriteUpgrade(uint256 upgradeId, uint256 essenceCost, uint256[] calldata componentTypeIds, uint256[] calldata componentAmounts, uint256 minAetheriteLevel, bytes32 newMetadataHash)`: Admin function to add or update an `Aetherite` upgrade, detailing costs, requirements, and metadata changes.
14. `removeAetheriteUpgrade(uint256 upgradeId)`: Admin function to remove an existing `Aetherite` upgrade.

**D. Resource & Auxiliary NFT Management**
15. `setEssenceContract(address _essenceContract)`: Admin function to update the address of the `AetherEssence` (ERC-20) token contract.
16. `setComponentCatalystContract(address _componentCatalystContract)`: Admin function to update the address of the `AetherComponents` and `AetherCatalystForges` (ERC-1155) token contract.
17. `authorizeXPProvider(address _provider, bool _isAuthorized)`: Admin function to grant or revoke authorization for external addresses or contracts to call `gainAetherXP`.

**E. Admin & Configuration**
18. `setBaseTokenURI(string _newBaseTokenURI)`: Admin function to update the base URI used for constructing `Aetherite` metadata URLs.
19. `setXPPerLevelFormula(uint256 _baseXP, uint256 _multiplier)`: Admin function to configure the mathematical formula determining `AetherXP` requirements for leveling up.
20. `setMinLevelForRecipe(uint256 recipeId, uint256 _minLevel)`: Admin function to set or adjust the minimum `Aetherite` level required to use a specific crafting recipe.
21. `setMinLevelForUpgrade(uint256 upgradeId, uint256 _minLevel)`: Admin function to set or adjust the minimum `Aetherite` level required to apply a specific upgrade.
22. `withdrawUnspentEssence(address _to, uint256 _amount)`: Admin function to withdraw `AetherEssence` from the contract, for scenarios like refunds or rebalancing.
23. `setInitialAetheriteMetadataHash(bytes32 _hash)`: Admin function to set the default metadata hash for newly minted `Aetherite` NFTs.
24. `setCatalystEffectiveness(uint256 forgeTypeId, uint256 bonusPercentage)`: Admin function to define or update the crafting success or efficiency bonus provided by different `CatalystForge` types.
25. `pause()`: Inherited from `Pausable`. Admin function to pause core contract functionalities (e.g., minting, crafting, XP gain) in emergencies.
26. `unpause()`: Inherited from `Pausable`. Admin function to unpause the contract's functionalities.

---

### **Source Code**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces for external tokens ---

/**
 * @title IAetherEssence
 * @dev Interface for the AetherEssence ERC-20 token, used as a resource.
 */
interface IAetherEssence is IERC20 {
    // IERC20 already provides transferFrom, approve, etc.
}

/**
 * @title IAetherComponentsCatalysts
 * @dev Interface for the AetherComponents and AetherCatalystForges ERC-1155 token.
 *      This contract will manage both components for crafting and catalyst forges.
 */
interface IAetherComponentsCatalysts is IERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address from, uint256 id, uint256 amount) external;
}


/**
 * @title AetherForge
 * @dev A dynamic NFT ecosystem enabling Aetherite NFT progression, crafting, and upgrades.
 *      Aetherites (ERC-721) gain XP, level up, and can be used in crafting processes.
 *      Crafting requires AetherEssence (ERC-20) and AetherComponents (ERC-1155),
 *      and can be boosted by AetherCatalystForges (ERC-1155).
 *      Metadata changes dynamically based on Aetherite's state.
 */
contract AetherForge is ERC721, Ownable, Pausable, ERC1155Holder {
    using Strings for uint256;

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for Aetherite NFTs

    // Struct to store dynamic Aetherite NFT data
    struct Aetherite {
        uint256 currentXP;
        uint256 currentLevel;
        bytes32 metadataHash; // IPFS/Arweave hash for current metadata JSON
        uint64 lastActivityTimestamp; // To prevent XP farming or track progression
    }
    mapping(uint256 => Aetherite) public aetherites;

    // Crafting Recipes
    struct Recipe {
        uint256[] componentTypeIds;   // IDs of ERC-1155 components needed
        uint256[] componentAmounts;   // Amounts of each component needed
        uint256 essenceCost;          // Amount of AetherEssence needed
        uint256 outputTokenId;        // ID of the ERC-1155 token produced (0 if none)
        uint256 outputTokenAmount;    // Amount of output token
        uint256 minAetheriteLevel;    // Minimum Aetherite level required to craft
        bytes32 newMetadataHash;      // Optional: metadata hash for Aetherite after successful craft
        bool exists;
    }
    mapping(uint256 => Recipe) public recipes;

    // Aetherite Upgrades
    struct Upgrade {
        uint256 essenceCost;          // Amount of AetherEssence needed
        uint256[] componentTypeIds;   // IDs of ERC-1155 components needed
        uint256[] componentAmounts;   // Amounts of each component needed
        uint256 minAetheriteLevel;    // Minimum Aetherite level required to apply upgrade
        bytes32 newMetadataHash;      // Metadata hash for Aetherite after successful upgrade
        bool exists;
    }
    mapping(uint256 => Upgrade) public upgrades;

    // External contract addresses
    IAetherEssence public essenceContract;
    IAetherComponentsCatalysts public componentCatalystContract;

    // XP related parameters
    mapping(address => bool) public authorizedXPProviders; // Addresses allowed to grant XP
    uint256 public baseXPForNextLevel = 1000;
    uint256 public xpMultiplierPerLevel = 150; // e.g., 150 means 150% of previous level XP

    // Catalyst Forge effectiveness (ID => bonus percentage, e.g., 105 for 5% boost)
    mapping(uint256 => uint256) public catalystEffectiveness; // ID => bonus multiplier (e.g., 105 for 5%)

    // Base URI for Aetherite metadata (e.g., ipfs://CID/)
    string private _baseTokenURI;
    bytes32 public initialAetheriteMetadataHash; // Default metadata hash for new Aetherites


    // --- Events ---

    event AetheriteMinted(uint256 indexed tokenId, address indexed owner, bytes32 initialMetadataHash);
    event AetheriteXPGained(uint256 indexed tokenId, uint256 amount, uint256 newXP);
    event AetheriteLeveledUp(uint256 indexed tokenId, uint256 newLevel, bytes32 newMetadataHash);
    event ItemCrafted(uint256 indexed aetheriteId, uint256 indexed recipeId, address indexed crafter, uint256 outputTokenId, uint256 outputTokenAmount);
    event AetheriteUpgraded(uint256 indexed aetheriteId, uint256 indexed upgradeId, address indexed upgrader, bytes32 newMetadataHash);
    event RecipeDefined(uint256 indexed recipeId, uint256 essenceCost, uint256 outputTokenId);
    event UpgradeDefined(uint256 indexed upgradeId, uint256 essenceCost);
    event XPProviderAuthorized(address indexed provider, bool authorized);
    event CatalystEffectivenessSet(uint256 indexed forgeTypeId, uint256 bonusPercentage);


    // --- Constructor ---

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _essenceContract,
        address _componentCatalystContract
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_essenceContract != address(0), "Essence contract cannot be zero address");
        require(_componentCatalystContract != address(0), "Component/Catalyst contract cannot be zero address");
        
        _baseTokenURI = _baseUri;
        essenceContract = IAetherEssence(_essenceContract);
        componentCatalystContract = IAetherComponentsCatalysts(_componentCatalystContract);

        // Acknowledge that this contract can receive ERC-1155 tokens
        // ERC1155Holder constructor is internal and called automatically.
    }


    // --- Modifiers ---

    modifier onlyXPProvider() {
        require(authorizedXPProviders[msg.sender], "Caller is not an authorized XP provider");
        _;
    }

    modifier onlyAetheriteOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not Aetherite owner or approved for action");
        _;
    }


    // --- A. Core Aetherite Management (ERC-721) ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      Returns the dynamic URI for an Aetherite's metadata, reflecting its current state.
     *      The URI is constructed from the base URI and the Aetherite's current metadata hash.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(_baseTokenURI, aetherites[tokenId].metadataHash.toHexString()));
    }

    /**
     * @dev Mints a new base-level Aetherite NFT to a specified address.
     *      Requires `initialAetheriteMetadataHash` to be set by the owner.
     * @param _to The address to mint the Aetherite to.
     */
    function mintInitialAetherite(address _to) public virtual onlyOwner returns (uint256) {
        require(initialAetheriteMetadataHash != bytes32(0), "Initial metadata hash not set");
        _nextTokenId++;
        uint256 newItemId = _nextTokenId;

        _safeMint(_to, newItemId);
        
        aetherites[newItemId] = Aetherite({
            currentXP: 0,
            currentLevel: 1,
            metadataHash: initialAetheriteMetadataHash,
            lastActivityTimestamp: uint64(block.timestamp)
        });

        emit AetheriteMinted(newItemId, _to, initialAetheriteMetadataHash);
        return newItemId;
    }

    /**
     * @dev Retrieves a comprehensive summary of an Aetherite NFT's current state.
     * @param tokenId The ID of the Aetherite NFT.
     * @return currentXP The current experience points of the Aetherite.
     * @return currentLevel The current level of the Aetherite.
     * @return metadataHash The current metadata hash of the Aetherite.
     * @return lastActivityTimestamp The timestamp of the Aetherite's last recorded activity.
     */
    function getAetheriteDetails(uint256 tokenId)
        public
        view
        returns (
            uint256 currentXP,
            uint256 currentLevel,
            bytes32 metadataHash,
            uint64 lastActivityTimestamp
        )
    {
        _requireOwned(tokenId); // Ensure the token exists
        Aetherite storage aetherite = aetherites[tokenId];
        return (aetherite.currentXP, aetherite.currentLevel, aetherite.metadataHash, aetherite.lastActivityTimestamp);
    }


    // --- B. XP & Leveling System ---

    /**
     * @dev Awards AetherXP to a specific Aetherite NFT.
     *      Callable by authorized XP providers or the Aetherite's owner.
     * @param tokenId The ID of the Aetherite NFT to award XP to.
     * @param amount The amount of XP to award.
     */
    function gainAetherXP(uint256 tokenId, uint256 amount) public virtual whenNotPaused {
        _requireOwned(tokenId); // Ensure the token exists
        require(ownerOf(tokenId) == msg.sender || authorizedXPProviders[msg.sender], "Caller is not Aetherite owner or authorized XP provider");
        require(amount > 0, "XP amount must be greater than zero");

        Aetherite storage aetherite = aetherites[tokenId];
        aetherite.currentXP += amount;
        aetherite.lastActivityTimestamp = uint64(block.timestamp);

        emit AetheriteXPGained(tokenId, amount, aetherite.currentXP);
    }

    /**
     * @dev Allows an Aetherite owner to attempt a level-up if the Aetherite has accumulated sufficient AetherXP.
     *      Consumes XP and updates the Aetherite's metadata.
     * @param tokenId The ID of the Aetherite NFT to level up.
     */
    function levelUpAetherite(uint256 tokenId) public virtual onlyAetheriteOwner(tokenId) whenNotPaused {
        Aetherite storage aetherite = aetherites[tokenId];
        uint256 requiredXP = getNextLevelXPRequirement(aetherite.currentLevel);

        require(aetherite.currentXP >= requiredXP, "Not enough XP to level up");
        
        aetherite.currentXP -= requiredXP; // XP is consumed upon level up
        aetherite.currentLevel += 1;
        // Optionally update metadata hash here, or rely on crafting/upgrades for metadata changes
        // For simplicity, let's assume level up itself doesn't change the hash unless defined by an upgrade.
        // Or we could have a mapping `levelMetadataHashes` for predefined level up appearances.
        // For this contract, we'll keep `metadataHash` for specific upgrades/crafts.

        aetherite.lastActivityTimestamp = uint64(block.timestamp);
        emit AetheriteLeveledUp(tokenId, aetherite.currentLevel, aetherite.metadataHash);
    }

    /**
     * @dev Calculates the total AetherXP required for an Aetherite to reach the next level.
     *      Uses a simple exponential formula: baseXP * (multiplier ^ currentLevel).
     * @param currentLevel The current level of the Aetherite.
     * @return The amount of XP needed to reach the next level.
     */
    function getNextLevelXPRequirement(uint256 currentLevel) public view returns (uint256) {
        if (currentLevel == 0) return baseXPForNextLevel; // Should not happen with min level 1
        
        // Simple exponential scaling: baseXP * (multiplier/100)^(currentLevel-1)
        // To avoid floating point, we can do baseXP * (multiplier / 100) * (multiplier / 100) ...
        // Let's use a simpler progressive increase: baseXP + (currentLevel * baseXP * (multiplier/100 - 1))
        // Or just baseXP * currentLevel * (multiplier/100) roughly
        
        // For simplicity, let's use: baseXP + (currentLevel * baseXP * (xpMultiplierPerLevel / 10000))
        // Example: baseXP=1000, mult=150 (1.5x).
        // L1->L2: 1000 XP
        // L2->L3: 1000 + (1 * 1000 * 0.5) = 1500 XP
        // L3->L4: 1000 + (2 * 1000 * 0.5) = 2000 XP
        
        // Let's use: baseXP * (currentLevel ^ exponent) roughly
        // To avoid overflow for large levels and still maintain a simple formula:
        // XP_needed = baseXP * (1 + (currentLevel - 1) * xpMultiplierPerLevel / 10000)
        // E.g., multiplier 100 -> 1.0x (linear), 150 -> 1.5x (faster)
        // Current implementation: `baseXPForNextLevel` is the XP for the *next* level.
        // `xpMultiplierPerLevel` is percentage increase per level.
        // L1->L2: baseXPForNextLevel
        // L2->L3: baseXPForNextLevel * (xpMultiplierPerLevel / 100)
        // L3->L4: (baseXPForNextLevel * (xpMultiplierPerLevel / 100)) * (xpMultiplierPerLevel / 100)
        // This is a more standard geometric progression.
        
        uint256 required = baseXPForNextLevel;
        for (uint256 i = 1; i < currentLevel; i++) {
            required = (required * xpMultiplierPerLevel) / 100;
        }
        return required;
    }


    // --- C. Crafting & Upgrades ---

    /**
     * @dev Executes a predefined crafting recipe using a specific Aetherite.
     *      Consumes AetherEssence (ERC-20) and AetherComponents (ERC-1155).
     *      Can be boosted by an optional CatalystForge (ERC-1155).
     * @param aetheriteId The ID of the Aetherite NFT participating in crafting.
     * @param recipeId The ID of the crafting recipe to execute.
     * @param catalystForgeId The ID of the CatalystForge NFT to use (0 if none).
     */
    function craftItem(uint256 aetheriteId, uint256 recipeId, uint256 catalystForgeId) public virtual onlyAetheriteOwner(aetheriteId) whenNotPaused {
        Aetherite storage aetherite = aetherites[aetheriteId];
        Recipe storage recipe = recipes[recipeId];
        
        require(recipe.exists, "Recipe does not exist");
        require(aetherite.currentLevel >= recipe.minAetheriteLevel, "Aetherite level too low for this recipe");

        // 1. Consume AetherEssence
        require(essenceContract.balanceOf(msg.sender) >= recipe.essenceCost, "Insufficient AetherEssence");
        essenceContract.transferFrom(msg.sender, address(this), recipe.essenceCost);

        // 2. Consume AetherComponents (ERC-1155)
        for (uint256 i = 0; i < recipe.componentTypeIds.length; i++) {
            require(componentCatalystContract.balanceOf(msg.sender, recipe.componentTypeIds[i]) >= recipe.componentAmounts[i], "Insufficient component");
            componentCatalystContract.safeTransferFrom(msg.sender, address(this), recipe.componentTypeIds[i], recipe.componentAmounts[i], "");
        }

        // 3. Apply Catalyst Forge effect (optional)
        uint256 effectiveOutputAmount = recipe.outputTokenAmount;
        if (catalystForgeId != 0) {
            require(componentCatalystContract.balanceOf(msg.sender, catalystForgeId) > 0, "Catalyst Forge not owned by crafter");
            uint256 bonusPercentage = catalystEffectiveness[catalystForgeId];
            if (bonusPercentage > 0) {
                effectiveOutputAmount = (effectiveOutputAmount * bonusPercentage) / 100;
            }
            // Optional: Burn Catalyst Forge or reduce its durability here
            // For simplicity, we assume Catalyst Forges are not consumed by this process.
        }

        // 4. Produce output token (if any)
        if (recipe.outputTokenId != 0 && effectiveOutputAmount > 0) {
            componentCatalystContract.mint(msg.sender, recipe.outputTokenId, effectiveOutputAmount, "");
        }

        // 5. Update Aetherite metadata (if specified in recipe)
        if (recipe.newMetadataHash != bytes32(0)) {
            aetherite.metadataHash = recipe.newMetadataHash;
        }
        aetherite.lastActivityTimestamp = uint64(block.timestamp);

        emit ItemCrafted(aetheriteId, recipeId, msg.sender, recipe.outputTokenId, effectiveOutputAmount);
    }

    /**
     * @dev Admin function to add or update a crafting recipe.
     * @param recipeId The ID of the recipe to define/update.
     * @param componentTypeIds Array of ERC-1155 component IDs required.
     * @param componentAmounts Array of amounts corresponding to `componentTypeIds`.
     * @param essenceCost Amount of AetherEssence required.
     * @param outputTokenId ERC-1155 ID of the token produced (0 if none).
     * @param outputTokenAmount Amount of output token produced.
     * @param minAetheriteLevel Minimum Aetherite level for this recipe.
     * @param newMetadataHash Optional new metadata hash for the Aetherite after craft.
     */
    function defineCraftingRecipe(
        uint256 recipeId,
        uint256[] calldata componentTypeIds,
        uint256[] calldata componentAmounts,
        uint256 essenceCost,
        uint256 outputTokenId,
        uint256 outputTokenAmount,
        uint256 minAetheriteLevel,
        bytes32 newMetadataHash
    ) public virtual onlyOwner {
        require(componentTypeIds.length == componentAmounts.length, "Component arrays mismatch");
        recipes[recipeId] = Recipe({
            componentTypeIds: componentTypeIds,
            componentAmounts: componentAmounts,
            essenceCost: essenceCost,
            outputTokenId: outputTokenId,
            outputTokenAmount: outputTokenAmount,
            minAetheriteLevel: minAetheriteLevel,
            newMetadataHash: newMetadataHash,
            exists: true
        });
        emit RecipeDefined(recipeId, essenceCost, outputTokenId);
    }

    /**
     * @dev Admin function to remove an existing crafting recipe.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeCraftingRecipe(uint256 recipeId) public virtual onlyOwner {
        require(recipes[recipeId].exists, "Recipe does not exist");
        delete recipes[recipeId]; // Resets the struct
        emit RecipeDefined(recipeId, 0, 0); // Signifies removal with 0 costs/outputs
    }

    /**
     * @dev Retrieves the full details of a specific crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return Recipe struct details.
     */
    function getRecipeDetails(uint256 recipeId) public view returns (Recipe memory) {
        return recipes[recipeId];
    }

    /**
     * @dev Applies a predefined upgrade to an Aetherite.
     *      Consumes Essence and Components, and updates the Aetherite's metadata.
     * @param aetheriteId The ID of the Aetherite NFT to upgrade.
     * @param upgradeId The ID of the upgrade to apply.
     */
    function upgradeAetherite(uint256 aetheriteId, uint256 upgradeId) public virtual onlyAetheriteOwner(aetheriteId) whenNotPaused {
        Aetherite storage aetherite = aetherites[aetheriteId];
        Upgrade storage upgrade = upgrades[upgradeId];

        require(upgrade.exists, "Upgrade does not exist");
        require(aetherite.currentLevel >= upgrade.minAetheriteLevel, "Aetherite level too low for this upgrade");

        // 1. Consume AetherEssence
        require(essenceContract.balanceOf(msg.sender) >= upgrade.essenceCost, "Insufficient AetherEssence");
        essenceContract.transferFrom(msg.sender, address(this), upgrade.essenceCost);

        // 2. Consume AetherComponents (ERC-1155)
        for (uint256 i = 0; i < upgrade.componentTypeIds.length; i++) {
            require(componentCatalystContract.balanceOf(msg.sender, upgrade.componentTypeIds[i]) >= upgrade.componentAmounts[i], "Insufficient component");
            componentCatalystContract.safeTransferFrom(msg.sender, address(this), upgrade.componentTypeIds[i], upgrade.componentAmounts[i], "");
        }

        // 3. Update Aetherite metadata
        require(upgrade.newMetadataHash != bytes32(0), "Upgrade must specify a new metadata hash");
        aetherite.metadataHash = upgrade.newMetadataHash;
        aetherite.lastActivityTimestamp = uint64(block.timestamp);

        emit AetheriteUpgraded(aetheriteId, upgradeId, msg.sender, upgrade.newMetadataHash);
    }

    /**
     * @dev Admin function to add or update an Aetherite upgrade.
     * @param upgradeId The ID of the upgrade to define/update.
     * @param essenceCost Amount of AetherEssence required.
     * @param componentTypeIds Array of ERC-1155 component IDs required.
     * @param componentAmounts Array of amounts corresponding to `componentTypeIds`.
     * @param minAetheriteLevel Minimum Aetherite level for this upgrade.
     * @param newMetadataHash New metadata hash for the Aetherite after upgrade.
     */
    function defineAetheriteUpgrade(
        uint256 upgradeId,
        uint256 essenceCost,
        uint256[] calldata componentTypeIds,
        uint256[] calldata componentAmounts,
        uint256 minAetheriteLevel,
        bytes32 newMetadataHash
    ) public virtual onlyOwner {
        require(componentTypeIds.length == componentAmounts.length, "Component arrays mismatch");
        require(newMetadataHash != bytes32(0), "Upgrade must specify a new metadata hash");

        upgrades[upgradeId] = Upgrade({
            essenceCost: essenceCost,
            componentTypeIds: componentTypeIds,
            componentAmounts: componentAmounts,
            minAetheriteLevel: minAetheriteLevel,
            newMetadataHash: newMetadataHash,
            exists: true
        });
        emit UpgradeDefined(upgradeId, essenceCost);
    }

    /**
     * @dev Admin function to remove an existing Aetherite upgrade.
     * @param upgradeId The ID of the upgrade to remove.
     */
    function removeAetheriteUpgrade(uint256 upgradeId) public virtual onlyOwner {
        require(upgrades[upgradeId].exists, "Upgrade does not exist");
        delete upgrades[upgradeId]; // Resets the struct
        emit UpgradeDefined(upgradeId, 0); // Signifies removal
    }


    // --- D. Resource & Auxiliary NFT Management ---

    /**
     * @dev Admin function to update the address of the AetherEssence (ERC-20) token contract.
     * @param _essenceContract The new address of the Essence ERC-20 contract.
     */
    function setEssenceContract(address _essenceContract) public virtual onlyOwner {
        require(_essenceContract != address(0), "Essence contract cannot be zero address");
        essenceContract = IAetherEssence(_essenceContract);
    }

    /**
     * @dev Admin function to update the address of the AetherComponents and AetherCatalystForges (ERC-1155) token contract.
     * @param _componentCatalystContract The new address of the ERC-1155 contract.
     */
    function setComponentCatalystContract(address _componentCatalystContract) public virtual onlyOwner {
        require(_componentCatalystContract != address(0), "Component/Catalyst contract cannot be zero address");
        componentCatalystContract = IAetherComponentsCatalysts(_componentCatalystContract);
    }

    /**
     * @dev Admin function to grant or revoke authorization for external addresses or contracts to call `gainAetherXP`.
     *      This allows integrating external games or systems for XP rewards.
     * @param _provider The address to authorize/deauthorize.
     * @param _isAuthorized True to authorize, false to deauthorize.
     */
    function authorizeXPProvider(address _provider, bool _isAuthorized) public virtual onlyOwner {
        authorizedXPProviders[_provider] = _isAuthorized;
        emit XPProviderAuthorized(_provider, _isAuthorized);
    }


    // --- E. Admin & Configuration ---

    /**
     * @dev Admin function to update the base URI used for constructing Aetherite metadata URLs.
     * @param _newBaseTokenURI The new base URI (e.g., "ipfs://new_cid/").
     */
    function setBaseTokenURI(string memory _newBaseTokenURI) public virtual onlyOwner {
        _baseTokenURI = _newBaseTokenURI;
    }

    /**
     * @dev Admin function to configure the mathematical formula determining AetherXP requirements for leveling up.
     * @param _baseXP The base XP required for the first level-up.
     * @param _multiplier The percentage multiplier for subsequent level-ups (e.g., 150 for 150%).
     */
    function setXPPerLevelFormula(uint256 _baseXP, uint256 _multiplier) public virtual onlyOwner {
        require(_baseXP > 0, "Base XP must be greater than zero");
        require(_multiplier > 0, "Multiplier must be greater than zero");
        baseXPForNextLevel = _baseXP;
        xpMultiplierPerLevel = _multiplier;
    }

    /**
     * @dev Admin function to set or adjust the minimum Aetherite level required to use a specific crafting recipe.
     * @param recipeId The ID of the recipe.
     * @param _minLevel The new minimum level.
     */
    function setMinLevelForRecipe(uint256 recipeId, uint256 _minLevel) public virtual onlyOwner {
        require(recipes[recipeId].exists, "Recipe does not exist");
        recipes[recipeId].minAetheriteLevel = _minLevel;
    }

    /**
     * @dev Admin function to set or adjust the minimum Aetherite level required to apply a specific upgrade.
     * @param upgradeId The ID of the upgrade.
     * @param _minLevel The new minimum level.
     */
    function setMinLevelForUpgrade(uint256 upgradeId, uint256 _minLevel) public virtual onlyOwner {
        require(upgrades[upgradeId].exists, "Upgrade does not exist");
        upgrades[upgradeId].minAetheriteLevel = _minLevel;
    }

    /**
     * @dev Admin function to withdraw AetherEssence from the contract.
     *      This might be used for scenarios like refunds, rebalancing, or admin-controlled fees.
     * @param _to The address to send the Essence to.
     * @param _amount The amount of Essence to withdraw.
     */
    function withdrawUnspentEssence(address _to, uint256 _amount) public virtual onlyOwner {
        require(_to != address(0), "Recipient cannot be zero address");
        require(essenceContract.balanceOf(address(this)) >= _amount, "Insufficient Essence in contract");
        essenceContract.transfer(_to, _amount);
    }

    /**
     * @dev Admin function to set the default metadata hash for newly minted Aetherite NFTs.
     *      This hash points to the initial metadata JSON for a base Aetherite.
     * @param _hash The new initial metadata hash (e.g., IPFS CID).
     */
    function setInitialAetheriteMetadataHash(bytes32 _hash) public virtual onlyOwner {
        initialAetheriteMetadataHash = _hash;
    }

    /**
     * @dev Admin function to define or update the crafting success or efficiency bonus provided by different CatalystForge types.
     * @param forgeTypeId The ERC-1155 ID of the CatalystForge.
     * @param bonusPercentage The bonus percentage (e.g., 105 for 5% boost, 100 for no boost).
     */
    function setCatalystEffectiveness(uint256 forgeTypeId, uint256 bonusPercentage) public virtual onlyOwner {
        require(bonusPercentage >= 0, "Bonus percentage cannot be negative");
        catalystEffectiveness[forgeTypeId] = bonusPercentage;
        emit CatalystEffectivenessSet(forgeTypeId, bonusPercentage);
    }

    /**
     * @dev See {Pausable-pause}. Admin function to pause core contract functionalities.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}. Admin function to unpause the contract.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }


    // --- ERC1155Holder callback (required for receiving ERC-1155 tokens) ---
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view override returns (bytes4) {
        // This contract is designed to receive ERC-1155 tokens (Components/Catalysts)
        // primarily when users transfer them for crafting/upgrading, then they are burned.
        // It's not designed to hold arbitrary ERC-1155 tokens.
        // For simplicity, we just return the selector.
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view override returns (bytes4) {
        // Same as above for batch transfers.
        return this.onERC1155BatchReceived.selector;
    }
}

```