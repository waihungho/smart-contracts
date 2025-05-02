Okay, let's design an advanced, creative, and non-standard smart contract. We'll call it "QuantumLock".

The concept is inspired loosely by quantum mechanics principles: a deposit's state (specifically, who can access it and when) exists in a sort of "superposition" of possibilities until an "observation" or "measurement" event "collapses" the state into one definite outcome. We'll add concepts like "entanglement factors" that influence the probability distribution and "decoherence" if the state isn't measured in time.

**Disclaimer:** This contract uses pseudo-randomness based on blockchain data (`block.timestamp`, `block.number`, `block.difficulty` which is deprecated but included for conceptual hashing, etc.). This is susceptible to miner manipulation, especially on non-PoS chains. For production systems requiring secure randomness, a dedicated oracle (like Chainlink VRF) is necessary. This contract is for demonstrating complex concepts, not production-grade security randomness.

---

**Outline and Function Summary**

**Contract Name:** `QuantumLock`

**Concept:** A lock mechanism for Ether (`ETH`) deposits where the release conditions (recipient, amount, timing) are initially in a configurable "superposition" of possible outcomes. A specific "measurement" transaction collapses this superposition to a single, determined outcome based on pseudo-randomness influenced by internal state and external factors. Includes concepts like "entanglement factors" affecting probability distribution and "decoherence" for unmeasured states.

**State Variables:**

1.  `owner`: Contract deployer, administrative control.
2.  `paused`: Flag for pausing core operations.
3.  `currentEpoch`: A conceptual identifier for periods, deposits are tied to an epoch.
4.  `measurementWindow`: Duration (in seconds) after configuration during which measurement is allowed.
5.  `decoherenceTime`: Duration (in seconds) after measurement window closes, when state defaults to a predefined outcome.
6.  `globalEntanglementFactor`: A variable the owner can nudge, influencing pseudo-randomness.
7.  `depositStates`: Mapping user address to their active `DepositState` struct. Each user can only have one active state per epoch.
8.  `totalDepositedETH`: Total ETH held by the contract across all active deposits.

**Data Structures:**

1.  `Outcome`: Defines a single potential result of the "measurement".
    *   `recipient`: Address to send ETH to.
    *   `percentageBasisPoints`: Amount as a percentage of the initial deposit (0-10000, representing 0%-100%).
    *   `unlockTimestamp`: Timestamp after which withdrawal under this outcome is possible.
    *   `description`: A short text description (e.g., "Return to depositor", "Send to charity", "Unlock next year").
2.  `DepositState`: Represents a user's locked deposit and its current "quantum" state.
    *   `depositor`: The address that made the deposit.
    *   `amount`: The original ETH amount deposited.
    *   `epoch`: The epoch this deposit belongs to.
    *   `isConfigured`: True if outcomes and factors have been set.
    *   `isMeasured`: True if the measurement has occurred.
    *   `measuredOutcomeIndex`: Index of the `outcomes` array that was selected (if measured).
    *   `isDecohered`: True if the state decohered due to timeout.
    *   `outcomes`: Array of possible `Outcome` structs configured by the depositor.
    *   `entanglementFactors`: Bytes32 value provided by the depositor, influencing randomness.
    *   `configTimestamp`: Timestamp when configuration was completed.

**Functions (>= 20):**

