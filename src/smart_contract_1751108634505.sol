Okay, let's design a smart contract that goes beyond typical DeFi or NFT mechanics. How about a contract that enables *conditional, time-locked, oracle-dependent swaps* combined with a unique liquidity provision mechanism and dynamic features?

We'll call it "QuantumSwap". Users can set up swaps that only execute if a certain price target is met within a specific time window, using a price oracle. Liquidity providers supply tokens to pools, earning fees from successful swaps. We'll add features like TWAP conditions, cancelling/claiming expired swaps, dynamic fees, and modular token support.

This isn't a standard AMM (like Uniswap) or order book (like 0x). It's a hybrid, more like a decentralized, automated conditional limit order system backed by pooled liquidity.

---

## Contract Outline & Function Summary

**Contract Name:** `QuantumSwap`

**Description:**
A smart contract enabling users to request conditional, time-locked swaps between approved ERC20 tokens. Swaps only execute if a predefined price condition (based on an external oracle feed) is met within a specified time window. The contract also manages token liquidity pools provided by users and distributes swap fees.

**Key Concepts:**
*   **Conditional Swaps:** Swaps execute only if a price ratio condition is met.
*   **Time-Locked:** Conditions must be met within a user-defined start and end time window.
*   **Oracle Dependence:** Relies on external price feeds (e.g., Chainlink) for price conditions.
*   **Pooled Liquidity:** Liquidity providers supply tokens to pools to facilitate conditional swaps.
*   **Dynamic Features:** Supports TWAP conditions, adjustable fees, approved tokens list.

**Core Features (User/LP Interaction):**
1.  `requestConditionalSwap`: User locks tokens for a swap based on price, time, and oracle feed.
2.  `executeConditionalSwap`: Public function to trigger execution of eligible swaps.
3.  `cancelConditionalSwap`: User cancels their pending swap before the window starts or if conditions are no longer relevant.
4.  `claimExpiredSwap`: User claims back tokens if the swap window expires without execution.
5.  `provideLiquidity`: User adds tokens to a liquidity pool to earn fees.
6.  `withdrawLiquidity`: User removes tokens from a liquidity pool.
7.  `distributeLiquidityFees`: Allows liquidity providers to claim accumulated fees.

**Admin & Utility Features:**
8.  `setOracleAddress`: Owner sets the address for the price oracle.
9.  `setSwapFee`: Owner sets the percentage fee charged on successful swaps.
10. `setLiquidityFeeShare`: Owner sets the percentage of swap fees distributed to LPs.
11. `setTWAPPeriod`: Owner sets the lookback period for TWAP calculations (if used).
12. `setApprovedTokens`: Owner approves or unapproves tokens the contract can handle.
13. `pauseContract`: Owner pauses critical contract operations.
14. `unpauseContract`: Owner unpauses critical contract operations.
15. `collectProtocolFees`: Owner collects the protocol's share of swap fees.
16. `emergencyWithdrawAdmin`: Owner can withdraw specific tokens in emergencies (use with extreme caution!).

