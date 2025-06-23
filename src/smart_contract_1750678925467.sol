Okay, let's create a complex, feature-rich smart contract called "QuantumVault". This contract allows users to deposit ERC20 tokens and lock them under highly customizable, multi-conditional, and time-dependent terms for themselves or other recipients. The "Quantum" aspect comes from the idea that unlocking requires a confluence of different, potentially independent, conditions to align – a form of "state collapse" or fulfilling multiple requirements simultaneously.

It will incorporate:
1.  **Multi-conditional Release:** Unlocking requires satisfying a combination of time, external data, multi-party confirmations, Merkle proof verification, and/or specific interaction triggers.
2.  **Time Dynamics:** Time locks, expiration, and potentially time-based penalties.
3.  **Multi-Party Aspects:** Multiple recipients, multi-sig style confirmation requirements.
4.  **External Interaction Simulation:** Conditions dependent on external data (simulated oracle) or specific off-chain/other-contract interactions (simulated trigger).
5.  **Proof-based Release:** Unlocking can require providing a valid Merkle proof.
6.  **Complex State Management:** Tracking individual lock states, condition statuses, and confirmations.
7.  **Cancellation & Reclaiming:** Mechanisms for locker to cancel early (with penalty) or reclaim if conditions are never met/lock expires.

---

## QuantumVault Smart Contract

**Purpose:** A secure vault for locking ERC20 tokens based on complex, multi-faceted, time-dependent, and conditional criteria. Unlocking requires fulfilling a combination of predefined conditions.

**Outline:**
1.  **Imports:** ERC20 standard, utility libraries (SafeERC20, Ownable, Pausable).
2.  **Errors:** Custom errors for clarity.
3.  **Events:** To signal key actions (Lock Created, Unlocked, Cancelled, Condition Met, etc.).
4.  **Structs:** `QuantumLock` to define the parameters and state of each locked position.
5.  **State Variables:** Mappings for locks, user lock IDs, global parameters (oracle address, Merkle root, penalty rate), counters.
6.  **Modifiers:** Standard `onlyOwner`, `whenNotPaused`, custom condition-check helpers.
7.  **Constructor:** Initializes the token address and ownership.
8.  **Core Functionality:**
    *   Deposit tokens.
    *   Create a new Quantum Lock with various conditions.
    *   Check the current unlock status of a lock (view).
    *   Attempt to execute an unlock, verifying all conditions.
9.  **Condition Management:**
    *   Setting global external data parameters (by Oracle role).
    *   Setting global Merkle root (by Oracle/Owner role).
    *   Submitting Merkle proof for a specific lock/recipient.
    *   Submitting multi-sig confirmations by recipients.
    *   Triggering a specific interaction condition flag.
    *   Checking status of specific conditions (views).
10. **Lock Management:**
    *   Retrieving lock details (view).
    *   Getting locks associated with a user (view).
    *   Locker initiating early cancellation.
    *   Locker withdrawing tokens after cancellation or expiration/failure.
11. **Admin/Utility:**
    *   Pause/Unpause contract.
    *   Set various trusted addresses (Oracle, Interaction Trigger).
    *   Set penalty rates.
    *   Check contract token balance (view).
    *   Ownership management.

**Function Summary:**

