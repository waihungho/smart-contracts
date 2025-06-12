```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLock
 * @dev An experimental smart contract simulating a "Quantum Lock" mechanism.
 *      Funds or access can be locked and only potentially unlocked based on a
 *      complex, evolving internal state (`quantumStateSeed`). This state is influenced
 *      by time, block data entropy, and user interactions (`perturbState`, `mixEntropy`, etc.).
 *      The core concept is the `attemptMeasurement` function, which "observes" the
 *      current state, finalizing an outcome (`measurementResult`) that determines
 *      whether unlock conditions are met. This measurement is intended to be
 *      sensitive to the state at the exact moment of observation, making prediction
 *      difficult without influencing the state.
 *      The contract includes features for per-user lock configurations, state
 *      entanglement simulation with external keys, timed measurement windows,
 *      and potential state "tunneling" under rare conditions.
 *      NOTE: This contract uses blockchain data (block.timestamp, block.number, difficulty, coinbase, keccak256)
 *      as sources of entropy. While this is the standard practice on EVM, these are
 *      potentially manipulable by miners/validators, especially 'difficulty' and 'coinbase'.
 *      For high-security random outcomes, a dedicated on-chain VRF (like Chainlink VRF)
 *      or commit-reveal scheme is recommended. This contract prioritizes conceptual
 *      simulation over cryptographically secure randomness for its core state evolution.
 */

// --- Outline ---
// 1. State Variables: Store core contract state (owner, seed, funds, lock parameters, measurement state).
// 2. Events: Announce key actions (locking, measurement, release, state changes).
// 3. Errors: Custom errors for better revert reasons.
// 4. Modifiers: Restrict function access (`onlyOwner`, state-dependent checks).
// 5. Structs: Define complex data types (user lock parameters, measurement state).
// 6. Constructor: Initialize contract state.
// 7. Receive/Fallback: Allow receiving Ether.
// 8. Core Lock/Unlock Functions: `lockFunds`, `attemptMeasurement`, `releaseFunds`, `claimFailedAttemptFunds`.
// 9. State Manipulation Functions: `perturbState`, `mixEntropy`, `applyPhaseShift`, `registerExternalObservation`, `simulateQuantumTunneling`.
// 10. Configuration Functions: `configureLockParameters`, `setMeasurementWindow`, `setMinimumInteractionCount`, `entangleWithKey`, `decoupleFromKey`.
// 11. Query Functions: `getCurrentStateSeed`, `getLockParameters`, `getMeasurementResult`, `isStateMeasured`, `getTotalLockedFunds`, `getUserLockedFunds`, `getEntangledKeys`, `getInteractionCount`.
// 12. Utility/Management Functions: `resetMeasurementCycle`, `emergencyRelease`.

// --- Function Summary ---
// 1. constructor(): Deploys the contract, sets owner, initializes state seed.
// 2. receive(): Allows the contract to receive Ether.
// 3. lockFunds(bytes32[] calldata _entangledKeys, LockParameters calldata _params): Locks Ether sent with the transaction for the sender, configures per-user lock parameters and initial entangled keys.
// 4. configureLockParameters(LockParameters calldata _params): Allows a user to update their specific lock parameters *before* a measurement attempt.
// 5. perturbState(): Modifies the global `quantumStateSeed` using block data and current state, simulating environmental interaction. Increments interaction count.
// 6. mixEntropy(): A different mechanism to modify the seed, emphasizing entropy from recent block hashes. Increments interaction count.
// 7. applyPhaseShift(): Another seed modification method, potentially based on interaction count or time. Increments interaction count.
// 8. entangleWithKey(bytes32 _key): Adds a specific identifier (`_key`) to the sender's list of entangled keys, influencing their potential measurement outcome.
// 9. decoupleFromKey(bytes32 _key): Removes an identifier from the sender's entangled keys.
// 10. attemptMeasurement(): The core "observation" function. Checks conditions, calculates a final state value based on the current `quantumStateSeed`, block data, and user's entangled keys. Sets the `userMeasurementState` (isMeasured, result). Can only be called once per cycle per user within a window.
// 11. releaseFunds(): Allows a user to withdraw their locked funds *only if* their last `attemptMeasurement` resulted in a successful outcome.
// 12. claimFailedAttemptFunds(): Allows a user to withdraw their locked funds after a cooldown period if their last `attemptMeasurement` failed.
// 13. getCurrentStateSeed() view: Returns the current value of the global `quantumStateSeed`.
// 14. getLockParameters(address _user) view: Returns the `LockParameters` set for a specific user.
// 15. getMeasurementResult(address _user) view: Returns the `measurementResult` for a user's last measurement attempt.
// 16. isStateMeasured(address _user) view: Returns true if a user has an active measurement attempt cycle.
// 17. getTotalLockedFunds() view: Returns the total amount of Ether locked in the contract across all users.
// 18. getUserLockedFunds(address _user) view: Returns the amount of Ether locked by a specific user.
// 19. setMeasurementWindow(uint256 _start, uint256 _end): Owner sets the block numbers during which `attemptMeasurement` is allowed.
// 20. setMinimumInteractionCount(uint256 _count): Owner sets a global minimum number of state interactions before any measurement can occur.
// 21. getRequiredInteractionCount() view: Returns the global minimum interaction count.
// 22. registerExternalObservation(bytes32 _observationData): Allows the owner or other authorized entity to introduce external simulated data into the state seed calculation.
// 23. simulateQuantumTunneling(uint256 _specificInput): A complex, low-probability function allowing the owner (or multi-sig) to force the state seed to a specific value based on rare conditions being met. Intended to simulate a state bypass or rare event.
// 24. getEntangledKeys(address _user) view: Returns the list of entangled keys for a specific user.
// 25. getInteractionCount() view: Returns the total number of state interaction functions (`perturbState`, `mixEntropy`, `applyPhaseShift`, `registerExternalObservation`) called.
// 26. resetMeasurementCycle(): Allows a user to reset their measurement state after a cooldown, enabling a new `attemptMeasurement`.
// 27. emergencyRelease(address _user): Owner function to release a user's funds immediately in an emergency (e.g., contract bug, critical issue).

contract QuantumLock {

    // --- State Variables ---
    address public immutable owner;
    uint256 public quantumStateSeed;
    uint256 public totalInteractionCount; // Count of functions that modify the state seed

    // Mapping from user address to their locked Ether balance
    mapping(address => uint256) public lockedFunds;

    // Structure defining per-user lock parameters
    struct LockParameters {
        uint256 targetSeedMin; // Minimum value for the 'measured' seed to be successful
        uint256 targetSeedMax; // Maximum value for the 'measured' seed to be successful
        uint256 requiredUserInteractions; // Minimum *user-initiated* interactions needed before measurement (future feature concept)
        uint256 claimFailureCooldown; // Blocks to wait after failed measurement before claiming back
    }
    // Mapping from user address to their specific lock parameters
    mapping(address => LockParameters) public lockParams;

    // Structure defining the state of a user's measurement attempt
    struct UserMeasurementState {
        bool isMeasured; // True if an attempt has been made in the current cycle
        bool measurementResult; // True if the measurement was successful
        uint256 attemptBlock; // Block number when the attempt was made
        bytes32 measuredValueHash; // The hash value calculated during measurement
    }
    // Mapping from user address to their measurement state
    mapping(address => UserMeasurementState) public userMeasurementState;

    // Mapping from user address to their list of entangled keys (simulated)
    mapping(address => bytes32[]) public userEntangledKeys;

    // Global window for allowing measurement attempts (by block number)
    uint256 public measurementWindowStartBlock;
    uint256 public measurementWindowEndBlock;

    // Global minimum interactions required on the state seed before any measurement is allowed
    uint256 public minimumInteractionsForMeasurement;

    // --- Events ---
    event FundsLocked(address indexed user, uint256 amount, bytes32[] entangledKeys);
    event LockParametersUpdated(address indexed user, uint256 targetMin, uint256 targetMax, uint256 claimCooldown);
    event StatePerturbed(address indexed caller, uint256 newSeed);
    event EntangledWithKey(address indexed user, bytes32 key);
    event DecoupledFromKey(address indexed user, bytes32 key);
    event MeasurementAttempt(address indexed user, uint256 blockNumber);
    event MeasurementTaken(address indexed user, bool success, bytes32 measuredValueHash);
    event FundsReleased(address indexed user, uint256 amount);
    event FailedAttemptFundsClaimed(address indexed user, uint256 amount);
    event MeasurementWindowUpdated(uint256 startBlock, uint256 endBlock);
    event MinimumInteractionsUpdated(uint256 count);
    event ExternalObservationRegistered(address indexed caller, bytes32 data, uint256 newSeed);
    event QuantumTunnelingSimulated(address indexed caller, uint256 input, uint256 forcedSeed);
    event MeasurementCycleReset(address indexed user);
    event EmergencyRelease(address indexed user, uint256 amount);


    // --- Errors ---
    error OnlyOwner();
    error NoFundsLocked();
    error AlreadyMeasuredInCycle();
    error MeasurementNotAttempted();
    error MeasurementFailed();
    error CannotReleaseYet(); // For cooldown after failure
    error MeasurementWindowClosed();
    error InsufficientStateInteractions();
    error KeyNotFound();
    error InvalidMeasurementWindow();
    error TunnelingConditionsNotMet();
    error NotPermitted();
    error NoMeasurementAttempted();
    error CooldownInProgress(uint256 blocksRemaining);
    error CannotResetBeforeClaimOrCooldown();


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier whenNotMeasured(address _user) {
        if (userMeasurementState[_user].isMeasured) revert AlreadyMeasuredInCycle();
        _;
    }

    modifier whenMeasured(address _user) {
        if (!userMeasurementState[_user].isMeasured) revert NoMeasurementAttempted();
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        // Initialize seed with some initial entropy
        quantumStateSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));
        totalInteractionCount = 0;
        measurementWindowStartBlock = 0; // Default to always closed until set
        measurementWindowEndBlock = 0;
        minimumInteractionsForMeasurement = 0;
    }

    // --- Receive/Fallback ---
    receive() external payable {}

    // --- Core Lock/Unlock Functions ---

    /**
     * @dev Locks Ether sent with the transaction for the caller.
     * @param _entangledKeys Initial list of keys to entangle this lock with.
     * @param _params Specific lock parameters for this user.
     */
    function lockFunds(bytes32[] calldata _entangledKeys, LockParameters calldata _params) external payable whenNotMeasured(msg.sender) {
        if (msg.value == 0) revert NoFundsLocked(); // Or maybe error NoEtherSent();
        lockedFunds[msg.sender] += msg.value;
        lockParams[msg.sender] = _params;
        userEntangledKeys[msg.sender] = _entangledKeys; // Overwrites existing keys

        emit FundsLocked(msg.sender, msg.value, _entangledKeys);
        emit LockParametersUpdated(msg.sender, _params.targetSeedMin, _params.targetSeedMax, _params.claimFailureCooldown);
    }

    /**
     * @dev Attempts to "measure" the quantum state to determine unlock success.
     *      This function calculates a value based on the current state seed,
     *      block data, and user's entangled keys.
     *      Can only be called once per measurement cycle per user within the active window.
     */
    function attemptMeasurement() external whenNotMeasured(msg.sender) {
        if (lockedFunds[msg.sender] == 0) revert NoFundsLocked();
        if (block.number < measurementWindowStartBlock || block.number > measurementWindowEndBlock) revert MeasurementWindowClosed();
        if (totalInteractionCount < minimumInteractionsForMeasurement) revert InsufficientStateInteractions();

        // Simulate measurement process: calculate a hash based on current state and user factors
        bytes32 measuredValueHash = keccak256(abi.encodePacked(
            quantumStateSeed,
            block.timestamp,
            block.number,
            block.difficulty,
            block.coinbase,
            msg.sender,
            userEntangledKeys[msg.sender]
        ));

        // Convert hash to uint256 for comparison
        uint256 measuredValue = uint256(measuredValueHash);

        // Check if the measured value falls within the user's target range
        bool success = (measuredValue >= lockParams[msg.sender].targetSeedMin && measuredValue <= lockParams[msg.sender].targetSeedMax);

        // Record the measurement outcome
        userMeasurementState[msg.sender] = UserMeasurementState({
            isMeasured: true,
            measurementResult: success,
            attemptBlock: block.number,
            measuredValueHash: measuredValueHash
        });

        emit MeasurementAttempt(msg.sender, block.number);
        emit MeasurementTaken(msg.sender, success, measuredValueHash);
    }

    /**
     * @dev Releases locked funds if the last measurement attempt was successful.
     */
    function releaseFunds() external whenMeasured(msg.sender) {
        UserMeasurementState storage state = userMeasurementState[msg.sender];
        if (!state.measurementResult) revert MeasurementFailed();
        if (lockedFunds[msg.sender] == 0) revert NoFundsLocked();

        uint256 amountToRelease = lockedFunds[msg.sender];
        lockedFunds[msg.sender] = 0; // Update state before external call

        // Reset user's measurement state after successful claim
        delete userMeasurementState[msg.sender];
        // Optionally delete entangled keys or reset params here too if one-time lock

        // Use call for safe Ether transfer
        (bool success,) = payable(msg.sender).call{value: amountToRelease}("");
        if (!success) {
            // If transfer fails, try to revert state changes or handle recovery
            // Reverting is simplest for this example
            revert("Ether transfer failed");
        }

        emit FundsReleased(msg.sender, amountToRelease);
    }

    /**
     * @dev Allows claiming locked funds after a cooldown period if the last measurement failed.
     */
    function claimFailedAttemptFunds() external whenMeasured(msg.sender) {
        UserMeasurementState storage state = userMeasurementState[msg.sender];
        if (state.measurementResult) revert CannotReleaseYet(); // Measurement was successful, use releaseFunds
        if (lockedFunds[msg.sender] == 0) revert NoFundsLocked();

        uint256 cooldownEnds = state.attemptBlock + lockParams[msg.sender].claimFailureCooldown;
        if (block.number < cooldownEnds) revert CooldownInProgress(cooldownEnds - block.number);

        uint256 amountToClaim = lockedFunds[msg.sender];
        lockedFunds[msg.sender] = 0; // Update state before external call

        // Reset user's measurement state after claiming failed funds
        delete userMeasurementState[msg.sender];
        // Optionally delete entangled keys or reset params here too

        // Use call for safe Ether transfer
        (bool success,) = payable(msg.sender).call{value: amountToClaim}("");
         if (!success) {
            revert("Ether transfer failed");
        }

        emit FailedAttemptFundsClaimed(msg.sender, amountToClaim);
    }

     /**
      * @dev Allows a user to reset their measurement cycle after a cooldown,
      * enabling them to call `attemptMeasurement` again.
      * Requires either claiming funds after failure or a cooldown period after a successful release (if state wasn't deleted).
      */
    function resetMeasurementCycle() external {
        UserMeasurementState storage state = userMeasurementState[msg.sender];

        // Cannot reset if no attempt was made
        if (!state.isMeasured) revert NoMeasurementAttempted();

        // Cannot reset if funds are still locked and claim/release hasn't happened
        if (lockedFunds[msg.sender] > 0) {
            // Check if cooldown after failure has passed, or if funds were released successfully
            uint256 cooldownEnds = state.attemptBlock + lockParams[msg.sender].claimFailureCooldown;
            if (!state.measurementResult && block.number < cooldownEnds) {
                 revert CannotResetBeforeClaimOrCooldown(); // Still in failed attempt cooldown
            }
            // If state.measurementResult is true and lockedFunds > 0, it implies releaseFunds wasn't called after success, which is an inconsistency.
            // In a real contract, this might need stricter state transitions or owner intervention.
            // For this simulation, we'll assume lockedFunds[msg.sender] == 0 implies funds were handled.
             revert CannotResetBeforeClaimOrCooldown(); // Funds still locked, must handle them first.
        }

        // If lockedFunds is 0 (meaning release or claim happened) AND cooldown (if failed) is over, allow reset.
        delete userMeasurementState[msg.sender];

        emit MeasurementCycleReset(msg.sender);
    }


    // --- State Manipulation Functions ---

    /**
     * @dev Perturbs the global state seed using current block data.
     * Simulates external influence or environmental noise. Anyone can call.
     */
    function perturbState() external {
        quantumStateSeed = uint256(keccak256(abi.encodePacked(
            quantumStateSeed,
            block.timestamp,
            block.number,
            block.coinbase,
            msg.sender // Incorporate caller address to add more potential variability
        )));
        totalInteractionCount++;
        emit StatePerturbed(msg.sender, quantumStateSeed);
    }

     /**
      * @dev Mixes entropy from recent block hashes into the state seed.
      * Requires a minimum block number to access blockhash.
      */
    function mixEntropy() external {
        uint256 currentBlock = block.number;
        // Need sufficient block history for blockhash
        if (currentBlock <= 256) revert("Need more block history");

        // Mix hashes from several recent blocks
        bytes32 mixedHash = keccak256(abi.encodePacked(
            quantumStateSeed,
            blockhash(currentBlock - 1),
            blockhash(currentBlock - 10),
            blockhash(currentBlock - 100),
            block.timestamp,
            block.difficulty
        ));
        quantumStateSeed = uint256(mixedHash);
        totalInteractionCount++;
        emit StatePerturbed(msg.sender, quantumStateSeed); // Use generic StatePerturbed event
    }

    /**
     * @dev Applies a "phase shift" like modification to the state seed.
     * Formula is arbitrary, designed to create non-linear changes.
     */
    function applyPhaseShift() external {
        // Example non-linear transformation
        uint256 shift = (totalInteractionCount * block.timestamp) % 1000 + 1; // Ensure shift is at least 1
        quantumStateSeed = (quantumStateSeed << shift) | (quantumStateSeed >> (256 - shift)); // Circular shift
        quantumStateSeed ^= uint256(keccak256(abi.encodePacked(block.number, msg.sender))); // XOR with more entropy
        totalInteractionCount++;
        emit StatePerturbed(msg.sender, quantumStateSeed); // Use generic StatePerturbed event
    }


    /**
     * @dev Registers external simulated observation data influencing the seed.
     * Only owner or authorized can call. Simulates external oracle or input.
     * @param _observationData Arbitrary data bytes.
     */
    function registerExternalObservation(bytes32 _observationData) external onlyOwner {
         quantumStateSeed = uint256(keccak256(abi.encodePacked(
            quantumStateSeed,
            _observationData,
            block.timestamp,
            block.number,
            msg.sender
        )));
        totalInteractionCount++;
        emit ExternalObservationRegistered(msg.sender, _observationData, quantumStateSeed);
    }

    /**
     * @dev Simulates a rare quantum tunneling event allowing forced state change.
     * Requires specific, hard-to-predict conditions to be met. Owner-only.
     * The conditions are arbitrary and complex to simulate rarity.
     * @param _specificInput An arbitrary input required for the "tunneling" to occur.
     */
    function simulateQuantumTunneling(uint256 _specificInput) external onlyOwner {
        // Simulate complex, hard-to-meet conditions
        // Example: State seed must have a specific property AND block data must align AND specific input matches a pattern
        bool conditionsMet = (quantumStateSeed % 10000 == 4242) && // Specific seed property
                             (block.timestamp % 7 == 0) &&        // Specific time property
                             (block.difficulty > 1000000) &&       // High difficulty (less predictable)
                             (uint256(keccak256(abi.encodePacked(_specificInput, block.number))) % 99 == 50); // Input/block derived pattern

        if (!conditionsMet) revert TunnelingConditionsNotMet();

        // Force the state seed to a new value derived from the input and current state
        uint256 forcedSeed = uint256(keccak256(abi.encodePacked(quantumStateSeed, _specificInput, block.timestamp, block.number)));
        quantumStateSeed = forcedSeed;
        totalInteractionCount++; // Still counts as an interaction
        emit QuantumTunnelingSimulated(msg.sender, _specificInput, forcedSeed);
    }

    // --- Configuration Functions ---

    /**
     * @dev Allows a user to configure their lock parameters (target range, cooldown)
     *      before a measurement attempt.
     * @param _params The new lock parameters.
     */
    function configureLockParameters(LockParameters calldata _params) external whenNotMeasured(msg.sender) {
         // Optional: Add validation for _params values (e.g., min <= max)
        lockParams[msg.sender] = _params;
        emit LockParametersUpdated(msg.sender, _params.targetSeedMin, _params.targetSeedMax, _params.claimFailureCooldown);
    }

     /**
      * @dev Adds a key to the sender's list of entangled keys.
      * Influences their `attemptMeasurement` outcome.
      * @param _key The key to add.
      */
    function entangleWithKey(bytes32 _key) external {
        // Check if key already exists (optional, depends on desired behavior)
        // For simplicity, we allow duplicates in this example
        userEntangledKeys[msg.sender].push(_key);
        emit EntangledWithKey(msg.sender, _key);
    }

    /**
     * @dev Removes a key from the sender's list of entangled keys.
     * @param _key The key to remove.
     */
    function decoupleFromKey(bytes32 _key) external {
        bytes32[] storage keys = userEntangledKeys[msg.sender];
        bool found = false;
        for (uint i = 0; i < keys.length; i++) {
            if (keys[i] == _key) {
                // Found the key, replace it with the last element and shrink the array
                keys[i] = keys[keys.length - 1];
                keys.pop();
                found = true;
                break; // Assuming unique keys aren't required, remove only the first match
            }
        }
        if (!found) revert KeyNotFound();
        emit DecoupledFromKey(msg.sender, _key);
    }

    /**
     * @dev Owner sets the block number window during which `attemptMeasurement` is allowed.
     * @param _start The start block number (inclusive).
     * @param _end The end block number (inclusive). Set 0,0 to close window.
     */
    function setMeasurementWindow(uint256 _start, uint256 _end) external onlyOwner {
        if (_start > _end && _end != 0) revert InvalidMeasurementWindow(); // Allow 0,0 to close
        measurementWindowStartBlock = _start;
        measurementWindowEndBlock = _end;
        emit MeasurementWindowUpdated(_start, _end);
    }

    /**
     * @dev Owner sets a global minimum number of state interactions required
     *      before any user can call `attemptMeasurement`.
     * @param _count The minimum interaction count.
     */
    function setMinimumInteractionCount(uint256 _count) external onlyOwner {
        minimumInteractionsForMeasurement = _count;
        emit MinimumInteractionsUpdated(_count);
    }


    // --- Query Functions ---

    /**
     * @dev Returns the current global quantum state seed.
     */
    function getCurrentStateSeed() public view returns (uint256) {
        return quantumStateSeed;
    }

    /**
     * @dev Returns the lock parameters configured by a specific user.
     * @param _user The user address.
     */
    function getLockParameters(address _user) public view returns (LockParameters memory) {
        return lockParams[_user];
    }

    /**
     * @dev Returns the result of a user's last measurement attempt.
     * @param _user The user address.
     */
    function getMeasurementResult(address _user) public view returns (bool) {
        return userMeasurementState[_user].measurementResult;
    }

    /**
     * @dev Returns true if a user has made a measurement attempt in the current cycle.
     * @param _user The user address.
     */
    function isStateMeasured(address _user) public view returns (bool) {
        return userMeasurementState[_user].isMeasured;
    }

    /**
     * @dev Returns the total amount of Ether currently locked in the contract.
     */
    function getTotalLockedFunds() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the amount of Ether locked by a specific user.
     * @param _user The user address.
     */
    function getUserLockedFunds(address _user) public view returns (uint256) {
        return lockedFunds[_user];
    }

    /**
     * @dev Returns the list of entangled keys for a specific user.
     * @param _user The user address.
     */
    function getEntangledKeys(address _user) public view returns (bytes32[] memory) {
        return userEntangledKeys[_user];
    }

    /**
     * @dev Returns the total count of interactions that have modified the state seed.
     */
    function getInteractionCount() public view returns (uint256) {
        return totalInteractionCount;
    }

    /**
     * @dev Returns the globally required minimum interaction count for measurement.
     */
    function getRequiredInteractionCount() public view returns (uint256) {
        return minimumInteractionsForMeasurement;
    }

    /**
     * @dev Returns the block number of the user's last measurement attempt.
     * @param _user The user address.
     */
     function getAttemptBlock(address _user) public view returns (uint256) {
        return userMeasurementState[_user].attemptBlock;
     }

    /**
     * @dev Returns the calculated hash value from the user's last measurement attempt.
     * @param _user The user address.
     */
     function getMeasuredValueHash(address _user) public view returns (bytes32) {
        return userMeasurementState[_user].measuredValueHash;
     }


    // --- Utility/Management Functions ---

     /**
      * @dev Owner function to release a user's funds immediately in an emergency.
      * Bypasses all lock logic.
      * @param _user The user whose funds to release.
      */
    function emergencyRelease(address _user) external onlyOwner {
        uint256 amountToRelease = lockedFunds[_user];
        if (amountToRelease == 0) return; // Nothing to release

        lockedFunds[_user] = 0; // Update state first
        // Optionally delete measurement state and entangled keys
        delete userMeasurementState[_user];
        delete userEntangledKeys[_user];

        (bool success,) = payable(_user).call{value: amountToRelease}("");
         if (!success) {
             // In an emergency function, reverting is often preferred
             revert("Emergency Ether transfer failed");
         }

        emit EmergencyRelease(_user, amountToRelease);
    }
}
```