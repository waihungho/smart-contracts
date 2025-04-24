Okay, here is a Solidity smart contract concept called "QuantumLocker". It simulates some concepts inspired by quantum mechanics (like superposition and collapse) using cryptographic hashes, time-locks, and conditional outcomes. It's designed to be complex and non-standard, incorporating features like conditional asset release based on hidden information, transferable lock rights, gas sponsorship for specific actions, and multiple potential outcomes.

It aims to avoid duplicating simple vesting, escrow, or multi-sig contracts by introducing a unique state-dependent release mechanism based on future events.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLocker
 * @author YourName (or a Placeholder)
 * @dev A novel smart contract simulating 'quantum' states for asset locking.
 * Assets are deposited into a 'superposition' state where their eventual
 * recipient or action is uncertain. This state 'collapses' based on a
 * future event (time or hash reveal), determining one of multiple potential
 * outcomes. The determined outcome is then 'resolved' by transferring assets
 * or performing a defined action. Includes features like transferable lock rights,
 * gas sponsorship for the collapse transaction, and configurable outcomes.
 *
 * Outline:
 * 1. Data Structures: Enums for states, mechanisms, and outcome types; Structs for Outcomes and Locks.
 * 2. State Variables: Mapping for locks, lock counter, owner, supported assets, fee settings.
 * 3. Events: To log key state changes and actions.
 * 4. Modifiers: For access control and state checks.
 * 5. Core Lock Management: Functions to create, collapse, resolve, cancel, and expire locks.
 * 6. State & Info Functions: View functions to retrieve lock details and state.
 * 7. Configuration & Admin: Functions for owner to manage settings, supported assets, fees, and ownership.
 * 8. Advanced Features: Transferring lock rights, setting gas sponsors.
 * 9. Internal Logic: Helper functions for state transitions and outcome execution.
 */

// --- Function Summary ---
// Lock Management:
// 1.  createLock(address asset, uint256 amount, Outcome[] memory outcomes, CollapseMechanism collapseMechanism, bytes32 collapseData, uint64 collapseDeadline, uint64 expirationTime, bool transferableRights, address initialGasSponsor)
//     -   Creates a new lock in 'Superposition' state. Requires asset deposit (ETH or ERC20).
//     -   Defines multiple potential outcomes linked to hashes/values.
//     -   Sets the mechanism (time or hash reveal) and data/deadline for collapse.
//     -   Sets an expiration time after which the lock can be expired.
//     -   Allows making lock rights transferable.
//     -   Sets an optional initial gas sponsor for the collapse transaction.
// 2.  depositETH(Outcome[] memory outcomes, CollapseMechanism collapseMechanism, bytes32 collapseData, uint64 collapseDeadline, uint64 expirationTime, bool transferableRights, address initialGasSponsor) payable
//     -   Specific function to create a lock depositing ETH.
// 3.  depositERC20(address tokenAddress, uint256 amount, Outcome[] memory outcomes, CollapseMechanism collapseMechanism, bytes32 collapseData, uint64 collapseDeadline, uint64 expirationTime, bool transferableRights, address initialGasSponsor)
//     -   Specific function to create a lock depositing ERC20 tokens.
// 4.  collapseLock(uint256 lockId, bytes calldata revealValue)
//     -   Attempts to 'collapse' a lock from 'Superposition'.
//     -   For HashReveal mechanism, requires providing the revealValue (pre-image).
//     -   Validates the collapse condition (time passed or hash matches reveal).
//     -   Determines the winning outcome based on the collapse data/reveal.
//     -   Transitions lock state to 'Collapsed'.
// 5.  resolveLock(uint256 lockId)
//     -   Executes the chosen outcome for a 'Collapsed' lock.
//     -   Transfers assets or performs the defined action.
//     -   Transitions lock state to 'Resolved'.
// 6.  cancelLock(uint256 lockId)
//     -   Allows the original depositor (or owner) to cancel a lock *before* collapse.
//     -   May apply a cancellation penalty fee.
//     -   Returns remaining assets to depositor.
//     -   Transitions lock state to 'Cancelled'.
// 7.  expireLock(uint256 lockId)
//     -   Allows anyone to trigger expiration for a 'Superposition' lock past its expirationTime.
//     -   Applies an expiration penalty fee.
//     -   Returns remaining assets to depositor (or performs a default action).
//     -   Transitions lock state to 'Expired'.

// State & Info Functions (View/Pure):
// 8.  getLockDetails(uint256 lockId) view
//     -   Retrieves all details for a specific lock.
// 9.  getLockState(uint256 lockId) view
//     -   Retrieves the current state of a lock.
// 10. getPossibleOutcomes(uint256 lockId) view
//     -   Retrieves the array of potential outcomes defined for a lock.
// 11. getChosenOutcome(uint256 lockId) view
//     -   Retrieves the details of the outcome selected after collapse.
// 12. getLockExpirationTime(uint256 lockId) view
//     -   Retrieves the expiration timestamp of a lock.
// 13. getLockCollapseTime(uint256 lockId) view
//     -   Retrieves the collapse deadline timestamp for a time-based lock.
// 14. getLockCount() view
//     -   Retrieves the total number of locks created.
// 15. isLockResolvable(uint256 lockId) view
//     -   Checks if a lock is in the 'Collapsed' state and ready to be resolved.

