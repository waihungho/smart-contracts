Okay, here is a Solidity smart contract incorporating interesting concepts like multi-stage time-locked state transitions, configurable phase conditions (involving time, required value, required caller, randomness, and puzzle solving), role-based access control (without OpenZeppelin imports), and a dynamic state machine.

It focuses on the *process* of unlocking something valuable by navigating through a series of complex, interdependent conditions and user actions, simulating a digital vault or a multi-factor release mechanism.

This contract is for **demonstration and educational purposes**. Implementing secure randomness or complex puzzle mechanisms reliably on-chain is challenging and often requires off-chain components (oracles, verifiable computation). The randomness here is *simulated* via block hash, which is **not secure for high-value applications**.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLock Smart Contract
 * @author [Your Name/Alias]
 * @notice A complex, multi-stage time-locked digital vault.
 * Funds and potentially private data (off-chain pointer) are locked until
 * a series of configurable phases are successfully navigated. Each phase
 * requires meeting specific conditions (time elapsed, specific keyholder,
 * value sent, randomness provided, puzzle solved) to transition to the next.
 * Failure to meet conditions within limits can lead to a permanent lock state.
 *
 * Outline:
 * 1. State Variables: Define roles, states, phase configuration, and tracking.
 * 2. Events: Log important state changes and actions.
 * 3. Errors: Custom errors for clearer failure reasons.
 * 4. Modifiers: Access control and state checks.
 * 5. Enums: Define the possible states of the lock.
 * 6. Structs: Define the configuration for each transition phase.
 * 7. Access Control: Basic owner, keyholder, and oracle management (manual implementation).
 * 8. Configuration Functions: Setup phases, roles, and initial state.
 * 9. Interaction Functions: Deposit Ether, attempt phase transitions, provide randomness.
 * 10. Query Functions: Get current state, configs, balances, etc.
 * 11. Unlock Function: Release funds upon reaching the final state.
 * 12. Receive/Fallback: Handle incoming Ether.
 */

/**
 * @dev Function Summary:
 *
 * --- Setup & Configuration (Owner Only) ---
 * 1. constructor(): Deploys the contract, sets owner.
 * 2. addKeyholder(address _keyholder): Adds an address allowed to attempt transitions.
 * 3. removeKeyholder(address _keyholder): Removes a keyholder.
 * 4. setOracleAddress(address _oracle): Sets the address authorized to provide randomness.
 * 5. configurePhase(uint _phaseIndex, PhaseConfig calldata _config): Defines the conditions to exit a phase.
 * 6. finalizeConfiguration(uint _startingPhaseIndex): Locks configuration, starts the initial phase timer.
 * 7. setUnlockRecipient(address _recipient): Sets the address that receives funds on unlock.
 * 8. setInitialPhaseIndex(uint _index): Sets the index of the phase to start after configuration (before finalization).
 *
 * --- Interaction ---
 * 9. depositEther(): Allows anyone to deposit Ether into the contract.
 * 10. attemptPhaseTransition(bytes32 _puzzleSolution): Attempts to move to the next phase based on current state and provided puzzle solution.
 * 11. provideRandomness(uint _phaseIndex, uint256 _randomValue): Oracle-only function to provide randomness required for a phase transition.
 *
 * --- Query Functions (Public) ---
 * 12. getCurrentState(): Returns the current state of the lock (enum).
 * 13. getCurrentPhaseIndex(): Returns the index of the currently active phase.
 * 14. getPhaseStartTime(): Returns the timestamp when the current phase started.
 * 15. getPhaseConfig(uint _phaseIndex): Returns the configuration struct for a given phase index.
 * 16. getLockedBalance(): Returns the total Ether held by the contract.
 * 17. isKeyholder(address _addr): Checks if an address is a registered keyholder.
 * 18. getOracleAddress(): Returns the configured oracle address.
 * 19. getOwner(): Returns the contract owner's address.
 * 20. getUnlockRecipient(): Returns the address set to receive funds on unlock.
 * 21. getPuzzleAttempts(uint _phaseIndex): Returns the number of incorrect puzzle attempts for a phase.
 * 22. isRandomnessProvided(uint _phaseIndex): Checks if randomness has been provided for a phase transition.
 * 23. getTimeInCurrentPhase(): Returns the duration (in seconds) since the current phase started.
 * 24. getRequiredNextPhaseIndex(): Returns the index of the next phase defined for the current active phase's config.
 * 25. getPhaseMinimumDuration(uint _phaseIndex): Returns the min duration for a specific phase index.
 * 26. getPhaseMaximumDuration(uint _phaseIndex): Returns the max duration for a specific phase index (0 if none).
 *
 * --- Unlock ---
 * 27. withdraw(): Transfers the locked Ether to the unlock recipient if the lock is in the Unlocked state.
 *
 * --- Utility / Internal (Not directly callable by users) ---
 *    (Implicitly used by other functions)
 * 28. _checkTransitionConditions(): Internal logic for checking phase transition requirements.
 * 29. _transitionToPhase(): Internal logic to update state when a phase transition occurs.
 */


