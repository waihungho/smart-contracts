Okay, let's design a smart contract called `QuantumVault`. The concept will revolve around a vault that can hold various assets (ETH, ERC-20, ERC-721) but *only* allows actions (like transfers or external calls) to be executed if a dynamic set of complex, predefined conditions are met. This introduces concepts of conditional logic, state transitions based on multiple factors (time, balance, external data simulation, approvals, etc.), and a degree of programmatic control over asset release and interaction.

This isn't a direct copy of common open-source contracts like ERC-20, ERC-721, standard staking, basic vesting, or simple multi-sigs. It combines elements but in a rule-based, conditional execution engine context.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **License and Pragma**
2.  **Imports:** OpenZeppelin for basic utilities (`Ownable`, `SafeERC20`, `SafeTransferLib`, `ERC721`).
3.  **Error Handling**
4.  **Enums:** `ConditionType`, `ActionType`, `ActionStatus`.
5.  **Structs:** `Condition`, `Action`.
6.  **Events:** For deposits, withdrawals, condition changes, action creation, action execution, etc.
7.  **State Variables:**
    *   Ownership (`Ownable`)
    *   Asset balances (internal tracking)
    *   Mapping for Conditions (`id => Condition`)
    *   Mapping for Actions (`id => Action`)
    *   Counters for condition and action IDs
    *   Simulation data (e.g., simulated oracle prices)
    *   Paused state
    *   Multi-sig approver list and approval tracking
    *   Delegated condition managers
8.  **Modifiers:** (`whenNotPaused`, `onlyOwnerOrConditionManager`)
9.  **Core Logic:**
    *   `receive()` and `fallback()`
    *   Asset deposit functions
    *   Asset view functions
    *   Condition management functions (`add`, `remove`, `update`)
    *   Condition evaluation function (`checkConditionMet`) - complex logic based on type
    *   Action management functions (`create`, `cancel`)
    *   Action execution function (`executeConditionalAction`) - checks conditions and performs action
10. **Advanced Features:**
    *   Simulated Oracle Update
    *   Multi-Sig Approval Condition Logic
    *   Delegated Management
    *   Pause/Unpause
    *   Owner Rescue (limited)

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `receive() external payable`: Allows receiving ETH deposits.
3.  `depositERC20(address token, uint256 amount)`: Deposits a specified amount of ERC-20 tokens. Requires prior approval.
4.  `depositERC721(address token, uint256 tokenId)`: Deposits a specific ERC-721 token. Requires prior approval.
5.  `getETHBalance() public view returns (uint256)`: Returns the contract's ETH balance.
6.  `getERC20Balance(address token) public view returns (uint256)`: Returns the contract's balance for a specific ERC-20 token.
7.  `isERC721Deposited(address token, uint256 tokenId) public view returns (bool)`: Checks if a specific ERC-721 token is held by the contract.
8.  `addCondition(ConditionType conditionType, bytes calldata params) public onlyOwnerOrConditionManager returns (uint256 conditionId)`: Adds a new rule/condition that can be required for actions. `params` contains type-specific data.
9.  `removeCondition(uint256 conditionId) public onlyOwnerOrConditionManager`: Removes an existing condition.
10. `updateCondition(uint256 conditionId, ConditionType newConditionType, bytes calldata newParams) public onlyOwnerOrConditionManager`: Updates the details of an existing condition.
11. `checkConditionMet(uint256 conditionId) public view returns (bool)`: Evaluates whether a specific condition is currently true.
12. `createConditionalAction(ActionType actionType, bytes calldata actionParams, uint256[] calldata requiredConditionIds) public onlyOwner returns (uint256 actionId)`: Defines an action (transfer, call) that can only be executed if a specific set of conditions are all met.
13. `executeConditionalAction(uint256 actionId) public whenNotPaused`: Attempts to execute a predefined action. This function checks *all* required conditions first.
14. `cancelConditionalAction(uint256 actionId) public onlyOwner`: Cancels a pending or ready conditional action.
15. `getActionStatus(uint256 actionId) public view returns (ActionStatus)`: Returns the current status of a conditional action.
16. `getConditionDetails(uint256 conditionId) public view returns (ConditionType conditionType, bytes memory params)`: Retrieves the type and parameters of a condition.
17. `getRequiredConditionsForAction(uint256 actionId) public view returns (uint256[] memory)`: Gets the list of condition IDs required for a specific action.
18. `simulateOraclePriceUpdate(address token, uint256 price) public onlyOwner`: Allows the owner to simulate updating the price feed for a token (used by `MinPriceERC20` condition).
19. `addMultiSigApprover(address approver) public onlyOwner`: Adds an address that can submit approvals for `MultiSigApproval` conditions.
20. `removeMultiSigApprover(address approver) public onlyOwner`: Removes a multi-sig approver.
21. `submitApprovalForCondition(uint256 conditionId) public`: An approved multi-sig address submits their approval for a specific condition.
22. `checkMultiSigConditionMet(uint256 conditionId) public view returns (bool)`: Specifically checks if enough multi-sig approvals have been submitted for a condition.
23. `delegateConditionManagement(address manager, bool canManage) public onlyOwner`: Grants or revokes the ability for an address to manage conditions (add/remove/update).
24. `pauseExecution() public onlyOwner whenNotPaused`: Pauses the execution of *new* conditional actions. Already created actions cannot be executed while paused.
25. `unpauseExecution() public onlyOwner`: Unpauses execution.
26. `getIsPaused() public view returns (bool)`: Checks if the contract is paused.
27. `ownerWithdrawETH(uint256 amount) public onlyOwner`: Allows the owner to withdraw ETH (e.g., in emergency or for fees, if fees were implemented).
28. `ownerWithdrawERC20(address token, uint256 amount) public onlyOwner`: Allows the owner to withdraw ERC-20 tokens.
29. `ownerWithdrawERC721(address token, uint256 tokenId) public onlyOwner`: Allows the owner to withdraw ERC-721 tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has checked arithmetic by default, SafeMath is good for clarity or older versions/complex scenarios. Not strictly needed here but kept as a pattern.
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol"; // Use SafeERC721 for safer ERC721 interactions

