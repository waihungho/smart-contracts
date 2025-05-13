Okay, let's design a smart contract called `QuantumVault`. The core idea is a token vault where withdrawal access, fees, and maybe even yield are determined by the contract's internal "Quantum State" and external/time-based "Quantum Conditions". This moves beyond simple time locks or fixed rates, introducing dynamic complexity.

We'll use concepts like:
1.  **Dynamic States:** The vault transitions through different states (e.g., 'Stable', 'Fluctuating', 'Entangled', 'Decaying'), affecting rules.
2.  **Complex Conditions:** State transitions and withdrawal eligibility depend on meeting multiple, potentially interacting conditions (time elapsed, external triggers, internal metrics).
3.  **State-Dependent Logic:** Withdrawal fees, potentially withdrawal limits, and required conditions change based on the current vault state.
4.  **Oracle/Signaler Integration:** Allowing trusted external entities to trigger 'external' conditions.
5.  **Emergency Bypass:** An admin function to override conditions in emergencies.
6.  **User-Specific State:** While the vault has a global state, user withdrawal checks depend on their individual deposit attributes (like age) *relative to* the current global state's requirements.

This provides over 20 functions covering deposits, withdrawals, state management, condition management, fee handling, access control, and information retrieval.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title QuantumVault
 * @dev An advanced token vault with dynamic states, conditional access, and state-dependent fees.
 * Access and state transitions are governed by configurable 'Quantum Conditions'.
 *
 * Outline:
 * 1. State Variables: Contract configuration, states, conditions, user data, fees.
 * 2. Enums & Structs: Define possible states, condition types, and data structures for deposits and conditions.
 * 3. Events: Announce key actions and state changes.
 * 4. Modifiers: Access control and state checks.
 * 5. Constructor: Initialize the contract.
 * 6. Core Vault Logic: Deposit and conditional Withdrawal functions.
 * 7. Quantum State Management: Functions for defining, activating, and triggering conditions, and managing state transitions.
 * 8. Fee Management: Functions for setting state-dependent fees and managing collected fees.
 * 9. Access Control & Security: Pausing, Emergency mode, Authorized signalers.
 * 10. Information Retrieval: View functions for querying contract state, user data, and rules.
 * 11. Internal Helpers: Logic for checking conditions and updating state.
 */

/**
 * Function Summary:
 *
 * Core Vault Logic:
 * 1. deposit(uint256 amount): Deposits tokens into the vault for the caller.
 * 2. withdraw(uint256 amount): Attempts to withdraw tokens. Requires satisfying conditions for the current vault state.
 *
 * Quantum State & Condition Management:
 * 3. defineQuantumCondition(ConditionType _type, uint256 _value, bytes32 _identifier): Admin defines a new condition.
 * 4. updateQuantumCondition(bytes32 _identifier, ConditionType _type, uint256 _value): Admin updates an existing condition.
 * 5. activateQuantumCondition(bytes32 _identifier): Admin activates a defined condition, making it eligible for state transitions/withdrawal checks.
 * 6. deactivateQuantumCondition(bytes32 _identifier): Admin deactivates a condition.
 * 7. setVaultStateTransition(VaultState fromState, VaultState toState, bytes32[] requiredConditionIdentifiers): Admin defines conditions required to transition between states.
 * 8. setWithdrawalConditionsForState(VaultState state, bytes32[] requiredConditionIdentifiers): Admin defines conditions required for ANY withdrawal in a specific state.
 * 9. triggerExternalCondition(bytes32 _identifier): Authorized signaler triggers an external condition flag.
 * 10. updateVaultState(): Internal or Admin-called function to attempt transitioning state based on met conditions.
 *
 * Fee Management:
 * 11. setWithdrawalFeeRate(VaultState state, uint256 feeBasisPoints): Admin sets the withdrawal fee percentage (in basis points) for a state.
 * 12. getWithdrawalFeeRate(VaultState state): Get the fee rate for a state.
 * 13. withdrawCollectedFees(address recipient): Admin withdraws accumulated fees.
 *
 * Access Control & Security:
 * 14. pause(): Owner pauses the contract.
 * 15. unpause(): Owner unpauses the contract.
 * 16. initiateEmergencyWithdrawal(address recipient): Owner initiates emergency withdrawal of total vault balance to a recipient, bypassing conditions.
 * 17. cancelEmergencyWithdrawal(): Owner cancels ongoing emergency withdrawal (before initiation).
 * 18. addAuthorizedConditionSignaler(address signaler): Owner authorizes an address to trigger external conditions.
 * 19. removeAuthorizedConditionSignaler(address signaler): Owner removes authorization.
 *
 * Information Retrieval:
 * 20. getUserBalance(address user): Get user's total deposited balance.
 * 21. getTotalVaultBalance(): Get the total tokens held in the vault.
 * 22. getCurrentVaultState(): Get the current overall vault state.
 * 23. getUserDepositTimestamp(address user): Get the timestamp of the user's first deposit (simplified).
 * 24. getConditionDetails(bytes32 identifier): Get details of a defined condition.
 * 25. getConditionsRequiredForWithdrawal(VaultState state): Get the list of condition identifiers required for withdrawal in a specific state.
 * 26. checkUserWithdrawalEligibility(address user, uint256 amount): Checks if withdrawal conditions are currently met for a user and amount. (View function)
 * 27. getCollectedFees(): Get the total collected fees in the vault.
 *
 * (Note: Some internal helper functions like _checkConditionMet, _calculateWithdrawalFee also exist but are not exposed publicly)
 */
contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---
    IERC20 public supportedToken;
    uint256 public totalVaultBalance;
    uint256 public collectedFees;

    // User data (simplified: single timestamp per user for deposit age check)
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public userDepositTimestamps; // Timestamp of the first deposit

    // Quantum State Management
    enum VaultState { Initial, Phase1, Phase2, Entangled, Decaying, Stable, Emergency }
    VaultState public currentVaultState;

    enum ConditionType {
        TimeElapsedSinceDeposit, // uint256 value is minimum seconds
        TimeElapsedSinceStateEntry, // uint256 value is minimum seconds
        MinimumTotalVaultBalance, // uint256 value is minimum balance
        MinimumUserDepositCount, // uint256 value is minimum number of depositors
        ExternalTrigger // uint256 value is ignored, condition set externally
    }

    struct QuantumCondition {
        ConditionType conditionType;
        uint256 value;
        bool isActive;
        bool isMet; // For ExternalTrigger type
    }

    // Mapping of condition identifier (bytes32) to its details
    mapping(bytes32 => QuantumCondition) public quantumConditions;
    // List of all defined condition identifiers
    bytes32[] public definedConditionIdentifiers;

    // Mapping: fromState => toState => requiredConditionIdentifiers
    mapping(VaultState => mapping(VaultState => bytes32[])) public stateTransitions;

    // Mapping: state => requiredConditionIdentifiers for withdrawal
    mapping(VaultState => bytes32[]) public withdrawalConditions;

    // Mapping: state => withdrawal fee rate in basis points (100 = 1%)
    mapping(VaultState => uint256) public withdrawalFeeRates;

    // Authorized addresses that can trigger external conditions
    mapping(address => bool) public authorizedConditionSignalers;

    bool public emergencyWithdrawalActive = false;
    address public emergencyWithdrawalRecipient;

    // --- Events ---
    event Deposited(address indexed user, uint256 amount);
    event Withdrew(address indexed user, uint256 amount, uint256 fee);
    event VaultStateTransitioned(VaultState indexed oldState, VaultState indexed newState, uint256 timestamp);
    event ConditionDefined(bytes32 indexed identifier, ConditionType conditionType, uint256 value);
    event ConditionUpdated(bytes32 indexed identifier, ConditionType conditionType, uint256 value);
    event ConditionActivationChanged(bytes32 indexed identifier, bool isActive);
    event ExternalConditionTriggered(bytes32 indexed identifier, uint256 timestamp);
    event WithdrawalFeeRateUpdated(VaultState indexed state, uint256 feeBasisPoints);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event EmergencyWithdrawalInitiated(address indexed recipient, uint256 timestamp);
    event EmergencyWithdrawalCancelled(uint256 timestamp);
    event AuthorizedSignalerUpdated(address indexed signaler, bool authorized);
    event VaultPaused(address account);
    event VaultUnpaused(address account);

    // --- Modifiers ---
    modifier onlyAuthorizedSignaler() {
        require(authorizedConditionSignalers[msg.sender], "QuantumVault: Not authorized signaler");
        _;
    }

    // --- Constructor ---
    constructor(address _supportedTokenAddress) Ownable(msg.sender) {
        supportedToken = IERC20(_supportedTokenAddress);
        currentVaultState = VaultState.Initial;
        _defineInitialStatesAndConditions(); // Helper to set up initial state/conditions
        emit VaultStateTransitioned(VaultState.Initial, VaultState.Initial, block.timestamp);
    }

    // --- Core Vault Logic ---

    /**
     * @dev Deposits tokens into the vault.
     * User's first deposit timestamp is recorded.
     */
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "QuantumVault: Amount must be > 0");

        if (userBalances[msg.sender] == 0) {
            userDepositTimestamps[msg.sender] = block.timestamp;
        }

        userBalances[msg.sender] += amount;
        totalVaultBalance += amount;
        supportedToken.safeTransferFrom(msg.sender, address(this), amount);

        _updateVaultState(); // Attempt state transition after deposit

        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Attempts to withdraw tokens. Checks if withdrawal conditions for the current state are met.
     * Calculates and applies withdrawal fee.
     */
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(userBalances[msg.sender] >= amount, "QuantumVault: Insufficient balance");
        require(!emergencyWithdrawalActive, "QuantumVault: Emergency withdrawal is active");

        // Check if withdrawal is allowed in the current state
        require(_checkWithdrawalConditions(msg.sender, amount), "QuantumVault: Withdrawal conditions not met");

        uint256 fee = _calculateWithdrawalFee(amount);
        uint256 amountToSend = amount - fee;

        userBalances[msg.sender] -= amount;
        totalVaultBalance -= amount;
        collectedFees += fee;

        supportedToken.safeTransfer(msg.sender, amountToSend);

        _updateVaultState(); // Attempt state transition after withdrawal

        emit Withdrew(msg.sender, amountToSend, fee);
    }

    // --- Quantum State & Condition Management ---

    /**
     * @dev Admin defines a new quantum condition. Requires a unique identifier.
     * @param _type The type of condition.
     * @param _value The value associated with the condition (e.g., time in seconds, minimum balance).
     * @param _identifier A unique identifier for this condition (e.g., keccak256("min_deposit_age_1y")).
     */
    function defineQuantumCondition(ConditionType _type, uint256 _value, bytes32 _identifier) external onlyOwner {
        require(quantumConditions[_identifier].conditionType == ConditionType.TimeElapsedSinceDeposit || _identifier == bytes32(0), "QuantumVault: Condition identifier already exists");
        // Use TimeElapsedSinceDeposit default value check, as bytes32(0) is the default for unset mappings

        quantumConditions[_identifier] = QuantumCondition({
            conditionType: _type,
            value: _value,
            isActive: false,
            isMet: false // Only relevant for ExternalTrigger, initial state is false
        });
        definedConditionIdentifiers.push(_identifier);
        emit ConditionDefined(_identifier, _type, _value);
    }

     /**
     * @dev Admin updates an existing quantum condition.
     * @param _identifier The unique identifier for the condition.
     * @param _type The new type of condition.
     * @param _value The new value associated with the condition.
     */
    function updateQuantumCondition(bytes32 _identifier, ConditionType _type, uint256 _value) external onlyOwner {
         require(quantumConditions[_identifier].conditionType != ConditionType.TimeElapsedSinceDeposit || _identifier != bytes32(0), "QuantumVault: Condition identifier does not exist");
         // Check if identifier exists using the same logic as define

         QuantumCondition storage condition = quantumConditions[_identifier];
         condition.conditionType = _type;
         condition.value = _value;
         // isMet for ExternalTrigger is reset on update as the nature of the trigger might change
         if (_type == ConditionType.ExternalTrigger) {
             condition.isMet = false;
         }

         emit ConditionUpdated(_identifier, _type, _value);
    }

    /**
     * @dev Admin activates a defined condition. Active conditions can be used in state transitions or withdrawal rules.
     * @param _identifier The identifier of the condition to activate.
     */
    function activateQuantumCondition(bytes32 _identifier) external onlyOwner {
         require(quantumConditions[_identifier].conditionType != ConditionType.TimeElapsedSinceDeposit || _identifier != bytes32(0), "QuantumVault: Condition does not exist");
         quantumConditions[_identifier].isActive = true;
         emit ConditionActivationChanged(_identifier, true);
    }

     /**
     * @dev Admin deactivates a condition. Deactivated conditions are ignored for state transitions and withdrawal rules.
     * @param _identifier The identifier of the condition to deactivate.
     */
    function deactivateQuantumCondition(bytes32 _identifier) external onlyOwner {
         require(quantumConditions[_identifier].conditionType != ConditionType.TimeElapsedSinceDeposit || _identifier != bytes32(0), "QuantumVault: Condition does not exist");
         quantumConditions[_identifier].isActive = false;
         // If it was an external trigger that was met, reset it on deactivation
         if (quantumConditions[_identifier].conditionType == ConditionType.ExternalTrigger) {
             quantumConditions[_identifier].isMet = false;
         }
         emit ConditionActivationChanged(_identifier, false);
    }

    /**
     * @dev Admin defines the conditions required to transition from one state to another.
     * Requires all specified conditions to be active and met.
     * @param fromState The state to transition from.
     * @param toState The state to transition to.
     * @param requiredConditionIdentifiers Array of condition identifiers.
     */
    function setVaultStateTransition(VaultState fromState, VaultState toState, bytes32[] calldata requiredConditionIdentifiers) external onlyOwner {
        // Basic validation (more robust checks for valid states/identifiers possible)
        require(uint8(fromState) < uint8(VaultState.Emergency), "QuantumVault: Cannot set transition from Emergency state");
        require(uint8(toState) < uint8(VaultState.Emergency), "QuantumVault: Cannot set transition to Emergency state directly");

        stateTransitions[fromState][toState] = requiredConditionIdentifiers;
        // Event for this is not strictly necessary for every rule update, but possible.
    }

    /**
     * @dev Admin defines the conditions required for a user to withdraw any amount while the vault is in a specific state.
     * Requires all specified conditions to be active and met for the user's deposit.
     * @param state The state for which to set withdrawal conditions.
     * @param requiredConditionIdentifiers Array of condition identifiers.
     */
    function setWithdrawalConditionsForState(VaultState state, bytes32[] calldata requiredConditionIdentifiers) external onlyOwner {
         require(uint8(state) < uint8(VaultState.Emergency), "QuantumVault: Cannot set withdrawal conditions for Emergency state");
         withdrawalConditions[state] = requiredConditionIdentifiers;
         // Event not strictly necessary, but possible.
    }


    /**
     * @dev Allows an authorized signaler to trigger an 'ExternalTrigger' type condition.
     * This sets the `isMet` flag for that specific condition identifier.
     * @param _identifier The identifier of the ExternalTrigger condition to trigger.
     */
    function triggerExternalCondition(bytes32 _identifier) external onlyAuthorizedSignaler whenNotPaused {
        QuantumCondition storage condition = quantumConditions[_identifier];
        require(condition.conditionType == ConditionType.ExternalTrigger, "QuantumVault: Not an external trigger condition");
        require(condition.isActive, "QuantumVault: Condition is not active");
        require(!condition.isMet, "QuantumVault: Condition already met");

        condition.isMet = true;
        _updateVaultState(); // Attempt state transition after condition is met
        emit ExternalConditionTriggered(_identifier, block.timestamp);
    }

     /**
     * @dev Internal or Admin-called function to check if any defined state transitions
     * from the current state are possible based on currently met active conditions,
     * and executes the first valid transition found.
     */
    function updateVaultState() public { // Made public to allow Admin manual trigger if needed, otherwise internal
        if (currentVaultState == VaultState.Emergency) {
            return; // No transitions out of emergency except cancellation
        }

        // Iterate through possible next states from current state
        for (uint8 i = 0; i < uint8(VaultState.Emergency); i++) { // Iterate through all potential target states (excluding Emergency)
             VaultState potentialNextState = VaultState(i);
             if (potentialNextState == currentVaultState) continue; // Skip transition to same state

             bytes32[] storage required = stateTransitions[currentVaultState][potentialNextState];

             if (required.length > 0) { // Check if a transition rule is defined
                 bool allConditionsMet = true;
                 for (uint j = 0; j < required.length; j++) {
                     bytes32 conditionId = required[j];
                     if (!quantumConditions[conditionId].isActive || !_checkConditionMet(conditionId, address(0), 0)) {
                         // Pass address(0) and 0 as user context is not needed for state transitions based on global conditions
                         allConditionsMet = false;
                         break;
                     }
                 }

                 if (allConditionsMet) {
                     VaultState oldState = currentVaultState;
                     currentVaultState = potentialNextState;
                     emit VaultStateTransitioned(oldState, currentVaultState, block.timestamp);

                     // Reset ExternalTrigger conditions after a successful transition if needed
                     // (This is a design choice - whether conditions reset or persist)
                     // For simplicity, we'll assume external triggers used in the transition stay 'met' unless manually reset/deactivated.
                     // If they should reset, add logic here to set condition.isMet = false for relevant types.

                     // Recursively check if further transitions are possible immediately
                     // (Careful with deep recursion, but states should progress logically)
                     updateVaultState();
                     return; // Transition happened, exit
                 }
             }
         }
    }

    // --- Fee Management ---

    /**
     * @dev Admin sets the withdrawal fee rate for a specific vault state.
     * Rate is in basis points (e.g., 100 = 1%, 0 = 0%). Max 10000 (100%).
     * @param state The state for which to set the fee.
     * @param feeBasisPoints The fee rate in basis points.
     */
    function setWithdrawalFeeRate(VaultState state, uint256 feeBasisPoints) external onlyOwner {
        require(feeBasisPoints <= 10000, "QuantumVault: Fee rate cannot exceed 100%");
         require(uint8(state) < uint8(VaultState.Emergency), "QuantumVault: Cannot set fee for Emergency state");
        withdrawalFeeRates[state] = feeBasisPoints;
        emit WithdrawalFeeRateUpdated(state, feeBasisPoints);
    }

    /**
     * @dev Internal helper function to calculate withdrawal fee based on current state.
     * @param amount The amount being withdrawn.
     * @return The calculated fee amount.
     */
    function _calculateWithdrawalFee(uint255 amount) internal view returns (uint255) {
        uint256 feeRate = withdrawalFeeRates[currentVaultState];
        return (amount * feeRate) / 10000;
    }

     /**
     * @dev Admin withdraws accumulated fees to a specified recipient.
     * @param recipient The address to receive the fees.
     */
    function withdrawCollectedFees(address recipient) external onlyOwner {
        require(collectedFees > 0, "QuantumVault: No fees collected");
        uint256 amount = collectedFees;
        collectedFees = 0;
        supportedToken.safeTransfer(recipient, amount);
        emit FeesWithdrawn(recipient, amount);
    }

    // --- Access Control & Security ---

    /**
     * @dev Pauses the contract. Only owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit VaultPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit VaultUnpaused(msg.sender);
    }

    /**
     * @dev Owner can initiate an emergency withdrawal of the entire vault balance.
     * This bypasses all conditions and sends funds to a specified recipient.
     * Enters Emergency state.
     * @param recipient The address to receive all tokens.
     */
    function initiateEmergencyWithdrawal(address recipient) external onlyOwner {
        require(!emergencyWithdrawalActive, "QuantumVault: Emergency withdrawal already active");
        require(address(supportedToken).balance >= totalVaultBalance, "QuantumVault: Token balance mismatch"); // Safety check

        emergencyWithdrawalActive = true;
        emergencyWithdrawalRecipient = recipient;
        // Change state directly to Emergency
        VaultState oldState = currentVaultState;
        currentVaultState = VaultState.Emergency;
        emit VaultStateTransitioned(oldState, currentVaultState, block.timestamp);
        emit EmergencyWithdrawalInitiated(recipient, block.timestamp);

        // Perform the transfer
        uint256 totalAmount = address(supportedToken).balance; // Transfer actual balance in case of discrepancies
        totalVaultBalance = 0; // Reset internal tracking
        collectedFees = 0; // Fees are part of the total balance

        // Note: User balances mapping is NOT cleared here. This contract assumes user balances
        // represent their *claim* based on deposits, not necessarily the actual token amount
        // after an emergency withdrawal. A more complex design might handle residual claims.

        supportedToken.safeTransfer(recipient, totalAmount);
    }

     /**
     * @dev Owner can cancel the emergency withdrawal state if it was initiated
     * but the actual transfer hasn't happened (e.g., if transfer logic was separate).
     * IMPORTANT: In this implementation, initiateEmergencyWithdrawal performs the transfer immediately.
     * This function is mostly a state cleanup mechanism if the initiation failed halfway or was designed differently.
     * It would require re-setting balances/state carefully if tokens weren't actually transferred.
     * Given the current implementation, calling this *after* initiateEmergencyWithdrawal has transferred tokens is ill-advised
     * as it would put the contract in a state where totalVaultBalance is 0 but userBalances > 0.
     * Consider this primarily for a model where initiation only sets a flag and transfer is a separate step.
     */
    function cancelEmergencyWithdrawal() external onlyOwner {
        require(emergencyWithdrawalActive, "QuantumVault: Emergency withdrawal not active");
        // Revert state - dangerous, requires careful handling if tokens were transferred.
        // In this simple model, assume tokens *weren't* sent if this is called.
        // If they were sent, manual state cleanup or a different design is needed.
        emergencyWithdrawalActive = false;
        emergencyWithdrawalRecipient = address(0);
        // Decide which state to revert to. Initial? Previous? Complex.
        // For simplicity, revert to Initial.
        VaultState oldState = currentVaultState;
        currentVaultState = VaultState.Initial; // Revert to a safe, defined state
        emit VaultStateTransitioned(oldState, currentVaultState, block.timestamp);
        emit EmergencyWithdrawalCancelled(block.timestamp);

        // WARNING: If initiateEmergencyWithdrawal *did* send tokens,
        // totalVaultBalance will be 0, but userBalances will be non-zero.
        // A robust contract would need a recovery mechanism or prevent this call post-transfer.
    }


    /**
     * @dev Owner authorizes an address to trigger conditions of type ExternalTrigger.
     * @param signaler The address to authorize.
     */
    function addAuthorizedConditionSignaler(address signaler) external onlyOwner {
        require(signaler != address(0), "QuantumVault: Zero address not allowed");
        authorizedConditionSignalers[signaler] = true;
        emit AuthorizedSignalerUpdated(signaler, true);
    }

    /**
     * @dev Owner removes authorization from a signaler.
     * @param signaler The address to remove authorization from.
     */
    function removeAuthorizedConditionSignaler(address signaler) external onlyOwner {
        authorizedConditionSignalers[signaler] = false;
        emit AuthorizedSignalerUpdated(signaler, false);
    }


    // --- Information Retrieval (View Functions) ---

    /**
     * @dev Gets the total deposited balance for a user.
     */
    function getUserBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    /**
     * @dev Gets the total tokens held in the vault contract's address.
     * Note: This might differ slightly from totalVaultBalance if fees are collected
     * or due to token specifics, but should be close in a well-behaved ERC20.
     */
    function getTotalVaultBalance() external view returns (uint256) {
        // For simplicity, return the internally tracked balance.
        // returning supportedToken.balanceOf(address(this)) might be more accurate but could include fees.
        return totalVaultBalance;
    }

    /**
     * @dev Gets the current overall quantum state of the vault.
     */
    function getCurrentVaultState() external view returns (VaultState) {
        return currentVaultState;
    }

    /**
     * @dev Gets the timestamp of the user's first deposit.
     * Useful for TimeElapsedSinceDeposit condition checks.
     */
    function getUserDepositTimestamp(address user) external view returns (uint256) {
        return userDepositTimestamps[user];
    }

    /**
     * @dev Gets the details of a defined quantum condition.
     * @param identifier The identifier of the condition.
     * @return conditionType The type of condition.
     * @return value The value associated with the condition.
     * @return isActive Whether the condition is currently active.
     * @return isMet Whether the condition is currently met (primarily for ExternalTrigger).
     */
    function getConditionDetails(bytes32 identifier) external view returns (ConditionType conditionType, uint256 value, bool isActive, bool isMet) {
        QuantumCondition storage condition = quantumConditions[identifier];
        require(condition.conditionType != ConditionType.TimeElapsedSinceDeposit || identifier != bytes32(0), "QuantumVault: Condition does not exist");
        return (condition.conditionType, condition.value, condition.isActive, condition.isMet);
    }

    /**
     * @dev Gets the list of condition identifiers required for withdrawal in a specific state.
     * @param state The vault state to query.
     * @return Array of required condition identifiers.
     */
    function getConditionsRequiredForWithdrawal(VaultState state) external view returns (bytes32[] memory) {
        return withdrawalConditions[state];
    }

     /**
     * @dev Checks if withdrawal conditions are currently met for a user and a potential amount.
     * Does NOT perform the withdrawal. Useful for UI.
     * @param user The address of the user.
     * @param amount The potential amount to withdraw (used for balance checks).
     * @return bool True if conditions are met, false otherwise.
     */
    function checkUserWithdrawalEligibility(address user, uint256 amount) external view returns (bool) {
         if (userBalances[user] < amount || amount == 0 || paused() || emergencyWithdrawalActive) {
             return false;
         }
         // Internal helper already performs all necessary checks based on state and user data
         return _checkWithdrawalConditions(user, amount);
    }

     /**
     * @dev Gets the current withdrawal fee rate for a specific state.
     * @param state The vault state to query.
     * @return The fee rate in basis points.
     */
    function getFeeRateForState(VaultState state) external view returns (uint256) {
        return withdrawalFeeRates[state];
    }

     /**
     * @dev Gets the total accumulated fees waiting to be withdrawn by the owner.
     */
    function getCollectedFees() external view returns (uint256) {
        return collectedFees;
    }

    /**
     * @dev Gets the list of all defined condition identifiers.
     */
    function getDefinedConditionIdentifiers() external view returns (bytes32[] memory) {
        return definedConditionIdentifiers;
    }

    /**
     * @dev Internal helper to check if a specific condition is met.
     * Contextual info like user address and amount is needed for some condition types.
     * @param identifier The identifier of the condition to check.
     * @param user The user address (relevant for user-specific conditions). address(0) if not applicable.
     * @param amount The withdrawal amount (relevant for balance/amount checks). 0 if not applicable.
     * @return bool True if the condition is met, false otherwise or if inactive.
     */
    function _checkConditionMet(bytes32 identifier, address user, uint256 amount) internal view returns (bool) {
        QuantumCondition storage condition = quantumConditions[identifier];
        if (!condition.isActive) {
            return false; // Inactive conditions are never met
        }

        unchecked { // Safe due to nature of condition types and comparison
            if (condition.conditionType == ConditionType.TimeElapsedSinceDeposit) {
                require(user != address(0), "QuantumVault: User context required for TimeElapsedSinceDeposit");
                uint256 depositTimestamp = userDepositTimestamps[user];
                // Condition met if deposit was made AND enough time has passed
                return depositTimestamp > 0 && block.timestamp - depositTimestamp >= condition.value;
            } else if (condition.conditionType == ConditionType.TimeElapsedSinceStateEntry) {
                 // This would require storing entry timestamp for each state, which adds complexity.
                 // For simplicity, let's assume block.timestamp for now, or require an admin call to mark state entry time.
                 // A robust version needs `mapping(VaultState => uint256) stateEntryTimestamps;` and update it in `updateVaultState`.
                 // For *this* implementation, we'll make this condition type always false unless stateEntryTimestamps is added.
                 // TODO: Implement stateEntryTimestamps for real TimeElapsedSinceStateEntry logic.
                 // For now, returning false for this type.
                 return false; // Simplified: Condition never met with current info
            } else if (condition.conditionType == ConditionType.MinimumTotalVaultBalance) {
                return totalVaultBalance >= condition.value;
            } else if (condition.conditionType == ConditionType.MinimumUserDepositCount) {
                 // This requires tracking the number of distinct depositors, which adds complexity.
                 // For simplicity, we'll make this condition type always false unless distinct user counting is added.
                 // TODO: Implement distinct user counting for real MinimumUserDepositCount logic.
                 // For now, returning false for this type.
                 return false; // Simplified: Condition never met with current info
            } else if (condition.conditionType == ConditionType.ExternalTrigger) {
                return condition.isMet; // Met if the authorized signaler has triggered it
            } else {
                return false; // Unknown condition type
            }
        }
    }

    /**
     * @dev Internal helper to check if all withdrawal conditions for the current state are met for a user.
     * @param user The user address attempting withdrawal.
     * @param amount The amount user is attempting to withdraw.
     * @return bool True if all required conditions are met.
     */
    function _checkWithdrawalConditions(address user, uint256 amount) internal view returns (bool) {
        bytes32[] storage required = withdrawalConditions[currentVaultState];

        if (required.length == 0) {
            // If no conditions are set for this state, withdrawal is allowed based on state alone
            // (This implies owner must set rules, otherwise withdrawal is impossible)
            return true;
        }

        for (uint i = 0; i < required.length; i++) {
            bytes32 conditionId = required[i];
            // All required conditions must be active AND met
            if (!quantumConditions[conditionId].isActive || !_checkConditionMet(conditionId, user, amount)) {
                return false; // As soon as one condition is not met, return false
            }
        }

        return true; // All required and active conditions were met
    }

    /**
     * @dev Helper function called in constructor to define some initial states and conditions.
     * This is just example setup. Admin can redefine later.
     */
    function _defineInitialStatesAndConditions() private {
         // Define conditions (example identifiers)
         bytes32 condition_MinAge1Year = keccak256("MinAge1Year");
         defineQuantumCondition(ConditionType.TimeElapsedSinceDeposit, 365 days, condition_MinAge1Year);

         bytes32 condition_MinVaultBalance1000 = keccak256("MinVaultBalance1000");
         defineQuantumCondition(ConditionType.MinimumTotalVaultBalance, 1000 ether, condition_MinVaultBalance1000); // Assuming 18 decimals

         bytes32 condition_ExternalEventA = keccak256("ExternalEventA");
         defineQuantumCondition(ConditionType.ExternalTrigger, 0, condition_ExternalEventA); // Value ignored for ExternalTrigger

         // Activate some conditions initially
         activateQuantumCondition(condition_MinAge1Year);
         activateQuantumCondition(condition_MinVaultBalance1000);
         activateQuantumCondition(condition_ExternalEventA);

         // Set initial state transitions (example rules)
         // Initial -> Phase1 requires MinVaultBalance1000
         bytes32[] memory reqForPhase1 = new bytes32[](1);
         reqForPhase1[0] = condition_MinVaultBalance1000;
         setVaultStateTransition(VaultState.Initial, VaultState.Phase1, reqForPhase1);

         // Phase1 -> Stable requires ExternalEventA
         bytes32[] memory reqForStable = new bytes32[](1);
         reqForStable[0] = condition_ExternalEventA;
         setVaultStateTransition(VaultState.Phase1, VaultState.Stable, reqForStable);

         // Set withdrawal conditions per state (example rules)
         // In Initial state, withdrawal is allowed only if MinVaultBalance1000 is NOT met (e.g., early exit) - needs inverse logic or separate condition set
         // Simpler: In Initial state, withdrawal requires NO conditions.
         bytes32[] memory noConditions = new bytes32[](0);
         setWithdrawalConditionsForState(VaultState.Initial, noConditions);

         // In Phase1 state, withdrawal requires MinAge1Year
         bytes32[] memory reqWithdrawPhase1 = new bytes32[](1);
         reqWithdrawPhase1[0] = condition_MinAge1Year;
         setWithdrawalConditionsForState(VaultState.Phase1, reqWithdrawPhase1);

         // In Stable state, withdrawal requires both MinAge1Year and ExternalEventA met
         bytes32[] memory reqWithdrawStable = new bytes32[](2);
         reqWithdrawStable[0] = condition_MinAge1Year;
         reqWithdrawStable[1] = condition_ExternalEventA;
         setWithdrawalConditionsForState(VaultState.Stable, reqWithdrawStable);

         // Set initial fee rates (example)
         setWithdrawalFeeRate(VaultState.Initial, 500); // 5% fee in initial state
         setWithdrawalFeeRate(VaultState.Phase1, 200); // 2% fee in phase 1
         setWithdrawalFeeRate(VaultState.Stable, 50);  // 0.5% fee in stable state
         // Default fee for undefined states/Emergency is 0
    }
}
```

---

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic Quantum States (`VaultState` enum and transitions):** The contract isn't static. Its behavior changes based on its `currentVaultState`. This state transitions based on meeting predefined `QuantumCondition` sets. This creates a simple state machine within the contract.
2.  **Complex Quantum Conditions (`ConditionType`, `QuantumCondition` struct, `quantumConditions` mapping):** Conditions aren't just simple time locks. They can be based on:
    *   **Time Elapsed Since Deposit:** Standard, but combined with others.
    *   **Time Elapsed Since State Entry:** (Planned, requires more state tracking) Allows timing relative to contract events.
    *   **Minimum Total Vault Balance:** Links individual access/state transitions to the collective activity in the vault.
    *   **Minimum User Deposit Count:** (Planned, requires more state tracking) Links access/transitions to the community size.
    *   **External Trigger:** Crucially, allows off-chain events (via authorized oracles/signalers) to influence on-chain state and access. This introduces a controlled dependency on external data.
3.  **Condition Activation/Deactivation:** Conditions can be defined once and toggled on/off by the admin, allowing flexibility without redeploying condition logic.
4.  **State-Dependent Logic (`withdrawalConditions`, `withdrawalFeeRates` mappings):** Withdrawal rules (which conditions are required) and fees are not fixed but depend entirely on the current `VaultState`. This allows for complex, evolving tokenomics and access control (e.g., high fees/strict rules early, lower fees/lax rules later once certain conditions are met).
5.  **Oracle/Signaler Integration (`authorizedConditionSignalers`, `triggerExternalCondition`):** Explicitly supports trusted parties triggering events that influence the contract state and user access. This is a common pattern in DeFi/advanced contracts relying on external data feeds or events.
6.  **Separation of State Transition and Withdrawal Conditions:** The conditions required to *change* the vault's global state are separate from the conditions required for an *individual user* to withdraw in that state. This allows for scenarios where the vault state progresses even if not all users individually meet the conditions for withdrawal in the new state immediately.
7.  **Emergency Bypass (`initiateEmergencyWithdrawal`):** A necessary, though powerful, security feature to handle unforeseen circumstances, highlighting the responsibility of the owner in a complex system.
8.  **Abstraction via Identifiers:** Conditions are referenced by `bytes32` identifiers, allowing the underlying condition logic or values to be updated (`updateQuantumCondition`) without changing the state transition or withdrawal rules that reference them.

This contract structure provides a flexible framework for building dynamic, condition-governed vaults with behaviors that evolve over time and based on external factors, going beyond the scope of typical open-source time-lock or vesting contracts. It presents a more intricate model of interaction between users, contract state, and predefined rules influenced by external events.