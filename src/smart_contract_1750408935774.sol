Okay, let's create a smart contract with an interesting concept: a token that goes through different "phases" or "states," where its behavior (like transfer fees, staking eligibility, or access to features) changes based on its current state and potentially the state of the user holding it.

We'll call it `MetaMorphToken`. The core idea is a lifecycle: tokens start in one phase (e.g., "Hatchling"), can potentially be staked to move towards a transitional phase ("Chrysalis"), and then potentially evolve into a final phase ("Butterfly") once global conditions are met and user conditions (like stake duration) are fulfilled.

The functions will cover standard token operations, phase management, staking mechanics, dynamic fees, access control based on phase, and administrative controls.

Here is the contract outline, function summary, and the Solidity code.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Although we implement ERC20, importing can be useful for interface checks
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol"; // For name/symbol/decimals

// --- Contract Outline ---
// 1. State Variables & Mappings: Core token data, phase info, staking data, fees, control settings.
// 2. Enums & Structs: Define phases and user staking details.
// 3. Events: Log significant actions (transfers, phase changes, staking, etc.).
// 4. Errors: Custom errors for clearer failures.
// 5. Modifiers: Restrict access based on owner, pause status, or phase.
// 6. Constructor: Initialize token properties and initial state.
// 7. ERC20 Basic Functions: Implement standard ERC20 interface (balanceOf, transfer, approve, transferFrom, totalSupply). Modified for phase/fee logic.
// 8. Internal Helper Functions: Core logic like _transfer, fee calculation/distribution, user phase updates, reward calculation.
// 9. Phase Management: Functions to check and potentially trigger global phase changes.
// 10. Staking Mechanics: Functions for staking, withdrawing, claiming rewards.
// 11. Dynamic Properties: Get/Set transfer fee rates, reward rates, phase thresholds/durations.
// 12. Access Control / Admin: Owner functions for critical settings, treasury withdrawal, pausing.
// 13. Query Functions: Get state information (phases, staking details, fees, thresholds).
// 14. Utility Functions: Batch transfer, burn.
// 15. Phase-Specific Features: Example function checking if an address is in a specific phase for external use.

// --- Function Summary ---
// ERC20 & Core
// 1. totalSupply() - Returns total token supply.
// 2. balanceOf(address account) - Returns the balance of an account.
// 3. transfer(address to, uint256 amount) - Transfers tokens, applying fees and phase rules.
// 4. approve(address spender, uint256 amount) - Sets approval for a spender.
// 5. allowance(address owner, address spender) - Returns allowance amount.
// 6. transferFrom(address from, address to, uint256 amount) - Transfers tokens via allowance, applying fees and phase rules.
// 7. name() - Returns token name. (IERC20Metadata)
// 8. symbol() - Returns token symbol. (IERC20Metadata)
// 9. decimals() - Returns token decimals. (IERC20Metadata)
// 10. burn(uint256 amount) - Allows msg.sender to burn their own tokens.

// Phase Management
// 11. getGlobalPhase() - Returns the current global phase of the token.
// 12. getUserPhase(address account) - Returns the determined phase of a specific user's tokens.
// 13. initiateGlobalMetamorphosis() - Allows owner (or authorized) to trigger the global phase change process if conditions are met.
// 14. setPhaseThresholds(...) - Owner sets requirements (e.g., total staked) for phase changes.
// 15. getPhaseThresholds() - Gets current phase thresholds.
// 16. setPhaseDurations(...) - Owner sets duration requirements for user transformation within a phase.
// 17. getPhaseDurations() - Gets current phase durations.
// 18. setAllowedPhaseTransfer(Phase fromPhase, Phase toPhase, bool allowed) - Owner controls which phase transfers are permitted directly.
// 19. getAllowedPhaseTransfer(Phase fromPhase, Phase toPhase) - Gets allowed transfer status between phases.

// Staking Mechanics
// 20. stake(uint256 amount) - Stakes tokens, moving user towards/into CHRYSALIS phase.
// 21. withdrawStake() - Withdraws staked tokens and claims rewards, potentially moving user to BUTTERFLY phase.
// 22. claimStakingRewards() - Claims accrued staking rewards without unstaking.
// 23. getUserStakeInfo(address account) - Gets detailed info about a user's stake.
// 24. getUserStakeRewards(address account) - Calculates pending staking rewards for a user.
// 25. getTotalStakedSupply() - Returns total tokens currently staked in the contract.
// 26. setStakingRewardRate(uint256 rate) - Owner sets the annual staking reward rate (in tokens per staked token).
// 27. getStakingRewardRate() - Gets the current staking reward rate.

