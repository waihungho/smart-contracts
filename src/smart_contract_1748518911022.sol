Okay, here is a Solidity smart contract concept for an "Autonomous Growth Vault". This contract aims to be creative and advanced by incorporating:

1.  **Internal Strategy Switching:** Based on simulated internal metrics or time, the contract can switch between different predefined strategies.
2.  **Simulated Autonomous Actions:** It has a function (`executeAutonomousLogic`) that *anyone* can call, but it only performs actions (like strategy switching, rebalancing, or yield simulation) if specific internal conditions are met. This offloads execution costs while maintaining on-chain decision-making.
3.  **Performance Tracking & Simulated Yield:** It tracks internal "performance" and simulates yield generation based on the active strategy, affecting the value per share.
4.  **Conditional Logic:** Actions within `executeAutonomousLogic` are conditional based on time, performance score, or other internal states.
5.  **Multi-Strategy Management:** Allows adding, updating, and managing multiple potential growth strategies.
6.  **Fee Collection:** Includes logic for collecting performance fees based on simulated growth.

**It's crucial to understand:** This contract simulates many complex real-world DeFi actions (like yield farming, rebalancing, strategy performance). A production version would interact with actual external DeFi protocols, oracles, etc., which would add significant complexity and require external calls. This example keeps the core autonomous *decision-making* logic on-chain within a self-contained structure.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title AutonomousGrowthVault
 * @dev A conceptual smart contract simulating an autonomous asset management vault.
 *      The vault holds a single ERC20 token and attempts to "grow" it based on internal,
 *      strategically driven logic. It's designed to showcase:
 *      - Internal state-based decision making (autonomous logic).
 *      - Switching between different simulated investment strategies.
 *      - Simulated yield generation and performance tracking.
 *      - Conditional execution triggered by external calls (keepers).
 *
 *      NOTE: This contract SIMULATES investment strategies and yield. A real-world
 *      contract would interact with external DeFi protocols (yield farms, DEXs, lending)
 *      which adds significant complexity (oracles, external calls, security risks).
 *      This is a self-contained example focusing on the autonomous decision layer.
 */

// --- OUTLINE ---
// 1. Imports (ERC20 interface, SafeERC20, Ownable, Pausable)
// 2. Errors
// 3. Events
// 4. Structs (Strategy, StrategyParameters)
// 5. State Variables (Ownership, Pausability, Token Info, Shares, Vault Value, Strategies, Autonomous Logic Parameters, Fees, Performance Metrics)
// 6. Modifiers (Internal conditional checks for autonomous logic)
// 7. Constructor
// 8. Core Vault Functionality (Deposit, Withdraw, Get Value/Shares)
// 9. Autonomous Logic Trigger & Execution (Main autonomous function, internal strategy application)
// 10. Strategy Management (Add, Update, Deactivate strategies)
// 11. Fee Management (Set fees, Collect fees)
// 12. Autonomous Logic Configuration (Set thresholds, intervals)
// 13. Keeper Management (Addresses allowed to trigger autonomous logic)
// 14. Emergency Functions (Pause, Emergency Withdraw)
// 15. View Functions (Get state variables, strategy info, performance metrics)

// --- FUNCTION SUMMARY ---
// Public / User Facing:
// 1. constructor(address _vaultTokenAddress) - Initializes the vault with the target token.
// 2. deposit(uint256 amount) - Deposits tokens into the vault, minting shares.
// 3. withdraw(uint256 shares) - Burns shares and withdraws proportional tokens from the vault.
// 4. executeAutonomousLogic() - Trigger function for autonomous actions. Can be called by anyone (or specific keepers) if internal conditions are met.
// 5. balanceOf(address account) view - Returns the number of vault shares held by an account.
// 6. getTotalValue() view - Returns the current simulated total value of the vault's tokens.
// 7. getPricePerShare() view - Returns the current simulated value of a single vault share.

