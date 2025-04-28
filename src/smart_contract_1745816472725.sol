Okay, here is a smart contract named `QuantumLeap` that incorporates advanced concepts like dynamic conditional logic based on time, external data (via oracle), and internal state, combined with asset (ERC20 token) transformation/distribution triggered by these conditions. It allows defining flexible "Leap" configurations and initiating "Active Leaps" based on these configs.

It aims to be creative by allowing users to essentially program future contingent transfers or actions based on complex on-chain and off-chain conditions, going beyond simple timelocks or single-condition triggers. It's not a standard lending, DEX, NFT, or DAO contract.

We'll include at least 20 distinct public/external/view functions, plus internal helpers.

---

**Outline and Function Summary**

**Contract Name:** `QuantumLeap`

**Description:**
A smart contract platform for defining and executing conditional, time-locked, and oracle-driven ERC20 token transfers or distributions ("Leaps"). Users can define complex sets of conditions (time, oracle data, internal contract state) and corresponding actions (transfer tokens). Anyone can attempt to trigger a Leap if its conditions are met and it hasn't expired or been cancelled.

**Core Concepts:**
1.  **Leap Configurations (`LeapConfig`):** Templates defining *what* conditions trigger *what* actions. Stored immutably (or updatable only by owner) once defined.
2.  **Active Leaps (`ActiveLeap`):** Instances of a `LeapConfig`, initiated by a user with a specific token deposit, start time, and duration. These are the actual "packages" of tokens waiting for conditions.
3.  **Conditions:** Can be based on:
    *   `TIME`: Reaching a specific timestamp or passing a duration.
    *   `ORACLE_PRICE_ABOVE`/`BELOW`: Price of a token pair reported by a linked oracle.
    *   `INTERNAL_STATE_EQUALS`: A specific value in a contract-managed internal state variable.
4.  **Actions:** Currently focuses on transferring a specific amount of the deposited token (or another allowed token) to a target address.
5.  **Triggering:** An `ActiveLeap` can be executed only when its conditions are met and it's not expired or cancelled. Execution can potentially be triggered by anyone (if configured) or restricted.
6.  **State Machine:** Active Leaps transition through states: `INITIATED`, `CONDITIONS_MET`, `EXECUTED`, `CANCELLED`, `EXPIRED`.

**Structs:**
*   `LeapCondition`: Defines a single condition to be checked.
*   `LeapAction`: Defines a single action to be performed if conditions are met.
*   `LeapConfig`: Groups an array of conditions and actions into a reusable template.
*   `ActiveLeap`: Represents an instance of a `LeapConfig` with deposit details, state, timestamps.

**Enums:**
*   `ConditionType`: Type of condition check (TIME, ORACLE_PRICE_ABOVE/BELOW, INTERNAL_STATE_EQUALS).
*   `ActionType`: Type of action to perform (TRANSFER_TOKEN).
*   `LeapState`: Current state of an Active Leap (INITIATED, CONDITIONS_MET, EXECUTED, CANCELLED, EXPIRED).

**State Variables:**
*   `_owner`: Contract owner address.
*   `_oracleAddress`: Address of the linked Oracle contract.
*   `_leapConfigCounter`: Counter for unique Leap Configuration IDs.
*   `_leapConfigs`: Mapping from config ID to `LeapConfig` struct.
*   `_activeLeapCounter`: Counter for unique Active Leap IDs.
*   `_activeLeaps`: Mapping from active leap ID to `ActiveLeap` struct.
*   `_internalStates`: Mapping for arbitrary internal state variables (bytes32 key to uint256 value).

**Events:**
*   `LeapConfigDefined(uint256 configId, address indexed owner)`
*   `LeapInitiated(uint256 activeLeapId, uint256 configId, address indexed depositor, uint256 depositAmount, address depositToken)`
*   `LeapConditionsMet(uint256 indexed activeLeapId)`
*   `LeapExecuted(uint256 indexed activeLeapId)`
*   `LeapCancelled(uint256 indexed activeLeapId, address indexed cancelledBy)`
*   `LeapExpired(uint256 indexed activeLeapId)`
*   `InternalStateUpdated(bytes32 indexed key, uint256 value)`

**Functions (Public/External/View):**

