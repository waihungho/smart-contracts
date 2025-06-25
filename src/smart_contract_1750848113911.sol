Okay, here is a Solidity smart contract implementing a "Hyperbolic Time Lock" concept, which I've simplified to a "Quadratic Time Decay Penalty" for easier implementation in Solidity without complex fixed-point libraries or approximations of transcendental functions like `tanh`.

The core idea is a time-locked vault where users deposit Ether for a set duration. They can withdraw early, but face a penalty. This penalty is not a fixed percentage, but decreases quadratically as the time elapsed approaches the total lock duration. The penalty is higher the earlier you withdraw.

It includes features like multiple locks per user, partial early withdrawals, configurable penalty parameters, protocol fees, ownership, and pause functionality.

---

**Smart Contract: HyperbolicTimeLock**

**Outline:**

1.  **SPDX-License-Identifier & Pragma:** Standard Solidity header.
2.  **Error Definitions:** Custom errors for clarity and gas efficiency.
3.  **Structs:**
    *   `Anchor`: Represents a single time-locked deposit.
4.  **State Variables:**
    *   `_owner`: Contract owner.
    *   `_paused`: Paused state flag.
    *   `nextAnchorId`: Counter for unique anchor IDs.
    *   `anchors`: Array storing all `Anchor` structs.
    *   `userAnchorIds`: Mapping from user address to an array of their anchor IDs.
    *   `maxPenaltyBasisPoints`: Maximum possible penalty rate (in basis points).
    *   `penaltyDecayExponent`: Exponent for the quadratic decay calculation (fixed as 2 in this simplified version).
    *   `protocolFeeBasisPoints`: Fee rate charged on penalties (in basis points).
    *   `feeRecipient`: Address to receive protocol fees.
    *   `totalLockedValue`: Total Ether currently locked in the contract.
    *   `totalProtocolFeesCollected`: Total fees collected by the protocol.
5.  **Events:**
    *   `AnchorCreated`: When a new lock is created.
    *   `AnchorWithdrawn`: When an anchor is fully withdrawn after unlock time.
    *   `AnchorEarlyWithdrawn`: When an anchor is fully withdrawn before unlock time.
    *   `AnchorPartialEarlyWithdrawn`: When a partial withdrawal occurs before unlock time.
    *   `PenaltyParametersUpdated`: When penalty settings are changed.
    *   `ProtocolFeeParametersUpdated`: When fee settings are changed.
    *   `FeeRecipientUpdated`: When the fee recipient address is changed.
    *   `Paused`: When the contract is paused.
    *   `Unpaused`: When the contract is unpaused.
    *   `OwnershipTransferred`: Standard ownership transfer event.
    *   `ProtocolFeesWithdrawn`: When collected fees are withdrawn.
6.  **Modifiers:**
    *   `onlyOwner`: Restricts function access to the contract owner.
    *   `whenNotPaused`: Allows function execution only when the contract is not paused.
    *   `whenPaused`: Allows function execution only when the contract is paused.
7.  **Constructor:** Sets initial owner, penalty, fee parameters, and recipient.
8.  **Internal Helper Functions:**
    *   `_calculatePenaltyBasisPointsInternal`: Calculates the current penalty rate based on time elapsed and duration using the quadratic decay formula.
    *   `_getAnchor`: Retrieves an anchor by ID, ensuring it exists.
9.  **Core Functionality (Actions):**
    *   `createAnchor`: Allows users to deposit Ether for a specified duration.
    *   `withdrawAnchor`: Allows withdrawal of full amount after the unlock time.
    *   `earlyWithdrawAnchor`: Allows withdrawal of full amount before unlock time, applying penalty and fee.
    *   `partialEarlyWithdrawAnchor`: Allows withdrawal of a partial amount before unlock time, applying penalty and fee proportionally.
