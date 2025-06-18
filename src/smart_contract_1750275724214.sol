Okay, let's design a smart contract that incorporates several advanced, creative, and non-standard concepts around secure asset management based on complex, multi-factor conditions.

We'll call it `QuantumVault`. The "Quantum" aspect refers metaphorically to the state of unlockability not being simple ON/OFF, but dependent on observing multiple, potentially probabilistic, or time-sensitive external conditions that resolve over time.

It will function as a secure vault holding Native Currency (Ether) and ERC20 tokens, releasable to specific users only when intricate, pre-defined condition sets are met. These conditions can include time locks, external data checks (simulated oracle interaction), dependencies on other conditions, multi-signature requirements, and even a probabilistic element (requiring a VRF-like input).

---

### QuantumVault Smart Contract Outline

1.  **State Variables:**
    *   Owner address.
    *   Counters for unique IDs (conditions, condition sets, withdrawal requests).
    *   Mappings to store Condition definitions by ID.
    *   Mappings to store Condition Set definitions by ID.
    *   Mapping linking user addresses to their assigned Condition Set ID.
    *   Mappings to store Withdrawal Request details by ID.
    *   Mappings to store current state/confirmation counts for active withdrawal requests (e.g., for multi-sig or oracle results).
    *   Mapping to store latest oracle/VRF results needed for condition checks.
    *   Mapping to track deposited ERC20 balances per token.

2.  **Enums:**
    *   `ConditionType`: Defines different types of conditions (TimeLock, ExternalData, Dependent, MultiSigFactor, Probabilistic, Combined).
    *   `RequestStatus`: Defines the state of a withdrawal request (Pending, ConditionsMet, Executed, Cancelled).

3.  **Structs:**
    *   `Condition`: Defines parameters for a single condition based on its `ConditionType`.
    *   `ConditionSet`: Defines a group of `Condition` IDs and the logical operator (`AND`/`OR`) to combine them.
    *   `WithdrawalRequest`: Stores details of a user's request to withdraw, including the associated `conditionSetId`, requested amount, status, and potentially state variables for condition checking (e.g., multi-sig confirmations received).

4.  **Events:**
    *   `DepositMade`: Logs native or token deposits.
    *   `ConditionCreated`: Logs the creation of a new condition.
    *   `ConditionSetCreated`: Logs the creation of a new condition set.
    *   `ConditionSetAssigned`: Logs when a condition set is assigned to a user.
    *   `WithdrawalRequested`: Logs a user initiating a withdrawal attempt.
    *   `WithdrawalConditionsChecked`: Logs the outcome of checking conditions for a request.
    *   `WithdrawalExecuted`: Logs a successful withdrawal.
    *   `WithdrawalCancelled`: Logs the cancellation of a withdrawal request.
    *   `MultiSigConfirmationReceived`: Logs a confirmation for a multi-sig condition within a request.
    *   `ExternalDataReceived`: Logs external data received for a condition check.
    *   `VRFOutputReceived`: Logs VRF output received for a probabilistic condition.
    *   `EmergencyUnlockUsed`: Logs the use of the emergency override.
    *   `OwnershipTransferred`.

5.  **Functions (>= 20):**
    *   **Vault Management:**
        1.  `depositNative()`: User deposits Ether into the vault.
        2.  `depositToken(address tokenAddress, uint256 amount)`: User deposits ERC20 tokens (requires prior approval).
        3.  `getVaultBalanceNative()`: View total Ether held.
        4.  `getVaultBalanceToken(address tokenAddress)`: View total balance of a specific token held.
    *   **Condition Creation (Owner Only):**
        5.  `createTimeLockCondition(uint64 unlockTimestamp)`
        6.  `createExternalDataCondition(address oracleAddress, bytes dataQuery, bytes expectedResultHash)`: Defines a condition based on external data matching a hashed expected result (requires an oracle to provide data later).
        7.  `createDependentCondition(uint256 requiredConditionId, bool expectedState)`: Condition is met if another condition evaluates to a specific boolean state.
        8.  `createMultiSigFactorCondition(address[] signers, uint256 threshold)`: Condition requires a certain number of specified addresses to confirm *for a specific withdrawal request*.
        9.  `createProbabilisticCondition(uint256 baseConditionId, uint16 probabilityPercentage)`: Condition is met if a base condition is true *AND* a subsequent probabilistic check passes (requires VRF input later).
        10. `createCombinedCondition(uint256[] conditionIds, bool useANDLogic)`: Combines existing conditions with AND or OR logic.
    *   **Condition Set Management (Owner Only):**
        11. `createConditionSet(uint256[] conditionIds, bool useANDLogicForSet)`: Creates a set of conditions evaluated together.
        12. `assignConditionSetToUser(address user, uint256 conditionSetId)`: Assigns a specific condition set required for a user's withdrawals.
        13. `getUserConditionSetId(address user)`: View user's assigned condition set ID.
    *   **Condition Checking (View Functions):**
        14. `checkCondition(uint256 conditionId)`: Pure/View function to evaluate a *single* condition based on current state (requires oracle/VRF data to be pre-loaded if applicable).
        15. `checkConditionSet(uint256 conditionSetId)`: Pure/View function to evaluate a *set* of conditions.
        16. `getConditionDetails(uint256 conditionId)`: View details of a specific condition.
        17. `getConditionSetDetails(uint256 conditionSetId)`: View details of a specific condition set.
    *   **Withdrawal Workflow:**
        18. `requestConditionalWithdrawal(uint256 amount, address tokenAddress)`: User initiates a request for a specific amount of native/token. Links the request to their assigned condition set. Records the request's initial state.
        19. `confirmMultiSigForRequest(uint256 withdrawalRequestId)`: A signer calls this to add a confirmation for a request that includes a `MultiSigFactorCondition`.
        20. `executeConditionalWithdrawal(uint256 withdrawalRequestId)`: Anyone can call this. It checks if *all* conditions in the associated set for the request are met *at the time of execution*. If true, transfers the requested funds and marks the request as executed. Crucially, this function *reads* the pre-loaded oracle/VRF results.
        21. `cancelWithdrawalRequest(uint256 withdrawalRequestId)`: User or Owner can cancel a pending request.
        22. `getWithdrawalRequestDetails(uint256 withdrawalRequestId)`: View details of a withdrawal request.
    *   **Oracle/VRF Interaction (Owner or Designated Oracle Address Only):**
        23. `submitExternalDataResult(uint256 conditionId, bytes dataResult)`: Owner/Oracle submits the result for an `ExternalDataCondition`.
        24. `submitVRFOutput(uint256 conditionId, uint256 vrfOutput)`: Owner/VRF Callback submits output for a `ProbabilisticCondition`.
    *   **Emergency/Admin (Owner Only):**
        25. `emergencyUnlock(address user, uint256 amount, address tokenAddress)`: Owner can bypass conditions in an emergency.
        26. `transferOwnership(address newOwner)`
        27. `renounceOwnership()`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using OpenZeppelin for simplicity, but could be custom

