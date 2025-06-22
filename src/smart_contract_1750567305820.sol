Okay, here is a smart contract called `ChronosForge`. It's designed as a decentralized system where users (Forgemasters) earn "Essence" (a fungible resource/token), gain "Knowledge" (non-transferable reputation/skill points), upgrade their personal "Forge" (user state/level), and craft unique "Artifacts" (simulated NFTs) based on their progression.

It incorporates concepts like:
*   **Resource Management:** Two distinct resources (Essence, Knowledge).
*   **Progression:** User-specific level/state (`Forge`).
*   **Time-Based Mechanics:** Essence claims and daily tasks with cooldowns.
*   **Staking:** Locking Essence for potential future benefits (simple staking implemented).
*   **NFT Minting Logic:** Requirements based on user state (Forge level, Knowledge, Essence).
*   **Non-Transferable Reputation:** `Knowledge` cannot be sent to others.
*   **Action Delegation:** Users can delegate the ability to perform certain actions (like crafting) to another address.
*   **Dynamic Parameters:** Admin controls over rates, costs, etc.
*   **Random Events:** Admin-triggered discovery events with variable rewards.
*   **System Pause:** Global pause mechanism.

It aims to combine elements often seen in decentralized games, reputation systems, and resource management protocols without directly copying any single one.

**Outline:**

1.  **Contract Information:** SPDX License, Pragma.
2.  **State Variables:**
    *   Ownership/Admin
    *   System State (Paused, parameters)
    *   Essence Token Data (Total Supply, name/symbol implied)
    *   User Data (Mapping address to Forge state, Essence balance, Knowledge, Staked Essence, last claim time, last daily task time, action delegatee, owned artifact IDs)
    *   Forge Upgrade Costs
    *   Artifact Type Data
    *   Artifact Counter
3.  **Structs:**
    *   `UserForgeData`: Stores user-specific state (level, knowledge, essence, staking, cooldowns, delegatee, artifact IDs).
    *   `ForgeUpgradeCost`: Stores costs for a specific forge level.
    *   `ArtifactTypeData`: Stores requirements and costs for crafting an artifact type.
4.  **Events:** Signify important state changes.
5.  **Modifiers:** Access control and state checks.
6.  **Functions (Grouped by purpose):**
    *   **Admin/Setup:** Constructor, Pause/Unpause, Admin Role Management, Parameter Updates (Mining Rate, Upgrade Costs, Artifact Types), Admin Grant/Decay Knowledge, Admin Trigger Event.
    *   **User Core Actions:** Initialize Forge, Claim Essence, Upgrade Forge, Craft Artifact, Stake Essence, Unstake Essence, Burn Essence, Perform Daily Task, Delegate Actions, Revoke Delegation.
    *   **View/Query Functions:** Get User Data, Get Parameters, Check Eligibility, Get Counts/Totals.

**Function Summary:**

