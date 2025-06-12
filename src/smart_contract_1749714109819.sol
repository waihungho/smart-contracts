Okay, here is a Solidity smart contract for a "Soulbound Skill Tree". This concept utilizes Soulbound Token (SBT) principles by tying skill achievements permanently to an address, combined with a hierarchical dependency system reminiscent of RPG skill trees. It's not a standard token contract (like ERC-20/721/1155), but rather manages structured data tied to user addresses, making the "soulbound" aspect inherent in the state itself rather than a transfer restriction on a token ID.

It incorporates:
*   **Soulbound State:** User skills are tied directly to their address and cannot be transferred.
*   **Skill Dependencies:** Skills can require other skills at certain levels as prerequisites.
*   **Tiered Levels:** Skills can have multiple levels of proficiency.
*   **Minter Roles:** Designated addresses can grant and upgrade skills.
*   **Dynamic Skill Definition:** Skills and their dependencies can be defined and updated by the contract owner.

---

**Outline & Function Summary:**

1.  **Contract:** `SoulboundSkillTree`
2.  **Concept:** Manages a non-transferable record of user skills and levels within a defined skill tree structure. Skills are granted by approved minters based on defined dependencies.
3.  **State Variables:**
    *   `_owner`: Address of the contract owner.
    *   `skills`: Mapping from skill ID (uint256) to `Skill` struct. Stores definition of each skill.
    *   `userSkills`: Mapping from user address to another mapping (skill ID -> level). Stores the level of each skill a user possesses.
    *   `isMinter`: Mapping from address to bool. Tracks addresses authorized to grant/upgrade skills.
    *   `skillIds`: Array of all defined skill IDs.
4.  **Structs:**
    *   `SkillDependency`: Defines a prerequisite skill ID and the minimum level required.
    *   `Skill`: Defines a skill node: name, description, level cap, dependencies, and active status.
5.  **Events:**
    *   `OwnershipTransferred`: Emitted when contract ownership changes.
    *   `MinterAdded`: Emitted when a minter is added.
    *   `MinterRemoved`: Emitted when a minter is removed.
    *   `SkillAdded`: Emitted when a new skill is defined.
    *   `SkillUpdated`: Emitted when a skill definition is changed.
    *   `SkillActivated`: Emitted when a skill is activated.
    *   `SkillDeactivated`: Emitted when a skill is deactivated.
    *   `SkillGranted`: Emitted when a user is granted a skill (level 1).
    *   `SkillUpgraded`: Emitted when a user's skill level increases.
    *   `SkillLevelSet`: Emitted when a user's skill level is set directly.
    *   `SkillRevoked`: Emitted when a skill is removed from a user.
6.  **Modifiers:**
    *   `onlyOwner`: Restricts function access to the contract owner.
    *   `onlyMinter`: Restricts function access to approved minters or the owner.
