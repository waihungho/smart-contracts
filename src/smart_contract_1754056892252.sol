The `AetherNexusProtocol` is designed as a highly adaptive and autonomous decentralized protocol. It acts as a central orchestrator for managing a collective treasury, enabling complex multi-step operations through "intents" (conditional and time-bound transactions), and adapting its core strategies by integrating AI-augmented insights via trusted oracles. Its modular architecture ensures future extensibility and upgradability without core contract redeployments.

---

## Contract: `AetherNexusProtocol`

### Purpose:
The `AetherNexusProtocol` is a self-evolving, intent-driven decentralized autonomous protocol designed to manage a collective treasury, execute complex multi-step operations based on user-defined intents, and adapt its strategies through AI-augmented governance and real-time oracle data. It features a modular architecture allowing for dynamic upgrades and integration of specialized functionalities.

### Key Concepts & Advanced Features:
*   **Intent-Centric Design:** Users specify desired outcomes (multi-step, conditional operations) rather than precise execution paths. A network of "solvers" (or an `IntentExecutorModule`) would fulfill these intents.
*   **AI-Augmented Decision Making (via Oracles):** Protocol parameters and intent conditions can react to and be informed by AI model outputs (e.g., market sentiment, risk scores) delivered through whitelisted oracle networks.
*   **Modular Architecture:** Allows for registering, deregistering, and upgrading external functional modules (e.g., `TreasuryModule`, `GovernanceModule`, `IntentExecutorModule`) via a central registry, enhancing extensibility and maintainability.
*   **Dynamic Protocol Parameters:** Core protocol settings (e.g., fees, thresholds) can be updated through a governance process, potentially triggered by AI-driven insights from oracles.
*   **Pausable & Emergency Measures:** Includes safety mechanisms for pausing critical operations and recovering misplaced assets.

### Outline:

1.  **Core Architecture & State Variables:**
    *   Defines key roles, addresses, and mappings for modules, oracles, intents, and protocol parameters.
    *   Inherits `Ownable` for administrative control and `Pausable` for emergency halting.
2.  **Access Control & Lifecycle Management:**
    *   Functions for `pause`, `unpause`, transferring/renouncing ownership, and emergency token recovery.
3.  **Module Management:**
    *   Functions to register, update, and retrieve addresses of various protocol modules. Also includes a simplified proposal and approval mechanism for module upgrades.
4.  **Treasury & Asset Management:**
    *   Functions for users/modules to deposit assets into the protocol's vault. Includes asset whitelisting/blacklisting.
5.  **Intent Engine & Execution:**
    *   Allows users to submit complex `Intent` structs. Provides functions for intent cancellation and a permissioned mechanism for "solvers" (or an `IntentExecutorModule`) to mark intents as fulfilled. Includes getters for intent status and data.
6.  **Oracle & External Data Integration:**
    *   Manages the registration and deregistration of trusted oracle addresses.
    *   Includes functions for proposing and executing changes to core protocol parameters, which can be informed by oracle data and AI insights.
7.  **Solver Management:**
    *   Functions to approve and revoke addresses that are permitted to fulfill intents.
8.  **Events:**
    *   Emits events for all critical state changes for off-chain monitoring and indexing.

### Function Summary (27 Functions):

**I. Core Protocol & Access Control (6 functions)**
1.  `constructor(address initialOwner)`: Initializes the contract with an owner.
2.  `pause()`: Pauses core protocol functionalities (emergency).
3.  `unpause()`: Unpauses core protocol functionalities.
4.  `transferOwnership(address newOwner)`: Transfers ownership of the protocol (inherited).
5.  `renounceOwnership()`: Renounces ownership (inherited).
6.  `emergencyTokenWithdraw(IERC20 _token, address _to, uint256 _amount)`: Allows owner to recover misplaced tokens.

