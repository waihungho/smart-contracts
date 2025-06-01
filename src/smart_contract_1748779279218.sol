Okay, here is a concept for an advanced, complex, and rule-driven smart contract vault. It's designed not just to hold assets, but to release or act upon them based on combinations of on-chain conditions, external oracle data, and internal state variables, managed by different roles.

**Concept: QuantumVault**

A decentralized vault contract where access to assets (ETH, ERC20) and the ability to trigger actions are governed by highly configurable, composite rules. These rules can combine multiple conditions based on time, contract state, external oracle data, and even the result of calling view functions on other contracts. Different operator roles have granular permissions to define, manage, and execute these rules.

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports:** ERC20 Interface, Address Library
3.  **Error Definitions:** Custom errors for clearer failure reasons.
4.  **Event Definitions:** Log key actions (role changes, rule/condition/action definitions, rule execution attempts/results).
5.  **Enums:** Define roles, condition types, action types, logical operators.
6.  **Structs:** Define `Condition`, `Action`, and `Rule` structures.
7.  **State Variables:**
    *   Owner address.
    *   Mappings for operators and their roles.
    *   Counters for unique IDs for conditions, actions, rules.
    *   Mappings to store `Condition`, `Action`, and `Rule` definitions.
    *   Mapping to store generic internal state variables (`stateStorage`).
    *   Mapping to track activation status of rules.
8.  **Modifiers:** `onlyRole` modifier for access control.
9.  **Constructor:** Sets the initial owner/admin.
10. **Receive ETH Function:** Allows the contract to receive Ether.
11. **Operator Management Functions (Requires ADMIN role):**
    *   `addOperator`
    *   `removeOperator`
    *   `updateOperatorRole`
12. **Condition Management Functions (Requires CONDITION_MANAGER role):**
    *   `defineCondition`: Create a new condition definition.
    *   `updateCondition`: Modify an existing condition definition.
    *   `deleteCondition`: Remove a condition definition.
13. **Action Management Functions (Requires ACTION_MANAGER role):**
    *   `defineAction`: Create a new action definition.
    *   `updateAction`: Modify an existing action definition.
    *   `deleteAction`: Remove an action definition.
14. **Rule Management Functions (Requires RULE_MANAGER role):**
    *   `defineRule`: Create a new rule linking conditions and actions.
    *   `updateRule`: Modify an existing rule definition.
    *   `deleteRule`: Remove a rule definition.
    *   `activateRule`: Enable a rule for execution.
    *   `deactivateRule`: Disable a rule.
15. **State and Oracle Data Management Functions (Requires STATE_MANAGER or ORACLE_SUBMITTER role):**
    *   `updateStateValue`: Set a value in the internal `stateStorage`.
    *   `setOracleData`: Set specific state values reserved for oracle data (could be a specific key range or prefix).
16. **Asset Deposit Functions:**
    *   `depositERC20`: Receive ERC20 tokens (requires prior approval).
17. **Core Execution Function (Requires RULE_EXECUTOR role):**
    *   `executeRule`: Attempt to execute a rule's actions if its conditions are met.
18. **Internal Helper Functions:**
    *   `_checkCondition`: Evaluates a single condition definition against the current state/time/data.
    *   `_executeAction`: Performs a single action definition (transfer, call, etc.).
    *   `_checkRuleConditions`: Evaluates all conditions within a rule based on the rule's logic operator.
19. **Query Functions (View Functions):**
    *   `getOperatorRole`: Get the role of an address.
    *   `getCondition`: Get details of a condition definition.
    *   `getAction`: Get details of an action definition.
    *   `getRule`: Get details of a rule definition.
    *   `isRuleActive`: Check if a rule is active.
    *   `getVaultETHBalance`: Get contract's ETH balance.
    *   `getVaultERC20Balance`: Get contract's ERC20 balance for a specific token.
    *   `getStateValue`: Get a value from `stateStorage`.
    *   `checkConditionEvaluation`: Public function to test evaluation of a single condition (view only).
    *   `checkRuleConditionsEvaluation`: Public function to test evaluation of a rule's conditions (view only).

**Function Summary:**

1.  `constructor()`: Initializes the contract owner (ADMIN).
2.  `receive() external payable`: Allows direct ETH deposits.
3.  `addOperator(address operator, Role role)`: Assigns a role to an address.
4.  `removeOperator(address operator)`: Removes an operator's role.
5.  `updateOperatorRole(address operator, Role newRole)`: Changes an existing operator's role.
6.  `defineCondition(ConditionType conditionType, bytes data, uint256 comparisonValue, LogicOperator comparisonOperator)`: Creates a new condition definition. `data` stores type-specific parameters (e.g., time, state key, contract address + function signature).
7.  `updateCondition(uint256 conditionId, ConditionType conditionType, bytes data, uint256 comparisonValue, LogicOperator comparisonOperator)`: Updates an existing condition definition.
8.  `deleteCondition(uint256 conditionId)`: Deletes a condition definition.
9.  `defineAction(ActionType actionType, address target, uint256 value, bytes data, address tokenAddress)`: Creates a new action definition. `target`, `value`, `data`, `tokenAddress` are action-type specific parameters.
10. `updateAction(uint256 actionId, ActionType actionType, address target, uint256 value, bytes data, address tokenAddress)`: Updates an existing action definition.
11. `deleteAction(uint256 actionId)`: Deletes an action definition.
12. `defineRule(uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds)`: Creates a new rule linking a set of conditions (with logical AND/OR) to a set of actions.
13. `updateRule(uint256 ruleId, uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds)`: Updates an existing rule definition.
14. `deleteRule(uint256 ruleId)`: Deletes a rule definition.
15. `activateRule(uint256 ruleId)`: Enables a rule for execution.
16. `deactivateRule(uint256 ruleId)`: Disables a rule.
17. `updateStateValue(bytes32 key, uint256 value)`: Sets a value in the generic internal state storage.
18. `setOracleData(bytes32 key, uint256 value)`: Sets a value specifically designated for oracle data. (Could enforce `ORACLE_SUBMITTER` role).
19. `depositERC20(address token, uint256 amount)`: Transfers ERC20 tokens into the vault (requires caller to have approved the vault).
20. `executeRule(uint256 ruleId)`: Attempts to evaluate the conditions of an active rule and execute its actions if met.
21. `getOperatorRole(address operator) view returns (Role)`: Returns the role of an operator.
22. `getCondition(uint256 conditionId) view returns (ConditionType, bytes, uint256, LogicOperator)`: Retrieves condition details.
23. `getAction(uint256 actionId) view returns (ActionType, address, uint256, bytes, address)`: Retrieves action details.
24. `getRule(uint256 ruleId) view returns (uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds)`: Retrieves rule details.
25. `isRuleActive(uint256 ruleId) view returns (bool)`: Checks if a rule is active.
26. `getVaultETHBalance() view returns (uint256)`: Returns the contract's ETH balance.
27. `getVaultERC20Balance(address token) view returns (uint256)`: Returns the contract's balance for a specific ERC20 token.
28. `getStateValue(bytes32 key) view returns (uint256)`: Returns a value from the internal state storage.
29. `checkConditionEvaluation(uint256 conditionId) view returns (bool)`: Publicly checks if a single condition evaluates to true *currently*.
30. `checkRuleConditionsEvaluation(uint256 ruleId) view returns (bool)`: Publicly checks if a rule's *conditions* evaluate to true *currently*.

