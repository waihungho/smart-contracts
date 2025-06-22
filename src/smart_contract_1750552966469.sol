Okay, let's design a smart contract that acts as a multi-asset treasury with several advanced and dynamic distribution mechanisms, controlled by weighted strategies. We'll call it `QuantumTreasury` to reflect its dynamic and potentially non-deterministic (due to randomness) nature.

It will hold ETH and multiple ERC-20 tokens and distribute them to beneficiaries based on configurable rules: fixed shares, stake-based shares, vesting schedules, and even a lottery. The distribution weights for these strategies can be adjusted.

We will use OpenZeppelin's `SafeERC20` for secure token transfers.

---

**Outline:**

1.  **State Variables:** Define contract state, including owner, allowed tokens, beneficiaries with their info (shares, vesting IDs), distribution weights, user stakes, vesting schedules, lottery state, and claimable balances.
2.  **Enums & Structs:** Define enums for distribution strategies and structs for beneficiary info, vesting schedules, and potentially lottery state.
3.  **Events:** Define events for deposits, withdrawals, beneficiary changes, stake changes, distribution triggers, claims, and lottery outcomes.
4.  **Modifiers:** Define `onlyOwner` and state-related modifiers (`whenNotPaused`).
5.  **Constructor:** Initialize the contract owner.
6.  **Receive/Fallback:** Allow receiving ETH.
7.  **Admin/Setup Functions:** Functions for the owner to manage allowed tokens, beneficiaries, distribution weights, vesting schedules, oracle address (placeholder for external conditions), pause/unpause, sweeping dust, and emergency withdrawal.
8.  **Funding Functions:** Function for depositing ERC-20 tokens.
9.  **User Interaction Functions:** Functions for staking, unstaking, and claiming distributions (vested, fixed, stake-based, lottery).
10. **Distribution Logic:**
    *   Internal functions (`_distributeFixed`, `_distributeStakeBased`, `_runLotteryDistribution`, `_distributeVested`) to calculate and update claimable amounts based on each strategy.
    *   A main `triggerDistributionRound` function (callable by anyone, potentially with checks) that orchestrates the distribution for a given token based on the configured weights, updating claimable balances.
