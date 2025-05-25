Okay, let's design a smart contract focusing on advanced time-based logic for managing digital assets. We'll call it `ChronoVault`. It will handle ERC-20 tokens and allow users to deposit funds with complex, time-dependent release schedules and optional penalties, also allowing the creation of "template" vaults for collective contributions.

**Concept:** A dynamic, time-aware, multi-asset vault that manages token distribution based on configurable vesting schedules (like cliffs and linear release) and includes a penalty system for early withdrawals. It also supports creating "position templates" where multiple users can deposit towards a shared time-locked goal under pre-defined rules.

**Advanced/Creative Aspects:**
1.  **Dynamic Vesting Schedules:** Supports cliffs and linear release phases.
2.  **Configurable Penalties:** Early withdrawals incur a penalty, rate and destination are per-position configurable.
3.  **Position Templates:** Allows setting up a vault structure *before* tokens are deposited, enabling community contributions or goal-based deposits.
4.  **Position Ownership Transfer:** Vault positions can be transferred to another address, allowing the vesting rights/responsibilities to be traded or gifted.
5.  **Bulk Operations:** Functions for creating/depositing into multiple vaults at once.
6.  **Detailed View Functions:** Extensive getters to inspect vault state, schedule, and potential outcomes (like available amount and penalty).

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary OpenZeppelin libraries (SafeERC20, Ownable, Pausable) and ERC20 interface.
2.  **Error Handling:** Define custom errors for clarity and gas efficiency.
3.  **State Variables:**
    *   Contract owner, pausability status.
    *   Position counter.
    *   Mapping for `VaultPosition` structs by ID.
    *   Default penalty settings (address, rate).
    *   Minimum and maximum allowed lock durations.
4.  **Structs:** `VaultPosition` to hold details for each vault instance.
5.  **Events:** To signal key actions (Creation, Deposit, Claim, Transfer, Parameter Updates, etc.).
6.  **Modifiers:** Access control (`onlyOwner`, `onlyPositionOwner`) and state checks (`whenNotPaused`, `positionExists`, `positionNotFullyClaimed`).
7.  **Constructor:** Initialize contract owner, default penalty settings, and duration constraints.
8.  **Core Logic Functions:**
    *   **Creation/Deposit:**
        *   `createVaultPositionAndDeposit`: Create a new position and deposit tokens.
        *   `createVaultPositionTemplate`: Create a position structure without depositing.
        *   `depositIntoPosition`: Deposit into an existing position (template or owned).
        *   `bulkCreateVaultsAndDeposit`: Create multiple positions and deposit in bulk.
    *   **Claiming/Withdrawal:**
        *   `claimAvailableTokens`: Claim maximum currently claimable amount.
        *   `claimSpecificAmount`: Claim a specified amount (if available).
        *   Internal helper function `_calculateAvailableAmount`: Logic for vesting based on time.
        *   Internal helper function `_calculatePenaltyAmount`: Logic for penalty based on rate and early withdrawal.
    *   **Position Management:**
        *   `transferPositionOwnership`: Transfer position ownership.
        *   `updatePositionPenaltyAddress`: Update penalty recipient for a specific position.
        *   `updatePositionPenaltyRate`: Update penalty rate for a specific position.
        *   `renouncePositionOwnership`: Renounce position ownership.
9.  **Admin Functions (Owner Only):**
    *   `updateDefaultPenaltyAddress`: Update global default penalty address.
    *   `updateGlobalPenaltyRate`: Update global default penalty rate.
    *   `updateMinLockDuration`: Update minimum allowed lock duration.
    *   `updateMaxLockDuration`: Update maximum allowed lock duration.
    *   `withdrawContractBalance`: Rescue accidentally sent tokens.
    *   `pause`: Pause contract functionality.
    *   `unpause`: Unpause contract functionality.
10. **View Functions (Read-Only):**
    *   Get global settings (min/max duration, defaults).
    *   Get position details (all, owner, token, schedule, penalty info, amounts).
    *   Calculate available amount *now*.
    *   Calculate penalty for a given amount *now*.
    *   Check if a position is a template.
    *   Get total position count.

**Function Summary (Approx. 35 functions/views):**

*   `constructor(...)`
*   `createVaultPositionAndDeposit(...)`
*   `createVaultPositionTemplate(...)`
*   `depositIntoPosition(...)`
*   `bulkCreateVaultsAndDeposit(...)`
*   `claimAvailableTokens(...)`
*   `claimSpecificAmount(...)`
*   `_calculateAvailableAmount(...)` (internal)
*   `_calculatePenaltyAmount(...)` (internal)
*   `transferPositionOwnership(...)`
*   `updatePositionPenaltyAddress(...)`
*   `updatePositionPenaltyRate(...)`
*   `renouncePositionOwnership(...)`
*   `updateDefaultPenaltyAddress(...)`
*   `updateGlobalPenaltyRate(...)`
*   `updateMinLockDuration(...)`
*   `updateMaxLockDuration(...)`
*   `withdrawContractBalance(...)`
*   `pause()`
*   `unpause()`
*   `getMinLockDuration()` (view)
*   `getMaxLockDuration()` (view)
*   `getDefaultPenaltyRate()` (view)
*   `getDefaultPenaltyAddress()` (view)
*   `getPositionDetails(...)` (view)
*   `getPositionOwner(...)` (view)
*   `getPositionToken(...)` (view)
*   `getPositionSchedule(...)` (view)
*   `getPositionPenaltyInfo(...)` (view)
*   `getTotalDepositedAmount(...)` (view)
*   `getClaimedAmount(...)` (view)
*   `getRemainingAmount(...)` (view)
*   `getAvailableAmount(...)` (view, uses internal)
*   `calculatePenalty(...)` (view, uses internal)
*   `getClaimableAmountWithPenalty(...)` (view, combines available and penalty calculation)
*   `isPositionTemplate(...)` (view)
*   `getPositionCount()` (view)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title ChronoVault
/// @author Your Name/Alias
/// @notice A smart contract for managing time-locked and vested ERC-20 token distributions with dynamic penalties and position templates.
/// @dev This contract allows users to create vault positions with specific vesting schedules.
/// Funds become available over time, and early withdrawal may incur a penalty.
/// Supports position templates for crowd-deposits and transferring position ownership.