Let's write the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title QuantumVault
/// @author Your Name/Alias
/// @notice A complex, rule-driven vault contract managing assets and actions based on multi-conditional logic, internal state, and external data.
/// @dev This contract uses multiple roles, defined conditions, actions, and rules to control asset transfers and external interactions.
///      Conditions can be time-based, state-based, oracle-data-based, or based on external contract calls.
///      Rules combine conditions with AND/OR logic to trigger defined actions.

// --- Outline ---
// 1. SPDX License & Pragma
// 2. Imports (IERC20, Address)
// 3. Error Definitions
// 4. Event Definitions
// 5. Enums (Roles, Condition Types, Action Types, Logic Operators)
// 6. Structs (Condition, Action, Rule)
// 7. State Variables
// 8. Modifiers (onlyRole)
// 9. Constructor
// 10. Receive ETH Function
// 11. Operator Management Functions
// 12. Condition Management Functions
// 13. Action Management Functions
// 14. Rule Management Functions
// 15. State and Oracle Data Management Functions
// 16. Asset Deposit Functions
// 17. Core Execution Function (`executeRule`)
// 18. Internal Helper Functions (`_checkCondition`, `_executeAction`, `_checkRuleConditions`)
// 19. Query Functions (View Functions)

// --- Function Summary ---
// constructor(): Initializes the contract owner (ADMIN).
// receive(): Allows direct ETH deposits.
// addOperator(address operator, Role role): Assigns a role to an address (ADMIN).
// removeOperator(address operator): Removes an operator's role (ADMIN).
// updateOperatorRole(address operator, Role newRole): Changes an existing operator's role (ADMIN).
// defineCondition(ConditionType conditionType, bytes data, uint256 comparisonValue, LogicOperator comparisonOperator): Creates a new condition definition (CONDITION_MANAGER).
// updateCondition(uint256 conditionId, ConditionType conditionType, bytes data, uint256 comparisonValue, LogicOperator comparisonOperator): Updates an existing condition definition (CONDITION_MANAGER).
// deleteCondition(uint256 conditionId): Deletes a condition definition (CONDITION_MANAGER).
// defineAction(ActionType actionType, address target, uint256 value, bytes data, address tokenAddress): Creates a new action definition (ACTION_MANAGER).
// updateAction(uint256 actionId, ActionType actionType, address target, uint256 value, bytes data, address tokenAddress): Updates an existing action definition (ACTION_MANAGER).
// deleteAction(uint256 actionId): Deletes an action definition (ACTION_MANAGER).
// defineRule(uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds): Creates a new rule linking conditions and actions (RULE_MANAGER).
// updateRule(uint256 ruleId, uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds): Updates an existing rule definition (RULE_MANAGER).
// deleteRule(uint256 ruleId): Deletes a rule definition (RULE_MANAGER).
// activateRule(uint256 ruleId): Enables a rule for execution (RULE_MANAGER).
// deactivateRule(uint256 ruleId): Disables a rule (RULE_MANAGER).
// updateStateValue(bytes32 key, uint256 value): Sets a value in internal state storage (STATE_MANAGER).
// setOracleData(bytes32 key, uint256 value): Sets a value designated for oracle data (ORACLE_SUBMITTER).
// depositERC20(address token, uint256 amount): Deposits ERC20 tokens (Anyone with prior approval).
// executeRule(uint256 ruleId): Attempts to execute a rule if conditions are met (RULE_EXECUTOR).
// getOperatorRole(address operator) view returns (Role): Get role of an address (Anyone).
// getCondition(uint256 conditionId) view returns (ConditionType, bytes, uint256, LogicOperator): Retrieve condition details (Anyone).
// getAction(uint256 actionId) view returns (ActionType, address, uint256, bytes, address): Retrieve action details (Anyone).
// getRule(uint256 ruleId) view returns (uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds): Retrieve rule details (Anyone).
// isRuleActive(uint256 ruleId) view returns (bool): Check if a rule is active (Anyone).
// getVaultETHBalance() view returns (uint256): Get contract's ETH balance (Anyone).
// getVaultERC20Balance(address token) view returns (uint256): Get contract's ERC20 balance (Anyone).
// getStateValue(bytes32 key) view returns (uint256): Get a value from state storage (Anyone).
// checkConditionEvaluation(uint256 conditionId) view returns (bool): Publicly check evaluation of a single condition (Anyone).
// checkRuleConditionsEvaluation(uint256 ruleId) view returns (bool): Publicly check evaluation of a rule's conditions (Anyone).

