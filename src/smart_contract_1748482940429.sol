Okay, let's design a smart contract based on the idea of a "Conditional, Time-Sensitive Swap with State Transitions", using a "Quantum Entanglement" metaphor. It involves two parties depositing tokens which become "entangled", and can only be "collapsed" (swapped) if a specific on-chain condition is met before a deadline. If the deadline passes without the condition being met, the entanglement "decoheres", and parties can withdraw their original deposits.

This incorporates:
*   **State Machine:** The entanglement progresses through distinct states (Setup, Accepted, Deposited, Entangled, Collapsed, Decohered, Cancelled).
*   **Conditional Logic:** Swaps depend on meeting a defined on-chain condition.
*   **Time Sensitivity:** Deadlines force state transitions (Decoherence).
*   **Two-Party Protocol:** Requires interaction from two distinct addresses.
*   **Escrow:** Holds funds securely during the process.
*   **Extensibility:** Condition types can be expanded.
*   **Access Control:** Different functions callable by parties, admin, or anyone.
*   **Advanced ERC20 Handling:** Using `SafeERC20`.
*   **Reentrancy Guard:** Standard security.
*   **Pausability:** Admin control.

This is not a direct copy of common patterns like Uniswap, simple escrows, or NFT minting/trading, as the core mechanism is the conditional, time-bound, multi-stage swap protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title QuantumEntanglementSwap
 * @dev A smart contract for executing conditional and time-sensitive token swaps
 *      between two parties, modeled using a "Quantum Entanglement" metaphor.
 *      Parties deposit tokens which are 'entangled'. The swap ('collapse') only
 *      occurs if a predefined on-chain condition is met before a deadline.
 *      Otherwise, the 'entanglement decoheres', allowing parties to withdraw
 *      their initial deposits.
 */

