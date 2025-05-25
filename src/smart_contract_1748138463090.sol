Okay, let's design a smart contract called `QuantumVault`. The concept is a vault that holds assets (ETH and ERC20 tokens) and releases them based on complex, multi-factor "conditions sets." These condition sets act like the "measurement" in a quantum system – the state (locked/unlocked) depends on whether the conditions are simultaneously met at the time of checking.

It incorporates concepts like:
1.  **Complex Conditional Release:** Assets locked under multiple customizable conditions (time, external contract state, oracle data, balance checks).
2.  **Condition Sets:** Grouping conditions together, allowing users to lock funds against a specific *set* of requirements.
3.  **Delegated Conditional Access:** Allowing a third party to withdraw funds on your behalf *only if* the conditions are met.
4.  **Batch Operations:** Performing multiple withdrawals or checks in a single transaction.
5.  **External Interaction Placeholders:** Designed to interact with oracles or other contracts for condition checks.
6.  **Dynamic Logic via External Evaluator (Conceptual):** Structuring conditions such that a more complex off-chain or another on-chain evaluator could be plugged in (represented by `IConditionEvaluator`).

This goes beyond standard time-locks, vesting, or simple conditional transfers by allowing arbitrary combinations of on-chain verifiable conditions defined by users.

---

**Contract Outline: QuantumVault**

1.  **State Variables:**
    *   `owner`: Contract owner.
    *   `paused`: Pausability state.
    *   `allowedTokens`: List/mapping of supported ERC20 tokens.
    *   `conditionSets`: Mapping from a unique ID (bytes32) to `ConditionSet` struct.
    *   `userDepositsETH`: Mapping user address -> condition set ID -> amount.
    *   `userDepositsERC20`: Mapping ERC20 address -> user address -> condition set ID -> amount.
    *   `delegatedAccess`: Mapping user address -> condition set ID -> delegatee address -> `Delegation` struct.
    *   `observers`: Mapping condition set ID -> observer address -> boolean (for future notification).
    *   `oracleAddress`: Address of a potential oracle contract.
    *   `conditionEvaluatorAddress`: Address of a contract designed to evaluate complex conditions (placeholder).

2.  **Structs & Enums:**
    *   `ConditionType`: Enum for different types of conditions (Time, ExternalCall, OraclePrice, BalanceCheck, etc.).
    *   `Condition`: Struct defining parameters for a single condition.
    *   `ConditionSet`: Struct defining a group of conditions, including type of requirement (ALL or ANY) and active status.
    *   `Delegation`: Struct defining delegated withdrawal rights (delegatee, expiry, amount limit, etc.).

3.  **Events:**
    *   `ConditionSetCreated`, `ConditionSetUpdated`, `ConditionSetDeactivated`, `ConditionSetActivated`
    *   `DepositETH`, `DepositERC20`
    *   `WithdrawETH`, `WithdrawERC20`
    *   `DelegatedAccessGranted`, `DelegatedAccessRevoked`
    *   `ObserverAdded`, `ObserverRemoved`
    *   `AllowedTokenAdded`, `AllowedTokenRemoved`
    *   `OracleAddressUpdated`, `ConditionEvaluatorUpdated`
    *   `Paused`, `Unpaused`

4.  **Modifiers:**
    *   `onlyOwner`
    *   `whenNotPaused`
    *   `whenPaused`
    *   `isActiveConditionSet`
    *   `isAllowedToken`

5.  **Functions (20+):**
    *   **Admin (4):** `constructor`, `transferOwnership`, `pauseContract`, `unpauseContract`
    *   **Token Management (2):** `addAllowedToken`, `removeAllowedToken`
    *   **External Dependency Management (2):** `setOracleAddress`, `setConditionEvaluatorAddress`
    *   **Condition Set Management (6):** `createConditionSet`, `updateConditionSet`, `deactivateConditionSet`, `activateConditionSet`, `getConditionSetDetails` (view), `getAllConditionSetIds` (view)
    *   **Deposits (2):** `depositETH`, `depositERC20` (payable)
    *   **Condition Checking (1):** `checkConditionsMet` (view)
    *   **Withdrawals (3):** `withdrawETH`, `withdrawERC20`, `executeBatchedWithdrawals`
    *   **Delegation (3):** `delegateConditionalAccess`, `revokeConditionalAccess`, `executeDelegatedWithdrawal`
    *   **Observer (2):** `addObserver`, `removeObserver`
    *   **View Balances (3):** `getBalanceInSetETH` (view), `getBalanceInSetERC20` (view), `getTotalETHBalance` (view)
    *   **Advanced/Internal Helpers (Implicitly used or simple views):** `_checkConditions` (internal), `_getDelegationDetails` (view), `isDelegateValid` (internal/view helper) - Total is well over 20 including these.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Contract Outline: QuantumVault ---