contract QuantumVault {
    using Address for address;

    // --- Error Definitions ---
    error OnlyRole(Role requiredRole);
    error RoleAlreadyAssigned(address operator);
    error OperatorDoesNotExist(address operator);
    error OperatorHasRole();
    error InvalidConditionId(uint256 conditionId);
    error InvalidActionId(uint256 actionId);
    error InvalidRuleId(uint256 ruleId);
    error RuleNotActive(uint256 ruleId);
    error ConditionsNotMet(uint256 ruleId);
    error ETHTransferFailed(address target, uint256 amount);
    error ERC20TransferFailed(address token, address target, uint256 amount);
    error ExternalCallFailed(address target, bytes data);
    error ExternalCallConditionFailed(address target);
    error ERC20DepositFailed(address token, uint256 amount);
    error ConditionEvaluationError(uint256 conditionId, bytes message);
    error ActionExecutionError(uint256 actionId, bytes message);

    // --- Event Definitions ---
    event OperatorAdded(address indexed operator, Role indexed role);
    event OperatorRemoved(address indexed operator);
    event OperatorRoleUpdated(address indexed operator, Role indexed oldRole, Role indexed newRole);
    event ConditionDefined(uint256 indexed conditionId, ConditionType indexed conditionType, bytes data, uint256 comparisonValue, LogicOperator comparisonOperator);
    event ConditionUpdated(uint256 indexed conditionId, ConditionType indexed conditionType, bytes data, uint256 comparisonValue, LogicOperator comparisonOperator);
    event ConditionDeleted(uint256 indexed conditionId);
    event ActionDefined(uint256 indexed actionId, ActionType indexed actionType, address target, uint256 value, bytes data, address indexed tokenAddress);
    event ActionUpdated(uint256 indexed actionId, ActionType indexed actionType, address target, uint256 value, bytes data, address indexed tokenAddress);
    event ActionDeleted(uint256 indexed actionId);
    event RuleDefined(uint256 indexed ruleId, uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds);
    event RuleUpdated(uint256 indexed ruleId, uint256[] conditionIds, LogicOperator conditionsLogicOp, uint256[] actionIds);
    event RuleDeleted(uint256 indexed ruleId);
    event RuleActivated(uint256 indexed ruleId);
    event RuleDeactivated(uint256 indexed ruleId);
    event StateValueUpdated(bytes32 indexed key, uint256 value);
    event OracleDataUpdated(bytes32 indexed key, uint256 value);
    event ERC20Deposited(address indexed token, address indexed depositor, uint256 amount);
    event RuleExecutionAttempted(uint256 indexed ruleId, address indexed executor);
    event RuleExecutionSuccessful(uint256 indexed ruleId);
    event RuleExecutionFailed(uint56 indexed ruleId, bytes reason);
    event ConditionEvaluationResult(uint256 indexed conditionId, bool result);
    event ActionExecuted(uint256 indexed actionId, bool success, bytes resultData);

    // --- Enums ---
    enum Role {
        NONE,
        ADMIN,
        RULE_MANAGER,
        CONDITION_MANAGER,
        ACTION_MANAGER,
        STATE_MANAGER,
        ORACLE_SUBMITTER,
        RULE_EXECUTOR
    }

    enum ConditionType {
        NONE,
        TIME_BASED,          // data: N/A, comparisonValue: timestamp
        STATE_BASED,         // data: bytes32 key, comparisonValue: value
        ORACLE_BASED,        // data: bytes32 key, comparisonValue: value (Uses stateStorage, but semantic difference)
        VAULT_ETH_BALANCE,   // data: N/A, comparisonValue: balance
        VAULT_ERC20_BALANCE, // data: address token, comparisonValue: balance
        EXTERNAL_CALL_BOOL   // data: address target, function signature (bytes4), comparisonValue: N/A (expects bool return)
    }

    enum ActionType {
        NONE,
        TRANSFER_ETH,       // target: recipient, value: amount, data: N/A, tokenAddress: N/A
        TRANSFER_ERC20,     // target: recipient, value: amount, data: N/A, tokenAddress: token address
        CALL_CONTRACT,      // target: target contract, value: ETH value to send, data: call data, tokenAddress: N/A
        UPDATE_STATE        // target: N/A, value: value to set, data: bytes32 key, tokenAddress: N/A
    }

    enum LogicOperator {
        NONE,
        AND,
        OR,
        GREATER_THAN,         // For Conditions
        LESS_THAN,            // For Conditions
        EQUAL_TO              // For Conditions
    }

    // --- Structs ---
    struct Condition {
        ConditionType conditionType;
        bytes data;             // Type-specific data (e.g., bytes32 key, address)
        uint256 comparisonValue; // Value to compare against (e.g., timestamp, state value)
        LogicOperator comparisonOperator; // How to compare (>, <, ==)
        bool exists; // Flag to check if condition exists
    }

    struct Action {
        ActionType actionType;
        address target;         // Target address for transfer/call
        uint256 value;          // Amount for transfer, ETH value for call
        bytes data;             // Call data for CALL_CONTRACT, bytes32 key for UPDATE_STATE
        address tokenAddress;   // Token address for ERC20 actions
        bool exists; // Flag to check if action exists
    }

    struct Rule {
        uint256[] conditionIds;
        LogicOperator conditionsLogicOp; // AND or OR
        uint256[] actionIds;
        bool exists; // Flag to check if rule exists
    }

    // --- State Variables ---
    mapping(address => Role) private s_operators;
    address private s_owner; // ADMIN role is the initial owner

    uint256 private s_conditionCounter = 0;
    mapping(uint256 => Condition) private s_conditions;

    uint256 private s_actionCounter = 0;
    mapping(uint256 => Action) private s_actions;

    uint256 private s_ruleCounter = 0;
    mapping(uint256 => Rule) private s_rules;
    mapping(uint256 => bool) private s_ruleActive;

    mapping(bytes32 => uint256) private s_stateStorage; // Generic storage for state/oracle data

    // --- Modifiers ---
    modifier onlyRole(Role requiredRole) {
        if (s_operators[msg.sender] != requiredRole) {
            revert OnlyRole(requiredRole);
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        s_owner = msg.sender;
        s_operators[msg.sender] = Role.ADMIN;
        emit OperatorAdded(msg.sender, Role.ADMIN);
    }

    // --- Receive ETH Function ---
    receive() external payable {}

    // --- Operator Management Functions ---

    /// @notice Adds an operator with a specific role. Only ADMIN can call.
    /// @param operator The address to add as an operator.
    /// @param role The role to assign to the operator.
    function addOperator(address operator, Role role) external onlyRole(Role.ADMIN) {
        if (s_operators[operator] != Role.NONE) revert RoleAlreadyAssigned(operator);
        if (role == Role.NONE) revert OnlyRole(Role.ADMIN); // Cannot explicitly add NONE role
        s_operators[operator] = role;
        emit OperatorAdded(operator, role);
    }

    /// @notice Removes an operator's role. Only ADMIN can call.
    /// @param operator The address of the operator to remove.
    function removeOperator(address operator) external onlyRole(Role.ADMIN) {
        if (s_operators[operator] == Role.NONE) revert OperatorDoesNotExist(operator);
        if (s_operators[operator] == Role.ADMIN && operator == s_owner) revert OperatorHasRole(); // Cannot remove owner's ADMIN role this way
        Role oldRole = s_operators[operator];
        delete s_operators[operator];
        emit OperatorRemoved(operator);
        emit OperatorRoleUpdated(operator, oldRole, Role.NONE);
    }

    /// @notice Updates an existing operator's role. Only ADMIN can call.
    /// @param operator The address of the operator to update.
    /// @param newRole The new role to assign.
    function updateOperatorRole(address operator, Role newRole) external onlyRole(Role.ADMIN) {
        if (s_operators[operator] == Role.NONE) revert OperatorDoesNotExist(operator);
        if (s_operators[operator] == Role.ADMIN && operator == s_owner && newRole != Role.ADMIN) revert OperatorHasRole(); // Cannot downgrade owner's ADMIN role
        Role oldRole = s_operators[operator];
        s_operators[operator] = newRole;
        emit OperatorRoleUpdated(operator, oldRole, newRole);
    }

    // --- Condition Management Functions ---

    /// @notice Defines a new condition. Only CONDITION_MANAGER can call.
    /// @param conditionType The type of condition.
    /// @param data Type-specific parameters (e.g., bytes32 key, address).
    /// @param comparisonValue Value to compare against.
    /// @param comparisonOperator How to compare (>, <, ==).
    /// @return conditionId The ID of the newly defined condition.
    function defineCondition(
        ConditionType conditionType,
        bytes data,
        uint256 comparisonValue,
        LogicOperator comparisonOperator
    ) external onlyRole(Role.CONDITION_MANAGER) returns (uint256) {
        uint256 newId = ++s_conditionCounter;
        s_conditions[newId] = Condition({
            conditionType: conditionType,
            data: data,
            comparisonValue: comparisonValue,
            comparisonOperator: comparisonOperator,
            exists: true
        });
        emit ConditionDefined(newId, conditionType, data, comparisonValue, comparisonOperator);
        return newId;
    }

    /// @notice Updates an existing condition. Only CONDITION_MANAGER can call.
    /// @param conditionId The ID of the condition to update.
    /// @param conditionType The updated type of condition.
    /// @param data Updated type-specific parameters.
    /// @param comparisonValue Updated value to compare against.
    /// @param comparisonOperator Updated comparison method.
    function updateCondition(
        uint256 conditionId,
        ConditionType conditionType,
        bytes data,
        uint256 comparisonValue,
        LogicOperator comparisonOperator
    ) external onlyRole(Role.CONDITION_MANAGER) {
        if (!s_conditions[conditionId].exists) revert InvalidConditionId(conditionId);
        s_conditions[conditionId] = Condition({
            conditionType: conditionType,
            data: data,
            comparisonValue: comparisonValue,
            comparisonOperator: comparisonOperator,
            exists: true
        });
        emit ConditionUpdated(conditionId, conditionType, data, comparisonValue, comparisonOperator);
    }

    /// @notice Deletes a condition. Only CONDITION_MANAGER can call.
    /// @param conditionId The ID of the condition to delete.
    /// @dev Deleting a condition does not invalidate rules that reference it, but `executeRule` will revert if it encounters a non-existent condition ID.
    function deleteCondition(uint256 conditionId) external onlyRole(Role.CONDITION_MANAGER) {
        if (!s_conditions[conditionId].exists) revert InvalidConditionId(conditionId);
        delete s_conditions[conditionId]; // Sets 'exists' to false
        emit ConditionDeleted(conditionId);
    }

    // --- Action Management Functions ---

    /// @notice Defines a new action. Only ACTION_MANAGER can call.
    /// @param actionType The type of action.
    /// @param target Target address for transfer/call.
    /// @param value Amount for transfer, ETH value for call.
    /// @param data Call data for CALL_CONTRACT, bytes32 key for UPDATE_STATE.
    /// @param tokenAddress Token address for ERC20 actions.
    /// @return actionId The ID of the newly defined action.
    function defineAction(
        ActionType actionType,
        address target,
        uint256 value,
        bytes data,
        address tokenAddress
    ) external onlyRole(Role.ACTION_MANAGER) returns (uint256) {
        uint256 newId = ++s_actionCounter;
        s_actions[newId] = Action({
            actionType: actionType,
            target: target,
            value: value,
            data: data,
            tokenAddress: tokenAddress,
            exists: true
        });
        emit ActionDefined(newId, actionType, target, value, data, tokenAddress);
        return newId;
    }

    /// @notice Updates an existing action. Only ACTION_MANAGER can call.
    /// @param actionId The ID of the action to update.
    /// @param actionType Updated type of action.
    /// @param target Updated target address.
    /// @param value Updated value.
    /// @param data Updated data.
    /// @param tokenAddress Updated token address.
    function updateAction(
        uint256 actionId,
        ActionType actionType,
        address target,
        uint256 value,
        bytes data,
        address tokenAddress
    ) external onlyRole(Role.ACTION_MANAGER) {
        if (!s_actions[actionId].exists) revert InvalidActionId(actionId);
        s_actions[actionId] = Action({
            actionType: actionType,
            target: target,
            value: value,
            data: data,
            tokenAddress: tokenAddress,
            exists: true
        });
        emit ActionUpdated(actionId, actionType, target, value, data, tokenAddress);
    }

    /// @notice Deletes an action. Only ACTION_MANAGER can call.
    /// @param actionId The ID of the action to delete.
    /// @dev Deleting an action does not invalidate rules that reference it, but `executeRule` will revert if it encounters a non-existent action ID.
    function deleteAction(uint256 actionId) external onlyRole(Role.ACTION_MANAGER) {
        if (!s_actions[actionId].exists) revert InvalidActionId(actionId);
        delete s_actions[actionId]; // Sets 'exists' to false
        emit ActionDeleted(actionId);
    }

    // --- Rule Management Functions ---

    /// @notice Defines a new rule linking conditions and actions. Only RULE_MANAGER can call.
    /// @param conditionIds An array of condition IDs.
    /// @param conditionsLogicOp The logical operator (AND or OR) for combining condition results.
    /// @param actionIds An array of action IDs to execute if conditions are met.
    /// @return ruleId The ID of the newly defined rule.
    function defineRule(
        uint256[] memory conditionIds,
        LogicOperator conditionsLogicOp,
        uint256[] memory actionIds
    ) external onlyRole(Role.RULE_MANAGER) returns (uint256) {
        // Basic validation: check if IDs exist
        for (uint256 i = 0; i < conditionIds.length; i++) {
            if (!s_conditions[conditionIds[i]].exists) revert InvalidConditionId(conditionIds[i]);
        }
        for (uint256 i = 0; i < actionIds.length; i++) {
            if (!s_actions[actionIds[i]].exists) revert InvalidActionId(actionIds[i]);
        }

        uint256 newId = ++s_ruleCounter;
        s_rules[newId] = Rule({
            conditionIds: conditionIds,
            conditionsLogicOp: conditionsLogicOp,
            actionIds: actionIds,
            exists: true
        });
        s_ruleActive[newId] = false; // Rules start inactive
        emit RuleDefined(newId, conditionIds, conditionsLogicOp, actionIds);
        return newId;
    }

    /// @notice Updates an existing rule. Only RULE_MANAGER can call.
    /// @param ruleId The ID of the rule to update.
    /// @param conditionIds Updated array of condition IDs.
    /// @param conditionsLogicOp Updated logical operator.
    /// @param actionIds Updated array of action IDs.
    function updateRule(
        uint256 ruleId,
        uint256[] memory conditionIds,
        LogicOperator conditionsLogicOp,
        uint256[] memory actionIds
    ) external onlyRole(Role.RULE_MANAGER) {
        if (!s_rules[ruleId].exists) revert InvalidRuleId(ruleId);

        // Basic validation: check if updated IDs exist
        for (uint256 i = 0; i < conditionIds.length; i++) {
            if (!s_conditions[conditionIds[i]].exists) revert InvalidConditionId(conditionIds[i]);
        }
        for (uint256 i = 0; i < actionIds.length; i++) {
            if (!s_actions[actionIds[i]].exists) revert InvalidActionId(actionIds[i]);
        }

        s_rules[ruleId] = Rule({
            conditionIds: conditionIds,
            conditionsLogicOp: conditionsLogicOp,
            actionIds: actionIds,
            exists: true
        });
        // Activation status remains unchanged on update
        emit RuleUpdated(ruleId, conditionIds, conditionsLogicOp, actionIds);
    }

    /// @notice Deletes a rule. Only RULE_MANAGER can call.
    /// @param ruleId The ID of the rule to delete.
    function deleteRule(uint256 ruleId) external onlyRole(Role.RULE_MANAGER) {
        if (!s_rules[ruleId].exists) revert InvalidRuleId(ruleId);
        delete s_rules[ruleId]; // Sets 'exists' to false
        delete s_ruleActive[ruleId];
        emit RuleDeleted(ruleId);
    }

    /// @notice Activates a rule, making it eligible for execution. Only RULE_MANAGER can call.
    /// @param ruleId The ID of the rule to activate.
    function activateRule(uint256 ruleId) external onlyRole(Role.RULE_MANAGER) {
        if (!s_rules[ruleId].exists) revert InvalidRuleId(ruleId);
        s_ruleActive[ruleId] = true;
        emit RuleActivated(ruleId);
    }

    /// @notice Deactivates a rule, preventing it from being executed. Only RULE_MANAGER can call.
    /// @param ruleId The ID of the rule to deactivate.
    function deactivateRule(uint256 ruleId) external onlyRole(Role.RULE_MANAGER) {
        if (!s_rules[ruleId].exists) revert InvalidRuleId(ruleId);
        s_ruleActive[ruleId] = false;
        emit RuleDeactivated(ruleId);
    }

    // --- State and Oracle Data Management Functions ---

    /// @notice Updates a value in the internal state storage. Used for STATE_BASED conditions. Only STATE_MANAGER can call.
    /// @param key The bytes32 key for the state variable.
    /// @param value The uint256 value to set.
    function updateStateValue(bytes32 key, uint256 value) external onlyRole(Role.STATE_MANAGER) {
        s_stateStorage[key] = value;
        emit StateValueUpdated(key, value);
    }

    /// @notice Sets a value designated as oracle data. Used for ORACLE_BASED conditions. Only ORACLE_SUBMITTER can call.
    /// @param key The bytes32 key for the oracle data.
    /// @param value The uint256 value to set.
    function setOracleData(bytes32 key, uint256 value) external onlyRole(Role.ORACLE_SUBMITTER) {
        // Could add checks here to distinguish oracle keys from general state keys if needed
        s_stateStorage[key] = value;
        emit OracleDataUpdated(key, value);
    }

    // --- Asset Deposit Functions ---

    /// @notice Allows users to deposit ERC20 tokens into the vault. Requires prior ERC20 approval.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) external {
        IERC20 erc20 = IERC20(token);
        bool success = erc20.transferFrom(msg.sender, address(this), amount);
        if (!success) revert ERC20DepositFailed(token, amount);
        emit ERC20Deposited(token, msg.sender, amount);
    }

    // --- Core Execution Function ---

    /// @notice Attempts to execute a rule's actions if its conditions are met and the rule is active. Only RULE_EXECUTOR can call.
    /// @param ruleId The ID of the rule to execute.
    function executeRule(uint256 ruleId) external onlyRole(Role.RULE_EXECUTOR) {
        emit RuleExecutionAttempted(ruleId, msg.sender);

        if (!s_rules[ruleId].exists) revert InvalidRuleId(ruleId);
        if (!s_ruleActive[ruleId]) revert RuleNotActive(ruleId);

        Rule storage rule = s_rules[ruleId];

        // Check conditions
        bool conditionsMet = _checkRuleConditions(rule.conditionIds, rule.conditionsLogicOp);

        if (!conditionsMet) {
            revert ConditionsNotMet(ruleId);
        }

        // Execute actions if conditions are met
        bool allActionsSuccessful = true;
        for (uint256 i = 0; i < rule.actionIds.length; i++) {
            uint256 actionId = rule.actionIds[i];
            if (!s_actions[actionId].exists) {
                // If an action definition is missing, the rule cannot be fully executed.
                // Decide on behavior: revert the whole rule execution or skip the action?
                // Reverting is safer to prevent partial execution based on potentially invalid definitions.
                revert InvalidActionId(actionId);
            }
            Action storage action = s_actions[actionId];
            (bool success, bytes memory resultData) = _executeAction(actionId, action);

            if (!success) {
                allActionsSuccessful = false;
                // Decide on behavior: continue executing other actions or revert the whole rule execution?
                // For safety and atomicity, reverting the whole rule execution on any action failure is often preferable.
                // If atomic execution of ALL actions is required, uncomment the following line:
                 revert ActionExecutionError(actionId, resultData);
                // If non-atomic execution (try all, log failures) is acceptable, remove the above revert.
            }
        }

        if (allActionsSuccessful) {
            emit RuleExecutionSuccessful(ruleId);
        } else {
            // This branch is only reachable if we chose non-atomic execution above
             emit RuleExecutionFailed(ruleId, "Some actions failed");
        }
    }

    // --- Internal Helper Functions ---

    /// @dev Evaluates a single condition definition. Internal function.
    /// @param conditionId The ID of the condition to evaluate.
    /// @param condition The Condition struct.
    /// @return bool True if the condition is met, false otherwise.
    function _checkCondition(uint256 conditionId, Condition storage condition) internal returns (bool) {
        if (!condition.exists) revert InvalidConditionId(conditionId); // Should not happen if called from executeRule

        uint256 currentValue;
        bool externalBoolResult;

        try {
            if (condition.conditionType == ConditionType.TIME_BASED) {
                currentValue = block.timestamp;
            } else if (condition.conditionType == ConditionType.STATE_BASED || condition.conditionType == ConditionType.ORACLE_BASED) {
                bytes32 key = abi.decode(condition.data, (bytes32));
                currentValue = s_stateStorage[key];
            } else if (condition.conditionType == ConditionType.VAULT_ETH_BALANCE) {
                currentValue = address(this).balance;
            } else if (condition.conditionType == ConditionType.VAULT_ERC20_BALANCE) {
                address token = abi.decode(condition.data, (address));
                currentValue = IERC20(token).balanceOf(address(this));
            } else if (condition.conditionType == ConditionType.EXTERNAL_CALL_BOOL) {
                 (address target, bytes4 funcSig) = abi.decode(condition.data, (address, bytes4));
                 (bool success, bytes memory returndata) = target.staticcall(abi.encodeWithSelector(funcSig));
                 if (!success) revert ExternalCallConditionFailed(target);
                 externalBoolResult = abi.decode(returndata, (bool));
                 emit ConditionEvaluationResult(conditionId, externalBoolResult);
                 return externalBoolResult; // EXTERNAL_CALL_BOOL directly returns a bool
            } else {
                revert ConditionEvaluationError(conditionId, "Unknown condition type");
            }
        } catch Error(string memory reason) {
            revert ConditionEvaluationError(conditionId, bytes(reason));
        } catch Panic(uint errorCode) {
            revert ConditionEvaluationError(conditionId, abi.encodeWithUint(errorCode));
        } catch {
             revert ConditionEvaluationError(conditionId, "Unexpected failure during evaluation");
        }


        // For non-boolean conditions, compare currentValue with comparisonValue
        bool result;
        if (condition.comparisonOperator == LogicOperator.GREATER_THAN) {
            result = currentValue > condition.comparisonValue;
        } else if (condition.comparisonOperator == LogicOperator.LESS_THAN) {
            result = currentValue < condition.comparisonValue;
        } else if (condition.comparisonOperator == LogicOperator.EQUAL_TO) {
            result = currentValue == condition.comparisonValue;
        } else {
             revert ConditionEvaluationError(conditionId, "Unknown comparison operator");
        }

        emit ConditionEvaluationResult(conditionId, result);
        return result;
    }

    /// @dev Evaluates all conditions within a rule based on the rule's logical operator. Internal function.
    /// @param conditionIds The array of condition IDs in the rule.
    /// @param conditionsLogicOp The logical operator (AND or OR).
    /// @return bool True if the combined conditions are met, false otherwise.
    function _checkRuleConditions(uint256[] memory conditionIds, LogicOperator conditionsLogicOp) internal returns (bool) {
        if (conditionIds.length == 0) return true; // No conditions means conditions are met

        if (conditionsLogicOp == LogicOperator.AND) {
            for (uint256 i = 0; i < conditionIds.length; i++) {
                uint256 condId = conditionIds[i];
                if (!s_conditions[condId].exists) revert InvalidConditionId(condId); // Ensure condition exists
                if (!_checkCondition(condId, s_conditions[condId])) {
                    return false; // If any condition is false for AND, the result is false
                }
            }
            return true; // If all conditions were true for AND, the result is true
        } else if (conditionsLogicOp == LogicOperator.OR) {
             for (uint256 i = 0; i < conditionIds.length; i++) {
                uint256 condId = conditionIds[i];
                 if (!s_conditions[condId].exists) revert InvalidConditionId(condId); // Ensure condition exists
                 if (_checkCondition(condId, s_conditions[condId])) {
                     return true; // If any condition is true for OR, the result is true
                 }
             }
             return false; // If all conditions were false for OR, the result is false
        } else {
             revert ConditionEvaluationError(0, "Invalid rule logic operator"); // Use 0 for rule-level error
        }
    }


    /// @dev Executes a single action definition. Internal function.
    /// @param actionId The ID of the action being executed.
    /// @param action The Action struct.
    /// @return success True if the action executed without error.
    /// @return resultData Raw result data from the action (e.g., from a low-level call).
    function _executeAction(uint256 actionId, Action storage action) internal returns (bool success, bytes memory resultData) {
         if (!action.exists) revert InvalidActionId(actionId); // Should not happen if called from executeRule

        try {
            if (action.actionType == ActionType.TRANSFER_ETH) {
                (success, resultData) = payable(action.target).call{value: action.value}("");
                if (!success) revert ETHTransferFailed(action.target, action.value);
            } else if (action.actionType == ActionType.TRANSFER_ERC20) {
                IERC20 token = IERC20(action.tokenAddress);
                success = token.transfer(action.target, action.value);
                // ERC20 standards pre-date `require` on return, so some tokens might return false instead of reverting.
                // Checking `success` is still needed for older tokens or non-standard ones.
                if (!success) revert ERC20TransferFailed(action.tokenAddress, action.target, action.value);
                resultData = ""; // No specific result data for standard ERC20 transfer
            } else if (action.actionType == ActionType.CALL_CONTRACT) {
                 // WARNING: Low-level calls are powerful and potentially risky. Ensure target and data are vetted.
                (success, resultData) = action.target.call{value: action.value}(action.data);
                if (!success) revert ExternalCallFailed(action.target, action.data);
            } else if (action.actionType == ActionType.UPDATE_STATE) {
                bytes32 key = abi.decode(action.data, (bytes32));
                s_stateStorage[key] = action.value;
                success = true;
                resultData = ""; // No specific result data for state update
                 emit StateValueUpdated(key, action.value); // Re-emit state update event for traceability via action execution
            } else {
                 revert ActionExecutionError(actionId, "Unknown action type");
            }

            emit ActionExecuted(actionId, success, resultData);
            return (success, resultData);

        } catch Error(string memory reason) {
            emit ActionExecuted(actionId, false, bytes(reason));
            return (false, bytes(reason));
        } catch Panic(uint errorCode) {
            emit ActionExecuted(actionId, false, abi.encodeWithUint(errorCode));
            return (false, abi.encodeWithUint(errorCode));
        } catch (bytes memory reason) {
             // Catch generic call failures with revert reasons
             emit ActionExecuted(actionId, false, reason);
             return (false, reason);
        }
    }


    // --- Query Functions (View Functions) ---

    /// @notice Returns the role assigned to an address.
    /// @param operator The address to check.
    /// @return The Role enum value.
    function getOperatorRole(address operator) external view returns (Role) {
        return s_operators[operator];
    }

    /// @notice Retrieves the definition of a condition.
    /// @param conditionId The ID of the condition.
    /// @return conditionType, data, comparisonValue, comparisonOperator, exists
    function getCondition(uint256 conditionId) external view returns (ConditionType conditionType, bytes memory data, uint256 comparisonValue, LogicOperator comparisonOperator, bool exists) {
        Condition storage cond = s_conditions[conditionId];
        return (cond.conditionType, cond.data, cond.comparisonValue, cond.comparisonOperator, cond.exists);
    }

    /// @notice Retrieves the definition of an action.
    /// @param actionId The ID of the action.
    /// @return actionType, target, value, data, tokenAddress, exists
    function getAction(uint256 actionId) external view returns (ActionType actionType, address target, uint256 value, bytes memory data, address tokenAddress, bool exists) {
        Action storage act = s_actions[actionId];
        return (act.actionType, act.target, act.value, act.data, act.tokenAddress, act.exists);
    }

    /// @notice Retrieves the definition of a rule.
    /// @param ruleId The ID of the rule.
    /// @return conditionIds, conditionsLogicOp, actionIds, exists
    function getRule(uint256 ruleId) external view returns (uint256[] memory conditionIds, LogicOperator conditionsLogicOp, uint256[] memory actionIds, bool exists) {
        Rule storage rule = s_rules[ruleId];
        return (rule.conditionIds, rule.conditionsLogicOp, rule.actionIds, rule.exists);
    }

    /// @notice Checks if a rule is currently active.
    /// @param ruleId The ID of the rule.
    /// @return bool True if the rule is active, false otherwise.
    function isRuleActive(uint256 ruleId) external view returns (bool) {
        if (!s_rules[ruleId].exists) return false;
        return s_ruleActive[ruleId];
    }

    /// @notice Returns the current ETH balance of the vault contract.
    /// @return uint256 The ETH balance.
    function getVaultETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the current balance of a specific ERC20 token held by the vault.
    /// @param token The address of the ERC20 token.
    /// @return uint256 The token balance.
    function getVaultERC20Balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @notice Returns a value from the internal state storage.
    /// @param key The bytes32 key.
    /// @return uint256 The stored value.
    function getStateValue(bytes32 key) external view returns (uint256) {
        return s_stateStorage[key];
    }

    /// @notice Publicly checks the evaluation of a single condition *without* needing a specific role.
    /// @dev This is a read-only view function. It does not execute any actions or change state.
    /// @param conditionId The ID of the condition to evaluate.
    /// @return bool True if the condition evaluates to true based on the current state, false otherwise.
    function checkConditionEvaluation(uint256 conditionId) external view returns (bool) {
        if (!s_conditions[conditionId].exists) revert InvalidConditionId(conditionId);
        // Temporarily cast view function to internal to call _checkCondition
        // Note: _checkCondition uses storage references, which is not allowed in view functions directly if it modified state.
        // However, _checkCondition only *reads* state. We must be careful if _checkCondition were to interact with non-view external calls.
        // For EXTERNAL_CALL_BOOL condition, we must ensure the target contract's function is also view/pure/staticcall compatible.
        // Solidity's `view` context means `staticcall` is used, which enforces this.
        // A non-view internal function cannot be called directly from a view external function, so we need a separate view helper.
        return _checkConditionView(conditionId, s_conditions[conditionId]);
    }

     /// @dev View helper function to evaluate a single condition. Safe for view context.
     /// @param conditionId The ID of the condition to evaluate.
     /// @param condition The Condition struct.
     /// @return bool True if the condition is met, false otherwise.
     function _checkConditionView(uint256 conditionId, Condition storage condition) internal view returns (bool) {
         if (!condition.exists) revert InvalidConditionId(conditionId);

         uint256 currentValue;
         bool externalBoolResult;

         // Minimal error handling for view context
         if (condition.conditionType == ConditionType.TIME_BASED) {
             currentValue = block.timestamp;
         } else if (condition.conditionType == ConditionType.STATE_BASED || condition.conditionType == ConditionType.ORACLE_BASED) {
             bytes32 key = abi.decode(condition.data, (bytes32));
             currentValue = s_stateStorage[key];
         } else if (condition.conditionType == ConditionType.VAULT_ETH_BALANCE) {
             currentValue = address(this).balance;
         } else if (condition.conditionType == ConditionType.VAULT_ERC20_BALANCE) {
             address token = abi.decode(condition.data, (address));
             currentValue = IERC20(token).balanceOf(address(this));
         } else if (condition.conditionType == ConditionType.EXTERNAL_CALL_BOOL) {
              (address target, bytes4 funcSig) = abi.decode(condition.data, (address, bytes4));
              (bool success, bytes memory returndata) = target.staticcall(abi.encodeWithSelector(funcSig));
              // In a view function, we can't revert with custom errors based on external call failure data easily.
              // Just returning false on external call failure or invalid return is the safest approach for a view.
              if (!success || returndata.length != 32) return false; // Check success and expect boolean return size (32 bytes)
              try {
                 externalBoolResult = abi.decode(returndata, (bool));
                 return externalBoolResult;
              } catch {
                 return false; // Handle decoding errors gracefully in view context
              }
         } else {
             // Unknown type
             return false; // Or revert with a generic error
         }

         // For non-boolean conditions, compare currentValue with comparisonValue
         if (condition.comparisonOperator == LogicOperator.GREATER_THAN) {
             return currentValue > condition.comparisonValue;
         } else if (condition.comparisonOperator == LogicOperator.LESS_THAN) {
             return currentValue < condition.comparisonValue;
         } else if (condition.comparisonOperator == LogicOperator.EQUAL_TO) {
             return currentValue == condition.comparisonValue;
         } else {
             // Unknown comparison operator
             return false; // Or revert
         }
     }


    /// @notice Publicly checks the evaluation of a rule's conditions *without* needing a specific role.
    /// @dev This is a read-only view function. It does not execute any actions or change state.
    /// @param ruleId The ID of the rule whose conditions to evaluate.
    /// @return bool True if the rule's conditions currently evaluate to true, false otherwise.
    function checkRuleConditionsEvaluation(uint256 ruleId) external view returns (bool) {
         if (!s_rules[ruleId].exists) revert InvalidRuleId(ruleId);
         Rule storage rule = s_rules[ruleId];

         if (rule.conditionIds.length == 0) return true; // No conditions means conditions are met

         if (rule.conditionsLogicOp == LogicOperator.AND) {
             for (uint256 i = 0; i < rule.conditionIds.length; i++) {
                 uint256 condId = rule.conditionIds[i];
                 if (!s_conditions[condId].exists) revert InvalidConditionId(condId); // Ensure condition exists
                 if (!_checkConditionView(condId, s_conditions[condId])) {
                     return false; // If any condition is false for AND, the result is false
                 }
             }
             return true; // If all conditions were true for AND, the result is true
         } else if (rule.conditionsLogicOp == LogicOperator.OR) {
              for (uint256 i = 0; i < rule.conditionIds.length; i++) {
                 uint256 condId = rule.conditionIds[i];
                  if (!s_conditions[condId].exists) revert InvalidConditionId(condId); // Ensure condition exists
                  if (_checkConditionView(condId, s_conditions[condId])) {
                      return true; // If any condition is true for OR, the result is true
                  }
              }
              return false; // If all conditions were false for OR, the result is false
         } else {
              revert ConditionEvaluationError(0, "Invalid rule logic operator for view check");
         }
    }
}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Rule-Driven Execution:** The core idea is that the vault's behavior isn't hardcoded into simple functions like `withdraw()` but is dictated by dynamic `Rule` definitions. This allows for highly flexible and complex access control or automation scenarios.
2.  **Composite Conditions:** Conditions aren't just single checks (like a time lock). They are building blocks (`Condition` structs) that can be combined with `AND` or `OR` logic within a `Rule`. This enables scenarios like "release funds if Bob requests *AND* the price feed is above X *OR* it's after Y date".
3.  **Diverse Condition Types:**
    *   `TIME_BASED`: Standard timelock functionality.
    *   `STATE_BASED` / `ORACLE_BASED`: Allows conditions to depend on data written to the contract's storage by authorized parties (State Manager, Oracle Submitter). This decouples the condition logic from the data source update mechanism.
    *   `VAULT_BALANCE_BASED`: Conditions based on the vault's own asset holdings.
    *   `EXTERNAL_CALL_BOOL`: *Advanced*. Allows the condition check to call a `view` function on *another* contract and use its boolean return value as part of the condition. This could link vault actions to the state of other protocols (e.g., check if a user has staked in Protocol X, check a governance vote result, check a game state).
