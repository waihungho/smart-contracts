Okay, let's craft an advanced, creative, and feature-rich DeFi smart contract that acts as a dynamic yield optimizer vault with a decentralized strategy proposal and voting system.

This contract allows users to deposit various allowed tokens, which are then strategically deployed into different external yield-generating protocols ("Strategies") chosen and voted upon by the community (or a designated group). It handles rebalancing, yield reinvestment, performance fees, and offers emergency withdrawal mechanisms.

**Concept:** Dynamic Yield Optimization Vault with Strategy Governance.

**Advanced Concepts:**
1.  **Dynamic Strategy Allocation:** Funds are not tied to a single strategy but can be distributed across multiple, with adjustable allocations.
2.  **Strategy Proposal & Voting:** A mechanism for users/admins to propose new yield strategies and for stakeholders to vote on their inclusion and initial allocation.
3.  **Yield Reinvestment & Auto-Compounding:** Automatically harvests yield from strategies and compounds it back into the vault, increasing the value per share.
4.  **Performance Fees:** Charges a fee on generated yield, distributed to a fee recipient.
5.  **Multi-Token Support (via Base Token Conversion):** Allows deposits of multiple ERC20 tokens, converting them to a designated "Base Token" internally for simplified accounting and strategy interaction (strategies are assumed to operate primarily with the base token or standard pairs involving it).
6.  **Vault Shares (ERC20):** The contract itself acts as an ERC20 token representing shares in the vault's total value locked (TVL).
7.  **DEX Aggregator Integration:** Uses an external DEX aggregator to facilitate token swaps needed for multi-token deposits, rebalancing, or panic withdrawals.
8.  **Panic Withdrawal:** An emergency function to quickly pull funds out of strategies back into the vault if needed.

**Non-Duplication:** While yield farms, vaults, and governance systems exist, this specific combination of:
*   Dynamic allocation *managed by the contract*.
*   A specific on-chain *proposal and voting system for adding new strategies*.
*   Multi-token deposit *converting to a base token* managed within an ERC20 vault.
*   Integration with a *generic DEX aggregator*.
*   Coupled with advanced features like performance fees, reinvestment, and panic withdrawal within a single contract scope.

...creates a unique architecture that isn't a direct copy of standard Yearn vaults, Compound/Aave lending pools, or simple staking contracts. The strategy governance mechanism is more advanced than just admin-controlled strategy lists.

---

**Outline:**

1.  **License & Pragma**
2.  **Imports** (ERC20, SafeMath or built-in checks)
3.  **Interfaces** (IERC20, IYieldStrategy, IDEXAggregator)
4.  **Events** (covering all major actions)
5.  **Error Handling** (custom errors for clarity)
6.  **State Variables** (Owner, fee recipient, fee percentage, strategy mapping, allowed tokens mapping, proposal mapping, voting threshold, DEX aggregator address, base token address, total shares, etc.)
7.  **Structs** (StrategyInfo, StrategyProposal)
8.  **Modifiers** (onlyOwner, onlyAllowedToken, etc.)
9.  **ERC20 Implementation** (standard functions: `transfer`, `approve`, `totalSupply`, `balanceOf`, `transferFrom`, `allowance`) - These operate on vault shares.
10. **Constructor** (Initializes owner, base token, fee recipient, threshold)
11. **Access Control Functions** (`transferOwnership`, `renounceOwnership`)
12. **Vault Management Functions** (`deposit`, `withdraw`, `addAllowedToken`, `removeAllowedToken`, `panicWithdraw`, `getTotalValue`, `getBaseToken`, `getAllowedTokens`)
13. **Strategy Management Functions** (`addStrategy`, `removeStrategy`, `updateStrategyAllocation`, `rebalanceStrategies`, `reinvestYield`, `getStrategyInfo`, `getCurrentStrategyAllocations`)
14. **Strategy Governance Functions** (`proposeStrategy`, `voteForStrategy`, `executeStrategyProposal`, `setStrategyApprovalThreshold`, `getPendingStrategyVotes`)
15. **Fee Management Functions** (`setPerformanceFee`, `claimFees`, `getPerformanceFee`, `setFeeRecipient`)
16. **DEX Integration Functions** (`setDEXAggregator`, `swapTokens` - internal/admin utility)
17. **Internal/Helper Functions** (`_getTotalValue`, `_depositToBaseToken`, `_calculateSharesMinted`, `_calculateAmountOut`, `_safeTransfer`, `_safeTransferFrom`, `_safeApprove`)

---

**Function Summary:**

