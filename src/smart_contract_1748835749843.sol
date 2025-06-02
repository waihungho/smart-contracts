Okay, let's design a smart contract system called `QuantumRealmForge`. This system incorporates dynamic NFTs, multi-token crafting, resource management, time-based mechanics (decay), state-dependent interactions (observation), non-transferable tokens (for reputation/skill), and governance over system parameters.

It's challenging to guarantee *zero* overlap with *any* open-source project, as many fundamental building blocks exist. However, this design aims for a unique *combination* of features and mechanics that are not commonly found together in a single, self-contained example contract.

---

**QuantumRealmForge Smart Contract System**

**Overview:**

The `QuantumRealmForge` is a complex crafting and synthesis system operating within a simulated "Quantum Realm." Users collect various `Essences` (ERC-20 tokens), combine them with `Catalysts` (ERC-1155 tokens) using predefined `Recipes` to forge `Artifacts` (dynamic ERC-721 NFTs). Artifacts have properties that can change over time or based on user actions (`Decay`, `Observe`, `Upgrade`, `Fuse`). Users can gain `Insight` (a non-transferable token) by interacting with the system, which can unlock capabilities. Artifacts can be deployed to `Dimensions` (simulated spaces) influencing their properties.

**Key Concepts:**

1.  **Essences (ERC-20):** Fungible resources needed for crafting and maintenance. Multiple types possible.
2.  **Artifacts (Dynamic ERC-721):** Unique non-fungible tokens with mutable properties stored on-chain. Properties change based on crafting inputs, upgrades, decay, observation, and fusion.
3.  **Insights (Simulated SBT):** A non-transferable score or token representing a user's knowledge, skill, or connection to the Realm. Gained through actions, used for unlocking features or benefits.
4.  **Dimensions (Simulated Spaces):** Conceptual locations where Artifacts can be deployed. Properties of the Dimension can influence deployed Artifacts, and vice versa. Represented simplistically by an ID and properties linked to an owner.
5.  **Catalysts (ERC-1155):** Special items that influence crafting or other processes (e.g., boost success rate, modify output properties).
6.  **Recipes:** On-chain configurations defining inputs (Essences, Catalysts, maybe other Artifacts) and outputs (new Artifact, upgraded Artifact properties, fusion result) for crafting and fusion.
7.  **Decay:** Artifact properties can degrade over time or usage. Requires maintenance (using Essences) to counteract.
8.  **Observation:** A unique action that can temporarily alter an Artifact's state or reveal hidden properties, simulating the observer effect in quantum mechanics.
9.  **Fusion:** Combining multiple Artifacts into a new, potentially more powerful or unique one, potentially transferring or blending properties.
10. **Governance/Parameters:** Key system parameters (recipes, decay rates, insight gain rates) can be set by an owner or a governance mechanism.

**Function Summary (20+ Functions):**

**A. Token Management (Essence - ERC-20 like):**
1.  `mintEssence(address recipient, uint256 essenceType, uint256 amount)`: Mints a specific type and amount of Essence to a recipient.
2.  `burnEssence(uint256 essenceType, uint256 amount)`: Burns a specific type and amount of Essence from the caller's balance.
3.  `transferEssence(uint256 essenceType, address recipient, uint256 amount)`: Transfers Essence between users.
4.  `essenceBalanceOf(address account, uint256 essenceType)`: Get the balance of a specific Essence type for an account.
5.  `getTotalEssenceSupply(uint256 essenceType)`: Get the total supply of a specific Essence type.

**B. Artifact Management (Dynamic ERC-721):**
6.  `craftArtifact(uint256 recipeId, uint256[] essenceTypes, uint256[] essenceAmounts, uint256[] catalystIds, uint256[] catalystAmounts)`: Crafts a new Artifact using specified recipe, Essences, and Catalysts.
7.  `upgradeArtifact(uint256 artifactId, uint256 recipeId, uint256[] essenceTypes, uint256[] essenceAmounts, uint256[] catalystIds, uint256[] catalystAmounts)`: Upgrades an existing Artifact based on a recipe, consuming resources.
8.  `fuseArtifacts(uint256 recipeId, uint256[] artifactIdsToFuse, uint256[] essenceTypes, uint256[] essenceAmounts)`: Fuses multiple Artifacts into a new one (or modifies one), consuming resources based on a recipe.
9.  `decayArtifact(uint256 artifactId)`: Applies decay effects to an Artifact based on time passed or usage, potentially reducing properties.
10. `maintainArtifact(uint256 artifactId, uint256[] essenceTypes, uint256[] essenceAmounts)`: Consumes Essences to counteract or reverse decay on an Artifact.
11. `observeArtifact(uint256 artifactId)`: Triggers a temporary state change or reveals hidden properties of an Artifact.
12. `getArtifactProperties(uint256 artifactId)`: Retrieves the current dynamic properties of an Artifact.
13. `isArtifactDecayed(uint256 artifactId)`: Checks if an Artifact is currently in a decayed state needing maintenance.
14. `listUserArtifacts(address account)`: Returns an array of Artifact IDs owned by an account.

**C. Insight Management (Simulated SBT):**
15. `gainInsight(address account, uint256 amount)`: Awards Insight to a specific account (non-transferable via standard means). (Admin/System call)
16. `spendInsight(uint256 amount)`: Allows a user to spend their accumulated Insight for benefits within the system.
17. `getInsightLevel(address account)`: Get the Insight level/points for an account.

**D. Dimension Management (Simulated Spaces):**
18. `claimDimension(uint256 dimensionId)`: Allows a user to claim ownership of a simulated Dimension ID.
19. `deployArtifactToDimension(uint256 artifactId, uint256 dimensionId)`: Places a user's Artifact into their claimed Dimension.
20. `reclaimArtifactFromDimension(uint256 artifactId, uint256 dimensionId)`: Removes an Artifact from a Dimension and returns it to the owner's inventory.
21. `getDimensionProperties(uint256 dimensionId)`: Retrieves the current properties of a Dimension (influenced by deployed Artifacts).
22. `listArtifactsInDimension(uint256 dimensionId)`: Lists Artifact IDs currently deployed in a Dimension.

**E. Catalyst Management (ERC-1155 like):**
23. `mintCatalyst(address recipient, uint256 catalystId, uint256 amount, bytes data)`: Mints a specific Catalyst type to a recipient.
24. `catalystBalanceOf(address account, uint256 catalystId)`: Get the balance of a specific Catalyst type for an account.

**F. Recipe & Parameter Management (Admin/Governance):**
25. `setCraftingRecipe(uint256 recipeId, bytes recipeData)`: Sets or updates the data for a crafting recipe.
26. `setUpgradeRecipe(uint256 recipeId, bytes recipeData)`: Sets or updates the data for an upgrade recipe.
27. `setFusionRecipe(uint256 recipeId, bytes recipeData)`: Sets or updates the data for a fusion recipe.
28. `setDecayRate(uint256 artifactTypeId, uint256 rate)`: Sets the decay rate for a specific type of Artifact.
29. `setInsightGainRate(uint256 actionType, uint256 rate)`: Sets the Insight gain rate for different system actions.
30. `getRecipe(uint256 recipeId)`: Retrieves the data for a specific recipe.

