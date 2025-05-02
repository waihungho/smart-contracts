Okay, let's design a smart contract that manages dynamic, evolving assets with crafting, research, and probabilistic mechanics.

Here's a concept I'll call `QuantumForge`. It will manage unique tokens (like NFTs) that have mutable properties. Users can craft new assets or modify existing ones using resources, and can participate in research to unlock new capabilities. Assets have a 'Stability' property that decays over time, potentially triggering unpredictable 'Mutations'.

---

**Outline:**

1.  **Contract Overview:** ERC721 compliant, manages dynamic asset NFTs. Interacts with an external resource token (ERC20). Features crafting, evolution, stability decay/restore, mutation, and a research system.
2.  **State Variables:** Storage for asset properties, crafting recipes, research topics, user research progress, configurations (decay rate, mutation chance), and addresses of dependencies (resource token).
3.  **Data Structures:**
    *   `AssetProperties`: Defines the mutable state of an asset (level, stability, purity, traits, etc.).
    *   `RecipeInput`: Defines ingredients (required tokens, resource amounts).
    *   `RecipeOutput`: Defines results (property changes, potentially new traits).
    *   `CraftingRecipe`: Full recipe definition (ID, name, inputs, outputs, unlock requirements).
    *   `ResearchTopic`: Defines a research project (ID, name, cost, duration, unlock result).
    *   `UserResearch`: Tracks a user's progress on a specific research topic.
4.  **Events:** Logs key actions like Minting, Crafting, Evolution, Decay, Mutation, Research Started/Completed.
5.  **Modifiers:** Access control (owner), validation (asset existence, recipe existence, etc.).
6.  **ERC721 Standard Functions:** Basic required functions (`balanceOf`, `ownerOf`, `transferFrom`, approvals, metadata URI).
7.  **Asset Management Functions:**
    *   Minting initial assets.
    *   Retrieving asset properties.
    *   Dynamic token URI generation.
8.  **Crafting Functions:**
    *   Viewing available recipes.
    *   Executing a craft operation.
    *   Admin functions to add/remove recipes.
9.  **Evolution Functions:**
    *   Evolving an asset using resources.
10. **Stability & Mutation Functions:**
    *   Triggering time-based stability decay.
    *   Restoring asset stability using resources.
    *   Checking for and applying probabilistic mutations based on asset state.
    *   Admin functions to configure decay/mutation parameters.
11. **Research Functions:**
    *   Viewing available research topics.
    *   Starting a research project (staking resources).
    *   Completing a research project (triggered externally or time-based).
    *   Claiming research results (unlocked recipes/traits).
    *   Viewing user's research status.
    *   Admin functions to add research topics.
12. **Utility & Admin Functions:**
    *   Setting resource token address.
    *   Withdrawing protocol fees/resources.
    *   Checking contract balances.
    *   Getting contract version.

---

**Function Summary (List of Public/External Functions):**

1.  `name()`: ERC721 standard.
2.  `symbol()`: ERC721 standard.
3.  `balanceOf(address owner)`: ERC721 standard.
4.  `ownerOf(uint256 tokenId)`: ERC721 standard.
5.  `approve(address to, uint256 tokenId)`: ERC721 standard.
6.  `getApproved(uint256 tokenId)`: ERC721 standard.
7.  `setApprovalForAll(address operator, bool approved)`: ERC721 standard.
8.  `isApprovedForAll(address owner, address operator)`: ERC721 standard.
9.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard.
12. `supportsInterface(bytes4 interfaceId)`: ERC721 standard.
13. `tokenURI(uint256 tokenId)`: ERC721 standard (dynamic).
14. `mintInitialAsset(address recipient, uint256 initialStability, uint256 initialPurity, string[] memory initialTraits)`: Mints a new base asset (Owner only).
15. `getAssetProperties(uint256 tokenId)`: Retrieves dynamic properties of an asset.
16. `listAvailableCraftingRecipes()`: Returns a list of available recipe IDs.
17. `getCraftingRecipe(uint256 recipeId)`: Returns details of a specific recipe.
18. `craftAsset(uint256 recipeId, uint256 targetTokenId, uint256[] memory inputTokenIds, uint256[] memory inputResourceAmounts)`: Executes a crafting recipe, modifying `targetTokenId` and consuming inputs.
19. `evolveAsset(uint256 tokenId, uint256 resourceAmount)`: Evolves an asset, increasing its level and modifying properties.
20. `triggerStabilityDecay(uint256 tokenId)`: Manually triggers the stability decay calculation for an asset.
21. `restoreStability(uint256 tokenId, uint256 resourceAmount)`: Restores an asset's stability using resources.
22. `checkAndApplyMutation(uint256 tokenId)`: Checks conditions and applies a mutation probabilistically.
23. `listAvailableResearchTopics()`: Returns a list of available research topic IDs.
24. `getResearchTopic(uint256 topicId)`: Returns details of a specific research topic.
25. `startResearch(uint256 topicId, uint256 resourceStake)`: Starts a research project for the caller.
26. `completeResearchProject(uint256 researchTopicId, address researcher)`: Marks a research project as complete (could be permissioned or based on time).
27. `claimResearchResult(uint256 researchTopicId)`: Claims the results of a completed research project.
28. `getUserResearchStatus(address user, uint256 topicId)`: Views the status of a user's research project.
29. `addCraftingRecipe(CraftingRecipe calldata recipe)`: Admin adds a new crafting recipe.
30. `addResearchTopic(ResearchTopic calldata topic)`: Admin adds a new research topic.
31. `setResourceToken(address tokenAddress)`: Admin sets the address of the ERC20 resource token.
32. `setStabilityDecayRate(uint256 rate)`: Admin sets the rate at which stability decays per unit time.
33. `setMutationChanceConfig(uint256 baseChancePercentage)`: Admin sets a base chance for mutations.
34. `withdrawProtocolFees(address tokenAddress, uint256 amount)`: Admin withdraws accumulated fees/resources.
35. `getProtocolBalance(address tokenAddress)`: Gets the contract's balance of a specific token.
36. `getContractVersion()`: Returns the contract version.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Outline ---
// 1. Contract Overview: ERC721 compliant, manages dynamic asset NFTs. Interacts with an external resource token (ERC20). Features crafting, evolution, stability decay/restore, mutation, and a research system.
// 2. State Variables: Storage for asset properties, crafting recipes, research topics, user research progress, configurations (decay rate, mutation chance), and addresses of dependencies (resource token).
// 3. Data Structures: AssetProperties, RecipeInput, RecipeOutput, CraftingRecipe, ResearchTopic, UserResearch.
// 4. Events: Logs key actions like Minting, Crafting, Evolution, Decay, Mutation, Research Started/Completed.
// 5. Modifiers: Access control (owner), validation (asset existence, recipe existence, etc.).
// 6. ERC721 Standard Functions: Basic required functions.
// 7. Asset Management Functions: Minting, Get properties, Dynamic URI.
// 8. Crafting Functions: View recipes, Execute craft, Admin add/remove recipes.
// 9. Evolution Functions: Evolve asset.
// 10. Stability & Mutation Functions: Trigger decay, Restore stability, Check/Apply mutation, Admin config.
// 11. Research Functions: View topics, Start research, Complete research, Claim results, View status, Admin add topics.
// 12. Utility & Admin Functions: Set resource token, Withdraw fees, Get contract balance, Get version.

