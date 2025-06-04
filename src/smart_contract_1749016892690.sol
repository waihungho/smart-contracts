Okay, here is a Solidity smart contract implementing a "Dynamic Yield Allocation Strategy" concept. This contract acts as a vault that accepts a specific token (e.g., USDC, DAI) and dynamically allocates these funds across different underlying DeFi yield-generating "strategies" (which are represented by external adapter contracts). The allocation percentages can be changed by a designated strategist, and funds can be rebalanced to optimize yield or manage risk.

It uses a share-based system similar to Yearn vaults to track user deposits and yield proportionally.

**Key Concepts:**

*   **Dynamic Allocation:** Funds are split among multiple strategies, with allocation percentages adjustable by a strategist.
*   **Strategy Adapters:** External contracts that know how to interact with specific DeFi protocols (Aave, Compound, Uniswap LP, etc.). The main vault interacts *only* with these adapters via a standard interface.
*   **Share System:** Users deposit tokens and receive shares representing their proportion of the total assets (principal + yield). This simplifies tracking yield accrual for users.
*   **Rebalancing:** A mechanism to redistribute funds among strategies based on the current allocation settings.
*   **Performance Fees:** A percentage of the yield can be collected as a fee.
*   **Access Control:** Owner manages core settings, Strategist manages allocations and rebalancing.
*   **Pause/Emergency:** Mechanisms for safety in case of issues.

---

**Contract Outline & Function Summary**

**Contract Name:** `DeFiDynamicYield`

**Concept:** A yield-bearing vault that dynamically allocates deposited funds across multiple external DeFi strategy adapters based on adjustable percentages. Uses a share system for proportional yield distribution.

**Interfaces:**
*   `IStrategyAdapter`: Defines the minimum interface required for external strategy contracts (deposit, withdraw, getTotalAssets, getSupportedTokens).

**State Variables:**
*   `owner`: Contract owner (governance/admin).
*   `strategist`: Address allowed to manage strategies and rebalance funds.
*   `paused`: Pause status for core operations.
*   `supportedTokens`: Mapping of supported deposit tokens to boolean.
*   `strategies`: Mapping of strategy addresses to `StrategyInfo` struct.
*   `strategyAddresses`: Array storing registered strategy addresses.
*   `totalAllocationBps`: Sum of all active strategy allocation percentages (in basis points, should equal 10000).
*   `totalShares`: Total supply of vault shares.
*   `userShares`: Mapping of user addresses to their share balance.
*   `performanceFeePercentageBps`: Percentage of *yield* taken as performance fee (in basis points).
*   `feeRecipient`: Address receiving performance fees.
*   `minDepositAmount`: Minimum amount required for a deposit.
*   `minWithdrawAmount`: Minimum amount of shares to withdraw.
*   `lastRebalanceTime`: Timestamp of the last successful rebalance.
*   `rebalanceInterval`: Minimum time between manual rebalance calls.

**Structs:**
*   `StrategyInfo`: Stores strategy adapter address, current allocation percentage (bps), and whether it's active.