10. **Calculation & Query Functions (Views):**
    *   `calculateCurrentPenaltyBasisPoints`: Public view function to calculate the penalty rate for an anchor.
    *   `calculateEarlyWithdrawalAmount`: Calculates the net amount received for a full early withdrawal.
    *   `calculatePartialEarlyWithdrawalAmount`: Calculates the net amount received for a partial early withdrawal.
    *   `getAnchor`: Retrieves details of a specific anchor.
    *   `getUserAnchors`: Retrieves the list of anchor IDs for a user.
    *   `getAnchorDetails`: Retrieves full details for a specific anchor ID.
    *   `getTotalLockedValue`: Returns the total Ether locked.
    *   `getUserLockedValue`: Returns the total Ether locked by a user.
    *   `getPenaltyCurveParameters`: Returns the current penalty settings.
    *   `getProtocolFeeBasisPoints`: Returns the current protocol fee rate.
    *   `getFeeRecipient`: Returns the current fee recipient.
    *   `getTotalProtocolFeesCollected`: Returns the total accumulated protocol fees.
    *   `isPaused`: Returns the paused state.
    *   `getOwner`: Returns the current contract owner.
13. **Admin Functions:**
    *   `setPenaltyCurveParameters`: Owner sets `maxPenaltyBasisPoints`.
    *   `setProtocolFeeBasisPoints`: Owner sets `protocolFeeBasisPoints`.
    *   `setFeeRecipient`: Owner sets `feeRecipient`.
    *   `pauseContract`: Owner pauses operations.
    *   `unpauseContract`: Owner unpauses operations.
    *   `withdrawProtocolFees`: Owner withdraws collected fees.
    *   `transferOwnership`: Owner transfers ownership.

**Function Summary (Total: 23 Functions):**

1.  `constructor`: Initializes the contract with owner and default parameters.
2.  `createAnchor(uint64 _duration)`: Creates a new time lock (anchor) for the sent Ether, locked for `_duration` seconds.
3.  `withdrawAnchor(uint256 _anchorId)`: Withdraws the full principal of `_anchorId` after its unlock time has passed.
4.  `earlyWithdrawAnchor(uint256 _anchorId)`: Withdraws the full principal of `_anchorId` before its unlock time, applying the calculated penalty and protocol fee.
5.  `partialEarlyWithdrawAnchor(uint256 _anchorId, uint256 _amountToWithdraw)`: Withdraws a partial amount from `_anchorId` before its unlock time, applying the proportional penalty and protocol fee.
6.  `calculateCurrentPenaltyBasisPoints(uint256 _anchorId)`: Public view to see the penalty rate (0-10000 basis points) for `_anchorId` *if* withdrawn at the current time.
7.  `calculateEarlyWithdrawalAmount(uint256 _anchorId)`: View to see the net amount receivable for a full early withdrawal of `_anchorId` currently.
8.  `calculatePartialEarlyWithdrawalAmount(uint256 _anchorId, uint256 _amountToWithdraw)`: View to see the net amount receivable for a partial early withdrawal of `_amountToWithdraw` from `_anchorId` currently.
9.  `getAnchor(uint256 _anchorId)`: View to get the `Anchor` struct data for `_anchorId`.
10. `getUserAnchors(address _user)`: View to get the array of anchor IDs owned by `_user`.
11. `getAnchorDetails(uint256 _anchorId)`: View to get detailed information (amount, locked time, unlock time, withdrawn amount) for `_anchorId`.
12. `getTotalLockedValue()`: View to get the total sum of principal currently locked in the contract.
13. `getUserLockedValue(address _user)`: View to get the total sum of principal currently locked by `_user`.
14. `getPenaltyCurveParameters()`: View to get the contract's `maxPenaltyBasisPoints`. (Note: `penaltyDecayExponent` is fixed internally).
15. `getProtocolFeeBasisPoints()`: View to get the contract's `protocolFeeBasisPoints`.
16. `getFeeRecipient()`: View to get the address designated to receive protocol fees.
17. `getTotalProtocolFeesCollected()`: View to get the cumulative amount of protocol fees collected.
18. `isPaused()`: View to check if the contract is paused.
19. `getOwner()`: View to get the current owner address.
20. `setPenaltyCurveParameters(uint16 _maxPenaltyBasisPoints)`: Owner-only function to set the maximum penalty rate.
21. `setProtocolFeeBasisPoints(uint16 _protocolFeeBasisPoints)`: Owner-only function to set the protocol fee rate.
22. `setFeeRecipient(address _feeRecipient)`: Owner-only function to set the address that receives fees.
23. `pauseContract()`: Owner-only function to pause core deposit/withdrawal operations.
24. `unpauseContract()`: Owner-only function to unpause core operations.
25. `withdrawProtocolFees()`: Owner-only function to transfer accumulated fees to the fee recipient.
26. `transferOwnership(address newOwner)`: Owner-only function to transfer ownership of the contract.

