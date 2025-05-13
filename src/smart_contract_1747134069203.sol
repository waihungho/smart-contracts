Okay, let's create a smart contract that uses concepts inspired by quantum mechanics metaphors – "Quantum States," "Measurement," and "Entanglement" – to manage values and interactions based on probabilistic-like outcomes derived from on-chain entropy.

This contract, which we'll call `QuantumVault`, will allow creating abstract "quantum states" each associated with a potential value. These states can be "entangled" with each other. A "measurement" process, influenced by on-chain data (simulating observation and state collapse) and potentially other entangled states, determines the final, realized value for a state. This final value can then be claimed.

**Disclaimer:** This contract uses quantum mechanics concepts purely as a metaphor for creating a unique state management and value distribution logic on the blockchain. It does *not* perform actual quantum computation or use quantum cryptographic primitives (which are beyond the EVM's current capabilities). The randomness is pseudo-random based on on-chain data, subject to miner manipulation if used for high-value, time-sensitive outcomes in adversarial conditions.

---

### **Outline & Function Summary**

**Contract Name:** `QuantumVault`

**Concept:** A metaphorical representation of quantum states, measurement, and entanglement on the blockchain to manage and distribute values based on probabilistic-like outcomes derived from on-chain entropy.

**Core Components:**
1.  **QuantumState Struct:** Defines the properties of each state (ID, creator, initial amplitude, associated potential value, observed status, final realized value, entanglement links, etc.).
2.  **State Management:** Functions to create, query, update, and entangle/disentangle states.
3.  **Measurement:** A core function that "collapses" a state, determining its final value based on entropy and entangled partners.
4.  **Value Management:** Functions to deposit funds and claim the realized values after measurement.
5.  **Access Control:** Basic ownership and role management (State Creators, Observers).

---

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `receive()`: Allows receiving Ether deposits.
3.  `addStateCreator(address _creator)`: Grants the State Creator role.
4.  `removeStateCreator(address _creator)`: Revokes the State Creator role.
5.  `isStateCreator(address _account) view`: Checks if an address is a State Creator.
6.  `addObserverRole(address _observer)`: Grants the Observer role (can measure states).
7.  `removeObserverRole(address _observer)`: Revokes the Observer role.
8.  `isObserverRole(address _account) view`: Checks if an address is an Observer.
9.  `transferOwnership(address _newOwner)`: Transfers contract ownership.
10. `renounceOwnership()`: Renounces contract ownership (sets owner to zero address).
11. `createQuantumState(uint256 _initialAmplitude, uint256 _associatedValue, bytes32 _measurementBasisSeed)`: Creates a new quantum state. `_initialAmplitude` influences the *potential* outcome range, `_associatedValue` is the *potential maximum* claimable value, `_measurementBasisSeed` adds external entropy influence.
12. `getQuantumState(uint256 _stateId) view`: Retrieves the details of a specific state.
13. `updateAssociatedValue(uint256 _stateId, uint256 _newValue)`: Updates the potential associated value of an *unmeasured* state (only by creator or owner).
14. `updateAmplitude(uint256 _stateId, uint256 _newAmplitude)`: Updates the initial amplitude of an *unmeasured* state (only by creator or owner).
15. `entangleStates(uint256 _stateId1, uint256 _stateId2)`: Links two *unmeasured* states together such that the measurement of one can influence the other.
16. `disentangleStates(uint256 _stateId1, uint256 _stateId2)`: Removes the entanglement link between two states.
17. `measureState(uint256 _stateId)`: Performs the "measurement" on an *unmeasured* state. Calculates and finalizes its `finalRealizedValue` based on initial parameters, on-chain entropy, and the `finalRealizedValue` of any *already measured* entangled states. Requires Observer role.
18. `batchMeasureStates(uint256[] calldata _stateIds)`: Measures multiple states sequentially. Requires Observer role.
19. `getMeasuredOutcome(uint256 _stateId) view`: Returns the final realized value if the state has been measured.
20. `claimRealizedValue(uint256 _stateId)`: Allows the state's creator to claim the `finalRealizedValue` if the state is measured and not yet claimed. Transfers ETH from the contract's balance.
21. `getPendingValueForClaim(uint256 _stateId) view`: Checks the `finalRealizedValue` and claim status to see how much is available for claiming.
22. `canClaimStateValue(uint256 _stateId) view`: Checks if a state is measured, not claimed, and the caller is the creator or owner.
23. `getTotalStates() view`: Returns the total number of states created.
24. `getEntangledStates(uint256 _stateId) view`: Returns the list of state IDs entangled with a given state.
25. `isStateMeasured(uint256 _stateId) view`: Checks if a state has been measured.
26. `isStateClaimed(uint256 _stateId) view`: Checks if a state's value has been claimed.
27. `getStateCreator(uint256 _stateId) view`: Returns the address of the state's creator.
28. `getStateObserver(uint256 _stateId) view`: Returns the address that measured the state (if measured).
29. `getStateMeasurementTimestamp(uint256 _stateId) view`: Returns the timestamp when the state was measured (if measured).
30. `getInitialStateAmplitude(uint256 _stateId) view`: Returns the initial amplitude of the state.
31. `getInitialAssociatedValue(uint256 _stateId) view`: Returns the initial potential associated value.
32. `withdrawUnauthorizedTokens(address _tokenAddress)`: Allows the owner to withdraw ERC20 tokens accidentally sent to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A smart contract using quantum mechanics concepts as a metaphor for state management,
 *      probabilistic-like outcomes, and value distribution on the blockchain.
 *      States can be created, entangled, and measured. Measurement determines a final,
 *      realized value based on on-chain entropy and entangled states.
 *      Value associated with states can be claimed after measurement.
 *
 * Disclaimer: This is a conceptual contract. The "quantum" behavior is simulated
 * using deterministic (pseudo-random) logic based on on-chain data (blockhash, timestamp, etc.).
 * Such on-chain "randomness" is subject to miner manipulation in adversarial contexts.
 * This contract does not use true quantum computation or quantum-resistant cryptography.
 */

contract QuantumVault {

    // --- Structs ---

    /**
     * @dev Represents a single "quantum state" in the vault.
     *      Uses quantum metaphors: amplitude (potential probability/weight),
     *      observed (measured state collapse), entangledWith (links to other states).
     */
    struct QuantumState {
        uint256 id;
        address creator;             // Address that created this state
        uint256 initialAmplitude;    // Conceptual value influencing measurement outcome range (e.g., potential)
        uint256 initialAssociatedValue; // Potential maximum value associated with this state before measurement
        bool observed;               // True if the state has been "measured" (collapsed)
        uint256 finalRealizedValue;  // The value realized after measurement
        address observer;            // Address that performed the measurement
        uint256 measurementTimestamp; // Timestamp of measurement
        uint256[] entangledWith;     // IDs of other states this one is entangled with
        bytes32 measurementBasisSeed; // An external seed influencing measurement
        bool claimed;                // True if the finalRealizedValue has been claimed
        address claimant;            // Address that claimed the value
    }

    // --- State Variables ---

    address private _owner;
    uint256 private _nextStateId;

    mapping(uint256 => QuantumState) private quantumStates;
    mapping(address => bool) private stateCreators;
    mapping(address => bool) private observers;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event StateCreatorAdded(address indexed account);
    event StateCreatorRemoved(address indexed account);
    event ObserverAdded(address indexed account);
    event ObserverRemoved(address indexed account);
    event StateCreated(uint256 indexed stateId, address indexed creator, uint256 initialAmplitude, uint256 initialAssociatedValue);
    event StatesEntangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event StatesDisentangled(uint256 indexed stateId1, uint256 indexed stateId2);
    event StateMeasured(uint256 indexed stateId, address indexed observer, uint256 finalRealizedValue, uint256 measurementTimestamp);
    event ValueClaimed(uint256 indexed stateId, address indexed claimant, uint256 amount);
    event UnauthorizedTokensWithdrawn(address indexed tokenAddress, address indexed owner, uint256 amount);
    event EtherReceived(address indexed sender, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "QVault: Caller is not the owner");
        _;
    }

    modifier onlyStateCreator() {
        require(stateCreators[msg.sender] || msg.sender == _owner, "QVault: Caller is not a state creator or owner");
        _;
    }

    modifier onlyObserver() {
        require(observers[msg.sender] || msg.sender == _owner, "QVault: Caller is not an observer or owner");
        _;
    }

    modifier stateExists(uint256 _stateId) {
        require(_stateId > 0 && _stateId < _nextStateId, "QVault: State does not exist");
        _;
    }

    modifier stateNotMeasured(uint256 _stateId) {
        require(quantumStates[_stateId].observed == false, "QVault: State has already been measured");
        _;
    }

    modifier stateMeasured(uint256 _stateId) {
        require(quantumStates[_stateId].observed == true, "QVault: State has not been measured");
        _;
    }

    modifier stateNotClaimed(uint256 _stateId) {
        require(quantumStates[_stateId].claimed == false, "QVault: State value has already been claimed");
        _;
    }

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _nextStateId = 1; // Start state IDs from 1
        stateCreators[msg.sender] = true; // Owner is initially a state creator
        observers[msg.sender] = true; // Owner is initially an observer
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // --- Receive Ether ---

    /**
     * @dev Allows the contract to receive Ether. This Ether can be used to fulfill claims.
     */
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    // --- Access Control (Owner) ---

    /**
     * @dev Adds an address to the list of state creators. Only owner can call.
     */
    function addStateCreator(address _creator) external onlyOwner {
        require(_creator != address(0), "QVault: Zero address");
        stateCreators[_creator] = true;
        emit StateCreatorAdded(_creator);
    }

    /**
     * @dev Removes an address from the list of state creators. Only owner can call.
     */
    function removeStateCreator(address _creator) external onlyOwner {
        require(_creator != address(0), "QVault: Zero address");
        stateCreators[_creator] = false;
        emit StateCreatorRemoved(_creator);
    }

    /**
     * @dev Checks if an account is a state creator.
     */
    function isStateCreator(address _account) public view returns (bool) {
        return stateCreators[_account];
    }

    /**
     * @dev Adds an address to the list of observers (can measure states). Only owner can call.
     */
    function addObserverRole(address _observer) external onlyOwner {
        require(_observer != address(0), "QVault: Zero address");
        observers[_observer] = true;
        emit ObserverAdded(_observer);
    }

    /**
     * @dev Removes an address from the list of observers. Only owner can call.
     */
    function removeObserverRole(address _observer) external onlyOwner {
        require(_observer != address(0), "QVault: Zero address");
        observers[_observer] = false;
        emit ObserverRemoved(_observer);
    }

    /**
     * @dev Checks if an account has the observer role.
     */
    function isObserverRole(address _account) public view returns (bool) {
        return observers[_account];
    }

    /**
     * @dev Transfers ownership of the contract to a new address. Only owner can call.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "QVault: New owner is the zero address");
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @dev Renounces ownership of the contract.
     *      Leaves the contract without an owner. Can only be called by the current owner.
     */
    function renounceOwnership() external onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    // --- State Management ---

    /**
     * @dev Creates a new quantum state. Only state creators or owner can call.
     * @param _initialAmplitude Conceptual value influencing the measurement outcome range.
     * @param _associatedValue The potential maximum value associated with this state.
     * @param _measurementBasisSeed An external seed influencing the measurement process.
     * @return stateId The ID of the newly created state.
     */
    function createQuantumState(uint256 _initialAmplitude, uint256 _associatedValue, bytes32 _measurementBasisSeed)
        external
        onlyStateCreator
        returns (uint256 stateId)
    {
        require(_initialAmplitude > 0, "QVault: Initial amplitude must be positive");
        stateId = _nextStateId++;
        quantumStates[stateId] = QuantumState({
            id: stateId,
            creator: msg.sender,
            initialAmplitude: _initialAmplitude,
            initialAssociatedValue: _associatedValue,
            observed: false,
            finalRealizedValue: 0,
            observer: address(0),
            measurementTimestamp: 0,
            entangledWith: new uint256[](0),
            measurementBasisSeed: _measurementBasisSeed,
            claimed: false,
            claimant: address(0)
        });

        emit StateCreated(stateId, msg.sender, _initialAmplitude, _associatedValue);
        return stateId;
    }

    /**
     * @dev Retrieves the details of a specific quantum state.
     * @param _stateId The ID of the state to retrieve.
     * @return state The QuantumState struct.
     */
    function getQuantumState(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (QuantumState memory state)
    {
        return quantumStates[_stateId];
    }

     /**
     * @dev Updates the potential associated value of an unmeasured state. Only state creator or owner can call.
     * @param _stateId The ID of the state to update.
     * @param _newValue The new potential associated value.
     */
    function updateAssociatedValue(uint256 _stateId, uint256 _newValue)
        external
        stateExists(_stateId)
        stateNotMeasured(_stateId)
        onlyStateCreator
    {
        require(quantumStates[_stateId].creator == msg.sender || msg.sender == _owner, "QVault: Only creator or owner can update");
        quantumStates[_stateId].initialAssociatedValue = _newValue;
        // No event emitted for this minor update, could add one if needed.
    }

     /**
     * @dev Updates the initial amplitude of an unmeasured state. Only state creator or owner can call.
     * @param _stateId The ID of the state to update.
     * @param _newAmplitude The new initial amplitude.
     */
    function updateAmplitude(uint256 _stateId, uint256 _newAmplitude)
        external
        stateExists(_stateId)
        stateNotMeasured(_stateId)
        onlyStateCreator
    {
        require(quantumStates[_stateId].creator == msg.sender || msg.sender == _owner, "QVault: Only creator or owner can update");
        require(_newAmplitude > 0, "QVault: New amplitude must be positive");
        quantumStates[_stateId].initialAmplitude = _newAmplitude;
         // No event emitted for this minor update, could add one if needed.
    }


    /**
     * @dev Entangles two unmeasured quantum states.
     *      Measurement of one entangled state can influence the outcome of the other *if measured later*.
     *      Entanglement is stored one-way in this implementation for simplicity.
     * @param _stateId1 The ID of the first state.
     * @param _stateId2 The ID of the second state.
     */
    function entangleStates(uint256 _stateId1, uint256 _stateId2)
        external
        stateExists(_stateId1)
        stateExists(_stateId2)
        stateNotMeasured(_stateId1)
        stateNotMeasured(_stateId2)
        onlyStateCreator // Only state creators/owner can entangle
    {
        require(_stateId1 != _stateId2, "QVault: Cannot entangle a state with itself");

        // Check if caller is creator or owner of *both* states, or owner of contract
        require(
            (quantumStates[_stateId1].creator == msg.sender && quantumStates[_stateId2].creator == msg.sender) || msg.sender == _owner,
            "QVault: Caller must be creator of both states or owner"
        );

        // Add entanglement link from state1 to state2
        bool alreadyEntangled = false;
        for (uint256 i = 0; i < quantumStates[_stateId1].entangledWith.length; i++) {
            if (quantumStates[_stateId1].entangledWith[i] == _stateId2) {
                alreadyEntangled = true;
                break;
            }
        }
        if (!alreadyEntangled) {
            quantumStates[_stateId1].entangledWith.push(_stateId2);
            // Optional: add entanglement link from state2 to state1 for symmetric checks
            // For this example, we'll keep it one-way for calculation simplicity.
            // If symmetric entanglement was needed for the measurement logic, add:
            // quantumStates[_stateId2].entangledWith.push(_stateId1);
            emit StatesEntangled(_stateId1, _stateId2);
        }
    }

    /**
     * @dev Disentangles two quantum states.
     * @param _stateId1 The ID of the first state.
     * @param _stateId2 The ID of the second state.
     */
    function disentangleStates(uint256 _stateId1, uint256 _stateId2)
        external
        stateExists(_stateId1)
        stateExists(_stateId2)
        onlyStateCreator // Only state creators/owner can disentangle
    {
        require(_stateId1 != _stateId2, "QVault: Cannot disentangle a state from itself");
          // Check if caller is creator or owner of *both* states, or owner of contract
        require(
            (quantumStates[_stateId1].creator == msg.sender && quantumStates[_stateId2].creator == msg.sender) || msg.sender == _owner,
            "QVault: Caller must be creator of both states or owner"
        );

        // Remove entanglement link from state1 to state2
        uint256[] storage entangledWith1 = quantumStates[_stateId1].entangledWith;
        for (uint256 i = 0; i < entangledWith1.length; i++) {
            if (entangledWith1[i] == _stateId2) {
                // Swap with last element and pop to remove efficiently
                entangledWith1[i] = entangledWith1[entangledWith1.length - 1];
                entangledWith1.pop();
                emit StatesDisentangled(_stateId1, _stateId2);

                // If symmetric entanglement was stored, remove the reverse link too:
                // uint256[] storage entangledWith2 = quantumStates[_stateId2].entangledWith;
                // for (uint256 j = 0; j < entangledWith2.length; j++) {
                //     if (entangledWith2[j] == _stateId1) {
                //          entangledWith2[j] = entangledWith2[entangledWith2.length - 1];
                //          entangledWith2.pop();
                //          break;
                //     }
                // }

                break; // Assuming no duplicate entanglement entries
            }
        }
    }


    // --- Measurement & Interaction ---

    /**
     * @dev Performs the "measurement" of a quantum state.
     *      This collapses the state and determines its final realized value.
     *      The outcome is influenced by initial parameters, on-chain entropy,
     *      and the realized values of any *already measured* entangled states.
     *      Requires Observer role.
     * @param _stateId The ID of the state to measure.
     */
    function measureState(uint256 _stateId)
        external
        onlyObserver
        stateExists(_stateId)
        stateNotMeasured(_stateId)
    {
        QuantumState storage state = quantumStates[_stateId];

        // --- Conceptual Measurement / PRNG ---
        // Generate base entropy from standard EVM sources and state parameters
        uint256 entropy = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Note: Difficulty is 0 on PoS, use block.prevrandao instead
            block.number,
            tx.origin, // Be cautious with tx.origin in complex access control
            _stateId,
            state.initialAmplitude,
            state.measurementBasisSeed,
            msg.sender // Add observer influence
        )));

        // Incorporate influence from already measured entangled states
        for (uint256 i = 0; i < state.entangledWith.length; i++) {
            uint256 entangledId = state.entangledWith[i];
            // Check if entangled state exists and is measured
            if (entangledId > 0 && entangledId < _nextStateId && quantumStates[entangledId].observed) {
                 // Mix the entangled state's realized value into the entropy calculation
                 entropy = uint256(keccak256(abi.encodePacked(entropy, quantumStates[entangledId].finalRealizedValue)));
            }
        }

        // Determine the final realized value based on entropy, initial amplitude, and initial associated value
        // Example logic: Scale initial associated value by a factor derived from entropy and amplitude.
        // This makes the outcome probabilistic-like, bounded by the initial potential.
        // A simple scaling factor could be (entropy % (amplitude + 1)) / amplitude
        // Let's make it simpler but still influenced: (entropy % (amplitude * 2)) / amplitude * associatedValue
        // Or: Calculate a factor between 0 and 2x based on entropy and amplitude.
        uint256 scalingFactor = (entropy % (state.initialAmplitude * 2 + 1)); // Ranges from 0 to 2*amplitude
        uint256 intermediateValue = (state.initialAssociatedValue * scalingFactor);

        // Ensure final value is within a reasonable range, e.g., 0 to 2x initial potential.
        // Dividing by initialAmplitude creates a factor around 1.
        uint256 finalValue = intermediateValue / state.initialAmplitude;

        // Cap the final value at 2x the initial associated value as an upper bound example
        // Or let the calculation flow. Let's cap it slightly above initial potential.
        // Example: cap at initialAssociatedValue * 1.5 for demonstration
        uint256 maxPossibleValue = (state.initialAssociatedValue * 3) / 2; // 1.5x
        if (finalValue > maxPossibleValue) {
            finalValue = maxPossibleValue;
        }


        // --- State Collapse ---
        state.observed = true;
        state.finalRealizedValue = finalValue;
        state.observer = msg.sender;
        state.measurementTimestamp = block.timestamp;

        emit StateMeasured(_stateId, msg.sender, finalValue, block.timestamp);
    }

     /**
     * @dev Measures multiple states sequentially. Requires Observer role.
     *      If any measurement fails (e.g., state already measured), the transaction will revert.
     *      Consider batching measurements carefully due to gas limits.
     * @param _stateIds An array of state IDs to measure.
     */
    function batchMeasureStates(uint256[] calldata _stateIds) external onlyObserver {
        for (uint256 i = 0; i < _stateIds.length; i++) {
            measureState(_stateIds[i]); // This will revert if any state is already measured or doesn't exist/caller not observer
        }
    }


    /**
     * @dev Gets the final realized value after a state has been measured.
     * @param _stateId The ID of the state.
     * @return finalRealizedValue The determined value.
     */
    function getMeasuredOutcome(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        stateMeasured(_stateId)
        returns (uint256 finalRealizedValue)
    {
        return quantumStates[_stateId].finalRealizedValue;
    }

    /**
     * @dev Allows the creator of a state to claim the final realized value after measurement.
     *      Requires the state to be measured and not yet claimed.
     *      Transfers Ether from the contract's balance.
     * @param _stateId The ID of the state to claim value for.
     */
    function claimRealizedValue(uint256 _stateId)
        external
        stateExists(_stateId)
        stateMeasured(_stateId)
        stateNotClaimed(_stateId)
    {
        QuantumState storage state = quantumStates[_stateId];
        require(msg.sender == state.creator || msg.sender == _owner, "QVault: Only state creator or owner can claim");
        uint256 amountToClaim = state.finalRealizedValue;
        require(amountToClaim > 0, "QVault: Claimable value is zero");
        require(address(this).balance >= amountToClaim, "QVault: Contract has insufficient balance for claim");

        state.claimed = true;
        state.claimant = msg.sender;

        // Transfer Ether
        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "QVault: ETH transfer failed");

        emit ValueClaimed(_stateId, msg.sender, amountToClaim);
    }

    /**
     * @dev Checks the value available for claiming for a state.
     * @param _stateId The ID of the state.
     * @return amount The amount that can be claimed (0 if not measured or already claimed).
     */
    function getPendingValueForClaim(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (uint256 amount)
    {
        QuantumState storage state = quantumStates[_stateId];
        if (state.observed && !state.claimed) {
            return state.finalRealizedValue;
        }
        return 0;
    }

     /**
     * @dev Checks if the current caller can claim the value for a state.
     * @param _stateId The ID of the state.
     * @return bool True if the conditions for claiming are met for msg.sender.
     */
    function canClaimStateValue(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (bool)
    {
        QuantumState storage state = quantumStates[_stateId];
        return state.observed && !state.claimed && (msg.sender == state.creator || msg.sender == _owner) && state.finalRealizedValue > 0 && address(this).balance >= state.finalRealizedValue;
    }


    // --- Asset Management ---

    // receive() is handled above for Ether deposits.

    /**
     * @dev Allows the owner to withdraw ERC20 tokens accidentally sent to the contract.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function withdrawUnauthorizedTokens(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "QVault: No tokens to withdraw");
        require(token.transfer(_owner, balance), "QVault: Token transfer failed");
        emit UnauthorizedTokensWithdrawn(_tokenAddress, _owner, balance);
    }


    // --- Query Functions ---

    /**
     * @dev Returns the total number of quantum states created so far.
     */
    function getTotalStates() external view returns (uint256) {
        return _nextStateId - 1; // Since IDs start at 1
    }

    /**
     * @dev Returns the list of state IDs entangled with a given state.
     * @param _stateId The ID of the state.
     * @return entangledStateIds An array of entangled state IDs.
     */
    function getEntangledStates(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (uint256[] memory)
    {
        return quantumStates[_stateId].entangledWith;
    }

    /**
     * @dev Checks if a state has been measured.
     * @param _stateId The ID of the state.
     * @return bool True if measured, false otherwise.
     */
    function isStateMeasured(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (bool)
    {
        return quantumStates[_stateId].observed;
    }

    /**
     * @dev Checks if a state's value has been claimed.
     * @param _stateId The ID of the state.
     * @return bool True if claimed, false otherwise.
     */
     function isStateClaimed(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (bool)
    {
        return quantumStates[_stateId].claimed;
    }

    /**
     * @dev Returns the creator of a state.
     * @param _stateId The ID of the state.
     * @return creator The address of the creator.
     */
    function getStateCreator(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (address)
    {
        return quantumStates[_stateId].creator;
    }

    /**
     * @dev Returns the observer who measured the state. Address(0) if not measured.
     * @param _stateId The ID of the state.
     * @return observer The address of the observer.
     */
    function getStateObserver(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (address)
    {
        return quantumStates[_stateId].observer;
    }

    /**
     * @dev Returns the timestamp when the state was measured. 0 if not measured.
     * @param _stateId The ID of the state.
     * @return timestamp The measurement timestamp.
     */
     function getStateMeasurementTimestamp(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (uint256)
    {
        return quantumStates[_stateId].measurementTimestamp;
    }

    /**
     * @dev Returns the initial amplitude of a state.
     * @param _stateId The ID of the state.
     * @return amplitude The initial amplitude value.
     */
    function getInitialStateAmplitude(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (uint256)
    {
        return quantumStates[_stateId].initialAmplitude;
    }

     /**
     * @dev Returns the initial associated value of a state.
     * @param _stateId The ID of the state.
     * @return value The initial associated value.
     */
    function getInitialAssociatedValue(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (uint256)
    {
        return quantumStates[_stateId].initialAssociatedValue;
    }


    // --- External Interface for ERC20 (Minimal) ---
    // Required for withdrawUnauthorizedTokens

    interface IERC20 {
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
    }
}
```