**II. Module Management (5 functions)**
7.  `registerModule(bytes32 _moduleId, address _moduleAddress)`: Registers or updates an address for a specific functional module.
8.  `deregisterModule(bytes32 _moduleId)`: Removes a module's registered address.
9.  `getModuleAddress(bytes32 _moduleId)`: Retrieves the current address for a given module ID.
10. `proposeModuleUpgrade(bytes32 _moduleId, address _newAddress, string memory _details)`: Initiates a proposal for a module upgrade (governance placeholder).
11. `approveModuleUpgrade(bytes32 _moduleId, address _newAddress)`: Owner/governance executes a module upgrade.

**III. Treasury & Asset Management (Core Protocol interaction - 4 functions)**
12. `depositAssets(address _token, uint256 _amount)`: Allows users or modules to deposit assets into the protocol's main vault.
13. `whitelistAsset(address _token)`: Whitelists an ERC20 token for protocol interactions.
14. `blacklistAsset(address _token)`: Blacklists an ERC20 token.
15. `isAssetWhitelisted(address _token)`: Checks if an asset is whitelisted.

**IV. Intent Engine & Execution (5 functions)**
16. `submitIntent(Intent memory _intent)`: Allows users to submit a complex, multi-step, conditional "intent."
17. `cancelIntent(bytes32 _intentId)`: Allows the intent submitter to cancel their pending intent.
18. `markIntentFulfilled(bytes32 _intentId, bytes memory _proof)`: Called by an approved "solver" module to mark an intent as fulfilled.
19. `getIntentStatus(bytes32 _intentId)`: Retrieves the current status of a submitted intent.
20. `getIntent(bytes32 _intentId)`: Retrieves the full Intent struct.

**V. Oracle & Data Integration (5 functions)**
21. `registerOracle(bytes32 _oracleId, address _oracleAddress)`: Registers a trusted oracle address for data feeds.
22. `deregisterOracle(bytes32 _oracleId)`: Deregisters an oracle.
23. `getOracleAddress(bytes32 _oracleId)`: Retrieves the address of a registered oracle.
24. `proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _description)`: Proposes a change to a core protocol parameter (governance placeholder).
25. `executeParameterChange(bytes32 _parameterKey, uint256 _newValue)`: Executes a proposed parameter change.
26. `getProtocolParameter(bytes32 _parameterKey)`: Retrieves the current value of a protocol parameter.

