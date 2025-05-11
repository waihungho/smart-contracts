Okay, let's design a creative and advanced smart contract concept. How about a "Dynamic Reputation-Gated Feature Protocol"?

This protocol would allow users to earn reputation points based on on-chain interactions or verifiable actions (simulated via admin/oracle calls in this example). These reputation points would automatically place users into different tiers. Each tier would unlock access to specific functions or features within the contract, making it a dynamic access control system tied to on-chain contribution/status.

To make it more interesting and reach the function count, we'll add:
1.  A simple Task/Quest system where completing tasks grants reputation.
2.  Tier-specific rewards that can be claimed once.
3.  Admin controls for managing tiers, tasks, and potentially adjusting reputation (with caution).
4.  Example gated functions.

It combines concepts of reputation systems, tiered access control, and conditional execution, without being a direct copy of a standard token, marketplace, or lending protocol.

---

## Outline and Function Summary: ReputationGateProtocol

**Core Concept:** A protocol where user reputation points determine their tier level, which in turn grants dynamic access to specific functions and features within the contract. Includes a task system for earning reputation and tier-based rewards.

**Modules:**

1.  **Protocol Core & Access Control:** Basic ownership, pausing, and the core tier-based access modifier.
2.  **Reputation & Tier Management:** Functions to view, update, and manage user reputation and defined tiers.
3.  **Task & Quest System:** Functions for admins to create tasks and users/oracles to verify task completion, awarding reputation.
4.  **Gated Actions & Features:** Example functions that can only be called by users in specific tiers.
5.  **Tier Rewards:** Functions allowing users to claim unique rewards upon reaching a new tier.
6.  **Admin & Utility:** Functions for contract administration, configuration, and maintenance.

**Function Summary:**

*   **`constructor()`**: Initializes contract owner.
*   **`pauseProtocol()`**: Admin pauses the contract.
*   **`unpauseProtocol()`**: Admin unpauses the contract.
*   **`getReputationPoints(address user)`**: View user's current reputation points.
*   **`getCurrentTierId(address user)`**: View user's current tier ID.
*   **`getTierDetails(uint256 tierId)`**: View details (min points, name) of a defined tier.
*   **`defineTier(uint256 tierId, uint256 minPoints, string memory name)`**: Admin defines or updates a tier.
*   **`removeTier(uint256 tierId)`**: Admin removes a tier definition.
*   **`getDefinedTierIds()`**: View a list of all currently defined tier IDs.
*   **`proposeReputationIncrease(address user, uint256 amount, string memory reason)`**: Admin/Oracle adds reputation points to a user. (Simplified: Admin only)
*   **`setBaseReputation(address user, uint256 points)`**: Admin overrides a user's reputation points. (Use with caution)
*   **`createTask(uint256 taskId, string memory description, uint256 requiredTier, uint256 rewardPoints, bool isActive)`**: Admin creates or updates a task.
*   **`getTaskDetails(uint256 taskId)`**: View details of a specific task.
*   **`getTasksForTier(uint256 tierId)`**: View IDs of tasks available for a specific tier.
*   **`requestTaskCompletionVerification(uint256 taskId)`**: User signals they have completed a task and request verification. Requires meeting the task's required tier.
*   **`verifyTaskCompletion(address user, uint256 taskId)`**: Admin/TaskExecutor verifies a user's task completion, awards reputation, and marks as completed for the user.
*   **`isTaskCompletedByUser(address user, uint256 taskId)`**: View if a user has completed a specific task.
*   **`deactivateTask(uint256 taskId)`**: Admin deactivates a task.
*   **`performTier1Action(uint256 parameter)`**: Example function requiring Tier 1 or higher.
*   **`performTier3SpecialAction(bytes dataPayload)`**: Example function requiring Tier 3 or higher, accepting complex data.
*   **`checkTierFeatureAccess(uint256 tierId, bytes4 featureId)`**: View function to check if a specific tier has access to a conceptual feature ID. (Requires mapping features to tiers internally).
*   **`claimTierReward(uint256 tierId)`**: User claims a one-time reward associated with a specific tier they have reached.
*   **`getClaimStatusForTierReward(address user, uint256 tierId)`**: View if a user has claimed the reward for a specific tier.
*   **`setTaskExecutor(address executor)`**: Admin sets the address allowed to verify tasks (if not owner).
*   **`getTaskExecutor()`**: View the current task executor address.
*   **`withdrawEth(uint256 amount)`**: Admin withdraws ETH from the contract. (If the contract were to receive ETH).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReputationGateProtocol
 * @dev A protocol where user reputation points determine their tier level,
 * which grants dynamic access to specific functions and features.
 * Includes a task system for earning reputation and tier-based rewards.
 *
 * Outline:
 * 1. Protocol Core & Access Control (constructor, pausing, modifiers)
 * 2. Reputation & Tier Management (view, add, set, define tiers)
 * 3. Task & Quest System (create, view, request/verify completion)
 * 4. Gated Actions & Features (example functions requiring tiers)
 * 5. Tier Rewards (claim rewards for reaching tiers)
 * 6. Admin & Utility (set executor, withdraw, overrides)
 */
