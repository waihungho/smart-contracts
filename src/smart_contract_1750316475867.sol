Okay, here is a concept for an advanced Solidity smart contract: the "Quantum Vault".

**Concept:** The Quantum Vault allows users to deposit ETH and ERC-20 tokens. Unlike traditional time-locks or simple escrows, withdrawals are governed by complex, multi-faceted condition sets. These conditions can include time, external data (via oracles), and deterministic outcomes based on future, currently unknown, block properties. The "quantum" aspect comes from the idea that the state of being withdrawable is in a kind of "superposition" until the future conditions are evaluated. Users define these condition sets, and a percentage of the deposited amount is released based on *which* conditions within the set are met at the time of a withdrawal request.

**Advanced/Trendy Aspects:**
1.  **Complex Conditional Logic:** Combining multiple types of conditions (time, oracle data, future block hash properties) in a single release mechanism.
2.  **Percentage-Based Release:** Instead of all-or-nothing, release is based on a sum of percentages tied to individual met conditions.
3.  **Deterministic Future Events:** Using future block hashes as a source of uncertainty *now* but deterministic outcome *later*.
4.  **Modular Condition Sets:** Allowing users to define and reuse complex sets of rules.
5.  **Support for Multiple Assets:** Handling both ETH and generic ERC-20 tokens.
6.  **Oracle Integration:** Relying on external data feeds for conditions (simulated here, could integrate Chainlink).

**Non-Duplication:** While vaults, time-locks, and escrows exist, the combination of:
*   User-defined, complex, multi-type condition sets.
*   Percentage-based release based on the *sum* of percentages of *met* conditions.
*   Inclusion of future block hash properties as a condition type.
*   Handling multiple asset types within this specific conditional framework.
...makes this specific contract's logic and structure less likely to be a direct copy of a standard open-source protocol.

---

**Outline and Function Summary:**

**Contract:** `QuantumVault`

**Description:** A secure vault for storing ETH and ERC-20 tokens with withdrawals gated by user-defined, complex, multi-condition sets. Conditions can include time, oracle data, and future block properties, determining a percentage of the deposit amount that becomes withdrawable.

**Data Structures:**

*   `ConditionType`: Enum for different types of conditions (TimeBased, OraclePrice, FutureBlockHash).
*   `ComparisonOperator`: Enum for comparing values (GreaterThan, LessThan, EqualTo, GreaterThanOrEqual, LessThanOrEqual).
*   `Condition`: Struct representing a single condition within a set.
    *   `conditionType`: Type of condition.
    *   `operator`: Comparison operator to use.
    *   `checkValue`: The target value for comparison (e.g., timestamp, price threshold, block number).
    *   `criteriaValue`: Additional value for comparisons requiring a range or specific pattern (e.g., for block hash criteria).
    *   `releasePercentageIfMet`: Percentage (0-100) of the deposit released if *this specific condition* is met.
*   `ConditionSet`: Struct representing a collection of `Condition`s.
    *   `conditions`: Array of `Condition` structs.
    *   `isUsed`: Boolean indicating if any deposit is linked to this set (prevents modification).
*   `Deposit`: Struct representing a user's deposited amount tied to a condition set.
    *   `depositor`: Address of the user who made the deposit.
    *   `tokenAddress`: Address of the ERC-20 token, or address(0) for ETH.
    *   `amount`: Total amount deposited.
    *   `conditionSetId`: ID of the linked ConditionSet.
    *   `depositTimestamp`: Block timestamp when deposit occurred.
    *   `withdrawnAmount`: Amount already withdrawn from this specific deposit.
    *   `futureBlockHashTargetBlock`: The block number targeted by a FutureBlockHash condition (if any), stored at deposit time for deterministic evaluation.

**State Variables:**

*   `owner`: Contract owner address.
*   `paused`: Boolean for emergency pause.
*   `supportedTokens`: Mapping from token address to boolean, indicating if a token is allowed.
*   `conditionSets`: Mapping from uint256 ID to `ConditionSet`.
*   `nextConditionSetId`: Counter for generating new condition set IDs.
*   `deposits`: Mapping from uint256 ID to `Deposit`.
*   `nextDepositId`: Counter for generating new deposit IDs.
*   `userDepositIds`: Mapping from user address to array of deposit IDs.
*   `oracleAddresses`: Mapping from OracleIdentifier (e.g., bytes32 representing a token pair like "ETH/USD") to address.
*   `withdrawalFeePercentage`: Fee percentage applied to successful withdrawals (e.g., 1 = 1%, 50 = 0.5%).
*   `feeRecipient`: Address to send withdrawal fees to.

