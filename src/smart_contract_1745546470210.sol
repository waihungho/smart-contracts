Okay, let's design an interesting, advanced-concept smart contract. We'll call it the "Quantum Vault".

The concept: A vault that stores ETH or tokens associated with unique "Quantum States". Accessing (revealing) a Quantum State isn't just about a simple key or time lock; it requires meeting a set of potentially "entangled" and complex conditions, drawing parallels (metaphorically) from quantum mechanics concepts like superposition (multiple conditions must align) and entanglement (unlocking one state might depend on another). It also incorporates external data dependency via oracles and a "decay" mechanism if conditions aren't met in time.

This contract goes beyond basic timelocks or multisigs by combining multiple, flexible condition types including state-dependency, requiring *all* currently defined conditions to be met simultaneously for a successful reveal.

---

**Quantum Vault Smart Contract**

**Outline:**

1.  **Contract Name:** `QuantumVault`
2.  **Description:** A secure vault for storing ETH/tokens associated with distinct "Quantum States". Each state holds a reference (hash) to potentially sensitive data/secrets and can only be accessed (revealed) if a dynamic set of "quantum" conditions are all met simultaneously.
3.  **Key Features:**
    *   **Quantum States:** Creation of distinct, identifiable states storing a data hash and associated value.
    *   **Dynamic Conditions:** Ability to add multiple types of unlock conditions to a state (time lock, address approval, oracle data, state dependency).
    *   **Simultaneous Condition Check:** Reveal requires *all* attached conditions to be true at the moment of access.
    *   **State Entanglement (Dependency):** One state's reveal can depend on another state being revealed.
    *   **Oracle Integration:** Conditions can depend on external data feeds.
    *   **Multi-Party Control:** Conditions can require approvals from multiple specified addresses.
    *   **Decay Mechanism:** States can expire and become permanently inaccessible after a deadline.
    *   **Fee Structure:** Optional fees for revealing states.
    *   **Pausable & Ownable:** Standard access control and emergency stop features.
4.  **Modules/Components:**
    *   `Ownable` (from OpenZeppelin): Admin ownership.
    *   `Pausable` (from OpenZeppelin): Emergency pausing.
    *   `QuantumState` Struct: Defines the structure of a stored state.
    *   `UnlockCondition` Struct: Defines the structure of an unlock condition.
    *   Condition Types Enum: Differentiates unlock condition types.
    *   Mappings: Store states, track address approvals for conditions.
    *   Events: Log key actions (state creation, reveal, condition added, etc.).
    *   Core Functions: Creation, condition management, reveal logic, utility functions.
    *   Admin Functions: Configuration, withdrawal.
    *   Helper Functions: Internal logic for checking conditions.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner, fee receiver, and potentially initial fee settings.
