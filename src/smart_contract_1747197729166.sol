Okay, let's create a smart contract concept that's a bit advanced, creative, and trendy, focusing on conditional asset release based on external data or randomness – let's call it a "Quantum Vault" system, playing on the idea of states resolving based on conditions.

This concept involves users depositing assets into vaults whose release depends on the outcome of future events (fetched by oracles) or pseudo-randomness. It combines elements of prediction markets, conditional escrow, and interaction with external data sources.

**Important Considerations for this concept:**

1.  **Oracle Dependency:** Reliably getting external data (like asset prices, event outcomes) on-chain requires secure oracle solutions (like Chainlink). This contract will use an interface placeholder.
2.  **Randomness:** Secure on-chain randomness is hard. Using a system like Chainlink VRF is standard. This contract will use an interface placeholder.
3.  **Complexity:** Managing multiple vault types, states, and user claims adds complexity.
4.  **Gas Costs:** On-chain computation and storage for many vaults and predictions can be expensive.
5.  **Security:** Handling user funds and external data sources requires rigorous security audits.

This contract will be a *conceptual example* demonstrating the structure and logic, rather than a production-ready system integrated with specific oracle/VRF providers.

---

**QuantumVault: Smart Contract Outline**

This contract allows users to create and interact with conditional vaults. Assets are locked based on future conditions (oracle price feeds, random numbers, specific events) and released to depositors who predicted or supported the eventual winning outcome.

1.  **State Variables:**
    *   Admin/Config: Owner, Oracle addresses, Randomness coordinator address, Fees, Supported ERC20 tokens.
    *   Vault Data: Mapping of vault IDs to Vault structs, Vault counter.
    *   User Data: Mapping of user addresses to their prediction shares in vaults.
    *   External Request Tracking: Mappings for Oracle/Randomness requests to vault IDs.

2.  **Enums:**
    *   `ConditionType`: PRICE_ORACLE, RANDOM_NUMBER, SPECIFIC_EVENT.
    *   `Outcome`: PENDING, OUTCOME_A, OUTCOME_B, OUTCOME_C, DRAW, INVALID. (Simplified set of potential outcomes)
    *   `VaultState`: ACTIVE, RESOLUTION_REQUESTED, RESOLVED, DISTRIBUTED, CANCELLED (Not implemented full cancel logic in this example for brevity).

3.  **Structs:**
    *   `Condition`: Defines the type and parameters of the condition (e.g., target price, range, event ID). Includes resolution status.
    *   `Vault`: Holds vault details (owner, asset, total locked, state, condition, prediction pools for each outcome, mapping to track individual user shares).

4.  **Events:**
    *   `VaultCreated`, `DepositedAndPredicted`, `ResolutionRequested`, `OracleDataFulfilled`, `RandomnessFulfilled`, `VaultResolved`, `WinningsClaimed`, `AdminFeeWithdraw`.

5.  **Functions (Approx. 25+ planned):**
    *   **Admin/Configuration (5+):** Constructor, set addresses (oracle, randomness), set fees, add/remove supported ERC20s, withdraw admin fees, pause/unpause.
    *   **Vault Creation (3+):** Create vault with different condition types (Price, Random, Specific Event).
    *   **Deposit & Predict (2):** Deposit ETH or ERC20 and associate the deposit with a predicted outcome.
    *   **Resolution (5+):** Trigger oracle/randomness requests, callback functions for oracle/randomness, function for owner/anyone to attempt resolution once due, manual resolution for Specific Event type.
    *   **Claiming (1):** Users claim their share of the winning pool after resolution.
    *   **View Functions (8+):** Get vault details, user prediction shares, pool balances, vault counts, supported tokens, fees, contract state (paused).

---

**Function Summary:**