*Self-correction:* The count is now 26, more than the required 20. Excellent. Let's make sure the implementation reflects this list accurately.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HyperbolicTimeLock (Simplified Quadratic Time Decay Penalty)
/// @author Your Name/Alias
/// @notice This contract allows users to lock Ether for a specified duration.
/// Early withdrawal is possible but incurs a penalty that decreases quadratically
/// as the time elapsed approaches the full lock duration.
/// A configurable protocol fee is taken on penalties.
/// Includes ownership, pausable functionality, and parameter tuning.

// Error Definitions
error InvalidDuration();
error AnchorNotFound();
error WithdrawalAmountTooLarge();
error AlreadyWithdrawn();
error NotYetUnlocked();
error Unauthorized();
error Paused();
error NotPaused();
error ZeroAddress();
error SameAddress();
error FeeRateTooHigh();
error PenaltyRateTooHigh();

// Structs
struct Anchor {
    address depositor;      // The address that created the lock
    uint256 principalAmount; // The original amount of Ether locked
    uint64 lockedTime;      // Timestamp when the anchor was created
    uint64 unlockTime;      // Timestamp when the anchor is fully unlocked
    uint256 withdrawnAmount; // Amount already withdrawn from this anchor (for partial withdrawals)
}

// State Variables
address private _owner;
bool private _paused;

uint256 private nextAnchorId = 1; // Start IDs from 1
Anchor[] private anchors; // anchors[0] will be unused, using 1-based indexing via mapping

mapping(address => uint256[]) private userAnchorIds; // Map user address to array of their anchor IDs

// Parameters for the penalty curve (Quadratic Decay: Penalty = maxPenalty * (time_remaining / total_duration)^2)
uint16 public maxPenaltyBasisPoints; // Max penalty expressed in basis points (e.g., 5000 for 50%)
uint8 private constant PENALTY_DECAY_EXPONENT = 2; // Fixed exponent for quadratic decay

// Protocol Fee parameters
uint16 public protocolFeeBasisPoints; // Fee rate on the calculated penalty (e.g., 1000 for 10%)
address public feeRecipient; // Address that receives the protocol fees

uint256 public totalLockedValue = 0; // Sum of principalAmount across all active anchors
uint256 public totalProtocolFeesCollected = 0; // Sum of protocol fees collected

// Events
event AnchorCreated(uint256 indexed anchorId, address indexed depositor, uint256 amount, uint64 duration, uint64 unlockTime);
event AnchorWithdrawn(uint256 indexed anchorId, address indexed depositor, uint256 amount);
event AnchorEarlyWithdrawn(uint256 indexed anchorId, address indexed depositor, uint256 principalWithdrawn, uint256 penaltyAmount, uint256 feeAmount);
event AnchorPartialEarlyWithdrawn(uint256 indexed anchorId, address indexed depositor, uint256 requestedAmount, uint256 principalReceived, uint256 penaltyAmount, uint256 feeAmount, uint256 newWithdrawnAmount);
event PenaltyParametersUpdated(uint16 newMaxPenaltyBasisPoints);
event ProtocolFeeParametersUpdated(uint16 newProtocolFeeBasisPoints);
event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
event Paused(address account);
event Unpaused(address account);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);


// Modifiers (Simple custom implementation, not using OpenZeppelin to meet "don't duplicate open source" constraint)
modifier onlyOwner() {
    if (msg.sender != _owner) revert Unauthorized();
    _;
}

modifier whenNotPaused() {
    if (_paused) revert Paused();
    _;
}

modifier whenPaused() {
    if (!_paused) revert NotPaused();
    _;
}