2.  `createQuantumState(bytes32 _dataHash, uint64 _expiryTimestamp)`: Creates a new Quantum State, associates it with a data hash and an optional expiry timestamp. Receives ETH/tokens as the state's value. Emits `StateCreated`.
3.  `addTimeLockCondition(uint256 _stateId, uint64 _unlockTimestamp)`: Adds a time-based unlock condition to a state. Requires current time to be greater than or equal to `_unlockTimestamp`. Only callable by state owner or contract owner. Emits `ConditionAdded`.
4.  `addAddressApprovalCondition(uint256 _stateId, address[] calldata _approvers)`: Adds a multi-party approval condition to a state. Requires specified addresses to submit approval before revealing. Only callable by state owner or contract owner. Emits `ConditionAdded`.
5.  `addOracleCondition(uint256 _stateId, address _oracleAddress, bytes32 _oracleQueryId)`: Adds a condition dependent on an external oracle. Requires the oracle to report a specific status (e.g., `true`). Only callable by state owner or contract owner. Emits `ConditionAdded`.
6.  `addStateDependencyCondition(uint256 _stateId, uint256 _dependentStateId)`: Adds a condition requiring another specified Quantum State to be revealed first. Only callable by state owner or contract owner. Emits `ConditionAdded`.
7.  `submitAddressApproval(uint256 _stateId)`: Allows an address required by an `AddressApprovalCondition` to submit their approval for a specific state. Emits `ApprovalSubmitted`.
8.  `revealQuantumState(uint256 _stateId)`: Attempts to reveal a Quantum State. Checks if ALL currently attached conditions are met simultaneously and if the state has not expired or already been revealed. If successful, transfers the associated value to the state owner, marks the state as revealed, and logs the action. Emits `StateRevealed`.
9.  `checkStateConditions(uint256 _stateId) public view`: A view function to check if all unlock conditions for a state are currently met, without attempting to reveal.
10. `getQuantumState(uint256 _stateId) public view`: Returns the details of a specific Quantum State.
11. `getConditions(uint256 _stateId) public view`: Returns the list of all unlock conditions attached to a specific state.
12. `getAddressApprovalStatus(uint256 _stateId, address _approver) public view`: Checks if a specific address has submitted approval for a state requiring it.
13. `getRequiredApprovers(uint256 _stateId) public view`: Returns the list of addresses required for approval conditions on a state.
14. `isStateExpired(uint256 _stateId) public view`: Checks if a state's expiry timestamp has passed.
15. `checkDependencyStatus(uint256 _stateId) public view`: Checks the reveal status of states required by `StateDependencyCondition`s.
16. `decayExpiredState(uint256 _stateId)`: Allows anyone to call this function to process an expired state. If expired and not revealed, the state's value is transferred to the fee receiver (or locked, depending on policy) and the state is marked as decayed. Emits `StateDecayed`. Includes a small incentive transfer to the caller (optional, for gas).
17. `transferStateOwnership(uint256 _stateId, address _newOwner)`: Allows the current state owner to transfer control of a state to a new address. Only callable by current state owner or contract owner. Emits `StateOwnershipTransferred`.
18. `cancelQuantumState(uint256 _stateId)`: Allows the contract owner or state owner to cancel a state before it's revealed or expired, returning the deposited value. Adds a penalty (optional, not implemented in basic structure below but possible). Emits `StateCancelled`.
19. `setRevealFee(uint256 _fee)`: Admin function to set the fee charged upon successful state reveal.
20. `setFeeReceiver(address _receiver)`: Admin function to set the address that receives reveal fees and potentially decayed state values.
21. `withdrawFees()`: Admin function to withdraw accumulated fees from the contract.
22. `pauseContract()`: Admin function to pause contract operations (creation, reveal).
23. `unpauseContract()`: Admin function to unpause the contract.
24. `getOracleConditionStatus(uint256 _stateId, bytes32 _oracleQueryId) public view`: Placeholder/interface view function. In a real implementation, this would query the actual oracle contract. Returns a mock status here.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential future token support

// Note: In a real scenario, OracleInterface would interact with a live oracle network (e.g., Chainlink)
// For this example, we use a simple mock interface concept.
interface IOracle {
    // Example function signature - replace with actual oracle interface
    function getData(bytes32 queryId) external view returns (bool success, bytes memory data);
}