// --- OUTLINE & FUNCTION SUMMARY ---
/*
 Outline:
 1.  State Definitions (Enums for EntanglementState, ConditionType)
 2.  Struct for Entanglement details (parties, tokens, amounts, condition, deadline, state, flags)
 3.  State Variables (mapping for entanglements, counter for IDs, internal state counter, admin)
 4.  Events for tracking key lifecycle changes
 5.  Modifiers for access control and state checks
 6.  Constructor
 7.  Core Lifecycle Functions:
     - proposeEntanglement: Initiate a new swap proposal (Party A)
     - acceptEntanglement: Accept a proposal (Party B)
     - depositTokenA: Party A deposits their token
     - depositTokenB: Party B deposits their token
     - checkAndEntangle: Move state to Entangled once deposits match
     - collapseEntanglement: Attempt to execute the swap if condition met before deadline (callable by anyone)
     - cancelEntanglement: Cancel proposal/deposit before Entangled state (Party A or B)
     - withdrawCancelled: Withdraw deposited tokens after cancellation
     - withdrawDecohered: Withdraw deposited tokens after deadline and unmet condition (Party A or B)
     - withdrawExcessDeposits: Withdraw any tokens deposited beyond the required amount
 8.  Condition Management Functions:
     - incrementInternalState: Increment an internal counter used for condition checks (Admin)
     - setInternalState: Set the internal counter directly (Admin)
 9.  View Functions:
     - getEntanglement: Get details of an entanglement
     - getCurrentState: Get current state enum
     - canCollapse: Check if collapse condition is currently met and within deadline
     - canWithdrawDecohered: Check if decoherence withdrawal is possible
     - canWithdrawCancelled: Check if cancellation withdrawal is possible
     - isEntanglementSetup: State check helper
     - isEntanglementAccepted: State check helper
     - isEntanglementDeposited: State check helper (either party deposited)
     - isEntangled: State check helper
     - isCollapsed: State check helper
     - isDecohered: State check helper
     - isCancelled: State check helper
     - isTimestampConditionMet: Check timestamp condition
     - isOraclePriceConditionMet: Check oracle price condition (placeholder/mocked)
     - isInternalStateConditionMet: Check internal state condition
     - getDepositedAmount: Get amount deposited by a specific party for a token
     - getNextEntanglementId: Get the next available ID
     - getEntanglementCount: Get total created entanglements
     - getEntanglementsForParty: List entanglement IDs involving a party (helper - potentially costly)
     - getInternalState: Get the current internal state counter value
 10. Admin Functions:
     - pause: Pause contract functionality (Admin)
     - unpause: Unpause contract functionality (Admin)
     - withdrawStuckTokens: Rescue accidentally sent ERC20 tokens (Admin)
     - setOracleAddress: Set address for oracle condition (Admin - placeholder)

 Function Summary:
 - `proposeEntanglement(address _partyB, address _tokenA, uint256 _amountA, address _tokenB, uint256 _amountB, uint8 _conditionType, uint256 _conditionValue, uint256 _deadline)`: Creates a new entanglement proposal (State: Setup). Callable by Party A.
 - `acceptEntanglement(uint256 _entanglementId)`: Party B accepts a proposal (State: Accepted). Callable by Party B.
 - `depositTokenA(uint256 _entanglementId)`: Party A transfers `_amountA` of `_tokenA` to the contract. Callable by Party A.
 - `depositTokenB(uint256 _entanglementId)`: Party B transfers `_amountB` of `_tokenB` to the contract. Callable by Party B.
 - `checkAndEntangle(uint256 _entanglementId)`: Checks if both parties have deposited sufficient tokens and moves state to Entangled. Callable by either party.
 - `collapseEntanglement(uint256 _entanglementId)`: Checks condition and deadline. If met, performs the swap (transfers tokens) and sets state to Collapsed. Callable by anyone.
 - `cancelEntanglement(uint256 _entanglementId)`: Allows Party A or B to cancel before state is Entangled. Sets state to Cancelled.
 - `withdrawCancelled(uint256 _entanglementId)`: Allows parties to withdraw their deposited tokens after cancellation. Callable by Party A or B.
 - `withdrawDecohered(uint256 _entanglementId)`: Allows parties to withdraw their deposited tokens if the deadline is past and condition unmet (from Entangled state). Sets state to Decohered. Callable by Party A or B.
 - `withdrawExcessDeposits(uint256 _entanglementId, address _token)`: Allows a party to withdraw any amount deposited for a specific token that exceeds the required amount for the entanglement. Callable by the depositor.
 - `incrementInternalState(uint256 _by)`: Increments the contract's internal counter. Used for `ConditionType.InternalState`. Callable by Owner.
 - `setInternalState(uint256 _value)`: Sets the contract's internal counter to a specific value. Callable by Owner.
 - `getEntanglement(uint256 _entanglementId)`: Returns all details of an entanglement. View function.
 - `getCurrentState(uint256 _entanglementId)`: Returns the current state enum of an entanglement. View function.
 - `canCollapse(uint256 _entanglementId)`: Returns true if the entanglement is in the Entangled state, the condition is met, and the deadline is not passed. View function.
 - `canWithdrawDecohered(uint256 _entanglementId)`: Returns true if the entanglement is in the Entangled state, the deadline is past, and the condition was not met. View function.
 - `canWithdrawCancelled(uint256 _entanglementId)`: Returns true if the entanglement is in the Cancelled state. View function.
 - `isEntanglementSetup(uint256 _id)`: Returns true if state is Setup. View function.
 - `isEntanglementAccepted(uint256 _id)`: Returns true if state is Accepted. View function.
 - `isEntanglementDeposited(uint256 _id)`: Returns true if state is Accepted and at least one party has deposited. View function.
 - `isEntangled(uint256 _id)`: Returns true if state is Entangled. View function.
 - `isCollapsed(uint256 _id)`: Returns true if state is Collapsed. View function.
 - `isDecohered(uint256 _id)`: Returns true if state is Decohered. View function.
 - `isCancelled(uint256 _id)`: Returns true if state is Cancelled. View function.
 - `isTimestampConditionMet(uint256 _id)`: Checks if current timestamp >= conditionValue. View function.
 - `isOraclePriceConditionMet(uint256 _id)`: Checks a mock oracle price condition. View function.
 - `isInternalStateConditionMet(uint256 _id)`: Checks if internal counter >= conditionValue. View function.
 - `getDepositedAmount(uint256 _entanglementId, address _party, address _token)`: Returns the amount deposited by `_party` for `_token` in entanglement `_entanglementId`. View function.
 - `getNextEntanglementId()`: Returns the ID for the next proposed entanglement. View function.
 - `getEntanglementCount()`: Returns the total number of entanglements created. View function.
 - `getEntanglementsForParty(address _party)`: Returns an array of entanglement IDs involving `_party`. View function (caution: potentially high gas).
 - `getInternalState()`: Returns the current value of the internal state counter. View function.
 - `pause()`: Pauses contract operations (certain functions). Callable by Owner.
 - `unpause()`: Unpauses contract operations. Callable by Owner.
 - `withdrawStuckTokens(address _token, uint256 _amount)`: Allows owner to withdraw accidentally sent tokens. Callable by Owner.
 - `setOracleAddress(address _oracle)`: Sets the address of a mock oracle (for future expansion). Callable by Owner.
*/

// --- CONTRACT BODY ---

enum EntanglementState {
    Setup,          // Party A proposed
    Accepted,       // Party B accepted
    Accepted_A_Deposited, // Accepted, A deposited
    Accepted_B_Deposited, // Accepted, B deposited
    Entangled,      // Both deposited, ready for collapse or decoherence
    Collapsed,      // Swap executed successfully
    Decohered,      // Deadline passed, condition unmet, original tokens withdrawn
    Cancelled       // Cancelled before Entangled state
}

enum ConditionType {
    Timestamp,          // ConditionValue is a future timestamp (condition met if block.timestamp >= conditionValue)
    OraclePriceGreater, // ConditionValue is a price threshold (condition met if oracle price > conditionValue) - Mocked
    OraclePriceLess,    // ConditionValue is a price threshold (condition met if oracle price < conditionValue) - Mocked
    InternalState       // ConditionValue is a counter threshold (condition met if internalState >= conditionValue)
}

struct Entanglement {
    address partyA;
    address partyB;
    IERC20 tokenA;
    uint256 amountA;
    IERC20 tokenB;
    uint256 amountB;
    ConditionType conditionType;
    uint256 conditionValue;
    uint256 deadline; // Timestamp
    EntanglementState state;
    // Flags to prevent double withdrawal in Decohered state
    bool aWithdrewDecohered;
    bool bWithdrewDecohered;
    // Flags to prevent double withdrawal in Cancelled state
    bool aWithdrewCancelled;
    bool bWithdrewCancelled;
}

