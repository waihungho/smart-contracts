Okay, here is a Solidity smart contract concept I've developed. It's designed to be a "Quantum Treasury" – not in the sense of using actual quantum computing (which isn't possible on the EVM), but in the sense that it manages multiple potential future states (strategies), reacts to external conditions (via a simulated oracle), and allows for sophisticated asset deployment based on rules and risk parameters.

It combines elements of multi-asset management, conditional execution, scheduled tasks, strategy patterns, and risk tagging, attempting to be more dynamic and proactive than a standard treasury or simple multisig.

It is designed to be complex and illustrative of advanced concepts, and it does *not* directly duplicate common open-source contracts like standard ERC-20, ERC-721, basic DAO voting, simple vesting, or standard AMM/lending logic.

---

**Outline:**

1.  **Contract Preamble:** SPDX License, Pragma, Imports (Ownable, ERC20).
2.  **Enums:** Define types for Strategy Status, Strategy Type, Risk Level.
3.  **Structs:** Define data structures for Strategies and Scheduled Tasks.
4.  **State Variables:**
    *   Owner
    *   Supported ERC20 tokens mapping
    *   Mapping of strategy IDs to Strategy structs
    *   Array of strategy IDs
    *   Mapping of scheduled task IDs to ScheduledTask structs
    *   Array of scheduled task IDs
    *   Counter for strategy IDs
    *   Counter for scheduled task IDs
    *   Global risk tolerance level
    *   Mapping for mock oracle data (for simulation purposes)
5.  **Events:** Define events for significant actions (Deposit, Withdrawal, StrategyAdded, StrategyExecuted, TaskScheduled, etc.).
6.  **Modifiers:** `onlyOwner`.
7.  **Constructor:** Initializes owner and global risk tolerance.
8.  **Receive Function:** Allows receiving native ETH.
9.  **Treasury Management Functions:**
    *   `depositEth`
    *   `depositERC20`
    *   `withdrawEth`
    *   `withdrawERC20`
    *   `getEthBalance`
    *   `getERC20Balance`
10. **Supported Token Management Functions:**
    *   `addSupportedToken`
    *   `removeSupportedToken`
    *   `isSupportedToken`
    *   `getSupportedTokens`
11. **Strategy Management Functions:**
    *   `addStrategy`
    *   `updateStrategy`
    *   `removeStrategy`
    *   `getStrategy`
    *   `listStrategyIds`
    *   `getStrategyCount`
    *   `pauseStrategy`
    *   `resumeStrategy`
12. **Strategy Execution Functions:**
    *   `executeStrategy` (Manual trigger)
    *   `checkAndExecuteStrategy` (Conditional trigger based on mock oracle/state)
    *   Internal `_executeStrategy` helper function
13. **Scheduled Task Functions:**
    *   `scheduleStrategy`
    *   `cancelScheduledStrategy`
    *   `getScheduledTask`
    *   `listScheduledTaskIds`
    *   `getScheduledTaskCount`
    *   `executeScheduledTask` (Must be called after schedule time)
    *   `isScheduledTaskActive`
14. **Risk Management Functions:**
    *   `setGlobalRiskTolerance`
    *   `getGlobalRiskTolerance`
15. **Mock Oracle Functions (for demonstration):**
    *   `setMockOracleData`
    *   `getMockOracleData`
    *   Internal `_checkConditions` helper function (uses mock data)
16. **Utility Functions:**
    *   `getOwner`

---

**Function Summary:**

1.  `depositEth()`: Allows anyone to deposit Ether into the treasury.
2.  `depositERC20(address tokenAddress, uint256 amount)`: Allows anyone to deposit a supported ERC20 token into the treasury. Requires prior approval.
3.  `withdrawEth(address payable recipient, uint256 amount)`: Owner-only function to withdraw native Ether from the treasury.
4.  `withdrawERC20(address tokenAddress, address recipient, uint256 amount)`: Owner-only function to withdraw a supported ERC20 token from the treasury.
5.  `getEthBalance()`: Returns the current native Ether balance of the contract.
6.  `getERC20Balance(address tokenAddress)`: Returns the current balance of a specific ERC20 token held by the contract.
7.  `addSupportedToken(address tokenAddress)`: Owner-only function to add an ERC20 token to the list of supported assets.
8.  `removeSupportedToken(address tokenAddress)`: Owner-only function to remove an ERC20 token from the list of supported assets.
9.  `isSupportedToken(address tokenAddress)`: Checks if a given token address is currently supported by the treasury.
10. `getSupportedTokens()`: Returns an array of all currently supported ERC20 token addresses.
11. `addStrategy(StrategyType strategyType, address targetToken, uint256 minAmount, uint256 maxAmount, RiskLevel riskLevel, bytes conditionData)`: Owner-only function to define and add a new strategy to the treasury's potential actions. Returns the new strategy ID.
12. `updateStrategy(uint256 strategyId, StrategyType strategyType, address targetToken, uint256 minAmount, uint256 maxAmount, RiskLevel riskLevel, bytes conditionData, bool isActive)`: Owner-only function to modify an existing strategy's parameters.
13. `removeStrategy(uint256 strategyId)`: Owner-only function to remove a strategy.
14. `getStrategy(uint256 strategyId)`: Returns the details of a specific strategy.
15. `listStrategyIds()`: Returns an array of all existing strategy IDs.
16. `getStrategyCount()`: Returns the total number of strategies defined.
17. `pauseStrategy(uint256 strategyId)`: Owner-only function to temporarily disable a strategy.
18. `resumeStrategy(uint256 strategyId)`: Owner-only function to re-enable a paused strategy.
19. `executeStrategy(uint256 strategyId)`: Owner-only function to manually trigger the execution of a specific strategy, *bypassing* condition checks (use with caution).
20. `checkAndExecuteStrategy(uint256 strategyId)`: Allows anyone (e.g., an automated relayer) to check if a strategy's conditions are met (using mock oracle/state) and execute it if they are, respecting risk levels and amounts.
21. `scheduleStrategy(uint256 strategyId, uint64 executionTime)`: Owner-only function to schedule a strategy execution for a future timestamp.
22. `cancelScheduledStrategy(uint256 taskId)`: Owner-only function to cancel a previously scheduled task.
23. `getScheduledTask(uint256 taskId)`: Returns the details of a specific scheduled task.
24. `listScheduledTaskIds()`: Returns an array of all existing scheduled task IDs.
25. `getScheduledTaskCount()`: Returns the total number of scheduled tasks.
26. `executeScheduledTask(uint256 taskId)`: Allows anyone (e.g., an automated relayer) to execute a scheduled task if the current time is past the scheduled time and the task hasn't been executed or cancelled.
27. `isScheduledTaskActive(uint256 taskId)`: Checks if a scheduled task is still pending execution.
28. `setGlobalRiskTolerance(RiskLevel tolerance)`: Owner-only function to set the overall risk appetite for strategy execution. Strategies exceeding this risk level will not execute via automated checks.
29. `getGlobalRiskTolerance()`: Returns the current global risk tolerance setting.
30. `setMockOracleData(bytes32 key, uint256 value)`: Owner-only function to simulate updating external oracle data. *For demonstration/testing only.*
31. `getMockOracleData(bytes32 key)`: Retrieves simulated oracle data. *For demonstration/testing only.*
32. `getOwner()`: Returns the address of the contract owner.

*(Note: This exceeds the minimum 20 functions requested, providing more capabilities.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title QuantumTreasury
 * @dev A sophisticated, dynamic treasury contract capable of holding multiple assets,
 *      defining parameterized strategies, executing actions based on conditions (simulated oracle),
 *      scheduling future tasks, and managing risk levels.
 *      "Quantum" refers to the management of multiple potential actions/states (strategies)
 *      and reaction to external "quantum" events (oracle data).
 *
 * Outline:
 * 1. Contract Preamble: SPDX License, Pragma, Imports (Ownable, ERC20, SafeERC20, ReentrancyGuard).
 * 2. Enums: Define types for Strategy Status, Strategy Type, Risk Level.
 * 3. Structs: Define data structures for Strategies and Scheduled Tasks.
 * 4. State Variables: Owner, Supported ERC20 tokens, Strategies mapping/array, Scheduled tasks mapping/array, Counters, Global risk tolerance, Mock oracle data.
 * 5. Events: Define events for significant actions.
 * 6. Modifiers: onlyOwner.
 * 7. Constructor: Initializes owner and global risk tolerance.
 * 8. Receive Function: Allows receiving native ETH.
 * 9. Treasury Management Functions (6 functions).
 * 10. Supported Token Management Functions (4 functions).
 * 11. Strategy Management Functions (8 functions).
 * 12. Strategy Execution Functions (3 functions, inc. internal).
 * 13. Scheduled Task Functions (7 functions).
 * 14. Risk Management Functions (2 functions).
 * 15. Mock Oracle Functions (3 functions, inc. internal).
 * 16. Utility Functions (1 function).
 *
 * Function Summary:
 * 1.  depositEth(): Deposit native Ether.
 * 2.  depositERC20(address tokenAddress, uint256 amount): Deposit supported ERC20.
 * 3.  withdrawEth(address payable recipient, uint256 amount): Withdraw Ether (Owner).
 * 4.  withdrawERC20(address tokenAddress, address recipient, uint256 amount): Withdraw ERC20 (Owner).
 * 5.  getEthBalance(): Get contract's ETH balance.
 * 6.  getERC20Balance(address tokenAddress): Get contract's ERC20 balance.
 * 7.  addSupportedToken(address tokenAddress): Add supported ERC20 (Owner).
 * 8.  removeSupportedToken(address tokenAddress): Remove supported ERC20 (Owner).
 * 9.  isSupportedToken(address tokenAddress): Check if token is supported.
 * 10. getSupportedTokens(): List supported tokens.
 * 11. addStrategy(...): Add a new strategy (Owner).
 * 12. updateStrategy(...): Update existing strategy (Owner).
 * 13. removeStrategy(uint256 strategyId): Remove strategy (Owner).
 * 14. getStrategy(uint256 strategyId): Get strategy details.
 * 15. listStrategyIds(): List all strategy IDs.
 * 16. getStrategyCount(): Get total strategy count.
 * 17. pauseStrategy(uint256 strategyId): Pause a strategy (Owner).
 * 18. resumeStrategy(uint256 strategyId): Resume a strategy (Owner).
 * 19. executeStrategy(uint256 strategyId): Manually execute strategy (Owner, bypasses conditions).
 * 20. checkAndExecuteStrategy(uint256 strategyId): Check conditions and execute strategy (Any, checks conditions).
 * 21. scheduleStrategy(uint256 strategyId, uint64 executionTime): Schedule strategy execution (Owner).
 * 22. cancelScheduledStrategy(uint256 taskId): Cancel scheduled task (Owner).
 * 23. getScheduledTask(uint256 taskId): Get scheduled task details.
 * 24. listScheduledTaskIds(): List all scheduled task IDs.
 * 25. getScheduledTaskCount(): Get total scheduled task count.
 * 26. executeScheduledTask(uint256 taskId): Execute scheduled task (Any, after time).
 * 27. isScheduledTaskActive(uint256 taskId): Check if scheduled task is active.
 * 28. setGlobalRiskTolerance(RiskLevel tolerance): Set global risk tolerance (Owner).
 * 29. getGlobalRiskTolerance(): Get global risk tolerance.
 * 30. setMockOracleData(bytes32 key, uint256 value): Simulate setting oracle data (Owner).
 * 31. getMockOracleData(bytes32 key): Get simulated oracle data.
 * 32. getOwner(): Get contract owner.
 */
contract QuantumTreasury is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Enums ---

    enum StrategyStatus {
        Active,
        Paused,
        Removed // Logically removed, entry might still exist but inactive
    }

    // Example Strategy Types - extend as needed for complex actions (Swap, Deposit, etc.)
    enum StrategyType {
        SendToken // Example: Simply sends a targetToken amount to an address specified in conditionData
    }

    enum RiskLevel {
        Low,
        Medium,
        High,
        Experimental
    }

    // --- Structs ---

    struct Strategy {
        uint256 id;
        StrategyType strategyType;
        address targetToken; // Token address to be used by the strategy (e.g., token to send)
        uint256 minAmount; // Minimum amount of targetToken to use
        uint256 maxAmount; // Maximum amount of targetToken to use (capped by balance)
        RiskLevel riskLevel;
        StrategyStatus status;
        // Condition parameters (using mock oracle pattern for this example)
        bytes32 conditionOracleKey; // Key for the mock oracle data
        uint256 conditionThreshold; // Threshold value to check against oracle data
        bool conditionCheckGreaterThan; // true: check if oracleData > threshold, false: check if oracleData <= threshold
        bytes strategyData; // Arbitrary data specific to the strategyType (e.g., recipient address for SendToken)
    }

    struct ScheduledTask {
        uint256 id;
        uint256 strategyId;
        uint64 executionTime; // Unix timestamp
        bool executed;
        bool cancelled;
    }

    // --- State Variables ---

    mapping(address => bool) private supportedTokens;
    address[] private supportedTokenList; // To easily list supported tokens

    mapping(uint256 => Strategy) private strategies;
    uint256[] private strategyIds; // To easily list strategy IDs
    uint256 private nextStrategyId = 1;

    mapping(uint256 => ScheduledTask) private scheduledTasks;
    uint256[] private scheduledTaskIds; // To easily list task IDs
    uint256 private nextTaskId = 1;

    RiskLevel public globalRiskTolerance;

    // Mock Oracle Data (for demonstration purposes)
    mapping(bytes32 => uint256) private mockOracleData;

    // --- Events ---

    event EtherDeposited(address indexed sender, uint256 amount);
    event ERC20Deposited(address indexed token, address indexed sender, uint256 amount);
    event EtherWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Withdrawn(address indexed token, address indexed recipient, uint256 amount);
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event StrategyAdded(uint256 indexed strategyId, StrategyType indexed strategyType, RiskLevel indexed riskLevel);
    event StrategyUpdated(uint256 indexed strategyId);
    event StrategyRemoved(uint256 indexed strategyId);
    event StrategyPaused(uint256 indexed strategyId);
    event StrategyResumed(uint256 indexed strategyId);
    event StrategyExecuted(uint256 indexed strategyId, StrategyType indexed strategyType, uint256 amountUsed);
    event TaskScheduled(uint256 indexed taskId, uint256 indexed strategyId, uint64 executionTime);
    event TaskCancelled(uint256 indexed taskId);
    event TaskExecuted(uint256 indexed taskId, uint256 indexed strategyId);
    event GlobalRiskToleranceUpdated(RiskLevel indexed tolerance);
    event MockOracleDataUpdated(bytes32 indexed key, uint256 value);

    // --- Constructor ---

    constructor(RiskLevel initialRiskTolerance) Ownable(msg.sender) {
        globalRiskTolerance = initialRiskTolerance;
    }

    // --- Receive Function ---

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    // --- Treasury Management Functions ---

    /**
     * @dev Deposits native Ether into the treasury.
     */
    function depositEth() external payable nonReentrant {
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Deposits a supported ERC20 token into the treasury.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address tokenAddress, uint256 amount) external nonReentrant {
        require(supportedTokens[tokenAddress], "Token not supported");
        require(amount > 0, "Amount must be positive");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Withdraws native Ether from the treasury. Owner only.
     * @param recipient The address to send the Ether to.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawEth(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(address(this).balance >= amount, "Insufficient ETH balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
        emit EtherWithdrawn(recipient, amount);
    }

    /**
     * @dev Withdraws a supported ERC20 token from the treasury. Owner only.
     * @param tokenAddress The address of the ERC20 token.
     * @param recipient The address to send the tokens to.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address tokenAddress, address recipient, uint256 amount) external onlyOwner nonReentrant {
        require(supportedTokens[tokenAddress], "Token not supported");
        require(amount > 0, "Amount must be positive");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.safeTransfer(recipient, amount);
        emit ERC20Withdrawn(tokenAddress, recipient, amount);
    }

    /**
     * @dev Returns the current native Ether balance of the contract.
     */
    function getEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the current balance of a specific ERC20 token held by the contract.
     * @param tokenAddress The address of the ERC20 token.
     */
    function getERC20Balance(address tokenAddress) external view returns (uint256) {
        require(supportedTokens[tokenAddress], "Token not supported");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // --- Supported Token Management Functions ---

    /**
     * @dev Adds an ERC20 token to the list of supported assets. Owner only.
     * @param tokenAddress The address of the ERC20 token.
     */
    function addSupportedToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(!supportedTokens[tokenAddress], "Token already supported");
        supportedTokens[tokenAddress] = true;
        supportedTokenList.push(tokenAddress);
        emit SupportedTokenAdded(tokenAddress);
    }

    /**
     * @dev Removes an ERC20 token from the list of supported assets. Owner only.
     * @param tokenAddress The address of the ERC20 token.
     */
    function removeSupportedToken(address tokenAddress) external onlyOwner {
        require(supportedTokens[tokenAddress], "Token not supported");
        supportedTokens[tokenAddress] = false;
        // Simple removal from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < supportedTokenList.length; i++) {
            if (supportedTokenList[i] == tokenAddress) {
                supportedTokenList[i] = supportedTokenList[supportedTokenList.length - 1];
                supportedTokenList.pop();
                break;
            }
        }
        emit SupportedTokenRemoved(tokenAddress);
    }

    /**
     * @dev Checks if a given token address is currently supported by the treasury.
     * @param tokenAddress The address of the ERC20 token.
     */
    function isSupportedToken(address tokenAddress) external view returns (bool) {
        return supportedTokens[tokenAddress];
    }

    /**
     * @dev Returns an array of all currently supported ERC20 token addresses.
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokenList;
    }

    // --- Strategy Management Functions ---

    /**
     * @dev Defines and adds a new strategy to the treasury's potential actions. Owner only.
     * @param strategyType The type of strategy (e.g., SendToken).
     * @param targetToken The token involved in the strategy.
     * @param minAmount Minimum amount for the strategy execution.
     * @param maxAmount Maximum amount for the strategy execution (capped by balance).
     * @param riskLevel The risk level associated with this strategy.
     * @param conditionData Arbitrary data defining the condition (e.g., oracle key, threshold, comparison type). Bytes format for flexibility.
     * @return The ID of the newly added strategy.
     */
    function addStrategy(
        StrategyType strategyType,
        address targetToken,
        uint256 minAmount,
        uint256 maxAmount,
        RiskLevel riskLevel,
        bytes memory conditionData // Encoded condition parameters
    ) external onlyOwner returns (uint256) {
        require(targetToken != address(0), "Invalid target token address");
        if (strategyType == StrategyType.SendToken) {
             require(supportedTokens[targetToken], "Target token not supported for SendToken strategy");
             require(conditionData.length == 53, "Invalid conditionData for SendToken strategy"); // bytes32 key + uint256 threshold + bool comparison + address recipient
        }
        require(minAmount <= maxAmount, "minAmount cannot exceed maxAmount");

        uint256 strategyId = nextStrategyId++;
        (bytes32 conditionKey, uint256 conditionThresholdValue, bool conditionGreater) = _decodeConditionData(conditionData);

        strategies[strategyId] = Strategy({
            id: strategyId,
            strategyType: strategyType,
            targetToken: targetToken,
            minAmount: minAmount,
            maxAmount: maxAmount,
            riskLevel: riskLevel,
            status: StrategyStatus.Active,
            conditionOracleKey: conditionKey,
            conditionThreshold: conditionThresholdValue,
            conditionCheckGreaterThan: conditionGreater,
            strategyData: conditionData // Store full condition data including recipient for SendToken
        });
        strategyIds.push(strategyId);

        emit StrategyAdded(strategyId, strategyType, riskLevel);
        return strategyId;
    }

     /**
     * @dev Updates an existing strategy's parameters. Owner only.
     * @param strategyId The ID of the strategy to update.
     * @param strategyType The type of strategy.
     * @param targetToken The token involved.
     * @param minAmount Minimum amount.
     * @param maxAmount Maximum amount.
     * @param riskLevel The risk level.
     * @param conditionData Arbitrary data defining the condition.
     * @param isActive New active status.
     */
    function updateStrategy(
        uint256 strategyId,
        StrategyType strategyType,
        address targetToken,
        uint256 minAmount,
        uint256 maxAmount,
        RiskLevel riskLevel,
        bytes memory conditionData,
        bool isActive
    ) external onlyOwner {
        require(strategies[strategyId].id != 0, "Strategy not found"); // Check if strategy exists
        require(strategies[strategyId].status != StrategyStatus.Removed, "Strategy is removed");

        require(targetToken != address(0), "Invalid target token address");
         if (strategyType == StrategyType.SendToken) {
             require(supportedTokens[targetToken], "Target token not supported for SendToken strategy");
             require(conditionData.length == 53, "Invalid conditionData for SendToken strategy"); // bytes32 key + uint256 threshold + bool comparison + address recipient
        }
        require(minAmount <= maxAmount, "minAmount cannot exceed maxAmount");

        (bytes32 conditionKey, uint256 conditionThresholdValue, bool conditionGreater) = _decodeConditionData(conditionData);


        strategies[strategyId].strategyType = strategyType;
        strategies[strategyId].targetToken = targetToken;
        strategies[strategyId].minAmount = minAmount;
        strategies[strategyId].maxAmount = maxAmount;
        strategies[strategyId].riskLevel = riskLevel;
        strategies[strategyId].status = isActive ? StrategyStatus.Active : StrategyStatus.Paused;
        strategies[strategyId].conditionOracleKey = conditionKey;
        strategies[strategyId].conditionThreshold = conditionThresholdValue;
        strategies[strategyId].conditionCheckGreaterThan = conditionGreater;
        strategies[strategyId].strategyData = conditionData; // Update arbitrary data


        emit StrategyUpdated(strategyId);
    }

    /**
     * @dev Removes a strategy. Owner only. Mark as removed rather than deleting to preserve ID integrity.
     * @param strategyId The ID of the strategy to remove.
     */
    function removeStrategy(uint256 strategyId) external onlyOwner {
        require(strategies[strategyId].id != 0, "Strategy not found");
        strategies[strategyId].status = StrategyStatus.Removed;

         // Simple removal from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < strategyIds.length; i++) {
            if (strategyIds[i] == strategyId) {
                strategyIds[i] = strategyIds[strategyIds.length - 1];
                strategyIds.pop();
                break;
            }
        }

        // Cancel any scheduled tasks using this strategy
        for (uint i = 0; i < scheduledTaskIds.length; i++) {
            uint256 taskId = scheduledTaskIds[i];
            if (scheduledTasks[taskId].strategyId == strategyId && !scheduledTasks[taskId].executed && !scheduledTasks[taskId].cancelled) {
                scheduledTasks[taskId].cancelled = true;
                emit TaskCancelled(taskId);
            }
        }

        emit StrategyRemoved(strategyId);
    }

    /**
     * @dev Gets the details of a specific strategy.
     * @param strategyId The ID of the strategy.
     * @return The Strategy struct.
     */
    function getStrategy(uint256 strategyId) external view returns (Strategy memory) {
        require(strategies[strategyId].id != 0, "Strategy not found");
        return strategies[strategyId];
    }

     /**
     * @dev Returns an array of all existing strategy IDs (excluding removed ones from the list).
     */
    function listStrategyIds() external view returns (uint256[] memory) {
        return strategyIds;
    }

    /**
     * @dev Returns the total number of strategies (including paused/removed, based on next ID counter).
     * Note: Use listStrategyIds().length for count of non-removed strategies.
     */
    function getStrategyCount() external view returns (uint256) {
        return nextStrategyId - 1;
    }

    /**
     * @dev Pauses an active strategy. Owner only.
     * @param strategyId The ID of the strategy to pause.
     */
    function pauseStrategy(uint256 strategyId) external onlyOwner {
        require(strategies[strategyId].id != 0, "Strategy not found");
        require(strategies[strategyId].status == StrategyStatus.Active, "Strategy is not active");
        strategies[strategyId].status = StrategyStatus.Paused;
        emit StrategyPaused(strategyId);
    }

    /**
     * @dev Resumes a paused strategy. Owner only.
     * @param strategyId The ID of the strategy to resume.
     */
    function resumeStrategy(uint256 strategyId) external onlyOwner {
        require(strategies[strategyId].id != 0, "Strategy not found");
        require(strategies[strategyId].status == StrategyStatus.Paused, "Strategy is not paused");
        strategies[strategyId].status = StrategyStatus.Active;
        emit StrategyResumed(strategyId);
    }


    // --- Strategy Execution Functions ---

     /**
     * @dev Manually executes a strategy. Owner only.
     *      This bypasses condition checks and risk tolerance settings. Use with caution.
     * @param strategyId The ID of the strategy to execute.
     */
    function executeStrategy(uint256 strategyId) external onlyOwner nonReentrant {
        require(strategies[strategyId].id != 0, "Strategy not found");
        require(strategies[strategyId].status == StrategyStatus.Active || strategies[strategyId].status == StrategyStatus.Paused, "Strategy is removed"); // Allow executing paused manually
        // Manual execution bypasses conditions and risk check
        _executeStrategy(strategyId, strategies[strategyId].strategyData);
    }


    /**
     * @dev Checks if a strategy's conditions are met and executes it if allowed by risk tolerance.
     *      Can be called by anyone (e.g., automated relayer).
     * @param strategyId The ID of the strategy to check and execute.
     */
    function checkAndExecuteStrategy(uint256 strategyId) external nonReentrant {
        Strategy storage strategy = strategies[strategyId];
        require(strategy.id != 0, "Strategy not found");
        require(strategy.status == StrategyStatus.Active, "Strategy not active");

        // Check risk tolerance
        require(strategy.riskLevel <= globalRiskTolerance, "Strategy risk exceeds global tolerance");

        // Check conditions using mock oracle pattern
        require(_checkConditions(strategy.conditionOracleKey, strategy.conditionThreshold, strategy.conditionCheckGreaterThan), "Strategy conditions not met");

        // Execute the strategy
        _executeStrategy(strategyId, strategy.strategyData);
    }

    /**
     * @dev Internal helper function to execute the logic of a strategy.
     *      Handles different strategy types based on strategy.strategyType.
     * @param strategyId The ID of the strategy being executed.
     * @param strategyData Arbitrary data specific to the strategy type.
     */
    function _executeStrategy(uint256 strategyId, bytes memory strategyData) internal {
        Strategy storage strategy = strategies[strategyId];
        uint256 amountToUse = strategy.maxAmount; // Default to max, cap by balance

        if (strategy.targetToken != address(0)) {
             uint256 tokenBalance = IERC20(strategy.targetToken).balanceOf(address(this));
             if (amountToUse > tokenBalance) {
                 amountToUse = tokenBalance; // Cap by available balance
             }
             require(amountToUse >= strategy.minAmount, "Amount to use below minimum required");
        } else {
             // Handle ETH strategies or strategies without a target token if needed later
             require(strategy.strategyType != StrategyType.SendToken, "SendToken requires a targetToken");
             amountToUse = 0; // No token amount for this type
        }

        // Execute logic based on strategy type
        if (strategy.strategyType == StrategyType.SendToken) {
            // Expect strategyData to be ABI-encoded (bytes32 key, uint256 threshold, bool comparison, address recipient)
            require(strategyData.length == 53, "Invalid strategyData for SendToken");
            address recipient;
            // Decode only the recipient part from strategyData (last 20 bytes of a 32-byte word)
            assembly {
                 recipient := and(mload(add(strategyData, 0x20)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
             require(recipient != address(0), "Invalid recipient address in strategyData");
             require(strategy.targetToken != address(0), "SendToken strategy must have a targetToken");

             IERC20 token = IERC20(strategy.targetToken);
             token.safeTransfer(recipient, amountToUse);

             emit StrategyExecuted(strategyId, strategy.strategyType, amountToUse);

        } else {
            // Handle other strategy types here
            revert("Unsupported strategy type");
        }
    }

    // --- Scheduled Task Functions ---

    /**
     * @dev Schedules a strategy execution for a future timestamp. Owner only.
     * @param strategyId The ID of the strategy to schedule.
     * @param executionTime The Unix timestamp when the strategy should be executable.
     */
    function scheduleStrategy(uint256 strategyId, uint64 executionTime) external onlyOwner returns (uint256) {
        require(strategies[strategyId].id != 0, "Strategy not found");
        require(strategies[strategyId].status == StrategyStatus.Active, "Strategy not active");
        require(executionTime > block.timestamp, "Execution time must be in the future");

        uint256 taskId = nextTaskId++;
        scheduledTasks[taskId] = ScheduledTask({
            id: taskId,
            strategyId: strategyId,
            executionTime: executionTime,
            executed: false,
            cancelled: false
        });
        scheduledTaskIds.push(taskId);

        emit TaskScheduled(taskId, strategyId, executionTime);
        return taskId;
    }

    /**
     * @dev Cancels a previously scheduled task. Owner only.
     * @param taskId The ID of the task to cancel.
     */
    function cancelScheduledStrategy(uint256 taskId) external onlyOwner {
        require(scheduledTasks[taskId].id != 0, "Task not found");
        require(!scheduledTasks[taskId].executed, "Task already executed");
        require(!scheduledTasks[taskId].cancelled, "Task already cancelled");

        scheduledTasks[taskId].cancelled = true;

        // Simple removal from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < scheduledTaskIds.length; i++) {
            if (scheduledTaskIds[i] == taskId) {
                scheduledTaskIds[i] = scheduledTaskIds[scheduledTaskIds.length - 1];
                scheduledTaskIds.pop();
                break;
            }
        }

        emit TaskCancelled(taskId);
    }

    /**
     * @dev Gets the details of a specific scheduled task.
     * @param taskId The ID of the task.
     * @return The ScheduledTask struct.
     */
    function getScheduledTask(uint256 taskId) external view returns (ScheduledTask memory) {
        require(scheduledTasks[taskId].id != 0, "Task not found");
        return scheduledTasks[taskId];
    }

    /**
     * @dev Returns an array of all existing scheduled task IDs (excluding executed/cancelled from the list).
     */
    function listScheduledTaskIds() external view returns (uint256[] memory) {
        return scheduledTaskIds;
    }

    /**
     * @dev Returns the total number of scheduled tasks (including executed/cancelled, based on next ID counter).
     * Note: Use listScheduledTaskIds().length for count of non-executed/cancelled tasks.
     */
    function getScheduledTaskCount() external view returns (uint256) {
        return nextTaskId - 1;
    }

     /**
     * @dev Executes a scheduled task if the current time is past the scheduled time.
     *      Can be called by anyone (e.g., automated relayer).
     *      Strategy conditions/risk are NOT checked here, only the schedule time and task status.
     * @param taskId The ID of the task to execute.
     */
    function executeScheduledTask(uint256 taskId) external nonReentrant {
        ScheduledTask storage task = scheduledTasks[taskId];
        require(task.id != 0, "Task not found");
        require(!task.executed, "Task already executed");
        require(!task.cancelled, "Task cancelled");
        require(block.timestamp >= task.executionTime, "Execution time not reached");

        Strategy storage strategy = strategies[task.strategyId];
        require(strategy.id != 0, "Strategy not found for task");
        // Note: This execution does NOT check strategy status, risk, or conditions.
        // It assumes scheduling implies intent to execute when time comes.
        // If conditions/risk should be checked, use checkAndExecuteStrategy in conjunction with scheduling.
        // This provides a simpler time-based trigger.

        task.executed = true; // Mark as executed BEFORE calling the strategy
        emit TaskExecuted(taskId, task.strategyId);

         // Simple removal from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < scheduledTaskIds.length; i++) {
            if (scheduledTaskIds[i] == taskId) {
                scheduledTaskIds[i] = scheduledTaskIds[scheduledTaskIds.length - 1];
                scheduledTaskIds.pop();
                break;
            }
        }


        _executeStrategy(task.strategyId, strategy.strategyData); // Execute the linked strategy
    }

    /**
     * @dev Checks if a scheduled task is still pending execution.
     * @param taskId The ID of the task.
     * @return True if the task exists, is not executed, and is not cancelled.
     */
    function isScheduledTaskActive(uint256 taskId) external view returns (bool) {
         return scheduledTasks[taskId].id != 0 && !scheduledTasks[taskId].executed && !scheduledTasks[taskId].cancelled;
    }

    // --- Risk Management Functions ---

    /**
     * @dev Sets the global risk tolerance for automated strategy execution. Owner only.
     * @param tolerance The new global risk tolerance level.
     */
    function setGlobalRiskTolerance(RiskLevel tolerance) external onlyOwner {
        globalRiskTolerance = tolerance;
        emit GlobalRiskToleranceUpdated(tolerance);
    }

    /**
     * @dev Gets the current global risk tolerance setting.
     * @return The current global risk tolerance level.
     */
    function getGlobalRiskTolerance() external view returns (RiskLevel) {
        return globalRiskTolerance;
    }

    // --- Mock Oracle Functions (for demonstration) ---
    // In a real contract, this would interact with a decentralized oracle network (Chainlink, etc.)

    /**
     * @dev Simulates setting external oracle data. Owner only. For testing/demo.
     * @param key A bytes32 key identifying the data feed (e.g., keccak256("ETH/USD")).
     * @param value The data value.
     */
    function setMockOracleData(bytes32 key, uint256 value) external onlyOwner {
        mockOracleData[key] = value;
        emit MockOracleDataUpdated(key, value);
    }

    /**
     * @dev Retrieves simulated oracle data. For testing/demo.
     * @param key A bytes32 key identifying the data feed.
     * @return The data value.
     */
    function getMockOracleData(bytes32 key) public view returns (uint256) {
        // In a real oracle, this would call the oracle contract
        return mockOracleData[key];
    }

     /**
     * @dev Internal helper to check conditions using mock oracle data.
     * @param key The oracle data key.
     * @param threshold The threshold value.
     * @param greaterThan True if checking data > threshold, false if data <= threshold.
     * @return True if conditions are met.
     */
    function _checkConditions(bytes32 key, uint256 threshold, bool greaterThan) internal view returns (bool) {
        uint256 oracleData = getMockOracleData(key); // Use internal getter
        if (greaterThan) {
            return oracleData > threshold;
        } else {
            return oracleData <= threshold;
        }
    }

    /**
     * @dev Internal helper to decode condition data bytes.
     *      Expected format: abi.encodePacked(bytes32 oracleKey, uint256 threshold, bool greaterThan, address recipient)
     *      Note: This specific decoding logic is tied to the SendToken strategyData structure.
     *      More complex strategies would need more sophisticated decoding or a different pattern.
     */
    function _decodeConditionData(bytes memory data) internal pure returns (bytes32 key, uint256 threshold, bool greaterThan) {
         require(data.length >= 32 + 32 + 1, "Invalid conditionData length"); // bytes32 + uint256 + bool (at least)

         assembly {
             // Read bytes32 key (first 32 bytes)
             key := mload(add(data, 0x20))
             // Read uint256 threshold (next 32 bytes)
             threshold := mload(add(data, 0x40))
             // Read bool greaterThan (next byte, potentially padded)
             // We load 32 bytes and take the last byte
             greaterThan := byte(0, mload(add(data, 0x60))) // Bool is stored as 1 or 0 at the end of a 32-byte word
         }
         // Note: Recipient address for SendToken is part of the full strategyData,
         // but not needed for the general condition check decoding.
    }


    // --- Utility Functions ---

    /**
     * @dev Returns the address of the contract owner.
     */
    function getOwner() external view returns (address) {
        return owner(); // Inherited from Ownable
    }

    // fallback() external payable {
    //     // Optional: Add logic here if you want to handle ETH sent without calling receive()
    //     emit EtherDeposited(msg.sender, msg.value);
    // }
}
```