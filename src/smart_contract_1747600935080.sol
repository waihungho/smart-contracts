Okay, let's design a smart contract that represents a decentralized "Adeptness" or "Skill Progression" system. Users interact with the contract to earn experience points (XP), level up, unlock skills, and earn achievements based on on-chain actions or simulated tasks. This incorporates gamification, dynamic user state, conditional logic, and achievement tracking, going beyond typical token or simple utility contracts.

We'll make it relatively complex with various ways to earn points, unlock features, and check status, fulfilling the requirement for many functions.

**Concept:** **AdeptArena** - A contract where users register, perform certain "tasks" (simulated on-chain actions), earn XP, gain levels and skill points, unlock skills that grant in-contract benefits, and earn achievements.

**Outline and Function Summary:**

1.  **Outline:**
    *   Pragma and Imports
    *   Contract Definition (with Ownable and Pausable)
    *   Custom Errors
    *   Events
    *   Struct Definitions (`User`, `Skill`, `Achievement`)
    *   State Variables (mappings for users, skills, achievements; counters, level thresholds)
    *   Modifiers
    *   Constructor
    *   Admin Functions (Setup and Management)
    *   User Interaction Functions (Earning, Spending, Checking)
    *   Achievement System Functions
    *   Skill System Functions
    *   Utility/View Functions
    *   Internal/Helper Functions
    *   Receive Ether Function

2.  **Function Summary:**

    *   **Admin Functions:**
        *   `addSkill`: Define a new unlockable skill with prerequisites, cost, etc.
        *   `updateSkill`: Modify properties of an existing skill.
        *   `removeSkill`: Remove a skill (careful with dependencies).
        *   `addAchievement`: Define a new achievement with conditions and rewards.
        *   `updateAchievement`: Modify properties of an existing achievement.
        *   `removeAchievement`: Remove an achievement.
        *   `setLevelThresholds`: Set the XP required to reach each level.
        *   `grantXP`: Manually grant XP to a user (e.g., for off-chain events).
        *   `grantSkillPoints`: Manually grant skill points.
        *   `withdrawFunds`: Withdraw any accumulated Ether (e.g., from fees or failed interactions).
        *   `pause`: Pause user interactions (from Pausable).
        *   `unpause`: Unpause user interactions (from Pausable).

    *   **User Interaction Functions:**
        *   `registerUser`: Initialize a user's profile.
        *   `earnXP_SimulatedTask`: A function simulating an on-chain task that awards XP if conditions are met.
        *   `spendSkillPoints`: Use earned skill points to unlock a defined skill.
        *   `triggerAchievementCheck`: Allows a user to manually check if they qualify for any achievements they haven't unlocked.
        *   `performAction_RequiresSkill`: Example function demonstrating a task only accessible with a specific unlocked skill.
        *   `predictOutcome_Simulated`: Users make a prediction, earning bonus XP/points if correct based on simple contract logic.

    *   **Utility/View Functions (Read-Only):**
        *   `getUserDetails`: Retrieve all details for a specific user.
        *   `getUserLevel`: Get a user's current level.
        *   `getUserXP`: Get a user's current XP.
        *   `getUserSkillPoints`: Get a user's current skill points.
        *   `hasSkill`: Check if a user has unlocked a specific skill.
        *   `hasAchievement`: Check if a user has earned a specific achievement.
        *   `getUnlockedSkills`: Get a list of skill IDs unlocked by a user.
        *   `getEarnedAchievements`: Get a list of achievement IDs earned by a user.
        *   `getSkillDetails`: Get details for a specific skill ID.
        *   `getAchievementDetails`: Get details for a specific achievement ID.
        *   `getAllSkillIds`: Get a list of all defined skill IDs.
        *   `getAllAchievementIds`: Get a list of all defined achievement IDs.
        *   `getLevelThreshold`: Get the XP needed for a specific level.

    *   **Internal/Helper Functions:**
        *   `_grantXP`: Internal logic to add XP, check for level up, and potentially check for achievements.
        *   `_calculateLevel`: Determine a user's current level based on XP and thresholds.
        *   `_checkAchievementCondition`: Internal logic to verify if a user meets the condition for a *specific* achievement ID.
        *   `_checkAndUnlockAchievements`: Internal helper to check for *all* applicable achievements for a user.
        *   `_countUnlockedSkills`: Internal helper to count how many skills a user has unlocked.

    *   **Receive Function:**
        *   `receive`: Allows the contract to accept Ether.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. Pragma and Imports
