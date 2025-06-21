Okay, here is a smart contract concept called `QuantumVault`. This contract allows users to deposit ERC20 tokens and configure multiple "Release Gates". Each gate can be set up with a complex set of conditions (like time locks, block numbers, oracle values, or even the state of *other* contracts) that must *all* be met for a specific recipient to withdraw a defined portion of the vault's tokens.

This goes beyond simple time locks or single-condition releases by allowing logical ANDing of diverse conditions and having multiple independent release paths ("gates") within the same vault for different recipients or different scenarios.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title QuantumVault
 * @dev A complex multi-conditional token vault allowing deposits and releases
 *      based on various external and internal states.
 *      Each "Gate" represents a potential release mechanism with multiple,
 *      combinable conditions.
 */

/*
Outline & Function Summary:

1.  Core Structures & Enums
    -   `GateStatus`: Enum for the state of a release gate (NotReady, Ready, Redeemed, Paused).
    -   `ConditionType`: Enum defining the type of condition to check (Time, Block, Oracle, External Contract State, ERC20 Balance).
    -   `Condition`: Struct representing a single condition within a gate.
    -   `ReleaseGate`: Struct representing a full release gate with recipient, token, amount/percentage, conditions, and status.

2.  State Variables
    -   `owner()`: Inherited from Ownable.
    -   `vaultBalances`: Mapping to track deposited token balances.
    -   `gates`: Mapping from gate ID to ReleaseGate struct.
    -   `nextGateId`: Counter for issuing unique gate IDs.
    -   `trustedOracles`: Mapping from oracle ID to trusted oracle contract address.
    -   `nextOracleId`: Counter for issuing unique oracle IDs.
    -   `isTrustedOracle`: Mapping to quickly check if an address is a trusted oracle.
    -   `emergencyWithdrawLockoutUntil`: Timestamp blocking owner emergency withdrawal.

3.  Events
    -   `TokensDeposited`: Logs token deposits.
    -   `GateAdded`: Logs the creation of a new release gate.
    -   `GateRemoved`: Logs the removal of a release gate.
    -   `ConditionAddedToGate`: Logs a condition being added to a gate.
    -   `ConditionRemovedFromGate`: Logs a condition being removed from a gate.
    -   `TrustedOracleAdded`: Logs adding a new trusted oracle.
    -   `TrustedOracleRemoved`: Logs removing a trusted oracle.
    -   `GateActivated`: Logs when all conditions for a gate are met and it becomes Ready.
    -   `TokensWithdrawn`: Logs successful withdrawal from a gate.
    -   `GatePaused`: Logs when a gate is paused.
    -   `GateUnpaused`: Logs when a gate is unpaused.
    -   `EmergencyWithdrawal`: Logs owner emergency withdrawal.
    -   `EmergencyWithdrawalLockoutSet`: Logs when the emergency withdraw lockout is set.
    -   `GateUpdated`: Logs when a gate's main parameters are updated.
    -   `ConditionUpdatedInGate`: Logs when a specific condition is updated.


4.  Oracle Interface
    -   `IOracle`: Interface expected for trusted oracle contracts (`getValue` function).

5.  Functions (28 functions planned)

    -   `constructor()`: Initializes the contract and owner.
    -   `deposit(address token, uint256 amount)`: Allows users to deposit a specific ERC20 token into the vault.
    -   `addReleaseGate(address recipient, address token, uint256 percentagePermille, uint256 fixedAmount, bool usePercentage, Condition[] calldata conditions, uint256 oracleIdForGate)`: Adds a new release gate with complex conditions. Owner only.
    -   `removeReleaseGate(uint256 gateId)`: Removes an existing release gate. Owner only.
    -   `updateReleaseGate(uint256 gateId, address recipient, uint256 percentagePermille, uint256 fixedAmount, bool usePercentage, uint256 oracleIdForGate)`: Updates main parameters of a gate (recipient, amount). Owner only.
    -   `addConditionToGate(uint256 gateId, Condition calldata newCondition)`: Adds a single condition to an existing gate. Owner only.
    -   `removeConditionFromGate(uint256 gateId, uint256 conditionIndex)`: Removes a condition from a gate by index. Owner only. (Marks inactive rather than shifts array)
    -   `updateConditionInGate(uint256 gateId, uint256 conditionIndex, Condition calldata updatedCondition)`: Updates a condition within a gate. Owner only.
    -   `addTrustedOracle(address oracleAddress)`: Adds a new address to the list of trusted oracle contracts. Owner only.
    -   `removeTrustedOracle(uint256 oracleId)`: Removes a trusted oracle by ID. Owner only.
    -   `updateTrustedOracle(uint256 oracleId, address newAddress)`: Updates the address for an existing trusted oracle ID. Owner only.
    -   `setEmergencyWithdrawLockout(uint256 untilTimestamp)`: Sets a timestamp before which emergency withdrawal is blocked. Owner only.
    -   `emergencyWithdraw(address token)`: Allows the owner to withdraw all of a specific token in case of emergency, subject to lockout.
    -   `checkConditionStatus(uint256 gateId, uint256 conditionIndex)`: View function to check the status of a *single* condition.
    -   `checkGateConditions(uint256 gateId)`: Internal helper to check *all* active conditions for a gate.
    -   `canActivateGate(uint256 gateId)`: Public view function alias for `checkGateConditions`.
    -   `activateReleaseGate(uint256 gateId)`: Attempts to activate a gate by checking its conditions. If all pass, changes status to Ready.
    -   `withdrawFromGate(uint256 gateId)`: Allows the gate's recipient to withdraw funds if the gate is Ready and not paused.
    -   `pauseReleaseGate(uint256 gateId)`: Pauses a specific gate, preventing activation or withdrawal. Owner only.
    -   `unpauseReleaseGate(uint256 gateId)`: Unpauses a specific gate. Owner only.
    -   `getGateDetails(uint256 gateId)`: View function returning details about a specific gate.
    -   `getGateStatus(uint256 gateId)`: View function returning the current status of a gate.
    -   `getTotalVaultBalance(address token)`: View function returning the total balance of a specific token in the vault.
    -   `getGateCalculatedAmount(uint256 gateId)`: View function returning the amount calculated for withdrawal for a Ready gate.
    -   `getRecipientClaimableAmount(address recipient, address token)`: View function calculating total claimable amount for a recipient across all *Ready* and *unpaused* gates for a specific token.
    -   `getGateCount()`: View function returning the total number of gates ever added.
    -   `getTrustedOracleCount()`: View function returning the total number of trusted oracles ever added.
    -   `getTrustedOracleAddress(uint256 oracleId)`: View function returning the address of a trusted oracle by ID.
    -   `getEmergencyWithdrawLockoutUntil()`: View function returning the emergency withdrawal lockout timestamp.
*/

