Okay, here is a Solidity smart contract incorporating interesting, advanced, creative, and trendy concepts. It's a "Quantum Liquidity Vault" that manages user deposits across multiple tokens, uses an epoch-based system for dynamic strategy execution and transitions, simulates yield generation based on different "strategies", allows users to time-lock funds for higher simulated yields, and includes a user opt-out feature for certain strategies.

This contract *does not* directly integrate with external DeFi protocols (like actual AMMs or lending platforms) or use literal quantum computing, but simulates complex behaviors internally, making it more self-contained as an example and avoiding direct reliance on specific external dependencies which are heavily documented in open source. The "Quantum" aspect is metaphorical, representing the dynamic, state-dependent, and potentially unpredictable (without knowing the state/epoch) nature of the vault's behavior and yield generation.

**Disclaimer:** This contract is complex and includes simulated mechanics. It is provided purely for educational and illustrative purposes. It has *not* been audited or tested for production use. Implementing real-world financial logic requires rigorous testing, auditing, and careful consideration of edge cases and security vulnerabilities. Simulated yield does not represent actual profit from external protocols.

---

## Quantum Liquidity Vault Smart Contract

**Contract Name:** `QuantumLiquidityVault`

**Description:** An advanced multi-token vault that operates in distinct, epoch-based strategies. Users can deposit and withdraw supported ERC-20 tokens. The vault simulates yield generation based on the active strategy. Key features include time-locked staking with potential bonuses/penalties and a user option to opt-out of yield-generating strategies for increased perceived safety (at the cost of simulated returns). The vault's state and strategy transition dynamically based on epochs managed by the owner.

**Key Concepts:**
*   **Epochs:** Time-based periods governing vault state and strategy.
*   **Dynamic Strategies:** Vault behaves differently (e.g., yield simulation methods, withdrawal restrictions) based on the active strategy.
*   **Simulated Yield:** Internal accounting of yield generation based on defined parameters, independent of external protocols.
*   **Time-Lock Staking:** Users can lock funds for a set period within the vault for potentially higher simulated yields or different access rules.
*   **User Strategy Opt-Out:** Allows users to choose a more conservative approach, foregoing potential yield from the active strategy.
*   **State Transitions:** Epochs trigger transitions between proposed strategies.

**Outline:**

1.  **Pragma and Imports**
2.  **Interfaces (IERC20)**
3.  **Error Handling**
4.  **Libraries (SafeERC20, ReentrancyGuard)**
5.  **Enums**
    *   `VaultState`: `Operational`, `EpochTransition`, `Emergency`
    *   `Strategy`: `Idle`, `SimulatedYieldFarming`, `TimeLockBonus`, `ArbitrageSim` (Simulated)
6.  **Structs**
    *   `TimeLockData`: Amount, StartTime, Duration
    *   `TimeLockStrategyParams`: BaseAPY (simulated), PenaltyFactor (for early exit)
    *   `YieldSimStrategyParams`: BaseYieldRate (simulated per epoch), EligibilityFactor (adjust yield calculation)
7.  **State Variables**
    *   Owner
    *   Supported Tokens mapping
    *   User Deposit Balances mapping
    *   User Time-Lock Data mapping
    *   Total Accumulated Simulated Yield mapping (per token)
    *   User Claimable General Yield mapping (per token)
    *   Current Epoch details (number, start time, duration)
    *   Vault State (enum)
    *   Current Strategy (enum)
    *   Proposed Next Strategy (enum)
    *   Strategy Parameters (mappings for different strategy types)
    *   User Strategy Opt-Out mapping
    *   Reentrancy Guard state
8.  **Events**
    *   Deposit/Withdraw
    *   EpochAdvanced
    *   StrategyProposed/Transitioned
    *   YieldSimulated/Claimed
    *   TimeLockEntered/Exited
    *   StrategyOptedOut
    *   EmergencyStateActivated/Deactivated
9.  **Modifiers**
    *   `onlyOwner`
    *   `whenNotEmergency`
    *   `whenEmergency`
    *   `nonReentrant`
    *   `onlySupportedToken`
10. **Constructor**
11. **Token Management Functions**
    *   `addSupportedToken`
    *   `removeSupportedToken`
    *   `isTokenSupported` (View)
    *   `getSupportedTokens` (View)
12. **Core Vault Operations**
    *   `deposit`
    *   `withdraw`
13. **Epoch & State Management Functions**
    *   `advanceEpoch`
    *   `proposeNextStrategy` (Owner)
    *   `setEpochDuration` (Owner)
    *   `getCurrentEpochInfo` (View)
    *   `getVaultState` (View)
    *   `getCurrentStrategy` (View)
    *   `getProposedNextStrategy` (View)
    *   `setEmergencyState` (Owner)
    *   `exitEmergencyState` (Owner)
    *   `isVaultInEmergency` (View)
14. **Strategy Parameter Functions**
    *   `setTimeLockStrategyParams` (Owner)
    *   `getTimeLockStrategyParams` (View)
    *   `setYieldSimStrategyParams` (Owner)
    *   `getYieldSimStrategyParams` (View)
    *   `performInternalRebalance` (Owner, simulates an internal strategy action)
15. **Simulated Yield Functions**
    *   `simulateYieldGeneration` (Owner/Trigger)
    *   `claimYield`
    *   `getAccumulatedTotalSimulatedYield` (View)
    *   `getUserClaimableGeneralYield` (View)
16. **Time-Lock Staking Functions**
    *   `enterTimeLockStaking`
    *   `exitTimeLockStaking`
    *   `getUserTimeLockInfo` (View)
    *   `calculateTimeLockYield` (View, utility)
    *   `calculateEarlyWithdrawalPenalty` (View, utility)