mapping(uint256 => Entanglement) public entanglements;
uint256 private nextEntanglementId = 1;

// To track deposited amounts before the final checkAndEntangle
// entanglementId => partyAddress => tokenAddress => amount
mapping(uint256 => mapping(address => mapping(address => uint256))) private depositedAmounts;

uint256 public internalStateCounter = 0; // Used for InternalState condition

// Placeholder for oracle address (e.g., Chainlink AggregatorV3Interface)
address public oracleAddress;

// Mapping to help find entanglements for a party (can be gas-intensive if lists are large)
mapping(address => uint256[]) private partyEntanglementIds;

event EntanglementProposed(uint256 indexed id, address indexed partyA, address indexed partyB, address tokenA, uint256 amountA, address tokenB, uint256 amountB, uint8 conditionType, uint256 conditionValue, uint256 deadline);
event EntanglementAccepted(uint256 indexed id, address indexed partyB);
event TokenDeposited(uint256 indexed id, address indexed depositor, address indexed token, uint256 amount);
event EntanglementCreated(uint256 indexed id); // State moved to Entangled
event EntanglementCollapsed(uint256 indexed id); // Swap executed
event EntanglementDecohered(uint256 indexed id); // Deadline passed, condition unmet
event EntanglementCancelled(uint256 indexed id); // Cancelled before entangled
event WithdrawalProcessed(uint256 indexed id, address indexed party, address indexed token, uint256 amount);
event ExcessWithdrawal(uint256 indexed id, address indexed party, address indexed token, uint256 amount);
event InternalStateUpdated(uint256 indexed newValue);
event OracleAddressUpdated(address indexed newOracle);

// --- MODIFIERS ---

modifier onlyPartyA(uint256 _id) {
    require(entanglements[_id].partyA == msg.sender, "Not party A");
    _;
}

modifier onlyPartyB(uint256 _id) {
    require(entanglements[_id].partyB == msg.sender, "Not party B");
    _;
}

modifier onlyParties(uint256 _id) {
    require(entanglements[_id].partyA == msg.sender || entanglements[_id].partyB == msg.sender, "Not a party in this entanglement");
    _;
}

modifier whenState(uint256 _id, EntanglementState _state) {
    require(entanglements[_id].state == _state, "Invalid state for this action");
    _;
}

modifier notState(uint256 _id, EntanglementState _state) {
    require(entanglements[_id].state != _state, "Action not allowed in this state");
    _;
}

// Placeholder modifier for condition check (actual check in internal function)
modifier whenConditionMet(uint256 _id) {
    require(_checkConditionMet(_id), "Condition not met");
    _;
}

modifier withinDeadline(uint256 _id) {
    require(block.timestamp <= entanglements[_id].deadline, "Deadline passed");
    _;
}

modifier afterDeadline(uint256 _id) {
    require(block.timestamp > entanglements[_id].deadline, "Deadline not passed yet");
    _;
}

// --- CONSTRUCTOR ---

constructor(address initialOracleAddress) Ownable(msg.sender) Pausable() {
    // Initial oracle address can be set here or later via setOracleAddress
    oracleAddress = initialOracleAddress;
}

// --- CORE LIFECYCLE FUNCTIONS ---

/**
 * @dev Party A proposes a new conditional swap entanglement.
 * @param _partyB The address of Party B.
 * @param _tokenA The address of the token Party A offers.
 * @param _amountA The amount of _tokenA Party A offers.
 * @param _tokenB The address of the token Party B offers.
 * @param _amountB The amount of _tokenB Party B offers.
 * @param _conditionType The type of condition to check for collapse (0=Timestamp, 1=OraclePriceGreater, 2=OraclePriceLess, 3=InternalState).
 * @param _conditionValue The value associated with the condition (e.g., timestamp, price threshold, counter value).
 * @param _deadline The timestamp by which the condition must be met.
 * @return uint256 The ID of the newly created entanglement proposal.
 */
function proposeEntanglement(
    address _partyB,
    address _tokenA,
    uint256 _amountA,
    address _tokenB,
    uint256 _amountB,
    uint8 _conditionType,
    uint256 _conditionValue,
    uint256 _deadline
)
    external
    whenNotPaused
    returns (uint256)
{
    require(_partyB != address(0) && _partyB != msg.sender, "Invalid Party B address");
    require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
    require(_amountA > 0 && _amountB > 0, "Amounts must be greater than zero");
    require(_deadline > block.timestamp, "Deadline must be in the future");
    require(_conditionType <= uint8(ConditionType.InternalState), "Invalid condition type");
    if (ConditionType(_conditionType) >= ConditionType.OraclePriceGreater && ConditionType(_conditionType) <= ConditionType.OraclePriceLess) {
        require(oracleAddress != address(0), "Oracle address not set for this condition type");
    }

    uint256 id = nextEntanglementId++;

    entanglements[id] = Entanglement({
        partyA: msg.sender,
        partyB: _partyB,
        tokenA: IERC20(_tokenA),
        amountA: _amountA,
        tokenB: IERC20(_tokenB),
        amountB: _amountB,
        conditionType: ConditionType(_conditionType),
        conditionValue: _conditionValue,
        deadline: _deadline,
        state: EntanglementState.Setup,
        aWithdrewDecohered: false,
        bWithdrewDecohered: false,
        aWithdrewCancelled: false,
        bWithdrewCancelled: false
    });

    // Track this entanglement for both parties
    partyEntanglementIds[msg.sender].push(id);
    partyEntanglementIds[_partyB].push(id);

    emit EntanglementProposed(id, msg.sender, _partyB, _tokenA, _amountA, _tokenB, _amountB, _conditionType, _conditionValue, _deadline);

    return id;
}