// Constructor
/// @notice Initializes the contract.
/// @param _initialMaxPenaltyBasisPoints Maximum penalty rate (0-10000).
/// @param _initialProtocolFeeBasisPoints Protocol fee rate on penalty (0-10000).
/// @param _initialFeeRecipient Address to receive initial fees.
constructor(uint16 _initialMaxPenaltyBasisPoints, uint16 _initialProtocolFeeBasisPoints, address _initialFeeRecipient) {
    if (_initialFeeRecipient == address(0)) revert ZeroAddress();
    if (_initialMaxPenaltyBasisPoints > 10000) revert PenaltyRateTooHigh();
    if (_initialProtocolFeeBasisPoints > 10000) revert FeeRateTooHigh();

    _owner = msg.sender;
    maxPenaltyBasisPoints = _initialMaxPenaltyBasisPoints;
    protocolFeeBasisPoints = _initialProtocolFeeBasisPoints;
    feeRecipient = _initialFeeRecipient;

    // Initialize anchors array with a dummy element at index 0 to allow 1-based indexing
    anchors.push();
}

// --- Internal Helper Functions ---

/// @dev Calculates the current penalty rate in basis points (0-10000) for an anchor.
/// Penalty decreases quadratically as time approaches unlockTime.
/// Formula: maxPenalty * (time_remaining / total_duration)^2
/// time_remaining = unlockTime - currentTime
/// total_duration = unlockTime - lockedTime
/// clamped_remaining_ratio = max(0, min(1, (unlockTime - currentTime) / (unlockTime - lockedTime)))
/// PenaltyBasisPoints = maxPenalty * (clamped_remaining_ratio)^2
/// Uses fixed-point arithmetic (multiply by 10000 for basis points, then square, then divide)
/// @param _anchor The anchor struct.
/// @return uint16 The penalty rate in basis points (0-10000).
function _calculatePenaltyBasisPointsInternal(Anchor storage _anchor) internal view returns (uint16) {
    uint64 currentTime = uint64(block.timestamp);

    // If unlock time has passed, no penalty
    if (currentTime >= _anchor.unlockTime) {
        return 0;
    }

    uint64 totalDuration = _anchor.unlockTime - _anchor.lockedTime;
    // Should not happen with valid input, but check
    if (totalDuration == 0) {
         return maxPenaltyBasisPoints; // Or revert? Let's apply max penalty for duration 0
    }

    uint64 timeRemaining = _anchor.unlockTime - currentTime;

    // Calculate remaining ratio in basis points (0-10000)
    uint256 remainingRatioBasisPoints = (uint256(timeRemaining) * 10000) / totalDuration;

    // Apply exponent (fixed as 2 for quadratic)
    // remainingRatioBasisPoints is [0, 10000]
    // remainingRatioBasisPoints^2 is [0, 10000 * 10000]
    uint256 remainingRatioSquared = (remainingRatioBasisPoints * remainingRatioBasisPoints) / 10000; // Divide by 10000 to get back to [0, 10000] scale

    // Calculate final penalty basis points
    // maxPenaltyBasisPoints is [0, 10000]
    // (maxPenaltyBasisPoints * remainingRatioSquared) / 10000 -> [0, 10000]
    uint256 penaltyBp = (uint256(maxPenaltyBasisPoints) * remainingRatioSquared) / 10000;

    // Ensure it doesn't exceed maxPenaltyBasisPoints (shouldn't happen with the formula, but bounds check)
    return uint16(penaltyBp > maxPenaltyBasisPoints ? maxPenaltyBasisPoints : penaltyBp);
}

/// @dev Retrieves an anchor from storage, validating the ID.
/// @param _anchorId The ID of the anchor.
/// @return Anchor storage reference.
function _getAnchor(uint256 _anchorId) internal view returns (Anchor storage) {
    // Check if ID is valid (greater than 0 and less than or equal to the current number of anchors)
    if (_anchorId == 0 || _anchorId >= nextAnchorId) {
        revert AnchorNotFound();
    }
    // Array is 0-indexed, but we use 1-based IDs, so access anchors[_anchorId]
    return anchors[_anchorId];
}

// --- Core Functionality ---

