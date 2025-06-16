Okay, let's design an interesting and advanced smart contract.

Instead of a typical token, NFT, or DAO, we'll create a system centered around **dynamic, stateful "Traits"** tied to user addresses within the protocol, influenced by a shared, dynamic **"Protocol Health"** metric. Users acquire and upgrade these traits using an internal resource called "Essence," which itself is earned based on time and the current `ProtocolHealth`. Depositing Essence into the system acts as a "sink" and boosts `ProtocolHealth`, creating a feedback loop where collective contribution benefits individual essence earning.

This combines concepts of:
1.  **Stateful User Assets:** Traits are not transferable tokens, but attributes bound to the user's address within the contract's storage, with levels and properties.
2.  **Dynamic Economics:** Trait upgrade costs and Essence earning rates are not fixed but depend on trait levels and the global `ProtocolHealth`.
3.  **Shared Global State:** `ProtocolHealth` is a central variable influenced by user actions, affecting everyone.
4.  **Resource Sinks & Feedback Loops:** Spending Essence to boost `ProtocolHealth` provides a collective benefit (increased earning rate).
5.  **Progression System:** Users unlock and upgrade traits to enhance their capabilities or standing within the protocol (conceptually, even if specific trait effects are abstract in V1).

---

**Smart Contract: AdaptiveTraitProtocol**

**Outline:**

1.  **State Variables:** Define core data storage including user data (Essence balance, traits, last claim time), trait definitions, Protocol Health, admin address, paused status, total supplies.
2.  **Structs:** Define data structures for Trait Definitions and User-owned Traits.
3.  **Events:** Announce key actions (registration, trait unlock/upgrade, essence claim/deposit, health change, admin actions).
4.  **Modifiers:** Control access and state (owner-only, registration check, pause checks).
5.  **Core Logic:**
    *   User Registration
    *   Trait Definitions (Admin)
    *   Essence Management (Claiming, Depositing for Health)
    *   Trait Management (Unlocking, Upgrading, Querying)
    *   Protocol Health Management
    *   Query Functions (for all key data)
    *   Admin Functions (parameters, pause)
6.  **Functions:** Implement the detailed logic for each action and query.

**Function Summary:**

*   **Initialization & Admin:**
    *   `constructor()`: Sets contract owner, initializes state.
    *   `defineTraitType(uint256 _traitTypeId, string calldata _name, uint256 _baseUnlockCost, uint256 _upgradeCostIncrease)`: Admin function to define properties of a new trait type.
    *   `setBaseEssenceClaimRate(uint256 _rate)`: Admin function to set the base rate of Essence claiming.
    *   `setProtocolHealthInfluenceFactor(uint256 _factor)`: Admin function to set how much depositing Essence affects Protocol Health.
    *   `pauseContract()`: Admin function to pause core user interactions.
    *   `unpauseContract()`: Admin function to unpause the contract.
*   **User Management:**
    *   `registerUser()`: Allows a new user to register and initialize their state.
    *   `isRegistered(address _user)`: Checks if an address is registered.
    *   `getTotalRegisteredUsers()`: Gets the total count of registered users.
*   **Essence Management:**
    *   `claimEssence()`: Allows a registered user to claim accumulated Essence based on time and Protocol Health.
    *   `depositEssenceForHealth(uint256 _amount)`: Allows a registered user to deposit Essence, increasing Protocol Health (acts as a sink).
    *   `getUserEssenceBalance(address _user)`: Gets the Essence balance for a user.
    *   `getEssenceClaimRate(address _user)`: Calculates the current per-second Essence claim rate for a user (based on Protocol Health).
    *   `timeSinceLastEssenceClaim(address _user)`: Gets the time elapsed since a user's last claim.
    *   `getEssenceTotalSupply()`: Gets the total amount of Essence ever minted.