/**
 * @dev Party B accepts an entanglement proposal.
 * @param _entanglementId The ID of the proposal to accept.
 */
function acceptEntanglement(uint256 _entanglementId)
    external
    whenNotPaused
    onlyPartyB(_entanglementId)
    whenState(_entanglementId, EntanglementState.Setup)
{
    entanglements[_entanglementId].state = EntanglementState.Accepted;
    emit EntanglementAccepted(_entanglementId, msg.sender);
}

/**
 * @dev Party A deposits the required amount of their token.
 * @param _entanglementId The ID of the entanglement.
 */
function depositTokenA(uint256 _entanglementId)
    external
    whenNotPaused
    onlyPartyA(_entanglementId)
    notState(_entanglementId, EntanglementState.Entangled) // Cannot deposit if already Entangled (both deposited)
    notState(_entanglementId, EntanglementState.Collapsed)
    notState(_entanglementId, EntanglementState.Decohered)
    notState(_entanglementId, EntanglementState.Cancelled)
{
    Entanglement storage entanglement = entanglements[_entanglementId];
    require(entanglement.state == EntanglementState.Accepted || entanglement.state == EntanglementState.Accepted_B_Deposited, "Invalid state for deposit");

    uint256 requiredAmount = entanglement.amountA;
    uint256 currentDeposit = depositedAmounts[_entanglementId][msg.sender][address(entanglement.tokenA)];
    uint256 amountToTransfer = requiredAmount - currentDeposit;

    require(amountToTransfer > 0, "Amount already deposited");

    // Transfer tokens from Party A to the contract
    SafeERC20.safeTransferFrom(entanglement.tokenA, msg.sender, address(this), amountToTransfer);

    depositedAmounts[_entanglementId][msg.sender][address(entanglement.tokenA)] += amountToTransfer;

    // Update state based on whether Party B has already deposited
    if (entanglement.state == EntanglementState.Accepted) {
         entanglement.state = EntanglementState.Accepted_A_Deposited;
    } else if (entanglement.state == EntanglementState.Accepted_B_Deposited) {
         // This case means A deposited AFTER B, potentially making both deposited.
         // checkAndEntangle will handle the transition to Entangled.
    }


    emit TokenDeposited(_entanglementId, msg.sender, address(entanglement.tokenA), amountToTransfer);
}

/**
 * @dev Party B deposits the required amount of their token.
 * @param _entanglementId The ID of the entanglement.
 */
function depositTokenB(uint256 _entanglementId)
    external
    whenNotPaused
    onlyPartyB(_entanglementId)
    notState(_entanglementId, EntanglementState.Entangled) // Cannot deposit if already Entangled (both deposited)
    notState(_entanglementId, EntanglementState.Collapsed)
    notState(_entanglementId, EntanglementState.Decohered)
    notState(_entanglementId, EntanglementState.Cancelled)
{
    Entanglement storage entanglement = entanglements[_entanglementId];
    require(entanglement.state == EntanglementState.Accepted || entanglement.state == EntanglementState.Accepted_A_Deposited, "Invalid state for deposit");

    uint256 requiredAmount = entanglement.amountB;
    uint256 currentDeposit = depositedAmounts[_entanglementId][msg.sender][address(entanglement.tokenB)];
    uint256 amountToTransfer = requiredAmount - currentDeposit;

    require(amountToTransfer > 0, "Amount already deposited");

    // Transfer tokens from Party B to the contract
    SafeERC20.safeTransferFrom(entanglement.tokenB, msg.sender, address(this), amountToTransfer);

    depositedAmounts[_entanglementId][msg.sender][address(entanglement.tokenB)] += amountToTransfer;

    // Update state based on whether Party A has already deposited
    if (entanglement.state == EntanglementState.Accepted) {
         entanglement.state = EntanglementState.Accepted_B_Deposited;
    } else if (entanglement.state == EntanglementState.Accepted_A_Deposited) {
         // This case means B deposited AFTER A, potentially making both deposited.
         // checkAndEntangle will handle the transition to Entangled.
    }

    emit TokenDeposited(_entanglementId, msg.sender, address(entanglement.tokenB), amountToTransfer);
}

/**
 * @dev Checks if both parties have deposited the required amounts and, if so, moves the state to Entangled.
 *      Can be called by either party after deposits are potentially complete.
 * @param _entanglementId The ID of the entanglement.
 */