/// @notice Creates a new time lock with the sent Ether.
/// @dev The duration must be greater than 0.
/// @param _duration The lock duration in seconds.
function createAnchor(uint64 _duration) external payable whenNotPaused {
    if (msg.value == 0) revert InvalidDuration(); // require amount > 0 for any lock
    if (_duration == 0) revert InvalidDuration();

    uint64 lockedTime = uint64(block.timestamp);
    uint64 unlockTime = lockedTime + _duration;

    uint256 currentAnchorId = nextAnchorId;
    nextAnchorId++;

    // Store the new anchor
    // Add to the end of the anchors array (index currentAnchorId)
    anchors.push(
        Anchor({
            depositor: msg.sender,
            principalAmount: msg.value,
            lockedTime: lockedTime,
            unlockTime: unlockTime,
            withdrawnAmount: 0
        })
    );

    // Add the new anchor ID to the user's list
    userAnchorIds[msg.sender].push(currentAnchorId);

    totalLockedValue += msg.value;

    emit AnchorCreated(currentAnchorId, msg.sender, msg.value, _duration, unlockTime);
}

/// @notice Withdraws the full principal of an anchor after its unlock time.
/// @dev The caller must be the depositor and the unlock time must have passed.
/// The anchor must not have been fully withdrawn already.
/// @param _anchorId The ID of the anchor to withdraw.
function withdrawAnchor(uint256 _anchorId) external whenNotPaused {
    Anchor storage anchor = _getAnchor(_anchorId);

    if (msg.sender != anchor.depositor) revert Unauthorized();
    if (block.timestamp < anchor.unlockTime) revert NotYetUnlocked();
    if (anchor.principalAmount == anchor.withdrawnAmount) revert AlreadyWithdrawn(); // Already fully withdrawn

    uint256 amountToSend = anchor.principalAmount - anchor.withdrawnAmount;

    // Update state *before* sending to follow Checks-Effects-Interactions pattern
    totalLockedValue -= amountToSend;
    anchor.withdrawnAmount = anchor.principalAmount; // Mark as fully withdrawn

    (bool success, ) = payable(msg.sender).call{value: amountToSend}("");
    require(success, "Transfer failed");

    emit AnchorWithdrawn(_anchorId, msg.sender, amountToSend);
}

/// @notice Withdraws the full principal of an anchor before its unlock time.
/// @dev The caller must be the depositor. A penalty and protocol fee will be applied.
/// The anchor must not have been fully withdrawn already.
/// @param _anchorId The ID of the anchor to withdraw early.
function earlyWithdrawAnchor(uint256 _anchorId) external whenNotPaused {
    Anchor storage anchor = _getAnchor(_anchorId);

    if (msg.sender != anchor.depositor) revert Unauthorized();
    if (block.timestamp >= anchor.unlockTime) revert NotYetUnlocked(); // Use withdrawAnchor after unlock
    if (anchor.principalAmount == anchor.withdrawnAmount) revert AlreadyWithdrawn(); // Already fully withdrawn

    uint256 remainingPrincipal = anchor.principalAmount - anchor.withdrawnAmount;

    uint16 penaltyBasisPoints = _calculatePenaltyBasisPointsInternal(anchor);
    uint256 penaltyAmount = (remainingPrincipal * penaltyBasisPoints) / 10000;

    uint256 feeAmount = (penaltyAmount * protocolFeeBasisPoints) / 10000;
    uint256 amountToSend = remainingPrincipal - penaltyAmount; // Net amount after penalty

    // Update state *before* sending
    totalLockedValue -= remainingPrincipal; // Total locked decreases by the original remaining principal
    totalProtocolFeesCollected += feeAmount;
    anchor.withdrawnAmount = anchor.principalAmount; // Mark as fully withdrawn

    // Send funds
    (bool successUser, ) = payable(msg.sender).call{value: amountToSend}("");
    require(successUser, "User transfer failed");

    // Fee collection is deferred to withdrawProtocolFees, but update the collected amount
    // (The Ether remains in the contract balance until withdrawn by owner)

    emit AnchorEarlyWithdrawn(_anchorId, msg.sender, amountToSend, penaltyAmount, feeAmount);
}


