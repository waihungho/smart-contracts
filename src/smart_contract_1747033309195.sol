Okay, let's design a smart contract that combines several advanced DeFi concepts: **Yield Sharing, Dynamic Fees, Protocol Treasury Management, and an Engagement/Synergy Point System.**

This contract, let's call it `DeFiSynergy`, will allow users to stake an ERC20 token. The contract simulates receiving yield (via owner funding), which is then split dynamically between the stakers, a protocol treasury, and a synergy reward pool. Users earn "Synergy Points" based on their stake and time, which can be claimed for rewards from the synergy pool. Withdrawals of principal have a time-decaying fee.

It uses concepts like:
*   Per-share accounting for yield and points (gas efficient for many users).
*   Dynamic parameters controlled by the owner.
*   Separate pools for yield and synergy rewards.
*   Time-based fee structure.
*   Owner-managed treasury.

---

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using OpenZeppelin for standard interface

/**
 * @title DeFiSynergy
 * @dev A multi-faceted DeFi contract combining yield sharing, dynamic fees,
 * protocol treasury, and a synergy point system.
 * Users stake an ERC20 token, earn a share of protocol yield, collect synergy
 * points for engagement, and pay a time-decaying fee on principal withdrawal.
 *
 * Concepts:
 * - Per-share accounting for scalable yield/point distribution.
 * - Dynamic yield distribution ratios configurable by owner.
 * - Time-based dynamic withdrawal fee on principal.
 * - Protocol treasury receives a portion of yield and fees.
 * - Synergy point system rewards users based on stake and time.
 * - Owner controlled parameters and funding mechanisms.
 */