*   **Trait Management:**
    *   `unlockTrait(uint256 _traitTypeId)`: Allows a registered user to unlock Level 1 of a trait using Essence.
    *   `upgradeTrait(uint256 _traitTypeId)`: Allows a registered user to upgrade an owned trait using Essence.
    *   `getUserTraitLevel(address _user, uint256 _traitTypeId)`: Gets the level of a specific trait for a user.
    *   `getUserOwnedTraitTypes(address _user)`: Gets the list of trait type IDs owned by a user.
    *   `calculateUnlockCost(uint256 _traitTypeId)`: Calculates the Essence cost to unlock a trait type.
    *   `calculateUpgradeCost(address _user, uint256 _traitTypeId)`: Calculates the Essence cost to upgrade a user's specific trait.
    *   `getTraitTypeDetails(uint256 _traitTypeId)`: Gets the definition details of a trait type.
    *   `getTotalTraitTypes()`: Gets the total number of defined trait types.
    *   `getUserTotalTraitLevels(address _user)`: Sums the levels of all traits owned by a user.
*   **Protocol Health:**
    *   `getProtocolHealth()`: Gets the current global Protocol Health value.
    *   `getProtocolHealthInfluenceFactor()`: Gets the current factor for Essence deposit affecting health.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AdaptiveTraitProtocol
 * @dev A smart contract managing dynamic user traits, an internal resource (Essence),
 * and a global Protocol Health state. Users earn Essence, unlock/upgrade traits,
 * and can contribute Essence to boost Protocol Health, which in turn increases
 * the rate of Essence earning for everyone. This creates a dynamic, self-sustaining
 * feedback loop centered around collective contribution and individual progression.
 */

/**
 * Outline:
 * 1. State Variables: Core data storage for users, traits, health, settings.
 * 2. Structs: Definitions for Trait types and User status.
 * 3. Events: Signalling key protocol activities.
 * 4. Modifiers: Access control and state checks.
 * 5. Core Logic: Implementation of user registration, trait handling, essence mechanics,
 *    protocol health updates, and admin functions.
 * 6. Functions: Detailed implementation of all outlined operations and queries.
 */

/**
 * Function Summary:
 *
 * Initialization & Admin:
 * - constructor(): Sets initial owner and state.
 * - defineTraitType(uint256 _traitTypeId, string calldata _name, uint256 _baseUnlockCost, uint256 _upgradeCostIncrease): Admin - Defines properties of a new trait type.
 * - setBaseEssenceClaimRate(uint256 _rate): Admin - Sets the base per-second rate for Essence claiming.
 * - setProtocolHealthInfluenceFactor(uint256 _factor): Admin - Sets how depositing Essence influences Protocol Health.
 * - pauseContract(): Admin - Pauses user interactions.
 * - unpauseContract(): Admin - Unpauses the contract.
 *
 * User Management:
 * - registerUser(): Registers a new user, initializing their state.
 * - isRegistered(address _user): Checks if an address is registered.
 * - getTotalRegisteredUsers(): Gets the count of registered users.
 *
 * Essence Management:
 * - claimEssence(): Claims accumulated Essence based on time and Protocol Health.
 * - depositEssenceForHealth(uint256 _amount): Deposits Essence to boost Protocol Health (acts as a sink).
 * - getUserEssenceBalance(address _user): Gets a user's Essence balance.
 * - getEssenceClaimRate(address _user): Calculates a user's current per-second Essence claim rate.
 * - timeSinceLastEssenceClaim(address _user): Gets time elapsed since last claim.
 * - getEssenceTotalSupply(): Gets total Essence minted.
 *
 * Trait Management:
 * - unlockTrait(uint256 _traitTypeId): Unlocks Level 1 of a trait for a user using Essence.
 * - upgradeTrait(uint256 _traitTypeId): Upgrades an owned trait using Essence.
 * - getUserTraitLevel(address _user, uint256 _traitTypeId): Gets a user's level for a trait.
 * - getUserOwnedTraitTypes(address _user): Lists trait type IDs owned by a user.
 * - calculateUnlockCost(uint256 _traitTypeId): Calculates unlock cost for a trait type.
 * - calculateUpgradeCost(address _user, uint256 _traitTypeId): Calculates upgrade cost for a user's trait.
 * - getTraitTypeDetails(uint256 _traitTypeId): Gets details of a trait definition.
 * - getTotalTraitTypes(): Gets the count of defined trait types.
 * - getUserTotalTraitLevels(address _user): Sums levels of all traits owned by a user.
 *
 * Protocol Health:
 * - getProtocolHealth(): Gets the current global Protocol Health value.
 * - getProtocolHealthInfluenceFactor(): Gets the health influence factor.
 */