// Admin / Owner Only:
// 8. addStrategy(uint256 strategyId, StrategyParameters calldata params) - Adds a new investment strategy.
// 9. updateStrategy(uint256 strategyId, StrategyParameters calldata params) - Updates an existing strategy's parameters.
// 10. deactivateStrategy(uint256 strategyId) - Deactivates a strategy, preventing it from being selected.
// 11. setCurrentStrategy(uint256 strategyId) - Manually sets the active strategy (bypassing autonomous logic for emergencies/manual control).
// 12. setAutonomousLogicInterval(uint256 interval) - Sets the minimum time between autonomous logic executions.
// 13. setPerformanceScoreThresholds(int256 switchThreshold, int256 rebalanceThreshold) - Sets thresholds for strategy switching and rebalancing based on performance score.
// 14. setPerformanceFeePercentage(uint256 feeBps) - Sets the performance fee percentage (in basis points).
// 15. setKeeper(address keeper, bool isAllowed) - Manages addresses allowed to call `executeAutonomousLogic`.
// 16. collectFees() - Allows the owner to collect accrued performance fees.
// 17. pause() - Pauses deposits, withdrawals, and autonomous logic.
// 18. unpause() - Unpauses the contract.
// 19. emergencyWithdraw(address tokenAddress, uint256 amount) - Allows owner to withdraw any token in emergencies.

// View Functions (Public):
// 20. getStrategyParameters(uint256 strategyId) view - Gets parameters for a specific strategy.
// 21. getCurrentStrategyId() view - Gets the ID of the currently active strategy.
// 22. getLastAutonomousExecutionTime() view - Gets the timestamp of the last autonomous logic execution.
// 23. getPerformanceScore() view - Gets the current simulated performance score.
// 24. getPerformanceFeePercentage() view - Gets the performance fee percentage.
// 25. getAccruedFees() view - Gets the total accrued performance fees ready for collection.
// 26. isKeeper(address account) view - Checks if an address is a designated keeper.