1.  `constructor(address tokenAddress)`: Initializes contract, sets the ERC20 token, and sets deployer as owner.
2.  `pause()`: Pauses the contract, preventing state-changing actions (Owner only).
3.  `unpause()`: Unpauses the contract (Owner only).
4.  `deposit(uint256 amount)`: User deposits ERC20 tokens into the vault (requires token approval).
5.  `createQuantumLock(address[] recipients, uint256 amount, uint64 endTime, uint256 requiredExternalDataValue, uint256 requiredConfirmations, bytes32 requiredMerkleLeaf, bool requiresSpecificInteraction, bool requiresExternalData, bool requiresMultiSig, bool requiresMerkleProof, bool requiresSpecificInteraction)`: Creates a new lock with the specified parameters and conditions. Transfers `amount` from locker to contract.
6.  `checkLockStatus(uint256 lockId)`: View function. Checks if *all* required conditions for a lock are currently met based on the current global state and individual lock state. Returns `true` if unlockable, `false` otherwise.
7.  `attemptUnlock(uint256 lockId)`: Attempts to unlock a lock. Requires `msg.sender` to be one of the recipients. Calls `checkLockStatus`. If true, transfers the recipient's share of tokens and updates lock state.
8.  `getLockDetails(uint256 lockId)`: View function. Returns all stored details for a given lock ID.
9.  `getUserLockIds(address user)`: View function. Returns an array of lock IDs associated with the given user (as locker or recipient).
10. `cancelLockByLocker(uint256 lockId)`: Allows the original locker to initiate cancellation *before* the `endTime`. Marks lock as cancelled and available for withdrawal (subject to penalty).
11. `withdrawCancelledTokens(uint256 lockId)`: Allows the original locker to withdraw tokens from a lock previously marked as cancelled. Calculates and applies the early cancellation penalty.
12. `reclaimExpiredLock(uint256 lockId)`: Allows the original locker to reclaim tokens from a lock whose `endTime` has passed *without* successfully being unlocked by any recipient.
13. `setOracleAddress(address _oracleAddress)`: Owner sets the trusted address for providing external data and Merkle roots.
14. `updateExternalDataValue(uint256 _newValue)`: Only the Oracle address can call this to update the global `currentExternalDataValue`.
15. `setMerkleRoot(bytes32 _newRoot)`: Only the Oracle address (or Owner) can call this to update the global `currentMerkleRoot` for Merkle proof conditions.
16. `provideMerkleProof(uint256 lockId, bytes32[] calldata proof)`: Allows a recipient of a lock requiring Merkle proof to submit their proof. Verifies the proof against the `currentMerkleRoot` and the `requiredMerkleLeaf` stored in the lock. Sets a flag on the lock indicating proof provided for this recipient.
17. `setInteractionTriggerAddress(address _triggerAddress)`: Owner sets the trusted address that can signal specific interaction conditions.
18. `triggerSpecificInteractionCondition(uint256 lockId)`: Only the Interaction Trigger address can call this to mark the `specificInteractionConditionMet` flag for a given lock.
19. `confirmMultiSigCondition(uint256 lockId)`: Allows a recipient of a lock requiring multi-sig to submit their confirmation. Increments the confirmation count for that lock.
20. `isMultiSigConditionMet(uint256 lockId)`: View function. Checks if the required number of multi-sig confirmations has been reached for a lock.
21. `getPendingMultiSigConfirmations(uint256 lockId)`: View function. Returns the number of confirmations still needed for a lock's multi-sig condition.
22. `setEarlyCancellationPenaltyRate(uint256 rateInBasisPoints)`: Owner sets the penalty rate for early cancellation (e.g., 500 for 5%).
23. `calculateCancellationPenalty(uint256 lockId)`: View function. Calculates the potential penalty amount if the locker were to cancel the specified lock now.
24. `getVaultBalance()`: View function. Returns the contract's current balance of the locked ERC20 token.
25. `transferOwnership(address newOwner)`: Transfers ownership of the contract (Owner only).
26. `renounceOwnership()`: Renounces ownership of the contract (Owner only).
27. `getRecipientUnlockAmount(uint256 lockId)`: View function. Calculates the amount each recipient is due upon successful unlock, based on the total lock amount and number of recipients.
28. `checkMerkleProofProvided(uint256 lockId, address recipient)`: View function. Checks if the Merkle proof condition has been successfully fulfilled by a specific recipient for a lock.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath explicitly for basis points calculation safety

