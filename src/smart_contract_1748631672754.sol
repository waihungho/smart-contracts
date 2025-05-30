Okay, let's create a smart contract concept called `QuantumSwap`. The idea is to allow users to create swap orders with *multiple potential outcomes*, where the *actual* outcome depends on a future, observable condition (like a price feed value). This is a conceptual nod to quantum superposition and collapse – the order is in multiple states until the condition is "observed."

Liquidity providers (LPs) can then provide liquidity *conditionally*, specifying which outcome they are willing to fulfill if the corresponding condition is met.

This involves conditional logic, interaction with external data sources (oracles), time-based expiry, and a matching mechanism between user orders and LP offers.

---

**QuantumSwap Smart Contract**

**Outline:**

1.  **Contract Information:** Pragma, Imports, Contract Definition, Interfaces.
2.  **State Variables:** Storage for orders, offers, counters, owner, fees, supported tokens, oracle address.
3.  **Enums:** Define states for orders, offers, and types of conditions.
4.  **Structs:** Define the data structures for `Condition`, `SwapOutcome`, `QuantumSwapOrder`, and `ConditionalLiquidityOffer`.
5.  **Events:** Emit events for key actions (order creation, collapse, cancellation, offer creation, etc.).
6.  **Modifiers:** Access control (`onlyOwner`), contract state (`whenNotPaused`).
7.  **Constructor:** Initializes the contract owner and potentially an oracle address.
8.  **Admin Functions:** Functions for managing contract parameters, supported tokens, fees, and oracle address.
9.  **User (Swapper) Functions:** Functions for creating, cancelling, collapsing swap orders, and querying order status.
10. **User (Liquidity Provider) Functions:** Functions for adding and removing conditional liquidity offers, and querying offer status.
11. **View Functions:** Read-only functions to get contract state, order details, and offer details.
12. **Internal/Helper Functions:** Logic for checking conditions, finding matches, etc.

**Function Summary:**

*   `constructor()`: Initializes the contract owner and optionally the initial oracle address.
*   `setOracleAddress(address _oracle)`: Admin function to set the address of the oracle contract.
*   `addSupportedToken(address _token)`: Admin function to add a token address to the list of supported tokens.
*   `removeSupportedToken(address _token)`: Admin function to remove a token address from the list of supported tokens.
*   `setCollapseFee(uint256 _fee)`: Admin function to set the fee charged when a swap order is successfully collapsed.
*   `withdrawAdminFees(address _token, uint256 _amount)`: Admin function to withdraw collected fees for a specific token.
*   `pauseContract()`: Admin function to pause contract state-changing operations.
*   `unpauseContract()`: Admin function to unpause the contract.
*   `createQuantumSwap(address _inputToken, uint256 _inputAmount, address _outputToken, SwapOutcome[] calldata _outcomes, uint64 _expiryBlock)`: Allows a user to create a multi-outcome swap order. Requires input tokens to be approved and transferred.
*   `cancelQuantumSwap(uint256 _orderId)`: Allows the order creator to cancel a pending swap order before it expires or is collapsed. Returns input tokens.
*   `collapseQuantumSwap(uint256 _orderId, uint256 _outcomeIndex)`: Allows any party (or potentially an incentivized executor) to attempt to finalize a swap order by checking if the condition for a specific outcome is met via the oracle. If met and matching conditional liquidity exists, the swap executes.
*   `addConditionalLiquidity(address _outputToken, uint256 _outputAmount, address _inputToken, uint256 _requiredInputAmount, Condition calldata _condition)`: Allows an LP to deposit output tokens, specifying the condition under which these tokens can be used and the input tokens/amount they require in return.
*   `removeConditionalLiquidity(uint256 _offerId)`: Allows an LP to remove their active conditional liquidity offer. Returns output tokens.
*   `getOrderDetails(uint256 _orderId)`: View function to get the full details of a specific swap order.
*   `getOrdersByUser(address _user)`: View function to get a list of order IDs created by a specific user. (Note: May be gas-intensive for many orders, consider pagination in production).
*   `getPendingOrdersForCondition(bytes32 _conditionHash)`: View function to get a list of *pending* order IDs associated with a specific condition hash. (Note: Gas-intensive).
*   `getPossibleOutcomes(uint256 _orderId)`: View function to get the list of potential outcomes and their conditions for a pending order.
*   `getCollapsedOutcome(uint256 _orderId)`: View function to get the details of the outcome that was executed for a collapsed order.
*   `getConditionalLiquidityOfferDetails(uint256 _offerId)`: View function to get the details of a specific liquidity offer.
*   `getConditionalLiquidityOffersByUser(address _user)`: View function to get a list of offer IDs created by a specific LP. (Note: Gas-intensive).
*   `getConditionalOffersForCondition(bytes32 _conditionHash)`: View function to get a list of *active* offer IDs associated with a specific condition hash. (Note: Gas-intensive).
*   `getContractTokenBalance(address _token)`: View function to check the contract's balance of a specific token.
*   `getSupportedTokens()`: View function to get the list of supported token addresses.
*   `getProtocolFees(address _token)`: View function to check the amount of fees collected for a specific token.
*   `_isConditionMet(Condition memory _condition)`: Internal helper function to interact with the oracle and check if a given condition is met.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Define an interface for the Oracle contract the QuantumSwap will interact with
// This is a conceptual interface; a real implementation would depend on the oracle type (e.g., Chainlink)
interface IConditionOracle {
    // Example function to check if a condition is met
    // Returns true if condition met, false otherwise.
    // Could return more detailed data if needed.
    function checkCondition(bytes calldata _conditionData) external view returns (bool);

