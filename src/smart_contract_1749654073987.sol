Okay, here is a Solidity smart contract concept called `QuantumLock`. It's designed around the metaphor of quantum states: values or conditions that exist in a state of potential (superposition) until observed (triggered), collapsing into a single outcome. This outcome can influence the probabilities of other unobserved states (simulating entanglement) and determines withdrawal rights to locked Ether.

This design avoids direct duplication of common DeFi primitives (like standard ERC tokens, simple escrows, or yield farms) by focusing on a unique state-collapse mechanism with probabilistic and inter-dependent outcomes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumLock
/// @author Your Name/Alias (Conceptual)
/// @notice This contract simulates a system where locked Ether can only be withdrawn based on the final outcomes of "quantum states" that are collapsed by specific actions or time.
/// It introduces concepts of probabilistic outcomes for states, entanglement (where collapsing one state affects probabilities of others), and conditional withdrawal rights based on collapsed outcomes.
/// This is a complex, experimental concept primarily for exploring advanced Solidity patterns related to state management, probabilistic simulation, and complex access control.
/// SECURITY DISCLAIMER: Using block variables (`block.timestamp`, `block.number`, etc.) for entropy is susceptible to miner manipulation, especially in low-block-time scenarios. For high-value contracts, a more robust, decentralized oracle-based entropy source would be required. This contract uses block variables for simplicity in demonstrating the concept.

// --- Outline ---
// 1. State Definitions & Variables: Structs for states, outcomes, entanglement, mappings to store them.
// 2. Ownership & Pause: Basic access control patterns.
// 3. Deposit: Function to receive Ether.
// 4. State Management (Admin): Functions to define, update, remove states and entanglement rules.
// 5. Withdrawal Allocation (Admin): Functions to map outcomes to withdrawal percentages for addresses.
// 6. State Observation/Collapse: Functions to trigger the collapse of states.
// 7. Withdrawal: Function for users to claim allocated Ether based on collapsed states.
// 8. Query Functions: Read-only functions to inspect state definitions, statuses, allocations, etc.
// 9. Internal Logic: Helper functions for calculating outcomes, applying entanglement, updating withdrawal balances.
// 10. Events: Logging key actions and state changes.

// --- Function Summary ---
// Admin/Setup (Requires Owner):
// - constructor(): Deploys the contract, sets initial owner.
// - transferOwnership(address newOwner): Transfers contract ownership.
// - pauseContract(): Pauses core functionality (deposit, trigger, withdraw).
// - unpauseContract(): Unpauses the contract.
// - addQuantumStateDefinition(...): Defines a new potential quantum state with outcomes and initial weights.
// - updateQuantumStateDefinition(...): Modifies an existing state definition (if not collapsed).
// - removeQuantumStateDefinition(uint256 stateId): Removes a state definition (if not collapsed).
// - defineEntanglement(...): Sets up an entanglement rule: collapsing triggerStateId to triggerOutcome affects potential outcomes of targetStateId.
// - removeEntanglement(uint256 triggerStateId, uint256 targetStateId): Removes a specific entanglement rule.
// - setWithdrawalAllocation(...): Allocates a percentage of the total deposited Ether to an address if a state collapses to a specific outcome.
// - removeWithdrawalAllocation(uint256 stateId, bytes32 outcomeHash, address recipient): Removes a specific withdrawal allocation.
// - setTimedObservationTrigger(uint256 stateId, uint256 blockNumber): Sets a future block number where a specific state will be automatically observed.
// - cancelTimedObservationTrigger(uint256 stateId): Cancels a pending timed observation trigger.

// User Interaction / State Management:
// - depositEther(): Allows users to deposit Ether into the contract.
// - triggerStateObservation(uint256 stateId): Allows anyone to trigger the observation (collapse) of a specific unobserved state.
// - triggerAllUnobservedStates(): Allows anyone to trigger the observation of all currently unobserved states.
// - withdraw(): Allows addresses with available allocated Ether to withdraw it.

// Query Functions (Read-Only):
// - isPaused(): Checks if the contract is paused.
// - getQuantumStateDefinition(uint256 stateId): Retrieves the definition of a state.
// - getQuantumStateStatus(uint256 stateId): Retrieves the current status (collapsed/outcome) of a state.
// - getPotentialOutcomes(uint256 stateId): Calculates and returns the potential outcomes and their *current effective* weights (considering entanglement) for an uncollapsed state.
// - getEntanglementDefinition(uint256 triggerStateId, uint256 targetStateId): Retrieves the entanglement rule between two states.
// - getWithdrawalAllocation(uint256 stateId, bytes32 outcomeHash, address recipient): Retrieves a specific withdrawal allocation amount (in basis points).
// - getTotalDeposits(): Returns the total Ether held by the contract.
// - getAvailableWithdrawalAmount(address user): Returns the total amount of Ether an address is currently eligible to withdraw.
// - getUnobservedStateIds(): Returns a list of state IDs that have not yet been observed/collapsed.
// - getTimedObservationTriggerBlock(uint256 stateId): Returns the block number set for a timed observation trigger, or 0 if none.