contract AutonomousGrowthVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- ERRORS ---
    error InvalidAmount();
    error InsufficientShares();
    error ZeroAddress();
    error StrategyNotFound();
    error StrategyNotActive();
    error AutonomousLogicConditionsNotMet();
    error InvalidFeePercentage();
    error NoFeesToCollect();

    // --- EVENTS ---
    event Deposit(address indexed account, uint256 amount, uint256 shares);
    event Withdrawal(address indexed account, uint256 shares, uint256 amount);
    event StrategyAdded(uint256 indexed strategyId, StrategyParameters params);
    event StrategyUpdated(uint256 indexed strategyId, StrategyParameters params);
    event StrategyDeactivated(uint256 indexed strategyId);
    event StrategySwitched(uint256 indexed oldStrategyId, uint256 indexed newStrategyId);
    event AutonomousLogicExecuted(uint256 indexed strategyId, int256 performanceScore, uint256 timeElapsed);
    event PerformanceFeeCollected(uint256 amount);
    event KeeperSet(address indexed keeper, bool isAllowed);
    event PerformanceScoreUpdated(int256 indexed newScore);

    // --- STRUCTS ---
    struct StrategyParameters {
        string name; // e.g., "Conservative", "Aggressive"
        uint256 simulatedBaseYieldRate; // Simulated yield per time unit (e.g., per second), scaled
        uint256 simulatedRiskFactor; // Simulated risk affecting performance score volatility
        bool isActive; // Whether the strategy is currently active and selectable
        bytes data; // Placeholder for potential future complex strategy parameters/data
    }

    // --- STATE VARIABLES ---
    IERC20 public immutable vaultToken;

    uint256 public totalShares;
    mapping(address => uint256) public shares;
    mapping(address => uint256) public depositedPrincipal; // Tracks initial deposit amount per user

    // Represents the total simulated value of the vault's assets including simulated yield.
    // This is the basis for calculating shares and withdrawals.
    // Starts equal to total supply of tokens deposited.
    uint256 public vaultTotalValue;

    // Strategy Management
    uint256 public currentStrategyId;
    mapping(uint256 => StrategyParameters) public strategies;
    uint256 private nextStrategyId = 1; // Start strategy IDs from 1

    // Autonomous Logic Parameters
    uint256 public lastAutonomousExecutionTime;
    uint256 public autonomousLogicInterval = 1 days; // Minimum time between executions
    int256 public performanceScore; // Simulated score reflecting strategy performance
    int256 public performanceScoreSwitchThreshold = -50; // Score below which strategy might switch
    int256 public performanceScoreRebalanceThreshold = 20; // Score above which a simulated rebalance might occur

    // Fee Parameters
    uint256 public performanceFeePercentageBps; // Performance fee in basis points (e.g., 1000 = 10%)
    uint256 public accruedFees; // Fees accumulated, ready for collection

    // Keeper Management
    mapping(address => bool) public isKeeper; // Addresses allowed to trigger executeAutonomousLogic

    // --- MODIFIERS ---

    /**
     * @dev Modifier to check if autonomous logic conditions are met.
     *      Can be called by anyone or specific keepers.
     */
    modifier autonomousConditionMet() {
        bool keeperAllowed = isKeeper[msg.sender];
        // Allow anyone if no specific keepers are set, OR if the sender is a keeper
        bool callerAllowed = totalKeepers == 0 || keeperAllowed;

        if (!callerAllowed) {
             revert AutonomousLogicConditionsNotMet(); // Or a more specific error like CallerNotKeeper()
        }

        if (block.timestamp < lastAutonomousExecutionTime + autonomousLogicInterval) {
            revert AutonomousLogicConditionsNotMet(); // Not enough time elapsed
        }

        // Add other potential conditions here (e.g., price feeds, internal metrics)
        // For this example, time is the primary trigger condition.

        _;
    }

    // Internal counter for keepers
    uint256 private totalKeepers = 0;

    // --- CONSTRUCTOR ---

    constructor(address _vaultTokenAddress) Ownable(msg.sender) Pausable(false) {
        if (_vaultTokenAddress == address(0)) revert ZeroAddress();
        vaultToken = IERC20(_vaultTokenAddress);
        lastAutonomousExecutionTime = block.timestamp; // Initialize last execution time
    }

    // --- CORE VAULT FUNCTIONALITY ---

    /**
     * @dev Deposits tokens into the vault and mints corresponding shares.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external whenNotPaused {
        if (amount == 0) revert InvalidAmount();

        uint256 sharesToMint;
        if (totalShares == 0) {
            // First deposit
            sharesToMint = amount;
            vaultTotalValue = amount; // Initial vault value equals deposited amount
        } else {
            // Calculate shares based on current value per share
            // sharesToMint = (amount * totalShares) / vaultTotalValue;
            // Using 1e18 scaling to maintain precision before division
            sharesToMint = (amount * totalShares * 1e18) / vaultTotalValue;
            sharesToMint = sharesToMint / 1e18; // Scale back
            if (sharesToMint == 0) revert InvalidAmount(); // Amount too small for a share
        }

        vaultToken.safeTransferFrom(msg.sender, address(this), amount);

        shares[msg.sender] += sharesToMint;
        totalShares += sharesToMint;
        depositedPrincipal[msg.sender] += amount; // Track principal

        // Update vault total value - important if yield accrued between deposits
        vaultTotalValue += amount; // Correctly reflect tokens added

        emit Deposit(msg.sender, amount, sharesToMint);
    }

    /**
     * @dev Withdraws tokens from the vault by burning shares.
     * @param sharesToBurn The number of shares to burn.
     */
    function withdraw(uint256 sharesToBurn) external whenNotPaused {
        if (sharesToBurn == 0) revert InsufficientShares();
        if (shares[msg.sender] < sharesToBurn) revert InsufficientShares();

        // Calculate the amount of tokens to withdraw based on current value per share
        // amountToWithdraw = (sharesToBurn * vaultTotalValue) / totalShares;
        // Using 1e18 scaling for precision
        uint256 amountToWithdraw = (sharesToBurn * vaultTotalValue * 1e18) / totalShares;
        amountToWithdraw = amountToWithdraw / 1e18; // Scale back

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        // Update vault total value BEFORE transfer
        vaultTotalValue -= amountToWithdraw;

        // Note: Tracking depositedPrincipal for withdrawal profit calculation is complex
        // as profit is shared among all holders. We won't update depositedPrincipal here.
        // P/L tracking would require per-user share value tracking over time, which is state-heavy.

        vaultToken.safeTransfer(msg.sender, amountToWithdraw);

        emit Withdrawal(msg.sender, sharesToBurn, amountToWithdraw);
    }

    /**
     * @dev Returns the current simulated total value of the vault's assets.
     *      This value increases with simulated yield.
     */
    function getTotalValue() public view returns (uint256) {
         // In this simulated contract, vaultTotalValue is updated by autonomous logic,
         // so it directly represents the current total value.
         // In a real contract, this would query actual token balances in various strategies/protocols.
         return vaultTotalValue;
    }

     /**
      * @dev Returns the current simulated price per share.
      *      Equivalent to vaultTotalValue / totalShares.
      *      Returns 1e18 (1 token) if totalShares is 0.
      */
     function getPricePerShare() public view returns (uint256) {
         if (totalShares == 0) {
             // Represents 1 share = 1 token initially
             return 1e18; // Standard token scaling
         }
         // Returns scaled value (e.g., 1.05 token value per share -> 1.05e18)
         return (vaultTotalValue * 1e18) / totalShares;
     }


    // --- AUTONOMOUS LOGIC TRIGGER & EXECUTION ---

    /**
     * @dev Triggers the autonomous logic execution.
     *      This function can be called by anyone (or designated keepers)
     *      but only executes the core logic if `autonomousConditionMet` is true.
     *      This allows externalizing the gas cost of maintenance calls.
     */
    function executeAutonomousLogic() external whenNotPaused autonomousConditionMet {
        uint256 timeElapsed = block.timestamp - lastAutonomousExecutionTime;

        // Simulate yield generation based on elapsed time and current strategy
        _simulateYield(timeElapsed);

        // Update performance score based on simulated activity (very basic simulation)
        _updatePerformanceScore(timeElapsed);

        // Apply strategy-specific actions or switch strategies based on performance/state
        _applyStrategyLogic();

        lastAutonomousExecutionTime = block.timestamp;
        emit AutonomousLogicExecuted(currentStrategyId, performanceScore, timeElapsed);
    }

    /**
     * @dev Internal function to simulate yield based on the current strategy.
     *      Increases `vaultTotalValue`.
     *      NOTE: Highly simplified simulation. Real logic would involve external calls.
     * @param timeElapsed Time in seconds since the last execution.
     */
    function _simulateYield(uint256 timeElapsed) internal {
        StrategyParameters storage currentParams = strategies[currentStrategyId];
        if (!currentParams.isActive) {
            // If current strategy somehow became inactive, simulate minimal or no yield
            // or revert/switch. For simplicity, let's just not add yield.
            return;
        }

        // Basic yield simulation: yield = value * rate * time
        // Rate is simulatedBaseYieldRate per second.
        // Add scaled yield to avoid precision loss early
        uint256 simulatedYield = (vaultTotalValue * currentParams.simulatedBaseYieldRate * timeElapsed) / 1e18; // simulatedBaseYieldRate is expected to be scaled (e.g., 1e18 = 100% per second, unlikely but illustrates scaling)

        vaultTotalValue += simulatedYield;

        // Accrue performance fees on the generated yield
        if (performanceFeePercentageBps > 0 && simulatedYield > 0) {
             uint256 feeAmount = (simulatedYield * performanceFeePercentageBps) / 10000; // 10000 for basis points
             accruedFees += feeAmount;
             // Note: Fees are removed from the vault's total value, effectively reducing value/share slightly
             // for all holders when they are accrued/collected.
             vaultTotalValue -= feeAmount; // Deduct fees from the value increase
        }
    }

    /**
     * @dev Internal function to update the simulated performance score.
     *      Score could be affected by simulated yield rate, risk factor, random elements (if oracle used).
     *      NOTE: Highly simplified simulation. Real performance would come from external data.
     * @param timeElapsed Time in seconds since the last execution.
     */
    function _updatePerformanceScore(uint256 timeElapsed) internal {
        StrategyParameters storage currentParams = strategies[currentStrategyId];
        if (!currentParams.isActive) {
             // If strategy inactive, maybe performance score decays or stays put
             performanceScore = performanceScore > 0 ? performanceScore - 1 : (performanceScore < 0 ? performanceScore + 1 : 0);
        } else {
            // Simulate score change based on strategy parameters and time
            // Example: Higher yield rate increases score, higher risk adds volatility
            int256 scoreChange = int256((currentParams.simulatedBaseYieldRate * timeElapsed) / 1e18 / 1e6); // Scale down impact
            // Add a simulated "risk" factor impact - could involve randomness with VRF in a real contract
            scoreChange += int256(currentParams.simulatedRiskFactor / 1e6) - int256(5); // Arbitrary risk impact simulation

            performanceScore += scoreChange;

            // Clamp score within a reasonable range
            if (performanceScore > 100) performanceScore = 100;
            if (performanceScore < -100) performanceScore = -100;
        }
         emit PerformanceScoreUpdated(performanceScore);
    }

    /**
     * @dev Internal function where autonomous decisions about strategy switching
     *      or simulated rebalancing would occur based on state variables like performanceScore.
     *      NOTE: Highly simplified. Real rebalancing/switching involves complex logic
     *      and potentially interacting with different strategies/protocols.
     */
    function _applyStrategyLogic() internal {
        StrategyParameters storage currentParams = strategies[currentStrategyId];

        // --- Simulated Decision Logic ---

        // 1. Strategy Switching Condition
        if (currentParams.isActive && performanceScore < performanceScoreSwitchThreshold) {
            uint256 bestNextStrategyId = 0;
            int256 bestNextScoreEstimate = -1000; // Start low

            // Simple example: Find the active strategy with potentially better simulated parameters
            // A real contract would need more sophisticated logic or oracle data
            for (uint256 i = 1; i < nextStrategyId; i++) {
                StrategyParameters storage nextParams = strategies[i];
                if (nextParams.isActive && i != currentStrategyId) {
                    // Very basic scoring: higher yield, lower risk (simplified combination)
                    int256 scoreEstimate = int256(nextParams.simulatedBaseYieldRate / 1e18) - int256(nextParams.simulatedRiskFactor / 1e18);
                    if (scoreEstimate > bestNextScoreEstimate) {
                        bestNextScoreEstimate = scoreEstimate;
                        bestNextStrategyId = i;
                    }
                }
            }

            if (bestNextStrategyId != 0 && bestNextStrategyId != currentStrategyId) {
                currentStrategyId = bestNextStrategyId;
                // Reset performance score on switch (optional, depends on strategy design)
                performanceScore = 0;
                emit StrategySwitched(currentStrategyId, bestNextStrategyId);
                emit PerformanceScoreUpdated(performanceScore);
                // In a real scenario, funds would be moved/rebalanced here
            }
        }
        // 2. Simulated Rebalancing/Optimization Condition
        // This is highly conceptual in this simulation. A real contract would
        // move assets between integrated protocols/strategies here.
        else if (currentParams.isActive && performanceScore > performanceScoreRebalanceThreshold) {
             // Simulate a successful optimization/rebalance -> maybe slightly boost yield for next period
             // In this simulation, we'll just reset performance score or apply a minor value boost (optional)
             performanceScore = performanceScoreRebalanceThreshold / 2; // Decay score after successful phase
             emit PerformanceScoreUpdated(performanceScore);
             // Example: vaultTotalValue could get a minor boost here if rebalancing is simulated as adding value
             // vaultTotalValue = (vaultTotalValue * 1005) / 1000; // Simulate 0.5% rebalance gain
             // Accrue fees on this simulated rebalance gain as well if applicable
        }
        // Add other conditions (e.g., time-based rebalancing, external trigger)
    }


    // --- STRATEGY MANAGEMENT (OWNER ONLY) ---

    /**
     * @dev Adds a new investment strategy. Requires unique ID.
     * @param strategyId The unique ID for the new strategy.
     * @param params The parameters for the strategy.
     */
    function addStrategy(uint256 strategyId, StrategyParameters calldata params) external onlyOwner {
        if (strategies[strategyId].isActive) revert StrategyNotFound(); // Check if ID is already used (assuming isActive is false by default)
        if (strategyId == 0) revert InvalidAmount(); // Reserve ID 0 or invalid ID

        strategies[strategyId] = params;
        strategies[strategyId].isActive = true; // Explicitly set active
        if (currentStrategyId == 0) {
            currentStrategyId = strategyId; // Set first added strategy as current
        }
        if (strategyId >= nextStrategyId) {
            nextStrategyId = strategyId + 1; // Keep track of potential next ID, though manual ID is used
        }

        emit StrategyAdded(strategyId, params);
    }

    /**
     * @dev Updates parameters for an existing strategy.
     * @param strategyId The ID of the strategy to update.
     * @param params The new parameters.
     */
    function updateStrategy(uint256 strategyId, StrategyParameters calldata params) external onlyOwner {
        if (!strategies[strategyId].isActive) revert StrategyNotFound();

        strategies[strategyId] = params;
        strategies[strategyId].isActive = true; // Ensure it stays active unless explicitly deactivated

        emit StrategyUpdated(strategyId, params);
    }

    /**
     * @dev Deactivates a strategy, preventing it from being selected autonomously.
     *      Does NOT change the current strategy if it's the one being deactivated.
     *      Use `setCurrentStrategy` to change the active strategy if needed.
     * @param strategyId The ID of the strategy to deactivate.
     */
    function deactivateStrategy(uint256 strategyId) external onlyOwner {
        if (!strategies[strategyId].isActive) revert StrategyNotFound();

        strategies[strategyId].isActive = false;

        emit StrategyDeactivated(strategyId);
    }

     /**
      * @dev Allows the owner to manually set the current active strategy.
      *      Overrides autonomous selection temporarily.
      *      Useful for emergencies or manual rebalancing.
      * @param strategyId The ID of the strategy to set as current.
      */
     function setCurrentStrategy(uint256 strategyId) external onlyOwner {
         if (!strategies[strategyId].isActive) revert StrategyNotActive();
         if (currentStrategyId == strategyId) return; // No change

         uint256 oldStrategyId = currentStrategyId;
         currentStrategyId = strategyId;
         // Optional: Reset performance score on manual switch
         performanceScore = 0;
         emit StrategySwitched(oldStrategyId, currentStrategyId);
         emit PerformanceScoreUpdated(performanceScore);
     }


    // --- FEE MANAGEMENT (OWNER ONLY) ---

    /**
     * @dev Sets the performance fee percentage in basis points.
     *      Fee is applied to simulated yield increases during autonomous execution.
     * @param feeBps Fee percentage in basis points (0-10000).
     */
    function setPerformanceFeePercentage(uint256 feeBps) external onlyOwner {
        if (feeBps > 10000) revert InvalidFeePercentage();
        performanceFeePercentageBps = feeBps;
    }

    /**
     * @dev Allows the owner or a designated collector to withdraw accrued performance fees.
     */
    function collectFees() external onlyOwner { // Could add a separate role for fee collector
        if (accruedFees == 0) revert NoFeesToCollect();
        uint256 fees = accruedFees;
        accruedFees = 0;
        vaultToken.safeTransfer(msg.sender, fees);
        emit PerformanceFeeCollected(fees);
    }


    // --- AUTONOMOUS LOGIC CONFIGURATION (OWNER ONLY) ---

    /**
     * @dev Sets the minimum time interval between autonomous logic executions.
     * @param interval Time in seconds.
     */
    function setAutonomousLogicInterval(uint256 interval) external onlyOwner {
        autonomousLogicInterval = interval;
    }

    /**
     * @dev Sets the performance score thresholds for strategy switching and rebalancing.
     * @param switchThreshold Score below which a switch might occur (e.g., -50).
     * @param rebalanceThreshold Score above which a rebalance might occur (e.g., +20).
     */
    function setPerformanceScoreThresholds(int256 switchThreshold, int256 rebalanceThreshold) external onlyOwner {
        performanceScoreSwitchThreshold = switchThreshold;
        performanceScoreRebalanceThreshold = rebalanceThreshold;
    }

     /**
      * @dev Sets an address as a keeper, allowing them to trigger `executeAutonomousLogic`.
      *      If no keepers are set, anyone can call it (subject to time interval).
      * @param keeper The address to set/unset as a keeper.
      * @param isAllowed Whether the address should be allowed (true) or disallowed (false).
      */
     function setKeeper(address keeper, bool isAllowed) external onlyOwner {
         if (keeper == address(0)) revert ZeroAddress();
         bool currentlyAllowed = isKeeper[keeper];
         if (currentlyAllowed == isAllowed) return; // No change needed

         isKeeper[keeper] = isAllowed;
         if (isAllowed) {
             totalKeepers++;
         } else {
             if (totalKeepers > 0) totalKeepers--; // Prevent underflow, though logic should ensure > 0
         }
         emit KeeperSet(keeper, isAllowed);
     }

     /**
      * @dev Removes an address from the list of keepers.
      * @param keeper The address to remove.
      */
     function removeKeeper(address keeper) external onlyOwner {
          setKeeper(keeper, false);
     }


    // --- EMERGENCY FUNCTIONS (OWNER ONLY) ---

    /**
     * @dev Pauses core actions (deposit, withdraw, autonomous logic).
     *      Does not affect owner-only config functions or emergencyWithdraw.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses core actions.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw any token from the contract in emergencies.
     *      Use with caution!
     * @param tokenAddress The address of the token to withdraw.
     * @param amount The amount to withdraw.
     */
    function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) revert ZeroAddress();
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, amount);
    }


    // --- VIEW FUNCTIONS ---

    /**
     * @dev Gets parameters for a specific strategy.
     * @param strategyId The ID of the strategy.
     */
    function getStrategyParameters(uint256 strategyId) external view returns (StrategyParameters memory) {
        // Note: Does not check isActive here, allows viewing parameters of inactive strategies
        return strategies[strategyId];
    }

    /**
     * @dev Gets the ID of the currently active strategy.
     */
    function getCurrentStrategyId() external view returns (uint256) {
        return currentStrategyId;
    }

    /**
     * @dev Gets the timestamp of the last autonomous logic execution.
     */
    function getLastAutonomousExecutionTime() external view returns (uint256) {
        return lastAutonomousExecutionTime;
    }

    /**
     * @dev Gets the current simulated performance score.
     */
    function getPerformanceScore() external view returns (int256) {
        return performanceScore;
    }

    /**
     * @dev Gets the current performance fee percentage in basis points.
     */
    function getPerformanceFeePercentage() external view returns (uint256) {
        return performanceFeePercentageBps;
    }

    /**
     * @dev Gets the total accrued performance fees ready for collection.
     */
    function getAccruedFees() external view returns (uint256) {
        return accruedFees;
    }

     /**
      * @dev Checks if an address is a designated keeper.
      */
     function isKeeper(address account) public view returns (bool) {
         return isKeeper[account];
     }
}
```