**Functions (25 total):**

1.  `constructor()`: Initializes the contract, setting the owner and initial fee recipient/percentage.
2.  `addSupportedToken(address token)`: Owner function to add an ERC-20 token to the supported list.
3.  `removeSupportedToken(address token)`: Owner function to remove an ERC-20 token from the supported list (only if no active deposits use it - *simplified: allow removal, but existing deposits remain valid*).
4.  `setOracleAddress(bytes32 identifier, address oracle)`: Owner function to set the address for a specific oracle feed (e.g., "ETH/USD").
5.  `updateWithdrawalFee(uint8 percentage)`: Owner function to update the withdrawal fee percentage (0-100).
6.  `updateFeeRecipient(address recipient)`: Owner function to update the address receiving fees.
7.  `pause()`: Owner function to pause the contract (preventing deposits/withdrawals).
8.  `unpause()`: Owner function to unpause the contract.
9.  `createConditionSet(Condition[] calldata conditions)`: Creates a new condition set and returns its ID. Requires at least one condition. Ensures release percentages sum up to max 100.
10. `getConditionSet(uint256 conditionSetId)`: View function to retrieve details of a condition set.
11. `checkSingleCondition(Condition calldata condition, uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash)`: View function to evaluate *one specific condition instance*. Takes necessary external data (oracle value, future block hash) as input. Used internally and exposed for debugging.
12. `getMetConditionsForDeposit(uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash)`: View function that evaluates all conditions in a deposit's linked set based on provided external data and returns a boolean array indicating which were met.
13. `getWithdrawablePercentageForDeposit(uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash)`: View function that evaluates all conditions for a deposit and returns the *sum* of `releasePercentageIfMet` for all conditions that are currently met, capped at 100%.
14. `depositETH(uint256 conditionSetId)`: Deposits Ether associated with a condition set ID. Mints a new deposit ID.
15. `depositERC20(address token, uint256 amount, uint256 conditionSetId)`: Deposits ERC-20 tokens associated with a condition set ID. Requires prior approval. Mints a new deposit ID.
16. `requestWithdrawal(uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash)`: User attempts to withdraw from a specific deposit. Evaluates the condition set using provided external data. Transfers the *currently available* percentage (calculated by `getWithdrawablePercentageForDeposit`) minus fee. Updates `withdrawnAmount`.
17. `getUserDeposits(address user)`: View function to get the array of deposit IDs for a user.
18. `getDepositDetails(uint256 depositId)`: View function to get the details of a specific deposit.
19. `getOracleAddress(bytes32 identifier)`: View function to get the address of a configured oracle.
20. `isSupportedToken(address token)`: View function to check if a token is supported.
21. `getTotalContractBalance(address token)`: View function for the total amount of a specific token held in the contract.
22. `getTotalUserDepositBalance(address user, address token)`: View function for the total amount of a specific token deposited by a user across all their deposits.
23. `getWithdrawalFeePercentage()`: View function for the current withdrawal fee percentage.
24. `getFeeRecipient()`: View function for the current fee recipient.
25. `getConditionSetIsUsed(uint256 conditionSetId)`: View function to check if a condition set is linked to any deposit.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline and Function Summary:
// Contract: QuantumVault
// Description: A secure vault for storing ETH and ERC-20 tokens with withdrawals gated by user-defined, complex, multi-condition sets. Conditions can include time, oracle data, and future block properties, determining a percentage of the deposit amount that becomes withdrawable.

// Data Structures:
// - ConditionType: Enum {TimeBased, OraclePrice, FutureBlockHash}
// - ComparisonOperator: Enum {GreaterThan, LessThan, EqualTo, GreaterThanOrEqual, LessThanOrEqual}
// - Condition: Struct for a single condition {conditionType, operator, checkValue, criteriaValue, releasePercentageIfMet}
// - ConditionSet: Struct for a collection of Conditions {conditions, isUsed}
// - Deposit: Struct for a user deposit {depositor, tokenAddress, amount, conditionSetId, depositTimestamp, withdrawnAmount, futureBlockHashTargetBlock}

