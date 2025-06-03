Okay, let's design a smart contract that combines a few interesting concepts: multi-asset locking (ETH, ERC20, ERC721), time-based conditions, and an external "observation" trigger that simulates a measurement influencing the unlock state. We'll call it `QuantumLock`.

It's not a standard escrow or time lock because it requires *both* time elapsed *and* a specific "observation" event to potentially unlock, adding a layer of conditional release beyond simple time.

---

**Outline and Function Summary**

**Contract Name:** `QuantumLock`

**Description:** A smart contract that allows creators to lock Ether, a single specified ERC20 token, and a single specified ERC721 token for a recipient. The release of locked assets is conditional upon *both* a specified time elapsed *and* a specific "observation" event being triggered by an authorized observer. This simulates a dependency on an external, observed state change.

**Key Concepts:**
*   **Multi-Asset Locking:** Handles ETH, ERC20, and ERC721 simultaneously within a single lock instance.
*   **Dual Condition Release:** Requires both a minimum time *and* an external 'observation' flag to be set to enable unlocking.
*   **Dynamic States:** Locks transition through different states (Pending, Active, Unlocking, Expired, Claimed, Cancelled) based on time, funding, observation, and actions.
*   **Observer Pattern:** An authorized role (`Observer`) can trigger the 'observation' event, influencing lock states.
*   **Protocol Fees:** Allows collecting a small fee on asset claims or reversions.

**Enums & Structs:**
*   `LockState`: Defines the possible states of a lock.
*   `Lock`: Struct holding all details for a single lock instance (creator, recipient, assets, times, conditions, state, etc.).

**State Variables:**
*   `_lockCounter`: Counter for generating unique lock IDs.
*   `_locks`: Mapping from lock ID to `Lock` struct.
*   `_observers`: Mapping to track authorized observer addresses.
*   `_erc20Token`: Address of the approved ERC20 token.
*   `_erc721Token`: Address of the approved ERC721 token.
*   `_feeAddress`: Address receiving protocol fees.
*   `_protocolFeeBps`: Protocol fee percentage in basis points.
*   `_totalFeesCollectedETH`, `_totalFeesCollectedERC20`: Accumulated fees.

**Events:**
*   `LockCreated`: Emitted when a new lock is defined.
*   `LockFunded`: Emitted when ETH, ERC20, or ERC721 is added to a lock.
*   `ObservationMade`: Emitted when an authorized observer calls the observation function.
*   `LockStateChanged`: Emitted when a lock's state transitions.
*   `LockClaimed`: Emitted when a recipient successfully claims assets.
*   `FeesWithdrawn`: Emitted when owner withdraws fees.
*   `LockCancelled`: Emitted when a pending lock is cancelled.
*   `LockExpired`: Emitted when a lock transitions to the Expired state.
*   `LockReverted`: Emitted when assets from an expired lock are reverted.

**Errors:** Custom errors for specific failure conditions (e.g., `InvalidState`, `Unauthorized`, `LockNotFound`, `InsufficientFunds`, `ConditionNotMet`, `InvalidAddress`, `TokenNotApproved`, `InvalidFee`, `AlreadyFunded`, `NotExpired`, `PendingLocksExist`).

**Functions (26 functions):**