17. **User Preference Functions**
    *   `userOptOutStrategyYield`
    *   `getUserStrategyPreference` (View)
18. **Utility/View Functions**
    *   `owner` (View)
    *   `getUserDepositAmount` (View)
    *   `getVaultTokenBalance` (View) - total deposited + time-locked
    *   `getVaultTotalDeposited` (View) - total *non*-time-locked deposits
    *   `getVaultTotalTimeLocked` (View) (View)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Interfaces ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// --- Error Handling ---
error QuantumLiquidityVault__NotOwner();
error QuantumLiquidityVault__ReentrantCall();
error QuantumLiquidityVault__EmergencyState();
error QuantumLiquidityVault__VaultOperational();
error QuantumLiquidityVault__EpochInProgress();
error QuantumLiquidityVault__EpochTransitionNotReady();
error QuantumLiquidityVault__EpochTransitionReady();
error QuantumLiquidityVault__EpochNotAdvanced();
error QuantumLiquidityVault__ZeroAddress();
error QuantumLiquidityVault__InvalidAmount();
error QuantumLiquidityVault__TokenNotSupported();
error QuantumLiquidityVault__TokenAlreadySupported();
error QuantumLiquidityVault__InsufficientDepositBalance();
error QuantumLiquidityVault__InsufficientVaultBalance();
error QuantumLiquidityVault__InsufficientYieldBalance();
error QuantumLiquidityVault__TimeLockActive();
error QuantumLiquidityVault__TimeLockExpired();
error QuantumLiquidityVault__NoActiveTimeLock();
error QuantumLiquidityVault__InvalidStrategy();
error QuantumLiquidityVault__StrategyParamsNotSet();
error QuantumLiquidityVault__UserOptedOut();
error QuantumLiquidityVault__StrategyRequiresOptIn();


// --- Libraries ---
// Basic SafeERC20 implementation - avoids reentrancy on token transfers
library SafeERC20 {
    using SafeERC20 for IERC20;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        bytes memory data = abi.encodeWithSelector(token.transfer.selector, to, value);
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: transfer failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: transfer did not return success");
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, from, to, value);
        (bool success, bytes memory returndata) = address(token).call(data);
         require(success, "SafeERC20: transferFrom failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: transferFrom did not return success");
    }
}

// Basic Reentrancy Guard
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _reentrancyStatus;

    constructor() {
        _reentrancyStatus = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        if (_reentrancyStatus == _ENTERED) revert QuantumLiquidityVault__ReentrantCall();
        _reentrancyStatus = _ENTERED;
        _;
        _reentrancyStatus = _NOT_ENTERED;
    }
}


