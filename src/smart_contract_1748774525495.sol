Okay, let's design a smart contract that plays with concepts inspired by Quantum Mechanics, applied to a secure vault. This allows for creative function naming and state manipulation that isn't just standard token/NFT/DAO logic.

We'll create a "Quantum Vault" where access to certain features or assets depends on the probabilistic "measurement" of simulated "quantum states". These states can be "perturbed", "entangled", and undergo "decoherence" over time.

**Disclaimer:** This contract uses terms from Quantum Mechanics metaphorically. It does *not* perform actual quantum computation (impossible on a classical blockchain) and relies on pseudo-randomness for probabilistic outcomes, which is an inherent limitation on determininstic blockchains. This is purely a creative and conceptual implementation.

---

**Smart Contract: QuantumVault**

**Outline:**

1.  **Metadata:** SPDX License, Pragma.
2.  **Errors:** Custom errors for clarity.
3.  **Structs:** Define `QuantumStateUnit` to hold state data.
4.  **Events:** Log key actions like state creation, perturbation, measurement, entanglement, and withdrawals.
5.  **State Variables:** Store contract owner, admin, state data, user associations, config parameters, and asset balances.
6.  **Modifiers:** `onlyOwner`, `onlyAdmin`, `whenStateExists`.
7.  **Constructor:** Initialize owner, admin, and basic config.
8.  **Access Control:** Functions for owner/admin management.
9.  **Configuration:** Functions to set parameters affecting state behavior (costs, rates).
10. **Quantum State Management:**
    *   Create new state units.
    *   Retrieve state unit details (non-measurement).
    *   Simulate decoherence (time evolution).
    *   Perturb state units (influence parameters).
    *   Entangle/Decouple state units (create/remove correlations).
    *   Perform a probabilistic "measurement" of a state unit.
11. **User State Association:** Link users to specific state units.
12. **Asset Management:**
    *   Deposit ETH and ERC20 tokens.
    *   Withdraw ETH and ERC20 tokens *conditional* on a specific state measurement outcome.
13. **Query Functions:** View state data, balances, user associations.
14. **Internal Helpers:** Logic for randomness, decoherence calculation, measurement simulation, correlation effects.
15. **Receive ETH:** Allow receiving direct ETH transfers.

**Function Summary:**

1.  `constructor()`: Initializes owner, admin, and initial config.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership.
3.  `transferAdmin(address newAdmin)`: Transfers admin role.
4.  `renounceAdmin()`: Renounces the admin role.
5.  `setConfig(uint256 _measurementGasCost, uint256 _decoherenceRate, uint256 _perturbationCost)`: Sets parameters for state interactions.
6.  `createQuantumStateUnit(uint256 initialProbabilityScore, uint256 initialEntropyLevel)`: Creates a new simulated quantum state unit.
7.  `getQuantumStateUnit(uint256 stateId)`: Views the current parameters of a state unit (non-measurement).
8.  `perturbStateUnit(uint256 stateId, bytes32 perturbationData)`: Attempts to influence a state unit's parameters (simulates interaction). Costs ETH/gas.
9.  `measureStateUnit(uint256 stateId)`: Performs a probabilistic 'measurement' of a state, yielding a simulated outcome and altering the state. Costs ETH/gas.
10. `entangleStates(uint256 stateId1, uint256 stateId2)`: Creates a correlation link between two state units.
11. `decoupleStates(uint256 stateId1, uint256 stateId2)`: Removes a correlation link between two state units.
12. `assignStateToUser(address user, uint256 stateId)`: Associates a specific state unit with a user (e.g., for access control).
13. `revokeStateFromUser(address user, uint256 stateId)`: Removes a state unit association from a user.
14. `getUserStateUnits(address user)`: Gets the list of state units associated with a user.
15. `depositAsset(address tokenAddress, uint256 amount)`: Deposits ERC20 tokens into the vault.
16. `withdrawAsset(address tokenAddress, uint256 amount, uint256 requiredStateId, bytes32 expectedMeasurementOutcome)`: Attempts to withdraw assets. Requires a measurement of `requiredStateId` to match `expectedMeasurementOutcome`.
17. `getStateEntropy(uint256 stateId)`: Views the current simulated entropy level of a state.
18. `getStateProbabilityScore(uint256 stateId)`: Views the current simulated probability score of a state.
19. `getCorrelationIds(uint256 stateId)`: Views the list of state units entangled with a given state.
20. `getTokenBalance(address tokenAddress)`: Views the contract's balance of a specific ERC20 token.
21. `getEthBalance()`: Views the contract's ETH balance.
22. `adminOverrideState(uint256 stateId, bytes32 newStateValue, uint256 newProbabilityScore, uint256 newEntropyLevel)`: Admin function to directly set a state unit's parameters (bypasses quantum simulation).
23. `receive() external payable`: Allows receiving direct ETH transfers (treated as deposits of address(0)).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol"; // Using a local interface for ERC20 compatibility

