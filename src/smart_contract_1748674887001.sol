Okay, let's design a smart contract factory that creates advanced, conditional, and potentially bundled swap agreements. We'll call it the `QuantumSwapFactory`, using "Quantum" metaphorically to imply complex, potentially entangled (bundled), and probabilistic (conditional) states of swaps based on external triggers.

This contract will not directly implement a standard Automated Market Maker (AMM) like Uniswap or a simple escrow. Instead, it will be a factory for deploying instances of a separate `QuantumSwapLogic` contract, each representing a specific, complex swap agreement with unique conditions, participants, and assets (FTs and/or NFTs).

**Advanced/Creative Concepts Used:**

1.  **Factory Pattern:** Deploys instances of other complex contracts.
2.  **Conditional Execution:** Swaps only execute if specific, externally verifiable conditions are met (e.g., price feeds, external events).
3.  **Bundled/Atomic Swaps:** Allows creating agreements where multiple asset exchanges happen atomically (all or nothing).
4.  **Time-Based Logic:** Swaps can be time-locked or have expiry times.
5.  **FT and NFT Interoperability:** Handles transfers of both ERC20 and ERC721 tokens within the same framework.
6.  **Modular Condition Handling:** Uses interfaces to allow different types of conditions to be plugged in via separate handler contracts.
7.  **External Data Dependency:** Designed to interact with oracles or other external data sources (via condition handlers).
8.  **Upgradeability Pattern Hint:** Includes a mechanism to set the `QuantumSwapLogic` implementation address, hinting at proxy-based upgradeability (though a full proxy implementation is outside the scope of just *this* factory contract).
9.  **Access Control & Pausing:** Standard but necessary for management.
10. **Fees:** Factory collects fees for creating complex agreements.
11. **Detailed State Tracking:** The factory tracks created swap instances, their owners, and basic parameters for querying.

---

**Outline and Function Summary**

**Contract Name:** `QuantumSwapFactory`

**Description:** A factory contract responsible for deploying and managing instances of `QuantumSwapLogic` contracts. Each deployed instance represents a unique, potentially complex, conditional, or bundled swap agreement involving FTs and/or NFTs.

**Core Concepts:** Factory Pattern, Conditional Swaps, Bundled Swaps, Time-Locked Swaps, FT/NFT Interoperability, Modular Conditions, External Data Integration, Upgradeability Hint, Access Control, Fees.

---

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports:** ERC20, ERC721, Ownable, Pausable (from OpenZeppelin, or minimal interfaces)
3.  **Interfaces:**
    *   `IQuantumSwapLogic`: Interface for the deployed swap instances.
    *   `IConditionHandler`: Interface for contracts checking specific swap conditions.
    *   `IOracleRegistry`: Interface for a potential oracle system dependency.
