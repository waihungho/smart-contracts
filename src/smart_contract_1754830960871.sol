This smart contract, **AetherFlow**, is designed as a dynamic lending and borrowing protocol that adapts its core economic parameters based on real-time market conditions and user behavior. It aims to showcase advanced concepts such as:

*   **Self-Amending Policy Engine:** The protocol's rules (e.g., interest rate curves, collateral ratio thresholds) are not hardcoded but are dynamically stored and can be updated through governance. Furthermore, certain parameters can *autonomously adjust* within defined boundaries based on market data, without requiring a full governance vote for every minor fluctuation.
*   **Contextualized DeFi Parameters:** Interest rates, collateralization ratios, and liquidation bonuses are not static. Instead, they are derived from a multi-faceted **Market Health Index (MHI)**, which reflects various market states (e.g., volatility, liquidity, sentiment from an oracle). This makes the protocol highly responsive to market dynamics.
*   **Adaptive User Risk Scoring:** Each user has a dynamic behavioral risk score that influences their borrowing terms (e.g., slightly better rates for reliable repayers, stricter terms for those with liquidation history).
*   **Dynamic Incentives:** Reward structures for liquidity providers and borrowers can also change based on the MHI, encouraging desired market behaviors.

The goal is to create a more resilient, adaptive, and efficient DeFi protocol that can navigate volatile market conditions with built-in flexibility.

---

## AetherFlow: Dynamic Liquidity & Adaptive Governance Protocol

**Solidity Version:** `^0.8.20`
**Dependencies:** OpenZeppelin Contracts (for `IERC20`, `Ownable`, `ReentrancyGuard`, `SafeMath`)

---

### Outline and Function Summary

**I. CORE DATA STRUCTURES & ENUMS**
*   `PolicyParameterType`: Enum defining types of parameters that can be dynamically adjusted (e.g., InterestRateCurve, CollateralRatioCurve).
*   `CurvePoint`: Struct for defining points on dynamic curves (x, y coordinates).
*   `PolicyRule`: Struct defining the rules for dynamic adjustment for each parameter type, including current data (ABI-encoded curve points), adjustment bounds, and intervals.
*   `MarketHealthIndex`: Struct storing the aggregated MHI value and its last update timestamp.
*   `Loan`: Struct for detailed loan information.
*   `PolicyAmendment`: Struct for governance proposals to modify policy rules.

**II. STATE VARIABLES**
*   `s_marketHealthIndex`: Current global Market Health Index.
*   `s_oracleAddress`: Trusted address for updating MHI.
*   `s_governanceToken`: Address of the token used for governance voting (simplified for this example).
*   `s_paused`: Protocol pause status.
*   `s_totalLiquidity`: Total deposited liquidity per asset.
*   `s_userLiquidity`: User's deposited liquidity per asset.
*   `s_loans`, `s_nextLoanId`, `s_userActiveLoans`: Loan management.
*   `s_userBehavioralScore`: Dynamic risk score for each user.
*   `s_isSupportedAsset`: Whitelist for supported ERC20 assets.
*   `s_policyRules`: Mapping from `PolicyParameterType` to its `PolicyRule` definition.
*   `s_policyAmendments`, `s_nextProposalId`, `s_voteDuration`: Governance proposal tracking.
*   `s_whitelistedAccess`: For special user access.
*   `s_accruedIncentives`: Basic incentive tracking (simplified).

**III. EVENTS**
*   Comprehensive events for transparency and off-chain indexing of all key actions and parameter changes.

**IV. MODIFIERS**
*   `onlyOracle`: Restricts function access to the trusted oracle.
*   `onlyGovernance`: Restricts function access to the contract owner or governance token holder (simplified).
*   `whenNotPaused`: Prevents execution if the protocol is paused.
*   `whenPaused`: Allows execution only if the protocol is paused (e.g., for emergency actions).

**V. CORE PROTOCOL LOGIC (Lending & Borrowing)**

1.  `depositLiquidity(address asset, uint256 amount)`:
    *   Allows users to deposit ERC20 tokens into a liquidity pool. Funds contribute to overall pool depth, influencing the MHI and eligibility for dynamic incentives.
