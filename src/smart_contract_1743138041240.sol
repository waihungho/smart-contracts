```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Achievement Profile Contract
 * @author Gemini AI (Example - Adapt and customize)
 * @dev A smart contract implementing a dynamic reputation and achievement system.
 *      Users can build profiles, earn reputation through various actions, unlock achievements,
 *      and potentially gain access to exclusive features or rewards based on their profile.
 *
 * **Outline and Function Summary:**
 *
 * **Core Profile Management:**
 *   1. `createUserProfile()`: Allows a user to create a profile, initializing their reputation and profile data.
 *   2. `updateProfileData(string _name, string _bio)`: Allows users to update their profile name and bio.
 *   3. `viewUserProfile(address _user)`:  Returns a user's profile information (name, bio, reputation, level, achievements).
 *   4. `getUserReputation(address _user)`: Returns a user's current reputation score.
 *   5. `getUserLevel(address _user)`: Returns a user's current level based on reputation.
 *
 * **Reputation and Level System:**
 *   6. `earnReputationForAction(address _user, uint256 _reputationAmount, string memory _actionType)`:  Allows the contract owner or designated roles to award reputation points for specific actions.
 *   7. `deductReputationForAction(address _user, uint256 _reputationAmount, string memory _actionType)`: Allows the contract owner or designated roles to deduct reputation points for specific actions (e.g., rule violations).
 *   8. `levelThresholds(uint256 _level)`: (View) Returns the reputation threshold required to reach a specific level. Configurable by the owner.
 *   9. `setReputationThreshold(uint256 _level, uint256 _threshold)`: Allows the contract owner to set or update the reputation threshold for a specific level.
 *
 * **Achievement System:**
 *   10. `awardAchievement(address _user, string memory _achievementId, string memory _achievementName)`: Allows the contract owner or designated roles to award specific achievements to users.
 *   11. `revokeAchievement(address _user, string memory _achievementId)`: Allows the contract owner or designated roles to revoke achievements from users.
 *   12. `getUserAchievements(address _user)`: Returns a list of achievement IDs that a user has earned.
 *   13. `achievementDetails(string memory _achievementId)`: (View) Returns the name and potentially other details for a specific achievement ID. Configurable by the owner.
 *   14. `defineAchievement(string memory _achievementId, string memory _achievementName)`: Allows the contract owner to define new achievements with names and IDs.
 *
 * **Profile Customization & Features (Example - can be extended):**
 *   15. `setUserProfileBadge(address _user, string memory _badgeId)`: Allows users to set a badge on their profile (badges could be linked to achievements or levels).
 *   16. `getUserProfileBadge(address _user)`: Returns the badge ID set on a user's profile.
 *   17. `defineBadge(string memory _badgeId, string memory _badgeName)`: Allows the contract owner to define new badges.
 *
 * **Governance & Admin (Example - can be extended):**
 *   18. `setReputationAuthority(address _authority)`: Allows the contract owner to set an address authorized to award/deduct reputation (role-based access control).
 *   19. `setAchievementAuthority(address _authority)`: Allows the contract owner to set an address authorized to award/revoke achievements (role-based access control).
 *   20. `pauseContract()`: Allows the contract owner to pause certain functionalities of the contract in case of emergency.
 *   21. `unpauseContract()`: Allows the contract owner to unpause the contract.
 *   22. `isContractPaused()`: (View) Returns whether the contract is currently paused.
 *   23. `withdrawContractBalance()`: Allows the contract owner to withdraw any Ether accidentally sent to the contract.
 */

contract DynamicReputationProfile {

    // --- Structs ---

    struct UserProfile {
        string name;
        string bio;
        uint256 reputation;
        uint256 level;
        mapping(string => bool) achievements; // Achievement ID to boolean (true if earned)
        string profileBadgeId; // Optional badge to display on profile
    }

    struct AchievementDefinition {
        string name;
        // Can add more details like description, image URI, etc. in future versions
    }

    struct BadgeDefinition {
        string name;
        // Can add more details like description, image URI, etc.
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => uint256) public levelThresholds; // Level to reputation threshold
    mapping(string => AchievementDefinition) public achievementDefinitions; // Achievement ID to definition
    mapping(string => BadgeDefinition) public badgeDefinitions; // Badge ID to definition

    address public owner;
    address public reputationAuthority; // Address authorized to award/deduct reputation
    address public achievementAuthority; // Address authorized to award/revoke achievements
    bool public paused;

    uint256 public nextProfileId = 1; // Example if you want to assign IDs (not used in current version, address is the primary identifier)

    // --- Events ---

    event ProfileCreated(address user, uint256 profileId);
    event ProfileUpdated(address user);
    event ReputationEarned(address user, uint256 amount, string actionType);
    event ReputationDeducted(address user, uint256 amount, string actionType);
    event LevelUp(address user, uint256 newLevel);
    event AchievementAwarded(address user, string achievementId, string achievementName);
    event AchievementRevoked(address user, string achievementId);
    event ProfileBadgeSet(address user, string badgeId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyReputationAuthority() {
        require(msg.sender == reputationAuthority, "Only reputation authority can call this function.");
        _;
    }

    modifier onlyAchievementAuthority() {
        require(msg.sender == achievementAuthority, "Only achievement authority can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier profileExists(address _user) {
        require(userProfiles[_user].reputation >= 0 , "User profile does not exist."); // Reputation initialized to 0 upon creation
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        reputationAuthority = msg.sender; // Initially owner is also reputation authority
        achievementAuthority = msg.sender; // Initially owner is also achievement authority
        paused = false;

        // Initialize default level thresholds (example)
        levelThresholds[1] = 100;
        levelThresholds[2] = 300;
        levelThresholds[3] = 700;
        levelThresholds[4] = 1500;
        levelThresholds[5] = 3000;

        // Define some initial achievements (example)
        defineAchievement("FIRST_PROFILE", "Profile Pioneer");
        defineAchievement("REACH_LEVEL_1", "Level 1 Achiever");
        defineAchievement("CONTRIBUTE_CONTENT", "Content Contributor");

        // Define some initial badges (example)
        defineBadge("BRONZE_BADGE", "Bronze Contributor Badge");
        defineBadge("SILVER_BADGE", "Silver Contributor Badge");
        defineBadge("GOLD_BADGE", "Gold Contributor Badge");
    }

    // --- Core Profile Management Functions ---

    /// @notice Allows a user to create a profile.
    function createUserProfile() external whenNotPaused {
        require(userProfiles[msg.sender].reputation == 0, "Profile already exists for this address."); // Basic check to prevent re-creation. Adapt as needed.

        userProfiles[msg.sender] = UserProfile({
            name: "New User",
            bio: "Welcome to the community!",
            reputation: 0,
            level: 0,
            profileBadgeId: "" // No badge initially
        });

        emit ProfileCreated(msg.sender, nextProfileId++); // Example using profile ID (can remove if not needed)
    }

    /// @notice Allows users to update their profile name and bio.
    /// @param _name The new name for the profile.
    /// @param _bio The new bio for the profile.
    function updateProfileData(string memory _name, string memory _bio) external whenNotPaused profileExists(msg.sender) {
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].bio = _bio;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Returns a user's profile information.
    /// @param _user The address of the user.
    /// @return name The user's profile name.
    /// @return bio The user's profile bio.
    /// @return reputation The user's reputation score.
    /// @return level The user's current level.
    /// @return achievementIds An array of achievement IDs earned by the user.
    /// @return profileBadgeId The badge ID set on the user's profile.
    function viewUserProfile(address _user) external view profileExists(_user) returns (
        string memory name,
        string memory bio,
        uint256 reputation,
        uint256 level,
        string[] memory achievementIds,
        string memory profileBadgeId
    ) {
        UserProfile storage profile = userProfiles[_user];
        name = profile.name;
        bio = profile.bio;
        reputation = profile.reputation;
        level = profile.level;
        profileBadgeId = profile.profileBadgeId;

        // Collect achievement IDs into an array
        uint256 achievementCount = 0;
        for (uint256 i = 0; i < 100; i++) { // Iterate through max 100 achievement IDs (adjust if needed, better to use dynamic array for achievement IDs in definition for real-world)
            string memory achievementId = string(abi.encodePacked("ACHIEVEMENT_", uint256(i))); // Example achievement ID generation - improve in real app
            if (profile.achievements[achievementId]) {
                achievementCount++;
            }
        }
        achievementIds = new string[](achievementCount);
        uint256 index = 0;
        for (uint256 i = 0; i < 100; i++) { // Iterate again to populate the array
            string memory achievementId = string(abi.encodePacked("ACHIEVEMENT_", uint256(i))); // Example achievement ID generation - improve in real app
            if (profile.achievements[achievementId]) {
                achievementIds[index] = achievementId;
                index++;
            }
        }
    }

    /// @notice Returns a user's current reputation score.
    /// @param _user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address _user) external view profileExists(_user) returns (uint256) {
        return userProfiles[_user].reputation;
    }

    /// @notice Returns a user's current level based on reputation.
    /// @param _user The address of the user.
    /// @return The user's level.
    function getUserLevel(address _user) external view profileExists(_user) returns (uint256) {
        return userProfiles[_user].level;
    }

    // --- Reputation and Level System Functions ---

    /// @notice Allows the reputation authority to award reputation points to a user.
    /// @param _user The address of the user to award reputation to.
    /// @param _reputationAmount The amount of reputation points to award.
    /// @param _actionType A description of the action for which reputation is awarded.
    function earnReputationForAction(address _user, uint256 _reputationAmount, string memory _actionType) external whenNotPaused onlyReputationAuthority profileExists(_user) {
        userProfiles[_user].reputation += _reputationAmount;
        _updateLevel(_user); // Update level after reputation change
        emit ReputationEarned(_user, _reputationAmount, _actionType);
    }

    /// @notice Allows the reputation authority to deduct reputation points from a user.
    /// @param _user The address of the user to deduct reputation from.
    /// @param _reputationAmount The amount of reputation points to deduct.
    /// @param _actionType A description of the action for which reputation is deducted.
    function deductReputationForAction(address _user, uint256 _reputationAmount, string memory _actionType) external whenNotPaused onlyReputationAuthority profileExists(_user) {
        // Prevent reputation from going below zero (optional, adjust as needed)
        if (_reputationAmount > userProfiles[_user].reputation) {
            userProfiles[_user].reputation = 0;
        } else {
            userProfiles[_user].reputation -= _reputationAmount;
        }
        _updateLevel(_user); // Update level after reputation change
        emit ReputationDeducted(_user, _reputationAmount, _actionType);
    }

    /// @notice (View) Returns the reputation threshold required to reach a specific level.
    /// @param _level The level to check the threshold for.
    /// @return The reputation threshold for the given level.
    function levelThresholds(uint256 _level) external view returns (uint256) {
        return levelThresholds[_level];
    }

    /// @notice Allows the contract owner to set or update the reputation threshold for a specific level.
    /// @param _level The level to set the threshold for.
    /// @param _threshold The reputation threshold for the level.
    function setReputationThreshold(uint256 _level, uint256 _threshold) external onlyOwner whenNotPaused {
        levelThresholds[_level] = _threshold;
    }

    /// @dev Internal function to update a user's level based on their reputation.
    function _updateLevel(address _user) internal {
        uint256 currentReputation = userProfiles[_user].reputation;
        uint256 currentLevel = userProfiles[_user].level;
        uint256 nextLevel = currentLevel + 1;

        while (levelThresholds[nextLevel] > 0 && currentReputation >= levelThresholds[nextLevel]) {
            currentLevel = nextLevel;
            nextLevel++;
        }
        if (userProfiles[_user].level != currentLevel) {
            userProfiles[_user].level = currentLevel;
            if (currentLevel > userProfiles[_user].level) { // To prevent level down event if level is already higher.
                emit LevelUp(_user, currentLevel);
                // Example: Award achievement for reaching a level
                if (currentLevel == 1 && !userProfiles[_user].achievements["REACH_LEVEL_1"]) {
                    awardAchievement(_user, "REACH_LEVEL_1", "Level 1 Achiever");
                }
            }
        }
    }


    // --- Achievement System Functions ---

    /// @notice Allows the achievement authority to award a specific achievement to a user.
    /// @param _user The address of the user to award the achievement to.
    /// @param _achievementId The ID of the achievement to award.
    /// @param _achievementName The name of the achievement (for event logging and clarity - can be fetched from definition).
    function awardAchievement(address _user, string memory _achievementId, string memory _achievementName) external whenNotPaused onlyAchievementAuthority profileExists(_user) {
        require(achievementDefinitions[_achievementId].name != "", "Achievement ID not defined.");
        require(!userProfiles[_user].achievements[_achievementId], "Achievement already awarded.");
        userProfiles[_user].achievements[_achievementId] = true;
        emit AchievementAwarded(_user, _achievementId, _achievementName);
    }

    /// @notice Allows the achievement authority to revoke an achievement from a user.
    /// @param _user The address of the user to revoke the achievement from.
    /// @param _achievementId The ID of the achievement to revoke.
    function revokeAchievement(address _user, string memory _achievementId) external whenNotPaused onlyAchievementAuthority profileExists(_user) {
        require(userProfiles[_user].achievements[_achievementId], "Achievement not awarded to revoke.");
        delete userProfiles[_user].achievements[_achievementId]; // Set to false or delete from mapping
        emit AchievementRevoked(_user, _achievementId);
    }

    /// @notice Returns a list of achievement IDs that a user has earned.
    /// @param _user The address of the user.
    /// @return An array of achievement IDs earned by the user.
    function getUserAchievements(address _user) external view profileExists(_user) returns (string[] memory) {
        UserProfile storage profile = userProfiles[_user];
        uint256 achievementCount = 0;
        for (uint256 i = 0; i < 100; i++) { // Iterate through max 100 achievement IDs (adjust if needed, better to use dynamic array for achievement IDs in definition for real-world)
            string memory achievementId = string(abi.encodePacked("ACHIEVEMENT_", uint256(i))); // Example achievement ID generation - improve in real app
            if (profile.achievements[achievementId]) {
                achievementCount++;
            }
        }
        string[] memory achievementIds = new string[](achievementCount);
        uint256 index = 0;
        for (uint256 i = 0; i < 100; i++) { // Iterate again to populate the array
            string memory achievementId = string(abi.encodePacked("ACHIEVEMENT_", uint256(i))); // Example achievement ID generation - improve in real app
            if (profile.achievements[achievementId]) {
                achievementIds[index] = achievementId;
                index++;
            }
        }
        return achievementIds;
    }

    /// @notice (View) Returns the name and potentially other details for a specific achievement ID.
    /// @param _achievementId The ID of the achievement.
    /// @return The name of the achievement.
    function achievementDetails(string memory _achievementId) external view returns (string memory name) {
        return achievementDefinitions[_achievementId].name;
    }

    /// @notice Allows the contract owner to define new achievements with names and IDs.
    /// @param _achievementId The unique ID for the achievement (e.g., "CONTRIBUTE_CONTENT").
    /// @param _achievementName The human-readable name of the achievement (e.g., "Content Contributor").
    function defineAchievement(string memory _achievementId, string memory _achievementName) external onlyOwner whenNotPaused {
        achievementDefinitions[_achievementId] = AchievementDefinition({
            name: _achievementName
        });
    }


    // --- Profile Customization & Features ---

    /// @notice Allows users to set a badge on their profile.
    /// @param _badgeId The ID of the badge to set.
    function setUserProfileBadge(address _user, string memory _badgeId) external whenNotPaused profileExists(_user) {
        require(badgeDefinitions[_badgeId].name != "", "Badge ID not defined.");
        userProfiles[_user].profileBadgeId = _badgeId;
        emit ProfileBadgeSet(_user, _badgeId);
    }

    /// @notice Returns the badge ID set on a user's profile.
    /// @param _user The address of the user.
    /// @return The badge ID set on the user's profile (empty string if no badge set).
    function getUserProfileBadge(address _user) external view profileExists(_user) returns (string memory) {
        return userProfiles[_user].profileBadgeId;
    }

    /// @notice Allows the contract owner to define new badges.
    /// @param _badgeId The unique ID for the badge.
    /// @param _badgeName The human-readable name of the badge.
    function defineBadge(string memory _badgeId, string memory _badgeName) external onlyOwner whenNotPaused {
        badgeDefinitions[_badgeId] = BadgeDefinition({
            name: _badgeName
        });
    }


    // --- Governance & Admin Functions ---

    /// @notice Sets the address authorized to award and deduct reputation.
    /// @param _authority The address of the reputation authority.
    function setReputationAuthority(address _authority) external onlyOwner whenNotPaused {
        reputationAuthority = _authority;
    }

    /// @notice Sets the address authorized to award and revoke achievements.
    /// @param _authority The address of the achievement authority.
    function setAchievementAuthority(address _authority) external onlyOwner whenNotPaused {
        achievementAuthority = _authority;
    }

    /// @notice Pauses the contract, preventing certain functionalities.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, restoring functionalities.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice (View) Returns whether the contract is currently paused.
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /// @notice Allows the owner to withdraw any Ether accidentally sent to the contract.
    function withdrawContractBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // --- Fallback and Receive (Optional for demonstration - handle accidental ETH sent to contract) ---
    receive() external payable {}
    fallback() external payable {}
}
```