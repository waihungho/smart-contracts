Okay, let's design a smart contract around an advanced concept. How about a "Quantum Vault" where tokens are locked, but the unlock conditions can vary dynamically based on time, global contract phase, admin-set conditions, and a pseudo-random factor? This incorporates multiple concepts and moves beyond simple time-locks or single-condition releases.

We'll avoid inheriting standard libraries like OpenZeppelin's `Ownable` or `Pausable` to meet the "don't duplicate any of open source" requirement for structural patterns, implementing that logic manually.

---

## Quantum Vault Smart Contract

This contract allows users to deposit ERC-20 tokens into a vault. Tokens are locked and can only be withdrawn if one of several distinct unlock conditions is met. These conditions depend on the user's deposit timestamp, the contract's current operational phase, specific flags set by the admin, and a periodically updated pseudo-random value.

**Core Concepts:**

*   **Multi-modal Unlock:** Users can attempt withdrawal via different methods (`tryPhaseUnlock`, `tryConditionalUnlock`, `tryDeterministicUnlock`, `tryQuantumFluctuationUnlock`), each with specific criteria.
*   **Phased Operation:** The contract can transition through different administrative phases, each potentially altering unlock requirements.
*   **Conditional Release:** Admin can enable or disable a specific global condition that allows withdrawals.
*   **Pseudo-Random Influence:** A periodically updated value introduces an element of non-determinism into one of the unlock methods. (NOTE: On-chain pseudo-randomness is not truly unpredictable and should not be used for high-security applications. This is for conceptual demonstration).
*   **Manual Ownership/Pausable:** Custom implementation of access control and pausing logic.

---

## Function Summary:

**Vault Core:**
1.  `constructor(address _tokenAddress, uint48 _initialMinimumLockDuration)`: Initializes the contract with the token address and a global minimum lock duration. Sets initial owner and phase.
2.  `deposit(uint256 amount)`: Allows a user to deposit approved ERC-20 tokens into the vault. Records deposit amount and timestamp.
3.  `viewUserBalance(address user)`: Returns the amount of tokens deposited by a specific user.
4.  `viewTotalDeposits()`: Returns the total balance of the managed token held by the contract.

**Unlock Mechanisms:**
5.  `tryPhaseUnlock()`: Attempts to withdraw tokens based on the rules configured for the vault's `currentPhase`.
6.  `tryConditionalUnlock()`: Attempts to withdraw tokens if the global `conditionalTriggerActive` flag is set.
7.  `tryDeterministicUnlock()`: Attempts to withdraw tokens if `deterministicModeActive` is set, based purely on the minimum lock duration since deposit.
8.  `tryQuantumFluctuationUnlock()`: Attempts to withdraw tokens if configured in the current phase and a calculation involving the `randomFactor` and user data meets a threshold.

**Admin & Configuration:**
9.  `transferOwnership(address newOwner)`: Transfers contract ownership (manual implementation).
10. `pauseContract()`: Pauses certain core functionalities (manual implementation).
11. `unpauseContract()`: Unpauses contract functionality (manual implementation).
12. `rescueFunds(uint256 amount)`: Allows the owner to withdraw emergency funds (e.g., gas token stuck in contract, though not required for this token contract).
13. `setNextPhase(uint8 nextPhase)`: Owner transitions the vault to a new operational phase.
14. `setPhaseParameters(uint8 phase, PhaseParameters params)`: Owner configures the rules and requirements for a specific phase.
15. `setConditionalUnlockTrigger(bool active)`: Owner activates or deactivates the global conditional unlock trigger.
16. `setDeterministicUnlockMode(bool active)`: Owner activates or deactivates the simpler deterministic unlock mode.
17. `setMinimumLockDuration(uint48 duration)`: Owner sets the global minimum time tokens must be locked.
18. `triggerRandomFactorUpdate()`: Owner (or designated keeper role, implemented here as owner) updates the pseudo-random factor using recent block data.
19. `setQuantumFluctuationThreshold(uint256 threshold)`: Owner sets the threshold for the quantum fluctuation unlock calculation.