1.  `constructor()`: Initializes the contract, sets owner and initial parameters.
2.  `depositETH()`: Allows users to deposit ETH and initiate a new deposit state for the current epoch. Payable.
3.  `configureOutcomes()`: Depositor sets the array of possible `Outcome` structs for their deposit state. Requires state not yet configured or measured.
4.  `configureEntanglementFactors()`: Depositor sets their specific `entanglementFactors` (bytes32) to influence the pseudo-random outcome selection. Requires state not yet configured or measured.
5.  `completeConfiguration()`: Depositor finalizes configuration, enabling measurement. Sets `isConfigured = true` and `configTimestamp`. Requires outcomes and factors to be set.
6.  `performMeasurement()`: Depositor (or anyone, depending on logic) triggers the "measurement". This function calculates a pseudo-random index based on various factors (block data, global factor, depositor factor) and selects one `Outcome` from the configured array. Sets `isMeasured = true` and `measuredOutcomeIndex`. Can only be called within the `measurementWindow`.
7.  `applyDecoherence()`: Can be called by anyone *after* the `decoherenceTime` has passed since configuration. If the deposit state was not measured, it sets `isDecohered = true`, defaulting to a specific outcome (e.g., index 0, often configured to return to depositor, or a special 'lost' state).
8.  `withdrawETH()`: Allows the designated recipient from the *measured* or *decohered* outcome to withdraw the specified amount *if* the `unlockTimestamp` condition is met.
9.  `resetUnconfiguredDeposit()`: Allows a depositor to reclaim their ETH and reset their deposit state *only if* it has not been configured or measured, and potentially within a grace period.
10. `getCurrentEpoch()`: View function to get the current global epoch number.
11. `getDepositState()`: View function to retrieve the full `DepositState` struct for a given user address.
12. `getOutcomeDetails()`: View function to see the details of all *configured* outcomes for a user's deposit state (before measurement).
13. `getMeasuredOutcome()`: View function to see the details of the *selected* outcome after measurement, or details of the decohered outcome if applicable.
14. `getMeasurementResultIndex()`: View function to get the index of the outcome selected by `performMeasurement`, or a special value if not measured/decohered.
15. `isMeasurementPossible()`: View function to check if a user's deposit state is currently eligible for `performMeasurement` (configured, not measured, within window).
16. `isWithdrawalPossible()`: View function to check if a withdrawal is currently possible for a specific address based on a measured/decohered state and timestamp.
17. `getTotalDeposited()`: View function to get the total amount of ETH held by the contract.
18. `setMeasurementWindow()`: Owner-only function to update the duration of the measurement window.
19. `setDecoherenceTime()`: Owner-only function to update the duration for decoherence.
20. `advanceEpoch()`: Owner-only function to increment the global epoch counter. This effectively isolates deposits into conceptual groups and requires new deposits to start fresh.
21. `nudgeGlobalEntanglement()`: Owner-only function to modify the `globalEntanglementFactor`, affecting the pseudo-random outcome calculation for future measurements.
22. `pause()`: Owner-only function to pause core operations (deposits, configuration, measurement, withdrawal).
23. `unpause()`: Owner-only function to unpause the contract.
24. `getGlobalEntanglementFactor()`: View function to see the current `globalEntanglementFactor`.
25. `getDecoherenceOutcomeDetails()`: View function to see the details of the outcome index designated for decoherence (e.g., outcome at index 0).
26. `getUnlockTimestampForOutcome()`: Helper view function to get the unlock time for a specific outcome index in a user's state.
27. `getRecipientForOutcome()`: Helper view function to get the recipient for a specific outcome index in a user's state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLock
 * @dev A conceptual smart contract simulating quantum mechanics principles
 *      (superposition, measurement, entanglement, decoherence) to determine
 *      access/withdrawal conditions for deposited ETH.
 *
 *      The state of a deposit (who can withdraw, when, how much) is initially
 *      in a "superposition" of configured outcomes. A 'measurement' action
 *      collapses this state based on pseudo-random factors. If not measured
 *      within a timeframe, the state "decoheres" to a default outcome.
 *
 *      DISCLAIMER: Uses pseudo-randomness based on block data, which is
 *      susceptible to manipulation, especially on PoW chains. Not suitable
 *      for applications requiring robust, unmanipulable randomness.
 */
