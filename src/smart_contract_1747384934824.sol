Okay, let's design a smart contract with an interesting, advanced, and somewhat conceptual feature: a "Quantum Lock". This contract will manage assets (Ether and ERC20 tokens) and its ultimate state (how the assets can be accessed or what happens to the contract) will be determined by an "observation" event that collapses the contract's "potential states" based on conditions evaluated at the time of observation.

This concept is inspired by quantum mechanics principles (superposition, observation causing wave function collapse) applied metaphorically to contract state and access control. It incorporates ideas of time-sensitive conditions, external data dependencies (via simulated oracles), and complex state transitions, aiming for something less common than standard DeFi or NFT contracts.

We'll ensure we have at least 20 functions by breaking down the setup, state management, observation process, asset handling, and querying into distinct roles and actions.

**Outline and Function Summary:**

1.  **Contract Description:** A Quantum Lock smart contract that holds assets. Its final access state is determined by an 'observation' event, which collapses multiple potential states based on conditions met at that specific moment in time/block.
2.  **Core Concept:** Simulate 'superposition' by defining multiple possible outcome states upfront. Simulate 'observation' via a transaction that evaluates real-world conditions (time, block data, oracle data, internal state) and selects the single winning state. Access control and asset withdrawal depend on this final state.
3.  **Key Features:**
    *   Deposit/Withdraw Ether and ERC20 tokens.
    *   Define multiple `PotentialState` structs (e.g., UnlockForOwner, UnlockForSpecificAddress, PermanentlyLocked, SelfDestruct).
    *   Attach various `Condition` types (time, block, oracle value, internal balance, caller address) to each `PotentialState`.
    *   Set a priority order for `PotentialState` evaluation during observation.
    *   The `observeState` function is the core trigger, evaluating conditions and setting the `finalState`.
    *   Access to assets is gated by the `finalState`.
    *   Observer roles for triggering state collapse.
    *   Fallback state if no conditions are met.
    *   Ability to preview condition evaluation before observation.
    *   Includes time-lock forcing for observation.
4.  **State Variables:** Stores contract state, owner, observation status, final state, potential states, conditions, priority, observer roles, oracle address, etc.
5.  **Structs & Enums:** Define structure for PotentialState, Condition, and types/operators.
6.  **Events:** Signal key actions like StateObserved, Deposit, Withdrawal, StateAdded, ConditionAdded.
7.  **Modifiers:** Control access based on ownership, observer role, and whether observation has occurred.
8.  **Functions (>= 20):**
    *   **Setup & Configuration (Owner/Admin):**
        1.  `constructor`: Initializes owner, default state.
        2.  `addPotentialState`: Defines a new possible outcome state.
        3.  `removePotentialState`: Removes a potential state (only before observation).
        4.  `addStateCondition`: Adds a condition to a specific potential state.
        5.  `removeStateCondition`: Removes a condition from a state (only before observation).
        6.  `setStatePriorityOrder`: Sets the ordered list for state evaluation during observation.
        7.  `setDefaultObservationState`: Sets the fallback state if no conditions match.
        8.  `setOracleAddress`: Configures the oracle contract address.
        9.  `addObserverRole`: Grants permission to call `observeState`.
        10. `removeObserverRole`: Revokes observer permission.
        11. `setObservationGracePeriod`: Sets a delay after which observation can be forced.
    *   **Observation & State Management (Observer/Owner/Forced):**
        12. `observeState`: Triggers the state collapse based on current conditions.
        13. `forceObservation`: Allows anyone to trigger observation after the grace period expires.
        14. `pauseObservationSetup`: Temporarily prevents adding/removing states/conditions.
        15. `resumeObservationSetup`: Allows modifications again.
    *   **Asset Management:**
        16. `depositEther`: Allows depositing Ether into the lock (before observation).
        17. `depositERC20`: Allows depositing ERC20 tokens (before observation).
        18. `withdrawEther`: Allows withdrawal based on the final state.
        19. `withdrawERC20`: Allows ERC20 withdrawal based on the final state.
        20. `transferOwnership`: Standard Ownable function.
    *   **Information & Querying:**
        21. `getFinalState`: Returns the determined final state ID.
        22. `hasBeenObserved`: Checks if the state has collapsed.
        23. `getObservationBlock`: Returns the block number of observation.
        24. `getPotentialStatesCount`: Returns the number of defined potential states.
        25. `getConditionsForState`: Returns the conditions attached to a specific potential state.
        26. `getStatePriority`: Returns the current state priority order.
        27. `getDefaultObservationState`: Returns the current default fallback state ID.
        28. `isObserver`: Checks if an address has the observer role.
        29. `getEtherBalance`: Returns the contract's Ether balance.
        30. `getERC20Balance`: Returns the contract's balance for a specific ERC20 token.
        31. `evaluatePotentialStateConditions`: Allows simulating condition evaluation for a specific state based on current conditions (view function).