**View & Status:**
20. `viewOwner()`: Returns the address of the contract owner.
21. `viewPausedStatus()`: Returns the current paused status of the contract.
22. `viewCurrentPhase()`: Returns the current operational phase of the vault.
23. `viewPhaseParameters(uint8 phase)`: Returns the configuration parameters for a specific phase.
24. `viewCurrentPhaseParameters()`: Returns the configuration parameters for the currently active phase.
25. `viewConditionalTriggerStatus()`: Returns the status of the global conditional unlock trigger.
26. `viewDeterministicModeStatus()`: Returns the status of the deterministic unlock mode.
27. `viewMinimumLockDuration()`: Returns the global minimum lock duration.
28. `viewCurrentRandomFactor()`: Returns the current pseudo-random factor value.
29. `viewQuantumFluctuationThreshold()`: Returns the threshold for the quantum fluctuation unlock.
30. `viewDepositTimestamp(address user)`: Returns the timestamp when a user made their deposit.
31. `viewUnlockEligibility(address user)`: Returns a detailed breakdown of which specific unlock conditions a user currently meets.
32. `viewTimeSinceDeposit(address user)`: Returns the time elapsed since a user deposited.
33. `viewTimeInCurrentPhase()`: Returns the time elapsed since the vault entered the current phase.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interface for ERC-20 tokens
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title QuantumVault
 * @dev A complex smart contract vault with multi-modal unlock conditions influenced by
 *      time, contract phase, admin triggers, and pseudo-randomness.
 */