    // Define different condition types recognized by the oracle
    enum ConditionType {
        PRICE_GREATER_THAN,
        PRICE_LESS_THAN,
        BLOCK_NUMBER_AFTER,
        CUSTOM_CONDITION // For more complex, custom checks
    }
}

contract QuantumSwap is Ownable, ReentrancyGuard {

    // --- State Variables ---
    address public oracleAddress;
    mapping(address => bool) public supportedTokens;
    uint256 public collapseFee; // Fee charged on successful collapse (in input token or other token)
    mapping(address => uint256) public protocolFees; // Fees collected per token

    uint256 private orderCounter;
    uint256 private offerCounter;

    enum OrderStatus { PENDING, COLLAPSED, CANCELLED, EXPIRED }
    enum OfferStatus { ACTIVE, FILLED, CANCELLED }
    enum ConditionType {
        PRICE_GREATER_THAN,
        PRICE_LESS_THAN,
        BLOCK_NUMBER_AFTER,
        CUSTOM_CONDITION
    }

    struct Condition {
        ConditionType conditionType;
        address targetAddress; // e.g., Price feed address, or contract address for CUSTOM_CONDITION
        uint256 comparisonValue; // e.g., Price threshold (scaled), block number
        address tokenA; // For price feeds (e.g., base token)
        address tokenB; // For price feeds (e.g., quote token)
        bytes customData; // Additional data for CUSTOM_CONDITION
    }

    struct SwapOutcome {
        uint256 outputAmount;
        Condition condition; // The condition required for this outcome
        bytes32 conditionHash; // Hash of the condition data for lookup
    }

    struct QuantumSwapOrder {
        address user;
        address inputToken;
        uint256 inputAmount;
        address outputToken; // Output token is the same for all outcomes in one order
        SwapOutcome[] outcomes; // Multiple potential outcomes based on conditions
        uint64 expiryBlock; // Block number after which the order expires
        OrderStatus status;
        uint256 executedOutcomeIndex; // Index of the outcome that was executed (-1 if none)
        uint64 createdBlock;
    }

    mapping(uint256 => QuantumSwapOrder) public quantumSwapOrders;
    mapping(address => uint256[]) public ordersByUser; // For easy lookup
    mapping(bytes32 => uint256[]) public pendingOrdersByCondition; // For easy lookup by condition

    struct ConditionalLiquidityOffer {
        address provider;
        address outputToken;
        uint256 outputAmount; // Total amount offered under this condition
        address inputToken; // Token required in exchange
        uint256 requiredInputAmount; // Amount required in exchange per unit of output
        Condition condition; // The condition under which this offer is valid
        bytes32 conditionHash; // Hash of the condition data for lookup
        OfferStatus status;
        uint64 createdBlock;
    }

    mapping(uint256 => ConditionalLiquidityOffer) public conditionalLiquidityOffers;
    mapping(address => uint256[]) public offersByProvider; // For easy lookup
    mapping(bytes32 => uint256[]) public activeOffersByCondition; // For easy lookup by condition

    bool public paused = false;

    // --- Events ---
    event OracleAddressSet(address indexed _oracle);
    event TokenSupported(address indexed _token, bool _isSupported);
    event CollapseFeeSet(uint256 _fee);
    event AdminFeesWithdrawn(address indexed _token, uint256 _amount, address indexed _to);
    event ContractPaused(address indexed _by);
    event ContractUnpaused(address indexed _by);

    event QuantumSwapCreated(uint256 indexed orderId, address indexed user, address inputToken, uint256 inputAmount, address outputToken, uint64 expiryBlock);
    event QuantumSwapCollapsed(uint256 indexed orderId, address indexed user, uint256 executedOutcomeIndex, uint256 outputAmount, uint256 feeAmount);
    event QuantumSwapCancelled(uint256 indexed orderId, address indexed user);
    event QuantumSwapExpired(uint256 indexed orderId);

    event ConditionalLiquidityAdded(uint256 indexed offerId, address indexed provider, address outputToken, uint256 outputAmount, bytes32 conditionHash);
    event ConditionalLiquidityRemoved(uint256 indexed offerId, address indexed provider);
    event ConditionalLiquidityFilled(uint256 indexed offerId, uint256 matchedOrderId, address indexed user);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- Constructor ---
    constructor(address _oracle) Ownable(msg.sender) {
        require(_oracle != address(0), "Invalid oracle address");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
        // Default fee is 0
        collapseFee = 0;
    }

    // --- Admin Functions ---

    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid oracle address");
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    function addSupportedToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(!supportedTokens[_token], "Token already supported");
        supportedTokens[_token] = true;
        emit TokenSupported(_token, true);
    }

    function removeSupportedToken(address _token) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");
        supportedTokens[_token] = false;
        emit TokenSupported(_token, false);
    }

    function setCollapseFee(uint256 _fee) external onlyOwner {
        collapseFee = _fee;
        emit CollapseFeeSet(_fee);
    }

    function withdrawAdminFees(address _token, uint256 _amount) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");
        require(protocolFees[_token] >= _amount, "Insufficient fees collected");
        protocolFees[_token] -= _amount;
        IERC20(_token).transfer(owner(), _amount); // Transfer to owner()
        emit AdminFeesWithdrawn(_token, _amount, owner());
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Internal Helper Functions ---

    // Calculates a unique hash for a condition
    function _hashCondition(Condition memory _condition) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            _condition.conditionType,
            _condition.targetAddress,
            _condition.comparisonValue,
            _condition.tokenA,
            _condition.tokenB,
            _condition.customData
        ));
    }

    // Checks if a condition is met using the registered oracle
    function _isConditionMet(Condition memory _condition) internal view returns (bool) {
        require(oracleAddress != address(0), "Oracle address not set");
        // Encode condition data to pass to the oracle
        bytes memory conditionData = abi.encode(
            _condition.conditionType,
            _condition.targetAddress,
            _condition.comparisonValue,
            _condition.tokenA,
            _condition.tokenB,
            _condition.customData
        );
        return IConditionOracle(oracleAddress).checkCondition(conditionData);
    }

    // Finds a matching liquidity offer for a given condition hash, required input, and output token/amount
    // Note: This simple implementation iterates through active offers for the condition hash.
    // A production system might need a more efficient matching engine or indexing.
    function _findMatchingOffer(
        bytes32 _conditionHash,
        address _inputToken,
        uint256 _requiredInputAmount,
        address _outputToken,
        uint256 _outputAmount
    ) internal view returns (uint256 offerId, bool found) {
        uint256[] storage offerIds = activeOffersByCondition[_conditionHash];
        for (uint i = 0; i < offerIds.length; i++) {
            uint256 currentOfferId = offerIds[i];
            ConditionalLiquidityOffer storage offer = conditionalLiquidityOffers[currentOfferId];

            if (offer.status == OfferStatus.ACTIVE &&
                offer.outputToken == _outputToken &&
                offer.outputAmount >= _outputAmount && // Offer must have enough output tokens
                offer.inputToken == _inputToken &&
                offer.requiredInputAmount <= _requiredInputAmount // Offer must require *at most* the available input
            ) {
                // Found a match!
                return (currentOfferId, true);
            }
        }
        return (0, false); // No match found
    }

    // Removes an offerId from the activeOffersByCondition list for a given hash
    // Note: Simple removal by swapping with last element. Requires iterating to find index.
    // Could be optimized if necessary.
    function _removeOfferIdFromConditionList(bytes32 _conditionHash, uint256 _offerId) internal {
         uint256[] storage offerIds = activeOffersByCondition[_conditionHash];
         for (uint i = 0; i < offerIds.length; i++) {
             if (offerIds[i] == _offerId) {
                 // Swap with the last element and pop
                 offerIds[i] = offerIds[offerIds.length - 1];
                 offerIds.pop();
                 break; // Assuming offer IDs are unique in the list
             }
         }
    }


    // --- User (Swapper) Functions ---

    /**
     * @notice Creates a new multi-outcome quantum swap order.
     * @param _inputToken The token the user is swapping from.
     * @param _inputAmount The amount of input token.
     * @param _outputToken The token the user wants to swap to.
     * @param _outcomes An array of potential outcomes, each with a condition and output amount.
     * @param _expiryBlock The block number after which this order is no longer valid.
     */
    function createQuantumSwap(
        address _inputToken,
        uint256 _inputAmount,
        address _outputToken,
        SwapOutcome[] calldata _outcomes,
        uint64 _expiryBlock
    ) external nonReentrant whenNotPaused {
        require(supportedTokens[_inputToken], "Input token not supported");
        require(supportedTokens[_outputToken], "Output token not supported");
        require(_inputAmount > 0, "Input amount must be greater than 0");
        require(_outcomes.length > 0, "Must provide at least one outcome");
        require(_expiryBlock > block.number, "Expiry block must be in the future");

        uint256 currentOrderId = orderCounter++;
        QuantumSwapOrder storage newOrder = quantumSwapOrders[currentOrderId];

        newOrder.user = msg.sender;
        newOrder.inputToken = _inputToken;
        newOrder.inputAmount = _inputAmount;
        newOrder.outputToken = _outputToken;
        newOrder.expiryBlock = _expiryBlock;
        newOrder.status = OrderStatus.PENDING;
        newOrder.executedOutcomeIndex = type(uint256).max; // Indicate not executed
        newOrder.createdBlock = uint64(block.number);

        newOrder.outcomes.length = _outcomes.length;
        for (uint i = 0; i < _outcomes.length; i++) {
            // Store outcome data
            newOrder.outcomes[i].outputAmount = _outcomes[i].outputAmount;
            newOrder.outcomes[i].condition = _outcomes[i].condition;
            // Calculate and store the hash of the condition
            bytes32 conditionHash = _hashCondition(_outcomes[i].condition);
            newOrder.outcomes[i].conditionHash = conditionHash;

            // Add order ID to lookup mapping for this condition hash
            pendingOrdersByCondition[conditionHash].push(currentOrderId);
        }

        // Transfer input tokens from the user to the contract
        IERC20(_inputToken).transferFrom(msg.sender, address(this), _inputAmount);

        ordersByUser[msg.sender].push(currentOrderId);

        emit QuantumSwapCreated(currentOrderId, msg.sender, _inputToken, _inputAmount, _outputToken, _expiryBlock);
    }

    /**
     * @notice Allows the order creator to cancel a pending swap order.
     * @param _orderId The ID of the order to cancel.
     */
    function cancelQuantumSwap(uint256 _orderId) external nonReentrant whenNotPaused {
        QuantumSwapOrder storage order = quantumSwapOrders[_orderId];
        require(order.user == msg.sender, "Not your order");
        require(order.status == OrderStatus.PENDING, "Order is not pending");
        require(block.number <= order.expiryBlock, "Order has expired");

        // Return input tokens to the user
        IERC20(order.inputToken).transfer(order.user, order.inputAmount);

        // Update status
        order.status = OrderStatus.CANCELLED;

        // Remove order ID from pendingOrdersByCondition lists
        for (uint i = 0; i < order.outcomes.length; i++) {
             bytes32 conditionHash = order.outcomes[i].conditionHash;
             uint256[] storage orderIds = pendingOrdersByCondition[conditionHash];
             for (uint j = 0; j < orderIds.length; j++) {
                 if (orderIds[j] == _orderId) {
                      orderIds[j] = orderIds[orderIds.length - 1];
                      orderIds.pop();
                      break; // Assuming order IDs are unique in the list
                 }
             }
        }


        emit QuantumSwapCancelled(_orderId, msg.sender);
    }

     /**
     * @notice Attempts to collapse a quantum swap order by checking if a specific outcome's condition is met
     *         and finding a matching liquidity offer. Callable by anyone (executor).
     * @param _orderId The ID of the order to collapse.
     * @param _outcomeIndex The index of the specific outcome to check the condition for.
     * @dev An incentivized third party (executor) would typically call this when a condition is met.
     */
    function collapseQuantumSwap(uint256 _orderId, uint256 _outcomeIndex) external nonReentrant whenNotPaused {
        QuantumSwapOrder storage order = quantumSwapOrders[_orderId];
        require(order.status == OrderStatus.PENDING, "Order is not pending");
        require(block.number <= order.expiryBlock, "Order has expired");
        require(_outcomeIndex < order.outcomes.length, "Invalid outcome index");
        require(oracleAddress != address(0), "Oracle address not set");

        SwapOutcome storage chosenOutcome = order.outcomes[_outcomeIndex];

        // 1. Check if the condition for the chosen outcome is met
        bool conditionMet = _isConditionMet(chosenOutcome.condition);
        require(conditionMet, "Condition not met for the selected outcome");

        // 2. Find a matching liquidity offer for this outcome
        // We look for an offer that provides the output token under this condition hash,
        // with at least the required output amount, and requests the input token
        // requiring at most the amount deposited by the user.
        (uint256 matchingOfferId, bool offerFound) = _findMatchingOffer(
            chosenOutcome.conditionHash,
            order.inputToken,
            order.inputAmount, // The max input amount the offer can require
            order.outputToken,
            chosenOutcome.outputAmount
        );

        require(offerFound, "No matching liquidity offer found");

        ConditionalLiquidityOffer storage matchingOffer = conditionalLiquidityOffers[matchingOfferId];
        require(matchingOffer.status == OfferStatus.ACTIVE, "Matching offer is not active"); // Double check status

        // Ensure the offer requirement is <= the user's deposit for this specific outcome's amount
        // Calculate the required input based on the offer's *rate* (requiredInputAmount / outputAmount)
        // We need to be careful with division and potential precision loss.
        // A simpler model assumes the offer's requiredInputAmount is for the *total* output it offers.
        // Let's use the simpler model: the offer provides X output for Y input under condition C.
        // If the order needs A output and has B input under condition C, we need an offer with:
        // Output Offered >= A AND Input Required <= B AND Condition == C.
        // The findMatchingOffer function already uses this simplified check. Let's re-verify the logic.
        // The offer provides `matchingOffer.outputAmount` for `matchingOffer.requiredInputAmount`.
        // The order needs `chosenOutcome.outputAmount` and provided `order.inputAmount`.
        // A direct match means the offer's *rate* (input/output) is favorable or equal to the user's implicit rate.
        // Offer Rate = matchingOffer.requiredInputAmount / matchingOffer.outputAmount
        // User Implicit Rate = order.inputAmount / chosenOutcome.outputAmount
        // We need Offer Rate <= User Implicit Rate
        // (matchingOffer.requiredInputAmount * chosenOutcome.outputAmount) <= (order.inputAmount * matchingOffer.outputAmount)
        // This check ensures the LP is willing to give the required output amount for no more input than the user provided.
        require(matchingOffer.requiredInputAmount * chosenOutcome.outputAmount <= order.inputAmount * matchingOffer.outputAmount, "Offer rate not favorable enough");

        // 3. Execute the swap
        uint256 outputToSend = chosenOutcome.outputAmount;
        uint256 inputToSendToLP = (matchingOffer.requiredInputAmount * outputToSend) / matchingOffer.outputAmount; // Calculate precise input based on offer's rate for the fulfilled amount

        // Transfer output token from contract (LP's funds) to the user
        IERC20(order.outputToken).transfer(order.user, outputToSend);

        // Transfer input token from contract (user's funds) to the LP
        // Deduct potential fees from the input token sent to the LP
        uint256 feeAmount = 0;
        if (collapseFee > 0) {
            // Ensure fee doesn't exceed the amount being sent to the LP
            feeAmount = inputToSendToLP * collapseFee / 10000; // Assuming collapseFee is in basis points (e.g., 100 = 1%)
            if (feeAmount > inputToSendToLP) {
                 feeAmount = inputToSendToLP; // Cap fee
            }
            protocolFees[order.inputToken] += feeAmount; // Collect fee
            inputToSendToLP -= feeAmount; // Amount remaining for LP
        }
         // Ensure remaining inputToSendToLP is not negative (shouldn't be with cap)
        if (inputToSendToLP > 0) {
             IERC20(order.inputToken).transfer(matchingOffer.provider, inputToSendToLP);
        }


        // 4. Update statuses
        order.status = OrderStatus.COLLAPSED;
        order.executedOutcomeIndex = _outcomeIndex;

        matchingOffer.status = OfferStatus.FILLED;
        // Note: We don't adjust the offer's outputAmount/requiredInputAmount because it's marked FILLED.
        // If partial filling were allowed, this would be more complex.

        // Remove the filled offer from the active list for its condition hash
        _removeOfferIdFromConditionList(matchingOffer.conditionHash, matchingOfferId);

         // Remove the collapsed order from pendingListsByCondition
         for (uint i = 0; i < order.outcomes.length; i++) {
             bytes32 conditionHash = order.outcomes[i].conditionHash;
              uint256[] storage orderIds = pendingOrdersByCondition[conditionHash];
             for (uint j = 0; j < orderIds.length; j++) {
                 if (orderIds[j] == _orderId) {
                      orderIds[j] = orderIds[orderIds.length - 1];
                      orderIds.pop();
                      break; // Assuming order IDs are unique in the list
                 }
             }
         }


        emit QuantumSwapCollapsed(_orderId, order.user, _outcomeIndex, outputToSend, feeAmount);
        emit ConditionalLiquidityFilled(matchingOfferId, _orderId, order.user);
    }

    // --- User (Liquidity Provider) Functions ---

    /**
     * @notice Allows an LP to add conditional liquidity.
     * @param _outputToken The token the LP is offering.
     * @param _outputAmount The amount of output token offered.
     * @param _inputToken The token the LP requires in exchange.
     * @param _requiredInputAmount The total amount of input token required for the _outputAmount offered.
     * @param _condition The condition under which this offer is valid.
     */
    function addConditionalLiquidity(
        address _outputToken,
        uint256 _outputAmount,
        address _inputToken,
        uint256 _requiredInputAmount,
        Condition calldata _condition
    ) external nonReentrant whenNotPaused {
        require(supportedTokens[_outputToken], "Output token not supported");
        require(supportedTokens[_inputToken], "Input token not supported");
        require(_outputAmount > 0, "Output amount must be greater than 0");
        require(_requiredInputAmount > 0, "Required input amount must be greater than 0");
        // Add checks for condition data validity if necessary

        uint256 currentOfferId = offerCounter++;
        ConditionalLiquidityOffer storage newOffer = conditionalLiquidityOffers[currentOfferId];

        newOffer.provider = msg.sender;
        newOffer.outputToken = _outputToken;
        newOffer.outputAmount = _outputAmount;
        newOffer.inputToken = _inputToken;
        newOffer.requiredInputAmount = _requiredInputAmount;
        newOffer.condition = _condition;
        newOffer.conditionHash = _hashCondition(_condition);
        newOffer.status = OfferStatus.ACTIVE;
        newOffer.createdBlock = uint64(block.number);

        // Transfer output tokens from the LP to the contract
        IERC20(_outputToken).transferFrom(msg.sender, address(this), _outputAmount);

        offersByProvider[msg.sender].push(currentOfferId);
        activeOffersByCondition[newOffer.conditionHash].push(currentOfferId); // Add to active list for lookup

        emit ConditionalLiquidityAdded(currentOfferId, msg.sender, _outputToken, _outputAmount, newOffer.conditionHash);
    }

    /**
     * @notice Allows an LP to remove their active conditional liquidity offer.
     * @param _offerId The ID of the offer to remove.
     */
    function removeConditionalLiquidity(uint256 _offerId) external nonReentrant whenNotPaused {
        ConditionalLiquidityOffer storage offer = conditionalLiquidityOffers[_offerId];
        require(offer.provider == msg.sender, "Not your offer");
        require(offer.status == OfferStatus.ACTIVE, "Offer is not active");
        // Could potentially add a time lock or condition lock before removal is possible

        // Return output tokens to the LP
        IERC20(offer.outputToken).transfer(offer.provider, offer.outputAmount);

        // Update status
        offer.status = OfferStatus.CANCELLED;

        // Remove offer ID from activeOffersByCondition list
        _removeOfferIdFromConditionList(offer.conditionHash, _offerId);

        emit ConditionalLiquidityRemoved(_offerId, msg.sender);
    }

    // --- View Functions ---

    function getOrderDetails(uint256 _orderId) external view returns (QuantumSwapOrder memory) {
        // Note: This returns a copy of the struct from storage.
        // Modifications to the returned struct won't affect state.
        return quantumSwapOrders[_orderId];
    }

    function getOrdersByUser(address _user) external view returns (uint256[] memory) {
        // Note: This can be gas-intensive if a user has many orders.
        // In a production system, consider pagination or returning a limited number.
        return ordersByUser[_user];
    }

    function getPendingOrdersForCondition(bytes32 _conditionHash) external view returns (uint256[] memory) {
        // Note: Can be gas-intensive.
        return pendingOrdersByCondition[_conditionHash];
    }

     function getPossibleOutcomes(uint256 _orderId) external view returns (SwapOutcome[] memory) {
        QuantumSwapOrder storage order = quantumSwapOrders[_orderId];
        require(order.status != OrderStatus.COLLAPSED, "Order is already collapsed");
        return order.outcomes;
    }

    function getCollapsedOutcome(uint256 _orderId) external view returns (SwapOutcome memory, uint256 outcomeIndex) {
        QuantumSwapOrder storage order = quantumSwapOrders[_orderId];
        require(order.status == OrderStatus.COLLAPSED, "Order is not collapsed");
        require(order.executedOutcomeIndex < order.outcomes.length, "Invalid executed outcome index");
        return (order.outcomes[order.executedOutcomeIndex], order.executedOutcomeIndex);
    }


    function getConditionalLiquidityOfferDetails(uint256 _offerId) external view returns (ConditionalLiquidityOffer memory) {
        return conditionalLiquidityOffers[_offerId];
    }

    function getConditionalLiquidityOffersByUser(address _user) external view returns (uint256[] memory) {
         // Note: Can be gas-intensive.
        return offersByProvider[_user];
    }

    function getConditionalOffersForCondition(bytes32 _conditionHash) external view returns (uint256[] memory) {
         // Note: Can be gas-intensive. This returns ACTIVE offers based on the _removeOfferIdFromConditionList logic.
        return activeOffersByCondition[_conditionHash];
    }

    function getContractTokenBalance(address _token) external view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

     function getSupportedTokens() external view returns (address[] memory) {
        // Note: Simple implementation. In production, maintain a dynamic array or iterable mapping.
        // This will return all potential token addresses including removed ones, initialized to false.
        // A better approach for 'view' is to iterate over keys if possible or maintain a separate list.
        // For demonstration, we'll return the addresses we know might have `true`.
        // A more realistic approach needs a separate array populated in add/remove.
        // Let's add a state variable for supported tokens list.

        // Re-structuring to maintain a list for supported tokens view function
        // (This change impacts state variables and add/remove functions)
        // Adding: address[] private _supportedTokensList;
        // In add: _supportedTokensList.push(_token);
        // In remove: Need to find index and remove from _supportedTokensList.

        // For *this* code example, let's just return the *mapping keys* we know about,
        // or acknowledge the limitation and suggest a better pattern for production.
        // Let's add a temporary list tracking.
        // Better approach would use IterableMapping or manually manage an array.
        // Given the constraint to *avoid* open source patterns if possible, let's
        // manually manage a dynamic array for supported tokens.
        // (Implementing this change now in state variables and add/remove funcs)

        // --- (Revisiting State Variables and Admin Functions based on this) ---
        // We now have:
        // mapping(address => bool) public supportedTokens;
        // address[] private _supportedTokensList; // <-- Added this

        // `addSupportedToken`:
        // supportedTokens[_token] = true;
        // _supportedTokensList.push(_token); // <-- Add here

        // `removeSupportedToken`:
        // supportedTokens[_token] = false; // Mark as unsupported
        // // Need to remove from _supportedTokensList. This is inefficient in arrays.
        // // For simplicity in this example, let's leave the item in the list but rely on the mapping check.
        // // This means getSupportedTokens might return tokens that are technically unsupported but still in the list.
        // // Or we iterate and build a new list. Iterating is feasible for a view function.

        uint256 count = 0;
        for(uint i = 0; i < _supportedTokensList.length; i++) {
            if(supportedTokens[_supportedTokensList[i]]) {
                count++;
            }
        }

        address[] memory currentlySupported = new address[](count);
        uint256 current = 0;
         for(uint i = 0; i < _supportedTokensList.length; i++) {
            if(supportedTokens[_supportedTokensList[i]]) {
                currentlySupported[current] = _supportedTokensList[i];
                current++;
            }
        }
        return currentlySupported;
    }

     // Adding `_supportedTokensList` state variable and modifying admin functions as decided above.
     address[] private _supportedTokensList; // Track order of supported tokens for view function

     // Modify addSupportedToken
     function addSupportedToken(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(!supportedTokens[_token], "Token already supported");
        supportedTokens[_token] = true;
        _supportedTokensList.push(_token); // Add to the list
        emit TokenSupported(_token, true);
    }

    // Modify removeSupportedToken
     function removeSupportedToken(address _token) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");
        supportedTokens[_token] = false; // Mark as unsupported
        // Removing from _supportedTokensList in place is complex/gas heavy.
        // The `getSupportedTokens` view function will filter based on the mapping.
        // We won't remove from _supportedTokensList directly here for simplicity,
        // accepting that the list might contain 'false' entries that are filtered in the getter.
        emit TokenSupported(_token, false);
    }
    // End of modification due to getSupportedTokens requirement.

    function getProtocolFees(address _token) external view returns (uint256) {
        return protocolFees[_token];
    }

    // Total function count check:
    // Constructor: 1
    // Admin: 7 (setOracle, addSupported, removeSupported, setCollapseFee, withdrawFees, pause, unpause)
    // Swapper: 7 (create, cancel, collapse, getOrder, getOrdersByUser, getPossibleOutcomes, getCollapsedOutcome)
    // LP: 3 (addLiquidity, removeLiquidity, getOffersByUser)
    // View: 6 (getOrder, getOrdersByUser, getPendingOrdersForCondition, getPossibleOutcomes, getCollapsedOutcome, getOfferDetails, getOffersByUser, getOffersForCondition, getTokenBalance, getSupported, getFees)
    // Helper: 2 (_hashCondition, _isConditionMet)

    // Let's count public/external functions:
    // constructor: 1
    // Admin: 7
    // Swapper: 3 (create, cancel, collapse) + 4 (getOrder, getOrdersByUser, getPossibleOutcomes, getCollapsedOutcome - views) = 7
    // LP: 2 (addLiquidity, removeLiquidity) + 2 (getOfferDetails, getOffersByUser - views) = 4
    // General Views: 3 (getPendingOrdersForCondition, getOffersForCondition, getTokenBalance, getSupportedTokens, getProtocolFees)

    // Total external/public count: 1 + 7 + 3 + 2 + 4 + 3 = 20. Yes, 20 public/external functions.

}
```

---

**Explanation of Advanced Concepts Used:**

1.  **Conditional Execution & Multi-State Orders (Quantum Analogy):** The core concept. Orders aren't simple A->B swaps. They have multiple potential A->B outcomes, each contingent on a specific condition. The order is effectively in a "superposition" of these outcomes until one condition is met, causing the state to "collapse" to that specific outcome.
2.  **Oracle Dependency:** The contract relies on an external oracle (`IConditionOracle`) to determine if a condition is met. This is crucial for bringing real-world or complex on-chain data (like specific contract states or aggregated price feeds) into the swap logic.
3.  **Conditional Liquidity:** LPs don't just provide liquidity to a general pool. They provide liquidity *tied to a specific condition*. This allows LPs to express views on future events or prices, only putting their capital at risk if their anticipated condition is met.
4.  **Matching Engine (Simplified):** The `collapseQuantumSwap` function includes a basic mechanism to find a matching LP offer for the met condition and required amounts. A production system might need a more sophisticated, potentially off-chain but verifiable, matching engine.
5.  **Executor Pattern:** The `collapseQuantumSwap` function is callable by *anyone*. This allows for a decentralized execution layer. An incentivized "executor" could monitor conditions and call `collapseQuantumSwap` when a condition is met to earn a small fee (`collapseFee`), ensuring orders are finalized without relying solely on the user or LP.
6.  **Dynamic Condition Definition:** The `Condition` struct and the use of `bytes calldata _conditionData` passed to the oracle allow for flexibility in the *type* and *parameters* of conditions that can be used, as long as the oracle supports interpreting the data.
7.  **Hashing for Condition Linking:** Using `_hashCondition` provides a standardized way to link orders and liquidity offers that depend on the *same* specific set of condition parameters, enabling efficient lookup via mappings like `pendingOrdersByCondition` and `activeOffersByCondition`.

This contract goes beyond simple AMM swaps by introducing conditional logic and separating the initial order creation from the final execution based on external factors, enabling more expressive and potentially more complex trading strategies directly on-chain.