**G. Admin & Utility:**
31. `pause()`: Pauses core system functions (crafting, upgrading, etc.).
32. `unpause()`: Unpauses core system functions.
33. `withdrawFunds(address payable recipient)`: Withdraws any accumulated Ether or tokens (if applicable, not explicitly modeled here but standard practice).
34. `transferOwnership(address newOwner)`: Transfers contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Outline & Function Summary ---
//
// QuantumRealmForge Smart Contract System
//
// Overview:
// A complex crafting and synthesis system involving multiple token types (Essences ERC20, Catalysts ERC1155, Artifacts ERC721),
// dynamic NFT properties, time-based decay, state-dependent observation, non-transferable Insight, and simulated Dimensions.
//
// Key Concepts: Essences (ERC20), Artifacts (Dynamic ERC721), Insights (SBT-like), Dimensions (simulated space),
// Catalysts (ERC1155), Recipes, Dynamic Properties, Decay, Observation, Fusion, Governance.
//
// Function Summary (20+ Functions):
//
// A. Token Management (Essence - ERC-20 like):
//  1. mintEssence(address recipient, uint256 essenceType, uint256 amount): Mints a specific type and amount of Essence.
//  2. burnEssence(uint256 essenceType, uint256 amount): Burns Essence from caller's balance.
//  3. transferEssence(uint256 essenceType, address recipient, uint256 amount): Transfers Essence.
//  4. essenceBalanceOf(address account, uint256 essenceType): Get balance of specific Essence.
//  5. getTotalEssenceSupply(uint256 essenceType): Get total supply of specific Essence.
//
// B. Artifact Management (Dynamic ERC-721):
//  6. craftArtifact(uint256 recipeId, uint256[] essenceTypes, uint256[] essenceAmounts, uint256[] catalystIds, uint256[] catalystAmounts): Crafts a new Artifact.
//  7. upgradeArtifact(uint256 artifactId, uint256 recipeId, uint256[] essenceTypes, uint256[] essenceAmounts, uint256[] catalystIds, uint256[] catalystAmounts): Upgrades an Artifact.
//  8. fuseArtifacts(uint256 recipeId, uint256[] artifactIdsToFuse, uint256[] essenceTypes, uint256[] essenceAmounts): Fuses multiple Artifacts.
//  9. decayArtifact(uint256 artifactId): Applies decay effects.
// 10. maintainArtifact(uint256 artifactId, uint256[] essenceTypes, uint256[] essenceAmounts): Counteracts decay.
// 11. observeArtifact(uint256 artifactId): Triggers observation state change/reveal.
// 12. getArtifactProperties(uint256 artifactId): Retrieves dynamic properties.
// 13. isArtifactDecayed(uint256 artifactId): Checks decay status.
// 14. listUserArtifacts(address account): Lists Artifacts owned by an account. (via ERC721Enumerable)
//
// C. Insight Management (Simulated SBT):
// 15. gainInsight(address account, uint256 amount): Awards Insight (Admin/System).
// 16. spendInsight(uint256 amount): Allows user to spend Insight.
// 17. getInsightLevel(address account): Get user's Insight level.
//
// D. Dimension Management (Simulated Spaces):
// 18. claimDimension(uint256 dimensionId): Claims ownership of a Dimension.
// 19. deployArtifactToDimension(uint256 artifactId, uint256 dimensionId): Deploys Artifact to a Dimension.
// 20. reclaimArtifactFromDimension(uint256 artifactId, uint256 dimensionId): Reclaims Artifact from a Dimension.
// 21. getDimensionProperties(uint256 dimensionId): Retrieves Dimension properties.
// 22. listArtifactsInDimension(uint256 dimensionId): Lists Artifacts in a Dimension.
//
// E. Catalyst Management (ERC-1155 like):
// 23. mintCatalyst(address recipient, uint256 catalystId, uint256 amount, bytes data): Mints Catalyst.
// 24. catalystBalanceOf(address account, uint256 catalystId): Get balance of specific Catalyst.
//
// F. Recipe & Parameter Management (Admin/Governance):
// 25. setCraftingRecipe(uint256 recipeId, bytes memory recipeData): Sets crafting recipe data.
// 26. setUpgradeRecipe(uint256 recipeId, bytes memory recipeData): Sets upgrade recipe data.
// 27. setFusionRecipe(uint256 recipeId, bytes memory recipeData): Sets fusion recipe data.
// 28. setDecayRate(uint256 artifactTypeId, uint256 rate): Sets decay rate for Artifact type.
// 29. setInsightGainRate(uint256 actionType, uint256 rate): Sets Insight gain rate for actions.
// 30. getRecipe(uint256 recipeId): Retrieves recipe data.
//
// G. Admin & Utility:
// 31. pause(): Pauses functions.
// 32. unpause(): Unpauses functions.
// 33. withdrawFunds(address payable recipient): Withdraws funds.
// 34. transferOwnership(address newOwner): Transfers ownership.

// --- Custom Errors ---
error QuantumRealmForge__InsufficientEssence(uint256 essenceType, uint256 required, uint256 available);
error QuantumRealmForge__InsufficientCatalyst(uint256 catalystId, uint256 required, uint256 available);
error QuantumRealmForge__InsufficientInsight(uint256 required, uint256 available);
error QuantumRealmForge__ArtifactNotFound(uint256 artifactId);
error QuantumRealmForge__ArtifactNotOwned(uint256 artifactId, address owner);
error QuantumRealmForge__ArtifactCannotBeDecayed(uint256 artifactId);
error QuantumRealmForge__ArtifactNotDecayed(uint256 artifactId);
error QuantumRealmForge__ArtifactAlreadyObserved(uint256 artifactId);
error QuantumRealmForge__ArtifactNotInDimension(uint256 artifactId, uint256 dimensionId);
error QuantumRealmForge__DimensionNotClaimed(uint256 dimensionId);
error QuantumRealmForge__DimensionAlreadyClaimed(uint256 dimensionId);
error QuantumRealmForge__NotDimensionOwner(uint256 dimensionId, address owner);
error QuantumRealmForge__InvalidRecipe(uint256 recipeId);
error QuantumRealmForge__InsufficientArtifactsForFusion(uint256 recipeId, uint256 required, uint256 provided);
error QuantumRealmForge__Unauthorized();
error QuantumRealmForge__Paused();
error QuantumRealmForge__NotPaused();
error QuantumRealmForge__ArtifactAlreadyInDimension(uint256 artifactId);


// --- Structs ---
struct ArtifactProperties {
    uint256 artifactTypeId; // General type ID (e.g., 1=Tool, 2=Weapon, 3=Entity)
    uint256 level;
    uint256 quality;        // 0-100
    int256 energy;         // Can be positive or negative, represents charge/stability
    uint256 lastDecayTimestamp;
    bool isInObservedState; // Temporary state after observation
    uint256 observedUntilTimestamp;
    uint256 deployedDimensionId; // 0 if not deployed
    bytes dynamicMetadata;  // Flexible storage for type-specific properties
}

struct DimensionProperties {
    address owner;
    uint256 creationTimestamp;
    // Add more properties here that might be influenced by deployed artifacts
    uint256 stability; // e.g., 0-100
    uint256 yieldRate; // e.g., affects passive essence generation (simulated)
    uint256[] deployedArtifactIds; // List of artifacts currently in this dimension
}

