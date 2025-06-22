Okay, here is a Solidity smart contract concept combining elements of a Decentralized Autonomous Market Maker (DAMM) and a Strategy Vault. It allows users to deposit multiple assets, the contract can function as an internal AMM for pairs of these assets, and a portion of the assets can be allocated to external, approved yield-generating strategies.

This design is advanced as it involves:
1.  **Multi-Asset Vault:** Managing user shares representing ownership of a basket of assets, not just one underlying asset (unlike standard ERC-4626).
2.  **Internal AMM:** Implementing liquidity provision and swapping logic directly within the vault contract.
3.  **External Strategy Allocation:** Interacting with external contracts for yield generation, requiring state tracking and access control.
4.  **Dynamic Asset Valuation:** Needing an oracle to determine the value of the diverse assets for accurate share pricing.
5.  **Role-Based Access Control:** Differentiating between owner, strategists, and users.

**Outline:**

1.  **License & Pragma**
2.  **Interfaces:**
    *   `IERC20`: Standard ERC-20 token interface.
    *   `IPriceOracle`: Interface for a price oracle (e.g., Chainlink simplified).
    *   `IStrategy`: Interface for approved external strategy contracts.
3.  **Errors:** Custom errors for better revert reasons.
4.  **State Variables:**
    *   Vault shares (total supply, user balances).
    *   Approved tokens list and balances.
    *   Internal AMM reserves and LP token tracking.
    *   Approved strategies list.
    *   Strategy target allocations (percentages).
    *   Price Oracle address.
    *   Access control roles (Owner, Strategists).
    *   Protocol fee/treasury.
    *   Vault metadata (name, symbol).
5.  **Events:** Logging key actions (deposit, withdrawal, swap, strategy allocation, role changes, etc.).
6.  **Modifiers:** Access control checks (`onlyOwner`, `onlyStrategist`, etc.).
7.  **Constructor:** Initializes vault details, owner, and approved tokens.
8.  **Access Control:** Functions to manage roles.
9.  **Approved Tokens Management:** Functions to add/remove tokens the vault supports.
10. **Vault Functions (ERC4626-inspired Logic):**
    *   Deposit assets for shares.
    *   Withdraw assets by redeeming shares.
    *   Convert between assets value and shares (view functions).
    *   Calculate total value of assets managed by the vault.
11. **Internal AMM Functions:**
    *   Add liquidity to an internal pool.
    *   Remove liquidity from an internal pool.
    *   Perform a swap between two approved tokens.
    *   View functions for reserves and swap outputs.
12. **Strategy Management & Execution:**
    *   Add/remove approved strategies.
    *   Set target allocation percentages for strategies.
    *   Allocate assets to strategies (move funds from vault to strategy).
    *   Redeem assets from strategies (move funds from strategy back to vault).
    *   Execute strategy-specific actions (e.g., harvest yield).
13. **View Functions:**
    *   Get lists of approved tokens, strategies, strategists.
    *   Get current strategy allocations.
    *   Get internal AMM reserves and LP supply.
    *   Get vault share price.
    *   Get asset prices via oracle.
    *   Get vault balances of specific tokens.
    *   Get protocol fee settings.

**Function Summary:**

1.  `constructor`: Initializes the vault with a name, symbol, initial tokens, and owner.
2.  `deposit`: Allows a user to deposit approved tokens into the vault for vault shares.
3.  `withdraw`: Allows a user to redeem vault shares for a proportional amount of the underlying approved tokens.
4.  `convertToShares`: Calculates how many vault shares correspond to a given value of assets (requires oracle).
5.  `convertToAssets`: Calculates the value of assets corresponding to a given number of vault shares (requires oracle).
6.  `totalAssets`: Returns the total calculated value of all assets held and managed by the vault (requires oracle).
7.  `addLiquidity`: Allows a strategist or automated process to add liquidity from vault assets into the internal AMM pool.
8.  `removeLiquidity`: Allows a strategist or automated process to remove liquidity from the internal AMM pool back into general vault assets.
9.  `swap`: Allows a strategist or automated process to perform a swap between two tokens using the internal AMM pool.
10. `getAmountOut`: View function to calculate the output amount for a swap on the internal AMM.
11. `getReserves`: View function to get the current reserves of a token in the internal AMM pool (if implemented as a single pool per token).
12. `addApprovedToken`: Owner function to add a new ERC20 token that the vault can hold and manage.
13. `removeApprovedToken`: Owner function to remove an approved ERC20 token (fails if vault holds balance).
14. `addStrategy`: Owner function to add an approved external strategy contract address.
15. `removeStrategy`: Owner function to remove an approved strategy contract address (fails if funds allocated).
16. `setStrategyTargetAllocation`: Strategist function to set the target percentage of *allocatable* assets for a specific strategy.
17. `allocateToStrategy`: Strategist function to move a specified amount of a token from the vault balance into a specific approved strategy.
18. `redeemFromStrategy`: Strategist function to request redemption of a specified amount (or shares/representation) from a strategy back into the vault balance.
19. `executeStrategyHarvest`: Strategist function to call a specific 'harvest' or 'claim' function on an approved strategy to collect yield back into the vault.
20. `addStrategist`: Owner function to grant the STRATEGIST role to an address.
21. `removeStrategist`: Owner function to revoke the STRATEGIST role from an address.
22. `transferOwnership`: Owner function to transfer ownership of the contract.
23. `setPriceOracle`: Owner function to set the address of the price oracle contract.
24. `getAssetPrice`: View function to get the price of an approved asset via the oracle.
25. `getTotalVaultValue`: View function alias for `totalAssets`.
26. `getStrategyAllocations`: View function to show target allocation percentages for all strategies.
27. `getApprovedTokens`: View function to list all approved token addresses.
28. `getApprovedStrategies`: View function to list all approved strategy addresses.
29. `getStrategists`: View function to list all addresses with the STRATEGIST role.
30. `getVaultSharePrice`: View function calculating the value of a single vault share relative to a base currency (e.g., USD) or a base asset using `totalAssets()` and `totalSupply()`.

*(Note: The actual implementation of internal AMM logic for multiple pairs and robust strategy allocation/rebalancing is complex. This example provides the function signatures and a basic structure. Calculating total vault value accurately across diverse assets, internal AMM positions, and external strategies requires careful design of the `totalAssets` function and reliable oracle integration.)*

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- INTERFACES ---