// Configuration & Admin:
// 16. addSupportedAsset(address tokenAddress)
//     -   Owner function to add an ERC20 token to the list of supported assets.
// 17. removeSupportedAsset(address tokenAddress)
//     -   Owner function to remove an ERC20 token from the list of supported assets.
// 18. setFeeSettings(uint256 createFeeETH, uint256 createFeeERC20BasisPoints, uint256 cancelPenaltyBasisPoints, uint256 expirePenaltyBasisPoints, address feeRecipient)
//     -   Owner function to configure various fee parameters.
// 19. withdrawFees(address tokenAddress, uint256 amount)
//     -   Owner function to withdraw collected fees for a specific asset.
// 20. transferOwnership(address newOwner)
//     -   Transfers ownership of the contract.
// 21. renounceOwnership()
//     -   Renounces ownership of the contract.

// Advanced Features:
// 22. transferLockRights(uint256 lockId, address newRightsHolder)
//     -   Allows the current rights holder (original depositor initially, or previous transferee)
//       to transfer the rights associated with a transferable lock *before* collapse.
//       This transfers the ability to potentially cancel or claim in some default scenarios.
// 23. setLockGasSponsor(uint256 lockId, address sponsorAddress)
//     -   Allows the lock's depositor/rights holder to set or change the address designated
//       as the gas sponsor for the `collapseLock` transaction. The sponsor pays the gas.

