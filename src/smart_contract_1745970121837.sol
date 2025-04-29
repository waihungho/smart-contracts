Okay, let's create a smart contract concept that's a bit more involved than standard tokens or vaults, incorporating elements of resource management, time-based mechanics, crafting/upgrading, and dynamic parameters. We'll call it the "ChronoForge Nexus".

The idea is that users can stake various approved tokens to generate different types of "Essence" over time. This Essence is an internal, non-transferable resource within the contract. Users then use combinations of different Essence types and potentially other crafted "Components" to craft or upgrade more complex Components. Recipes and generation rates can be dynamic, managed by an admin or potential future governance. There could also be a 'Discovery' mechanic where users spend resources to potentially unlock new recipes.

This combines staking (trendy), internal resource management (creative/advanced), time-based generation (advanced), dynamic recipes/upgrades (advanced/creative), and potential for future complexity (interesting). It's not a standard ERC-20/721, DeFi pool, or simple DAO.

Here's the outline and function summary:

```solidity
// ChronoForge Nexus Smart Contract

// Outline:
// 1. Contract Overview: A system for staking approved tokens to generate
//    time-based internal "Essence" resources. Essence and crafted "Components"
//    are used to craft/upgrade other Components based on dynamic recipes.
// 2. Core State:
//    - User Stakes: Tracks tokens staked by each user and when.
//    - User Essences: Tracks balances of different Essence types per user (internal).
//    - User Components: Tracks balances of different Component types per user (internal).
//    - Essence Generation Rates: Defines how much Essence is generated per staked token per second.
//    - Allowed Stake Tokens: List of ERC20 tokens that can be staked.
//    - Recipes: Defines requirements (Essence & Components) for crafting/upgrading Components.
//    - Admin/Owner: Controls parameters, recipes, allowed tokens.
// 3. Key Mechanisms:
//    - Time-based Essence Generation: Calculated upon claiming or staking/unstaking changes.
//    - Resource Consumption: Crafting/upgrading requires and consumes Essence/Components.
//    - Dynamic Recipes: Admin can add, update, or remove recipes.
//    - Discovery Mechanic (Conceptual): A resource sink that could potentially unlock new recipes or benefits.
// 4. External Interfaces: Interacts with standard ERC20 tokens for staking.
// 5. Safety Features: Pausability, Owner-only critical functions, token withdrawal safety.

// Function Summary:
// (Categories are for clarity, not strict grouping in code)

// --- Staking & Essence Management (User Functions) ---
// 1. stake(IERC20 token, uint256 amount): Stake approved ERC20 tokens.
// 2. unstake(IERC20 token, uint256 amount): Unstake tokens and claim pending essence.
// 3. claimEssence(): Claim all pending accumulated essence from all stakes.
// 4. getPendingEssence(address user, EssenceType essenceType): View pending essence of a specific type for a user.
// 5. getPendingEssenceAll(address user): View all pending essence amounts for a user.
// 6. getUserEssence(address user, EssenceType essenceType): View user's current non-pending essence balance.
// 7. getStakeInfo(address user, IERC20 token): View details of a user's stake in a specific token.

// --- Component Crafting & Management (User Functions) ---
// 8. craftComponent(ComponentType componentToCraft, uint256 quantity): Craft components using available essence/components based on recipe.
// 9. upgradeComponent(ComponentType componentToUpgrade, uint256 quantity): Upgrade components using available essence/components based on upgrade recipe.
// 10. getUserComponents(address user, ComponentType componentType): View user's current component balance.

// --- Recipes & Costs (View Functions) ---
// 11. getRecipe(ComponentType componentType): View the crafting recipe details for a component.
// 12. getUpgradeRecipe(ComponentType componentType): View the upgrade recipe details for a component.
// 13. getEssenceGenerationRate(IERC20 stakedToken, EssenceType essenceType): View the generation rate for a specific token/essence pair.
// 14. getAllowedStakeTokens(): View the list of tokens allowed for staking.
// 15. isRecipeAvailable(ComponentType componentType): Check if a crafting recipe exists for a component.
// 16. isUpgradeRecipeAvailable(ComponentType componentType): Check if an upgrade recipe exists for a component.

// --- Discovery & Special Mechanics (User Functions) ---
// 17. attemptDiscovery(): Spend resources for a chance/progress towards discovering new recipes/benefits (implementation placeholder).
// 18. getDiscoveryProgress(address user): View user's progress in the discovery mechanic.

// --- Admin & Governance (Owner-only Functions) ---
// 19. setEssenceGenerationRate(IERC20 stakedToken, EssenceType essenceType, uint256 ratePerSecond): Set generation rate for a token/essence.
// 20. setAllowedStakeToken(IERC20 token, bool allowed): Allow or disallow a token for staking.
// 21. addRecipe(ComponentType componentToCraft, Recipe memory recipeDetails): Add a new crafting recipe.
// 22. updateRecipe(ComponentType componentToCraft, Recipe memory recipeDetails): Update an existing crafting recipe.
// 23. removeRecipe(ComponentType componentToCraft): Remove a crafting recipe.
// 24. addUpgradeRecipe(ComponentType componentToUpgrade, Recipe memory recipeDetails): Add a new upgrade recipe.
// 25. updateUpgradeRecipe(ComponentType componentToUpgrade, Recipe memory recipeDetails): Update an existing upgrade recipe.
// 26. removeUpgradeRecipe(ComponentType componentToUpgrade): Remove an upgrade recipe.
// 27. pause(): Pause critical user interactions.
// 28. unpause(): Unpause critical user interactions.
// 29. withdrawStuckTokens(address tokenAddress): Withdraw tokens accidentally sent to the contract (excluding allowed stake tokens).
// 30. setDiscoveryCost(uint256 essenceCost, uint256 componentCost): Set costs for attempting discovery. (Example admin function)

// Note: The Discovery mechanic (17, 18) is conceptual here; its internal logic (how progress works, what discoveries do) would need detailed implementation based on the desired game mechanics. The total function count exceeds 20.
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Define types of internal resources
enum EssenceType { ChronoEssence, PlasmaEssence, AetherEssence, VoidEssence }
enum ComponentType { Gear, Coil, Crystal, Conduit, Core, Catalyst, Artifact }

// Struct to hold stake information
struct StakeInfo {
    address token; // The address of the staked ERC20 token
    uint256 amount; // The amount staked
    uint256 startTime; // Timestamp when staking started or last essence claimed
    uint256 essenceGenerationRate; // Essence generated per second per token staked (specific to this stake)
    EssenceType essenceTypeGenerated; // The type of essence generated by this stake
}

// Struct to define crafting/upgrade recipes
struct Recipe {
    // Resources required for crafting/upgrading
    EssenceType[] requiredEssenceTypes;
    uint256[] requiredEssenceAmounts;
    ComponentType[] requiredComponentTypes;
    uint256[] requiredComponentAmounts;
    // Time/other factors (optional)
    // uint256 craftingTime; // Could add time locks
}

contract ChronoForgeNexus is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // User Stakes: user address => staked token => StakeInfo
    mapping(address => mapping(address => StakeInfo)) private userStakes;

    // User Essences: user address => EssenceType => balance
    mapping(address => mapping(EssenceType => uint256)) private userEssences;

    // User Components: user address => ComponentType => balance
    mapping(address => mapping(ComponentType => uint256)) private userComponents;

    // Essence Generation Rates: staked token address => EssenceType => rate per second per token
    mapping(address => mapping(EssenceType => uint256)) private essenceGenerationRates;

    // Allowed Stake Tokens
    mapping(address => bool) private allowedStakeTokens;
    address[] private allowedStakeTokenList; // For easier enumeration

    // Crafting Recipes: ComponentType to craft => Recipe details
    mapping(ComponentType => Recipe) private craftingRecipes;

    // Upgrade Recipes: ComponentType to upgrade => Recipe details
    mapping(ComponentType => Recipe) private upgradeRecipes;

    // Discovery Mechanic (Simple Example State)
    mapping(address => uint256) private userDiscoveryProgress;
    uint256 private discoveryEssenceCost;
    uint256 private discoveryComponentCost; // Example: requires 1 of a specific component
    ComponentType private discoveryRequiredComponentType; // Example: requires a 'Conduit' component

    // --- Events ---

    event Staked(address indexed user, address indexed token, uint256 amount, EssenceType essenceType);
    event Unstaked(address indexed user, address indexed token, uint256 amount, uint256 claimedEssence);
    event EssenceClaimed(address indexed user, EssenceType essenceType, uint256 amount);
    event ComponentCrafted(address indexed user, ComponentType componentType, uint256 quantity);
    event ComponentUpgraded(address indexed user, ComponentType componentType, uint256 quantity);
    event RecipeAdded(ComponentType indexed componentType, bool isUpgrade);
    event RecipeUpdated(ComponentType indexed componentType, bool isUpgrade);
    event RecipeRemoved(ComponentType indexed componentType, bool isUpgrade);
    event EssenceRateUpdated(address indexed token, EssenceType indexed essenceType, uint256 newRate);
    event StakeTokenAllowed(address indexed token, bool allowed);
    event DiscoveryAttempted(address indexed user, uint256 currentProgress);
    event DiscoveryCostUpdated(uint256 essenceCost, uint256 componentCost, ComponentType requiredComponent);

    // --- Constructor ---

    constructor() Ownable() Pausable() {
        // Set initial discovery costs (example)
        discoveryEssenceCost = 100; // Requires 100 units of ChronoEssence
        discoveryComponentCost = 1; // Requires 1 component
        discoveryRequiredComponentType = ComponentType.Conduit; // Requires 1 Conduit
    }

    // --- Internal Helper Functions ---

    // Calculates pending essence for a single stake
    function _calculatePendingEssence(StakeInfo storage stake) internal view returns (uint256 pendingEssence) {
        if (stake.amount == 0 || stake.essenceGenerationRate == 0) {
            return 0;
        }
        uint256 duration = block.timestamp - stake.startTime;
        pendingEssence = stake.amount * stake.essenceGenerationRate * duration;
    }

    // Claims pending essence for a single stake and updates the stake state
    function _claimEssenceForStake(address user, address token) internal returns (uint256 claimedAmount, EssenceType essenceType) {
        StakeInfo storage stake = userStakes[user][token];
        claimedAmount = _calculatePendingEssence(stake);
        essenceType = stake.essenceTypeGenerated;

        if (claimedAmount > 0) {
            userEssences[user][essenceType] += claimedAmount;
            stake.startTime = block.timestamp; // Reset timer
            emit EssenceClaimed(user, essenceType, claimedAmount);
        }
    }

    // Deducts required resources (essence and components)
    function _deductResources(address user, Recipe memory recipe) internal {
        for (uint i = 0; i < recipe.requiredEssenceTypes.length; i++) {
            EssenceType essenceType = recipe.requiredEssenceTypes[i];
            uint256 requiredAmount = recipe.requiredEssenceAmounts[i];
            require(userEssences[user][essenceType] >= requiredAmount, "ChronoForge: Insufficient essence");
            userEssences[user][essenceType] -= requiredAmount;
        }
        for (uint i = 0; i < recipe.requiredComponentTypes.length; i++) {
            ComponentType componentType = recipe.requiredComponentTypes[i];
            uint256 requiredAmount = recipe.requiredComponentAmounts[i];
            require(userComponents[user][componentType] >= requiredAmount, "ChronoForge: Insufficient components");
            userComponents[user][componentType] -= requiredAmount;
        }
    }

    // --- User Staking & Essence Functions ---

    /**
     * @notice Stakes an approved ERC20 token to generate essence.
     * @param token The address of the ERC20 token to stake.
     * @param amount The amount of tokens to stake.
     */
    function stake(IERC20 token, uint256 amount) external whenNotPaused {
        require(amount > 0, "ChronoForge: Amount must be > 0");
        require(allowedStakeTokens[address(token)], "ChronoForge: Token not allowed for staking");
        require(essenceGenerationRates[address(token)][EssenceType.ChronoEssence] > 0 ||
                essenceGenerationRates[address(token)][EssenceType.PlasmaEssence] > 0 ||
                essenceGenerationRates[address(token)][EssenceType.AetherEssence] > 0 ||
                essenceGenerationRates[address(token)][EssenceType.VoidEssence] > 0,
                "ChronoForge: Token has no generation rate set");

        // Claim any pending essence from existing stake of this token before adding more
        _claimEssenceForStake(msg.sender, address(token));

        token.safeTransferFrom(msg.sender, address(this), amount);

        StakeInfo storage currentStake = userStakes[msg.sender][address(token)];
        if (currentStake.amount == 0) {
             // This assumes a token only generates ONE type of essence at a time.
             // A more complex model could have tokens generate multiple essence types.
             // For simplicity here, we find the first non-zero rate.
             EssenceType generatedType;
             uint256 rate;
             if (essenceGenerationRates[address(token)][EssenceType.ChronoEssence] > 0) {
                 generatedType = EssenceType.ChronoEssence;
                 rate = essenceGenerationRates[address(token)][EssenceType.ChronoEssence];
             } else if (essenceGenerationRates[address(token)][EssenceType.PlasmaEssence] > 0) {
                 generatedType = EssenceType.PlasmaEssence;
                 rate = essenceGenerationRates[address(token)][EssenceType.PlasmaEssence];
             } else if (essenceGenerationRates[address(token)][EssenceType.AetherEssence] > 0) {
                 generatedType = EssenceType.AetherEssence;
                 rate = essenceGenerationRates[address(token)][EssenceType.AetherEssence];
             } else if (essenceGenerationRates[address(token)][EssenceType.VoidEssence] > 0) {
                 generatedType = EssenceType.VoidEssence;
                 rate = essenceGenerationRates[address(token)][EssenceType.VoidEssence];
             }
             currentStake.token = address(token);
             currentStake.amount = amount;
             currentStake.startTime = block.timestamp;
             currentStake.essenceGenerationRate = rate;
             currentStake.essenceTypeGenerated = generatedType;
             emit Staked(msg.sender, address(token), amount, generatedType);

        } else {
             // Adding to existing stake
             require(currentStake.essenceGenerationRate == essenceGenerationRates[address(token)][currentStake.essenceTypeGenerated], "ChronoForge: Rate changed, unstake first");
             currentStake.amount += amount;
             // startTime is already updated by _claimEssenceForStake
             emit Staked(msg.sender, address(token), amount, currentStake.essenceTypeGenerated);
        }
    }

    /**
     * @notice Unstakes tokens and claims all pending essence from that stake.
     * @param token The address of the staked ERC20 token.
     * @param amount The amount of tokens to unstake.
     */
    function unstake(IERC20 token, uint256 amount) external whenNotPaused {
        require(amount > 0, "ChronoForge: Amount must be > 0");
        StakeInfo storage stake = userStakes[msg.sender][address(token)];
        require(stake.amount >= amount, "ChronoForge: Insufficient staked amount");

        // Claim pending essence before unstaking
        uint256 claimed = _claimEssenceForStake(msg.sender, address(token));

        stake.amount -= amount;

        token.safeTransfer(msg.sender, amount);

        if (stake.amount == 0) {
            // Clear the stake entry if amount reaches zero
            delete userStakes[msg.sender][address(token)];
        }

        emit Unstaked(msg.sender, address(token), amount, claimed);
    }

    /**
     * @notice Claims all pending accumulated essence from all active stakes for the user.
     */
    function claimEssence() external whenNotPaused {
         // This requires iterating through all possible staked tokens per user,
         // which is not practical/gas-efficient if the user can stake many different types.
         // A better pattern is to require the user to specify the token or use
         // a system where stakes are linked in a list per user (more complex state).
         // For this example, we'll require the user to specify the token.
         // Let's rename this function or add a parameter.
         // Alternative: Users claim essence per token type staked.
         // Let's add a view to see *all* pending and make claim per token.

         // Let's change this function to claim for a *specific* token.
         // Removing this function as claimEssence(token) is more practical.
         revert("ChronoForge: Please use claimEssenceForToken(token)");
    }

     /**
     * @notice Claims all pending accumulated essence from a specific stake for the user.
     * @param token The address of the staked ERC20 token to claim from.
     */
    function claimEssenceForToken(IERC20 token) external whenNotPaused {
        StakeInfo storage stake = userStakes[msg.sender][address(token)];
        require(stake.amount > 0, "ChronoForge: No active stake for this token");
        _claimEssenceForStake(msg.sender, address(token));
    }

    /**
     * @notice Gets the amount of pending essence of a specific type for a user.
     * @param user The address of the user.
     * @param essenceType The type of essence to check.
     * @return The amount of pending essence.
     */
    function getPendingEssence(address user, EssenceType essenceType) external view returns (uint256) {
         // This requires iterating all stakes again. Similar issue to claimEssence().
         // We can return the sum of pending essence *across all stakes* that generate this type.
         uint256 pending = 0;
         // This loop iterates through a potentially large list - could hit gas limits.
         // In a real system, this state would need to be structured differently (e.g., linked list of user stakes)
         // or this function would be removed/restricted. For demonstration, we show the concept.
         for(uint i=0; i < allowedStakeTokenList.length; i++) {
             address tokenAddr = allowedStakeTokenList[i];
             StakeInfo storage stake = userStakes[user][tokenAddr];
             if (stake.amount > 0 && stake.essenceTypeGenerated == essenceType) {
                 pending += _calculatePendingEssence(stake);
             }
         }
         return pending;
    }

    /**
     * @notice Gets all pending essence amounts for a user across all essence types.
     * @param user The address of the user.
     * @return An array of EssenceTypes and their corresponding pending amounts.
     */
    function getPendingEssenceAll(address user) external view returns (EssenceType[] memory, uint256[] memory) {
         // This is also potentially gas-intensive due to iteration.
         // Collect pending essence per type by iterating stakes.
         mapping(EssenceType => uint256) memory pendingMap;
         for(uint i=0; i < allowedStakeTokenList.length; i++) {
             address tokenAddr = allowedStakeTokenList[i];
             StakeInfo storage stake = userStakes[user][tokenAddr];
             if (stake.amount > 0) {
                 pendingMap[stake.essenceTypeGenerated] += _calculatePendingEssence(stake);
             }
         }

         // Convert map to arrays for return
         EssenceType[] memory types = new EssenceType[](4); // Fixed size for 4 essence types
         uint256[] memory amounts = new uint256[](4);

         types[0] = EssenceType.ChronoEssence; amounts[0] = pendingMap[EssenceType.ChronoEssence];
         types[1] = EssenceType.PlasmaEssence; amounts[1] = pendingMap[EssenceType.PlasmaEssence];
         types[2] = EssenceType.AetherEssence; amounts[2] = pendingMap[EssenceType.AetherEssence];
         types[3] = EssenceType.VoidEssence; amounts[3] = pendingMap[EssenceType.VoidEssence];

         // Filter out types with 0 pending if needed, but returning fixed arrays is often simpler
         return (types, amounts);
    }


    /**
     * @notice Gets a user's current non-pending essence balance of a specific type.
     * @param user The address of the user.
     * @param essenceType The type of essence to check.
     * @return The user's essence balance.
     */
    function getUserEssence(address user, EssenceType essenceType) external view returns (uint256) {
        return userEssences[user][essenceType];
    }

     /**
     * @notice Gets the details of a user's stake in a specific token.
     * @param user The address of the user.
     * @param token The address of the staked ERC20 token.
     * @return StakeInfo struct containing details.
     */
    function getStakeInfo(address user, IERC20 token) external view returns (StakeInfo memory) {
        return userStakes[user][address(token)];
    }

    // --- User Component Crafting & Management Functions ---

    /**
     * @notice Crafts a specific component using required resources.
     * @param componentToCraft The type of component to craft.
     * @param quantity The number of components to craft.
     */
    function craftComponent(ComponentType componentToCraft, uint256 quantity) external whenNotPaused {
        require(quantity > 0, "ChronoForge: Quantity must be > 0");
        Recipe storage recipe = craftingRecipes[componentToCraft];
        require(recipe.requiredEssenceTypes.length > 0 || recipe.requiredComponentTypes.length > 0, "ChronoForge: Recipe does not exist");

        // Check and deduct resources for each unit crafted
        for (uint i = 0; i < quantity; i++) {
            _deductResources(msg.sender, recipe);
        }

        userComponents[msg.sender][componentToCraft] += quantity;
        emit ComponentCrafted(msg.sender, componentToCraft, quantity);
    }

    /**
     * @notice Upgrades a specific component using required resources and lower-level components.
     * @param componentToUpgrade The type of component to upgrade.
     * @param quantity The number of components to upgrade.
     */
    function upgradeComponent(ComponentType componentToUpgrade, uint256 quantity) external whenNotPaused {
        require(quantity > 0, "ChronoForge: Quantity must be > 0");
        Recipe storage recipe = upgradeRecipes[componentToUpgrade];
         require(recipe.requiredEssenceTypes.length > 0 || recipe.requiredComponentTypes.length > 0, "ChronoForge: Upgrade recipe does not exist");

        // Check and deduct resources for each unit upgraded
        for (uint i = 0; i < quantity; i++) {
             _deductResources(msg.sender, recipe);
        }

        userComponents[msg.sender][componentToUpgrade] += quantity;
        emit ComponentUpgraded(msg.sender, componentToUpgrade, quantity);
    }

    /**
     * @notice Gets a user's current balance of a specific component type.
     * @param user The address of the user.
     * @param componentType The type of component to check.
     * @return The user's component balance.
     */
    function getUserComponents(address user, ComponentType componentType) external view returns (uint256) {
        return userComponents[user][componentType];
    }


    // --- Recipes & Costs (View Functions) ---

    /**
     * @notice Gets the crafting recipe details for a component.
     * @param componentType The type of component whose recipe is requested.
     * @return The Recipe struct.
     */
    function getRecipe(ComponentType componentType) external view returns (Recipe memory) {
        return craftingRecipes[componentType];
    }

    /**
     * @notice Gets the upgrade recipe details for a component.
     * @param componentType The type of component whose upgrade recipe is requested.
     * @return The Recipe struct.
     */
    function getUpgradeRecipe(ComponentType componentType) external view returns (Recipe memory) {
        return upgradeRecipes[componentType];
    }

    /**
     * @notice Gets the essence generation rate for a specific staked token and essence type.
     * @param stakedToken The address of the staked ERC20 token.
     * @param essenceType The type of essence generated.
     * @return The rate per second per token.
     */
    function getEssenceGenerationRate(IERC20 stakedToken, EssenceType essenceType) external view returns (uint256) {
        return essenceGenerationRates[address(stakedToken)][essenceType];
    }

    /**
     * @notice Gets the list of tokens currently allowed for staking.
     * @return An array of allowed token addresses.
     */
    function getAllowedStakeTokens() external view returns (address[] memory) {
        return allowedStakeTokenList;
    }

    /**
     * @notice Checks if a crafting recipe exists for a component type.
     * @param componentType The type of component.
     * @return True if a recipe exists, false otherwise.
     */
    function isRecipeAvailable(ComponentType componentType) external view returns (bool) {
         // Check if recipe struct is non-zero (simple check, assumes empty means non-existent)
         // A more robust check might involve a separate mapping or checking a specific field.
         return craftingRecipes[componentType].requiredEssenceTypes.length > 0 || craftingRecipes[componentType].requiredComponentTypes.length > 0;
    }

    /**
     * @notice Checks if an upgrade recipe exists for a component type.
     * @param componentType The type of component.
     * @return True if an upgrade recipe exists, false otherwise.
     */
    function isUpgradeRecipeAvailable(ComponentType componentType) external view returns (bool) {
        return upgradeRecipes[componentType].requiredEssenceTypes.length > 0 || upgradeRecipes[componentType].requiredComponentTypes.length > 0;
    }

    // --- Discovery & Special Mechanics (User Functions) ---

    /**
     * @notice Attempts a discovery action by spending resources. Increases user's discovery progress.
     * (Internal discovery logic would need detailed implementation based on desired game mechanics)
     */
    function attemptDiscovery() external whenNotPaused {
        require(userEssences[msg.sender][EssenceType.ChronoEssence] >= discoveryEssenceCost, "ChronoForge: Not enough ChronoEssence for discovery");
        require(userComponents[msg.sender][discoveryRequiredComponentType] >= discoveryComponentCost, "ChronoForge: Not enough required components for discovery");

        // Deduct resources
        userEssences[msg.sender][EssenceType.ChronoEssence] -= discoveryEssenceCost;
        userComponents[msg.sender][discoveryRequiredComponentType] -= discoveryComponentCost;

        // Increase progress (simple example)
        userDiscoveryProgress[msg.sender]++;

        // TODO: Add more complex discovery logic here
        // - Potential chance of discovering a new recipe (call internal function that adds recipe via admin logic?)
        // - Granting a temporary buff
        // - Minting a special NFT

        emit DiscoveryAttempted(msg.sender, userDiscoveryProgress[msg.sender]);
    }

    /**
     * @notice Gets a user's current progress in the discovery mechanic.
     * @param user The address of the user.
     * @return The user's discovery progress value.
     */
    function getDiscoveryProgress(address user) external view returns (uint256) {
        return userDiscoveryProgress[user];
    }


    // --- Admin & Governance (Owner-only Functions) ---

    /**
     * @notice Sets the essence generation rate for a specific staked token and essence type.
     * Can be 0 to disable generation for that pair.
     * @param stakedToken The address of the ERC20 token.
     * @param essenceType The type of essence generated.
     * @param ratePerSecond The new rate (per second per token staked).
     */
    function setEssenceGenerationRate(IERC20 stakedToken, EssenceType essenceType, uint256 ratePerSecond) external onlyOwner {
        essenceGenerationRates[address(stakedToken)][essenceType] = ratePerSecond;
        emit EssenceRateUpdated(address(stakedToken), essenceType, ratePerSecond);
    }

    /**
     * @notice Allows or disallows a token for staking.
     * @param token The address of the ERC20 token.
     * @param allowed Whether the token should be allowed.
     */
    function setAllowedStakeToken(IERC20 token, bool allowed) external onlyOwner {
        bool currentlyAllowed = allowedStakeTokens[address(token)];
        if (currentlyAllowed != allowed) {
            allowedStakeTokens[address(token)] = allowed;
            if (allowed) {
                allowedStakeTokenList.push(address(token));
            } else {
                 // Remove from list (simple array removal - inefficient for large lists)
                for (uint i = 0; i < allowedStakeTokenList.length; i++) {
                    if (allowedStakeTokenList[i] == address(token)) {
                        allowedStakeTokenList[i] = allowedStakeTokenList[allowedStakeTokenList.length - 1];
                        allowedStakeTokenList.pop();
                        break;
                    }
                }
            }
             emit StakeTokenAllowed(address(token), allowed);
        }
    }

    /**
     * @notice Adds a new crafting recipe. Overwrites if recipe for component type already exists.
     * @param componentToCraft The type of component this recipe crafts.
     * @param recipeDetails The details of the recipe.
     */
    function addRecipe(ComponentType componentToCraft, Recipe memory recipeDetails) external onlyOwner {
        // Basic validation (could be more thorough)
        require(recipeDetails.requiredEssenceTypes.length == recipeDetails.requiredEssenceAmounts.length, "ChronoForge: Essence array length mismatch");
        require(recipeDetails.requiredComponentTypes.length == recipeDetails.requiredComponentAmounts.length, "ChronoForge: Component array length mismatch");

        craftingRecipes[componentToCraft] = recipeDetails;
        emit RecipeAdded(componentToCraft, false);
    }

    /**
     * @notice Updates an existing crafting recipe.
     * @param componentToCraft The type of component this recipe crafts.
     * @param recipeDetails The updated details of the recipe.
     */
    function updateRecipe(ComponentType componentToCraft, Recipe memory recipeDetails) external onlyOwner {
        // Could add a check if recipe exists first, but adding overwrites anyway.
         require(recipeDetails.requiredEssenceTypes.length == recipeDetails.requiredEssenceAmounts.length, "ChronoForge: Essence array length mismatch");
        require(recipeDetails.requiredComponentTypes.length == recipeDetails.requiredComponentAmounts.length, "ChronoForge: Component array length mismatch");

        craftingRecipes[componentToCraft] = recipeDetails;
        emit RecipeUpdated(componentToCraft, false);
    }

    /**
     * @notice Removes a crafting recipe.
     * @param componentToCraft The type of component whose recipe to remove.
     */
    function removeRecipe(ComponentType componentToCraft) external onlyOwner {
        // Could add a check if recipe exists first
        delete craftingRecipes[componentToCraft];
        emit RecipeRemoved(componentToCraft, false);
    }

     /**
     * @notice Adds a new upgrade recipe. Overwrites if recipe for component type already exists.
     * @param componentToUpgrade The type of component this recipe upgrades.
     * @param recipeDetails The details of the recipe.
     */
    function addUpgradeRecipe(ComponentType componentToUpgrade, Recipe memory recipeDetails) external onlyOwner {
         require(recipeDetails.requiredEssenceTypes.length == recipeDetails.requiredEssenceAmounts.length, "ChronoForge: Essence array length mismatch");
        require(recipeDetails.requiredComponentTypes.length == recipeDetails.requiredComponentAmounts.length, "ChronoForge: Component array length mismatch");

        upgradeRecipes[componentToUpgrade] = recipeDetails;
        emit RecipeAdded(componentToUpgrade, true);
    }

    /**
     * @notice Updates an existing upgrade recipe.
     * @param componentToUpgrade The type of component this recipe upgrades.
     * @param recipeDetails The updated details of the recipe.
     */
    function updateUpgradeRecipe(ComponentType componentToUpgrade, Recipe memory recipeDetails) external onlyOwner {
         require(recipeDetails.requiredEssenceTypes.length == recipeDetails.requiredEssenceAmounts.length, "ChronoForge: Essence array length mismatch");
        require(recipeDetails.requiredComponentTypes.length == recipeDetails.requiredComponentAmounts.length, "ChronoForge: Component array length mismatch");

        upgradeRecipes[componentToUpgrade] = recipeDetails;
        emit RecipeUpdated(componentToUpgrade, true);
    }

    /**
     * @notice Removes an upgrade recipe.
     * @param componentToUpgrade The type of component whose recipe to remove.
     */
    function removeUpgradeRecipe(ComponentType componentToUpgrade) external onlyOwner {
        delete upgradeRecipes[componentToUpgrade];
        emit RecipeRemoved(componentToUpgrade, true);
    }

    /**
     * @notice Pauses critical user operations (staking, crafting, discovery).
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses critical user operations.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw ERC20 tokens accidentally sent to the contract.
     * Prevents withdrawing tokens used for staking or other core contract functions.
     * @param tokenAddress The address of the token to withdraw.
     */
    function withdrawStuckTokens(address tokenAddress) external onlyOwner {
        require(!allowedStakeTokens[tokenAddress], "ChronoForge: Cannot withdraw allowed stake tokens via this function");
        // Could add other checks for tokens used internally (e.g., catalyst token if implemented)

        IERC20 stuckToken = IERC20(tokenAddress);
        uint256 balance = stuckToken.balanceOf(address(this));
        require(balance > 0, "ChronoForge: No tokens of this type to withdraw");
        stuckToken.safeTransfer(owner(), balance);
    }

    /**
     * @notice Sets the resource costs for attempting discovery.
     * @param essenceCost The amount of ChronoEssence required.
     * @param componentCost The amount of the required component.
     * @param requiredComponent The type of component required.
     */
    function setDiscoveryCost(uint256 essenceCost, uint256 componentCost, ComponentType requiredComponent) external onlyOwner {
        discoveryEssenceCost = essenceCost;
        discoveryComponentCost = componentCost;
        discoveryRequiredComponentType = requiredComponent;
        emit DiscoveryCostUpdated(essenceCost, componentCost, requiredComponent);
    }
}
```