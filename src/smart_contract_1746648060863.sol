Okay, let's create a smart contract concept around a "Quantum State Lock" or "QuantumLock". The idea is inspired by quantum superposition and measurement – a lock that exists in an indeterminate state until a specific "measurement" or "observation" collapses it into one of several possible final states, each granting different permissions or releasing different assets. The outcome of the collapse will be determined by an unpredictable external factor, like Chainlink VRF randomness.

This concept allows for complex, multi-outcome conditional logic and access control not typically found in simple time-locks or multi-sigs.

**Outline and Function Summary:**

*   **Contract Name:** `QuantumLock`
*   **Core Concept:** A smart contract representing a lock with a state that is initially `Indeterminate`. A `triggerMeasurement` function initiates a process (using Chainlink VRF) that results in a random outcome. The `fulfillRandomWords` callback acts as the "measurement," collapsing the `Indeterminate` state into one of several predefined `Collapsed` states based on the random value. Each `Collapsed` state can be configured to grant specific permissions or release different types/amounts of assets.
*   **Inheritances:** `Ownable` (for basic administrative control), `VRFConsumerBaseV2` (for Chainlink VRF).
*   **State Variables:**
    *   `owner`: Contract administrator.
    *   `currentState`: Enum tracking `Indeterminate` or `Collapsed`.
    *   `collapsedStateId`: The ID of the state the lock collapsed into (if collapsed).
    *   `possibleCollapsedStates`: Mapping storing configurations for each potential collapsed state (permissions, token release data).
    *   `stateIdCounter`: Counter for unique state IDs.
    *   `measurementRequestStatus`: Mapping tracking VRF request IDs and their resulting collapsed state ID.
    *   VRF-related variables (`s_keyHash`, `s_subscriptionId`, `s_callbackGasLimit`, `s_numWords`).
    *   Mapping to track balances of ERC20 tokens held for specific potential states.
    *   `s_pendingRequests`: Set/mapping to track requests waiting for fulfillment.
*   **Structs:**
    *   `CollapsedStateData`: Configuration for a possible outcome state (description, arbitrary permissions map).
    *   `ERC20ReleaseData`: Data for releasing ERC20 tokens upon collapse (token address, amount).
*   **Events:**
    *   `StateAdded`: When a possible collapsed state is defined.
    *   `StateRemoved`: When a possible collapsed state is removed.
    *   `MeasurementTriggered`: When a VRF request is sent.
    *   `StateCollapsed`: When the state transitions from Indeterminate to Collapsed.
    *   `PermissionGranted`: When a permission is set for a state.
    *   `ERC20DepositedForState`: When ERC20 is deposited for a state outcome.
    *   `ERC20ClaimedFromState`: When ERC20 is claimed after collapse.
    *   `MeasurementRequestCancelled`: When a pending request is logically cancelled.
*   **Modifiers:**
    *   `whenStateIs(State expectedState)`: Restrict function to a specific state.
    *   `whenStateIsNot(State forbiddenState)`: Restrict function from a specific state.
    *   `onlyCollapsedState()`: Alias for `whenStateIs(State.Collapsed)`.
    *   `onlyIndeterminateState()`: Alias for `whenStateIs(State.Indeterminate)`.