function checkAndEntangle(uint256 _entanglementId)
    external
    whenNotPaused
    onlyParties(_entanglementId)
    whenState(_entanglementId, EntanglementState.Accepted_A_Deposited)
{
    Entanglement storage entanglement = entanglements[_entanglementId];

    // Re-check state - could have been Accepted_B_Deposited if B deposited last
    require(entanglement.state == EntanglementState.Accepted_A_Deposited || entanglement.state == EntanglementState.Accepted_B_Deposited, "Invalid state for check and entangle");

    uint256 depositedA = depositedAmounts[_entanglementId][entanglement.partyA][address(entanglement.tokenA)];
    uint256 depositedB = depositedAmounts[_entanglementId][entanglement.partyB][address(entanglement.tokenB)];

    // Check if at least the required amounts are deposited
    if (depositedA >= entanglement.amountA && depositedB >= entanglement.amountB) {
        entanglement.state = EntanglementState.Entangled;
        // Note: We do *not* clear depositedAmounts here. It's needed for withdrawExcessDeposits later.
        emit EntanglementCreated(_entanglementId);
    }
    // If not enough deposited, state remains as is, and users need to deposit more or cancel.
}


/**
 * @dev Attempts to collapse the entanglement (perform the swap).
 *      This can be called by anyone once the state is Entangled.
 * @param _entanglementId The ID of the entanglement.
 */
function collapseEntanglement(uint256 _entanglementId)
    external
    whenNotPaused
    whenState(_entanglementId, EntanglementState.Entangled)
    withinDeadline(_entanglementId) // Condition must be met *before* or *at* the deadline
    whenConditionMet(_entanglementId) // Condition must be met
    nonReentrant // Prevent reentrancy issues during token transfers
{
    Entanglement storage entanglement = entanglements[_entanglementId];

    // Perform the swap (transfer tokens held by the contract)
    SafeERC20.safeTransfer(entanglement.tokenA, entanglement.partyB, entanglement.amountA);
    SafeERC20.safeTransfer(entanglement.tokenB, entanglement.partyA, entanglement.amountB);

    entanglement.state = EntanglementState.Collapsed;

    // Clear relevant deposit tracking after successful collapse
    delete depositedAmounts[_entanglementId][entanglement.partyA][address(entanglement.tokenA)];
    delete depositedAmounts[_entanglementId][entanglement.partyB][address(entanglement.tokenB)];

    emit EntanglementCollapsed(_entanglementId);
}

/**
 * @dev Allows a party to cancel the entanglement before it reaches the Entangled state.
 * @param _entanglementId The ID of the entanglement to cancel.
 */
function cancelEntanglement(uint256 _entanglementId)
    external
    whenNotPaused
    onlyParties(_entanglementId)
    notState(_entanglementId, EntanglementState.Entangled) // Cannot cancel after Entangled
    notState(_entanglementId, EntanglementState.Collapsed)
    notState(_entanglementId, EntanglementState.Decohered)
    notState(_entanglementId, EntanglementState.Cancelled)
{
    // Allowed states for cancellation are Setup, Accepted, Accepted_A_Deposited, Accepted_B_Deposited
    entanglements[_entanglementId].state = EntanglementState.Cancelled;
    emit EntanglementCancelled(_entanglementId);
}

/**
 * @dev Allows a party to withdraw their deposited tokens after cancellation.
 * @param _entanglementId The ID of the cancelled entanglement.
 */
function withdrawCancelled(uint256 _entanglementId)
    external
    whenNotPaused
    onlyParties(_entanglementId)
    whenState(_entanglementId, EntanglementState.Cancelled)
    nonReentrant
{
    Entanglement storage entanglement = entanglements[_entanglementId];
    address party = msg.sender;

    if (party == entanglement.partyA) {
        require(!entanglement.aWithdrewCancelled, "Party A already withdrew");
        entanglement.aWithdrewCancelled = true;
        IERC20 token = entanglement.tokenA;
        uint256 amount = depositedAmounts[_entanglementId][party][address(token)];
        require(amount > 0, "No tokens to withdraw for Party A");

        delete depositedAmounts[_entanglementId][party][address(token)];
        SafeERC20.safeTransfer(token, party, amount);
        emit WithdrawalProcessed(_entanglementId, party, address(token), amount);

    } else if (party == entanglement.partyB) {
         require(!entanglement.bWithdrewCancelled, "Party B already withdrew");
        entanglement.bWithdrewCancelled = true;
        IERC20 token = entanglement.tokenB;
        uint256 amount = depositedAmounts[_entanglementId][party][address(token)];
        require(amount > 0, "No tokens to withdraw for Party B");

        delete depositedAmounts[_entanglementId][party][address(token)];
        SafeERC20.safeTransfer(token, party, amount);
        emit WithdrawalProcessed(_entanglementId, party, address(token), amount);
    }
}


/**
 * @dev Allows a party to withdraw their deposited tokens if the entanglement decohered
 *      (deadline passed and condition was not met from Entangled state).
 * @param _entanglementId The ID of the decohered entanglement.
 */
