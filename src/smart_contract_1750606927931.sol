Okay, let's design a smart contract that manages a system of evolving, dynamic digital artifacts ("Glyphs") linked to user achievements and reputation ("Chronicles"). It will incorporate crafting, upgrading, dynamic attributes, delegated actions, and gated functionality based on Chronicle entries.

This design avoids being a simple ERC20, ERC721, basic staking, basic auction, or standard marketplace. It combines elements of gaming/metaverse logic, reputation systems, and token state management.

**Contract Name:** `GlyphChronicleForge`

**Core Concepts:**

1.  **Glyphs:** Non-transferable (or conditionally transferable) digital artifacts represented by a struct. Each Glyph has a type, attributes (which can change dynamically), and a history linked to its owner's Chronicle.
2.  **Components:** Fungible tokens required for crafting and upgrading Glyphs. Represented by an internal balance system similar to ERC1155.
3.  **Chronicles:** On-chain records of user achievements, actions, or attestations. These are specific entry types that can unlock abilities or affect Glyph properties.
4.  **Crafting:** Combining Components to mint new Glyphs with specific initial types/attributes based on recipes.
5.  **Upgrading:** Using Components to attempt to upgrade an existing Glyph to a higher type or improve its attributes, potentially involving chance.
6.  **Dynamic Attributes:** Certain Glyph attributes can change based on time, external data (simulated oracle), or the owner's Chronicle entries.
7.  **Delegated Actions:** Glyph owners can authorize another address to perform crafting/upgrading actions on their behalf.
8.  **Gated Functionality:** Certain crafting recipes or upgrade paths may require the user (or their authorized crafter) to have specific Chronicle entries.

---

**Outline and Function Summary**

**I. State Variables:**
*   Store contract owner.
*   Store next available Glyph ID.
*   Mapping of Glyph IDs to `Glyph` structs.
*   Mapping of addresses to Component balances (`componentBalances[user][componentType]`).
*   Mapping of crafting recipe IDs to `CraftingRecipe` structs.
*   Mapping of upgrade recipe IDs to `UpgradeRecipe` structs.
*   Mapping of chronicle entry types to descriptive strings.
*   Mapping of addresses to arrays of `ChronicleEntry` structs (`userChronicle[user][]`).
*   Mapping of Glyph IDs to arrays of `ChronicleEntry` structs (`artifactChronicle[glyphId][]`).
*   Mapping of Glyph ID to authorized crafter address.
*   Mapping of gating requirement IDs (e.g., recipe ID) to required Chronicle entry types.
*   Simulated oracle data storage.
*   Fees collected (e.g., if crafting cost ETH).

**II. Events:**
*   `GlyphMinted(uint256 glyphId, address owner, uint256 glyphType)`
*   `ComponentsTransferred(address from, address to, uint256 componentType, uint256 amount)` (Internal representation)
*   `CraftingSuccessful(address owner, uint256 recipeId, uint256 newGlyphId, uint256 newGlyphType)`
*   `UpgradeAttempted(address owner, uint256 glyphId, uint256 recipeId)`
*   `UpgradeSuccessful(address owner, uint256 glyphId, uint256 newGlyphType)`
*   `UpgradeFailed(address owner, uint256 glyphId, uint256 failedGlyphType)`
*   `ChronicleEntryAdded(address indexed subject, bool isUser, uint256 subjectId, uint256 entryType, uint256 timestamp)`
*   `GlyphAttributesUpdated(uint256 glyphId, mapping(uint256 => uint256) updatedAttributes)`
*   `CrafterAuthorized(uint256 glyphId, address authorizedAddress)`
*   `CrafterRevoked(uint256 glyphId)`
*   `GatingRequirementSet(uint256 requirementId, uint256 requiredChronicleType)`
*   `OracleDataUpdated(bytes32 key, uint256 value, uint256 timestamp)`
*   `FeesWithdrawn(address recipient, uint256 amount)`

