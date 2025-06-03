Okay, let's design a smart contract that simulates a dynamic, evolving ecosystem with resource management, crafting, rituals, and decay mechanics. This goes beyond standard token or NFT contracts by introducing intertwined systems.

We'll call it `CryptoEcosystem`.

**Core Concepts:**

1.  **Essence:** A non-transferable resource unique to each user, representing their connection to the ecosystem. It can be cultivated (grows over time/activity) and decays if inactive. It's consumed for actions.
2.  **Artifacts:** Fungible resources (ERC-1155 style, but implemented manually for simplicity and to avoid standard templates) found or crafted within the ecosystem. Different types have different uses. They can also decay.
3.  **Nodes:** Static points of interest users interact with to discover artifacts, costing Essence.
4.  **Crafting:** Users combine Artifacts and Essence to create new Artifacts based on defined recipes.
5.  **Rites:** High-cost Essence sacrifices for potential rare rewards.
6.  **Synergy Rituals:** Combining specific Artifacts for a chance at unique outcomes or boosts, introducing randomness.
7.  **Decay:** A mechanic where inactive users' Essence and Artifacts diminish over time, encouraging participation.
8.  **Cultivation:** A mechanic where active users' Essence grows.
9.  **Admin Controls:** The contract owner/admin can define parameters, recipes, nodes, decay rates, etc.

This design aims for complexity through interrelated systems (Essence is used for Node interaction, Crafting, Rites, Boosts; Artifacts are found at Nodes, used in Crafting, Rites, Boosts, Synergy; Decay affects both).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CryptoEcosystem
 * @notice A complex smart contract simulating a dynamic, resource-based ecosystem.
 * Users manage Essence and Artifacts, interact with Nodes, craft items, perform rituals,
 * and face decay, while benefiting from cultivation and potential synergies.
 */

// --- Outline and Function Summary ---
/*
Outline:
1. State Variables: Core data structures, configurations, user data, admin.
2. Events: Signaling important contract activities.
3. Modifiers: Access control and state checks.
4. Structs: Complex data types for users, nodes, recipes, rites, synergy outcomes.
5. Admin & Setup Functions: Initialize ecosystem parameters, add nodes, define recipes/rites/synergies.
6. User Management Functions: Register users, get user state.
7. Core Resource Management Functions (Essence & Artifacts):
   - Essence: Cultivation, Consumption (internal), Getting amount.
   - Artifacts: Discovery (via Nodes), Transfer, Getting balance, Defining types.
8. Interaction Functions:
   - Node Interaction: Interact with defined points of interest.
   - Crafting: Combine resources to create new artifacts.
   - Rituals: Perform high-cost essence sacrifices.
   - Synergy: Perform rituals with artifacts for chance outcomes.
9. Dynamic System Functions (Decay & Boosts):
   - Decay Check & Apply: Function to trigger resource decay based on inactivity.
   - Essence Boost: Use resources for temporary essence gains/reduced costs.
10. Utility & View Functions: Get state information, check parameters.
11. Pausability & Withdrawal: Contract state control and fund management.
*/

/*
Function Summary:

--- Admin & Setup ---
1. constructor() - Initializes owner and sets initial admin.
2. setAdmin(address _admin) - Sets or changes the admin address.
3. defineArtifactType(uint256 artifactTypeId, string memory name) - Defines a new type of artifact with a name.
4. addNode(uint256 nodeId, uint256 essenceCost, uint256[] memory yieldArtifactTypes, uint256[] memory yieldArtifactAmounts) - Adds a new node to the ecosystem with defined interaction cost and yields.
5. updateNode(uint256 nodeId, uint256 essenceCost, uint256[] memory yieldArtifactTypes, uint256[] memory yieldArtifactAmounts) - Updates an existing node's parameters.
6. defineCraftingRecipe(uint256 recipeId, uint256 artifactToCraft, uint256 essenceCost, uint256[] memory requiredArtifactTypes, uint256[] memory requiredArtifactAmounts) - Defines a recipe for crafting an artifact.
7. updateCraftingRecipe(uint256 recipeId, uint256 artifactToCraft, uint256 essenceCost, uint256[] memory requiredArtifactTypes, uint256[] memory requiredArtifactAmounts) - Updates an existing crafting recipe.
8. defineRite(uint256 riteId, uint256 essenceCostThreshold, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts) - Defines a type of high-cost ritual sacrifice and its reward.
9. updateRite(uint256 riteId, uint256 essenceCostThreshold, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts) - Updates an existing rite definition.
10. defineSynergyOutcome(uint256 outcomeId, uint256 essenceBoost, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts, uint256 successChance) - Defines a possible outcome for a synergy ritual with a success chance.
11. updateSynergyOutcome(uint256 outcomeId, uint256 essenceBoost, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts, uint256 successChance) - Updates an existing synergy outcome definition.
12. setEssenceCultivationRate(uint256 ratePerUnitTime) - Sets the rate at which essence cultivates for active users.
13. setEssenceDecayRate(uint256 ratePerUnitTime) - Sets the rate at which essence decays for inactive users.
14. setArtifactDecayRate(uint256 artifactTypeId, uint256 ratePerUnitTime) - Sets the decay rate for a specific artifact type.
15. setBaseEssenceBoostDuration(uint256 durationInSeconds) - Sets the base duration for essence boost effects.
16. withdrawFunds(address payable recipient, uint256 amount) - Allows owner/admin to withdraw ETH sent to the contract (e.g., from future payable functions or fees).

--- User Management ---
17. registerUser() - Allows a new user to join the ecosystem, receiving initial essence.
18. getUserState(address user) - View function to get a user's current essence, artifact balances, and last activity time.

--- Core Resource & Interaction ---
19. cultivateEssence() - Allows a user to manually trigger essence cultivation based on time elapsed.
20. _consumeEssence(address user, uint256 amount) - Internal function to decrease a user's essence.
21. discoverArtifact(uint256 nodeId) - User interacts with a node, consuming essence and yielding artifacts based on the node's definition.
22. transferArtifact(address recipient, uint256 artifactTypeId, uint256 amount) - Allows a user to transfer artifacts to another user.
23. craftArtifact(uint256 recipeId) - User crafts an artifact by consuming required artifacts and essence based on a recipe.
24. performEssenceRite(uint256 riteId) - User performs a ritual sacrifice of essence to potentially earn a reward defined by the rite.
25. claimRiteReward(uint256 pendingRiteIndex) - User claims a pending reward from a previously performed rite.
26. performSynergyRitual(uint256[] memory artifactTypes, uint256[] memory amounts) - User performs a ritual by consuming artifacts, with a chance of triggering a predefined synergy outcome.

--- Dynamic System ---
27. checkAndApplyDecay(address user) - Public function that anyone can call to check and apply decay for a user based on inactivity.
28. applyEssenceBoost(uint256[] memory artifactTypes, uint256[] memory amounts) - User consumes specific artifacts to gain a temporary boost to essence mechanics (e.g., increased cultivation, reduced consumption/decay). (Implementation detail: boost could be stored as a timestamp and multiplier in UserInfo).

--- Utility & View ---
29. getArtifactBalance(address user, uint256 artifactTypeId) - View function to get a user's balance of a specific artifact type.
30. getArtifactTypeInfo(uint256 artifactTypeId) - View function to get the name of an artifact type.
31. getNodeInfo(uint256 nodeId) - View function to get the details of a node.
32. getCraftingRecipe(uint256 recipeId) - View function to get the details of a crafting recipe.
33. getRiteDefinition(uint256 riteId) - View function to get the details of a rite definition.
34. getSynergyOutcome(uint256 outcomeId) - View function to get the details of a synergy outcome definition.
35. getDecayRates() - View function to get the current essence and artifact decay rates.
36. getEssenceCultivationRate() - View function for the cultivation rate.
37. getTimeSinceLastActivity(address user) - Helper view function to calculate inactivity duration.
38. getTotalRegisteredUsers() - View function for the total number of registered users.
39. getAllNodeIds() - View function returning all registered node IDs.
40. getAllArtifactTypeIds() - View function returning all defined artifact type IDs.
41. getAllCraftingRecipeIds() - View function returning all defined recipe IDs.
42. getAllRiteDefinitionIds() - View function returning all defined rite IDs.
43. getAllSynergyOutcomeIds() - View function returning all defined synergy outcome IDs.
44. isUserRegistered(address user) - View function to check if an address is registered.
45. getUserPendingRiteRewards(address user) - View function to see a user's pending rite rewards.
46. getUserEssenceBoostStatus(address user) - View function to check a user's current essence boost status.

--- Pausability ---
47. pauseContract() - Pauses certain contract functions (admin/owner only).
48. unpauseContract() - Unpauses the contract (admin/owner only).

Total Functions: 48 (Well over the required 20)
*/