*   `constructor()`: Initializes the contract owner and sets initial system parameters.
*   `setSystemPaused(bool _paused)`: Allows the owner to pause or unpause core system functions.
*   `grantAdminRole(address admin)`: Grants administrative privileges to an address. Admins can manage certain system parameters and trigger specific events.
*   `revokeAdminRole(address admin)`: Revokes administrative privileges from an address.
*   `updateEssenceMiningRate(uint256 newRatePerSecondPerLevel)`: Sets the rate at which Essence can be claimed per second per Forge level. (Admin only)
*   `updateForgeUpgradeCosts(uint256 level, uint256 essenceCost, uint256 knowledgeCost)`: Sets the Essence and Knowledge required to upgrade to a specific Forge `level`. (Admin only)
*   `updateArtifactTypeData(uint256 typeId, string calldata name, uint256 essenceCost, uint256 knowledgeRequired, uint256 forgeLevelRequired, uint64 craftingCooldown)`: Defines or updates an artifact type, including costs, requirements, and crafting cooldown. (Admin only)
*   `adminGrantKnowledge(address user, uint256 amount)`: Adds Knowledge points to a user's profile. (Admin only, simulating rewards)
*   `adminDecayKnowledge(address user, uint256 amount)`: Removes Knowledge points from a user's profile. (Admin only, simulating decay or penalties)
*   `adminTriggerDiscoveryEvent(address user)`: Triggers a simulated random discovery event for a user, potentially granting rewards based on their Forge level. (Admin only)
*   `initializeForgeForUser()`: Allows a user to create their initial Forge profile in the system. Must be called only once per user.
*   `claimEssence()`: Allows a user to claim accumulated Essence based on the time elapsed since the last claim, their Forge level, and the current mining rate.
*   `upgradeForge()`: Allows a user to upgrade their Forge level by spending the required Essence and Knowledge.
*   `craftArtifact(uint256 artifactTypeId)`: Allows a user (or their delegatee) to craft a specific type of artifact by paying the Essence cost and meeting Knowledge, Forge Level, and cooldown requirements. Mints a simulated NFT ID.
*   `stakeEssence(uint256 amount)`: Allows a user to lock their Essence within the system.
*   `unstakeEssence(uint256 amount)`: Allows a user to withdraw staked Essence. (Basic version, could add lock-up period logic).
*   `burnEssence(uint256 amount)`: Allows a user to permanently destroy their Essence.
*   `performDailyTask()`: Allows a user to perform a task once every 24 hours to earn a small reward (e.g., fixed Essence/Knowledge).
*   `delegateActionPermission(address delegatee)`: Allows a user to delegate the permission to call `upgradeForge` and `craftArtifact` on their behalf to another address.
*   `revokeActionPermissionDelegate()`: Allows a user to remove the currently set delegatee.
*   `getForgeData(address user)`: (View) Returns the Forge level, Knowledge, last claim time, last daily task time, and action delegatee for a user.
*   `getEssenceBalance(address user)`: (View) Returns the user's current Essence balance.
*   `getKnowledgeAmount(address user)`: (View) Returns the user's current Knowledge points.
*   `getArtifactTypeData(uint256 typeId)`: (View) Returns the data associated with a specific artifact type.
*   `getSystemState()`: (View) Returns core system parameters like mining rate, pause status, total essence supply.
*   `getUserStakedEssence(address user)`: (View) Returns the amount of Essence a user has staked.
*   `isSystemPaused()`: (View) Checks if the system is currently paused.
*   `hasAdminRole(address user)`: (View) Checks if an address has admin privileges.
*   `checkCraftingEligibility(address user, uint256 artifactTypeId)`: (View) Checks if a user meets all the requirements (Essence, Knowledge, Forge Level, Cooldown) to craft a specific artifact type.
*   `getActionDelegatee(address user)`: (View) Returns the address currently delegated to perform actions for the user.
*   `getUserArtifactIds(address user)`: (View) Returns the list of artifact IDs owned by a user.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ChronosForge Smart Contract
// A decentralized system for user progression, resource management,
// and crafting unique assets (Artifacts) based on in-game activities.
// Users are "Forgemasters" who accumulate "Essence" (fungible resource),
// gain "Knowledge" (non-transferable reputation), upgrade their "Forge"
// (personal level/state), and craft "Artifacts" (simulated NFTs).

// Outline:
// 1. Contract Information (License, Pragma)
// 2. State Variables (Ownership, Parameters, User Data, Artifacts)
// 3. Structs (UserForgeData, ForgeUpgradeCost, ArtifactTypeData)
// 4. Events (State Changes, Actions)
// 5. Modifiers (Access Control, State Checks)
// 6. Functions
//    - Admin/Setup: constructor, setSystemPaused, grantAdminRole, revokeAdminRole,
//                     updateEssenceMiningRate, updateForgeUpgradeCosts, updateArtifactTypeData,
//                     adminGrantKnowledge, adminDecayKnowledge, adminTriggerDiscoveryEvent
//    - User Core Actions: initializeForgeForUser, claimEssence, upgradeForge, craftArtifact,
//                         stakeEssence, unstakeEssence, burnEssence, performDailyTask,
//                         delegateActionPermission, revokeActionPermissionDelegate
//    - View/Query: getForgeData, getEssenceBalance, getKnowledgeAmount, getArtifactTypeData,
//                  getSystemState, getUserStakedEssence, isSystemPaused, hasAdminRole,
//                  checkCraftingEligibility, getActionDelegatee, getUserArtifactIds