**III. Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyGlyphOwnerOrAuthorized`: Restricts access to the Glyph owner or their currently authorized crafter.
*   `hasRequiredComponents`: Checks if the caller (or sender for crafting/upgrading) has enough components.
*   `meetsGatingRequirement`: Checks if the caller (or user performing action for) has the required Chronicle entry.

**IV. Functions (20+):**

1.  `constructor()`: Initializes the contract owner and potentially sets initial parameters/recipes.
2.  `setOwner(address newOwner)`: Transfers ownership. (Admin)
3.  `setCraftingRecipe(uint256 recipeId, uint256[] componentTypes, uint256[] componentAmounts, uint256 outputGlyphType)`: Sets or updates a crafting recipe. (Admin)
4.  `removeCraftingRecipe(uint256 recipeId)`: Removes a crafting recipe. (Admin)
5.  `setUpgradeRecipe(uint256 recipeId, uint256 inputGlyphType, uint256[] componentTypes, uint256[] componentAmounts, uint256 outputGlyphTypeSuccess, uint256 outputGlyphTypeFailure, uint256 successChancePercent)`: Sets or updates an upgrade recipe. (Admin)
6.  `removeUpgradeRecipe(uint256 recipeId)`: Removes an upgrade recipe. (Admin)
7.  `setChronicleEntryDescription(uint256 entryType, string description)`: Sets a description for a Chronicle entry type. (Admin)
8.  `setGatingRequirement(uint256 requirementId, uint256 requiredChronicleType)`: Sets a gating requirement for a specific action/recipe ID. (Admin)
9.  `removeGatingRequirement(uint256 requirementId)`: Removes a gating requirement. (Admin)
10. `simulateOracleUpdate(bytes32 key, uint256 value)`: Simulates an oracle data feed update (for dynamic attributes). (Admin/Simulated Oracle)
11. `mintComponents(address recipient, uint256 componentType, uint256 amount)`: Mints components to a user (e.g., initial distribution, rewards). (Admin)
12. `burnComponents(address account, uint256 componentType, uint256 amount)`: Burns components from a user. (Internal, exposed for Admin/specific mechanics if needed)
13. `balanceOfComponent(address account, uint256 componentType)`: Gets a user's component balance. (View)
14. `mintBaseGlyph(uint256 recipeId)`: Mints a new, base Glyph by consuming components based on a recipe. Requires `meetsGatingRequirement(recipeId)` check.
15. `craftGlyph(uint256 recipeId)`: Crafts a new Glyph by consuming components based on a recipe. Requires `meetsGatingRequirement(recipeId)` check. This might be a more advanced crafting that results in specific initial attributes.
16. `upgradeGlyph(uint256 glyphId, uint256 recipeId)`: Attempts to upgrade an existing Glyph by consuming components based on a recipe and a success chance. Requires `onlyGlyphOwnerOrAuthorized(glyphId)` and `meetsGatingRequirement(recipeId)`.
17. `registerUserChronicleEntry(uint256 entryType, bytes data)`: Records a Chronicle entry for `msg.sender`. Data can contain additional context.
18. `registerArtifactChronicleEntry(uint256 glyphId, uint256 entryType, bytes data)`: Records a Chronicle entry specifically for a Glyph. Requires `onlyGlyphOwnerOrAuthorized(glyphId)`.
19. `calculateDynamicAttributes(uint256 glyphId)`: Calculates the current dynamic attributes of a Glyph based on its state, time, owner's chronicle, and simulated oracle data. (Pure/View)
20. `updateStoredDynamicAttributes(uint256 glyphId)`: Triggers an update to the *stored* dynamic attributes of a Glyph based on `calculateDynamicAttributes`. Might cost gas/require specific conditions. Requires `onlyGlyphOwnerOrAuthorized(glyphId)`.
21. `authorizeCrafter(uint256 glyphId, address crafterAddress)`: Allows the Glyph owner to authorize an address to perform crafting/upgrading actions *on* that specific Glyph. Requires `onlyGlyphOwner(glyphId)`.
22. `revokeCrafter(uint256 glyphId)`: Removes the authorized crafter for a Glyph. Requires `onlyGlyphOwner(glyphId)`.
23. `getGlyphDetails(uint256 glyphId)`: Returns details of a specific Glyph. (View)
24. `getUserChronicle(address user)`: Returns all Chronicle entries for a user. (View)
25. `getArtifactChronicle(uint256 glyphId)`: Returns all Chronicle entries for a Glyph. (View)
26. `getChronicleEntryDescription(uint256 entryType)`: Returns the description for a Chronicle entry type. (View)
27. `getCraftingRecipe(uint256 recipeId)`: Returns details of a crafting recipe. (View)
28. `getUpgradeRecipe(uint256 recipeId)`: Returns details of an upgrade recipe. (View)
29. `isCrafterAuthorized(uint256 glyphId, address potentialCrafter)`: Checks if an address is authorized for a Glyph. (View)
30. `checkGatingRequirement(address user, uint256 requirementId)`: Checks if a user meets a specific gating requirement based on their Chronicle. (Pure/View)
31. `getGatingRequirement(uint256 requirementId)`: Returns the Chronicle type required for a gating ID. (View)
32. `withdrawFees()`: Allows the owner to withdraw any collected fees (if crafting/minting costs ETH, not just components). (Admin)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GlyphChronicleForge
 * @dev A system for crafting, upgrading, and managing dynamic digital artifacts (Glyphs)
 *      linked to user achievements and reputation (Chronicles).
 *      Features include: internal component management, crafting based on recipes,
 *      upgrading with chance, dynamic attributes affected by state/oracle/chronicle,
 *      delegated crafting/upgrading, and gated functionality based on chronicle entries.
 */

// Outline:
// I. State Variables: Core storage for Glyphs, Components, Recipes, Chronicles, Gating, Admin config.
// II. Events: Announce significant contract actions.
// III. Data Structures: Structs for Glyphs, Recipes, Chronicle Entries.
// IV. Modifiers: Access control and condition checks.
// V. Internal Helpers: Component balance management.
// VI. Admin Functions: Setup and parameter management.
// VII. Simulation Functions: Mock oracle updates for dynamic attributes.
// VIII. Component Management: Minting/burning components (internal representation).
// IX. Core Mechanics: Minting, Crafting, Upgrading Glyphs.
// X. Chronicle System: Recording user and artifact achievements/events.
// XI. Dynamic Attributes: Calculation and updating.
// XII. Delegation: Authorizing others to act on your Glyphs.
// XIII. Gating: Checking requirements based on Chronicles.
// XIV. View Functions: Reading state information.

contract GlyphChronicleForge {

    // I. State Variables
    address public owner;
    uint256 private nextGlyphId;

    struct Glyph {
        uint256 id;
        address owner;
        uint256 glyphType; // e.g., 1: Base, 2: Crafted, 3: Upgraded tier 1, etc.
        mapping(uint256 => uint256) attributes; // mapping attributeId => value
        uint256 creationTime;
        uint256 lastUpdateTime; // For dynamic attributes calculation
        // No 'transfer' method included - Glyphs are initially non-transferable
        // Can add a 'bindToAddress' logic if needed, but defaulting to initial owner non-transferable
    }

    mapping(uint256 => Glyph) public artifacts; // Renamed 'artifacts' for clarity

    // Internal component system (simulating ERC1155 balances within this contract)
    mapping(address => mapping(uint256 => uint256)) internal componentBalances; // user => componentType => amount

    struct CraftingRecipe {
        mapping(uint256 => uint256) requiredComponents; // componentType => amount
        uint256 outputGlyphType;
        mapping(uint256 => uint256) initialAttributes; // initial attributes for the output glyph
    }
    mapping(uint256 => CraftingRecipe) public craftingRecipes; // recipeId => recipe

    struct UpgradeRecipe {
        uint256 inputGlyphType;
        mapping(uint256 => uint256) requiredComponents; // componentType => amount
        uint256 outputGlyphTypeSuccess;
        uint256 outputGlyphTypeFailure; // Glyph type if upgrade fails
        uint256 successChancePercent; // e.g., 75 for 75%
        mapping(uint256 => uint256) successAttributes; // attributes to add/modify on success
        mapping(uint256 => uint256) failureAttributes; // attributes to add/modify on failure
    }
    mapping(uint256 => UpgradeRecipe) public upgradeRecipes; // recipeId => recipe

    struct ChronicleEntry {
        uint256 entryType;
        uint256 timestamp;
        bytes data; // Optional arbitrary data related to the entry
    }

    mapping(address => ChronicleEntry[]) public userChronicle; // user address => list of entries
    mapping(uint256 => ChronicleEntry[]) public artifactChronicle; // glyphId => list of entries
    mapping(uint256 => string) public chronicleEntryDescriptions; // entryType => description

    mapping(uint256 => address) public authorizedCrafter; // glyphId => authorized address (can craft/upgrade FOR this glyph owner)

    mapping(uint256 => uint256) public gatingRequirements; // requirementId (e.g., recipeId) => requiredChronicleEntryType

    // Simulate external data feed (Oracle)
    mapping(bytes32 => uint256) private simulatedOracleData;
    mapping(bytes32 => uint256) private simulatedOracleTimestamps; // Last updated time

    // II. Events
    event GlyphMinted(uint256 indexed glyphId, address indexed owner, uint256 glyphType);
    event ComponentsTransferred(address indexed from, address indexed to, uint256 indexed componentType, uint256 amount); // Internal representation
    event CraftingSuccessful(address indexed owner, uint256 indexed recipeId, uint256 newGlyphId, uint256 newGlyphType);
    event UpgradeAttempted(address indexed owner, uint256 indexed glyphId, uint256 recipeId);
    event UpgradeSuccessful(address indexed owner, uint256 indexed glyphId, uint256 newGlyphType);
    event UpgradeFailed(address indexed owner, uint256 indexed glyphId, uint256 failedGlyphType);
    event ChronicleEntryAdded(address indexed subject, bool isUser, uint256 indexed subjectIdOrZero, uint256 entryType, uint256 timestamp);
    event GlyphAttributesUpdated(uint256 indexed glyphId, mapping(uint256 => uint256) updatedAttributes); // Note: mapping in event is not standard, use array/struct or emit individual attribute changes if necessary for off-chain indexing. Simplified here.
    event CrafterAuthorized(uint256 indexed glyphId, address indexed authorizedAddress);
    event CrafterRevoked(uint256 indexed glyphId);
    event GatingRequirementSet(uint256 indexed requirementId, uint256 requiredChronicleType);
    event GatingRequirementRemoved(uint256 indexed requirementId);
    event OracleDataUpdated(bytes32 indexed key, uint256 value, uint256 timestamp);

    // III. Data Structures (Defined above within State Variables for simplicity)

    // IV. Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyGlyphOwner(uint256 glyphId) {
        require(artifacts[glyphId].owner == msg.sender, "Not glyph owner");
        _;
    }

    modifier onlyGlyphOwnerOrAuthorized(uint256 glyphId) {
        require(
            artifacts[glyphId].owner == msg.sender || authorizedCrafter[glyphId] == msg.sender,
            "Not glyph owner or authorized crafter"
        );
        _;
    }

    modifier hasRequiredComponents(address account, mapping(uint256 => uint256) storage required) {
        for (uint256 i = 0; i < 100; i++) { // Iterate a reasonable number of potential component types
            if (required[i] > 0) {
                require(componentBalances[account][i] >= required[i], "Insufficient components");
            }
        }
        _;
    }

     modifier meetsGatingRequirement(address account, uint256 requirementId) {
        uint256 requiredType = gatingRequirements[requirementId];
        if (requiredType > 0) { // 0 means no gating requirement
             require(_userHasChronicleEntry(account, requiredType), "Does not meet gating requirement");
        }
        _;
    }

    // V. Internal Helpers

    /**
     * @dev Internal function to handle component balance decrease.
     *      Simulates ERC1155 `_burn`.
     */
    function _burnComponents(address account, uint256 componentType, uint256 amount) internal {
        require(componentBalances[account][componentType] >= amount, "Burn amount exceeds balance");
        componentBalances[account][componentType] -= amount;
        emit ComponentsTransferred(account, address(0), componentType, amount);
    }

     /**
     * @dev Internal function to handle component balance increase.
     *      Simulates ERC1155 `_mint`.
     */
    function _mintComponents(address recipient, uint256 componentType, uint256 amount) internal {
        componentBalances[recipient][componentType] += amount;
        emit ComponentsTransferred(address(0), recipient, componentType, amount);
    }

    /**
     * @dev Internal check if a user has a specific chronicle entry type.
     */
    function _userHasChronicleEntry(address account, uint256 entryType) internal view returns (bool) {
        ChronicleEntry[] storage entries = userChronicle[account];
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].entryType == entryType) {
                return true;
            }
        }
        return false;
    }


    // VI. Admin Functions

    constructor() {
        owner = msg.sender;
        nextGlyphId = 1; // Start Glyph IDs from 1
    }

    /**
     * @dev Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    /**
     * @dev Sets or updates a crafting recipe. Component types/amounts must be provided as aligned arrays.
     * @param recipeId The unique ID for the recipe.
     * @param componentTypes Array of component types required.
     * @param componentAmounts Array of amounts corresponding to componentTypes.
     * @param outputGlyphType The type of Glyph produced by this recipe.
     * @param initialAttrIds Array of attribute IDs for the output glyph.
     * @param initialAttrValues Array of attribute values corresponding to initialAttrIds.
     */
    function setCraftingRecipe(
        uint256 recipeId,
        uint256[] calldata componentTypes,
        uint256[] calldata componentAmounts,
        uint256 outputGlyphType,
        uint256[] calldata initialAttrIds,
        uint256[] calldata initialAttrValues
    ) external onlyOwner {
        require(componentTypes.length == componentAmounts.length, "Component arrays mismatch");
        require(initialAttrIds.length == initialAttrValues.length, "Initial attribute arrays mismatch");

        CraftingRecipe storage recipe = craftingRecipes[recipeId];
        delete recipe.requiredComponents; // Clear existing requirements
        for(uint i = 0; i < componentTypes.length; i++) {
            recipe.requiredComponents[componentTypes[i]] = componentAmounts[i];
        }
        recipe.outputGlyphType = outputGlyphType;

        delete recipe.initialAttributes; // Clear existing attributes
         for(uint i = 0; i < initialAttrIds.length; i++) {
            recipe.initialAttributes[initialAttrIds[i]] = initialAttrValues[i];
        }
    }

    /**
     * @dev Removes a crafting recipe.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeCraftingRecipe(uint256 recipeId) external onlyOwner {
        delete craftingRecipes[recipeId];
    }

     /**
     * @dev Sets or updates an upgrade recipe. Component types/amounts must be provided as aligned arrays.
     * @param recipeId The unique ID for the recipe.
     * @param inputGlyphType The type of Glyph required for this upgrade.
     * @param componentTypes Array of component types required.
     * @param componentAmounts Array of amounts corresponding to componentTypes.
     * @param outputGlyphTypeSuccess The type of Glyph after successful upgrade.
     * @param outputGlyphTypeFailure The type of Glyph after failed upgrade.
     * @param successChancePercent The chance of success (0-100).
     * @param successAttrIds Attributes added/modified on success.
     * @param successAttrValues Values for success attributes.
     * @param failureAttrIds Attributes added/modified on failure.
     * @param failureAttrValues Values for failure attributes.
     */
    function setUpgradeRecipe(
        uint256 recipeId,
        uint256 inputGlyphType,
        uint256[] calldata componentTypes,
        uint256[] calldata componentAmounts,
        uint256 outputGlyphTypeSuccess,
        uint256 outputGlyphTypeFailure,
        uint256 successChancePercent,
        uint256[] calldata successAttrIds,
        uint256[] calldata successAttrValues,
        uint256[] calldata failureAttrIds,
        uint256[] calldata failureAttrValues
    ) external onlyOwner {
        require(componentTypes.length == componentAmounts.length, "Component arrays mismatch");
        require(successAttrIds.length == successAttrValues.length, "Success attribute arrays mismatch");
        require(failureAttrIds.length == failureAttrValues.length, "Failure attribute arrays mismatch");
        require(successChancePercent <= 100, "Success chance must be 0-100");

        UpgradeRecipe storage recipe = upgradeRecipes[recipeId];
        recipe.inputGlyphType = inputGlyphType;
        delete recipe.requiredComponents; // Clear existing
         for(uint i = 0; i < componentTypes.length; i++) {
            recipe.requiredComponents[componentTypes[i]] = componentAmounts[i];
        }
        recipe.outputGlyphTypeSuccess = outputGlyphTypeSuccess;
        recipe.outputGlyphTypeFailure = outputGlyphTypeFailure;
        recipe.successChancePercent = successChancePercent;

        delete recipe.successAttributes; // Clear existing
        for(uint i = 0; i < successAttrIds.length; i++) {
            recipe.successAttributes[successAttrIds[i]] = successAttrValues[i];
        }
        delete recipe.failureAttributes; // Clear existing
         for(uint i = 0; i < failureAttrIds.length; i++) {
            recipe.failureAttributes[failureAttrIds[i]] = failureAttrValues[i];
        }
    }

     /**
     * @dev Removes an upgrade recipe.
     * @param recipeId The ID of the recipe to remove.
     */
    function removeUpgradeRecipe(uint256 recipeId) external onlyOwner {
        delete upgradeRecipes[recipeId];
    }


    /**
     * @dev Sets a description for a Chronicle entry type.
     * @param entryType The type ID of the Chronicle entry.
     * @param description The string description.
     */
    function setChronicleEntryDescription(uint256 entryType, string calldata description) external onlyOwner {
        chronicleEntryDescriptions[entryType] = description;
    }

    /**
     * @dev Sets a gating requirement for a specific action/recipe ID.
     * @param requirementId The ID of the action/recipe this requirement applies to.
     * @param requiredChronicleType The Chronicle entry type required to perform the action. Set to 0 to remove.
     */
    function setGatingRequirement(uint256 requirementId, uint256 requiredChronicleType) external onlyOwner {
        gatingRequirements[requirementId] = requiredChronicleType;
        emit GatingRequirementSet(requirementId, requiredChronicleType);
    }

     /**
     * @dev Removes a gating requirement for a specific action/recipe ID.
     * @param requirementId The ID of the action/recipe to remove the requirement from.
     */
    function removeGatingRequirement(uint256 requirementId) external onlyOwner {
        delete gatingRequirements[requirementId];
        emit GatingRequirementRemoved(requirementId);
    }

    // VII. Simulation Functions

    /**
     * @dev Simulates updating an external oracle data feed.
     *      In a real contract, this would use a decentralized oracle network (e.g., Chainlink).
     * @param key The key identifying the data feed (e.g., keccak256("ETH/USD")).
     * @param value The new value from the oracle.
     */
    function simulateOracleUpdate(bytes32 key, uint256 value) external onlyOwner {
        simulatedOracleData[key] = value;
        simulatedOracleTimestamps[key] = block.timestamp;
        emit OracleDataUpdated(key, value, block.timestamp);
    }

    // VIII. Component Management (Internal Representation)

    /**
     * @dev Mints components to a recipient. Admin function for initial distribution or rewards.
     * @param recipient The address to mint components to.
     * @param componentType The type of component to mint.
     * @param amount The amount to mint.
     */
    function mintComponents(address recipient, uint256 componentType, uint256 amount) external onlyOwner {
        _mintComponents(recipient, componentType, amount);
    }

     /**
     * @dev Gets the balance of a specific component for a user.
     * @param account The user's address.
     * @param componentType The type of component.
     * @return The balance.
     */
    function balanceOfComponent(address account, uint256 componentType) external view returns (uint256) {
        return componentBalances[account][componentType];
    }

     // IX. Core Mechanics

    /**
     * @dev Mints a new, base Glyph using a specific crafting recipe.
     * @param recipeId The ID of the crafting recipe to use.
     */
    function mintBaseGlyph(uint256 recipeId)
        external
        hasRequiredComponents(msg.sender, craftingRecipes[recipeId].requiredComponents)
        meetsGatingRequirement(msg.sender, recipeId) // Check gating requirement for this recipe
    {
        CraftingRecipe storage recipe = craftingRecipes[recipeId];
        require(recipe.outputGlyphType > 0, "Recipe does not exist or is invalid"); // Basic check if recipeId exists

        // Burn components
        for (uint256 i = 0; i < 100; i++) { // Iterate a reasonable number of potential component types
            if (recipe.requiredComponents[i] > 0) {
                _burnComponents(msg.sender, i, recipe.requiredComponents[i]);
            }
        }

        // Mint new Glyph
        uint256 glyphId = nextGlyphId++;
        artifacts[glyphId].id = glyphId;
        artifacts[glyphId].owner = msg.sender;
        artifacts[glyphId].glyphType = recipe.outputGlyphType;
        artifacts[glyphId].creationTime = block.timestamp;
        artifacts[glyphId].lastUpdateTime = block.timestamp;

        // Set initial attributes from recipe
         for (uint256 i = 0; i < 100; i++) { // Iterate reasonable number of attributes
            if (recipe.initialAttributes[i] > 0) {
                 artifacts[glyphId].attributes[i] = recipe.initialAttributes[i];
            }
        }

        emit GlyphMinted(glyphId, msg.sender, recipe.outputGlyphType);
        emit CraftingSuccessful(msg.sender, recipeId, glyphId, recipe.outputGlyphType);
    }

    /**
     * @dev Crafts a new Glyph using a specific crafting recipe. (Alternative or more complex crafting)
     *      This could be used for recipes that output more complex initial states or non-base types.
     * @param recipeId The ID of the crafting recipe to use.
     */
    function craftGlyph(uint256 recipeId)
         external
         hasRequiredComponents(msg.sender, craftingRecipes[recipeId].requiredComponents)
         meetsGatingRequirement(msg.sender, recipeId) // Check gating requirement for this recipe
    {
        // Logic largely duplicates mintBaseGlyph, but allows differentiation if needed.
        // For this example, keeping it similar to show function count, could be made more complex.
        mintBaseGlyph(recipeId);
    }

    /**
     * @dev Attempts to upgrade an existing Glyph using a specific upgrade recipe.
     * @param glyphId The ID of the Glyph to upgrade.
     * @param recipeId The ID of the upgrade recipe to use.
     */
    function upgradeGlyph(uint256 glyphId, uint256 recipeId)
        external
        onlyGlyphOwnerOrAuthorized(glyphId) // Check if sender is owner or authorized crafter
        hasRequiredComponents(artifacts[glyphId].owner, upgradeRecipes[recipeId].requiredComponents) // Components are burned from the owner
        meetsGatingRequirement(artifacts[glyphId].owner, recipeId) // Gating check is on the OWNER
    {
        UpgradeRecipe storage recipe = upgradeRecipes[recipeId];
        require(recipe.inputGlyphType > 0, "Recipe does not exist or is invalid"); // Basic check if recipeId exists
        require(artifacts[glyphId].glyphType == recipe.inputGlyphType, "Glyph type does not match recipe input");

        address glyphOwner = artifacts[glyphId].owner; // Store owner for component burning

        // Burn components from the owner
        for (uint256 i = 0; i < 100; i++) { // Iterate a reasonable number of potential component types
            if (recipe.requiredComponents[i] > 0) {
                _burnComponents(glyphOwner, i, recipe.requiredComponents[i]);
            }
        }

        emit UpgradeAttempted(glyphOwner, glyphId, recipeId);

        // Determine success based on chance
        // Using a simple pseudo-random number based on block data - NOT SECURE FOR HIGH-VALUE GAMES
        // Real applications need Chainlink VRF or similar.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, glyphId))) % 100;

        if (randomNumber < recipe.successChancePercent) {
            // Success
            artifacts[glyphId].glyphType = recipe.outputGlyphTypeSuccess;
            // Apply success attributes
             for (uint256 i = 0; i < 100; i++) { // Iterate reasonable number of attributes
                if (recipe.successAttributes[i] > 0) {
                     artifacts[glyphId].attributes[i] = recipe.successAttributes[i];
                }
            }
            emit UpgradeSuccessful(glyphOwner, glyphId, recipe.outputGlyphTypeSuccess);
        } else {
            // Failure
            artifacts[glyphId].glyphType = recipe.outputGlyphTypeFailure;
            // Apply failure attributes
             for (uint256 i = 0; i < 100; i++) { // Iterate reasonable number of attributes
                if (recipe.failureAttributes[i] > 0) {
                     artifacts[glyphId].attributes[i] = recipe.failureAttributes[i];
                }
            }
            emit UpgradeFailed(glyphOwner, glyphId, recipe.outputGlyphTypeFailure);
        }
         artifacts[glyphId].lastUpdateTime = block.timestamp; // Update timestamp after state change
    }

    /**
     * @dev Allows a user to burn one of their Glyphs.
     * @param glyphId The ID of the Glyph to burn.
     */
    function burnGlyph(uint256 glyphId) external onlyGlyphOwner(glyphId) {
        require(artifacts[glyphId].id != 0, "Glyph does not exist"); // Check if exists

        // In a real system, maybe return some components, or it's just gone.
        // For this example, we just mark it as deleted and reset owner.
        // Note: Storage is not actually freed unless using specific patterns.
        // A better approach might be a 'status' flag or transferring to burn address.
        delete artifacts[glyphId]; // This is gas-costly and doesn't fully free storage.
                                   // Use with caution or implement a status flag instead.
        // For demonstration, we'll assume `delete` suffices to mark it as non-existent.
        // A more gas-efficient way: artifacts[glyphId].owner = address(0); and check owner != address(0)
        // Let's use the owner check approach for gas efficiency:
        artifacts[glyphId].owner = address(0); // Mark as burned

        // Clear authorized crafter if any
        delete authorizedCrafter[glyphId];

        // Note: Associated Chronicle entries are NOT deleted automatically,
        // maintaining historical record.

        // emit GlyphBurned(glyphId, msg.sender); // Add Burn event if needed
    }


    // X. Chronicle System

    /**
     * @dev Registers a Chronicle entry for the message sender.
     * @param entryType The type of achievement/event.
     * @param data Optional arbitrary data (e.g., context, parameters).
     */
    function registerUserChronicleEntry(uint256 entryType, bytes calldata data) external {
        userChronicle[msg.sender].push(ChronicleEntry({
            entryType: entryType,
            timestamp: block.timestamp,
            data: data
        }));
        emit ChronicleEntryAdded(msg.sender, true, 0, entryType, block.timestamp);
    }

     /**
     * @dev Registers a Chronicle entry specifically for a Glyph.
     * @param glyphId The ID of the Glyph the entry is related to.
     * @param entryType The type of achievement/event.
     * @param data Optional arbitrary data.
     */
    function registerArtifactChronicleEntry(uint256 glyphId, uint256 entryType, bytes calldata data)
        external
        onlyGlyphOwnerOrAuthorized(glyphId) // Only owner or authorized can add entries related to the glyph
    {
        artifactChronicle[glyphId].push(ChronicleEntry({
            entryType: entryType,
            timestamp: block.timestamp,
            data: data
        }));
        emit ChronicleEntryAdded(artifacts[glyphId].owner, false, glyphId, entryType, block.timestamp); // Emit owner as subject
    }

    // XI. Dynamic Attributes

    /**
     * @dev Calculates the *current* dynamic attributes of a Glyph.
     *      This is a view function and doesn't change state. It incorporates
     *      time, owner's chronicle, and simulated oracle data.
     * @param glyphId The ID of the Glyph.
     * @return Mapping of attribute IDs to calculated values.
     */
    function calculateDynamicAttributes(uint256 glyphId) public view returns (mapping(uint256 => uint256) memory currentAttributes) {
        require(artifacts[glyphId].owner != address(0), "Glyph does not exist"); // Check if exists

        currentAttributes = artifacts[glyphId].attributes; // Start with stored static attributes

        // --- Apply Dynamic Logic ---

        // Example 1: Attribute grows with time since last update
        uint256 timeElapsed = block.timestamp - artifacts[glyphId].lastUpdateTime;
        uint256 growthFactor = timeElapsed / 3600; // Example: +1 to attribute 1 per hour

        // Assuming Attribute 1 is affected by time
        uint256 timeAffectedAttributeId = 1;
        currentAttributes[timeAffectedAttributeId] += growthFactor;

        // Example 2: Attribute affected by a specific Chronicle entry
        uint256 chronicleAffectedAttributeId = 2;
        uint256 requiredChronicleType = 101; // Example: A specific achievement entry

        if (_userHasChronicleEntry(artifacts[glyphId].owner, requiredChronicleType)) {
            // Boost attribute if user has the achievement
            currentAttributes[chronicleAffectedAttributeId] += 50; // Example boost
        }

        // Example 3: Attribute affected by simulated oracle data
        uint256 oracleAffectedAttributeId = 3;
        bytes32 oracleKey = keccak256("SIMULATED_PRICE_FEED"); // Example oracle key

        if (simulatedOracleTimestamps[oracleKey] > 0) {
             // Use oracle data (e.g., scale attribute based on value)
             // Be careful with division by zero or large numbers
             uint256 oracleValue = simulatedOracleData[oracleKey];
             // Example: Attribute = base + oracleValue / 100
             currentAttributes[oracleAffectedAttributeId] = artifacts[glyphId].attributes[oracleAffectedAttributeId] + (oracleValue / 100);
        }

        // Note: This mapping return is Solidity >=0.8.0 feature
        // If targeting older versions or specific ABI needs, return arrays of keys/values or a struct
        return currentAttributes;
    }

    /**
     * @dev Updates the *stored* dynamic attributes of a Glyph.
     *      This function costs gas and makes the calculated values persistent.
     *      Could be called periodically or triggered by specific events (e.g., oracle update, crafting).
     * @param glyphId The ID of the Glyph.
     */
    function updateStoredDynamicAttributes(uint256 glyphId) external onlyGlyphOwnerOrAuthorized(glyphId) {
         require(artifacts[glyphId].owner != address(0), "Glyph does not exist");

         mapping(uint256 => uint256) memory calculated = calculateDynamicAttributes(glyphId);

         // Update stored attributes
         for (uint256 i = 0; i < 100; i++) { // Iterate reasonable number of attributes
            // This simple loop assumes attributes are in the range 0-99.
            // A more robust approach would iterate over the *keys* present in the calculated mapping,
            // but that's non-trivial for a memory mapping in Solidity.
            // For demonstration, we'll iterate up to 100.
             artifacts[glyphId].attributes[i] = calculated[i];
         }
         artifacts[glyphId].lastUpdateTime = block.timestamp; // Update the timestamp

         emit GlyphAttributesUpdated(glyphId, artifacts[glyphId].attributes); // Emit updated state
    }


    // XII. Delegation

    /**
     * @dev Allows the Glyph owner to authorize another address to perform actions
     *      (like crafting/upgrading) on behalf of this specific Glyph.
     * @param glyphId The ID of the Glyph.
     * @param crafterAddress The address to authorize. Set to address(0) to revoke.
     */
    function authorizeCrafter(uint256 glyphId, address crafterAddress) external onlyGlyphOwner(glyphId) {
         require(artifacts[glyphId].owner != address(0), "Glyph does not exist");
         require(crafterAddress != artifacts[glyphId].owner, "Cannot authorize self as crafter"); // Prevent authorizing self
         authorizedCrafter[glyphId] = crafterAddress;
         if (crafterAddress == address(0)) {
             emit CrafterRevoked(glyphId);
         } else {
             emit CrafterAuthorized(glyphId, crafterAddress);
         }
    }

     /**
     * @dev Revokes the currently authorized crafter for a Glyph.
     * @param glyphId The ID of the Glyph.
     */
    function revokeCrafter(uint256 glyphId) external onlyGlyphOwner(glyphId) {
        authorizeCrafter(glyphId, address(0)); // Use the existing function
    }

     /**
     * @dev Checks if an address is the owner or authorized crafter for a Glyph.
     * @param glyphId The ID of the Glyph.
     * @param potentialCrafter The address to check.
     * @return True if the address is the owner or authorized crafter.
     */
    function isCrafterAuthorized(uint256 glyphId, address potentialCrafter) external view returns (bool) {
        require(artifacts[glyphId].owner != address(0), "Glyph does not exist");
        return artifacts[glyphId].owner == potentialCrafter || authorizedCrafter[glyphId] == potentialCrafter;
    }

    // XIII. Gating

     /**
     * @dev Checks if a user meets a specific gating requirement based on their Chronicle.
     * @param user The address of the user to check.
     * @param requirementId The ID of the gating requirement.
     * @return True if the user has the required Chronicle entry type, false otherwise.
     */
    function checkGatingRequirement(address user, uint256 requirementId) external view returns (bool) {
        uint256 requiredType = gatingRequirements[requirementId];
        if (requiredType == 0) {
            return true; // No requirement set, always passes
        }
        return _userHasChronicleEntry(user, requiredType);
    }


    // XIV. View Functions

    /**
     * @dev Gets the details of a specific Glyph.
     * @param glyphId The ID of the Glyph.
     * @return owner, glyphType, creationTime, lastUpdateTime, and attributes (mapping key/value pairs)
     */
     // Note: Returning a mapping directly from public/external view is fine in modern Solidity,
     // but fetching all keys from a mapping is not possible. You might need helper functions
     // or return attribute data as arrays if known beforehand.
    function getGlyphDetails(uint256 glyphId)
        external
        view
        returns (address owner, uint256 glyphType, uint256 creationTime, uint256 lastUpdateTime, mapping(uint256 => uint256) memory attributes)
    {
        require(artifacts[glyphId].owner != address(0), "Glyph does not exist");
        Glyph storage g = artifacts[glyphId];
        owner = g.owner;
        glyphType = g.glyphType;
        creationTime = g.creationTime;
        lastUpdateTime = g.lastUpdateTime;
        // Note: Directly returning a storage mapping requires careful handling or helper loops
        // This assumes you access specific keys off-chain. If you need all, return arrays.
        // For simplicity here, we show the mapping return.
        attributes = g.attributes;
    }


    /**
     * @dev Gets the full Chronicle history for a user.
     * @param user The address of the user.
     * @return Array of ChronicleEntry structs.
     */
    function getUserChronicle(address user) external view returns (ChronicleEntry[] memory) {
        return userChronicle[user];
    }

     /**
     * @dev Gets the full Chronicle history for a Glyph.
     * @param glyphId The ID of the Glyph.
     * @return Array of ChronicleEntry structs.
     */
    function getArtifactChronicle(uint256 glyphId) external view returns (ChronicleEntry[] memory) {
         require(artifacts[glyphId].owner != address(0), "Glyph does not exist");
         return artifactChronicle[glyphId];
     }

    /**
     * @dev Gets the description for a Chronicle entry type.
     * @param entryType The type ID.
     * @return The description string.
     */
    function getChronicleEntryDescription(uint256 entryType) external view returns (string memory) {
        return chronicleEntryDescriptions[entryType];
    }

     /**
     * @dev Gets the details of a crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return outputGlyphType, requiredComponents (mapping), initialAttributes (mapping).
     */
    // Note: Similar mapping return limitation as getGlyphDetails.
    function getCraftingRecipe(uint256 recipeId)
        external
        view
        returns (uint256 outputGlyphType, mapping(uint256 => uint256) memory requiredComponents, mapping(uint256 => uint256) memory initialAttributes)
    {
        CraftingRecipe storage recipe = craftingRecipes[recipeId];
        require(recipe.outputGlyphType > 0, "Recipe does not exist");
        outputGlyphType = recipe.outputGlyphType;
        requiredComponents = recipe.requiredComponents;
        initialAttributes = recipe.initialAttributes;
    }

    /**
     * @dev Gets the details of an upgrade recipe.
     * @param recipeId The ID of the recipe.
     * @return inputGlyphType, requiredComponents (mapping), outputGlyphTypeSuccess, outputGlyphTypeFailure, successChancePercent, successAttributes (mapping), failureAttributes (mapping).
     */
    // Note: Similar mapping return limitation as getGlyphDetails.
    function getUpgradeRecipe(uint256 recipeId)
        external
        view
        returns (
            uint256 inputGlyphType,
            mapping(uint256 => uint256) memory requiredComponents,
            uint256 outputGlyphTypeSuccess,
            uint256 outputGlyphTypeFailure,
            uint256 successChancePercent,
            mapping(uint256 => uint256) memory successAttributes,
            mapping(uint256 => uint256) memory failureAttributes
        )
    {
        UpgradeRecipe storage recipe = upgradeRecipes[recipeId];
         require(recipe.inputGlyphType > 0, "Recipe does not exist");
        inputGlyphType = recipe.inputGlyphType;
        requiredComponents = recipe.requiredComponents;
        outputGlyphTypeSuccess = recipe.outputGlyphTypeSuccess;
        outputGlyphTypeFailure = recipe.outputGlyphTypeFailure;
        successChancePercent = recipe.successChancePercent;
        successAttributes = recipe.successAttributes;
        failureAttributes = recipe.failureAttributes;
    }

    /**
     * @dev Gets the required Chronicle entry type for a gating requirement ID.
     * @param requirementId The ID of the gating requirement.
     * @return The required Chronicle entry type (0 if no requirement).
     */
    function getGatingRequirement(uint256 requirementId) external view returns (uint256) {
        return gatingRequirements[requirementId];
    }

     // Placeholder for potential future fee collection mechanism
     // function withdrawFees() external onlyOwner {
     //    uint256 balance = address(this).balance;
     //    (bool success, ) = msg.sender.call{value: balance}("");
     //    require(success, "Fee withdrawal failed");
     //    emit FeesWithdrawn(msg.sender, balance);
     // }
}
```