// Internal Logic:
// 24. _executeOutcome(uint256 lockId, Outcome memory outcome) internal
//     -   Internal helper to perform the action defined by an outcome (transfer, burn).
// 25. _chargeFee(address asset, uint256 amount, uint256 basisPoints, address feeRecipient) internal
//     -   Internal helper to calculate and transfer fee amounts.
// 26. _calculateOutcomeIndex(uint256 lockId, bytes calldata revealValue) internal view
//     -   Internal helper to determine the index of the winning outcome based on collapse logic.

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract QuantumLocker {
    enum LockState {
        Superposition, // Initial state: Outcome uncertain
        Collapsed,     // Outcome determined, ready for resolution
        Resolved,      // Outcome executed, assets moved/burned
        Cancelled,     // Lock cancelled by depositor/owner before collapse
        Expired        // Lock expired due to collapse deadline passed without action
    }

    enum CollapseMechanism {
        Time,        // Collapse happens after a specific timestamp
        HashReveal   // Collapse happens when a pre-image is revealed that matches a specific hash
    }

    enum OutcomeType {
        Transfer, // Transfer to a specific address
        Burn,     // Burn the locked assets
        Delegate  // Delegate rights/action to another contract (conceptually)
    }

    struct Outcome {
        OutcomeType outcomeType; // Type of action
        address recipient;       // Recipient for Transfer type
        bytes32 conditionHash;   // Hash that must match collapse data for this outcome
        uint256 value;           // Value/data specific to the outcome type (e.g., sub-amount for split)
        string description;      // Optional description of the outcome
    }

    struct Lock {
        uint256 id;
        address depositor;         // Original creator of the lock
        address currentRightsHolder; // Address currently holding cancellation/expiration rights
        address asset;             // 0x0 for ETH, token address for ERC20
        uint256 amount;            // Amount of asset locked
        LockState state;           // Current state of the lock
        CollapseMechanism collapseMechanism; // How the superposition collapses
        bytes32 collapseData;      // Hash (for HashReveal) or arbitrary data (for Time)
        uint64 collapseDeadline;   // Timestamp or block number threshold for collapse
        uint64 expirationTime;     // Timestamp after which the lock can be expired
        Outcome[] potentialOutcomes; // Array of possible outcomes, one matches collapseData/reveal
        int256 chosenOutcomeIndex;   // Index of the outcome chosen after collapse (-1 if not collapsed)
        bool transferableRights;   // Can the rights be transferred?
        address gasSponsor;        // Address designated to pay for the collapse transaction gas
    }

    mapping(uint256 => Lock) public locks;
    uint256 private _lockCounter;

    address public owner;
    address public feeRecipient;

    mapping(address => bool) public supportedAssets; // 0x0 for ETH is implicitly supported

    // Fee settings: Basis points (10000 = 100%)
    uint256 public createFeeETH;
    uint256 public createFeeERC20BasisPoints;
    uint256 public cancelPenaltyBasisPoints;
    uint256 public expirePenaltyBasisPoints;

    event LockCreated(uint256 indexed lockId, address indexed depositor, address asset, uint256 amount, LockState initialState);
    event LockCollapsed(uint256 indexed lockId, bytes32 indexed collapseTriggerData, int256 indexed chosenOutcomeIndex);
    event LockResolved(uint256 indexed lockId, int256 outcomeIndex, OutcomeType outcomeType, address recipient, uint256 value);
    event LockCancelled(uint256 indexed lockId, address indexed cancelledBy, uint256 returnedAmount, uint256 feeAmount);
    event LockExpired(uint256 indexed lockId, uint256 returnedAmount, uint256 feeAmount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SupportedAssetAdded(address indexed tokenAddress);
    event SupportedAssetRemoved(address indexed tokenAddress);
    event FeeSettingsUpdated(uint256 createFeeETH, uint256 createFeeERC20BasisPoints, uint256 cancelPenaltyBasisPoints, uint256 expirePenaltyBasisPoints, address indexed feeRecipient);
    event FeesWithdrawn(address indexed tokenAddress, uint256 amount);
    event LockRightsTransferred(uint256 indexed lockId, address indexed from, address indexed to);
    event LockGasSponsorUpdated(uint256 indexed lockId, address indexed sponsor);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier lockExists(uint256 _lockId) {
        require(_lockId > 0 && _lockId <= _lockCounter, "Lock does not exist");
        _;
    }

    modifier isSuperposition(uint256 _lockId) {
        require(locks[_lockId].state == LockState.Superposition, "Lock is not in Superposition state");
        _;
    }

    modifier isCollapsed(uint256 _lockId) {
        require(locks[_lockId].state == LockState.Collapsed, "Lock is not in Collapsed state");
        _;
    }

    modifier isResolvable(uint256 _lockId) {
        require(locks[_lockId].state == LockState.Collapsed && locks[_lockId].chosenOutcomeIndex >= 0, "Lock not ready for resolution");
        _;
    }

    modifier isExpired(uint256 _lockId) {
        require(locks[_lockId].state == LockState.Expired, "Lock is not in Expired state");
        _;
    }

    modifier isSupportedAsset(address _asset) {
        require(_asset == address(0) || supportedAssets[_asset], "Asset is not supported");
        _;
    }

    constructor() {
        owner = msg.sender;
        feeRecipient = msg.sender; // Default fee recipient is owner
        _lockCounter = 0;

        // Default fee settings
        createFeeETH = 0;
        createFeeERC20BasisPoints = 0; // 0%
        cancelPenaltyBasisPoints = 1000; // 10%
        expirePenaltyBasisPoints = 2000; // 20%
    }

    // --- Core Lock Management ---

    /**
     * @dev Creates a new lock with defined potential outcomes and collapse mechanism.
     * @param asset Address of the asset (0x0 for ETH).
     * @param amount Amount of asset to lock.
     * @param outcomes Array of possible outcomes, each with a condition hash.
     * @param collapseMechanism The mechanism that triggers state collapse.
     * @param collapseData Data relevant to the collapse mechanism (hash for HashReveal, arbitrary for Time).
     * @param collapseDeadline Timestamp or block number after which collapse can occur (Time) or must occur before expiration (HashReveal).
     * @param expirationTime Timestamp after which the lock can be expired if not collapsed.
     * @param transferableRights Whether the rights to the lock can be transferred by the current holder.
     * @param initialGasSponsor Address to potentially sponsor the collapse transaction gas (0x0 if none).
     */
    function createLock(
        address asset,
        uint256 amount,
        Outcome[] memory outcomes,
        CollapseMechanism collapseMechanism,
        bytes32 collapseData,
        uint64 collapseDeadline,
        uint64 expirationTime,
        bool transferableRights,
        address initialGasSponsor
    ) internal isSupportedAsset(asset) returns (uint256 lockId) {
        require(outcomes.length > 0, "Must define at least one outcome");
        require(expirationTime > collapseDeadline, "Expiration must be after collapse deadline");

        _lockCounter++;
        lockId = _lockCounter;

        locks[lockId] = Lock({
            id: lockId,
            depositor: msg.sender,
            currentRightsHolder: msg.sender, // Initially, depositor holds the rights
            asset: asset,
            amount: amount,
            state: LockState.Superposition,
            collapseMechanism: collapseMechanism,
            collapseData: collapseData,
            collapseDeadline: collapseDeadline,
            expirationTime: expirationTime,
            potentialOutcomes: outcomes, // Deep copy required if outcomes were state variable
            chosenOutcomeIndex: -1, // Not yet collapsed
            transferableRights: transferableRights,
            gasSponsor: initialGasSponsor == address(0) ? msg.sender : initialGasSponsor // Default sponsor is depositor
        });

        // Handle fee payment
        uint256 fee = 0;
        if (asset == address(0)) {
            require(msg.value >= amount + createFeeETH, "Insufficient ETH sent for amount and fee");
            fee = createFeeETH;
            if (msg.value > amount + fee) {
                 // Refund excess ETH
                payable(msg.sender).transfer(msg.value - amount - fee);
            }
            // No need to transfer deposit amount here, it's already msg.value
        } else {
            require(msg.value == createFeeETH, "Must send creation fee in ETH");
            fee = (amount * createFeeERC20BasisPoints) / 10000;
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");
        }

        if (fee > 0) {
             if (asset == address(0)) {
                // ETH fee already covered by msg.value check, just ensure feeRecipient is payable
                payable(feeRecipient).transfer(fee);
             } else {
                // For ERC20 deposit, fee is taken from the deposited amount or a separate mechanism (here assuming from deposited amount)
                // A more complex fee model might charge a separate ETH fee or require approval for a fee token
                // For simplicity here, we'll say the fee is taken from the locked amount if asset is ERC20
                uint256 assetFee = (amount * createFeeERC20BasisPoints) / 10000;
                if (assetFee > 0) {
                    // This implies the actual locked amount is amount - assetFee
                    // A better design would be to require amount + fee for ETH and amount for ERC20 + separate ETH fee.
                    // Let's adjust: ETH fee is separate ETH, ERC20 fee is basis points OF the amount, reducing locked amount.
                    uint256 actualLockedAmount = amount - assetFee;
                    if (actualLockedAmount > 0 && assetFee > 0) {
                         // Transfer asset fee to fee recipient
                        // This requires an allowance from the depositor, which is bad UX.
                        // Let's simplify: ETH fee is paid via msg.value. ERC20 fee is paid separately in ETH.
                         require(msg.value >= createFeeETH, "Must send creation fee in ETH");
                         if (msg.value > createFeeETH) {
                            payable(msg.sender).transfer(msg.value - createFeeETH); // Refund excess ETH fee
                         }
                         payable(feeRecipient).transfer(createFeeETH);
                    }
                     // Revert the ERC20 fee logic - charging a fee from the deposited amount makes it complex.
                     // Let's assume ERC20 deposit requires `amount` approved, and a separate `msg.value` for ETH fee.

                     // Re-doing fee logic:
                     // ETH deposit: msg.value >= amount + createFeeETH. Refund excess msg.value. Lock `amount`. Send `createFeeETH` to feeRecipient.
                     // ERC20 deposit: msg.value >= createFeeETH. Refund excess msg.value. Require amount transferred via transferFrom. Lock `amount`. Send `createFeeETH` to feeRecipient.

                    require(msg.value >= createFeeETH, "Insufficient ETH sent for creation fee");
                    if (msg.value > createFeeETH) {
                        payable(msg.sender).transfer(msg.value - createFeeETH); // Refund excess ETH
                    }
                     if (createFeeETH > 0) {
                        payable(feeRecipient).transfer(createFeeETH);
                     }
                    // The amount `amount` is locked via transferFrom below
                }
        }

        emit LockCreated(lockId, msg.sender, asset, amount, LockState.Superposition);
        return lockId;
    }

    /**
     * @dev Creates a lock specifically for ETH deposits.
     * @param outcomes Array of possible outcomes.
     * @param collapseMechanism The mechanism that triggers state collapse.
     * @param collapseData Data relevant to the collapse mechanism.
     * @param collapseDeadline Timestamp or block number threshold.
     * @param expirationTime Timestamp after which the lock can be expired.
     * @param transferableRights Whether the rights can be transferred.
     * @param initialGasSponsor Address to potentially sponsor gas.
     */
    function depositETH(
        Outcome[] memory outcomes,
        CollapseMechanism collapseMechanism,
        bytes32 collapseData,
        uint64 collapseDeadline,
        uint64 expirationTime,
        bool transferableRights,
        address initialGasSponsor
    ) public payable returns (uint256) {
        require(msg.value > createFeeETH, "Insufficient ETH sent for amount and fee"); // Require at least fee + some amount
        uint256 amountToLock = msg.value - createFeeETH;

        uint256 lockId = createLock(
            address(0), // ETH
            amountToLock,
            outcomes,
            collapseMechanism,
            collapseData,
            collapseDeadline,
            expirationTime,
            transferableRights,
            initialGasSponsor
        );

         if (createFeeETH > 0) {
            payable(feeRecipient).transfer(createFeeETH);
        }
        // AmountToLock is already in the contract via msg.value

        return lockId;
    }

    /**
     * @dev Creates a lock specifically for ERC20 deposits.
     * Requires msg.sender to have approved this contract to spend `amount` of the token.
     * Also requires msg.value to cover the ETH creation fee.
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of ERC20 to lock.
     * @param outcomes Array of possible outcomes.
     * @param collapseMechanism The mechanism that triggers state collapse.
     * @param collapseData Data relevant to the collapse mechanism.
     * @param collapseDeadline Timestamp or block number threshold.
     * @param expirationTime Timestamp after which the lock can be expired.
     * @param transferableRights Whether the rights can be transferred.
     * @param initialGasSponsor Address to potentially sponsor gas.
     */
    function depositERC20(
        address tokenAddress,
        uint256 amount,
        Outcome[] memory outcomes,
        CollapseMechanism collapseMechanism,
        bytes32 collapseData,
        uint64 collapseDeadline,
        uint64 expirationTime,
        bool transferableRights,
        address initialGasSponsor
    ) public payable returns (uint256) {
         require(msg.value >= createFeeETH, "Insufficient ETH sent for creation fee");
        if (msg.value > createFeeETH) {
            payable(msg.sender).transfer(msg.value - createFeeETH); // Refund excess ETH
        }
         if (createFeeETH > 0) {
            payable(feeRecipient).transfer(createFeeETH);
        }


        uint256 lockId = createLock(
            tokenAddress,
            amount,
            outcomes,
            collapseMechanism,
            collapseData,
            collapseDeadline,
            expirationTime,
            transferableRights,
            initialGasSponsor
        );

        // Transfer ERC20 after lock creation (within createLock)
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "ERC20 transferFrom failed");

        return lockId;
    }


    /**
     * @dev Triggers the collapse of a lock's superposition state.
     * This function is intended to be called by the designated gas sponsor,
     * but can be called by anyone if no sponsor is set or they wish to front the gas.
     * @param lockId The ID of the lock to collapse.
     * @param revealValue The pre-image required for HashReveal mechanism (ignored for Time).
     */
    function collapseLock(uint256 lockId, bytes calldata revealValue)
        public
        lockExists(lockId)
        isSuperposition(lockId)
    {
        Lock storage lock = locks[lockId];
        int256 chosenIndex = -1;
        bytes32 collapseTriggerData; // Data that actually caused the collapse

        if (lock.collapseMechanism == CollapseMechanism.Time) {
            require(block.timestamp >= lock.collapseDeadline, "Collapse deadline not yet reached");
            collapseTriggerData = lock.collapseData; // Use the predefined data for Time-based collapse
             // For Time-based, we could select an outcome based on `block.timestamp` relative to something,
             // or simply require the collapseData to match one of the outcome conditionHashes.
             // Let's use the latter for consistency: Time collapse requires `collapseData` to match an outcome hash.
            chosenIndex = _calculateOutcomeIndex(lockId, abi.encodePacked(lock.collapseData)); // Treat collapseData as the "reveal"
             require(chosenIndex != -1, "No outcome matches collapse data");

        } else if (lock.collapseMechanism == CollapseMechanism.HashReveal) {
             require(block.timestamp <= lock.expirationTime, "Collapse window has passed, lock expired"); // Can't collapse after expiration
            collapseTriggerData = keccak256(revealValue);
            require(collapseTriggerData == lock.collapseData, "Invalid reveal value");
             // For HashReveal, the *matching* hash determines the outcome.
             // The `collapseData` itself (the hash) must match the revealed pre-image's hash.
             // The outcome selection should be based on a *different* property or the specific reveal value.
             // Let's redefine: For HashReveal, `collapseData` is the hash to match. `revealValue` is the pre-image.
             // The *outcome* is determined by which Outcome.conditionHash matches `keccak256(revealValue)`.
             chosenIndex = _calculateOutcomeIndex(lockId, revealValue);
             require(chosenIndex != -1, "Revealed value does not match any outcome condition hash");

        } else {
            revert("Unsupported collapse mechanism");
        }

        lock.state = LockState.Collapsed;
        lock.chosenOutcomeIndex = chosenIndex;

        emit LockCollapsed(lockId, collapseTriggerData, chosenIndex);
    }

    /**
     * @dev Resolves a collapsed lock by executing the chosen outcome.
     * This function can be called by anyone to finalize the lock.
     * @param lockId The ID of the lock to resolve.
     */
    function resolveLock(uint256 lockId)
        public
        lockExists(lockId)
        isResolvable(lockId)
    {
        Lock storage lock = locks[lockId];
        require(lock.chosenOutcomeIndex >= 0 && uint256(lock.chosenOutcomeIndex) < lock.potentialOutcomes.length, "Invalid chosen outcome index");

        Outcome memory chosenOutcome = lock.potentialOutcomes[uint256(lock.chosenOutcomeIndex)];

        _executeOutcome(lockId, chosenOutcome);

        lock.state = LockState.Resolved;

        emit LockResolved(lockId, lock.chosenOutcomeIndex, chosenOutcome.outcomeType, chosenOutcome.recipient, chosenOutcome.value);
        // Note: Locked amount is now effectively zero or handled by the outcome.
        // We don't explicitly set lock.amount to 0, as the state indicates resolution.
    }

    /**
     * @dev Allows the current rights holder or owner to cancel a lock before collapse.
     * Applies a penalty fee.
     * @param lockId The ID of the lock to cancel.
     */
    function cancelLock(uint256 lockId)
        public
        lockExists(lockId)
        isSuperposition(lockId)
    {
        Lock storage lock = locks[lockId];
        require(msg.sender == lock.currentRightsHolder || msg.sender == owner, "Only current rights holder or owner can cancel");

        uint256 totalAmount = lock.amount;
        uint256 penaltyAmount = (totalAmount * cancelPenaltyBasisPoints) / 10000;
        uint256 returnAmount = totalAmount - penaltyAmount;

        if (returnAmount > 0) {
             if (lock.asset == address(0)) {
                 payable(lock.depositor).transfer(returnAmount);
             } else {
                 require(IERC20(lock.asset).transfer(lock.depositor, returnAmount), "ERC20 transfer failed during cancel");
             }
        }

        if (penaltyAmount > 0) {
            // Penalty amount stays in contract, added to fee balance (withdrawal handled by owner)
            // Or directly send to feeRecipient? Sending to feeRecipient is simpler.
             if (lock.asset == address(0)) {
                 if (address(this).balance < penaltyAmount) {
                    // This shouldn't happen if penalty is deducted from totalAmount
                    // but safe check anyway. If ETH fee is sent directly, ensure payable.
                    payable(feeRecipient).transfer(penaltyAmount);
                 } else {
                    payable(feeRecipient).transfer(penaltyAmount);
                 }
             } else {
                 // This needs a transfer, implies the contract needs approval or holds the tokens
                 // The locked tokens *are* held by the contract.
                 require(IERC20(lock.asset).transfer(feeRecipient, penaltyAmount), "ERC20 fee transfer failed during cancel");
             }
        }


        lock.state = LockState.Cancelled;
        // Clear sensitive data? Or leave for history? Leave for history.

        emit LockCancelled(lockId, msg.sender, returnAmount, penaltyAmount);
    }

    /**
     * @dev Allows anyone to expire a lock if the expiration time has passed
     * and it's still in Superposition. Applies a penalty and typically
     * returns assets to the original depositor (a default outcome).
     * @param lockId The ID of the lock to expire.
     */
    function expireLock(uint256 lockId)
        public
        lockExists(lockId)
        isSuperposition(lockId)
    {
        Lock storage lock = locks[lockId];
        require(block.timestamp >= lock.expirationTime, "Expiration time not reached");

        uint256 totalAmount = lock.amount;
        uint256 penaltyAmount = (totalAmount * expirePenaltyBasisPoints) / 10000;
        uint256 returnAmount = totalAmount - penaltyAmount;

         if (returnAmount > 0) {
             if (lock.asset == address(0)) {
                 payable(lock.depositor).transfer(returnAmount);
             } else {
                 require(IERC20(lock.asset).transfer(lock.depositor, returnAmount), "ERC20 transfer failed during expire");
             }
        }

        if (penaltyAmount > 0) {
             if (lock.asset == address(0)) {
                 if (address(this).balance < penaltyAmount) {
                    payable(feeRecipient).transfer(penaltyAmount);
                 } else {
                    payable(feeRecipient).transfer(penaltyAmount);
                 }
             } else {
                 require(IERC20(lock.asset).transfer(feeRecipient, penaltyAmount), "ERC20 fee transfer failed during expire");
             }
        }

        lock.state = LockState.Expired;
        // Could optionally set a default outcome index (-2 maybe?)

        emit LockExpired(lockId, returnAmount, penaltyAmount);
    }


    // --- State & Info Functions (View/Pure) ---

    /**
     * @dev Retrieves all details for a specific lock.
     * @param lockId The ID of the lock.
     * @return The Lock struct.
     */
    function getLockDetails(uint256 lockId) public view lockExists(lockId) returns (Lock memory) {
        return locks[lockId];
    }

    /**
     * @dev Retrieves the current state of a lock.
     * @param lockId The ID of the lock.
     * @return The LockState enum value.
     */
    function getLockState(uint256 lockId) public view lockExists(lockId) returns (LockState) {
        return locks[lockId].state;
    }

    /**
     * @dev Retrieves the array of potential outcomes defined for a lock.
     * @param lockId The ID of the lock.
     * @return An array of Outcome structs.
     */
    function getPossibleOutcomes(uint256 lockId) public view lockExists(lockId) returns (Outcome[] memory) {
        return locks[lockId].potentialOutcomes;
    }

    /**
     * @dev Retrieves the details of the outcome selected after collapse.
     * @param lockId The ID of the lock.
     * @return The chosen Outcome struct (will return default/empty if not collapsed).
     */
    function getChosenOutcome(uint255 lockId) public view lockExists(lockId) returns (Outcome memory) {
        Lock storage lock = locks[lockId];
        if (lock.state == LockState.Collapsed && lock.chosenOutcomeIndex >= 0 && uint256(lock.chosenOutcomeIndex) < lock.potentialOutcomes.length) {
            return lock.potentialOutcomes[uint256(lock.chosenOutcomeIndex)];
        }
        // Return an empty Outcome struct if not collapsed or index invalid
        return Outcome(OutcomeType.Transfer, address(0), bytes32(0), 0, "");
    }

    /**
     * @dev Retrieves the expiration timestamp of a lock.
     * @param lockId The ID of the lock.
     * @return The expiration timestamp.
     */
    function getLockExpirationTime(uint256 lockId) public view lockExists(lockId) returns (uint64) {
        return locks[lockId].expirationTime;
    }

    /**
     * @dev Retrieves the collapse deadline timestamp for a time-based lock.
     * Returns 0 if the mechanism is HashReveal.
     * @param lockId The ID of the lock.
     * @return The collapse deadline timestamp or 0.
     */
    function getLockCollapseTime(uint256 lockId) public view lockExists(lockId) returns (uint64) {
         Lock storage lock = locks[lockId];
        if (lock.collapseMechanism == CollapseMechanism.Time) {
            return lock.collapseDeadline;
        }
        return 0; // Not applicable for HashReveal
    }

    /**
     * @dev Retrieves the total number of locks created.
     * @return The total lock count.
     */
    function getLockCount() public view returns (uint256) {
        return _lockCounter;
    }

    /**
     * @dev Checks if a lock is in the 'Collapsed' state and ready to be resolved.
     * @param lockId The ID of the lock.
     * @return True if resolvable, false otherwise.
     */
    function isLockResolvable(uint256 lockId) public view lockExists(lockId) returns (bool) {
        Lock storage lock = locks[lockId];
        return lock.state == LockState.Collapsed && lock.chosenOutcomeIndex >= 0;
    }


    // --- Configuration & Admin ---

    /**
     * @dev Owner adds an ERC20 token to the list of supported assets for deposits.
     * @param tokenAddress The address of the ERC20 token.
     */
    function addSupportedAsset(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "Cannot add zero address as supported asset");
        supportedAssets[tokenAddress] = true;
        emit SupportedAssetAdded(tokenAddress);
    }

    /**
     * @dev Owner removes an ERC20 token from the list of supported assets.
     * Does not affect existing locks using this asset.
     * @param tokenAddress The address of the ERC20 token.
     */
    function removeSupportedAsset(address tokenAddress) public onlyOwner {
         require(tokenAddress != address(0), "Cannot remove zero address");
        supportedAssets[tokenAddress] = false;
        emit SupportedAssetRemoved(tokenAddress);
    }

     /**
      * @dev Owner sets various fee parameters for the contract.
      * @param _createFeeETH Flat ETH fee for creating any lock.
      * @param _createFeeERC20BasisPoints Basis points fee on amount for ERC20 creation (UNUSED IN CURRENT FEE LOGIC).
      * @param _cancelPenaltyBasisPoints Basis points penalty on total amount for cancellation.
      * @param _expirePenaltyBasisPoints Basis points penalty on total amount for expiration.
      * @param _feeRecipient Address to receive collected fees.
      */
    function setFeeSettings(
        uint256 _createFeeETH,
        uint256 _createFeeERC20BasisPoints, // UNUSED IN CURRENT FEE LOGIC
        uint256 _cancelPenaltyBasisPoints,
        uint256 _expirePenaltyBasisPoints,
        address _feeRecipient
    ) public onlyOwner {
        createFeeETH = _createFeeETH;
        createFeeERC20BasisPoints = _createFeeERC20BasisPoints; // Keep for future reference/logic change
        cancelPenaltyBasisPoints = _cancelPenaltyBasisPoints;
        expirePenaltyBasisPoints = _expirePenaltyBasisPoints;
        feeRecipient = _feeRecipient;
        emit FeeSettingsUpdated(createFeeETH, createFeeERC20BasisPoints, cancelPenaltyBasisPoints, expirePenaltyBasisPoints, feeRecipient);
    }

    /**
     * @dev Owner withdraws collected fees for a specific asset.
     * Fees are collected from cancellation/expiration penalties and potentially creation.
     * @param tokenAddress The address of the token to withdraw (0x0 for ETH).
     * @param amount The amount to withdraw.
     */
    function withdrawFees(address tokenAddress, uint256 amount) public onlyOwner {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount, "Insufficient ETH balance");
            payable(owner).transfer(amount); // Withdraw ETH fees to owner
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
            require(token.transfer(owner, amount), "Token withdrawal failed"); // Withdraw ERC20 fees to owner
        }
        emit FeesWithdrawn(tokenAddress, amount);
    }

    /**
     * @dev Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Renounces ownership of the contract.
     * The contract will no longer have an owner, preventing further owner-only calls.
     */
    function renounceOwnership() public onlyOwner {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    // --- Advanced Features ---

    /**
     * @dev Allows the current rights holder of a transferable lock to transfer their rights.
     * This includes the ability to cancel or potentially receive assets on expiration.
     * Only possible while the lock is in 'Superposition'.
     * @param lockId The ID of the lock.
     * @param newRightsHolder The address to transfer rights to.
     */
    function transferLockRights(uint256 lockId, address newRightsHolder)
        public
        lockExists(lockId)
        isSuperposition(lockId)
    {
        Lock storage lock = locks[lockId];
        require(lock.transferableRights, "Lock rights are not transferable");
        require(msg.sender == lock.currentRightsHolder, "Only current rights holder can transfer rights");
        require(newRightsHolder != address(0), "New rights holder cannot be the zero address");

        lock.currentRightsHolder = newRightsHolder;
        emit LockRightsTransferred(lockId, msg.sender, newRightsHolder);
    }

    /**
     * @dev Allows the current rights holder of a lock to set or update the gas sponsor.
     * The gas sponsor is the address intended to call and pay for the `collapseLock` transaction.
     * Only possible while the lock is in 'Superposition'.
     * @param lockId The ID of the lock.
     * @param sponsorAddress The address to set as the gas sponsor (0x0 to remove sponsor, defaulting to depositor).
     */
    function setLockGasSponsor(uint256 lockId, address sponsorAddress)
        public
        lockExists(lockId)
        isSuperposition(lockId)
    {
        Lock storage lock = locks[lockId];
        require(msg.sender == lock.currentRightsHolder, "Only current rights holder can set gas sponsor");

        lock.gasSponsor = sponsorAddress == address(0) ? lock.depositor : sponsorAddress;
        emit LockGasSponsorUpdated(lockId, lock.gasSponsor);
    }


    // --- Internal Logic ---

    /**
     * @dev Internal helper function to execute a specific outcome.
     * @param lockId The ID of the lock.
     * @param outcome The Outcome struct to execute.
     */
    function _executeOutcome(uint256 lockId, Outcome memory outcome) internal {
        Lock storage lock = locks[lockId];
        uint256 amountToTransfer = lock.amount; // By default, transfer the whole amount

        // Implement outcome-specific logic
        if (outcome.outcomeType == OutcomeType.Transfer) {
             require(outcome.recipient != address(0), "Transfer outcome requires a recipient");
             // Could add logic here to handle partial transfers based on outcome.value
             // For simplicity, assuming the chosen outcome gets the full amount locked for now.

             if (lock.asset == address(0)) {
                 // Transfer ETH
                 (bool success, ) = payable(outcome.recipient).call{value: amountToTransfer}("");
                 require(success, "ETH transfer failed during resolution");
             } else {
                 // Transfer ERC20
                 IERC20 token = IERC20(lock.asset);
                 require(token.transfer(outcome.recipient, amountToTransfer), "ERC20 transfer failed during resolution");
             }
        } else if (outcome.outcomeType == OutcomeType.Burn) {
            // Burning ETH is not possible, it's just left in the contract or sent to 0x0
            // Burning ERC20 requires the token to support burning functionality (e.g., via transfer to 0x0)
            if (lock.asset == address(0)) {
                // Send ETH to burn address (0x0) or leave it
                 (bool success, ) = payable(address(0)).call{value: amountToTransfer}("");
                 require(success, "ETH burn (transfer to 0x0) failed");
            } else {
                 IERC20 token = IERC20(lock.asset);
                 require(token.transfer(address(0), amountToTransfer), "ERC20 burn failed"); // Assuming transfer to 0x0 burns
            }
        } else if (outcome.outcomeType == OutcomeType.Delegate) {
             // This is a conceptual outcome type. Implementation would depend on what
             // 'delegating' means - e.g., transferring an NFT representing the lock,
             // calling a function on another contract, etc.
             revert("Delegate outcome type is conceptual and not implemented");
        } else {
            revert("Unsupported outcome type");
        }
    }

     /**
      * @dev Internal helper to calculate the index of the winning outcome after collapse.
      * For Time-based, it finds the outcome whose conditionHash matches the lock's collapseData.
      * For HashReveal, it finds the outcome whose conditionHash matches the hash of the revealValue.
      * @param lockId The ID of the lock.
      * @param triggerData The data that triggered the collapse (keccak256(revealValue) or lock.collapseData).
      * @return The index of the matching outcome, or -1 if no match is found.
      */
    function _calculateOutcomeIndex(uint256 lockId, bytes calldata triggerData) internal view returns (int256) {
        Lock storage lock = locks[lockId];
        bytes32 triggerHash = keccak256(triggerData); // Hash of the reveal value for HashReveal, or hash of collapseData for Time

        for (uint i = 0; i < lock.potentialOutcomes.length; i++) {
             // For HashReveal, we need keccak256(revealValue) to match lock.collapseData
             // And the revealValue's hash must match one of the outcome conditionHashes.
             // This implies a revealValue must satisfy TWO conditions simultaneously:
             // 1. keccak256(revealValue) == lock.collapseData (the overall lock's condition)
             // 2. keccak256(revealValue) == lock.potentialOutcomes[i].conditionHash (the specific outcome's condition)
             // This means lock.collapseData must be equal to the winning outcome's conditionHash.
             // Let's simplify: For HashReveal, keccak256(revealValue) matches the lock's collapseData. The *index*
             // is simply found by matching collapseData to an outcome's conditionHash.
             // For Time, lock.collapseData is the value to match against outcome conditionHashes.

             if (lock.potentialOutcomes[i].conditionHash == triggerHash) {
                 return int256(i);
             }
        }
        return -1; // No matching outcome
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Optional: Function to handle ERC721 or ERC1155 locking could be added,
    // requiring different data structures and transfer mechanisms.
    // This contract focuses on fungible tokens (ETH/ERC20).
}
```