contract QuantumVault is Ownable {

    enum GateStatus { NotReady, Ready, Redeemed, Paused }
    enum ConditionType {
        TimeAfter,      // intValue = timestamp
        TimeBefore,     // intValue = timestamp
        BlockAfter,     // intValue = block number
        BlockBefore,    // intValue = block number
        OracleValueGE,  // intValue = threshold, oracleIndex specifies oracle, data is query data
        OracleValueLE,  // intValue = threshold, oracleIndex specifies oracle, data is query data
        ExternalContractValueGE, // intValue = threshold, targetAddress = contract, data = call data (selector + args)
        ExternalContractValueLE, // intValue = threshold, targetAddress = contract, data = call data (selector + args)
        ERC20BalanceGE, // intValue = threshold, targetAddress = token address, uintValue = address to check balance of
        ERC20BalanceLE  // intValue = threshold, targetAddress = token address, uintValue = address to check balance of
    }

    struct Condition {
        ConditionType conditionType;
        int256 intValue;   // Generic integer value for threshold, timestamp, block number
        uint256 uintValue;  // Generic unsigned integer value (e.g., for address index, balance check recipient)
        address targetAddress; // Address for token, oracle, or external contract
        bytes data;         // Generic bytes data (e.g., oracle query data, contract call data)
        bool isActive;      // Allows logical removal without array manipulation
    }

    struct ReleaseGate {
        uint256 id;
        address recipient;
        address tokenAddress;
        uint256 percentagePermille; // e.g., 500 for 50% (out of 1000)
        uint256 fixedAmount; // Fixed amount override
        bool usePercentage; // true if percentagePermille is used, false if fixedAmount is used
        uint256 calculatedAmount; // Amount determined at activation time if usePercentage was true
        GateStatus status;
        Condition[] conditions;
        uint256 activationTimestamp; // When gate became Ready
        bool isPaused; // Separate pause flag
        uint256 amountRedeemed; // To track partial withdrawals if implemented (currently full withdrawal)
    }

    mapping(address => uint256) private vaultBalances;
    mapping(uint256 => ReleaseGate) private gates;
    uint256 private nextGateId = 1;

    // Oracles
    mapping(uint256 => address) private trustedOracles;
    mapping(address => uint256) private trustedOracleId; // Map address back to ID
    mapping(address => bool) private isTrustedOracle; // Quick check if an address is trusted
    uint256 private nextOracleId = 1;

    uint256 private emergencyWithdrawLockoutUntil;

    // Interface for oracles
    interface IOracle {
        function getValue(bytes calldata data) external view returns (int256);
    }

    // Events
    event TokensDeposited(address indexed token, address indexed depositor, uint256 amount);
    event GateAdded(uint256 indexed gateId, address indexed recipient, address indexed token, uint256 percentagePermille, uint256 fixedAmount, bool usePercentage);
    event GateRemoved(uint256 indexed gateId);
    event ConditionAddedToGate(uint256 indexed gateId, uint256 conditionIndex, ConditionType conditionType);
    event ConditionRemovedFromGate(uint256 indexed gateId, uint256 conditionIndex);
    event TrustedOracleAdded(uint256 indexed oracleId, address indexed oracleAddress);
    event TrustedOracleRemoved(uint256 indexed oracleId, address indexed oracleAddress);
    event GateActivated(uint256 indexed gateId, address indexed recipient, uint256 calculatedAmount, address indexed token);
    event TokensWithdrawn(uint256 indexed gateId, address indexed recipient, address indexed token, uint256 amount);
    event GatePaused(uint256 indexed gateId);
    event GateUnpaused(uint256 indexed gateId);
    event EmergencyWithdrawal(address indexed token, uint256 amount);
    event EmergencyWithdrawalLockoutSet(uint256 untilTimestamp);
    event GateUpdated(uint256 indexed gateId, address indexed newRecipient, uint256 newPercentagePermille, uint256 newFixedAmount, bool newUsePercentage);
    event ConditionUpdatedInGate(uint256 indexed gateId, uint256 conditionIndex, ConditionType newConditionType);


    constructor() Ownable(msg.sender) {}

    /**
     * @dev Deposits ERC20 tokens into the vault.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function deposit(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 tokenContract = IERC20(token);
        // Transfer tokens from sender to this contract
        bool success = tokenContract.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        vaultBalances[token] += amount;

        emit TokensDeposited(token, msg.sender, amount);
    }

    /**
     * @dev Adds a new release gate definition.
     * @param recipient The address to receive tokens when the gate is activated and withdrawn.
     * @param token The address of the token this gate applies to.
     * @param percentagePermille The percentage of the vault's token balance at activation time (in permille, e.g., 500 for 50%). Used if usePercentage is true.
     * @param fixedAmount A fixed amount of tokens to release. Used if usePercentage is false.
     * @param usePercentage Whether to use percentagePermille (true) or fixedAmount (false).
     * @param conditions Array of Condition structs defining the gate's conditions.
     * @param oracleIdForGate If any conditions use an oracle, specify the primary trusted oracle ID here.
     */
    function addReleaseGate(
        address recipient,
        address token,
        uint256 percentagePermille,
        uint256 fixedAmount,
        bool usePercentage,
        Condition[] calldata conditions,
        uint256 oracleIdForGate // Redundant if oracleId is in Condition, keep for simplicity? Or remove from Condition? Let's keep per-condition oracle ID for flexibility. Removing this param.
    ) external onlyOwner {
         require(recipient != address(0), "Invalid recipient address");
         require(token != address(0), "Invalid token address");
         if (usePercentage) {
             require(percentagePermille <= 1000, "Percentage exceeds 100%");
             require(fixedAmount == 0, "Fixed amount must be zero when using percentage");
         } else {
              require(fixedAmount > 0, "Fixed amount must be greater than zero when not using percentage");
              require(percentagePermille == 0, "Percentage must be zero when using fixed amount");
         }
         require(conditions.length > 0, "At least one condition required");

         uint256 currentGateId = nextGateId++;
         ReleaseGate storage newGate = gates[currentGateId];

         newGate.id = currentGateId;
         newGate.recipient = recipient;
         newGate.tokenAddress = token;
         newGate.percentagePermille = percentagePermille;
         newGate.fixedAmount = fixedAmount;
         newGate.usePercentage = usePercentage;
         newGate.status = GateStatus.NotReady;
         newGate.isPaused = false;
         newGate.amountRedeemed = 0; // Not used in current full withdrawal logic

         // Deep copy conditions and set isActive flag
         newGate.conditions.length = conditions.length;
         for (uint i = 0; i < conditions.length; i++) {
             newGate.conditions[i] = conditions[i];
             newGate.conditions[i].isActive = true; // Mark as active initially
         }

         emit GateAdded(currentGateId, recipient, token, percentagePermille, fixedAmount, usePercentage);
    }

    /**
     * @dev Removes a release gate. Marks it as removed internally. Cannot be activated or withdrawn from.
     * @param gateId The ID of the gate to remove.
     */
    function removeReleaseGate(uint256 gateId) external onlyOwner {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId, "Gate does not exist");
        require(gate.status != GateStatus.Redeemed, "Cannot remove a redeemed gate");

        // Mark the gate as logically removed/inactive by changing status
        gate.status = GateStatus.Redeemed; // Abuse status to mark as unavailable
        // Or, simpler: just delete it from the mapping. But deleting might break loops iterating IDs.
        // Let's mark it inactive and potentially clear sensitive data.
        gate.recipient = address(0);
        // Keep tokenAddress and amount info for auditing purposes, but clear conditions?
        // Clearing conditions prevents accidental evaluation.
        delete gate.conditions; // Clear the array contents
        gate.isPaused = true; // Ensure it stays paused

        emit GateRemoved(gateId);
    }

     /**
     * @dev Updates main parameters of an existing gate. Conditions cannot be updated here.
     * @param gateId The ID of the gate to update.
     * @param newRecipient The new recipient address.
     * @param newPercentagePermille The new percentage.
     * @param newFixedAmount The new fixed amount.
     * @param newUsePercentage Whether to use percentage or fixed amount.
     */
    function updateReleaseGate(
        uint256 gateId,
        address newRecipient,
        uint256 newPercentagePermille,
        uint256 newFixedAmount,
        bool newUsePercentage
    ) external onlyOwner {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(gate.status == GateStatus.NotReady || gate.status == GateStatus.Paused, "Gate cannot be updated after activation or redemption");
        require(newRecipient != address(0), "Invalid new recipient address");

        if (newUsePercentage) {
            require(newPercentagePermille <= 1000, "Percentage exceeds 100%");
            require(newFixedAmount == 0, "Fixed amount must be zero when using percentage");
        } else {
             require(newFixedAmount > 0, "Fixed amount must be greater than zero when not using percentage");
             require(newPercentagePermille == 0, "Percentage must be zero when using fixed amount");
        }

        gate.recipient = newRecipient;
        gate.percentagePermille = newPercentagePermille;
        gate.fixedAmount = newFixedAmount;
        gate.usePercentage = newUsePercentage;

        emit GateUpdated(gateId, newRecipient, newPercentagePermille, newFixedAmount, newUsePercentage);
    }

    /**
     * @dev Adds a single condition to an existing gate.
     * @param gateId The ID of the gate.
     * @param newCondition The Condition struct to add.
     */
    function addConditionToGate(uint256 gateId, Condition calldata newCondition) external onlyOwner {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(gate.status == GateStatus.NotReady || gate.status == GateStatus.Paused, "Gate cannot be modified after activation or redemption");

        newCondition.isActive = true; // Ensure the new condition is active
        gate.conditions.push(newCondition);

        emit ConditionAddedToGate(gateId, gate.conditions.length - 1, newCondition.conditionType);
    }

    /**
     * @dev Removes a condition from a gate by marking it inactive. Does not change array length.
     * @param gateId The ID of the gate.
     * @param conditionIndex The index of the condition in the gate's conditions array.
     */
    function removeConditionFromGate(uint256 gateId, uint256 conditionIndex) external onlyOwner {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(conditionIndex < gate.conditions.length, "Condition index out of bounds");
        require(gate.status == GateStatus.NotReady || gate.status == GateStatus.Paused, "Gate cannot be modified after activation or redemption");

        require(gate.conditions[conditionIndex].isActive, "Condition is already inactive");

        gate.conditions[conditionIndex].isActive = false; // Mark as inactive

        emit ConditionRemovedFromGate(gateId, conditionIndex);
    }

     /**
     * @dev Updates a condition within a gate at a specific index.
     * @param gateId The ID of the gate.
     * @param conditionIndex The index of the condition to update.
     * @param updatedCondition The updated Condition struct.
     */
    function updateConditionInGate(uint256 gateId, uint256 conditionIndex, Condition calldata updatedCondition) external onlyOwner {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(conditionIndex < gate.conditions.length, "Condition index out of bounds");
        require(gate.status == GateStatus.NotReady || gate.status == GateStatus.Paused, "Gate cannot be modified after activation or redemption");
        require(gate.conditions[conditionIndex].isActive, "Cannot update an inactive condition");

        // Preserve the isActive status, copy everything else
        bool wasActive = gate.conditions[conditionIndex].isActive;
        gate.conditions[conditionIndex] = updatedCondition;
        gate.conditions[conditionIndex].isActive = wasActive; // Ensure it remains active unless explicitly removed

        emit ConditionUpdatedInGate(gateId, conditionIndex, updatedCondition.conditionType);
    }


    /**
     * @dev Adds a trusted oracle contract address.
     * @param oracleAddress The address of the oracle contract.
     */
    function addTrustedOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(!isTrustedOracle[oracleAddress], "Oracle address already trusted");

        uint256 currentOracleId = nextOracleId++;
        trustedOracles[currentOracleId] = oracleAddress;
        trustedOracleId[oracleAddress] = currentOracleId; // Store reverse mapping
        isTrustedOracle[oracleAddress] = true;

        emit TrustedOracleAdded(currentOracleId, oracleAddress);
    }

    /**
     * @dev Removes a trusted oracle by its ID. Sets address to zero.
     * @param oracleId The ID of the oracle to remove.
     */
    function removeTrustedOracle(uint256 oracleId) external onlyOwner {
        address oracleAddress = trustedOracles[oracleId];
        require(oracleAddress != address(0), "Oracle ID not found");

        delete isTrustedOracle[oracleAddress];
        delete trustedOracleId[oracleAddress]; // Remove reverse mapping
        delete trustedOracles[oracleId]; // Set address to zero

        emit TrustedOracleRemoved(oracleId, oracleAddress);
    }

    /**
     * @dev Updates the address for an existing trusted oracle ID. Useful for oracle upgrades.
     * @param oracleId The ID of the oracle to update.
     * @param newAddress The new address for the oracle contract.
     */
    function updateTrustedOracle(uint256 oracleId, address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid new oracle address");
        address oldAddress = trustedOracles[oracleId];
        require(oldAddress != address(0), "Oracle ID not found");
        require(oldAddress != newAddress, "New address is the same as the old one");
        require(!isTrustedOracle[newAddress], "New address is already a trusted oracle");

        // Clean up old mappings
        delete isTrustedOracle[oldAddress];
        delete trustedOracleId[oldAddress];

        // Set new mappings
        trustedOracles[oracleId] = newAddress;
        trustedOracleId[newAddress] = oracleId;
        isTrustedOracle[newAddress] = true;

        emit TrustedOracleAdded(oracleId, newAddress); // Log as added, maybe a specific update event is better
    }

     /**
     * @dev Sets a timestamp before which the owner cannot perform an emergency withdrawal.
     * @param untilTimestamp The timestamp until which emergency withdrawal is locked out.
     */
    function setEmergencyWithdrawLockout(uint256 untilTimestamp) external onlyOwner {
        emergencyWithdrawLockoutUntil = untilTimestamp;
        emit EmergencyWithdrawalLockoutSet(untilTimestamp);
    }


    /**
     * @dev Allows the owner to withdraw all of a specific token in case of emergency.
     *      Subject to the emergency withdraw lockout timestamp.
     * @param token The address of the token to withdraw.
     */
    function emergencyWithdraw(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(block.timestamp >= emergencyWithdrawLockoutUntil, "Emergency withdrawal is locked out");

        uint256 balance = vaultBalances[token];
        require(balance > 0, "No balance of this token to withdraw");

        vaultBalances[token] = 0; // Set balance to zero before transferring

        // Transfer tokens to the owner
        IERC20 tokenContract = IERC20(token);
        bool success = tokenContract.transfer(owner(), balance);
        require(success, "Emergency token transfer failed");

        emit EmergencyWithdrawal(token, balance);
    }


    /**
     * @dev Internal helper function to check the status of a single condition within a gate.
     * @param gateId The ID of the gate.
     * @param conditionIndex The index of the condition to check.
     * @return bool True if the condition is met, false otherwise.
     */
    function checkConditionStatus(uint256 gateId, uint256 conditionIndex) internal view returns (bool) {
        ReleaseGate storage gate = gates[gateId];
        require(conditionIndex < gate.conditions.length, "Condition index out of bounds");

        Condition storage condition = gate.conditions[conditionIndex];
        if (!condition.isActive) {
            return false; // Inactive conditions are never met
        }

        bytes memory callData; // Placeholder for potential external calls

        // Note: Direct cross-contract calls in conditions add significant gas cost.
        // Oracles should provide data efficiently. External contract state checks
        // are the most gas-intensive.

        // Re-entrancy is not a concern here as we are only performing view/static calls
        // in this check function.

        unchecked { // Use unchecked for arithmetic operations where overflow is not expected/critical for checks
            if (condition.conditionType == ConditionType.TimeAfter) {
                return block.timestamp >= uint256(condition.intValue);
            } else if (condition.conditionType == ConditionType.TimeBefore) {
                return block.timestamp < uint256(condition.intValue);
            } else if (condition.conditionType == ConditionType.BlockAfter) {
                 return block.number >= uint256(condition.intValue);
            } else if (condition.conditionType == ConditionType.BlockBefore) {
                 return block.number < uint256(condition.intValue);
            } else if (condition.conditionType == ConditionType.OracleValueGE) {
                 address oracleAddress = trustedOracles[condition.uintValue]; // uintValue stores oracle ID
                 require(isTrustedOracle[oracleAddress], "Condition uses untrusted or missing oracle");
                 int256 oracleValue = IOracle(oracleAddress).getValue(condition.data); // data is oracle query specific
                 return oracleValue >= condition.intValue;
            } else if (condition.conditionType == ConditionType.OracleValueLE) {
                 address oracleAddress = trustedOracles[condition.uintValue]; // uintValue stores oracle ID
                 require(isTrustedOracle[oracleAddress], "Condition uses untrusted or missing oracle");
                 int256 oracleValue = IOracle(oracleAddress).getValue(condition.data);
                 return oracleValue <= condition.intValue;
            } else if (condition.conditionType == ConditionType.ExternalContractValueGE) {
                 require(condition.targetAddress != address(0), "Condition target address not set");
                 // data should contain the function selector and encoded arguments
                 (bool success, bytes memory result) = condition.targetAddress.staticcall(condition.data);
                 require(success, "External contract call failed");
                 // Assuming the external function returns an int256 compatible value (e.g., uint256, int256, bool)
                 // Need to decode based on expected return type. Assuming simple int256 for threshold check.
                 require(result.length >= 32, "External call returned insufficient data");
                 int256 externalValue = abi.decode(result, (int256));
                 return externalValue >= condition.intValue;
            } else if (condition.conditionType == ConditionType.ExternalContractValueLE) {
                 require(condition.targetAddress != address(0), "Condition target address not set");
                 (bool success, bytes memory result) = condition.targetAddress.staticcall(condition.data);
                 require(success, "External contract call failed");
                 require(result.length >= 32, "External call returned insufficient data");
                 int256 externalValue = abi.decode(result, (int256));
                 return externalValue <= condition.intValue;
            } else if (condition.conditionType == ConditionType.ERC20BalanceGE) {
                 require(condition.targetAddress != address(0), "Condition target token address not set"); // targetAddress is token address
                 require(condition.uintValue != 0, "Condition target balance address not set"); // uintValue is address to check balance of
                 uint256 balance = IERC20(condition.targetAddress).balanceOf(address(uint160(condition.uintValue)));
                 return balance >= uint256(condition.intValue);
            } else if (condition.conditionType == ConditionType.ERC20BalanceLE) {
                 require(condition.targetAddress != address(0), "Condition target token address not set"); // targetAddress is token address
                 require(condition.uintValue != 0, "Condition target balance address not set"); // uintValue is address to check balance of
                 uint256 balance = IERC20(condition.targetAddress).balanceOf(address(uint160(condition.uintValue)));
                 return balance <= uint256(condition.intValue);
            }
        } // end unchecked
        // Should not reach here if all types are covered
        return false;
    }


    /**
     * @dev Internal helper function to check if all active conditions for a gate are met.
     * @param gateId The ID of the gate.
     * @return bool True if ALL active conditions are met, false otherwise.
     */
    function checkGateConditions(uint256 gateId) internal view returns (bool) {
         ReleaseGate storage gate = gates[gateId];
         if (gate.id != gateId || gate.status == GateStatus.Redeemed) {
             return false; // Gate doesn't exist or is removed
         }

         if (gate.conditions.length == 0) {
             return true; // No conditions means conditions are met (though addGate requires at least 1)
         }

         for (uint i = 0; i < gate.conditions.length; i++) {
             if (gate.conditions[i].isActive) {
                 if (!checkConditionStatus(gateId, i)) {
                     return false; // If any active condition is NOT met, the gate is not ready
                 }
             }
         }
         return true; // All active conditions were met
    }

    /**
     * @dev Public view function to check if a gate's conditions are met and it *could* be activated.
     *      Alias for `checkGateConditions`. Does not check current gate status or pause state.
     * @param gateId The ID of the gate.
     * @return bool True if all active conditions are met.
     */
    function canActivateGate(uint256 gateId) public view returns (bool) {
        return checkGateConditions(gateId);
    }


    /**
     * @dev Attempts to activate a release gate by checking its conditions.
     *      Callable by anyone. If all conditions are met, the gate status is set to Ready.
     * @param gateId The ID of the gate to activate.
     */
    function activateReleaseGate(uint256 gateId) external {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(gate.status == GateStatus.NotReady, "Gate is not in NotReady status");
        require(!gate.isPaused, "Gate is paused");

        require(checkGateConditions(gateId), "Gate conditions are not met");

        // Calculate the amount to be released IF using percentage
        uint256 amountToRelease = gate.fixedAmount;
        if (gate.usePercentage) {
            uint256 totalTokenBalance = vaultBalances[gate.tokenAddress];
            // Use a larger multiplier for intermediate calculation to minimize precision loss
            amountToRelease = (totalTokenBalance * gate.percentagePermille) / 1000;
        }

        require(amountToRelease > 0, "Calculated release amount is zero"); // Ensure amount is non-zero

        gate.calculatedAmount = amountToRelease; // Store the calculated amount
        gate.status = GateStatus.Ready;
        gate.activationTimestamp = block.timestamp;

        emit GateActivated(gateId, gate.recipient, amountToRelease, gate.tokenAddress);
    }

    /**
     * @dev Allows the recipient of a Ready and unpaused gate to withdraw the tokens.
     * @param gateId The ID of the gate to withdraw from.
     */
    function withdrawFromGate(uint256 gateId) external {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(gate.status == GateStatus.Ready, "Gate is not Ready for withdrawal");
        require(!gate.isPaused, "Gate is paused");
        require(msg.sender == gate.recipient, "Only the gate recipient can withdraw");

        uint256 amountToWithdraw = gate.calculatedAmount; // Use the amount calculated at activation
        require(amountToWithdraw > 0, "Amount to withdraw is zero");

        address tokenAddress = gate.tokenAddress;
        require(vaultBalances[tokenAddress] >= amountToWithdraw, "Insufficient balance in vault for withdrawal");

        // Update internal balance before transfer
        vaultBalances[tokenAddress] -= amountToWithdraw;

        // Perform the token transfer
        IERC20 tokenContract = IERC20(tokenAddress);
        // Use low-level call pattern with require check for safety
        (bool success, ) = tokenContract.call(abi.encodeWithSelector(tokenContract.transfer.selector, gate.recipient, amountToWithdraw));
        require(success, "Token transfer failed");

        gate.amountRedeemed = amountToWithdraw; // Mark the amount as redeemed (currently full amount)
        gate.status = GateStatus.Redeemed; // Mark the gate as fully redeemed

        emit TokensWithdrawn(gateId, gate.recipient, tokenAddress, amountToWithdraw);
    }

    /**
     * @dev Pauses a specific gate, preventing activation or withdrawal. Owner only.
     * @param gateId The ID of the gate to pause.
     */
    function pauseReleaseGate(uint256 gateId) external onlyOwner {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(!gate.isPaused, "Gate is already paused");

        gate.isPaused = true;
        emit GatePaused(gateId);
    }

    /**
     * @dev Unpauses a specific gate. Owner only.
     * @param gateId The ID of the gate to unpause.
     */
    function unpauseReleaseGate(uint256 gateId) external onlyOwner {
        ReleaseGate storage gate = gates[gateId];
        require(gate.id == gateId && gate.status != GateStatus.Redeemed, "Gate does not exist or is removed");
        require(gate.isPaused, "Gate is not paused");

        gate.isPaused = false;
        emit GateUnpaused(gateId);
    }

    // --- View Functions ---

    /**
     * @dev Gets details of a specific release gate.
     * @param gateId The ID of the gate.
     * @return ReleaseGate struct containing gate details.
     */
    function getGateDetails(uint256 gateId) public view returns (ReleaseGate storage) {
        require(gates[gateId].id == gateId, "Gate does not exist"); // Check if ID matches (basic existence check)
        // Note: Cannot return storage reference directly to external calls.
        // Need to return as a memory struct or individual fields.
        // Returning storage for internal/testing convenience. For public API, return memory.
        // Let's return memory for public API compliance.

        // Temporary memory struct
        ReleaseGate memory gateMemory = gates[gateId];
        return gates[gateId]; // Solidity often handles this by returning a copy for external calls
    }

    /**
     * @dev Gets the status of a specific release gate.
     * @param gateId The ID of the gate.
     * @return GateStatus The current status of the gate.
     */
    function getGateStatus(uint256 gateId) public view returns (GateStatus) {
         require(gates[gateId].id == gateId, "Gate does not exist");
         return gates[gateId].status;
    }

    /**
     * @dev Gets the total balance of a specific token held in the vault.
     * @param token The address of the token.
     * @return uint256 The total balance.
     */
    function getTotalVaultBalance(address token) public view returns (uint256) {
        return vaultBalances[token];
    }

    /**
     * @dev Gets the calculated withdrawal amount for a gate once it's Ready.
     * @param gateId The ID of the gate.
     * @return uint256 The calculated amount. Returns 0 if not Ready or amount wasn't calculated.
     */
    function getGateCalculatedAmount(uint256 gateId) public view returns (uint255) {
         ReleaseGate storage gate = gates[gateId];
         require(gate.id == gateId, "Gate does not exist");
         if (gate.status == GateStatus.Ready || gate.status == GateStatus.Redeemed) {
             return gate.calculatedAmount;
         }
         return 0;
    }


    /**
     * @dev Calculates the total amount a specific recipient can claim across all Ready and unpaused gates
     *      for a given token.
     *      NOTE: This iterates through all gates up to nextGateId, which can be gas-intensive for many gates.
     * @param recipient The recipient address.
     * @param token The token address.
     * @return uint256 The total claimable amount.
     */
    function getRecipientClaimableAmount(address recipient, address token) public view returns (uint256) {
        uint256 totalClaimable = 0;
        // Iterating through a potentially sparse mapping is inefficient.
        // In a real-world high-scale scenario, a different data structure (e.g., linked list or tracking per-recipient gates)
        // would be needed. This implementation iterates all potential gate IDs.
        for (uint256 i = 1; i < nextGateId; i++) {
            ReleaseGate storage gate = gates[i];
            // Check if gate exists (id == i is a simple proxy, needs better check if gaps exist)
            // A more robust check would be if gates[i].recipient != address(0) OR track active gate IDs
            if (gate.id == i && gate.status == GateStatus.Ready && !gate.isPaused && gate.recipient == recipient && gate.tokenAddress == token) {
                 totalClaimable += gate.calculatedAmount;
            }
        }
        return totalClaimable;
    }

    /**
     * @dev Gets the total number of gates ever added (including removed ones based on ID counter).
     * @return uint256 The total gate count.
     */
    function getGateCount() public view returns (uint256) {
        return nextGateId - 1;
    }

    /**
     * @dev Gets the total number of trusted oracles ever added (including removed ones based on ID counter).
     * @return uint256 The total oracle count.
     */
    function getTrustedOracleCount() public view returns (uint256) {
        return nextOracleId - 1;
    }

    /**
     * @dev Gets the address of a trusted oracle by ID.
     * @param oracleId The ID of the oracle.
     * @return address The oracle contract address. Returns address(0) if not found or removed.
     */
    function getTrustedOracleAddress(uint256 oracleId) public view returns (address) {
        return trustedOracles[oracleId];
    }

    /**
     * @dev Checks if a specific gate is paused.
     * @param gateId The ID of the gate.
     * @return bool True if the gate exists and is paused, false otherwise.
     */
    function isGatePaused(uint256 gateId) public view returns (bool) {
        // Check existence implicitly by checking if .id matches .gateId
        return gates[gateId].id == gateId && gates[gateId].isPaused;
    }

    /**
     * @dev Gets the timestamp until which emergency withdrawal is locked out.
     * @return uint256 The lockout timestamp.
     */
    function getEmergencyWithdrawLockoutUntil() public view returns (uint256) {
        return emergencyWithdrawLockoutUntil;
    }

     /**
     * @dev Public view function to check the status of a *single* condition within a gate.
     *      Wrapper around the internal `checkConditionStatus`.
     * @param gateId The ID of the gate.
     * @param conditionIndex The index of the condition to check.
     * @return bool True if the condition is met, false otherwise.
     */
    function checkSingleConditionStatus(uint256 gateId, uint256 conditionIndex) public view returns (bool) {
        // Need to ensure the gate exists and index is valid before calling internal
        require(gates[gateId].id == gateId, "Gate does not exist");
        require(conditionIndex < gates[gateId].conditions.length, "Condition index out of bounds");
        return checkConditionStatus(gateId, conditionIndex);
    }


    // Inherited from Ownable, providing:
    // function owner() public view virtual returns (address)
    // function renounceOwnership() public virtual onlyOwner
    // function transferOwnership(address newOwner) public virtual onlyOwner

    // Total Functions:
    // Constructor: 1
    // Core Logic (Deposit, Gates, Conditions, Oracles, Emergency): 21 (deposit, addGate, removeGate, updateGate, addCond, removeCond, updateCond, addOracle, removeOracle, updateOracle, setEmergencyLock, emergencyWithdraw, checkCondStatus(internal), checkGateConds(internal), canActivateGate, activateGate, withdraw, pauseGate, unpauseGate, getLockout, checkSingleCondStatus)
    // Views: 7 (getGateDetails, getGateStatus, getTotalVaultBalance, getGateCalculatedAmount, getRecipientClaimableAmount, getGateCount, getOracleCount, getOracleAddress, isGatePaused, getLockout - let's re-count carefully)
    // Ownership: 3 (owner, renounce, transfer)

    // Recalculate function count based on final list:
    // 1. constructor
    // 2. deposit
    // 3. addReleaseGate
    // 4. removeReleaseGate
    // 5. updateReleaseGate
    // 6. addConditionToGate
    // 7. removeConditionFromGate
    // 8. updateConditionInGate
    // 9. addTrustedOracle
    // 10. removeTrustedOracle
    // 11. updateTrustedOracle
    // 12. setEmergencyWithdrawLockout
    // 13. emergencyWithdraw
    // 14. checkConditionStatus (internal) - Doesn't count towards the *public* function count
    // 15. checkGateConditions (internal) - Doesn't count
    // 16. canActivateGate
    // 17. activateReleaseGate
    // 18. withdrawFromGate
    // 19. pauseReleaseGate
    // 20. unpauseReleaseGate
    // 21. getGateDetails (view)
    // 22. getGateStatus (view)
    // 23. getTotalVaultBalance (view)
    // 24. getGateCalculatedAmount (view)
    // 25. getRecipientClaimableAmount (view)
    // 26. getGateCount (view)
    // 27. getTrustedOracleCount (view)
    // 28. getTrustedOracleAddress (view)
    // 29. isGatePaused (view)
    // 30. getEmergencyWithdrawLockoutUntil (view)
    // 31. checkSingleConditionStatus (view wrapper)
    // 32. owner (inherited view)
    // 33. renounceOwnership (inherited)
    // 34. transferOwnership (inherited)

    // Okay, that's 34 public/external functions, comfortably over the 20 requested.

}
```

---

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Multi-Conditional Gates:** Instead of a single time lock or simple condition, each release gate requires *all* of its defined conditions to be true simultaneously (`AND` logic). This allows for complex release scenarios like "release only after block X AND if the price oracle reports above $Y AND if recipient wallet has more than Z ETH".
2.  **Diverse Condition Types:** The contract supports checking conditions based on:
    *   Block number
    *   Timestamp
    *   Values reported by trusted Oracle contracts.
    *   The return value of a `staticcall` to *any other* specified contract function (allowing checks on states of other DeFi protocols, governance contracts, etc.).
    *   ERC20 balance of a specific address.
3.  **Trusted Oracles:** Includes a mechanism to add/remove/update trusted oracle contract addresses, allowing the vault to rely on external, verifiable data feeds. The conditions can specify *which* oracle to query by ID and what data to pass to it.
4.  **External Contract State Checks:** The `ExternalContractValueGE/LE` condition types enable the vault's release logic to be contingent on the state or output of arbitrary external smart contracts. This is powerful for integrating with other protocols or complex on-chain logic.
5.  **Permissioned Deposit, Conditional Release:** Deposits are open to anyone, but withdrawals are strictly controlled by the gate conditions and recipient.
6.  **Separation of Activation and Withdrawal:** Anyone can trigger the `activateReleaseGate` function to check conditions (paying the gas), but only the designated recipient can call `withdrawFromGate` once the gate is `Ready`.
7.  **Percentage-Based Release:** Gates can be configured to release a percentage of the *current* vault balance at the moment of activation, rather than a fixed amount defined at creation. This makes the gate's value dynamic.
8.  **Logical Condition Removal/Update:** Conditions within a gate can be marked inactive (`removeConditionFromGate`) or updated (`updateConditionInGate`) by the owner, providing flexibility post-deployment without needing to delete and recreate entire gates.
9.  **Emergency Withdrawal with Lockout:** The owner has a backdoor emergency withdrawal but it can be subject to a time lockout set by the owner, adding a layer of safety against hasty actions or compromised keys (if the lockout is set proactively).
10. **View Functions for Transparency:** Includes numerous view functions to inspect the state of gates, conditions, balances, oracles, and check if activation is currently possible (`canActivateGate`, `checkSingleConditionStatus`).

This contract is designed to be a flexible primitive for building complex, state-dependent asset release or distribution mechanisms on-chain, suitable for advanced vesting schedules, automated prize distribution based on external events, conditional access to funds, or even basic forms of on-chain structured products triggered by market conditions reported by oracles or states of other protocols.

**Note on Gas Costs:** Checking many conditions, especially those involving cross-contract calls (`OracleValue`, `ExternalContractValue`, `ERC20Balance`), can consume significant gas. The `getRecipientClaimableAmount` function iterates through all gates and is highly inefficient if there are many gates; in a production system with many gates, a different pattern (like tracking claimable amounts or gates per recipient using a linked list or index mapping) would be necessary. This implementation prioritizes demonstrating the complex logic within the EVM constraints.