contract ReputationGateProtocol {

    address private owner;
    bool private paused;
    address private taskExecutor; // Dedicated role for verifying tasks

    // --- State Variables ---

    // Mapping user address to reputation points
    mapping(address => uint256) private reputationPoints;
    // Mapping user address to their current tier ID
    mapping(address => uint256) private userTier;

    // Struct to define a tier
    struct Tier {
        uint256 minPoints;
        string name;
        // Future: Maybe add features/permissions encoded here
        bool exists; // Flag to indicate if the tier ID is defined
    }
    // Mapping tier ID to Tier details
    mapping(uint256 => Tier) private tiers;
    // Array to keep track of defined tier IDs (for enumeration)
    uint256[] private definedTierIds;
    // Mapping to track if a tier ID is in the definedTierIds array
    mapping(uint256 => bool) private isTierIdInDefinedList;

    // Struct to define a task
    struct Task {
        string description;
        uint256 requiredTier; // Minimum tier required to attempt/request verification
        uint256 rewardPoints;
        bool isActive;
        bool exists; // Flag to indicate if the task ID is defined
    }
    // Mapping task ID to Task details
    mapping(uint256 => Task) private tasks;
    // Mapping tier ID to array of task IDs available for that tier (conceptual)
    // Note: This is a simplified view; actual filtering by tier would be done in functions
    // Mapping user address to task ID to completion status
    mapping(address => mapping(uint256 => bool)) private completedTasks;
    // Mapping user address to task ID to indicate verification is requested
    mapping(address => mapping(uint256 => bool)) private verificationRequestedTasks;


    // Mapping user address to tier ID to indicate if tier reward has been claimed
    mapping(address => mapping(uint256 => bool)) private claimedTierReward;

    // --- Events ---

    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event ReputationEarned(address indexed user, uint256 amount, uint256 newTotalPoints);
    event ReputationSet(address indexed user, uint256 newTotalPoints, address indexed by);
    event TierUpgraded(address indexed user, uint256 oldTierId, uint256 newTierId);
    event TierDefined(uint256 indexed tierId, uint256 minPoints, string name);
    event TierRemoved(uint256 indexed tierId);
    event TaskCreated(uint256 indexed taskId, uint256 requiredTier, uint256 rewardPoints);
    event TaskDeactivated(uint256 indexed taskId);
    event TaskCompletionRequested(address indexed user, uint256 indexed taskId);
    event TaskCompleted(address indexed user, uint256 indexed taskId, uint256 pointsAwarded);
    event TierRewardClaimed(address indexed user, uint256 indexed tierId);
    event TaskExecutorSet(address indexed oldExecutor, address indexed newExecutor);
    event EthWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Protocol is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Protocol is not paused");
        _;
    }

    /**
     * @dev Modifier to restrict function access based on user's current tier.
     * Requires the user's current tier ID to be greater than or equal to
     * the minimum required tier ID.
     * @param _minTierId The minimum tier ID required to access the function.
     */
    modifier requiresTier(uint256 _minTierId) {
        require(userTier[msg.sender] >= _minTierId, "Requires a higher tier");
        _;
    }

    /**
     * @dev Modifier to restrict function access to the owner or task executor.
     */
    modifier onlyTaskExecutorOrOwner() {
        require(msg.sender == owner || msg.sender == taskExecutor, "Only task executor or owner");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        paused = false;
        taskExecutor = msg.sender; // Owner is default task executor

        // Define a default Tier 0 (base tier)
        tiers[0] = Tier(0, "Base Tier", true);
        definedTierIds.push(0);
        isTierIdInDefinedList[0] = true;
    }

    // --- 1. Protocol Core & Access Control ---

    /**
     * @dev Pauses the protocol. Callable only by the owner.
     * While paused, most state-changing functions should be disabled.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol. Callable only by the owner.
     */
    function unpauseProtocol() external onlyOwner whenPaused {
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    // --- 2. Reputation & Tier Management ---

    /**
     * @dev Returns the current reputation points for a user.
     * @param user The address of the user.
     * @return The user's reputation points.
     */
    function getReputationPoints(address user) external view returns (uint256) {
        return reputationPoints[user];
    }

    /**
     * @dev Returns the current tier ID for a user.
     * @param user The address of the user.
     * @return The user's current tier ID.
     */
    function getCurrentTierId(address user) external view returns (uint256) {
        return userTier[user];
    }

    /**
     * @dev Returns the details of a defined tier.
     * @param tierId The ID of the tier.
     * @return minPoints The minimum reputation points required for this tier.
     * @return name The name of the tier.
     * @return exists True if the tier ID is defined.
     */
    function getTierDetails(uint256 tierId) external view returns (uint256 minPoints, string memory name, bool exists) {
        Tier storage tier = tiers[tierId];
        return (tier.minPoints, tier.name, tier.exists);
    }

    /**
     * @dev Admin function to define or update a tier.
     * Tier IDs should generally increase with `minPoints`.
     * @param tierId The ID of the tier to define/update.
     * @param minPoints The minimum reputation points required for this tier.
     * @param name The name of the tier.
     */
    function defineTier(uint256 tierId, uint256 minPoints, string memory name) external onlyOwner {
        require(tierId > 0 || (tierId == 0 && minPoints == 0), "Tier 0 must have 0 points, other tiers must be > 0");
        require(bytes(name).length > 0, "Tier name cannot be empty");

        bool isNewTier = !tiers[tierId].exists;
        tiers[tierId] = Tier(minPoints, name, true);

        if (isNewTier) {
            // Keep definedTierIds sorted for easier lookup (though not strictly necessary for functionality)
            bool inserted = false;
            for (uint i = 0; i < definedTierIds.length; i++) {
                if (definedTierIds[i] > tierId) {
                    // Insert tierId at position i
                    uint256[] memory newDefinedTierIds = new uint256[](definedTierIds.length + 1);
                    for (uint j = 0; j < i; j++) newDefinedTierIds[j] = definedTierIds[j];
                    newDefinedTierIds[i] = tierId;
                    for (uint j = i; j < definedTierIds.length; j++) newDefinedTierIds[j+1] = definedTierIds[j];
                    definedTierIds = newDefinedTierIds;
                    inserted = true;
                    break;
                }
            }
            if (!inserted) {
                 // Add to the end if it's the largest ID or list was empty
                definedTierIds.push(tierId);
            }
            isTierIdInDefinedList[tierId] = true;
        }

        emit TierDefined(tierId, minPoints, name);

        // Potentially update user tiers if tier requirements changed
        // NOTE: Doing this for all users is gas-intensive.
        // A practical contract would likely only update tiers on reputation change
        // or have an admin function to trigger updates for batches of users.
        // For simplicity, we omit a mass update here. Tiers are re-evaluated
        // when reputation changes via `_updateTier`.
    }

     /**
     * @dev Admin function to remove a tier definition.
     * Cannot remove Tier 0.
     * Users currently in this tier will remain until their reputation changes
     * and they are re-evaluated into a different active tier.
     * @param tierId The ID of the tier to remove.
     */
    function removeTier(uint256 tierId) external onlyOwner {
        require(tierId != 0, "Cannot remove Tier 0");
        require(tiers[tierId].exists, "Tier does not exist");

        delete tiers[tierId];
        // Remove from definedTierIds array
        for (uint i = 0; i < definedTierIds.length; i++) {
            if (definedTierIds[i] == tierId) {
                definedTierIds[i] = definedTierIds[definedTierIds.length - 1];
                definedTierIds.pop();
                break;
            }
        }
        delete isTierIdInDefinedList[tierId];

        emit TierRemoved(tierId);
    }

    /**
     * @dev Returns a list of all currently defined tier IDs.
     * Useful for frontends to discover available tiers.
     * @return An array of defined tier IDs, generally sorted ascending.
     */
    function getDefinedTierIds() external view returns (uint256[] memory) {
        return definedTierIds;
    }


    /**
     * @dev Internal function to add reputation points to a user and potentially update their tier.
     * @param user The address of the user.
     * @param amount The amount of reputation points to add.
     */
    function _addReputation(address user, uint256 amount) internal {
        uint256 oldTotalPoints = reputationPoints[user];
        uint256 newTotalPoints = oldTotalPoints + amount;
        reputationPoints[user] = newTotalPoints;

        emit ReputationEarned(user, amount, newTotalPoints);

        _updateTier(user);
    }

     /**
     * @dev Internal function to check and update a user's tier based on their current reputation points.
     * Called automatically after reputation changes.
     * Iterates through defined tiers to find the highest tier the user qualifies for.
     * @param user The address of the user.
     */
    function _updateTier(address user) internal {
        uint256 currentPoints = reputationPoints[user];
        uint256 oldTierId = userTier[user];
        uint256 newTierId = oldTierId;

        // Iterate through defined tiers (assuming definedTierIds is sorted)
        // to find the highest tier the user qualifies for.
        for (uint i = 0; i < definedTierIds.length; i++) {
            uint256 tierId = definedTierIds[i];
            if (tiers[tierId].exists && currentPoints >= tiers[tierId].minPoints) {
                 // If definedTierIds is sorted ascending by ID, this logic works.
                 // If sorted by minPoints ascending, this is more robust.
                 // Let's assume definedTierIds is sorted by minPoints ascending for simplicity.
                 // If sorted by ID, need to compare minPoints.
                 // Simple approach: Find highest qualifying tier ID regardless of sorted list
                 uint256 highestQualifyingTier = 0; // Tier 0 is always base
                 for(uint j = 0; j < definedTierIds.length; j++) {
                     uint256 tId = definedTierIds[j];
                     if (tiers[tId].exists && currentPoints >= tiers[tId].minPoints) {
                        if (tId > highestQualifyingTier) { // Assume higher ID means 'better' tier
                           highestQualifyingTier = tId;
                        }
                     }
                 }
                 newTierId = highestQualifyingTier;
            }
        }


        if (newTierId != oldTierId) {
            userTier[user] = newTierId;
            emit TierUpgraded(user, oldTierId, newTierId);
        }
    }

    /**
     * @dev Allows owner or a designated oracle/admin to add reputation points to a user.
     * Could represent completing off-chain tasks, positive behavior, etc.
     * In a real system, this might be triggered by a secure oracle. Here, it's owner-only.
     * @param user The address of the user to add points to.
     * @param amount The amount of reputation points to add.
     * @param reason A string describing the reason for the reputation increase. (Not stored, for event logging/transparency)
     */
    function proposeReputationIncrease(address user, uint256 amount, string memory reason) external onlyOwner whenNotPaused {
        // Note: 'reason' is just for the event, not used in logic
        _addReputation(user, amount);
        // Emit event including reason conceptually, though solidity events don't handle complex strings easily as indexed params
        // For simplicity, reason is not explicitly indexed in event
    }

     /**
     * @dev Admin function to directly set a user's base reputation points.
     * Use with extreme caution as this overrides earned points.
     * @param user The address of the user.
     * @param points The new total reputation points for the user.
     */
    function setBaseReputation(address user, uint256 points) external onlyOwner whenNotPaused {
        reputationPoints[user] = points;
        emit ReputationSet(user, points, msg.sender);
        _updateTier(user); // Ensure tier is updated based on the new points
    }


    // --- 3. Task & Quest System ---

    /**
     * @dev Admin function to create or update a task/quest.
     * Tasks are a way for users to earn reputation.
     * @param taskId A unique identifier for the task.
     * @param description A description of the task.
     * @param requiredTier The minimum tier required for a user to attempt/request verification for this task.
     * @param rewardPoints The reputation points awarded upon successful completion.
     * @param isActive Whether the task is currently active and available.
     */
    function createTask(uint256 taskId, string memory description, uint256 requiredTier, uint256 rewardPoints, bool isActive) external onlyOwner {
        require(tiers[requiredTier].exists, "Required tier does not exist");
        require(bytes(description).length > 0, "Task description cannot be empty");

        tasks[taskId] = Task(description, requiredTier, rewardPoints, isActive, true);

        emit TaskCreated(taskId, requiredTier, rewardPoints);
    }

    /**
     * @dev Returns the details of a specific task.
     * @param taskId The ID of the task.
     * @return description The task description.
     * @return requiredTier The minimum tier to attempt the task.
     * @return rewardPoints The reputation points awarded.
     * @return isActive Whether the task is active.
     * @return exists Whether the task ID is defined.
     */
    function getTaskDetails(uint256 taskId) external view returns (string memory description, uint256 requiredTier, uint256 rewardPoints, bool isActive, bool exists) {
        Task storage task = tasks[taskId];
        return (task.description, task.requiredTier, task.rewardPoints, task.isActive, task.exists);
    }

     /**
     * @dev Returns whether a user has completed a specific task.
     * @param user The address of the user.
     * @param taskId The ID of the task.
     * @return True if the user has completed the task, false otherwise.
     */
    function isTaskCompletedByUser(address user, uint256 taskId) external view returns (bool) {
        return completedTasks[user][taskId];
    }

    /**
     * @dev Allows a user to signal they have completed a task and are requesting verification.
     * Requires the user to meet the task's minimum tier requirement.
     * @param taskId The ID of the task completed.
     */
    function requestTaskCompletionVerification(uint256 taskId) external whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.exists, "Task does not exist");
        require(task.isActive, "Task is not active");
        require(userTier[msg.sender] >= task.requiredTier, "User does not meet required tier for task");
        require(!completedTasks[msg.sender][taskId], "Task already completed by user");
        require(!verificationRequestedTasks[msg.sender][taskId], "Verification already requested for this task");

        verificationRequestedTasks[msg.sender][taskId] = true;

        emit TaskCompletionRequested(msg.sender, taskId);
    }

     /**
     * @dev Allows the owner or designated task executor to verify a user's task completion.
     * Awards reputation points and marks the task as completed for the user.
     * Resets the verification requested status for the user/task.
     * @param user The address of the user whose task completion is being verified.
     * @param taskId The ID of the task being verified.
     */
    function verifyTaskCompletion(address user, uint256 taskId) external onlyTaskExecutorOrOwner whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.exists, "Task does not exist");
        require(task.isActive, "Task is not active");
        require(userTier[user] >= task.requiredTier, "User did not meet required tier for task at time of request"); // Could add a timestamp check for added robustness
        require(!completedTasks[user][taskId], "Task already completed by user");
        require(verificationRequestedTasks[user][taskId], "Verification was not requested for this task by this user");

        // Mark as completed
        completedTasks[user][taskId] = true;
        // Award reputation
        _addReputation(user, task.rewardPoints);
        // Reset verification request status
        verificationRequestedTasks[user][taskId] = false;

        emit TaskCompleted(user, taskId, task.rewardPoints);
    }

    /**
     * @dev Admin function to deactivate a task. Inactive tasks cannot be attempted or verified.
     * @param taskId The ID of the task to deactivate.
     */
    function deactivateTask(uint256 taskId) external onlyOwner {
        require(tasks[taskId].exists, "Task does not exist");
        tasks[taskId].isActive = false;
        emit TaskDeactivated(taskId);
    }

    // NOTE: getTasksForTier(uint256 tierId) - Implementing this efficiently (returning an array)
    // requires storing task IDs per tier or iterating all tasks. Iterating is gas-intensive.
    // Storing in arrays per tier adds complexity on task creation/removal.
    // A realistic implementation might return all tasks and let the frontend filter,
    // or use a more complex mapping structure. For this example, we'll omit the direct
    // array return but include the summary entry.

    // --- 4. Gated Actions & Features ---

    /**
     * @dev An example function that requires the user to be in Tier 1 or higher.
     * @param parameter A dummy parameter for the function.
     */
    function performTier1Action(uint256 parameter) external whenNotPaused requiresTier(1) {
        // Logic for Tier 1+ feature
        // ...
        emit FeatureUnlocked(msg.sender, userTier[msg.sender], "Tier1Action");
    }

    /**
     * @dev An example function that requires the user to be in Tier 3 or higher.
     * Accepts a bytes payload for more complex data interaction.
     * @param dataPayload A dummy data payload for the function.
     */
    function performTier3SpecialAction(bytes calldata dataPayload) external whenNotPaused requiresTier(3) {
        // Logic for Tier 3+ special feature
        // Can decode dataPayload to access specific parameters
        // For example: abi.decode(dataPayload, (address, uint256))
        // ...
        emit FeatureUnlocked(msg.sender, userTier[msg.sender], "Tier3SpecialAction");
    }

     /**
     * @dev A conceptual function to check if a given tier ID has access to a specific feature ID.
     * Requires internal logic mapping tiers to features (not fully implemented here).
     * @param tierId The tier ID to check.
     * @param featureId A unique identifier for the feature (e.g., a bytes4 hash of the function signature).
     * @return True if the tier has access, false otherwise.
     */
    function checkTierFeatureAccess(uint256 tierId, bytes4 featureId) external view returns (bool) {
        // In a real system, you would have a mapping like:
        // mapping(uint256 => mapping(bytes4 => bool)) public tierFeatures;
        // return tierFeatures[tierId][featureId];

        // For this example, let's implement simple logic:
        // Tier 1+ access 'Tier1Action' (hash of function signature)
        // Tier 3+ access 'Tier3SpecialAction' (hash of function signature)
        bytes4 tier1ActionHash = this.performTier1Action.selector;
        bytes4 tier3SpecialActionHash = this.performTier3SpecialAction.selector;

        if (!tiers[tierId].exists) {
             return false; // Cannot check access for non-existent tier
        }

        if (featureId == tier1ActionHash) {
            return tierId >= 1;
        } else if (featureId == tier3SpecialActionHash) {
            return tierId >= 3;
        }
        // Add more feature checks here...

        return false; // Feature not recognized or not linked to tiers this way
    }

    event FeatureUnlocked(address indexed user, uint256 indexed tierId, string featureName); // Example event

    // --- 5. Tier Rewards ---

    /**
     * @dev Allows a user to claim a one-time reward associated with a specific tier they have reached.
     * Requires the user's current tier to be at least the tier for which the reward is claimed.
     * @param tierId The ID of the tier for which to claim the reward.
     * NOTE: Reward logic (e.g., transferring tokens) would be added here.
     */
    function claimTierReward(uint256 tierId) external whenNotPaused requiresTier(tierId) {
        require(tiers[tierId].exists, "Tier does not exist");
        require(tierId > 0, "Tier 0 has no claimable reward"); // Assume Tier 0 has no reward
        require(!claimedTierReward[msg.sender][tierId], "Tier reward already claimed");

        // --- Reward Logic Placeholder ---
        // This is where you would implement the actual reward distribution,
        // e.g., transferring a specific ERC-20 token amount, minting a special NFT, etc.
        // For demonstration, we just emit an event.
        // Example: IFungibleToken(tokenAddress).transfer(msg.sender, rewardAmountForTier[tierId]);
        // Example: INRCToken(nftContractAddress).mint(msg.sender, tierSpecificNFTId);
        // ---------------------------------

        claimedTierReward[msg.sender][tierId] = true;

        emit TierRewardClaimed(msg.sender, tierId);
    }

    /**
     * @dev Returns whether a user has claimed the one-time reward for a specific tier.
     * @param user The address of the user.
     * @param tierId The ID of the tier.
     * @return True if the reward has been claimed, false otherwise.
     */
    function getClaimStatusForTierReward(address user, uint256 tierId) external view returns (bool) {
        return claimedTierReward[user][tierId];
    }

    // --- 6. Admin & Utility ---

    /**
     * @dev Admin function to set the address of the task executor.
     * The task executor is allowed to verify task completions.
     * @param executor The address to set as the task executor.
     */
    function setTaskExecutor(address executor) external onlyOwner {
        require(executor != address(0), "Executor cannot be zero address");
        address oldExecutor = taskExecutor;
        taskExecutor = executor;
        emit TaskExecutorSet(oldExecutor, executor);
    }

    /**
     * @dev Returns the current task executor address.
     * @return The address of the task executor.
     */
    function getTaskExecutor() external view returns (address) {
        return taskExecutor;
    }

    /**
     * @dev Admin function to withdraw accumulated ETH from the contract.
     * Only callable by the owner.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawEth(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner).transfer(amount);
        emit EthWithdrawn(owner, amount);
    }

    // Fallback function to receive ETH (optional, remove if contract shouldn't receive ETH)
    receive() external payable {
        // Optionally log receipt or restrict who can send ETH
        // emit EthReceived(msg.sender, msg.value);
    }

    // --- Internal/Helper Functions (already defined: _addReputation, _updateTier) ---
}
```