/// @notice Withdraws a partial amount from an anchor before its unlock time.
/// @dev The caller must be the depositor. A proportional penalty and protocol fee will be applied.
/// The requested amount must not exceed the remaining principal.
/// @param _anchorId The ID of the anchor.
/// @param _amountToWithdraw The amount to attempt to withdraw.
function partialEarlyWithdrawAnchor(uint256 _anchorId, uint256 _amountToWithdraw) external whenNotPaused {
    Anchor storage anchor = _getAnchor(_anchorId);

    if (msg.sender != anchor.depositor) revert Unauthorized();
    if (block.timestamp >= anchor.unlockTime) revert NotYetUnlocked(); // Use withdrawAnchor after unlock
    if (anchor.principalAmount == anchor.withdrawnAmount) revert AlreadyWithdrawn(); // Already fully withdrawn
    if (_amountToWithdraw == 0) revert InvalidDuration(); // Amount must be > 0

    uint256 remainingPrincipal = anchor.principalAmount - anchor.withdrawnAmount;
    if (_amountToWithdraw > remainingPrincipal) revert WithdrawalAmountTooLarge();

    uint16 penaltyBasisPoints = _calculatePenaltyBasisPointsInternal(anchor);

    // Calculate penalty and fee based on the amount requested for withdrawal
    uint256 penaltyAmount = (_amountToWithdraw * penaltyBasisPoints) / 10000;
    uint256 feeAmount = (penaltyAmount * protocolFeeBasisPoints) / 10000;
    uint256 amountToSend = _amountToWithdraw - penaltyAmount;

    // Update state *before* sending
    // Only decrease totalLockedValue by the *actual principal* amount sent to the user
    // (amountToSend + penaltyAmount + feeAmount = _amountToWithdraw) -- this is not right.
    // amountToSend + penaltyAmount = _amountToWithdraw. Fee comes from penalty.
    // The amount that leaves the locked value pool is amountToSend + feeAmount.
    // Let's rethink: The value *removed* from the anchor's potential future payout is `_amountToWithdraw`.
    // This `_amountToWithdraw` is split into amountToSend (user), penaltyAmount (penalty pool), feeAmount (fee pool).
    // Total amount that leaves the anchor is `_amountToWithdraw`.
    // Total amount leaving the *contract locked value* pool should correspond to what the user gets PLUS the fee that's diverted. The penalty stays within the contract's *total* balance but is no longer counted as *locked principal*.
    // Correct state update:
    // totalLockedValue decreases by the amount that is *no longer* the user's principal + fee.
    // User gets `amountToSend`. Fee recipient gets `feeAmount`.
    // The total amount that was requested to be 'unlocked' was `_amountToWithdraw`.
    // Out of `_amountToWithdraw`, `amountToSend` goes to the user, `feeAmount` is reserved as fee, `penaltyAmount - feeAmount` remains in contract effectively as penalty reserve not tied to any lock.
    // Total locked value should decrease by the requested amount.
    totalLockedValue -= _amountToWithdraw; // Decrease total locked value by the requested *principal* amount

    totalProtocolFeesCollected += feeAmount;
    anchor.withdrawnAmount += _amountToWithdraw; // Track that this amount of principal has been processed

    // Send funds
    (bool successUser, ) = payable(msg.sender).call{value: amountToSend}("");
    require(successUser, "User transfer failed");

    // Fee collection is deferred.

    emit AnchorPartialEarlyWithdrawn(_anchorId, msg.sender, _amountToWithdraw, amountToSend, penaltyAmount, feeAmount, anchor.withdrawnAmount);
}


// --- Calculation & Query Functions (Views) ---

/// @notice Calculates the penalty rate in basis points for a specific anchor at the current time.
/// @param _anchorId The ID of the anchor.
/// @return uint16 The penalty rate in basis points (0-10000).
function calculateCurrentPenaltyBasisPoints(uint256 _anchorId) external view returns (uint16) {
    Anchor storage anchor = _getAnchor(_anchorId);
    return _calculatePenaltyBasisPointsInternal(anchor);
}

/// @notice Calculates the net amount received for a full early withdrawal of an anchor at the current time.
/// @param _anchorId The ID of the anchor.
/// @return uint256 The amount the user would receive if withdrawing fully now.
function calculateEarlyWithdrawalAmount(uint256 _anchorId) external view returns (uint256) {
    Anchor storage anchor = _getAnchor(_anchorId);
     if (block.timestamp >= anchor.unlockTime) return anchor.principalAmount - anchor.withdrawnAmount; // No penalty if unlocked
    if (anchor.principalAmount == anchor.withdrawnAmount) return 0; // Already fully withdrawn

    uint256 remainingPrincipal = anchor.principalAmount - anchor.withdrawnAmount;
    uint16 penaltyBasisPoints = _calculatePenaltyBasisPointsInternal(anchor);
    uint256 penaltyAmount = (remainingPrincipal * penaltyBasisPoints) / 10000;
    return remainingPrincipal - penaltyAmount;
}