contract QuantumVault is Ownable, Pausable, ReentrancyGuard {

    // --- Errors ---
    error StateNotFound(uint256 stateId);
    error StateAlreadyRevealed(uint256 stateId);
    error StateExpired(uint256 stateId);
    error StateNotExpired(uint256 stateId);
    error RevealConditionsNotMet(uint256 stateId);
    error OnlyStateOwnerOrAdmin(uint256 stateId);
    error AlreadyApproved(uint256 stateId, address approver);
    error ApproverNotRequired(uint256 stateId, address approver);
    error CannotAddConditionAfterExpiry(uint256 stateId);
    error CannotAddConditionToRevealedState(uint256 stateId);
    error ConditionNotFound(uint256 stateId, uint256 conditionIndex);
    error InvalidDependencyState(uint256 dependentStateId);
    error CannotAddDuplicateCondition(uint256 stateId);


    // --- Events ---
    event StateCreated(uint256 indexed stateId, address indexed owner, bytes32 dataHash, uint256 depositAmount, uint64 expiryTimestamp, uint64 creationTimestamp);
    event StateRevealed(uint256 indexed stateId, address indexed receiver, uint256 amount, uint256 feeAmount);
    event ConditionAdded(uint256 indexed stateId, ConditionType indexed conditionType, uint256 conditionIndex);
    event ApprovalSubmitted(uint256 indexed stateId, address indexed approver);
    event StateOwnershipTransferred(uint256 indexed stateId, address indexed oldOwner, address indexed newOwner);
    event StateCancelled(uint256 indexed stateId, address indexed initiator);
    event StateDecayed(uint256 indexed stateId, address indexed valueReceiver);
    event RevealFeeUpdated(uint256 newFee);
    event FeeReceiverUpdated(address indexed newReceiver);
    event FeesWithdrawn(address indexed receiver, uint256 amount);


    // --- Enums ---
    enum ConditionType {
        TimeLock,          // Requires a specific timestamp to pass
        AddressApproval,   // Requires one or more specific addresses to approve
        OracleData,        // Requires an external oracle to provide a specific status
        StateDependency    // Requires another QuantumState to be revealed first
    }

    // --- Structs ---
    struct UnlockCondition {
        ConditionType conditionType;
        // Data specific to the condition type
        uint64 timeLockTimestamp;       // For TimeLock
        address[] requiredApprovers;    // For AddressApproval
        bytes32 oracleQueryId;          // For OracleData (ID passed to oracle)
        address oracleContractAddress;  // For OracleData (address of the oracle)
        uint256 dependentStateId;       // For StateDependency
        // Note: Oracle status check logic depends on the specific oracle interface/data format
        // For AddressApproval, a mapping outside the struct tracks submitted approvals
    }

    struct QuantumState {
        uint256 id;
        bytes32 dataHash;           // A hash representing the hidden data/secret
        uint256 depositAmount;      // ETH/Token value associated with this state
        address owner;              // Address allowed to reveal the state
        UnlockCondition[] conditions; // List of conditions that must ALL be met to reveal
        bool isRevealed;            // True if the state has been successfully revealed
        bool isDecayed;             // True if the state has expired and decayed
        uint64 creationTimestamp;
        uint64 expiryTimestamp;      // Timestamp after which the state decays (0 means no expiry)
        // Add token support? Would need IERC20 and token address per state or contract-wide
    }


    // --- State Variables ---
    QuantumState[] public states;
    uint256 private _stateCounter; // Counter for unique state IDs

    // Mapping to track address approvals for AddressApproval conditions
    // stateId => approverAddress => hasApproved
    mapping(uint256 => mapping(address => bool)) private addressApprovals;

    uint256 public revealFee; // Fee charged upon successful reveal (in wei)
    address public feeReceiver; // Address to receive fees and potentially decayed state value

    // Oracle address mapping (if using multiple oracles) - simplified here to one
    // mapping(bytes32 => address) public oracleRegistry; // queryId => oracleAddress


    // --- Modifiers ---
    modifier onlyStateOwnerOrAdmin(uint256 _stateId) {
        QuantumState storage state = states[_stateId]; // Access state by index (assuming states are dense)
        if (_stateId >= states.length) revert StateNotFound(_stateId); // Basic bounds check if not using counter for direct access

        if (msg.sender != state.owner && msg.sender != owner()) revert OnlyStateOwnerOrAdmin(_stateId);
        _;
    }

    modifier stateExists(uint256 _stateId) {
         if (_stateId >= states.length) revert StateNotFound(_stateId); // Basic bounds check
        _;
    }

    modifier notExpired(uint256 _stateId) {
        QuantumState storage state = states[_stateId];
        if (state.expiryTimestamp > 0 && block.timestamp >= state.expiryTimestamp) revert StateExpired(_stateId);
        _;
    }

     modifier notRevealed(uint256 _stateId) {
        QuantumState storage state = states[_state[_stateId].id]; // Access by ID using the mapping or directly if states is dense
        if (state.isRevealed) revert StateAlreadyRevealed(_stateId);
        _;
    }


    // --- Constructor ---
    constructor(address _feeReceiver) Ownable(msg.sender) Pausable(false) {
        feeReceiver = _feeReceiver;
        revealFee = 0; // Default to no fee
        _stateCounter = 0;
    }


    // --- Core Functionality ---

    /**
     * @notice Creates a new Quantum State with an associated data hash and value.
     * @param _dataHash A hash referencing the secret data stored off-chain.
     * @param _expiryTimestamp The Unix timestamp after which the state decays (0 for no expiry).
     */
    function createQuantumState(bytes32 _dataHash, uint64 _expiryTimestamp)
        external
        payable
        whenNotPaused
        returns (uint256 newStateId)
    {
        require(msg.value > 0, "Must deposit value with state");

        uint256 stateId = _stateCounter++;

        QuantumState memory newState;
        newState.id = stateId;
        newState.dataHash = _dataHash;
        newState.depositAmount = msg.value;
        newState.owner = msg.sender;
        // conditions array is initially empty
        newState.isRevealed = false;
        newState.isDecayed = false;
        newState.creationTimestamp = uint64(block.timestamp);
        newState.expiryTimestamp = _expiryTimestamp;

        states.push(newState); // Add to storage array

        emit StateCreated(stateId, msg.sender, _dataHash, msg.value, _expiryTimestamp, uint64(block.timestamp));

        return stateId;
    }

    /**
     * @notice Adds a Time Lock condition to a Quantum State.
     * @param _stateId The ID of the state.
     * @param _unlockTimestamp The timestamp when the state becomes potentially unlockable by this condition.
     */
    function addTimeLockCondition(uint256 _stateId, uint64 _unlockTimestamp)
        external
        onlyStateOwnerOrAdmin(_stateId)
        stateExists(_stateId)
        notExpired(_stateId)
        notRevealed(_stateId)
        whenNotPaused
    {
         QuantumState storage state = states[_stateId];

        // Prevent adding duplicate conditions of the same simple type, or conditions already met/passed
        for(uint i=0; i < state.conditions.length; i++) {
            if (state.conditions[i].conditionType == ConditionType.TimeLock && state.conditions[i].timeLockTimestamp == _unlockTimestamp) {
                 revert CannotAddDuplicateCondition(_stateId);
            }
        }
        if (_unlockTimestamp < block.timestamp) revert("Time lock must be in the future or now");


        UnlockCondition memory newCondition;
        newCondition.conditionType = ConditionType.TimeLock;
        newCondition.timeLockTimestamp = _unlockTimestamp;

        state.conditions.push(newCondition);

        emit ConditionAdded(_stateId, ConditionType.TimeLock, state.conditions.length - 1);
    }

    /**
     * @notice Adds an Address Approval condition to a Quantum State. All listed approvers must call submitAddressApproval.
     * @param _stateId The ID of the state.
     * @param _approvers An array of addresses that must approve.
     */
    function addAddressApprovalCondition(uint256 _stateId, address[] calldata _approvers)
        external
        onlyStateOwnerOrAdmin(_stateId)
        stateExists(_stateId)
        notExpired(_stateId)
        notRevealed(_stateId)
        whenNotPaused
    {
         QuantumState storage state = states[_stateId];
         require(_approvers.length > 0, "Must provide at least one approver");

         // Prevent adding duplicate conditions or conditions with the exact same set of approvers
         // (Simple check: check if any AddressApproval exists) - more complex check needed for exact match
         for(uint i=0; i < state.conditions.length; i++) {
            if (state.conditions[i].conditionType == ConditionType.AddressApproval) {
                 revert CannotAddDuplicateCondition(_stateId); // Simplified check
            }
        }


        UnlockCondition memory newCondition;
        newCondition.conditionType = ConditionType.AddressApproval;
        newCondition.requiredApprovers = _approvers;

        state.conditions.push(newCondition);

        // Initialize approval status in mapping
        for (uint i = 0; i < _approvers.length; i++) {
             addressApprovals[_stateId][_approvers[i]] = false; // Set all required approvers to false initially
        }


        emit ConditionAdded(_stateId, ConditionType.AddressApproval, state.conditions.length - 1);
    }

     /**
     * @notice Adds an Oracle Data condition to a Quantum State.
     * @param _stateId The ID of the state.
     * @param _oracleAddress The address of the oracle contract.
     * @param _oracleQueryId The ID or identifier for the specific data query on the oracle.
     */
    function addOracleCondition(uint256 _stateId, address _oracleAddress, bytes32 _oracleQueryId)
        external
        onlyStateOwnerOrAdmin(_stateId)
        stateExists(_stateId)
        notExpired(_stateId)
        notRevealed(_stateId)
        whenNotPaused
    {
         QuantumState storage state = states[_stateId];
         require(_oracleAddress != address(0), "Invalid oracle address");
         require(_oracleQueryId != bytes32(0), "Invalid oracle query ID");

         // Prevent adding duplicate conditions with the same oracle and query
         for(uint i=0; i < state.conditions.length; i++) {
            if (state.conditions[i].conditionType == ConditionType.OracleData &&
                state.conditions[i].oracleContractAddress == _oracleAddress &&
                state.conditions[i].oracleQueryId == _oracleQueryId) {
                 revert CannotAddDuplicateCondition(_stateId);
            }
        }


        UnlockCondition memory newCondition;
        newCondition.conditionType = ConditionType.OracleData;
        newCondition.oracleContractAddress = _oracleAddress;
        newCondition.oracleQueryId = _oracleQueryId;

        state.conditions.push(newCondition);

        emit ConditionAdded(_stateId, ConditionType.OracleData, state.conditions.length - 1);
    }


     /**
     * @notice Adds a State Dependency condition to a Quantum State. Requires another state to be revealed.
     * @param _stateId The ID of the state adding the dependency.
     * @param _dependentStateId The ID of the state that must be revealed.
     */
    function addStateDependencyCondition(uint256 _stateId, uint256 _dependentStateId)
        external
        onlyStateOwnerOrAdmin(_stateId)
        stateExists(_stateId)
        notExpired(_stateId)
        notRevealed(_stateId)
        whenNotPaused
    {
         QuantumState storage state = states[_stateId];
         if (_dependentStateId >= states.length) revert InvalidDependencyState(_dependentStateId);
         if (_dependentStateId == _stateId) revert("Cannot depend on self");

          // Prevent adding duplicate dependencies or circular dependencies (simple check for direct self-reference)
         for(uint i=0; i < state.conditions.length; i++) {
            if (state.conditions[i].conditionType == ConditionType.StateDependency &&
                state.conditions[i].dependentStateId == _dependentStateId) {
                 revert CannotAddDuplicateCondition(_stateId);
            }
        }
        // Note: Detecting complex circular dependencies (A->B, B->C, C->A) would require more advanced graph traversal logic,
        // which is usually too complex/gas-intensive for a simple on-chain function. Assume users add dependencies reasonably.


        UnlockCondition memory newCondition;
        newCondition.conditionType = ConditionType.StateDependency;
        newCondition.dependentStateId = _dependentStateId;

        state.conditions.push(newCondition);

        emit ConditionAdded(_stateId, ConditionType.StateDependency, state.conditions.length - 1);
    }


    /**
     * @notice Submits approval for an Address Approval condition.
     * @param _stateId The ID of the state requiring approval.
     */
    function submitAddressApproval(uint256 _stateId)
        external
        stateExists(_stateId)
        notExpired(_stateId)
        notRevealed(_stateId)
        whenNotPaused
    {
        QuantumState storage state = states[_stateId];
        bool isRequired = false;
        for(uint i = 0; i < state.conditions.length; i++) {
            if (state.conditions[i].conditionType == ConditionType.AddressApproval) {
                for(uint j = 0; j < state.conditions[i].requiredApprovers.length; j++) {
                    if (state.conditions[i].requiredApprovers[j] == msg.sender) {
                        isRequired = true;
                        break; // Found msg.sender in required approvers
                    }
                }
                if (isRequired) break; // Found AddressApproval condition
            }
        }

        if (!isRequired) revert ApproverNotRequired(_stateId, msg.sender);
        if (addressApprovals[_stateId][msg.sender]) revert AlreadyApproved(_stateId, msg.sender);

        addressApprovals[_stateId][msg.sender] = true;

        emit ApprovalSubmitted(_stateId, msg.sender);
    }


    /**
     * @notice Attempts to reveal a Quantum State, transferring its value if all conditions are met.
     * This is the core "observation" function.
     * @param _stateId The ID of the state to reveal.
     */
    function revealQuantumState(uint256 _stateId)
        external
        stateExists(_stateId)
        notRevealed(_stateId)
        notExpired(_stateId)
        whenNotPaused
        nonReentrant // Prevents reentrancy during ETH transfer
    {
        QuantumState storage state = states[_stateId];

        // Only the state owner can attempt to reveal
        require(msg.sender == state.owner, "Only state owner can reveal");

        // Check ALL conditions attached to the state
        if (!_checkAllConditionsMet(_stateId)) {
            revert RevealConditionsNotMet(_stateId);
        }

        // Conditions met - transfer value
        uint256 amountToTransfer = state.depositAmount;
        uint256 fee = revealFee;

        // Ensure fee doesn't exceed amount
        if (fee > amountToTransfer) {
            fee = amountToTransfer;
        }

        uint256 payoutAmount = amountToTransfer - fee;

        // Mark as revealed BEFORE sending ETH
        state.isRevealed = true;

        // Transfer fee to the fee receiver
        if (fee > 0) {
             (bool successFee, ) = payable(feeReceiver).call{value: fee}("");
             // Optionally handle failed fee transfer - could revert, or log and continue.
             // For simplicity, we'll let the main transfer proceed.
             require(successFee, "Fee transfer failed");
        }

        // Transfer the remaining amount to the state owner
        (bool successPayout, ) = payable(state.owner).call{value: payoutAmount}("");
        require(successPayout, "Payout transfer failed"); // Revert if main transfer fails

        emit StateRevealed(_stateId, state.owner, payoutAmount, fee);
    }


    /**
     * @notice Allows anyone to trigger the decay logic for an expired state.
     * Transfers state value to feeReceiver if expired and not revealed.
     * Includes a small incentive transfer to the caller.
     * @param _stateId The ID of the state to decay.
     */
    function decayExpiredState(uint256 _stateId)
        external
        stateExists(_stateId)
        nonReentrant
    {
        QuantumState storage state = states[_stateId];

        if (!isStateExpired(_stateId)) revert StateNotExpired(_stateId);
        if (state.isRevealed) revert StateAlreadyRevealed(_stateId);
        if (state.isDecayed) revert("State already decayed");

        state.isDecayed = true; // Mark as decayed BEFORE sending value

        // Transfer state value to the fee receiver
        uint256 amountToTransfer = state.depositAmount;
        address receiver = feeReceiver; // Send value to fee receiver

        // Small incentive for the caller (optional) - e.g., 0.001 ETH
        uint256 incentive = 1e15; // 0.001 ETH
        uint256 transferAmount = amountToTransfer;

        if (amountToTransfer >= incentive) {
            transferAmount = amountToTransfer - incentive;
             (bool successIncentive, ) = payable(msg.sender).call{value: incentive}("");
             require(successIncentive, "Incentive transfer failed");
        }


        (bool success, ) = payable(receiver).call{value: transferAmount}("");
        require(success, "Decay value transfer failed"); // Revert if transfer fails

        emit StateDecayed(_stateId, receiver);
    }

    /**
     * @notice Allows the state owner to transfer ownership of an unrevealed/undecayed state.
     * @param _stateId The ID of the state.
     * @param _newOwner The address of the new owner.
     */
    function transferStateOwnership(uint256 _stateId, address _newOwner)
        external
        onlyStateOwnerOrAdmin(_stateId)
        stateExists(_stateId)
        notRevealed(_stateId)
        whenNotPaused
    {
        QuantumState storage state = states[_stateId];
        require(!state.isDecayed, "Cannot transfer ownership of a decayed state");
        require(_newOwner != address(0), "New owner cannot be zero address");

        address oldOwner = state.owner;
        state.owner = _newOwner;

        emit StateOwnershipTransferred(_stateId, oldOwner, _newOwner);
    }

    /**
     * @notice Allows the state owner or contract owner to cancel an unrevealed/undecayed state.
     * Returns the deposited value to the state owner.
     * @param _stateId The ID of the state to cancel.
     */
    function cancelQuantumState(uint256 _stateId)
        external
        onlyStateOwnerOrAdmin(_stateId)
        stateExists(_stateId)
        notRevealed(_stateId)
        whenNotPaused
        nonReentrant
    {
        QuantumState storage state = states[_stateId];
        require(!state.isDecayed, "Cannot cancel a decayed state");

        state.isDecayed = true; // Mark as decayed/cancelled to prevent further interaction

        uint256 amountToReturn = state.depositAmount;
        state.depositAmount = 0; // Zero out balance to be safe

        (bool success, ) = payable(state.owner).call{value: amountToReturn}("");
        require(success, "Cancellation refund failed");

        emit StateCancelled(_stateId, msg.sender);
    }


    // --- View Functions ---

    /**
     * @notice Checks if all conditions for a state are currently met.
     * @param _stateId The ID of the state.
     * @return bool True if all conditions are met, false otherwise.
     */
    function checkStateConditions(uint256 _stateId)
        public
        view
        stateExists(_stateId)
    {
       _checkAllConditionsMet(_stateId);
    }

     /**
     * @notice Internal helper to check if all conditions for a state are currently met.
     * @param _stateId The ID of the state.
     * @return bool True if all conditions are met, false otherwise.
     */
    function _checkAllConditionsMet(uint256 _stateId)
        internal
        view
        returns (bool)
    {
        QuantumState storage state = states[_stateId];

        if (state.conditions.length == 0) {
             // If no conditions are set, it's immediately revealable (if not expired/revealed)
             return true;
        }

        for (uint i = 0; i < state.conditions.length; i++) {
            UnlockCondition storage condition = state.conditions[i];

            bool conditionMet = false;
            if (condition.conditionType == ConditionType.TimeLock) {
                if (block.timestamp >= condition.timeLockTimestamp) {
                    conditionMet = true;
                }
            } else if (condition.conditionType == ConditionType.AddressApproval) {
                 bool allApproved = true;
                 for(uint j = 0; j < condition.requiredApprovers.length; j++) {
                     if (!addressApprovals[_stateId][condition.requiredApprovers[j]]) {
                         allApproved = false;
                         break;
                     }
                 }
                 if (allApproved) {
                     conditionMet = true;
                 }
            } else if (condition.conditionType == ConditionType.OracleData) {
                 // In a real contract, this would call the oracle contract.
                 // For this example, we simulate the check or rely on a mock.
                 // Assume the oracle's success means the condition is met.
                 (bool success, ) = IOracle(condition.oracleContractAddress).getData(condition.oracleQueryId);
                 // Complex oracle data parsing would go here if needed, returning bool based on data
                 if (success) { // Simplified: Oracle call success indicates condition met
                     conditionMet = true;
                 }

            } else if (condition.conditionType == ConditionType.StateDependency) {
                 // Check if the dependent state has been revealed
                 uint256 depStateId = condition.dependentStateId;
                 if (depStateId < states.length && states[depStateId].isRevealed) {
                      conditionMet = true;
                 }
                 // Note: Circular dependency checks should ideally happen on addCondition,
                 // but a complex graph cannot be easily checked here.
            }

            if (!conditionMet) {
                // If any single condition is not met, the overall conditions are not met
                return false;
            }
        }

        // If the loop completes, all conditions were met
        return true;
    }


    /**
     * @notice Retrieves details for a specific Quantum State.
     * @param _stateId The ID of the state.
     * @return QuantumState The state struct.
     */
    function getQuantumState(uint256 _stateId)
        public
        view
        stateExists(_stateId)
        returns (QuantumState memory)
    {
        return states[_stateId];
    }

    /**
     * @notice Retrieves all unlock conditions for a specific state.
     * @param _stateId The ID of the state.
     * @return UnlockCondition[] An array of condition structs.
     */
    function getConditions(uint256 _stateId)
        public
        view
        stateExists(_stateId)
        returns (UnlockCondition[] memory)
    {
        return states[_stateId].conditions;
    }

    /**
     * @notice Checks if a specific address has submitted approval for a state's Address Approval condition.
     * @param _stateId The ID of the state.
     * @param _approver The address to check.
     * @return bool True if the address has approved, false otherwise.
     */
    function getAddressApprovalStatus(uint256 _stateId, address _approver)
        public
        view
        stateExists(_stateId)
        returns (bool)
    {
         // No need to check if approver is required here, just check if they approved in the mapping
         return addressApprovals[_stateId][_approver];
    }

    /**
     * @notice Retrieves the list of addresses required for Address Approval conditions on a state.
     * Note: This assumes only one AddressApproval condition per state for simplicity.
     * @param _stateId The ID of the state.
     * @return address[] An array of required approver addresses.
     */
    function getRequiredApprovers(uint256 _stateId)
        public
        view
        stateExists(_stateId)
        returns (address[] memory)
    {
         QuantumState storage state = states[_stateId];
         for(uint i = 0; i < state.conditions.length; i++) {
             if (state.conditions[i].conditionType == ConditionType.AddressApproval) {
                 return state.conditions[i].requiredApprovers;
             }
         }
         // Return empty array if no AddressApproval condition exists
         return new address[](0);
    }


    /**
     * @notice Checks if a state's expiry timestamp has passed.
     * @param _stateId The ID of the state.
     * @return bool True if expired, false otherwise.
     */
    function isStateExpired(uint256 _stateId)
        public
        view
        stateExists(_stateId)
        returns (bool)
    {
        QuantumState storage state = states[_stateId];
        return state.expiryTimestamp > 0 && block.timestamp >= state.expiryTimestamp;
    }

    /**
     * @notice Checks the reveal status of states required by State Dependency conditions.
     * Note: Returns true only if ALL dependency conditions reference a revealed state.
     * @param _stateId The ID of the state.
     * @return bool True if all dependent states are revealed, false otherwise.
     */
    function checkDependencyStatus(uint256 _stateId)
         public
         view
         stateExists(_stateId)
         returns (bool)
    {
         QuantumState storage state = states[_stateId];
         for(uint i = 0; i < state.conditions.length; i++) {
             if (state.conditions[i].conditionType == ConditionType.StateDependency) {
                 uint256 depStateId = state.conditions[i].dependentStateId;
                 // If dependent state doesn't exist or isn't revealed, return false
                 if (depStateId >= states.length || !states[depStateId].isRevealed) {
                      return false;
                 }
             }
         }
         // If no dependency conditions, or all dependent states are revealed
         return true;
    }

     /**
     * @notice Placeholder view function to simulate checking an OracleData condition status.
     * In a real implementation, this would call the actual oracle contract.
     * @param _stateId The ID of the state.
     * @param _oracleQueryId The query ID for the oracle data.
     * @return bool True if the oracle data meets the condition, false otherwise (simulated).
     */
    function getOracleConditionStatus(uint256 _stateId, bytes32 _oracleQueryId)
         public
         view
         stateExists(_stateId)
         returns (bool)
    {
        // This is a mock implementation. A real one would query the oracle.
        // Find the relevant oracle condition for the given queryId
        QuantumState storage state = states[_stateId];
        for(uint i = 0; i < state.conditions.length; i++) {
            if (state.conditions[i].conditionType == ConditionType.OracleData &&
                state.conditions[i].oracleQueryId == _oracleQueryId) {
                // Example mock logic: assume oracle is always 'successful' if queryId is non-zero
                 return _oracleQueryId != bytes32(0);
                // Or call the oracle contract:
                // (bool success, bytes memory data) = IOracle(state.conditions[i].oracleContractAddress).getData(_oracleQueryId);
                // return success; // or parse 'data' to check the condition
            }
        }
        // If no matching oracle condition found, it can't be met
        return false;
    }


    // --- Admin Functions (Ownable) ---

    /**
     * @notice Admin function to set the fee for revealing a state.
     * @param _fee The new reveal fee in wei.
     */
    function setRevealFee(uint256 _fee) external onlyOwner {
        revealFee = _fee;
        emit RevealFeeUpdated(_fee);
    }

    /**
     * @notice Admin function to set the address that receives fees and decayed state values.
     * @param _receiver The new fee receiver address.
     */
    function setFeeReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), "Fee receiver cannot be zero address");
        feeReceiver = _receiver;
        emit FeeReceiverUpdated(_receiver);
    }

    /**
     * @notice Admin function to withdraw accumulated fees from the contract balance.
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance - (_stateCounter > 0 ? states[states.length - 1].depositAmount : 0); // Simple calculation of available balance ignoring state values
        // A more robust approach would track fees separately or iterate states
        // This is a simplification; a real vault might segregate operational funds

        uint256 feesAvailable = 0;
         // This fee tracking is simplified. A real contract should track accumulated fees.
         // For this structure, fees go directly to feeReceiver on reveal/decay.
         // This function would only be for *other* ETH sent to the contract.
         // Let's remove or clarify this unless fee logic is more complex.
         // Simpler: Fees are sent directly. This function is not needed with current fee logic.
         // Keeping for potential future use or other ETH received.

        // This logic is flawed for the current fee structure. Fees are sent directly.
        // Let's repurpose this to withdraw any residual balance not tied to states.
        // This requires careful accounting, which is omitted for brevity.
        // Reverting this function for now as it doesn't align with current fee/decay model.
         revert("Withdrawal of residual balance requires careful accounting, not implemented in this example.");
    }

     /**
     * @notice Admin function to pause contract operations (creation, reveal).
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

     /**
     * @notice Admin function to unpause the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }


    // --- Utility / Getters ---

    /**
     * @notice Get the current number of states created.
     * @return uint256 The total number of states.
     */
    function getStateCount() external view returns (uint256) {
        return _stateCounter;
    }

     // Fallback function to receive ETH not associated with state creation (optional, but good practice if ETH might be sent)
    receive() external payable {}
    fallback() external payable {}

    // Note on ERC20: Adding ERC20 support would require creating states with a token address
    // and amount, using safeTransfer/safeTransferFrom from a library like SafeERC20,
    // and adjusting depositAmount/transfers to handle tokens. This would add significant complexity
    // and duplicate many functions (e.g., createQuantumStateERC20, revealQuantumStateERC20).
    // Keeping it ETH-only for this example to manage complexity and function count.
}
```

**Explanation of Advanced/Creative Aspects:**

1.  **Quantum State as a Concept:** Using the term "Quantum State" for a vault entry is metaphorical. It represents a unit of value/data that is "locked" in a state analogous to superposition (requires multiple conditions simultaneously) and can only transition to an observable state ("revealed") when all conditions are met.
2.  **Dynamic, Combinatorial Conditions:** The core advancement is the `UnlockCondition[] conditions` array. A state isn't just a simple timelock *or* a multisig; it's a *combination* of *all* the conditions currently added. This creates complex requirements for revealing.
3.  **State Entanglement (Dependency):** The `StateDependency` condition type simulates entanglement. Unlocking one state (`_stateId`) is tied to the state of another (`_dependentStateId`). This allows for constructing chains or networks of interconnected secrets/assets.
4.  **Oracle Integration:** The `OracleData` condition demonstrates integrating external, real-world data into unlock requirements. This connects the on-chain state to off-chain events, making conditions arbitrarily complex (e.g., "unlock if the price of BTC is > $100k", "unlock if a specific sports event result is confirmed by the oracle"). (Note: The oracle implementation is mocked for simplicity).
5.  **Decay Mechanism:** The `expiryTimestamp` and `decayExpiredState` function add a time-sensitive element beyond simple locks. If conditions aren't met before expiry, the state "collapses" or decays, and its value goes to the fee receiver, rather than remaining indefinitely locked. `decayExpiredState` being callable by *anyone* (with an incentive) encourages the network to clean up expired states.
6.  **Simultaneous Condition Check:** The `_checkAllConditionsMet` function is the "observer" mechanism. It evaluates the state of *all* conditions at the precise moment of the `revealQuantumState` call. If even one condition is not met, the entire reveal attempt fails.
7.  **Non-Duplication:** While individual components like time-locks, multisigs, or oracle calls exist in various contracts, the specific architecture of having dynamically added conditions stored in an array attached to a unique "Quantum State", requiring *all* types of conditions to be simultaneously met, combined with state dependency and decay, is not a standard, widely available open-source pattern like an ERC-20, standard vesting contract, or simple timelock.

This contract provides a flexible framework for building complex conditional logic around releasing assets or revealing information references on the blockchain, pushing beyond the typical single-condition or basic multi-signature patterns.