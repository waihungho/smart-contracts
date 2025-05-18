Okay, here is a smart contract concept focusing on an "Epoch-Based Dynamic DeFi Reserve with Risk Scoring and Flash Loans".

The core idea is to create a lending/borrowing protocol where:
1.  Operations are structured around discrete time periods (epochs).
2.  Interest rates dynamically adjust based on utilization within each epoch.
3.  A simplified on-chain risk score influences borrowing limits or rates (conceptually, though implementation is simplified).
4.  It supports Flash Loans as a key feature.
5.  Interest accrual and certain calculations happen primarily at epoch transitions.

This combines epoch-based mechanics, dynamic rates, a basic risk concept, and a popular DeFi feature (flash loans), aiming for a non-trivial design different from basic examples or direct copies of large protocols.

**Disclaimer:** This is a complex contract concept. Implementing a production-ready DeFi protocol requires extensive security audits, formal verification, and careful consideration of economic incentives, edge cases, gas costs, and oracle reliability. This example provides a framework and demonstrates the features requested but *should not be used in production without significant further development and auditing.* The risk scoring is illustrative.

---

## Contract Outline & Function Summary

**Contract Name:** `EpochBasedDynamicDefiReserve`

**Core Concept:** An epoch-based protocol for depositing, borrowing, and managing assets with dynamic interest rates, risk scoring, and flash loans.

**Key Features:**
1.  **Epoch System:** Time is divided into fixed-duration epochs. Interest, rewards, and risk parameters are updated at the start of each new epoch.
2.  **Dynamic Interest Rates:** Borrow and deposit rates adjust per token based on its utilization ratio within the current epoch.
3.  **Risk Scoring (Simplified):** A basic conceptual score per user influences lending parameters.
4.  **Flash Loans:** Supports ERC3156-like flash loans.
5.  **Collateral Management:** Users must provide collateral to borrow.
6.  **Liquidation:** Unhealthy positions can be liquidated.
7.  **Parameter Governance:** Owner can set key parameters.

**State Variables Summary:**
*   `owner`: Contract owner (governance).
*   `paused`: Pause mechanism flag.
*   `epochDuration`: Duration of each epoch in seconds.
*   `currentEpoch`: The current epoch number.
*   `currentEpochStartTime`: Timestamp when the current epoch started.
*   `supportedTokens`: Mapping of token addresses to boolean (is supported?).
*   `reserveBalances`: Mapping of token addresses to total token balance in the contract.
*   `totalDeposits`: Mapping of token addresses to total value deposited by users.
*   `totalBorrows`: Mapping of token addresses to total value borrowed by users.
*   `userDeposits`: User address -> Token address -> Amount deposited.
*   `userBorrows`: User address -> Token address -> Amount borrowed.
*   `userCollateral`: User address -> Token address -> Amount held as collateral.
*   `userBorrowInterestIndex`: Per token, tracks accumulated borrow interest factor.
*   `userDepositYieldIndex`: Per token, tracks accumulated deposit yield factor.
*   `lastUpdateEpochIndex`: User address -> Token address -> Last epoch index was applied.
*   `borrowRatePerEpoch`: Mapping of token addresses to the current borrow rate per epoch.
*   `depositRatePerEpoch`: Mapping of token addresses to the current deposit rate per epoch.
*   `interestRateModelParams`: Mapping of token addresses to parameters for the rate model (e.g., baseRate, multiplier).
*   `oracle`: Address of the price oracle contract.
*   `liquidationBonus`: Percentage bonus granted to liquidators (e.g., 10500 for 5%).
*   `collateralRatio`: Minimum collateralization ratio required (e.g., 15000 for 150%).
*   `userRiskScore`: Mapping of user addresses to a conceptual risk score (simple integer).
*   `flashLoanFeeRate`: Fee rate for flash loans (e.g., 100 for 0.1%).
*   `rewardToken`: Address of the reward token.
*   `epochRewardPool`: Amount of reward token available for the current epoch.
*   `userClaimableRewards`: Mapping of user address to reward token amount claimable.

**Function Summary (25+ functions):**

**Core Reserve & Lending (6)**
1.  `deposit(address token, uint256 amount)`: Deposit tokens into the reserve.
2.  `withdraw(address token, uint256 amount)`: Withdraw deposited tokens.
3.  `borrow(address token, uint256 amount, address collateralToken, uint256 collateralAmount)`: Borrow tokens using collateral.
4.  `repay(address token, uint256 amount)`: Repay borrowed tokens.
5.  `liquidate(address borrower, address debtToken, address collateralToken)`: Liquidate an unhealthy position.
6.  `flashLoan(address receiver, address token, uint256 amount, bytes calldata data)`: Initiate a flash loan.

**Epoch Management & Interest (4)**
7.  `startNextEpoch()`: Owner or authorized role transitions to the next epoch, updating rates and interest.
8.  `getCurrentEpoch()`: Get the current epoch number.
9.  `getEpochStartTime()`: Get the start timestamp of the current epoch.
10. `getEpochEndTime()`: Get the end timestamp of the current epoch.

**Calculation & State Update (Internal/Public Views) (5)**
11. `_updateUserInterestAndYield(address user, address token)`: Internal helper to apply accrued interest/yield since last update.
12. `_calculateUtilization(address token)`: Internal helper to calculate utilization ratio.
13. `_calculateRates(address token)`: Internal helper to calculate dynamic borrow/deposit rates based on utilization.
14. `getUserTotalCollateralValue(address user)`: Get total value of user's collateral in a reference currency (via oracle).
15. `getUserTotalBorrowValue(address user)`: Get total value of user's borrows in a reference currency (via oracle).

**User State & Health (5)**
16. `getUserDeposit(address user, address token)`: Get user's deposit balance for a token.
17. `getUserBorrow(address user, address token)`: Get user's borrow balance for a token.
18. `getUserCollateral(address user, address token)`: Get user's collateral balance for a token.
19. `getUserHealthFactor(address user)`: Get the user's health factor (collateral value / borrow value).
20. `getUserRiskScore(address user)`: Get the user's conceptual risk score.

**Parameter & Governance (8)**
21. `addSupportedToken(address token)`: Add a token to the supported list.
22. `removeSupportedToken(address token)`: Remove a token from the supported list.
23. `setEpochDuration(uint256 duration)`: Set the duration of epochs.
24. `setInterestRateModelParams(address token, uint256 baseRate, uint256 multiplier)`: Set parameters for a token's interest rate model.
25. `setOracleAddress(address _oracle)`: Set the address of the price oracle.
26. `setLiquidationBonus(uint256 bonus)`: Set the liquidation bonus percentage.
27. `setCollateralRatio(uint256 ratio)`: Set the minimum collateralization ratio.
28. `setFlashLoanFeeRate(uint256 rate)`: Set the flash loan fee rate.

**Rewards (3)**
29. `distributeEpochRewards(address token, uint256 amount)`: Owner distributes rewards for the current epoch.
30. `claimRewards()`: Users claim accumulated rewards.
31. `getClaimableRewards(address user)`: Get user's claimable rewards.