2.  `withdrawLiquidity(address asset, uint256 amount)`:
    *   Enables users to withdraw their deposited tokens. Dynamic withdrawal limits/fees based on MHI could be integrated.
3.  `borrowFunds(address asset, uint256 amount, address collateralAsset, uint256 collateralAmount)`:
    *   Allows users to borrow funds against collateral. Interest rate and required collateral ratio are dynamically calculated based on the current MHI and the borrower's adaptive risk score.
4.  `repayLoan(uint256 loanId, uint256 amount)`:
    *   Enables borrowers to repay their loans. Successful repayments positively influence the borrower's behavioral risk score.
5.  `liquidateLoan(uint256 loanId)`:
    *   Allows third parties (liquidators) to repay under-collateralized loans. The liquidation bonus for liquidators is dynamically adjusted by the MHI, incentivizing stability.

**VI. MARKET HEALTH INDEX (MHI) & ORACLE INTEGRATION**

6.  `updateMarketHealthIndex(uint256 newMHI, uint256 timestamp)`:
    *   Callable by a trusted oracle to update the global Market Health Index. This index is crucial for all dynamic parameter adjustments.
7.  `getMarketHealthIndex()`:
    *   Returns the current global Market Health Index.

**VII. ADAPTIVE POLICY ENGINE & GOVERNANCE**

8.  `proposePolicyAmendment(PolicyParameterType paramType, bytes calldata newData)`:
    *   Initiates a governance proposal to modify a specific protocol parameter's underlying logic. This means changing *how* a parameter is derived (e.g., updating a curve's definition, modifying an adjustment algorithm) rather than just a fixed value.
9.  `voteOnPolicyAmendment(uint256 proposalId, bool support)`:
    *   Allows governance token holders to vote on proposed policy amendments. (Simplified voting power for this example).
10. `executePolicyAmendment(uint256 proposalId)`:
    *   Executes a passed policy amendment, updating the contract's internal logic and parameters with the new rules/data.
11. `triggerAdaptiveAdjustment()`:
    *   Callable by anyone (potentially incentivized via a keeper network) to initiate an automated adjustment of dynamic parameters. This mechanism allows for autonomous parameter "drift" within governance-defined limits and intervals, reducing governance overhead for minor market fluctuations.
12. `getAdjustedParameterValue(PolicyParameterType paramType)`:
    *   Returns the currently active, dynamically calculated value for a specific protocol parameter based on the current MHI.

**VIII. USER RISK SCORING & BEHAVIORAL ADJUSTMENTS**

13. `getUserRiskScore(address user)`:
    *   Calculates and returns a dynamic risk score for a user, based on their on-chain behavior (e.g., repayment history, liquidation events).
14. `_updateUserBehavioralScore(address user, bool success)`:
    *   Internal helper function to update a user's behavioral score after key events like loan repayments or liquidations, integrating behavioral economics into lending terms.
15. `grantWhitelistedAccess(address user, bool status)`:
    *   Allows governance to whitelist users for specific advanced features or potentially more favorable terms, possibly based on their high internal risk score or external vetting.

**IX. INCENTIVES & REWARDS**

16. `claimDynamicIncentives(address asset)`:
    *   Allows liquidity providers and borrowers to claim their accrued incentives. Incentive rates are dynamically adjusted by MHI to encourage desired behavior (e.g., higher LP rewards during low liquidity).
17. `setIncentiveWeights(PolicyParameterType incentiveType, bytes calldata newWeights)`:
    *   Governance function to adjust the weighting algorithms or curves for dynamic incentives, allowing fine-tuning of reward distribution.

**X. GOVERNANCE & EMERGENCY FUNCTIONS**

18. `setOracleAddress(address _oracle)`:
    *   Governance function to update the trusted oracle address that provides the MHI.
19. `setSupportedAsset(address _asset, bool _isSupported)`:
    *   Governance function to add or remove supported ERC20 assets for lending/borrowing.
20. `setLiquidationBonusCurve(bytes calldata newCurveData)`:
    *   Governance function to update the curve that defines the dynamic liquidation bonus.
21. `pauseProtocol(bool _paused)`:
    *   An emergency function allowing governance to pause critical operations of the protocol in unforeseen circumstances.