contract QuantumLock {

    // --- State Variables ---

    address public owner;
    bool public paused;

    uint256 public currentEpoch; // Conceptual identifier for periods
    uint40 public measurementWindow; // Duration (seconds) after config for measurement
    uint40 public decoherenceTime;   // Duration (seconds) after window for decoherence

    // A factor potentially influenced by owner, conceptually represents a global state influence
    uint256 public globalEntanglementFactor;

    // Mapping from depositor address to their active deposit state for the current epoch
    mapping(address => DepositState) public depositStates;

    uint256 public totalDepositedETH; // Total ETH held by the contract

    // --- Data Structures ---

    /**
     * @dev Defines a single potential outcome of the 'measurement'.
     */
    struct Outcome {
        address recipient;
        uint16 percentageBasisPoints; // Amount as 1/100th of a percent (0-10000)
        uint40 unlockTimestamp;      // Timestamp after which withdrawal is possible
        string description;          // Short description of the outcome
    }

    /**
     * @dev Represents a user's locked deposit and its current state.
     */
    struct DepositState {
        address depositor;
        uint256 amount;
        uint256 epoch;

        bool isConfigured;    // True if outcomes and factors are set
        bool isMeasured;      // True if the measurement occurred
        int8 measuredOutcomeIndex; // Index of the selected outcome (-1 if not measured)
        bool isDecohered;     // True if the state decohered due to timeout

        Outcome[] outcomes; // Array of possible outcomes configured by the depositor

        bytes32 entanglementFactors; // Depositor-provided factor influencing randomness calculation
        uint40 configTimestamp;      // Timestamp when configuration was completed
    }

    // --- Events ---

    event EthDeposited(address indexed depositor, uint256 amount, uint256 epoch);
    event OutcomesConfigured(address indexed depositor, uint256 epoch, uint256 numOutcomes);
    event EntanglementFactorsConfigured(address indexed depositor, uint256 epoch, bytes32 factors);
    event ConfigurationCompleted(address indexed depositor, uint256 epoch, uint40 configTimestamp);
    event StateMeasured(address indexed depositor, uint256 epoch, uint8 selectedOutcomeIndex, uint256 pseudoRandomnessSeed);
    event StateDecohered(address indexed depositor, uint256 epoch, uint8 defaultOutcomeIndex);
    event EthWithdrawn(address indexed recipient, uint256 amount, uint256 epoch);
    event UnconfiguredDepositReset(address indexed depositor, uint256 epoch, uint256 refundedAmount);
    event EpochAdvanced(uint256 newEpoch);
    event GlobalEntanglementNudged(uint256 newFactor);
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "QL: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QL: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "QL: Not paused");
        _;
    }

    modifier onlyDepositor(address _depositor) {
        require(msg.sender == _depositor, "QL: Not depositor");
        _;
    }

    // --- Constructor ---

    constructor(uint40 _measurementWindow, uint40 _decoherenceTime) {
        owner = msg.sender;
        paused = false;
        currentEpoch = 1;
        measurementWindow = _measurementWindow;
        decoherenceTime = _decoherenceTime;
        globalEntanglementFactor = 1; // Start with a non-zero factor
    }

    // --- Core Functionality ---

    /**
     * @dev Allows a user to deposit ETH and create a new deposit state for the current epoch.
     *      A user can only have one active deposit state per epoch.
     */
    function depositETH() external payable whenNotPaused {
        require(msg.value > 0, "QL: Must deposit ETH");
        require(depositStates[msg.sender].epoch != currentEpoch, "QL: Active deposit exists for current epoch");

        depositStates[msg.sender] = DepositState({
            depositor: msg.sender,
            amount: msg.value,
            epoch: currentEpoch,
            isConfigured: false,
            isMeasured: false,
            measuredOutcomeIndex: -1, // -1 indicates not measured
            isDecohered: false,
            outcomes: new Outcome[](0), // Initialize empty
            entanglementFactors: bytes32(0), // Initialize zero
            configTimestamp: 0
        });

        totalDepositedETH += msg.value;
        emit EthDeposited(msg.sender, msg.value, currentEpoch);
    }

    /**
     * @dev Depositor configures the possible outcomes for their deposit.
     *      Can only be called once per deposit state, and before measurement.
     * @param _outcomes Array of possible outcomes.
     */
    function configureOutcomes(Outcome[] calldata _outcomes) external whenNotPaused onlyDepositor(msg.sender) {
        DepositState storage state = depositStates[msg.sender];
        require(state.epoch == currentEpoch, "QL: No active deposit for current epoch");
        require(!state.isConfigured, "QL: Deposit already configured");
        require(!state.isMeasured, "QL: Deposit already measured");
        require(_outcomes.length > 0 && _outcomes.length <= 8, "QL: Must provide 1-8 outcomes"); // Limit complexity

        state.outcomes = _outcomes;

        emit OutcomesConfigured(msg.sender, currentEpoch, _outcomes.length);
    }

    /**
     * @dev Depositor sets their entanglement factors, influencing the pseudo-random outcome.
     *      Can only be called once per deposit state, and before measurement.
     * @param _factors Bytes32 value provided by the depositor.
     */
    function configureEntanglementFactors(bytes32 _factors) external whenNotPaused onlyDepositor(msg.sender) {
        DepositState storage state = depositStates[msg.sender];
        require(state.epoch == currentEpoch, "QL: No active deposit for current epoch");
        require(!state.isConfigured, "QL: Deposit already configured");
        require(!state.isMeasured, "QL: Deposit already measured");
        require(_factors != bytes32(0), "QL: Factors cannot be zero");

        state.entanglementFactors = _factors;

        emit EntanglementFactorsConfigured(msg.sender, currentEpoch, _factors);
    }

    /**
     * @dev Completes the configuration phase. Must be called after setting outcomes and factors.
     *      Enables the 'measurement' phase and starts the timer for the measurement window and decoherence.
     */
    function completeConfiguration() external whenNotPaused onlyDepositor(msg.sender) {
        DepositState storage state = depositStates[msg.sender];
        require(state.epoch == currentEpoch, "QL: No active deposit for current epoch");
        require(!state.isConfigured, "QL: Deposit already configured");
        require(!state.isMeasured, "QL: Deposit already measured");
        require(state.outcomes.length > 0, "QL: Outcomes not configured");
        require(state.entanglementFactors != bytes32(0), "QL: Entanglement factors not configured");

        state.isConfigured = true;
        state.configTimestamp = uint40(block.timestamp);

        emit ConfigurationCompleted(msg.sender, currentEpoch, state.configTimestamp);
    }


    /**
     * @dev Performs the "measurement", collapsing the superposition to a single outcome.
     *      Calculates a pseudo-random index based on block data, global and user factors.
     *      Can only be called if configured, not measured, and within the measurement window.
     *      Can be called by the depositor or potentially anyone (allowing others to "observe").
     */
    function performMeasurement(address _depositor) external whenNotPaused {
        DepositState storage state = depositStates[_depositor];
        require(state.epoch == currentEpoch, "QL: No active deposit for current epoch");
        require(state.isConfigured, "QL: Deposit not configured");
        require(!state.isMeasured, "QL: Deposit already measured");
        require(!state.isDecohered, "QL: Deposit already decohered");
        require(block.timestamp >= state.configTimestamp, "QL: Configuration timestamp not reached?"); // Should not happen
        require(block.timestamp < state.configTimestamp + measurementWindow, "QL: Measurement window closed");

        // --- Pseudo-randomness Calculation ---
        // Combine various factors to generate a seed. Note: Block data is predictable/manipulable.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            // block.difficulty, // Deprecated, but conceptually relevant for hashing sources
            msg.sender, // The address triggering the measurement
            _depositor, // The deposit owner
            state.entanglementFactors, // Depositor's factor
            globalEntanglementFactor // Global factor
            // Potentially add historical data hashes if available (e.g., previous block hashes)
        )));

        uint8 selectedIndex = uint8(seed % state.outcomes.length);

        state.isMeasured = true;
        state.measuredOutcomeIndex = int8(selectedIndex);
        // configTimestamp remains, measurementTimestamp could be added if needed

        emit StateMeasured(_depositor, currentEpoch, selectedIndex, seed);
    }

    /**
     * @dev Applies decoherence to an unmeasured deposit state if the decoherence time has passed.
     *      Defaults the state to a specific outcome (e.g., index 0). Can be called by anyone.
     * @param _depositor The address of the deposit owner.
     */
    function applyDecoherence(address _depositor) external whenNotPaused {
        DepositState storage state = depositStates[_depositor];
        require(state.epoch == currentEpoch, "QL: No active deposit for current epoch");
        require(state.isConfigured, "QL: Deposit not configured"); // Must be configured to have outcomes/timers
        require(!state.isMeasured, "QL: Deposit already measured");
        require(!state.isDecohered, "QL: Deposit already decohered");
        require(block.timestamp >= state.configTimestamp + measurementWindow + decoherenceTime, "QL: Decoherence time not reached");
        require(state.outcomes.length > 0, "QL: No outcomes to decohere to"); // Should have outcomes if configured

        // Default to outcome index 0 upon decoherence
        uint8 defaultIndex = 0;
        require(defaultIndex < state.outcomes.length, "QL: Default decoherence outcome index out of bounds");

        state.isDecohered = true;
        state.measuredOutcomeIndex = int8(defaultIndex); // Set to default outcome index

        emit StateDecohered(_depositor, currentEpoch, defaultIndex);
    }

    /**
     * @dev Allows withdrawal based on the measured or decohered outcome.
     *      The caller must be the recipient defined in the selected outcome,
     *      and the unlock timestamp must have passed.
     * @param _depositor The address of the deposit owner whose state was measured/decohered.
     */
    function withdrawETH(address _depositor) external whenNotPaused {
        DepositState storage state = depositStates[_depositor];
        require(state.epoch == currentEpoch, "QL: No active deposit state found");
        require(state.isMeasured || state.isDecohered, "QL: Deposit state not measured or decohered");
        require(state.measuredOutcomeIndex >= 0 && uint8(state.measuredOutcomeIndex) < state.outcomes.length, "QL: Invalid measured outcome index");

        Outcome storage selectedOutcome = state.outcomes[uint8(state.measuredOutcomeIndex)];

        require(msg.sender == selectedOutcome.recipient, "QL: Not the designated recipient for this outcome");
        require(block.timestamp >= selectedOutcome.unlockTimestamp, "QL: Unlock time not reached yet");

        // Calculate withdrawal amount based on percentage
        uint256 withdrawalAmount = (state.amount * selectedOutcome.percentageBasisPoints) / 10000;
        require(withdrawalAmount > 0, "QL: Withdrawal amount is zero for this outcome"); // Or allow 0 if intended

        // Prevent re-withdrawal for the same deposit state/outcome?
        // The current structure implies a single withdrawal per state.
        // To prevent multiple withdrawals from a single outcome (e.g., if percentage < 100),
        // we would need to track remaining withdrawable amount per outcome/state, which adds complexity.
        // For this version, assume each state is withdrawn once per the outcome's parameters.
        // A simple way to prevent re-withdrawal: delete the deposit state after withdrawal.
        // Or, zero out the amount/percentage in the outcome within the state struct. Let's zero out the amount.

        uint256 amountToTransfer = withdrawalAmount;
        selectedOutcome.percentageBasisPoints = 0; // Mark as withdrawn by zeroing out percentage

        // Ensure enough ETH in the contract for the amount
        require(address(this).balance >= amountToTransfer, "QL: Insufficient contract balance");

        totalDepositedETH -= amountToTransfer;

        (bool success, ) = payable(selectedOutcome.recipient).call{value: amountToTransfer}("");
        require(success, "QL: ETH transfer failed");

        // Consider deleting or marking the state as fully processed if the percentage was 100
        // For simplicity, leaving the state struct there but with 0 percentage.

        emit EthWithdrawn(selectedOutcome.recipient, amountToTransfer, state.epoch);
    }

    /**
     * @dev Allows the depositor to reset their deposit state and reclaim ETH
     *      IF it has not been configured or measured yet.
     * @param _depositor The address of the deposit owner.
     */
    function resetUnconfiguredDeposit(address _depositor) external whenNotPaused onlyDepositor(msg.sender) {
        DepositState storage state = depositStates[_depositor];
        require(state.epoch == currentEpoch, "QL: No active deposit for current epoch");
        require(!state.isConfigured, "QL: Deposit already configured");
        require(!state.isMeasured, "QL: Deposit already measured");
        require(!state.isDecohered, "QL: Deposit already decohered");
        require(state.amount > 0, "QL: No deposit amount to reset"); // Should be true if epoch matches

        uint256 refundAmount = state.amount;
        totalDepositedETH -= refundAmount;

        // Delete the state from the mapping
        delete depositStates[_depositor];

        (bool success, ) = payable(_depositor).call{value: refundAmount}("");
        require(success, "QL: ETH refund failed");

        emit UnconfiguredDepositReset(_depositor, currentEpoch, refundAmount);
    }


    // --- Owner/Admin Functions ---

    /**
     * @dev Pauses the contract. Only owner.
     */
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only owner.
     */
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Owner can update the measurement window duration.
     * @param _measurementWindow The new duration in seconds.
     */
    function setMeasurementWindow(uint40 _measurementWindow) external onlyOwner {
        measurementWindow = _measurementWindow;
        // Consider adding an event
    }

    /**
     * @dev Owner can update the decoherence time duration.
     * @param _decoherenceTime The new duration in seconds.
     */
    function setDecoherenceTime(uint40 _decoherenceTime) external onlyOwner {
        decoherenceTime = _decoherenceTime;
         // Consider adding an event
    }

    /**
     * @dev Owner advances the global epoch counter.
     *      This effectively 'finalizes' the previous epoch conceptually,
     *      and new deposits start in the new epoch. Old states remain accessible
     *      via the getDepositState view function if needed, but core logic focuses
     *      on the current epoch via the direct mapping lookup.
     *      Note: This doesn't automatically process old states; `applyDecoherence`
     *      must still be called if needed for unmeasured states from the *previous* epoch
     *      if their timers have passed.
     */
    function advanceEpoch() external onlyOwner {
        currentEpoch++;
        emit EpochAdvanced(currentEpoch);
    }

    /**
     * @dev Owner can nudge the global entanglement factor.
     *      This changes a component used in the pseudo-randomness calculation.
     * @param _newFactor The new global entanglement factor.
     */
    function nudgeGlobalEntanglement(uint256 _newFactor) external onlyOwner {
        globalEntanglementFactor = _newFactor;
        emit GlobalEntanglementNudged(_newFactor);
    }

    // --- View Functions (Reading State) ---

    /**
     * @dev Gets the current global epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Retrieves the DepositState struct for a given depositor address for the *current* epoch.
     * @param _depositor The address of the depositor.
     * @return The DepositState struct.
     */
    function getDepositState(address _depositor) external view returns (DepositState memory) {
        // Note: This returns the state for the current epoch only.
        // Accessing states from past epochs would require a different mapping structure.
        return depositStates[_depositor];
    }

    /**
     * @dev Retrieves the configured outcome details for a depositor's state.
     *      Useful before measurement to see potential outcomes.
     * @param _depositor The address of the depositor.
     * @return Array of Outcome structs.
     */
    function getOutcomeDetails(address _depositor) external view returns (Outcome[] memory) {
        DepositState storage state = depositStates[_depositor];
        // Only return if outcomes are configured and state exists for current epoch
        if (state.epoch == currentEpoch && state.outcomes.length > 0) {
             return state.outcomes;
        } else {
            return new Outcome[](0); // Return empty array if no outcomes configured
        }
    }

     /**
     * @dev Retrieves the details of the measured (or decohered) outcome.
     * @param _depositor The address of the depositor.
     * @return The selected/decohered Outcome struct, or an empty struct if not measured/decohered.
     */
    function getMeasuredOutcome(address _depositor) external view returns (Outcome memory) {
        DepositState storage state = depositStates[_depositor];
        if ((state.isMeasured || state.isDecohered) && state.measuredOutcomeIndex >= 0 && uint8(state.measuredOutcomeIndex) < state.outcomes.length) {
            return state.outcomes[uint8(state.measuredOutcomeIndex)];
        } else {
            // Return a zero-initialized struct if no valid measured/decohered outcome
            return Outcome(address(0), 0, 0, "");
        }
    }

    /**
     * @dev Gets the index of the measured outcome. Returns -1 if not measured/decohered.
     * @param _depositor The address of the depositor.
     * @return The index (-1 if not measured).
     */
    function getMeasurementResultIndex(address _depositor) external view returns (int8) {
        return depositStates[_depositor].measuredOutcomeIndex;
    }

    /**
     * @dev Checks if a depositor has an active deposit state for the current epoch.
     * @param _depositor The address to check.
     * @return True if active, false otherwise.
     */
    function isActiveDeposit(address _depositor) external view returns (bool) {
        return depositStates[_depositor].epoch == currentEpoch && depositStates[_depositor].amount > 0;
    }

    /**
     * @dev Checks if a user's deposit state is currently eligible for 'measurement'.
     * @param _depositor The address of the depositor.
     * @return True if measurement is possible, false otherwise.
     */
    function isMeasurementPossible(address _depositor) external view returns (bool) {
        DepositState storage state = depositStates[_depositor];
        return state.epoch == currentEpoch &&
               state.isConfigured &&
               !state.isMeasured &&
               !state.isDecohered &&
               block.timestamp >= state.configTimestamp && // Should always be true if configTimestamp is set
               block.timestamp < state.configTimestamp + measurementWindow;
    }

    /**
     * @dev Checks if withdrawal is currently possible for a specific address from a depositor's state.
     *      Checks if measured/decohered and if the caller is the recipient and unlock time met.
     * @param _depositor The address of the depositor whose state is checked.
     * @param _recipient The potential recipient address (usually msg.sender in withdrawal).
     * @return True if withdrawal conditions *might* be met for this recipient, false otherwise.
     *         Note: Actual withdrawal requires the selected outcome to match _recipient.
     */
    function isWithdrawalPossible(address _depositor, address _recipient) external view returns (bool) {
        DepositState storage state = depositStates[_depositor];
        if (!(state.isMeasured || state.isDecohered) || state.measuredOutcomeIndex < 0 || uint8(state.measuredOutcomeIndex) >= state.outcomes.length) {
            return false; // Not measured/decohered or invalid outcome index
        }

        Outcome storage selectedOutcome = state.outcomes[uint8(state.measuredOutcomeIndex)];

        // Check if the recipient matches AND the unlock time has passed
        return selectedOutcome.recipient == _recipient &&
               block.timestamp >= selectedOutcome.unlockTimestamp &&
               selectedOutcome.percentageBasisPoints > 0; // Still has an amount to withdraw
    }

    /**
     * @dev Gets the total amount of ETH currently held by the contract across all deposits.
     */
    function getTotalDeposited() external view returns (uint256) {
        return totalDepositedETH;
    }

     /**
     * @dev Gets the original deposit amount for a user in the current epoch.
     * @param _depositor The address of the depositor.
     * @return The deposited amount. Returns 0 if no active deposit for current epoch.
     */
    function getDepositAmount(address _depositor) external view returns (uint256) {
        DepositState storage state = depositStates[_depositor];
        if (state.epoch == currentEpoch) {
            return state.amount;
        } else {
            return 0;
        }
    }

    /**
     * @dev Gets the current setting for the measurement window duration.
     */
    function getMeasurementWindow() external view returns (uint40) {
        return measurementWindow;
    }

    /**
     * @dev Gets the current setting for the decoherence time duration.
     */
    function getDecoherenceTime() external view returns (uint40) {
        return decoherenceTime;
    }

    /**
     * @dev Gets the current value of the global entanglement factor.
     */
    function getGlobalEntanglementFactor() external view returns (uint256) {
        return globalEntanglementFactor;
    }

    /**
     * @dev Gets the epoch in which a depositor's current state was created.
     * @param _depositor The address of the depositor.
     * @return The epoch number. Returns 0 if no active deposit state for current epoch.
     */
    function getDepositEpoch(address _depositor) external view returns (uint256) {
         return depositStates[_depositor].epoch == currentEpoch ? currentEpoch : 0;
    }

    /**
     * @dev Gets the entanglement factors configured by the depositor for their current state.
     * @param _depositor The address of the depositor.
     * @return The configured entanglement factors (bytes32). Returns bytes32(0) if not configured.
     */
    function getEntanglementFactors(address _depositor) external view returns (bytes32) {
        DepositState storage state = depositStates[_depositor];
         if (state.epoch == currentEpoch && state.isConfigured) {
            return state.entanglementFactors;
         } else {
             return bytes32(0);
         }
    }

     /**
     * @dev Gets the details of the outcome designated for decoherence (typically index 0).
     *      Note: This assumes outcome index 0 is the default decoherence outcome.
     *      The actual outcome details come from the depositor's configured outcomes.
     * @param _depositor The address of the depositor.
     * @return The Outcome struct for the default decoherence outcome (index 0), or an empty struct if none exists.
     */
    function getDecoherenceOutcomeDetails(address _depositor) external view returns (Outcome memory) {
         DepositState storage state = depositStates[_depositor];
         if (state.epoch == currentEpoch && state.outcomes.length > 0) {
             return state.outcomes[0]; // Assuming index 0 is the default
         } else {
             return Outcome(address(0), 0, 0, "");
         }
    }

    // --- Helper View Functions for Outcome Details (Optional, but useful for client) ---
    // These access specific fields of configured/measured outcomes for a depositor's state.

     /**
     * @dev Gets the unlock timestamp for a specific outcome index for a depositor's state.
     *      Useful before measurement.
     * @param _depositor The address of the depositor.
     * @param _index The index of the outcome.
     * @return The unlock timestamp, or 0 if index is invalid or not configured.
     */
    function getUnlockTimestampForOutcome(address _depositor, uint8 _index) external view returns (uint40) {
        DepositState storage state = depositStates[_depositor];
        if (state.epoch == currentEpoch && _index < state.outcomes.length) {
            return state.outcomes[_index].unlockTimestamp;
        }
        return 0;
    }

    /**
     * @dev Gets the recipient address for a specific outcome index for a depositor's state.
     *      Useful before measurement.
     * @param _depositor The address of the depositor.
     * @param _index The index of the outcome.
     * @return The recipient address, or address(0) if index is invalid or not configured.
     */
    function getRecipientForOutcome(address _depositor, uint8 _index) external view returns (address) {
        DepositState storage state = depositStates[_depositor];
         if (state.epoch == currentEpoch && _index < state.outcomes.length) {
            return state.outcomes[_index].recipient;
        }
        return address(0);
    }

     /**
     * @dev Gets the percentage (in basis points) for a specific outcome index for a depositor's state.
     *      Useful before measurement.
     * @param _depositor The address of the depositor.
     * @param _index The index of the outcome.
     * @return The percentage in basis points, or 0 if index is invalid or not configured.
     */
    function getPercentageForOutcome(address _depositor, uint8 _index) external view returns (uint16) {
        DepositState storage state = depositStates[_depositor];
         if (state.epoch == currentEpoch && _index < state.outcomes.length) {
            return state.outcomes[_index].percentageBasisPoints;
        }
        return 0;
    }
}
```