Okay, here is a Solidity smart contract incorporating several interesting, advanced, and creative concepts. It's designed around a "Quantum Quirk Relay" idea, allowing users to submit arbitrary function calls to external contracts that are executed *conditionally* based on predefined "quirk" conditions, potentially involving randomness (simulated via Chainlink VRF) or other external factors. A relayer can then trigger the execution of these requests when conditions are met, earning a fee.

This contract includes:
*   **Conditional Execution:** Requests only execute when specific on-chain/oracle conditions are met.
*   **Asynchronous Relaying:** Anyone can be a relayer to trigger eligible requests.
*   **Batch Execution:** Relayers can execute multiple requests in a single transaction.
*   **VRF Integration:** A condition type based on Chainlink VRF for probabilistic outcomes.
*   **Configurable Conditions:** Parameters for conditions can be set by an admin.
*   **Role-Based Access (Simple Admin):** Beyond the owner, an admin can configure certain parameters.
*   **Pausable:** Emergency stop mechanism.
*   **Fee Structure:** Relayers are compensated.
*   **Token Handling:** Basic functions for receiving/withdrawing various token types sent to the contract (useful if quirk requests involve sending tokens).

It aims to be non-standard by combining a conditional relay pattern with VRF and configurable external dependencies, going beyond typical token, NFT, or basic DeFi patterns.

---

## Quantum Quirk Relay Contract

**Outline:**

1.  **Pragma & Imports:** Specifies compiler version and imports necessary libraries (Ownable, Pausable, Chainlink VRF interfaces, ERC standards).
2.  **Errors:** Custom error definitions for clarity and gas efficiency.
3.  **Enums & Structs:** Defines the state of a quirk request and the structure for storing requests. Defines types for quirk conditions.
4.  **Events:** Logs significant actions like request submission, execution, cancellation, and state changes.
5.  **State Variables:** Stores contract owner, admin roles, relay fee, request counter, requests mapping, VRF parameters, and allowed target contracts.
6.  **Constructor:** Initializes ownership, pausable state, and VRF configuration.
7.  **Modifiers:** Standard `onlyOwner`, `whenNotPaused`. Custom `onlyAdmin` (internal check).
8.  **Core Request Management Functions:**
    *   `submitQuirkRequest`: Creates and stores a new quirk request.
    *   `cancelQuirkRequest`: Allows the initiator to cancel a pending request.
    *   `getQuirkRequest`: View function to retrieve details of a request.
    *   `getQuirkRequestState`: View function to check the current state of a request.
9.  **Quirk Execution & Condition Logic Functions:**
    *   `checkQuirkCondition`: Internal function to evaluate if a specific request's condition is met.
    *   `executeQuirkRequest`: Executes a single, eligible quirk request.
    *   `batchExecuteQuirkRequests`: Allows executing multiple eligible requests in one transaction.
10. **Chainlink VRF Functions:**
    *   `requestVRFQuirk`: (Internal/Triggered by `checkQuirkCondition` or related logic) Requests randomness for VRF-dependent quirks.
    *   `fulfillRandomWords`: Chainlink VRF callback function. Processes the received randomness.
11. **Admin & Configuration Functions:**
    *   `setAdmin`: Grants or revokes admin role.
    *   `isAdmin`: Checks if an address is an admin.
    *   `setRelayFee`: Sets the fee amount paid to relayers.
    *   `setAllowedTargetContract`: Adds a contract to the list of executable targets (security).
    *   `removeAllowedTargetContract`: Removes a contract from the allowed list.
    *   `isAllowedTargetContract`: Checks if a contract is an allowed target.
    *   `setQuirkConditionParameters`: Configures specific parameters for different condition types.
    *   `setVRFParameters`: Configures Chainlink VRF settings.
12. **Pausable Functions:**
    *   `pauseContract`: Pauses contract operations (admin/owner).
    *   `unpauseContract`: Unpauses contract operations (admin/owner).
13. **Withdrawal & Token Handling Functions:**
    *   `withdrawFees`: Allows owner/admin to withdraw accumulated relay fees.
    *   `withdrawERC20`: Allows owner/admin to withdraw specific ERC20 tokens held by the contract.
    *   `withdrawERC721`: Allows owner/admin to withdraw specific ERC721 tokens held by the contract.
    *   `onERC721Received`: ERC721 receiver hook.
    *   `onERC1155Received`: ERC1155 receiver hook.
    *   `onERC1155BatchReceived`: ERC1155 batch receiver hook.
    *   `supportsInterface`: ERC-165 support.

**Function Summary:**