contract ChronosForge {

    address public owner;
    mapping(address => bool) public admins;
    bool public systemPaused = false;

    // --- Parameters ---
    uint256 public essenceMiningRatePerSecondPerLevel; // How much essence is mined per sec per forge level
    uint64 public dailyTaskCooldown = 24 * 60 * 60; // 24 hours in seconds
    uint256 public dailyTaskEssenceReward = 50;
    uint256 public dailyTaskKnowledgeReward = 5;

    // --- Token / Resource State ---
    uint256 private _totalSupplyEssence;
    mapping(address => uint256) public essenceBalances;
    mapping(address => uint256) public stakedEssence; // Basic staking tracking

    // --- User Progression State ---
    struct UserForgeData {
        bool initialized;
        uint256 level; // Forge Level
        uint256 knowledge; // Non-transferable reputation/skill points
        uint64 lastEssenceClaimTime;
        uint64 lastDailyTaskTime;
        address actionDelegatee; // Address allowed to perform craft/upgrade for this user
        uint256[] ownedArtifactIds; // List of artifact IDs owned by the user
        mapping(uint256 => uint64) artifactCraftCooldowns; // Cooldown for crafting specific artifact types
    }
    mapping(address => UserForgeData) public userForges;

    // --- Upgrade Costs ---
    struct ForgeUpgradeCost {
        uint256 essenceCost;
        uint256 knowledgeCost;
    }
    mapping(uint256 => ForgeUpgradeCost) public forgeUpgradeCosts; // Maps level to cost to REACH that level

    // --- Artifact Data ---
    struct ArtifactTypeData {
        string name;
        uint256 essenceCost;
        uint256 knowledgeRequired;
        uint256 forgeLevelRequired;
        uint64 craftingCooldown; // Cooldown after crafting this specific type
        bool exists; // To check if the typeId is defined
    }
    mapping(uint256 => ArtifactTypeData) public artifactTypes;
    uint256 public nextArtifactId = 1; // Simple counter for unique artifact IDs

    // --- Events ---
    event SystemPaused(bool paused);
    event AdminRoleGranted(address admin);
    event AdminRoleRevoked(address admin);
    event ParametersUpdated(string parameterName, uint256 value);
    event ForgeInitialized(address user);
    event EssenceMinted(address receiver, uint256 amount);
    event EssenceBurned(address burner, uint256 amount);
    event KnowledgeGained(address user, uint256 amount);
    event KnowledgeLost(address user, uint256 amount);
    event ForgeUpgraded(address user, uint256 newLevel);
    event ArtifactTypeUpdated(uint256 typeId, string name);
    event ArtifactCrafted(address user, uint256 artifactId, uint256 artifactTypeId);
    event EssenceStaked(address user, uint256 amount);
    event EssenceUnstaked(address user, uint256 amount);
    event DailyTaskCompleted(address user, uint256 essenceReward, uint256 knowledgeReward);
    event ActionPermissionDelegated(address delegator, address delegatee);
    event ActionPermissionRevoked(address delegator, address oldDelegatee);
    event DiscoveryEventTriggered(address user, uint256 essenceReward, uint256 knowledgeReward);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "Only admin or owner can call this function");
        _;
    }

    modifier notPaused() {
        require(!systemPaused, "System is currently paused");
        _;
    }

    modifier userInitialized(address user) {
        require(userForges[user].initialized, "User forge not initialized");
        _;
    }

    // Checks if sender is the user OR their current delegatee
    modifier onlyDelegateOrOwner(address user) {
        require(msg.sender == user || msg.sender == userForges[user].actionDelegatee, "Not authorized to perform action for this user");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        // Set some initial parameters
        essenceMiningRatePerSecondPerLevel = 1; // 1 essence per second per level initially
        // Set initial upgrade costs (example: cost to reach level 2 from level 1)
        forgeUpgradeCosts[2] = ForgeUpgradeCost(100, 10); // Cost to reach level 2
        forgeUpgradeCosts[3] = ForgeUpgradeCost(300, 30); // Cost to reach level 3
        // ... add more levels as needed
    }

    // --- Admin/Setup Functions ---

    function setSystemPaused(bool _paused) external onlyOwner {
        systemPaused = _paused;
        emit SystemPaused(_paused);
    }

    function grantAdminRole(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        admins[admin] = true;
        emit AdminRoleGranted(admin);
    }

    function revokeAdminRole(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        admins[admin] = false;
        emit AdminRoleRevoked(admin);
    }

    function updateEssenceMiningRate(uint256 newRatePerSecondPerLevel) external onlyAdmin notPaused {
        essenceMiningRatePerSecondPerLevel = newRatePerSecondPerLevel;
        emit ParametersUpdated("EssenceMiningRate", newRatePerSecondPerLevel);
    }

    function updateForgeUpgradeCosts(uint256 level, uint256 essenceCost, uint256 knowledgeCost) external onlyAdmin {
         require(level > 1, "Cannot set cost for level 1 or 0");
        forgeUpgradeCosts[level] = ForgeUpgradeCost(essenceCost, knowledgeCost);
        // No specific event for this, could add one if needed.
    }

    function updateArtifactTypeData(
        uint256 typeId,
        string calldata name,
        uint256 essenceCost,
        uint256 knowledgeRequired,
        uint256 forgeLevelRequired,
        uint64 craftingCooldown
    ) external onlyAdmin {
        require(typeId > 0, "Artifact Type ID must be greater than 0");
        artifactTypes[typeId] = ArtifactTypeData(
            name,
            essenceCost,
            knowledgeRequired,
            forgeLevelRequired,
            craftingCooldown,
            true // Mark as existing
        );
        emit ArtifactTypeUpdated(typeId, name);
    }

    function adminGrantKnowledge(address user, uint256 amount) external onlyAdmin notPaused userInitialized(user) {
        require(amount > 0, "Amount must be positive");
        userForges[user].knowledge += amount;
        emit KnowledgeGained(user, amount);
    }

    function adminDecayKnowledge(address user, uint256 amount) external onlyAdmin notPaused userInitialized(user) {
        require(amount > 0, "Amount must be positive");
        if (userForges[user].knowledge < amount) {
            userForges[user].knowledge = 0;
            amount = userForges[user].knowledge; // Amount actually decayed
        } else {
            userForges[user].knowledge -= amount;
        }
        emit KnowledgeLost(user, amount);
    }

    function adminTriggerDiscoveryEvent(address user) external onlyAdmin notPaused userInitialized(user) {
        // Simple example: Rewards scale with forge level
        uint256 essenceReward = userForges[user].level * 100 + uint256(keccak256(abi.encodePacked(block.timestamp, user))) % 50; // Add some randomness
        uint256 knowledgeReward = userForges[user].level * 10 + uint256(keccak256(abi.encodePacked(block.timestamp, user, "knowledge")))% 10;

        _mintEssence(user, essenceReward);
        userForges[user].knowledge += knowledgeReward;

        emit DiscoveryEventTriggered(user, essenceReward, knowledgeReward);
        emit KnowledgeGained(user, knowledgeReward); // Also emit knowledge event
    }

    // --- User Core Action Functions ---

    function initializeForgeForUser() external notPaused {
        require(!userForges[msg.sender].initialized, "Forge already initialized for user");
        userForges[msg.sender].initialized = true;
        userForges[msg.sender].level = 1; // Start at level 1
        userForges[msg.sender].knowledge = 0;
        userForges[msg.sender].lastEssenceClaimTime = uint64(block.timestamp); // Start claim timer
        userForges[msg.sender].lastDailyTaskTime = uint64(block.timestamp); // Start daily task timer
        // Delegatee is address(0) by default
        // ownedArtifactIds is empty dynamic array by default

        emit ForgeInitialized(msg.sender);
    }

    function claimEssence() external notPaused userInitialized(msg.sender) {
        uint64 currentTime = uint64(block.timestamp);
        uint64 lastClaim = userForges[msg.sender].lastEssenceClaimTime;
        uint256 forgeLevel = userForges[msg.sender].level;

        uint256 secondsElapsed = currentTime - lastClaim;
        uint256 essenceToMint = secondsElapsed * essenceMiningRatePerSecondPerLevel * forgeLevel;

        require(essenceToMint > 0, "No essence accumulated yet");

        _mintEssence(msg.sender, essenceToMint);
        userForges[msg.sender].lastEssenceClaimTime = currentTime;

        // EssenceMinted event is emitted in _mintEssence
    }

    function upgradeForge() external notPaused userInitialized(msg.sender) onlyDelegateOrOwner(msg.sender) {
        uint256 currentLevel = userForges[msg.sender].level;
        uint256 nextLevel = currentLevel + 1;

        ForgeUpgradeCost storage costs = forgeUpgradeCosts[nextLevel];
        require(costs.essenceCost > 0 || costs.knowledgeCost > 0, "No upgrade cost defined for next level");
        require(essenceBalances[msg.sender] >= costs.essenceCost, "Not enough essence to upgrade");
        require(userForges[msg.sender].knowledge >= costs.knowledgeCost, "Not enough knowledge to upgrade");

        // Deduct costs
        essenceBalances[msg.sender] -= costs.essenceCost;
        userForges[msg.sender].knowledge -= costs.knowledgeCost;
        userForges[msg.sender].level = nextLevel;

        emit ForgeUpgraded(msg.sender, nextLevel);
    }

    function craftArtifact(uint256 artifactTypeId) external notPaused userInitialized(msg.sender) onlyDelegateOrOwner(msg.sender) {
        ArtifactTypeData storage artifactData = artifactTypes[artifactTypeId];
        require(artifactData.exists, "Artifact type does not exist");

        UserForgeData storage userData = userForges[msg.sender];

        // Check cooldown
        require(block.timestamp >= userData.artifactCraftCooldowns[artifactTypeId] + artifactData.craftingCooldown, "Artifact type on cooldown");

        // Check requirements
        require(essenceBalances[msg.sender] >= artifactData.essenceCost, "Not enough essence to craft");
        require(userData.knowledge >= artifactData.knowledgeRequired, "Not enough knowledge to craft");
        require(userData.level >= artifactData.forgeLevelRequired, "Forge level too low to craft");

        // Deduct costs
        essenceBalances[msg.sender] -= artifactData.essenceCost;
        // Knowledge is a requirement, not consumed (like a skill)

        // Mint the artifact (simulate NFT by assigning a unique ID)
        uint256 newArtifactId = nextArtifactId++;
        userData.ownedArtifactIds.push(newArtifactId); // Track ownership internally

        // Set cooldown
        userData.artifactCraftCooldowns[artifactTypeId] = uint64(block.timestamp);

        emit ArtifactCrafted(msg.sender, newArtifactId, artifactTypeId);
    }

    function stakeEssence(uint256 amount) external notPaused userInitialized(msg.sender) {
        require(amount > 0, "Amount must be positive");
        require(essenceBalances[msg.sender] >= amount, "Not enough essence to stake");

        essenceBalances[msg.sender] -= amount;
        stakedEssence[msg.sender] += amount;

        emit EssenceStaked(msg.sender, amount);
    }

    function unstakeEssence(uint256 amount) external notPaused userInitialized(msg.sender) {
        require(amount > 0, "Amount must be positive");
        require(stakedEssence[msg.sender] >= amount, "Not enough staked essence to unstake");

        stakedEssence[msg.sender] -= amount;
        essenceBalances[msg.sender] += amount;

        emit EssenceUnstaked(msg.sender, amount);
    }

    function burnEssence(uint256 amount) external notPaused userInitialized(msg.sender) {
        require(amount > 0, "Amount must be positive");
        require(essenceBalances[msg.sender] >= amount, "Not enough essence to burn");

        essenceBalances[msg.sender] -= amount;
        _totalSupplyEssence -= amount;

        emit EssenceBurned(msg.sender, amount);
    }

    function performDailyTask() external notPaused userInitialized(msg.sender) {
        uint64 currentTime = uint64(block.timestamp);
        require(currentTime >= userForges[msg.sender].lastDailyTaskTime + dailyTaskCooldown, "Daily task is on cooldown");

        _mintEssence(msg.sender, dailyTaskEssenceReward);
        userForges[msg.sender].knowledge += dailyTaskKnowledgeReward;
        userForges[msg.sender].lastDailyTaskTime = currentTime;

        emit DailyTaskCompleted(msg.sender, dailyTaskEssenceReward, dailyTaskKnowledgeReward);
        emit KnowledgeGained(msg.sender, dailyTaskKnowledgeReward); // Also emit knowledge event
    }

    function delegateActionPermission(address delegatee) external notPaused userInitialized(msg.sender) {
        require(delegatee != msg.sender, "Cannot delegate to self");
        userForges[msg.sender].actionDelegatee = delegatee;
        emit ActionPermissionDelegated(msg.sender, delegatee);
    }

    function revokeActionPermissionDelegate() external notPaused userInitialized(msg.sender) {
        address oldDelegatee = userForges[msg.sender].actionDelegatee;
        require(oldDelegatee != address(0), "No delegatee currently set");
        userForges[msg.sender].actionDelegatee = address(0);
        emit ActionPermissionRevoked(msg.sender, oldDelegatee);
    }

    // --- View/Query Functions ---

    function getForgeData(address user) external view returns (
        bool initialized,
        uint256 level,
        uint256 knowledge,
        uint64 lastEssenceClaimTime,
        uint64 lastDailyTaskTime,
        address actionDelegatee,
        uint256 essenceBalance,
        uint256 stakedEssenceAmount
    ) {
        UserForgeData storage data = userForges[user];
        return (
            data.initialized,
            data.level,
            data.knowledge,
            data.lastEssenceClaimTime,
            data.lastDailyTaskTime,
            data.actionDelegatee,
            essenceBalances[user],
            stakedEssence[user]
        );
    }

    function getEssenceBalance(address user) external view returns (uint256) {
        return essenceBalances[user];
    }

    function getKnowledgeAmount(address user) external view returns (uint256) {
        return userForges[user].knowledge;
    }

    function getArtifactTypeData(uint256 typeId) external view returns (
        string memory name,
        uint256 essenceCost,
        uint256 knowledgeRequired,
        uint256 forgeLevelRequired,
        uint64 craftingCooldown,
        bool exists
    ) {
        ArtifactTypeData storage data = artifactTypes[typeId];
        return (
            data.name,
            data.essenceCost,
            data.knowledgeRequired,
            data.forgeLevelRequired,
            data.craftingCooldown,
            data.exists
        );
    }

    function getSystemState() external view returns (
        address currentOwner,
        bool paused,
        uint256 currentMiningRatePerSecondPerLevel,
        uint256 totalEssenceSupply,
        uint64 currentDailyTaskCooldown,
        uint256 currentDailyTaskEssenceReward,
        uint256 currentDailyTaskKnowledgeReward,
        uint256 nextAvailableArtifactId
    ) {
        return (
            owner,
            systemPaused,
            essenceMiningRatePerSecondPerLevel,
            _totalSupplyEssence,
            dailyTaskCooldown,
            dailyTaskEssenceReward,
            dailyTaskKnowledgeReward,
            nextArtifactId
        );
    }

    function getUserStakedEssence(address user) external view returns (uint256) {
        return stakedEssence[user];
    }

     function isSystemPaused() external view returns (bool) {
        return systemPaused;
    }

    function hasAdminRole(address user) external view returns (bool) {
        return admins[user] || user == owner;
    }

    function checkCraftingEligibility(address user, uint256 artifactTypeId) external view returns (
        bool eligible,
        string memory reason,
        uint256 essenceRequired,
        uint256 knowledgeRequired,
        uint256 forgeLevelRequired,
        uint64 craftingCooldownEnds
    ) {
        ArtifactTypeData storage artifactData = artifactTypes[artifactTypeId];
        if (!artifactData.exists) {
             return (false, "Artifact type does not exist", 0, 0, 0, 0);
        }

        UserForgeData storage userData = userForges[user];
        if (!userData.initialized) {
             return (false, "User forge not initialized", 0, 0, 0, 0);
        }

        uint64 cooldownEnds = userData.artifactCraftCooldowns[artifactTypeId] + artifactData.craftingCooldown;
        if (block.timestamp < cooldownEnds) {
            return (false, "Artifact type on cooldown", artifactData.essenceCost, artifactData.knowledgeRequired, artifactData.forgeLevelRequired, cooldownEnds);
        }

        if (essenceBalances[user] < artifactData.essenceCost) {
            return (false, "Not enough essence", artifactData.essenceCost, artifactData.knowledgeRequired, artifactData.forgeLevelRequired, cooldownEnds);
        }

        if (userData.knowledge < artifactData.knowledgeRequired) {
            return (false, "Not enough knowledge", artifactData.essenceCost, artifactData.knowledgeRequired, artifactData.forgeLevelRequired, cooldownEnds);
        }

        if (userData.level < artifactData.forgeLevelRequired) {
            return (false, "Forge level too low", artifactData.essenceCost, artifactData.knowledgeRequired, artifactData.forgeLevelRequired, cooldownEnds);
        }

        return (true, "Eligible", artifactData.essenceCost, artifactData.knowledgeRequired, artifactData.forgeLevelRequired, cooldownEnds);
    }

    function getActionDelegatee(address user) external view returns (address) {
        return userForges[user].actionDelegatee;
    }

    function getUserArtifactIds(address user) external view returns (uint256[] memory) {
        // Note: This copies the entire array to memory, could be expensive for users with many artifacts.
        // For a real NFT system, you'd typically query ERC721 balance/tokenOfOwnerByIndex.
        return userForges[user].ownedArtifactIds;
    }

    // --- Internal Helper Functions ---

    function _mintEssence(address receiver, uint256 amount) internal {
        require(receiver != address(0), "Mint to the zero address");
        _totalSupplyEssence += amount;
        essenceBalances[receiver] += amount;
        emit EssenceMinted(receiver, amount);
    }

    // Add more internal helper functions if needed for complex logic
}
```