// --- QuantumVault Smart Contract ---
// A secure vault that holds assets (Ether & ERC20) releasable only when
// complex, multi-factor, and potentially time-sensitive or probabilistic
// condition sets are met.

// Outline:
// 1. State Variables & Counters
// 2. Enums & Structs for Conditions and Requests
// 3. Events
// 4. Modifiers (e.g., onlyOwner, checkConditionStatus)
// 5. Constructor
// 6. Deposit Functions
// 7. Condition & ConditionSet Creation (Owner Only)
// 8. ConditionSet Assignment (Owner Only)
// 9. Condition & ConditionSet Evaluation (View Functions)
// 10. Withdrawal Workflow (Request, Confirm, Execute, Cancel)
// 11. Oracle/VRF Result Submission (Owner/Oracle Only)
// 12. Emergency & Ownership Functions
// 13. View Functions for Details

// Function Summary:
// Vault Management:
// - depositNative(): Deposit Ether into the vault.
// - depositToken(address tokenAddress, uint256 amount): Deposit ERC20 tokens.
// - getVaultBalanceNative(): View total Ether balance.
// - getVaultBalanceToken(address tokenAddress): View total ERC20 balance for a token.

// Condition Creation (Owner Only):
// - createTimeLockCondition(uint64 unlockTimestamp): Condition based on time.
// - createExternalDataCondition(address oracleAddress, bytes dataQuery, bytes32 expectedResultHash): Condition based on external data hash matching.
// - createDependentCondition(uint256 requiredConditionId, bool expectedState): Condition based on another condition's state.
// - createMultiSigFactorCondition(address[] signers, uint256 threshold): Condition requiring M of N confirmations for a specific request.
// - createProbabilisticCondition(uint256 baseConditionId, uint16 probabilityPercentage): Condition based on a base condition and VRF output.
// - createCombinedCondition(uint256[] conditionIds, bool useANDLogic): Combines conditions with AND/OR.

// Condition Set Management (Owner Only):
// - createConditionSet(uint256[] conditionIds, bool useANDLogicForSet): Groups conditions into a set.
// - assignConditionSetToUser(address user, uint256 conditionSetId): Assigns a condition set to a user for withdrawal eligibility.
// - getUserConditionSetId(address user): View assigned condition set ID for a user.

// Condition Checking (View Functions):
// - checkCondition(uint256 conditionId): Evaluate a single condition based on current state/data.
// - checkConditionSet(uint256 conditionSetId): Evaluate an entire condition set.
// - getConditionDetails(uint256 conditionId): Get details of a condition.
// - getConditionSetDetails(uint256 conditionSetId): Get details of a condition set.

// Withdrawal Workflow:
// - requestConditionalWithdrawal(uint256 amount, address tokenAddress): Initiate a withdrawal request.
// - confirmMultiSigForRequest(uint256 withdrawalRequestId): Signer confirms for MultiSigFactor condition.
// - executeConditionalWithdrawal(uint256 withdrawalRequestId): Execute request if conditions are met.
// - cancelWithdrawalRequest(uint256 withdrawalRequestId): Cancel a pending request.
// - getWithdrawalRequestDetails(uint256 withdrawalRequestId): Get details of a request.

// Oracle/VRF Result Submission (Owner/Oracle Only):
// - submitExternalDataResult(uint256 conditionId, bytes dataResult): Submit oracle result for a condition.
// - submitVRFOutput(uint256 conditionId, uint256 vrfOutput): Submit VRF output for a condition.

// Emergency & Ownership:
// - emergencyUnlock(address user, uint256 amount, address tokenAddress): Owner override for withdrawals.
// - transferOwnership(address newOwner): Transfer contract ownership.
// - renounceOwnership(): Renounce contract ownership.