This structure provides over 30 functions, meeting the requirement and offering complex interactions around the core quantum lock concept.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// We'll use OpenZeppelin's Ownable for ownership management
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For potential balance checks
import "@openzeppelin/contracts/utils/Address.sol"; // For balance checks

// Using Address.sendValue/call directly is more common in modern Solidity,
// but SafeMath and Address are still good practice references. Let's stick to modern `call`.

// Assuming a simple oracle interface for demonstration
// In a real scenario, this would be a specific Oracle contract like Chainlink
interface ISimpleOracle {
    function getValue(bytes32 key) external view returns (uint256);
    function getAddress(bytes32 key) external view returns (address);
    // Add other data types as needed
}


/// @title QuantumLock
/// @author [Your Name/Alias]
/// @notice A smart contract acting as a lock whose final state is determined by an 'observation' event,
///         collapsing multiple potential outcomes based on real-time conditions.
/// @dev Simulates quantum superposition and observation for asset access control.
///      Offers multiple potential states with attached conditions (time, block, oracle, internal state).
///      Observation collapses to a single deterministic state based on condition evaluation priority.
contract QuantumLock is Ownable {
    using SafeMath for uint256; // Example usage if needed, though direct ops often suffice in 0.8+
    using Address for address;

    // --- State Variables ---

    /// @dev True if the contract's state has been observed and collapsed.
    bool public hasBeenObserved;

    /// @dev The ID of the potential state that was determined as the final state after observation.
    uint256 public finalStateId;

    /// @dev The block number at which the state observation occurred.
    uint256 public observationBlock;

    /// @dev A mapping from potential state ID to its details.
    mapping(uint256 => PotentialState) public potentialStates;

    /// @dev Counter for generating unique potential state IDs.
    uint256 private _stateIdCounter;

    /// @dev A mapping from potential state ID to an array of conditions required for that state to be valid.
    mapping(uint256 => Condition[]) private _stateConditions;

    /// @dev The ordered list of state IDs to check during observation. The first state whose conditions are met wins.
    uint256[] public statePriority;

    /// @dev The ID of the state that is chosen if no potential state's conditions are met during observation.
    uint256 public defaultObservationStateId;

    /// @dev Mapping of addresses with the observer role (can trigger observation).
    mapping(address => bool) public observers;

    /// @dev Address of the oracle contract used for external data conditions.
    ISimpleOracle public oracleAddress;

    /// @dev Timestamp after which observation can be forced by anyone. 0 means no force possible.
    uint256 public observationGracePeriodEnd;

    /// @dev Flag to temporarily pause modification of states and conditions.
    bool public observationSetupPaused;

    // --- Enums ---

    /// @dev Defines the possible types of outcome states.
    enum StateType {
        Invalid,             // 0: Should not be used
        UnlockForOwner,      // 1: Owner can withdraw assets
        UnlockForSpecificAddress, // 2: A predefined address can withdraw assets
        PermanentlyLocked,   // 3: Assets are locked forever
        SelfDestruct         // 4: Contract self-destructs, sending assets to a predefined address (owner in this case)
        // Add more complex states as needed (e.g., UnlockConditional, SplitAssets)
    }

    /// @dev Defines the types of conditions that can be attached to a state.
    enum ConditionType {
        Invalid,              // 0: Should not be used
        TimeBefore,           // 1: block.timestamp < valueUint
        TimeAfter,            // 2: block.timestamp > valueUint
        BlockBefore,          // 3: block.number < valueUint
        BlockAfter,           // 4: block.number > valueUint
        BlockHashBitmask,     // 5: (uint256(block.blockhash(block.number - 1)) & valueUint) == valueUint
        BalanceEthAtLeast,    // 6: address(this).balance >= valueUint
        BalanceERC20AtLeast,  // 7: IERC20(valueAddress).balanceOf(address(this)) >= valueUint (uses valueAddress for token, valueUint for amount)
        OracleValueUint,      // 8: Oracle.getValue(valueBytes32) comparison with valueUint (uses valueBytes32 for key)
        OracleValueAddress,   // 9: Oracle.getAddress(valueBytes32) comparison with valueAddress (uses valueBytes32 for key)
        SenderIs              // 10: msg.sender == valueAddress
        // Add more condition types (e.g., specific function calls, event checks - though difficult)
    }

    /// @dev Defines the comparison operator for conditions that require one.
    enum ComparisonOperator {
        Equal,     // 0: ==
        NotEqual,  // 1: !=
        GreaterThan, // 2: > (for numeric types)
        LessThan,  // 3: < (for numeric types)
        GreaterThanOrEqual, // 4: >= (for numeric types)
        LessThanOrEqual // 5: <= (for numeric types)
    }

    // --- Structs ---

    /// @dev Represents a potential outcome state of the lock.
    struct PotentialState {
        uint256 id;
        StateType stateType;
        address targetAddress; // Used for UnlockForSpecificAddress or SelfDestruct target
        bool exists; // Helper to check if state ID is valid
    }

    /// @dev Represents a condition that must be met for a potential state to be valid during observation.
    struct Condition {
        ConditionType conditionType;
        ComparisonOperator comparisonOperator; // Used for numeric/address comparisons
        uint256 valueUint;
        address valueAddress;
        bytes32 valueBytes32; // Used for oracle keys, block hash bitmasks, etc.
        bool exists; // Helper to check if condition is valid
    }

    // --- Events ---

    /// @dev Emitted when a new potential state is added.
    event PotentialStateAdded(uint256 stateId, StateType stateType, address targetAddress);

    /// @dev Emitted when a potential state is removed.
    event PotentialStateRemoved(uint256 stateId);

    /// @dev Emitted when a condition is added to a state.
    event ConditionAdded(uint256 stateId, uint256 conditionIndex, ConditionType conditionType);

    /// @dev Emitted when a condition is removed from a state.
    event ConditionRemoved(uint256 stateId, uint256 conditionIndex);

    /// @dev Emitted when the state priority order is updated.
    event StatePriorityUpdated(uint256[] newStatePriority);

    /// @dev Emitted when the default fallback state is set.
    event DefaultObservationStateSet(uint256 stateId);

    /// @dev Emitted when the contract's state is observed and collapsed.
    event StateObserved(uint256 finalStateId, StateType finalStateType, uint256 observationBlock);

    /// @dev Emitted when Ether is deposited.
    event EtherDeposited(address indexed depositor, uint256 amount);

    /// @dev Emitted when ERC20 tokens are deposited.
    event ERC20Deposited(address indexed depositor, address indexed tokenAddress, uint256 amount);

    /// @dev Emitted when Ether is withdrawn after observation.
    event EtherWithdrawal(address indexed recipient, uint256 amount, uint256 finalStateId);

    /// @dev Emitted when ERC20 tokens are withdrawn after observation.
    event ERC20Withdrawal(address indexed recipient, address indexed tokenAddress, uint256 amount, uint256 finalStateId);

    /// @dev Emitted when an observer role is granted or revoked.
    event ObserverRoleUpdated(address indexed observer, bool granted);

    /// @dev Emitted when the oracle address is set.
    event OracleAddressSet(address indexed newOracleAddress);

    /// @dev Emitted when the observation setup pause status changes.
    event ObservationSetupPaused(bool paused);

    /// @dev Emitted when the observation grace period ends.
    event ObservationGracePeriodEndSet(uint256 endTime);

    // --- Modifiers ---

    /// @dev Requires that the state has not yet been observed.
    modifier beforeObserved() {
        require(!hasBeenObserved, "QL: State already observed");
        _;
    }

    /// @dev Requires that the state HAS been observed.
    modifier afterObserved() {
        require(hasBeenObserved, "QL: State not yet observed");
        _;
    }

    /// @dev Requires the caller is the owner or has the observer role.
    modifier onlyObserver() {
        require(msg.sender == owner() || observers[msg.sender], "QL: Caller is not owner or observer");
        _;
    }

    /// @dev Requires that observation setup is not currently paused.
    modifier whenObservationSetupNotPaused() {
        require(!observationSetupPaused, "QL: Observation setup is paused");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _defaultObservationStateId) Ownable(msg.sender) {
        // Initialize the contract with a default state that will be chosen if no conditions match.
        // This state must be added separately later.
        defaultObservationStateId = _defaultObservationStateId;
        _stateIdCounter = 0; // State IDs start from 1 or higher
    }

    // --- Setup & Configuration (Owner/Admin) ---

    /// @notice Adds a new potential outcome state to the contract.
    /// @dev Only callable by owner before observation and when setup is not paused.
    /// @param _stateType The type of state (e.g., UnlockForOwner, SelfDestruct).
    /// @param _targetAddress The address associated with the state (e.g., recipient for unlock/self-destruct).
    /// @return stateId The unique ID assigned to the new state.
    function addPotentialState(StateType _stateType, address _targetAddress) external onlyOwner beforeObserved whenObservationSetupNotPaused returns (uint256 stateId) {
        require(_stateType != StateType.Invalid, "QL: Invalid state type");

        stateId = ++_stateIdCounter;
        potentialStates[stateId] = PotentialState({
            id: stateId,
            stateType: _stateType,
            targetAddress: _targetAddress,
            exists: true
        });

        emit PotentialStateAdded(stateId, _stateType, _targetAddress);
        return stateId;
    }

    /// @notice Removes a potential state by its ID.
    /// @dev Only callable by owner before observation and when setup is not paused.
    ///      Removes conditions and potentially updates priority if removed state was present.
    /// @param _stateId The ID of the state to remove.
    function removePotentialState(uint256 _stateId) external onlyOwner beforeObserved whenObservationSetupNotPaused {
        PotentialState storage stateToRemove = potentialStates[_stateId];
        require(stateToRemove.exists, "QL: State ID does not exist");
        require(_stateId != defaultObservationStateId, "QL: Cannot remove default state");

        delete potentialStates[_stateId];
        delete _stateConditions[_stateId];

        // Remove from priority list if present
        uint256 currentLength = statePriority.length;
        for (uint256 i = 0; i < currentLength; i++) {
            if (statePriority[i] == _stateId) {
                // Shift elements left to remove the gap
                for (uint256 j = i; j < currentLength - 1; j++) {
                    statePriority[j] = statePriority[j+1];
                }
                statePriority.pop(); // Remove the last (duplicated) element
                break; // Only expected to find it once
            }
        }

        emit PotentialStateRemoved(_stateId);
    }

    /// @notice Adds a condition to a specific potential state.
    /// @dev Only callable by owner before observation and when setup is not paused.
    /// @param _stateId The ID of the state to add the condition to.
    /// @param _condition The condition details.
    function addStateCondition(uint256 _stateId, Condition calldata _condition) external onlyOwner beforeObserved whenObservationSetupNotPaused {
        require(potentialStates[_stateId].exists, "QL: State ID does not exist");
        require(_condition.conditionType != ConditionType.Invalid, "QL: Invalid condition type");
        // Add more validation for specific condition types if needed

        _stateConditions[_stateId].push(_condition);

        emit ConditionAdded(_stateId, _stateConditions[_stateId].length - 1, _condition.conditionType);
    }

    /// @notice Removes a condition from a specific potential state by index.
    /// @dev Only callable by owner before observation and when setup is not paused.
    /// @param _stateId The ID of the state to remove the condition from.
    /// @param _conditionIndex The index of the condition in the state's conditions array.
    function removeStateCondition(uint256 _stateId, uint256 _conditionIndex) external onlyOwner beforeObserved whenObservationSetupNotPaused {
        require(potentialStates[_stateId].exists, "QL: State ID does not exist");
        require(_conditionIndex < _stateConditions[_stateId].length, "QL: Condition index out of bounds");

        // Replace the condition to remove with the last condition, then pop.
        uint256 lastIndex = _stateConditions[_stateId].length - 1;
        if (_conditionIndex != lastIndex) {
            _stateConditions[_stateId][_conditionIndex] = _stateConditions[_stateId][lastIndex];
        }
        _stateConditions[_stateId].pop();

        emit ConditionRemoved(_stateId, _conditionIndex);
    }

    /// @notice Sets the priority order for evaluating potential states during observation.
    /// @dev Only callable by owner before observation and when setup is not paused.
    ///      Only includes states that exist.
    /// @param _statePriority The ordered array of state IDs.
    function setStatePriorityOrder(uint256[] calldata _statePriority) external onlyOwner beforeObserved whenObservationSetupNotPaused {
        // Optional: Add validation to ensure all IDs in _statePriority exist and are unique
        // This implementation simply replaces the array.
        statePriority = _statePriority;
        emit StatePriorityUpdated(statePriority);
    }

    /// @notice Sets the default state ID to be used if no conditions for any potential state are met during observation.
    /// @dev Only callable by owner before observation and when setup is not paused.
    /// @param _stateId The ID of the default state. Must exist.
    function setDefaultObservationState(uint256 _stateId) external onlyOwner beforeObserved whenObservationSetupNotPaused {
        require(potentialStates[_stateId].exists, "QL: Default state ID does not exist");
        defaultObservationStateId = _stateId;
        emit DefaultObservationStateSet(defaultObservationStateId);
    }

    /// @notice Grants the observer role to an address, allowing them to call `observeState`.
    /// @dev Only callable by owner before observation.
    /// @param _observer The address to grant the role to.
    /// @param _granted True to grant, false to revoke.
    function addObserverRole(address _observer, bool _granted) external onlyOwner beforeObserved {
        observers[_observer] = _granted;
        emit ObserverRoleUpdated(_observer, _granted);
    }

    /// @notice Configures the address of the oracle contract used for Oracle conditions.
    /// @dev Only callable by owner before observation and when setup is not paused.
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(ISimpleOracle _oracleAddress) external onlyOwner beforeObserved whenObservationSetupNotPaused {
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(address(oracleAddress));
    }

    /// @notice Sets the timestamp after which the observation can be forced by anyone.
    /// @dev Only callable by owner before observation and when setup is not paused.
    /// @param _endTime The timestamp when the grace period ends. 0 disables forced observation.
    function setObservationGracePeriodEnd(uint256 _endTime) external onlyOwner beforeObserved whenObservationSetupNotPaused {
         require(_endTime > block.timestamp || _endTime == 0, "QL: End time must be in the future or 0");
         observationGracePeriodEnd = _endTime;
         emit ObservationGracePeriodEndSet(observationGracePeriodEnd);
    }

    /// @notice Temporarily pauses modifications to states, conditions, and priority.
    /// @dev Only callable by owner before observation.
    /// @param _paused True to pause, false to resume.
    function pauseObservationSetup(bool _paused) external onlyOwner beforeObserved {
        observationSetupPaused = _paused;
        emit ObservationSetupPaused(observationSetupPaused);
    }

    // --- Observation & State Management (Observer/Owner/Forced) ---

    /// @notice Triggers the state observation and collapse process.
    /// @dev Callable by owner or any address with the observer role, before observation.
    ///      Evaluates states in priority order and sets the final state.
    function observeState() external onlyObserver beforeObserved {
        _performObservation();
    }

    /// @notice Forces the state observation process if the grace period has ended.
    /// @dev Callable by anyone if `observationGracePeriodEnd` is non-zero and block.timestamp >= `observationGracePeriodEnd`.
    function forceObservation() external beforeObserved {
         require(observationGracePeriodEnd != 0, "QL: Forced observation not enabled");
         require(block.timestamp >= observationGracePeriodEnd, "QL: Grace period has not ended");
        _performObservation();
    }


    /// @dev Internal function to execute the state observation logic.
    function _performObservation() internal beforeObserved {
        uint256 winningStateId = defaultObservationStateId; // Default to fallback state

        // Evaluate states in priority order
        for (uint256 i = 0; i < statePriority.length; i++) {
            uint256 currentStateId = statePriority[i];
            if (potentialStates[currentStateId].exists) {
                if (evaluatePotentialStateConditions(currentStateId)) {
                    winningStateId = currentStateId; // This state's conditions are met, it wins based on priority
                    break; // Stop evaluating, the highest priority winning state is found
                }
            }
        }

        // Set the final state
        hasBeenObserved = true;
        finalStateId = winningStateId;
        observationBlock = block.number;

        PotentialState storage finalState = potentialStates[finalStateId];

        emit StateObserved(finalStateId, finalState.stateType, observationBlock);

        // Execute actions based on the final state if applicable at observation time
        if (finalState.stateType == StateType.SelfDestruct) {
            require(finalState.targetAddress != address(0), "QL: Self-destruct target address not set");
            selfdestruct(payable(finalState.targetAddress)); // Send remaining ETH to target
            // Note: ERC20s won't be sent automatically by selfdestruct.
            // A SelfDestruct state might require manual withdrawal of ERC20s first,
            // or a more complex state type to handle multiple asset types.
            // For this example, selfdestruct only handles ETH.
            // A real implementation might require a pre-withdrawal or a state that forces specific token transfers.
        }
    }

    /// @notice Evaluates whether all conditions for a specific potential state are currently met.
    /// @dev Pure or View function used internally and exposed for preview.
    /// @param _stateId The ID of the state to evaluate.
    /// @return bool True if all conditions for the state are met, false otherwise.
    function evaluatePotentialStateConditions(uint256 _stateId) public view returns (bool) {
        require(potentialStates[_stateId].exists, "QL: State ID does not exist");

        Condition[] storage conditions = _stateConditions[_stateId];
        if (conditions.length == 0 && _stateId != defaultObservationStateId) {
            // A non-default state with no conditions is considered invalid for winning
            // unless it's explicitly designed to win without conditions (e.g., default state).
            // Let's require at least one condition for non-default winning states.
             return false;
        }

        for (uint256 i = 0; i < conditions.length; i++) {
            Condition storage cond = conditions[i];
            bool conditionMet = false;

            // Evaluate the condition based on its type
            if (cond.conditionType == ConditionType.TimeBefore) {
                conditionMet = (block.timestamp < cond.valueUint);
            } else if (cond.conditionType == ConditionType.TimeAfter) {
                 conditionMet = (block.timestamp > cond.valueUint);
            } else if (cond.conditionType == ConditionType.BlockBefore) {
                 conditionMet = (block.number < cond.valueUint);
            } else if (cond.conditionType == ConditionType.BlockAfter) {
                 conditionMet = (block.number > cond.valueUint);
            } else if (cond.conditionType == ConditionType.BlockHashBitmask) {
                 // Cannot use current block hash. Use previous. block.hash(block.number - 1) is reliable.
                 bytes32 prevBlockHash = block.blockhash(block.number > 0 ? block.number - 1 : 0); // Handle block 0
                 conditionMet = (uint256(prevBlockHash) & cond.valueUint) == cond.valueUint;
            } else if (cond.conditionType == ConditionType.BalanceEthAtLeast) {
                 conditionMet = (address(this).balance >= cond.valueUint);
            } else if (cond.conditionType == ConditionType.BalanceERC20AtLeast) {
                 // Requires a valid token address in valueAddress
                 require(cond.valueAddress != address(0), "QL: ERC20 Balance condition requires token address");
                 require(Address.isContract(cond.valueAddress), "QL: ERC20 Balance condition requires contract address");
                 uint256 tokenBalance = IERC20(cond.valueAddress).balanceOf(address(this));
                 conditionMet = (tokenBalance >= cond.valueUint);
            } else if (cond.conditionType == ConditionType.OracleValueUint) {
                // Requires oracle address to be set
                require(address(oracleAddress) != address(0), "QL: Oracle condition requires oracle address");
                 uint256 oracleValue = oracleAddress.getValue(cond.valueBytes32);
                 if (cond.comparisonOperator == ComparisonOperator.Equal) conditionMet = (oracleValue == cond.valueUint);
                 else if (cond.comparisonOperator == ComparisonOperator.NotEqual) conditionMet = (oracleValue != cond.valueUint);
                 else if (cond.comparisonOperator == ComparisonOperator.GreaterThan) conditionMet = (oracleValue > cond.valueUint);
                 else if (cond.comparisonOperator == ComparisonOperator.LessThan) conditionMet = (oracleValue < cond.valueUint);
                 else if (cond.comparisonOperator == ComparisonOperator.GreaterThanOrEqual) conditionMet = (oracleValue >= cond.valueUint);
                 else if (cond.comparisonOperator == ComparisonOperator.LessThanOrEqual) conditionMet = (oracleValue <= cond.valueUint);
                 else revert("QL: Invalid comparison operator for OracleValueUint");
            } else if (cond.conditionType == ConditionType.OracleValueAddress) {
                // Requires oracle address to be set
                 require(address(oracleAddress) != address(0), "QL: Oracle condition requires oracle address");
                 address oracleValue = oracleAddress.getAddress(cond.valueBytes32);
                 if (cond.comparisonOperator == ComparisonOperator.Equal) conditionMet = (oracleValue == cond.valueAddress);
                 else if (cond.comparisonOperator == ComparisonOperator.NotEqual) conditionMet = (oracleValue != cond.valueAddress);
                 else revert("QL: Invalid comparison operator for OracleValueAddress");
            } else if (cond.conditionType == ConditionType.SenderIs) {
                 conditionMet = (msg.sender == cond.valueAddress);
            } else {
                // Unknown or invalid condition type - consider it not met or revert?
                // Revert is safer during observation, but for preview, return false.
                // Let's return false for invalid types.
                 conditionMet = false;
            }

            // If any condition is NOT met, the whole state fails
            if (!conditionMet) {
                return false;
            }
        }

        // If the loop completes, all conditions were met
        return true;
    }

    // --- Asset Management ---

    /// @notice Allows depositing Ether into the contract.
    /// @dev Callable by anyone before observation.
    function depositEther() external payable beforeObserved {
        require(msg.value > 0, "QL: Must deposit non-zero Ether");
        emit EtherDeposited(msg.sender, msg.value);
    }

    /// @notice Allows depositing ERC20 tokens into the contract.
    /// @dev Requires prior approval. Callable by anyone before observation.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _amount The amount of tokens to deposit.
    function depositERC20(address _tokenAddress, uint256 _amount) external beforeObserved {
        require(_tokenAddress != address(0), "QL: Invalid token address");
        require(_amount > 0, "QL: Must deposit non-zero amount");
        require(Address.isContract(_tokenAddress), "QL: Token address is not a contract");

        IERC20 token = IERC20(_tokenAddress);
        // TransferFrom requires the sender to have approved this contract
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "QL: ERC20 transfer failed");

        emit ERC20Deposited(msg.sender, _tokenAddress, _amount);
    }

    /// @notice Allows withdrawal of Ether based on the final state.
    /// @dev Callable only after observation and if the final state allows withdrawal to the caller.
    function withdrawEther() external afterObserved {
        PotentialState storage finalState = potentialStates[finalStateId];
        address payable recipient = payable(address(0));

        if (finalState.stateType == StateType.UnlockForOwner) {
            require(msg.sender == owner(), "QL: Not authorized to withdraw in this state");
            recipient = payable(owner());
        } else if (finalState.stateType == StateType.UnlockForSpecificAddress) {
            require(msg.sender == finalState.targetAddress, "QL: Not authorized to withdraw in this state");
            recipient = payable(finalState.targetAddress);
        } else {
            revert("QL: Final state does not allow Ether withdrawal");
        }

        uint256 balance = address(this).balance;
        require(balance > 0, "QL: No Ether balance to withdraw");

        // Use low-level call for flexibility and reentrancy caution (though not strictly needed here as it's after observation)
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "QL: Ether withdrawal failed");

        emit EtherWithdrawal(recipient, balance, finalStateId);
    }

    /// @notice Allows withdrawal of ERC20 tokens based on the final state.
    /// @dev Callable only after observation and if the final state allows withdrawal to the caller.
    /// @param _tokenAddress The address of the ERC20 token.
    function withdrawERC20(address _tokenAddress) external afterObserved {
        require(_tokenAddress != address(0), "QL: Invalid token address");
        require(Address.isContract(_tokenAddress), "QL: Token address is not a contract");

        PotentialState storage finalState = potentialStates[finalStateId];
        address recipient = address(0);

        if (finalState.stateType == StateType.UnlockForOwner) {
            require(msg.sender == owner(), "QL: Not authorized to withdraw in this state");
            recipient = owner();
        } else if (finalState.stateType == StateType.UnlockForSpecificAddress) {
            require(msg.sender == finalState.targetAddress, "QL: Not authorized to withdraw in this state");
            recipient = finalState.targetAddress;
        } else {
            revert("QL: Final state does not allow ERC20 withdrawal");
        }

        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "QL: No ERC20 balance to withdraw");

        bool success = token.transfer(recipient, balance);
        require(success, "QL: ERC20 withdrawal failed");

        emit ERC20Withdrawal(recipient, _tokenAddress, balance, finalStateId);
    }

    // Override transferOwnership to ensure it can only happen before observation
    function transferOwnership(address newOwner) public override onlyOwner beforeObserved {
        super.transferOwnership(newOwner);
    }


    // --- Information & Querying ---

    /// @notice Returns the ID of the final state after observation.
    /// @dev Returns 0 or the default state ID if not observed yet.
    /// @return finalStateId The ID of the collapsed state.
    function getFinalStateId() external view returns (uint256) {
        return finalStateId;
    }

    /// @notice Checks if the contract's state has been observed.
    /// @return bool True if observed, false otherwise.
    function hasBeenObserved() external view returns (bool) {
        return hasBeenObserved;
    }

    /// @notice Returns the block number at which observation occurred.
    /// @dev Returns 0 if not observed yet.
    /// @return observationBlock The block number.
    function getObservationBlock() external view returns (uint256) {
        return observationBlock;
    }

    /// @notice Returns the number of potential states defined.
    /// @dev This reflects the counter, some states might have been removed.
    /// @return count The current value of the state ID counter.
    function getPotentialStatesCount() external view returns (uint256) {
        return _stateIdCounter;
    }

    /// @notice Returns the conditions attached to a specific potential state.
    /// @dev Use carefully for potentially large arrays.
    /// @param _stateId The ID of the state.
    /// @return conditions An array of Condition structs.
    function getConditionsForState(uint256 _stateId) external view returns (Condition[] memory) {
        require(potentialStates[_stateId].exists, "QL: State ID does not exist");
        return _stateConditions[_stateId];
    }

    /// @notice Returns the current priority order of state evaluation.
    /// @return priority An array of state IDs.
    function getStatePriority() external view returns (uint256[] memory) {
        return statePriority;
    }

     /// @notice Returns the current default fallback state ID.
    /// @return stateId The default state ID.
    function getDefaultObservationStateId() external view returns (uint256) {
        return defaultObservationStateId;
    }

    /// @notice Checks if an address has the observer role.
    /// @param _addr The address to check.
    /// @return bool True if the address is an observer, false otherwise.
    function isObserver(address _addr) external view returns (bool) {
        return observers[_addr];
    }

    /// @notice Returns the current Ether balance held by the contract.
    /// @return balance The Ether balance in wei.
    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the current balance of a specific ERC20 token held by the contract.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @return balance The token balance.
    function getERC20Balance(address _tokenAddress) external view returns (uint256) {
        require(_tokenAddress != address(0), "QL: Invalid token address");
        require(Address.isContract(_tokenAddress), "QL: Token address is not a contract");
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    // Fallback and Receive functions to accept Ether deposits
    receive() external payable {
         if (!hasBeenObserved) {
            emit EtherDeposited(msg.sender, msg.value);
        }
        // Allow receiving Ether even after observation, though depositEther is gated.
        // This is standard practice unless explicitly disallowed.
    }

    fallback() external payable {
         if (!hasBeenObserved) {
            emit EtherDeposited(msg.sender, msg.value);
        }
        // Allow receiving Ether even after observation via fallback.
    }
}
```

**Explanation of Advanced/Creative Concepts and Functions:**

1.  **Quantum Metaphor (Superposition & Observation):** The contract is explicitly designed around the idea of having multiple potential states (`PotentialState` struct, stored in `potentialStates` mapping) simultaneously. These states represent different futures for the contract's assets and access control. The `observeState` function (and `forceObservation`) acts as the 'observer', evaluating conditions at a specific point in time (`observationBlock`, `block.timestamp`) and causing the 'wave function collapse' into a single, deterministic `finalStateId`. This is a creative interpretation of state management.
2.  **Complex Conditional Logic:** The `Condition` struct and `ConditionType` enum allow defining diverse rules for *each* potential state. This goes beyond simple time locks or single boolean checks. Conditions can depend on:
    *   Time and Block Number (`TimeBefore`, `TimeAfter`, `BlockBefore`, `BlockAfter`)
    *   Past Block Data (`BlockHashBitmask` - checking properties of a recent block hash)
    *   Internal Contract State (`BalanceEthAtLeast`, `BalanceERC20AtLeast`)
    *   External Data (via `ISimpleOracle` interface for `OracleValueUint`, `OracleValueAddress`)
    *   Caller Identity (`SenderIs`)
    The `evaluatePotentialStateConditions` function encapsulates the logic for checking these complex, potentially interacting conditions.
3.  **State Priority:** The `statePriority` array introduces a deterministic way to resolve situations where multiple `PotentialState` conditions might be met simultaneously. The contract doesn't fall into an undefined state; it checks the highest priority state first, and if its conditions are met, that's the winner. This adds a layer of designed complexity to the state transition.
4.  **Observer Role & Forced Observation:** Separating the trigger of observation from the owner (`onlyObserver` modifier) allows for decentralized or specific parties to initiate the state collapse. The `forceObservation` function adds a safeguard – if the designated observers/owner fail to trigger observation by a certain time (`observationGracePeriodEnd`), anyone can step in, ensuring the lock doesn't remain perpetually in superposition.
5.  **Preview Function:** `evaluatePotentialStateConditions` is made public (`view`) specifically so that participants (owner, observers, potentially anyone, depending on design) can *preview* which states *would* win based on current conditions *before* the actual `observeState` transaction occurs. This offers transparency and strategic insight into the potential outcome.
6.  **Diverse State Types:** The `StateType` enum defines varied outcomes beyond just simple unlock/lock. `SelfDestruct` is a terminal state, `UnlockForSpecificAddress` allows for third-party beneficiaries, etc. This can be extended for more complex scenarios (e.g., distributing assets proportionally, triggering another contract call).
7.  **Modular Setup:** Functions like `addPotentialState`, `addStateCondition`, `setStatePriorityOrder`, `setOracleAddress`, `addObserverRole` allow the contract's potential behavior to be configured granularly before observation, making it highly customizable for different use cases. The `observationSetupPaused` flag adds a mechanism to freeze this configuration period.

This contract isn't a direct copy of standard libraries or simple examples. Its core mechanism of defining multiple conditional states that collapse upon observation is a novel way to think about timed or event-driven access control and asset management on a blockchain, drawing inspiration from physics to create a unique smart contract pattern.

Remember that deploying and using this contract requires careful consideration of gas costs for complex condition evaluations and the reliability/trust assumptions made about the configured oracle. The self-destruct logic in Solidity only handles Ether; ERC20s would need separate handling within that state type or via a preceding withdrawal.