// Simplified Price Oracle Interface (e.g., Chainlink Aggregator facade)
interface IPriceOracle {
    // Returns the price of the asset in a base currency (e.g., USD) with a certain number of decimals.
    // Assumes assetAddress is the address of the token to get the price for.
    // Returns 0 if price is unavailable or stale.
    function getLatestPrice(address assetAddress) external view returns (uint256 price, uint8 decimals);
}

// Simplified Strategy Interface
interface IStrategy {
    // Function to invest assets received from the vault into the strategy
    // tokenAddress: The address of the token being invested
    // amount: The amount of the token to invest
    function invest(address tokenAddress, uint256 amount) external;

    // Function to redeem assets from the strategy back to the vault
    // tokenAddress: The address of the token to redeem
    // amountOrShares: The amount of underlying asset or strategy-specific representation to redeem
    // Returns the amount of underlying asset redeemed
    function redeem(address tokenAddress, uint256 amountOrShares) external returns (uint256 redeemedAmount);

    // Function to collect yield/rewards generated by the strategy back to the vault
    // Can be called by the vault to trigger reward claiming
    function harvest() external;

    // Function for the vault to query the total value managed by this strategy (in a base currency or token value)
    // This is crucial for the vault's totalAssets calculation.
    // Returns the value and its decimal precision. Returns 0 if calculation fails.
    function getValue() external view returns (uint256 value, uint8 decimals);
}

// --- ERRORS ---

error Unauthorized();
error InvalidAmount();
error TokenNotApproved();
error TokenIsApproved();
error StrategyNotApproved();
error StrategyIsApproved();
error StrategyHasAllocations();
error InsufficientVaultBalance();
error ZeroAddress();
error SwapPairNotApproved();
error InsufficientLiquidity();
error SlippageTooHigh();
error CalculationError();
error OracleUnavailable();

// --- CONTRACT ---

/**
 * @title Decentralized Autonomous Market Maker & Strategy Vault (DAMM-SV)
 * @author YourNameHere
 * @notice An advanced vault contract that allows depositing multiple assets,
 *         functions as an internal AMM, and allocates capital to external strategies.
 *         Users deposit assets to receive vault shares representing a claim on the
 *         total managed portfolio value.
 *
 * @dev This contract uses a simplified approach for multi-asset valuation and strategy
 *      interaction for illustrative purposes. A production system would require
 *      more robust oracle handling, precise value tracking across strategies,
 *      complex rebalancing logic, gas optimizations, and comprehensive testing.
 */
