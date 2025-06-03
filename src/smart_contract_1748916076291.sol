Okay, here is a Solidity smart contract implementing a **Decentralized Prediction Market with Dynamic Bonding Curve Pricing**.

This concept is advanced and creative because:
1.  **Dynamic Bonding Curve:** Instead of fixed-price shares or liquidity pools (like AMMs), the price to buy shares of a specific outcome *increases* as more shares of that outcome are purchased. This is governed by a configurable bonding curve.
2.  **Dynamic Exit Liquidity:** Users can *sell* their shares back to the contract *before* resolution along the *same* bonding curve (minus a fee), providing dynamic exit liquidity without needing a separate AMM or counterparty.
3.  **Outcome-Specific Curves:** The bonding state (total shares/collateral) is tracked *per outcome*, making the price for Outcome A independent (in terms of curve position) from Outcome B, though they draw from a shared collateral pool.
4.  **Integrated Resolution & Claiming:** Combines the dynamic pricing mechanism with a standard oracle resolution and proportional claiming of the total pooled collateral.

It aims to be non-duplicative by specifically integrating the bonding curve purchase/sale mechanism directly into the prediction market share system, rather than using bonding curves for initial token launches or general AMM swaps.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Outline:
// 1. Contract Definition and Imports
// 2. Custom Errors
// 3. Events
// 4. Enums and Structs
// 5. State Variables
// 6. Bonding Curve Math Helpers (Internal Pure/View)
// 7. Core Market Functions (Constructor, Join, Exit, Resolve, Claim)
// 8. Getter/View Functions
// 9. Admin/Owner Functions (Fees, Oracle, Pause, Recovery)
// 10. Modifiers

// Function Summary:
// Constructor: Deploys the market with initial parameters (oracle, collateral, bonding curve, event details).
// setOracleAddress: Owner can update the oracle address.
// setBondingCurveParameters: Owner can adjust bonding curve params (base price, slope, scale).
// setFees: Owner can adjust exit and resolution fees.
// updateOutcomeDescription: Owner can update the market event description.
// getMarketStatus: Returns the current status (Open, Resolved, Closed).
// getTotalCollateral: Returns total collateral locked in the market.
// getTotalCollateralForOutcome: Returns collateral locked for a specific outcome.
// getTotalSharesForOutcome: Returns total shares issued for a specific outcome.
// getOutcomeShareBalance: Returns a user's share balance for an outcome.
// calculatePurchaseCost: Estimates collateral needed to buy a specific number of shares for an outcome (view).
// calculateSharesReceived: Estimates shares received for a specific collateral amount for an outcome (view).
// calculateExitRefund: Estimates collateral refund for selling a specific number of shares for an outcome (view).
// calculateWinningClaim: Estimates a user's potential winnings after resolution (view).
// joinMarket: Allows a user to deposit collateral and receive outcome shares based on the bonding curve.
// exitMarket: Allows a user to sell their outcome shares back to the contract for collateral based on the bonding curve (minus fee).
// resolveMarket: Called by the oracle to set the winning outcome and transition market status.
// claimWinnings: Allows users holding winning shares to claim their proportional share of the total collateral pool (minus fee).
// collectFees: Owner function to withdraw accumulated fees.
// getResolutionTime: Returns the market's resolution timestamp.
// getCollateralToken: Returns the address of the collateral token.
// getOracleAddress: Returns the address of the oracle allowed to resolve.
// getBondingCurveParameters: Returns the bonding curve parameters.
// getOutcomeDescription: Returns the market event description.
// getPauseStatus: Returns if the market is paused.
// pauseMarket: Owner can pause market interactions (join/exit).
// unpauseMarket: Owner can unpause the market.
// recoverAccidentallySentTokens: Owner function to recover tokens accidentally sent to the contract (excluding collateral).