// Simplified Recipe data structure - In a real complex system, this would be more detailed
// potentially with input arrays, output structs, probability, etc.
// For this example, bytes is used as a placeholder for complex recipe data.
struct Recipe {
    uint256 recipeType; // e.g., 1=Craft, 2=Upgrade, 3=Fuse
    bytes recipeData;   // Encoded data defining inputs/outputs/effects
    bool exists;
}

// --- Events ---
event EssenceMinted(address indexed recipient, uint256 indexed essenceType, uint256 amount);
event EssenceBurned(address indexed account, uint256 indexed essenceType, uint256 amount);
event EssenceTransferred(uint256 indexed essenceType, address indexed sender, address indexed recipient, uint256 amount);

event ArtifactCrafted(address indexed owner, uint256 indexed artifactId, uint256 recipeId, uint256 artifactTypeId);
event ArtifactUpgraded(address indexed owner, uint256 indexed artifactId, uint256 recipeId, uint256 newLevel);
event ArtifactFused(address indexed owner, uint256 indexed resultArtifactId, uint256 recipeId, uint256[] consumedArtifactIds);
event ArtifactDecayed(uint256 indexed artifactId, int256 energyChange, uint256 newQuality);
event ArtifactMaintained(uint256 indexed artifactId, uint256 newEnergy);
event ArtifactObserved(uint256 indexed artifactId, uint256 observedUntilTimestamp);
event ArtifactPropertiesUpdated(uint256 indexed artifactId, bytes newDynamicMetadata);

event InsightGained(address indexed account, uint256 amount, uint256 newInsightLevel);
event InsightSpent(address indexed account, uint256 amount, uint256 newInsightLevel);

event DimensionClaimed(address indexed owner, uint256 indexed dimensionId);
event ArtifactDeployedToDimension(uint256 indexed artifactId, uint256 indexed dimensionId, address indexed owner);
event ArtifactReclaimedFromDimension(uint256 indexed artifactId, uint256 indexed dimensionId, address indexed owner);
event DimensionPropertiesUpdated(uint256 indexed dimensionId, bytes newProperties); // Simplified

event CatalystMinted(address indexed recipient, uint256 indexed catalystId, uint256 amount);

event RecipeSet(uint256 indexed recipeId, uint256 indexed recipeType);
event DecayRateSet(uint256 indexed artifactTypeId, uint256 rate);
event InsightGainRateSet(uint256 indexed actionType, uint256 rate);

event ContractPaused(address account);
event ContractUnpaused(address account);


