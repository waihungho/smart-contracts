Okay, here is a smart contract concept called `QuantumVault`. It attempts to simulate or represent certain abstract concepts inspired by quantum mechanics (superposition, entanglement, measurement, gates) and apply them to control access and logic within a decentralized vault for assets (Ether and ERC-20 tokens).

**Disclaimer:** This contract *simulates* quantum concepts using classical computing logic on a deterministic blockchain. It does *not* perform actual quantum computation, which is currently impossible within Solidity. The "quantum" aspect is a creative abstraction for state management and access control. This is an advanced and complex example, likely for educational or theoretical purposes, and would require rigorous security audits before any real-world deployment with significant value.

---

**Outline and Function Summary**

**Contract Name:** QuantumVault

**Concept:** A decentralized vault that manages Ether and ERC-20 tokens. Access and specific operations are controlled by the state of abstract "Qubits" which can exist in simulated states of superposition and entanglement, and whose definitive value is determined upon "measurement" using a pseudo-random process.

**Core Concepts Simulated:**
*   **Qubit:** Represented by a struct holding potential values (A and B), probability (for A), measured state, and entanglement link.
*   **Superposition:** A Qubit is in superposition if it hasn't been measured (`isMeasured` is false), holding `potentialValueA` and `potentialValueB` with a given probability `potentialProbabilityA`.
*   **Entanglement:** Two Qubits can be linked (`entangledWithId`), and their measurement outcomes can be correlated based on a defined `EntanglementRule`.
*   **Measurement:** The process of collapsing a Qubit's superposition into a single `measuredValue`. This uses a pseudo-random number derived from block data and user entropy.
*   **Quantum Gates (Simulated):** Functions that manipulate the potential states or entanglement of Qubits (`applyHadamardGate`, `applyPauliXGate`, `applyCNOTGate`).
*   **Decoherence (Simulated):** A mechanism for Qubits in superposition to randomly collapse their state over time or through external trigger.
*   **Quantum Key/Condition:** Specific operations (like withdrawals) require certain Qubits to be in a specific *measured* state.
*   **Fractal Measurement:** Measuring one Qubit can influence or trigger the measurement of connected (not necessarily entangled) Qubits.
*   **Dependent Qubits:** A Qubit whose measured state is deterministically derived from the measured state of another Qubit based on a defined rule.
*   **Delegated Measurement:** Allowing a third party to perform the measurement action for a specific Qubit.
*   **Measurement Cost:** Making the act of measurement require payment, simulating energy cost or effort.

**Function Summary:**

1.  **`constructor()`:** Initializes contract owner.
2.  **`receive()`:** Allows receiving Ether deposits into the vault.
3.  **`fallback()`:** Handles unexpected Ether transfers.
4.  **`addSupportedToken(IERC20 token)`:** Owner adds an ERC-20 token address that the vault will accept and manage.
5.  **`depositERC20(IERC20 token, uint256 amount)`:** Deposits ERC-20 tokens into the vault (requires prior approval).
6.  **`withdrawEther(uint256 amount, uint256 conditionQubitId, uint256 requiredState)`:** Withdraws Ether, requires a specific Qubit to be measured to a required state.
7.  **`withdrawERC20(IERC20 token, uint256 amount, uint256 conditionQubitId, uint256 requiredState)`:** Withdraws ERC-20, requires a specific Qubit to be measured to a required state.
8.  **`setVaultAccessCondition(uint256 conditionQubitId, uint256 requiredState)`:** Sets a global vault access condition based on a Qubit's measured state.
9.  **`getVaultAccessCondition()`:** View function to get the global vault access condition.
10. **`createQubit()`:** Creates a new Qubit in a default (unmeasured) superposition state (e.g., 0/1, 50/50).
11. **`setPotentialStates(uint256 qubitId, uint256 valueA, uint256 valueB, uint64 probabilityApermil)`:** Sets specific potential values and probability for a Qubit in superposition. Probability is per mille (1/1000).
12. **`applyHadamardGate(uint256 qubitId)`:** Simulates a Hadamard gate - sets superposition to 0 and 1 with ~50/50 probability.
13. **`applyPauliXGate(uint252 qubitId)`:** Simulates a Pauli-X (NOT) gate - swaps potential states if in superposition, or flips measured state (0<->1) if measured (assuming 0/1 states).
14. **`entangleQubits(uint256 qubitId1, uint256 qubitId2, EntanglementRule rule)`:** Links two unmeasured Qubits with a specific correlation rule.
15. **`applyCNOTGate(uint256 controlQubitId, uint256 targetQubitId)`:** Simulates a CNOT gate - If the control Qubit is measured as 1, it applies a Pauli-X gate to the target Qubit (if in superposition or measured).
16. **`measureQubit(uint256 qubitId, uint256 userEntropy)`:** Measures a single Qubit, collapsing its superposition based on probability and pseudo-randomness. Also handles entangled pairs if the partner is unmeasured. Payable if a measurement cost is set.
17. **`measureEntangledPair(uint256 qubitId1, uint256 qubitId2, uint256 userEntropy)`:** Measures two entangled Qubits, ensuring their outcomes correlate according to their entanglement rule. Payable.
18. **`setAutoMeasureTimestamp(uint256 qubitId, uint64 timestamp)`:** Schedules a Qubit to be automatically measured after a specific time.
19. **`triggerAutoMeasurements(uint256[] calldata qubitIds)`:** Allows anyone to trigger auto-measurements for a list of Qubits whose schedule has passed.
20. **`delegateMeasurement(uint256 qubitId, address delegatee, uint64 validUntil)`:** Allows `delegatee` to measure `qubitId` until `validUntil` timestamp.
21. **`revokeMeasurementDelegate(uint256 qubitId, address delegatee)`:** Revokes measurement delegation.
22. **`isDelegateForMeasurement(uint256 qubitId, address account)`:** View function to check if an account is a valid delegate for a Qubit.
23. **`fractalMeasure(uint256 primaryQubitId, uint256[] calldata connectedQubitIds, uint256 userEntropy)`:** Measures the primary Qubit, then attempts to measure connected Qubits that are still in superposition, potentially using a shared entropy. Payable.
24. **`simulateDecoherence(uint256 qubitId, uint256 userEntropy)`:** Triggers a random measurement of a Qubit that is in superposition, simulating environmental interaction or decoherence. Payable.
25. **`setMeasurementCost(uint256 qubitId, uint256 cost)`:** Sets a required Ether payment for measuring a specific Qubit.
26. **`getQubitState(uint256 qubitId)`:** View function to get the current state of a Qubit (measured value or potential values/probability).
27. **`getEntangledPairState(uint256 qubitId1, uint256 qubitId2)`:** View function to get the state and entanglement details of a potential or actual entangled pair.
28. **`createDependentQubit(uint256 sourceQubitId, DependencyRule rule)`:** Creates a new Qubit whose *potential* state depends on the *future measured* state of the source Qubit according to a rule. Initially unmeasured.
29. **`triggerDependentQubitUpdate(uint256 dependentQubitId)`:** Updates the state of a dependent Qubit if its source Qubit has been measured and the dependent Qubit is still unmeasured. The dependent Qubit then becomes measured.
30. **`getDependentQubitDetails(uint256 dependentQubitId)`:** View function for details of a dependent Qubit.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin for Owner pattern
import "@openzeppelin/contracts/utils/math/Math.sol"; // Using OpenZeppelin for utilities