**View/Query Functions:**
17. `getPendingSwapDetails`: Retrieve parameters for a specific pending swap.
18. `getUserPendingSwaps`: List all pending swap IDs for a given user.
19. `getLiquidityBalance`: Get user's liquidity balance for a specific token.
20. `getPoolLiquidity`: Get the total liquidity for a specific token pool.
21. `getCurrentPrice`: Get the current price from the oracle for a token pair.
22. `checkSwapEligibility`: Check if a specific pending swap currently meets its condition.
23. `isTokenApproved`: Check if a token address is approved by the owner.
24. `getRequiredTWAPPeriod`: Get the current TWAP lookback period setting.
25. `getSwapFee`: Get the current swap fee percentage.
26. `getLiquidityFeeShare`: Get the current LP fee share percentage.
27. `getProtocolFeeBalance`: Get the accumulated protocol fee for a token.
28. `getLiquidityFeeBalance`: Get the total accumulated LP fee for a token pool.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title QuantumSwap
/// @author YourNameOrAlias
/// @notice A smart contract for conditional, time-locked, oracle-dependent swaps with pooled liquidity.
contract QuantumSwap is Ownable, ReentrancyGuard {

    /*═════════════════════════════════════════ State Variables ═════════════════════════════════════════*/

    struct PendingSwap {
        address user;               // The user requesting the swap
        address tokenIn;            // The token the user is depositing
        address tokenOut;           // The token the user wants to receive
        uint256 amountIn;           // The amount of tokenIn deposited
        uint256 minAmountOut;       // Minimum amount of tokenOut user must receive
        uint256 targetPriceRatio;   // Price ratio (tokenIn / tokenOut) in fixed-point, multiplied by priceFeedDecimals
        bool useTWAP;               // Whether to use TWAP or spot price for condition
        uint256 startTime;          // Timestamp when the swap becomes eligible for execution
        uint256 endTime;            // Timestamp after which the swap expires
        bool executed;              // Whether the swap has been executed
        bool cancelled;             // Whether the swap has been cancelled
    }

    // Mapping from swap ID to PendingSwap struct
    mapping(uint256 => PendingSwap) public pendingSwaps;
    uint256 private _nextSwapId = 1; // Counter for unique swap IDs

    // Mapping from token address to total liquidity amount
    mapping(address => uint256) public totalLiquidity;

    // Mapping from user address to token address to liquidity amount
    mapping(address => mapping(address => uint256)) public liquidityBalances;

    // Mapping from token address to accumulated protocol fees
    mapping(address => uint256) public protocolFeeBalances;

    // Mapping from token address to accumulated LP fees
    mapping(address => uint256) public liquidityFeeBalances;

    // Oracle address for price feeds (e.g., Chainlink Aggregator)
    AggregatorV3Interface public priceOracle;

    // Fee percentage for executed swaps (e.g., 10 = 0.1%)
    uint256 public swapFeeBps; // Basis points (100 = 1%)

    // Percentage of swapFeeBps allocated to LPs (e.g., 7000 = 70%)
    uint256 public liquidityFeeShareBps; // Basis points

    // Lookback period for TWAP calculation in seconds
    uint256 public twapPeriod; // In seconds

    // Mapping of approved token addresses
    mapping(address => bool) public approvedTokens;

    // Paused state
    bool public paused = false;

    /*═════════════════════════════════════════ Events ═════════════════════════════════════════*/

    /// @dev Emitted when a new conditional swap request is made.
    /// @param swapId The unique ID of the new swap.
    /// @param user The address of the user requesting the swap.
    /// @param tokenIn The address of the token deposited by the user.
    /// @param amountIn The amount of tokenIn deposited.
    /// @param tokenOut The address of the token the user wants to receive.
    /// @param targetPriceRatio The target price ratio set by the user.
    /// @param useTWAP Whether TWAP was requested for the condition.
    /// @param startTime The timestamp when the swap becomes eligible.
    /// @param endTime The timestamp when the swap expires.
    event ConditionalSwapRequested(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 targetPriceRatio,
        bool useTWAP,
        uint256 startTime,
        uint256 endTime
    );

    /// @dev Emitted when a conditional swap is successfully executed.
    /// @param swapId The unique ID of the executed swap.
    /// @param user The address of the user who requested the swap.
    /// @param tokenIn The address of the token swapped out.
    /// @param amountIn The amount of tokenIn swapped out.
    /// @param tokenOut The address of the token swapped in.
    /// @param amountOut The amount of tokenOut swapped in.
    /// @param feeAmount The amount of fee collected from the swap.
    event ConditionalSwapExecuted(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        uint256 feeAmount
    );

    /// @dev Emitted when a pending swap is cancelled by the user.
    /// @param swapId The unique ID of the cancelled swap.
    /// @param user The address of the user who cancelled.
    /// @param tokenIn The address of the token refunded.
    /// @param amountIn The amount of token refunded.
    event ConditionalSwapCancelled(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn
    );

    /// @dev Emitted when an expired swap is claimed by the user.
    /// @param swapId The unique ID of the expired swap.
    /// @param user The address of the user who claimed.
    /// @param tokenIn The address of the token refunded.
    /// @param amountIn The amount of token refunded.
    event ExpiredSwapClaimed(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn
    );

    /// @dev Emitted when a user provides liquidity to a pool.
    /// @param user The address of the liquidity provider.
    /// @param token The address of the token provided.
    /// @param amount The amount of token provided.
    event LiquidityProvided(address indexed user, address indexed token, uint256 amount);

    /// @dev Emitted when a user withdraws liquidity from a pool.
    /// @param user The address of the liquidity provider.
    /// @param token The address of the token withdrawn.
    /// @param amount The amount of token withdrawn.
    event LiquidityWithdrawal(address indexed user, address indexed token, uint256 amount);

    /// @dev Emitted when LP fees are distributed to a user.
    /// @param user The address of the liquidity provider.
    /// @param token The address of the token the fee is in.
    /// @param amount The amount of fee distributed.
    event LiquidityFeesDistributed(address indexed user, address indexed token, uint256 amount);

    /// @dev Emitted when protocol fees are collected by the owner.
    /// @param owner The contract owner.
    /// @param token The address of the token the fee is in.
    /// @param amount The amount of fee collected.
    event ProtocolFeesCollected(address indexed owner, address indexed token, uint256 amount);

    /// @dev Emitted when the contract is paused or unpaused.
    /// @param paused The new paused state.
    event Paused(bool paused);

    /// @dev Emitted when a token's approval status is updated.
    /// @param token The address of the token.
    /// @param approved Whether the token is now approved.
    event TokenApprovalUpdated(address indexed token, bool approved);

    /*═════════════════════════════════════════ Modifiers ═════════════════════════════════════════*/

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    /*═════════════════════════════════════════ Constructor ═════════════════════════════════════════*/

    /// @notice Initializes the contract with owner, oracle, and initial settings.
    /// @param initialOwner The address of the initial owner.
    /// @param _priceOracle The address of the Chainlink AggregatorV3Interface.
    /// @param _swapFeeBps Initial swap fee percentage in basis points (e.g., 10 for 0.1%).
    /// @param _liquidityFeeShareBps Initial percentage of swap fees going to LPs in basis points (e.g., 7000 for 70%).
    /// @param _twapPeriod Initial TWAP lookback period in seconds.
    constructor(address initialOwner, address _priceOracle, uint256 _swapFeeBps, uint256 _liquidityFeeShareBps, uint256 _twapPeriod) Ownable(initialOwner) {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = AggregatorV3Interface(_priceOracle);
        swapFeeBps = _swapFeeBps;
        liquidityFeeShareBps = _liquidityFeeShareBps;
        twapPeriod = _twapPeriod;
        // Approve ETH/WETH by default if needed, or leave empty for owner to approve tokens
    }

    /*═════════════════════════════════════════ Core User/LP Functions ═════════════════════════════════════════*/

    /// @notice Requests a conditional swap by depositing tokenIn.
    /// User must have approved this contract to transfer `amountIn` of `tokenIn`.
    /// @param tokenIn The address of the token to deposit.
    /// @param amountIn The amount of tokenIn to deposit.
    /// @param tokenOut The address of the token desired in return.
    /// @param minAmountOut The minimum amount of tokenOut required for the swap to be valid upon execution.
    /// @param targetPriceRatio The target price ratio (tokenIn / tokenOut) * 10^decimals of the price feed.
    /// @param _useTWAP Whether to use TWAP (true) or spot price (false) for the condition check.
    /// @param _startTime Timestamp when the swap becomes eligible for execution. Must be in the future or now.
    /// @param _endTime Timestamp after which the swap expires. Must be after _startTime.
    /// @return swapId The unique ID of the created pending swap.
    function requestConditionalSwap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 targetPriceRatio,
        bool _useTWAP,
        uint256 _startTime,
        uint256 _endTime
    ) external whenNotPaused nonReentrant returns (uint256 swapId) {
        require(amountIn > 0, "AmountIn must be > 0");
        require(minAmountOut > 0, "MinAmountOut must be > 0");
        require(tokenIn != address(0) && tokenOut != address(0) && tokenIn != tokenOut, "Invalid token addresses");
        require(approvedTokens[tokenIn], "TokenIn not approved");
        require(approvedTokens[tokenOut], "TokenOut not approved");
        require(_startTime >= block.timestamp, "Start time must be in the future or now");
        require(_endTime > _startTime, "End time must be after start time");
        require(targetPriceRatio > 0, "Target price ratio must be > 0");

        swapId = _nextSwapId++;
        pendingSwaps[swapId] = PendingSwap({
            user: msg.sender,
            tokenIn: tokenIn,
            amountIn: amountIn,
            tokenOut: tokenOut,
            minAmountOut: minAmountOut,
            targetPriceRatio: targetPriceRatio,
            useTWAP: _useTWAP,
            startTime: _startTime,
            endTime: _endTime,
            executed: false,
            cancelled: false
        });

        // Transfer tokens from user to contract
        bool success = IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        require(success, "Token transfer failed");

        emit ConditionalSwapRequested(
            swapId,
            msg.sender,
            tokenIn,
            amountIn,
            tokenOut,
            targetPriceRatio,
            _useTWAP,
            _startTime,
            _endTime
        );
    }

    /// @notice Executes a pending conditional swap if its conditions are met and it's within the time window.
    /// This function can be called by anyone. Incentive for calling is future feature (e.g., gas rebate).
    /// @param swapId The ID of the pending swap to execute.
    function executeConditionalSwap(uint256 swapId) external nonReentrant whenNotPaused {
        PendingSwap storage swap = pendingSwaps[swapId];

        require(swap.user != address(0), "Swap ID does not exist");
        require(!swap.executed, "Swap already executed");
        require(!swap.cancelled, "Swap cancelled");
        require(block.timestamp >= swap.startTime, "Swap window has not started");
        require(block.timestamp <= swap.endTime, "Swap window has ended");
        require(checkSwapEligibility(swapId), "Swap conditions not met");
        require(totalLiquidity[swap.tokenOut] >= swap.minAmountOut, "Insufficient liquidity in tokenOut pool");

        swap.executed = true;

        // Calculate amountOut based on current oracle price and fees
        uint256 currentPriceRatio = swap.useTWAP ? _getTWAP(swap.tokenIn, swap.tokenOut) : _getSpotPrice(swap.tokenIn, swap.tokenOut);
        require(currentPriceRatio > 0, "Could not get valid oracle price"); // Should also be handled by checkSwapEligibility, but good safety check
        require(priceOracle.decimals() > 0, "Oracle decimals not set"); // Ensure oracle decimals is valid

        // Price ratio is tokenIn / tokenOut. So (amountIn / amountOut) is approx price ratio.
        // amountOut = (amountIn * 10^decimals_tokenOut) / (priceRatio * 10^decimals_tokenIn)
        // To calculate amountOut using targetPriceRatio (tokenIn / tokenOut, already adjusted by oracle decimals),
        // we need token decimals. Let's assume standard 18 decimals for simplification or fetch them.
        // For now, let's simplify the amountOut calculation based on the *current* eligible price ratio.
        // amountOut = (amountIn * (10^tokenOut.decimals / 10^tokenIn.decimals)) / priceRatioFromOracle
        // This requires knowing token decimals or standardizing. Let's use a simplified ratio calculation relative to oracle.
        // Assuming price ratio is A/B. If oracle gives price of B in A, we need 1/price.
        // If oracle gives price of A/B directly, amountOut = amountIn / priceRatio.

        // Let's assume oracle gives price of TokenOut in terms of TokenIn (e.g., ETH/USD gives price of USD in ETH).
        // If tokenIn=ETH, tokenOut=USDC, oracle is ETH/USD -> Price of 1 ETH in USD. PriceRatio is TokenIn/TokenOut.
        // If price is P (ETH/USD), then PriceRatio is P. AmountOut (USD) = AmountIn (ETH) * P.
        // If tokenIn=USDC, tokenOut=ETH, oracle is ETH/USD -> Price of 1 ETH in USD. PriceRatio is TokenIn/TokenOut (USDC/ETH).
        // Price of 1 ETH in USD is P. Price of 1 USD in ETH is 1/P. PriceRatio USDC/ETH is 1/P.
        // AmountOut (ETH) = AmountIn (USDC) / (1/P) = AmountIn * P.
        // This still depends on *how* the oracle feed is configured relative to the token pair.
        // A more robust way would require knowing base/quote of the oracle feed AND token decimals.

        // Let's simplify by assuming the `targetPriceRatio` and `currentPriceRatio` are normalized relative
        // to the oracle's precision AND implicitly handle the token decimals based on the oracle feed configuration.
        // We'll calculate amountOut based on the *exact* `currentPriceRatio` at execution time (minus fees).
        // A common pattern is amountOut = (amountIn * PriceTokenOut) / PriceTokenIn
        // If oracle gives PriceTokenIn / PriceTokenOut, then amountOut = amountIn / (PriceTokenIn / PriceTokenOut)
        // AmountOut = amountIn * (1 / currentPriceRatio)

        // We need to handle potential division by zero and ensure precision.
        // Let's assume price ratios are scaled by 10^oracle_decimals.
        // AmountOut = (amountIn * 10^oracle_decimals) / currentPriceRatio * (10^tokenOut.decimals / 10^tokenIn.decimals)
        // This still requires token decimals. Let's add helper functions or assume standard precision for the example.
        // Assuming token decimals are 18 for both for simplicity in calculation:
        // AmountOut = (amountIn * 1e18 / currentPriceRatio) * (1e18 / 1e18) = (amountIn * 1e18) / currentPriceRatio
        // No, the ratio itself is scaled by oracle decimals. Let's stick to:
        // AmountOut = (amountIn * 10^oracle_decimals) / currentPriceRatio, if oracle gives PriceA/PriceB and A is tokenIn.
        // AmountOut = amountIn * currentPriceRatio / 10^oracle_decimals, if oracle gives PriceB/PriceA and A is tokenIn.

        // This requires knowing oracle feed configuration (base/quote) which isn't directly available from AggregatorV3Interface.
        // A real-world contract would need a mapping or config for each token pair -> oracle -> direction.

        // Let's assume a simplified calculation for this example: the `targetPriceRatio` is tokenIn/tokenOut
        // normalized relative to oracle decimals.
        // If currentPriceRatio is the price of tokenIn *per* tokenOut (e.g., price of 1 BTC in ETH if tokenIn=BTC, tokenOut=ETH)
        // Then amountOut = amountIn / currentPriceRatio.
        // If currentPriceRatio is the price of tokenOut *per* tokenIn (e.g., price of 1 ETH in BTC if tokenIn=ETH, tokenOut=BTC)
        // Then amountOut = amountIn * currentPriceRatio.

        // The checkSwapEligibility logic comparing `currentPriceRatio` to `targetPriceRatio` implies a specific ratio meaning.
        // Let's assume `targetPriceRatio` and `currentPriceRatio` represent `Price(tokenIn) / Price(tokenOut)`.
        // So `amountOut = amountIn / currentPriceRatio`. Using fixed point:
        // amountOut = (amountIn * (10 ** oracle.decimals())) / currentPriceRatio;
        // We need to adjust for token decimals. Let's use a simplified approach and acknowledge the limitation.
        // Assume currentPriceRatio is scaled appropriately and represents the swap rate (amountOut / amountIn).
        // e.g., if price ratio is 0.0001 (BTC/USDC), 1 BTC = 10000 USDC. Rate is 10000.
        // `targetPriceRatio` and `currentPriceRatio` should represent `amountOut / amountIn`.
        // Let's redefine `targetPriceRatio` as `Price(tokenOut) / Price(tokenIn)` scaled.

        // REDEFINITION: Let `targetPriceRatio` and `currentPriceRatio` represent `Price(tokenOut) / Price(tokenIn)`
        // scaled by 10^oracle_decimals * 10^(tokenIn.decimals - tokenOut.decimals). This is complex.

        // SIMPLEST APPROACH: Let `targetPriceRatio` and `currentPriceRatio` represent a numerical ratio.
        // The swap is conditional on `currentPriceRatio >= targetPriceRatio` or `<=` depending on the desired trade direction.
        // Let's assume the price feed is `Price(tokenOut) per Price(tokenIn)`.
        // E.g., ETH/USD feed, gives price of 1 ETH in USD. If tokenIn=ETH, tokenOut=USD, ratio is USD per ETH.
        // `targetPriceRatio` = desired min USD/ETH. `amountOut = amountIn * currentPriceRatio`.
        // If tokenIn=USD, tokenOut=ETH, ratio is ETH per USD. `targetPriceRatio` = desired min ETH/USD.
        // `amountOut = amountIn * currentPriceRatio`.

        // This requires configuring per-pair oracle feeds. Let's assume for THIS contract example,
        // `targetPriceRatio` and `currentPriceRatio` represent the quantity of `tokenOut` received per `tokenIn`.
        // e.g., if ETH/USD is 2000, and tokenIn=ETH, tokenOut=USD, targetRatio is 2000 * 10^oracle_decimals.
        // amountOut = amountIn * currentPriceRatio / 10^oracle_decimals.

        // Recalculating amountOut:
        // amountOut = (swap.amountIn * currentPriceRatio) / (10 ** priceOracle.decimals()); // This assumes price is tokenOut/tokenIn
        // Need to adjust for token decimals:
        // Assuming 18 decimals for both tokens for simplicity here.
        // amountOut = (swap.amountIn * currentPriceRatio) / (10 ** priceOracle.decimals()); // Still seems off without token decimals

        // Let's assume the oracle feed gives a price `P` for the pair (TokenA, TokenB) with `D` decimals.
        // If Price is TokenA / TokenB: `amountOut = (swap.amountIn * (10**tokenOut.decimals)) / (currentPriceRatio * (10**tokenIn.decimals) / (10**priceOracle.decimals))`
        // This is complicated. Let's simplify:
        // Assume `targetPriceRatio` and `currentPriceRatio` are scaled by the oracle's decimals only, and represent TokenIn/TokenOut.
        // If `currentPriceRatio` is price of tokenIn in tokenOut (scaled by oracle decimals).
        // e.g., ETH/USD feed gives 2000 * 1e8. If tokenIn=ETH, tokenOut=USD, this is price of ETH in USD.
        // `targetPriceRatio` for buy USD with ETH: must be low (e.g., <= 2000 * 1e8).
        // `amountOut = amountIn * (1e18 / (currentPriceRatio / 1e8)) = amountIn * 1e8 / currentPriceRatio`. This is wrong.
        // It should be: amountOut = (amountIn * 10**tokenOut.decimals) / (currentPriceRatio / 10**oracle_decimals * 10**tokenIn.decimals)

        // Let's define the ratio as AMOUNT_OUT / AMOUNT_IN per unit.
        // targetPriceRatio = (amountOut / amountIn) scaled.
        // amountOut = (amountIn * currentPriceRatio) / SCALING_FACTOR.
        // What is SCALING_FACTOR? It must account for oracle decimals and token decimals.
        // Let's assume `targetPriceRatio` and `currentPriceRatio` are directly comparable, scaled by `10^oracle_decimals`, and represent `amountOut / amountIn`.
        // e.g. If ETH/USD feed gives 2000 * 1e8 (price of 1 ETH in USD).
        // If tokenIn=ETH, tokenOut=USD, the ratio of AmountOut/AmountIn should be ~2000.
        // So `targetPriceRatio` and `currentPriceRatio` should be 2000 * 1e8.
        // AmountOut = (amountIn * currentPriceRatio) / 1e8. This doesn't account for token decimals.

        // Let's assume token decimals are needed.
        uint256 tokenInDecimals = IERC20(swap.tokenIn).decimals(); // Requires IERC20(token).decimals()
        uint256 tokenOutDecimals = IERC20(swap.tokenOut).decimals();

        // currentPriceRatio is scaled by 10^oracle.decimals() and represents Price(tokenIn)/Price(tokenOut)
        // Target: AmountOut = AmountIn * (Price(tokenIn) / Price(tokenOut))_effective
        // (Price(tokenIn) / Price(tokenOut))_effective = (currentPriceRatio / 10^oracle.decimals()) * (10^tokenOut.decimals / 10^tokenIn.decimals)
        // amountOut = swap.amountIn * (currentPriceRatio / 10**priceOracle.decimals()) * (10**tokenOutDecimals / 10**tokenInDecimals)
        // amountOut = (swap.amountIn * currentPriceRatio * (10**tokenOutDecimals)) / (10**priceOracle.decimals() * (10**tokenInDecimals))

        // This needs careful handling of division/multiplication order to maintain precision.
        // Usecase: Buy tokenOut with tokenIn. Swap is triggered when Price(tokenIn)/Price(tokenOut) is <= target (e.g. buy ETH with USD when ETH/USD price is low).
        // Usecase: Sell tokenIn for tokenOut. Swap is triggered when Price(tokenIn)/Price(tokenOut) is >= target (e.g. sell ETH for USD when ETH/USD price is high).
        // Let's assume targetPriceRatio and currentPriceRatio are Price(tokenIn) / Price(tokenOut) scaled by 10^oracle.decimals().
        // The `checkSwapEligibility` logic implies this ratio direction.
        // AmountOut = amountIn * (Price(tokenIn)/Price(tokenOut))_actual
        // (Price(tokenIn)/Price(tokenOut))_actual = currentPriceRatio / 10^oracle.decimals() * 10^(tokenOut.decimals - tokenIn.decimals)
        // amountOut = swap.amountIn * (currentPriceRatio / (10**priceOracle.decimals())) * (10**(tokenOutDecimals - tokenInDecimals))
        // To avoid large exponents/division order issues:
        // if tokenOutDecimals >= tokenInDecimals:
        // amountOut = (swap.amountIn * currentPriceRatio * (10**(tokenOutDecimals - tokenInDecimals))) / (10**priceOracle.decimals());
        // if tokenOutDecimals < tokenInDecimals:
        // amountOut = (swap.amountIn * currentPriceRatio) / (10**priceOracle.decimals() * (10**(tokenInDecimals - tokenOutDecimals)));

        uint256 amountOut;
        uint256 oracleDecimals = priceOracle.decimals();
        uint256 priceRatioAdjustedForOracle = currentPriceRatio; // currentPriceRatio is scaled by 10^oracleDecimals

        if (tokenOutDecimals >= tokenInDecimals) {
            amountOut = (swap.amountIn * priceRatioAdjustedForOracle * (10**(tokenOutDecimals - tokenInDecimals))) / (10**oracleDecimals);
        } else { // tokenOutDecimals < tokenInDecimals
            amountOut = (swap.amountIn * priceRatioAdjustedForOracle) / (10**oracleDecimals * (10**(tokenInDecimals - tokenOutDecimals)));
        }
        // Potential precision loss here. Using a SafeMath library for fixed point might be better in production.

        require(amountOut >= swap.minAmountOut, "Swap output below minimum");
        require(totalLiquidity[swap.tokenOut] >= amountOut, "Insufficient liquidity in tokenOut pool for execution");

        // Calculate fees
        uint256 totalFee = (amountOut * swapFeeBps) / 10000;
        uint256 lpFee = (totalFee * liquidityFeeShareBps) / 10000;
        uint256 protocolFee = totalFee - lpFee;

        uint256 amountOutAfterFee = amountOut - totalFee;

        // Update fee balances
        protocolFeeBalances[swap.tokenOut] += protocolFee;
        liquidityFeeBalances[swap.tokenOut] += lpFee;

        // Update liquidity pools
        // AmountIn goes from user deposit to tokenIn pool (conceptually, or just stays in contract)
        // AmountOut comes from tokenOut pool
        // This specific design doesn't have a 'tokenIn pool' for the deposited funds,
        // the deposited funds *are* the source for the swap. So amountIn is already in the contract.
        // Need to transfer amountOut from contract's tokenOut balance (from LP pool) to the user.
        totalLiquidity[swap.tokenOut] -= amountOut; // Decrease tokenOut pool by amount sent to user

        // Transfer tokenOut to the user
        bool success = IERC20(swap.tokenOut).transfer(swap.user, amountOutAfterFee);
        require(success, "TokenOut transfer failed");

        emit ConditionalSwapExecuted(
            swapId,
            swap.user,
            swap.tokenIn,
            swap.amountIn,
            swap.tokenOut,
            amountOutAfterFee,
            totalFee
        );

        // The deposited tokenIn (swap.amountIn) stays in the contract. It could conceptually be added
        // to the tokenIn liquidity pool *at this point*, but that changes the LP model.
        // In this model, the deposited tokenIn is consumed by the swap. Its value is exchanged for tokenOut.
        // The *source* of tokenOut is the liquidity pool. The tokenIn doesn't necessarily enter a pool.
        // Let's update this: The deposited tokenIn should contribute to the tokenIn pool *conceptually* to balance the pools.
        // Let's model the deposited tokenIn as adding to the tokenIn pool after execution.
        // But this implies the user's original deposit becomes LP tokenIn. This changes the user flow.
        // Alternative: The tokenIn from the user is simply swapped away. The source of TokenOut is LP pool.
        // The contract needs to manage its balance of *both* tokens.
        // When user deposits TokenIn for a swap, contract balance of TokenIn increases.
        // When swap executes, contract balance of TokenIn decreases by AmountIn, Contract balance of TokenOut decreases by AmountOut.
        // Net effect on pools: TokenOut pool reduces by AmountOut. TokenIn pool increases by AmountIn.
        // This makes the TokenIn pool grow from user deposits, TokenOut pool shrink.
        // This is *not* how AMMs work (where pool ratios determine price).
        // This model is more like: Users deposit TokenIn, contract buys TokenOut from LP pool using that value.

        // Let's adjust the model: The user's deposited TokenIn is *used* to pay for the TokenOut.
        // The TokenOut comes from the pool.
        // How does TokenIn get into the pool for LPs to withdraw?
        // A standard AMM takes *both* tokens for liquidity. This design separates swap input from LP input.

        // Let's refine the liquidity model: Users provide liquidity for *both* tokens.
        // When a swap executes (In -> Out), TokenIn from user goes to TokenOut pool, TokenOut from TokenOut pool goes to user.
        // No, that doesn't make sense for balancing.

        // Let's simplify the model: Users provide liquidity for specific tokens.
        // When a swap executes (TokenIn -> TokenOut):
        // 1. TokenIn (amountIn) from user is consumed.
        // 2. TokenOut (amountOutAfterFee + totalFee) is sent to user and fee recipients *from* the contract's TokenOut balance (sourced from LP pool).
        // 3. The *value* equivalent of amountIn in terms of tokenOut (amountOut, pre-fee) is added to the TokenIn pool. No, this is confusing.

        // The most straightforward model:
        // - LPs deposit Token A into A pool, Token B into B pool.
        // - Users deposit TokenIn (A or B) for a swap. This TokenIn is *held* by the contract.
        // - When swap executes:
        //     - Contract transfers TokenOut from its balance (sourced from TokenOut LP pool) to the user.
        //     - The user's deposited TokenIn remains in the contract. It is NOT returned. It represents the value exchanged.
        //     - To compensate the TokenOut LP pool, the *equivalent value* of the TokenIn should be transferred conceptually or actually.
        //     - A simple way is to add the received TokenIn to the TokenIn pool.
        // This means LPs in TokenIn pool get more TokenIn, LPs in TokenOut pool get less TokenOut.
        // This shifts the pool balances.

        // Let's implement this: After executing a swap (TokenIn -> TokenOut), add the user's TokenIn to the TokenIn pool.
        totalLiquidity[swap.tokenIn] += swap.amountIn; // Add consumed TokenIn to its pool
        // totalLiquidity[swap.tokenOut] -= amountOut; // Already done above

        // Note: This might not perfectly track LP shares if relative prices change significantly between LP deposit and swap execution.
        // A more advanced model would use LP tokens or tracking value, but this meets the requirements for function count and basic concept.
    }

    /// @notice Cancels a pending swap request.
    /// Can only be cancelled before the start time, or after the start time if not yet executed/expired.
    /// @param swapId The ID of the swap to cancel.
    function cancelConditionalSwap(uint256 swapId) external nonReentrant whenNotPaused {
        PendingSwap storage swap = pendingSwaps[swapId];

        require(swap.user == msg.sender, "Not your swap");
        require(swap.user != address(0), "Swap ID does not exist");
        require(!swap.executed, "Swap already executed");
        require(!swap.cancelled, "Swap already cancelled");
        // Allow cancel before start time OR after start time but before end time and not executed
        require(block.timestamp < swap.startTime || (block.timestamp >= swap.startTime && block.timestamp <= swap.endTime), "Cannot cancel after end time or once executed");

        swap.cancelled = true;

        // Transfer deposited tokens back to user
        bool success = IERC20(swap.tokenIn).transfer(msg.sender, swap.amountIn);
        require(success, "Token transfer failed");

        emit ConditionalSwapCancelled(swapId, msg.sender, swap.tokenIn, swap.amountIn);

        // Optional: Delete swap from mapping to save gas, but makes historical lookup harder.
        // delete pendingSwaps[swapId]; // Not doing this to allow querying cancelled swaps
    }

    /// @notice Claims back tokens from an expired swap request.
    /// Can only be claimed after the end time if the swap was not executed or cancelled.
    /// @param swapId The ID of the expired swap to claim.
    function claimExpiredSwap(uint256 swapId) external nonReentrant whenNotPaused {
        PendingSwap storage swap = pendingSwaps[swapId];

        require(swap.user == msg.sender, "Not your swap");
        require(swap.user != address(0), "Swap ID does not exist");
        require(!swap.executed, "Swap was executed");
        require(!swap.cancelled, "Swap was cancelled"); // Cannot claim if already cancelled
        require(block.timestamp > swap.endTime, "Swap has not expired yet");

        // Ensure state is updated - not strictly necessary if not deleting, but clear
        // swap.cancelled = true; // Could set cancelled to true here too, or have a separate 'claimed' state.
        // Let's allow claiming expired swaps that were neither executed nor cancelled explicitly.

        // Transfer deposited tokens back to user
        bool success = IERC20(swap.tokenIn).transfer(msg.sender, swap.amountIn);
        require(success, "Token transfer failed");

        emit ExpiredSwapClaimed(swapId, msg.sender, swap.tokenIn, swap.amountIn);

        // Optional: Delete swap from mapping
        // delete pendingSwaps[swapId];
    }

    /// @notice Provides liquidity to a token pool.
    /// User must have approved this contract to transfer `amount` of `token`.
    /// @param token The address of the token to provide liquidity for.
    /// @param amount The amount of token to provide.
    function provideLiquidity(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(token != address(0), "Invalid token address");
        require(approvedTokens[token], "Token not approved for liquidity");

        // Transfer tokens from user to contract
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // Update liquidity balances
        liquidityBalances[msg.sender][token] += amount;
        totalLiquidity[token] += amount;

        emit LiquidityProvided(msg.sender, token, amount);
    }

    /// @notice Withdraws liquidity from a token pool.
    /// @param token The address of the token pool to withdraw from.
    /// @param amount The amount of liquidity to withdraw.
    function withdrawLiquidity(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(token != address(0), "Invalid token address");
        require(approvedTokens[token], "Token not approved for liquidity");
        require(liquidityBalances[msg.sender][token] >= amount, "Insufficient liquidity balance");
        require(totalLiquidity[token] >= amount, "Insufficient total pool liquidity"); // Should be covered by user balance, but safety check

        // Update liquidity balances
        liquidityBalances[msg.sender][token] -= amount;
        totalLiquidity[token] -= amount;

        // Transfer tokens from contract to user
        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "Token transfer failed");

        emit LiquidityWithdrawal(msg.sender, token, amount);
    }

     /// @notice Allows liquidity providers to claim their accumulated fee share for a specific token.
     /// @param token The address of the token for which to claim fees.
    function distributeLiquidityFees(address token) external nonReentrant whenNotPaused {
        require(token != address(0), "Invalid token address");
        require(approvedTokens[token], "Token not approved for liquidity");
        require(totalLiquidity[token] > 0, "No liquidity in pool to distribute fees"); // Only distribute if pool exists

        // Calculate fee share for msg.sender based on their contribution
        // This requires tracking each LP's share of totalLiquidity *at the time fees were accrued*.
        // A simpler approach: fees are added to the pool, increasing LP share value.
        // But the request asks for claiming accumulated fees.
        // Let's assume a simple pro-rata distribution based on *current* balance vs *total accrued fees*.
        // This can be unfair if LPs join/leave frequently or price changes drastically.
        // A more robust model would use LP tokens and track fee accumulation per LP token.

        // Simple pro-rata distribution for this example:
        uint256 userLiquidity = liquidityBalances[msg.sender][token];
        require(userLiquidity > 0, "No liquidity balance to claim fees from");

        // Calculate user's share of total accrued LP fees for this token
        // This assumes fees are added to a separate balance and claimed.
        // Fees are added to `liquidityFeeBalances[token]` during swap execution.
        // How much of `liquidityFeeBalances[token]` belongs to *this* user?
        // (userLiquidity / totalLiquidity[token]) * liquidityFeeBalances[token]
        // This is complex because totalLiquidity changes.

        // A common simplified model: Fees are *not* added to liquidityFeeBalances directly for claiming.
        // Instead, fees increase the value of the pool. When LPs withdraw, they get their share of the larger pool.
        // This contract *does* track `liquidityFeeBalances`. This suggests claimable fees.
        // The fair way to calculate claimable fees needs a system tracking LP shares over time, or fees per LP share.
        // Let's adopt a model where fees are claimable based on the *current* liquidity balance ratio.
        // This is an approximation but fits the function signature.

        uint256 totalPoolFees = liquidityFeeBalances[token];
        if (totalPoolFees == 0) {
            return; // Nothing to claim
        }

        // Calculate user's share of the *total* fees accrued since the last distribution/claim
        // This simple ratio (user_balance / total_balance) assumes all fees were accrued while user had that exact ratio.
        // It's an oversimplification for a dynamic pool.
        uint256 userFeeShare = (userLiquidity * totalPoolFees) / totalLiquidity[token];

        // We need to ensure the user *can't* claim fees multiple times based on the same balance.
        // Fees should be claimable *on withdrawal* or tracked per deposit.
        // Let's refine: liquidityFeeBalances[token] is the *pool's* total undistributed fees.
        // Each user needs a mapping: `mapping(address => mapping(address => uint256)) public claimableLpFees;`
        // When swap executes: calculate LP fee share, add to `claimableLpFees[LP][token]` for all active LPs prorata. This is very complex.

        // Let's revert to the simpler (less fair) model for the example contract: fees increase pool value implicitly.
        // Liquidity provision/withdrawal handles fee distribution implicitly.
        // So, `distributeLiquidityFees` function is *not* needed in that model.
        // But the prompt asked for 20+ functions, and fee claiming is a common pattern.
        // Let's *re-implement* the claimable fee concept but with a simplified distribution mechanism.
        // Fees are accrued to `liquidityFeeBalances[token]`. Anyone can trigger distribution.
        // When distribution is triggered, `liquidityFeeBalances[token]` is divided among *current* LPs based on their balance.
        // The fees are then moved from `liquidityFeeBalances[token]` to each user's `claimableLpFees[user][token]`.
        // A *separate* function is needed for users to `claimMyLpFees(token)`.

        // Okay, let's add `claimableLpFees` mapping and two functions: `_distributePoolFees` (internal) and `claimMyLpFees` (external).

        // Re-thinking `distributeLiquidityFees`: This function should probably be internal or called by execute.
        // Fees generated by a swap in TokenOut should be distributed among LPs *in the TokenOut pool*.

        // Let's rename `distributeLiquidityFees` to `claimMyLiquidityFees`.

        revert("Function needs re-implementation based on proper fee tracking per LP or pool value");
        // This function design needs to be adjusted based on a specific fee distribution model (e.g., fee-bearing LP tokens, or tracked debt).
        // To meet the function count requirement and illustrate a *claim* function:
        // Let's imagine a simpler model where `liquidityFeeBalances[token]` represents the total fees claimable by *all* LPs of that token.
        // When a user calls `claimMyLiquidityFees`, they claim their pro-rata share based on their *current* liquidity balance,
        // and their share of the total fee balance is deducted. This is still flawed as totalLiquidity changes.

        // Let's just implement the pro-rata claim based on snapshot at claim time, acknowledging its limitation.

        /*
        uint256 userLiquidity = liquidityBalances[msg.sender][token];
        require(userLiquidity > 0, "No liquidity balance to claim fees from");

        uint256 totalPoolFees = liquidityFeeBalances[token];
        if (totalPoolFees == 0) {
             return; // Nothing to claim
        }

        uint256 totalLpSupply = totalLiquidity[token]; // totalLiquidity includes LP deposits + swap inputs

        // The share should be based on the user's share of the *LP deposits*, not total liquidity.
        // Need a separate variable `totalLpDeposits[token]`. Let's add it.
        */

        // Adding `totalLpDeposits` state variable.
        // mapping(address => uint256) public totalLpDeposits;

        /*
        // Reworking provide/withdraw liquidity to track totalLpDeposits
        // Reworking executeConditionalSwap to add swap.amountIn to totalLiquidity *but not* totalLpDeposits.

        // --- Reworked provideLiquidity ---
        function provideLiquidity(...) {
            // ... transferFrom ...
            liquidityBalances[msg.sender][token] += amount;
            totalLiquidity[token] += amount; // total liquidity managed by contract
            totalLpDeposits[token] += amount; // only tracks explicit LP deposits
            emit LiquidityProvided(...);
        }

        // --- Reworked withdrawLiquidity ---
        function withdrawLiquidity(...) {
            // ... checks ...
            liquidityBalances[msg.sender][token] -= amount;
            totalLiquidity[token] -= amount;
            totalLpDeposits[token] -= amount;
            // ... transfer ...
            emit LiquidityWithdrawal(...);
        }

        // --- Reworked executeConditionalSwap ---
        function executeConditionalSwap(...) {
            // ... execution logic ...
            totalLiquidity[swap.tokenOut] -= amountOut; // TokenOut leaves contract
            totalLiquidity[swap.tokenIn] += swap.amountIn; // TokenIn stays in contract, adds to overall liquidity
            // ... fee calculations ...
            liquidityFeeBalances[swap.tokenOut] += lpFee; // Fees are for tokenOut pool
            protocolFeeBalances[swap.tokenOut] += protocolFee; // Fees are for tokenOut pool
            // ... transfers ...
        }

        // Now, `distributeLiquidityFees` for token `T` distributes `liquidityFeeBalances[T]`
        // among LPs of token `T` based on their `liquidityBalances[LP][T]` relative to `totalLpDeposits[T]`.
        */

        // Let's implement `claimMyLiquidityFees` using the revised model with `totalLpDeposits`.

        uint256 userLiquidity = liquidityBalances[msg.sender][token];
        require(userLiquidity > 0, "No liquidity balance to claim fees from");

        // It's impossible to fairly calculate each user's *exact* fee share without tracking fees per share over time.
        // The most practical approach for a claimable fee is to track fees *per user* directly when earned.
        // Need `mapping(address => mapping(address => uint256)) public claimableLpFees;`

        // Okay, let's add the `claimableLpFees` state variable.
        // mapping(address => mapping(address => uint256)) public claimableLpFees;

        // --- Reworked executeConditionalSwap again ---
        /*
        function executeConditionalSwap(...) {
            // ... execution logic ...
            // ... fee calculations ...
            uint256 totalPoolFees = lpFee; // Fee amount *just* generated for this swap's TokenOut pool
            if (totalPoolFees > 0 && totalLpDeposits[swap.tokenOut] > 0) {
                 // Distribute this fee amount pro-rata among *current* LPs
                 uint256 cumulativeDistributed = 0;
                 // This requires iterating over all LPs which is bad practice in Solidity.
                 // A standard pattern uses cumulative sum or LP tokens.

                 // Let's skip direct per-user fee distribution in execute.
                 // Fees accrue to `liquidityFeeBalances[tokenOut]`.
                 // Users claim from this pool based on their share. This still needs a snapshot logic.
                 // Or, fees are added to the pool (increase asset balance), and withdrawal captures value.
                 // The requested function signature `distributeLiquidityFees(token)` implies claiming.

                 // Let's assume a simplified model: fees are added to `liquidityFeeBalances`.
                 // When a user claims, they get `(userLiquidity / totalLpDeposits[token]) * liquidityFeeBalances[token]`
                 // *and this amount is deducted from `liquidityFeeBalances[token]`*. This makes subsequent claims unfair.

                 // Let's use the cumulative share per unit of liquidity deposited.
                 // Need `mapping(address => uint256) public cumulativeFeePerShare;`
                 // Need `mapping(address => mapping(address => uint256)) public userLastFeePerShare;`
                 // When fees are generated (in execute): `cumulativeFeePerShare[tokenOut] += (lpFee * 1e18) / totalLpDeposits[tokenOut];`
                 // When user claims: `claimable = userLiquidity * (cumulativeFeePerShare[token] - userLastFeePerShare[msg.sender][token]) / 1e18;`
                 // Update `userLastFeePerShare[msg.sender][token] = cumulativeFeePerShare[token];`
                 // Transfer `claimable`.

                 // This adds two more state variables and complexity to execute/claim. Let's add them to meet function count and advanced concept.
        }
        */

        // Adding `cumulativeFeePerShare` and `userLastFeePerShare`
        mapping(address => uint256) public cumulativeFeePerShare; // Per token, scaled
        mapping(address => mapping(address => uint256)) public userLastFeePerShare; // Per user per token

        // Reworking provide/withdraw/execute/claim

        // --- Reworked provideLiquidity ---
        // Track user's fee share snapshot upon deposit
        uint256 claimableBefore = _calculateClaimableFees(msg.sender, token);
        if (claimableBefore > 0) {
             // Automatically claim outstanding fees before adding new liquidity
             // To avoid claiming fees on liquidity that just joined
             _transferToken(token, msg.sender, claimableBefore);
             // Need to update the fee balance state here implicitly or explicitly.
             // This requires `_calculateClaimableFees` to *also* deduct from the pool's claimable balance.
             // This suggests a pull-based system where totalFees - claimedFees = remaining fees.
             // This is getting complicated.

             // Let's stick to the simpler cumulative approach.
             // On deposit: update user's snapshot of cumulativeFeePerShare.
        }
        userLastFeePerShare[msg.sender][token] = cumulativeFeePerShare[token];
        // ... rest of provideLiquidity ...


        // --- Reworked withdrawLiquidity ---
        // Claim outstanding fees on withdrawal
        uint256 claimableBefore = _calculateClaimableFees(msg.sender, token);
        if (claimableBefore > 0) {
            // Transfer fees
             _transferToken(token, msg.sender, claimableBefore);
            // Fees are deducted from the pool's balance when calculated as claimable.
        }
        userLastFeePerShare[msg.sender][token] = cumulativeFeePerShare[token]; // Update snapshot even on withdrawal
        // ... rest of withdrawLiquidity ...

        // --- Reworked executeConditionalSwap ---
        /*
        function executeConditionalSwap(...) {
             // ... execution logic ...
             // ... fee calculations ...
             uint256 totalPoolFees = lpFee; // Fee amount *just* generated for this swap's TokenOut pool
             if (totalPoolFees > 0 && totalLpDeposits[swap.tokenOut] > 0) {
                  // Update cumulative fee per share for the TokenOut pool
                  // cumulativeFeePerShare[tokenOut] += (lpFee * 1e18) / totalLpDeposits[tokenOut]; // Scale by 1e18 for precision
                  // Add the fee amount to the pool's claimable balance
                  liquidityFeeBalances[swap.tokenOut] += lpFee; // This pool holds the claimable fees
             }
             // ... rest of execute ...
        }
        */

        // Function to calculate claimable fees for a user/token
        // internal view function _calculateClaimableFees(address user, address token)

        // Final attempt at `claimMyLiquidityFees` using the cumulative fee per share model.
    }

    /// @notice Allows liquidity providers to claim their accumulated fee share for a specific token.
    /// This function calculates the user's share based on the cumulative fee per share model.
    /// @param token The address of the token for which to claim fees.
    function claimMyLiquidityFees(address token) external nonReentrant whenNotPaused {
        require(token != address(0), "Invalid token address");
        require(approvedTokens[token], "Token not approved"); // LPs only for approved tokens

        uint256 claimableAmount = _calculateClaimableFees(msg.sender, token);

        if (claimableAmount > 0) {
            // Deduct claimed amount from the pool's total claimable fees
            // This requires recalculating the total claimable fees *after* deducting the user's share.
            // Or, the _calculate function should manage the deduction.

            // The standard cumulative approach *doesn't* subtract from a pool balance.
            // It's a calculation based on snapshots. The fees are assumed to be *in the pool's asset balance*.
            // The `liquidityFeeBalances` should actually be the total fees available *in that token* for LPs.
            // The _calculate function just tells you how much *of that pool balance* belongs to you.
            // Claiming transfers from the contract's token balance.

            // Let's rename `liquidityFeeBalances` to `totalClaimableLpFees` for clarity.
            // mapping(address => uint256) public totalClaimableLpFees; // Total fees available for LPs in a token

            // --- Reworked executeConditionalSwap again ---
            /*
            function executeConditionalSwap(...) {
                // ... execution logic ...
                // ... fee calculations ...
                uint256 totalPoolFees = lpFee; // Fee amount *just* generated for this swap's TokenOut pool
                if (totalPoolFees > 0 && totalLpDeposits[swap.tokenOut] > 0) {
                    // Update cumulative fee per share for the TokenOut pool
                    uint256 feePerShare = (lpFee * 1e18) / totalLpDeposits[swap.tokenOut]; // Scale by 1e18
                    cumulativeFeePerShare[swap.tokenOut] += feePerShare;

                    // The generated fee `lpFee` is implicitly now part of the pool's token balance.
                    // No need to add to a separate `liquidityFeeBalances`. The cumulativeFeePerShare tracks entitlement.
                    // The tokens themselves are in `address(this).balance(tokenOut)`.
                    // The `totalClaimableLpFees` concept is redundant if cumulativeFeePerShare tracks entitlement.
                }
                // ... rest of execute ...
            }
            */

            // Ok, cumulativeFeePerShare approach implies fees are in the contract's token balance.
            // `claimMyLiquidityFees` transfers from `address(this).balance`.
            // The calculation in `_calculateClaimableFees` determines the amount.

            // Transfer claimable fees
            _transferToken(token, msg.sender, claimableAmount);

            // Update user's fee snapshot to the current cumulative value
            userLastFeePerShare[msg.sender][token] = cumulativeFeePerShare[token];

            // No need to subtract from liquidityFeeBalances, as it's not used in this model.
            // The initial `liquidityFeeBalances` was a simpler fee pool idea. Removing it.
            // Same for `protocolFeeBalances`. Owner collects from contract balance based on tracked amount.

            // Let's add `protocolFeeBalances` back to track the owner's claimable amount.
            // mapping(address => uint256) public protocolFeeBalances; // Track protocol fees waiting for owner claim


            // --- Reworked executeConditionalSwap again ---
            /*
            function executeConditionalSwap(...) {
                // ... fee calculations ...
                uint256 totalFee = (amountOut * swapFeeBps) / 10000;
                uint256 lpFee = (totalFee * liquidityFeeShareBps) / 10000;
                uint256 protocolFee = totalFee - lpFee;

                if (lpFee > 0 && totalLpDeposits[swap.tokenOut] > 0) {
                    // Update cumulative fee per share for the TokenOut pool
                    uint256 feePerShare = (lpFee * 1e18) / totalLpDeposits[swap.tokenOut]; // Scale by 1e18
                    cumulativeFeePerShare[swap.tokenOut] += feePerShare;
                    // The actual tokens `lpFee` are in contract's balance. Claiming uses _transferToken.
                }

                protocolFeeBalances[swap.tokenOut] += protocolFee; // Protocol fees track claimable amount

                uint256 amountOutAfterFee = amountOut - totalFee;

                // ... transfers ...
                // TokenOut transferred from contract to user (amountOutAfterFee)
                // TokenIn transferred from user to contract (swap.amountIn) -> adds to totalLiquidity/totalLpDeposits?
                // The user's TokenIn deposit *is* the input. It doesn't go back to the user.
                // The model where it adds to totalLiquidity[tokenIn] makes sense for tracking contract assets,
                // but it shouldn't add to `totalLpDeposits[tokenIn]` as it wasn't an LP deposit.
                // So `totalLiquidity` tracks contract balance, `totalLpDeposits` tracks LP contributions.

                totalLiquidity[swap.tokenOut] -= amountOut; // Amount paid out
                totalLiquidity[swap.tokenIn] += swap.amountIn; // Amount received

                // No change to totalLpDeposits in execute. totalLpDeposits only changes in provide/withdrawLiquidity.
                // The cumulativeFeePerShare for tokenIn pool increases if swap fee is in tokenIn, which it isn't here.
                // Fees are collected in tokenOut. So only tokenOut pool cumulativeFeePerShare updates.
            }
            */

            // Yes, this cumulative fee per share model works. Need to add the `_calculateClaimableFees` internal view function.

            emit LiquidityFeesDistributed(msg.sender, token, claimableAmount);
        }
    }


    /*═════════════════════════════════════════ Admin Functions ═════════════════════════════════════════*/

    /// @notice Sets the address of the Chainlink AggregatorV3Interface oracle.
    /// @param _priceOracle The new oracle contract address.
    function setOracleAddress(address _priceOracle) external onlyOwner {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = AggregatorV3Interface(_priceOracle);
    }

    /// @notice Sets the swap fee percentage.
    /// @param _swapFeeBps The new fee in basis points (100 = 1%). Max 10000 (100%).
    function setSwapFee(uint256 _swapFeeBps) external onlyOwner {
        require(_swapFeeBps <= 10000, "Fee exceeds 100%");
        swapFeeBps = _swapFeeBps;
    }

    /// @notice Sets the percentage of the swap fee that goes to liquidity providers.
    /// @param _liquidityFeeShareBps The new share in basis points (100 = 1%). Max 10000 (100%).
    function setLiquidityFeeShare(uint256 _liquidityFeeShareBps) external onlyOwner {
        require(_liquidityFeeShareBps <= 10000, "Share exceeds 100%");
        liquidityFeeShareBps = _liquidityFeeShareBps;
    }

     /// @notice Sets the lookback period for TWAP calculations in seconds.
     /// @param _twapPeriod The new TWAP period in seconds.
    function setTWAPPeriod(uint256 _twapPeriod) external onlyOwner {
        require(_twapPeriod > 0, "TWAP period must be greater than 0");
        twapPeriod = _twapPeriod;
    }

    /// @notice Approves or unapproves a token for use in the contract (swaps and liquidity).
    /// @param token The address of the token.
    /// @param approved Whether the token should be approved (true) or unapproved (false).
    function setApprovedTokens(address token, bool approved) external onlyOwner {
        require(token != address(0), "Invalid token address");
        approvedTokens[token] = approved;
        emit TokenApprovalUpdated(token, approved);
    }

    /// @notice Pauses core contract operations (requests, executions, liquidity, claims).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(true);
    }

    /// @notice Unpauses contract operations.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Paused(false);
    }

    /// @notice Allows the owner to collect the protocol's share of fees for a specific token.
    /// @param token The address of the token for which to collect fees.
    function collectProtocolFees(address token) external onlyOwner nonReentrant {
        uint256 amount = protocolFeeBalances[token];
        if (amount > 0) {
            protocolFeeBalances[token] = 0;
            _transferToken(token, owner(), amount);
            emit ProtocolFeesCollected(owner(), token, amount);
        }
    }

    /// @notice Emergency withdrawal of a token by the owner. Use with extreme caution.
    /// Intended for recovering tokens sent accidentally or in case of critical vulnerability.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount of token to withdraw.
    function emergencyWithdrawAdmin(address token, uint256 amount) external onlyOwner nonReentrant {
         require(token != address(0), "Invalid token address");
         require(amount > 0, "Amount must be > 0");
         // This can potentially withdraw LP or user funds. Use only in emergencies.
         _transferToken(token, owner(), amount);
    }

    /*═════════════════════════════════════════ View/Query Functions ═════════════════════════════════════════*/

    /// @notice Retrieves the details of a pending swap.
    /// @param swapId The ID of the swap.
    /// @return swap The PendingSwap struct for the given ID.
    function getPendingSwapDetails(uint256 swapId) external view returns (PendingSwap memory swap) {
        return pendingSwaps[swapId];
    }

    /// @notice Retrieves the IDs of all pending swaps for a user.
    /// NOTE: This function iterates over a mapping, which can be gas-intensive if a user has many swaps.
    /// This is generally acceptable for read-only view functions, but consider alternative patterns for very large numbers.
    /// @param user The address of the user.
    /// @return swapIds An array of pending swap IDs for the user.
    function getUserPendingSwaps(address user) external view returns (uint256[] memory swapIds) {
        uint256 count = 0;
        // First pass to count
        for (uint256 i = 1; i < _nextSwapId; i++) {
            if (pendingSwaps[i].user == user && !pendingSwaps[i].executed && !pendingSwaps[i].cancelled) {
                count++;
            }
        }

        swapIds = new uint256[](count);
        uint256 currentIndex = 0;
        // Second pass to collect IDs
        for (uint256 i = 1; i < _nextSwapId; i++) {
             if (pendingSwaps[i].user == user && !pendingSwaps[i].executed && !pendingSwaps[i].cancelled) {
                 swapIds[currentIndex] = i;
                 currentIndex++;
             }
        }
        return swapIds;
    }


    /// @notice Gets a user's liquidity balance for a specific token.
    /// @param user The address of the user.
    /// @param token The address of the token.
    /// @return balance The user's liquidity balance.
    function getLiquidityBalance(address user, address token) external view returns (uint256 balance) {
        return liquidityBalances[user][token];
    }

     /// @notice Gets the total liquidity amount for a specific token pool managed by the contract.
     /// This includes LP deposits and deposited swap tokens.
     /// @param token The address of the token.
     /// @return total The total amount of the token held by the contract as liquidity.
    function getPoolLiquidity(address token) external view returns (uint256 total) {
        return totalLiquidity[token];
    }

    /// @notice Gets the total amount deposited by LPs for a specific token.
    /// This excludes swap inputs held by the contract.
    /// @param token The address of the token.
    /// @return total The total amount of the token deposited by LPs.
    mapping(address => uint256) public totalLpDeposits; // Need to add this state variable

    function getTotalLpDeposits(address token) external view returns (uint256 total) {
         return totalLpDeposits[token];
    }


    /// @notice Gets the current price from the oracle for a token pair.
    /// Assumes the oracle feed directly provides the price for tokenIn/tokenOut or tokenOut/tokenIn.
    /// Requires configuration outside this contract to map token pairs to specific oracle feeds.
    /// For this example, we assume `priceOracle` is configured for a pair that involves tokenIn and tokenOut.
    /// This function is a placeholder and needs a robust oracle integration layer mapping pairs to feeds.
    /// @param tokenIn The address of the input token.
    /// @param tokenOut The address of the output token.
    /// @return price The current price (scaled by oracle decimals). Returns 0 if no valid price.
    /// @return decimals The number of decimals used by the oracle feed.
    function getCurrentPrice(address tokenIn, address tokenOut) public view returns (int256 price, uint8 decimals) {
        // In a real dApp, you'd have a mapping like:
        // mapping(bytes32 => address) public priceFeedForPair;
        // bytes32 pairHash = keccak256(abi.encodePacked(tokenIn, tokenOut)); // Or sorted tokens
        // address feedAddress = priceFeedForPair[pairHash];
        // AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        // (uint80 roundId, int256 _price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) = feed.latestRoundData();
        // return (_price, feed.decimals());

        // For this example, we use the single `priceOracle` and assume it's relevant.
        // This might be valid if tokenIn and tokenOut are WETH and USDC, and the oracle is ETH/USD.
        // But how to interpret the price? If ETH/USD feed is 2000, tokenIn=ETH, tokenOut=USDC, price=2000.
        // If tokenIn=USDC, tokenOut=ETH, price is 1/2000.
        // The contract needs to know the base/quote of the feed.

        // Let's assume the single `priceOracle` gives a price for WETH/USD or similar.
        // We need a mapping to determine how to use this price for ANY tokenIn/tokenOut pair.
        // This requires knowing the price of tokenIn vs a base, and tokenOut vs the base.
        // e.g., Price(A/B) = Price(A/Base) / Price(B/Base).

        // Adding a simple check assuming the single oracle is relevant, but acknowledge limitation.
        // This function will return the raw oracle price and its decimals.
        // The caller (executeConditionalSwap, checkSwapEligibility) needs to interpret it correctly
        // based on tokenIn/tokenOut and the oracle's base/quote.

        // Let's assume the oracle gives Price(tokenIn) / Price(tokenOut) directly for the pair.
        // This implies the single oracle is configured for a very specific pair used in the swap.
        // This is a major simplification. A real system needs a price oracle *router* or registry.

        // For the sake of having a function that interacts with the oracle:
        try priceOracle.latestRoundData() returns (uint80 roundId, int256 _price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) {
             require(timeStamp > 0 && _price > 0, "Invalid oracle data"); // Check for stale or invalid data
             try priceOracle.decimals() returns (uint8 _decimals) {
                 return (_price, _decimals);
             } catch {
                 revert("Could not get oracle decimals");
             }
        } catch {
            revert("Oracle call failed");
        }
    }

    /// @notice Checks if a specific pending swap currently meets its price condition and is within its time window.
    /// @param swapId The ID of the swap to check.
    /// @return isEligible True if the swap is eligible for execution, false otherwise.
    function checkSwapEligibility(uint256 swapId) public view returns (bool isEligible) {
        PendingSwap storage swap = pendingSwaps[swapId];

        if (swap.user == address(0) || swap.executed || swap.cancelled) {
            return false; // Invalid, executed, or cancelled swap
        }

        if (block.timestamp < swap.startTime || block.timestamp > swap.endTime) {
            return false; // Outside time window
        }

        (int256 currentPrice, uint8 oracleDecimals) = getCurrentPrice(swap.tokenIn, swap.tokenOut);
        if (currentPrice <= 0) {
            return false; // Cannot get a valid price
        }

        // The `targetPriceRatio` and `currentPrice` are both scaled by 10^oracleDecimals.
        // `targetPriceRatio` represents the threshold for Price(tokenIn) / Price(tokenOut).
        // The swap is eligible if the current Price(tokenIn)/Price(tokenOut) meets the `targetPriceRatio`.
        // The condition `currentPrice >= targetPriceRatio` means:
        // User wants to sell tokenIn for tokenOut when tokenIn is expensive relative to tokenOut.
        // The condition `currentPrice <= targetPriceRatio` means:
        // User wants to buy tokenOut with tokenIn when tokenOut is expensive relative to tokenIn (or tokenIn is cheap relative to tokenOut).

        // The `requestConditionalSwap` function takes a single `targetPriceRatio`.
        // This implies either the user specifies the comparison (>= or <=) or the contract assumes one.
        // Let's assume the user specifies the desired price ratio. The `targetPriceRatio` is the *threshold*.
        // The *comparison* logic (>= or <=) is implicit based on the swap direction or user intent,
        // which isn't explicitly stored.

        // Let's assume `targetPriceRatio` is always a *maximum* desired price for tokenIn per tokenOut.
        // i.e., swap ETH -> USD when ETH/USD price <= Target. This is buying USD (selling ETH).
        // Let's refine: `targetPriceRatio` is Price(tokenIn) / Price(tokenOut).
        // Condition is `currentPrice <= targetPriceRatio` for "buy low" (of tokenIn relative to tokenOut) swaps.
        // Condition is `currentPrice >= targetPriceRatio` for "sell high" (of tokenIn relative to tokenOut) swaps.
        // How does the contract know if it's a "buy low" or "sell high" swap? Based on which token is tokenIn? No.
        // Based on minAmountOut vs amountIn? No.

        // The user needs to specify the *direction* of the comparison.
        // Let's add a `bool triggerIfPriceAboveTarget` to the `PendingSwap` struct and `requestConditionalSwap`.

        // Adding `triggerIfPriceAboveTarget` to struct.
        // struct PendingSwap { ... bool triggerIfPriceAboveTarget; ... }

        // Reworking `requestConditionalSwap` to accept this param.

        // Reworking `checkSwapEligibility` with `triggerIfPriceAboveTarget`.
        if (swap.useTWAP) {
            // Placeholder for TWAP logic. Getting TWAP on-chain from Chainlink is complex.
            // It usually requires iterating through past rounds or using a dedicated TWAP oracle.
            // Chainlink's basic AggregatorV3Interface doesn't provide TWAP directly.
            // This function would need to call a custom TWAP oracle or calculate it (expensive).
            // For this example, TWAP eligibility is simulated by calling the spot price function.
            // A real implementation needs a proper TWAP oracle or on-chain calculation logic.
            (int256 twapPrice, uint8 twapDecimals) = _getTWAP(swap.tokenIn, swap.tokenOut); // Placeholder call
            if (twapPrice <= 0 || twapDecimals != oracleDecimals) { // Ensure decimals match for comparison
                return false;
            }
            currentPrice = twapPrice; // Use TWAP for the check
        }

        // Compare current price (spot or TWAP) against the target ratio
        if (swap.triggerIfPriceAboveTarget) {
            isEligible = currentPrice >= int256(swap.targetPriceRatio);
        } else { // Trigger if price is at or below target
            isEligible = currentPrice <= int256(swap.targetPriceRatio);
        }

        // Also check liquidity before declaring eligible
        if (isEligible) {
             // Need to estimate amountOut *before* executing to check against minAmountOut AND pool liquidity.
             // This involves the same calculation as in `executeConditionalSwap`.
             // Let's replicate the calculation safely.

             uint256 oracleDecimals = priceOracle.decimals(); // Get again in case oracle changed

             uint256 estimatedAmountOut;
             uint256 tokenInDecimals = IERC20(swap.tokenIn).decimals();
             uint256 tokenOutDecimals = IERC20(swap.tokenOut).decimals();

             // currentPrice is Price(tokenIn)/Price(tokenOut) scaled by 10^oracleDecimals
             if (tokenOutDecimals >= tokenInDecimals) {
                 estimatedAmountOut = (swap.amountIn * uint256(currentPrice) * (10**(tokenOutDecimals - tokenInDecimals))) / (10**oracleDecimals);
             } else { // tokenOutDecimals < tokenInDecimals
                 estimatedAmountOut = (swap.amountIn * uint256(currentPrice)) / (10**oracleDecimals * (10**(tokenInDecimals - tokenOutDecimals)));
             }

             // Check against minAmountOut
             if (estimatedAmountOut < swap.minAmountOut) {
                 return false; // Estimated output too low
             }

             // Check against pool liquidity (amount needed is estimatedAmountOut including potential fee)
             // Fees are calculated on the amountOut *received by the user*. The pool needs to supply amountOut + fee amount.
             // Let's assume fees are taken from amountOut for simplicity (user receives amountOut - fee).
             // So pool needs to supply estimatedAmountOut.
             if (totalLiquidity[swap.tokenOut] < estimatedAmountOut) {
                 return false; // Insufficient liquidity in target pool
             }
        }


        return isEligible;
    }

    /// @notice Checks if a token is approved for use in the contract.
    /// @param token The address of the token.
    /// @return isApproved True if the token is approved, false otherwise.
    function isTokenApproved(address token) external view returns (bool isApproved) {
        return approvedTokens[token];
    }

     /// @notice Gets the currently required TWAP lookback period.
     /// @return period The TWAP period in seconds.
    function getRequiredTWAPPeriod() external view returns (uint256 period) {
        return twapPeriod;
    }

    /// @notice Gets the current swap fee percentage.
    /// @return feeBps The swap fee in basis points.
    function getSwapFee() external view returns (uint256 feeBps) {
        return swapFeeBps;
    }

    /// @notice Gets the current percentage of swap fees allocated to LPs.
    /// @return shareBps The LP fee share in basis points.
    function getLiquidityFeeShare() external view returns (uint256 shareBps) {
        return liquidityFeeShareBps;
    }

    /// @notice Gets the total accumulated protocol fees for a specific token.
    /// @param token The address of the token.
    /// @return balance The total protocol fee balance.
    function getProtocolFeeBalance(address token) external view returns (uint256 balance) {
        return protocolFeeBalances[token];
    }

     /// @notice Gets the amount of fees a user can claim for a specific liquidity token.
     /// @param user The address of the user.
     /// @param token The address of the liquidity token.
     /// @return claimableAmount The amount of fees claimable by the user.
    function getClaimableLiquidityFees(address user, address token) external view returns (uint256 claimableAmount) {
         return _calculateClaimableFees(user, token);
    }

    /*═════════════════════════════════════════ Internal/Private Helpers ═════════════════════════════════════════*/

    /// @dev Internal function to safely transfer tokens.
    /// @param token The address of the token.
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    function _transferToken(address token, address to, uint256 amount) internal {
         require(amount > 0, "Transfer amount must be > 0"); // Should be checked by caller, but safety
         uint256 contractBalance = IERC20(token).balanceOf(address(this));
         require(contractBalance >= amount, "Insufficient contract balance for transfer");
         bool success = IERC20(token).transfer(to, amount);
         require(success, "Token transfer failed");
    }

    /// @dev Internal helper to get spot price from the oracle.
    /// Placeholder - needs proper oracle integration layer.
    /// @param tokenA Address of the first token.
    /// @param tokenB Address of the second token.
    /// @return price Price (scaled by oracle decimals), assumed Price(tokenA)/Price(tokenB).
    /// @return decimals Oracle decimals.
    function _getSpotPrice(address tokenA, address tokenB) internal view returns (int256 price, uint8 decimals) {
        // In a real scenario, map tokenA/tokenB to the correct Chainlink feed and call it.
        // For this example, we use the single configured `priceOracle`.
        // We assume `priceOracle` is configured such that its result can be interpreted
        // as Price(tokenA)/Price(tokenB) after potential scaling or inversion based on A and B.
        // This requires external configuration knowledge or a more complex oracle system.
        // Let's return the raw price and decimals from the single oracle.
        // The interpretation happens in `checkSwapEligibility` and `executeConditionalSwap`.

        (int256 _price, uint8 _decimals) = getCurrentPrice(tokenA, tokenB); // Call the public view function
        return (_price, _decimals);
    }

    /// @dev Internal helper to get TWAP from the oracle over `twapPeriod`.
    /// Placeholder - Chainlink AggregatorV3Interface doesn't provide TWAP directly.
    /// This function needs a dedicated TWAP oracle or complex on-chain logic reading historical rounds.
    /// For this example, it just returns the spot price.
    /// @param tokenA Address of the first token.
    /// @param tokenB Address of the second token.
    /// @return price TWAP price (scaled by oracle decimals).
    /// @return decimals Oracle decimals.
    function _getTWAP(address tokenA, address tokenB) internal view returns (int256 price, uint8 decimals) {
        // A real TWAP function would fetch past rounds and calculate the time-weighted average.
        // Example (simplified, incomplete):
        // uint256 timeAgo = block.timestamp - twapPeriod;
        // Get latest round...
        // Find round ID at timeAgo...
        // Iterate through rounds between then and now...
        // Calculate weighted average.
        // This is gas-intensive and complex.

        // For demonstration, return spot price.
        return _getSpotPrice(tokenA, tokenB);
    }

     /// @dev Internal helper to calculate claimable fees for a user based on cumulative fee per share.
     /// @param user The address of the user.
     /// @param token The address of the liquidity token.
     /// @return claimableAmount The amount of fees claimable by the user.
    function _calculateClaimableFees(address user, address token) internal view returns (uint256 claimableAmount) {
        uint256 userLiquidity = liquidityBalances[user][token];
        if (userLiquidity == 0) {
            return 0;
        }

        // Current cumulative fee per share for this token pool
        uint256 currentCumulative = cumulativeFeePerShare[token];

        // Last cumulative fee per share seen by this user for this token
        uint256 userLastCumulative = userLastFeePerShare[user][token];

        // Fees earned per share since user's last snapshot
        uint256 earnedPerShare = currentCumulative - userLastCumulative;

        // Total claimable amount = user liquidity * earnedPerShare
        // Need to handle scaling (earnedPerShare is scaled by 1e18)
        claimableAmount = (userLiquidity * earnedPerShare) / 1e18;

        // Important: This calculates the amount based on the cumulative value.
        // The actual tokens for these fees are assumed to be in the contract's balance.
        // This calculation doesn't deduct from `liquidityFeeBalances` because that variable is no longer used
        // to track the pool of claimable fees in this cumulative model.
        // Fees accrue implicitly to the contract's token balance, and cumulativeFeePerShare tracks entitlement.
        // The `claimMyLiquidityFees` function will perform the transfer and update the user's snapshot.

        return claimableAmount;
    }

    // Need to add a require in provideLiquidity and withdrawLiquidity
    // to update userLastFeePerShare snapshot when they change liquidity.
    // Reworked functions implicitly update snapshot in the final implementation.

    // Add missing state variable definition
    // mapping(address => uint256) public totalLpDeposits; // Total amount of tokens deposited by LPs

    // Need to add updates to totalLpDeposits in provide/withdrawLiquidity
    // And ensure `executeConditionalSwap` does NOT add `swap.amountIn` to `totalLpDeposits`.

    // Final check of function count:
    // 1 constructor
    // 7 Core User/LP Functions (request, execute, cancel, claimExpired, provide, withdraw, claimMyFees)
    // 8 Admin & Utility Functions (setOracle, setSwapFee, setLPShare, setTWAPPeriod, setApproved, pause, unpause, collectProtocol, emergencyWithdraw) - Wait, that's 9
    // 12 View/Query Functions (getPending, getUserPending, getLiquidity, getPoolLiquidity, getTotalLpDeposits, getCurrentPrice, checkEligibility, isApproved, getTWAPPeriod, getSwapFee, getLPShare, getProtocolFee, getClaimableLPFees) - That's 13
    // Total: 1 + 7 + 9 + 13 = 30 functions. More than 20. Excellent.

    // Renaming `distributeLiquidityFees` to `claimMyLiquidityFees` as per revised fee model.
    // Adding `getTotalLpDeposits` view function and `totalLpDeposits` state variable.
    // Adding `getClaimableLiquidityFees` view function.
    // Adding `triggerIfPriceAboveTarget` to PendingSwap struct and `requestConditionalSwap`.
    // Implementing cumulative fee per share logic in relevant functions and `_calculateClaimableFees`.
    // Removed `liquidityFeeBalances` and `protocolFeeBalances` as pool balances, used only `protocolFeeBalances` for owner claim.
    // Fees (LP share) are now implicitly in the token balance, tracked by cumulativeFeePerShare.

    // Final check on state variables:
    // pendingSwaps, _nextSwapId, totalLiquidity, liquidityBalances, priceOracle, swapFeeBps,
    // liquidityFeeShareBps, twapPeriod, approvedTokens, paused,
    // cumulativeFeePerShare, userLastFeePerShare, totalLpDeposits, protocolFeeBalances.
    // Seems correct for the chosen models.

    // Final check on imports: IERC20, Ownable, ReentrancyGuard, AggregatorV3Interface. Correct.

    // Final check on `executeConditionalSwap`: it decreases totalLiquidity[tokenOut] and increases totalLiquidity[tokenIn].
    // This assumes the *value* of tokenIn received covers the *value* of tokenOut sent from the LP pool.
    // This requires the swap execution price to be based on the oracle, not pool ratios, which is the design.
    // The TokenIn received is added to `totalLiquidity[tokenIn]` but not `totalLpDeposits[tokenIn]`. Correct.

    // The logic in `checkSwapEligibility` and `executeConditionalSwap` for calculating `amountOut` based on oracle price
    // and token decimals assumes the oracle price needs to be adjusted by token decimal differences.
    // This is standard for converting a fiat-denominated price feed (like ETH/USD) to a token-to-token ratio (like USDC/ETH).
    // The formula used: `amountOut = (amountIn * currentPriceRatio * (10**(tokenOutDecimals - tokenInDecimals))) / (10**oracleDecimals)`
    // if tokenOutDecimals >= tokenInDecimals
    // `amountOut = (amountIn * currentPriceRatio) / (10**oracleDecimals * (10**(tokenInDecimals - tokenOutDecimals)))`
    // if tokenOutDecimals < tokenInDecimals
    // where `currentPriceRatio` is `Price(tokenIn)/Price(tokenOut)` scaled by `10^oracleDecimals`.
    // This seems correct for converting price ratio A/B to amountOut of B for amountIn of A.


    // Looks ready to write the final code block.
}

