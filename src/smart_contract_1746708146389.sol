Okay, here is a Solidity smart contract designed around the concept of managing and interacting with a *simulated* quantum state, and orchestrating interaction with off-chain "quantum processors". It incorporates concepts like state representation (via probability distribution), simplified gate applications (that can be modeled via permutations on probabilities), measurement-induced collapse, access control, and an external job submission/result pattern.

This contract is *not* a real quantum computer simulator (Solidity isn't suited for complex linear algebra or complex numbers needed for that), but rather a creative use of Solidity to manage state and workflow *inspired by* quantum computing principles, and to interact with off-chain services. It aims to be unique by combining these specific simulated mechanics with a decentralized job delegation pattern.

**Outline and Function Summary**

This contract, `QuantumStateProxy`, acts as a central manager for a simulated multi-qubit quantum state and facilitates interactions with external processing services.

**State Variables:**

*   `_owner`: Address of the contract owner.
*   `_isInitialized`: Flag to prevent re-initialization.
*   `_numQubits`: The number of qubits in the simulated system.
*   `_scaleFactor`: A large number used to represent probabilities as integers (e.g., 10^18).
*   `_stateProbabilities`: An array of `uint256` representing the scaled probabilities of each of the `2^_numQubits` classical outcomes. Sum of elements equals `_scaleFactor`.
*   `_isCollapsed`: Boolean indicating if the state has been measured and collapsed.
*   `_lastMeasurementResult`: The classical outcome index (0 to 2^_numQubits - 1) of the last `measureAll` operation.
*   `_gateOperators`: Mapping to track addresses allowed to apply gates.
*   `_measurers`: Mapping to track addresses allowed to perform measurements.
*   `_jobCounter`: Counter for unique quantum jobs submitted.
*   `_jobs`: Mapping from job ID to `Job` struct.
*   `_allowedJobSubmitters`: Mapping to track addresses allowed to submit jobs.
*   `_maxQubitsSupported`: Maximum number of qubits this contract can manage (due to state array size limitations).

**Structs:**

*   `Job`: Represents an off-chain quantum computation request.
    *   `submitter`: Address that submitted the job.
    *   `data`: Raw bytes representing the job details (e.g., circuit description).
    *   `results`: Array of `uint256` representing computation results.
    *   `status`: Enum indicating the job's lifecycle stage.

**Enums:**

*   `JobStatus`: `Submitted`, `Processing`, `Completed`, `Cancelled`.

**Events:**

*   `StateInitialized(uint8 numQubits, uint256 scaleFactor)`: Logged on successful initialization.
*   `StateReset()`: Logged when the state is reset.
*   `GateApplied(string gateName, uint8[] qubitIndices, address operator)`: Logged when a gate is applied.
*   `Measured(uint256 outcomeIndex, address measurer)`: Logged when `measureAll` is performed.
*   `JobSubmitted(uint256 jobId, address submitter)`: Logged when a new job is submitted.
*   `ResultSubmitted(uint256 jobId, address processor)`: Logged when results for a job are submitted.
*   `JobCancelled(uint256 jobId, address initiator)`: Logged when a job is cancelled.
*   `OwnershipTransferred(address indexed previousOwner, address indexed newOwner)`: Logged on owner change.
*   `GateOperatorAdded(address indexed operator)`: Logged when an operator is added.
*   `GateOperatorRemoved(address indexed operator)`: Logged when an operator is removed.
*   `MeasurerAdded(address indexed measurer)`: Logged when a measurer is added.
*   `MeasurerRemoved(address indexed measurer)`: Logged when a measurer is removed.
*   `JobSubmitterAllowed(address indexed submitter)`: Logged when a submitter is allowed.
*   `JobSubmitterDisallowed(address indexed submitter)`: Logged when a submitter is disallowed.
*   `MaxQubitsSupportedSet(uint8 maxQubits)`: Logged when the max qubits limit is set.

**Function Summary (29 Functions):**

1.  `initialize(uint8 numQubits, uint256 scaleFactor)`: Sets up the initial quantum state (|00...0>), number of qubits, and probability scaling factor. Can only be called once.
2.  `resetState()`: Resets the simulated quantum state back to the initial |00...0> classical state.
3.  `getCurrentStateProbabilities()`: Returns the current scaled probability distribution over the 2^N classical outcomes.
4.  `getProbabilityForOutcome(uint256 outcomeIndex)`: Returns the scaled probability for a specific classical outcome index.
5.  `getMarginalQubitProbability(uint8 qubitIndex, bool outcome)`: Calculates and returns the marginal scaled probability of a single qubit being in state 0 or 1.
6.  `applyPauliX(uint8 qubitIndex)`: Applies a simulated Pauli-X (NOT) gate to a specified qubit by permuting probabilities. Requires `onlyGateOperator`.
7.  `applyCNOT(uint8 controlQubit, uint8 targetQubit)`: Applies a simulated Controlled-NOT gate to the state by permuting probabilities. Requires `onlyGateOperator`.
8.  `applySWAP(uint8 qubit1, uint8 qubit2)`: Applies a simulated SWAP gate between two qubits by permuting probabilities. Requires `onlyGateOperator`.
9.  `applyHadamardInitialState(uint8 qubitIndex)`: Applies a simulated Hadamard gate to a specified qubit, *only if the system is in a classical basis state*. This simplified model transitions a single qubit from |0> or |1> to a [0.5, 0.5] probability state without tracking phase. Requires `onlyGateOperator`.
10. `measureAll()`: Simulates measuring all qubits simultaneously. This collapses the state probabilistically to one classical outcome based on current probabilities. Requires `onlyMeasurer`. Uses basic block hash/timestamp for pseudorandomness.
11. `getLastMeasurementResult()`: Returns the index of the classical outcome from the most recent `measureAll`.
12. `isStateCollapsed()`: Returns true if the state has been collapsed by `measureAll`, false otherwise (unless reset).
13. `addGateOperator(address operator)`: Grants permission to an address to apply gates. Requires `onlyOwner`.
14. `removeGateOperator(address operator)`: Revokes gate application permission from an address. Requires `onlyOwner`.
15. `isGateOperator(address operator)`: Checks if an address has gate operator permissions.
16. `addMeasurer(address measurer)`: Grants permission to an address to perform measurements. Requires `onlyOwner`.
17. `removeMeasurer(address measurer)`: Revokes measurement permission from an address. Requires `onlyOwner`.
18. `isMeasurer(address measurer)`: Checks if an address has measurer permissions.
19. `submitQuantumJob(bytes memory jobData)`: Submits a request for an off-chain quantum computation. Stores job data and assigns a unique ID. Requires `onlyAllowedSubmitter`.
20. `submitQuantumResult(uint256 jobId, uint256[] memory results)`: Allows an external processor to submit results for a previously submitted job. Requires the caller to be an allowed job submitter (in this simplified model, the submitter is also the one who can provide results, or this could be extended).
21. `getJobData(uint256 jobId)`: Retrieves the data associated with a specific job ID.
22. `getJobResult(uint256 jobId)`: Retrieves the results submitted for a specific job ID.
23. `getJobStatus(uint256 jobId)`: Retrieves the current status of a job.
24. `getJobCount()`: Returns the total number of jobs submitted.
25. `cancelJob(uint256 jobId)`: Allows the job submitter or owner to cancel a job before it's completed.
26. `allowJobSubmitter(address submitter)`: Grants permission to an address to submit quantum jobs. Requires `onlyOwner`.
27. `disallowJobSubmitter(address submitter)`: Revokes job submission permission. Requires `onlyOwner`.
28. `isJobSubmitterAllowed(address submitter)`: Checks if an address is allowed to submit jobs.
29. `setMaxQubits(uint8 maxQubits)`: Sets the maximum number of qubits allowed during initialization. Requires `onlyOwner`. Can only be set once.
30. `getMaxQubits()`: Returns the configured maximum number of qubits.
31. `setOwner(address newOwner)`: Transfers contract ownership. Requires `onlyOwner`.
32. `getOwner()`: Returns the current owner address.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// QuantumStateProxy Contract

// Outline:
// 1. State Variables for quantum state simulation, access control, and job management.
// 2. Structs & Enums for jobs.
// 3. Events for logging state changes, operations, and job lifecycle.
// 4. Modifiers for access control (ownership, roles).
// 5. Initialization function.
// 6. Core Quantum State Management: Reset, Query State/Probabilities.
// 7. Simulated Gate Operations: Pauli-X, CNOT, SWAP, specialized Hadamard.
// 8. Simulated Measurement & State Collapse.
// 9. Access Control Management: Owner, Gate Operators, Measurers.
// 10. Off-chain Job Management: Submit, Result, Query, Cancel, Submitters.
// 11. Configuration: Max Qubits.
// 12. Ownership Management.
// 13. Utility functions (Getters).

// Function Summary (29 Functions):
// 1. initialize(uint8 numQubits, uint256 scaleFactor)
// 2. resetState()
// 3. getCurrentStateProbabilities()
// 4. getProbabilityForOutcome(uint256 outcomeIndex)
// 5. getMarginalQubitProbability(uint8 qubitIndex, bool outcome)
// 6. applyPauliX(uint8 qubitIndex)
// 7. applyCNOT(uint8 controlQubit, uint8 targetQubit)
// 8. applySWAP(uint8 qubit1, uint8 qubit2)
// 9. applyHadamardInitialState(uint8 qubitIndex)
// 10. measureAll()
// 11. getLastMeasurementResult()
// 12. isStateCollapsed()
// 13. addGateOperator(address operator)
// 14. removeGateOperator(address operator)
// 15. isGateOperator(address operator)
// 16. addMeasurer(address measurer)
// 17. removeMeasurer(address measurer)
// 18. isMeasurer(address measurer)
// 19. submitQuantumJob(bytes memory jobData)
// 20. submitQuantumResult(uint256 jobId, uint256[] memory results)
// 21. getJobData(uint256 jobId)
// 22. getJobResult(uint256 jobId)
// 23. getJobStatus(uint256 jobId)
// 24. getJobCount()
// 25. cancelJob(uint256 jobId)
// 26. allowJobSubmitter(address submitter)
// 27. disallowJobSubmitter(address submitter)
// 28. isJobSubmitterAllowed(address submitter)
// 29. setMaxQubits(uint8 maxQubits)
// 30. getMaxQubits()
// 31. setOwner(address newOwner)
// 32. getOwner()


contract QuantumStateProxy {

    address private _owner;
    bool private _isInitialized;

    uint8 private _numQubits;
    uint256 private _scaleFactor; // Represents probabilities as integers (e.g., 10^18)
    uint256[] private _stateProbabilities; // Array of size 2^_numQubits

    bool private _isCollapsed;
    uint256 private _lastMeasurementResult;

    mapping(address => bool) private _gateOperators;
    mapping(address => bool) private _measurers;
    mapping(address => bool) private _allowedJobSubmitters;

    uint256 private _jobCounter;

    enum JobStatus { Submitted, Processing, Completed, Cancelled }

    struct Job {
        address submitter;
        bytes data;
        uint256[] results;
        JobStatus status;
    }

    mapping(uint256 => Job) private _jobs;

    // Limitation: Array size grows as 2^N. Max practical N on chain is small (maybe 8-10).
    // Setting a hard cap prevents deployment with unrealistic N.
    uint8 private constant DEFAULT_MAX_QUBITS = 3; // Default reasonable max
    uint8 private _maxQubitsSupported = DEFAULT_MAX_QUBITS;
    bool private _maxQubitsSet;


    event StateInitialized(uint8 numQubits, uint256 scaleFactor);
    event StateReset();
    event GateApplied(string gateName, uint8[] qubitIndices, address operator);
    event Measured(uint256 outcomeIndex, address measurer);
    event JobSubmitted(uint256 jobId, address submitter);
    event ResultSubmitted(uint256 jobId, address processor);
    event JobCancelled(uint256 jobId, address initiator);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GateOperatorAdded(address indexed operator);
    event GateOperatorRemoved(address indexed operator);
    event MeasurerAdded(address indexed measurer);
    event MeasurerRemoved(address indexed measurer);
    event JobSubmitterAllowed(address indexed submitter);
    event JobSubmitterDisallowed(address indexed submitter);
    event MaxQubitsSupportedSet(uint8 maxQubits);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "QSP: Not owner");
        _;
    }

    modifier onlyGateOperator() {
        require(_gateOperators[msg.sender] || msg.sender == _owner, "QSP: Not gate operator");
        require(!_isCollapsed, "QSP: State collapsed");
        _;
    }

    modifier onlyMeasurer() {
        require(_measurers[msg.sender] || msg.sender == _owner, "QSP: Not measurer");
        require(!_isCollapsed, "QSP: State already collapsed");
        _;
    }

     modifier onlyAllowedSubmitter() {
        require(_allowedJobSubmitters[msg.sender] || msg.sender == _owner, "QSP: Not allowed submitter");
        _;
    }

    // --- Constructor & Initialization ---

    constructor() {
        _owner = msg.sender;
        // Max qubits can be set once after deployment by owner, default is 3.
    }

    /// @notice Initializes the quantum state proxy. Sets number of qubits and probability scaling factor.
    /// @param numQubits_ The number of qubits in the simulated system (max limited by _maxQubitsSupported).
    /// @param scaleFactor_ The total sum for probability representation (e.g., 1e18).
    function initialize(uint8 numQubits_, uint256 scaleFactor_) public onlyOwner {
        require(!_isInitialized, "QSP: Already initialized");
        require(numQubits_ > 0 && numQubits_ <= _maxQubitsSupported, "QSP: Invalid number of qubits");
        require(scaleFactor_ > 0, "QSP: Invalid scale factor");

        _numQubits = numQubits_;
        _scaleFactor = scaleFactor_;

        uint256 stateSize = 1 << _numQubits;
        _stateProbabilities = new uint256[](stateSize);

        // Initial state is |00...0>, so only the first probability is 1 (scaled)
        _stateProbabilities[0] = _scaleFactor;
        for (uint256 i = 1; i < stateSize; i++) {
            _stateProbabilities[i] = 0;
        }

        _isCollapsed = false;
        _lastMeasurementResult = type(uint256).max; // Indicates no measurement yet

        _isInitialized = true;
        emit StateInitialized(_numQubits, _scaleFactor);
    }

    // --- Quantum State Management ---

    /// @notice Resets the quantum state to the initial |00...0> classical state.
    function resetState() public onlyGateOperator { // Allow operators to reset
        require(_isInitialized, "QSP: Not initialized");

        uint256 stateSize = 1 << _numQubits;
        for (uint256 i = 0; i < stateSize; i++) {
            _stateProbabilities[i] = 0;
        }
        _stateProbabilities[0] = _scaleFactor;

        _isCollapsed = false;
        _lastMeasurementResult = type(uint256).max;

        emit StateReset();
    }

    /// @notice Gets the current scaled probability distribution over all classical outcomes.
    /// @return An array of scaled probabilities.
    function getCurrentStateProbabilities() public view returns (uint256[] memory) {
        require(_isInitialized, "QSP: Not initialized");
        return _stateProbabilities;
    }

    /// @notice Gets the scaled probability for a specific classical outcome index.
    /// @param outcomeIndex The index of the classical outcome (0 to 2^N - 1).
    /// @return The scaled probability for the given outcome.
    function getProbabilityForOutcome(uint256 outcomeIndex) public view returns (uint256) {
        require(_isInitialized, "QSP: Not initialized");
        require(outcomeIndex < (1 << _numQubits), "QSP: Invalid outcome index");
        return _stateProbabilities[outcomeIndex];
    }

    /// @notice Calculates the marginal scaled probability for a single qubit being in a specific state (0 or 1).
    /// @param qubitIndex The index of the qubit (0 to N-1).
    /// @param outcome The desired outcome for the qubit (false for 0, true for 1).
    /// @return The marginal scaled probability for the qubit.
    function getMarginalQubitProbability(uint8 qubitIndex, bool outcome) public view returns (uint256) {
        require(_isInitialized, "QSP: Not initialized");
        require(qubitIndex < _numQubits, "QSP: Invalid qubit index");

        uint256 totalProb = 0;
        uint256 stateSize = 1 << _numQubits;
        uint256 mask = 1 << qubitIndex;

        for (uint256 i = 0; i < stateSize; i++) {
            // Check the bit corresponding to the qubitIndex in the outcome index `i`
            bool bitValue = (i & mask) != 0;
            if (bitValue == outcome) {
                totalProb += _stateProbabilities[i];
            }
        }
        return totalProb;
    }

    // --- Simulated Gate Operations ---
    // Note: These simulate effects on probability distribution. Full quantum state simulation
    // requires complex numbers and is infeasible on-chain.

    /// @notice Applies a simulated Pauli-X (NOT) gate to a specified qubit.
    /// This permutes probabilities based on the qubit index.
    /// @param qubitIndex The index of the qubit to apply the gate to.
    function applyPauliX(uint8 qubitIndex) public onlyGateOperator {
        require(qubitIndex < _numQubits, "QSP: Invalid qubit index");

        uint256 stateSize = 1 << _numQubits;
        uint256 mask = 1 << qubitIndex;
        uint256[] memory newProbs = new uint256[](stateSize);

        for (uint256 i = 0; i < stateSize; i++) {
            // Find the index `j` which is `i` with the `qubitIndex` bit flipped
            uint256 j = i ^ mask;
            newProbs[j] = _stateProbabilities[i];
        }
        _stateProbabilities = newProbs; // Replace old probabilities with new

        emit GateApplied("PauliX", new uint8[](1), msg.sender); // Simplified event data
    }

    /// @notice Applies a simulated Controlled-NOT (CNOT) gate.
    /// If controlQubit is 1, applies X to targetQubit. Permutes probabilities.
    /// @param controlQubit The index of the control qubit.
    /// @param targetQubit The index of the target qubit.
    function applyCNOT(uint8 controlQubit, uint8 targetQubit) public onlyGateOperator {
        require(controlQubit < _numQubits && targetQubit < _numQubits && controlQubit != targetQubit, "QSP: Invalid qubit indices");

        uint256 stateSize = 1 << _numQubits;
        uint256 controlMask = 1 << controlQubit;
        uint256 targetMask = 1 << targetQubit;
        uint256[] memory newProbs = new uint256[](stateSize);

        for (uint256 i = 0; i < stateSize; i++) {
            // If the control bit is 1 in index `i`
            if ((i & controlMask) != 0) {
                // Flip the target bit to get index `j`
                uint256 j = i ^ targetMask;
                 newProbs[j] = _stateProbabilities[i];
            } else {
                // If control bit is 0, state is unchanged
                 newProbs[i] = _stateProbabilities[i];
            }
        }
         _stateProbabilities = newProbs; // Replace old probabilities with new

        emit GateApplied("CNOT", new uint8[](2), msg.sender); // Simplified event data
    }

     /// @notice Applies a simulated SWAP gate between two qubits.
     /// Permutes probabilities.
     /// @param qubit1 The index of the first qubit.
     /// @param qubit2 The index of the second qubit.
    function applySWAP(uint8 qubit1, uint8 qubit2) public onlyGateOperator {
        require(qubit1 < _numQubits && qubit2 < _numQubits && qubit1 != qubit2, "QSP: Invalid qubit indices");

        // SWAP(q1, q2) is equivalent to CNOT(q1, q2) then CNOT(q2, q1) then CNOT(q1, q2)
        // We can implement the direct permutation: swap probabilities for states that differ only in q1 and q2 bits.
        uint256 stateSize = 1 << _numQubits;
        uint256 mask1 = 1 << qubit1;
        uint256 mask2 = 1 << qubit2;
        uint256[] memory newProbs = new uint256[](stateSize);

         for (uint256 i = 0; i < stateSize; i++) {
            // Check if the state `i` has different bits at qubit1 and qubit2 positions
            if (((i & mask1) != 0) != ((i & mask2) != 0)) {
                 // Find the index `j` by flipping both bits
                 uint256 j = i ^ mask1 ^ mask2;
                 // We only process each pair (i, j) once. Check if i < j.
                 if (i < j) {
                    newProbs[i] = _stateProbabilities[j];
                    newProbs[j] = _stateProbabilities[i];
                 } else if (i > j) {
                     // Pair was already handled when we processed j
                 } else { // i == j, should not happen if bits are different
                     newProbs[i] = _stateProbabilities[i];
                 }
            } else {
                // If bits are the same, state is unchanged by SWAP
                newProbs[i] = _stateProbabilities[i];
            }
        }
        _stateProbabilities = newProbs; // Replace old probabilities with new

        emit GateApplied("SWAP", new uint8[](2), msg.sender); // Simplified event data
    }

    /// @notice Applies a simulated Hadamard gate to a qubit, but ONLY if the *entire system*
    /// is in a classical basis state (|00..0> or a permutation like |10..0>, |01..0>, etc.).
    /// This simplifies the effect to moving from a definite state to a superposition
    /// represented by 0.5/0.5 probability for the affected qubit's outcomes.
    /// DOES NOT correctly handle superpositions or relative phases.
    /// @param qubitIndex The index of the qubit to apply H to.
    function applyHadamardInitialState(uint8 qubitIndex) public onlyGateOperator {
         require(qubitIndex < _numQubits, "QSP: Invalid qubit index");

         uint256 stateSize = 1 << _numQubits;
         uint256 classicalStateIndex = type(uint256).max; // Index of the single non-zero probability state

         // Check if the state is a classical basis state (only one non-zero probability)
         uint256 nonZeroCount = 0;
         for(uint256 i=0; i < stateSize; i++){
             if(_stateProbabilities[i] > 0){
                 nonZeroCount++;
                 classicalStateIndex = i;
             }
         }
         require(nonZeroCount == 1 && classicalStateIndex != type(uint256).max, "QSP: Hadamard (simplified) only works on classical basis states");
         require(_stateProbabilities[classicalStateIndex] == _scaleFactor, "QSP: Classical state probability must be scale factor");


         uint256 mask = 1 << qubitIndex;
         // Check the state of the target qubit in the classical state
         bool qubitInitialState = (classicalStateIndex & mask) != 0;

         // After H on classical state |0> or |1>, the new state is a superposition.
         // In our probability model, this means probabilities are now split 50/50
         // between the two states that differ ONLY at qubitIndex.
         // E.g., |00> --H on q1--> (|00> + |01>)/sqrt(2) -> Probabilities [0.5, 0.5, 0, 0] scaled.
         // E.g., |10> --H on q1--> (|10> + |11>)/sqrt(2) -> Probabilities [0, 0, 0.5, 0.5] scaled.

         uint256 index1 = classicalStateIndex & ~mask; // State with qubitIndex = 0
         uint256 index2 = classicalStateIndex | mask; // State with qubitIndex = 1

         for(uint256 i=0; i < stateSize; i++){
             _stateProbabilities[i] = 0;
         }
         _stateProbabilities[index1] = _scaleFactor / 2;
         _stateProbabilities[index2] = _scaleFactor / 2;


         emit GateApplied("HadamardInitialState", new uint8[](1), msg.sender); // Simplified event data
    }


    // --- Simulated Measurement ---

    /// @notice Simulates measuring all qubits. Collapses the state probabilistically
    /// to one classical outcome based on the current probability distribution.
    /// Uses basic on-chain entropy sources for simulation.
    function measureAll() public onlyMeasurer {
        require(_isInitialized, "QSP: Not initialized");

        uint256 stateSize = 1 << _numQubits;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tx.origin))) % _scaleFactor;

        uint256 cumulativeProb = 0;
        uint256 outcome = 0;

        for (uint256 i = 0; i < stateSize; i++) {
            cumulativeProb += _stateProbabilities[i];
            if (randomNumber < cumulativeProb) {
                outcome = i;
                break;
            }
        }

        // Collapse the state: set probability of the chosen outcome to 1 (scaled)
        // and all others to 0.
        for (uint256 i = 0; i < stateSize; i++) {
            _stateProbabilities[i] = 0;
        }
        _stateProbabilities[outcome] = _scaleFactor;

        _isCollapsed = true;
        _lastMeasurementResult = outcome;

        emit Measured(outcome, msg.sender);
    }

    /// @notice Gets the result of the last `measureAll` operation.
    /// Returns type(uint256).max if no measurement has occurred.
    function getLastMeasurementResult() public view returns (uint256) {
        require(_isInitialized, "QSP: Not initialized");
        return _lastMeasurementResult;
    }

    /// @notice Checks if the simulated quantum state has been collapsed by measurement.
    function isStateCollapsed() public view returns (bool) {
         require(_isInitialized, "QSP: Not initialized");
         return _isCollapsed;
    }


    // --- Access Control Management (Roles) ---

    /// @notice Grants gate operator permissions to an address.
    /// @param operator The address to grant permission to.
    function addGateOperator(address operator) public onlyOwner {
        require(operator != address(0), "QSP: Zero address");
        _gateOperators[operator] = true;
        emit GateOperatorAdded(operator);
    }

    /// @notice Revokes gate operator permissions from an address.
    /// @param operator The address to revoke permission from.
    function removeGateOperator(address operator) public onlyOwner {
        require(operator != address(0), "QSP: Zero address");
        _gateOperators[operator] = false;
        emit GateOperatorRemoved(operator);
    }

     /// @notice Checks if an address has gate operator permissions.
     /// @param operator The address to check.
     /// @return True if the address is a gate operator, false otherwise.
    function isGateOperator(address operator) public view returns (bool) {
        return _gateOperators[operator];
    }

    /// @notice Grants measurer permissions to an address.
    /// @param measurer The address to grant permission to.
    function addMeasurer(address measurer) public onlyOwner {
        require(measurer != address(0), "QSP: Zero address");
        _measurers[measurer] = true;
        emit MeasurerAdded(measurer);
    }

    /// @notice Revokes measurer permissions from an address.
    /// @param measurer The address to revoke permission from.
    function removeMeasurer(address measurer) public onlyOwner {
        require(measurer != address(0), "QSP: Zero address");
        _measurers[measurer] = false;
        emit MeasurerRemoved(measurer);
    }

    /// @notice Checks if an address has measurer permissions.
    /// @param measurer The address to check.
    /// @return True if the address is a measurer, false otherwise.
    function isMeasurer(address measurer) public view returns (bool) {
        return _measurers[measurer];
    }


    // --- Off-chain Quantum Job Management ---

    /// @notice Submits a description of a quantum computation job to be processed off-chain.
    /// @param jobData Raw bytes describing the job (e.g., OpenQASM, QIR, etc.).
    /// @return The unique ID assigned to the submitted job.
    function submitQuantumJob(bytes memory jobData) public onlyAllowedSubmitter returns (uint256) {
        require(jobData.length > 0, "QSP: Job data cannot be empty");

        uint256 jobId = _jobCounter++;
        _jobs[jobId] = Job({
            submitter: msg.sender,
            data: jobData,
            results: new uint256[](0), // Empty results initially
            status: JobStatus.Submitted
        });

        emit JobSubmitted(jobId, msg.sender);
        return jobId;
    }

    /// @notice Allows an authorized entity (in this simplified model, the submitter)
    /// to submit the results for a previously submitted quantum job.
    /// @param jobId The ID of the job.
    /// @param results An array of uint256 representing the results (e.g., measurement outcomes).
    function submitQuantumResult(uint256 jobId, uint256[] memory results) public onlyAllowedSubmitter {
        Job storage job = _jobs[jobId];
        require(job.submitter != address(0), "QSP: Job not found");
        require(job.status == JobStatus.Submitted || job.status == JobStatus.Processing, "QSP: Job not in eligible status for results");
        // require(msg.sender == job.submitter || <authorized processor>, "QSP: Not authorized to submit results"); // Could add processor role

        job.results = results;
        job.status = JobStatus.Completed; // Simplified: results submission marks completed

        // Optional: Process results here or have another function triggered
        // based on job results, potentially updating the on-chain state.
        // (Too complex to add 20+ *more* functions for result processing)

        emit ResultSubmitted(jobId, msg.sender); // Assuming submitter is processor for simplicity
    }

    /// @notice Retrieves the raw data associated with a quantum job.
    /// @param jobId The ID of the job.
    /// @return The raw job data bytes.
    function getJobData(uint256 jobId) public view returns (bytes memory) {
         require(_jobs[jobId].submitter != address(0), "QSP: Job not found");
         return _jobs[jobId].data;
    }

    /// @notice Retrieves the results submitted for a quantum job.
    /// @param jobId The ID of the job.
    /// @return An array of uint256 results. Returns empty array if no results submitted.
    function getJobResult(uint256 jobId) public view returns (uint256[] memory) {
        require(_jobs[jobId].submitter != address(0), "QSP: Job not found");
        return _jobs[jobId].results;
    }

    /// @notice Retrieves the current status of a quantum job.
    /// @param jobId The ID of the job.
    /// @return The status enum value.
    function getJobStatus(uint256 jobId) public view returns (JobStatus) {
        require(_jobs[jobId].submitter != address(0), "QSP: Job not found");
        return _jobs[jobId].status;
    }

    /// @notice Gets the total number of quantum jobs submitted.
    /// @return The total count of jobs.
    function getJobCount() public view returns (uint256) {
        return _jobCounter;
    }

    /// @notice Allows the job submitter or the contract owner to cancel a job
    /// that has not yet been completed.
    /// @param jobId The ID of the job to cancel.
    function cancelJob(uint256 jobId) public {
        Job storage job = _jobs[jobId];
        require(job.submitter != address(0), "QSP: Job not found");
        require(msg.sender == job.submitter || msg.sender == _owner, "QSP: Not authorized to cancel");
        require(job.status != JobStatus.Completed && job.status != JobStatus.Cancelled, "QSP: Job not in eligible status for cancellation");

        job.status = JobStatus.Cancelled;
        emit JobCancelled(jobId, msg.sender);
    }

    /// @notice Grants permission to an address to submit quantum jobs.
    /// @param submitter The address to grant permission to.
    function allowJobSubmitter(address submitter) public onlyOwner {
        require(submitter != address(0), "QSP: Zero address");
        _allowedJobSubmitters[submitter] = true;
        emit JobSubmitterAllowed(submitter);
    }

    /// @notice Revokes job submission permission from an address.
    /// @param submitter The address to revoke permission from.
    function disallowJobSubmitter(address submitter) public onlyOwner {
        require(submitter != address(0), "QSP: Zero address");
        _allowedJobSubmitters[submitter] = false;
        emit JobSubmitterDisallowed(submitter);
    }

     /// @notice Checks if an address is allowed to submit jobs.
     /// @param submitter The address to check.
     /// @return True if the address is allowed, false otherwise.
    function isJobSubmitterAllowed(address submitter) public view returns (bool) {
        return _allowedJobSubmitters[submitter];
    }


    // --- Configuration ---

    /// @notice Sets the maximum number of qubits this contract can support.
    /// This value is used during initialization validation. Can only be set once.
    /// Lowering this value after initialization has no effect on existing state.
    /// @param maxQubits_ The maximum number of qubits to allow (up to ~10 is practical).
    function setMaxQubits(uint8 maxQubits_) public onlyOwner {
        require(!_maxQubitsSet, "QSP: Max qubits already set");
        require(maxQubits_ > 0, "QSP: Max qubits must be positive");
        // Note: Realistically, even 10 is pushing array size limits on chain.
        // Gas costs increase exponentially with numQubits.
        require(maxQubits_ <= 10, "QSP: Max qubits capped at 10 for practical reasons"); // Hard cap for gas
        _maxQubitsSupported = maxQubits_;
        _maxQubitsSet = true;
        emit MaxQubitsSupportedSet(maxQubits_);
    }

    /// @notice Gets the maximum number of qubits supported by this contract.
    /// @return The maximum number of qubits.
    function getMaxQubits() public view returns (uint8) {
        return _maxQubitsSupported;
    }


    // --- Ownership ---

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address of the new owner.
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "QSP: New owner is the zero address");
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /// @notice Gets the current owner of the contract.
    /// @return The owner address.
    function getOwner() public view returns (address) {
        return _owner;
    }

    // --- Internal Helpers ---
    // (No new functions exposed externally needed to meet count)

    // Could add internal function for state normalization if needed after operations
    // that don't intrinsically preserve sum (like a probabilistic error model)
    // function _normalizeStateProbabilities() internal { ... }

}
```