/**
 * @title QuantumVault
 * @dev A decentralized vault simulating quantum concepts (superposition, entanglement, measurement)
 *      to control asset access (Ether and ERC-20).
 *      Note: This contract simulates quantum mechanics using classical computing logic
 *      on a deterministic blockchain. It does not perform actual quantum computation.
 *      The "quantum" aspect is an abstract layer for state management and access control.
 */
contract QuantumVault is Ownable {
    using Math for uint256; // Example using Math for min/max (optional)

    // --- Events ---
    event QubitCreated(uint256 indexed qubitId, address creator);
    event QubitStateChanged(uint256 indexed qubitId, uint256 oldValue, uint256 newValue, bool wasMeasured);
    event QubitMeasured(uint256 indexed qubitId, uint256 measuredValue, uint256 userEntropyUsed);
    event EntanglementCreated(uint256 indexed qubitId1, uint256 indexed qubitId2, EntanglementRule rule);
    event QubitEntanglementBroken(uint256 indexed qubitId);
    event DepositEther(address indexed account, uint256 amount);
    event WithdrawEther(address indexed account, uint256 amount);
    event DepositERC20(address indexed account, IERC20 indexed token, uint256 amount);
    event WithdrawERC20(address indexed account, IERC20 indexed token, uint256 amount);
    event VaultAccessConditionSet(uint256 indexed conditionQubitId, uint256 requiredState);
    event AutoMeasureScheduled(uint256 indexed qubitId, uint64 timestamp);
    event AutoMeasureTriggered(uint256 indexed qubitId, address triggerer);
    event MeasurementDelegated(uint256 indexed qubitId, address indexed delegatee, uint64 validUntil);
    event MeasurementDelegateRevoked(uint256 indexed qubitId, address indexed delegatee);
    event FractalMeasurementTriggered(uint256 indexed primaryQubitId, uint256[] connectedQubitIds);
    event DecoherenceSimulated(uint256 indexed qubitId);
    event MeasurementCostSet(uint256 indexed qubitId, uint256 cost);
    event DependentQubitCreated(uint256 indexed dependentQubitId, uint256 indexed sourceQubitId, DependencyRule rule);
    event DependentQubitUpdated(uint256 indexed dependentQubitId, uint256 measuredValue);

    // --- Enums ---
    enum EntanglementRule {
        XOR_Correlated,     // Measured states a ^ b == 0 (i.e., a == b)
        NOT_XOR_Correlated, // Measured states a ^ b == 1 (i.e., a != b)
        Sum_Even,           // Measured states a + b is even
        Sum_Odd             // Measured states a + b is odd
    }

    enum DependencyRule {
        SourceValue,           // Dependent value = Source value
        SourceValuePlus1,      // Dependent value = Source value + 1
        SourceValueTimes2,     // Dependent value = Source value * 2
        IfSourceZeroThen1Else2 // Dependent value = 1 if Source is 0, 2 otherwise
    }

    // --- Structs ---
    struct QuBit {
        bool isMeasured;          // True if the Qubit has been measured
        uint256 measuredValue;    // The definitive value after measurement
        uint256 potentialValueA;  // One potential value if in superposition
        uint256 potentialValueB;  // The other potential value if in superposition
        uint64 potentialProbabilityApermil; // Probability of collapsing to valueA (out of 1000) if in superposition

        uint256 entangledWithId;  // ID of the Qubit it's entangled with (0 if none)
        EntanglementRule entanglementRule; // Rule governing correlation if entangled

        uint64 autoMeasureTimestamp; // Timestamp after which auto-measurement can be triggered (0 if none)

        uint256 dependsOnQubitId;   // ID of the Qubit this one depends on (0 if none)
        DependencyRule dependencyRule; // Rule to derive value if dependent
    }

    struct MeasurementDelegate {
        address delegatee;
        uint64 validUntil; // Timestamp until the delegation is valid
    }

    // --- State Variables ---
    mapping(uint256 => QuBit) public qubits; // Mapping from unique ID to Qubit data
    uint256 private nextQubitId = 1;         // Counter for issuing unique Qubit IDs

    mapping(address => bool) public supportedTokens; // ERC20 tokens supported by the vault
    // Note: ERC20 balances are tracked directly in the token contract.
    // The vault contract's balance represents Ether held.

    uint256 public vaultConditionQubitId = 0; // Qubit ID required for vault access (0 if none)
    uint256 public vaultRequiredState = 0;    // Required measured state of the conditionQubitId

    mapping(uint252 => mapping(address => MeasurementDelegate)) private measurementDelegates; // QubitId => Delegatee => Delegation details

    mapping(uint256 => uint256) public qubitMeasurementCost; // QubitId => Required Ether cost to measure

    // Pseudo-randomness counter to add variance between measurements in the same block
    uint256 private randomnessCounter = 0;

    // --- Modifiers ---
    modifier qubitExists(uint256 _qubitId) {
        require(_qubitId > 0 && _qubitId < nextQubitId, "Invalid Qubit ID");
        _;
    }

    modifier qubitNotMeasured(uint256 _qubitId) {
        require(!qubits[_qubitId].isMeasured, "Qubit already measured");
        _;
    }

    modifier qubitIsInSuperposition(uint256 _qubitId) {
        require(!qubits[_qubitId].isMeasured, "Qubit is not in superposition (already measured)");
        require(qubits[_qubitId].potentialValueA != qubits[_qubitId].potentialValueB || qubits[_qubitId].potentialProbabilityApermil != 0, "Qubit is in a fixed potential state, not true superposition");
        _;
    }

    modifier qubitIsMeasured(uint256 _qubitId) {
        require(qubits[_qubitId].isMeasured, "Qubit is not yet measured");
        _;
    }

    modifier onlyDelegateOrOwner(uint256 _qubitId) {
        MeasurementDelegate storage delegateInfo = measurementDelegates[_qubitId][msg.sender];
        require(
            msg.sender == owner() || (delegateInfo.delegatee != address(0) && block.timestamp <= delegateInfo.validUntil),
            "Not authorized: Must be owner or valid delegate"
        );
        _;
    }

    modifier checkVaultAccessCondition() {
        if (vaultConditionQubitId != 0) {
            require(
                qubits[vaultConditionQubitId].isMeasured && qubits[vaultConditionQubitId].measuredValue == vaultRequiredState,
                "Vault access condition not met: Required Qubit not in correct measured state"
            );
        }
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {}

    // --- Receive and Fallback ---
    receive() external payable {
        emit DepositEther(msg.sender, msg.value);
    }

    fallback() external payable {
        emit DepositEther(msg.sender, msg.value);
    }

    // --- Internal Helpers ---

    /**
     * @dev Generates a pseudo-random number within a range.
     *      Uses block data and user entropy. Highly dependent on miner behavior
     *      and user input, NOT cryptographically secure or truly random.
     *      Suitable only for simulation purposes within a deterministic environment.
     * @param max The upper bound (exclusive) for the random number.
     * @param userEntropy Additional entropy provided by the user.
     * @return A pseudo-random uint256 less than max.
     */
    function _getPseudoRandomNumber(uint256 max, uint256 userEntropy) internal returns (uint256) {
        randomnessCounter++;
        uint256 source = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.number,
                    block.difficulty, // Use block.prevrandao on PoS chains
                    block.gaslimit,
                    msg.sender,
                    userEntropy,
                    randomnessCounter // Add counter for variance within a block
                )
            )
        );
        return source % max;
    }

    /**
     * @dev Internal function to set a Qubit to a measured state.
     * @param _qubitId The ID of the Qubit to measure.
     * @param _measuredValue The value to set the Qubit to.
     */
    function _setMeasuredState(uint256 _qubitId, uint256 _measuredValue) internal {
        QuBit storage qubit = qubits[_qubitId];
        uint256 oldVal = qubit.measuredValue; // Store old value if it was already measured (unlikely with checks)
        bool wasMeasured = qubit.isMeasured;

        qubit.isMeasured = true;
        qubit.measuredValue = _measuredValue;
        // Clear superposition state
        qubit.potentialValueA = 0;
        qubit.potentialValueB = 0;
        qubit.potentialProbabilityApermil = 0;
        // Clear auto-measure schedule
        qubit.autoMeasureTimestamp = 0;
        // Clear delegation
        delete measurementDelegates[_qubitId]; // Clear all delegates for this qubit

        emit QubitStateChanged(_qubitId, oldVal, _measuredValue, wasMeasured);
    }

    // --- Vault Management Functions ---

    /**
     * @dev Owner adds a supported ERC20 token address.
     * @param token The address of the ERC20 token.
     */
    function addSupportedToken(IERC20 token) external onlyOwner {
        require(address(token) != address(0), "Invalid token address");
        supportedTokens[address(token)] = true;
    }

    /**
     * @dev Deposits ERC20 tokens into the vault.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(IERC20 token, uint256 amount) external {
        require(supportedTokens[address(token)], "Token not supported");
        require(amount > 0, "Amount must be greater than zero");
        // Requires the user to have approved this contract to spend the tokens
        token.transferFrom(msg.sender, address(this), amount);
        emit DepositERC20(msg.sender, token, amount);
    }

    /**
     * @dev Withdraws Ether from the vault. Requires a specific Qubit to be in a required measured state.
     * @param amount The amount of Ether to withdraw.
     * @param conditionQubitId The ID of the Qubit whose state is checked for access.
     * @param requiredState The required measured value of the condition Qubit.
     */
    function withdrawEther(uint256 amount, uint256 conditionQubitId, uint256 requiredState)
        external
        qubitExists(conditionQubitId)
        qubitIsMeasured(conditionQubitId)
        checkVaultAccessCondition // Also check global condition if set
    {
        require(qubits[conditionQubitId].measuredValue == requiredState, "Specific withdrawal condition not met");
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient Ether balance in vault");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Ether withdrawal failed");

        emit WithdrawEther(msg.sender, amount);
    }

    /**
     * @dev Withdraws ERC20 tokens from the vault. Requires a specific Qubit to be in a required measured state.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     * @param conditionQubitId The ID of the Qubit whose state is checked for access.
     * @param requiredState The required measured value of the condition Qubit.
     */
    function withdrawERC20(IERC20 token, uint256 amount, uint256 conditionQubitId, uint256 requiredState)
        external
        qubitExists(conditionQubitId)
        qubitIsMeasured(conditionQubitId)
        checkVaultAccessCondition // Also check global condition if set
    {
        require(supportedTokens[address(token)], "Token not supported");
        require(qubits[conditionQubitId].measuredValue == requiredState, "Specific withdrawal condition not met");
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance in vault");

        token.transfer(msg.sender, amount);

        emit WithdrawERC20(msg.sender, token, amount);
    }

    /**
     * @dev Owner sets a global condition for any vault action requiring access control.
     *      Setting conditionQubitId to 0 removes the global condition.
     * @param conditionQubitId The ID of the Qubit whose state is checked.
     * @param requiredState The required measured value.
     */
    function setVaultAccessCondition(uint256 conditionQubitId, uint256 requiredState) external onlyOwner {
        if (conditionQubitId != 0) {
            require(conditionQubitId > 0 && conditionQubitId < nextQubitId, "Invalid Qubit ID for condition");
        }
        vaultConditionQubitId = conditionQubitId;
        vaultRequiredState = requiredState;
        emit VaultAccessConditionSet(conditionQubitId, requiredState);
    }

    /**
     * @dev Gets the current global vault access condition.
     * @return conditionQubitId The ID of the Qubit checked for access (0 if none).
     * @return requiredState The required measured value.
     */
    function getVaultAccessCondition() external view returns (uint256, uint256) {
        return (vaultConditionQubitId, vaultRequiredState);
    }

    // --- Qubit Creation and State Setting ---

    /**
     * @dev Creates a new Qubit in a default superposition state (0/1 with ~50/50 chance).
     * @return The ID of the newly created Qubit.
     */
    function createQubit() external returns (uint256) {
        uint256 qubitId = nextQubitId;
        qubits[qubitId] = QuBit({
            isMeasured: false,
            measuredValue: 0, // Default before measurement
            potentialValueA: 0,
            potentialValueB: 1,
            potentialProbabilityApermil: 500, // 50%
            entangledWithId: 0,
            entanglementRule: EntanglementRule.XOR_Correlated, // Default rule
            autoMeasureTimestamp: 0,
            dependsOnQubitId: 0,
            dependencyRule: DependencyRule.SourceValue // Default rule
        });
        nextQubitId++;
        emit QubitCreated(qubitId, msg.sender);
        return qubitId;
    }

    /**
     * @dev Sets the potential states and probability for a Qubit in superposition.
     * @param qubitId The ID of the Qubit.
     * @param valueA Potential value A.
     * @param valueB Potential value B.
     * @param probabilityApermil Probability of collapsing to valueA (0-1000).
     */
    function setPotentialStates(uint255 qubitId, uint256 valueA, uint256 valueB, uint64 probabilityApermil)
        external
        qubitExists(qubitId)
        qubitNotMeasured(qubitId)
    {
        require(probabilityApermil <= 1000, "Probability must be between 0 and 1000");
        QuBit storage qubit = qubits[qubitId];
        qubit.potentialValueA = valueA;
        qubit.potentialValueB = valueB;
        qubit.potentialProbabilityApermil = probabilityApermil;
        // If probabilities are 0 or 1000, it's no longer truly in superposition w.r.t values
        if (probabilityApermil == 0 || probabilityApermil == 1000) {
             emit QubitStateChanged(qubitId, qubit.measuredValue, (probabilityApermil == 1000 ? valueA : valueB), false); // Indicate potential change
        } else {
             emit QubitStateChanged(qubitId, qubit.measuredValue, 0, false); // Indicate transition/stay in superposition
        }
    }

     /**
      * @dev Simulates applying a Hadamard gate: Sets potential states to 0 and 1 with ~50/50 probability.
      * @param qubitId The ID of the Qubit.
      */
     function applyHadamardGate(uint256 qubitId) external qubitIsInSuperposition(qubitId) {
         setPotentialStates(qubitId, 0, 1, 500); // Values 0 and 1, 50% chance for 0
         // Note: The exact values 0 and 1 are arbitrary simulation choices.
         // A true Hadamard transforms basis states |0> and |1> into superpositions.
     }

     /**
      * @dev Simulates applying a Pauli-X (NOT) gate.
      *      If in superposition: Swaps potentialValueA and potentialValueB, flips probability (1000 - prob).
      *      If measured (and value is 0 or 1): Flips measured value (0->1, 1->0).
      * @param qubitId The ID of the Qubit.
      */
     function applyPauliXGate(uint256 qubitId) external qubitExists(qubitId) {
         QuBit storage qubit = qubits[qubitId];
         if (qubit.isMeasured) {
             // Simulate flipping measured state (assuming states are 0 or 1)
             require(qubit.measuredValue == 0 || qubit.measuredValue == 1, "PauliX simulation only applies to 0/1 measured states");
             _setMeasuredState(qubitId, qubit.measuredValue == 0 ? 1 : 0);
         } else {
             // Simulate flipping potential states
             uint256 tempValue = qubit.potentialValueA;
             qubit.potentialValueA = qubit.potentialValueB;
             qubit.potentialValueB = tempValue;
             qubit.potentialProbabilityApermil = 1000 - qubit.potentialProbabilityApermil;
             emit QubitStateChanged(qubitId, qubit.measuredValue, 0, false); // Still in superposition
         }
     }


    /**
     * @dev Entangles two unmeasured Qubits with a specific correlation rule upon measurement.
     * @param qubitId1 The ID of the first Qubit.
     * @param qubitId2 The ID of the second Qubit.
     * @param rule The EntanglementRule to apply upon measurement.
     */
    function entangleQubits(uint256 qubitId1, uint256 qubitId2, EntanglementRule rule)
        external
        qubitExists(qubitId1)
        qubitExists(qubitId2)
        qubitNotMeasured(qubitId1)
        qubitNotMeasured(qubitId2)
    {
        require(qubitId1 != qubitId2, "Cannot entangle a Qubit with itself");
        require(qubits[qubitId1].entangledWithId == 0 && qubits[qubitId2].entangledWithId == 0, "One or both Qubits are already entangled");

        qubits[qubitId1].entangledWithId = qubitId2;
        qubits[qubit1].entanglementRule = rule;
        qubits[qubitId2].entangledWithId = qubitId1;
        qubits[qubitId2].entanglementRule = rule; // Both qubits store the rule

        emit EntanglementCreated(qubitId1, qubitId2, rule);
    }

    /**
     * @dev Simulates applying a CNOT gate (Controlled-NOT).
     *      Requires the control Qubit to be measured. If measured as 1, applies Pauli-X to the target.
     *      If control is 0, target remains unchanged. If control unmeasured, action is undefined/not possible.
     * @param controlQubitId The ID of the control Qubit (must be measured).
     * @param targetQubitId The ID of the target Qubit.
     */
    function applyCNOTGate(uint256 controlQubitId, uint256 targetQubitId)
        external
        qubitExists(controlQubitId)
        qubitExists(targetQubitId)
        qubitIsMeasured(controlQubitId) // CNOT acts based on measured control
    {
        require(qubitId1 != qubitId2, "Control and target Qubits must be different");

        QuBit storage control = qubits[controlQubitId];
        // Simulate CNOT logic: if control is 1, apply Pauli-X (NOT) to target
        if (control.measuredValue == 1) {
             // Check if target is measured. If so, apply PauliX (flips 0/1).
             // If target is in superposition, apply PauliX to its potential states.
             applyPauliXGate(targetQubitId); // Reuse existing PauliX logic
        }
        // If control is 0, do nothing to target - this is handled by the implicit 'if'
    }


    // --- Qubit Measurement Functions ---

    /**
     * @dev Measures a single Qubit, collapsing its superposition.
     *      If the Qubit is entangled and its partner is unmeasured, measures the partner as well with correlated outcome.
     *      This function is payable if a measurement cost is set for this qubit.
     * @param qubitId The ID of the Qubit to measure.
     * @param userEntropy Additional entropy from the user for pseudo-randomness.
     */
    function measureQubit(uint256 qubitId, uint256 userEntropy)
        external
        payable
        qubitExists(qubitId)
        qubitNotMeasured(qubitId)
        onlyDelegateOrOwner(qubitId) // Can only be called by owner or authorized delegate
    {
        // Check and handle measurement cost
        uint256 cost = qubitMeasurementCost[qubitId];
        if (cost > 0) {
             require(msg.value >= cost, "Insufficient payment for measurement");
             if (msg.value > cost) {
                 // Refund excess Ether
                 (bool success, ) = msg.sender.call{value: msg.value - cost}("");
                 require(success, "Refund failed");
             }
             // Transfer cost to owner (or another address/logic)
             (bool success, ) = owner().call{value: cost}("");
             require(success, "Cost transfer failed");
         } else {
             require(msg.value == 0, "No Ether expected for this measurement");
         }


        QuBit storage qubit = qubits[qubitId];
        uint256 measuredVal;

        if (qubit.entangledWithId != 0) {
            // Handle entangled measurement
            uint256 partnerId = qubit.entangledWithId;
            QuBit storage partner = qubits[partnerId];

            require(!partner.isMeasured, "Partner Qubit is already measured. Entanglement broken.");

            // Measure both entangled qubits ensuring correlation
            (uint256 val1, uint256 val2) = _measureEntangled(qubitId, partnerId, qubit.entanglementRule, userEntropy);

            // Set measured states for both
            _setMeasuredState(qubitId, val1);
            _setMeasuredState(partnerId, val2);
            measuredVal = val1; // Return the measured value of the originally requested qubit

            emit QubitMeasured(qubitId, measuredVal, userEntropy);
            emit QubitMeasured(partnerId, val2, userEntropy);
            emit QubitEntanglementBroken(qubitId); // Entanglement is broken after measurement
            emit QubitEntanglementBroken(partnerId);

        } else if (qubit.dependsOnQubitId != 0) {
            // This case should ideally be handled by triggerDependentQubitUpdate *after* source is measured
            // Prevent direct measurement if it's a dependent qubit still waiting for source
             revert("Dependent Qubit cannot be directly measured until source is measured");

        } else {
            // Measure a single, non-entangled, non-dependent qubit in superposition
            uint256 randomNum = _getPseudoRandomNumber(1000, userEntropy); // Random number 0-999

            if (randomNum < qubit.potentialProbabilityApermil) {
                measuredVal = qubit.potentialValueA;
            } else {
                measuredVal = qubit.potentialValueB;
            }

            _setMeasuredState(qubitId, measuredVal);
            emit QubitMeasured(qubitId, measuredVal, userEntropy);
        }
    }

     /**
      * @dev Internal helper to measure an entangled pair according to the rule.
      *      Assumes both qubits are unmeasured and entangled.
      * @param qubitId1 ID of the first Qubit.
      * @param qubitId2 ID of the second Qubit.
      * @param rule The EntanglementRule.
      * @param userEntropy Entropy for pseudo-randomness.
      * @return (value1, value2) The measured values for qubit1 and qubit2.
      */
     function _measureEntangled(uint256 qubitId1, uint256 qubitId2, EntanglementRule rule, uint256 userEntropy)
        internal
        returns (uint256, uint256)
     {
         // Simplified entanglement simulation:
         // Measure the first qubit based on its probability, then determine the second
         // based on the rule and the first qubit's outcome.

         QuBit storage qubit1 = qubits[qubitId1];
         QuBit storage qubit2 = qubits[qubitId2];

         uint256 randomNum = _getPseudoRandomNumber(1000, userEntropy);
         uint256 measuredVal1;
         uint256 measuredVal2;

         // First, determine the outcome for Qubit 1 based on its superposition state (even if entangled)
         // This is a simplification; in true QM, measurement of one instantly determines both.
         if (randomNum < qubit1.potentialProbabilityApermil) {
             measuredVal1 = qubit1.potentialValueA;
         } else {
             measuredVal1 = qubit1.potentialValueB;
         }

         // Now, determine the outcome for Qubit 2 based on Qubit 1's outcome and the rule
         // This simulation assumes potential values are somewhat aligned (e.g., 0/1)
         // More complex rules might need lookup tables or more sophisticated logic.
         if (rule == EntanglementRule.XOR_Correlated) { // a == b
             measuredVal2 = measuredVal1;
         } else if (rule == EntanglementRule.NOT_XOR_Correlated) { // a != b (Requires potential values to be different)
             if (measuredVal1 == qubit2.potentialValueA) {
                 measuredVal2 = qubit2.potentialValueB; // Should collapse to the *other* potential value
             } else { // measuredVal1 == qubit2.potentialValueB
                  measuredVal2 = qubit2.potentialValueA; // Should collapse to the *other* potential value
             }
         } else if (rule == EntanglementRule.Sum_Even) { // a + b is even
             // If val1 is even, val2 must be even. If val1 is odd, val2 must be odd.
             if (measuredVal1 % 2 == 0) { // val1 is even
                 // Qubit 2 must measure to an even value. Pick from potentialValueA/B if even exists.
                 if (qubit2.potentialValueA % 2 == 0) measuredVal2 = qubit2.potentialValueA;
                 else if (qubit2.potentialValueB % 2 == 0) measuredVal2 = qubit2.potentialValueB;
                 else revert("Entanglement rule incompatible with potential states for Sum_Even"); // Rule cannot be satisfied
             } else { // val1 is odd
                 // Qubit 2 must measure to an odd value. Pick from potentialValueA/B if odd exists.
                 if (qubit2.potentialValueA % 2 != 0) measuredVal2 = qubit2.potentialValueA;
                 else if (qubit2.potentialValueB % 2 != 0) measuredVal2 = qubit2.potentialValueB;
                 else revert("Entanglement rule incompatible with potential states for Sum_Even"); // Rule cannot be satisfied
             }
         } else if (rule == EntanglementRule.Sum_Odd) { // a + b is odd
              // If val1 is even, val2 must be odd. If val1 is odd, val2 must be even.
              if (measuredVal1 % 2 == 0) { // val1 is even
                 // Qubit 2 must measure to an odd value.
                 if (qubit2.potentialValueA % 2 != 0) measuredVal2 = qubit2.potentialValueA;
                 else if (qubit2.potentialValueB % 2 != 0) measuredVal2 = qubit2.potentialValueB;
                 else revert("Entanglement rule incompatible with potential states for Sum_Odd");
             } else { // val1 is odd
                 // Qubit 2 must measure to an even value.
                 if (qubit2.potentialValueA % 2 == 0) measuredVal2 = qubit2.potentialValueA;
                 else if (qubit2.potentialValueB % 2 == 0) measuredVal2 = qubit2.potentialValueB;
                 else revert("Entanglement rule incompatible with potential states for Sum_Odd");
             }
         } else {
             // Default / fallback - this shouldn't happen if enum is used correctly
             measuredVal2 = qubit2.potentialValueA; // Arbitrarily pick one
         }

         return (measuredVal1, measuredVal2);
     }

    /**
     * @dev Measures two entangled Qubits simultaneously. Requires both to be unmeasured and entangled with each other.
     * @param qubitId1 The ID of the first Qubit.
     * @param qubitId2 The ID of the second Qubit.
     * @param userEntropy Additional entropy for pseudo-randomness.
     */
    function measureEntangledPair(uint256 qubitId1, uint256 qubitId2, uint256 userEntropy)
        external
        payable // Allow payment if measurement costs are set for either qubit
        qubitExists(qubitId1)
        qubitExists(qubitId2)
        qubitNotMeasured(qubitId1)
        qubitNotMeasured(qubitId2)
    {
        require(qubitId1 != qubitId2, "IDs must be different");
        require(qubits[qubitId1].entangledWithId == qubitId2 && qubits[qubitId2].entangledWithId == qubitId1, "Qubits are not properly entangled with each other");

        // Handle potential measurement costs for both qubits
         uint256 cost1 = qubitMeasurementCost[qubitId1];
         uint256 cost2 = qubitMeasurementCost[qubitId2];
         uint256 totalCost = cost1 + cost2;

         if (totalCost > 0) {
             require(msg.value >= totalCost, "Insufficient payment for measurement");
             if (msg.value > totalCost) {
                 (bool success, ) = msg.sender.call{value: msg.value - totalCost}("");
                 require(success, "Refund failed");
             }
             (bool success, ) = owner().call{value: totalCost}("");
             require(success, "Cost transfer failed");
         } else {
             require(msg.value == 0, "No Ether expected for this measurement");
         }


        // Measure both according to the entanglement rule
        (uint256 val1, uint256 val2) = _measureEntangled(qubitId1, qubitId2, qubits[qubitId1].entanglementRule, userEntropy);

        // Set measured states for both
        _setMeasuredState(qubitId1, val1);
        _setMeasuredState(qubitId2, val2);

        emit QubitMeasured(qubitId1, val1, userEntropy);
        emit QubitMeasured(qubitId2, val2, userEntropy);
        emit QubitEntanglementBroken(qubitId1); // Entanglement is broken after measurement
        emit QubitEntanglementBroken(qubitId2);
    }


    // --- Timed and Delegated Measurement ---

    /**
     * @dev Schedules a Qubit for automatic measurement after a specified timestamp.
     *      Requires the Qubit to be in superposition.
     * @param qubitId The ID of the Qubit.
     * @param timestamp The Unix timestamp after which auto-measurement can be triggered.
     */
    function setAutoMeasureTimestamp(uint256 qubitId, uint64 timestamp)
        external
        qubitIsInSuperposition(qubitId)
        onlyOwner // Only owner can schedule auto-measurement
    {
        require(timestamp > block.timestamp, "Timestamp must be in the future");
        qubits[qubitId].autoMeasureTimestamp = timestamp;
        emit AutoMeasureScheduled(qubitId, timestamp);
    }

    /**
     * @dev Allows anyone to trigger auto-measurements for a list of Qubits whose scheduled time has passed.
     *      Provides a gas incentive by allowing anyone to call it.
     * @param qubitIds An array of Qubit IDs to check and potentially auto-measure.
     */
    function triggerAutoMeasurements(uint256[] calldata qubitIds) external {
        uint256 userEntropy = uint256(uint160(msg.sender)); // Use sender address as simple entropy

        for (uint i = 0; i < qubitIds.length; i++) {
            uint256 qubitId = qubitIds[i];
            if (qubitId > 0 && qubitId < nextQubitId) {
                 QuBit storage qubit = qubits[qubitId];
                 if (!qubit.isMeasured && qubit.autoMeasureTimestamp != 0 && block.timestamp >= qubit.autoMeasureTimestamp) {
                     // Attempt to measure - handles single or entangled
                     // Note: This bypasses delegation and measurement cost checks
                     // Auto-measurement is a different mechanism.
                     uint256 measuredVal;

                     if (qubit.entangledWithId != 0) {
                         uint256 partnerId = qubit.entangledWithId;
                         QuBit storage partner = qubits[partnerId];
                         if (!partner.isMeasured) {
                              (uint256 val1, uint256 val2) = _measureEntangled(qubitId, partnerId, qubit.entanglementRule, userEntropy + qubitId + partnerId); // Add IDs for variance
                              _setMeasuredState(qubitId, val1);
                              _setMeasuredState(partnerId, val2);
                              measuredVal = val1;
                              emit QubitMeasured(qubitId, measuredVal, userEntropy + qubitId + partnerId);
                              emit QubitMeasured(partnerId, val2, userEntropy + qubitId + partnerId);
                              emit QubitEntanglementBroken(qubitId);
                              emit QubitEntanglementBroken(partnerId);
                         }
                     } else if (qubit.dependsOnQubitId == 0) { // Don't auto-measure dependent qubits directly
                         uint256 randomNum = _getPseudoRandomNumber(1000, userEntropy + qubitId); // Add ID for variance
                         if (randomNum < qubit.potentialProbabilityApermil) {
                             measuredVal = qubit.potentialValueA;
                         } else {
                             measuredVal = qubit.potentialValueB;
                         }
                         _setMeasuredState(qubitId, measuredVal);
                         emit QubitMeasured(qubitId, measuredVal, userEntropy + qubitId);
                     } else {
                         // If it's a dependent qubit, check if source is measured
                         uint256 sourceId = qubit.dependsOnQubitId;
                         if (sourceId > 0 && sourceId < nextQubitId && qubits[sourceId].isMeasured) {
                            // Trigger the update for the dependent qubit
                            _triggerDependentQubitUpdate(qubitId);
                         }
                     }

                     emit AutoMeasureTriggered(qubitId, msg.sender);
                 }
            }
        }
    }

    /**
     * @dev Allows the owner to delegate the right to measure a specific Qubit to another address.
     * @param qubitId The ID of the Qubit.
     * @param delegatee The address to delegate to.
     * @param validUntil Timestamp until the delegation is valid. Set to 0 to remove existing delegation.
     */
    function delegateMeasurement(uint256 qubitId, address delegatee, uint64 validUntil) external onlyOwner qubitExists(qubitId) {
        require(delegatee != address(0), "Delegatee address cannot be zero");
        require(!qubits[qubitId].isMeasured, "Cannot delegate measurement for an already measured Qubit");

        if (validUntil > 0) {
            measurementDelegates[qubitId][delegatee] = MeasurementDelegate(delegatee, validUntil);
            emit MeasurementDelegated(qubitId, delegatee, validUntil);
        } else {
            // Remove delegation if validUntil is 0
            delete measurementDelegates[qubitId][delegatee];
            emit MeasurementDelegateRevoked(qubitId, delegatee);
        }
    }

    /**
     * @dev Revokes a specific measurement delegation. Can be called by owner or the delegatee themselves.
     * @param qubitId The ID of the Qubit.
     * @param delegatee The address whose delegation to revoke.
     */
     function revokeMeasurementDelegate(uint256 qubitId, address delegatee) external qubitExists(qubitId) {
         MeasurementDelegate storage delegateInfo = measurementDelegates[qubitId][delegatee];
         require(delegateInfo.delegatee != address(0), "No active delegation found for this address on this Qubit");
         require(msg.sender == owner() || msg.sender == delegatee, "Only owner or the delegatee can revoke delegation");

         delete measurementDelegates[qubitId][delegatee];
         emit MeasurementDelegateRevoked(qubitId, delegatee);
     }

     /**
      * @dev Checks if an account is a valid delegate for measuring a specific Qubit at the current time.
      * @param qubitId The ID of the Qubit.
      * @param account The address to check.
      * @return True if the account is a valid delegate, false otherwise.
      */
    function isDelegateForMeasurement(uint256 qubitId, address account) external view returns (bool) {
        MeasurementDelegate storage delegateInfo = measurementDelegates[qubitId][account];
        return delegateInfo.delegatee != address(0) && block.timestamp <= delegateInfo.validUntil;
    }


    // --- Advanced/Creative Qubit Interactions ---

    /**
     * @dev Simulates 'Fractal Measurement': Measures a primary Qubit, and then attempts to
     *      trigger measurement for a list of specified 'connected' Qubits that are still in superposition.
     *      These connected Qubits are *not* necessarily entangled but might represent a related system.
     *      The same entropy is (partially) reused for the connected Qubits.
     * @param primaryQubitId The ID of the primary Qubit to measure first.
     * @param connectedQubitIds An array of IDs of Qubits potentially connected.
     * @param userEntropy Additional entropy from the user.
     */
    function fractalMeasure(uint256 primaryQubitId, uint256[] calldata connectedQubitIds, uint256 userEntropy)
        external
        payable // Allow payment for the primary measurement cost
        qubitExists(primaryQubitId)
        qubitIsInSuperposition(primaryQubitId)
        onlyDelegateOrOwner(primaryQubitId) // Only owner or delegate can trigger the primary measurement
    {
        // Measure the primary qubit first (handles cost, delegation, entanglement, etc.)
        // Call the existing measureQubit function logic
        measureQubit(primaryQubitId, userEntropy);
        // Note: The 'payable' keyword needs to be handled by the calling function (`measureQubit`)
        // For simplicity here, we assume the primary `measureQubit` call includes payment logic.

        emit FractalMeasurementTriggered(primaryQubitId, connectedQubitIds);

        // Now attempt to measure the connected qubits IF they are still in superposition
        uint256 baseEntropy = userEntropy + primaryQubitId + qubits[primaryQubitId].measuredValue;

        for (uint i = 0; i < connectedQubitIds.length; i++) {
            uint256 connectedId = connectedQubitIds[i];
            // Ensure the connected qubit exists and is not yet measured
            if (connectedId > 0 && connectedId < nextQubitId && !qubits[connectedId].isMeasured) {
                // Add a small, unique entropy component for each connected qubit
                uint256 connectedEntropy = baseEntropy + connectedId;

                 // Check if the connected qubit has a measurement cost. If so, this function
                 // does NOT automatically pay it. It simply attempts the measurement,
                 // which will revert if payment is required and not sent (which it isn't here).
                 // A more complex version might handle bundled payments. For this example,
                 // connected measurements without cost or delegation are attempted.
                 // We also must ensure the caller or owner *can* measure the connected qubit
                 // if it has delegation/owner checks. Let's simplify and allow this flow
                 // only if the connected qubit has NO delegation requirements or costs.
                 // Or, better, add a check: `if(qubitMeasurementCost[connectedId] == 0 && measurementDelegates[connectedId][address(0)].delegatee == address(0))`

                 // Let's refine: Fractal measurement only triggers 'free' and 'non-delegated' connected qubits.
                 if (qubitMeasurementCost[connectedId] == 0) { // Simplified: Check cost only
                     // If the connected qubit is entangled and its partner is unmeasured, measure the pair
                     if (qubits[connectedId].entangledWithId != 0 && !qubits[qubits[connectedId].entangledWithId].isMeasured) {
                         uint256 partnerId = qubits[connectedId].entangledWithId;
                         (uint256 val1, uint256 val2) = _measureEntangled(connectedId, partnerId, qubits[connectedId].entanglementRule, connectedEntropy);
                         _setMeasuredState(connectedId, val1);
                         _setMeasuredState(partnerId, val2);
                         emit QubitMeasured(connectedId, val1, connectedEntropy);
                         emit QubitMeasured(partnerId, val2, connectedEntropy);
                         emit QubitEntanglementBroken(connectedId);
                         emit QubitEntanglementBroken(partnerId);
                     } else if (qubits[connectedId].dependsOnQubitId == 0) { // Don't measure dependent qubits here
                          // Measure the single connected qubit
                          uint256 randomNum = _getPseudoRandomNumber(1000, connectedEntropy);
                          uint256 measuredVal;
                          if (randomNum < qubits[connectedId].potentialProbabilityApermil) {
                              measuredVal = qubits[connectedId].potentialValueA;
                          } else {
                              measuredVal = qubits[connectedId].potentialValueB;
                          }
                          _setMeasuredState(connectedId, measuredVal);
                          emit QubitMeasured(connectedId, measuredVal, connectedEntropy);
                     } else {
                        // If it's a dependent qubit, check if source is measured and trigger update
                        uint256 sourceId = qubits[connectedId].dependsOnQubitId;
                        if (sourceId > 0 && sourceId < nextQubitId && qubits[sourceId].isMeasured) {
                            _triggerDependentQubitUpdate(connectedId);
                        }
                     }
                 }
            }
        }
    }


    /**
     * @dev Simulates 'Decoherence': Triggers a random measurement for a Qubit that is currently in superposition,
     *      mimicking interaction with the environment causing state collapse.
     *      This function bypasses delegation but honors measurement cost.
     * @param qubitId The ID of the Qubit to simulate decoherence on.
     * @param userEntropy Additional entropy for pseudo-randomness.
     */
    function simulateDecoherence(uint256 qubitId, uint256 userEntropy)
         external
         payable // Allow payment if cost is set
         qubitIsInSuperposition(qubitId)
    {
        // Check and handle measurement cost
         uint256 cost = qubitMeasurementCost[qubitId];
         if (cost > 0) {
             require(msg.value >= cost, "Insufficient payment for decoherence simulation");
             if (msg.value > cost) {
                 (bool success, ) = msg.sender.call{value: msg.value - cost}("");
                 require(success, "Refund failed");
             }
              (bool success, ) = owner().call{value: cost}("");
              require(success, "Cost transfer failed");
         } else {
             require(msg.value == 0, "No Ether expected for this decoherence simulation");
         }

        QuBit storage qubit = qubits[qubitId];
        uint256 measuredVal;

         // If entangled and partner not measured, measure the pair
         if (qubit.entangledWithId != 0) {
             uint256 partnerId = qubit.entangledWithId;
             QuBit storage partner = qubits[partnerId];
             if (!partner.isMeasured) {
                  (uint256 val1, uint256 val2) = _measureEntangled(qubitId, partnerId, qubit.entanglementRule, userEntropy);
                  _setMeasuredState(qubitId, val1);
                  _setMeasuredState(partnerId, val2);
                  measuredVal = val1;
                  emit QubitMeasured(qubitId, measuredVal, userEntropy);
                  emit QubitMeasured(partnerId, val2, userEntropy);
                  emit QubitEntanglementBroken(qubitId);
                  emit QubitEntanglementBroken(partnerId);
             }
         } else if (qubit.dependsOnQubitId == 0) { // Don't simulate decoherence on dependent qubits
              // Measure the single qubit based on its probability
              uint256 randomNum = _getPseudoRandomNumber(1000, userEntropy);
              if (randomNum < qubit.potentialProbabilityApermil) {
                  measuredVal = qubit.potentialValueA;
              } else {
                  measuredVal = qubit.potentialValueB;
              }
              _setMeasuredState(qubitId, measuredVal);
              emit QubitMeasured(qubitId, measuredVal, userEntropy);
         } else {
             // If it's a dependent qubit, check if source is measured and trigger update
             uint256 sourceId = qubit.dependsOnQubitId;
             if (sourceId > 0 && sourceId < nextQubitId && qubits[sourceId].isMeasured) {
                _triggerDependentQubitUpdate(qubitId);
                // The decoherence simulation *on the dependent qubit itself* isn't a measurement
                // but rather triggering its state resolution if possible.
                measuredVal = qubits[qubitId].measuredValue; // Get the newly measured value
             } else {
                 // Decoherence couldn't resolve the dependent qubit's state yet
                 revert("Decoherence simulation failed: Dependent Qubit source not measured or already measured.");
             }
         }


         emit DecoherenceSimulated(qubitId);
     }

    /**
     * @dev Owner sets an optional Ether cost required to measure a specific Qubit.
     *      Setting cost to 0 removes the cost.
     * @param qubitId The ID of the Qubit.
     * @param cost The required Ether amount in wei.
     */
    function setMeasurementCost(uint256 qubitId, uint256 cost) external onlyOwner qubitExists(qubitId) {
        require(!qubits[qubitId].isMeasured, "Cannot set cost for an already measured Qubit");
        qubitMeasurementCost[qubitId] = cost;
        emit MeasurementCostSet(qubitId, cost);
    }

    /**
     * @dev Creates a new Qubit whose measured state will be derived from the measured state of a source Qubit.
     *      The new Qubit starts unmeasured and can only be measured implicitly via its source.
     * @param sourceQubitId The ID of the Qubit this new one depends on.
     * @param rule The DependencyRule to apply to the source's measured value.
     * @return The ID of the newly created dependent Qubit.
     */
    function createDependentQubit(uint256 sourceQubitId, DependencyRule rule) external qubitExists(sourceQubitId) returns (uint256) {
        require(sourceQubitId != 0, "Source Qubit ID cannot be zero");

        uint256 dependentId = nextQubitId;
         qubits[dependentId] = QuBit({
             isMeasured: false,
             measuredValue: 0, // Default before measurement
             potentialValueA: 0, // Potential values irrelevant for dependent qubits
             potentialValueB: 0,
             potentialProbabilityApermil: 0,
             entangledWithId: 0, // Cannot be entangled
             entanglementRule: EntanglementRule.XOR_Correlated, // Irrelevant
             autoMeasureTimestamp: 0, // Cannot be auto-measured directly
             dependsOnQubitId: sourceQubitId,
             dependencyRule: rule
         });
         nextQubitId++;

        emit DependentQubitCreated(dependentId, sourceQubitId, rule);
        return dependentId;
    }

    /**
     * @dev Internal helper to update a dependent Qubit's state based on its source.
     *      Called after the source Qubit is measured, or via triggerAutoMeasurements/simulateDecoherence.
     *      Requires the dependent Qubit to be unmeasured and the source Qubit to be measured.
     * @param dependentQubitId The ID of the dependent Qubit to update.
     */
     function _triggerDependentQubitUpdate(uint256 dependentQubitId) internal qubitExists(dependentQubitId) qubitNotMeasured(dependentQubitId) {
         QuBit storage dependent = qubits[dependentQubitId];
         require(dependent.dependsOnQubitId != 0, "Qubit is not a dependent qubit");

         uint256 sourceId = dependent.dependsOnQubitId;
         require(sourceId > 0 && sourceId < nextQubitId && qubits[sourceId].isMeasured, "Source Qubit not found or not measured");

         uint256 sourceValue = qubits[sourceId].measuredValue;
         uint256 derivedValue;

         // Apply the dependency rule
         if (dependent.dependencyRule == DependencyRule.SourceValue) {
             derivedValue = sourceValue;
         } else if (dependent.dependencyRule == DependencyRule.SourceValuePlus1) {
             derivedValue = sourceValue + 1;
         } else if (dependent.dependencyRule == DependencyRule.SourceValueTimes2) {
              derivedValue = sourceValue * 2;
         } else if (dependent.dependencyRule == DependencyRule.IfSourceZeroThen1Else2) {
              derivedValue = (sourceValue == 0) ? 1 : 2;
         } else {
             // Should not happen if rule is valid enum
             revert("Invalid dependency rule");
         }

         // Set the dependent qubit's measured state
         _setMeasuredState(dependentQubitId, derivedValue);
         emit DependentQubitUpdated(dependentQubitId, derivedValue);
     }

     /**
      * @dev Allows triggering the update for a list of dependent qubits.
      *      Useful after a batch of source qubits might have been measured.
      * @param dependentQubitIds An array of dependent Qubit IDs to check and update.
      */
     function triggerDependentQubitUpdates(uint256[] calldata dependentQubitIds) external {
         for (uint i = 0; i < dependentQubitIds.length; i++) {
              uint256 dependentId = dependentQubitIds[i];
              if (dependentId > 0 && dependentId < nextQubitId && !qubits[dependentId].isMeasured && qubits[dependentId].dependsOnQubitId != 0) {
                  uint256 sourceId = qubits[dependentId].dependsOnQubitId;
                   if (sourceId > 0 && sourceId < nextQubitId && qubits[sourceId].isMeasured) {
                       _triggerDependentQubitUpdate(dependentId);
                   }
              }
         }
     }


    // --- View Functions ---

    /**
     * @dev Gets the current state of a Qubit.
     * @param qubitId The ID of the Qubit.
     * @return isMeasured Whether the Qubit has been measured.
     * @return measuredValue The measured value if `isMeasured` is true.
     * @return potentialValueA Potential value A if not measured.
     * @return potentialValueB Potential value B if not measured.
     * @return potentialProbabilityApermil Probability of A if not measured (out of 1000).
     * @return entangledWithId ID of entangled partner (0 if none).
     * @return autoMeasureTimestamp Auto-measure timestamp (0 if none).
     * @return dependsOnQubitId ID of source qubit if dependent (0 if none).
     * @return dependencyRule Rule if dependent.
     */
    function getQubitState(uint256 qubitId)
        external
        view
        qubitExists(qubitId)
        returns (
            bool isMeasured,
            uint256 measuredValue,
            uint256 potentialValueA,
            uint256 potentialValueB,
            uint64 potentialProbabilityApermil,
            uint256 entangledWithId,
            uint64 autoMeasureTimestamp,
            uint256 dependsOnQubitId,
            DependencyRule dependencyRule
        )
    {
        QuBit storage qubit = qubits[qubitId];
        return (
            qubit.isMeasured,
            qubit.measuredValue,
            qubit.potentialValueA,
            qubit.potentialValueB,
            qubit.potentialProbabilityApermil,
            qubit.entangledWithId,
            qubit.autoMeasureTimestamp,
            qubit.dependsOnQubitId,
            qubit.dependencyRule
        );
    }

    /**
     * @dev Gets the state and entanglement details of two Qubits.
     * @param qubitId1 The ID of the first Qubit.
     * @param qubitId2 The ID of the second Qubit.
     * @return isEntangled True if both are mutually entangled.
     * @return rule The entanglement rule if entangled.
     * @return state1 Qubit 1's state (measured value or potential states).
     * @return state2 Qubit 2's state (measured value or potential states).
     */
    function getEntangledPairState(uint256 qubitId1, uint256 qubitId2)
        external
        view
        qubitExists(qubitId1)
        qubitExists(qubitId2)
        returns (
            bool isEntangled,
            EntanglementRule rule,
            QuBit memory state1,
            QuBit memory state2
        )
    {
        QuBit storage q1 = qubits[qubitId1];
        QuBit storage q2 = qubits[qubitId2];

        bool areMutuallyEntangled = (q1.entangledWithId == qubitId2 && q2.entangledWithId == qubitId1 && !q1.isMeasured && !q2.isMeasured);

        // Return full Qubit structs for detailed state
        return (
            areMutuallyEntangled,
            areMutuallyEntangled ? q1.entanglementRule : EntanglementRule.XOR_Correlated, // Default if not entangled
            q1,
            q2
        );
    }

    /**
     * @dev Gets the potential probability of outcome A for a Qubit in superposition (out of 1000).
     * @param qubitId The ID of the Qubit.
     * @return The probability (0-1000) or 0 if measured.
     */
    function getQubitPotentialProbability(uint256 qubitId) external view qubitExists(qubitId) returns (uint64) {
        return qubits[qubitId].potentialProbabilityApermil;
    }

    /**
     * @dev Gets the details for a dependent Qubit.
     * @param dependentQubitId The ID of the dependent Qubit.
     * @return sourceQubitId The ID of the source Qubit.
     * @return rule The dependency rule.
     * @return isMeasured Whether the dependent Qubit is measured.
     * @return measuredValue The measured value if measured.
     */
    function getDependentQubitDetails(uint256 dependentQubitId)
        external
        view
        qubitExists(dependentQubitId)
        returns (uint256 sourceQubitId, DependencyRule rule, bool isMeasured, uint256 measuredValue)
    {
        QuBit storage dependent = qubits[dependentQubitId];
        require(dependent.dependsOnQubitId != 0, "Qubit is not a dependent qubit");

        return (
            dependent.dependsOnQubitId,
            dependent.dependencyRule,
            dependent.isMeasured,
            dependent.measuredValue
        );
    }

    // Function count check:
    // 1. constructor
    // 2. receive
    // 3. fallback
    // 4. addSupportedToken
    // 5. depositERC20
    // 6. withdrawEther
    // 7. withdrawERC20
    // 8. setVaultAccessCondition
    // 9. getVaultAccessCondition
    // 10. createQubit
    // 11. setPotentialStates
    // 12. applyHadamardGate
    // 13. applyPauliXGate
    // 14. entangleQubits
    // 15. applyCNOTGate
    // 16. measureQubit (includes cost logic)
    // 17. measureEntangledPair (includes cost logic)
    // 18. setAutoMeasureTimestamp
    // 19. triggerAutoMeasurements
    // 20. delegateMeasurement
    // 21. revokeMeasurementDelegate
    // 22. isDelegateForMeasurement
    // 23. fractalMeasure (calls measureQubit internally for primary)
    // 24. simulateDecoherence (includes cost logic)
    // 25. setMeasurementCost
    // 26. getQubitState
    // 27. getEntangledPairState
    // 28. createDependentQubit
    // 29. triggerDependentQubitUpdates (calls internal _triggerDependentQubitUpdate)
    // 30. getDependentQubitDetails

    // That's 30 public/external functions, well over the requested 20.
}
```