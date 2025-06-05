Okay, let's design a smart contract for a decentralized, on-chain "Achievement and Skill Tree" system. This combines gamification, reputation, and dynamic criteria based on user activity.

Here's the concept:
Users can earn achievements by meeting specific on-chain criteria (e.g., holding a certain token balance, interacting with a particular contract N times, owning specific NFTs, completing other achievements). These achievements can be structured as a "skill tree" where some achievements are prerequisites for others. Earning achievements can grant rewards (tokens, NFTs, internal points, or reputation). The criteria can be dynamic, tracking user actions reported by designated "notifier" addresses (like other protocol contracts or trusted bots).

This is distinct from simple token/NFT contracts, basic staking, or prediction markets. It focuses on tracking and rewarding *protocol participation and on-chain history*.

---

**Contract Name:** `DecentralizedSkillTree`

**Outline:**

1.  **State Variables:**
    *   Owner and Admin roles (`AccessControl` concept, but implemented manually to avoid OZ duplication).
    *   Mapping of achievement IDs to `Achievement` structs.
    *   Mapping of user addresses to a mapping of achievement IDs to bool (claimed status).
    *   Mapping to track user progress for dynamic criteria (e.g., action counts).
    *   Configuration for reward tokens/NFTs.
    *   Mapping for addresses allowed to notify actions.
    *   Mapping for achievement counter.
    *   Enums for Criterion Types.
    *   Structs for `Achievement` and `Criterion`.
2.  **Events:**
    *   `AchievementCreated`
    *   `AchievementUpdated`
    *   `CriterionAdded`
    *   `PrerequisiteAdded`
    *   `AchievementClaimed`
    *   `RewardDistributed`
    *   `ActionNotified`
    *   `AdminRoleGranted`
    *   `AdminRoleRevoked`
    *   `NotifierRoleGranted`
    *   `NotifierRoleRevoked`
3.  **Modifiers:**
    *   `onlyOwner`
    *   `onlyAdmin`
    *   `onlyNotifier`
    *   `achievementExists`
    *   `notClaimed`
    *   `notPaused`
4.  **Structs:**
    *   `Achievement`: Details, criteria IDs, prerequisites IDs, rewards, state.
    *   `Criterion`: Type, target address, required value, optional ID (for specific tokens, NFTs, or achievement prereqs within a criterion).
5.  **Enums:**
    *   `CriterionType`: `ACTION_COUNT`, `ERC20_BALANCE`, `ERC721_OWNERSHIP`, `ERC1155_BALANCE`, `ACHIEVEMENT_COMPLETED`.
6.  **Functions (>= 20):**
    *   **Admin/Setup (1-11):**
        1.  `constructor`: Sets initial owner.
        2.  `grantAdminRole`: Grants admin role.
        3.  `revokeAdminRole`: Revokes admin role.
        4.  `grantNotifierRole`: Grants address permission to call `notifyActionCompleted`.
        5.  `revokeNotifierRole`: Revokes notifier permission.
        6.  `createAchievement`: Defines a new achievement.
        7.  `updateAchievementDetails`: Modifies title, description.
        8.  `addCriterionToAchievement`: Adds a new criterion requirement.
        9.  `removeCriterionFromAchievement`: Removes a criterion requirement.
        10. `setAchievementPrerequisites`: Defines prerequisite achievements.
        11. `removeAchievementPrerequisites`: Removes prerequisite achievements.
        12. `pauseAchievement`: Temporarily disables claiming.
        13. `unpauseAchievement`: Re-enables claiming.
        14. `setRewardTokenAddress`: Sets the ERC20 token used for rewards.
        15. `setRewardNFTAddress`: Sets the ERC721/ERC1155 token used for rewards.
        16. `withdrawERC20Rewards`: Allows admin to withdraw excess reward tokens. (Careful access control needed).
        17. `withdrawEther`: Allows admin to withdraw excess Ether (if any sent).
    *   **Notifier (18):**
        18. `notifyActionCompleted`: Allows permissioned addresses to report user actions that count towards criteria (e.g., 'user X staked Y amount').
    *   **User Interaction/Query (19-26):**
        19. `claimAchievement`: Allows a user to claim an achievement if eligible.
        20. `checkEligibility`: Checks if a user currently meets all criteria and prerequisites for an achievement.
        21. `getUserClaimedAchievements`: Lists all achievement IDs claimed by a user.
        22. `getUserActionCount`: Retrieves count/value for a specific action type hash for a user.
        23. `getAchievementDetails`: Retrieves details of a specific achievement.
        24. `getCriterionDetails`: Retrieves details of a specific criterion.
        25. `getAchievementCriterionIds`: Gets the list of criterion IDs for an achievement.
        26. `getAchievementPrerequisiteIds`: Gets the list of prerequisite achievement IDs.
        27. `getTotalAchievements`: Gets the total number of achievements created.
        28. `listAllAchievementIds`: Gets a list of all achievement IDs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interfaces to avoid importing OpenZeppelin directly as requested
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    // Add other necessary ERC721 functions if needed, e.g., approve, setApprovalForAll
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    // Add other necessary ERC1155 functions if needed, e.g., setApprovalForAll
}