22. `rescueFunds(address tokenAddress, uint256 amount)`:
    *   Enables governance to retrieve ERC20 tokens that were accidentally sent to the contract address.

**XI. INTERNAL HELPER FUNCTIONS**
*   `_calculateCurrentInterest`: Calculates outstanding interest on a loan based on time and dynamic rates.
*   `_calculateDynamicInterestRate`, `_calculateDynamicCollateralRatio`: Internal functions to derive parameters from MHI and stored curves.
*   `_getLiquidationThreshold`: Calculates the dynamic collateral threshold at which a loan becomes liquidatable.
*   `_getLoanHealth`: Computes the current health of a loan (collateral value vs. outstanding debt).
*   `_applyDynamicParameter`: A generic function to decode and apply MHI-based calculations from ABI-encoded `PolicyRule` data.
*   `_interpolateCurve`: A pure function for linear interpolation on `CurvePoint` arrays.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for older Solidity versions, or for clarity, though 0.8+ handles overflow/underflow by default

/**
 * @title AetherFlow: Dynamic Liquidity & Adaptive Governance Protocol
 * @dev AetherFlow is an advanced DeFi lending/borrowing protocol where core economic parameters
 *      (interest rates, collateral ratios, liquidation bonuses) are not static but dynamically
 *      adjusted based on a multi-factor "Market Health Index" (MHI) and user-specific risk scores.
 *      It features an adaptive policy engine that allows the protocol's governing parameters to
 *      evolve and self-adjust within defined boundaries, enabling resilient and responsive operation
 *      in varying market conditions without requiring constant governance intervention for minor tweaks.
 *      Governance focuses on defining the "rules of adjustment" rather than individual parameter values.
 */

// --- OUTLINE AND FUNCTION SUMMARY ---

// I. CORE DATA STRUCTURES & ENUMS
//    - PolicyParameterType: Enum for types of parameters that can be dynamically adjusted.
//    - CurvePoint: Struct for defining points on dynamic curves (x, y coordinates).
//    - PolicyRule: Struct defining the rules for dynamic adjustment (current data, bounds, adjustment interval).
//    - MarketHealthIndex: Struct for MHI details (value, timestamp).
//    - Loan: Struct for loan details.
//    - PolicyAmendment: Struct for governance proposals.

// II. STATE VARIABLES
//    - Global state (MHI, paused status, supported assets, etc.)
//    - Mappings for loans, user balances, user risk scores.
//    - Mappings for dynamic policy rules and governance proposals.

// III. EVENTS
//    - For transparency and off-chain indexing.

// IV. MODIFIERS
//    - `onlyOracle`: Restricts access to trusted oracle address.
//    - `onlyGovernance`: Restricts access to governance/owner.
//    - `whenNotPaused`: Prevents execution if protocol is paused.
//    - `whenPaused`: Allows execution only if protocol is paused (e.g., rescue functions).

// V. CORE PROTOCOL LOGIC (Lending & Borrowing)
//    1.  `depositLiquidity(address asset, uint256 amount)`:
//        - Allows users to deposit ERC20 tokens into a liquidity pool.
//        - **Advanced:** Funds contribute to overall pool depth, influencing MHI.
//    2.  `withdrawLiquidity(address asset, uint256 amount)`:
//        - Allows users to withdraw their deposited tokens.
//        - **Advanced:** Withdrawal limits/fees could dynamically adjust based on MHI.
//    3.  `borrowFunds(address asset, uint256 amount, address collateralAsset, uint256 collateralAmount)`:
//        - Enables users to borrow funds against collateral.
//        - **Advanced:** Interest rate and required collateral ratio are dynamically calculated based on MHI and user risk score.
//    4.  `repayLoan(uint256 loanId, uint256 amount)`:
//        - Allows borrowers to repay their loans.
//        - **Advanced:** Successfully repayments improve user's behavioral risk score.
//    5.  `liquidateLoan(uint256 loanId)`:
//        - Enables third parties (liquidators) to repay under-collateralized loans.
//        - **Advanced:** Liquidation bonus is dynamically adjusted by MHI.

