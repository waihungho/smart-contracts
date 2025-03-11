```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Skill Oracle Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic reputation and skill tracking system,
 *      leveraging on-chain and off-chain (simulated oracle) data to create evolving user profiles.
 *      This contract allows users to build reputation through various on-chain activities and acquire
 *      and showcase skills, making it a dynamic representation of their blockchain presence.
 *
 * **Outline:**
 * 1. **Profile Management:**
 *    - `registerProfile()`: Allows users to create a profile.
 *    - `updateProfileName()`:  Allows users to update their profile name.
 *    - `updateProfileBio()`: Allows users to update their profile bio.
 *    - `setProfileAvatar()`: Allows users to set a profile avatar URI.
 *    - `getProfile()`: Retrieves a user's profile information.
 *    - `isProfileRegistered()`: Checks if a user has a profile.
 *
 * 2. **Reputation System:**
 *    - `increaseReputation()`: Increases a user's reputation (e.g., for positive actions).
 *    - `decreaseReputation()`: Decreases a user's reputation (e.g., for negative actions - admin only).
 *    - `getReputation()`: Retrieves a user's reputation score.
 *    - `voteForReputation()`: Allows users to vote for another user's reputation (weighted voting).
 *    - `withdrawVotingRewards()`: Allows voters to withdraw accumulated rewards (if any).
 *
 * 3. **Skill Tracking & Badges:**
 *    - `addSkill()`: Allows admin to add a new skill to the system.
 *    - `awardSkillBadge()`: Allows admin to award a skill badge to a user.
 *    - `revokeSkillBadge()`: Allows admin to revoke a skill badge from a user.
 *    - `getUserSkills()`: Retrieves the list of skills a user possesses.
 *    - `getSkillDetails()`: Retrieves details of a specific skill.
 *
 * 4. **Activity Tracking (Simulated Oracle - On-chain for demonstration):**
 *    - `simulateExternalActivity()`: Simulates an oracle reporting external activity completion (e.g., completing a task, contributing to a project).
 *    - `recordActivityCompletion()`: Records activity completion and potentially rewards reputation/skills (oracle-triggered).
 *    - `getActivityCount()`: Gets the number of activities completed by a user.
 *
 * 5. **Customization & Preferences:**
 *    - `setUserProfileVisibility()`: Allows users to set profile visibility preferences (public/private).
 *    - `getProfileVisibility()`: Retrieves a user's profile visibility setting.
 *
 * 6. **Admin & Utility Functions:**
 *    - `setAdmin()`: Allows the contract owner to change the admin role.
 *    - `pauseContract()`: Pauses the contract functionality.
 *    - `unpauseContract()`: Resumes the contract functionality.
 *    - `withdrawContractBalance()`: Allows the owner to withdraw contract ETH balance.
 *
 * **Function Summaries:**
 * - **Profile Management:** Functions for creating, updating, and retrieving user profiles.
 * - **Reputation System:** Functions for managing user reputation scores, voting, and rewards.
 * - **Skill Tracking & Badges:** Functions for managing skills and awarding/revoking skill badges.
 * - **Activity Tracking (Simulated Oracle):** Functions simulating external activity reporting and recording.
 * - **Customization & Preferences:** Functions for user profile visibility settings.
 * - **Admin & Utility Functions:** Functions for contract administration, pausing, and withdrawals.
 */

contract DynamicReputationOracle {

    // --- Structs ---
    struct UserProfile {
        string name;
        string bio;
        string avatarURI;
        uint256 reputation;
        bool isRegistered;
        bool isProfilePublic;
    }

    struct Skill {
        string skillName;
        string description;
        uint256 badgeCount;
    }

    struct Activity {
        string activityName;
        uint256 timestamp;
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Skill) public skills; // Skill ID => Skill
    mapping(address => mapping(uint256 => bool)) public userSkills; // User => Skill ID => Has Skill
    mapping(address => Activity[]) public userActivities; // User => Array of Activities
    mapping(address => uint256) public reputationScores;
    mapping(address => uint256) public votingPower; // Example voting power, could be based on staked tokens etc.
    mapping(address => mapping(address => uint256)) public reputationVotes; // Voter => User voted for => Vote Value (e.g., 1 for upvote, -1 for downvote)

    address public owner;
    address public admin;
    uint256 public skillCount;
    bool public paused;

    // --- Events ---
    event ProfileRegistered(address user, string name);
    event ProfileUpdated(address user, string name);
    event ReputationIncreased(address user, uint256 amount);
    event ReputationDecreased(address user, uint256 amount);
    event SkillAdded(uint256 skillId, string skillName);
    event SkillBadgeAwarded(address user, uint256 skillId);
    event SkillBadgeRevoked(address user, uint256 skillId);
    event ActivityRecorded(address user, string activityName);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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
        require(userProfiles[_user].isRegistered, "Profile not registered.");
        _;
    }

    modifier profileNotExists(address _user) {
        require(!userProfiles[_user].isRegistered, "Profile already registered.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        admin = msg.sender; // Initially, owner is also admin
        paused = false;
        skillCount = 0;
    }

    // --- 1. Profile Management ---
    function registerProfile(string memory _name, string memory _bio, string memory _avatarURI) external whenNotPaused profileNotExists(msg.sender) {
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            bio: _bio,
            avatarURI: _avatarURI,
            reputation: 0,
            isRegistered: true,
            isProfilePublic: true // Default visibility: public
        });
        emit ProfileRegistered(msg.sender, _name);
    }

    function updateProfileName(string memory _newName) external whenNotPaused profileExists(msg.sender) {
        userProfiles[msg.sender].name = _newName;
        emit ProfileUpdated(msg.sender, _newName);
    }

    function updateProfileBio(string memory _newBio) external whenNotPaused profileExists(msg.sender) {
        userProfiles[msg.sender].bio = _newBio;
        emit ProfileUpdated(msg.sender, userProfiles[msg.sender].name);
    }

    function setProfileAvatar(string memory _avatarURI) external whenNotPaused profileExists(msg.sender) {
        userProfiles[msg.sender].avatarURI = _avatarURI;
        emit ProfileUpdated(msg.sender, userProfiles[msg.sender].name);
    }

    function getProfile(address _user) external view profileExists(_user) returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function isProfileRegistered(address _user) external view returns (bool) {
        return userProfiles[_user].isRegistered;
    }

    // --- 2. Reputation System ---
    function increaseReputation(address _user, uint256 _amount) external onlyAdmin whenNotPaused profileExists(_user) {
        reputationScores[_user] += _amount;
        userProfiles[_user].reputation = reputationScores[_user];
        emit ReputationIncreased(_user, _amount);
    }

    function decreaseReputation(address _user, uint256 _amount) external onlyAdmin whenNotPaused profileExists(_user) {
        // Add checks to prevent reputation from going negative if needed
        if (reputationScores[_user] >= _amount) {
            reputationScores[_user] -= _amount;
        } else {
            reputationScores[_user] = 0; // Or handle negative reputation differently
        }
        userProfiles[_user].reputation = reputationScores[_user];
        emit ReputationDecreased(_user, _amount);
    }

    function getReputation(address _user) external view profileExists(_user) returns (uint256) {
        return reputationScores[_user];
    }

    function voteForReputation(address _targetUser, int8 _voteValue) external whenNotPaused profileExists(msg.sender) profileExists(_targetUser) {
        require(msg.sender != _targetUser, "Cannot vote for yourself.");
        require(votingPower[msg.sender] > 0, "No voting power available."); // Example: Voting power required
        require(reputationVotes[msg.sender][_targetUser] == 0, "Already voted for this user."); // Prevent double voting

        uint256 voteWeight = votingPower[msg.sender]; // In a real system, this might be derived from token holdings, activity, etc.

        if (_voteValue > 0) { // Positive vote
            increaseReputation(_targetUser, voteWeight);
        } else if (_voteValue < 0) { // Negative vote
            decreaseReputation(_targetUser, voteWeight);
        } else {
            revert("Invalid vote value.");
        }

        reputationVotes[msg.sender][_targetUser] = uint256(_voteValue); // Store vote direction (using uint256 to avoid potential issues with negative storage)
        votingPower[msg.sender] -= 1; // Decrease voting power after voting - example mechanism
        // In a more complex system, you might have voting periods, reward mechanisms for voters, etc.
    }

    // function withdrawVotingRewards() external {} // Placeholder for potential voting reward mechanism

    // --- 3. Skill Tracking & Badges ---
    function addSkill(string memory _skillName, string memory _description) external onlyAdmin whenNotPaused {
        skillCount++;
        skills[skillCount] = Skill({
            skillName: _skillName,
            description: _description,
            badgeCount: 0
        });
        emit SkillAdded(skillCount, _skillName);
    }

    function awardSkillBadge(address _user, uint256 _skillId) external onlyAdmin whenNotPaused profileExists(_user) {
        require(skills[_skillId].skillName.length > 0, "Skill does not exist.");
        require(!userSkills[_user][_skillId], "Skill badge already awarded."); // Prevent awarding duplicate badges

        userSkills[_user][_skillId] = true;
        skills[_skillId].badgeCount++;
        emit SkillBadgeAwarded(_user, _skillId);
    }

    function revokeSkillBadge(address _user, uint256 _skillId) external onlyAdmin whenNotPaused profileExists(_user) {
        require(skills[_skillId].skillName.length > 0, "Skill does not exist.");
        require(userSkills[_user][_skillId], "Skill badge not awarded to revoke.");

        userSkills[_user][_skillId] = false;
        skills[_skillId].badgeCount--;
        emit SkillBadgeRevoked(_user, _skillId);
    }

    function getUserSkills(address _user) external view profileExists(_user) returns (uint256[] memory) {
        uint256[] memory userSkillIds = new uint256[](skillCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= skillCount; i++) {
            if (userSkills[_user][i]) {
                userSkillIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of skills
        assembly {
            mstore(userSkillIds, count) // Update length in memory
        }
        return userSkillIds;
    }

    function getSkillDetails(uint256 _skillId) external view returns (Skill memory) {
        return skills[_skillId];
    }

    // --- 4. Activity Tracking (Simulated Oracle) ---
    // In a real system, this would be called by an off-chain oracle based on external events.
    function simulateExternalActivity(address _user, string memory _activityName) external onlyAdmin whenNotPaused profileExists(_user) {
        // In a real oracle setup, validation and checks would be done by the oracle itself.
        recordActivityCompletion(_user, _activityName);
    }

    function recordActivityCompletion(address _user, string memory _activityName) internal whenNotPaused profileExists(_user) {
        userActivities[_user].push(Activity({
            activityName: _activityName,
            timestamp: block.timestamp
        }));
        emit ActivityRecorded(_user, _activityName);
        // Optionally reward reputation or skills based on activity here.
        increaseReputation(_user, 5); // Example: Small reputation reward for each activity
    }

    function getActivityCount(address _user) external view profileExists(_user) returns (uint256) {
        return userActivities[_user].length;
    }

    function getUserActivities(address _user) external view profileExists(_user) returns (Activity[] memory) {
        return userActivities[_user];
    }


    // --- 5. Customization & Preferences ---
    function setUserProfileVisibility(bool _isPublic) external whenNotPaused profileExists(msg.sender) {
        userProfiles[msg.sender].isProfilePublic = _isPublic;
        emit ProfileUpdated(msg.sender, userProfiles[msg.sender].name);
    }

    function getProfileVisibility(address _user) external view profileExists(_user) returns (bool) {
        return userProfiles[_user].isProfilePublic;
    }


    // --- 6. Admin & Utility Functions ---
    function setAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Invalid admin address.");
        admin = _newAdmin;
    }

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    function withdrawContractBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {} // Allow contract to receive ETH

    fallback() external {} // Fallback function
}
```