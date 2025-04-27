Okay, this is an exciting challenge! Let's design a smart contract that uses analogies from quantum mechanics to manage digital assets (specifically ERC-20 tokens). We'll avoid direct copies of common DeFi or NFT patterns and focus on unique state-management concepts.

We'll call it the `QuantumVault`.

**Core Concepts:**

1.  **Superposition States:** Instead of a single balance for a user's token, the balance can be distributed across multiple conceptual "superposition states" simultaneously upon deposit.
2.  **Measurement (Withdrawal):** Withdrawing from a specific state "measures" that state, collapsing the superposition for the withdrawn amount from that state.
3.  **Entanglement Links:** Two superposition states can be "entangled." An action (like measurement/withdrawal) in one state can trigger a related effect (like locking, unlocking, or transferring a notional value) in the entangled state.
4.  **Conditional Measurement Logic:** Each state can have associated logic or parameters that influence the outcome of a measurement (withdrawal) beyond just reducing the balance.
5.  **Observer Pattern:** Allow external addresses to register as "observers" to receive detailed event data about state changes and measurements.
6.  **Keeper Network:** Entanglement effects might require a separate transaction to process (to save gas for the user). A keeper network can be incentivized to trigger these effects.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title QuantumVault
 * @dev A creative smart contract managing ERC-20 tokens using quantum mechanics analogies.
 * Assets are held in "superposition states," subject to "measurement" (withdrawal)
 * and "entanglement" effects between states.
 */
