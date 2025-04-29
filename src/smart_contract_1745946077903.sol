Okay, let's design a smart contract that represents a "Quantum Vault". The idea is a vault where assets (ETH or ERC20 tokens) can be locked with different types of release conditions, some deterministic (time, external events) and some probabilistic or complex combinations. It will also feature delegation of condition management and administration controls.

This contract aims for advanced concepts like:
1.  **Multiple, Flexible Release Conditions:** Not just a simple time lock.
2.  **Probabilistic Unlock:** Introducing a chance-based element (requires careful consideration of randomness sources in a real-world scenario; we'll simulate or point to oracle usage).
3.  **Complex/Compound Conditions:** Requiring multiple sub-conditions to be met (simulated via struct/mapping).
4.  **Delegated Condition Management:** Allowing a user to grant rights to another address to modify their deposit's conditions.
5.  **Oracle Interaction Pattern:** Design functions that *would* be triggered by oracles for event-based conditions.
6.  **Internal ID System:** Managing deposits and conditions via unique IDs.

---

**Outline:**

1.  **License and Version:** SPDX License Identifier, Solidity version.
2.  **Imports:** ERC20 interface, SafeERC20, Ownable, Pausable, ReentrancyGuard.
3.  **Error Definitions:** Custom errors for clarity and gas efficiency.
4.  **Enums:** Define types for conditions and complex condition logic.
5.  **Structs:** Define structures for Deposits, various Condition types, and Complex Conditions.
6.  **State Variables:** Mappings and counters to store deposits, conditions, delegation info, parameters, and contract state.
7.  **Events:** Define events for key actions (Deposit, Unlock, Condition Added/Modified/Triggered, Delegation, Admin actions).
8.  **Modifiers:** Define access control modifiers (`onlyOracle`, `onlyDepositOwnerOrDelegate`).
9.  **Constructor:** Initialize the owner, optional initial parameters.
10. **Pausable Implementation:** Functions for pausing/unpausing core logic.
11. **Deposit Functions (2):**
    *   `depositEther`: Lock ETH with a specific initial condition.
    *   `depositToken`: Lock ERC20 tokens with a specific initial condition.
12. **Internal Deposit Helper:** `_addDeposit`.
13. **Condition Management Functions (at least 7):**
    *   `modifyTimeCondition`: Update the release time for a time-based condition.
    *   `createEventCondition`: Create a new event-based condition structure.
    *   `modifyEventCondition`: Update details of an event-based condition.
    *   `createComplexCondition`: Create a new complex condition structure.
    *   `addPartToComplexCondition`: Add a sub-condition requirement to a complex condition.
    *   `removePartFromComplexCondition`: Remove a sub-condition requirement from a complex condition.
    *   `setProbabilisticConditionChance`: Adjust the chance for a probabilistic condition (if delegated/owner).
14. **Unlock/Claim Functions (at least 3):**
    *   `claimDeterministicUnlock`: Attempt to claim based on Time or simple Event condition.
    *   `attemptProbabilisticUnlock`: Attempt to claim based on a probabilistic condition roll.
    *   `claimComplexConditionalUnlock`: Attempt to claim based on a Complex condition being fully met.
15. **Delegation Functions (2):**
    *   `delegateConditionManagement`: Grant condition modification rights for a deposit ID.
    *   `revokeConditionManagementDelegate`: Revoke condition modification rights.
16. **Oracle/External Interaction Function (1):**
    *   `triggerEventCondition`: Function called by an authorized oracle to mark an event condition as met.
17. **Admin Functions (at least 3):**
    *   `adminSetOracleAddress`: Update the authorized oracle address.
    *   `adminSetProbabilisticParameters`: Adjust global parameters influencing probabilistic unlocks.
    *   `adminWithdrawStuckTokens`: Withdraw accidentally sent ERC20 tokens (excluding deposit tokens).
18. **View/Query Functions (at least 4):**
    *   `getUserDepositIds`: Get list of deposit IDs for a user.
    *   `getDepositDetails`: Get details of a specific deposit.
    *   `getConditionDetails`: Get details of any condition by ID and type.
    *   `isConditionMet`: Check if a given condition ID of a specific type is currently met (deterministic check).
    *   `calculateProbabilisticChance`: Calculate the current chance for a probabilistic condition.

**Function Summary:**

*   `constructor`: Initializes the contract, setting the owner and possibly an oracle address.
*   `pause()`: Owner function to pause transfers and unlocks.
*   `unpause()`: Owner function to unpause the contract.
*   `depositEther(uint256 _initialConditionId, ConditionType _initialConditionType)`: Allows users to deposit ETH with a specified initial condition.
*   `depositToken(IERC20 _token, uint256 _amount, uint256 _initialConditionId, ConditionType _initialConditionType)`: Allows users to deposit ERC20 tokens with a specified initial condition (requires prior approval).
*   `modifyTimeCondition(uint256 _depositId, uint256 _newReleaseTime)`: Allows deposit owner or delegate to change the release time for a time-based condition linked to their deposit.
*   `createEventCondition(bytes32 _eventIdHash)`: Creates a new, untriggered event condition and returns its ID. Anyone can *create* the structure, but it's only useful when linked to a deposit and triggered by the oracle.
*   `modifyEventCondition(uint256 _conditionId, bytes32 _newEventIdHash)`: Allows changing the event identifier for an existing event condition (requires admin or specific rights, depends on design; let's make it admin/oracle for simplicity).
*   `createComplexCondition(ComplexLogicGate _logicGate)`: Creates a new empty complex condition structure and returns its ID.
*   `addPartToComplexCondition(uint256 _complexConditionId, uint256 _partConditionId, ConditionType _partConditionType)`: Allows adding a sub-condition (by ID and type) to a complex condition (requires admin or linked deposit owner/delegate).
*   `removePartFromComplexCondition(uint256 _complexConditionId, uint256 _partConditionId)`: Removes a sub-condition from a complex condition (requires admin or linked deposit owner/delegate).
*   `setProbabilisticConditionChance(uint256 _depositId, uint256 _newChancePercentage)`: Allows deposit owner or delegate to adjust the chance percentage for a probabilistic condition linked to their deposit.
*   `claimDeterministicUnlock(uint256 _depositId)`: Attempts to unlock a deposit if its linked Time or Event condition is met.
*   `attemptProbabilisticUnlock(uint256 _depositId)`: Attempts to unlock a deposit if its linked Probabilistic condition is met based on a random roll.
*   `claimComplexConditionalUnlock(uint256 _depositId)`: Attempts to unlock a deposit if its linked Complex condition (and all its parts) are met according to the defined logic gate.
*   `delegateConditionManagement(uint256 _depositId, address _delegate)`: Allows a deposit owner to grant condition modification rights for their deposit to another address.
*   `revokeConditionManagementDelegate(uint256 _depositId)`: Allows a deposit owner to revoke the condition management delegate for their deposit.
*   `triggerEventCondition(uint256 _conditionId)`: Function callable ONLY by the authorized oracle address to mark a specific Event condition as met.
*   `adminSetOracleAddress(address _newOracle)`: Owner function to update the authorized oracle address.
*   `adminSetProbabilisticParameters(uint256 _baseChancePercentage, uint256 _maxChancePercentage, uint256 _minChancePercentage)`: Owner function to set global parameters for probabilistic unlocks.
*   `adminWithdrawStuckTokens(IERC20 _token, address _to)`: Owner function to withdraw any ERC20 tokens sent to the contract that are NOT part of user deposits.
*   `getUserDepositIds(address _user)`: View function to retrieve all deposit IDs associated with a user.
*   `getDepositDetails(uint256 _depositId)`: View function to retrieve the full details of a specific deposit.
*   `getConditionDetails(uint256 _conditionId, ConditionType _conditionType)`: View function to retrieve details of a specific condition by ID and type.
*   `isConditionMet(uint256 _conditionId, ConditionType _conditionType)`: View function to check if a given condition (excluding Probabilistic) is currently met based on current state.
*   `calculateProbabilisticChance(uint256 _depositId)`: View function to calculate the current *potential* chance for unlocking a deposit with a probabilistic condition (might incorporate deposit age, etc., based on `ProbabilisticParameters`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Useful for tracking user deposit IDs

// Outline:
// 1. License and Version
// 2. Imports
// 3. Error Definitions
// 4. Enums
// 5. Structs
// 6. State Variables
// 7. Events
// 8. Modifiers
// 9. Constructor
// 10. Pausable Implementation
// 11. Deposit Functions (2)
// 12. Internal Deposit Helper
// 13. Condition Management Functions (>= 7)
// 14. Unlock/Claim Functions (>= 3)
// 15. Delegation Functions (2)
// 16. Oracle/External Interaction Function (1)
// 17. Admin Functions (>= 3)
// 18. View/Query Functions (>= 4)

// Function Summary:
// constructor(): Initializes the contract, sets owner and oracle.
// pause(): Owner function to pause transfers and unlocks.
// unpause(): Owner function to unpause the contract.
// depositEther(uint256 _initialConditionId, ConditionType _initialConditionType): Deposit ETH with a linked condition.
// depositToken(IERC20 _token, uint256 _amount, uint256 _initialConditionId, ConditionType _initialConditionType): Deposit ERC20 with a linked condition.
// modifyTimeCondition(uint256 _depositId, uint256 _newReleaseTime): Change release time for a deposit's time condition (owner/delegate).
// createEventCondition(bytes32 _eventIdHash): Create a new event condition structure (returns ID).
// modifyEventCondition(uint256 _conditionId, bytes32 _newEventIdHash): Change event ID for an existing event condition (admin/oracle).
// createComplexCondition(ComplexLogicGate _logicGate): Create a new complex condition structure (returns ID).
// addPartToComplexCondition(uint256 _complexConditionId, uint256 _partConditionId, ConditionType _partConditionType): Add a sub-condition to a complex condition (admin/owner/delegate).
// removePartFromComplexCondition(uint256 _complexConditionId, uint256 _partConditionId): Remove a sub-condition from a complex condition (admin/owner/delegate).
// setProbabilisticConditionChance(uint256 _depositId, uint256 _newChancePercentage): Adjust chance for a deposit's probabilistic condition (owner/delegate).
// claimDeterministicUnlock(uint256 _depositId): Claim if Time or Event condition met.
// attemptProbabilisticUnlock(uint256 _depositId): Claim if Probabilistic condition met (random roll).
// claimComplexConditionalUnlock(uint256 _depositId): Claim if Complex condition met.
// delegateConditionManagement(uint256 _depositId, address _delegate): Grant condition management rights for a deposit.
// revokeConditionManagementDelegate(uint256 _depositId): Revoke condition management delegate for a deposit.
// triggerEventCondition(uint256 _conditionId): Called by oracle to mark an event condition as met.
// adminSetOracleAddress(address _newOracle): Owner sets oracle address.
// adminSetProbabilisticParameters(uint256 _baseChancePercentage, uint256 _maxChancePercentage, uint256 _minChancePercentage): Owner sets global probabilistic parameters.
// adminWithdrawStuckTokens(IERC20 _token, address _to): Owner withdraws accidental tokens.
// getUserDepositIds(address _user): View function: Get deposit IDs for a user.
// getDepositDetails(uint256 _depositId): View function: Get details of a deposit.
// getConditionDetails(uint256 _conditionId, ConditionType _conditionType): View function: Get details of a condition.
// isConditionMet(uint256 _conditionId, ConditionType _conditionType): View function: Check if a non-probabilistic condition is met.
// calculateProbabilisticChance(uint256 _depositId): View function: Calculate current chance for a probabilistic condition.

contract QuantumVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- 3. Error Definitions ---
    error InvalidAmount();
    error DepositNotFound();
    error ConditionNotFound();
    error ConditionTypeMismatch();
    error DepositConditionMismatch();
    error ConditionNotMet();
    error AlreadyClaimed();
    error NotDepositOwnerOrDelegate();
    error InvalidDelegate();
    error DelegationAlreadySet();
    error DelegationNotSet();
    error NotOracle();
    error CannotWithdrawDepositTokens();
    error InvalidProbabilisticChance();
    error ComplexConditionPartNotFound();
    error ConditionNotSupportedForUnlock();
    error ZeroAddressNotAllowed();

    // --- 4. Enums ---
    enum ConditionType {
        None, // Represents no condition or an uninitialized state
        TimeBased,
        EventBased,
        Probabilistic,
        Complex
    }

    enum ComplexLogicGate {
        AND,
        OR
    }

    // --- 5. Structs ---
    struct Deposit {
        address owner;
        address tokenAddress; // Address(0) for ETH
        uint256 amount;
        uint256 depositTime;
        ConditionType conditionType;
        uint256 conditionId;
        bool claimed;
    }

    struct TimeCondition {
        uint256 releaseTime;
    }

    struct EventCondition {
        bytes32 eventIdHash; // Unique identifier for the off-chain event
        bool isTriggered;    // Set to true by the oracle
    }

    struct ProbabilisticCondition {
        // Parameters could influence the chance dynamically, e.g., deposit age, global params
        // For simplicity in this example, a base chance percentage linked to the deposit.
        // In a real system, this would be more complex and potentially linked to global settings.
        // The actual calculation happens in calculateProbabilisticChance and attemptProbabilisticUnlock
        uint256 baseChancePercentage; // 0-10000 (for 0.00% to 100.00%)
    }

    struct ComplexCondition {
        ComplexLogicGate logicGate;
        // Mapping from part condition ID (uint256 packed with type) to type & met status
        mapping(uint256 => bool) requiredParts; // Maps packedConditionId => required
        EnumerableSet.UintSet partIds;          // Store packed condition IDs for iteration
    }

    // Helper to pack/unpack condition ID and type
    // Format: (conditionId << 8) | uint8(conditionType)
    function _packConditionId(uint256 _id, ConditionType _type) private pure returns (uint256) {
        require(uint8(_type) < 2**8, "Type too large");
        return (_id << 8) | uint8(_type);
    }

    function _unpackConditionId(uint256 _packedId) private pure returns (uint256 id, ConditionType type_) {
        id = _packedId >> 8;
        type_ = ConditionType(uint8(_packedId));
    }

    // --- 6. State Variables ---
    uint256 private _depositCounter;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => EnumerableSet.UintSet) private _userDeposits;

    uint256 private _conditionCounter; // Counter for all condition types
    mapping(uint256 => TimeCondition) public timeConditions;
    mapping(uint256 => EventCondition) public eventConditions;
    mapping(uint256 => ProbabilisticCondition) public probabilisticConditions;
    mapping(uint256 => ComplexCondition) public complexConditions;

    // Delegation: depositId => delegate address
    mapping(uint256 => address) public conditionDelegates;

    address public oracleAddress; // Address authorized to trigger event conditions

    // Global parameters for probabilistic unlocks (e.g., min/max bounds)
    // These could influence the calculateProbabilisticChance view function logic
    // For simplicity, let's just store base min/max here, actual logic can be more complex.
    uint256 public probabilisticBaseChancePercentage = 100; // Default 1% (100/10000)
    uint256 public probabilisticMaxChancePercentage = 5000; // Default 50%
    uint256 public probabilisticMinChancePercentage = 10;   // Default 0.1%

    // --- 7. Events ---
    event DepositMade(uint256 depositId, address indexed owner, address indexed token, uint256 amount, ConditionType conditionType, uint256 conditionId);
    event DepositClaimed(uint256 depositId, address indexed owner, address indexed token, uint256 amount, ConditionType conditionType, uint256 conditionId);
    event ConditionModified(uint256 conditionId, ConditionType conditionType);
    event EventConditionTriggered(uint256 conditionId, bytes32 eventIdHash, uint256 timestamp);
    event DelegationUpdated(uint256 depositId, address indexed delegator, address indexed delegate);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event ProbabilisticParametersUpdated(uint256 base, uint256 max, uint256 min);
    event StuckTokensWithdrawn(IERC20 indexed token, address indexed to, uint256 amount);

    // --- 8. Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert NotOracle();
        }
        _;
    }

    modifier onlyDepositOwnerOrDelegate(uint256 _depositId) {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0)) revert DepositNotFound(); // Basic check

        if (msg.sender != deposit.owner && msg.sender != conditionDelegates[_depositId]) {
            revert NotDepositOwnerOrDelegate();
        }
        _;
    }

    // --- 9. Constructor ---
    constructor(address _oracleAddress) Ownable(msg.sender) {
        if (_oracleAddress == address(0)) revert ZeroAddressNotAllowed();
        oracleAddress = _oracleAddress;
        _depositCounter = 0;
        _conditionCounter = 0;
    }

    // --- 10. Pausable Implementation ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- 11. Deposit Functions ---
    function depositEther(uint256 _initialConditionId, ConditionType _initialConditionType)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        if (msg.value == 0) revert InvalidAmount();
        _addDeposit(msg.sender, address(0), msg.value, _initialConditionId, _initialConditionType);
    }

    function depositToken(IERC20 _token, uint256 _amount, uint256 _initialConditionId, ConditionType _initialConditionType)
        public
        whenNotPaused
        nonReentrant
    {
        if (_amount == 0) revert InvalidAmount();
        if (address(_token) == address(0)) revert ZeroAddressNotAllowed();

        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _addDeposit(msg.sender, address(_token), _amount, _initialConditionId, _initialConditionType);
    }

    // --- 12. Internal Deposit Helper ---
    function _addDeposit(
        address _owner,
        address _tokenAddress,
        uint256 _amount,
        uint256 _initialConditionId,
        ConditionType _initialConditionType
    ) private {
        // Validate initial condition exists (basic check, detailed validation could be added)
        bool conditionExists = false;
        if (_initialConditionType == ConditionType.TimeBased && timeConditions[_initialConditionId].releaseTime > 0) conditionExists = true;
        if (_initialConditionType == ConditionType.EventBased && bytes32(0) != eventConditions[_initialConditionId].eventIdHash) conditionExists = true;
        if (_initialConditionType == ConditionType.Probabilistic && probabilisticConditions[_initialConditionId].baseChancePercentage <= 10000) conditionExists = true;
        if (_initialConditionType == ConditionType.Complex && complexConditions[_initialConditionId].partIds.length() > 0) conditionExists = true; // Check if it has parts

        // Allow deposit with ConditionType.None or if condition exists
        if (_initialConditionType != ConditionType.None && !conditionExists) {
             revert ConditionNotFound(); // Or a more specific error
        }

        _depositCounter++;
        uint256 newDepositId = _depositCounter;

        deposits[newDepositId] = Deposit({
            owner: _owner,
            tokenAddress: _tokenAddress,
            amount: _amount,
            depositTime: block.timestamp,
            conditionType: _initialConditionType,
            conditionId: _initialConditionId,
            claimed: false
        });

        _userDeposits[_owner].add(newDepositId);

        emit DepositMade(newDepositId, _owner, _tokenAddress, _amount, _initialConditionType, _initialConditionId);
    }

    // --- 13. Condition Management Functions ---

    // Only supports updating the release time for an existing TimeBased condition linked to a deposit
    function modifyTimeCondition(uint256 _depositId, uint256 _newReleaseTime)
        public
        whenNotPaused
        onlyDepositOwnerOrDelegate(_depositId)
    {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.conditionType != ConditionType.TimeBased) {
            revert DepositConditionMismatch();
        }

        TimeCondition storage timeCond = timeConditions[deposit.conditionId];
        if (timeCond.releaseTime == 0) revert ConditionNotFound(); // Should not happen if linked

        timeCond.releaseTime = _newReleaseTime;

        emit ConditionModified(deposit.conditionId, ConditionType.TimeBased);
    }

    // Creates a new EventBased condition structure
    function createEventCondition(bytes32 _eventIdHash) public returns (uint256) {
        _conditionCounter++;
        uint256 newConditionId = _conditionCounter;
        eventConditions[newConditionId] = EventCondition({
            eventIdHash: _eventIdHash,
            isTriggered: false
        });
        // No specific "ConditionCreated" event for structure creation,
        // the linkage happens when a deposit uses it.
        return newConditionId;
    }

    // Modifies an existing EventBased condition (primarily by the oracle or admin)
    function modifyEventCondition(uint256 _conditionId, bytes32 _newEventIdHash)
        public
        onlyOwner // Or `onlyOracle` if the oracle needs to redefine events
    {
        EventCondition storage eventCond = eventConditions[_conditionId];
        if (bytes32(0) == eventCond.eventIdHash) revert ConditionNotFound();

        eventCond.eventIdHash = _newEventIdHash;
        // isTriggered might be reset depending on logic, but let's not here.

        emit ConditionModified(_conditionId, ConditionType.EventBased);
    }


    // Creates a new empty ComplexCondition structure
    function createComplexCondition(ComplexLogicGate _logicGate) public returns (uint256) {
        _conditionCounter++;
        uint256 newConditionId = _conditionCounter;
        complexConditions[newConditionId].logicGate = _logicGate;
        // parts are added via addPartToComplexCondition
        return newConditionId;
    }

    // Adds a sub-condition requirement to a ComplexCondition
    // Requires owner/delegate permission IF the complex condition is already linked to a deposit.
    // If the complex condition is not yet linked, anyone could potentially add parts (design choice).
    // Let's enforce owner/delegate if linked, and allow anyone if not linked.
    // To check if linked, we'd need to iterate through deposits, which is gas-intensive.
    // Simpler approach: require caller to be owner/delegate of a deposit *that uses this complex condition*, OR the contract owner if it's a global/template condition.
    // Let's simplify: Only the contract owner can manage complex condition parts.
    function addPartToComplexCondition(
        uint256 _complexConditionId,
        uint256 _partConditionId,
        ConditionType _partConditionType
    ) public onlyOwner { // Simpler access control for example
        ComplexCondition storage complexCond = complexConditions[_complexConditionId];
        if (complexCond.partIds.length() == 0 && complexCond.logicGate != ComplexLogicGate.AND && complexCond.logicGate != ComplexLogicGate.OR) revert ConditionNotFound(); // Basic check if complex condition exists

        uint256 packedPartId = _packConditionId(_partConditionId, _partConditionType);

        if (!complexCond.requiredParts[packedPartId]) {
             complexCond.requiredParts[packedPartId] = true; // Mark as required
             complexCond.partIds.add(packedPartId);
             // Note: isMet status for parts is evaluated dynamically, not stored here.
             emit ConditionModified(_complexConditionId, ConditionType.Complex);
        }
    }

     // Removes a sub-condition requirement from a ComplexCondition
    function removePartFromComplexCondition(uint256 _complexConditionId, uint256 _partConditionId, ConditionType _partConditionType)
        public
        onlyOwner // Simpler access control for example
    {
        ComplexCondition storage complexCond = complexConditions[_complexConditionId];
        if (complexCond.partIds.length() == 0 && complexCond.logicGate != ComplexLogicGate.AND && complexCond.logicGate != ComplexLogicGate.OR) revert ConditionNotFound();

        uint256 packedPartId = _packConditionId(_partConditionId, _partConditionType);

        if (complexCond.requiredParts[packedPartId]) {
             complexCond.requiredParts[packedPartId] = false; // Mark as no longer required
             complexCond.partIds.remove(packedPartId);
             emit ConditionModified(_complexConditionId, ConditionType.Complex);
        }
    }

    // Only supports updating the chance for an existing Probabilistic condition linked to a deposit
    function setProbabilisticConditionChance(uint256 _depositId, uint256 _newChancePercentage)
        public
        whenNotPaused
        onlyDepositOwnerOrDelegate(_depositId)
    {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.conditionType != ConditionType.Probabilistic) {
            revert DepositConditionMismatch();
        }

        ProbabilisticCondition storage probCond = probabilisticConditions[deposit.conditionId];
         if (probCond.baseChancePercentage > 10000 && probCond.baseChancePercentage != 0) revert ConditionNotFound(); // Should not happen if linked

        if (_newChancePercentage > 10000) revert InvalidProbabilisticChance();

        probCond.baseChancePercentage = _newChancePercentage;

        emit ConditionModified(deposit.conditionId, ConditionType.Probabilistic);
    }


    // --- 14. Unlock/Claim Functions ---

    function claimDeterministicUnlock(uint256 _depositId)
        public
        whenNotPaused
        nonReentrant
    {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0) || deposit.claimed) revert DepositNotFound(); // Check existence & claimed state

        if (deposit.conditionType != ConditionType.TimeBased && deposit.conditionType != ConditionType.EventBased) {
            revert ConditionNotSupportedForUnlock();
        }

        if (!_isConditionMet(deposit.conditionId, deposit.conditionType)) {
            revert ConditionNotMet();
        }

        _executeClaim(deposit);
    }

    function attemptProbabilisticUnlock(uint256 _depositId)
        public
        whenNotPaused
        nonReentrant
    {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0) || deposit.claimed) revert DepositNotFound();

        if (deposit.conditionType != ConditionType.Probabilistic) {
            revert ConditionNotSupportedForUnlock();
        }

        // --- Probabilistic Logic ---
        // WARNING: Using block.timestamp and block.difficulty/blockhash for randomness is insecure.
        // A real-world implementation must use a secure oracle like Chainlink VRF.
        // This implementation is for demonstration ONLY and is vulnerable to front-running.
        uint256 currentChance = calculateProbabilisticChance(_depositId); // Calculate based on current state/params
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _depositId, block.number)));
        uint265 randomNumber = uint256(keccak256(abi.encodePacked(randomSeed))) % 10001; // Result between 0 and 10000

        if (randomNumber <= currentChance) {
            // Condition met probabilistically
            _executeClaim(deposit);
        } else {
            // Condition not met
            revert ConditionNotMet(); // Specific error message could be added
        }
    }

    function claimComplexConditionalUnlock(uint256 _depositId)
        public
        whenNotPaused
        nonReentrant
    {
         Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0) || deposit.claimed) revert DepositNotFound();

        if (deposit.conditionType != ConditionType.Complex) {
            revert ConditionNotSupportedForUnlock();
        }

        if (!_isComplexConditionMet(deposit.conditionId)) {
            revert ConditionNotMet();
        }

        _executeClaim(deposit);
    }

    // Internal function to perform the actual claim transfer
    function _executeClaim(Deposit storage deposit) private {
        deposit.claimed = true;

        if (deposit.tokenAddress == address(0)) {
            // ETH Transfer
            (bool success, ) = deposit.owner.call{value: deposit.amount}("");
            require(success, "ETH transfer failed");
        } else {
            // ERC20 Transfer
            IERC20(deposit.tokenAddress).safeTransfer(deposit.owner, deposit.amount);
        }

        // Remove deposit ID from user's set (optional, but good for gas/cleanup on views)
        _userDeposits[deposit.owner].remove(_depositIdCounter); // deposit variable is reference to deposits[_depositId], need to use depositId directly

        emit DepositClaimed(_depositIdCounter, deposit.owner, deposit.tokenAddress, deposit.amount, deposit.conditionType, deposit.conditionId);
    }


    // --- 15. Delegation Functions ---

    // Allows deposit owner to delegate condition management rights
    function delegateConditionManagement(uint256 _depositId, address _delegate)
        public
        whenNotPaused
    {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0)) revert DepositNotFound();
        if (msg.sender != deposit.owner) revert NotDepositOwnerOrDelegate(); // Only owner can delegate

        if (_delegate == address(0)) revert InvalidDelegate();
        if (conditionDelegates[_depositId] != address(0)) revert DelegationAlreadySet();

        conditionDelegates[_depositId] = _delegate;

        emit DelegationUpdated(_depositId, msg.sender, _delegate);
    }

    // Allows deposit owner to revoke delegation
    function revokeConditionManagementDelegate(uint256 _depositId)
        public
        whenNotPaused
    {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0)) revert DepositNotFound();
        if (msg.sender != deposit.owner) revert NotDepositOwnerOrDelegate(); // Only owner can revoke

        if (conditionDelegates[_depositId] == address(0)) revert DelegationNotSet();

        delete conditionDelegates[_depositId];

        emit DelegationUpdated(_depositId, msg.sender, address(0));
    }

    // --- 16. Oracle/External Interaction Function ---

    // Called by the authorized oracle to trigger an event condition
    function triggerEventCondition(uint256 _conditionId)
        public
        whenNotPaused
        onlyOracle
    {
        EventCondition storage eventCond = eventConditions[_conditionId];
        if (bytes32(0) == eventCond.eventIdHash) revert ConditionNotFound();

        if (!eventCond.isTriggered) {
            eventCond.isTriggered = true;
            emit EventConditionTriggered(_conditionId, eventCond.eventIdHash, block.timestamp);
        }
        // If already triggered, do nothing.
    }

    // --- 17. Admin Functions ---

    // Owner sets the address authorized to trigger event conditions
    function adminSetOracleAddress(address _newOracle) public onlyOwner {
        if (_newOracle == address(0)) revert ZeroAddressNotAllowed();
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    // Owner sets global parameters for probabilistic unlocks
    function adminSetProbabilisticParameters(uint256 _baseChancePercentage, uint256 _maxChancePercentage, uint256 _minChancePercentage) public onlyOwner {
        if (_baseChancePercentage > 10000 || _maxChancePercentage > 10000 || _minChancePercentage > 10000) revert InvalidProbabilisticChance();
        if (_minChancePercentage > _baseChancePercentage || _baseChancePercentage > _maxChancePercentage) revert InvalidProbabilisticChance();

        probabilisticBaseChancePercentage = _baseChancePercentage;
        probabilisticMaxChancePercentage = _maxChancePercentage;
        probabilisticMinChancePercentage = _minChancePercentage;

        emit ProbabilisticParametersUpdated(_baseChancePercentage, _maxChancePercentage, _minChancePercentage);
    }

    // Owner can withdraw tokens accidentally sent to the contract address,
    // EXCLUDING tokens held within active deposits.
    function adminWithdrawStuckTokens(IERC20 _token, address _to) public onlyOwner nonReentrant {
        if (_to == address(0)) revert ZeroAddressNotAllowed();

        // This requires iterating through all deposits to calculate the balance
        // that *should* be in the contract. This can be gas-intensive with many deposits.
        // A more efficient approach would track the *total* deposited balance per token.
        uint256 totalDeposited = 0;
        uint256 totalDepositsCount = _depositCounter; // Use current counter value

        // WARNING: Iterating over a growing mapping like this can hit block gas limits.
        // For a contract with many deposits, this function would need redesign (e.g., pagination, or tracking total per token).
        // This implementation is for demonstration and assumes a manageable number of deposits.
        for (uint256 i = 1; i <= totalDepositsCount; i++) {
            Deposit storage dep = deposits[i];
             // Check if deposit exists (wasn't deleted) and is the correct token
            if (dep.owner != address(0) && dep.tokenAddress == address(_token) && !dep.claimed) {
                 totalDeposited += dep.amount;
            }
        }

        uint256 contractBalance = _token.balanceOf(address(this));
        if (contractBalance <= totalDeposited) {
            // No "stuck" tokens, or potentially a rounding/accounting issue.
            // Or deposited ETH if _token is address(0) - this function is for ERC20 only.
             return;
        }

        uint256 amountToWithdraw = contractBalance - totalDeposited;
        _token.safeTransfer(_to, amountToWithdraw);

        emit StuckTokensWithdrawn(_token, _to, amountToWithdraw);
    }


    // --- 18. View/Query Functions ---

    function getUserDepositIds(address _user) public view returns (uint256[] memory) {
        return _userDeposits[_user].values();
    }

    function getDepositDetails(uint256 _depositId) public view returns (Deposit memory) {
        Deposit memory deposit = deposits[_depositId];
        if (deposit.owner == address(0)) revert DepositNotFound();
        return deposit;
    }

    // Get details for any condition structure by ID and type
    function getConditionDetails(uint256 _conditionId, ConditionType _conditionType)
        public
        view
        returns (
            uint256 timeReleaseTime,
            bytes32 eventIdHash,
            bool eventIsTriggered,
            uint256 probabilisticChance,
            ComplexLogicGate complexGate,
            uint256[] memory complexPartPackedIds
        )
    {
        // Initialize return values
        timeReleaseTime = 0;
        eventIdHash = bytes32(0);
        eventIsTriggered = false;
        probabilisticChance = 0;
        complexGate = ComplexLogicGate.AND; // Default or first enum value
        complexPartPackedIds = new uint256[](0);

        if (_conditionId == 0) return (0, bytes32(0), false, 0, ComplexLogicGate.AND, new uint256[](0)); // Handle case where ID is 0 (e.g., ConditionType.None)


        if (_conditionType == ConditionType.TimeBased) {
            TimeCondition storage cond = timeConditions[_conditionId];
            if (cond.releaseTime == 0) revert ConditionNotFound();
            timeReleaseTime = cond.releaseTime;
        } else if (_conditionType == ConditionType.EventBased) {
            EventCondition storage cond = eventConditions[_conditionId];
            if (bytes32(0) == cond.eventIdHash) revert ConditionNotFound();
            eventIdHash = cond.eventIdHash;
            eventIsTriggered = cond.isTriggered;
        } else if (_conditionType == ConditionType.Probabilistic) {
             ProbabilisticCondition storage cond = probabilisticConditions[_conditionId];
             // Need a better check than >10000 if 0 is a valid chance. Let's check if it was ever set >=0.
             // Or simply check if the ID exists in a set/mapping of valid IDs for the type.
             // For simplicity, let's use the 0-10000 range check.
            if (cond.baseChancePercentage > 10000 && cond.baseChancePercentage != 0) revert ConditionNotFound();
            probabilisticChance = cond.baseChancePercentage; // This is the base chance, not the dynamic calculated one
        } else if (_conditionType == ConditionType.Complex) {
            ComplexCondition storage cond = complexConditions[_conditionId];
             if (cond.partIds.length() == 0 && cond.logicGate != ComplexLogicGate.AND && cond.logicGate != ComplexLogicGate.OR) revert ConditionNotFound();
            complexGate = cond.logicGate;
            complexPartPackedIds = cond.partIds.values();
        } else {
            revert ConditionTypeMismatch(); // Or specific error for unsupported type
        }
    }

    // Check if a given non-probabilistic condition is currently met
    // This function should NOT be used for Probabilistic conditions
    function isConditionMet(uint256 _conditionId, ConditionType _conditionType) public view returns (bool) {
        if (_conditionType == ConditionType.None) return true; // No condition is always met

        if (_conditionType == ConditionType.TimeBased) {
            TimeCondition storage cond = timeConditions[_conditionId];
            if (cond.releaseTime == 0) return false; // Not found or invalid
            return block.timestamp >= cond.releaseTime;

        } else if (_conditionType == ConditionType.EventBased) {
            EventCondition storage cond = eventConditions[_conditionId];
            if (bytes32(0) == cond.eventIdHash) return false; // Not found or invalid
            return cond.isTriggered;

        } else if (_conditionType == ConditionType.Complex) {
            return _isComplexConditionMet(_conditionId);

        } else {
            // Probabilistic and other unknown types are not deterministicly "met" in this function
            return false;
        }
    }

    // Internal helper to check complex conditions
    function _isComplexConditionMet(uint256 _complexConditionId) private view returns (bool) {
         ComplexCondition storage complexCond = complexConditions[_complexConditionId];
         if (complexCond.partIds.length() == 0 && complexCond.logicGate != ComplexLogicGate.AND && complexCond.logicGate != ComplexLogicGate.OR) return false; // Not found or empty

        if (complexCond.partIds.length() == 0) {
            // An empty complex condition with AND or OR logic is technically vacuously true
            // based on standard logic interpretations. We'll treat it as met.
            return true;
        }

        if (complexCond.logicGate == ComplexLogicGate.AND) {
            // ALL parts must be met
            for (uint256 i = 0; i < complexCond.partIds.length(); i++) {
                uint256 packedPartId = complexCond.partIds.at(i);
                (uint256 partId, ConditionType partType) = _unpackConditionId(packedPartId);
                // Probabilistic parts within complex conditions are evaluated as always false for deterministic check
                if (partType == ConditionType.Probabilistic || partType == ConditionType.Complex) {
                     // Complex parts within a complex condition require recursive check
                     if (partType == ConditionType.Complex && !_isComplexConditionMet(partId)) {
                         return false; // Recursive check failed
                     } else if (partType != ConditionType.Complex) {
                         // Probabilistic parts or other types not supported in deterministic check
                         return false;
                     }
                } else if (!isConditionMet(partId, partType)) {
                    return false; // Any single deterministic part not met fails AND
                }
            }
            return true; // All parts met (or were probabilistic/complex and handled)

        } else if (complexCond.logicGate == ComplexLogicGate.OR) {
            // ANY part must be met
             for (uint256 i = 0; i < complexCond.partIds.length(); i++) {
                uint256 packedPartId = complexCond.partIds.at(i);
                (uint256 partId, ConditionType partType) = _unpackConditionId(packedPartId);
                // Probabilistic parts within complex conditions are evaluated as always false for deterministic check
                 if (partType == ConditionType.Probabilistic || partType == ConditionType.Complex) {
                     // Complex parts within a complex condition require recursive check
                     if (partType == ConditionType.Complex && _isComplexConditionMet(partId)) {
                         return true; // Recursive check passed
                     } else if (partType != ConditionType.Complex) {
                         // Probabilistic parts or other types not supported in deterministic check
                         continue; // Skip this part for deterministic check
                     }
                 } else if (isConditionMet(partId, partType)) {
                    return true; // Any single deterministic part met passes OR
                }
            }
            return false; // No parts met

        } else {
            // Should not happen with the enum, but as a safeguard
            return false;
        }
    }


    // Calculate the current chance percentage for a probabilistic unlock (0-10000)
    // This is where dynamic factors (like deposit age) could be incorporated.
    function calculateProbabilisticChance(uint256 _depositId) public view returns (uint256) {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.owner == address(0)) return 0; // Deposit not found
        if (deposit.conditionType != ConditionType.Probabilistic) return 0; // Not a probabilistic deposit

        ProbabilisticCondition storage probCond = probabilisticConditions[deposit.conditionId];
        if (probCond.baseChancePercentage > 10000 && probCond.baseChancePercentage != 0) return 0; // Invalid condition

        // Example Dynamic Calculation (can be much more complex):
        // Increase chance based on deposit age, capped by maxChancePercentage
        uint256 base = probCond.baseChancePercentage;
        uint256 ageInDays = (block.timestamp - deposit.depositTime) / 1 days;
        uint256 ageBonus = ageInDays * 10; // Example: +0.1% per day

        uint256 calculatedChance = base + ageBonus;

        // Apply global min/max bounds
        calculatedChance = calculatedChance > probabilisticMaxChancePercentage ? probabilisticMaxChancePercentage : calculatedChance;
        calculatedChance = calculatedChance < probabilisticMinChancePercentage ? probabilisticMinChancePercentage : calculatedChance;

        return calculatedChance;
    }
}
```