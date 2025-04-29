Okay, here is a smart contract concept called "QuantumVault". It uses a metaphorical "quantum state" machine to control access to funds, incorporating concepts like probabilistic state collapse, required "measurement stake", simulated "decoherence" over time, and distinct access rules based on the collapsed state. It's designed to be more complex and less conventional than standard vault or staking contracts.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **License & Pragma**
2.  **Imports** (Assuming OpenZeppelin Ownable)
3.  **Error Definitions**
4.  **Enums:** Define the possible states of the vault (Superposition, Collapsed_Secure, Collapsed_Accessible).
5.  **State Variables:**
    *   Owner address.
    *   Current vault state.
    *   Configurable parameters (measurement probability, decoherence time, stake amounts, fees, hashes).
    *   Mappings for user stakes and access tracking.
    *   Timestamps for state changes.
    *   Counts for successful measurements/accesses.
6.  **Events:** Signal state changes, deposits, withdrawals, stake actions, parameter updates.
7.  **Modifiers:** Restrict function access (e.g., onlyOwner, whenStateIs).
8.  **Function Summary:** Detailed breakdown of each function's purpose.
9.  **Constructor:** Initialize owner and default parameters/state.
10. **Receive/Fallback:** Allow the contract to receive Ether.
11. **Core State Management Functions:**
    *   Checking current state.
    *   Attempting probabilistic state collapse (`attemptMeasurement`).
    *   Triggering state decay/decoherence (`checkAndApplyDecoherence`).
    *   Admin overrides for state (`adminCollapseState`, `adminSetSuperposition`).
    *   Simulating quantum fluctuations (admin/time-based).
12. **Access/Withdrawal Functions:**
    *   Main withdrawal function checking state/conditions.
    *   Withdrawal specific to the "Secure" state (requires proof).
    *   Withdrawal specific to the "Accessible" state.
    *   Attempting withdrawal from Superposition (maybe via high fee).
    *   Reclaiming "dust" amounts under specific conditions.