// Dynamic Properties & Fees
// 28. getTransferFeeRate() - Returns the current transfer fee rate (basis points).
// 29. setTransferFeeRate(uint256 rate) - Owner sets the transfer fee rate (basis points).
// 30. setFeeTreasury(address treasuryAddress) - Owner sets the address receiving a portion of fees.
// 31. getFeeTreasury() - Gets the current fee treasury address.
// 32. withdrawTreasury(uint256 amount) - Owner withdraws ETH from the treasury balance held in the contract.
// 33. setFeeBurnRatio(uint256 ratio) - Owner sets the ratio of fees to be burned (basis points).
// 34. getFeeBurnRatio() - Gets the current fee burn ratio.

// Admin & Utility
// 35. pause() - Owner pauses token transfers and staking.
// 36. unpause() - Owner unpauses token transfers and staking.
// 37. batchTransfer(address[] recipients, uint256[] amounts) - Transfers to multiple recipients efficiently.
// 38. transferOwnership(address newOwner) - Transfers contract ownership. (Ownable)

// Phase-Specific Feature Check (Example)
// 39. canAccessPhase3Feature(address account) - Checks if a user is in the BUTTERFLY phase, potentially granting access to external features.

contract MetaMorphToken is Context, Ownable, Pausable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    // --- Phase Management ---
    enum Phase {
        HATCHLING,  // Initial phase: basic ERC20, users can stake
        CHRYSALIS,  // Transitional phase: staking locked, rewards accrue, global transition triggered
        BUTTERFLY   // Final phase: advanced features unlocked, potentially different fees, unstaking allowed
    }

    Phase private _currentGlobalPhase;
    uint256 private _globalPhaseChangeTime; // Timestamp when the global phase last changed

    // User-specific phase, determined by global phase AND user actions (like staking)
    mapping(address => Phase) private _userPhase;

    // Conditions required to trigger global phase changes (e.g., total tokens staked)
    struct PhaseThresholds {
        uint256 toChrysalisStaked; // Min total staked to initiate CHRYSALIS transition
        // Add thresholds for future phases if needed
    }
    PhaseThresholds private _phaseThresholds;

    // Duration requirements for user transformation (e.g., stake duration)
    struct PhaseDurations {
        uint64 chrysalisStakeDuration; // Min seconds staked in CHRYSALIS phase for user to become BUTTERFLY
        // Add durations for future phases if needed
    }
    PhaseDurations private _phaseDurations;

    // Control allowed transfers between phases (e.g., maybe HATCHLING cannot transfer to CHRYSALIS address directly)
    mapping(uint8 => mapping(uint8 => bool)) private _allowedPhaseTransfer; // mapping(fromPhase => mapping(toPhase => allowed))

    // --- Staking Mechanics ---
    struct StakeInfo {
        uint256 amount;
        uint64 startTime; // Timestamp when staking started or last claimed/compounded
        uint256 rewardsClaimed; // Total rewards claimed
    }
    mapping(address => StakeInfo) private _stakes;
    uint256 private _totalStakedSupply;
    uint256 private _stakingRewardRate; // Annual reward rate in basis points (e.g., 500 for 5%)

    // --- Dynamic Properties & Fees ---
    uint256 private _transferFeeRate; // Transfer fee in basis points (100 = 1%)
    address private _feeTreasury;
    uint256 private _feeBurnRatio; // Ratio of fee to burn (basis points)

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event GlobalPhaseChanged(Phase indexed oldPhase, Phase indexed newPhase, uint256 timestamp);
    event UserPhaseChanged(address indexed account, Phase indexed oldPhase, Phase indexed newPhase);
    event Staked(address indexed account, uint256 amount, uint256 totalStaked);
    event WithdrawStake(address indexed account, uint256 amount, uint256 rewardsClaimed, uint256 totalStaked);
    event ClaimRewards(address indexed account, uint256 amount, uint256 totalClaimed);
    event FeeTaken(address indexed from, uint256 feeAmount, uint256 burnedAmount, uint256 treasuryAmount);
    event TransferFeeRateUpdated(uint256 oldRate, uint256 newRate);
    event StakingRewardRateUpdated(uint256 oldRate, uint256 newRate);
    event FeeTreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeBurnRatioUpdated(uint256 oldRatio, uint256 newRatio);
    event PhaseThresholdsUpdated(PhaseThresholds newThresholds);
    event PhaseDurationsUpdated(PhaseDurations newDurations);
    event AllowedPhaseTransferUpdated(Phase indexed fromPhase, Phase indexed toPhase, bool allowed);

    // --- Errors ---
    error InvalidAmount();
    error InsufficientBalance();
    error InsufficientAllowance();
    error TransfersPaused();
    error StakingPaused();
    error WithdrawPaused(); // Can separate pause states if needed
    error AlreadyStaked();
    error NoActiveStake();
    error StakeDurationNotMet();
    error NotEnoughStakedGlobally();
    error AlreadyInPhase(Phase currentPhase);
    error NotInExpectedPhase(Phase requiredPhase, Phase currentPhase);
    error TransferNotAllowedBetweenPhases(Phase fromPhase, Phase toPhase);
    error InvalidRecipient(); // e.g., cannot transfer to zero address, maybe contract address?
    error InvalidFeeRate();
    error InvalidBurnRatio();
    error TreasuryWithdrawFailed();
    error BatchTransferMismatch();
    error CannotStakeZero();
    error CannotWithdrawZero();
    error CannotClaimZero();

    // --- Modifiers ---
    modifier whenStakingNotPaused() {
        if (paused()) revert StakingPaused();
        _;
    }

    modifier whenWithdrawNotPaused() {
        if (paused()) revert WithdrawPaused(); // Using general pause, but could be separate
        _;
        if (paused()) revert StakingPaused(); // Ensure general pause allows withdraw
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, uint256 initialSupply, address initialTreasury) Ownable(_msgSender()) {
        _name = name_;
        _symbol = symbol_;
        _currentGlobalPhase = Phase.HATCHLING;
        _globalPhaseChangeTime = block.timestamp; // Initialize global phase start time

        // Set initial balances and total supply
        _mint(_msgSender(), initialSupply);

        // Set initial fees and treasury (can be updated by owner)
        _transferFeeRate = 100; // 1% default fee
        _feeBurnRatio = 5000; // 50% of fee is burned
        _feeTreasury = initialTreasury;

        // Set initial phase thresholds (can be updated by owner)
        _phaseThresholds.toChrysalisStaked = initialSupply / 10; // Example: 10% of initial supply must be staked

        // Set initial phase durations (can be updated by owner)
        _phaseDurations.chrysalisStakeDuration = 30 days; // Example: 30 days minimum stake in Chrysalis for user transformation

        // Set initial staking reward rate (can be updated by owner)
        _stakingRewardRate = 500; // 5% annual rate

        // Default allowed phase transfers: Allow transfers within the same phase.
        // Owner can configure more complex rules later.
        _allowedPhaseTransfer[uint8(Phase.HATCHLING)][uint8(Phase.HATCHLING)] = true;
        _allowedPhaseTransfer[uint8(Phase.CHRYSALIS)][uint8(Phase.CHRYSALIS)] = true; // Staked tokens cannot transfer, but allowance/balance checks might happen
        _allowedPhaseTransfer[uint8(Phase.BUTTERFLY)][uint8(Phase.BUTTERFLY)] = true;
    }

    // --- ERC20 & Core ---

    /// @inheritdoc IERC20
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view override returns (uint256) {
        // Note: This balance includes staked tokens. Staked tokens cannot be transferred directly.
        // Use getUserStakeInfo to see the breakdown.
        return _balances[account];
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[from][_msgSender()];
        if (currentAllowance < amount) revert InsufficientAllowance();
        _transfer(from, to, amount);
        _approve(from, _msgSender(), currentAllowance - amount);
        return true;
    }

    /// @inheritdoc IERC20Metadata
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public view override returns (uint8) {
        return 18; // Standard for most tokens
    }

    /// @dev Burns tokens from the caller's balance.
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) public whenNotPaused {
        _burn(_msgSender(), amount);
    }

    // --- Internal Helper Functions ---

    /// @dev Internal transfer, handles fees and phase checks.
    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert InvalidAmount(); // Cannot transfer from zero address
        if (to == address(0)) revert InvalidRecipient(); // Cannot transfer to zero address

        // Basic balance check (stake included in balance, so this passes even if staked)
        if (_balances[from] < amount) revert InsufficientBalance();

        // Cannot transfer staked tokens
        if (_stakes[from].amount > 0) {
            if (amount > _balances[from] - _stakes[from].amount) {
                 // User is trying to transfer more than their unstaked balance
                 // Or sender is in a phase that disallows transfers completely (like CHRYSALIS might be configured)
                 Phase fromPhase = _getUserPhase(from);
                 Phase toPhase = _getUserPhase(to); // Use recipient's phase for 'to' check
                 if (fromPhase == Phase.CHRYSALIS || !_allowedPhaseTransfer[uint8(fromPhase)][uint8(toPhase)]) {
                     revert TransferNotAllowedBetweenPhases(fromPhase, toPhase);
                 }
                 // If transfer IS allowed from this phase, but they are staked, check unstaked balance specifically
                 if (amount > _balances[from] - _stakes[from].amount) revert InsufficientBalance(); // trying to transfer staked tokens
            }
        } else {
             // Sender is not staked, just check phase compatibility
             Phase fromPhase = _getUserPhase(from);
             Phase toPhase = _getUserPhase(to); // Use recipient's phase for 'to' check
             if (!_allowedPhaseTransfer[uint8(fromPhase)][uint8(toPhase)]) {
                 revert TransferNotAllowedBetweenPhases(fromPhase, toPhase);
             }
        }


        uint256 feeAmount = 0;
        if (_transferFeeRate > 0) {
            feeAmount = (amount * _transferFeeRate) / 10000; // Basis points: /10000
        }

        uint256 amountAfterFee = amount - feeAmount;

        unchecked {
            _balances[from] -= amount;
        }
        _balances[to] += amountAfterFee;

        if (feeAmount > 0) {
            uint256 burnedAmount = (feeAmount * _feeBurnRatio) / 10000; // Basis points
            uint256 treasuryAmount = feeAmount - burnedAmount;

            if (burnedAmount > 0) {
                 _totalSupply -= burnedAmount; // Reduce total supply for burned tokens
            }
             if (treasuryAmount > 0) {
                 // Tokens sent to the treasury address directly, they become part of its balance.
                 // They are NOT removed from _totalSupply unless the treasury address burns them later.
                 // Alternatively, could send ETH to a contract balance if fees were in ETH.
                 // Here, fees are in the token itself. Treasury address just receives tokens.
                _balances[_feeTreasury] += treasuryAmount;
            }

            emit FeeTaken(from, feeAmount, burnedAmount, treasuryAmount);
        }

        emit Transfer(from, to, amountAfterFee); // Emit transfer of net amount
        if (feeAmount > 0) {
             // Can also emit a separate event for the fee transfer if desired
             emit Transfer(from, address(0), burnedAmount); // Transfer event for burn
             emit Transfer(from, _feeTreasury, treasuryAmount); // Transfer event for treasury
        }

        // Update phases if necessary after transfer (less likely for transfers, mainly for stake/unstake)
        // _updateUserPhase(from); // Might be gas-intensive to do on every transfer
        // _updateUserPhase(to);   // User phases primarily update on stake/unstake or global phase change
    }

    /// @dev Internal mint function.
    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidRecipient();
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /// @dev Internal burn function.
    function _burn(address account, uint256 amount) internal {
        if (account == address(0)) revert InvalidAmount();
        if (_balances[account] < amount) revert InsufficientBalance();

        // Cannot burn staked tokens directly via burn function
        if (_stakes[account].amount > 0) {
             if (amount > _balances[account] - _stakes[account].amount) revert InsufficientBalance(); // trying to burn staked tokens
        }

        unchecked {
            _balances[account] -= amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }


    /// @dev Internal approve function.
    function _approve(address owner, address spender, uint256 amount) internal {
        if (spender == address(0)) revert InvalidRecipient(); // Cannot approve zero address
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @dev Calculates pending staking rewards for a user.
    function _calculateStakingRewards(address account) internal view returns (uint256) {
        StakeInfo storage stake = _stakes[account];
        if (stake.amount == 0 || _stakingRewardRate == 0) {
            return 0;
        }

        uint256 duration = block.timestamp - stake.startTime;
        // Annual rate is in basis points. Calculate daily rate: rate / 365
        // Then multiply by duration in seconds: (daily rate / seconds_in_day) * duration
        // Or annual rate / seconds_in_year * duration
        // (stake.amount * rate / 10000) * duration / seconds_in_year
        // Using 365 days * 24 hours * 60 minutes * 60 seconds = 31,536,000
        uint256 secondsInYear = 31536000; // Approximate seconds in a year

        // Prevent division by zero if rate or secondsInYear is somehow zero (shouldn't happen)
        if (_stakingRewardRate == 0 || secondsInYear == 0) return 0;

        // Calculate based on stake amount and duration
        // Result = (stake.amount * _stakingRewardRate / 10000) * duration / secondsInYear
        // Rearranging to minimize division loss: (stake.amount * _stakingRewardRate * duration) / (10000 * secondsInYear)
        uint256 pendingRewards = (stake.amount * _stakingRewardRate * duration) / (10000 * secondsInYear);

        return pendingRewards;
    }

    /// @dev Internal function to update a user's phase based on global phase and their stake/duration.
    /// @param account The address of the user.
    function _updateUserPhase(address account) internal {
        Phase oldPhase = _userPhase[account];
        Phase newPhase = oldPhase;

        if (_currentGlobalPhase == Phase.HATCHLING) {
            // User is Hatchling unless they are staked
            if (_stakes[account].amount > 0) {
                newPhase = Phase.CHRYSALIS;
            } else {
                newPhase = Phase.HATCHLING;
            }
        } else if (_currentGlobalPhase == Phase.CHRYSALIS) {
            // User is Chrysalis if they are staked and global phase is Chrysalis
            // User becomes Butterfly if global phase is Chrysalis AND their stake duration is met
            if (_stakes[account].amount > 0) {
                if (block.timestamp >= _stakes[account].startTime + _phaseDurations.chrysalisStakeDuration) {
                    newPhase = Phase.BUTTERFLY;
                } else {
                    newPhase = Phase.CHRYSALIS; // Still in Chrysalis, duration not met
                }
            } else {
                 // Global phase is Chrysalis, but user is NOT staked.
                 // Should they remain Hatchling? Or cannot transition?
                 // Let's assume if not staked, they cannot advance past Hatchling, regardless of global phase.
                 // Or maybe they are stuck in Hatchling until global phase hits BUTTERFLY and they meet other criteria?
                 // Let's rule: Not staked means remain HATCHLING until global is BUTTERFLY, then they become BUTTERFLY?
                 // Alternative rule: If global is CHRYSALIS but user isn't staked, they are stuck in HATCHLING.
                 // Let's go with the latter: Staking is required for user to enter CHRYSALIS state and potentially BUTTERFLY.
                newPhase = Phase.HATCHLING; // Staking required to enter CHRYSALIS state
            }

        } else if (_currentGlobalPhase == Phase.BUTTERFLY) {
            // Global phase is Butterfly. All users are BUTTERFLY regardless of stake?
            // Or do they need to have completed the CHRYSALIS duration at some point?
            // Let's say if global is BUTTERFLY, users who were staked AND met duration become BUTTERFLY.
            // Users who were not staked, or didn't meet duration, or unstaked too early,
            // can they still become BUTTERFLY just because global is BUTTERFLY?
            // Let's say if global is BUTTERFLY, any user who *ever* met the stake duration becomes BUTTERFLY.
            // If they never staked or didn't meet duration, they remain HATCHLING?
            // Let's simplify: If global is BUTTERFLY, all users who *were* or *are* staked and met the duration are BUTTERFLY.
            // If global is BUTTERFLY and a user is *not* staked but *did* meet duration requirements before, they become BUTTERFLY.
            // If global is BUTTERFLY and a user *never* staked or met duration, they remain HATCHLING.

            // This logic is getting complex. Let's simplify:
            // Global: HATCHLING -> CHRYSALIS (via total stake + trigger) -> BUTTERFLY (via owner trigger after time/conditions)
            // User: HATCHLING -> CHRYSALIS (by staking in HATCHLING global) -> BUTTERFLY (by unstaking/claiming rewards after meeting stake duration while global is >= CHRYSALIS)

            // Revised User Logic:
            if (_currentGlobalPhase == Phase.BUTTERFLY) {
                 // If global is BUTTERFLY, user becomes BUTTERFLY
                 newPhase = Phase.BUTTERFLY;
            } else if (_stakes[account].amount > 0) {
                // Global is HATCHLING or CHRYSALIS, user is staked
                newPhase = Phase.CHRYSALIS;
            } else {
                // Global is HATCHLING or CHRYSALIS, user is not staked
                newPhase = Phase.HATCHLING;
            }
        }


        if (newPhase != oldPhase) {
            _userPhase[account] = newPhase;
            emit UserPhaseChanged(account, oldPhase, newPhase);
        }
    }

    /// @dev Gets the determined phase for a specific user account.
    /// @param account The address of the user.
    /// @return The current phase of the user's tokens.
    function _getUserPhase(address account) internal returns (Phase) {
        // Re-calculate user phase based on current global phase and their state
        _updateUserPhase(account);
        return _userPhase[account];
    }


    // --- Phase Management ---

    /// @notice Returns the current global phase of the token.
    function getGlobalPhase() public view returns (Phase) {
        return _currentGlobalPhase;
    }

    /// @notice Returns the determined phase of a specific user's tokens.
    /// @param account The address of the account to check.
    /// @return The current phase of the user's tokens.
    function getUserPhase(address account) public returns (Phase) {
         // Call internal function to ensure phase is potentially updated
        return _getUserPhase(account);
    }

    /// @notice Allows owner to trigger the global phase change process if conditions are met.
    /// Can transition from HATCHLING to CHRYSALIS if enough tokens are staked.
    /// Can transition from CHRYSALIS to BUTTERFLY (e.g., owner decides based on time/external factors).
    function initiateGlobalMetamorphosis() public onlyOwner {
        if (_currentGlobalPhase == Phase.HATCHLING) {
            if (_totalStakedSupply < _phaseThresholds.toChrysalisStaked) {
                revert NotEnoughStakedGlobally();
            }
            Phase oldPhase = _currentGlobalPhase;
            _currentGlobalPhase = Phase.CHRYSALIS;
            _globalPhaseChangeTime = block.timestamp;
            emit GlobalPhaseChanged(oldPhase, _currentGlobalPhase, block.timestamp);
             // Note: User phases will update on their next interaction (stake/unstake/claim)
             // or when getUserPhase is called explicitly.
        } else if (_currentGlobalPhase == Phase.CHRYSALIS) {
             // Example: Owner can trigger the final phase manually after CHRYSALIS has been active for some time
             // Or add another threshold requirement here if needed
            Phase oldPhase = _currentGlobalPhase;
            _currentGlobalPhase = Phase.BUTTERFLY;
            _globalPhaseChangeTime = block.timestamp;
            emit GlobalPhaseChanged(oldPhase, _currentGlobalPhase, block.timestamp);
             // User phases will update on interaction/query
        } else {
             revert AlreadyInPhase(_currentGlobalPhase);
        }
    }

    /// @notice Owner sets requirements (e.g., total staked) for phase changes.
    /// @param toChrysalisStaked_ Minimum total tokens staked to trigger CHRYSALIS.
    function setPhaseThresholds(uint256 toChrysalisStaked_) public onlyOwner {
        _phaseThresholds.toChrysalisStaked = toChrysalisStaked_;
        emit PhaseThresholdsUpdated(_phaseThresholds);
    }

    /// @notice Gets current phase thresholds.
    /// @return The current PhaseThresholds struct.
    function getPhaseThresholds() public view returns (PhaseThresholds memory) {
        return _phaseThresholds;
    }

    /// @notice Owner sets duration requirements for user transformation (e.g., stake duration).
    /// @param chrysalisStakeDuration_ Minimum seconds staked in CHRYSALIS for user to become BUTTERFLY.
    function setPhaseDurations(uint64 chrysalisStakeDuration_) public onlyOwner {
        _phaseDurations.chrysalisStakeDuration = chrysalisStakeDuration_;
        emit PhaseDurationsUpdated(_phaseDurations);
    }

    /// @notice Gets current phase durations.
    /// @return The current PhaseDurations struct.
    function getPhaseDurations() public view returns (PhaseDurations memory) {
        return _phaseDurations;
    }

    /// @notice Owner controls which transfers are permitted directly between phases.
    /// By default, only transfers within the same phase are allowed.
    /// @param fromPhase The phase of the sender's tokens.
    /// @param toPhase The phase of the recipient's tokens.
    /// @param allowed True to allow, false to disallow.
    function setAllowedPhaseTransfer(Phase fromPhase, Phase toPhase, bool allowed) public onlyOwner {
        _allowedPhaseTransfer[uint8(fromPhase)][uint8(toPhase)] = allowed;
        emit AllowedPhaseTransferUpdated(fromPhase, toPhase, allowed);
    }

    /// @notice Gets allowed transfer status between phases.
    /// @param fromPhase The phase of the sender's tokens.
    /// @param toPhase The phase of the recipient's tokens.
    /// @return True if transfers between these phases are allowed, false otherwise.
    function getAllowedPhaseTransfer(Phase fromPhase, Phase toPhase) public view returns (bool) {
        return _allowedPhaseTransfer[uint8(fromPhase)][uint8(toPhase)];
    }

    // --- Staking Mechanics ---

    /// @notice Stakes tokens from the caller's balance.
    /// User must be in HATCHLING phase to initiate a stake.
    /// Staking moves user into CHRYSALIS phase regardless of global phase.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 amount) public whenStakingNotPaused {
        if (amount == 0) revert CannotStakeZero();
        address account = _msgSender();
        if (_balances[account] < amount) revert InsufficientBalance();
        if (_stakes[account].amount > 0) revert AlreadyStaked(); // Only one active stake allowed per user

        Phase userCurrentPhase = _getUserPhase(account);
        if (userCurrentPhase != Phase.HATCHLING) {
             // Only Hatchlings can initiate staking to enter Chrysalis state
             revert NotInExpectedPhase(Phase.HATCHLING, userCurrentPhase);
        }

        _balances[account] -= amount; // Tokens are effectively held by the contract
        _stakes[account] = StakeInfo({
            amount: amount,
            startTime: uint64(block.timestamp),
            rewardsClaimed: 0
        });
        _totalStakedSupply += amount;

        _updateUserPhase(account); // User should now be CHRYSALIS

        emit Staked(account, amount, _totalStakedSupply);
    }

    /// @notice Withdraws staked tokens and claims accrued rewards.
    /// Requires meeting the minimum stake duration if global phase is CHRYSALIS.
    /// Moves user to BUTTERFLY phase if duration is met and global phase is >= CHRYSALIS.
    function withdrawStake() public whenWithdrawNotPaused {
        address account = _msgSender();
        StakeInfo storage stake = _stakes[account];
        if (stake.amount == 0) revert NoActiveStake();

        // Check duration requirement if global phase is CHRYSALIS
        if (_currentGlobalPhase == Phase.CHRYSALIS) {
            if (block.timestamp < stake.startTime + _phaseDurations.chrysalisStakeDuration) {
                revert StakeDurationNotMet();
            }
        }
         // If global phase is HATCHLING or BUTTERFLY, duration isn't strictly required for withdrawal.
         // HATCHLING: User can unstake anytime.
         // BUTTERFLY: User who staked might unstake after global transition.

        // Calculate and claim rewards before unstaking
        uint256 pendingRewards = _calculateStakingRewards(account);
        uint256 totalClaimable = pendingRewards; // + potentially previous unclaimed rewards

        // Transfer staked amount back
        uint256 stakedAmount = stake.amount;
        _balances[account] += stakedAmount;
        _totalStakedSupply -= stakedAmount;

        // Handle rewards
        if (totalClaimable > 0) {
             // Mint or transfer rewards? If rewards come from total supply, need to transfer.
             // If rewards increase total supply (inflationary), need to mint.
             // Let's assume inflationary for simplicity: mint new tokens as rewards.
            _mint(account, totalClaimable);
             stake.rewardsClaimed += totalClaimable;
            emit ClaimRewards(account, totalClaimable, stake.rewardsClaimed);
        }

        // Clear stake info
        delete _stakes[account];

        // Update user phase after unstaking (likely moves to BUTTERFLY if global >= CHRYSALIS and duration met, or back to HATCHLING)
        _updateUserPhase(account);

        emit WithdrawStake(account, stakedAmount, totalClaimable, _totalStakedSupply);
    }

    /// @notice Claims accrued staking rewards without unstaking.
    /// Resets the staking start time for future reward calculation.
    function claimStakingRewards() public whenStakingNotPaused {
        address account = _msgSender();
        StakeInfo storage stake = _stakes[account];
        if (stake.amount == 0) revert NoActiveStake();

        uint256 pendingRewards = _calculateStakingRewards(account);
        if (pendingRewards == 0) revert CannotClaimZero();

        // Mint rewards
        _mint(account, pendingRewards);

        // Update stake info
        stake.rewardsClaimed += pendingRewards;
        stake.startTime = uint64(block.timestamp); // Reset timer for future rewards calculation

        emit ClaimRewards(account, pendingRewards, stake.rewardsClaimed);
    }


    /// @notice Gets detailed info about a user's stake.
    /// @param account The address of the user.
    /// @return amount Staked amount.
    /// @return startTime Stake start timestamp.
    /// @return rewardsClaimed Total rewards ever claimed.
    /// @return pendingRewards Calculated pending rewards based on current time.
    function getUserStakeInfo(address account) public view returns (uint256 amount, uint64 startTime, uint256 rewardsClaimed, uint256 pendingRewards) {
        StakeInfo storage stake = _stakes[account];
        amount = stake.amount;
        startTime = stake.startTime;
        rewardsClaimed = stake.rewardsClaimed;
        pendingRewards = _calculateStakingRewards(account);
         // Note: pendingRewards is calculated up to the *current* block timestamp,
         // even though stake.startTime is only updated on claim/withdraw.
         // This means the timer is effectively paused for rewards calculation until claim/withdraw.
         // An alternative is to update startTime on claim *and* potentially on global phase change
         // or when a threshold is met, depending on desired reward mechanics.
         // The current model is simpler: timer runs, rewards accrue, timer resets on claim/withdraw.
        return (amount, startTime, rewardsClaimed, pendingRewards);
    }

    /// @notice Calculates pending staking rewards for a user.
    /// @param account The address of the user.
    /// @return The amount of tokens pending as rewards.
    function getUserStakeRewards(address account) public view returns (uint256) {
        return _calculateStakingRewards(account);
    }

    /// @notice Returns total tokens currently staked in the contract.
    function getTotalStakedSupply() public view returns (uint256) {
        return _totalStakedSupply;
    }

    /// @notice Owner sets the annual staking reward rate.
    /// @param rate The annual reward rate in basis points (e.g., 500 for 5%). Max 10000 (100%).
    function setStakingRewardRate(uint256 rate) public onlyOwner {
        if (rate > 10000) revert InvalidFeeRate(); // Max 100% annual rate
        uint256 oldRate = _stakingRewardRate;
        _stakingRewardRate = rate;
        emit StakingRewardRateUpdated(oldRate, rate);
    }

    /// @notice Gets the current staking reward rate.
    /// @return The annual staking reward rate in basis points.
    function getStakingRewardRate() public view returns (uint256) {
        return _stakingRewardRate;
    }

    // --- Dynamic Properties & Fees ---

    /// @notice Returns the current transfer fee rate.
    /// @return The transfer fee rate in basis points (e.g., 100 for 1%).
    function getTransferFeeRate() public view returns (uint256) {
        return _transferFeeRate;
    }

    /// @notice Owner sets the transfer fee rate.
    /// @param rate The transfer fee rate in basis points (e.g., 100 for 1%). Max 10000 (100%).
    function setTransferFeeRate(uint256 rate) public onlyOwner {
         if (rate > 10000) revert InvalidFeeRate(); // Max 100% fee
        uint256 oldRate = _transferFeeRate;
        _transferFeeRate = rate;
        emit TransferFeeRateUpdated(oldRate, rate);
    }

    /// @notice Owner sets the address receiving a portion of fees.
    /// @param treasuryAddress The new treasury address. Cannot be address(0).
    function setFeeTreasury(address treasuryAddress) public onlyOwner {
        if (treasuryAddress == address(0)) revert InvalidRecipient();
        address oldTreasury = _feeTreasury;
        _feeTreasury = treasuryAddress;
        emit FeeTreasuryUpdated(oldTreasury, treasuryAddress);
    }

    /// @notice Gets the current fee treasury address.
    function getFeeTreasury() public view returns (address) {
        return _feeTreasury;
    }

    /// @notice Owner withdraws ETH from the contract's balance (if any received, e.g., from sales or other interactions).
    /// Note: Fees in this contract are collected in the token itself, not ETH.
    /// This function is for withdrawing any incidental ETH sent to the contract address.
    /// @param amount The amount of ETH to withdraw.
    function withdrawTreasury(uint256 amount) public onlyOwner {
        if (amount == 0) revert InvalidAmount();
        if (address(this).balance < amount) revert InsufficientBalance(); // contract ETH balance

        (bool success,) = _feeTreasury.call{value: amount}("");
        if (!success) revert TreasuryWithdrawFailed();
    }

    /// @notice Owner sets the ratio of collected fees to be burned.
    /// @param ratio The burn ratio in basis points (e.g., 5000 for 50%). Max 10000 (100%).
    function setFeeBurnRatio(uint256 ratio) public onlyOwner {
        if (ratio > 10000) revert InvalidBurnRatio(); // Max 100% burn
        uint256 oldRatio = _feeBurnRatio;
        _feeBurnRatio = ratio;
        emit FeeBurnRatioUpdated(oldRatio, ratio);
    }

    /// @notice Gets the current fee burn ratio.
    /// @return The fee burn ratio in basis points.
    function getFeeBurnRatio() public view returns (uint256) {
        return _feeBurnRatio;
    }


    // --- Admin & Utility ---

    /// @inheritdoc Pausable
    function pause() public override onlyOwner {
        _pause();
    }

    /// @inheritdoc Pausable
    function unpause() public override onlyOwner {
        _unpause();
    }

    /// @notice Transfers tokens to multiple recipients efficiently.
    /// Applies transfer fees and phase rules to each individual transfer.
    /// @param recipients An array of recipient addresses.
    /// @param amounts An array of amounts corresponding to each recipient.
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) public whenNotPaused {
        if (recipients.length != amounts.length) revert BatchTransferMismatch();

        address sender = _msgSender();
        for (uint i = 0; i < recipients.length; i++) {
            // Apply individual transfer logic including fees and phase checks
            _transfer(sender, recipients[i], amounts[i]);
             // Note: This approach means if any transfer fails due to balance/phase/etc., the whole batch fails.
             // For robustness, consider a pattern that allows successful transfers to complete
             // and reports failures (more complex, maybe return status array or use events).
        }
    }

     /// @inheritdoc Ownable
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // --- Phase-Specific Feature Check (Example) ---

    /// @notice Checks if a user is currently in the BUTTERFLY phase.
    /// This function could be used by external contracts or dApps
    /// to grant special access or discounts to BUTTERFLY holders.
    /// @param account The address to check.
    /// @return True if the account's tokens are in the BUTTERFLY phase, false otherwise.
    function canAccessPhase3Feature(address account) public returns (bool) {
        // Call _getUserPhase to ensure the phase is evaluated based on current state
        return _getUserPhase(account) == Phase.BUTTERFLY;
    }
}
```

---

**Explanation of Advanced/Interesting Concepts Used:**

1.  **Dynamic Token Lifecycle (Phases):** The token isn't static. It transitions through different global states (`HATCHLING`, `CHRYSALIS`, `BUTTERFLY`).
2.  **User-Specific State:** A user's token "phase" (`_userPhase`) is not just the global phase, but is also influenced by their actions (staking) and meeting specific duration requirements within a global phase.
3.  **Conditional State Transitions:** The global phase change (`initiateGlobalMetamorphosis`) is not just an owner action, but requires meeting on-chain conditions (like `_totalStakedSupply` >= `_phaseThresholds.toChrysalisStaked`). User phase transition is based on global phase AND user stake status/duration.
4.  **Dynamic Fees:** Transfer fees (`_transferFeeRate`) can be changed by the owner, making the tokenomics adaptable.
5.  **Multi-Destination Fees:** Fees are split into a burned portion (`_feeBurnRatio`) and a treasury portion, adding deflationary and funding mechanisms.
6.  **Integrated Staking:** Staking is built directly into the token contract, influencing user phase and providing rewards. Staking rewards are calculated dynamically based on duration.
7.  **Phase-Based Access Control:** Transfers are restricted based on the sender's and recipient's determined phase (`_allowedPhaseTransfer`). This prevents transfers between phases that are not logically allowed (e.g., transferring a "Hatchling" token to someone expected to hold "Chrysalis" tokens via staking).
8.  **Phase-Gated Features:** An example function (`canAccessPhase3Feature`) shows how external applications can query the token contract to determine if a user is in a specific phase (`BUTTERFLY`) to unlock features.
9.  **Batch Operations:** `batchTransfer` provides a gas-efficient way to send tokens to multiple recipients.
10. **Custom Errors:** Using `error` instead of `require` strings saves gas and provides clearer error handling.
11. **Pausable:** Standard but important for emergency control.
12. **OpenZeppelin Usage:** Leveraging audited libraries (`Ownable`, `Context`, `Pausable`, standard interfaces) for common patterns.

This contract goes beyond a simple ERC20 by weaving in state-dependent behavior, user interaction-driven state changes, and dynamic tokenomics parameters, all tied together by the concept of a token lifecycle.