**VI. Solver Management (3 functions)**
27. `approveSolver(address _solverAddress)`: Approves an address to act as a solver for intents.
28. `revokeSolver(address _solverAddress)`: Revokes an address's permission to act as a solver.
29. `isApprovedSolver(address _solverAddress)`: Checks if an address is an approved solver.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AetherNexusProtocol
 * @dev The AetherNexusProtocol is a self-evolving, intent-driven decentralized autonomous protocol designed to
 *      manage a collective treasury, execute complex multi-step operations based on user-defined intents,
 *      and adapt its strategies through AI-augmented governance and real-time oracle data.
 *      It features a modular architecture allowing for dynamic upgrades and integration of specialized functionalities.
 *
 * Outline:
 * 1. Core Architecture & State Variables:
 *    - Defines key roles, addresses, and mappings for modules, oracles, intents, and protocol parameters.
 *    - Inherits Ownable for administrative control and Pausable for emergency halting.
 * 2. Access Control & Lifecycle Management:
 *    - Functions for pause, unpause, transferring/renouncing ownership, and emergency token recovery.
 * 3. Module Management:
 *    - Functions to register, update, and retrieve addresses of various protocol modules. Also includes a simplified
 *      proposal and approval mechanism for module upgrades.
 * 4. Treasury & Asset Management (Core Protocol's interaction with assets):
 *    - Functions for users/modules to deposit assets into the protocol's vault. Includes asset whitelisting/blacklisting.
 * 5. Intent Engine & Execution:
 *    - Allows users to submit complex Intent structs. Provides functions for intent cancellation and a permissioned
 *      mechanism for "solvers" (or an IntentExecutorModule) to mark intents as fulfilled. Includes getters for intent status and data.
 * 6. Oracle & External Data Integration:
 *    - Manages the registration and deregistration of trusted oracle addresses.
 *    - Includes functions for proposing and executing changes to core protocol parameters, which can be informed by
 *      oracle data and AI insights.
 * 7. Solver Management:
 *    - Functions to approve and revoke addresses that are permitted to fulfill intents.
 * 8. Events:
 *    - Emits events for all critical state changes for off-chain monitoring and indexing.
 *
 * Function Summary (27 Functions):
 * I. Core Protocol & Access Control (6 functions)
 * 1. constructor(address initialOwner): Initializes the contract with an owner.
 * 2. pause(): Pauses core protocol functionalities (emergency).
 * 3. unpause(): Unpauses core protocol functionalities.
 * 4. transferOwnership(address newOwner): Transfers ownership of the protocol (inherited from Ownable).
 * 5. renounceOwnership(): Renounces ownership (inherited from Ownable).
 * 6. emergencyTokenWithdraw(IERC20 _token, address _to, uint256 _amount): Allows owner to recover misplaced tokens.
 *
 * II. Module Management (5 functions)
 * 7. registerModule(bytes32 _moduleId, address _moduleAddress): Registers or updates an address for a specific functional module.
 * 8. deregisterModule(bytes32 _moduleId): Removes a module's registered address.
 * 9. getModuleAddress(bytes32 _moduleId): Retrieves the current address for a given module ID.
 * 10. proposeModuleUpgrade(bytes32 _moduleId, address _newAddress, string memory _details): Initiates a proposal for a module upgrade (governance placeholder).
 * 11. approveModuleUpgrade(bytes32 _moduleId, address _newAddress): Owner/governance executes a module upgrade.
 *
 * III. Treasury & Asset Management (Core Protocol interaction - 4 functions)
 * 12. depositAssets(address _token, uint256 _amount): Allows users or modules to deposit assets into the protocol's main vault.
 * 13. whitelistAsset(address _token): Whitelists an ERC20 token for protocol interactions.
 * 14. blacklistAsset(address _token): Blacklists an ERC20 token.
 * 15. isAssetWhitelisted(address _token): Checks if an asset is whitelisted.
 *
 * IV. Intent Engine & Execution (5 functions)
 * 16. submitIntent(Intent memory _intent): Allows users to submit a complex, multi-step, conditional "intent."
 * 17. cancelIntent(bytes32 _intentId): Allows the intent submitter to cancel their pending intent.
 * 18. markIntentFulfilled(bytes32 _intentId, bytes memory _proof): Called by an approved "solver" module to mark an intent as fulfilled.
 * 19. getIntentStatus(bytes32 _intentId): Retrieves the current status of a submitted intent.
 * 20. getIntent(bytes32 _intentId): Retrieves the full Intent struct.
 *
 * V. Oracle & Data Integration (6 functions)
 * 21. registerOracle(bytes32 _oracleId, address _oracleAddress): Registers a trusted oracle address for data feeds.
 * 22. deregisterOracle(bytes32 _oracleId): Deregisters an oracle.
 * 23. getOracleAddress(bytes32 _oracleId): Retrieves the address of a registered oracle.
 * 24. proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _description): Proposes a change to a core protocol parameter (governance placeholder).
 * 25. executeParameterChange(bytes32 _parameterKey, uint256 _newValue): Executes a proposed parameter change.
 * 26. getProtocolParameter(bytes32 _parameterKey): Retrieves the current value of a protocol parameter.
 *
 * VI. Solver Management (3 functions)
 * 27. approveSolver(address _solverAddress): Approves an address to act as a solver for intents.
 * 28. revokeSolver(address _solverAddress): Revokes an address's permission to act as a solver.
 * 29. isApprovedSolver(address _solverAddress): Checks if an address is an approved solver.
 */