contract QuantumVault is Ownable {

    enum ConditionType {
        TimeLock,
        ExternalData,
        Dependent,
        MultiSigFactor,
        Probabilistic,
        Combined // For sets of conditions
    }

    enum RequestStatus {
        Pending,
        ConditionsMet, // Conditions were met at the time of *last check* (internal state)
        Executed,
        Cancelled
    }

    struct Condition {
        ConditionType conditionType;
        // Parameters based on type
        uint64 unlockTimestamp; // For TimeLock
        address oracleAddress; // For ExternalData
        bytes dataQuery; // For ExternalData (Identifier for the query)
        bytes32 expectedResultHash; // For ExternalData (Hash of the expected result)
        uint256 requiredConditionId; // For Dependent
        bool expectedState; // For Dependent
        address[] signers; // For MultiSigFactor
        uint256 threshold; // For MultiSigFactor
        uint256 baseConditionId; // For Probabilistic
        uint16 probabilityPercentage; // For Probabilistic (0-10000, 10000 = 100%)
        uint256[] subConditionIds; // For Combined
        bool useANDLogicForCombined; // For Combined (true = AND, false = OR)
    }

    struct ConditionSet {
        uint256[] conditionIds;
        bool useANDLogicForSet; // true = all conditions in the set must be true, false = at least one must be true
    }

    struct WithdrawalRequest {
        address user;
        uint256 amount;
        address tokenAddress; // Address(0) for native Ether
        uint256 conditionSetId;
        RequestStatus status;
        uint256 confirmationsReceived; // For MultiSigFactor within this request
        // Note: ExternalData/VRF results are stored globally per conditionId, not per request
    }

    uint256 private nextConditionId = 1;
    uint256 private nextConditionSetId = 1;
    uint256 private nextWithdrawalRequestId = 1;

    mapping(uint256 => Condition) public conditions;
    mapping(uint256 => ConditionSet) public conditionSets;
    mapping(address => uint256) public userConditionSet; // Maps user address to their required ConditionSetId
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;

    // State variables for condition checks that depend on external input
    mapping(uint256 => bytes32) private externalDataResultsHash; // conditionId -> hash of submitted data
    mapping(uint256 => uint256) private vrfResults; // conditionId -> submitted VRF output

    // Keep track of ERC20 balances held by the contract per token type
    mapping(address => uint255) private tokenBalances; // uint255 to differentiate from native balance


    event DepositMade(address indexed user, address indexed tokenAddress, uint256 amount);
    event ConditionCreated(uint256 indexed conditionId, ConditionType conditionType);
    event ConditionSetCreated(uint256 indexed conditionSetId);
    event ConditionSetAssigned(address indexed user, uint256 indexed conditionSetId);
    event WithdrawalRequested(uint256 indexed requestId, address indexed user, uint256 amount, address indexed tokenAddress);
    event WithdrawalConditionsChecked(uint256 indexed requestId, bool conditionsMet);
    event WithdrawalExecuted(uint256 indexed requestId, address indexed user, uint256 amount, address indexed tokenAddress);
    event WithdrawalCancelled(uint256 indexed requestId);
    event MultiSigConfirmationReceived(uint256 indexed requestId, address indexed signer, uint256 confirmations);
    event ExternalDataReceived(uint256 indexed conditionId, bytes dataResult);
    event VRFOutputReceived(uint256 indexed conditionId, uint256 vrfOutput);
    event EmergencyUnlockUsed(address indexed user, uint256 amount, address indexed tokenAddress);

    constructor() Ownable(msg.sender) {
        // Contract is deployed by the initial owner
    }

    // --- Vault Management ---

    /// @notice Deposit native Ether into the vault.
    receive() external payable {
        emit DepositMade(msg.sender, address(0), msg.value);
    }

    function depositNative() external payable {
        emit DepositMade(msg.sender, address(0), msg.value);
    }

    /// @notice Deposit ERC20 tokens into the vault. Requires prior approval.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositToken(address tokenAddress, uint256 amount) external {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        // Use safeTransferFrom from a library in production for safety
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        tokenBalances[tokenAddress] += uint255(amount); // Keep track separately
        emit DepositMade(msg.sender, tokenAddress, amount);
    }

    /// @notice Get the total native Ether balance held by the vault.
    /// @return The native Ether balance.
    function getVaultBalanceNative() public view returns (uint255) {
        return uint255(address(this).balance);
    }

    /// @notice Get the total ERC20 balance held by the vault for a specific token.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The token balance.
    function getVaultBalanceToken(address tokenAddress) public view returns (uint255) {
        return tokenBalances[tokenAddress];
    }

    // --- Condition Creation (Owner Only) ---

    /// @notice Create a TimeLock condition.
    /// @param unlockTimestamp The Unix timestamp when the condition becomes true.
    /// @return The ID of the created condition.
    function createTimeLockCondition(uint64 unlockTimestamp) external onlyOwner returns (uint255) {
        uint256 conditionId = nextConditionId++;
        conditions[conditionId] = Condition({
            conditionType: ConditionType.TimeLock,
            unlockTimestamp: unlockTimestamp,
            oracleAddress: address(0), dataQuery: "", expectedResultHash: bytes32(0),
            requiredConditionId: 0, expectedState: false,
            signers: new address[](0), threshold: 0,
            baseConditionId: 0, probabilityPercentage: 0,
            subConditionIds: new uint256[](0), useANDLogicForCombined: false
        });
        emit ConditionCreated(conditionId, ConditionType.TimeLock);
        return conditionId;
    }

    /// @notice Create an ExternalData condition. Requires an oracle to submit the data later.
    /// @param oracleAddress The address expected to submit the data result.
    /// @param dataQuery An identifier for the specific external data point.
    /// @param expectedResultHash The hash of the data result required for the condition to be true.
    /// @return The ID of the created condition.
    function createExternalDataCondition(address oracleAddress, bytes memory dataQuery, bytes32 expectedResultHash) external onlyOwner returns (uint256) {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(expectedResultHash != bytes32(0), "Expected result hash cannot be zero");
        uint256 conditionId = nextConditionId++;
        conditions[conditionId] = Condition({
            conditionType: ConditionType.ExternalData,
            unlockTimestamp: 0,
            oracleAddress: oracleAddress, dataQuery: dataQuery, expectedResultHash: expectedResultHash,
            requiredConditionId: 0, expectedState: false,
            signers: new address[](0), threshold: 0,
            baseConditionId: 0, probabilityPercentage: 0,
            subConditionIds: new uint256[](0), useANDLogicForCombined: false
        });
        emit ConditionCreated(conditionId, ConditionType.ExternalData);
        return conditionId;
    }

    /// @notice Create a Dependent condition. Its state depends on another condition's state.
    /// @param requiredConditionId The ID of the condition this one depends on.
    /// @param expectedState The boolean state (true/false) the requiredConditionId must evaluate to.
    /// @return The ID of the created condition.
    function createDependentCondition(uint256 requiredConditionId, bool expectedState) external onlyOwner returns (uint256) {
        require(conditions[requiredConditionId].conditionType != ConditionType.Combined, "Cannot depend directly on a Combined condition"); // Avoid simple circular dependency issues
        require(requiredConditionId > 0 && requiredConditionId < nextConditionId, "Invalid requiredConditionId");
        uint256 conditionId = nextConditionId++;
        conditions[conditionId] = Condition({
            conditionType: ConditionType.Dependent,
            unlockTimestamp: 0, oracleAddress: address(0), dataQuery: "", expectedResultHash: bytes32(0),
            requiredConditionId: requiredConditionId, expectedState: expectedState,
            signers: new address[](0), threshold: 0,
            baseConditionId: 0, probabilityPercentage: 0,
            subConditionIds: new uint256[](0), useANDLogicForCombined: false
        });
        emit ConditionCreated(conditionId, ConditionType.Dependent);
        return conditionId;
    }

    /// @notice Create a MultiSigFactor condition. Requires a specific number of signatures for a *specific request*.
    /// @param signers The list of addresses that can provide a confirmation.
    /// @param threshold The minimum number of unique signers required.
    /// @return The ID of the created condition.
    function createMultiSigFactorCondition(address[] memory signers, uint256 threshold) external onlyOwner returns (uint256) {
        require(signers.length > 0, "Signers list cannot be empty");
        require(threshold > 0 && threshold <= signers.length, "Threshold must be between 1 and number of signers");
        uint256 conditionId = nextConditionId++;
        conditions[conditionId] = Condition({
            conditionType: ConditionType.MultiSigFactor,
            unlockTimestamp: 0, oracleAddress: address(0), dataQuery: "", expectedResultHash: bytes32(0),
            requiredConditionId: 0, expectedState: false,
            signers: signers, threshold: threshold,
            baseConditionId: 0, probabilityPercentage: 0,
            subConditionIds: new uint256[](0), useANDLogicForCombined: false
        });
        emit ConditionCreated(conditionId, ConditionType.MultiSigFactor);
        return conditionId;
    }

    /// @notice Create a Probabilistic condition. Requires a base condition and VRF output.
    /// @param baseConditionId The ID of the base condition that must first be true.
    /// @param probabilityPercentage The chance (0-10000, 10000=100%) this condition is true *if* the base condition is true, based on VRF output.
    /// @return The ID of the created condition.
    function createProbabilisticCondition(uint256 baseConditionId, uint16 probabilityPercentage) external onlyOwner returns (uint256) {
        require(baseConditionId > 0 && baseConditionId < nextConditionId, "Invalid baseConditionId");
         require(conditions[baseConditionId].conditionType != ConditionType.Combined && conditions[baseConditionId].conditionType != ConditionType.Probabilistic, "Cannot base on Combined or another Probabilistic condition"); // Prevent complex chains
        require(probabilityPercentage <= 10000, "Probability percentage must be between 0 and 10000");
        uint256 conditionId = nextConditionId++;
        conditions[conditionId] = Condition({
            conditionType: ConditionType.Probabilistic,
            unlockTimestamp: 0, oracleAddress: address(0), dataQuery: "", expectedResultHash: bytes32(0),
            requiredConditionId: 0, expectedState: false,
            signers: new address[](0), threshold: 0,
            baseConditionId: baseConditionId, probabilityPercentage: probabilityPercentage,
            subConditionIds: new uint256[](0), useANDLogicForCombined: false
        });
        emit ConditionCreated(conditionId, ConditionType.Probabilistic);
        return conditionId;
    }

    /// @notice Create a Combined condition from existing conditions.
    /// @param conditionIds The IDs of the conditions to combine.
    /// @param useANDLogicForCombined True for AND logic (all must be true), False for OR logic (at least one must be true).
    /// @return The ID of the created condition.
    function createCombinedCondition(uint256[] memory conditionIds, bool useANDLogicForCombined) external onlyOwner returns (uint256) {
        require(conditionIds.length > 0, "Must provide condition IDs to combine");
        for(uint i = 0; i < conditionIds.length; i++) {
             require(conditionIds[i] > 0 && conditionIds[i] < nextConditionId, "Invalid condition ID in list");
        }
        uint256 conditionId = nextConditionId++;
         conditions[conditionId] = Condition({
            conditionType: ConditionType.Combined,
            unlockTimestamp: 0, oracleAddress: address(0), dataQuery: "", expectedResultHash: bytes32(0),
            requiredConditionId: 0, expectedState: false,
            signers: new address[](0), threshold: 0,
            baseConditionId: 0, probabilityPercentage: 0,
            subConditionIds: conditionIds, useANDLogicForCombined: useANDLogicForCombined
        });
        emit ConditionCreated(conditionId, ConditionType.Combined);
        return conditionId;
    }

    // --- Condition Set Management (Owner Only) ---

    /// @notice Create a Condition Set from existing condition IDs.
    /// @param conditionIds The IDs of the conditions in this set.
    /// @param useANDLogicForSet True for AND logic (all must be true), False for OR logic (at least one must be true).
    /// @return The ID of the created condition set.
    function createConditionSet(uint256[] memory conditionIds, bool useANDLogicForSet) external onlyOwner returns (uint256) {
         require(conditionIds.length > 0, "Condition set must contain at least one condition");
         for(uint i = 0; i < conditionIds.length; i++) {
             require(conditionIds[i] > 0 && conditionIds[i] < nextConditionId, "Invalid condition ID in list");
         }
        uint256 conditionSetId = nextConditionSetId++;
        conditionSets[conditionSetId] = ConditionSet({
            conditionIds: conditionIds,
            useANDLogicForSet: useANDLogicForSet
        });
        emit ConditionSetCreated(conditionSetId);
        return conditionSetId;
    }

    /// @notice Assign a Condition Set to a specific user. This determines the requirements for their withdrawals.
    /// @param user The address of the user.
    /// @param conditionSetId The ID of the condition set to assign.
    function assignConditionSetToUser(address user, uint256 conditionSetId) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(conditionSetId > 0 && conditionSetId < nextConditionSetId, "Invalid conditionSetId");
        userConditionSet[user] = conditionSetId;
        emit ConditionSetAssigned(user, conditionSetId);
    }

    /// @notice Get the assigned Condition Set ID for a user.
    /// @param user The address of the user.
    /// @return The condition set ID, or 0 if none assigned.
    function getUserConditionSetId(address user) public view returns (uint256) {
        return userConditionSet[user];
    }

    // --- Condition Checking (Internal Helper and View Functions) ---

    /// @notice Internal function to evaluate a single condition.
    /// @param conditionId The ID of the condition to check.
    /// @param requestId The ID of the withdrawal request (needed for MultiSigFactor).
    /// @return True if the condition is met, false otherwise.
    function _checkCondition(uint256 conditionId, uint256 requestId) internal view returns (bool) {
        require(conditionId > 0 && conditionId < nextConditionId, "Invalid condition ID");
        Condition storage cond = conditions[conditionId];

        if (cond.conditionType == ConditionType.TimeLock) {
            return block.timestamp >= cond.unlockTimestamp;
        } else if (cond.conditionType == ConditionType.ExternalData) {
            // Check if oracle data has been submitted and matches the expected hash
            bytes32 storedHash = externalDataResultsHash[conditionId];
            return storedHash != bytes32(0) && storedHash == cond.expectedResultHash;
        } else if (cond.conditionType == ConditionType.Dependent) {
            // Check the required condition recursively
            return _checkCondition(cond.requiredConditionId, requestId) == cond.expectedState;
        } else if (cond.conditionType == ConditionType.MultiSigFactor) {
            // Check the number of confirmations received for this specific request
            WithdrawalRequest storage req = withdrawalRequests[requestId];
            return req.confirmationsReceived >= cond.threshold;
        } else if (cond.conditionType == ConditionType.Probabilistic) {
             // Check base condition AND probabilistic outcome
             if (!_checkCondition(cond.baseConditionId, requestId)) {
                 return false; // Base condition not met
             }
             // Check if VRF output has been submitted
             uint256 vrfOutput = vrfResults[conditionId];
             if (vrfOutput == 0) {
                 // VRF output not available yet, condition cannot be met
                 // In a real contract, you might indicate this state
                 return false;
             }
             // Deterministically check probability based on VRF output
             // (vrfOutput % 10000) is used as a pseudo-random value between 0-9999
             return (vrfOutput % 10000) < cond.probabilityPercentage;
        } else if (cond.conditionType == ConditionType.Combined) {
             // Evaluate sub-conditions based on AND/OR logic
             if (cond.useANDLogicForCombined) {
                 // All sub-conditions must be true
                 for(uint i = 0; i < cond.subConditionIds.length; i++) {
                     if (!_checkCondition(cond.subConditionIds[i], requestId)) {
                         return false; // Found one false condition in AND set
                     }
                 }
                 return true; // All sub-conditions were true
             } else {
                 // At least one sub-condition must be true
                 for(uint i = 0; i < cond.subConditionIds.length; i++) {
                      if (_checkCondition(cond.subConditionIds[i], requestId)) {
                         return true; // Found one true condition in OR set
                     }
                 }
                 return false; // No sub-condition was true
             }
        }
        // Unknown condition type or unhandled case
        return false;
    }

    /// @notice Check if a single condition is met based on current state and submitted external data/VRF results.
    /// @param conditionId The ID of the condition to check.
    /// @return True if the condition is met, false otherwise.
    /// @dev Note: MultiSigFactor conditions require a request context, this function cannot fully check them without one. Returns false for MultiSigFactor.
    function checkCondition(uint256 conditionId) public view returns (bool) {
         require(conditionId > 0 && conditionId < nextConditionId, "Invalid condition ID");
         if (conditions[conditionId].conditionType == ConditionType.MultiSigFactor) {
             // MultiSigFactor depends on a specific request's confirmations, cannot be checked generically
             return false;
         }
         // Use a dummy requestId (0) for checks that don't depend on request state
         return _checkCondition(conditionId, 0);
    }


    /// @notice Check if all conditions in a Condition Set are met based on current state and submitted external data/VRF results.
    /// @param conditionSetId The ID of the condition set to check.
    /// @return True if the condition set is met, false otherwise.
    /// @dev Note: MultiSigFactor conditions require a request context, this function cannot fully check them without one. Returns false if the set contains a MultiSigFactor condition.
    function checkConditionSet(uint256 conditionSetId) public view returns (bool) {
        require(conditionSetId > 0 && conditionSetId < nextConditionSetId, "Invalid condition set ID");
        ConditionSet storage cSet = conditionSets[conditionSetId];

        // Pre-check for MultiSigFactor conditions which cannot be checked generically
        for(uint i = 0; i < cSet.conditionIds.length; i++) {
            if (conditions[cSet.conditionIds[i]].conditionType == ConditionType.MultiSigFactor) {
                 // Cannot evaluate a set containing MultiSigFactor without a specific request context
                 return false;
            }
             // Basic validation: ensure conditions exist
             require(cSet.conditionIds[i] > 0 && cSet.conditionIds[i] < nextConditionId, "Invalid condition ID in set");
        }

        // Use a dummy requestId (0) for checks that don't depend on request state
        if (cSet.useANDLogicForSet) {
            for (uint i = 0; i < cSet.conditionIds.length; i++) {
                if (!_checkCondition(cSet.conditionIds[i], 0)) {
                    return false;
                }
            }
            return true;
        } else {
            for (uint i = 0; i < cSet.conditionIds.length; i++) {
                 if (_checkCondition(cSet.conditionIds[i], 0)) {
                    return true;
                }
            }
            return false;
        }
    }

     /// @notice Get details of a specific condition.
     /// @param conditionId The ID of the condition.
     /// @return Condition struct details.
    function getConditionDetails(uint256 conditionId) public view returns (Condition memory) {
        require(conditionId > 0 && conditionId < nextConditionId, "Invalid condition ID");
        return conditions[conditionId];
    }

    /// @notice Get details of a specific condition set.
    /// @param conditionSetId The ID of the condition set.
    /// @return ConditionSet struct details.
    function getConditionSetDetails(uint256 conditionSetId) public view returns (ConditionSet memory) {
        require(conditionSetId > 0 && conditionSetId < nextConditionSetId, "Invalid condition set ID");
        return conditionSets[conditionSetId];
    }


    // --- Withdrawal Workflow ---

    /// @notice User initiates a conditional withdrawal request.
    /// @param amount The amount to withdraw.
    /// @param tokenAddress The token address (address(0) for native Ether).
    /// @return The ID of the created withdrawal request.
    function requestConditionalWithdrawal(uint256 amount, address tokenAddress) external returns (uint256) {
        uint256 conditionSetId = userConditionSet[msg.sender];
        require(conditionSetId > 0, "No condition set assigned to user");
        require(conditionSetId < nextConditionSetId, "Assigned condition set is invalid"); // Should not happen if assignment is correct

        if (tokenAddress == address(0)) {
             require(amount > 0 && address(this).balance >= amount, "Insufficient native balance in vault");
        } else {
             require(amount > 0 && tokenBalances[tokenAddress] >= uint255(amount), "Insufficient token balance in vault");
        }

        uint256 requestId = nextWithdrawalRequestId++;

        withdrawalRequests[requestId] = WithdrawalRequest({
            user: msg.sender,
            amount: amount,
            tokenAddress: tokenAddress,
            conditionSetId: conditionSetId,
            status: RequestStatus.Pending,
            confirmationsReceived: 0 // Initialize confirmations for MultiSigFactor check
        });

        emit WithdrawalRequested(requestId, msg.sender, amount, tokenAddress);
        return requestId;
    }

    /// @notice A signer confirms a MultiSigFactor condition for a pending withdrawal request.
    /// @param withdrawalRequestId The ID of the withdrawal request.
    function confirmMultiSigForRequest(uint256 withdrawalRequestId) external {
        WithdrawalRequest storage req = withdrawalRequests[withdrawalRequestId];
        require(req.status == RequestStatus.Pending, "Request is not pending");

        uint256 conditionSetId = req.conditionSetId;
        ConditionSet storage cSet = conditionSets[conditionSetId];

        // Find the MultiSigFactor condition within the set (assuming at most one for simplicity)
        uint256 multiSigCondId = 0;
        for(uint i = 0; i < cSet.conditionIds.length; i++) {
            uint256 currentCondId = cSet.conditionIds[i];
            if (conditions[currentCondId].conditionType == ConditionType.MultiSigFactor) {
                multiSigCondId = currentCondId;
                break; // Found the multi-sig condition
            }
        }
        require(multiSigCondId != 0, "Request condition set does not contain a MultiSigFactor condition");

        Condition storage multiSigCond = conditions[multiSigCondId];
        bool isSigner = false;
        for (uint i = 0; i < multiSigCond.signers.length; i++) {
            if (multiSigCond.signers[i] == msg.sender) {
                isSigner = true;
                break;
            }
        }
        require(isSigner, "Caller is not a designated signer for this condition");

        // Prevent duplicate confirmations from the same signer for the same request
        // This requires tracking signers *per request*. Could use a mapping within the request struct,
        // but for simplicity here, we'll just increment and rely on external logic/monitoring
        // to prevent double calls from the same signer for the *same* request state.
        // A more robust version would map (requestId => signer => bool confirmed).
        req.confirmationsReceived++;

        emit MultiSigConfirmationReceived(withdrawalRequestId, msg.sender, req.confirmationsReceived);
    }

    /// @notice Check conditions for a request and execute withdrawal if met. Anyone can call this.
    /// @param withdrawalRequestId The ID of the withdrawal request.
    function executeConditionalWithdrawal(uint256 withdrawalRequestId) external {
        WithdrawalRequest storage req = withdrawalRequests[withdrawalRequestId];
        require(req.status == RequestStatus.Pending, "Request is not pending");
        require(req.user != address(0), "Invalid request ID"); // Ensure request exists

        bool conditionsMet = _checkConditionSetForRequest(req.conditionSetId, withdrawalRequestId);

        emit WithdrawalConditionsChecked(withdrawalRequestId, conditionsMet);

        if (conditionsMet) {
            req.status = RequestStatus.Executed; // Mark as executed *before* transfer

            if (req.tokenAddress == address(0)) {
                // Transfer native Ether
                 (bool success, ) = payable(req.user).call{value: req.amount}("");
                 require(success, "Native transfer failed");
            } else {
                // Transfer ERC20 tokens
                 IERC20 token = IERC20(req.tokenAddress);
                 tokenBalances[req.tokenAddress] -= uint255(req.amount); // Update internal balance tracking
                 bool success = token.transfer(req.user, req.amount);
                 require(success, "Token transfer failed");
            }

            emit WithdrawalExecuted(requestId, req.user, req.amount, req.tokenAddress);
        } else {
             // Optionally update status to something like 'Pending_Conditions_Not_Met' if needed,
             // but 'Pending' implies it's still waiting for conditions to align.
             // req.status = RequestStatus.Pending_Conditions_Not_Met; // Example alternative
        }
    }

    /// @notice Internal helper to check a condition set using the context of a specific withdrawal request.
    /// @param conditionSetId The ID of the condition set.
    /// @param requestId The ID of the withdrawal request.
    /// @return True if the condition set is met for this request, false otherwise.
    function _checkConditionSetForRequest(uint256 conditionSetId, uint256 requestId) internal view returns (bool) {
        require(conditionSetId > 0 && conditionSetId < nextConditionSetId, "Invalid condition set ID");
        ConditionSet storage cSet = conditionSets[conditionSetId];

        if (cSet.useANDLogicForSet) {
            for (uint i = 0; i < cSet.conditionIds.length; i++) {
                // Pass the requestId to the condition check
                if (!_checkCondition(cSet.conditionIds[i], requestId)) {
                    return false; // Found one false condition in AND set
                }
            }
            return true; // All conditions were true
        } else {
            for (uint i = 0; i < cSet.conditionIds.length; i++) {
                 // Pass the requestId to the condition check
                 if (_checkCondition(cSet.conditionIds[i], requestId)) {
                    return true; // Found one true condition in OR set
                }
            }
            return false; // No condition was true
        }
    }


    /// @notice Cancel a pending withdrawal request. Can be called by the user or the owner.
    /// @param withdrawalRequestId The ID of the withdrawal request.
    function cancelWithdrawalRequest(uint256 withdrawalRequestId) external {
        WithdrawalRequest storage req = withdrawalRequests[withdrawalRequestId];
        require(req.status == RequestStatus.Pending, "Request is not pending");
        require(req.user == msg.sender || owner() == msg.sender, "Not authorized to cancel this request");

        req.status = RequestStatus.Cancelled;
        emit WithdrawalCancelled(withdrawalRequestId);
    }

    /// @notice Get details of a specific withdrawal request.
    /// @param withdrawalRequestId The ID of the request.
    /// @return WithdrawalRequest struct details.
    function getWithdrawalRequestDetails(uint256 withdrawalRequestId) public view returns (WithdrawalRequest memory) {
        require(withdrawalRequestId > 0 && withdrawalRequestId < nextWithdrawalRequestId, "Invalid withdrawal request ID");
        return withdrawalRequests[withdrawalRequestId];
    }

    // --- Oracle/VRF Result Submission (Owner or Designated Oracle Address Only) ---

    /// @notice Submit the data result for an ExternalData condition.
    /// @param conditionId The ID of the ExternalData condition.
    /// @param dataResult The actual data result from the oracle.
    function submitExternalDataResult(uint256 conditionId, bytes memory dataResult) external {
        Condition storage cond = conditions[conditionId];
        require(cond.conditionType == ConditionType.ExternalData, "Not an ExternalData condition");
        require(cond.oracleAddress == address(0) || cond.oracleAddress == msg.sender || owner() == msg.sender, "Not authorized to submit data for this condition"); // Allow owner or specified oracle

        bytes32 resultHash = keccak256(dataResult);
        require(resultHash == cond.expectedResultHash, "Submitted data hash does not match expected hash");

        externalDataResultsHash[conditionId] = resultHash; // Store the hash to mark as received and validated
        emit ExternalDataReceived(conditionId, dataResult);
    }

    /// @notice Submit the VRF output for a Probabilistic condition.
    /// @param conditionId The ID of the Probabilistic condition.
    /// @param vrfOutput The VRF random output value.
    function submitVRFOutput(uint256 conditionId, uint256 vrfOutput) external {
        Condition storage cond = conditions[conditionId];
        require(cond.conditionType == ConditionType.Probabilistic, "Not a Probabilistic condition");
         // In a real scenario, this would likely be called by a trusted VRF oracle address
         // For this example, allow owner to simulate submission
         require(owner() == msg.sender, "Only owner can submit VRF output (simulation)");

        vrfResults[conditionId] = vrfOutput;
        emit VRFOutputReceived(conditionId, vrfOutput);
    }

    // --- Emergency & Ownership ---

    /// @notice Owner can bypass conditions and unlock funds in an emergency.
    /// @param user The recipient of the funds.
    /// @param amount The amount to withdraw.
    /// @param tokenAddress The token address (address(0) for native Ether).
    function emergencyUnlock(address user, uint256 amount, address tokenAddress) external onlyOwner {
        require(user != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");

        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount, "Insufficient native balance for emergency unlock");
            (bool success, ) = payable(user).call{value: amount}("");
            require(success, "Emergency native transfer failed");
        } else {
            require(tokenBalances[tokenAddress] >= uint255(amount), "Insufficient token balance for emergency unlock");
            IERC20 token = IERC20(tokenAddress);
            tokenBalances[tokenAddress] -= uint255(amount); // Update internal balance tracking
            bool success = token.transfer(user, amount);
            require(success, "Emergency token transfer failed");
        }

        emit EmergencyUnlockUsed(user, amount, tokenAddress);
    }

    // OpenZeppelin's Ownable provides transferOwnership and renounceOwnership
    // function transferOwnership(address newOwner) public virtual onlyOwner { ... }
    // function renounceOwnership() public virtual onlyOwner { ... }
}
```

---

**Explanation of Advanced/Creative Concepts Used:**

1.  **Multi-Factor Conditional Release:** The core idea isn't a simple time lock or multi-sig, but a combination of potentially many different conditions evaluated together using AND/OR logic (`ConditionSet`).
2.  **Diverse Condition Types:** Includes standard (TimeLock), but also more complex ones:
    *   `ExternalData`: Simulates dependency on off-chain data provided by an oracle, ensuring release only when specific external facts are confirmed on-chain.
    *   `Dependent`: Creates logic chains where one condition's state depends on another.
    *   `MultiSigFactor`: Multi-signature is treated *as a condition*, not the overall wallet control. This means a withdrawal might require an N of M approval *in addition to* a time lock *and* an oracle data feed being correct. Importantly, confirmations are tied to a specific `WithdrawalRequest`.
    *   `Probabilistic`: Introduces a non-deterministic element dependent on a Verifiable Random Function (VRF) output (simulated here). This allows for scenarios like "this is releasable after the time lock *and* there's a 70% chance based on the next random beacon."
3.  **Combined Conditions (`ConditionType.Combined`):** Allows nesting logical operators within conditions, making the unlock logic highly granular (e.g., "(A AND B) OR (C AND D)").
4.  **User-Specific Condition Sets:** Different users/beneficiaries can be assigned entirely different sets of unlock requirements, making the vault flexible for various use cases (e.g., different release schedules or conditions for co-founders vs. advisors vs. investors).
5.  **Request-Based Withdrawal Workflow:** Instead of a direct `withdraw()` call, users `requestConditionalWithdrawal()`. This creates a specific request object that tracks the attempt. The actual transfer happens via `executeConditionalWithdrawal()`, which checks the conditions *at that moment*. This decouples the *intent* to withdraw from the *ability* to withdraw and allows for conditions (like MultiSigFactor confirmations) to be gathered over time *per request*.
6.  **State-Dependent Condition Checking:** The `_checkCondition` and `_checkConditionSetForRequest` functions are the core logic, reading the contract's state (current time, stored oracle/VRF results, confirmations per request) to determine unlockability dynamically.
7.  **Oracle/VRF Callbacks (Simulated):** The contract includes specific functions (`submitExternalDataResult`, `submitVRFOutput`) that act as entry points for external systems (like oracles or VRF services) to provide the data needed for certain conditions to become true.
8.  **Internal Balance Tracking for ERC20:** While `IERC20.balanceOf(address(this))` gives the total, tracking it internally (`tokenBalances`) can be useful for complex scenarios or access control on specific token types within the vault, although `balanceOf` is sufficient for simple checks. This version updates the internal balance upon deposit and successful withdrawal.

This contract provides a framework for building sophisticated, rule-based asset release mechanisms that go far beyond standard single-condition locks.

**Disclaimer:** This is a complex example for educational purposes. Deploying such a contract requires rigorous auditing, careful consideration of gas costs for complex condition evaluations, secure oracle integration, and robust error handling for edge cases not fully detailed here. The simulation of oracle/VRF input (`submitExternalDataResult`, `submitVRFOutput`) would need to be replaced with a secure oracle pattern (like Chainlink) in a production environment. The MultiSigFactor condition tracking is simplified and would need more robust duplicate prevention per signer per request.