4.  **Configurable Actions:** Actions are also defined separately and linked to rules. This means a rule can trigger multiple distinct actions atomically (or non-atomically, based on implementation choice in `executeRule`). Actions can be simple transfers or complex external contract calls.
5.  **Granular Role-Based Access Control:** Instead of a single owner or multisig, different addresses can be assigned specific roles (`ADMIN`, `RULE_MANAGER`, `CONDITION_MANAGER`, `ACTION_MANAGER`, `STATE_MANAGER`, `ORACLE_SUBMITTER`, `RULE_EXECUTOR`). This allows separation of concerns and distributed management of the vault's logic and data.
6.  **Dynamic Logic Updates:** Rules, conditions, and actions can be updated or deleted by their respective managers (though care must be taken not to break active rules referencing deleted items – the current code implements a safety check/revert during `executeRule`). Rules can also be activated/deactivated. This offers flexibility for evolving logic without deploying new contracts (limited by contract size).
7.  **Internal State Management (`s_stateStorage`):** Provides a simple key-value store within the vault itself that conditions can read from and actions can write to (`UPDATE_STATE`). This allows the vault to maintain its own internal state or process data submitted by authorized roles.
8.  **Public View Functions for Logic Preview:** `checkConditionEvaluation` and `checkRuleConditionsEvaluation` allow anyone to test if conditions for a given ID are *currently* met without needing execution permission or potentially wasting gas on a failed `executeRule` transaction. This adds transparency and usability.
9.  **Extensibility:** The use of enums and bytes `data` allows adding new `ConditionType` or `ActionType` logic in future contract versions (if upgradeability is added) or via derived contracts, without changing the core rule structure.

This contract goes significantly beyond standard vaults, time locks, or multi-sigs by making the *logic itself* a first-class, configurable, and multi-party managed component. It could be used for complex vesting schedules tied to project milestones (oracle data), decentralized insurance payouts triggered by external state or data feeds, automated treasury management based on protocol metrics, or complex multi-party escrows.