// 2. Contract Definition (AdeptArena with Ownable, Pausable, ReentrancyGuard)
// 3. Custom Errors
// 4. Events
// 5. Struct Definitions (User, Skill, Achievement)
// 6. State Variables (users, skills, achievements, counters, thresholds, etc.)
// 7. Modifiers
// 8. Constructor
// 9. Admin Functions (Setup & Management) - 12+ functions
// 10. User Interaction Functions (Earning, Spending, Checking) - 6+ functions
// 11. Utility/View Functions (Read-Only Getters) - 12+ functions
// 12. Internal/Helper Functions - 5+ functions
// 13. Receive Ether Function
// Total >= 20 functions

// Function Summary:
// Admin: addSkill, updateSkill, removeSkill, addAchievement, updateAchievement, removeAchievement, setLevelThresholds, grantXP, grantSkillPoints, withdrawFunds, pause, unpause
// User Interaction: registerUser, earnXP_SimulatedTask, spendSkillPoints, triggerAchievementCheck, performAction_RequiresSkill, predictOutcome_Simulated
// Utility/View: getUserDetails, getUserLevel, getUserXP, getUserSkillPoints, hasSkill, hasAchievement, getUnlockedSkills, getEarnedAchievements, getSkillDetails, getAchievementDetails, getAllSkillIds, getAllAchievementIds, getLevelThreshold
// Internal: _grantXP, _calculateLevel, _checkAchievementCondition, _checkAndUnlockAchievements, _countUnlockedSkills
// Receive: receive

