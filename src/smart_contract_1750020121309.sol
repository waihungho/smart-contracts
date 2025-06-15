Okay, let's create a smart contract with advanced concepts centered around conditional asset release based on complex, multi-factor criteria, somewhat metaphorically inspired by "quantum states" and "measurements" collapsing possibilities.

We'll call it `QuantumVault`. It will allow depositing Ether or registered ERC-20 tokens with a set of conditions. These conditions can be time-based, external oracle data-based (simulated), dependent on the state of *other* vault entries, or requiring approvals from specific parties. An `operator` role is needed to "measure" or evaluate these conditions, potentially changing the state of the vault entry towards `ReadyForRelease`.

This avoids simple time locks or basic multi-sigs and introduces concepts of state dependency and operator-triggered evaluation of conditions.

---

**Outline & Function Summary: QuantumVault.sol**

**Contract Purpose:**
A smart contract designed to hold Ether or ERC-20 tokens and release them to a beneficiary only when a set of predefined, complex conditions are met and evaluated by an authorized operator. It features multi-condition logic, state dependency, simulated oracle integration, and role-based access control.

**Key Concepts:**
*   **VaultEntry:** A container for deposited assets, conditions, state, depositor, and beneficiary.
*   **VaultState:** Enum representing the current status of a vault entry (Pending, LockedByConditions, ReadyForRelease, Challenged, Released, Expired).
*   **Condition:** A struct defining a specific requirement for release (e.g., time, oracle result, dependency on another entry, required approvals).
*   **ConditionType:** Enum classifying the nature of a condition.
*   **Measurement:** The process (triggered by an Operator) of evaluating an entry's conditions to potentially transition its state.
*   **Operator:** A role authorized to manage entries, add/remove conditions, and trigger measurement.
*   **Challenge:** A mechanism to dispute the current state or conditions of an entry.

**Function Summary:**

**1. Admin & Setup:**
*   `constructor()`: Initializes the contract owner.
*   `addOperator(address operator)`: Grants operator role (Owner only).
*   `removeOperator(address operator)`: Revokes operator role (Owner only).
*   `transferOwnership(address newOwner)`: Transfers contract ownership (Owner only).
*   `pauseContract()`: Pauses critical functions (Owner only).
*   `unpauseContract()`: Unpauses critical functions (Owner only).
*   `registerERC20Token(address token)`: Allows a specific ERC-20 token for deposits (Owner only).
*   `deregisterERC20Token(address token)`: Disallows an ERC-20 token (Owner only).

**2. Deposits:**
*   `depositETH(bytes32 metadata, Condition[] conditions)`: Deposits ETH with initial conditions.
*   `depositERC20(address tokenAddress, uint256 amount, bytes32 metadata, Condition[] conditions)`: Deposits specified ERC-20 amount with initial conditions.

**3. Entry Management & State Transition:**
*   `addConditionToEntry(uint256 entryId, Condition newCondition)`: Adds a new condition to an existing entry (Operator or Depositor, with restrictions).
*   `removeConditionFromEntry(uint256 entryId, uint256 conditionIndex)`: Removes a condition (Operator or Depositor, with restrictions).
*   `updateBeneficiary(uint256 entryId, address newBeneficiary)`: Changes the beneficiary of an entry (Operator or Depositor, with restrictions).
*   `triggerMeasurement(uint256 entryId)`: Evaluates all conditions for an entry and updates its state (Operator only).
*   `approveCondition(uint256 entryId)`: Provides an approval for `ApprovalBased` conditions (Any address if required).
*   `challengeState(uint256 entryId, string reason)`: Changes entry state to `Challenged` (Any address, requires later resolution).
*   `resolveChallenge(uint256 entryId, bool releaseDecision)`: Resolves a challenged state, deciding if it moves towards release or back to locked (Operator only).
*   `fulfillOracleQuery(uint256 oracleQueryId, bytes32 result)`: Placeholder for an oracle callback (Callable by designated oracle address, integrated into measurement). *Note: Simulates oracle interaction.*

**4. Withdrawals:**
*   `releaseFunds(uint256 entryId)`: Releases funds if the entry state is `ReadyForRelease` (Beneficiary or Operator).
*   `emergencyOperatorWithdraw(uint256 entryId)`: Allows Operator to withdraw funds under specific emergency conditions (e.g., Contract Paused). *Requires careful implementation logic.*