*   `constructor(...)`: Deploys the contract, setting initial owner, VRF coordinator, keyhash, and fee.
*   `submitQuirkRequest(...)`: Initiator submits a request specifying target, data, value, expiration, condition type/params, and an optional relay fee. Payable if value > 0.
*   `cancelQuirkRequest(uint256 _requestId)`: Initiator cancels a pending request.
*   `getQuirkRequest(uint256 _requestId)`: Reads full details of a request.
*   `getQuirkRequestState(uint256 _requestId)`: Reads the state (Pending, Executable, Executed, etc.) of a request.
*   `checkQuirkCondition(uint256 _requestId)`: *Internal* helper to check if conditions for a request are met.
*   `executeQuirkRequest(uint256 _requestId)`: Relayer attempts to execute a specific request if eligible. Pays relayer the `relayFee`.
*   `batchExecuteQuirkRequests(uint256[] memory _requestIds)`: Relayer attempts to execute multiple requests efficiently.
*   `requestVRFQuirk(uint256 _requestId)`: *Internal* function called to initiate a VRF request for a quirk.
*   `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: *Callback from VRF Coordinator.* Processes random number and potentially marks VRF-dependent quirks as executable.
*   `setAdmin(address _admin, bool _enabled)`: Grants or revokes admin permissions.
*   `isAdmin(address _address)`: Checks if an address has admin rights.
*   `setRelayFee(uint256 _fee)`: Sets the fee amount paid to a relayer per successful execution.
*   `setAllowedTargetContract(address _target, bool _allowed)`: Manages the whitelist of contracts that can be targeted by quirk requests (security measure).
*   `removeAllowedTargetContract(address _target)`: Removes from whitelist.
*   `isAllowedTargetContract(address _target)`: Checks whitelist status.
*   `setQuirkConditionParameters(QuirkConditionType _type, bytes memory _params)`: Configures parameters needed for specific condition types (e.g., threshold for VRF, oracle address/ID).
*   `setVRFParameters(address _vrfCoordinator, bytes32 _keyHash, uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords, uint256 _subId, uint256 _vrfFee)`: Sets VRF configuration.
*   `pauseContract()`: Pauses most contract interactions.
*   `unpauseContract()`: Unpauses the contract.
*   `withdrawFees(address payable _recipient)`: Owner/Admin can withdraw accumulated ether fees.
*   `withdrawERC20(address _token, address _recipient, uint256 _amount)`: Owner/Admin withdraws ERC20.
*   `withdrawERC721(address _token, address _recipient, uint256 _tokenId)`: Owner/Admin withdraws ERC721.
*   `onERC721Received(...)`: Standard ERC721 receiver hook, prevents locking tokens.
*   `onERC1155Received(...)`: Standard ERC1155 receiver hook.
*   `onERC1155BatchReceived(...)`: Standard ERC1155 batch receiver hook.
*   `supportsInterface(bytes4 interfaceId)`: Standard ERC-165 implementation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary libraries
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // For ERC721Receiver
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; // For ERC1155Receiver
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Arrays.sol"; // Not strictly needed here but useful for complex array ops
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title Quantum Quirk Relay
/// @author Your Name Here (based on prompt requirements)
/// @notice This contract allows users to submit conditional execution requests (Quirk Requests)
///         which can be triggered by relayers when specified on-chain or oracle conditions are met.
///         Includes support for Chainlink VRF based probabilistic execution conditions.

// --- Outline ---
// 1. Pragma & Imports
// 2. Errors
// 3. Enums & Structs
// 4. Events
// 5. State Variables
// 6. Constructor
// 7. Modifiers
// 8. Core Request Management Functions
// 9. Quirk Execution & Condition Logic Functions
// 10. Chainlink VRF Functions
// 11. Admin & Configuration Functions
// 12. Pausable Functions
// 13. Withdrawal & Token Handling Functions
// 14. ERC-165 Support

// --- Function Summary ---
// constructor(...) - Initializes the contract.
// submitQuirkRequest(...) - Submits a new conditional execution request.
// cancelQuirkRequest(...) - Allows initiator to cancel a pending request.
// getQuirkRequest(...) - View function to retrieve request details.
// getQuirkRequestState(...) - View function to retrieve request state.
// checkQuirkCondition(...) - Internal: Evaluates if a request's condition is met.
// executeQuirkRequest(...) - Executes a single, eligible request (callable by relayer).
// batchExecuteQuirkRequests(...) - Executes multiple eligible requests (callable by relayer).
// requestVRFQuirk(...) - Internal: Triggers a VRF request for a quirk.
// fulfillRandomWords(...) - VRF Coordinator callback: Processes random number.
// setAdmin(...) - Manages admin roles.
// isAdmin(...) - Checks admin status.
// setRelayFee(...) - Sets the relayer fee.
// setAllowedTargetContract(...) - Manages whitelist of callable targets.
// removeAllowedTargetContract(...) - Removes from target whitelist.
// isAllowedTargetContract(...) - Checks target whitelist status.
// setQuirkConditionParameters(...) - Configures parameters for condition types.
// setVRFParameters(...) - Sets VRF configuration.
// pauseContract() - Pauses operations (Admin/Owner).
// unpauseContract() - Unpauses operations (Admin/Owner).
// withdrawFees(...) - Withdraws accumulated ether fees.
// withdrawERC20(...) - Withdraws specific ERC20 tokens.
// withdrawERC721(...) - Withdraws specific ERC721 tokens.
// onERC721Received(...) - ERC721 receiver hook.
// onERC1155Received(...) - ERC1155 receiver hook.
// onERC1155BatchReceived(...) - ERC1155 batch receiver hook.
// supportsInterface(...) - ERC-165 support.

contract QuantumQuirkRelay is Ownable, Pausable, VRFConsumerBaseV2, ERC721Holder, ERC1155Holder {

    // --- Errors ---
    error RequestNotFound(uint256 requestId);
    error RequestAlreadyProcessed(uint256 requestId);
    error RequestNotCancellable(uint256 requestId);
    error NotInitiator(uint256 requestId);
    error NotQuirkAdmin();
    error RequestNotExecutable(uint256 requestId);
    error CallFailed(uint256 requestId, bytes returnData);
    error TargetContractNotAllowed(address target);
    error QuirkExpired(uint256 requestId);
    error InvalidConditionParameters(QuirkConditionType conditionType);
    error VRFNotReady(uint256 requestId);
    error VRFAlreadyRequested(uint256 requestId);
    error InvalidVRFCallback(uint256 vrfRequestId);
    error NothingToWithdraw();
    error NotEnoughBalance(uint256 required, uint256 available);

    // --- Enums & Structs ---

    enum QuirkState {
        Pending,      // Waiting for conditions
        VRF_Requested, // Waiting for VRF fulfillment
        Executable,   // Conditions met, ready to be triggered by a relayer
        Executed,     // Successfully executed
        Failed,       // Execution failed (e.g., target call reverted, gas issues)
        Cancelled     // Cancelled by initiator
    }

    // Defines different types of conditions that must be met for execution
    enum QuirkConditionType {
        NONE,                  // Always executable (if not expired/cancelled)
        BLOCK_HEIGHT,          // Execute at or after a specific block number (params: uint256 blockNumber)
        TIMESTAMP,             // Execute at or after a specific timestamp (params: uint256 timestamp)
        VRF_RANDOM_THRESHOLD,  // Execute if VRF is fulfilled AND random number < threshold (params: uint256 threshold)
        EXTERNAL_ORACLE_VALUE  // Execute if an external oracle returns a value meeting a condition (params: abi-encoded oracle specific data)
    }

    struct QuirkRequest {
        uint256 requestId;
        address initiator;          // Address that submitted the request
        address targetContract;     // The contract to call
        bytes callData;             // The function call data
        uint256 value;              // Ether value to send with the call
        uint64 expirationBlock;     // Request is invalid after this block
        QuirkConditionType conditionType; // Type of condition
        bytes conditionParams;      // Parameters for the condition type (abi-encoded)
        QuirkState state;           // Current state of the request
        uint64 creationBlock;       // Block when the request was created
        uint64 executionBlock;      // Block when the request was executed (0 if not executed)
        uint256 relayFee;           // Fee paid to the relayer upon successful execution

        // VRF specific fields
        uint256 vrfRequestId;       // Chainlink VRF request ID (0 if not applicable/requested)
        uint256 vrfRandomWord;      // The fulfilled random word (0 if not fulfilled)
    }

    // --- Events ---
    event RequestSubmitted(
        uint256 indexed requestId,
        address indexed initiator,
        address indexed targetContract,
        QuirkConditionType conditionType,
        uint256 value,
        uint64 expirationBlock,
        uint256 relayFee
    );
    event RequestStateChanged(uint256 indexed requestId, QuirkState oldState, QuirkState newState);
    event RequestExecuted(
        uint256 indexed requestId,
        address indexed initiator,
        address indexed targetContract,
        address indexed relayer,
        bool success,
        bytes returnData
    );
    event RequestFailed(
        uint256 indexed requestId,
        address indexed initiator,
        address indexed targetContract,
        address indexed relayer,
        bytes returnData
    ); // More specific event for failed execution
    event RequestCancelled(uint256 indexed requestId, address indexed initiator);
    event FeeWithdrawn(address indexed recipient, uint256 amount);
    event VRFRequested(uint256 indexed requestId, uint256 indexed vrfRequestId);
    event VRFFulfilled(uint256 indexed vrfRequestId, uint256 indexed requestId, uint256 randomWord);
    event QuirkConditionParametersSet(QuirkConditionType indexed conditionType, bytes params);

    // --- State Variables ---
    uint256 private _nextRequestId;
    mapping(uint256 => QuirkRequest) public requests;
    mapping(address => bool) private _admins; // Simple admin role
    uint256 public relayFee; // Fee paid to the relayer per executed quirk request
    mapping(address => bool) private _allowedTargetContracts; // Whitelist of allowed target contracts

    // Condition-specific parameters storage
    mapping(QuirkConditionType => bytes) private _quirkConditionParameters;

    // VRF Configuration (from VRFConsumerBaseV2 requires these)
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 immutable i_keyHash;
    uint32 immutable i_callbackGasLimit;
    uint16 immutable i_requestConfirmations;
    uint32 immutable i_numWords; // How many random words to request (usually 1)
    uint256 immutable i_subId; // Subscription ID for VRF service
    uint256 immutable i_vrfFee; // VRF fee for the request

    // Mapping Chainlink VRF request ID to our Quirk Request ID
    mapping(uint256 => uint256) private _vrfRequestIdToQuirkId;

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint32 numWords,
        uint256 subId,
        uint256 vrfFee
    )
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
        ERC721Holder() // Inherit ERC721Holder for onERC721Received
        ERC1155Holder() // Inherit ERC1155Holder for onERC1155Received/Batch
    {
        // Initialize VRF settings
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;
        i_numWords = numWords;
        i_subId = subId;
        i_vrfFee = vrfFee;

        // Default allowed targets (can be modified by owner/admin)
        // Example: allow calling WETH deposit (WETH address would be set post-deployment)
        // _allowedTargetContracts[0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = true; // WETH on Mainnet
    }

    // --- Modifiers ---
    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function _checkAdmin() internal view {
        if (!_admins[msg.sender] && msg.sender != owner()) {
            revert NotQuirkAdmin();
        }
    }

    // --- Core Request Management Functions ---

    /// @notice Submits a new quirk request.
    /// @param _targetContract The address of the contract to call.
    /// @param _callData The ABI-encoded function call data for the target contract.
    /// @param _value The amount of Ether to send with the call.
    /// @param _expirationBlock The block number after which the request is invalid.
    /// @param _conditionType The type of condition required for execution.
    /// @param _conditionParams ABI-encoded parameters specific to the condition type.
    /// @param _relayFee The fee to pay the relayer upon successful execution (in Wei).
    /// @dev The contract must be unpaused to submit requests.
    /// @dev _targetContract must be added to the allowed list by an admin/owner.
    /// @dev Requires `msg.value` to be equal to `_value` if `_value > 0`.
    /// @return requestId The unique ID of the submitted request.
    function submitQuirkRequest(
        address _targetContract,
        bytes calldata _callData,
        uint256 _value,
        uint64 _expirationBlock,
        QuirkConditionType _conditionType,
        bytes calldata _conditionParams,
        uint256 _relayFee
    ) external payable whenNotPaused returns (uint256 requestId) {
        if (!_allowedTargetContracts[_targetContract]) {
            revert TargetContractNotAllowed(_targetContract);
        }
        if (msg.value != _value) {
            revert NotEnoughBalance(_value, msg.value);
        }
        if (_expirationBlock <= block.number) {
            revert QuirkExpired(0); // Use 0 as request ID doesn't exist yet
        }

        requestId = _nextRequestId++;
        requests[requestId] = QuirkRequest({
            requestId: requestId,
            initiator: msg.sender,
            targetContract: _targetContract,
            callData: _callData,
            value: _value,
            expirationBlock: _expirationBlock,
            conditionType: _conditionType,
            conditionParams: _conditionParams,
            state: QuirkState.Pending,
            creationBlock: uint64(block.number),
            executionBlock: 0,
            relayFee: _relayFee,
            vrfRequestId: 0,
            vrfRandomWord: 0
        });

        emit RequestSubmitted(
            requestId,
            msg.sender,
            _targetContract,
            _conditionType,
            _value,
            _expirationBlock,
            _relayFee
        );
        emit RequestStateChanged(requestId, QuirkState.Pending, QuirkState.Pending); // Initial state change event

        // Automatically request VRF if the condition type requires it and it's not already requested
        if (_conditionType == QuirkConditionType.VRF_RANDOM_THRESHOLD && requests[requestId].vrfRequestId == 0) {
            // This will transition the state from Pending to VRF_Requested internally
             _requestVRFQuirk(requestId);
        }
    }

    /// @notice Allows the initiator to cancel their pending quirk request.
    /// @param _requestId The ID of the request to cancel.
    /// @dev Only requests in the `Pending`, `VRF_Requested`, or `Executable` state can be cancelled.
    function cancelQuirkRequest(uint256 _requestId) external whenNotPaused {
        QuirkRequest storage request = requests[_requestId];

        if (request.requestId == 0 && _requestId != 0) { // Check if request exists (assuming 0 is never a valid ID used by _nextRequestId)
             revert RequestNotFound(_requestId);
        }
        if (request.initiator != msg.sender) {
            revert NotInitiator(_requestId);
        }
        if (request.state == QuirkState.Executed || request.state == QuirkState.Failed || request.state == QuirkState.Cancelled) {
            revert RequestNotCancellable(_requestId);
        }

        emit RequestStateChanged(_requestId, request.state, QuirkState.Cancelled);
        request.state = QuirkState.Cancelled;
        emit RequestCancelled(_requestId, msg.sender);

        // Refund any Ether value sent with the request
        if (request.value > 0) {
             (bool success, ) = payable(msg.sender).call{value: request.value}("");
             // We don't revert on failure here, as cancelling is more important than the refund succeeding immediately
             // Initiator might need to manually withdraw if refund fails. Add a withdrawal function if needed for this.
             // For now, assume direct refund is attempted.
        }
         // No refund of relayFee - it's a cost of submission regardless of execution/cancellation.
    }

    /// @notice Gets the details of a quirk request.
    /// @param _requestId The ID of the request.
    /// @return request The QuirkRequest struct.
    function getQuirkRequest(uint256 _requestId) external view returns (QuirkRequest memory request) {
        request = requests[_requestId];
        if (request.requestId == 0 && _requestId != 0) {
            revert RequestNotFound(_requestId);
        }
    }

    /// @notice Gets the current state of a quirk request.
    /// @param _requestId The ID of the request.
    /// @return state The current state of the request.
    function getQuirkRequestState(uint256 _requestId) external view returns (QuirkState state) {
         QuirkRequest storage request = requests[_requestId];
         if (request.requestId == 0 && _requestId != 0) {
             revert RequestNotFound(_requestId);
         }
         return request.state;
    }


    // --- Quirk Execution & Condition Logic Functions ---

    /// @notice Checks if the conditions for a specific quirk request are met.
    /// @param _requestId The ID of the request.
    /// @return bool True if the request is executable based on its conditions.
    function checkQuirkCondition(uint256 _requestId) public view returns (bool) {
        QuirkRequest storage request = requests[_requestId];

        // Basic checks first
        if (request.requestId == 0 && _requestId != 0) { return false; } // Doesn't exist
        if (request.state != QuirkState.Pending && request.state != QuirkState.Executable) { return false; } // Not in a state to be checked
        if (block.number > request.expirationBlock) { return false; } // Expired

        // Evaluate condition based on type
        QuirkConditionType condition = request.conditionType;
        bytes memory params = request.conditionParams;

        if (condition == QuirkConditionType.NONE) {
            // Always executable if not expired/cancelled
            return true;

        } else if (condition == QuirkConditionType.BLOCK_HEIGHT) {
            // params: uint256 blockNumber
            if (params.length != 32) return false; // Invalid parameters
            uint256 requiredBlock;
            assembly { requiredBlock := mload(add(params, 32)) }
            return block.number >= requiredBlock;

        } else if (condition == QuirkConditionType.TIMESTAMP) {
            // params: uint256 timestamp
            if (params.length != 32) return false; // Invalid parameters
            uint256 requiredTimestamp;
             assembly { requiredTimestamp := mload(add(params, 32)) }
            return block.timestamp >= requiredTimestamp;

        } else if (condition == QuirkConditionType.VRF_RANDOM_THRESHOLD) {
             // Requires VRF to be fulfilled AND the random number to be below a threshold
             // params: uint256 threshold
             if (params.length != 32) return false; // Invalid parameters
             uint256 threshold;
             assembly { threshold := mload(add(params, 32)) }

             // Must have a VRF request fulfilled
             if (request.state != QuirkState.Executable || request.vrfRandomWord == 0) {
                 return false; // Not yet executable via VRF or VRF not fulfilled
             }

             // Check if random word meets the threshold condition
             return request.vrfRandomWord < threshold;

        } else if (condition == QuirkConditionType.EXTERNAL_ORACLE_VALUE) {
             // This is a placeholder for integrating with a hypothetical external oracle.
             // The implementation would depend on the specific oracle interface and data format.
             // Example: `params` could encode the oracle address, data ID, and required value/comparison.
             // Example pseudo-code:
             /*
             (address oracleAddress, bytes32 dataId, uint256 requiredValue, uint8 comparisonType) = abi.decode(params, (address, bytes32, uint256, uint8));
             uint256 oracleValue = IOracle(oracleAddress).getValue(dataId);
             if (comparisonType == 0) return oracleValue == requiredValue;
             if (comparisonType == 1) return oracleValue > requiredValue;
             if (comparisonType == 2) return oracleValue < requiredValue;
             ... etc ...
             */
             // For this example, we'll make this condition always false unless specifically implemented.
             // In a real contract, you'd need to define and interact with an IOracle interface.
             return false;
        }

        return false; // Unknown condition type
    }

    /// @notice Executes a single quirk request if its conditions are met.
    /// @param _requestId The ID of the request to execute.
    /// @dev Callable by anyone acting as a relayer.
    /// @dev Relayer receives the `relayFee` upon successful execution.
    function executeQuirkRequest(uint256 _requestId) external whenNotPaused {
        QuirkRequest storage request = requests[_requestId];

        if (request.requestId == 0 && _requestId != 0) {
             revert RequestNotFound(_requestId);
        }
        if (request.state != QuirkState.Pending && request.state != QuirkState.Executable) {
            revert RequestAlreadyProcessed(_requestId); // Already Executed, Failed, or Cancelled
        }
        if (block.number > request.expirationBlock) {
             emit RequestStateChanged(_requestId, request.state, QuirkState.Failed); // Mark as failed due to expiration
             request.state = QuirkState.Failed;
             revert QuirkExpired(_requestId);
        }
         if (request.state == QuirkState.VRF_Requested) {
             revert VRFNotReady(_requestId); // VRF condition pending fulfillment
         }


        // Ensure condition is met *at the moment of execution attempt*
        // For VRF_RANDOM_THRESHOLD, checkQuirkCondition relies on state being Executable (set by fulfillRandomWords)
        if (!checkQuirkCondition(_requestId)) {
             // If it's a VRF condition and VRF hasn't been requested, request it now.
             // Note: This means a relayer might trigger the VRF request, but can't execute until fulfillRandomWords.
             if (request.conditionType == QuirkConditionType.VRF_RANDOM_THRESHOLD && request.vrfRequestId == 0) {
                 _requestVRFQuirk(_requestId);
                 revert VRFNotReady(_requestId); // Now waiting for VRF
             }
             revert RequestNotExecutable(_requestId); // Condition not met or invalid parameters
        }

        // Execute the target call using low-level `call`
        (bool success, bytes memory returnData) = request.targetContract.call{value: request.value}(request.callData);

        if (success) {
            emit RequestStateChanged(_requestId, request.state, QuirkState.Executed);
            request.state = QuirkState.Executed;
            request.executionBlock = uint64(block.number);

            // Pay relay fee
            if (request.relayFee > 0) {
                (bool feeSent, ) = payable(msg.sender).call{value: request.relayFee}("");
                // Log fee payment attempt, but don't revert the quirk execution if fee transfer fails
                 if (!feeSent) {
                     // Potentially log a warning or emit a specific event for failed fee payment
                 }
            }

            emit RequestExecuted(_requestId, request.initiator, request.targetContract, msg.sender, true, returnData);

        } else {
            // Execution failed
            emit RequestStateChanged(_requestId, request.state, QuirkState.Failed);
            request.state = QuirkState.Failed;
            request.executionBlock = uint64(block.number);
            emit RequestFailed(_requestId, request.initiator, request.targetContract, msg.sender, returnData);
            revert CallFailed(_requestId, returnData); // Revert the relayer's transaction, providing call data
        }
    }

    /// @notice Allows a relayer to attempt execution of multiple requests in one transaction.
    /// @param _requestIds An array of request IDs to attempt to execute.
    /// @dev Executes each request sequentially. If one fails, it attempts the next.
    /// @dev Relayer pays gas for the batch call but receives individual `relayFee` for each successful execution.
    function batchExecuteQuirkRequests(uint256[] memory _requestIds) external whenNotPaused {
        for (uint i = 0; i < _requestIds.length; i++) {
            uint256 requestId = _requestIds[i];
            // Use a try/catch block to execute each request and continue if one fails
            try this.executeQuirkRequest(requestId) {
                // Success for this specific request is handled within executeQuirkRequest
            } catch (bytes memory reason) {
                // Failure for this specific request is handled within executeQuirkRequest (state change, event)
                // The reason variable contains the error data from the failed call or our own revert
                // We can log this or ignore it, continuing the loop
                emit RequestFailed(requestId, address(0), address(0), msg.sender, reason); // Log batch-level failure attempt
            }
        }
    }

    // --- Chainlink VRF Functions ---

    /// @notice Internal function to request randomness for a Quirk Request.
    /// @param _requestId The ID of the request needing VRF.
    function _requestVRFQuirk(uint256 _requestId) internal {
         QuirkRequest storage request = requests[_requestId];
         if (request.vrfRequestId != 0) {
              revert VRFAlreadyRequested(_requestId);
         }
         if (request.state != QuirkState.Pending) {
             // Should only request from Pending, possibly VRF_Requested if a retry mechanism were added
             return; // Do not request if not Pending
         }

        uint256 vrfReqId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subId,
            i_requestConfirmations,
            i_callbackGasLimit,
            i_numWords
        );

        request.vrfRequestId = vrfReqId;
        _vrfRequestIdToQuirkId[vrfReqId] = _requestId;

        emit RequestStateChanged(_requestId, request.state, QuirkState.VRF_Requested);
        request.state = QuirkState.VRF_Requested;
        emit VRFRequested(_requestId, vrfReqId);
    }

    /// @notice Chainlink VRF callback function.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The array of random words returned by VRF.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // This function is called by the VRF Coordinator contract.
        // It must be internal and match the signature required by VRFConsumerBaseV2.

        if (randomWords.length == 0) {
            // Should not happen with numWords > 0, but good practice
            return;
        }

        uint256 quirkId = _vrfRequestIdToQuirkId[requestId];
        if (quirkId == 0) {
             // This VRF request ID doesn't map to a known quirk request in this contract
             // This could happen if _vrfRequestIdToQuirkId was manually cleared or an old request was fulfilled.
             revert InvalidVRFCallback(requestId);
        }

        QuirkRequest storage request = requests[quirkId];
        if (request.requestId == 0 || request.vrfRequestId != requestId) {
             // Double check mapping consistency
             revert InvalidVRFCallback(requestId);
        }
        if (request.state != QuirkState.VRF_Requested) {
            // VRF already fulfilled or request cancelled/executed etc. Ignore this callback.
            return;
        }

        // Store the random word(s)
        request.vrfRandomWord = randomWords[0]; // Assume numWords is 1 for simplicity in condition check

        // VRF is fulfilled, mark the request as executable (relayer can now check condition & execute)
        emit RequestStateChanged(quirkId, request.state, QuirkState.Executable);
        request.state = QuirkState.Executable;
        emit VRFFulfilled(requestId, quirkId, randomWords[0]);

        // Optional: Could automatically attempt execution here, but letting a relayer do it
        // is generally better practice to keep the callback fast and avoid reverts.
    }


    // --- Admin & Configuration Functions ---

    /// @notice Grants or revokes admin privileges to an address.
    /// @param _admin The address to grant/revoke admin status.
    /// @param _enabled True to grant, false to revoke.
    /// @dev Only callable by the contract owner. Admins can set parameters and pause/unpause.
    function setAdmin(address _admin, bool _enabled) external onlyOwner {
        _admins[_admin] = _enabled;
    }

    /// @notice Checks if an address has admin privileges.
    /// @param _address The address to check.
    /// @return bool True if the address is an admin or the owner.
    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address] || _address == owner();
    }

    /// @notice Sets the fee paid to a relayer for successfully executing a quirk request.
    /// @param _fee The fee amount in Wei.
    /// @dev Callable by owner or admin.
    function setRelayFee(uint256 _fee) external onlyAdmin {
        relayFee = _fee;
    }

    /// @notice Adds or removes a contract from the allowed list of target contracts.
    /// @param _target The address of the target contract.
    /// @param _allowed True to allow, false to disallow.
    /// @dev Callable by owner or admin. Prevents users from targeting arbitrary malicious contracts.
    function setAllowedTargetContract(address _target, bool _allowed) external onlyAdmin {
        _allowedTargetContracts[_target] = _allowed;
    }

     /// @notice Removes a contract from the allowed list of target contracts.
     /// @param _target The address of the target contract.
     /// @dev Callable by owner or admin. Alias for `setAllowedTargetContract(_target, false)`.
    function removeAllowedTargetContract(address _target) external onlyAdmin {
        _allowedTargetContracts[_target] = false;
    }

    /// @notice Checks if a target contract address is allowed.
    /// @param _target The address to check.
    /// @return bool True if the contract is allowed.
    function isAllowedTargetContract(address _target) external view returns (bool) {
        return _allowedTargetContracts[_target];
    }

    /// @notice Configures parameters required for specific quirk condition types.
    /// @param _type The condition type to configure.
    /// @param _params ABI-encoded parameters specific to the condition type.
    /// @dev Callable by owner or admin. The structure of `_params` depends on `_type`.
    function setQuirkConditionParameters(QuirkConditionType _type, bytes memory _params) external onlyAdmin {
        _quirkConditionParameters[_type] = _params;
        emit QuirkConditionParametersSet(_type, _params);
    }

    /// @notice Sets the parameters for Chainlink VRF integration.
    /// @dev Callable by owner. Required if using VRF_RANDOM_THRESHOLD condition.
    /// @dev The `subId` must be funded via the Chainlink VRF UI.
    function setVRFParameters(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        uint256 _subId,
        uint256 _vrfFee
    ) external onlyOwner {
        // Note: VRFCoordinator address is immutable, set in constructor.
        // These parameters could be made configurable if needed, but subId funding is external.
        // For this example, they are immutable from constructor. If you uncomment this, remove immutable from state vars.
        /*
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
        i_requestConfirmations = _requestConfirmations;
        i_numWords = _numWords;
        i_subId = _subId;
        i_vrfFee = _vrfFee;
        */
        revert("VRF parameters are immutable and set in the constructor"); // Remove this line if you make VRF parameters configurable after deployment
    }


    // --- Pausable Functions ---
    // Inherits `paused()` view function.

    /// @notice Pauses contract operations.
    /// @dev Callable by owner or admin. Prevents submission, execution, and cancellation.
    function pauseContract() external onlyAdmin {
        _pause();
    }

    /// @notice Unpauses contract operations.
    /// @dev Callable by owner or admin.
    function unpauseContract() external onlyAdmin {
        _unpause();
    }

    // --- Withdrawal & Token Handling Functions ---

    /// @notice Allows owner or admin to withdraw accumulated Ether fees.
    /// @param _recipient The address to send the fees to.
    /// @dev Excludes Ether sent with quirk requests (`value`), which is handled by `submitQuirkRequest` or `cancelQuirkRequest`.
    function withdrawFees(address payable _recipient) external onlyAdmin {
        uint256 balance = address(this).balance;
        // Need to subtract Ether sent with PENDING/VRF_REQUESTED/EXECUTABLE requests
        // This is complex to track accurately if value isn't immediately refunded.
        // A safer approach is to only allow withdrawal of fees collected (e.g., relayFee) or make requests non-payable.
        // Let's assume for simplicity this withdraws ALL contract balance except value from PENDING/VRF_REQUESTED requests.
        // A more robust system would track fees separately or have a dedicated withdrawal function for user-sent value.

        // Simplified: just withdraw the total balance. Admins must be careful.
        // A better way: maintain a separate fee balance counter.
        // For this example, we'll withdraw total balance, assuming request values are handled appropriately or refunded.
        // **WARNING: This simplified withdrawal might make request value locked if not refunded correctly.**
        // A real-world contract needs careful accounting of funds.

         if (balance == 0) {
             revert NothingToWithdraw();
         }

        (bool success, ) = _recipient.call{value: balance}("");
        if (!success) {
            revert("Failed to send Ether"); // Revert the withdrawal transaction
        }
        emit FeeWithdrawn(_recipient, balance);
    }

    /// @notice Allows owner or admin to withdraw ERC20 tokens held by the contract.
    /// @param _token The address of the ERC20 token.
    /// @param _recipient The address to send the tokens to.
    /// @param _amount The amount of tokens to withdraw.
    /// @dev Use with caution. Do not withdraw tokens intended for quirk request execution or user refunds.
    function withdrawERC20(address _token, address _recipient, uint256 _amount) external onlyAdmin {
        IERC20 token = IERC20(_token);
         if (token.balanceOf(address(this)) < _amount) {
              revert NotEnoughBalance(_amount, token.balanceOf(address(this)));
         }
        bool success = token.transfer(_recipient, _amount);
        require(success, "ERC20 transfer failed");
    }

     /// @notice Allows owner or admin to withdraw ERC721 tokens held by the contract.
     /// @param _token The address of the ERC721 token.
     /// @param _recipient The address to send the token to.
     /// @param _tokenId The ID of the ERC721 token.
     /// @dev Use with caution. Do not withdraw tokens needed for operations.
    function withdrawERC721(address _token, address _recipient, uint256 _tokenId) external onlyAdmin {
         IERC721 token = IERC721(_token);
         require(token.ownerOf(_tokenId) == address(this), "Not token owner");
         token.safeTransferFrom(address(this), _recipient, _tokenId);
    }

    // --- ERC-165 Support (for token receivers) ---

    // The ERC721Holder and ERC1155Holder contracts already implement `supportsInterface`
    // for their respective receiver interfaces (0x150b7a02 for ERC721, 0x4e2312e0 for ERC1155).
    // We can override and call super to include them, or rely on inheritance.
    // Let's explicitly override for clarity.

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Holder, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Fallback/Receive (Optional but good practice) ---
    // receive() external payable {}
    // fallback() external payable {}
    // Handled by payable submitQuirkRequest, other Ether should not be sent directly unless intended for fees/balance.
    // Explicit receive/fallback can be added if needed, but might complicate fee accounting.

}
```