// VI. MARKET HEALTH INDEX (MHI) & ORACLE INTEGRATION
//    6.  `updateMarketHealthIndex(uint256 newMHI, uint256 timestamp)`:
//        - Callable by a trusted oracle to update the global MHI.
//        - **Advanced:** MHI is a complex, multi-factor score (e.g., volatility, liquidity, sentiment).
//    7.  `getMarketHealthIndex()`:
//        - Returns the current Market Health Index.

// VII. ADAPTIVE POLICY ENGINE & GOVERNANCE
//    8.  `proposePolicyAmendment(PolicyParameterType paramType, bytes calldata newData)`:
//        - Initiates a governance proposal to modify a specific protocol parameter's underlying logic (e.g., update a curve, change an adjustment algorithm ID).
//        - **Advanced:** Not just changing a value, but changing *how* a value is derived.
//    9.  `voteOnPolicyAmendment(uint256 proposalId, bool support)`:
//        - Allows governance token holders to vote on proposed amendments.
//   10.  `executePolicyAmendment(uint256 proposalId)`:
//        - Executes a passed policy amendment, updating the contract's internal logic/parameters.
//   11.  `triggerAdaptiveAdjustment()`:
//        - Callable by anyone (incentivized keeper) to initiate an automated adjustment of dynamic parameters based on current MHI and predefined policy rules/bounds.
//        - **Advanced:** Autonomous parameter "drift" within governance-defined limits, reducing governance overhead for minor fluctuations.
//   12.  `getAdjustedParameterValue(PolicyParameterType paramType)`:
//        - Returns the currently active, dynamically calculated value for a specific protocol parameter based on the MHI.
//        - **Advanced:** Abstracts the complex MHI-based calculation logic.

// VIII. USER RISK SCORING & BEHAVIORAL ADJUSTMENTS
//   13.  `getUserRiskScore(address user)`:
//        - Calculates and returns a dynamic risk score for a user, based on their on-chain behavior (repayment history, participation, collateral health).
//        - **Advanced:** Behavioral economics integrated into lending terms.
//   14.  `_updateUserBehavioralScore(address user, bool success)`:
//        - Internal hook to update a user's behavioral score after key events.
//        - **Advanced:** Real-time adaptation of user profiles.
//   15.  `grantWhitelistedAccess(address user, bool status)`:
//        - Allows governance to whitelist users for specific advanced features or lower thresholds, potentially based on high internal risk scores or external vetting.

// IX. INCENTIVES & REWARDS
//   16.  `claimDynamicIncentives(address asset)`:
//        - Allows liquidity providers/borrowers to claim incentives, adjusted dynamically based on MHI and their contribution.
//        - **Advanced:** Incentive rates are dynamically adjusted by MHI to encourage desired behavior.
//   17.  `setIncentiveWeights(PolicyParameterType incentiveType, bytes calldata newWeights)`:
//        - Governance function to adjust the weighting algorithms for dynamic incentives.

// X. GOVERNANCE & EMERGENCY FUNCTIONS
//   18.  `setOracleAddress(address _oracle)`:
//        - Governance function to update the trusted oracle address.
//   19.  `setSupportedAsset(address _asset, bool _isSupported)`:
//        - Governance function to add or remove supported ERC20 assets for lending/borrowing.
//   20.  `setLiquidationBonusCurve(bytes calldata newCurveData)`:
//        - Governance function to update the curve defining the dynamic liquidation bonus.
//   21.  `pauseProtocol(bool _paused)`:
//        - Emergency function to pause critical operations.
//   22.  `rescueFunds(address tokenAddress, uint256 amount)`:
//        - Allows governance to rescue accidentally sent ERC20 tokens.

// XI. INTERNAL HELPER FUNCTIONS
//    - `_getLiquidationThreshold`: Calculates dynamic threshold.
//    - `_getLoanHealth`: Calculates current health of a loan.
//    - `_calculateCurrentInterest`: Calculates accrued interest.
//    - `_calculateDynamicInterestRate`: Calculates current dynamic interest rate.
//    - `_calculateDynamicCollateralRatio`: Calculates current dynamic collateral ratio.
//    - `_applyDynamicParameter`: Generic function to apply MHI-based parameter calculation.
//    - `_interpolateCurve`: Interpolates a value from a set of curve points.