contract AetherNexusProtocol is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Enums and Structs ---

    /// @dev Represents the current status of an intent.
    enum IntentStatus { Pending, Fulfilled, Cancelled, Expired, Failed }

    /// @dev Defines the type of operation an intent step will perform.
    enum IntentOperation { SWAP, STAKE, LP, TRANSFER, CALL_MODULE, ORACLE_QUERY_THEN_ACT }

    /// @dev Represents a condition that must be met for an intent to be fulfilled.
    ///      Conditions can reference protocol parameters or external oracle data (e.g., AI model outputs).
    struct IntentCondition {
        bytes32 paramKey;     // e.g., keccak256("TokenAPrice") or keccak256("AI_Sentiment_Score_ETH")
        uint256 value;        // The threshold value for the condition.
        bytes32 comparator;   // e.g., keccak256("GT") for greater than, "LT" for less than, "EQ" for equal.
        bytes32 oracleId;     // Identifier for the oracle providing the data for this condition. (bytes32(0) if internal param)
        bytes32 oracleDataKey; // Specific data key within the oracle's feed (e.g., "ETH_USD_Price", "Market_Sentiment").
    }

    /// @dev Represents a single executable step within a multi-step intent.
    ///      Steps can be conditional on fresh oracle data.
    struct IntentStep {
        IntentOperation operation;              // The type of operation to perform.
        address targetContract;                 // Contract address to interact with (e.g., Uniswap router, staking pool, a module).
        bytes callData;                         // Encoded function call for the operation.
        uint256 value;                          // ETH value to send with the call (for operation or fee).
        bool requiresOracleDataForExecution;    // Does this step require fresh oracle data before execution?
        bytes32 oracleIdForStep;                // Which oracle to consult if requiresOracleDataForExecution is true.
        bytes32 oracleDataKeyForStep;           // Specific data key from the oracle (e.g., "AI_RebalanceThreshold").
    }

    /// @dev Represents a user-defined intent, encapsulating conditions and executable steps.
    ///      Intents are unique, time-bound, and can carry a fee for solvers.
    struct Intent {
        bytes32 id;             // Unique ID for the intent.
        address submitter;      // Address of the user who submitted the intent.
        uint256 submissionTime; // Timestamp when the intent was submitted.
        uint256 expirationTime; // Timestamp when the intent becomes invalid.
        IntentStatus status;    // Current status of the intent.
        uint256 fulfillmentFee; // Fee to be paid to the solver upon successful fulfillment.
        IntentCondition[] conditions; // Array of conditions that must be met for the intent to be executed.
        IntentStep[] steps;      // Array of operations to perform if conditions are met.
        address designatedSolver; // Optional: A specific solver address allowed to fulfill this intent. address(0) for any.
    }

    // --- State Variables ---

    /// @dev Maps a unique module ID to its deployed contract address.
    mapping(bytes32 => address) private _modules;
    /// @dev Maps a unique oracle ID to its deployed contract address.
    mapping(bytes32 => address) private _oracles;
    /// @dev Tracks whether an ERC20 token is whitelisted for use within the protocol.
    mapping(address => bool) private _whitelistedAssets;
    /// @dev Stores all submitted intents by their unique ID.
    mapping(bytes32 => Intent) private _intents;
    /// @dev Stores generic protocol parameters (e.g., fees, thresholds) identified by a key.
    mapping(bytes32 => uint256) private _protocolParameters;
    /// @dev Tracks addresses that are approved to act as solvers for intents.
    mapping(address => bool) private _approvedSolvers;

    // --- Events ---

    /// @dev Emitted when a module is registered or its address is updated.
    event ModuleRegistered(bytes32 indexed moduleId, address indexed moduleAddress);
    /// @dev Emitted when a module is deregistered.
    event ModuleDeregistered(bytes32 indexed moduleId);
    /// @dev Emitted when a module upgrade proposal is initiated.
    event ModuleUpgradeProposed(bytes32 indexed moduleId, address newAddress, string details);
    /// @dev Emitted when a module upgrade is successfully approved and applied.
    event ModuleUpgradeApproved(bytes32 indexed moduleId, address newAddress);
    /// @dev Emitted when an asset is whitelisted.
    event AssetWhitelisted(address indexed token);
    /// @dev Emitted when an asset is blacklisted.
    event AssetBlacklisted(address indexed token);
    /// @dev Emitted when a new intent is successfully submitted.
    event IntentSubmitted(bytes32 indexed intentId, address indexed submitter, uint256 expirationTime);
    /// @dev Emitted when an intent's status changes.
    event IntentStatusChanged(bytes32 indexed intentId, IntentStatus oldStatus, IntentStatus newStatus);
    /// @dev Emitted when an oracle is registered.
    event OracleRegistered(bytes32 indexed oracleId, address indexed oracleAddress);
    /// @dev Emitted when an oracle is deregistered.
    event OracleDeregistered(bytes32 indexed oracleId);
    /// @dev Emitted when a protocol parameter is updated.
    event ProtocolParameterUpdated(bytes32 indexed parameterKey, uint256 oldValue, uint256 newValue);
    /// @dev Emitted when a protocol parameter change is proposed.
    event ProtocolParameterProposed(bytes32 indexed parameterKey, uint256 newValue, string description);
    /// @dev Emitted when an address is approved as a solver.
    event SolverApproved(address indexed solver);
    /// @dev Emitted when an address's solver permission is revoked.
    event SolverRevoked(address indexed solver);

    // --- Constructor ---

    /// @dev Initializes the contract and sets the initial owner.
    ///      Also initializes some default protocol parameters.
    /// @param initialOwner The address of the initial owner for the protocol.
    constructor(address initialOwner) Ownable(initialOwner) {
        // Initialize default protocol parameters
        _protocolParameters[keccak256("DefaultFulfillmentFee")] = 0; // Default to 0, can be updated by governance
        _protocolParameters[keccak256("MinIntentExpiration")] = 1 hours; // Minimum expiration time for an intent
        _protocolParameters[keccak256("MaxIntentSteps")] = 10;     // Maximum number of steps per intent
        _protocolParameters[keccak256("MaxIntentConditions")] = 5; // Maximum number of conditions per intent
    }

    // --- I. Core Protocol & Access Control ---

    /// @notice Pauses core protocol functionalities. Only callable by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses core protocol functionalities. Only callable by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to recover tokens mistakenly sent to this contract.
    /// @param _token The address of the ERC20 token to withdraw. Use address(0) for ETH.
    /// @param _to The address to send the tokens to.
    /// @param _amount The amount of tokens to withdraw.
    function emergencyTokenWithdraw(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        require(_to != address(0), "Recipient cannot be zero address");

        if (address(_token) == address(0)) { // ETH withdrawal
            payable(_to).transfer(_amount);
        } else { // ERC20 token withdrawal
            _token.safeTransfer(_to, _amount);
        }
    }

    // `transferOwnership` and `renounceOwnership` are inherited from Ownable.

    // --- II. Module Management ---

    /// @notice Registers or updates an address for a specific functional module.
    ///         Only callable by the owner.
    /// @param _moduleId A unique identifier (e.g., keccak256("TreasuryModule")) for the module.
    /// @param _moduleAddress The address of the deployed module contract.
    function registerModule(bytes32 _moduleId, address _moduleAddress) public onlyOwner {
        require(_moduleAddress != address(0), "Module address cannot be zero");
        _modules[_moduleId] = _moduleAddress;
        emit ModuleRegistered(_moduleId, _moduleAddress);
    }

    /// @notice Deregisters a module, effectively removing its associated address.
    ///         Only callable by the owner.
    /// @param _moduleId The unique identifier of the module to deregister.
    function deregisterModule(bytes32 _moduleId) public onlyOwner {
        require(_modules[_moduleId] != address(0), "Module not registered");
        delete _modules[_moduleId];
        emit ModuleDeregistered(_moduleId);
    }

    /// @notice Retrieves the current address for a given module ID.
    /// @param _moduleId The unique identifier of the module.
    /// @return The address of the registered module.
    function getModuleAddress(bytes32 _moduleId) public view returns (address) {
        return _modules[_moduleId];
    }

    /// @notice Initiates a proposal for a module upgrade. This function is a placeholder;
    ///         actual voting/governance logic would typically be handled by a separate GovernanceModule.
    ///         For this example, it simply emits an event. Only callable by the owner.
    /// @param _moduleId The ID of the module to upgrade.
    /// @param _newAddress The new address for the module.
    /// @param _details A description of the upgrade.
    function proposeModuleUpgrade(bytes32 _moduleId, address _newAddress, string memory _details) public onlyOwner {
        emit ModuleUpgradeProposed(_moduleId, _newAddress, _details);
    }

    /// @notice Executes a module upgrade after a successful proposal/vote.
    ///         This function calls `registerModule` to update the module's address.
    ///         Only callable by the owner for simplification in this example.
    /// @param _moduleId The ID of the module to upgrade.
    /// @param _newAddress The new address for the module.
    function approveModuleUpgrade(bytes32 _moduleId, address _newAddress) public onlyOwner {
        // In a real system, this would require checking a successful governance vote outcome.
        registerModule(_moduleId, _newAddress); // Re-uses registerModule to update the address
        emit ModuleUpgradeApproved(_moduleId, _newAddress);
    }

    // --- III. Treasury & Asset Management (Core Protocol interaction) ---

    /// @notice Allows users or modules to deposit assets into the protocol's main vault.
    ///         These assets are then conceptually managed by the TreasuryModule (not explicitly
    ///         implemented here but assumed via `getModuleAddress`).
    /// @param _token The address of the ERC20 token to deposit. Use address(0) for ETH.
    /// @param _amount The amount of tokens to deposit.
    function depositAssets(address _token, uint256 _amount) public payable whenNotPaused {
        require(_whitelistedAssets[_token], "Asset not whitelisted");
        require(_amount > 0, "Deposit amount must be greater than zero");

        if (_token == address(0)) { // ETH deposit
            require(msg.value == _amount, "ETH amount mismatch");
        } else { // ERC20 deposit
            require(msg.value == 0, "Cannot send ETH with ERC20 deposit");
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
        // In a production system, these funds would likely be immediately transferred
        // to a dedicated, separate TreasuryModule contract. For this example,
        // `address(this)` is assumed to be the protocol's primary vault.
    }

    /// @notice Whitelists an ERC20 token for use within the protocol.
    ///         Only callable by the owner.
    /// @param _token The address of the token to whitelist.
    function whitelistAsset(address _token) public onlyOwner {
        require(_token != address(0), "Token address cannot be zero");
        _whitelistedAssets[_token] = true;
        emit AssetWhitelisted(_token);
    }

    /// @notice Blacklists an ERC20 token, preventing further deposits or specific interactions.
    ///         Only callable by the owner.
    /// @param _token The address of the token to blacklist.
    function blacklistAsset(address _token) public onlyOwner {
        require(_token != address(0), "Token address cannot be zero");
        _whitelistedAssets[_token] = false;
        emit AssetBlacklisted(_token);
    }

    /// @notice Checks if an asset is whitelisted.
    /// @param _token The address of the token.
    /// @return True if the token is whitelisted, false otherwise.
    function isAssetWhitelisted(address _token) public view returns (bool) {
        return _whitelistedAssets[_token];
    }

    // --- IV. Intent Engine & Execution ---

    /// @notice Allows users to submit a complex, multi-step, conditional "intent."
    ///         A `fulfillmentFee` (in ETH) must be paid to potentially reward solvers.
    ///         The actual execution of the intent steps would be handled by a separate
    ///         `IntentExecutorModule` or a network of off-chain solvers.
    /// @param _intent The Intent struct containing conditions and steps.
    /// @return The unique ID of the submitted intent.
    function submitIntent(Intent memory _intent) public payable whenNotPaused returns (bytes32) {
        require(_intent.expirationTime > block.timestamp + _protocolParameters[keccak256("MinIntentExpiration")], "Intent expiration too soon");
        require(_intent.steps.length > 0, "Intent must have at least one step");
        require(_intent.steps.length <= _protocolParameters[keccak256("MaxIntentSteps")], "Too many intent steps");
        require(_intent.conditions.length <= _protocolParameters[keccak256("MaxIntentConditions")], "Too many intent conditions");
        require(msg.value >= _intent.fulfillmentFee, "Insufficient fulfillment fee");
        require(_intent.id == bytes32(0), "Intent ID must be zero for new submission"); // ID is generated internally

        bytes32 newIntentId = keccak256(abi.encodePacked(msg.sender, block.timestamp, _intent.steps.length, _intent.conditions.length, _intent.expirationTime));
        // Ensure no active intent with this ID exists, although unlikely due to randomness
        require(_intents[newIntentId].status == IntentStatus.Pending || _intents[newIntentId].status == IntentStatus.Fulfilled, "Intent ID collision detected");

        _intent.id = newIntentId;
        _intent.submitter = msg.sender;
        _intent.submissionTime = block.timestamp;
        _intent.status = IntentStatus.Pending;

        _intents[newIntentId] = _intent;
        emit IntentSubmitted(newIntentId, msg.sender, _intent.expirationTime);
        return newIntentId;
    }

    /// @notice Allows the intent submitter to cancel their pending intent.
    ///         Refunds the fulfillment fee if the intent is still pending and not expired.
    /// @param _intentId The ID of the intent to cancel.
    function cancelIntent(bytes32 _intentId) public whenNotPaused {
        Intent storage intent = _intents[_intentId];
        require(intent.id != bytes32(0), "Intent not found");
        require(intent.submitter == msg.sender, "Not intent submitter");
        require(intent.status == IntentStatus.Pending, "Intent not in pending state");
        require(block.timestamp < intent.expirationTime, "Intent has expired");

        emit IntentStatusChanged(_intentId, intent.status, IntentStatus.Cancelled);
        intent.status = IntentStatus.Cancelled;

        // Refund the fulfillment fee
        payable(msg.sender).transfer(intent.fulfillmentFee);
    }

    /// @notice Called by an approved "solver" to mark an intent as fulfilled.
    ///         This function would typically be called by the `IntentExecutorModule` after
    ///         it successfully executes all steps of an intent. Pays the solver's fee.
    /// @param _intentId The ID of the intent to mark as fulfilled.
    /// @param _proof An optional proof or hash of execution details (for off-chain verification).
    function markIntentFulfilled(bytes32 _intentId, bytes memory _proof) public whenNotPaused {
        require(_approvedSolvers[msg.sender], "Caller is not an approved solver");

        Intent storage intent = _intents[_intentId];
        require(intent.id != bytes32(0), "Intent not found");
        require(intent.status == IntentStatus.Pending, "Intent not in pending state");
        require(block.timestamp < intent.expirationTime, "Intent has expired");
        if (intent.designatedSolver != address(0)) {
            require(intent.designatedSolver == msg.sender, "Not the designated solver for this intent");
        }

        // Additional logic to verify fulfillment could be more complex, potentially involving _proof
        // For now, this function assumes the solver has done their job correctly.
        emit IntentStatusChanged(_intentId, intent.status, IntentStatus.Fulfilled);
        intent.status = IntentStatus.Fulfilled;

        // Pay the solver their fulfillment fee
        payable(msg.sender).transfer(intent.fulfillmentFee);
    }

    /// @notice Retrieves the current status of a submitted intent.
    /// @param _intentId The ID of the intent.
    /// @return The current status of the intent.
    function getIntentStatus(bytes32 _intentId) public view returns (IntentStatus) {
        return _intents[_intentId].status;
    }

    /// @notice Retrieves the full intent struct.
    ///         Note: For very large structs, consider separate getters for individual fields
    ///         for gas efficiency in specific use cases.
    /// @param _intentId The ID of the intent.
    /// @return The Intent struct.
    function getIntent(bytes32 _intentId) public view returns (Intent memory) {
        return _intents[_intentId];
    }

    // --- V. Oracle & Data Integration ---

    /// @notice Registers a trusted oracle address for data feeds.
    ///         Only callable by the owner.
    /// @param _oracleId A unique identifier for the oracle (e.g., keccak256("ChainlinkPriceFeed")).
    /// @param _oracleAddress The address of the oracle contract.
    function registerOracle(bytes32 _oracleId, address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        _oracles[_oracleId] = _oracleAddress;
        emit OracleRegistered(_oracleId, _oracleAddress);
    }

    /// @notice Deregisters an oracle.
    ///         Only callable by the owner.
    /// @param _oracleId The unique identifier of the oracle to deregister.
    function deregisterOracle(bytes32 _oracleId) public onlyOwner {
        require(_oracles[_oracleId] != address(0), "Oracle not registered");
        delete _oracles[_oracleId];
        emit OracleDeregistered(_oracleId);
    }

    /// @notice Retrieves the address of a registered oracle.
    /// @param _oracleId The unique identifier of the oracle.
    /// @return The address of the registered oracle.
    function getOracleAddress(bytes32 _oracleId) public view returns (address) {
        return _oracles[_oracleId];
    }

    /// @notice Proposes a change to a core protocol parameter.
    ///         This function is a placeholder; actual voting/governance logic would typically
    ///         be handled by a separate GovernanceModule. This proposal might be informed by
    ///         AI model insights received via oracles. Only callable by the owner.
    /// @param _parameterKey A unique key for the parameter (e.g., keccak256("TreasuryRiskFactor")).
    /// @param _newValue The proposed new value for the parameter.
    /// @param _description A description of why the change is being proposed (e.g., "AI model advises lower risk tolerance").
    function proposeParameterChange(bytes32 _parameterKey, uint256 _newValue, string memory _description) public onlyOwner {
        // In a real system, this would create a governance proposal that needs voting.
        emit ProtocolParameterProposed(_parameterKey, _newValue, _description);
    }

    /// @notice Executes a proposed parameter change after successful voting/approval.
    ///         Only callable by the owner for simplification.
    /// @param _parameterKey The key of the parameter to update.
    /// @param _newValue The value to set the parameter to.
    function executeParameterChange(bytes32 _parameterKey, uint256 _newValue) public onlyOwner {
        // In a real system, this would require checking a successful governance vote outcome.
        uint256 oldValue = _protocolParameters[_parameterKey];
        _protocolParameters[_parameterKey] = _newValue;
        emit ProtocolParameterUpdated(_parameterKey, oldValue, _newValue);
    }

    /// @notice Retrieves the current value of a protocol parameter.
    /// @param _parameterKey The key of the parameter.
    /// @return The current value of the parameter.
    function getProtocolParameter(bytes32 _parameterKey) public view returns (uint256) {
        return _protocolParameters[_parameterKey];
    }

    // --- VI. Solver Management ---

    /// @notice Approves an address to act as a solver, able to mark intents as fulfilled.
    ///         Only callable by the owner.
    /// @param _solverAddress The address to approve.
    function approveSolver(address _solverAddress) public onlyOwner {
        require(_solverAddress != address(0), "Solver address cannot be zero");
        _approvedSolvers[_solverAddress] = true;
        emit SolverApproved(_solverAddress);
    }

    /// @notice Revokes an address's permission to act as a solver.
    ///         Only callable by the owner.
    /// @param _solverAddress The address to revoke.
    function revokeSolver(address _solverAddress) public onlyOwner {
        require(_approvedSolvers[_solverAddress], "Solver not approved");
        _approvedSolvers[_solverAddress] = false;
        emit SolverRevoked(_solverAddress);
    }

    /// @notice Checks if an address is an approved solver.
    /// @param _solverAddress The address to check.
    /// @return True if the address is an approved solver, false otherwise.
    function isApprovedSolver(address _solverAddress) public view returns (bool) {
        return _approvedSolvers[_solverAddress];
    }
}
```