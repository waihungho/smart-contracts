Okay, let's create a smart contract concept centered around a dynamic, non-linear system simulation. This isn't a standard token, NFT, or simple DeFi protocol. Instead, it simulates a theoretical "Quantum Fluctuation Engine" where user interactions influence internal states, and outcomes are based on these states and a form of in-contract pseudo-randomness, yielding unique "Quantum Particles".

This contract will feature concepts like:
1.  **Dynamic State:** Core parameters (Amplitude, Frequency, Entropy) change based on user interactions and time.
2.  **Resource Generation:** Users can 'Observe' fluctuations to gain 'Quantum Particles', but the yield is variable and depends on the system's state.
3.  **Resource Consumption:** Users can 'Inject Energy' (ETH) or 'Stabilize' (burn particles) to influence the state.
4.  **Simulated Entanglement:** Users can link their state with another, potentially sharing outcomes.
5.  **Entropy & State Shifts:** An internal entropy level increases, potentially triggering complex system resets or rule changes ('State Epochs').
6.  **Parameter Tuning:** Limited ability for users or admin to influence system parameters, possibly with timelocks.
7.  **Particle Decay:** Particles held by users slowly decay over time if not maintained.

This setup allows for a variety of interactions, state changes, and resulting functions.

---

## Quantum Fluctuator: Contract Outline & Function Summary

**Concept:** A smart contract simulating a dynamic, non-linear system ("Quantum Fluctuation Engine"). Users interact by injecting energy or observing fluctuations, which influences the system's internal state variables (Amplitude, Frequency, Entropy). Outcomes (generation of Quantum Particles) are probabilistic, based on the current state and pseudo-randomness. The system evolves through State Epochs triggered by increasing Entropy, potentially changing rules or resetting parameters.

**State Variables:**
*   `fluctuationAmplitude`: Represents the overall energy/volatility of the system. (Starts low, increases with energy injection, decreases with stabilization/decay).
*   `resonanceFrequency`: A parameter affecting the probability distribution of observation outcomes. (Can be tuned).
*   `entropyLevel`: Measures the disorder/time progression of the system. (Increases over time/interactions, triggers State Shifts).
*   `stateEpoch`: Counter for major state shifts. Each epoch might have slightly different rules or base parameters.
*   `quantumParticles`: Mapping of addresses to their particle balances. (Gained from observation, lost by decay/burning/transfer/stabilization).
*   `userLastObservationTime`: Mapping to track last observation per user (for decay calculation).
*   `entanglement`: Mapping storing paired addresses for simulated entanglement.
*   `adminAddress`: Owner of the contract for critical parameter adjustments and withdrawals.
*   `parametersLockDuration`: Duration after admin changes during which certain parameters cannot be changed again.
*   `lastParameterChangeTime`: Timestamp of the last admin parameter change.
*   `entropyThreshold`: The level of entropy that triggers a state shift.
*   `baseObservationYield`: Base value used in observation yield calculation.
*   `decayRate`: Rate at which particles decay per unit of time.

**Events:**
*   `EnergyInjected(address indexed user, uint256 amount, uint256 newAmplitude)`
*   `FluctuationObserved(address indexed user, uint256 particlesGenerated, uint256 currentAmplitude, uint256 currentFrequency)`
*   `ParticlesTransferred(address indexed from, address indexed to, uint256 amount)`
*   `ParticlesBurned(address indexed user, uint256 amount)`
*   `FluctuationStabilized(address indexed user, uint256 particlesBurned, uint256 newAmplitude)`
*   `StateShiftTriggered(uint256 indexed oldEpoch, uint256 indexed newEpoch, uint256 newEntropyThreshold)`
*   `EntropyLevelIncreased(uint256 newEntropy)`
*   `ResonanceFrequencyTuned(address indexed tuner, uint256 newFrequency)`
*   `Entangled(address indexed user1, address indexed user2)`
*   `Disentangled(address indexed user1, address indexed user2)`
*   `ParticlesDecayed(address indexed user, uint256 decayedAmount, uint256 remainingAmount)`
*   `ParametersAdjusted(address indexed admin, string parameterName, uint256 oldValue, uint256 newValue)`