*   `constructor()`: Initializes the contract owner and potentially other configurations.
*   `setOracleAddress(address _oracle)`: Admin function to set the address of the oracle contract.
*   `setRandomnessCoordinator(address _coordinator)`: Admin function to set the address of the randomness coordinator contract.
*   `setVaultCreationFee(uint256 _feeETH, uint256 _feeERC20)`: Admin function to set fees for creating vaults.
*   `addSupportedERC20(address _token)`: Admin function to whitelist an ERC20 token address for use in vaults.
*   `removeSupportedERC20(address _token)`: Admin function to remove a whitelisted ERC20 token address.
*   `withdrawAdminFees(address payable _to, uint256 _amountETH, address _token, uint256 _amountToken)`: Admin function to withdraw accumulated fees.
*   `createVault_PriceOracle(address _asset, uint256 _totalAssetAmount, bytes32 _oracleDataFeedId, int256 _targetValue, uint64 _resolveTime, Outcome _outcomeIfConditionMet, Outcome _outcomeIfConditionNotMet)`: Creates a vault where the resolution depends on an oracle price feed meeting a target value by a specific time.
*   `createVault_RandomNumber(address _asset, uint256 _totalAssetAmount, uint256 _randomNumberRange, uint64 _resolveTime, mapping(uint256 => Outcome) memory _rangeOutcomes)`: Creates a vault where resolution depends on a random number outcome within a defined range.
*   `createVault_SpecificEvent(address _asset, uint256 _totalAssetAmount, bytes32 _eventId, uint64 _resolveTime, Outcome _winningOutcome)`: Creates a vault for a simpler event with a single winning outcome (resolution might be manual or triggered by another system).
*   `depositAndPredictETH(uint256 _vaultId, Outcome _prediction) payable`: Deposits ETH into a vault and records the user's prediction for its outcome.
*   `depositAndPredictERC20(uint256 _vaultId, Outcome _prediction, uint256 _amount)`: Deposits ERC20 into a vault (requires prior approval) and records the user's prediction.
*   `requestOracleData(uint256 _vaultId)`: Public function to trigger an oracle data request for a price oracle vault, if resolution time is met.
*   `fulfillOracleData(bytes32 _requestId, int256 _value)`: Callback function for the oracle to provide the requested data and potentially trigger resolution. (Simplified - actual integration varies).
*   `requestRandomness(uint256 _vaultId)`: Public function to trigger a randomness request for a random number vault, if resolution time is met.
*   `rawFulfillRandomness(bytes32 _requestId, uint256 _randomWord)`: Callback function for the randomness source to provide the random number and potentially trigger resolution. (Simplified - actual integration varies).
*   `resolveVault_SpecificEvent(uint256 _vaultId, Outcome _actualOutcome)`: Allows the vault owner or authorized address to manually resolve a Specific Event vault once its time is met.
*   `triggerResolutionAttempt(uint256 _vaultId)`: A permissionless function allowing anyone to attempt to finalize the resolution of a vault whose condition time has passed and data is available (if needed).
*   `claimWinnings(uint256 _vaultId)`: Allows a user to claim their share of the winning outcome's pool after the vault is resolved.
*   `getVaultDetails(uint256 _vaultId) view`: Returns all details of a specific vault.
*   `getUserPredictionShares(uint256 _vaultId, address _user, Outcome _outcome) view`: Returns the amount of prediction shares a user holds for a specific outcome in a vault.
*   `getPredictionPoolBalance(uint256 _vaultId, Outcome _outcome) view`: Returns the total amount of assets deposited into the prediction pool for a specific outcome.
*   `getVaultCount() view`: Returns the total number of vaults created.
*   `getSupportedERC20s() view`: Returns the list of supported ERC20 token addresses.
*   `getVaultCreationFee() view`: Returns the current vault creation fees.
*   `pause()`: Admin function to pause the contract, preventing most user interactions.
*   `unpause()`: Admin function to unpause the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Placeholder Interfaces for external services
// In a real contract, you would import actual libraries like Chainlink's
interface IOracle {
    // Example function signature - depends on specific oracle service
    // This is a simplified pull model for demonstration
    function requestData(bytes32 _dataFeedId, uint256 _vaultId) external returns (bytes32 requestId);
    // Need a way for the oracle to call back the vault - handled by vault's fulfill function
}

interface IRandomnessCoordinator {
    // Example function signature - depends on specific VRF service
    // This is a simplified request model for demonstration
    function requestRandomness(uint256 _vaultId, uint256 _range) external returns (bytes32 requestId);
     // Need a way for the randomness source to call back the vault - handled by vault's fulfill function
}


/**
 * @title QuantumVault
 * @dev A smart contract platform for creating and interacting with conditional asset vaults.
 * Assets are locked and released based on the resolution of external conditions
 * like oracle data or randomness, supporting prediction market mechanics.
 */
