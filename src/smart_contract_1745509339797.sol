Okay, let's design a smart contract that uses concepts inspired by quantum mechanics (like superposition, entanglement, measurement, and probabilistic outcomes) applied to asset management within the EVM. This is a creative interpretation, as the EVM is classical, but we can model these ideas through state, conditions, and deterministic randomness (with limitations).

We'll create a "Quantum Vault" that holds assets (ETH and ERC-20s) which can only be unlocked under complex, conditionally entangled, and potentially probabilistic circumstances determined by state "measurements" and external "quantum events" reported by a trusted oracle.

**Concept:**

Assets are deposited into "Quantum States". Each state has properties like required external conditions, links to other "entangled" states, and a "probability weight". Funds can only be withdrawn if a "measurement" of the state succeeds. A measurement succeeds only if all required external conditions are met *AND* a probabilistic check passes *AND* (due to "entanglement") none of the linked states that have been "measured" have failed their own measurement. External "Quantum Events" reported by an oracle can influence the probability weights or trigger state changes. Certain actions require specific "Quantum Key Fragments" held by addresses.

This design includes:
*   Managing structured data (states, conditions, links).
*   Interaction with a trusted oracle.
*   Conditional logic based on multiple factors (internal state, external conditions, probabilistic outcome).
*   Simulated probabilistic outcomes using block data (acknowledging real-world limitations for security).
*   Complex state dependencies ("entanglement").
*   Role-based access control using "key fragments".
*   Batch operations.

**Outline:**

1.  **Contract Setup:** Basic ownership, oracle address, entropy source.
2.  **Data Structures:** Struct for QuantumState, mappings for states, links, conditions, key fragments.
3.  **Modifiers:** Access control (`onlyOwner`, `onlyOracle`), state checks.
4.  **Core Logic:**
    *   Creating and configuring Quantum States (deposits, conditions, links).
    *   Managing Quantum Key Fragments.
    *   Oracle interactions (reporting conditions and events).
    *   Attempting State Measurement (the core unlock logic combining conditions, probability, and entanglement).
    *   Claiming Unlocked Funds.
5.  **Query Functions:** Reading state data.
6.  **Emergency/Admin:** Owner functions.

**Function Summary (24 Functions):**

1.  `constructor()`: Deploys the contract, sets owner.
2.  `setOracle(address _oracle)`: Sets the address of the trusted oracle (Owner only).
3.  `setEntropySource(address _entropySource)`: Sets the address used for pseudo-randomness (e.g., Chainlink VRF coordinator, Owner only).
4.  `setEventInfluence(bytes32 _eventTypeHash, int256 _influence)`: Sets how a specific external event type influences measurement probabilities (Owner only).
5.  `createQuantumStateETH(bytes32[] calldata _requiredConditions, uint256 _probabilityWeight, address _unlockRecipient, uint256[] calldata _initialLinkedStates) payable`: Creates a new Quantum State holding ETH.
6.  `createQuantumStateERC20(address _tokenAddress, uint256 _amount, bytes32[] calldata _requiredConditions, uint256 _probabilityWeight, address _unlockRecipient, uint256[] calldata _initialLinkedStates)`: Creates a new Quantum State holding ERC-20 tokens (requires prior approval).
7.  `addConditionsToState(uint256 _stateId, bytes32[] calldata _newConditions)`: Adds more required conditions to an existing state (Depositor or Owner only).
8.  `linkStates(uint256 _stateId1, uint256 _stateId2)`: Creates an entanglement link between two states (Owner or specific Key Fragment required).
9.  `unlinkStates(uint256 _stateId1, uint256 _stateId2)`: Removes an entanglement link (Owner or specific Key Fragment required).
10. `addKeyFragment(address _user, bytes32 _fragment)`: Grants a Quantum Key Fragment to an address (Owner only).
11. `removeKeyFragment(address _user, bytes32 _fragment)`: Revokes a Quantum Key Fragment from an address (Owner only).
12. `reportConditionMet(bytes32 _conditionHash)`: Called by the Oracle to report an external condition is now true.
13. `reportExternalEvent(bytes32 _eventTypeHash, bytes calldata _eventData)`: Called by the Oracle to report a general external event.
14. `attemptStateMeasurement(uint256 _stateId)`: Attempts to "measure" (unlock) a single state. This triggers the core probabilistic and conditional logic.
15. `attemptBatchMeasurement(uint256[] calldata _stateIds)`: Attempts measurement for multiple states.
16. `claimUnlockedFunds(uint256 _stateId)`: Allows the `unlockRecipient` to claim funds if the state has been successfully unlocked.
17. `getStateInfo(uint256 _stateId)`: Retrieves detailed information about a specific state.
18. `getLinkedStates(uint256 _stateId)`: Retrieves the list of states linked to a given state.
19. `getConditionStatus(bytes32 _conditionHash)`: Checks if a specific condition has been reported as met by the oracle.
20. `getUserStates(address _user)`: Retrieves a list of state IDs created by a user (storage complexity, might return limited list or iterator in a real contract).
21. `hasKeyFragment(address _user, bytes32 _fragment)`: Checks if a user possesses a specific key fragment.
22. `ownerEmergencyWithdrawETH(uint256 _amount)`: Allows the owner to withdraw ETH from the *contract's balance* (intended for unlocked funds or recovery, *not* user deposits unless unlocked).
23. `ownerEmergencyWithdrawERC20(address _tokenAddress, uint256 _amount)`: Allows the owner to withdraw ERC20 from the *contract's balance* (intended for unlocked funds or recovery, *not* user deposits unless unlocked).
24. `transferOwnership(address _newOwner)`: Transfers contract ownership.