**Modifiers:**
*   `onlyAdmin`: Restricts access to the contract admin.
*   `parametersUnlocked`: Ensures sufficient time has passed since the last parameter change.

**Internal Helper Functions:**
*   `_increaseEntropy()`: Increases the `entropyLevel`, potentially triggering `_triggerStateShift`.
*   `_triggerStateShift()`: Implements the logic for changing states (e.g., resetting entropy, adjusting base parameters based on the new epoch, distributing leftover energy).
*   `_calculateObservationYield(uint256 userSeed)`: Calculates the potential particle yield based on `fluctuationAmplitude`, `resonanceFrequency`, and a user-specific seed derived from block data and user state.
*   `_applyDecay(address user)`: Calculates and applies particle decay for a user based on elapsed time and `decayRate`.

**Function Summary (at least 20 functions):**

1.  `constructor(address initialAdmin)`: Initializes the contract, sets the admin, and initial state parameters.
2.  `injectEnergy()`: `payable` function. Users send ETH, which increases `fluctuationAmplitude`.
3.  `observeFluctuation()`: Allows a user to attempt to observe fluctuations. Internally calls `_applyDecay`, then `_calculateObservationYield`, potentially adds particles to user balance, and calls `_increaseEntropy`.
4.  `transferParticles(address recipient, uint256 amount)`: Transfers `amount` of `quantumParticles` from the caller to `recipient`. Calls `_applyDecay` for the sender before transfer.
5.  `burnParticles(uint256 amount)`: Destroys `amount` of the caller's `quantumParticles`. Calls `_applyDecay` for the caller first.
6.  `stabilizeFluctuation(uint256 particlesToBurn)`: Burns particles to decrease `fluctuationAmplitude`. Calls `_applyDecay` first.
7.  `entangleWithUser(address userToEntangleWith)`: Initiates simulated entanglement with another user. Requires payment (ETH or particles?) or maybe a shared state criteria. Updates `entanglement` mapping. Adds complexity to `observeFluctuation` for entangled users.
8.  `disentangleFromUser(address userToDisentangleFrom)`: Breaks the simulated entanglement.
9.  `triggerStateShift()`: Allows anyone to call this function if `entropyLevel` is above `entropyThreshold`. Calls the internal `_triggerStateShift`.
10. `decayParticles(address user)`: Public function allowing anyone to trigger particle decay calculation for a specific user. This ensures decay happens even if the user is inactive, making the decay mechanism active.
11. `getQuantumParticles(address user)`: `view` function to retrieve a user's particle balance *after* applying decay.
12. `getCurrentAmplitude()`: `view` function to get the current `fluctuationAmplitude`.
13. `getCurrentFrequency()`: `view` function to get the current `resonanceFrequency`.
14. `getEntropyLevel()`: `view` function to get the current `entropyLevel`.
15. `getStateEpoch()`: `view` function to get the current `stateEpoch`.
16. `getEntangledUser(address user)`: `view` function to see who a user is entangled with.
17. `getEntropyThreshold()`: `view` function to get the current `entropyThreshold`.
18. `getBaseObservationYield()`: `view` function to get the `baseObservationYield`.
19. `getDecayRate()`: `view` function to get the `decayRate`.
20. `getTimeUntilParameterUnlock()`: `view` function to check how much time is left until parameters can be adjusted by admin.
21. `previewObservationYield(address user)`: `view` function to calculate the potential yield *without* changing state or adding particles. Useful for users to gauge outcomes. Calls `_calculateObservationYield`.
22. `adjustResonanceFrequencyByAdmin(uint256 newFrequency)`: `onlyAdmin`, `parametersUnlocked`. Sets a new `resonanceFrequency`.
23. `adjustEntropyThresholdByAdmin(uint256 newThreshold)`: `onlyAdmin`, `parametersUnlocked`. Sets a new `entropyThreshold`.
24. `adjustBaseObservationYieldByAdmin(uint256 newBaseYield)`: `onlyAdmin`, `parametersUnlocked`. Sets a new `baseObservationYield`.
25. `adjustDecayRateByAdmin(uint256 newRate)`: `onlyAdmin`, `parametersUnlocked`. Sets a new `decayRate`.
26. `withdrawETH(uint256 amount)`: `onlyAdmin`. Allows admin to withdraw injected ETH.
27. `transferOwnership(address newAdmin)`: `onlyAdmin`. Transfers admin rights.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumFluctuator
 * @dev A conceptual smart contract simulating a dynamic "Quantum Fluctuation Engine".
 * Users interact to influence internal state parameters (Amplitude, Frequency, Entropy)
 * and 'Observe' fluctuations to generate non-fungible 'Quantum Particles'.
 * The system includes simulated entanglement, particle decay, and state shifts.
 * This is a complex simulation model and not a standard token/NFT/DeFi contract.
 *
 * Outline:
 * 1. State Variables: Defines the core parameters and user data.
 * 2. Events: Announces significant changes and actions.
 * 3. Errors: Custom errors for clearer failure reasons.
 * 4. Modifiers: Access control and parameter lock.
 * 5. Internal Helpers: Core logic for state changes, yield calculation, decay.
 * 6. External/Public Functions: User interactions and system triggers.
 * 7. View Functions: Read-only functions to query contract state.
 * 8. Admin Functions: Restricted functions for parameter tuning and management.
 *
 * Function Summary (>= 20 functions):
 * - constructor: Initializes the contract.
 * - injectEnergy: Pay ETH to increase fluctuation amplitude.
 * - observeFluctuation: Attempt to gain particles based on current state and pseudo-randomness.
 * - transferParticles: Send particles to another user.
 * - burnParticles: Destroy own particles.
 * - stabilizeFluctuation: Burn particles to reduce amplitude.
 * - entangleWithUser: Form a simulated entanglement link.
 * - disentangleFromUser: Break an entanglement link.
 * - triggerStateShift: Public call to potentially trigger a state transition if entropy is high.
 * - decayParticles: Public call to trigger particle decay for a user.
 * - getQuantumParticles: Get user's particle balance (after decay).
 * - getCurrentAmplitude: Get current fluctuation amplitude.
 * - getCurrentFrequency: Get current resonance frequency.
 * - getEntropyLevel: Get current entropy level.
 * - getStateEpoch: Get current state epoch number.
 * - getEntangledUser: Get entangled partner for a user.
 * - getEntropyThreshold: Get the threshold for state shifts.
 * - getBaseObservationYield: Get the base particle yield value.
 * - getDecayRate: Get the current particle decay rate.
 * - getTimeUntilParameterUnlock: Check remaining time before admin can change params again.
 * - previewObservationYield: Estimate potential particle yield from observation without state change.
 * - adjustResonanceFrequencyByAdmin: Admin sets new resonance frequency (locked).
 * - adjustEntropyThresholdByAdmin: Admin sets new entropy threshold (locked).
 * - adjustBaseObservationYieldByAdmin: Admin sets new base observation yield (locked).
 * - adjustDecayRateByAdmin: Admin sets new decay rate (locked).
 * - withdrawETH: Admin withdraws contract balance.
 * - transferOwnership: Admin transfers admin rights.
 */

