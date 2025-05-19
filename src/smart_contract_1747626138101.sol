Okay, here is a Solidity smart contract designed around an advanced concept I'll call a "Quantum Vault". This contract manages ERC20 tokens but access isn't based on simple ownership or approval. Instead, withdrawal and state transitions depend on a combination of time-based locks, simulated external "signals" (representing oracle input or complex conditions), administrator actions, and a user-solvable "chronomatic puzzle".

It aims for creativity by having distinct, non-linear access states and requiring users/admins to interact in specific ways to move between states or unlock funds. It avoids duplicating standard patterns like simple vesting, multi-sig (though admin roles exist), or standard NFT mechanics.

---

**QuantumVault.sol**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version, import ERC20 interface.
2.  **Errors:** Define custom errors for clarity.
3.  **Events:** Define events for state changes, deposits, withdrawals, admin actions, puzzle events.
4.  **Enums:** Define the possible states of the Quantum Vault.
5.  **State Variables:**
    *   ERC20 token address.
    *   Current Vault State.
    *   Mapping for user token balances within the vault.
    *   Admin role management.
    *   ChronoLock parameters (unlock timestamp, duration config).
    *   Simulated Entanglement Signal parameters (required signal, current signal).
    *   Simulated Singularity Conditions (boolean flags or simple values).
    *   Singularity Proofs (mapping user => assignment timestamp).
    *   Singularity Proof Validity Duration.
    *   Chronomatic Puzzle parameters (target hash, user attempt storage, solved status).
    *   Emergency Withdrawal parameters (unlock timestamp, lock duration config).
    *   Mapping to track emergency withdrawal initiation by admins.
    *   Total token balance in the contract (redundant with token balance query, but useful for views).
6.  **Modifiers:**
    *   `onlyAdmin`: Restricts function calls to addresses with the admin role.
7.  **Constructor:** Initializes the contract, sets the ERC20 token address, and assigns the deployer as the initial admin.
8.  **Core Functionality:**
    *   `deposit`: Allows users to deposit ERC20 tokens.
    *   `withdraw`: The primary withdrawal function. Its behavior and required conditions depend entirely on the current `vaultState`.
9.  **State Management (Admin Only):**
    *   `transitionState`: A central function to transition the vault between different states based on provided parameters and validation.
    *   Helper functions for specific state transitions (called internally by `transitionState` or explicitly if preferred, but a single entry point is cleaner).
10. **Conditional Parameter Management (Admin Only):**
    *   `setChronoLockDuration`: Configures how long the vault stays locked in ChronoLocked state.
    *   `updateSimulatedEntanglementSignal`: Updates the current simulated external signal.
    *   `setRequiredEntanglementSignal`: Sets the signal value required for Entangled state withdrawal.
    *   `updateSimulatedSingularityConditions`: Updates the simulated conditions for Singularity state.
    *   `setSingularityProofValidityDuration`: Sets how long a Singularity Proof is valid.
    *   `setChronomaticPuzzleHash`: Sets the hash users must find to solve the puzzle.
11. **User Interaction Functions:**
    *   `submitChronomaticPuzzleAttempt`: Users submit attempts to solve the puzzle. Successful attempt grants Singularity Proof.
12. **Admin Role Management (Owner Only):**
    *   `addAdmin`: Grants admin role.
    *   `removeAdmin`: Revokes admin role.
13. **Emergency Functions:**
    *   `initiateEmergencyWithdrawal`: Admins (possibly multiple or time-locked) can initiate emergency withdrawal if in Emergency state.
    *   `cancelEmergencyWithdrawal`: Owner can cancel an initiated emergency withdrawal.
    *   `executeEmergencyWithdrawal`: Executes the time-locked emergency withdrawal to owner.
    *   `setEmergencyWithdrawLockDuration`: Owner sets the delay for emergency withdrawals.
14. **View Functions (Query State and Conditions):**
    *   `getVaultState`: Returns the current state.
    *   `isWithdrawConditionMet`: Checks if the *caller* can withdraw based on the current state and their status.
    *   `getChronoUnlockTimestamp`: Returns the unlock time if in ChronoLocked state.
    *   `getChronoLockDuration`: Returns the configured duration for ChronoLock.
    *   `getCurrentEntanglementSignal`: Returns the current simulated signal.
    *   `getRequiredEntanglementSignal`: Returns the signal needed for Entangled state withdrawal.
    *   `getSimulatedSingularityConditions`: Returns the current simulated conditions for Singularity.
    *   `getUserSingularityProofStatus`: Returns if a user has a valid Singularity Proof and its assignment time.
    *   `getSingularityProofValidityDuration`: Returns the validity duration for proofs.
    *   `hasSolvedChronomaticPuzzle`: Returns if a user has solved the puzzle.
    *   `getChronomaticPuzzleHash`: Returns the target hash for the puzzle.
    *   `getLastPuzzleAttemptHash`: Returns the user's last puzzle attempt hash.
    *   `isAdmin`: Checks if an address is an admin.
    *   `getEmergencyWithdrawUnlockTime`: Returns the unlock time for emergency withdrawal.
    *   `getEmergencyWithdrawLockDuration`: Returns the configured lock duration for emergency withdrawal.
    *   `isEmergencyWithdrawalInitiated`: Checks if emergency withdrawal is initiated by an admin.
    *   `getUserTokenBalanceInVault`: Returns a user's deposited balance.
    *   `getTotalVaultBalance`: Returns the total balance of tokens held by the contract.