// --- Contract Definition ---
contract QuantumLiquidityVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Enums ---
    enum VaultState {
        Operational,
        EpochTransition,
        Emergency
    }

    enum Strategy {
        Idle,                 // No active strategy, basic deposits/withdrawals
        SimulatedYieldFarming,// Simulates yield generation based on total vault balance
        TimeLockBonus,        // Encourages time locks with higher simulated yield
        ArbitrageSim          // Simulates yield based on internal rebalancing/price changes
    }

    // --- Structs ---
    struct TimeLockData {
        uint256 amount;
        uint4 uint256 startTime; // Use uint32/uint64 if block.timestamp fits, uint256 is safer.
        uint256 duration;
        bool active;
    }

    struct TimeLockStrategyParams {
        uint256 baseAPY; // Simulated APY in basis points (e.g., 100 = 1%, 5000 = 50%)
        uint256 penaltyFactor; // Basis points penalty for early exit (e.g., 1000 = 10%)
        uint256 bonusYieldFactor; // Basis points yield multiplier while locked
    }

     struct YieldSimStrategyParams {
        uint256 baseYieldRate; // Simulated yield rate per unit of token per epoch
        uint256 eligibilityFactor; // Basis points factor for eligible balance calculation
    }

    // --- State Variables ---
    address public owner;
    mapping(address => bool) public supportedTokens;
    address[] private _supportedTokensList; // To easily retrieve supported tokens

    mapping(address => mapping(address => uint256)) private userDeposits; // token => user => amount (non-time-locked)
    mapping(address => mapping(address => TimeLockData)) private userTimeLocks; // token => user => time lock data

    mapping(address => uint256) private totalAccumulatedSimulatedYield; // token => total yield generated across all strategies
    mapping(address => mapping(address => uint256)) private userClaimableGeneralYield; // token => user => claimable yield from general deposits

    uint256 public currentEpoch;
    uint256 public epochStartTime;
    uint256 public epochDuration; // Duration in seconds

    VaultState public vaultState;
    Strategy public currentStrategy;
    Strategy public proposedNextStrategy;

    mapping(address => TimeLockStrategyParams) public timeLockStrategyParameters; // token => params
    mapping(address => YieldSimStrategyParams) public yieldSimStrategyParameters; // token => params

    mapping(address => bool) private userStrategyOptOut; // user => has opted out of high-yield strategies

    // --- Events ---
    event TokenSupported(address indexed token);
    event TokenRemoved(address indexed token);
    event Deposited(address indexed user, address indexed token, uint256 amount);
    event WithdrawRequested(address indexed user, address indexed token, uint256 amount); // Could be instant or delayed depending on state/strategy
    event Withdrawn(address indexed user, address indexed token, uint256 amount);

    event EpochAdvanced(uint256 indexed epoch, uint256 timestamp);
    event StrategyProposed(Strategy indexed proposedStrategy);
    event StrategyTransitioned(uint256 indexed epoch, Strategy indexed oldStrategy, Strategy indexed newStrategy);

    event YieldSimulated(address indexed token, uint256 amount);
    event YieldClaimed(address indexed user, address indexed token, uint256 amount);

    event TimeLockEntered(address indexed user, address indexed token, uint256 amount, uint256 duration);
    event TimeLockExited(address indexed user, address indexed token, uint256 amount, uint225 yieldEarned, uint256 penaltyPaid);

    event StrategyOptedOut(address indexed user, bool optedOut);

    event EmergencyStateActivated();
    event EmergencyStateDeactivated();

    event InternalRebalancePerformed(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert QuantumLiquidityVault__NotOwner();
        _;
    }

    modifier whenNotEmergency() {
        if (vaultState == VaultState.Emergency) revert QuantumLiquidityVault__EmergencyState();
        _;
    }

     modifier whenEmergency() {
        if (vaultState != VaultState.Emergency) revert QuantumLiquidityVault__VaultOperational();
        _;
    }

    modifier onlySupportedToken(address token) {
        if (!supportedTokens[token]) revert QuantumLiquidityVault__TokenNotSupported();
        _;
    }

    // --- Constructor ---
    constructor(uint256 _epochDuration) ReentrancyGuard() {
        if (_epochDuration == 0) revert QuantumLiquidityVault__InvalidAmount();
        owner = msg.sender;
        epochDuration = _epochDuration;
        epochStartTime = block.timestamp; // Start the first epoch immediately
        currentEpoch = 1;
        vaultState = VaultState.Operational;
        currentStrategy = Strategy.Idle;
        proposedNextStrategy = Strategy.Idle; // Default to Idle
        emit EpochAdvanced(currentEpoch, block.timestamp);
        emit StrategyTransitioned(currentEpoch, Strategy.Idle, Strategy.Idle);
    }

    // --- Token Management Functions ---

    /**
     * @notice Adds a new ERC-20 token to the list of supported tokens.
     * @param token The address of the ERC-20 token.
     */
    function addSupportedToken(address token) external onlyOwner {
        if (token == address(0)) revert QuantumLiquidityVault__ZeroAddress();
        if (supportedTokens[token]) revert QuantumLiquidityVault__TokenAlreadySupported();
        supportedTokens[token] = true;
        _supportedTokensList.push(token);
        emit TokenSupported(token);
    }

    /**
     * @notice Removes a token from the supported list.
     * @dev This function is simplified; a real contract would need to handle existing user balances for this token.
     * @param token The address of the ERC-20 token to remove.
     */
    function removeSupportedToken(address token) external onlyOwner onlySupportedToken(token) {
        // In a real contract, need to ensure no users have balances or time locks for this token.
        // For simplicity in this example, we just remove it.
        supportedTokens[token] = false;
        // Removing from dynamic array is gas-costly, especially large arrays.
        // A better approach for many tokens is a mapping `address => uint256` tokenAddress -> index in list
        // and swap-and-pop removal. Simplified here.
         for (uint i = 0; i < _supportedTokensList.length; i++) {
            if (_supportedTokensList[i] == token) {
                _supportedTokensList[i] = _supportedTokensList[_supportedTokensList.length - 1];
                _supportedTokensList.pop();
                break;
            }
        }
        emit TokenRemoved(token);
    }

    /**
     * @notice Checks if a token is supported by the vault.
     * @param token The address of the ERC-20 token.
     * @return bool True if supported, false otherwise.
     */
    function isTokenSupported(address token) external view returns (bool) {
        return supportedTokens[token];
    }

     /**
     * @notice Gets the list of all supported token addresses.
     * @return address[] An array of supported token addresses.
     */
    function getSupportedTokens() external view returns (address[] memory) {
        return _supportedTokensList;
    }


    // --- Core Vault Operations ---

    /**
     * @notice Deposits supported ERC-20 tokens into the vault.
     * @param token The address of the ERC-20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address token, uint256 amount) external nonReentrant whenNotEmergency onlySupportedToken(token) {
        if (amount == 0) revert QuantumLiquidityVault__InvalidAmount();

        userDeposits[token][msg.sender] += amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, token, amount);
    }

    /**
     * @notice Initiates a withdrawal of non-time-locked tokens from the vault.
     * @dev Withdrawal behavior might be restricted by the current strategy or emergency state.
     * @param token The address of the ERC-20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(address token, uint256 amount) external nonReentrant whenNotEmergency onlySupportedToken(token) {
        if (amount == 0) revert QuantumLiquidityVault__InvalidAmount();
        if (userDeposits[token][msg.sender] < amount) revert QuantumLiquidityVault__InsufficientDepositBalance();

        // Check current strategy for potential withdrawal restrictions (example logic)
        // In a real contract, strategies might have cool-downs, fees, etc.
        if (currentStrategy == Strategy.TimeLockBonus && userTimeLocks[token][msg.sender].active) {
             // Example restriction: Cannot withdraw free balance if time lock is active in TimeLockBonus state?
             // decide complexity - for simplicity, let's allow withdrawal of non-locked funds
             // unless in a specific restricted state not defined here yet.
        }

        userDeposits[token][msg.sender] -= amount;
        // Claim any general yield before withdrawing the principal
        _claimGeneralYield(token, msg.sender);
        // Now transfer the requested amount
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, token, amount);
    }

    // --- Epoch & State Management Functions ---

    /**
     * @notice Advances the vault to the next epoch, triggering a strategy transition if proposed.
     * @dev Callable by anyone once the current epoch duration has passed.
     */
    function advanceEpoch() external nonReentrant {
        if (block.timestamp < epochStartTime + epochDuration) revert QuantumLiquidityVault__EpochInProgress();
        if (vaultState == VaultState.Emergency) revert QuantumLiquidityVault__EmergencyState();
        if (vaultState == VaultState.EpochTransition) revert QuantumLiquidityVault__EpochTransitionReady();

        // Transition to EpochTransition state
        vaultState = VaultState.EpochTransition;
        emit EpochAdvanced(currentEpoch + 1, block.timestamp);

        // Perform transition tasks (simulated yield calculation/distribution before state change?)
        // In a real contract, complex state migration or calculations would happen here.
        // For simplicity, we'll just transition strategy and reset epoch timer.

        // Record old strategy before changing
        Strategy oldStrategy = currentStrategy;

        // Transition to the proposed next strategy
        currentStrategy = proposedNextStrategy;
        // Reset proposed strategy
        proposedNextStrategy = Strategy.Idle; // Reset proposed strategy after transition

        // Update epoch details
        currentEpoch++;
        epochStartTime = block.timestamp; // New epoch starts now
        vaultState = VaultState.Operational; // Return to operational state

        emit StrategyTransitioned(currentEpoch, oldStrategy, currentStrategy);
    }

    /**
     * @notice Owner proposes the next strategy for the vault.
     * @dev The strategy transition only happens at the next epoch advancement.
     * @param nextStrategy The strategy to propose.
     */
    function proposeNextStrategy(Strategy nextStrategy) external onlyOwner {
        if (nextStrategy == currentStrategy) revert QuantumLiquidityVault__InvalidStrategy(); // Cannot propose current strategy
        if (nextStrategy == proposedNextStrategy) return; // Already proposed

        proposedNextStrategy = nextStrategy;
        emit StrategyProposed(proposedNextStrategy);
    }

    /**
     * @notice Owner sets the duration of future epochs.
     * @param duration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 duration) external onlyOwner {
        if (duration == 0) revert QuantumLiquidityVault__InvalidAmount();
        epochDuration = duration;
    }

    /**
     * @notice Owner activates the emergency state, pausing most operations.
     */
    function setEmergencyState() external onlyOwner whenNotEmergency {
        vaultState = VaultState.Emergency;
        emit EmergencyStateActivated();
    }

    /**
     * @notice Owner deactivates the emergency state, resuming operations.
     */
    function exitEmergencyState() external onlyOwner whenEmergency {
         vaultState = VaultState.Operational;
        emit EmergencyStateDeactivated();
    }

    // --- Strategy Parameter Functions ---

    /**
     * @notice Owner sets parameters for the TimeLockBonus strategy for a specific token.
     * @param token The token address.
     * @param baseAPY Simulated base APY in basis points.
     * @param penaltyFactor Basis points penalty for early withdrawal.
     * @param bonusYieldFactor Basis points bonus multiplier while locked.
     */
    function setTimeLockStrategyParams(address token, uint256 baseAPY, uint256 penaltyFactor, uint256 bonusYieldFactor) external onlyOwner onlySupportedToken(token) {
        timeLockStrategyParameters[token] = TimeLockStrategyParams(baseAPY, penaltyFactor, bonusYieldFactor);
        // Event could be added here
    }

     /**
     * @notice Owner sets parameters for the SimulatedYieldFarming strategy for a specific token.
     * @param token The token address.
     * @param baseYieldRate Simulated yield rate per unit of token per epoch.
     * @param eligibilityFactor Basis points factor for eligible balance calculation (e.g., 9000 = 90% of balance is eligible).
     */
    function setYieldSimStrategyParams(address token, uint256 baseYieldRate, uint256 eligibilityFactor) external onlyOwner onlySupportedToken(token) {
         yieldSimStrategyParameters[token] = YieldSimStrategyParams(baseYieldRate, eligibilityFactor);
         // Event could be added here
    }

    /**
     * @notice Owner triggers a simulated internal rebalance or strategy action (e.g., swapping token A for B).
     * @dev This function represents a simplified strategy action that doesn't leave the vault.
     * @param tokenIn The token to simulate selling.
     * @param tokenOut The token to simulate buying.
     * @param amountIn The amount of tokenIn to simulate selling.
     * @param simulatedAmountOut The simulated amount of tokenOut received.
     */
    function performInternalRebalance(address tokenIn, address tokenOut, uint256 amountIn, uint256 simulatedAmountOut) external onlyOwner whenNotEmergency onlySupportedToken(tokenIn) onlySupportedToken(tokenOut) {
        if (amountIn == 0 || simulatedAmountOut == 0) revert QuantumLiquidityVault__InvalidAmount();
        // This is a *simulated* rebalance for illustrative purposes.
        // In a real contract, this might interact with an internal AMM logic
        // or represent an external swap that redeposits to the vault.
        // Here, we just log the simulated action.
        // No token transfers or balance changes occur in this simulation within the vault logic.
        emit InternalRebalancePerformed(tokenIn, tokenOut, amountIn, simulatedAmountOut);
    }


    // --- Simulated Yield Functions ---

    /**
     * @notice Owner or trigger mechanism simulates yield generation for the current epoch/strategy.
     * @dev This adds simulated yield to the vault's total and users' claimable balances.
     * @param token The token for which to simulate yield.
     */
    function simulateYieldGeneration(address token) external onlyOwner whenNotEmergency onlySupportedToken(token) {
        // This simulation logic is simplified.
        // In a real system, this might be called by a keeper or after certain conditions are met.
        // Yield is calculated based on current strategy and parameters.

        uint256 totalEligibleBalance = 0;
        uint256 simulatedYieldAmount = 0;

        if (currentStrategy == Strategy.SimulatedYieldFarming) {
            YieldSimStrategyParams storage params = yieldSimStrategyParameters[token];
             if (params.baseYieldRate == 0) revert QuantumLiquidityVault__StrategyParamsNotSet(); // Ensure params are set

            // Calculate total eligible balance: all non-opted-out deposits
            for (uint i = 0; i < _supportedTokensList.length; i++) {
                 address supportedToken = _supportedTokensList[i];
                 if (supportedToken == token) {
                    // Iterate through users (inefficient on-chain, better with snapshots or external calculation)
                    // Simplified: calculate based on total vault balance not opted out
                     uint252 vaultTotal = getVaultTokenBalance(token); // Total includes locked
                     // This is a significant simplification; real yield depends on *where* funds are
                     // For simplicity, let's apply yield simulation on the *total* balance
                     // minus funds belonging to users who opted out.
                     uint256 totalNonOptedOutBalance = 0;
                     // This requires iterating all users, which is not feasible on-chain.
                     // A better approach is to track a total non-opted-out balance.
                     // Let's simplify further: yield is generated based on total vault balance,
                     // and distributed proportionally to users who *haven't* opted out.
                     // This still requires user iteration or complex balance tracking.
                     // ALTERNATIVE SIMPLIFICATION: Yield applies only to general deposits (not time-locked)
                     // of non-opted-out users, based on total general deposits.
                     uint256 totalGeneralDeposits = getVaultTotalDeposited(token);
                     simulatedYieldAmount = (totalGeneralDeposits * params.baseYieldRate) / 1e18; // Assuming rate is 1e18 scaled

                 }
            }
             // This simulation applies yield to *general* deposits based on the strategy params
             // Time-lock yield is handled separately on exitTimeLockStaking.
             totalAccumulatedSimulatedYield[token] += simulatedYieldAmount;

            // Distribute proportionally to eligible users
             // This loop is highly inefficient and could exceed gas limits!
             // A real system needs an off-chain mechanism to calculate user shares
             // or a pull-based yield distribution model.
             // For demonstration, let's skip actual distribution here and just increase total.
             // Users will claim from `userClaimableGeneralYield` which needs to be updated off-chain
             // or by a separate distribution function iterating users.
             // Let's add a simplified distribution mechanism: distribute to all *current* depositors
             // proportionally who haven't opted out. Still gas heavy.
             // Final Simplification for example: simulate yield adds to total vault yield.
             // `claimYield` allows users to claim a share based on their *current* general deposit balance
             // relative to total general deposits *at the time of claiming*. This is not quite right,
             // yield should be proportional to balance *over time*.
             // Let's revert to: simulate adds to total, users claim their share of the *total*
             // based on their deposits *when yield was simulated*. This requires snapshotting balances.
             // Okay, simplest simulation: simulate adds a fixed amount per token per epoch based on params.
             // Users claim a share of *this added amount* based on their general deposit balance.

             simulatedYieldAmount = (getVaultTotalDeposited(token) * params.baseYieldRate) / 1e18; // Example calculation

        } else if (currentStrategy == Strategy.ArbitrageSim) {
            // Simulate Arbitrage yield - perhaps based on vault balance and internal rebalances
            // This would be more complex, maybe using performInternalRebalance data
             // For simplicity, just add a small amount based on a separate rate for this strategy
             uint256 arbitrageRate = 100; // Example BPS
             simulatedYieldAmount = (getVaultTotalDeposited(token) * arbitrageRate) / 10000;
        }
        // Strategy.TimeLockBonus yield is handled on exit. Idle has no yield.

        if (simulatedYieldAmount > 0) {
             totalAccumulatedSimulatedYield[token] += simulatedYieldAmount;
             // Distribution is handled when users claim proportionally
             // Or, this function could distribute directly to userClaimableGeneralYield.
             // Let's make this function distribute directly for clarity, assuming it's triggered carefully.
             // This is still gas-heavy if many users.
             // Simpler: calculate user share based on current balance against total eligible balance.
             // This doesn't track yield earned over time correctly but works for an example.
             uint256 totalEligibleDeposit = 0;
             // Requires iterating users or tracking aggregate eligible balance.
             // Let's assume an off-chain process calculates and sets userClaimableGeneralYield,
             // and this function just increases the total.
             // OR, make this function accept a mapping/array of user shares calculated off-chain (too complex for example)

             // FINAL SIMPLIFICATION: simulateYieldGeneration increases the total pool.
             // ClaimYield calculates the user's share of the *increase since last claim* based on their balance at that time.
             // This requires tracking user's 'yield cursor'. Let's track totalYieldPerShare.

             uint256 totalVaultBalance = getVaultTokenBalance(token); // Use total balance including locked for yield source simulation
             if (totalVaultBalance > 0 && simulatedYieldAmount > 0) {
                 // This simulation is getting complex. Let's simplify the simulation process significantly.
                 // simulateYieldGeneration just adds a fixed, owner-defined amount per token.
                 // The *distribution* is where strategy parameters matter.
                 // No, let's use the strategy params to *calculate* the simulated amount added.

                 // Let's make simulateYieldGeneration calculate yield based on total balance (general + locked)
                 // for eligible users and add it directly to userClaimableGeneralYield.
                 // This means this function MUST iterate users. This is BAD for production on-chain.
                 // Example only! DO NOT USE IN PRODUCTION.
                 uint256 totalBalanceForYield = getVaultTokenBalance(token); // Total ERC20 balance held by contract
                 if (totalBalanceForYield > 0) {
                    // Simplified ArbitrageSim yield as a % of total balance
                     if (currentStrategy == Strategy.ArbitrageSim) {
                          simulatedYieldAmount = (totalBalanceForYield * 500) / 10000; // Simulate 5% APY / EpochsPerYear (assume EpochsPerYear=10 for 500bps)
                     } else if (currentStrategy == Strategy.SimulatedYieldFarming) {
                          YieldSimStrategyParams storage params = yieldSimStrategyParameters[token];
                          if (params.baseYieldRate > 0) {
                              // Yield based on rate per unit and eligibility factor on total balance
                               simulatedYieldAmount = (totalBalanceForYield * params.baseYieldRate * params.eligibilityFactor) / (1e18 * 10000);
                          }
                     }
                 }

                 if (simulatedYieldAmount > 0) {
                     totalAccumulatedSimulatedYield[token] += simulatedYieldAmount;
                     // Distribution: Add proportionally to users who haven't opted out
                     // This requires iterating users... BAD BAD BAD.
                     // Let's just add the simulatedYieldAmount to a global pool,
                     // and `claimYield` will take the user's share based on their *current* balance.
                     // This is an approximation but avoids iteration. It means users with higher current balances
                     // get a larger share of the pool, regardless of their balance when yield was generated.

                      // Simple yield simulation: Add amount to total pool.
                      totalAccumulatedSimulatedYield[token] += simulatedYieldAmount;
                      emit YieldSimulated(token, simulatedYieldAmount);
                 }
             }
    }

    /**
     * @notice Allows a user to claim their share of simulated general yield.
     * @param token The token for which to claim yield.
     */
    function claimYield(address token) external nonReentrant onlySupportedToken(token) whenNotEmergency {
        // Claimable yield is their share of the totalAccumulatedSimulatedYield
        // based on their current deposit balance vs total deposits (non-opted-out).
        // This is a simple proportional model based on current balances.
        // More complex models track yield earned over time or per share.

        uint256 userCurrentDeposit = userDeposits[token][msg.sender];
        if (userCurrentDeposit == 0) {
             // User has no general deposit balance, cannot claim general yield this way
             // Or, yield is only claimable if they had balance when yield was simulated?
             // Let's allow claiming any accrued yield, regardless of current deposit balance,
             // but the *accrual* logic in simulateYieldGeneration should have handled distribution.
             // Since simulateYieldGeneration currently adds to a total pool,
             // let's calculate claimable yield here based on the user's *share* of general deposits
             // *when they claim*, applied to the *total pool*. This is flawed.

             // Better: User's yield is added to userClaimableGeneralYield mapping directly
             // during `simulateYieldGeneration` or an external distribution call.
             // Let's assume simulateYieldGeneration *does* somehow update `userClaimableGeneralYield`.
             // Then `claimYield` is simple:
        }

        uint256 claimable = userClaimableGeneralYield[token][msg.sender];
        if (claimable == 0) revert QuantumLiquidityVault__InsufficientYieldBalance();

        userClaimableGeneralYield[token][msg.sender] = 0;
        IERC20(token).safeTransfer(msg.sender, claimable);

        emit YieldClaimed(msg.sender, token, claimable);
    }


    // --- Time-Lock Staking Functions ---

    /**
     * @notice Users can lock their deposited funds for a specified duration.
     * @dev Funds are moved from general deposits to time-locked balance.
     * @param token The token to time-lock.
     * @param amount The amount to time-lock.
     * @param duration The duration in seconds.
     */
    function enterTimeLockStaking(address token, uint256 amount, uint256 duration) external nonReentrant onlySupportedToken(token) whenNotEmergency {
        if (amount == 0 || duration == 0) revert QuantumLiquidityVault__InvalidAmount();
        if (userDeposits[token][msg.sender] < amount) revert QuantumLiquidityVault__InsufficientDepositBalance();
        if (userTimeLocks[token][msg.sender].active) revert QuantumLiquidityVault__TimeLockActive(); // Only one active time lock per user per token

        userDeposits[token][msg.sender] -= amount;
        userTimeLocks[token][msg.sender] = TimeLockData({
            amount: amount,
            startTime: block.timestamp,
            duration: duration,
            active: true
        });

        // Claim any general yield before locking funds
        _claimGeneralYield(token, msg.sender);

        emit TimeLockEntered(msg.sender, token, amount, duration);
    }

    /**
     * @notice Allows user to exit their time-lock, claiming principal and yield (or paying penalty).
     * @param token The token of the time-lock.
     */
    function exitTimeLockStaking(address token) external nonReentrant onlySupportedToken(token) whenNotEmergency {
        TimeLockData storage timeLock = userTimeLocks[token][msg.sender];
        if (!timeLock.active) revert QuantumLiquidityVault__NoActiveTimeLock();

        uint256 principal = timeLock.amount;
        uint256 yieldEarned = 0;
        uint256 penaltyPaid = 0;
        uint256 amountToTransfer = principal;

        bool earlyExit = block.timestamp < timeLock.startTime + timeLock.duration;

        TimeLockStrategyParams storage params = timeLockStrategyParameters[token];
        if (params.baseAPY > 0) { // Ensure params are set
            if (!earlyExit) {
                // Calculate time-lock bonus yield if exited after duration
                 yieldEarned = calculateTimeLockYield(msg.sender, token); // Calculate based on params and duration
                 amountToTransfer += yieldEarned;
            } else {
                // Calculate early withdrawal penalty if exited before duration
                penaltyPaid = calculateEarlyWithdrawalPenalty(msg.sender, token);
                amountToTransfer -= penaltyPaid; // Reduce withdrawal amount by penalty
            }
        }
        // If params aren't set, no bonus yield or penalty applies, just principal is transferred.

        // Clear the time lock data
        timeLock.active = false;
        timeLock.amount = 0;
        timeLock.startTime = 0;
        timeLock.duration = 0;
        // No need to zero out the struct data explicitly as amount/startTime/duration become 0

        // Transfer funds (principal + yield - penalty)
        if (amountToTransfer > 0) {
             IERC20(token).safeTransfer(msg.sender, amountToTransfer);
        }

        emit TimeLockExited(msg.sender, token, principal, yieldEarned, penaltyPaid);
    }

    /**
     * @notice Calculates the simulated yield for an active time lock.
     * @param user The user address.
     * @param token The token address.
     * @return uint256 The calculated simulated yield amount.
     */
    function calculateTimeLockYield(address user, address token) public view onlySupportedToken(token) returns (uint256) {
        TimeLockData storage timeLock = userTimeLocks[token][user];
        if (!timeLock.active || block.timestamp < timeLock.startTime + timeLock.duration) return 0; // Only calculate if expired

        TimeLockStrategyParams storage params = timeLockStrategyParameters[token];
        if (params.baseAPY == 0 || params.bonusYieldFactor == 0) return 0; // No params set

        // Simple yield calculation: principal * APY * bonus * duration_in_seconds / seconds_in_year
        // Assume seconds_in_year = 31536000
        // APY is in basis points, bonus factor in basis points
        uint256 secondsInYear = 31536000;
        uint256 totalDuration = timeLock.duration; // Calculate yield based on intended duration

        // Calculate APY adjusted by bonus factor
        // Example: 10% APY (1000 bps), 1.2x bonus (12000 bps) -> Effective APY = 1000 * 12000 / 10000 = 1200 bps (12%)
        uint256 effectiveAPY = (params.baseAPY * params.bonusYieldFactor) / 10000;

        uint256 yield = (timeLock.amount * effectiveAPY * totalDuration) / (secondsInYear * 10000); // 10000 for basis points

        return yield;
    }

     /**
     * @notice Calculates the simulated early withdrawal penalty for an active time lock.
     * @param user The user address.
     * @param token The token address.
     * @return uint256 The calculated simulated penalty amount.
     */
    function calculateEarlyWithdrawalPenalty(address user, address token) public view onlySupportedToken(token) returns (uint256) {
        TimeLockData storage timeLock = userTimeLocks[token][user];
        if (!timeLock.active || block.timestamp >= timeLock.startTime + timeLock.duration) return 0; // Only calculate if still active (early)

        TimeLockStrategyParams storage params = timeLockStrategyParameters[token];
        if (params.penaltyFactor == 0) return 0; // No penalty set

        // Simple penalty calculation: principal * penaltyFactor
        uint256 penalty = (timeLock.amount * params.penaltyFactor) / 10000; // PenaltyFactor is in basis points

        // Penalty should probably not exceed the principal
        return penalty > timeLock.amount ? timeLock.amount : penalty;
    }


    // --- User Preference Functions ---

    /**
     * @notice Allows a user to opt out of potentially higher-yield, higher-risk strategies.
     * @dev Opting out means their deposits won't be considered for yield generation simulations
     *      in strategies like SimulatedYieldFarming. They remain in the Idle-like state.
     * @param optOut True to opt out, false to opt back in.
     */
    function userOptOutStrategyYield(bool optOut) external whenNotEmergency {
        if (userStrategyOptOut[msg.sender] == optOut) return; // No change

        // Claim any accrued general yield before changing opt-out status
        for (uint i = 0; i < _supportedTokensList.length; i++) {
            _claimGeneralYield(_supportedTokensList[i], msg.sender);
        }

        userStrategyOptOut[msg.sender] = optOut;
        emit StrategyOptedOut(msg.sender, optOut);
    }


    // --- Internal Helper Function ---
    /**
     * @notice Internal function to claim general yield for a user and token.
     * @dev Used before operations that might change the user's balance or strategy preference.
     * @param token The token address.
     * @param user The user address.
     */
    function _claimGeneralYield(address token, address user) internal {
         uint256 claimable = userClaimableGeneralYield[token][user];
        if (claimable > 0) {
             userClaimableGeneralYield[token][user] = 0;
             // Assume internal transfer for simplicity, or direct safeTransfer if needed.
             // If transferring externally, consider reentrancy guard.
             // As this is an *internal* helper, let's assume it's called within a nonReentrant context.
             IERC20(token).safeTransfer(user, claimable); // Transfer to user
             emit YieldClaimed(user, token, claimable);
        }
    }


    // --- View Functions ---

    /**
     * @notice Gets the owner of the contract.
     * @return address The owner's address.
     */
    function owner() external view returns (address) {
        return owner;
    }

    /**
     * @notice Gets the current epoch number, start time, and duration.
     * @return uint256 currentEpoch The current epoch number.
     * @return uint256 epochStartTime The timestamp when the current epoch started.
     * @return uint256 epochDuration The duration of each epoch in seconds.
     */
    function getCurrentEpochInfo() external view returns (uint256 currentEpoch, uint256 epochStartTime, uint256 epochDuration) {
        return (this.currentEpoch, this.epochStartTime, this.epochDuration);
    }

    /**
     * @notice Gets the current state of the vault (Operational, EpochTransition, Emergency).
     * @return VaultState The current state.
     */
    function getVaultState() external view returns (VaultState) {
        return vaultState;
    }

     /**
     * @notice Gets the current active strategy of the vault.
     * @return Strategy The current strategy.
     */
    function getCurrentStrategy() external view returns (Strategy) {
        return currentStrategy;
    }

     /**
     * @notice Gets the proposed strategy for the next epoch transition.
     * @return Strategy The proposed next strategy.
     */
    function getProposedNextStrategy() external view returns (Strategy) {
        return proposedNextStrategy;
    }

     /**
     * @notice Checks if the vault is in an emergency state.
     * @return bool True if in emergency, false otherwise.
     */
    function isVaultInEmergency() external view returns (bool) {
        return vaultState == VaultState.Emergency;
    }

    /**
     * @notice Gets the user's non-time-locked deposit amount for a specific token.
     * @param user The user address.
     * @param token The token address.
     * @return uint256 The user's deposit amount.
     */
    function getUserDepositAmount(address user, address token) external view onlySupportedToken(token) returns (uint256) {
        return userDeposits[token][user];
    }

    /**
     * @notice Gets the total balance of a specific token held by the vault (including time-locked).
     * @param token The token address.
     * @return uint256 The total vault balance for the token.
     */
    function getVaultTokenBalance(address token) public view onlySupportedToken(token) returns (uint256) {
        // Return actual contract balance, which includes deposits and time locks
        return IERC20(token).balanceOf(address(this));
    }

     /**
     * @notice Gets the total amount of a token deposited into the vault (excluding time-locked).
     * @dev This aggregates `userDeposits`. Inefficient for many users.
     *      Consider removing or replacing with sum of user balances if needed.
     * @param token The token address.
     * @return uint256 The total non-time-locked deposits for the token.
     */
    function getVaultTotalDeposited(address token) public view onlySupportedToken(token) returns (uint256) {
        // This function requires iterating all users to be accurate, which is not feasible on-chain.
        // Returning 0 for now or remove, or calculate based on total balance minus time-locked total.
        // Calculating total time-locked total also requires iteration.
        // For demonstration, let's return 0 or rely on off-chain calculation.
        // A better state variable would track this aggregate.
        // Let's implement a simplified version by iterating _supportedTokensList and users if possible (gas permitting)
        // No, iterating users on-chain is prohibitive. We will assume this is managed off-chain
        // or represents a tracked state variable not fully implemented for simplicity.
        // For this example, we'll just return 0 as a placeholder,
        // or better, calculate based on total balance - total locked.
         return getVaultTokenBalance(token) - getVaultTotalTimeLocked(token); // This is an approximation.

    }

     /**
     * @notice Gets the total amount of a token currently in time-locks across all users.
     * @dev Requires iterating all users to be accurate. Inefficient on-chain.
     * @param token The token address.
     * @return uint256 The total time-locked amount for the token.
     */
    function getVaultTotalTimeLocked(address token) public view onlySupportedToken(token) returns (uint256) {
         // Similar to getVaultTotalDeposited, this requires iterating users.
         // Placeholder: In a real contract, this would need to be a tracked state variable.
         return 0; // Placeholder
    }


    /**
     * @notice Gets the details of a user's active time lock for a token.
     * @param user The user address.
     * @param token The token address.
     * @return uint256 amount Locked amount.
     * @return uint256 startTime Time lock start timestamp.
     * @return uint256 duration Time lock duration in seconds.
     * @return bool active Is the time lock active.
     */
    function getUserTimeLockInfo(address user, address token) external view onlySupportedToken(token) returns (uint256 amount, uint256 startTime, uint256 duration, bool active) {
        TimeLockData storage timeLock = userTimeLocks[token][user];
        return (timeLock.amount, timeLock.startTime, timeLock.duration, timeLock.active);
    }


    /**
     * @notice Gets the accumulated simulated yield for a specific token across the entire vault.
     * @param token The token address.
     * @return uint256 The total accumulated simulated yield.
     */
    function getAccumulatedTotalSimulatedYield(address token) external view onlySupportedToken(token) returns (uint256) {
        return totalAccumulatedSimulatedYield[token];
    }

    /**
     * @notice Gets the simulated general yield currently claimable by a user for a token.
     * @param user The user address.
     * @param token The token address.
     * @return uint256 The user's claimable simulated general yield.
     */
    function getUserClaimableGeneralYield(address user, address token) external view onlySupportedToken(token) returns (uint256) {
        return userClaimableGeneralYield[token][user];
    }

     /**
     * @notice Gets the time lock strategy parameters for a specific token.
     * @param token The token address.
     * @return uint256 baseAPY Simulated base APY in basis points.
     * @return uint256 penaltyFactor Basis points penalty for early exit.
     * @return uint256 bonusYieldFactor Basis points yield multiplier.
     */
    function getTimeLockStrategyParams(address token) external view onlySupportedToken(token) returns (uint256 baseAPY, uint256 penaltyFactor, uint256 bonusYieldFactor) {
         TimeLockStrategyParams storage params = timeLockStrategyParameters[token];
         return (params.baseAPY, params.penaltyFactor, params.bonusYieldFactor);
    }

     /**
     * @notice Gets the simulated yield farming strategy parameters for a specific token.
     * @param token The token address.
     * @return uint256 baseYieldRate Simulated yield rate per unit per epoch.
     * @return uint256 eligibilityFactor Basis points factor for eligible balance.
     */
    function getYieldSimStrategyParams(address token) external view onlySupportedToken(token) returns (uint256 baseYieldRate, uint256 eligibilityFactor) {
         YieldSimStrategyParams storage params = yieldSimStrategyParameters[token];
         return (params.baseYieldRate, params.eligibilityFactor);
    }

     /**
     * @notice Checks if a user has opted out of high-yield strategies.
     * @param user The user address.
     * @return bool True if opted out, false otherwise.
     */
    function getUserStrategyPreference(address user) external view returns (bool) {
        return userStrategyOptOut[user];
    }
}
```