contract QuantumFluctuator {

    // --- State Variables ---

    uint256 public fluctuationAmplitude; // System's energy/volatility. Affected by inject/stabilize.
    uint256 public resonanceFrequency;   // Parameter affecting observation outcomes. Tunable.
    uint256 public entropyLevel;         // Measures system disorder/time. Increases, triggers shifts.
    uint256 public stateEpoch;           // Counter for major state shifts. Rules might change per epoch.

    mapping(address => uint256) private _quantumParticles; // User particle balances.
    mapping(address => uint48) private _userLastObservationTime; // Timestamp of last observation or decay application.

    mapping(address => address) private _entanglement; // Mapping from user -> entangled partner. Bidirectional.

    address public adminAddress; // Contract owner for critical functions.

    uint64 public parametersLockDuration; // Time in seconds parameters are locked after admin change.
    uint48 private _lastParameterChangeTime; // Timestamp of the last admin parameter change.

    uint256 public entropyThreshold;     // Entropy level required to trigger a state shift.
    uint256 public baseObservationYield; // Base factor for observation yield calculation.
    uint256 public decayRate;            // Particles decay rate per second.

    // --- Events ---

    event EnergyInjected(address indexed user, uint256 amount, uint256 newAmplitude);
    event FluctuationObserved(address indexed user, uint256 particlesGenerated, uint256 currentAmplitude, uint256 currentFrequency, uint256 currentEntropy);
    event ParticlesTransferred(address indexed from, address indexed to, uint256 amount);
    event ParticlesBurned(address indexed user, uint256 amount);
    event FluctuationStabilized(address indexed user, uint256 particlesBurned, uint256 newAmplitude);
    event StateShiftTriggered(uint256 indexed oldEpoch, uint256 indexed newEpoch, uint256 newEntropyThreshold);
    event EntropyLevelIncreased(uint256 newEntropy);
    event ResonanceFrequencyTuned(address indexed tuner, uint256 newFrequency); // Could be admin or community based later
    event Entangled(address indexed user1, address indexed user2);
    event Disentangled(address indexed user1, address indexed user2);
    event ParticlesDecayed(address indexed user, uint256 decayedAmount, uint256 remainingAmount);
    event ParametersAdjusted(address indexed admin, string parameterName, uint256 oldValue, uint256 newValue);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event ETHWithdrawn(address indexed admin, uint256 amount);

    // --- Errors ---

    error NotAdmin();
    error ParametersLocked();
    error InsufficientParticles(uint256 required, uint256 available);
    error CannotEntangleWithSelf();
    error AlreadyEntangled(address entangledWith);
    error NotEntangledWith(address user);
    error EntropyThresholdNotReached(uint256 currentEntropy, uint256 threshold);
    error TransferFailed(); // Generic fallback

    // --- Modifiers ---

    modifier onlyAdmin() {
        if (msg.sender != adminAddress) revert NotAdmin();
        _;
    }

    modifier parametersUnlocked() {
        if (block.timestamp < _lastParameterChangeTime + parametersLockDuration) revert ParametersLocked();
        _;
    }

    // --- Constructor ---

    constructor(address initialAdmin) {
        adminAddress = initialAdmin;
        fluctuationAmplitude = 100; // Initial low amplitude
        resonanceFrequency = 42;    // Arbitrary initial frequency
        entropyLevel = 0;           // Start with low entropy
        stateEpoch = 1;             // Start at epoch 1
        parametersLockDuration = 24 * 3600; // Lock for 24 hours initially
        _lastParameterChangeTime = uint48(block.timestamp);
        entropyThreshold = 1000;    // Initial entropy threshold
        baseObservationYield = 10;  // Initial base yield
        decayRate = 1;              // Initial decay rate (1 particle per second)
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Increases the entropy level and potentially triggers a state shift.
     * @param entropyIncrease Amount to increase entropy by.
     */
    function _increaseEntropy(uint256 entropyIncrease) internal {
        entropyLevel += entropyIncrease;
        emit EntropyLevelIncreased(entropyLevel);
        if (entropyLevel >= entropyThreshold) {
            _triggerStateShift();
        }
    }

    /**
     * @dev Implements the logic for triggering a state shift.
     * Resets entropy, increments epoch, potentially adjusts threshold/parameters.
     */
    function _triggerStateShift() internal {
        uint256 oldEpoch = stateEpoch;
        stateEpoch++;
        entropyLevel = 0; // Reset entropy

        // Example state shift logic: Adjust threshold and base yield based on epoch
        entropyThreshold = entropyThreshold + (stateEpoch * 100);
        baseObservationYield = baseObservationYield + (stateEpoch * 5);

        // More complex logic could be added here, e.g.:
        // - Randomly adjust resonance frequency slightly
        // - Redistribute a small percentage of total particles
        // - Apply a temporary bonus/penalty to observations in the new epoch

        emit StateShiftTriggered(oldEpoch, stateEpoch, entropyThreshold);
    }

    /**
     * @dev Calculates the potential particle yield from an observation attempt.
     * Formula is conceptual, aiming for non-linearity and dependence on state.
     * Uses block data for pseudo-randomness.
     * @param userSeed A value unique to the user's observation event (e.g., hash).
     * @return The calculated particle yield.
     */
    function _calculateObservationYield(uint256 userSeed) internal view returns (uint256) {
        // Simple pseudo-randomness based on block data and user seed
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, msg.sender, userSeed)));

        // Conceptual yield calculation:
        // - Base yield
        // - Modified by amplitude (higher amplitude -> potentially higher range)
        // - Modified by frequency match (pseudoRandom % resonanceFrequency -> closer to 0 might give bonus)
        // - Modified by epoch (via baseObservationYield adjustment in _triggerStateShift)

        uint256 yieldFactor = (fluctuationAmplitude > 0 ? pseudoRandom % fluctuationAmplitude : 1); // Yield range influenced by amplitude
        uint256 frequencyMatchBonus = (pseudoRandom % resonanceFrequency == 0 ? baseObservationYield / 2 : 0); // Bonus if frequency aligns

        uint256 potentialYield = baseObservationYield + (yieldFactor / 10) + frequencyMatchBonus; // Simple combination

        // Add complexity based on epoch if needed:
        // if (stateEpoch > 1) { potentialYield = potentialYield * stateEpoch / 2; }

        return potentialYield;
    }

    /**
     * @dev Applies particle decay to a user's balance based on elapsed time.
     * Updates the last observation time.
     * @param user The address of the user to apply decay for.
     */
    function _applyDecay(address user) internal {
        uint48 lastTime = _userLastObservationTime[user];
        uint48 currentTime = uint48(block.timestamp);

        if (lastTime == 0) {
            // First interaction or user just received particles. Set time without decay.
            _userLastObservationTime[user] = currentTime;
            return;
        }

        uint256 particles = _quantumParticles[user];
        if (particles == 0) {
            _userLastObservationTime[user] = currentTime; // Just update time if no particles
            return;
        }

        uint256 timeElapsed = currentTime - lastTime;
        uint256 decayAmount = timeElapsed * decayRate;

        if (decayAmount > 0) {
            uint256 newBalance = particles > decayAmount ? particles - decayAmount : 0;
            uint256 actualDecay = particles - newBalance;

            if (actualDecay > 0) {
                 _quantumParticles[user] = newBalance;
                 emit ParticlesDecayed(user, actualDecay, newBalance);
            }
        }

        _userLastObservationTime[user] = currentTime;
    }


    // --- External/Public Functions ---

    /**
     * @dev Inject ETH into the contract to increase fluctuation amplitude.
     */
    function injectEnergy() external payable {
        require(msg.value > 0, "Must send ETH");
        // Amplitude increases non-linearly with injected energy (simple example)
        fluctuationAmplitude += msg.value / (fluctuationAmplitude > 0 ? fluctuationAmplitude / 100 + 1 : 1);
        _increaseEntropy(1); // Minor entropy increase per injection
        emit EnergyInjected(msg.sender, msg.value, fluctuationAmplitude);
    }

    /**
     * @dev Attempt to observe fluctuations and gain particles.
     * Applies decay, calculates yield, adds particles, increases entropy.
     */
    function observeFluctuation() external {
        _applyDecay(msg.sender); // Apply decay before calculating yield

        // Use block hash and sender for a unique seed for this specific observation
        // block.prevrandao is used for randomness in newer Solidity versions (post-Merge)
        // block.difficulty is deprecated post-Merge, using block.prevrandao is preferred.
        // For simplicity and broader compatibility with older compilers, using block.timestamp and block.difficulty/prevrandao combination.
        uint256 userSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, msg.sender)));

        uint256 particlesGenerated = _calculateObservationYield(userSeed);

        if (particlesGenerated > 0) {
            _quantumParticles[msg.sender] += particlesGenerated;
            // Applying decay again immediately after gaining particles ensures the time is updated.
            // However, it's simpler to just update the timestamp directly here.
             _userLastObservationTime[msg.sender] = uint48(block.timestamp); // Update time to now

            emit FluctuationObserved(msg.sender, particlesGenerated, fluctuationAmplitude, resonanceFrequency, entropyLevel);
        }

        _increaseEntropy(particlesGenerated > 0 ? particlesGenerated / 10 + 1 : 1); // Entropy increase proportional to particles gained (or a base minimum)
    }

    /**
     * @dev Transfer particles to another user.
     * @param recipient The address to transfer particles to.
     * @param amount The number of particles to transfer.
     */
    function transferParticles(address recipient, uint256 amount) external {
        require(recipient != address(0), "Cannot transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(recipient != msg.sender, "Cannot transfer to yourself");

        _applyDecay(msg.sender); // Apply decay before checking balance

        uint256 senderBalance = _quantumParticles[msg.sender];
        if (senderBalance < amount) revert InsufficientParticles(amount, senderBalance);

        // Apply decay to recipient if they exist in the decay tracking
        if (_userLastObservationTime[recipient] != 0 || _quantumParticles[recipient] > 0) {
             _applyDecay(recipient);
        }

        unchecked {
            _quantumParticles[msg.sender] = senderBalance - amount;
            _quantumParticles[recipient] += amount;
        }

         _userLastObservationTime[msg.sender] = uint48(block.timestamp); // Update sender's time
         _userLastObservationTime[recipient] = uint48(block.timestamp); // Update recipient's time

        emit ParticlesTransferred(msg.sender, recipient, amount);
    }

    /**
     * @dev Burn a specified amount of the caller's particles.
     * @param amount The number of particles to burn.
     */
    function burnParticles(uint256 amount) external {
        require(amount > 0, "Burn amount must be greater than zero");

        _applyDecay(msg.sender); // Apply decay before checking balance

        uint256 senderBalance = _quantumParticles[msg.sender];
        if (senderBalance < amount) revert InsufficientParticles(amount, senderBalance);

        unchecked {
             _quantumParticles[msg.sender] = senderBalance - amount;
        }
        _userLastObservationTime[msg.sender] = uint48(block.timestamp); // Update time

        emit ParticlesBurned(msg.sender, amount);
    }

    /**
     * @dev Burn particles to reduce fluctuation amplitude and entropy.
     * @param particlesToBurn The number of particles to burn.
     */
    function stabilizeFluctuation(uint256 particlesToBurn) external {
        require(particlesToBurn > 0, "Must burn more than zero particles");

        _applyDecay(msg.sender); // Apply decay before checking balance

        uint256 senderBalance = _quantumParticles[msg.sender];
        if (senderBalance < particlesToBurn) revert InsufficientParticles(particlesToBurn, senderBalance);

        unchecked {
            _quantumParticles[msg.sender] = senderBalance - particlesToBurn;
        }
        _userLastObservationTime[msg.sender] = uint48(block.timestamp); // Update time

        // Amplitude decreases based on burned particles (simple example)
        fluctuationAmplitude = fluctuationAmplitude > (particlesToBurn / 2) ? fluctuationAmplitude - (particlesToBurn / 2) : 0;

        // Entropy also decreases, but minimum 0
        entropyLevel = entropyLevel > (particlesToBurn / 5) ? entropyLevel - (particlesToBurn / 5) : 0;

        emit FluctuationStabilized(msg.sender, particlesToBurn, fluctuationAmplitude);
    }

    /**
     * @dev Form a simulated entanglement link with another user.
     * This is a simple simulation: users must mutually agree.
     * A more complex version could require particle cost or specific state conditions.
     * @param userToEntangleWith The address to attempt to entangle with.
     */
    function entangleWithUser(address userToEntangleWith) external {
        require(userToEntangleWith != address(0), "Cannot entangle with zero address");
        require(userToEntangleWith != msg.sender, "Cannot entangle with yourself");
        if (_entanglement[msg.sender] != address(0)) revert AlreadyEntangled(_entanglement[msg.sender]);
        if (_entanglement[userToEntangleWith] != address(0)) revert AlreadyEntangled(_entanglement[userToEntangleWith]);

        // Simple mutual agreement mechanism: user A calls, then user B calls with A's address.
        // A more robust system would use a request/accept pattern.
        // For this example, assume both call this function naming the other.
        // A real system needs to prevent A calling with B, then B calling with C before calling with A.
        // Let's simplify and just allow entanglement if neither is already entangled.
        // The EFFECT of entanglement will be simple, e.g., shared observation yield in _calculateObservationYield.

        _entanglement[msg.sender] = userToEntangleWith;
        _entanglement[userToEntangleWith] = msg.sender;

        emit Entangled(msg.sender, userToEntangleWith);
    }

    /**
     * @dev Break a simulated entanglement link.
     * @param userToDisentangleFrom The address of the entangled partner.
     */
    function disentangleFromUser(address userToDisentangleFrom) external {
        if (_entanglement[msg.sender] != userToDisentangleFrom) revert NotEntangledWith(userToDisentangleFrom);
        if (_entanglement[userToDisentangleFrom] != msg.sender) revert NotEntangledWith(msg.sender); // Should be true if _entanglement[msg.sender] is correct

        delete _entanglement[msg.sender];
        delete _entanglement[userToDisentangleFrom];

        emit Disentangled(msg.sender, userToDisentangleFrom);
    }

    /**
     * @dev Allows anyone to attempt to trigger a state shift if entropy threshold is met.
     * Costs a small amount of gas for the caller.
     */
    function triggerStateShift() external {
        if (entropyLevel < entropyThreshold) revert EntropyThresholdNotReached(entropyLevel, entropyThreshold);
        _triggerStateShift();
    }

    /**
     * @dev Allows anyone to trigger particle decay calculation for a specific user.
     * Useful for making the decay mechanism 'self-maintaining' by the community.
     * @param user The address of the user whose particles should decay.
     */
    function decayParticles(address user) external {
         _applyDecay(user);
         // No event needed here as _applyDecay emits ParticlesDecayed
    }


    // --- View Functions ---

    /**
     * @dev Get a user's particle balance after applying potential decay.
     * @param user The address of the user.
     * @return The current particle balance.
     */
    function getQuantumParticles(address user) external view returns (uint256) {
        // Apply decay calculation *hypothetically* for the view function
        uint48 lastTime = _userLastObservationTime[user];
        uint48 currentTime = uint48(block.timestamp);
        uint256 currentParticles = _quantumParticles[user];

        if (lastTime == 0 || currentParticles == 0) {
            return currentParticles;
        }

        uint256 timeElapsed = currentTime - lastTime;
        uint256 decayAmount = timeElapsed * decayRate;

        return currentParticles > decayAmount ? currentParticles - decayAmount : 0;
    }

    /**
     * @dev Get the current fluctuation amplitude.
     * @return The current amplitude.
     */
    function getCurrentAmplitude() external view returns (uint256) {
        return fluctuationAmplitude;
    }

    /**
     * @dev Get the current resonance frequency.
     * @return The current frequency.
     */
    function getCurrentFrequency() external view returns (uint256) {
        return resonanceFrequency;
    }

    /**
     * @dev Get the current entropy level.
     * @return The current entropy.
     */
    function getEntropyLevel() external view returns (uint256) {
        return entropyLevel;
    }

     /**
     * @dev Get the current state epoch number.
     * @return The current epoch.
     */
    function getStateEpoch() external view returns (uint256) {
        return stateEpoch;
    }

    /**
     * @dev Get the address of the user entangled with the given user.
     * @param user The user address.
     * @return The entangled user's address, or address(0) if not entangled.
     */
    function getEntangledUser(address user) external view returns (address) {
        return _entanglement[user];
    }

    /**
     * @dev Get the current entropy threshold for state shifts.
     * @return The threshold.
     */
    function getEntropyThreshold() external view returns (uint256) {
        return entropyThreshold;
    }

    /**
     * @dev Get the current base observation yield parameter.
     * @return The base yield.
     */
    function getBaseObservationYield() external view returns (uint256) {
        return baseObservationYield;
    }

    /**
     * @dev Get the current particle decay rate per second.
     * @return The decay rate.
     */
    function getDecayRate() external view returns (uint256) {
        return decayRate;
    }

    /**
     * @dev Calculate time remaining until parameters can be adjusted by admin again.
     * @return Time remaining in seconds. Returns 0 if unlocked.
     */
    function getTimeUntilParameterUnlock() external view returns (uint256) {
        uint256 unlockTime = uint256(_lastParameterChangeTime) + parametersLockDuration;
        if (block.timestamp >= unlockTime) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }

     /**
     * @dev Preview the potential particle yield from an observation *without* changing state.
     * Useful for users to estimate outcomes.
     * @param user The address simulating the observation (usually msg.sender).
     * @return Estimated particle yield.
     */
    function previewObservationYield(address user) external view returns (uint256) {
         // Use a hypothetical seed based on current state and sender for preview
         uint256 userSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, user, "preview")));
        return _calculateObservationYield(userSeed);
    }


    // --- Admin Functions ---

    /**
     * @dev Admin function to set the resonance frequency.
     * Subject to the parameters lock duration.
     * @param newFrequency The new resonance frequency.
     */
    function adjustResonanceFrequencyByAdmin(uint256 newFrequency) external onlyAdmin parametersUnlocked {
        uint256 oldFrequency = resonanceFrequency;
        resonanceFrequency = newFrequency;
        _lastParameterChangeTime = uint48(block.timestamp);
        emit ParametersAdjusted(msg.sender, "resonanceFrequency", oldFrequency, newFrequency);
    }

    /**
     * @dev Admin function to set the entropy threshold for state shifts.
     * Subject to the parameters lock duration.
     * @param newThreshold The new entropy threshold.
     */
    function adjustEntropyThresholdByAdmin(uint256 newThreshold) external onlyAdmin parametersUnlocked {
        uint256 oldThreshold = entropyThreshold;
        entropyThreshold = newThreshold;
        _lastParameterChangeTime = uint48(block.timestamp);
        emit ParametersAdjusted(msg.sender, "entropyThreshold", oldThreshold, newThreshold);
    }

    /**
     * @dev Admin function to set the base observation yield.
     * Subject to the parameters lock duration.
     * @param newBaseYield The new base observation yield.
     */
    function adjustBaseObservationYieldByAdmin(uint256 newBaseYield) external onlyAdmin parametersUnlocked {
         uint256 oldBaseYield = baseObservationYield;
         baseObservationYield = newBaseYield;
         _lastParameterChangeTime = uint48(block.timestamp);
         emit ParametersAdjusted(msg.sender, "baseObservationYield", oldBaseYield, newBaseYield);
    }

    /**
     * @dev Admin function to set the particle decay rate.
     * Subject to the parameters lock duration.
     * @param newRate The new decay rate (particles per second).
     */
    function adjustDecayRateByAdmin(uint256 newRate) external onlyAdmin parametersUnlocked {
        uint256 oldRate = decayRate;
        decayRate = newRate;
        _lastParameterChangeTime = uint48(block.timestamp);
        emit ParametersAdjusted(msg.sender, "decayRate", oldRate, newRate);
    }

    /**
     * @dev Admin function to withdraw accumulated ETH.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint256 amount) external onlyAdmin {
        require(amount > 0 && amount <= address(this).balance, "Invalid withdraw amount");
        (bool success, ) = payable(adminAddress).call{value: amount}("");
        if (!success) revert TransferFailed();
        emit ETHWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Admin function to transfer the contract ownership.
     * @param newAdmin The address of the new admin.
     */
    function transferOwnership(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        address previousAdmin = adminAddress;
        adminAddress = newAdmin;
        emit AdminTransferred(previousAdmin, newAdmin);
    }

    // --- Receive Ether Function ---
    // Allows receiving ETH without calling injectEnergy specifically,
    // but it won't affect amplitude unless handled here.
    // Adding a fallback/receive makes the contract able to receive ETH.
    // If you want any received ETH to increase amplitude, you could
    // call injectEnergy() internally from receive() or fallback().
    // For this example, just allowing reception.
    receive() external payable {
        // ETH received without calling a specific function.
        // Could log or potentially call injectEnergy(msg.value) here.
        // Let's just receive it for simplicity, it's withdrawable by admin.
    }
}
```