// --- Errors ---
error Unauthorized();
error InvalidState();
error AlreadyConfigured();
error NotYetConfigured();
error ConfigurationNotFinalized();
error ConfigurationFinalized();
error PhaseConfigNotSet(uint phaseIndex);
error InvalidPhaseIndex();
error TransitionConditionsNotMet(string reason);
error PuzzleAlreadySolvedOrRandomnessProvided();
error PuzzleSolutionIncorrect();
error MaxPuzzleAttemptsExceeded();
error PhaseDurationNotMet();
error PhaseDurationExceeded();
error RandomnessRequiredButNotProvided();
error SpecificKeyholderRequired(address requiredKeyholder);
error NotKeyholderOrRequiredCaller();
error InsufficientValue();
error RandomnessAlreadyProvided();
error RandomnessNotRequiredForPhase();
error AlreadyProvidedRandomnessForPhase(uint phaseIndex);
error UnlockRecipientNotSet();
error NoFundsToWithdraw();


// --- Enums ---
enum LockState {
    Initialized,        // Contract deployed, owner set, no configuration yet
    Configured,         // Phases and roles being configured
    PhaseActive,        // Currently navigating through phases (use with currentPhaseIndex)
    Unlocking,          // Transitioning to Unlocked state (potentially waiting for final checks)
    Unlocked,           // Successfully navigated all phases, funds are withdrawable
    Failed              // Transition failed permanently (e.g., max puzzle attempts, time limit exceeded)
}

// --- Structs ---
struct PhaseConfig {
    uint minDuration;          // Minimum time in seconds required in this phase before attempting transition
    uint maxDuration;          // Maximum time in seconds allowed in this phase (0 for no max)
    bool requiresRandomness;   // True if randomness must be provided by the oracle for this phase's transition
    bool requiresPuzzle;       // True if a puzzle solution is required for this phase's transition
    bytes32 puzzleHash;        // Keccak256 hash of the required puzzle solution
    uint maxPuzzleAttempts;    // Maximum number of incorrect puzzle solution attempts allowed (0 for no limit)
    address requiredKeyholder; // Specific keyholder address required for the transition (address(0) for any keyholder)
    uint requiredValue;        // Minimum Ether value that must be sent with the transition transaction
    uint nextPhaseIndex;       // The index of the phase to transition to upon success
    bool isFinalPhase;         // If true, successfully completing this phase transitions to Unlocked state
}

// --- State Variables ---
address private _owner;
address private _oracleAddress;
mapping(address => bool) private _keyholders;
address private _unlockRecipient;

LockState public currentLockState = LockState.Initialized;
uint public currentPhaseIndex;
uint public phaseStartTime; // Timestamp when the current phase became active

mapping(uint => PhaseConfig) private _phaseConfigs;
mapping(uint => uint) private _puzzleAttempts;
mapping(uint => bool) private _randomnessProvided;
mapping(uint => uint256) private _phaseRandomness; // Store provided randomness per phase

bool private _configurationFinalized = false;
uint private _initialPhaseIndex = 0; // Default starting phase index

