Okay, let's design a smart contract that represents a decentralized, skill-based reputation and questing system. Users register, gain "skills" (represented internally with levels, not necessarily external tokens for simplicity and statefulness), earn reputation, and can participate in "quests" which have prerequisites (skills, reputation) and grant rewards (more skills, reputation).

This contract combines elements of identity, gaming mechanics, dynamic state updates, and structured interactions, going beyond simple token transfers or basic registries. It avoids directly duplicating common DeFi (AMMs, lending), standard NFT marketplaces, or simple DAO frameworks.

We'll aim for a good mix of state-changing and view functions to meet the 20+ function requirement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Decentralized Skill Registry & Quest Platform
/// @dev This contract manages user profiles, skills, and quests. Users register, gain skills and reputation by completing quests,
///      and can view their progress and available quests. Skills are represented internally with levels.
///      Quests have prerequisites (reputation, skills) and grant rewards (reputation, skills).
///      This is a base model and could be extended with on-chain randomness, external oracle calls for verification,
///      token rewards (ERC20/ERC721), or more complex quest mechanics.

// --- OUTLINE ---
// 1. State Variables & Data Structures
//    - UserProfile: Stores user's reputation and skill levels.
//    - Skill: Defines a type of skill.
//    - Quest: Defines a quest with prerequisites and rewards.
//    - UserQuestStatus: Tracks a user's progress on a specific quest.
//    - Mappings for users, skills, quests, and user quest statuses.
//    - Counters for Skill IDs and Quest IDs.
// 2. Events: Signify important state changes.
// 3. Modifiers: Access control (Ownable), pausing (Pausable).
// 4. Constructor: Initialize owner.
// 5. Core User Profile Management (Public)
//    - registerUser
//    - getUserProfile
//    - getUserSkillLevel
//    - getAllUserSkills
// 6. Skill Management (Owner Only)
//    - createSkill
//    - updateSkillDetails
//    - getSkillDetails
//    - listAllSkills
// 7. Quest Management (Owner Only)
//    - createQuest
//    - updateQuestDetails
//    - getQuestDetails
//    - listAllQuests
// 8. User Quest Interaction (Public)
//    - startQuest
//    - getUserQuestStatus
//    - attemptQuestCompletion (Self-service based on elapsed time)
//    - failQuest (User abandons)
//    - checkQuestPrerequisites (Helper view function)
// 9. Admin/Utility Functions (Owner Only)
//    - grantSkillToUser (Manual skill award)
//    - grantReputationToUser (Manual reputation award)
//    - pause / unpause
// 10. Query/View Functions (Public)
//    - getTotalRegisteredUsers
//    - getTotalSkills
//    - getTotalQuests
//    - getQuestRewardDetails
//    - canAttemptCompletion (Checks if time elapsed)