*   **Functions (>= 20):**
    1.  `constructor()`: Initializes the contract, sets owner, VRF parameters.
    2.  `getCurrentState()`: Returns the current state (`Indeterminate` or `Collapsed`).
    3.  `getCollapsedStateId()`: Returns the ID of the collapsed state if the state is `Collapsed`.
    4.  `addPossibleCollapsedState(string description)`: Defines a new potential collapsed state and returns its unique ID. Only allowed when `Indeterminate`.
    5.  `removePossibleCollapsedState(uint256 stateId)`: Removes a previously defined potential state. Only allowed when `Indeterminate`.
    6.  `getPossibleStateData(uint256 stateId)`: Retrieves the configuration data for a potential collapsed state.
    7.  `grantPermissionToState(uint256 stateId, string permissionKey, bool value)`: Sets or revokes a specific boolean permission for a *potential* collapsed state. Only allowed when `Indeterminate`.
    8.  `getStatePermission(uint256 stateId, string permissionKey)`: Checks the status of a specific permission for a *potential* collapsed state.
    9.  `hasPermissionInCurrentState(string permissionKey)`: Checks if the *current* collapsed state grants a specific permission. Only callable when `Collapsed`.
    10. `depositERC20ForCollapseState(uint256 stateId, address tokenAddress, uint256 amount)`: Allows users to deposit ERC20 tokens that are designated for release if the state collapses to `stateId`. Requires approval beforehand. Only allowed when `Indeterminate`.
    11. `getERC20DepositedForState(uint256 stateId, address tokenAddress)`: Checks the amount of a specific ERC20 token deposited for a potential state.
    12. `triggerMeasurement(uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords)`: Initiates the state collapse process by requesting randomness from Chainlink VRF. Only allowed when `Indeterminate`.
    13. `fulfillRandomWords(uint256 requestId, uint256[] randomWords)`: VRF callback function. Processes the random result, determines the collapsed state, updates the state variables, and potentially queues token releases. Transitions state from `Indeterminate` to `Collapsed`.
    14. `getMeasurementOutcomeId(uint256 requestId)`: Gets the collapsed state ID determined by a specific VRF request.
    15. `isMeasurementRequestFulfilled(uint256 requestId)`: Checks if a specific VRF request has been fulfilled.
    16. `getPendingMeasurementRequests()`: Returns a list of request IDs currently awaiting VRF fulfillment.
    17. `cancelPendingMeasurementRequest(uint256 requestId)`: Allows cancellation of a VRF request *if* it hasn't been fulfilled yet, preventing it from collapsing the state. (Logical cancellation within contract state).
    18. `claimERC20FromCollapsedState(address tokenAddress)`: Allows a user to claim their allocated ERC20 tokens *if* the state has collapsed and the collapsed state configuration specifies release for the caller. Only callable when `Collapsed`.
    19. `executePermissionedAction(string permissionKey)`: An example function demonstrating how permissions in the collapsed state can gate functionality. Requires `hasPermissionInCurrentState(permissionKey)`.
    20. `addERC20ReleaseToState(uint256 stateId, address tokenAddress, uint256 amount)`: Configures that a certain amount of a token *should* be released to the *caller* of `claimERC20FromCollapsedState` if the state collapses to `stateId`. This is configuration, not deposit. Only allowed when `Indeterminate`.
    21. `getERC20ReleaseConfigForState(uint256 stateId, address tokenAddress)`: Gets the configured release amount for a potential state and token.
    22. `withdrawERC20Owner(address tokenAddress, uint256 amount)`: Emergency owner withdrawal of any token held by the contract (e.g., mistakenly sent or leftover).
    23. `transferOwnership(address newOwner)`: Standard Ownable function.
    24. `renounceOwnership()`: Standard Ownable function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/vrf/V2/VRFConsumerBaseV2.sol";

// Outline:
// Contract Name: QuantumLock
// Core Concept: A state lock contract where the state is initially Indeterminate (superposition analogue)
// and transitions to one of multiple possible Collapsed states based on Chainlink VRF randomness (measurement analogue).
// Different Collapsed states grant different permissions and trigger different ERC20 token releases.
// Inheritances: Ownable, VRFConsumerBaseV2
// State Variables: owner, currentState, collapsedStateId, possibleCollapsedStates, stateIdCounter,
// measurementRequestStatus, VRF params, erc20DepositsForState, s_pendingRequests
// Structs: CollapsedStateData, ERC20ReleaseConfig
// Events: StateAdded, StateRemoved, MeasurementTriggered, StateCollapsed, PermissionGranted,
// ERC20DepositedForState, ERC20ClaimedFromState, MeasurementRequestCancelled
// Modifiers: whenStateIs, whenStateIsNot, onlyCollapsedState, onlyIndeterminateState
// Functions: (See summary below)

