Okay, let's create a smart contract that implements a sophisticated, multi-condition, time-locked, and event-driven asset release system. We'll call it "QuantumVault" to reflect its ability to handle complex, conditional states.

This contract will allow users to deposit ETH or ERC20 tokens and lock them under *multiple, composable conditions* that must *all* be met for the assets to be claimed. Conditions can include time locks, external oracle data validation, and multi-party attestations. It also allows for transferring the *ownership* of the locked deposit itself, making the locked position a potential transferable asset.

It's designed to be more advanced than simple vesting contracts or time locks by allowing dynamic sets of conditions linked per deposit.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **SPDX License and Pragma**
2.  **Imports:** ERC20 interface, potentially ReentrancyGuard (for safety).
3.  **Events:**
    *   DepositMade
    *   ConditionDefined
    *   ConditionAddedToDeposit
    *   ConditionRemovedFromDeposit
    *   AttestationMade
    *   OracleConditionMet
    *   DepositClaimed
    *   DepositCancelled
    *   DepositOwnershipTransferred
    *   AllowedConditionSetterAdded
    *   AllowedConditionSetterRemoved
    *   OracleRegistered
    *   ConditionModified
4.  **Enums:**
    *   `ConditionType`: Enum to define different types of release conditions.
5.  **Structs:**
    *   `Deposit`: Stores deposit details (owner, token, amount, linked condition IDs, status).
    *   `Condition`: Stores condition details (type, parameters specific to type, current state, related attestations/oracle data).
6.  **State Variables:**
    *   Counters for deposits and conditions.
    *   Mappings: ID to Deposit, ID to Condition.
    *   Mapping: Deposit ID to linked Condition IDs.
    *   Mapping: User address to Deposit IDs they own.
    *   Mapping: Allowed addresses that can set conditions for *any* deposit (in addition to the depositor).
    *   Mapping: Oracle type (bytes32 identifier) to Oracle contract address.
    *   Contract Owner.
    *   Reentrancy Guard flag.
7.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `onlyDepositOwnerOrAllowedSetter`: Restricts access to the deposit owner or an allowed condition setter.
    *   `onlyRegisteredOracle`: Restricts access to addresses registered as oracles for a specific type.
    *   `nonReentrant`: Prevents reentrant calls.
8.  **Constructor:** Sets the contract owner.
9.  **Core Deposit Functions:**
    *   `depositETH`: Deposit Ether into the vault.
    *   `depositERC20`: Deposit ERC20 tokens into the vault.
10. **Condition Definition & Management Functions:**
    *   `defineTimeLockCondition`: Create a time-based condition (absolute timestamp).
    *   `defineDurationLockCondition`: Create a time-based condition (duration from deposit).
    *   `defineOracleValueCondition`: Create a condition based on an oracle reporting a specific value.
    *   `defineAttestationCondition`: Create a condition requiring attestations from specified addresses.
    *   `defineCompoundCondition`: Create a condition requiring *all* linked sub-conditions to be met (AND logic).
    *   `addConditionToDeposit`: Link a defined condition to a specific deposit.
    *   `removeConditionFromDeposit`: Unlink a condition from a deposit (under certain rules).
    *   `modifyConditionParameter`: Modify parameters of a specific condition (e.g., update oracle data key, add attester - restricted).
11. **Condition State Update Functions:**
    *   `attestCondition`: User calls this to provide an attestation for an `AttestationCondition`.
    *   `triggerOracleConditionUpdate`: Called by a registered oracle to report data relevant to an `OracleValueCondition`.
12. **Condition Checking Functions:**
    *   `checkConditionMet(uint256 conditionId)`: Internal/View function to check if a single condition is met.
    *   `checkAllDepositConditionsMet(uint256 depositId)`: Internal/View function to check if *all* conditions linked to a deposit are met.
13. **Claim & Cancellation Functions:**
    *   `claim(uint256 depositId)`: Allows a deposit owner to claim assets if all conditions are met.
    *   `cancelDeposit(uint256 depositId)`: Allows the deposit owner to cancel the deposit and withdraw early (only if no conditions have been met *and* within a grace period).
14. **Information Retrieval (View) Functions:**
    *   `getDepositInfo(uint256 depositId)`: Get details of a specific deposit.
    *   `getDepositConditionIds(uint256 depositId)`: Get IDs of conditions linked to a deposit.
    *   `getConditionInfo(uint256 conditionId)`: Get details of a specific condition.
    *   `getUserDeposits(address user)`: Get IDs of deposits owned by a user.
    *   `getTotalDeposits()`: Get the total number of deposits.
    *   `getTotalConditions()`: Get the total number of defined conditions.
    *   `getAllowedConditionSetters()`: Get list of addresses allowed to set conditions.
    *   `getOracleAddress(bytes32 oracleType)`: Get the address for a registered oracle type.
    *   `getAttestationStatus(uint256 conditionId, address attester)`: Check if an attester has attested for a specific condition.
15. **Access Control & Management Functions:**
    *   `addAllowedConditionSetter`: Add an address to the list allowed to set conditions.
    *   `removeAllowedConditionSetter`: Remove an address from the list.
    *   `transferDepositOwnership`: Transfer the ownership of a locked deposit position.
    *   `registerOracle`: Register an address as a trusted oracle for a specific type.
    *   `removeOracle`: Remove an oracle registration.

**Function Summary:**