/// @title QuantumVault
/// @notice A secure vault for locking ERC20 tokens under complex, multi-conditional terms.
/// Unlocking requires fulfilling a combination of time, external data, multi-party confirmations, Merkle proof, and interaction conditions.
contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256; // Used specifically for penalty calculation

    // --- Custom Errors ---
    error InvalidAmount();
    error InvalidLockTime();
    error NoRecipients();
    error LockDoesNotExist();
    error NotRecipient();
    error LockNotActive();
    error LockAlreadyUnlocked();
    error LockAlreadyCancelled();
    error LockNotCancelled();
    error LockNotExpired();
    error LockStillActive();
    error NotLocker();
    error OracleOnly();
    error InteractionTriggerOnly();
    error MultiSigConditionNotRequired();
    error AlreadyConfirmedMultiSig();
    error MerkleProofNotRequired();
    error MerkleProofAlreadyProvided();
    error MerkleProofVerificationFailed();
    error SpecificInteractionConditionNotRequired();
    error ConditionsNotMet();
    error PenaltyRateInvalid();
    error RecipientAmountZero();

    // --- Events ---
    event LockCreated(uint256 indexed lockId, address indexed locker, address[] recipients, uint256 amount, uint64 endTime);
    event LockConditionsChecked(uint256 indexed lockId, bool conditionsMet);
    event LockAttempted(uint256 indexed lockId, address indexed recipient);
    event LockUnlocked(uint256 indexed lockId, address indexed recipient, uint256 amount);
    event LockCancelled(uint256 indexed lockId, address indexed locker);
    event CancelledTokensWithdrawn(uint256 indexed lockId, address indexed locker, uint256 amount, uint256 penalty);
    event ExpiredLockReclaimed(uint256 indexed lockId, address indexed locker, uint256 amount);
    event ExternalDataValueUpdated(uint256 newValue);
    event MerkleRootUpdated(bytes32 newRoot);
    event MerkleProofProvided(uint256 indexed lockId, address indexed recipient);
    event MultiSigConfirmed(uint256 indexed lockId, address indexed confirmer, uint256 currentConfirmations);
    event InteractionTriggered(uint256 indexed lockId);
    event EarlyCancellationPenaltyRateUpdated(uint256 rate);

    // --- Structs ---
    struct QuantumLock {
        address locker;
        address[] recipients; // Addresses that can attempt to unlock
        uint256 amount;
        uint64 startTime; // Block timestamp when lock was created
        uint64 endTime;   // Block timestamp after which time condition is met
        uint256 lockId;

        // Conditions
        bool requiresMultiSig; // N of M recipients must confirm
        uint256 requiredConfirmations; // N for multi-sig
        mapping(address => bool) multiSigConfirmed; // Who has confirmed

        bool requiresExternalData; // Requires `currentExternalDataValue` >= `requiredExternalDataValue`
        uint256 requiredExternalDataValue; // Threshold for external data

        bool requiresMerkleProof; // Requires recipient to provide Merkle proof
        bytes32 requiredMerkleLeaf; // Leaf corresponding to the recipient's identity/data
        // Merkle proof verification status is tracked in a separate top-level mapping

        bool requiresSpecificInteraction; // Requires `specificInteractionConditionMet` flag to be set
        bool specificInteractionConditionMet; // Flag set by trusted address

        // State
        bool active;     // True while the lock is potentially unlockable/cancellable
        bool cancelled;  // True if cancelled by locker
        bool unlocked;   // True if successfully unlocked by a recipient
    }

    // --- State Variables ---
    IERC20 public immutable lockedToken; // The ERC20 token held by the vault

    mapping(uint256 => QuantumLock) public quantumLocks; // All created locks
    mapping(address => uint256[]) public userLockIds; // Map users to their locks (as locker or recipient)
    uint256 private nextLockId; // Counter for unique lock IDs

    address public oracleAddress; // Trusted address to provide external data/merkle roots
    address public interactionTriggerAddress; // Trusted address to signal specific interactions

    bytes32 public currentMerkleRoot; // Current Merkle root for proof verification
    uint256 public currentExternalDataValue; // Current value from external data source (oracle)

    uint256 public earlyCancellationPenaltyRate; // Penalty rate in basis points (e.g., 500 for 5%)

    // Tracks if a recipient has provided a valid Merkle proof for a specific lock
    mapping(uint256 => mapping(address => bool)) public merkleProofProvidedForLock;

    // Tracks if a recipient has already successfully unlocked their share for a specific lock
    // This is needed if multiple recipients can claim independently
    mapping(uint256 => mapping(address => bool)) public recipientUnlockedShare;

    // --- Constructor ---
    constructor(address tokenAddress) Ownable(msg.sender) Pausable(false) {
        lockedToken = IERC20(tokenAddress);
        nextLockId = 1; // Start lock IDs from 1
        earlyCancellationPenaltyRate = 0; // Default to no penalty
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert OracleOnly();
        _;
    }

    modifier onlyInteractionTrigger() {
        if (msg.sender != interactionTriggerAddress) revert InteractionTriggerOnly();
        _;
    }

    // --- Core Functionality ---

    /// @notice Allows a user to deposit tokens into the vault.
    /// The user must approve the contract to spend the tokens beforehand.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) public whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        lockedToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Creates a new quantum lock with specified conditions.
    /// Tokens must be deposited beforehand or approved for transfer.
    /// @param recipients Addresses who are eligible to unlock this lock.
    /// @param amount The total amount of tokens to lock.
    /// @param endTime The timestamp after which the time condition is met.
    /// @param requiredExternalDataValue The required minimum value for external data condition.
    /// @param requiredConfirmations The number of recipient confirmations required for multi-sig.
    /// @param requiredMerkleLeaf The expected Merkle leaf for the Merkle proof condition.
    /// @param requiresSpecificInteraction Whether a specific interaction trigger is needed.
    /// @param requiresExternalData Whether an external data condition is needed.
    /// @param requiresMultiSig Whether a multi-sig condition is needed.
    /// @param requiresMerkleProof Whether a Merkle proof condition is needed.
    function createQuantumLock(
        address[] calldata recipients,
        uint256 amount,
        uint64 endTime,
        uint256 requiredExternalDataValue,
        uint256 requiredConfirmations,
        bytes32 requiredMerkleLeaf,
        bool requiresSpecificInteraction,
        bool requiresExternalData,
        bool requiresMultiSig,
        bool requiresMerkleProof
    ) public whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (endTime <= block.timestamp) revert InvalidLockTime();
        if (recipients.length == 0) revert NoRecipients();
        if (requiresMultiSig && requiredConfirmations == 0) revert MultiSigConditionNotRequired();
        if (requiresMultiSig && requiredConfirmations > recipients.length) revert MultiSigConditionNotRequired();

        // Transfer tokens from the locker (msg.sender) to the contract
        lockedToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 id = nextLockId++;
        QuantumLock storage newLock = quantumLocks[id];

        newLock.locker = msg.sender;
        newLock.recipients = recipients; // Store the entire array
        newLock.amount = amount;
        newLock.startTime = uint64(block.timestamp);
        newLock.endTime = endTime;
        newLock.lockId = id;

        // Set conditions
        newLock.requiresMultiSig = requiresMultiSig;
        newLock.requiredConfirmations = requiresMultiSig ? requiredConfirmations : 0;
        // multiSigConfirmed mapping is initialized empty by default

        newLock.requiresExternalData = requiresExternalData;
        newLock.requiredExternalDataValue = requiresExternalData ? requiredExternalDataValue : 0;

        newLock.requiresMerkleProof = requiresMerkleProof;
        newLock.requiredMerkleLeaf = requiresMerkkleProof ? requiredMerkleLeaf : bytes32(0);
        // merkleProofProvidedForLock mapping is initialized empty by default

        newLock.requiresSpecificInteraction = requiresSpecificInteraction;
        newLock.specificInteractionConditionMet = false; // Must be triggered later

        // Set initial state
        newLock.active = true;
        newLock.cancelled = false;
        newLock.unlocked = false;
        newLock.currentConfirmations = 0; // For multi-sig

        // Map lock ID to locker and recipients
        userLockIds[msg.sender].push(id);
        for (uint i = 0; i < recipients.length; i++) {
            userLockIds[recipients[i]].push(id);
        }

        emit LockCreated(id, msg.sender, recipients, amount, endTime);
    }

    /// @notice Checks if all required conditions for a lock are currently met.
    /// This is a view function and does not attempt to unlock.
    /// @param lockId The ID of the lock to check.
    /// @return bool True if all conditions are met and the lock is unlockable, false otherwise.
    function checkLockStatus(uint256 lockId) public view returns (bool) {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (!lock.active) return false; // Lock is not active (cancelled, unlocked, or reclaimed)

        // Check Time Condition
        bool timeConditionMet = block.timestamp >= lock.endTime;

        // Check Multi-Sig Condition
        bool multiSigConditionMet = !lock.requiresMultiSig || (lock.currentConfirmations >= lock.requiredConfirmations);

        // Check External Data Condition
        bool externalDataConditionMet = !lock.requiresExternalData || (currentExternalDataValue >= lock.requiredExternalDataValue);

        // Merkle Proof condition is checked per recipient in `provideMerkleProof`
        // This function only checks the flag, not the proof itself.
        // It's assumed `provideMerkleProof` has been called successfully by the recipient.
        // The recipient check is done in `attemptUnlock`.

        // Check Specific Interaction Condition
        bool specificInteractionConditionMet = !lock.requiresSpecificInteraction || lock.specificInteractionConditionMet;

        bool allConditionsMet = timeConditionMet && multiSigConditionMet && externalDataConditionMet && specificInteractionConditionMet;

        // Note: Merkle proof is per-recipient. `checkLockStatus` only confirms the *requirement* is there,
        // but doesn't check if *this specific caller's* proof is provided. That happens in attemptUnlock.
        // For a general status check, we assume the condition is met if required. A more granular view
        // function `checkMerkleProofProvided` exists.

        emit LockConditionsChecked(lockId, allConditionsMet);
        return allConditionsMet;
    }

    /// @notice Attempts to unlock a share of tokens from a lock.
    /// Must be called by a recipient of the lock. Verifies all conditions, including recipient-specific ones like Merkle proof.
    /// Each recipient can claim their share once.
    /// @param lockId The ID of the lock to attempt unlocking.
    function attemptUnlock(uint256 lockId) public whenNotPaused {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (!lock.active) revert LockNotActive();
        if (lock.unlocked) revert LockAlreadyUnlocked(); // Primary unlocked state

        bool isRecipient = false;
        for (uint i = 0; i < lock.recipients.length; i++) {
            if (lock.recipients[i] == msg.sender) {
                isRecipient = true;
                break;
            }
        }
        if (!isRecipient) revert NotRecipient();

        // Check if this recipient has already unlocked their share
        if (recipientUnlockedShare[lockId][msg.sender]) {
            // This recipient has already claimed their share, even if the lock isn't fully unlocked
            // (relevant if amount > 0 and recipients > 1)
            revert LockAlreadyUnlocked();
        }

        // Check all conditions required for the lock
        bool timeConditionMet = block.timestamp >= lock.endTime;
        bool multiSigConditionMet = !lock.requiresMultiSig || (lock.currentConfirmations >= lock.requiredConfirmations);
        bool externalDataConditionMet = !lock.requiresExternalData || (currentExternalDataValue >= lock.requiredExternalDataValue);
        bool specificInteractionConditionMet = !lock.requiresSpecificInteraction || lock.specificInteractionConditionMet;

        // Check Recipient-Specific Merkle Proof Condition
        bool merkleProofConditionMet = !lock.requiresMerkleProof || merkleProofProvidedForLock[lockId][msg.sender];

        if (!(timeConditionMet && multiSigConditionMet && externalDataConditionMet && specificInteractionConditionMet && merkleProofConditionMet)) {
             revert ConditionsNotMet();
        }

        emit LockAttempted(lockId, msg.sender);

        uint256 recipientAmount = lock.amount / lock.recipients.length;
        if (recipientAmount == 0) revert RecipientAmountZero(); // Should not happen if amount > 0 and recipients > 0, but good check

        // Mark this recipient's share as unlocked
        recipientUnlockedShare[lockId][msg.sender] = true;

        // Transfer the recipient's share
        lockedToken.safeTransfer(msg.sender, recipientAmount);

        emit LockUnlocked(lockId, msg.sender, recipientAmount);

        // Check if all recipients have unlocked their share
        bool allRecipientsUnlocked = true;
        for(uint i = 0; i < lock.recipients.length; i++) {
            if (!recipientUnlockedShare[lockId][lock.recipients[i]]) {
                allRecipientsUnlocked = false;
                break;
            }
        }

        // If all recipients have claimed, mark the entire lock as fully unlocked and inactive
        if (allRecipientsUnlocked) {
            lock.unlocked = true;
            lock.active = false;
        }
    }

    // --- Condition Management ---

    /// @notice Sets the address authorized to act as the oracle.
    /// @param _oracleAddress The address of the oracle.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
    }

    /// @notice Updates the global external data value used for lock conditions.
    /// Can only be called by the designated oracle address.
    /// @param _newValue The new value for the external data.
    function updateExternalDataValue(uint256 _newValue) public onlyOracle whenNotPaused {
        currentExternalDataValue = _newValue;
        emit ExternalDataValueUpdated(_newValue);
    }

    /// @notice Updates the global Merkle root used for Merkle proof conditions.
    /// Can only be called by the designated oracle address or owner.
    /// @param _newRoot The new Merkle root.
    function setMerkleRoot(bytes32 _newRoot) public whenNotPaused {
        if (msg.sender != owner() && msg.sender != oracleAddress) revert OracleOnly(); // Owner or Oracle

        currentMerkleRoot = _newRoot;
        emit MerkleRootUpdated(_newRoot);
    }

    /// @notice Allows a recipient to provide a Merkle proof for a lock requiring one.
    /// Verifies the proof against the current root and lock's required leaf.
    /// @param lockId The ID of the lock.
    /// @param proof The Merkle proof array.
    function provideMerkleProof(uint256 lockId, bytes32[] calldata proof) public whenNotPaused {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (!lock.active) revert LockNotActive();
        if (!lock.requiresMerkleProof) revert MerkleProofNotRequired();

        bool isRecipient = false;
        for (uint i = 0; i < lock.recipients.length; i++) {
            if (lock.recipients[i] == msg.sender) {
                isRecipient = true;
                break;
            }
        }
        if (!isRecipient) revert NotRecipient();

        if (merkleProofProvidedForLock[lockId][msg.sender]) revert MerkleProofAlreadyProvided();

        // Verify the proof. The required leaf is stored in the lock struct.
        // The leaf should typically represent the recipient's identity or a hash thereof,
        // included in the Merkle tree set by the oracle.
        // Example: MerkleProof.verify(proof, currentMerkleRoot, keccak256(abi.encodePacked(msg.sender, lock.requiredMerkleLeaf)));
        // For simplicity here, we assume the requiredMerkleLeaf *is* the leaf the user provides proof for.
        // In a real scenario, the required leaf would be structured data related to the recipient.
        bytes32 recipientLeaf = keccak256(abi.encodePacked(msg.sender)); // Example leaf format
        if (lock.requiredMerkleLeaf != recipientLeaf) revert MerkleProofVerificationFailed(); // The leaf doesn't match what the lock expects this recipient to prove.

        if (!MerkleProof.verify(proof, currentMerkleRoot, recipientLeaf)) {
             revert MerkleProofVerificationFailed();
        }

        merkleProofProvidedForLock[lockId][msg.sender] = true;
        emit MerkleProofProvided(lockId, msg.sender);
    }

     /// @notice Sets the address authorized to trigger specific interaction conditions.
    /// @param _triggerAddress The address of the interaction trigger.
    function setInteractionTriggerAddress(address _triggerAddress) public onlyOwner {
        interactionTriggerAddress = _triggerAddress;
    }

    /// @notice Allows the designated interaction trigger address to set the interaction flag for a lock.
    /// @param lockId The ID of the lock.
    function triggerSpecificInteractionCondition(uint256 lockId) public onlyInteractionTrigger whenNotPaused {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (!lock.active) revert LockNotActive();
        if (!lock.requiresSpecificInteraction) revert SpecificInteractionConditionNotRequired();

        lock.specificInteractionConditionMet = true;
        emit InteractionTriggered(lockId);
    }

    /// @notice Allows a recipient to confirm their participation for a multi-sig condition lock.
    /// @param lockId The ID of the lock.
    function confirmMultiSigCondition(uint256 lockId) public whenNotPaused {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (!lock.active) revert LockNotActive();
        if (!lock.requiresMultiSig) revert MultiSigConditionNotRequired();

        bool isRecipient = false;
        for (uint i = 0; i < lock.recipients.length; i++) {
            if (lock.recipients[i] == msg.sender) {
                isRecipient = true;
                break;
            }
        }
        if (!isRecipient) revert NotRecipient();

        if (lock.multiSigConfirmed[msg.sender]) revert AlreadyConfirmedMultiSig();

        lock.multiSigConfirmed[msg.sender] = true;
        lock.currentConfirmations++;
        emit MultiSigConfirmed(lockId, msg.sender, lock.currentConfirmations);
    }

    /// @notice View function to check if the multi-sig condition is currently met for a lock.
    /// @param lockId The ID of the lock.
    /// @return bool True if required confirmations are met or multi-sig is not required.
    function isMultiSigConditionMet(uint256 lockId) public view returns (bool) {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist(); // Or handle gracefully if view functions shouldn't revert
        return !lock.requiresMultiSig || (lock.currentConfirmations >= lock.requiredConfirmations);
    }

    /// @notice View function to get the number of pending multi-sig confirmations for a lock.
    /// @param lockId The ID of the lock.
    /// @return uint256 Number of confirmations still needed. Returns 0 if condition met or not required.
    function getPendingMultiSigConfirmations(uint256 lockId) public view returns (uint256) {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0 || !lock.requiresMultiSig) return 0;
        if (lock.currentConfirmations >= lock.requiredConfirmations) return 0;
        return lock.requiredConfirmations - lock.currentConfirmations;
    }

    // --- Lock Management ---

    /// @notice View function to retrieve the details of a specific lock.
    /// @param lockId The ID of the lock.
    /// @return QuantumLock The struct containing the lock's details.
    function getLockDetails(uint256 lockId) public view returns (QuantumLock storage) {
         // Accessing directly via public mapping getter
        if (quantumLocks[lockId].lockId == 0) revert LockDoesNotExist(); // Add check
        return quantumLocks[lockId];
    }

     /// @notice View function to get all lock IDs associated with a user (as locker or recipient).
    /// @param user The address of the user.
    /// @return uint256[] An array of lock IDs.
    function getUserLockIds(address user) public view returns (uint256[] storage) {
        // Accessing directly via public mapping getter
        return userLockIds[user];
    }

    /// @notice Allows the locker to initiate early cancellation of a lock before its end time.
    /// The tokens become available for withdrawal by the locker, subject to a penalty.
    /// @param lockId The ID of the lock to cancel.
    function cancelLockByLocker(uint256 lockId) public whenNotPaused {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (lock.locker != msg.sender) revert NotLocker();
        if (!lock.active) revert LockNotActive();
        if (lock.cancelled) revert LockAlreadyCancelled();
        if (lock.unlocked) revert LockAlreadyUnlocked(); // Cannot cancel if already unlocked

        if (block.timestamp >= lock.endTime) revert LockNotExpired(); // Cannot 'early' cancel after end time

        lock.active = false; // Deactivate the lock for recipients
        lock.cancelled = true; // Mark as cancelled by locker

        emit LockCancelled(lockId, msg.sender);
    }

    /// @notice Allows the locker to withdraw tokens after successfully cancelling a lock.
    /// Applies the early cancellation penalty.
    /// @param lockId The ID of the cancelled lock.
    function withdrawCancelledTokens(uint256 lockId) public whenNotPaused {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (lock.locker != msg.sender) revert NotLocker();
        if (!lock.cancelled) revert LockNotCancelled();
        if (lock.amount == 0) return; // Already withdrawn or zero amount

        uint256 penalty = calculateCancellationPenalty(lockId);
        uint256 amountToWithdraw = lock.amount.sub(penalty);

        // Set amount to 0 to prevent double withdrawal
        lock.amount = 0;

        lockedToken.safeTransfer(msg.sender, amountToWithdraw);

        emit CancelledTokensWithdrawn(lockId, msg.sender, amountToWithdraw, penalty);
    }

    /// @notice Allows the locker to reclaim tokens from an expired lock if it was never unlocked by recipients.
    /// @param lockId The ID of the lock to reclaim.
    function reclaimExpiredLock(uint256 lockId) public whenNotPaused {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) revert LockDoesNotExist();
        if (lock.locker != msg.sender) revert NotLocker();
        if (lock.active) revert LockStillActive(); // Must be inactive to reclaim this way

        // Check if it expired without unlock
        if (block.timestamp < lock.endTime) revert LockNotExpired();
        if (lock.unlocked) revert LockAlreadyUnlocked();
        if (lock.cancelled) revert LockAlreadyCancelled(); // Handled by withdrawCancelledTokens

        if (lock.amount == 0) return; // Already withdrawn or zero amount

        uint256 amountToReclaim = lock.amount;

        // Set amount to 0 to prevent double withdrawal
        lock.amount = 0;
        lock.active = false; // Ensure it's inactive

        lockedToken.safeTransfer(msg.sender, amountToReclaim);

        emit ExpiredLockReclaimed(lockId, msg.sender, amountToReclaim);
    }

    // --- Admin / Utility ---

    /// @notice Sets the penalty rate for early cancellation in basis points.
    /// 10000 basis points = 100%.
    /// @param rateInBasisPoints The penalty rate (0-10000).
    function setEarlyCancellationPenaltyRate(uint256 rateInBasisPoints) public onlyOwner whenNotPaused {
        if (rateInBasisPoints > 10000) revert PenaltyRateInvalid();
        earlyCancellationPenaltyRate = rateInBasisPoints;
        emit EarlyCancellationPenaltyRateUpdated(rateInBasisPoints);
    }

    /// @notice View function to calculate the penalty for early cancellation of a lock.
    /// @param lockId The ID of the lock.
    /// @return uint256 The calculated penalty amount.
    function calculateCancellationPenalty(uint256 lockId) public view returns (uint256) {
        QuantumLock storage lock = quantumLocks[lockId];
        if (lock.lockId == 0) return 0; // Or revert, depending on desired behavior for non-existent locks

        // Penalty applies only if cancelled early
        if (block.timestamp >= lock.endTime || lock.amount == 0) {
            return 0;
        }

        // Calculate penalty: (amount * rate) / 10000
        return lock.amount.mul(earlyCancellationPenaltyRate).div(10000);
    }

    /// @notice View function to get the contract's current balance of the locked token.
    /// @return uint256 The contract's token balance.
    function getVaultBalance() public view returns (uint256) {
        return lockedToken.balanceOf(address(this));
    }

    /// @notice View function to calculate the amount each recipient receives upon successful unlock.
    /// @param lockId The ID of the lock.
    /// @return uint256 The amount per recipient.
    function getRecipientUnlockAmount(uint256 lockId) public view returns (uint256) {
        QuantumLock storage lock = quantumLocks[lockId];
         if (lock.lockId == 0) revert LockDoesNotExist();
         if (lock.recipients.length == 0) return 0; // Should not happen based on create lock checks
         return lock.amount / lock.recipients.length;
    }

    /// @notice View function to check if the Merkle proof condition has been met by a specific recipient for a lock.
    /// @param lockId The ID of the lock.
    /// @param recipient The address of the recipient.
    /// @return bool True if the proof has been provided successfully by the recipient.
    function checkMerkleProofProvided(uint256 lockId, address recipient) public view returns (bool) {
        // Check existence first
        if (quantumLocks[lockId].lockId == 0) return false;
        return merkleProofProvidedForLock[lockId][recipient];
    }

    // Owner functions inherited from Ownable:
    // transferOwnership(address newOwner)
    // renounceOwnership()
    // owner() - view function

    // Pausable functions inherited from Pausable:
    // paused() - view function

}
```