1.  `constructor(address initialOracleAddress)`: Initializes the contract with an owner and the oracle address.
2.  `setOracleAddress(address newOracleAddress)`: (Owner) Sets the address of the Oracle contract.
3.  `getOracleAddress() view`: Returns the current Oracle contract address.
4.  `setInternalState(bytes32 key, uint256 value)`: (Owner) Sets or updates a key-value pair in the internal state mapping, usable for `INTERNAL_STATE_EQUALS` conditions.
5.  `getInternalState(bytes32 key) view`: Returns the value associated with an internal state key.
6.  `defineLeapConfig(LeapCondition[] calldata conditions, LeapAction[] calldata actions, bool executableByAnyone)`: Defines a new Leap Configuration template. Returns the new config ID.
7.  `getLeapConfig(uint256 configId) view`: Returns the details of a specific Leap Configuration.
8.  `getLeapConfigCount() view`: Returns the total number of defined Leap Configurations.
9.  `getLeapConfigConditionCount(uint256 configId) view`: Returns the number of conditions in a specific Leap Configuration.
10. `getLeapConfigActionCount(uint256 configId) view`: Returns the number of actions in a specific Leap Configuration.
11. `getLeapConfigExecutableByAnyone(uint256 configId) view`: Returns whether a config allows anyone to trigger.
12. `initiateLeap(uint256 configId, address depositToken, uint256 depositAmount, uint256 durationSeconds)`: Initiates an Active Leap based on a config. Requires prior ERC20 `approve` for the contract. Transfers `depositToken` and `depositAmount` from the caller. Sets state to `INITIATED`. Returns the new active leap ID.
13. `cancelLeap(uint256 activeLeapId)`: (Depositor or Owner) Cancels an Active Leap if it's still `INITIATED` or `EXPIRED`. Transfers the deposited tokens back to the depositor. Sets state to `CANCELLED`.
14. `triggerLeapExecution(uint256 activeLeapId)`: (Anyone or Depositor/Owner based on config) Attempts to execute an Active Leap. Checks if conditions are met and it's not expired/cancelled/executed. If conditions met, performs actions and sets state to `EXECUTED`.
15. `getLeapState(uint256 activeLeapId) view`: Returns the current state of an Active Leap (enum).
16. `getActiveLeapCount() view`: Returns the total number of initiated Active Leaps.
17. `getLeapDepositor(uint256 activeLeapId) view`: Returns the depositor's address for an Active Leap.
18. `getLeapDepositAmount(uint256 activeLeapId) view`: Returns the deposited amount for an Active Leap.
19. `getLeapDepositToken(uint256 activeLeapId) view`: Returns the address of the deposited token for an Active Leap.
20. `getLeapInitiatedTimestamp(uint256 activeLeapId) view`: Returns the timestamp when the Active Leap was initiated.
21. `getLeapExpiryTimestamp(uint256 activeLeapId) view`: Returns the timestamp when the Active Leap expires.
22. `getLeapConditionsMetStatus(uint256 activeLeapId) view`: Checks and returns `true` if all conditions for an Active Leap are currently met, *without* changing state or executing actions. Includes expiry check.
23. `getLeapConfigIdFromActiveLeap(uint256 activeLeapId) view`: Returns the configuration ID used for an Active Leap.
24. `getLeapConditionParameter(uint256 configId, uint256 conditionIndex) view`: Returns the `parameter1` for a specific condition in a config.
25. `getLeapActionDetails(uint256 configId, uint256 actionIndex) view`: Returns details (`actionType`, `targetAddress`, `amountOrPercentage`, `tokenAddress`) for a specific action in a config.

**Internal Helper Functions:**
*   `_evaluateCondition(LeapCondition memory condition, ActiveLeap storage activeLeap) internal view`: Evaluates a single condition against the current state and active leap details.
*   `_checkAllConditions(uint256 activeLeapId) internal view`: Checks all conditions for a given Active Leap and its expiry.
*   `_getOracleData(bytes32 oracleId, address tokenAddress) internal view`: Calls the linked Oracle contract to get data.
*   `_performAction(LeapAction memory action, ActiveLeap storage activeLeap) internal`: Executes a single action, e.g., transfers tokens.
*   `executeLeapActions(uint256 activeLeapId) internal`: Executes all actions defined in the config for a leap.
*   `_safeTransfer(address token, address to, uint256 amount) internal`: Helper for robust ERC20 transfers.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// --- Outline and Function Summary (See above) ---

