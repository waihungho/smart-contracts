Okay, let's design a smart contract that incorporates a few advanced, non-standard concepts:

1.  **Integrated Reputation System:** Users have an on-chain reputation score managed by the contract itself or a trusted oracle. This reputation gates access to certain actions.
2.  **Conditional & Time-Locked Actions:** The contract manages actions that can only be executed after a set of external conditions are met (verified by oracles) AND a time lock has passed.
3.  **Reputation-Staked Commitments:** Users commit or "stake" a portion of their reputation (or require a minimum reputation) to initiate or participate in these conditional actions. Staked reputation can be slashed if conditions fail or actions are disputed.
4.  **Modular Conditions & Actions:** Use enums and bytes to allow for different *types* of conditions and actions, making the contract extensible without needing upgrades for every new type (though interpreting the bytes and potentially executing complex actions/conditions would likely require linked helper contracts or off-chain logic interacting with the contract).
5.  **Role-Based Access:** Differentiate between admin roles (Owner), Oracle roles (for reputation and condition resolution), and general users.

This creates a system where complex, multi-step, externally dependent processes can be orchestrated on-chain, with participants putting their on-chain standing (reputation) at stake.

---

**Smart Contract Outline & Function Summary**

**Contract Name:** ConditionalReputationEngine

**Core Concept:** A system for managing reputation-gated, time-locked, and oracle-verified conditional actions, where users stake reputation to participate.

**Key Components:**

1.  **Reputation:** An integer score per user. Can be increased/decreased/slashed. Managed by the contract and an assigned Oracle.
2.  **Conditions:** Abstract representations of external or internal criteria that must be met. Resolved by assigned Oracles.
3.  **Conditional Actions:** Abstract tasks or claims that can only be executed after specific Conditions are met and a time lock expires. Require minimum reputation to create.
4.  **Commitments:** A user's stake of reputation towards a specific Conditional Action, showing intent to participate or benefit.

**Function Categories & Summary:**

*   **Ownership & Control:**
    *   Standard `Ownable` functions (`transferOwnership`, `renounceOwnership`).
    *   `pause`/`unpause`: Global contract pause.
*   **Configuration:**
    *   Set addresses for Oracles (Reputation, Condition Types).
    *   Set minimum reputation required to create an action.
    *   Set reputation amount required to make a commitment.
*   **Reputation Management:**
    *   Get a user's reputation score.
    *   Increase/decrease a user's reputation (Oracle/Admin only).
    *   Slash a user's reputation (Oracle/Admin/Internal dispute result).
*   **Condition Management:**
    *   Create a new abstract Condition definition.
    *   Get Condition details.
    *   Resolve a Condition (Only by the assigned Oracle for that type).
    *   Check if a Condition is resolved and get its result.
*   **Conditional Action Management:**
    *   Create a new Conditional Action (Requires minimum reputation).
    *   Get Conditional Action details.
    *   Activate a Conditional Action (Starts its timelock).
    *   Check if a Conditional Action is ready for fulfillment (Conditions met, timelock passed).
    *   Fulfill a Conditional Action (Executes the core logic, requires readiness).
    *   Cancel a Conditional Action (Admin or Creator under specific states).
*   **Commitment Management:**
    *   Commit reputation to a specific Conditional Action (User stakes reputation).
    *   Get Commitment details.
    *   Withdraw staked reputation from a Commitment (After action resolution).
    *   Slash staked reputation from a Commitment (Internal, typically on failure/dispute).
    *   Get the number of commitments for a user.
*   **Getters & Helpers:**
    *   Various view functions to retrieve state details (counters, minimums, addresses).

**Total Functions (Public/External):** Approximately 30 (includes Ownable/Pausable).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Note: This contract is a framework. The actual logic for interpreting
// `bytes actionParameters`, `bytes conditionParameters`, and `bytes conditionResult`
// would typically be handled by external systems, helper contracts, or off-chain logic
// triggered by events and interacting back with the contract via Oracles or fulfillment calls.
// The "action execution" part is a placeholder.

/**
 * @title ConditionalReputationEngine
 * @dev A smart contract managing reputation-gated, time-locked, and oracle-verified conditional actions.
 * Participants stake reputation on potential actions, which unlock only when predefined, oracle-resolved
 * conditions are met and a time lock expires.
 * @author Your Name/Handle (or Placeholder)
 */
