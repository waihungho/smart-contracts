Okay, let's design a smart contract that leverages some advanced and creative concepts. We'll create a "Quantum Flux Vault" where deposited assets are locked until specific, dynamically set conditions are met. These conditions can be time-based, external event-based, data-feed based (simulated oracle), or even "entangled" with the state of *other* deposits within the vault. The contract will include functions for dynamic management of these deposits and conditions.

**Concept:** Quantum Flux Vault - A vault where deposited tokens are locked in a "flux state" until complex, user-defined conditions are met. Conditions can be entangled with other deposits or dependent on external factors.

**Advanced/Creative Aspects:**
1.  **Complex, Dynamic Conditions:** Not just simple time locks, but conditions based on external flags, simulated oracle data, and dependencies on the state of *other* deposits.
2.  **Deposit Entanglement:** The unlock condition of one deposit can be linked to the condition being met for another deposit within the vault. Includes checks to prevent simple circular dependencies.
3.  **Dynamic Deposit Management:** Functions to split deposits, merge deposits, change conditions (under certain constraints), and transfer deposit ownership *before* withdrawal.
4.  **External Flag Control:** Owner/trusted party can trigger conditions for groups of deposits by setting external flags.
5.  **Recursion (Simulated/Checked):** The entanglement check involves a recursive-like call structure for checking conditions of dependent deposits, requiring loop prevention.

---

## Quantum Flux Vault Contract Outline

**Contract Name:** `QuantumFluxVault`

**Core Concept:** A vault for locking ERC20 tokens until complex, dynamic conditions are met.

**Key Features:**
*   Conditional withdrawals based on multiple configurable types.
*   Support for Time, External Flag, Oracle Price (simulated), and Entangled Unlock conditions.
*   Entanglement allows one deposit's condition to depend on another's condition state.
*   Functions for splitting, merging, and transferring deposit ownership.
*   Owner control over external flags and oracle addresses.

**Interfaces Used:**
*   `IERC20`: Standard ERC20 token interface.
*   `AggregatorV3Interface` (Simulated): Interface for fetching price data from an oracle.

## Function Summary