contract QuantumRealmForge is ERC721Enumerable, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Essences (Simulated ERC-20 per type)
    mapping(uint256 => mapping(address => uint256)) private _essenceBalances;
    mapping(uint256 => uint256) private _totalEssenceSupply;

    // Artifacts (Dynamic ERC-721 properties)
    Counters.Counter private _artifactTokenIds;
    mapping(uint256 => ArtifactProperties) private _artifactProperties;

    // Insights (Simulated SBT)
    mapping(address => uint256) private _insightLevels;

    // Dimensions (Simulated Spaces)
    mapping(uint256 => DimensionProperties) private _dimensions;
    mapping(uint256 => bool) private _isDimensionClaimed; // To easily check existence

    // Catalysts (Simulated ERC-1155 per type)
    mapping(uint256 => mapping(address => uint256)) private _catalystBalances;
    // Note: ERC-1155 requires a bit more infrastructure (like hooks),
    // this is a simplified balance tracking for the sake of the example.

    // Recipes and Parameters
    mapping(uint256 => Recipe) private _recipes; // recipeId => Recipe
    mapping(uint256 => uint256) private _decayRates; // artifactTypeId => rate (e.g., decay per day/hour)
    mapping(uint256 => uint256) private _insightGainRates; // actionType => rate

    // Constants (Example Types)
    uint256 constant ESSENCE_FLUX = 1;
    uint256 constant ESSENCE_ECHO = 2;
    uint256 constant ESSENCE_VOID = 3;
    uint256 constant ESSENCE_CHRONON = 4;

    uint256 constant ARTIFACT_TYPE_TOOL = 1;
    uint256 constant ARTIFACT_TYPE_WEAPON = 2;
    uint256 constant ARTIFACT_TYPE_ENTITY = 3;

    uint256 constant RECIPE_TYPE_CRAFT = 1;
    uint256 constant RECIPE_TYPE_UPGRADE = 2;
    uint256 constant RECIPE_TYPE_FUSE = 3;

    uint256 constant ACTION_CRAFT = 1;
    uint256 constant ACTION_UPGRADE = 2;
    uint256 constant ACTION_FUSE = 3;
    uint256 constant ACTION_OBSERVE = 4;
    uint256 constant ACTION_MAINTAIN = 5;

    // --- Constructor ---
    constructor() ERC721("QuantumArtifact", "QRART") Ownable(msg.sender) {}

    // --- Modifiers ---
    modifier whenNotPaused() override {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() override {
        _requirePaused();
        _;
    }

    modifier onlyArtifactOwner(uint256 artifactId) {
        if (ownerOf(artifactId) != msg.sender) {
            revert QuantumRealmForge__ArtifactNotOwned(artifactId, msg.sender);
        }
        _;
    }

    modifier onlyDimensionOwner(uint256 dimensionId) {
        if (!_isDimensionClaimed[dimensionId] || _dimensions[dimensionId].owner != msg.sender) {
             revert QuantumRealmForge__NotDimensionOwner(dimensionId, msg.sender);
        }
        _;
    }

    // --- ERC721 Overrides (for Pausable and Enumerable) ---
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._transfer(from, to, tokenId);
        // Handle potential state changes on transfer, e.g., removing from dimension
         if (_artifactProperties[tokenId].deployedDimensionId != 0) {
            uint256 dimId = _artifactProperties[tokenId].deployedDimensionId;
            // Internal function to remove artifact from dimension's list
            _removeArtifactFromDimensionList(tokenId, dimId);
            _artifactProperties[tokenId].deployedDimensionId = 0;
        }
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

     function totalSupply() public view override(ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }

    function tokenByIndex(uint256 index) public view override(ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    // ERC721 transfers (safeTransferFrom, transferFrom) are inherited and work with Pausable/Enumerable overrides.
    // balance of (14. listUserArtifacts is covered by ERC721Enumerable.tokenOfOwnerByIndex and totalSupply combined)
    // ownerOf (17. part of standard ERC721)
    // approve, setApprovalForAll (part of standard ERC721)

    // --- A. Token Management (Essence - ERC-20 like) ---

    /// @notice Mints a specific type and amount of Essence to a recipient.
    /// @param recipient The address to mint Essence to.
    /// @param essenceType The type of Essence (e.g., ESSENCE_FLUX).
    /// @param amount The amount of Essence to mint.
    function mintEssence(address recipient, uint256 essenceType, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        _essenceBalances[essenceType][recipient] = _essenceBalances[essenceType][recipient].add(amount);
        _totalEssenceSupply[essenceType] = _totalEssenceSupply[essenceType].add(amount);
        emit EssenceMinted(recipient, essenceType, amount);
    }

    /// @notice Burns a specific type and amount of Essence from the caller's balance.
    /// @param essenceType The type of Essence to burn.
    /// @param amount The amount of Essence to burn.
    function burnEssence(uint256 essenceType, uint256 amount) external whenNotPaused {
        if (_essenceBalances[essenceType][msg.sender] < amount) {
             revert QuantumRealmForge__InsufficientEssence(essenceType, amount, _essenceBalances[essenceType][msg.sender]);
        }
        _essenceBalances[essenceType][msg.sender] = _essenceBalances[essenceType][msg.sender].sub(amount);
        _totalEssenceSupply[essenceType] = _totalEssenceSupply[essenceType].sub(amount);
        emit EssenceBurned(msg.sender, essenceType, amount);
    }

    /// @notice Transfers a specific type and amount of Essence between users.
    /// @param essenceType The type of Essence to transfer.
    /// @param recipient The address to transfer Essence to.
    /// @param amount The amount of Essence to transfer.
    function transferEssence(uint256 essenceType, address recipient, uint256 amount) external whenNotPaused {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_essenceBalances[essenceType][msg.sender] < amount) {
             revert QuantumRealmForge__InsufficientEssence(essenceType, amount, _essenceBalances[essenceType][msg.sender]);
        }
        _essenceBalances[essenceType][msg.sender] = _essenceBalances[essenceType][msg.sender].sub(amount);
        _essenceBalances[essenceType][recipient] = _essenceBalances[essenceType][recipient].add(amount);
        emit EssenceTransferred(essenceType, msg.sender, recipient, amount);
    }

     /// @notice Get the balance of a specific Essence type for an account.
     /// @param account The address to query.
     /// @param essenceType The type of Essence.
     /// @return The balance of the specified Essence type.
    function essenceBalanceOf(address account, uint256 essenceType) public view returns (uint256) {
        return _essenceBalances[essenceType][account];
    }

     /// @notice Get the total supply of a specific Essence type.
     /// @param essenceType The type of Essence.
     /// @return The total supply of the specified Essence type.
    function getTotalEssenceSupply(uint256 essenceType) public view returns (uint256) {
        return _totalEssenceSupply[essenceType];
    }


    // --- B. Artifact Management (Dynamic ERC-721) ---

    /// @notice Crafts a new Artifact using specified recipe, Essences, and Catalysts.
    /// @param recipeId The ID of the crafting recipe to use.
    /// @param essenceTypes Array of Essence types required by the recipe.
    /// @param essenceAmounts Array of corresponding Essence amounts.
    /// @param catalystIds Array of Catalyst IDs required by the recipe.
    /// @param catalystAmounts Array of corresponding Catalyst amounts.
    /// @dev This is a simplified implementation. Real recipe logic would be complex.
    function craftArtifact(
        uint256 recipeId,
        uint256[] memory essenceTypes,
        uint256[] memory essenceAmounts,
        uint256[] memory catalystIds,
        uint256[] memory catalystAmounts
    ) external whenNotPaused {
        Recipe storage recipe = _recipes[recipeId];
        if (!recipe.exists || recipe.recipeType != RECIPE_TYPE_CRAFT) {
            revert QuantumRealmForge__InvalidRecipe(recipeId);
        }

        // --- Simulate Resource Consumption based on recipeData ---
        // In a real scenario, recipeData would be decoded here to get required inputs.
        // For this example, we just consume the provided inputs if the user has them.
        // A real recipe would define *which* inputs are needed, not just take arbitrary ones.
        require(essenceTypes.length == essenceAmounts.length, "Invalid essence input arrays");
        require(catalystIds.length == catalystAmounts.length, "Invalid catalyst input arrays");

        for (uint i = 0; i < essenceTypes.length; i++) {
            if (_essenceBalances[essenceTypes[i]][msg.sender] < essenceAmounts[i]) {
                revert QuantumRealmForge__InsufficientEssence(essenceTypes[i], essenceAmounts[i], _essenceBalances[essenceTypes[i]][msg.sender]);
            }
        }
         for (uint i = 0; i < catalystIds.length; i++) {
            if (_catalystBalances[catalystIds[i]][msg.sender] < catalystAmounts[i]) {
                revert QuantumRealmForge__InsufficientCatalyst(catalystIds[i], catalystAmounts[i], _catalystBalances[catalystIds[i]][msg.sender]);
            }
        }

        // Consume resources
        for (uint i = 0; i < essenceTypes.length; i++) {
            _essenceBalances[essenceTypes[i]][msg.sender] = _essenceBalances[essenceTypes[i]][msg.sender].sub(essenceAmounts[i]);
             _totalEssenceSupply[essenceTypes[i]] = _totalEssenceSupply[essenceTypes[i]].sub(essenceAmounts[i]); // Assuming burning on use
            emit EssenceBurned(msg.sender, essenceTypes[i], essenceAmounts[i]); // Or a different event if transferred to contract
        }
         for (uint i = 0; i < catalystIds.length; i++) {
            // Simulate burning catalyst on use
            _catalystBalances[catalystIds[i]][msg.sender] = _catalystBalances[catalystIds[i]][msg.sender].sub(catalystAmounts[i]);
             emit CatalystBurned(msg.sender, catalystIds[i], catalystAmounts[i]); // Assuming a catalyst burn event
        }

        // --- Create New Artifact ---
        _artifactTokenIds.increment();
        uint256 newArtifactId = _artifactTokenIds.current();

        // Simulate initial properties based on recipe/inputs
        ArtifactProperties memory newProps;
        newProps.artifactTypeId = ARTIFACT_TYPE_TOOL; // Example type based on recipe logic (not implemented here)
        newProps.level = 1;
        newProps.quality = 50; // Example base quality
        newProps.energy = 100; // Example base energy
        newProps.lastDecayTimestamp = block.timestamp;
        newProps.isInObservedState = false;
        newProps.observedUntilTimestamp = 0;
        newProps.deployedDimensionId = 0;
        newProps.dynamicMetadata = recipe.recipeData; // Example: recipe data influences initial metadata

        _artifactProperties[newArtifactId] = newProps;

        _safeMint(msg.sender, newArtifactId);

        // Simulate Insight gain for crafting
        _gainInsight(msg.sender, _insightGainRates[ACTION_CRAFT]);

        emit ArtifactCrafted(msg.sender, newArtifactId, recipeId, newProps.artifactTypeId);
    }

    /// @notice Upgrades an existing Artifact based on a recipe, consuming resources.
    /// @param artifactId The ID of the Artifact to upgrade.
    /// @param recipeId The ID of the upgrade recipe to use.
    /// @param essenceTypes Array of Essence types required.
    /// @param essenceAmounts Array of corresponding Essence amounts.
    /// @param catalystIds Array of Catalyst IDs required.
    /// @param catalystAmounts Array of corresponding Catalyst amounts.
    /// @dev Simplified resource consumption like craftArtifact.
    function upgradeArtifact(
        uint256 artifactId,
        uint256 recipeId,
        uint256[] memory essenceTypes,
        uint256[] memory essenceAmounts,
        uint256[] memory catalystIds,
        uint256[] memory catalystAmounts
    ) external whenNotPaused onlyArtifactOwner(artifactId) {
        Recipe storage recipe = _recipes[recipeId];
        if (!recipe.exists || recipe.recipeType != RECIPE_TYPE_UPGRADE) {
            revert QuantumRealmForge__InvalidRecipe(recipeId);
        }
         if (_artifactProperties[artifactId].deployedDimensionId != 0) {
             revert QuantumRealmForge__ArtifactAlreadyInDimension(artifactId);
         }


        // Simulate Resource Consumption (similar to craft)
         require(essenceTypes.length == essenceAmounts.length, "Invalid essence input arrays");
        require(catalystIds.length == catalystAmounts.length, "Invalid catalyst input arrays");

        for (uint i = 0; i < essenceTypes.length; i++) {
            if (_essenceBalances[essenceTypes[i]][msg.sender] < essenceAmounts[i]) {
                revert QuantumRealmForge__InsufficientEssence(essenceTypes[i], essenceAmounts[i], _essenceBalances[essenceTypes[i]][msg.sender]);
            }
        }
         for (uint i = 0; i < catalystIds.length; i++) {
            if (_catalystBalances[catalystIds[i]][msg.sender] < catalystAmounts[i]) {
                revert QuantumRealmForge__InsufficientCatalyst(catalystIds[i], catalystAmounts[i], _catalystBalances[catalystIds[i]][msg.sender]);
            }
        }

        for (uint i = 0; i < essenceTypes.length; i++) {
            _essenceBalances[essenceTypes[i]][msg.sender] = _essenceBalances[essenceTypes[i]][msg.sender].sub(essenceAmounts[i]);
             _totalEssenceSupply[essenceTypes[i]] = _totalEssenceSupply[essenceTypes[i]].sub(essenceAmounts[i]);
             emit EssenceBurned(msg.sender, essenceTypes[i], essenceAmounts[i]);
        }
         for (uint i = 0; i < catalystIds.length; i++) {
            _catalystBalances[catalystIds[i]][msg.sender] = _catalystBalances[catalystIds[i]][msg.sender].sub(catalystAmounts[i]);
            emit CatalystBurned(msg.sender, catalystIds[i], catalystAmounts[i]);
        }


        // --- Simulate Artifact Property Update ---
        ArtifactProperties storage props = _artifactProperties[artifactId];
        props.level = props.level.add(1);
        props.quality = props.quality.add(5).min(100); // Example: Quality increases
        props.energy = props.energy.add(50);        // Example: Energy refilled/increased
        // Simulate updating dynamic metadata based on recipe
        props.dynamicMetadata = abi.encodePacked(props.dynamicMetadata, recipe.recipeData);


        // Simulate Insight gain for upgrading
        _gainInsight(msg.sender, _insightGainRates[ACTION_UPGRADE]);

        emit ArtifactUpgraded(msg.sender, artifactId, recipeId, props.level);
        emit ArtifactPropertiesUpdated(artifactId, props.dynamicMetadata); // Emit event for dynamic property changes
    }

    /// @notice Fuses multiple Artifacts into a new one (or modifies one), consuming resources based on a recipe.
    /// @param recipeId The ID of the fusion recipe.
    /// @param artifactIdsToFuse Array of Artifact IDs to consume in the fusion.
    /// @param essenceTypes Array of Essence types required.
    /// @param essenceAmounts Array of corresponding Essence amounts.
    /// @dev This is a complex operation. Simplified here. Assumes the first artifactIdToFuse is the target if not creating a new one.
    function fuseArtifacts(
        uint256 recipeId,
        uint256[] memory artifactIdsToFuse,
        uint256[] memory essenceTypes,
        uint256[] memory essenceAmounts
    ) external whenNotPaused {
        Recipe storage recipe = _recipes[recipeId];
        if (!recipe.exists || recipe.recipeType != RECIPE_TYPE_FUSE) {
            revert QuantumRealmForge__InvalidRecipe(recipeId);
        }

        require(artifactIdsToFuse.length >= 2, "Need at least 2 artifacts to fuse");
         for(uint i=0; i < artifactIdsToFuse.length; i++) {
            if (ownerOf(artifactIdsToFuse[i]) != msg.sender) {
                 revert QuantumRealmForge__ArtifactNotOwned(artifactIdsToFuse[i], msg.sender);
             }
              if (_artifactProperties[artifactIdsToFuse[i]].deployedDimensionId != 0) {
                 revert QuantumRealmForge__ArtifactAlreadyInDimension(artifactIdsToFuse[i]);
             }
         }


        // Simulate Resource Consumption (similar to craft)
         require(essenceTypes.length == essenceAmounts.length, "Invalid essence input arrays");

        for (uint i = 0; i < essenceTypes.length; i++) {
            if (_essenceBalances[essenceTypes[i]][msg.sender] < essenceAmounts[i]) {
                revert QuantumRealmForge__InsufficientEssence(essenceTypes[i], essenceAmounts[i], _essenceBalances[essenceTypes[i]][msg.sender]);
            }
        }

        for (uint i = 0; i < essenceTypes.length; i++) {
            _essenceBalances[essenceTypes[i]][msg.sender] = _essenceBalances[essenceTypes[i]][msg.sender].sub(essenceAmounts[i]);
            _totalEssenceSupply[essenceTypes[i]] = _totalEssenceSupply[essenceTypes[i]].sub(essenceAmounts[i]);
            emit EssenceBurned(msg.sender, essenceTypes[i], essenceAmounts[i]);
        }

        // --- Simulate Fusion Logic ---
        // In a real implementation, recipeData would define how properties are combined,
        // which artifact becomes the 'base', or if a new one is minted.
        // Example: Burn all but the first artifact, modify the first artifact's properties.
        uint256 resultArtifactId = artifactIdsToFuse[0];

        for (uint i = 1; i < artifactIdsToFuse.length; i++) {
            uint256 artifactToBurn = artifactIdsToFuse[i];
            // Transfer to burn address (address(0)) and clear properties
            _transfer(msg.sender, address(0), artifactToBurn);
             delete _artifactProperties[artifactToBurn];
        }

        // Modify properties of the resulting artifact
        ArtifactProperties storage resultProps = _artifactProperties[resultArtifactId];
        resultProps.level = resultProps.level.add(artifactIdsToFuse.length - 1); // Example: Level increases based on fused count
        resultProps.quality = resultProps.quality.add(10).min(100);
        resultProps.energy = resultProps.energy.add(100);
        // Simulate combining metadata
        for (uint i = 1; i < artifactIdsToFuse.length; i++) {
             resultProps.dynamicMetadata = abi.encodePacked(resultProps.dynamicMetadata, _artifactProperties[artifactIdsToFuse[i]].dynamicMetadata);
        }
        resultProps.dynamicMetadata = abi.encodePacked(resultProps.dynamicMetadata, recipe.recipeData); // Also incorporate recipe data

        // Simulate Insight gain for fusion
        _gainInsight(msg.sender, _insightGainRates[ACTION_FUSE]);

        emit ArtifactFused(msg.sender, resultArtifactId, recipeId, artifactIdsToFuse);
         emit ArtifactPropertiesUpdated(resultArtifactId, resultProps.dynamicMetadata);
    }

    /// @notice Applies decay effects to an Artifact based on time passed or usage, potentially reducing properties.
    /// @param artifactId The ID of the Artifact to decay.
    /// @dev This function needs to be called for decay to occur. Can be called by anyone, state updates affect owner.
    function decayArtifact(uint256 artifactId) external whenNotPaused {
         if (ownerOf(artifactId) == address(0)) { // Check if artifact exists
             revert QuantumRealmForge__ArtifactNotFound(artifactId);
         }
        ArtifactProperties storage props = _artifactProperties[artifactId];
        uint256 artifactTypeId = props.artifactTypeId;
        uint256 decayRate = _decayRates[artifactTypeId];

        if (decayRate == 0) {
             revert QuantumRealmForge__ArtifactCannotBeDecayed(artifactId); // No decay configured for this type
        }

        uint256 timeElapsed = block.timestamp.sub(props.lastDecayTimestamp);
        // Simulate decay based on time elapsed and decay rate
        int256 energyLoss = int256(timeElapsed.mul(decayRate).div(1 days)); // Example: lose energy per day
        uint256 qualityLoss = timeElapsed.mul(decayRate).div(7 days).min(props.quality); // Example: lose quality per week

        props.energy = props.energy.sub(energyLoss);
        props.quality = props.quality.sub(qualityLoss);
        props.lastDecayTimestamp = block.timestamp; // Update decay timestamp

        emit ArtifactDecayed(artifactId, energyLoss, props.quality);
        emit ArtifactPropertiesUpdated(artifactId, props.dynamicMetadata); // Decay affects properties, so update metadata state might change
    }

     /// @notice Consumes Essences to counteract or reverse decay on an Artifact.
     /// @param artifactId The ID of the Artifact to maintain.
     /// @param essenceTypes Array of Essence types required.
     /// @param essenceAmounts Array of corresponding Essence amounts.
    function maintainArtifact(
        uint256 artifactId,
        uint256[] memory essenceTypes,
        uint256[] memory essenceAmounts
    ) external whenNotPaused onlyArtifactOwner(artifactId) {
         if (ownerOf(artifactId) == address(0)) {
             revert QuantumRealmForge__ArtifactNotFound(artifactId);
         }
          if (_artifactProperties[artifactId].deployedDimensionId != 0) {
             revert QuantumRealmForge__ArtifactAlreadyInDimension(artifactId);
         }

        // Simulate Resource Consumption (similar to craft)
         require(essenceTypes.length == essenceAmounts.length, "Invalid essence input arrays");

        for (uint i = 0; i < essenceTypes.length; i++) {
            if (_essenceBalances[essenceTypes[i]][msg.sender] < essenceAmounts[i]) {
                revert QuantumRealmForge__InsufficientEssence(essenceTypes[i], essenceAmounts[i], _essenceBalances[essenceTypes[i]][msg.sender]);
            }
        }

        for (uint i = 0; i < essenceTypes.length; i++) {
            _essenceBalances[essenceTypes[i]][msg.sender] = _essenceBalances[essenceTypes[i]][msg.sender].sub(essenceAmounts[i]);
            _totalEssenceSupply[essenceTypes[i]] = _totalEssenceSupply[essenceTypes[i]].sub(essenceAmounts[i]);
            emit EssenceBurned(msg.sender, essenceTypes[i], essenceAmounts[i]);
        }

        // --- Simulate Maintenance Effect ---
        ArtifactProperties storage props = _artifactProperties[artifactId];
        // Example: Maintenance restores energy and quality
        props.energy = props.energy.add(200); // Restore a fixed amount
        props.quality = props.quality.add(10).min(100); // Restore a fixed amount up to 100

        // Simulate Insight gain for maintenance
        _gainInsight(msg.sender, _insightGainRates[ACTION_MAINTAIN]);

        emit ArtifactMaintained(artifactId, props.energy);
         emit ArtifactPropertiesUpdated(artifactId, props.dynamicMetadata);
    }

    /// @notice Triggers a temporary state change or reveals hidden properties of an Artifact.
    /// Simulates the "observer effect".
    /// @param artifactId The ID of the Artifact to observe.
    function observeArtifact(uint256 artifactId) external whenNotPaused onlyArtifactOwner(artifactId) {
         if (ownerOf(artifactId) == address(0)) {
             revert QuantumRealmForge__ArtifactNotFound(artifactId);
         }
         ArtifactProperties storage props = _artifactProperties[artifactId];
         if (props.isInObservedState && props.observedUntilTimestamp > block.timestamp) {
             revert QuantumRealmForge__ArtifactAlreadyObserved(artifactId);
         }
         if (_artifactProperties[artifactId].deployedDimensionId != 0) {
             revert QuantumRealmForge__ArtifactAlreadyInDimension(artifactId);
         }

        // Simulate temporary state change
        props.isInObservedState = true;
        props.observedUntilTimestamp = block.timestamp.add(1 hours); // Example: Observed state lasts 1 hour

        // Simulate revealing hidden property (e.g., change metadata temporarily, or unlock a function call)
        // This example doesn't have complex hidden states, but a real one would modify props.dynamicMetadata
        // or unlock temporary access to other contract functions via the observed state flag.

        // Simulate Insight gain for observation
        _gainInsight(msg.sender, _insightGainRates[ACTION_OBSERVE]);

        emit ArtifactObserved(artifactId, props.observedUntilTimestamp);
        // If observation visibly changes metadata, emit update event
        // emit ArtifactPropertiesUpdated(artifactId, props.dynamicMetadata);
    }

    /// @notice Retrieves the current dynamic properties of an Artifact.
    /// @param artifactId The ID of the Artifact.
    /// @return ArtifactProperties struct containing the current state.
    function getArtifactProperties(uint256 artifactId) public view returns (ArtifactProperties memory) {
         if (ownerOf(artifactId) == address(0)) { // Check if artifact exists
             revert QuantumRealmForge__ArtifactNotFound(artifactId);
         }
        return _artifactProperties[artifactId];
    }

    /// @notice Checks if an Artifact is currently in a decayed state needing maintenance.
    /// Simplified check based on energy level.
    /// @param artifactId The ID of the Artifact.
    /// @return True if decayed, false otherwise.
    function isArtifactDecayed(uint256 artifactId) public view returns (bool) {
         if (ownerOf(artifactId) == address(0)) {
             revert QuantumRealmForge__ArtifactNotFound(artifactId);
         }
        // Example: Decayed if energy is below a threshold (e.g., 20)
        return _artifactProperties[artifactId].energy < 20;
    }

    /// @notice Lists Artifact IDs owned by an account.
    /// @param account The address to query.
    /// @return An array of Artifact IDs.
    /// @dev Uses ERC721Enumerable's functionality. This is function #14.
    function listUserArtifacts(address account) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(account);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(account, i);
        }
        return tokenIds;
    }


    // --- C. Insight Management (Simulated SBT) ---

    /// @notice Awards Insight to a specific account.
    /// @param account The address to award Insight to.
    /// @param amount The amount of Insight to add.
    /// @dev This function is intended to be called by the contract itself after certain actions
    /// or by an authorized admin/system account. Simulating internal call via onlyOwner for example.
    function gainInsight(address account, uint256 amount) public onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        _insightLevels[account] = _insightLevels[account].add(amount);
        emit InsightGained(account, amount, _insightLevels[account]);
    }

    /// @notice Allows a user to spend their accumulated Insight for benefits within the system.
    /// @param amount The amount of Insight to spend.
    /// @dev The actual benefit logic (e.g., reducing crafting cost, accessing special recipes)
    /// would be implemented in other functions that check the user's insight level.
    function spendInsight(uint256 amount) external whenNotPaused {
        if (_insightLevels[msg.sender] < amount) {
             revert QuantumRealmForge__InsufficientInsight(amount, _insightLevels[msg.sender]);
        }
        _insightLevels[msg.sender] = _insightLevels[msg.sender].sub(amount);
        emit InsightSpent(msg.sender, amount, _insightLevels[msg.sender]);
    }

    /// @notice Get the Insight level/points for an account.
    /// @param account The address to query.
    /// @return The Insight level of the account.
    function getInsightLevel(address account) public view returns (uint256) {
        return _insightLevels[account];
    }

    // --- D. Dimension Management (Simulated Spaces) ---

    /// @notice Allows a user to claim ownership of a simulated Dimension ID.
    /// @param dimensionId The ID of the Dimension to claim.
    function claimDimension(uint256 dimensionId) external whenNotPaused {
        if (_isDimensionClaimed[dimensionId]) {
            revert QuantumRealmForge__DimensionAlreadyClaimed(dimensionId);
        }
        _dimensions[dimensionId].owner = msg.sender;
        _dimensions[dimensionId].creationTimestamp = block.timestamp;
        _dimensions[dimensionId].stability = 50; // Example initial property
        _dimensions[dimensionId].yieldRate = 1; // Example initial property
        _isDimensionClaimed[dimensionId] = true;

        emit DimensionClaimed(msg.sender, dimensionId);
    }

    /// @notice Places a user's Artifact into their claimed Dimension.
    /// @param artifactId The ID of the Artifact to deploy.
    /// @param dimensionId The ID of the Dimension to deploy to.
    function deployArtifactToDimension(uint256 artifactId, uint256 dimensionId) external whenNotPaused onlyArtifactOwner(artifactId) onlyDimensionOwner(dimensionId) {
         if (ownerOf(artifactId) == address(0)) {
             revert QuantumRealmForge__ArtifactNotFound(artifactId);
         }
         ArtifactProperties storage props = _artifactProperties[artifactId];
         if (props.deployedDimensionId != 0) {
             revert QuantumRealmForge__ArtifactAlreadyInDimension(artifactId);
         }


        props.deployedDimensionId = dimensionId;
         _dimensions[dimensionId].deployedArtifactIds.push(artifactId);

        // Simulate Dimension property change based on artifact deployed
        // Example: deploying a high-energy artifact increases dimension stability
        DimensionProperties storage dimProps = _dimensions[dimensionId];
        dimProps.stability = dimProps.stability.add(props.energy / 10).min(100); // Simplified effect

        emit ArtifactDeployedToDimension(artifactId, dimensionId, msg.sender);
        emit DimensionPropertiesUpdated(dimensionId, abi.encode(dimProps.stability, dimProps.yieldRate)); // Example update event data
    }

     /// @notice Removes an Artifact from a Dimension and returns it to the owner's inventory.
     /// @param artifactId The ID of the Artifact to reclaim.
     /// @param dimensionId The ID of the Dimension to reclaim from.
    function reclaimArtifactFromDimension(uint256 artifactId, uint256 dimensionId) external whenNotPaused onlyArtifactOwner(artifactId) onlyDimensionOwner(dimensionId) {
         if (ownerOf(artifactId) == address(0)) {
             revert QuantumRealmForge__ArtifactNotFound(artifactId);
         }
         ArtifactProperties storage props = _artifactProperties[artifactId];
         if (props.deployedDimensionId != dimensionId) {
             revert QuantumRealmForge__ArtifactNotInDimension(artifactId, dimensionId);
         }

        props.deployedDimensionId = 0;
         _removeArtifactFromDimensionList(artifactId, dimensionId);

        // Simulate Dimension property change based on artifact removed
        // Example: removing an artifact decreases dimension stability
        DimensionProperties storage dimProps = _dimensions[dimensionId];
        dimProps.stability = dimProps.stability.sub(props.energy / 10).max(0); // Simplified effect

        emit ArtifactReclaimedFromDimension(artifactId, dimensionId, msg.sender);
         emit DimensionPropertiesUpdated(dimensionId, abi.encode(dimProps.stability, dimProps.yieldRate)); // Example update event data
    }

    /// @notice Retrieves the current properties of a Dimension.
    /// @param dimensionId The ID of the Dimension.
    /// @return DimensionProperties struct containing the current state.
    function getDimensionProperties(uint256 dimensionId) public view returns (DimensionProperties memory) {
         if (!_isDimensionClaimed[dimensionId]) {
             revert QuantumRealmForge__DimensionNotClaimed(dimensionId);
         }
        return _dimensions[dimensionId];
    }

     /// @notice Lists Artifact IDs currently deployed in a Dimension.
     /// @param dimensionId The ID of the Dimension.
     /// @return An array of Artifact IDs.
    function listArtifactsInDimension(uint256 dimensionId) external view returns (uint256[] memory) {
         if (!_isDimensionClaimed[dimensionId]) {
             revert QuantumRealmForge__DimensionNotClaimed(dimensionId);
         }
        return _dimensions[dimensionId].deployedArtifactIds;
    }

    // Internal helper to remove an artifact ID from a dimension's list
    function _removeArtifactFromDimensionList(uint256 artifactId, uint256 dimensionId) internal {
        DimensionProperties storage dimProps = _dimensions[dimensionId];
        uint256[] storage deployedIds = dimProps.deployedArtifactIds;
        for (uint i = 0; i < deployedIds.length; i++) {
            if (deployedIds[i] == artifactId) {
                // Replace the found ID with the last element
                deployedIds[i] = deployedIds[deployedIds.length - 1];
                // Remove the last element
                deployedIds.pop();
                return;
            }
        }
        // Should not happen if deployedDimensionId was set correctly
    }

    // --- E. Catalyst Management (ERC-1155 like) ---

    /// @notice Mints a specific Catalyst type to a recipient.
    /// @param recipient The address to mint Catalyst to.
    /// @param catalystId The ID of the Catalyst type.
    /// @param amount The amount of Catalyst to mint.
    /// @param data Additional data for the mint operation (ERC-1155 compatibility).
    function mintCatalyst(address recipient, uint256 catalystId, uint256 amount, bytes memory data) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        _catalystBalances[catalystId][recipient] = _catalystBalances[catalystId][recipient].add(amount);
        // ERC-1155 doesn't track total supply inherently per ID without extension
        // emit TransferSingle(operator, address(0), recipient, id, amount); // Standard ERC1155 mint event would be here
        emit CatalystMinted(recipient, catalystId, amount);
    }

    // Note: Standard ERC1155 transfer/balanceOf/etc. would be implemented here,
    // but using a simplified balance map for this example's complexity focus.

     /// @notice Get the balance of a specific Catalyst type for an account.
     /// @param account The address to query.
     /// @param catalystId The ID of the Catalyst.
     /// @return The balance of the specified Catalyst type.
    function catalystBalanceOf(address account, uint256 catalystId) public view returns (uint256) {
        return _catalystBalances[catalystId][account];
    }

    // --- F. Recipe & Parameter Management (Admin/Governance) ---

    /// @notice Sets or updates the data for a crafting recipe.
    /// @param recipeId The ID of the recipe.
    /// @param recipeData Encoded data defining the recipe inputs/outputs/effects.
    function setCraftingRecipe(uint256 recipeId, bytes memory recipeData) external onlyOwner whenNotPaused {
        _recipes[recipeId] = Recipe(RECIPE_TYPE_CRAFT, recipeData, true);
        emit RecipeSet(recipeId, RECIPE_TYPE_CRAFT);
    }

    /// @notice Sets or updates the data for an upgrade recipe.
    /// @param recipeId The ID of the recipe.
    /// @param recipeData Encoded data defining the recipe inputs/outputs/effects.
    function setUpgradeRecipe(uint256 recipeId, bytes memory recipeData) external onlyOwner whenNotPaused {
        _recipes[recipeId] = Recipe(RECIPE_TYPE_UPGRADE, recipeData, true);
        emit RecipeSet(recipeId, RECIPE_TYPE_UPGRADE);
    }

    /// @notice Sets or updates the data for a fusion recipe.
    /// @param recipeId The ID of the recipe.
    /// @param recipeData Encoded data defining the recipe inputs/outputs/effects.
    function setFusionRecipe(uint256 recipeId, bytes memory recipeData) external onlyOwner whenNotPaused {
        _recipes[recipeId] = Recipe(RECIPE_TYPE_FUSE, recipeData, true);
        emit RecipeSet(recipeId, RECIPE_TYPE_FUSE);
    }

    /// @notice Sets the decay rate for a specific type of Artifact.
    /// @param artifactTypeId The ID of the Artifact type.
    /// @param rate The decay rate (higher means faster decay).
    function setDecayRate(uint256 artifactTypeId, uint256 rate) external onlyOwner whenNotPaused {
        _decayRates[artifactTypeId] = rate;
        emit DecayRateSet(artifactTypeId, rate);
    }

    /// @notice Sets the Insight gain rate for different system actions.
    /// @param actionType The type of action (e.g., ACTION_CRAFT).
    /// @param rate The amount of Insight gained per action.
    function setInsightGainRate(uint256 actionType, uint256 rate) external onlyOwner whenNotPaused {
        _insightGainRates[actionType] = rate;
        emit InsightGainRateSet(actionType, rate);
    }

    /// @notice Retrieves the data for a specific recipe.
    /// @param recipeId The ID of the recipe.
    /// @return Recipe struct containing the type and data.
    function getRecipe(uint256 recipeId) public view returns (Recipe memory) {
         if (!_recipes[recipeId].exists) {
             revert QuantumRealmForge__InvalidRecipe(recipeId);
         }
        return _recipes[recipeId];
    }


    // --- G. Admin & Utility ---

    /// @notice Pauses core system functions.
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses core system functions.
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Withdraws any accumulated Ether or tokens from the contract.
    /// (Assumes contract might receive funds, e.g., via crafting fees - not explicitly modeled).
    /// @param payable recipient The address to send funds to.
    function withdrawFunds(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            recipient.transfer(balance);
        }
        // Add logic here to withdraw other tokens if the contract holds any
    }

    // transferOwnership is inherited from Ownable

    // --- Internal Helper Functions ---

    /// @dev Internal function to award insight. Used by other functions.
    function _gainInsight(address account, uint256 amount) internal {
         if (amount > 0) {
            _insightLevels[account] = _insightLevels[account].add(amount);
            emit InsightGained(account, amount, _insightLevels[account]);
         }
    }

     // Add more internal helpers for complex recipe parsing, property calculations, etc.
     // For example, _applyRecipeEffects(uint256 artifactId, bytes memory recipeData)
     // or _calculateFusionResult(uint256[] memory artifactIdsToFuse, bytes memory recipeData)

    // Function Count Check:
    // A: 5
    // B: 9 (counting ERC721Enumerable methods implicitly used by listUserArtifacts as part of the B category) + 3 standard inherited ERC721 methods (transferFrom, safeTransferFrom, ownerOf, balanceOf covered by Enumerable) + approve/setApprovalForAll = ~12-15 artifact related public methods
    // C: 3
    // D: 5 + 1 internal helper
    // E: 2 (Simplified ERC1155)
    // F: 6
    // G: 3 + 1 inherited Ownable
    // Total: ~5 + (9+3+2) + 3 + 5 + 2 + 6 + 4 = ~37+ functions. Exceeds 20.

    // Note: Standard ERC20 approve/allowance, ERC721 approve/getApproved/setApprovalForAll are omitted for brevity
    // but would typically be part of the full implementation or handled via interfaces/libraries if using real ERCs.
    // The ERC721Enumerable provides listUserArtifacts, balanceO, totalSupply, tokenOfOwnerByIndex, tokenByIndex.
}