// --- Function Summary (Public/External) ---
// name(), symbol(), balanceOf(), ownerOf(), approve(), getApproved(), setApprovalForAll(), isApprovedForAll(), transferFrom(), safeTransferFrom(address,address,uint256), safeTransferFrom(address,address,uint256,bytes), supportsInterface(), tokenURI(),
// mintInitialAsset(address, uint256, uint256, string[]), getAssetProperties(uint256), listAvailableCraftingRecipes(), getCraftingRecipe(uint256), craftAsset(uint256, uint256, uint256[], uint256[]), evolveAsset(uint256, uint256), triggerStabilityDecay(uint256), restoreStability(uint256, uint256), checkAndApplyMutation(uint256), listAvailableResearchTopics(), getResearchTopic(uint256), startResearch(uint256, uint256), completeResearchProject(uint256, address), claimResearchResult(uint256), getUserResearchStatus(address, uint256), addCraftingRecipe(CraftingRecipe), addResearchTopic(ResearchTopic), setResourceToken(address), setStabilityDecayRate(uint256), setMutationChanceConfig(uint256), withdrawProtocolFees(address, uint256), getProtocolBalance(address), getContractVersion().

contract QuantumForge is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _recipeIdCounter;
    Counters.Counter private _researchTopicIdCounter;

    // --- State Variables ---
    struct AssetProperties {
        uint256 level;
        uint256 stability; // 0-10000 (scaled percentage)
        uint256 purity;    // 0-10000 (scaled percentage)
        uint256 lastUpdateTimestamp;
        uint256 mutationType; // 0 = None, >0 = Specific mutation ID
        string[] traits;
    }

    struct RecipeInput {
        uint256[] requiredTokenIds; // Specific token IDs needed (if any)
        // Note: Could add required traits or minimum level/stability here
        uint256[] requiredResourceAmounts; // Amounts of resource token needed
    }

    struct RecipeOutput {
        uint256 levelIncrease;
        int256 stabilityChange; // Can be positive or negative
        int256 purityChange;    // Can be positive or negative
        string[] addedTraits;
        string[] removedTraits;
        bool burnInputTokens; // If true, inputTokenIds are burned (except target)
        // Note: Could add outputting a new token here
    }

    struct CraftingRecipe {
        uint256 recipeId;
        string name;
        RecipeInput input;
        RecipeOutput output;
        // Unlock requirements (e.g., unlocked by a research project)
        uint256 unlockedByResearchId; // 0 if initially available
    }

    struct ResearchTopic {
        uint256 topicId;
        string name;
        string description;
        uint256 requiredStake; // Amount of resource token to stake
        uint256 duration;      // Duration in seconds
        uint256 unlockedRecipeId; // Recipe unlocked upon completion (0 if none)
        string unlockedTrait;      // Trait unlocked upon completion (empty if none)
    }

    struct UserResearch {
        uint256 topicId;
        uint256 stakeAmount;
        uint256 startTime;
        bool isComplete;
        bool claimed;
    }

    mapping(uint256 => AssetProperties) private _assetProperties;
    mapping(uint256 => CraftingRecipe) private _craftingRecipes;
    mapping(uint256 => bool) private _isRecipeAvailable; // To quickly check if a recipe is unlocked/available
    mapping(uint256 => ResearchTopic) private _researchTopics;
    mapping(address => mapping(uint256 => UserResearch)) private _userResearch; // user => topicId => researchState

    IERC20 private _resourceToken;
    uint256 private _stabilityDecayRatePerSecond; // How much stability drops per second (scaled)
    uint256 private _baseMutationChancePercentage; // Base chance out of 100 for mutation check to trigger

    // --- Events ---
    event AssetMinted(uint256 indexed tokenId, address indexed owner, uint256 initialStability, uint256 initialPurity);
    event AssetCrafted(uint256 indexed targetTokenId, uint256 indexed recipeId, address indexed crafter);
    event AssetEvolved(uint256 indexed tokenId, address indexed evolver, uint256 newLevel);
    event StabilityDecayed(uint256 indexed tokenId, uint256 oldStability, uint256 newStability);
    event StabilityRestored(uint256 indexed tokenId, uint256 oldStability, uint256 newStability, uint256 resourceAmount);
    event MutationTriggered(uint256 indexed tokenId, uint256 indexed mutationType);
    event ResearchStarted(address indexed user, uint256 indexed topicId, uint256 stakeAmount);
    event ResearchCompleted(address indexed user, uint256 indexed topicId);
    event ResearchClaimed(address indexed user, uint256 indexed topicId, uint256 unlockedRecipeId, string unlockedTrait);
    event RecipeAdded(uint256 indexed recipeId, string name);
    event ResearchTopicAdded(uint256 indexed topicId, string name);
    event RecipeUnlocked(address indexed user, uint256 indexed recipeId);
    event TraitUnlocked(address indexed user, string trait);

    // --- Modifiers ---
    modifier assetExists(uint256 tokenId) {
        require(_exists(tokenId), "QF: token does not exist");
        _;
    }

    modifier recipeAvailable(uint256 recipeId) {
        require(_craftingRecipes.िकांनी```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// 1. Contract Overview: ERC721 compliant, manages dynamic asset NFTs. Interacts with an external resource token (ERC20). Features crafting, evolution, stability decay/restore, mutation, and a research system.
// 2. State Variables: Storage for asset properties, crafting recipes, research topics, user research progress, configurations (decay rate, mutation chance), and addresses of dependencies (resource token).
// 3. Data Structures: AssetProperties, RecipeInput, RecipeOutput, CraftingRecipe, ResearchTopic, UserResearch.
// 4. Events: Logs key actions like Minting, Crafting, Evolution, Decay, Mutation, Research Started/Completed.
// 5. Modifiers: Access control (owner), validation (asset existence, recipe existence, etc.).
// 6. ERC721 Standard Functions: Basic required functions.
// 7. Asset Management Functions: Minting, Get properties, Dynamic URI.
// 8. Crafting Functions: View recipes, Execute craft, Admin add recipes.
// 9. Evolution Functions: Evolve asset.
// 10. Stability & Mutation Functions: Trigger decay, Restore stability, Check/Apply mutation, Admin config.
// 11. Research Functions: View topics, Start research, Complete research, Claim results, View status, Admin add topics.
// 12. Utility & Admin Functions: Set resource token, Withdraw fees, Get contract balance, Get version.

// --- Function Summary (Public/External) ---
// name(), symbol(), balanceOf(), ownerOf(), approve(), getApproved(), setApprovalForAll(), isApprovedForAll(), transferFrom(), safeTransferFrom(address,address,uint256), safeTransferFrom(address,address,uint256,bytes), supportsInterface(), tokenURI(),
// mintInitialAsset(address, uint256, uint256, string[]), getAssetProperties(uint256), listAvailableCraftingRecipes(), getCraftingRecipe(uint256), craftAsset(uint256, uint256, uint256[], uint256[]), evolveAsset(uint256, uint256), triggerStabilityDecay(uint256), restoreStability(uint256, uint256), checkAndApplyMutation(uint256), listAvailableResearchTopics(), getResearchTopic(uint256), startResearch(uint256, uint256), completeResearchProject(uint256, address), claimResearchResult(uint256), getUserResearchStatus(address, uint256), addCraftingRecipe(CraftingRecipe), addResearchTopic(ResearchTopic), setResourceToken(address), setStabilityDecayRate(uint256), setMutationChanceConfig(uint256), withdrawProtocolFees(address, uint256), getProtocolBalance(address), getContractVersion().

contract QuantumForge is ERC721, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _recipeIdCounter;
    Counters.Counter private _researchTopicIdCounter;

    // --- State Variables ---
    // Represents the mutable state of an asset
    struct AssetProperties {
        uint256 level;
        uint256 stability; // 0-10000 (scaled percentage, 100% = 10000)
        uint256 purity;    // 0-10000 (scaled percentage, 100% = 10000)
        uint256 lastUpdateTimestamp;
        uint256 mutationType; // 0 = None, >0 = Specific mutation ID (arbitrary for this example)
        string[] traits;
    }

    // Defines required inputs for crafting
    struct RecipeInput {
        uint256[] requiredTokenIds; // Specific token IDs needed (if any are burned/consumed)
        // Note: Could add required traits or minimum level/stability here
        uint256[] requiredResourceAmounts; // Amounts of resource token needed (index corresponds to requiredTokenIds or is global)
        // For simplicity, let's assume requiredResourceAmounts is global for the recipe
        uint256 totalRequiredResource;
    }

    // Defines the output effects of crafting
    struct RecipeOutput {
        uint256 levelIncrease;
        int256 stabilityChange; // Can be positive or negative
        int256 purityChange;    // Can be positive or negative
        string[] addedTraits;
        string[] removedTraits;
        bool burnInputTokens; // If true, specified inputTokenIds (except the targetTokenId if present) are burned
    }

    // Full crafting recipe definition
    struct CraftingRecipe {
        uint256 recipeId;
        string name;
        RecipeInput input;
        RecipeOutput output;
        // Unlock requirements (e.g., unlocked by a research project)
        uint256 unlockedByResearchTopicId; // 0 if initially available
    }

    // Definition of a research project
    struct ResearchTopic {
        uint256 topicId;
        string name;
        string description;
        uint256 requiredStake; // Amount of resource token to stake
        uint256 duration;      // Duration in seconds
        uint256 unlockedRecipeId; // Recipe unlocked upon completion (0 if none)
        string unlockedTrait;      // Trait unlocked upon completion (empty if none)
    }

    // Tracks a user's progress on a specific research topic
    struct UserResearch {
        uint256 topicId;
        uint256 stakeAmount;
        uint256 startTime;
        bool isComplete;
        bool claimed;
    }

    mapping(uint256 => AssetProperties) private _assetProperties;
    mapping(uint256 => CraftingRecipe) private _craftingRecipes;
    mapping(uint256 => bool) private _isRecipeUnlockedForTopic; // researchTopicId => isUnlocked
    mapping(uint256 => ResearchTopic) private _researchTopics;
    mapping(address => mapping(uint256 => UserResearch)) private _userResearch; // user => topicId => researchState

    IERC20 private _resourceToken;
    uint256 private _stabilityDecayRatePerSecond; // How much stability drops per second (scaled 0-10000 per sec)
    uint256 private _baseMutationChancePercentage; // Base chance out of 100 for mutation check to trigger

    string private _baseTokenURI;

    // Contract version
    string private constant _CONTRACT_VERSION = "1.0.0";

    // --- Events ---
    event AssetMinted(uint256 indexed tokenId, address indexed owner, uint256 initialStability, uint256 initialPurity);
    event AssetCrafted(uint256 indexed targetTokenId, uint256 indexed recipeId, address indexed crafter);
    event AssetEvolved(uint256 indexed tokenId, address indexed evolver, uint256 newLevel);
    event StabilityDecayed(uint256 indexed tokenId, uint256 oldStability, uint256 newStability);
    event StabilityRestored(uint256 indexed tokenId, uint256 oldStability, uint256 newStability, uint256 resourceAmount);
    event MutationTriggered(uint256 indexed tokenId, uint256 indexed mutationType);
    event ResearchStarted(address indexed user, uint256 indexed topicId, uint256 stakeAmount);
    event ResearchCompleted(address indexed user, uint256 indexed topicId);
    event ResearchClaimed(address indexed user, uint256 indexed topicId, uint256 unlockedRecipeId, string unlockedTrait);
    event RecipeAdded(uint256 indexed recipeId, string name);
    event ResearchTopicAdded(uint256 indexed topicId, string name);
    event RecipeUnlocked(address indexed user, uint256 indexed recipeId);
    event TraitUnlocked(address indexed user, string trait);
    event ResourceTokenSet(address indexed tokenAddress);

    // --- Modifiers ---
    modifier assetExists(uint256 tokenId) {
        require(_exists(tokenId), "QF: token does not exist");
        _;
    }

    modifier recipeExists(uint256 recipeId) {
        require(_craftingRecipes[recipeId].recipeId != 0, "QF: recipe does not exist");
        _;
    }

    modifier researchTopicExists(uint256 topicId) {
        require(_researchTopics[topicId].topicId != 0, "QF: research topic does not exist");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Initial configurations (can be set by owner later)
        _stabilityDecayRatePerSecond = 1; // Example: 1 / 10000 = 0.01% stability loss per second
        _baseMutationChancePercentage = 5; // Example: 5% base chance
    }

    // --- Internal Helpers ---

    // Applies stability decay based on time passed
    function _applyStabilityDecay(uint256 tokenId) internal assetExists(tokenId) {
        AssetProperties storage asset = _assetProperties[tokenId];
        uint256 timePassed = block.timestamp.sub(asset.lastUpdateTimestamp);
        uint256 decayAmount = timePassed.mul(_stabilityDecayRatePerSecond);
        uint256 oldStability = asset.stability;

        if (decayAmount >= asset.stability) {
            asset.stability = 0;
        } else {
            asset.stability = asset.stability.sub(decayAmount);
        }
        asset.lastUpdateTimestamp = block.timestamp;

        if (oldStability != asset.stability) {
            emit StabilityDecayed(tokenId, oldStability, asset.stability);
        }
    }

    // Adds or removes traits
    function _updateTraits(uint256 tokenId, string[] memory addedTraits, string[] memory removedTraits) internal assetExists(tokenId) {
        AssetProperties storage asset = _assetProperties[tokenId];
        string[] storage currentTraits = asset.traits;

        // Add traits
        for (uint i = 0; i < addedTraits.length; i++) {
            bool found = false;
            for (uint j = 0; j < currentTraits.length; j++) {
                if (keccak256(bytes(currentTraits[j])) == keccak256(bytes(addedTraits[i]))) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                currentTraits.push(addedTraits[i]);
            }
        }

        // Remove traits
        string[] memory remainingTraits = new string[](currentTraits.length);
        uint256 remainingCount = 0;
        for (uint i = 0; i < currentTraits.length; i++) {
            bool toBeRemoved = false;
            for (uint j = 0; j < removedTraits.length; j++) {
                if (keccak256(bytes(currentTraits[i])) == keccak256(bytes(removedTraits[j]))) {
                    toBeRemoved = true;
                    break;
                }
            }
            if (!toBeRemoved) {
                remainingTraits[remainingCount] = currentTraits[i];
                remainingCount++;
            }
        }
        // Resize the traits array
        assembly {
            mstore(currentTraits.buffer, remainingCount)
        }
        for (uint i = 0; i < remainingCount; i++) {
             currentTraits[i] = remainingTraits[i];
        }
    }


    // Simple pseudo-random number generator for example (DO NOT use for high-value on mainnet)
    // For production, use Chainlink VRF or similar secure randomness solution.
    function _generatePseudoRandomNumber(uint256 seed) internal view returns (uint256) {
        // Combine block data and seed for more entropy (still not truly random)
        uint256 combinedSeed = seed.add(block.timestamp).add(uint256(keccak256(abi.encodePacked(msg.sender, tx.origin, block.number))));
        return uint256(keccak256(abi.encodePacked(combinedSeed)));
    }

    // Checks conditions and applies mutation probabilistically
    function _triggerMutationIfConditionsMet(uint256 tokenId) internal assetExists(tokenId) {
        AssetProperties storage asset = _assetProperties[tokenId];

        // Mutation check based on stability and purity (example logic)
        // Lower stability/purity could increase mutation chance
        // This is a simplified example. Real logic could be more complex.
        uint256 currentChance = _baseMutationChancePercentage;

        if (asset.stability < 2000) currentChance = currentChance.add(10); // +10% if stability < 20%
        if (asset.purity < 1000) currentChance = currentChance.add(15);   // +15% if purity < 10%
        if (asset.level > 10) currentChance = currentChance.add(asset.level.sub(10)); // +1% per level over 10

        // Cap chance at 100% (or a high value)
        currentChance = currentChance > 100 ? 100 : currentChance;

        uint256 randomValue = _generatePseudoRandomNumber(tokenId) % 100; // Get a value between 0 and 99

        if (randomValue < currentChance) {
             // Mutation occurs!
             // Determine mutation type (example: based on stability/purity levels)
            uint256 mutationId = 1; // Default/Basic mutation
            if (asset.stability == 0) mutationId = 2; // Unstable mutation
            if (asset.purity == 0) mutationId = 3;    // Impure mutation
            if (asset.stability < 1000 && asset.purity < 1000) mutationId = 4; // Volatile mutation

            asset.mutationType = mutationId;

            // Apply mutation effects (example: random trait changes, stability/purity drop)
            if (mutationId == 1) {
                // Basic: lose some purity, gain a random "Mutated" trait
                 asset.purity = asset.purity > 500 ? asset.purity.sub(500) : 0;
                 _updateTraits(tokenId, new string[]("Mutated"), new string[](0));
            } else if (mutationId == 2) {
                // Unstable: significant purity drop, could remove a trait
                 asset.purity = asset.purity > 1000 ? asset.purity.sub(1000) : 0;
                 if (asset.traits.length > 0) {
                     string[] memory removed = new string[](1);
                     removed[0] = asset.traits[0]; // Remove the first trait (example)
                    _updateTraits(tokenId, new string[](0), removed);
                 }
            }
            // Add more mutation types and effects here...

            emit MutationTriggered(tokenId, mutationId);

             // Optional: Reset mutationType after some time or action, or make it permanent
        }
    }

    // --- ERC721 Standard Functions ---

    // Override tokenURI to provide dynamic metadata URL
    function tokenURI(uint256 tokenId) public view override assetExists(tokenId) returns (string memory) {
        // Note: The actual JSON metadata should be served by an off-chain API
        // which queries the contract's state for the given tokenId
        // and generates the JSON response dynamically.
        // This function just provides the base URI + token ID.
        // Example: https://myquantumforge.api/metadata/123
        require(bytes(_baseTokenURI).length > 0, "QF: Base token URI not set");
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // The following ERC721 functions are inherited and work with the standard state.
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // transferFrom, safeTransferFrom (two versions), supportsInterface

    // Optional: Override transfer functions if decay/mutation should happen on transfer
    // Example:
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //     if (from != address(0)) { // Not minting
    //         _applyStabilityDecay(tokenId); // Apply decay before transfer
    //         // Might also check/apply mutation here, or restrict transfers below certain stability
    //     }
    // }


    // --- Asset Management Functions ---

    /**
     * @notice Mints a new initial asset. Can only be called by the contract owner.
     * @param recipient The address to mint the asset to.
     * @param initialStability The initial stability (0-10000).
     * @param initialPurity The initial purity (0-10000).
     * @param initialTraits An array of initial traits for the asset.
     */
    function mintInitialAsset(address recipient, uint256 initialStability, uint256 initialPurity, string[] memory initialTraits) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        require(initialStability <= 10000, "QF: Initial stability invalid");
        require(initialPurity <= 10000, "QF: Initial purity invalid");

        _safeMint(recipient, newItemId);

        AssetProperties storage newAsset = _assetProperties[newItemId];
        newAsset.level = 1;
        newAsset.stability = initialStability;
        newAsset.purity = initialPurity;
        newAsset.lastUpdateTimestamp = block.timestamp;
        newAsset.mutationType = 0; // No mutation initially
        newAsset.traits = initialTraits;

        emit AssetMinted(newItemId, recipient, initialStability, initialPurity);
    }

    /**
     * @notice Retrieves the dynamic properties of a specific asset.
     * @param tokenId The ID of the asset.
     * @return A tuple containing the asset's properties.
     */
    function getAssetProperties(uint256 tokenId) public view assetExists(tokenId) returns (
        uint256 level,
        uint256 stability,
        uint256 purity,
        uint256 lastUpdateTimestamp,
        uint256 mutationType,
        string[] memory traits
    ) {
        AssetProperties storage asset = _assetProperties[tokenId];
        return (
            asset.level,
            asset.stability,
            asset.purity,
            asset.lastUpdateTimestamp,
            asset.mutationType,
            asset.traits
        );
    }

    // --- Crafting Functions ---

    /**
     * @notice Lists the IDs of all available crafting recipes.
     * @return An array of available recipe IDs.
     */
    function listAvailableCraftingRecipes() public view returns (uint256[] memory) {
        uint256[] memory availableRecipes = new uint256[](_recipeIdCounter.current()); // Max size, will copy later

        uint256 count = 0;
        // Iterate through all potential recipe IDs up to the current counter
        for (uint i = 1; i <= _recipeIdCounter.current(); i++) {
             CraftingRecipe storage recipe = _craftingRecipes[i];
             // Check if recipe exists AND if it's unlocked (if required)
             if (recipe.recipeId != 0 && (_isRecipeUnlockedForTopic[recipe.unlockedByResearchTopicId] || recipe.unlockedByResearchTopicId == 0)) {
                 availableRecipes[count] = recipe.recipeId;
                 count++;
             }
        }

        // Create a new array with the exact count
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = availableRecipes[i];
        }
        return result;
    }


    /**
     * @notice Retrieves details of a specific crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return A tuple containing the recipe's details.
     */
    function getCraftingRecipe(uint256 recipeId) public view recipeExists(recipeId) returns (CraftingRecipe memory) {
        // Ensure the recipe is available/unlocked to view details, or allow viewing if it exists but is locked
        // For now, allow viewing if it exists, but craft function checks unlocked status.
        return _craftingRecipes[recipeId];
    }

    /**
     * @notice Executes a crafting recipe. Requires the caller to own input tokens and approve resource token transfer.
     * @param recipeId The ID of the recipe to execute.
     * @param targetTokenId The ID of the asset token that will be modified (if recipe applies to an existing token). Use 0 if the recipe mints a new token (not implemented in this version).
     * @param inputTokenIds An array of token IDs required as input ingredients.
     * @param inputResourceAmounts An array of amounts of resource token required as input ingredients. For simplicity, assume this maps to inputTokenIds or is a single amount. Let's use totalRequiredResource in RecipeInput struct. inputResourceAmounts param is kept for potential future complexity.
     */
    function craftAsset(uint256 recipeId, uint256 targetTokenId, uint256[] memory inputTokenIds, uint256[] memory inputResourceAmounts /* Kept for flexibility, but RecipeInput.totalRequiredResource used for simplicity */) external recipeExists(recipeId) assetExists(targetTokenId) {
        CraftingRecipe storage recipe = _craftingRecipes[recipeId];
        AssetProperties storage targetAsset = _assetProperties[targetTokenId];

        // Check if recipe is unlocked if required
        require(_isRecipeUnlockedForTopic[recipe.unlockedByResearchTopicId] || recipe.unlockedByResearchTopicId == 0, "QF: Recipe is locked");

        // --- Input Validation and Consumption ---

        // Check target token ownership
        require(ownerOf(targetTokenId) == msg.sender, "QF: Caller does not own target token");

        // Check and consume input tokens
        require(inputTokenIds.length == recipe.input.requiredTokenIds.length, "QF: Incorrect number of input tokens provided");
        // This simple check assumes inputTokenIds maps 1:1 with recipe.input.requiredTokenIds and order matters.
        // A more robust check would iterate through both lists ensuring all required tokens are provided and owned.
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 requiredId = recipe.input.requiredTokenIds[i];
            uint256 providedId = inputTokenIds[i];
            require(_exists(providedId), "QF: Input token does not exist");
            require(ownerOf(providedId) == msg.sender, "QF: Caller does not own input token");
            // Optional: require specific token IDs match, or check for specific traits/types instead
            // For simplicity, assuming inputTokenIds *are* the required specific token IDs
            require(requiredId == providedId, "QF: Provided input token does not match required token ID");

             // Prevent using the target token as an input token to burn itself (unless logic allows)
             require(targetTokenId != providedId, "QF: Cannot use target token as burnable input");
        }

         // Check and consume resource token
        require(address(_resourceToken) != address(0), "QF: Resource token not set");
        uint256 totalResourceRequired = recipe.input.totalRequiredResource;
        require(_resourceToken.balanceOf(msg.sender) >= totalResourceRequired, "QF: Insufficient resource token balance");
        // Transfer resources from the user to the contract (requires user approval beforehand)
        _resourceToken.transferFrom(msg.sender, address(this), totalResourceRequired);


        // --- Apply Recipe Output ---

        // Burn input tokens if required (excluding the targetTokenId)
        if (recipe.output.burnInputTokens) {
            for (uint i = 0; i < inputTokenIds.length; i++) {
                 uint256 inputBurnId = inputTokenIds[i];
                 _burn(inputBurnId);
            }
        }

        // Update target asset properties
        targetAsset.level = targetAsset.level.add(recipe.output.levelIncrease);
        targetAsset.stability = uint256(int256(targetAsset.stability).add(recipe.output.stabilityChange));
        targetAsset.purity = uint256(int256(targetAsset.purity).add(recipe.output.purityChange));

        // Ensure stability and purity are within bounds [0, 10000]
        if (targetAsset.stability > 10000) targetAsset.stability = 10000;
        if (targetAsset.stability < 0) targetAsset.stability = 0; // Should not happen with uint256 logic, but good practice
        if (targetAsset.purity > 10000) targetAsset.purity = 10000;
        if (targetAsset.purity < 0) targetAsset.purity = 0; // Should not happen

        // Apply trait changes
        _updateTraits(targetTokenId, recipe.output.addedTraits, recipe.output.removedTraits);

        // Update last update timestamp for decay
        targetAsset.lastUpdateTimestamp = block.timestamp;

        // Check and apply mutation after changes (as changes might trigger mutation)
        _triggerMutationIfConditionsMet(targetTokenId);

        emit AssetCrafted(targetTokenId, recipeId, msg.sender);
    }


    /**
     * @notice Adds a new crafting recipe. Can only be called by the contract owner.
     * @param recipe The CraftingRecipe struct containing recipe details.
     */
    function addCraftingRecipe(CraftingRecipe calldata recipe) external onlyOwner {
         _recipeIdCounter.increment();
         uint256 newRecipeId = _recipeIdCounter.current();
         // Ensure recipe ID in struct matches the counter
         require(recipe.recipeId == newRecipeId, "QF: Recipe ID mismatch");

         // Validate recipe data (basic checks)
         require(bytes(recipe.name).length > 0, "QF: Recipe name cannot be empty");
         // Add more specific validation for inputs/outputs if needed

        _craftingRecipes[newRecipeId] = recipe;

        // If recipe is not unlocked by research, mark it as available immediately
        if (recipe.unlockedByResearchTopicId == 0) {
             _isRecipeUnlockedForTopic[0] = true; // Use 0 to signify base unlocked state
        }

        emit RecipeAdded(newRecipeId, recipe.name);
    }

    // --- Evolution Functions ---

    /**
     * @notice Evolves an asset, increasing its level and applying property changes.
     * Requires the caller to own the asset and approve resource token transfer.
     * This is a specific type of "crafting" but separated as a distinct concept.
     * @param tokenId The ID of the asset to evolve.
     * @param resourceAmount The amount of resource token to spend on evolution.
     */
    function evolveAsset(uint256 tokenId, uint256 resourceAmount) external assetExists(tokenId) {
         require(ownerOf(tokenId) == msg.sender, "QF: Caller does not own token");
         require(address(_resourceToken) != address(0), "QF: Resource token not set");

         // Define evolution costs/benefits (example logic)
         // Costs/benefits could be based on current level, traits, etc.
         uint256 requiredResource = 1000 * _assetProperties[tokenId].level; // Cost increases with level
         uint256 levelIncrease = 1;
         int256 stabilityBoost = 500; // +5% stability
         int256 purityBoost = 200;    // +2% purity

         require(resourceAmount >= requiredResource, "QF: Insufficient resource amount for evolution");
         require(_resourceToken.balanceOf(msg.sender) >= resourceAmount, "QF: Insufficient resource token balance");

         // Transfer resources
         _resourceToken.transferFrom(msg.sender, address(this), resourceAmount);

         // Apply stability decay before evolution (optional, but fits model)
         _applyStabilityDecay(tokenId);

         // Apply evolution effects
         AssetProperties storage asset = _assetProperties[tokenId];
         asset.level = asset.level.add(levelIncrease);
         asset.stability = uint256(int256(asset.stability).add(stabilityBoost));
         asset.purity = uint256(int256(asset.purity).add(purityBoost));

         // Ensure stability and purity are within bounds [0, 10000]
         if (asset.stability > 10000) asset.stability = 10000;
         if (asset.stability < 0) asset.stability = 0;
         if (asset.purity > 10000) asset.purity = 10000;
         if (asset.purity < 0) asset.purity = 0;

         asset.lastUpdateTimestamp = block.timestamp; // Update timestamp after action

         // Check and apply mutation after evolution
         _triggerMutationIfConditionsMet(tokenId);

         emit AssetEvolved(tokenId, msg.sender, asset.level);
    }


    // --- Stability & Mutation Functions ---

    /**
     * @notice Manually triggers the stability decay calculation for an asset.
     * Anyone can call this to update the asset's state based on time.
     * @param tokenId The ID of the asset.
     */
    function triggerStabilityDecay(uint256 tokenId) external assetExists(tokenId) {
        _applyStabilityDecay(tokenId);
        // Note: Mutation check is already called inside _applyStabilityDecay via _triggerMutationIfConditionsMet
    }

    /**
     * @notice Restores an asset's stability using resource tokens.
     * @param tokenId The ID of the asset.
     * @param resourceAmount The amount of resource token to spend.
     */
    function restoreStability(uint256 tokenId, uint256 resourceAmount) external assetExists(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "QF: Caller does not own token");
        require(address(_resourceToken) != address(0), "QF: Resource token not set");
        require(resourceAmount > 0, "QF: Must spend positive amount");

        // Resource cost vs. stability gain (example logic)
        uint256 stabilityGain = resourceAmount.div(10); // Example: 10 resource = 1 stability point (scaled)

        // Apply stability decay first
        _applyStabilityDecay(tokenId);

        // Transfer resources
        require(_resourceToken.balanceOf(msg.sender) >= resourceAmount, "QF: Insufficient resource token balance");
        _resourceToken.transferFrom(msg.sender, address(this), resourceAmount);

        // Apply stability gain (capped at 10000)
        AssetProperties storage asset = _assetProperties[tokenId];
        uint256 oldStability = asset.stability;
        asset.stability = asset.stability.add(stabilityGain);
        if (asset.stability > 10000) asset.stability = 10000;

        asset.lastUpdateTimestamp = block.timestamp; // Update timestamp

        // Mutation check might happen here too, or only on decay/crafting/evolution
        // For this example, let's have mutation check only on decay/craft/evolve for distinct triggers.

        emit StabilityRestored(tokenId, oldStability, asset.stability, resourceAmount);
    }

    /**
     * @notice Explicitly checks for and applies a mutation on an asset based on its current state and randomness.
     * Can be called by anyone, but the outcome depends on the asset's properties.
     * @param tokenId The ID of the asset.
     */
    function checkAndApplyMutation(uint256 tokenId) external assetExists(tokenId) {
         // Apply decay first, as decay can influence mutation chance
         _applyStabilityDecay(tokenId);
         // The decay function already calls _triggerMutationIfConditionsMet,
         // so this external function essentially just ensures decay is up-to-date
         // and the mutation check is performed. Redundant call is fine.
    }


    /**
     * @notice Sets the rate at which stability decays per second. Can only be called by the owner.
     * @param rate The new decay rate (scaled 0-10000 per sec).
     */
    function setStabilityDecayRate(uint256 rate) external onlyOwner {
        _stabilityDecayRatePerSecond = rate;
    }

    /**
     * @notice Sets the base chance percentage for mutations to occur when checked. Can only be called by the owner.
     * @param baseChancePercentage The new base chance (out of 100).
     */
    function setMutationChanceConfig(uint256 baseChancePercentage) external onlyOwner {
        require(baseChancePercentage <= 100, "QF: Chance cannot exceed 100");
        _baseMutationChancePercentage = baseChancePercentage;
    }


    // --- Research Functions ---

    /**
     * @notice Lists the IDs of all available research topics.
     * @return An array of research topic IDs.
     */
    function listAvailableResearchTopics() public view returns (uint256[] memory) {
         uint256[] memory availableTopics = new uint256[](_researchTopicIdCounter.current());
         uint256 count = 0;
         for (uint i = 1; i <= _researchTopicIdCounter.current(); i++) {
              if (_researchTopics[i].topicId != 0) {
                   availableTopics[count] = _researchTopics[i].topicId;
                   count++;
              }
         }

         uint256[] memory result = new uint256[](count);
         for(uint i = 0; i < count; i++) {
             result[i] = availableTopics[i];
         }
         return result;
    }


    /**
     * @notice Retrieves details of a specific research topic.
     * @param topicId The ID of the research topic.
     * @return A tuple containing the topic's details.
     */
    function getResearchTopic(uint256 topicId) public view researchTopicExists(topicId) returns (ResearchTopic memory) {
         return _researchTopics[topicId];
    }

    /**
     * @notice Starts a research project for the caller, staking resource tokens.
     * @param topicId The ID of the research topic to start.
     * @param resourceStake The amount of resource token to stake. Must meet the required stake.
     */
    function startResearch(uint256 topicId, uint256 resourceStake) external researchTopicExists(topicId) {
         ResearchTopic storage topic = _researchTopics[topicId];
         require(_userResearch[msg.sender][topicId].topicId == 0, "QF: Research already started or completed"); // Check if not started

         require(resourceStake >= topic.requiredStake, "QF: Insufficient resource stake");
         require(address(_resourceToken) != address(0), "QF: Resource token not set");
         require(_resourceToken.balanceOf(msg.sender) >= resourceStake, "QF: Insufficient resource token balance to stake");

         // Transfer resources to the contract as stake
         _resourceToken.transferFrom(msg.sender, address(this), resourceStake);

         _userResearch[msg.sender][topicId] = UserResearch({
             topicId: topicId,
             stakeAmount: resourceStake,
             startTime: block.timestamp,
             isComplete: false,
             claimed: false
         });

         emit ResearchStarted(msg.sender, topicId, resourceStake);
    }

    /**
     * @notice Marks a user's research project as complete if the duration has passed.
     * Can be called by anyone to check and finalize a research project's state.
     * @param researchTopicId The ID of the research topic.
     * @param researcher The address of the user whose research is being completed.
     */
    function completeResearchProject(uint256 researchTopicId, address researcher) external researchTopicExists(researchTopicId) {
         UserResearch storage userResearch = _userResearch[researcher][researchTopicId];
         require(userResearch.topicId != 0, "QF: Research project not started");
         require(!userResearch.isComplete, "QF: Research project already complete");

         ResearchTopic storage topic = _researchTopics[researchTopicId];
         require(block.timestamp >= userResearch.startTime.add(topic.duration), "QF: Research duration not passed");

         userResearch.isComplete = true;

         // Unlock recipe/trait for this user (or globally if desired, this example unlocks globally)
         // For global unlock: _isRecipeUnlockedForTopic[researchTopicId] = true;
         // For per-user unlock, need a mapping: mapping(address => mapping(uint256 => bool)) _userHasRecipe;

         // Let's make unlocks global for simplicity in this example contract structure
         if (topic.unlockedRecipeId != 0) {
             _isRecipeUnlockedForTopic[researchTopicId] = true;
             emit RecipeUnlocked(researcher, topic.unlockedRecipeId); // Emit for the user who completed it
         }
         if (bytes(topic.unlockedTrait).length > 0) {
             // In a real system, maybe add this trait to the user's profile or potential assets
             // For this example, just log the unlock event
             emit TraitUnlocked(researcher, topic.unlockedTrait); // Emit for the user
         }


         emit ResearchCompleted(researcher, researchTopicId);
    }


    /**
     * @notice Allows a user to claim the results of a completed research project, including staked resources.
     * @param researchTopicId The ID of the research topic.
     */
    function claimResearchResult(uint256 researchTopicId) external researchTopicExists(researchTopicId) {
         UserResearch storage userResearch = _userResearch[msg.sender][researchTopicId];
         require(userResearch.topicId != 0, "QF: Research project not started");
         require(userResearch.isComplete, "QF: Research project not complete");
         require(!userResearch.claimed, "QF: Research results already claimed");

         ResearchTopic storage topic = _researchTopics[researchTopicId];

         // Transfer staked resources back to the user
         require(address(_resourceToken) != address(0), "QF: Resource token not set");
         _resourceToken.transfer(msg.sender, userResearch.stakeAmount);

         // Mark as claimed
         userResearch.claimed = true;

         emit ResearchClaimed(msg.sender, researchTopicId, topic.unlockedRecipeId, topic.unlockedTrait);

         // Note: The actual unlock (e.g. enabling a recipe) happened in completeResearchProject
    }

    /**
     * @notice Retrieves the status of a user's research project on a specific topic.
     * @param user The address of the user.
     * @param topicId The ID of the research topic.
     * @return A tuple containing the user's research status.
     */
    function getUserResearchStatus(address user, uint256 topicId) public view researchTopicExists(topicId) returns (UserResearch memory) {
         return _userResearch[user][topicId];
    }

    /**
     * @notice Adds a new research topic. Can only be called by the contract owner.
     * @param topic The ResearchTopic struct containing topic details.
     */
    function addResearchTopic(ResearchTopic calldata topic) external onlyOwner {
         _researchTopicIdCounter.increment();
         uint256 newTopicId = _researchTopicIdCounter.current();
         // Ensure topic ID in struct matches the counter
         require(topic.topicId == newTopicId, "QF: Research topic ID mismatch");

         // Validate topic data (basic checks)
         require(bytes(topic.name).length > 0, "QF: Topic name cannot be empty");
         require(topic.duration > 0, "QF: Research duration must be positive");
         // Add more specific validation if needed

         _researchTopics[newTopicId] = topic;

         emit ResearchTopicAdded(newTopicId, topic.name);
    }


    // --- Utility & Admin Functions ---

    /**
     * @notice Sets the address of the ERC20 resource token used in the contract. Can only be called by the owner.
     * @param tokenAddress The address of the ERC20 token contract.
     */
    function setResourceToken(address tokenAddress) external onlyOwner {
         _resourceToken = IERC20(tokenAddress);
         emit ResourceTokenSet(tokenAddress);
    }

    /**
     * @notice Sets the base URI for token metadata. Can only be called by the owner.
     * @param baseURI The base URI string.
     */
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    /**
     * @notice Allows the owner to withdraw accumulated fees or resources from the contract.
     * @param tokenAddress The address of the token to withdraw (use address(0) for ETH).
     * @param amount The amount to withdraw.
     */
    function withdrawProtocolFees(address tokenAddress, uint256 amount) external onlyOwner {
         if (tokenAddress == address(0)) {
             // Withdraw ETH
             require(address(this).balance >= amount, "QF: Insufficient ETH balance");
             payable(msg.sender).transfer(amount);
         } else {
             // Withdraw ERC20
             IERC20 token = IERC20(tokenAddress);
             require(token.balanceOf(address(this)) >= amount, "QF: Insufficient token balance");
             token.transfer(msg.sender, amount);
         }
    }

    /**
     * @notice Gets the balance of a specific token held by the contract.
     * @param tokenAddress The address of the token (use address(0) for ETH).
     * @return The balance amount.
     */
    function getProtocolBalance(address tokenAddress) external view onlyOwner returns (uint256) {
         if (tokenAddress == address(0)) {
             return address(this).balance;
         } else {
             IERC20 token = IERC20(tokenAddress);
             return token.balanceOf(address(this));
         }
    }

     /**
      * @notice Gets the current version of the contract.
      * @return The contract version string.
      */
    function getContractVersion() public pure returns (string memory) {
         return _CONTRACT_VERSION;
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```