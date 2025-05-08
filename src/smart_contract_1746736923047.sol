Okay, here is a Solidity smart contract concept I've devised called `QuantumSwap`. It's inspired by the idea of quantum superposition and observation – a swap state exists in multiple potential outcomes simultaneously until an "observation" event (a specific function call) causes it to collapse into one definite outcome based on predefined conditions.

This goes beyond a simple conditional swap by allowing *multiple* potential outcomes, each with potentially complex conditions, and introduces concepts like observer-specific outcomes and external data checks. It also includes configuration, fees, and state management.

This concept is not a direct copy of common open-source patterns like Uniswap, lending protocols, or standard escrows, focusing instead on a multi-state conditional execution triggered by interaction.

---

**Smart Contract Name:** `QuantumSwap`

**Concept:** A decentralized exchange mechanism where a swap proposal (Input Token A for potential Output Token B, C, or D) exists in a "superposition" of multiple possible outcomes. An "observation" (calling `observeQuantumSwapState`) collapses the state, executing the first outcome whose conditions are met. If no specific conditions are met by a deadline, a default outcome occurs.

**Key Features:**

1.  **Multi-State Swaps:** Define a swap with various possible output tokens/amounts/recipients.
2.  **Conditional Resolution:** Each outcome has specific conditions (time, observer identity, external data) that must be met.
3.  **Observation Trigger:** A specific function call attempts to trigger the state collapse and execution.
4.  **Prioritized Outcomes:** Outcomes are checked in the order they were defined; the first matching one executes.
5.  **Default Outcome:** A fallback if no specific outcome conditions are met by the deadline.
6.  **Cancellable:** Creator can cancel before observation or deadline (with potential rules).
7.  **Configurable Fees:** Contract owner can set fees for successful swaps.
8.  **Oracle Integration:** Conditions can depend on external data fetched from a configured oracle contract.
9.  **Pausable:** Standard safety mechanism.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `createQuantumSwapState()`: Creates a new multi-outcome swap proposal, transferring input tokens to the contract.
3.  `modifyOutcomeCondition()`: Allows the creator to change conditions for a specific outcome in an unobserved state.
4.  `addOutcomeToSwap()`: Allows the creator to add a new potential outcome to an unobserved state.
5.  `removeOutcomeFromSwap()`: Allows the creator to remove an outcome from an unobserved state.
6.  `observeQuantumSwapState()`: Attempts to "collapse" a swap state, checking conditions and executing the first matching outcome or the default.
7.  `cancelQuantumSwapState()`: Allows the creator to cancel an unobserved swap state and retrieve input tokens (subject to deadline).
8.  `setFeePercentage()`: (Owner) Sets the percentage fee charged on successful swaps.
9.  `setFeeRecipient()`: (Owner) Sets the address where collected fees are sent.
10. `setOracleAddress()`: (Owner) Sets the address of the trusted oracle contract for external data conditions.
11. `withdrawFees()`: (Owner) Transfers accumulated fees from the contract balance to the fee recipient.
12. `pauseContract()`: (Owner) Pauses core functionality (`create`, `observe`).
13. `unpauseContract()`: (Owner) Unpauses the contract.
14. `getQuantumSwapStateDetails()`: (View) Retrieves full details of a specific swap state.
15. `getPossibleOutcomes()`: (View) Retrieves the list of possible outcomes for a swap state.
16. `getOutcomeConditions()`: (View) Retrieves conditions for a specific outcome within a swap state.
17. `getActiveSwapStateIds()`: (View) Returns an array of IDs for swap states that are currently open/unobserved.
18. `getContractBalance()`: (View) Gets the balance of a specific token held by the contract.
19. `isSwapStateActive()`: (View) Checks if a swap state exists and is neither observed nor cancelled.
20. `getTotalSwapStatesCreated()`: (View) Returns the total number of swap states created.
21. `getFeePercentage()`: (View) Returns the current fee percentage.
22. `getFeeRecipient()`: (View) Returns the current fee recipient address.
23. `getOracleAddress()`: (View) Returns the address of the configured oracle contract.
24. `getSwapStateCreator()`: (View) Returns the creator address of a specific swap state.
25. `getSwapStateInputDetails()`: (View) Returns the input token and amount for a specific swap state.
26. `getSwapStateDeadline()`: (View) Returns the deadline timestamp for a specific swap state.
27. `getSwapStateStatus()`: (View) Returns the observed/cancelled status and observed outcome index.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Define a simple Oracle interface for external data checks
// Assumes an oracle contract exists with a view function returning uint256
interface IOracle {
    function getUintValue() external view returns (uint256);
}