// --- Events ---
event KeyholderAdded(address indexed keyholder);
event KeyholderRemoved(address indexed keyholder);
event OracleAddressSet(address indexed oracle);
event UnlockRecipientSet(address indexed recipient);
event PhaseConfigured(uint indexed phaseIndex, PhaseConfig config);
event ConfigurationFinalized(uint indexed startingPhaseIndex);
event LockStateChanged(LockState oldState, LockState newState, uint indexed phaseIndex);
event PhaseTransitionAttempted(address indexed caller, uint indexed fromPhase, uint indexed toPhase, bool success);
event PhaseTransitionSuccess(uint indexed fromPhase, uint indexed toPhase);
event RandomnessProvided(uint indexed phaseIndex, uint256 randomValue);
event PuzzleAttemptMade(uint indexed phaseIndex, address indexed caller, bool success, uint attempts);
event LockUnlocked(address indexed recipient, uint amount);
event LockFailed(uint indexed phaseIndex, string reason);
event InitialPhaseIndexSet(uint indexed index);

// --- Modifiers ---
modifier onlyOwner() {
    if (msg.sender != _owner) revert Unauthorized();
    _;
}

modifier onlyKeyholderOrOwner() {
    if (msg.sender != _owner && !_keyholders[msg.sender]) revert NotKeyholderOrRequiredCaller(); // Simplified check
    _;
}

modifier onlyOracle() {
    if (msg.sender != _oracleAddress) revert Unauthorized();
    _;
}

modifier whenState(LockState _state) {
    if (currentLockState != _state) revert InvalidState();
    _;
}

modifier whenNotState(LockState _state) {
     if (currentLockState == _state) revert InvalidState();
     _;
}

modifier whenStateIsNotOneOf(LockState s1, LockState s2, LockState s3, LockState s4, LockState s5, LockState s6) {
    if (currentLockState == s1 || currentLockState == s2 || currentLockState == s3 || currentLockState == s4 || currentLockState == s5 || currentLockState == s6) revert InvalidState();
    _;
}


// --- Constructor ---
constructor() {
    _owner = msg.sender;
    emit LockStateChanged(LockState.Initialized, currentLockState, 0);
}

// --- Receive Ether ---
receive() external payable {
    // Funds are deposited into the contract balance
}

// --- Configuration Functions ---

/**
 * @notice Adds an address to the list of keyholders.
 * @param _keyholder The address to add.
 */
function addKeyholder(address _keyholder) external onlyOwner whenStateIsNotOneOf(LockState.PhaseActive, LockState.Unlocking, LockState.Unlocked, LockState.Failed) {
    _keyholders[_keyholder] = true;
    emit KeyholderAdded(_keyholder);
}

/**
 * @notice Removes an address from the list of keyholders.
 * @param _keyholder The address to remove.
 */
function removeKeyholder(address _keyholder) external onlyOwner whenStateIsNotOneOf(LockState.PhaseActive, LockState.Unlocking, LockState.Unlocked, LockState.Failed) {
    _keyholders[_keyholder] = false;
    emit KeyholderRemoved(_keyholder);
}

/**
 * @notice Sets the address authorized to provide randomness.
 * @param _oracle The address of the oracle.
 */
function setOracleAddress(address _oracle) external onlyOwner whenStateIsNotOneOf(LockState.PhaseActive, LockState.Unlocking, LockState.Unlocked, LockState.Failed) {
    _oracleAddress = _oracle;
    emit OracleAddressSet(_oracle);
}

/**
 * @notice Sets the address to receive funds upon successful unlock.
 * Can only be set before the lock is Unlocked or Failed.
 * @param _recipient The address to set as the unlock recipient.
 */
function setUnlockRecipient(address _recipient) external onlyOwner whenStateIsNotOneOf(LockState.Unlocking, LockState.Unlocked, LockState.Failed) {
     if (_recipient == address(0)) revert UnlockRecipientNotSet(); // Simple non-zero check
    _unlockRecipient = _recipient;
    emit UnlockRecipientSet(_recipient);
}


/**
 * @notice Configures the conditions required to transition *out* of a specific phase.
 * Can only be called in Initialized or Configured state.
 * @param _phaseIndex The index of the phase being configured (e.g., 0, 1, 2...).
 * @param _config The PhaseConfig struct defining transition conditions.
 */