---

**Function Summary (Total: 35)**

1.  `constructor(address initialTokenAddress)`: Deploys the contract, sets the token, makes deployer admin.
2.  `deposit(uint256 amount)`: Allows depositing ERC20 tokens into the user's balance in the vault.
3.  `withdraw(uint256 amount)`: Attempts to withdraw tokens. Logic depends on `vaultState` and meeting specific state conditions.
4.  `getVaultState()`: (View) Returns the current state of the vault.
5.  `transitionState(VaultState newState, bytes32 paramHash)`: (Admin) Initiates a state transition. `paramHash` holds state-specific transition data (e.g., a hash of required conditions or parameters for the new state). Checks vary by `newState`.
    *   Handles transitions: `Initial -> ChronoLocked`, `ChronoLocked -> Entangled`, `Entangled -> Singularity`, `Any -> Emergency`, `Emergency -> Initial` (requires specific conditions).
6.  `setChronoLockDuration(uint256 duration)`: (Admin) Sets the default duration for future `ChronoLocked` states.
7.  `updateSimulatedEntanglementSignal(bytes32 signal)`: (Admin) Updates the external signal simulation.
8.  `setRequiredEntanglementSignal(bytes32 signal)`: (Admin) Sets the signal required for withdrawal in `Entangled` state.
9.  `updateSimulatedSingularityConditions(bool cond1, bool cond2, uint256 value)`: (Admin) Updates simulated external conditions needed for `Singularity` state access/transition.
10. `isWithdrawConditionMet(address user)`: (View) Checks if a given `user` is currently eligible to withdraw based on the current state and *their* status (proofs, puzzle, etc.).
11. `getChronoUnlockTimestamp()`: (View) Returns the block timestamp when the current `ChronoLocked` state unlocks.
12. `getChronoLockDuration()`: (View) Returns the configured ChronoLock duration.
13. `getCurrentEntanglementSignal()`: (View) Returns the current simulated entanglement signal.
14. `getRequiredEntanglementSignal()`: (View) Returns the entanglement signal required for `Entangled` state withdrawal.
15. `getSimulatedSingularityConditions()`: (View) Returns the current simulated conditions for `Singularity` state.
16. `addAdmin(address newAdmin)`: (Owner) Grants admin privileges to an address.
17. `removeAdmin(address adminToRemove)`: (Owner) Revokes admin privileges from an address.
18. `isAdmin(address account)`: (View) Checks if an address has admin privileges.
19. `initiateEmergencyWithdrawal()`: (Admin) Initiates a time-locked emergency withdrawal of all funds to the owner, but only if in `Emergency` state. Multiple admin confirmations could be added for more complexity.
20. `cancelEmergencyWithdrawal()`: (Owner) Cancels an emergency withdrawal initiated by an admin.
21. `executeEmergencyWithdrawal()`: (Owner) Executes the emergency withdrawal *after* the lock duration has passed, but only if initiated and not cancelled.
22. `setEmergencyWithdrawLockDuration(uint256 duration)`: (Owner) Sets the time lock duration for admin-initiated emergency withdrawals.
23. `getEmergencyWithdrawUnlockTime()`: (View) Returns the timestamp when an initiated emergency withdrawal can be executed.
24. `getEmergencyWithdrawLockDuration()`: (View) Returns the configured emergency withdrawal lock duration.
25. `getUserSingularityProofStatus(address user)`: (View) Returns boolean and timestamp indicating if a user has a valid Singularity Proof and when it was assigned.
26. `grantSingularityProof(address user)`: (Internal) Assigns a Singularity Proof to a user with the current timestamp. Called upon successful puzzle solve.
27. `revokeSingularityProof(address user)`: (Admin) Revokes a user's Singularity Proof.
28. `getSingularityProofAssignmentTime(address user)`: (View) Returns the timestamp when a user's Singularity Proof was assigned.
29. `setSingularityProofValidityDuration(uint256 duration)`: (Admin) Sets how long a Singularity Proof remains valid.
30. `getSingularityProofValidityDuration()`: (View) Returns the validity duration for Singularity Proofs.
31. `getTotalVaultBalance()`: (View) Returns the total ERC20 token balance held by the contract address.
32. `getUserTokenBalanceInVault(address user)`: (View) Returns the balance of tokens a specific user has deposited in the vault.
33. `setChronomaticPuzzleHash(bytes32 puzzleHash)`: (Admin) Sets the target hash for the Chronomatic Puzzle.
34. `submitChronomaticPuzzleAttempt(bytes memory attemptData)`: (User) Submits data. The hash of this data is compared to the target puzzle hash. If it matches, the user is granted a Singularity Proof and marked as having solved the puzzle.
35. `getChronomaticPuzzleHash()`: (View) Returns the target hash of the Chronomatic Puzzle.
36. `getLastPuzzleAttemptHash(address user)`: (View) Returns the hash of the last puzzle attempt submitted by a user.
37. `hasSolvedChronomaticPuzzle(address user)`: (View) Returns true if the user has successfully solved the puzzle.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint255 value); // Note: ERC20 standard is uint256, but some old interfaces might use uint255. Sticking to common uint256.
}