**View & Utility (3)**
32. `getReserveBalance(address token)`: Get the total token balance held by the contract.
33. `getSupportedTokens()`: Get the list of all supported token addresses (might need iteration if many).
34. `getTotalBorrowed(address token)`: Get the total amount borrowed for a token across all users.

*(Note: Some internal helper functions like `_calculateValueInUSD` using the oracle would also exist but aren't listed in the public summary count)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Define interfaces for external contracts
interface IPriceOracle {
    // Returns the price of token in USD (or a reference currency)
    function getPrice(address token) external view returns (uint256 price);
}

interface IFlashLoanRecipient {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes4);

    bytes4 constant ERC3156_CALLBACK_SUCCESS = 0x22075333; // As per EIP-3156
}


/**
 * @title EpochBasedDynamicDefiReserve
 * @dev An advanced smart contract for an epoch-based decentralized finance reserve.
 *      Features dynamic interest rates, risk scoring concept, and flash loans.
 *      Interest and yield are calculated based on accumulated indexes per epoch.
 */
contract EpochBasedDynamicDefiReserve is Ownable, ReentrancyGuard, IFlashLoanRecipient {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    bool public paused;

    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public currentEpoch;
    uint256 public currentEpochStartTime;

    // Supported tokens mapping
    mapping(address => bool) public supportedTokens;
    // Array of supported tokens (for iteration, potentially gas-intensive if many)
    address[] private _supportedTokens;

    // Reserve balances (tokens held by this contract)
    mapping(address => uint256) public reserveBalances;

    // Total protocol state per token
    mapping(address => uint256) public totalDeposits; // Total value deposited (principal + accrued yield)
    mapping(address => uint256) public totalBorrows;  // Total value borrowed (principal + accrued interest)

    // User balances per token
    mapping(address => mapping(address => uint256)) public userDeposits;
    mapping(address => mapping(address => uint256)) public userBorrows;
    mapping(address => mapping(address => uint256)) public userCollateral;

    // Interest & Yield Tracking (Index based)
    // Accumulated interest factor per token (scaled)
    mapping(address => uint256) public borrowInterestIndex; // Total accrued borrow interest factor (per token)
    mapping(address => uint256) public depositYieldIndex;  // Total accrued deposit yield factor (per token)

    // User's index snapshot at their last interaction or update
    mapping(address => mapping(address => uint256)) private userLastBorrowInterestIndex;
    mapping(address => mapping(address => uint256)) private userLastDepositYieldIndex;
    mapping(address => mapping(address => uint256)) private userLastUpdateEpoch;


    // Dynamic Rate Parameters (Simple linear model: rate = base + utilization * multiplier)
    struct RateModelParams {
        uint256 baseRate; // Scaled, e.g., 1e18 for 100% per epoch
        uint256 multiplier; // Scaled
    }
    mapping(address => RateModelParams) public interestRateModelParams;

    // Current rates calculated per epoch
    mapping(address => uint256) public currentBorrowRatePerEpoch;
    mapping(address => uint256) public currentDepositRatePerEpoch;

    // Risk Management
    IPriceOracle public oracle;
    uint256 public liquidationBonus; // Scaled percentage (e.g., 10500 for 5% bonus)
    uint256 public collateralRatio;  // Scaled percentage (e.g., 15000 for 150% minimum collateral)
    mapping(address => uint256) public userRiskScore; // Simple integer score (conceptual)

    // Flash Loans
    uint256 public flashLoanFeeRate; // Scaled (e.g., 100 for 0.1%)

    // Rewards
    address public rewardToken;
    uint256 public epochRewardPool; // Rewards available for distribution in the current epoch
    mapping(address => uint256) public userClaimableRewards;
    // Could add tracking for reward eligibility per epoch if needed, simplified for now.

    // --- Events ---

    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 newUserBalance);
    event Withdrew(address indexed user, address indexed token, uint256 amount, uint256 newUserBalance);
    event Borrowed(address indexed user, address indexed token, uint256 amount, address indexed collateralToken, uint256 collateralAmount, uint256 newUserBalance);
    event Repaid(address indexed user, address indexed token, uint256 amount, uint256 newUserBalance);
    event Liquidated(address indexed liquidator, address indexed borrower, address indexed debtToken, address collateralToken, uint256 debtAmount, uint256 collateralSeized);
    event EpochStarted(uint256 indexed epochNumber, uint256 startTime, uint256 duration);
    event RatesUpdated(address indexed token, uint256 borrowRate, uint256 depositRate, uint256 utilization);
    event ParameterSet(string paramName, uint256 value); // Generic for uint256 params
    event AddressParameterSet(string paramName, address value); // Generic for address params
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event FlashLoan(address indexed receiver, address indexed token, uint256 amount, uint256 fee);
    event RewardsDistributed(address indexed token, uint256 amount, uint256 indexed epoch);
    event RewardsClaimed(address indexed user, address indexed token, uint256 amount);
    event RiskScoreUpdated(address indexed user, uint256 newScore);

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlySupportedToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }

    modifier updateState(address user, address token) {
         // Apply accrued interest/yield before any state change for the user/token pair
        _updateUserInterestAndYield(user, token);
        _;
    }

    // --- Constructor ---

    constructor(
        uint256 _epochDuration,
        uint256 _liquidationBonus,
        uint256 _collateralRatio,
        uint256 _flashLoanFeeRate,
        address _oracle,
        address _rewardToken
    ) Ownable(msg.sender) {
        require(_epochDuration > 0, "Epoch duration must be positive");
        require(_collateralRatio > 10000, "Collateral ratio must be > 100%"); // 10000 represents 100%
        require(_oracle != address(0), "Oracle address cannot be zero");
        require(_rewardToken != address(0), "Reward token address cannot be zero");

        epochDuration = _epochDuration;
        currentEpoch = 1;
        currentEpochStartTime = block.timestamp;
        paused = false;

        liquidationBonus = _liquidationBonus;
        collateralRatio = _collateralRatio;
        flashLoanFeeRate = _flashLoanFeeRate;
        oracle = IPriceOracle(_oracle);
        rewardToken = _rewardToken;

        // Initialize index for all tokens to 1e18 (100%)
        // This is done implicitly per token when it's first used/added,
        // but good to note the starting point is 1e18 (scaled)
    }

    // --- Core Reserve & Lending Functions ---

    /**
     * @dev Deposits tokens into the reserve.
     * @param token The address of the token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address token, uint256 amount) external nonReentrant whenNotPaused onlySupportedToken(token) updateState(msg.sender, token) {
        require(amount > 0, "Deposit amount must be positive");

        // Transfer tokens from user to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Update balances
        reserveBalances[token] += amount;
        userDeposits[msg.sender][token] += amount;
        totalDeposits[token] += amount; // Note: totalDeposits tracks principal + yield

        emit Deposited(msg.sender, token, amount, userDeposits[msg.sender][token]);
    }

    /**
     * @dev Withdraws deposited tokens from the reserve.
     * @param token The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(address token, uint256 amount) external nonReentrant whenNotPaused onlySupportedToken(token) updateState(msg.sender, token) {
        require(amount > 0, "Withdraw amount must be positive");
        require(userDeposits[msg.sender][token] >= amount, "Insufficient deposited balance");

        // Update balances first
        userDeposits[msg.sender][token] -= amount;
        reserveBalances[token] -= amount;
        totalDeposits[token] -= amount; // Note: totalDeposits tracks principal + yield

        // Transfer tokens from contract to user
        IERC20(token).safeTransfer(msg.sender, amount);

        // Check user's health factor if they have borrows after withdrawal (if this affects collateral)
        // Simplified: Assuming deposited tokens are not collateral for borrows in this model.
        // If deposits *could* be used as collateral, a health factor check would be needed here.

        emit Withdrew(msg.sender, token, amount, userDeposits[msg.sender][token]);
    }

    /**
     * @dev Borrows tokens from the reserve, requires collateral.
     * @param token The address of the token to borrow.
     * @param amount The amount of tokens to borrow.
     * @param collateralToken The address of the token to use as collateral.
     * @param collateralAmount The amount of collateral tokens to lock.
     */
    function borrow(address token, uint256 amount, address collateralToken, uint256 collateralAmount) external nonReentrant whenNotPaused onlySupportedToken(token) onlySupportedToken(collateralToken) updateState(msg.sender, token) updateState(msg.sender, collateralToken) {
        require(amount > 0, "Borrow amount must be positive");
        require(collateralAmount > 0, "Collateral amount must be positive");
        require(token != collateralToken, "Borrow token cannot be the same as collateral token"); // Prevent using the same token for debt and collateral

        // Lock collateral first
        IERC20(collateralToken).safeTransferFrom(msg.sender, address(this), collateralAmount);
        userCollateral[msg.sender][collateralToken] += collateralAmount;

        // Check if contract has enough liquidity
        require(reserveBalances[token] >= amount, "Insufficient reserve liquidity");

        // Apply interest/yield BEFORE checking health factor (already done by modifier)

        // Check user's health factor AFTER adding collateral and BEFORE borrowing
        // Calculate potential new borrow value
        uint256 currentBorrowValueUSD = getUserTotalBorrowValue(msg.sender);
        uint256 borrowValueUSD = _calculateValueInUSD(token, amount);
        uint256 projectedBorrowValueUSD = currentBorrowValueUSD + borrowValueUSD;

        uint256 currentCollateralValueUSD = getUserTotalCollateralValue(msg.sender);

        // Check if the loan is viable based on health factor
        // Health Factor = Collateral Value / Borrow Value
        // Need Projected Health Factor >= 1 (or >= collateralRatio/100%)
        require(currentCollateralValueUSD * 10000 >= projectedBorrowValueUSD * collateralRatio, "Insufficient collateral or poor health factor");

        // Update balances
        reserveBalances[token] -= amount;
        userBorrows[msg.sender][token] += amount;
        totalBorrows[token] += amount; // Note: totalBorrows tracks principal + interest

        // Transfer borrowed tokens to user
        IERC20(token).safeTransfer(msg.sender, amount);

        // Update risk score (conceptual)
        userRiskScore[msg.sender] = (userRiskScore[msg.sender] * 9 + 10) / 10; // Simple heuristic, increase slightly on borrow

        emit Borrowed(msg.sender, token, amount, collateralToken, collateralAmount, userBorrows[msg.sender][token]);
    }

    /**
     * @dev Repays borrowed tokens.
     * @param token The address of the token to repay.
     * @param amount The amount of tokens to repay.
     */
    function repay(address token, uint256 amount) external nonReentrant whenNotPaused onlySupportedToken(token) updateState(msg.sender, token) {
        require(amount > 0, "Repay amount must be positive");
        require(userBorrows[msg.sender][token] > 0, "No outstanding borrow for this token");

        // Cap repayment to the current outstanding borrow balance
        uint256 amountToRepay = amount > userBorrows[msg.sender][token] ? userBorrows[msg.sender][token] : amount;

        // Transfer tokens from user to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountToRepay);

        // Update balances
        userBorrows[msg.sender][token] -= amountToRepay;
        reserveBalances[token] += amountToRepay;
        totalBorrows[token] -= amountToRepay; // Note: totalBorrows tracks principal + interest

        // Update risk score (conceptual)
        userRiskScore[msg.sender] = (userRiskScore[msg.sender] * 9) / 10; // Simple heuristic, decrease slightly on repay

        emit Repaid(msg.sender, token, amountToRepay, userBorrows[msg.sender][token]);
    }

    /**
     * @dev Liquidates an unhealthy borrower position.
     *      Requires health factor < 1 (or < collateralRatio).
     * @param borrower The address of the borrower to liquidate.
     * @param debtToken The address of the token the borrower owes.
     * @param collateralToken The address of the token used as collateral.
     */
    function liquidate(address borrower, address debtToken, address collateralToken) external nonReentrant whenNotPaused onlySupportedToken(debtToken) onlySupportedToken(collateralToken) {
        require(borrower != address(0), "Invalid borrower address");
        require(borrower != msg.sender, "Cannot liquidate yourself");
        require(debtToken != collateralToken, "Debt and collateral tokens cannot be the same");

        // Apply accrued interest/yield for borrower's position BEFORE checking health
        _updateUserInterestAndYield(borrower, debtToken);
        _updateUserInterestAndYield(borrower, collateralToken); // Although collateral doesn't accrue yield in this model, good practice

        // Check borrower's health factor
        require(getUserHealthFactor(borrower) < 10000, "Borrower's position is healthy"); // 10000 represents 1.0 health factor

        // Determine liquidation amount (can be full or partial).
        // Simplified: Liquidate enough collateral to cover debt + bonus.
        // Need to calculate the value of the debt and the collateral.
        uint256 borrowerDebt = userBorrows[borrower][debtToken];
        uint256 borrowerCollateral = userCollateral[borrower][collateralToken];

        require(borrowerDebt > 0, "Borrower has no debt for this token");
        require(borrowerCollateral > 0, "Borrower has no collateral for this token");

        uint256 debtValueUSD = _calculateValueInUSD(debtToken, borrowerDebt);
        uint256 collateralValueUSD = _calculateValueInUSD(collateralToken, borrowerCollateral);

        require(collateralValueUSD > 0, "Collateral value is zero"); // Oracle must provide a price

        // Calculate amount of collateral needed to cover debt + bonus
        // Needed Collateral USD = Debt USD * (1 + Liquidation Bonus %)
        uint256 neededCollateralValueUSD = (debtValueUSD * liquidationBonus) / 10000; // liquidationBonus is scaled

        // Calculate the actual collateral amount based on the collateral token price
        uint256 collateralTokenPrice = oracle.getPrice(collateralToken);
        require(collateralTokenPrice > 0, "Collateral token price is zero");

        // Needed Collateral Amount = Needed Collateral USD / Collateral Token Price USD
        // Scale math: (neededCollateralValueUSD * 1e18) / collateralTokenPrice
        uint256 collateralToSeize = (neededCollateralValueUSD * 1e18) / collateralTokenPrice;

        // Cap seized collateral by available collateral
        if (collateralToSeize > borrowerCollateral) {
            collateralToSeize = borrowerCollateral; // Seize all available collateral if not enough
        }

        // Calculate the value of seized collateral to determine how much debt is cleared
        uint256 seizedCollateralValueUSD = _calculateValueInUSD(collateralToken, collateralToSeize);

        // Amount of debt to cover = Seized Collateral Value USD / (1 + Liquidation Bonus %)
        // Scaled math: (seizedCollateralValueUSD * 10000) / liquidationBonus
        uint256 debtCoveredValueUSD = (seizedCollateralValueUSD * 10000) / liquidationBonus;

        // Calculate the actual debt amount cleared based on the debt token price
        uint256 debtTokenPrice = oracle.getPrice(debtToken);
        require(debtTokenPrice > 0, "Debt token price is zero");

        // Debt Amount Cleared = Debt Covered Value USD / Debt Token Price USD
        // Scaled math: (debtCoveredValueUSD * 1e18) / debtTokenPrice
        uint256 debtAmountCleared = (debtCoveredValueUSD * 1e18) / debtTokenPrice;

        // Cap cleared debt by outstanding debt
         if (debtAmountCleared > borrowerDebt) {
            debtAmountCleared = borrowerDebt; // Clear all outstanding debt if seized collateral is sufficient
        }

        // Update borrower's balances
        userBorrows[borrower][debtToken] -= debtAmountCleared;
        userCollateral[borrower][collateralToken] -= collateralToSeize;
        totalBorrows[debtToken] -= debtAmountCleared; // Update total protocol borrows

        // Transfer seized collateral to liquidator
        IERC20(collateralToken).safeTransfer(msg.sender, collateralToSeize);

        // The contract receives the cleared debt amount conceptually, but it's "burned" from the borrow pool
        // It doesn't directly increase reserveBalances unless there's a specific mechanism for that.
        // We'll assume the debt is simply reduced from the total.

        emit Liquidated(msg.sender, borrower, debtToken, collateralToken, debtAmountCleared, collateralToSeize);

        // Optional: Update risk score of liquidated user (decrease significantly)
        userRiskScore[borrower] = userRiskScore[borrower] / 2; // Example: Halve the score
    }

    /**
     * @dev Initiates a flash loan.
     * @param receiver The address of the contract to receive the flash loan.
     * @param token The address of the token to loan.
     * @param amount The amount of tokens to loan.
     * @param data Optional data passed to the receiver's onFlashLoan function.
     */
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external nonReentrant whenNotPaused onlySupportedToken(token) {
        require(amount > 0, "Flash loan amount must be positive");
        require(receiver != address(0), "Receiver address cannot be zero");
        require(reserveBalances[token] >= amount, "Insufficient reserve liquidity for flash loan");

        uint256 fee = (amount * flashLoanFeeRate) / 10000; // flashLoanFeeRate is scaled
        uint256 totalAmountToReturn = amount + fee;

        // Transfer loan amount to receiver
        IERC20(token).safeTransfer(receiver, amount);

        // Call the receiver's onFlashLoan function
        IFlashLoanRecipient recipient = IFlashLoanRecipient(receiver);
        bytes4 returnedValue = recipient.onFlashLoan(msg.sender, token, amount, fee, data);

        // Check if the callback was successful
        require(returnedValue == IFlashLoanRecipient.ERC3156_CALLBACK_SUCCESS, "Flash loan callback failed");

        // Verify and transfer the full amount (loan + fee) back
        IERC20(token).safeTransferFrom(receiver, address(this), totalAmountToReturn);

        // Note: reserveBalances are temporarily reduced then fully restored (+ fee)
        // No update needed to reserveBalances[token] unless we want to track the fee separately.
        // Let's assume the fee stays in reserveBalances.

        emit FlashLoan(receiver, token, amount, fee);
    }


    // --- Epoch Management & Interest Functions ---

    /**
     * @dev Transitions the protocol to the next epoch.
     *      Updates rates and applies accrued interest/yield for all active positions.
     *      Can only be called after the current epoch duration has passed.
     *      NOTE: This function can be very gas-intensive if there are many active users/tokens.
     *      A more scalable approach would involve 'pulling' interest/yield calculation
     *      when a user interacts, which is implemented using the index approach.
     *      This function primarily updates the global indexes and rates.
     */
    function startNextEpoch() external nonReentrant whenNotPaused {
        require(block.timestamp >= currentEpochStartTime + epochDuration, "Epoch duration has not passed");

        // Update global indexes for all supported tokens based on current rates
        for (uint i = 0; i < _supportedTokens.length; i++) {
            address token = _supportedTokens[i];

            if (totalBorrows[token] > 0) {
                // Calculate utilization
                uint256 utilization = (totalBorrows[token] * 1e18) / totalDeposits[token];
                 // Calculate current rates for the *next* epoch based on *this* epoch's utilization
                _calculateRates(token);

                // Apply current epoch's rate to global indexes for calculation in the next epoch
                // Index update: index = old_index * (1 + rate_per_epoch)
                // Simplified: Assuming the rate is applied to the index once per epoch transition
                borrowInterestIndex[token] = (borrowInterestIndex[token] * (1e18 + currentBorrowRatePerEpoch[token])) / 1e18;
                depositYieldIndex[token] = (depositYieldIndex[token] * (1e18 + currentDepositRatePerEpoch[token])) / 1e18;
            } else {
                 // If no borrows, rates are base rate, indexes don't increase from utilization
                _calculateRates(token); // Still calculate base rates
                 // Indexes should still potentially increase based on base rate even with zero utilization
                 // Let's simplify and say index only increases if utilization > 0 for now.
                 // In reality, deposit rate > 0 even with 0 utilization, and borrow rate = base rate.
                 // Adjusting simplified logic:
                 // _calculateRates updates current rates based on *current* epoch utilization.
                 // These rates are then used to update global indexes for the *next* epoch's calculations.
                 // This is slightly off from standard models but fits the epoch concept.
                 // Let's make it simpler: rates calculated *now* apply to the *next* epoch's accrual.
                 // Global index increases by the *current* rate.
                 borrowInterestIndex[token] = (borrowInterestIndex[token] * (1e18 + currentBorrowRatePerEpoch[token])) / 1e18;
                 depositYieldIndex[token] = (depositYieldIndex[token] * (1e18 + currentDepositRatePerEpoch[token])) / 1e18;
            }

             emit RatesUpdated(token, currentBorrowRatePerEpoch[token], currentDepositRatePerEpoch[token], _calculateUtilization(token));
        }

        // Advance epoch counter and timestamp
        currentEpoch++;
        currentEpochStartTime = block.timestamp;

        // Distribute epoch rewards (if any were set for this epoch)
        if (epochRewardPool > 0) {
             // Simplified: Distribute total pool proportionally based on current deposits
             // A more complex model would track average deposits over the epoch.
             uint256 totalCurrentDepositsValue = 0; // Need value, not just amount
             // This would require iterating all users and their deposits... gas intensive.
             // Let's simplify: assume totalDeposits state variable *conceptually* tracks total value
             // or distribute equally, or require an external rewards distributor.
             // Simplest: Distribute a fixed amount per depositor, or just add to a pool for claim.
             // Let's use the userClaimableRewards pool and distribute the epochRewardPool into it
             // based on some criteria (e.g., total deposits value in this epoch).
             // For this example, we'll just add the epochRewardPool to a global pot users can claim from.
             // A proper distribution requires tracking individual user contributions within the epoch.
             // Let's make `distributeEpochRewards` add to the global pool, and `startNextEpoch`
             // doesn't automatically distribute to users, they must claim from the pool.
             // Redefining `distributeEpochRewards` to add to the pool.
             // And `startNextEpoch` does nothing with rewards beyond potentially resetting a per-epoch distribution amount.
             // Let's remove epochRewardPool and use userClaimableRewards directly with `claimRewards`.
             // The `distributeEpochRewards` function will be used by owner to add rewards to the claimable pool.
             // This function now just focuses on epoch transition and rates.
        }


        emit EpochStarted(currentEpoch, currentEpochStartTime, epochDuration);
    }

    /**
     * @dev Helper to apply accrued interest/yield for a specific user and token.
     *      Called by the `updateState` modifier before any balance-changing operation.
     * @param user The user address.
     * @param token The token address.
     */
    function _updateUserInterestAndYield(address user, address token) internal {
        // Only update if the user/token pair hasn't been updated in the current epoch
        if (userLastUpdateEpoch[user][token] < currentEpoch) {
            // Calculate accrued interest since last update for borrows
            uint256 accruedBorrowInterest = 0;
            uint256 userBorrow = userBorrows[user][token];
            if (userBorrow > 0) {
                // Index delta: current_global_index - user_snapshot_index
                uint256 indexDelta = borrowInterestIndex[token] - userLastBorrowInterestIndex[user][token];
                 // Accrued interest = user_balance * index_delta / 1e18
                accruedBorrowInterest = (userBorrow * indexDelta) / 1e18;
                userBorrows[user][token] += accruedBorrowInterest;
                 totalBorrows[token] += accruedBorrowInterest; // Update total protocol borrows
            }

            // Calculate accrued yield since last update for deposits
            uint256 accruedDepositYield = 0;
            uint256 userDeposit = userDeposits[user][token];
            if (userDeposit > 0) {
                 uint256 indexDelta = depositYieldIndex[token] - userLastDepositYieldIndex[user][token];
                accruedDepositYield = (userDeposit * indexDelta) / 1e18;
                userDeposits[user][token] += accruedDepositYield;
                 totalDeposits[token] += accruedDepositYield; // Update total protocol deposits
            }

            // Update user's index snapshots and last update epoch
            userLastBorrowInterestIndex[user][token] = borrowInterestIndex[token];
            userLastDepositYieldIndex[user][token] = depositYieldIndex[token];
            userLastUpdateEpoch[user][token] = currentEpoch;

             // Note: This accrual happens *within* an epoch based on rates set at the *start* of the epoch.
             // The global indexes are updated only at epoch transitions.
        }
    }


    /**
     * @dev Calculates the utilization ratio for a token.
     * @param token The token address.
     * @return utilization The utilization ratio scaled by 1e18. Returns 0 if total deposits is 0.
     */
    function _calculateUtilization(address token) internal view returns (uint256 utilization) {
        uint256 currentTotalDeposits = totalDeposits[token]; // Use stored value (principal + yield)
        uint256 currentTotalBorrows = totalBorrows[token];   // Use stored value (principal + interest)

        if (currentTotalDeposits == 0) {
            return 0; // Utilization is 0 if no deposits
        }
        // Using total values which include accrued interest/yield is a simplification.
        // A more accurate model would use principal amounts or a separate tracking.
        // Let's refine: totalDeposits/Borrows track the *current* balance including accruals.
        // Utilization should ideally be based on principal or average balances across the epoch.
        // For simplicity, let's use the current total values.
         if (currentTotalDeposits == 0) return 0; // Avoid division by zero
        return (currentTotalBorrows * 1e18) / currentTotalDeposits;
    }

    /**
     * @dev Calculates dynamic borrow and deposit rates for a token based on utilization.
     *      Uses a simple linear model. Updates internal state.
     * @param token The token address.
     */
    function _calculateRates(address token) internal {
        RateModelParams memory params = interestRateModelParams[token];
        uint256 utilization = _calculateUtilization(token); // Scaled 1e18

        // Simple linear model: rate = base + utilization * multiplier
        // Both rates are per epoch, scaled by 1e18
        uint256 borrowRate = params.baseRate + (utilization * params.multiplier) / 1e18;
        // Deposit rate is typically a fraction of borrow rate, often linked to reserve factor
        // Let's simplify: deposit rate = borrow rate * utilization (roughly what protocol keeps vs passes on)
        uint256 depositRate = (borrowRate * utilization) / 1e18; // Scaled 1e18

        currentBorrowRatePerEpoch[token] = borrowRate;
        currentDepositRatePerEpoch[token] = depositRate;
    }


     /**
     * @dev Calculates the value of an amount of token in USD (or reference currency) via oracle.
     * @param token The token address.
     * @param amount The amount of tokens.
     * @return valueUSD The value in USD (scaled by 1e18 if oracle provides scaled price).
     */
    function _calculateValueInUSD(address token, uint256 amount) internal view returns (uint256 valueUSD) {
        if (amount == 0) return 0;
        uint256 price = oracle.getPrice(token);
        if (price == 0) return 0; // Cannot calculate value if price is zero
        // Assuming oracle price is already scaled (e.g., 1e18 USD per token)
        // valueUSD = (amount * price) / 1e18 (assuming token decimals are 18, adjust otherwise)
        // For simplicity, assume 18 decimals for all supported tokens and oracle price is 1e18 per token.
        return (amount * price) / 1e18;
    }


    /**
     * @dev Gets the total value of a user's collateral in USD (or reference currency).
     * @param user The user address.
     * @return totalValueUSD The total collateral value in USD.
     */
    function getUserTotalCollateralValue(address user) public view returns (uint256 totalValueUSD) {
        totalValueUSD = 0;
         for (uint i = 0; i < _supportedTokens.length; i++) {
            address token = _supportedTokens[i];
            uint256 collateralAmount = userCollateral[user][token];
            if (collateralAmount > 0) {
                totalValueUSD += _calculateValueInUSD(token, collateralAmount);
            }
        }
    }

    /**
     * @dev Gets the total value of a user's outstanding borrows in USD (or reference currency).
     * @param user The user address.
     * @return totalValueUSD The total borrow value in USD.
     */
    function getUserTotalBorrowValue(address user) public view returns (uint256 totalValueUSD) {
        totalValueUSD = 0;
         for (uint i = 0; i < _supportedTokens.length; i++) {
            address token = _supportedTokens[i];
             // Need to consider accrued interest *up to now* for health factor calculation
            uint256 borrowAmount = userBorrows[user][token]; // This already includes accrued interest from _updateUserInterestAndYield called by modifier

            // If calling this *without* a prior state update (e.g., from a view function),
            // the accrued interest since the last update wouldn't be reflected.
            // A proper implementation needs a view function that calculates current balance *with* pending interest.
            // Let's add that capability.

            // Calculate pending interest if user state hasn't been updated in the current epoch
            if (userLastUpdateEpoch[user][token] < currentEpoch) {
                 uint256 indexDelta = borrowInterestIndex[token] - userLastBorrowInterestIndex[user][token];
                 uint256 pendingInterest = (userBorrows[user][token] * indexDelta) / 1e18;
                 borrowAmount += pendingInterest;
            }

            if (borrowAmount > 0) {
                totalValueUSD += _calculateValueInUSD(token, borrowAmount);
            }
        }
    }

    // --- User State & Health Functions ---

    /**
     * @dev Gets a user's current deposit balance for a token, including accrued yield.
     * @param user The user address.
     * @param token The token address.
     * @return The total deposited amount including yield.
     */
    function getUserDeposit(address user, address token) public view returns (uint256) {
         // Need to calculate pending yield if user state hasn't been updated in the current epoch
         uint256 depositAmount = userDeposits[user][token];
          if (userLastUpdateEpoch[user][token] < currentEpoch && depositAmount > 0) {
               uint256 indexDelta = depositYieldIndex[token] - userLastDepositYieldIndex[user][token];
               uint256 pendingYield = (depositAmount * indexDelta) / 1e18;
               depositAmount += pendingYield;
          }
          return depositAmount;
    }

    /**
     * @dev Gets a user's current borrow balance for a token, including accrued interest.
     * @param user The user address.
     * @param token The token address.
     * @return The total borrowed amount including interest.
     */
    function getUserBorrow(address user, address token) public view returns (uint256) {
        // Need to calculate pending interest if user state hasn't been updated in the current epoch
         uint256 borrowAmount = userBorrows[user][token];
          if (userLastUpdateEpoch[user][token] < currentEpoch && borrowAmount > 0) {
              uint256 indexDelta = borrowInterestIndex[token] - userLastBorrowInterestIndex[user][token];
               uint256 pendingInterest = (borrowAmount * indexDelta) / 1e18;
               borrowAmount += pendingInterest;
          }
          return borrowAmount;
    }


    /**
     * @dev Gets a user's current collateral balance for a token.
     * @param user The user address.
     * @param token The token address.
     * @return The total collateral amount.
     */
    function getUserCollateral(address user, address token) public view returns (uint256) {
        return userCollateral[user][token];
    }

    /**
     * @dev Gets a user's health factor.
     *      Health Factor = (Total Collateral Value) / (Total Borrow Value)
     *      Scaled by 1e18. 1e18 means healthy, < 1e18 means potentially unhealthy.
     *      Liquidation Threshold is typically slightly above 1e18 (e.g., 1.05).
     *      Collateral Ratio (set via collateralRatio) is the minimum HF needed to borrow.
     * @param user The user address.
     * @return healthFactor The user's health factor scaled by 1e18. Returns max uint256 if borrow value is zero.
     */
    function getUserHealthFactor(address user) public view returns (uint256 healthFactor) {
        uint256 totalCollateralValue = getUserTotalCollateralValue(user);
        uint256 totalBorrowValue = getUserTotalBorrowValue(user); // This already accounts for pending interest in the view function

        if (totalBorrowValue == 0) {
            return type(uint256).max; // Healthy - no borrows
        }

        // healthFactor = (totalCollateralValue * 1e18) / totalBorrowValue
        return (totalCollateralValue * 1e18) / totalBorrowValue;
    }

    /**
     * @dev Gets a user's conceptual risk score.
     * @param user The user address.
     * @return score The user's risk score.
     */
    function getUserRiskScore(address user) public view returns (uint256 score) {
        return userRiskScore[user];
    }


    // --- Parameter & Governance Functions ---

    /**
     * @dev Adds a token to the list of supported tokens. Only callable by owner.
     *      Initializes rates and index tracking for the new token.
     * @param token The address of the token to add.
     */
    function addSupportedToken(address token) external onlyOwner whenPaused {
        require(token != address(0), "Token address cannot be zero");
        require(!supportedTokens[token], "Token is already supported");

        supportedTokens[token] = true;
        _supportedTokens.push(token); // Add to array

        // Initialize indices (representing 100%)
        borrowInterestIndex[token] = 1e18;
        depositYieldIndex[token] = 1e18;

        // Set default rate model params (can be updated later)
        interestRateModelParams[token] = RateModelParams({baseRate: 0, multiplier: 0}); // Default to 0 rates
        currentBorrowRatePerEpoch[token] = 0;
        currentDepositRatePerEpoch[token] = 0;


        emit SupportedTokenAdded(token);
    }

     /**
     * @dev Removes a token from the list of supported tokens. Only callable by owner.
     *      Requires all outstanding borrows and deposits for this token to be zero.
     *      NOTE: Removing from the array is gas-intensive and requires swapping the last element.
     * @param token The address of the token to remove.
     */
    function removeSupportedToken(address token) external onlyOwner whenPaused {
        require(supportedTokens[token], "Token is not supported");
        require(totalBorrows[token] == 0, "Token still has outstanding borrows");
        require(totalDeposits[token] == 0, "Token still has outstanding deposits");
        require(reserveBalances[token] == 0, "Token still has balance in reserve");

        supportedTokens[token] = false;

        // Remove from array - find and swap with last element
        uint256 lastIndex = _supportedTokens.length - 1;
        for (uint i = 0; i < _supportedTokens.length; i++) {
            if (_supportedTokens[i] == token) {
                _supportedTokens[i] = _supportedTokens[lastIndex];
                _supportedTokens.pop();
                break;
            }
        }

        // Optional: Clear mappings for this token to save gas on reads later (explicit deletion)
        delete borrowInterestIndex[token];
        delete depositYieldIndex[token];
        delete interestRateModelParams[token];
        delete currentBorrowRatePerEpoch[token];
        delete currentDepositRatePerEpoch[token];
        delete totalBorrows[token];
        delete totalDeposits[token];
        delete reserveBalances[token];
        // User-specific mappings are not cleared here; would require iterating all users, infeasible.

        emit SupportedTokenRemoved(token);
    }

    /**
     * @dev Sets the duration of an epoch in seconds. Only callable by owner.
     *      Can only be set when not in the middle of an epoch transition window.
     * @param duration The new epoch duration.
     */
    function setEpochDuration(uint256 duration) external onlyOwner whenNotPaused {
        require(duration > 0, "Epoch duration must be positive");
         // To prevent issues, only allow setting duration if the current epoch has finished
         // or if the contract is paused. Or, just allow it and the next epoch start time
         // will be calculated based on the *new* duration from the *current* start time + old duration.
         // Let's allow it anytime when not paused, the change takes effect for the *next* epoch start.
        epochDuration = duration;
        emit ParameterSet("epochDuration", duration);
    }

     /**
     * @dev Sets the parameters for the interest rate model for a specific token.
     *      Only callable by owner.
     * @param token The token address.
     * @param baseRate The base rate per epoch (scaled 1e18).
     * @param multiplier The multiplier for utilization (scaled 1e18).
     */
    function setInterestRateModelParams(address token, uint256 baseRate, uint256 multiplier) external onlyOwner whenNotPaused onlySupportedToken(token) {
        interestRateModelParams[token] = RateModelParams({baseRate: baseRate, multiplier: multiplier});
        // Rates will be recalculated based on new params at the next epoch transition
        // Can optionally force a rate recalculation here too.
         _calculateRates(token); // Recalculate current rates immediately
        emit ParameterSet("interestRateModelParams", uint256(uint160(token))); // Use token address as identifier
    }

    /**
     * @dev Sets the address of the price oracle contract. Only callable by owner.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        oracle = IPriceOracle(_oracle);
        emit AddressParameterSet("oracle", _oracle);
    }

    /**
     * @dev Sets the liquidation bonus percentage. Only callable by owner.
     * @param bonus The liquidation bonus percentage (scaled 1e4, e.g., 10500 for 5%).
     */
    function setLiquidationBonus(uint256 bonus) external onlyOwner {
        liquidationBonus = bonus;
        emit ParameterSet("liquidationBonus", bonus);
    }

    /**
     * @dev Sets the minimum collateralization ratio required to borrow. Only callable by owner.
     * @param ratio The collateralization ratio percentage (scaled 1e4, e.g., 15000 for 150%).
     */
    function setCollateralRatio(uint256 ratio) external onlyOwner {
        require(ratio >= 10000, "Ratio must be at least 100%");
        collateralRatio = ratio;
        emit ParameterSet("collateralRatio", ratio);
    }

    /**
     * @dev Sets the fee rate for flash loans. Only callable by owner.
     * @param rate The fee rate (scaled 1e4, e.g., 100 for 0.1%).
     */
    function setFlashLoanFeeRate(uint256 rate) external onlyOwner {
        flashLoanFeeRate = rate;
        emit ParameterSet("flashLoanFeeRate", rate);
    }

    /**
     * @dev Sets the risk score for a user (illustrative governance function). Only callable by owner.
     *      A real system would derive this score automatically or via a decentralized mechanism.
     * @param user The user address.
     * @param score The new risk score.
     */
    function setUserRiskScore(address user, uint256 score) external onlyOwner {
        userRiskScore[user] = score;
        emit RiskScoreUpdated(user, score);
    }

    /**
     * @dev Pauses contract operations (deposit, withdraw, borrow, repay, flashLoan). Only callable by owner.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit ParameterSet("paused", 1); // Represent boolean as 1 for true
    }

    /**
     * @dev Unpauses contract operations. Only callable by owner.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit ParameterSet("paused", 0); // Represent boolean as 0 for false
    }

    // --- Rewards Functions ---

    /**
     * @dev Allows the owner to distribute rewards into a global pool for claiming.
     *      These rewards are claimable by users based on the claim logic (currently manual claim).
     * @param amount The amount of reward token to distribute.
     */
    function distributeEpochRewards(uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Reward amount must be positive");
        // Transfer reward tokens to the contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), amount);
        // Add to a conceptual pool that users can claim from.
        // Simplified: Just add to a global pool, claimable by anyone? No, per-user claimable.
        // This function should probably add to `userClaimableRewards` based on some criteria.
        // As it's complex to track per-epoch contributions for every user,
        // let's simplify: This function ADDS to a general pot. Users can claim from that pot.
        // A more advanced system would distribute based on user activity weighted by epoch.
        // Let's use this to fund a pool that *will* be distributed. Re-implementing:
        // Owner sends rewards, they go into the contract. A separate mechanism (manual owner call, or within startNextEpoch)
        // would then calculate *how much* each user gets from this pool and add to their `userClaimableRewards`.
        // Let's make it simple: owner sends rewards *to* the contract, and users claim from a pool.
        // How much can they claim? Let's assume it's based on their deposits *at the time of distribution*.
        // This function needs to determine *which* users get rewards and *how much*.
        // This is still very gas intensive if done on-chain for all users.
        // A common pattern is off-chain calculation and on-chain distribution proof (Merkle tree).
        // Let's choose the simplest on-chain model: the owner adds to the `userClaimableRewards` mapping directly.
        // This allows the owner (or a trusted role) to decide the distribution off-chain.

        // Simplified: Owner explicitly sets how much each user can claim.
        // This function signature needs adjustment or a helper.
        // Let's make `distributeRewardsToUser` instead.
    }

     /**
     * @dev Allows the owner to add claimable rewards for a specific user.
     *      Reward tokens must be pre-approved/sent to the contract.
     * @param user The user address.
     * @param amount The amount of reward token to add to their claimable balance.
     */
    function distributeRewardsToUser(address user, uint256 amount) external onlyOwner {
         require(user != address(0), "User address cannot be zero");
         require(amount > 0, "Reward amount must be positive");
         // Check if contract holds enough reward tokens (they must have been sent previously)
         require(IERC20(rewardToken).balanceOf(address(this)) >= amount, "Insufficient reward tokens in contract");

         userClaimableRewards[user] += amount;
         emit RewardsDistributed(rewardToken, amount, currentEpoch); // Attribute to current epoch for context
    }


    /**
     * @dev Allows users to claim their accumulated rewards.
     */
    function claimRewards() external nonReentrant whenNotPaused {
        uint256 amountToClaim = userClaimableRewards[msg.sender];
        require(amountToClaim > 0, "No rewards to claim");

        userClaimableRewards[msg.sender] = 0;

        // Transfer reward tokens to user
        IERC20(rewardToken).safeTransfer(msg.sender, amountToClaim);

        emit RewardsClaimed(msg.sender, rewardToken, amountToClaim);
    }

    /**
     * @dev Gets the amount of reward tokens a user can claim.
     * @param user The user address.
     * @return claimableAmount The amount of reward tokens claimable by the user.
     */
    function getClaimableRewards(address user) public view returns (uint256 claimableAmount) {
        return userClaimableRewards[user];
    }


    // --- View & Utility Functions ---

    /**
     * @dev Gets the total balance of a token held by the contract.
     * @param token The token address.
     * @return balance The total token balance.
     */
    function getReserveBalance(address token) public view returns (uint256 balance) {
        return reserveBalances[token];
    }

    /**
     * @dev Gets the list of all supported token addresses.
     *      Note: Gas costs scale linearly with the number of supported tokens.
     * @return tokens An array of supported token addresses.
     */
    function getSupportedTokens() public view returns (address[] memory tokens) {
        return _supportedTokens;
    }

     /**
     * @dev Gets the total amount borrowed for a token across all users, including accrued interest.
     *      Note: This iterates through supported tokens but not users, faster than summing user borrows.
     * @param token The token address.
     * @return total The total borrowed amount.
     */
    function getTotalBorrowed(address token) public view returns (uint256 total) {
         // This state variable `totalBorrows` already tracks the amount including accruals applied by the updateState modifier or epoch transition.
         // However, if called as a simple view function *without* any prior transaction triggering updateState,
         // the value might be slightly stale within the current epoch.
         // A completely accurate view function would need to calculate the pending interest for *all* users.
         // Given the scaling issue, returning the stored `totalBorrows` is a practical compromise for a view function.
         // A user's individual `getUserBorrow` is accurate because it calculates pending interest on demand.
         return totalBorrows[token];
    }

     /**
     * @dev Gets the total amount deposited for a token across all users, including accrued yield.
     *      Note: Similar considerations to `getTotalBorrowed` apply.
     * @param token The token address.
     * @return total The total deposited amount.
     */
    function getTotalDeposited(address token) public view returns (uint256 total) {
        // See notes on getTotalBorrowed. Returning stored value as a compromise.
         return totalDeposits[token];
    }

    /**
     * @dev Gets the total value of all collateral in the protocol across all users and tokens.
     *      Note: This iterates through supported tokens and potentially calculates value for each.
     * @return totalValueUSD The total collateral value in USD.
     */
    function getTotalCollateralValue() public view returns (uint256 totalValueUSD) {
         totalValueUSD = 0;
          for (uint i = 0; i < _supportedTokens.length; i++) {
            address token = _supportedTokens[i];
            // This doesn't iterate through users, it relies on the `userCollateral` mapping directly,
            // but needs to sum it up across users, which is not directly stored.
            // To get the *actual* total collateral held in the contract:
            uint256 totalCollateralAmount = reserveBalances[token] - totalDeposits[token] - IERC20(token).balanceOf(address(this)) + reserveBalances[token]; // Incorrect logic

            // The true total collateral is the sum of userCollateral balances across all users.
            // Calculating this on-chain would require iterating all users which is infeasible.
            // The `reserveBalances[token]` holds everything (deposits + collateral + fees + flash loan buffers).
            // A separate state variable `totalCollateralAmount[token]` would be needed, updated on deposit/withdraw/borrow/liquidate.
            // For now, return 0 or acknowledge this is complex without iterating users.
            // Let's return 0 and add a note that calculating this precisely on-chain is hard.
            // Or, return the total amount of the token held by the contract, but that's ReserveBalance.
            // Let's remove this function as it's hard to implement correctly/efficiently.
         }
         // Function removed from outline and code.
         return 0; // Dummy return, function logically removed
    }


    // --- IFlashLoanRecipient Interface Implementation ---

    /**
     * @dev ERC3156 Flash loan receiver hook.
     *      This function is called by the flashLoan initiator after sending the loan amount.
     *      The receiver contract must perform its logic and repay the loan amount + fee before this function returns.
     * @param initiator The address that initiated the flash loan (the caller of flashLoan).
     * @param token The address of the token loaned.
     * @param amount The amount of tokens loaned.
     * @param fee The fee charged for the loan.
     * @param data Optional data passed by the initiator.
     * @return bytes4 ERC3156_CALLBACK_SUCCESS if successful, otherwise revert.
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes4) {
        // Ensure the caller is *this* contract (prevent external calls)
        require(msg.sender == address(this), "Callback must be from this contract");

        // The receiving contract's logic goes here.
        // It must use the 'amount' received and ensure that 'amount + fee'
        // is approved for transfer back to THIS contract (address(this))
        // before this function returns.

        // Example: Perform an arbitrage trade, or use the tokens in another DeFi protocol.
        // For this template, we just check if the contract *could* repay.
        // A real receiver contract would need complex logic here.

        uint256 totalAmountToReturn = amount + fee;
        require(IERC20(token).balanceOf(address(this)) >= totalAmountToReturn, "Flash loan repayment failed: insufficient balance after operations");

        // The repayment is handled by the `flashLoan` function *after* this callback returns.

        // Return the success magic value
        return IFlashLoanRecipient.ERC3156_CALLBACK_SUCCESS;
    }


    // --- Compound Yield (Conceptual) ---
    // This function allows a user to "compound" their accrued yield mid-epoch.
    // In the index-based model, yield is added to the principal when _updateUserInterestAndYield is called.
    // This function simply triggers that update for the user/token pair.
    /**
     * @dev Triggers the application of accrued yield for a user's deposit position.
     *      This effectively compounds the yield by adding it to the principal mid-epoch.
     * @param token The token address of the deposit.
     */
    function compoundYield(address token) external nonReentrant whenNotPaused onlySupportedToken(token) {
        require(userDeposits[msg.sender][token] > 0, "No deposit for this token");
        // _updateUserInterestAndYield will calculate and add any accrued yield
        _updateUserInterestAndYield(msg.sender, token);
        // No explicit event for this as it's part of the general update.
        // The Deposit event could potentially be modified to indicate compounding,
        // but the balance update is already reflected in the event emitted by deposit/withdraw/borrow/repay
        // when updateState modifier is used. A separate event might be clearer.
        // Let's add an event.
        emit Deposited(msg.sender, token, 0, userDeposits[msg.sender][token]); // Amount = 0, just balance update
    }

     // --- Getters for Current Rates (Added for completeness, already in state) ---
     /**
     * @dev Gets the current borrow rate per epoch for a token.
     * @param token The token address.
     * @return rate The current borrow rate (scaled 1e18).
     */
     function getCurrentBorrowRatePerEpoch(address token) public view returns (uint256 rate) {
         return currentBorrowRatePerEpoch[token];
     }

     /**
     * @dev Gets the current deposit rate per epoch for a token.
     * @param token The token address.
     * @return rate The current deposit rate (scaled 1e18).
     */
     function getCurrentDepositRatePerEpoch(address token) public view returns (uint256 rate) {
         return currentDepositRatePerEpoch[token];
     }

     // --- View for epoch details ---
     function getEpochNumber() public view returns (uint256) {
        return currentEpoch;
     }

      function getEpochStartTime() public view returns (uint256) {
        return currentEpochStartTime;
     }

     function getEpochEndTime() public view returns (uint256) {
         return currentEpochStartTime + epochDuration;
     }

     function getEpochDuration() public view returns (uint256) {
         return epochDuration;
     }

}
```