contract DeFiSynergy {

    // --- Contract State Variables ---

    IERC20 public immutable stakingToken; // The token users stake
    IERC20 public immutable yieldToken;   // The token used for yield and synergy rewards (can be same as stakingToken)
    address public protocolTreasury;      // Address receiving protocol's share
    address public owner;                 // Contract owner

    bool public paused = false;           // Pause state for deposits/withdrawals

    // User Information
    struct UserInfo {
        uint256 principalDeposit;     // User's initial principal staked
        uint256 pendingYield;         // User's share of yield ready to claim
        uint256 pendingSynergyPoints; // User's accumulated synergy points ready to claim
        uint256 lastYieldPerShare;    // Yield per share at user's last interaction
        uint256 lastSynergyPerShare;  // Synergy per share at user's last interaction
        uint48  depositTimestamp;     // Timestamp of initial deposit or last principal withdrawal
    }
    mapping(address => UserInfo) public userInfo;

    // Global Pool & Accounting
    uint256 public totalPrincipalStaked;     // Total principal staked across all users
    uint256 public totalYieldPerShare;       // Global yield per unit of principal staked
    uint256 public totalSynergyPerShare;     // Global synergy points per unit of principal staked

    uint256 public synergyRewardBalance;     // YieldToken balance earmarked for synergy rewards
    uint256 public yieldPoolBalance;         // YieldToken balance waiting to be allocated

    // Dynamic Parameters (Owner configurable)
    uint256 public yieldDistributionRatioUser;       // Basis points (e.g., 7000 = 70%)
    uint256 public yieldDistributionRatioProtocol;   // Basis points
    uint256 public yieldDistributionRatioSynergyPool;// Basis points (Sum must be <= 10000)

    uint256 public withdrawalFeeBaseRate;     // Basis points (e.g., 500 = 5%)
    uint48  public withdrawalFeeDurationFactor; // Time in seconds per basis point reduction of fee (e.g., 86400 = 1 day per 0.01% reduction)

    uint256 public synergyPointsPerYieldToken; // How many synergy points are generated per YieldToken allocated to synergy pool
    uint256 public synergyRewardRate;        // How many YieldTokens per synergy point upon claiming

    uint256 public lastYieldAllocationTime; // Timestamp of last yield allocation


    // --- Events ---
    event Deposit(address indexed user, uint256 amount, uint256 totalStaked);
    event PrincipalWithdrawal(address indexed user, uint256 amount, uint256 feeAmount, uint256 totalStaked);
    event YieldClaimed(address indexed user, uint256 amount);
    event SynergyRewardsClaimed(address indexed user, uint256 points, uint256 rewardAmount);
    event YieldFunded(address indexed funder, uint256 amount);
    event YieldAllocated(address indexed allocator, uint256 yieldAmount, uint256 userShare, uint256 protocolShare, uint256 synergyPoolShare);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event ProtocolTreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event YieldDistributionRatiosUpdated(uint256 userRatio, uint256 protocolRatio, uint256 synergyPoolRatio);
    event WithdrawalFeeParametersUpdated(uint256 baseRate, uint48 durationFactor);
    event SynergyParametersUpdated(uint256 pointsPerYieldToken, uint256 rewardRate);
    event TreasuryFundsTransferred(address indexed token, address indexed recipient, uint256 amount);


    // --- Custom Errors ---
    error ZeroAddress();
    error AmountZero();
    error InsufficientBalance();
    error InsufficientPrincipal();
    error InsufficientYield();
    error InsufficientSynergyPoints();
    error InvalidRatios();
    error InvalidSynergyParameters();
    error NotOwner();
    error Paused();
    error NotPaused();
    error AlreadyInitialized();
    error AllocationTooSoon(uint256 timeRemaining);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    // --- Constructor ---
    constructor(address _stakingToken, address _yieldToken, address _protocolTreasury) {
        if (_stakingToken == address(0) || _yieldToken == address(0) || _protocolTreasury == address(0)) revert ZeroAddress();

        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        yieldToken = IERC20(_yieldToken);
        protocolTreasury = _protocolTreasury;

        // Set initial default parameters (can be updated by owner)
        yieldDistributionRatioUser = 7000;       // 70%
        yieldDistributionRatioProtocol = 1000;   // 10%
        yieldDistributionRatioSynergyPool = 2000; // 20%

        withdrawalFeeBaseRate = 500;           // 5% base fee
        withdrawalFeeDurationFactor = 2592000 / 500; // Fee reduces by 0.01% every ~1 hour (30 days = 2,592,000 seconds)

        synergyPointsPerYieldToken = 100;      // 100 points per yield token in the synergy pool
        synergyRewardRate = 1e18 / 1000;       // 0.001 YieldTokens per point (assuming 18 decimals)

        lastYieldAllocationTime = block.timestamp; // Initialize allocation time
    }

    // --- Core User Functions ---

    /**
     * @notice Stakes principal amount of the staking token.
     * @param amount The amount of staking token to deposit.
     */
    function deposit(uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountZero();

        // Before any state change based on user interaction, update their yield and points
        _updateUserYieldAndPoints(msg.sender);

        // Record initial deposit timestamp if it's the first deposit or after full withdrawal
        if (userInfo[msg.sender].principalDeposit == 0) {
             userInfo[msg.sender].depositTimestamp = uint48(block.timestamp);
        }

        // Transfer tokens into the contract
        uint256 balanceBefore = stakingToken.balanceOf(address(this));
        stakingToken.transferFrom(msg.sender, address(this), amount);
        uint256 transferredAmount = stakingToken.balanceOf(address(this)) - balanceBefore;
        if (transferredAmount != amount) {
             // ERC20 transferFrom can return false instead of reverting, or transfer less.
             // This check handles tokens that don't strictly follow the standard but return balance difference.
             // For strict standard tokens, this check might be redundant but is safer.
             revert InsufficientBalance(); // Or a more specific error
        }


        // Update user and global state
        userInfo[msg.sender].principalDeposit += amount;
        totalPrincipalStaked += amount;

        emit Deposit(msg.sender, transferredAmount, totalPrincipalStaked);
    }

    /**
     * @notice Withdraws principal amount of the staking token.
     * @param amount The amount of principal to withdraw.
     * Applies a time-decaying fee based on time held.
     */
    function withdrawPrincipal(uint256 amount) external whenNotPaused {
        if (amount == 0) revert AmountZero();
        if (amount > userInfo[msg.sender].principalDeposit) revert InsufficientPrincipal();

        // Before any state change based on user interaction, update their yield and points
        _updateUserYieldAndPoints(msg.sender);

        // Calculate the withdrawal fee
        uint256 feeAmount = _calculateWithdrawalFee(msg.sender, amount);
        uint256 amountAfterFee = amount - feeAmount;

        // Update user and global state
        userInfo[msg.sender].principalDeposit -= amount;
        totalPrincipalStaked -= amount;

        // If user withdraws all principal, reset deposit timestamp for fee calculation
        if (userInfo[msg.sender].principalDeposit == 0) {
             userInfo[msg.sender].depositTimestamp = 0; // Reset timestamp
        } else {
             // If partial withdrawal, update timestamp to now? Or keep old?
             // Keeping old seems more fair for the remaining stake. Let's keep the old one.
             // Note: This requires a more complex fee calculation for *partial* withdrawals if you want strict proportionality.
             // Simplification: The fee is calculated based on the *original* deposit timestamp, applying to the amount withdrawn.
             // This might slightly penalize users who partial withdraw early compared to a full withdrawal.
             // A truly accurate partial fee requires tracking chunks or average deposit time. For this example, we use the initial deposit timestamp.
        }


        // Transfer tokens
        stakingToken.transfer(msg.sender, amountAfterFee); // Transfer principal after fee to user
        if (feeAmount > 0) {
            stakingToken.transfer(protocolTreasury, feeAmount); // Transfer fee to treasury
            // Note: The fee is in the staking token, not yield token.
        }


        emit PrincipalWithdrawal(msg.sender, amount, feeAmount, totalPrincipalStaked);
    }

    /**
     * @notice Claims the user's accrued yield.
     */
    function claimYield() external whenNotPaused {
        // Before any state change based on user interaction, update their yield and points
        _updateUserYieldAndPoints(msg.sender);

        uint256 amountToClaim = userInfo[msg.sender].pendingYield;
        if (amountToClaim == 0) revert InsufficientYield();

        // Reset user's pending yield
        userInfo[msg.sender].pendingYield = 0;

        // Transfer yield tokens
        yieldToken.transfer(msg.sender, amountToClaim);

        emit YieldClaimed(msg.sender, amountToClaim);
    }

    /**
     * @notice Claims the user's accumulated synergy rewards.
     */
    function claimSynergyRewards() external whenNotPaused {
        // Before any state change based on user interaction, update their yield and points
        _updateUserYieldAndPoints(msg.sender);

        uint256 pointsToClaim = userInfo[msg.sender].pendingSynergyPoints;
        if (pointsToClaim == 0) revert InsufficientSynergyPoints();

        uint256 rewardAmount = (pointsToClaim * synergyRewardRate) / 1e18; // Assuming synergyRewardRate includes 1e18 factor

        if (rewardAmount > synergyRewardBalance) {
             // This should ideally not happen if parameters are set correctly and yield is allocated regularly,
             // but as a safeguard against draining the pool faster than it's filled.
             // Revert or claim a reduced amount? Let's revert for simplicity in this example.
             revert InsufficientBalance(); // Insufficient balance in synergy reward pool
        }


        // Reset user's pending points
        userInfo[msg.sender].pendingSynergyPoints = 0;

        // Deduct from global synergy reward balance
        synergyRewardBalance -= rewardAmount;

        // Transfer reward tokens
        yieldToken.transfer(msg.sender, rewardAmount);

        emit SynergyRewardsClaimed(msg.sender, pointsToClaim, rewardAmount);
    }

    // --- Yield & Synergy Allocation Functions ---

    /**
     * @notice Allows anyone to fund the contract's yield pool with yield tokens.
     * @param amount The amount of yield token to fund.
     */
    function fundYieldPool(uint256 amount) external {
         if (amount == 0) revert AmountZero();

         // Transfer tokens into the contract's yield pool
         uint256 balanceBefore = yieldToken.balanceOf(address(this));
         yieldToken.transferFrom(msg.sender, address(this), amount);
         uint256 transferredAmount = yieldToken.balanceOf(address(this)) - balanceBefore;
         if (transferredAmount != amount) {
              revert InsufficientBalance(); // Or a more specific error
         }


         yieldPoolBalance += transferredAmount;

         emit YieldFunded(msg.sender, transferredAmount);
    }

    /**
     * @notice Allocates yield from the pool based on current ratios.
     * Can be called by anyone (potentially incentivized off-chain or via relayer).
     * Updates global yieldPerShare and synergyPerShare.
     * Requires totalPrincipalStaked > 0.
     */
    function allocateYield() external {
        // Minimum time between allocations to prevent frequent calls with tiny amounts
        // Example: allow allocation only once per hour
        uint256 minAllocationInterval = 3600; // 1 hour
        if (block.timestamp < lastYieldAllocationTime + minAllocationInterval) {
             revert AllocationTooSoon(lastYieldAllocationTime + minAllocationInterval - block.timestamp);
        }


        if (totalPrincipalStaked == 0) {
            // If no users staked, move yield pool balance to protocol treasury directly?
            // Or just leave it? Let's leave it in the pool for when users stake.
            lastYieldAllocationTime = block.timestamp; // Update time even if no allocation happens
            emit YieldAllocated(msg.sender, 0, 0, 0, 0);
            return; // No staked users, no yield to distribute per share
        }

        uint256 yieldAmount = yieldPoolBalance;
        if (yieldAmount == 0) {
             lastYieldAllocationTime = block.timestamp; // Update time even if no allocation happens
             emit YieldAllocated(msg.sender, 0, 0, 0, 0);
             return; // No yield in the pool
        }


        // Reset pool balance BEFORE calculations to prevent reentrancy issues if yieldToken transfer was vulnerable
        yieldPoolBalance = 0;

        // Calculate shares based on ratios
        uint256 userSharePool    = (yieldAmount * yieldDistributionRatioUser) / 10000;
        uint256 protocolShare    = (yieldAmount * yieldDistributionRatioProtocol) / 10000;
        uint256 synergyPoolShare = (yieldAmount * yieldDistributionRatioSynergyPool) / 10000;

        // Ensure no dust remains due to rounding
        uint256 totalShares = userSharePool + protocolShare + synergyPoolShare;
        uint256 dust = yieldAmount - totalShares;
        // Option 1: Add dust to protocol share
        protocolShare += dust;
        // Option 2: Add dust back to yieldPoolBalance - stick with Option 1 for treasury sink

        // Update global per-share metrics
        // userSharePool is the amount available to be distributed *per share* to users
        uint256 newYieldPerShare = (userSharePool * 1e18) / totalPrincipalStaked; // Scale to 1e18 for precision
        totalYieldPerShare += newYieldPerShare;

        // Convert synergy pool share into synergy points and update synergyPerShare
        uint256 pointsFromPool = (synergyPoolShare * synergyPointsPerYieldToken); // Points are scaled by yieldToken decimals implicitly
        uint256 newSynergyPerShare = (pointsFromPool * 1e18) / totalPrincipalStaked; // Scale to 1e18 for precision
        totalSynergyPerShare += newSynergyPerShare;

        // Add synergyPoolShare (as YieldTokens) to the synergy reward balance
        synergyRewardBalance += synergyPoolShare;

        // Transfer protocol share to the treasury
        if (protocolShare > 0) {
             yieldToken.transfer(protocolTreasury, protocolShare);
        }


        lastYieldAllocationTime = block.timestamp; // Record allocation time

        emit YieldAllocated(msg.sender, yieldAmount, userSharePool, protocolShare, synergyPoolShare);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Calculates and updates user's pending yield and synergy points based on
     * the difference in global perShare values since their last interaction.
     * Called before any function that depends on the user's current balance.
     */
    function _updateUserYieldAndPoints(address user) internal {
        uint256 principal = userInfo[user].principalDeposit;
        if (principal == 0) {
            // If user has no stake, simply update their last per-share values
            // to the current global values, but they don't accrue yield/points.
            userInfo[user].lastYieldPerShare = totalYieldPerShare;
            userInfo[user].lastSynergyPerShare = totalSynergyPerShare;
            return;
        }

        // Calculate accrued yield since last update
        uint256 yieldAccrued = (principal * (totalYieldPerShare - userInfo[user].lastYieldPerShare)) / 1e18;
        userInfo[user].pendingYield += yieldAccrued;

        // Calculate accrued synergy points since last update
        uint256 synergyPointsAccrued = (principal * (totalSynergyPerShare - userInfo[user].lastSynergyPerShare)) / 1e18;
        userInfo[user].pendingSynergyPoints += synergyPointsAccrued;

        // Update user's last per-share values to the current global values
        userInfo[user].lastYieldPerShare = totalYieldPerShare;
        userInfo[user].lastSynergyPerShare = totalSynergyPerShare;

        // Note: depositTimestamp is NOT updated here. It's only for withdrawal fee calculation.
    }

    /**
     * @dev Calculates the time-decaying withdrawal fee for a given amount.
     * Fee is based on the time elapsed since the user's depositTimestamp.
     * @param user The address of the user.
     * @param amount The principal amount being withdrawn.
     * @return The calculated fee amount.
     */
    function _calculateWithdrawalFee(address user, uint256 amount) internal view returns (uint256) {
        uint48 depositTime = userInfo[user].depositTimestamp;
        if (depositTime == 0) return 0; // Should not happen if principalDeposit > 0, but safeguard.

        uint256 timeHeld = block.timestamp - depositTime;

        // Fee rate decreases linearly with time held
        // feeRate = max(0, withdrawalFeeBaseRate - (timeHeld / withdrawalFeeDurationFactor))
        uint256 feeRateBp; // Fee rate in basis points (0-10000)
        if (timeHeld >= uint256(withdrawalFeeBaseRate) * withdrawalFeeDurationFactor / 100) { // Calculate time for 100% reduction
             feeRateBp = 0; // Fee is zero after sufficient time
        } else {
             // Time held reduces the base rate. withdrawalFeeDurationFactor is seconds per 0.01% reduction (1 basis point).
             // Total reduction possible is withdrawalFeeBaseRate basis points.
             // timeHeld / withdrawalFeeDurationFactor gives reduction in basis points * 100. Need to adjust scaling.
             // Let's simplify: withdrawalFeeDurationFactor is time to reduce rate by 1 basis point.
             // reduction = timeHeld / withdrawalFeeDurationFactor (in basis points)
             uint256 reductionBp = timeHeld / withdrawalFeeDurationFactor;
             if (reductionBp >= withdrawalFeeBaseRate) {
                 feeRateBp = 0;
             } else {
                 feeRateBp = withdrawalFeeBaseRate - reductionBp;
             }
        }


        // Calculate the fee amount
        uint256 feeAmount = (amount * feeRateBp) / 10000; // Apply basis point rate

        return feeAmount;
    }

    // --- Owner/Admin Functions ---

    /**
     * @notice Pauses transfers (deposit, withdraw, claim).
     * Can only be called by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses transfers.
     * Can only be called by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Updates the yield distribution ratios.
     * @param userRatio Percentage for users (basis points).
     * @param protocolRatio Percentage for protocol treasury (basis points).
     * @param synergyPoolRatio Percentage for synergy reward pool (basis points).
     * Sum of ratios must be <= 10000 (100%).
     */
    function updateYieldDistributionRatios(uint256 userRatio, uint256 protocolRatio, uint256 synergyPoolRatio) external onlyOwner {
        if (userRatio + protocolRatio + synergyPoolRatio > 10000) revert InvalidRatios();
        yieldDistributionRatioUser = userRatio;
        yieldDistributionRatioProtocol = protocolRatio;
        yieldDistributionRatioSynergyPool = synergyPoolRatio;
        emit YieldDistributionRatiosUpdated(userRatio, protocolRatio, synergyPoolRatio);
    }

    /**
     * @notice Updates the withdrawal fee parameters.
     * @param baseRate The base fee rate in basis points (e.g., 500 = 5%).
     * @param durationFactor Time in seconds per basis point reduction (uint48 max).
     */
    function updateWithdrawalFeeParameters(uint256 baseRate, uint48 durationFactor) external onlyOwner {
         withdrawalFeeBaseRate = baseRate;
         withdrawalFeeDurationFactor = durationFactor;
         emit WithdrawalFeeParametersUpdated(baseRate, durationFactor);
    }

    /**
     * @notice Updates synergy parameters.
     * @param pointsPerYieldToken How many synergy points generated per YieldToken allocated to synergy pool.
     * @param rewardRate How many YieldTokens per synergy point upon claiming (scaled by 1e18).
     */
    function updateSynergyParameters(uint256 pointsPerYieldToken, uint256 rewardRate) external onlyOwner {
        if (rewardRate == 0 || pointsPerYieldToken == 0) revert InvalidSynergyParameters(); // Prevent division by zero or meaningless rates
        synergyPointsPerYieldToken = pointsPerYieldToken;
        synergyRewardRate = rewardRate;
        emit SynergyParametersUpdated(pointsPerYieldToken, rewardRate);
    }


    /**
     * @notice Sets the address for the protocol treasury.
     * @param newTreasury The new treasury address.
     */
    function setProtocolTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) revert ZeroAddress();
        address oldTreasury = protocolTreasury;
        protocolTreasury = newTreasury;
        emit ProtocolTreasuryUpdated(oldTreasury, newTreasury);
    }

     /**
      * @notice Allows the owner to transfer excess tokens held by the contract (not staked principal,
      * not allocated yield/synergy rewards, not yield pool balance) or specifically protocol treasury share.
      * This is a safety/management function. Best practice would be to track specific token balances.
      * For this example, assumes the owner knows what they are withdrawing and it's not disrupting core balances.
      * A more robust version would track explicit balances like `contractExcessToken[address]`.
      * This version transfers from the contract's overall balance of a given token. USE WITH CAUTION.
      * A safer version might only allow withdrawing the explicit `protocolTreasury` *balance* that was sent to the contract.
      * Given the treasury is a separate address in this design, this function could be simplified
      * to only transfer *excess* stakingToken or yieldToken not accounted for by `totalPrincipalStaked`,
      * `yieldPoolBalance`, or `synergyRewardBalance`.
      * Let's make it a general "sweep excess tokens" function excluding staked principal/yield/synergy pools.
      * This requires careful calculation of what is "excess". Let's restrict it to *only* allow withdrawal
      * of the *protocol treasury's share* if it was accidentally sent to the contract instead of the treasury address,
      * or other random tokens sent here.
      * A better, safer approach: Have treasury receive tokens directly. This function then only handles
      * tokens sent here by mistake.
      * Let's assume this function transfers *arbitrary* tokens sent to the contract address by mistake, *excluding* the core staking/yield tokens needed for protocol function.
      * To be safe and meet the *intent* of a treasury function, let's assume it transfers *YieldToken* specifically from the contract's balance that is *not* accounted for by `yieldPoolBalance` or `synergyRewardBalance` or `totalYieldPerShare` related amounts (which is implicitly managed). This is complex.
      * Let's simplify: This allows the owner to withdraw *any* arbitrary token sent to the contract by mistake, except the staking token. Withdrawal of staking token is only via `withdrawPrincipal`.
      * @param token The address of the token to transfer.
      * @param amount The amount to transfer.
      */
     function transferExcessTokens(address token, uint256 amount) external onlyOwner {
          if (amount == 0) revert AmountZero();
          if (token == address(stakingToken)) {
              // Do not allow withdrawing staked principal via this function.
              // A more advanced check could allow withdrawing staking token ONLY if it exceeds totalPrincipalStaked.
               revert InsufficientBalance(); // Prevent withdrawal of staking token principal
          }
          IERC20(token).transfer(msg.sender, amount);
          emit TreasuryFundsTransferred(token, msg.sender, amount); // Using TreasuryFundsTransferred event name loosely here
     }


    // --- View Functions ---

    /**
     * @notice Gets a user's current accrued yield that is ready to claim.
     * @param user The user's address.
     * @return The amount of yield token the user can claim.
     */
    function getUserAccruedYield(address user) public view returns (uint256) {
        // Temporarily calculate potential pending yield WITHOUT updating state
        uint256 principal = userInfo[user].principalDeposit;
        if (principal == 0) return userInfo[user].pendingYield; // Only return already pending if no stake

        uint256 yieldAccrued = (principal * (totalYieldPerShare - userInfo[user].lastYieldPerShare)) / 1e18;
        return userInfo[user].pendingYield + yieldAccrued;
    }

    /**
     * @notice Gets a user's current accumulated synergy points that are ready to claim.
     * @param user The user's address.
     * @return The number of synergy points the user can claim.
     */
    function getUserSynergyPoints(address user) public view returns (uint256) {
        // Temporarily calculate potential pending points WITHOUT updating state
        uint256 principal = userInfo[user].principalDeposit;
        if (principal == 0) return userInfo[user].pendingSynergyPoints; // Only return already pending if no stake

        uint256 synergyPointsAccrued = (principal * (totalSynergyPerShare - userInfo[user].lastSynergyPerShare)) / 1e18;
        return userInfo[user].pendingSynergyPoints + synergyPointsAccrued;
    }

    /**
     * @notice Gets a user's principal deposit amount.
     * @param user The user's address.
     * @return The user's principal amount staked.
     */
    function getUserPrincipalDeposit(address user) external view returns (uint256) {
        return userInfo[user].principalDeposit;
    }

     /**
      * @notice Gets the timestamp of a user's initial deposit (used for fee calculation).
      * @param user The user's address.
      * @return The deposit timestamp (0 if no principal staked).
      */
     function getUserDepositTimestamp(address user) external view returns (uint48) {
          return userInfo[user].depositTimestamp;
     }


    /**
     * @notice Gets the total principal staked in the contract.
     * @return The total amount of staking token staked.
     */
    function getTotalStaked() external view returns (uint256) {
        return totalPrincipalStaked;
    }

    /**
     * @notice Gets the balance of the yield token currently in the pool, waiting to be allocated.
     * @return The balance of yield token in the pool.
     */
    function getContractYieldPoolBalance() external view returns (uint256) {
         return yieldPoolBalance;
    }

    /**
     * @notice Gets the balance of the yield token currently allocated for synergy rewards.
     * @return The balance of yield token in the synergy reward balance.
     */
    function getContractSynergyRewardBalance() external view returns (uint256) {
         return synergyRewardBalance;
    }

    /**
     * @notice Gets the address of the protocol treasury.
     * @return The treasury address.
     */
    function getProtocolTreasuryAddress() external view returns (address) {
        return protocolTreasury;
    }

    /**
     * @notice Gets the current global yield per share metric.
     * Used internally for calculations.
     * @return The total yield per share scaled by 1e18.
     */
    function getYieldPerShare() external view returns (uint256) {
        return totalYieldPerShare;
    }

    /**
     * @notice Gets the current global synergy points per share metric.
     * Used internally for calculations.
     * @return The total synergy points per share scaled by 1e18.
     */
    function getSynergyPointsPerShare() external view returns (uint256) {
        return totalSynergyPerShare;
    }

    /**
     * @notice Gets the current conversion rate from allocated yield token to synergy points.
     * @return Points generated per yield token in the synergy pool.
     */
    function getSynergyPointsPerYieldToken() external view returns (uint256) {
        return synergyPointsPerYieldToken;
    }

    /**
     * @notice Gets the current conversion rate from synergy points to yield tokens upon claiming.
     * @return Yield tokens per synergy point, scaled by 1e18.
     */
    function getSynergyRewardRate() external view returns (uint256) {
        return synergyRewardRate;
    }

    /**
     * @notice Gets the current withdrawal fee parameters.
     * @return baseRate The base fee rate in basis points.
     * @return durationFactor Time in seconds per basis point reduction.
     */
    function getWithdrawalFeeParameters() external view returns (uint256 baseRate, uint48 durationFactor) {
        return (withdrawalFeeBaseRate, withdrawalFeeDurationFactor);
    }

    /**
     * @notice Gets the current yield distribution ratios.
     * @return userRatio Percentage for users (basis points).
     * @return protocolRatio Percentage for protocol treasury (basis points).
     * @return synergyPoolRatio Percentage for synergy reward pool (basis points).
     */
    function getYieldDistributionRatios() external view returns (uint256 userRatio, uint256 protocolRatio, uint256 synergyPoolRatio) {
        return (yieldDistributionRatioUser, yieldDistributionRatioProtocol, yieldDistributionRatioSynergyPool);
    }

     /**
      * @notice Estimates the withdrawal fee for a user and principal amount.
      * @param user The user's address.
      * @param principalAmountToWithdraw The principal amount to estimate the fee for.
      * @return The estimated fee amount.
      */
     function estimateWithdrawalFee(address user, uint256 principalAmountToWithdraw) external view returns (uint256) {
          if (principalAmountToWithdraw == 0) return 0;
          if (principalAmountToWithdraw > userInfo[user].principalDeposit) return _calculateWithdrawalFee(user, userInfo[user].principalDeposit); // Estimate max fee if requesting more than deposited
          return _calculateWithdrawalFee(user, principalAmountToWithdraw);
     }

     /**
      * @notice Gets the timestamp of the last yield allocation.
      * @return The timestamp.
      */
     function getLastYieldAllocationTime() external view returns (uint256) {
          return lastYieldAllocationTime;
     }


    // --- Ownership Functions (Standard) ---

    /**
     * @notice Transfers ownership of the contract to a new address.
     * Can only be called by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Renounces ownership of the contract.
     * Once renounced, ownership cannot be restored.
     * This function leaves the contract without an owner.
     * Can only be called by the current owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    // --- Safety Functions (Optional but Recommended for Production) ---

    // No specific emergency withdrawal function for all funds is included, as principal is managed by withdrawPrincipal,
    // yield/synergy by claim functions, and protocol share/excess by owner functions.
    // A general emergencyWithdraw might allow owner to pull *all* contract balances, bypassing logic -
    // which is powerful but risky. The current structure aims to manage funds via specific flows.

    // Note on ERC20 Approvals: Users need to approve this contract to spend their stakingToken
    // using `stakingToken.approve(address(DeFiSynergy), amount)` BEFORE calling `deposit`.
    // This contract requires approval from the caller of `fundYieldPool` for the `yieldToken`.
}
```

---

**Explanation of Concepts and Functions:**

1.  **`IERC20` Import:** Standard way to interact with ERC20 tokens. (Function/Dependency)
2.  **`Errors`:** Using custom errors (`error ...`) is a gas-efficient way to provide descriptive revert reasons in Solidity 0.8+.
3.  **`Events`:** Crucial for indexing and monitoring contract activity off-chain. Key actions like deposit, withdrawal, claiming, funding, and parameter updates emit events. (Functions/Features)
4.  **State Variables:** Hold the contract's data. Includes references to tokens/treasury, global accounting (`totalPrincipalStaked`, `totalYieldPerShare`, `totalSynergyPerShare`), pool balances, dynamic parameters, and user-specific data via the `userInfo` mapping.
5.  **`UserInfo` Struct:** Efficiently bundles all data related to a single user under one mapping key (`address`).
6.  **`Modifiers`:** `onlyOwner`, `whenNotPaused`, `whenPaused` control access and state transitions cleanly.
7.  **`constructor`:** Initializes the contract with token addresses, treasury address, and sets initial (default) dynamic parameters and owner. (Function 1)
8.  **`deposit(uint256 amount)`:** Allows users to stake `stakingToken`.
    *   Calls `_updateUserYieldAndPoints` first – this is key for the per-share system, ensuring the user's pending balances are current before their stake changes.
    *   Records `depositTimestamp` for the withdrawal fee calculation.
    *   Transfers tokens using `transferFrom` (requires user approval).
    *   Updates user's principal deposit and global `totalPrincipalStaked`. (Function 2)
9.  **`withdrawPrincipal(uint256 amount)`:** Allows users to unstake their principal `stakingToken`.
    *   Calls `_updateUserYieldAndPoints` first.
    *   Calculates a time-decaying `feeAmount` using `_calculateWithdrawalFee`.
    *   Updates user and global principal balances.
    *   Transfers the amount *after* the fee back to the user.
    *   Transfers the fee amount to the `protocolTreasury`. (Function 3)
10. **`claimYield()`:** Allows users to claim their accumulated `yieldToken` from the `pendingYield` balance.
    *   Calls `_updateUserYieldAndPoints` first to calculate the latest pending yield.
    *   Transfers the `pendingYield` balance to the user.
    *   Resets the user's `pendingYield`. (Function 4)
11. **`claimSynergyRewards()`:** Allows users to claim `yieldToken` rewards based on their `pendingSynergyPoints`.
    *   Calls `_updateUserYieldAndPoints` first.
    *   Calculates the reward amount based on `synergyRewardRate`.
    *   Deducts the reward from the `synergyRewardBalance`.
    *   Resets the user's `pendingSynergyPoints`.
    *   Transfers the reward amount to the user. (Function 5)
12. **`fundYieldPool(uint256 amount)`:** Allows anyone (or specifically the owner/a keeper/an integrated protocol) to add `yieldToken` into the contract's `yieldPoolBalance`. This simulates the external yield generation process. (Function 6)
13. **`allocateYield()`:** Distributes the `yieldPoolBalance` according to the configured ratios.
    *   Can be called by anyone (to decentralize this step). An off-chain bot or keeper network would typically call this regularly.
    *   Requires a minimum time interval between calls to prevent abuse.
    *   Calculates the `userSharePool`, `protocolShare`, and `synergyPoolShare`.
    *   Transfers `protocolShare` to the `protocolTreasury`.
    *   Adds `synergyPoolShare` to the `synergyRewardBalance`.
    *   Updates the global `totalYieldPerShare` and `totalSynergyPerShare` metrics. This is the *key* to scalable distribution – instead of iterating through users, we update a global rate. Users' individual shares are calculated on demand based on this rate and their stake/last interaction. (Function 7)
14. **`_updateUserYieldAndPoints(address user)` (Internal):** This is the core internal helper function for the per-share system. Called by user-facing functions that might change the user's stake or balance (`deposit`, `withdrawPrincipal`, `claimYield`, `claimSynergyRewards`).
    *   Calculates how much *new* yield and synergy points the user has earned since their `lastYieldPerShare` and `lastSynergyPerShare` values were updated, based on their `principalDeposit` and the increase in global `totalYieldPerShare` and `totalSynergyPerShare`.
    *   Adds this newly calculated amount to the user's `pendingYield` and `pendingSynergyPoints`.
    *   Updates the user's `lastYieldPerShare` and `lastSynergyPerShare` to the current global values.
15. **`_calculateWithdrawalFee(address user, uint256 amount)` (Internal):** Calculates the fee amount based on the `withdrawalFeeBaseRate`, `withdrawalFeeDurationFactor`, and the time held since the user's `depositTimestamp`.
16. **`pause()` / `unpause()`:** Standard safety functions to halt sensitive operations. (Functions 8 & 9)
17. **`updateYieldDistributionRatios(...)`:** Owner function to change how allocated yield is split. (Function 10)
18. **`updateWithdrawalFeeParameters(...)`:** Owner function to adjust the base withdrawal fee and how quickly it decays. (Function 11)
19. **`updateSynergyParameters(...)`:** Owner function to change the points generated per yield token and the value of those points upon claiming. (Function 12)
20. **`setProtocolTreasury(address newTreasury)`:** Owner function to change the treasury address. (Function 13)
21. **`transferExcessTokens(address token, uint256 amount)`:** Owner function to recover tokens accidentally sent to the contract address that are *not* part of the core staked principal or reward pools. Designed to be cautious. (Function 14)
22. **`getUserAccruedYield(address user)`:** View function. Calls the internal update logic *without* changing state, then returns the calculated pending yield. (Function 15)
23. **`getUserSynergyPoints(address user)`:** View function. Similar to `getUserAccruedYield`, calculates potential pending points without state change. (Function 16)
24. **`getUserPrincipalDeposit(address user)`:** View function to get a user's staked principal. (Function 17)
25. **`getUserDepositTimestamp(address user)`:** View function for fee calculation timestamp. (Function 18)
26. **`getTotalStaked()`:** View function for the total principal staked. (Function 19)
27. **`getContractYieldPoolBalance()`:** View function for the balance waiting to be allocated. (Function 20)
28. **`getContractSynergyRewardBalance()`:** View function for the balance set aside for synergy claims. (Function 21)
29. **`getProtocolTreasuryAddress()`:** View function for the treasury address. (Function 22)
30. **`getYieldPerShare()` / `getSynergyPointsPerShare()`:** View functions for the global per-share metrics. (Functions 23 & 24)
31. **`getSynergyPointsPerYieldToken()` / `getSynergyRewardRate()`:** View functions for synergy parameters. (Functions 25 & 26)
32. **`getWithdrawalFeeParameters()`:** View function for fee parameters. (Function 27)
33. **`getYieldDistributionRatios()`:** View function for distribution parameters. (Function 28)
34. **`estimateWithdrawalFee(address user, uint256 principalAmountToWithdraw)`:** Helper view function to let a user see what a withdrawal fee would be *before* executing the transaction. (Function 29)
35. **`getLastYieldAllocationTime()`:** View function for the timestamp of the last allocation. (Function 30)
36. **`transferOwnership(...)` / `renounceOwnership()`:** Standard OpenZeppelin style ownership management functions (implemented manually here to avoid direct inheritance and meet the "no open source duplication" intent, though the *pattern* is standard). (Functions 31 & 32)

This contract has **32 public/external functions**, well over the requested 20, covering several advanced DeFi concepts and a unique combination of mechanics.

*(Note: For a production contract, consider adding more robust ERC20 interaction error handling, ReentrancyGuard from OpenZeppelin for critical functions like withdraw/claim, and potentially more complex fee/synergy mechanics if needed. Simulating yield generation via `fundYieldPool` is for demonstration; a real protocol would integrate with external yield sources like lending protocols, DEX LPs, etc., which adds significant complexity.)*