// Outline:
// 1. Pragma and Imports
// 2. Error Handling
// 3. State Variables
// 4. Structs (VaultPosition)
// 5. Events
// 6. Modifiers
// 7. Constructor
// 8. Core Logic Functions:
//    - Creation/Deposit (createVaultPositionAndDeposit, createVaultPositionTemplate, depositIntoPosition, bulkCreateVaultsAndDeposit)
//    - Claiming/Withdrawal (claimAvailableTokens, claimSpecificAmount, _calculateAvailableAmount, _calculatePenaltyAmount)
//    - Position Management (transferPositionOwnership, updatePositionPenaltyAddress, updatePositionPenaltyRate, renouncePositionOwnership)
// 9. Admin Functions (updateDefaultPenaltyAddress, updateGlobalPenaltyRate, updateMinLockDuration, updateMaxLockDuration, withdrawContractBalance, pause, unpause)
// 10. View Functions (Getters for global/position details, calculation views)

// Function Summary:
// - constructor: Initializes the contract, owner, default penalty settings, and duration constraints.
// - createVaultPositionAndDeposit: Creates a new vault position with a defined schedule and deposits tokens into it from the caller.
// - createVaultPositionTemplate: Creates a vault position structure without initial deposit, intended for others to deposit into.
// - depositIntoPosition: Allows depositing tokens into an existing vault position. Requires approval if called by someone other than the position owner or if it's a template.
// - bulkCreateVaultsAndDeposit: Creates multiple vault positions and deposits tokens for each from the caller in a single transaction.
// - claimAvailableTokens: Claims the maximum possible amount of tokens currently available from a position based on its schedule and applies any early withdrawal penalty.
// - claimSpecificAmount: Claims a requested amount of tokens from a position, only if it's less than or equal to the currently available amount, applying penalty if applicable.
// - _calculateAvailableAmount: Internal helper to determine the amount of tokens available for claiming based on the current time and position schedule.
// - _calculatePenaltyAmount: Internal helper to calculate the penalty amount for a given amount claimed early based on the position's penalty rate.
// - transferPositionOwnership: Transfers ownership of a vault position to a new address. Only callable by the current position owner.
// - updatePositionPenaltyAddress: Updates the address that receives the penalty fees for a specific position. Only callable by the position owner.
// - updatePositionPenaltyRate: Updates the penalty rate for early withdrawals for a specific position (rate in basis points). Only callable by the position owner.
// - renouncePositionOwnership: Allows a position owner to renounce ownership of their position, making it unclaimable/untransferable by them.
// - updateDefaultPenaltyAddress: Admin function to update the default penalty address for new positions.
// - updateGlobalPenaltyRate: Admin function to update the default penalty rate (in basis points) for new positions.
// - updateMinLockDuration: Admin function to set the minimum allowed duration (endTime - startTime) for new positions.
// - updateMaxLockDuration: Admin function to set the maximum allowed duration (endTime - startTime) for new positions.
// - withdrawContractBalance: Admin function to rescue any tokens accidentally sent directly to the contract address (excluding tokens held in active positions).
// - pause: Pauses the contract, preventing most operations. Only callable by the owner.
// - unpause: Unpauses the contract. Only callable by the owner.
// - getMinLockDuration: View function to get the contract's minimum allowed lock duration.
// - getMaxLockDuration: View function to get the contract's maximum allowed lock duration.
// - getDefaultPenaltyRate: View function to get the contract's default penalty rate.
// - getDefaultPenaltyAddress: View function to get the contract's default penalty address.
// - getPositionDetails: View function to retrieve all details of a specific vault position.
// - getPositionOwner: View function to get the owner address of a specific position.
// - getPositionToken: View function to get the token address associated with a specific position.
// - getPositionSchedule: View function to get the start, end, and cliff timestamps for a position.
// - getPositionPenaltyInfo: View function to get the penalty rate and address for a position.
// - getTotalDepositedAmount: View function to get the total amount of tokens ever deposited into a position.
// - getClaimedAmount: View function to get the amount of tokens already claimed from a position.
// - getRemainingAmount: View function to get the total amount minus the claimed amount for a position.
// - getAvailableAmount: View function to calculate the currently available amount for claiming for a position, *before* considering penalty.
// - calculatePenalty: View function to calculate the penalty amount that would be applied if a given amount were claimed from a position *right now*.
// - getClaimableAmountWithPenalty: View function to calculate the net amount (available - penalty) that would be received if all available tokens were claimed *right now*.
// - isPositionTemplate: View function to check if a position is configured to allow deposits from anyone.
// - getPositionCount: View function to get the total number of vault positions ever created.