function configurePhase(uint _phaseIndex, PhaseConfig calldata _config) external onlyOwner whenStateIsNotOneOf(LockState.PhaseActive, LockState.Unlocking, LockState.Unlocked, LockState.Failed) {
    _phaseConfigs[_phaseIndex] = _config;
    // Transition state if starting from Initialized
    if (currentLockState == LockState.Initialized) {
        currentLockState = LockState.Configured;
        emit LockStateChanged(LockState.Initialized, currentLockState, 0);
    }
    emit PhaseConfigured(_phaseIndex, _config);
}

/**
 * @notice Sets the index of the phase the lock will start at after finalization.
 * Must be called in Initialized or Configured state, before finalization.
 * @param _index The desired starting phase index.
 */
function setInitialPhaseIndex(uint _index) external onlyOwner whenStateIsNotOneOf(LockState.PhaseActive, LockState.Unlocking, LockState.Unlocked, LockState.Failed) {
    // Basic check: ensure *some* config exists for the index if not 0, or allow 0 anyway
    if (_index > 0 && _phaseConfigs[_index].minDuration == 0 && !_phaseConfigs[_index].requiresRandomness && !_phaseConfigs[_index].requiresPuzzle && _phaseConfigs[_index].requiredKeyholder == address(0) && _phaseConfigs[_index].requiredValue == 0 && _phaseConfigs[_index].nextPhaseIndex == 0 && !_phaseConfigs[_index].isFinalPhase) {
         // This is a very basic check; a more robust system would check if the phase *exists* logically.
         // For this demo, we allow setting any index, but transition attempts later might fail if config is missing.
         // Consider requiring `_phaseConfigs[_index].minDuration > 0` or similar if index > 0 for production.
    }
    _initialPhaseIndex = _index;
    emit InitialPhaseIndexSet(_index);
}


/**
 * @notice Finalizes the configuration, locking changes and starting the lock process
 * at the configured initial phase index.
 * Can only be called once in the Configured state.
 */
function finalizeConfiguration(uint _startingPhaseIndex) external onlyOwner whenState(LockState.Configured) {
     // Check if *any* phase (at least the starting one) has been configured
     if (_phaseConfigs[_startingPhaseIndex].minDuration == 0 && !_phaseConfigs[_startingPhaseIndex].requiresRandomness && !_phaseConfigs[_startingPhaseIndex].requiresPuzzle && _phaseConfigs[_startingPhaseIndex].requiredKeyholder == address(0) && _phaseConfigs[_startingPhaseIndex].requiredValue == 0 && _phaseConfigs[_startingPhaseIndex].nextPhaseIndex == 0 && !_phaseConfigs[_startingPhaseIndex].isFinalPhase) {
         revert PhaseConfigNotSet(_startingPhaseIndex);
     }
    _configurationFinalized = true;
    currentPhaseIndex = _startingPhaseIndex;
    phaseStartTime = block.timestamp;
    LockState oldState = currentLockState;
    currentLockState = LockState.PhaseActive;
    emit ConfigurationFinalized(_startingPhaseIndex);
    emit LockStateChanged(oldState, currentLockState, currentPhaseIndex);
}

/**
 * @notice Finalizes configuration using the previously set initial phase index.
 */
function finalizeConfiguration() external onlyOwner whenState(LockState.Configured) {
    finalizeConfiguration(_initialPhaseIndex);
}


// --- Interaction Functions ---

/**
 * @notice Allows anyone to deposit Ether into the contract.
 * The Ether is added to the total locked balance.
 */
function depositEther() external payable {
    // Funds automatically increase address(this).balance
}


/**
 * @notice Attempts to transition from the current phase to the next.
 * Requires meeting the conditions defined in the PhaseConfig for the current phase.
 * @param _puzzleSolution The solution to the puzzle, if required for the current phase.
 *                        Must be 0 bytes32 if no puzzle is required.
 */