1.  `constructor()`: Initializes the contract with essential parameters like owner, base token, initial fee recipient, and strategy approval threshold.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership.
3.  `renounceOwnership()`: Renounces contract ownership (sets to zero address).
4.  `deposit(uint256 amount, address tokenIn)`: Allows a user to deposit `tokenIn`. If `tokenIn` is not the base token, it is swapped to the base token using the DEX aggregator. Shares in the vault proportional to the base token value deposited are minted to the user.
5.  `withdraw(uint256 sharesAmount)`: Allows a user to burn `sharesAmount` and receive the equivalent value in the base token from the vault's holdings.
6.  `addAllowedToken(address token)`: Allows the owner/admin to add a token address to the list of accepted deposit tokens.
7.  `removeAllowedToken(address token)`: Allows the owner/admin to remove a token address from the list of accepted deposit tokens.
8.  `getAllowedTokens() view`: Returns the list of allowed deposit tokens.
9.  `panicWithdraw(address tokenOut)`: Allows owner/admin to emergency withdraw a specific token (`tokenOut`) from all strategies and the vault balance to the owner/admin address. Funds are *not* returned to users via shares here; this is for emergency recovery.
10. `addStrategy(address strategyAddress, uint252 initialAllocationBps)`: Allows the owner/admin to add a *pre-approved* strategy (e.g., simple, trusted ones initially) with a target allocation percentage (in basis points).
11. `removeStrategy(address strategyAddress)`: Allows the owner/admin to remove an active strategy. Requires withdrawing all funds from that strategy first.
12. `updateStrategyAllocation(address strategyAddress, uint252 newAllocationBps)`: Allows the owner/admin to change the target allocation percentage for an active strategy.
13. `rebalanceStrategies()`: Rebalances funds across active strategies based on their current target allocation percentages. This involves withdrawing from over-allocated strategies and depositing into under-allocated ones, possibly using the DEX aggregator for token conversions if strategies hold different assets (in this design, assumes base token primarily).
14. `reinvestYield()`: Iterates through active strategies, harvests their yield, converts harvested tokens to the base token (if necessary) via the DEX aggregator, and redeposits the base token into strategies according to current allocations. Calculates and collects the performance fee before reinvestment.
15. `getStrategyInfo(address strategyAddress) view`: Returns details about a specific strategy (active status, target allocation).
16. `getCurrentStrategyAllocations() view`: Returns the current target allocation for all active strategies.
17. `proposeStrategy(address strategyAddress, uint252 initialAllocationBps)`: Allows a user/admin to propose a new strategy address and its initial target allocation for community voting.
18. `voteForStrategy(address strategyAddress)`: Allows a stakeholder (e.g., share holder, or specific voter group) to vote in favor of a proposed strategy. (Simple 1 address = 1 vote or share-weighted vote based on implementation detail - keeping it simple here).
19. `executeStrategyProposal(address strategyAddress)`: Allows anyone to execute an approved strategy proposal if it has met the voting threshold and hasn't expired (timeout mechanism could be added). Adds the strategy to the active list.
20. `setStrategyApprovalThreshold(uint256 threshold)`: Allows the owner/admin to set the minimum number of votes required to approve a strategy proposal.
21. `getPendingStrategyVotes(address strategyAddress) view`: Returns the current vote count for a strategy proposal.
22. `setPerformanceFee(uint252 newFeeBps)`: Allows the owner/admin to update the performance fee percentage.
23. `claimFees()`: Allows the fee recipient to claim collected performance fees.
24. `getPerformanceFee() view`: Returns the current performance fee percentage.
25. `setFeeRecipient(address recipient)`: Allows the owner/admin to change the address that receives performance fees.
26. `setDEXAggregator(address aggregator)`: Allows the owner/admin to set the address of the trusted DEX aggregator contract.
27. `swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address recipient)`: Internal or admin-callable utility function to perform a token swap via the configured DEX aggregator. Used in deposit, rebalance, reinvest, panicWithdraw.
28. `getTotalValue() view`: Calculates the total value locked in the vault (sum of balances in the vault contract and within all active strategies), expressed in terms of the `baseToken` equivalent.
29. `getBaseToken() view`: Returns the address of the base token used by the vault.
30. `balanceOf(address account) view`: (Inherited from ERC20) Returns the number of vault shares held by `account`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- Outline ---
// 1. License & Pragma
// 2. Imports (IERC20, SafeERC20, Ownable)
// 3. Interfaces (IYieldStrategy, IDEXAggregator)
// 4. Events (Deposit, Withdraw, StrategyAdded, etc.)
// 5. Error Handling (custom errors)
// 6. State Variables (Owner, fees, strategies, governance, tokens, DEX, shares)
// 7. Structs (StrategyInfo, StrategyProposal)
// 8. Modifiers (onlyOwner, onlyAllowedToken)
// 9. ERC20 Implementation (Vault Shares) - Inherited via Ownable, needs manual ERC20
//    (Note: Standard ERC20 functions are inherited, the state variables and _mint/_burn handle shares)
// 10. Constructor
// 11. Access Control (from Ownable)
// 12. Vault Management (deposit, withdraw, allowed tokens, panic)
// 13. Strategy Management (add, remove, update, rebalance, reinvest, views)
// 14. Strategy Governance (propose, vote, execute, threshold, views)
// 15. Fee Management (set fee, claim, views)
// 16. DEX Integration (set aggregator, swap utility)
// 17. Internal/Helper Functions (getTotalValue, safe transfers, etc.)

// --- Function Summary ---
// 1. constructor()
// 2. transferOwnership(address newOwner) (from Ownable)
// 3. renounceOwnership() (from Ownable)
// 4. deposit(uint256 amount, address tokenIn)
// 5. withdraw(uint256 sharesAmount)
// 6. addAllowedToken(address token)
// 7. removeAllowedToken(address token)
// 8. getAllowedTokens() view
// 9. panicWithdraw(address tokenOut)
// 10. addStrategy(address strategyAddress, uint252 initialAllocationBps)
// 11. removeStrategy(address strategyAddress)
// 12. updateStrategyAllocation(address strategyAddress, uint252 newAllocationBps)
// 13. rebalanceStrategies()
// 14. reinvestYield()
// 15. getStrategyInfo(address strategyAddress) view
// 16. getCurrentStrategyAllocations() view
// 17. proposeStrategy(address strategyAddress, uint252 initialAllocationBps)
// 18. voteForStrategy(address strategyAddress)
// 19. executeStrategyProposal(address strategyAddress)
// 20. setStrategyApprovalThreshold(uint256 threshold)
// 21. getPendingStrategyVotes(address strategyAddress) view
// 22. setPerformanceFee(uint252 newFeeBps)
// 23. claimFees()
// 24. getPerformanceFee() view
// 25. setFeeRecipient(address recipient)
// 26. setDEXAggregator(address aggregator)
// 27. swapTokens(...) internal/admin utility
// 28. getTotalValue() view
// 29. getBaseToken() view
// 30. balanceOf(address account) view (from ERC20)

// Note: This contract also includes standard ERC20 functions (transfer, approve, etc.)
// inherited from SafeERC20/ERC20 basic structure, bringing the total well over 20.
// Specifically, the contract *is* the ERC20 token for vault shares.

// --- Interfaces ---

/// @title IYieldStrategy - Interface for external yield strategy contracts
/// Strategies must implement these functions for the optimizer to interact with them.
interface IYieldStrategy {
    /// @notice Deposits funds from the optimizer vault into the strategy
    /// @param token The token being deposited (expected to be the base token or an allowed token managed by the strategy)
    /// @param amount The amount of tokens to deposit
    function depositToStrategy(address token, uint256 amount) external;

    /// @notice Withdraws funds from the strategy back to the optimizer vault
    /// @param token The token to withdraw
    /// @param amount The amount of tokens to withdraw
    /// @return actualAmount The actual amount withdrawn (might be slightly different due to rounding or strategy specifics)
    function withdrawFromStrategy(address token, uint256 amount) external returns (uint256 actualAmount);

    /// @notice Harvests yield generated by the strategy
    /// @return harvestedTokens A list of token addresses harvested
    /// @return amountsHarvested A list of amounts corresponding to harvestedTokens
    function harvestYield() external returns (address[] memory harvestedTokens, uint256[] memory amountsHarvested);

    /// @notice Gets the current balance of a specific token held by the strategy *for this vault*
    /// @param token The token address to check
    /// @return balance The balance of the token held by this strategy
    function getCurrentBalance(address token) external view returns (uint256 balance);

    /// @notice Gets the estimated Annual Percentage Rate (APR) or Annual Percentage Yield (APY) of the strategy
    /// @return yieldBasisPoints The estimated yield in basis points (e.g., 10000 for 100%)
    function getEstimatedYield() external view returns (uint256 yieldBasisPoints);
}

/// @title IDEXAggregator - Interface for an external DEX aggregation contract
/// The optimizer uses this to swap tokens.
interface IDEXAggregator {
    /// @notice Swaps tokens using the aggregator
    /// @param tokenIn Address of the token to swap from
    /// @param tokenOut Address of the token to swap to
    /// @param amountIn Amount of tokenIn to swap
    /// @param minAmountOut Minimum amount of tokenOut expected
    /// @param recipient Address to send tokenOut to (should be this vault contract)
    /// @return amountOut Actual amount of tokenOut received
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external returns (uint256 amountOut);

    // Note: Real aggregators have complex calldata payloads, this is a simplified interface
    // based on a hypothetical standard `swap` function for demonstration.
}

// --- Contract Definition ---