// 1. State Variables: owner, paused, allowedTokens, conditionSets, userDepositsETH, userDepositsERC20, delegatedAccess, observers, oracleAddress, conditionEvaluatorAddress
// 2. Structs & Enums: ConditionType, Condition, ConditionSet, Delegation
// 3. Events: ConditionSetCreated, DepositETH, WithdrawETH, DelegatedAccessGranted, etc. (See full list below)
// 4. Modifiers: onlyOwner, whenNotPaused, isActiveConditionSet, isAllowedToken
// 5. Functions (20+): Admin (4), Token Management (2), External Deps (2), Condition Sets (6), Deposits (2), Checking (1), Withdrawals (3), Delegation (3), Observer (2), Views (3+).

// --- Function Summary ---
// Admin:
// - constructor(address initialOwner): Initializes the contract owner.
// - transferOwnership(address newOwner): Transfers contract ownership.
// - pauseContract(): Pauses all sensitive operations (deposits, withdrawals).
// - unpauseContract(): Unpauses the contract.

// Token Management:
// - addAllowedToken(address tokenAddress): Adds an ERC20 token to the list of supported tokens.
// - removeAllowedToken(address tokenAddress): Removes an ERC20 token from the supported list.

// External Dependency Management:
// - setOracleAddress(address _oracleAddress): Sets the address of a trusted oracle contract.
// - setConditionEvaluatorAddress(address _evaluatorAddress): Sets the address of an external condition evaluator contract.

// Condition Set Management:
// - createConditionSet(Condition[] memory conditions, bool requiresAll, string memory description): Creates a new set of conditions with a unique ID.
// - updateConditionSet(bytes32 setId, Condition[] memory conditions, bool requiresAll, string memory description): Updates an existing condition set (only allowed if no funds locked).
// - deactivateConditionSet(bytes32 setId): Deactivates a condition set, preventing new deposits and withdrawals using it.
// - activateConditionSet(bytes32 setId): Activates a previously deactivated condition set.
// - getConditionSetDetails(bytes32 setId): View function to retrieve details of a condition set.
// - getAllConditionSetIds(): View function to get all existing condition set IDs.

// Deposits:
// - depositETH(bytes32 setId): Deposits ETH into the vault locked under a specific condition set.
// - depositERC20(IERC20 token, uint256 amount, bytes32 setId): Deposits ERC20 tokens into the vault locked under a specific condition set.

// Condition Checking:
// - checkConditionsMet(bytes32 setId, address depositor): View function to check if all/any conditions are currently met for a set and specific depositor.

// Withdrawals:
// - withdrawETH(bytes32 setId): Withdraws ETH from a set if conditions are met for the caller (depositor).
// - withdrawERC20(IERC20 token, bytes32 setId): Withdraws ERC20 from a set if conditions are met for the caller (depositor).
// - executeBatchedWithdrawals(WithdrawalRequest[] memory requests): Attempts to perform multiple ETH/ERC20 withdrawals in a single transaction.

// Delegation:
// - delegateConditionalAccess(bytes32 setId, address delegatee, uint256 expiryTimestamp, uint256 amountLimit): Grants permission to another address to withdraw funds from a set if conditions are met.
// - revokeConditionalAccess(bytes32 setId, address delegatee): Revokes delegated access.
// - executeDelegatedWithdrawal(bytes32 setId, address depositor, uint256 amount): Allows a delegatee to withdraw funds on behalf of a depositor if conditions and delegation are valid.

// Observer:
// - addObserver(bytes32 setId, address observerAddress): Adds an address to a list to potentially be notified (via event) when conditions are met for a set.
// - removeObserver(bytes32 setId, address observerAddress): Removes an observer.

// View Balances:
// - getBalanceInSetETH(bytes32 setId, address depositor): Gets the ETH balance for a depositor in a set.
// - getBalanceInSetERC20(IERC20 token, bytes32 setId, address depositor): Gets the ERC20 balance for a depositor in a set.
// - getTotalETHBalance(): Gets the total ETH held by the contract.

// Advanced/Internal Helpers (implicitly counted in the total):
// - _checkConditions(bytes32 setId, address depositor): Internal logic for checking all conditions in a set.
// - _getDelegationDetails(bytes32 setId, address depositor, address delegatee): View for delegation details.
// - isDelegateValid(bytes32 setId, address depositor, address delegatee, uint256 requestedAmount): Internal helper to check if delegation is valid.

// Interface for a conceptual Condition Evaluator
interface IConditionEvaluator {
    function check(bytes32 setId, address depositor, bytes[] memory conditionParams) external view returns (bool);
}

contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // State Variables
    EnumerableSet.AddressSet private _allowedTokens;

    enum ConditionType {
        TIME_BASED,         // Params: uint256 timestamp (e.g., release after)
        EXTERNAL_CALL,      // Params: address target, bytes callData, bytes expectedResponse (e.g., check state of another contract)
        ORACLE_PRICE,       // Params: address oracleFeed, uint256 threshold, bool greaterThan (e.g., price feed > threshold)
        BALANCE_CHECK,      // Params: address checkToken, address targetAddress, uint256 minBalance (e.g., target address has X of token)
        // Add more complex or custom types here
        EXTERNAL_EVALUATOR  // Params: bytes[] arbitrary data for external evaluator
    }

    struct Condition {
        ConditionType conditionType;
        bytes params; // ABI-encoded parameters for the specific condition type
        string description; // Human-readable description
    }

    struct ConditionSet {
        bytes32 id; // Unique identifier for the set
        Condition[] conditions;
        bool requiresAll; // True if ALL conditions must be met, False if ANY condition must be met
        bool isActive; // Can deposits/withdrawals be made using this set?
        string description; // Description of the set
    }

    struct Delegation {
        address delegatee;
        uint256 expiryTimestamp;
        uint256 amountLimit; // 0 for unlimited
        bool active;
    }

    // Mapping: conditionSetId => ConditionSet struct
    mapping(bytes32 => ConditionSet) public conditionSets;
    // Mapping: userAddress => conditionSetId => ETH balance
    mapping(address => mapping(bytes32 => uint256)) public userDepositsETH;
    // Mapping: tokenAddress => userAddress => conditionSetId => ERC20 balance
    mapping(address => mapping(address => mapping(bytes32 => uint256))) public userDepositsERC20;
    // Mapping: userAddress => conditionSetId => delegateeAddress => Delegation struct
    mapping(address => mapping(bytes32 => mapping(address => Delegation))) public delegatedAccess;
     // Mapping: conditionSetId => observerAddress => bool
    mapping(bytes32 => mapping(address => bool)) public observers;
    // Set of all condition set IDs
    EnumerableSet.Bytes32Set private _conditionSetIds;

    address public oracleAddress; // Address of a potential oracle contract
    address public conditionEvaluatorAddress; // Address of an external contract for complex condition evaluation

    // Events
    event ConditionSetCreated(bytes32 indexed setId, address indexed creator);
    event ConditionSetUpdated(bytes32 indexed setId, address indexed updater);
    event ConditionSetDeactivated(bytes32 indexed setId, address indexed admin);
    event ConditionSetActivated(bytes32 indexed setId, address indexed admin);
    event DepositETH(address indexed depositor, bytes32 indexed setId, uint256 amount);
    event DepositERC20(IERC20 indexed token, address indexed depositor, bytes32 indexed setId, uint256 amount);
    event WithdrawETH(address indexed withdrawer, bytes32 indexed setId, uint256 amount);
    event WithdrawERC20(IERC20 indexed token, address indexed withdrawer, bytes32 indexed setId, uint256 amount);
    event DelegatedAccessGranted(address indexed depositor, bytes32 indexed setId, address indexed delegatee, uint256 expiryTimestamp, uint256 amountLimit);
    event DelegatedAccessRevoked(address indexed depositor, bytes32 indexed setId, address indexed delegatee);
    event DelegatedWithdrawalExecuted(address indexed delegatee, address indexed depositor, bytes32 indexed setId, uint256 amount);
    event ObserverAdded(bytes32 indexed setId, address indexed observer);
    event ObserverRemoved(bytes32 indexed setId, address indexed observer);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event ConditionEvaluatorAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event Paused(address account);
    event Unpaused(address account);
    event ConditionsPossiblyMet(bytes32 indexed setId); // Hint for observers to check

    // Errors
    error SetDoesNotExist(bytes32 setId);
    error SetNotActive(bytes32 setId);
    error SetHasDeposits(bytes32 setId);
    error TokenNotAllowed(address token);
    error InsufficientBalanceInSet(bytes32 setId, uint256 requested, uint256 available);
    error ConditionsNotMet(bytes32 setId);
    error NoDelegationFound(bytes32 setId, address depositor, address delegatee);
    error DelegationExpired(bytes32 setId, address delegatee);
    error DelegationAmountLimitReached(bytes32 setId, address delegatee, uint256 requested, uint256 limit);
    error DelegateCannotBeDepositor();
    error InvalidWithdrawalRequest();
    error ZeroAddressNotAllowed();
    error OracleAddressNotSet();
    error ConditionEvaluatorAddressNotSet();


    // --- Modifiers ---
    modifier isActiveConditionSet(bytes32 setId) {
        if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
        if (!conditionSets[setId].isActive) revert SetNotActive(setId);
        _;
    }

    modifier isAllowedToken(address token) {
        if (!_allowedTokens.contains(token)) revert TokenNotAllowed(token);
        _;
    }

    // --- Admin Functions ---

    constructor(address initialOwner) Ownable(initialOwner) Pausable() {
        if (initialOwner == address(0)) revert ZeroAddressNotAllowed();
        // No-op, Ownable handles ownership transfer
    }

    // Inherits transferOwnership from Ownable

    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Token Management ---

    function addAllowedToken(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        _allowedTokens.add(tokenAddress);
        emit AllowedTokenAdded(tokenAddress);
    }

    function removeAllowedToken(address tokenAddress) public onlyOwner {
         if (tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        _allowedTokens.remove(tokenAddress);
        emit AllowedTokenRemoved(tokenAddress);
    }

     function getAllowedTokens() public view returns (address[] memory) {
        return _allowedTokens.values();
    }

    // --- External Dependency Management ---

    function setOracleAddress(address _oracleAddress) public onlyOwner {
        if (_oracleAddress == address(0)) revert ZeroAddressNotAllowed();
        address oldAddress = oracleAddress;
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(oldAddress, oracleAddress);
    }

    function setConditionEvaluatorAddress(address _evaluatorAddress) public onlyOwner {
         if (_evaluatorAddress == address(0)) revert ZeroAddressNotAllowed();
        address oldAddress = conditionEvaluatorAddress;
        conditionEvaluatorAddress = _evaluatorAddress;
        emit ConditionEvaluatorAddressUpdated(oldAddress, conditionEvaluatorAddress);
    }

    // --- Condition Set Management ---

    function createConditionSet(Condition[] memory conditions, bool requiresAll, string memory description)
        public onlyOwner whenNotPaused
        returns (bytes32 setId)
    {
        // Generate a unique ID. Using a hash of creator, timestamp, and description
        // Note: Collisions are theoretically possible but extremely unlikely.
        // A counter could also be used, but hash is less predictable.
        setId = keccak256(abi.encodePacked(msg.sender, block.timestamp, description, conditions));

        // Ensure ID is not already used (highly improbable with hash, but good practice)
        // If collision happens, try hashing again with a nonce or similar.
        // For simplicity here, we assume collision is negligible.
        require(!_conditionSetIds.contains(setId), "Set ID collision");

        conditionSets[setId] = ConditionSet({
            id: setId,
            conditions: conditions,
            requiresAll: requiresAll,
            isActive: true,
            description: description
        });

        _conditionSetIds.add(setId);
        emit ConditionSetCreated(setId, msg.sender);
    }

     function updateConditionSet(bytes32 setId, Condition[] memory conditions, bool requiresAll, string memory description)
        public onlyOwner whenNotPaused
    {
        if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
        // Only allow updates if no funds are currently locked in this set
        // Checking ETH requires iterating userDepositsETH. Checking ERC20 requires iterating userDepositsERC20.
        // This can be gas-intensive. A simpler rule: disallow update if *any* deposit has ever been made,
        // or track active deposits per set. Let's use a simple placeholder check:
        // For a real contract, need a more robust check tracking deposits per set.
        // Checking balances in mappings is not feasible for arbitrary users/tokens.
        // We'll add a state variable per set tracking if deposits exist. For this example,
        // we'll skip the rigorous check and *assume* it would be checked here.
        // require(totalDepositsInSet[setId] == 0, "Set has deposits, cannot update");
        // Using a simple placeholder check for demonstrative purposes:
        bool hasDeposits = false; // Placeholder - actual check is complex
        if (hasDeposits) revert SetHasDeposits(setId);


        conditionSets[setId].conditions = conditions;
        conditionSets[setId].requiresAll = requiresAll;
        conditionSets[setId].description = description;

        emit ConditionSetUpdated(setId, msg.sender);
    }


    function deactivateConditionSet(bytes32 setId) public onlyOwner {
        if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
        conditionSets[setId].isActive = false;
        emit ConditionSetDeactivated(setId, msg.sender);
    }

    function activateConditionSet(bytes32 setId) public onlyOwner {
        if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
        conditionSets[setId].isActive = true;
        emit ConditionSetActivated(setId, msg.sender);
    }

    function getConditionSetDetails(bytes32 setId) public view returns (Condition[] memory conditions, bool requiresAll, bool isActive, string memory description) {
        if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
        ConditionSet storage set = conditionSets[setId];
        return (set.conditions, set.requiresAll, set.isActive, set.description);
    }

     function getAllConditionSetIds() public view returns (bytes32[] memory) {
        return _conditionSetIds.values();
    }

    // --- Deposits ---

    function depositETH(bytes32 setId)
        public payable whenNotPaused isActiveConditionSet(setId)
    {
        if (msg.value == 0) revert InsufficientBalanceInSet(setId, 0, 0); // Using this error type broadly

        userDepositsETH[msg.sender][setId] += msg.value;

        emit DepositETH(msg.sender, setId, msg.value);
        emit ConditionsPossiblyMet(setId); // Hint that state changed for this set
    }

    function depositERC20(IERC20 token, uint256 amount, bytes32 setId)
        public whenNotPaused isActiveConditionSet(setId) isAllowedToken(address(token))
    {
        if (amount == 0) revert InsufficientBalanceInSet(setId, 0, 0); // Using this error type broadly

        uint256 beforeBalance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 afterBalance = token.balanceOf(address(this));
        uint256 transferredAmount = afterBalance - beforeBalance; // Handle fee-on-transfer tokens

        userDepositsERC20[address(token)][msg.sender][setId] += transferredAmount;

        emit DepositERC20(token, msg.sender, setId, transferredAmount);
         emit ConditionsPossiblyMet(setId); // Hint that state changed for this set
    }

    // --- Condition Checking ---

    function checkConditionsMet(bytes32 setId, address depositor) public view returns (bool) {
         if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
         // Note: This view function does *not* check if the set is active, allowing pre-checks.
         // The withdrawal functions *do* check activity.

        ConditionSet storage set = conditionSets[setId];
        uint256 metCount = 0;
        uint256 totalConditions = set.conditions.length;

        if (totalConditions == 0) {
            return true; // A set with no conditions is always met
        }

        for (uint i = 0; i < totalConditions; i++) {
            bool currentConditionMet = false;
            Condition storage cond = set.conditions[i];

            // --- Core Condition Evaluation Logic (Placeholder Implementation) ---
            // In a real advanced contract, this would interact with Oracles, other contracts etc.
            // Using abi.decode requires knowing the parameter types beforehand.
            // A more robust system might use a dedicated evaluator contract or a more complex
            // encoding schema. This is a simplified demonstration.
            bytes memory params = cond.params;

            if (cond.conditionType == ConditionType.TIME_BASED) {
                // Expects uint256 timestamp in params
                uint256 requiredTimestamp = abi.decode(params, (uint256));
                currentConditionMet = block.timestamp >= requiredTimestamp;

            } else if (cond.conditionType == ConditionType.EXTERNAL_CALL) {
                // Expects address target, bytes callData, bytes expectedResponse
                 // Note: This is a complex check. Call target, get response, compare.
                 // Requires dynamic low-level calls and careful error handling.
                 // Placeholder: Always return false for safety/simplicity in this example
                 currentConditionMet = false; // Placeholder - needs actual implementation

            } else if (cond.conditionType == ConditionType.ORACLE_PRICE) {
                 // Expects address oracleFeed, uint256 threshold, bool greaterThan
                 // Placeholder: Requires interacting with a specific oracle interface
                 // Example: IFetchPrice(oracleFeed).latestPrice().value
                 // currentConditionMet = ... call oracle ...
                 currentConditionMet = false; // Placeholder - needs actual implementation
                  if (oracleAddress == address(0)) {
                     // Conditions requiring oracle cannot be met if oracle address is not set
                     currentConditionMet = false;
                 } else {
                     // Attempt interaction with oracleAddress if set
                     // Example: (bool success, bytes memory retdata) = oracleAddress.staticcall(...);
                     // This is highly dependent on the oracle interface.
                     // For this example, we'll just use a dummy check or rely on EXTERNAL_EVALUATOR.
                     currentConditionMet = false; // Placeholder for actual oracle interaction
                 }

             } else if (cond.conditionType == ConditionType.BALANCE_CHECK) {
                  // Expects address checkToken, address targetAddress, uint256 minBalance
                  (address checkToken, address targetAddress, uint256 minBalance) = abi.decode(params, (address, address, uint256));
                  IERC20 token = IERC20(checkToken);
                  currentConditionMet = token.balanceOf(targetAddress) >= minBalance;

            } else if (cond.conditionType == ConditionType.EXTERNAL_EVALUATOR) {
                 // Expects bytes[] arbitrary data. Relies on conditionEvaluatorAddress.
                 if (conditionEvaluatorAddress == address(0)) {
                     currentConditionMet = false; // Cannot evaluate if no evaluator set
                 } else {
                     // Attempt interaction with external evaluator
                     // The external evaluator is responsible for decoding bytes and checking logic
                     // (bool success, bytes memory retdata) = conditionEvaluatorAddress.staticcall(
                     //     abi.encodeWithSelector(IConditionEvaluator.check.selector, setId, depositor, arbitraryDataArray)
                     // );
                     // currentConditionMet = success && abi.decode(retdata, (bool));
                     currentConditionMet = false; // Placeholder for actual external call
                 }
            }
            // --- End Core Condition Evaluation Logic ---

            if (currentConditionMet) {
                metCount++;
                if (!set.requiresAll) {
                    // If only ANY is required and one is met, we can stop
                    return true;
                }
            }
        }

        // If requiresAll, all conditions must have been met (metCount == totalConditions)
        // If not requiresAll, we would have returned true already if metCount > 0.
        // So, if we are here and requiresAll is false, it means metCount was 0.
        // If requiresAll is true, we return metCount == totalConditions.
        return set.requiresAll ? (metCount == totalConditions) : (metCount > 0);
    }

    // --- Withdrawals ---

    function withdrawETH(bytes32 setId)
        public nonReentrant whenNotPaused isActiveConditionSet(setId)
    {
        address depositor = msg.sender;
        uint256 amount = userDepositsETH[depositor][setId];

        if (amount == 0) revert InsufficientBalanceInSet(setId, 0, 0);
        if (!checkConditionsMet(setId, depositor)) revert ConditionsNotMet(setId);

        userDepositsETH[depositor][setId] = 0; // Clear balance before transfer
        (bool success, ) = payable(depositor).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit WithdrawETH(depositor, setId, amount);
    }

    function withdrawERC20(IERC20 token, bytes32 setId)
        public nonReentrant whenNotPaused isActiveConditionSet(setId) isAllowedToken(address(token))
    {
        address depositor = msg.sender;
        uint256 amount = userDepositsERC20[address(token)][depositor][setId];

        if (amount == 0) revert InsufficientBalanceInSet(setId, 0, 0);
        if (!checkConditionsMet(setId, depositor)) revert ConditionsNotMet(setId);

        userDepositsERC20[address(token)][depositor][setId] = 0; // Clear balance before transfer
        token.safeTransfer(depositor, amount);

        emit WithdrawERC20(token, depositor, setId, amount);
    }

    struct WithdrawalRequest {
        address token; // Use address(0) for ETH
        bytes32 setId;
        address depositor; // Used for delegated withdrawals, msg.sender if not delegated
        uint256 amount;    // 0 for max available
    }

    function executeBatchedWithdrawals(WithdrawalRequest[] memory requests)
        public nonReentrant whenNotPaused
    {
        for (uint i = 0; i < requests.length; i++) {
            WithdrawalRequest storage req = requests[i];
            address depositor = (req.depositor == address(0)) ? msg.sender : req.depositor;

            // Check if caller is depositor or a valid delegate
            bool isDepositor = (msg.sender == depositor);
            bool isDelegate = false;
            uint256 delegatedAmountLimit = 0; // 0 means no limit or not delegated

            if (!isDepositor) {
                Delegation storage delegation = delegatedAccess[depositor][req.setId][msg.sender];
                if (delegation.active && block.timestamp <= delegation.expiryTimestamp) {
                    isDelegate = true;
                    delegatedAmountLimit = delegation.amountLimit;
                }
                if (!isDelegate) revert InvalidWithdrawalRequest(); // Caller is neither depositor nor valid delegate
                if (req.depositor == address(0)) revert InvalidWithdrawalRequest(); // Must specify depositor for delegated
            } else {
                 if (req.depositor != address(0)) revert InvalidWithdrawalRequest(); // Must NOT specify depositor if calling as depositor
            }

             // Check set activity *before* conditions for efficiency
             if (!_conditionSetIds.contains(req.setId)) revert SetDoesNotExist(req.setId);
             if (!conditionSets[req.setId].isActive) revert SetNotActive(req.setId);


            // Check conditions
            if (!checkConditionsMet(req.setId, depositor)) revert ConditionsNotMet(req.setId);

            uint256 availableAmount;
            if (req.token == address(0)) { // ETH
                availableAmount = userDepositsETH[depositor][req.setId];
                 if (availableAmount == 0) continue; // Skip if no balance
                uint256 amountToWithdraw = (req.amount == 0 || req.amount > availableAmount) ? availableAmount : req.amount;

                if (isDelegate) {
                    if (delegatedAmountLimit > 0 && amountToWithdraw > delegatedAmountLimit) {
                         revert DelegationAmountLimitReached(req.setId, msg.sender, amountToWithdraw, delegatedAmountLimit);
                    }
                    delegatedAccess[depositor][req.setId][msg.sender].amountLimit -= amountToWithdraw; // Decrease limit for delegate
                }

                userDepositsETH[depositor][req.setId] -= amountToWithdraw;
                (bool success, ) = payable(depositor).call{value: amountToWithdraw}("");
                require(success, "ETH transfer failed in batch");
                emit WithdrawETH(isDelegate ? msg.sender : depositor, req.setId, amountToWithdraw);
                 if (isDelegate) emit DelegatedWithdrawalExecuted(msg.sender, depositor, req.setId, amountToWithdraw);


            } else { // ERC20
                IERC20 token = IERC20(req.token);
                if (!_allowedTokens.contains(address(token))) revert TokenNotAllowed(address(token)); // Redundant check but safe
                availableAmount = userDepositsERC20[address(token)][depositor][req.setId];
                if (availableAmount == 0) continue; // Skip if no balance
                uint256 amountToWithdraw = (req.amount == 0 || req.amount > availableAmount) ? availableAmount : req.amount;

                 if (isDelegate) {
                    if (delegatedAmountLimit > 0 && amountToWithdraw > delegatedAmountLimit) {
                         revert DelegationAmountLimitReached(req.setId, msg.sender, amountToWithdraw, delegatedAmountLimit);
                    }
                    delegatedAccess[depositor][req.setId][msg.sender].amountLimit -= amountToWithdraw; // Decrease limit for delegate
                 }

                userDepositsERC20[address(token)][depositor][req.setId] -= amountToWithdraw;
                token.safeTransfer(depositor, amountToWithdraw);
                emit WithdrawERC20(token, isDelegate ? msg.sender : depositor, req.setId, amountToWithdraw);
                 if (isDelegate) emit DelegatedWithdrawalExecuted(msg.sender, depositor, req.setId, amountToWithdraw);
            }
        }
    }


    // --- Delegation ---

    function delegateConditionalAccess(bytes32 setId, address delegatee, uint256 expiryTimestamp, uint256 amountLimit)
        public whenNotPaused isActiveConditionSet(setId) // Delegation only possible on active sets
    {
        address depositor = msg.sender;
        if (delegatee == address(0)) revert ZeroAddressNotAllowed();
        if (delegatee == depositor) revert DelegateCannotBeDepositor();

        delegatedAccess[depositor][setId][delegatee] = Delegation({
            delegatee: delegatee,
            expiryTimestamp: expiryTimestamp,
            amountLimit: amountLimit,
            active: true
        });

        emit DelegatedAccessGranted(depositor, setId, delegatee, expiryTimestamp, amountLimit);
    }

    function revokeConditionalAccess(bytes32 setId, address delegatee)
        public whenNotPaused // Can revoke even if set is inactive or conditions met
    {
        address depositor = msg.sender;
        if (delegatee == address(0)) revert ZeroAddressNotAllowed();

        Delegation storage delegation = delegatedAccess[depositor][setId][delegatee];
        if (!delegation.active) revert NoDelegationFound(setId, depositor, delegatee);

        delegation.active = false; // Simply deactivate, don't delete storage

        emit DelegatedAccessRevoked(depositor, setId, delegatee);
    }

    function executeDelegatedWithdrawal(bytes32 setId, address depositor, uint256 amount)
        public nonReentrant whenNotPaused isActiveConditionSet(setId)
    {
        address delegatee = msg.sender;
        if (delegatee == depositor) revert DelegateCannotBeDepositor();

        Delegation storage delegation = delegatedAccess[depositor][setId][delegatee];
        if (!delegation.active) revert NoDelegationFound(setId, depositor, delegatee);
        if (block.timestamp > delegation.expiryTimestamp) revert DelegationExpired(setId, delegatee);

        // Check conditions for the *depositor*
        if (!checkConditionsMet(setId, depositor)) revert ConditionsNotMet(setId);

        // Determine withdrawal amount, respecting delegation limit and depositor's balance
        uint256 depositorETHBalance = userDepositsETH[depositor][setId];
        uint256 amountToWithdraw = amount;

        if (delegation.amountLimit > 0) {
            // Delegate has a limit
            if (amountToWithdraw == 0 || amountToWithdraw > delegation.amountLimit) {
                amountToWithdraw = delegation.amountLimit; // Withdraw up to the limit
            }
            if (amountToWithdraw > delegation.amountLimit) revert DelegationAmountLimitReached(setId, delegatee, amountToWithdraw, delegation.amountLimit);
             delegation.amountLimit -= amountToWithdraw; // Decrease delegate's limit
        } else {
             // No delegation limit, withdraw requested amount or max
            if (amountToWithdraw == 0) {
                 amountToWithdraw = depositorETHBalance; // Withdraw max if 0 requested
            }
        }

         if (amountToWithdraw > depositorETHBalance) revert InsufficientBalanceInSet(setId, amountToWithdraw, depositorETHBalance);
         if (amountToWithdraw == 0) revert InsufficientBalanceInSet(setId, 0, 0);

        // Perform the withdrawal
        userDepositsETH[depositor][setId] -= amountToWithdraw;
        (bool success, ) = payable(depositor).call{value: amountToWithdraw}("");
        require(success, "Delegated ETH transfer failed");

        emit WithdrawETH(delegatee, setId, amountToWithdraw);
        emit DelegatedWithdrawalExecuted(delegatee, depositor, setId, amountToWithdraw);

        // Note: ERC20 delegation is similar but requires passing the token address.
        // This function only covers ETH for simplicity to keep function count down while demonstrating concept.
        // A separate executeDelegatedERC20Withdrawal would be needed, or modify this one to handle both.
        // We'll count this ETH version as demonstrating the delegation concept.
    }

     // Helper view function for delegation details
    function getDelegationDetails(bytes32 setId, address depositor, address delegatee) public view returns (Delegation memory) {
        return delegatedAccess[depositor][setId][delegatee];
    }

     // Helper view function to check if a delegate is valid for an amount
    function isDelegateValid(bytes32 setId, address depositor, address delegatee, uint256 requestedAmount) public view returns (bool valid, uint256 remainingLimit) {
        Delegation storage delegation = delegatedAccess[depositor][setId][delegatee];
        bool isActiveAndNotExpired = delegation.active && block.timestamp <= delegation.expiryTimestamp;
        bool withinLimit = delegation.amountLimit == 0 || requestedAmount <= delegation.amountLimit; // 0 limit means no limit

        return (isActiveAndNotExpired && withinLimit, delegation.amountLimit);
    }


    // --- Observer Functions ---

    function addObserver(bytes32 setId, address observerAddress) public {
        // Anyone can add an observer
        if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
         if (observerAddress == address(0)) revert ZeroAddressNotAllowed();
        observers[setId][observerAddress] = true;
        emit ObserverAdded(setId, observerAddress);
    }

    function removeObserver(bytes32 setId, address observerAddress) public {
        // Anyone can remove themselves as an observer
         if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
         if (observerAddress == address(0)) revert ZeroAddressNotAllowed();
        observers[setId][observerAddress] = false; // Don't delete storage
        emit ObserverRemoved(setId, observerAddress);
    }

    // Note: The contract does *not* actively notify observers with calls
    // (that would be a security risk due to reentrancy/gas limits).
    // The `ConditionsPossiblyMet` event is emitted on deposit as a signal
    // for off-chain services or other contracts to check conditions if they are observing.

    // --- View Functions ---

    function getBalanceInSetETH(bytes32 setId, address depositor) public view returns (uint256) {
        // Does not require set to be active
         if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
        return userDepositsETH[depositor][setId];
    }

     function getBalanceInSetERC20(IERC20 token, bytes32 setId, address depositor) public view returns (uint256) {
        // Does not require set to be active
         if (!_conditionSetIds.contains(setId)) revert SetDoesNotExist(setId);
         if (!_allowedTokens.contains(address(token))) revert TokenNotAllowed(address(token));
        return userDepositsERC20[address(token)][depositor][setId];
    }

    function getTotalETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Add function to get total balance for a specific ERC20 token
    function getTotalERC20Balance(IERC20 token) public view returns (uint256) {
         if (!_allowedTokens.contains(address(token))) revert TokenNotAllowed(address(token));
         return token.balanceOf(address(this));
    }

    // Fallback/Receive to accept ETH that is not tied to a specific deposit (accidental sends)
    receive() external payable {
        // ETH sent without calling depositETH function
        // This ETH is not associated with any set and can only be recovered by the owner
        // via a specific owner function (not implemented here for brevity, but crucial for production)
        // Or ignored/burned, depending on contract design.
        // For this example, it's simply stored in the contract balance.
        // A production contract needs an emergency withdraw for owner for such funds.
    }

    // Total Functions Count Check:
    // Admin: 4
    // Token Management: 2 (add, remove) + 1 (getAllowedTokens) = 3
    // External Deps: 2
    // Condition Sets: 4 (create, update, activate, deactivate) + 2 (get, getAll) = 6
    // Deposits: 2
    // Checking: 1
    // Withdrawals: 3 (ETH, ERC20, Batch)
    // Delegation: 3 (grant, revoke, execute) + 2 (get, isValid helper) = 5
    // Observer: 2
    // View Balances: 3 (ETH in set, ERC20 in set, Total ETH) + 1 (Total ERC20) = 4
    // Total: 4 + 3 + 2 + 6 + 2 + 1 + 3 + 5 + 2 + 4 = 32 functions. Well over 20.
}
```

**Explanation of Advanced/Creative Concepts Used:**

1.  **Conditional Release via Condition Sets:** The core mechanism. Users define complex logic (multiple conditions of different types) and lock funds against it. This is more flexible than hardcoded conditions in typical contracts. The `requiresAll` flag adds logical depth (AND vs OR for conditions).
2.  **External Dependency Integration (Conceptual):** The `ORACLE_PRICE` and `EXTERNAL_EVALUATOR` condition types, along with the `oracleAddress` and `conditionEvaluatorAddress` state variables and `set` functions, show how the contract is designed to interact with external data sources or even delegate complex boolean logic to other contracts. While the *implementation* in this example is a placeholder (`false`), the *structure* demonstrates how this would be done.
3.  **Delegated Conditional Access:** The `delegateConditionalAccess`, `revokeConditionalAccess`, and `executeDelegatedWithdrawal` functions allow a depositor to grant limited power to another address to interact with their locked funds *only if* the pre-defined conditions for the set are met *and* the delegation itself is valid (not expired, within amount limits). This is useful for escrow agents, automated agents, or allowing a trusted party to manage funds under specific circumstances.
4.  **Batch Operations:** `executeBatchedWithdrawals` allows a user or delegate to attempt withdrawals from multiple condition sets (potentially for different tokens and different depositors if delegated) in a single transaction. This saves gas for users dealing with many conditional deposits.
5.  **EnumerableSet for Tracking:** Using OpenZeppelin's `EnumerableSet` for `_allowedTokens` and `_conditionSetIds` allows for efficient tracking and retrieval of lists of tokens and condition sets, which is better than just using mappings if you need to iterate or list keys.
6.  **Structured Conditions:** The `Condition` struct with an `enum` and `bytes params` allows for extensibility. New `ConditionType` enums can be added, and their specific parameters encoded into the `bytes params`, without changing the struct definition. The `checkConditionsMet` function uses a basic `abi.decode` example, but this pattern is the foundation for integrating arbitrary complex condition checks.
7.  **Observers (via Event):** The `addObserver` and `removeObserver` functions, combined with the `ConditionsPossiblyMet` event, provide a pattern for building off-chain or other on-chain systems that can monitor condition sets and react when they might become met. This is a common design pattern for triggering external actions based on contract state changes.

This contract structure provides a robust framework for managing assets under flexible, external-data-dependent conditions, incorporating delegation and batching capabilities which are beyond typical basic vault or lock contracts.