error ChronoVault__PositionDoesNotExist(uint256 _positionId);
error ChronoVault__PositionAlreadyFullyClaimed(uint256 _positionId);
error ChronoVault__InsufficientFunds(uint256 _positionId, uint256 _available, uint256 _requested);
error ChronoVault__ClaimAmountTooSmall(uint256 _amount);
error ChronoVault__NotPositionOwner(uint256 _positionId);
error ChronoVault__CannotTransferToZeroAddress();
error ChronoVault__InvalidPenaltyRate(uint256 _rate); // Rate should be <= 10000 (100%)
error ChronoVault__InvalidDuration(uint256 _duration);
error ChronoVault__InvalidStartTime();
error ChronoVault__InvalidCliffTime();
error ChronoVault__DepositNotAllowed(uint256 _positionId);
error ChronoVault__TemplateDepositRequiresTokenAddress(); // Specific error for depositing into template
error ChronoVault__ArrayLengthMismatch();

struct VaultPosition {
    address owner;           // Address of the position owner
    address token;           // Address of the ERC-20 token
    uint256 totalAmount;     // Total amount ever deposited
    uint256 claimedAmount;   // Amount already claimed/withdrawn
    uint64 startTime;       // Timestamp when vesting begins
    uint64 endTime;         // Timestamp when vesting ends
    uint64 cliffTime;       // Timestamp of the cliff (if any)
    uint16 penaltyRate;     // Penalty rate for early withdrawal (in basis points, 0-10000)
    address penaltyAddress;  // Address to send penalty fees
    bool allowAnyoneToDeposit; // If true, anyone can deposit into this position
}

mapping(uint256 => VaultPosition) private s_vaultPositions;
uint256 private s_positionCounter;

address private s_defaultPenaltyAddress;
uint16 private s_globalPenaltyRate; // in basis points, 0-10000 (0% to 100%)

uint256 private s_minLockDuration;
uint256 private s_maxLockDuration;

// Use SafeERC20 for safer token interactions
using SafeERC20 for IERC20;

// --- Events ---
event PositionCreated(uint256 indexed positionId, address indexed owner, address token, uint64 startTime, uint64 endTime, uint64 cliffTime);
event TokensDeposited(uint256 indexed positionId, address indexed depositor, address token, uint256 amount, uint256 totalDeposited);
event TokensClaimed(uint256 indexed positionId, address indexed claimant, address token, uint256 amountClaimed, uint256 penaltyPaid, uint256 remainingAmount);
event PositionTransferred(uint256 indexed positionId, address indexed from, address indexed to);
event PositionPenaltyAddressUpdated(uint256 indexed positionId, address oldAddress, address newAddress);
event PositionPenaltyRateUpdated(uint256 indexed positionId, uint16 oldRate, uint16 newRate);
event DefaultPenaltyAddressUpdated(address oldAddress, address newAddress);
event GlobalPenaltyRateUpdated(uint16 oldRate, uint16 newRate);
event MinLockDurationUpdated(uint256 oldDuration, uint256 newDuration);
event MaxLockDurationUpdated(uint256 oldDuration, uint256 newDuration);

// --- Modifiers ---
modifier positionExists(uint256 _positionId) {
    if (_positionId == 0 || _positionId > s_positionCounter) {
        revert ChronoVault__PositionDoesNotExist(_positionId);
    }
    _;
}

modifier onlyPositionOwner(uint256 _positionId) {
    if (s_vaultPositions[_positionId].owner != msg.sender) {
        revert ChronoVault__NotPositionOwner(_positionId);
    }
    _;
}

modifier positionNotFullyClaimed(uint256 _positionId) {
    if (s_vaultPositions[_positionId].claimedAmount >= s_vaultPositions[_positionId].totalAmount) {
         revert ChronoVault__PositionAlreadyFullyClaimed(_positionId);
    }
    _;
}

// --- Constructor ---
constructor(
    address _defaultPenaltyAddress,
    uint16 _globalPenaltyRateBasisPoints,
    uint256 _minLockDuration, // in seconds
    uint256 _maxLockDuration  // in seconds
) Ownable(msg.sender) Pausable() {
    if (_globalPenaltyRateBasisPoints > 10000) {
        revert ChronoVault__InvalidPenaltyRate(_globalPenaltyRateBasisPoints);
    }
    if (_minLockDuration > _maxLockDuration) {
        revert ChronoVault__InvalidDuration(0); // Indicate invalid range
    }

    s_defaultPenaltyAddress = _defaultPenaltyAddress;
    s_globalPenaltyRate = _globalPenaltyRateBasisPoints;
    s_minLockDuration = _minLockDuration;
    s_maxLockDuration = _maxLockDuration;
    s_positionCounter = 0; // Positions start from ID 1
}

// --- Core Logic: Creation & Deposit ---

/// @notice Creates a new vault position and deposits tokens into it.
/// @dev Requires caller to have approved this contract to spend `_amount` of `_token`.
/// The token address, start time, end time, cliff time, penalty settings, and deposit permission are configured.
/// @param _token The address of the ERC-20 token.
/// @param _amount The amount of tokens to deposit initially.
/// @param _startTime The timestamp when the vesting/locking period begins. Must be <= _endTime.
/// @param _endTime The timestamp when the vesting/locking period ends and all funds are available. Must be > _startTime.
/// @param _cliffTime The timestamp of the cliff. No tokens are available before this time (unless _cliffTime == _startTime). Must be >= _startTime and <= _endTime.
/// @param _penaltyRate The penalty rate for early withdrawal in basis points (0-10000). If 0, uses the global default.
/// @param _penaltyAddress The address to send penalty fees. If address(0), uses the global default.
/// @param _allowAnyoneToDeposit If true, allows any address to deposit into this position later.
/// @return The ID of the newly created vault position.
function createVaultPositionAndDeposit(
    address _token,
    uint256 _amount,
    uint64 _startTime,
    uint64 _endTime,
    uint64 _cliffTime,
    uint16 _penaltyRate,
    address _penaltyAddress,
    bool _allowAnyoneToDeposit
) external whenNotPaused returns (uint256) {
    if (_amount == 0) {
        revert ChronoVault__InsufficientFunds(0, 0, 0); // Position ID 0 indicates creation error
    }

    uint256 positionId = _createVaultPositionInternal(
        _token,
        _startTime,
        _endTime,
        _cliffTime,
        _penaltyRate,
        _penaltyAddress,
        _allowAnyoneToDeposit,
        _amount // Initial amount for validation
    );

    s_vaultPositions[positionId].totalAmount = _amount;

    // Transfer initial deposit
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    emit TokensDeposited(positionId, msg.sender, _token, _amount, _amount);

    return positionId;
}