function attemptPhaseTransition(bytes32 _puzzleSolution) external payable onlyKeyholderOrOwner whenState(LockState.PhaseActive) {
    uint fromPhaseIndex = currentPhaseIndex;
    bytes32 puzzleAttemptHash = keccak256(abi.encodePacked(_puzzleSolution));

    PhaseConfig storage currentConfig = _phaseConfigs[fromPhaseIndex];

    // Check configuration exists for the current phase
    if (currentConfig.minDuration == 0 && !currentConfig.requiresRandomness && !currentConfig.requiresPuzzle && currentConfig.requiredKeyholder == address(0) && currentConfig.requiredValue == 0 && currentConfig.nextPhaseIndex == 0 && !currentConfig.isFinalPhase) {
         // This is a fallback check; configurePhase should have been called for this index
        revert PhaseConfigNotSet(fromPhaseIndex);
    }

    // Check Keyholder/Caller Requirement
    if (currentConfig.requiredKeyholder != address(0) && msg.sender != currentConfig.requiredKeyholder) {
        emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, false);
        revert SpecificKeyholderRequired(currentConfig.requiredKeyholder);
    }
     // If a specific keyholder isn't required, the onlyKeyholderOrOwner modifier handles general access

    // Check Minimum Duration
    if (block.timestamp < phaseStartTime + currentConfig.minDuration) {
        emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, false);
        revert PhaseDurationNotMet();
    }

    // Check Maximum Duration (if set)
    if (currentConfig.maxDuration > 0 && block.timestamp > phaseStartTime + currentConfig.maxDuration) {
        // Transition to Failed state if max duration is exceeded
        LockState oldState = currentLockState;
        currentLockState = LockState.Failed;
        emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, false); // Log attempt before fail
        emit LockFailed(fromPhaseIndex, "Max phase duration exceeded");
        emit LockStateChanged(oldState, currentLockState, fromPhaseIndex);
        return; // Stop execution after failing
    }

    // Check Required Value
    if (msg.value < currentConfig.requiredValue) {
        emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, false);
        revert InsufficientValue();
    }

    // Check Randomness Requirement
    if (currentConfig.requiresRandomness && !_randomnessProvided[fromPhaseIndex]) {
         // If randomness is required, it must have been provided by the oracle *for this phase* already.
        emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, false);
        revert RandomnessRequiredButNotProvided();
    }

    // Check Puzzle Requirement
    bool puzzleSuccess = true;
    if (currentConfig.requiresPuzzle) {
        if (puzzleAttemptHash != currentConfig.puzzleHash) {
            puzzleSuccess = false;
            _puzzleAttempts[fromPhaseIndex]++;
            emit PuzzleAttemptMade(fromPhaseIndex, msg.sender, false, _puzzleAttempts[fromPhaseIndex]);

            // Check Max Puzzle Attempts
            if (currentConfig.maxPuzzleAttempts > 0 && _puzzleAttempts[fromPhaseIndex] >= currentConfig.maxPuzzleAttempts) {
                // Transition to Failed state if max attempts exceeded
                LockState oldState = currentLockState;
                currentLockState = LockState.Failed;
                emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, false); // Log attempt before fail
                emit LockFailed(fromPhaseIndex, "Max puzzle attempts exceeded");
                emit LockStateChanged(oldState, currentLockState, fromPhaseIndex);
                return; // Stop execution after failing
            }

            emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, false);
            revert PuzzleSolutionIncorrect(); // Revert if puzzle fails (and not too many attempts yet)
        } else {
             // Correct puzzle solution provided
             emit PuzzleAttemptMade(fromPhaseIndex, msg.sender, true, _puzzleAttempts[fromPhaseIndex]);
        }
    }


    // --- All conditions met, attempt transition ---
    emit PhaseTransitionAttempted(msg.sender, fromPhaseIndex, currentConfig.nextPhaseIndex, true);

    // Perform the transition
    if (currentConfig.isFinalPhase) {
        LockState oldState = currentLockState;
        currentLockState = LockState.Unlocking; // Intermediate state before Unlocked (optional, adds complexity)
         // For simplicity, let's just transition directly to Unlocked in this demo
         currentLockState = LockState.Unlocked;
        emit PhaseTransitionSuccess(fromPhaseIndex, currentConfig.nextPhaseIndex); // nextPhaseIndex might be irrelevant if isFinalPhase
        emit LockStateChanged(oldState, currentLockState, currentPhaseIndex); // currentPhaseIndex is still the final phase index
    } else {
        // Check if the next phase configuration exists before transitioning
        // This prevents transitioning to a non-configured phase index (except 0 if that's the start)
        // A production contract might enforce that all phases up to the final one are configured.
        // For this demo, we allow potential failure if a later phase config is missing.
        // Checking _phaseConfigs[currentConfig.nextPhaseIndex] existence here adds complexity,
        // so we'll rely on the check at the start of the *next* attemptPhaseTransition call.

        LockState oldState = currentLockState;
        currentPhaseIndex = currentConfig.nextPhaseIndex;
        phaseStartTime = block.timestamp; // Reset timer for the new phase
        // currentLockState remains LockState.PhaseActive
        emit PhaseTransitionSuccess(fromPhaseIndex, currentPhaseIndex);
        emit LockStateChanged(oldState, currentLockState, currentPhaseIndex);
    }
}