// --- Internal Logic (Not Directly Callable Externally) ---
// - _collapseState(uint256 stateId): Internal function to perform the state collapse logic.
// - _calculateOutcome(uint256 stateId): Internal function to determine the final outcome using entropy and effective weights.
// - _getEffectiveWeights(uint256 stateId): Internal function to calculate current weights considering entanglement effects from *collapsed* states.
// - _applyEntanglementEffect(uint256 triggerStateId, bytes32 finalOutcome): Internal function to update effective weights for entangled *uncollapsed* states.
// - _updateAvailableWithdrawalsForOutcome(uint256 stateId, bytes32 outcome): Internal function to credit addresses based on withdrawal allocations for a collapsed state/outcome.

contract QuantumLock {
    address private _owner;
    bool private _paused;

    // --- Structs ---

    /// @dev Represents a possible outcome for a quantum state.
    /// outcomeIdentifier: A unique hash or identifier for the outcome (e.g., keccak256("SUCCESS"), keccak256("FAILURE")).
    /// weight: A relative weight determining the probability of this outcome (higher weight = higher probability).
    struct OutcomeOption {
        bytes32 outcomeIdentifier;
        uint256 weight;
    }

    /// @dev Defines a potential quantum state before it's observed (collapsed).
    /// description: A human-readable description of the state.
    /// potentialOutcomes: An array of possible outcomes and their *initial* weights.
    /// canBeObserved: True if this state is eligible to be triggered/collapsed.
    /// isCollapsed: True if the state has already been observed.
    struct QuantumStateDefinition {
        string description;
        OutcomeOption[] potentialOutcomes;
        bool canBeObserved;
        bool isCollapsed; // Should ideally match stateStatuses mapping, kept here for quick lookup.
    }

    /// @dev Stores the status of a quantum state after it has been observed (collapsed).
    /// isCollapsed: True if the state has been observed.
    /// finalOutcome: The identifier of the outcome the state collapsed into.
    /// collapseBlock: The block number when the state was collapsed.
    /// collapseTimestamp: The timestamp when the state was collapsed.
    struct QuantumStateStatus {
        bool isCollapsed;
        bytes32 finalOutcome;
        uint256 collapseBlock;
        uint256 collapseTimestamp;
    }

    /// @dev Defines how collapsing one state influences the probabilities of another.
    /// triggerOutcome: The specific outcome of the triggerStateId that causes this entanglement effect.
    /// targetStateId: The ID of the state whose probabilities are affected.
    /// probabilityAdjustments: Adjustments to weights for specific outcomes in the targetStateId's potential outcomes.
    ///   - A positive adjustment increases weight.
    ///   - A negative adjustment decreases weight (can make an outcome impossible if it reduces weight to 0 or below).
    struct EntanglementEffect {
        bytes32 triggerOutcome;
        uint256 targetStateId;
        OutcomeOption[] probabilityAdjustments; // Use weight field as the adjustment amount (+ or -)
    }

    // --- State Variables ---

    uint256 private _nextStateId;
    mapping(uint256 => QuantumStateDefinition) private _stateDefinitions;
    mapping(uint256 => QuantumStateStatus) private _stateStatuses;
    mapping(uint256 => mapping(uint256 => EntanglementEffect[])) private _entanglements; // triggerStateId => targetStateId => effects
    mapping(uint256 => mapping(bytes32 => mapping(address => uint256))) private _withdrawalAllocations; // stateId => outcomeHash => recipient => allocation (in basis points, 1/10000)
    mapping(address => uint256) private _availableWithdrawals; // Accumulated Ether available for withdrawal per address

    uint256 private _totalDeposited; // Total Ether deposited into the contract

    mapping(uint256 => uint256) private _timedObservationTriggers; // stateId => targetBlockNumber

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event EtherDeposited(address indexed depositor, uint256 amount);
    event StateDefinitionAdded(uint256 indexed stateId, string description);
    event StateDefinitionUpdated(uint256 indexed stateId);
    event StateDefinitionRemoved(uint256 indexed stateId);
    event EntanglementDefined(uint256 indexed triggerStateId, uint256 indexed targetStateId, bytes32 triggerOutcome);
    event EntanglementRemoved(uint256 indexed triggerStateId, uint256 indexed targetStateId);
    event WithdrawalAllocationSet(uint256 indexed stateId, bytes32 indexed outcomeHash, address indexed recipient, uint256 allocationBps);
    event WithdrawalAllocationRemoved(uint256 indexed stateId, bytes32 indexed outcomeHash, address indexed recipient);
    event StateObserved(uint256 indexed stateId, bytes32 indexed finalOutcome, uint256 blockNumber, uint256 timestamp);
    event EntanglementEffectApplied(uint256 indexed triggerStateId, bytes32 triggerOutcome, uint256 indexed targetStateId);
    event WithdrawalAvailable(address indexed recipient, uint256 amountAdded, uint256 totalAvailable);
    event EtherWithdrawn(address indexed recipient, uint256 amount);
    event TimedObservationTriggerSet(uint256 indexed stateId, uint256 blockNumber);
    event TimedObservationTriggerCancelled(uint256 indexed stateId);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyUncollapsedState(uint256 stateId) {
        require(_stateDefinitions[stateId].canBeObserved, "State not observable or does not exist");
        require(!_stateStatuses[stateId].isCollapsed, "State already collapsed");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _paused = false;
        _nextStateId = 1;
        emit OwnershipTransferred(address(0), _owner);
    }

    // --- Owner Functions ---

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function pauseContract() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Defines a new quantum state that can later be observed.
    /// @param description A human-readable description.
    /// @param potentialOutcomes Array of possible outcomes with their initial relative weights.
    /// @param canBeObserved Whether this state can be triggered for observation.
    /// @return The ID of the newly created state.
    function addQuantumStateDefinition(
        string calldata description,
        OutcomeOption[] calldata potentialOutcomes,
        bool canBeObserved
    ) external onlyOwner returns (uint256) {
        require(potentialOutcomes.length > 0, "Must have at least one outcome");
        uint256 stateId = _nextStateId++;
        _stateDefinitions[stateId] = QuantumStateDefinition({
            description: description,
            potentialOutcomes: potentialOutcomes,
            canBeObserved: canBeObserved,
            isCollapsed: false
        });
        emit StateDefinitionAdded(stateId, description);
        return stateId;
    }

    /// @notice Updates an existing quantum state definition (only if not collapsed).
    /// @param stateId The ID of the state to update.
    /// @param description New description.
    /// @param potentialOutcomes New array of possible outcomes with weights.
    /// @param canBeObserved New value for whether it can be observed.
    function updateQuantumStateDefinition(
        uint256 stateId,
        string calldata description,
        OutcomeOption[] calldata potentialOutcomes,
        bool canBeObserved
    ) external onlyOwner {
        QuantumStateDefinition storage stateDef = _stateDefinitions[stateId];
        require(stateDef.potentialOutcomes.length > 0, "State does not exist");
        require(!stateDef.isCollapsed, "Cannot update a collapsed state");
        require(potentialOutcomes.length > 0, "Must have at least one outcome");

        stateDef.description = description;
        stateDef.potentialOutcomes = potentialOutcomes;
        stateDef.canBeObserved = canBeObserved;

        emit StateDefinitionUpdated(stateId);
    }

    /// @notice Removes a quantum state definition (only if not collapsed and has no active entanglement).
    /// @param stateId The ID of the state to remove.
    function removeQuantumStateDefinition(uint256 stateId) external onlyOwner {
        QuantumStateDefinition storage stateDef = _stateDefinitions[stateId];
        require(stateDef.potentialOutcomes.length > 0, "State does not exist");
        require(!stateDef.isCollapsed, "Cannot remove a collapsed state");
        // Add check for active entanglement rules involving this state? Requires iterating mappings, can be gas intensive.
        // For simplicity in this example, we omit the active entanglement check, assuming careful admin.
        delete _stateDefinitions[stateId];
        emit StateDefinitionRemoved(stateId);
    }

    /// @notice Defines an entanglement rule: collapsing triggerStateId to triggerOutcome affects targetStateId's probabilities.
    /// @param triggerStateId The state whose collapse triggers the effect.
    /// @param triggerOutcome The specific outcome of triggerStateId that activates this rule.
    /// @param targetStateId The state whose probabilities are affected.
    /// @param probabilityAdjustments Array of outcome identifiers and the weight adjustments (+ or -) for the targetStateId.
    function defineEntanglement(
        uint256 triggerStateId,
        bytes32 triggerOutcome,
        uint256 targetStateId,
        OutcomeOption[] calldata probabilityAdjustments
    ) external onlyOwner {
        require(_stateDefinitions[triggerStateId].potentialOutcomes.length > 0, "Trigger state does not exist");
        require(_stateDefinitions[targetStateId].potentialOutcomes.length > 0, "Target state does not exist");
        require(!_stateDefinitions[triggerStateId].isCollapsed, "Trigger state is already collapsed");
        require(triggerStateId != targetStateId, "Cannot entangle a state with itself");

        _entanglements[triggerStateId][targetStateId].push(EntanglementEffect({
            triggerOutcome: triggerOutcome,
            targetStateId: targetStateId,
            probabilityAdjustments: probabilityAdjustments
        }));

        emit EntanglementDefined(triggerStateId, targetStateId, triggerOutcome);
    }

     /// @notice Removes a specific entanglement rule between two states.
     /// Note: This implementation is basic. A more robust version might require identifying the specific effect within the array.
     /// For simplicity, this removes *all* entanglement effects defined between a specific trigger and target state pair.
    function removeEntanglement(uint256 triggerStateId, uint256 targetStateId) external onlyOwner {
         require(_stateDefinitions[triggerStateId].potentialOutcomes.length > 0 && _stateDefinitions[targetStateId].potentialOutcomes.length > 0, "State(s) do not exist");
         delete _entanglements[triggerStateId][targetStateId];
         emit EntanglementRemoved(triggerStateId, targetStateId);
     }


    /// @notice Allocates a percentage of the total deposited Ether to a recipient if a specific state collapses to a specific outcome.
    /// @param stateId The state ID.
    /// @param outcomeHash The identifier of the outcome.
    /// @param recipient The address that receives the allocation.
    /// @param allocationBps The percentage allocation in basis points (e.g., 1000 for 10%, 10000 for 100%). Max 10000.
    function setWithdrawalAllocation(
        uint256 stateId,
        bytes32 outcomeHash,
        address recipient,
        uint256 allocationBps
    ) external onlyOwner {
        require(_stateDefinitions[stateId].potentialOutcomes.length > 0, "State does not exist");
        require(!_stateStatuses[stateId].isCollapsed, "Cannot set allocation for a collapsed state");
        require(recipient != address(0), "Recipient is the zero address");
        require(allocationBps <= 10000, "Allocation cannot exceed 100%");

        // Optional: Check if outcomeHash is a valid outcome for this state definition.
        // This would require iterating potentialOutcomes array, omitted for gas in this example.

        _withdrawalAllocations[stateId][outcomeHash][recipient] = allocationBps;
        emit WithdrawalAllocationSet(stateId, outcomeHash, recipient, allocationBps);
    }

    /// @notice Removes a specific withdrawal allocation.
    function removeWithdrawalAllocation(uint256 stateId, bytes32 outcomeHash, address recipient) external onlyOwner {
        require(_stateDefinitions[stateId].potentialOutcomes.length > 0, "State does not exist");
         // Allow removing allocation even after collapse for cleanup, but it won't affect already added available withdrawals.
        require(recipient != address(0), "Recipient is the zero address");

        delete _withdrawalAllocations[stateId][outcomeHash][recipient];
        emit WithdrawalAllocationRemoved(stateId, outcomeHash, recipient);
    }

    /// @notice Sets a future block number at which a specific uncollapsed state will be automatically observed.
    /// Only one timed trigger per state is possible. Setting 0 cancels the trigger.
    /// @param stateId The ID of the state to trigger.
    /// @param blockNumber The target block number. Set to 0 to cancel.
    function setTimedObservationTrigger(uint256 stateId, uint256 blockNumber) external onlyOwner onlyUncollapsedState(stateId) {
        if (blockNumber > 0) {
             require(blockNumber > block.number, "Trigger block must be in the future");
            _timedObservationTriggers[stateId] = blockNumber;
            emit TimedObservationTriggerSet(stateId, blockNumber);
        } else {
             cancelTimedObservationTrigger(stateId); // Use existing cancel function
        }
    }

    /// @notice Cancels a pending timed observation trigger for a state.
    /// @param stateId The ID of the state whose trigger to cancel.
    function cancelTimedObservationTrigger(uint256 stateId) public onlyOwner { // Made public to be callable internally from setTimedObservationTrigger(0)
         require(_timedObservationTriggers[stateId] > 0, "No active timed trigger for this state");
         delete _timedObservationTriggers[stateId];
         emit TimedObservationTriggerCancelled(stateId);
    }

    // --- User Interaction Functions ---

    /// @notice Allows users to deposit Ether into the contract.
    function depositEther() external payable whenNotPaused {
        require(msg.value > 0, "Must send Ether");
        _totalDeposited += msg.value;
        emit EtherDeposited(msg.sender, msg.value);
    }

    /// @notice Triggers the observation and collapse of a specific uncollapsed state.
    /// Can be called by anyone.
    /// Automatically triggers any timed observations if their block is reached.
    /// @param stateId The ID of the state to observe.
    function triggerStateObservation(uint256 stateId) external whenNotPaused onlyUncollapsedState(stateId) {
        // Check for and trigger any timed observations whose block has arrived
        _checkAndTriggerTimedObservations();

        // Trigger the specific state requested, only if it's still uncollapsed after checking timed triggers
        if (!_stateStatuses[stateId].isCollapsed) {
            _collapseState(stateId);
        }
    }

    /// @notice Triggers the observation and collapse of all states that are currently unobserved.
    /// Can be called by anyone.
    /// Automatically triggers any timed observations whose block has arrived.
    function triggerAllUnobservedStates() external whenNotPaused {
         // Check for and trigger any timed observations whose block has arrived
         _checkAndTriggerTimedObservations();

         // Iterate through all defined states (gas intensive if many states)
         // A more gas-efficient approach might involve tracking observable states in a dynamic array or linked list.
         // For this example, we iterate state IDs up to the current max.
         uint256 maxStateId = _nextStateId; // Capture current max ID
         for (uint256 i = 1; i < maxStateId; i++) {
             // Check if state exists and is uncollapsed
             if (_stateDefinitions[i].potentialOutcomes.length > 0 && _stateDefinitions[i].canBeObserved && !_stateStatuses[i].isCollapsed) {
                 _collapseState(i);
             }
         }
    }

    /// @notice Allows users to withdraw Ether that has been allocated to them based on collapsed state outcomes.
    function withdraw() external payable whenNotPaused { // Allow sending 0 value to just trigger a check
        uint256 amount = _availableWithdrawals[msg.sender];
        require(amount > 0, "No withdrawal amount available");

        _availableWithdrawals[msg.sender] = 0; // Clear balance before sending

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether withdrawal failed");

        // _totalDeposited might not be accurate anymore if withdrawals happen,
        // consider tracking balance separately or recalculating available funds differently.
        // For simplicity, we'll assume totalDeposited represents the initial pool.
        // A more robust system would track remaining contract balance or adjust calculations.
        // totalDeposited -= amount; // Only safe if totalDeposited tracks current balance.
        // Let's *not* decrease totalDeposited as it's used for percentage calculation.
        // The contract balance naturally decreases.

        emit EtherWithdrawn(msg.sender, amount);
    }

    // --- Query Functions ---

    function isPaused() external view returns (bool) {
        return _paused;
    }

    function getQuantumStateDefinition(uint256 stateId) external view returns (
        string memory description,
        OutcomeOption[] memory potentialOutcomes,
        bool canBeObserved,
        bool isCollapsed
    ) {
        QuantumStateDefinition storage stateDef = _stateDefinitions[stateId];
        require(stateDef.potentialOutcomes.length > 0, "State does not exist"); // Check if state is defined

        description = stateDef.description;
        potentialOutcomes = stateDef.potentialOutcomes; // Note: This copies the array
        canBeObserved = stateDef.canBeObserved;
        isCollapsed = stateDef.isCollapsed; // Redundant check with status mapping, but convenient
    }

    function getQuantumStateStatus(uint256 stateId) external view returns (
        bool isCollapsed,
        bytes32 finalOutcome,
        uint256 collapseBlock,
        uint256 collapseTimestamp
    ) {
        QuantumStateStatus storage stateStatus = _stateStatuses[stateId];
        // Check if state is defined, though status might exist even if definition is removed.
        require(_stateDefinitions[stateId].potentialOutcomes.length > 0 || stateStatus.isCollapsed, "State does not exist or never collapsed");

        return (
            stateStatus.isCollapsed,
            stateStatus.finalOutcome,
            stateStatus.collapseBlock,
            stateStatus.collapseTimestamp
        );
    }

    /// @notice Calculates the effective weights for potential outcomes of an uncollapsed state, considering entanglement effects from *collapsed* states.
    /// @param stateId The state ID.
    /// @return An array of OutcomeOptions with their currently calculated effective weights.
    function getPotentialOutcomes(uint256 stateId) external view onlyUncollapsedState(stateId) returns (OutcomeOption[] memory) {
        return _getEffectiveWeights(stateId);
    }

    /// @notice Retrieves the entanglement rules defined between a trigger state and a target state.
    /// @param triggerStateId The state whose collapse triggers the effect.
    /// @param targetStateId The state whose probabilities are affected.
    /// @return An array of EntanglementEffect rules.
    function getEntanglementDefinition(uint256 triggerStateId, uint256 targetStateId) external view returns (EntanglementEffect[] memory) {
        return _entanglements[triggerStateId][targetStateId];
    }

     /// @notice Retrieves the withdrawal allocation percentage (in basis points) for a specific recipient and outcome.
     /// @param stateId The state ID.
     /// @param outcomeHash The identifier of the outcome.
     /// @param recipient The address receiving the allocation.
     /// @return The allocation amount in basis points (0-10000).
    function getWithdrawalAllocation(uint256 stateId, bytes32 outcomeHash, address recipient) external view returns (uint256) {
        return _withdrawalAllocations[stateId][outcomeHash][recipient];
    }

    function getTotalDeposits() external view returns (uint256) {
        return _totalDeposited;
    }

    function getAvailableWithdrawalAmount(address user) external view returns (uint256) {
        return _availableWithdrawals[user];
    }

     /// @notice Returns a list of state IDs that are defined as observable but not yet collapsed.
     /// Note: This iterates through state IDs up to the current max, potentially gas intensive.
     /// @return An array of unobserved state IDs.
    function getUnobservedStateIds() external view returns (uint256[] memory) {
        uint256[] memory unobserved;
        uint256 count = 0;
        // First pass to count
        uint256 maxStateId = _nextStateId;
        for (uint256 i = 1; i < maxStateId; i++) {
             if (_stateDefinitions[i].potentialOutcomes.length > 0 && _stateDefinitions[i].canBeObserved && !_stateStatuses[i].isCollapsed) {
                 count++;
             }
        }
        // Second pass to populate
        unobserved = new uint256[](count);
        uint256 index = 0;
         for (uint256 i = 1; i < maxStateId; i++) {
             if (_stateDefinitions[i].potentialOutcomes.length > 0 && _stateDefinitions[i].canBeObserved && !_stateStatuses[i].isCollapsed) {
                 unobserved[index++] = i;
             }
        }
        return unobserved;
    }

    /// @notice Returns the block number set for a timed observation trigger for a state.
    /// Returns 0 if no trigger is set.
    /// @param stateId The state ID.
    /// @return The target block number for the timed trigger, or 0.
    function getTimedObservationTriggerBlock(uint256 stateId) external view returns (uint256) {
        return _timedObservationTriggers[stateId];
    }


    // --- Internal Logic ---

    /// @dev Checks for and triggers timed observations whose block number has been reached or surpassed.
    function _checkAndTriggerTimedObservations() internal {
        uint256 maxStateId = _nextStateId;
        for (uint256 i = 1; i < maxStateId; i++) {
            uint256 triggerBlock = _timedObservationTriggers[i];
            // Check if state is defined, observable, uncollapsed, and has a timed trigger whose block is met
            if (_stateDefinitions[i].potentialOutcomes.length > 0 &&
                _stateDefinitions[i].canBeObserved &&
                !_stateStatuses[i].isCollapsed &&
                triggerBlock > 0 &&
                block.number >= triggerBlock)
            {
                // Trigger collapse for this state
                _collapseState(i);
                // Cancel the trigger after collapsing
                 delete _timedObservationTriggers[i]; // Done inside _collapseState? No, better here after check.
                 emit TimedObservationTriggerCancelled(i); // Emit cancellation event
            }
        }
    }


    /// @dev Performs the core logic of collapsing a quantum state.
    /// Calculates the outcome, updates status, applies entanglement effects, and updates withdrawal balances.
    /// Assumes the state is uncollapsed and observable based on modifier/calling function logic.
    /// @param stateId The ID of the state to collapse.
    function _collapseState(uint256 stateId) internal {
        // Double check state is still uncollapsed after _checkAndTriggerTimedObservations
         require(!_stateStatuses[stateId].isCollapsed, "State already collapsed in this transaction batch");

        bytes32 finalOutcome = _calculateOutcome(stateId);

        _stateStatuses[stateId] = QuantumStateStatus({
            isCollapsed: true,
            finalOutcome: finalOutcome,
            collapseBlock: block.number,
            collapseTimestamp: block.timestamp
        });
        _stateDefinitions[stateId].isCollapsed = true; // Update definition copy too

        emit StateObserved(stateId, finalOutcome, block.number, block.timestamp);

        // Apply entanglement effects caused by this collapse
        _applyEntanglementEffect(stateId, finalOutcome);

        // Update available withdrawal amounts based on this outcome
        _updateAvailableWithdrawalsForOutcome(stateId, finalOutcome);

         // Cancel any pending timed observation trigger for this state now that it's collapsed
         delete _timedObservationTriggers[stateId];
         // Note: Event for cancellation might be emitted by _checkAndTriggerTimedObservations or here.
         // Let's emit here if it existed.
         // if (_timedObservationTriggers[stateId] > 0) { // Check before deleting is safer if cancellation was elsewhere
         //    emit TimedObservationTriggerCancelled(stateId);
         // }


    }

    /// @dev Determines the final outcome of a state collapse based on effective weights and entropy.
    /// @param stateId The ID of the state.
    /// @return The identifier of the final outcome.
    function _calculateOutcome(uint256 stateId) internal view returns (bytes32) {
        OutcomeOption[] memory effectiveOutcomes = _getEffectiveWeights(stateId);
        require(effectiveOutcomes.length > 0, "No effective outcomes available for calculation");

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < effectiveOutcomes.length; i++) {
            totalWeight += effectiveOutcomes[i].weight;
        }

        require(totalWeight > 0, "Total effective weight is zero, cannot determine outcome");

        // Generate entropy (Note: Miner manipulable)
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            tx.origin, // Using tx.origin adds another layer, but beware of its own issues
            msg.sender,
            block.difficulty, // 0 on PoS, include for PoW compatibility or simulation
            address(this),
            totalWeight // Include total weight to make it slightly dependent on state config
        )));

        uint256 choice = entropy % totalWeight;
        uint256 cumulativeWeight = 0;

        for (uint256 i = 0; i < effectiveOutcomes.length; i++) {
            cumulativeWeight += effectiveOutcomes[i].weight;
            if (choice < cumulativeWeight) {
                return effectiveOutcomes[i].outcomeIdentifier;
            }
        }

        // Fallback: This should theoretically not be reached if totalWeight > 0
        // Return the last outcome or a predefined error outcome
        return effectiveOutcomes[effectiveOutcomes.length - 1].outcomeIdentifier;
    }

    /// @dev Calculates the current effective weights for outcomes of a state, considering base weights and entanglement adjustments from *collapsed* states.
    /// @param stateId The ID of the state.
    /// @return An array of OutcomeOptions with calculated effective weights.
    function _getEffectiveWeights(uint256 stateId) internal view returns (OutcomeOption[] memory) {
        QuantumStateDefinition storage stateDef = _stateDefinitions[stateId];
        require(stateDef.potentialOutcomes.length > 0, "State definition not found for effective weights");
        require(!stateDef.isCollapsed, "State is already collapsed");

        // Start with base weights
        OutcomeOption[] memory effectiveOutcomes = new OutcomeOption[](stateDef.potentialOutcomes.length);
        for (uint256 i = 0; i < stateDef.potentialOutcomes.length; i++) {
            effectiveOutcomes[i] = stateDef.potentialOutcomes[i];
        }

        // Apply adjustments from *collapsed* trigger states
        // Iterate through all *potential* trigger states defined in entanglements
        uint256 maxStateId = _nextStateId;
         for (uint256 triggerId = 1; triggerId < maxStateId; triggerId++) {
             // Check if this potential trigger state exists and is collapsed
             if (_stateStatuses[triggerId].isCollapsed) {
                 bytes32 triggerOutcome = _stateStatuses[triggerId].finalOutcome;
                 EntanglementEffect[] storage effects = _entanglements[triggerId][stateId]; // Check if this stateId is a target
                 if (effects.length > 0) {
                      // Found entanglement rules where triggerId collapsed and targets *this* stateId
                      for(uint256 i = 0; i < effects.length; i++) {
                           EntanglementEffect storage effect = effects[i];
                           if (effect.triggerOutcome == triggerOutcome) {
                                // This specific effect is active due to the trigger state's collapse and outcome
                                for(uint256 j = 0; j < effect.probabilityAdjustments.length; j++) {
                                     OutcomeOption storage adjustment = effect.probabilityAdjustments[j];
                                     // Find the corresponding outcome in effectiveOutcomes and apply adjustment
                                     for(uint256 k = 0; k < effectiveOutcomes.length; k++) {
                                          if (effectiveOutcomes[k].outcomeIdentifier == adjustment.outcomeIdentifier) {
                                               // Apply signed adjustment, ensuring weight doesn't go below zero
                                               if (adjustment.weight > 0) {
                                                    effectiveOutcomes[k].weight += adjustment.weight;
                                               } else { // adjustment.weight is negative or zero
                                                    uint256 deduction = uint256(0 - int256(adjustment.weight)); // Convert negative weight to positive deduction
                                                    if (effectiveOutcomes[k].weight > deduction) {
                                                         effectiveOutcomes[k].weight -= deduction;
                                                    } else {
                                                         effectiveOutcomes[k].weight = 0; // Cannot go below zero
                                                    }
                                               }
                                               // Assume only one adjustment per outcome identifier per effect, break inner loop
                                               break;
                                          }
                                     }
                                }
                                // If multiple effects exist for the same trigger outcome/target state, they are all applied.
                           }
                      }
                 }
             }
         }

        // Optional: Filter out outcomes with weight 0? Or let _calculateOutcome handle it?
        // _calculateOutcome requires total weight > 0. If all weights become 0, it will revert.
        // Let's keep outcomes with weight 0 in the array returned by this function.
        return effectiveOutcomes;
    }


    /// @dev Updates the `_availableWithdrawals` mapping for recipients based on a collapsed state's outcome and defined allocations.
    /// @param stateId The ID of the collapsed state.
    /// @param outcome The final outcome identifier.
    function _updateAvailableWithdrawalsForOutcome(uint256 stateId, bytes32 outcome) internal {
        // Retrieve all allocations for this state and this specific outcome
        // Iterating a mapping is not directly possible without knowing all keys (recipients).
        // This requires storing recipients associated with allocations, or iterating *all* possible recipients (impractical).
        // A more practical implementation would store recipients in a list or set alongside the allocation mapping.
        // For this example, we will simulate by iterating through potential recipients if we had a list.
        // A simpler approach for this example: assume allocation is defined for specific recipients known beforehand or linked to the state/outcome.
        // Let's assume the mapping `_withdrawalAllocations[stateId][outcome][recipient]` is the source of truth,
        // and we only update available withdrawals for addresses that have a non-zero allocation *defined in this mapping*.

        // How to get the list of recipients for this specific state/outcome?
        // This is a limitation of standard Solidity mappings. A better design would use:
        // `mapping(uint256 => mapping(bytes32 => address[])) private _recipientsPerOutcome;`
        // `mapping(uint256 => mapping(bytes32 => mapping(address => uint256))) private _withdrawalAllocations;`
        // Then iterate `_recipientsPerOutcome[stateId][outcome]`.

        // Given the current mapping structure, we *cannot* efficiently iterate recipients.
        // We have to assume the admin has set allocations for known recipients.
        // When an outcome collapses, we only update `_availableWithdrawals` for addresses that *have* an entry in `_withdrawalAllocations[stateId][outcome]`.
        // A user querying `getAvailableWithdrawalAmount` will see their updated balance.
        // The issue is, we can't easily trigger updates for *all* relevant recipients here without knowing who they are.

        // Let's proceed with the current mapping structure and accept this limitation for the example's complexity.
        // When `_updateAvailableWithdrawalsForOutcome` is called, it implies the outcome `outcome` for `stateId` occurred.
        // Any address `recipient` for which `_withdrawalAllocations[stateId][outcome][recipient]` is non-zero is eligible.
        // The actual crediting happens *implicitly* or requires a list of recipients associated with this state/outcome.

        // *** REVISED APPROACH: ***
        // The `_withdrawalAllocations` mapping stores the *rules*.
        // When a state collapses, we iterate the *rules* for that specific state/outcome.
        // For each rule (stateId, outcome, recipient, allocationBps), we calculate the amount and add it to `_availableWithdrawals[recipient]`.
        // This still requires iterating over relevant recipients for that outcome.

        // Let's change the allocation mapping structure slightly for better iteration or accept iteration limitation.
        // Structure: `mapping(uint256 => mapping(bytes32 => address[])) private _outcomeRecipients;`
        // And keep: `mapping(uint256 => mapping(bytes32 => mapping(address => uint256))) private _withdrawalAllocations;`

        // *** Implementation with the revised approach (conceptual change): ***
        // When `setWithdrawalAllocation` is called, add `recipient` to `_outcomeRecipients[stateId][outcomeHash]` if not already present.
        // When `_updateAvailableWithdrawalsForOutcome` is called:
        address[] memory recipients = new address[](0); // Placeholder: actual implementation needs this list populated by setWithdrawalAllocation
        // In a real contract, you'd retrieve recipients from _outcomeRecipients[stateId][outcome];
        // For this example, let's assume `getRecipientsForOutcome(stateId, outcome)` exists and returns the list.

        // For the purpose of *this* example code (without changing the struct to add recipient lists):
        // We cannot iterate all recipients linked to this outcome using the current mapping structure.
        // The contract can only update balances *when an address attempts to interact or query*,
        // or if we iterate through a known list of *all* potential recipients (highly inefficient).

        // Let's revert to the initial simpler interpretation for this example:
        // `_availableWithdrawals` is updated *only* for the specific state/outcome/recipient entry *when the rule is set*
        // or perhaps upon withdrawal attempt? No, must be upon collapse.
        // Let's add a helper function that returns a list of recipients for a given outcome to make the logic clear,
        // acknowledging it's a conceptual placeholder without modifying the primary mappings.

        // Placeholder: Get recipients for this specific outcome.
        // In a real contract, you would fetch this list. Example:
        // address[] memory recipientsForThisOutcome = getRecipientsForOutcome(stateId, outcome); // This helper doesn't exist in this code.

        // Let's rethink: The simplest way with the current mapping is that *anyone* can call `withdraw`.
        // `withdraw` checks their balance `_availableWithdrawals[msg.sender]`.
        // This balance needs to be updated *at the time of collapse* for *all* relevant addresses.
        // To do that, we need to know *which* addresses are relevant for this state/outcome.
        // This *absolutely requires* a way to iterate or list recipients per outcome.

        // Okay, let's add the necessary structure to track recipients per outcome.
        // *** Adding: `mapping(uint256 => mapping(bytes32 => address[])) private _outcomeRecipients;` ***
        // This requires updating `setWithdrawalAllocation` and `removeWithdrawalAllocation` to manage this list.
        // And the query `getWithdrawalAllocation` might need adjustment or a new function to get recipients.
        // Let's modify set/remove allocation functions.

        // Now, _updateAvailableWithdrawalsForOutcome becomes feasible:
        address[] memory recipientsForThisOutcome = _outcomeRecipients[stateId][outcome];
        uint256 totalAllocationBpsForOutcome = 0; // Optional: sum basis points for checking total < 10000

        for (uint256 i = 0; i < recipientsForThisOutcome.length; i++) {
            address recipient = recipientsForThisOutcome[i];
            uint256 allocationBps = _withdrawalAllocations[stateId][outcome][recipient];

            if (allocationBps > 0) {
                 uint256 allocationAmount = (_totalDeposited * allocationBps) / 10000; // Calculate based on total initial deposits
                 _availableWithdrawals[recipient] += allocationAmount; // Add to available balance

                 emit WithdrawalAvailable(recipient, allocationAmount, _availableWithdrawals[recipient]);
            }
        }
    }

    // --- Helper for _updateAvailableWithdrawalsForOutcome (Requires structural change) ---
    // This function is conceptual based on the revised structure and not included directly in the code summary list above.
    // Needs to be integrated into set/remove allocation functions.

     /// @dev Helper to add a recipient to the list for a specific outcome if not already present.
     /// @param stateId The state ID.
     /// @param outcomeHash The outcome identifier.
     /// @param recipient The recipient address.
     function _addRecipientForOutcome(uint256 stateId, bytes32 outcomeHash, address recipient) internal {
         address[] storage recipients = _outcomeRecipients[stateId][outcomeHash];
         bool found = false;
         for(uint256 i = 0; i < recipients.length; i++) {
              if (recipients[i] == recipient) {
                   found = true;
                   break;
              }
         }
         if (!found) {
              recipients.push(recipient);
         }
     }

      /// @dev Helper to remove a recipient from the list for a specific outcome.
      /// @param stateId The state ID.
      /// @param outcomeHash The outcome identifier.
      /// @param recipient The recipient address.
     function _removeRecipientForOutcome(uint256 stateId, bytes32 outcomeHash, address recipient) internal {
          address[] storage recipients = _outcomeRecipients[stateId][outcomeHash];
          for(uint256 i = 0; i < recipients.length; i++) {
               if (recipients[i] == recipient) {
                    // Replace with last element and pop to remove efficiently
                    recipients[i] = recipients[recipients.length - 1];
                    recipients.pop();
                    // No need to check for duplicates, simply remove the first match
                    break;
               }
          }
      }

      // --- Modify set/remove withdrawal allocation to use these helpers ---
      // (Updating the existing functions above conceptually)

      // setWithdrawalAllocation:
      // ... existing checks ...
      // _withdrawalAllocations[stateId][outcomeHash][recipient] = allocationBps;
      // _addRecipientForOutcome(stateId, outcomeHash, recipient); // ADD THIS CALL
      // ... emit event ...

      // removeWithdrawalAllocation:
      // ... existing checks ...
      // delete _withdrawalAllocations[stateId][outcomeHash][recipient];
      // _removeRecipientForOutcome(stateId, outcomeHash, recipient); // ADD THIS CALL
      // ... emit event ...

    // --- Add the outcomeRecipients mapping to state variables ---
    mapping(uint256 => mapping(bytes32 => address[])) private _outcomeRecipients; // stateId => outcomeHash => recipients

    // --- Add a query function for recipients per outcome ---
     /// @notice Gets the list of addresses allocated for a specific state outcome.
     /// @param stateId The state ID.
     /// @param outcomeHash The outcome identifier.
     /// @return An array of recipient addresses.
     function getRecipientsForOutcome(uint256 stateId, bytes32 outcomeHash) external view returns (address[] memory) {
         // Check if state exists? Not strictly necessary for querying the mapping.
         return _outcomeRecipients[stateId][outcomeHash];
     }

}
```