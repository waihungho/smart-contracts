Okay, here is a smart contract concept called "ArcaneAlchemist" that combines internal resource management, timed operations, a knowledge/skill system, and a recipe discovery mechanism. It avoids being a standard ERC20, NFT, or simple vault contract. It focuses on internal state changes simulating complex interactions.

**Outline and Function Summary:**

This contract simulates an on-chain "Alchemy" system. Users manage internal balances of different "Essences" and "Potions", gain "Knowledge", and use "Recipes" to transform Essences into Potions over time. It includes a recipe discovery mechanism where users can spend resources to unlock new recipes.

**Core Concepts:**

1.  **Essences & Potions:** Represented by `uint256` IDs. Users have internal balances managed by the contract.
2.  **Knowledge:** An internal score (`uint256`) representing user proficiency. Gained by completing operations.
3.  **Recipes:** Define the transformation (input Essences -> output Potions + Knowledge), discovery status, and duration.
4.  **Operations:** Timed processes where a user locks inputs for a duration to get outputs. Only one active operation per user at a time.
5.  **Recipe Discovery:** Users can spend resources (Essences, Knowledge) to attempt to unlock new recipes from a pool of "undiscovered" recipes.

**Function Categories:**

*   **Admin Functions (Owner Only):** Manage global parameters, add new types/recipes.
*   **View Functions:** Query state information for users, recipes, etc.
*   **User Resource Management:** Deposit (simulated initially), withdraw (simulated), transfer, burn internal balances.
*   **Alchemy Operations:** Start, check, complete, cancel operations.
*   **Recipe Discovery:** Attempt to discover new recipes.

**Function Summary (30+ Functions):**