7.  **Functions (27 Total):**

    *   **Admin/Setup (Owner Only):**
        1.  `constructor()`: Sets the initial contract owner.
        2.  `transferOwnership(address newOwner)`: Transfers ownership of the contract.
        3.  `addMinter(address minter)`: Adds an address to the minters list.
        4.  `removeMinter(address minter)`: Removes an address from the minters list.
        5.  `addSkill(uint256 skillId, string memory name, string memory description, uint8 levelCap, SkillDependency[] memory dependencies)`: Defines a new skill node with dependencies and level cap.
        6.  `updateSkill(uint256 skillId, string memory name, string memory description, uint8 levelCap, SkillDependency[] memory dependencies)`: Updates details of an existing skill.
        7.  `deactivateSkill(uint256 skillId)`: Marks a skill as inactive, preventing new grants/upgrades.
        8.  `activateSkill(uint256 skillId)`: Marks a skill as active, allowing grants/upgrades again.

    *   **Skill Management (Minter or Owner Only):**
        9.  `grantSkill(address user, uint256 skillId)`: Grants a skill to a user at level 1. Checks dependencies and skill status.
        10. `upgradeSkill(address user, uint256 skillId)`: Increases a user's skill level by 1. Checks dependencies, level cap, and skill status.
        11. `setLevel(address user, uint256 skillId, uint8 level)`: Sets a user's skill level directly. Checks dependencies (for level > 0) and skill status. Allows setting level 0 (effectively revoking).
        12. `revokeSkill(address user, uint256 skillId)`: Removes a skill entirely from a user by setting level to 0.
        13. `batchGrantSkills(address[] memory users, uint256 skillId)`: Grants a skill to multiple users.
        14. `batchUpgradeSkills(address[] memory users, uint256 skillId)`: Upgrades a skill for multiple users.
        15. `batchSetLevel(address[] memory users, uint256 skillId, uint8 level)`: Sets the level of a skill for multiple users.
        16. `batchRevokeSkills(address[] memory users, uint256 skillId)`: Revokes a skill from multiple users.

    *   **Querying/Viewing (Public/View):**
        17. `getOwner() view returns (address)`: Returns the contract owner.
        18. `isMinter(address minter) view returns (bool)`: Checks if an address is a minter.
        19. `getSkillDetails(uint256 skillId) view returns (string memory name, string memory description, uint8 levelCap, bool isActive, SkillDependency[] memory dependencies)`: Gets details of a specific skill.
        20. `getUserSkillLevel(address user, uint256 skillId) view returns (uint8)`: Gets the level of a specific skill for a user. Returns 0 if not possessed.
        21. `userHasSkill(address user, uint256 skillId) view returns (bool)`: Checks if a user possesses a skill (level > 0).
        22. `userMeetsDependency(address user, uint256 skillId, uint256 dependencySkillId, uint8 requiredLevel) view returns (bool)`: Helper to check if a user meets a single dependency requirement.
        23. `userMeetsAllDependencies(address user, uint256 skillId) view returns (bool)`: Checks if a user meets all dependencies for a given skill.
        24. `getDefinedSkillIds() view returns (uint256[] memory)`: Returns an array of all currently defined skill IDs.
        25. `getUserSkillIds(address user) view returns (uint256[] memory)`: Returns an array of skill IDs possessed by a user.
        26. `getTotalSkillsDefined() view returns (uint256)`: Returns the total number of defined skills.
        27. `getSkillDependencyCount(uint256 skillId) view returns (uint256)`: Returns the number of dependencies for a given skill.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// --- Outline & Function Summary ---
// 1. Contract: SoulboundSkillTree
// 2. Concept: Manages a non-transferable record of user skills and levels within a defined skill tree structure.
//    Skills are granted by approved minters based on defined dependencies.
// 3. State Variables: _owner, skills, userSkills, isMinter, skillIds
// 4. Structs: SkillDependency, Skill
// 5. Events: OwnershipTransferred, MinterAdded, MinterRemoved, SkillAdded, SkillUpdated,
//    SkillActivated, SkillDeactivated, SkillGranted, SkillUpgraded, SkillLevelSet, SkillRevoked
// 6. Modifiers: onlyOwner, onlyMinter
// 7. Functions (27 Total):
//    - Admin/Setup (Owner Only): constructor, transferOwnership, addMinter, removeMinter, addSkill, updateSkill, deactivateSkill, activateSkill
//    - Skill Management (Minter or Owner Only): grantSkill, upgradeSkill, setLevel, revokeSkill, batchGrantSkills, batchUpgradeSkills, batchSetLevel, batchRevokeSkills
//    - Querying/Viewing (Public/View): getOwner, isMinter, getSkillDetails, getUserSkillLevel, userHasSkill, userMeetsDependency, userMeetsAllDependencies, getDefinedSkillIds, getUserSkillIds, getTotalSkillsDefined, getSkillDependencyCount
// -------------------------------------