function withdrawDecohered(uint256 _entanglementId)
    external
    whenNotPaused
    onlyParties(_entanglementId)
    whenState(_entanglementId, EntanglementState.Entangled) // Must be in Entangled state when calling
    afterDeadline(_entanglementId) // Deadline must have passed
    notState(_entanglementId, EntanglementState.Collapsed) // Must not have collapsed
    nonReentrant
{
    // Check if the condition was NOT met at the time of withdrawal
    require(!_checkConditionMet(_entanglementId), "Condition was met before deadline");

    Entanglement storage entanglement = entanglements[_entanglementId];
    address party = msg.sender;

    // Set state to Decohered on first withdrawal attempt
    if (entanglement.state == EntanglementState.Entangled) {
        entanglement.state = EntanglementState.Decohered;
        emit EntanglementDecohered(_entanglementId);
    }

    // Process withdrawal based on which party is calling
    if (party == entanglement.partyA) {
        require(!entanglement.aWithdrewDecohered, "Party A already withdrew decohered tokens");
        entanglement.aWithdrewDecohered = true;
        IERC20 token = entanglement.tokenA;
        // Withdraw the original required amount
        uint256 amount = entanglement.amountA;
        // Ensure the contract actually holds at least this amount deposited by A
        // (This check is implicitly covered by the fact it reached Entangled state)
        // Safe transfer will revert if balance is insufficient.

        SafeERC20.safeTransfer(token, party, amount);
        emit WithdrawalProcessed(_entanglementId, party, address(token), amount);

    } else if (party == entanglement.partyB) {
        require(!entanglement.bWithdrewDecohered, "Party B already withdrew decohered tokens");
        entanglement.bWithdrewDecohered = true;
        IERC20 token = entanglement.tokenB;
         // Withdraw the original required amount
        uint256 amount = entanglement.amountB;
         // Ensure the contract actually holds at least this amount deposited by B

        SafeERC20.safeTransfer(token, party, amount);
        emit WithdrawalProcessed(_entanglementId, party, address(token), amount);
    }

    // Note: Excess deposits are handled by withdrawExcessDeposits
}

/**
 * @dev Allows a party to withdraw any tokens they deposited beyond the required amount
 *      for an entanglement, provided the entanglement is not Collapsed.
 * @param _entanglementId The ID of the entanglement.
 * @param _token The address of the token to withdraw excess for.
 */
function withdrawExcessDeposits(uint256 _entanglementId, address _token)
    external
    whenNotPaused
    onlyParties(_entanglementId)
    notState(_entanglementId, EntanglementState.Collapsed) // Excess is gone after collapse
    nonReentrant
{
    Entanglement storage entanglement = entanglements[_entanglementId];
    address party = msg.sender;
    IERC20 token = IERC20(_token);

    uint256 requiredAmount = 0;
    if (party == entanglement.partyA && address(token) == address(entanglement.tokenA)) {
        requiredAmount = entanglement.amountA;
    } else if (party == entanglement.partyB && address(token) == address(entanglement.tokenB)) {
        requiredAmount = entanglement.amountB;
    } else {
        revert("Cannot withdraw excess of this token for this party");
    }

    uint256 deposited = depositedAmounts[_entanglementId][party][address(token)];
    uint256 excessAmount = deposited > requiredAmount ? deposited - requiredAmount : 0;

    require(excessAmount > 0, "No excess tokens deposited");

    // Update depositedAmounts to reflect the withdrawal
    depositedAmounts[_entanglementId][party][address(token)] = requiredAmount;

    SafeERC20.safeTransfer(token, party, excessAmount);
    emit ExcessWithdrawal(_entanglementId, party, address(token), excessAmount);
}


// --- CONDITION MANAGEMENT FUNCTIONS ---

/**
 * @dev Increments the internal state counter. Used for ConditionType.InternalState.
 * @param _by The amount to increment the counter by.
 */
function incrementInternalState(uint256 _by) external onlyOwner whenNotPaused {
    internalStateCounter += _by;
    emit InternalStateUpdated(internalStateCounter);
}

/**
 * @dev Sets the internal state counter to a specific value. Used for ConditionType.InternalState.
 * @param _value The value to set the counter to.
 */
function setInternalState(uint256 _value) external onlyOwner whenNotPaused {
    internalStateCounter = _value;
    emit InternalStateUpdated(internalStateCounter);
}

// --- INTERNAL CONDITION CHECK ---

/**
 * @dev Internal function to check if the entanglement's condition is met.
 * @param _entanglementId The ID of the entanglement.
 * @return bool True if the condition is met, false otherwise.
 */
function _checkConditionMet(uint256 _entanglementId) internal view returns (bool) {
    Entanglement storage entanglement = entanglements[_entanglementId];

    if (entanglement.state != EntanglementState.Entangled) {
        // Condition can only be met when Entangled (ready for collapse)
        return false;
    }

    // Check based on condition type
    if (entanglement.conditionType == ConditionType.Timestamp) {
        return block.timestamp >= entanglement.conditionValue;
    } else if (entanglement.conditionType == ConditionType.OraclePriceGreater) {
        // Mocked oracle call - in a real contract, interact with a Chainlink Aggregator or similar
        // Assume oracleAddress is a contract that has a `latestAnswer()` function returning int256
        // For this example, we'll just use the oracleAddress value itself as a mock price feed identifier
        // and use the internalStateCounter as the "mock oracle price". This is purely illustrative.
        // A real implementation would involve an interface and a call like `AggregatorV3Interface(oracleAddress).latestAnswer()`
        // require(oracleAddress != address(0), "Oracle address not set"); // Already checked in propose
        // int256 price = AggregatorV3Interface(oracleAddress).latestAnswer();
        // return price > int256(entanglement.conditionValue);
        // Using internalStateCounter as mock price:
        return internalStateCounter > entanglement.conditionValue;

    } else if (entanglement.conditionType == ConditionType.OraclePriceLess) {
         // require(oracleAddress != address(0), "Oracle address not set"); // Already checked in propose
         // int256 price = AggregatorV3Interface(oracleAddress).latestAnswer();
         // return price < int256(entanglement.conditionValue);
         // Using internalStateCounter as mock price:
         return internalStateCounter < entanglement.conditionValue;

    } else if (entanglement.conditionType == ConditionType.InternalState) {
        return internalStateCounter >= entanglement.conditionValue;
    }

    return false; // Should not reach here
}