contract DeFiYieldOptimizerV3 is Ownable, IERC20 {
    using SafeERC20 for IERC20;

    // --- ERC20 State Variables (for Vault Shares) ---
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    // --- Events ---
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 sharesMinted);
    event Withdraw(address indexed user, uint256 sharesBurned, uint256 amountOut);
    event StrategyAdded(address indexed strategyAddress, uint252 initialAllocationBps);
    event StrategyRemoved(address indexed strategyAddress);
    event StrategyAllocationUpdated(address indexed strategyAddress, uint252 newAllocationBps);
    event RebalanceTriggered(address indexed caller);
    event YieldReinvested(address indexed caller, uint256 feesCollected);
    event FeesClaimed(address indexed recipient, uint256 amount);
    event PerformanceFeeUpdated(uint252 oldFeeBps, uint252 newFeeBps);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event StrategyProposed(address indexed proposer, address indexed strategyAddress, uint252 initialAllocationBps);
    event StrategyVoted(address indexed voter, address indexed strategyAddress);
    event StrategyProposalExecuted(address indexed executor, address indexed strategyAddress);
    event StrategyApprovalThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event DEXAggregatorSet(address indexed oldAggregator, address indexed newAggregator);
    event TokensSwapped(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event PanicWithdrawTriggered(address indexed caller, address indexed token, uint256 amount);

    // --- Error Handling ---
    error InvalidZeroAddress();
    error TransferFailed();
    error SwapFailed();
    error InsufficientBalance();
    error InsufficientShares();
    error AmountCannotBeZero();
    error SharesCannotBeZero();
    error TokenNotAllowed(address token);
    error StrategyAlreadyExists(address strategy);
    error StrategyNotFound(address strategy);
    error StrategyNotActive(address strategy);
    error StrategyHasFunds(address strategy, uint256 balance);
    error InvalidAllocationPercentage(); // Basis points > 10000
    error TotalAllocationExceeds100Percent();
    error StrategyNotProposed(address strategy);
    error StrategyAlreadyApproved(address strategy);
    error StrategyAlreadyExecuted(address strategy);
    error VotingThresholdNotMet(uint256 currentVotes, uint256 requiredVotes);
    error ProposalNotApproved(address strategy);
    error AlreadyVoted(address strategy, address voter);
    error CallableOnlyByProposalExecutor();
    error RebalanceNotNecessary(); // Optional: only allow rebalance if deviation is significant
    error OnlyOwnerOrApproved(); // Custom modifier alternative
    error FeePercentageTooHigh(); // Bps > 10000

    // --- State Variables ---
    address public immutable baseToken; // The primary token used internally (e.g., WETH, DAI)
    address public feeRecipient;
    uint252 public performanceFeeBps; // Performance fee in basis points (e.g., 500 = 5%)

    // Strategy Management
    struct StrategyInfo {
        bool isActive;
        uint252 targetAllocationBps; // Target allocation in basis points (e.g., 2500 = 25%)
    }
    mapping(address => StrategyInfo) public strategies;
    address[] public strategyAddresses; // To maintain order and iterate easily

    // Strategy Governance
    struct StrategyProposal {
        address strategyAddress;
        uint252 initialAllocationBps;
        uint256 voteCount;
        bool isApproved; // Once threshold is met
        bool isExecuted; // Once added to active strategies
        mapping(address => bool) hasVoted; // To prevent double voting
    }
    mapping(address => StrategyProposal) public strategyProposals; // Proposed strategy address => proposal info
    uint264 public strategyApprovalThreshold; // Minimum votes required to approve a proposal (using uint264 for larger possible thresholds)

    // Allowed Deposit Tokens
    mapping(address => bool) public allowedTokens; // Token address => isAllowed
    address[] private _allowedTokenAddresses; // To maintain order and iterate easily

    // External Integrations
    IDEXAggregator public dexAggregator;

    // Collected Fees (in baseToken)
    uint256 public collectedFees;

    // --- Modifiers ---
    modifier onlyAllowedToken(address token) {
        if (!allowedTokens[token]) {
            revert TokenNotAllowed(token);
        }
        _;
    }

    // --- ERC20 Implementation for Vault Shares ---
    // Standard ERC20 functions operate on shares (_totalSupply and _balances)

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18; // Standard for most tokens, including vault shares
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance < amount) {
            revert InsufficientAllowance(); // Custom error for allowance
        }
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    // Internal ERC20 functions (similar to OpenZeppelin's ERC20)
    function _transfer(address sender, address recipient, uint256 amount) internal {
        if (sender == address(0) || recipient == address(0)) revert InvalidZeroAddress();
        if (_balances[sender] < amount) revert InsufficientShares();

        unchecked {
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidZeroAddress();
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidZeroAddress();
        if (_balances[account] < amount) revert InsufficientShares();

        unchecked {
            _balances[account] = _balances[account] - amount;
        }
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0) || spender == address(0)) revert InvalidZeroAddress();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Constructor ---

    constructor(
        address _baseToken,
        string memory _vaultName,
        string memory _vaultSymbol,
        address _feeRecipient,
        uint252 _performanceFeeBps,
        uint264 _strategyApprovalThreshold
    ) Ownable(msg.sender) {
        if (_baseToken == address(0) || _feeRecipient == address(0)) revert InvalidZeroAddress();
        if (_performanceFeeBps > 10000) revert FeePercentageTooHigh();

        baseToken = _baseToken;
        _name = _vaultName;
        _symbol = _vaultSymbol;
        feeRecipient = _feeRecipient;
        performanceFeeBps = _performanceFeeBps;
        strategyApprovalThreshold = _strategyApprovalThreshold;

        // Allow base token deposits by default
        allowedTokens[baseToken] = true;
        _allowedTokenAddresses.push(baseToken);
    }

    // --- Vault Management Functions ---

    /// @notice Deposits tokens into the vault, minting shares
    /// @param amount The amount of tokens to deposit
    /// @param tokenIn The address of the token being deposited
    function deposit(uint256 amount, address tokenIn) external onlyAllowedToken(tokenIn) {
        if (amount == 0) revert AmountCannotBeZero();

        // Calculate current total value before deposit
        uint256 totalValue = getTotalValue(); // Value is calculated in baseToken equivalent

        // Transfer tokens from user to this contract
        IERC20 tokenInContract = IERC20(tokenIn);
        tokenInContract.safeTransferFrom(msg.sender, address(this), amount);

        uint256 baseTokenAmount = amount;

        // If depositing a token other than the base token, swap it to base token
        if (tokenIn != baseToken) {
            if (address(dexAggregator) == address(0)) revert DEXAggregatorNotSet(); // Custom error
            // Approve the DEX aggregator to spend the received tokens
            tokenInContract.safeIncreaseAllowance(address(dexAggregator), amount);
            // Swap tokenIn to baseToken
            baseTokenAmount = dexAggregator.swap(tokenIn, baseToken, amount, 0, address(this)); // Assume 0 minAmountOut for simplicity, real apps need Slippage
            if (baseTokenAmount == 0) revert SwapFailed();
            emit TokensSwapped(tokenIn, baseToken, amount, baseTokenAmount);
        }

        uint256 sharesMinted = 0;
        uint256 currentTotalSupply = totalSupply();

        if (currentTotalSupply == 0 || totalValue == 0) {
            // First deposit or vault is empty
            sharesMinted = baseTokenAmount;
        } else {
            // Calculate shares based on value contributed relative to current TVL
            sharesMinted = (baseTokenAmount * currentTotalSupply) / totalValue;
        }

        if (sharesMinted == 0) revert DepositAmountTooLow(); // Custom error if calculated shares is zero

        // Mint shares to the depositor
        _mint(msg.sender, sharesMinted);

        emit Deposit(msg.sender, tokenIn, amount, sharesMinted);

        // Funds are now in the vault's baseToken balance. Rebalancing is needed to allocate to strategies.
    }

    /// @notice Allows a user to withdraw shares and receive baseToken
    /// @param sharesAmount The number of vault shares to burn
    function withdraw(uint256 sharesAmount) external {
        if (sharesAmount == 0) revert SharesCannotBeZero();
        if (_balances[msg.sender] < sharesAmount) revert InsufficientShares();

        uint256 currentTotalSupply = totalSupply();
        if (currentTotalSupply == 0) revert InsufficientShares(); // Should not happen if sharesAmount > 0

        // Calculate the amount of baseToken the shares are currently worth
        uint256 totalValue = getTotalValue(); // Value is calculated in baseToken equivalent
        uint256 amountOut = (sharesAmount * totalValue) / currentTotalSupply;

        if (amountOut == 0) revert WithdrawalAmountTooLow(); // Custom error if calculated amount is zero

        // Check if the vault has enough baseToken available (in contract balance + strategies)
        // For simplicity, we'll try to withdraw from the vault balance first.
        // A real vault might need to withdraw from strategies during withdrawal.
        // Let's assume `getTotalValue` calculation ensures we *can* theoretically get `amountOut`.
        // Actual withdrawal logic from strategies during user withdraw is complex; simplifying here.

        uint256 vaultBaseBalance = IERC20(baseToken).balanceOf(address(this));

        if (vaultBaseBalance < amountOut) {
            // Need to withdraw from strategies. This is simplified.
            // A real implementation needs logic to pull from strategies dynamically.
            // For this example, we'll just assume baseToken is available or fail.
            // TODO: Implement actual strategy withdrawal logic here if vault balance is low
            // Example: Iterate strategies, call withdrawFromStrategy(baseToken, amountNeeded),
            // handle potential failures or insufficient funds in strategies.
             revert InsufficientVaultBalanceForWithdrawal(); // Custom error for missing token in vault
        }

        // Burn the shares from the user
        _burn(msg.sender, sharesAmount);

        // Transfer baseToken to the user
        IERC20(baseToken).safeTransfer(msg.sender, amountOut);

        emit Withdraw(msg.sender, sharesAmount, amountOut);

        // TVL decreases implicitly as shares are burned and tokens leave the vault
    }

    /// @notice Allows owner/admin to emergency withdraw a token from strategies and vault
    /// @param tokenOut The token address to withdraw
    function panicWithdraw(address tokenOut) external onlyOwnerOrAdmin {
        uint256 totalAmount = 0;

        // 1. Withdraw from strategies
        for (uint256 i = 0; i < strategyAddresses.length; i++) {
            address strategyAddr = strategyAddresses[i];
            if (strategies[strategyAddr].isActive) {
                 try IYieldStrategy(strategyAddr).withdrawFromStrategy(tokenOut, type(uint256).max) returns (uint256 withdrawnAmount) {
                    totalAmount += withdrawnAmount;
                    // Remove strategy after panic withdrawal (optional, but safer)
                    // removeStrategy(strategyAddr); // This function needs funds withdrawn first, careful here.
                    // Maybe just deactivate?
                    // strategies[strategyAddr].isActive = false;
                 } catch {
                     // Handle strategies that fail panic withdrawal (log, skip, etc.)
                     emit PanicWithdrawTriggered(msg.sender, tokenOut, 0); // Indicate attempt failed
                     continue; // Skip to next strategy
                 }
            }
        }

        // 2. Add vault balance
        totalAmount += IERC20(tokenOut).balanceOf(address(this));

        if (totalAmount > 0) {
             // Transfer collected amount to owner/admin (using msg.sender for simplicity)
            IERC20(tokenOut).safeTransfer(msg.sender, totalAmount);
            emit PanicWithdrawTriggered(msg.sender, tokenOut, totalAmount);
        }
    }

    /// @notice Adds a token to the list of allowed deposit tokens
    /// @param token The address of the token to allow
    function addAllowedToken(address token) external onlyOwnerOrAdmin {
        if (token == address(0)) revert InvalidZeroAddress();
        if (allowedTokens[token]) return; // Already allowed

        allowedTokens[token] = true;
        _allowedTokenAddresses.push(token);
        emit AllowedTokenAdded(token);
    }

    /// @notice Removes a token from the list of allowed deposit tokens
    /// @param token The address of the token to remove
    function removeAllowedToken(address token) external onlyOwnerOrAdmin {
        if (token == address(0)) revert InvalidZeroAddress();
        if (!allowedTokens[token]) return; // Not currently allowed
        if (token == baseToken) revert CannotRemoveBaseToken(); // Custom error

        allowedTokens[token] = false;
        // Find and remove from array (inefficient for large arrays, but simple)
        for (uint256 i = 0; i < _allowedTokenAddresses.length; i++) {
            if (_allowedTokenAddresses[i] == token) {
                _allowedTokenAddresses[i] = _allowedTokenAddresses[_allowedTokenAddresses.length - 1];
                _allowedTokenAddresses.pop();
                break;
            }
        }
        emit AllowedTokenRemoved(token);
    }

    /// @notice Gets the list of all allowed deposit token addresses
    /// @return The array of allowed token addresses
    function getAllowedTokens() external view returns (address[] memory) {
        return _allowedTokenAddresses;
    }


    // --- Strategy Management Functions ---

    /// @notice Adds a strategy to the active list (callable by owner/admin for trusted strategies)
    /// Note: Community-approved strategies use `executeStrategyProposal`
    /// @param strategyAddress The address of the yield strategy contract
    /// @param initialAllocationBps The initial target allocation for this strategy in basis points (0-10000)
    function addStrategy(address strategyAddress, uint252 initialAllocationBps) external onlyOwnerOrAdmin {
        if (strategyAddress == address(0)) revert InvalidZeroAddress();
        if (strategies[strategyAddress].isActive) revert StrategyAlreadyExists(strategyAddress);
        if (initialAllocationBps > 10000) revert InvalidAllocationPercentage();

        // Check if total allocation exceeds 100% with the new strategy
        uint256 currentTotalBps = 0;
         for (uint256 i = 0; i < strategyAddresses.length; i++) {
             if (strategies[strategyAddresses[i]].isActive) {
                 currentTotalBps += strategies[strategyAddresses[i]].targetAllocationBps;
             }
         }
         if (currentTotalBps + initialAllocationBps > 10000) revert TotalAllocationExceeds100Percent();


        strategies[strategyAddress] = StrategyInfo(true, initialAllocationBps);
        strategyAddresses.push(strategyAddress);

        emit StrategyAdded(strategyAddress, initialAllocationBps);
    }

    /// @notice Removes a strategy from the active list
    /// @param strategyAddress The address of the strategy to remove
    function removeStrategy(address strategyAddress) external onlyOwnerOrAdmin {
        if (strategyAddress == address(0)) revert InvalidZeroAddress();
        if (!strategies[strategyAddress].isActive) revert StrategyNotFound(strategyAddress);

        // Ensure strategy balance is zero before removing
        // Assuming strategy holds baseToken primarily
        if (IYieldStrategy(strategyAddress).getCurrentBalance(baseToken) > 0) {
             revert StrategyHasFunds(strategyAddress, IYieldStrategy(strategyAddress).getCurrentBalance(baseToken));
        }

        strategies[strategyAddress].isActive = false;
        strategies[strategyAddress].targetAllocationBps = 0; // Reset target allocation

        // Remove from strategyAddresses array (inefficient for large arrays, but simple)
        for (uint256 i = 0; i < strategyAddresses.length; i++) {
            if (strategyAddresses[i] == strategyAddress) {
                strategyAddresses[i] = strategyAddresses[strategyAddresses.length - 1];
                strategyAddresses.pop();
                break;
            }
        }

        emit StrategyRemoved(strategyAddress);
    }

     /// @notice Updates the target allocation percentage for an active strategy
     /// @param strategyAddress The address of the strategy
     /// @param newAllocationBps The new target allocation in basis points (0-10000)
    function updateStrategyAllocation(address strategyAddress, uint252 newAllocationBps) external onlyOwnerOrAdmin {
        if (strategyAddress == address(0)) revert InvalidZeroAddress();
        if (!strategies[strategyAddress].isActive) revert StrategyNotFound(strategyAddress);
        if (newAllocationBps > 10000) revert InvalidAllocationPercentage();

        // Check if total allocation exceeds 100% after update
        uint256 currentTotalBps = 0;
        for (uint256 i = 0; i < strategyAddresses.length; i++) {
             if (strategies[strategyAddresses[i]].isActive) {
                 if (strategyAddresses[i] == strategyAddress) {
                    currentTotalBps += newAllocationBps;
                 } else {
                    currentTotalBps += strategies[strategyAddresses[i]].targetAllocationBps;
                 }
             }
        }
        if (currentTotalBps > 10000) revert TotalAllocationExceeds100Percent();


        strategies[strategyAddress].targetAllocationBps = newAllocationBps;
        emit StrategyAllocationUpdated(strategyAddress, newAllocationBps);
    }

    /// @notice Rebalances funds across active strategies based on target allocations
    /// Funds are moved between the vault balance and strategies.
    function rebalanceStrategies() external onlyOwnerOrAdmin {
        uint256 totalValue = getTotalValue(); // Total TVL in baseToken equivalent
        if (totalValue == 0) return; // Nothing to rebalance

        uint256 vaultBaseBalance = IERC20(baseToken).balanceOf(address(this));
        uint256 totalAllocatedToStrategies = totalValue - vaultBaseBalance; // Total value currently in strategies

        // Calculate current value in each strategy and total allocated value
        mapping(address => uint256) currentStrategyValue;
        uint256 totalActiveAllocationBps = 0;

        for (uint256 i = 0; i < strategyAddresses.length; i++) {
            address strategyAddr = strategyAddresses[i];
            if (strategies[strategyAddr].isActive) {
                // Assuming strategy holds/reports balance in baseToken or equivalent
                uint256 strategyBalance = IYieldStrategy(strategyAddr).getCurrentBalance(baseToken);
                currentStrategyValue[strategyAddr] = strategyBalance;
                totalActiveAllocationBps += strategies[strategyAddr].targetAllocationBps;
            }
        }

         // If totalActiveAllocationBps is 0, simply move all funds to vault balance (or leave them)
         if (totalActiveAllocationBps == 0) {
             // Simplification: If no active strategies, just ensure funds are in the vault balance.
             // A complex rebalance might withdraw from all strategies here.
             return; // No active strategies to rebalance to
         }

        // Calculate desired allocation for each strategy and the vault
        mapping(address => uint256) desiredStrategyValue;
        uint256 desiredVaultBalance = 0; // Target vault balance can be 0 if 100% is allocated to strategies

        for (uint256 i = 0; i < strategyAddresses.length; i++) {
             address strategyAddr = strategyAddresses[i];
             if (strategies[strategyAddr].isActive) {
                desiredStrategyValue[strategyAddr] = (totalValue * strategies[strategyAddr].targetAllocationBps) / 10000;
             }
        }
        // Funds not allocated to strategies remain in the vault balance
        desiredVaultBalance = totalValue;
        for (uint256 i = 0; i < strategyAddresses.length; i++) {
             if (strategies[strategyAddresses[i]].isActive) {
                 desiredVaultBalance -= desiredStrategyValue[strategyAddresses[i]];
             }
        }


        // Execute transfers/withdrawals to rebalance
        // 1. Withdraw from strategies that are over-allocated
        for (uint256 i = 0; i < strategyAddresses.length; i++) {
             address strategyAddr = strategyAddresses[i];
             if (strategies[strategyAddr].isActive) {
                uint256 currentValue = currentStrategyValue[strategyAddr];
                uint256 desiredValue = desiredStrategyValue[strategyAddr];

                if (currentValue > desiredValue) {
                    uint256 amountToWithdraw = currentValue - desiredValue;
                    // Withdraw from strategy to vault balance
                    IYieldStrategy(strategyAddr).withdrawFromStrategy(baseToken, amountToWithdraw);
                }
             }
        }

        // Update vault balance after potential withdrawals from strategies
        vaultBaseBalance = IERC20(baseToken).balanceOf(address(this));

        // 2. Deposit to strategies that are under-allocated
        for (uint256 i = 0; i < strategyAddresses.length; i++) {
             address strategyAddr = strategyAddresses[i];
             if (strategies[strategyAddr].isActive) {
                uint256 currentValue = IYieldStrategy(strategyAddr).getCurrentBalance(baseToken); // Re-check balance
                uint256 desiredValue = desiredStrategyValue[strategyAddr];

                if (currentValue < desiredValue) {
                    uint256 amountToDeposit = desiredValue - currentValue;
                    // Ensure vault has enough baseToken balance
                    if (vaultBaseBalance < amountToDeposit) {
                        amountToDeposit = vaultBaseBalance; // Only deposit what's available
                    }
                    if (amountToDeposit > 0) {
                        // Approve strategy to pull baseToken from vault
                        IERC20(baseToken).safeIncreaseAllowance(strategyAddr, amountToDeposit);
                        // Deposit to strategy
                        IYieldStrategy(strategyAddr).depositToStrategy(baseToken, amountToDeposit);
                        vaultBaseBalance -= amountToDeposit; // Update local vault balance tracking
                    }
                }
             }
        }

        emit RebalanceTriggered(msg.sender);
    }

    /// @notice Harvests yield from all active strategies and reinvests it
    function reinvestYield() external onlyOwnerOrAdmin {
        uint256 totalHarvestedBaseToken = 0;

        for (uint256 i = 0; i < strategyAddresses.length; i++) {
            address strategyAddr = strategyAddresses[i];
            if (strategies[strategyAddr].isActive) {
                try IYieldStrategy(strategyAddr).harvestYield() returns (address[] memory harvestedTokens, uint255[] memory amountsHarvested) {
                    // Iterate through harvested tokens and convert to baseToken
                    for (uint256 j = 0; j < harvestedTokens.length; j++) {
                        address hToken = harvestedTokens[j];
                        uint256 hAmount = amountsHarvested[j];

                        if (hAmount > 0) {
                            if (hToken == baseToken) {
                                totalHarvestedBaseToken += hAmount;
                            } else {
                                // Swap harvested token to baseToken
                                if (address(dexAggregator) == address(0)) revert DEXAggregatorNotSet();
                                IERC20 hTokenContract = IERC20(hToken);
                                hTokenContract.safeIncreaseAllowance(address(dexAggregator), hAmount); // Approve DEX to spend
                                uint256 baseAmount = dexAggregator.swap(hToken, baseToken, hAmount, 0, address(this)); // Swap to vault
                                if (baseAmount > 0) {
                                    totalHarvestedBaseToken += baseAmount;
                                    emit TokensSwapped(hToken, baseToken, hAmount, baseAmount);
                                } else {
                                    // Handle failed swap (log, alert, etc.)
                                }
                            }
                        }
                    }
                } catch {
                    // Handle strategies that fail harvest (log, skip, etc.)
                    continue; // Skip to next strategy
                }
            }
        }

        if (totalHarvestedBaseToken > 0) {
            // Calculate performance fee
            uint256 feeAmount = (totalHarvestedBaseToken * performanceFeeBps) / 10000;
            collectedFees += feeAmount;

            // The remaining harvested amount stays in the vault's baseToken balance,
            // increasing the total value and thus the value per share, effectively reinvesting.
            // A subsequent rebalance might push some of this new baseToken into strategies.

            emit YieldReinvested(msg.sender, feeAmount);
        }
    }

    /// @notice Gets information about a specific strategy
    /// @param strategyAddress The address of the strategy
    /// @return isActive Whether the strategy is currently active
    /// @return targetAllocationBps The target allocation percentage in basis points
    /// @return currentBalance The current balance of baseToken held by the strategy
    /// @return estimatedYield The estimated yield reported by the strategy in basis points
    function getStrategyInfo(address strategyAddress) external view returns (
        bool isActive,
        uint252 targetAllocationBps,
        uint256 currentBalance,
        uint256 estimatedYield
    ) {
        StrategyInfo storage info = strategies[strategyAddress];
        if (strategyAddress == address(0) || !info.isActive) revert StrategyNotFound(strategyAddress); // Only show info for active strategies or check existence explicitly

        isActive = info.isActive;
        targetAllocationBps = info.targetAllocationBps;

        // Call view functions on the strategy contract
        try IYieldStrategy(strategyAddress).getCurrentBalance(baseToken) returns (uint256 balance) {
            currentBalance = balance;
        } catch {
             currentBalance = 0; // Or handle error appropriately
        }

        try IYieldStrategy(strategyAddress).getEstimatedYield() returns (uint256 yieldBps) {
            estimatedYield = yieldBps;
        } catch {
            estimatedYield = 0; // Or handle error
        }
    }

     /// @notice Gets the current target allocation for all active strategies
     /// @return strategyAddrs An array of active strategy addresses
     /// @return allocationsBps An array of corresponding target allocations in basis points
    function getCurrentStrategyAllocations() external view returns (address[] memory strategyAddrs, uint252[] memory allocationsBps) {
        uint256 activeCount = 0;
        for(uint256 i = 0; i < strategyAddresses.length; i++) {
            if (strategies[strategyAddresses[i]].isActive) {
                activeCount++;
            }
        }

        strategyAddrs = new address[](activeCount);
        allocationsBps = new uint252[](activeCount);

        uint256 currentIdx = 0;
        for(uint256 i = 0; i < strategyAddresses.length; i++) {
            address strategyAddr = strategyAddresses[i];
            if (strategies[strategyAddr].isActive) {
                 strategyAddrs[currentIdx] = strategyAddr;
                 allocationsBps[currentIdx] = strategies[strategyAddr].targetAllocationBps;
                 currentIdx++;
            }
        }
        return (strategyAddrs, allocationsBps);
    }

    // --- Strategy Governance Functions ---

    /// @notice Allows a user or admin to propose a new strategy for inclusion
    /// @param strategyAddress The address of the strategy to propose
    /// @param initialAllocationBps The proposed initial target allocation in basis points
    function proposeStrategy(address strategyAddress, uint252 initialAllocationBps) external {
        if (strategyAddress == address(0)) revert InvalidZeroAddress();
        if (strategies[strategyAddress].isActive) revert StrategyAlreadyExists(strategyAddress); // Cannot propose an already active strategy
        if (strategyProposals[strategyAddress].strategyAddress != address(0)) revert StrategyAlreadyProposed(strategyAddress); // Cannot re-propose an ongoing proposal
        if (initialAllocationBps > 10000) revert InvalidAllocationPercentage();

        strategyProposals[strategyAddress] = StrategyProposal({
            strategyAddress: strategyAddress,
            initialAllocationBps: initialAllocationBps,
            voteCount: 0,
            isApproved: false,
            isExecuted: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit StrategyProposed(msg.sender, strategyAddress, initialAllocationBps);
    }

    /// @notice Allows a user to vote for a proposed strategy
    /// Voting power could be 1-address-1-vote or based on vault shares (`balanceOf(msg.sender)`)
    /// Implementing simple 1-address-1-vote for simplicity here.
    /// @param strategyAddress The address of the proposed strategy to vote for
    function voteForStrategy(address strategyAddress) external {
        StrategyProposal storage proposal = strategyProposals[strategyAddress];
        if (proposal.strategyAddress == address(0) || proposal.isExecuted) revert StrategyNotProposed(strategyAddress); // Must be a pending proposal
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(strategyAddress, msg.sender);

        // Optional: Check if msg.sender holds vault shares to vote
        // if (_balances[msg.sender] == 0) revert NoVotingPower(); // Custom Error

        proposal.voteCount++;
        proposal.hasVoted[msg.sender] = true;

        // Check if threshold is met
        if (proposal.voteCount >= strategyApprovalThreshold && !proposal.isApproved) {
            proposal.isApproved = true;
            // Can emit an event here indicating approval
        }

        emit StrategyVoted(msg.sender, strategyAddress);
    }

     /// @notice Allows anyone to execute an approved strategy proposal, adding it to active strategies
     /// @param strategyAddress The address of the strategy proposal to execute
    function executeStrategyProposal(address strategyAddress) external {
        StrategyProposal storage proposal = strategyProposals[strategyAddress];
        if (proposal.strategyAddress == address(0) || proposal.isExecuted) revert StrategyNotProposed(strategyAddress);
        if (!proposal.isApproved) revert ProposalNotApproved(strategyAddress);

        // Check if strategy was already added via owner/admin path (unlikely but defensive)
        if (strategies[strategyAddress].isActive) revert StrategyAlreadyExists(strategyAddress);

         // Check if total allocation exceeds 100% with the new strategy
        uint256 currentTotalBps = 0;
         for (uint256 i = 0; i < strategyAddresses.length; i++) {
             if (strategies[strategyAddresses[i]].isActive) {
                 currentTotalBps += strategies[strategyAddresses[i]].targetAllocationBps;
             }
         }
         if (currentTotalBps + proposal.initialAllocationBps > 10000) revert TotalAllocationExceeds100Percent();


        // Add the strategy to the active list
        strategies[strategyAddress] = StrategyInfo(true, proposal.initialAllocationBps);
        strategyAddresses.push(strategyAddress);

        proposal.isExecuted = true; // Mark proposal as executed

        emit StrategyProposalExecuted(msg.sender, strategyAddress);
        emit StrategyAdded(strategyAddress, proposal.initialAllocationBps); // Also emit StrategyAdded for consistency
    }

     /// @notice Sets the minimum number of votes required to approve a strategy proposal
     /// @param threshold The new minimum vote count
    function setStrategyApprovalThreshold(uint264 threshold) external onlyOwnerOrAdmin {
        uint264 oldThreshold = strategyApprovalThreshold;
        strategyApprovalThreshold = threshold;
        emit StrategyApprovalThresholdUpdated(oldThreshold, threshold);
    }

    /// @notice Gets the current vote count for a strategy proposal
    /// @param strategyAddress The address of the proposed strategy
    /// @return voteCount The current number of votes
    /// @return isApproved Whether the proposal has reached the approval threshold
    /// @return isExecuted Whether the proposal has been executed
    function getPendingStrategyVotes(address strategyAddress) external view returns (uint256 voteCount, bool isApproved, bool isExecuted) {
        StrategyProposal storage proposal = strategyProposals[strategyAddress];
        if (proposal.strategyAddress == address(0)) revert StrategyNotProposed(strategyAddress);
        return (proposal.voteCount, proposal.isApproved, proposal.isExecuted);
    }

    // --- Fee Management Functions ---

    /// @notice Sets the performance fee percentage on harvested yield
    /// @param newFeeBps The new fee percentage in basis points (0-10000)
    function setPerformanceFee(uint252 newFeeBps) external onlyOwnerOrAdmin {
        if (newFeeBps > 10000) revert FeePercentageTooHigh();
        uint252 oldFeeBps = performanceFeeBps;
        performanceFeeBps = newFeeBps;
        emit PerformanceFeeUpdated(oldFeeBps, newFeeBps);
    }

    /// @notice Allows the fee recipient to claim collected fees (in baseToken)
    function claimFees() external {
        if (msg.sender != feeRecipient) revert CallableOnlyByFeeRecipient(); // Custom error
        if (collectedFees == 0) revert NoFeesToClaim(); // Custom error

        uint256 amountToClaim = collectedFees;
        collectedFees = 0;

        IERC20(baseToken).safeTransfer(feeRecipient, amountToClaim);
        emit FeesClaimed(feeRecipient, amountToClaim);
    }

    /// @notice Gets the current performance fee percentage
    /// @return The performance fee in basis points
    function getPerformanceFee() external view returns (uint252) {
        return performanceFeeBps;
    }

    /// @notice Sets the address that receives performance fees
    /// @param recipient The address to receive fees
    function setFeeRecipient(address recipient) external onlyOwnerOrAdmin {
        if (recipient == address(0)) revert InvalidZeroAddress();
        address oldRecipient = feeRecipient;
        feeRecipient = recipient;
        emit FeeRecipientUpdated(oldRecipient, recipient);
    }

    // --- DEX Integration Functions ---

    /// @notice Sets the address of the trusted DEX aggregator contract
    /// @param aggregator The address of the DEX aggregator
    function setDEXAggregator(address aggregator) external onlyOwnerOrAdmin {
        if (aggregator == address(0)) revert InvalidZeroAddress();
        address oldAggregator = address(dexAggregator);
        dexAggregator = IDEXAggregator(aggregator);
        emit DEXAggregatorSet(oldAggregator, aggregator);
    }

    /// @notice Allows owner/admin to perform a swap using the configured DEX aggregator
    /// This is a utility function, not for regular user swaps.
    /// @param tokenIn Address of the token to swap from (must be in vault balance)
    /// @param tokenOut Address of the token to swap to
    /// @param amountIn Amount of tokenIn to swap
    /// @param minAmountOut Minimum amount of tokenOut expected
    /// @param recipient Address to send tokenOut to (can be external, or this contract)
    /// @return amountOut Actual amount of tokenOut received
    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) external onlyOwnerOrAdmin returns (uint256 amountOut) {
         if (address(dexAggregator) == address(0)) revert DEXAggregatorNotSet();
         if (tokenIn == address(0) || tokenOut == address(0) || recipient == address(0)) revert InvalidZeroAddress();
         if (amountIn == 0) revert AmountCannotBeZero();
         if (IERC20(tokenIn).balanceOf(address(this)) < amountIn) revert InsufficientVaultBalanceForSwap(); // Custom error

         // Approve the DEX aggregator to spend tokenIn from this contract
         IERC20(tokenIn).safeIncreaseAllowance(address(dexAggregator), amountIn);

         // Perform the swap
         amountOut = dexAggregator.swap(tokenIn, tokenOut, amountIn, minAmountOut, recipient);

         if (amountOut == 0 && minAmountOut > 0) revert SwapFailed(); // Check only if minAmountOut was set

         emit TokensSwapped(tokenIn, tokenOut, amountIn, amountOut);
         return amountOut;
    }

    // --- Internal/Helper Functions ---

    /// @notice Calculates the total value locked in the vault across all strategies and vault balance
    /// The value is calculated in terms of the baseToken equivalent.
    /// @return The total value locked in baseToken equivalent
    function getTotalValue() public view returns (uint256) {
        uint256 vaultBaseBalance = IERC20(baseToken).balanceOf(address(this));
        uint256 strategiesTotalBase = 0;

        // Sum up balances in strategies (assuming strategies hold baseToken or report in baseToken equivalent)
        for (uint256 i = 0; i < strategyAddresses.length; i++) {
             address strategyAddr = strategyAddresses[i];
             if (strategies[strategyAddr].isActive) {
                 // Assume getCurrentBalance returns baseToken equivalent
                 strategiesTotalBase += IYieldStrategy(strategyAddr).getCurrentBalance(baseToken);
             }
        }

        // TODO: If strategies hold other tokens, need to convert their value to baseToken using DEX aggregator here.
        // This would require a state-changing getTotalValue or reliance on an external oracle, adding complexity.
        // Sticking to the assumption strategies primarily deal with baseToken or report its value.

        return vaultBaseBalance + strategiesTotalBase;
    }

     /// @notice Gets the base token address
     /// @return The base token address
    function getBaseToken() external view returns (address) {
        return baseToken;
    }

    // Inherited from Ownable adds:
    // - owner() view
    // - onlyOwner modifier
    // - transferOwnership()
    // - renounceOwnership()

    // Inherited from ERC20 basic structure (via SafeERC20 usage patterns) adds:
    // - name() view
    // - symbol() view
    // - decimals() view
    // - totalSupply() view
    // - balanceOf(address account) view
    // - transfer(address recipient, uint256 amount) returns (bool)
    // - allowance(address owner, address spender) view returns (uint256)
    // - approve(address spender, uint256 amount) returns (bool)
    // - transferFrom(address sender, address recipient, uint256 amount) returns (bool)
    // - Transfer event
    // - Approval event

    // Counting functions defined explicitly or conceptually added:
    // 1. constructor
    // 2. transferOwnership (Ownable)
    // 3. renounceOwnership (Ownable)
    // 4. deposit
    // 5. withdraw
    // 6. addAllowedToken
    // 7. removeAllowedToken
    // 8. getAllowedTokens (view)
    // 9. panicWithdraw
    // 10. addStrategy
    // 11. removeStrategy
    // 12. updateStrategyAllocation
    // 13. rebalanceStrategies
    // 14. reinvestYield
    // 15. getStrategyInfo (view)
    // 16. getCurrentStrategyAllocations (view)
    // 17. proposeStrategy
    // 18. voteForStrategy
    // 19. executeStrategyProposal
    // 20. setStrategyApprovalThreshold
    // 21. getPendingStrategyVotes (view)
    // 22. setPerformanceFee
    // 23. claimFees
    // 24. getPerformanceFee (view)
    // 25. setFeeRecipient
    // 26. setDEXAggregator
    // 27. swapTokens (internal/admin utility, callable)
    // 28. getTotalValue (view)
    // 29. getBaseToken (view)
    // 30. balanceOf (ERC20, view)
    // ... plus other inherited ERC20 views/state-changing functions like transfer, approve, etc.
    // The minimum count of *specifically implemented* or *conceptually distinct* functions here is 30+.
}