// Outline & Function Summary (See above for detailed summary)
/*
Contract Name: QuantumSwap
Concept: Multi-state conditional swaps resolved by "observation".

Function Summary:
1. constructor() - Initialize owner
2. createQuantumSwapState() - Create swap with multiple outcomes
3. modifyOutcomeCondition() - Modify outcome conditions (creator only, unobserved)
4. addOutcomeToSwap() - Add outcome (creator only, unobserved)
5. removeOutcomeFromSwap() - Remove outcome (creator only, unobserved)
6. observeQuantumSwapState() - Trigger state collapse and execution
7. cancelQuantumSwapState() - Cancel swap (creator only, subject to deadline)
8. setFeePercentage() - Set swap fee (owner)
9. setFeeRecipient() - Set fee recipient (owner)
10. setOracleAddress() - Set external oracle address (owner)
11. withdrawFees() - Withdraw collected fees (owner)
12. pauseContract() - Pause contract (owner)
13. unpauseContract() - Unpause contract (owner)
14. getQuantumSwapStateDetails() - View swap details
15. getPossibleOutcomes() - View swap outcomes
16. getOutcomeConditions() - View specific outcome conditions
17. getActiveSwapStateIds() - View active swap IDs
18. getContractBalance() - View contract token balance
19. isSwapStateActive() - Check if swap is active
20. getTotalSwapStatesCreated() - View total swaps created
21. getFeePercentage() - View fee percentage
22. getFeeRecipient() - View fee recipient
23. getOracleAddress() - View oracle address
24. getSwapStateCreator() - View swap creator
25. getSwapStateInputDetails() - View swap input details
26. getSwapStateDeadline() - View swap deadline
27. getSwapStateStatus() - View swap status (observed/cancelled)
*/