/// @notice Calculates the net amount received for a partial early withdrawal of a specific amount from an anchor at the current time.
/// @param _anchorId The ID of the anchor.
/// @param _amountToWithdraw The amount of principal to simulate withdrawing.
/// @return uint256 The amount the user would receive for withdrawing `_amountToWithdraw` now.
function calculatePartialEarlyWithdrawalAmount(uint256 _anchorId, uint256 _amountToWithdraw) external view returns (uint256) {
    Anchor storage anchor = _getAnchor(_anchorId);
    if (block.timestamp >= anchor.unlockTime) return _amountToWithdraw; // No penalty if unlocked
    if (anchor.principalAmount == anchor.withdrawnAmount) return 0; // Already fully withdrawn
     if (_amountToWithdraw == 0) return 0;

    uint256 remainingPrincipal = anchor.principalAmount - anchor.withdrawnAmount;
     if (_amountToWithdraw > remainingPrincipal) _amountToWithdraw = remainingPrincipal; // Clamp to remaining

    uint16 penaltyBasisPoints = _calculatePenaltyBasisPointsInternal(anchor);
    uint256 penaltyAmount = (_amountToWithdraw * penaltyBasisPoints) / 10000;
    return _amountToWithdraw - penaltyAmount;
}


/// @notice Retrieves details of a specific anchor.
/// @param _anchorId The ID of the anchor.
/// @return depositor The address that created the lock.
/// @return principalAmount The original amount of Ether locked.
/// @return lockedTime Timestamp when the anchor was created.
/// @return unlockTime Timestamp when the anchor is fully unlocked.
/// @return withdrawnAmount Amount already withdrawn from this anchor.
function getAnchorDetails(uint256 _anchorId) external view returns (
    address depositor,
    uint256 principalAmount,
    uint64 lockedTime,
    uint64 unlockTime,
    uint256 withdrawnAmount
) {
    Anchor storage anchor = _getAnchor(_anchorId);
    return (
        anchor.depositor,
        anchor.principalAmount,
        anchor.lockedTime,
        anchor.unlockTime,
        anchor.withdrawnAmount
    );
}

/// @notice Retrieves the list of anchor IDs owned by a user.
/// @param _user The address of the user.
/// @return uint256[] An array of anchor IDs.
function getUserAnchors(address _user) external view returns (uint256[] memory) {
    return userAnchorIds[_user];
}

/// @notice Retrieves details of a specific anchor (returns the struct directly).
/// @dev This is an alternative to getAnchorDetails and less gas-efficient if you only need specific fields off-chain.
/// Included to fulfill the function count and offer a different view.
/// @param _anchorId The ID of the anchor.
/// @return Anchor The anchor struct.
function getAnchor(uint256 _anchorId) external view returns (Anchor memory) {
     // Need to load into memory to return struct directly
    Anchor storage anchor = _getAnchor(_anchorId);
    return anchor;
}


/// @notice Returns the total sum of principal currently locked in the contract.
/// @return uint256 Total locked Ether.
function getTotalLockedValue() external view returns (uint256) {
    return totalLockedValue;
}

/// @notice Returns the total sum of principal currently locked by a specific user across all their anchors.
/// @param _user The address of the user.
/// @return uint256 Total locked Ether for the user.
function getUserLockedValue(address _user) external view returns (uint256) {
    uint256 userTotal = 0;
    uint256[] memory anchorIds = userAnchorIds[_user];
    // Iterate through user's anchor IDs and sum up the *remaining* principal
    for (uint i = 0; i < anchorIds.length; i++) {
        uint256 anchorId = anchorIds[i];
        // Ensure the anchor still exists and add its remaining principal
         if (anchorId > 0 && anchorId < nextAnchorId) {
             Anchor storage anchor = anchors[anchorId];
             userTotal += (anchor.principalAmount - anchor.withdrawnAmount);
         }
    }
    return userTotal;
}