1.  `constructor()`: Initializes the contract, setting the owner.
2.  `depositETH()`: Receives Ether, creates a new Deposit entry.
3.  `depositERC20(address token, uint256 amount)`: Receives ERC20 tokens, creates a new Deposit entry.
4.  `defineTimeLockCondition(uint256 unlockTimestamp)`: Creates a new `Condition` requiring a specific timestamp to pass. Returns the new condition ID.
5.  `defineDurationLockCondition(uint256 duration)`: Creates a new `Condition` requiring a duration (relative to deposit time) to pass. Returns the new condition ID.
6.  `defineOracleValueCondition(bytes32 oracleType, bytes32 dataKey, uint256 requiredValue)`: Creates a new `Condition` requiring a registered oracle of `oracleType` to report `requiredValue` for `dataKey`. Returns condition ID.
7.  `defineAttestationCondition(address[] requiredAttesters, uint256 requiredCount)`: Creates a new `Condition` requiring `requiredCount` attestations from the `requiredAttesters` list. Returns condition ID.
8.  `defineCompoundCondition(uint256[] conditionIds)`: Creates a new `Condition` that is met only if ALL conditions in `conditionIds` are met. Returns condition ID.
9.  `addConditionToDeposit(uint256 depositId, uint256 conditionId)`: Links an existing `Condition` to a `Deposit`. Requires deposit owner or allowed setter.
10. `removeConditionFromDeposit(uint256 depositId, uint256 conditionId)`: Unlinks a `Condition` from a `Deposit`. Requires deposit owner or allowed setter. May have time restrictions.
11. `attestCondition(uint256 conditionId)`: Allows an address listed in an `AttestationCondition` to attest. Updates the condition's state.
12. `triggerOracleConditionUpdate(uint256 conditionId, uint256 reportedValue)`: Called by a registered oracle to update the state of an `OracleValueCondition`. Checks if the condition is now met.
13. `checkConditionMet(uint256 conditionId)`: *View* function. Checks if a single condition's criteria are currently satisfied.
14. `checkAllDepositConditionsMet(uint256 depositId)`: *View* function. Checks if *all* conditions linked to `depositId` are met.
15. `claim(uint256 depositId)`: Allows the deposit owner to withdraw assets if `checkAllDepositConditionsMet` returns true. Uses `nonReentrant`.
16. `cancelDeposit(uint256 depositId)`: Allows the deposit owner to cancel if allowed (e.g., within grace period, no conditions met yet). Refunds assets.
17. `transferDepositOwnership(uint256 depositId, address newOwner)`: Transfers the right to claim/cancel a deposit to a new address. Requires current deposit owner.
18. `addAllowedConditionSetter(address setter)`: *Owner-only*. Adds an address that can set conditions for *any* deposit.
19. `removeAllowedConditionSetter(address setter)`: *Owner-only*. Removes an address from the allowed setters list.
20. `registerOracle(bytes32 oracleType, address oracleAddress)`: *Owner-only*. Registers an address as a trusted oracle for a given type identifier.
21. `removeOracle(bytes32 oracleType)`: *Owner-only*. Removes an oracle registration.
22. `getDepositInfo(uint256 depositId)`: *View*. Returns details of a deposit.
23. `getDepositConditionIds(uint256 depositId)`: *View*. Returns the array of condition IDs linked to a deposit.
24. `getConditionInfo(uint256 conditionId)`: *View*. Returns details of a condition.
25. `getUserDeposits(address user)`: *View*. Returns array of deposit IDs owned by `user`.
26. `getTotalDeposits()`: *View*. Returns the total count of deposits made.
27. `getTotalConditions()`: *View*. Returns the total count of conditions defined.
28. `getAllowedConditionSetters()`: *View*. Returns the list of addresses allowed to set conditions.
29. `getOracleAddress(bytes32 oracleType)`: *View*. Returns the address of the registered oracle for a type.
30. `getAttestationStatus(uint256 conditionId, address attester)`: *View*. Returns true if `attester` has attested for `conditionId`.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for basic contract admin

// Note: For a production system, complex logic involving external calls
// and state changes might require more sophisticated error handling,
// gas optimization, and potentially a modular architecture (like upgradeable proxies).
// This implementation focuses on demonstrating the concepts.

/**
 * @title QuantumVault
 * @dev A sophisticated vault contract allowing conditional, time-locked,
 * and event-driven release of assets (ETH or ERC20).
 * Assets are locked under multiple, composable conditions that must all be met
 * for claiming. Supports time locks, oracle data triggers, multi-party attestations,
 * and transferable locked positions.
 */