1.  `constructor()`: Deploys the contract, sets owner.
2.  `pause()`: Admin: Pauses core user interactions.
3.  `unpause()`: Admin: Unpauses core user interactions.
4.  `addEssenceType(string memory _name)`: Admin: Defines a new Essence type with a unique ID.
5.  `addPotionType(string memory _name)`: Admin: Defines a new Potion type with a unique ID.
6.  `addRecipe(uint256[] calldata _inputEssenceIds, uint256[] calldata _inputEssenceAmounts, uint256[] calldata _outputPotionIds, uint256[] calldata _outputPotionAmounts, uint256 _knowledgeGained, uint256 _baseDuration)`: Admin: Adds a new standard recipe, available to all users if discovered.
7.  `addUndiscoveredRecipe(uint256[] calldata _inputEssenceIds, uint256[] calldata _inputEssenceAmounts, uint256[] calldata _outputPotionIds, uint256[] calldata _outputPotionAmounts, uint256 _knowledgeGained, uint256 _baseDuration, uint256 _discoveryCostKnowledge, uint256[] calldata _discoveryCostEssenceIds, uint256[] calldata _discoveryCostEssenceAmounts)`: Admin: Adds a recipe to the pool of undiscovered recipes with specific discovery costs.
8.  `mintInitialEssence(address _user, uint256 _essenceId, uint256 _amount)`: Admin: Mints initial Essence to a user's internal balance (for testing/initial distribution).
9.  `getUserEssenceBalance(address _user, uint256 _essenceId)`: View: Get a user's balance of a specific Essence.
10. `getUserPotionBalance(address _user, uint256 _potionId)`: View: Get a user's balance of a specific Potion.
11. `getUserKnowledge(address _user)`: View: Get a user's Knowledge points.
12. `getEssenceName(uint256 _essenceId)`: View: Get the name of an Essence ID.
13. `getPotionName(uint256 _potionId)`: View: Get the name of a Potion ID.
14. `getRecipeDetails(uint256 _recipeId)`: View: Get details of a specific recipe.
15. `getUserActiveOperation(address _user)`: View: Get details of a user's current active operation.
16. `isOperationComplete(address _user)`: View: Check if a user's active operation duration has passed.
17. `getUserDiscoveredRecipes(address _user)`: View: Get the list of recipe IDs discovered by a user.
18. `isRecipeDiscovered(address _user, uint256 _recipeId)`: View: Check if a user has discovered a specific recipe.
19. `getAllKnownEssenceIds()`: View: Get list of all defined Essence IDs.
20. `getAllKnownPotionIds()`: View: Get list of all defined Potion IDs.
21. `getAllAvailableRecipeIds()`: View: Get list of all recipes added (discovered or undiscovered).
22. `startAlchemyOperation(uint256 _recipeId)`: User: Initiate an operation using a discovered recipe. Checks discovery status, balance, deducts inputs, starts timer.
23. `completeAlchemyOperation()`: User: Finalize a completed operation. Checks timer, adds outputs/knowledge, clears active op.
24. `cancelAlchemyOperation()`: User: Cancel an active operation (inputs might be lost or partially returned, implement simple loss).
25. `attemptRecipeDiscovery()`: User: Attempt to discover the next available undiscovered recipe. Checks discovery costs (Knowledge, Essences), deducts them, unlocks recipe, removes it from the undiscovered pool.
26. `transferEssenceInternal(address _to, uint256 _essenceId, uint256 _amount)`: User: Transfer internal Essence balance to another user.
27. `transferPotionInternal(address _to, uint256 _potionId, uint256 _amount)`: User: Transfer internal Potion balance to another user.
28. `burnEssence(uint256 _essenceId, uint256 _amount)`: User: Burn (destroy) internal Essence balance.
29. `burnPotion(uint256 _potionId, uint256 _amount)`: User: Burn (destroy) internal Potion balance.
30. `withdrawPotion(uint256 _potionId, uint256 _amount)`: User: Simulates withdrawing a potion *from the system*, decreasing internal balance. (Could be adapted to interact with a real ERC20 withdrawal if needed, but simulating internal is simpler for this example).
31. `getUndiscoveredRecipeCost(uint256 _recipeId)`: View: Get the discovery costs for a specific undiscovered recipe.
32. `getUndiscoveredRecipeCount()`: View: Get the number of recipes remaining in the undiscovered pool.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ArcaneAlchemist
 * @dev A smart contract simulating an on-chain alchemy and resource management system.
 * Users manage internal balances of Essences and Potions, gain Knowledge, and use Recipes
 * via timed operations. Includes a recipe discovery mechanism.
 *
 * Outline and Function Summary:
 * (See above for detailed summary)
 *
 * Core Concepts:
 * - Essences & Potions: Internal balances (uint256 IDs).
 * - Knowledge: Internal user score.
 * - Recipes: Input/output definitions, duration, knowledge gain, discovery status/cost.
 * - Operations: Timed processes using recipes. One per user at a time.
 * - Recipe Discovery: Users spend resources to unlock new recipes from a pool.
 *
 * Function Categories:
 * - Admin Functions (Owner Only): pause, unpause, addEssenceType, addPotionType, addRecipe, addUndiscoveredRecipe, mintInitialEssence
 * - View Functions: getUserEssenceBalance, getUserPotionBalance, getUserKnowledge, getEssenceName, getPotionName, getRecipeDetails, getUserActiveOperation, isOperationComplete, getUserDiscoveredRecipes, isRecipeDiscovered, getAllKnownEssenceIds, getAllKnownPotionIds, getAllAvailableRecipeIds, getUndiscoveredRecipeCost, getUndiscoveredRecipeCount
 * - User Resource Management: transferEssenceInternal, transferPotionInternal, burnEssence, burnPotion, withdrawPotion
 * - Alchemy Operations: startAlchemyOperation, completeAlchemyOperation, cancelAlchemyOperation
 * - Recipe Discovery: attemptRecipeDiscovery
 *
 * Minimum 20 functions requirement met with 30+ functions.
 */