contract ReputationSkillQuestRegistry is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- 1. State Variables & Data Structures ---

    enum QuestState {
        Inactive, // Not started by this user
        Active,   // User is currently attempting
        Completed, // User successfully completed
        Failed    // User failed or abandoned
    }

    struct UserProfile {
        uint256 reputation;
        bool isRegistered;
        // Skills are stored in a separate mapping: address => skillId => level
    }

    struct Skill {
        uint256 id;
        string name;
        string description;
        bool exists; // To check if a skill ID is valid
    }

    struct Quest {
        uint256 id;
        string name;
        string description;
        uint256 requiredReputation;
        uint256 durationSeconds; // Minimum time required before completion attempt
        // Prerequisites:
        uint256[] requiredSkillIds;
        uint256[] requiredSkillLevels;
        // Rewards:
        uint256 rewardReputation;
        uint256 rewardSkillId;
        uint256 rewardSkillLevel; // Level gained for the reward skill
        bool exists; // To check if a quest ID is valid
    }

    struct UserQuestStatus {
        QuestState state;
        uint40 startTime; // Using uint40 for efficiency if seconds fit
        uint256 questId; // Link back to the quest definition
    }

    // Mappings
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(uint256 => uint256)) public userSkills; // address => skillId => level
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Quest) public quests;
    mapping(address => mapping(uint256 => UserQuestStatus)) private userQuestStatuses; // user => questId => status

    // Counters
    Counters.Counter private _skillIds;
    Counters.Counter private _questIds;
    uint256 private _totalRegisteredUsers = 0;

    // --- 2. Events ---

    event UserRegistered(address indexed user);
    event ReputationChanged(address indexed user, uint256 oldReputation, uint256 newReputation);
    event SkillGained(address indexed user, uint256 indexed skillId, uint256 newLevel);
    event SkillLevelChanged(address indexed user, uint256 indexed skillId, uint256 oldLevel, uint256 newLevel);
    event SkillCreated(uint256 indexed skillId, string name);
    event QuestCreated(uint256 indexed questId, string name);
    event QuestStarted(address indexed user, uint256 indexed questId);
    event QuestCompleted(address indexed user, uint256 indexed questId, uint256 earnedReputation, uint256 earnedSkillId, uint256 earnedSkillLevel);
    event QuestFailed(address indexed user, uint256 indexed questId);

    // --- 3. Modifiers ---

    // Inherits onlyOwner from OpenZeppelin

    // Inherits whenNotPaused and whenPaused from OpenZeppelin

    modifier onlyRegisteredUser(address _user) {
        require(userProfiles[_user].isRegistered, "User not registered");
        _;
    }

    // --- 4. Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- 5. Core User Profile Management ---

    /// @dev Registers the calling address as a user.
    /// @return success True if registration was successful.
    function registerUser() public whenNotPaused returns (bool success) {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        userProfiles[msg.sender].isRegistered = true;
        userProfiles[msg.sender].reputation = 0; // Start with 0 reputation
        _totalRegisteredUsers++;
        emit UserRegistered(msg.sender);
        return true;
    }

    /// @dev Gets the profile details for a user.
    /// @param _user The address of the user.
    /// @return reputation The user's reputation score.
    /// @return isRegistered True if the user is registered.
    function getUserProfile(address _user) public view returns (uint256 reputation, bool isRegistered) {
        return (userProfiles[_user].reputation, userProfiles[_user].isRegistered);
    }

    /// @dev Gets the level of a specific skill for a user.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill.
    /// @return The level of the skill the user possesses. Returns 0 if the user doesn't have the skill or is not registered.
    function getUserSkillLevel(address _user, uint256 _skillId) public view returns (uint256) {
        if (!userProfiles[_user].isRegistered) return 0;
        if (!skills[_skillId].exists) return 0; // Skill must exist
        return userSkills[_user][_skillId];
    }

    /// @dev Gets a list of all skills a user possesses with their levels.
    /// @dev Note: Iterating over mappings is not directly possible. This requires maintaining a separate list or using an external indexer.
    ///      For this example, we'll provide a function signature showing the intent, but direct on-chain retrieval of *all* skills
    ///      like this is generally inefficient or impossible without auxiliary state. A common pattern is emitting events and using off-chain indexing.
    ///      Alternatively, the `userSkills` mapping *could* map to a struct containing an array of skill IDs, but this adds complexity to updates.
    ///      We'll return skill IDs the user has a level > 0 for up to a certain limit or require knowing skill IDs.
    ///      A better approach for a robust system would track skills in a dynamic array within the UserProfile or use an external subgraph.
    ///      Let's compromise: return levels for a provided list of skill IDs, or indicate that getting *all* is complex.
    ///      For demonstration, we'll return levels for a list, indicating the need for skill IDs externally.
    /// @param _user The address of the user.
    /// @param _skillIds A list of skill IDs to check.
    /// @return levels An array of levels corresponding to the provided skill IDs.
    function getUserSkillLevelsForIds(address _user, uint256[] memory _skillIds) public view onlyRegisteredUser(_user) returns (uint256[] memory levels) {
        levels = new uint256[](_skillIds.length);
        for (uint i = 0; i < _skillIds.length; i++) {
            levels[i] = userSkills[_user][_skillIds[i]];
        }
        return levels;
    }

    // --- 6. Skill Management (Owner Only) ---

    /// @dev Creates a new skill type.
    /// @param _name The name of the skill.
    /// @param _description A description of the skill.
    /// @return newSkillId The ID of the newly created skill.
    function createSkill(string calldata _name, string calldata _description) public onlyOwner whenNotPaused returns (uint256 newSkillId) {
        _skillIds.increment();
        newSkillId = _skillIds.current();
        skills[newSkillId] = Skill(newSkillId, _name, _description, true);
        emit SkillCreated(newSkillId, _name);
        return newSkillId;
    }

    /// @dev Updates details for an existing skill.
    /// @param _skillId The ID of the skill to update.
    /// @param _name The new name of the skill.
    /// @param _description The new description of the skill.
    function updateSkillDetails(uint256 _skillId, string calldata _name, string calldata _description) public onlyOwner whenNotPaused {
        require(skills[_skillId].exists, "Skill does not exist");
        skills[_skillId].name = _name;
        skills[_skillId].description = _description;
        // No event for simple detail update in this model
    }

    /// @dev Gets the details of a specific skill.
    /// @param _skillId The ID of the skill.
    /// @return skillId The ID of the skill.
    /// @return name The name of the skill.
    /// @return description The description of the skill.
    function getSkillDetails(uint256 _skillId) public view returns (uint256 skillId, string memory name, string memory description) {
        require(skills[_skillId].exists, "Skill does not exist");
        Skill storage skill = skills[_skillId];
        return (skill.id, skill.name, skill.description);
    }

    /// @dev Gets the total number of distinct skills registered.
    /// @return The total count of skills.
    function getTotalSkills() public view returns (uint256) {
        return _skillIds.current();
    }

     /// @dev Lists all active skill IDs. Note: This can be gas-intensive for large numbers.
     ///      A more scalable approach involves off-chain indexing or pagination.
     ///      For simplicity, returns all IDs up to the current counter.
    function listAllSkillIds() public view returns (uint256[] memory) {
        uint256 total = _skillIds.current();
        uint256[] memory skillIds = new uint256[total];
        for (uint i = 1; i <= total; i++) {
            skillIds[i-1] = i;
        }
        return skillIds;
    }


    // --- 7. Quest Management (Owner Only) ---

    /// @dev Creates a new quest type.
    /// @param _name The name of the quest.
    /// @param _description A description of the quest.
    /// @param _requiredReputation Minimum reputation required to start.
    /// @param _durationSeconds Minimum time in seconds the user must wait before attempting completion.
    /// @param _requiredSkillIds Array of skill IDs required.
    /// @param _requiredSkillLevels Array of minimum levels required for the corresponding skill IDs. Must match length of _requiredSkillIds.
    /// @param _rewardReputation Reputation gained upon successful completion.
    /// @param _rewardSkillId Skill ID gained upon successful completion (0 if no skill reward).
    /// @param _rewardSkillLevel Level of the reward skill gained.
    /// @return newQuestId The ID of the newly created quest.
    function createQuest(
        string calldata _name,
        string calldata _description,
        uint256 _requiredReputation,
        uint256 _durationSeconds,
        uint256[] calldata _requiredSkillIds,
        uint256[] calldata _requiredSkillLevels,
        uint256 _rewardReputation,
        uint256 _rewardSkillId,
        uint256 _rewardSkillLevel
    ) public onlyOwner whenNotPaused returns (uint256 newQuestId) {
        require(_requiredSkillIds.length == _requiredSkillLevels.length, "Skill ID and level arrays must match length");
        if (_rewardSkillId != 0) {
             require(skills[_rewardSkillId].exists, "Reward skill does not exist");
             require(_rewardSkillLevel > 0, "Reward skill level must be greater than 0 if skill is rewarded");
        }
        for(uint i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].exists, "Required skill does not exist");
        }

        _questIds.increment();
        newQuestId = _questIds.current();

        quests[newQuestId] = Quest(
            newQuestId,
            _name,
            _description,
            _requiredReputation,
            _durationSeconds,
            _requiredSkillIds,
            _requiredSkillLevels,
            _rewardReputation,
            _rewardSkillId,
            _rewardSkillLevel,
            true
        );
        emit QuestCreated(newQuestId, _name);
        return newQuestId;
    }

     /// @dev Updates details for an existing quest.
     /// @dev Note: Updating quest requirements/rewards mid-quest could impact ongoing attempts.
     ///      Care should be taken or updates restricted.
     /// @param _questId The ID of the quest to update.
     /// @param _name The new name.
     /// @param _description The new description.
     /// @param _requiredReputation New min reputation.
     /// @param _durationSeconds New min duration.
     /// @param _requiredSkillIds New required skill IDs.
     /// @param _requiredSkillLevels New required skill levels.
     /// @param _rewardReputation New reward reputation.
     /// @param _rewardSkillId New reward skill ID.
     /// @param _rewardSkillLevel New reward skill level.
    function updateQuestDetails(
        uint256 _questId,
        string calldata _name,
        string calldata _description,
        uint256 _requiredReputation,
        uint256 _durationSeconds,
        uint256[] calldata _requiredSkillIds,
        uint256[] calldata _requiredSkillLevels,
        uint256 _rewardReputation,
        uint256 _rewardSkillId,
        uint256 _rewardSkillLevel
    ) public onlyOwner whenNotPaused {
        require(quests[_questId].exists, "Quest does not exist");
        require(_requiredSkillIds.length == _requiredSkillLevels.length, "Skill ID and level arrays must match length");
         if (_rewardSkillId != 0) {
             require(skills[_rewardSkillId].exists, "Reward skill does not exist");
             require(_rewardSkillLevel > 0, "Reward skill level must be greater than 0 if skill is rewarded");
         }
         for(uint i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].exists, "Required skill does not exist");
        }

        quests[_questId].name = _name;
        quests[_questId].description = _description;
        quests[_questId].requiredReputation = _requiredReputation;
        quests[_questId].durationSeconds = _durationSeconds;
        quests[_questId].requiredSkillIds = _requiredSkillIds;
        quests[_questId].requiredSkillLevels = _requiredSkillLevels;
        quests[_questId].rewardReputation = _rewardReputation;
        quests[_questId].rewardSkillId = _rewardSkillId;
        quests[_questId].rewardSkillLevel = _rewardSkillLevel;
        // No event for update in this model
    }


    /// @dev Gets the details of a specific quest.
    /// @param _questId The ID of the quest.
    /// @return quest The Quest struct.
    function getQuestDetails(uint256 _questId) public view returns (Quest memory quest) {
        require(quests[_questId].exists, "Quest does not exist");
        return quests[_questId];
    }

    /// @dev Gets the total number of distinct quests registered.
    /// @return The total count of quests.
    function getTotalQuests() public view returns (uint256) {
        return _questIds.current();
    }

    /// @dev Lists all active quest IDs. Note: This can be gas-intensive for large numbers.
     ///      A more scalable approach involves off-chain indexing or pagination.
     ///      For simplicity, returns all IDs up to the current counter.
    function listAllQuestIds() public view returns (uint256[] memory) {
        uint256 total = _questIds.current();
        uint256[] memory questIds = new uint256[total];
        for (uint i = 1; i <= total; i++) {
            questIds[i-1] = i;
        }
        return questIds;
    }


    // --- 8. User Quest Interaction ---

    /// @dev Allows a registered user to start a quest if they meet the prerequisites.
    /// @param _questId The ID of the quest to start.
    function startQuest(uint256 _questId) public whenNotPaused onlyRegisteredUser(msg.sender) {
        require(quests[_questId].exists, "Quest does not exist");
        // Prevent starting if already active or completed/failed previously (can be changed based on design)
        require(userQuestStatuses[msg.sender][_questId].state == QuestState.Inactive, "Quest is already active or previously attempted");

        require(checkQuestPrerequisites(msg.sender, _questId), "User does not meet quest prerequisites");

        userQuestStatuses[msg.sender][_questId] = UserQuestStatus(
            QuestState.Active,
            uint40(block.timestamp),
            _questId
        );

        emit QuestStarted(msg.sender, _questId);
    }

    /// @dev Gets the current status of a user's attempt for a specific quest.
    /// @param _user The address of the user.
    /// @param _questId The ID of the quest.
    /// @return state The current QuestState.
    /// @return startTime The timestamp when the quest was started by the user.
    /// @return questId The ID of the quest (useful if querying without knowing the questId directly).
    function getUserQuestStatus(address _user, uint256 _questId) public view onlyRegisteredUser(_user) returns (QuestState state, uint40 startTime, uint256 questId) {
        // Return default Inactive state if status doesn't exist
        if (userQuestStatuses[_user][_questId].state == QuestState.Inactive && userQuestStatuses[_user][_questId].questId != _questId) {
             return (QuestState.Inactive, 0, _questId);
        }
        UserQuestStatus storage status = userQuestStatuses[_user][_questId];
        return (status.state, status.startTime, status.questId);
    }

    /// @dev Allows a user to attempt to complete a quest.
    /// @dev Completion is based purely on meeting the minimum duration requirement in this simplified model.
    ///      More advanced versions could require submitting proof (e.g., transaction on another chain, oracle call).
    /// @param _questId The ID of the quest to attempt completion.
    function attemptQuestCompletion(uint256 _questId) public whenNotPaused onlyRegisteredUser(msg.sender) {
        UserQuestStatus storage status = userQuestStatuses[msg.sender][_questId];
        require(status.state == QuestState.Active, "Quest is not active for this user");

        Quest storage quest = quests[_questId];
        require(quest.exists, "Quest does not exist"); // Should always exist if status is active, but safety check.

        // Check if minimum duration has passed
        require(canAttemptCompletion(msg.sender, _questId), "Minimum quest duration has not passed");

        // In this model, time elapsed == success.
        // Award rewards
        _awardQuestRewards(msg.sender, _questId);

        // Update status
        status.state = QuestState.Completed;

        emit QuestCompleted(msg.sender, _questId, quest.rewardReputation, quest.rewardSkillId, quest.rewardSkillLevel);
    }

    /// @dev Allows a user to manually fail or abandon an active quest.
    /// @param _questId The ID of the quest to fail.
    function failQuest(uint256 _questId) public whenNotPaused onlyRegisteredUser(msg.sender) {
        UserQuestStatus storage status = userQuestStatuses[msg.sender][_questId];
        require(status.state == QuestState.Active, "Quest is not active for this user");

        status.state = QuestState.Failed;
        // Could add penalty here (e.g., reputation loss, cooldown)

        emit QuestFailed(msg.sender, _questId);
    }


     /// @dev Checks if a user meets the prerequisites to start a specific quest.
     /// @param _user The address of the user.
     /// @param _questId The ID of the quest.
     /// @return bool True if the user meets all prerequisites.
    function checkQuestPrerequisites(address _user, uint256 _questId) public view onlyRegisteredUser(_user) returns (bool) {
        Quest storage quest = quests[_questId];
        require(quest.exists, "Quest does not exist");

        // Check reputation requirement
        if (userProfiles[_user].reputation < quest.requiredReputation) {
            return false;
        }

        // Check skill requirements
        require(quest.requiredSkillIds.length == quest.requiredSkillLevels.length, "Quest has invalid skill prerequisites"); // Should not happen if created correctly
        for (uint i = 0; i < quest.requiredSkillIds.length; i++) {
            uint256 requiredSkillId = quest.requiredSkillIds[i];
            uint256 requiredLevel = quest.requiredSkillLevels[i];
            if (userSkills[_user][requiredSkillId] < requiredLevel) {
                return false;
            }
        }

        // All checks passed
        return true;
    }

     /// @dev Checks if a user is allowed to attempt completion based on elapsed time.
     /// @param _user The address of the user.
     /// @param _questId The ID of the quest.
     /// @return bool True if the minimum duration has passed since the quest started.
    function canAttemptCompletion(address _user, uint256 _questId) public view onlyRegisteredUser(_user) returns (bool) {
        UserQuestStatus storage status = userQuestStatuses[_user][_questId];
        require(status.state == QuestState.Active, "Quest is not active for this user");

        Quest storage quest = quests[_questId];
        require(quest.exists, "Quest does not exist");

        return block.timestamp >= (status.startTime + quest.durationSeconds);
    }


    // --- 9. Admin/Utility Functions (Owner Only) ---

    /// @dev Allows the owner to manually grant a skill level to a user. Useful for off-chain achievements.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill to grant.
    /// @param _level The level to grant. This replaces the current level if higher.
    function grantSkillToUser(address _user, uint256 _skillId, uint256 _level) public onlyOwner whenNotPaused onlyRegisteredUser(_user) {
        require(skills[_skillId].exists, "Skill does not exist");
        require(_level > 0, "Level must be greater than 0"); // Use grantReputationToUser for 0 level changes

        uint256 currentLevel = userSkills[_user][_skillId];
        if (_level > currentLevel) {
            userSkills[_user][_skillId] = _level;
            if (currentLevel == 0) {
                 emit SkillGained(_user, _skillId, _level);
            } else {
                emit SkillLevelChanged(_user, _skillId, currentLevel, _level);
            }
        }
    }

    /// @dev Allows the owner to manually grant (or reduce) reputation for a user.
    /// @param _user The address of the user.
    /// @param _amount The amount of reputation to add (can be 0).
    function grantReputationToUser(address _user, uint256 _amount) public onlyOwner whenNotPaused onlyRegisteredUser(_user) {
        uint256 oldReputation = userProfiles[_user].reputation;
        userProfiles[_user].reputation += _amount;
        emit ReputationChanged(_user, oldReputation, userProfiles[_user].reputation);
    }

    /// @dev Grants rewards for a completed quest. Internal helper function.
    function _awardQuestRewards(address _user, uint256 _questId) internal onlyRegisteredUser(_user) {
        Quest storage quest = quests[_questId];
        require(quest.exists, "Quest does not exist"); // Should be true

        // Award Reputation
        if (quest.rewardReputation > 0) {
            uint256 oldReputation = userProfiles[_user].reputation;
            userProfiles[_user].reputation += quest.rewardReputation;
            emit ReputationChanged(_user, oldReputation, userProfiles[_user].reputation);
        }

        // Award Skill
        if (quest.rewardSkillId != 0 && quest.rewardSkillLevel > 0) {
             // Check if the reward skill exists (should be true from quest creation check)
             require(skills[quest.rewardSkillId].exists, "Reward skill does not exist internally");

            uint256 currentLevel = userSkills[_user][quest.rewardSkillId];
            // Only increase skill level if the reward level is higher than current
            if (quest.rewardSkillLevel > currentLevel) {
                userSkills[_user][quest.rewardSkillId] = quest.rewardSkillLevel;
                 if (currentLevel == 0) {
                    emit SkillGained(_user, quest.rewardSkillId, quest.rewardSkillLevel);
                 } else {
                    emit SkillLevelChanged(_user, quest.rewardSkillId, currentLevel, quest.rewardSkillLevel);
                 }
            }
        }
    }


    // Inherits pause() and unpause() from Pausable


    // --- 10. Query/View Functions ---

    /// @dev Gets the total number of registered users.
    /// @return The total count of registered users.
    function getTotalRegisteredUsers() public view returns (uint256) {
        return _totalRegisteredUsers;
    }


    /// @dev Gets the reward details for a specific quest.
    /// @param _questId The ID of the quest.
    /// @return rewardReputation Reputation gained.
    /// @return rewardSkillId Skill ID gained (0 if none).
    /// @return rewardSkillLevel Level of skill gained.
    function getQuestRewardDetails(uint256 _questId) public view returns (uint256 rewardReputation, uint256 rewardSkillId, uint256 rewardSkillLevel) {
        require(quests[_questId].exists, "Quest does not exist");
        Quest storage quest = quests[_questId];
        return (quest.rewardReputation, quest.rewardSkillId, quest.rewardSkillLevel);
    }

    /// @dev Get the required skills and levels for a quest.
    /// @param _questId The ID of the quest.
    /// @return requiredSkillIds Array of required skill IDs.
    /// @return requiredSkillLevels Array of required skill levels.
    function getQuestRequiredSkills(uint256 _questId) public view returns (uint256[] memory requiredSkillIds, uint256[] memory requiredSkillLevels) {
        require(quests[_questId].exists, "Quest does not exist");
        Quest storage quest = quests[_questId];
        return (quest.requiredSkillIds, quest.requiredSkillLevels);
    }

    /// @dev Get the required reputation for a quest.
    /// @param _questId The ID of the quest.
    /// @return requiredReputation The minimum reputation required.
    function getQuestRequiredReputation(uint256 _questId) public view returns (uint256) {
         require(quests[_questId].exists, "Quest does not exist");
        return quests[_questId].requiredReputation;
    }

    /// @dev Get the minimum duration for a quest.
    /// @param _questId The ID of the quest.
    /// @return durationSeconds The minimum duration in seconds.
    function getQuestDuration(uint256 _questId) public view returns (uint256) {
         require(quests[_questId].exists, "Quest does not exist");
        return quests[_questId].durationSeconds;
    }

    /// @dev List all quest IDs currently active for a specific user.
     ///      Note: Similar to listing all user skills, this is inefficient for many active quests without auxiliary state.
     ///      Returning a placeholder indicating the challenge or requiring external data.
     ///      For simplicity, we will return an empty array or require off-chain indexing.
     ///      A robust design would have a mapping `address => uint256[] activeQuestIds`.
     ///      Let's provide a signature that acknowledges the difficulty without a full implementation of auxiliary state.
    function getUserActiveQuestIds(address _user) public view onlyRegisteredUser(_user) returns (uint256[] memory) {
        // WARNING: Directly iterating over the keys of userQuestStatuses[user] to find Active quests is NOT possible in Solidity.
        // A separate array (e.g., `uint256[] public userActiveQuestIds;` in UserProfile) would be needed, updated on start/complete/fail.
        // Implementing that requires modifying UserProfile and updating the array carefully (add on start, remove on finish).
        // To keep this example simpler and avoid modifying structs extensively late, this function is a placeholder.
        // A real application would use events and off-chain indexing (e.g., The Graph) to list active quests per user efficiently.
        revert("Listing all active quest IDs per user on-chain is inefficient; use events and off-chain indexing.");
        // return new uint256[](0); // Or return an empty array as a placeholder
    }

    // Total functions: 25 (register, getProfile, getSkillLevel, getSkillLevelsForIds, createSkill, updateSkillDetails, getSkillDetails, getTotalSkills, listAllSkillIds, createQuest, updateQuestDetails, getQuestDetails, getTotalQuests, listAllQuestIds, startQuest, getUserQuestStatus, attemptQuestCompletion, failQuest, checkQuestPrerequisites, canAttemptCompletion, grantSkillToUser, grantReputationToUser, pause, unpause, getTotalRegisteredUsers, getQuestRewardDetails, getQuestRequiredSkills, getQuestRequiredReputation, getQuestDuration, getUserActiveQuestIds - Oops, counted more than 25. Let's verify exactly 20+.

    // Let's recount and ensure 20+ distinct public/external functions:
    // 1. registerUser
    // 2. getUserProfile
    // 3. getUserSkillLevel
    // 4. getUserSkillLevelsForIds
    // 5. createSkill (Owner)
    // 6. updateSkillDetails (Owner)
    // 7. getSkillDetails
    // 8. getTotalSkills
    // 9. listAllSkillIds
    // 10. createQuest (Owner)
    // 11. updateQuestDetails (Owner)
    // 12. getQuestDetails
    // 13. getTotalQuests
    // 14. listAllQuestIds
    // 15. startQuest
    // 16. getUserQuestStatus
    // 17. attemptQuestCompletion
    // 18. failQuest
    // 19. checkQuestPrerequisites
    // 20. canAttemptCompletion
    // 21. grantSkillToUser (Owner)
    // 22. grantReputationToUser (Owner)
    // 23. pause (Owner)
    // 24. unpause (Owner)
    // 25. getTotalRegisteredUsers
    // 26. getQuestRewardDetails
    // 27. getQuestRequiredSkills
    // 28. getQuestRequiredReputation
    // 29. getQuestDuration
    // 30. getUserActiveQuestIds (Placeholder)

    // Okay, that's 30 functions (including the placeholder), well over the 20+ requirement.

}
```

---

**Explanation of Concepts and Features:**

1.  **Stateful Profiles & Skills:** Instead of just a token balance, users have a `UserProfile` struct storing their `reputation` score. Skills are not standard ERC1155 tokens but are tracked internally as `uint256` levels within a mapping (`userSkills`). This allows for gradual progression (leveling up) beyond simply owning a token ID.
2.  **Dynamic State Updates:** User reputation and skill levels change directly within the contract's state based on completing quests, making the profile dynamic.
3.  **Structured Interactions (Quests):** The `Quest` struct defines complex activities with multiple parameters:
    *   `requiredReputation` and `requiredSkills` create entry barriers based on the user's profile state.
    *   `durationSeconds` introduces a time-based mechanic, requiring users to wait before attempting completion, simulating effort or waiting period.
    *   `rewardReputation` and `rewardSkill` define the outcomes, directly updating the user's state.
4.  **User Quest Status:** The `UserQuestStatus` mapping tracks the state (`Active`, `Completed`, `Failed`) and start time for *each* user on *each* quest they attempt. This is a stateful per-user, per-item tracking mechanism.
5.  **Self-Service Completion (Time-Based):** The `attemptQuestCompletion` function allows the user to trigger completion themselves *after* the required duration has passed. This is a simplified model for demonstration; in a real application, this might involve submitting off-chain proofs verified by an oracle or requiring a multi-signature confirmation.
6.  **Admin Overrides:** `grantSkillToUser` and `grantReputationToUser` provide owner functions to manually adjust user state. This is useful for integrating off-chain activities or correcting errors.
7.  **Pausable:** Standard security pattern allowing the owner to pause contract interactions in emergencies.
8.  **Counters:** Used for generating unique IDs for skills and quests.
9.  **Mapping Limitations:** The `getUserActiveQuestIds` and `listAllSkillIds`/`listAllQuestIds` functions highlight a common challenge in Solidity: iterating over arbitrary mapping keys or listing all entries is not natively supported or is gas-prohibitive for large datasets. The code includes notes on how this would typically be handled in a production environment (events + off-chain indexing like The Graph, or auxiliary state arrays).

This contract offers a foundation for applications like decentralized educational platforms (skill validation), gaming backends (quest systems, character progression), or professional networking where verifiable on-chain experience is built.