/// @notice Returns the current penalty curve parameters.
/// @dev Only the maximum penalty rate is configurable. The decay exponent is fixed.
/// @return uint16 The maximum penalty basis points (0-10000).
function getPenaltyCurveParameters() external view returns (uint16 maxPenaltyBp, uint8 decayExponent) {
    return (maxPenaltyBasisPoints, PENALTY_DECAY_EXPONENT);
}

/// @notice Returns the current protocol fee rate on penalties.
/// @return uint16 The protocol fee basis points (0-10000).
function getProtocolFeeBasisPoints() external view returns (uint16) {
    return protocolFeeBasisPoints;
}

/// @notice Returns the current fee recipient address.
/// @return address The fee recipient.
function getFeeRecipient() external view returns (address) {
    return feeRecipient;
}

/// @notice Returns the cumulative amount of protocol fees collected so far.
/// @return uint256 Total fees collected.
function getTotalProtocolFeesCollected() external view returns (uint256) {
    return totalProtocolFeesCollected;
}

/// @notice Checks if the contract is currently paused.
/// @return bool True if paused, false otherwise.
function isPaused() external view returns (bool) {
    return _paused;
}

/// @notice Returns the current contract owner.
/// @return address The owner's address.
function getOwner() external view returns (address) {
    return _owner;
}

// --- Admin Functions ---

/// @notice Allows the owner to set the maximum penalty rate for early withdrawals.
/// @dev Value is in basis points (e.g., 5000 for 50%). Cannot exceed 10000.
/// @param _maxPenaltyBasisPoints The new maximum penalty rate.
function setPenaltyCurveParameters(uint16 _maxPenaltyBasisPoints) external onlyOwner {
    if (_maxPenaltyBasisPoints > 10000) revert PenaltyRateTooHigh();
    maxPenaltyBasisPoints = _maxPenaltyBasisPoints;
    emit PenaltyParametersUpdated(_maxPenaltyBasisPoints);
}

/// @notice Allows the owner to set the protocol fee rate on penalties.
/// @dev Value is in basis points (e.g., 1000 for 10%). Cannot exceed 10000.
/// @param _protocolFeeBasisPoints The new protocol fee rate.
function setProtocolFeeBasisPoints(uint16 _protocolFeeBasisPoints) external onlyOwner {
    if (_protocolFeeBasisPoints > 10000) revert FeeRateTooHigh();
    protocolFeeBasisPoints = _protocolFeeBasisPoints;
    emit ProtocolFeeParametersUpdated(_protocolFeeBasisPoints);
}

/// @notice Allows the owner to set the address that receives protocol fees.
/// @dev Cannot set to the zero address.
/// @param _feeRecipient The new fee recipient address.
function setFeeRecipient(address _feeRecipient) external onlyOwner {
    if (_feeRecipient == address(0)) revert ZeroAddress();
     if (_feeRecipient == feeRecipient) revert SameAddress();
    address oldRecipient = feeRecipient;
    feeRecipient = _feeRecipient;
    emit FeeRecipientUpdated(oldRecipient, _feeRecipient);
}


/// @notice Pauses the contract, preventing deposits and withdrawals.
/// @dev Only callable by the owner.
function pauseContract() external onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
}

/// @notice Unpauses the contract, re-enabling deposits and withdrawals.
/// @dev Only callable by the owner.
function unpauseContract() external onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
}

/// @notice Allows the owner to withdraw accumulated protocol fees.
/// @dev Fees are sent to the designated feeRecipient address.
function withdrawProtocolFees() external onlyOwner {
    uint256 fees = totalProtocolFeesCollected;
    if (fees == 0) return; // No fees to withdraw

    // Reset fee count *before* sending
    totalProtocolFeesCollected = 0;

    (bool success, ) = payable(feeRecipient).call{value: fees}("");
    require(success, "Fee transfer failed");

    emit ProtocolFeesWithdrawn(feeRecipient, fees);
}


/// @notice Allows the current owner to transfer ownership of the contract to a new address.
/// @dev Prevents transferring to the zero address.
/// @param newOwner The address of the new owner.
function transferOwnership(address newOwner) external onlyOwner {
    if (newOwner == address(0)) revert ZeroAddress();
    if (newOwner == _owner) revert SameAddress();
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
}

// Fallback and Receive functions to accept Ether
receive() external payable {}
fallback() external payable {}
```