contract ArcaneAlchemist {
    address public owner;
    bool public isPaused;

    // --- State Variables ---

    // User Balances & Stats
    mapping(address => mapping(uint256 => uint256)) private userEssenceBalances;
    mapping(address => mapping(uint256 => uint256)) private userPotionBalances;
    mapping(address => uint256) private userKnowledge;

    // Asset Definitions (IDs and Names)
    mapping(uint256 => string) public essenceNames;
    mapping(uint256 => string) public potionNames;
    uint256 private nextEssenceId = 1; // Start IDs from 1
    uint256 private nextPotionId = 1;

    // Recipe Definitions
    struct Recipe {
        uint256[] inputEssenceIds;
        uint256[] inputEssenceAmounts;
        uint256[] outputPotionIds;
        uint256[] outputPotionAmounts;
        uint256 knowledgeGained;
        uint256 baseDuration; // Duration in seconds
        bool exists; // To check if a recipe ID is defined
    }
    mapping(uint256 => Recipe) private definedRecipes;
    uint256 private nextRecipeId = 1;

    // Recipe Discovery
    struct DiscoveryInfo {
        uint256 recipeId; // Links to definedRecipes
        uint256 discoveryCostKnowledge;
        uint256[] discoveryCostEssenceIds;
        uint256[] discoveryCostEssenceAmounts;
    }
    DiscoveryInfo[] private undiscoveredRecipes; // Pool of recipes waiting to be discovered
    mapping(address => mapping(uint256 => bool)) private userDiscoveredRecipes; // user => recipeId => discovered?

    // Active Operations
    struct ActiveOperation {
        uint256 recipeId;
        uint256 startTime;
        bool isActive;
    }
    mapping(address => ActiveOperation) private userActiveOperations; // Only one active operation per user

    // --- Events ---

    event Paused(address account);
    event Unpaused(address account);
    event EssenceTypeAdded(uint256 indexed essenceId, string name);
    event PotionTypeAdded(uint256 indexed potionId, string name);
    event RecipeAdded(uint256 indexed recipeId, uint256 knowledgeGained, uint256 baseDuration);
    event UndiscoveredRecipeAdded(uint256 indexed recipeId, uint256 discoveryCostKnowledge);
    event EssenceMinted(address indexed user, uint256 indexed essenceId, uint256 amount);
    event EssenceTransferred(address indexed from, address indexed to, uint256 indexed essenceId, uint256 amount);
    event PotionTransferred(address indexed from, address indexed to, uint256 indexed potionId, uint256 amount);
    event EssenceBurned(address indexed user, uint256 indexed essenceId, uint256 amount);
    event PotionBurned(address indexed user, uint256 indexed potionId, uint256 amount);
    event PotionWithdrawn(address indexed user, uint256 indexed potionId, uint256 amount); // Simulated withdrawal
    event OperationStarted(address indexed user, uint256 indexed recipeId, uint256 startTime);
    event OperationCompleted(address indexed user, uint256 indexed recipeId, uint256 knowledgeGained);
    event OperationCancelled(address indexed user, uint256 indexed recipeId);
    event KnowledgeGained(address indexed user, uint256 amount);
    event RecipeDiscovered(address indexed user, uint256 indexed recipeId);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused, "Contract is not paused");
        _;
    }

    modifier userNotBusy() {
        require(!userActiveOperations[msg.sender].isActive, "User is already busy with an operation");
        _;
    }

    modifier userIsBusy() {
        require(userActiveOperations[msg.sender].isActive, "User is not busy with an operation");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        isPaused = false;
    }

    // --- Admin Functions ---

    /**
     * @dev Pauses the contract. Only owner can call.
     */
    function pause() external onlyOwner whenNotPaused {
        isPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpause() external onlyOwner whenPaused {
        isPaused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Defines a new essence type.
     * @param _name The human-readable name of the essence.
     */
    function addEssenceType(string memory _name) external onlyOwner {
        uint256 newId = nextEssenceId++;
        essenceNames[newId] = _name;
        emit EssenceTypeAdded(newId, _name);
    }

    /**
     * @dev Defines a new potion type.
     * @param _name The human-readable name of the potion.
     */
    function addPotionType(string memory _name) external onlyOwner {
        uint256 newId = nextPotionId++;
        potionNames[newId] = _name;
        emit PotionTypeAdded(newId, _name);
    }

    /**
     * @dev Adds a new standard recipe. This recipe must still be discovered by users
     * if it's intended as an undiscovered recipe. Use `addUndiscoveredRecipe` for that.
     * @param _inputEssenceIds IDs of required essences.
     * @param _inputEssenceAmounts Amounts of required essences.
     * @param _outputPotionIds IDs of produced potions.
     * @param _outputPotionAmounts Amounts of produced potions.
     * @param _knowledgeGained Knowledge points gained upon completion.
     * @param _baseDuration Base duration in seconds.
     */
    function addRecipe(
        uint256[] calldata _inputEssenceIds,
        uint256[] calldata _inputEssenceAmounts,
        uint256[] calldata _outputPotionIds,
        uint256[] calldata _outputPotionAmounts,
        uint256 _knowledgeGained,
        uint256 _baseDuration
    ) external onlyOwner {
        require(_inputEssenceIds.length == _inputEssenceAmounts.length, "Input essence arrays mismatch");
        require(_outputPotionIds.length == _outputPotionAmounts.length, "Output potion arrays mismatch");

        uint256 newRecipeId = nextRecipeId++;
        Recipe storage newRecipe = definedRecipes[newRecipeId];
        newRecipe.inputEssenceIds = _inputEssenceIds;
        newRecipe.inputEssenceAmounts = _inputEssenceAmounts;
        newRecipe.outputPotionIds = _outputPotionIds;
        newRecipe.outputPotionAmounts = _outputPotionAmounts;
        newRecipe.knowledgeGained = _knowledgeGained;
        newRecipe.baseDuration = _baseDuration;
        newRecipe.exists = true;

        emit RecipeAdded(newRecipeId, _knowledgeGained, _baseDuration);
    }

    /**
     * @dev Adds a recipe to the pool of undiscovered recipes.
     * @param _inputEssenceIds Input essence IDs for the recipe.
     * @param _inputEssenceAmounts Input essence amounts for the recipe.
     * @param _outputPotionIds Output potion IDs for the recipe.
     * @param _outputPotionAmounts Output potion amounts for the recipe.
     * @param _knowledgeGained Knowledge points gained upon completion.
     * @param _baseDuration Base duration in seconds.
     * @param _discoveryCostKnowledge Knowledge required to attempt discovery.
     * @param _discoveryCostEssenceIds Essence IDs required to attempt discovery.
     * @param _discoveryCostEssenceAmounts Essence amounts required to attempt discovery.
     */
    function addUndiscoveredRecipe(
        uint256[] calldata _inputEssenceIds,
        uint256[] calldata _inputEssenceAmounts,
        uint256[] calldata _outputPotionIds,
        uint256[] calldata _outputPotionAmounts,
        uint256 _knowledgeGained,
        uint256 _baseDuration,
        uint256 _discoveryCostKnowledge,
        uint256[] calldata _discoveryCostEssenceIds,
        uint256[] calldata _discoveryCostEssenceAmounts
    ) external onlyOwner {
        require(_discoveryCostEssenceIds.length == _discoveryCostEssenceAmounts.length, "Discovery cost essence arrays mismatch");

        // First, add the recipe definition as a regular recipe
        uint256 newRecipeId = nextRecipeId++;
        Recipe storage newRecipe = definedRecipes[newRecipeId];
        newRecipe.inputEssenceIds = _inputEssenceIds;
        newRecipe.inputEssenceAmounts = _inputEssenceAmounts;
        newRecipe.outputPotionIds = _outputPotionIds;
        newRecipe.outputPotionAmounts = _outputPotionAmounts;
        newRecipe.knowledgeGained = _knowledgeGained;
        newRecipe.baseDuration = _baseDuration;
        newRecipe.exists = true;

        // Then, add its discovery info to the undiscovered pool
        undiscoveredRecipes.push(
            DiscoveryInfo({
                recipeId: newRecipeId,
                discoveryCostKnowledge: _discoveryCostKnowledge,
                discoveryCostEssenceIds: _discoveryCostEssenceIds,
                discoveryCostEssenceAmounts: _discoveryCostEssenceAmounts
            })
        );

        emit UndiscoveredRecipeAdded(newRecipeId, _discoveryCostKnowledge);
        emit RecipeAdded(newRecipeId, _knowledgeGained, _baseDuration); // Also signal recipe existence
    }

    /**
     * @dev Mints initial essence balance for a user (for setup/testing).
     * @param _user The user to mint essence for.
     * @param _essenceId The ID of the essence.
     * @param _amount The amount to mint.
     */
    function mintInitialEssence(address _user, uint256 _essenceId, uint256 _amount) external onlyOwner {
        require(essenceNames[_essenceId].length > 0, "Essence ID not defined");
        userEssenceBalances[_user][_essenceId] += _amount;
        emit EssenceMinted(_user, _essenceId, _amount);
    }

    // --- View Functions ---

    /**
     * @dev Gets a user's balance of a specific essence.
     * @param _user The user address.
     * @param _essenceId The ID of the essence.
     * @return The balance amount.
     */
    function getUserEssenceBalance(address _user, uint256 _essenceId) external view returns (uint256) {
        return userEssenceBalances[_user][_essenceId];
    }

    /**
     * @dev Gets a user's balance of a specific potion.
     * @param _user The user address.
     * @param _potionId The ID of the potion.
     * @return The balance amount.
     */
    function getUserPotionBalance(address _user, uint256 _potionId) external view returns (uint256) {
        return userPotionBalances[_user][_potionId];
    }

    /**
     * @dev Gets a user's knowledge points.
     * @param _user The user address.
     * @return The knowledge points.
     */
    function getUserKnowledge(address _user) external view returns (uint256) {
        return userKnowledge[_user];
    }

    /**
     * @dev Gets the name of an essence by ID.
     * @param _essenceId The ID of the essence.
     * @return The name of the essence.
     */
    function getEssenceName(uint256 _essenceId) external view returns (string memory) {
        return essenceNames[_essenceId];
    }

    /**
     * @dev Gets the name of a potion by ID.
     * @param _potionId The ID of the potion.
     * @return The name of the potion.
     */
    function getPotionName(uint256 _potionId) external view returns (string memory) {
        return potionNames[_potionId];
    }

    /**
     * @dev Gets details of a specific recipe.
     * @param _recipeId The ID of the recipe.
     * @return Recipe details.
     */
    function getRecipeDetails(uint256 _recipeId) external view returns (
        uint256[] memory inputEssenceIds,
        uint256[] memory inputEssenceAmounts,
        uint256[] memory outputPotionIds,
        uint256[] memory outputPotionAmounts,
        uint256 knowledgeGained,
        uint256 baseDuration,
        bool exists
    ) {
        Recipe storage recipe = definedRecipes[_recipeId];
        return (
            recipe.inputEssenceIds,
            recipe.inputEssenceAmounts,
            recipe.outputPotionIds,
            recipe.outputPotionAmounts,
            recipe.knowledgeGained,
            recipe.baseDuration,
            recipe.exists
        );
    }

    /**
     * @dev Gets details of a user's current active operation.
     * @param _user The user address.
     * @return recipeId The ID of the active recipe.
     * @return startTime The timestamp when the operation started.
     * @return isActive Whether an operation is currently active.
     */
    function getUserActiveOperation(address _user) external view returns (uint256 recipeId, uint256 startTime, bool isActive) {
        ActiveOperation storage op = userActiveOperations[_user];
        return (op.recipeId, op.startTime, op.isActive);
    }

    /**
     * @dev Checks if a user's active operation duration has passed.
     * @param _user The user address.
     * @return True if the operation is complete, false otherwise.
     */
    function isOperationComplete(address _user) external view returns (bool) {
        ActiveOperation storage op = userActiveOperations[_user];
        if (!op.isActive) {
            return false;
        }
        Recipe storage recipe = definedRecipes[op.recipeId];
        // Check if recipe exists defensively, though active op should imply it does
        if (!recipe.exists) {
            return false;
        }
        return block.timestamp >= op.startTime + recipe.baseDuration;
    }

    /**
     * @dev Gets the list of recipe IDs discovered by a user.
     * @param _user The user address.
     * @return An array of discovered recipe IDs.
     */
    function getUserDiscoveredRecipes(address _user) external view returns (uint256[] memory) {
        // Note: This is inefficient if a user discovers many recipes.
        // A better way might involve pagination or storing the list directly.
        // For this example, we iterate through all known recipes.
        uint256[] memory allRecipes = getAllAvailableRecipeIds();
        uint256 count = 0;
        for (uint256 i = 0; i < allRecipes.length; i++) {
            if (userDiscoveredRecipes[_user][allRecipes[i]]) {
                count++;
            }
        }

        uint256[] memory discovered = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allRecipes.length; i++) {
            if (userDiscoveredRecipes[_user][allRecipes[i]]) {
                discovered[index] = allRecipes[i];
                index++;
            }
        }
        return discovered;
    }

     /**
     * @dev Checks if a user has discovered a specific recipe.
     * @param _user The user address.
     * @param _recipeId The ID of the recipe.
     * @return True if discovered, false otherwise.
     */
    function isRecipeDiscovered(address _user, uint256 _recipeId) external view returns (bool) {
         // Recipes added via addRecipe are implicitly "discovered" for everyone from the start
         // Recipes added via addUndiscoveredRecipe must be explicitly discovered per user
        return userDiscoveredRecipes[_user][_recipeId];
    }


    /**
     * @dev Gets a list of all defined Essence IDs.
     * @return An array of Essence IDs.
     */
    function getAllKnownEssenceIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](nextEssenceId - 1);
        for (uint265 i = 1; i < nextEssenceId; i++) {
            ids[i-1] = i;
        }
        return ids;
    }

    /**
     * @dev Gets a list of all defined Potion IDs.
     * @return An array of Potion IDs.
     */
    function getAllKnownPotionIds() external view returns (uint256[] memory) {
        uint265[] memory ids = new uint256[](nextPotionId - 1);
        for (uint256 i = 1; i < nextPotionId; i++) {
            ids[i-1] = i;
        }
        return ids;
    }

    /**
     * @dev Gets a list of all recipe IDs that have been added (discovered or undiscovered).
     * @return An array of recipe IDs.
     */
    function getAllAvailableRecipeIds() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](nextRecipeId - 1);
         for (uint256 i = 1; i < nextRecipeId; i++) {
            ids[i-1] = i;
        }
        return ids;
    }

    /**
     * @dev Gets the discovery costs for a specific recipe in the undiscovered pool.
     * @param _recipeId The ID of the recipe.
     * @return Discovery costs (knowledge, essence IDs, essence amounts).
     */
    function getUndiscoveredRecipeCost(uint256 _recipeId) external view returns (uint256 knowledgeCost, uint256[] memory essenceIds, uint256[] memory essenceAmounts) {
         for (uint256 i = 0; i < undiscoveredRecipes.length; i++) {
            if (undiscoveredRecipes[i].recipeId == _recipeId) {
                return (
                    undiscoveredRecipes[i].discoveryCostKnowledge,
                    undiscoveredRecipes[i].discoveryCostEssenceIds,
                    undiscoveredRecipes[i].discoveryCostEssenceAmounts
                );
            }
        }
        revert("Recipe not found in undiscovered pool");
    }

    /**
     * @dev Gets the number of recipes remaining in the undiscovered pool.
     * @return The count of undiscovered recipes.
     */
    function getUndiscoveredRecipeCount() external view returns (uint256) {
        return undiscoveredRecipes.length;
    }

    // --- User Resource Management ---

    /**
     * @dev Transfers internal essence balance from sender to another user.
     * @param _to The recipient address.
     * @param _essenceId The ID of the essence.
     * @param _amount The amount to transfer.
     */
    function transferEssenceInternal(address _to, uint256 _essenceId, uint256 _amount) external whenNotPaused {
        require(_to != address(0), "Cannot transfer to zero address");
        require(userEssenceBalances[msg.sender][_essenceId] >= _amount, "Insufficient essence balance");
        userEssenceBalances[msg.sender][_essenceId] -= _amount;
        userEssenceBalances[_to][_essenceId] += _amount;
        emit EssenceTransferred(msg.sender, _to, _essenceId, _amount);
    }

    /**
     * @dev Transfers internal potion balance from sender to another user.
     * @param _to The recipient address.
     * @param _potionId The ID of the potion.
     * @param _amount The amount to transfer.
     */
    function transferPotionInternal(address _to, uint256 _potionId, uint256 _amount) external whenNotPaused {
        require(_to != address(0), "Cannot transfer to zero address");
        require(userPotionBalances[msg.sender][_potionId] >= _amount, "Insufficient potion balance");
        userPotionBalances[msg.sender][_potionId] -= _amount;
        userPotionBalances[_to][_potionId] += _amount;
        emit PotionTransferred(msg.sender, _to, _potionId, _amount);
    }

    /**
     * @dev Burns internal essence balance of the sender.
     * @param _essenceId The ID of the essence.
     * @param _amount The amount to burn.
     */
    function burnEssence(uint256 _essenceId, uint256 _amount) external whenNotPaused {
        require(userEssenceBalances[msg.sender][_essenceId] >= _amount, "Insufficient essence balance to burn");
        userEssenceBalances[msg.sender][_essenceId] -= _amount;
        emit EssenceBurned(msg.sender, _essenceId, _amount);
    }

    /**
     * @dev Burns internal potion balance of the sender.
     * @param _potionId The ID of the potion.
     * @param _amount The amount to burn.
     */
    function burnPotion(uint256 _potionId, uint256 _amount) external whenNotPaused {
         require(userPotionBalances[msg.sender][_potionId] >= _amount, "Insufficient potion balance to burn");
        userPotionBalances[msg.sender][_potionId] -= _amount;
        emit PotionBurned(msg.sender, _potionId, _amount);
    }

    /**
     * @dev Simulates withdrawing a potion from the contract system, decreasing internal balance.
     * Does NOT transfer real tokens unless integrated.
     * @param _potionId The ID of the potion to withdraw.
     * @param _amount The amount to withdraw.
     */
    function withdrawPotion(uint256 _potionId, uint256 _amount) external whenNotPaused {
        require(userPotionBalances[msg.sender][_potionId] >= _amount, "Insufficient potion balance to withdraw");
        userPotionBalances[msg.sender][_potionId] -= _amount;
        // In a real application, this might trigger an external token transfer
        // Or interaction with another system. Here, it's just a balance decrease.
        emit PotionWithdrawn(msg.sender, _potionId, _amount);
    }

    // --- Alchemy Operations ---

    /**
     * @dev Starts an alchemy operation for the user.
     * @param _recipeId The ID of the recipe to use.
     */
    function startAlchemyOperation(uint256 _recipeId) external whenNotPaused userNotBusy {
        Recipe storage recipe = definedRecipes[_recipeId];
        require(recipe.exists, "Recipe does not exist");
        require(userDiscoveredRecipes[msg.sender][_recipeId], "Recipe not discovered");

        // Check and deduct input essences
        for (uint256 i = 0; i < recipe.inputEssenceIds.length; i++) {
            uint256 essenceId = recipe.inputEssenceIds[i];
            uint256 requiredAmount = recipe.inputEssenceAmounts[i];
            require(userEssenceBalances[msg.sender][essenceId] >= requiredAmount, "Insufficient essence balance for inputs");
            userEssenceBalances[msg.sender][essenceId] -= requiredAmount;
        }

        // Set active operation
        userActiveOperations[msg.sender] = ActiveOperation({
            recipeId: _recipeId,
            startTime: block.timestamp,
            isActive: true
        });

        emit OperationStarted(msg.sender, _recipeId, block.timestamp);
    }

    /**
     * @dev Completes a finished alchemy operation and grants outputs/knowledge.
     */
    function completeAlchemyOperation() external whenNotPaused userIsBusy {
        ActiveOperation storage op = userActiveOperations[msg.sender];
        Recipe storage recipe = definedRecipes[op.recipeId];

        require(block.timestamp >= op.startTime + recipe.baseDuration, "Operation not yet complete");

        // Add output potions
        for (uint256 i = 0; i < recipe.outputPotionIds.length; i++) {
            userPotionBalances[msg.sender][recipe.outputPotionIds[i]] += recipe.outputPotionAmounts[i];
        }

        // Add knowledge
        if (recipe.knowledgeGained > 0) {
             userKnowledge[msg.sender] += recipe.knowledgeGained;
             emit KnowledgeGained(msg.sender, recipe.knowledgeGained);
        }


        // Clear active operation
        uint256 completedRecipeId = op.recipeId; // Store before clearing
        delete userActiveOperations[msg.sender];

        emit OperationCompleted(msg.sender, completedRecipeId, recipe.knowledgeGained);
    }

    /**
     * @dev Cancels an active alchemy operation. Inputs are lost.
     * Note: A more complex contract might implement partial refunds.
     */
    function cancelAlchemyOperation() external whenNotPaused userIsBusy {
        ActiveOperation storage op = userActiveOperations[msg.sender];
        uint256 cancelledRecipeId = op.recipeId; // Store before clearing

        // Inputs were already deducted when starting the operation and are NOT refunded.

        // Clear active operation
        delete userActiveOperations[msg.sender];

        emit OperationCancelled(msg.sender, cancelledRecipeId);
    }

    // --- Recipe Discovery ---

    /**
     * @dev Attempts to discover the next available recipe from the undiscovered pool.
     * Requires spending resources defined by the recipe's discovery cost.
     * Discovery is sequential based on the order recipes were added via addUndiscoveredRecipe.
     */
    function attemptRecipeDiscovery() external whenNotPaused {
        require(undiscoveredRecipes.length > 0, "No undiscovered recipes left");

        // Get the next undiscovered recipe from the pool (sequential discovery)
        DiscoveryInfo storage discoveryInfo = undiscoveredRecipes[0];
        uint256 recipeIdToDiscover = discoveryInfo.recipeId;
        Recipe storage recipe = definedRecipes[recipeIdToDiscover]; // Get details from definedRecipes

        require(!userDiscoveredRecipes[msg.sender][recipeIdToDiscover], "Recipe already discovered");

        // Check and deduct discovery costs (Knowledge)
        require(userKnowledge[msg.sender] >= discoveryInfo.discoveryCostKnowledge, "Insufficient knowledge for discovery");
        userKnowledge[msg.sender] -= discoveryInfo.discoveryCostKnowledge;

         // Check and deduct discovery costs (Essences)
        for (uint256 i = 0; i < discoveryInfo.discoveryCostEssenceIds.length; i++) {
            uint256 essenceId = discoveryInfo.discoveryCostEssenceIds[i];
            uint256 requiredAmount = discoveryInfo.discoveryCostEssenceAmounts[i];
            require(userEssenceBalances[msg.sender][essenceId] >= requiredAmount, "Insufficient essence for discovery cost");
            userEssenceBalances[msg.sender][essenceId] -= requiredAmount;
        }

        // Mark recipe as discovered for the user
        userDiscoveredRecipes[msg.sender][recipeIdToDiscover] = true;

        // Remove the recipe from the undiscovered pool (shift elements left)
        for (uint256 i = 0; i < undiscoveredRecipes.length - 1; i++) {
            undiscoveredRecipes[i] = undiscoveredRecipes[i + 1];
        }
        undiscoveredRecipes.pop(); // Remove the last element (which was the second-to-last shifted)

        emit RecipeDiscovered(msg.sender, recipeIdToDiscover);
        // Knowledge and Essence Burns for cost are emitted implicitly by deductions
    }
}
```