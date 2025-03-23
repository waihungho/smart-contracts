```solidity
/**
 * @title SkillBasedReputationSystem - A Smart Contract for Skill-Based Reputation and Gamification
 * @author Gemini AI (Based on User Request)
 * @dev This contract implements a skill-based reputation system where users can acquire skills,
 * level up those skills through actions (simulated here), and earn reputation based on their skill levels.
 * It incorporates gamification elements like level progression, reputation ranking, and potential for token rewards.
 *
 * **Outline:**
 *
 * **1. Skill Management (Admin-Controlled):**
 *    - `addSkillType(string skillName)`: Adds a new skill type to the system.
 *    - `getSkillTypes()`: Returns a list of all registered skill types.
 *    - `setSkillLevelThresholds(uint256 skillId, uint256[] thresholds)`: Sets the experience points required for each level of a skill.
 *    - `getSkillLevelThresholds(uint256 skillId)`: Retrieves the level thresholds for a specific skill.
 *
 * **2. User Skill Acquisition and Progression:**
 *    - `acquireSkill(uint256 skillId)`: Allows a user to acquire a specific skill (starts at level 1).
 *    - `getUserSkills(address user)`: Returns a list of skills acquired by a user.
 *    - `getSkillLevel(address user, uint256 skillId)`: Returns the current level of a specific skill for a user.
 *    - `getSkillExperience(address user, uint256 skillId)`: Returns the current experience points for a specific skill of a user.
 *    - `increaseSkillExperience(address user, uint256 skillId, uint256 experiencePoints)`: Allows adding experience points to a user's skill, triggering level ups if thresholds are met.
 *
 * **3. Reputation System:**
 *    - `calculateReputation(address user)`: Calculates a user's reputation score based on their skill levels.
 *    - `getReputation(address user)`: Returns the calculated reputation score of a user.
 *    - `getTopReputationUsers(uint256 count)`: Returns a list of addresses with the highest reputation scores, up to a specified count.
 *
 * **4. Token Integration (Optional Gamification):**
 *    - `setRewardToken(address tokenAddress)`: Sets the address of an ERC20 token to be used for rewards.
 *    - `setRewardAmountPerLevel(uint256 skillId, uint256 rewardAmount)`: Sets the reward amount of tokens for reaching a new level in a specific skill.
 *    - `claimLevelUpReward(uint256 skillId)`: Allows a user to claim token rewards upon leveling up a skill.
 *    - `getUserTokenBalance(address user)`: Returns the token balance held by the contract for a user (for rewards).
 *
 * **5. Admin and Utility Functions:**
 *    - `setAdmin(address newAdmin)`: Changes the contract administrator.
 *    - `isAdmin(address account)`: Checks if an address is the contract administrator.
 *    - `pauseContract()`: Pauses the contract, restricting certain functions.
 *    - `unpauseContract()`: Unpauses the contract, restoring full functionality.
 *    - `isPaused()`: Checks if the contract is currently paused.
 *    - `withdrawAdminFunds(address payable recipient)`: Allows the admin to withdraw any accidentally sent Ether to the contract.
 *
 * **Function Summary:**
 *
 * - **Skill Management:** Functions for adding, viewing, and configuring skill types and level thresholds.
 * - **User Skills:** Functions for users to acquire skills, view their skills and levels, and progress their skills by gaining experience.
 * - **Reputation:** Functions to calculate and retrieve user reputation based on their skill levels, and to get a reputation leaderboard.
 * - **Token Rewards:** Functions to integrate an ERC20 token for rewarding users upon leveling up skills (optional gamification feature).
 * - **Admin/Utility:** Functions for contract administration, pausing/unpausing, and basic utility operations.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SkillBasedReputationSystem is Ownable, Pausable {
    using Strings for uint256;

    // --- Data Structures ---
    struct SkillType {
        string name;
        uint256[] levelThresholds; // Experience points needed for each level (e.g., [100, 250, 500] for level 2, 3, 4)
        uint256 rewardAmountPerLevel; // Token reward per level up, if applicable
    }

    struct UserSkillData {
        uint256 level;
        uint256 experience;
        uint256 lastLevelUpLevel; // Track last level up to prevent double rewards in same level
    }

    // --- State Variables ---
    mapping(uint256 => SkillType) public skillTypes; // skillId => SkillType
    uint256 public skillTypeCount;
    mapping(address => mapping(uint256 => UserSkillData)) public userSkills; // userAddress => (skillId => UserSkillData)
    IERC20 public rewardToken; // Optional ERC20 reward token
    mapping(address => uint256) public userTokenBalances; // Track token balances for rewards (internal contract balance tracking)

    // --- Events ---
    event SkillTypeAdded(uint256 skillId, string skillName);
    event SkillLevelThresholdsSet(uint256 skillId, uint256[] thresholds);
    event SkillAcquired(address user, uint256 skillId);
    event SkillExperienceIncreased(address user, uint256 skillId, uint256 experiencePoints, uint256 newExperience);
    event SkillLevelUp(address user, uint256 skillId, uint256 newLevel);
    event ReputationCalculated(address user, uint256 reputationScore);
    event RewardTokenSet(address tokenAddress);
    event RewardAmountPerLevelSet(uint256 skillId, uint256 rewardAmount);
    event LevelUpRewardClaimed(address user, uint256 skillId, uint256 rewardAmount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminFundsWithdrawn(address admin, address recipient, uint256 amount);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admin can perform this action");
        _;
    }

    modifier validSkillId(uint256 skillId) {
        require(skillId > 0 && skillId <= skillTypeCount, "Invalid skill ID");
        _;
    }

    modifier skillExists(uint256 skillId) {
        require(skillTypes[skillId].name.length > 0, "Skill type does not exist");
        _;
    }

    modifier skillNotAcquired(address user, uint256 skillId) {
        require(userSkills[user][skillId].level == 0, "Skill already acquired");
        _;
    }

    modifier skillAcquired(address user, uint256 skillId) {
        require(userSkills[user][skillId].level > 0, "Skill not acquired");
        _;
    }

    // --- Constructor ---
    constructor() {
        // Set the deployer as the initial admin (Ownerable constructor handles this)
    }

    // --- 1. Skill Management (Admin-Controlled) ---

    /**
     * @dev Adds a new skill type to the system. Only admin can call this function.
     * @param skillName The name of the new skill.
     */
    function addSkillType(string memory skillName) external onlyAdmin whenNotPaused {
        require(bytes(skillName).length > 0, "Skill name cannot be empty");
        skillTypeCount++;
        skillTypes[skillTypeCount] = SkillType({
            name: skillName,
            levelThresholds: new uint256[](0), // Initially no level thresholds
            rewardAmountPerLevel: 0
        });
        emit SkillTypeAdded(skillTypeCount, skillName);
    }

    /**
     * @dev Returns a list of all registered skill types (names).
     * @return A string array of skill names.
     */
    function getSkillTypes() external view returns (string[] memory) {
        string[] memory names = new string[](skillTypeCount);
        for (uint256 i = 1; i <= skillTypeCount; i++) {
            names[i - 1] = skillTypes[i].name;
        }
        return names;
    }

    /**
     * @dev Sets the experience points required for each level of a skill. Only admin can call this.
     * @param skillId The ID of the skill to set thresholds for.
     * @param thresholds An array of experience points required for each level (starting from level 2).
     */
    function setSkillLevelThresholds(uint256 skillId, uint256[] memory thresholds) external onlyAdmin validSkillId skillExists(skillId) whenNotPaused {
        skillTypes[skillId].levelThresholds = thresholds;
        emit SkillLevelThresholdsSet(skillId, thresholds);
    }

    /**
     * @dev Retrieves the level thresholds for a specific skill.
     * @param skillId The ID of the skill.
     * @return An array of experience points required for each level.
     */
    function getSkillLevelThresholds(uint256 skillId) external view validSkillId skillExists(skillId) returns (uint256[] memory) {
        return skillTypes[skillId].levelThresholds;
    }

    // --- 2. User Skill Acquisition and Progression ---

    /**
     * @dev Allows a user to acquire a specific skill. Starts at level 1 with 0 experience.
     * @param skillId The ID of the skill to acquire.
     */
    function acquireSkill(uint256 skillId) external whenNotPaused validSkillId skillExists(skillId) skillNotAcquired(msg.sender, skillId) {
        userSkills[msg.sender][skillId] = UserSkillData({
            level: 1,
            experience: 0,
            lastLevelUpLevel: 0
        });
        emit SkillAcquired(msg.sender, skillId);
    }

    /**
     * @dev Returns a list of skills acquired by a user (skill IDs).
     * @param user The address of the user.
     * @return An array of skill IDs.
     */
    function getUserSkills(address user) external view returns (uint256[] memory) {
        uint256[] memory acquiredSkillIds = new uint256[](skillTypeCount); // Max possible skills
        uint256 count = 0;
        for (uint256 i = 1; i <= skillTypeCount; i++) {
            if (userSkills[user][i].level > 0) {
                acquiredSkillIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of skills
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = acquiredSkillIds[i];
        }
        return result;
    }

    /**
     * @dev Returns the current level of a specific skill for a user.
     * @param user The address of the user.
     * @param skillId The ID of the skill.
     * @return The skill level.
     */
    function getSkillLevel(address user, uint256 skillId) external view validSkillId skillExists(skillId) skillAcquired(user, skillId) returns (uint256) {
        return userSkills[user][skillId].level;
    }

    /**
     * @dev Returns the current experience points for a specific skill of a user.
     * @param user The address of the user.
     * @param skillId The ID of the skill.
     * @return The skill experience points.
     */
    function getSkillExperience(address user, uint256 skillId) external view validSkillId skillExists(skillId) skillAcquired(user, skillId) returns (uint256) {
        return userSkills[user][skillId].experience;
    }

    /**
     * @dev Allows adding experience points to a user's skill. Triggers level ups if thresholds are met.
     * @param user The address of the user.
     * @param skillId The ID of the skill to increase experience for.
     * @param experiencePoints The amount of experience points to add.
     */
    function increaseSkillExperience(address user, uint256 skillId, uint256 experiencePoints) external whenNotPaused validSkillId skillExists(skillId) skillAcquired(user, skillId) {
        require(experiencePoints > 0, "Experience points must be positive");
        UserSkillData storage skillData = userSkills[user][skillId];
        uint256 oldLevel = skillData.level;
        skillData.experience += experiencePoints;
        emit SkillExperienceIncreased(user, skillId, experiencePoints, skillData.experience);

        uint256 currentLevel = skillData.level;
        uint256[] memory thresholds = skillTypes[skillId].levelThresholds;

        // Level Up Logic
        while (true) {
            uint256 nextLevel = currentLevel + 1;
            if (nextLevel - 1 < thresholds.length) { // Check if there is a threshold for the next level
                if (skillData.experience >= thresholds[nextLevel - 1]) {
                    skillData.level = nextLevel;
                    emit SkillLevelUp(user, skillId, skillData.level);
                    currentLevel = nextLevel;
                    // Reward logic upon level up
                    _handleLevelUpReward(user, skillId, currentLevel);
                } else {
                    break; // No level up
                }
            } else {
                break; // No more levels defined
            }
        }
    }

    // --- 3. Reputation System ---

    /**
     * @dev Calculates a user's reputation score based on their skill levels.
     *      Simple reputation calculation: Sum of all skill levels.
     *      Can be customized to weigh skills differently in the future.
     * @param user The address of the user.
     * @return The calculated reputation score.
     */
    function calculateReputation(address user) public view returns (uint256) {
        uint256 reputationScore = 0;
        for (uint256 i = 1; i <= skillTypeCount; i++) {
            reputationScore += userSkills[user][i].level;
        }
        emit ReputationCalculated(user, reputationScore); // Emit event whenever calculated, could optimize if needed
        return reputationScore;
    }

    /**
     * @dev Returns the calculated reputation score of a user.
     * @param user The address of the user.
     * @return The reputation score.
     */
    function getReputation(address user) external view returns (uint256) {
        return calculateReputation(user);
    }

    /**
     * @dev Returns a list of addresses with the highest reputation scores, up to a specified count.
     *      This is a simplified approach for demonstration. For large numbers of users,
     *      more efficient ranking algorithms might be needed (off-chain or using more advanced data structures).
     * @param count The number of top users to retrieve.
     * @return An array of addresses with the highest reputation.
     */
    function getTopReputationUsers(uint256 count) external view returns (address[] memory) {
        require(count > 0, "Count must be positive");
        uint256 userCount = 0;
        address[] memory allUsers = new address[](1000); // Assume max 1000 users for simplicity, can be adjusted or made dynamic
        // In a real application, you'd need a way to track all users who have acquired skills
        // For this example, we'll just iterate through all possible addresses (inefficient, but illustrative)

        // **Warning: Inefficient for a large number of users in a real-world scenario.
        //  This is for demonstration. Consider off-chain indexing or more efficient data structures for large scale.**
        uint256 checkedUsers = 0;
        for (uint256 i = 0; i < 10000; i++) { // Check a range of addresses - very simplified, not realistic user tracking
            address potentialUser = address(uint160(i)); // Generate some potential addresses for demonstration
            bool hasSkill = false;
            for (uint256 j = 1; j <= skillTypeCount; j++) {
                if (userSkills[potentialUser][j].level > 0) {
                    hasSkill = true;
                    break;
                }
            }
            if (hasSkill) {
                allUsers[userCount] = potentialUser;
                userCount++;
            }
            checkedUsers++;
            if (userCount >= 1000) break; // Limit to 1000 users for example
        }

        // Now we have a list of users who have acquired skills (in 'allUsers' up to 'userCount')
        // Sort them by reputation (descending) - basic bubble sort for simplicity (inefficient for large scale)
        for (uint256 i = 0; i < userCount - 1; i++) {
            for (uint256 j = 0; j < userCount - i - 1; j++) {
                if (calculateReputation(allUsers[j]) < calculateReputation(allUsers[j + 1])) {
                    address temp = allUsers[j];
                    allUsers[j] = allUsers[j + 1];
                    allUsers[j + 1] = temp;
                }
            }
        }

        // Return top 'count' users
        uint256 resultCount = count > userCount ? userCount : count;
        address[] memory topUsers = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            topUsers[i] = allUsers[i];
        }
        return topUsers;
    }


    // --- 4. Token Integration (Optional Gamification) ---

    /**
     * @dev Sets the address of an ERC20 token to be used for rewards. Only admin can call this.
     * @param tokenAddress The address of the ERC20 token contract.
     */
    function setRewardToken(address tokenAddress) external onlyAdmin whenNotPaused {
        require(tokenAddress != address(0), "Token address cannot be zero");
        rewardToken = IERC20(tokenAddress);
        emit RewardTokenSet(tokenAddress);
    }

    /**
     * @dev Sets the reward amount of tokens for reaching a new level in a specific skill. Only admin can call this.
     * @param skillId The ID of the skill.
     * @param rewardAmount The amount of tokens to reward per level up.
     */
    function setRewardAmountPerLevel(uint256 skillId, uint256 rewardAmount) external onlyAdmin validSkillId skillExists(skillId) whenNotPaused {
        skillTypes[skillId].rewardAmountPerLevel = rewardAmount;
        emit RewardAmountPerLevelSet(skillId, rewardAmount);
    }

    /**
     * @dev Allows a user to claim token rewards upon leveling up a skill.
     *      Rewards are only claimable once per level.
     * @param skillId The ID of the skill for which to claim the reward.
     */
    function claimLevelUpReward(uint256 skillId) external whenNotPaused validSkillId skillExists(skillId) skillAcquired(msg.sender, skillId) {
        require(address(rewardToken) != address(0), "Reward token not set");
        uint256 rewardAmount = skillTypes[skillId].rewardAmountPerLevel;
        require(rewardAmount > 0, "No reward set for this skill level up");

        UserSkillData storage skillData = userSkills[msg.sender][skillId];
        require(skillData.level > skillData.lastLevelUpLevel, "Reward already claimed for current level or no level up");

        uint256 currentLevel = skillData.level;
        skillData.lastLevelUpLevel = currentLevel; // Update last level up level to prevent re-claiming in same level

        // Transfer tokens to user (contract needs to hold tokens for rewards)
        require(rewardToken.transfer(msg.sender, rewardAmount), "Token transfer failed");
        userTokenBalances[msg.sender] += rewardAmount; // Track internal balance for rewards (optional, can remove if not needed)
        emit LevelUpRewardClaimed(msg.sender, skillId, rewardAmount);
    }

    /**
     * @dev Returns the token balance held by the contract for a user (for rewards - internal tracking).
     * @param user The address of the user.
     * @return The user's token balance within the contract.
     */
    function getUserTokenBalance(address user) external view returns (uint256) {
        return userTokenBalances[user];
    }


    // --- 5. Admin and Utility Functions ---

    /**
     * @dev Sets a new admin for the contract. Only current admin can call this.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "New admin address cannot be zero");
        address oldAdmin = _owner();
        _transferOwnership(newAdmin); // From Ownable
        emit AdminChanged(oldAdmin, newAdmin);
    }

    /**
     * @dev Checks if an address is the contract administrator.
     * @param account The address to check.
     * @return True if the address is admin, false otherwise.
     */
    function isAdmin(address account) public view returns (bool) {
        return account == _owner(); // From Ownable
    }

    /**
     * @dev Pauses the contract, preventing certain actions (defined by whenNotPaused modifier).
     * Only admin can call this.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        _pause(); // From Pausable
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring full functionality. Only admin can call this.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        _unpause(); // From Pausable
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return paused(); // From Pausable
    }

    /**
     * @dev Allows the admin to withdraw any Ether accidentally sent to the contract.
     * @param recipient The address to receive the withdrawn Ether.
     */
    function withdrawAdminFunds(address payable recipient) external onlyAdmin whenNotPaused {
        require(recipient != address(0), "Recipient address cannot be zero");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No Ether to withdraw");
        (bool success, ) = recipient.call{value: contractBalance}("");
        require(success, "Withdrawal failed");
        emit AdminFundsWithdrawn(msg.sender, recipient, contractBalance);
    }

    // Fallback function to prevent accidental Ether sending
    receive() external payable {
        // Revert if Ether is sent directly to the contract address without a function call
        revert("Direct Ether sending not allowed. Use contract functions.");
    }
}
```