contract AdeptArena is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Custom Errors ---
    error UserNotFound();
    error UserAlreadyRegistered();
    error InsufficientXP(); // Currently not used for spending, but good to have
    error InsufficientSkillPoints();
    error SkillNotFound();
    error AchievementNotFound();
    error SkillAlreadyUnlocked();
    error LevelTooLow();
    error PrerequisiteSkillsNotMet();
    error AchievementAlreadyUnlocked();
    error InvalidLevelThresholds();
    error InvalidPrediction();
    error TaskConditionNotMet();
    error CooldownNotElapsed(uint256 timeRemaining);

    // --- Events ---
    event UserRegistered(address indexed user);
    event XPReceived(address indexed user, uint256 amount, uint256 newTotalXP);
    event LevelUp(address indexed user, uint256 oldLevel, uint256 newLevel);
    event SkillPointsEarned(address indexed user, uint256 amount, uint256 newTotalPoints);
    event SkillUnlocked(address indexed user, uint256 indexed skillId);
    event AchievementUnlocked(address indexed user, uint256 indexed achievementId);
    event TaskCompleted(address indexed user, uint256 indexed taskId, uint256 xpEarned, uint256 pointsEarned);
    event PredictionSuccessful(address indexed user, uint256 bonusXP, uint256 bonusPoints);

    // --- Struct Definitions ---

    struct User {
        bool isRegistered;
        uint256 xp;
        uint256 level;
        uint256 skillPoints;
        // Mapping skillId => unlocked?
        mapping(uint256 => bool) unlockedSkills;
        // Mapping achievementId => earned?
        mapping(uint256 => bool) earnedAchievements;
        uint256 lastActionTime; // Cooldown mechanism
    }

    struct Skill {
        string name;
        string effectDescription; // Describes the conceptual effect (implementation is in related functions)
        uint256 costSkillPoints;
        uint256 requiredLevel;
        uint256[] prerequisiteSkillIds;
        bool exists; // To track if ID is active
    }

    struct Achievement {
        string name;
        string description;
        // Note: The 'condition' is implemented in the _checkAchievementCondition internal function.
        uint256 rewardXP;
        uint256 rewardSkillPoints;
        bool exists; // To track if ID is active
    }

    // --- State Variables ---

    mapping(address => User) public users;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Achievement) public achievements;

    Counters.Counter private _skillIds;
    Counters.Counter private _achievementIds;

    // XP required to reach a specific level (index = level - 1)
    // e.g., levelThresholds[0] = XP for Level 1, levelThresholds[1] = XP for Level 2, etc.
    // Level 0 requires 0 XP. Level 1 requires levelThresholds[0], etc.
    uint256[] public levelThresholds;

    // Cooldown for earning XP from simulated tasks
    uint256 public constant TASK_COOLDOWN = 1 minutes;

    // --- Modifiers ---

    modifier userRegistered() {
        if (!users[msg.sender].isRegistered) {
            revert UserNotFound();
        }
        _;
    }

    // --- Constructor ---

    constructor(uint256[] memory _initialLevelThresholds) Ownable(msg.sender) {
        _setLevelThresholds(_initialLevelThresholds);
    }

    // --- Admin Functions ---

    /**
     * @notice Sets the XP thresholds required for each level.
     * @param _thresholds Array where index i is the minimum XP for level i+1.
     * Requires thresholds to be strictly increasing.
     */
    function setLevelThresholds(uint256[] memory _thresholds) external onlyOwner {
        _setLevelThresholds(_thresholds);
    }

    function _setLevelThresholds(uint256[] memory _thresholds) internal {
         if (_thresholds.length == 0) {
             revert InvalidLevelThresholds();
         }
         // Check if thresholds are strictly increasing
         for (uint i = 0; i < _thresholds.length - 1; i++) {
             if (_thresholds[i] >= _thresholds[i+1]) {
                 revert InvalidLevelThresholds();
             }
         }
         levelThresholds = _thresholds;
    }


    /**
     * @notice Adds a new skill definition.
     * @param _name Name of the skill.
     * @param _effectDescription Description of the skill's effect.
     * @param _cost Skill points required to unlock.
     * @param _requiredLevel Minimum user level to unlock.
     * @param _prerequisiteSkillIds Array of skill IDs that must be unlocked first.
     * @return The ID of the newly added skill.
     */
    function addSkill(
        string calldata _name,
        string calldata _effectDescription,
        uint256 _cost,
        uint256 _requiredLevel,
        uint256[] calldata _prerequisiteSkillIds
    ) external onlyOwner returns (uint256) {
        _skillIds.increment();
        uint256 newId = _skillIds.current();

        // Basic validation for prerequisites (check if they exist)
        for(uint i = 0; i < _prerequisiteSkillIds.length; i++) {
            if (!skills[_prerequisiteSkillIds[i]].exists) {
                revert SkillNotFound(); // Prerequisite doesn't exist
            }
             // Prevent self-prerequisite
            if (_prerequisiteSkillIds[i] == newId) {
                revert InvalidSkillID(); // Cannot be prerequisite for itself
            }
        }


        skills[newId] = Skill({
            name: _name,
            effectDescription: _effectDescription,
            costSkillPoints: _cost,
            requiredLevel: _requiredLevel,
            prerequisiteSkillIds: _prerequisiteSkillIds,
            exists: true
        });

        return newId;
    }

    /**
     * @notice Updates an existing skill definition.
     * @param _skillId ID of the skill to update.
     * @param _name New name.
     * @param _effectDescription New description.
     * @param _cost New skill point cost.
     * @param _requiredLevel New required level.
     * @param _prerequisiteSkillIds New array of prerequisite skill IDs.
     */
    function updateSkill(
        uint256 _skillId,
        string calldata _name,
        string calldata _effectDescription,
        uint256 _cost,
        uint256 _requiredLevel,
        uint256[] calldata _prerequisiteSkillIds
    ) external onlyOwner {
        if (!skills[_skillId].exists) {
            revert SkillNotFound();
        }

         // Basic validation for prerequisites (check if they exist)
        for(uint i = 0; i < _prerequisiteSkillIds.length; i++) {
            if (!skills[_prerequisiteSkillIds[i]].exists) {
                revert SkillNotFound(); // Prerequisite doesn't exist
            }
            // Prevent self-prerequisite
            if (_prerequisiteSkillIds[i] == _skillId) {
                revert InvalidSkillID(); // Cannot be prerequisite for itself
            }
        }

        skills[_skillId].name = _name;
        skills[_skillId].effectDescription = _effectDescription;
        skills[_skillId].costSkillPoints = _cost;
        skills[_skillId].requiredLevel = _requiredLevel;
        skills[_skillId].prerequisiteSkillIds = _prerequisiteSkillIds;
    }

    /**
     * @notice Removes a skill definition. Does not affect users who already unlocked it.
     * @param _skillId ID of the skill to remove.
     */
    function removeSkill(uint256 _skillId) external onlyOwner {
         if (!skills[_skillId].exists) {
            revert SkillNotFound();
        }
        // Note: This just marks it as non-existent. Data remains to avoid state corruption.
        // Consider checking if any *other* active skills have this as a prerequisite in a real system.
        skills[_skillId].exists = false;
        // Optionally could clear other fields, but 'exists' is sufficient for checks.
    }

    /**
     * @notice Adds a new achievement definition.
     * @param _name Name of the achievement.
     * @param _description Description.
     * @param _rewardXP XP awarded upon earning.
     * @param _rewardSkillPoints Skill points awarded upon earning.
     * @return The ID of the newly added achievement.
     */
    function addAchievement(
        string calldata _name,
        string calldata _description,
        uint256 _rewardXP,
        uint256 _rewardSkillPoints
    ) external onlyOwner returns (uint256) {
        _achievementIds.increment();
        uint256 newId = _achievementIds.current();

        achievements[newId] = Achievement({
            name: _name,
            description: _description,
            rewardXP: _rewardXP,
            rewardSkillPoints: _rewardSkillPoints,
            exists: true
        });

        return newId;
    }

    /**
     * @notice Updates an existing achievement definition.
     * @param _achievementId ID of the achievement to update.
     * @param _name New name.
     * @param _description New description.
     * @param _rewardXP New XP reward.
     * @param _rewardSkillPoints New skill point reward.
     */
    function updateAchievement(
        uint256 _achievementId,
        string calldata _name,
        string calldata _description,
        uint256 _rewardXP,
        uint256 _rewardSkillPoints
    ) external onlyOwner {
        if (!achievements[_achievementId].exists) {
            revert AchievementNotFound();
        }

        achievements[_achievementId].name = _name;
        achievements[_achievementId].description = _description;
        achievements[_achievementId].rewardXP = _rewardXP;
        achievements[_achievementId].rewardSkillPoints = _rewardSkillPoints;
    }

     /**
     * @notice Removes an achievement definition. Does not affect users who already earned it.
     * @param _achievementId ID of the achievement to remove.
     */
    function removeAchievement(uint256 _achievementId) external onlyOwner {
         if (!achievements[_achievementId].exists) {
            revert AchievementNotFound();
        }
        achievements[_achievementId].exists = false;
    }


    /**
     * @notice Manually grants XP to a user.
     * @param _user Address of the user.
     * @param _amount Amount of XP to grant.
     */
    function grantXP(address _user, uint256 _amount) external onlyOwner {
        if (!users[_user].isRegistered) {
            revert UserNotFound();
        }
        _grantXP(_user, _amount);
        // Achievement check is done inside _grantXP
    }

     /**
     * @notice Manually grants Skill Points to a user.
     * @param _user Address of the user.
     * @param _amount Amount of Skill Points to grant.
     */
    function grantSkillPoints(address _user, uint256 _amount) external onlyOwner {
         if (!users[_user].isRegistered) {
            revert UserNotFound();
        }
        users[_user].skillPoints += _amount;
         emit SkillPointsEarned(_user, _amount, users[_user].skillPoints);
    }

    /**
     * @notice Allows owner to withdraw any Ether held by the contract.
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // Inherited pause/unpause from Pausable

    // --- User Interaction Functions ---

    /**
     * @notice Registers a new user in the AdeptArena.
     */
    function registerUser() external whenNotPaused {
        if (users[msg.sender].isRegistered) {
            revert UserAlreadyRegistered();
        }

        users[msg.sender].isRegistered = true;
        users[msg.sender].xp = 0;
        users[msg.sender].level = 0;
        users[msg.sender].skillPoints = 0;
        users[msg.sender].lastActionTime = 0; // Or block.timestamp if starting cooldown immediately

        emit UserRegistered(msg.sender);

        // Grant initial XP/points or achievement if needed
        _grantXP(msg.sender, 50); // Example: grant 50 XP for registering
        users[msg.sender].skillPoints += 5; // Example: grant 5 points
        emit SkillPointsEarned(msg.sender, 5, users[msg.sender].skillPoints);
        _checkAndUnlockAchievements(msg.sender); // Check for registration achievement etc.
    }

     /**
     * @notice Simulates a task completion that awards XP and skill points.
     * This function includes a simple on-chain condition and a cooldown.
     * In a real system, this logic would be more complex or tied to external events via oracles.
     * @param _taskInput A simple input parameter for the simulated task condition.
     */
    function earnXP_SimulatedTask(uint256 _taskInput) external userRegistered whenNotPaused nonReentrant {
        User storage user = users[msg.sender];
        uint256 timeSinceLastAction = block.timestamp - user.lastActionTime;

        if (timeSinceLastAction < TASK_COOLDOWN) {
            revert CooldownNotElapsed(TASK_COOLDOWN - timeSinceLastAction);
        }

        // --- Simulated Task Logic ---
        // Example Condition: User input must match a simple calculation based on block data
        // This is a basic example; real tasks would be more complex or external.
        uint256 requiredInput = (block.timestamp % 10) + (block.number % 5); // Simple dynamic target
        uint256 taskId = 1; // Example task ID

        if (_taskInput != requiredInput) {
            revert TaskConditionNotMet();
        }
        // --- End Simulated Task Logic ---

        uint256 xpReward = 100; // Base reward
        uint256 pointsReward = 2; // Base reward

        // Optional: Add bonus XP/points based on level, skills, or other factors
        if (user.level >= 5) xpReward += 20;
        if (user.unlockedSkills[3]) xpReward += 50; // Example: Bonus for having skill ID 3

        _grantXP(msg.sender, xpReward);
        user.skillPoints += pointsReward;
        user.lastActionTime = block.timestamp;

        emit SkillPointsEarned(msg.sender, pointsReward, user.skillPoints);
        emit TaskCompleted(msg.sender, taskId, xpReward, pointsReward);

        _checkAndUnlockAchievements(msg.sender); // Check for achievements after earning XP/points
    }


    /**
     * @notice Allows a user to spend skill points to unlock a defined skill.
     * Checks for prerequisites, level, and point cost.
     * @param _skillId The ID of the skill to unlock.
     */
    function spendSkillPoints(uint256 _skillId) external userRegistered whenNotPaused {
        User storage user = users[msg.sender];
        Skill storage skill = skills[_skillId];

        if (!skill.exists) {
            revert SkillNotFound();
        }
        if (user.unlockedSkills[_skillId]) {
            revert SkillAlreadyUnlocked();
        }
        if (user.skillPoints < skill.costSkillPoints) {
            revert InsufficientSkillPoints();
        }
        if (user.level < skill.requiredLevel) {
            revert LevelTooLow();
        }

        // Check prerequisites
        for (uint i = 0; i < skill.prerequisiteSkillIds.length; i++) {
            if (!user.unlockedSkills[skill.prerequisiteSkillIds[i]]) {
                revert PrerequisiteSkillsNotMet();
            }
        }

        user.skillPoints -= skill.costSkillPoints;
        user.unlockedSkills[_skillId] = true;

        emit SkillUnlocked(msg.sender, _skillId);
        _checkAndUnlockAchievements(msg.sender); // Check for achievements after unlocking a skill
    }

    /**
     * @notice Allows a user to trigger a check for all achievements they haven't earned yet.
     * This is a user-initiated check to save gas compared to checking automatically on every state change.
     */
    function triggerAchievementCheck() external userRegistered whenNotPaused {
        _checkAndUnlockAchievements(msg.sender);
    }

    /**
     * @notice An example function that requires a specific skill to be unlocked.
     * This demonstrates how unlocked skills can grant access or benefits.
     * @param _requiredSkillId The skill ID needed to perform this action.
     */
    function performAction_RequiresSkill(uint256 _requiredSkillId) external userRegistered whenNotPaused nonReentrant {
        if (!skills[_requiredSkillId].exists) {
             revert SkillNotFound();
        }
        if (!users[msg.sender].unlockedSkills[_requiredSkillId]) {
            revert PrerequisiteSkillsNotMet(); // Reusing error for simplicity
        }

        // --- Action Logic Goes Here ---
        // Example: Award a small amount of bonus points
        uint256 bonus = 10;
        users[msg.sender].skillPoints += bonus;
        emit SkillPointsEarned(msg.sender, bonus, users[msg.sender].skillPoints);
        // Example: Log that the action was performed
        // event ActionPerformed(address indexed user, uint256 indexed skillUsed);
        // emit ActionPerformed(msg.sender, _requiredSkillId);
        // --- End Action Logic ---

         _checkAndUnlockAchievements(msg.sender); // Check achievements after action
    }

    /**
     * @notice Simulates a prediction market interaction. Users make a simple prediction,
     * and if it matches a predetermined (or pseudo-random) outcome based on contract state/block data,
     * they receive a bonus.
     * @param _predictedOutcome A simple integer prediction.
     */
    function predictOutcome_Simulated(uint256 _predictedOutcome) external userRegistered whenNotPaused nonReentrant {
         User storage user = users[msg.sender];
         uint256 timeSinceLastPrediction = block.timestamp - user.lastActionTime; // Reuse lastActionTime for cooldown

        if (timeSinceLastPrediction < TASK_COOLDOWN) { // Reuse task cooldown
            revert CooldownNotElapsed(TASK_COOLDOWN - timeSinceLastPrediction);
        }

        // --- Simulated Prediction Logic ---
        // Example: The winning outcome is based on block data + user's level + current skill points parity
        uint256 actualOutcome = (block.timestamp % 5) + (block.number % 3) + (user.level % 2) + (user.skillPoints % 2);
        uint256 maxOutcomeValue = 5 + 3 + 1 + 1; // Max possible value

        if (_predictedOutcome > maxOutcomeValue) {
             revert InvalidPrediction(); // Prediction outside possible range
        }

        if (_predictedOutcome == actualOutcome) {
            uint256 bonusXP = 75;
            uint256 bonusPoints = 5;
            _grantXP(msg.sender, bonusXP);
            user.skillPoints += bonusPoints;
            emit SkillPointsEarned(msg.sender, bonusPoints, user.skillPoints);
            emit PredictionSuccessful(msg.sender, bonusXP, bonusPoints);
        } else {
            // Optional: Penalty for wrong prediction, or just no reward
            // _grantXP(msg.sender, 10); // Small consolation XP
             revert PredictionIncorrect();
        }

        user.lastActionTime = block.timestamp; // Reset cooldown
        _checkAndUnlockAchievements(msg.sender); // Check achievements
    }


    // --- Utility/View Functions ---

    function getUserDetails(address _user) external view returns (
        bool isRegistered,
        uint256 xp,
        uint256 level,
        uint256 skillPoints,
        uint256 lastActionTime
    ) {
        User storage user = users[_user];
        return (user.isRegistered, user.xp, user.level, user.skillPoints, user.lastActionTime);
    }

    function getUserLevel(address _user) external view returns (uint256) {
        if (!users[_user].isRegistered) return 0; // Or revert? Depends on desired behavior for unregistered
        return users[_user].level;
    }

     function getUserXP(address _user) external view returns (uint256) {
        if (!users[_user].isRegistered) return 0;
        return users[_user].xp;
    }

    function getUserSkillPoints(address _user) external view returns (uint256) {
         if (!users[_user].isRegistered) return 0;
        return users[_user].skillPoints;
    }

    function hasSkill(address _user, uint256 _skillId) public view returns (bool) {
        if (!users[_user].isRegistered) return false;
        return users[_user].unlockedSkills[_skillId];
    }

    function hasAchievement(address _user, uint256 _achievementId) public view returns (bool) {
         if (!users[_user].isRegistered) return false;
         if (!achievements[_achievementId].exists) return false; // Cannot have a non-existent achievement
        return users[_user].earnedAchievements[_achievementId];
    }

     function getUnlockedSkills(address _user) external view returns (uint256[] memory) {
        if (!users[_user].isRegistered) return new uint256[](0);

        uint256[] memory unlocked = new uint256[](_skillIds.current());
        uint256 count = 0;
        // Iterate potential skill IDs and check if user has them
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (skills[i].exists && users[_user].unlockedSkills[i]) {
                unlocked[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = unlocked[i];
        }
        return result;
    }

     function getEarnedAchievements(address _user) external view returns (uint256[] memory) {
         if (!users[_user].isRegistered) return new uint256[](0);

        uint256[] memory earned = new uint256[](_achievementIds.current());
        uint256 count = 0;
        // Iterate potential achievement IDs and check if user has them
        for (uint256 i = 1; i <= _achievementIds.current(); i++) {
            if (achievements[i].exists && users[_user].earnedAchievements[i]) {
                earned[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = earned[i];
        }
        return result;
    }


    function getSkillDetails(uint256 _skillId) external view returns (
        string memory name,
        string memory effectDescription,
        uint256 costSkillPoints,
        uint256 requiredLevel,
        uint256[] memory prerequisiteSkillIds,
        bool exists
    ) {
        Skill storage skill = skills[_skillId];
        if (!skill.exists) {
             // Return default values or specific marker for non-existence
             return ("", "", 0, 0, new uint256[](0), false);
        }
        return (
            skill.name,
            skill.effectDescription,
            skill.costSkillPoints,
            skill.requiredLevel,
            skill.prerequisiteSkillIds,
            skill.exists
        );
    }

    function getAchievementDetails(uint256 _achievementId) external view returns (
        string memory name,
        string memory description,
        uint256 rewardXP,
        uint256 rewardSkillPoints,
        bool exists
    ) {
         Achievement storage achievement = achievements[_achievementId];
        if (!achievement.exists) {
             // Return default values
            return ("", "", 0, 0, false);
        }
        return (
            achievement.name,
            achievement.description,
            achievement.rewardXP,
            achievement.rewardSkillPoints,
            achievement.exists
        );
    }

    function getAllSkillIds() external view returns (uint256[] memory) {
        uint256 totalSkills = _skillIds.current();
        uint256[] memory activeIds = new uint256[](totalSkills);
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSkills; i++) {
            if (skills[i].exists) {
                activeIds[count] = i;
                count++;
            }
        }
         uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

     function getAllAchievementIds() external view returns (uint256[] memory) {
        uint256 totalAchievements = _achievementIds.current();
        uint256[] memory activeIds = new uint256[](totalAchievements);
        uint256 count = 0;
        for (uint256 i = 1; i <= totalAchievements; i++) {
            if (achievements[i].exists) {
                activeIds[count] = i;
                count++;
            }
        }
         uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

    function getLevelThreshold(uint256 _level) external view returns (uint256) {
        if (_level == 0) return 0; // Level 0 requires 0 XP
        if (_level > levelThresholds.length) return type(uint256).max; // Reached max defined level or beyond
        return levelThresholds[_level - 1];
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to grant XP, recalculate level, and check achievements.
     * @param _user Address of the user.
     * @param _amount Amount of XP to grant.
     */
    function _grantXP(address _user, uint256 _amount) internal {
        User storage user = users[_user];
        user.xp += _amount;
        emit XPReceived(_user, _amount, user.xp);

        uint256 oldLevel = user.level;
        user.level = _calculateLevel(user.xp);

        if (user.level > oldLevel) {
            emit LevelUp(_user, oldLevel, user.level);
            // Optional: Grant skill points on level up
            uint256 pointsGained = (user.level - oldLevel) * 5; // Example: 5 points per level
            user.skillPoints += pointsGained;
            emit SkillPointsEarned(_user, pointsGained, user.skillPoints);
        }

        _checkAndUnlockAchievements(_user); // Check for achievements after any XP gain/level up
    }

    /**
     * @dev Internal function to calculate a user's current level based on their XP.
     * @param _xp User's current XP.
     * @return The calculated level.
     */
    function _calculateLevel(uint256 _xp) internal view returns (uint256) {
        uint256 currentLevel = 0;
        // Level 0 is < levelThresholds[0]
        // Level 1 is >= levelThresholds[0]
        // Level i is >= levelThresholds[i-1]
        for (uint i = 0; i < levelThresholds.length; i++) {
            if (_xp >= levelThresholds[i]) {
                currentLevel = i + 1;
            } else {
                // XP is less than the threshold for the next level,
                // so currentLevel is the correct one.
                break;
            }
        }
        return currentLevel;
    }

    /**
     * @dev Internal function to check if a user meets the specific condition for an achievement.
     * This logic is specific to each achievement ID.
     * @param _user Address of the user.
     * @param _achievementId The achievement ID to check.
     * @return true if the user meets the condition, false otherwise.
     */
    function _checkAchievementCondition(address _user, uint256 _achievementId) internal view returns (bool) {
        User storage user = users[_user];

        // --- Achievement Conditions Logic ---
        // Add complex conditions here based on _achievementId
        // This is where the "creativity" and state interaction happens.
        if (_achievementId == 1) { // Example: Reach Level 5
            return user.level >= 5;
        } else if (_achievementId == 2) { // Example: Unlock 3 Skills
            return _countUnlockedSkills(_user) >= 3;
        } else if (_achievementId == 3) { // Example: Earn 1000 Total XP
             return user.xp >= 1000;
        } else if (_achievementId == 4) { // Example: Have at least 50 skill points
             return user.skillPoints >= 50;
        } else if (_achievementId == 5) { // Example: Unlock Skill ID 7
             return user.unlockedSkills[7];
        }
         // Add more conditions for other achievement IDs...

        // If no condition matches (or achievement doesn't exist/is inactive), return false
        return false;
    }

    /**
     * @dev Internal helper to iterate through all active achievements and unlock any the user qualifies for.
     * Should be called after state changes that might affect achievements (XP gain, level up, skill unlock, etc.).
     * @param _user Address of the user.
     */
    function _checkAndUnlockAchievements(address _user) internal {
        User storage user = users[_user];
        // Iterate through all defined achievement IDs
        uint256 totalAchievements = _achievementIds.current();
        for (uint256 id = 1; id <= totalAchievements; id++) {
            if (achievements[id].exists && !user.earnedAchievements[id]) {
                // Check condition only for active, unearned achievements
                if (_checkAchievementCondition(_user, id)) {
                    user.earnedAchievements[id] = true;
                    user.xp += achievements[id].rewardXP; // Grant XP reward
                    user.skillPoints += achievements[id].rewardSkillPoints; // Grant skill points reward

                    // Need to recalculate level and emit XP/Points events AFTER adding rewards
                    uint256 oldLevel = user.level;
                    user.level = _calculateLevel(user.xp);

                    emit XPReceived(_user, achievements[id].rewardXP, user.xp);
                    emit SkillPointsEarned(_user, achievements[id].rewardSkillPoints, user.skillPoints);
                    emit AchievementUnlocked(_user, id);

                     if (user.level > oldLevel) {
                        emit LevelUp(_user, oldLevel, user.level);
                        // Note: Skill points from LevelUp are handled in _grantXP.
                        // This achievement check might be triggered *by* a level up,
                        // so points logic needs careful thought if points are gained from both.
                        // Current simple model: XP/Points from achievements are added, then level recalculated.
                    }

                    // It's possible unlocking one achievement immediately unlocks another.
                    // In a very complex dependency graph, this might need re-checking loop or careful ordering.
                    // For simplicity here, we just check all once per call.
                }
            }
        }
    }

     /**
     * @dev Internal helper to count the number of skills a user has unlocked.
     * Used for achievement conditions.
     * @param _user Address of the user.
     * @return The count of unlocked skills.
     */
    function _countUnlockedSkills(address _user) internal view returns (uint256) {
        uint256 count = 0;
        // Iterate potential skill IDs and count unlocked ones that still exist
        uint256 totalSkills = _skillIds.current();
        for (uint256 i = 1; i <= totalSkills; i++) {
            if (skills[i].exists && users[_user].unlockedSkills[i]) {
                count++;
            }
        }
        return count;
    }


    // --- Receive Ether Function ---

    /**
     * @notice Allows the contract to receive Ether.
     * Could be used for future features like paid tasks or entry fees.
     */
    receive() external payable {
        // Event could be added here if needed
    }
}
```