contract ConditionalReputationEngine is Ownable, Pausable {

    // --- Enums ---

    enum ConditionState {
        Created,
        Resolved,
        FailedResolution // Oracle reported failure or invalid resolution
    }

    enum ActionState {
        Created,        // Action defined, but not yet active
        Active,         // Timelock started, conditions can be resolved
        ReadyToFulfill, // Conditions met and timelock expired
        Fulfilled,      // Action successfully executed
        Cancelled       // Action cancelled before fulfillment
    }

    enum CommitmentState {
        Active,        // Reputation is staked
        Withdrawn,     // Reputation has been successfully withdrawn
        Slashed        // Reputation has been slashed due to action failure/dispute
    }

    // --- Structs ---

    /**
     * @dev Represents a reputation profile for a user.
     * reputationScore: The current integer score. Can be positive or negative.
     */
    struct Reputation {
        int256 score;
    }

    /**
     * @dev Represents an abstract condition that needs to be met.
     * conditionType: An identifier for the type of condition (e.g., 0 for "price check", 1 for "task completed").
     * parameters: Arbitrary bytes data specific to the condition type (e.g., token address, target price, task ID).
     * oracle: Address of the oracle responsible for resolving this condition type.
     * state: Current state of the condition (Created, Resolved, FailedResolution).
     * resolvedTimestamp: Timestamp when the condition was resolved.
     * result: Arbitrary bytes data provided by the oracle upon resolution.
     */
    struct Condition {
        uint8 conditionType;
        bytes parameters;
        address oracle; // Oracle assigned to resolve this specific condition instance or type
        ConditionState state;
        uint40 resolvedTimestamp;
        bytes result;
    }

    /**
     * @dev Represents a conditional action that can be executed once conditions are met.
     * actionType: An identifier for the type of action (e.g., 0 for "token transfer", 1 for "unlock feature").
     * parameters: Arbitrary bytes data specific to the action type (e.g., recipient, amount, feature ID).
     * creator: Address of the user who created the action.
     * requiredConditionIds: Array of condition IDs that must be resolved successfully.
     * timelockDuration: Duration in seconds after activation before fulfillment is possible.
     * activationTimestamp: Timestamp when the action became Active.
     * state: Current state of the action (Created, Active, ReadyToFulfill, Fulfilled, Cancelled).
     * totalCommitments: Counter for commitments made to this action.
     */
    struct ConditionalAction {
        uint8 actionType;
        bytes parameters;
        address creator;
        uint256[] requiredConditionIds;
        uint256 timelockDuration; // In seconds
        uint40 activationTimestamp;
        ActionState state;
        uint256 totalCommitments; // Count of commitments made to this action
    }

     /**
      * @dev Represents a user's commitment (reputation stake) to a conditional action.
      * actionId: The ID of the conditional action the user is committing to.
      * user: The address of the user making the commitment.
      * stakedReputation: The amount of reputation staked.
      * state: Current state of the commitment (Active, Withdrawn, Slashed).
      */
    struct Commitment {
        uint256 actionId;
        address user;
        uint256 stakedReputation;
        CommitmentState state;
    }

    // --- State Variables ---

    uint256 private _nextConditionId = 1;
    uint256 private _nextActionId = 1;
    uint256 private _nextCommitmentId = 1;

    // Mappings to store data by ID
    mapping(uint256 => Condition) public conditions;
    mapping(uint256 => ConditionalAction) public conditionalActions;
    mapping(uint256 => Commitment) public commitments;

    // Mapping to store user reputation
    mapping(address => Reputation) private _userReputation;

    // Mapping to link Condition Types to specific Oracle addresses
    mapping(uint8 => address) public conditionOracles;

    // Address of the Oracle responsible for general reputation updates (if separate)
    address public reputationOracle;

    // Minimum reputation required to create a Conditional Action
    uint256 public minReputationForActionCreation = 0;

    // Reputation amount required for a single Commitment to an action
    uint256 public commitmentReputationStakeAmount = 100; // Example default

    // Mapping to track commitment IDs per user (to get a count easily)
    mapping(address => uint256) private _userCommitmentCount;

    // --- Events ---

    event ReputationUpdated(address indexed user, int256 newScore, int256 change);
    event ConditionCreated(uint256 indexed conditionId, uint8 conditionType, address indexed oracle);
    event ConditionResolved(uint256 indexed conditionId, ConditionState newState, bytes result);
    event ConditionalActionCreated(uint256 indexed actionId, uint8 actionType, address indexed creator);
    event ConditionalActionActivated(uint256 indexed actionId, uint40 activationTimestamp);
    event ConditionalActionStateChanged(uint256 indexed actionId, ActionState newState);
    event ConditionalActionFulfilled(uint256 indexed actionId);
    event ConditionalActionCancelled(uint256 indexed actionId);
    event CommitmentMade(uint256 indexed commitmentId, uint256 indexed actionId, address indexed user, uint256 stakedReputation);
    event CommitmentStateChanged(uint256 indexed commitmentId, CommitmentState newState);
    event ConfigUpdated(string key, uint256 value); // Generic config update event

    // --- Modifiers ---

    modifier onlyConditionOracle(uint256 conditionId) {
        require(conditions[conditionId].oracle != address(0), "No oracle set for condition");
        require(msg.sender == conditions[conditionId].oracle, "Not authorized to resolve this condition");
        _;
    }

    modifier onlyReputationOracle() {
        require(msg.sender == reputationOracle || msg.sender == owner(), "Not reputation oracle or owner");
        _;
    }

    // --- Constructor ---

    constructor(address initialReputationOracle) Ownable(msg.sender) Pausable(false) {
        reputationOracle = initialReputationOracle;
    }

    // --- Ownership & Control Functions (from Ownable, Pausable) ---
    // Included via inheritance. Public functions:
    // transferOwnership(address newOwner)
    // renounceOwnership()
    // pause()
    // unpause()

    // --- Configuration Functions ---

    /**
     * @dev Sets the oracle address for a specific condition type. Only owner can call.
     * @param conditionType The type identifier of the condition.
     * @param oracle The address of the oracle contract/account.
     */
    function setConditionOracle(uint8 conditionType, address oracle) external onlyOwner {
        require(oracle != address(0), "Oracle address cannot be zero");
        conditionOracles[conditionType] = oracle;
    }

    /**
     * @dev Gets the oracle address for a specific condition type.
     * @param conditionType The type identifier of the condition.
     * @return The oracle address.
     */
    function getConditionOracle(uint8 conditionType) external view returns (address) {
        return conditionOracles[conditionType];
    }

    /**
     * @dev Sets the main reputation oracle address. Only owner can call.
     * @param oracle The address of the reputation oracle.
     */
    function setReputationOracle(address oracle) external onlyOwner {
        require(oracle != address(0), "Reputation oracle address cannot be zero");
        reputationOracle = oracle;
    }

    /**
     * @dev Sets the minimum reputation required to create a Conditional Action. Only owner can call.
     * @param amount The minimum reputation score.
     */
    function setMinimumReputationForActionCreation(uint256 amount) external onlyOwner {
        minReputationForActionCreation = amount;
        emit ConfigUpdated("minReputationForActionCreation", amount);
    }

     /**
     * @dev Sets the reputation amount required to make a single Commitment. Only owner can call.
     * @param amount The amount of reputation to stake per commitment.
     */
    function setCommitmentReputationStakeAmount(uint256 amount) external onlyOwner {
        commitmentReputationStakeAmount = amount;
        emit ConfigUpdated("commitmentReputationStakeAmount", amount);
    }


    // --- Reputation Management Functions ---

    /**
     * @dev Gets the reputation score for a user.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address user) public view returns (int256) {
        return _userReputation[user].score;
    }

    /**
     * @dev Internal helper to update a user's reputation score.
     * @param user The address of the user.
     * @param amount The amount to change the score by (can be positive or negative).
     */
    function _updateReputationScore(address user, int256 amount) internal {
        // Using unchecked for int256 add/sub as overflow/underflow is part of the design
        // for reputation systems (scores can go very high or very low).
        unchecked {
             _userReputation[user].score += amount;
        }
        emit ReputationUpdated(user, _userReputation[user].score, amount);
    }

    /**
     * @dev Increases a user's reputation score. Only Reputation Oracle or Owner can call.
     * @param user The address of the user.
     * @param amount The amount to increase the score by.
     */
    function increaseReputation(address user, uint256 amount) external onlyReputationOracle whenNotPaused {
        require(amount > 0, "Amount must be positive");
        _updateReputationScore(user, int256(amount));
    }

    /**
     * @dev Decreases a user's reputation score. Only Reputation Oracle or Owner can call.
     * @param user The address of the user.
     * @param amount The amount to decrease the score by.
     */
    function decreaseReputation(address user, uint256 amount) external onlyReputationOracle whenNotPaused {
        require(amount > 0, "Amount must be positive");
         _updateReputationScore(user, -int256(amount));
    }

    /**
     * @dev Slashes a user's reputation score (significant decrease, often due to negative action).
     * Only Reputation Oracle or Owner can call. Can also be called internally.
     * @param user The address of the user.
     * @param amount The amount to slash from the score.
     */
    function slashReputation(address user, uint256 amount) public onlyReputationOracle whenNotPaused {
        require(amount > 0, "Amount must be positive");
         _updateReputationScore(user, -int256(amount));
    }


    // --- Condition Management Functions ---

    /**
     * @dev Creates a new abstract condition that needs to be resolved.
     * Conditions must be created before being linked to an action.
     * Only an address assigned as an Oracle for that conditionType, or the owner, can create.
     * @param conditionType The type identifier of the condition.
     * @param parameters Arbitrary bytes data specific to the condition type.
     * @return The ID of the newly created condition.
     */
    function createCondition(uint8 conditionType, bytes calldata parameters) external onlyOwner whenNotPaused returns (uint256) {
        // Require an oracle to be set for this type before a condition of this type can be created.
        address oracleAddress = conditionOracles[conditionType];
        require(oracleAddress != address(0), "Oracle not set for this condition type");

        uint256 conditionId = _nextConditionId++;
        conditions[conditionId] = Condition({
            conditionType: conditionType,
            parameters: parameters,
            oracle: oracleAddress,
            state: ConditionState.Created,
            resolvedTimestamp: 0,
            result: "" // Empty result initially
        });

        emit ConditionCreated(conditionId, conditionType, oracleAddress);
        return conditionId;
    }

    /**
     * @dev Resolves a specific condition. Can only be called by the assigned oracle for that condition.
     * The oracle provides the resolution status (success based on external criteria) and result data.
     * @param conditionId The ID of the condition to resolve.
     * @param result Arbitrary bytes data representing the resolution result.
     * @param success True if the condition criteria were met, false otherwise.
     */
    function resolveCondition(uint256 conditionId, bytes calldata result, bool success)
        external
        onlyConditionOracle(conditionId)
        whenNotPaused
    {
        Condition storage condition = conditions[conditionId];
        require(condition.state == ConditionState.Created, "Condition already resolved or failed");

        condition.state = success ? ConditionState.Resolved : ConditionState.FailedResolution;
        condition.resolvedTimestamp = uint40(block.timestamp);
        condition.result = result;

        emit ConditionResolved(conditionId, condition.state, result);
    }

    /**
     * @dev Checks if a condition has been resolved successfully.
     * @param conditionId The ID of the condition.
     * @return True if the condition is in Resolved state, false otherwise.
     */
    function isConditionResolved(uint256 conditionId) public view returns (bool) {
        return conditions[conditionId].state == ConditionState.Resolved;
    }

     /**
     * @dev Gets the resolution result for a condition.
     * @param conditionId The ID of the condition.
     * @return The bytes result if resolved, or empty bytes.
     */
    function getConditionResult(uint256 conditionId) public view returns (bytes memory) {
        return conditions[conditionId].result;
    }


    // --- Conditional Action Management Functions ---

    /**
     * @dev Creates a new conditional action. Requires the creator to have minimum reputation.
     * @param actionType The type identifier of the action.
     * @param parameters Arbitrary bytes data specific to the action type.
     * @param requiredConditionIds Array of condition IDs that must be resolved successfully for this action.
     * @param timelockDuration The duration in seconds after activation before fulfillment is possible.
     * @return The ID of the newly created action.
     */
    function createConditionalAction(
        uint8 actionType,
        bytes calldata parameters,
        uint256[] calldata requiredConditionIds,
        uint256 timelockDuration
    ) external whenNotPaused returns (uint256) {
        require(getReputationScore(msg.sender) >= int256(minReputationForActionCreation), "Insufficient reputation to create action");
        require(timelockDuration > 0, "Timelock duration must be greater than 0");

        // Basic check: Ensure all required conditions exist. More complex checks (e.g., state) could be added.
        for (uint i = 0; i < requiredConditionIds.length; i++) {
            require(conditions[requiredConditionIds[i]].conditionType != 0 || requiredConditionIds[i] == 0, "Required condition does not exist"); // Check ID > 0 implicitly, and existence
        }

        uint256 actionId = _nextActionId++;
        conditionalActions[actionId] = ConditionalAction({
            actionType: actionType,
            parameters: parameters,
            creator: msg.sender,
            requiredConditionIds: requiredConditionIds,
            timelockDuration: timelockDuration,
            activationTimestamp: 0, // Not active yet
            state: ActionState.Created,
            totalCommitments: 0
        });

        emit ConditionalActionCreated(actionId, actionType, msg.sender);
        return actionId;
    }

    /**
     * @dev Activates a conditional action, starting its timelock. Only the creator can call.
     * @param actionId The ID of the action to activate.
     */
    function activateConditionalAction(uint256 actionId) external whenNotPaused {
        ConditionalAction storage action = conditionalActions[actionId];
        require(action.creator == msg.sender, "Only creator can activate");
        require(action.state == ActionState.Created, "Action is not in Created state");

        action.state = ActionState.Active;
        action.activationTimestamp = uint40(block.timestamp);

        emit ConditionalActionActivated(actionId, action.activationTimestamp);
        emit ConditionalActionStateChanged(actionId, ActionState.Active);
    }

    /**
     * @dev Checks if a conditional action is ready to be fulfilled.
     * Requires the action to be Active or ReadyToFulfill, all conditions to be Resolved,
     * and the timelock to have expired since activation.
     * @param actionId The ID of the action.
     * @return True if the action is ready for fulfillment, false otherwise.
     */
    function canFulfillConditionalAction(uint256 actionId) public view returns (bool) {
        ConditionalAction storage action = conditionalActions[actionId];

        if (action.state != ActionState.Active && action.state != ActionState.ReadyToFulfill) {
            return false;
        }

        // Check timelock
        if (action.activationTimestamp == 0 || block.timestamp < action.activationTimestamp + action.timelockDuration) {
            return false;
        }

        // Check all required conditions are resolved
        for (uint i = 0; i < action.requiredConditionIds.length; i++) {
            if (!isConditionResolved(action.requiredConditionIds[i])) {
                return false;
            }
        }

        // All checks passed
        return true;
    }

    /**
     * @dev Fulfills a conditional action, executing its core logic. Can be called by anyone
     * once `canFulfillConditionalAction` returns true.
     * Note: The actual action execution logic is a placeholder. This is where integration
     * with other contracts or logic based on actionType and parameters would happen.
     * Commitments associated with this action are set to Withdrawn state.
     * @param actionId The ID of the action to fulfill.
     */
    function fulfillConditionalAction(uint256 actionId) external whenNotPaused {
        ConditionalAction storage action = conditionalActions[actionId];
        require(action.state == ActionState.Active || action.state == ActionState.ReadyToFulfill, "Action not in Active or ReadyToFulfill state");
        require(canFulfillConditionalAction(actionId), "Action is not ready for fulfillment");

        // Transition state immediately to prevent re-entrancy or multiple fulfillments
        action.state = ActionState.Fulfilled;
        emit ConditionalActionStateChanged(actionId, ActionState.Fulfilled);
        emit ConditionalActionFulfilled(actionId);

        // --- Placeholder for actual action execution logic ---
        // This part would be highly application-specific.
        // Example: If actionType 1 is "TokenTransfer", logic here might call an ERC20 transfer.
        // bytes memory actionParameters = action.parameters;
        // require(executeAction(action.actionType, actionParameters), "Action execution failed");
        // For now, just a placeholder comment:
        // execute_action_logic(action.actionType, action.parameters);
        // -----------------------------------------------------

        // Automatically allow withdrawal of staked reputation for all commitments
        // associated with this action by changing their state.
        // We don't iterate commitments here due to potential gas limits.
        // The `withdrawCommitmentStake` function will check the action state.
    }

    /**
     * @dev Cancels a conditional action. Can be called by the creator (if not yet fulfilled)
     * or the owner (anytime, effectively an admin override).
     * Commitments associated with this action are set to Withdrawn state.
     * @param actionId The ID of the action to cancel.
     */
    function cancelConditionalAction(uint256 actionId) external whenNotPaused {
        ConditionalAction storage action = conditionalActions[actionId];
        require(action.state != ActionState.Fulfilled && action.state != ActionState.Cancelled, "Action cannot be cancelled from its current state");
        require(action.creator == msg.sender || owner() == msg.sender, "Only creator or owner can cancel");

        action.state = ActionState.Cancelled;
        emit ConditionalActionStateChanged(actionId, ActionState.Cancelled);

        // Automatically allow withdrawal of staked reputation for all commitments
        // associated with this action by changing their state.
        // The `withdrawCommitmentStake` function will check the action state.
    }

    // --- Commitment Management Functions ---

    /**
     * @dev User commits reputation to a conditional action.
     * Requires the action to be in Created or Active state.
     * Stakes the predefined `commitmentReputationStakeAmount` from the user's score.
     * @param actionId The ID of the conditional action to commit to.
     * @return The ID of the newly created commitment.
     */
    function commitToConditionalAction(uint256 actionId) external whenNotPaused returns (uint256) {
        ConditionalAction storage action = conditionalActions[actionId];
        require(action.state == ActionState.Created || action.state == ActionState.Active, "Action is not accepting commitments");
        require(getReputationScore(msg.sender) >= int256(commitmentReputationStakeAmount), "Insufficient reputation to commit");

        uint256 commitmentId = _nextCommitmentId++;

        commitments[commitmentId] = Commitment({
            actionId: actionId,
            user: msg.sender,
            stakedReputation: commitmentReputationStakeAmount, // Stake the configured amount
            state: CommitmentState.Active
        });

        // Decrease user's active reputation by the staked amount
        _updateReputationScore(msg.sender, -int256(commitmentReputationStakeAmount));

        action.totalCommitments++;
        _userCommitmentCount[msg.sender]++;

        emit CommitmentMade(commitmentId, actionId, msg.sender, commitmentReputationStakeAmount);
        return commitmentId;
    }

    /**
     * @dev Allows a user to withdraw their staked reputation from a commitment
     * if the associated action was successfully fulfilled or cancelled.
     * @param commitmentId The ID of the commitment.
     */
    function withdrawCommitmentStake(uint256 commitmentId) external whenNotPaused {
        Commitment storage commitment = commitments[commitmentId];
        require(commitment.state == CommitmentState.Active, "Commitment is not active");
        require(commitment.user == msg.sender, "Not your commitment");

        ConditionalAction storage action = conditionalActions[commitment.actionId];
        require(action.state == ActionState.Fulfilled || action.state == ActionState.Cancelled, "Action not yet fulfilled or cancelled");

        // Return the staked reputation
        _updateReputationScore(commitment.user, int256(commitment.stakedReputation));

        commitment.state = CommitmentState.Withdrawn;
        emit CommitmentStateChanged(commitmentId, CommitmentState.Withdrawn);
    }

    /**
     * @dev Slashes the staked reputation for a commitment. Can be called internally
     * (e.g., by a dispute resolution system) or by owner/oracle in specific cases.
     * Note: This function is exposed as `public` but intended for trusted callers.
     * @param commitmentId The ID of the commitment.
     */
    function slashCommitmentStake(uint256 commitmentId) public onlyReputationOracle whenNotPaused {
         Commitment storage commitment = commitments[commitmentId];
        require(commitment.state == CommitmentState.Active, "Commitment is not active");
        // Note: Reputation was already decreased when committing. Slashing means it's not returned.
        // If slashing involved *further* reduction, that logic would go here.
        // As designed, slashing means the *staked* amount is permanently lost.
        // The reduction already happened on commit, so we just change state.
        // If slashing meant losing *more* than the stake, we'd call _updateReputationScore again.

        commitment.state = CommitmentState.Slashed;
        emit CommitmentStateChanged(commitmentId, CommitmentState.Slashed);

        // Note: The staked reputation was already removed from the active score upon commitment.
        // No further score reduction is needed for this specific staking model on slash.
        // If the model was different (e.g., lock tokens not reputation score), this would change.
    }

    // --- Getter Functions ---

    /**
     * @dev Gets the details of a specific condition.
     * @param conditionId The ID of the condition.
     * @return Tuple containing condition details.
     */
    function getCondition(uint256 conditionId)
        external
        view
        returns (
            uint8 conditionType,
            bytes memory parameters,
            address oracle,
            ConditionState state,
            uint40 resolvedTimestamp,
            bytes memory result
        )
    {
        Condition storage c = conditions[conditionId];
        require(c.conditionType != 0 || conditionId == 0, "Condition does not exist"); // Basic existence check
        return (c.conditionType, c.parameters, c.oracle, c.state, c.resolvedTimestamp, c.result);
    }

    /**
     * @dev Gets the details of a specific conditional action.
     * @param actionId The ID of the action.
     * @return Tuple containing action details.
     */
    function getConditionalAction(uint256 actionId)
        external
        view
        returns (
            uint8 actionType,
            bytes memory parameters,
            address creator,
            uint256[] memory requiredConditionIds,
            uint256 timelockDuration,
            uint40 activationTimestamp,
            ActionState state,
            uint256 totalCommitments
        )
    {
        ConditionalAction storage a = conditionalActions[actionId];
         require(a.actionType != 0 || actionId == 0, "Action does not exist"); // Basic existence check
        return (
            a.actionType,
            a.parameters,
            a.creator,
            a.requiredConditionIds,
            a.timelockDuration,
            a.activationTimestamp,
            a.state,
            a.totalCommitments
        );
    }

    /**
     * @dev Gets the details of a specific commitment.
     * @param commitmentId The ID of the commitment.
     * @return Tuple containing commitment details.
     */
    function getCommitment(uint256 commitmentId)
         external
         view
         returns (
             uint256 actionId,
             address user,
             uint256 stakedReputation,
             CommitmentState state
         )
    {
        Commitment storage c = commitments[commitmentId];
        require(c.actionId != 0 || commitmentId == 0, "Commitment does not exist"); // Basic existence check
        return (c.actionId, c.user, c.stakedReputation, c.state);
    }

    /**
     * @dev Gets the current minimum reputation required to create an action.
     * @return The minimum reputation amount.
     */
    function getMinimumReputationForActionCreation() external view returns (uint256) {
        return minReputationForActionCreation;
    }

    /**
     * @dev Gets the current reputation amount required for a single commitment stake.
     * @return The commitment stake amount.
     */
     function getCommitmentReputationStakeAmount() external view returns (uint256) {
         return commitmentReputationStakeAmount;
     }

     /**
      * @dev Gets the total number of commitments made by a specific user.
      * Note: This doesn't return the commitment IDs themselves, only a count.
      * @param user The address of the user.
      * @return The total number of commitments.
      */
     function getUserCommitmentCount(address user) external view returns (uint256) {
         return _userCommitmentCount[user];
     }

     /**
      * @dev Gets the next available Condition ID.
      */
     function getNextConditionId() external view returns (uint256) {
         return _nextConditionId;
     }

     /**
      * @dev Gets the next available Action ID.
      */
     function getNextActionId() external view returns (uint256) {
         return _nextActionId;
     }

     /**
      * @dev Gets the next available Commitment ID.
      */
     function getNextCommitmentId() external view returns (uint256) {
         return _nextCommitmentId;
     }

    // --- Internal/Helper Functions ---
    // (_updateReputationScore is internal)

    // Note on action/condition execution:
    // The interpretation of `actionType`, `actionParameters`, `conditionType`, `conditionParameters`,
    // and `conditionResult` is outside the scope of this core contract framework.
    // A real implementation would likely involve:
    // 1. A registry of action/condition handler contracts.
    // 2. The `fulfillConditionalAction` function calling out to a handler contract
    //    based on `action.actionType` and passing `action.parameters`.
    // 3. Oracles resolving conditions by interpreting `condition.parameters` and
    //    reporting results via `resolveCondition`.
    // This design keeps the core state and logic management separate from the
    // potentially complex or varied execution logic.
}
```