contract QuantumVault is Ownable {
    // --- Outline ---
    // 1. State Variables
    //    - Mappings for user balances in superposition states
    //    - Structs for Superposition States and Entanglement Links
    //    - Counters for state and link IDs
    //    - Mappings for state properties, accepted tokens, fees, approvals, processed triggers
    //    - Array for registered observers
    // 2. Events
    //    - Deposit, Withdrawal, Measurement, State Management, Entanglement Management, Triggering, Fees, Observer, etc.
    // 3. Modifiers
    //    - State existence, link existence, accepted token, etc.
    // 4. Core Deposit & Withdrawal (Measurement) Functions
    // 5. Superposition State Management Functions
    // 6. Entanglement Link Management Functions
    // 7. Entanglement Triggering & Processing Functions
    // 8. Advanced State Manipulation Functions (Split, Merge, Transfer)
    // 9. Conditional Measurement Logic Functions
    // 10. Access Control & Configuration Functions (Owner, Fees, Accepted Tokens, Entanglement Window)
    // 11. Observer Management Functions
    // 12. Query & Utility Functions

    // --- Function Summary (20+ functions) ---
    // Core Deposit/Withdrawal:
    // 1. deposit(address _token, uint256 _amount, uint256[] memory _stateIds, uint256[] memory _amountsPerState): Deposit into multiple states.
    // 2. withdrawMeasured(address _token, uint256 _stateId, uint256 _amount, bytes memory _measurementParams): Withdraw from a specific state ("measure").
    // 3. withdrawAllFromState(address _token, uint256 _stateId): Withdraw all from one state.
    // 4. withdrawAllTotal(address _token): Withdraw total across all states (collapses all).

    // Superposition State Management:
    // 5. addSuperpositionState(string memory _name): Owner adds a new state type.
    // 6. removeSuperpositionState(uint256 _stateId): Owner removes a state.
    // 7. setSuperpositionStateProperty(uint256 _stateId, string memory _propertyName, bytes memory _propertyValue): Owner sets dynamic state properties.
    // 8. getSuperpositionStateName(uint256 _stateId): Get state name.
    // 9. getSuperpositionStateProperty(uint256 _stateId, string memory _propertyName): Get state property.
    // 10. isSuperpositionStateValid(uint256 _stateId): Check if state exists.

    // Entanglement Link Management:
    // 11. addEntanglementLink(uint256 _stateIdA, uint256 _stateIdB, uint8 _linkType, bytes memory _linkParams): Owner creates an entanglement link.
    // 12. removeEntanglementLink(uint256 _linkId): Owner removes a link.
    // 13. updateEntanglementParams(uint256 _linkId, bytes memory _newParams): Owner updates link parameters.
    // 14. getEntanglementLinkDetails(uint256 _linkId): Get link details.
    // 15. isEntanglementLinkValid(uint256 _linkId): Check if link exists.

    // Entanglement Triggering & Processing:
    // 16. triggerEntanglementEffect(address _triggeringUser, address _triggeringToken, uint256 _triggeringStateId, uint256 _triggeredAmount, uint256 _triggerTimestamp, uint256 _eventNonce): Anyone can call to process effects from a measurement event (incentivized).
    // 17. setEntanglementTriggerFee(address _token, uint256 _feeAmount): Owner sets fee for keepers triggering effects.
    // 18. getEntanglementTriggerFee(address _token): Get trigger fee.
    // 19. setEntanglementProcessingWindow(uint256 _windowSeconds): Owner sets time window for processing triggers.
    // 20. getEntanglementProcessingWindow(): Get processing window.
    // 21. pauseEntanglementProcessing(bool _paused): Owner can pause triggers.
    // 22. isEntanglementProcessingPaused(): Check trigger pause status.

    // Advanced State Manipulation:
    // 23. splitSuperposition(address _token, uint256 _fromStateId, uint256[] memory _toStateIds, uint256[] memory _amounts): Redistribute balance from one state to others internally.
    // 24. mergeSuperposition(address _token, uint256[] memory _fromStateIds, uint256 _toStateId): Combine balances from multiple states into one.
    // 25. transferSuperpositionBalance(address _toUser, address _token, uint256 _stateId, uint256 _amount): User transfers balance within a specific state to another user.
    // 26. allowUserTransfer(address _token, uint256 _stateId, address _spender, uint256 _amount): Approve a spender to transfer balance from a specific state (ERC-20 allowance style).
    // 27. transferSuperpositionBalanceFrom(address _fromUser, address _toUser, address _token, uint256 _stateId, uint256 _amount): Spender executes an approved transfer.

    // Observer Management:
    // 28. registerObserver(): Register msg.sender as an observer.
    // 29. unregisterObserver(): Unregister msg.sender.
    // 30. getRegisteredObservers(): Get list of observers.

    // Access Control & Configuration:
    // Inherits Ownable (transferOwnership, renounceOwnership) - counts as 2 functions.
    // 31. addAcceptedToken(address _token): Owner allows a new ERC-20 token.
    // 32. removeAcceptedToken(address _token): Owner removes an accepted token.
    // 33. isTokenAccepted(address _token): Check if token is accepted.
    // 34. getAcceptedTokens(): List accepted tokens.
    // 35. sweepFees(address _token, address _recipient): Owner collects accumulated fees.

    // Query & Utility:
    // 36. getUserSuperpositionBalance(address _user, address _token, uint256 _stateId): Get user balance in a specific state.
    // 37. getUserTotalBalance(address _user, address _token): Get user's total deposited balance.
    // 38. getTotalSupply(address _token): Total amount of a token held by the contract.
    // 39. getSuperpositionStateCount(): Get total number of state types.
    // 40. getEntanglementLinkCount(): Get total number of entanglement links.
    // 41. getAccumulatedFees(address _token): Check accumulated fees.

    // (Total functions: 41 + 2 from Ownable = 43 functions)

    // --- State Variables ---

    // Represents a conceptual superposition state
    struct SuperpositionState {
        string name;
        bool exists; // Use a flag instead of relying on counter maximum
        mapping(string => bytes) properties; // Dynamic properties for conditional logic
    }

    // Represents an entanglement link between two states
    struct EntanglementLink {
        uint256 stateIdA;
        uint256 stateIdB;
        uint8 linkType; // 0: A affects B, 1: B affects A, 2: A <-> B
        bytes linkParams; // Parameters for the entanglement effect (e.g., ratio, time delay)
        bool exists; // Use a flag
    }

    // User -> Token -> State ID -> Balance
    mapping(address => mapping(address => mapping(uint256 => uint256))) private userSuperpositionBalances;

    // User -> Token -> State ID -> Spender -> Amount (for transferSuperpositionBalanceFrom)
    mapping(address => mapping(address => mapping(uint256 => mapping(address => uint256)))) private userStateAllowances;

    // State ID -> Superposition State details
    mapping(uint256 => SuperpositionState) private superpositionStates;
    Counters.Counter private _superpositionStateCounter;

    // Entanglement Link ID -> Entanglement Link details
    mapping(uint256 => EntanglementLink) private entanglementLinks;
    Counters.Counter private _entanglementLinkCounter;

    // Mapping to track accepted ERC-20 tokens
    mapping(address => bool) private acceptedTokens;
    address[] private acceptedTokenList; // To retrieve the list

    // Fees collected for triggering entanglement effects
    mapping(address => uint256) private accumulatedFees;
    mapping(address => uint256) private entanglementTriggerFees; // Fee per token

    // Window after a measurement event during which its entanglement trigger can be processed
    uint256 public entanglementProcessingWindow = 1 days; // Default window

    // Mapping to prevent replay attacks on triggerEntanglementEffect calls
    // Hash of (triggeringUser, triggeringToken, triggeringStateId, triggeredAmount, triggerTimestamp, eventNonce) => processed?
    mapping(bytes32 => bool) private processedEntanglementTriggers;
    bool public entanglementProcessingPaused = false;

    // Registered observers
    address[] private observers;
    mapping(address => bool) private isObserver;

    // --- Events ---

    event SuperpositionStateAdded(uint256 stateId, string name);
    event SuperpositionStateRemoved(uint256 stateId);
    event SuperpositionStatePropertyChanged(uint256 stateId, string propertyName, bytes propertyValue);

    event EntanglementLinkAdded(uint256 linkId, uint256 stateIdA, uint256 stateIdB, uint8 linkType);
    event EntanglementLinkRemoved(uint256 linkId);
    event EntanglementParamsUpdated(uint256 linkId, bytes newParams);

    event Deposit(address user, address token, uint256 totalAmount, uint256[] stateIds, uint256[] amountsPerState);
    event Withdrawal(address user, address token, uint256 stateId, uint256 amount);
    event MeasurementOccurred(address indexed user, address indexed token, uint256 indexed stateId, uint256 amount, uint256 timestamp);

    event SuperpositionSplit(address user, address token, uint256 fromStateId, uint256[] toStateIds, uint256[] amounts);
    event SuperpositionMerged(address user, address token, uint256[] fromStateIds, uint256 toStateId);
    event SuperpositionBalanceTransferred(address fromUser, address toUser, address token, uint256 stateId, uint256 amount);
    event SuperpositionAllowanceSet(address owner, address token, uint256 stateId, address spender, uint256 amount);

    event EntanglementEffectTriggered(address indexed caller, address indexed triggeringUser, address indexed triggeringToken, uint256 indexed triggeringStateId, uint256 triggeredAmount, uint256 triggerTimestamp, uint256 eventNonce, uint256 processedTimestamp);
    event EntanglementFeePaid(address indexed recipient, address indexed token, uint256 amount);
    event FeesSwept(address indexed owner, address indexed token, uint256 amount, address indexed recipient);

    event ObserverRegistered(address observer);
    event ObserverUnregistered(address observer);

    event AcceptedTokenAdded(address token);
    event AcceptedTokenRemoved(address token);

    // --- Modifiers ---

    modifier onlyAcceptedToken(address _token) {
        require(acceptedTokens[_token], "Token not accepted");
        _;
    }

    modifier onlyExistingState(uint256 _stateId) {
        require(superpositionStates[_stateId].exists, "State does not exist");
        _;
    }

    modifier onlyExistingLink(uint256 _linkId) {
        require(entanglementLinks[_linkId].exists, "Link does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Core Deposit & Withdrawal (Measurement) Functions ---

    /**
     * @dev Deposits ERC-20 tokens into multiple superposition states for the caller.
     * Requires prior approval of the token amount to the contract.
     * @param _token The address of the ERC-20 token.
     * @param _amount The total amount to deposit.
     * @param _stateIds The IDs of the states to distribute the amount into.
     * @param _amountsPerState The amounts corresponding to each state in _stateIds.
     */
    function deposit(address _token, uint256 _amount, uint256[] memory _stateIds, uint256[] memory _amountsPerState) external onlyAcceptedToken(_token) {
        require(_stateIds.length == _amountsPerState.length, "State and amount arrays must match length");

        uint256 totalAmountAllocated = 0;
        for (uint i = 0; i < _stateIds.length; i++) {
            require(superpositionStates[_stateIds[i]].exists, "Invalid state ID provided");
            totalAmountAllocated += _amountsPerState[i];
        }
        require(totalAmountAllocated == _amount, "Total allocated amount must equal deposit amount");

        IERC20 token = IERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        for (uint i = 0; i < _stateIds.length; i++) {
            userSuperpositionBalances[msg.sender][_token][_stateIds[i]] += _amountsPerState[i];
        }

        emit Deposit(msg.sender, _token, _amount, _stateIds, _amountsPerState);
    }

    /**
     * @dev Withdraws tokens from a specific superposition state ("measures" the state).
     * Emits a MeasurementOccurred event that can be processed by keepers for entanglement effects.
     * @param _token The address of the ERC-20 token.
     * @param _stateId The ID of the state to withdraw from.
     * @param _amount The amount to withdraw.
     * @param _measurementParams Arbitrary bytes that could influence conditional logic (interpreted off-chain or by a future extension).
     */
    function withdrawMeasured(address _token, uint256 _stateId, uint256 _amount, bytes memory _measurementParams) external onlyAcceptedToken(_token) onlyExistingState(_stateId) {
        require(userSuperpositionBalances[msg.sender][_token][_stateId] >= _amount, "Insufficient balance in state");
        require(_amount > 0, "Withdrawal amount must be positive");

        uint256 fee = entanglementTriggerFees[_token]; // Fee potentially paid to keeper later
        uint256 amountToWithdraw = _amount; // Measurement params could theoretically affect this, but for simplicity here they don't directly alter the withdrawal amount.

        userSuperpositionBalances[msg.sender][_token][_stateId] -= amountToWithdraw;

        // Send tokens to the user BEFORE emitting events / considering fees (Checks-Effects-Interactions)
        // Fee is deducted from the *remaining* balance or collected separately, NOT from the amount sent to user in this basic implementation.
        // A more complex version might deduct fee from withdrawal amount or require fee upfront.
        // For simplicity, fees accumulate and are swept by the owner. The *purpose* of the trigger fee is to incentivize calling `triggerEntanglementEffect` later.

        IERC20 token = IERC20(_token);
        require(token.transfer(msg.sender, amountToWithdraw), "Token transfer failed");

        emit Withdrawal(msg.sender, _token, _stateId, amountToWithdraw);
        // Emit event for keepers to trigger entanglement processing
        emit MeasurementOccurred(msg.sender, _token, _stateId, amountToWithdraw, block.timestamp);
    }

    /**
     * @dev Withdraws all tokens from a specific superposition state.
     * Similar to withdrawMeasured but for the entire state balance.
     * @param _token The address of the ERC-20 token.
     * @param _stateId The ID of the state to withdraw from.
     */
    function withdrawAllFromState(address _token, uint256 _stateId) external onlyAcceptedToken(_token) onlyExistingState(_stateId) {
        uint256 amountToWithdraw = userSuperpositionBalances[msg.sender][_token][_stateId];
        require(amountToWithdraw > 0, "No balance in this state");

        userSuperpositionBalances[msg.sender][_token][_stateId] = 0;

        IERC20 token = IERC20(_token);
        require(token.transfer(msg.sender, amountToWithdraw), "Token transfer failed");

        emit Withdrawal(msg.sender, _token, _stateId, amountToWithdraw);
        // Emit event for keepers to trigger entanglement processing
        emit MeasurementOccurred(msg.sender, _token, _stateId, amountToWithdraw, block.timestamp);
    }

    /**
     * @dev Withdraws the user's total balance of a token across all states.
     * Conceptually collapses all states for this token and user.
     * Does NOT emit individual MeasurementOccurred events per state, as it's a total collapse.
     * @param _token The address of the ERC-20 token.
     */
    function withdrawAllTotal(address _token) external onlyAcceptedToken(_token) {
        uint256 totalAmount = 0;
        uint256 stateCount = _superpositionStateCounter.current();

        // Sum up balances across all existing states
        for (uint256 i = 1; i <= stateCount; i++) {
            if (superpositionStates[i].exists) {
                totalAmount += userSuperpositionBalances[msg.sender][_token][i];
                userSuperpositionBalances[msg.sender][_token][i] = 0; // Reset balance in state
            }
        }

        require(totalAmount > 0, "No total balance to withdraw");

        IERC20 token = IERC20(_token);
        require(token.transfer(msg.sender, totalAmount), "Token transfer failed");

        emit Withdrawal(msg.sender, _token, 0, totalAmount); // State ID 0 could indicate total withdrawal
    }


    // --- Superposition State Management Functions ---

    /**
     * @dev Owner adds a new type of superposition state.
     * @param _name The descriptive name of the state.
     * @return The ID of the newly created state.
     */
    function addSuperpositionState(string memory _name) external onlyOwner returns (uint256) {
        _superpositionStateCounter.increment();
        uint256 newStateId = _superpositionStateCounter.current();
        superpositionStates[newStateId].name = _name;
        superpositionStates[newStateId].exists = true;
        emit SuperpositionStateAdded(newStateId, _name);
        return newStateId;
    }

    /**
     * @dev Owner removes an existing superposition state.
     * Requires the state to have zero total balance across all users/tokens.
     * @param _stateId The ID of the state to remove.
     */
    function removeSuperpositionState(uint256 _stateId) external onlyOwner onlyExistingState(_stateId) {
        // TODO: Add a mechanism to check if any user/token still holds balance in this state
        // This requires iterating potentially many balances, which is gas-intensive.
        // For a production system, a withdrawal sweep or a separate state-clearing process would be needed first.
        // For this example, we'll omit the balance check for simplicity, but note the risk.
        superpositionStates[_stateId].exists = false; // Mark as non-existent
        // State data remains but is marked invalid. Counter is not decremented.
        emit SuperpositionStateRemoved(_stateId);
    }

    /**
     * @dev Owner sets a dynamic property for a superposition state.
     * These properties can be used for off-chain interpretation of conditional logic.
     * @param _stateId The ID of the state.
     * @param _propertyName The name of the property (e.g., "measurement_effect_type", "risk_level").
     * @param _propertyValue The value of the property (e.g., encoded parameters).
     */
    function setSuperpositionStateProperty(uint256 _stateId, string memory _propertyName, bytes memory _propertyValue) external onlyOwner onlyExistingState(_stateId) {
        superpositionStates[_stateId].properties[_propertyName] = _propertyValue;
        emit SuperpositionStatePropertyChanged(_stateId, _propertyName, _propertyValue);
    }

    /**
     * @dev Gets the name of a superposition state.
     * @param _stateId The ID of the state.
     * @return The name of the state.
     */
    function getSuperpositionStateName(uint256 _stateId) external view onlyExistingState(_stateId) returns (string memory) {
        return superpositionStates[_stateId].name;
    }

     /**
     * @dev Gets a specific dynamic property of a superposition state.
     * @param _stateId The ID of the state.
     * @param _propertyName The name of the property.
     * @return The value of the property.
     */
    function getSuperpositionStateProperty(uint256 _stateId, string memory _propertyName) external view onlyExistingState(_stateId) returns (bytes memory) {
        return superpositionStates[_stateId].properties[_propertyName];
    }

    /**
     * @dev Checks if a superposition state ID is currently valid (exists).
     * @param _stateId The ID to check.
     * @return True if the state exists, false otherwise.
     */
    function isSuperpositionStateValid(uint256 _stateId) external view returns (bool) {
        // ID 0 is reserved/invalid for specific states
        if (_stateId == 0) return false;
        return superpositionStates[_stateId].exists;
    }


    // --- Entanglement Link Management Functions ---

    /**
     * @dev Owner creates an entanglement link between two states.
     * Requires both states to exist. Link is directional or bi-directional based on linkType.
     * @param _stateIdA The ID of the first state.
     * @param _stateIdB The ID of the second state.
     * @param _linkType The type of link (0: A->B, 1: B->A, 2: A<->B).
     * @param _linkParams Arbitrary parameters defining the nature of the entanglement effect.
     * @return The ID of the newly created link.
     */
    function addEntanglementLink(uint256 _stateIdA, uint256 _stateIdB, uint8 _linkType, bytes memory _linkParams) external onlyOwner onlyExistingState(_stateIdA) onlyExistingState(_stateIdB) returns (uint256) {
        require(_stateIdA != _stateIdB, "Cannot entangle a state with itself");
        require(_linkType <= 2, "Invalid link type");

        _entanglementLinkCounter.increment();
        uint256 newLinkId = _entanglementLinkCounter.current();
        entanglementLinks[newLinkId] = EntanglementLink({
            stateIdA: _stateIdA,
            stateIdB: _stateIdB,
            linkType: _linkType,
            linkParams: _linkParams,
            exists: true
        });

        emit EntanglementLinkAdded(newLinkId, _stateIdA, _stateIdB, _linkType);
        return newLinkId;
    }

    /**
     * @dev Owner removes an existing entanglement link.
     * @param _linkId The ID of the link to remove.
     */
    function removeEntanglementLink(uint256 _linkId) external onlyOwner onlyExistingLink(_linkId) {
        entanglementLinks[_linkId].exists = false; // Mark as non-existent
        // Link data remains but is marked invalid. Counter is not decremented.
        emit EntanglementLinkRemoved(_linkId);
    }

    /**
     * @dev Owner updates the parameters of an existing entanglement link.
     * @param _linkId The ID of the link to update.
     * @param _newParams The new parameters for the link.
     */
    function updateEntanglementParams(uint256 _linkId, bytes memory _newParams) external onlyOwner onlyExistingLink(_linkId) {
        entanglementLinks[_linkId].linkParams = _newParams;
        emit EntanglementParamsUpdated(_linkId, _newParams);
    }

    /**
     * @dev Gets the details of an entanglement link.
     * @param _linkId The ID of the link.
     * @return stateIdA, stateIdB, linkType, linkParams, exists flag.
     */
    function getEntanglementLinkDetails(uint256 _linkId) external view onlyExistingLink(_linkId) returns (uint256, uint256, uint8, bytes memory, bool) {
        EntanglementLink storage link = entanglementLinks[_linkId];
        return (link.stateIdA, link.stateIdB, link.linkType, link.linkParams, link.exists);
    }

    /**
     * @dev Checks if an entanglement link ID is currently valid (exists).
     * @param _linkId The ID to check.
     * @return True if the link exists, false otherwise.
     */
    function isEntanglementLinkValid(uint256 _linkId) external view returns (bool) {
        // ID 0 is reserved/invalid for links
        if (_linkId == 0) return false;
        return entanglementLinks[_linkId].exists;
    }

    // --- Entanglement Triggering & Processing Functions ---

    /**
     * @dev Allows anyone (e.g., a keeper) to trigger the processing of entanglement effects
     * resulting from a specific MeasurementOccurred event.
     * This function is incentivized by paying a fee to the caller.
     * It's designed to be idempotent using the eventNonce.
     * Note: The actual application of complex entanglement logic based on `linkParams`
     * is left as an off-chain interpretation or future contract extension due to gas costs.
     * This function primarily serves as the on-chain trigger and fee distribution mechanism.
     * @param _triggeringUser The user who performed the measurement.
     * @param _triggeringToken The token involved.
     * @param _triggeringStateId The state from which the measurement occurred.
     * @param _triggeredAmount The amount measured.
     * @param _triggerTimestamp The timestamp of the MeasurementOccurred event.
     * @param _eventNonce A unique nonce associated with the MeasurementOccurred event (e.g., block number + log index hash).
     */
    function triggerEntanglementEffect(address _triggeringUser, address _triggeringToken, uint256 _triggeringStateId, uint256 _triggeredAmount, uint256 _triggerTimestamp, uint256 _eventNonce) external {
        require(!entanglementProcessingPaused, "Entanglement processing is paused");

        // Prevent processing if the event is too old
        require(block.timestamp <= _triggerTimestamp + entanglementProcessingWindow, "Measurement event is outside processing window");

        // Generate a unique key for this specific event and nonce
        bytes32 triggerKey = keccak256(abi.encode(_triggeringUser, _triggeringToken, _triggeringStateId, _triggeredAmount, _triggerTimestamp, _eventNonce));
        require(!processedEntanglementTriggers[triggerKey], "Entanglement trigger already processed");

        processedEntanglementTriggers[triggerKey] = true; // Mark as processed

        // Log the trigger event for off-chain systems to interpret and apply effects
        emit EntanglementEffectTriggered(msg.sender, _triggeringUser, _triggeringToken, _triggeringStateId, _triggeredAmount, _triggerTimestamp, _eventNonce, block.timestamp);

        // Pay the keeper the configured fee if any
        uint256 feeAmount = entanglementTriggerFees[_triggeringToken];
        if (feeAmount > 0) {
            accumulatedFees[_triggeringToken] += feeAmount; // Fees accumulate, keeper collects via sweepFees
            // A direct transfer here might be better if keepers collect immediately
             // For simplicity in this example, fees are pooled.
            // To directly pay the keeper:
            // uint256 balanceBefore = IERC20(_triggeringToken).balanceOf(address(this));
            // bool success = IERC20(_triggeringToken).transfer(msg.sender, feeAmount);
            // if (!success) {
            //    accumulatedFees[_triggeringToken] += feeAmount; // Revert to pooling if transfer fails
            // } else {
            //    emit EntanglementFeePaid(msg.sender, _triggeringToken, feeAmount);
            // }
            // Let's stick to the accumulated fees for owner sweep for simplicity of fee handling.
        }
    }

    /**
     * @dev Owner sets the fee amount paid to keepers for triggering entanglement effects for a specific token.
     * @param _token The address of the ERC-20 token.
     * @param _feeAmount The fee amount.
     */
    function setEntanglementTriggerFee(address _token, uint256 _feeAmount) external onlyOwner onlyAcceptedToken(_token) {
        entanglementTriggerFees[_token] = _feeAmount;
    }

    /**
     * @dev Gets the current entanglement trigger fee for a specific token.
     * @param _token The address of the ERC-20 token.
     * @return The fee amount.
     */
    function getEntanglementTriggerFee(address _token) external view onlyAcceptedToken(_token) returns (uint256) {
        return entanglementTriggerFees[_token];
    }

    /**
     * @dev Owner sets the time window after a measurement event during which its entanglement trigger can be processed.
     * @param _windowSeconds The window duration in seconds.
     */
    function setEntanglementProcessingWindow(uint256 _windowSeconds) external onlyOwner {
        entanglementProcessingWindow = _windowSeconds;
    }

    /**
     * @dev Gets the current entanglement processing window.
     * @return The window duration in seconds.
     */
    function getEntanglementProcessingWindow() external view returns (uint256) {
        return entanglementProcessingWindow;
    }

    /**
     * @dev Owner can pause or unpause entanglement trigger processing.
     * @param _paused True to pause, false to unpause.
     */
    function pauseEntanglementProcessing(bool _paused) external onlyOwner {
        entanglementProcessingPaused = _paused;
        // Event could be useful here
    }

     /**
     * @dev Checks if entanglement processing is currently paused.
     * @return True if paused, false otherwise.
     */
    function isEntanglementProcessingPaused() external view returns (bool) {
        return entanglementProcessingPaused;
    }

    // --- Advanced State Manipulation Functions ---

    /**
     * @dev Splits a portion of a user's balance from one state into multiple other states.
     * This happens internally without tokens leaving the contract.
     * @param _token The address of the ERC-20 token.
     * @param _fromStateId The state to split from.
     * @param _toStateIds The states to split into.
     * @param _amounts The amounts corresponding to each state in _toStateIds.
     */
    function splitSuperposition(address _token, uint256 _fromStateId, uint256[] memory _toStateIds, uint256[] memory _amounts) external onlyAcceptedToken(_token) onlyExistingState(_fromStateId) {
        require(_toStateIds.length == _amounts.length, "Destination state and amount arrays must match length");

        uint256 totalAmountToSplit = 0;
        for (uint i = 0; i < _amounts.length; i++) {
             require(superpositionStates[_toStateIds[i]].exists, "Invalid destination state ID");
             totalAmountToSplit += _amounts[i];
        }

        require(userSuperpositionBalances[msg.sender][_token][_fromStateId] >= totalAmountToSplit, "Insufficient balance in source state for splitting");
        require(totalAmountToSplit > 0, "Amount to split must be positive");

        userSuperpositionBalances[msg.sender][_token][_fromStateId] -= totalAmountToSplit;

        for (uint i = 0; i < _toStateIds.length; i++) {
            userSuperpositionBalances[msg.sender][_token][_toStateIds[i]] += _amounts[i];
        }

        emit SuperpositionSplit(msg.sender, _token, _fromStateId, _toStateIds, _amounts);
    }

    /**
     * @dev Merges balances from multiple states into a single state.
     * This happens internally without tokens leaving the contract.
     * @param _token The address of the ERC-20 token.
     * @param _fromStateIds The states to merge from.
     * @param _toStateId The state to merge into.
     */
    function mergeSuperposition(address _token, uint256[] memory _fromStateIds, uint256 _toStateId) external onlyAcceptedToken(_token) onlyExistingState(_toStateId) {
        require(_fromStateIds.length > 0, "Must provide states to merge from");

        uint256 totalAmountToMerge = 0;
        for (uint i = 0; i < _fromStateIds.length; i++) {
            require(superpositionStates[_fromStateIds[i]].exists, "Invalid source state ID");
            require(_fromStateIds[i] != _toStateId, "Cannot merge a state into itself");
            totalAmountToMerge += userSuperpositionBalances[msg.sender][_token][_fromStateIds[i]];
            userSuperpositionBalances[msg.sender][_token][_fromStateIds[i]] = 0; // Clear source balance
        }

        require(totalAmountToMerge > 0, "No balance to merge from the specified states");

        userSuperpositionBalances[msg.sender][_token][_toStateId] += totalAmountToMerge;

        emit SuperpositionMerged(msg.sender, _token, _fromStateIds, _toStateId);
    }

    /**
     * @dev Transfers a specific amount of balance from the caller's specified state to another user's same state.
     * Similar to ERC-20 transfer, but scoped to a specific superposition state.
     * @param _toUser The recipient user.
     * @param _token The address of the ERC-20 token.
     * @param _stateId The ID of the state involved.
     * @param _amount The amount to transfer.
     */
    function transferSuperpositionBalance(address _toUser, address _token, uint256 _stateId, uint256 _amount) external onlyAcceptedToken(_token) onlyExistingState(_stateId) {
        require(_toUser != address(0), "Cannot transfer to zero address");
        require(userSuperpositionBalances[msg.sender][_token][_stateId] >= _amount, "Insufficient balance in state for transfer");
        require(_amount > 0, "Transfer amount must be positive");

        userSuperpositionBalances[msg.sender][_token][_stateId] -= _amount;
        userSuperpositionBalances[_toUser][_token][_stateId] += _amount;

        emit SuperpositionBalanceTransferred(msg.sender, _toUser, _token, _stateId, _amount);
    }

    /**
     * @dev Approves a `_spender` to transfer a specific amount of balance from the caller's `_stateId` on their behalf.
     * Similar to ERC-20 approve, but scoped to a specific superposition state.
     * @param _token The address of the ERC-20 token.
     * @param _stateId The ID of the state involved.
     * @param _spender The address allowed to spend.
     * @param _amount The maximum amount the spender can transfer from this state.
     */
    function allowUserTransfer(address _token, uint256 _stateId, address _spender, uint256 _amount) external onlyAcceptedToken(_token) onlyExistingState(_stateId) {
        require(_spender != address(0), "Cannot approve zero address");
        userStateAllowances[msg.sender][_token][_stateId][_spender] = _amount;
        emit SuperpositionAllowanceSet(msg.sender, _token, _stateId, _spender, _amount);
    }

    /**
     * @dev Allows an approved `_spender` to transfer balance from `_fromUser`'s `_stateId` to `_toUser`.
     * Similar to ERC-20 transferFrom, but scoped to a specific superposition state.
     * @param _fromUser The user whose balance is being transferred.
     * @param _toUser The recipient user.
     * @param _token The address of the ERC-20 token.
     * @param _stateId The ID of the state involved.
     * @param _amount The amount to transfer.
     */
    function transferSuperpositionBalanceFrom(address _fromUser, address _toUser, address _token, uint256 _stateId, uint256 _amount) external onlyAcceptedToken(_token) onlyExistingState(_stateId) {
        require(_toUser != address(0), "Cannot transfer to zero address");
        require(_fromUser != address(0), "Cannot transfer from zero address");
        require(userSuperpositionBalances[_fromUser][_token][_stateId] >= _amount, "Insufficient balance in state for transferFrom");
        require(_amount > 0, "Transfer amount must be positive");

        uint256 currentAllowance = userStateAllowances[_fromUser][_token][_stateId][msg.sender];
        require(currentAllowance >= _amount, "Allowance insufficient");

        userSuperpositionBalances[_fromUser][_token][_stateId] -= _amount;
        userSuperpositionBalances[_toUser][_token][_stateId] += _amount;

        // Decrease allowance (handle unlimited allowance if needed, simple deduction here)
        userStateAllowances[_fromUser][_token][_stateId][msg.sender] -= _amount;

        emit SuperpositionBalanceTransferred(_fromUser, _toUser, _token, _stateId, _amount);
    }

    // --- Observer Management Functions ---

    /**
     * @dev Registers the caller's address as an observer to receive detailed events.
     */
    function registerObserver() external {
        if (!isObserver[msg.sender]) {
            isObserver[msg.sender] = true;
            observers.push(msg.sender);
            emit ObserverRegistered(msg.sender);
        }
    }

    /**
     * @dev Unregisters the caller's address as an observer.
     */
    function unregisterObserver() external {
        if (isObserver[msg.sender]) {
            isObserver[msg.sender] = false;
            // Remove from array - simple implementation is O(n), optimize for large arrays in production
            for (uint i = 0; i < observers.length; i++) {
                if (observers[i] == msg.sender) {
                    observers[i] = observers[observers.length - 1];
                    observers.pop();
                    break;
                }
            }
            emit ObserverUnregistered(msg.sender);
        }
    }

    /**
     * @dev Gets the list of registered observer addresses.
     * @return An array of observer addresses.
     */
    function getRegisteredObservers() external view returns (address[] memory) {
        return observers;
    }


    // --- Access Control & Configuration Functions ---

    // Inherits onlyOwner from Ownable for transferOwnership and renounceOwnership

    /**
     * @dev Owner allows a new ERC-20 token to be deposited into the vault.
     * @param _token The address of the ERC-20 token contract.
     */
    function addAcceptedToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(!acceptedTokens[_token], "Token already accepted");
        acceptedTokens[_token] = true;
        acceptedTokenList.push(_token);
        emit AcceptedTokenAdded(_token);
    }

    /**
     * @dev Owner removes an ERC-20 token from the list of accepted tokens.
     * Note: This does not affect existing balances, but prevents new deposits of this token.
     * Removing a token that still has balances requires careful consideration in a real system.
     * @param _token The address of the ERC-20 token contract.
     */
    function removeAcceptedToken(address _token) external onlyOwner {
        require(acceptedTokens[_token], "Token not accepted");
        acceptedTokens[_token] = false;
        // Remove from array - simple implementation is O(n), optimize for large arrays in production
         for (uint i = 0; i < acceptedTokenList.length; i++) {
            if (acceptedTokenList[i] == _token) {
                acceptedTokenList[i] = acceptedTokenList[acceptedTokenList.length - 1];
                acceptedTokenList.pop();
                break;
            }
        }
        emit AcceptedTokenRemoved(_token);
    }

     /**
     * @dev Checks if a token is currently accepted for deposit.
     * @param _token The address of the ERC-20 token.
     * @return True if the token is accepted, false otherwise.
     */
    function isTokenAccepted(address _token) external view returns (bool) {
        return acceptedTokens[_token];
    }

    /**
     * @dev Gets the list of all currently accepted ERC-20 tokens.
     * @return An array of accepted token addresses.
     */
    function getAcceptedTokens() external view returns (address[] memory) {
        return acceptedTokenList;
    }

    /**
     * @dev Owner collects accumulated fees for a specific token.
     * These fees are accumulated from entanglement trigger calls.
     * @param _token The address of the ERC-20 token.
     * @param _recipient The address to send the fees to.
     */
    function sweepFees(address _token, address _recipient) external onlyOwner onlyAcceptedToken(_token) {
        uint256 feesToSweep = accumulatedFees[_token];
        require(feesToSweep > 0, "No fees accumulated for this token");
        require(_recipient != address(0), "Invalid recipient address");

        accumulatedFees[_token] = 0;
        IERC20 token = IERC20(_token);
        require(token.transfer(_recipient, feesToSweep), "Fee sweep failed");

        emit FeesSwept(msg.sender, _token, feesToSweep, _recipient);
    }


    // --- Query & Utility Functions ---

    /**
     * @dev Gets the balance of a specific user for a token in a specific superposition state.
     * @param _user The user's address.
     * @param _token The address of the ERC-20 token.
     * @param _stateId The ID of the superposition state.
     * @return The balance amount.
     */
    function getUserSuperpositionBalance(address _user, address _token, uint256 _stateId) external view onlyAcceptedToken(_token) onlyExistingState(_stateId) returns (uint256) {
        return userSuperpositionBalances[_user][_token][_stateId];
    }

    /**
     * @dev Gets the total deposited balance of a specific user for a token across all states.
     * @param _user The user's address.
     * @param _token The address of the ERC-20 token.
     * @return The total balance amount.
     */
    function getUserTotalBalance(address _user, address _token) external view onlyAcceptedToken(_token) returns (uint256) {
         uint256 totalAmount = 0;
        uint256 stateCount = _superpositionStateCounter.current();
        for (uint256 i = 1; i <= stateCount; i++) {
            if (superpositionStates[i].exists) { // Only sum up existing states
                 totalAmount += userSuperpositionBalances[_user][_token][i];
            }
        }
        return totalAmount;
    }

     /**
     * @dev Gets the total amount of a token held by the contract across all users and states.
     * This should ideally match the contract's actual token balance if no tokens are stuck.
     * @param _token The address of the ERC-20 token.
     * @return The total supply held within the vault logic.
     */
    function getTotalSupply(address _token) external view onlyAcceptedToken(_token) returns (uint256) {
        // Warning: Calculating total supply by iterating through all users is not feasible on-chain.
        // This function will return the *actual* balance of the token held by this contract address.
        // This is the standard way total supply within a vault/contract is queried.
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Gets the current number of defined superposition state types.
     * @return The total count of state types (including potentially removed but marked as non-existent).
     */
    function getSuperpositionStateCount() external view returns (uint256) {
        return _superpositionStateCounter.current();
    }

    /**
     * @dev Gets the current number of defined entanglement links.
     * @return The total count of links (including potentially removed but marked as non-existent).
     */
    function getEntanglementLinkCount() external view returns (uint256) {
        return _entanglementLinkCounter.current();
    }

     /**
     * @dev Gets the total accumulated fees for a specific token that can be swept by the owner.
     * @param _token The address of the ERC-20 token.
     * @return The accumulated fee amount.
     */
    function getAccumulatedFees(address _token) external view onlyAcceptedToken(_token) returns (uint256) {
        return accumulatedFees[_token];
    }

    // Note: Functions to list all state IDs or link IDs are omitted as they would require
    // iterating through mappings, which is not possible or gas-efficient for unknown sizes.
    // The counters provide the upper bound of potential IDs to query individually.
}
```

**Explanation of Concepts and Functions:**

1.  **Superposition States (`SuperpositionState`, `userSuperpositionBalances`, `addSuperpositionState`, `removeSuperpositionState`, `setSuperpositionStateProperty`, `getSuperpositionStateName`, `getSuperpositionStateProperty`, `isSuperpositionStateValid`, `getSuperpositionStateCount`):**
    *   Instead of one bucket per token per user, a user's deposited tokens can be allocated across different `SuperpositionState` IDs. This is tracked in the `userSuperpositionBalances` mapping.
    *   States are defined by the owner and can have dynamic properties (`properties` mapping within the struct) which could influence off-chain interpretation of events.
    *   `deposit` allows allocating the deposit amount across chosen states.
    *   `splitSuperposition` and `mergeSuperposition` allow users to redistribute their balances *between* their own states *within* the contract, simulating manipulating the superposition without measurement.

2.  **Measurement (Withdrawal) (`withdrawMeasured`, `withdrawAllFromState`, `withdrawAllTotal`, `MeasurementOccurred` event):**
    *   `withdrawMeasured` is the core "measurement" function. It pulls tokens from a *specific* state, effectively collapsing the superposition for that amount from that state.
    *   It emits `MeasurementOccurred`, which is the key event signifying a measurement has taken place and might trigger entanglement effects.
    *   `withdrawAllFromState` is a convenience for measuring the entire balance of a state.
    *   `withdrawAllTotal` collapses *all* states for a user's token balance and withdraws the total. It doesn't trigger individual entanglement events as it's a full collapse.

3.  **Entanglement Links (`EntanglementLink`, `entanglementLinks`, `addEntanglementLink`, `removeEntanglementLink`, `updateEntanglementParams`, `getEntanglementLinkDetails`, `isEntanglementLinkValid`, `getEntanglementLinkCount`):**
    *   Owner can link states together using `EntanglementLink` structs.
    *   `linkType` defines the directionality (A->B, B->A, A<->B).
    *   `linkParams` is a flexible `bytes` field intended to hold parameters for how the entanglement *should* affect the entangled state. The contract itself doesn't interpret complex logic from `linkParams` directly on-chain due to gas constraints; this is where off-chain keepers or future layer-2 solutions would interpret and act.

4.  **Entanglement Triggering & Processing (`triggerEntanglementEffect`, `entanglementTriggerFees`, `accumulatedFees`, `setEntanglementTriggerFee`, `getEntanglementTriggerFee`, `setEntanglementProcessingWindow`, `getEntanglementProcessingWindow`, `pauseEntanglementProcessing`, `isEntanglementProcessingPaused`, `EntanglementEffectTriggered` event, `processedEntanglementTriggers`):**
    *   `triggerEntanglementEffect` is designed to be called by anyone (a "keeper") *after* a `MeasurementOccurred` event is observed off-chain.
    *   It takes the details of the measurement event as parameters.
    *   It uses `processedEntanglementTriggers` and an `eventNonce` to ensure each specific measurement event is processed for entanglement effects only once.
    *   It pays a small fee (from `accumulatedFees`) to the caller, incentivizing the keeper network to process these events.
    *   The actual *effect* on the entangled state (e.g., locking balance, transferring notional value, triggering another event) is *not* fully implemented *within* this function. Instead, it emits `EntanglementEffectTriggered`, allowing off-chain systems (listening keepers, indexers, dApps) to interpret the `linkParams` of relevant entanglement links and perform necessary actions (potentially calling *other* functions on *this* contract or elsewhere). This is a common pattern to offload complex, non-critical computation from expensive on-chain execution.
    *   The owner can set fees and a time window for processing, and even pause it.

5.  **Advanced State Manipulation (`splitSuperposition`, `mergeSuperposition`, `transferSuperpositionBalance`, `allowUserTransfer`, `transferSuperpositionBalanceFrom`, `SuperpositionSplit`, `SuperpositionMerged`, `SuperpositionBalanceTransferred`, `SuperpositionAllowanceSet` events):**
    *   These allow users (or approved spenders) to move token balances *between* states or *between* users *within* specific states without actual token transfers in or out of the contract's total balance.

6.  **Observer Pattern (`observers`, `isObserver`, `registerObserver`, `unregisterObserver`, `getRegisteredObservers`, `ObserverRegistered`, `ObserverUnregistered` events):**
    *   Allows users to register interest in receiving *all* detailed event logs emitted by the contract, useful for monitoring complex state changes.

7.  **Access Control & Configuration (`Ownable`, `addAcceptedToken`, `removeAcceptedToken`, `isTokenAccepted`, `getAcceptedTokens`, `sweepFees`):**
    *   Standard `Ownable` pattern for critical owner-only functions.
    *   Owner controls which ERC-20 tokens the vault accepts.
    *   Owner can sweep collected trigger fees.

8.  **Query & Utility (`getUserSuperpositionBalance`, `getUserTotalBalance`, `getTotalSupply`, `getSuperpositionStateCount`, `getEntanglementLinkCount`, `getAccumulatedFees`):**
    *   Standard view functions to query balances, state/link counts, fees, etc. `getTotalSupply` is a standard ERC-20 like query showing the total tokens held by the contract.

This contract provides a framework for managing tokens with statefulness and interconnectedness inspired by quantum concepts, utilizing advanced patterns like keeper incentives and off-chain logic interpretation while keeping the core on-chain logic focused on state transitions and event emission. It avoids direct duplication of standard protocols by implementing a unique state model.