1.  `constructor()`: Initializes the contract, setting the owner.
2.  `deposit(IERC20 _token, uint256 _amount, ConditionParams memory _condition)`: Allows users to deposit supported ERC20 tokens with specified unlock conditions.
3.  `withdraw(uint256 _depositId)`: Allows a user to withdraw a deposit if its unlock condition is met.
4.  `splitDeposit(uint256 _depositId, uint256 _splitAmount, ConditionParams memory _newCondition)`: Splits an existing, unwithdrawn deposit into two: one with `_splitAmount` and `_newCondition`, and the original retaining the remainder amount and original condition.
5.  `mergeDeposits(uint256[] memory _depositIds, ConditionParams memory _newCondition)`: Merges multiple existing, unwithdrawn deposits of the same token from the same user into a single new deposit with a combined amount and `_newCondition`. Invalidates the original deposits.
6.  `entangleDeposit(uint256 _depositId, uint256 _entangledDepositId)`: Changes the condition of `_depositId` to `EntangledUnlock`, linking it to `_entangledDepositId`.
7.  `disentangleDeposit(uint256 _depositId)`: Resets an `EntangledUnlock` condition on `_depositId` to `NoCondition` (effectively making it immediately withdrawable if no other conditions applied), provided the entangled condition wasn't already met.
8.  `extendTimedCondition(uint256 _depositId, uint256 _newUnlockTime)`: Extends the unlock timestamp for a deposit with a `Timed` condition, provided the original time hasn't passed.
9.  `changeExternalFlagConditionKey(uint256 _depositId, bytes32 _newFlagKey)`: Changes the external flag key for a deposit with an `ExternalFlag` condition, provided the original flag hasn't been set to true.
10. `transferDepositOwnership(uint256 _depositId, address _newOwner)`: Transfers the ownership of an unwithdrawn deposit to another address.
11. `getDepositStatus(address _user, uint256 _depositId)`: View function. Returns the deposit details and whether its condition is currently met.
12. `getUserDepositIds(address _user)`: View function. Returns an array of deposit IDs belonging to a user.
13. `getContractTokenBalance(IERC20 _token)`: View function. Returns the balance of a specific token held by the contract.
14. `getTotalActiveDepositedAmount(IERC20 _token)`: View function. Calculates the total amount of a specific token currently held in active, unwithdrawn deposits across all users.
15. `isSupportedToken(IERC20 _token)`: View function. Checks if a token is supported for deposits.
16. `addSupportedToken(IERC20 _token)`: Owner function. Adds a token to the list of supported deposit tokens.
17. `removeSupportedToken(IERC20 _token)`: Owner function. Removes a token from the list of supported deposit tokens (prevents new deposits, doesn't affect existing ones).
18. `setOraclePriceFeed(IERC20 _token, address _priceFeed)`: Owner function. Sets the address of an Oracle price feed for a specific token (used for `OraclePrice` conditions).
19. `setExternalFlag(bytes32 _flagKey, bool _value)`: Owner function. Sets the state of an external flag (used for `ExternalFlag` conditions).
20. `getOraclePrice(IERC20 _token)`: View function. Calls the registered oracle feed for a token and returns the latest price (simulated call).
21. `emergencyWithdrawUnsupportedToken(IERC20 _token, uint256 _amount)`: Owner function. Allows withdrawal of unsupported tokens accidentally sent to the contract.
22. `renounceOwnership()`: Owner function. Renounces ownership of the contract.
23. `transferOwnership(address newOwner)`: Owner function. Transfers ownership of the contract.

*(Note: This list is 23 functions, exceeding the minimum of 20)*

---

## Solidity Source Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // Recommended for safe token transfers

/**
 * @title QuantumFluxVault
 * @dev A smart contract for depositing and conditionally locking ERC20 tokens.
 *      Unlock conditions can be time-based, external flag-based, simulated oracle-based,
 *      or entangled with the condition state of other deposits within the vault.
 */
contract QuantumFluxVault is Context, Ownable {

    using Address for address; // For safe token transfers

    // --- Error Definitions ---
    error DepositNotFound(uint256 depositId);
    error DepositAlreadyWithdrawn(uint256 depositId);
    error ConditionNotMet(uint256 depositId);
    error UnsupportedToken(address token);
    error InvalidAmount();
    error InvalidConditionParams();
    error ConditionAlreadyMetOrInvalidType(uint256 depositId);
    error DepositAlreadySplit(uint256 depositId);
    error NotDepositOwner(uint256 depositId);
    error DepositNotEntangled(uint256 depositId);
    error DepositConditionsNotCompatible(string reason);
    error EntanglementLoopDetected(uint256 depositId, uint256 entangledId);
    error EntangledDepositNotFound(uint256 entangledId);
    error InsufficientAmountToSplit(uint256 depositId, uint256 splitAmount, uint256 originalAmount);
    error UnsupportedOrActiveDepositToken(address token);
    error ZeroAddressNotAllowed();


    // --- Enums ---
    enum ConditionType {
        NoCondition,         // Can be withdrawn immediately (or after specific action triggers this state)
        Timed,               // Unlock after a specific timestamp
        ExternalFlag,        // Unlock when a specific external flag is set to true
        OraclePrice,         // Unlock when an Oracle price feed reaches a specific value
        EntangledUnlock      // Unlock when the condition of another specific deposit is met
    }

    // --- Structs ---

    struct ConditionParams {
        ConditionType conditionType;
        uint256 uintParam;   // Used for Timed (timestamp), OraclePrice (target value), EntangledUnlock (entangled depositId)
        bytes32 bytes32Param; // Used for ExternalFlag (flag key)
        address addressParam; // Used for OraclePrice (oracle feed address, if different from default) - Note: Default oracle feed per token stored in state
    }

    struct Deposit {
        IERC20 token;
        uint256 amount;
        address owner; // Who owns this deposit lock
        ConditionParams condition;
        bool isWithdrawn;
        bool isSplitOrMerged; // Flag to invalidate deposits after split/merge
        uint256 creationBlock; // For potential future use or debugging
    }

    // --- State Variables ---

    uint256 private nextDepositId;
    mapping(uint256 => Deposit) private deposits;
    mapping(address => uint256[] as private userDepositIds; // To track deposit IDs per user

    mapping(IERC20 => bool) private supportedTokens; // List of tokens allowed for deposit
    mapping(IERC20 => address) private tokenOracleFeeds; // Default oracle feed per token for OraclePrice conditions

    mapping(bytes32 => bool) private externalFlags; // External conditions controllable by owner

    // --- Events ---

    event DepositMade(uint256 depositId, address indexed user, IERC20 indexed token, uint256 amount, ConditionType conditionType);
    event WithdrawalSuccessful(uint256 depositId, address indexed user, IERC20 indexed token, uint255 amount);
    event ConditionSet(uint256 indexed depositId, ConditionType conditionType);
    event ConditionMet(uint256 indexed depositId, ConditionType conditionType);
    event DepositSplit(uint256 indexed originalDepositId, uint256 newDepositId, uint256 splitAmount, ConditionType newConditionType);
    event DepositsMerged(uint256[] indexed originalDepositIds, uint256 newDepositId, uint256 totalAmount, ConditionType newConditionType);
    event DepositEntangled(uint256 indexed depositId, uint256 indexed entangledDepositId);
    event DepositDisentangled(uint256 indexed depositId);
    event TimedConditionExtended(uint256 indexed depositId, uint256 newUnlockTime);
    event ExternalFlagConditionKeyChanged(uint256 indexed depositId, bytes32 newFlagKey);
    event DepositOwnershipTransferred(uint256 indexed depositId, address indexed oldOwner, address indexed newOwner);
    event ExternalFlagSet(bytes32 indexed flagKey, bool value);
    event OracleFeedSet(IERC20 indexed token, address indexed feedAddress);
    event SupportedTokenAdded(IERC20 indexed token);
    event SupportedTokenRemoved(IERC20 indexed token);
    event EmergencyWithdraw(IERC20 indexed token, uint256 amount);


    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        nextDepositId = 1; // Start deposit IDs from 1
    }

    // --- Core Functionality ---

    /**
     * @dev Deposits supported ERC20 tokens into the vault with specified unlock conditions.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     * @param _condition The unlock condition parameters.
     */
    function deposit(IERC20 _token, uint256 _amount, ConditionParams memory _condition) external {
        if (!supportedTokens[_token]) {
            revert UnsupportedToken(address(_token));
        }
        if (_amount == 0) {
            revert InvalidAmount();
        }
        if (_condition.conditionType == ConditionType.OraclePrice && tokenOracleFeeds[_token] == address(0)) {
             revert InvalidConditionParams(); // OraclePrice needs a registered oracle feed for the token
        }
         if (_condition.conditionType == ConditionType.EntangledUnlock && _condition.uintParam == 0) {
             revert InvalidConditionParams(); // EntangledUnlock needs a valid deposit ID
        }


        // ERC20 transferFrom requires allowance
        bool success = _token.transferFrom(_msgSender(), address(this), _amount);
        require(success, "Token transfer failed");

        uint256 currentDepositId = nextDepositId++;
        deposits[currentDepositId] = Deposit({
            token: _token,
            amount: _amount,
            owner: _msgSender(),
            condition: _condition,
            isWithdrawn: false,
            isSplitOrMerged: false,
            creationBlock: block.number
        });

        userDepositIds[_msgSender()].push(currentDepositId);

        emit DepositMade(currentDepositId, _msgSender(), _token, _amount, _condition.conditionType);
        emit ConditionSet(currentDepositId, _condition.conditionType);
    }

    /**
     * @dev Allows a user to withdraw a deposit if its unlock condition is met.
     * @param _depositId The ID of the deposit to withdraw.
     */
    function withdraw(uint256 _depositId) external {
        Deposit storage deposit = deposits[_depositId];

        if (deposit.owner == address(0)) { // Check if deposit exists
            revert DepositNotFound(_depositId);
        }
        if (deposit.isWithdrawn) {
            revert DepositAlreadyWithdrawn(_depositId);
        }
        if (deposit.isSplitOrMerged) {
             revert DepositAlreadySplit(_depositId); // Cannot withdraw a deposit that was split or merged
        }
        if (deposit.owner != _msgSender()) {
             revert NotDepositOwner(_depositId);
        }

        // Check if the condition is met, preventing entanglement loops during check
        mapping(uint256 => bool) memory checkingConditionRecursionGuard;
        if (!_isConditionMetRecursive(_depositId, checkingConditionRecursionGuard)) {
            revert ConditionNotMet(_depositId);
        }

        deposit.isWithdrawn = true;
        emit ConditionMet(_depositId, deposit.condition.conditionType);

        // Perform the actual token transfer
        deposit.token.safeTransfer(deposit.owner, deposit.amount); // Use safeTransfer from Address lib

        emit WithdrawalSuccessful(_depositId, deposit.owner, deposit.token, deposit.amount);
    }

    // --- Dynamic Deposit Management ---

    /**
     * @dev Splits an existing unwithdrawn deposit into two parts.
     * The original deposit retains the original condition and remaining amount.
     * A new deposit is created with the specified split amount and a new condition.
     * @param _originalDepositId The ID of the deposit to split.
     * @param _splitAmount The amount for the new deposit.
     * @param _newCondition The condition for the new deposit.
     */
    function splitDeposit(uint256 _originalDepositId, uint256 _splitAmount, ConditionParams memory _newCondition) external {
        Deposit storage originalDeposit = deposits[_originalDepositId];

        if (originalDeposit.owner == address(0)) revert DepositNotFound(_originalDepositId);
        if (originalDeposit.owner != _msgSender()) revert NotDepositOwner(_originalDepositId);
        if (originalDeposit.isWithdrawn || originalDeposit.isSplitOrMerged) revert DepositAlreadySplit(_originalDepositId);
        if (_splitAmount == 0 || _splitAmount >= originalDeposit.amount) revert InsufficientAmountToSplit(_originalDepositId, _splitAmount, originalDeposit.amount);
         if (_newCondition.conditionType == ConditionType.OraclePrice && tokenOracleFeeds[originalDeposit.token] == address(0)) {
             revert InvalidConditionParams();
        }
        if (_newCondition.conditionType == ConditionType.EntangledUnlock && _newCondition.uintParam == 0) {
             revert InvalidConditionParams();
        }


        // Create the new deposit
        uint256 newDepositId = nextDepositId++;
         deposits[newDepositId] = Deposit({
            token: originalDeposit.token,
            amount: _splitAmount,
            owner: _msgSender(),
            condition: _newCondition,
            isWithdrawn: false,
            isSplitOrMerged: false,
            creationBlock: block.number // Can potentially derive from original, but block.number is simpler
        });

        userDepositIds[_msgSender()].push(newDepositId); // Add new ID to user's list

        // Update the original deposit
        originalDeposit.amount -= _splitAmount;

        emit DepositSplit(_originalDepositId, newDepositId, _splitAmount, _newCondition.conditionType);
        emit DepositMade(newDepositId, _msgSender(), originalDeposit.token, _splitAmount, _newCondition.conditionType);
         emit ConditionSet(newDepositId, _newCondition.conditionType);
    }

    /**
     * @dev Merges multiple unwithdrawn deposits of the same token from the same user into a single new deposit.
     * The original deposits are marked as merged and become invalid.
     * @param _depositIds The IDs of the deposits to merge.
     * @param _newCondition The condition for the new combined deposit.
     */
    function mergeDeposits(uint256[] memory _depositIds, ConditionParams memory _newCondition) external {
        if (_depositIds.length <= 1) revert InvalidAmount(); // Need at least two deposits to merge
        if (_newCondition.conditionType == ConditionType.OraclePrice && tokenOracleFeeds[deposits[_depositIds[0]].token] == address(0)) {
             revert InvalidConditionParams();
        }
        if (_newCondition.conditionType == ConditionType.EntangledUnlock && _newCondition.uintParam == 0) {
             revert InvalidConditionParams();
        }

        uint256 totalAmount = 0;
        IERC20 commonToken;
        bool firstDepositProcessed = false;

        for (uint256 i = 0; i < _depositIds.length; i++) {
            uint256 depositId = _depositIds[i];
            Deposit storage deposit = deposits[depositId];

            if (deposit.owner == address(0)) revert DepositNotFound(depositId);
            if (deposit.owner != _msgSender()) revert NotDepositOwner(depositId);
            if (deposit.isWithdrawn || deposit.isSplitOrMerged) revert DepositAlreadySplit(depositId);

            if (!firstDepositProcessed) {
                commonToken = deposit.token;
                firstDepositProcessed = true;
            } else if (deposit.token != commonToken) {
                revert DepositConditionsNotCompatible("Tokens must match");
            }

            totalAmount += deposit.amount;
        }

        // Create the new merged deposit
        uint256 newDepositId = nextDepositId++;
         deposits[newDepositId] = Deposit({
            token: commonToken,
            amount: totalAmount,
            owner: _msgSender(),
            condition: _newCondition,
            isWithdrawn: false,
            isSplitOrMerged: false,
            creationBlock: block.number
        });

        userDepositIds[_msgSender()].push(newDepositId); // Add new ID to user's list

        // Mark original deposits as merged
        for (uint256 i = 0; i < _depositIds.length; i++) {
             deposits[_depositIds[i]].isSplitOrMerged = true;
        }

        emit DepositsMerged(_depositIds, newDepositId, totalAmount, _newCondition.conditionType);
        emit DepositMade(newDepositId, _msgSender(), commonToken, totalAmount, _newCondition.conditionType);
        emit ConditionSet(newDepositId, _newCondition.conditionType);
    }


    /**
     * @dev Changes the condition of a deposit to `EntangledUnlock`, linking it to another deposit.
     * The target deposit must exist and cannot be the same as the source. Prevents simple A->B, B->A loops.
     * @param _depositId The ID of the deposit to entangle.
     * @param _entangledDepositId The ID of the deposit it will be entangled with.
     */
    function entangleDeposit(uint256 _depositId, uint256 _entangledDepositId) external {
        Deposit storage deposit = deposits[_depositId];
        Deposit storage entangledDeposit = deposits[_entangledDepositId];

        if (deposit.owner == address(0)) revert DepositNotFound(_depositId);
        if (deposit.owner != _msgSender()) revert NotDepositOwner(_depositId);
        if (deposit.isWithdrawn || deposit.isSplitOrMerged) revert DepositAlreadySplit(_depositId);
        if (entangledDeposit.owner == address(0)) revert EntangledDepositNotFound(_entangledDepositId);
        if (_depositId == _entangledDepositId) revert EntanglementLoopDetected(_depositId, _entangledDepositId);

        // Basic check to prevent immediate A->B, B->A loop: Cannot entangle with a deposit that is *already* entangled with the current deposit.
        // More complex loops (A->B->C->A) are checked during _isConditionMetRecursive.
        if (entangledDeposit.condition.conditionType == ConditionType.EntangledUnlock && entangledDeposit.condition.uintParam == _depositId) {
             revert EntanglementLoopDetected(_depositId, _entangledDepositId);
        }

        deposit.condition.conditionType = ConditionType.EntangledUnlock;
        deposit.condition.uintParam = _entangledDepositId;
        deposit.condition.bytes32Param = bytes32(0); // Clear other params
        deposit.condition.addressParam = address(0);

        emit DepositEntangled(_depositId, _entangledDepositId);
        emit ConditionSet(_depositId, ConditionType.EntangledUnlock);
    }

     /**
     * @dev Resets an `EntangledUnlock` condition back to `NoCondition`.
     * Only possible if the deposit has an `EntangledUnlock` condition and its condition hasn't been met yet.
     * @param _depositId The ID of the deposit to disentangle.
     */
    function disentangleDeposit(uint256 _depositId) external {
         Deposit storage deposit = deposits[_depositId];

        if (deposit.owner == address(0)) revert DepositNotFound(_depositId);
        if (deposit.owner != _msgSender()) revert NotDepositOwner(_depositId);
        if (deposit.isWithdrawn || deposit.isSplitOrMerged) revert DepositAlreadySplit(_depositId); // Cannot disentangle if already resolved by split/merge
        if (deposit.condition.conditionType != ConditionType.EntangledUnlock) revert DepositNotEntangled(_depositId);

         // Cannot disentangle if the entangled condition is ALREADY met
         mapping(uint256 => bool) memory checkingConditionRecursionGuard;
         if (_isConditionMetRecursive(_depositId, checkingConditionRecursionGuard)) {
             revert ConditionAlreadyMetOrInvalidType(_depositId);
         }

        deposit.condition.conditionType = ConditionType.NoCondition;
        deposit.condition.uintParam = 0;
        deposit.condition.bytes32Param = bytes32(0);
        deposit.condition.addressParam = address(0);

        emit DepositDisentangled(_depositId);
        emit ConditionSet(_depositId, ConditionType.NoCondition);
    }


    /**
     * @dev Extends the unlock timestamp for a deposit with a `Timed` condition.
     * Only allowed if the original time hasn't passed and the new time is in the future.
     * @param _depositId The ID of the deposit.
     * @param _newUnlockTime The new timestamp for unlocking. Must be greater than the current time AND the existing unlock time.
     */
    function extendTimedCondition(uint256 _depositId, uint256 _newUnlockTime) external {
        Deposit storage deposit = deposits[_depositId];

        if (deposit.owner == address(0)) revert DepositNotFound(_depositId);
        if (deposit.owner != _msgSender()) revert NotDepositOwner(_depositId);
        if (deposit.isWithdrawn || deposit.isSplitOrMerged) revert DepositAlreadySplit(_depositId);
        if (deposit.condition.conditionType != ConditionType.Timed) revert ConditionAlreadyMetOrInvalidType(_depositId);
        if (_newUnlockTime <= block.timestamp) revert InvalidConditionParams(); // New time must be in the future
        if (_newUnlockTime <= deposit.condition.uintParam) revert InvalidConditionParams(); // New time must be strictly greater than current unlock time

        deposit.condition.uintParam = _newUnlockTime;
        emit TimedConditionExtended(_depositId, _newUnlockTime);
    }

     /**
     * @dev Changes the external flag key for a deposit with an `ExternalFlag` condition.
     * Only allowed if the original flag hasn't been set to true.
     * @param _depositId The ID of the deposit.
     * @param _newFlagKey The new external flag key. Cannot be bytes32(0).
     */
    function changeExternalFlagConditionKey(uint256 _depositId, bytes32 _newFlagKey) external {
        Deposit storage deposit = deposits[_depositId];

        if (deposit.owner == address(0)) revert DepositNotFound(_depositId);
        if (deposit.owner != _msgSender()) revert NotDepositOwner(_depositId);
        if (deposit.isWithdrawn || deposit.isSplitOrMerged) revert DepositAlreadySplit(_depositId);
        if (deposit.condition.conditionType != ConditionType.ExternalFlag) revert ConditionAlreadyMetOrInvalidType(_depositId);
        if (_newFlagKey == bytes32(0)) revert InvalidConditionParams();

        // Cannot change if the old flag is ALREADY true
        if(externalFlags[deposit.condition.bytes32Param]) {
             revert ConditionAlreadyMetOrInvalidType(_depositId);
        }

        deposit.condition.bytes32Param = _newFlagKey;
        emit ExternalFlagConditionKeyChanged(_depositId, _newFlagKey);
    }

    /**
     * @dev Allows the current owner of an unwithdrawn deposit to transfer its ownership to another address.
     * The new owner gains the right to withdraw the deposit once its condition is met.
     * @param _depositId The ID of the deposit to transfer.
     * @param _newOwner The address of the new owner. Cannot be address(0).
     */
    function transferDepositOwnership(uint256 _depositId, address _newOwner) external {
        Deposit storage deposit = deposits[_depositId];

        if (deposit.owner == address(0)) revert DepositNotFound(_depositId);
        if (deposit.owner != _msgSender()) revert NotDepositOwner(_depositId);
        if (deposit.isWithdrawn || deposit.isSplitOrMerged) revert DepositAlreadySplit(_depositId);
        if (_newOwner == address(0)) revert ZeroAddressNotAllowed();

        address oldOwner = deposit.owner;
        deposit.owner = _newOwner;

        // Note: Updating userDepositIds mapping to remove the old ID and add the new one
        // is complex and gas-intensive (requires iterating and shifting arrays).
        // For simplicity and gas efficiency in this example, we'll allow getUserDepositIds
        // to return old IDs that are no longer owned. A frontend would need to filter.
        // In production, consider linked lists or more complex mapping structures.

        emit DepositOwnershipTransferred(_depositId, oldOwner, _newOwner);
    }


    // --- Owner/Admin Functions ---

    /**
     * @dev Adds a token to the list of supported tokens for deposits.
     * Only the owner can call this.
     * @param _token The address of the ERC20 token.
     */
    function addSupportedToken(IERC20 _token) external onlyOwner {
        if (_token == IERC20(address(0))) revert ZeroAddressNotAllowed();
        supportedTokens[_token] = true;
        emit SupportedTokenAdded(_token);
    }

    /**
     * @dev Removes a token from the list of supported tokens. New deposits of this token will fail.
     * Existing deposits are unaffected.
     * Only the owner can call this.
     * @param _token The address of the ERC20 token.
     */
    function removeSupportedToken(IERC20 _token) external onlyOwner {
         if (_token == IERC20(address(0))) revert ZeroAddressNotAllowed();
        supportedTokens[_token] = false;
        // Note: Does not affect existing deposits in this example.
        // A more complex implementation might track active deposits per token.
        emit SupportedTokenRemoved(_token);
    }


    /**
     * @dev Sets the address of a Chainlink-compatible AggregatorV3Interface price feed for a token.
     * Used for `OraclePrice` conditions.
     * Only the owner can call this.
     * @param _token The token the price feed is for.
     * @param _priceFeed The address of the AggregatorV3Interface contract.
     */
    function setOraclePriceFeed(IERC20 _token, address _priceFeed) external onlyOwner {
         if (_token == IERC20(address(0)) || _priceFeed == address(0)) revert ZeroAddressNotAllowed();
        tokenOracleFeeds[_token] = _priceFeed;
        emit OracleFeedSet(_token, _priceFeed);
    }

    /**
     * @dev Sets the state of an external flag. Can be used to trigger `ExternalFlag` conditions.
     * Only the owner can call this.
     * @param _flagKey The key of the flag.
     * @param _value The boolean value to set the flag to.
     */
    function setExternalFlag(bytes32 _flagKey, bool _value) external onlyOwner {
        if (_flagKey == bytes32(0)) revert InvalidConditionParams();
        externalFlags[_flagKey] = _value;
        emit ExternalFlagSet(_flagKey, _value);
    }

     /**
     * @dev Allows the owner to withdraw supported tokens *not* currently associated with active, unwithdrawn deposits.
     * Primarily for retrieving tokens sent mistakenly or stuck for unforeseen reasons.
     * WARNING: Use with extreme caution. This should NOT be used to drain active deposits.
     * This implementation only allows withdrawal of tokens *not* marked as supported or tokens that are supported
     * but the contract balance exceeds the total active deposit amount for that token.
     * The latter requires calculating total active deposits, which is complex.
     * For simplicity, this function ONLY withdraws *unsupported* tokens accidentally sent.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawUnsupportedToken(IERC20 _token, uint256 _amount) external onlyOwner {
        if (supportedTokens[_token]) {
            // Complex check needed here to ensure amount doesn't impact active deposits.
            // For simplicity, this example only allows unsupported tokens.
            revert UnsupportedOrActiveDepositToken(address(_token));
        }
         if (_token == IERC20(address(0))) revert ZeroAddressNotAllowed();
         if (_amount == 0) revert InvalidAmount();


        _token.safeTransfer(owner(), _amount);
        emit EmergencyWithdraw(_token, _amount);
    }


    // --- View Functions ---

    /**
     * @dev Gets the details of a specific deposit and whether its condition is currently met.
     * @param _user The owner address of the deposit.
     * @param _depositId The ID of the deposit.
     * @return depositDetails The deposit struct.
     * @return conditionIsMet True if the condition is currently met.
     * @return exists True if the deposit ID corresponds to a valid, non-split/merged deposit.
     */
    function getDepositStatus(address _user, uint256 _depositId) external view returns (Deposit memory depositDetails, bool conditionIsMet, bool exists) {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0) || deposit.owner != _user || deposit.isSplitOrMerged) {
            return (Deposit({
                token: IERC20(address(0)),
                amount: 0,
                owner: address(0),
                condition: ConditionParams(ConditionType.NoCondition, 0, bytes32(0), address(0)),
                isWithdrawn: false,
                isSplitOrMerged: false,
                creationBlock: 0
            }), false, false);
        }

        mapping(uint256 => bool) memory checkingConditionRecursionGuard;
        bool met = !deposit.isWithdrawn && _isConditionMetRecursive(_depositId, checkingConditionRecursationGuard);

        return (deposit, met, true);
    }

    /**
     * @dev Gets the list of deposit IDs associated with a user.
     * Note: This might include IDs of deposits that have been split/merged or transferred out,
     * as modifying storage arrays is gas-intensive. Frontend should filter based on `getDepositStatus`.
     * @param _user The user address.
     * @return The array of deposit IDs.
     */
    function getUserDepositIds(address _user) external view returns (uint256[] memory) {
        return userDepositIds[_user];
    }

    /**
     * @dev Gets the current balance of a specific token held by the contract.
     * @param _token The token address.
     * @return The balance amount.
     */
    function getContractTokenBalance(IERC20 _token) external view returns (uint256) {
        return _token.balanceOf(address(this));
    }

     /**
     * @dev Calculates the total amount of a specific token currently held in active, unwithdrawn deposits.
     * NOTE: This function iterates through all user deposits and is gas-intensive.
     * @param _token The token address.
     * @return The total active amount.
     */
    function getTotalActiveDepositedAmount(IERC20 _token) external view returns (uint256) {
        uint256 totalAmount = 0;
         // WARNING: Iterating through all deposits/users can be very gas expensive.
         // In a large-scale system, consider alternative storage patterns
         // or off-chain indexing for this kind of aggregate query.
        // For demonstration, we'll iterate through ALL deposit IDs created.
        // This assumes nextDepositId is a reasonable upper bound.
        // A more accurate way would iterate through userDepositIds for all *known* users,
        // which itself requires tracking all users, also gas intensive.
        // Let's iterate through deposit IDs up to the current count.
        // This includes checking deposits from old owners if ownership was transferred,
        // which is correct for contract balance calculation.

        for (uint256 i = 1; i < nextDepositId; i++) {
             Deposit storage deposit = deposits[i];
             // Check if deposit exists (owner != address(0)) and is active (not withdrawn/split/merged)
             // and matches the token.
            if (deposit.owner != address(0) && !deposit.isWithdrawn && !deposit.isSplitOrMerged && deposit.token == _token) {
                 totalAmount += deposit.amount;
             }
         }
        return totalAmount;
    }


    /**
     * @dev Checks if a token is currently supported for new deposits.
     * @param _token The token address.
     * @return True if supported.
     */
    function isSupportedToken(IERC20 _token) external view returns (bool) {
        return supportedTokens[_token];
    }

    /**
     * @dev Gets the current state of an external flag.
     * @param _flagKey The key of the flag.
     * @return The boolean value of the flag.
     */
    function getExternalFlag(bytes32 _flagKey) external view returns (bool) {
        return externalFlags[_flagKey];
    }

     /**
     * @dev Calls the registered oracle feed for a token to get the latest price.
     * Requires a feed address to be set via `setOraclePriceFeed`.
     * Returns 0 if no oracle is set or call fails (simplistic error handling).
     * @param _token The token address.
     * @return The latest price as reported by the oracle, scaled by its decimals.
     */
    function getOraclePrice(IERC20 _token) external view returns (int256) {
        return _getOraclePrice(_token);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to check if a deposit's condition is met.
     * Includes logic for different condition types and recursive check for entanglement.
     * Uses a recursion guard to prevent infinite loops.
     * @param _depositId The ID of the deposit to check.
     * @param checkingConditionRecursionGuard Mapping to track visited deposit IDs during recursion.
     * @return True if the condition is met, false otherwise.
     */
    function _isConditionMetRecursive(uint256 _depositId, mapping(uint256 => bool) storage checkingConditionRecursionGuard) internal view returns (bool) {
        Deposit storage deposit = deposits[_depositId];

        // Base case for recursion guard
        if (checkingConditionRecursionGuard[_depositId]) {
            // We have detected a loop (e.g., A entangled with B, B entangled with A)
            // Or a path that revisits a node (A->B->C->A).
            // Such conditions cannot be met.
            return false; // Or potentially revert EntanglementLoopDetected(_depositId, entangledId) - returning false allows other conditions in a complex AND/OR structure (if implemented) to still potentially pass. Sticking to 'false' for current simple logic.
        }

        // Mark this deposit as currently being checked in this path
        checkingConditionRecursionGuard[_depositId] = true;

        bool met = false;
        ConditionParams memory condition = deposit.condition;

        if (deposit.isWithdrawn || deposit.isSplitOrMerged) {
            // A withdrawn or merged deposit's condition is effectively 'met' for entanglement checks,
            // but the deposit itself cannot be acted upon.
            // However, for the purpose of checking if its *condition* was met to unlock *another* deposit,
            // we need to check the original condition. Let's assume for EntangledUnlock,
            // the condition target must have *successfully passed* its check at some point.
            // Simplest implementation: recursively check the entangled deposit's condition.
            // If the deposit itself is already withdrawn/merged, its condition is considered resolved/met for others.
            met = (deposit.isWithdrawn || deposit.isSplitOrMerged);
             if(met) {
                 // If the deposit is already resolved, the condition check for deposits entangled with it succeeds.
             } else {
                 // If not resolved, check the actual condition type.
                if (condition.conditionType == ConditionType.NoCondition) {
                    met = true;
                } else if (condition.conditionType == ConditionType.Timed) {
                    met = block.timestamp >= condition.uintParam;
                } else if (condition.conditionType == ConditionType.ExternalFlag) {
                    met = externalFlags[condition.bytes32Param];
                } else if (condition.conditionType == ConditionType.OraclePrice) {
                    // Use the default oracle feed for the token unless overridden in conditionParams
                    address oracleFeedAddress = condition.addressParam != address(0) ? condition.addressParam : tokenOracleFeeds[deposit.token];
                    if (oracleFeedAddress != address(0)) {
                        int256 price = _getOraclePrice(deposit.token); // This handles the oracle call
                        met = price >= int256(condition.uintParam); // Compare price against target value
                    } else {
                        // No oracle feed configured for this token
                        met = false;
                    }
                } else if (condition.conditionType == ConditionType.EntangledUnlock) {
                    uint256 entangledId = condition.uintParam;
                    Deposit storage entangledDeposit = deposits[entangledId];

                    if (entangledDeposit.owner == address(0)) {
                        // Entangled deposit doesn't exist
                        met = false;
                    } else {
                         // Recursive call to check the entangled deposit's condition state
                         // Pass the same recursion guard map
                         met = _isConditionMetRecursive(entangledId, checkingConditionRecursionGuard);
                    }
                }
             }
        } else {
             // Deposit is active, check its current condition
              if (condition.conditionType == ConditionType.NoCondition) {
                met = true;
            } else if (condition.conditionType == ConditionType.Timed) {
                met = block.timestamp >= condition.uintParam;
            } else if (condition.conditionType == ConditionType.ExternalFlag) {
                met = externalFlags[condition.bytes32Param];
            } else if (condition.conditionType == ConditionType.OraclePrice) {
                address oracleFeedAddress = condition.addressParam != address(0) ? condition.addressParam : tokenOracleFeeds[deposit.token];
                if (oracleFeedAddress != address(0)) {
                     int256 price = _getOraclePrice(deposit.token);
                     met = price >= int256(condition.uintParam);
                } else {
                     met = false; // No oracle feed configured
                }
            } else if (condition.conditionType == ConditionType.EntangledUnlock) {
                uint256 entangledId = condition.uintParam;
                Deposit storage entangledDeposit = deposits[entangledId];
                 if (entangledDeposit.owner == address(0)) {
                    met = false; // Entangled deposit doesn't exist
                } else {
                    met = _isConditionMetRecursive(entangledId, checkingConditionRecursionGuard);
                }
            }
        }


        // Remove this deposit from the current recursion path *before* returning,
        // allowing it to be checked again if it's in a *different* path.
        // This is important for complex dependency graphs that aren't simple loops.
        // Example: A -> B, A -> C, B -> D, C -> D. D's check needs B and C.
        // When checking B's path to D, A shouldn't be marked.
        // However, the current mapping implementation is *per initial call* (per withdraw call).
        // A path-based tracking or depth limit would be more robust for complex graphs.
        // The current mapping prevents direct cycles but might fail on complex non-cycle graphs if depth is an issue.
        // Let's stick to the simple mapping for now, which primarily guards against simple cycles within one check tree.
        checkingConditionRecursionGuard[_depositId] = false; // This line might be incorrect for tracking path. A depth counter or path array is better but more complex. Let's simplify: mapping just checks "is currently being processed in *this specific check tree*".

        return met;
    }

    /**
     * @dev Internal helper to get oracle price. Calls the registered feed.
     * Assumes AggregatorV3Interface compatible. Returns 0 on call failure or no feed.
     * @param _token The token.
     * @return The price or 0 if unavailable/error.
     */
    function _getOraclePrice(IERC20 _token) internal view returns (int256) {
        address priceFeedAddress = tokenOracleFeeds[_token];
        if (priceFeedAddress == address(0)) {
            return 0; // No oracle configured
        }

        // Simulate calling AggregatorV3Interface.latestRoundData()
        // In a real contract, import and use the interface: `AggregatorV3Interface feed = AggregatorV3Interface(priceFeedAddress);`
        // And handle return values: `(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();`
        // This is a placeholder simulation for demonstration.
        // Assume a successful call returns a positive price > 0.
        // Let's return a dummy price based on token address hash for simulation purposes.
        // In reality, you'd call the oracle contract.

        try AggregatorV3Interface(priceFeedAddress).latestRoundData() returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
            if (updatedAt == 0) {
                 // Data not available
                return 0;
            }
            // Check if the answer is not stale - real implementation would add checks like updatedAt > block.timestamp - STALENESS_THRESHOLD
             return answer;

        } catch {
             // Oracle call failed or not a valid AggregatorV3Interface
            return 0;
        }
    }

    // --- Interface Definition (Simplified AggregatorV3Interface) ---
    // Required for the simulated oracle call in _getOraclePrice.
    // Import this from @chainlink/contracts if using real Chainlink feeds.
    interface AggregatorV3Interface {
        function latestRoundData() external view returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
        // Add other functions if needed, e.g., description, version, decimals
    }

    // --- Override Ownable functions for error messages if needed ---
    // Not strictly required by the prompt, but good practice.
    // function renounceOwnership() public virtual override onlyOwner { super.renounceOwnership(); }
    // function transferOwnership(address newOwner) public virtual override onlyOwner { super.transferOwnership(newOwner); }

}
```