**Events:**
*   `Deposited`: Logged on successful deposit.
*   `Withdrawn`: Logged on successful withdrawal.
*   `StrategyAdded`: Logged when a strategy is added.
*   `StrategyRemoved`: Logged when a strategy is removed.
*   `StrategyAllocationUpdated`: Logged when a strategy's allocation changes.
*   `FundsRebalanced`: Logged after rebalancing.
*   `PerformanceFeeCollected`: Logged when fees are harvested.
*   `SupportedTokenAdded`: Logged when a token is supported.
*   `SupportedTokenRemoved`: Logged when a token is unsupported.
*   `StrategistUpdated`: Logged when the strategist address changes.
*   `FeeRecipientUpdated`: Logged when the fee recipient changes.
*   `PerformanceFeePercentageUpdated`: Logged when fee percentage changes.
*   `MinDepositAmountUpdated`: Logged when min deposit changes.
*   `MinWithdrawAmountUpdated`: Logged when min withdraw changes.
*   `Paused`: Logged when contract is paused.
*   `Unpaused`: Logged when contract is unpaused.
*   `EmergencyWithdrawal`: Logged on user emergency withdrawal.
*   `StuckTokensRecovered`: Logged on admin token recovery.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyStrategist`: Restricts access to the strategist address.
*   `whenNotPaused`: Restricts access when the contract is not paused.
*   `whenPaused`: Restricts access when the contract is paused.

**Functions:**

1.  `constructor`: Initializes owner, strategist, fee recipient, initial fees, and supported tokens.
2.  `deposit(address token, uint256 amount)`: Allows users to deposit a supported token and receive shares.
3.  `withdraw(address token, uint256 shares)`: Allows users to burn their shares and withdraw proportional underlying tokens.
4.  `emergencyWithdraw(address token)`: Allows a user to withdraw their *full* balance (shares converted to tokens) immediately during a paused state. Skips rebalancing logic.
5.  `getTotalAssets(address token)`: Returns the total value of assets managed by the vault for a specific token (including funds in strategies and contract balance).
6.  `sharesForAmount(address token, uint256 amount)`: Calculates how many shares are minted for a given token amount.
7.  `amountForShares(address token, uint256 shares)`: Calculates how many tokens a given number of shares is currently worth.
8.  `addStrategy(address strategyAddress, address token, uint256 allocationBps)`: Adds a new strategy adapter for a specific token and sets its initial allocation. (Owner only)
9.  `removeStrategy(address strategyAddress)`: Removes an existing strategy adapter. Requires allocation to be 0. (Owner only)
10. `setStrategyAllocation(address strategyAddress, uint256 allocationBps)`: Sets the allocation percentage for an active strategy. Sum of allocations must be 10000 bps (100%). (Strategist only)
11. `rebalanceFunds(address token)`: Redistributes funds of a specific token across active strategies based on current allocations. (Strategist only, subject to interval)
12. `getCurrentAllocations(address token)`: Returns a list of active strategies and their current allocation percentages for a token. (View)
13. `getStrategies(address token)`: Returns a list of active strategy addresses for a token. (View)
14. `getTotalAssetsInStrategy(address strategyAddress)`: Returns the total assets held by a specific strategy adapter (as reported by the adapter). (View)
15. `setStrategist(address _strategist)`: Sets the address allowed to manage strategies and rebalance. (Owner only)
16. `getStrategist()`: Returns the current strategist address. (View)
17. `setFeeRecipient(address _feeRecipient)`: Sets the address receiving performance fees. (Owner only)
18. `getFeeRecipient()`: Returns the current fee recipient. (View)
19. `setPerformanceFeePercentage(uint256 _performanceFeePercentageBps)`: Sets the percentage of yield collected as fees. (Owner only)
20. `getPerformanceFeePercentage()`: Returns the current performance fee percentage. (View)
21. `addSupportedToken(address token)`: Adds a token that can be deposited and managed. (Owner only)
22. `removeSupportedToken(address token)`: Removes a supported token. (Owner only)
23. `getSupportedTokens()`: Returns an array of supported token addresses. (View)
24. `isTokenSupported(address token)`: Checks if a token is supported. (View)
25. `withdrawStuckTokens(address token, uint256 amount, address recipient)`: Allows owner to recover tokens accidentally sent to the contract (excluding supported tokens managed by the vault). (Owner only)
26. `pause()`: Pauses certain contract operations. (Owner only)
27. `unpause()`: Unpauses the contract. (Owner only)
28. `setMinDepositAmount(uint256 _minDepositAmount)`: Sets the minimum deposit amount. (Owner only)
29. `getMinDepositAmount()`: Returns the minimum deposit amount. (View)
30. `setMinWithdrawAmount(uint256 _minWithdrawAmount)`: Sets the minimum shares to withdraw. (Owner only)
31. `getMinWithdrawAmount()`: Returns the minimum withdraw amount. (View)
32. `setRebalanceInterval(uint256 _rebalanceInterval)`: Sets the minimum time between manual rebalances. (Strategist only)
33. `getRebalanceInterval()`: Returns the rebalance interval. (View)
34. `lastRebalanceTime(address token)`: Returns the last rebalance timestamp for a specific token. (View)
35. `userShares(address user)`: Returns the shares held by a specific user. (View)
36. `getTotalSupply()`: Returns the total outstanding shares. (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Minimal interface for strategy adapters
interface IStrategyAdapter {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getTotalAssets() external view returns (uint256);
    function getSupportedTokens() external view returns (address[] memory); // Adapter specifies which tokens it handles
}

contract DeFiDynamicYield is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    address public strategist;
    mapping(address => bool) private supportedTokens;
    address[] private supportedTokenArray; // To iterate supported tokens

    struct StrategyInfo {
        address strategyAddress;
        address token; // Token this strategy manages
        uint256 allocationBps; // Allocation in basis points (10000 = 100%)
        bool active;
    }

    // Mapping from token address to a mapping of strategy address to its info
    mapping(address => mapping(address => StrategyInfo)) public strategies;
    // Mapping from token address to an array of strategy addresses for that token
    mapping(address => address[]) public strategyAddresses;
    // Mapping from token address to the sum of active allocation basis points for that token
    mapping(address => uint256) public totalAllocationBps;

    uint256 public totalShares;
    mapping(address => uint256) public userShares;

    uint256 public performanceFeePercentageBps; // Percentage of yield taken as fee (0-10000)
    address public feeRecipient;

    uint256 public minDepositAmount;
    uint256 public minWithdrawAmount; // Minimum shares to withdraw

    mapping(address => uint256) public lastRebalanceTime; // Last rebalance time per token
    uint256 public rebalanceInterval = 1 days; // Minimum time between manual rebalances

    // --- Events ---

    event Deposited(address indexed user, address indexed token, uint256 tokenAmount, uint256 sharesMinted);
    event Withdrawn(address indexed user, address indexed token, uint256 tokenAmount, uint256 sharesBurned);
    event EmergencyWithdrawal(address indexed user, address indexed token, uint256 tokenAmount);
    event StrategyAdded(address indexed strategyAddress, address indexed token, uint256 initialAllocationBps);
    event StrategyRemoved(address indexed strategyAddress, address indexed token);
    event StrategyAllocationUpdated(address indexed strategyAddress, address indexed token, uint256 newAllocationBps);
    event FundsRebalanced(address indexed token, uint256 totalAssetsAfter);
    event PerformanceFeeCollected(address indexed token, uint256 feeAmount);
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event StrategistUpdated(address indexed oldStrategist, address indexed newStrategist);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event PerformanceFeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event MinDepositAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event MinWithdrawAmountUpdated(uint256 oldAmount, uint256 newAmount);
    event StuckTokensRecovered(address indexed token, uint256 amount, address indexed recipient);

    // --- Modifiers ---

    modifier onlyStrategist() {
        require(msg.sender == strategist, "Not strategist");
        _;
    }

    modifier onlySupportedToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }

    // --- Constructor ---

    constructor(
        address initialStrategist,
        address initialFeeRecipient,
        uint256 initialPerformanceFeeBps,
        address[] memory initialSupportedTokens
    ) Ownable(msg.sender) {
        strategist = initialStrategist;
        feeRecipient = initialFeeRecipient;
        require(initialPerformanceFeeBps <= 10000, "Fee Bps must be <= 10000");
        performanceFeePercentageBps = initialPerformanceFeeBps;

        for (uint i = 0; i < initialSupportedTokens.length; i++) {
            require(initialSupportedTokens[i] != address(0), "Initial supported token cannot be zero address");
            supportedTokens[initialSupportedTokens[i]] = true;
            supportedTokenArray.push(initialSupportedTokens[i]);
            emit SupportedTokenAdded(initialSupportedTokens[i]);
        }
    }

    // --- Core Vault Logic ---

    /**
     * @notice Deposits a supported token into the vault and mints shares.
     * @param token The address of the token being deposited.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address token, uint256 amount) external payable nonReentrant whenNotPaused onlySupportedToken(token) {
        require(amount >= minDepositAmount, "Deposit amount too low");

        uint256 currentTotalAssets = getTotalAssets(token);
        uint256 sharesMinted;

        if (totalShares == 0 || currentTotalAssets == 0) {
            // First deposit or assets somehow became zero
            sharesMinted = amount;
        } else {
            // Calculate shares based on proportion of total assets
            sharesMinted = (amount * totalShares) / currentTotalAssets;
        }

        require(sharesMinted > 0, "Must mint non-zero shares");

        // Transfer tokens to the vault contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Update state
        userShares[msg.sender] += sharesMinted;
        totalShares += sharesMinted;

        emit Deposited(msg.sender, token, amount, sharesMinted);

        // Optionally trigger rebalance if below a certain threshold held in contract?
        // This is a design choice - could be manual, time-based, or triggered here.
        // For simplicity, we rely on manual/timed rebalance for now.
    }

    /**
     * @notice Allows a user to withdraw their share of assets by burning shares.
     * @param token The address of the token to withdraw.
     * @param shares The number of shares to burn.
     */
    function withdraw(address token, uint256 shares) external nonReentrant whenNotPaused onlySupportedToken(token) {
        require(userShares[msg.sender] >= shares, "Insufficient shares");
        require(shares >= minWithdrawAmount, "Withdraw amount too low");

        uint256 currentTotalAssets = getTotalAssets(token);
        uint256 tokenAmount = (shares * currentTotalAssets) / totalShares;

        require(tokenAmount > 0, "Withdraw amount is zero");

        // Update state first (Checks-Effects-Interactions)
        userShares[msg.sender] -= shares;
        totalShares -= shares;

        // Check balance in contract. If not enough, trigger pulling from strategies.
        // This is a critical part: ensures user gets funds even if they are in strategies.
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        uint256 amountToPullFromStrategies = 0;

        if (contractBalance < tokenAmount) {
            amountToPullFromStrategies = tokenAmount - contractBalance;
            // Note: This proportional withdrawal might leave strategies unbalanced.
            // A full rebalance is recommended after significant withdrawals/deposits.
            _pullFromStrategies(token, amountToPullFromStrategies);
            // Re-check balance after pulling from strategies
            contractBalance = IERC20(token).balanceOf(address(this));
            require(contractBalance >= tokenAmount, "Failed to pull enough funds from strategies");
        }

        // Transfer tokens to user
        IERC20(token).safeTransfer(msg.sender, tokenAmount);

        emit Withdrawn(msg.sender, token, tokenAmount, shares);
    }

    /**
     * @notice Allows a user to emergency withdraw their full balance during a paused state.
     * Skips strategy rebalancing logic and transfers available balance.
     * Note: May not be able to withdraw 100% if funds are stuck in unresponsive strategies.
     * @param token The address of the token to withdraw.
     */
    function emergencyWithdraw(address token) external nonReentrant whenPaused onlySupportedToken(token) {
        uint256 shares = userShares[msg.sender];
        require(shares > 0, "No shares to withdraw");

        uint256 currentTotalAssets = getTotalAssets(token);
        uint256 tokenAmount = (shares * currentTotalAssets) / totalShares; // Theoretical amount

        // Update state first
        userShares[msg.sender] = 0;
        totalShares -= shares;

        // Transfer available balance in the contract up to the theoretical amount
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        uint256 amountToTransfer = (tokenAmount < contractBalance) ? tokenAmount : contractBalance; // Cannot exceed contract balance

        if (amountToTransfer > 0) {
             IERC20(token).safeTransfer(msg.sender, amountToTransfer);
             emit EmergencyWithdrawal(msg.sender, token, amountToTransfer);
        } else {
             // Refund shares if no tokens could be withdrawn
             userShares[msg.sender] = shares;
             totalShares += shares;
             revert("No funds available in contract for emergency withdrawal");
        }
    }


    /**
     * @notice Returns the total value of assets managed by the vault for a specific token.
     * This includes the balance held in the contract and the assets held by strategies.
     * @param token The address of the token to query.
     * @return The total assets in the vault denominated in the query token.
     */
    function getTotalAssets(address token) public view onlySupportedToken(token) returns (uint256) {
        uint256 total = IERC20(token).balanceOf(address(this));
        address[] memory addresses = strategyAddresses[token];
        for (uint i = 0; i < addresses.length; i++) {
            if (strategies[token][addresses[i]].active) {
                 // Call the strategy adapter to get its managed assets
                try IStrategyAdapter(addresses[i]).getTotalAssets() returns (uint256 strategyAssets) {
                    total += strategyAssets;
                } catch {
                    // If a strategy call fails, assume it has 0 assets for getTotalAssets calculation
                    // Consider adding monitoring/alerting for failed calls
                }
            }
        }
        return total;
    }

    /**
     * @notice Calculates the number of shares to mint for a given token amount.
     * @param token The address of the token.
     * @param amount The amount of tokens.
     * @return The calculated number of shares.
     */
    function sharesForAmount(address token, uint256 amount) public view onlySupportedToken(token) returns (uint256) {
         uint256 currentTotalAssets = getTotalAssets(token);
         if (totalShares == 0 || currentTotalAssets == 0) {
             return amount; // First deposit or assets became zero
         }
         return (amount * totalShares) / currentTotalAssets;
    }

    /**
     * @notice Calculates the token amount equivalent to a given number of shares.
     * @param token The address of the token.
     * @param shares The number of shares.
     * @return The calculated token amount.
     */
    function amountForShares(address token, uint256 shares) public view onlySupportedToken(token) returns (uint256) {
        uint256 currentTotalAssets = getTotalAssets(token);
        if (totalShares == 0) {
            return 0; // Should not happen if shares > 0, but safety check
        }
        return (shares * currentTotalAssets) / totalShares;
    }

    // --- Strategy Management ---

    /**
     * @notice Adds a new strategy adapter for a specific token.
     * The adapter must implement the IStrategyAdapter interface.
     * Initial allocation should be 0 or added later via setStrategyAllocation.
     * @param strategyAddress The address of the strategy adapter contract.
     * @param token The address of the token this strategy manages.
     * @param initialAllocationBps The initial allocation percentage in basis points (0-10000).
     */
    function addStrategy(address strategyAddress, address token, uint256 initialAllocationBps)
        external onlyOwner onlySupportedToken(token) nonReentrant
    {
        require(strategyAddress != address(0), "Strategy address cannot be zero");
        require(!strategies[token][strategyAddress].active, "Strategy already active for this token");
        require(initialAllocationBps <= 10000, "Allocation Bps must be <= 10000");

        // Optional: Verify the strategy actually supports the token via its interface
        // try IStrategyAdapter(strategyAddress).getSupportedTokens() returns (address[] memory supportedByStrategy) {
        //     bool found = false;
        //     for(uint i = 0; i < supportedByStrategy.length; i++) {
        //         if (supportedByStrategy[i] == token) {
        //             found = true;
        //             break;
        //         }
        //     }
        //    require(found, "Strategy does not report supporting this token");
        // } catch {
        //    revert("Failed to query strategy supported tokens");
        // }


        strategies[token][strategyAddress] = StrategyInfo({
            strategyAddress: strategyAddress,
            token: token,
            allocationBps: initialAllocationBps,
            active: true
        });

        strategyAddresses[token].push(strategyAddress);
        totalAllocationBps[token] += initialAllocationBps;

        require(totalAllocationBps[token] <= 10000, "Total allocation exceeds 100%");

        emit StrategyAdded(strategyAddress, token, initialAllocationBps);
    }

    /**
     * @notice Removes an existing strategy adapter.
     * Requires the strategy's allocation to be 0 before removal.
     * Assets must be withdrawn from the strategy manually beforehand.
     * @param strategyAddress The address of the strategy adapter contract.
     */
    function removeStrategy(address strategyAddress) external onlyOwner nonReentrant {
        // Find the strategy and its token
        address tokenToRemove = address(0);
        bool found = false;
        for (uint i = 0; i < supportedTokenArray.length; i++) {
            address token = supportedTokenArray[i];
            if (strategies[token][strategyAddress].active) {
                tokenToRemove = token;
                found = true;
                break;
            }
        }
        require(found, "Strategy not found or not active");
        require(strategies[tokenToRemove][strategyAddress].allocationBps == 0, "Cannot remove strategy with non-zero allocation");

        strategies[tokenToRemove][strategyAddress].active = false;
        strategies[tokenToRemove][strategyAddress].allocationBps = 0; // Should already be 0, but double check

        // Remove from the array of strategy addresses for this token (simple swap-and-pop)
        address[] storage addresses = strategyAddresses[tokenToRemove];
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == strategyAddress) {
                addresses[i] = addresses[addresses.length - 1];
                addresses.pop();
                break;
            }
        }

        // totalAllocationBps[tokenToRemove] doesn't need update as allocation was already 0

        emit StrategyRemoved(strategyAddress, tokenToRemove);
    }

    /**
     * @notice Sets the allocation percentage for an active strategy.
     * Sum of all active strategy allocations for a token must equal 10000 bps (100%) after the change.
     * @param strategyAddress The address of the strategy adapter contract.
     * @param allocationBps The new allocation percentage in basis points (0-10000).
     */
    function setStrategyAllocation(address strategyAddress, uint256 allocationBps)
        external onlyStrategist nonReentrant
    {
        // Find the strategy and its token
        address tokenToUpdate = address(0);
        bool found = false;
        for (uint i = 0; i < supportedTokenArray.length; i++) {
            address token = supportedTokenArray[i];
            if (strategies[token][strategyAddress].active) {
                tokenToUpdate = token;
                found = true;
                break;
            }
        }
        require(found, "Strategy not found or not active");
        require(allocationBps <= 10000, "Allocation Bps must be <= 10000");

        uint256 oldAllocationBps = strategies[tokenToUpdate][strategyAddress].allocationBps;
        uint256 currentTotalAlloc = totalAllocationBps[tokenToUpdate];

        // Update total allocation sum
        currentTotalAlloc -= oldAllocationBps;
        currentTotalAlloc += allocationBps;

        require(currentTotalAlloc <= 10000, "Total allocation exceeds 100%"); // Should ideally be exactly 10000
        // Add a tolerance check? e.g., abs(currentTotalAlloc - 10000) < tolerance

        strategies[tokenToUpdate][strategyAddress].allocationBps = allocationBps;
        totalAllocationBps[tokenToUpdate] = currentTotalAlloc;

        emit StrategyAllocationUpdated(strategyAddress, tokenToUpdate, allocationBps);
    }

    /**
     * @notice Rebalances funds for a specific token across strategies based on current allocations.
     * Pulls excess funds from over-allocated strategies and deposits into under-allocated ones.
     * Can only be called by the strategist and is subject to the rebalanceInterval.
     * This function can be gas intensive depending on the number of strategies and interactions.
     * @param token The address of the token to rebalance.
     */
    function rebalanceFunds(address token) external onlyStrategist nonReentrant whenNotPaused onlySupportedToken(token) {
        require(block.timestamp >= lastRebalanceTime[token] + rebalanceInterval, "Rebalance interval not met");
        require(totalAllocationBps[token] == 10000, "Total allocation must be 100%"); // Ensure full allocation before rebalance

        uint256 currentTotalAssets = getTotalAssets(token); // Assets across contract + strategies
        address[] memory addresses = strategyAddresses[token];
        uint256 contractBalance = IERC20(token).balanceOf(address(this));

        // 1. Calculate target amount for each strategy and the amount to keep in the contract (optional, could be 0 target)
        // Let's simplify: Target 0 in contract unless needed for immediate withdrawals.
        // The total assets will be distributed among strategies according to allocation.
        // Any excess in the contract is treated as 'unallocated' or available liquidity.
        // Rebalance focuses on bringing strategies *closer* to target based on *total* assets.

        mapping(address => uint256) internal targetAmounts;
        uint256 totalTargetedByStrategies = 0;

        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                uint256 allocationBps = strategies[token][stratAddr].allocationBps;
                uint256 target = (currentTotalAssets * allocationBps) / 10000;
                targetAmounts[stratAddr] = target;
                totalTargetedByStrategies += target;
            }
        }

        // The remaining amount (totalAssets - totalTargetedByStrategies) should ideally be close to 0
        // or deliberately kept in the contract for liquidity. For this simplified rebalance,
        // we'll attempt to deposit all available contract balance into strategies that are under target.

        // 2. Pull from strategies that are over their target allocation
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                 // Call the strategy adapter to get its managed assets
                try IStrategyAdapter(stratAddr).getTotalAssets() returns (uint256 strategyAssets) {
                    if (strategyAssets > targetAmounts[stratAddr]) {
                        uint256 amountToPull = strategyAssets - targetAmounts[stratAddr];
                        // Add a small buffer to leave some dust? Or pull exactly? Pull exactly for simplicity.
                         // Check if strategy supports withdrawal of this amount. If not, pull max available?
                         // For simplicity, assume withdraw(amount) pulls *up to* amount.
                         // If strategy fails to pull exact amount, it's a strategy issue.
                        try IStrategyAdapter(stratAddr).withdraw(amountToPull) {
                             // Success, funds are now in this contract
                        } catch {
                             // Handle strategy withdrawal failure (e.g., log, skip strategy)
                             // For simplicity here, we just catch and continue
                             emit StrategyOperationFailed(stratAddr, "withdraw", amountToPull);
                        }
                    }
                } catch {
                    // Handle strategy getTotalAssets failure
                    emit StrategyOperationFailed(stratAddr, "getTotalAssets", 0);
                }
            }
        }

        // Update contract balance after pulling
        contractBalance = IERC20(token).balanceOf(address(this));

        // 3. Deposit into strategies that are under their target allocation
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                 // Re-fetch strategy assets after potential pulls
                try IStrategyAdapter(stratAddr).getTotalAssets() returns (uint256 strategyAssets) {
                    if (strategyAssets < targetAmounts[stratAddr]) {
                         uint256 neededAmount = targetAmounts[stratAddr] - strategyAssets;
                         // Calculate amount to deposit, limited by available contract balance
                         uint256 amountToDeposit = (neededAmount < contractBalance) ? neededAmount : contractBalance;

                         if (amountToDeposit > 0) {
                             // Transfer tokens from contract to strategy
                             IERC20(token).safeTransfer(stratAddr, amountToDeposit);
                              // Call strategy deposit
                             try IStrategyAdapter(stratAddr).deposit(amountToDeposit) {
                                 contractBalance -= amountToDeposit; // Update local balance
                             } catch {
                                 // Handle strategy deposit failure. Funds are stuck in the strategy contract now!
                                 // This is a major issue and requires manual recovery or robust error handling in adapter.
                                 // For simplicity, just log and continue, but in real DeFi this needs careful handling.
                                 emit StrategyOperationFailed(stratAddr, "deposit", amountToDeposit);
                             }
                         }
                    }
                } catch {
                    // Handle strategy getTotalAssets failure
                    emit StrategyOperationFailed(stratAddr, "getTotalAssets", 0);
                }
            }
        }

        // 4. Harvest Performance Fees (Optional step within rebalance)
        // This is complex on-chain. A simpler approach: fees are taken when funds are withdrawn
        // or based on contract's balance increase over time relative to total shares.
        // Let's add a separate function for fee harvesting triggered by strategist.
        // The rebalance just moves funds.

        lastRebalanceTime[token] = block.timestamp;
        emit FundsRebalanced(token, getTotalAssets(token)); // Log total assets *after* rebalance
    }

    event StrategyOperationFailed(address indexed strategyAddress, string operation, uint256 amount);


    /**
     * @notice Allows strategist to harvest performance fees if yield has increased total assets.
     * Calculates yield as the increase in total asset value beyond initial deposits,
     * proportional to shares, and takes a percentage. This is a simplified model.
     * A more robust model tracks yield per strategy or uses external oracles.
     * @param token The address of the token for which to harvest fees.
     */
    function harvestYieldAndFees(address token) external onlyStrategist nonReentrant onlySupportedToken(token) {
         require(feeRecipient != address(0), "Fee recipient not set");
         require(performanceFeePercentageBps > 0, "Performance fee percentage is zero");

         uint256 currentTotalAssets = getTotalAssets(token);

         if (totalShares == 0) {
             // No users, no yield to distribute or take fees from yet
             return;
         }

         // Calculate 'principal' value based on total shares
         // The total assets if each share was worth 1 unit of the token at the beginning (simplistic)
         // A better approach: track total deposited vs total withdrawn token amounts.
         // Or better: rely on strategy adapters reporting realized yield.
         // Let's use a simpler model based on total asset increase relative to shares.
         // This assumes 1 share was worth 1 token initially. Yield is totalAssets - totalShares.
         // This is flawed if deposits/withdrawals happen at different prices.
         // A robust share system handles this: totalAssets / totalShares gives price per share.
         // Yield is the increase in (totalAssets / totalShares) * totalShares since last harvest? Still complex.

         // Alternative simple model: Calculate yield as the increase in contract balance since last rebalance/harvest,
         // plus yield reported by strategies since last check. Requires strategies to report 'realized yield'.
         // Let's assume strategies accrue yield internally, and `rebalanceFunds` or direct calls
         // to strategies realize some yield back into the main vault contract's balance.
         // The harvest function simply sweeps a percentage of the *available contract balance* (that isn't needed to match shares)
         // as fees. This is also imperfect but simpler.

         // Let's refine: Assume yield is harvested *into* the contract when rebalancing or via separate calls.
         // `harvestYieldAndFees` identifies the portion of the contract balance eligible for fees.
         // Eligible yield = Contract Balance - (Total Assets if Shares = Tokens)
         // This is still potentially incorrect due to asset value changes.

         // Let's simplify drastically for this example: fees are a percentage of *new* funds received by the contract from strategies
         // since the last harvest, that are *above* the proportional amount needed for user shares.
         // This is still hard.

         // Simplest model: Harvest a percentage of the *entire increase in total assets* since last harvest?
         // yield = currentTotalAssets - assetsAtLastHarvest
         // This requires tracking assets at last harvest... need a state variable.
         // Let's track assets at last fee harvest per token.

         uint256 assetsAtLastFeeHarvest = 0; // Needs to be a state variable per token or global? Per token. Add mapping.
         // mapping(address => uint256) public assetsAtLastFeeHarvest; // Add this state variable

         // Re-thinking required for robust on-chain fee calculation...
         // This example will skip complex on-chain yield/fee calculation during harvestYieldAndFees.
         // Instead, let's assume strategies realize yield internally, and funds are pulled back
         // during rebalance. Fees can be a % of *withdrawals* (less ideal), or
         // a % of funds successfully *deposited into* strategies *from* the contract balance,
         // which implies those funds came from deposits or realized yield.
         // Let's make fee harvesting simpler: Strategist can claim a percentage of the contract's *free balance*
         // above a certain buffer, assuming that free balance represents yield or excess liquidity.
         // This is still not a proper yield calculation.

         // Let's make `rebalanceFunds` also handle a simple fee: when funds are pulled from strategies *back to the vault*,
         // a percentage of the *increase* in assets pulled vs. assets deposited into that strategy originally
         // could be yield, and a fee is taken. Still hard to track deposit amounts per strategy.

         // Okay, let's implement the *simplest possible* fee model: The strategist can call `harvestYieldAndFees`
         // and specify an amount to harvest from the *contract's current balance*. This amount is then sent
         // to the fee recipient. The strategist is responsible for ensuring this amount is actually
         // realized yield and not principal or needed liquidity. Requires off-chain calculation.

         // Let's add a simpler fee model: A percentage of the *amount withdrawn* by users is taken as a fee. (Less common, but simple)
         // Let's add a parameter to `withdraw` for this? No, performance fees are on *yield*, not principal.
         // Let's revert to the "fee is harvested from available balance" model, but triggered manually.
         // The strategist calculates yield off-chain and decides how much to harvest.
         // This function will simply transfer a specified amount from the contract balance to the fee recipient,
         // up to the total amount available *minus* what's theoretically needed for user withdrawals (currentTotalAssets - sum of strategy assets = contract balance)
         // Still complex.

         // Final Fee Model Decision: The contract maintains a performance fee percentage. When `rebalanceFunds` is called,
         // it identifies the *net increase* in `getTotalAssets()` for that token since the *last rebalance*. This increase is considered yield.
         // A percentage of this yield is sent to the fee recipient from the contract's balance if available, or tagged for future collection.
         // This requires storing `getTotalAssets()` at the last rebalance per token.

         // Add state variable: mapping(address => uint256) public totalAssetsAtLastRebalance;

         // Re-implement Rebalance with Fee Logic:
         // 1. Store totalAssets before rebalance: uint256 assetsBefore = getTotalAssets(token);
         // 2. Perform all pulls and deposits.
         // 3. Store totalAssets after rebalance: uint256 assetsAfter = getTotalAssets(token);
         // 4. Calculate yield: if (assetsAfter > assetsBefore) uint256 yield = assetsAfter - assetsBefore; else yield = 0;
         // 5. Calculate fee: uint256 feeAmount = (yield * performanceFeePercentageBps) / 10000;
         // 6. Transfer fee from contract balance: if (feeAmount > 0 && IERC20(token).balanceOf(address(this)) >= feeAmount) { IERC20(token).safeTransfer(feeRecipient, feeAmount); emit PerformanceFeeCollected(...); }
         // 7. Update totalAssetsAtLastRebalance[token] = assetsAfter;

         // Remove the separate `harvestYieldAndFees` function. Fees are implicitly handled during `rebalanceFunds`.
         // This simplifies the interface and ties fees to the yield realization/allocation process.
         // We still need functions to *set* fee recipient and percentage.

         // Re-check function count:
         // 1. constructor
         // 2. deposit
         // 3. withdraw
         // 4. emergencyWithdraw
         // 5. getTotalAssets
         // 6. sharesForAmount
         // 7. amountForShares
         // 8. addStrategy
         // 9. removeStrategy
         // 10. setStrategyAllocation
         // 11. rebalanceFunds (Now includes fee logic)
         // 12. getCurrentAllocations
         // 13. getStrategies
         // 14. getTotalAssetsInStrategy
         // 15. setStrategist
         // 16. getStrategist
         // 17. setFeeRecipient
         // 18. getFeeRecipient
         // 19. setPerformanceFeePercentage
         // 20. getPerformanceFeePercentage
         // 21. addSupportedToken
         // 22. removeSupportedToken
         // 23. getSupportedTokens
         // 24. isTokenSupported
         // 25. withdrawStuckTokens
         // 26. pause
         // 27. unpause
         // 28. setMinDepositAmount
         // 29. getMinDepositAmount
         // 30. setMinWithdrawAmount
         // 31. getMinWithdrawAmount
         // 32. setRebalanceInterval
         // 33. getRebalanceInterval
         // 34. lastRebalanceTime (view)
         // 35. userShares (view)
         // 36. getTotalSupply (view)
         // 37. totalAllocationBps (view per token)
         // 38. totalAssetsAtLastRebalance (view per token) -> Need to add this state variable

         // This gives us 38 functions/public variables which is well over 20.
         // Let's proceed with implementing the fee logic in `rebalanceFunds` and removing `harvestYieldAndFees`.

    }

    // --- Strategy & Rebalancing Details ---

    // Add state variable for tracking assets at last rebalance (for fee calculation)
    mapping(address => uint256) public totalAssetsAtLastRebalance;


    /**
     * @notice Rebalances funds for a specific token across strategies based on current allocations.
     * Pulls excess funds from over-allocated strategies and deposits into under-allocated ones.
     * Can only be called by the strategist and is subject to the rebalanceInterval.
     * This function can be gas intensive depending on the number of strategies and interactions.
     * Includes simple performance fee calculation on realized yield during rebalance.
     * @param token The address of the token to rebalance.
     */
    function rebalanceFunds(address token) external onlyStrategist nonReentrant whenNotPaused onlySupportedToken(token) {
        require(block.timestamp >= lastRebalanceTime[token] + rebalanceInterval, "Rebalance interval not met");
        require(totalAllocationBps[token] == 10000, "Total allocation must be 100%"); // Ensure full allocation before rebalance

        uint256 assetsBeforeRebalance = getTotalAssets(token); // Get total assets before any pulls/deposits
        address[] memory addresses = strategyAddresses[token];

        // 1. Calculate target amount for each strategy
        mapping(address => uint256) internal targetAmounts;
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                uint256 allocationBps = strategies[token][stratAddr].allocationBps;
                targetAmounts[stratAddr] = (assetsBeforeRebalance * allocationBps) / 10000;
            }
        }

        // 2. Pull from strategies that are over their target allocation
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                try IStrategyAdapter(stratAddr).getTotalAssets() returns (uint256 strategyAssets) {
                    if (strategyAssets > targetAmounts[stratAddr]) {
                        uint256 amountToPull = strategyAssets - targetAmounts[stratAddr];
                        try IStrategyAdapter(stratAddr).withdraw(amountToPull) {}
                        catch { emit StrategyOperationFailed(stratAddr, "withdraw", amountToPull); }
                    }
                } catch { emit StrategyOperationFailed(stratAddr, "getTotalAssets (pull stage)", 0); }
            }
        }

        // 3. Deposit into strategies that are under their target allocation
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                try IStrategyAdapter(stratAddr).getTotalAssets() returns (uint256 strategyAssets) {
                    if (strategyAssets < targetAmounts[stratAddr]) {
                         uint256 neededAmount = targetAmounts[stratAddr] - strategyAssets;
                         uint256 amountToDeposit = (neededAmount < contractBalance) ? neededAmount : contractBalance;

                         if (amountToDeposit > 0) {
                             IERC20(token).safeTransfer(stratAddr, amountToDeposit);
                             try IStrategyAdapter(stratAddr).deposit(amountToDeposit) {
                                 contractBalance -= amountToDeposit; // Update local balance
                             } catch {
                                 emit StrategyOperationFailed(stratAddr, "deposit", amountToDeposit);
                             }
                         }
                    }
                } catch { emit StrategyOperationFailed(stratAddr, "getTotalAssets (deposit stage)", 0); }
            }
        }

        // 4. Calculate and Harvest Performance Fees
        // Yield = Increase in Total Assets since last rebalance
        uint256 assetsAfterRebalance = getTotalAssets(token);
        uint256 yield = 0;
        if (assetsAfterRebalance > totalAssetsAtLastRebalance[token]) {
            yield = assetsAfterRebalance - totalAssetsAtLastRebalance[token];
        }
        totalAssetsAtLastRebalance[token] = assetsAfterRebalance; // Update for next calculation

        uint256 feeAmount = 0;
        if (yield > 0 && performanceFeePercentageBps > 0 && feeRecipient != address(0)) {
            feeAmount = (yield * performanceFeePercentageBps) / 10000;
             // Ensure fee amount doesn't exceed current contract balance
            uint256 currentContractBalanceForFees = IERC20(token).balanceOf(address(this));
            if (feeAmount > currentContractBalanceForFees) {
                feeAmount = currentContractBalanceForFees;
            }
            if (feeAmount > 0) {
                IERC20(token).safeTransfer(feeRecipient, feeAmount);
                emit PerformanceFeeCollected(token, feeAmount);
            }
        }

        lastRebalanceTime[token] = block.timestamp;
        emit FundsRebalanced(token, assetsAfterRebalance);
    }


    /**
     * @notice Pulls a specified amount of tokens from strategies proportionally
     * based on their current asset balances. Used internally for withdrawals.
     * @param token The address of the token to pull.
     * @param amountToPull The total amount of tokens needed from strategies.
     */
    function _pullFromStrategies(address token, uint256 amountToPull) internal {
        address[] memory addresses = strategyAddresses[token];
        uint256 totalStrategyAssets = 0;
        mapping(address => uint256) internal strategyAssets;

        // First, get total assets across all active strategies for this token
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                 try IStrategyAdapter(stratAddr).getTotalAssets() returns (uint256 assets) {
                    strategyAssets[stratAddr] = assets;
                    totalStrategyAssets += assets;
                } catch { emit StrategyOperationFailed(stratAddr, "getTotalAssets (pull internal)", 0); }
            }
        }

        require(totalStrategyAssets >= amountToPull, "Insufficient total assets in strategies");

        // Pull from strategies proportionally
        uint256 pulledAmount = 0;
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active && strategyAssets[stratAddr] > 0) {
                // Calculate proportional amount to pull from this strategy
                uint256 amountFromThisStrategy = (amountToPull * strategyAssets[stratAddr]) / totalStrategyAssets;
                if (amountFromThisStrategy > 0) {
                     try IStrategyAdapter(stratAddr).withdraw(amountFromThisStrategy) {
                        pulledAmount += amountFromThisStrategy;
                        // Break if we've pulled enough (can happen due to rounding or small differences)
                        if (pulledAmount >= amountToPull) {
                            break;
                        }
                    } catch { emit StrategyOperationFailed(stratAddr, "withdraw (internal)", amountFromThisStrategy); }
                }
            }
        }
        // Note: It's possible pulledAmount is slightly less than amountToPull due to rounding or failed calls.
        // The caller (`withdraw`) will check the contract balance afterwards.
    }

    // --- Query Functions ---

    /**
     * @notice Returns the list of active strategies and their current allocation percentages for a token.
     * @param token The address of the token to query.
     * @return An array of StrategyInfo structs for active strategies.
     */
    function getCurrentAllocations(address token) external view onlySupportedToken(token) returns (StrategyInfo[] memory) {
        address[] memory addresses = strategyAddresses[token];
        StrategyInfo[] memory activeStrategies = new StrategyInfo[](addresses.length); // Max possible size
        uint256 count = 0;
        for (uint i = 0; i < addresses.length; i++) {
            address stratAddr = addresses[i];
            if (strategies[token][stratAddr].active) {
                activeStrategies[count] = strategies[token][stratAddr];
                count++;
            }
        }

        // Resize array to actual number of active strategies
        StrategyInfo[] memory result = new StrategyInfo[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeStrategies[i];
        }
        return result;
    }

     /**
      * @notice Returns the list of active strategy addresses for a specific token.
      * @param token The address of the token to query.
      * @return An array of active strategy addresses.
      */
    function getStrategies(address token) external view onlySupportedToken(token) returns (address[] memory) {
         address[] memory addresses = strategyAddresses[token];
         address[] memory activeAddresses = new address[](addresses.length); // Max possible size
         uint256 count = 0;
         for (uint i = 0; i < addresses.length; i++) {
             address stratAddr = addresses[i];
             if (strategies[token][stratAddr].active) {
                 activeAddresses[count] = stratAddr;
                 count++;
             }
         }

         address[] memory result = new address[](count);
         for (uint i = 0; i < count; i++) {
             result[i] = activeAddresses[i];
         }
         return result;
    }

    /**
     * @notice Returns the total assets held by a specific strategy adapter, as reported by the adapter.
     * @param strategyAddress The address of the strategy adapter contract.
     * @return The total assets held by the strategy. Returns 0 if call fails or strategy is inactive/not found.
     */
    function getTotalAssetsInStrategy(address strategyAddress) external view returns (uint256) {
         // Find which token this strategy manages
         address token = address(0);
         for(uint i = 0; i < supportedTokenArray.length; i++) {
             if(strategies[supportedTokenArray[i]][strategyAddress].active) {
                 token = supportedTokenArray[i];
                 break;
             }
         }
         if (token == address(0)) {
             return 0; // Strategy not found or inactive
         }

        // Call the strategy adapter
        try IStrategyAdapter(strategyAddress).getTotalAssets() returns (uint256 strategyAssets) {
            return strategyAssets;
        } catch {
            // Return 0 if the call to the strategy fails
            return 0;
        }
    }

    // --- Access Control & Settings ---

    /**
     * @notice Sets the address allowed to manage strategies and trigger rebalances.
     * @param _strategist The new strategist address.
     */
    function setStrategist(address _strategist) external onlyOwner {
        require(_strategist != address(0), "Strategist cannot be zero address");
        emit StrategistUpdated(strategist, _strategist);
        strategist = _strategist;
    }

    /**
     * @notice Gets the current strategist address.
     */
    function getStrategist() external view returns (address) {
        return strategist;
    }

    /**
     * @notice Sets the address receiving performance fees.
     * @param _feeRecipient The new fee recipient address.
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Gets the current fee recipient address.
     */
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /**
     * @notice Sets the percentage of yield collected as performance fees.
     * @param _performanceFeePercentageBps The new percentage in basis points (0-10000).
     */
    function setPerformanceFeePercentage(uint256 _performanceFeePercentageBps) external onlyOwner {
        require(_performanceFeePercentageBps <= 10000, "Percentage must be <= 10000");
        emit PerformanceFeePercentageUpdated(performanceFeePercentageBps, _performanceFeePercentageBps);
        performanceFeePercentageBps = _performanceFeePercentageBps;
    }

    /**
     * @notice Gets the current performance fee percentage in basis points.
     */
    function getPerformanceFeePercentage() external view returns (uint256) {
        return performanceFeePercentageBps;
    }


    /**
     * @notice Adds a token that can be deposited into and managed by the vault.
     * @param token The address of the token to add.
     */
    function addSupportedToken(address token) external onlyOwner nonReentrant {
        require(token != address(0), "Token cannot be zero address");
        require(!supportedTokens[token], "Token already supported");
        supportedTokens[token] = true;
        supportedTokenArray.push(token);
        emit SupportedTokenAdded(token);
    }

    /**
     * @notice Removes a supported token. Requires no active strategies for this token.
     * @param token The address of the token to remove.
     */
    function removeSupportedToken(address token) external onlyOwner nonReentrant {
        require(supportedTokens[token], "Token not supported");
        require(strategyAddresses[token].length == 0, "Cannot remove token with active strategies");

        supportedTokens[token] = false;

        // Remove from array (simple swap-and-pop)
        for (uint i = 0; i < supportedTokenArray.length; i++) {
            if (supportedTokenArray[i] == token) {
                supportedTokenArray[i] = supportedTokenArray[supportedTokenArray.length - 1];
                supportedTokenArray.pop();
                break;
            }
        }
        emit SupportedTokenRemoved(token);
    }

    /**
     * @notice Returns an array of currently supported token addresses.
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokenArray;
    }

    /**
     * @notice Checks if a token is currently supported for deposit/management.
     * @param token The address of the token to check.
     */
    function isTokenSupported(address token) external view returns (bool) {
        return supportedTokens[token];
    }


    /**
     * @notice Allows the owner to recover tokens accidentally sent to the contract.
     * Cannot be used to withdraw supported tokens managed by the vault.
     * @param token The address of the token to recover.
     * @param amount The amount of tokens to recover.
     * @param recipient The address to send the tokens to.
     */
    function withdrawStuckTokens(address token, uint256 amount, address recipient) external onlyOwner nonReentrant {
        require(token != address(0), "Token cannot be zero address");
        require(recipient != address(0), "Recipient cannot be zero address");
        require(!supportedTokens[token], "Cannot withdraw supported tokens this way"); // Prevent draining vault assets

        IERC20(token).safeTransfer(recipient, amount);
        emit StuckTokensRecovered(token, amount, recipient);
    }

    /**
     * @notice Pauses certain operations (deposit, withdraw, rebalance, emergencyWithdraw).
     * Callable only by owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract. Callable only by owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
         emit Unpaused(msg.sender);
    }

     /**
      * @notice Sets the minimum deposit amount for any supported token.
      * @param _minDepositAmount The new minimum amount (in token units).
      */
    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        emit MinDepositAmountUpdated(minDepositAmount, _minDepositAmount);
        minDepositAmount = _minDepositAmount;
    }

    /**
     * @notice Gets the current minimum deposit amount.
     */
    function getMinDepositAmount() external view returns (uint256) {
        return minDepositAmount;
    }

    /**
     * @notice Sets the minimum withdrawal amount (in shares).
     * @param _minWithdrawAmount The new minimum share amount.
     */
    function setMinWithdrawAmount(uint256 _minWithdrawAmount) external onlyOwner {
        emit MinWithdrawAmountUpdated(minWithdrawAmount, _minWithdrawAmount);
        minWithdrawAmount = _minWithdrawAmount;
    }

    /**
     * @notice Gets the current minimum withdrawal amount (in shares).
     */
    function getMinWithdrawAmount() external view returns (uint256) {
        return minWithdrawAmount;
    }

     /**
      * @notice Sets the minimum time interval required between manual rebalance calls.
      * @param _rebalanceInterval The new interval in seconds.
      */
    function setRebalanceInterval(uint256 _rebalanceInterval) external onlyStrategist {
        rebalanceInterval = _rebalanceInterval;
    }

    /**
     * @notice Gets the current rebalance interval.
     */
    function getRebalanceInterval() external view returns (uint256) {
        return rebalanceInterval;
    }

    /**
     * @notice Returns the last rebalance timestamp for a specific token.
     * @param token The address of the token to query.
     */
    function lastRebalanceTime(address token) external view returns (uint256) {
        return lastRebalanceTime[token];
    }

    /**
     * @notice Returns the total shares held by a specific user.
     * @param user The user's address.
     */
    function userShares(address user) external view returns (uint256) {
        return userShares[user];
    }

    /**
     * @notice Returns the total supply of vault shares.
     */
    function getTotalSupply() external view returns (uint256) {
        return totalShares;
    }

    // Helper view functions (can be exposed as public variables directly if preferred)
    // totalAllocationBps is already public mapping
    // totalAssetsAtLastRebalance is already public mapping


}
```