1.  `constructor()`: Initializes the contract owner and optionally sets initial approved tokens or fee details.
2.  `setERC20Token(address tokenAddress)`: Owner sets the single approved ERC20 token address.
3.  `setERC721Token(address tokenAddress)`: Owner sets the single approved ERC721 token address.
4.  `addObserver(address observerAddress)`: Owner adds an address to the list of authorized observers.
5.  `removeObserver(address observerAddress)`: Owner removes an address from the list of authorized observers.
6.  `setFeeAddress(address feeAddress)`: Owner sets the address where fees are sent.
7.  `setProtocolFeeBps(uint16 feeBps)`: Owner sets the protocol fee percentage (in basis points, max 10000).
8.  `createLock(address recipient, uint64 startTime, uint64 endTime, bool observationRequired, uint256 ethAmount, uint256 erc20Amount, uint256 erc721Id)`: Creator defines the parameters of a new lock. Creates a lock ID and sets state to `Pending`. Assets are specified but not transferred here.
9.  `fundLockETH(uint256 lockId) payable`: Creator sends ETH to a `Pending` lock. Transitions state if all asset funding conditions are met.
10. `fundLockERC20(uint256 lockId, uint256 amount)`: Creator transfers ERC20 to a `Pending` lock. Requires prior approval. Transitions state if all asset funding conditions are met.
11. `fundLockERC721(uint256 lockId, uint256 tokenId)`: Creator transfers ERC721 to a `Pending` lock. Requires prior approval. Transitions state if all asset funding conditions are met.
12. `cancelLockPending(uint256 lockId)`: Creator cancels an unfunded `Pending` lock.
13. `observeAndAttemptUnlock(uint256 lockId)`: Authorized observer calls this for a specific lock. Sets the `observationStatus` for that lock to true. *Also* attempts to advance the lock state.
14. `calculateCurrentState(uint256 lockId)`: (View) Calculates and returns the *current potential state* of a lock based on time, funding, and observation status, without changing the stored state.
15. `checkLockState(uint256 lockId)`: (View) Returns the stored state of a lock.
16. `claimLock(uint256 lockId)`: Recipient attempts to claim assets. Requires lock state to be `Unlocking` or `Expired` (with penalty calculation). Transfers assets and transitions state to `Claimed`.
17. `expireLock(uint256 lockId)`: Anyone can call after `endTime`. If state is `Active` or `Unlocking` and conditions haven't led to `Claimed`, transitions state to `Expired`.
18. `revertExpiredLock(uint256 lockId)`: Creator attempts to revert assets from an `Expired` lock. Transfers assets (potentially minus penalty/fees) back to creator. Transitions state to `Reverted`.
19. `getLockDetails(uint256 lockId)`: (View) Returns all configuration details of a lock (recipient, times, required conditions, initial asset amounts, state). Does *not* return current balances.
20. `getLockAssets(uint256 lockId)`: (View) Returns the locked asset amounts and ERC721 ID defined during creation. Does *not* reflect actual current balances if partially funded or claimed.
21. `getLockBalances(uint256 lockId)`: (View) Returns the *actual current* balances of ETH, ERC20, and ERC721 held *by the contract* for a specific lock ID. Requires iterating/checking contract balance. (Note: ERC721 balance check per ID is complex; will simplify to just the configured token ID).
22. `isObserver(address account)`: (View) Checks if an address is an authorized observer.
23. `getApprovedTokens()`: (View) Returns the addresses of the approved ERC20 and ERC721 tokens.
24. `getFeeInfo()`: (View) Returns the fee address and percentage.
25. `getFeesCollected()`: (View) Returns the total collected fees for ETH and ERC20.
26. `withdrawProtocolFees(address tokenAddress)`: Owner withdraws accumulated fees for either ETH (address(0)) or the approved ERC20 token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // Using _msgSender() from Context

// --- Custom Errors ---
error InvalidState(uint256 lockId, LockState currentState, LockState requiredState);
error Unauthorized(address account);
error LockNotFound(uint256 lockId);
error InsufficientFunds(uint256 lockId, string assetType, uint256 requiredAmount, uint256 currentAmount);
error ConditionNotMet(uint256 lockId, string condition);
error InvalidAddress(address account);
error TokenNotApproved(address tokenAddress);
error InvalidFee(uint16 feeBps);
error AlreadyFunded(uint256 lockId);
error NotExpired(uint256 lockId);
error LockNotPending(uint256 lockId);
error ZeroAmount();
error ERC721TransferFailed(uint256 tokenId);
error ETHTransferFailed(address recipient, uint256 amount);
error ERC20TransferFailed(address recipient, uint256 amount);


// --- Enums ---
enum LockState {
    Pending,   // Created, waiting for all assets to be funded
    Active,    // All assets funded, conditions not yet met for unlock
    Unlocking, // Conditions (time + observation) met, waiting for recipient claim
    Expired,   // End time passed, conditions not met, can be reverted or potentially claimed with penalty
    Claimed,   // Recipient has claimed assets
    Cancelled, // Creator cancelled before funding
    Reverted   // Creator reverted assets from an expired lock
}

// --- Structs ---
struct Lock {
    address creator;
    address recipient;
    uint64 startTime; // Timestamp when lock becomes active (optional, usually 0)
    uint64 endTime;   // Timestamp after which conditions might change (e.g., expiry)
    bool observationRequired; // If true, 'observe' must be called
    bool observationStatus;   // Set to true when observe() is called for this lock

    uint256 ethAmount;   // Amount of ETH to be locked
    uint256 erc20Amount; // Amount of ERC20 to be locked
    uint256 erc721Id;    // ID of ERC721 token to be locked

    LockState state;
    uint256 fundedETH;   // Actual ETH received for this lock
    uint256 fundedERC20; // Actual ERC20 received for this lock
    bool fundedERC721;   // True if ERC721 received for this lock
}