/// @notice Creates a vault position structure without an initial deposit.
/// @dev Useful for setting up template vaults where others can deposit later.
/// Requires caller to be the desired owner of the template.
/// @param _token The address of the ERC-20 token this template is for.
/// @param _startTime The timestamp when the vesting/locking period begins. Must be <= _endTime.
/// @param _endTime The timestamp when the vesting/locking period ends. Must be > _startTime.
/// @param _cliffTime The timestamp of the cliff. Must be >= _startTime and <= _endTime.
/// @param _penaltyRate The penalty rate (0-10000). If 0, uses global default.
/// @param _penaltyAddress The address for penalties. If address(0), uses global default.
/// @param _allowAnyoneToDeposit Must be true for a template intended for crowd-deposits.
/// @return The ID of the newly created vault position template.
function createVaultPositionTemplate(
    address _token,
    uint64 _startTime,
    uint64 _endTime,
    uint64 _cliffTime,
    uint16 _penaltyRate,
    address _penaltyAddress,
    bool _allowAnyoneToDeposit
) external whenNotPaused returns (uint256) {
    // Templates usually allow deposits from anyone, but technically you could make a template only you can deposit into later
    // if you want to define the rules first. Let's just allow the flag to be set here.
    // If _allowAnyoneToDeposit is false, only the owner can deposit into this template later.

    return _createVaultPositionInternal(
        _token,
        _startTime,
        _endTime,
        _cliffTime,
        _penaltyRate,
        _penaltyAddress,
        _allowAnyoneToDeposit,
        0 // No initial amount
    );
}

/// @notice Internal helper to create a vault position struct.
/// @dev Handles validation and increments the position counter.
/// @param _initialAmount Used only for duration validation if > 0.
/// @return The new position ID.
function _createVaultPositionInternal(
    address _token,
    uint64 _startTime,
    uint64 _endTime,
    uint64 _cliffTime,
    uint16 _penaltyRate,
    address _penaltyAddress,
    bool _allowAnyoneToDeposit,
    uint256 _initialAmount
) private returns (uint256) {
    if (_startTime >= _endTime) {
        revert ChronoVault__InvalidStartTime();
    }
    if (_cliffTime < _startTime || _cliffTime > _endTime) {
         revert ChronoVault__InvalidCliffTime();
    }

    uint256 duration = _endTime - _startTime;
    if (duration < s_minLockDuration || duration > s_maxLockDuration) {
        revert ChronoVault__InvalidDuration(duration);
    }

    if (_penaltyRate > 10000) {
        revert ChronoVault__InvalidPenaltyRate(_penaltyRate);
    }

    s_positionCounter++;
    uint256 newPositionId = s_positionCounter;

    s_vaultPositions[newPositionId] = VaultPosition({
        owner: msg.sender,
        token: _token,
        totalAmount: 0, // Will be updated by deposit function
        claimedAmount: 0,
        startTime: _startTime,
        endTime: _endTime,
        cliffTime: _cliffTime,
        penaltyRate: _penaltyRate == 0 ? s_globalPenaltyRate : _penaltyRate,
        penaltyAddress: _penaltyAddress == address(0) ? s_defaultPenaltyAddress : _penaltyAddress,
        allowAnyoneToDeposit: _allowAnyoneToDeposit
    });

    emit PositionCreated(newPositionId, msg.sender, _token, _startTime, _endTime, _cliffTime);

    return newPositionId;
}


/// @notice Deposits additional tokens into an existing vault position.
/// @dev Only callable by the position owner or if the position allows anyone to deposit.
/// Requires caller to have approved this contract to spend `_amount` of the position's token.
/// @param _positionId The ID of the target vault position.
/// @param _amount The amount of tokens to deposit.
function depositIntoPosition(
    uint256 _positionId,
    uint256 _amount
) external whenNotPaused positionExists(_positionId) positionNotFullyClaimed(_positionId) {
    VaultPosition storage position = s_vaultPositions[_positionId];

    // Check if depositor is allowed
    if (msg.sender != position.owner && !position.allowAnyoneToDeposit) {
        revert ChronoVault__DepositNotAllowed(_positionId);
    }

    if (_amount == 0) {
         revert ChronoVault__InsufficientFunds(_positionId, 0, 0); // Amount 0 is invalid
    }

    // Transfer the tokens
    IERC20(position.token).safeTransferFrom(msg.sender, address(this), _amount);

    // Update total amount
    position.totalAmount += _amount;

    emit TokensDeposited(_positionId, msg.sender, position.token, _amount, position.totalAmount);
}