contract QuantumSwap is Ownable, Pausable {

    // --- State Variables ---

    uint256 public nextSwapStateId = 1;
    mapping(uint256 => QuantumSwapState) public swapStates;

    uint256 private _feePercentage = 0; // Basis points (e.g., 100 = 1%)
    address public feeRecipient;
    address public oracleAddress; // Address of the trusted oracle contract

    // --- Enums and Structs ---

    enum ConditionType {
        TimeBefore,       // Condition met if block.timestamp < targetValue
        TimeAfter,        // Condition met if block.timestamp > targetValue
        IsObserver,       // Condition met if msg.sender == targetAddress
        OracleValueBelow, // Condition met if IOracle(oracleAddress).getUintValue() < targetValue
        OracleValueAbove, // Condition met if IOracle(oracleAddress).getUintValue() > targetValue
        OracleValueEquals // Condition met if IOracle(oracleAddress).getUintValue() == targetValue
    }

    struct Condition {
        ConditionType conditionType;
        uint256 targetValue;   // Used for Time or Oracle checks
        address targetAddress; // Used for IsObserver check
        // Note: externalCheckAddress is implicitly oracleAddress for OracleValue* types
    }

    struct Outcome {
        address recipient;     // Address receiving tokens for this outcome
        address outputToken;   // The token address to send
        uint256 outputAmount;  // The amount of tokens to send
        Condition[] conditions; // ALL conditions in this array must be met
    }

    struct QuantumSwapState {
        address creator;         // The address that created the swap
        address inputToken;      // The token address provided by the creator
        uint256 inputAmount;     // The amount of input tokens provided
        uint256 deadline;        // Timestamp after which default outcome or cancellation is possible
        Outcome[] outcomes;      // The list of possible outcomes (checked in order)
        address defaultRecipient; // Recipient for the default outcome
        address defaultOutputToken; // Token for the default outcome
        uint256 defaultOutputAmount; // Amount for the default outcome
        bool isObserved;         // True if the state has collapsed into an outcome
        bool isCancelled;        // True if the state was cancelled by the creator
        int256 observedOutcomeIndex; // -1 if default, index if specific outcome
    }

    // --- Events ---

    event SwapStateCreated(uint256 indexed swapId, address indexed creator, address inputToken, uint256 inputAmount, uint256 deadline);
    event SwapStateObserved(uint256 indexed swapId, address indexed observer, int256 indexed outcomeIndex, address finalRecipient, address outputToken, uint256 outputAmount);
    event SwapStateCancelled(uint256 indexed swapId, address indexed creator);
    event FeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event FeesWithdrawn(address indexed recipient, address indexed token, uint256 amount);
    event OutcomeModified(uint256 indexed swapId, uint256 indexed outcomeIndex);
    event OutcomeAdded(uint256 indexed swapId, uint256 indexed outcomeIndex);
    event OutcomeRemoved(uint256 indexed swapId, uint256 indexed outcomeIndex);


    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        feeRecipient = msg.sender; // Default fee recipient is owner
    }

    // --- Core Functionality ---

    /// @notice Creates a new quantum swap state with multiple potential outcomes.
    /// @param _inputToken The address of the token to be swapped.
    /// @param _inputAmount The amount of input tokens.
    /// @param _deadline The timestamp when the swap expires (allows default or cancellation).
    /// @param _outcomes The array of possible outcomes with their conditions.
    /// @param _defaultRecipient The recipient for the default outcome.
    /// @param _defaultOutputToken The token for the default outcome.
    /// @param _defaultOutputAmount The amount for the default outcome.
    function createQuantumSwapState(
        address _inputToken,
        uint256 _inputAmount,
        uint256 _deadline,
        Outcome[] memory _outcomes,
        address _defaultRecipient,
        address _defaultOutputToken,
        uint256 _defaultOutputAmount
    ) external whenNotPaused returns (uint256 swapId) {
        require(_inputAmount > 0, "Input amount must be > 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_outcomes.length > 0, "Must provide at least one possible outcome");

        swapId = nextSwapStateId++;

        // Transfer input tokens from creator to the contract
        IERC20(_inputToken).transferFrom(msg.sender, address(this), _inputAmount);

        swapStates[swapId] = QuantumSwapState({
            creator: msg.sender,
            inputToken: _inputToken,
            inputAmount: _inputAmount,
            deadline: _deadline,
            outcomes: _outcomes, // Store the array of outcomes
            defaultRecipient: _defaultRecipient,
            defaultOutputToken: _defaultOutputToken,
            defaultOutputAmount: _defaultOutputAmount,
            isObserved: false,
            isCancelled: false,
            observedOutcomeIndex: -1 // -1 indicates default or not yet observed
        });

        emit SwapStateCreated(swapId, msg.sender, _inputToken, _inputAmount, _deadline);
        return swapId;
    }

    /// @notice Allows the creator to modify conditions for a specific outcome before observation.
    /// @param _swapId The ID of the swap state.
    /// @param _outcomeIndex The index of the outcome to modify.
    /// @param _newConditions The new array of conditions for this outcome.
    function modifyOutcomeCondition(uint256 _swapId, uint256 _outcomeIndex, Condition[] memory _newConditions)
        external
        whenNotPaused
    {
        QuantumSwapState storage state = swapStates[_swapId];
        require(state.creator == msg.sender, "Only creator can modify");
        require(!state.isObserved && !state.isCancelled, "Swap state must be active");
        require(_outcomeIndex < state.outcomes.length, "Invalid outcome index");

        state.outcomes[_outcomeIndex].conditions = _newConditions;

        emit OutcomeModified(_swapId, _outcomeIndex);
    }

    /// @notice Allows the creator to add a new outcome to the end of the list before observation.
    /// @param _swapId The ID of the swap state.
    /// @param _newOutcome The outcome struct to add.
    function addOutcomeToSwap(uint256 _swapId, Outcome memory _newOutcome)
        external
        whenNotPaused
    {
        QuantumSwapState storage state = swapStates[_swapId];
        require(state.creator == msg.sender, "Only creator can add outcomes");
        require(!state.isObserved && !state.isCancelled, "Swap state must be active");

        state.outcomes.push(_newOutcome);

        emit OutcomeAdded(_swapId, state.outcomes.length - 1);
    }

     /// @notice Allows the creator to remove an outcome by index before observation.
     /// @dev Removing from array is gas expensive. Consider alternative data structures for production.
    /// @param _swapId The ID of the swap state.
    /// @param _outcomeIndex The index of the outcome to remove.
    function removeOutcomeFromSwap(uint256 _swapId, uint256 _outcomeIndex)
        external
        whenNotPaused
    {
        QuantumSwapState storage state = swapStates[_swapId];
        require(state.creator == msg.sender, "Only creator can remove outcomes");
        require(!state.isObserved && !state.isCancelled, "Swap state must be active");
        require(_outcomeIndex < state.outcomes.length, "Invalid outcome index");
        require(state.outcomes.length > 1, "Cannot remove the last outcome");

        // Simple remove by swapping with last and popping (changes order)
        uint lastIndex = state.outcomes.length - 1;
        if (_outcomeIndex != lastIndex) {
            state.outcomes[_outcomeIndex] = state.outcomes[lastIndex];
        }
        state.outcomes.pop();

        emit OutcomeRemoved(_swapId, _outcomeIndex);
    }


    /// @notice Attempts to observe a swap state and trigger execution based on conditions.
    /// @param _swapId The ID of the swap state.
    function observeQuantumSwapState(uint256 _swapId) external whenNotPaused {
        QuantumSwapState storage state = swapStates[_swapId];
        require(!state.isObserved && !state.isCancelled, "Swap state is not active");

        bool outcomeExecuted = false;
        int256 executedOutcomeIndex = -1; // -1 for default

        // Attempt to find a matching outcome
        if (block.timestamp <= state.deadline) {
            for (uint i = 0; i < state.outcomes.length; i++) {
                if (_checkConditions(state.outcomes[i].conditions)) {
                    // Found the first matching outcome, execute it
                    _executeOutcome(_swapId, i, state.outcomes[i]);
                    outcomeExecuted = true;
                    executedOutcomeIndex = int256(i);
                    break; // Collapse: stop checking after the first match
                }
            }
        }

        // If no specific outcome was executed AND the deadline is passed, execute the default
        // (Or if deadline passed and someone calls observe to trigger default)
        if (!outcomeExecuted && block.timestamp > state.deadline) {
            _executeOutcome(_swapId, -1, Outcome({
                recipient: state.defaultRecipient,
                outputToken: state.defaultOutputToken,
                outputAmount: state.defaultOutputAmount,
                conditions: new Condition[](0) // Default has no conditions to check here
            }));
            outcomeExecuted = true; // Redundant, but clear
            executedOutcomeIndex = -1;
        }

        require(outcomeExecuted, "No outcome conditions met and deadline not passed");

        // Mark state as observed AFTER successful execution
        state.isObserved = true;
        state.observedOutcomeIndex = executedOutcomeIndex;

        // Swap state is now finalized, input tokens are transferred out
        // We can potentially free up state space later if needed, but for now it remains recorded.
    }

    /// @notice Allows the creator to cancel an unobserved swap state if the deadline has passed.
    /// @param _swapId The ID of the swap state.
    function cancelQuantumSwapState(uint256 _swapId) external whenNotPaused {
        QuantumSwapState storage state = swapStates[_swapId];
        require(state.creator == msg.sender, "Only creator can cancel");
        require(!state.isObserved && !state.isCancelled, "Swap state is not active");
        require(block.timestamp > state.deadline, "Cannot cancel before deadline");

        // Transfer input tokens back to the creator
        IERC20(state.inputToken).transfer(state.creator, state.inputAmount);

        state.isCancelled = true;
        // Optionally delete the state here to save gas for future interactions if desired
        // delete swapStates[_swapId]; // Be careful if views rely on historical data

        emit SwapStateCancelled(_swapId, msg.sender);
    }

    // --- Configuration (Owner Only) ---

    /// @notice Sets the fee percentage charged on successful swaps (in basis points).
    /// @param _feePercentageBasisPoints The fee percentage in basis points (e.g., 100 = 1%). Max 1000 (10%).
    function setFeePercentage(uint256 _feePercentageBasisPoints) external onlyOwner {
        require(_feePercentageBasisPoints <= 1000, "Fee percentage cannot exceed 10%"); // Cap fee
        emit FeePercentageUpdated(_feePercentage, _feePercentageBasisPoints);
        _feePercentage = _feePercentageBasisPoints;
    }

    /// @notice Sets the address that receives collected fees.
    /// @param _recipient The address to receive fees.
    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "Fee recipient cannot be zero address");
        emit FeeRecipientUpdated(feeRecipient, _recipient);
        feeRecipient = _recipient;
    }

    /// @notice Sets the address of the trusted oracle contract used for conditions.
    /// @param _oracleAddress The address of the oracle contract.
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero address");
        // Optional: Add check if the address is actually a contract or supports expected interface
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(oracleAddress, _oracleAddress);
    }

    /// @notice Allows the fee recipient to withdraw accumulated fees for a specific token.
    /// @param _token The address of the token to withdraw fees for.
    function withdrawFees(address _token) external {
        require(msg.sender == feeRecipient, "Only fee recipient can withdraw");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        // Note: This withdraws the entire balance of the token, assuming it's all fees.
        // A more complex system would track fees per token type explicitly.
        // This is a simplification.
        if (balance > 0) {
            IERC20(_token).transfer(feeRecipient, balance);
            emit FeesWithdrawn(feeRecipient, _token, balance);
        }
    }

    // --- Pause Functionality ---

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- View Functions ---

    /// @notice Gets the full details of a quantum swap state.
    /// @param _swapId The ID of the swap state.
    /// @return creator, inputToken, inputAmount, deadline, outcomes, defaultRecipient, defaultOutputToken, defaultOutputAmount, isObserved, isCancelled, observedOutcomeIndex
    function getQuantumSwapStateDetails(uint256 _swapId)
        external
        view
        returns (
            address creator,
            address inputToken,
            uint256 inputAmount,
            uint256 deadline,
            Outcome[] memory outcomes,
            address defaultRecipient,
            address defaultOutputToken,
            uint256 defaultOutputAmount,
            bool isObserved,
            bool isCancelled,
            int256 observedOutcomeIndex
        )
    {
        QuantumSwapState storage state = swapStates[_swapId];
        require(state.creator != address(0), "Swap state does not exist"); // Check existence

        creator = state.creator;
        inputToken = state.inputToken;
        inputAmount = state.inputAmount;
        deadline = state.deadline;
        outcomes = state.outcomes;
        defaultRecipient = state.defaultRecipient;
        defaultOutputToken = state.defaultOutputToken;
        defaultOutputAmount = state.defaultOutputAmount;
        isObserved = state.isObserved;
        isCancelled = state.isCancelled;
        observedOutcomeIndex = state.observedOutcomeIndex;
    }

    /// @notice Gets the possible outcomes for a swap state.
    /// @param _swapId The ID of the swap state.
    /// @return An array of Outcome structs.
    function getPossibleOutcomes(uint256 _swapId) external view returns (Outcome[] memory) {
        QuantumSwapState storage state = swapStates[_swapId];
        require(state.creator != address(0), "Swap state does not exist");
        return state.outcomes;
    }

    /// @notice Gets the conditions for a specific outcome within a swap state.
    /// @param _swapId The ID of the swap state.
    /// @param _outcomeIndex The index of the outcome.
    /// @return An array of Condition structs.
    function getOutcomeConditions(uint256 _swapId, uint256 _outcomeIndex) external view returns (Condition[] memory) {
        QuantumSwapState storage state = swapStates[_swapId];
        require(state.creator != address(0), "Swap state does not exist");
        require(_outcomeIndex < state.outcomes.length, "Invalid outcome index");
        return state.outcomes[_outcomeIndex].conditions;
    }

     /// @notice Returns an array of IDs for swap states that are currently open/unobserved.
     /// @dev This can be gas-expensive if many states exist. Consider alternative indexing for scale.
    function getActiveSwapStateIds() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](nextSwapStateId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextSwapStateId; i++) {
            if (swapStates[i].creator != address(0) && !swapStates[i].isObserved && !swapStates[i].isCancelled) {
                 // Check deadline here if 'active' strictly means 'before deadline'
                 // Currently, 'active' means 'not observed/cancelled'
                 // if (block.timestamp <= swapStates[i].deadline) { // Include deadline check if desired
                    activeIds[count] = i;
                    count++;
                 // }
            }
        }
        // Trim the array to the actual count
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }


    /// @notice Gets the balance of a specific token held by the contract.
    /// @param _token The address of the token.
    /// @return The balance amount.
    function getContractBalance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice Checks if a swap state exists and is currently active (neither observed nor cancelled).
    /// @param _swapId The ID of the swap state.
    /// @return True if active, false otherwise.
    function isSwapStateActive(uint256 _swapId) external view returns (bool) {
        QuantumSwapState storage state = swapStates[_swapId];
        return state.creator != address(0) && !state.isObserved && !state.isCancelled;
    }

    /// @notice Returns the total number of swap states that have been created.
    function getTotalSwapStatesCreated() external view returns (uint256) {
        return nextSwapStateId - 1;
    }

    /// @notice Returns the current fee percentage.
    function getFeePercentage() external view returns (uint256) {
        return _feePercentage;
    }

    /// @notice Returns the current fee recipient address.
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /// @notice Returns the address of the configured oracle contract.
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    /// @notice Returns the creator address of a specific swap state.
    /// @param _swapId The ID of the swap state.
    function getSwapStateCreator(uint256 _swapId) external view returns (address) {
         QuantumSwapState storage state = swapStates[_swapId];
         require(state.creator != address(0), "Swap state does not exist");
         return state.creator;
    }

    /// @notice Returns the input token and amount for a specific swap state.
    /// @param _swapId The ID of the swap state.
    /// @return inputToken, inputAmount
    function getSwapStateInputDetails(uint256 _swapId) external view returns (address, uint256) {
         QuantumSwapState storage state = swapStates[_swapId];
         require(state.creator != address(0), "Swap state does not exist");
         return (state.inputToken, state.inputAmount);
    }

    /// @notice Returns the deadline timestamp for a specific swap state.
    /// @param _swapId The ID of the swap state.
    function getSwapStateDeadline(uint256 _swapId) external view returns (uint256) {
         QuantumSwapState storage state = swapStates[_swapId];
         require(state.creator != address(0), "Swap state does not exist");
         return state.deadline;
    }

    /// @notice Returns the observation/cancellation status and observed outcome index for a swap state.
    /// @param _swapId The ID of the swap state.
    /// @return isObserved, isCancelled, observedOutcomeIndex
    function getSwapStateStatus(uint256 _swapId) external view returns (bool, bool, int256) {
         QuantumSwapState storage state = swapStates[_swapId];
         require(state.creator != address(0), "Swap state does not exist");
         return (state.isObserved, state.isCancelled, state.observedOutcomeIndex);
    }


    // --- Internal / Helper Functions ---

    /// @dev Checks if ALL conditions for a given outcome are met.
    function _checkConditions(Condition[] memory _conditions) internal view returns (bool) {
        if (_conditions.length == 0) {
            return true; // No conditions means always met
        }

        for (uint i = 0; i < _conditions.length; i++) {
            Condition storage cond = _conditions[i];
            bool conditionMet = false;

            if (cond.conditionType == ConditionType.TimeBefore) {
                conditionMet = block.timestamp < cond.targetValue;
            } else if (cond.conditionType == ConditionType.TimeAfter) {
                conditionMet = block.timestamp > cond.targetValue;
            } else if (cond.conditionType == ConditionType.IsObserver) {
                conditionMet = msg.sender == cond.targetAddress;
            } else if (cond.conditionType == ConditionType.OracleValueBelow) {
                 require(oracleAddress != address(0), "Oracle address not set");
                 uint256 oracleValue = IOracle(oracleAddress).getUintValue();
                 conditionMet = oracleValue < cond.targetValue;
            } else if (cond.conditionType == ConditionType.OracleValueAbove) {
                 require(oracleAddress != address(0), "Oracle address not set");
                 uint256 oracleValue = IOracle(oracleAddress).getUintValue();
                 conditionMet = oracleValue > cond.targetValue;
            } else if (cond.conditionType == ConditionType.OracleValueEquals) {
                 require(oracleAddress != address(0), "Oracle address not set");
                 uint256 oracleValue = IOracle(oracleAddress).getUintValue();
                 conditionMet = oracleValue == cond.targetValue;
            }
            // Add more condition types here as needed

            if (!conditionMet) {
                return false; // If any single condition is not met, the whole outcome fails
            }
        }
        return true; // All conditions were met
    }

    /// @dev Executes a specific outcome (or default outcome) for a swap state. Handles fees.
    /// @param _swapId The ID of the swap state.
    /// @param _outcomeIndex The index of the outcome (-1 for default).
    /// @param _outcome The outcome details (copied for default, referenced for specific).
    function _executeOutcome(uint256 _swapId, int256 _outcomeIndex, Outcome memory _outcome) internal {
        uint256 outputAmount = _outcome.outputAmount;
        address outputToken = _outcome.outputToken;
        address recipient = _outcome.recipient;

        uint256 feeAmount = 0;
        if (_feePercentage > 0 && outputAmount > 0) {
            // Calculate fee based on output amount
            feeAmount = (outputAmount * _feePercentage) / 10000; // Fee in basis points
            outputAmount = outputAmount - feeAmount; // Recipient gets amount minus fee
        }

        // Transfer tokens to the recipient
        if (outputAmount > 0) {
             // Check if contract holds enough balance
             require(IERC20(outputToken).balanceOf(address(this)) >= outputAmount + feeAmount, "Insufficient contract balance for outcome");
             IERC20(outputToken).transfer(recipient, outputAmount);
        }

        // Transfer fees
        if (feeAmount > 0 && feeRecipient != address(0)) {
             IERC20(outputToken).transfer(feeRecipient, feeAmount);
        }

        emit SwapStateObserved(_swapId, msg.sender, _outcomeIndex, recipient, outputToken, outputAmount);
    }

    // Fallback and Receive functions to potentially handle ETH, though primarily ERC20
     receive() external payable {}
     fallback() external payable {}
     // Note: ETH received this way can be withdrawn via `withdrawFees` if feeRecipient calls it
     // with address(0) or WETH equivalent, depending on implementation detail not included here.
     // For simplicity, this contract is primarily designed for ERC20 swaps.
}
```