contract CryptoEcosystem {
    address public owner;
    address public admin;
    bool public paused;

    uint256 public essenceCultivationRate; // Essence per second of cultivation (if active)
    uint256 public essenceDecayRate;       // Essence per second of inactivity
    uint256 public baseEssenceBoostDuration; // Base duration for boost effects

    // --- Data Structures ---

    struct UserInfo {
        bool isRegistered;
        uint256 essence;
        mapping(uint256 => uint256) artifactBalances;
        uint48 lastEssenceCultivationTime; // Timestamp of last cultivation/activity for growth calculation
        uint48 lastActivityTime;           // Timestamp of last action for decay calculation
        uint48 essenceBoostEndTime;        // Timestamp when essence boost ends
        uint256 essenceBoostMultiplier;   // Multiplier for essence gain/reduction during boost (e.g., 1000 = 1x, 1500 = 1.5x)
        PendingRiteReward[] pendingRiteRewards;
    }

    struct PendingRiteReward {
        uint256 riteId;
        uint256[] rewardArtifactTypes;
        uint256[] rewardArtifactAmounts;
        bool claimed;
    }

    struct NodeInfo {
        uint256 essenceCost;
        uint256[] yieldArtifactTypes;
        uint256[] yieldArtifactAmounts;
    }

    struct ArtifactRecipe {
        uint256 artifactToCraft;
        uint256 essenceCost;
        uint256[] requiredArtifactTypes;
        uint256[] requiredArtifactAmounts;
    }

    struct RiteDefinition {
        uint256 essenceCostThreshold;
        uint256[] rewardArtifactTypes;
        uint256[] rewardArtifactAmounts;
    }

    struct SynergyOutcome {
        uint256 essenceBoost; // Flat essence gain on success
        uint256[] rewardArtifactTypes;
        uint256[] rewardArtifactAmounts;
        uint256 successChance; // Chance out of 10000 (e.g., 5000 = 50%)
    }

    // --- State Mappings ---

    mapping(address => UserInfo) public users;
    mapping(uint256 => NodeInfo) public nodes;
    mapping(uint256 => ArtifactRecipe) public craftingRecipes;
    mapping(uint256 => RiteDefinition) public riteDefinitions;
    mapping(uint256 => SynergyOutcome) public synergyOutcomes;
    mapping(uint256 => string) public artifactNames;
    mapping(uint256 => uint256) public artifactDecayRates; // Decay rate per second for each artifact type

    // --- State Arrays (for enumeration) ---

    address[] public registeredUsers;
    uint256[] public nodeIds;
    uint256[] public artifactTypeIds;
    uint256[] public craftingRecipeIds;
    uint256[] public riteDefinitionIds;
    uint256[] public synergyOutcomeIds;

    // --- Events ---

    event UserRegistered(address indexed user);
    event EssenceCultivated(address indexed user, uint256 amount, uint256 newTotal);
    event EssenceConsumed(address indexed user, uint256 amount, uint256 newTotal, string action);
    event EssenceDecayed(address indexed user, uint256 amount, uint256 newTotal);
    event ArtifactDecayed(address indexed user, uint256 artifactTypeId, uint256 amount, uint256 newTotal);
    event ArtifactDiscovered(address indexed user, uint256 nodeId, uint256 artifactTypeId, uint256 amount);
    event ArtifactTransferred(address indexed from, address indexed to, uint256 artifactTypeId, uint256 amount);
    event ArtifactCrafted(address indexed user, uint256 recipeId, uint256 artifactTypeId, uint256 amount);
    event RitePerformed(address indexed user, uint256 riteId, uint256 essenceSacrificed, uint256 pendingRewardIndex);
    event RiteRewardClaimed(address indexed user, uint256 pendingRewardIndex);
    event SynergyRitualPerformed(address indexed user, bool success, uint256 outcomeId);
    event EssenceBoostApplied(address indexed user, uint48 boostEndTime, uint256 multiplier);
    event NodeAdded(uint256 indexed nodeId);
    event RecipeDefined(uint256 indexed recipeId);
    event RiteDefined(uint256 indexed riteId);
    event SynergyOutcomeDefined(uint256 indexed outcomeId);
    event ArtifactTypeDefined(uint256 indexed artifactTypeId, string name);
    event ContractPaused(address indexed actor);
    event ContractUnpaused(address indexed actor);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin, "Only admin or owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier userRegistered(address user) {
        require(users[user].isRegistered, "User not registered");
        _;
    }

    modifier hasEssence(address user, uint256 amount) {
        require(users[user].essence >= amount, "Insufficient essence");
        _;
    }

    modifier hasArtifact(address user, uint256 artifactTypeId, uint256 amount) {
        require(users[user].artifactBalances[artifactTypeId] >= amount, "Insufficient artifact");
        _;
    }

    // --- Constructor ---

    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin;
        paused = false;

        // Set some initial rates (can be updated by admin)
        essenceCultivationRate = 1; // 1 essence per second cultivated
        essenceDecayRate = 1; // 1 essence per second decayed
        baseEssenceBoostDuration = 3600; // 1 hour
    }

    // --- Admin & Setup Functions ---

    /**
     * @notice Sets or changes the admin address. Only owner can call.
     * @param _admin The address to set as admin.
     */
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Invalid admin address");
        admin = _admin;
    }

    /**
     * @notice Defines a new type of artifact.
     * @param artifactTypeId A unique identifier for the artifact type.
     * @param name The name of the artifact type.
     */
    function defineArtifactType(uint256 artifactTypeId, string memory name) external onlyAdmin {
        require(bytes(artifactNames[artifactTypeId]).length == 0, "Artifact type already defined");
        artifactNames[artifactTypeId] = name;
        artifactTypeIds.push(artifactTypeId);
        emit ArtifactTypeDefined(artifactTypeId, name);
    }

    /**
     * @notice Adds a new node to the ecosystem.
     * @param nodeId A unique identifier for the node.
     * @param essenceCost The essence cost to interact with this node.
     * @param yieldArtifactTypes The types of artifacts yielded by this node.
     * @param yieldArtifactAmounts The corresponding amounts of artifacts yielded.
     */
    function addNode(uint256 nodeId, uint256 essenceCost, uint256[] memory yieldArtifactTypes, uint256[] memory yieldArtifactAmounts) external onlyAdmin {
        require(nodes[nodeId].essenceCost == 0, "Node already exists"); // Simple check if node exists
        require(yieldArtifactTypes.length == yieldArtifactAmounts.length, "Yield arrays mismatch");
        // Basic check for defined artifact types
        for(uint i = 0; i < yieldArtifactTypes.length; i++){
            require(bytes(artifactNames[yieldArtifactTypes[i]]).length > 0, "Undefined yield artifact type");
        }

        nodes[nodeId] = NodeInfo(essenceCost, yieldArtifactTypes, yieldArtifactAmounts);
        nodeIds.push(nodeId);
        emit NodeAdded(nodeId);
    }

    /**
     * @notice Updates an existing node's parameters.
     * @param nodeId The identifier of the node to update.
     * @param essenceCost The new essence cost.
     * @param yieldArtifactTypes The new types of artifacts yielded.
     * @param yieldArtifactAmounts The new corresponding amounts.
     */
    function updateNode(uint256 nodeId, uint256 essenceCost, uint256[] memory yieldArtifactTypes, uint256[] memory yieldArtifactAmounts) external onlyAdmin {
         require(nodes[nodeId].essenceCost > 0, "Node does not exist");
         require(yieldArtifactTypes.length == yieldArtifactAmounts.length, "Yield arrays mismatch");
         for(uint i = 0; i < yieldArtifactTypes.length; i++){
            require(bytes(artifactNames[yieldArtifactTypes[i]]).length > 0, "Undefined yield artifact type");
         }
         nodes[nodeId] = NodeInfo(essenceCost, yieldArtifactTypes, yieldArtifactAmounts);
    }


    /**
     * @notice Defines a new crafting recipe.
     * @param recipeId A unique identifier for the recipe.
     * @param artifactToCraft The type of artifact produced by the recipe.
     * @param essenceCost The essence cost for crafting.
     * @param requiredArtifactTypes The types of artifacts required.
     * @param requiredArtifactAmounts The corresponding amounts of required artifacts.
     */
    function defineCraftingRecipe(uint256 recipeId, uint256 artifactToCraft, uint256 essenceCost, uint256[] memory requiredArtifactTypes, uint256[] memory requiredArtifactAmounts) external onlyAdmin {
        require(craftingRecipes[recipeId].artifactToCraft == 0, "Recipe already exists"); // Simple check
        require(requiredArtifactTypes.length == requiredArtifactAmounts.length, "Requirement arrays mismatch");
        require(bytes(artifactNames[artifactToCraft]).length > 0, "Undefined artifact to craft type");
         for(uint i = 0; i < requiredArtifactTypes.length; i++){
            require(bytes(artifactNames[requiredArtifactTypes[i]]).length > 0, "Undefined required artifact type");
         }

        craftingRecipes[recipeId] = ArtifactRecipe(artifactToCraft, essenceCost, requiredArtifactTypes, requiredArtifactAmounts);
        craftingRecipeIds.push(recipeId);
        emit RecipeDefined(recipeId);
    }

     /**
     * @notice Updates an existing crafting recipe.
     * @param recipeId The identifier of the recipe to update.
     * @param artifactToCraft The new type of artifact produced.
     * @param essenceCost The new essence cost.
     * @param requiredArtifactTypes The new types of artifacts required.
     * @param requiredArtifactAmounts The new corresponding amounts.
     */
    function updateCraftingRecipe(uint256 recipeId, uint256 artifactToCraft, uint256 essenceCost, uint256[] memory requiredArtifactTypes, uint256[] memory requiredArtifactAmounts) external onlyAdmin {
        require(craftingRecipes[recipeId].artifactToCraft > 0, "Recipe does not exist");
        require(requiredArtifactTypes.length == requiredArtifactAmounts.length, "Requirement arrays mismatch");
        require(bytes(artifactNames[artifactToCraft]).length > 0, "Undefined artifact to craft type");
         for(uint i = 0; i < requiredArtifactTypes.length; i++){
            require(bytes(artifactNames[requiredArtifactTypes[i]]).length > 0, "Undefined required artifact type");
         }
        craftingRecipes[recipeId] = ArtifactRecipe(artifactToCraft, essenceCost, requiredArtifactTypes, requiredArtifactAmounts);
    }


    /**
     * @notice Defines a new high-cost essence ritual (rite).
     * @param riteId A unique identifier for the rite.
     * @param essenceCostThreshold The minimum essence cost required for this rite.
     * @param rewardArtifactTypes The types of artifacts awarded upon successful rite completion (claimed later).
     * @param rewardArtifactAmounts The corresponding amounts of reward artifacts.
     */
    function defineRite(uint256 riteId, uint256 essenceCostThreshold, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts) external onlyAdmin {
        require(riteDefinitions[riteId].essenceCostThreshold == 0 && riteDefinitions[riteId].rewardArtifactTypes.length == 0, "Rite already exists"); // Simple check
        require(rewardArtifactTypes.length == rewardArtifactAmounts.length, "Reward arrays mismatch");
         for(uint i = 0; i < rewardArtifactTypes.length; i++){
            require(bytes(artifactNames[rewardArtifactTypes[i]]).length > 0, "Undefined reward artifact type");
         }
        riteDefinitions[riteId] = RiteDefinition(essenceCostThreshold, rewardArtifactTypes, rewardArtifactAmounts);
        riteDefinitionIds.push(riteId);
        emit RiteDefined(riteId);
    }

     /**
     * @notice Updates an existing rite definition.
     * @param riteId The identifier of the rite to update.
     * @param essenceCostThreshold The new minimum essence cost.
     * @param rewardArtifactTypes The new types of reward artifacts.
     * @param rewardArtifactAmounts The new corresponding amounts.
     */
    function updateRite(uint256 riteId, uint256 essenceCostThreshold, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts) external onlyAdmin {
        require(riteDefinitions[riteId].essenceCostThreshold > 0 || riteDefinitions[riteId].rewardArtifactTypes.length > 0, "Rite does not exist");
        require(rewardArtifactTypes.length == rewardArtifactAmounts.length, "Reward arrays mismatch");
         for(uint i = 0; i < rewardArtifactTypes.length; i++){
            require(bytes(artifactNames[rewardArtifactTypes[i]]).length > 0, "Undefined reward artifact type");
         }
        riteDefinitions[riteId] = RiteDefinition(essenceCostThreshold, rewardArtifactTypes, rewardArtifactAmounts);
    }

    /**
     * @notice Defines a possible outcome for a synergy ritual. Multiple outcomes can exist with different chances.
     * @param outcomeId A unique identifier for the synergy outcome.
     * @param essenceBoost A flat essence gain on success.
     * @param rewardArtifactTypes The types of artifacts rewarded on success.
     * @param rewardArtifactAmounts The corresponding amounts of reward artifacts.
     * @param successChance The chance of this outcome occurring (out of 10000).
     */
    function defineSynergyOutcome(uint256 outcomeId, uint256 essenceBoost, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts, uint256 successChance) external onlyAdmin {
        require(synergyOutcomes[outcomeId].successChance == 0 && synergyOutcomes[outcomeId].rewardArtifactTypes.length == 0, "Synergy outcome already exists"); // Simple check
        require(rewardArtifactTypes.length == rewardArtifactAmounts.length, "Reward arrays mismatch");
        require(successChance <= 10000, "Success chance out of bounds (max 10000)");
         for(uint i = 0; i < rewardArtifactTypes.length; i++){
            require(bytes(artifactNames[rewardArtifactTypes[i]]).length > 0, "Undefined reward artifact type");
         }
        synergyOutcomes[outcomeId] = SynergyOutcome(essenceBoost, rewardArtifactTypes, rewardArtifactAmounts, successChance);
        synergyOutcomeIds.push(outcomeId);
        emit SynergyOutcomeDefined(outcomeId);
    }

    /**
     * @notice Updates an existing synergy outcome definition.
     * @param outcomeId The identifier of the outcome to update.
     * @param essenceBoost The new flat essence gain.
     * @param rewardArtifactTypes The new types of reward artifacts.
     * @param rewardArtifactAmounts The new corresponding amounts.
     * @param successChance The new success chance (out of 10000).
     */
     function updateSynergyOutcome(uint256 outcomeId, uint256 essenceBoost, uint256[] memory rewardArtifactTypes, uint256[] memory rewardArtifactAmounts, uint256 successChance) external onlyAdmin {
        require(synergyOutcomes[outcomeId].successChance > 0 || synergyOutcomes[outcomeId].rewardArtifactTypes.length > 0, "Synergy outcome does not exist");
        require(rewardArtifactTypes.length == rewardArtifactAmounts.length, "Reward arrays mismatch");
        require(successChance <= 10000, "Success chance out of bounds (max 10000)");
         for(uint i = 0; i < rewardArtifactTypes.length; i++){
            require(bytes(artifactNames[rewardArtifactTypes[i]]).length > 0, "Undefined reward artifact type");
         }
        synergyOutcomes[outcomeId] = SynergyOutcome(essenceBoost, rewardArtifactTypes, rewardArtifactAmounts, successChance);
     }

    /**
     * @notice Sets the rate at which essence cultivates for active users.
     * @param ratePerUnitTime The rate (e.g., essence per second).
     */
    function setEssenceCultivationRate(uint256 ratePerUnitTime) external onlyAdmin {
        essenceCultivationRate = ratePerUnitTime;
    }

    /**
     * @notice Sets the rate at which essence decays for inactive users.
     * @param ratePerUnitTime The rate (e.g., essence per second).
     */
    function setEssenceDecayRate(uint256 ratePerUnitTime) external onlyAdmin {
        essenceDecayRate = ratePerUnitTime;
    }

     /**
     * @notice Sets the decay rate for a specific artifact type.
     * @param artifactTypeId The type of artifact.
     * @param ratePerUnitTime The rate (e.g., amount per second).
     */
    function setArtifactDecayRate(uint256 artifactTypeId, uint256 ratePerUnitTime) external onlyAdmin {
        require(bytes(artifactNames[artifactTypeId]).length > 0, "Undefined artifact type");
        artifactDecayRates[artifactTypeId] = ratePerUnitTime;
    }

     /**
     * @notice Sets the base duration for essence boost effects applied via rituals/items.
     * @param durationInSeconds The base duration in seconds.
     */
    function setBaseEssenceBoostDuration(uint256 durationInSeconds) external onlyAdmin {
         baseEssenceBoostDuration = durationInSeconds;
     }

    /**
     * @notice Allows owner or admin to withdraw ETH sent to the contract.
     * @param recipient The address to send the ETH to.
     * @param amount The amount of ETH to withdraw (in wei).
     */
    function withdrawFunds(address payable recipient, uint256 amount) external onlyAdmin {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
        emit FundsWithdrawn(recipient, amount);
    }

    // --- User Management Functions ---

    /**
     * @notice Registers a new user in the ecosystem. Provides initial essence.
     */
    function registerUser() external whenNotPaused {
        require(!users[msg.sender].isRegistered, "User already registered");

        users[msg.sender].isRegistered = true;
        users[msg.sender].essence = 100; // Initial essence
        users[msg.sender].lastActivityTime = users[msg.sender].lastEssenceCultivationTime = uint48(block.timestamp);
        users[msg.sender].essenceBoostMultiplier = 1000; // Default multiplier 1x
        registeredUsers.push(msg.sender);

        emit UserRegistered(msg.sender);
    }

    /**
     * @notice Gets the current state of a user.
     * @param user The address of the user.
     * @return UserInfo struct containing essence, artifact balances (partial via mapping), timestamps, etc.
     * @dev Note: Artifact balances mapping within the struct is not directly iterable via this return.
     *      Use getArtifactBalance for specific types or getTotalRegisteredUsers/getAllArtifactTypeIds
     *      to iterate and check all balances if needed off-chain.
     */
    function getUserState(address user) external view userRegistered(user) returns (UserInfo memory) {
         // Cannot return the mapping directly, structure for view function limitation
         // Providing key fields for a snapshot
        UserInfo storage userInfo = users[user];
        return UserInfo({
            isRegistered: true,
            essence: userInfo.essence,
            artifactBalances: userInfo.artifactBalances, // This mapping is not fully returned here
            lastEssenceCultivationTime: userInfo.lastEssenceCultivationTime,
            lastActivityTime: userInfo.lastActivityTime,
            essenceBoostEndTime: userInfo.essenceBoostEndTime,
            essenceBoostMultiplier: userInfo.essenceBoostMultiplier,
            pendingRiteRewards: userInfo.pendingRiteRewards // Returns the dynamic array of pending rewards
        });
    }

    // --- Core Resource & Interaction ---

    /**
     * @notice Allows a user to cultivate essence based on time since last cultivation/activity.
     * Applies decay first, then cultivation. Applies essence boost multiplier if active.
     */
    function cultivateEssence() external userRegistered(msg.sender) whenNotPaused {
        // Apply decay before cultivation
        checkAndApplyDecay(msg.sender);

        UserInfo storage user = users[msg.sender];
        uint256 timeElapsed = block.timestamp - user.lastEssenceCultivationTime;

        if (timeElapsed > 0) {
            uint256 cultivatedAmount = (timeElapsed * essenceCultivationRate * user.essenceBoostMultiplier) / 1000; // Apply boost
             // Prevent overflow, cap increase
            uint256 maxIncrease = type(uint256).max - user.essence;
            cultivatedAmount = cultivatedAmount > maxIncrease ? maxIncrease : cultivatedAmount;

            user.essence += cultivatedAmount;
            user.lastEssenceCultivationTime = uint48(block.timestamp);
            user.lastActivityTime = uint48(block.timestamp); // Activity also counts as cultivation update

            if (cultivatedAmount > 0) {
                 emit EssenceCultivated(msg.sender, cultivatedAmount, user.essence);
            }
        }
    }

    /**
     * @notice Internal function to safely consume essence from a user.
     * Assumes hasEssence modifier check has passed.
     * @param user The address of the user.
     * @param amount The amount of essence to consume.
     * @param action A string describing the action for logging.
     */
    function _consumeEssence(address user, uint256 amount, string memory action) internal {
        UserInfo storage userInfo = users[user];
        userInfo.essence -= amount;
        emit EssenceConsumed(user, amount, userInfo.essence, action);
    }

    /**
     * @notice User interacts with a node to discover artifacts. Consumes essence.
     * Applies decay first. Applies essence boost multiplier to cost.
     * @param nodeId The ID of the node to interact with.
     */
    function discoverArtifact(uint256 nodeId) external userRegistered(msg.sender) whenNotPaused {
        // Apply decay first
        checkAndApplyDecay(msg.sender);

        NodeInfo storage node = nodes[nodeId];
        require(node.essenceCost > 0 || node.yieldArtifactTypes.length > 0, "Invalid node ID"); // Check if node exists and is valid

        UserInfo storage user = users[msg.sender];
        uint256 effectiveEssenceCost = (node.essenceCost * 1000) / user.essenceBoostMultiplier; // Apply boost (lower cost)
        require(user.essence >= effectiveEssenceCost, "Insufficient essence to interact with node");

        _consumeEssence(msg.sender, effectiveEssenceCost, string(abi.encodePacked("Node Interaction ", Strings.toString(nodeId))));

        // Add artifacts to user's balance
        for (uint i = 0; i < node.yieldArtifactTypes.length; i++) {
            uint256 artifactType = node.yieldArtifactTypes[i];
            uint256 amount = node.yieldArtifactAmounts[i];
            user.artifactBalances[artifactType] += amount;
            emit ArtifactDiscovered(msg.sender, nodeId, artifactType, amount);
        }

        user.lastActivityTime = uint48(block.timestamp);
    }

     /**
     * @notice Allows a user to transfer artifacts to another user.
     * @param recipient The address of the recipient.
     * @param artifactTypeId The type of artifact to transfer.
     * @param amount The amount to transfer.
     */
    function transferArtifact(address recipient, uint256 artifactTypeId, uint256 amount) external userRegistered(msg.sender) whenNotPaused hasArtifact(msg.sender, artifactTypeId, amount) {
        require(recipient != address(0), "Cannot send to zero address");
        require(users[recipient].isRegistered, "Recipient not registered");
        require(amount > 0, "Amount must be greater than zero");
         require(bytes(artifactNames[artifactTypeId]).length > 0, "Undefined artifact type");

        // No decay check on transfer, decay applies based on *last activity* on the sender's account
        // checkAndApplyDecay(msg.sender); // Can optionally uncomment if transfer should trigger decay check

        users[msg.sender].artifactBalances[artifactTypeId] -= amount;
        users[recipient].artifactBalances[artifactTypeId] += amount;

        emit ArtifactTransferred(msg.sender, recipient, artifactTypeId, amount);

        // Update activity for sender (transferring is an activity)
        users[msg.sender].lastActivityTime = uint48(block.timestamp);
         // Optional: Update activity for recipient if receiving counts
        // users[recipient].lastActivityTime = uint48(block.timestamp);
    }

    /**
     * @notice User crafts an artifact using a defined recipe. Consumes required artifacts and essence.
     * Applies decay first. Applies essence boost multiplier to essence cost.
     * @param recipeId The ID of the crafting recipe to use.
     */
    function craftArtifact(uint256 recipeId) external userRegistered(msg.sender) whenNotPaused {
        // Apply decay first
        checkAndApplyDecay(msg.sender);

        ArtifactRecipe storage recipe = craftingRecipes[recipeId];
        require(recipe.artifactToCraft > 0, "Invalid recipe ID"); // Check if recipe exists

        UserInfo storage user = users[msg.sender];
        uint256 effectiveEssenceCost = (recipe.essenceCost * 1000) / user.essenceBoostMultiplier; // Apply boost
        require(user.essence >= effectiveEssenceCost, "Insufficient essence for crafting");

        // Check and consume required artifacts
        for (uint i = 0; i < recipe.requiredArtifactTypes.length; i++) {
            uint256 reqType = recipe.requiredArtifactTypes[i];
            uint256 reqAmount = recipe.requiredArtifactAmounts[i];
            require(user.artifactBalances[reqType] >= reqAmount, "Insufficient required artifact");
            user.artifactBalances[reqType] -= reqAmount;
        }

        _consumeEssence(msg.sender, effectiveEssenceCost, string(abi.encodePacked("Crafting ", Strings.toString(recipeId))));

        // Mint the crafted artifact
        user.artifactBalances[recipe.artifactToCraft] += 1; // Assume 1 artifact is crafted per recipe execution

        emit ArtifactCrafted(msg.sender, recipeId, recipe.artifactToCraft, 1);

        user.lastActivityTime = uint48(block.timestamp);
    }

    /**
     * @notice User performs a high-cost essence ritual for a potential reward.
     * The reward is not granted immediately but added to pending rewards, claimable later.
     * Applies decay first.
     * @param riteId The ID of the rite definition to perform.
     * @param essenceSacrificeAmount The amount of essence the user chooses to sacrifice (must meet threshold).
     */
    function performEssenceRite(uint256 riteId, uint256 essenceSacrificeAmount) external userRegistered(msg.sender) whenNotPaused {
         // Apply decay first
        checkAndApplyDecay(msg.sender);

        RiteDefinition storage rite = riteDefinitions[riteId];
        require(rite.essenceCostThreshold > 0 || rite.rewardArtifactTypes.length > 0, "Invalid rite ID"); // Check if rite exists
        require(essenceSacrificeAmount >= rite.essenceCostThreshold, "Essence sacrifice below threshold");

        UserInfo storage user = users[msg.sender];
        require(user.essence >= essenceSacrificeAmount, "Insufficient essence for sacrifice");

        _consumeEssence(msg.sender, essenceSacrificeAmount, string(abi.encodePacked("Essence Rite ", Strings.toString(riteId))));

        // Add reward to pending rewards list
        user.pendingRiteRewards.push(
            PendingRiteReward({
                riteId: riteId,
                rewardArtifactTypes: rite.rewardArtifactTypes,
                rewardArtifactAmounts: rite.rewardArtifactAmounts,
                claimed: false
            })
        );

        emit RitePerformed(msg.sender, riteId, essenceSacrificeAmount, user.pendingRiteRewards.length - 1);

        user.lastActivityTime = uint48(block.timestamp);
    }

    /**
     * @notice Allows a user to claim a pending reward from a previously performed rite.
     * @param pendingRiteIndex The index in the user's pendingRiteRewards array.
     */
    function claimRiteReward(uint256 pendingRiteIndex) external userRegistered(msg.sender) whenNotPaused {
        UserInfo storage user = users[msg.sender];
        require(pendingRiteIndex < user.pendingRiteRewards.length, "Invalid pending rite index");
        PendingRiteReward storage pending = user.pendingRiteRewards[pendingRiteIndex];
        require(!pending.claimed, "Reward already claimed");

        // Distribute rewards
        for (uint i = 0; i < pending.rewardArtifactTypes.length; i++) {
            uint256 artifactType = pending.rewardArtifactTypes[i];
            uint256 amount = pending.rewardArtifactAmounts[i];
            user.artifactBalances[artifactType] += amount;
            // No specific event for claiming individual artifacts, RiteRewardClaimed covers it
        }

        pending.claimed = true; // Mark as claimed

        emit RiteRewardClaimed(msg.sender, pendingRiteIndex);

        user.lastActivityTime = uint48(block.timestamp);
    }

    /**
     * @notice User performs a synergy ritual by consuming specific artifacts for a chance at a unique outcome.
     * Applies decay first.
     * Introduces pseudo-randomness based on block data.
     * @param artifactTypes The types of artifacts to consume for the ritual.
     * @param amounts The corresponding amounts to consume.
     */
    function performSynergyRitual(uint256[] memory artifactTypes, uint256[] memory amounts) external userRegistered(msg.sender) whenNotPaused {
        require(artifactTypes.length > 0, "Must consume artifacts for ritual");
        require(artifactTypes.length == amounts.length, "Artifact arrays mismatch");

         // Apply decay first
        checkAndApplyDecay(msg.sender);

        UserInfo storage user = users[msg.sender];

        // Check and consume required artifacts
        for (uint i = 0; i < artifactTypes.length; i++) {
            uint256 artType = artifactTypes[i];
            uint256 amount = amounts[i];
            require(amount > 0, "Amount must be greater than zero");
            require(bytes(artifactNames[artType]).length > 0, "Undefined artifact type");
            require(user.artifactBalances[artType] >= amount, "Insufficient artifact for ritual");
            user.artifactBalances[artType] -= amount;
        }

        // Determine outcome based on pseudo-randomness and defined chances
        // WARNING: Blockchain randomness is insecure for high-value outcomes.
        // This is for demonstration. A real application might use Chainlink VRF or similar.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number))) % 10000;
        bool success = false;
        uint256 triggeredOutcomeId = 0;

        for (uint i = 0; i < synergyOutcomeIds.length; i++) {
            uint256 outcomeId = synergyOutcomeIds[i];
            SynergyOutcome storage outcome = synergyOutcomes[outcomeId];

            // Check if this outcome is triggered based on chance
            if (randomNumber < outcome.successChance) {
                // Apply outcome effects
                user.essence += outcome.essenceBoost;
                for (uint j = 0; j < outcome.rewardArtifactTypes.length; j++) {
                    user.artifactBalances[outcome.rewardArtifactTypes[j]] += outcome.rewardArtifactAmounts[j];
                }
                success = true;
                triggeredOutcomeId = outcomeId;
                // In a real scenario, you might break here if only one outcome can trigger,
                // or handle multiple potential outcomes if chances sum > 10000
                break; // For simplicity, first triggered outcome wins
            }
             // Adjust randomNumber for subsequent checks if desired outcomes are mutually exclusive
            randomNumber -= outcome.successChance;
             if (randomNumber < 0) randomNumber = 0; // Should not happen if chances sum <= 10000
        }

        emit SynergyRitualPerformed(msg.sender, success, triggeredOutcomeId);

        user.lastActivityTime = uint48(block.timestamp);
    }

     /**
     * @notice User consumes specific artifacts to gain a temporary boost to essence mechanics.
     * Applies decay first. Boost duration is cumulative or reset, depending on logic.
     * Let's make it additive to the end time.
     * @param artifactTypes The types of artifacts to consume for the boost.
     * @param amounts The corresponding amounts to consume.
     */
     function applyEssenceBoost(uint256[] memory artifactTypes, uint256[] memory amounts) external userRegistered(msg.sender) whenNotPaused {
        require(artifactTypes.length > 0, "Must consume artifacts for boost");
        require(artifactTypes.length == amounts.length, "Artifact arrays mismatch");

        // Apply decay first
        checkAndApplyDecay(msg.sender);

        UserInfo storage user = users[msg.sender];

        // Check and consume required artifacts (admin defines which artifacts give boost and multiplier/duration)
        // For simplicity here, let's assume any consumed artifact type adds to the boost duration.
        // A more complex version would map artifact types to specific boosts/durations/multipliers.
        // Let's make it simpler: define *one* specific "Boost Catalyst" artifact type.
        // Admin would need a function like `setBoostCatalyst(uint256 artifactTypeId, uint256 durationPerUnit, uint256 multiplier)`.
        // For this example, let's use a placeholder artifact type ID (e.g., 999) and a fixed effect.
        uint256 BOOST_CATALYST_ARTIFACT_TYPE = 999; // Placeholder ID
        uint256 durationAddedPerUnit = baseEssenceBoostDuration; // Example: 1 base duration per catalyst consumed
        uint256 boostMultiplier = 2000; // Example: 2x essence effect (2000/1000)

        bool catalystFound = false;
        for (uint i = 0; i < artifactTypes.length; i++) {
            uint256 artType = artifactTypes[i];
            uint256 amount = amounts[i];
            require(amount > 0, "Amount must be greater than zero");
            require(bytes(artifactNames[artType]).length > 0, "Undefined artifact type");
            require(user.artifactBalances[artType] >= amount, "Insufficient artifact for boost");

            if (artType == BOOST_CATALYST_ARTIFACT_TYPE) {
                catalystFound = true;
                 user.artifactBalances[artType] -= amount; // Consume catalyst
                 // Add duration for each catalyst consumed
                 uint48 currentBoostEndTime = user.essenceBoostEndTime < block.timestamp ? uint48(block.timestamp) : user.essenceBoostEndTime;
                 user.essenceBoostEndTime = currentBoostEndTime + uint48(amount * durationAddedPerUnit);
                 user.essenceBoostMultiplier = boostMultiplier; // Set/Update multiplier

            } else {
                 // Optionally consume other artifacts without giving boost, or just require catalyst
                 user.artifactBalances[artType] -= amount; // Consume other artifacts if part of recipe
            }
        }

        require(catalystFound, "Must consume at least one Boost Catalyst artifact (type 999)");
         // Ensure multiplier resets after boost ends (check done in functions using boost)
        // Ensure multiplier is minimum 1000 (1x) if boost ends
        if (user.essenceBoostEndTime < block.timestamp) {
             user.essenceBoostMultiplier = 1000; // Reset if already expired
        }


        emit EssenceBoostApplied(msg.sender, user.essenceBoostEndTime, user.essenceBoostMultiplier);

        user.lastActivityTime = uint48(block.timestamp);
     }


    // --- Dynamic System Functions (Decay) ---

    /**
     * @notice Public function that anyone can call to check and apply decay for a user.
     * This encourages the community to prune inactive users.
     * Decay applies to Essence and Artifacts based on time since last activity.
     * Only applies decay if decay is due (time elapsed > 0).
     * @param user The address of the user to check.
     */
    function checkAndApplyDecay(address user) public userRegistered(user) {
        UserInfo storage userInfo = users[user];
        uint256 timeElapsed = block.timestamp - userInfo.lastActivityTime;

        if (timeElapsed > 0) {
            // --- Apply Essence Decay ---
            uint256 essenceLoss = (timeElapsed * essenceDecayRate);
             // Apply reverse boost effect to decay if boost is active
             if (userInfo.essenceBoostEndTime >= block.timestamp) {
                 essenceLoss = (essenceLoss * 1000) / userInfo.essenceBoostMultiplier; // Higher multiplier means less decay
             }

            uint256 effectiveEssenceLoss = essenceLoss > userInfo.essence ? userInfo.essence : essenceLoss;
            if (effectiveEssenceLoss > 0) {
                userInfo.essence -= effectiveEssenceLoss;
                emit EssenceDecayed(user, effectiveEssenceLoss, userInfo.essence);
            }

            // --- Apply Artifact Decay ---
            // Iterate through all known artifact types
            for(uint i = 0; i < artifactTypeIds.length; i++) {
                uint256 artifactTypeId = artifactTypeIds[i];
                uint256 artifactDecayRatePerSecond = artifactDecayRates[artifactTypeId]; // Defaults to 0 if not set
                if (artifactDecayRatePerSecond > 0 && userInfo.artifactBalances[artifactTypeId] > 0) {
                    uint256 artifactLoss = (timeElapsed * artifactDecayRatePerSecond);
                    // Apply reverse boost effect to artifact decay if boost is active
                    if (userInfo.essenceBoostEndTime >= block.timestamp) {
                        artifactLoss = (artifactLoss * 1000) / userInfo.essenceBoostMultiplier; // Higher multiplier means less decay
                    }

                     uint256 effectiveArtifactLoss = artifactLoss > userInfo.artifactBalances[artifactTypeId] ? userInfo.artifactBalances[artifactTypeId] : artifactLoss;

                    if (effectiveArtifactLoss > 0) {
                        userInfo.artifactBalances[artifactTypeId] -= effectiveArtifactLoss;
                        emit ArtifactDecayed(user, artifactTypeId, effectiveArtifactLoss, userInfo.artifactBalances[artifactTypeId]);
                    }
                }
            }

            // Update last activity time after decay is applied
            // This ensures decay time is based on the *actual* duration of inactivity
            userInfo.lastActivityTime = uint48(block.timestamp);

             // Reset boost multiplier if boost expired during inactivity
             if (userInfo.essenceBoostEndTime < block.timestamp) {
                 userInfo.essenceBoostMultiplier = 1000;
             }
        }
    }


    // --- Utility & View Functions ---

     /**
     * @notice Gets a user's balance of a specific artifact type.
     * @param user The address of the user.
     * @param artifactTypeId The type of artifact.
     * @return The balance of the artifact.
     */
    function getArtifactBalance(address user, uint256 artifactTypeId) public view userRegistered(user) returns (uint256) {
        return users[user].artifactBalances[artifactTypeId];
    }

     /**
     * @notice Gets the name of an artifact type.
     * @param artifactTypeId The type of artifact.
     * @return The name of the artifact type.
     */
    function getArtifactTypeInfo(uint256 artifactTypeId) public view returns (string memory) {
        return artifactNames[artifactTypeId];
    }

    /**
     * @notice Gets the details of a node.
     * @param nodeId The ID of the node.
     * @return NodeInfo struct.
     */
    function getNodeInfo(uint256 nodeId) public view returns (NodeInfo memory) {
        return nodes[nodeId];
    }

    /**
     * @notice Gets the details of a crafting recipe.
     * @param recipeId The ID of the recipe.
     * @return ArtifactRecipe struct.
     */
    function getCraftingRecipe(uint256 recipeId) public view returns (ArtifactRecipe memory) {
        return craftingRecipes[recipeId];
    }

    /**
     * @notice Gets the details of a rite definition.
     * @param riteId The ID of the rite.
     * @return RiteDefinition struct.
     */
    function getRiteDefinition(uint256 riteId) public view returns (RiteDefinition memory) {
        return riteDefinitions[riteId];
    }

    /**
     * @notice Gets the details of a synergy outcome definition.
     * @param outcomeId The ID of the outcome.
     * @return SynergyOutcome struct.
     */
    function getSynergyOutcome(uint256 outcomeId) public view returns (SynergyOutcome memory) {
        return synergyOutcomes[outcomeId];
    }

    /**
     * @notice Gets the current decay rates.
     * @return essenceRate Essence decay rate per second.
     * @return artifactRates Mapping of artifact type ID to decay rate per second (Note: Mapping not fully returned, needs iteration off-chain).
     */
    function getDecayRates() public view returns (uint256 essenceRate, mapping(uint256 => uint256) storage artifactRates) {
        // Cannot return mapping directly. This function signature is for demonstration,
        // in practice, you'd need separate functions for each artifact type or return an array
        // if artifactTypeIds array was used to build a return struct/array.
        // Returning storage mapping is not possible for external calls this way.
        // A practical implementation might return essenceRate and require calling getArtifactDecayRate(typeId) for each type.
         revert("Cannot return mapping directly. Use getEssenceDecayRate and getArtifactDecayRate(typeId)");
    }

     /**
     * @notice Gets the essence decay rate.
     * @return The essence decay rate per second.
     */
    function getEssenceDecayRate() public view returns (uint256) {
        return essenceDecayRate;
    }

     /**
     * @notice Gets the decay rate for a specific artifact type.
     * @param artifactTypeId The type of artifact.
     * @return The decay rate per second for the artifact type.
     */
     function getArtifactDecayRate(uint256 artifactTypeId) public view returns (uint256) {
         require(bytes(artifactNames[artifactTypeId]).length > 0, "Undefined artifact type");
         return artifactDecayRates[artifactTypeId];
     }


    /**
     * @notice Gets the essence cultivation rate.
     * @return The cultivation rate per second.
     */
    function getEssenceCultivationRate() public view returns (uint256) {
        return essenceCultivationRate;
    }

     /**
     * @notice Helper view function to calculate time since last activity for a user.
     * @param user The address of the user.
     * @return The time elapsed in seconds.
     */
    function getTimeSinceLastActivity(address user) public view userRegistered(user) returns (uint256) {
        return block.timestamp - users[user].lastActivityTime;
    }

    /**
     * @notice Gets the total number of registered users.
     * @return The count of registered users.
     */
    function getTotalRegisteredUsers() public view returns (uint256) {
        return registeredUsers.length;
    }

     /**
     * @notice Gets all registered node IDs.
     * @return An array of node IDs.
     */
    function getAllNodeIds() public view returns (uint256[] memory) {
        return nodeIds;
    }

     /**
     * @notice Gets all defined artifact type IDs.
     * @return An array of artifact type IDs.
     */
    function getAllArtifactTypeIds() public view returns (uint256[] memory) {
        return artifactTypeIds;
    }

     /**
     * @notice Gets all defined crafting recipe IDs.
     * @return An array of recipe IDs.
     */
    function getAllCraftingRecipeIds() public view returns (uint256[] memory) {
        return craftingRecipeIds;
    }

    /**
     * @notice Gets all defined rite definition IDs.
     * @return An array of rite IDs.
     */
    function getAllRiteDefinitionIds() public view returns (uint256[] memory) {
        return riteDefinitionIds;
    }

     /**
     * @notice Gets all defined synergy outcome IDs.
     * @return An array of synergy outcome IDs.
     */
    function getAllSynergyOutcomeIds() public view returns (uint256[] memory) {
        return synergyOutcomeIds;
    }

     /**
     * @notice Checks if an address is a registered user.
     * @param user The address to check.
     * @return True if registered, false otherwise.
     */
     function isUserRegistered(address user) public view returns (bool) {
         return users[user].isRegistered;
     }

     /**
     * @notice Gets a user's pending rite rewards.
     * @param user The address of the user.
     * @return An array of PendingRiteReward structs.
     */
     function getUserPendingRiteRewards(address user) public view userRegistered(user) returns (PendingRiteReward[] memory) {
         return users[user].pendingRiteRewards;
     }

    /**
     * @notice Gets a user's current essence boost status.
     * @param user The address of the user.
     * @return boostEndTime The timestamp when the boost ends.
     * @return boostMultiplier The current boost multiplier (1000 = 1x).
     */
     function getUserEssenceBoostStatus(address user) public view userRegistered(user) returns (uint48 boostEndTime, uint256 boostMultiplier) {
         UserInfo storage userInfo = users[user];
         // Return default (no boost) if expired
         if (userInfo.essenceBoostEndTime < block.timestamp) {
             return (0, 1000);
         }
         return (userInfo.essenceBoostEndTime, userInfo.essenceBoostMultiplier);
     }


    // --- Pausability ---

    /**
     * @notice Pauses the contract, preventing key user actions.
     * Only owner or admin can call.
     */
    function pauseContract() external onlyAdmin {
        require(!paused, "Contract is already paused");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing user actions again.
     * Only owner or admin can call.
     */
    function unpauseContract() external onlyAdmin {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // Utility library for uint256 to string conversion (for logging/debugging)
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Interconnected Resources & Actions:** Essence and Artifacts are not just standalone tokens. Essence is *consumed* for actions (`discoverArtifact`, `craftArtifact`, `performEssenceRite`), and Artifacts are *required* for crafting and synergy, and *found* at nodes by spending essence. This creates a loop.
2.  **Dynamic Resources (Cultivation & Decay):** Essence and Artifacts aren't static. They grow with activity/time (Essence Cultivation) but also shrink with inactivity (Decay). This encourages active participation and resource management. The `checkAndApplyDecay` function being public allows anyone to trigger decay for an inactive user, potentially as a griefing vector or a community maintenance task.
3.  **Essence Boost:** Introducing a temporary buff (`applyEssenceBoost`) that alters core mechanics (cultivation rate, consumption/decay cost) adds a strategic layer. Users might save specific artifacts for key moments or challenges.
4.  **Rituals & Synergy (Chance Outcomes):** `performEssenceRite` and `performSynergyRitual` add high-risk, high-reward elements and introduce *chance* into the ecosystem using pseudo-randomness (with the standard caveat about blockchain randomness). Synergy rituals, in particular, are designed for potentially unpredictable positive outcomes. Rites offer deterministic rewards *if* the sacrifice threshold is met, but the act is costly.
5.  **User-Triggered Decay:** While standard ERC contracts don't have decay, making decay callable by *anyone* incentivizes the network to clean up inactive users or penalize competitors.
6.  **Pending Rewards:** For the Rite mechanic, making rewards *pending* and requiring a separate `claimRiteReward` step is common in complex game/DeFi contracts (like yield farming claims) and adds a state management layer.
7.  **Role-Based Access (Owner/Admin):** Differentiating between `owner` and `admin` allows for more granular control over ecosystem parameters without giving full ownership power.
8.  **Pausability:** Essential for complex systems to halt operations during upgrades or critical issues.

This contract provides a framework for building a sophisticated on-chain game or economic simulation, moving beyond simple token transfers or NFT ownership into resource management, dynamic state changes, and strategic interaction with the environment (Nodes) and other users (Crafting inputs/outputs, potentially future trading/gifting mechanics which are partially implemented). The inclusion of decay, cultivation, boosts, and chance outcomes adds layers of complexity and potential for interesting gameplay loops.