// Minimal ERC20 interface (to avoid duplicating open-source libraries like OpenZeppelin)
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// Custom Errors
error QuantumVault__Unauthorized();
error QuantumVault__StateNotFound(uint256 stateId);
error QuantumVault__InsufficientFunds();
error QuantumVault__StateMeasurementFailed(bytes32 actualOutcome, bytes32 expectedOutcome);
error QuantumVault__InvalidStateID();
error QuantumVault__SelfEntanglementForbidden();
error QuantumVault__AlreadyEntangled();
error QuantumVault__NotEntangled();
error QuantumVault__StateAlreadyAssigned(address user, uint256 stateId);
error QuantumVault__StateNotAssigned(address user, uint256 stateId);
error QuantumVault__ZeroAddress();
error QuantumVault__EthTransferFailed();


contract QuantumVault {

    // --- Structs ---
    struct QuantumStateUnit {
        bytes32 currentStateValue; // A simulated value representing the state outcome
        uint256 probabilityScore;  // Simulated probability towards a specific outcome (e.g., 0-10000 representing 0-100%)
        uint256 entropyLevel;      // Simulated randomness/uncertainty (0-10000)
        uint256[] correlationIds;  // IDs of other states entangled with this one
        uint256 lastUpdateTime;    // Timestamp of the last interaction (perturb, measure, decoherence)
    }

    // --- State Variables ---
    address private _owner;
    address private _admin;

    uint256 private _nextStateUnitId = 1;
    mapping(uint256 => QuantumStateUnit) private _quantumStates;
    mapping(address => uint256[]) private _userStateUnits; // Maps user to state IDs they are associated with

    mapping(address => uint256) private _tokenBalances; // Balances of tokens held by the contract (address(0) for ETH)

    // Configuration parameters affecting quantum simulation costs and rates
    uint256 public measurementGasCost; // Simulated cost required to perform a measurement (in wei/tokens)
    uint256 public decoherenceRate;    // Rate at which states drift towards higher entropy/neutral probability over time
    uint256 public perturbationCost;   // Simulated cost to perturb a state (in wei/tokens)

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event ConfigUpdated(uint256 measurementGasCost, uint256 decoherenceRate, uint256 perturbationCost);
    event QuantumStateCreated(uint256 indexed stateId, uint256 initialProbabilityScore, uint256 initialEntropyLevel);
    event QuantumStatePerturbed(uint256 indexed stateId, address indexed user, bytes32 perturbationData);
    event QuantumStateMeasured(uint256 indexed stateId, address indexed user, bytes32 outcome, uint256 newProbabilityScore, uint256 newEntropyLevel);
    event StatesEntangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event StatesDecoupled(uint256 indexed stateId1, uint al correlation stateId2);
    event StateAssignedToUser(address indexed user, uint256 indexed stateId);
    event StateRevokedFromUser(address indexed user, uint256 indexed stateId);
    event AssetDeposited(address indexed tokenAddress, address indexed user, uint256 amount);
    event AssetWithdrawn(address indexed tokenAddress, address indexed user, uint256 amount, uint256 indexed stateId, bytes32 requiredOutcome, bytes32 actualOutcome);
    event StateOverridden(uint256 indexed stateId, address indexed admin, bytes32 newStateValue, uint256 newProbabilityScore, uint256 newEntropyLevel);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert QuantumVault__Unauthorized();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin && msg.sender != _owner) revert QuantumVault__Unauthorized();
        _;
    }

    modifier whenStateExists(uint256 stateId) {
        if (_quantumStates[stateId].lastUpdateTime == 0) revert QuantumVault__StateNotFound(stateId); // Using lastUpdateTime as existence check (0 is default)
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialMeasurementCost, uint256 initialDecoherenceRate, uint256 initialPerturbationCost) {
        _owner = msg.sender;
        _admin = msg.sender; // Owner is initially also the admin
        measurementGasCost = initialMeasurementCost;
        decoherenceRate = initialDecoherenceRate;
        perturbationCost = initialPerturbationCost;
        emit OwnershipTransferred(address(0), msg.sender);
        emit AdminTransferred(address(0), msg.sender);
        emit ConfigUpdated(measurementGasCost, decoherenceRate, perturbationCost);
    }

    // --- Access Control ---
    /**
     * @notice Transfers ownership of the contract.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert QuantumVault__ZeroAddress();
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Transfers the admin role. Admin has special override capabilities.
     * @param newAdmin The address of the new admin.
     */
    function transferAdmin(address newAdmin) external onlyOwner {
        if (newAdmin == address(0)) revert QuantumVault__ZeroAddress();
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    /**
     * @notice Renounces the admin role.
     */
    function renounceAdmin() external onlyAdmin {
        if (_admin == msg.sender) { // Only allow the current admin (if not owner) to renounce
             _admin = address(0);
             emit AdminTransferred(msg.sender, address(0));
        } else if (_owner == msg.sender && _admin == msg.sender) {
             // Owner is renouncing their admin role
             _admin = address(0);
             emit AdminTransferred(msg.sender, address(0));
        } else {
             revert QuantumVault__Unauthorized(); // Should not happen if logic is correct
        }
    }

    // --- Configuration ---
    /**
     * @notice Sets configuration parameters for state interactions.
     * @param _measurementGasCost Simulated cost for measurement.
     * @param _decoherenceRate Rate of state decay over time.
     * @param _perturbationCost Simulated cost for perturbation.
     */
    function setConfig(uint256 _measurementGasCost, uint256 _decoherenceRate, uint256 _perturbationCost) external onlyAdmin {
        measurementGasCost = _measurementGasCost;
        decoherenceRate = _decoherenceRate;
        perturbationCost = _perturbationCost;
        emit ConfigUpdated(measurementGasCost, decoherenceRate, perturbationCost);
    }

    // --- Quantum State Management ---

    /**
     * @notice Creates a new simulated quantum state unit.
     * @param initialProbabilityScore The starting probability score (0-10000).
     * @param initialEntropyLevel The starting entropy level (0-10000).
     * @return stateId The ID of the newly created state.
     */
    function createQuantumStateUnit(uint256 initialProbabilityScore, uint256 initialEntropyLevel) external onlyAdmin returns (uint256 stateId) {
        uint256 newId = _nextStateUnitId++;
        _quantumStates[newId] = QuantumStateUnit({
            currentStateValue: bytes32(0), // Initial state is undefined/superposition represented by 0
            probabilityScore: initialProbabilityScore,
            entropyLevel: initialEntropyLevel,
            correlationIds: new uint256[](0),
            lastUpdateTime: block.timestamp
        });
        emit QuantumStateCreated(newId, initialProbabilityScore, initialEntropyLevel);
        return newId;
    }

    /**
     * @notice Views the current parameters of a state unit without performing a measurement.
     * Does not alter the state.
     * @param stateId The ID of the state unit.
     * @return stateValue The current simulated state value.
     * @return probabilityScore The current probability score.
     * @return entropyLevel The current entropy level.
     */
    function getQuantumStateUnit(uint256 stateId) external view whenStateExists(stateId) returns (bytes32 stateValue, uint256 probabilityScore, uint256 entropyLevel) {
        QuantumStateUnit storage state = _quantumStates[stateId];
        // Note: This view doesn't apply decoherence automatically
        return (state.currentStateValue, state.probabilityScore, state.entropyLevel);
    }

     /**
      * @notice Applies the effect of decoherence (time evolution) to a state unit.
      * Can be called by anyone. Incentives could be added off-chain.
      * @param stateId The ID of the state unit.
      */
    function applyDecoherence(uint256 stateId) external whenStateExists(stateId) {
        _applyDecoherenceLogic(stateId);
    }

    /**
     * @notice Attempts to influence a state unit's parameters (simulates interaction).
     * Requires paying the perturbation cost.
     * @param stateId The ID of the state unit.
     * @param perturbationData Arbitrary data used to influence the state (e.g., hash of data, user input).
     */
    function perturbStateUnit(uint256 stateId, bytes32 perturbationData) external payable whenStateExists(stateId) {
        if (msg.value < perturbationCost) revert QuantumVault__InsufficientFunds();

        _applyDecoherenceLogic(stateId); // Apply time evolution first

        QuantumStateUnit storage state = _quantumStates[stateId];

        // Simulate perturbation effect based on perturbationData and randomness
        // Example: simple XOR and modulo operations to change state parameters
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, perturbationData, stateId)));

        state.probabilityScore = (state.probabilityScore * 9000 + (uint256(perturbationData) ^ randomFactor) % 2000) / 10000; // Adjust probability
        if (state.probabilityScore > 10000) state.probabilityScore = 10000;

        state.entropyLevel = (state.entropyLevel * 9000 + (uint256(perturbationData) ^ randomFactor) % 2000) / 10000; // Adjust entropy
        if (state.entropyLevel > 10000) state.entropyLevel = 10000;

        state.lastUpdateTime = block.timestamp;

        emit QuantumStatePerturbed(stateId, msg.sender, perturbationData);
    }

    /**
     * @notice Performs a probabilistic 'measurement' of a state unit.
     * Costs ETH/gas. Yields a simulated outcome and significantly alters the state ('collapse').
     * Affects entangled states.
     * @param stateId The ID of the state unit.
     * @return outcome The simulated outcome of the measurement.
     */
    function measureStateUnit(uint256 stateId) external payable whenStateExists(stateId) returns (bytes32 outcome) {
        if (msg.value < measurementGasCost) revert QuantumVault__InsufficientFunds();

        _applyDecoherenceLogic(stateId); // Apply time evolution first

        QuantumStateUnit storage state = _quantumStates[stateId];

        // Simulate measurement outcome
        outcome = _simulateMeasurementOutcome(stateId);

        // Simulate state collapse - state value is now determined by the outcome
        state.currentStateValue = outcome;

        // Simulate dramatic change in probability/entropy after measurement ('collapse')
        // Example: Probability might skew towards the measured outcome, entropy might decrease temporarily
        state.probabilityScore = (state.probabilityScore + uint224(uint256(outcome) % 10000)) / 2; // Example adjustment
        state.entropyLevel = state.entropyLevel / 2; // Example reduction

        state.lastUpdateTime = block.timestamp;

        // Apply effects to entangled states
        _applyCorrelationEffect(stateId, outcome);

        emit QuantumStateMeasured(stateId, msg.sender, outcome, state.probabilityScore, state.entropyLevel);
        return outcome;
    }

    /**
     * @notice Creates a correlation link between two state units (simulates entanglement).
     * @param stateId1 The ID of the first state unit.
     * @param stateId2 The ID of the second state unit.
     */
    function entangleStates(uint256 stateId1, uint256 stateId2) external whenStateExists(stateId1) whenStateExists(stateId2) onlyAdmin {
        if (stateId1 == stateId2) revert QuantumVault__SelfEntanglementForbidden();

        QuantumStateUnit storage state1 = _quantumStates[stateId1];
        QuantumStateUnit storage state2 = _quantumStates[stateId2];

        // Check if already entangled
        bool alreadyEntangled = false;
        for (uint i = 0; i < state1.correlationIds.length; i++) {
            if (state1.correlationIds[i] == stateId2) {
                alreadyEntangled = true;
                break;
            }
        }
        if (alreadyEntangled) revert QuantumVault__AlreadyEntangled();

        state1.correlationIds.push(stateId2);
        state2.correlationIds.push(stateId1); // Entanglement is bidirectional

        // Apply a small correlation effect upon entanglement? (Optional complex logic)
        // For now, just link them.

        emit StatesEntangled(stateId1, stateId2);
    }

    /**
     * @notice Removes a correlation link between two state units (simulates decoupling).
     * @param stateId1 The ID of the first state unit.
     * @param stateId2 The ID of the second state unit.
     */
    function decoupleStates(uint256 stateId1, uint256 stateId2) external whenStateExists(stateId1) whenStateExists(stateId2) onlyAdmin {
        if (stateId1 == stateId2) revert QuantumVault__SelfEntanglementForbidden();

        QuantumStateUnit storage state1 = _quantumStates[stateId1];
        QuantumStateUnit storage state2 = _quantumStates[stateId2];

        // Find and remove stateId2 from state1's correlations
        bool found = false;
        for (uint i = 0; i < state1.correlationIds.length; i++) {
            if (state1.correlationIds[i] == stateId2) {
                state1.correlationIds[i] = state1.correlationIds[state1.correlationIds.length - 1];
                state1.correlationIds.pop();
                found = true;
                break;
            }
        }
        if (!found) revert QuantumVault__NotEntangled(); // stateId2 not found in state1's correlations

        // Find and remove stateId1 from state2's correlations (guaranteed to be there if found above)
        for (uint i = 0; i < state2.correlationIds.length; i++) {
            if (state2.correlationIds[i] == stateId1) {
                state2.correlationIds[i] = state2.correlationIds[state2.correlationIds.length - 1];
                state2.correlationIds.pop();
                break; // Found and removed
            }
        }

        emit StatesDecoupled(stateId1, stateId2);
    }

    // --- User State Association ---
    /**
     * @notice Associates a specific state unit with a user. Can be used for access control or tracking.
     * @param user The address of the user.
     * @param stateId The ID of the state unit to associate.
     */
    function assignStateToUser(address user, uint256 stateId) external whenStateExists(stateId) onlyAdmin {
        if (user == address(0)) revert QuantumVault__ZeroAddress();

        // Check if already assigned
        for (uint i = 0; i < _userStateUnits[user].length; i++) {
            if (_userStateUnits[user][i] == stateId) {
                revert QuantumVault__StateAlreadyAssigned(user, stateId);
            }
        }

        _userStateUnits[user].push(stateId);
        emit StateAssignedToUser(user, stateId);
    }

    /**
     * @notice Removes a state unit association from a user.
     * @param user The address of the user.
     * @param stateId The ID of the state unit to revoke.
     */
    function revokeStateFromUser(address user, uint256 stateId) external whenStateExists(stateId) onlyAdmin {
        if (user == address(0)) revert QuantumVault__ZeroAddress();

        // Find and remove the state ID from the user's list
        bool found = false;
        for (uint i = 0; i < _userStateUnits[user].length; i++) {
            if (_userStateUnits[user][i] == stateId) {
                _userStateUnits[user][i] = _userStateUnits[user][_userStateUnits[user].length - 1];
                _userStateUnits[user].pop();
                found = true;
                break;
            }
        }
        if (!found) revert QuantumVault__StateNotAssigned(user, stateId);

        emit StateRevokedFromUser(user, stateId);
    }

    /**
     * @notice Gets the list of state units associated with a user.
     * @param user The address of the user.
     * @return stateIds An array of state unit IDs.
     */
    function getUserStateUnits(address user) external view returns (uint256[] memory) {
        return _userStateUnits[user];
    }


    // --- Asset Management ---
    /**
     * @notice Allows receiving direct ETH transfers. Treats it as a deposit.
     */
    receive() external payable {
        _tokenBalances[address(0)] += msg.value;
        emit AssetDeposited(address(0), msg.sender, msg.value);
    }

    /**
     * @notice Deposits ERC20 tokens into the vault. Requires prior approval.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositAsset(address tokenAddress, uint256 amount) external {
        if (tokenAddress == address(0)) revert QuantumVault__InvalidStateID(); // Address(0) is reserved for ETH
        if (amount == 0) return;
        IERC20 token = IERC20(tokenAddress);
        // TransferFrom requires the user to have approved the contract to spend their tokens
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert QuantumVault__InsufficientFunds(); // More specifically, could be approval issue or balance issue

        _tokenBalances[tokenAddress] += amount;
        emit AssetDeposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @notice Attempts to withdraw assets (ETH or ERC20).
     * Requires a measurement of `requiredStateId` to match `expectedMeasurementOutcome`.
     * Performs the measurement internally as part of the withdrawal logic.
     * @param tokenAddress The address of the asset (address(0) for ETH).
     * @param amount The amount to withdraw.
     * @param requiredStateId The ID of the state unit that must be measured.
     * @param expectedMeasurementOutcome The specific outcome expected from the measurement.
     */
    function withdrawAsset(address tokenAddress, uint256 amount, uint256 requiredStateId, bytes32 expectedMeasurementOutcome) external payable whenStateExists(requiredStateId) {
         if (amount == 0) return;
         if (_tokenBalances[tokenAddress] < amount) revert QuantumVault__InsufficientFunds();

         // --- Crucial: Perform the measurement here as part of the withdrawal condition ---
         // The sender must pay the measurement cost.
         if (msg.value < measurementGasCost) revert QuantumVault__InsufficientFunds();

         _applyDecoherenceLogic(requiredStateId); // Apply time evolution first

         // Simulate measurement outcome
         bytes32 actualOutcome = _simulateMeasurementOutcome(requiredStateId);

         // Simulate state collapse and apply correlation effects BEFORE checking outcome
         QuantumStateUnit storage state = _quantumStates[requiredStateId];
         state.currentStateValue = actualOutcome;
         state.probabilityScore = (state.probabilityScore + uint224(uint256(actualOutcome) % 10000)) / 2;
         state.entropyLevel = state.entropyLevel / 2;
         state.lastUpdateTime = block.timestamp;
         _applyCorrelationEffect(requiredStateId, actualOutcome);

         emit QuantumStateMeasured(requiredStateId, msg.sender, actualOutcome, state.probabilityScore, state.entropyLevel);
         // --- End Measurement ---

         // Check if the actual outcome matches the expected outcome
         if (actualOutcome != expectedMeasurementOutcome) {
             revert QuantumVault__StateMeasurementFailed(actualOutcome, expectedMeasurementOutcome);
         }

         // If measurement successful, proceed with withdrawal
         _tokenBalances[tokenAddress] -= amount;
         emit AssetWithdrawn(tokenAddress, msg.sender, amount, requiredStateId, expectedMeasurementOutcome, actualOutcome);

         if (tokenAddress == address(0)) {
             (bool success,) = payable(msg.sender).call{value: amount}("");
             if (!success) {
                // If ETH transfer fails, potentially revert or log and handle
                // Reverting is safer to maintain state consistency
                revert QuantumVault__EthTransferFailed();
             }
         } else {
             IERC20 token = IERC20(tokenAddress);
             bool success = token.transfer(msg.sender, amount);
             if (!success) {
                // If token transfer fails, revert
                 revert QuantumVault__InsufficientFunds(); // Or specific error
             }
         }

         // Refund any excess ETH sent for measurementCost
         if (msg.value > measurementGasCost) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - measurementGasCost}("");
             // Ignore result of refund, main transfer is more important
             success; // To avoid unused variable warning
         }
    }


    // --- Query Functions ---

    /**
     * @notice Views the current simulated entropy level of a state. Does not measure.
     * @param stateId The ID of the state unit.
     * @return entropyLevel The current entropy level.
     */
    function getStateEntropy(uint256 stateId) external view whenStateExists(stateId) returns (uint256 entropyLevel) {
        // Note: This view doesn't apply decoherence automatically
        return _quantumStates[stateId].entropyLevel;
    }

    /**
     * @notice Views the current simulated probability score of a state. Does not measure.
     * @param stateId The ID of the state unit.
     * @return probabilityScore The current probability score.
     */
    function getStateProbabilityScore(uint256 stateId) external view whenStateExists(stateId) returns (uint256 probabilityScore) {
         // Note: This view doesn't apply decoherence automatically
        return _quantumStates[stateId].probabilityScore;
    }

    /**
     * @notice Views the list of state units entangled with a given state.
     * @param stateId The ID of the state unit.
     * @return correlationIds An array of entangled state IDs.
     */
    function getCorrelationIds(uint256 stateId) external view whenStateExists(stateId) returns (uint256[] memory) {
        return _quantumStates[stateId].correlationIds;
    }

     /**
      * @notice Get the number of times a specific state unit has been measured.
      * Note: We don't store individual measurement history on-chain due to gas costs.
      * This function is a placeholder for conceptual completeness, practical implementation
      * would involve relying on emitted events.
      * @param stateId The ID of the state unit.
      * @return count The simulated measurement count (not accurately tracked on-chain).
      */
    function getMeasurementCount(uint256 stateId) external view returns (uint256) {
        // Placeholder: Actual measurement count would need off-chain indexing of events.
        // Returning 0 for now as history is not stored.
        stateId; // To avoid unused variable warning
        return 0;
    }


    /**
     * @notice Views the contract's balance of a specific ERC20 token.
     * @param tokenAddress The address of the ERC20 token (address(0) for ETH).
     * @return balance The balance of the token held by the contract.
     */
    function getTokenBalance(address tokenAddress) external view returns (uint256) {
        return _tokenBalances[tokenAddress];
    }

    /**
     * @notice Views the contract's ETH balance.
     * @return balance The ETH balance held by the contract.
     */
    function getEthBalance() external view returns (uint256) {
        return address(this).balance; // This reflects actual ETH balance, _tokenBalances[address(0)] might lag slightly if ETH is transferred outside receive/withdraw
    }

    // --- Admin Override (Non-Quantum Action) ---

    /**
     * @notice Allows the admin to directly set a state unit's parameters, bypassing quantum simulation.
     * Useful for emergency fixes or specific scenarios.
     * @param stateId The ID of the state unit.
     * @param newStateValue The new simulated state value.
     * @param newProbabilityScore The new probability score (0-10000).
     * @param newEntropyLevel The new entropy level (0-10000).
     */
    function adminOverrideState(uint256 stateId, bytes32 newStateValue, uint256 newProbabilityScore, uint256 newEntropyLevel) external onlyAdmin whenStateExists(stateId) {
        QuantumStateUnit storage state = _quantumStates[stateId];
        state.currentStateValue = newStateValue;
        state.probabilityScore = newProbabilityScore;
        state.entropyLevel = newEntropyLevel;
        state.lastUpdateTime = block.timestamp;
        emit StateOverridden(stateId, msg.sender, newStateValue, newProbabilityScore, newEntropyLevel);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to simulate applying decoherence (time evolution).
     * Increases entropy and pushes probability towards a neutral state based on time elapsed.
     * @param stateId The ID of the state unit.
     */
    function _applyDecoherenceLogic(uint256 stateId) internal {
         QuantumStateUnit storage state = _quantumStates[stateId];
         uint256 timeElapsed = block.timestamp - state.lastUpdateTime;

         if (timeElapsed > 0 && decoherenceRate > 0) {
             // Calculate decay based on time elapsed and rate (simplified linear decay towards midpoint)
             uint256 probabilityDecay = (timeElapsed * decoherenceRate) / 1e18; // Scale rate appropriately
             uint256 entropyIncrease = (timeElapsed * decoherenceRate) / 1e18;

             // Probability score drifts towards 5000 (50%)
             if (state.probabilityScore > 5000) {
                 state.probabilityScore = state.probabilityScore > probabilityDecay ? state.probabilityScore - probabilityDecay : 5000;
             } else {
                 state.probabilityScore = state.probabilityScore + probabilityDecay <= 5000 ? state.probabilityScore + probabilityDecay : 5000;
             }

             // Entropy increases towards 10000
             state.entropyLevel = state.entropyLevel + entropyIncrease <= 10000 ? state.entropyLevel + entropyIncrease : 10000;

             // Ensure bounds
             if (state.probabilityScore > 10000) state.probabilityScore = 10000; // Should not happen with this logic but safety
             if (state.entropyLevel > 10000) state.entropyLevel = 10000;
         }
         // state.lastUpdateTime is updated by the calling function (perturb, measure, override)
    }


    /**
     * @dev Internal function to simulate a probabilistic measurement outcome.
     * Outcome is influenced by current probabilityScore and entropyLevel using a pseudo-random seed.
     * @param stateId The ID of the state unit.
     * @return outcome The simulated measured value (bytes32).
     */
    function _simulateMeasurementOutcome(uint256 stateId) internal view returns (bytes32 outcome) {
        QuantumStateUnit storage state = _quantumStates[stateId];

        // Weak on-chain PRNG seed - DO NOT use for high-security applications
        // Combines block data, sender, state info, and current gas left.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            tx.origin,
            gasleft(),
            stateId,
            state.currentStateValue,
            state.probabilityScore,
            state.entropyLevel,
            block.number
        )));

        // Simulate outcome based on probability and randomness
        // Higher entropy means randomness dominates. Higher probability means probabilityScore dominates.
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(seed, "outcome_random")));
        uint256 threshold = (state.probabilityScore * (10000 - state.entropyLevel) + (randomFactor % 10000) * state.entropyLevel) / 10000; // Weighted average

        if (threshold >= 5000) { // Simplified: Outcome tends one way if threshold >= 5000
            outcome = bytes32(uint256(keccak256(abi.encodePacked(seed, "outcome_positive"))));
        } else { // Outcome tends the other way
            outcome = bytes32(uint256(keccak256(abi.encodePacked(seed, "outcome_negative"))));
        }

        // Can refine outcome based on probability/entropy further if needed
        // e.g., lower entropy makes the outcome more "stable" or predictable from the probabilityScore
        // Currently, entropy mainly affects the threshold calculation.

        return outcome;
    }

    /**
     * @dev Internal function to simulate the effect of measuring one state on its entangled states.
     * Propagates some aspects of the measurement outcome to correlated states.
     * @param triggerStateId The ID of the state that was measured.
     * @param outcome The outcome of the measurement.
     */
    function _applyCorrelationEffect(uint256 triggerStateId, bytes32 outcome) internal {
        QuantumStateUnit storage triggerState = _quantumStates[triggerStateId];

        for (uint i = 0; i < triggerState.correlationIds.length; i++) {
            uint256 correlatedStateId = triggerState.correlationIds[i];
            // Check if correlated state exists before accessing
             if (_quantumStates[correlatedStateId].lastUpdateTime != 0) {
                QuantumStateUnit storage correlatedState = _quantumStates[correlatedStateId];

                // Simulate effect: Entangled states' parameters are influenced by the outcome.
                // Example: Probability might shift based on the measured outcome value.
                // Entropy might increase slightly due to the disturbance.
                uint256 outcomeInfluence = uint256(keccak256(abi.encodePacked(outcome, correlatedStateId))) % 1000; // Some derived influence value

                // Adjust probability - could make it more similar or dissimilar based on outcome
                if (uint256(outcome) % 2 == 0) { // Simple rule based on outcome parity
                    correlatedState.probabilityScore = correlatedState.probabilityScore + outcomeInfluence <= 10000 ? correlatedState.probabilityScore + outcomeInfluence : 10000;
                } else {
                    correlatedState.probabilityScore = correlatedState.probabilityScore > outcomeInfluence ? correlatedState.probabilityScore - outcomeInfluence : 0;
                }

                // Increase entropy slightly
                correlatedState.entropyLevel = correlatedState.entropyLevel + (outcomeInfluence / 10) <= 10000 ? correlatedState.entropyLevel + (outcomeInfluence / 10) : 10000;

                correlatedState.lastUpdateTime = block.timestamp; // Update timestamp of correlated state
            }
        }
    }

}

// Add a minimal IERC20.sol file if you don't have one in your project path
/*
// IERC20.sol
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
*/
```