// --- VIEW FUNCTIONS ---

/**
 * @dev Gets the full details of an entanglement.
 * @param _entanglementId The ID of the entanglement.
 * @return tuple Containing all entanglement data.
 */
function getEntanglement(uint256 _entanglementId)
    external
    view
    returns (
        address partyA,
        address partyB,
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB,
        uint8 conditionType,
        uint256 conditionValue,
        uint256 deadline,
        EntanglementState state,
        bool aWithdrewDecohered,
        bool bWithdrewDecohered,
        bool aWithdrewCancelled,
        bool bWithdrewCancelled
    )
{
    Entanglement storage entanglement = entanglements[_entanglementId];
     partyA = entanglement.partyA;
     partyB = entanglement.partyB;
     tokenA = address(entanglement.tokenA);
     amountA = entanglement.amountA;
     tokenB = address(entanglement.tokenB);
     amountB = entanglement.amountB;
     conditionType = uint8(entanglement.conditionType);
     conditionValue = entanglement.conditionValue;
     deadline = entanglement.deadline;
     state = entanglement.state;
     aWithdrewDecohered = entanglement.aWithdrewDecohered;
     bWithdrewDecohered = entanglement.bWithdrewDecohered;
     aWithdrewCancelled = entanglement.aWithdrewCancelled;
     bWithdrewCancelled = entanglement.bWithdrewCancelled;
}

/**
 * @dev Gets the current state of an entanglement.
 * @param _entanglementId The ID of the entanglement.
 * @return EntanglementState The current state.
 */
function getCurrentState(uint256 _entanglementId) external view returns (EntanglementState) {
    return entanglements[_entanglementId].state;
}

/**
 * @dev Checks if an entanglement can currently be collapsed (swap executed).
 * @param _entanglementId The ID of the entanglement.
 * @return bool True if collapse is possible, false otherwise.
 */
function canCollapse(uint256 _entanglementId) external view returns (bool) {
    Entanglement storage entanglement = entanglements[_entanglementId];
    return entanglement.state == EntanglementState.Entangled &&
           block.timestamp <= entanglement.deadline &&
           _checkConditionMet(_entanglementId);
}

/**
 * @dev Checks if deposited tokens can be withdrawn due to decoherence (deadline passed, condition unmet).
 * @param _entanglementId The ID of the entanglement.
 * @return bool True if withdrawal is possible due to decoherence, false otherwise.
 */
function canWithdrawDecohered(uint256 _entanglementId) external view returns (bool) {
    Entanglement storage entanglement = entanglements[_entanglementId];
    return (entanglement.state == EntanglementState.Entangled &&
            block.timestamp > entanglement.deadline &&
            !_checkConditionMet(_entanglementId)) ||
           entanglement.state == EntanglementState.Decohered; // Also possible if already in Decohered state
}

/**
 * @dev Checks if deposited tokens can be withdrawn due to cancellation.
 * @param _entanglementId The ID of the entanglement.
 * @return bool True if withdrawal is possible due to cancellation, false otherwise.
 */
function canWithdrawCancelled(uint256 _entanglementId) external view returns (bool) {
    return entanglements[_entanglementId].state == EntanglementState.Cancelled;
}

/**
 * @dev Helper view function to check if state is Setup.
 */
function isEntanglementSetup(uint256 _id) external view returns (bool) {
    return entanglements[_id].state == EntanglementState.Setup;
}

/**
 * @dev Helper view function to check if state is Accepted.
 */
function isEntanglementAccepted(uint256 _id) external view returns (bool) {
    return entanglements[_id].state == EntanglementState.Accepted;
}

/**
 * @dev Helper view function to check if state is Accepted_A_Deposited or Accepted_B_Deposited.
 */
function isEntanglementDeposited(uint256 _id) external view returns (bool) {
     EntanglementState state = entanglements[_id].state;
    return state == EntanglementState.Accepted_A_Deposited || state == EntanglementState.Accepted_B_Deposited;
}


/**
 * @dev Helper view function to check if state is Entangled.
 */
function isEntangled(uint256 _id) external view returns (bool) {
    return entanglements[_id].state == EntanglementState.Entangled;
}

/**
 * @dev Helper view function to check if state is Collapsed.
 */
function isCollapsed(uint256 _id) external view returns (bool) {
    return entanglements[_id].state == EntanglementState.Collapsed;
}

/**
 * @dev Helper view function to check if state is Decohered.
 */