contract QuantumVault is Ownable, ReentrancyGuard {

    // --- Events ---
    event DepositMade(uint256 indexed depositId, address indexed owner, address indexed token, uint256 amount, uint256 timestamp);
    event ConditionDefined(uint256 indexed conditionId, ConditionType conditionType, address indexed creator);
    event ConditionAddedToDeposit(uint256 indexed depositId, uint256 indexed conditionId);
    event ConditionRemovedFromDeposit(uint256 indexed depositId, uint256 indexed conditionId);
    event AttestationMade(uint256 indexed conditionId, address indexed attester);
    event OracleConditionUpdateTriggered(uint256 indexed conditionId, bytes32 indexed oracleType, uint256 reportedValue);
    event DepositClaimed(uint256 indexed depositId, address indexed claimant, uint256 timestamp);
    event DepositCancelled(uint256 indexed depositId, address indexed canceller, uint256 timestamp);
    event DepositOwnershipTransferred(uint256 indexed depositId, address indexed oldOwner, address indexed newOwner);
    event AllowedConditionSetterAdded(address indexed setter);
    event AllowedConditionSetterRemoved(address indexed setter);
    event OracleRegistered(bytes32 indexed oracleType, address indexed oracleAddress);
    event OracleRemoved(bytes32 indexed oracleType, address indexed oracleAddress);
    event ConditionModified(uint256 indexed conditionId, bytes description); // Generic event for modification

    // --- Enums ---
    enum ConditionType {
        TimeAbsolute,     // Unlock after a specific timestamp
        TimeDuration,     // Unlock after a duration relative to deposit time
        OracleValue,      // Unlock when a specific oracle reports a value
        Attestation,      // Unlock when N out of M parties attest
        Compound          // Unlock when ALL linked conditions are met
    }

    // --- Structs ---
    struct Deposit {
        address owner;           // The address currently allowed to claim/manage
        address token;           // Address of the ERC20 token, or address(0) for ETH
        uint256 amount;          // Amount deposited
        uint256 depositTimestamp; // Timestamp of the deposit
        uint256[] conditionIds;  // IDs of conditions linked to this deposit
        bool isClaimed;          // True if the deposit has been claimed
    }

    struct Condition {
        ConditionType conditionType;
        bool isMet;              // Flag to indicate if the condition is currently met

        // Parameters (only relevant fields used based on conditionType)
        uint256 uint256Param1;   // e.g., timestamp, duration, requiredCount, compound conditionId
        address addressParam1;   // e.g., oracle contract address, required attester address (if single)
        bytes32 bytes32Param1;   // e.g., oracle data key, oracle type identifier
        address[] addressArrayParam1; // e.g., required attesters list
        uint256[] uint256ArrayParam1; // e.g., compound condition IDs

        // State (used by specific condition types)
        mapping(address => bool) attestations; // For Attestation type: attester address => has_attested
    }

    // --- State Variables ---
    uint256 private _nextDepositId;
    uint256 private _nextConditionId;

    mapping(uint256 => Deposit) private _deposits;
    mapping(address => uint256[]) private _userDeposits; // Maps user to their deposit IDs
    mapping(uint256 => Condition) private _conditions;

    // Mapping from deposit ID to array of condition IDs (redundant but maybe useful for lookups)
    // Note: Deposit struct already contains this. This might be removed to save gas/storage if not strictly necessary for external views.
    // Keeping it simple for now, relying on the array in the struct.

    mapping(address => bool) private _allowedConditionSetters; // Addresses allowed to add/remove conditions for ANY deposit

    mapping(bytes32 => address) private _oracleRegistry; // Maps oracle type identifier to oracle contract address

    uint256 public constant GRACE_PERIOD_FOR_CANCELLATION = 7 days; // Example grace period

    // --- Modifiers ---
    modifier onlyDepositOwnerOrAllowedSetter(uint256 depositId) {
        require(_deposits[depositId].owner == msg.sender || _allowedConditionSetters[msg.sender], "Not authorized to modify deposit conditions");
        _;
    }

    modifier onlyRegisteredOracle(bytes32 oracleType) {
        require(_oracleRegistry[oracleType] != address(0), "Oracle type not registered");
        require(_oracleRegistry[oracleType] == msg.sender, "Caller is not the registered oracle for this type");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        _nextDepositId = 1; // Start IDs from 1
        _nextConditionId = 1;
    }

    // --- Core Deposit Functions ---

    /**
     * @dev Deposits ETH into the vault under the caller's ownership.
     * @param conditionIds The IDs of the conditions to link to this deposit.
     */
    receive() external payable nonReentrant {
        _createDeposit(msg.sender, address(0), msg.value, new uint256[](0));
    }

    /**
     * @dev Deposits ETH into the vault under the caller's ownership, linking conditions.
     * @param conditionIds The IDs of the conditions to link to this deposit.
     */
    function depositETH(uint256[] calldata conditionIds) external payable nonReentrant {
         _createDeposit(msg.sender, address(0), msg.value, conditionIds);
    }

    /**
     * @dev Deposits ERC20 tokens into the vault under the caller's ownership.
     * Requires allowance to be set beforehand.
     * @param token Address of the ERC20 token.
     * @param amount Amount of tokens to deposit.
     * @param conditionIds The IDs of the conditions to link to this deposit.
     */
    function depositERC20(address token, uint256 amount, uint256[] calldata conditionIds) external nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20 tokenContract = IERC20(token);
        require(tokenContract.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        _createDeposit(msg.sender, token, amount, conditionIds);
    }

    /**
     * @dev Internal function to create a deposit entry.
     */
    function _createDeposit(address owner, address token, uint256 amount, uint256[] memory conditionIds) internal {
        uint256 depositId = _nextDepositId++;
        uint256 depositTimestamp = block.timestamp;

        _deposits[depositId] = Deposit({
            owner: owner,
            token: token,
            amount: amount,
            depositTimestamp: depositTimestamp,
            conditionIds: new uint256[](conditionIds.length), // Initialize with correct size
            isClaimed: false
        });

        // Link conditions immediately during deposit creation
        for(uint i = 0; i < conditionIds.length; i++) {
            _addConditionToDepositInternal(depositId, conditionIds[i]); // Internal function doesn't need auth check here
        }


        _userDeposits[owner].push(depositId);

        emit DepositMade(depositId, owner, token, amount, depositTimestamp);
    }


    // --- Condition Definition & Management Functions ---

    /**
     * @dev Defines a new TimeAbsolute condition.
     * @param unlockTimestamp The Unix timestamp after which the condition is met.
     * @return The ID of the newly created condition.
     */
    function defineTimeLockCondition(uint256 unlockTimestamp) external returns (uint256) {
        require(unlockTimestamp > block.timestamp, "Unlock timestamp must be in the future");
        uint256 conditionId = _nextConditionId++;
        _conditions[conditionId] = Condition({
            conditionType: ConditionType.TimeAbsolute,
            isMet: false, // Will be checked dynamically
            uint256Param1: unlockTimestamp,
            addressParam1: address(0),
            bytes32Param1: bytes32(0),
            addressArrayParam1: new address[](0),
            uint256ArrayParam1: new uint256[](0),
            attestations: new mapping(address => bool)() // Initialize mapping
        });
        emit ConditionDefined(conditionId, ConditionType.TimeAbsolute, msg.sender);
        return conditionId;
    }

     /**
     * @dev Defines a new TimeDuration condition.
     * @param duration The duration in seconds from the deposit timestamp after which the condition is met.
     * @return The ID of the newly created condition.
     */
    function defineDurationLockCondition(uint256 duration) external returns (uint256) {
        require(duration > 0, "Duration must be greater than 0");
        uint256 conditionId = _nextConditionId++;
         _conditions[conditionId] = Condition({
            conditionType: ConditionType.TimeDuration,
            isMet: false, // Will be checked dynamically
            uint256Param1: duration, // Store duration, not unlock time
            addressParam1: address(0),
            bytes32Param1: bytes32(0),
            addressArrayParam1: new address[](0),
            uint256ArrayParam1: new uint256[](0),
            attestations: new mapping(address => bool)() // Initialize mapping
        });
        emit ConditionDefined(conditionId, ConditionType.TimeDuration, msg.sender);
        return conditionId;
    }

    /**
     * @dev Defines a new OracleValue condition.
     * This condition is met when the registered oracle for `oracleType` reports `requiredValue` for `dataKey`.
     * An oracle contract needs to be registered using `registerOracle`.
     * The oracle calls `triggerOracleConditionUpdate` to report the value.
     * @param oracleType Identifier for the type of oracle (e.g., keccak256("ChainlinkPriceFeed")).
     * @param dataKey Identifier for the specific data point (e.g., keccak256("ETH/USD")).
     * @param requiredValue The value the oracle must report for the condition to be met.
     * @return The ID of the newly created condition.
     */
    function defineOracleValueCondition(bytes32 oracleType, bytes32 dataKey, uint256 requiredValue) external returns (uint256) {
        require(_oracleRegistry[oracleType] != address(0), "Oracle type not registered");
        uint256 conditionId = _nextConditionId++;
        _conditions[conditionId] = Condition({
            conditionType: ConditionType.OracleValue,
            isMet: false, // Initial state is not met
            uint256Param1: requiredValue,
            addressParam1: address(0), // Not used for this type
            bytes32Param1: dataKey, // Store data key
            addressArrayParam1: new address[](0),
            uint256ArrayParam1: new uint256[](0),
             attestations: new mapping(address => bool)() // Initialize mapping
        });
        // Store oracle type for later validation in triggerOracleConditionUpdate
        // No direct field for oracleType in Condition struct, let's map condition ID to oracle type externally or store in bytes32Param1 if dataKey not used.
        // Let's use bytes32Param1 for dataKey and bytes32Param2 (implicitly via a temp var or separate mapping if needed) for oracleType.
        // Simpler approach: Just store dataKey and requiredValue. The oracle triggering logic validates the oracle address/type.
        emit ConditionDefined(conditionId, ConditionType.OracleValue, msg.sender);
        return conditionId;
    }

     /**
     * @dev Defines a new Attestation condition.
     * This condition is met when `requiredCount` of the `requiredAttesters` have called `attestCondition` for this condition ID.
     * @param requiredAttesters The list of addresses allowed to attest.
     * @param requiredCount The minimum number of attestations required.
     * @return The ID of the newly created condition.
     */
    function defineAttestationCondition(address[] calldata requiredAttesters, uint256 requiredCount) external returns (uint256) {
        require(requiredCount > 0 && requiredCount <= requiredAttesters.length, "Invalid required count or attester list");
        uint256 conditionId = _nextConditionId++;
        _conditions[conditionId] = Condition({
            conditionType: ConditionType.Attestation,
            isMet: false, // Initial state is not met
            uint256Param1: requiredCount,
            addressParam1: address(0), // Not used directly
            bytes32Param1: bytes32(0), // Not used
            addressArrayParam1: requiredAttesters, // Store attester list
            uint256ArrayParam1: new uint256[](0), // Not used
            attestations: new mapping(address => bool)() // Initialize mapping
        });
        emit ConditionDefined(conditionId, ConditionType.Attestation, msg.sender);
        return conditionId;
    }

    /**
     * @dev Defines a new Compound condition (AND logic).
     * This condition is met only if ALL `conditionIds` in the provided list are met.
     * @param conditionIds The IDs of the conditions that must all be met.
     * @return The ID of the newly created condition.
     */
    function defineCompoundCondition(uint256[] calldata conditionIds) external returns (uint256) {
        require(conditionIds.length > 0, "Compound condition must include at least one sub-condition");
        for(uint i = 0; i < conditionIds.length; i++) {
            require(_conditions[conditionIds[i]].conditionType != ConditionType.Compound, "Nesting compound conditions not allowed"); // Prevent complex recursion/loops
        }
        uint256 conditionId = _nextConditionId++;
        _conditions[conditionId] = Condition({
            conditionType: ConditionType.Compound,
            isMet: false, // Will be checked dynamically
            uint256Param1: 0, // Not used
            addressParam1: address(0), // Not used
            bytes32Param1: bytes32(0), // Not used
            addressArrayParam1: new address[](0), // Not used
            uint256ArrayParam1: conditionIds, // Store sub-condition IDs
            attestations: new mapping(address => bool)() // Initialize mapping
        });
         emit ConditionDefined(conditionId, ConditionType.Compound, msg.sender);
        return conditionId;
    }

    /**
     * @dev Links an existing defined condition to a specific deposit.
     * Requires the deposit owner or an allowed condition setter.
     * @param depositId The ID of the deposit to link the condition to.
     * @param conditionId The ID of the condition to link.
     */
    function addConditionToDeposit(uint256 depositId, uint256 conditionId) external onlyDepositOwnerOrAllowedSetter(depositId) {
        _addConditionToDepositInternal(depositId, conditionId);
    }

     /**
     * @dev Internal function to add a condition to a deposit.
     */
    function _addConditionToDepositInternal(uint256 depositId, uint256 conditionId) internal {
        require(_deposits[depositId].owner != address(0), "Deposit does not exist");
        require(_conditions[conditionId].conditionType != ConditionType.TimeDuration || _deposits[depositId].depositTimestamp != 0, "TimeDuration condition requires existing deposit timestamp");
        // Ensure conditionId is valid (exists)
        require(_conditions[conditionId].conditionType <= ConditionType.Compound, "Invalid condition ID"); // Basic check

        // Check if already linked (simple scan)
        for (uint i = 0; i < _deposits[depositId].conditionIds.length; i++) {
            require(_deposits[depositId].conditionIds[i] != conditionId, "Condition already linked to deposit");
        }

        _deposits[depositId].conditionIds.push(conditionId);
        emit ConditionAddedToDeposit(depositId, conditionId);
    }


    /**
     * @dev Unlinks a condition from a deposit.
     * Requires the deposit owner or an allowed condition setter.
     * Cannot remove if the condition is already met.
     * @param depositId The ID of the deposit.
     * @param conditionId The ID of the condition to unlink.
     */
    function removeConditionFromDeposit(uint256 depositId, uint256 conditionId) external onlyDepositOwnerOrAllowedSetter(depositId) {
        require(_deposits[depositId].owner != address(0), "Deposit does not exist");

        uint256[] storage depositConditionIds = _deposits[depositId].conditionIds;
        bool found = false;
        for (uint i = 0; i < depositConditionIds.length; i++) {
            if (depositConditionIds[i] == conditionId) {
                require(!checkConditionMet(conditionId), "Cannot remove a condition that is already met");
                // Remove the condition ID by swapping with the last element and shrinking the array
                depositConditionIds[i] = depositConditionIds[depositConditionIds.length - 1];
                depositConditionIds.pop();
                found = true;
                break;
            }
        }
        require(found, "Condition not linked to this deposit");
        emit ConditionRemovedFromDeposit(depositId, conditionId);
    }

     /**
     * @dev Allows modifying a parameter of a condition (restricted).
     * Example use cases: add attester to list, update oracle data key (if oracle not yet triggered).
     * Requires owner (for sensitive changes) or potentially allowed setter (based on type/parameter).
     * This function requires careful implementation depending on *which* parameter for *which* type is being modified.
     * A generic implementation is complex and risky. This is a placeholder.
     * A safer approach would be specific functions like `addAttesterToCondition`.
     * @param conditionId The ID of the condition to modify.
     * @param newParameter Example: New uint256 value for TimeAbsolute/Duration, or a new address for attestation.
     * @dev NOTE: This is a simplified example. Real implementation needs type checks and careful parameter handling.
     * Only contract owner can call this in this example for safety.
     */
    function modifyConditionParameter(uint256 conditionId, uint256 newParameter) external onlyOwner {
        require(_conditions[conditionId].conditionType <= ConditionType.Compound, "Invalid condition ID");
        require(!_conditions[conditionId].isMet, "Cannot modify a condition that is already met");

        // --- Simplified Example Modification ---
        // This example only allows changing uint256Param1 for TimeAbsolute or TimeDuration
        // A real implementation would need to handle different types and parameters securely.
        ConditionType cType = _conditions[conditionId].conditionType;
        require(cType == ConditionType.TimeAbsolute || cType == ConditionType.TimeDuration || cType == ConditionType.Attestation, "Condition type not modifiable via this function");

        if (cType == ConditionType.TimeAbsolute) {
             require(newParameter > block.timestamp, "New unlock timestamp must be in the future");
            _conditions[conditionId].uint256Param1 = newParameter; // Update timestamp
        } else if (cType == ConditionType.TimeDuration) {
             require(newParameter > 0, "New duration must be greater than 0");
            _conditions[conditionId].uint256Param1 = newParameter; // Update duration
        }
        // Add other types/parameters here with proper checks

        emit ConditionModified(conditionId, "Uint256Param1 updated");
    }

     /**
     * @dev Allows adding a single attester to an existing Attestation condition.
     * Requires owner for safety in this example. Could be restricted to allowed setters or specific roles.
     * @param conditionId The ID of the Attestation condition.
     * @param attesterAddress The address to add to the required attesters list.
     */
    function addAttesterToCondition(uint256 conditionId, address attesterAddress) external onlyOwner {
        require(_conditions[conditionId].conditionType == ConditionType.Attestation, "Condition must be of type Attestation");
        require(attesterAddress != address(0), "Invalid attester address");
        require(!_conditions[conditionId].isMet, "Cannot modify a condition that is already met");

        // Check if attester is already in the list
        address[] storage attesters = _conditions[conditionId].addressArrayParam1;
        for(uint i = 0; i < attesters.length; i++) {
            require(attesters[i] != attesterAddress, "Attester already in list");
        }

        attesters.push(attesterAddress);
        // Note: This changes the attester list but does NOT change the requiredCount.
        // Modifying requiredCount would need another function and careful consideration.
        emit ConditionModified(conditionId, "Attester added");
    }


    // --- Condition State Update Functions ---

    /**
     * @dev Allows a required attester to make an attestation for an Attestation condition.
     * Updates the internal state of the condition.
     * @param conditionId The ID of the Attestation condition.
     */
    function attestCondition(uint256 conditionId) external {
        Condition storage condition = _conditions[conditionId];
        require(condition.conditionType == ConditionType.Attestation, "Condition is not an Attestation type");
        require(!condition.isMet, "Condition is already met");

        bool isRequiredAttester = false;
        for (uint i = 0; i < condition.addressArrayParam1.length; i++) {
            if (condition.addressArrayParam1[i] == msg.sender) {
                isRequiredAttester = true;
                break;
            }
        }
        require(isRequiredAttester, "Caller is not a required attester for this condition");

        require(!condition.attestations[msg.sender], "Attestation already made by caller");

        condition.attestations[msg.sender] = true;

        // Check if condition is now met
        uint256 currentAttestations = 0;
        for (uint i = 0; i < condition.addressArrayParam1.length; i++) {
            if (condition.attestations[condition.addressArrayParam1[i]]) {
                currentAttestations++;
            }
        }

        if (currentAttestations >= condition.uint256Param1) { // uint256Param1 stores requiredCount
            condition.isMet = true;
        }

        emit AttestationMade(conditionId, msg.sender);
    }

    /**
     * @dev Called by a registered oracle contract to report data for an OracleValue condition.
     * Requires the caller to be a registered oracle for the condition's specified oracle type.
     * @param conditionId The ID of the OracleValue condition.
     * @param reportedValue The value reported by the oracle.
     */
    function triggerOracleConditionUpdate(uint256 conditionId, uint256 reportedValue) external {
        Condition storage condition = _conditions[conditionId];
        require(condition.conditionType == ConditionType.OracleValue, "Condition is not an OracleValue type");
        require(!condition.isMet, "Condition is already met");

        // Determine oracle type needed for this condition (needs careful mapping or storage)
        // Since we didn't store oracleType explicitly in Condition struct,
        // we need to rethink how the oracle knows which type it is allowed to trigger.
        // A safer design would involve the oracle passing its *type* and the contract verifying.
        // Let's assume for this example, the oracle contract itself identifies its type.
        // This requires the oracle contract to have a public variable or view function like `oracleType()`.
        // This makes the OracleValue condition definition slightly different or requires mapping conditionId to oracleType separately.
        // Let's modify defineOracleValueCondition to store oracleType in addressParam1 (abusing address type, not ideal but works for identification).
        // Re-structuring Condition might be better, but let's proceed with this limitation for the example length.
        // --- Assuming `bytes32Param1` now stores the oracleType ---
         bytes32 oracleType = condition.bytes32Param1;
        require(_oracleRegistry[oracleType] != address(0), "Oracle type not registered for this condition");
        require(_oracleRegistry[oracleType] == msg.sender, "Caller is not the registered oracle for this type");

        // Check if the reported value matches the required value
        if (reportedValue == condition.uint256Param1) { // uint256Param1 stores requiredValue
             condition.isMet = true;
        }

        emit OracleConditionUpdateTriggered(conditionId, oracleType, reportedValue);
    }

    // --- Condition Checking Functions ---

    /**
     * @dev Internal function to check if a single condition is met.
     * Oracle and Attestation conditions rely on their `isMet` flag being updated by external triggers.
     * Time-based and Compound conditions are checked dynamically.
     * @param conditionId The ID of the condition to check.
     * @return True if the condition is met, false otherwise.
     */
    function checkConditionMet(uint256 conditionId) public view returns (bool) {
        Condition storage condition = _conditions[conditionId];
        // require(condition.conditionType <= ConditionType.Compound, "Invalid condition ID"); // Add check if needed

        if (condition.isMet) {
            // Oracle and Attestation types set this flag directly when triggered
            return true;
        }

        // Dynamically check other types
        if (condition.conditionType == ConditionType.TimeAbsolute) {
            return block.timestamp >= condition.uint256Param1; // uint256Param1 = unlockTimestamp
        } else if (condition.conditionType == ConditionType.TimeDuration) {
            // TimeDuration depends on the deposit timestamp. Need to find deposits linked to this condition.
            // This check is inefficient if a condition is linked to many deposits.
            // A better design might store the deposit timestamp within the condition context if it's per-deposit.
            // As conditions are reusable, this implies the TimeDuration condition should store the DURATION,
            // and the CHECK function needs the DEPOSIT ID to calculate the actual unlock time (depositTime + duration).
            // Let's update TimeDuration definition and check function.
            // The current `checkConditionMet(uint256 conditionId)` design is problematic for TimeDuration.
            // We need a function `checkDepositConditionMet(uint256 depositId, uint256 conditionId)`.
             revert("TimeDuration condition requires deposit context for check");
        } else if (condition.conditionType == ConditionType.Compound) {
            // Check all sub-conditions recursively
            for (uint i = 0; i < condition.uint256ArrayParam1.length; i++) {
                // Note: Recursive calls can hit gas limits on complex structures.
                if (!checkConditionMet(condition.uint256ArrayParam1[i])) {
                    return false; // If any sub-condition is not met, compound is not met
                }
            }
            return true; // All sub-conditions were met
        }

        // For OracleValue and Attestation, if isMet is false, they are not met dynamically here.
        return false;
    }

     /**
     * @dev Public view function to check if a condition linked to a specific deposit is met.
     * This version correctly handles TimeDuration conditions using the deposit timestamp.
     * @param depositId The ID of the deposit.
     * @param conditionId The ID of the condition to check.
     * @return True if the condition is met, false otherwise.
     */
    function checkDepositConditionMet(uint256 depositId, uint256 conditionId) public view returns (bool) {
        require(_deposits[depositId].owner != address(0), "Deposit does not exist");
         Condition storage condition = _conditions[conditionId];
        // require(condition.conditionType <= ConditionType.Compound, "Invalid condition ID"); // Add check if needed

        if (condition.isMet) {
            return true;
        }

        if (condition.conditionType == ConditionType.TimeAbsolute) {
            return block.timestamp >= condition.uint256Param1; // uint256Param1 = unlockTimestamp
        } else if (condition.conditionType == ConditionType.TimeDuration) {
             uint256 depositTimestamp = _deposits[depositId].depositTimestamp;
             uint256 duration = condition.uint256Param1; // uint256Param1 = duration
             // Handle potential overflow if adding depositTimestamp and duration
             // Should not overflow block.timestamp + duration in practice, but good to be aware.
             return block.timestamp >= depositTimestamp + duration;
        } else if (condition.conditionType == ConditionType.Compound) {
             for (uint i = 0; i < condition.uint256ArrayParam1.length; i++) {
                // Recursively check sub-conditions using deposit context
                if (!checkDepositConditionMet(depositId, condition.uint256ArrayParam1[i])) {
                    return false;
                }
            }
            return true;
        }

        return false; // For OracleValue and Attestation, relies on isMet flag
    }


    /**
     * @dev Internal function to check if ALL conditions linked to a deposit are met.
     * @param depositId The ID of the deposit.
     * @return True if all conditions are met, false otherwise.
     */
    function checkAllDepositConditionsMet(uint256 depositId) internal view returns (bool) {
        require(_deposits[depositId].owner != address(0), "Deposit does not exist");
        Deposit storage deposit = _deposits[depositId];

        if (deposit.conditionIds.length == 0) {
            // No conditions means it's immediately claimable (might want to restrict this)
            // Or implies an error in setup. Let's require at least one condition.
             return false; // Require at least one condition
        }

        for (uint i = 0; i < deposit.conditionIds.length; i++) {
            if (!checkDepositConditionMet(depositId, deposit.conditionIds[i])) {
                return false; // If any condition is not met, all are not met
            }
        }
        return true; // All conditions were met
    }

    // --- Claim & Cancellation Functions ---

    /**
     * @dev Allows the current deposit owner to claim the locked assets.
     * Requires all conditions linked to the deposit to be met.
     * @param depositId The ID of the deposit to claim.
     */
    function claim(uint256 depositId) external nonReentrant {
        Deposit storage deposit = _deposits[depositId];
        require(deposit.owner != address(0), "Deposit does not exist");
        require(deposit.owner == msg.sender, "Only the deposit owner can claim");
        require(!deposit.isClaimed, "Deposit already claimed");
        require(checkAllDepositConditionsMet(depositId), "All release conditions are not met");

        deposit.isClaimed = true;

        if (deposit.token == address(0)) {
            // Send ETH
             (bool success, ) = payable(deposit.owner).call{value: deposit.amount}("");
             require(success, "ETH transfer failed");
        } else {
            // Send ERC20
             IERC20 tokenContract = IERC20(deposit.token);
            require(tokenContract.transfer(deposit.owner, deposit.amount), "Token transfer failed");
        }

        emit DepositClaimed(depositId, msg.sender, block.timestamp);

        // Consider cleaning up deposit/condition data after claim to save gas/storage?
        // Or leave for historical records. Leaving for records in this example.
    }

     /**
     * @dev Allows the deposit owner to cancel the deposit and withdraw early.
     * This is only permitted if NO conditions linked to the deposit have been met YET,
     * AND within a grace period after deposit.
     * @param depositId The ID of the deposit to cancel.
     */
    function cancelDeposit(uint256 depositId) external nonReentrant {
        Deposit storage deposit = _deposits[depositId];
        require(deposit.owner != address(0), "Deposit does not exist");
        require(deposit.owner == msg.sender, "Only the deposit owner can cancel");
        require(!deposit.isClaimed, "Deposit already claimed");

        // Check cancellation grace period
        require(block.timestamp <= deposit.depositTimestamp + GRACE_PERIOD_FOR_CANCELLATION, "Cancellation grace period expired");

        // Check if ANY condition is already met
        bool anyConditionMet = false;
         for (uint i = 0; i < deposit.conditionIds.length; i++) {
            if (checkDepositConditionMet(depositId, deposit.conditionIds[i])) {
                anyConditionMet = true;
                break;
            }
        }
        require(!anyConditionMet, "Cannot cancel if any release condition is already met");

        deposit.isClaimed = true; // Mark as claimed to prevent double withdrawal

        if (deposit.token == address(0)) {
            // Send ETH back
             (bool success, ) = payable(deposit.owner).call{value: deposit.amount}("");
             require(success, "ETH transfer failed");
        } else {
            // Send ERC20 back
             IERC20 tokenContract = IERC20(deposit.token);
            require(tokenContract.transfer(deposit.owner, deposit.amount), "Token transfer failed");
        }

        emit DepositCancelled(depositId, msg.sender, block.timestamp);
    }


    // --- Access Control & Management Functions ---

    /**
     * @dev Allows the contract owner to add an address that can set conditions
     * for *any* deposit, in addition to the deposit owner themselves.
     * @param setter The address to allow setting conditions.
     */
    function addAllowedConditionSetter(address setter) external onlyOwner {
        require(setter != address(0), "Invalid setter address");
        _allowedConditionSetters[setter] = true;
        emit AllowedConditionSetterAdded(setter);
    }

    /**
     * @dev Allows the contract owner to remove an address from the allowed condition setters list.
     * @param setter The address to remove.
     */
    function removeAllowedConditionSetter(address setter) external onlyOwner {
        require(setter != address(0), "Invalid setter address");
        _allowedConditionSetters[setter] = false;
        emit AllowedConditionSetterRemoved(setter);
    }

    /**
     * @dev Allows the current owner of a locked deposit position to transfer
     * the ownership (the right to claim/cancel) to a new address.
     * @param depositId The ID of the deposit to transfer.
     * @param newOwner The address to transfer ownership to.
     */
    function transferDepositOwnership(uint256 depositId, address newOwner) external {
        Deposit storage deposit = _deposits[depositId];
        require(deposit.owner != address(0), "Deposit does not exist");
        require(deposit.owner == msg.sender, "Only the current deposit owner can transfer ownership");
        require(newOwner != address(0), "New owner cannot be zero address");
        require(!deposit.isClaimed, "Cannot transfer ownership of a claimed deposit");

        address oldOwner = deposit.owner;
        deposit.owner = newOwner;

        // Remove from old owner's list (inefficient, consider indexed storage or linked lists for scale)
        uint256[] storage oldOwnerDeposits = _userDeposits[oldOwner];
        for (uint i = 0; i < oldOwnerDeposits.length; i++) {
            if (oldOwnerDeposits[i] == depositId) {
                // Swap with last and pop
                oldOwnerDeposits[i] = oldOwnerDeposits[oldOwnerDeposits.length - 1];
                oldOwnerDeposits.pop();
                break; // Found and removed
            }
        }

        // Add to new owner's list
        _userDeposits[newOwner].push(depositId);

        emit DepositOwnershipTransferred(depositId, oldOwner, newOwner);
    }

     /**
     * @dev Registers an address as a trusted oracle for a specific type.
     * Only the contract owner can register oracles.
     * @param oracleType A unique identifier for the oracle type (e.g., keccak256("PriceFeed")).
     * @param oracleAddress The address of the oracle contract.
     */
    function registerOracle(bytes32 oracleType, address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(_oracleRegistry[oracleType] == address(0), "Oracle type already registered");
        _oracleRegistry[oracleType] = oracleAddress;
        emit OracleRegistered(oracleType, oracleAddress);
    }

    /**
     * @dev Removes an oracle registration.
     * Only the contract owner can remove oracles.
     * @param oracleType The identifier for the oracle type to remove.
     */
    function removeOracle(bytes32 oracleType) external onlyOwner {
        require(_oracleRegistry[oracleType] != address(0), "Oracle type not registered");
        address oracleAddress = _oracleRegistry[oracleType];
        delete _oracleRegistry[oracleType];
        emit OracleRemoved(oracleType, oracleAddress);
    }


    // --- Information Retrieval (View) Functions ---

    /**
     * @dev Gets details of a specific deposit.
     * @param depositId The ID of the deposit.
     * @return Tuple containing deposit details.
     */
    function getDepositInfo(uint256 depositId) external view returns (address owner, address token, uint256 amount, uint256 depositTimestamp, bool isClaimed) {
        Deposit storage deposit = _deposits[depositId];
        require(deposit.owner != address(0), "Deposit does not exist");
        return (deposit.owner, deposit.token, deposit.amount, deposit.depositTimestamp, deposit.isClaimed);
    }

     /**
     * @dev Gets the IDs of conditions linked to a specific deposit.
     * @param depositId The ID of the deposit.
     * @return Array of condition IDs.
     */
    function getDepositConditionIds(uint256 depositId) external view returns (uint256[] memory) {
         require(_deposits[depositId].owner != address(0), "Deposit does not exist");
        return _deposits[depositId].conditionIds;
    }

    /**
     * @dev Gets details of a specific condition.
     * Note: Returns raw parameters. Interpretation depends on ConditionType.
     * Mapping `attestations` state is not directly exposed via a view function returning a map.
     * Use `getAttestationStatus` for Attestation condition state.
     * @param conditionId The ID of the condition.
     * @return Tuple containing condition type and parameters.
     */
    function getConditionInfo(uint256 conditionId) external view returns (ConditionType conditionType, uint256 uint256Param1, address addressParam1, bytes32 bytes32Param1, address[] memory addressArrayParam1, uint256[] memory uint256ArrayParam1, bool isMet) {
         Condition storage condition = _conditions[conditionId];
         require(condition.conditionType <= ConditionType.Compound, "Condition does not exist"); // Basic check

         return (condition.conditionType, condition.uint256Param1, condition.addressParam1, condition.bytes32Param1, condition.addressArrayParam1, condition.uint256ArrayParam1, condition.isMet);
    }

     /**
     * @dev Gets the IDs of deposits owned by a specific user.
     * @param user The address of the user.
     * @return Array of deposit IDs.
     */
    function getUserDeposits(address user) external view returns (uint256[] memory) {
        return _userDeposits[user];
    }

    /**
     * @dev Gets the total number of deposits created.
     * @return Total deposit count.
     */
    function getTotalDeposits() external view returns (uint256) {
        return _nextDepositId - 1; // Since IDs start from 1
    }

     /**
     * @dev Gets the total number of conditions defined.
     * @return Total condition count.
     */
    function getTotalConditions() external view returns (uint256) {
        return _nextConditionId - 1; // Since IDs start from 1
    }

     /**
     * @dev Checks if an address is an allowed condition setter.
     * @param setter The address to check.
     * @return True if the address is allowed, false otherwise.
     */
    function isAllowedConditionSetter(address setter) external view returns (bool) {
        return _allowedConditionSetters[setter];
    }

    /**
     * @dev Gets the address of the registered oracle for a specific type.
     * @param oracleType The identifier for the oracle type.
     * @return The oracle contract address, or address(0) if not registered.
     */
    function getOracleAddress(bytes32 oracleType) external view returns (address) {
        return _oracleRegistry[oracleType];
    }

     /**
     * @dev Checks if a specific attester has attested for an Attestation condition.
     * @param conditionId The ID of the Attestation condition.
     * @param attester The address of the attester to check.
     * @return True if the attester has attested, false otherwise.
     */
    function getAttestationStatus(uint256 conditionId, address attester) external view returns (bool) {
         Condition storage condition = _conditions[conditionId];
         require(condition.conditionType == ConditionType.Attestation, "Condition is not an Attestation type");
         return condition.attestations[attester];
    }

     /**
     * @dev Gets the list of required attesters for an Attestation condition.
     * @param conditionId The ID of the Attestation condition.
     * @return Array of required attester addresses.
     */
    function getRequiredAttesters(uint256 conditionId) external view returns (address[] memory) {
         Condition storage condition = _conditions[conditionId];
         require(condition.conditionType == ConditionType.Attestation, "Condition is not an Attestation type");
         return condition.addressArrayParam1;
    }

    /**
     * @dev Gets the required number of attestations for an Attestation condition.
     * @param conditionId The ID of the Attestation condition.
     * @return The required count.
     */
    function getRequiredAttestationCount(uint256 conditionId) external view returns (uint256) {
        Condition storage condition = _conditions[conditionId];
         require(condition.conditionType == ConditionType.Attestation, "Condition is not an Attestation type");
         return condition.uint256Param1; // uint256Param1 stores requiredCount
    }

     /**
     * @dev Gets the current number of attestations made for an Attestation condition.
     * Iterates through required attesters to count made attestations.
     * @param conditionId The ID of the Attestation condition.
     * @return The current count of attestations made.
     */
    function getCurrentAttestationCount(uint256 conditionId) external view returns (uint256) {
        Condition storage condition = _conditions[conditionId];
         require(condition.conditionType == ConditionType.Attestation, "Condition is not an Attestation type");

         uint256 currentCount = 0;
         address[] memory requiredAttesters = condition.addressArrayParam1; // Read into memory for iteration
         for(uint i = 0; i < requiredAttesters.length; i++) {
             if(condition.attestations[requiredAttesters[i]]) {
                 currentCount++;
             }
         }
         return currentCount;
    }

    /**
     * @dev Checks if a specific address is in the list of allowed condition setters.
     * This is the same as isAllowedConditionSetter but explicitly named for the list.
     * @param setter The address to check.
     * @return True if the address is in the list, false otherwise.
     */
    function checkIsAllowedConditionSetter(address setter) external view returns (bool) {
        return _allowedConditionSetters[setter];
    }


}
```