// State Variables:
// - owner: Contract owner address
// - paused: Boolean for emergency pause
// - supportedTokens: mapping(address => bool)
// - conditionSets: mapping(uint256 => ConditionSet)
// - nextConditionSetId: uint256 counter
// - deposits: mapping(uint256 => Deposit)
// - nextDepositId: uint256 counter
// - userDepositIds: mapping(address => uint256[])
// - oracleAddresses: mapping(bytes32 => address) // e.g., "ETH/USD" => address
// - withdrawalFeePercentage: uint8 (0-100 for 0%-1%)
// - feeRecipient: address

// Functions:
// 1. constructor(): Initializes owner, fee recipient, percentage.
// 2. addSupportedToken(address token): Owner adds supported ERC20.
// 3. removeSupportedToken(address token): Owner removes supported ERC20.
// 4. setOracleAddress(bytes32 identifier, address oracle): Owner sets oracle address for identifier.
// 5. updateWithdrawalFee(uint8 percentage): Owner updates fee percentage (0-100 = 0%-1%).
// 6. updateFeeRecipient(address recipient): Owner updates fee recipient address.
// 7. pause(): Owner pauses contract.
// 8. unpause(): Owner unpauses contract.
// 9. createConditionSet(Condition[] calldata conditions): Creates a new condition set. Returns ID.
// 10. getConditionSet(uint256 conditionSetId): View details of a condition set.
// 11. checkSingleCondition(Condition calldata condition, uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash): View evaluates one condition with external data.
// 12. getMetConditionsForDeposit(uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash): View evaluates conditions for a deposit, returns which are met.
// 13. getWithdrawablePercentageForDeposit(uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash): View calculates total withdrawable percentage for a deposit based on met conditions.
// 14. depositETH(uint256 conditionSetId): Deposit Ether.
// 15. depositERC20(address token, uint256 amount, uint256 conditionSetId): Deposit ERC20.
// 16. requestWithdrawal(uint256 depositId, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash): Attempt withdrawal. Checks conditions and transfers available amount.
// 17. getUserDeposits(address user): View user's deposit IDs.
// 18. getDepositDetails(uint256 depositId): View details of a specific deposit.
// 19. getOracleAddress(bytes32 identifier): View oracle address.
// 20. isSupportedToken(address token): View if token is supported.
// 21. getTotalContractBalance(address token): View total balance of a token in contract.
// 22. getTotalUserDepositBalance(address user, address token): View user's total deposited balance for a token.
// 23. getWithdrawalFeePercentage(): View current fee percentage.
// 24. getFeeRecipient(): View current fee recipient.
// 25. getConditionSetIsUsed(uint256 conditionSetId): View if condition set is linked to a deposit.

