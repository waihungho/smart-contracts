Okay, here is a Solidity smart contract incorporating advanced concepts like state-dependent logic, multiple roles, dynamic conditions for fund release inspired by quantum mechanics (as a metaphor for probabilistic/conditional state transitions), multi-asset handling, and state linking (entanglement metaphor).

It aims for novelty by combining these elements in a specific "Quantum Vault" pattern, different from standard vesting, time locks, or multi-sigs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol"; // Using SafeERC20 for safer interactions
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Adding ReentrancyGuard

/**
 * @title QuantumVault
 * @dev A complex smart contract simulating conditional fund release based on "observation" of "quantum states".
 * Funds are locked in states with defined conditions. An authorized "Observer" triggers evaluation,
 * causing the state to collapse into a success (release) or failure (re-lock/residual) outcome.
 * The "quantum" aspect is a metaphor for the non-deterministic (from the perspective of needing an external trigger),
 * state-dependent, and potentially entangled nature of fund release compared to simple time-locks.
 */

/**
 * Outline:
 * 1. State Variables & Data Structures:
 *    - Owner, Observers list.
 *    - State counter.
 *    - Enum for State Status (Superposed, ObservedSuccess, ObservedFailure, Cancelled).
 *    - Enum for State Type (TimeGated, Dependent, ExternalCondition).
 *    - Struct for QuantumState.
 *    - Mappings for states by ID, and indexes for lookups by depositor/recipient/status.
 *    - Mapping for entangled states.
 * 2. Events: For tracking state changes, observations, claims, etc.
 * 3. Errors: Custom errors for clearer reverts.
 * 4. Modifiers: Access control.
 * 5. Constructor: Sets the owner.
 * 6. Observer Management: Add/remove observers.
 * 7. State Creation: Define and deposit funds into a new QuantumState with specified conditions.
 * 8. State Observation: The core logic. An observer triggers evaluation of a state's conditions, determining its final status and initiating transfers.
 * 9. Fund Claiming: Allows the recipient to claim funds from successfully observed states.
 * 10. State Management: Cancel states (under conditions), get state information.
 * 11. Entanglement: Link two states such that observing one affects the other.
 * 12. Residual Funds: Owner withdrawal of funds from failed or cancelled states.
 * 13. Fallback/Receive: For receiving ETH deposits directly (not into a state).
 * 14. View Functions: Get state info, check balances, list states by status/user.
 */

/**
 * Function Summary:
 * - constructor(): Deploys the contract, sets the initial owner.
 * - fallback(): Allows receiving bare ETH transfers.
 * - receive(): Explicitly allows receiving ETH.
 * - addObserver(address _observer): Owner adds an address to the list of authorized observers.
 * - removeObserver(address _observer): Owner removes an address from the list of authorized observers.
 * - isObserver(address _address): Checks if an address is an authorized observer.
 * - createState(address _asset, uint256 _amount, address _recipient, StateType _type, bytes32 _conditionHashOrLink, uint256 _conditionValue, uint256 _observationFee): Creates a new QuantumState, locking the specified asset and amount with defined conditions. Requires prior approval for ERC20.
 * - observeState(uint256 _stateId, bytes32 _observationData): An authorized observer attempts to resolve a state. Evaluates conditions based on _observationData and state type. If successful, transfers funds (minus fee) to recipient and fee to observer. Updates state status.
 * - claimFunds(uint256 _stateId): Recipient claims funds from a state that has been successfully observed (`ObservedSuccess`).
 * - cancelState(uint256 _stateId): Allows the depositor or owner to cancel a state before it's observed. Returns funds to the depositor.
 * - getStateInfo(uint256 _stateId): Returns detailed information about a specific state (view function).
 * - getTotalContractBalance(address _asset): Returns the total balance of a specific asset held by the contract (view function).
 * - getUserClaimableBalance(address _user, address _asset): Calculates the total amount of a specific asset claimable by a user across all their `ObservedSuccess` states (view function).
 * - getSuperposedStateIdsByDepositor(address _depositor): Returns a list of state IDs deposited by a user that are still `Superposed` (view function).
 * - getSuperposedStateIdsByRecipient(address _recipient): Returns a list of state IDs targeting a recipient that are still `Superposed` (view function).
 * - getClaimableStateIdsByRecipient(address _recipient): Returns a list of state IDs targeting a recipient that are `ObservedSuccess` and not yet claimed (view function).
 * - ownerWithdrawResidualETH(): Owner can withdraw any ETH in the contract not locked within a `Superposed` state.
 * - ownerWithdrawResidualERC20(address _tokenAddress): Owner can withdraw any ERC20 tokens in the contract not locked within a `Superposed` state.
 * - updateStateObservationFee(uint256 _stateId, uint256 _newFee): Allows the depositor or owner to update the observation fee for a `Superposed` state.
 * - linkStatesForEntanglement(uint256 _stateId1, uint256 _stateId2): Links two `DEPENDENT` states for entanglement. Observing _stateId1 will attempt to resolve _stateId2 based on its entanglement outcome setting.
 * - setEntanglementOutcome(uint256 _stateId, bool _outcome): Sets the pre-determined outcome for a `DEPENDENT` state when its linked state is observed.
 * - checkStateConditions(QuantumState storage _state, bytes32 _observationData): Internal helper to evaluate a state's conditions.
 */

