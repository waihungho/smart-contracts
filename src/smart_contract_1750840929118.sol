Okay, here is a smart contract concept that aims to be interesting, advanced, creative, and trendy without directly duplicating common open-source protocols like standard ERC-20/721/1155, basic staking, simple AMMs, or fixed-price mints.

This concept is a **Dynamic Effort & Reputation Protocol (DERP)**. It's a system where users stake a base token ("Effort"), passively generate a time-based resource ("Focus"), use Focus and potentially Effort/Reputation to perform various "Actions", earn "Reputation" and a dynamic reward token ("Reward") from completing Actions, and potentially craft "Artifacts" using resources and Reputation.

It incorporates:
1.  **Time-Weighted Resource Generation:** Passive Focus generation based on staked Effort and time.
2.  **Reputation System:** Earned through successful actions, potentially decays (though decay is complex to implement perfectly on-chain, we'll include functions for it conceptually), affects eligibility and rewards.
3.  **Action System:** Multi-stage or single-stage tasks requiring resources, yielding rewards and reputation upon completion. Different action types with varying requirements and outputs.
4.  **Dynamic Rewards:** Reward rate influenced by overall protocol activity (e.g., total staked Effort, total reputation).
5.  **Crafting:** Burning resources and reputation to create unique (or scarce) digital items (represented here as counts of artifact IDs per user).
6.  **Pausable & Ownable:** Standard access control and emergency stop mechanisms.

**Disclaimer:** This is a complex example designed to showcase various concepts. It is *not* audited or ready for production use without significant testing, optimization, and security review. Implementing concepts like perfect on-chain reputation decay or highly dynamic reward curves can be gas-intensive and complex.

---

**Outline and Function Summary**

**Contract Name:** DynamicEffortReputationProtocol (DERP)

**Core Concept:** Users stake $EFFORT, generate $FOCUS over time, use $FOCUS and $EFFORT/$REPUTATION to perform $ACTIONS, earning $REPUTATION and $REWARD. Users can also craft $ARTIFACTS.

**Key Components:**
*   `EFFORT` Token (ERC-20): Base staking token.
*   `REWARD` Token (ERC-20): Protocol reward token.
*   `FOCUS`: Internal resource generated over time from staking $EFFORT.
*   `REPUTATION`: Non-transferable score earned by completing actions.
*   `ACTIONS`: Predefined tasks requiring $FOCUS/$EFFORT/$REPUTATION, granting $REWARD/$REPUTATION upon completion.
*   `ARTIFACTS`: Digital items crafted by burning resources.

**State Variables:**
*   Token addresses (`effortToken`, `rewardToken`)
*   User state (staked $EFFORT, $FOCUS balance, $REPUTATION, last focus claim time, active actions, artifact counts)
*   Protocol state (total staked $EFFORT, action types, artifact recipes, dynamic rate params, next action ID)
*   Admin state (owner, paused status)

**Structs:**
*   `ActionType`: Defines cost, duration, rewards, rep gain for a type of action.
*   `UserAction`: Tracks an instance of a user performing an action.
*   `ArtifactRecipe`: Defines resource costs and reputation requirement for crafting.

**Events:**
*   `Staked`, `Unstaked`, `RewardsClaimed`, `FocusClaimed`
*   `ActionStarted`, `ActionCompleted`, `ActionCancelled`
*   `ArtifactCrafted`
*   `ReputationGained`, `ReputationLost` (if decay implemented)
*   Admin events (`ActionTypeAdded`, `RecipeAdded`, etc.)

**Functions (20+):**

**Core User Interaction (17 functions):**
1.  `constructor`: Initializes contract with token addresses and owner.
2.  `stake(uint256 amount)`: Stakes $EFFORT tokens. Requires user approval.
3.  `unstake(uint256 amount)`: Unstakes $EFFORT tokens. Subject to potential cool-downs or penalties (not implemented for brevity, but could be added).
4.  `claimGeneratedFocus()`: Claims passively generated $FOCUS based on staked $EFFORT and time.
5.  `startAction(uint256 actionTypeId)`: Initiates a specific type of action. Checks requirements ($FOCUS, $EFFORT, $REPUTATION). Burns required resources. Creates a `UserAction` instance.
6.  `completeAction(uint256 userActionId)`: Finalizes a started action after its duration has passed. Grants $REWARD and $REPUTATION.
7.  `cancelAction(uint256 userActionId)`: Stops an ongoing action. May incur penalties or partial resource return (not implemented).
8.  `claimRewards()`: Claims all accrued $REWARD from completed actions and passive generation (if applicable).
9.  `craftArtifact(uint256 artifactId)`: Crafts an artifact. Checks recipe requirements ($FOCUS, $EFFORT, $REPUTATION). Burns required resources. Increments user's artifact count.

**View / Query Functions (11 functions):**
10. `getUserStake(address user)`: Returns the amount of $EFFORT staked by a user.
11. `getUserFocusBalance(address user)`: Returns the usable $FOCUS balance of a user.
12. `getUserReputation(address user)`: Returns the $REPUTATION score of a user.
13. `getUserGeneratedFocus(address user)`: Calculates and returns the amount of $FOCUS a user *could* claim based on time since last claim.
14. `getUserRewardBalance(address user)`: Calculates and returns the amount of $REWARD a user *could* claim.
15. `getUserActiveActions(address user)`: Returns a list of `userActionId`s for a user's ongoing actions.
16. `getUserActionDetails(uint256 userActionId)`: Returns details of a specific ongoing or completed user action.
17. `getUserArtifactCount(address user, uint256 artifactId)`: Returns the count of a specific artifact owned by a user.
18. `getActionTypeDetails(uint256 actionTypeId)`: Returns the parameters of a specific action type.
19. `getNumActionTypes()`: Returns the total number of defined action types.
20. `getArtifactRecipeDetails(uint256 artifactId)`: Returns the requirements for crafting a specific artifact.
21. `getDynamicRewardRate()`: Calculates and returns the current dynamic multiplier for rewards.

**Admin / Protocol Management (9 functions):**
22. `pause()`: Pauses core user actions (staking, claiming, actions, crafting).
23. `unpause()`: Unpauses the contract.
24. `addActionType(uint256 actionTypeId, ActionType calldata params)`: Adds or updates an action type definition.
25. `removeActionType(uint256 actionTypeId)`: Removes an action type definition (careful with active actions!).
26. `addArtifactRecipe(uint256 artifactId, ArtifactRecipe calldata params)`: Adds or updates an artifact recipe definition.
27. `removeArtifactRecipe(uint256 artifactId)`: Removes an artifact recipe definition.
28. `setFocusGenerationRate(uint256 ratePerSecondPerEffort)`: Sets the rate at which Focus is generated per staked Effort per second.
29. `setDynamicRewardParams(...)`: Sets parameters influencing the dynamic reward rate calculation (e.g., scaling factors for total stake, total reputation).
30. `recoverERC20(address tokenAddress, uint256 amount)`: Allows owner to recover accidentally sent ERC20 tokens (excluding protocol tokens).

Total Functions: 30

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Redundant in 0.8+, but good for clarity/habit if needed

// --- Outline ---
// Contract: DynamicEffortReputationProtocol (DERP)
// Core Concept: Stake $EFFORT, generate $FOCUS, perform $ACTIONS for $REPUTATION & $REWARD, craft $ARTIFACTS.
// Components: $EFFORT (ERC20), $REWARD (ERC20), $FOCUS (Internal), $REPUTATION (Score), $ACTIONS (Tasks), $ARTIFACTS (Items).
// State: Token addresses, user balances/scores/actions/artifacts, protocol totals, definitions (actions, recipes), admin state.
// Structs: ActionType, UserAction, ArtifactRecipe.
// Events: Staking, Rewards, Focus, Actions, Crafting, Reputation, Admin.
// Functions: User interactions (Stake, Unstake, Claim Focus/Rewards, Start/Complete/Cancel Action, Craft), Views, Admin.

// --- Function Summary ---
// 1. constructor(address _effortToken, address _rewardToken, uint256 _initialFocusRate): Initializes contract.
// 2. stake(uint256 amount): Stakes EFFORT.
// 3. unstake(uint256 amount): Unstakes EFFORT.
// 4. claimGeneratedFocus(): Claims generated FOCUS.
// 5. startAction(uint256 actionTypeId): Starts an action.
// 6. completeAction(uint256 userActionId): Completes an action.
// 7. cancelAction(uint256 userActionId): Cancels an action.
// 8. claimRewards(): Claims accrued REWARD.
// 9. craftArtifact(uint256 artifactId): Crafts an artifact.
// 10. getUserStake(address user): View staked EFFORT.
// 11. getUserFocusBalance(address user): View FOCUS balance.
// 12. getUserReputation(address user): View REPUTATION.
// 13. getUserGeneratedFocus(address user): View claimable FOCUS.
// 14. getUserRewardBalance(address user): View claimable REWARD.
// 15. getUserActiveActions(address user): View active action IDs.
// 16. getUserActionDetails(uint256 userActionId): View action details.
// 17. getUserArtifactCount(address user, uint256 artifactId): View artifact count.
// 18. getActionTypeDetails(uint256 actionTypeId): View action type details.
// 19. getNumActionTypes(): View total action types.
// 20. getArtifactRecipeDetails(uint256 artifactId): View artifact recipe details.
// 21. getDynamicRewardRate(): View current dynamic reward rate.
// 22. pause(): Owner pauses.
// 23. unpause(): Owner unpauses.
// 24. addActionType(uint256 actionTypeId, ActionType calldata params): Owner adds/updates action type.
// 25. removeActionType(uint256 actionTypeId): Owner removes action type.
// 26. addArtifactRecipe(uint256 artifactId, ArtifactRecipe calldata params): Owner adds/updates recipe.
// 27. removeArtifactRecipe(uint256 artifactId): Owner removes recipe.
// 28. setFocusGenerationRate(uint256 ratePerSecondPerEffort): Owner sets focus rate.
// 29. setDynamicRewardParams(uint256 totalStakeWeight, uint256 totalReputationWeight): Owner sets dynamic reward weights.
// 30. recoverERC20(address tokenAddress, uint256 amount): Owner recovers tokens.

contract DynamicEffortReputationProtocol is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Still useful for explicit checks sometimes, though 0.8+ has built-in checks

    // --- State Variables ---

    IERC20 public immutable effortToken;
    IERC20 public immutable rewardToken;

    // User Balances & Scores
    mapping(address => uint256) private _stakedEffort;
    mapping(address => uint256) private _userFocusBalance;
    mapping(address => uint256) private _userReputation;
    mapping(address => uint256) private _lastFocusClaimTime; // Timestamp of last FOCUS claim
    mapping(address => mapping(uint256 => uint256)) private _userArtifactCounts; // artifactId => count

    // Protocol Totals
    uint256 private _totalStakedEffort;
    uint256 private _totalReputation; // Sum of all user reputations
    // uint256 private _totalFocusConsumed; // Could track this for dynamic rates, but adds complexity

    // Action Definitions
    struct ActionType {
        string name;
        uint256 focusCost;
        uint256 effortCost; // Optional EFFORT cost
        uint256 duration; // In seconds
        uint256 rewardAmount;
        uint256 reputationGain;
        uint256 requiredReputation; // Minimum reputation to start
        bool exists; // To check if an action type ID is valid
    }
    mapping(uint256 => ActionType) private _actionTypes;
    uint256[] private _actionTypeIds; // List of valid action type IDs

    // User Action Instances
    enum ActionState {
        None,
        InProgress,
        Completed,
        Cancelled
    }
    struct UserAction {
        uint256 actionTypeId;
        address user;
        uint256 startTime;
        uint256 endTime;
        ActionState state;
    }
    mapping(uint256 => UserAction) private _userActions; // userActionId => UserAction
    mapping(address => uint256[] ) private _userActionIds; // List of action IDs for a user
    Counters.Counter private _userActionIdCounter;

    // Artifact Recipes
    struct ArtifactRecipe {
        string name;
        uint256 focusCost;
        uint256 effortCost; // Optional EFFORT cost
        uint256 reputationCost; // Reputation burned or required? Let's make it required AND consume a small amount or have a cooldown based on rep. Simple: Required min rep & consume resources.
        bool exists; // To check if a recipe ID is valid
    }
    mapping(uint256 => ArtifactRecipe) private _artifactRecipes;
    uint256[] private _artifactIds; // List of valid artifact IDs

    // Dynamic Rate Parameters
    uint256 public focusGenerationRatePerSecondPerEffort; // How much FOCUS 1 EFFORT generates per second
    uint256 public dynamicRewardTotalStakeWeight; // Weight for total stake in dynamic rate (e.g., 1000 for 0.1x influence)
    uint256 public dynamicRewardTotalReputationWeight; // Weight for total reputation in dynamic rate

    // --- Events ---

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event FocusClaimed(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationGained(address indexed user, uint256 amount);
    // event ReputationLost(address indexed user, uint256 amount); // If decay is implemented

    event ActionStarted(address indexed user, uint256 userActionId, uint256 actionTypeId);
    event ActionCompleted(address indexed user, uint256 userActionId, uint256 rewardAmount, uint256 reputationGained);
    event ActionCancelled(address indexed user, uint256 userActionId);

    event ArtifactCrafted(address indexed user, uint256 artifactId, uint256 newCount);

    event ActionTypeAdded(uint256 indexed actionTypeId, string name);
    event ActionTypeUpdated(uint256 indexed actionTypeId, string name);
    event ActionTypeRemoved(uint256 indexed actionTypeId);

    event ArtifactRecipeAdded(uint256 indexed artifactId, string name);
    event ArtifactRecipeUpdated(uint256 indexed artifactId, string name);
    event ArtifactRecipeRemoved(uint256 indexed artifactId);

    event FocusRateSet(uint256 rate);
    event DynamicRewardParamsSet(uint256 totalStakeWeight, uint256 totalReputationWeight);

    // --- Modifiers ---

    // No custom modifiers needed beyond Pausable's whenNotPaused and Ownable's onlyOwner

    // --- Constructor ---

    /// @notice Initializes the contract with token addresses and initial parameters.
    /// @param _effortToken Address of the EFFORT ERC20 token.
    /// @param _rewardToken Address of the REWARD ERC20 token.
    /// @param _initialFocusRate Initial rate for FOCUS generation (per second per staked Effort).
    constructor(address _effortToken, address _rewardToken, uint256 _initialFocusRate) Ownable(msg.sender) Pausable() {
        require(_effortToken != address(0), "Invalid effort token address");
        require(_rewardToken != address(0), "Invalid reward token address");

        effortToken = IERC20(_effortToken);
        rewardToken = IERC20(_rewardToken);
        focusGenerationRatePerSecondPerEffort = _initialFocusRate;

        // Set initial dynamic reward parameters (can be 0 to disable dynamic part)
        dynamicRewardTotalStakeWeight = 0;
        dynamicRewardTotalReputationWeight = 0;
    }

    // --- Core User Interaction Functions ---

    /// @notice Stakes EFFORT tokens in the protocol.
    /// @param amount The amount of EFFORT tokens to stake.
    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot stake 0");

        // Transfer tokens from user to contract
        // User must approve contract beforehand!
        effortToken.transferFrom(msg.sender, address(this), amount);

        // Update state
        uint256 pendingFocus = _calculateGeneratedFocus(msg.sender);
        _userFocusBalance[msg.sender] = _userFocusBalance[msg.sender].add(pendingFocus);
        _lastFocusClaimTime[msg.sender] = block.timestamp;

        _stakedEffort[msg.sender] = _stakedEffort[msg.sender].add(amount);
        _totalStakedEffort = _totalStakedEffort.add(amount);

        emit Staked(msg.sender, amount);
    }

    /// @notice Unstakes EFFORT tokens from the protocol.
    /// @param amount The amount of EFFORT tokens to unstake.
    function unstake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Cannot unstake 0");
        require(_stakedEffort[msg.sender] >= amount, "Insufficient staked effort");

        // Claim pending focus before unstaking to capture generation up to this point
        uint256 pendingFocus = _calculateGeneratedFocus(msg.sender);
        _userFocusBalance[msg.sender] = _userFocusBalance[msg.sender].add(pendingFocus);
        _lastFocusClaimTime[msg.sender] = block.timestamp; // Reset time based on current timestamp

        // Update state
        _stakedEffort[msg.sender] = _stakedEffort[msg.sender].sub(amount);
        _totalStakedEffort = _totalStakedEffort.sub(amount);

        // Transfer tokens back to user
        effortToken.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /// @notice Claims generated FOCUS resource.
    function claimGeneratedFocus() external whenNotPaused {
        uint256 pendingFocus = _calculateGeneratedFocus(msg.sender);
        require(pendingFocus > 0, "No focus generated yet");

        _userFocusBalance[msg.sender] = _userFocusBalance[msg.sender].add(pendingFocus);
        _lastFocusClaimTime[msg.sender] = block.timestamp; // Reset time

        emit FocusClaimed(msg.sender, pendingFocus);
    }

    /// @notice Starts a specific type of action.
    /// @param actionTypeId The ID of the action type to start.
    function startAction(uint256 actionTypeId) external whenNotPaused {
        ActionType storage actionType = _actionTypes[actionTypeId];
        require(actionType.exists, "Invalid action type");
        require(_userFocusBalance[msg.sender] >= actionType.focusCost, "Insufficient focus");
        require(_stakedEffort[msg.sender] >= actionType.effortCost, "Insufficient staked effort for action");
        require(_userReputation[msg.sender] >= actionType.requiredReputation, "Insufficient reputation to start action");

        // Deduct costs
        _userFocusBalance[msg.sender] = _userFocusBalance[msg.sender].sub(actionType.focusCost);
        // Note: EffortCost is conceptually "used" or locked, but we won't transfer it out yet.
        // A more complex version might temporarily reduce usable stakedEffort.
        // For simplicity here, it's just a requirement check.

        // Create action instance
        uint256 userActionId = _userActionIdCounter.current();
        _userActionIdCounter.increment();

        _userActions[userActionId] = UserAction({
            actionTypeId: actionTypeId,
            user: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp.add(actionType.duration),
            state: ActionState.InProgress
        });

        _userActionIds[msg.sender].push(userActionId);

        emit ActionStarted(msg.sender, userActionId, actionTypeId);
    }

    /// @notice Completes a started action after its duration has passed.
    /// @param userActionId The ID of the user's action instance.
    function completeAction(uint256 userActionId) external whenNotPaused {
        UserAction storage userAction = _userActions[userActionId];
        require(userAction.user == msg.sender, "Not your action");
        require(userAction.state == ActionState.InProgress, "Action not in progress");
        require(block.timestamp >= userAction.endTime, "Action duration not passed yet");

        // Mark as completed
        userAction.state = ActionState.Completed;

        // Grant rewards and reputation
        ActionType storage actionType = _actionTypes[userAction.actionTypeId];
        uint256 rewardAmount = actionType.rewardAmount;
        uint256 reputationGain = actionType.reputationGain;

        // Apply dynamic rate multiplier to rewards
        uint256 dynamicMultiplier = _getDynamicRewardRate();
        // Simple multiplier application: rewardAmount = (rewardAmount * dynamicMultiplier) / SCALING_FACTOR
        // Need a scaling factor if dynamicMultiplier is >100 or uses decimals. Let's use 10000 for 4 decimals.
        uint256 scaledReward = rewardAmount.mul(dynamicMultiplier).div(10000); // Assuming dynamicMultiplier is base 10000 (e.g., 1.2345 represented as 12345)

        // Accumulate rewards (don't transfer yet, user must claim)
        // Need a way to track accumulated rewards per user. Add a mapping.
        mapping(address => uint256) private _userPendingRewards;
        _userPendingRewards[msg.sender] = _userPendingRewards[msg.sender].add(scaledReward);

        // Grant reputation
        _userReputation[msg.sender] = _userReputation[msg.sender].add(reputationGain);
        _totalReputation = _totalReputation.add(reputationGain);

        emit ActionCompleted(msg.sender, userActionId, scaledReward, reputationGain);
        emit ReputationGained(msg.sender, reputationGain);
    }

    /// @notice Cancels a started action. No refunds implemented for simplicity.
    /// @param userActionId The ID of the user's action instance.
    function cancelAction(uint256 userActionId) external whenNotPaused {
        UserAction storage userAction = _userActions[userActionId];
        require(userAction.user == msg.sender, "Not your action");
        require(userAction.state == ActionState.InProgress, "Action not in progress");

        // Mark as cancelled
        userAction.state = ActionState.Cancelled;

        // Note: No refund of costs or penalty implemented here.
        // A real system might return some resources or apply a penalty.

        emit ActionCancelled(msg.sender, userActionId);
    }

    /// @notice Claims all accrued REWARD tokens.
    function claimRewards() external whenNotPaused {
        uint256 amount = _userPendingRewards[msg.sender];
        require(amount > 0, "No rewards to claim");

        // Reset pending rewards
        _userPendingRewards[msg.sender] = 0;

        // Transfer rewards to user
        rewardToken.transfer(msg.sender, amount);

        emit RewardsClaimed(msg.sender, amount);
    }

    /// @notice Crafts an artifact by burning resources and meeting reputation requirement.
    /// @param artifactId The ID of the artifact to craft.
    function craftArtifact(uint256 artifactId) external whenNotPaused {
        ArtifactRecipe storage recipe = _artifactRecipes[artifactId];
        require(recipe.exists, "Invalid artifact ID");
        require(_userFocusBalance[msg.sender] >= recipe.focusCost, "Insufficient focus to craft");
        require(_stakedEffort[msg.sender] >= recipe.effortCost, "Insufficient staked effort to craft");
        require(_userReputation[msg.sender] >= recipe.reputationCost, "Insufficient reputation to craft");

        // Deduct costs
        _userFocusBalance[msg.sender] = _userFocusBalance[msg.sender].sub(recipe.focusCost);
        // EffortCost is a requirement here, not burned.
        // ReputationCost is a minimum requirement, not burned, unless desired. Let's make it a minimum.

        // Mint/Grant artifact (increment count)
        _userArtifactCounts[msg.sender][artifactId] = _userArtifactCounts[msg.sender][artifactId].add(1);

        emit ArtifactCrafted(msg.sender, artifactId, _userArtifactCounts[msg.sender][artifactId]);
    }

    // --- View / Query Functions ---

    /// @notice Returns the amount of EFFORT staked by a user.
    /// @param user The user's address.
    /// @return The staked amount.
    function getUserStake(address user) external view returns (uint256) {
        return _stakedEffort[user];
    }

     /// @notice Returns the total amount of EFFORT staked across all users.
    /// @return The total staked amount.
    function getTotalStaked() external view returns (uint256) {
        return _totalStakedEffort;
    }

    /// @notice Returns the usable FOCUS balance of a user.
    /// @param user The user's address.
    /// @return The FOCUS balance.
    function getUserFocusBalance(address user) external view returns (uint256) {
        return _userFocusBalance[user];
    }

    /// @notice Returns the REPUTATION score of a user.
    /// @param user The user's address.
    /// @return The REPUTATION score.
    function getUserReputation(address user) external view returns (uint256) {
        return _userReputation[user];
    }

    /// @notice Calculates and returns the amount of FOCUS a user could claim.
    /// @param user The user's address.
    /// @return The pending FOCUS amount.
    function getUserGeneratedFocus(address user) public view returns (uint256) {
        return _calculateGeneratedFocus(user);
    }

     /// @notice Calculates and returns the amount of REWARD a user could claim.
    /// @param user The user's address.
    /// @return The pending REWARD amount.
    function getUserRewardBalance(address user) external view returns (uint256) {
        return _userPendingRewards[user];
    }

    /// @notice Returns the list of IDs for a user's active and completed actions.
    /// @param user The user's address.
    /// @return An array of user action IDs.
    function getUserActiveActions(address user) external view returns (uint256[] memory) {
        // This returns all action IDs for a user, you might filter by state off-chain
        return _userActionIds[user];
    }

    /// @notice Returns details of a specific user action instance.
    /// @param userActionId The ID of the user's action instance.
    /// @return The action details.
    function getUserActionDetails(uint256 userActionId) external view returns (UserAction memory) {
        require(_userActions[userActionId].user != address(0), "Invalid user action ID"); // Check if action exists
        return _userActions[userActionId];
    }

    /// @notice Returns the count of a specific artifact owned by a user.
    /// @param user The user's address.
    /// @param artifactId The ID of the artifact.
    /// @return The count of the artifact.
    function getUserArtifactCount(address user, uint256 artifactId) external view returns (uint256) {
        return _userArtifactCounts[user][artifactId];
    }

    /// @notice Returns the parameters of a specific action type.
    /// @param actionTypeId The ID of the action type.
    /// @return The action type details.
    function getActionTypeDetails(uint256 actionTypeId) external view returns (ActionType memory) {
        require(_actionTypes[actionTypeId].exists, "Invalid action type ID");
        return _actionTypes[actionTypeId];
    }

    /// @notice Returns the total number of defined action types.
    /// @return The count of action types.
    function getNumActionTypes() external view returns (uint256) {
        return _actionTypeIds.length;
    }

    /// @notice Returns the parameters required for crafting a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return The artifact recipe details.
    function getArtifactRecipeDetails(uint256 artifactId) external view returns (ArtifactRecipe memory) {
        require(_artifactRecipes[artifactId].exists, "Invalid artifact ID");
        return _artifactRecipes[artifactId];
    }

    /// @notice Calculates and returns the current dynamic multiplier for rewards.
    /// @return The dynamic multiplier (scaled by 10000).
    function getDynamicRewardRate() public view returns (uint256) {
        // Simple example: base rate is 10000 (1x multiplier).
        // Add bonus based on total reputation relative to total staked effort.
        // Avoid division by zero if total staked is 0.
        uint256 baseMultiplier = 10000; // 1x

        if (_totalStakedEffort == 0 || (dynamicRewardTotalStakeWeight == 0 && dynamicRewardTotalReputationWeight == 0)) {
             return baseMultiplier;
        }

        // Example calculation: Base + (TotalReputation * RepWeight) / (TotalStakedEffort * StakeWeight)
        // Needs careful scaling to avoid overflow and underflow.
        // Let's do a simpler version: base + (TotalReputation / ScalingFactorRep) * (TotalStaked / ScalingFactorStake)
        // Even simpler: multiplier = base + (totalRep * repWeight) / (totalStaked * stakeWeight / 10000?)
        // Let's make it a ratio: base * (1 + (totalRep * repWeight) / (totalStaked * stakeWeight))
        // Or base * (totalRep / totalStaked) * ratioWeight
        // A common pattern is: base * (1 + influence) where influence is f(rep, stake, etc.)
        // Example: 1x + (totalRep / 1e18) * repWeight / (totalStake / 1e18) * stakeWeight ... this needs careful scaling.

        // Simpler dynamic rate: base + bonus based on total reputation / total staked ratio
        // Bonus = (totalReputation * dynamicRewardTotalReputationWeight) / (totalStakedEffort * dynamicRewardTotalStakeWeight / 1e18) ?
        // Let's assume dynamicRewardTotalStakeWeight and dynamicRewardTotalReputationWeight are scaling factors themselves.
        // e.g., if repWeight=1, stakeWeight=10000, then TotalRep/1e18 gives bonus 1 for every 1e18 total rep per TotalStake/10000.
        // A robust dynamic rate needs careful math and state tracking (like total focus consumed, actions completed, etc.)
        // For this example, let's use a simpler conceptual one:
        // Multiplier increases as TotalReputation increases relative to TotalStakedEffort.
        // multiplier = base + (totalReputation * repWeight / 1e18) / (totalStakedEffort * stakeWeight / 1e18) * someFactor
        // Let's use fixed weights for simplicity in this example:
        // Multiplier = base + (totalRep * dynamicRewardTotalReputationWeight) / (totalStaked * dynamicRewardTotalStakeWeight) * some_scale
        // Example: base=10000. repWeight=1000, stakeWeight=10000.
        // If totalRep=10000, totalStaked=1e18, Bonus = (10000 * 1000) / (1e18 * 10000) * scale
        // Let's use the weights as direct multipliers/divisors after scaling the inputs
        // Multiplier = base + ( (_totalReputation / 1e18) * dynamicRewardTotalReputationWeight ) / ( (_totalStakedEffort / 1e18) * dynamicRewardTotalStakeWeight ) * 1e18 / 1e18
        // This still risks division by zero or tiny numbers.

        // More robust approach for demo: Multiplier = base + (totalReputation * RepFactor) / (totalStakedEffort * StakeFactor + 1)
        // Where RepFactor and StakeFactor are set by owner.
        uint256 repTerm = _totalReputation.mul(dynamicRewardTotalReputationWeight);
        uint256 stakeTerm = _totalStakedEffort.mul(dynamicRewardTotalStakeWeight);

        // Add 1 to denominator to avoid division by zero if StakeFactor is 0 and totalStaked is 0, or StakeFactor is huge
        uint256 bonus = 0;
        if (stakeTerm > 0) {
           // Scale repTerm up before division if stakeTerm is large to maintain precision
           // Use a large factor like 1e18 for scaling
           bonus = repTerm.mul(1e18).div(stakeTerm); // Bonus is now scaled by 1e18
        } else if (repTerm > 0) {
            // If stakeTerm is zero but repTerm is positive, bonus is effectively infinite? Cap it.
            bonus = 10000 * 100; // Cap bonus to 100x base multiplier, scaled by 1e18
        }
        // Scale bonus back down and add to base
        // Add a scaling factor `dynamicRewardRateScale` set by owner
        // Let's add a state var `dynamicRewardRateScale`
         uint256 public dynamicRewardRateScale = 1e18; // Scale for the bonus term

        if (stakeTerm > 0) {
           bonus = repTerm.mul(dynamicRewardRateScale).div(stakeTerm);
        } else if (repTerm > 0) {
             bonus = dynamicRewardRateScale.mul(100); // Cap bonus contribution if total stake is zero
        } else {
            bonus = 0;
        }


        // Apply bonus with its scale and the base multiplier scale (10000)
        // Total Multiplier (scaled by 10000) = 10000 + (bonus * 10000 / dynamicRewardRateScale)
        // Example: bonus = 0.5e18, dynamicRewardRateScale = 1e18
        // bonus scaled = 0.5e18 * 10000 / 1e18 = 5000
        // Multiplier = 10000 + 5000 = 15000 (1.5x)
        // Example: bonus = 2e18, dynamicRewardRateScale = 1e18
        // bonus scaled = 2e18 * 10000 / 1e18 = 20000
        // Multiplier = 10000 + 20000 = 30000 (3x)

        uint256 scaledBonus = bonus.mul(10000).div(dynamicRewardRateScale);

        return baseMultiplier.add(scaledBonus);
    }


    // --- Admin / Protocol Management Functions ---

    /// @notice Pauses core user interactions. Only callable by owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses core user interactions. Only callable by owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Adds or updates an action type definition.
    /// @param actionTypeId The ID of the action type.
    /// @param params The parameters for the action type.
    function addActionType(uint256 actionTypeId, ActionType calldata params) external onlyOwner {
        // Basic validation for params
        require(bytes(params.name).length > 0, "Action name cannot be empty");
        // Add more param validation if needed (e.g., duration > 0)

        bool isUpdate = _actionTypes[actionTypeId].exists;
        _actionTypes[actionTypeId] = params;
        _actionTypes[actionTypeId].exists = true; // Ensure exists flag is set

        if (!isUpdate) {
            _actionTypeIds.push(actionTypeId);
            emit ActionTypeAdded(actionTypeId, params.name);
        } else {
            emit ActionTypeUpdated(actionTypeId, params.name);
        }
    }

    /// @notice Removes an action type definition. Careful: Does not affect active actions of this type.
    /// @param actionTypeId The ID of the action type to remove.
    function removeActionType(uint256 actionTypeId) external onlyOwner {
        require(_actionTypes[actionTypeId].exists, "Invalid action type ID");

        // In a real system, you might want to prevent removal if active actions exist,
        // or handle them gracefully (e.g., auto-complete or cancel with refunds).
        // For simplicity here, we just mark it as not existing.

        delete _actionTypes[actionTypeId];
        // Remove from _actionTypeIds array (less efficient, but ok for admin function)
        for (uint i = 0; i < _actionTypeIds.length; i++) {
            if (_actionTypeIds[i] == actionTypeId) {
                _actionTypeIds[i] = _actionTypeIds[_actionTypeIds.length - 1];
                _actionTypeIds.pop();
                break;
            }
        }

        emit ActionTypeRemoved(actionTypeId);
    }

    /// @notice Adds or updates an artifact recipe definition.
    /// @param artifactId The ID of the artifact.
    /// @param params The parameters for the artifact recipe.
    function addArtifactRecipe(uint256 artifactId, ArtifactRecipe calldata params) external onlyOwner {
        // Basic validation for params
        require(bytes(params.name).length > 0, "Artifact name cannot be empty");
        // Add more param validation if needed

        bool isUpdate = _artifactRecipes[artifactId].exists;
        _artifactRecipes[artifactId] = params;
        _artifactRecipes[artifactId].exists = true; // Ensure exists flag is set

        if (!isUpdate) {
            _artifactIds.push(artifactId);
            emit ArtifactRecipeAdded(artifactId, params.name);
        } else {
             emit ArtifactRecipeUpdated(artifactId, params.name);
        }
    }

    /// @notice Removes an artifact recipe definition.
    /// @param artifactId The ID of the artifact recipe to remove.
    function removeArtifactRecipe(uint256 artifactId) external onlyOwner {
        require(_artifactRecipes[artifactId].exists, "Invalid artifact ID");

        delete _artifactRecipes[artifactId];
         // Remove from _artifactIds array (less efficient, but ok for admin function)
        for (uint i = 0; i < _artifactIds.length; i++) {
            if (_artifactIds[i] == artifactId) {
                _artifactIds[i] = _artifactIds[_artifactIds.length - 1];
                _artifactIds.pop();
                break;
            }
        }
        emit ArtifactRecipeRemoved(artifactId);
    }

    /// @notice Sets the rate at which FOCUS is generated per second per staked Effort.
    /// @param ratePerSecondPerEffort The new focus generation rate.
    function setFocusGenerationRate(uint256 ratePerSecondPerEffort) external onlyOwner {
        focusGenerationRatePerSecondPerEffort = ratePerSecondPerEffort;
        emit FocusRateSet(ratePerSecondPerEffort);
    }

    /// @notice Sets parameters influencing the dynamic reward rate calculation.
    /// Requires careful tuning. Values are simple weights/factors.
    /// Example: totalStakeWeight=1e18, totalReputationWeight=1e18, dynamicRewardRateScale=1e18
    /// This makes the bonus proportional to (totalReputation / totalStakedEffort).
    /// @param totalStakeWeight Weight for total staked effort in the calculation.
    /// @param totalReputationWeight Weight for total reputation in the calculation.
     /// @param rateScale The scaling factor for the bonus term in the dynamic rate calculation (e.g., 1e18).
    function setDynamicRewardParams(uint256 totalStakeWeight, uint256 totalReputationWeight, uint256 rateScale) external onlyOwner {
        dynamicRewardTotalStakeWeight = totalStakeWeight;
        dynamicRewardTotalReputationWeight = totalReputationWeight;
        dynamicRewardRateScale = rateScale;
        emit DynamicRewardParamsSet(totalStakeWeight, totalReputationWeight);
    }


    /// @notice Allows the owner to recover ERC20 tokens sent to the contract by mistake, excluding protocol tokens.
    /// @param tokenAddress The address of the token to recover.
    /// @param amount The amount of tokens to recover.
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(effortToken), "Cannot recover effort token");
        require(tokenAddress != address(rewardToken), "Cannot recover reward token");
        IERC20(tokenAddress).transfer(owner(), amount);
    }


    // --- Internal / Helper Functions ---

    /// @dev Calculates the amount of FOCUS generated since the last claim.
    /// @param user The user's address.
    /// @return The calculated pending FOCUS amount.
    function _calculateGeneratedFocus(address user) internal view returns (uint256) {
        uint256 staked = _stakedEffort[user];
        uint256 lastClaimTime = _lastFocusClaimTime[user];
        uint256 currentTime = block.timestamp;

        if (staked == 0 || currentTime <= lastClaimTime || focusGenerationRatePerSecondPerEffort == 0) {
            return 0;
        }

        uint256 timeElapsed = currentTime.sub(lastClaimTime);
        // Focus generated = staked * time_elapsed * rate
        // Use SafeMath multiplication implicitly via 0.8+ checks, ensure scaling is handled
        // If rate is low, may need to scale staked * rate first, then multiply by time_elapsed
        // Assuming rate is already scaled appropriately (e.g., tokens per second per effort unit * 1e18)
        // Let's assume rate is in basic units, small. E.g., 1e10 for 1e18 EFFORT per second.
        // The scaling depends on the desired magnitude of FOCUS.
        // Simple: total generated = staked * time * rate (assuming rate is small enough)
        uint256 generated = staked.mul(timeElapsed).mul(focusGenerationRatePerSecondPerEffort);

        return generated;
    }

    // Function to update reputation (e.g., handle potential decay if implemented)
    // For simplicity, reputation only increases currently.
    // function _updateUserReputation(address user) internal {
        // Placeholder for decay logic
        // uint256 lastUpdateTime = _lastReputationUpdateTime[user];
        // uint256 timeElapsed = block.timestamp.sub(lastUpdateTime);
        // uint256 decayAmount = calculateDecay(_userReputation[user], timeElapsed, decayRate);
        // _userReputation[user] = _userReputation[user].sub(decayAmount); // Check for underflow
        // _lastReputationUpdateTime[user] = block.timestamp;
        // emit ReputationLost(user, decayAmount);
    // }


}
```