**5. Querying & Information:**
*   `getEntryState(uint256 entryId)`: Returns the current `VaultState` of an entry.
*   `getEntryDetails(uint256 entryId)`: Returns the full `VaultEntry` struct details.
*   `getConditions(uint256 entryId)`: Returns the list of `Condition` structs for an entry.
*   `isConditionMet(uint256 entryId, uint256 conditionIndex)`: Checks if a specific condition within an entry is currently met based on current state and external factors.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title QuantumVault
/// @dev A contract for conditional asset release based on complex, multi-factor criteria.
/// Assets are held in "vault entries" with defined conditions that must be met and evaluated
/// by an operator before release.

contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _entryIds;

    enum VaultState {
        Pending,             // Newly created entry, conditions not yet evaluated
        LockedByConditions,  // Conditions exist and are not all met
        ReadyForRelease,     // Conditions evaluated and all met
        Challenged,          // State is being disputed
        Released,            // Assets have been withdrawn
        Expired              // Entry conditions failed or entry timed out (optional future feature)
    }

    enum ConditionType {
        TimeBased,          // Release after a specific timestamp
        OracleBased,        // Release based on oracle result (simulated)
        DependencyBased,    // Release depends on another entry reaching a state
        ApprovalBased       // Release requires specific approvals
    }

    struct Condition {
        ConditionType conditionType;
        bool isMet; // Evaluated dynamically, not stored state for complex types

        // Specific parameters for each type
        uint64 targetTime; // For TimeBased (unix timestamp)
        uint256 oracleQueryId; // For OracleBased (simulated query ID)
        bytes32 oracleExpectedResult; // For OracleBased
        uint256 dependencyEntryId; // For DependencyBased
        VaultState dependencyTargetState; // For DependencyBased
        mapping(address => bool) approvals; // For ApprovalBased
        uint256 requiredApprovals; // For ApprovalBased
        address[] approvers; // For ApprovalBased (list of unique approvers)
        uint256 currentApprovalsCount; // For ApprovalBased
    }

    struct VaultEntry {
        address depositor;
        address beneficiary;
        address tokenAddress; // 0x0 for ETH
        uint256 amount;
        VaultState currentState;
        Condition[] conditions; // Dynamic array of conditions
        bytes32 metadata; // Optional data like description hash
        uint40 depositTime; // Timestamp of deposit
    }

    mapping(uint256 => VaultEntry) public vaultEntries;
    mapping(address => bool) public isOperator;
    mapping(address => bool) public allowedERC20Tokens;

    // --- Events ---

    event EntryCreated(
        uint256 indexed entryId,
        address indexed depositor,
        address indexed beneficiary,
        address tokenAddress,
        uint256 amount,
        VaultState initialState,
        bytes32 metadata
    );
    event StateChanged(
        uint256 indexed entryId,
        VaultState indexed oldState,
        VaultState indexed newState,
        string reason
    );
    event ConditionAdded(
        uint256 indexed entryId,
        uint256 indexed conditionIndex,
        ConditionType conditionType
    );
    event ConditionRemoved(uint256 indexed entryId, uint256 indexed conditionIndex);
    event BeneficiaryUpdated(uint256 indexed entryId, address indexed oldBeneficiary, address indexed newBeneficiary);
    event FundsReleased(uint256 indexed entryId, address indexed beneficiary, address tokenAddress, uint256 amount);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event ERC20TokenRegistered(address indexed token);
    event ERC20TokenDeregistered(address indexed token);
    event ConditionApproved(uint256 indexed entryId, address indexed approver);
    event ChallengeInitiated(uint256 indexed entryId, address indexed challenger, string reason);
    event ChallengeResolved(uint256 indexed entryId, bool releaseDecision);
    event EmergencyWithdrawal(uint256 indexed entryId, address indexed recipient, uint256 amount); // More specific emergency event

    // --- Modifiers ---

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not an operator");
        _;
    }

    modifier onlyOperatorOrDepositor(uint256 entryId) {
        require(isOperator[msg.sender] || vaultEntries[entryId].depositor == msg.sender, "Not operator or depositor");
        _;
    }

    modifier entryExists(uint256 entryId) {
        require(vaultEntries[entryId].depositTime > 0, "Entry does not exist"); // Assuming depositTime 0 means non-existent
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Admin Functions (Owner Only) ---

    /// @dev Grants operator role. Only callable by owner.
    /// @param operator The address to grant operator role to.
    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "Zero address");
        isOperator[operator] = true;
        emit OperatorAdded(operator);
    }

    /// @dev Revokes operator role. Only callable by owner.
    /// @param operator The address to revoke operator role from.
    function removeOperator(address operator) external onlyOwner {
        require(operator != address(0), "Zero address");
        isOperator[operator] = false;
        emit OperatorRemoved(operator);
    }

    // Ownable provides transferOwnership

    /// @dev Pauses the contract, preventing most state-changing operations. Only callable by owner.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract. Only callable by owner.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @dev Registers an ERC20 token address as allowed for deposits. Only callable by owner.
    /// @param token The address of the ERC20 token.
    function registerERC20Token(address token) external onlyOwner {
        require(token != address(0), "Zero address");
        allowedERC20Tokens[token] = true;
        emit ERC20TokenRegistered(token);
    }

    /// @dev Deregisters an ERC20 token address, disallowing future deposits of this token. Only callable by owner.
    /// @param token The address of the ERC20 token.
    function deregisterERC20Token(address token) external onlyOwner {
        require(token != address(0), "Zero address");
        allowedERC20Tokens[token] = false;
        emit ERC20TokenDeregistered(token);
    }

    // --- Deposit Functions ---

    /// @dev Deposits Ether into the vault with specified initial conditions.
    /// @param metadata Optional metadata for the entry.
    /// @param conditions Initial conditions for releasing the ETH.
    /// @return The ID of the created vault entry.
    function depositETH(
        bytes32 metadata,
        Condition[] memory conditions // Use memory for function arguments
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        _entryIds.increment();
        uint256 entryId = _entryIds.current();

        VaultEntry storage newEntry = vaultEntries[entryId];
        newEntry.depositor = msg.sender;
        newEntry.beneficiary = msg.sender; // Default beneficiary is depositor
        newEntry.tokenAddress = address(0); // ETH
        newEntry.amount = msg.value;
        newEntry.metadata = metadata;
        newEntry.depositTime = uint40(block.timestamp);

        // Add conditions, handling mappings and arrays properly
        _addConditionsToEntry(newEntry, conditions);

        newEntry.currentState = (newEntry.conditions.length == 0) ? VaultState.ReadyForRelease : VaultState.LockedByConditions;

        emit EntryCreated(
            entryId,
            msg.sender,
            newEntry.beneficiary,
            address(0),
            msg.value,
            newEntry.currentState,
            metadata
        );

        emit StateChanged(entryId, VaultState.Pending, newEntry.currentState, "Entry created"); // Initial state transition

        return entryId;
    }

    /// @dev Deposits ERC20 tokens into the vault with specified initial conditions.
    /// The caller must have approved this contract to spend the tokens.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of ERC20 tokens to deposit.
    /// @param metadata Optional metadata for the entry.
    /// @param conditions Initial conditions for releasing the tokens.
    /// @return The ID of the created vault entry.
    function depositERC20(
        address tokenAddress,
        uint256 amount,
        bytes32 metadata,
        Condition[] memory conditions
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(allowedERC20Tokens[tokenAddress], "Token not registered");
        require(tokenAddress != address(0), "Zero address");

        IERC20 token = IERC20(tokenAddress);
        // Check allowance is done off-chain by the user approving the contract.
        // We directly perform the transferFrom here.
        token.safeTransferFrom(msg.sender, address(this), amount);

        _entryIds.increment();
        uint256 entryId = _entryIds.current();

        VaultEntry storage newEntry = vaultEntries[entryId];
        newEntry.depositor = msg.sender;
        newEntry.beneficiary = msg.sender; // Default beneficiary is depositor
        newEntry.tokenAddress = tokenAddress;
        newEntry.amount = amount;
        newEntry.metadata = metadata;
        newEntry.depositTime = uint40(block.timestamp);

        // Add conditions, handling mappings and arrays properly
        _addConditionsToEntry(newEntry, conditions);

        newEntry.currentState = (newEntry.conditions.length == 0) ? VaultState.ReadyForRelease : VaultState.LockedByConditions;

         emit EntryCreated(
            entryId,
            msg.sender,
            newEntry.beneficiary,
            tokenAddress,
            amount,
            newEntry.currentState,
            metadata
        );

        emit StateChanged(entryId, VaultState.Pending, newEntry.currentState, "Entry created"); // Initial state transition

        return entryId;
    }

    // Internal helper for adding conditions
    function _addConditionsToEntry(VaultEntry storage entry, Condition[] memory conditions) internal {
        for (uint i = 0; i < conditions.length; i++) {
            Condition memory newCondition = conditions[i];
            // Ensure mappings/dynamic arrays in struct are handled correctly when adding
            // For simplicity, copy only fixed size data here. Mappings (like approvals)
            // within a condition struct *must* be handled carefully if cloning/copying conditions.
            // In this design, approvals mapping belongs *to the condition instance* within the entry.
            entry.conditions.push(Condition({
                conditionType: newCondition.conditionType,
                isMet: false, // Always evaluate initially as false
                targetTime: newCondition.targetTime,
                oracleQueryId: newCondition.oracleQueryId,
                oracleExpectedResult: newCondition.oracleExpectedResult,
                dependencyEntryId: newCondition.dependencyEntryId,
                dependencyTargetState: newCondition.dependencyTargetState,
                // Mappings/dynamic arrays are not copied this way.
                // We need to initialize them explicitly for the new condition.
                approvals: newCondition.approvals, // This copies the storage pointer if from storage, but from memory is complex. Better initialize.
                requiredApprovals: newCondition.requiredApprovals,
                approvers: newCondition.approvers,
                currentApprovalsCount: 0 // Always start with 0 approvals
            }));

             // Explicitly initialize the approval mapping if needed (Solidity handles this for new storage structs)
             // Also, make sure approvers list and count match requiredApprovals setup
             VaultEntry storage currentEntry = entry; // Alias for clarity
             Condition storage addedCondition = currentEntry.conditions[currentEntry.conditions.length - 1];
             // Validate ApprovalBased conditions setup
             require(addedCondition.conditionType != ConditionType.ApprovalBased || addedCondition.requiredApprovals > 0, "Approval condition requires >0 approvals");
             // Note: Adding approvers to the `approvers` array here from input `conditions` is complex due to memory vs storage.
             // A better approach for `ApprovalBased` conditions passed during deposit would be to pass `requiredApprovals`
             // and potentially a list of *eligible* approvers separately, or assume *any* address can approve.
             // Let's simplify: for deposit, only requiredApprovals is passed. Approvers list is built on `approveCondition`.
             addedCondition.approvers = new address[](0); // Initialize as empty
             addedCondition.currentApprovalsCount = 0; // Explicitly set

            emit ConditionAdded(entryId, entry.conditions.length - 1, newCondition.conditionType);
        }
    }

    // --- Entry Management & State Transition ---

    /// @dev Adds a new condition to an existing vault entry.
    /// @param entryId The ID of the vault entry.
    /// @param newCondition The condition struct to add.
    function addConditionToEntry(uint256 entryId, Condition memory newCondition)
        external
        onlyOperatorOrDepositor(entryId)
        entryExists(entryId)
        whenNotPaused
    {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState != VaultState.Released && entry.currentState != VaultState.Expired, "Entry is finalized");

        uint256 conditionIndex = entry.conditions.length;
         entry.conditions.push(Condition({
            conditionType: newCondition.conditionType,
            isMet: false,
            targetTime: newCondition.targetTime,
            oracleQueryId: newCondition.oracleQueryId,
            oracleExpectedResult: newCondition.oracleExpectedResult,
            dependencyEntryId: newCondition.dependencyEntryId,
            dependencyTargetState: newCondition.dependencyTargetState,
            // Mappings/dynamic arrays initialized
            approvals: newCondition.approvals, // Initialize mapping
            requiredApprovals: newCondition.requiredApprovals,
            approvers: new address[](0), // Initialize dynamic array
            currentApprovalsCount: 0
        }));

        // Validate ApprovalBased condition setup
        require(newCondition.conditionType != ConditionType.ApprovalBased || newCondition.requiredApprovals > 0, "Approval condition requires >0 approvals");


        // If the entry was ReadyForRelease and a new condition is added, it goes back to Locked
        if (entry.currentState == VaultState.ReadyForRelease) {
            _changeState(entryId, VaultState.LockedByConditions, "New condition added");
        }

        emit ConditionAdded(entryId, conditionIndex, newCondition.conditionType);
    }

    /// @dev Removes a condition from an existing vault entry.
    /// @param entryId The ID of the vault entry.
    /// @param conditionIndex The index of the condition to remove.
    function removeConditionFromEntry(uint256 entryId, uint256 conditionIndex)
        external
        onlyOperatorOrDepositor(entryId)
        entryExists(entryId)
        whenNotPaused
    {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState != VaultState.Released && entry.currentState != VaultState.Expired, "Entry is finalized");
        require(conditionIndex < entry.conditions.length, "Condition index out of bounds");

        // To remove from dynamic array, swap with last element and pop
        uint lastIndex = entry.conditions.length - 1;
        if (conditionIndex != lastIndex) {
            entry.conditions[conditionIndex] = entry.conditions[lastIndex];
        }
        entry.conditions.pop();

        // If entry was LockedByConditions and this removal makes all remaining conditions met,
        // the state will be updated on the next triggerMeasurement.
        // No state change needed here unless it was the *last* condition removed,
        // in which case it might transition, but triggerMeasurement handles full evaluation.

        emit ConditionRemoved(entryId, conditionIndex);
    }


    /// @dev Updates the beneficiary address for a vault entry.
    /// @param entryId The ID of the vault entry.
    /// @param newBeneficiary The new beneficiary address.
    function updateBeneficiary(uint256 entryId, address newBeneficiary)
        external
        onlyOperatorOrDepositor(entryId)
        entryExists(entryId)
        whenNotPaused
    {
        require(newBeneficiary != address(0), "New beneficiary cannot be zero address");
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState != VaultState.Released && entry.currentState != VaultState.Expired, "Entry is finalized");

        address oldBeneficiary = entry.beneficiary;
        entry.beneficiary = newBeneficiary;

        emit BeneficiaryUpdated(entryId, oldBeneficiary, newBeneficiary);
    }


    /// @dev Evaluates the conditions for a vault entry and potentially updates its state.
    /// This acts as the "measurement" function.
    /// @param entryId The ID of the vault entry.
    function triggerMeasurement(uint256 entryId) external onlyOperator entryExists(entryId) whenNotPaused {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState == VaultState.LockedByConditions || entry.currentState == VaultState.Pending, "Entry is not in a state requiring measurement");

        bool allConditionsMet = true;
        for (uint i = 0; i < entry.conditions.length; i++) {
            // Evaluate isMet dynamically
             if (!isConditionMet(entryId, i)) {
                 allConditionsMet = false;
                 break; // No need to check further conditions
             }
        }

        if (allConditionsMet) {
            _changeState(entryId, VaultState.ReadyForRelease, "All conditions met after measurement");
        }
        // If not all conditions are met, state remains LockedByConditions (or Pending)
    }

    /// @dev Helper function to check if a specific condition is currently met.
    /// @param entryId The ID of the vault entry.
    /// @param conditionIndex The index of the condition.
    /// @return True if the condition is met, false otherwise.
    function isConditionMet(uint256 entryId, uint256 conditionIndex) public view entryExists(entryId) returns (bool) {
         VaultEntry storage entry = vaultEntries[entryId];
         require(conditionIndex < entry.conditions.length, "Condition index out of bounds");
         Condition storage condition = entry.conditions[conditionIndex];

         if (condition.conditionType == ConditionType.TimeBased) {
             return block.timestamp >= condition.targetTime;
         } else if (condition.conditionType == ConditionType.OracleBased) {
             // This requires external callback from oracle.
             // The `fulfillOracleQuery` would update a mapping storing results by query ID.
             // Here we check that mapping.
             // For simulation purposes, let's assume a helper mapping exists:
             // mapping(uint256 => bytes32) private oracleResults;
             // Then check: return oracleResults[condition.oracleQueryId] == condition.oracleExpectedResult;
             // Since we don't have a live oracle, this check is illustrative.
             // A real implementation needs a robust oracle integration pattern (e.g., Chainlink).
             // For this example, let's simulate by assuming condition is met if a result was "received" matching expected.
             // We'll need to add a simulated way to "receive" results.
             // Let's assume `oracleResults[condition.oracleQueryId]` is set by `fulfillOracleQuery`.
             // We can't directly check `oracleResults` in a view function without a state variable.
             // Let's just return false for OracleBased conditions in this view function,
             // as their status is meant to be updated by the oracle callback.
             // A real system would check state updated by the oracle callback.
             // Let's return true if the simulated result matches (requires state variable).
             // For demonstration, let's add a dummy oracle result mapping.
             // mapping(uint256 => bytes32) private simulatedOracleResults; // <-- Add this to state
             return simulatedOracleResults[condition.oracleQueryId] == condition.oracleExpectedResult;

         } else if (condition.conditionType == ConditionType.DependencyBased) {
             VaultEntry storage dependencyEntry = vaultEntries[condition.dependencyEntryId];
             // Check if dependency entry exists and is in the target state
             return dependencyEntry.depositTime > 0 && dependencyEntry.currentState == condition.dependencyTargetState;
         } else if (condition.conditionType == ConditionType.ApprovalBased) {
             return condition.currentApprovalsCount >= condition.requiredApprovals;
         }

         return false; // Unknown condition type
    }

    // Dummy mapping to simulate oracle results being available
    mapping(uint256 => bytes32) private simulatedOracleResults;

    /// @dev Simulates an oracle callback providing a result for a query.
    /// In a real scenario, this would be callable only by a trusted oracle address.
    /// @param oracleQueryId The ID of the query.
    /// @param result The result of the query.
    function fulfillOracleQuery(uint256 oracleQueryId, bytes32 result) external {
        // In a real contract, add require(msg.sender == oracleAddress);
        simulatedOracleResults[oracleQueryId] = result;
        // Note: This doesn't automatically trigger measurement. An operator would still
        // need to call `triggerMeasurement` after the oracle result is known.
    }

    /// @dev Provides an approval for an ApprovalBased condition within an entry.
    /// Any address can approve by default. Logic can be added to restrict approvers.
    /// @param entryId The ID of the vault entry.
    function approveCondition(uint256 entryId) external entryExists(entryId) whenNotPaused {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState != VaultState.Released && entry.currentState != VaultState.Expired, "Entry is finalized");

        bool approvedAny = false;
        for (uint i = 0; i < entry.conditions.length; i++) {
            Condition storage condition = entry.conditions[i];
            if (condition.conditionType == ConditionType.ApprovalBased && !condition.approvals[msg.sender] && condition.currentApprovalsCount < condition.requiredApprovals) {
                 condition.approvals[msg.sender] = true;
                 // Add approver to list if not already present (to track unique approvers)
                 bool alreadyAdded = false;
                 for(uint j = 0; j < condition.approvers.length; j++) {
                     if (condition.approvers[j] == msg.sender) {
                         alreadyAdded = true;
                         break;
                     }
                 }
                 if (!alreadyAdded) {
                    condition.approvers.push(msg.sender);
                    condition.currentApprovalsCount++; // Increment unique approver count
                 }

                 approvedAny = true;
                 emit ConditionApproved(entryId, msg.sender);

                 // Optional: Trigger measurement immediately if this approval met a condition
                 // if (condition.currentApprovalsCount >= condition.requiredApprovals) {
                 //     triggerMeasurement(entryId); // This would require approveCondition to be onlyOperator? Or call a public helper?
                 //     // Calling state-changing functions from loops can be gas intensive.
                 //     // It's safer to require the Operator to call triggerMeasurement separately.
                 // }
            }
        }
         require(approvedAny, "No approval needed or possible for this entry by sender");
    }


    /// @dev Initiates a challenge for a vault entry, setting its state to Challenged.
    /// This can be called by anyone, but its resolution requires an Operator.
    /// @param entryId The ID of the vault entry.
    /// @param reason A string explaining the reason for the challenge.
    function challengeState(uint256 entryId, string calldata reason)
        external
        entryExists(entryId)
        whenNotPaused
    {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState != VaultState.Released && entry.currentState != VaultState.Expired && entry.currentState != VaultState.Challenged, "Entry cannot be challenged in its current state");

        _changeState(entryId, VaultState.Challenged, reason);

        emit ChallengeInitiated(entryId, msg.sender, reason);
    }

    /// @dev Resolves a challenged vault entry. An operator decides the next state.
    /// @param entryId The ID of the vault entry.
    /// @param releaseDecision If true, moves to ReadyForRelease (if conditions allow), otherwise back to LockedByConditions.
    function resolveChallenge(uint256 entryId, bool releaseDecision)
        external
        onlyOperator
        entryExists(entryId)
        whenNotPaused
    {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState == VaultState.Challenged, "Entry is not in Challenged state");

        if (releaseDecision) {
            // Re-evaluate conditions before going to ReadyForRelease
            bool allConditionsMet = true;
             for (uint i = 0; i < entry.conditions.length; i++) {
                 if (!isConditionMet(entryId, i)) {
                     allConditionsMet = false;
                     break;
                 }
             }
            if (allConditionsMet) {
                _changeState(entryId, VaultState.ReadyForRelease, "Challenge resolved: Conditions met");
            } else {
                _changeState(entryId, VaultState.LockedByConditions, "Challenge resolved: Conditions not yet met");
            }
        } else {
            _changeState(entryId, VaultState.LockedByConditions, "Challenge resolved: Denied release");
        }

        emit ChallengeResolved(entryId, releaseDecision);
    }

    // Internal helper function to change state and emit event
    function _changeState(uint256 entryId, VaultState newState, string memory reason) internal {
        VaultEntry storage entry = vaultEntries[entryId];
        VaultState oldState = entry.currentState;
        entry.currentState = newState;
        emit StateChanged(entryId, oldState, newState, reason);
    }

    // --- Withdrawal Functions ---

    /// @dev Releases funds from a vault entry if it is in the ReadyForRelease state.
    /// Callable by the beneficiary or an operator.
    /// @param entryId The ID of the vault entry.
    function releaseFunds(uint256 entryId)
        external
        entryExists(entryId)
        whenNotPaused
        nonReentrant
    {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState == VaultState.ReadyForRelease, "Entry not ready for release");
        require(msg.sender == entry.beneficiary || isOperator[msg.sender], "Not authorized to release");
        require(entry.amount > 0, "Entry has no funds");

        uint256 amountToRelease = entry.amount; // Release full amount

        address tokenAddress = entry.tokenAddress;
        entry.amount = 0; // Set amount to 0 *before* transfer (Checks-Effects-Interactions)

        if (tokenAddress == address(0)) {
            // Release ETH
            (bool success, ) = payable(entry.beneficiary).call{value: amountToRelease}("");
            require(success, "ETH transfer failed");
        } else {
            // Release ERC20
            IERC20 token = IERC20(tokenAddress);
            token.safeTransfer(entry.beneficiary, amountToRelease);
        }

        _changeState(entryId, VaultState.Released, "Funds released");
        emit FundsReleased(entryId, entry.beneficiary, tokenAddress, amountToRelease);

        // Consider adding logic for cleaning up storage for released entries if gas becomes an issue
        // delete vaultEntries[entryId]; // This frees up storage cost but removes history
    }

    /// @dev Allows an operator to withdraw funds in specific emergency situations (e.g., contract paused).
    /// Implementation should be very careful to avoid abuse. Example: only allowed if paused.
    /// @param entryId The ID of the vault entry.
    function emergencyOperatorWithdraw(uint256 entryId)
        external
        onlyOperator
        entryExists(entryId)
        whenPaused // Only allowed when contract is paused
        nonReentrant
    {
        VaultEntry storage entry = vaultEntries[entryId];
        require(entry.currentState != VaultState.Released && entry.currentState != VaultState.Expired, "Entry is already finalized");
        require(entry.amount > 0, "Entry has no funds");

        uint256 amountToWithdraw = entry.amount;
        address tokenAddress = entry.tokenAddress;

        // Operator withdraws to their own address or a designated emergency address?
        // Let's allow withdrawal to the operator's address for simplicity in this example.
        // A real emergency function might be more complex or only allow withdrawal to owner.
        address emergencyRecipient = msg.sender;

        entry.amount = 0; // Checks-Effects-Interactions

        if (tokenAddress == address(0)) {
             (bool success, ) = payable(emergencyRecipient).call{value: amountToWithdraw}("");
            require(success, "ETH emergency transfer failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.safeTransfer(emergencyRecipient, amountToWithdraw);
        }

        // Mark entry as potentially resolved or moved to a special emergency state
        _changeState(entryId, VaultState.Released, "Funds emergency withdrawn by operator"); // Mark as released to prevent further action
        emit EmergencyWithdrawal(entryId, emergencyRecipient, amountToWithdraw);
    }

    // --- Querying Functions ---

    /// @dev Gets the current state of a vault entry.
    /// @param entryId The ID of the vault entry.
    /// @return The current VaultState.
    function getEntryState(uint256 entryId) public view entryExists(entryId) returns (VaultState) {
        return vaultEntries[entryId].currentState;
    }

    /// @dev Gets all details of a vault entry.
    /// @param entryId The ID of the vault entry.
    /// @return The VaultEntry struct.
    function getEntryDetails(uint256 entryId) public view entryExists(entryId) returns (VaultEntry memory) {
         // Need to reconstruct struct for return as mapping value cannot be returned directly with dynamic parts
         VaultEntry storage entry = vaultEntries[entryId];
         // Deep copy conditions array
         Condition[] memory conditionsCopy = new Condition[entry.conditions.length];
         for(uint i = 0; i < entry.conditions.length; i++) {
             Condition storage originalCondition = entry.conditions[i];
             conditionsCopy[i].conditionType = originalCondition.conditionType;
             conditionsCopy[i].isMet = isConditionMet(entryId, i); // Evaluate dynamically
             conditionsCopy[i].targetTime = originalCondition.targetTime;
             conditionsCopy[i].oracleQueryId = originalCondition.oracleQueryId;
             conditionsCopy[i].oracleExpectedResult = originalCondition.oracleExpectedResult;
             conditionsCopy[i].dependencyEntryId = originalCondition.dependencyEntryId;
             conditionsCopy[i].dependencyTargetState = originalCondition.dependencyTargetState;
             // Note: Mappings (approvals) and dynamic arrays (approvers) within a struct
             // cannot be returned directly from a public function via the struct.
             // We would need separate getter functions for these, or modify the struct
             // to exclude them for public view purposes or return a simplified version.
             // For this example, we'll omit the mapping/dynamic array fields in the returned struct copy.
             // Let's return a simplified struct or use separate getters for conditions.
             // Re-evaluating: Solidity ^0.8.0 allows returning structs with dynamic arrays,
             // but mappings are still problematic. Let's return a simplified version of the struct
             // that excludes the mappings. Or, better, return the full struct and let clients
             // handle fetching mapping data via dedicated getters if needed.
             // Let's try returning the full struct copy including dynamic arrays but acknowledging
             // that mappings within it won't be readable via web3 calls in the standard way.
             conditionsCopy[i].requiredApprovals = originalCondition.requiredApprovals;
             conditionsCopy[i].currentApprovalsCount = originalCondition.currentApprovalsCount;
             // Approvers list copy - deep copy
             conditionsCopy[i].approvers = new address[](originalCondition.approvers.length);
             for(uint j=0; j<originalCondition.approvers.length; j++) {
                 conditionsCopy[i].approvers[j] = originalCondition.approvers[j];
             }
         }


         return VaultEntry({
             depositor: entry.depositor,
             beneficiary: entry.beneficiary,
             tokenAddress: entry.tokenAddress,
             amount: entry.amount,
             currentState: entry.currentState,
             conditions: conditionsCopy, // Return the deep copy
             metadata: entry.metadata,
             depositTime: entry.depositTime
             // approvals mapping is not part of this returned struct copy
         });
    }

     /// @dev Gets the list of conditions for a vault entry.
     /// Note: Mappings within conditions (like 'approvals') are not returned here.
     /// @param entryId The ID of the vault entry.
     /// @return An array of Condition structs (without the approvals mapping).
    function getConditions(uint256 entryId) public view entryExists(entryId) returns (Condition[] memory) {
        VaultEntry storage entry = vaultEntries[entryId];
        Condition[] storage originalConditions = entry.conditions;
        Condition[] memory conditionsCopy = new Condition[originalConditions.length];

        for (uint i = 0; i < originalConditions.length; i++) {
             Condition storage originalCondition = originalConditions[i];
             conditionsCopy[i].conditionType = originalCondition.conditionType;
             conditionsCopy[i].isMet = isConditionMet(entryId, i); // Evaluate dynamically
             conditionsCopy[i].targetTime = originalCondition.targetTime;
             conditionsCopy[i].oracleQueryId = originalCondition.oracleQueryId;
             conditionsCopy[i].oracleExpectedResult = originalCondition.oracleExpectedResult;
             conditionsCopy[i].dependencyEntryId = originalCondition.dependencyEntryId;
             conditionsCopy[i].dependencyTargetState = originalCondition.dependencyTargetState;
             conditionsCopy[i].requiredApprovals = originalCondition.requiredApprovals;
             conditionsCopy[i].currentApprovalsCount = originalCondition.currentApprovalsCount;

             // Deep copy approvers list
             conditionsCopy[i].approvers = new address[](originalCondition.approvers.length);
             for(uint j=0; j<originalCondition.approvers.length; j++) {
                 conditionsCopy[i].approvers[j] = originalCondition.approvers[j];
             }
             // approvals mapping is omitted
         }
         return conditionsCopy;
    }

    /// @dev Gets the list of addresses that have approved a specific ApprovalBased condition.
    /// @param entryId The ID of the vault entry.
    /// @param conditionIndex The index of the condition (must be ApprovalBased).
    /// @return An array of approver addresses.
    function getConditionApprovers(uint256 entryId, uint256 conditionIndex) public view entryExists(entryId) returns (address[] memory) {
        VaultEntry storage entry = vaultEntries[entryId];
        require(conditionIndex < entry.conditions.length, "Condition index out of bounds");
        Condition storage condition = entry.conditions[conditionIndex];
        require(condition.conditionType == ConditionType.ApprovalBased, "Condition is not ApprovalBased");

        // Return the stored approvers list
        return condition.approvers;
    }

    /// @dev Gets the number of unique approvers for a specific ApprovalBased condition.
    /// @param entryId The ID of the vault entry.
    /// @param conditionIndex The index of the condition (must be ApprovalBased).
    /// @return The count of current unique approvals.
    function getConditionApprovalCount(uint256 entryId, uint256 conditionIndex) public view entryExists(entryId) returns (uint256) {
        VaultEntry storage entry = vaultEntries[entryId];
        require(conditionIndex < entry.conditions.length, "Condition index out of bounds");
        Condition storage condition = entry.conditions[conditionIndex];
        require(condition.conditionType == ConditionType.ApprovalBased, "Condition is not ApprovalBased");

        return condition.currentApprovalsCount;
    }

    // Note: getEntryDetails includes condition details, so this might be slightly redundant,
    // but explicitly checking a single condition's status is useful.


    /// @dev Allows receiving Ether.
    receive() external payable whenNotPaused {}
    fallback() external payable whenNotPaused {}

}
```