/// @notice Creates multiple vault positions and deposits tokens into each in a single transaction.
/// @dev Requires caller to have approved this contract for the total amount across all positions for the respective tokens.
/// Array lengths for all parameters must match.
/// @param _tokens Array of token addresses.
/// @param _amounts Array of amounts to deposit for each position.
/// @param _startTimes Array of start timestamps.
/// @param _endTimes Array of end timestamps.
/// @param _cliffTimes Array of cliff timestamps.
/// @param _penaltyRates Array of penalty rates.
/// @param _penaltyAddresses Array of penalty addresses.
/// @param _allowAnyoneToDeposits Array of deposit permission flags.
function bulkCreateVaultsAndDeposit(
    address[] memory _tokens,
    uint256[] memory _amounts,
    uint64[] memory _startTimes,
    uint64[] memory _endTimes,
    uint64[] memory _cliffTimes,
    uint16[] memory _penaltyRates,
    address[] memory _penaltyAddresses,
    bool[] memory _allowAnyoneToDeposits
) external whenNotPaused {
    uint256 count = _tokens.length;
    if (count == 0 || _amounts.length != count || _startTimes.length != count ||
        _endTimes.length != count || _cliffTimes.length != count ||
        _penaltyRates.length != count || _penaltyAddresses.length != count ||
        _allowAnyoneToDeposits.length != count) {
        revert ChronoVault__ArrayLengthMismatch();
    }

    for (uint i = 0; i < count; i++) {
        uint256 positionId = _createVaultPositionInternal(
            _tokens[i],
            _startTimes[i],
            _endTimes[i],
            _cliffTimes[i],
            _penaltyRates[i],
            _penaltyAddresses[i],
            _allowAnyoneToDeposits[i],
            _amounts[i] // Pass amount for duration validation
        );

        s_vaultPositions[positionId].totalAmount = _amounts[i];

        // Transfer initial deposit for this specific position
        if (_amounts[i] > 0) {
             IERC20(_tokens[i]).safeTransferFrom(msg.sender, address(this), _amounts[i]);
        }


        emit TokensDeposited(positionId, msg.sender, _tokens[i], _amounts[i], _amounts[i]);
    }
}

// --- Core Logic: Claiming & Withdrawal ---

/// @notice Claims the maximum amount of tokens currently available from a vault position.
/// @dev Calculates the available amount based on the vesting schedule and applies any penalty if claiming early.
/// Tokens are transferred to the position owner.
/// @param _positionId The ID of the vault position.
function claimAvailableTokens(uint256 _positionId) external whenNotPaused positionExists(_positionId) positionNotFullyClaimed(_positionId) {
    VaultPosition storage position = s_vaultPositions[_positionId];

    // Only position owner can claim
    if (msg.sender != position.owner) {
        revert ChronoVault__NotPositionOwner(_positionId);
    }

    uint256 availableAmount = _calculateAvailableAmount(_positionId);

    // Ensure there's something to claim
    if (availableAmount == 0) {
         revert ChronoVault__InsufficientFunds(_positionId, availableAmount, 0);
    }

    // Calculate penalty if claiming before endTime
    uint256 penaltyAmount = 0;
    if (block.timestamp < position.endTime) {
        penaltyAmount = _calculatePenaltyAmount(_positionId, availableAmount);
    }

    uint256 amountToClaimNet = availableAmount - penaltyAmount;

    // Update claimed amount *before* transfers (Checks-Effects-Interactions pattern)
    position.claimedAmount += availableAmount; // Note: claimedAmount tracks the *gross* amount available

    // Transfer tokens
    if (amountToClaimNet > 0) {
        IERC20(position.token).safeTransfer(position.owner, amountToClaimNet);
    }
    if (penaltyAmount > 0) {
        // Send penalty to the specified address
        IERC20(position.token).safeTransfer(position.penaltyAddress, penaltyAmount);
    }

    emit TokensClaimed(_positionId, msg.sender, position.token, amountToClaimNet, penaltyAmount, position.totalAmount - position.claimedAmount);
}

/// @notice Claims a specific amount of tokens from a vault position.
/// @dev The requested amount must be less than or equal to the currently available amount.
/// Applies any penalty if claiming early. Tokens are transferred to the position owner.
/// @param _positionId The ID of the vault position.
/// @param _amountToClaim The specific amount of tokens to claim.
function claimSpecificAmount(uint256 _positionId, uint256 _amountToClaim) external whenNotPaused positionExists(_positionId) positionNotFullyClaimed(_positionId) {
    VaultPosition storage position = s_vaultPositions[_positionId];

    // Only position owner can claim
    if (msg.sender != position.owner) {
        revert ChronoVault__NotPositionOwner(_positionId);
    }

    if (_amountToClaim == 0) {
        revert ChronoVault__ClaimAmountTooSmall(0);
    }

    uint256 availableAmount = _calculateAvailableAmount(_positionId);

    // Check if the requested amount is available
    if (_amountToClaim > availableAmount) {
        revert ChronoVault__InsufficientFunds(_positionId, availableAmount, _amountToClaim);
    }

    // Calculate penalty if claiming before endTime
    uint256 penaltyAmount = 0;
    if (block.timestamp < position.endTime) {
        penaltyAmount = _calculatePenaltyAmount(_positionId, _amountToClaim);
    }

    uint256 amountToClaimNet = _amountToClaim - penaltyAmount;

     // Update claimed amount *before* transfers (Checks-Effects-Interactions pattern)
    position.claimedAmount += _amountToClaim; // Note: claimedAmount tracks the *gross* amount claimed

    // Transfer tokens
    if (amountToClaimNet > 0) {
        IERC20(position.token).safeTransfer(position.owner, amountToClaimNet);
    }
    if (penaltyAmount > 0) {
        // Send penalty to the specified address
        IERC20(position.token).safeTransfer(position.penaltyAddress, penaltyAmount);
    }

    emit TokensClaimed(_positionId, msg.sender, position.token, amountToClaimNet, penaltyAmount, position.totalAmount - position.claimedAmount);
}