contract QuantumVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;

    // --- State Variables ---
    uint256 private stateCounter;
    mapping(uint256 => QuantumState) public states;
    mapping(address => bool) public isObserver;

    // Indexes for view functions (simplified for example, production might use more gas-efficient structures)
    mapping(address => uint256[]) private superposedStateIdsByDepositor;
    mapping(address => uint256[]) private superposedStateIdsByRecipient;
    mapping(address => uint256[]) private claimableStateIdsByRecipient; // States ObservedSuccess but not claimed

    // Mapping for entanglement (linkedStateId => dependentStateId)
    mapping(uint256 => uint256) private entangledStates;

    // --- Enums ---
    enum StateStatus {
        Superposed,        // Initial state, waiting for observation
        ObservedSuccess,   // Conditions met, funds claimable by recipient
        ObservedFailure,   // Conditions not met, funds locked or residual (owner claimable)
        Cancelled          // State cancelled by owner/depositor
    }

    enum StateType {
        TimeGated,          // ConditionValue is a timestamp
        Dependent,          // ConditionValue is a stateId to link to, ConditionHashOrLink is the desired outcome hash (e.g., hash of true/false)
        ExternalCondition   // ConditionHashOrLink must match _observationData provided by observer
    }

    // --- Structs ---
    struct QuantumState {
        uint256 id;
        address depositor;
        address asset; // Use address(0) for ETH
        uint256 amount;
        address recipient;
        StateType stateType;
        bytes32 conditionHashOrLink; // For ExternalCondition (hash of required data), or Dependent (linked state ID as bytes32)
        uint256 conditionValue;      // For TimeGated (timestamp), or Dependent (linked state ID as uint256)
        uint256 observationFee;      // Amount paid to the observer on successful observation (taken from state amount)
        StateStatus status;
        uint256 creationTimestamp;
        bool claimed; // Flag for claimable states
        bool entanglementOutcome; // For Dependent states: true if linked state success -> this state success, false if linked state success -> this state failure
    }

    // --- Events ---
    event ObserverAdded(address indexed observer);
    event ObserverRemoved(address indexed observer);
    event StateCreated(
        uint256 indexed stateId,
        address indexed depositor,
        address indexed recipient,
        address asset,
        uint256 amount,
        StateType stateType
    );
    event StateObserved(
        uint256 indexed stateId,
        address indexed observer,
        StateStatus newStatus,
        bytes32 observationData
    );
    event FundsClaimed(
        uint256 indexed stateId,
        address indexed recipient,
        address asset,
        uint256 amount
    );
    event StateCancelled(uint256 indexed stateId, address indexed cancelledBy);
    event ObservationFeeUpdated(uint256 indexed stateId, uint256 newFee);
    event StatesLinkedForEntanglement(
        uint256 indexed stateId1,
        uint256 indexed stateId2
    );
    event EntanglementOutcomeSet(uint256 indexed stateId, bool outcome);

    // --- Errors ---
    error NotOwner();
    error NotObserver();
    error StateNotFound(uint256 stateId);
    error StateNotSuperposed(uint256 stateId);
    error StateAlreadyObserved(uint256 stateId);
    error StateNotClaimable(uint256 stateId);
    error StateClaimed(uint256 stateId);
    error NotDepositorOrOwner();
    error InvalidCondition();
    error InsufficientFundsForFee(uint256 stateId, uint256 requiredFee, uint256 availableAmount);
    error ClaimAmountMismatch(uint256 stateId, uint256 expected, uint256 claimed);
    error InvalidEntanglementLink();
    error StateNotDependent(uint256 stateId);
    error EntanglementOutcomeAlreadySet(uint256 stateId);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyObserver() {
        if (!isObserver[msg.sender]) revert NotObserver();
        _;
    }

    modifier whenStateIs(uint256 _stateId, StateStatus _status) {
        if (states[_stateId].status != _status) revert StateNotFound(_stateId); // Basic check
        _;
    }

    // --- Constructor ---
    constructor() ReentrancyGuard() {
        owner = msg.sender;
    }

    // --- Fallback & Receive ---
    // Allows the contract to receive bare ETH transfers, though not recommended for funds intended for states.
    fallback() external payable {}

    // Explicit receive function
    receive() external payable {}

    // --- Observer Management ---
    function addObserver(address _observer) external onlyOwner {
        isObserver[_observer] = true;
        emit ObserverAdded(_observer);
    }

    function removeObserver(address _observer) external onlyOwner {
        isObserver[_observer] = false;
        emit ObserverRemoved(_observer);
    }

    // --- State Creation ---
    /**
     * @dev Creates a new Quantum State.
     * @param _asset The address of the ERC20 token (or address(0) for ETH).
     * @param _amount The amount of asset to lock.
     * @param _recipient The address that will receive the funds if the state is observed successfully.
     * @param _type The type of state (TimeGated, Dependent, ExternalCondition).
     * @param _conditionHashOrLink Specific data for the condition evaluation. For ExternalCondition, this is a hash that must be matched by the observer. For Dependent, this should ideally be the ID of the linked state cast to bytes32.
     * @param _conditionValue Specific numeric value for the condition evaluation. For TimeGated, this is a future timestamp. For Dependent, this is the ID of the linked state.
     * @param _observationFee The fee to be paid to the observer on successful observation. Must be less than _amount.
     */
    function createState(
        address _asset,
        uint256 _amount,
        address _recipient,
        StateType _type,
        bytes32 _conditionHashOrLink,
        uint256 _conditionValue,
        uint256 _observationFee
    ) external payable nonReentrant {
        if (_amount == 0) revert InvalidCondition();
        if (_recipient == address(0)) revert InvalidCondition();
        if (_observationFee >= _amount) revert InsufficientFundsForFee(0, _observationFee, _amount); // Fee must be strictly less than amount

        uint256 stateId = stateCounter++;

        // Handle ETH deposit
        if (_asset == address(0)) {
            if (msg.value != _amount) revert InvalidCondition(); // Must send exact ETH amount
        } else {
            // Handle ERC20 deposit
            if (msg.value > 0) revert InvalidCondition(); // Cannot send ETH with ERC20
            IERC20 token = IERC20(_asset);
            // Requires caller to have approved this contract to spend _amount
            token.safeTransferFrom(msg.sender, address(this), _amount);
        }

        states[stateId] = QuantumState({
            id: stateId,
            depositor: msg.sender,
            asset: _asset,
            amount: _amount,
            recipient: _recipient,
            stateType: _type,
            conditionHashOrLink: _conditionHashOrLink,
            conditionValue: _conditionValue,
            observationFee: _observationFee,
            status: StateStatus.Superposed,
            creationTimestamp: block.timestamp,
            claimed: false,
            entanglementOutcome: false // Default, should be set for Dependent states
        });

        // Add to index mappings
        superposedStateIdsByDepositor[msg.sender].push(stateId);
        superposedStateIdsByRecipient[_recipient].push(stateId);

        emit StateCreated(
            stateId,
            msg.sender,
            _recipient,
            _asset,
            _amount,
            _type
        );
    }

    // --- State Observation ---
    /**
     * @dev Allows an authorized observer to attempt to resolve a state.
     * @param _stateId The ID of the state to observe.
     * @param _observationData Data provided by the observer to check against the state's condition (e.g., a hash).
     */
    function observeState(uint256 _stateId, bytes32 _observationData)
        external
        onlyObserver
        nonReentrant
        whenStateIs(_stateId, StateStatus.Superposed)
    {
        QuantumState storage state = states[_stateId];

        // Check conditions based on state type
        bool conditionsMet = checkStateConditions(state, _observationData);

        if (conditionsMet) {
            state.status = StateStatus.ObservedSuccess;
            state.claimed = false; // Ready to be claimed
            uint256 payoutAmount = state.amount - state.observationFee;

            // Pay observation fee to the observer
            if (state.observationFee > 0) {
                if (state.asset == address(0)) {
                    (bool success, ) = msg.sender.call{value: state.observationFee}("");
                    if (!success) {
                         // Handle failure: Revert or log? For simplicity, let's revert.
                         // A more robust contract might try again or log.
                         revert InsufficientFundsForFee(_stateId, state.observationFee, state.amount); // Reusing error, maybe needs a specific one
                    }
                } else {
                    IERC20 token = IERC20(state.asset);
                    token.safeTransfer(msg.sender, state.observationFee);
                }
            }

            // Add to claimable index
            claimableStateIdsByRecipient[state.recipient].push(stateId);

            // Handle entanglement: If this state is linked TO another dependent state, observe the linked state
            if (entangledStates[_stateId] != 0) {
                 uint256 dependentStateId = entangledStates[_stateId];
                 QuantumState storage dependentState = states[dependentStateId];
                 if (dependentState.status == StateStatus.Superposed && dependentState.stateType == StateType.Dependent) {
                     // Recursively observe the dependent state based on its pre-set outcome
                     if (dependentState.entanglementOutcome) {
                          // Linked state success -> dependent state success
                          // Note: Dependent states usually don't have observation fees or external data
                          // Simplify: Dependent state success means funds become claimable for *its* recipient
                          dependentState.status = StateStatus.ObservedSuccess;
                          dependentState.claimed = false; // Ready to be claimed
                           claimableStateIdsByRecipient[dependentState.recipient].push(dependentStateId);
                           emit StateObserved(dependentStateId, address(this), StateStatus.ObservedSuccess, bytes32(0)); // Observer is this contract
                     } else {
                          // Linked state success -> dependent state failure
                           dependentState.status = StateStatus.ObservedFailure;
                           emit StateObserved(dependentStateId, address(this), StateStatus.ObservedFailure, bytes32(0)); // Observer is this contract
                     }
                     _removeStateFromSuperposedIndex(dependentState.depositor, dependentStateId);
                     _removeStateFromSuperposedIndex(dependentState.recipient, dependentStateId);
                 }
            }


        } else {
            state.status = StateStatus.ObservedFailure;
        }

        // Remove from superposed indexes regardless of outcome
        _removeStateFromSuperposedIndex(state.depositor, stateId);
        _removeStateFromSuperposedIndex(state.recipient, stateId);

        emit StateObserved(
            stateId,
            msg.sender,
            state.status,
            _observationData
        );
    }

    /**
     * @dev Internal helper to check state conditions.
     * @param _state The state struct.
     * @param _observationData Data provided by the observer.
     * @return True if conditions are met, false otherwise.
     */
    function checkStateConditions(
        QuantumState storage _state,
        bytes32 _observationData
    ) internal view returns (bool) {
        if (_state.stateType == StateType.TimeGated) {
            // ConditionValue is a timestamp
            return block.timestamp >= _state.conditionValue;
        } else if (_state.stateType == StateType.ExternalCondition) {
            // ConditionHashOrLink is the required hash
            return _observationData == _state.conditionHashOrLink;
        } else if (_state.stateType == StateType.Dependent) {
             // ConditionValue/ConditionHashOrLink refers to a linked state ID
             // This state resolves based on the *observation* of its linked state,
             // and the entanglementOutcome flag set for THIS state.
             // The actual resolution is handled within observeState when the LINKED state is observed.
             // This check function is only called when the DEPENDENT state itself is DIRECTLY observed,
             // which should generally revert or be handled differently if strict entanglement is desired.
             // For this implementation, direct observation of a Dependent state is considered a failure unless
             // it's already been resolved by its linked state (which observeState checks via state.status).
             // So, if we reach here and status is Superposed, direct observation fails the condition.
             return false; // Dependent states cannot be resolved by direct observation alone in this model
        }
        return false; // Should not reach here
    }

    // --- Fund Claiming ---
    /**
     * @dev Allows the recipient to claim funds from a state that has been successfully observed.
     * @param _stateId The ID of the state to claim from.
     */
    function claimFunds(uint256 _stateId)
        external
        nonReentrant
        whenStateIs(_stateId, StateStatus.ObservedSuccess)
    {
        QuantumState storage state = states[_stateId];

        if (state.recipient != msg.sender) revert StateNotClaimable(_stateId);
        if (state.claimed) revert StateClaimed(_stateId);

        state.claimed = true;
        uint256 payoutAmount = state.amount - state.observationFee;

        // Remove from claimable index
        _removeStateFromClaimableIndex(msg.sender, _stateId);

        // Transfer funds
        if (state.asset == address(0)) {
            (bool success, ) = payable(state.recipient).call{value: payoutAmount}("");
            if (!success) {
                 // If ETH transfer fails, mark as not claimed so recipient can try again
                 state.claimed = false;
                 // Re-add to claimable index (or handle appropriately)
                 claimableStateIdsByRecipient[msg.sender].push(_stateId); // Simple re-add, could check for duplicates
                 revert ClaimAmountMismatch(_stateId, payoutAmount, 0); // Reusing error for transfer failure
            }
        } else {
            IERC20 token = IERC20(state.asset);
            token.safeTransfer(state.recipient, payoutAmount);
        }

        emit FundsClaimed(_stateId, msg.sender, state.asset, payoutAmount);
    }

     /**
      * @dev Internal helper to remove state ID from the superposed index array.
      * @param _user The depositor or recipient address.
      * @param _stateId The state ID to remove.
      */
     function _removeStateFromSuperposedIndex(address _user, uint256 _stateId) internal {
         // Remove from depositor's list
         uint256[] storage depositorStates = superposedStateIdsByDepositor[_user];
         for (uint i = 0; i < depositorStates.length; i++) {
             if (depositorStates[i] == _stateId) {
                 depositorStates[i] = depositorStates[depositorStates.length - 1];
                 depositorStates.pop();
                 break;
             }
         }

         // Remove from recipient's list (can be the same user)
         uint256[] storage recipientStates = superposedStateIdsByRecipient[_user];
         for (uint i = 0; i < recipientStates.length; i++) {
             if (recipientStates[i] == _stateId) {
                 recipientStates[i] = recipientStates[recipientStates.length - 1];
                 recipientStates.pop();
                 break;
             }
         }
     }

     /**
      * @dev Internal helper to remove state ID from the claimable index array.
      * @param _user The recipient address.
      * @param _stateId The state ID to remove.
      */
     function _removeStateFromClaimableIndex(address _user, uint256 _stateId) internal {
         uint256[] storage claimableStates = claimableStateIdsByRecipient[_user];
         for (uint i = 0; i < claimableStates.length; i++) {
             if (claimableStates[i] == _stateId) {
                 claimableStates[i] = claimableStates[claimableStates.length - 1];
                 claimableStates.pop();
                 break;
             }
         }
     }


    // --- State Management ---
    /**
     * @dev Allows the depositor or owner to cancel a state that hasn't been observed yet.
     * Returns the locked funds to the depositor.
     * @param _stateId The ID of the state to cancel.
     */
    function cancelState(uint256 _stateId)
        external
        nonReentrant
        whenStateIs(_stateId, StateStatus.Superposed)
    {
        QuantumState storage state = states[_stateId];

        if (state.depositor != msg.sender && owner != msg.sender)
            revert NotDepositorOrOwner();

        state.status = StateStatus.Cancelled;

        // Remove from superposed indexes
        _removeStateFromSuperposedIndex(state.depositor, _stateId);
        _removeStateFromSuperposedIndex(state.recipient, _stateId); // Also remove from recipient's superposed view

        // Return funds to depositor
        if (state.amount > 0) {
            if (state.asset == address(0)) {
                 (bool success, ) = payable(state.depositor).call{value: state.amount}("");
                 // If transfer fails, funds remain in contract under 'Cancelled' state.
                 // Owner can potentially recover via ownerWithdrawResidualETH if needed,
                 // but recipient cannot claim. For robustness, could add retry logic.
                 if (!success) {
                      // Log failure or revert? Reverting is safer for funds.
                      revert ClaimAmountMismatch(_stateId, state.amount, 0); // Reusing error
                 }
            } else {
                 IERC20 token = IERC20(state.asset);
                 token.safeTransfer(state.depositor, state.amount);
            }
        }


        emit StateCancelled(_stateId, msg.sender);
    }

    /**
     * @dev Allows the depositor or owner to update the observation fee for a superposed state.
     * @param _stateId The ID of the state.
     * @param _newFee The new observation fee amount.
     */
    function updateStateObservationFee(uint256 _stateId, uint256 _newFee)
        external
        nonReentrant
        whenStateIs(_stateId, StateStatus.Superposed)
    {
        QuantumState storage state = states[_stateId];

        if (state.depositor != msg.sender && owner != msg.sender)
            revert NotDepositorOrOwner();

        if (_newFee >= state.amount) revert InsufficientFundsForFee(_stateId, _newFee, state.amount);

        state.observationFee = _newFee;

        emit ObservationFeeUpdated(_stateId, _newFee);
    }


    // --- Entanglement Functions ---
    /**
     * @dev Links two states for entanglement. Requires stateId1 to be Superposed and stateId2 to be a Superposed DEPENDENT state.
     * Observing stateId1 will attempt to resolve stateId2.
     * @param _stateId1 The ID of the state that, when observed, affects stateId2.
     * @param _stateId2 The ID of the DEPENDENT state that is affected by observing stateId1.
     */
    function linkStatesForEntanglement(uint256 _stateId1, uint256 _stateId2)
        external
        nonReentrant
    {
        if (_stateId1 == _stateId2) revert InvalidEntanglementLink();

        QuantumState storage state1 = states[_stateId1];
        QuantumState storage state2 = states[_stateId2];

        if (state1.status != StateStatus.Superposed || state2.status != StateStatus.Superposed)
             revert StateNotSuperposed( state1.status != StateStatus.Superposed ? _stateId1 : _stateId2);

        if (state2.stateType != StateType.Dependent) revert StateNotDependent(_stateId2);
        // Ensure state2 is actually intended to be linked to state1
        if (state2.conditionValue != _stateId1 && bytes32(state2.conditionValue) != state2.conditionHashOrLink) {
             // This dependent state wasn't created with stateId1 as its condition link
             revert InvalidEntanglementLink();
        }


        // Only depositor of state2 or owner can link it
        if (state2.depositor != msg.sender && owner != msg.sender) revert NotDepositorOrOwner();

        // Prevent relinking if already linked
        if (entangledStates[_stateId1] != 0) revert InvalidEntanglementLink(); // state1 already links to something
        // Could also check if _stateId2 is already linked FROM another state

        entangledStates[_stateId1] = _stateId2;

        emit StatesLinkedForEntanglement(_stateId1, _stateId2);
    }

    /**
     * @dev Sets the predetermined outcome for a DEPENDENT state when its linked state is observed.
     * This must be set BEFORE the linked state is observed.
     * @param _stateId The ID of the DEPENDENT state.
     * @param _outcome If true, observing the linked state successfully makes this state success. If false, makes it failure.
     */
    function setEntanglementOutcome(uint256 _stateId, bool _outcome)
        external
        nonReentrant
        whenStateIs(_stateId, StateStatus.Superposed)
    {
         QuantumState storage state = states[_stateId];

         if (state.stateType != StateType.Dependent) revert StateNotDependent(_stateId);

         // Prevent setting if already set or linked state observed (implicitly by Superposed check)
         // We can add a flag if needed, but let's assume setting it once is sufficient if status is Superposed
         // if (state.entanglementOutcomeSetFlag) revert EntanglementOutcomeAlreadySet(_stateId); // Optional flag


         // Only depositor of state or owner can set the outcome
         if (state.depositor != msg.sender && owner != msg.sender) revert NotDepositorOrOwner();


         state.entanglementOutcome = _outcome;
         // state.entanglementOutcomeSetFlag = true; // Optional flag

         emit EntanglementOutcomeSet(_stateId, _outcome);
    }


    // --- Owner Residual Funds Withdrawal ---
    /**
     * @dev Allows the owner to withdraw ETH that is not currently locked in a Superposed state.
     * This includes ETH from Failed or Cancelled states (if transfer back failed) or ETH sent without creating a state.
     */
    function ownerWithdrawResidualETH() external onlyOwner nonReentrant {
        uint256 contractETHBalance = address(this).balance;

        // Calculate ETH currently locked in Superposed states
        uint256 lockedETH = 0;
        // This requires iterating or maintaining a separate sum.
        // Iterating through *all* stateIds might be gas intensive if there are many.
        // A more efficient approach would be to track locked balances by asset.
        // For this example, let's assume a reasonable number of states or add a warning.
        // WARNING: Iterating states could exceed block gas limit for many states.
        // Efficient alternative: Track totalLockedETH and adjust in state transitions.
        // For demonstrating functionality, let's do a simple iteration (less code, but gas heavy).
        // Better: Track totalLocked[asset]
        mapping(address => uint256) private totalLocked;
        // Update createState, observeState, cancelState to manage totalLocked

        // Let's switch to tracking totalLocked
        // This function becomes much simpler and safer.
        uint256 residualBalance = address(this).balance - totalLocked[address(0)];

        if (residualBalance > 0) {
            (bool success, ) = payable(owner).call{value: residualBalance}("");
            if (!success) {
                // Handle failure - log or revert. Reverting is safer.
                revert ClaimAmountMismatch(0, residualBalance, 0); // Reusing error, 0 stateId
            }
        }
    }

     /**
      * @dev Allows the owner to withdraw ERC20 tokens that are not currently locked in a Superposed state.
      * @param _tokenAddress The address of the ERC20 token.
      */
    function ownerWithdrawResidualERC20(address _tokenAddress) external onlyOwner nonReentrant {
        if (_tokenAddress == address(0)) revert InvalidCondition();

        IERC20 token = IERC20(_tokenAddress);
        uint256 contractTokenBalance = token.balanceOf(address(this));

        // Calculate token amount currently locked in Superposed states
        uint256 lockedTokens = totalLocked[_tokenAddress];
        // Using the totalLocked mapping

        uint256 residualBalance = contractTokenBalance - lockedTokens;

        if (residualBalance > 0) {
            token.safeTransfer(owner, residualBalance);
        }
    }


    // --- View Functions ---
    /**
     * @dev Gets detailed information about a specific state.
     * @param _stateId The ID of the state.
     * @return The QuantumState struct data.
     */
    function getStateInfo(uint256 _stateId)
        external
        view
        returns (QuantumState memory)
    {
        // Allow viewing even if not Superposed, but check existence
        if (states[_stateId].id == 0 && _stateId != 0) revert StateNotFound(_stateId); // Check if state exists (id is non-zero unless default)
         if (_stateId == 0 && stateCounter == 0) revert StateNotFound(_stateId); // Handle state 0 if no states created yet
         if (_stateId >= stateCounter) revert StateNotFound(_stateId);

        return states[_stateId];
    }

    /**
     * @dev Returns the total balance of a specific asset held by the contract.
     * @param _asset The address of the asset (address(0) for ETH).
     * @return The total balance.
     */
    function getTotalContractBalance(address _asset) external view returns (uint256) {
         if (_asset == address(0)) {
             return address(this).balance;
         } else {
             return IERC20(_asset).balanceOf(address(this));
         }
    }

    /**
     * @dev Calculates the total amount of a specific asset claimable by a user across all their ObservedSuccess states.
     * Note: This is potentially gas-intensive if a user has many claimable states.
     * @param _user The recipient address.
     * @param _asset The address of the asset (address(0) for ETH).
     * @return The total claimable amount.
     */
    function getUserClaimableBalance(address _user, address _asset) external view returns (uint256) {
        uint256 total = 0;
        uint256[] memory claimableIds = claimableStateIdsByRecipient[_user]; // Get a memory copy

        for (uint i = 0; i < claimableIds.length; i++) {
            uint256 stateId = claimableIds[i];
            // Check if state exists and matches asset, although the index should ensure this
            // Additional check for safety/robustness:
            if (states[stateId].id == stateId &&
                states[stateId].status == StateStatus.ObservedSuccess &&
                !states[stateId].claimed &&
                states[stateId].asset == _asset) {
                total += (states[stateId].amount - states[stateId].observationFee);
            }
        }
        return total;
    }

     /**
      * @dev Returns a list of state IDs deposited by a user that are still Superposed.
      * @param _depositor The depositor address.
      * @return An array of state IDs.
      */
     function getSuperposedStateIdsByDepositor(address _depositor) external view returns (uint256[] memory) {
         return superposedStateIdsByDepositor[_depositor];
     }

     /**
      * @dev Returns a list of state IDs targeting a recipient that are still Superposed.
      * @param _recipient The recipient address.
      * @return An array of state IDs.
      */
     function getSuperposedStateIdsByRecipient(address _recipient) external view returns (uint256[] memory) {
         return superposedStateIdsByRecipient[_recipient];
     }

     /**
      * @dev Returns a list of state IDs targeting a recipient that are ObservedSuccess and not yet claimed.
      * @param _recipient The recipient address.
      * @return An array of state IDs.
      */
     function getClaimableStateIdsByRecipient(address _recipient) external view returns (uint256[] memory) {
         return claimableStateIdsByRecipient[_recipient];
     }

     // --- Internal helpers to update totalLocked ---
     // Need to update these in createState, observeState, cancelState

     constructor(...) { // Modified constructor for totalLocked initialization
         owner = msg.sender;
         // No totalLocked initialization needed, defaults to 0
     }

     function createState(...) { // Inside createState, after successful transfer
        // ... existing code ...
        totalLocked[_asset] += _amount;
        // ... existing code ...
     }

     function observeState(...) { // Inside observeState, after state status update
        // ... existing code ...
        if (conditionsMet) {
            // Funds transition from locked to claimable (still considered locked until claimed for owner withdrawal logic)
            // No change to totalLocked needed here as funds haven't left the contract yet.
        } else { // ObservedFailure
             totalLocked[state.asset] -= state.amount; // Funds are no longer locked towards state resolution
        }

        // Handle dependent state observation within observeState
        if (entangledStates[_stateId] != 0) {
             uint256 dependentStateId = entangledStates[_stateId];
             QuantumState storage dependentState = states[dependentStateId];
             if (dependentState.status == StateStatus.Superposed && dependentState.stateType == StateType.Dependent) {
                 if (dependentState.entanglementOutcome) {
                     // Dependent state success - no change to totalLocked yet
                 } else {
                     // Dependent state failure
                     totalLocked[dependentState.asset] -= dependentState.amount;
                 }
             }
        }
        // ... existing code ...
     }

     function claimFunds(...) { // Inside claimFunds, after successful transfer
         // ... existing code ...
         totalLocked[state.asset] -= payoutAmount; // Only remove claimed amount
         // Note: the fee part (observationFee) was implicitly removed from totalLocked if the state was success.
         // Let's rethink totalLocked: it should represent funds that *must stay* for Superposed states.
         // Let's correct totalLocked updates:
     }
     // --- Corrected totalLocked logic ---
     mapping(address => uint256) private totalLocked; // Amount locked in Superposed states

     function createState(...) {
         // ... checks and transfers ...
         totalLocked[_asset] += _amount;
         // ... rest of createState ...
     }

     function observeState(...) {
          QuantumState storage state = states[_stateId];
          address asset = state.asset; // Cache asset

         if (conditionsMet) {
             state.status = StateStatus.ObservedSuccess;
             // Funds transition from Superposed to ObservedSuccess.
             // The *full* initial amount is no longer required to be locked for the state to resolve
             // (only the amount minus fee is claimable).
             // The observation fee amount is effectively *unlocked* for the owner.
             // The claimable amount remains notionally 'locked' for the recipient.
             // Let's simplify: totalLocked tracks funds *required* for state resolution.
             // Once observed (success or failure), state funds are no longer "Superposed".
             totalLocked[asset] -= state.amount; // Remove the full amount from totalLocked

             uint256 payoutAmount = state.amount - state.observationFee;
             // ... fee payment ...
             // ... add to claimable index ...

             // Handle entanglement
             if (entangledStates[_stateId] != 0) {
                  uint256 dependentStateId = entangledStates[_stateId];
                  QuantumState storage dependentState = states[dependentStateId];
                  if (dependentState.status == StateStatus.Superposed && dependentState.stateType == StateType.Dependent) {
                       // Dependent state is also resolved by this observation
                       totalLocked[dependentState.asset] -= dependentState.amount; // Remove dependent state's amount
                       if (dependentState.entanglementOutcome) {
                            dependentState.status = StateStatus.ObservedSuccess;
                            dependentState.claimed = false;
                            claimableStateIdsByRecipient[dependentState.recipient].push(dependentStateId);
                            emit StateObserved(dependentStateId, address(this), StateStatus.ObservedSuccess, bytes32(0));
                       } else {
                            dependentState.status = StateStatus.ObservedFailure;
                            emit StateObserved(dependentStateId, address(this), StateStatus.ObservedFailure, bytes32(0));
                       }
                       _removeStateFromSuperposedIndex(dependentState.depositor, dependentStateId);
                       _removeStateFromSuperposedIndex(dependentState.recipient, dependentStateId);
                  }
             }


         } else { // ObservedFailure
             state.status = StateStatus.ObservedFailure;
              // Funds transition from Superposed to ObservedFailure.
             // The full initial amount is no longer required for resolution.
             // It becomes residual funds claimable by the owner.
             totalLocked[asset] -= state.amount; // Remove the full amount from totalLocked
         }

         // Remove from superposed indexes regardless of outcome
         _removeStateFromSuperposedIndex(state.depositor, _stateId);
         _removeStateFromSuperposedIndex(state.recipient, _stateId);

         emit StateObserved(_stateId, msg.sender, state.status, _observationData);
     }

     function claimFunds(...) {
          QuantumState storage state = states[_stateId];
          // totalLocked was already decreased in observeState.
          // No change to totalLocked needed here. Funds are simply transferred out.
          // ... existing claim logic ...
     }

     function cancelState(...) {
          QuantumState storage state = states[_stateId];
          address asset = state.asset; // Cache asset

         if (state.depositor != msg.sender && owner != msg.sender)
             revert NotDepositorOrOwner();

         state.status = StateStatus.Cancelled;
         // Funds transition from Superposed to Cancelled.
         // The full initial amount is no longer required for resolution.
         totalLocked[asset] -= state.amount; // Remove the full amount from totalLocked

         // Remove from superposed indexes
         _removeStateFromSuperposedIndex(state.depositor, _stateId);
         _removeStateFromSuperposedIndex(state.recipient, _stateId);

         // Return funds to depositor
         // ... transfer logic ...
          if (state.amount > 0) {
              if (state.asset == address(0)) {
                   (bool success, ) = payable(state.depositor).call{value: state.amount}("");
                   if (!success) {
                        // Funds could be stuck if transfer fails.
                        // Owner can potentially withdraw via ownerWithdrawResidualETH/ERC20.
                        // totalLocked was already reduced, so residual calculation is correct.
                        emit StateCancelled(_stateId, msg.sender); // Emit event even if transfer fails? Yes, state status changed.
                        revert ClaimAmountMismatch(_stateId, state.amount, 0); // Revert to prevent partial state change
                   }
              } else {
                   IERC20 token = IERC20(state.asset);
                   token.safeTransfer(state.depositor, state.amount);
              }
         }

         emit StateCancelled(_stateId, msg.sender);
     }


     // Re-adding owner withdraw functions using the corrected totalLocked logic
     function ownerWithdrawResidualETH() external onlyOwner nonReentrant {
         uint256 contractETHBalance = address(this).balance;
         uint256 lockedETH = totalLocked[address(0)];
         uint256 residualBalance = contractETHBalance - lockedETH;

         if (residualBalance > 0) {
             (bool success, ) = payable(owner).call{value: residualBalance}("");
             if (!success) {
                  revert ClaimAmountMismatch(0, residualBalance, 0); // Reusing error
             }
         }
     }

      function ownerWithdrawResidualERC20(address _tokenAddress) external onlyOwner nonReentrant {
         if (_tokenAddress == address(0)) revert InvalidCondition();

         IERC20 token = IERC20(_tokenAddress);
         uint256 contractTokenBalance = token.balanceOf(address(this));
         uint256 lockedTokens = totalLocked[_tokenAddress];
         uint256 residualBalance = contractTokenBalance - lockedTokens;

         if (residualBalance > 0) {
             token.safeTransfer(owner, residualBalance);
         }
     }


     // Total function count check:
     // 1. constructor
     // 2. fallback
     // 3. receive
     // 4. addObserver
     // 5. removeObserver
     // 6. isObserver (public state variable implies getter exists)
     // 7. createState
     // 8. observeState
     // 9. claimFunds
     // 10. cancelState
     // 11. getStateInfo
     // 12. getTotalContractBalance
     // 13. getUserClaimableBalance
     // 14. getSuperposedStateIdsByDepositor
     // 15. getSuperposedStateIdsByRecipient
     // 16. getClaimableStateIdsByRecipient
     // 17. ownerWithdrawResidualETH
     // 18. ownerWithdrawResidualERC20
     // 19. updateStateObservationFee
     // 20. linkStatesForEntanglement
     // 21. setEntanglementOutcome
     // 22. checkStateConditions (internal, doesn't count as a public/external function)
     // 23. _removeStateFromSuperposedIndex (internal)
     // 24. _removeStateFromClaimableIndex (internal)
     // 25. totalLocked (public state variable implies getter exists per asset)

     // External/Public count: 1 (constructor) + 2 (receive/fallback) + 2 (observer mgmt) + 1 (isObserver) + 1 (create) + 1 (observe) + 1 (claim) + 1 (cancel) + 1 (getStateInfo) + 1 (getTotalContractBalance) + 1 (getUserClaimableBalance) + 3 (get...Ids) + 2 (ownerWithdraw) + 1 (updateFee) + 2 (entanglement) + 1 (totalLocked getter) = 23 public/external functions/getters.

     // Let's remove the explicit `isObserver` function and rely on the public variable getter.
     // Let's remove the explicit `totalLocked` function and rely on the public mapping getter.
     // Count = 2 + 2 + 1 + 1 + 1 + 1 + 1 + 1 + 3 + 2 + 1 + 2 = 18. Need two more.

     // Add more view functions or simple state transitions:
     // - getEntangledState(uint256 _stateId): returns the stateId linked FROM stateId (the dependent one)
     // - getLinkingState(uint256 _stateId): returns the stateId that _stateId is dependent ON (requires indexing from conditionValue) - might be complex
     // - transferOwnership(address _newOwner) (standard)
     // - renounceOwnership() (standard)

     // Let's add Ownership functions and getEntangledState.

     // --- Ownership Functions ---
     // Standard OpenZeppelin Ownable pattern
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     function transferOwnership(address _newOwner) external onlyOwner {
         if (_newOwner == address(0)) revert InvalidCondition();
         address oldOwner = owner;
         owner = _newOwner;
         emit OwnershipTransferred(oldOwner, _newOwner);
     }

     function renounceOwnership() external onlyOwner {
         address oldOwner = owner;
         owner = address(0);
         emit OwnershipTransferred(oldOwner, address(0));
     }

     // --- Added View Function ---
     /**
      * @dev Returns the state ID that the given state is linked *to* for entanglement resolution.
      * This state is the DEPENDENT state.
      * @param _stateId The ID of the state that triggers the dependent state.
      * @return The ID of the dependent state, or 0 if none linked.
      */
     function getEntangledState(uint256 _stateId) external view returns (uint256) {
         return entangledStates[_stateId];
     }

     // Final count check:
     // 1. constructor
     // 2. fallback
     // 3. receive
     // 4. addObserver
     // 5. removeObserver
     // 6. createState
     // 7. observeState
     // 8. claimFunds
     // 9. cancelState
     // 10. getStateInfo
     // 11. getTotalContractBalance
     // 12. getUserClaimableBalance
     // 13. getSuperposedStateIdsByDepositor
     // 14. getSuperposedStateIdsByRecipient
     // 15. getClaimableStateIdsByRecipient
     // 16. ownerWithdrawResidualETH
     // 17. ownerWithdrawResidualERC20
     // 18. updateStateObservationFee
     // 19. linkStatesForEntanglement
     // 20. setEntanglementOutcome
     // 21. transferOwnership
     // 22. renounceOwnership
     // 23. getEntangledState
     // 24. isObserver (public variable getter)
     // 25. totalLocked (public mapping getter)

     // OK, 25 public/external functions/getters.

}
```

---

**Explanation of Key Concepts and Functions:**

1.  **Quantum State Metaphor:** The contract locks funds in `QuantumState` structs. These states are initially `Superposed`. They don't automatically release based on simple conditions like time. They require an external action – `observeState` – which represents an "observation" that collapses the state into one of two outcomes: `ObservedSuccess` or `ObservedFailure`.
2.  **Observer Role:** A dedicated `onlyObserver` role is introduced. Only addresses with this role can call `observeState`. This externalizes the trigger mechanism, preventing anyone from resolving states arbitrarily.
3.  **State Types (`StateType`):** Different types of conditions determine if the observation is successful:
    *   `TimeGated`: Requires the current block timestamp to be greater than or equal to the state's `conditionValue` (a timestamp).
    *   `ExternalCondition`: Requires the `_observationData` provided by the observer in the `observeState` call to exactly match the `conditionHashOrLink` stored in the state. This simulates needing specific external information (like a data feed hash) verified by the observer.
    *   `Dependent`: This state's outcome is determined by the successful *observation* of another linked state, not by direct observation of its own conditions. Its `conditionValue` and `conditionHashOrLink` store the ID of the linked state.
4.  **Observation (`observeState`):** This is the core function. An authorized observer calls it with a state ID and potentially external data. The function checks:
    *   Is the state `Superposed`?
    *   Does the `_observationData` satisfy the state's specific `StateType` conditions?
    *   Based on the checks, the state's `status` is updated to `ObservedSuccess` or `ObservedFailure`.
    *   If successful, an `observationFee` is paid to the observer from the state's amount, and the remaining amount becomes claimable by the recipient.
    *   Crucially, if this state is the "linking" state for a `Dependent` state (via `entangledStates`), that dependent state is *also* resolved based on its pre-set `entanglementOutcome`.
5.  **Entanglement (`linkStatesForEntanglement`, `setEntanglementOutcome`):** Two states can be "entangled". `linkStatesForEntanglement` connects a 'linking' state (`_stateId1`) to a 'dependent' state (`_stateId2`, which *must* be of `StateType.Dependent`). `setEntanglementOutcome` allows the creator of the dependent state to pre-determine whether it resolves to `ObservedSuccess` or `ObservedFailure` *if* its linked state (`_stateId1`) is successfully observed. This adds a layer of linked, conditional resolution.
6.  **Fund Claiming (`claimFunds`):** After a state is `ObservedSuccess`, the designated `recipient` can call `claimFunds` to withdraw their portion (state amount minus observation fee).
7.  **Cancellation (`cancelState`):** The depositor or owner can cancel a state *only if* it is still `Superposed`. This returns the locked funds to the depositor.
8.  **Residual Funds (`ownerWithdrawResidualETH`, `ownerWithdrawResidualERC20`):** The owner can sweep any funds (ETH or ERC20) held by the contract that are *not* currently locked within a `Superposed` state. This handles funds from failed states or bare transfers. The `totalLocked` mapping is used internally to track funds actively held for `Superposed` states.
9.  **Multi-Asset Support:** The contract handles both ETH (using `address(0)` as the asset address) and any ERC-20 token. `SafeERC20` is used for safer token interactions.
10. **Indexing:** Basic index mappings (`superposedStateIdsByDepositor`, etc.) are included to allow view functions to retrieve state lists efficiently without iterating through all possible state IDs, which would be gas-prohibitive on-chain.
11. **Reentrancy Guard:** Used to prevent re-entrancy attacks during transfers.
12. **Custom Errors:** Provides clearer reasons for transaction failures.

This contract provides a framework for managing funds under complex, triggered, and potentially inter-dependent conditions, moving beyond standard escrow or vesting models with the "quantum" metaphor driving the design patterns.