Let's write the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title QuantumVault
/// @author [Your Name/Alias]
/// @notice A smart contract modeling "quantum" concepts for conditional asset release.
/// Assets (ETH, ERC20) are locked in "Quantum States" with complex unlock conditions
/// based on external oracle reports, simulated probability, and "entanglement" links
/// to other states.
contract QuantumVault is Ownable {

    // --- Function Summary ---
    // 1. constructor()
    // 2. setOracle(address _oracle)
    // 3. setEntropySource(address _entropySource)
    // 4. setEventInfluence(bytes32 _eventTypeHash, int256 _influence)
    // 5. createQuantumStateETH(...)
    // 6. createQuantumStateERC20(...)
    // 7. addConditionsToState(...)
    // 8. linkStates(...)
    // 9. unlinkStates(...)
    // 10. addKeyFragment(...)
    // 11. removeKeyFragment(...)
    // 12. reportConditionMet(...)
    // 13. reportExternalEvent(...)
    // 14. attemptStateMeasurement(...)
    // 15. attemptBatchMeasurement(...)
    // 16. claimUnlockedFunds(...)
    // 17. getStateInfo(...)
    // 18. getLinkedStates(...)
    // 19. getConditionStatus(...)
    // 20. getUserStates(...) // Note: This can be gas-intensive for many states per user
    // 21. hasKeyFragment(...)
    // 22. ownerEmergencyWithdrawETH(...)
    // 23. ownerEmergencyWithdrawERC20(...)
    // 24. transferOwnership(...)

    // --- Data Structures ---

    struct QuantumState {
        address depositor;          // The address that created the state
        address asset;              // Asset address (0x0 for ETH)
        uint256 amount;             // Amount deposited
        bytes32[] requiredConditions; // Hashes of external conditions that must be met
        uint256 probabilityWeight;  // Weight influencing measurement success probability (0-10000)
        address unlockRecipient;    // Address authorized to claim if unlocked
        bool isMeasured;            // Has this state been measured? (Measurement is final)
        bool isUnlocked;            // Was the measurement successful?
        bool isClaimed;             // Has the unlocked amount been claimed?
        uint256 creationTimestamp;  // When the state was created
    }

    uint256 private _stateCounter; // Counter for unique state IDs
    mapping(uint256 => QuantumState) private _quantumStates;
    mapping(uint256 => bool) private _stateExists; // Quick check if ID is valid

    // Entanglement links: stateId => list of linked stateIds
    mapping(uint256 => uint256[]) private _entanglementLinks;

    // Status of external conditions reported by oracle: conditionHash => isMet
    mapping(bytes32 => bool) private _conditionStatus;

    // Influence of external events on probability: eventTypeHash => probability adjustment (basis points)
    mapping(bytes32 => int256) private _eventInfluence;

    // Quantum Key Fragments for access control: user address => list of fragment hashes
    mapping(address => mapping(bytes32 => bool)) private _quantumKeyFragments;

    address public oracleAddress; // Trusted oracle address
    address public entropySource; // Address for pseudo-randomness source

    // --- Constants ---
    bytes32 public constant KEY_FRAGMENT_LINK_MASTER = keccak256("LINK_MASTER"); // Key fragment allows linking/unlinking
    bytes32 public constant KEY_FRAGMENT_FORCED_MEASUREMENT = keccak256("FORCED_MEASUREMENT"); // Key fragment allows forced measurement attempt (bypassing depositor-only)

    // --- Events ---

    event OracleSet(address indexed oracle);
    event EntropySourceSet(address indexed source);
    event EventInfluenceSet(bytes32 indexed eventTypeHash, int256 influence);
    event QuantumStateCreated(uint256 indexed stateId, address indexed depositor, address indexed asset, uint256 amount);
    event ConditionsAdded(uint256 indexed stateId, bytes32[] newConditions);
    event StatesLinked(uint256 indexed stateId1, uint256 indexed stateId2);
    event StatesUnlinked(uint256 indexed stateId1, uint256 indexed stateId2);
    event KeyFragmentAdded(address indexed user, bytes32 indexed fragment);
    event KeyFragmentRemoved(address indexed user, bytes32 indexed fragment);
    event ConditionStatusUpdated(bytes32 indexed conditionHash, bool status);
    event ExternalEventReported(bytes32 indexed eventTypeHash, bytes eventData);
    event StateMeasurementAttempted(uint256 indexed stateId, address indexed caller, bool success);
    event StateUnlocked(uint256 indexed stateId);
    event StateClaimed(uint256 indexed stateId, address indexed recipient, uint256 amount);
    event FundsWithdrawnByOwner(address indexed asset, uint256 amount);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QV: Caller is not the oracle");
        _;
    }

    modifier stateExists(uint256 _stateId) {
        require(_stateExists[_stateId], "QV: State does not exist");
        _;
    }

    modifier stateNotMeasured(uint256 _stateId) {
        require(stateExists(_stateId), "QV: State does not exist");
        require(!_quantumStates[_stateId].isMeasured, "QV: State already measured");
        _;
    }

    modifier stateUnlocked(uint256 _stateId) {
        require(stateExists(_stateId), "QV: State does not exist");
        require(_quantumStates[_stateId].isUnlocked, "QV: State not unlocked");
        _;
    }

    modifier stateNotClaimed(uint256 _stateId) {
        require(stateExists(_stateId), "QV: State does not exist");
        require(!_quantumStates[_stateId].isClaimed, "QV: State already claimed");
        _;
    }

    modifier hasKeyFragment(bytes32 _fragment) {
        require(_quantumKeyFragments[msg.sender][_fragment], "QV: Missing key fragment");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        _stateCounter = 0; // State IDs start from 1
    }

    // --- Owner / Admin Functions ---

    /// @notice Sets the address of the trusted oracle.
    /// @param _oracle The address of the new oracle.
    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "QV: Oracle address cannot be zero");
        oracleAddress = _oracle;
        emit OracleSet(_oracle);
    }

    /// @notice Sets the address of the trusted entropy source (e.g., VRF coordinator).
    /// @param _entropySource The address of the new entropy source.
    function setEntropySource(address _entropySource) external onlyOwner {
         require(_entropySource != address(0), "QV: Entropy source address cannot be zero");
        entropySource = _entropySource;
        emit EntropySourceSet(_entropySource);
    }

    /// @notice Sets the influence of a specific external event type on measurement probabilities.
    /// Influence is in basis points (e.g., 100 = +1%, -50 = -0.5%).
    /// @param _eventTypeHash Hash representing the type of external event.
    /// @param _influence Probability adjustment in basis points (e.g., 100 for +1%).
    function setEventInfluence(bytes32 _eventTypeHash, int256 _influence) external onlyOwner {
        _eventInfluence[_eventTypeHash] = _influence;
        emit EventInfluenceSet(_eventTypeHash, _influence);
    }

    /// @notice Grants a specific Quantum Key Fragment to a user.
    /// Key fragments are used for access control to certain functions.
    /// @param _user The address to grant the key fragment to.
    /// @param _fragment The hash of the key fragment to grant.
    function addKeyFragment(address _user, bytes32 _fragment) external onlyOwner {
        _quantumKeyFragments[_user][_fragment] = true;
        emit KeyFragmentAdded(_user, _fragment);
    }

    /// @notice Revokes a specific Quantum Key Fragment from a user.
    /// @param _user The address to remove the key fragment from.
    /// @param _fragment The hash of the key fragment to remove.
    function removeKeyFragment(address _user, bytes32 _fragment) external onlyOwner {
        _quantumKeyFragments[_user][_fragment] = false;
        emit KeyFragmentRemoved(_user, _fragment);
    }

     /// @notice Allows the owner to withdraw ETH held by the contract.
     /// This should be used cautiously, ideally only for unlocked funds
     /// or in emergency recovery scenarios.
     /// @param _amount The amount of ETH to withdraw.
    function ownerEmergencyWithdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "QV: Insufficient contract balance");
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "QV: ETH withdrawal failed");
        emit FundsWithdrawnByOwner(address(0), _amount);
    }

    /// @notice Allows the owner to withdraw ERC20 tokens held by the contract.
    /// Use cautiously, ideally only for unlocked funds or recovery.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _amount The amount of tokens to withdraw.
    function ownerEmergencyWithdrawERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "QV: Insufficient contract token balance");
        token.transfer(owner(), _amount);
        emit FundsWithdrawnByOwner(_tokenAddress, _amount);
    }


    // --- State Creation / Configuration ---

    /// @notice Creates a new Quantum State holding Ether.
    /// Requires sending ETH with the transaction.
    /// @param _requiredConditions Hashes of external conditions needed for unlock.
    /// @param _probabilityWeight Weight for probabilistic unlock check (0-10000, represents basis points).
    /// @param _unlockRecipient The address authorized to claim if unlocked.
    /// @param _initialLinkedStates Initial states to entangle with.
    /// @return stateId The ID of the newly created state.
    function createQuantumStateETH(
        bytes32[] calldata _requiredConditions,
        uint256 _probabilityWeight,
        address _unlockRecipient,
        uint256[] calldata _initialLinkedStates
    ) external payable returns (uint256 stateId) {
        require(msg.value > 0, "QV: Deposit amount must be greater than zero");
        require(_probabilityWeight <= 10000, "QV: Probability weight cannot exceed 10000");

        stateId = ++_stateCounter;
        _stateExists[stateId] = true;

        QuantumState storage newState = _quantumStates[stateId];
        newState.depositor = msg.sender;
        newState.asset = address(0); // ETH
        newState.amount = msg.value;
        newState.requiredConditions = _requiredConditions;
        newState.probabilityWeight = _probabilityWeight;
        newState.unlockRecipient = _unlockRecipient;
        newState.creationTimestamp = block.timestamp;

        // Initialize entanglement links
        for (uint i = 0; i < _initialLinkedStates.length; i++) {
            if (_stateExists[_initialLinkedStates[i]]) {
                 // Avoid linking a state to itself and avoid duplicate links
                 bool alreadyLinked = false;
                 for(uint j=0; j<_entanglementLinks[stateId].length; j++) {
                     if (_entanglementLinks[stateId][j] == _initialLinkedStates[i]) {
                         alreadyLinked = true;
                         break;
                     }
                 }
                 if (_initialLinkedStates[i] != stateId && !alreadyLinked) {
                     _entanglementLinks[stateId].push(_initialLinkedStates[i]);
                     _entanglementLinks[_initialLinkedStates[i]].push(stateId); // Bidirectional link
                 }
            }
        }

        emit QuantumStateCreated(stateId, msg.sender, address(0), msg.value);
        return stateId;
    }

    /// @notice Creates a new Quantum State holding ERC-20 tokens.
    /// Requires the contract to have sufficient allowance beforehand (`IERC20(tokenAddress).approve(address(this), amount)`).
    /// @param _tokenAddress The address of the ERC-20 token.
    /// @param _amount The amount of tokens to deposit.
    /// @param _requiredConditions Hashes of external conditions needed for unlock.
    /// @param _probabilityWeight Weight for probabilistic unlock check (0-10000).
    /// @param _unlockRecipient The address authorized to claim if unlocked.
    /// @param _initialLinkedStates Initial states to entangle with.
    /// @return stateId The ID of the newly created state.
    function createQuantumStateERC20(
        address _tokenAddress,
        uint256 _amount,
        bytes32[] calldata _requiredConditions,
        uint256 _probabilityWeight,
        address _unlockRecipient,
        uint256[] calldata _initialLinkedStates
    ) external returns (uint256 stateId) {
        require(_amount > 0, "QV: Deposit amount must be greater than zero");
        require(_tokenAddress != address(0), "QV: Token address cannot be zero");
        require(_probabilityWeight <= 10000, "QV: Probability weight cannot exceed 10000");

        IERC20 token = IERC20(_tokenAddress);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "QV: ERC20 allowance too low");

        stateId = ++_stateCounter;
        _stateExists[stateId] = true;

        QuantumState storage newState = _quantumStates[stateId];
        newState.depositor = msg.sender;
        newState.asset = _tokenAddress;
        newState.amount = _amount;
        newState.requiredConditions = _requiredConditions;
        newState.probabilityWeight = _probabilityWeight;
        newState.unlockRecipient = _unlockRecipient;
        newState.creationTimestamp = block.timestamp;

        // Initialize entanglement links
        for (uint i = 0; i < _initialLinkedStates.length; i++) {
            if (_stateExists[_initialLinkedStates[i]]) {
                 bool alreadyLinked = false;
                 for(uint j=0; j<_entanglementLinks[stateId].length; j++) {
                     if (_entanglementLinks[stateId][j] == _initialLinkedStates[i]) {
                         alreadyLinked = true;
                         break;
                     }
                 }
                 if (_initialLinkedStates[i] != stateId && !alreadyLinked) {
                    _entanglementLinks[stateId].push(_initialLinkedStates[i]);
                    _entanglementLinks[_initialLinkedLinks[i]].push(stateId); // Bidirectional link
                 }
            }
        }

        // Transfer tokens
        token.transferFrom(msg.sender, address(this), _amount);

        emit QuantumStateCreated(stateId, msg.sender, _tokenAddress, _amount);
        return stateId;
    }

    /// @notice Adds additional required conditions to an existing state.
    /// Can only be called by the state's depositor or the owner.
    /// @param _stateId The ID of the state to modify.
    /// @param _newConditions The hashes of conditions to add.
    function addConditionsToState(uint256 _stateId, bytes32[] calldata _newConditions)
        external
        stateExists(_stateId)
    {
        require(msg.sender == _quantumStates[_stateId].depositor || msg.sender == owner(), "QV: Not authorized to add conditions");
        QuantumState storage state = _quantumStates[_stateId];
        for (uint i = 0; i < _newConditions.length; i++) {
             // Avoid duplicates
             bool exists = false;
             for(uint j=0; j<state.requiredConditions.length; j++) {
                 if (state.requiredConditions[j] == _newConditions[i]) {
                     exists = true;
                     break;
                 }
             }
             if (!exists) {
                 state.requiredConditions.push(_newConditions[i]);
             }
        }
        emit ConditionsAdded(_stateId, _newConditions);
    }

    /// @notice Creates a bidirectional entanglement link between two states.
    /// Requires the `KEY_FRAGMENT_LINK_MASTER` or ownership.
    /// Linking measured states is allowed but has no effect on their measurement outcome.
    /// @param _stateId1 The ID of the first state.
    /// @param _stateId2 The ID of the second state.
    function linkStates(uint256 _stateId1, uint256 _stateId2)
        external
        stateExists(_stateId1)
        stateExists(_stateId2)
        hasKeyFragment(KEY_FRAGMENT_LINK_MASTER) // Custom key fragment required
    {
        require(_stateId1 != _stateId2, "QV: Cannot link a state to itself");

        // Add link state1 -> state2 if not exists
        bool link1Exists = false;
        for(uint i=0; i<_entanglementLinks[_stateId1].length; i++) {
            if (_entanglementLinks[_stateId1][i] == _stateId2) {
                link1Exists = true;
                break;
            }
        }
        if (!link1Exists) {
            _entanglementLinks[_stateId1].push(_stateId2);
        }

        // Add link state2 -> state1 if not exists
        bool link2Exists = false;
        for(uint i=0; i<_entanglementLinks[_stateId2].length; i++) {
            if (_entanglementLinks[_stateId2][i] == _stateId1) {
                link2Exists = true;
                break;
            }
        }
        if (!link2Exists) {
             _entanglementLinks[_stateId2].push(_stateId1);
        }

        if (!link1Exists || !link2Exists) {
            emit StatesLinked(_stateId1, _stateId2);
        }
    }

    /// @notice Removes a bidirectional entanglement link between two states.
    /// Requires the `KEY_FRAGMENT_LINK_MASTER` or ownership.
    /// @param _stateId1 The ID of the first state.
    /// @param _stateId2 The ID of the second state.
    function unlinkStates(uint256 _stateId1, uint256 _stateId2)
        external
        stateExists(_stateId1)
        stateExists(_stateId2)
        hasKeyFragment(KEY_FRAGMENT_LINK_MASTER) // Custom key fragment required
    {
        require(_stateId1 != _stateId2, "QV: Cannot unlink a state from itself");

        // Remove state2 from state1's links
        uint256[] storage links1 = _entanglementLinks[_stateId1];
        for (uint i = 0; i < links1.length; i++) {
            if (links1[i] == _stateId2) {
                links1[i] = links1[links1.length - 1]; // Swap with last element
                links1.pop(); // Remove last element
                break; // Assuming no duplicate links
            }
        }

        // Remove state1 from state2's links
        uint256[] storage links2 = _entanglementLinks[_stateId2];
        for (uint i = 0; i < links2.length; i++) {
            if (links2[i] == _stateId1) {
                links2[i] = links2[links2.length - 1]; // Swap with last element
                links2.pop(); // Remove last element
                break; // Assuming no duplicate links
            }
        }

        emit StatesUnlinked(_stateId1, _stateId2);
    }

    // --- Oracle Interactions ---

    /// @notice Called by the trusted oracle to report that a specific external condition has been met.
    /// This updates the contract's internal state about the condition.
    /// @param _conditionHash The hash of the condition that is now met.
    function reportConditionMet(bytes32 _conditionHash) external onlyOracle {
        require(_conditionHash != bytes32(0), "QV: Condition hash cannot be zero");
        _conditionStatus[_conditionHash] = true;
        emit ConditionStatusUpdated(_conditionHash, true);
    }

     /// @notice Called by the trusted oracle to report a general external event.
     /// This can influence future state measurements via setEventInfluence.
     /// @param _eventTypeHash Hash representing the type of external event.
     /// @param _eventData Optional arbitrary data related to the event.
    function reportExternalEvent(bytes32 _eventTypeHash, bytes calldata _eventData) external onlyOracle {
         emit ExternalEventReported(_eventTypeHash, _eventData);
         // The effect of this event is indirect, handled when attempting measurement
         // by looking up _eventInfluence[_eventTypeHash]
    }


    // --- Core Logic: Measurement ---

    /// @notice Attempts to "measure" the state of a specific Quantum State.
    /// Measurement is a final operation. Once attempted, the state's outcome (Unlocked/Locked) is determined.
    /// Unlock conditions:
    /// 1. State must not have been measured before.
    /// 2. Caller must be the depositor or have the `KEY_FRAGMENT_FORCED_MEASUREMENT`.
    /// 3. ALL `requiredConditions` must have been reported as met by the oracle.
    /// 4. The probabilistic check must pass (based on probabilityWeight and recent blockhash).
    /// 5. (Entanglement) NONE of the states entangled with this state that have *already* been measured can have failed their measurement.
    /// @param _stateId The ID of the state to measure.
    function attemptStateMeasurement(uint256 _stateId)
        external
        stateNotMeasured(_stateId) // Implies stateExists
    {
        QuantumState storage state = _quantumStates[_stateId];

        // Condition 2: Caller Authorization
        bool isDepositor = (msg.sender == state.depositor);
        bool canForce = _quantumKeyFragments[msg.sender][KEY_FRAGMENT_FORCED_MEASUREMENT];
        require(isDepositor || canForce, "QV: Not authorized to measure this state");

        // Condition 3: Required Conditions Check
        bool allConditionsMet = true;
        for (uint i = 0; i < state.requiredConditions.length; i++) {
            if (!_conditionStatus[state.requiredConditions[i]]) {
                allConditionsMet = false;
                break;
            }
        }
        if (!allConditionsMet) {
            state.isMeasured = true; // Measurement failed due to conditions
            state.isUnlocked = false;
            emit StateMeasurementAttempted(_stateId, msg.sender, false);
            return; // Measurement failed
        }

        // Condition 5: Entanglement Check (Negative Entanglement: failure propagates)
        bool entanglementAllowsUnlock = true;
        uint256[] storage linkedStates = _entanglementLinks[_stateId];
        for (uint i = 0; i < linkedStates.length; i++) {
            uint256 linkedStateId = linkedStates[i];
            // Check if the linked state exists and has been measured
            if (_stateExists[linkedStateId] && _quantumStates[linkedStateId].isMeasured) {
                // If a *measured* linked state failed its measurement, this state's measurement fails
                if (!_quantumStates[linkedStateId].isUnlocked) {
                    entanglementAllowsUnlock = false;
                    break; // No need to check further linked states
                }
            }
        }
        if (!entanglementAllowsUnlock) {
            state.isMeasured = true; // Measurement failed due to entanglement
            state.isUnlocked = false;
             emit StateMeasurementAttempted(_stateId, msg.sender, false);
            return; // Measurement failed
        }

        // Condition 4: Probabilistic Check (Simulated)
        // Note: blockhash is deprecated and unreliable past 256 blocks.
        // Using it here for conceptual demonstration. A real system needs a VRF oracle.
        bytes32 entropySeed = blockhash(block.number - 1); // Use a recent blockhash
        if (entropySource != address(0)) {
            // If a specific entropy source is set, combine its address (as hash) for better dispersion
            entropySeed = keccak256(abi.encodePacked(entropySeed, entropySource, _stateId, block.timestamp));
        } else {
             // If no source, use stateId and timestamp with blockhash
             entropySeed = keccak256(abi.encodePacked(entropySeed, _stateId, block.timestamp));
        }


        // Calculate probability based on base weight and event influences
        uint256 finalProbabilityWeight = state.probabilityWeight; // Basis points (0-10000)
        // This part is simplified; a real system might track recent events and their influence
        // For demonstration, we'll just check a single event influence keyed by blockhash - 2
        // This isn't robust, but shows the concept of external influence
        bytes32 pastEventHash = keccak256(abi.encodePacked("PastEventInfluence", block.number - 2)); // Dummy event hash based on block number
        if (_eventInfluence[pastEventHash] != 0) {
             int256 influence = _eventInfluence[pastEventHash];
             // Apply influence while preventing overflow/underflow and staying within 0-10000
             int256 adjustedWeight = int256(finalProbabilityWeight) + influence;
             if (adjustedWeight < 0) adjustedWeight = 0;
             if (adjustedWeight > 10000) adjustedWeight = 10000;
             finalProbabilityWeight = uint256(adjustedWeight);
        }


        uint256 randomNumber = uint256(entropySeed) % 10001; // Number between 0 and 10000

        bool probabilisticCheckPassed = (randomNumber <= finalProbabilityWeight);


        // Final Determination
        state.isMeasured = true;
        state.isUnlocked = probabilisticCheckPassed; // If conditions and entanglement allowed, probability decides

        emit StateMeasurementAttempted(_stateId, msg.sender, probabilisticCheckPassed);

        if (state.isUnlocked) {
            emit StateUnlocked(_stateId);
        }
    }

    /// @notice Attempts to measure multiple states in a batch.
    /// Iterates through the provided list and calls `attemptStateMeasurement` for each.
    /// Note: If one measurement fails or reverts, the entire batch transaction will likely revert
    /// unless handled with try/catch (complex in Solidity < 0.9).
    /// @param _stateIds Array of state IDs to attempt measurement for.
    function attemptBatchMeasurement(uint256[] calldata _stateIds) external {
        for (uint i = 0; i < _stateIds.length; i++) {
            // Internal call to attemptStateMeasurement.
            // Note: Reverts in the loop will stop the whole batch.
            // Use low-level call with success check or try/catch in production for robustness.
            attemptStateMeasurement(_stateIds[i]);
        }
    }

    // --- Claiming ---

    /// @notice Allows the designated unlock recipient to claim funds from a state that has been successfully measured and unlocked.
    /// @param _stateId The ID of the state to claim from.
    function claimUnlockedFunds(uint256 _stateId)
        external
        stateUnlocked(_stateId) // Implies stateExists
        stateNotClaimed(_stateId)
    {
        QuantumState storage state = _quantumStates[_stateId];
        require(msg.sender == state.unlockRecipient, "QV: Not the unlock recipient");

        state.isClaimed = true;
        uint256 amountToTransfer = state.amount;
        address assetAddress = state.asset;
        address recipient = state.unlockRecipient;

        if (assetAddress == address(0)) {
            // ETH Transfer
            (bool success, ) = payable(recipient).call{value: amountToTransfer}("");
            require(success, "QV: ETH transfer failed");
        } else {
            // ERC20 Transfer
            IERC20 token = IERC20(assetAddress);
            token.transfer(recipient, amountToTransfer);
        }

        emit StateClaimed(_stateId, recipient, amountToTransfer);
    }

    // --- Query Functions ---

    /// @notice Retrieves information about a specific Quantum State.
    /// @param _stateId The ID of the state to query.
    /// @return stateDetails A tuple containing all relevant details of the state.
    function getStateInfo(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (
            address depositor,
            address asset,
            uint256 amount,
            bytes32[] memory requiredConditions,
            uint256 probabilityWeight,
            address unlockRecipient,
            bool isMeasured,
            bool isUnlocked,
            bool isClaimed,
            uint256 creationTimestamp
        )
    {
        QuantumState storage state = _quantumStates[_stateId];
        return (
            state.depositor,
            state.asset,
            state.amount,
            state.requiredConditions,
            state.probabilityWeight,
            state.unlockRecipient,
            state.isMeasured,
            state.isUnlocked,
            state.isClaimed,
            state.creationTimestamp
        );
    }

    /// @notice Retrieves the IDs of states entangled with a given state.
    /// @param _stateId The ID of the state to query.
    /// @return linkedStateIds An array of state IDs linked to the queried state.
    function getLinkedStates(uint256 _stateId)
        external
        view
        stateExists(_stateId)
        returns (uint256[] memory)
    {
        return _entanglementLinks[_stateId];
    }

    /// @notice Checks the status of a specific external condition.
    /// @param _conditionHash The hash of the condition to check.
    /// @return isMet True if the condition has been reported as met by the oracle, false otherwise.
    function getConditionStatus(bytes32 _conditionHash) external view returns (bool isMet) {
        return _conditionStatus[_conditionHash];
    }

    /// @notice Retrieves a list of state IDs created by a specific user.
    /// WARNING: This function can be very gas-intensive or impossible if a user creates many states.
    /// In a production contract, consider a more scalable approach (e.g., off-chain indexing, paginated view).
    /// For this example, it iterates through all state IDs created up to the current counter.
    /// @param _user The address of the user to query.
    /// @return stateIds An array of state IDs created by the user.
    function getUserStates(address _user) external view returns (uint256[] memory) {
        uint256[] memory userStates = new uint256[](0); // Dynamic array
        uint256 currentCounter = _stateCounter; // Read state variable once

        // Iterate from state ID 1 up to the current counter
        for (uint256 i = 1; i <= currentCounter; i++) {
            // Check if the state exists and was created by the user
            // _stateExists check is important if IDs could be deleted or skipped in future versions
            if (_stateExists[i] && _quantumStates[i].depositor == _user) {
                 // Append the state ID to the dynamic array
                 uint256 currentLength = userStates.length;
                 uint256[] memory temp = new uint256[](currentLength + 1);
                 for(uint j=0; j<currentLength; j++) {
                     temp[j] = userStates[j];
                 }
                 temp[currentLength] = i;
                 userStates = temp; // Assign the new, larger array
            }
        }
        return userStates;
    }


    /// @notice Checks if a user possesses a specific Quantum Key Fragment.
    /// @param _user The address to check.
    /// @param _fragment The hash of the key fragment to check for.
    /// @return hasFragment True if the user has the key fragment, false otherwise.
    function hasKeyFragment(address _user, bytes32 _fragment) external view returns (bool hasFragment) {
        return _quantumKeyFragments[_user][_fragment];
    }

    // --- Fallback/Receive ---

    receive() external payable {
        // Optional: Handle plain ETH deposits if they don't correspond to a state creation
        // For this contract, direct ETH receive without creating a state might be unexpected.
        // Can either revert, or log, or hold as general contract balance (risky for user funds).
        // Let's revert to enforce using createQuantumStateETH.
        revert("QV: Direct ETH receive is not allowed, use createQuantumStateETH");
    }
}
```