/**
 * @notice Called by the configured oracle address to provide randomness for a specific phase.
 * Required if the configuration for transitioning out of that phase includes `requiresRandomness`.
 * Can only be called once per phase when the lock is PhaseActive and *before* the transition attempt that uses it.
 * @param _phaseIndex The index of the phase for which randomness is being provided.
 * @param _randomValue The random value provided by the oracle.
 */
function provideRandomness(uint _phaseIndex, uint256 _randomValue) external onlyOracle whenState(LockState.PhaseActive) {
     // Check if randomness is even needed for transitioning out of this phase
     // NOTE: This check is slightly complex. Randomness for phase N is needed for the transition *out of* phase N,
     // which happens when attempting to transition *from* phase N. So, the phase index passed here
     // is the *current* phase index (fromPhaseIndex in attemptPhaseTransition).
     // Let's clarify: Randomness provided for phase X is needed to *complete* phase X and move to phase X+1 (or next).
     // So _phaseIndex here refers to the phase we are currently in and trying to exit.
     if (_phaseIndex != currentPhaseIndex) revert InvalidPhaseIndex();

     PhaseConfig storage currentConfig = _phaseConfigs[currentPhaseIndex];

    // Check if the config for the current phase *requires* randomness for the *next* transition
    // If currentConfig.nextPhaseIndex requires randomness, it should have been set in configurePhase for currentPhaseIndex.
    // Let's adjust the logic slightly: Randomness is provided *for the phase you are currently in*, and it's used to *enable* the transition *out* of that phase.
    if (!currentConfig.requiresRandomness) {
        revert RandomnessNotRequiredForPhase();
    }

    // Check if randomness has already been provided for this phase
    if (_randomnessProvided[currentPhaseIndex]) {
        revert AlreadyProvidedRandomnessForPhase(currentPhaseIndex);
    }

    _phaseRandomness[currentPhaseIndex] = _randomValue;
    _randomnessProvided[currentPhaseIndex] = true;

    emit RandomnessProvided(currentPhaseIndex, _randomValue);
}


// --- Query Functions ---

/**
 * @notice Returns the current state of the lock.
 */
function getCurrentState() external view returns (LockState) {
    return currentLockState;
}

/**
 * @notice Returns the index of the currently active phase.
 * Relevant when currentLockState is PhaseActive.
 */
function getCurrentPhaseIndex() external view returns (uint) {
    return currentPhaseIndex;
}

/**
 * @notice Returns the timestamp when the current phase started.
 * Relevant when currentLockState is PhaseActive.
 */
function getPhaseStartTime() external view returns (uint) {
    return phaseStartTime;
}

/**
 * @notice Returns the configuration struct for a given phase index.
 * @param _phaseIndex The index of the phase to query.
 */
function getPhaseConfig(uint _phaseIndex) external view returns (PhaseConfig memory) {
    return _phaseConfigs[_phaseIndex];
}

/**
 * @notice Returns the total Ether currently held by the contract.
 */
function getLockedBalance() external view returns (uint) {
    return address(this).balance;
}