11. **Query Functions:** View functions to inspect contract state, check balances, get beneficiary info, distribution settings, claimable amounts, and lottery state.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract with the owner.
2.  `receive() external payable`: Allows receiving ETH deposits.
3.  `addAllowedToken(address _token)`: Owner adds an ERC-20 token address to the list of allowed deposit/distribution tokens.
4.  `removeAllowedToken(address _token)`: Owner removes an ERC-20 token address from the allowed list.
5.  `addBeneficiary(address _beneficiary, uint256 _fixedShareBps)`: Owner adds a beneficiary and sets their initial fixed share (in basis points).
6.  `removeBeneficiary(address _beneficiary)`: Owner removes a beneficiary.
7.  `setBeneficiaryFixedShare(address _beneficiary, uint256 _fixedShareBps)`: Owner updates a beneficiary's fixed share (in basis points).
8.  `setDistributionWeight(DistributionStrategy _strategy, uint256 _weightBps)`: Owner sets the distribution weight (in basis points) for a specific strategy. Weights must sum to 10000.
9.  `setVestingSchedule(address _beneficiary, uint256 _amount, uint256 _start, uint256 _duration, uint256 _cliff, uint256 _interval)`: Owner sets or updates a vesting schedule for a beneficiary.
10. `depositERC20(address _token, uint256 _amount)`: Users or other contracts deposit allowed ERC-20 tokens into the treasury.
11. `stakeForDistribution(address _token, uint256 _amount)`: Users stake an allowed token to earn stake-based distribution shares for *another* token (e.g., stake TokenA to earn TokenB).
12. `unstakeForDistribution(address _token, uint256 _amount)`: Users unstake tokens.
13. `registerForLottery()`: Users register for the current lottery round.
14. `triggerLotteryDraw(address _token)`: Callable function (potentially permissioned or condition-based) to draw the winner for the lottery distribution of a specific token. Uses block hash for randomness (note: insecure for high value).
15. `claimVestedTokens(address _token)`: Beneficiaries claim their vested tokens for a specific token.
16. `claimFixedShare(address _token)`: Beneficiaries claim their calculated fixed share for a specific token from available claimable balance.
17. `claimStakeShare(address _token)`: Beneficiaries claim their calculated stake-based share for a specific token from available claimable balance.
18. `claimLotteryWin(address _token)`: Lottery winner claims their prize for a specific token.
19. `triggerDistributionRound(address _token)`: Callable function (potentially permissioned or condition-based) to process a distribution round for a specific token based on configured weights, updating claimable balances for beneficiaries.
20. `isAllowedToken(address _token) public view`: Checks if a token is allowed.
21. `getBeneficiaryInfo(address _beneficiary) public view`: Gets information about a beneficiary.
22. `getERC20Balance(address _token) public view`: Gets the treasury's balance of a specific ERC-20 token.
23. `getETHBalance() public view`: Gets the treasury's ETH balance.
24. `getDistributionWeight(DistributionStrategy _strategy) public view`: Gets the distribution weight for a strategy.
25. `getVestingSchedule(address _beneficiary) public view`: Gets the vesting schedule details for a beneficiary.
26. `getUserStake(address _user, address _token) public view`: Gets a user's stake amount for a specific token.
27. `isParticipatingInLottery(address _user) public view`: Checks if a user is registered for the current lottery round.
28. `getLotteryWinner(address _token) public view`: Gets the winner of the last lottery round for a token.
29. `getCurrentLotteryRound() public view`: Gets the current lottery round number.
30. `getClaimedVestedAmount(address _beneficiary, address _token) public view`: Gets the total amount of a token claimed by a beneficiary via vesting.
31. `getClaimableFixed(address _beneficiary, address _token) public view`: Calculates the currently claimable fixed share for a beneficiary for a token.
32. `getClaimableStakeBased(address _beneficiary, address _token) public view`: Calculates the currently claimable stake-based share for a beneficiary for a token.
33. `getClaimableLottery(address _beneficiary, address _token) public view`: Calculates the currently claimable lottery win for a beneficiary for a token.
34. `getLastDistributionTimestamp(address _token) public view`: Gets the timestamp of the last distribution round for a token.
35. `pause() public onlyOwner whenNotPaused`: Pauses certain contract functions.
36. `unpause() public onlyOwner whenPaused`: Unpauses the contract.
37. `sweepDustTokens(address _token, uint256 _threshold)`: Owner can sweep small amounts of a token below a certain threshold to a designated address (e.g., owner's address or burn address).
38. `emergencyWithdraw(address _token, uint256 _amount)`: Owner can withdraw funds in an emergency. Use with caution. (Needs careful permissioning/multisig in prod).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- QuantumTreasury Smart Contract ---
//
// Outline:
// 1. State Variables: Owner, allowed tokens, beneficiaries, distribution weights, stakes,
//    vesting schedules, lottery state, claimable balances.
// 2. Enums & Structs: Define strategy types, beneficiary info, vesting, lottery state.
// 3. Events: For deposits, withdrawals, beneficiary/stake changes, distributions, claims, lottery.
// 4. Modifiers: onlyOwner, Pausable modifiers.
// 5. Constructor: Initialize owner.
// 6. Receive/Fallback: Handle ETH deposits.
// 7. Admin/Setup: Manage tokens, beneficiaries, weights, vesting, pause, sweep, emergency withdraw.
// 8. Funding: Deposit ERC20 tokens.
// 9. User Interaction: Stake, unstake, claim distributions (vested, fixed, stake, lottery).
// 10. Distribution Logic: Internal helpers for strategies, main trigger function to calculate
//     and update claimable balances based on weights.
// 11. Query Functions: View state, balances, config, claimable amounts.
//
// Function Summary:
// - Admin/Setup: addAllowedToken, removeAllowedToken, addBeneficiary, removeBeneficiary,
//   setBeneficiaryFixedShare, setDistributionWeight, setVestingSchedule, pause, unpause,
//   sweepDustTokens, emergencyWithdraw.
// - Funding: receive (for ETH), depositERC20.
// - User Interaction: stakeForDistribution, unstakeForDistribution, registerForLottery,
//   claimVestedTokens, claimFixedShare, claimStakeShare, claimLotteryWin.
// - Distribution Logic: triggerLotteryDraw, triggerDistributionRound.
// - Query: isAllowedToken, getBeneficiaryInfo, getERC20Balance, getETHBalance,
//   getDistributionWeight, getVestingSchedule, getUserStake, isParticipatingInLottery,
//   getLotteryWinner, getCurrentLotteryRound, getClaimedVestedAmount,
//   getClaimableFixed, getClaimableStakeBased, getClaimableLottery, getLastDistributionTimestamp,
//   isPaused. (Total ~38 publicly accessible functions including views, meeting the >=20 requirement)

contract QuantumTreasury is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    // Allowed tokens for deposit and distribution
    mapping(address => bool) public allowedTokens;

    // Beneficiary Information
    struct BeneficiaryInfo {
        bool isActive;
        uint256 fixedShareBps; // Fixed share in Basis Points (1/10000)
        uint256 vestingScheduleId; // Link to vesting schedule (0 if none)
    }
    mapping(address => BeneficiaryInfo) public beneficiaries;
    address[] public beneficiaryList; // Keep a list for iteration (potentially gas-intensive for large lists)

    // Distribution Strategies
    enum DistributionStrategy { Fixed, StakeBased, Vesting, Lottery }
    mapping(DistributionStrategy => uint256) public distributionWeightsBps; // Weights in Basis Points

    // User Stakes for Stake-Based Distribution (Staking Token => User Address => Amount)
    mapping(address => mapping(address => uint256)) public userStakes;
    // Mapping from Distribution Token to Staking Token (defines which stake influences which distribution)
    mapping(address => address) public distributionTokenStakingToken;

    // Vesting Schedules
    struct VestingSchedule {
        uint256 totalAmount; // Total amount to be vested
        uint64 startTimestamp; // Start time of vesting
        uint64 duration;       // Total duration in seconds
        uint64 cliffDuration;  // Cliff duration in seconds
        uint64 interval;       // Release interval in seconds (0 for linear)
    }
    // mapping from schedule ID to schedule details
    mapping(uint256 => VestingSchedule) public vestingSchedules;
    uint256 private nextVestingScheduleId = 1;

    // Track claimed vested amounts per beneficiary per token
    mapping(address => mapping(address => uint256)) public claimedVestedAmounts;

    // Lottery State
    struct LotteryState {
        uint256 round;
        address winner; // Winner of the *last* round
        uint256 prizeAmount; // Prize amount for the *last* round
        mapping(address => bool) participants; // Participants in the *current* round
        address[] participantAddresses; // List of participants for drawing
        bool roundClosed; // Flag indicating if registration is closed for the current round
    }
    // Mapping from Distribution Token to Lottery State
    mapping(address => LotteryState) public lotteryState;
    uint256 private constant HASH_DIVISOR = 10000; // For simple randomness from block hash

    // Claimable Balances (User Address => Token Address => Amount Claimable)
    mapping(address => mapping(address => uint256)) public claimableBalances;

    // Last distribution timestamp per token
    mapping(address => uint66) public lastDistributionTimestamp; // Using uint66 to potentially save gas if packed

    // --- Events ---

    event TokenAllowed(address indexed token);
    event TokenRemoved(address indexed token);
    event BeneficiaryAdded(address indexed beneficiary, uint256 fixedShareBps);
    event BeneficiaryRemoved(address indexed beneficiary);
    event BeneficiaryFixedShareUpdated(address indexed beneficiary, uint256 oldShareBps, uint256 newShareBps);
    event DistributionWeightUpdated(DistributionStrategy strategy, uint256 weightBps);
    event VestingScheduleSet(address indexed beneficiary, uint256 scheduleId, uint256 amount, uint256 start, uint256 duration, uint256 cliff, uint256 interval);
    event DepositERC20(address indexed depositor, address indexed token, uint256 amount);
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RegisteredForLottery(address indexed user, uint256 round);
    event LotteryDraw(address indexed token, uint256 round, address indexed winner, uint256 prizeAmount);
    event DistributionRoundTriggered(address indexed token, uint256 distributedAmount);
    event Claimed(address indexed user, address indexed token, uint256 amount, string strategy);
    event DustSwept(address indexed token, address indexed recipient, uint256 amount);
    event EmergencyWithdrawal(address indexed token, address indexed recipient, uint256 amount);

    // --- Modifiers ---

    // Inherits onlyOwner from Ownable
    // Inherits whenNotPaused, whenPaused from Pausable

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable() {
        // Default weights (e.g., 25% each) - owner can change later
        distributionWeightsBps[DistributionStrategy.Fixed] = 2500;
        distributionWeightsBps[DistributionStrategy.StakeBased] = 2500;
        distributionWeightsBps[DistributionStrategy.Vesting] = 2500;
        distributionWeightsBps[DistributionStrategy.Lottery] = 2500;

        // Define default staking token mapping (e.g., stake the same token to earn it)
        // This should likely be set per token by the owner
        // For this example, let's assume staking TokenA earns TokenA, etc., unless specified
    }

    // --- Receive/Fallback ---

    receive() external payable whenNotPaused {
        // ETH deposited directly to the contract is now available
        emit DepositERC20(msg.sender, address(0), msg.value); // Use address(0) for ETH
    }

    // --- Admin/Setup Functions ---

    function addAllowedToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address");
        require(!allowedTokens[_token], "Token already allowed");
        allowedTokens[_token] = true;
        // Default: staking the token itself is required to earn stake-based share
        distributionTokenStakingToken[_token] = _token;
        emit TokenAllowed(_token);
    }

    function removeAllowedToken(address _token) external onlyOwner {
        require(_token != address(0), "Zero address");
        require(allowedTokens[_token], "Token not allowed");
        // Note: This doesn't remove existing balances or stakes associated with this token
        // Consider adding migration logic in a real scenario
        delete allowedTokens[_token];
        delete distributionTokenStakingToken[_token];
        emit TokenRemoved(_token);
    }

    function addBeneficiary(address _beneficiary, uint256 _fixedShareBps) external onlyOwner {
        require(_beneficiary != address(0), "Zero address");
        require(!beneficiaries[_beneficiary].isActive, "Beneficiary already exists");
        require(_fixedShareBps <= 10000, "Fixed share exceeds 100%");

        beneficiaries[_beneficiary] = BeneficiaryInfo({
            isActive: true,
            fixedShareBps: _fixedShareBps,
            vestingScheduleId: 0 // No vesting by default
        });
        beneficiaryList.push(_beneficiary);
        emit BeneficiaryAdded(_beneficiary, _fixedShareBps);
    }

    function removeBeneficiary(address _beneficiary) external onlyOwner {
        require(beneficiaries[_beneficiary].isActive, "Beneficiary not active");

        // Mark as inactive instead of deleting state to preserve history (vesting, claims)
        beneficiaries[_beneficiary].isActive = false;

        // Find and remove from beneficiaryList (gas-intensive for large lists)
        for (uint i = 0; i < beneficiaryList.length; i++) {
            if (beneficiaryList[i] == _beneficiary) {
                // Swap with last element and pop
                beneficiaryList[i] = beneficiaryList[beneficiaryList.length - 1];
                beneficiaryList.pop();
                break; // Found and removed
            }
        }
        emit BeneficiaryRemoved(_beneficiary);
    }

    function setBeneficiaryFixedShare(address _beneficiary, uint256 _fixedShareBps) external onlyOwner {
        require(beneficiaries[_beneficiary].isActive, "Beneficiary not active");
        require(_fixedShareBps <= 10000, "Fixed share exceeds 100%");

        uint256 oldShare = beneficiaries[_beneficiary].fixedShareBps;
        beneficiaries[_beneficiary].fixedShareBps = _fixedShareBps;
        emit BeneficiaryFixedShareUpdated(_beneficiary, oldShare, _fixedShareBps);
    }

    function setDistributionWeight(DistributionStrategy _strategy, uint256 _weightBps) external onlyOwner {
        require(_weightBps <= 10000, "Weight exceeds 100%");
        // Add logic to ensure total weight across all strategies is <= 10000 if needed,
        // or just allow individual setting and let `triggerDistributionRound` handle
        // potential cases where total weight is > 10000 (e.g., cap at 100%).
        // Let's enforce <= 10000 sum in a helper/view function, but allow setting individually here.
        distributionWeightsBps[_strategy] = _weightBps;
        emit DistributionWeightUpdated(_strategy, _weightBps);
    }

    // Helper view to check total distribution weight
    function getTotalDistributionWeight() public view returns (uint256) {
        return distributionWeightsBps[DistributionStrategy.Fixed] +
               distributionWeightsBps[DistributionStrategy.StakeBased] +
               distributionWeightsBps[DistributionStrategy.Vesting] +
               distributionWeightsBps[DistributionStrategy.Lottery];
    }

    function setVestingSchedule(address _beneficiary, uint256 _totalAmount, uint64 _start, uint64 _duration, uint64 _cliff, uint64 _interval) external onlyOwner {
        require(beneficiaries[_beneficiary].isActive, "Beneficiary not active");
        // Basic validation for vesting parameters
        require(_duration > 0, "Duration must be > 0");
        require(_cliff <= _duration, "Cliff must be <= duration");
        require(_interval <= _duration || _interval == 0, "Interval must be <= duration or 0");
        if (_interval > 0) require(_duration % _interval == 0, "Duration must be divisible by interval");


        uint256 scheduleId = nextVestingScheduleId++;
        vestingSchedules[scheduleId] = VestingSchedule({
            totalAmount: _totalAmount,
            startTimestamp: _start,
            duration: _duration,
            cliffDuration: _cliff,
            interval: _interval
        });
        beneficiaries[_beneficiary].vestingScheduleId = scheduleId;

        emit VestingScheduleSet(_beneficiary, scheduleId, _totalAmount, _start, _duration, _cliff, _interval);
    }

    function sweepDustTokens(address _token, uint256 _threshold) external onlyOwner whenNotPaused {
        require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");

        uint256 balance;
        if (_token == address(0)) { // ETH
            balance = address(this).balance;
        } else { // ERC20
            balance = IERC20(_token).balanceOf(address(this));
        }

        if (balance > 0 && balance <= _threshold) {
            uint256 amountToSweep = balance;
            if (_token == address(0)) { // ETH
                (bool success, ) = payable(owner()).call{value: amountToSweep}("");
                require(success, "ETH transfer failed");
            } else { // ERC20
                IERC20(_token).safeTransfer(owner(), amountToSweep);
            }
            emit DustSwept(_token, owner(), amountToSweep);
        }
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner whenPaused {
         require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");
         require(_amount > 0, "Amount must be > 0");

         uint256 contractBalance;
         if (_token == address(0)) { // ETH
            contractBalance = address(this).balance;
            require(_amount <= contractBalance, "Insufficient ETH balance");
            (bool success, ) = payable(owner()).call{value: _amount}("");
            require(success, "ETH transfer failed");
         } else { // ERC20
            contractBalance = IERC20(_token).balanceOf(address(this));
            require(_amount <= contractBalance, "Insufficient ERC20 balance");
            IERC20(_token).safeTransfer(owner(), _amount);
         }
         emit EmergencyWithdrawal(_token, owner(), _amount);
    }


    // --- Funding Functions ---

    function depositERC20(address _token, uint256 _amount) external whenNotPaused {
        require(allowedTokens[_token], "Token not allowed");
        require(_amount > 0, "Amount must be > 0");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit DepositERC20(msg.sender, _token, _amount);
    }

    // --- User Interaction Functions ---

    // Defines which token stake counts towards distribution of another token
    function setDistributionStakingToken(address _distributionToken, address _stakingToken) external onlyOwner {
         require(allowedTokens[_distributionToken], "Distribution token not allowed");
         require(allowedTokens[_stakingToken] || _stakingToken == address(0), "Staking token not allowed or ETH");
         distributionTokenStakingToken[_distributionToken] = _stakingToken;
    }

    function stakeForDistribution(address _stakingToken, uint256 _amount) external whenNotPaused {
        require(allowedTokens[_stakingToken] || _stakingToken == address(0), "Staking token not allowed or ETH");
        require(_amount > 0, "Amount must be > 0");

        if (_stakingToken == address(0)) { // ETH Stake
            require(msg.value == _amount, "Msg.value mismatch");
            // ETH is already received by the contract via receive()
            // Just update the stake balance
            userStakes[address(0)][msg.sender] += _amount;
        } else { // ERC20 Stake
            IERC20(_stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
            userStakes[_stakingToken][msg.sender] += _amount;
        }
        emit Staked(msg.sender, _stakingToken, _amount);
    }

     function unstakeForDistribution(address _stakingToken, uint256 _amount) external whenNotPaused {
        require(allowedTokens[_stakingToken] || _stakingToken == address(0), "Staking token not allowed or ETH");
        require(_amount > 0, "Amount must be > 0");
        require(userStakes[_stakingToken][msg.sender] >= _amount, "Insufficient stake");

        userStakes[_stakingToken][msg.sender] -= _amount;

        if (_stakingToken == address(0)) { // ETH Stake
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "ETH unstake failed");
        } else { // ERC20 Stake
            IERC20(_stakingToken).safeTransfer(msg.sender, _amount);
        }
        emit Unstaked(msg.sender, _stakingToken, _amount);
    }

    function registerForLottery(address _token) external whenNotPaused {
        require(allowedTokens[_token], "Token not allowed");
        // Check if the lottery round is open for registration
        require(!lotteryState[_token].roundClosed, "Lottery registration is closed");

        // Ensure user is a beneficiary to participate (optional rule)
        // require(beneficiaries[msg.sender].isActive, "Must be a beneficiary to register");

        if (!lotteryState[_token].participants[msg.sender]) {
             lotteryState[_token].participants[msg.sender] = true;
             lotteryState[_token].participantAddresses.push(msg.sender);
             emit RegisteredForLottery(msg.sender, lotteryState[_token].round);
        }
    }

    function claimVestedTokens(address _token) external whenNotPaused {
        require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");
        require(beneficiaries[msg.sender].isActive, "Not an active beneficiary");

        uint256 scheduleId = beneficiaries[msg.sender].vestingScheduleId;
        require(scheduleId > 0, "No vesting schedule set for beneficiary");

        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        require(schedule.totalAmount > 0, "Vesting schedule is empty");

        uint256 totalClaimable = calculateClaimableVested(msg.sender, _token);
        uint256 alreadyClaimed = claimedVestedAmounts[msg.sender][_token];
        uint256 amountToClaim = totalClaimable - alreadyClaimed;

        if (amountToClaim > 0) {
            // Ensure the contract actually holds enough of this token/ETH
             uint256 contractBalance;
             if (_token == address(0)) { // ETH
                contractBalance = address(this).balance;
             } else { // ERC20
                contractBalance = IERC20(_token).balanceOf(address(this));
             }
             amountToClaim = (amountToClaim > contractBalance) ? contractBalance : amountToClaim;
             require(amountToClaim > 0, "Insufficient contract balance for claim");

            claimedVestedAmounts[msg.sender][_token] += amountToClaim;

            if (_token == address(0)) { // ETH
                (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
                require(success, "ETH claim failed");
            } else { // ERC20
                 IERC20(_token).safeTransfer(msg.sender, amountToClaim);
            }

            emit Claimed(msg.sender, _token, amountToClaim, "Vesting");
        }
    }

    // Claims claimable balance accumulated via triggerDistributionRound
    function claimFixedShare(address _token) external whenNotPaused {
        _claimStrategyShare(msg.sender, _token, DistributionStrategy.Fixed);
    }

    // Claims claimable balance accumulated via triggerDistributionRound
    function claimStakeShare(address _token) external whenNotPaused {
         _claimStrategyShare(msg.sender, _token, DistributionStrategy.StakeBased);
    }

    // Claims claimable balance accumulated via triggerDistributionRound (if won lottery)
    function claimLotteryWin(address _token) external whenNotPaused {
        _claimStrategyShare(msg.sender, _token, DistributionStrategy.Lottery);
    }

    // Internal helper for claiming general claimable balance
    function _claimStrategyShare(address _user, address _token, DistributionStrategy _strategy) internal whenNotPaused {
         require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");
         // Optionally require beneficiary status if claiming fixed/stake shares only for beneficiaries
         // require(beneficiaries[_user].isActive, "Not an active beneficiary");

         uint256 amountToClaim = claimableBalances[_user][_token];
         require(amountToClaim > 0, "No claimable balance");

         // Ensure the contract actually holds enough of this token/ETH
         uint256 contractBalance;
         if (_token == address(0)) { // ETH
            contractBalance = address(this).balance;
         } else { // ERC20
            contractBalance = IERC20(_token).balanceOf(address(this));
         }
         amountToClaim = (amountToClaim > contractBalance) ? contractBalance : amountToClaim;
         require(amountToClaim > 0, "Insufficient contract balance for claim");

         claimableBalances[_user][_token] -= amountToClaim; // Deduct *before* transfer

         if (_token == address(0)) { // ETH
             (bool success, ) = payable(_user).call{value: amountToClaim}("");
             require(success, "ETH claim failed");
         } else { // ERC20
              IERC20(_token).safeTransfer(_user, amountToClaim);
         }

         // Map strategy enum to string for event
         string memory strategyName;
         if (_strategy == DistributionStrategy.Fixed) strategyName = "Fixed";
         else if (_strategy == DistributionStrategy.StakeBased) strategyName = "StakeBased";
         else if (_strategy == DistributionStrategy.Lottery) strategyName = "Lottery";
         else strategyName = "Unknown"; // Should not happen with current strategies

         emit Claimed(_user, _token, amountToClaim, strategyName);
    }


    // --- Distribution Logic ---

    // Simplified Lottery Draw (Uses block hash - NOT suitable for high-value lotteries)
    function triggerLotteryDraw(address _token) external whenNotPaused {
        require(allowedTokens[_token], "Token not allowed");
        require(lotteryState[_token].participantAddresses.length > 0, "No lottery participants");
        require(!lotteryState[_token].roundClosed, "Lottery round already drawn"); // Can only draw once per round

        lotteryState[_token].roundClosed = true; // Close registration for this round

        uint256 numParticipants = lotteryState[_token].participantAddresses.length;

        // Simple, but potentially insecure, randomness from blockhash
        // For production, use Chainlink VRF or similar secure randomness solution
        bytes32 randomHash = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number));
        uint256 winnerIndex = uint256(randomHash) % numParticipants;

        address winnerAddress = lotteryState[_token].participantAddresses[winnerIndex];

        // Store winner and prize for the *last* round
        // The actual prize calculation happens in triggerDistributionRound

        lotteryState[_token].winner = winnerAddress;
        // The prizeAmount field is set in triggerDistributionRound after allocation
        // lotteryState[_token].prizeAmount = ...

        emit LotteryDraw(_token, lotteryState[_token].round, winnerAddress, 0); // Prize amount is 0 here, set later

        // Prepare for the next round: Increment round number, clear participants and winner
        lotteryState[_token].round++;
        delete lotteryState[_token].participants; // Clear mapping
        delete lotteryState[_token].participantAddresses; // Clear list
        lotteryState[_token].winner = address(0); // Reset winner for next round
        lotteryState[_token].prizeAmount = 0;
        lotteryState[_token].roundClosed = false; // Open registration for the new round
    }


    // Main function to trigger a distribution round for a token
    // This function calculates how much to allocate to *each strategy*
    // based on weights from the available contract balance for that token,
    // and updates the `claimableBalances` or beneficiary states accordingly.
    // It does *not* transfer funds directly, users must call claim functions.
    function triggerDistributionRound(address _token) external whenNotPaused {
        require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");
        // Optional: require a minimum time interval between distributions per token
        // require(block.timestamp >= lastDistributionTimestamp[_token] + MIN_DISTRIBUTION_INTERVAL, "Too soon for next distribution");

        uint256 totalContractBalance;
        if (_token == address(0)) { // ETH
            totalContractBalance = address(this).balance;
        } else { // ERC20
            totalContractBalance = IERC20(_token).balanceOf(address(this));
        }

        require(totalContractBalance > 0, "Insufficient contract balance to distribute");

        uint256 totalWeight = getTotalDistributionWeight();
        // Cap total weight at 10000 (100%) if configured higher
        if (totalWeight > 10000) {
            totalWeight = 10000;
        }

        if (totalWeight == 0) {
             emit DistributionRoundTriggered(_token, 0);
             return; // Nothing to distribute if total weight is 0
        }

        // Amount available for THIS distribution round (can be all or a percentage of balance)
        // For simplicity, let's distribute the *entire* current balance based on weights.
        // In a real system, you might want to only distribute a yield or a specific amount.
        uint256 amountToDistribute = totalContractBalance;

        // Calculate amounts per strategy based on weight and total amount
        uint256 fixedAllocation = (amountToDistribute * distributionWeightsBps[DistributionStrategy.Fixed]) / totalWeight;
        uint256 stakeAllocation = (amountToDistribute * distributionWeightsBps[DistributionStrategy.StakeBased]) / totalWeight;
        uint256 vestingAllocation = (amountToDistribute * distributionWeightsBps[DistributionStrategy.Vesting]) / totalWeight;
        uint256 lotteryAllocation = (amountToDistribute * distributionWeightsBps[DistributionStrategy.Lottery]) / totalWeight;

        uint256 totalAllocated = 0; // Track actual allocated sum
        if (fixedAllocation > 0) {
            _distributeFixed(_token, fixedAllocation);
             totalAllocated += fixedAllocation;
        }
        if (stakeAllocation > 0) {
             _distributeStakeBased(_token, stakeAllocation);
             totalAllocated += stakeAllocation;
        }
        // Note: Vesting allocation might be complex - users claim *based on their schedule* from *total* pool.
        // Instead of allocating to specific vesting schedules here, we ensure there's *enough total*
        // funds in the contract and users claim their calculated vested amount from the pool.
        // The vesting weight could influence how much *new* funds are added to the treasury
        // via an external process, or simply reserve a portion notionally.
        // For this example, let's make vesting claims independent of this trigger,
        // assuming vested amounts are simply claimable from the total pool as they unlock.
        // We'll skip _distributeVested here, but keep the weight for potential future use.
        // totalAllocated += vestingAllocation; // Add notionally if needed
        // Or, use vestingAllocation to top up a dedicated vesting sub-pool?

        if (lotteryAllocation > 0) {
             _runLotteryDistribution(_token, lotteryAllocation);
             totalAllocated += lotteryAllocation;
        }

        lastDistributionTimestamp[_token] = uint66(block.timestamp);

        emit DistributionRoundTriggered(_token, totalAllocated);
    }

    // Internal helper for fixed distribution
    function _distributeFixed(address _token, uint256 _amount) internal {
        uint256 totalFixedSharesBps = 0;
        // Calculate total active fixed shares first
        for (uint i = 0; i < beneficiaryList.length; i++) {
            address beneficiaryAddr = beneficiaryList[i];
            if (beneficiaries[beneficiaryAddr].isActive && beneficiaries[beneficiaryAddr].fixedShareBps > 0) {
                totalFixedSharesBps += beneficiaries[beneficiaryAddr].fixedShareBps;
            }
        }

        if (totalFixedSharesBps == 0) return; // No one to distribute to

        // Distribute to each active beneficiary based on their fixed share
        for (uint i = 0; i < beneficiaryList.length; i++) {
            address beneficiaryAddr = beneficiaryList[i];
            if (beneficiaries[beneficiaryAddr].isActive && beneficiaries[beneficiaryAddr].fixedShareBps > 0) {
                 uint256 shareAmount = (_amount * beneficiaries[beneficiaryAddr].fixedShareBps) / totalFixedSharesBps;
                 if (shareAmount > 0) {
                    claimableBalances[beneficiaryAddr][_token] += shareAmount;
                 }
            }
        }
    }

    // Internal helper for stake-based distribution
    function _distributeStakeBased(address _token, uint256 _amount) internal {
        address stakingToken = distributionTokenStakingToken[_token];
        if (stakingToken == address(0) || !allowedTokens[stakingToken]) {
             // Cannot perform stake-based distribution if staking token is not set/allowed
             // Consider logging or handling this error
             return;
        }

        uint256 totalStake = 0;
        // Calculating total stake requires iterating over all potential stakers
        // This can be gas-intensive. A more scalable approach would be to track total stake.
        // For this example, let's assume we can iterate beneficiaries or have a separate list of stakers.
        // Let's iterate beneficiaries for simplicity, assuming only they can stake for distributions.
        // In a real dapp, you'd iterate users who have a non-zero stake balance.
        // Need a list of addresses who have staked for this stakingToken.
        // Let's add a simple map to track addresses who have staked at least once.
        // mapping(address => mapping(address => bool)) private hasStaked; // stakingToken => user => bool
        // address[] private stakingUsersList; // list of *all* users who have staked any token (very rough)

        // A better way: require users to register their stake interest or pre-calculate total stake off-chain.
        // For this example, we'll skip actual stake iteration and assume totalStake is magically available.
        // !!! IMPORTANT: The iteration below is a PLACEHOLDER and WILL NOT WORK correctly or efficiently
        // without tracking stakers and their total stake properly.
        // To make it work simply for this example: let's just use the *total supply* of the staking token as total stake base
        // This is NOT how stake-based distribution usually works but demonstrates the concept of proportioning.
        // A real implementation needs a list of stakers and sum their actual stakes.

        // Placeholder Logic (replace with proper stake tracking and summing):
        // We need the total amount staked *in this contract* for the specific staking token.
        // Tracking this requires updating a totalStake variable in stake/unstake functions.
        // Let's add a mapping: mapping(address => uint256) public totalStakedAmount; // stakingToken => total

        uint256 totalStaked = 0;
         if (stakingToken == address(0)) { // ETH stake total
             // Requires tracking total ETH staked - add totalStakedAmount[address(0)] += amount logic to stake/unstake
             // For this example, let's just get the contract's ETH balance as a proxy total stake (simplified & not accurate)
             // totalStaked = address(this).balance; // Not correct - this is total ETH, not total STAKED ETH
             // Correct way: need totalStakedAmount mapping
             // Let's assume totalStakedAmount[_stakingToken] is correctly updated elsewhere.
             // Add: totalStakedAmount[_stakingToken] += _amount in stakeForDistribution
             // Add: totalStakedAmount[_stakingToken] -= _amount in unstakeForDistribution
         } else { // ERC20 stake total
              // totalStaked = IERC20(stakingToken).balanceOf(address(this)); // Not correct - this is total token, not total STAKED
              // Correct way: need totalStakedAmount mapping
         }

        // Reverting to the simple (but inefficient for many users) method for demonstration: iterate beneficiaries.
        // Assume ONLY beneficiaries can stake for distribution shares.
        uint256 totalBeneficiaryStake = 0;
         for (uint i = 0; i < beneficiaryList.length; i++) {
             address beneficiaryAddr = beneficiaryList[i];
             if (beneficiaries[beneficiaryAddr].isActive) {
                  totalBeneficiaryStake += userStakes[stakingToken][beneficiaryAddr];
             }
         }

        if (totalBeneficiaryStake == 0) return; // No stake, no distribution

        // Distribute to each active beneficiary based on their stake
         for (uint i = 0; i < beneficiaryList.length; i++) {
             address beneficiaryAddr = beneficiaryList[i];
             if (beneficiaries[beneficiaryAddr].isActive) {
                  uint256 beneficiaryStake = userStakes[stakingToken][beneficiaryAddr];
                  if (beneficiaryStake > 0) {
                       uint256 shareAmount = (_amount * beneficiaryStake) / totalBeneficiaryStake;
                       if (shareAmount > 0) {
                            claimableBalances[beneficiaryAddr][_token] += shareAmount;
                       }
                  }
             }
         }
    }

    // Internal helper for lottery distribution
    function _runLotteryDistribution(address _token, uint256 _amount) internal {
        // Check if a winner has been drawn for the *last* round and the prize hasn't been allocated yet
        // The lotteryState holds the winner of the *previous* round after triggerLotteryDraw is called.
        // If lotteryState[_token].winner is address(0), it means no draw happened or prize was allocated.
        // The prizeAmount field can track if the prize for the LAST round was allocated.
        // Let's use a simple boolean flag: lotteryState[_token].prizeAllocatedForRound

        // This function is called by triggerDistributionRound *after* a lottery draw might have happened.
        // It allocates the prize amount determined by the lottery weight to the winner of the *most recently completed* lottery round.
        address lastWinner = lotteryState[_token].winner; // Winner of the round *before* the current one
        uint256 lastPrizeAmount = lotteryState[_token].prizeAmount; // Prize for the round *before* the current one

        // Only allocate if there was a winner AND the prize amount wasn't set yet for that round
        // Need a way to track if the prize for a specific round has been allocated.
        // Let's add a mapping: mapping(address => mapping(uint256 => bool)) public lotteryPrizeAllocated; // token => round => allocated?

        // Re-thinking the lottery state: winner and prize should be tied to a *specific* round.
        // Let's modify the LotteryState struct:
        // struct LotteryState {
        //     uint256 currentRound;
        //     mapping(address => bool) participants; // Participants in currentRound
        //     address[] participantAddresses; // Participants list for currentRound draw
        //     bool registrationClosed; // for currentRound
        //     uint256 lastDrawnRound; // The round number that was last drawn
        //     address lastWinner;      // Winner of lastDrawnRound
        //     uint256 lastPrizeAmount; // Prize amount calculated for lastDrawnRound
        //     bool lastPrizeClaimed;   // Flag if the prize for lastDrawnRound has been claimed
        // }

        // Let's simplify the lottery logic in _runLotteryDistribution for this example:
        // If the lottery has been drawn for _token (winner != address(0)) and the prize hasn't been allocated (prizeAmount is 0),
        // allocate the _amount to the winner's claimable balance and set the prizeAmount.
        // This assumes triggerDistributionRound is called *after* triggerLotteryDraw for that token.

        if (lotteryState[_token].winner != address(0) && lotteryState[_token].prizeAmount == 0) {
            address winnerAddr = lotteryState[_token].winner;
            claimableBalances[winnerAddr][_token] += _amount; // Allocate the weighted amount to the winner
            lotteryState[_token].prizeAmount = _amount; // Record the allocated prize amount for this winner/round

             // Add to beneficiary list if winner is not already one (optional based on rules)
             // For simplicity, assume lottery winners are automatically eligible to claim.

             emit Claimed(winnerAddr, _token, _amount, "LotteryAllocation"); // Emit allocation event
        }
        // If winner == address(0), no lottery draw happened yet for this token/round.
        // If prizeAmount > 0, the prize for this winner/round has already been allocated.
    }

    // Internal helper (or skipped) for vesting distribution - handled by claimVestedTokens


    // --- Query Functions ---

    function isAllowedToken(address _token) public view returns (bool) {
        return allowedTokens[_token];
    }

    function getBeneficiaryInfo(address _beneficiary) public view returns (BeneficiaryInfo memory) {
        return beneficiaries[_beneficiary];
    }

    function getERC20Balance(address _token) public view returns (uint256) {
        require(_token != address(0), "Use getETHBalance for ETH");
        return IERC20(_token).balanceOf(address(this));
    }

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDistributionWeight(DistributionStrategy _strategy) public view returns (uint256) {
        return distributionWeightsBps[_strategy];
    }

    function getVestingSchedule(address _beneficiary) public view returns (VestingSchedule memory) {
        uint256 scheduleId = beneficiaries[_beneficiary].vestingScheduleId;
        require(scheduleId > 0, "No vesting schedule set for beneficiary");
        return vestingSchedules[scheduleId];
    }

    function getUserStake(address _user, address _token) public view returns (uint256) {
        require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");
        return userStakes[_token][_user];
    }

    function isParticipatingInLottery(address _user, address _token) public view returns (bool) {
        require(allowedTokens[_token], "Token not allowed");
        return lotteryState[_token].participants[_user];
    }

    function getLotteryWinner(address _token) public view returns (address) {
         require(allowedTokens[_token], "Token not allowed");
         return lotteryState[_token].winner; // Winner of the *last* round
    }

    function getCurrentLotteryRound(address _token) public view returns (uint256) {
        require(allowedTokens[_token], "Token not allowed");
        return lotteryState[_token].round;
    }

    function getClaimedVestedAmount(address _beneficiary, address _token) public view returns (uint256) {
        require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");
        return claimedVestedAmounts[_beneficiary][_token];
    }

    // Calculate claimable vested amount based on schedule and time
    function calculateClaimableVested(address _beneficiary, address _token) public view returns (uint256) {
        uint256 scheduleId = beneficiaries[_beneficiary].vestingScheduleId;
        if (scheduleId == 0) return 0;

        VestingSchedule storage schedule = vestingSchedules[scheduleId];
        if (schedule.totalAmount == 0 || schedule.duration == 0) return 0;

        uint64 currentTime = uint64(block.timestamp);

        // Before vesting start or during cliff
        if (currentTime < schedule.startTimestamp + schedule.cliffDuration) {
            return 0;
        }

        uint256 timeSinceStart = currentTime - schedule.startTimestamp;

        // After full duration
        if (timeSinceStart >= schedule.duration) {
            return schedule.totalAmount;
        }

        // Linear vesting if interval is 0 or equals duration
        if (schedule.interval == 0 || schedule.interval == schedule.duration) {
             // Proportionate release after cliff
             uint256 vestedAmount = (schedule.totalAmount * (timeSinceStart - schedule.cliffDuration)) / (schedule.duration - schedule.cliffDuration);
             return vestedAmount;
        } else { // Interval vesting
            uint256 intervalsPassed = (currentTime - schedule.startTimestamp) / schedule.interval;
            uint256 totalIntervals = schedule.duration / schedule.interval;
            require(totalIntervals > 0, "Invalid vesting intervals"); // Should be caught in setVestingSchedule

            uint256 vestedAmount = (schedule.totalAmount * intervalsPassed) / totalIntervals;
            return vestedAmount;
        }
    }

    // Get the currently claimable balance from the main `claimableBalances` map (accumulated by triggerDistributionRound)
    function getClaimableFixed(address _beneficiary, address _token) public view returns (uint256) {
         // Fixed shares are simply added to claimableBalances
         return claimableBalances[_beneficiary][_token];
    }

    // Get the currently claimable balance from the main `claimableBalances` map (accumulated by triggerDistributionRound)
     function getClaimableStakeBased(address _beneficiary, address _token) public view returns (uint256) {
        // Stake-based shares are simply added to claimableBalances
        return claimableBalances[_beneficiary][_token];
     }

    // Get the currently claimable balance from the main `claimableBalances` map (accumulated by triggerDistributionRound)
    function getClaimableLottery(address _beneficiary, address _token) public view returns (uint256) {
        // Lottery prize is added to claimableBalances
        return claimableBalances[_beneficiary][_token];
    }


    function getLastDistributionTimestamp(address _token) public view returns (uint66) {
        require(allowedTokens[_token] || _token == address(0), "Token not allowed or ETH");
        return lastDistributionTimestamp[_token];
    }

    function isPaused() public view returns (bool) {
        return paused();
    }
}
```