contract AetherFlow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- ENUMS & STRUCTS ---

    enum PolicyParameterType {
        InterestRateCurve,
        CollateralRatioCurve,
        LiquidationBonusCurve,
        LiquidityIncentiveCurve,
        BorrowerIncentiveCurve,
        MHIWeightings, // For adjusting how MHI is composed (more complex, not single uint)
        BehavioralScoreImpact // How user behavior impacts terms (single uint)
    }

    struct CurvePoint {
        uint256 x; // MHI value or other input (e.g., 0-10000)
        uint256 y; // Corresponding parameter value (e.g., interest rate in BPS, ratio in BPS)
    }

    struct PolicyRule {
        bytes currentData; // ABI-encoded data for the current curve (e.g., CurvePoint[]), or a specific value.
        uint256 lastAdjustedTimestamp;
        uint256 adjustmentInterval; // How often auto-adjustment can occur (0 if no auto-adjustment)
        uint256 minBound; // Minimum allowed value for dynamic adjustment (for scalar parameters)
        uint256 maxBound; // Maximum allowed value for dynamic adjustment (for scalar parameters)
    }

    struct MarketHealthIndex {
        uint256 value;     // The aggregated MHI score (e.g., 0-10000 representing 0-100%)
        uint256 timestamp; // When MHI was last updated
    }

    struct Loan {
        address borrower;
        address asset;
        uint256 principalAmount;
        address collateralAsset;
        uint256 collateralAmount; // Amount of collateral tokens
        uint256 borrowedTimestamp;
        uint256 lastRepaymentTimestamp;
        uint256 outstandingPrincipal;
        uint256 initialCollateralRatioBps; // Basis points (e.g., 15000 for 150%)
        uint256 initialInterestRateBps;
        bool active;
    }

    struct PolicyAmendment {
        PolicyParameterType paramType;
        bytes newData; // New ABI-encoded data for the parameter (e.g., new CurvePoint[]).
        uint256 proposalId;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Simplified: check if address voted, not voting power
        bool executed;
        bool passed;
    }

    // --- STATE VARIABLES ---

    MarketHealthIndex public s_marketHealthIndex;
    address public s_oracleAddress; // Trusted address to update MHI (mutable via governance)
    address public s_governanceToken; // Token used for governance voting (simplified for direct check)
    bool public s_paused;

    // Mapping of asset address to its total deposited liquidity
    mapping(address => uint256) public s_totalLiquidity;
    // Mapping of user address to asset to deposited amount
    mapping(address => mapping(address => uint256)) public s_userLiquidity;

    // Loan storage
    uint256 public s_nextLoanId;
    mapping(uint256 => Loan) public s_loans;
    mapping(address => uint256[]) public s_userActiveLoans; // User => Array of loan IDs

    // User behavioral risk score (e.g., 0-1000, 1000 being lowest risk)
    // New users default to 500, higher for good behavior, lower for bad.
    mapping(address => uint256) public s_userBehavioralScore;

    // Supported assets for lending/borrowing
    mapping(address => bool) public s_isSupportedAsset;

    // Policy rules for dynamic parameters
    mapping(PolicyParameterType => PolicyRule) public s_policyRules;

    // Governance proposals
    uint256 public s_nextProposalId;
    mapping(uint256 => PolicyAmendment) public s_policyAmendments;
    uint256 public s_voteDuration = 3 days; // Default vote duration for proposals

    // Whitelisted addresses for special features/terms
    mapping(address => bool) public s_whitelistedAccess;

    // Incentive tracking for LPs and Borrowers (simplified for this example)
    // This would ideally be more complex with a separate reward token and continuous accrual.
    mapping(address => mapping(address => uint256)) public s_accruedIncentives; // user => asset => amount

    // --- EVENTS ---

    event MarketHealthIndexUpdated(uint256 newMHI, uint256 timestamp);
    event LiquidityDeposited(address indexed user, address indexed asset, uint256 amount);
    event LiquidityWithdrawn(address indexed user, address indexed asset, uint222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