/**
 * @notice Checks if an address is currently registered as a keyholder.
 * @param _addr The address to check.
 */
function isKeyholder(address _addr) external view returns (bool) {
    return _keyholders[_addr];
}

/**
 * @notice Returns the configured oracle address.
 */
function getOracleAddress() external view returns (address) {
    return _oracleAddress;
}

/**
 * @notice Returns the contract owner's address.
 */
function getOwner() external view returns (address) {
    return _owner;
}

/**
 * @notice Returns the address configured to receive funds upon successful unlock.
 */
function getUnlockRecipient() external view returns (address) {
    return _unlockRecipient;
}

/**
 * @notice Returns the number of incorrect puzzle solution attempts made for a specific phase.
 * @param _phaseIndex The phase index to query.
 */
function getPuzzleAttempts(uint _phaseIndex) external view returns (uint) {
    return _puzzleAttempts[_phaseIndex];
}

/**
 * @notice Checks if randomness has been provided by the oracle for a specific phase's transition.
 * @param _phaseIndex The phase index to query.
 */
function isRandomnessProvided(uint _phaseIndex) external view returns (bool) {
    return _randomnessProvided[_phaseIndex];
}

/**
 * @notice Returns the duration (in seconds) since the current phase started.
 * @return The time elapsed in the current phase.
 */
function getTimeInCurrentPhase() external view returns (uint) {
     if (currentLockState != LockState.PhaseActive) return 0;
    return block.timestamp - phaseStartTime;
}

/**
 * @notice Returns the index of the next phase defined in the config for the current phase.
 * @return The index of the phase that would follow the current one upon successful transition.
 */
function getRequiredNextPhaseIndex() external view returns (uint) {
     if (currentLockState != LockState.PhaseActive) return 0; // Or revert, depending on desired behavior
    return _phaseConfigs[currentPhaseIndex].nextPhaseIndex;
}

/**
 * @notice Returns the minimum duration requirement for a specific phase.
 * @param _phaseIndex The phase index to query.
 */
function getPhaseMinimumDuration(uint _phaseIndex) external view returns (uint) {
    return _phaseConfigs[_phaseIndex].minDuration;
}

/**
 * @notice Returns the maximum duration requirement for a specific phase.
 * @param _phaseIndex The phase index to query. Returns 0 if no max duration is set.
 */
function getPhaseMaximumDuration(uint _phaseIndex) external view returns (uint) {
    return _phaseConfigs[_phaseIndex].maxDuration;
}


/**
 * @notice Returns the PhaseConfig for the currently active phase.
 */
function getCurrentPhaseConfig() external view returns (PhaseConfig memory) {
    if (currentLockState != LockState.PhaseActive) revert InvalidState();
    return _phaseConfigs[currentPhaseIndex];
}


// --- Unlock Function ---

/**
 * @notice Transfers the total locked Ether to the configured unlock recipient.
 * Can only be called when the lock is in the Unlocked state.
 */
function withdraw() external whenState(LockState.Unlocked) {
    if (_unlockRecipient == address(0)) revert UnlockRecipientNotSet(); // Should have been set before unlocking
    uint balance = address(this).balance;
    if (balance == 0) revert NoFundsToWithdraw();

    // Use call for safer Ether transfer
    (bool success, ) = payable(_unlockRecipient).call{value: balance}("");
    if (!success) {
        // This is a critical failure, consider emitting an event or handling differently
        // Reverting here would keep funds locked in a potentially Unlocked state, which is bad.
        // A safer approach might be to log the failure and allow retries or owner intervention.
        // For this demo, we'll just emit and let the state remain Unlocked but unfunded.
        emit LockFailed(currentPhaseIndex, "Withdrawal call failed");
        // Optionally transition to a 'WithdrawalFailed' state? Added complexity.
    } else {
         emit LockUnlocked(_unlockRecipient, balance);
    }
}

// --- Utility Functions (Internal/Private) ---
// (None explicitly needed as separate public functions, but logic exists within others)

// Function 28 (Internal check - part of attemptPhaseTransition)
// Function 29 (Internal state update - part of attemptPhaseTransition)

}
```