contract QuantumLock is Ownable, ReentrancyGuard, ERC721Holder {

    // --- State Variables ---
    uint256 private _lockCounter;
    mapping(uint256 => Lock) private _locks;

    mapping(address => bool) private _observers;

    address private _erc20Token;
    address private _erc721Token;

    address private _feeAddress;
    uint16 private _protocolFeeBps; // Basis points (e.g., 100 = 1%)

    uint256 private _totalFeesCollectedETH;
    uint256 private _totalFeesCollectedERC20; // For the approved token

    // --- Events ---
    event LockCreated(uint256 indexed lockId, address indexed creator, address indexed recipient, Lock parameters);
    event LockFunded(uint256 indexed lockId, address indexed funder, string assetType, uint256 amountOrId);
    event ObservationMade(uint256 indexed lockId, address indexed observer);
    event LockStateChanged(uint256 indexed lockId, LockState oldState, LockState newState);
    event LockClaimed(uint256 indexed lockId, address indexed recipient, uint256 ethAmount, uint256 erc20Amount, uint256 erc721Id, uint256 feeETH, uint256 feeERC20);
    event FeesWithdrawn(address indexed owner, address indexed token, uint256 amount);
    event LockCancelled(uint256 indexed lockId, address indexed creator);
    event LockExpired(uint256 indexed lockId);
    event LockReverted(uint256 indexed lockId, address indexed creator, uint256 ethAmount, uint256 erc20Amount, uint256 erc721Id, uint256 feeETH, uint256 feeERC20);


    // --- Modifiers ---
    modifier onlyObserver() {
        if (!_observers[_msgSender()]) {
            revert Unauthorized(_msgSender());
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialFeeAddress, uint16 initialFeeBps) Ownable(_msgSender()) {
        if (initialFeeAddress == address(0)) revert InvalidAddress(address(0));
        if (initialFeeBps > 10000) revert InvalidFee(initialFeeBps); // Max 100%
        _feeAddress = initialFeeAddress;
        _protocolFeeBps = initialFeeBps;
        _lockCounter = 0;
    }

    // --- Configuration Functions (Owner Only) ---

    /**
     * @notice Sets the single approved ERC20 token address for locking.
     * @param tokenAddress The address of the ERC20 token.
     */
    function setERC20Token(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidAddress(address(0));
        _erc20Token = tokenAddress;
        // Consider adding an event here
    }

    /**
     * @notice Sets the single approved ERC721 token address for locking.
     * @param tokenAddress The address of the ERC721 token.
     */
    function setERC721Token(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidAddress(address(0));
        _erc721Token = tokenAddress;
        // Consider adding an event here
    }

    /**
     * @notice Adds an address as an authorized observer.
     * @param observerAddress The address to add.
     */
    function addObserver(address observerAddress) external onlyOwner {
        if (observerAddress == address(0)) revert InvalidAddress(address(0));
        _observers[observerAddress] = true;
        // Consider adding an event here
    }

    /**
     * @notice Removes an address as an authorized observer.
     * @param observerAddress The address to remove.
     */
    function removeObserver(address observerAddress) external onlyOwner {
        if (observerAddress == address(0)) revert InvalidAddress(address(0));
        _observers[observerAddress] = false;
        // Consider adding an event here
    }

    /**
     * @notice Sets the address where protocol fees are collected.
     * @param feeAddress The address to receive fees.
     */
    function setFeeAddress(address feeAddress) external onlyOwner {
         if (feeAddress == address(0)) revert InvalidAddress(address(0));
        _feeAddress = feeAddress;
        // Consider adding an event here
    }

    /**
     * @notice Sets the protocol fee percentage in basis points.
     * @param feeBps The fee percentage (max 10000).
     */
    function setProtocolFeeBps(uint16 feeBps) external onlyOwner {
        if (feeBps > 10000) revert InvalidFee(feeBps);
        _protocolFeeBps = feeBps;
        // Consider adding an event here
    }

    // --- Lock Creation & Funding ---

    /**
     * @notice Defines the parameters for a new conditional lock.
     *         Assets specified here are not transferred until fund functions are called.
     * @param recipient The address to receive assets upon unlock.
     * @param startTime The timestamp when the lock becomes potentially active (0 for immediate).
     * @param endTime The timestamp after which the lock state might change (e.g., expire).
     * @param observationRequired True if an observation event is needed for unlock.
     * @param ethAmount The amount of ETH intended for this lock.
     * @param erc20Amount The amount of approved ERC20 intended for this lock.
     * @param erc721Id The ID of the approved ERC721 token intended for this lock (0 if not locking ERC721).
     * @return lockId The unique ID of the created lock.
     */
    function createLock(
        address recipient,
        uint64 startTime,
        uint64 endTime,
        bool observationRequired,
        uint256 ethAmount,
        uint256 erc20Amount,
        uint256 erc721Id
    ) external nonReentrant returns (uint256 lockId) {
        if (recipient == address(0)) revert InvalidAddress(address(0));
        if (endTime <= startTime) revert ConditionNotMet(0, "endTime must be after startTime"); // Use 0 for new lock

        // Check if *any* asset is being locked
        if (ethAmount == 0 && erc20Amount == 0 && erc721Id == 0) revert ZeroAmount();
        // Check if ERC20/ERC721 addresses are set if amounts > 0
        if (erc20Amount > 0 && _erc20Token == address(0)) revert TokenNotApproved(address(0));
        if (erc721Id > 0 && _erc721Token == address(0)) revert TokenNotApproved(address(0));


        lockId = ++_lockCounter; // Pre-increment to start IDs from 1

        _locks[lockId] = Lock({
            creator: _msgSender(),
            recipient: recipient,
            startTime: startTime,
            endTime: endTime,
            observationRequired: observationRequired,
            observationStatus: false, // Initially not observed
            ethAmount: ethAmount,
            erc20Amount: erc20Amount,
            erc721Id: erc721Id,
            state: LockState.Pending,
            fundedETH: 0,
            fundedERC20: 0,
            fundedERC721: false
        });

        emit LockCreated(lockId, _msgSender(), recipient, _locks[lockId]);

        return lockId;
    }

    /**
     * @notice Funds a pending lock with ETH.
     * @param lockId The ID of the lock to fund.
     */
    function fundLockETH(uint256 lockId) external payable nonReentrant {
        Lock storage lock = _getLock(lockId);
        if (lock.state != LockState.Pending) revert InvalidState(lockId, lock.state, LockState.Pending);
        if (lock.creator != _msgSender()) revert Unauthorized(_msgSender());
        if (msg.value == 0) revert ZeroAmount();
        if (lock.ethAmount == 0) revert AlreadyFunded(lockId); // ETH amount was set to 0 in createLock

        lock.fundedETH += msg.value;
        emit LockFunded(lockId, _msgSender(), "ETH", msg.value);

        _attemptStateAdvance(lockId); // Attempt to move to Active if all funded
    }

    /**
     * @notice Funds a pending lock with the approved ERC20 token.
     *         Requires prior approval of the token amount to this contract.
     * @param lockId The ID of the lock to fund.
     * @param amount The amount of ERC20 token to transfer. Must match the required amount.
     */
    function fundLockERC20(uint256 lockId, uint256 amount) external nonReentrant {
        Lock storage lock = _getLock(lockId);
        if (lock.state != LockState.Pending) revert InvalidState(lockId, lock.state, LockState.Pending);
        if (lock.creator != _msgSender()) revert Unauthorized(_msgSender());
         if (_erc20Token == address(0)) revert TokenNotApproved(address(0));
        if (amount == 0) revert ZeroAmount();
        if (lock.erc20Amount == 0) revert AlreadyFunded(lockId); // ERC20 amount was set to 0 in createLock
        if (lock.fundedERC20 > 0) revert AlreadyFunded(lockId); // Only fund ERC20 once

        if (amount != lock.erc20Amount) revert InsufficientFunds(lockId, "ERC20", lock.erc20Amount, amount); // Must fund the exact required amount at once

        lock.fundedERC20 = amount;

        // Transfer token
        bool success = IERC20(_erc20Token).transferFrom(_msgSender(), address(this), amount);
        if (!success) revert ERC20TransferFailed(address(this), amount);

        emit LockFunded(lockId, _msgSender(), "ERC20", amount);

        _attemptStateAdvance(lockId); // Attempt to move to Active if all funded
    }

    /**
     * @notice Funds a pending lock with the approved ERC721 token.
     *         Requires prior approval of the token to this contract.
     * @param lockId The ID of the lock to fund.
     * @param tokenId The ID of the ERC721 token to transfer. Must match the required ID.
     */
    function fundLockERC721(uint256 lockId, uint256 tokenId) external nonReentrant {
        Lock storage lock = _getLock(lockId);
        if (lock.state != LockState.Pending) revert InvalidState(lockId, lock.state, LockState.Pending);
        if (lock.creator != _msgSender()) revert Unauthorized(_msgSender());
        if (_erc721Token == address(0)) revert TokenNotApproved(address(0));
        if (lock.erc721Id == 0) revert AlreadyFunded(lockId); // ERC721 ID was set to 0 in createLock
        if (lock.fundedERC721) revert AlreadyFunded(lockId); // Only fund ERC721 once

        if (tokenId != lock.erc721Id) revert ConditionNotMet(lockId, "Incorrect ERC721 ID");

        lock.fundedERC721 = true;

        // Transfer token
        IERC721(_erc721Token).safeTransferFrom(_msgSender(), address(this), tokenId);

        emit LockFunded(lockId, _msgSender(), "ERC721", tokenId);

        _attemptStateAdvance(lockId); // Attempt to move to Active if all funded
    }

    /**
     * @notice Allows the creator to cancel a lock that is still in the Pending state (unfunded).
     * @param lockId The ID of the lock to cancel.
     */
    function cancelLockPending(uint256 lockId) external nonReentrant {
        Lock storage lock = _getLock(lockId);
        if (lock.state != LockState.Pending) revert LockNotPending(lockId);
        if (lock.creator != _msgSender()) revert Unauthorized(_msgSender());

        LockState oldState = lock.state;
        lock.state = LockState.Cancelled;
        emit LockStateChanged(lockId, oldState, lock.state);
        emit LockCancelled(lockId, _msgSender());

        // Note: No assets to transfer back as it was cancelled before funding
    }


    // --- State Manipulation & Observation ---

     /**
      * @notice Called by an authorized observer to make an observation for a specific lock.
      *         This sets the observationStatus flag to true and attempts to advance the lock state.
      * @param lockId The ID of the lock to observe.
      */
    function observeAndAttemptUnlock(uint256 lockId) external onlyObserver nonReentrant {
        Lock storage lock = _getLock(lockId);
         // Can only observe if the lock requires observation and is not yet observed or finished
        if (!lock.observationRequired || lock.observationStatus) {
             revert ConditionNotMet(lockId, "Observation not required or already made");
        }
         // Must be in a state where observation matters (e.g., Active, not Pending, Expired, Claimed, Cancelled, Reverted)
        if (lock.state != LockState.Active && lock.state != LockState.Unlocking) {
             revert InvalidState(lockId, lock.state, LockState.Active); // Or relevant states
        }

        lock.observationStatus = true;
        emit ObservationMade(lockId, _msgSender());

        _attemptStateAdvance(lockId); // Attempt to move state based on observation and time
    }

     /**
      * @notice Calculates the potential current state of a lock based on current conditions.
      *         Does NOT change the stored state. Useful for checking before interacting.
      * @param lockId The ID of the lock.
      * @return The calculated potential LockState.
      */
    function calculateCurrentState(uint256 lockId) public view returns (LockState) {
        Lock storage lock = _getLock(lockId); // Use storage for efficiency in view
        uint64 currentTime = uint64(block.timestamp);

        // Final states are terminal
        if (lock.state == LockState.Claimed ||
            lock.state == LockState.Cancelled ||
            lock.state == LockState.Reverted) {
            return lock.state;
        }

        // If Pending and not fully funded, it's still pending
        if (lock.state == LockState.Pending && !_isFullyFunded(lock)) {
            return LockState.Pending;
        }

        // If Pending but fully funded, it should be Active (this check helps external callers)
         if (lock.state == LockState.Pending && _isFullyFunded(lock)) {
             return LockState.Active;
         }

        // From Active or Unlocking...
        if (lock.state == LockState.Active || lock.state == LockState.Unlocking) {
            bool timeConditionMet = currentTime >= lock.endTime; // Using endTime as the primary time trigger
            bool observationConditionMet = !lock.observationRequired || lock.observationStatus;

            if (timeConditionMet && observationConditionMet) {
                return LockState.Unlocking; // Ready to be claimed
            } else if (currentTime >= lock.endTime) {
                 // If endTime is past but conditions not met, it's expired
                 return LockState.Expired;
             } else {
                return LockState.Active; // Not yet meeting unlock conditions, but funded
            }
        }

        // If Expired, it remains Expired until Reverted or potentially Claimed (with penalty)
        if (lock.state == LockState.Expired) {
            return LockState.Expired;
        }

        // Should not reach here for a valid lock ID, but as a fallback
        return lock.state;
    }

    /**
     * @notice Gets the current stored state of a lock.
     * @param lockId The ID of the lock.
     * @return The current LockState.
     */
    function checkLockState(uint256 lockId) external view returns (LockState) {
        return _getLock(lockId).state;
    }


    // --- Claiming & Reversion ---

    /**
     * @notice Allows the recipient to claim the locked assets.
     *         Requires the lock state to be Unlocking or potentially Expired (with penalty).
     * @param lockId The ID of the lock to claim.
     */
    function claimLock(uint256 lockId) external nonReentrant {
        Lock storage lock = _getLock(lockId);
        if (lock.recipient != _msgSender()) revert Unauthorized(_msgSender()); // Only recipient can claim

        // Check calculated state, not just stored state, to allow claiming immediately after conditions met/expired
        LockState potentialState = calculateCurrentState(lockId);

        if (potentialState != LockState.Unlocking && potentialState != LockState.Expired) {
            revert ConditionNotMet(lockId, "Lock is not ready to be claimed or is expired");
        }

        uint256 ethAmount = lock.fundedETH;
        uint256 erc20Amount = lock.fundedERC20;
        uint256 erc721Id = lock.erc721Id; // Claim the originally specified ID
        bool fundedERC721 = lock.fundedERC721;

        uint256 ethFee = 0;
        uint256 erc20Fee = 0;

        // Apply penalty if claiming from Expired state
        if (potentialState == LockState.Expired) {
             // Example penalty: X% fee if claimed after expiry
            if (ethAmount > 0) ethFee = _calculateFee(ethAmount);
            if (erc20Amount > 0) erc20Fee = _calculateFee(erc20Amount);

            ethAmount -= ethFee;
            erc20Amount -= erc20Fee;

            // Accumulate fees
            _totalFeesCollectedETH += ethFee;
            _totalFeesCollectedERC20 += erc20Fee;
        }

        // Transfer assets (excluding fees)
        _transferAssets(lock.recipient, ethAmount, erc20Amount, fundedERC721 ? erc721Id : 0, _erc20Token, _erc721Token);

        // Update state
        LockState oldState = lock.state;
        lock.state = LockState.Claimed;
        emit LockStateChanged(lockId, oldState, lock.state);
        emit LockClaimed(lockId, _msgSender(), ethAmount, erc20Amount, fundedERC721 ? erc721Id : 0, ethFee, erc20Fee);

        // If there are fees, transfer them to the fee address
        if ((ethFee > 0 || erc20Fee > 0) && _feeAddress != address(0)) {
            if (ethFee > 0) {
                (bool successETH, ) = payable(_feeAddress).call{value: ethFee}("");
                if (!successETH) emit ETHTransferFailed(_feeAddress, ethFee); // Emit error but don't revert claim
            }
             if (erc20Fee > 0) {
                bool successERC20 = IERC20(_erc20Token).transfer(_feeAddress, erc20Fee);
                 if (!successERC20) emit ERC20TransferFailed(_feeAddress, erc20Fee); // Emit error but don't revert claim
            }
        }
    }

    /**
     * @notice Transitions a lock to the Expired state if its endTime has passed and it hasn't been claimed.
     *         Can be called by anyone.
     * @param lockId The ID of the lock.
     */
    function expireLock(uint256 lockId) external nonReentrant {
        Lock storage lock = _getLock(lockId);
        uint64 currentTime = uint64(block.timestamp);

        // Only transition from Active or Unlocking (if not claimed)
        if (lock.state != LockState.Active && lock.state != LockState.Unlocking) {
             revert InvalidState(lockId, lock.state, LockState.Active); // Or Unlocking
        }

        // Check if endTime has passed AND it's not already in a terminal state or Unlocking ready for claim
        LockState potentialState = calculateCurrentState(lockId);
        if (potentialState != LockState.Expired) {
            revert NotExpired(lockId); // Conditions don't currently put it in Expired state
        }

        LockState oldState = lock.state;
        lock.state = LockState.Expired;
        emit LockStateChanged(lockId, oldState, lock.state);
        emit LockExpired(lockId);
    }

    /**
     * @notice Allows the creator to revert assets from an expired lock back to themselves.
     *         May involve a penalty/fee.
     * @param lockId The ID of the lock.
     */
    function revertExpiredLock(uint256 lockId) external nonReentrant {
        Lock storage lock = _getLock(lockId);
        if (lock.creator != _msgSender()) revert Unauthorized(_msgSender()); // Only creator can revert

        // Must be in Expired state
        if (lock.state != LockState.Expired) {
             revert InvalidState(lockId, lock.state, LockState.Expired);
        }

        uint256 ethAmount = lock.fundedETH;
        uint256 erc20Amount = lock.fundedERC20;
        uint256 erc721Id = lock.erc721Id;
        bool fundedERC721 = lock.fundedERC721;


        // Apply penalty (example: different penalty for reversion vs recipient claim)
        // Let's reuse the same fee mechanism for simplicity in this example
        uint256 ethFee = 0;
        uint256 erc20Fee = 0;

        if (ethAmount > 0) ethFee = _calculateFee(ethAmount);
        if (erc20Amount > 0) erc20Fee = _calculateFee(erc20Amount);

        ethAmount -= ethFee;
        erc20Amount -= erc20Fee;

        // Accumulate fees
        _totalFeesCollectedETH += ethFee;
        _totalFeesCollectedERC20 += erc20Fee;

        // Transfer assets (excluding fees) back to creator
        _transferAssets(lock.creator, ethAmount, erc20Amount, fundedERC721 ? erc721Id : 0, _erc20Token, _erc721Token);

        // Update state
        LockState oldState = lock.state;
        lock.state = LockState.Reverted;
        emit LockStateChanged(lockId, oldState, lock.state);
        emit LockReverted(lockId, _msgSender(), ethAmount, erc20Amount, fundedERC721 ? erc721Id : 0, ethFee, erc20Fee);

         // If there are fees, transfer them to the fee address
        if ((ethFee > 0 || erc20Fee > 0) && _feeAddress != address(0)) {
            if (ethFee > 0) {
                (bool successETH, ) = payable(_feeAddress).call{value: ethFee}("");
                 if (!successETH) emit ETHTransferFailed(_feeAddress, ethFee); // Emit error but don't revert claim
            }
             if (erc20Fee > 0) {
                bool successERC20 = IERC20(_erc20Token).transfer(_feeAddress, erc20Fee);
                 if (!successERC20) emit ERC20TransferFailed(_feeAddress, erc20Fee); // Emit error but don't revert claim
            }
        }
    }


    // --- Queries & Information (View Functions) ---

    /**
     * @notice Gets the creation details of a specific lock.
     * @param lockId The ID of the lock.
     * @return Lock struct details.
     */
    function getLockDetails(uint256 lockId) external view returns (Lock memory) {
        return _getLock(lockId);
    }

     /**
      * @notice Gets the *intended* asset amounts specified during lock creation.
      * @param lockId The ID of the lock.
      * @return ethAmount The intended ETH amount.
      * @return erc20Amount The intended ERC20 amount.
      * @return erc721Id The intended ERC721 ID (0 if none).
      */
    function getLockAssets(uint256 lockId) external view returns (uint256 ethAmount, uint256 erc20Amount, uint256 erc721Id) {
        Lock storage lock = _getLock(lockId); // Use storage for efficiency
        return (lock.ethAmount, lock.erc20Amount, lock.erc721Id);
    }

    /**
     * @notice Gets the *actual funded* balances for a specific lock ID held by the contract.
     *         Note: ERC721 check is simplified to just whether the intended ID was funded.
     * @param lockId The ID of the lock.
     * @return fundedETH The actual ETH funded.
     * @return fundedERC20 The actual ERC20 funded.
     * @return fundedERC721 True if the intended ERC721 was funded.
     */
     function getLockBalances(uint256 lockId) external view returns (uint256 fundedETH, uint256 fundedERC20, bool fundedERC721) {
         Lock storage lock = _getLock(lockId);
         return (lock.fundedETH, lock.fundedERC20, lock.fundedERC721);
     }

    /**
     * @notice Checks if an address is currently an authorized observer.
     * @param account The address to check.
     * @return True if the address is an observer, false otherwise.
     */
    function isObserver(address account) external view returns (bool) {
        return _observers[account];
    }

    /**
     * @notice Gets the addresses of the approved ERC20 and ERC721 tokens.
     * @return erc20Token The approved ERC20 token address.
     * @return erc721Token The approved ERC721 token address.
     */
    function getApprovedTokens() external view returns (address erc20Token, address erc721Token) {
        return (_erc20Token, _erc721Token);
    }

    /**
     * @notice Gets the current fee address and percentage.
     * @return feeAddress The address receiving fees.
     * @return protocolFeeBps The fee percentage in basis points.
     */
    function getFeeInfo() external view returns (address feeAddress, uint16 protocolFeeBps) {
        return (_feeAddress, _protocolFeeBps);
    }

    /**
     * @notice Gets the total accumulated fees for ETH and ERC20.
     * @return totalFeesCollectedETH Total collected ETH fees.
     * @return totalFeesCollectedERC20 Total collected ERC20 fees (for the approved token).
     */
     function getFeesCollected() external view returns (uint256 totalFeesCollectedETH, uint256 totalFeesCollectedERC20) {
         return (_totalFeesCollectedETH, _totalFeesCollectedERC20);
     }

    // --- Fee Management (Owner Only) ---

     /**
      * @notice Allows the owner to withdraw collected protocol fees.
      * @param tokenAddress The address of the token to withdraw fees for (address(0) for ETH).
      */
     function withdrawProtocolFees(address tokenAddress) external onlyOwner nonReentrant {
         uint256 amount;
         string memory assetType;

         if (tokenAddress == address(0)) {
             amount = _totalFeesCollectedETH;
             _totalFeesCollectedETH = 0; // Reset balance before transfer
             assetType = "ETH";

             if (amount > 0) {
                 (bool success, ) = payable(_feeAddress).call{value: amount}("");
                 if (!success) {
                     // Revert balance if transfer fails, but emit error
                     _totalFeesCollectedETH = amount;
                     revert ETHTransferFailed(_feeAddress, amount);
                 }
                 emit FeesWithdrawn(_msgSender(), address(0), amount);
             }

         } else if (tokenAddress == _erc20Token && _erc20Token != address(0)) {
             amount = _totalFeesCollectedERC20;
             _totalFeesCollectedERC20 = 0; // Reset balance before transfer
             assetType = "ERC20";

             if (amount > 0) {
                 bool success = IERC20(_erc20Token).transfer(_feeAddress, amount);
                 if (!success) {
                      // Revert balance if transfer fails, but emit error
                     _totalFeesCollectedERC20 = amount;
                     revert ERC20TransferFailed(_feeAddress, amount);
                 }
                 emit FeesWithdrawn(_msgSender(), _erc20Token, amount);
             }

         } else {
              revert TokenNotApproved(tokenAddress); // Cannot withdraw fees for this token
         }

         if (amount == 0) {
             // Consider adding a specific error or event for no fees to withdraw
             // For now, just return without error/event
         }
     }


    // --- Internal/Private Helper Functions ---

    /**
     * @dev Internal function to retrieve a lock and check existence.
     */
    function _getLock(uint256 lockId) internal view returns (Lock storage) {
        if (lockId == 0 || lockId > _lockCounter) {
            revert LockNotFound(lockId);
        }
        return _locks[lockId];
    }

     /**
      * @dev Internal function to check if all specified assets for a lock have been funded.
      */
    function _isFullyFunded(Lock storage lock) internal view returns (bool) {
        if (lock.ethAmount > 0 && lock.fundedETH < lock.ethAmount) return false;
        if (lock.erc20Amount > 0 && lock.fundedERC20 < lock.erc20Amount) return false;
        if (lock.erc721Id > 0 && !lock.fundedERC721) return false;
         // If ethAmount/erc20Amount/erc721Id are 0, they are considered "funded"
        return true;
    }

    /**
     * @dev Internal function to attempt to advance a lock's state based on funding and conditions.
     *      Called after funding or observation.
     */
    function _attemptStateAdvance(uint256 lockId) internal {
        Lock storage lock = _getLock(lockId);
        LockState oldState = lock.state;
        LockState potentialState = calculateCurrentState(lockId);

        // Transition from Pending to Active if fully funded
        if (oldState == LockState.Pending && potentialState == LockState.Active) {
            lock.state = LockState.Active;
            emit LockStateChanged(lockId, oldState, lock.state);
        }
        // Transition from Active to Unlocking if conditions are met
        else if (oldState == LockState.Active && potentialState == LockState.Unlocking) {
             lock.state = LockState.Unlocking;
             emit LockStateChanged(lockId, oldState, lock.state);
        }
        // Transition from Active/Unlocking to Expired if time passes and conditions not fully met
        else if ((oldState == LockState.Active || oldState == LockState.Unlocking) && potentialState == LockState.Expired) {
             lock.state = LockState.Expired;
             emit LockStateChanged(lockId, oldState, lock.state);
             emit LockExpired(lockId); // Also emit Expired event
        }
         // Note: Transitions to Claimed/Reverted are handled directly in claim/revert functions
    }

     /**
      * @dev Internal function to calculate the protocol fee for a given amount.
      */
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        // Avoid division by zero, although _protocolFeeBps is validated
        if (_protocolFeeBps == 0) return 0;
        // Using a fixed point approach: amount * bps / 10000
        // Ensure no overflow if amount is very large
        uint256 fee = (amount * _protocolFeeBps) / 10000;
        // Sanity check: fee should not exceed amount
        return fee > amount ? amount : fee;
    }

    /**
     * @dev Internal function to transfer assets for claiming or reverting.
     */
    function _transferAssets(
        address recipient,
        uint256 ethAmount,
        uint256 erc20Amount,
        uint256 erc721Id, // Use 0 if not transferring ERC721
        address erc20Token, // Pass approved token addresses for clarity
        address erc721Token
    ) internal {
        if (ethAmount > 0) {
            (bool successETH, ) = payable(recipient).call{value: ethAmount}("");
            if (!successETH) emit ETHTransferFailed(recipient, ethAmount); // Emit error but don't revert
        }
        if (erc20Amount > 0 && erc20Token != address(0)) {
             bool successERC20 = IERC20(erc20Token).transfer(recipient, erc20Amount);
             if (!successERC20) emit ERC20TransferFailed(recipient, erc20Amount); // Emit error but don't revert
        }
        if (erc721Id > 0 && erc721Token != address(0)) {
             try IERC721(erc721Token).safeTransferFrom(address(this), recipient, erc771Id) {
                 // Success
             } catch {
                 // ERC721 transfer failed (e.g., recipient not ERC721Receiver, token not owned)
                  emit ERC721TransferFailed(erc721Id); // Emit error but don't revert
             }
        }
    }

    // --- ERC721Holder compatibility ---
    // Necessary to receive ERC721 tokens via safeTransferFrom
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Optional: Add checks here if needed, e.g., only allow transfers for specific lock IDs.
        // However, given the funding functions handle matching the ID, this simple
        // implementation just accepts the transfer. The logic in fundLockERC721
        // ensures the correct token ID is received for the correct lock.
        return this.onERC721Received.selector;
    }

     // --- Receive/Fallback for ETH ---
     // Only allow receiving ETH via fundLockETH
    receive() external payable {
         if (msg.sender != address(this)) { // Allow internal calls (e.g. self calls for ETH transfer)
             // Revert if ETH is sent without calling fundLockETH
             revert Unauthorized(msg.sender);
         }
         // If msg.sender is address(this), it's an internal call, likely from _transferAssets
         // No explicit check on call data as receive() is checked before fallback()
    }

    fallback() external payable {
        // Revert if any other call is made with ETH that's not handled by a function
        revert Unauthorized(msg.sender);
    }
}
```