/// @title QuantumVault
/// @notice A complex ERC20 token vault with multiple access states and conditions.
/// @dev This contract demonstrates advanced concepts like state-dependent logic, time locks,
/// simulated external signals, admin roles, user-specific proofs earned via a puzzle,
/// and an emergency recovery mechanism. It is NOT audited or intended for production use
/// without extensive security review.

contract QuantumVault {

    // --- Errors ---
    error NotAdmin(address caller);
    error NotOwner(address caller);
    error InvalidStateTransition(VaultState currentState, VaultState newState);
    error VaultLocked(VaultState currentState);
    error InsufficientBalance(uint256 requested, uint256 available);
    error ChronoLockNotExpired(uint256 unlockTime);
    error EntanglementSignalMismatch(bytes32 currentSignal, bytes32 requiredSignal);
    error SingularityProofRequired();
    error SingularityProofInvalid(address user);
    error SingularityConditionsNotMet();
    error EmergencyWithdrawalNotInitiated();
    error EmergencyWithdrawalLockActive(uint256 unlockTime);
    error EmergencyWithdrawalAlreadyInitiated();
    error EmergencyWithdrawalNotInEmergencyState();
    error EmergencyWithdrawalNotYetCancellable(); // Could add a lock period for cancellation
    error PuzzleAlreadySolved();
    error InvalidPuzzleAttempt();
    error CannotTransitionToSelf(VaultState currentState);
    error InvalidTransitionParameters();
    error TokenTransferFailed();

    // --- Events ---
    event VaultStateChanged(VaultState indexed oldState, VaultState indexed newState, bytes32 paramHash);
    event TokensDeposited(address indexed user, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount, VaultState indexed state);
    event AdminAdded(address indexed newAdmin, address indexed addedBy);
    event AdminRemoved(address indexed admin, address indexed removedBy);
    event ChronoLockDurationUpdated(uint256 newDuration);
    event SimulatedEntanglementSignalUpdated(bytes32 signal);
    event RequiredEntanglementSignalUpdated(bytes32 signal);
    event SimulatedSingularityConditionsUpdated(bool cond1, bool cond2, uint256 value);
    event SingularityProofAssigned(address indexed user, uint256 timestamp);
    event SingularityProofRevoked(address indexed user);
    event SingularityProofValidityDurationUpdated(uint256 newDuration);
    event ChronomaticPuzzleHashSet(bytes32 indexed puzzleHash);
    event ChronomaticPuzzleAttemptSubmitted(address indexed user, bytes32 indexed attemptHash);
    event ChronomaticPuzzleSolved(address indexed user, bytes32 indexed puzzleHash);
    event EmergencyWithdrawalInitiated(address indexed initiator, uint256 unlockTime);
    event EmergencyWithdrawalCancelled(address indexed canceller);
    event EmergencyWithdrawalExecuted(address indexed recipient, uint256 amount);
    event EmergencyWithdrawLockDurationUpdated(uint256 newDuration);

    // --- Enums ---
    enum VaultState {
        Initial,       // Basic deposit/withdraw (maybe restricted, or open)
        ChronoLocked,  // Locked until a specific time
        Entangled,     // Access depends on a simulated external signal match
        Singularity,   // Access depends on having a valid user-specific proof (earned via puzzle) AND simulated conditions
        Emergency      // Restricted access, typically for admin emergency actions
    }

    // --- State Variables ---
    IERC20 public immutable token;
    address private _owner; // Owner is the primary admin, but also has special privileges (like cancelling emergency)

    mapping(address => bool) private _admins; // Addresses with admin privileges
    mapping(address => uint256) private userBalances; // User balances within the vault

    VaultState public vaultState;

    // ChronoLocked State
    uint256 public chronoUnlockTimestamp; // When ChronoLocked state unlocks
    uint256 public chronoLockDuration = 365 days; // Default duration for new ChronoLocks

    // Entangled State
    bytes32 public currentEntanglementSignal; // Simulated external signal
    bytes32 public requiredEntanglementSignal; // Signal needed for withdrawal

    // Singularity State
    mapping(address => uint256) public singularityProofAssignmentTime; // Timestamp when proof was assigned (0 if none)
    uint256 public singularityProofValidityDuration = 90 days; // How long the proof is valid
    // Simulated external conditions required *in addition* to proof for Singularity withdrawal
    bool public singularityCond1 = false;
    bool public singularityCond2 = false;
    uint256 public singularityValue = 0;

    // Chronomatic Puzzle (Grants Singularity Proof)
    bytes32 public chronomaticPuzzleHash; // Target hash to solve
    mapping(address => bytes32) public lastPuzzleAttemptHash; // Last hash submitted by user
    mapping(address => bool) public hasSolvedChronomaticPuzzle; // Whether user has solved the puzzle

    // Emergency State
    uint256 public emergencyWithdrawLockDuration = 7 days; // Time lock for emergency withdrawal execution
    uint256 public emergencyWithdrawUnlockTime; // Timestamp when emergency withdrawal can be executed
    bool public emergencyWithdrawalInitiated = false;
    // Could add multi-sig initiation here (e.g., mapping admin => bool initiated)

    // Cache total balance (optional, can calculate from token.balanceOf(address(this)))
    uint256 private _totalVaultBalance;

    // --- Modifiers ---
    modifier onlyAdmin() {
        if (!_admins[msg.sender]) revert NotAdmin(msg.sender);
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner(msg.sender);
        _;
    }

    // --- Constructor ---
    /// @param initialTokenAddress Address of the ERC20 token this vault will hold.
    constructor(address initialTokenAddress) {
        token = IERC20(initialTokenAddress);
        _owner = msg.sender;
        _admins[msg.sender] = true; // Deployer is the initial admin
        vaultState = VaultState.Initial;
        emit AdminAdded(msg.sender, address(0)); // Use address(0) for deployer
    }

    // --- Core Functionality ---

    /// @notice Deposits ERC20 tokens into the vault.
    /// @dev Requires the user to have approved this contract to spend the tokens.
    /// @param amount The amount of tokens to deposit.
    function deposit(uint256 amount) external {
        if (amount == 0) return; // Do nothing for zero deposit
        uint256 contractBalanceBefore = token.balanceOf(address(this));

        // Using transferFrom requires the sender to have approved this contract first
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TokenTransferFailed();

        // Verify the balance increased by the expected amount (basic check against inflation bugs)
        // This is a simplification; robust checks involve pre- and post-transfer balances
        uint256 contractBalanceAfter = token.balanceOf(address(this));
        if (contractBalanceAfter < contractBalanceBefore + amount) revert TokenTransferFailed(); // TransferFrom failed or token has fee/rebasing

        userBalances[msg.sender] += amount;
        _totalVaultBalance += amount;
        emit TokensDeposited(msg.sender, amount);
    }

    /// @notice Attempts to withdraw tokens from the vault.
    /// @dev Withdrawal conditions vary based on the current vault state.
    /// @param amount The amount of tokens to withdraw.
    function withdraw(uint256 amount) external {
        if (amount == 0) return;
        if (userBalances[msg.sender] < amount) revert InsufficientBalance(amount, userBalances[msg.sender]);

        bool withdrawAllowed = false;

        // Check withdrawal conditions based on the current state
        if (vaultState == VaultState.Initial) {
            // Initial state: Maybe allow simple withdrawal? Let's make it simple here.
            withdrawAllowed = true;
        } else if (vaultState == VaultState.ChronoLocked) {
            // ChronoLocked state: Access only after unlock timestamp
            if (block.timestamp >= chronoUnlockTimestamp) {
                withdrawAllowed = true;
            } else {
                revert ChronoLockNotExpired(chronoUnlockTimestamp);
            }
        } else if (vaultState == VaultState.Entangled) {
            // Entangled state: Access only if simulated signal matches
            if (currentEntanglementSignal == requiredEntanglementSignal) {
                withdrawAllowed = true;
            } else {
                revert EntanglementSignalMismatch(currentEntanglementSignal, requiredEntanglementSignal);
            }
        } else if (vaultState == VaultState.Singularity) {
            // Singularity state: Access requires a valid proof AND simulated conditions
            if (!getUserSingularityProofStatus(msg.sender)) revert SingularityProofRequired(); // Checks validity and assignment time
            if (singularityCond1 && singularityCond2 && singularityValue > 0) { // Example complex condition
                 withdrawAllowed = true;
            } else {
                revert SingularityConditionsNotMet();
            }
        } else if (vaultState == VaultState.Emergency) {
             // Emergency state: No standard withdrawals allowed, only emergency mechanism
             revert VaultLocked(vaultState);
        }

        if (withdrawAllowed) {
            userBalances[msg.sender] -= amount;
            _totalVaultBalance -= amount;
            bool success = token.transfer(msg.sender, amount);
            if (!success) {
                // Revert the state changes if transfer fails
                userBalances[msg.sender] += amount;
                _totalVaultBalance += amount;
                revert TokenTransferFailed();
            }
            emit TokensWithdrawn(msg.sender, amount, vaultState);
        } else {
             // This should ideally not be reached if conditions are correctly checked above,
             // but as a fallback for states that don't allow withdrawal.
             revert VaultLocked(vaultState);
        }
    }

    // --- State Management (Admin Only) ---

    /// @notice Transitions the vault to a new state.
    /// @dev State transitions have specific requirements and can set parameters for the new state.
    /// @param newState The target state to transition to.
    /// @param paramHash A hash containing parameters specific to the transition. Interpretation depends on newState.
    ///                  - ChronoLocked: Hash could encode the duration (or use default)
    ///                  - Entangled: Hash could encode the required signal
    ///                  - Singularity: Hash could encode required external conditions
    ///                  - Emergency: Hash could be unused or for logging
    function transitionState(VaultState newState, bytes32 paramHash) external onlyAdmin {
        if (vaultState == newState) revert CannotTransitionToSelf(vaultState);

        VaultState oldState = vaultState;
        vaultState = newState; // Transition first, then set parameters based on the new state

        if (newState == VaultState.Initial) {
             // Transition to Initial: No specific parameters usually, maybe reset some states?
             // For simplicity, no specific params needed for this transition.
        } else if (newState == VaultState.ChronoLocked) {
            // Transition to ChronoLocked: Set the unlock timestamp.
            // paramHash could potentially override the default chronoLockDuration,
            // but we'll use the default for simplicity here, and paramHash for event logging.
            chronoUnlockTimestamp = block.timestamp + chronoLockDuration;
        } else if (newState == VaultState.Entangled) {
            // Transition to Entangled: Maybe paramHash is the required signal? Or admin sets separately?
            // Let's require admin to set requiredSignal separately. paramHash for logging.
            // Add check if requiredSignal is set? Not strictly needed for transition, but good practice.
            if (requiredEntanglementSignal == bytes32(0)) {
                 // Optional: require required signal to be set before entering Entangled state
                 // revert InvalidTransitionParameters();
            }
        } else if (newState == VaultState.Singularity) {
            // Transition to Singularity: Access depends on simulated conditions and user proof.
            // paramHash could encode required conditions, but we update those separately via updateSimulatedSingularityConditions.
            // Add check if simulated conditions are set? Not strictly needed.
        } else if (newState == VaultState.Emergency) {
            // Transition to Emergency: Allows admin to initiate recovery after a delay.
            // Emergency withdrawal initiation is separate, triggered by initiateEmergencyWithdrawal.
            // paramHash for logging.
        } else {
            // Should not happen with enum
             revert InvalidStateTransition(oldState, newState);
        }

        // Specific transition logic/checks if needed (e.g., can't go Initial -> Singularity directly)
        // For this contract, direct transitions are allowed by design for flexibility,
        // but real-world use might restrict them.

        emit VaultStateChanged(oldState, newState, paramHash);
    }

    // --- Conditional Parameter Management (Admin Only) ---

    /// @notice Sets the default duration for the ChronoLocked state.
    /// @param duration The new duration in seconds.
    function setChronoLockDuration(uint256 duration) external onlyAdmin {
        chronoLockDuration = duration;
        emit ChronoLockDurationUpdated(duration);
    }

    /// @notice Updates the simulated external entanglement signal.
    /// @dev This simulates an oracle or external system feed.
    /// @param signal The new simulated signal value.
    function updateSimulatedEntanglementSignal(bytes32 signal) external onlyAdmin {
        currentEntanglementSignal = signal;
        emit SimulatedEntanglementSignalUpdated(signal);
    }

    /// @notice Sets the entanglement signal required for withdrawal in Entangled state.
    /// @param signal The required signal value.
    function setRequiredEntanglementSignal(bytes32 signal) external onlyAdmin {
        requiredEntanglementSignal = signal;
        emit RequiredEntanglementSignalUpdated(signal);
    }

    /// @notice Updates the simulated external conditions required for Singularity state access/transition.
    /// @param cond1 First boolean condition.
    /// @param cond2 Second boolean condition.
    /// @param value Numeric condition value.
    function updateSimulatedSingularityConditions(bool cond1, bool cond2, uint256 value) external onlyAdmin {
        singularityCond1 = cond1;
        singularityCond2 = cond2;
        singularityValue = value;
        emit SimulatedSingularityConditionsUpdated(cond1, cond2, value);
    }

    /// @notice Sets how long a Singularity Proof is valid after being assigned.
    /// @param duration The validity duration in seconds.
    function setSingularityProofValidityDuration(uint256 duration) external onlyAdmin {
        singularityProofValidityDuration = duration;
        emit SingularityProofValidityDurationUpdated(duration);
    }

     /// @notice Sets the target hash for the Chronomatic Puzzle.
    /// @dev Users must find data whose hash matches this to earn a Singularity Proof.
    /// @param puzzleHash The target hash (e.g., keccak256("some secret phrase")).
    function setChronomaticPuzzleHash(bytes32 puzzleHash) external onlyAdmin {
        chronomaticPuzzleHash = puzzleHash;
        emit ChronomaticPuzzleHashSet(puzzleHash);
    }


    // --- User Interaction Functions ---

    /// @notice Submits an attempt to solve the Chronomatic Puzzle.
    /// @dev If the hash of the submitted data matches the target hash, the user earns a Singularity Proof.
    /// @param attemptData The data string or bytes representing the puzzle solution attempt.
    function submitChronomaticPuzzleAttempt(bytes memory attemptData) external {
        if (hasSolvedChronomaticPuzzle[msg.sender]) revert PuzzleAlreadySolved();
        if (chronomaticPuzzleHash == bytes32(0)) revert InvalidPuzzleAttempt(); // Puzzle not set yet

        bytes32 attemptHash = keccak256(attemptData);
        lastPuzzleAttemptHash[msg.sender] = attemptHash;
        emit ChronomaticPuzzleAttemptSubmitted(msg.sender, attemptHash);

        if (attemptHash == chronomaticPuzzleHash) {
            hasSolvedChronomaticPuzzle[msg.sender] = true;
            grantSingularityProof(msg.sender); // Grant the proof upon solving
            emit ChronomaticPuzzleSolved(msg.sender, chronomaticPuzzleHash);
        } else {
            revert InvalidPuzzleAttempt(); // Indicate attempt was wrong
        }
    }


    // --- Admin Role Management (Owner Only) ---

    /// @notice Grants admin privileges to an address.
    /// @param newAdmin The address to grant privileges to.
    function addAdmin(address newAdmin) external onlyOwner {
        if (!_admins[newAdmin]) {
            _admins[newAdmin] = true;
            emit AdminAdded(newAdmin, msg.sender);
        }
    }

    /// @notice Revokes admin privileges from an address.
    /// @dev Cannot remove the owner's admin privilege using this function.
    /// @param adminToRemove The address to revoke privileges from.
    function removeAdmin(address adminToRemove) external onlyOwner {
        if (adminToRemove == _owner) {
            // Owner's admin privilege cannot be removed via this function
            revert NotAdmin(adminToRemove); // Re-using error, or define new one
        }
        if (_admins[adminToRemove]) {
            _admins[adminToRemove] = false;
            emit AdminRemoved(adminToRemove, msg.sender);
        }
    }

    // --- Emergency Functions ---

    /// @notice Initiates a time-locked emergency withdrawal of all funds to the owner.
    /// @dev Only callable by admins when the vault is in the Emergency state.
    function initiateEmergencyWithdrawal() external onlyAdmin {
        if (vaultState != VaultState.Emergency) revert EmergencyWithdrawalNotInEmergencyState();
        if (emergencyWithdrawalInitiated) revert EmergencyWithdrawalAlreadyInitiated();

        emergencyWithdrawUnlockTime = block.timestamp + emergencyWithdrawLockDuration;
        emergencyWithdrawalInitiated = true;
        emit EmergencyWithdrawalInitiated(msg.sender, emergencyWithdrawUnlockTime);
    }

    /// @notice Cancels an initiated emergency withdrawal.
    /// @dev Only callable by the contract owner.
    function cancelEmergencyWithdrawal() external onlyOwner {
        if (!emergencyWithdrawalInitiated) revert EmergencyWithdrawalNotInitiated();
        // Optional: Add a time window during which it can be cancelled, e.g., within first 24 hours.
        // if (block.timestamp > emergencyWithdrawUnlockTime - 1 days) revert EmergencyWithdrawalNotYetCancellable(); // Example lock

        emergencyWithdrawalInitiated = false;
        // Reset unlock time? Not strictly needed if initiated flag is checked.
        emit EmergencyWithdrawalCancelled(msg.sender);
    }

    /// @notice Executes the emergency withdrawal after the lock duration has passed.
    /// @dev Only callable by the contract owner, and only if initiated and not cancelled.
    function executeEmergencyWithdrawal() external onlyOwner {
        if (!emergencyWithdrawalInitiated) revert EmergencyWithdrawalNotInitiated();
        if (block.timestamp < emergencyWithdrawUnlockTime) revert EmergencyWithdrawalLockActive(emergencyWithdrawUnlockTime);

        uint256 total = _totalVaultBalance; // Or token.balanceOf(address(this))
        if (total == 0) {
            // No funds to withdraw, reset state
            emergencyWithdrawalInitiated = false; // Reset flag even if no funds
            return;
        }

        _totalVaultBalance = 0;
        // Reset user balances? Depends on design. If emergency means total reset, clear mapping.
        // For now, just transfer total balance. User balances remain but cannot be withdrawn via standard flow.
        // A more complex design would require accounting for *which* user funds are withdrawn.
        // Here, emergency means 'drain the contract'.

        bool success = token.transfer(_owner, total);
        if (!success) {
             // If transfer fails, attempt to revert state changes (complex, might need manual intervention)
             // For simplicity, we assume transfer to owner will succeed.
            _totalVaultBalance = total; // Attempt to restore state on failure
            revert TokenTransferFailed();
        }

        emergencyWithdrawalInitiated = false; // Reset flag after successful execution
        emit EmergencyWithdrawalExecuted(_owner, total);
    }

    /// @notice Sets the time lock duration for admin-initiated emergency withdrawals.
    /// @dev Only callable by the contract owner.
    /// @param duration The new duration in seconds.
    function setEmergencyWithdrawLockDuration(uint256 duration) external onlyOwner {
        emergencyWithdrawLockDuration = duration;
        emit EmergencyWithdrawLockDurationUpdated(duration);
    }


    // --- Internal Helper Functions ---

    /// @dev Assigns a Singularity Proof to a user. Called internally, e.g., after puzzle solve.
    /// @param user The user address to assign the proof to.
    function grantSingularityProof(address user) internal {
        singularityProofAssignmentTime[user] = block.timestamp;
        // Also mark puzzle as solved if that's the trigger
        hasSolvedChronomaticPuzzle[user] = true;
        emit SingularityProofAssigned(user, block.timestamp);
    }


    // --- View Functions (Query State and Conditions) ---

    /// @notice Returns the current state of the vault.
    /// @return The current VaultState enum value.
    function getVaultState() external view returns (VaultState) {
        return vaultState;
    }

    /// @notice Checks if a user is currently eligible to withdraw based on the vault's state and their status.
    /// @dev This function checks the conditions without attempting withdrawal.
    /// @param user The address to check eligibility for.
    /// @return True if the user can withdraw in the current state, false otherwise.
    function isWithdrawConditionMet(address user) public view returns (bool) {
        if (userBalances[user] == 0) return false; // Cannot withdraw if balance is 0

        if (vaultState == VaultState.Initial) {
            return true; // Assuming Initial state allows withdrawal
        } else if (vaultState == VaultState.ChronoLocked) {
            return block.timestamp >= chronoUnlockTimestamp;
        } else if (vaultState == VaultState.Entangled) {
            return currentEntanglementSignal == requiredEntanglementSignal;
        } else if (vaultState == VaultState.Singularity) {
            // Requires valid proof AND simulated conditions
            bool hasValidProof = getUserSingularityProofStatus(user);
            bool simulatedConditionsMet = (singularityCond1 && singularityCond2 && singularityValue > 0);
            return hasValidProof && simulatedConditionsMet;
        } else { // VaultState.Emergency
            return false; // No standard withdrawal in Emergency
        }
    }

    /// @notice Returns the timestamp when the ChronoLocked state unlocks.
    /// @return The unlock timestamp. Returns 0 if not in ChronoLocked state or not set.
    function getChronoUnlockTimestamp() external view returns (uint256) {
        return chronoUnlockTimestamp;
    }

    /// @notice Returns the configured duration for new ChronoLocked states.
    /// @return The duration in seconds.
    function getChronoLockDuration() external view returns (uint256) {
        return chronoLockDuration;
    }

    /// @notice Returns the current simulated external entanglement signal.
    /// @return The current signal value.
    function getCurrentEntanglementSignal() external view returns (bytes32) {
        return currentEntanglementSignal;
    }

    /// @notice Returns the entanglement signal required for withdrawal in Entangled state.
    /// @return The required signal value.
    function getRequiredEntanglementSignal() external view returns (bytes32) {
        return requiredEntanglementSignal;
    }

    /// @notice Returns the current simulated external conditions required for Singularity state access.
    /// @return cond1, cond2, value The three condition variables.
    function getSimulatedSingularityConditions() external view returns (bool cond1, bool cond2, uint256 value) {
        return (singularityCond1, singularityCond2, singularityValue);
    }

    /// @notice Checks if a user has a valid Singularity Proof.
    /// @param user The address to check.
    /// @return isValid True if the user has a proof and it hasn't expired, false otherwise.
    /// @return assignmentTime The timestamp when the proof was assigned (0 if no proof).
    function getUserSingularityProofStatus(address user) public view returns (bool isValid, uint256 assignmentTime) {
        assignmentTime = singularityProofAssignmentTime[user];
        if (assignmentTime == 0) {
            return (false, 0); // No proof ever assigned
        }
        // Proof is valid if assigned and hasn't expired
        isValid = (block.timestamp < assignmentTime + singularityProofValidityDuration);
        return (isValid, assignmentTime);
    }

    /// @notice Returns the timestamp when a user's Singularity Proof was assigned.
    /// @param user The address to check.
    /// @return The assignment timestamp (0 if no proof).
    function getSingularityProofAssignmentTime(address user) external view returns (uint256) {
        return singularityProofAssignmentTime[user];
    }

    /// @notice Returns the configured validity duration for Singularity Proofs.
    /// @return The duration in seconds.
    function getSingularityProofValidityDuration() external view returns (uint256) {
        return singularityProofValidityDuration;
    }

     /// @notice Returns true if the given address has admin privileges.
    /// @param account The address to check.
    /// @return True if the account is an admin, false otherwise.
    function isAdmin(address account) external view returns (bool) {
        return _admins[account];
    }

    /// @notice Returns the timestamp when an initiated emergency withdrawal can be executed.
    /// @return The unlock timestamp (0 if not initiated).
    function getEmergencyWithdrawUnlockTime() external view returns (uint256) {
        return emergencyWithdrawUnlockTime;
    }

    /// @notice Returns the configured lock duration for admin-initiated emergency withdrawals.
    /// @return The duration in seconds.
    function getEmergencyWithdrawLockDuration() external view returns (uint256) {
        return emergencyWithdrawLockDuration;
    }

    /// @notice Checks if an emergency withdrawal has been initiated by an admin.
    /// @return True if initiated, false otherwise.
    function isEmergencyWithdrawalInitiated() external view returns (bool) {
        return emergencyWithdrawalInitiated;
    }

    /// @notice Returns the target hash for the Chronomatic Puzzle.
    /// @return The puzzle hash.
    function getChronomaticPuzzleHash() external view returns (bytes32) {
        return chronomaticPuzzleHash;
    }

    /// @notice Returns the hash of a user's last Chronomatic Puzzle attempt.
    /// @param user The address to check.
    /// @return The hash of the last attempt (bytes32(0) if no attempt).
    function getLastPuzzleAttemptHash(address user) external view returns (bytes32) {
        return lastPuzzleAttemptHash[user];
    }

    /// @notice Checks if a user has successfully solved the Chronomatic Puzzle.
    /// @param user The address to check.
    /// @return True if the user has solved the puzzle, false otherwise.
    function hasSolvedChronomaticPuzzle(address user) public view returns (bool) {
        return hasSolvedChronomaticPuzzle[user];
    }

    /// @notice Returns the amount of tokens a specific user has deposited in the vault.
    /// @param user The address to check.
    /// @return The user's balance within the vault.
    function getUserTokenBalanceInVault(address user) external view returns (uint256) {
        return userBalances[user];
    }

    /// @notice Returns the total amount of tokens held by the vault contract.
    /// @dev This reflects the actual token balance, which might differ from the sum of userBalances
    ///      in edge cases (e.g., token fees, or emergency withdrawal only taking contract balance).
    /// @return The total token balance of the contract.
    function getTotalVaultBalance() external view returns (uint256) {
        // It's safer to query the token contract directly for the true balance
        return token.balanceOf(address(this));
    }

    // Fallback/Receive functions (optional, but good practice if sending ETH)
    // receive() external payable { emit ReceivedETH(msg.sender, msg.value); }
    // fallback() external payable { emit ReceivedETH(msg.sender, msg.value); }
}
```