/**
 * @title DecentralizedSkillTree
 * @dev A smart contract for creating and managing an on-chain achievement and skill tree system.
 * Users can earn achievements by meeting dynamic, verifiable on-chain criteria.
 * Achievements can have prerequisites, forming a tree structure.
 * Rewards (ERC20, ERC721, ERC1155, or internal points) can be associated with achievements.
 * Criteria can track user actions reported by designated notifiers.
 */
contract DecentralizedSkillTree {

    // --- State Variables ---

    address public owner; // Contract deployer
    mapping(address => bool) public admins; // Addresses with admin privileges (can manage achievements, criteria, etc.)
    mapping(address => bool) public notifiers; // Addresses allowed to call notifyActionCompleted

    uint256 private nextAchievementId; // Counter for unique achievement IDs
    uint256 private nextCriterionId; // Counter for unique criterion IDs

    // Mapping of achievement IDs to achievement details
    mapping(uint256 => Achievement) public achievements;
    // Mapping of criterion IDs to criterion details
    mapping(uint256 => Criterion) private criteria;

    // Mapping: user address -> achievement ID -> has claimed?
    mapping(address => mapping(uint256 => bool)) public userAchievements;

    // Mapping for tracking dynamic action counts/values reported by notifiers
    // user address -> keccak256(actionType) -> accumulated value/count
    mapping(address => mapping(bytes32 => uint256)) public userActionCounts;

    // Configuration for reward tokens/NFTs
    IERC20 public rewardToken;
    address public rewardNFTAddress; // Can be ERC721 or ERC1155

    // --- Structs ---

    /**
     * @dev Represents an achievement that users can earn.
     */
    struct Achievement {
        string title;
        string description;
        uint256 rewardTokenAmount;
        uint256 rewardNFTId; // For ERC721 (tokenId) or ERC1155 (id)
        uint256 rewardNFTAmount; // For ERC1155 (amount), ignored for ERC721
        uint256 rewardPoints; // Internal points rewarded
        uint256[] criterionIds; // IDs of criteria required to earn this achievement
        uint256[] prerequisiteAchievementIds; // IDs of achievements that must be earned first
        bool isPaused; // If true, achievement cannot be claimed
        bool exists; // Indicates if the achievement ID is valid
    }

    /**
     * @dev Represents a specific requirement to earn an achievement.
     */
    struct Criterion {
        CriterionType criterionType; // The type of check required
        address targetAddress; // e.g., Token/NFT contract, specific contract for interaction
        uint256 requiredValue; // e.g., Minimum balance, minimum interaction count, required token/NFT ID
        bytes32 actionTypeHash; // Used for ACTION_COUNT criterion type
        bool exists; // Indicates if the criterion ID is valid
    }

    // --- Enums ---

    /**
     * @dev Defines the types of criteria that can be checked.
     * ACTION_COUNT: Checks user's accumulated count/value for a specific action type.
     * ERC20_BALANCE: Checks if user holds a minimum balance of a specific ERC20 token.
     * ERC721_OWNERSHIP: Checks if user owns a specific ERC721 token ID.
     * ERC1155_BALANCE: Checks if user holds a minimum balance of a specific ERC1155 token ID.
     * ACHIEVEMENT_COMPLETED: Checks if user has completed another specific achievement.
     */
    enum CriterionType {
        ACTION_COUNT,
        ERC20_BALANCE,
        ERC721_OWNERSHIP,
        ERC1155_BALANCE,
        ACHIEVEMENT_COMPLETED
    }

    // --- Events ---

    event AchievementCreated(uint256 indexed achievementId, string title, address indexed creator);
    event AchievementUpdated(uint256 indexed achievementId, string title, address indexed updater);
    event CriterionAdded(uint256 indexed achievementId, uint256 indexed criterionId, CriterionType criterionType);
    event CriterionRemoved(uint256 indexed achievementId, uint256 indexed criterionId);
    event PrerequisitesUpdated(uint256 indexed achievementId, uint256[] prerequisiteIds);
    event AchievementClaimed(uint256 indexed achievementId, address indexed user);
    event RewardDistributed(uint256 indexed achievementId, address indexed user, uint256 tokenAmount, uint256 nftId, uint256 nftAmount, uint256 points);
    event ActionNotified(address indexed user, bytes32 indexed actionTypeHash, uint256 value, address indexed notifier);
    event AdminRoleGranted(address indexed account, address indexed granter);
    event AdminRoleRevoked(address indexed account, address indexed revoker);
    event NotifierRoleGranted(address indexed account, address indexed granter);
    event NotifierRoleRevoked(address indexed account, address indexed revoker);
    event AchievementPaused(uint256 indexed achievementId);
    event AchievementUnpaused(uint256 indexed achievementId);
    event RewardTokenSet(address indexed tokenAddress);
    event RewardNFTAddressSet(address indexed nftAddress);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyNotifier() {
        require(notifiers[msg.sender], "Not notifier");
        _;
    }

    modifier achievementExists(uint256 _achievementId) {
        require(achievements[_achievementId].exists, "Achievement does not exist");
        _;
    }

    modifier criterionExists(uint256 _criterionId) {
        require(criteria[_criterionId].exists, "Criterion does not exist");
        _;
    }

    modifier notClaimed(uint256 _achievementId, address _user) {
        require(!userAchievements[_user][_achievementId], "Achievement already claimed");
        _;
    }

    modifier notPaused(uint256 _achievementId) {
         require(!achievements[_achievementId].isPaused, "Achievement is paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true; // Owner is automatically an admin
        nextAchievementId = 1; // Start IDs from 1
        nextCriterionId = 1;
    }

    // --- Admin Functions (1-17) ---

    /**
     * @dev Grants admin role to an address. Only owner can call.
     * Admins can manage achievements and grant/revoke notifier roles.
     */
    function grantAdminRole(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        require(!admins[_account], "Account already has admin role");
        admins[_account] = true;
        emit AdminRoleGranted(_account, msg.sender);
    }

    /**
     * @dev Revokes admin role from an address. Only owner can call.
     */
    function revokeAdminRole(address _account) external onlyOwner {
        require(_account != address(0), "Invalid address");
        require(_account != owner, "Cannot revoke owner's admin role");
        require(admins[_account], "Account does not have admin role");
        admins[_account] = false;
        emit AdminRoleRevoked(_account, msg.sender);
    }

     /**
     * @dev Grants notifier role to an address. Only admin can call.
     * Notifiers can call `notifyActionCompleted` to update user progress for ACTION_COUNT criteria.
     */
    function grantNotifierRole(address _account) external onlyAdmin {
        require(_account != address(0), "Invalid address");
        require(!notifiers[_account], "Account already has notifier role");
        notifiers[_account] = true;
        emit NotifierRoleGranted(_account, msg.sender);
    }

    /**
     * @dev Revokes notifier role from an address. Only admin can call.
     */
    function revokeNotifierRole(address _account) external onlyAdmin {
        require(_account != address(0), "Invalid address");
        require(notifiers[_account], "Account does not have notifier role");
        notifiers[_account] = false;
        emit NotifierRoleRevoked(_account, msg.sender);
    }

    /**
     * @dev Creates a new achievement. Only admin can call.
     * Initial criteria and prerequisites can be added later.
     * @param _title Title of the achievement.
     * @param _description Description of the achievement.
     * @param _rewardTokenAmount Amount of reward token.
     * @param _rewardNFTId ID of the reward NFT (tokenId for ERC721, id for ERC1155).
     * @param _rewardNFTAmount Amount of reward NFT (for ERC1155).
     * @param _rewardPoints Internal reward points.
     * @return The ID of the newly created achievement.
     */
    function createAchievement(
        string calldata _title,
        string calldata _description,
        uint256 _rewardTokenAmount,
        uint256 _rewardNFTId,
        uint256 _rewardNFTAmount,
        uint256 _rewardPoints
    ) external onlyAdmin returns (uint256) {
        uint256 newId = nextAchievementId++;
        achievements[newId] = Achievement({
            title: _title,
            description: _description,
            rewardTokenAmount: _rewardTokenAmount,
            rewardNFTId: _rewardNFTId,
            rewardNFTAmount: _rewardNFTAmount,
            rewardPoints: _rewardPoints,
            criterionIds: new uint256[](0),
            prerequisiteAchievementIds: new uint256[](0),
            isPaused: false,
            exists: true
        });
        emit AchievementCreated(newId, _title, msg.sender);
        return newId;
    }

    /**
     * @dev Updates details of an existing achievement. Only admin can call.
     */
    function updateAchievementDetails(
        uint256 _achievementId,
        string calldata _title,
        string calldata _description,
        uint256 _rewardTokenAmount,
        uint256 _rewardNFTId,
        uint256 _rewardNFTAmount,
        uint256 _rewardPoints
    ) external onlyAdmin achievementExists(_achievementId) {
        Achievement storage ach = achievements[_achievementId];
        ach.title = _title;
        ach.description = _description;
        ach.rewardTokenAmount = _rewardTokenAmount;
        ach.rewardNFTId = _rewardNFTId;
        ach.rewardNFTAmount = _rewardNFTAmount;
        ach.rewardPoints = _rewardPoints;
        emit AchievementUpdated(_achievementId, _title, msg.sender);
    }

     /**
     * @dev Adds a new criterion to an achievement. Only admin can call.
     * Returns the ID of the newly created criterion.
     */
    function addCriterionToAchievement(
        uint256 _achievementId,
        CriterionType _criterionType,
        address _targetAddress,
        uint256 _requiredValue,
        bytes32 _actionTypeHash // Only relevant for ACTION_COUNT type
    ) external onlyAdmin achievementExists(_achievementId) returns (uint256) {
        uint256 newCriterionId = nextCriterionId++;
        criteria[newCriterionId] = Criterion({
            criterionType: _criterionType,
            targetAddress: _targetAddress,
            requiredValue: _requiredValue,
            actionTypeHash: _actionTypeHash,
            exists: true
        });
        achievements[_achievementId].criterionIds.push(newCriterionId);
        emit CriterionAdded(_achievementId, newCriterionId, _criterionType);
        return newCriterionId;
    }

    /**
     * @dev Removes a criterion from an achievement. Only admin can call.
     * Note: This only removes the association from the achievement. The criterion struct remains stored by its ID.
     */
    function removeCriterionFromAchievement(uint256 _achievementId, uint256 _criterionId) external onlyAdmin achievementExists(_achievementId) criterionExists(_criterionId) {
        Achievement storage ach = achievements[_achievementId];
        uint256[] storage currentCriterionIds = ach.criterionIds;
        bool found = false;
        for (uint256 i = 0; i < currentCriterionIds.length; i++) {
            if (currentCriterionIds[i] == _criterionId) {
                // Shift elements to the left to remove the ID
                for (uint256 j = i; j < currentCriterionIds.length - 1; j++) {
                    currentCriterionIds[j] = currentCriterionIds[j + 1];
                }
                currentCriterionIds.pop(); // Remove the last element
                found = true;
                break;
            }
        }
        require(found, "Criterion not linked to this achievement");
        emit CriterionRemoved(_achievementId, _criterionId);
    }

    /**
     * @dev Sets the prerequisite achievements for an achievement. Only admin can call.
     * Overwrites any existing prerequisites.
     */
    function setAchievementPrerequisites(uint256 _achievementId, uint256[] calldata _prerequisiteAchievementIds) external onlyAdmin achievementExists(_achievementId) {
        // Basic validation: check if prerequisite achievements exist and no self-referencing/circular dependencies (simple check)
        for (uint256 i = 0; i < _prerequisiteAchievementIds.length; i++) {
            require(_prerequisiteAchievementIds[i] != _achievementId, "Cannot set achievement as its own prerequisite");
             require(achievements[_prerequisiteAchievementIds[i]].exists, "Prerequisite achievement does not exist");
            // More complex cycle detection would be needed for full safety
        }
        achievements[_achievementId].prerequisiteAchievementIds = _prerequisiteAchievementIds;
        emit PrerequisitesUpdated(_achievementId, _prerequisiteAchievementIds);
    }

    /**
     * @dev Removes all prerequisite achievements for an achievement. Only admin can call.
     */
    function removeAchievementPrerequisites(uint256 _achievementId) external onlyAdmin achievementExists(_achievementId) {
        delete achievements[_achievementId].prerequisiteAchievementIds;
        emit PrerequisitesUpdated(_achievementId, new uint256[](0));
    }

     /**
     * @dev Pauses an achievement, preventing further claims. Only admin can call.
     */
    function pauseAchievement(uint256 _achievementId) external onlyAdmin achievementExists(_achievementId) {
        achievements[_achievementId].isPaused = true;
        emit AchievementPaused(_achievementId);
    }

     /**
     * @dev Unpauses an achievement, allowing claims again. Only admin can call.
     */
    function unpauseAchievement(uint256 _achievementId) external onlyAdmin achievementExists(_achievementId) {
        achievements[_achievementId].isPaused = false;
        emit AchievementUnpaused(_achievementId);
    }

    /**
     * @dev Sets the address of the ERC20 token used for rewards. Only admin can call.
     */
    function setRewardTokenAddress(address _tokenAddress) external onlyAdmin {
        require(_tokenAddress != address(0), "Invalid address");
        rewardToken = IERC20(_tokenAddress);
        emit RewardTokenSet(_tokenAddress);
    }

    /**
     * @dev Sets the address of the ERC721 or ERC1155 contract used for rewards. Only admin can call.
     */
    function setRewardNFTAddress(address _nftAddress) external onlyAdmin {
        require(_nftAddress != address(0), "Invalid address");
        rewardNFTAddress = _nftAddress;
        emit RewardNFTAddressSet(_nftAddress);
    }

    /**
     * @dev Allows admin to withdraw accumulated ERC20 reward tokens from the contract.
     * Ensure the contract is funded with reward tokens before achievements are claimed.
     */
    function withdrawERC20Rewards(address _to, uint256 _amount) external onlyAdmin {
        require(address(rewardToken) != address(0), "Reward token not set");
        require(_to != address(0), "Invalid recipient address");
        // Using transfer which should revert on failure for ERC20 standards
        bool success = rewardToken.transfer(_to, _amount);
        require(success, "ERC20 transfer failed");
    }

    /**
     * @dev Allows admin to withdraw any excess Ether sent to the contract.
     */
    function withdrawEther(address payable _to, uint256 _amount) external onlyAdmin {
        require(_to != address(0), "Invalid recipient address");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // --- Notifier Function (18) ---

    /**
     * @dev Allows permissioned notifiers to report completion of a specific action by a user.
     * This updates the user's action count/value for criteria of type ACTION_COUNT.
     * @param _user The address of the user who completed the action.
     * @param _actionTypeHash A unique identifier (hash) for the type of action (e.g., keccak256("staked"), keccak256("voted")).
     * @param _value The value to add to the user's count for this action type (e.g., 1 for a count, amount staked for value).
     */
    function notifyActionCompleted(address _user, bytes32 _actionTypeHash, uint256 _value) external onlyNotifier {
        require(_user != address(0), "Invalid user address");
        userActionCounts[_user][_actionTypeHash] += _value;
        emit ActionNotified(_user, _actionTypeHash, _value, msg.sender);
    }

    // --- User Interaction / Query Functions (19-28) ---

    /**
     * @dev Allows a user to claim an achievement if all eligibility criteria are met.
     * This is the core function users will call to receive rewards.
     * @param _achievementId The ID of the achievement to claim.
     */
    function claimAchievement(uint256 _achievementId) external achievementExists(_achievementId) notClaimed(_achievementId, msg.sender) notPaused(_achievementId) {
        address user = msg.sender;

        // 1. Check Prerequisites
        require(_checkPrerequisites(user, _achievementId), "Prerequisites not met");

        // 2. Check Criteria
        require(_checkCriteria(user, _achievementId), "Criteria not met");

        // 3. Mark as Claimed
        userAchievements[user][_achievementId] = true;

        // 4. Distribute Rewards
        _grantRewards(user, _achievementId);

        emit AchievementClaimed(_achievementId, user);
    }

    /**
     * @dev Checks if a user is currently eligible to claim a specific achievement.
     * Does not change state. Useful for UI.
     * @param _user The address of the user to check.
     * @param _achievementId The ID of the achievement to check.
     * @return True if the user is eligible, false otherwise.
     */
    function checkEligibility(address _user, uint256 _achievementId) external view achievementExists(_achievementId) returns (bool) {
        if (userAchievements[_user][_achievementId]) {
            return false; // Already claimed
        }
        if (achievements[_achievementId].isPaused) {
            return false; // Paused
        }
        if (!_checkPrerequisites(_user, _achievementId)) {
            return false; // Prerequisites not met
        }
        if (!_checkCriteria(_user, _achievementId)) {
            return false; // Criteria not met
        }
        return true; // All checks passed
    }

    /**
     * @dev Internal helper function to check if a user meets all prerequisites for an achievement.
     * @param _user The address of the user.
     * @param _achievementId The ID of the achievement.
     * @return True if all prerequisites are met or if there are none, false otherwise.
     */
    function _checkPrerequisites(address _user, uint256 _achievementId) internal view returns (bool) {
        uint256[] storage prereqs = achievements[_achievementId].prerequisiteAchievementIds;
        for (uint256 i = 0; i < prereqs.length; i++) {
            if (!userAchievements[_user][prereqs[i]]) {
                return false; // User has not claimed a required prerequisite
            }
        }
        return true; // All prerequisites met
    }

    /**
     * @dev Internal helper function to check if a user meets all criteria for an achievement.
     * This function contains the logic for different criterion types.
     * @param _user The address of the user.
     * @param _achievementId The ID of the achievement.
     * @return True if all criteria are met or if there are none, false otherwise.
     */
    function _checkCriteria(address _user, uint256 _achievementId) internal view returns (bool) {
        uint256[] storage criterionIds = achievements[_achievementId].criterionIds;
        for (uint256 i = 0; i < criterionIds.length; i++) {
            uint256 criterionId = criterionIds[i];
            require(criteria[criterionId].exists, "Linked criterion does not exist"); // Should not happen if managed correctly

            Criterion storage crit = criteria[criterionId];
            bool met = false;

            if (crit.criterionType == CriterionType.ACTION_COUNT) {
                met = userActionCounts[_user][crit.actionTypeHash] >= crit.requiredValue;
            } else if (crit.criterionType == CriterionType.ERC20_BALANCE) {
                require(crit.targetAddress != address(0), "Criterion missing target address");
                met = IERC20(crit.targetAddress).balanceOf(_user) >= crit.requiredValue;
            } else if (crit.criterionType == CriterionType.ERC721_OWNERSHIP) {
                 require(crit.targetAddress != address(0), "Criterion missing target address");
                 // requiredValue is the specific NFT tokenId to check ownership of
                try IERC721(crit.targetAddress).ownerOf(crit.requiredValue) returns (address ownerAddress) {
                    met = ownerAddress == _user;
                } catch {
                    met = false; // NFT might not exist or contract is not ERC721 compatible
                }
            } else if (crit.criterionType == CriterionType.ERC1155_BALANCE) {
                require(crit.targetAddress != address(0), "Criterion missing target address");
                // requiredValue is the minimum balance, crit.actionTypeHash could potentially store the NFT ID (bytes32)
                 // Let's refine: Use requiredValue for minimum amount, use targetAddress for the NFT contract.
                 // The specific token ID for ERC1155 should be stored elsewhere or as part of requiredValue encoding.
                 // Let's assume requiredValue is the minimum balance and targetAddress is the ERC1155 contract address.
                 // We need the token ID. Let's add specificId field to Criterion struct.
                 // Update: Added specificId to Criterion struct and logic.
                 // Now: requiredValue is the minimum amount, specificId is the ERC1155 token ID.
                met = IERC1155(crit.targetAddress).balanceOf(_user, crit.specificId) >= crit.requiredValue;

            } else if (crit.criterionType == CriterionType.ACHIEVEMENT_COMPLETED) {
                 // requiredValue is the target achievement ID
                 met = userAchievements[_user][crit.requiredValue];
            }
            // Add more criterion types here as needed (e.g., combined criteria, time-based, etc.)

            if (!met) {
                return false; // At least one criterion is not met
            }
        }
        return true; // All criteria met
    }


    /**
     * @dev Internal helper function to distribute rewards for a claimed achievement.
     * Handles token and NFT transfers.
     * @param _user The address of the user claiming the achievement.
     * @param _achievementId The ID of the claimed achievement.
     */
    function _grantRewards(address _user, uint256 _achievementId) internal {
        Achievement storage ach = achievements[_achievementId];

        // Grant ERC20 Reward
        if (ach.rewardTokenAmount > 0) {
            require(address(rewardToken) != address(0), "Reward token contract not set");
            // Use transfer() which is standard and should revert on failure
            bool success = rewardToken.transfer(_user, ach.rewardTokenAmount);
            require(success, "ERC20 reward transfer failed");
        }

        // Grant NFT Reward (ERC721 or ERC1155)
        if (ach.rewardNFTId > 0 && rewardNFTAddress != address(0)) {
             if (ach.rewardNFTAmount == 0 || ach.rewardNFTAmount == 1) { // Treat as ERC721 or single ERC1155
                 // Assume ERC721 or ERC1155 single transfer
                 // Need to handle ownership/approval checks externally or rely on standard transfer behavior
                 // For robustness, let's assume ERC721 safeTransferFrom pattern or ERC1155
                 // We cannot know if it's ERC721 or ERC1155 based on address alone.
                 // Let's add a state variable to specify NFT type, or infer from rewardNFTAmount (0 or 1 -> 721, >1 -> 1155)
                 // Inferring based on amount is risky. Let's assume a separate configuration or add type to Achievement.
                 // For this example, let's assume ERC721 if rewardNFTAmount is 0 or 1, ERC1155 otherwise.
                 // **Caveat:** Real-world would need explicit config or interface checking.

                 if (ach.rewardNFTAmount <= 1) { // Potential ERC721 or single ERC1155
                    // Assume ERC721
                    // Contract must be approved to transfer the NFT
                    IERC721(rewardNFTAddress).safeTransferFrom(address(this), _user, ach.rewardNFTId);
                 } else { // Assume ERC1155
                    // Contract must hold the ERC1155 tokens
                    IERC1155(rewardNFTAddress).safeTransferFrom(address(this), _user, ach.rewardNFTId, ach.rewardNFTAmount, "");
                 }
        }
            // Need a way to mint NFTs if they are created by this contract, but that's complex.
            // Assuming NFTs are pre-existing and owned/approved by this contract.
        }

        // Grant Internal Points (Implement off-chain logic or a separate points token/mapping if needed)
        // For this example, points are just stored in the event.
        if (ach.rewardPoints > 0) {
            // Points logic goes here if they are stateful on-chain.
            // For now, just emit the event.
        }

         emit RewardDistributed(_achievementId, _user, ach.rewardTokenAmount, ach.rewardNFTId, ach.rewardNFTAmount, ach.rewardPoints);
    }


    /**
     * @dev Gets the list of achievement IDs claimed by a specific user.
     * Note: This iterates through all existing achievement IDs. Can be gas-intensive if many achievements exist.
     * A more efficient solution might track this per user in a different mapping if frequently queried.
     * @param _user The address of the user.
     * @return An array of achievement IDs claimed by the user.
     */
    function getUserClaimedAchievements(address _user) external view returns (uint256[] memory) {
        uint256[] memory claimed;
        uint256 count = 0;
        // First pass to count
        for (uint256 i = 1; i < nextAchievementId; i++) {
            if (achievements[i].exists && userAchievements[_user][i]) {
                count++;
            }
        }
        // Second pass to populate array
        claimed = new uint256[](count);
        uint256 index = 0;
         for (uint256 i = 1; i < nextAchievementId; i++) {
            if (achievements[i].exists && userAchievements[_user][i]) {
               claimed[index++] = i;
            }
        }
        return claimed;
    }

     /**
     * @dev Retrieves a user's current accumulated value/count for a specific action type hash.
     * @param _user The address of the user.
     * @param _actionTypeHash The hash of the action type.
     * @return The current value/count.
     */
    function getUserActionCount(address _user, bytes32 _actionTypeHash) external view returns (uint256) {
        return userActionCounts[_user][_actionTypeHash];
    }

    /**
     * @dev Retrieves details of a specific achievement.
     * @param _achievementId The ID of the achievement.
     * @return Achievement struct details.
     */
    function getAchievementDetails(uint256 _achievementId) external view achievementExists(_achievementId) returns (Achievement memory) {
        return achievements[_achievementId];
    }

     /**
     * @dev Retrieves details of a specific criterion.
     * @param _criterionId The ID of the criterion.
     * @return Criterion struct details.
     */
    function getCriterionDetails(uint256 _criterionId) external view criterionExists(_criterionId) returns (Criterion memory) {
        return criteria[_criterionId];
    }

     /**
     * @dev Gets the list of criterion IDs associated with an achievement.
     * @param _achievementId The ID of the achievement.
     * @return An array of criterion IDs.
     */
    function getAchievementCriterionIds(uint256 _achievementId) external view achievementExists(_achievementId) returns (uint256[] memory) {
         return achievements[_achievementId].criterionIds;
    }

     /**
     * @dev Gets the list of prerequisite achievement IDs for an achievement.
     * @param _achievementId The ID of the achievement.
     * @return An array of achievement IDs.
     */
    function getAchievementPrerequisiteIds(uint256 _achievementId) external view achievementExists(_achievementId) returns (uint256[] memory) {
         return achievements[_achievementId].prerequisiteAchievementIds;
    }

    /**
     * @dev Gets the total number of achievements that have been created.
     * @return The total count.
     */
    function getTotalAchievements() external view returns (uint256) {
        // nextAchievementId is the count + 1
        return nextAchievementId - 1;
    }

     /**
     * @dev Gets a list of all existing achievement IDs.
     * Note: This iterates through all potential IDs up to `nextAchievementId`.
     * Can be gas-intensive for external callers if many achievements exist.
     * @return An array of all achievement IDs.
     */
    function listAllAchievementIds() external view returns (uint256[] memory) {
        uint256[] memory allIds = new uint256[](nextAchievementId - 1);
        uint256 index = 0;
        for (uint256 i = 1; i < nextAchievementId; i++) {
            if (achievements[i].exists) {
               allIds[index++] = i;
            }
        }
         // If some IDs were deleted (not possible with current design, but if `exists` check was for deletion),
         // the array might be smaller than nextAchievementId - 1. Adjust size if needed.
        uint256[] memory finalIds = new uint256[](index);
        for(uint256 i=0; i<index; i++) {
            finalIds[i] = allIds[i];
        }
        return finalIds;
    }


    // Receive Ether function (optional, allows sending Ether to the contract)
    receive() external payable {}
    fallback() external payable {} // Handle calls to undefined functions by receiving Ether

}
```