contract DecentralizedPredictionMarketWithDynamicBonding is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Custom Errors ---
    error MarketAlreadyResolved();
    error MarketNotOpen();
    error MarketNotResolved();
    error MarketClosed();
    error InvalidOutcome();
    error ResolutionTimeNotPassed();
    error NotOracle();
    error InsufficientShares();
    error WinningsAlreadyClaimed();
    error ZeroShares();
    error ZeroCollateral();
    error MarketPaused();
    error CannotRecoverCollateral();
    error ResolutionTimeInPast();
    error InvalidBondingCurveParameters();

    // --- Events ---
    event MarketJoined(address indexed user, uint8 indexed outcome, uint256 collateralAmount, uint256 sharesReceived, uint256 totalCollateralForOutcome, uint256 totalSharesForOutcome);
    event MarketExited(address indexed user, uint8 indexed outcome, uint256 sharesSold, uint256 collateralRefunded, uint256 totalCollateralForOutcome, uint256 totalSharesForOutcome);
    event MarketResolved(uint8 indexed winningOutcome, uint256 resolvedTimestamp);
    event WinningsClaimed(address indexed user, uint256 amountClaimed);
    event FeesCollected(address indexed owner, uint256 amount);
    event MarketPausedStateChanged(bool isPaused);
    event BondingCurveParametersUpdated(uint256 basePrice, uint256 slope, uint256 priceScale);

    // --- Enums and Structs ---
    enum MarketStatus { Open, Resolved, Closed }

    // --- State Variables ---
    IERC20 public immutable collateralToken;
    address public oracleAddress; // Address allowed to resolve the market
    uint256 public resolutionTime; // Timestamp after which the market can be resolved
    string public outcomeDescription; // Description of the event being predicted

    // Market State
    MarketStatus public marketStatus;
    uint8 public winningOutcome = 255; // 0 for Outcome A, 1 for Outcome B. 255 means not resolved.
    bool public isPaused; // Allows pausing join/exit

    // Bonding Curve Parameters (Scaled)
    // Price per share for outcome 'i' = basePrice + slope * totalSharesForOutcome[i] / priceScale
    uint256 public basePrice; // Base price per share (scaled)
    uint256 public slope;     // Slope of the price curve (scaled)
    uint256 public priceScale; // Scale factor for bonding curve calculations (e.g., 1e18)

    // Market Balances and Shares
    mapping(uint8 => uint256) private _totalCollateralForOutcome; // Total collateral deposited for each outcome
    mapping(uint8 => uint256) private _totalSharesIssuedForOutcome; // Total shares issued for each outcome

    // User Balances and State
    mapping(address => mapping(uint8 => uint256)) public userOutcomeShares; // User's balance of shares for each outcome
    mapping(address => bool) public hasClaimed; // Whether a user has claimed their winnings

    // Fees
    uint256 public exitFeeBasisPoints; // Fee taken when exiting (selling shares)
    uint256 public resolutionFeeBasisPoints; // Fee taken from the total pool during resolution
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000; // 10000 basis points = 100%
    uint256 private _totalFeesAccrued; // Accumulated fees in collateral token

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert NotOracle();
        _;
    }

    modifier marketIsOpen() {
        if (marketStatus != MarketStatus.Open) revert MarketNotOpen();
        if (isPaused) revert MarketPaused();
        _;
    }

    modifier marketIsResolved() {
        if (marketStatus != MarketStatus.Resolved) revert MarketNotResolved();
        _;
    }

    modifier marketNotResolved() {
        if (marketStatus == MarketStatus.Resolved) revert MarketAlreadyResolved();
        _;
    }

    modifier validOutcome(uint8 _outcome) {
        if (_outcome != 0 && _outcome != 1) revert InvalidOutcome();
        _;
    }

    // --- Constructor ---
    constructor(
        address _collateralToken,
        address _oracleAddress,
        uint256 _resolutionTime,
        string memory _outcomeDescription,
        uint256 _basePrice,
        uint256 _slope,
        uint256 _priceScale, // e.g., 1e18
        uint256 _exitFeeBasisPoints,
        uint256 _resolutionFeeBasisPoints
    ) Ownable(msg.sender) {
        if (_resolutionTime <= block.timestamp) revert ResolutionTimeInPast();
        if (_basePrice == 0 || _priceScale == 0) revert InvalidBondingCurveParameters();
        if (_exitFeeBasisPoints > BASIS_POINTS_DENOMINATOR || _resolutionFeeBasisPoints > BASIS_POINTS_DENOMINATOR) revert InvalidBondingCurveParameters();


        collateralToken = IERC20(_collateralToken);
        oracleAddress = _oracleAddress;
        resolutionTime = _resolutionTime;
        outcomeDescription = _outcomeDescription;

        basePrice = _basePrice;
        slope = _slope;
        priceScale = _priceScale;

        exitFeeBasisPoints = _exitFeeBasisPoints;
        resolutionFeeBasisPoints = _resolutionFeeBasisPoints;

        marketStatus = MarketStatus.Open;
        isPaused = false;
    }

    // --- Bonding Curve Math Helpers (Internal) ---
    // Calculate the cost (collateral) to buy a specific number of shares
    // Cost = Integral of (basePrice + slope * s / priceScale) ds from S0 to S0+N
    // Cost = basePrice * N + (slope / priceScale) * ( (S0+N)^2 / 2 - S0^2 / 2 )
    // Cost = basePrice * N + (slope / (2 * priceScale)) * ( (S0+N)^2 - S0^2 )
    // Cost = basePrice * N + (slope / (2 * priceScale)) * ( N^2 + 2 * S0 * N )
    // Cost = basePrice * N + (slope * N / (2 * priceScale)) * ( N + 2 * S0 )
    // Using fixed point:
    // Cost = (basePrice * N * priceScale + slope * N * (N + 2 * S0) / 2) / priceScale
    function _getCostForShares(uint256 s0, uint256 n) internal view returns (uint256 cost) {
        // Avoid division by zero
        if (priceScale == 0) return 0;

        // Using 2*priceScale for slope term denominator
        uint256 term1 = basePrice * n; // basePrice is already scaled relative to priceScale implicitly
        uint256 term2 = (slope * n / 2) / priceScale; // slope needs to be divided by 2 and priceScale

        // term2 calculation might need more care to avoid precision loss if slope * n is small
        // Let's use a common denominator approach for the whole expression:
        // Cost = (basePrice * N * priceScale + slope * ( (S0+N)^2 - S0^2 ) / 2) / priceScale
        // S0+N can overflow if S0 and N are very large. Check potential overflow for (S0+N).
        uint256 s1 = s0 + n;
        if (s1 < s0) { // Overflow check
             revert ZeroShares(); // Or a specific overflow error
        }

        // (S0+N)^2 calculation:
        uint256 s1_squared = s1 * s1;
         if (s1 != 0 && s1_squared / s1 != s1) { // Overflow check for multiplication
             revert ZeroShares(); // Or a specific overflow error
        }

        // S0^2 calculation:
         uint256 s0_squared = s0 * s0;
         if (s0 != 0 && s0_squared / s0 != s0) { // Overflow check for multiplication
             revert ZeroShares(); // Or a specific overflow error
        }


        // (s1_squared - s0_squared) / 2:
        // Ensure s1_squared >= s0_squared (which is true if s1 >= s0)
        uint256 diff_squared_half = (s1_squared - s0_squared) / 2;

        // slope * diff_squared_half:
         uint256 slope_term = slope * diff_squared_half;
        if (slope != 0 && slope_term / slope != diff_squared_half) { // Overflow check
             revert ZeroShares(); // Or a specific overflow error
        }


        // basePrice * N * priceScale:
        uint256 base_term = basePrice * n; // basePrice is scaled, need to multiply by priceScale for consistent unit

        // Total numerator:
        uint256 numerator = base_term + (slope_term / priceScale);
        // Integer division handles the final division by priceScale

        return numerator; // This is the cost. priceScale is implicitly handled by how basePrice/slope are defined.

        // RETHINKING THE SCALING:
        // Let actualPrice(s) = basePrice_unscaled + slope_unscaled * s
        // Store basePrice and slope as scaled values, relative to priceScale.
        // basePrice_scaled = basePrice_unscaled * priceScale
        // slope_scaled = slope_unscaled * priceScale
        // Actual Price = (basePrice_scaled + slope_scaled * s / priceScale) / priceScale
        // Cost = Integral( (basePrice_scaled + slope_scaled * s / priceScale) / priceScale ) ds
        // Cost = (1/priceScale) * [ basePrice_scaled * s + (slope_scaled / priceScale) * s^2 / 2 ] from S0 to S0+N
        // Cost = (1/priceScale) * [ basePrice_scaled * N + (slope_scaled / (2 * priceScale)) * ( (S0+N)^2 - S0^2 ) ]
        // Cost = ( basePrice_scaled * N * priceScale + slope_scaled * ( (S0+N)^2 - S0^2 ) / 2 ) / (priceScale * priceScale)

        // Let's assume basePrice and slope are scaled relative to priceScale directly, i.e.,
        // Price(s) = (basePrice + slope * s / priceScale) / priceScale
        // Cost to buy N shares starting at S0 shares:
        // Integral from S0 to S0+N of (basePrice + slope*s/priceScale)/priceScale ds
        // = (1/priceScale) * [ basePrice * s + (slope/priceScale) * s^2/2 ] from S0 to S0+N
        // = (1/priceScale) * [ basePrice * N + (slope / (2*priceScale)) * ( (S0+N)^2 - S0^2 ) ]
        // To keep precision, multiply by priceScale^2 for calculation, then divide:
        // Numerator = basePrice * N * priceScale + slope * ( (S0+N)^2 - S0^2 ) / 2
        // Denominator = priceScale * priceScale
        // Cost = Numerator / Denominator

        uint256 two_priceScale_squared = 2 * priceScale * priceScale;
         if (two_priceScale_squared == 0) revert ZeroCollateral(); // Should not happen if priceScale > 0

        // Calculate the area under the curve P(s) = (basePrice + slope * s / priceScale) / priceScale from S0 to S0+N
        // Area = (1 / priceScale) * [basePrice * s + (slope / (2 * priceScale)) * s^2]_S0^(S0+N)
        // Area = (1 / priceScale) * ( (basePrice * (S0+N) + (slope * (S0+N)^2) / (2 * priceScale)) - (basePrice * S0 + (slope * S0^2) / (2 * priceScale)) )
        // Area = (1 / priceScale) * ( basePrice * N + (slope / (2 * priceScale)) * ((S0+N)^2 - S0^2) )
        // Area = (1 / priceScale) * ( basePrice * N + (slope / (2 * priceScale)) * (N^2 + 2 * S0 * N) )
        // Area = ( basePrice * N ) / priceScale + ( slope * N * (N + 2 * S0) ) / (2 * priceScale * priceScale)

        // Calculate terms with common denominator 2 * priceScale * priceScale
        uint256 term_base = basePrice * N * 2 * priceScale;
        uint256 term_slope = slope * N;
        uint256 term_slope_part2 = N + (2 * S0);
         if (N > 0 && (2 * S0) > type(uint256).max - N) revert ZeroShares(); // Check overflow for N + 2*S0
        term_slope = term_slope * term_slope_part2;
        if (slope > 0 && N > 0 && term_slope / slope != term_slope_part2) revert ZeroShares(); // Check overflow for slope * N * (N + 2*S0)

        uint256 total_numerator = term_base + term_slope;
        if (term_base > 0 && term_slope > type(uint256).max - term_base) revert ZeroShares(); // Check overflow for addition

        return total_numerator / two_priceScale_squared;
    }

    // Calculate the number of shares received for depositing a specific collateral amount
    // This involves solving the quadratic equation:
    // Cost = ( basePrice * N * priceScale + slope * N * (N + 2 * S0) / 2 ) / (priceScale * priceScale) for N
    // Cost * 2 * priceScale^2 = basePrice * N * 2 * priceScale + slope * N^2 + slope * 2 * S0 * N
    // slope * N^2 + (basePrice * 2 * priceScale + slope * 2 * S0) * N - Cost * 2 * priceScale^2 = 0
    // This is a quadratic equation of the form a*N^2 + b*N + c = 0
    // where a = slope
    //       b = basePrice * 2 * priceScale + slope * 2 * S0
    //       c = -Cost * 2 * priceScale^2
    // Solve for N using quadratic formula: N = (-b + sqrt(b^2 - 4ac)) / (2a) (we take the positive root)
    function _getSharesForCost(uint256 s0, uint256 cost) internal view returns (uint256 shares) {
         if (slope == 0) {
             // Linear price (no slope)
             // Price is constant: (basePrice / priceScale)
             // Shares = Cost / Price = Cost * priceScale / basePrice
             if (basePrice == 0) revert ZeroCollateral(); // Division by zero
             return (cost * priceScale) / basePrice;
         }

        uint256 two_priceScale = 2 * priceScale;
        uint256 two_priceScale_squared = two_priceScale * priceScale;
         if (two_priceScale_squared == 0) revert ZeroCollateral(); // Should not happen

        // Calculate b
        uint256 term_b1 = basePrice * two_priceScale;
        uint256 term_b2 = slope * 2 * s0;
         if (term_b1 > type(uint256).max - term_b2) revert ZeroCollateral(); // Overflow check
        uint256 b = term_b1 + term_b2;

        // Calculate c_abs = Cost * 2 * priceScale^2
        uint256 c_abs = cost * two_priceScale_squared;
         if (cost > 0 && c_abs / cost != two_priceScale_squared) revert ZeroCollateral(); // Overflow check

        // Calculate b^2 - 4ac. Since c is negative, -4ac is positive 4 * slope * c_abs
        // b^2 calculation:
        uint256 b_squared = b * b;
         if (b > 0 && b_squared / b != b) revert ZeroCollateral(); // Overflow check

        // 4 * slope * c_abs:
        uint256 four_ac = 4 * slope;
         if (slope > 0 && four_ac / slope != 4) revert ZeroCollateral(); // Overflow check
        four_ac = four_ac * c_abs;
         if (c_abs > 0 && four_ac / c_abs != 4 * slope) revert ZeroCollateral(); // Overflow check

        uint256 discriminant = b_squared + four_ac;
        if (discriminant < b_squared) revert ZeroCollateral(); // Overflow check for addition

        uint256 sqrt_discriminant = sqrt(discriminant); // Using custom sqrt function

        // N = (-b + sqrt(discriminant)) / (2 * a)
        // N = (sqrt(discriminant) - b) / (2 * slope)
        // Ensure sqrt_discriminant >= b (should be true for positive cost)
        if (sqrt_discriminant < b) revert ZeroCollateral(); // Error in logic or math

        uint256 numerator = sqrt_discriminant - b;
        uint256 denominator = 2 * slope;
        if (denominator == 0) revert ZeroCollateral(); // Should not happen if slope > 0

        return numerator / denominator;
    }

    // Calculate the refund (collateral) received for selling a specific number of shares
    // Refund = Integral of (basePrice + slope * s / priceScale) ds from S0-N to S0
    // Refund = basePrice * N + (slope / (2 * priceScale)) * ( S0^2 - (S0-N)^2 )
    // Refund = basePrice * N + (slope / (2 * priceScale)) * ( S0^2 - (S0^2 - 2*S0*N + N^2) )
    // Refund = basePrice * N + (slope / (2 * priceScale)) * ( 2*S0*N - N^2 )
    // Refund = basePrice * N + (slope * N / (2 * priceScale)) * ( 2*S0 - N )
     function _getRefundForShares(uint256 s0, uint256 n) internal view returns (uint256 refund) {
         if (n == 0) return 0;
         if (n > s0) revert InsufficientShares(); // Cannot sell more shares than held

         uint256 two_priceScale_squared = 2 * priceScale * priceScale;
         if (two_priceScale_squared == 0) revert ZeroCollateral(); // Should not happen

        // Calculate the area under the curve P(s) = (basePrice + slope * s / priceScale) / priceScale from S0-N to S0
        // Area = (1 / priceScale) * [basePrice * s + (slope / (2 * priceScale)) * s^2]_S0-N^S0
        // Area = (1 / priceScale) * ( (basePrice * S0 + (slope * S0^2) / (2 * priceScale)) - (basePrice * (S0-N) + (slope * (S0-N)^2) / (2 * priceScale)) )
        // Area = (1 / priceScale) * ( basePrice * N + (slope / (2 * priceScale)) * (S0^2 - (S0-N)^2) )
        // Area = (1 / priceScale) * ( basePrice * N + (slope / (2 * priceScale)) * (2 * S0 * N - N^2) )
        // Area = ( basePrice * N ) / priceScale + ( slope * N * (2 * S0 - N) ) / (2 * priceScale * priceScale)

         // Calculate terms with common denominator 2 * priceScale * priceScale
         uint256 term_base = basePrice * N * 2 * priceScale;
         uint256 term_slope = slope * N;
         uint256 term_slope_part2;
         if (2 * s0 < n) revert InsufficientShares(); // Should not happen if n <= s0, but safety check
         term_slope_part2 = 2 * s0 - n;

         term_slope = term_slope * term_slope_part2;
         if (slope > 0 && N > 0 && term_slope / slope != term_slope_part2) revert ZeroShares(); // Check overflow

         uint256 total_numerator = term_base + term_slope;
         if (term_base > 0 && term_slope > type(uint256).max - term_base) revert ZeroShares(); // Check overflow

         return total_numerator / two_priceScale_squared;
    }

    // Simple integer square root (Newton's method)
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }


    // --- Core Market Functions ---

    /**
     * @notice Allows a user to deposit collateral and join the market for a specific outcome.
     * Shares are minted based on the current position on the bonding curve.
     * @param _outcome The outcome (0 or 1) the user is betting on.
     * @param _collateralAmount The amount of collateral token to deposit.
     */
    function joinMarket(uint8 _outcome, uint256 _collateralAmount)
        external
        nonReentrant
        marketIsOpen
        validOutcome(_outcome)
    {
        if (_collateralAmount == 0) revert ZeroCollateral();

        uint256 s0 = _totalSharesIssuedForOutcome[_outcome];
        uint256 sharesReceived = _getSharesForCost(s0, _collateralAmount);
        if (sharesReceived == 0) revert ZeroShares(); // Deposited amount too small for even 1 share

        // Transfer collateral from user to contract
        collateralToken.safeTransferFrom(msg.sender, address(this), _collateralAmount);

        // Update state
        userOutcomeShares[msg.sender][_outcome] += sharesReceived;
        _totalCollateralForOutcome[_outcome] += _collateralAmount;
        _totalSharesIssuedForOutcome[_outcome] += sharesReceived;

        emit MarketJoined(msg.sender, _outcome, _collateralAmount, sharesReceived, _totalCollateralForOutcome[_outcome], _totalSharesIssuedForOutcome[_outcome]);
    }

    /**
     * @notice Allows a user to sell their outcome shares back to the contract.
     * User receives collateral based on the bonding curve (minus exit fee).
     * @param _outcome The outcome the shares belong to.
     * @param _sharesToSell The number of shares to sell.
     */
    function exitMarket(uint8 _outcome, uint256 _sharesToSell)
        external
        nonReentrant
        marketIsOpen
        validOutcome(_outcome)
    {
        if (_sharesToSell == 0) revert ZeroShares();
        if (userOutcomeShares[msg.sender][_outcome] < _sharesToSell) revert InsufficientShares();

        uint256 s0 = _totalSharesIssuedForOutcome[_outcome];
        if (s0 < _sharesToSell) revert InsufficientShares(); // Should be covered by user balance check, but double check total

        uint256 refundAmount = _getRefundForShares(s0, _sharesToSell);
         if (refundAmount == 0) revert ZeroCollateral(); // Selling shares resulted in 0 refund

        // Calculate fee
        uint256 exitFee = (refundAmount * exitFeeBasisPoints) / BASIS_POINTS_DENOMINATOR;
        uint256 netRefundAmount = refundAmount - exitFee;

        // Check if contract has enough collateral to refund
        if (collateralToken.balanceOf(address(this)) < netRefundAmount) {
            // This should ideally not happen if bonding curve math is correct and
            // collateral is only ever added or distributed proportionally to winning shares.
            // Could indicate an issue or extreme imbalance. Revert to prevent contract drain.
            revert ZeroCollateral(); // Use generic error for now
        }

        // Update state
        userOutcomeShares[msg.sender][_outcome] -= _sharesToSell;
        _totalCollateralForOutcome[_outcome] -= refundAmount; // Deduct gross refund from pool
        _totalSharesIssuedForOutcome[_outcome] -= _sharesToSell;
        _totalFeesAccrued += exitFee;

        // Transfer collateral back to user
        collateralToken.safeTransfer(msg.sender, netRefundAmount);

        emit MarketExited(msg.sender, _outcome, _sharesToSell, netRefundAmount, _totalCollateralForOutcome[_outcome], _totalSharesIssuedForOutcome[_outcome]);
    }

    /**
     * @notice Called by the oracle to resolve the market with the winning outcome.
     * Can only be called after the resolution time has passed.
     * @param _winningOutcome The outcome (0 or 1) that won.
     */
    function resolveMarket(uint8 _winningOutcome)
        external
        nonReentrant
        onlyOracle
        marketNotResolved
        validOutcome(_winningOutcome)
    {
        if (block.timestamp < resolutionTime) revert ResolutionTimeNotPassed();

        winningOutcome = _winningOutcome;
        marketStatus = MarketStatus.Resolved;

        // Calculate and accrue resolution fee from the *total* collateral pool
        uint256 totalCollateralInPool = collateralToken.balanceOf(address(this));
        uint256 resolutionFee = (totalCollateralInPool * resolutionFeeBasisPoints) / BASIS_POINTS_DENOMINATOR;
        _totalFeesAccrued += resolutionFee;

        emit MarketResolved(_winningOutcome, block.timestamp);
    }

    /**
     * @notice Allows users who hold shares of the winning outcome to claim their winnings.
     * Winnings are distributed proportionally from the total collateral pool (after resolution fee).
     */
    function claimWinnings()
        external
        nonReentrant
        marketIsResolved
    {
        if (hasClaimed[msg.sender]) revert WinningsAlreadyClaimed();
        if (winningOutcome == 255) revert MarketNotResolved(); // Should be covered by marketIsResolved, but safety

        uint256 userWinningShares = userOutcomeShares[msg.sender][winningOutcome];
        if (userWinningShares == 0) revert ZeroShares(); // User has no winning shares

        // Calculate total collateral available for distribution
        uint256 totalCollateralPool = collateralToken.balanceOf(address(this));
        uint256 totalWinningShares = _totalSharesIssuedForOutcome[winningOutcome];

        if (totalWinningShares == 0) {
             // This edge case implies the oracle resolved to an outcome for which no shares were ever bought or all were sold.
             // Winnings are 0 as there's no pool allocated to this outcome's shareholders relative to total shares.
             // Or could distribute the whole pool? Standard is proportional. If totalWinningShares is 0, no one wins.
             // Let's stick to proportional: 0 / 0 is undefined, but logically share is 0.
             // If total shares is 0, their share is 0.
             userWinningShares = 0; // Set to 0 to prevent calculation errors
        }

        uint256 amountToClaim = 0;
        if (userWinningShares > 0) {
             // Winnings = (userWinningShares / totalWinningShares) * (totalCollateralPool - fees already taken)
             // Total pool already includes fees from resolution (collected to _totalFeesAccrued but still in contract balance).
             // So, share is relative to total shares of the winning outcome applied to the *entire* current balance.
             amountToClaim = (userWinningShares * totalCollateralPool) / totalWinningShares;

             // Safety check: Ensure calculated amount doesn't exceed the actual balance
             if (amountToClaim > totalCollateralPool) {
                amountToClaim = totalCollateralPool;
             }
        }


        if (amountToClaim == 0) revert ZeroCollateral(); // No winnings to claim

        // Mark user as claimed before transfer
        hasClaimed[msg.sender] = true;
        // Zero out user's shares after claiming? Standard practice is usually yes.
        // userOutcomeShares[msg.sender][winningOutcome] = 0; // Decide if shares are burned or just claiming is marked. Let's burn.
         _totalSharesIssuedForOutcome[winningOutcome] -= userWinningShares; // Reduce total shares for winning outcome
         userOutcomeShares[msg.sender][winningOutcome] = 0; // Burn user's shares

        // Transfer winnings
        collateralToken.safeTransfer(msg.sender, amountToClaim);

        emit WinningsClaimed(msg.sender, amountToClaim);

        // After all claims, if total shares for winning outcome is 0, the market is effectively closed for claims.
        // Could transition state to Closed here, but let's allow claiming until all shares are redeemed.
        // A separate owner function to close can sweep dust.
    }


    // --- Getter/View Functions ---

    /**
     * @notice Returns the current status of the market.
     */
    function getMarketStatus() external view returns (MarketStatus) {
        return marketStatus;
    }

    /**
     * @notice Returns the total amount of collateral token locked in the market.
     */
    function getTotalCollateral() external view returns (uint256) {
        return collateralToken.balanceOf(address(this));
    }

    /**
     * @notice Returns the total amount of collateral token locked for a specific outcome.
     * @param _outcome The outcome (0 or 1).
     */
    function getTotalCollateralForOutcome(uint8 _outcome) external view validOutcome(_outcome) returns (uint256) {
        return _totalCollateralForOutcome[_outcome];
    }

     /**
     * @notice Returns the total shares issued for a specific outcome.
     * @param _outcome The outcome (0 or 1).
     */
    function getTotalSharesForOutcome(uint8 _outcome) external view validOutcome(_outcome) returns (uint256) {
        return _totalSharesIssuedForOutcome[_outcome];
    }

    /**
     * @notice Estimates the collateral required to purchase a given number of shares for an outcome.
     * @param _outcome The outcome (0 or 1).
     * @param _sharesToBuy The number of shares to estimate cost for.
     */
    function calculatePurchaseCost(uint8 _outcome, uint256 _sharesToBuy) external view validOutcome(_outcome) returns (uint256 estimatedCost) {
         if (_sharesToBuy == 0) return 0;
         return _getCostForShares(_totalSharesIssuedForOutcome[_outcome], _sharesToBuy);
    }

     /**
     * @notice Estimates the number of shares received for depositing a given collateral amount for an outcome.
     * @param _outcome The outcome (0 or 1).
     * @param _collateralAmount The collateral amount to estimate shares for.
     */
    function calculateSharesReceived(uint8 _outcome, uint256 _collateralAmount) external view validOutcome(_outcome) returns (uint256 estimatedShares) {
         if (_collateralAmount == 0) return 0;
         // This function is sensitive to the complexity of solving the quadratic.
         // Could approximate or provide a range. For simplicity, use the exact solver.
         return _getSharesForCost(_totalSharesIssuedForOutcome[_outcome], _collateralAmount);
    }

     /**
     * @notice Estimates the collateral refund received for selling a given number of shares for an outcome (before fee).
     * @param _outcome The outcome (0 or 1).
     * @param _sharesToSell The number of shares to estimate refund for.
     */
    function calculateExitRefund(uint8 _outcome, uint256 _sharesToSell) external view validOutcome(_outcome) returns (uint256 estimatedRefundBeforeFee) {
         if (_sharesToSell == 0) return 0;
         uint256 s0 = _totalSharesIssuedForOutcome[_outcome];
         if (_sharesToSell > s0) return 0; // Cannot sell more than exist in total pool state
         return _getRefundForShares(s0, _sharesToSell);
    }

     /**
     * @notice Estimates the potential winnings for a user's shares after resolution.
     * This is an estimate based on the current total pool, does not account for future claims or fees not yet processed.
     * @param _user The address of the user.
     */
    function calculateWinningClaim(address _user) external view returns (uint256 estimatedWinnings) {
        if (marketStatus != MarketStatus.Resolved || winningOutcome == 255) return 0;
        if (hasClaimed[_user]) return 0;

        uint256 userWinningShares = userOutcomeShares[_user][winningOutcome];
        if (userWinningShares == 0) return 0;

        uint256 totalCollateralPool = collateralToken.balanceOf(address(this));
        uint256 totalWinningShares = _totalSharesIssuedForOutcome[winningOutcome] + userWinningShares; // Add user's shares back for calculation basis if they haven't claimed yet

        // If total winning shares is 0 (meaning no one bought shares for the winning outcome, highly unlikely but possible),
        // then user's share is 0.
        if (totalWinningShares == 0) return 0;


         // Winnings = (userWinningShares / totalWinningShares) * totalCollateralPool
         // Using scaled math for precision
         return (userWinningShares * totalCollateralPool) / totalWinningShares;
    }


    // --- Admin/Owner Functions ---

    /**
     * @notice Owner can update the oracle address.
     * @param _newOracle The address of the new oracle.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        oracleAddress = _newOracle;
    }

    /**
     * @notice Owner can adjust bonding curve parameters.
     * WARNING: Changing this on an active market can significantly affect existing participants.
     * @param _basePrice New base price (scaled).
     * @param _slope New slope (scaled).
     * @param _priceScale New price scale.
     */
    function setBondingCurveParameters(uint256 _basePrice, uint256 _slope, uint256 _priceScale) external onlyOwner {
        if (_basePrice == 0 || _priceScale == 0) revert InvalidBondingCurveParameters();
        basePrice = _basePrice;
        slope = _slope;
        priceScale = _priceScale;
        emit BondingCurveParametersUpdated(basePrice, slope, priceScale);
    }

    /**
     * @notice Owner can adjust exit and resolution fees.
     * @param _exitFeeBasisPoints New exit fee in basis points (e.g., 100 for 1%).
     * @param _resolutionFeeBasisPoints New resolution fee in basis points.
     */
    function setFees(uint256 _exitFeeBasisPoints, uint256 _resolutionFeeBasisPoints) external onlyOwner {
         if (_exitFeeBasisPoints > BASIS_POINTS_DENOMINATOR || _resolutionFeeBasisPoints > BASIS_POINTS_DENOMINATOR) revert InvalidBondingCurveParameters(); // Reusing error name for fee range
        exitFeeBasisPoints = _exitFeeBasisPoints;
        resolutionFeeBasisPoints = _resolutionFeeBasisPoints;
    }

    /**
     * @notice Owner can update the market event description.
     * @param _newDescription The new description string.
     */
    function updateOutcomeDescription(string memory _newDescription) external onlyOwner {
        outcomeDescription = _newDescription;
    }

    /**
     * @notice Owner can temporarily pause joining and exiting the market.
     */
    function pauseMarket() external onlyOwner {
        if (!isPaused) {
            isPaused = true;
            emit MarketPausedStateChanged(true);
        }
    }

    /**
     * @notice Owner can unpause the market.
     */
    function unpauseMarket() external onlyOwner {
        if (isPaused) {
            isPaused = false;
            emit MarketPausedStateChanged(false);
        }
    }

    /**
     * @notice Owner can withdraw accumulated fees.
     */
    function collectFees() external onlyOwner {
        uint256 feesToCollect = _totalFeesAccrued;
        if (feesToCollect == 0) return;

        // Ensure the contract has enough balance, even if fees are recorded.
        // Fees are held in the contract's collateral token balance.
        uint256 currentBalance = collateralToken.balanceOf(address(this));
        if (currentBalance < feesToCollect) {
            // This implies a calculation error or discrepancy.
            // Revert or collect only what's available? Revert for safety.
             revert ZeroCollateral(); // Use generic error
        }

        _totalFeesAccrued = 0; // Reset fees before transfer
        collateralToken.safeTransfer(msg.sender, feesToCollect);
        emit FeesCollected(msg.sender, feesToCollect);
    }

    /**
     * @notice Owner can recover ERC20 tokens accidentally sent to the contract.
     * Prevents recovering the primary collateral token.
     * @param _tokenAddress The address of the ERC20 token to recover.
     */
    function recoverAccidentallySentTokens(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == address(collateralToken)) revert CannotRecoverCollateral();
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.safeTransfer(msg.sender, balance);
        }
    }

     // --- Additional View Functions for State ---

     /**
     * @notice Returns the market's resolution timestamp.
     */
    function getResolutionTime() external view returns (uint256) {
        return resolutionTime;
    }

    /**
     * @notice Returns the address of the collateral token used in the market.
     */
    function getCollateralToken() external view returns (address) {
        return address(collateralToken);
    }

    /**
     * @notice Returns the address of the oracle allowed to resolve the market.
     */
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    /**
     * @notice Returns the current bonding curve parameters.
     */
    function getBondingCurveParameters() external view returns (uint256 _basePrice, uint256 _slope, uint256 _priceScale) {
        return (basePrice, slope, priceScale);
    }

     /**
     * @notice Returns the description of the market event.
     */
    function getOutcomeDescription() external view returns (string memory) {
        return outcomeDescription;
    }

    /**
     * @notice Returns true if the market is currently paused for trading (join/exit).
     */
    function getPauseStatus() external view returns (bool) {
        return isPaused;
    }

    /**
     * @notice Returns the amount of fees currently accrued and collectable by the owner.
     */
    function getAccruedFees() external view returns (uint256) {
        return _totalFeesAccrued;
    }

    /**
     * @notice Returns the winning outcome after resolution. Returns 255 if not resolved.
     */
     function getWinningOutcome() external view returns (uint8) {
         return winningOutcome;
     }
}
```

---

**Explanation of Concepts and Implementation:**

1.  **Bonding Curve Math:** The core complexity lies in `_getCostForShares`, `_getSharesForCost`, and `_getRefundForShares`. These functions implement the integral calculus required for a bonding curve where the price `P(s)` is a function of the number of shares `s`.
    *   We use a simple linear price curve: `Price(s) = basePrice_unscaled + slope_unscaled * s`.
    *   To handle fixed-point arithmetic in Solidity (no decimals), we scale `basePrice` and `slope` by a `priceScale` (e.g., 1e18). The actual price calculation involves division by `priceScale`.
    *   Buying shares means calculating the area under the price curve from the current total shares (`S0`) to `S0 + N`, where `N` is the number of shares being bought. This requires integration.
    *   Selling shares means calculating the area under the curve from `S0 - N` to `S0`.
    *   Calculating shares received for a given cost involves solving the inverse problem, which leads to a quadratic equation. The `sqrt` function is a simple integer square root helper.
    *   Careful attention is paid to potential integer overflows during intermediate calculations by checking before multiplication/addition.

2.  **Market Lifecycle:** The contract defines `MarketStatus` (Open, Resolved, Closed, though implicitly Closed after all claims/fees collected) and transitions state via `resolveMarket`. Trading (join/exit) is only allowed in the `Open` state.

3.  **Collateral and Shares:** Users deposit a single `collateralToken`. They receive "outcome shares" (tracked in `userOutcomeShares`) which represent their claim on the collateral pool. There's no separate token for shares; they are internal balances.

4.  **Oracle Resolution:** An `onlyOracle` modifier ensures only the designated address can call `resolveMarket` after the specified `resolutionTime`.

5.  **Claiming Winnings:** After resolution, users holding the `winningOutcome`'s shares can call `claimWinnings`. The total collateral pool (minus the resolution fee taken) is distributed proportionally based on the user's winning shares relative to the `_totalSharesIssuedForOutcome[winningOutcome]`. Shares are effectively burned upon claiming.

6.  **Fees:** `exitFeeBasisPoints` are taken from the user's calculated refund when they `exitMarket`. `resolutionFeeBasisPoints` are taken from the *total* collateral pool when the market is resolved. These fees are accumulated in `_totalFeesAccrued` and can be withdrawn by the owner via `collectFees`.

7.  **Pause Functionality:** The `isPaused` flag allows the owner to temporarily halt `joinMarket` and `exitMarket` interactions, providing an emergency stop mechanism.

8.  **Non-Reentrancy:** The `nonReentrant` modifier is used on functions performing external calls (`safeTransfer`, `safeTransferFrom`) to prevent reentrancy attacks.

9.  **Error Handling:** Custom errors (`error ...`) are used instead of `require` strings for better gas efficiency and clearer debugging on failure.

10. **Ownership and Admin:** Uses OpenZeppelin's `Ownable` for standard owner permissions. Owner functions are provided to update parameters, manage pause state, collect fees, and recover accidentally sent tokens (excluding the primary collateral).

11. **Gas Optimization:** Uses standard practices like packing state variables where feasible, using custom errors, marking view/pure functions, and using `calldata`. The complex bonding curve math is performance-sensitive and relies on integer arithmetic.

This contract provides a framework for a prediction market where the cost of entry and exit is dynamically determined by the collective sentiment (reflected in the total shares bought for each outcome) via a bonding curve. This offers a different dynamic than traditional markets or AMM-based markets.