/// @notice Internal helper to calculate the amount of tokens available for claiming.
/// @dev Calculation is based on the current time and the position's vesting schedule (cliff and linear release).
/// @param _positionId The ID of the vault position.
/// @return The amount of tokens available for claiming, before subtracting the already claimed amount and before penalty calculation.
function _calculateAvailableAmount(uint256 _positionId) internal view positionExists(_positionId) returns (uint256) {
    VaultPosition storage position = s_vaultPositions[_positionId];
    uint256 total = position.totalAmount;
    uint64 start = position.startTime;
    uint64 end = position.endTime;
    uint64 cliff = position.cliffTime;
    uint64 now64 = uint64(block.timestamp);

    // If current time is before the start, nothing is available
    if (now64 < start) {
        return 0;
    }

    // If current time is at or after the end, all remaining tokens are available
    if (now64 >= end) {
        return total;
    }

    // If current time is between start and end, apply vesting schedule
    // Check cliff time first
    if (now64 < cliff) {
        return 0; // Before cliff, nothing is available
    }

    // Time is after cliff and before end, calculate linearly vested amount
    // Vesting duration after cliff starts (effectively) is end - start (the full period)
    uint256 lockDuration = end - start;
    // Time elapsed *since start*
    uint256 timeElapsedSinceStart = now64 - start;

    // Calculate the proportion vested since start time, relative to the total duration
    // Use Math.mulDiv for precision: (total * timeElapsedSinceStart) / lockDuration
    // The vested amount is a proportion of the *total* amount based on time.
    uint256 vestedAmount = Math.mulDiv(total, timeElapsedSinceStart, lockDuration);

    return vestedAmount;
}

/// @notice Internal helper to calculate the penalty amount for claiming early.
/// @dev Penalty is applied if `block.timestamp < position.endTime`.
/// @param _positionId The ID of the vault position.
/// @param _amount The amount being claimed.
/// @return The penalty amount to be deducted.
function _calculatePenaltyAmount(uint256 _positionId, uint256 _amount) internal view positionExists(_positionId) returns (uint256) {
    VaultPosition storage position = s_vaultPositions[_positionId];

    // Penalty only applies if claiming BEFORE the end time
    if (block.timestamp >= position.endTime || position.penaltyRate == 0) {
        return 0;
    }

    // Calculate penalty based on the amount being claimed and the penalty rate
    // Rate is in basis points (e.g., 10000 for 100%)
    return Math.mulDiv(_amount, position.penaltyRate, 10000);
}


// --- Core Logic: Position Management ---

/// @notice Transfers the ownership of a vault position to a new address.
/// @dev Only the current position owner can call this function.
/// The new owner gains the right to claim tokens from the position.
/// @param _positionId The ID of the vault position.
/// @param _newOwner The address of the new owner.
function transferPositionOwnership(uint256 _positionId, address _newOwner) external whenNotPaused positionExists(_positionId) onlyPositionOwner(_positionId) {
    if (_newOwner == address(0)) {
        revert ChronoVault__CannotTransferToZeroAddress();
    }

    address oldOwner = s_vaultPositions[_positionId].owner;
    s_vaultPositions[_positionId].owner = _newOwner;

    emit PositionTransferred(_positionId, oldOwner, _newOwner);
}

/// @notice Updates the address that receives penalty fees for a specific vault position.
/// @dev Only the position owner can call this function.
/// @param _positionId The ID of the vault position.
/// @param _newPenaltyAddress The new address for penalty fees. If address(0), reverts to the contract's default.
function updatePositionPenaltyAddress(uint256 _positionId, address _newPenaltyAddress) external whenNotPaused positionExists(_positionId) onlyPositionOwner(_positionId) {
     if (_newPenaltyAddress == address(0)) {
         // Revert to default behavior
         _newPenaltyAddress = s_defaultPenaltyAddress;
     }
    address oldAddress = s_vaultPositions[_positionId].penaltyAddress;
    s_vaultPositions[_positionId].penaltyAddress = _newPenaltyAddress;
    emit PositionPenaltyAddressUpdated(_positionId, oldAddress, _newPenaltyAddress);
}

/// @notice Updates the penalty rate for early withdrawals for a specific vault position.
/// @dev Only the position owner can call this function. Rate is in basis points (0-10000).
/// @param _positionId The ID of the vault position.
/// @param _newPenaltyRate The new penalty rate (in basis points). If 0, reverts to the contract's global default.
function updatePositionPenaltyRate(uint256 _positionId, uint16 _newPenaltyRate) external whenNotPaused positionExists(_positionId) onlyPositionOwner(_positionId) {
    if (_newPenaltyRate > 10000) {
        revert ChronoVault__InvalidPenaltyRate(_newPenaltyRate);
    }
     uint16 oldRate = s_vaultPositions[_positionId].penaltyRate;
    s_vaultPositions[_positionId].penaltyRate = _newPenaltyRate == 0 ? s_globalPenaltyRate : _newPenaltyRate;
     emit PositionPenaltyRateUpdated(_positionId, oldRate, s_vaultPositions[_positionId].penaltyRate);
}

/// @notice Allows a position owner to renounce their ownership.
/// @dev The position will no longer have a specific owner address (becomes address(0)).
/// This effectively locks the remaining funds in the vault forever unless the contract includes a specific recovery mechanism (which this version does not for renounced positions).
/// Use with caution.
/// @param _positionId The ID of the vault position.
function renouncePositionOwnership(uint256 _positionId) external whenNotPaused positionExists(_positionId) onlyPositionOwner(_positionId) {
    address oldOwner = s_vaultPositions[_positionId].owner;
    s_vaultPositions[_positionId].owner = address(0);
     emit PositionTransferred(_positionId, oldOwner, address(0));
}