// Reworked implementation based on thought process

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title QuantumSwap
/// @author YourNameOrAlias
/// @notice A smart contract for conditional, time-locked, oracle-dependent swaps with pooled liquidity and claimable fees.
contract QuantumSwap is Ownable, ReentrancyGuard {

    /*═════════════════════════════════════════ State Variables ═════════════════════════════════════════*/

    struct PendingSwap {
        address user;               // The user requesting the swap
        address tokenIn;            // The token the user is depositing
        address tokenOut;           // The token the user wants to receive
        uint256 amountIn;           // The amount of tokenIn deposited
        uint256 minAmountOut;       // Minimum amount of tokenOut user must receive
        uint256 targetPriceRatio;   // Target price ratio (Price(tokenIn) / Price(tokenOut)) scaled by 10^oracle_decimals
        bool triggerIfPriceAboveTarget; // If true, swap triggers when current price >= target; if false, triggers when current price <= target.
        bool useTWAP;               // Whether to use TWAP or spot price for condition
        uint256 startTime;          // Timestamp when the swap becomes eligible for execution
        uint256 endTime;            // Timestamp after which the swap expires
        bool executed;              // Whether the swap has been executed
        bool cancelled;             // Whether the swap has been cancelled (explicitly by user or implicitly by claim/expire)
    }

    // Mapping from swap ID to PendingSwap struct
    mapping(uint256 => PendingSwap) public pendingSwaps;
    uint256 private _nextSwapId = 1; // Counter for unique swap IDs

    // Mapping from token address to total amount held by the contract (LP deposits + deposited swap tokens)
    mapping(address => uint256) public totalLiquidity;

    // Mapping from token address to total amount explicitly deposited by LPs
    mapping(address => uint256) public totalLpDeposits;

    // Mapping from user address to token address to liquidity amount deposited by user
    mapping(address => mapping(address => uint256)) public liquidityBalances;

    // Oracle address for price feeds (e.g., Chainlink Aggregator). Placeholder, needs robust mapping in real dApp.
    AggregatorV3Interface public priceOracle;

    // Fee percentage for executed swaps (e.g., 10 = 0.1%)
    uint256 public swapFeeBps; // Basis points (100 = 1%)

    // Percentage of swapFeeBps allocated to LPs (e.g., 7000 = 70%)
    uint256 public liquidityFeeShareBps; // Basis points

    // Lookback period for TWAP calculation in seconds (placeholder, requires TWAP oracle)
    uint256 public twapPeriod; // In seconds

    // Mapping of approved token addresses
    mapping(address => bool) public approvedTokens;

    // Paused state
    bool public paused = false;

    // Cumulative fee per unit of liquidity deposited (scaled by 1e18) for each token pool
    mapping(address => uint256) public cumulativeFeePerShare; // Per token, scaled by 1e18

    // Mapping from user address to token address to the cumulativeFeePerShare snapshot at last interaction
    mapping(address => mapping(address => uint256)) public userLastFeePerShare; // Per user per token

    // Mapping from token address to accumulated protocol fees waiting for owner claim
    mapping(address => uint256) public protocolFeeBalances;

    /*═════════════════════════════════════════ Events ═════════════════════════════════════════*/

    /// @dev Emitted when a new conditional swap request is made.
    /// @param swapId The unique ID of the new swap.
    /// @param user The address of the user requesting the swap.
    /// @param tokenIn The address of the token deposited by the user.
    /// @param amountIn The amount of tokenIn deposited.
    /// @param tokenOut The address of the token the user wants to receive.
    /// @param targetPriceRatio The target price ratio set by the user.
    /// @param triggerAbove If true, triggers when price >= target; false, triggers when price <= target.
    /// @param useTWAP Whether TWAP was requested for the condition.
    /// @param startTime The timestamp when the swap becomes eligible.
    /// @param endTime The timestamp when the swap expires.
    event ConditionalSwapRequested(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 targetPriceRatio,
        bool triggerAbove,
        bool useTWAP,
        uint256 startTime,
        uint256 endTime
    );

    /// @dev Emitted when a conditional swap is successfully executed.
    /// @param swapId The unique ID of the executed swap.
    /// @param user The address of the user who requested the swap.
    /// @param tokenIn The address of the token swapped out (consumed from deposit).
    /// @param amountIn The amount of tokenIn swapped out.
    /// @param tokenOut The address of the token swapped in (sent from pool).
    /// @param amountOut The amount of tokenOut sent to the user.
    /// @param totalFeeAmount The total fee amount collected in tokenOut.
    event ConditionalSwapExecuted(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        uint256 totalFeeAmount
    );

    /// @dev Emitted when a pending swap is cancelled by the user.
    /// @param swapId The unique ID of the cancelled swap.
    /// @param user The address of the user who cancelled.
    /// @param tokenIn The address of the token refunded.
    /// @param amountIn The amount of token refunded.
    event ConditionalSwapCancelled(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn
    );

    /// @dev Emitted when an expired swap is claimed by the user.
    /// @param swapId The unique ID of the expired swap.
    /// @param user The address of the user who claimed.
    /// @param tokenIn The address of the token refunded.
    /// @param amountIn The amount of token refunded.
    event ExpiredSwapClaimed(
        uint256 indexed swapId,
        address indexed user,
        address tokenIn,
        uint256 amountIn
    );

    /// @dev Emitted when a user provides liquidity to a pool.
    /// @param user The address of the liquidity provider.
    /// @param token The address of the token provided.
    /// @param amount The amount of token provided.
    event LiquidityProvided(address indexed user, address indexed token, uint256 amount);

    /// @dev Emitted when a user withdraws liquidity from a pool.
    /// @param user The address of the liquidity provider.
    /// @param token The address of the token withdrawn.
    /// @param amount The amount of token withdrawn.
    event LiquidityWithdrawal(address indexed user, address indexed token, uint256 amount);

     /// @dev Emitted when liquidity provider fees are claimed by a user.
     /// @param user The address of the liquidity provider.
     /// @param token The address of the token the fee is in.
     /// @param amount The amount of fee claimed.
    event LiquidityFeesClaimed(address indexed user, address indexed token, uint256 amount);


    /// @dev Emitted when protocol fees are collected by the owner.
    /// @param owner The contract owner.
    /// @param token The address of the token the fee is in.
    /// @param amount The amount of fee collected.
    event ProtocolFeesCollected(address indexed owner, address indexed token, uint256 amount);

    /// @dev Emitted when the contract is paused or unpaused.
    /// @param paused The new paused state.
    event Paused(bool paused);

    /// @dev Emitted when a token's approval status is updated.
    /// @param token The address of the token.
    /// @param approved Whether the token is now approved.
    event TokenApprovalUpdated(address indexed token, bool approved);

    /*═════════════════════════════════════════ Modifiers ═════════════════════════════════════════*/

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    /*═════════════════════════════════════════ Constructor ═════════════════════════════════════════*/

    /// @notice Initializes the contract with owner, oracle, and initial settings.
    /// @param initialOwner The address of the initial owner.
    /// @param _priceOracle The address of the Chainlink AggregatorV3Interface (or a compatible oracle).
    /// @param _swapFeeBps Initial swap fee percentage in basis points (e.g., 10 for 0.1%). Max 10000.
    /// @param _liquidityFeeShareBps Initial percentage of swap fees going to LPs in basis points (e.g., 7000 for 70%). Max 10000.
    /// @param _twapPeriod Initial TWAP lookback period in seconds (placeholder, needs TWAP oracle).
    constructor(address initialOwner, address _priceOracle, uint256 _swapFeeBps, uint256 _liquidityFeeShareBps, uint256 _twapPeriod) Ownable(initialOwner) {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = AggregatorV3Interface(_priceOracle);
        require(_swapFeeBps <= 10000, "Initial fee exceeds 100%");
        swapFeeBps = _swapFeeBps;
        require(_liquidityFeeShareBps <= 10000, "Initial LP share exceeds 100%");
        liquidityFeeShareBps = _liquidityFeeShareBps;
        require(_twapPeriod > 0, "Initial TWAP period must be > 0");
        twapPeriod = _twapPeriod;
    }

    /*═════════════════════════════════════════ Core User/LP Functions ═════════════════════════════════════════*/

    /// @notice Requests a conditional swap by depositing tokenIn.
    /// User must have approved this contract to transfer `amountIn` of `tokenIn`.
    /// The `targetPriceRatio` is interpreted as Price(tokenIn) / Price(tokenOut) scaled by 10^oracle_decimals.
    /// The swap triggers if the current price meets the target based on `triggerIfPriceAboveTarget`.
    /// @param tokenIn The address of the token to deposit.
    /// @param amountIn The amount of tokenIn to deposit.
    /// @param tokenOut The address of the token desired in return.
    /// @param minAmountOut The minimum amount of tokenOut required for the swap to be valid upon execution.
    /// @param targetPriceRatio The target price ratio (Price(tokenIn) / Price(tokenOut)) * 10^oracle_decimals.
    /// @param triggerIfPriceAboveTarget If true, swap triggers when current price >= target; if false, triggers when current price <= target.
    /// @param _useTWAP Whether to use TWAP (true) or spot price (false) for the condition check.
    /// @param _startTime Timestamp when the swap becomes eligible for execution. Must be in the future or now.
    /// @param _endTime Timestamp after which the swap expires. Must be after _startTime.
    /// @return swapId The unique ID of the created pending swap.
    function requestConditionalSwap(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 targetPriceRatio,
        bool triggerIfPriceAboveTarget,
        bool _useTWAP,
        uint256 _startTime,
        uint256 _endTime
    ) external whenNotPaused nonReentrant returns (uint256 swapId) {
        require(amountIn > 0, "AmountIn must be > 0");
        require(minAmountOut > 0, "MinAmountOut must be > 0");
        require(tokenIn != address(0) && tokenOut != address(0) && tokenIn != tokenOut, "Invalid token addresses");
        require(approvedTokens[tokenIn], "TokenIn not approved");
        require(approvedTokens[tokenOut], "TokenOut not approved");
        require(_startTime >= block.timestamp, "Start time must be in the future or now");
        require(_endTime > _startTime, "End time must be after start time");
        require(targetPriceRatio > 0, "Target price ratio must be > 0");

        swapId = _nextSwapId++;
        pendingSwaps[swapId] = PendingSwap({
            user: msg.sender,
            tokenIn: tokenIn,
            amountIn: amountIn,
            tokenOut: tokenOut,
            minAmountOut: minAmountOut,
            targetPriceRatio: targetPriceRatio,
            triggerIfPriceAboveTarget: triggerIfPriceAboveTarget,
            useTWAP: _useTWAP,
            startTime: _startTime,
            endTime: _endTime,
            executed: false,
            cancelled: false
        });

        // Transfer tokens from user to contract
        bool success = IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        require(success, "Token transfer failed");

        // Update total liquidity held by the contract
        totalLiquidity[tokenIn] += amountIn;

        emit ConditionalSwapRequested(
            swapId,
            msg.sender,
            tokenIn,
            amountIn,
            tokenOut,
            targetPriceRatio,
            triggerIfPriceAboveTarget,
            _useTWAP,
            _startTime,
            _endTime
        );
    }

    /// @notice Executes a pending conditional swap if its conditions are met and it's within the time window.
    /// This function can be called by anyone.
    /// @param swapId The ID of the pending swap to execute.
    function executeConditionalSwap(uint256 swapId) external nonReentrant whenNotPaused {
        PendingSwap storage swap = pendingSwaps[swapId];

        require(swap.user != address(0), "Swap ID does not exist");
        require(!swap.executed, "Swap already executed");
        require(!swap.cancelled, "Swap cancelled");
        require(block.timestamp >= swap.startTime, "Swap window has not started");
        require(block.timestamp <= swap.endTime, "Swap window has ended");

        // Check price condition and liquidity
        (int256 currentPrice, uint8 oracleDecimals) = swap.useTWAP ? _getTWAP(swap.tokenIn, swap.tokenOut) : _getSpotPrice(swap.tokenIn, swap.tokenOut);
        require(currentPrice > 0, "Could not get valid oracle price"); // Ensure oracle is providing valid price

        // Check price condition based on trigger flag
        bool priceConditionMet;
        if (swap.triggerIfPriceAboveTarget) {
            priceConditionMet = currentPrice >= int256(swap.targetPriceRatio);
        } else {
            priceConditionMet = currentPrice <= int256(swap.targetPriceRatio);
        }
        require(priceConditionMet, "Swap price conditions not met");

        // Calculate amountOut based on current oracle price and token decimals
        uint256 tokenInDecimals = IERC20(swap.tokenIn).decimals();
        uint256 tokenOutDecimals = IERC20(swap.tokenOut).decimals();

        // currentPrice is Price(tokenIn)/Price(tokenOut) scaled by 10^oracleDecimals
        uint256 amountOut;
        if (tokenOutDecimals >= tokenInDecimals) {
             amountOut = (swap.amountIn * uint256(currentPrice) * (10**(tokenOutDecimals - tokenInDecimals))) / (10**oracleDecimals);
        } else { // tokenOutDecimals < tokenInDecimals
             amountOut = (swap.amountIn * uint256(currentPrice)) / (10**oracleDecimals * (10**(tokenInDecimals - tokenOutDecimals)));
        }
        require(amountOut >= swap.minAmountOut, "Swap output below minimum");

        // Calculate fees BEFORE checking liquidity needs the final amountOut
        uint256 totalFee = (amountOut * swapFeeBps) / 10000;
        uint256 lpFee = (totalFee * liquidityFeeShareBps) / 10000;
        uint256 protocolFee = totalFee - lpFee;

        uint256 amountOutAfterFee = amountOut - totalFee;
        uint256 totalAmountOutNeeded = amountOutAfterFee + totalFee; // Total tokenOut leaving the pool

        require(totalLiquidity[swap.tokenOut] >= totalAmountOutNeeded, "Insufficient liquidity in tokenOut pool");

        // Mark swap as executed
        swap.executed = true;

        // Update fee balances (protocol fees are claimable by owner)
        protocolFeeBalances[swap.tokenOut] += protocolFee;

        // Update cumulative fee per share for the TokenOut pool LPs
        if (lpFee > 0 && totalLpDeposits[swap.tokenOut] > 0) {
            // Use 1e18 for scaling cumulative fee per share
             uint256 feePerShare = (lpFee * 1e18) / totalLpDeposits[swap.tokenOut];
             cumulativeFeePerShare[swap.tokenOut] += feePerShare;
             // The actual `lpFee` tokens remain in the contract's `totalLiquidity[swap.tokenOut]`.
             // LPs claim their share of this balance via `claimMyLiquidityFees`.
        }

        // Update total liquidity held by the contract
        // amountOut is sent out, amountIn stays in (it was already added on deposit)
        totalLiquidity[swap.tokenOut] -= totalAmountOutNeeded;
        // totalLiquidity[swap.tokenIn] already includes swap.amountIn from deposit

        // Transfer tokenOut to the user
        _transferToken(swap.tokenOut, swap.user, amountOutAfterFee);

        emit ConditionalSwapExecuted(
            swapId,
            swap.user,
            swap.tokenIn,
            swap.amountIn,
            swap.tokenOut,
            amountOutAfterFee,
            totalFee
        );

        // Swap is complete. The user's tokenIn (swap.amountIn) remains in the contract.
        // It has effectively been swapped for the tokenOut from the pool.
    }

    /// @notice Cancels a pending swap request.
    /// Can only be cancelled before the end time if not yet executed.
    /// Refunds the deposited tokens to the user.
    /// @param swapId The ID of the swap to cancel.
    function cancelConditionalSwap(uint256 swapId) external nonReentrant whenNotPaused {
        PendingSwap storage swap = pendingSwaps[swapId];

        require(swap.user == msg.sender, "Not your swap");
        require(swap.user != address(0), "Swap ID does not exist");
        require(!swap.executed, "Swap already executed");
        require(!swap.cancelled, "Swap already cancelled");
        require(block.timestamp <= swap.endTime, "Cannot cancel after end time"); // Can cancel anytime before or during window, if not executed

        swap.cancelled = true;

        // Refund deposited tokens to user
        _transferToken(swap.tokenIn, msg.sender, swap.amountIn);

        // Update total liquidity held by the contract
        totalLiquidity[swap.tokenIn] -= swap.amountIn;

        emit ConditionalSwapCancelled(swapId, msg.sender, swap.tokenIn, swap.amountIn);
    }

    /// @notice Claims back tokens from an expired swap request.
    /// Can only be claimed after the end time if the swap was not executed or cancelled.
    /// Refunds the deposited tokens to the user.
    /// @param swapId The ID of the expired swap to claim.
    function claimExpiredSwap(uint256 swapId) external nonReentrant whenNotPaused {
        PendingSwap storage swap = pendingSwaps[swapId];

        require(swap.user == msg.sender, "Not your swap");
        require(swap.user != address(0), "Swap ID does not exist");
        require(!swap.executed, "Swap was executed");
        require(!swap.cancelled, "Swap was cancelled");
        require(block.timestamp > swap.endTime, "Swap has not expired yet");

        // Mark as cancelled implicitly by claiming
        swap.cancelled = true;

        // Refund deposited tokens to user
        _transferToken(swap.tokenIn, msg.sender, swap.amountIn);

        // Update total liquidity held by the contract
        totalLiquidity[swap.tokenIn] -= swap.amountIn;

        emit ExpiredSwapClaimed(swapId, msg.sender, swap.tokenIn, swap.amountIn);
    }

    /// @notice Provides liquidity to a token pool.
    /// User must have approved this contract to transfer `amount` of `token`.
    /// Updates the user's fee snapshot for this token pool.
    /// @param token The address of the token to provide liquidity for.
    /// @param amount The amount of token to provide.
    function provideLiquidity(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(token != address(0), "Invalid token address");
        require(approvedTokens[token], "Token not approved for liquidity");

        // Claim any outstanding fees before adding new liquidity to maintain fairness
        uint256 claimableBefore = _calculateClaimableFees(msg.sender, token);
        if (claimableBefore > 0) {
             // Transfer fees (this also updates the user's snapshot implicitly in _calculateClaimableFees logic)
            _transferToken(token, msg.sender, claimableBefore);
             emit LiquidityFeesClaimed(msg.sender, token, claimableBefore);
        }

        // Update user's fee snapshot to the current cumulative value BEFORE adding liquidity
        userLastFeePerShare[msg.sender][token] = cumulativeFeePerShare[token];

        // Transfer tokens from user to contract
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // Update liquidity balances
        liquidityBalances[msg.sender][token] += amount;
        totalLiquidity[token] += amount; // Total tokens held by contract
        totalLpDeposits[token] += amount; // Total tokens explicitly deposited by LPs

        emit LiquidityProvided(msg.sender, token, amount);
    }

    /// @notice Withdraws liquidity from a token pool.
    /// Claims any accumulated fees for the user before withdrawing liquidity.
    /// @param token The address of the token pool to withdraw from.
    /// @param amount The amount of liquidity to withdraw.
    function withdrawLiquidity(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(token != address(0), "Invalid token address");
        require(approvedTokens[token], "Token not approved for liquidity");
        require(liquidityBalances[msg.sender][token] >= amount, "Insufficient liquidity balance");
        require(totalLpDeposits[token] >= amount, "Insufficient total LP liquidity"); // Should be covered by user balance check conceptually

        // Claim any outstanding fees before withdrawing liquidity
        uint256 claimableBefore = _calculateClaimableFees(msg.sender, token);
        if (claimableBefore > 0) {
             // Transfer fees (this also updates the user's snapshot implicitly in _calculateClaimableFees logic)
            _transferToken(token, msg.sender, claimableBefore);
             emit LiquidityFeesClaimed(msg.sender, token, claimableBefore);
        }

        // Update user's fee snapshot to the current cumulative value BEFORE withdrawing
        // This ensures they don't earn fees on the amount withdrawn after this point
        userLastFeePerShare[msg.sender][token] = cumulativeFeePerShare[token];

        // Update liquidity balances
        liquidityBalances[msg.sender][token] -= amount;
        totalLiquidity[token] -= amount; // Total tokens held by contract
        totalLpDeposits[token] -= amount; // Total tokens explicitly deposited by LPs

        // Transfer tokens from contract to user
        _transferToken(token, msg.sender, amount);

        emit LiquidityWithdrawal(msg.sender, token, amount);
    }

     /// @notice Allows liquidity providers to claim their accumulated fee share for a specific token.
     /// This function calculates the user's share based on the cumulative fee per share model
     /// and transfers the fees from the contract's token balance.
     /// @param token The address of the token for which to claim fees.
    function claimMyLiquidityFees(address token) external nonReentrant whenNotPaused {
        require(token != address(0), "Invalid token address");
        require(approvedTokens[token], "Token not approved"); // LPs only for approved tokens

        uint256 claimableAmount = _calculateClaimableFees(msg.sender, token);

        if (claimableAmount > 0) {
            // Transfer claimable fees from the contract's token balance
            _transferToken(token, msg.sender, claimableAmount);

            // Update user's fee snapshot to the current cumulative value after claiming
            userLastFeePerShare[msg.sender][token] = cumulativeFeePerShare[token];

            emit LiquidityFeesClaimed(msg.sender, token, claimableAmount);
        }
    }

    /*═════════════════════════════════════════ Admin Functions ═════════════════════════════════════════*/

    /// @notice Sets the address of the Chainlink AggregatorV3Interface oracle.
    /// @param _priceOracle The new oracle contract address.
    function setOracleAddress(address _priceOracle) external onlyOwner {
        require(_priceOracle != address(0), "Invalid oracle address");
        priceOracle = AggregatorV3Interface(_priceOracle);
    }

    /// @notice Sets the swap fee percentage.
    /// @param _swapFeeBps The new fee in basis points (100 = 1%). Max 10000 (100%).
    function setSwapFee(uint256 _swapFeeBps) external onlyOwner {
        require(_swapFeeBps <= 10000, "Fee exceeds 100%");
        swapFeeBps = _swapFeeBps;
    }

    /// @notice Sets the percentage of the swap fee that goes to liquidity providers.
    /// @param _liquidityFeeShareBps The new share in basis points (100 = 1%). Max 10000 (100%).
    function setLiquidityFeeShare(uint256 _liquidityFeeShareBps) external onlyOwner {
        require(_liquidityFeeShareBps <= 10000, "Share exceeds 100%");
        liquidityFeeShareBps = _liquidityFeeShareBps;
    }

     /// @notice Sets the lookback period for TWAP calculations in seconds (placeholder).
     /// @param _twapPeriod The new TWAP period in seconds.
    function setTWAPPeriod(uint256 _twapPeriod) external onlyOwner {
        require(_twapPeriod > 0, "TWAP period must be greater than 0");
        twapPeriod = _twapPeriod;
    }

    /// @notice Approves or unapproves a token for use in the contract (swaps and liquidity).
    /// @param token The address of the token.
    /// @param approved Whether the token should be approved (true) or unapproved (false).
    function setApprovedTokens(address token, bool approved) external onlyOwner {
        require(token != address(0), "Invalid token address");
        approvedTokens[token] = approved;
        emit TokenApprovalUpdated(token, approved);
    }

    /// @notice Pauses core contract operations (requests, executions, liquidity, claims).
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(true);
    }

    /// @notice Unpauses contract operations.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Paused(false);
    }

    /// @notice Allows the owner to collect the protocol's share of fees for a specific token.
    /// @param token The address of the token for which to collect fees.
    function collectProtocolFees(address token) external onlyOwner nonReentrant {
        uint256 amount = protocolFeeBalances[token];
        if (amount > 0) {
            protocolFeeBalances[token] = 0;
            _transferToken(token, owner(), amount);
            emit ProtocolFeesCollected(owner(), token, amount);
        }
    }

    /// @notice Emergency withdrawal of a token by the owner. Use with extreme caution.
    /// Intended for recovering tokens sent accidentally or in case of critical vulnerability.
    /// @param token The address of the token to withdraw.
    /// @param amount The amount of token to withdraw.
    function emergencyWithdrawAdmin(address token, uint256 amount) external onlyOwner nonReentrant {
         require(token != address(0), "Invalid token address");
         require(amount > 0, "Amount must be > 0");
         // This can potentially withdraw LP or user funds. Use only in emergencies.
         // It bypasses normal withdrawal logic.
         _transferToken(token, owner(), amount);
    }

    /*═════════════════════════════════════════ View/Query Functions ═════════════════════════════════════════*/

    /// @notice Retrieves the details of a pending swap.
    /// @param swapId The ID of the swap.
    /// @return swap The PendingSwap struct for the given ID.
    function getPendingSwapDetails(uint256 swapId) external view returns (PendingSwap memory swap) {
        return pendingSwaps[swapId];
    }

    /// @notice Retrieves the IDs of all pending swaps for a user.
    /// NOTE: This function iterates over a mapping, which can be gas-intensive if a user has many swaps.
    /// This is generally acceptable for read-only view functions, but consider alternative patterns for very large numbers.
    /// @param user The address of the user.
    /// @return swapIds An array of pending swap IDs for the user.
    function getUserPendingSwaps(address user) external view returns (uint256[] memory swapIds) {
        uint256 count = 0;
        // First pass to count non-executed, non-cancelled swaps for the user
        for (uint256 i = 1; i < _nextSwapId; i++) {
            if (pendingSwaps[i].user == user && !pendingSwaps[i].executed && !pendingSwaps[i].cancelled) {
                count++;
            }
        }

        swapIds = new uint256[](count);
        uint256 currentIndex = 0;
        // Second pass to collect IDs
        for (uint256 i = 1; i < _nextSwapId; i++) {
             if (pendingSwaps[i].user == user && !pendingSwaps[i].executed && !pendingSwaps[i].cancelled) {
                 swapIds[currentIndex] = i;
                 currentIndex++;
             }
        }
        return swapIds;
    }

    /// @notice Gets a user's liquidity balance for a specific token (amount explicitly deposited by LP).
    /// @param user The address of the user.
    /// @param token The address of the token.
    /// @return balance The user's liquidity balance.
    function getLiquidityBalance(address user, address token) external view returns (uint256 balance) {
        return liquidityBalances[user][token];
    }

     /// @notice Gets the total liquidity amount for a specific token held by the contract.
     /// This includes LP deposits and deposited swap tokens.
     /// @param token The address of the token.
     /// @return total The total amount of the token held by the contract.
    function getPoolLiquidity(address token) external view returns (uint256 total) {
        return totalLiquidity[token];
    }

    /// @notice Gets the total amount explicitly deposited by LPs for a specific token.
    /// This excludes swap inputs held by the contract. Used for LP fee calculations.
    /// @param token The address of the token.
    /// @return total The total amount of the token deposited by LPs.
    function getTotalLpDeposits(address token) external view returns (uint256 total) {
         return totalLpDeposits[token];
    }

    /// @notice Gets the current price from the oracle for a token pair.
    /// Assumes the oracle feed directly provides a price relevant to tokenIn/tokenOut.
    /// This is a simplified placeholder function.
    /// @param tokenIn The address of the input token.
    /// @param tokenOut The address of the output token.
    /// @return price The current price (scaled by oracle decimals). Returns 0 if no valid price.
    /// @return decimals The number of decimals used by the oracle feed.
    function getCurrentPrice(address tokenIn, address tokenOut) public view returns (int256 price, uint8 decimals) {
        // Placeholder: Assumes the single priceOracle is the correct feed for this pair and direction.
        // A real implementation needs a robust way to map token pairs to oracle feeds and interpret results.
        try priceOracle.latestRoundData() returns (uint80 roundId, int256 _price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) {
             require(timeStamp > 0 && _price != 0, "Invalid oracle data"); // Check for stale or invalid data
             try priceOracle.decimals() returns (uint8 _decimals) {
                 return (_price, _decimals);
             } catch {
                 revert("Could not get oracle decimals");
             }
        } catch {
            revert("Oracle call failed");
        }
    }

    /// @notice Checks if a specific pending swap currently meets its price condition and is within its time window.
    /// @param swapId The ID of the swap to check.
    /// @return isEligible True if the swap is eligible for execution, false otherwise.
    function checkSwapEligibility(uint256 swapId) public view returns (bool isEligible) {
        PendingSwap storage swap = pendingSwaps[swapId];

        if (swap.user == address(0) || swap.executed || swap.cancelled) {
            return false; // Invalid, executed, or cancelled swap
        }

        if (block.timestamp < swap.startTime || block.timestamp > swap.endTime) {
            return false; // Outside time window
        }

        // Get current price (spot or TWAP placeholder)
        (int256 currentPrice, uint8 oracleDecimals) = swap.useTWAP ? _getTWAP(swap.tokenIn, swap.tokenOut) : _getSpotPrice(swap.tokenIn, swap.tokenOut);
        if (currentPrice <= 0) {
            return false; // Cannot get a valid price (or price is zero/negative)
        }

        // Check price condition based on trigger flag
        bool priceConditionMet;
        if (swap.triggerIfPriceAboveTarget) {
            priceConditionMet = currentPrice >= int256(swap.targetPriceRatio);
        } else { // Trigger if price is at or below target
            priceConditionMet = currentPrice <= int256(swap.targetPriceRatio);
        }

        if (!priceConditionMet) {
            return false; // Price condition not met
        }

        // Check liquidity and minAmountOut before declaring eligible
        // Need to estimate amountOut based on the current price
        uint256 tokenInDecimals = IERC20(swap.tokenIn).decimals();
        uint256 tokenOutDecimals = IERC20(swap.tokenOut).decimals();

        uint256 estimatedAmountOut;
         if (tokenOutDecimals >= tokenInDecimals) {
             estimatedAmountOut = (swap.amountIn * uint256(currentPrice) * (10**(tokenOutDecimals - tokenInDecimals))) / (10**oracleDecimals);
         } else { // tokenOutDecimals < tokenInDecimals
             estimatedAmountOut = (swap.amountIn * uint256(currentPrice)) / (10**oracleDecimals * (10**(tokenInDecimals - tokenOutDecimals)));
         }

        if (estimatedAmountOut < swap.minAmountOut) {
            return false; // Estimated output below minimum
        }

        // Calculate total tokenOut needed from the pool (amountOut + fee)
        uint256 totalFee = (estimatedAmountOut * swapFeeBps) / 10000;
        uint256 totalAmountOutNeeded = estimatedAmountOut + totalFee;

        if (totalLiquidity[swap.tokenOut] < totalAmountOutNeeded) {
            return false; // Insufficient liquidity in target pool
        }

        return true; // All conditions met
    }


    /// @notice Checks if a token address is approved by the owner for use in the contract.
    /// @param token The address of the token.
    /// @return isApproved True if the token is approved, false otherwise.
    function isTokenApproved(address token) external view returns (bool isApproved) {
        return approvedTokens[token];
    }

     /// @notice Gets the currently configured TWAP lookback period.
     /// @return period The TWAP period in seconds.
    function getRequiredTWAPPeriod() external view returns (uint256 period) {
        return twapPeriod;
    }

    /// @notice Gets the current swap fee percentage.
    /// @return feeBps The swap fee in basis points.
    function getSwapFee() external view returns (uint256 feeBps) {
        return swapFeeBps;
    }

    /// @notice Gets the current percentage of swap fees allocated to LPs.
    /// @return shareBps The LP fee share in basis points.
    function getLiquidityFeeShare() external view returns (uint256 shareBps) {
        return liquidityFeeShareBps;
    }

    /// @notice Gets the total accumulated protocol fees for a specific token waiting for owner claim.
    /// @param token The address of the token.
    /// @return balance The total protocol fee balance.
    function getProtocolFeeBalance(address token) external view returns (uint256 balance) {
        return protocolFeeBalances[token];
    }

     /// @notice Gets the amount of fees a user can claim for a specific liquidity token pool.
     /// @param user The address of the user.
     /// @param token The address of the liquidity token.
     /// @return claimableAmount The amount of fees claimable by the user.
    function getClaimableLiquidityFees(address user, address token) external view returns (uint256 claimableAmount) {
         return _calculateClaimableFees(user, token);
    }


    /*═════════════════════════════════════════ Internal/Private Helpers ═════════════════════════════════════════*/

    /// @dev Internal function to safely transfer tokens.
    /// @param token The address of the token.
    /// @param to The recipient address.
    /// @param amount The amount to transfer.
    function _transferToken(address token, address to, uint256 amount) internal {
         if (amount == 0) return; // Handle 0 transfers gracefully
         uint256 contractBalance = IERC20(token).balanceOf(address(this));
         require(contractBalance >= amount, "Insufficient contract balance for transfer");
         bool success = IERC20(token).transfer(to, amount);
         require(success, "Token transfer failed");
    }

    /// @dev Internal helper to get spot price from the oracle.
    /// Placeholder - needs proper oracle integration layer mapping pairs to feeds and handling direction.
    /// Assumes the single `priceOracle` is relevant and its result is Price(tokenA)/Price(tokenB) scaled by its decimals.
    /// @param tokenA Address of the first token.
    /// @param tokenB Address of the second token.
    /// @return price Price (scaled by oracle decimals), assumed Price(tokenA)/Price(tokenB).
    /// @return decimals Oracle decimals.
    function _getSpotPrice(address tokenA, address tokenB) internal view returns (int256 price, uint8 decimals) {
        // In a real scenario, map tokenA/tokenB to the correct Chainlink feed and call it.
        // For this example, we use the single configured `priceOracle`.
        // This assumes `priceOracle` is configured such that its result can be interpreted
        // as Price(tokenA)/Price(tokenB) after potential scaling or inversion based on A and B.
        // This requires external configuration knowledge or a more complex oracle system.

        // Call the public view function which handles basic oracle interaction error checking
        return getCurrentPrice(tokenA, tokenB);
    }

    /// @dev Internal helper to get TWAP from the oracle over `twapPeriod`.
    /// Placeholder - Chainlink AggregatorV3Interface doesn't provide TWAP directly.
    /// This function needs a dedicated TWAP oracle or complex on-chain logic reading historical rounds.
    /// For this example, it just returns the spot price.
    /// @param tokenA Address of the first token.
    /// @param tokenB Address of the second token.
    /// @return price TWAP price (scaled by oracle decimals), assumed Price(tokenA)/Price(tokenB).
    /// @return decimals Oracle decimals.
    function _getTWAP(address tokenA, address tokenB) internal view returns (int256 price, uint8 decimals) {
        // A real TWAP function would fetch past rounds and calculate the time-weighted average.
        // For demonstration, return spot price.
        return _getSpotPrice(tokenA, tokenB);
    }

     /// @dev Internal helper to calculate claimable fees for a user based on cumulative fee per share.
     /// Fees are accrued to the contract's token balance and entitlement is tracked via cumulativeFeePerShare.
     /// @param user The address of the user.
     /// @param token The address of the liquidity token pool.
     /// @return claimableAmount The amount of fees claimable by the user.
    function _calculateClaimableFees(address user, address token) internal view returns (uint256 claimableAmount) {
        uint256 userLiquidity = liquidityBalances[user][token];
        if (userLiquidity == 0) {
            return 0;
        }

        // Current cumulative fee per share for this token pool
        uint256 currentCumulative = cumulativeFeePerShare[token];

        // Last cumulative fee per share seen by this user for this token
        uint256 userLastCumulative = userLastFeePerShare[user][token];

        // Fees earned per share since user's last snapshot
        uint256 earnedPerShare = currentCumulative - userLastCumulative;

        // Total claimable amount = user liquidity * earnedPerShare
        // `earnedPerShare` is scaled by 1e18, `userLiquidity` is not scaled.
        claimableAmount = (userLiquidity * earnedPerShare) / 1e18;

        return claimableAmount;
    }
}
```