function isDecohered(uint256 _id) external view returns (bool) {
    return entanglements[_id].state == EntanglementState.Decohered;
}

/**
 * @dev Helper view function to check if state is Cancelled.
 */
function isCancelled(uint256 _id) external view returns (bool) {
    return entanglements[_id].state == EntanglementState.Cancelled;
}


/**
 * @dev Checks if the Timestamp condition is met for an entanglement.
 * @param _id The ID of the entanglement.
 * @return bool True if condition is met.
 */
function isTimestampConditionMet(uint256 _id) external view returns (bool) {
     Entanglement storage entanglement = entanglements[_id];
     require(entanglement.conditionType == ConditionType.Timestamp, "Condition type is not Timestamp");
     return block.timestamp >= entanglement.conditionValue;
}

/**
 * @dev Checks if the Oracle Price condition is met for an entanglement (uses mock).
 * @param _id The ID of the entanglement.
 * @return bool True if condition is met.
 */
function isOraclePriceConditionMet(uint256 _id) external view returns (bool) {
    Entanglement storage entanglement = entanglements[_id];
    require(entanglement.conditionType == ConditionType.OraclePriceGreater || entanglement.conditionType == ConditionType.OraclePriceLess, "Condition type is not Oracle Price");
    // Mocked oracle check
    if (entanglement.conditionType == ConditionType.OraclePriceGreater) {
        return internalStateCounter > entanglement.conditionValue; // Using internalStateCounter as mock price
    } else {
        return internalStateCounter < entanglement.conditionValue; // Using internalStateCounter as mock price
    }
}

/**
 * @dev Checks if the Internal State condition is met for an entanglement.
 * @param _id The ID of the entanglement.
 * @return bool True if condition is met.
 */
function isInternalStateConditionMet(uint256 _id) external view returns (bool) {
     Entanglement storage entanglement = entanglements[_id];
     require(entanglement.conditionType == ConditionType.InternalState, "Condition type is not InternalState");
     return internalStateCounter >= entanglement.conditionValue;
}


/**
 * @dev Gets the amount of a specific token deposited by a party for an entanglement.
 * @param _entanglementId The ID of the entanglement.
 * @param _party The address of the party.
 * @param _token The address of the token.
 * @return uint256 The deposited amount.
 */
function getDepositedAmount(uint256 _entanglementId, address _party, address _token)
    external
    view
    returns (uint256)
{
    return depositedAmounts[_entanglementId][_party][_token];
}


/**
 * @dev Gets the ID that will be assigned to the next proposed entanglement.
 */
function getNextEntanglementId() external view returns (uint256) {
    return nextEntanglementId;
}

/**
 * @dev Gets the total number of entanglements that have been proposed.
 */
function getEntanglementCount() external view returns (uint256) {
    return nextEntanglementId - 1;
}

/**
 * @dev Gets a list of entanglement IDs associated with a specific party.
 *      Note: This function can be gas-intensive if a party is involved in many entanglements.
 * @param _party The address of the party.
 * @return uint256[] An array of entanglement IDs.
 */
function getEntanglementsForParty(address _party) external view returns (uint256[] memory) {
    return partyEntanglementIds[_party];
}

/**
 * @dev Gets the current value of the internal state counter.
 */
function getInternalState() external view returns (uint256) {
    return internalStateCounter;
}


// --- ADMIN FUNCTIONS ---

/**
 * @dev Allows the owner to pause the contract.
 */
function pause() external onlyOwner {
    _pause();
}

/**
 * @dev Allows the owner to unpause the contract.
 */
function unpause() external onlyOwner {
    _unpause();
}

/**
 * @dev Allows the owner to withdraw tokens accidentally sent directly to the contract.
 *      This should NOT be used for tokens locked in active entanglements.
 * @param _token The address of the token to withdraw.
 * @param _amount The amount to withdraw.
 */
function withdrawStuckTokens(address _token, uint256 _amount) external onlyOwner nonReentrant {
    require(_token != address(0), "Invalid token address");
    IERC20 token = IERC20(_token);
    SafeERC20.safeTransfer(token, owner(), _amount);
}

/**
 * @dev Allows the owner to set the address of the mock oracle contract.
 * @param _oracle The address of the oracle contract.
 */
function setOracleAddress(address _oracle) external onlyOwner {
    oracleAddress = _oracle;
    emit OracleAddressUpdated(_oracle);
}

// Total Functions: 29 (Public/External: proposeEntanglement, acceptEntanglement, depositTokenA, depositTokenB, checkAndEntangle, collapseEntanglement, cancelEntanglement, withdrawCancelled, withdrawDecohered, withdrawExcessDeposits, incrementInternalState, setInternalState, getEntanglement, getCurrentState, canCollapse, canWithdrawDecohered, canWithdrawCancelled, isEntanglementSetup, isEntanglementAccepted, isEntanglementDeposited, isEntangled, isCollapsed, isDecohered, isCancelled, isTimestampConditionMet, isOraclePriceConditionMet, isInternalStateConditionMet, getDepositedAmount, getNextEntanglementId, getEntanglementCount, getEntanglementsForParty, getInternalState, pause, unpause, withdrawStuckTokens, setOracleAddress) - Yes, exceeds 20.
}
```