contract SoulboundSkillTree {

    // --- State Variables ---

    address private _owner;
    // Maps skill ID to Skill definition
    mapping(uint256 => Skill) public skills;
    // Maps user address to a map of skill ID to their level in that skill
    mapping(address => mapping(uint256 => uint8)) public userSkills;
    // Maps address to bool indicating if they are a minter
    mapping(address => bool) public isMinter;
    // Array to keep track of all defined skill IDs (for iteration)
    uint256[] internal skillIds;
    // To prevent adding duplicate skill IDs
    mapping(uint256 => bool) internal skillIdExists;


    // --- Structs ---

    struct SkillDependency {
        uint256 skillId; // The prerequisite skill ID
        uint8 requiredLevel; // The minimum level required in the prerequisite skill
    }

    struct Skill {
        string name;
        string description;
        uint8 levelCap; // Max level for this skill (1-255)
        SkillDependency[] dependencies; // List of prerequisite skills and required levels
        bool isActive; // Can this skill be granted/upgraded?
    }

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event SkillAdded(uint256 indexed skillId, string name, uint8 levelCap);
    event SkillUpdated(uint256 indexed skillId, string name, uint8 levelCap);
    event SkillActivated(uint256 indexed skillId);
    event SkillDeactivated(uint256 indexed skillId);
    event SkillGranted(address indexed user, uint256 indexed skillId); // Granted at level 1
    event SkillUpgraded(address indexed user, uint256 indexed skillId, uint8 newLevel);
    event SkillLevelSet(address indexed user, uint256 indexed skillId, uint8 level); // Direct level set
    event SkillRevoked(address indexed user, uint256 indexed skillId); // Level set to 0

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender] || msg.sender == _owner, "SoulboundSkillTree: caller is not a minter or owner");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // --- Admin/Setup Functions (Owner Only) ---

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Adds an address to the list of authorized minters.
     * Minters can grant and upgrade skills.
     */
    function addMinter(address minter) public onlyOwner {
        require(minter != address(0), "SoulboundSkillTree: minter is the zero address");
        require(!isMinter[minter], "SoulboundSkillTree: minter already added");
        isMinter[minter] = true;
        emit MinterAdded(minter);
    }

    /**
     * @dev Removes an address from the list of authorized minters.
     */
    function removeMinter(address minter) public onlyOwner {
        require(isMinter[minter], "SoulboundSkillTree: address is not a minter");
        isMinter[minter] = false;
        emit MinterRemoved(minter);
    }

    /**
     * @dev Defines a new skill in the skill tree.
     * Can only be called by the owner.
     * @param skillId Unique identifier for the skill.
     * @param name Display name of the skill.
     * @param description Description of the skill.
     * @param levelCap Maximum level this skill can reach (1-255).
     * @param dependencies Array of prerequisite skills and their required levels.
     */
    function addSkill(uint256 skillId, string memory name, string memory description, uint8 levelCap, SkillDependency[] memory dependencies) public onlyOwner {
        require(!skillIdExists[skillId], "SoulboundSkillTree: skillId already exists");
        require(levelCap > 0, "SoulboundSkillTree: levelCap must be greater than 0");

        for (uint i = 0; i < dependencies.length; i++) {
            require(skillIdExists[dependencies[i].skillId], "SoulboundSkillTree: dependency skill does not exist");
            require(dependencies[i].skillId != skillId, "SoulboundSkillTree: skill cannot depend on itself");
            require(dependencies[i].requiredLevel > 0, "SoulboundSkillTree: dependency level must be greater than 0");
            // Optional: Add check for circular dependencies if the tree depth is limited or traversal is used
        }

        skills[skillId] = Skill(name, description, levelCap, dependencies, true);
        skillIds.push(skillId);
        skillIdExists[skillId] = true;

        emit SkillAdded(skillId, name, levelCap);
    }

    /**
     * @dev Updates the details of an existing skill definition.
     * Can only be called by the owner.
     * @param skillId Unique identifier for the skill to update.
     * @param name New display name.
     * @param description New description.
     * @param levelCap New maximum level.
     * @param dependencies New array of prerequisite skills and their required levels.
     */
    function updateSkill(uint256 skillId, string memory name, string memory description, uint8 levelCap, SkillDependency[] memory dependencies) public onlyOwner {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(levelCap > 0, "SoulboundSkillTree: levelCap must be greater than 0");
        // Note: Updating dependencies after users have acquired the skill might lead to inconsistent states
        // depending on desired behavior. This implementation allows it. Add specific checks if needed.

        for (uint i = 0; i < dependencies.length; i++) {
            require(skillIdExists[dependencies[i].skillId], "SoulboundSkillTree: dependency skill does not exist");
             require(dependencies[i].skillId != skillId, "SoulboundSkillTree: skill cannot depend on itself");
             require(dependencies[i].requiredLevel > 0, "SoulboundSkillTree: dependency level must be greater than 0");
        }

        Skill storage skill = skills[skillId];
        skill.name = name;
        skill.description = description;
        skill.levelCap = levelCap;
        skill.dependencies = dependencies; // Replaces existing dependencies

        emit SkillUpdated(skillId, name, levelCap);
    }

     /**
     * @dev Deactivates a skill, preventing it from being granted or upgraded.
     * Does not affect users who already possess the skill.
     * Can only be called by the owner.
     * @param skillId Unique identifier for the skill to deactivate.
     */
    function deactivateSkill(uint256 skillId) public onlyOwner {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(skills[skillId].isActive, "SoulboundSkillTree: skill is already inactive");
        skills[skillId].isActive = false;
        emit SkillDeactivated(skillId);
    }

    /**
     * @dev Activates a previously deactivated skill.
     * Can only be called by the owner.
     * @param skillId Unique identifier for the skill to activate.
     */
    function activateSkill(uint256 skillId) public onlyOwner {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(!skills[skillId].isActive, "SoulboundSkillTree: skill is already active");
        skills[skillId].isActive = true;
        emit SkillActivated(skillId);
    }


    // --- Skill Management Functions (Minter or Owner Only) ---

    /**
     * @dev Grants a skill to a user at level 1.
     * Requires caller to be a minter or owner.
     * Requires skill to be active.
     * Requires user to meet all skill dependencies.
     * Requires user not to already have the skill (level 0).
     * @param user The address to grant the skill to.
     * @param skillId The ID of the skill to grant.
     */
    function grantSkill(address user, uint256 skillId) public onlyMinter {
        require(user != address(0), "SoulboundSkillTree: user is zero address");
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(skills[skillId].isActive, "SoulboundSkillTree: skill is inactive");
        require(userSkills[user][skillId] == 0, "SoulboundSkillTree: user already has this skill");
        require(userMeetsAllDependencies(user, skillId), "SoulboundSkillTree: user does not meet dependencies");
        require(skills[skillId].levelCap >= 1, "SoulboundSkillTree: skill level cap is less than 1");


        userSkills[user][skillId] = 1;
        emit SkillGranted(user, skillId);
        emit SkillLevelSet(user, skillId, 1); // Also emit generic level set event
    }

    /**
     * @dev Upgrades a user's level in a specific skill by 1.
     * Requires caller to be a minter or owner.
     * Requires skill to be active.
     * Requires user to already possess the skill (level > 0).
     * Requires user's current level to be less than the skill's level cap.
     * Requires user to meet all skill dependencies for the *new* level (optional, this implementation checks dependencies only on grant/set > 0).
     * @param user The address whose skill is being upgraded.
     * @param skillId The ID of the skill to upgrade.
     */
    function upgradeSkill(address user, uint256 skillId) public onlyMinter {
        require(user != address(0), "SoulboundSkillTree: user is zero address");
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(skills[skillId].isActive, "SoulboundSkillTree: skill is inactive");
        require(userSkills[user][skillId] > 0, "SoulboundSkillTree: user does not have this skill");
        uint8 currentLevel = userSkills[user][skillId];
        uint8 levelCap = skills[skillId].levelCap;
        require(currentLevel < levelCap, "SoulboundSkillTree: skill is already at max level");

        userSkills[user][skillId] = currentLevel + 1;
        emit SkillUpgraded(user, skillId, currentLevel + 1);
        emit SkillLevelSet(user, skillId, currentLevel + 1); // Also emit generic level set event
    }

    /**
     * @dev Sets a user's level for a specific skill directly.
     * Allows setting level to 0 (revoking), granting (setting to > 0), or upgrading.
     * Requires caller to be a minter or owner.
     * Requires skill to be active IF setting level > 0.
     * Requires user to meet all skill dependencies IF setting level > 0.
     * @param user The address whose skill level is being set.
     * @param skillId The ID of the skill.
     * @param level The desired level (0 to levelCap).
     */
    function setLevel(address user, uint256 skillId, uint8 level) public onlyMinter {
         require(user != address(0), "SoulboundSkillTree: user is zero address");
         require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
         uint8 currentLevel = userSkills[user][skillId];

         if (level > 0) {
             require(skills[skillId].isActive, "SoulboundSkillTree: skill is inactive");
             require(level <= skills[skillId].levelCap, "SoulboundSkillTree: level exceeds skill level cap");
             require(userMeetsAllDependencies(user, skillId), "SoulboundSkillTree: user does not meet dependencies");

             if (currentLevel == 0) {
                 emit SkillGranted(user, skillId); // Treat setting from 0 to > 0 as granting
             } else if (level > currentLevel) {
                 emit SkillUpgraded(user, skillId, level); // Treat increasing level as upgrade
             } // No specific event if level is decreased (but > 0) or set to current level
         } else { // Setting level to 0
             if (currentLevel > 0) {
                 emit SkillRevoked(user, skillId); // Treat setting to 0 as revoking
             }
         }

         userSkills[user][skillId] = level;
         if (currentLevel != level) {
             emit SkillLevelSet(user, skillId, level);
         }
    }

    /**
     * @dev Removes a skill from a user by setting their level to 0.
     * Requires caller to be a minter or owner.
     * @param user The address to remove the skill from.
     * @param skillId The ID of the skill to remove.
     */
    function revokeSkill(address user, uint256 skillId) public onlyMinter {
        require(user != address(0), "SoulboundSkillTree: user is zero address");
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(userSkills[user][skillId] > 0, "SoulboundSkillTree: user does not have this skill");

        userSkills[user][skillId] = 0;
        emit SkillRevoked(user, skillId);
        emit SkillLevelSet(user, skillId, 0); // Also emit generic level set event
    }

    /**
     * @dev Grants a skill to multiple users at level 1 in a single transaction.
     * Calls `grantSkill` for each user.
     * @param users Array of addresses to grant the skill to.
     * @param skillId The ID of the skill to grant.
     */
    function batchGrantSkills(address[] memory users, uint256 skillId) public onlyMinter {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(skills[skillId].isActive, "SoulboundSkillTree: skill is inactive");
        require(skills[skillId].levelCap >= 1, "SoulboundSkillTree: skill level cap is less than 1");

        // Check dependencies once for the skill itself, then iterate users
        require(userMeetsAllDependencies(users[0], skillId), "SoulboundSkillTree: first user does not meet dependencies (check others individually)"); // Basic check, individual checks inside loop are more robust

        for (uint i = 0; i < users.length; i++) {
             address user = users[i];
             // Re-check for each user as dependency requirements might differ
             if (user != address(0) && userSkills[user][skillId] == 0 && userMeetsAllDependencies(user, skillId)) {
                 userSkills[user][skillId] = 1;
                 emit SkillGranted(user, skillId);
                 emit SkillLevelSet(user, skillId, 1);
             }
             // Note: This loop doesn't revert on individual failures (e.g., user already has skill, dependency failure).
             // Add more rigorous checks and potential reverts if needed for atomicity.
        }
    }

     /**
     * @dev Upgrades a skill for multiple users in a single transaction.
     * Calls `upgradeSkill` logic for each user.
     * @param users Array of addresses to upgrade the skill for.
     * @param skillId The ID of the skill to upgrade.
     */
    function batchUpgradeSkills(address[] memory users, uint256 skillId) public onlyMinter {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        require(skills[skillId].isActive, "SoulboundSkillTree: skill is inactive");
        uint8 levelCap = skills[skillId].levelCap;

         for (uint i = 0; i < users.length; i++) {
             address user = users[i];
             uint8 currentLevel = userSkills[user][skillId];

             if (user != address(0) && currentLevel > 0 && currentLevel < levelCap) {
                 userSkills[user][skillId] = currentLevel + 1;
                 emit SkillUpgraded(user, skillId, currentLevel + 1);
                 emit SkillLevelSet(user, skillId, currentLevel + 1);
             }
             // Note: Similar to batchGrant, this skips users that fail checks without reverting.
        }
    }

    /**
     * @dev Sets the level of a skill for multiple users in a single transaction.
     * Calls `setLevel` logic for each user.
     * @param users Array of addresses.
     * @param skillId The ID of the skill.
     * @param level The desired level.
     */
    function batchSetLevel(address[] memory users, uint256 skillId, uint8 level) public onlyMinter {
         require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");

         if (level > 0) {
             require(skills[skillId].isActive, "SoulboundSkillTree: skill is inactive if level > 0");
             require(level <= skills[skillId].levelCap, "SoulboundSkillTree: level exceeds skill level cap");
             // Note: Dependencies are not checked in batchSetLevel for efficiency.
             // If strict dependency checks are needed for each user in a batch set > 0,
             // this function would need significant modification (e.g., separate logic or individual calls).
             // This assumes the caller ensures dependencies are met for users being set to level > 0.
         }

         for (uint i = 0; i < users.length; i++) {
             address user = users[i];
             uint8 currentLevel = userSkills[user][skillId];

             if (user != address(0) && currentLevel != level) {
                 userSkills[user][skillId] = level;
                 emit SkillLevelSet(user, skillId, level);

                 if (level == 0 && currentLevel > 0) {
                     emit SkillRevoked(user, skillId);
                 } else if (level > 0 && currentLevel == 0) {
                     emit SkillGranted(user, skillId);
                 } else if (level > currentLevel) {
                     emit SkillUpgraded(user, skillId, level);
                 }
             }
         }
    }

    /**
     * @dev Revokes a skill from multiple users in a single transaction.
     * Calls `revokeSkill` logic for each user.
     * @param users Array of addresses to revoke the skill from.
     * @param skillId The ID of the skill to revoke.
     */
    function batchRevokeSkills(address[] memory users, uint256 skillId) public onlyMinter {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");

        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            if (user != address(0) && userSkills[user][skillId] > 0) {
                 userSkills[user][skillId] = 0;
                 emit SkillRevoked(user, skillId);
                 emit SkillLevelSet(user, skillId, 0);
             }
        }
    }

    // --- Querying/Viewing Functions (Public) ---

    /**
     * @dev Returns the address of the current contract owner.
     */
    function getOwner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Checks if a given address is an authorized minter.
     */
    function isMinter(address minter) public view returns (bool) {
        return isMinter[minter];
    }

    /**
     * @dev Gets the details of a specific skill definition.
     * @param skillId The ID of the skill.
     * @return name, description, levelCap, isActive, dependencies.
     */
    function getSkillDetails(uint256 skillId) public view returns (string memory name, string memory description, uint8 levelCap, bool isActive, SkillDependency[] memory dependencies) {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        Skill storage skill = skills[skillId];
        return (skill.name, skill.description, skill.levelCap, skill.isActive, skill.dependencies);
    }

    /**
     * @dev Gets the level a user has in a specific skill.
     * Returns 0 if the user does not possess the skill.
     * @param user The address of the user.
     * @param skillId The ID of the skill.
     * @return The user's level in the skill.
     */
    function getUserSkillLevel(address user, uint256 skillId) public view returns (uint8) {
        // No need to require skillIdExists here, as mapping returns default 0
        // require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist"); // Optional: add this if you want to distinguish non-existent skill from level 0
        return userSkills[user][skillId];
    }

    /**
     * @dev Checks if a user possesses a skill (level > 0).
     * @param user The address of the user.
     * @param skillId The ID of the skill.
     * @return True if the user has the skill at level > 0, false otherwise.
     */
    function userHasSkill(address user, uint256 skillId) public view returns (bool) {
         // No need to require skillIdExists here
        return userSkills[user][skillId] > 0;
    }

     /**
     * @dev Helper function to check if a user meets a single skill dependency requirement.
     * @param user The address of the user.
     * @param skillId The ID of the skill whose dependency is being checked.
     * @param dependencySkillId The ID of the required prerequisite skill.
     * @param requiredLevel The minimum level needed in the prerequisite skill.
     * @return True if the user meets the dependency, false otherwise.
     */
    function userMeetsDependency(address user, uint256 skillId, uint256 dependencySkillId, uint8 requiredLevel) public view returns (bool) {
        // We don't necessarily need to check if skillId or dependencySkillId exist here,
        // as this is an internal helper primarily used with valid skill data.
        // The main functions calling this should ensure validity.
        // If used externally, add checks.
        return userSkills[user][dependencySkillId] >= requiredLevel;
    }

    /**
     * @dev Checks if a user meets all dependencies required for a given skill.
     * @param user The address of the user.
     * @param skillId The ID of the skill to check dependencies for.
     * @return True if the user meets all dependencies, false otherwise.
     */
    function userMeetsAllDependencies(address user, uint256 skillId) public view returns (bool) {
        require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
        Skill storage skill = skills[skillId];
        for (uint i = 0; i < skill.dependencies.length; i++) {
            SkillDependency storage dep = skill.dependencies[i];
            if (userSkills[user][dep.skillId] < dep.requiredLevel) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Returns an array of all defined skill IDs in the tree.
     */
    function getDefinedSkillIds() public view returns (uint256[] memory) {
        return skillIds;
    }

     /**
     * @dev Returns an array of skill IDs that a user possesses (level > 0).
     * Note: This iterates through all defined skills. Can be gas-intensive
     * if there are many skills. Consider alternative indexing or off-chain retrieval
     * for large skill trees.
     * @param user The address of the user.
     * @return An array of skill IDs the user has.
     */
    function getUserSkillIds(address user) public view returns (uint256[] memory) {
        uint256[] memory possessedSkillIds = new uint256[](skillIds.length);
        uint256 count = 0;
        for (uint i = 0; i < skillIds.length; i++) {
            uint256 skillId = skillIds[i];
            if (userSkills[user][skillId] > 0) {
                possessedSkillIds[count] = skillId;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = possessedSkillIds[i];
        }
        return result;
    }

    /**
     * @dev Returns the total number of unique skills defined in the tree.
     */
    function getTotalSkillsDefined() public view returns (uint256) {
        return skillIds.length;
    }

     /**
     * @dev Returns the number of dependencies for a specific skill.
     * @param skillId The ID of the skill.
     * @return The number of dependencies.
     */
    function getSkillDependencyCount(uint256 skillId) public view returns (uint256) {
         require(skillIdExists[skillId], "SoulboundSkillTree: skillId does not exist");
         return skills[skillId].dependencies.length;
    }
}
```