// Simple Mock Contracts (needed for compilation without actual imports)
// In a real scenario, you would import these from OpenZeppelin.
/*
// Mock IERC20
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// Mock IERC1155
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

// Mock ERC721 (base)
contract ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    constructor(string memory name, string memory symbol) {}
    function ownerOf(uint256 tokenId) public view virtual returns (address) { return _owners[tokenId]; }
    function balanceOf(address owner) public view virtual returns (uint256) { return _balances[owner]; }
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
         _balances[from] -= 1; _balances[to] += 1; _owners[tokenId] = to; emit Transfer(from, to, tokenId);
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _balances[to] += 1; _owners[tokenId] = to; emit Transfer(address(0), to, tokenId);
    }
     function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {}
     function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) { return false;} // Simplified
}

// Mock ERC721Enumerable
contract ERC721Enumerable is ERC721 {
     constructor(string memory name, string memory symbol) : ERC721(name, symbol) {}
     function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {} // Mock
     function totalSupply() public view virtual returns (uint256) {} // Mock
     function tokenByIndex(uint256 index) public view virtual returns (uint256) {} // Mock
      function _update(address to, uint256 tokenId, address auth) internal override returns (address) {return super._update(to, tokenId, auth);}
      function _increaseBalance(address account, uint256 amount) internal override {}
     function supportsInterface(bytes4 interfaceId) public view override returns (bool) { return super.supportsInterface(interfaceId);}
}


// Mock Ownable
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) { _transferOwnership(initialOwner); }
    modifier onlyOwner() { require(msg.sender == _owner, "Ownable: caller is not the owner"); _;}
    function owner() public view virtual returns (address) { return _owner; }
    function transferOwnership(address newOwner) public virtual onlyOwner { require(newOwner != address(0), "Ownable: new owner is zero address"); _transferOwnership(newOwner); }
    function _transferOwnership(address newOwner) internal virtual { address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}
}

// Mock Pausable
contract Pausable {
    bool private _paused;
    constructor() {}
    modifier whenNotPaused() { require(!_paused, "Pausable: paused"); _;}
    modifier whenPaused() { require(_paused, "Pausable: not paused"); _;}
    function paused() public view virtual returns (bool) { return _paused; }
    function _pause() internal virtual { _paused = true; }
    function _unpause() internal virtual { _paused = false; }
     function _requireNotPaused() internal view virtual {}
     function _requirePaused() internal view virtual {}
}

// Mock Counters
library Counters {
    struct Counter { uint256 _value; }
    function current(Counter storage counter) internal view returns (uint256) { return counter._value; }
    function increment(Counter storage counter) internal { unchecked { counter._value += 1; } }
}

// Mock SafeMath - Use uint256 directly in >0.8.0, but include for conceptual completeness
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a, "SafeMath: subtraction underflow"); uint256 c = a - b; return c; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) return 0; uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: division by zero"); uint256 c = a / b; return c; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "SafeMath: modulo by zero"); return a % b; }
     function min(uint256 a, uint256 b) internal pure returns (uint256) { return a < b ? a : b; }
      function max(uint256 a, uint256 b) internal pure returns (uint256) { return a > b ? a : b; }
       function sub(int256 a, int256 b) internal pure returns (int256) { int256 c = a - b; require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMath: subtraction overflow"); return c; }
        function add(int256 a, int256 b) internal pure returns (int256) { int256 c = a + b; require((b >= 0 && c >= a) || (b < 0 && c < a), "SafeMath: addition overflow"); return c; }
}
*/
```