// Custom Errors
error QuantumVault__NotEnoughETH();
error QuantumVault__TransferFailed();
error QuantumVault__ERC20TransferFromFailed();
error QuantumVault__ERC721TransferFromFailed();
error QuantumVault__ConditionNotFound(uint256 conditionId);
error QuantumVault__ActionNotFound(uint256 actionId);
error QuantumVault__ActionNotPendingOrReady(uint256 actionId);
error QuantumVault__ConditionNotMet(uint256 conditionId);
error QuantumVault__NotAllConditionsMet();
error QuantumVault__ActionAlreadyExecutedOrCancelled(uint256 actionId);
error QuantumVault__NotAuthorizedToManageConditions();
error QuantumVault__NotAMultiSigApprover();
error QuantumVault__AlreadyApproved(uint256 conditionId, address approver);
error QuantumVault__InvalidConditionTypeForApproval(uint256 conditionId);
error QuantumVault__ExecutionPaused();
error QuantumVault__InsufficientBalance(address token, uint256 required, uint256 available);
error QuantumVault__ERC721NotHeld(address token, uint256 tokenId);
error QuantumVault__InvalidParametersForConditionType();
error QuantumVault__InvalidParametersForActionType();
error QuantumVault__CallFailed(bytes data);


contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;
    using Address for address;
    using SafeMath for uint256; // SafeMath is largely superseded by native checks in 0.8+, but can be used for clarity or specific patterns.

    // --- Enums ---

    enum ConditionType {
        TimeLock,             // Params: uint256 unlockTimestamp
        MinBalanceETH,        // Params: uint256 requiredAmount
        MinBalanceERC20,      // Params: address token, uint256 requiredAmount
        MinERC721Count,       // Params: address token, uint256 requiredCount
        MinPriceERC20,        // Params: address token, uint256 requiredPrice (simulated)
        MultiSigApproval,     // Params: uint256 requiredApprovals
        ActionExecutedCount,  // Params: uint256 actionId, uint256 minExecutions
        ExternalCallSuccess   // Params: address target, bytes callData, bytes expectedReturnData (optional)
    }

    enum ActionType {
        TransferETH,         // Params: address recipient, uint256 amount
        TransferERC20,       // Params: address token, address recipient, uint256 amount
        TransferERC721,      // Params: address token, address recipient, uint256 tokenId
        CallExternal         // Params: address target, uint256 value, bytes callData
    }

    enum ActionStatus {
        Pending, // Conditions not yet met
        Ready,   // Conditions met, waiting for execution call
        Executed,
        Cancelled,
        Failed   // Execution attempted but failed
    }

    // --- Structs ---

    struct Condition {
        ConditionType conditionType;
        bytes params; // Encoded parameters specific to the condition type
        // Note: isMet state is checked dynamically, not stored per condition instance
    }

    struct Action {
        ActionType actionType;
        bytes actionParams; // Encoded parameters specific to the action type
        uint256[] requiredConditionIds;
        ActionStatus status;
        uint256 executionCount;
    }

    // --- State Variables ---

    uint256 private _conditionCounter;
    uint256 private _actionCounter;

    mapping(uint256 => Condition) private _conditions;
    mapping(uint256 => Action) private _actions;

    // --- Simulation Data ---
    // In a real scenario, this would interact with decentralized oracles (e.g., Chainlink)
    mapping(address => uint256) private _simulatedOraclePrices; // token => price (scaled)

    // --- Multi-Sig Approval Data (for MultiSigApproval condition type) ---
    mapping(address => bool) private _isMultiSigApprover;
    mapping(uint256 => mapping(address => bool)) private _conditionApprovals; // conditionId => approver => approved
    mapping(uint256 => uint256) private _conditionApprovalCount; // conditionId => current count

    // --- Delegated Management ---
    mapping(address => bool) private _canManageConditions;

    // --- Pause Mechanism ---
    bool private _paused;

    // --- Events ---

    event ETHDeposited(address indexed sender, uint256 amount);
    event ERC20Deposited(address indexed token, address indexed sender, uint256 amount);
    event ERC721Deposited(address indexed token, address indexed from, uint256 indexed tokenId);

    event ConditionAdded(uint256 indexed conditionId, ConditionType conditionType);
    event ConditionRemoved(uint256 indexed conditionId);
    event ConditionUpdated(uint256 indexed conditionId, ConditionType newConditionType);
    event ConditionMet(uint256 indexed conditionId); // Emitted when checked and met

    event ActionCreated(uint256 indexed actionId, ActionType actionType, uint256[] requiredConditionIds);
    event ActionStatusChanged(uint256 indexed actionId, ActionStatus oldStatus, ActionStatus newStatus);
    event ActionExecuted(uint256 indexed actionId);
    event ActionExecutionFailed(uint256 indexed actionId, bytes reason);
    event ActionCancelled(uint256 indexed actionId);

    event OraclePriceUpdated(address indexed token, uint256 newPrice);

    event MultiSigApproverAdded(address indexed approver);
    event MultiSigApproverRemoved(address indexed approver);
    event ApprovalSubmitted(uint256 indexed conditionId, address indexed approver);

    event ConditionManagerDelegated(address indexed manager, bool canManage);

    event ExecutionPaused();
    event ExecutionUnpaused();

    event OwnerWithdrawalETH(address indexed owner, uint256 amount);
    event OwnerWithdrawalERC20(address indexed owner, address indexed token, uint256 amount);
    event OwnerWithdrawalERC721(address indexed owner, address indexed token, uint256 indexed tokenId);

    // --- Modifiers ---

    modifier whenNotPaused() {
        if (_paused) {
            revert QuantumVault__ExecutionPaused();
        }
        _;
    }

    modifier onlyOwnerOrConditionManager() {
        if (msg.sender != owner() && !_canManageConditions[msg.sender]) {
            revert QuantumVault__NotAuthorizedToManageConditions();
        }
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        _conditionCounter = 0;
        _actionCounter = 0;
        _paused = false;
    }

    // --- Receive ETH ---

    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        // Optional: handle unexpected calls, or just let receive() handle it.
        // For simplicity, letting receive() handle ETH and reverting for calls with data.
        if (msg.data.length > 0) {
             revert(); // Revert if ETH sent with data
        }
         emit ETHDeposited(msg.sender, msg.value); // Redundant if receive() exists, but safe
    }


    // --- Asset Deposit Functions ---

    /**
     * @notice Deposits a specified amount of ERC-20 tokens into the vault.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     * @dev Requires the sender to have approved this contract to transfer the tokens beforehand.
     */
    function depositERC20(address token, uint256 amount) external {
        if (amount == 0) return;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(token, msg.sender, amount);
    }

    /**
     * @notice Deposits a specific ERC-721 token into the vault.
     * @param token The address of the ERC-721 token contract.
     * @param tokenId The ID of the token to deposit.
     * @dev Requires the sender to have approved this contract or the token to be in the sender's address.
     */
    function depositERC721(address token, uint256 tokenId) external {
         // SafeTransferFrom checks if sender is owner or approved
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
        emit ERC721Deposited(token, msg.sender, tokenId);
    }

    // --- Asset View Functions ---

    /**
     * @notice Returns the current ETH balance held by the contract.
     */
    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the current balance of a specific ERC-20 token held by the contract.
     * @param token The address of the ERC-20 token.
     */
    function getERC20Balance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice Checks if a specific ERC-721 token is currently held by the contract.
     * @param token The address of the ERC-721 token contract.
     * @param tokenId The ID of the token to check.
     */
    function isERC721Deposited(address token, uint256 tokenId) public view returns (bool) {
        // Using try/catch in case token address isn't a valid ERC721 or doesn't have ownerOf
        try IERC721(token).ownerOf(tokenId) returns (address ownerAddress) {
            return ownerAddress == address(this);
        } catch {
            return false; // Assume not deposited if ownerOf call fails (e.g., not ERC721 or token doesn't exist)
        }
    }

    // --- Condition Management Functions ---

    /**
     * @notice Adds a new condition that can be used to gate actions.
     * @param conditionType The type of condition.
     * @param params Encoded parameters specific to the condition type.
     * @return conditionId The unique ID assigned to the new condition.
     */
    function addCondition(ConditionType conditionType, bytes calldata params) public onlyOwnerOrConditionManager returns (uint256) {
        _conditionCounter++;
        uint256 newConditionId = _conditionCounter;
        _conditions[newConditionId] = Condition(conditionType, params);
        emit ConditionAdded(newConditionId, conditionType);
        return newConditionId;
    }

    /**
     * @notice Removes an existing condition.
     * @param conditionId The ID of the condition to remove.
     */
    function removeCondition(uint256 conditionId) public onlyOwnerOrConditionManager {
        if (_conditions[conditionId].conditionType == ConditionType(0) && conditionId != 0) {
             revert QuantumVault__ConditionNotFound(conditionId);
        }
        // Note: Does not check if condition is used in any action.
        // Actions using this condition will fail to execute if the condition is removed.
        delete _conditions[conditionId];
        // Clean up multi-sig approvals if it was a MultiSigApproval type
        delete _conditionApprovals[conditionId];
        delete _conditionApprovalCount[conditionId];

        emit ConditionRemoved(conditionId);
    }

     /**
     * @notice Updates the type and parameters of an existing condition.
     * @param conditionId The ID of the condition to update.
     * @param newConditionType The new type for the condition.
     * @param newParams New encoded parameters for the condition.
     */
    function updateCondition(uint256 conditionId, ConditionType newConditionType, bytes calldata newParams) public onlyOwnerOrConditionManager {
         if (_conditions[conditionId].conditionType == ConditionType(0) && conditionId != 0) {
             revert QuantumVault__ConditionNotFound(conditionId);
         }
         // Note: Does not check if condition is used in any action.
         _conditions[conditionId].conditionType = newConditionType;
         _conditions[conditionId].params = newParams;
         // Reset multi-sig state if type changed or params imply changes
         delete _conditionApprovals[conditionId];
         delete _conditionApprovalCount[conditionId];

         emit ConditionUpdated(conditionId, newConditionType);
    }


    /**
     * @notice Evaluates whether a specific condition is currently true.
     * @param conditionId The ID of the condition to check.
     * @return A boolean indicating if the condition is met.
     */
    function checkConditionMet(uint256 conditionId) public view returns (bool) {
        Condition storage cond = _conditions[conditionId];
        if (cond.conditionType == ConditionType(0) && conditionId != 0) {
             revert QuantumVault__ConditionNotFound(conditionId);
        }

        // Decode parameters based on condition type and evaluate
        if (cond.conditionType == ConditionType.TimeLock) {
            (uint256 unlockTimestamp) = abi.decode(cond.params, (uint256));
            return block.timestamp >= unlockTimestamp;

        } else if (cond.conditionType == ConditionType.MinBalanceETH) {
            (uint256 requiredAmount) = abi.decode(cond.params, (uint256));
            return address(this).balance >= requiredAmount;

        } else if (cond.conditionType == ConditionType.MinBalanceERC20) {
            (address token, uint256 requiredAmount) = abi.decode(cond.params, (address, uint256));
            return IERC20(token).balanceOf(address(this)) >= requiredAmount;

        } else if (cond.conditionType == ConditionType.MinERC721Count) {
             (address token, uint256 requiredCount) = abi.decode(cond.params, (address, uint256));
             // This check is simple: does the *contract* hold at least requiredCount NFTs?
             // A more complex version would require iterating or tracking per-depositor counts.
             // We'll use a simple approximate check based on balance if token supports ERC165 and balance,
             // or just assume true if requiredCount is 0. Accurate count requires iteration or specific token functions.
             // For simplicity, let's make this a basic check: if requiredCount > 0, does the ownerOf any specific ID match the contract?
             // Or even simpler for this example contract: does the contract have *any* balance > 0 if requiredCount > 0?
             // Let's refine: requires `requiredCount` *unique* tokens of that type. This is hard without iterating or tracking.
             // A practical implementation might check if `requiredCount` specific tokenIds exist or use a different metric.
             // For this example, let's simplify to check if the contract holds *any* of that token type if requiredCount > 0.
             // Or better, let's use a hypothetical `getNFTCount` if the token supports it, falling back or assuming false.
             // A simple implementation might just check if requiredCount is 0 or 1 and ownerOf a specific ID.
             // Let's implement based on the *count* of *specific* token IDs if passed, or a simple balance check if count > 0.
             // Assuming params might be `(address token, uint256 requiredCount)` OR `(address token, uint256[] requiredTokenIds)`.
             // Let's stick to `(address token, uint256 requiredCount)`. Counting specific tokens is complex.
             // Let's assume this condition means "the vault holds AT LEAST `requiredCount` tokens of this type".
             // This requires an off-chain indexer or iterating `token.balanceOf` (if ERC721 supports it, many don't) or iterating *all* tokenIds deposited.
             // The *simplest* interpretation is `requiredCount == 0` (always true) or `requiredCount == 1` AND `isERC721Deposited(token, a_specific_id_in_params)`.
             // Let's go with `(address token, uint256 countThreshold)`. If `countThreshold > 0`, check if *any* deposited ERC721 of that type exists. This is a simplification.
             // A proper implementation might require a helper mapping like `_depositedERC721s[token][tokenId] = true;` and iterating.
             // For this example, let's check if `countThreshold` is 0, or if we hold at least one of that token type (simplification).
             // Or even better: rely on `IERC721.balanceOf` if the token implements it (optional part of ERC721).
             // Let's assume tokens used with this condition *must* implement `balanceOf`.
             try IERC721(token).balanceOf(address(this)) returns (uint256 currentCount) {
                 return currentCount >= requiredCount;
             } catch {
                 // If balanceOf call fails, token doesn't support it or address is bad. Assume condition not met if requiredCount > 0.
                 return requiredCount == 0;
             }


        } else if (cond.conditionType == ConditionType.MinPriceERC20) {
             (address token, uint256 requiredPrice) = abi.decode(cond.params, (address, uint256));
             // Uses the simulated oracle price
             uint256 currentPrice = _simulatedOraclePrices[token];
             return currentPrice >= requiredPrice && currentPrice > 0; // Require price to be set and meet threshold

        } else if (cond.conditionType == ConditionType.MultiSigApproval) {
             (uint256 requiredApprovals) = abi.decode(cond.params, (uint256));
             return _conditionApprovalCount[conditionId] >= requiredApprovals;

        } else if (cond.conditionType == ConditionType.ActionExecutedCount) {
             (uint256 actionId, uint256 minExecutions) = abi.decode(cond.params, (uint256, uint256));
             Action storage act = _actions[actionId];
             // Check if action exists and has been executed at least minExecutions times
             return actionId != 0 && act.executionCount >= minExecutions;

        } else if (cond.conditionType == ConditionType.ExternalCallSuccess) {
             (address target, bytes memory callData) = abi.decode(cond.params, (address, bytes));
             // Optional: bytes expectedReturnData. Let's skip this complexity for now.
             // Simply checks if the call succeeds (returns true)
             (bool success, ) = target.call(callData);
             return success;
        }
        // If ConditionType is unknown or 0
        return false;
    }


    // --- Action Management Functions ---

    /**
     * @notice Creates a new conditional action that can be executed.
     * @param actionType The type of action (transfer, call).
     * @param actionParams Encoded parameters specific to the action type.
     * @param requiredConditionIds An array of condition IDs. ALL of these must be met to execute the action.
     * @return actionId The unique ID assigned to the new action.
     */
    function createConditionalAction(ActionType actionType, bytes calldata actionParams, uint256[] calldata requiredConditionIds) public onlyOwner returns (uint256) {
        // Basic validation: check if required conditions exist
        for (uint i = 0; i < requiredConditionIds.length; i++) {
            if (_conditions[requiredConditionIds[i]].conditionType == ConditionType(0) && requiredConditionIds[i] != 0) {
                revert QuantumVault__ConditionNotFound(requiredConditionIds[i]);
            }
        }

        _actionCounter++;
        uint256 newActionId = _actionCounter;
        _actions[newActionId] = Action(
            actionType,
            actionParams,
            requiredConditionIds,
            ActionStatus.Pending, // Starts as pending
            0 // executionCount
        );

        emit ActionCreated(newActionId, actionType, requiredConditionIds);
        return newActionId;
    }

    /**
     * @notice Attempts to execute a predefined conditional action.
     * @param actionId The ID of the action to execute.
     * @dev This function checks if ALL required conditions are met before executing the action.
     */
    function executeConditionalAction(uint256 actionId) public whenNotPaused {
        Action storage action = _actions[actionId];

        if (action.actionType == ActionType(0) && actionId != 0) {
            revert QuantumVault__ActionNotFound(actionId);
        }
        if (action.status == ActionStatus.Executed || action.status == ActionStatus.Cancelled) {
             revert QuantumVault__ActionAlreadyExecutedOrCancelled(actionId);
        }

        // 1. Check all required conditions
        bool allConditionsMet = true;
        for (uint i = 0; i < action.requiredConditionIds.length; i++) {
            uint256 condId = action.requiredConditionIds[i];
            if (!checkConditionMet(condId)) {
                allConditionsMet = false;
                emit QuantumVault__ConditionNotMet(condId); // Log which condition failed
                break; // Exit loop early if any condition fails
            } else {
                 emit ConditionMet(condId); // Log which condition passed
            }
        }

        if (!allConditionsMet) {
             // Action status remains Pending/Ready if conditions aren't met
             revert QuantumVault__NotAllConditionsMet();
        }

        // 2. Conditions met, update status to Ready (optional intermediate step)
        if (action.status == ActionStatus.Pending) {
            action.status = ActionStatus.Ready;
            emit ActionStatusChanged(actionId, ActionStatus.Pending, ActionStatus.Ready);
        }

        // 3. Execute the action
        bool success = false;
        bytes memory returnData;

        if (action.actionType == ActionType.TransferETH) {
            (address recipient, uint256 amount) = abi.decode(action.actionParams, (address, uint256));
            if (address(this).balance < amount) {
                revert QuantumVault__InsufficientBalance(address(0), amount, address(this).balance);
            }
            (success, ) = recipient.call{value: amount}(""); // Low-level call for ETH transfer
            // Note: Using send/transfer is safer against reentrancy for simple ETH transfers,
            // but call allows specifying gas and is more flexible. Since we're not immediately
            // checking state or calling back into unknown code after the transfer, 'call' is acceptable here
            // but requires checking `success`.
             if (!success) {
                 emit ActionExecutionFailed(actionId, "ETH transfer failed");
                 revert QuantumVault__TransferFailed();
             }


        } else if (action.actionType == ActionType.TransferERC20) {
            (address token, address recipient, uint256 amount) = abi.decode(action.actionParams, (address, address, uint256));
             if (IERC20(token).balanceOf(address(this)) < amount) {
                revert QuantumVault__InsufficientBalance(token, amount, IERC20(token).balanceOf(address(this)));
             }
            IERC20(token).safeTransfer(recipient, amount); // Safe method checks success

        } else if (action.actionType == ActionType.TransferERC721) {
             (address token, address recipient, uint256 tokenId) = abi.decode(action.actionParams, (address, address, uint256));
             if (!isERC721Deposited(token, tokenId)) {
                 revert QuantumVault__ERC721NotHeld(token, tokenId);
             }
             IERC721(token).safeTransferFrom(address(this), recipient, tokenId); // Safe method checks ownership/approval

        } else if (action.actionType == ActionType.CallExternal) {
             (address target, uint256 value, bytes memory callData) = abi.decode(action.actionParams, (address, uint256, bytes));
             if (address(this).balance < value) {
                revert QuantumVault__InsufficientBalance(address(0), value, address(this).balance);
             }
             (success, returnData) = target.call{value: value}(callData);
             if (!success) {
                 // If the external call fails, mark action as failed and revert
                 action.status = ActionStatus.Failed;
                 emit ActionStatusChanged(actionId, ActionStatus.Ready, ActionStatus.Failed);
                 emit ActionExecutionFailed(actionId, returnData); // Include return data if available
                 revert QuantumVault__CallFailed(returnData);
             }
        } else {
            // Unknown action type
            revert QuantumVault__ActionExecutionFailed(actionId, "Unknown action type");
        }

        // 4. Update action status to Executed
        action.status = ActionStatus.Executed;
        action.executionCount++;
        emit ActionStatusChanged(actionId, ActionStatus.Ready, ActionStatus.Executed);
        emit ActionExecuted(actionId);
    }

    /**
     * @notice Cancels a pending or ready conditional action.
     * @param actionId The ID of the action to cancel.
     */
    function cancelConditionalAction(uint256 actionId) public onlyOwner {
        Action storage action = _actions[actionId];
         if (action.actionType == ActionType(0) && actionId != 0) {
            revert QuantumVault__ActionNotFound(actionId);
        }
        if (action.status == ActionStatus.Executed || action.status == ActionStatus.Cancelled) {
             revert QuantumVault__ActionAlreadyExecutedOrCancelled(actionId);
        }

        action.status = ActionStatus.Cancelled;
        emit ActionCancelled(actionId);
        emit ActionStatusChanged(actionId, action.status, ActionStatus.Cancelled); // oldStatus would be Pending/Ready
    }

    /**
     * @notice Returns the current status of a conditional action.
     * @param actionId The ID of the action.
     * @return The status of the action (Pending, Ready, Executed, Cancelled, Failed).
     */
    function getActionStatus(uint256 actionId) public view returns (ActionStatus) {
        if (_actions[actionId].actionType == ActionType(0) && actionId != 0) {
            // Differentiate between unitialized (0) and not found
            if (actionId > _actionCounter || actionId == 0) return ActionStatus.Cancelled; // Arbitrarily return Cancelled for non-existent IDs
            // If actionId is <= _actionCounter but not found in mapping, something is wrong, but technically it doesn't exist.
            // Let's stick to checking the first element of the struct for non-zero ID.
            revert QuantumVault__ActionNotFound(actionId); // Or return a specific 'NotFound' status if enum allowed it.
        }
        return _actions[actionId].status;
    }

    /**
     * @notice Retrieves the details of a condition.
     * @param conditionId The ID of the condition.
     * @return conditionType The type of the condition.
     * @return params The encoded parameters of the condition.
     */
    function getConditionDetails(uint256 conditionId) public view returns (ConditionType conditionType, bytes memory params) {
        Condition storage cond = _conditions[conditionId];
        if (cond.conditionType == ConditionType(0) && conditionId != 0) {
             revert QuantumVault__ConditionNotFound(conditionId);
        }
        return (cond.conditionType, cond.params);
    }

     /**
     * @notice Retrieves the list of condition IDs required for a specific action.
     * @param actionId The ID of the action.
     * @return An array of condition IDs.
     */
    function getRequiredConditionsForAction(uint256 actionId) public view returns (uint256[] memory) {
        if (_actions[actionId].actionType == ActionType(0) && actionId != 0) {
             revert QuantumVault__ActionNotFound(actionId);
        }
        return _actions[actionId].requiredConditionIds;
    }


    // --- Advanced Features ---

    /**
     * @notice Simulates an update to the price feed for a specific ERC-20 token.
     * @dev In a real scenario, this would be called by a trusted oracle contract.
     * @param token The address of the ERC-20 token.
     * @param price The new simulated price (scaled, e.g., USD per token * 10^decimals).
     */
    function simulateOraclePriceUpdate(address token, uint256 price) public onlyOwner {
        _simulatedOraclePrices[token] = price;
        emit OraclePriceUpdated(token, price);
    }

    /**
     * @notice Adds an address that can submit approvals for MultiSigApproval conditions.
     * @param approver The address to add as an approver.
     */
    function addMultiSigApprover(address approver) public onlyOwner {
        _isMultiSigApprover[approver] = true;
        emit MultiSigApproverAdded(approver);
    }

    /**
     * @notice Removes an address from the multi-sig approver list.
     * @param approver The address to remove.
     */
    function removeMultiSigApprover(address approver) public onlyOwner {
        _isMultiSigApprover[approver] = false;
        // Note: This does not remove existing approvals, only prevents future ones.
        // A more complex implementation might clear approvals upon removal.
        emit MultiSigApproverRemoved(approver);
    }

    /**
     * @notice Submits an approval for a specific MultiSigApproval condition.
     * @param conditionId The ID of the MultiSigApproval condition.
     * @dev Can only be called by an address previously added via `addMultiSigApprover`.
     */
    function submitApprovalForCondition(uint256 conditionId) public {
        if (!_isMultiSigApprover[msg.sender]) {
            revert QuantumVault__NotAMultiSigApprover();
        }

        Condition storage cond = _conditions[conditionId];
        if (cond.conditionType != ConditionType.MultiSigApproval) {
            revert QuantumVault__InvalidConditionTypeForApproval(conditionId);
        }

        if (_conditionApprovals[conditionId][msg.sender]) {
            revert QuantumVault__AlreadyApproved(conditionId, msg.sender);
        }

        _conditionApprovals[conditionId][msg.sender] = true;
        _conditionApprovalCount[conditionId]++;

        emit ApprovalSubmitted(conditionId, msg.sender);
    }

    /**
     * @notice Checks if a specific MultiSigApproval condition has received enough approvals.
     * @param conditionId The ID of the condition.
     * @return A boolean indicating if the required number of approvals has been met.
     */
    function checkMultiSigConditionMet(uint256 conditionId) public view returns (bool) {
        Condition storage cond = _conditions[conditionId];
        if (cond.conditionType != ConditionType.MultiSigApproval) {
             revert QuantumVault__InvalidConditionTypeForApproval(conditionId);
        }
         (uint256 requiredApprovals) = abi.decode(cond.params, (uint256));
         return _conditionApprovalCount[conditionId] >= requiredApprovals;
    }

    /**
     * @notice Grants or revokes an address's ability to manage conditions (add/remove/update).
     * @param manager The address to delegate/revoke management rights.
     * @param canManage True to grant, false to revoke.
     */
    function delegateConditionManagement(address manager, bool canManage) public onlyOwner {
        _canManageConditions[manager] = canManage;
        emit ConditionManagerDelegated(manager, canManage);
    }

    /**
     * @notice Pauses the execution of *new* conditional actions.
     * @dev Actions that have already started execution will complete.
     */
    function pauseExecution() public onlyOwner whenNotPaused {
        _paused = true;
        emit ExecutionPaused();
    }

    /**
     * @notice Unpauses the execution of conditional actions.
     */
    function unpauseExecution() public onlyOwner {
        _paused = false;
        emit ExecutionUnpaused();
    }

    /**
     * @notice Checks if the contract is currently paused.
     */
    function getIsPaused() public view returns (bool) {
        return _paused;
    }

    // --- Owner Rescue/Withdrawal (use with caution) ---

    /**
     * @notice Allows the contract owner to withdraw a specific amount of ETH.
     * @dev Use primarily for emergencies or owner-controlled distribution outside of conditional actions.
     * @param amount The amount of ETH to withdraw.
     */
    function ownerWithdrawETH(uint256 amount) public onlyOwner {
        if (address(this).balance < amount) {
            revert QuantumVault__InsufficientBalance(address(0), amount, address(this).balance);
        }
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) {
             revert QuantumVault__TransferFailed();
        }
        emit OwnerWithdrawalETH(owner(), amount);
    }

    /**
     * @notice Allows the contract owner to withdraw a specific amount of an ERC-20 token.
     * @dev Use primarily for emergencies or owner-controlled distribution.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function ownerWithdrawERC20(address token, uint256 amount) public onlyOwner {
         if (IERC20(token).balanceOf(address(this)) < amount) {
             revert QuantumVault__InsufficientBalance(token, amount, IERC20(token).balanceOf(address(this)));
         }
        IERC20(token).safeTransfer(owner(), amount);
        emit OwnerWithdrawalERC20(owner(), token, amount);
    }

    /**
     * @notice Allows the contract owner to withdraw a specific ERC-721 token.
     * @dev Use primarily for emergencies or owner-controlled distribution.
     * @param token The address of the ERC-721 token contract.
     * @param tokenId The ID of the token to withdraw.
     */
    function ownerWithdrawERC721(address token, uint256 tokenId) public onlyOwner {
        if (!isERC721Deposited(token, tokenId)) {
            revert QuantumVault__ERC721NotHeld(token, tokenId);
        }
        IERC721(token).safeTransferFrom(address(this), owner(), tokenId);
        emit OwnerWithdrawalERC721(owner(), token, tokenId);
    }

    // --- Internal Helper for decoding condition parameters (if needed for internal use, not strictly required if decoding only happens in checkConditionMet) ---
    // This is just illustrative. The decoding happens within `checkConditionMet`.
    /*
    function _decodeConditionParams(uint256 conditionId) internal view returns (bytes memory) {
        Condition storage cond = _conditions[conditionId];
        if (cond.conditionType == ConditionType(0) && conditionId != 0) {
             revert QuantumVault__ConditionNotFound(conditionId);
        }
        return cond.params;
    }
    */
}
```