// --- Admin Functions (Owner Only) ---

/// @notice Updates the default penalty address used for new positions if no specific address is provided.
/// @dev Only callable by the contract owner.
/// @param _newDefaultPenaltyAddress The new default penalty address. Must not be address(0).
function updateDefaultPenaltyAddress(address _newDefaultPenaltyAddress) external onlyOwner whenNotPaused {
    if (_newDefaultPenaltyAddress == address(0)) {
         revert ChronoVault__CannotTransferToZeroAddress(); // Cannot set default to zero
    }
    address oldAddress = s_defaultPenaltyAddress;
    s_defaultPenaltyAddress = _newDefaultPenaltyAddress;
    emit DefaultPenaltyAddressUpdated(oldAddress, _newDefaultPenaltyAddress);
}

/// @notice Updates the global default penalty rate used for new positions if no specific rate is provided.
/// @dev Only callable by the contract owner. Rate in basis points (0-10000).
/// @param _newGlobalPenaltyRateBasisPoints The new global default penalty rate.
function updateGlobalPenaltyRate(uint16 _newGlobalPenaltyRateBasisPoints) external onlyOwner whenNotPaused {
    if (_newGlobalPenaltyRateBasisPoints > 10000) {
        revert ChronoVault__InvalidPenaltyRate(_newGlobalPenaltyRateBasisPoints);
    }
    uint16 oldRate = s_globalPenaltyRate;
    s_globalPenaltyRate = _newGlobalPenaltyRateBasisPoints;
    emit GlobalPenaltyRateUpdated(oldRate, _newGlobalPenaltyRateBasisPoints);
}

/// @notice Updates the minimum allowed lock duration for new positions.
/// @dev Only callable by the contract owner. Must be less than or equal to the current max duration.
/// @param _newMinLockDuration The new minimum duration in seconds.
function updateMinLockDuration(uint256 _newMinLockDuration) external onlyOwner whenNotPaused {
    if (_newMinLockDuration > s_maxLockDuration) {
         revert ChronoVault__InvalidDuration(_newMinLockDuration); // Cannot set min > max
    }
    uint256 oldDuration = s_minLockDuration;
    s_minLockDuration = _newMinLockDuration;
     emit MinLockDurationUpdated(oldDuration, _newMinLockDuration);
}

/// @notice Updates the maximum allowed lock duration for new positions.
/// @dev Only callable by the contract owner. Must be greater than or equal to the current min duration.
/// @param _newMaxLockDuration The new maximum duration in seconds.
function updateMaxLockDuration(uint256 _newMaxLockDuration) external onlyOwner whenNotPaused {
    if (_newMaxLockDuration < s_minLockDuration) {
        revert ChronoVault__InvalidDuration(_newMaxLockDuration); // Cannot set max < min
    }
     uint256 oldDuration = s_maxLockDuration;
    s_maxLockDuration = _newMaxLockDuration;
     emit MaxLockDurationUpdated(oldDuration, _newMaxLockDuration);
}


/// @notice Allows the contract owner to withdraw tokens that were sent directly to the contract address
/// and are NOT associated with any specific vault position (e.g., accidental transfers).
/// @dev Use with caution. Cannot withdraw tokens held within active vault positions.
/// @param _token The address of the ERC-20 token to withdraw.
/// @param _amount The amount of tokens to withdraw.
function withdrawContractBalance(address _token, uint256 _amount) external onlyOwner whenNotPaused {
    IERC20 token = IERC20(_token);
    uint256 contractBalance = token.balanceOf(address(this));

    // Calculate the total amount held within all vault positions for this token
    // NOTE: This is a simplified check. In a real, large-scale contract, iterating
    // through all positions might hit gas limits. A more robust system would track
    // total locked balances per token. For this example, we iterate.
    uint256 totalLockedInPositions = 0;
     // This loop might be expensive if s_positionCounter is very large.
    for(uint256 i = 1; i <= s_positionCounter; i++) {
        VaultPosition storage pos = s_vaultPositions[i];
         // Check if position exists and holds the requested token
        if(pos.token == _token) {
            totalLockedInPositions += (pos.totalAmount - pos.claimedAmount);
        }
    }

    uint256 unlockedBalance = contractBalance - totalLockedInPositions;

    if (_amount > unlockedBalance) {
        // Reverting with a generic message to avoid leaking balance info for security
        revert ChronoVault__InsufficientFunds(0, unlockedBalance, _amount);
    }

    token.safeTransfer(msg.sender, _amount);
}

/// @notice Pauses the contract. Most state-changing functions will be blocked.
/// @dev Only callable by the contract owner.
function pause() external onlyOwner {
    _pause();
}

/// @notice Unpauses the contract, resuming normal operations.
/// @dev Only callable by the contract owner.
function unpause() external onlyOwner {
    _unpause();
}

// --- View Functions ---

/// @notice Gets the contract's minimum allowed lock duration for new positions.
/// @return Minimum duration in seconds.
function getMinLockDuration() external view returns (uint256) {
    return s_minLockDuration;
}

/// @notice Gets the contract's maximum allowed lock duration for new positions.
/// @return Maximum duration in seconds.
function getMaxLockDuration() external view returns (uint256) {
    return s_maxLockDuration;
}

/// @notice Gets the contract's default penalty rate.
/// @return Default rate in basis points (0-10000).
function getDefaultPenaltyRate() external view returns (uint16) {
    return s_globalPenaltyRate;
}

/// @notice Gets the contract's default penalty address.
/// @return Default penalty address.
function getDefaultPenaltyAddress() external view returns (address) {
    return s_defaultPenaltyAddress;
}