// Function Summary:
// 1.  constructor(): Initializes contract with owner, VRF details.
// 2.  getCurrentState(): Returns the current state (Indeterminate/Collapsed).
// 3.  getCollapsedStateId(): Gets the ID of the final state if collapsed.
// 4.  addPossibleCollapsedState(string description): Defines a new potential outcome state.
// 5.  removePossibleCollapsedState(uint256 stateId): Removes a potential outcome state (if not collapsed).
// 6.  getPossibleStateData(uint256 stateId): Retrieves config for a potential state.
// 7.  grantPermissionToState(uint256 stateId, string permissionKey, bool value): Sets a boolean permission for a potential state.
// 8.  getStatePermission(uint256 stateId, string permissionKey): Checks a permission for a potential state.
// 9.  hasPermissionInCurrentState(string permissionKey): Checks permission in the actual collapsed state.
// 10. depositERC20ForCollapseState(uint256 stateId, address tokenAddress, uint256 amount): Deposit tokens allocated for a specific outcome state.
// 11. getERC20DepositedForState(uint256 stateId, address tokenAddress): Checks deposited amount for a state.
// 12. triggerMeasurement(uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords): Requests VRF randomness to collapse state.
// 13. fulfillRandomWords(uint256 requestId, uint256[] randomWords): VRF callback; performs the state collapse based on randomness.
// 14. getMeasurementOutcomeId(uint256 requestId): Gets the collapsed state ID resulting from a VRF request.
// 15. isMeasurementRequestFulfilled(uint256 requestId): Checks if a VRF request was processed.
// 16. getPendingMeasurementRequests(): Lists VRF requests awaiting fulfillment.
// 17. cancelPendingMeasurementRequest(uint256 requestId): Logically cancels a pending request within the contract.
// 18. claimERC20FromCollapsedState(address tokenAddress): Claims tokens allocated to the caller in the collapsed state.
// 19. executePermissionedAction(string permissionKey): Example of a function gated by collapsed state permission.
// 20. addERC20ReleaseToState(uint256 stateId, address tokenAddress, uint256 amount): Configures token release amount for a state (not deposit).
// 21. getERC20ReleaseConfigForState(uint256 stateId, address tokenAddress): Gets configured token release amount for a state.
// 22. withdrawERC20Owner(address tokenAddress, uint256 amount): Owner emergency withdrawal of tokens.
// 23. transferOwnership(address newOwner): Transfers contract ownership.
// 24. renounceOwnership(): Renounces contract ownership.