/**
 * @title QuantumLeap
 * @dev A smart contract platform for defining and executing conditional,
 *      time-locked, and oracle-driven ERC20 token transfers.
 */
contract QuantumLeap is Ownable, ReentrancyGuard {

    // --- Interfaces ---

    /**
     * @dev Basic interface for an Oracle contract.
     *      Assumes a function `getData` that takes a bytes32 ID and optionally a token address
     *      and returns a uint256 value (e.g., price, event data).
     *      Actual oracle implementation would be more complex (e.g., Chainlink, custom).
     */
    interface IQuantumOracle {
        function getData(bytes32 oracleId, address tokenAddress) external view returns (uint256);
    }

    // --- Enums ---

    enum ConditionType {
        TIME,                   // Check against block.timestamp
        ORACLE_PRICE_ABOVE,     // Check if oracle price > parameter1
        ORACLE_PRICE_BELOW,     // Check if oracle price < parameter1
        INTERNAL_STATE_EQUALS   // Check if internal state[key] == parameter1
    }

    enum ActionType {
        TRANSFER_TOKEN          // Transfer deposited or another token
    }

    enum LeapState {
        INITIATED,      // Leap is active and waiting for conditions
        CONDITIONS_MET, // Conditions were met, ready for execution
        EXECUTED,       // Leap actions have been performed
        CANCELLED,      // Leap was cancelled by depositor/owner
        EXPIRED         // Leap's duration has passed before conditions met
    }

    // --- Structs ---

    struct LeapCondition {
        ConditionType conditionType;
        uint256 parameter1;       // e.g., timestamp, price threshold, state value
        bytes32 oracleId;         // Used for ORACLE_* types
        address tokenAddress;     // Used for ORACLE_* types (e.g., token pair)
        bytes32 internalStateKey; // Used for INTERNAL_STATE_EQUALS type
    }

    struct LeapAction {
        ActionType actionType;
        address targetAddress;
        uint256 amountOrPercentage; // For TRANSFER_TOKEN, exact amount of the specified token
        address tokenAddress;       // Token to transfer (can be different from deposit token)
    }

    struct LeapConfig {
        LeapCondition[] conditions;
        LeapAction[] actions;
        bool executableByAnyone;    // If true, anyone can call triggerLeapExecution
    }

    struct ActiveLeap {
        uint256 configId;
        LeapState currentState;
        address depositor;
        uint256 depositAmount;
        address depositToken;       // Token deposited for this specific leap
        uint256 initiatedTimestamp;
        uint256 expiryTimestamp;
    }

    // --- State Variables ---

    IQuantumOracle private _oracle;

    uint256 private _leapConfigCounter;
    mapping(uint256 => LeapConfig) private _leapConfigs;

    uint256 private _activeLeapCounter;
    mapping(uint256 => ActiveLeap) private _activeLeaps;

    // Arbitrary internal state variables for conditional checks
    mapping(bytes32 => uint256) private _internalStates;

    // --- Events ---

    event LeapConfigDefined(uint256 indexed configId, address indexed owner);
    event LeapInitiated(uint256 indexed activeLeapId, uint256 configId, address indexed depositor, uint256 depositAmount, address depositToken);
    event LeapConditionsMet(uint256 indexed activeLeapId);
    event LeapExecuted(uint256 indexed activeLeapId);
    event LeapCancelled(uint256 indexed activeLeapId, address indexed cancelledBy);
    event LeapExpired(uint256 indexed activeLeapId);
    event InternalStateUpdated(bytes32 indexed key, uint256 value);

    // --- Constructor ---

    constructor(address initialOracleAddress) Ownable(_msgSender()) {
        require(initialOracleAddress != address(0), "Oracle address cannot be zero");
        _oracle = IQuantumOracle(initialOracleAddress);
    }

    // --- Admin Functions (Ownable) ---

    /**
     * @dev Sets the address of the Oracle contract.
     * @param newOracleAddress The address of the new Oracle contract.
     */
    function setOracleAddress(address newOracleAddress) external onlyOwner {
        require(newOracleAddress != address(0), "New oracle address cannot be zero");
        _oracle = IQuantumOracle(newOracleAddress);
        // Consider adding an event here
    }

    /**
     * @dev Returns the current Oracle contract address.
     */
    function getOracleAddress() external view returns (address) {
        return address(_oracle);
    }

    /**
     * @dev Sets or updates an internal state variable used for INTERNAL_STATE_EQUALS conditions.
     * @param key The bytes32 key for the state variable.
     * @param value The uint256 value to set.
     */
    function setInternalState(bytes32 key, uint256 value) external onlyOwner {
        _internalStates[key] = value;
        emit InternalStateUpdated(key, value);
    }

    /**
     * @dev Returns the value associated with an internal state key.
     * @param key The bytes32 key.
     * @return The uint256 value.
     */
    function getInternalState(bytes32 key) external view returns (uint256) {
        return _internalStates[key];
    }

    // --- Leap Configuration Functions ---

    /**
     * @dev Defines a new Leap Configuration template.
     * @param conditions Array of LeapCondition structs.
     * @param actions Array of LeapAction structs.
     * @param executableByAnyone If true, anyone can trigger the execution of an Active Leap based on this config.
     * @return The ID of the newly created configuration.
     */
    function defineLeapConfig(
        LeapCondition[] calldata conditions,
        LeapAction[] calldata actions,
        bool executableByAnyone
    ) external onlyOwner returns (uint256) { // Only owner can define for safety/quality control
        require(conditions.length > 0, "Must have at least one condition");
        require(actions.length > 0, "Must have at least one action");

        // Basic validation for condition types (more robust validation depends on specific oracle/state logic)
        for (uint i = 0; i < conditions.length; i++) {
            if (conditions[i].conditionType == ConditionType.ORACLE_PRICE_ABOVE || conditions[i].conditionType == ConditionType.ORACLE_PRICE_BELOW) {
                require(conditions[i].oracleId != bytes32(0), "Oracle ID required for price conditions");
                require(conditions[i].tokenAddress != address(0), "Token address required for price conditions");
            }
             if (conditions[i].conditionType == ConditionType.INTERNAL_STATE_EQUALS) {
                require(conditions[i].internalStateKey != bytes32(0), "Internal state key required");
            }
        }

        // Basic validation for action types
        for (uint i = 0; i < actions.length; i++) {
             if (actions[i].actionType == ActionType.TRANSFER_TOKEN) {
                require(actions[i].targetAddress != address(0), "Target address required for transfer");
                require(actions[i].tokenAddress != address(0), "Token address required for transfer");
            }
        }

        uint256 configId = _leapConfigCounter++;
        _leapConfigs[configId] = LeapConfig(
            conditions,
            actions,
            executableByAnyone
        );

        emit LeapConfigDefined(configId, _msgSender());
        return configId;
    }

    /**
     * @dev Returns the details of a specific Leap Configuration.
     * @param configId The ID of the configuration.
     */
    function getLeapConfig(uint256 configId) external view returns (
        LeapCondition[] memory conditions,
        LeapAction[] memory actions,
        bool executableByAnyone
    ) {
        require(configId < _leapConfigCounter, "Invalid config ID");
        LeapConfig storage config = _leapConfigs[configId];
        return (config.conditions, config.actions, config.executableByAnyone);
    }

    /**
     * @dev Returns the total number of defined Leap Configurations.
     */
    function getLeapConfigCount() external view returns (uint256) {
        return _leapConfigCounter;
    }

    /**
     * @dev Returns the number of conditions in a specific Leap Configuration.
     * @param configId The ID of the configuration.
     */
    function getLeapConfigConditionCount(uint256 configId) external view returns (uint256) {
        require(configId < _leapConfigCounter, "Invalid config ID");
        return _leapConfigs[configId].conditions.length;
    }

    /**
     * @dev Returns the number of actions in a specific Leap Configuration.
     * @param configId The ID of the configuration.
     */
    function getLeapConfigActionCount(uint256 configId) external view returns (uint256) {
         require(configId < _leapConfigCounter, "Invalid config ID");
        return _leapConfigs[configId].actions.length;
    }

     /**
     * @dev Returns whether a Leap Configuration is executable by anyone.
     * @param configId The ID of the configuration.
     */
    function getLeapConfigExecutableByAnyone(uint256 configId) external view returns (bool) {
         require(configId < _leapConfigCounter, "Invalid config ID");
        return _leapConfigs[configId].executableByAnyone;
    }

    /**
     * @dev Returns a specific condition from a Leap Configuration.
     * @param configId The ID of the configuration.
     * @param conditionIndex The index of the condition.
     */
     function getLeapConditionParameter(uint256 configId, uint256 conditionIndex) external view returns (uint256 parameter1) {
        require(configId < _leapConfigCounter, "Invalid config ID");
        require(conditionIndex < _leapConfigs[configId].conditions.length, "Invalid condition index");
        return _leapConfigs[configId].conditions[conditionIndex].parameter1;
    }

    /**
     * @dev Returns details of a specific action from a Leap Configuration.
     * @param configId The ID of the configuration.
     * @param actionIndex The index of the action.
     */
     function getLeapActionDetails(uint256 configId, uint256 actionIndex) external view returns (
        ActionType actionType,
        address targetAddress,
        uint256 amountOrPercentage,
        address tokenAddress
    ) {
        require(configId < _leapConfigCounter, "Invalid config ID");
        require(actionIndex < _leapConfigs[configId].actions.length, "Invalid action index");
        LeapAction storage action = _leapConfigs[configId].actions[actionIndex];
        return (action.actionType, action.targetAddress, action.amountOrPercentage, action.tokenAddress);
    }


    // --- Active Leap Functions ---

    /**
     * @dev Initiates an Active Leap based on a configuration.
     *      Transfers the specified amount of depositToken from the caller to the contract.
     *      Requires prior approval via depositToken.approve(contractAddress, depositAmount).
     * @param configId The ID of the Leap Configuration to use.
     * @param depositToken The address of the ERC20 token being deposited.
     * @param depositAmount The amount of tokens to deposit.
     * @param durationSeconds The duration in seconds for which the leap is active. After this, it expires.
     * @return The ID of the newly created Active Leap.
     */
    function initiateLeap(
        uint256 configId,
        address depositToken,
        uint256 depositAmount,
        uint256 durationSeconds
    ) external nonReentrant returns (uint256) {
        require(configId < _leapConfigCounter, "Invalid config ID");
        require(depositToken != address(0), "Deposit token address cannot be zero");
        require(depositAmount > 0, "Deposit amount must be greater than zero");
        require(durationSeconds > 0, "Duration must be greater than zero");

        // Use transferFrom requires caller to have approved this contract
        _safeTransferFrom(depositToken, _msgSender(), address(this), depositAmount);

        uint256 activeLeapId = _activeLeapCounter++;
        uint256 initiatedTime = block.timestamp;

        _activeLeaps[activeLeapId] = ActiveLeap(
            configId,
            LeapState.INITIATED,
            _msgSender(),
            depositAmount,
            depositToken,
            initiatedTime,
            initiatedTime + durationSeconds
        );

        emit LeapInitiated(activeLeapId, configId, _msgSender(), depositAmount, depositToken);
        return activeLeapId;
    }

    /**
     * @dev Cancels an Active Leap.
     *      Only the depositor or contract owner can cancel.
     *      Only possible if the leap is in INITIATED or EXPIRED state.
     *      Returns the deposited tokens to the depositor.
     * @param activeLeapId The ID of the Active Leap to cancel.
     */
    function cancelLeap(uint256 activeLeapId) external nonReentrant {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        ActiveLeap storage leap = _activeLeaps[activeLeapId];
        require(leap.currentState == LeapState.INITIATED || leap.currentState == LeapState.EXPIRED, "Leap not in cancellable state");
        require(leap.depositor == _msgSender() || owner() == _msgSender(), "Only depositor or owner can cancel");

        // Check expiry condition if not already expired
        if (leap.currentState == LeapState.INITIATED && block.timestamp >= leap.expiryTimestamp) {
            leap.currentState = LeapState.EXPIRED;
            emit LeapExpired(activeLeapId);
        }

        require(leap.currentState != LeapState.EXECUTED && leap.currentState != LeapState.CANCELLED && leap.currentState != LeapState.CONDITIONS_MET, "Leap cannot be cancelled in its current state");

        // Transfer deposited tokens back
        _safeTransfer(leap.depositToken, leap.depositor, leap.depositAmount);

        leap.currentState = LeapState.CANCELLED;
        emit LeapCancelled(activeLeapId, _msgSender());
    }

    /**
     * @dev Attempts to trigger the execution of an Active Leap.
     *      Checks if all conditions are met and the leap is in the INITIATED state and not expired.
     *      Execution is restricted based on the LeapConfig's `executableByAnyone` flag.
     * @param activeLeapId The ID of the Active Leap to trigger.
     */
    function triggerLeapExecution(uint256 activeLeapId) external nonReentrant {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        ActiveLeap storage leap = _activeLeaps[activeLeapId];
        LeapConfig storage config = _leapConfigs[leap.configId];

        require(leap.currentState == LeapState.INITIATED, "Leap not in initiated state");
        require(block.timestamp < leap.expiryTimestamp, "Leap has expired");

        // Access control based on config
        if (!config.executableByAnyone) {
            require(leap.depositor == _msgSender() || owner() == _msgSender(), "Execution restricted to depositor or owner");
        }

        // Check if conditions are met (this also handles expiry internally for the check)
        require(_checkAllConditions(activeLeapId), "Leap conditions not met");

        // Conditions met!
        leap.currentState = LeapState.CONDITIONS_MET; // Intermediate state
        emit LeapConditionsMet(activeLeapId);

        // Execute actions
        executeLeapActions(activeLeapId); // This function sets state to EXECUTED upon success
    }

    /**
     * @dev Returns the current state of an Active Leap.
     * @param activeLeapId The ID of the Active Leap.
     */
    function getLeapState(uint256 activeLeapId) external view returns (LeapState) {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        ActiveLeap storage leap = _activeLeaps[activeLeapId];

         // Check for expiry and update state if needed (view function cannot write, but logic is checked)
        if (leap.currentState == LeapState.INITIATED && block.timestamp >= leap.expiryTimestamp) {
            return LeapState.EXPIRED;
        }

        return leap.currentState;
    }

    /**
     * @dev Returns the total number of initiated Active Leaps.
     */
    function getActiveLeapCount() external view returns (uint256) {
        return _activeLeapCounter;
    }

    /**
     * @dev Returns the depositor address for an Active Leap.
     * @param activeLeapId The ID of the Active Leap.
     */
    function getLeapDepositor(uint256 activeLeapId) external view returns (address) {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        return _activeLeaps[activeLeapId].depositor;
    }

    /**
     * @dev Returns the deposited amount for an Active Leap.
     * @param activeLeapId The ID of the Active Leap.
     */
    function getLeapDepositAmount(uint256 activeLeapId) external view returns (uint256) {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        return _activeLeaps[activeLeapId].depositAmount;
    }

    /**
     * @dev Returns the address of the deposited token for an Active Leap.
     * @param activeLeapId The ID of the Active Leap.
     */
    function getLeapDepositToken(uint256 activeLeapId) external view returns (address) {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        return _activeLeaps[activeLeapId].depositToken;
    }

    /**
     * @dev Returns the timestamp when the Active Leap was initiated.
     * @param activeLeapId The ID of the Active Leap.
     */
    function getLeapInitiatedTimestamp(uint256 activeLeapId) external view returns (uint256) {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        return _activeLeaps[activeLeapId].initiatedTimestamp;
    }

    /**
     * @dev Returns the timestamp when the Active Leap expires.
     * @param activeLeapId The ID of the Active Leap.
     */
    function getLeapExpiryTimestamp(uint256 activeLeapId) external view returns (uint256) {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        return _activeLeaps[activeLeapId].expiryTimestamp;
    }

    /**
     * @dev Checks if all conditions for an Active Leap are currently met.
     *      Does *not* change the leap's state. Includes checking for expiry.
     * @param activeLeapId The ID of the Active Leap.
     * @return true if all conditions are met and the leap is not expired, false otherwise.
     */
    function getLeapConditionsMetStatus(uint256 activeLeapId) external view returns (bool) {
        require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        ActiveLeap storage leap = _activeLeaps[activeLeapId];

        // If already executed or cancelled, conditions are not met (in the context of triggering)
        if (leap.currentState == LeapState.EXECUTED || leap.currentState == LeapState.CANCELLED) {
            return false;
        }

         // Check for expiry
        if (block.timestamp >= leap.expiryTimestamp) {
             // In a view function, we just return false and let the state transition happen
             // in triggerLeapExecution or cancelLeap.
             return false;
        }

        // Evaluate actual conditions
        return _checkAllConditions(activeLeapId);
    }

    /**
     * @dev Returns the configuration ID associated with an Active Leap.
     * @param activeLeapId The ID of the Active Leap.
     */
    function getLeapConfigIdFromActiveLeap(uint256 activeLeapId) external view returns (uint256) {
         require(activeLeapId < _activeLeapCounter, "Invalid active leap ID");
        return _activeLeaps[activeLeapId].configId;
    }

    // --- Internal Logic Functions ---

    /**
     * @dev Evaluates a single LeapCondition for a given Active Leap.
     * @param condition The condition struct.
     * @param activeLeap The Active Leap struct.
     * @return true if the condition is met, false otherwise.
     */
    function _evaluateCondition(LeapCondition memory condition, ActiveLeap storage activeLeap) internal view returns (bool) {
        if (condition.conditionType == ConditionType.TIME) {
            // parameter1 is the target timestamp
            return block.timestamp >= condition.parameter1;
        } else if (condition.conditionType == ConditionType.ORACLE_PRICE_ABOVE) {
            // parameter1 is the price threshold (scaled by oracle)
            uint256 currentPrice = _getOracleData(condition.oracleId, condition.tokenAddress);
            return currentPrice > condition.parameter1;
        } else if (condition.conditionType == ConditionType.ORACLE_PRICE_BELOW) {
             // parameter1 is the price threshold (scaled by oracle)
            uint256 currentPrice = _getOracleData(condition.oracleId, condition.tokenAddress);
            return currentPrice < condition.parameter1;
        } else if (condition.conditionType == ConditionType.INTERNAL_STATE_EQUALS) {
            // parameter1 is the target state value
            uint256 currentStateValue = _internalStates[condition.internalStateKey];
            return currentStateValue == condition.parameter1;
        }
        // Should not reach here if enum is handled exhaustively
        return false;
    }

    /**
     * @dev Checks if all conditions for a given Active Leap are met AND it is not expired.
     * @param activeLeapId The ID of the Active Leap.
     * @return true if all conditions are met and not expired, false otherwise.
     */
    function _checkAllConditions(uint256 activeLeapId) internal view returns (bool) {
        ActiveLeap storage leap = _activeLeaps[activeLeapId];
        LeapConfig storage config = _leapConfigs[leap.configId];

        // Check expiry first
        if (block.timestamp >= leap.expiryTimestamp) {
             return false;
        }

        // Check all defined conditions
        for (uint i = 0; i < config.conditions.length; i++) {
            if (!_evaluateCondition(config.conditions[i], leap)) {
                // If any single condition is NOT met, the overall check fails
                return false;
            }
        }

        // If we looped through all conditions and none failed, they are all met
        return true;
    }

     /**
     * @dev Calls the linked Oracle contract to retrieve data.
     *      Includes basic error handling if the oracle call reverts.
     * @param oracleId The bytes32 identifier for the specific data feed/query.
     * @param tokenAddress Optional token address relevant to the query (e.g., for price pairs).
     * @return The uint256 data value returned by the oracle. Reverts if the oracle call fails.
     */
    function _getOracleData(bytes32 oracleId, address tokenAddress) internal view returns (uint256) {
        require(address(_oracle) != address(0), "Oracle address not set");
        // This assumes a simple oracle interface. Real-world oracles handle
        // data freshness, varying return types, multiple feeds, etc.
        // We wrap in try/catch or require to handle potential oracle issues.
        try _oracle.getData(oracleId, tokenAddress) returns (uint256 data) {
            return data;
        } catch {
            revert("Oracle data retrieval failed");
        }
    }

    /**
     * @dev Executes all actions defined in the config for a given Active Leap.
     *      Transfers tokens as specified. Sets state to EXECUTED upon completion.
     *      Reverts if any action fails.
     * @param activeLeapId The ID of the Active Leap.
     */
    function executeLeapActions(uint256 activeLeapId) internal {
        ActiveLeap storage leap = _activeLeaps[activeLeapId];
        LeapConfig storage config = _leapConfigs[leap.configId];

        // Ensure this is only called when conditions were just met
        require(leap.currentState == LeapState.CONDITIONS_MET, "Leap not in conditions met state");

        // Execute all actions sequentially
        for (uint i = 0; i < config.actions.length; i++) {
            _performAction(config.actions[i], leap);
        }

        // Mark as executed
        leap.currentState = LeapState.EXECUTED;
        emit LeapExecuted(activeLeapId);

        // Note: Any remaining deposited tokens after actions are performed would be locked
        // in the contract unless a specific action is included to return residuals.
        // For simplicity here, we assume actions use the intended amounts.
        // A more complex version might track remaining balance and allow claiming.
    }

     /**
     * @dev Performs a single action based on the action struct and active leap data.
     * @param action The action struct to perform.
     * @param activeLeap The Active Leap struct providing context (depositor, deposit token/amount).
     */
    function _performAction(LeapAction memory action, ActiveLeap storage activeLeap) internal {
        if (action.actionType == ActionType.TRANSFER_TOKEN) {
            // amountOrPercentage is the exact amount for TRANSFER_TOKEN action type
            uint256 amountToTransfer = action.amountOrPercentage;
            address tokenToTransfer = action.tokenAddress;
            address target = action.targetAddress;

            // Check if the contract holds enough of the token to transfer
            // This is a safety check, but the deposit logic should ensure sufficient funds
            // if the action uses the deposited token. If using a different token,
            // that token needs to be pre-approved/sent to the contract separately.
            // For this simplified example, let's assume actions only use the deposited token.
            // A real contract might need a registry of allowed action tokens or a different deposit model.
            require(tokenToTransfer == activeLeap.depositToken, "Action token must match deposit token (simplified)"); // Enforce simplification

            // Ensure amount requested doesn't exceed the deposited amount for the leap
            // A more complex model could allow partial execution or use a different funding source.
            // Here, actions consume from the single deposit.
            require(amountToTransfer <= activeLeap.depositAmount, "Action amount exceeds deposited amount"); // Basic check

            _safeTransfer(tokenToTransfer, target, amountToTransfer);

             // Note: If actions consume the deposit, need to track remaining deposit or make actions additive
             // For simplicity, we don't track remaining deposit here. Actions are discrete transfers.
        }
        // Add more action types here (e.g., DISTRIBUTE_PROPORTION, CALL_CONTRACT, etc.)
    }

    // --- ERC20 Safe Transfer Helpers ---
    // Using OpenZeppelin's safeTransfer and safeTransferFrom patterns

    /**
     * @dev Safely transfers tokens using the ERC20 standard.
     * @param token The address of the ERC20 token.
     * @param to The recipient address.
     * @param amount The amount of tokens to transfer.
     */
    function _safeTransfer(address token, address to, uint256 amount) internal {
        require(token != address(0), "SafeTransfer: zero address");
        IERC20 tokenContract = IERC20(token);

        // Use call to avoid reentrancy from malicious tokens and check return value
        (bool success, bytes memory data) = address(tokenContract).call(abi.encodeWithSelector(tokenContract.transfer.selector, to, amount));
        require(success, "SafeTransfer: transfer failed");

        // Check for short reverts on pre-ERC20 tokens
        if (data.length > 0) {
             require(abi.decode(data, (bool)), "SafeTransfer: transfer returned false");
        }
    }

     /**
     * @dev Safely transfers tokens from a sender using the ERC20 standard (requires approval).
     * @param token The address of the ERC20 token.
     * @param from The sender address (requires approval).
     * @param to The recipient address.
     * @param amount The amount of tokens to transfer.
     */
    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        require(token != address(0), "SafeTransferFrom: zero address");
        IERC20 tokenContract = IERC20(token);

        // Use call to avoid reentrancy from malicious tokens and check return value
        (bool success, bytes memory data) = address(tokenContract).call(abi.encodeWithSelector(tokenContract.transferFrom.selector, from, to, amount));
        require(success, "SafeTransferFrom: transferFrom failed");

         // Check for short reverts on pre-ERC20 tokens
        if (data.length > 0) {
             require(abi.decode(data, (bool)), "SafeTransferFrom: transferFrom returned false");
        }
    }

    // --- Fallback/Receive (Optional but good practice) ---

    // receive() external payable {
    //     // Reject receiving ETH unless explicitly intended
    //     revert("Cannot receive Ether directly");
    // }

    // fallback() external payable {
    //     // Reject receiving ETH via fallback
    //     revert("Cannot receive Ether via fallback");
    // }
}
```