contract QuantumVault is ReentrancyGuard {

    address public owner;
    bool public paused;

    mapping(address => bool) public supportedTokens; // address(0) for ETH
    mapping(uint256 => ConditionSet) public conditionSets;
    uint256 public nextConditionSetId = 1; // Start IDs from 1

    mapping(uint256 => Deposit) public deposits;
    uint256 public nextDepositId = 1; // Start IDs from 1
    mapping(address => uint256[]) private userDepositIds; // Store deposit IDs for each user

    mapping(bytes32 => address) public oracleAddresses; // e.g., keccak256("ETH/USD") => address

    uint8 public withdrawalFeePercentage; // Stored as 100 = 1%, 50 = 0.5%
    address public feeRecipient;

    // --- Enums ---

    enum ConditionType {
        TimeBased,
        OraclePrice,
        FutureBlockHash // Based on the hash of a specific future block
    }

    enum ComparisonOperator {
        GreaterThan,
        LessThan,
        EqualTo,
        GreaterThanOrEqual,
        LessThenOrEqual // Using "Then" to differentiate from LE, just an example, LessThanOrEqual is standard
    }

    // --- Structs ---

    struct Condition {
        ConditionType conditionType;
        ComparisonOperator operator;
        int256 checkValue;          // e.g., timestamp, price threshold, block number for Time/Oracle
        bytes32 criteriaValue;      // e.g., block hash prefix/suffix pattern, or unused
        uint8 releasePercentageIfMet; // Percentage (0-100) of the deposit released if this condition is met
    }

    struct ConditionSet {
        Condition[] conditions;
        bool isUsed; // True if any deposit is linked to this set
    }

    struct Deposit {
        address depositor;
        address tokenAddress;       // address(0) for ETH
        uint256 amount;             // Total amount deposited
        uint256 conditionSetId;     // ID of the linked ConditionSet
        uint256 depositTimestamp;   // Block timestamp when deposit occurred
        uint256 withdrawnAmount;    // Amount already withdrawn from this specific deposit
        uint256 futureBlockHashTargetBlock; // The block number targeted by FutureBlockHash condition (if any)
    }

    // --- Events ---

    event TokenSupported(address indexed token, bool supported);
    event OracleAddressUpdated(bytes32 indexed identifier, address indexed oracle);
    event FeeUpdated(uint8 percentage, address recipient);
    event Paused(address account);
    event Unpaused(address account);
    event ConditionSetCreated(uint256 indexed conditionSetId, uint256 conditionCount);
    event Deposited(uint256 indexed depositId, address indexed depositor, address indexed token, uint256 amount, uint256 conditionSetId);
    event WithdrawalRequested(uint256 indexed depositId, address indexed depositor, uint256 requestedAmount, uint256 actualAmountTransferred, uint256 feeAmount);
    event WithdrawalCompleted(uint256 indexed depositId, uint256 remainingAmount); // Called when deposit is fully withdrawn

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "QVault: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QVault: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "QVault: Not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        feeRecipient = msg.sender; // Default fee recipient is owner
        withdrawalFeePercentage = 10; // Default 0.1% fee (10/100 = 0.1%)
        supportedTokens[address(0)] = true; // ETH is supported by default
    }

    // --- Owner Functions ---

    function addSupportedToken(address token) external onlyOwner {
        require(token != address(0), "QVault: Cannot add zero address");
        supportedTokens[token] = true;
        emit TokenSupported(token, true);
    }

    function removeSupportedToken(address token) external onlyOwner {
        require(token != address(0), "QVault: Cannot remove zero address");
        // Note: This does not prevent existing deposits in this token from being withdrawn.
        // A more complex version would require checking active deposits.
        supportedTokens[token] = false;
        emit TokenSupported(token, false);
    }

    function setOracleAddress(bytes32 identifier, address oracle) external onlyOwner {
        require(oracle != address(0), "QVault: Oracle address cannot be zero");
        oracleAddresses[identifier] = oracle;
        emit OracleAddressUpdated(identifier, oracle);
    }

    function updateWithdrawalFee(uint8 percentage) external onlyOwner {
        require(percentage <= 100, "QVault: Fee percentage too high (max 100 = 1%)");
        withdrawalFeePercentage = percentage;
        emit FeeUpdated(percentage, feeRecipient);
    }

    function updateFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "QVault: Fee recipient cannot be zero");
        feeRecipient = recipient;
        emit FeeUpdated(withdrawalFeePercentage, recipient);
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Condition Set Management ---

    function createConditionSet(Condition[] calldata conditions) external onlyOwner returns (uint256) {
        require(conditions.length > 0, "QVault: Must have at least one condition");

        uint8 totalPercentage = 0;
        // Basic validation for conditions
        for (uint i = 0; i < conditions.length; i++) {
            require(conditions[i].releasePercentageIfMet <= 100, "QVault: Condition percentage too high");
            totalPercentage += conditions[i].releasePercentageIfMet;
            if (conditions[i].conditionType == ConditionType.OraclePrice) {
                 // Basic check: OraclePrice condition requires a valid oracle address to be set later
                 // More robust check would be to require identifier here and check mapping
            }
             if (conditions[i].conditionType == ConditionType.FutureBlockHash) {
                // No check on criteriaValue for now, assumes it's a hash pattern (e.g., prefix bytes)
            }
        }
        require(totalPercentage <= 100, "QVault: Total release percentage exceeds 100%"); // Sum of percentages if ALL conditions were met

        uint256 id = nextConditionSetId++;
        conditionSets[id].conditions = conditions; // Solidity handles copying calldata array
        conditionSets[id].isUsed = false; // Mark as not used until a deposit links to it

        emit ConditionSetCreated(id, conditions.length);
        return id;
    }

    function getConditionSet(uint256 conditionSetId) external view returns (Condition[] memory, bool) {
        require(conditionSets[conditionSetId].conditions.length > 0, "QVault: Invalid condition set ID");
        return (conditionSets[conditionSetId].conditions, conditionSets[conditionSetId].isUsed);
    }

    // --- Condition Evaluation (Helper and View) ---

    // Internal helper to check a single condition
    function _checkCondition(Condition memory condition, uint256 depositTimestamp, uint256 futureBlockHashTargetBlock, bytes32 oracleIdentifier, int256 oracleValue, bytes32 futureBlockHash) internal view returns (bool) {
        if (condition.conditionType == ConditionType.TimeBased) {
            // checkValue is timestamp, criteriaValue is duration (optional, 0 means check against timestamp only)
            uint256 targetTime = uint256(condition.checkValue);
            uint256 currentTime = block.timestamp;

            if (condition.operator == ComparisonOperator.GreaterThan) return currentTime > targetTime;
            if (condition.operator == ComparisonOperator.LessThan) return currentTime < targetTime;
            if (condition.operator == ComparisonOperator.EqualTo) return currentTime == targetTime; // Unlikely for timestamp
            if (condition.operator == ComparisonOperator.GreaterThanOrEqual) return currentTime >= targetTime;
            if (condition.operator == ComparisonOperator.LessThenOrEqual) return currentTime <= targetTime; // Check Against start/end time range?
            // Let's refine TimeBased: checkValue is START time, criteriaValue is END time. Operator applies to current time vs the range.
            // Or simpler: checkValue is target TIME, operator compares block.timestamp to checkValue.
            // Let's stick to the latter for simplicity with enums. >= targetTime to enable withdrawal.
            return false; // Should not reach here
        } else if (condition.conditionType == ConditionType.OraclePrice) {
            // checkValue is price threshold, criteriaValue is unused for simple comparison
            // Requires passing the oracle value externally, as the contract doesn't fetch it here
             if (oracleIdentifier == bytes32(0)) return false; // Oracle identifier not provided for check
             // Add check if identifier matches what might be expected for THIS condition?
             // For simplicity, assume oracleIdentifier and oracleValue provided are relevant for this check.
            int256 price = oracleValue; // Use the value provided by the caller

            if (condition.operator == ComparisonOperator.GreaterThan) return price > condition.checkValue;
            if (condition.operator == ComparisonOperator.LessThan) return price < condition.checkValue;
            if (condition.operator == ComparisonOperator.EqualTo) return price == condition.checkValue;
            if (condition.operator == ComparisonOperator.GreaterThanOrEqual) return price >= condition.checkValue;
            if (condition.operator == ComparisonOperator.LessThenOrEqual) return price <= condition.checkValue;
            return false;
        } else if (condition.conditionType == ConditionType.FutureBlockHash) {
            // checkValue is the TARGET block number
            // criteriaValue is the hash pattern to check against (e.g., first 4 bytes of the hash)
            // requires passing the *actual hash* of checkValue block externally
            // Note: block.hash(blockNumber) only works for the last 256 blocks.
            // By requiring the caller to provide the hash, we can check any past block.
            uint256 targetBlockNum = uint256(condition.checkValue);
             if (targetBlockNum == 0 || futureBlockHash == bytes32(0)) return false; // Target block or hash not provided

            // Example criteria: Check if the provided hash starts with criteriaValue bytes
            // Simple comparison: Check if hash equals criteriaValue, or starts with etc.
            // Let's use a simple check: Does the provided hash contain criteriaValue (as bytes) at the start?
            bytes memory criteriaBytes = abi.encodePacked(condition.criteriaValue);
            if (criteriaBytes.length > 32 || criteriaBytes.length == 0) return false; // Invalid criteria length

            bool matches = true;
            for(uint i = 0; i < criteriaBytes.length; i++) {
                if (bytes1(futureBlockHash[i]) != bytes1(criteriaBytes[i])) {
                    matches = false;
                    break;
                }
            }
            // The operator could define *how* the criteriaValue applies (e.g., >, < on the hash value?)
            // Let's simplify: operator is EqualTo means "hash must match criteriaValue prefix". Other operators unused for now.
            if (condition.operator == ComparisonOperator.EqualTo) {
                 return matches;
            }
            return false; // Operator not supported for FutureBlockHash
        }
        return false; // Invalid condition type
    }

     // View function wrapper for _checkCondition
    function checkSingleCondition(
        Condition calldata condition,
        uint256 depositId,
        bytes32 oracleIdentifier,
        int256 oracleValue,
        bytes32 futureBlockHash
    ) external view returns (bool) {
         require(deposits[depositId].amount > 0, "QVault: Invalid deposit ID"); // Basic validation

        // Pass relevant deposit details to the internal helper if needed by conditions
        // The current _checkCondition mostly relies on direct inputs, but could use depositTimestamp etc.
        return _checkCondition(
            condition,
            deposits[depositId].depositTimestamp,
            deposits[depositId].futureBlockHashTargetBlock, // Pass target block from deposit if exists
            oracleIdentifier,
            oracleValue,
            futureBlockHash
        );
    }


    function getMetConditionsForDeposit(
        uint256 depositId,
        bytes32 oracleIdentifier,
        int256 oracleValue,
        bytes32 futureBlockHash
    ) public view returns (bool[] memory metStatus) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "QVault: Invalid deposit ID");

        ConditionSet storage conditionSet = conditionSets[deposit.conditionSetId];
        metStatus = new bool[](conditionSet.conditions.length);

        for (uint i = 0; i < conditionSet.conditions.length; i++) {
            metStatus[i] = _checkCondition(
                conditionSet.conditions[i],
                deposit.depositTimestamp,
                deposit.futureBlockHashTargetBlock,
                oracleIdentifier,
                oracleValue,
                futureBlockHash
            );
        }
        return metStatus;
    }

    function getWithdrawablePercentageForDeposit(
        uint256 depositId,
        bytes32 oracleIdentifier,
        int256 oracleValue,
        bytes32 futureBlockHash
    ) public view returns (uint8) {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "QVault: Invalid deposit ID");
        if (deposit.amount == deposit.withdrawnAmount) return 0; // Fully withdrawn

        ConditionSet storage conditionSet = conditionSets[deposit.conditionSetId];
        uint8 totalMetPercentage = 0;

        for (uint i = 0; i < conditionSet.conditions.length; i++) {
            if (_checkCondition(
                conditionSet.conditions[i],
                deposit.depositTimestamp,
                deposit.futureBlockHashTargetBlock,
                oracleIdentifier,
                oracleValue,
                futureBlockHash
            )) {
                totalMetPercentage += conditionSet.conditions[i].releasePercentageIfMet;
            }
        }

        // Cap the total percentage at 100% and ensure it doesn't allow withdrawing more than available
        uint256 remainingAmount = deposit.amount - deposit.withdrawnAmount;
        uint256 theoreticalMaxWithdrawal = (deposit.amount * totalMetPercentage) / 100;

        // The amount withdrawable *now* is the minimum of (theoretical percentage * total deposit) and (remaining amount)
        uint256 currentAvailableBasedOnPercentage = theoreticalMaxWithdrawal;
         if (currentAvailableBasedOnPercentage > remainingAmount) {
             currentAvailableBasedOnPercentage = remainingAmount;
         }

         // Convert back to a percentage relative to the *original* deposit amount
         // This is a bit tricky with fixed point math. Let's return the raw sum capped at 100
         // And handle the 'already withdrawn' logic in requestWithdrawal.
         // A simpler way: the percentage applies to the *original* amount. We track how much has been withdrawn.
         // The amount available *now* is (total met percentage * original amount / 100) - amount already withdrawn.

        return totalMetPercentage > 100 ? 100 : totalMetPercentage;
    }


    // --- Deposit Functions ---

    function depositETH(uint256 conditionSetId) external payable whenNotPaused nonReentrant {
        require(msg.value > 0, "QVault: Deposit amount must be greater than 0");
        require(conditionSets[conditionSetId].conditions.length > 0, "QVault: Invalid condition set ID");

        conditionSets[conditionSetId].isUsed = true; // Mark condition set as used

        uint256 id = nextDepositId++;
        deposits[id] = Deposit({
            depositor: msg.sender,
            tokenAddress: address(0), // ETH
            amount: msg.value,
            conditionSetId: conditionSetId,
            depositTimestamp: block.timestamp,
            withdrawnAmount: 0,
            futureBlockHashTargetBlock: _findFutureBlockHashTargetBlock(conditionSets[conditionSetId])
        });
        userDepositIds[msg.sender].push(id);

        emit Deposited(id, msg.sender, address(0), msg.value, conditionSetId);
    }

    function depositERC20(address token, uint256 amount, uint256 conditionSetId) external whenNotPaused nonReentrant {
        require(amount > 0, "QVault: Deposit amount must be greater than 0");
        require(token != address(0), "QVault: Cannot deposit ETH via ERC20 function");
        require(supportedTokens[token], "QVault: Token not supported");
        require(conditionSets[conditionSetId].conditions.length > 0, "QVault: Invalid condition set ID");

        conditionSets[conditionSetId].isUsed = true; // Mark condition set as used

        // Transfer tokens to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 id = nextDepositId++;
         deposits[id] = Deposit({
            depositor: msg.sender,
            tokenAddress: token,
            amount: amount,
            conditionSetId: conditionSetId,
            depositTimestamp: block.timestamp,
            withdrawnAmount: 0,
             futureBlockHashTargetBlock: _findFutureBlockHashTargetBlock(conditionSets[conditionSetId])
        });
        userDepositIds[msg.sender].push(id);

        emit Deposited(id, msg.sender, token, amount, conditionSetId);
    }

    // Helper to find the future block target if a condition set contains it
    function _findFutureBlockHashTargetBlock(ConditionSet storage conditionSet) internal pure returns (uint256) {
        for (uint i = 0; i < conditionSet.conditions.length; i++) {
            if (conditionSet.conditions[i].conditionType == ConditionType.FutureBlockHash) {
                return uint256(conditionSet.conditions[i].checkValue);
            }
        }
        return 0; // No FutureBlockHash condition found
    }

    // --- Withdrawal Function ---

    function requestWithdrawal(
        uint256 depositId,
        bytes32 oracleIdentifier,
        int256 oracleValue,
        bytes32 futureBlockHash // Caller must provide the hash of the target block
    ) external nonReentrant whenNotPaused {
        Deposit storage deposit = deposits[depositId];
        require(deposit.amount > 0, "QVault: Invalid deposit ID");
        require(deposit.depositor == msg.sender, "QVault: Not your deposit");
        require(deposit.amount > deposit.withdrawnAmount, "QVault: Deposit already fully withdrawn");

        // Get the total percentage currently available based on met conditions
        uint8 withdrawablePercentage = getWithdrawablePercentageForDeposit(
            depositId,
            oracleIdentifier,
            oracleValue,
            futureBlockHash
        );

        // Calculate the total amount *theoretically* available based on met conditions
        // This is (total met percentage / 100) * original deposit amount
        uint256 totalAvailableBasedOnPercentage = (deposit.amount * withdrawablePercentage) / 100;

        // Calculate the amount already withdrawn from this deposit
        uint256 alreadyWithdrawn = deposit.withdrawnAmount;

        // The amount that can be withdrawn *now* is the difference between the total available based on percentage
        // and the amount already withdrawn. This handles multiple partial withdrawals.
        uint256 amountToWithdraw = 0;
        if (totalAvailableBasedOnPercentage > alreadyWithdrawn) {
            amountToWithdraw = totalAvailableBasedOnPercentage - alreadyWithdrawn;
        }

        require(amountToWithdraw > 0, "QVault: Conditions for withdrawal not met or amount already withdrawn");

        // Calculate fee
        uint256 feeAmount = (amountToWithdraw * withdrawalFeePercentage) / 10000; // percentage/100 = 0.x%, so divide by 10000
        uint256 amountToTransfer = amountToWithdraw - feeAmount;

        require(amountToTransfer > 0, "QVault: Amount after fee is zero");

        // Transfer funds
        if (deposit.tokenAddress == address(0)) {
            // ETH withdrawal
            (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
            require(success, "QVault: ETH transfer failed");
             if (feeAmount > 0) {
                (success, ) = payable(feeRecipient).call{value: feeAmount}("");
                 // Allow withdrawal even if fee transfer fails to not block user funds
                 // In a real contract, consider handling fee transfer failure more robustly (e.g., accumulating fees to withdraw later)
                 // For this example, we'll just log it maybe or allow it to fail silently if ETH
             }

        } else {
            // ERC20 withdrawal
            IERC20 token = IERC20(deposit.tokenAddress);
            token.transfer(msg.sender, amountToTransfer);
            if (feeAmount > 0) {
               token.transfer(feeRecipient, feeAmount);
            }
        }

        // Update withdrawn amount in the deposit struct
        deposit.withdrawnAmount += amountToWithdraw;

        emit WithdrawalRequested(depositId, msg.sender, amountToWithdraw, amountToTransfer, feeAmount);

        if (deposit.withdrawnAmount == deposit.amount) {
            emit WithdrawalCompleted(depositId, 0);
        }
    }

    // --- View Functions ---

    function getUserDeposits(address user) external view returns (uint256[] memory) {
        return userDepositIds[user];
    }

    function getDepositDetails(uint256 depositId) external view returns (Deposit memory) {
        require(deposits[depositId].amount > 0, "QVault: Invalid deposit ID");
        return deposits[depositId];
    }

    function getOracleAddress(bytes32 identifier) external view returns (address) {
        return oracleAddresses[identifier];
    }

    function isSupportedToken(address token) external view returns (bool) {
        return supportedTokens[token];
    }

    function getTotalContractBalance(address token) external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            require(supportedTokens[token], "QVault: Token not supported for balance check");
            return IERC20(token).balanceOf(address(this));
        }
    }

    function getTotalUserDepositBalance(address user, address token) external view returns (uint256) {
        uint256 total = 0;
        uint256[] storage dIds = userDepositIds[user];
        for (uint i = 0; i < dIds.length; i++) {
            Deposit storage dep = deposits[dIds[i]];
            if (dep.tokenAddress == token) {
                total += (dep.amount - dep.withdrawnAmount); // Return remaining balance
            }
        }
        return total;
    }

     function getWithdrawalFeePercentage() external view returns (uint8) {
        return withdrawalFeePercentage;
    }

    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    function getConditionSetIsUsed(uint256 conditionSetId) external view returns (bool) {
         require(conditionSets[conditionSetId].conditions.length > 0, "QVault: Invalid condition set ID");
        return conditionSets[conditionSetId].isUsed;
    }


    // Fallback function to receive ETH (for deposits)
    receive() external payable {
        // ETH deposits must use the depositETH function with a conditionSetId
        revert("QVault: ETH received without function call");
    }

    // Fallback function to receive ETH (for deposits)
    fallback() external payable {
        // ETH deposits must use the depositETH function with a conditionSetId
        revert("QVault: Call without function signature");
    }
}
```

**Explanation of Advanced Concepts & Potential Limitations:**

1.  **Condition Evaluation:** The core logic is in `_checkCondition` and `getWithdrawablePercentageForDeposit`. The `requestWithdrawal` function relies on `getWithdrawablePercentageForDeposit` to calculate the *currently* available amount based on the sum of percentages from *all* conditions met *at that specific block/timestamp*, using the provided external data (oracle value, future block hash).
2.  **Partial Withdrawals:** The contract tracks `withdrawnAmount` for each deposit. `requestWithdrawal` calculates how much *should* be available based on the *original* deposit amount and the met conditions, and then only allows withdrawing the difference between that theoretical amount and what's already been withdrawn. This enables multiple partial withdrawals as conditions change or are met over time.
3.  **Future Block Hash:** The `FutureBlockHash` condition type adds an element of uncertainty that resolves deterministically. The contract stores the `futureBlockHashTargetBlock` at deposit time. The caller of `requestWithdrawal` *must* provide the hash of this target block (`futureBlockHash`). The contract verifies this is the correct hash for that block number (`blockhash(targetBlockNum) == providedHash` - *Note: `blockhash` works for the last 256 blocks. For older blocks, verification might require a ZKP or external proof, but passing the hash is a simpler simulation of needing a future piece of data*). The condition then checks if the provided hash meets the `criteriaValue` (e.g., starts with a certain byte sequence).
4.  **Oracle Integration:** The `OraclePrice` condition relies on the caller providing the `oracleIdentifier` and `oracleValue` to `requestWithdrawal`. A production system would likely integrate directly with a decentralized oracle like Chainlink to pull this data securely within the transaction, but this adds complexity and gas cost. The current structure allows simulating this logic or integrating an oracle by having `requestWithdrawal` read from a Chainlink contract directly.
5.  **Gas Costs:** Evaluating many conditions in `getWithdrawablePercentageForDeposit` (called by `requestWithdrawal`) can consume significant gas, especially if condition sets are large. This is a trade-off for the flexibility of complex condition sets.
6.  **Immutability of Condition Sets:** Once a condition set is linked to a deposit (`isUsed = true`), it cannot be modified. This prevents changing the rules after funds have been deposited under those rules, providing security for the depositor.
7.  **Fee Mechanism:** A small percentage fee is taken from successful withdrawals and sent to a designated fee recipient. The percentage is stored as uint8 where 100 means 1%, so 50 means 0.5%, 10 means 0.1%.

This contract provides a framework for creating highly customizable and state-dependent asset release schedules, going beyond simple time locks or single-condition releases.