contract DammStrategyVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    // --- State Variables ---

    // ERC-20 Vault Shares
    string public name;
    string public symbol;
    uint256 private _vaultSharesTotalSupply;
    mapping(address => uint256) private _vaultShares; // user address => shares balance

    // Approved Assets Management
    mapping(address => bool) public isApprovedToken;
    address[] private _approvedTokensList; // To iterate over approved tokens

    // Internal AMM State
    // Reserves for tokens in the internal AMM pool.
    // Assumes a single pool where all approved tokens can potentially be swapped.
    // For a true AMM like Uniswap, this would need pairs (tokenA => tokenB => reserve).
    // This simplified version treats the contract's balance of an approved token as its reserve.
    // uint256 public swapFeeBasisPoints = 3; // 0.03% fee - Example

    // Internal AMM LP Tokens - Optional: if you want users/strategists to get LP tokens specifically
    // mapping(address => mapping(address => uint256)) private _internalLPTokens; // user => pair => LP balance
    // mapping(address => mapping(address => uint256)) private _internalLPTotalSupply; // pair => total supply

    // Strategy Management State
    mapping(address => bool) public isApprovedStrategy;
    address[] private _approvedStrategiesList; // To iterate over strategies
    mapping(address => uint256) private _strategyTargetAllocations; // strategy address => percentage (basis points, 10000 = 100%)
    // Note: Tracking *current* allocation in external strategies is complex.
    // getValue() on IStrategy is intended to help calculate this for totalAssets.

    // Access Control
    mapping(address => bool) public isStrategist;
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");

    // Oracle
    IPriceOracle public priceOracle;
    uint256 private constant PRICE_ORACLE_STALE_SECONDS = 3600; // 1 hour example staleness threshold

    // Protocol Fees - Example
    // address public feeRecipient;
    // uint256 public protocolFeeBasisPoints = 10; // 0.1% example on yield or swaps

    // --- Events ---

    event Deposit(address indexed caller, address indexed receiver, uint256 assetsReceived, uint256 sharesMinted);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 sharesBurned, uint256 assetsSent);
    event TokensApproved(address indexed tokenAddress);
    event TokensRemoved(address indexed tokenAddress);
    event LiquidityAdded(address indexed provider, address tokenA, uint256 amountA, address tokenB, uint256 amountB);
    event LiquidityRemoved(address indexed provider, address tokenA, uint256 amountA, address tokenB, uint256 amountB);
    event Swap(address indexed swapper, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event StrategyApproved(address indexed strategyAddress);
    event StrategyRemoved(address indexed strategyAddress);
    event StrategyTargetAllocationSet(address indexed strategyAddress, uint256 percentageBasisPoints);
    event AllocatedToStrategy(address indexed strategist, address indexed strategyAddress, address token, uint256 amount);
    event RedeemedFromStrategy(address indexed strategist, address indexed strategyAddress, address token, uint256 redeemedAmount);
    event StrategyHarvested(address indexed strategist, address indexed strategyAddress);
    event StrategistAdded(address indexed strategist);
    event StrategistRemoved(address indexed strategist);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PriceOracleSet(address indexed oracleAddress);
    // event ProtocolFeeSet(uint256 feeBasisPoints);
    // event FeeRecipientSet(address indexed recipient);


    // --- Modifiers ---

    modifier onlyStrategist() {
        if (!isStrategist[msg.sender] && msg.sender != owner()) revert Unauthorized();
        _;
    }

    modifier onlyApprovedToken(address tokenAddress) {
        if (!isApprovedToken[tokenAddress]) revert TokenNotApproved();
        _;
    }

    modifier onlyApprovedStrategy(address strategyAddress) {
        if (!isApprovedStrategy[strategyAddress]) revert StrategyNotApproved();
        _;
    }

    // --- Constructor ---

    /**
     * @notice Initializes the DAMM-SV contract.
     * @param _name The name of the vault shares token.
     * @param _symbol The symbol of the vault shares token.
     * @param initialApprovedTokens Addresses of the initial approved ERC20 tokens.
     * @param _priceOracleAddress Address of the price oracle contract.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory initialApprovedTokens,
        address _priceOracleAddress
        // address _feeRecipient // Optional: for protocol fees
    ) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
        // feeRecipient = _feeRecipient; // Optional

        if (_priceOracleAddress.isZero()) revert ZeroAddress();
        priceOracle = IPriceOracle(_priceOracleAddress);
        emit PriceOracleSet(_priceOracleAddress);

        for (uint i = 0; i < initialApprovedTokens.length; i++) {
            _addApprovedToken(initialApprovedTokens[i]);
        }

        // Optionally, add the owner as a strategist initially
        isStrategist[msg.sender] = true;
        emit StrategistAdded(msg.sender);
    }

    // --- Access Control ---

    /**
     * @notice Grants the STRATEGIST role to an address. Only callable by the owner.
     * @param strategist Address to grant the role to.
     */
    function addStrategist(address strategist) external onlyOwner {
        if (strategist.isZero()) revert ZeroAddress();
        if (isStrategist[strategist]) revert Unauthorized(); // Already a strategist
        isStrategist[strategist] = true;
        emit StrategistAdded(strategist);
    }

    /**
     * @notice Revokes the STRATEGIST role from an address. Only callable by the owner.
     * @param strategist Address to revoke the role from.
     */
    function removeStrategist(address strategist) external onlyOwner {
        if (strategist.isZero()) revert ZeroAddress();
        if (!isStrategist[strategist] || strategist == owner()) revert Unauthorized(); // Not a strategist or is the owner
        isStrategist[strategist] = false;
        emit StrategistRemoved(strategist);
    }

    // Override Ownable's transferOwnership to emit our specific event if needed,
    // or just use the base one. Let's keep it explicit for the function summary count.
    // Note: The base Ownable contract already emits OwnershipTransferred.
    // We'll just expose the function name for clarity in the summary.
    // function transferOwnership(address newOwner) public override onlyOwner {
    //     super.transferOwnership(newOwner);
    // }


    // --- Approved Tokens Management ---

    /**
     * @notice Adds an ERC20 token to the list of approved tokens the vault can manage. Only callable by the owner.
     * @param tokenAddress The address of the ERC20 token to approve.
     */
    function addApprovedToken(address tokenAddress) external onlyOwner {
       _addApprovedToken(tokenAddress);
    }

    /**
     * @dev Internal function to add an approved token.
     */
    function _addApprovedToken(address tokenAddress) internal {
        if (tokenAddress.isZero()) revert ZeroAddress();
        if (isApprovedToken[tokenAddress]) revert TokenIsApproved();

        isApprovedToken[tokenAddress] = true;
        _approvedTokensList.push(tokenAddress);
        emit TokensApproved(tokenAddress);
    }

    /**
     * @notice Removes an ERC20 token from the list of approved tokens. Only callable by the owner.
     *         Fails if the vault currently holds a balance of this token.
     * @param tokenAddress The address of the ERC20 token to remove.
     */
    function removeApprovedToken(address tokenAddress) external onlyOwner {
        if (tokenAddress.isZero()) revert ZeroAddress();
        if (!isApprovedToken[tokenAddress]) revert TokenNotApproved();
        if (IERC20(tokenAddress).balanceOf(address(this)) > 0) revert InvalidAmount(); // Cannot remove if vault holds balance

        isApprovedToken[tokenAddress] = false;
        // Remove from list (simple but potentially inefficient for large lists)
        for (uint i = 0; i < _approvedTokensList.length; i++) {
            if (_approvedTokensList[i] == tokenAddress) {
                _approvedTokensList[i] = _approvedTokensList[_approvedTokensList.length - 1];
                _approvedTokensList.pop();
                break;
            }
        }
        emit TokensRemoved(tokenAddress);
    }

    /**
     * @notice Gets the list of all currently approved token addresses.
     * @return An array of approved token addresses.
     */
    function getApprovedTokens() external view returns (address[] memory) {
        return _approvedTokensList;
    }


    // --- Vault Functions (ERC4626-inspired Logic) ---

    // Vault Shares ERC20 facade (partial implementation for supply and balances)
    function totalSupply() public view returns (uint256) {
        return _vaultSharesTotalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _vaultShares[account];
    }

    /**
     * @notice Deposits one or more approved tokens into the vault in exchange for vault shares.
     *         The amount of shares minted is based on the current total value of the vault.
     *         Requires the caller to approve the vault to spend the deposit amounts first.
     * @param depositTokens Array of token addresses to deposit.
     * @param depositAmounts Array of amounts corresponding to depositTokens.
     * @param receiver The address to receive the vault shares.
     * @return The number of vault shares minted.
     */
    function deposit(
        address[] memory depositTokens,
        uint256[] memory depositAmounts,
        address receiver
    ) external returns (uint256 sharesMinted) {
        if (depositTokens.length != depositAmounts.length || receiver.isZero()) revert InvalidAmount();

        uint256 totalValueBefore = getTotalVaultValue();
        uint256 vaultSharesBefore = _vaultSharesTotalSupply;

        // Transfer assets into the vault
        for (uint i = 0; i < depositTokens.length; i++) {
            address token = depositTokens[i];
            uint256 amount = depositAmounts[i];

            if (!isApprovedToken[token]) revert TokenNotApproved();
            if (amount == 0) continue;

            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        uint256 totalValueAfter = getTotalVaultValue();
        uint256 addedValue = totalValueAfter.sub(totalValueBefore);

        if (vaultSharesBefore == 0) {
            // First deposit: 1 share = 1 unit of vault value (e.g., 1 USD)
            // Assuming getTotalVaultValue returns value in USD-like units with 18 decimals
            sharesMinted = addedValue; // Or normalize to a base unit like 1e18
        } else {
            // Subsequent deposits: Shares minted based on value added relative to total value
            // shares = (addedValue * totalShares) / totalValueBefore
            // Using SafeMath adds checks against overflow/underflow
            sharesMinted = addedValue.mul(vaultSharesBefore).div(totalValueBefore);
        }

        if (sharesMinted == 0) revert InvalidAmount(); // Prevent minting zero shares

        _vaultShares[receiver] = _vaultShares[receiver].add(sharesMinted);
        _vaultSharesTotalSupply = _vaultSharesTotalSupply.add(sharesMinted);

        emit Deposit(msg.sender, receiver, addedValue, sharesMinted); // Event could detail tokens/amounts or total value
        return sharesMinted;
    }

     /**
      * @notice Redeems vault shares for a proportional amount of the underlying approved tokens.
      *         The specific tokens and amounts withdrawn depend on the current composition
      *         of the vault's assets. This simplified version attempts to withdraw
      *         proportionally based on vault's current token balances.
      * @param shares The number of vault shares to redeem.
      * @param receiver The address to receive the withdrawn tokens.
      * @param owner The address whose shares are being redeemed (allows withdrawal on behalf).
      * @return An array of withdrawn token addresses and their corresponding amounts.
      */
    function withdraw(
        uint256 shares,
        address receiver,
        address owner // Address whose shares are being redeemed (often msg.sender)
    ) external returns (address[] memory withdrawnTokens, uint256[] memory withdrawnAmounts) {
        if (shares == 0 || receiver.isZero() || owner.isZero()) revert InvalidAmount();
        if (_vaultShares[owner] < shares) revert InsufficientVaultBalance();
        if (_vaultSharesTotalSupply == 0) revert InsufficientVaultBalance(); // Cannot withdraw if no shares exist

        // Calculate total vault value and value being withdrawn
        uint256 totalValue = getTotalVaultValue();
        // valueToWithdraw = (shares * totalValue) / totalShares
        uint256 valueToWithdraw = shares.mul(totalValue).div(_vaultSharesTotalSupply);
        if (valueToWithdraw == 0) revert InvalidAmount(); // Value too small to withdraw anything

        // Calculate amounts to withdraw for each token based on current vault balances
        uint256 numApprovedTokens = _approvedTokensList.length;
        withdrawnTokens = new address[](numApprovedTokens);
        withdrawnAmounts = new uint256[](numApprovedTokens);

        // Need to ensure enough liquid assets are in the vault.
        // This simplistic implementation assumes all vault balance is liquid.
        // A real vault needs logic to pull from strategies/AMM if needed.
        uint256 vaultBalanceValueSum = 0;
         for (uint i = 0; i < numApprovedTokens; i++) {
             address token = _approvedTokensList[i];
             uint256 balance = IERC20(token).balanceOf(address(this));
             if (balance > 0) {
                 (uint256 price, uint8 decimals) = getAssetPrice(token);
                 if (price > 0) {
                     // Value = balance * price / (10^token_decimals) * (10^oracle_decimals)
                     // Simplified: Assume price and oracle decimals are consistent (e.g., 18)
                     // For production, use price feeds with consistent decimals or normalize carefully.
                     // Here, let's just use a basic multiplier assuming price is in a base unit per token unit
                      vaultBalanceValueSum = vaultBalanceValueSum.add(balance.mul(price)); // Rough sum
                 }
             }
         }

        if (vaultBalanceValueSum < valueToWithdraw) {
            // This is a critical point. If liquid balance isn't enough, withdrawal might fail
            // or require triggering deallocations from strategies/AMM.
            // For this example, we'll just check the liquid balance relative to the total value
            // and proportionally withdraw *from liquid assets*.
            // This is NOT how a real vault redemption works proportionally from *all* assets.
            // A real vault needs to manage liquidity and potentially make users wait or charge fees.
            // We will simplify and distribute the `valueToWithdraw` across available liquid balances.

            // Calculate value weight of each token in current liquid balance
             for (uint i = 0; i < numApprovedTokens; i++) {
                 address token = _approvedTokensList[i];
                 uint256 balance = IERC20(token).balanceOf(address(this));

                 if (balance > 0 && vaultBalanceValueSum > 0) {
                      (uint256 price, uint8 decimals) = getAssetPrice(token);
                      if (price > 0) {
                           // Value of this token's balance = balance * price (simplified)
                           uint256 tokenBalanceValue = balance.mul(price); // Rough value

                           // Amount to withdraw = (valueToWithdraw * tokenBalanceValue / vaultBalanceValueSum) / token_price
                           // Simplified: amount = (valueToWithdraw * balance) / vaultBalanceValueSum -- This is wrong
                           // Correct way: amount = (valueToWithdraw * (balance * price)) / (vaultBalanceValueSum * price) -> amount = (valueToWithdraw * balance) / vaultBalanceValueSum (using value sum in same units)
                           // Let's assume price feed returns value *per token unit* scaled by 1e18 for all tokens.
                           // Example: ETH price 2000e18, USDC price 1e18. 1 ETH has value 2000x, 1 USDC has value 1x.
                           // Total value: (ETH_bal * 2000) + (USDC_bal * 1) ... all scaled by 1e18
                           // Withdrawn amount of token = (valueToWithdraw / price) * (10^token_decimals)
                           // Need to handle decimals carefully. Assuming `getAssetPrice` returns price *per token unit* scaled to 18 decimals for simplicity here.

                           // amount = (valueToWithdraw * 1e18) / price; // Value in base unit, convert to token units
                            uint256 tokenValueInWithdrawal = valueToWithdraw.mul(tokenBalanceValue).div(vaultBalanceValueSum); // Value of this token to withdraw
                            uint256 amount = tokenValueInWithdrawal.div(price); // Amount of token to withdraw

                           if (amount > balance) amount = balance; // Cannot withdraw more than held liquidly
                           if (amount > 0) {
                                withdrawnTokens[i] = token;
                                withdrawnAmounts[i] = amount;
                                IERC20(token).safeTransfer(receiver, amount);
                           }
                      }
                 }
             }
         } else {
             // If liquid balance value is MORE than valueToWithdraw,
             // we could potentially withdraw exactly the required proportion from liquid assets.
             // This requires iterating again and calculating precise proportional amounts based on current balances.
             // Skipping exact proportional calculation from *liquid* pool for this example complexity.
             // The current loop *tries* to distribute the value proportionally across *all* approved token slots
             // but limited by actual liquid balance. This is a simplified redemption model.
             // A robust vault would manage liquidity pools or queue withdrawals.

             // For a simpler proportional liquid withdrawal:
             // 1. Calculate total liquid value vaultBalanceValueSum.
             // 2. For each token, calculate its weight in the liquid balance: (balance * price) / vaultBalanceValueSum.
             // 3. Calculate the total assets to be withdrawn in this token: valueToWithdraw * weight.
             // 4. Convert total assets in this token back to token amount: (valueToWithdraw * weight) / price.
             // This is complex and omitted for brevity in this example. The current loop attempts a rough distribution.
             revert CalculationError(); // Indicate this path needs proper implementation
         }


        _vaultShares[owner] = _vaultShares[owner].sub(shares);
        _vaultSharesTotalSupply = _vaultSharesTotalSupply.sub(shares);

        emit Withdraw(msg.sender, receiver, owner, shares, valueToWithdraw); // Event could detail tokens/amounts or total value
        return (withdrawnTokens, withdrawnAmounts);
    }

    /**
     * @notice Calculates the number of vault shares equivalent to a given value of assets.
     * @param assetsValue The value of assets (e.g., in USD scaled by 1e18).
     * @return The number of shares.
     */
    function convertToShares(uint256 assetsValue) public view returns (uint256) {
        uint256 totalValue = getTotalVaultValue();
        uint256 vaultShares = _vaultSharesTotalSupply;

        if (totalValue == 0 || vaultShares == 0) {
             // If vault is empty, 1 share = 1 unit of asset value (e.g., 1e18 USD)
            return assetsValue;
        }
        // shares = (assetsValue * totalShares) / totalValue
        return assetsValue.mul(vaultShares).div(totalValue);
    }

    /**
     * @notice Calculates the value of assets equivalent to a given number of vault shares.
     * @param shares The number of vault shares.
     * @return The value of assets (e.g., in USD scaled by 1e18).
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 totalValue = getTotalVaultValue();
        uint256 vaultShares = _vaultSharesTotalSupply;

        if (totalValue == 0 || vaultShares == 0) {
            return 0; // No value if vault is empty
        }
        // assetsValue = (shares * totalValue) / totalShares
        return shares.mul(totalValue).div(vaultShares);
    }

     /**
      * @notice Gets the total calculated value of all assets managed by the vault.
      *         Includes liquid balances, value in internal AMM (as balances), and value in strategies.
      *         Requires a working price oracle.
      * @return The total value of assets (e.g., in USD scaled by 1e18). Returns 0 if oracle is down or no assets/strategies.
      */
    function getTotalVaultValue() public view returns (uint256 totalValue) {
        address[] memory tokens = _approvedTokensList;
        address[] memory strategies = _approvedStrategiesList;
        uint256 numTokens = tokens.length;
        uint256 numStrategies = strategies.length;

        if (address(priceOracle).isZero()) revert OracleUnavailable();

        totalValue = 0;
        uint256 baseDecimals = 18; // Assume oracle returns value in 18 decimals

        // 1. Value of liquid assets (and assets considered "in AMM" as they are in contract balance)
        for (uint i = 0; i < numTokens; i++) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                 (uint256 price, uint8 decimals) = getAssetPrice(token); // Call internal helper
                 if (price > 0) {
                     // Normalize token balance value to baseDecimals using oracle price
                     // value = (balance * price) / (10^token_decimals) * (10^base_decimals)
                     // Simplified: assuming price is per token unit scaled to baseDecimals
                     totalValue = totalValue.add(balance.mul(price).div(10**decimals));
                 } else {
                     // If price is zero, cannot accurately value.
                     // In a real system, handle this: halt, use old price, or exclude.
                     // For example, return 0 or revert. Let's return 0 as an indicator of failed valuation.
                     return 0;
                 }
            }
        }

        // 2. Value of assets allocated to strategies
        for (uint i = 0; i < numStrategies; i++) {
            address strategyAddress = strategies[i];
            IStrategy strategy = IStrategy(strategyAddress);
             (uint256 strategyValue, uint8 decimals) = strategy.getValue(); // Strategy reports its total value
             if (strategyValue > 0) {
                  // Normalize strategy value to baseDecimals
                 totalValue = totalValue.add(strategyValue.mul(10**baseDecimals).div(10**decimals));
             } else {
                 // If strategy reports 0 value, either it's empty or failed to report.
                 // In a real system, handle carefully. For example, just add 0 or revert.
                 // For example, return 0 if any strategy fails to report value.
                  // return 0; // More strict approach
             }
        }

        return totalValue;
    }

    /**
     * @notice Alias for getTotalVaultValue for clarity in summary.
     * @return The total value of assets (e.g., in USD scaled by 1e18).
     */
     function totalAssets() public view returns (uint256) {
         return getTotalVaultValue();
     }

    /**
     * @notice Calculates the price of one vault share relative to the vault's total value.
     * @return The value of one share (e.g., in USD scaled by 1e18).
     */
    function getVaultSharePrice() public view returns (uint256) {
        uint256 totalValue = getTotalVaultValue();
        uint256 totalShares = _vaultSharesTotalSupply;

        if (totalValue == 0 || totalShares == 0) {
            // If vault is empty, define price as 1 unit of value per share (e.g., 1e18 USD per share)
            return 1e18;
        }

        // price = totalValue / totalShares
        return totalValue.div(totalShares); // Assuming totalValue and totalShares have compatible scaling
    }

    /**
     * @notice Helper to get asset price from the oracle.
     * @param assetAddress The address of the asset.
     * @return price The price of the asset scaled by oracle decimals. Returns 0 if oracle call fails or price stale.
     * @return decimals The decimal precision of the price. Returns 0 if oracle call fails.
     */
    function getAssetPrice(address assetAddress) public view onlyApprovedToken(assetAddress) returns (uint256 price, uint8 decimals) {
        if (address(priceOracle).isZero()) revert OracleUnavailable();
         // Note: Real Chainlink returns price, timestamp, roundId. Check timestamp for staleness.
        // For simplicity here, we just use the price and decimals returned by the interface.
        // A real implementation MUST check the timestamp and possibly roundId.
        try priceOracle.getLatestPrice(assetAddress) returns (uint256 _price, uint8 _decimals) {
            // Check for non-zero price or other conditions for validity if needed
            if (_price > 0) {
                 return (_price, _decimals);
            } else {
                return (0, 0); // Price unavailable or zero
            }
        } catch {
            return (0, 0); // Oracle call failed
        }
    }


    // --- Internal AMM Functions ---
    // Note: This is a very simplified internal AMM. A real one requires careful
    // reserve management per pair and handling potential attacks like sandwiching.
    // This example treats the vault's general balance as shared reserves.

    /**
     * @notice Adds liquidity for a pair of approved tokens into the internal AMM pool.
     *         Funds are moved from the vault's general balance into designated reserves (conceptually,
     *         though physically they remain in the contract balance).
     * @dev In this simplified model, adding liquidity just means ensuring the tokens are held.
     *      A real AMM would manage specific reserves per pair and issue LP tokens.
     * @param tokenA Address of the first token.
     * @param amountA Amount of the first token to add.
     * @param tokenB Address of the second token.
     * @param amountB Amount of the second token to add.
     * @param to Address receiving any potential internal LP tokens (not implemented in this simplified version).
     */
    function addLiquidity(
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB,
        address to // Who gets LP tokens - not implemented here
    ) external onlyStrategist onlyApprovedToken(tokenA) onlyApprovedToken(tokenB) {
         if (tokenA == tokenB) revert InvalidAmount();
         if (amountA == 0 && amountB == 0) revert InvalidAmount();
         // Note: In a real AMM, this would check if enough tokens are in the vault's liquid balance
         // and update specific pair reserves, mint LP tokens, etc.
         // This simplified version just logs the intent.
         emit LiquidityAdded(msg.sender, tokenA, amountA, tokenB, amountB);
    }

    /**
     * @notice Removes liquidity from the internal AMM pool.
     * @dev In this simplified model, removing liquidity just means making the tokens available
     *      in the vault's general balance. A real AMM would burn LP tokens and transfer reserves.
     * @param tokenA Address of the first token in the pair.
     * @param tokenB Address of the second token in the pair.
     * @param amountLPTokens The amount of internal LP tokens to burn (not used in this simplified version).
     * @param minAmountA Minimum amount of tokenA to receive.
     * @param minAmountB Minimum amount of tokenB to receive.
     * @param to Address receiving the tokens.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountLPTokens, // Not used in simplified model
        uint256 minAmountA,
        uint256 minAmountB,
        address to
    ) external onlyStrategist onlyApprovedToken(tokenA) onlyApprovedToken(tokenB) {
        if (tokenA == tokenB) revert InvalidAmount();
        if (to.isZero()) revert ZeroAddress();
        // Note: Real AMM needs amountLPTokens > 0, check minimums, calculate amounts based on reserves, burn LP tokens.
        // This simplified version just logs the intent and checks minimums conceptually.
        // We'd need to calculate actual amounts based on current reserves/state.
        // Example placeholders: uint256 actualAmountA = calculateA; uint256 actualAmountB = calculateB;
        // if (actualAmountA < minAmountA || actualAmountB < minAmountB) revert SlippageTooHigh();
        // IERC20(tokenA).safeTransfer(to, actualAmountA);
        // IERC20(tokenB).safeTransfer(to, actualAmountB);

        emit LiquidityRemoved(msg.sender, tokenA, 0, tokenB, 0); // Log 0 amounts as calculation is complex
    }

    /**
     * @notice Performs a swap between two approved tokens using the internal AMM pool.
     *         Assumes a basic x*y=k invariant on the contract's current balances of the pair.
     * @param amountIn The amount of tokenIn to swap.
     * @param amountOutMin The minimum acceptable amount of tokenOut.
     * @param tokenIn The address of the token being swapped in.
     * @param tokenOut The address of the token being swapped out.
     * @param to The address to receive the tokenOut.
     * @return The amount of tokenOut received.
     */
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to
    ) external onlyStrategist onlyApprovedToken(tokenIn) onlyApprovedToken(tokenOut) returns (uint256 amountOut) {
        if (amountIn == 0 || amountOutMin == 0 || tokenIn == tokenOut || to.isZero()) revert InvalidAmount();

        uint256 reserveIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 reserveOut = IERC20(tokenOut).balanceOf(address(this));

        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        // Basic x*y=k swap logic (simplified, no fee)
        // (reserveIn + amountIn) * (reserveOut - amountOut) = reserveIn * reserveOut
        // reserveOut - amountOut = (reserveIn * reserveOut) / (reserveIn + amountIn)
        // amountOut = reserveOut - (reserveIn * reserveOut) / (reserveIn + amountIn)
        // amountOut = reserveOut * (1 - reserveIn / (reserveIn + amountIn))
        // amountOut = reserveOut * ( (reserveIn + amountIn - reserveIn) / (reserveIn + amountIn) )
        // amountOut = reserveOut * (amountIn / (reserveIn + amountIn))
        // amountOut = (reserveOut * amountIn) / (reserveIn + amountIn)

        // With Fee (e.g., 0.3% fee -> 99.7% goes to liquidity)
        // (reserveIn + amountIn * (1 - fee)) * (reserveOut - amountOut) = reserveIn * reserveOut
        // Let fee be 0.3%, (1 - fee) = 0.997. Represent as 997/1000 or 9970/10000 (basis points)
        // (reserveIn * 1000 + amountIn * 997) * (reserveOut - amountOut) = reserveIn * reserveOut * 1000
        // amountOut = reserveOut - (reserveIn * reserveOut * 1000) / (reserveIn * 1000 + amountIn * 997)
        // This requires large numbers, better use:
        // amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
         uint256 amountInWithFee = amountIn.mul(997); // Assuming 0.3% fee (9970 basis points out of 10000)
         amountOut = reserveOut.mul(amountInWithFee).div(reserveIn.mul(1000).add(amountInWithFee));

        if (amountOut < amountOutMin) revert SlippageTooHigh();
        if (amountOut == 0) revert InvalidAmount();

        // Update reserves (conceptually, just transfer tokens)
        // The tokens are already in the vault's balance.
        // We just need to transfer tokenOut to the recipient.
        // Note: In a real AMM, this would adjust the internal reserve state *before* transferring.
        // This simplified version relies on contract balance and implies the swap happens instantly.
        // IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn); // If user swaps directly
        // In this Vault context, strategist triggers swap using *vault's* funds.
        // So, amountIn must be available in vault balance.

        // Transfer out the calculated amount
        IERC20(tokenOut).safeTransfer(to, amountOut);

        emit Swap(msg.sender, tokenIn, amountIn, tokenOut, amountOut);
        return amountOut;
    }

    /**
     * @notice View function to calculate the expected output amount for a swap.
     *         Uses the current vault token balances as reserves.
     * @param amountIn The amount of tokenIn.
     * @param tokenIn The address of the token being swapped in.
     * @param tokenOut The address of the token being swapped out.
     * @return The expected amount of tokenOut.
     */
     function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
     ) external view onlyApprovedToken(tokenIn) onlyApprovedToken(tokenOut) returns (uint256) {
         if (amountIn == 0 || tokenIn == tokenOut) return 0;

         uint256 reserveIn = IERC20(tokenIn).balanceOf(address(this));
         uint256 reserveOut = IERC20(tokenOut).balanceOf(address(this));

         if (reserveIn == 0 || reserveOut == 0) return 0; // Not enough liquidity

         // Same calculation as in swap, but without state change or checks
         uint256 amountInWithFee = amountIn.mul(997); // Assuming 0.3% fee
         uint256 amountOut = reserveOut.mul(amountInWithFee).div(reserveIn.mul(1000).add(amountInWithFee));
         return amountOut;
     }


    /**
     * @notice View function to get the current balance of an approved token held by the vault.
     *         This represents the liquid reserve of the token.
     * @param tokenAddress The address of the approved token.
     * @return The balance of the token held by the vault.
     */
     function getReserves(address tokenAddress) external view onlyApprovedToken(tokenAddress) returns (uint256) {
         return IERC20(tokenAddress).balanceOf(address(this));
     }

     /**
      * @notice View function to get the total supply of internal AMM LP tokens (if implemented).
      * @dev This is a placeholder as internal LP tokens are not fully implemented in this example.
      * @return Always returns 0 in this simplified version.
      */
     function getInternalLPTokenSupply() external pure returns (uint256) {
         // This would return the total supply of LP tokens for a specific pair in a real AMM
         // For this simplified model, we return 0.
         return 0;
     }


    // --- Strategy Management & Execution ---

    /**
     * @notice Adds a strategy contract to the list of approved strategies. Only callable by the owner.
     * @param strategyAddress The address of the strategy contract.
     */
    function addStrategy(address strategyAddress) external onlyOwner {
        if (strategyAddress.isZero()) revert ZeroAddress();
        if (isApprovedStrategy[strategyAddress]) revert StrategyIsApproved();

        isApprovedStrategy[strategyAddress] = true;
        _approvedStrategiesList.push(strategyAddress);
        emit StrategyApproved(strategyAddress);
    }

    /**
     * @notice Removes a strategy contract from the list of approved strategies. Only callable by the owner.
     *         Fails if the vault has funds currently allocated to this strategy (requires manual deallocation first).
     * @param strategyAddress The address of the strategy contract.
     */
    function removeStrategy(address strategyAddress) external onlyOwner onlyApprovedStrategy(strategyAddress) {
        if (strategyAddress.isZero()) revert ZeroAddress();
        // Check if strategy has funds. This requires the strategy to have a getValue() or similar.
        // Simplified check: just try calling getValue and if it returns > 0 value, disallow removal.
        // A more robust check would track allocations within the vault or require the strategy to confirm 0 balance.
        (uint256 value, ) = IStrategy(strategyAddress).getValue();
        if (value > 0) revert StrategyHasAllocations();

        isApprovedStrategy[strategyAddress] = false;
         // Remove from list (simple but potentially inefficient)
         for (uint i = 0; i < _approvedStrategiesList.length; i++) {
             if (_approvedStrategiesList[i] == strategyAddress) {
                 _approvedStrategiesList[i] = _approvedStrategiesList[_approvedStrategiesList.length - 1];
                 _approvedStrategiesList.pop();
                 break;
             }
         }
        // Also clear the target allocation
        delete _strategyTargetAllocations[strategyAddress];

        emit StrategyRemoved(strategyAddress);
    }


    /**
     * @notice Sets the target percentage of the allocatable vault value that should be deployed to a specific strategy.
     *         Allocatable value is typically the total value minus minimum liquidity reserves.
     *         Callable by owner or strategist.
     * @param strategyAddress The address of the approved strategy.
     * @param percentageBasisPoints The target percentage in basis points (e.g., 5000 for 50%). Max 10000.
     */
    function setStrategyTargetAllocation(address strategyAddress, uint256 percentageBasisPoints) external onlyStrategist onlyApprovedStrategy(strategyAddress) {
        if (percentageBasisPoints > 10000) revert InvalidAmount();
        _strategyTargetAllocations[strategyAddress] = percentageBasisPoints;
        emit StrategyTargetAllocationSet(strategyAddress, percentageBasisPoints);
    }

    /**
     * @notice Moves a specified amount of an approved token from the vault's liquid balance
     *         into an approved strategy via its `invest` function.
     *         Callable by strategist.
     * @param strategyAddress The address of the approved strategy.
     * @param tokenAddress The address of the approved token to allocate.
     * @param amount The amount of the token to allocate.
     */
    function allocateToStrategy(
        address strategyAddress,
        address tokenAddress,
        uint256 amount
    ) external onlyStrategist onlyApprovedStrategy(strategyAddress) onlyApprovedToken(tokenAddress) {
        if (amount == 0) revert InvalidAmount();
        if (IERC20(tokenAddress).balanceOf(address(this)) < amount) revert InsufficientVaultBalance();

        // Transfer tokens to the strategy contract
        IERC20(tokenAddress).safeTransfer(strategyAddress, amount);

        // Tell the strategy to invest the received tokens
        IStrategy(strategyAddress).invest(tokenAddress, amount);

        // Note: Tracking the *exact* amount/value currently in each strategy within the vault state is complex
        // and often relies on the strategy's own reporting (`getValue()` or similar).
        // This call just initiates the allocation.

        emit AllocatedToStrategy(msg.sender, strategyAddress, tokenAddress, amount);
    }

     /**
      * @notice Requests redemption of a specified amount (or strategy-specific representation)
      *         of an approved token from an approved strategy back into the vault's liquid balance.
      *         Callable by strategist.
      * @param strategyAddress The address of the approved strategy.
      * @param tokenAddress The address of the approved token expected back.
      * @param amountOrShares The amount of underlying asset or strategy-specific shares/representation to redeem.
      * @dev The strategy's `redeem` function must return the actual amount of `tokenAddress` redeemed.
      */
    function redeemFromStrategy(
        address strategyAddress,
        address tokenAddress,
        uint256 amountOrShares
    ) external onlyStrategist onlyApprovedStrategy(strategyAddress) onlyApprovedToken(tokenAddress) {
        if (amountOrShares == 0) revert InvalidAmount();

        // Call the strategy's redeem function
        // The strategy should transfer the tokens back to the vault (address(this))
        uint256 redeemedAmount = IStrategy(strategyAddress).redeem(tokenAddress, amountOrShares);

        // Verify the vault received the tokens (optional but good practice)
        // uint256 balanceBefore = IERC20(tokenAddress).balanceOf(address(this));
        // ... call redeem ...
        // uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        // if (balanceAfter.sub(balanceBefore) < redeemedAmount) ... error or adjust redeemedAmount ...
        // For simplicity, we trust the strategy's return value here.

        if (redeemedAmount == 0) revert InvalidAmount(); // Strategy returned 0 redeemed amount

        emit RedeemedFromStrategy(msg.sender, strategyAddress, tokenAddress, redeemedAmount);
    }

    /**
     * @notice Triggers the harvest function on an approved strategy to collect yield.
     *         Callable by strategist.
     * @param strategyAddress The address of the approved strategy.
     */
    function executeStrategyHarvest(address strategyAddress) external onlyStrategist onlyApprovedStrategy(strategyAddress) {
        IStrategy(strategyAddress).harvest();
        // The strategy should transfer harvested assets (could be any token) back to the vault (address(this)).
        // The vault's `getTotalVaultValue` will increase when assets are received.
        emit StrategyHarvested(msg.sender, strategyAddress);
    }

     /**
      * @notice Callable by strategist to attempt to rebalance assets towards target allocations.
      *         This is a simplified trigger. A real rebalancer would analyze current
      *         allocations vs targets and execute invest/redeem/swap actions.
      * @dev This implementation is a placeholder; actual rebalancing logic is complex.
      *      It could prioritize allocating available liquid funds to under-allocated strategies
      *      or pulling funds from over-allocated ones (if `redeemFromStrategy` is automated).
      *      This simplified version just logs the action.
      */
    function rebalanceAllocations() external onlyStrategist {
        // Example of complex logic needed here:
        // 1. Get total vault value.
        // 2. For each strategy:
        //    a. Get strategy's current value using strategy.getValue().
        //    b. Calculate target value for this strategy: totalVaultValue * targetPercentage / 10000.
        //    c. Compare current value to target value.
        //    d. If under target, calculate difference, identify liquid assets, and call allocateToStrategy.
        //    e. If over target, calculate difference, and potentially call redeemFromStrategy (requires complex decisions on which token/amount to redeem).
        // 3. Might also involve internal swaps or adding/removing internal liquidity to get required tokens for strategies.
        // 4. Gas limits are a major constraint for complex rebalancing in a single transaction.

        // Placeholder logic: Iterate approved strategies and try to allocate some of *any* available token if a target is set.
        address[] memory strategies = _approvedStrategiesList;
        address[] memory tokens = _approvedTokensList;
        uint256 numTokens = tokens.length;

        for (uint i = 0; i < strategies.length; i++) {
            address strategyAddress = strategies[i];
            uint256 targetPercentage = _strategyTargetAllocations[strategyAddress];

            if (targetPercentage > 0) {
                // This is a very basic trigger. A real rebalancer would be much smarter.
                // For example, allocate a small amount of a specific token if available.
                // Skipping actual allocation logic due to complexity.
                // This function primarily serves as a designated entry point for off-chain bots
                // or future complex on-chain rebalancing logic.
            }
        }
        // No event emitted for this simplified placeholder, as it doesn't perform concrete actions.
        // A real implementation would log specific allocation/redeem calls it triggers.
    }

    /**
     * @notice Gets the list of all currently approved strategy addresses.
     * @return An array of approved strategy addresses.
     */
     function getApprovedStrategies() external view returns (address[] memory) {
         return _approvedStrategiesList;
     }

    /**
     * @notice Gets the target allocation percentages for all approved strategies.
     * @return An array of strategy addresses and their corresponding target percentages in basis points.
     */
     function getStrategyAllocations() external view returns (address[] memory strategies, uint256[] memory percentages) {
         strategies = _approvedStrategiesList;
         percentages = new uint256[](strategies.length);
         for(uint i = 0; i < strategies.length; i++) {
             percentages[i] = _strategyTargetAllocations[strategies[i]];
         }
         return (strategies, percentages);
     }

    /**
     * @notice Gets the list of addresses with the STRATEGIST role.
     * @return An array of strategist addresses.
     * @dev This simple array iteration might become expensive with many strategists.
     *      A real system might use a different data structure or event history.
     */
     function getStrategists() external view returns (address[] memory) {
         address[] memory strategistsList = new address[](_strategists.length); // Need to track count separately or iterate map
         // This requires iterating the map, which is not directly supported in Solidity for view functions returning dynamic arrays.
         // A better way is to maintain a separate list like _approvedTokensList, or simply rely on the `isStrategist` mapping.
         // For this example, we'll return an empty array or revert, as iterating a mapping isn't suitable for this return type.
         // Let's just return an empty array as a placeholder.
         return new address[](0);
         // If we maintained a list:
         // return _strategistsList; // Assuming a list variable like `address[] private _strategistsList;`
     }


    // --- View Functions ---

    // Note: Many view functions are already included above within their sections (e.g., convertToShares, totalAssets, getReserves)

     /**
      * @notice Gets the current balance of a specific approved token held within the vault contract.
      * @param tokenAddress The address of the approved token.
      * @return The balance of the token.
      */
     function getVaultTokenBalance(address tokenAddress) external view onlyApprovedToken(tokenAddress) returns (uint256) {
         return IERC20(tokenAddress).balanceOf(address(this));
     }

    // --- Protocol Fee Functions (Optional - Example) ---
    /*
    function setProtocolFeeBasisPoints(uint256 feeBasisPoints) external onlyOwner {
        // Add validation: max fee %
        // protocolFeeBasisPoints = feeBasisPoints;
        // emit ProtocolFeeSet(feeBasisPoints);
    }

    function setFeeRecipient(address recipient) external onlyOwner {
         if (recipient.isZero()) revert ZeroAddress();
         // feeRecipient = recipient;
         // emit FeeRecipientSet(recipient);
    }
    */
}
```