contract QuantumVault {

    // --- State Variables ---

    address private _owner;
    bool private _paused;
    IERC20 private immutable _token;

    // User deposit information
    mapping(address => uint256) public deposits;
    mapping(address => uint48) public depositTimestamps; // Using uint48 for timestamp efficiency (up to ~year 2106)

    // Vault phase management
    uint8 public currentPhase;
    uint48 public currentPhaseStartTime; // Timestamp when the current phase started

    // Global unlock parameters
    uint48 public minimumLockDuration; // Global minimum time tokens must be locked (in seconds)
    bool public deterministicModeActive; // If active, simple time-based unlock is possible
    bool public conditionalTriggerActive; // If active, a specific condition allows unlock

    // Pseudo-randomness parameters (NOTE: This is NOT secure randomness)
    uint256 private randomFactor; // Updated periodically, used for pseudo-random calculation
    uint256 public quantumFluctuationThreshold; // Threshold for quantum unlock eligibility

    // Configuration for different phases
    struct PhaseParameters {
        uint48 minPhaseDuration; // Minimum time the vault must be IN this phase (seconds)
        bool requiresConditionalTrigger; // Does this phase require the conditional trigger to be active for phase unlock?
        bool requiresRandomFactorMatch; // Does this phase require the quantum fluctuation calculation to pass for phase unlock?
        uint256 requiredRandomThreshold; // Specific threshold for *this* phase's random check (overrides global if > 0)
        string description; // Optional description for the phase
    }
    mapping(uint8 => PhaseParameters) public phaseConfigs;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event TokenDeposited(address indexed user, uint256 amount, uint48 timestamp);
    event TokenWithdrawn(address indexed user, uint256 amount, string unlockMethod);
    event PhaseChanged(uint8 indexed newPhase, uint48 startTime);
    event PhaseParametersUpdated(uint8 indexed phase);
    event ConditionalTriggerStatusUpdated(bool active);
    event DeterministicModeStatusUpdated(bool active);
    event MinimumLockDurationUpdated(uint48 duration);
    event RandomFactorUpdated(uint256 newFactor);
    event QuantumFluctuationThresholdUpdated(uint256 threshold);
    event FundsRescued(address indexed recipient, uint256 amount);

    // --- Modifiers (Manual Implementation of Ownable & Pausable) ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "QV: Not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "QV: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "QV: Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor(address _tokenAddress, uint48 _initialMinimumLockDuration) {
        require(_tokenAddress != address(0), "QV: Invalid token address");
        _owner = msg.sender;
        _token = IERC20(_tokenAddress);
        minimumLockDuration = _initialMinimumLockDuration;
        currentPhase = 1; // Start in Phase 1
        currentPhaseStartTime = uint48(block.timestamp);
        _paused = false;
        deterministicModeActive = false;
        conditionalTriggerActive = false;
        randomFactor = 0; // Initialize random factor
        quantumFluctuationThreshold = 0; // Initialize threshold
    }

    // --- Core Vault Functions ---

    /**
     * @dev Allows a user to deposit ERC-20 tokens into the vault.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "QV: Deposit amount must be positive");
        // User must approve this contract to spend 'amount' tokens beforehand
        require(_token.transferFrom(msg.sender, address(this), amount), "QV: Token transfer failed");

        uint256 currentDeposit = deposits[msg.sender];
        if (currentDeposit == 0) {
            // First deposit, record timestamp
            depositTimestamps[msg.sender] = uint48(block.timestamp);
        } else {
             // If user already has a deposit, we could update the timestamp
             // or keep the original. Let's keep the original for simplicity
             // and assume deposits add to a single locked entry.
             // If re-locking on subsequent deposits was desired, we'd update.
             // For this example, let's keep the original timestamp as the reference.
             // depositTimestamps[msg.sender] = uint48(block.timestamp); // Uncomment to reset lock time on deposit
        }

        deposits[msg.sender] = currentDeposit + amount;
        emit TokenDeposited(msg.sender, amount, uint48(block.timestamp));
    }

    // --- Unlock Functions ---

    /**
     * @dev Attempts to unlock and withdraw tokens based on the current phase rules.
     * Requires minimum lock duration passed and current phase conditions met.
     */
    function tryPhaseUnlock() external whenNotPaused {
        require(deposits[msg.sender] > 0, "QV: No deposit found");
        require(uint48(block.timestamp) >= depositTimestamps[msg.sender] + minimumLockDuration, "QV: Minimum lock duration not met");

        PhaseParameters memory currentParams = phaseConfigs[currentPhase];
        require(uint48(block.timestamp) >= currentPhaseStartTime + currentParams.minPhaseDuration, "QV: Current phase duration not met");

        if (currentParams.requiresConditionalTrigger) {
            require(conditionalTriggerActive, "QV: Conditional trigger not active for this phase");
        }

        if (currentParams.requiresRandomFactorMatch) {
            // Use phase-specific threshold if set, otherwise global
            uint256 threshold = currentParams.requiredRandomThreshold > 0
                                ? currentParams.requiredRandomThreshold
                                : quantumFluctuationThreshold;
            uint256 userEntropy = uint256(keccak256(abi.encodePacked(msg.sender, depositTimestamps[msg.sender], deposits[msg.sender])));
            uint256 quantumCheckValue = uint256(keccak256(abi.encodePacked(randomFactor, userEntropy))) % 1000; // Simple pseudo-random check
            require(quantumCheckValue < threshold, "QV: Quantum fluctuation check failed");
        }

        // All phase conditions met, perform withdrawal
        _withdraw(msg.sender, deposits[msg.sender], "PhaseUnlock");
    }

    /**
     * @dev Attempts to unlock and withdraw tokens if the global conditional trigger is active.
     * Requires minimum lock duration passed.
     */
    function tryConditionalUnlock() external whenNotPaused {
        require(deposits[msg.sender] > 0, "QV: No deposit found");
        require(uint48(block.timestamp) >= depositTimestamps[msg.sender] + minimumLockDuration, "QV: Minimum lock duration not met");
        require(conditionalTriggerActive, "QV: Conditional trigger not active");

        // All conditional unlock conditions met, perform withdrawal
        _withdraw(msg.sender, deposits[msg.sender], "ConditionalUnlock");
    }

    /**
     * @dev Attempts to unlock and withdraw tokens based purely on minimum lock duration,
     * but only if deterministic mode is active and the current phase allows it.
     */
    function tryDeterministicUnlock() external whenNotPaused {
         require(deposits[msg.sender] > 0, "QV: No deposit found");
         require(uint48(block.timestamp) >= depositTimestamps[msg.sender] + minimumLockDuration, "QV: Minimum lock duration not met");
         require(deterministicModeActive, "QV: Deterministic mode is not active");

         PhaseParameters memory currentParams = phaseConfigs[currentPhase];
         require(currentParams.isDeterministicFallbackAllowed, "QV: Deterministic unlock not allowed in current phase");


         // All deterministic unlock conditions met, perform withdrawal
         _withdraw(msg.sender, deposits[msg.sender], "DeterministicUnlock");
    }


    /**
     * @dev Attempts a special "quantum fluctuation" unlock based on the random factor and user data.
     * Requires minimum lock duration passed and current phase configuration allows it.
     * NOTE: This uses on-chain pseudo-randomness, which is not truly unpredictable.
     */
    function tryQuantumFluctuationUnlock() external whenNotPaused {
        require(deposits[msg.sender] > 0, "QV: No deposit found");
        require(uint48(block.timestamp) >= depositTimestamps[msg.sender] + minimumLockDuration, "QV: Minimum lock duration not met");

        PhaseParameters memory currentParams = phaseConfigs[currentPhase];
        // Allow quantum unlock if the phase *requires* it (handled in tryPhaseUnlock)
        // OR if the phase *explicitly allows* it as a separate path.
        // Let's add a flag to PhaseParameters for this.
        // For now, require the phase to be configured to use the random factor *at all*.
        require(currentParams.requiresRandomFactorMatch || quantumFluctuationThreshold > 0, "QV: Quantum unlock not configured"); // Simplified check

        // Use phase-specific threshold if set, otherwise global
        uint256 threshold = currentParams.requiredRandomThreshold > 0
                            ? currentParams.requiredRandomThreshold
                            : quantumFluctuationThreshold;
        require(threshold > 0, "QV: Quantum fluctuation threshold not set");


        uint256 userEntropy = uint256(keccak256(abi.encodePacked(msg.sender, depositTimestamps[msg.sender], deposits[msg.sender])));
        uint256 quantumCheckValue = uint256(keccak256(abi.encodePacked(randomFactor, userEntropy))) % 1000; // Simple pseudo-random check

        require(quantumCheckValue < threshold, "QV: Quantum fluctuation check failed");

        // All quantum fluctuation conditions met, perform withdrawal
        _withdraw(msg.sender, deposits[msg.sender], "QuantumFluctuationUnlock");
    }


    // --- Internal Helper for Withdrawal ---

    /**
     * @dev Internal function to perform the token withdrawal.
     */
    function _withdraw(address user, uint256 amount, string memory method) private {
        uint256 userDeposit = deposits[user];
        require(userDeposit >= amount, "QV: Insufficient balance to withdraw requested amount"); // Should not happen if withdrawing full balance

        deposits[user] = userDeposit - amount;
        // If user withdraws full balance, clear their timestamp record
        if (deposits[user] == 0) {
             delete depositTimestamps[user];
        }

        require(_token.transfer(user, amount), "QV: Token transfer failed during withdrawal");
        emit TokenWithdrawn(user, amount, method);
    }


    // --- Admin & Configuration Functions (onlyOwner) ---

    /**
     * @dev Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "QV: New owner is the zero address");
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Pauses contract functionality.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses contract functionality.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to rescue accidentally sent tokens (excluding the managed token).
     * Useful if unrelated tokens are sent to the contract address.
     * @param amount The amount of Ether to rescue (sending to owner).
     */
    function rescueFunds(uint256 amount) public onlyOwner {
         // Example: Rescue Ether sent to contract
         require(address(this).balance >= amount, "QV: Insufficient contract balance");
         (bool success, ) = payable(_owner).call{value: amount}("");
         require(success, "QV: ETH rescue failed");
         emit FundsRescued(_owner, amount);

         // Note: Rescuing the managed token (_token) would require a different function
         // and careful consideration if it should impact user deposits.
         // rescueToken(IERC20 unwantedToken, uint256 amount) ...
    }


    /**
     * @dev Transitions the vault to a new operational phase.
     * @param nextPhase The phase number to transition to.
     */
    function setNextPhase(uint8 nextPhase) public onlyOwner whenNotPaused {
        require(nextPhase != currentPhase, "QV: Already in this phase");
        // Add checks? e.g., require(nextPhase > currentPhase, "QV: Cannot go back a phase");

        currentPhase = nextPhase;
        currentPhaseStartTime = uint48(block.timestamp);
        emit PhaseChanged(currentPhase, currentPhaseStartTime);
    }

    /**
     * @dev Configures the parameters and rules for a specific vault phase.
     * @param phase The phase number to configure.
     * @param params The PhaseParameters struct containing the configuration.
     */
    function setPhaseParameters(uint8 phase, PhaseParameters memory params) public onlyOwner {
        // Add sanity checks on params if necessary
        phaseConfigs[phase] = params;
        emit PhaseParametersUpdated(phase);
    }

    /**
     * @dev Activates or deactivates the global conditional unlock trigger.
     * @param active The new status of the trigger.
     */
    function setConditionalUnlockTrigger(bool active) public onlyOwner {
        conditionalTriggerActive = active;
        emit ConditionalTriggerStatusUpdated(active);
    }

    /**
     * @dev Activates or deactivates the deterministic unlock mode.
     * @param active The new status of the mode.
     */
    function setDeterministicUnlockMode(bool active) public onlyOwner {
        deterministicModeActive = active;
        emit DeterministicModeStatusUpdated(active);
    }

    /**
     * @dev Sets the global minimum duration tokens must be locked.
     * @param duration The minimum lock duration in seconds.
     */
    function setMinimumLockDuration(uint48 duration) public onlyOwner {
        minimumLockDuration = duration;
        emit MinimumLockDurationUpdated(duration);
    }

    /**
     * @dev Updates the pseudo-random factor using recent block data.
     * This influences the 'quantum fluctuation' unlock.
     * NOTE: On-chain randomness is NOT secure. This is for demonstration.
     */
    function triggerRandomFactorUpdate() public onlyOwner whenNotPaused {
        // Use block.prevrandao in PoS, block.difficulty in PoW (deprecated)
        // Use keccak256 to mix block data and potentially add a salt/counter
        uint256 newFactor;
        unchecked { // Allow overflow/underflow for hash mixing
             newFactor = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty, // Use block.prevrandao on PoS chains instead
                tx.origin, // Avoid msg.sender if possible for randomness, tx.origin is less safe but okay for pseudo
                block.number,
                randomFactor // Include previous factor for 'chaining'
             )));
        }
        randomFactor = newFactor;
        emit RandomFactorUpdated(newFactor);
    }

    /**
     * @dev Sets the global threshold for the quantum fluctuation unlock calculation.
     * A lower threshold makes the check harder to pass (requires a smaller random number).
     * Value is typically between 0 and 999 (inclusive) as the check is modulo 1000.
     * @param threshold The new threshold (0-1000).
     */
    function setQuantumFluctuationThreshold(uint256 threshold) public onlyOwner {
        require(threshold <= 1000, "QV: Threshold must be <= 1000");
        quantumFluctuationThreshold = threshold;
        emit QuantumFluctuationThresholdUpdated(threshold);
    }

    // --- View Functions ---

    /**
     * @dev Returns the address of the contract owner.
     */
    function viewOwner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the current paused status of the contract.
     */
    function viewPausedStatus() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns the current operational phase of the vault.
     */
    function viewCurrentPhase() public view returns (uint8) {
        return currentPhase;
    }

    /**
     * @dev Returns the configuration parameters for a specific vault phase.
     * @param phase The phase number to retrieve parameters for.
     */
    function viewPhaseParameters(uint8 phase) public view returns (PhaseParameters memory) {
        return phaseConfigs[phase];
    }

    /**
     * @dev Returns the configuration parameters for the currently active phase.
     */
    function viewCurrentPhaseParameters() public view returns (PhaseParameters memory) {
        return phaseConfigs[currentPhase];
    }


    /**
     * @dev Returns the status of the global conditional unlock trigger.
     */
    function viewConditionalTriggerStatus() public view returns (bool) {
        return conditionalTriggerActive;
    }

    /**
     * @dev Returns the status of the deterministic unlock mode.
     */
    function viewDeterministicModeStatus() public view returns (bool) {
        return deterministicModeActive;
    }

     /**
     * @dev Returns the global minimum lock duration.
     */
    function viewMinimumLockDuration() public view returns (uint48) {
        return minimumLockDuration;
    }

    /**
     * @dev Returns the current pseudo-random factor value.
     */
    function viewCurrentRandomFactor() public view returns (uint256) {
        return randomFactor;
    }

    /**
     * @dev Returns the threshold for the quantum fluctuation unlock calculation.
     */
    function viewQuantumFluctuationThreshold() public view returns (uint256) {
        return quantumFluctuationThreshold;
    }

    /**
     * @dev Returns the timestamp when a user made their deposit.
     * Returns 0 if the user has no active deposit.
     * @param user The address of the user.
     */
    function viewDepositTimestamp(address user) public view returns (uint48) {
        return depositTimestamps[user];
    }

    /**
     * @dev Returns the time elapsed since a user deposited.
     * Returns 0 if the user has no active deposit.
     * @param user The address of the user.
     */
    function viewTimeSinceDeposit(address user) public view returns (uint256) {
        uint48 depositTime = depositTimestamps[user];
        if (depositTime == 0) {
            return 0;
        }
        return block.timestamp - depositTime;
    }

    /**
     * @dev Returns the time elapsed since the vault entered the current phase.
     */
    function viewTimeInCurrentPhase() public view returns (uint256) {
        return block.timestamp - currentPhaseStartTime;
    }


    /**
     * @dev Returns a detailed breakdown of which specific unlock conditions a user currently meets.
     * Useful for users to check their eligibility before attempting withdrawal.
     * @param user The address of the user.
     * @return A tuple indicating eligibility for each unlock method.
     */
    function viewUnlockEligibility(address user) public view returns (
        bool isDepositor,
        bool minLockDurationMet,
        bool canTryPhaseUnlock,
        bool canTryConditionalUnlock,
        bool canTryDeterministicUnlock,
        bool canTryQuantumFluctuationUnlock
    ) {
        isDepositor = deposits[user] > 0;
        if (!isDepositor) {
            return (false, false, false, false, false, false);
        }

        minLockDurationMet = uint48(block.timestamp) >= depositTimestamps[user] + minimumLockDuration;

        if (!minLockDurationMet) {
            return (true, false, false, false, false, false);
        }

        // Check eligibility for each specific method *if minLockDurationMet*
        PhaseParameters memory currentParams = phaseConfigs[currentPhase];
        uint256 timeInPhase = block.timestamp - currentPhaseStartTime;

        // Phase Unlock Eligibility
        bool phaseDurationMet = timeInPhase >= currentParams.minPhaseDuration;
        bool phaseConditionalReqMet = !currentParams.requiresConditionalTrigger || conditionalTriggerActive;
        bool phaseRandomReqMet = true; // Assume met initially

        if (currentParams.requiresRandomFactorMatch) {
             uint256 threshold = currentParams.requiredRandomThreshold > 0
                                 ? currentParams.requiredRandomThreshold
                                 : quantumFluctuationThreshold;
             if (threshold > 0) {
                 uint256 userEntropy = uint256(keccak256(abi.encodePacked(user, depositTimestamps[user], deposits[user])));
                 uint256 quantumCheckValue = uint256(keccak256(abi.encodePacked(randomFactor, userEntropy))) % 1000;
                 phaseRandomReqMet = quantumCheckValue < threshold;
             } else {
                 phaseRandomReqMet = false; // Random check required but threshold not set
             }
        }
        canTryPhaseUnlock = phaseDurationMet && phaseConditionalReqMet && phaseRandomReqMet;


        // Conditional Unlock Eligibility
        canTryConditionalUnlock = conditionalTriggerActive;

        // Deterministic Unlock Eligibility
        canTryDeterministicUnlock = deterministicModeActive && currentParams.isDeterministicFallbackAllowed;

        // Quantum Fluctuation Unlock Eligibility (Separate path)
        bool quantumUnlockConfigured = currentParams.requiresRandomFactorMatch || quantumFluctuationThreshold > 0;
        bool quantumUnlockRandomCheckMet = false;
         if (quantumUnlockConfigured) {
            uint256 threshold = currentParams.requiredRandomThreshold > 0
                                ? currentParams.requiredRandomThreshold
                                : quantumFluctuationThreshold;
            if (threshold > 0) {
                uint256 userEntropy = uint256(keccak256(abi.encodePacked(user, depositTimestamps[user], deposits[user])));
                uint256 quantumCheckValue = uint256(keccak256(abi.encodePacked(randomFactor, userEntropy))) % 1000;
                quantumUnlockRandomCheckMet = quantumCheckValue < threshold;
            }
        }
        canTryQuantumFluctuationUnlock = quantumUnlockRandomCheckMet;


        return (
            true, // isDepositor
            true, // minLockDurationMet
            canTryPhaseUnlock,
            canTryConditionalUnlock,
            canTryDeterministicUnlock,
            canTryQuantumFluctuationUnlock
        );
    }
}
```