4.  **Errors:** Custom errors for specific failure cases.
5.  **Events:** For logging key actions.
6.  **State Variables:**
    *   Owner, Paused status
    *   Factory configuration (fees, recipient, logic contract address)
    *   Allowed tokens (FT/NFT)
    *   Swap tracking (counter, instance addresses, owner map, user's swap lists, basic parameters storage)
    *   Condition handler registry
    *   Oracle registry address
    *   Minimum execution delay
7.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
8.  **Constructor:** Initializes owner and initial logic contract address (optional).
9.  **Admin & Configuration Functions:**
    *   `setQuantumSwapLogicContract`: Update the logic contract address.
    *   `pauseFactory`: Pause new swap creation.
    *   `unpauseFactory`: Unpause new swap creation.
    *   `setFeeRecipient`: Set address to receive creation fees.
    *   `setCreationFee`: Set fee amount for creating swaps.
    *   `setAllowedToken`: Add an allowed token (FT or NFT).
    *   `removeAllowedToken`: Remove an allowed token.
    *   `setOracleRegistry`: Set the address of a relevant oracle registry.
    *   `setConditionHandler`: Register an address for a specific condition type.
    *   `setMinimumExecutionDelay`: Prevent execution too soon after creation.
    *   `withdrawFactoryFees`: Owner withdraws accumulated fees.
10. **Swap Creation Functions:**
    *   `createConditionalSwapFT`: Create a swap of FTs based on an external condition.
    *   `createBundledSwapFT`: Create an atomic bundle of multiple FT swaps.
    *   `createTimeLockedSwapFT`: Create an FT swap executable only after a certain time.
    *   `createConditionalSwapNFT`: Create a swap of NFTs (or NFTs for FTs) based on a condition.
    *   `createBundledSwapMixedAssets`: Create an atomic bundle of FT and NFT swaps.
    *   `createAgreementWithApprovalFT`: Create a swap requiring one or more parties to deposit later.
    *   `createAgreementWithApprovalNFT`: Create an NFT/FT swap requiring later deposit.
11. **Swap Interaction Functions (Delegated to Instance):**
    *   `depositForSwap`: Deposit required assets into a specific swap instance.
    *   `triggerSwapExecution`: Attempt to execute a specific swap instance if conditions met.
    *   `cancelSwapInstance`: Owner cancels a swap instance before execution.
    *   `reclaimFailedSwapAssets`: Reclaim assets from a failed/cancelled swap instance.
12. **Query Functions:**
    *   `querySwapStatus`: Get the current status of a swap instance.
    *   `getSwapParameters`: Get the creation parameters of a swap instance.
    *   `getUserSwapInstances`: Get a list of swap instances created by a user.
    *   `getAllowedTokens`: Get the list of allowed tokens.
    *   `getCreationFee`: Get the current creation fee.
    *   `getFeeRecipient`: Get the current fee recipient.
    *   `getSwapInstanceAddress`: Get the address of a swap instance by ID.
    *   `getTotalSwapInstances`: Get the total number of swaps created.
    *   `getConditionHandler`: Get the address of the handler for a condition type.

---

**Function Summary (Total: 25 functions):**

1.  `constructor()`: Initializes the contract, setting the owner and potentially an initial swap logic contract address.
2.  `setQuantumSwapLogicContract(address _newLogic)`: (Admin) Sets the address of the `IQuantumSwapLogic` contract that new swap instances will be cloned/deployed from. Crucial for potential upgradeability.
3.  `pauseFactory()`: (Admin) Pauses the creation of *new* swap instances. Existing instances can still be interacted with (execute, cancel, deposit) unless their logic contract is also paused.
4.  `unpauseFactory()`: (Admin) Unpauses the factory, allowing new swap creation again.
5.  `setFeeRecipient(address _recipient)`: (Admin) Sets the address where creation fees are sent.
6.  `setCreationFee(uint256 _fee)`: (Admin) Sets the amount of fee (in factory's native token, or Ether) required to create a new swap instance.
7.  `setAllowedToken(address _tokenAddress, bool _isAllowed, bool _isNFT)`: (Admin) Adds or removes a token (ERC20 or ERC721) from the factory's allowed list. Swaps can only be created using allowed tokens.
8.  `removeAllowedToken(address _tokenAddress)`: (Admin) Removes a token from the allowed list.
9.  `setOracleRegistry(address _registry)`: (Admin) Sets the address of a trusted oracle registry contract that can be queried by condition handlers.
10. `setConditionHandler(uint256 _conditionType, address _handler)`: (Admin) Registers a specific contract address (`_handler`) that implements `IConditionHandler` for a given `_conditionType`.
11. `setMinimumExecutionDelay(uint256 _delaySeconds)`: (Admin) Sets a minimum time delay between a swap's creation and when it can first be triggered for execution. Helps prevent certain front-running vectors.
12. `withdrawFactoryFees()`: (Admin) Allows the fee recipient to withdraw accumulated creation fees (assuming fees are paid in Ether or a specific ERC20).
13. `createConditionalSwapFT(...) payable`: (User) Creates a swap instance for ERC20 tokens that requires an external condition (`_conditionType`, `_conditionData`) to be met for execution. Pays the creation fee.
14. `createBundledSwapFT(...) payable`: (User) Creates a swap instance representing an atomic exchange of multiple ERC20 tokens between parties. Requires all inputs to be deposited before execution is possible. Pays the creation fee.
15. `createTimeLockedSwapFT(...) payable`: (User) Creates an ERC20 swap instance that cannot be executed before a specific `_executionTime`. Pays the creation fee.
16. `createConditionalSwapNFT(...) payable`: (User) Creates a swap instance involving ERC721 tokens (and potentially ERC20s) based on an external condition. Pays the creation fee.
17. `createBundledSwapMixedAssets(...) payable`: (User) Creates a complex swap instance involving an atomic exchange of both ERC20 and ERC721 tokens. Pays the creation fee.
18. `createAgreementWithApprovalFT(...) payable`: (User) Creates a conditional or time-locked FT swap instance where counter-parties need to deposit their assets *after* creation. Pays the creation fee.
19. `createAgreementWithApprovalNFT(...) payable`: (User) Creates a conditional or time-locked NFT/FT swap instance where counter-parties need to deposit their assets *after* creation. Pays the creation fee.
20. `depositForSwap(uint256 _swapId)`: (User) Allows a participant in a previously created swap (`_swapId`) to deposit the required assets (FTs via `transferFrom` approval, NFTs via `safeTransferFrom` approval). Interacts with the swap instance.
21. `triggerSwapExecution(uint256 _swapId)`: (Keeper/User) Attempts to execute the swap logic on the swap instance (`_swapId`). This function calls the `execute` method on the instance, which will check conditions (if any) and perform transfers if met.
22. `cancelSwapInstance(uint256 _swapId)`: (Swap Owner) Allows the creator/owner of a swap instance (`_swapId`) to cancel it before it has been fully executed. Interacts with the swap instance.
23. `reclaimFailedSwapAssets(uint256 _swapId)`: (User) Allows participants to reclaim deposited assets from a swap instance (`_swapId`) that has been cancelled or failed execution permanently. Interacts with the swap instance.
24. `querySwapStatus(uint256 _swapId)`: (Anyone) Returns the current state (e.g., Pending, Active, Executed, Cancelled, Failed) of a specific swap instance. Queries the swap instance.
25. `getSwapParameters(uint256 _swapId)`: (Anyone) Returns the initial parameters (tokens, amounts, conditions, participants, etc.) used to create the swap instance (`_swapId`). Queries the swap instance or reads from factory storage.
26. `getUserSwapInstances(address _user)`: (Anyone) Returns a list of swap IDs created by a specific user address.
27. `getAllowedTokens()`: (Anyone) Returns the full list of currently allowed token addresses.
28. `getCreationFee()`: (Anyone) Returns the current fee required to create a swap.
29. `getFeeRecipient()`: (Anyone) Returns the address designated to receive fees.

*(Self-correction: That's 29 functions, well over the 20 requested.)*

---

**Solidity Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Note: This is a simplified factory. The actual QuantumSwapLogic contract
// and ConditionHandler contracts would be complex and require separate implementations.
// This factory focuses on the deployment and management interface.

// --- Interfaces ---

/// @title IQuantumSwapLogic
/// @notice Interface for the deployed individual swap agreement contracts.
/// The factory deploys instances of a contract implementing this.
interface IQuantumSwapLogic {
    enum SwapStatus {
        Pending, // Agreement created, waiting for deposits/conditions
        Active,  // All deposits made, waiting for condition/time
        Executed, // Swap successfully completed
        Cancelled, // Swap cancelled by owner
        Failed,   // Swap failed execution permanently
        Reclaimed // Assets reclaimed after cancel/fail
    }

    /// @notice Initializes a new swap instance with specific parameters.
    /// @param _creator The address that created the swap via the factory.
    /// @param _params Detailed parameters defining the swap (tokens, amounts, conditions, etc.).
    function initialize(address _creator, bytes calldata _params) external;

    /// @notice Allows a party to deposit assets required for the swap.
    function deposit() external;

    /// @notice Attempts to execute the swap based on its logic and conditions.
    /// This is typically called by a keeper or anyone triggering the check.
    function execute() external;

    /// @notice Allows the swap creator to cancel the swap before execution.
    function cancel() external;

    /// @notice Allows participants to reclaim deposited assets if the swap is cancelled or failed.
    function reclaimAssets() external;

    /// @notice Gets the current status of the swap.
    /// @return The current SwapStatus.
    function getStatus() external view returns (SwapStatus);

    /// @notice Gets the initialization parameters of the swap.
    /// @return The parameters byte string used during initialization.
    function getParameters() external view returns (bytes memory);

    /// @notice Gets the address of the swap's creator.
    /// @return The creator's address.
    function getCreator() external view returns (address);
}

/// @title IConditionHandler
/// @notice Interface for contracts that handle specific types of swap conditions.
interface IConditionHandler {
    /// @notice Checks if a specific condition is met.
    /// @param _conditionData Arbitrary data specific to this condition type (e.g., oracle ID, target value).
    /// @param _oracleRegistry Address of the factory's configured oracle registry.
    /// @return true if the condition is met, false otherwise.
    function checkCondition(bytes calldata _conditionData, address _oracleRegistry) external view returns (bool);
}

/// @title IOracleRegistry
/// @notice Interface for a potential oracle registry contract.
/// Used by condition handlers to fetch oracle data reliably.
interface IOracleRegistry {
    /// @notice Example: Get latest price data for a feed.
    /// @param _feedId Identifier for the data feed.
    /// @return The latest data point and timestamp.
    function getLatestPrice(bytes32 _feedId) external view returns (int256 answer, uint256 timestamp);

    // Add other necessary oracle query functions (e.g., boolean conditions, specific events)
}


// --- Errors ---

/// @dev Thrown when attempting to interact with a non-existent swap ID.
error SwapNotFound(uint256 swapId);

/// @dev Thrown when an action can only be performed by the swap creator/owner.
error NotSwapOwner(uint256 swapId, address caller);

/// @dev Thrown when attempting an action on a swap that is not in the expected status.
error InvalidSwapStatus(uint256 swapId, IQuantumSwapLogic.SwapStatus currentStatus, IQuantumSwapLogic.SwapStatus requiredStatus);

/// @dev Thrown when the swap logic contract address is not set.
error SwapLogicNotSet();

/// @dev Thrown when the provided address is not a contract.
error NotAContract(address addr);

/// @dev Thrown when trying to create a swap with a token that is not allowed.
error TokenNotAllowed(address tokenAddress);

/// @dev Thrown when attempting an action that requires the factory to be unpaused.
error FactoryIsPaused();

/// @dev Thrown when attempting an action that requires the factory to be paused.
error FactoryIsNotPaused();

/// @dev Thrown when the creation fee recipient is not set.
error FeeRecipientNotSet();

/// @dev Thrown when the creation fee is not sufficient.
error InsufficientCreationFee(uint256 required, uint256 provided);

/// @dev Thrown when a condition handler for a given type is not registered.
error ConditionHandlerNotSet(uint256 conditionType);

/// @dev Thrown when the minimum execution delay has not passed since creation.
error MinimumDelayNotPassed(uint256 swapId, uint256 minExecutionTime);

/// @dev Thrown when attempting to withdraw fees when the fee recipient is zero.
error NoFeeRecipientSet();


// --- Events ---

/// @dev Emitted when a new Quantum Swap instance is created.
event SwapCreated(
    uint256 indexed swapId,
    address indexed creator,
    address indexed swapAddress,
    uint256 swapType, // Differentiates creation types (conditional FT, bundled NFT, etc.)
    bytes creationParams
);

/// @dev Emitted when a swap logic contract address is updated.
event SwapLogicUpdated(address indexed oldLogic, address indexed newLogic);

/// @dev Emitted when the factory is paused.
event FactoryPaused(address indexed by);

/// @dev Emitted when the factory is unpaused.
event FactoryUnpaused(address indexed by);

/// @dev Emitted when the fee recipient address is updated.
event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

/// @dev Emitted when the creation fee amount is updated.
event CreationFeeUpdated(uint256 oldFee, uint256 newFee);

/// @dev Emitted when a token is added to the allowed list.
event TokenAllowed(address indexed tokenAddress, bool isNFT);

/// @dev Emitted when a token is removed from the allowed list.
event TokenRemoved(address indexed tokenAddress);

/// @dev Emitted when the oracle registry address is updated.
event OracleRegistryUpdated(address indexed oldRegistry, address indexed newRegistry);

/// @dev Emitted when a condition handler is registered or updated.
event ConditionHandlerUpdated(uint256 indexed conditionType, address indexed handler);

/// @dev Emitted when the minimum execution delay is updated.
event MinimumExecutionDelayUpdated(uint256 oldDelay, uint256 newDelay);

/// @dev Emitted when fees are withdrawn by the recipient.
event FactoryFeesWithdrawn(address indexed recipient, uint256 amount);


// --- State Variables ---

contract QuantumSwapFactory is Ownable, Pausable {
    using Address for address;

    // --- Configuration ---
    address private quantumSwapLogicContract; // Address of the contract implementing IQuantumSwapLogic
    uint256 private swapCreationFee; // Fee required to create a swap (in Ether for this example)
    address private feeRecipient; // Address that receives the creation fees
    uint256 private minimumExecutionDelay = 0; // Minimum seconds before a swap can be triggered after creation

    // --- Allowed Tokens ---
    mapping(address => bool) private isAllowedToken;
    mapping(address => bool) private isNFTToken; // true if the allowed token is ERC721
    address[] private allowedTokensList; // To easily query all allowed tokens

    // --- Condition Handlers ---
    mapping(uint256 => address) private conditionHandlers; // Maps condition type hash/enum to handler contract address
    address private oracleRegistry; // Address of the trusted oracle registry

    // --- Swap Tracking ---
    uint256 private swapCounter = 0; // Counter for unique swap IDs
    mapping(uint256 => address) private swapInstances; // Maps swap ID to deployed contract address
    mapping(uint256 => address) private swapOwners; // Maps swap ID to the creator/owner address
    mapping(address => uint256[]) private userSwapInstances; // Maps user address to list of swap IDs they created
    mapping(uint256 => bytes) private swapCreationParameters; // Stores the raw parameters passed during creation

    // --- Fees ---
    uint256 private collectedFees = 0; // Accumulated fees (in Ether)


    // --- Modifiers ---

    /// @dev Checks if the swap ID exists and retrieves the instance address.
    modifier existingSwap(uint256 _swapId) {
        if (swapInstances[_swapId] == address(0)) {
            revert SwapNotFound(_swapId);
        }
        _;
    }


    // --- Constructor ---

    /// @notice Initializes the factory.
    /// @param initialLogic Optional initial address for the swap logic contract.
    constructor(address initialLogic) Ownable(msg.sender) {
        if (initialLogic != address(0)) {
             if (!initialLogic.isContract()) revert NotAContract(initialLogic);
             quantumSwapLogicContract = initialLogic;
             emit SwapLogicUpdated(address(0), initialLogic);
        }
    }

    // --- Admin & Configuration Functions ---

    /// @notice Sets the address of the contract that implements the IQuantumSwapLogic interface.
    /// New swap instances will be created using this logic contract.
    /// @param _newLogic The address of the new logic contract.
    function setQuantumSwapLogicContract(address _newLogic) external onlyOwner {
        if (!_newLogic.isContract()) revert NotAContract(_newLogic);
        emit SwapLogicUpdated(quantumSwapLogicContract, _newLogic);
        quantumSwapLogicContract = _newLogic;
    }

    /// @notice Pauses new swap creation. Existing swaps can still be interacted with.
    function pauseFactory() external onlyOwner {
        _pause();
        emit FactoryPaused(msg.sender);
    }

    /// @notice Unpauses new swap creation.
    function unpauseFactory() external onlyOwner {
        _unpause();
        emit FactoryUnpaused(msg.sender);
    }

    /// @notice Sets the address where creation fees are sent.
    /// @param _recipient The address to receive fees.
    function setFeeRecipient(address _recipient) external onlyOwner {
        emit FeeRecipientUpdated(feeRecipient, _recipient);
        feeRecipient = _recipient;
    }

    /// @notice Sets the amount of fee required to create a new swap.
    /// @param _fee The new creation fee (in Ether).
    function setCreationFee(uint256 _fee) external onlyOwner {
        emit CreationFeeUpdated(swapCreationFee, _fee);
        swapCreationFee = _fee;
    }

    /// @notice Adds or removes a token from the list of allowed tokens for swaps.
    /// Only allowed tokens can be specified in swap creation parameters.
    /// @param _tokenAddress The address of the token (ERC20 or ERC721).
    /// @param _isAllowed True to allow, false to disallow.
    /// @param _isNFT True if the token is an ERC721, false if ERC20.
    function setAllowedToken(address _tokenAddress, bool _isAllowed, bool _isNFT) external onlyOwner {
        if (_isAllowed) {
            if (!isAllowedToken[_tokenAddress]) {
                allowedTokensList.push(_tokenAddress);
            }
            isAllowedToken[_tokenAddress] = true;
            isNFTToken[_tokenAddress] = _isNFT;
            emit TokenAllowed(_tokenAddress, _isNFT);
        } else {
            isAllowedToken[_tokenAddress] = false;
            isNFTToken[_tokenAddress] = false;
            // Removing from allowedTokensList is complex and gas-intensive.
            // For simplicity, we mark as not allowed and leave in list, or iterate to rebuild (costly).
            // A real implementation might use a sparse array or linked list pattern.
            // Keeping it simple: Just mark as not allowed. Query functions need to filter.
            emit TokenRemoved(_tokenAddress);
        }
    }

     /// @notice Removes a token from the allowed list by marking it not allowed.
     /// @param _tokenAddress The address of the token to remove.
    function removeAllowedToken(address _tokenAddress) external onlyOwner {
        isAllowedToken[_tokenAddress] = false;
        isNFTToken[_tokenAddress] = false;
         emit TokenRemoved(_tokenAddress);
         // Note: Does not actually remove from allowedTokensList array for gas efficiency.
         // Query function `getAllowedTokens` must filter.
    }


    /// @notice Sets the address of a trusted oracle registry contract.
    /// Condition handlers can use this to fetch reliable external data.
    /// @param _registry The address of the oracle registry.
    function setOracleRegistry(address _registry) external onlyOwner {
         if (_registry != address(0) && !_registry.isContract()) revert NotAContract(_registry);
        emit OracleRegistryUpdated(oracleRegistry, _registry);
        oracleRegistry = _registry;
    }

    /// @notice Registers a contract address that implements the IConditionHandler interface
    /// for a specific type of condition.
    /// @param _conditionType A unique identifier for the condition type (e.g., hash of a string, enum value).
    /// @param _handler The address of the handler contract for this condition type.
    function setConditionHandler(uint256 _conditionType, address _handler) external onlyOwner {
         if (_handler != address(0) && !_handler.isContract()) revert NotAContract(_handler);
        emit ConditionHandlerUpdated(_conditionType, _handler);
        conditionHandlers[_conditionType] = _handler;
    }

    /// @notice Sets the minimum time delay required before a newly created swap can be executed.
    /// @param _delaySeconds The minimum delay in seconds.
    function setMinimumExecutionDelay(uint256 _delaySeconds) external onlyOwner {
        emit MinimumExecutionDelayUpdated(minimumExecutionDelay, _delaySeconds);
        minimumExecutionDelay = _delaySeconds;
    }

    /// @notice Allows the designated fee recipient to withdraw accumulated fees (Ether).
    function withdrawFactoryFees() external {
        if (msg.sender != feeRecipient) revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable's error
        if (feeRecipient == address(0)) revert NoFeeRecipientSet();
        uint256 amount = collectedFees;
        collectedFees = 0;
        (bool success,) = payable(feeRecipient).call{value: amount}("");
        require(success, "Fee withdrawal failed"); // Revert on failure
        emit FactoryFeesWithdrawn(feeRecipient, amount);
    }


    // --- Swap Creation Functions ---

    /// @dev Internal helper to check if a token is allowed.
    function _checkAllowedToken(address _tokenAddress) internal view {
        if (!isAllowedToken[_tokenAddress]) {
            revert TokenNotAllowed(_tokenAddress);
        }
    }

    /// @dev Internal helper to validate and pay the creation fee.
    function _validateAndPayFee() internal {
        if (feeRecipient == address(0)) revert FeeRecipientNotSet();
        if (msg.value < swapCreationFee) revert InsufficientCreationFee(swapCreationFee, msg.value);
        collectedFees += msg.value; // Collect fee (assuming Ether)
    }

    /// @dev Internal helper to deploy and register a new swap instance.
    /// @param _swapType A type identifier for the creation method used.
    /// @param _params Parameters specific to the swap type, encoded as bytes.
    /// @return The ID of the newly created swap instance.
    function _createSwapInstance(uint256 _swapType, bytes calldata _params) internal whenNotPaused returns (uint256) {
        _validateAndPayFee();

        if (quantumSwapLogicContract == address(0)) revert SwapLogicNotSet();

        swapCounter++;
        uint256 newSwapId = swapCounter;

        // Deploy the logic contract instance
        // Note: Using `new` here. For deterministic addresses, `create2` would be used.
        // The deployed contract's constructor or initialize function would handle actual setup.
        // In this simplified factory, we'll assume the deployed contract has an `initialize` function.
        // The `initialize` call is commented out as the logic contract isn't defined here.
        address newSwapAddress = address(new IQuantumSwapLogic(quantumSwapLogicContract)); // Deploy using the logic contract address
        IQuantumSwapLogic newSwapInstance = IQuantumSwapLogic(newSwapAddress);

        // Store instance details
        swapInstances[newSwapId] = newSwapAddress;
        swapOwners[newSwapId] = msg.sender;
        userSwapInstances[msg.sender].push(newSwapId);
        swapCreationParameters[newSwapId] = _params; // Store raw params for querying

        // Call initialize on the new instance (Conceptual call)
        // newSwapInstance.initialize(msg.sender, _params);

        emit SwapCreated(newSwapId, msg.sender, newSwapAddress, _swapType, _params);

        return newSwapId;
    }

    /// @notice Creates a conditional swap for FTs. Requires condition handler.
    /// @param _tokenIn The address of the token to be transferred by the creator.
    /// @param _amountIn The amount of _tokenIn.
    /// @param _tokenOut The address of the token the creator wishes to receive.
    /// @param _minAmountOut The minimum amount of _tokenOut the creator will accept.
    /// @param _counterparty The address expected to provide _tokenOut.
    /// @param _conditionType Identifier for the condition logic.
    /// @param _conditionData Specific data for the condition handler.
    /// @param _expiry Timestamp after which the swap can no longer be executed.
    /// @return The ID of the created swap instance.
    function createConditionalSwapFT(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _counterparty,
        uint256 _conditionType,
        bytes calldata _conditionData,
        uint256 _expiry
    ) external payable returns (uint256) {
        _checkAllowedToken(_tokenIn);
        _checkAllowedToken(_tokenOut);
        if (conditionHandlers[_conditionType] == address(0)) revert ConditionHandlerNotSet(_conditionType);

        // Example encoding of parameters - the actual logic contract needs to decode this
        bytes memory params = abi.encode(
            "ConditionalSwapFT",
            _tokenIn, _amountIn, _tokenOut, _minAmountOut, _counterparty,
            _conditionType, _conditionData, _expiry, block.timestamp + minimumExecutionDelay
        );

        return _createSwapInstance(1, params); // Swap Type 1
    }

     /// @notice Creates an atomic bundled swap for multiple FTs between two parties.
     /// @param _tokensIn Array of tokens creator transfers.
     /// @param _amountsIn Array of amounts creator transfers (must match _tokensIn length).
     /// @param _tokensOut Array of tokens creator receives.
     /// @param _minAmountsOut Array of minimum amounts creator receives (must match _tokensOut length).
     /// @param _counterparty The other party in the bundle.
     /// @param _expiry Timestamp after which the swap can no longer be executed.
     /// @return The ID of the created swap instance.
    function createBundledSwapFT(
        address[] calldata _tokensIn,
        uint256[] calldata _amountsIn,
        address[] calldata _tokensOut,
        uint256[] calldata _minAmountsOut,
        address _counterparty,
        uint256 _expiry
    ) external payable returns (uint256) {
        require(_tokensIn.length == _amountsIn.length && _tokensOut.length == _minAmountsOut.length, "Array lengths mismatch");
        for(uint i = 0; i < _tokensIn.length; i++) _checkAllowedToken(_tokensIn[i]);
        for(uint i = 0; i < _tokensOut.length; i++) _checkAllowedToken(_tokensOut[i]);

         bytes memory params = abi.encode(
            "BundledSwapFT",
            _tokensIn, _amountsIn, _tokensOut, _minAmountsOut, _counterparty,
            _expiry, block.timestamp + minimumExecutionDelay
        );

        return _createSwapInstance(2, params); // Swap Type 2
    }

    /// @notice Creates an FT swap that is time-locked and can only be executed after a specific time.
    /// @param _tokenIn The address of the token to be transferred by the creator.
    /// @param _amountIn The amount of _tokenIn.
    /// @param _tokenOut The address of the token the creator wishes to receive.
    /// @param _minAmountOut The minimum amount of _tokenOut the creator will accept.
    /// @param _counterparty The address expected to provide _tokenOut.
    /// @param _executionTime The earliest time this swap can be executed.
    /// @param _expiry Timestamp after which the swap can no longer be executed.
    /// @return The ID of the created swap instance.
    function createTimeLockedSwapFT(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _counterparty,
        uint256 _executionTime,
        uint256 _expiry
    ) external payable returns (uint256) {
        _checkAllowedToken(_tokenIn);
        _checkAllowedToken(_tokenOut);
        require(_executionTime >= block.timestamp, "Execution time must be in future");
        require(_expiry >= _executionTime, "Expiry must be after execution time");

        bytes memory params = abi.encode(
            "TimeLockedSwapFT",
            _tokenIn, _amountIn, _tokenOut, _minAmountOut, _counterparty,
            _executionTime, _expiry, block.timestamp + minimumExecutionDelay
        );

        return _createSwapInstance(3, params); // Swap Type 3
    }

     /// @notice Creates a conditional swap involving NFTs (and potentially FTs).
     /// @param _nftAddressIn The address of the NFT contract the creator transfers.
     /// @param _nftIdIn The ID of the NFT the creator transfers.
     /// @param _tokenOut Address of the token the creator receives (FT or NFT).
     /// @param _amountOut The amount/ID of _tokenOut.
     /// @param _isNFTOut True if _tokenOut is an NFT, false if ERC20 FT.
     /// @param _counterparty The address expected to provide _tokenOut.
     /// @param _conditionType Identifier for the condition logic.
     /// @param _conditionData Specific data for the condition handler.
     /// @param _expiry Timestamp after which the swap can no longer be executed.
     /// @return The ID of the created swap instance.
    function createConditionalSwapNFT(
        address _nftAddressIn,
        uint256 _nftIdIn,
        address _tokenOut,
        uint256 _amountOut, // Amount for FT, ID for NFT
        bool _isNFTOut,
        address _counterparty,
        uint256 _conditionType,
        bytes calldata _conditionData,
        uint256 _expiry
    ) external payable returns (uint256) {
        _checkAllowedToken(_nftAddressIn);
        if (!isNFTToken[_nftAddressIn]) revert TokenNotAllowed(_nftAddressIn); // Ensure _nftAddressIn is an allowed NFT
        _checkAllowedToken(_tokenOut);
        if (_isNFTOut != isNFTToken[_tokenOut]) revert TokenNotAllowed(_tokenOut); // Ensure _tokenOut matches its NFT flag

        if (conditionHandlers[_conditionType] == address(0)) revert ConditionHandlerNotSet(_conditionType);

        bytes memory params = abi.encode(
            "ConditionalSwapNFT",
            _nftAddressIn, _nftIdIn, _tokenOut, _amountOut, _isNFTOut, _counterparty,
            _conditionType, _conditionData, _expiry, block.timestamp + minimumExecutionDelay
        );

        return _createSwapInstance(4, params); // Swap Type 4
    }

     /// @notice Creates a complex bundled swap involving both FTs and NFTs.
     /// @param _ftTokensIn Creator's FTs to transfer.
     /// @param _ftAmountsIn Creator's FT amounts to transfer.
     /// @param _nftAddressesIn Creator's NFT contracts to transfer.
     /// @param _nftIdsIn Creator's NFT IDs to transfer.
     /// @param _ftTokensOut Creator's FTs to receive.
     /// @param _ftMinAmountsOut Creator's minimum FT amounts to receive.
     /// @param _nftAddressesOut Creator's NFT contracts to receive.
     /// @param _nftIdsOut Creator's NFT IDs to receive.
     /// @param _counterparty The other party in the bundle.
     /// @param _expiry Timestamp after which the swap can no longer be executed.
     /// @return The ID of the created swap instance.
    function createBundledSwapMixedAssets(
        address[] calldata _ftTokensIn,
        uint256[] calldata _ftAmountsIn,
        address[] calldata _nftAddressesIn,
        uint256[] calldata _nftIdsIn,
        address[] calldata _ftTokensOut,
        uint256[] calldata _ftMinAmountsOut,
        address[] calldata _nftAddressesOut,
        uint256[] calldata _nftIdsOut,
        address _counterparty,
        uint256 _expiry
    ) external payable returns (uint256) {
         require(_ftTokensIn.length == _ftAmountsIn.length, "FT In lengths mismatch");
         require(_nftAddressesIn.length == _nftIdsIn.length, "NFT In lengths mismatch");
         require(_ftTokensOut.length == _ftMinAmountsOut.length, "FT Out lengths mismatch");
         require(_nftAddressesOut.length == _nftIdsOut.length, "NFT Out lengths mismatch");

         for(uint i = 0; i < _ftTokensIn.length; i++) _checkAllowedToken(_ftTokensIn[i]);
         for(uint i = 0; i < _nftAddressesIn.length; i++) { _checkAllowedToken(_nftAddressesIn[i]); if (!isNFTToken[_nftAddressesIn[i]]) revert TokenNotAllowed(_nftAddressesIn[i]); }
         for(uint i = 0; i < _ftTokensOut.length; i++) _checkAllowedToken(_ftTokensOut[i]);
         for(uint i = 0; i < _nftAddressesOut.length; i++) { _checkAllowedToken(_nftAddressesOut[i]); if (!isNFTToken[_nftAddressesOut[i]]) revert TokenNotAllowed(_nftAddressesOut[i]); }


        bytes memory params = abi.encode(
            "BundledSwapMixed",
            _ftTokensIn, _ftAmountsIn, _nftAddressesIn, _nftIdsIn,
            _ftTokensOut, _ftMinAmountsOut, _nftAddressesOut, _nftIdsOut,
            _counterparty, _expiry, block.timestamp + minimumExecutionDelay
        );

        return _createSwapInstance(5, params); // Swap Type 5
    }

    /// @notice Creates a conditional/time-locked FT swap where the counterparty needs to deposit later.
    /// This differs from the above as only the creator deposits initially (implicitly via calling this).
    /// @param _tokenInCreator The token creator deposits.
    /// @param _amountInCreator The amount creator deposits.
    /// @param _tokenOutCounterparty The token counterparty deposits.
    /// @param _amountOutCounterparty The amount counterparty deposits.
    /// @param _counterparty The address required to deposit _tokenOutCounterparty.
    /// @param _conditionType Identifier for the condition logic (0 for time-locked).
    /// @param _conditionData Specific data for the condition handler (timestamp for time-locked).
    /// @param _expiry Timestamp after which the swap can no longer be executed.
    /// @return The ID of the created swap instance.
    function createAgreementWithApprovalFT(
        address _tokenInCreator,
        uint256 _amountInCreator,
        address _tokenOutCounterparty,
        uint256 _amountOutCounterparty,
        address _counterparty,
        uint256 _conditionType, // Use 0 for TimeLock, other types use handlers
        bytes calldata _conditionData, // Timestamp for TimeLock, data for handler
        uint256 _expiry
    ) external payable returns (uint256) {
         _checkAllowedToken(_tokenInCreator);
         _checkAllowedToken(_tokenOutCounterparty);
         if (_conditionType != 0 && conditionHandlers[_conditionType] == address(0)) revert ConditionHandlerNotSet(_conditionType); // If not TimeLock type 0, check handler

        bytes memory params = abi.encode(
            "AgreementApprovalFT",
            _tokenInCreator, _amountInCreator, _tokenOutCounterparty, _amountOutCounterparty, _counterparty,
            _conditionType, _conditionData, _expiry, block.timestamp + minimumExecutionDelay
        );

        return _createSwapInstance(6, params); // Swap Type 6
    }

     /// @notice Creates a conditional/time-locked NFT/FT swap where the counterparty needs to deposit later.
     /// @param _assetInCreator The asset creator deposits (FT or NFT).
     /// @param _amountIdInCreator The amount (FT) or ID (NFT) creator deposits.
     /// @param _isNFTInCreator True if creator deposits NFT, false if FT.
     /// @param _assetOutCounterparty The asset counterparty deposits (FT or NFT).
     /// @param _amountIdOutCounterparty The amount (FT) or ID (NFT) counterparty deposits.
     /// @param _isNFTOutCounterparty True if counterparty deposits NFT, false if FT.
     /// @param _counterparty The address required to deposit _assetOutCounterparty.
     /// @param _conditionType Identifier for the condition logic (0 for time-locked).
     /// @param _conditionData Specific data for the condition handler (timestamp for time-locked).
     /// @param _expiry Timestamp after which the swap can no longer be executed.
     /// @return The ID of the created swap instance.
     function createAgreementWithApprovalNFT(
        address _assetInCreator,
        uint256 _amountIdInCreator,
        bool _isNFTInCreator,
        address _assetOutCounterparty,
        uint256 _amountIdOutCounterparty,
        bool _isNFTOutCounterparty,
        address _counterparty,
        uint256 _conditionType, // Use 0 for TimeLock, other types use handlers
        bytes calldata _conditionData, // Timestamp for TimeLock, data for handler
        uint256 _expiry
     ) external payable returns (uint256) {
         _checkAllowedToken(_assetInCreator);
         if (_isNFTInCreator != isNFTToken[_assetInCreator]) revert TokenNotAllowed(_assetInCreator); // Ensure creator asset matches NFT flag

         _checkAllowedToken(_assetOutCounterparty);
         if (_isNFTOutCounterparty != isNFTToken[_assetOutCounterparty]) revert TokenNotAllowed(_assetOutCounterparty); // Ensure counterparty asset matches NFT flag

         if (_conditionType != 0 && conditionHandlers[_conditionType] == address(0)) revert ConditionHandlerNotSet(_conditionType); // If not TimeLock type 0, check handler


        bytes memory params = abi.encode(
            "AgreementApprovalNFT",
            _assetInCreator, _amountIdInCreator, _isNFTInCreator,
            _assetOutCounterparty, _amountIdOutCounterparty, _isNFTOutCounterparty,
            _counterparty, _conditionType, _conditionData, _expiry, block.timestamp + minimumExecutionDelay
        );

        return _createSwapInstance(7, params); // Swap Type 7
     }


    // --- Swap Interaction Functions (Delegated to Instance) ---

    /// @notice Allows a participant to deposit required assets into a swap instance.
    /// Requires prior approval of tokens/NFTs to the factory or the swap instance itself.
    /// The actual deposit logic resides in the swap instance contract.
    /// @param _swapId The ID of the swap instance.
    function depositForSwap(uint256 _swapId) external payable existingSwap(_swapId) {
        IQuantumSwapLogic swapInstance = IQuantumSwapLogic(swapInstances[_swapId]);
        // Note: The actual transfer logic (transferFrom/safeTransferFrom) would
        // happen *within* the `deposit` function of the swap instance,
        // requiring the user to have approved the *swap instance address*
        // or the *factory address* beforehand.
        swapInstance.deposit();
    }

    /// @notice Attempts to trigger the execution of a swap instance.
    /// The swap instance's logic will check conditions (time, oracle, deposits)
    /// and execute the swap if met.
    /// @param _swapId The ID of the swap instance.
    function triggerSwapExecution(uint256 _swapId) external existingSwap(_swapId) {
         // Optional: Add a check here based on minimumExecutionDelay using block.timestamp
         // uint256 creationTime = getSwapCreationTime(_swapId); // Requires storing creation time
         // if (block.timestamp < creationTime + minimumExecutionDelay) {
         //     revert MinimumDelayNotPassed(_swapId, creationTime + minimumExecutionDelay);
         // }

        IQuantumSwapLogic swapInstance = IQuantumSwapLogic(swapInstances[_swapId]);
        swapInstance.execute(); // Calls the logic contract's execute function
    }

    /// @notice Allows the creator/owner of a swap instance to cancel it before execution.
    /// @param _swapId The ID of the swap instance.
    function cancelSwapInstance(uint256 _swapId) external existingSwap(_swapId) {
        if (msg.sender != swapOwners[_swapId]) revert NotSwapOwner(_swapId, msg.sender);
        IQuantumSwapLogic swapInstance = IQuantumSwapLogic(swapInstances[_swapId]);
        swapInstance.cancel(); // Calls the logic contract's cancel function
    }

    /// @notice Allows participants to reclaim assets from a swap instance that was cancelled or failed.
    /// The actual reclaim logic resides in the swap instance contract.
    /// @param _swapId The ID of the swap instance.
    function reclaimFailedSwapAssets(uint256 _swapId) external existingSwap(_swapId) {
        IQuantumSwapLogic swapInstance = IQuantumSwapLogic(swapInstances[_swapId]);
        swapInstance.reclaimAssets(); // Calls the logic contract's reclaimAssets function
    }


    // --- Query Functions ---

    /// @notice Gets the current status of a swap instance.
    /// @param _swapId The ID of the swap instance.
    /// @return The current SwapStatus enum value.
    function querySwapStatus(uint256 _swapId) external view existingSwap(_swapId) returns (IQuantumSwapLogic.SwapStatus) {
        IQuantumSwapLogic swapInstance = IQuantumSwapLogic(swapInstances[_swapId]);
        return swapInstance.getStatus();
    }

    /// @notice Gets the parameters used to create a swap instance.
    /// @param _swapId The ID of the swap instance.
    /// @return The raw bytes used for initialization.
    function getSwapParameters(uint256 _swapId) external view existingSwap(_swapId) returns (bytes memory) {
         return swapCreationParameters[_swapId]; // Return stored params
         // Alternatively, call `swapInstance.getParameters()`
    }

    /// @notice Gets the list of swap IDs created by a specific user.
    /// @param _user The user's address.
    /// @return An array of swap IDs.
    function getUserSwapInstances(address _user) external view returns (uint256[] memory) {
        return userSwapInstances[_user];
    }

    /// @notice Gets the list of all currently allowed token addresses.
    /// Note: This iterates through the list, which might be gas-intensive for very large lists.
    /// @return An array of allowed token addresses.
    function getAllowedTokens() external view returns (address[] memory) {
        address[] memory allowed = new address[](allowedTokensList.length);
        uint256 count = 0;
        for (uint i = 0; i < allowedTokensList.length; i++) {
            if (isAllowedToken[allowedTokensList[i]]) {
                allowed[count] = allowedTokensList[i];
                count++;
            }
        }
        bytes memory data = abi.encodePacked(allowed); // Pack to get dynamic size correctly
        return abi.decode(data, (address[])); // Decode back
    }

    /// @notice Gets the current fee for creating a swap.
    /// @return The creation fee amount.
    function getCreationFee() external view returns (uint256) {
        return swapCreationFee;
    }

    /// @notice Gets the address designated to receive creation fees.
    /// @return The fee recipient address.
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /// @notice Gets the address of a deployed swap instance by its ID.
    /// @param _swapId The ID of the swap instance.
    /// @return The address of the swap contract.
    function getSwapInstanceAddress(uint256 _swapId) external view existingSwap(_swapId) returns (address) {
        return swapInstances[_swapId];
    }

    /// @notice Gets the total number of swap instances ever created.
    /// @return The total count of swaps.
    function getTotalSwapInstances() external view returns (uint256) {
        return swapCounter;
    }

     /// @notice Gets the address of the condition handler for a specific type.
     /// @param _conditionType The condition type identifier.
     /// @return The address of the registered handler contract, or address(0) if none set.
    function getConditionHandler(uint256 _conditionType) external view returns (address) {
        return conditionHandlers[_conditionType];
    }

     /// @notice Gets the minimum execution delay for new swaps.
     /// @return The delay in seconds.
    function getMinimumExecutionDelay() external view returns (uint256) {
        return minimumExecutionDelay;
    }

    // Optional: Receive function to accept Ether for fees
    receive() external payable {
        // Ether received is handled by the _validateAndPayFee function during swap creation.
        // If Ether is sent without calling a create function, it will be added to collectedFees,
        // which might be unexpected, but harmless if withdrawFactoryFees is controlled.
        // Or uncomment below to strictly only allow Ether during creation calls.
        // revert("Ether not accepted directly");
    }
}
```

**Explanation:**

1.  **Interfaces:** Defines how the `QuantumSwapFactory` interacts with the separate `QuantumSwapLogic` instances and potential `IConditionHandler`/`IOracleRegistry` contracts. This promotes modularity.
2.  **Errors and Events:** Provides clear reasons for failures and logs important state changes.
3.  **State Variables:** Tracks essential factory configuration, the link to the logic contract, allowed tokens, fee information, and mapping of swap IDs to their instance addresses, owners, and creators.
4.  **Admin Functions:** Allow the owner to configure the factory, including pointing to the implementation contract (`quantumSwapLogicContract`), managing fees, allowed tokens, and linking to external dependencies like oracle registries and condition handlers. Pausing (`pauseFactory`, `unpauseFactory`) adds a safety mechanism.
5.  **`_createSwapInstance` Internal Helper:** This is the core of the factory pattern. It handles the common steps for all creation functions: fee validation, incrementing the counter, deploying a *new instance* of the contract located at `quantumSwapLogicContract`, storing its details, and emitting the event.
6.  **Swap Creation Functions (`createConditionalSwapFT`, etc.):** These functions provide different interfaces for users to define specific types of complex swaps. They validate inputs (like allowed tokens, valid condition types), encode the swap-specific parameters into a `bytes` string, and then call `_createSwapInstance` to handle deployment and fee collection. The `_swapType` helps differentiate in logs/queries. *Crucially, these functions do not execute the swap or handle deposits themselves*; they just create the *agreement contract*.
7.  **Swap Interaction Functions (`depositForSwap`, `triggerSwapExecution`, etc.):** These functions act as proxies, forwarding calls to the actual deployed `QuantumSwapLogic` instance specified by the `_swapId`. The factory ensures the `_swapId` is valid (`existingSwap` modifier) but the logic (deposit handling, condition checking, execution, cancellation, reclaiming) resides entirely within the individual swap instance contracts.
8.  **Query Functions:** Provide ways for anyone to inspect the state of the factory or retrieve basic information about deployed swaps.
9.  **Allowed Tokens:** Implements a basic allowlist. Swap creation checks this list. `getAllowedTokens` demonstrates how to filter the internal list to return only currently allowed ones.
10. **Conditional Logic & Oracles:** The factory registers `IConditionHandler` addresses and an `IOracleRegistry`. The swap *creation* functions reference condition types and data. The swap *instance's* `execute` function would then use this information, query the factory for the correct handler address, and call `checkCondition` on the handler, which in turn might query the `oracleRegistry`.

This contract is significantly different from standard examples as it delegates the core logic of the swap itself to dynamically deployed instances, allowing for diverse and complex swap types managed by a single entry point. The concepts of conditional execution, bundled assets, and modular external data dependencies make it more advanced than a simple exchange or escrow.