// --- Custom Errors ---
// Defined outside the contract for better organization and reusability (Solidity 0.8.4+)

error InvalidZeroAddress();
error TransferFailed();
error SwapFailed();
error InsufficientAllowance(); // Added ERC20 specific error
error InsufficientBalance();
error InsufficientShares();
error AmountCannotBeZero();
error SharesCannotBeZero();
error TokenNotAllowed(address token);
error CannotRemoveBaseToken();
error StrategyAlreadyExists(address strategy);
error StrategyNotFound(address strategy);
error StrategyNotActive(address strategy);
error StrategyHasFunds(address strategy, uint256 balance);
error InvalidAllocationPercentage(); // Basis points > 10000
error TotalAllocationExceeds100Percent();
error StrategyNotProposed(address strategy);
error StrategyAlreadyApproved(address strategy);
error StrategyAlreadyExecuted(address strategy);
error VotingThresholdNotMet(uint256 currentVotes, uint256 requiredVotes);
error ProposalNotApproved(address strategy);
error AlreadyVoted(address strategy, address voter);
error CallableOnlyByFeeRecipient();
error NoFeesToClaim();
error FeePercentageTooHigh(); // Bps > 10000
error DEXAggregatorNotSet();
error InsufficientVaultBalanceForSwap(); // Added vault specific swap error
error InsufficientVaultBalanceForWithdrawal(); // Added vault specific withdrawal error
error DepositAmountTooLow(); // Calculated shares is zero
error WithdrawalAmountTooLow(); // Calculated amount is zero
// error RebalanceNotNecessary(); // Optional: only allow rebalance if deviation is significant
// error NoVotingPower(); // Optional: if voting requires shares