13. **Staking Functions (for Measurement):**
    *   Staking Ether to attempt measurement.
    *   Claiming staked Ether upon successful measurement/collapse.
    *   Withdrawing lost stakes (e.g., if state doesn't collapse).
14. **Configuration Functions (Admin Only):**
    *   Setting measurement probabilities.
    *   Setting decoherence time and target state.
    *   Setting required stake for measurement.
    *   Setting secure state condition hash/proof.
    *   Setting withdrawal limits.
    *   Setting superposition withdrawal fee.
15. **Information/View Functions:**
    *   Getting current parameters.
    *   Getting user-specific stake info.
    *   Checking vault balance.
    *   Checking time until decoherence.
    *   Getting count of successful accessors.
    *   Getting secure state proof hash.
16. **Admin/Ownership Functions:**
    *   Transferring ownership.
    *   Renouncing ownership.
    *   Emergency admin withdrawal.

---

**Function Summary:**

1.  `constructor(uint256 initialMeasurementProbability, uint256 initialDecoherenceTime, uint256 initialMinMeasurementStake, bytes32 initialSecureStateProofHash)`: Deploys the contract, setting owner and initial parameters.
2.  `receive()`: Allows receiving plain Ether deposits.
3.  `fallback()`: Catches calls to undefined functions, potentially logging or reverting.
4.  `deposit()`: Explicit function for depositing Ether (alternative to `receive`). Emits `Deposited`.
5.  `checkAndApplyDecoherence()`: Internal helper. Checks if enough time has passed since the last state change. If so, transitions the state back to the configured decoherence state (usually Superposition). Called at the beginning of state-changing or access functions.
6.  `getCurrentState() view`: Returns the current state of the vault (Superposition, Collapsed_Secure, Collapsed_Accessible).
7.  `attemptMeasurement()`: Requires `minMeasurementStake`. Attempts to transition the vault state from `Superposition` to either `Collapsed_Secure` or `Collapsed_Accessible` based on configured probabilities and a pseudo-random outcome derived from block data. Staked Ether is recorded. Emits `MeasurementAttempted` and `StateChanged` if successful. Stake is held until claimed.
8.  `claimStakeAfterSuccessfulMeasurement()`: Callable by a user who successfully triggered a state collapse via `attemptMeasurement`. Allows them to withdraw their staked Ether. Resets the user's pending stake. Emits `StakeClaimed`.
9.  `withdrawLostStake()`: Allows a user to withdraw their stake if their `attemptMeasurement` call *failed* to collapse the state *and* the state is now `Superposition` again (either due to subsequent attempts or decoherence), or if they staked and the state was already collapsed by someone else. Prevents locking funds. Emits `LostStakeWithdrawn`.
10. `withdrawFunds(uint256 amount)`: Main withdrawal function. Requires the state to be `Collapsed_Accessible`. Withdraws the specified amount up to the `withdrawalLimit`. Emits `Withdrawn`.
11. `withdrawIfSecureStateConditionsMet(bytes32 proof)`: Allows withdrawal only if the state is `Collapsed_Secure` AND the provided `proof` (simulated hash) matches the configured `secureStateProofHash`. Emits `WithdrawnSecure`.
12. `attemptWithdrawFromSuperposition(uint256 amount)`: Allows withdrawal directly from `Superposition` state *only* if the sent `msg.value` covers a predefined `superpositionWithdrawalFee` *in addition* to the `amount`. Burns/transfers the fee. High risk/cost method. Emits `WithdrawnSuperpositionFee`.
13. `attemptReclaimDust()`: Allows withdrawal of very small amounts of leftover Ether (less than 1 wei) if the state is `Collapsed_Accessible`. Handles potential precision issues. Emits `DustReclaimed`.
14. `adminCollapseState(VaultState targetState)`: Owner-only. Allows the owner to manually transition the state to `Collapsed_Secure` or `Collapsed_Accessible`. Emits `StateChangedAdmin`.
15. `adminSetSuperposition()`: Owner-only. Allows the owner to manually force the state back to `Superposition`. Emits `StateChangedAdmin`.
16. `adminApplyQuantumFlucutation()`: Owner-only. Simulates a random state transition (e.g., between collapsed states or to/from Superposition) based on internal logic/randomness source, ignoring time/stakes. Emits `StateChangedFlucutation`.
17. `setMeasurementProbability(uint256 newProbability)`: Owner-only. Sets the probability (0-100) for state collapse during `attemptMeasurement`. Emits `MeasurementProbabilityUpdated`.
18. `setDecoherenceTime(uint256 newDecoherenceTime)`: Owner-only. Sets the time duration after which a collapsed state will automatically return to `Superposition` (or configured decoherence state). Emits `DecoherenceTimeUpdated`.
19. `setDecoherenceTargetState(VaultState targetState)`: Owner-only. Sets the state the vault returns to after decoherence (must be `Superposition` or potentially other states if logic allowed). Emits `DecoherenceTargetStateUpdated`.
20. `setMinMeasurementStake(uint256 newStake)`: Owner-only. Sets the minimum Ether required to be staked when calling `attemptMeasurement`. Emits `MinMeasurementStakeUpdated`.
21. `setSecureStateProofHash(bytes32 newProofHash)`: Owner-only. Sets the hash required for withdrawal from the `Collapsed_Secure` state. Emits `SecureStateProofHashUpdated`.
22. `setWithdrawalLimit(uint256 newLimit)`: Owner-only. Sets the maximum Ether amount that can be withdrawn in a single call from the `Collapsed_Accessible` state. Emits `WithdrawalLimitUpdated`.
23. `setSuperpositionWithdrawalFee(uint256 newFee)`: Owner-only. Sets the required fee to withdraw directly from the `Superposition` state. Emits `SuperpositionWithdrawalFeeUpdated`.
24. `getVaultBalance() view`: Returns the current balance of the contract.
25. `getTimeToDecoherence() view`: Calculates and returns the time remaining until the state will decohere, if it's currently collapsed. Returns 0 if already Superposition or if decoherence is disabled (decoherenceTime = 0).
26. `getUserMeasurementStake(address user) view`: Returns the amount of Ether currently staked by a specific user for measurement attempts that is pending claim.
27. `getSuccessfulMeasurementCount() view`: Returns the total number of times a user successfully triggered a state collapse via `attemptMeasurement`.
28. `getSecureStateProofHash() view`: Returns the current hash required for secure withdrawals.
29. `getMeasurementProbability() view`: Returns the current probability for state collapse.
30. `getMinMeasurementStake() view`: Returns the minimum stake required for measurement attempts.
31. `getSuperpositionWithdrawalFee() view`: Returns the fee required for Superposition withdrawals.
32. `getWithdrawalLimit() view`: Returns the current withdrawal limit for the Accessible state.
33. `transferOwnership(address newOwner)`: Owner-only. Transfers ownership of the contract. Inherited from Ownable.
34. `renounceOwnership()`: Owner-only. Renounces ownership, setting owner to address(0). Inherited from Ownable.
35. `emergencyWithdrawAdmin()`: Owner-only. Allows the owner to withdraw all funds regardless of state (emergency fallback). Emits `EmergencyWithdrawal`.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title QuantumVault
/// @author YourNameHere
/// @notice A metaphorical "Quantum Vault" smart contract where access to deposited funds
/// is controlled by a state machine simulating quantum mechanics concepts:
/// - Superposition: Funds are locked, state is uncertain.
/// - Collapsed_Secure: Funds accessible only with a valid cryptographic proof (simulated hash).
/// - Collapsed_Accessible: Funds more easily accessible, potentially with limits.
/// State transitions can be probabilistic (via attemptMeasurement, requiring a stake),
/// manual (by owner), or due to simulated "decoherence" over time.

// --- Outline ---
// 1. License & Pragma
// 2. Imports (Ownable)
// 3. Error Definitions
// 4. Enums (VaultState)
// 5. State Variables
// 6. Events
// 7. Modifiers (Not explicitly used beyond Ownable)
// 8. Function Summary (Detailed above the code)
// 9. Constructor
// 10. Receive/Fallback
// 11. Core State Management Functions (checkAndApplyDecoherence, getCurrentState, attemptMeasurement, adminCollapseState, adminSetSuperposition, adminApplyQuantumFlucutation)
// 12. Access/Withdrawal Functions (withdrawFunds, withdrawIfSecureStateConditionsMet, attemptWithdrawFromSuperposition, attemptReclaimDust)
// 13. Staking Functions (attemptMeasurement requires stake, claimStakeAfterSuccessfulMeasurement, withdrawLostStake)
// 14. Configuration Functions (setMeasurementProbability, setDecoherenceTime, setDecoherenceTargetState, setMinMeasurementStake, setSecureStateProofHash, setWithdrawalLimit, setSuperpositionWithdrawalFee)
// 15. Information/View Functions (getVaultBalance, getTimeToDecoherence, getUserMeasurementStake, getSuccessfulMeasurementCount, getSecureStateProofHash, getMeasurementProbability, getMinMeasurementStake, getSuperpositionWithdrawalFee, getWithdrawalLimit)
// 16. Admin/Ownership Functions (transferOwnership, renounceOwnership, emergencyWithdrawAdmin)

// --- Function Summary (Detailed above the code) ---

contract QuantumVault is Ownable {

    // --- Error Definitions ---
    error InvalidStateForOperation(VaultState currentState, string requiredOperation);
    error InvalidProbability();
    error InvalidDecoherenceTargetState();
    error InsufficientMeasurementStake(uint256 required, uint256 provided);
    error MeasurementFailedToCollapse();
    error StakeNotClaimableYet();
    error NoStakeToWithdraw();
    error InsufficientFunds(uint256 required, uint256 available);
    error WithdrawalLimitExceeded(uint256 requested, uint256 limit);
    error InvalidSecureProof();
    error InsufficientSuperpositionFee(uint256 requiredFee, uint256 providedFee);
    error DustAmountTooLarge(uint256 amount);

    // --- Enums ---
    enum VaultState {
        Superposition,          // Funds are locked, state is uncertain, requires measurement to collapse.
        Collapsed_Secure,       // State is known, requires a specific 'proof' to access funds.
        Collapsed_Accessible    // State is known, funds are more easily accessible (potentially with limits).
    }

    // --- State Variables ---
    VaultState private currentState;
    uint256 private lastStateChangeTimestamp;

    // Configuration Parameters (Admin settable)
    uint256 public measurementProbability = 50; // Probability (0-100) of successful collapse during attemptMeasurement.
    uint256 public decoherenceTime = 7 days;    // Time after which a collapsed state reverts to decoherenceTargetState. 0 for no decoherence.
    VaultState public decoherenceTargetState = VaultState.Superposition; // State to revert to after decoherence.
    uint256 public minMeasurementStake = 0.01 ether; // Minimum stake required to attempt measurement.
    bytes32 public secureStateProofHash;        // Hash required as 'proof' for withdrawal from Collapsed_Secure state.
    uint256 public withdrawalLimit = type(uint256).max; // Max amount per withdrawal call from Collapsed_Accessible state.
    uint256 public superpositionWithdrawalFee = 0.1 ether; // Fee required to withdraw from Superposition.

    // User Specific Data
    mapping(address => uint256) private userMeasurementStakes; // Stake amount held for a user's attemptMeasurement
    mapping(address => bool) private userHadSuccessfulMeasurement; // Flag if user's last attempt was successful
    mapping(address => uint256) private userSuccessfulMeasurementStakeAmount; // Amount staked during a successful measurement

    uint256 private successfulMeasurementCount = 0; // Total count of successful state collapses via attemptMeasurement

    // --- Events ---
    event StateChanged(VaultState newState, VaultState oldState, string reason);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawnSecure(address indexed user, uint256 amount);
    event WithdrawnSuperpositionFee(address indexed user, uint256 amount, uint256 feePaid);
    event DustReclaimed(address indexed user, uint256 amount);
    event MeasurementAttempted(address indexed user, bool success, VaultState collapsedToState);
    event StakeClaimed(address indexed user, uint256 amount);
    event LostStakeWithdrawn(address indexed user, uint256 amount);
    event MeasurementProbabilityUpdated(uint256 newProbability);
    event DecoherenceTimeUpdated(uint256 newDecoherenceTime);
    event DecoherenceTargetStateUpdated(VaultState targetState);
    event MinMeasurementStakeUpdated(uint256 newStake);
    event SecureStateProofHashUpdated(bytes32 newProofHash);
    event WithdrawalLimitUpdated(uint256 newLimit);
    event SuperpositionWithdrawalFeeUpdated(uint256 newFee);
    event EmergencyWithdrawal(address indexed admin, uint256 amount);
    event StateChangedAdmin(VaultState newState, VaultState oldState);
    event StateChangedFlucutation(VaultState newState, VaultState oldState);

    // --- Constructor ---
    constructor(
        uint256 initialMeasurementProbability,
        uint256 initialDecoherenceTime,
        uint256 initialMinMeasurementStake,
        bytes32 initialSecureStateProofHash
    ) Ownable(msg.sender) {
        if (initialMeasurementProbability > 100) revert InvalidProbability();
        if (initialDecoherenceTargetState != VaultState.Superposition) revert InvalidDecoherenceTargetState(); // Only allow Superposition decoherence target initially

        currentState = VaultState.Superposition;
        lastStateChangeTimestamp = block.timestamp;

        measurementProbability = initialMeasurementProbability;
        decoherenceTime = initialDecoherenceTime;
        minMeasurementStake = initialMinMeasurementStake;
        secureStateProofHash = initialSecureStateProofHash;

        // Set initial parameters (optional, could be 0 or defaults)
        // withdrawalLimit = type(uint256).max;
        // superpositionWithdrawalFee = 0.1 ether;
    }

    // --- Receive & Fallback ---

    /// @notice Allows the contract to receive plain Ether. Treated as a deposit.
    receive() external payable {
        deposit();
    }

    /// @notice Catches calls to undefined functions. Can be used for logging or specific fallback logic.
    fallback() external payable {
        // Optional: Add logging or revert here.
        // For now, just allow Ether if sent.
        if (msg.value > 0) {
            deposit();
        }
    }

    // --- Core State Management Functions ---

    /// @notice Explicit function for depositing Ether.
    function deposit() public payable {
        if (msg.value == 0) return; // No-op if no Ether sent
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Internal helper to check if decoherence should occur and apply it.
    function checkAndApplyDecoherence() internal {
        if (decoherenceTime > 0 && currentState != VaultState.Superposition) {
            if (block.timestamp >= lastStateChangeTimestamp + decoherenceTime) {
                VaultState oldState = currentState;
                currentState = decoherenceTargetState; // Usually Superposition
                lastStateChangeTimestamp = block.timestamp;
                emit StateChanged(currentState, oldState, "Decoherence");
            }
        }
    }

    /// @notice Returns the current state of the vault.
    function getCurrentState() public view returns (VaultState) {
        // Note: This view function doesn't trigger checkAndApplyDecoherence
        // as it doesn't modify state. State might have decohered since last transaction.
        // Actual state used in transactional functions will be checked.
        if (decoherenceTime > 0 && currentState != VaultState.Superposition) {
             if (block.timestamp >= lastStateChangeTimestamp + decoherenceTime) {
                 return decoherenceTargetState; // Return perceived future state
             }
        }
        return currentState;
    }

    /// @notice Attempts to collapse the quantum state from Superposition to Collapsed_Secure or Collapsed_Accessible.
    /// Requires staking a minimum amount of Ether. Success is probabilistic.
    function attemptMeasurement() public payable {
        checkAndApplyDecoherence(); // Check if state already decohered

        if (currentState != VaultState.Superposition) {
             revert InvalidStateForOperation(currentState, "attempt measurement");
        }
        if (msg.value < minMeasurementStake) {
             revert InsufficientMeasurementStake(minMeasurementStake, msg.value);
        }

        // Record the stake
        userMeasurementStakes[msg.sender] += msg.value;

        // --- Simulate Quantum Probability ---
        // Acknowledge blockchain pseudo-randomness limitations.
        // Use a combination of block data for variability.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.number))) % 100;

        VaultState oldState = currentState;
        bool success = false;
        VaultState collapsedTo = VaultState.Superposition; // Default if measurement fails

        if (randomNumber < measurementProbability) {
            // Measurement successful - collapse to a state
            success = true;
            successfulMeasurementCount++;

            // Decide which state it collapses to (e.g., random split or deterministic)
            // Here, 50/50 chance between Secure and Accessible after successful collapse
            uint256 collapseTargetRandom = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, "target"))) % 100;

            if (collapseTargetRandom < 50) {
                currentState = VaultState.Collapsed_Accessible;
                collapsedTo = VaultState.Collapsed_Accessible;
            } else {
                currentState = VaultState.Collapsed_Secure;
                collapsedTo = VaultState.Collapsed_Secure;
            }

            lastStateChangeTimestamp = block.timestamp;
            userHadSuccessfulMeasurement[msg.sender] = true;
            userSuccessfulMeasurementStakeAmount[msg.sender] = userMeasurementStakes[msg.sender]; // Store total staked amount for claim
            userMeasurementStakes[msg.sender] = 0; // Clear pending stake
            emit StateChanged(currentState, oldState, "Measurement Successful");

        } else {
            // Measurement failed - state remains Superposition
            success = false;
            userHadSuccessfulMeasurement[msg.sender] = false; // Mark as failed attempt
            // Stake remains in userMeasurementStakes mapping, can be withdrawn later if state is Superposition.
        }

        emit MeasurementAttempted(msg.sender, success, collapsedTo);
    }

    /// @notice Owner-only function to manually collapse the state to a specific collapsed state.
    /// Skips probability and staking.
    function adminCollapseState(VaultState targetState) public onlyOwner {
        if (targetState == VaultState.Superposition) {
            revert InvalidDecoherenceTargetState(); // Use adminSetSuperposition for this
        }
        checkAndApplyDecoherence(); // Check before forced transition

        VaultState oldState = currentState;
        currentState = targetState;
        lastStateChangeTimestamp = block.timestamp;
        emit StateChangedAdmin(currentState, oldState);
        emit StateChanged(currentState, oldState, "Admin Collapse");
    }

    /// @notice Owner-only function to manually force the state back to Superposition.
    function adminSetSuperposition() public onlyOwner {
        checkAndApplyDecoherence(); // Check before forced transition
        VaultState oldState = currentState;
        currentState = VaultState.Superposition;
        lastStateChangeTimestamp = block.timestamp;
        emit StateChangedAdmin(currentState, oldState);
        emit StateChanged(currentState, oldState, "Admin Set Superposition");
    }

    /// @notice Owner-only function to simulate a random quantum fluctuation, potentially changing state.
    function adminApplyQuantumFlucutation() public onlyOwner {
         checkAndApplyDecoherence(); // Check before applying fluctuation

         VaultState oldState = currentState;
         VaultState newState = oldState; // Default: no change

         // Simulate a random shift (e.g., 33% chance of changing state)
         uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, "fluctuation"))) % 100;

         if (randomNumber < 33) {
             // Change state
             if (oldState == VaultState.Superposition) {
                 // From Superposition, randomly go to a collapsed state
                 uint256 targetRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, "fluc-target"))) % 100;
                 if (targetRandom < 50) {
                    newState = VaultState.Collapsed_Accessible;
                 } else {
                    newState = VaultState.Collapsed_Secure;
                 }
             } else if (oldState == VaultState.Collapsed_Accessible) {
                  // From Accessible, randomly go to Secure or Superposition
                  uint256 targetRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, "fluc-target2"))) % 100;
                  if (targetRandom < 50) {
                     newState = VaultState.Collapsed_Secure;
                  } else {
                     newState = VaultState.Superposition;
                  }
             } else if (oldState == VaultState.Collapsed_Secure) {
                  // From Secure, randomly go to Accessible or Superposition
                  uint256 targetRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, "fluc-target3"))) % 100;
                  if (targetRandom < 50) {
                     newState = VaultState.Collapsed_Accessible;
                  } else {
                     newState = VaultState.Superposition;
                  }
             }

             if (newState != oldState) {
                 currentState = newState;
                 lastStateChangeTimestamp = block.timestamp;
                 emit StateChangedFlucutation(currentState, oldState);
                 emit StateChanged(currentState, oldState, "Quantum Fluctuation");
             }
         }
    }


    // --- Access/Withdrawal Functions ---

    /// @notice Allows a user to claim the stake they put down for a successful measurement attempt.
    function claimStakeAfterSuccessfulMeasurement() public {
         if (!userHadSuccessfulMeasurement[msg.sender]) {
             revert StakeNotClaimableYet();
         }
         uint256 stakeAmount = userSuccessfulMeasurementStakeAmount[msg.sender];
         if (stakeAmount == 0) {
             revert NoStakeToWithdraw(); // Should not happen if userHadSuccessfulMeasurement is true
         }

         userHadSuccessfulMeasurement[msg.sender] = false;
         userSuccessfulMeasurementStakeAmount[msg.sender] = 0;

         (bool success, ) = payable(msg.sender).call{value: stakeAmount}("");
         require(success, "Stake withdrawal failed");

         emit StakeClaimed(msg.sender, stakeAmount);
    }

    /// @notice Allows a user to withdraw stake that was put down for a failed measurement attempt.
    /// Callable if state is currently Superposition.
    function withdrawLostStake() public {
        checkAndApplyDecoherence(); // State must be Superposition to withdraw lost stake

        if (currentState != VaultState.Superposition) {
             revert InvalidStateForOperation(currentState, "withdraw lost stake");
        }

        uint256 stakeAmount = userMeasurementStakes[msg.sender];
        if (stakeAmount == 0) {
             revert NoStakeToWithdraw();
        }

        userMeasurementStakes[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: stakeAmount}("");
        require(success, "Lost stake withdrawal failed");

        emit LostStakeWithdrawn(msg.sender, stakeAmount);
    }


    /// @notice Main function to withdraw funds from the vault.
    /// Only possible when the state is Collapsed_Accessible.
    function withdrawFunds(uint256 amount) public {
        checkAndApplyDecoherence(); // Check if state decohered

        if (currentState != VaultState.Collapsed_Accessible) {
            revert InvalidStateForOperation(currentState, "withdraw funds (Accessible)");
        }
        if (amount == 0) return;
        if (address(this).balance < amount) {
            revert InsufficientFunds(amount, address(this).balance);
        }
        if (amount > withdrawalLimit) {
            revert WithdrawalLimitExceeded(amount, withdrawalLimit);
        }

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Allows withdrawal specifically from the Collapsed_Secure state using a proof.
    function withdrawIfSecureStateConditionsMet(bytes32 proof) public {
        checkAndApplyDecoherence(); // Check if state decohered

        if (currentState != VaultState.Collapsed_Secure) {
             revert InvalidStateForOperation(currentState, "withdraw funds (Secure)");
        }
        if (proof != secureStateProofHash) {
            revert InvalidSecureProof();
        }

        uint256 amount = address(this).balance; // Withdraw all in secure state for simplicity
        if (amount == 0) return;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Secure withdrawal failed");

        emit WithdrawnSecure(msg.sender, amount);
    }

     /// @notice Attempts to withdraw funds directly from the Superposition state by paying a high fee.
     function attemptWithdrawFromSuperposition(uint256 amount) public payable {
        checkAndApplyDecoherence(); // Check if state decohered

        if (currentState != VaultState.Superposition) {
             revert InvalidStateForOperation(currentState, "withdraw funds (Superposition fee)");
        }
        if (amount == 0) return;

        uint256 totalRequired = amount + superpositionWithdrawalFee;
        if (msg.value < totalRequired) {
             revert InsufficientSuperpositionFee(superpositionWithdrawalFee, msg.value - amount);
        }
         if (address(this).balance < amount) {
            revert InsufficientFunds(amount, address(this).balance);
        }


        // Fee is collected implicitly by checking msg.value and only sending 'amount'
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Superposition withdrawal failed");

        emit WithdrawnSuperpositionFee(msg.sender, amount, superpositionWithdrawalFee);

        // Any excess msg.value beyond amount + fee remains in contract or is lost if fallback/receive not payable
        // Given receive/fallback are payable, excess just becomes a deposit.
     }


    /// @notice Allows reclaiming tiny residual dust amounts if the state is Collapsed_Accessible.
    function attemptReclaimDust() public {
        checkAndApplyDecoherence(); // Check if state decohered

        if (currentState != VaultState.Collapsed_Accessible) {
             revert InvalidStateForOperation(currentState, "reclaim dust");
        }

        uint256 balance = address(this).balance;
        // Define 'dust' as an amount less than 1 wei (which is impossible in practice)
        // Or define it as a very small fixed amount, e.g., less than 1000 wei
        // Let's use a pragmatic definition: less than 1000 wei AND less than the min stake
        uint256 dustThreshold = 1000; // Example threshold in wei
        if (balance >= dustThreshold || balance >= minMeasurementStake) {
             revert DustAmountTooLarge(balance);
        }
        if (balance == 0) return;

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Dust withdrawal failed");

        emit DustReclaimed(msg.sender, balance);
    }

    // --- Configuration Functions (Admin Only) ---

    /// @notice Sets the probability of successful state collapse during measurement (0-100).
    function setMeasurementProbability(uint256 newProbability) public onlyOwner {
        if (newProbability > 100) revert InvalidProbability();
        measurementProbability = newProbability;
        emit MeasurementProbabilityUpdated(newProbability);
    }

    /// @notice Sets the time duration after which a collapsed state decoheres back to the target state.
    /// Set to 0 to disable decoherence.
    function setDecoherenceTime(uint256 newDecoherenceTime) public onlyOwner {
        decoherenceTime = newDecoherenceTime;
        emit DecoherenceTimeUpdated(newDecoherenceTime);
    }

    /// @notice Sets the target state the vault returns to after decoherence.
    /// Currently only allows setting to Superposition.
    function setDecoherenceTargetState(VaultState targetState) public onlyOwner {
         if (targetState != VaultState.Superposition) revert InvalidDecoherenceTargetState();
         decoherenceTargetState = targetState;
         emit DecoherenceTargetStateUpdated(targetState);
    }

    /// @notice Sets the minimum Ether required to be staked for the attemptMeasurement function.
    function setMinMeasurementStake(uint256 newStake) public onlyOwner {
        minMeasurementStake = newStake;
        emit MinMeasurementStakeUpdated(newStake);
    }

    /// @notice Sets the cryptographic hash required to withdraw funds from the Collapsed_Secure state.
    function setSecureStateProofHash(bytes32 newProofHash) public onlyOwner {
        secureStateProofHash = newProofHash;
        emit SecureStateProofHashUpdated(newProofHash);
    }

    /// @notice Sets the maximum amount of Ether that can be withdrawn in a single transaction from the Collapsed_Accessible state.
    /// Set to type(uint256).max for no limit.
    function setWithdrawalLimit(uint256 newLimit) public onlyOwner {
        withdrawalLimit = newLimit;
        emit WithdrawalLimitUpdated(newLimit);
    }

    /// @notice Sets the fee required to withdraw funds directly from the Superposition state.
    function setSuperpositionWithdrawalFee(uint256 newFee) public onlyOwner {
        superpositionWithdrawalFee = newFee;
        emit SuperpositionWithdrawalFeeUpdated(newFee);
    }


    // --- Information/View Functions ---

    /// @notice Returns the current Ether balance held by the contract.
    function getVaultBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Calculates the remaining time until the vault state decoheres.
    /// Returns 0 if already Superposition or decoherence is disabled.
    function getTimeToDecoherence() public view returns (uint256) {
        if (currentState == VaultState.Superposition || decoherenceTime == 0) {
            return 0;
        }
        uint256 decoherenceTimestamp = lastStateChangeTimestamp + decoherenceTime;
        if (block.timestamp >= decoherenceTimestamp) {
            return 0; // Already decohered or will in this block
        }
        return decoherenceTimestamp - block.timestamp;
    }

    /// @notice Returns the amount of Ether currently staked by a specific user that is pending claim.
    /// This stake is either claimable after a successful measurement or withdrawable as lost stake if in Superposition.
    function getUserMeasurementStake(address user) public view returns (uint256) {
        return userMeasurementStakes[user] + userSuccessfulMeasurementStakeAmount[user];
    }

     /// @notice Returns the total amount staked by a user during their *last* successful measurement, waiting to be claimed.
     function getUserPendingSuccessfulStakeClaim(address user) public view returns (uint256) {
         return userSuccessfulMeasurementStakeAmount[user];
     }

    /// @notice Returns the total count of times a user successfully triggered a state collapse via attemptMeasurement.
    function getSuccessfulMeasurementCount() public view returns (uint256) {
        return successfulMeasurementCount;
    }

    /// @notice Returns the current hash required for withdrawal from the Collapsed_Secure state.
    function getSecureStateProofHash() public view returns (bytes32) {
        return secureStateProofHash;
    }

    /// @notice Returns the current probability setting for state collapse during measurement attempts (0-100).
    function getMeasurementProbability() public view returns (uint256) {
        return measurementProbability;
    }

    /// @notice Returns the minimum Ether stake required to call attemptMeasurement.
    function getMinMeasurementStake() public view returns (uint256) {
        return minMeasurementStake;
    }

    /// @notice Returns the fee required to withdraw funds directly from the Superposition state.
    function getSuperpositionWithdrawalFee() public view returns (uint256) {
        return superpositionWithdrawalFee;
    }

    /// @notice Returns the current maximum amount allowed per withdrawal transaction from the Collapsed_Accessible state.
    function getWithdrawalLimit() public view returns (uint256) {
        return withdrawalLimit;
    }


    // --- Admin/Ownership Functions (Inherited from Ownable or Owner-Specific) ---

    // Ownable functions: transferOwnership(address newOwner), renounceOwnership()

    /// @notice Allows the contract owner to withdraw all funds in case of emergency, regardless of state.
    function emergencyWithdrawAdmin() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) return;

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Emergency withdrawal failed");

        emit EmergencyWithdrawal(msg.sender, balance);
    }
}
```