contract QuantumLock is Ownable, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    enum State { Indeterminate, Collapsed }

    State public currentState;
    uint256 public collapsedStateId; // The ID of the state the lock collapsed into

    struct CollapsedStateData {
        string description;
        // Arbitrary permissions granted in this collapsed state
        mapping(string => bool) permissions;
        // Configured token amounts to be released to the *caller* of claimERC20FromCollapsedState
        mapping(address => uint256) erc20ReleaseConfig;
        bool exists; // Flag to check if the state ID is valid
    }

    // Mapping from state ID to its configuration
    mapping(uint256 => CollapsedStateData) private possibleCollapsedStates;
    uint256 private stateIdCounter = 1; // Start from 1, 0 could be invalid state

    // Mapping to track VRF request ID to the collapsed state ID it resulted in
    mapping(uint256 => uint256) private measurementRequestStatus; // 0 means not fulfilled or cancelled, >0 is the state ID

    // Chainlink VRF Variables
    bytes32 private s_keyHash;
    uint64 private s_subscriptionId;
    uint32 private s_callbackGasLimit;
    uint32 private s_numWords;

    // To track pending requests
    mapping(uint256 => bool) private s_pendingRequests; // request ID => true if pending

    // Mapping to track ERC20 balances held BY THE CONTRACT earmarked for specific states
    // stateId => tokenAddress => amount
    mapping(uint256 => mapping(address => uint256)) private erc20DepositsForState;

    // Events
    event StateAdded(uint256 indexed stateId, string description);
    event StateRemoved(uint256 indexed stateId);
    event MeasurementTriggered(uint256 indexed requestId, address indexed trigger);
    event StateCollapsed(uint256 indexed collapsedStateId, uint256 indexed requestId);
    event PermissionGranted(uint256 indexed stateId, string permissionKey, bool value);
    event ERC20DepositedForState(uint256 indexed stateId, address indexed tokenAddress, uint256 amount, address indexed depositor);
    event ERC20ClaimedFromState(uint256 indexed collapsedStateId, address indexed tokenAddress, uint256 amount, address indexed receiver);
    event MeasurementRequestCancelled(uint256 indexed requestId);

    // Modifiers
    modifier whenStateIs(State expectedState) {
        require(currentState == expectedState, "QuantumLock: Incorrect state");
        _;
    }

    modifier whenStateIsNot(State forbiddenState) {
        require(currentState != forbiddenState, "QuantumLock: Forbidden state");
        _;
    }

    modifier onlyCollapsedState() {
        whenStateIs(State.Collapsed) _;
    }

    modifier onlyIndeterminateState() {
        whenStateIs(State.Indeterminate) _;
    }

    modifier onlyExistingState(uint256 stateId) {
        require(possibleCollapsedStates[stateId].exists, "QuantumLock: State ID does not exist");
        _;
    }

    /// @notice Initializes the QuantumLock contract.
    /// @param vrfCoordinator The address of the VRF Coordinator contract.
    /// @param keyHash The key hash for VRF requests.
    /// @param subscriptionId The VRF subscription ID the contract will use.
    /// @param callbackGasLimit The maximum gas the callback `fulfillRandomWords` is allowed to consume.
    /// @param numWords The number of random words to request (should be 1 for picking one state).
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint32 numWords
    ) VRFConsumerBaseV2(vrfCoordinator) Ownable(msg.sender) {
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
        s_numWords = numWords; // Typically 1 for selecting one outcome
        currentState = State.Indeterminate;
        collapsedStateId = 0; // 0 indicates not collapsed
    }

    /// @notice Returns the current state of the QuantumLock.
    /// @return The current state (Indeterminate or Collapsed).
    function getCurrentState() public view returns (State) {
        return currentState;
    }

    /// @notice Returns the ID of the collapsed state if the lock has collapsed.
    /// @return The collapsed state ID, or 0 if still Indeterminate.
    function getCollapsedStateId() public view returns (uint256) {
        return collapsedStateId;
    }

    /// @notice Defines a new potential collapsed state. Only callable when the lock is Indeterminate.
    /// @param description A description for the state (e.g., "Unlocks Treasure", "Grants Admin").
    /// @return The unique ID assigned to the new state.
    function addPossibleCollapsedState(string calldata description)
        public
        onlyOwner
        onlyIndeterminateState
        returns (uint256)
    {
        uint256 newStateId = stateIdCounter++;
        possibleCollapsedStates[newStateId].description = description;
        possibleCollapsedStates[newStateId].exists = true;
        emit StateAdded(newStateId, description);
        return newStateId;
    }

    /// @notice Removes a previously defined potential collapsed state. Only callable when Indeterminate.
    /// Cannot remove if tokens are deposited for this state.
    /// @param stateId The ID of the state to remove.
    function removePossibleCollapsedState(uint256 stateId)
        public
        onlyOwner
        onlyIndeterminateState
        onlyExistingState(stateId)
    {
        // Check if any tokens are deposited for this state
        // (Iterating all tokens is impractical, relying on the owner to ensure no deposits remain)
        // A safer implementation might track unique token addresses per state or require withdrawal first.
        // For simplicity here, we assume owner manages this risk or ensures no deposits remain before removal.

        delete possibleCollapsedStates[stateId]; // This resets mappings within the struct
        possibleCollapsedStates[stateId].exists = false; // Explicitly mark as non-existent
        emit StateRemoved(stateId);
    }

    /// @notice Retrieves the configuration data for a potential collapsed state.
    /// Note: Does not return the internal mappings directly due to Solidity limitations.
    /// Use getStatePermission and getERC20ReleaseConfigForState for details.
    /// @param stateId The ID of the state to retrieve.
    /// @return description The state description.
    /// @return exists True if the state ID is valid and exists.
    function getPossibleStateData(uint256 stateId)
        public
        view
        returns (string memory description, bool exists)
    {
        CollapsedStateData storage stateData = possibleCollapsedStates[stateId];
        return (stateData.description, stateData.exists);
    }

    /// @notice Sets or revokes a boolean permission for a *potential* collapsed state.
    /// Only callable when Indeterminate.
    /// @param stateId The ID of the state to modify.
    /// @param permissionKey The identifier for the permission (e.g., "can_withdraw_funds", "is_admin").
    /// @param value True to grant, false to revoke.
    function grantPermissionToState(
        uint256 stateId,
        string calldata permissionKey,
        bool value
    ) public onlyOwner onlyIndeterminateState onlyExistingState(stateId) {
        possibleCollapsedStates[stateId].permissions[permissionKey] = value;
        emit PermissionGranted(stateId, permissionKey, value);
    }

    /// @notice Checks the status of a specific permission for a *potential* collapsed state.
    /// @param stateId The ID of the state to check.
    /// @param permissionKey The identifier for the permission.
    /// @return True if the permission is set for this state, false otherwise.
    function getStatePermission(uint256 stateId, string calldata permissionKey)
        public
        view
        onlyExistingState(stateId)
        returns (bool)
    {
        return possibleCollapsedStates[stateId].permissions[permissionKey];
    }

    /// @notice Checks if the *current* collapsed state grants a specific permission.
    /// Only callable when the lock is Collapsed.
    /// @param permissionKey The identifier for the permission.
    /// @return True if the current collapsed state grants the permission, false otherwise.
    function hasPermissionInCurrentState(string calldata permissionKey)
        public
        view
        onlyCollapsedState
        returns (bool)
    {
        return possibleCollapsedStates[collapsedStateId].permissions[permissionKey];
    }

    /// @notice Allows users to deposit ERC20 tokens designated for release if the state collapses to `stateId`.
    /// Requires the user to approve this contract to spend the tokens first. Only callable when Indeterminate.
    /// Tokens deposited here can potentially be claimed by *any* user in the collapsed state, depending on claim logic.
    /// A more complex system would track deposits per user, but this example pools deposits per state/token.
    /// @param stateId The ID of the potential state the deposit is for.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20ForCollapseState(
        uint256 stateId,
        address tokenAddress,
        uint256 amount
    ) public onlyIndeterminateState onlyExistingState(stateId) {
        require(amount > 0, "QuantumLock: Amount must be greater than 0");
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
        erc20DepositsForState[stateId][tokenAddress] += amount;
        emit ERC20DepositedForState(stateId, tokenAddress, amount, msg.sender);
    }

    /// @notice Checks the total amount of a specific ERC20 token deposited for a potential state.
    /// @param stateId The ID of the potential state.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The total deposited amount.
    function getERC20DepositedForState(uint256 stateId, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return erc20DepositsForState[stateId][tokenAddress];
    }

    /// @notice Configures the amount of a specific ERC20 token that *should* be claimable by the *caller* of `claimERC20FromCollapsedState`
    /// if the state collapses to `stateId`. This is a configuration, not a deposit.
    /// @param stateId The ID of the state to configure.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to configure for release (per claimer in that state).
    function addERC20ReleaseToState(
        uint256 stateId,
        address tokenAddress,
        uint256 amount
    ) public onlyOwner onlyIndeterminateState onlyExistingState(stateId) {
        possibleCollapsedStates[stateId].erc20ReleaseConfig[tokenAddress] = amount;
        emit ERC20ClaimedFromState(stateId, tokenAddress, amount, address(0)); // Receiver 0 signals config update
    }

    /// @notice Gets the configured ERC20 release amount for a state and token.
    /// This is the amount configured per *claimer* in the collapsed state, not the total deposited amount.
    /// @param stateId The ID of the potential state.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The configured release amount.
    function getERC20ReleaseConfigForState(uint256 stateId, address tokenAddress)
        public
        view
        onlyExistingState(stateId)
        returns (uint256)
    {
        return possibleCollapsedStates[stateId].erc20ReleaseConfig[tokenAddress];
    }


    /// @notice Initiates the state collapse process by requesting randomness from Chainlink VRF.
    /// Only callable when the lock is Indeterminate.
    /// @param callbackGasLimit The max gas for the fulfillRandomWords callback.
    /// @param requestConfirmations The number of block confirmations to wait for the VRF result.
    /// @param numWords The number of random words to request (should be 1).
    /// @return requestId The ID of the VRF request.
    function triggerMeasurement(
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords
    ) public onlyOwner onlyIndeterminateState returns (uint256 requestId) {
        require(stateIdCounter > 1, "QuantumLock: No collapsed states defined"); // Need at least one possible state
        require(numWords == 1, "QuantumLock: Only 1 random word supported for state collapse");

        s_callbackGasLimit = callbackGasLimit; // Allow owner to update gas limit on trigger
        s_numWords = numWords;
        // Will revert if subscription is not funded or if there are other VRF issues
        requestId = requestRandomWords(s_keyHash, s_subscriptionId, requestConfirmations, s_callbackGasLimit, s_numWords);

        s_pendingRequests[requestId] = true; // Mark as pending
        emit MeasurementTriggered(requestId, msg.sender);
    }

    /// @notice Chainlink VRF callback function. This function is automatically called by the VRF Coordinator
    /// after the randomness request is fulfilled. It performs the state collapse.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The array of random words returned by VRF.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // Check if this request is still considered pending and hasn't been logically cancelled
        if (!s_pendingRequests[requestId]) {
            // If not pending, it was either already fulfilled or cancelled. Do nothing.
            return;
        }

        // Mark request as no longer pending
        delete s_pendingRequests[requestId];

        // Ensure the state is still Indeterminate. Multiple requests could be pending,
        // only the first one to fulfill should collapse the state.
        if (currentState != State.Indeterminate) {
             // Log or handle the case where a late fulfillment arrives after collapse
             // For simplicity, we just return. The random word is effectively unused for collapse.
             return;
        }

        require(randomWords.length == s_numWords, "QuantumLock: Incorrect number of random words");

        uint256 randomIndex = randomWords[0];

        // Determine the collapsed state ID based on the random index and the number of defined states
        // The random number needs to be mapped to a valid state ID from our defined states (1 to stateIdCounter - 1)
        uint256 totalPossibleStates = stateIdCounter - 1;
        require(totalPossibleStates > 0, "QuantumLock: No possible states defined for collapse");

        // Map the random number to an index between 0 and totalPossibleStates - 1
        uint256 stateIndex = randomIndex % totalPossibleStates;

        // Find the state ID corresponding to this index
        uint256 selectedStateId = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 1; i < stateIdCounter; i++) {
            if (possibleCollapsedStates[i].exists) {
                if (currentIndex == stateIndex) {
                    selectedStateId = i;
                    break;
                }
                currentIndex++;
            }
        }

        require(selectedStateId != 0, "QuantumLock: Failed to select a valid state ID");
        require(possibleCollapsedStates[selectedStateId].exists, "QuantumLock: Selected state ID does not exist");

        // Perform the state collapse
        currentState = State.Collapsed;
        collapsedStateId = selectedStateId;
        measurementRequestStatus[requestId] = selectedStateId; // Record which request caused the collapse and to what state

        // Note: Token releases are not done here. They are claimed by users later.

        emit StateCollapsed(collapsedStateId, requestId);
    }

    /// @notice Gets the collapsed state ID determined by a specific VRF request.
    /// @param requestId The ID of the VRF request.
    /// @return The collapsed state ID (>= 1), or 0 if the request hasn't been fulfilled or was cancelled for collapse.
    function getMeasurementOutcomeId(uint256 requestId) public view returns (uint256) {
        return measurementRequestStatus[requestId];
    }

     /// @notice Checks if a specific VRF request has been fulfilled and processed by this contract's `fulfillRandomWords` for collapsing state.
     /// Returns true if `measurementRequestStatus[requestId]` is not 0.
     /// @param requestId The ID of the VRF request.
     /// @return True if fulfilled for collapse, false otherwise.
    function isMeasurementRequestFulfilled(uint256 requestId) public view returns (bool) {
        return measurementRequestStatus[requestId] != 0;
    }

    /// @notice Returns a list of request IDs that are currently pending VRF fulfillment and haven't been cancelled.
    /// Note: Iterating over a mapping is inefficient for large numbers of pending requests.
    /// For a production system, consider a linked list or array for pending requests if many are expected.
    /// @return An array of pending request IDs.
    function getPendingMeasurementRequests() public view onlyOwner returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i < type(uint256).max; i++) { // Limited iteration, adjust as needed or use a better data structure
            if (s_pendingRequests[i]) {
                count++;
            }
             // Basic break condition if request IDs are expected to be somewhat sequential
             // This is not robust for sparse request IDs.
            if (count > 0 && !s_pendingRequests[i] && !s_pendingRequests[i+1] && !s_pendingRequests[i+2] && !s_pendingRequests[i+3] && !s_pendingRequests[i+4]) break;
        }

        uint256[] memory pending = new uint256[](count);
        uint256 index = 0;
         for (uint256 i = 1; i < type(uint256).max; i++) {
             if (s_pendingRequests[i]) {
                 pending[index++] = i;
             }
             if (index == count) break; // Stop once all found
             if (index > 0 && !s_pendingRequests[i] && !s_pendingRequests[i+1] && !s_pendingRequests[i+2] && !s_pendingRequests[i+3] && !s_pendingRequests[i+4]) break;
         }

        return pending;
    }

    /// @notice Allows the owner to logically cancel a pending VRF request within the contract's state.
    /// This prevents `fulfillRandomWords` from collapsing the state for this specific request,
    /// but does *not* stop Chainlink from fulfilling the request or consume LINK.
    /// Only callable when Indeterminate and the request is pending.
    /// @param requestId The ID of the request to cancel.
    function cancelPendingMeasurementRequest(uint256 requestId) public onlyOwner onlyIndeterminateState {
        require(s_pendingRequests[requestId], "QuantumLock: Request is not pending");
        delete s_pendingRequests[requestId];
        // Optional: could set measurementRequestStatus[requestId] = type(uint256).max or some indicator of cancellation
        emit MeasurementRequestCancelled(requestId);
    }

    /// @notice Allows a user to claim ERC20 tokens allocated to them in the collapsed state.
    /// Assumes ERC20ReleaseConfig specifies the amount claimable *per user* for that token/state.
    /// In this simple version, it allows *any* caller to claim the configured amount once from the pool.
    /// A more advanced version would track which addresses have claimed for which state/token.
    /// @param tokenAddress The address of the ERC20 token to claim.
    function claimERC20FromCollapsedState(address tokenAddress) public onlyCollapsedState {
        uint256 amountToClaim = possibleCollapsedStates[collapsedStateId].erc20ReleaseConfig[tokenAddress];
        require(amountToClaim > 0, "QuantumLock: No claimable amount configured for this token in the collapsed state");

        // Simple claim logic: assume deposited funds for the collapsed state can be claimed up to the configured amount.
        // This version allows multiple callers to claim the configured amount until the deposited pool is depleted.
        // A more robust system would use a mapping like mapping(address => mapping(uint256 => mapping(address => bool))) claimedStatus;
        uint256 availableAmount = erc20DepositsForState[collapsedStateId][tokenAddress];
        uint256 actualClaimAmount = amountToClaim;

        if (availableAmount < actualClaimAmount) {
             // Can only claim up to what's available in the pool for this state/token
             actualClaimAmount = availableAmount;
        }

        require(actualClaimAmount > 0, "QuantumLock: No deposited funds available to claim for this token");

        erc20DepositsForState[collapsedStateId][tokenAddress] -= actualClaimAmount; // Deduct from the pool
        IERC20(tokenAddress).safeTransfer(msg.sender, actualClaimAmount);
        emit ERC20ClaimedFromState(collapsedStateId, tokenAddress, actualClaimAmount, msg.sender);
    }

    /// @notice An example function demonstrating how permissions in the collapsed state can gate functionality.
    /// Requires the `execute_example` permission to be true in the currently collapsed state.
    /// @param permissionKey The permission key required to execute this action.
    function executePermissionedAction(string calldata permissionKey) public onlyCollapsedState {
        require(
            hasPermissionInCurrentState(permissionKey),
            string(abi.encodePacked("QuantumLock: Requires '", permissionKey, "' permission"))
        );

        // --- Your permissioned logic here ---
        // For example:
        // require(msg.sender == specificAddress, "Only specific address can use this permission");
        // Perform some action: change a variable, call another contract, etc.
        // Example: If permissionKey is "unlock_vault", allow withdrawal from a separate vault contract.
        // Or if permissionKey is "grant_role", grant a role to msg.sender in another role-based access contract.
        // -----------------------------------

        // Emit a generic event for demonstration
        emit PermissionGranted(collapsedStateId, permissionKey, true); // Re-emitting for action demo

        // In a real scenario, this would trigger specific effects based on the permissionKey
        // For this example, we just log that the action was attempted/checked.
        // log("Permissioned action executed/checked for key:", permissionKey); // Pseudocode logging
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens held by the contract.
    /// Useful for emergency withdrawals or recovering mistakenly sent tokens.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function withdrawERC20Owner(address tokenAddress, uint256 amount) public onlyOwner {
        require(amount > 0, "QuantumLock: Amount must be > 0");
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }

    // Standard Ownable functions (2)
    // 23. transferOwnership
    // 24. renounceOwnership
    // (Inherited from OpenZeppelin Ownable.sol)

    // Fallback/Receive: Revert if ETH is sent directly
    receive() external payable {
        revert("QuantumLock: Cannot receive ETH");
    }

    fallback() external payable {
         revert("QuantumLock: Cannot receive calls");
    }

    /// @notice Returns the total number of defined possible collapsed states.
    /// @return The count of states.
    function getPossibleStateCount() public view returns (uint256) {
        return stateIdCounter - 1;
    }
}
```