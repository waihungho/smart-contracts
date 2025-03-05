```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill-Based Reputation System
 * @author Bard (Example Smart Contract)
 * @dev A smart contract for managing user profiles, skills, and decentralized reputation based on skill endorsements.
 *
 * **Outline and Function Summary:**
 *
 * **User Profile Management:**
 *   1. `registerUser(string _name)`: Allows a user to register a profile with a name.
 *   2. `updateProfileName(string _newName)`: Allows a registered user to update their profile name.
 *   3. `addSkill(string _skill)`: Allows a registered user to add a skill to their profile.
 *   4. `removeSkill(string _skill)`: Allows a registered user to remove a skill from their profile.
 *   5. `getUserProfile(address _user) view returns (UserProfile)`: Retrieves a user's profile information.
 *   6. `isUserRegistered(address _user) view returns (bool)`: Checks if an address is registered as a user.
 *
 * **Skill Endorsement and Reputation:**
 *   7. `endorseSkill(address _userToEndorse, string _skill)`: Allows registered users to endorse other users for specific skills.
 *   8. `withdrawEndorsement(address _userToWithdraw, string _skill)`: Allows users to withdraw their endorsements.
 *   9. `getSkillEndorsements(address _user, string _skill) view returns (uint256)`: Retrieves the number of endorsements a user has for a specific skill.
 *  10. `calculateReputation(address _user) internal`: (Internal) Calculates a user's reputation score based on endorsements (customizable algorithm).
 *  11. `getReputationScore(address _user) view returns (uint256)`: Retrieves a user's overall reputation score.
 *  12. `getTopUsersByReputation(uint256 _count) view returns (UserProfile[])`: Returns an array of top users sorted by reputation.
 *
 * **Skill Management (Admin Controlled):**
 *  13. `addAvailableSkill(string _skill) onlyOwner`: Allows the contract owner to add a new skill to the list of available skills in the system.
 *  14. `removeAvailableSkill(string _skill) onlyOwner`: Allows the contract owner to remove a skill from the list of available skills.
 *  15. `getAvailableSkills() view returns (string[])`: Retrieves the list of currently available skills in the system.
 *
 * **Reputation Modifier Functions (Admin Controlled):**
 *  16. `boostReputation(address _user, uint256 _amount) onlyOwner`: Allows the contract owner to manually boost a user's reputation (e.g., for exceptional contributions).
 *  17. `penalizeReputation(address _user, uint256 _amount) onlyOwner`: Allows the contract owner to manually penalize a user's reputation (e.g., for policy violations).
 *  18. `setEndorsementWeight(uint256 _weight) onlyOwner`: Allows the contract owner to adjust the weight of each endorsement in reputation calculation.
 *
 * **Utility and Contract Management:**
 *  19. `pauseContract() onlyOwner`: Pauses core contract functionalities (excluding essential reads).
 *  20. `unpauseContract() onlyOwner`: Resumes contract functionalities after pausing.
 *  21. `isContractPaused() view returns (bool)`: Checks if the contract is currently paused.
 *  22. `setContractOwner(address _newOwner) onlyOwner`: Allows the current owner to transfer contract ownership.
 *  23. `getTotalUsers() view returns (uint256)`: Returns the total number of registered users.
 *  24. `getTotalEndorsementsGiven() view returns (uint256)`: Returns the total number of endorsements given in the system.
 */
contract SkillReputationSystem {
    // --- State Variables ---

    struct UserProfile {
        address userAddress;
        string name;
        string[] skills;
        uint256 reputationScore;
        mapping(string => uint256) skillEndorsementsCount; // Skill -> Endorsement Count
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => bool) public isRegisteredUser;
    string[] public availableSkills;
    mapping(string => bool) public isAvailableSkill; // For faster skill validation

    address public owner;
    bool public paused;
    uint256 public endorsementWeight = 10; // Weight of each endorsement in reputation calculation
    uint256 public totalUsers = 0;
    uint256 public totalEndorsements = 0;

    // --- Events ---

    event UserRegistered(address userAddress, string name);
    event ProfileNameUpdated(address userAddress, string newName);
    event SkillAddedToProfile(address userAddress, string skill);
    event SkillRemovedFromProfile(address userAddress, string skill);
    event SkillEndorsed(address endorser, address endorsedUser, string skill);
    event EndorsementWithdrawn(address endorser, address endorsedUser, string skill);
    event ReputationScoreUpdated(address userAddress, uint256 newScore);
    event AvailableSkillAdded(string skill);
    event AvailableSkillRemoved(string skill);
    event ReputationBoosted(address userAddress, uint256 amount, address admin);
    event ReputationPenalized(address userAddress, uint256 amount, address admin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event OwnershipTransferred(address previousOwner, address newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyRegisteredUser() {
        require(isRegisteredUser[msg.sender], "You must be a registered user to perform this action.");
        _;
    }

    modifier validSkill(string memory _skill) {
        require(isAvailableSkill[_skill], "Skill is not valid or available in the system.");
        _;
    }

    modifier notSelfEndorsement(address _userToEndorse) {
        require(msg.sender != _userToEndorse, "You cannot endorse yourself.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    // --- User Profile Management Functions ---

    /// @notice Registers a new user profile.
    /// @param _name The name of the user.
    function registerUser(string memory _name) external whenNotPaused {
        require(!isRegisteredUser[msg.sender], "User already registered.");
        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            name: _name,
            skills: new string[](0),
            reputationScore: 0,
            skillEndorsementsCount: mapping(string => uint256)()
        });
        isRegisteredUser[msg.sender] = true;
        totalUsers++;
        emit UserRegistered(msg.sender, _name);
    }

    /// @notice Updates the name of an existing user profile.
    /// @param _newName The new name for the user profile.
    function updateProfileName(string memory _newName) external onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender].name = _newName;
        emit ProfileNameUpdated(msg.sender, _newName);
    }

    /// @notice Adds a skill to a user's profile, if the skill is available in the system.
    /// @param _skill The skill to add.
    function addSkill(string memory _skill) external onlyRegisteredUser whenNotPaused validSkill(_skill) {
        UserProfile storage profile = userProfiles[msg.sender];
        for (uint256 i = 0; i < profile.skills.length; i++) {
            if (keccak256(abi.encodePacked(profile.skills[i])) == keccak256(abi.encodePacked(_skill))) {
                revert("Skill already added to profile.");
            }
        }
        profile.skills.push(_skill);
        emit SkillAddedToProfile(msg.sender, _skill);
    }

    /// @notice Removes a skill from a user's profile.
    /// @param _skill The skill to remove.
    function removeSkill(string memory _skill) external onlyRegisteredUser whenNotPaused {
        UserProfile storage profile = userProfiles[msg.sender];
        bool skillRemoved = false;
        for (uint256 i = 0; i < profile.skills.length; i++) {
            if (keccak256(abi.encodePacked(profile.skills[i])) == keccak256(abi.encodePacked(_skill))) {
                delete profile.skills[i];
                skillRemoved = true;
                // To maintain array compactness, shift elements after removal (gas intensive for large arrays, consider alternative for production)
                for (uint256 j = i; j < profile.skills.length - 1; j++) {
                    profile.skills[j] = profile.skills[j + 1];
                }
                profile.skills.pop();
                break;
            }
        }
        require(skillRemoved, "Skill not found in profile.");
        emit SkillRemovedFromProfile(msg.sender, _skill);
    }

    /// @notice Retrieves a user's profile information.
    /// @param _user The address of the user.
    /// @return UserProfile struct containing the user's profile data.
    function getUserProfile(address _user) external view returns (UserProfile memory) {
        require(isRegisteredUser[_user], "User is not registered.");
        return userProfiles[_user];
    }

    /// @notice Checks if an address is registered as a user.
    /// @param _user The address to check.
    /// @return bool True if the address is registered, false otherwise.
    function isUserRegistered(address _user) external view returns (bool) {
        return isRegisteredUser[_user];
    }

    // --- Skill Endorsement and Reputation Functions ---

    /// @notice Allows a registered user to endorse another registered user for a specific skill.
    /// @param _userToEndorse The address of the user being endorsed.
    /// @param _skill The skill for which the user is being endorsed.
    function endorseSkill(address _userToEndorse, string memory _skill) external onlyRegisteredUser whenNotPaused validSkill(_skill) notSelfEndorsement(_userToEndorse) {
        require(isRegisteredUser[_userToEndorse], "User to endorse is not registered.");
        UserProfile storage endorsedProfile = userProfiles[_userToEndorse];
        bool hasSkill = false;
        for (uint256 i = 0; i < endorsedProfile.skills.length; i++) {
            if (keccak256(abi.encodePacked(endorsedProfile.skills[i])) == keccak256(abi.encodePacked(_skill))) {
                hasSkill = true;
                break;
            }
        }
        require(hasSkill, "User does not have this skill in their profile.");

        endorsedProfile.skillEndorsementsCount[_skill]++;
        _updateReputation(_userToEndorse);
        totalEndorsements++;
        emit SkillEndorsed(msg.sender, _userToEndorse, _skill);
    }

    /// @notice Allows a user to withdraw their endorsement for another user's skill.
    /// @param _userToWithdraw The address of the user whose endorsement is being withdrawn.
    /// @param _skill The skill for which the endorsement is being withdrawn.
    function withdrawEndorsement(address _userToWithdraw, string memory _skill) external onlyRegisteredUser whenNotPaused {
        require(isRegisteredUser[_userToWithdraw], "User whose endorsement is being withdrawn is not registered.");
        UserProfile storage endorsedProfile = userProfiles[_userToWithdraw];
        require(endorsedProfile.skillEndorsementsCount[_skill] > 0, "No endorsement exists for this skill from you to withdraw.");

        endorsedProfile.skillEndorsementsCount[_skill]--;
        _updateReputation(_userToWithdraw);
        totalEndorsements--; // Potentially decrement totalEndorsements if needed for accurate count tracking
        emit EndorsementWithdrawn(msg.sender, _userToWithdraw, _skill);
    }

    /// @notice Retrieves the number of endorsements a user has for a specific skill.
    /// @param _user The address of the user.
    /// @param _skill The skill to check endorsements for.
    /// @return uint256 The number of endorsements for the skill.
    function getSkillEndorsements(address _user, string memory _skill) external view returns (uint256) {
        require(isRegisteredUser[_user], "User is not registered.");
        return userProfiles[_user].skillEndorsementsCount[_skill];
    }

    /// @notice (Internal) Calculates and updates a user's reputation score based on their skill endorsements.
    /// @param _user The address of the user whose reputation is being updated.
    function _updateReputation(address _user) internal {
        uint256 newReputation = calculateReputation(_user);
        userProfiles[_user].reputationScore = newReputation;
        emit ReputationScoreUpdated(_user, newReputation);
    }

    /// @notice Calculates a user's reputation score based on their skill endorsements.
    /// @param _user The address of the user.
    /// @return uint256 The calculated reputation score.
    function calculateReputation(address _user) public view returns (uint256) {
        uint256 reputation = 0;
        UserProfile memory profile = userProfiles[_user];
        for (uint256 i = 0; i < profile.skills.length; i++) {
            reputation += profile.skillEndorsementsCount[profile.skills[i]] * endorsementWeight; // Simple linear model, can be customized
        }
        return reputation;
    }

    /// @notice Retrieves a user's overall reputation score.
    /// @param _user The address of the user.
    /// @return uint256 The user's reputation score.
    function getReputationScore(address _user) external view returns (uint256) {
        require(isRegisteredUser[_user], "User is not registered.");
        return userProfiles[_user].reputationScore;
    }

    /// @notice Retrieves an array of top users sorted by reputation score.
    /// @param _count The number of top users to retrieve.
    /// @return UserProfile[] An array of UserProfile structs, sorted by reputation in descending order.
    function getTopUsersByReputation(uint256 _count) external view returns (UserProfile[] memory) {
        uint256 userCount = totalUsers;
        uint256 count = _count > userCount ? userCount : _count; // Limit count to total users
        UserProfile[] memory topUsers = new UserProfile[](count);
        UserProfile[] memory allUsers = new UserProfile[](userCount);
        uint256 index = 0;

        // Collect all user profiles into an array
        for (uint256 i = 0; i < userCount; i++) {
            address userAddress;
            if (i < userCount) { // Iterate through registered users (not ideal for sparse registrations in production)
                uint256 userIndex = 0;
                uint256 usersFound = 0;
                for (uint256 j = 0; j < userCount; j++) { // Inefficient, consider a more efficient way to iterate through registered users in production
                    if(usersFound == i){
                        for(uint256 addrIndex = 0; addrIndex < userCount; addrIndex++){ // Extremely inefficient, but illustrative for concept
                            address potentialUser = address(uint160(uint256(keccak256(abi.encodePacked(addrIndex))))); // Pseudo address generation for example - replace with actual user iteration logic
                            if(isRegisteredUser[potentialUser]){
                                if(userIndex == usersFound){
                                    userAddress = potentialUser;
                                    break;
                                }
                                userIndex++;
                            }
                        }
                        break;
                    }
                    usersFound++;
                }

                if(isRegisteredUser[userAddress]){ // Double check registration - improve user iteration logic for production
                    allUsers[index] = userProfiles[userAddress];
                    index++;
                }
            }

        }

        // Bubble sort (or more efficient sort for larger sets in production) by reputation descending
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - i - 1; j++) {
                if (allUsers[j].reputationScore < allUsers[j + 1].reputationScore) {
                    UserProfile memory temp = allUsers[j];
                    allUsers[j] = allUsers[j + 1];
                    allUsers[j + 1] = temp;
                }
            }
        }

        // Copy top 'count' users to the result array
        for (uint256 i = 0; i < count; i++) {
            topUsers[i] = allUsers[i];
        }

        return topUsers;
    }


    // --- Skill Management Functions (Admin Only) ---

    /// @notice Adds a new skill to the list of available skills in the system.
    /// @param _skill The skill to add.
    function addAvailableSkill(string memory _skill) external onlyOwner whenNotPaused {
        require(!isAvailableSkill[_skill], "Skill already exists.");
        availableSkills.push(_skill);
        isAvailableSkill[_skill] = true;
        emit AvailableSkillAdded(_skill);
    }

    /// @notice Removes a skill from the list of available skills in the system.
    /// @param _skill The skill to remove.
    function removeAvailableSkill(string memory _skill) external onlyOwner whenNotPaused {
        require(isAvailableSkill[_skill], "Skill does not exist or is not available.");
        isAvailableSkill[_skill] = false;
        bool skillRemoved = false;
        for (uint256 i = 0; i < availableSkills.length; i++) {
            if (keccak256(abi.encodePacked(availableSkills[i])) == keccak256(abi.encodePacked(_skill))) {
                delete availableSkills[i];
                skillRemoved = true;
                // To maintain array compactness, shift elements after removal
                for (uint256 j = i; j < availableSkills.length - 1; j++) {
                    availableSkills[j] = availableSkills[j + 1];
                }
                availableSkills.pop();
                break;
            }
        }
        require(skillRemoved, "Skill not found in available skills list.");
        emit AvailableSkillRemoved(_skill);
    }

    /// @notice Retrieves the list of currently available skills in the system.
    /// @return string[] An array of available skills.
    function getAvailableSkills() external view returns (string[] memory) {
        return availableSkills;
    }

    // --- Reputation Modifier Functions (Admin Only) ---

    /// @notice Manually boosts a user's reputation score.
    /// @param _user The address of the user to boost reputation for.
    /// @param _amount The amount to boost the reputation by.
    function boostReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        require(isRegisteredUser[_user], "User is not registered.");
        userProfiles[_user].reputationScore += _amount;
        emit ReputationBoosted(_user, _amount, msg.sender);
        emit ReputationScoreUpdated(_user, userProfiles[_user].reputationScore);
    }

    /// @notice Manually penalizes a user's reputation score.
    /// @param _user The address of the user to penalize reputation for.
    /// @param _amount The amount to penalize the reputation by.
    function penalizeReputation(address _user, uint256 _amount) external onlyOwner whenNotPaused {
        require(isRegisteredUser[_user], "User is not registered.");
        // Prevent reputation from going below zero (optional, adjust as needed)
        userProfiles[_user].reputationScore = userProfiles[_user].reputationScore > _amount ? userProfiles[_user].reputationScore - _amount : 0;
        emit ReputationPenalized(_user, _amount, msg.sender);
        emit ReputationScoreUpdated(_user, userProfiles[_user].reputationScore);
    }

    /// @notice Sets the weight of each endorsement in the reputation calculation.
    /// @param _weight The new weight value.
    function setEndorsementWeight(uint256 _weight) external onlyOwner whenNotPaused {
        endorsementWeight = _weight;
    }

    // --- Utility and Contract Management Functions (Admin Only) ---

    /// @notice Pauses the contract, preventing most state-changing operations.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes the contract, allowing state-changing operations to proceed.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return bool True if the contract is paused, false otherwise.
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /// @notice Allows the current owner to transfer contract ownership to a new address.
    /// @param _newOwner The address of the new owner.
    function setContractOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner address cannot be zero.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// @notice Returns the total number of registered users.
    /// @return uint256 The total number of registered users.
    function getTotalUsers() external view returns (uint256) {
        return totalUsers;
    }

    /// @notice Returns the total number of endorsements given in the system.
    /// @return uint256 The total number of endorsements.
    function getTotalEndorsementsGiven() external view returns (uint256) {
        return totalEndorsements;
    }
}
```