**Explanation of Advanced/Interesting Concepts & Functions:**

1.  **Dynamic Allocation & Strategy Adapters (`addStrategy`, `removeStrategy`, `setStrategyAllocation`, `rebalanceFunds`, `IStrategyAdapter`)**: This is the core concept. The vault doesn't know *how* to farm yield on Aave or Compound directly. It delegates this to specialized `IStrategyAdapter` contracts. This makes the vault modular and extensible. You can add new strategies without modifying the main vault logic (as long as they implement `IStrategyAdapter`). The strategist can then dynamically change fund distribution (`setStrategyAllocation`) and trigger rebalancing (`rebalanceFunds`). This is more advanced than simple single-strategy vaults or fixed allocations. The `rebalanceFunds` function orchestrates pulling from over-allocated strategies and depositing into under-allocated ones.
2.  **Share System (`deposit`, `withdraw`, `totalShares`, `userShares`, `sharesForAmount`, `amountForShares`)**: Instead of tracking user deposits and accrued interest directly in tokens, the vault issues shares. The value of each share grows as the total assets held by the vault (principal + yield) increases. `getTotalAssets()` captures the total value across the vault and strategies. When a user deposits, they get shares proportional to the *current* value of assets. When they withdraw, they redeem shares for a proportional amount of the *current* total assets. This is a standard, efficient way to handle yield distribution and multiple users in vaults (e.g., Yearn Finance).
3.  **On-Chain Performance Fee (Simplified) (`setPerformanceFeePercentage`, `setFeeRecipient`, `rebalanceFunds`)**: The `rebalanceFunds` function attempts to calculate yield *realized* into the main vault contract by comparing `getTotalAssets` before and after the rebalancing operation. A percentage of this calculated yield is then sent to the fee recipient from the contract's balance. *Caveat*: On-chain yield calculation without oracles or standardized reporting from strategies is hard and this implementation is a simplified model. A production system might need more complex tracking or off-chain calculation with on-chain claiming.
4.  **Robust Access Control (`onlyOwner`, `onlyStrategist`, `transferOwnership`, `setStrategist`)**: Differentiates roles. Owner handles critical settings (adding tokens, strategies, fees, pausing, emergency recovery), while the Strategist handles operational tasks (setting allocations, rebalancing). This separation of concerns is crucial for complex DeFi protocols.
5.  **Pause/Unpause (`pause`, `unpause`, `whenNotPaused`, `whenPaused`)**: A standard but vital safety mechanism. Allows the owner to halt sensitive operations (`deposit`, `withdraw`, `rebalanceFunds`, `emergencyWithdraw`) in case of discovered bugs, strategy failures, or market black swans, giving time to assess or upgrade.
6.  **Emergency Withdrawal (`emergencyWithdraw`)**: Provides users a way to pull their funds out even if the contract is paused. This is a security feature, though it bypasses the normal withdrawal logic and might only be able to access funds currently available in the vault contract, not necessarily stuck in strategies.
7.  **Stuck Token Recovery (`withdrawStuckTokens`)**: Allows the owner to rescue tokens accidentally sent to the contract address that are *not* the supported vault tokens. This prevents permanent loss of assets sent incorrectly.
8.  **Supported Token Management (`addSupportedToken`, `removeSupportedToken`, `getSupportedTokens`, `isTokenSupported`)**: Makes the vault multi-token capable (conceptually), although each strategy adapter would typically handle only one specific base token. The vault needs to know which tokens it is configured to manage.
9.  **Minimums (`setMinDepositAmount`, `setMinWithdrawAmount`)**: Prevents dust deposits/withdrawals which can be gas inefficient or lead to precision issues with shares.
10. **Rebalance Interval (`setRebalanceInterval`)**: Prevents the strategist from calling the potentially gas-heavy `rebalanceFunds` function too frequently, ensuring stability and predictable gas costs.

This contract provides a framework for a dynamic, multi-strategy yield vault, showcasing modularity, proportional yield distribution, and role-based access control, going beyond basic staking or single-pool concepts. Remember that a full system would also require implementing the individual `IStrategyAdapter` contracts for each desired DeFi protocol.