contract QuantumVault is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- Enums ---

    enum ConditionType {
        PRICE_ORACLE,
        RANDOM_NUMBER,
        SPECIFIC_EVENT // Manually resolvable by owner/authorized entity based on external knowledge
    }

    enum Outcome {
        PENDING, // Initial state before prediction opens or before resolution
        OUTCOME_A, // First possible resolution outcome
        OUTCOME_B, // Second possible resolution outcome
        OUTCOME_C, // Third possible resolution outcome (can be extended)
        DRAW, // Condition resulted in a draw or ambiguous outcome
        INVALID // Condition could not be resolved or was invalid
    }

    enum VaultState {
        ACTIVE, // Open for deposits/predictions
        RESOLUTION_REQUESTED, // External data requested, awaiting callback
        RESOLVED, // Condition has been resolved, winnings available
        DISTRIBUTED, // All claims processed (or manually marked)
        CANCELLED // Vault was cancelled (not fully implemented)
    }

    // --- Structs ---

    struct Condition {
        ConditionType conditionType;
        uint64 resolveTime; // Timestamp after which resolution can be attempted

        // Price Oracle specific
        bytes32 oracleDataFeedId; // Identifier for the data feed
        int256 targetValue;      // Target value to check against
        Outcome outcomeIfConditionMet;
        Outcome outcomeIfConditionNotMet;
        bytes32 oracleRequestId; // ID of the active oracle request

        // Random Number specific
        uint256 randomNumberRange; // Upper bound (exclusive) for the random number
        mapping(uint256 => Outcome) rangeOutcomes; // Maps random number outcome to defined Outcome enum
        bytes32 randomnessRequestId; // ID of the active randomness request

        // Specific Event specific
        bytes32 eventId; // Identifier for a known event
        Outcome winningOutcome; // The predefined winning outcome for this event type vault

        // Resolution Status
        bool isResolved;
        Outcome resolvedOutcome;
        int256 resolvedValue; // The actual value from oracle or randomness
    }

    struct Vault {
        uint256 vaultId;
        address payable owner; // Creator of the vault
        address asset; // Address of the asset (0x0 for ETH)
        uint256 totalAssetLocked; // Total assets deposited into this vault
        Condition condition;
        VaultState state;
        mapping(Outcome => uint255) predictionPools; // Total amount deposited predicting this outcome
        mapping(address => mapping(Outcome => uint255)) depositorShares; // User shares in each prediction pool
        bool isClosedForDeposits; // Can the owner manually close deposits early?
    }

    // --- State Variables ---

    uint256 public nextVaultId = 1;
    mapping(uint256 => Vault) public vaults;

    address public oracleAddress; // Address of the oracle contract interface
    address public randomnessCoordinator; // Address of the randomness coordinator interface

    uint256 public vaultCreationFeeETH = 0;
    uint256 public vaultCreationFeeERC20 = 0; // Placeholder, fee token TBD or calculate equivalent ETH

    mapping(address => bool) public supportedERC20; // Whitelisted ERC20 tokens

    // Mappings to track external requests and link them back to vaults
    mapping(bytes32 => uint256) public oracleRequestIdToVaultId;
    mapping(bytes32 => uint256) public randomnessRequestIdToVaultId;

    uint256 public totalAdminFeesETH;
    mapping(address => uint256) public totalAdminFeesERC20; // Fees per token

    // --- Events ---

    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed asset, uint256 totalAssetAmount, ConditionType conditionType);
    event DepositedAndPredicted(uint256 indexed vaultId, address indexed user, address indexed asset, uint256 amount, Outcome prediction);
    event ResolutionRequested(uint256 indexed vaultId, bytes32 indexed requestId, ConditionType conditionType);
    event OracleDataFulfilled(bytes32 indexed requestId, uint256 indexed vaultId, int256 value);
    event RandomnessFulfilled(bytes32 indexed requestId, uint256 indexed vaultId, uint256 randomWord);
    event VaultResolved(uint256 indexed vaultId, Outcome indexed resolvedOutcome, int256 resolvedValue);
    event WinningsClaimed(uint256 indexed vaultId, address indexed user, address indexed asset, uint256 amount);
    event AdminFeeWithdraw(address indexed to, uint256 amountETH, address indexed token, uint256 amountToken);
    event SupportedERC20Added(address indexed token);
    event SupportedERC20Removed(address indexed token);
    event VaultCreationFeeUpdated(uint256 feeETH, uint256 feeERC20);

    // --- Modifiers ---

    modifier onlyOracle() {
        // In a real contract, this would verify msg.sender is the authorized oracle address/callback system
        // For this example, we'll use a placeholder check or potentially owner for simulation
        require(msg.sender == oracleAddress, "Not authorized oracle");
        _;
    }

    modifier onlyRandomnessCoordinator() {
        // In a real contract, verify msg.sender is the authorized randomness source
        require(msg.sender == randomnessCoordinator, "Not authorized randomness source");
        _;
    }

    modifier whenVaultActive(uint256 _vaultId) {
        require(vaults[_vaultId].state == VaultState.ACTIVE, "Vault not active");
        _;
    }

    modifier whenVaultResolved(uint256 _vaultId) {
        require(vaults[_vaultId].state == VaultState.RESOLVED, "Vault not resolved");
        _;
    }

    modifier onlyVaultOwner(uint256 _vaultId) {
        require(msg.sender == vaults[_vaultId].owner, "Not vault owner");
        _;
    }

    // --- Constructor ---

    constructor(address _oracle, address _randomnessCoordinator) Ownable(msg.sender) Pausable(false) {
        oracleAddress = _oracle;
        randomnessCoordinator = _randomnessCoordinator;
        // Add ETH as implicitly supported asset (represented by address(0))
    }

    // --- Admin Functions ---

    function setOracleAddress(address _oracle) external onlyOwner {
        oracleAddress = _oracle;
        // Consider emitting event
    }

    function setRandomnessCoordinator(address _coordinator) external onlyOwner {
        randomnessCoordinator = _coordinator;
        // Consider emitting event
    }

    function setVaultCreationFee(uint256 _feeETH, uint256 _feeERC20) external onlyOwner {
        vaultCreationFeeETH = _feeETH;
        vaultCreationFeeERC20 = _feeERC20; // Simplified - could be dynamic or token-specific
        emit VaultCreationFeeUpdated(_feeETH, _feeERC20);
    }

    function addSupportedERC20(address _token) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        supportedERC20[_token] = true;
        emit SupportedERC20Added(_token);
    }

    function removeSupportedERC20(address _token) external onlyOwner {
         require(_token != address(0), "Invalid token address");
         supportedERC20[_token] = false; // Simply mark as unsupported, don't break existing vaults
         emit SupportedERC20Removed(_token);
    }

     function withdrawAdminFees(address payable _to, uint256 _amountETH, address _token, uint256 _amountToken) external onlyOwner {
        require(_to != address(0), "Invalid recipient");

        if (_amountETH > 0) {
            require(totalAdminFeesETH >= _amountETH, "Insufficient ETH fees");
            totalAdminFeesETH = totalAdminFeesETH.sub(_amountETH);
            (bool success, ) = _to.call{value: _amountETH}("");
            require(success, "ETH transfer failed");
        }

        if (_amountToken > 0) {
            require(_token != address(0), "Invalid token address");
            require(totalAdminFeesERC20[_token] >= _amountToken, "Insufficient token fees");
            totalAdminFeesERC20[_token] = totalAdminFeesERC20[_token].sub(_amountToken);
            IERC20(_token).safeTransfer(_to, _amountToken);
        }

        emit AdminFeeWithdraw(_to, _amountETH, _token, _amountToken);
    }

    // --- Vault Creation Functions ---

    function _createVault(address _asset, uint256 _totalAssetAmount, Condition memory _condition) private returns (uint256) {
        require(_asset == address(0) || supportedERC20[_asset], "Unsupported asset");

        uint256 currentVaultId = nextVaultId++;
        Vault storage newVault = vaults[currentVaultId];

        newVault.vaultId = currentVaultId;
        newVault.owner = payable(msg.sender);
        newVault.asset = _asset;
        newVault.totalAssetLocked = _totalAssetAmount;
        newVault.condition = _condition; // Copy condition struct
        newVault.state = VaultState.ACTIVE;
        newVault.isClosedForDeposits = false;

        emit VaultCreated(currentVaultId, msg.sender, _asset, _totalAssetAmount, _condition.conditionType);
        return currentVaultId;
    }

    function createVault_PriceOracle(
        address _asset,
        uint256 _totalAssetAmount,
        bytes32 _oracleDataFeedId,
        int256 _targetValue,
        uint64 _resolveTime,
        Outcome _outcomeIfConditionMet,
        Outcome _outcomeIfConditionNotMet
    ) external payable whenNotPaused returns (uint256) {
        require(oracleAddress != address(0), "Oracle not set");
        require(_resolveTime > block.timestamp, "Resolve time must be in the future");
        require(_outcomeIfConditionMet != Outcome.PENDING && _outcomeIfConditionMet != Outcome.INVALID, "Invalid outcome if met");
        require(_outcomeIfConditionNotMet != Outcome.PENDING && _outcomeIfConditionNotMet != Outcome.INVALID, "Invalid outcome if not met");
        require(_outcomeIfConditionMet != _outcomeIfConditionNotMet, "Outcomes must be different");
        require(_oracleDataFeedId != bytes32(0), "Invalid oracle data feed ID");

        if (_asset == address(0)) {
             require(msg.value >= vaultCreationFeeETH.add(_totalAssetAmount), "Insufficient ETH sent for creation fee and total amount");
             totalAdminFeesETH = totalAdminFeesETH.add(vaultCreationFeeETH);
             // Total amount is handled implicitly by msg.value being available
        } else {
             require(msg.value >= vaultCreationFeeETH, "Insufficient ETH sent for creation fee");
             totalAdminFeesETH = totalAdminFeesETH.add(vaultCreationFeeETH);
             // For ERC20, the total amount must be transferred separately
             require(IERC20(_asset).allowance(msg.sender, address(this)) >= _totalAssetAmount, "Insufficient ERC20 allowance");
             IERC20(_asset).safeTransferFrom(msg.sender, address(this), _totalAssetAmount);
        }


        Condition memory condition;
        condition.conditionType = ConditionType.PRICE_ORACLE;
        condition.resolveTime = _resolveTime;
        condition.oracleDataFeedId = _oracleDataFeedId;
        condition.targetValue = _targetValue;
        condition.outcomeIfConditionMet = _outcomeIfConditionMet;
        condition.outcomeIfConditionNotMet = _outcomeIfConditionNotMet;
        condition.isResolved = false;
        condition.resolvedOutcome = Outcome.PENDING; // Not resolved initially

        return _createVault(_asset, _totalAssetAmount, condition);
    }

    function createVault_RandomNumber(
        address _asset,
        uint256 _totalAssetAmount,
        uint256 _randomNumberRange,
        uint64 _resolveTime,
        Outcome[] memory _outcomes // Array of outcomes indexed by random number 0 to range-1
    ) external payable whenNotPaused returns (uint256) {
        require(randomnessCoordinator != address(0), "Randomness coordinator not set");
        require(_resolveTime > block.timestamp, "Resolve time must be in the future");
        require(_randomNumberRange > 0 && _randomNumberRange <= _outcomes.length, "Invalid range or outcomes array size"); // Range must map to outcomes

         if (_asset == address(0)) {
             require(msg.value >= vaultCreationFeeETH.add(_totalAssetAmount), "Insufficient ETH sent for creation fee and total amount");
             totalAdminFeesETH = totalAdminFeesETH.add(vaultCreationFeeETH);
         } else {
             require(msg.value >= vaultCreationFeeETH, "Insufficient ETH sent for creation fee");
             totalAdminFeesETH = totalAdminFeesETH.add(vaultCreationFeeETH);
             require(IERC20(_asset).allowance(msg.sender, address(this)) >= _totalAssetAmount, "Insufficient ERC20 allowance");
             IERC20(_asset).safeTransferFrom(msg.sender, address(this), _totalAssetAmount);
         }

        Condition memory condition;
        condition.conditionType = ConditionType.RANDOM_NUMBER;
        condition.resolveTime = _resolveTime;
        condition.randomNumberRange = _randomNumberRange;
        // Copy outcomes to the mapping within the struct
        for (uint i = 0; i < _randomNumberRange; i++) {
             require(_outcomes[i] != Outcome.PENDING && _outcomes[i] != Outcome.INVALID, "Invalid outcome in array");
            condition.rangeOutcomes[i] = _outcomes[i];
        }
        condition.isResolved = false;
        condition.resolvedOutcome = Outcome.PENDING;

        return _createVault(_asset, _totalAssetAmount, condition);
    }

     function createVault_SpecificEvent(
        address _asset,
        uint256 _totalAssetAmount,
        bytes32 _eventId,
        uint64 _resolveTime,
        Outcome _winningOutcome
    ) external payable whenNotPaused returns (uint256) {
        require(_resolveTime > block.timestamp, "Resolve time must be in the future");
        require(_winningOutcome != Outcome.PENDING && _winningOutcome != Outcome.INVALID && _winningOutcome != Outcome.DRAW, "Winning outcome must be specific");
        require(_eventId != bytes32(0), "Invalid event ID");

        if (_asset == address(0)) {
             require(msg.value >= vaultCreationFeeETH.add(_totalAssetAmount), "Insufficient ETH sent for creation fee and total amount");
             totalAdminFeesETH = totalAdminFeesETH.add(vaultCreationFeeETH);
         } else {
             require(msg.value >= vaultCreationFeeETH, "Insufficient ETH sent for creation fee");
             totalAdminFeesETH = totalAdminFeesETH.add(vaultCreationFeeETH);
             require(IERC20(_asset).allowance(msg.sender, address(this)) >= _totalAssetAmount, "Insufficient ERC20 allowance");
             IERC20(_asset).safeTransferFrom(msg.sender, address(this), _totalAssetAmount);
         }

        Condition memory condition;
        condition.conditionType = ConditionType.SPECIFIC_EVENT;
        condition.resolveTime = _resolveTime;
        condition.eventId = _eventId;
        condition.winningOutcome = _winningOutcome;
        condition.isResolved = false;
        condition.resolvedOutcome = Outcome.PENDING;

        return _createVault(_asset, _totalAssetAmount, condition);
    }


    // --- Deposit & Predict Functions ---

    function _depositAndPredict(uint256 _vaultId, Outcome _prediction, uint256 _amount) private {
        Vault storage vault = vaults[_vaultId];
        require(_prediction != Outcome.PENDING && _prediction != Outcome.INVALID, "Cannot predict PENDING or INVALID outcome");
        // In a more complex system, would check if the prediction is valid for this vault type/outcomes

        vault.predictionPools[_prediction] = vault.predictionPools[_prediction].add(_amount);
        vault.depositorShares[msg.sender][_prediction] = vault.depositorShares[msg.sender][_prediction].add(_amount); // Shares == deposit amount in this model

        emit DepositedAndPredicted(_vaultId, msg.sender, vault.asset, _amount, _prediction);
    }

    function depositAndPredictETH(uint256 _vaultId, Outcome _prediction) external payable whenVaultActive(_vaultId) whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(vault.asset == address(0), "Vault does not accept ETH");
        require(!vault.isClosedForDeposits, "Vault is closed for deposits");
        require(msg.value > 0, "Must send ETH");

        _depositAndPredict(_vaultId, _prediction, msg.value);
    }

    function depositAndPredictERC20(uint256 _vaultId, Outcome _prediction, uint256 _amount) external whenVaultActive(_vaultId) whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(vault.asset != address(0), "Vault does not accept ERC20");
        require(!vault.isClosedForDeposits, "Vault is closed for deposits");
        require(_amount > 0, "Must deposit amount > 0");
        require(supportedERC20[vault.asset], "Unsupported asset for deposit");

        IERC20(vault.asset).safeTransferFrom(msg.sender, address(this), _amount);
        _depositAndPredict(_vaultId, _prediction, _amount);
    }

    // --- Resolution Functions ---

    // Allows anyone to trigger the resolution process if the time has passed and condition type allows
    function triggerResolutionAttempt(uint256 _vaultId) external whenVaultActive(_vaultId) whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(block.timestamp >= vault.condition.resolveTime, "Resolution time not yet met");
        require(!vault.condition.isResolved, "Vault already resolved");

        if (vault.condition.conditionType == ConditionType.PRICE_ORACLE) {
            require(oracleAddress != address(0), "Oracle not set for resolution");
            require(vault.condition.oracleRequestId == bytes32(0), "Oracle data request already pending");
            vault.state = VaultState.RESOLUTION_REQUESTED;
            bytes32 requestId = IOracle(oracleAddress).requestData(vault.condition.oracleDataFeedId, _vaultId);
            vault.condition.oracleRequestId = requestId;
            oracleRequestIdToVaultId[requestId] = _vaultId;
            emit ResolutionRequested(_vaultId, requestId, ConditionType.PRICE_ORACLE);

        } else if (vault.condition.conditionType == ConditionType.RANDOM_NUMBER) {
             require(randomnessCoordinator != address(0), "Randomness coordinator not set for resolution");
             require(vault.condition.randomnessRequestId == bytes32(0), "Randomness request already pending");
             vault.state = VaultState.RESOLUTION_REQUESTED;
             // Range passed to coordinator for generation needs to match vault's expectation
             bytes32 requestId = IRandomnessCoordinator(randomnessCoordinator).requestRandomness(_vaultId, vault.condition.randomNumberRange);
             vault.condition.randomnessRequestId = requestId;
             randomnessRequestIdToVaultId[requestId] = _vaultId;
             emit ResolutionRequested(_vaultId, requestId, ConditionType.RANDOM_NUMBER);

        } else if (vault.condition.conditionType == ConditionType.SPECIFIC_EVENT) {
             // Specific Event vaults are resolved manually by the owner/authorized entity
             // This attempt function does nothing for SPECIFIC_EVENT, they must use resolveVault_SpecificEvent
             revert("Specific Event vaults require manual resolution by owner");
        } else {
            revert("Unsupported condition type for resolution");
        }
    }

    // Callback for the Oracle (simplified)
    function fulfillOracleData(bytes32 _requestId, int256 _value) external onlyOracle {
        uint256 vaultId = oracleRequestIdToVaultId[_requestId];
        require(vaultId != 0, "Unknown oracle request ID");
        Vault storage vault = vaults[vaultId];
        require(vault.condition.conditionType == ConditionType.PRICE_ORACLE, "Vault type mismatch for oracle callback");
        require(!vault.condition.isResolved, "Vault already resolved");
        require(vault.condition.oracleRequestId == _requestId, "Request ID mismatch");

        delete oracleRequestIdToVaultId[_requestId]; // Clean up mapping

        vault.condition.resolvedValue = _value;
        vault.condition.isResolved = true;

        // Determine outcome based on target value
        if (_value >= vault.condition.targetValue) {
            vault.condition.resolvedOutcome = vault.condition.outcomeIfConditionMet;
        } else {
            vault.condition.resolvedOutcome = vault.condition.outcomeIfConditionNotMet;
        }

        vault.state = VaultState.RESOLVED;
        emit VaultResolved(vaultId, vault.condition.resolvedOutcome, _value);
    }

    // Callback for the Randomness Coordinator (simplified)
    function rawFulfillRandomness(bytes32 _requestId, uint256 _randomWord) external onlyRandomnessCoordinator {
         uint256 vaultId = randomnessRequestIdToVaultId[_requestId];
         require(vaultId != 0, "Unknown randomness request ID");
         Vault storage vault = vaults[vaultId];
         require(vault.condition.conditionType == ConditionType.RANDOM_NUMBER, "Vault type mismatch for randomness callback");
         require(!vault.condition.isResolved, "Vault already resolved");
         require(vault.condition.randomnessRequestId == _requestId, "Request ID mismatch");

         delete randomnessRequestIdToVaultId[_requestId]; // Clean up mapping

         // Use the random word, potentially modulo the range
         uint256 finalRandomValue = _randomWord % vault.condition.randomNumberRange;
         vault.condition.resolvedValue = int256(finalRandomValue); // Store as int for consistency

         vault.condition.isResolved = true;
         vault.condition.resolvedOutcome = vault.condition.rangeOutcomes[finalRandomValue];

         vault.state = VaultState.RESOLVED;
         emit VaultResolved(vaultId, vault.condition.resolvedOutcome, int256(finalRandomValue));
    }


    // Manual resolution for Specific Event vaults by owner/authorized
    function resolveVault_SpecificEvent(uint256 _vaultId, Outcome _actualOutcome) external onlyVaultOwner(_vaultId) whenVaultActive(_vaultId) whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        require(vault.condition.conditionType == ConditionType.SPECIFIC_EVENT, "Vault is not a Specific Event type");
        require(block.timestamp >= vault.condition.resolveTime, "Resolution time not yet met");
        require(!vault.condition.isResolved, "Vault already resolved");
         // Optional: require _actualOutcome == vault.condition.winningOutcome for strictness
         // Or allow owner to declare DRAW/INVALID if event outcome is ambiguous
        require(_actualOutcome != Outcome.PENDING, "Cannot resolve to PENDING");

        vault.condition.isResolved = true;
        vault.condition.resolvedOutcome = _actualOutcome;
        vault.condition.resolvedValue = 0; // N/A for specific events

        vault.state = VaultState.RESOLVED;
        emit VaultResolved(_vaultId, _actualOutcome, 0);
    }


    // --- Claiming Functions ---

    function claimWinnings(uint256 _vaultId) external whenVaultResolved(_vaultId) whenNotPaused {
        Vault storage vault = vaults[_vaultId];
        Outcome winningOutcome = vault.condition.resolvedOutcome;

        // Check if the user predicted the winning outcome
        uint256 userSharesInWinningPool = vault.depositorShares[msg.sender][winningOutcome];
        require(userSharesInWinningPool > 0, "User did not predict the winning outcome or already claimed");

        // Calculate the user's share of the total locked assets
        // Note: This model means only the winning pool participants split the *entire* vault total.
        // An alternative is winning pool participants split *only* the winning pool total,
        // and other pools' funds are lost or returned. This implementation uses the *total* pool.
        uint256 winningPoolTotal = vault.predictionPools[winningOutcome];
        require(winningPoolTotal > 0, "Winning pool is empty"); // Should not happen if user has shares, but safety check

        // Share = (user's deposit in winning pool / total deposit in winning pool) * total vault assets
        uint256 winnings = userSharesInWinningPool.mul(vault.totalAssetLocked).div(winningPoolTotal);

        // Reset user shares to prevent double claiming
        vault.depositorShares[msg.sender][winningOutcome] = 0;

        // Transfer winnings
        if (vault.asset == address(0)) {
            // ETH Transfer
            (bool success, ) = payable(msg.sender).call{value: winnings}("");
            require(success, "ETH transfer failed");
        } else {
            // ERC20 Transfer
            IERC20(vault.asset).safeTransfer(msg.sender, winnings);
        }

        emit WinningsClaimed(_vaultId, msg.sender, vault.asset, winnings);

        // Optional: Mark vault as distributed if all funds claimed (more complex tracking needed)
        // For simplicity, vault state stays RESOLVED after first claim.
    }

    // --- View Functions ---

    function getVaultDetails(uint256 _vaultId) public view returns (
        uint256 vaultId,
        address owner,
        address asset,
        uint256 totalAssetLocked,
        VaultState state,
        Condition memory condition,
        uint255 outcomeAPool,
        uint255 outcomeBPool,
        uint255 outcomeCPool,
        uint255 drawPool,
        uint255 invalidPool // Include all possible Outcome pools
    ) {
        Vault storage vault = vaults[_vaultId];
        vaultId = vault.vaultId;
        owner = vault.owner;
        asset = vault.asset;
        totalAssetLocked = vault.totalAssetLocked;
        state = vault.state;
        condition = vault.condition;
        outcomeAPool = vault.predictionPools[Outcome.OUTCOME_A];
        outcomeBPool = vault.predictionPools[Outcome.OUTCOME_B];
        outcomeCPool = vault.predictionPools[Outcome.OUTCOME_C];
        drawPool = vault.predictionPools[Outcome.DRAW];
        invalidPool = vault.predictionPools[Outcome.INVALID];
    }

    function getUserPredictionShares(uint256 _vaultId, address _user, Outcome _prediction) external view returns (uint255) {
        return vaults[_vaultId].depositorShares[_user][_prediction];
    }

    function getPredictionPoolBalance(uint256 _vaultId, Outcome _prediction) external view returns (uint255) {
        return vaults[_vaultId].predictionPools[_prediction];
    }

    function getVaultCount() external view returns (uint256) {
        return nextVaultId.sub(1);
    }

    function getSupportedERC20s() external view returns (address[] memory) {
        // Note: Iterating mappings is not possible. This requires tracking supported tokens in an array.
        // For simplicity in this example, we'll return a placeholder or require iterating off-chain.
        // A proper implementation would add/remove from an array alongside the mapping.
        // Returning an empty array as placeholder.
        address[] memory supported = new address[](0);
        // In a real contract, populate this array if tracking in one.
        // For demo purposes, imagine an off-chain tool queries the mapping for known tokens.
         return supported; // Placeholder
    }

    function getVaultCreationFee() external view returns (uint256 ethFee, uint256 erc20Fee) {
        return (vaultCreationFeeETH, vaultCreationFeeERC20);
    }

    function getVaultState(uint256 _vaultId) external view returns (VaultState) {
         return vaults[_vaultId].state;
    }

     function isVaultResolved(uint256 _vaultId) external view returns (bool) {
        return vaults[_vaultId].condition.isResolved;
    }

    function getVaultResolvedOutcome(uint256 _vaultId) external view returns (Outcome) {
        return vaults[_vaultId].condition.resolvedOutcome;
    }

    // --- Pausable Overrides ---
    // Most state-changing functions should include the whenNotPaused modifier
    // Admin functions (setters, withdraw) typically should NOT be pausable.

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Receive ETH ---
    receive() external payable {
        // Optional: handle incoming ETH not associated with a specific function call
        // Could potentially revert or add to admin fees, depending on desired behavior.
        // Reverting unexpected ETH sends is safer in most cases.
        revert("Direct ETH receive not allowed. Use depositAndPredictETH or include with vault creation.");
    }
}
```