/// @notice Gets all details for a specific vault position.
/// @param _positionId The ID of the vault position.
/// @return A tuple containing all fields from the VaultPosition struct.
function getPositionDetails(uint256 _positionId) external view positionExists(_positionId) returns (
    address owner,
    address token,
    uint256 totalAmount,
    uint256 claimedAmount,
    uint64 startTime,
    uint64 endTime,
    uint64 cliffTime,
    uint16 penaltyRate,
    address penaltyAddress,
    bool allowAnyoneToDeposit
) {
    VaultPosition storage position = s_vaultPositions[_positionId];
    return (
        position.owner,
        position.token,
        position.totalAmount,
        position.claimedAmount,
        position.startTime,
        position.endTime,
        position.cliffTime,
        position.penaltyRate,
        position.penaltyAddress,
        position.allowAnyoneToDeposit
    );
}

/// @notice Gets the owner address of a specific vault position.
/// @param _positionId The ID of the vault position.
/// @return The position owner's address.
function getPositionOwner(uint256 _positionId) external view positionExists(_positionId) returns (address) {
    return s_vaultPositions[_positionId].owner;
}

/// @notice Gets the token address associated with a specific vault position.
/// @param _positionId The ID of the vault position.
/// @return The ERC-20 token address.
function getPositionToken(uint256 _positionId) external view positionExists(_positionId) returns (address) {
    return s_vaultPositions[_positionId].token;
}

/// @notice Gets the schedule timestamps for a specific vault position.
/// @param _positionId The ID of the vault position.
/// @return A tuple containing the start, end, and cliff timestamps.
function getPositionSchedule(uint256 _positionId) external view positionExists(_positionId) returns (uint64 startTime, uint64 endTime, uint64 cliffTime) {
    VaultPosition storage position = s_vaultPositions[_positionId];
    return (position.startTime, position.endTime, position.cliffTime);
}

/// @notice Gets the penalty information for a specific vault position.
/// @param _positionId The ID of the vault position.
/// @return A tuple containing the penalty rate (basis points) and penalty address.
function getPositionPenaltyInfo(uint256 _positionId) external view positionExists(_positionId) returns (uint16 penaltyRate, address penaltyAddress) {
    VaultPosition storage position = s_vaultPositions[_positionId];
    return (position.penaltyRate, position.penaltyAddress);
}


/// @notice Gets the total amount of tokens deposited into a specific vault position.
/// @param _positionId The ID of the vault position.
/// @return The total deposited amount.
function getTotalDepositedAmount(uint256 _positionId) external view positionExists(_positionId) returns (uint256) {
    return s_vaultPositions[_positionId].totalAmount;
}

/// @notice Gets the amount of tokens already claimed from a specific vault position.
/// @param _positionId The ID of the vault position.
/// @return The amount claimed.
function getClaimedAmount(uint256 _positionId) external view positionExists(_positionId) returns (uint256) {
    return s_vaultPositions[_positionId].claimedAmount;
}

/// @notice Gets the amount of tokens remaining in a specific vault position (Total - Claimed).
/// @param _positionId The ID of the vault position.
/// @return The remaining amount.
function getRemainingAmount(uint256 _positionId) external view positionExists(_positionId) returns (uint256) {
    VaultPosition storage position = s_vaultPositions[_positionId];
    return position.totalAmount - position.claimedAmount;
}

/// @notice Calculates the amount of tokens currently available for claiming from a position.
/// @dev This is the amount before subtracting `claimedAmount` and before applying penalty.
/// @param _positionId The ID of the vault position.
/// @return The currently available amount based on the vesting schedule.
function getAvailableAmount(uint256 _positionId) external view positionExists(_positionId) returns (uint256) {
    uint256 totalVested = _calculateAvailableAmount(_positionId);
    VaultPosition storage position = s_vaultPositions[_positionId];
    // Actual claimable amount is the vested amount minus what's already claimed
    // It also cannot exceed the total remaining amount
    uint256 remaining = position.totalAmount - position.claimedAmount;
    return Math.min(totalVested, remaining);
}

/// @notice Calculates the penalty amount for claiming a specific amount from a position *right now*.
/// @dev Penalty is based on the position's penalty rate and whether `block.timestamp < position.endTime`.
/// @param _positionId The ID of the vault position.
/// @param _amountToClaim The amount you intend to claim (used for calculation).
/// @return The calculated penalty amount.
function calculatePenalty(uint256 _positionId, uint256 _amountToClaim) external view positionExists(_positionId) returns (uint256) {
    return _calculatePenaltyAmount(_positionId, _amountToClaim);
}

/// @notice Calculates the net amount that would be received if all currently available tokens were claimed right now.
/// @dev This is `getAvailableAmount` minus the penalty calculated on that amount.
/// @param _positionId The ID of the vault position.
/// @return The net amount claimable after penalty.
function getClaimableAmountWithPenalty(uint256 _positionId) external view positionExists(_positionId) returns (uint256) {
    uint256 availableAmount = getAvailableAmount(_positionId); // Uses the external view getter which handles claimedAmount subtraction
    uint256 penaltyAmount = _calculatePenaltyAmount(_positionId, availableAmount);
    return availableAmount - penaltyAmount;
}

/// @notice Checks if a vault position is configured to allow deposits from any address.
/// @param _positionId The ID of the vault position.
/// @return True if anyone can deposit, false otherwise.
function isPositionTemplate(uint256 _positionId) external view positionExists(_positionId) returns (bool) {
    return s_vaultPositions[_positionId].allowAnyoneToDeposit;
}

/// @notice Gets the total number of vault positions ever created.
/// @return The total position count.
function getPositionCount() external view returns (uint256) {
    return s_positionCounter;
}

}
```