contract AdaptiveTraitProtocol {

    address public owner;
    bool public paused = false;

    // --- Constants ---
    uint256 private constant SECONDS_PER_YEAR = 31536000; // Approx
    uint256 private constant HEALTH_SCALE_FACTOR = 10000; // Factor to scale health influence on claim rate

    // --- State Variables ---

    // User Status: Essence balance, registered status, last essence claim time, owned traits
    struct UserStatus {
        bool isRegistered;
        uint256 essenceBalance;
        uint256 lastEssenceClaimTime; // Timestamp of last claim
        mapping(uint256 => uint256) traits; // traitTypeId => level
        uint256[] ownedTraitTypeIds; // List of trait type IDs the user owns (for easier iteration)
    }
    mapping(address => UserStatus) public users;
    uint256 public totalRegisteredUsers = 0;

    // Trait Definitions: properties of each trait type
    struct TraitDefinition {
        string name;
        uint256 baseUnlockCost;      // Cost for level 1
        uint256 upgradeCostIncrease; // How much cost increases per level for upgrade
        bool isDefined; // Flag to check if traitTypeId is valid
    }
    mapping(uint256 => TraitDefinition) public traitDefinitions;
    uint256 public totalTraitTypes = 0; // Counter for unique trait type IDs used

    // Global Protocol State
    uint256 public protocolHealth = 0; // A metric influenced by user deposits
    uint256 public baseEssenceClaimRate = 1000; // Base essence claimable per second (scaled value, e.g., 1000 = 0.001 essence/sec)
    uint256 public protocolHealthInfluenceFactor = 1; // How many essence units equal 1 health point

    // Total tracked resource/state
    uint256 public totalEssenceMinted = 0;
    mapping(uint256 => uint256) public totalTraitUnlocks; // Count of times a specific trait type has been unlocked (level 1)
    mapping(uint256 => uint256) public totalTraitUpgrades; // Count of times a specific trait type has been upgraded beyond level 1


    // --- Events ---
    event UserRegistered(address indexed user);
    event EssenceClaimed(address indexed user, uint256 amount);
    event EssenceDepositedForHealth(address indexed user, uint256 amount, uint256 newProtocolHealth);
    event TraitDefined(uint256 indexed traitTypeId, string name, uint256 baseUnlockCost, uint256 upgradeCostIncrease);
    event TraitUnlocked(address indexed user, uint256 indexed traitTypeId, uint256 level);
    event TraitUpgraded(address indexed user, uint256 indexed traitTypeId, uint256 oldLevel, uint256 newLevel);
    event ProtocolHealthChanged(uint256 oldHealth, uint256 newHealth);
    event ParametersUpdated(string paramName, uint256 newValue);
    event Paused(address account);
    event Unpaused(address account);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyRegistered(address _user) {
        require(users[_user].isRegistered, "User not registered");
        _;
    }

    modifier onlyDefinedTrait(uint256 _traitTypeId) {
         require(traitDefinitions[_traitTypeId].isDefined, "Trait type not defined");
         _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Admin Functions ---

    /**
     * @dev Defines a new type of trait and its costs. Can only be called by the owner.
     * @param _traitTypeId A unique ID for the trait type.
     * @param _name The name of the trait.
     * @param _baseUnlockCost The Essence cost to unlock Level 1 of this trait.
     * @param _upgradeCostIncrease The amount the upgrade cost increases per level.
     */
    function defineTraitType(uint256 _traitTypeId, string calldata _name, uint256 _baseUnlockCost, uint256 _upgradeCostIncrease) external onlyOwner {
        require(!traitDefinitions[_traitTypeId].isDefined, "Trait type already defined");
        require(_traitTypeId > 0, "Trait type ID must be greater than 0");

        traitDefinitions[_traitTypeId] = TraitDefinition({
            name: _name,
            baseUnlockCost: _baseUnlockCost,
            upgradeCostIncrease: _upgradeCostIncrease,
            isDefined: true
        });
        totalTraitTypes++;
        emit TraitDefined(_traitTypeId, _name, _baseUnlockCost, _upgradeCostIncrease);
    }

    /**
     * @dev Sets the base rate at which users earn Essence per second.
     * @param _rate The new base rate (scaled value).
     */
    function setBaseEssenceClaimRate(uint256 _rate) external onlyOwner {
        baseEssenceClaimRate = _rate;
        emit ParametersUpdated("baseEssenceClaimRate", _rate);
    }

    /**
     * @dev Sets the factor determining how much depositing Essence increases Protocol Health.
     * @param _factor The new influence factor. 1 means 1 Essence = 1 Health point.
     */
    function setProtocolHealthInfluenceFactor(uint256 _factor) external onlyOwner {
        require(_factor > 0, "Influence factor must be greater than 0");
        protocolHealthInfluenceFactor = _factor;
         emit ParametersUpdated("protocolHealthInfluenceFactor", _factor);
    }

    /**
     * @dev Pauses the contract, preventing most user interactions.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, enabling user interactions.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- User Management ---

    /**
     * @dev Registers the calling address as a user in the protocol.
     * Initializes their state.
     */
    function registerUser() external whenNotPaused {
        require(!users[msg.sender].isRegistered, "User already registered");
        users[msg.sender].isRegistered = true;
        users[msg.sender].lastEssenceClaimTime = block.timestamp; // Initialize claim time
        totalRegisteredUsers++;
        emit UserRegistered(msg.sender);
    }

    /**
     * @dev Checks if a given address is a registered user.
     * @param _user The address to check.
     * @return True if the address is registered, false otherwise.
     */
    function isRegistered(address _user) public view returns (bool) {
        return users[_user].isRegistered;
    }

    /**
     * @dev Gets the total count of registered users.
     * @return The total number of registered users.
     */
    function getTotalRegisteredUsers() external view returns (uint256) {
        return totalRegisteredUsers;
    }


    // --- Essence Management ---

    /**
     * @dev Claims accumulated Essence for the calling user. Essence accrues based
     * on the time since the last claim and the current Protocol Health.
     */
    function claimEssence() external whenNotPaused onlyRegistered(msg.sender) {
        uint256 timeElapsed = block.timestamp - users[msg.sender].lastEssenceClaimTime;
        if (timeElapsed == 0) {
            return; // No time has passed
        }

        uint256 currentClaimRate = getEssenceClaimRate(msg.sender); // Scaled rate per second

        // Calculate claimable amount: (rate * time) / HEALTH_SCALE_FACTOR (because rate is scaled)
        uint256 claimableAmount = (currentClaimRate * timeElapsed) / HEALTH_SCALE_FACTOR;

        if (claimableAmount == 0) {
            users[msg.sender].lastEssenceClaimTime = block.timestamp; // Update time even if 0 claimed due to rounding
            return;
        }

        users[msg.sender].essenceBalance += claimableAmount;
        totalEssenceMinted += claimableAmount;
        users[msg.sender].lastEssenceClaimTime = block.timestamp; // Update last claim time

        emit EssenceClaimed(msg.sender, claimableAmount);
    }

    /**
     * @dev Allows a user to deposit Essence from their balance into the protocol.
     * This increases the global Protocol Health. Deposited Essence is burned/sunk.
     * @param _amount The amount of Essence to deposit.
     */
    function depositEssenceForHealth(uint256 _amount) external whenNotPaused onlyRegistered(msg.sender) {
        require(_amount > 0, "Deposit amount must be greater than 0");
        require(users[msg.sender].essenceBalance >= _amount, "Insufficient Essence balance");

        // Deduct Essence from user
        users[msg.sender].essenceBalance -= _amount;

        // Increase Protocol Health
        // Use a checked add for safety, although overflows are unlikely with uint256
        uint256 healthIncrease = _amount / protocolHealthInfluenceFactor;
        uint256 oldHealth = protocolHealth;
        protocolHealth += healthIncrease; // Potential optimization: add safety checks if health can become excessively large

        emit EssenceDepositedForHealth(msg.sender, _amount, protocolHealth);
        if (oldHealth != protocolHealth) {
             emit ProtocolHealthChanged(oldHealth, protocolHealth);
        }
    }

    /**
     * @dev Gets the current Essence balance of a user.
     * @param _user The address of the user.
     * @return The user's Essence balance.
     */
    function getUserEssenceBalance(address _user) external view onlyRegistered(_user) returns (uint256) {
        return users[_user].essenceBalance;
    }

    /**
     * @dev Calculates the current estimated per-second Essence claim rate for a user.
     * Rate is influenced by the global Protocol Health.
     * @param _user The address of the user.
     * @return The scaled per-second Essence claim rate.
     */
    function getEssenceClaimRate(address _user) public view onlyRegistered(_user) returns (uint256) {
        // Rate = baseRate + (baseRate * protocolHealth / HEALTH_SCALE_FACTOR)
        // This formula ensures health influence is proportional to the base rate
        // And scales the health impact down using HEALTH_SCALE_FACTOR
        uint256 healthInfluence = (baseEssenceClaimRate * protocolHealth) / HEALTH_SCALE_FACTOR;
        return baseEssenceClaimRate + healthInfluence;
    }

    /**
     * @dev Gets the time elapsed in seconds since a user last claimed Essence.
     * @param _user The address of the user.
     * @return The time elapsed in seconds.
     */
    function timeSinceLastEssenceClaim(address _user) external view onlyRegistered(_user) returns (uint256) {
        return block.timestamp - users[_user].lastEssenceClaimTime;
    }

    /**
     * @dev Gets the total cumulative amount of Essence that has been minted.
     * @return The total essence minted.
     */
    function getEssenceTotalSupply() external view returns (uint256) {
        return totalEssenceMinted;
    }


    // --- Trait Management ---

    /**
     * @dev Unlocks Level 1 of a specified trait for the calling user.
     * Requires the user to have sufficient Essence.
     * @param _traitTypeId The ID of the trait type to unlock.
     */
    function unlockTrait(uint256 _traitTypeId) external whenNotPaused onlyRegistered(msg.sender) onlyDefinedTrait(_traitTypeId) {
        require(users[msg.sender].traits[_traitTypeId] == 0, "Trait already unlocked");

        uint256 unlockCost = calculateUnlockCost(_traitTypeId);
        require(users[msg.sender].essenceBalance >= unlockCost, "Insufficient Essence to unlock trait");

        // Deduct cost
        users[msg.sender].essenceBalance -= unlockCost;

        // Unlock trait at level 1
        users[msg.sender].traits[_traitTypeId] = 1;

        // Add trait ID to owned list if it's the first time unlocking it
        bool alreadyInList = false;
        for (uint i = 0; i < users[msg.sender].ownedTraitTypeIds.length; i++) {
            if (users[msg.sender].ownedTraitTypeIds[i] == _traitTypeId) {
                alreadyInList = true; // Should not happen due to "Trait already unlocked" check, but good practice
                break;
            }
        }
        if (!alreadyInList) {
            users[msg.sender].ownedTraitTypeIds.push(_traitTypeId);
        }

        totalTraitUnlocks[_traitTypeId]++;

        emit TraitUnlocked(msg.sender, _traitTypeId, 1);
    }

    /**
     * @dev Upgrades a specified trait for the calling user.
     * Requires the user to own the trait and have sufficient Essence for the next level.
     * @param _traitTypeId The ID of the trait type to upgrade.
     */
    function upgradeTrait(uint256 _traitTypeId) external whenNotPaused onlyRegistered(msg.sender) onlyDefinedTrait(_traitTypeId) {
        uint256 currentLevel = users[msg.sender].traits[_traitTypeId];
        require(currentLevel > 0, "Trait is not unlocked");

        uint256 upgradeCost = calculateUpgradeCost(msg.sender, _traitTypeId);
        require(users[msg.sender].essenceBalance >= upgradeCost, "Insufficient Essence to upgrade trait");

        // Deduct cost
        users[msg.sender].essenceBalance -= upgradeCost;

        // Upgrade trait level
        uint256 newLevel = currentLevel + 1;
        users[msg.sender].traits[_traitTypeId] = newLevel;

        totalTraitUpgrades[_traitTypeId]++;

        emit TraitUpgraded(msg.sender, _traitTypeId, currentLevel, newLevel);
    }

     /**
     * @dev Gets the current level of a specific trait for a user.
     * @param _user The address of the user.
     * @param _traitTypeId The ID of the trait type.
     * @return The level of the trait (0 if not owned/unlocked).
     */
    function getUserTraitLevel(address _user, uint256 _traitTypeId) external view onlyRegistered(_user) returns (uint256) {
        return users[_user].traits[_traitTypeId];
    }

    /**
     * @dev Gets the list of trait type IDs that a user currently owns (level > 0).
     * @param _user The address of the user.
     * @return An array of trait type IDs.
     */
    function getUserOwnedTraitTypes(address _user) external view onlyRegistered(_user) returns (uint256[] memory) {
        return users[_user].ownedTraitTypeIds;
    }

    /**
     * @dev Calculates the Essence cost to unlock Level 1 of a specific trait type.
     * @param _traitTypeId The ID of the trait type.
     * @return The unlock cost.
     */
    function calculateUnlockCost(uint256 _traitTypeId) public view onlyDefinedTrait(_traitTypeId) returns (uint256) {
        return traitDefinitions[_traitTypeId].baseUnlockCost;
    }

    /**
     * @dev Calculates the Essence cost to upgrade a specific trait for a user
     * from their current level to the next. Cost scales with the current level.
     * Formula: baseUnlockCost + (currentLevel * upgradeCostIncrease)
     * @param _user The address of the user.
     * @param _traitTypeId The ID of the trait type.
     * @return The upgrade cost to the next level.
     */
    function calculateUpgradeCost(address _user, uint256 _traitTypeId) public view onlyRegistered(_user) onlyDefinedTrait(_traitTypeId) returns (uint256) {
        uint256 currentLevel = users[_user].traits[_traitTypeId];
        require(currentLevel > 0, "Trait is not unlocked");

        TraitDefinition storage traitDef = traitDefinitions[_traitTypeId];
        // Cost increases linearly with the *current* level
        return traitDef.baseUnlockCost + (currentLevel * traitDef.upgradeCostIncrease);
    }

    /**
     * @dev Gets the definition details for a specific trait type.
     * @param _traitTypeId The ID of the trait type.
     * @return The name, base unlock cost, and upgrade cost increase.
     */
    function getTraitTypeDetails(uint256 _traitTypeId) external view onlyDefinedTrait(_traitTypeId) returns (string memory name, uint256 baseUnlockCost, uint256 upgradeCostIncrease) {
        TraitDefinition storage traitDef = traitDefinitions[_traitTypeId];
        return (traitDef.name, traitDef.baseUnlockCost, traitDef.upgradeCostIncrease);
    }

    /**
     * @dev Gets the total number of unique trait types that have been defined.
     * @return The count of defined trait types.
     */
    function getTotalTraitTypes() external view returns (uint256) {
        return totalTraitTypes;
    }

     /**
     * @dev Calculates the sum of levels for all traits owned by a user.
     * @param _user The address of the user.
     * @return The total sum of trait levels.
     */
    function getUserTotalTraitLevels(address _user) external view onlyRegistered(_user) returns (uint256) {
        uint256 totalLevels = 0;
        uint256[] memory ownedIds = users[_user].ownedTraitTypeIds;
        for (uint i = 0; i < ownedIds.length; i++) {
            totalLevels += users[_user].traits[ownedIds[i]];
        }
        return totalLevels;
    }


    // --- Protocol Health ---

    /**
     * @dev Gets the current global Protocol Health value.
     * @return The current Protocol Health.
     */
    function getProtocolHealth() external view returns (uint256) {
        return protocolHealth;
    }

     /**
     * @dev Gets the current factor determining how much depositing Essence increases Protocol Health.
     * @return The current influence factor.
     */
    function getProtocolHealthInfluenceFactor() external view returns (uint256) {
        return protocolHealthInfluenceFactor;
    }

    // --- Statistics (Bonus Functions) ---

    /**
     * @dev Gets the total count of times a specific trait type has been unlocked (reached level 1).
     * @param _traitTypeId The ID of the trait type.
     * @return The total unlock count.
     */
    function getTraitUnlockCount(uint256 _traitTypeId) external view returns (uint256) {
        return totalTraitUnlocks[_traitTypeId];
    }

    /**
     * @dev Gets the total count of times a specific trait type has been upgraded (level 1 -> 2, 2 -> 3, etc.).
     * @param _traitTypeId The ID of the trait type.
     * @return The total upgrade count.
     */
    function getTraitUpgradeCount(uint256 _traitTypeId) external view returns (uint256) {
        return totalTraitUpgrades[_traitTypeId];
    }
}
```