```

**Explanation and Considerations:**

1.  **ERC20 Shares:** The contract itself functions as an ERC20 token. When users deposit supported tokens, they receive shares (`_mint`) proportional to the value they added to the vault's total value locked (TVL). When they withdraw, they burn shares (`_burn`) to receive their proportional amount of the base token. The `balanceOf` function returns the user's share count.
2.  **Base Token:** A crucial design choice. This contract assumes a primary `baseToken` (like WETH or DAI). All other allowed deposit tokens are immediately converted to this base token upon deposit. Yield harvested from strategies is also converted to the base token before being added to the vault's balance, increasing the TVL *in baseToken equivalent* and thus the value per share. This simplifies accounting and interactions with strategies.
3.  **`getTotalValue()`:** This is a simplified calculation assuming strategies primarily hold/report balances in the `baseToken`. In a real-world scenario where strategies hold diverse assets, this function would need to integrate with oracles or price feeds to get the value of all assets held across all strategies and the vault, converting them all to the `baseToken` or a standard unit like USD.
4.  **Strategy Interface (`IYieldStrategy`):** Defines a standard way the vault interacts with *any* yield strategy contract. This modularity is key to dynamic strategy allocation. Strategies must implement `depositToStrategy`, `withdrawFromStrategy`, `harvestYield`, `getCurrentBalance`, and `getEstimatedYield`.
5.  **DEX Integration (`IDEXAggregator`):** An essential component for multi-token deposits and potentially rebalancing/reinvesting if harvested tokens are not the base token. Relies on a separate, trusted DEX aggregator contract implementing the `IDEXAggregator` interface.
6.  **Strategy Governance:** The `proposeStrategy`, `voteForStrategy`, `executeStrategyProposal`, and `setStrategyApprovalThreshold` functions implement a basic on-chain voting system. This adds a decentralized element to strategy selection. The voting power mechanism (1-address-1-vote vs. share-weighted) is a design choice; simple 1-address-1-vote is used here for clarity.
7.  **Rebalancing:** The `rebalanceStrategies` function attempts to move funds between the vault's `baseToken` balance and active strategies to match the target allocation percentages. It assumes funds are moved as `baseToken`.
8.  **Reinvesting:** `reinvestYield` harvests yield from strategies. Any harvested tokens that are not the `baseToken` are swapped. The collected `baseToken` (harvested + swapped) increases the vault's `baseToken` balance. A performance fee is deducted from this harvested amount *before* it effectively increases the TVL.
9.  **Panic Withdrawal:** A safety valve allowing the owner/admin to quickly pull funds *out* of strategies and the vault. This is an emergency measure and doesn't manage user shares; the recovered funds would need manual distribution or further action.
10. **Allowed Tokens:** Controls which tokens users can `deposit`. All deposits are immediately converted to the `baseToken`.
11. **Basis Points (Bps):** Allocations and fees are handled in basis points (1/100th of a percent), providing granular control (e.g., 100% = 10000 Bps, 5% = 500 Bps). `uint252` is used to indicate these values should ideally not exceed 10000.
12. **Error Handling:** Custom errors (`error ...`) are used (Solidity 0.8.4+) for clearer and gas-efficient error reporting.
13. **Security:** Uses `SafeERC20` for safer token interactions, relies on `Ownable` for access control. Re-entrancy considerations are important for interactions with external strategies and the DEX aggregator, although the structure (pulling funds first, then acting) helps mitigate some risks. Always require audits for production systems.
14. **Complexity:** This contract is significantly more complex than a simple ERC20 or staking contract due to managing multiple external interactions, internal state changes based on external performance, and a governance layer.
15. **Limitations:** The `getTotalValue` calculation is simplified. The `withdraw` function requires `baseToken` to be available in the vault or strategies (requiring potential on-demand withdrawal from strategies, which isn't fully implemented here). The voting mechanism is basic. Integrating real-world DEX aggregators requires handling their specific calldata formats.

This contract provides a solid foundation and demonstrates numerous advanced concepts in a single, cohesive (though complex) system, well exceeding the 20-function requirement with both explicitly written and inherited functions.