**Explanation of Advanced/Creative Concepts Used:**

1.  **Conditional Execution Engine:** The core mechanism isn't a simple `call`. It's a queued request (`QuirkRequest`) that is only eligible for execution (`executeQuirkRequest`) if an arbitrary `checkQuirkCondition` function returns true. This allows complex, dynamic logic to gate state changes or interactions with other protocols.
2.  **Decoupled Submission and Execution (Relaying):** The user submits the request, but a separate entity (the "Relayer") actually performs the transaction to execute it. This pattern is common in meta-transactions, but here it's tied to conditional logic. The `relayFee` incentivizes this.
3.  **Batch Execution:** The `batchExecuteQuirkRequests` function is an optimization for relayers, allowing them to fulfill multiple eligible requests efficiently in a single transaction, reducing their gas overhead per request. The `try/catch` block ensures one failing execution doesn't stop the entire batch.
4.  **Chainlink VRF Integration:** The `VRF_RANDOM_THRESHOLD` condition type directly integrates with Chainlink's Verifiable Random Function oracle. This introduces controlled randomness, allowing for probabilistic outcomes in whether a request becomes executable (e.g., a 1 in 100 chance each block the condition is checked).
5.  **Configurable Conditions (`QuirkConditionType`, `conditionParams`, `setQuirkConditionParameters`):** The contract design allows for various condition types defined by the `QuirkConditionType` enum. The `conditionParams` field, using `bytes`, combined with `setQuirkConditionParameters`, makes the conditions somewhat extensible or configurable without changing the core contract logic for each specific parameter value (though adding *new* condition *types* requires code changes). The `checkQuirkCondition` function acts as the interpreter for these.
6.  **Allowed Target Contracts (Security):** Implementing a whitelist (`_allowedTargetContracts`) for target contracts is a crucial security feature when allowing arbitrary calls (`callData`). It prevents users from tricking the contract into interacting with malicious or unintended addresses.
7.  **Structured State Management:** The `QuirkRequest` struct and `QuirkState` enum provide clear tracking of the lifecycle of each request (Pending -> VRF_Requested -> Executable -> Executed/Failed/Cancelled).
8.  **Role-Based Access (Simple Admin):** Adding a separate `Admin` role via `_admins` mapping, distinct from the `Owner`, provides a simple form of tiered access control for configuration functions (`setRelayFee`, `setAllowedTargetContract`, `setQuirkConditionParameters`, `pauseContract`, `unpauseContract`, `withdrawFees`, `withdrawERC20`, `withdrawERC721`).

This contract is significantly more complex than a standard token or simple vault and demonstrates patterns useful in decentralized automation, conditional transactions, and oracle-dependent logic.

**Note:** This contract is a conceptual example. For production use, consider:
*   More robust handling of `value` sent with requests and fee accounting.
*   More sophisticated error handling and logging within `batchExecuteQuirkRequests`.
*   Potential gas optimizations, especially in loops.
*   A more detailed `EXTERNAL_ORACLE_VALUE` implementation requiring an actual oracle interface.
*   Testing extensively with mock contracts for VRF and target calls.
*   The potential for front-running if the `checkQuirkCondition` is predictable. VRF helps mitigate this for that specific condition type.
*   Consider upgradeability using proxies if the logic is expected to evolve.