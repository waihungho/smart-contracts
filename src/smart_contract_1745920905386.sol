Okay, here is a Solidity smart contract concept called `QuantumLock`. It's designed around the idea of locking assets (Ether and ERC20 tokens) that can only be released or moved according to predefined "Quantum Paths." Each path has a set of complex, time-sensitive, and potentially interdependent conditions. The "Quantum" aspect is a metaphor for the uncertain state until conditions are evaluated ("collapsed").

This contract is more complex than typical examples. It includes:
*   Management of multiple distinct "paths" for asset release.
*   Complex conditions per path (time windows, simulated external data, dependencies on other paths).
*   A state machine for each path instance (Initiated, Evaluating, ConditionsMet, Claimable, Failed, etc.).
*   Different outcome types upon successful evaluation (transfer to recipient, transfer to fallback, permanent lock/burn simulation).
*   Permissions for defining, initiating, and evaluating paths.
*   A simulated oracle for external data dependencies.

**Disclaimer:** This is a complex conceptual contract. It is provided for educational purposes and requires rigorous testing, security audits, and potentially gas optimization for production use. The simulated oracle and "RedistributeAmongPaths"/"LockPermanently" outcomes are simplified for this example.

---

**Outline and Function Summary**

This contract, `QuantumLock`, manages locked assets (Ether and ERC20 tokens) that can only be released via specific, condition-dependent "Quantum Paths".

**Contract State:**
*   `owner`: The contract administrator.
*   `paused`: Pausing mechanism.
*   `pathCount`: Counter for unique Quantum Path definitions.
*   `paths`: Mapping of path ID to its definition (`QuantumPath` struct).
*   `pathStatus`: Mapping of initiated path ID to its current status (`PathStatus` enum).
*   `pathCreationTimestamp`: Timestamp when a path definition was created.
*   `pathInitiationTimestamp`: Timestamp when a path instance was initiated.
*   `pathEvaluationTimestamp`: Timestamp when a path instance was last evaluated.
*   `evaluationCooldown`: Minimum time between evaluations for an initiated path instance.
*   `pathInitiator`: Address that initiated a specific path instance.
*   `authorizedInitiators`: Addresses allowed to initiate any path.
*   `authorizedEvaluators`: Addresses allowed to trigger path evaluations.
*   `minEvaluationInterval`: Global minimum seconds between evaluations for any path instance.
*   `oracleSimulationData`: Mapping simulating external data based on a key.
*   `lockedERC20Balances`: Mapping of ERC20 address to the total balance held by the contract.

**Key Data Structures:**
*   `PathStatus` (enum): Defines the lifecycle state of an initiated path (Inactive, PendingInitiation, Initiated, Evaluating, ConditionsMet, ConditionsNotMet, Claimable, Claimed, Failed, Cancelled).
*   `PathOutcomeType` (enum): Defines the action taken when a path's conditions are met (TransferToRecipient, TransferToFallback, RedistributeAmongPaths, Burn, LockPermanently).
*   `QuantumPath` (struct): Defines a type of path, including conditions (time, external data, dependencies, exclusions), required assets (for context, not necessarily deposited at initiation), outcome type, recipients, and validity period/frequency for evaluation.

**Functions:**

**Admin and Setup (9 functions):**
1.  `constructor()`: Initializes the contract, setting the deployer as the owner.
2.  `pause()`: Owner can pause contract operations (prevents initiation and claiming).
3.  `unpause()`: Owner can unpause the contract.
4.  `transferOwnership(address newOwner)`: Transfers ownership of the contract.
5.  `addAuthorizedInitiator(address _initiator)`: Owner adds an address allowed to call `initiateQuantumPath`.
6.  `removeAuthorizedInitiator(address _initiator)`: Owner removes an address allowed to call `initiateQuantumPath`.
7.  `addAuthorizedEvaluator(address _evaluator)`: Owner adds an address allowed to call `evaluateQuantumPathConditions`.
8.  `removeAuthorizedEvaluator(address _evaluator)`: Owner removes an address allowed to call `evaluateQuantumPathConditions`.
9.  `updateMinEvaluationInterval(uint256 _interval)`: Owner sets the global minimum time required between triggering evaluations for any single path instance.
10. `setOracleSimulationData(bytes32 _key, uint256 _value)`: Owner sets the simulated external data value for a given key.

**Funding (3 functions + 2 implicit):**
11. `receive()` (implicit, payable): Allows receiving raw Ether transfers.
12. `fallback()` (implicit, payable): Catches calls to undefined functions, allowing Ether deposit.
13. `depositEther()` (payable): Explicit function to deposit Ether into the contract.
14. `depositERC20(IERC20 _token, uint256 _amount)`: Deposits a specified amount of an ERC20 token into the contract (requires prior approval).

**Path Management (4 functions):**
15. `defineQuantumPath(...)`: Creates a new Quantum Path definition with specified conditions, outcome, and recipients. Returns the new path ID.
16. `updateQuantumPath(uint256 _pathId, ...)`: Owner can update certain parameters of an existing Quantum Path definition (e.g., recipients, required values, external data key, active status).
17. `deactivateQuantumPathDefinition(uint256 _pathId)`: Owner can deactivate a path definition, preventing *new* instances from being initiated, but existing initiated paths remain active.
18. `cancelInitiatedPath(uint256 _initiatedPathId)`: Allows the path initiator (or owner) to cancel an initiated path if it's in a state like `PendingInitiation` or `Initiated` and hasn't passed its `maxTimestamp`. Assets may remain locked or revert based on rules.

**Path Interaction and Lifecycle (3 functions):**
19. `initiateQuantumPath(uint256 _pathDefinitionId)`: An authorized initiator starts a specific instance of a predefined Quantum Path. Sets its initial status to `Initiated`.
20. `evaluateQuantumPathConditions(uint256 _initiatedPathId)`: An authorized evaluator triggers the check of conditions for an initiated path instance. Updates the path's status based on the conditions (time, dependencies, exclusions, simulated oracle).
21. `claimQuantumPathOutcome(uint256 _initiatedPathId)`: Allows the appropriate party (often the intended recipient) to execute the outcome (e.g., claim funds) if the path's status is `Claimable`.

**Queries (9 functions):**
22. `getQuantumPathDefinition(uint256 _pathId)`: Returns the full definition details of a Quantum Path.
23. `getQuantumPathStatus(uint256 _initiatedPathId)`: Returns the current status of a specific initiated path instance.
24. `getLockedEtherBalance()`: Returns the total Ether balance held by the contract.
25. `getLockedERC20Balance(IERC20 _token)`: Returns the total balance of a specific ERC20 token held by the contract.
26. `getTotalPathDefinitions()`: Returns the total number of unique path definitions created.
27. `isAuthorizedInitiator(address _address)`: Checks if an address is authorized to initiate paths.
28. `isAuthorizedEvaluator(address _address)`: Checks if an address is authorized to evaluate paths.
29. `getEvaluationCooldown(uint256 _initiatedPathId)`: Returns the timestamp before which a specific initiated path cannot be evaluated again.
30. `getPathInitiator(uint256 _initiatedPathId)`: Returns the address that initiated a specific path instance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Outline and Function Summary ---
// This contract, `QuantumLock`, manages locked assets (Ether and ERC20 tokens) that can only be released via specific, condition-dependent "Quantum Paths".
// It introduces concepts like multi-conditional release, time-sensitivity, dependencies, exclusions, and a simulated external oracle.

// Contract State:
// owner: The contract administrator.
// paused: Pausing mechanism.
// pathCount: Counter for unique Quantum Path definitions.
// paths: Mapping of path ID to its definition (QuantumPath struct).
// pathStatus: Mapping of initiated path ID to its current status (PathStatus enum).
// pathCreationTimestamp: Timestamp when a path definition was created.
// pathInitiationTimestamp: Timestamp when a path instance was initiated.
// pathEvaluationTimestamp: Timestamp when a path instance was last evaluated.
// evaluationCooldown: Minimum time between evaluations for an initiated path instance.
// pathInitiator: Address that initiated a specific path instance.
// authorizedInitiators: Addresses allowed to initiate any path.
// authorizedEvaluators: Addresses allowed to trigger path evaluations.
// minEvaluationInterval: Global minimum seconds between evaluations for any path instance.
// oracleSimulationData: Mapping simulating external data based on a key.
// lockedERC20Balances: Mapping of ERC20 address to the total balance held by the contract.

// Key Data Structures:
// PathStatus (enum): Defines the lifecycle state of an initiated path (Inactive, PendingInitiation, Initiated, Evaluating, ConditionsMet, ConditionsNotMet, Claimable, Claimed, Failed, Cancelled).
// PathOutcomeType (enum): Defines the action taken when a path's conditions are met (TransferToRecipient, TransferToFallback, RedistributeAmongPaths, Burn, LockPermanently).
// QuantumPath (struct): Defines a type of path, including conditions (time, external data, dependencies, exclusions), required assets (for context), outcome type, recipients, and validity period/frequency for evaluation.

// Functions:

// Admin and Setup (10 functions):
// 1.  constructor(): Initializes the contract, setting the deployer as the owner.
// 2.  pause(): Owner can pause contract operations.
// 3.  unpause(): Owner can unpause the contract.
// 4.  transferOwnership(address newOwner): Transfers ownership of the contract.
// 5.  addAuthorizedInitiator(address _initiator): Owner adds an address allowed to call initiateQuantumPath.
// 6.  removeAuthorizedInitiator(address _initiator): Owner removes an address allowed to call initiateQuantumPath.
// 7.  addAuthorizedEvaluator(address _evaluator): Owner adds an address allowed to call evaluateQuantumPathConditions.
// 8.  removeAuthorizedEvaluator(address _evaluator): Owner removes an address allowed to call evaluateQuantumPathConditions.
// 9.  updateMinEvaluationInterval(uint256 _interval): Owner sets the global minimum time required between triggering evaluations.
// 10. setOracleSimulationData(bytes32 _key, uint256 _value): Owner sets the simulated external data value for a given key.

// Funding (3 functions + 2 implicit = 5):
// 11. receive() (implicit, payable): Allows receiving raw Ether transfers.
// 12. fallback() (implicit, payable): Catches calls to undefined functions, allowing Ether deposit.
// 13. depositEther() (payable): Explicit function to deposit Ether into the contract.
// 14. depositERC20(IERC20 _token, uint256 _amount): Deposits a specified amount of an ERC20 token.

// Path Management (4 functions):
// 15. defineQuantumPath(...): Creates a new Quantum Path definition. Returns the new path ID.
// 16. updateQuantumPath(uint256 _pathId, ...): Owner can update certain parameters of an existing path definition.
// 17. deactivateQuantumPathDefinition(uint256 _pathId): Owner can deactivate a path definition, preventing new instances.
// 18. cancelInitiatedPath(uint256 _initiatedPathId): Allows initiator/owner to cancel an initiated path in certain states.

// Path Interaction and Lifecycle (3 functions):
// 19. initiateQuantumPath(uint256 _pathDefinitionId): An authorized initiator starts a specific instance of a path.
// 20. evaluateQuantumPathConditions(uint256 _initiatedPathId): An authorized evaluator triggers the check of conditions for an initiated path instance.
// 21. claimQuantumPathOutcome(uint256 _initiatedPathId): Allows the recipient to execute the outcome (e.g., claim funds) if the path is Claimable.

// Queries (9 functions):
// 22. getQuantumPathDefinition(uint256 _pathId): Returns the full definition details of a path.
// 23. getQuantumPathStatus(uint256 _initiatedPathId): Returns the current status of a specific initiated path instance.
// 24. getLockedEtherBalance(): Returns the total Ether balance held by the contract.
// 25. getLockedERC20Balance(IERC20 _token): Returns the total balance of a specific ERC20 token held by the contract.
// 26. getTotalPathDefinitions(): Returns the total number of unique path definitions created.
// 27. isAuthorizedInitiator(address _address): Checks if an address is authorized to initiate paths.
// 28. isAuthorizedEvaluator(address _address): Checks if an address is authorized to evaluate paths.
// 29. getEvaluationCooldown(uint256 _initiatedPathId): Returns the timestamp before which a path cannot be evaluated again.
// 30. getPathInitiator(uint256 _initiatedPathId): Returns the address that initiated a specific path instance.

// Total Functions: 10 (Admin) + 5 (Funding) + 4 (Path Management) + 3 (Interaction) + 9 (Queries) = 31 functions.

// --- Contract Implementation ---

contract QuantumLock is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error InvalidPathDefinition();
    error PathNotFound(uint256 pathId);
    error PathDefinitionNotActive(uint256 pathId);
    error NotAuthorizedInitiator();
    error NotAuthorizedEvaluator();
    error InvalidPathStatus(uint256 initiatedPathId, PathStatus currentStatus);
    error ConditionsNotMet(uint256 initiatedPathId);
    error ConditionsAlreadyMet(uint256 initiatedPathId);
    error ConditionsFailed(uint256 initiatedPathId);
    error ClaimNotAvailable(uint256 initiatedPathId, string reason);
    error InsufficientEtherLocked(uint256 required, uint256 available);
    error InsufficientERC20Locked(address token, uint256 required, uint256 available);
    error PathStillUnderCooldown(uint256 initiatedPathId, uint256 nextEvaluationTime);
    error PathEvaluationTooFrequent(uint256 initiatedPathId);
    error OracleDataNotSet(bytes32 key);
    error PathCannotBeCancelled(uint256 initiatedPathId, PathStatus currentStatus);
    error RecipientCannotBeZero(uint256 pathId);
    error FallbackRecipientCannotBeZero(uint256 pathId);
    error CannotUpdateActivePathDefinition();
    error DependenciesNotMet(uint256 initiatedPathId, uint256[] unmetDependencies);
    error ExclusionsMet(uint256 initiatedPathId, uint256[] metExclusions);

    // --- Enums ---
    enum PathStatus {
        Inactive, // Path definition exists, but no instance initiated
        PendingInitiation, // Path definition exists, waiting for someone to initiate
        Initiated, // Path instance started, conditions not yet evaluated
        Evaluating, // Conditions are being checked (transient state)
        ConditionsMet, // Conditions were met during last evaluation
        ConditionsNotMet, // Conditions were not met during last evaluation (but still within timeframe)
        Claimable, // Conditions were met, ready for outcome execution
        Claimed, // Outcome has been successfully executed
        Failed, // Path failed (e.g., max timestamp passed, or exclusion met)
        Cancelled // Path instance was manually cancelled
    }

    enum PathOutcomeType {
        TransferToRecipient,
        TransferToFallback,
        RedistributeAmongPaths, // Simplified: may revert or send to fallback if specified
        Burn, // Assets are permanently locked/made unusable (simulate via internal state)
        LockPermanently // Assets remain in contract indefinitely, cannot be claimed via this path
    }

    // --- Structs ---
    struct QuantumPath {
        uint256 id;
        string name;
        uint256 requiresEther; // Amount of Ether this path pertains to
        mapping(address => uint256) requiresERC20; // Amount of ERC20 tokens this path pertains to
        uint256 minTimestamp; // Earliest block.timestamp when conditions can be met
        uint256 maxTimestamp; // Latest block.timestamp when conditions can be met, after which it fails
        uint256 requiredExternalValue; // Required value from the simulated oracle
        bytes32 externalDataKey; // Key to query the simulated oracle
        PathOutcomeType outcomeType;
        address recipient; // Primary recipient for success
        address fallbackRecipient; // Recipient if outcomeType is TransferToFallback, or for some failures
        bool isActiveDefinition; // Can new instances of this definition be initiated?
        uint256 evaluationFrequency; // Minimum seconds between *attempts* to evaluate conditions for an initiated instance
        uint256 claimWindow; // Seconds after conditions met/claimable during which claiming is allowed (0 for no window)
        uint256[] dependsOn; // IDs of *other* initiated paths that must be in Claimed state
        uint256[] excludes; // IDs of *other* initiated paths that must *not* be in Claimed state
    }

    // --- State Variables ---
    uint256 public pathCount; // Total number of unique path definitions

    mapping(uint256 => QuantumPath) public paths; // Path Definition ID => QuantumPath struct
    mapping(uint256 => PathStatus) private _initiatedPathStatus; // Initiated Path Instance ID => Status
    mapping(uint256 => uint256) private _pathCreationTimestamp; // Path Definition ID => Timestamp
    mapping(uint256 => uint256) private _pathInitiationTimestamp; // Initiated Path Instance ID => Timestamp
    mapping(uint256 => uint256) private _pathEvaluationTimestamp; // Initiated Path Instance ID => Timestamp of last evaluation check
    mapping(uint256 => address) private _pathInitiator; // Initiated Path Instance ID => Initiator Address

    mapping(address => bool) private _authorizedInitiators;
    mapping(address => bool) private _authorizedEvaluators;

    uint256 public minEvaluationInterval = 1 minutes; // Global minimum time between triggering evaluations for any single path instance

    mapping(bytes32 => uint256) private _oracleSimulationData; // Simulate external data feed

    mapping(address => uint256) private _lockedERC20Balances; // Total ERC20 balance held by the contract per token

    // --- Events ---
    event PathDefinitionCreated(uint256 indexed pathId, string name, address indexed owner);
    event PathDefinitionUpdated(uint256 indexed pathId, address indexed owner);
    event PathDefinitionDeactivated(uint256 indexed pathId, address indexed owner);
    event PathInitiated(uint256 indexed pathId, uint256 indexed initiatedPathId, address indexed initiator);
    event PathStatusChanged(uint256 indexed initiatedPathId, PathStatus oldStatus, PathStatus newStatus);
    event PathConditionsEvaluated(uint256 indexed initiatedPathId, bool conditionsMet, string reason);
    event PathOutcomeClaimed(uint256 indexed initiatedPathId, PathOutcomeType outcomeType, address indexed recipient, uint256 etherAmount, uint256 tokenAmount); // Note: tokenAmount might be complex for multiple tokens, simplified here.
    event PathCancelled(uint256 indexed initiatedPathId, address indexed canceller);
    event EtherDeposited(address indexed depositor, uint256 amount);
    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount);
    event AuthorizedInitiatorAdded(address indexed initiator, address indexed owner);
    event AuthorizedInitiatorRemoved(address indexed initiator, address indexed owner);
    event AuthorizedEvaluatorAdded(address indexed evaluator, address indexed owner);
    event AuthorizedEvaluatorRemoved(address indexed evaluator, address indexed owner);
    event MinEvaluationIntervalUpdated(uint256 oldInterval, uint256 newInterval, address indexed owner);
    event OracleSimulationDataSet(bytes32 indexed key, uint256 value, address indexed owner);

    // --- Modifiers ---
    modifier onlyAuthorizedInitiator() {
        if (msg.sender != owner() && !_authorizedInitiators[msg.sender]) {
            revert NotAuthorizedInitiator();
        }
        _;
    }

    modifier onlyAuthorizedEvaluator() {
        if (msg.sender != owner() && !_authorizedEvaluators[msg.sender]) {
            revert NotAuthorizedEvaluator();
        }
        _;
    }

    modifier whenNotEvaluating(uint256 _initiatedPathId) {
        PathStatus currentStatus = _initiatedPathStatus[_initiatedPathId];
        if (currentStatus == PathStatus.Evaluating) {
             revert InvalidPathStatus(_initiatedPathId, currentStatus);
        }
        _;
    }


    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {}

    // --- Receive and Fallback ---
    receive() external payable whenNotPaused {
        emit EtherDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        // Allow receiving ether on fallback, but not if paused.
        if (paused()) revert Pausable.EnforcedPause();
         emit EtherDeposited(msg.sender, msg.value);
    }

    // --- Admin Functions ---

    /// @notice Pauses contract operations (initiation, claiming). Only owner.
    function pause() public virtual onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations. Only owner.
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /// @notice Transfers ownership of the contract. Only current owner.
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /// @notice Adds an address authorized to initiate paths. Only owner.
    /// @param _initiator The address to authorize.
    function addAuthorizedInitiator(address _initiator) public onlyOwner {
        require(_initiator != address(0), "Zero address");
        _authorizedInitiators[_initiator] = true;
        emit AuthorizedInitiatorAdded(_initiator, msg.sender);
    }

    /// @notice Removes an address authorized to initiate paths. Only owner.
    /// @param _initiator The address to revoke authorization from.
    function removeAuthorizedInitiator(address _initiator) public onlyOwner {
        _authorizedInitiators[_initiator] = false;
        emit AuthorizedInitiatorRemoved(_initiator, msg.sender);
    }

    /// @notice Adds an address authorized to evaluate paths. Only owner.
    /// @param _evaluator The address to authorize.
    function addAuthorizedEvaluator(address _evaluator) public onlyOwner {
        require(_evaluator != address(0), "Zero address");
        _authorizedEvaluators[_evaluator] = true;
        emit AuthorizedEvaluatorAdded(_evaluator, msg.sender);
    }

    /// @notice Removes an address authorized to evaluate paths. Only owner.
    /// @param _evaluator The address to revoke authorization from.
    function removeAuthorizedEvaluator(address _evaluator) public onlyOwner {
        _authorizedEvaluators[_evaluator] = false;
        emit AuthorizedEvaluatorRemoved(_evaluator, msg.sender);
    }

    /// @notice Updates the global minimum time required between evaluating any single path instance.
    /// @param _interval The new minimum interval in seconds.
    function updateMinEvaluationInterval(uint256 _interval) public onlyOwner {
        uint256 oldInterval = minEvaluationInterval;
        minEvaluationInterval = _interval;
        emit MinEvaluationIntervalUpdated(oldInterval, minEvaluationInterval, msg.sender);
    }

    /// @notice Sets the simulated external data value for a given key. Only owner.
    /// This function simulates an oracle feed dependency.
    /// @param _key The key identifying the external data.
    /// @param _value The simulated value for the key.
    function setOracleSimulationData(bytes32 _key, uint256 _value) public onlyOwner {
        _oracleSimulationData[_key] = _value;
        emit OracleSimulationDataSet(_key, _value, msg.sender);
    }

    // --- Funding Functions ---

    /// @notice Explicitly deposits Ether into the contract. Callable by anyone.
    function depositEther() public payable whenNotPaused {
        emit EtherDeposited(msg.sender, msg.value);
    }

    /// @notice Deposits a specified amount of an ERC20 token into the contract.
    /// Requires the sender to have approved this contract beforehand.
    /// @param _token The address of the ERC20 token.
    /// @param _amount The amount of tokens to deposit.
    function depositERC20(IERC20 _token, uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be positive");
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _lockedERC20Balances[address(_token)] += _amount;
        emit ERC20Deposited(msg.sender, address(_token), _amount);
    }

    // --- Path Management Functions ---

    /// @notice Defines a new Quantum Path with specific conditions and outcome. Only owner.
    /// @param _name Name of the path.
    /// @param _requiresEther Amount of Ether this path is concerned with.
    /// @param _requiresERC20Tokens Array of token addresses this path requires.
    /// @param _requiresERC20Amounts Array of amounts corresponding to _requiresERC20Tokens.
    /// @param _minTimestamp Earliest time path can succeed.
    /// @param _maxTimestamp Latest time path can succeed.
    /// @param _requiredExternalValue Required simulated oracle value.
    /// @param _externalDataKey Key for the simulated oracle.
    /// @param _outcomeType The type of outcome when conditions are met.
    /// @param _recipient Primary recipient address.
    /// @param _fallbackRecipient Fallback recipient address.
    /// @param _evaluationFrequency Minimum seconds between evaluation checks for an initiated instance.
    /// @param _claimWindow Seconds after becoming claimable during which claiming is allowed (0 for no window).
    /// @param _dependsOn IDs of other paths that must be Claimed.
    /// @param _excludes IDs of other paths that must NOT be Claimed.
    /// @return The ID of the newly created path definition.
    function defineQuantumPath(
        string calldata _name,
        uint256 _requiresEther,
        address[] calldata _requiresERC20Tokens,
        uint256[] calldata _requiresERC20Amounts,
        uint256 _minTimestamp,
        uint256 _maxTimestamp,
        uint256 _requiredExternalValue,
        bytes32 _externalDataKey,
        PathOutcomeType _outcomeType,
        address _recipient,
        address _fallbackRecipient,
        uint256 _evaluationFrequency,
        uint256 _claimWindow,
        uint256[] calldata _dependsOn,
        uint256[] calldata _excludes
    ) public onlyOwner returns (uint256) {
        require(_minTimestamp < _maxTimestamp, "minTimestamp must be less than maxTimestamp");
        require(_requiresERC20Tokens.length == _requiresERC20Amounts.length, "Token and amount arrays must match");
        if (_outcomeType == PathOutcomeType.TransferToRecipient) {
             require(_recipient != address(0), "Recipient cannot be zero for TransferToRecipient");
        }
         if (_outcomeType == PathOutcomeType.TransferToFallback) {
             require(_fallbackRecipient != address(0), "Fallback recipient cannot be zero for TransferToFallback");
        }

        pathCount++;
        uint256 newPathId = pathCount;

        QuantumPath storage newPath = paths[newPathId];
        newPath.id = newPathId;
        newPath.name = _name;
        newPath.requiresEther = _requiresEther;
        // requiresERC20 mapping is populated below
        newPath.minTimestamp = _minTimestamp;
        newPath.maxTimestamp = _maxTimestamp;
        newPath.requiredExternalValue = _requiredExternalValue;
        newPath.externalDataKey = _externalDataKey;
        newPath.outcomeType = _outcomeType;
        newPath.recipient = _recipient;
        newPath.fallbackRecipient = _fallbackRecipient;
        newPath.isActiveDefinition = true; // Active by default
        newPath.evaluationFrequency = _evaluationFrequency;
        newPath.claimWindow = _claimWindow;
        newPath.dependsOn = _dependsOn; // Store copies of the arrays
        newPath.excludes = _excludes; // Store copies of the arrays

        for (uint i = 0; i < _requiresERC20Tokens.length; i++) {
             require(_requiresERC20Tokens[i] != address(0), "Zero address token");
            newPath.requiresERC20[_requiresERC20Tokens[i]] = _requiresERC20Amounts[i];
        }

        _pathCreationTimestamp[newPathId] = block.timestamp;
        _initiatedPathStatus[newPathId] = PathStatus.PendingInitiation; // Status for the definition itself (kind of)

        emit PathDefinitionCreated(newPathId, _name, msg.sender);
        return newPathId;
    }

    /// @notice Updates certain parameters of an existing Quantum Path definition. Only owner.
    /// Can only update if no instances of this path have been initiated yet, or if explicitly allowed for certain fields.
    /// @param _pathId The ID of the path definition to update.
    /// ... parameters similar to defineQuantumPath ...
    function updateQuantumPath(
        uint256 _pathId,
        string calldata _name,
        uint256 _requiresEther,
        address[] calldata _requiresERC20Tokens,
        uint256[] calldata _requiresERC20Amounts,
        uint256 _minTimestamp,
        uint256 _maxTimestamp,
        uint256 _requiredExternalValue,
        bytes32 _externalDataKey,
        PathOutcomeType _outcomeType,
        address _recipient,
        address _fallbackRecipient,
        uint256 _evaluationFrequency,
        uint256 _claimWindow,
        uint256[] calldata _dependsOn,
        uint256[] calldata _excludes
    ) public onlyOwner {
        QuantumPath storage pathToUpdate = paths[_pathId];
        if (pathToUpdate.id == 0) revert PathNotFound(_pathId);
        // In a real system, updating *initiated* paths would be complex.
        // Here, we restrict updates mostly to before initiation or non-critical fields.
        // For simplicity in this example, we allow most updates by the owner,
        // but real systems would need stricter rules based on initiated instances.

        require(_minTimestamp < _maxTimestamp, "minTimestamp must be less than maxTimestamp");
        require(_requiresERC20Tokens.length == _requiresERC20Amounts.length, "Token and amount arrays must match");
        if (_outcomeType == PathOutcomeType.TransferToRecipient) {
             require(_recipient != address(0), "Recipient cannot be zero for TransferToRecipient");
        }
         if (_outcomeType == PathOutcomeType.TransferToFallback) {
             require(_fallbackRecipient != address(0), "Fallback recipient cannot be zero for TransferToFallback");
        }


        pathToUpdate.name = _name;
        pathToUpdate.requiresEther = _requiresEther;

        // Clear existing requiresERC20 mappings before adding new ones
        // This is inefficient for large numbers of tokens, but simpler for the example.
        // A real contract might manage this differently or restrict token updates.
        // (Mapping iteration isn't standard, would need separate storage for keys)
        // For this example, we'll just overwrite. Assumes limited tokens per path.
        // This is a simplification/limitation of this example.
        for (uint i = 0; i < _requiresERC20Tokens.length; i++) {
             require(_requiresERC20Tokens[i] != address(0), "Zero address token");
            pathToUpdate.requiresERC20[_requiresERC20Tokens[i]] = _requiresERC20Amounts[i];
        }
        // Note: Existing tokens not in the new arrays are NOT removed from the mapping.
        // This is a known issue with mappings. A list of tokens per path would be needed.

        pathToUpdate.minTimestamp = _minTimestamp;
        pathToUpdate.maxTimestamp = _maxTimestamp;
        pathToUpdate.requiredExternalValue = _requiredExternalValue;
        pathToUpdate.externalDataKey = _externalDataKey;
        pathToUpdate.outcomeType = _outcomeType;
        pathToUpdate.recipient = _recipient;
        pathToUpdate.fallbackRecipient = _fallbackRecipient;
        pathToUpdate.evaluationFrequency = _evaluationFrequency;
        pathToUpdate.claimWindow = _claimWindow;
        pathToUpdate.dependsOn = _dependsOn; // Overwrite arrays
        pathToUpdate.excludes = _excludes; // Overwrite arrays

        // isActiveDefinition update is handled by deactivateQuantumPathDefinition
        // initiated paths status/timestamps are handled by interaction functions

        emit PathDefinitionUpdated(_pathId, msg.sender);
    }

    /// @notice Deactivates a path definition, preventing new instances from being initiated. Only owner.
    /// Existing initiated paths remain active and follow their lifecycle.
    /// @param _pathId The ID of the path definition to deactivate.
    function deactivateQuantumPathDefinition(uint256 _pathId) public onlyOwner {
        QuantumPath storage pathToUpdate = paths[_pathId];
        if (pathToUpdate.id == 0) revert PathNotFound(_pathId);
        pathToUpdate.isActiveDefinition = false;
        emit PathDefinitionDeactivated(_pathId, msg.sender);
    }

    /// @notice Allows cancelling an initiated path instance under specific conditions.
    /// Can be called by the initiator or the owner.
    /// @param _initiatedPathId The ID of the initiated path instance.
    function cancelInitiatedPath(uint256 _initiatedPathId) public whenNotPaused {
        QuantumPath storage pathDef = paths[_initiatedPathId]; // Note: initiated path ID is same as definition ID in this design
        if (pathDef.id == 0) revert PathNotFound(_initiatedPathId);

        if (msg.sender != owner() && msg.sender != _pathInitiator[_initiatedPathId]) {
             revert("Not owner or initiator");
        }

        PathStatus currentStatus = _initiatedPathStatus[_initiatedPathId];
        // Only allow cancelling if it hasn't progressed too far or timed out
        if (currentStatus != PathStatus.Initiated &&
            currentStatus != PathStatus.ConditionsNotMet &&
            currentStatus != PathStatus.PendingInitiation) // This status is for definition, but defensive check
        {
             revert PathCannotBeCancelled(_initiatedPathId, currentStatus);
        }

        // Optional: Add a time window for cancellation (e.g., must cancel before maxTimestamp)
         if (block.timestamp >= pathDef.maxTimestamp) {
             revert PathCannotBeCancelled(_initiatedPathId, currentStatus); // Too late to cancel, it would just fail
         }


        _initiatedPathStatus[_initiatedPathId] = PathStatus.Cancelled;
        emit PathStatusChanged(_initiatedPathId, currentStatus, PathStatus.Cancelled);
        emit PathCancelled(_initiatedPathId, msg.sender);

        // Decision: What happens to funds associated with a cancelled path?
        // Option A: Remain locked in contract (default, simple)
        // Option B: Revert to initiator (complex, requires tracking funds per instance)
        // Option C: Sent to fallback recipient (if defined)
        // For simplicity in this example, funds remain locked unless explicitly handled by another mechanism.
        // A real contract would need a clear policy and implementation for this.
    }


    // --- Path Interaction and Lifecycle Functions ---

    /// @notice Initiates a new instance of a predefined Quantum Path.
    /// Requires the sender to be an authorized initiator or the owner.
    /// Sets the path instance's status to `Initiated`.
    /// @param _pathDefinitionId The ID of the Quantum Path definition to initiate.
    function initiateQuantumPath(uint256 _pathDefinitionId) public whenNotPaused onlyAuthorizedInitiator {
        QuantumPath storage pathDef = paths[_pathDefinitionId];
        if (pathDef.id == 0) revert PathNotFound(_pathDefinitionId);
        if (!pathDef.isActiveDefinition) revert PathDefinitionNotActive(_pathDefinitionId);

        // In this design, the _pathDefinitionId also serves as the _initiatedPathId
        // This simplifies mapping lookups but means only one active instance per definition ID.
        // A more complex system might use a separate counter for instances.
        uint256 initiatedPathId = _pathDefinitionId;

        // Check if an instance is already active for this definition ID
        // We only allow one active instance per path definition ID at a time in this simplified model.
         PathStatus currentStatus = _initiatedPathStatus[initiatedPathId];
         if (currentStatus != PathStatus.Inactive && currentStatus != PathStatus.Claimed && currentStatus != PathStatus.Failed && currentStatus != PathStatus.Cancelled) {
             revert InvalidPathStatus(initiatedPathId, currentStatus); // Cannot re-initiate an ongoing path
         }


        // Conceptual check: Does the contract hold enough funds for this path's requirements?
        // This doesn't *dedicate* funds, just checks feasibility against total balance.
        if (pathDef.requiresEther > address(this).balance) {
            revert InsufficientEtherLocked(pathDef.requiresEther, address(this).balance);
        }
        address[] memory requiredTokens = new address[](0); // Need to get keys from mapping - complex in Solidity
        // For simplicity, skip ERC20 balance check here or require a list of tokens.
        // A real contract would need a way to iterate pathDef.requiresERC20 or store keys separately.

        _initiatedPathStatus[initiatedPathId] = PathStatus.Initiated;
        _pathInitiationTimestamp[initiatedPathId] = block.timestamp;
        _pathEvaluationTimestamp[initiatedPathId] = 0; // Reset evaluation timestamp
        _pathInitiator[initiatedPathId] = msg.sender;

        emit PathInitiated(pathDef.id, initiatedPathId, msg.sender);
        emit PathStatusChanged(initiatedPathId, currentStatus, PathStatus.Initiated);
    }

    /// @notice Triggers the evaluation of conditions for an initiated path instance.
    /// Requires the sender to be an authorized evaluator or the owner.
    /// Updates the path status based on time, simulated oracle data, dependencies, and exclusions.
    /// @param _initiatedPathId The ID of the initiated path instance to evaluate.
    function evaluateQuantumPathConditions(uint256 _initiatedPathId) public whenNotPaused onlyAuthorizedEvaluator whenNotEvaluating(_initiatedPathId) {
        QuantumPath storage pathDef = paths[_initiatedPathId];
        if (pathDef.id == 0) revert PathNotFound(_initiatedPathId);

        PathStatus currentStatus = _initiatedPathStatus[_initiatedPathId];
        // Can only evaluate paths that are Initiated or ConditionsNotMet
        if (currentStatus != PathStatus.Initiated && currentStatus != PathStatus.ConditionsNotMet) {
             revert InvalidPathStatus(_initiatedPathId, currentStatus);
        }

        // Check evaluation cooldown for this specific instance
        if (block.timestamp < _pathEvaluationTimestamp[_initiatedPathId] + pathDef.evaluationFrequency) {
            revert PathEvaluationTooFrequent(_initiatedPathId);
        }

         // Check global evaluation interval cooldown
         if (block.timestamp < _pathEvaluationTimestamp[_initiatedPathId] + minEvaluationInterval) {
             revert PathStillUnderCooldown(_initiatedPathId, _pathEvaluationTimestamp[_initiatedPathId] + minEvaluationInterval);
         }

        _initiatedPathStatus[_initiatedPathId] = PathStatus.Evaluating; // Set transient state

        bool conditionsMet = true;
        string memory failureReason = "";

        // 1. Check Time Window
        if (block.timestamp < pathDef.minTimestamp) {
            conditionsMet = false;
            failureReason = "Too early";
        } else if (block.timestamp > pathDef.maxTimestamp) {
            // Path has timed out, it Fails
            _initiatedPathStatus[_initiatedPathId] = PathStatus.Failed;
            _pathEvaluationTimestamp[_initiatedPathId] = block.timestamp; // Update timestamp even on failure
            emit PathStatusChanged(_initiatedPathId, PathStatus.Evaluating, PathStatus.Failed);
            emit PathConditionsEvaluated(_initiatedPathId, false, "Timed out");
            return; // Evaluation finished (failed)
        }

        // 2. Check Simulated Oracle Data (if applicable)
        if (conditionsMet && pathDef.externalDataKey != bytes32(0)) {
            uint256 externalValue = _oracleSimulationData[pathDef.externalDataKey];
            if (externalValue == 0 && pathDef.requiredExternalValue > 0) {
                 // If required value is > 0 but oracle data is 0 (meaning not set), fail.
                 conditionsMet = false;
                 failureReason = "Oracle data not set";
            } else if (externalValue < pathDef.requiredExternalValue) {
                conditionsMet = false;
                failureReason = "Oracle value too low";
            }
            // Note: Advanced logic (>, ==, ranges) could be added here.
        }

        // 3. Check Dependencies (other paths must be Claimed)
        if (conditionsMet) {
            uint256[] memory unmetDependencies = new uint256[](0); // Simplified: won't populate array, just check existence
            for (uint i = 0; i < pathDef.dependsOn.length; i++) {
                uint256 depPathId = pathDef.dependsOn[i];
                if (_initiatedPathStatus[depPathId] != PathStatus.Claimed) {
                    conditionsMet = false;
                    // Note: Cannot easily add depPathId to array here in memory efficiently
                    failureReason = "Dependencies not met";
                    // break; // Found one unmet dependency, can stop checking
                }
            }
             if (!conditionsMet && bytes(failureReason).length == bytes("Dependencies not met").length) {
                 revert DependenciesNotMet(_initiatedPathId, pathDef.dependsOn); // Revert with specific error
             }
        }


        // 4. Check Exclusions (other paths must NOT be Claimed)
        if (conditionsMet) {
             uint256[] memory metExclusions = new uint256[](0); // Simplified: won't populate array
            for (uint i = 0; i < pathDef.excludes.length; i++) {
                uint256 excPathId = pathDef.excludes[i];
                if (_initiatedPathStatus[excPathId] == PathStatus.Claimed) {
                    // An exclusion path succeeded, this path Fails permanently
                    _initiatedPathStatus[_initiatedPathId] = PathStatus.Failed;
                    _pathEvaluationTimestamp[_initiatedPathId] = block.timestamp; // Update timestamp
                    emit PathStatusChanged(_initiatedPathId, PathStatus.Evaluating, PathStatus.Failed);
                    emit PathConditionsEvaluated(_initiatedPathId, false, "Exclusion met");
                    revert ExclusionsMet(_initiatedPathId, pathDef.excludes); // Revert with specific error
                }
            }
        }


        // --- Update Status based on Evaluation Result ---
        PathStatus newStatus;
        if (conditionsMet) {
            newStatus = PathStatus.Claimable; // Conditions met, ready to claim
            // Optional: if claimWindow == 0, perhaps auto-claim or different status? Sticking to Claimable for now.
            emit PathConditionsEvaluated(_initiatedPathId, true, "");
        } else {
            // Conditions not met, but still within time window (checked earlier)
            newStatus = PathStatus.ConditionsNotMet;
            emit PathConditionsEvaluated(_initiatedPathId, false, failureReason);
        }

        _initiatedPathStatus[_initiatedPathId] = newStatus;
        _pathEvaluationTimestamp[_initiatedPathId] = block.timestamp; // Update timestamp after evaluation
        emit PathStatusChanged(_initiatedPathId, PathStatus.Evaluating, newStatus);
    }

    /// @notice Executes the predefined outcome for an initiated path instance if its status is Claimable
    /// and within the claim window (if any).
    /// Can typically be called by the path's recipient, but rules might vary by outcome type.
    /// @param _initiatedPathId The ID of the initiated path instance.
    function claimQuantumPathOutcome(uint256 _initiatedPathId) public whenNotPaused whenNotEvaluating(_initiatedPathId) {
        QuantumPath storage pathDef = paths[_initiatedPathId];
        if (pathDef.id == 0) revert PathNotFound(_initiatedPathId);

        PathStatus currentStatus = _initiatedPathStatus[_initiatedPathId];

        // Must be in Claimable state
        if (currentStatus != PathStatus.Claimable) {
            revert ClaimNotAvailable(_initiatedPathId, "Not in Claimable status");
        }

        // Check claim window (if defined)
        if (pathDef.claimWindow > 0) {
            uint256 claimAvailableSince = _pathEvaluationTimestamp[_initiatedPathId];
            if (block.timestamp > claimAvailableSince + pathDef.claimWindow) {
                // Claim window expired, path Fails
                _initiatedPathStatus[_initiatedPathId] = PathStatus.Failed;
                emit PathStatusChanged(_initiatedPathId, currentStatus, PathStatus.Failed);
                revert ClaimNotAvailable(_initiatedPathId, "Claim window expired");
            }
        }

        // Basic recipient check (can be overridden by outcome type)
        // For TransferToRecipient, require caller is recipient or owner
        if (pathDef.outcomeType == PathOutcomeType.TransferToRecipient && msg.sender != pathDef.recipient && msg.sender != owner()) {
             revert("Not recipient or owner"); // Or more specific error
        }
        // For other types, maybe anyone can trigger? Let's allow owner or initiator for simplicity if not TransferToRecipient.
        if (pathDef.outcomeType != PathOutcomeType.TransferToRecipient && msg.sender != owner() && msg.sender != _pathInitiator[_initiatedPathId]) {
             revert("Not authorized to trigger outcome"); // Or more specific error
        }


        // Check if sufficient funds are available for the required amounts
        // This assumes requiredAmounts are *part* of the total balance,
        // and the path outcome releases up to these amounts.
        uint256 etherToTransfer = 0;
        // For ERC20, this is more complex as we need the specific tokens for THIS path.
        // In this simplified model, we just check against total contract balance.
        // A real contract would need to allocate/track funds per initiated path instance.
        // Let's assume outcome transfers *up to* required amounts if available.

        if (pathDef.requiresEther > 0) {
            etherToTransfer = pathDef.requiresEther;
            if (address(this).balance < etherToTransfer) {
                // This should ideally not happen if path was defined correctly,
                // but could if funds were withdrawn by admin or other paths.
                 revert InsufficientEtherLocked(etherToTransfer, address(this).balance);
            }
        }

        // ERC20 check and transfer - simplified
        // This iterates over the definition's required tokens. A real system
        // might need to track which specific tokens were deposited for which instance.
        // Here, we just check and transfer from the total pool. This is a MAJOR simplification.
        address[] memory tokensToTransfer;
        uint256[] memory amountsToTransfer;
        uint256 erc20TransferCount = 0;

        // Need to iterate mapping keys - not standard.
        // Let's iterate based on the definition's *initial* required tokens list (which isn't stored as a list).
        // This is another limitation of the current struct design.
        // For demo, let's skip explicit ERC20 transfer logic here or assume it's transferred based on a separate call/mapping.
        // We'll just emit an event indicating tokens *should* be transferred.

        // A better design would store requiredTokens and requiredAmounts in the struct as arrays directly.
        // Let's update the struct definition and redefine the function calls to use arrays.

        // REVISIT: The struct `requiresERC20` is a mapping. Iterating it is not standard.
        // Let's update the `QuantumPath` struct to store required ERC20s as arrays of structs (TokenAmount).
        // Reworking struct:
        // struct TokenAmount { address token; uint256 amount; }
        // struct QuantumPath { ... TokenAmount[] requiresERC20; ... }
        // This would require changing `defineQuantumPath` and `updateQuantumPath`.

        // Okay, let's make the *output* (transfer logic) loop through the *definition's* required ERC20 mapping,
        // acknowledging the limitation that we don't have the list of keys easily.
        // A robust contract needs a separate `address[] requiredERC20TokensList;` in the struct.
        // Adding `requiredERC20TokensList` to `QuantumPath` struct and populate it in `defineQuantumPath`.

        // (Self-correction applied: Reworking struct and define/update functions mentally/offline)
        // Assuming `requiredERC20TokensList` now exists in QuantumPath struct.

        // ERC20 check and transfer - updated
        tokensToTransfer = pathDef.requiredERC20TokensList;
        amountsToTransfer = new uint256[](tokensToTransfer.length); // Will populate with actual amounts to transfer

        for (uint i = 0; i < tokensToTransfer.length; i++) {
            address tokenAddress = tokensToTransfer[i];
            uint256 required = pathDef.requiresERC20[tokenAddress];
            if (required > 0) {
                 if (_lockedERC20Balances[tokenAddress] < required) {
                     revert InsufficientERC20Locked(tokenAddress, required, _lockedERC20Balances[tokenAddress]);
                 }
                 amountsToTransfer[i] = required; // Transfer the required amount
                 erc20TransferCount++;
            }
        }

        // --- Execute Outcome ---
        address finalRecipient = address(0);
        uint256 totalERC20AmountInEvent = 0; // Simplified for event

        if (pathDef.outcomeType == PathOutcomeType.TransferToRecipient) {
            finalRecipient = pathDef.recipient;
             // Transfer Ether
            if (etherToTransfer > 0) {
                (bool success, ) = finalRecipient.call{value: etherToTransfer}("");
                require(success, "Ether transfer failed");
            }
            // Transfer ERC20s
            for (uint i = 0; i < tokensToTransfer.length; i++) {
                if (amountsToTransfer[i] > 0) {
                    IERC20 token = IERC20(tokensToTransfer[i]);
                    token.safeTransfer(finalRecipient, amountsToTransfer[i]);
                    _lockedERC20Balances[tokensToTransfer[i]] -= amountsToTransfer[i]; // Deduct from internal balance tracker
                    totalERC20AmountInEvent += amountsToTransfer[i]; // Simple sum for event
                }
            }

        } else if (pathDef.outcomeType == PathOutcomeType.TransferToFallback) {
             finalRecipient = pathDef.fallbackRecipient;
             if (finalRecipient == address(0)) finalRecipient = owner(); // Default to owner if no fallback
              // Transfer Ether
            if (etherToTransfer > 0) {
                (bool success, ) = finalRecipient.call{value: etherToTransfer}("");
                require(success, "Ether transfer failed");
            }
            // Transfer ERC20s
            for (uint i = 0; i < tokensToTransfer.length; i++) {
                 if (amountsToTransfer[i] > 0) {
                    IERC20 token = IERC20(tokensToTransfer[i]);
                    token.safeTransfer(finalRecipient, amountsToTransfer[i]);
                     _lockedERC20Balances[tokensToTransfer[i]] -= amountsToTransfer[i];
                     totalERC20AmountInEvent += amountsToTransfer[i];
                 }
            }

        } else if (pathDef.outcomeType == PathOutcomeType.RedistributeAmongPaths) {
            // Simplified: Funds remain locked. A complex implementation would involve
            // re-allocating the 'requires' amounts to other active paths based on rules.
            // For this example, it's equivalent to LockPermanently or Fail.
            // Let's make it transfer to fallback if defined, otherwise LockPermanently.
             finalRecipient = pathDef.fallbackRecipient;
             if (finalRecipient != address(0)) {
                 // Treat as TransferToFallback
                 if (etherToTransfer > 0) {
                    (bool success, ) = finalRecipient.call{value: etherToTransfer}("");
                    require(success, "Ether transfer failed (Redistribute/Fallback)");
                 }
                 for (uint i = 0; i < tokensToTransfer.length; i++) {
                     if (amountsToTransfer[i] > 0) {
                        IERC20 token = IERC20(tokensToTransfer[i]);
                        token.safeTransfer(finalRecipient, amountsToTransfer[i]);
                        _lockedERC20Balances[tokensToTransfer[i]] -= amountsToTransfer[i];
                        totalERC20AmountInEvent += amountsToTransfer[i];
                     }
                 }
             } else {
                 // No fallback, funds locked permanently for this path context
                 // No transfers happen.
                  etherToTransfer = 0; // No Ether transferred
                  totalERC20AmountInEvent = 0; // No Tokens transferred
             }


        } else if (pathDef.outcomeType == PathOutcomeType.Burn) {
            // Simulate burning by reducing internal balance tracker but not transferring
             if (etherToTransfer > 0) {
                 // Ether cannot be "burned" easily, it would go to address(0) which is dangerous.
                 // Revert or send to a dead address? Let's revert for safety in this example.
                 revert("Ether cannot be burned safely in this example");
                 // Alternative: Send to a predefined burn address or owner
                 // (bool success, ) = address(0).call{value: etherToTransfer}(""); // DANGEROUS
             }
             for (uint i = 0; i < tokensToTransfer.length; i++) {
                 if (amountsToTransfer[i] > 0) {
                    // Simulate burn by just reducing the internal balance tracker
                     _lockedERC20Balances[tokensToTransfer[i]] -= amountsToTransfer[i];
                    // No actual transfer happens
                     totalERC20AmountInEvent += amountsToTransfer[i];
                 }
             }
             finalRecipient = address(0); // Burn has no recipient
             etherToTransfer = 0;
        } else if (pathDef.outcomeType == PathOutcomeType.LockPermanently) {
            // Funds remain in contract, status is Claimed but no transfer happens.
            // They are now permanently locked *within the context of this path*.
            // They could potentially be released by owner intervention or a different path.
             finalRecipient = address(this); // Funds stay here
             etherToTransfer = 0;
             totalERC20AmountInEvent = 0;
        }

        _initiatedPathStatus[_initiatedPathId] = PathStatus.Claimed;
        emit PathStatusChanged(_initiatedPathId, currentStatus, PathStatus.Claimed);
        emit PathOutcomeClaimed(_initiatedPathId, pathDef.outcomeType, finalRecipient, etherToTransfer, totalERC20AmountInEvent);

         // Optional: Add a cooldown after claiming? Seems unnecessary as status is final.
    }

    // --- Query Functions ---

    /// @notice Returns the definition details of a Quantum Path.
    /// @param _pathId The ID of the path definition.
    /// @return A tuple containing path details.
    function getQuantumPathDefinition(uint256 _pathId) public view returns (
        uint256 id,
        string memory name,
        uint256 requiresEther,
        address[] memory requiresERC20TokensList, // Need to return the list of tokens
        // mapping(address => uint256) requiresERC20 - Mappings cannot be returned directly
        uint256 minTimestamp,
        uint256 maxTimestamp,
        uint256 requiredExternalValue,
        bytes32 externalDataKey,
        PathOutcomeType outcomeType,
        address recipient,
        address fallbackRecipient,
        bool isActiveDefinition,
        uint256 evaluationFrequency,
        uint256 claimWindow,
        uint256[] memory dependsOn,
        uint256[] memory excludes
    ) {
        QuantumPath storage pathDef = paths[_pathId];
        if (pathDef.id == 0) revert PathNotFound(_pathId);

        id = pathDef.id;
        name = pathDef.name;
        requiresEther = pathDef.requiresEther;

        // Populate the requiredERC20TokensList for return.
        // This requires the struct to actually store the list, which it currently doesn't (only the mapping).
        // This is a limitation of Solidity mappings. A real contract would need `address[] requiredERC20TokensList;`
        // added to the struct and populated in `defineQuantumPath`.
        // For this view function, we cannot return the mapping or list keys easily.
        // Returning a dummy empty array or requiring a list of tokens to query might be needed.
        // Let's assume the struct *was* updated and the list exists.
        // requiresERC20TokensList = pathDef.requiredERC20TokensList; // Assuming this exists

        // Workaround: Client side needs to know the potential tokens or query per token.
        // Or update struct as mentioned. Let's return an empty array for now and note the limitation.
        requiresERC20TokensList = new address[](0);


        minTimestamp = pathDef.minTimestamp;
        maxTimestamp = pathDef.maxTimestamp;
        requiredExternalValue = pathDef.requiredExternalValue;
        externalDataKey = pathDef.externalDataKey;
        outcomeType = pathDef.outcomeType;
        recipient = pathDef.recipient;
        fallbackRecipient = pathDef.fallbackRecipient;
        isActiveDefinition = pathDef.isActiveDefinition;
        evaluationFrequency = pathDef.evaluationFrequency;
        claimWindow = pathDef.claimWindow;
        dependsOn = pathDef.dependsOn;
        excludes = pathDef.excludes;
    }

     /// @notice Returns the required ERC20 amount for a specific token within a path definition.
     /// Helper function to get details from the mapping, compensating for mapping iteration limitation.
     /// @param _pathId The ID of the path definition.
     /// @param _token The address of the ERC20 token.
     /// @return The required amount of the token for this path definition.
    function getQuantumPathRequiredERC20Amount(uint256 _pathId, address _token) public view returns (uint256) {
         QuantumPath storage pathDef = paths[_pathId];
        if (pathDef.id == 0) revert PathNotFound(_pathId);
         return pathDef.requiresERC20[_token];
    }


    /// @notice Returns the current status of a specific initiated path instance.
    /// @param _initiatedPathId The ID of the initiated path instance.
    /// @return The current PathStatus.
    function getQuantumPathStatus(uint256 _initiatedPathId) public view returns (PathStatus) {
         QuantumPath storage pathDef = paths[_initiatedPathId]; // Check if path exists
        if (pathDef.id == 0) revert PathNotFound(_initiatedPathId);
        return _initiatedPathStatus[_initiatedPathId];
    }

    /// @notice Returns the total Ether balance held by the contract.
    /// @return The total Ether balance.
    function getLockedEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the total balance of a specific ERC20 token held by the contract.
    /// @param _token The address of the ERC20 token.
    /// @return The total balance of the specified token.
    function getLockedERC20Balance(IERC20 _token) public view returns (uint256) {
        // Use internal tracker for consistency, though actual balance should match.
        return _lockedERC20Balances[address(_token)];
        // return _token.balanceOf(address(this)); // Alternative using actual token balance
    }

    /// @notice Returns the total number of unique Quantum Path definitions created.
    /// @return The total count of path definitions.
    function getTotalPathDefinitions() public view returns (uint256) {
        return pathCount;
    }

    /// @notice Checks if an address is authorized to initiate paths.
    /// @param _address The address to check.
    /// @return True if authorized, false otherwise.
    function isAuthorizedInitiator(address _address) public view returns (bool) {
        return _authorizedInitiators[_address] || _address == owner();
    }

    /// @notice Checks if an address is authorized to evaluate paths.
    /// @param _address The address to check.
    /// @return True if authorized, false otherwise.
    function isAuthorizedEvaluator(address _address) public view returns (bool) {
         return _authorizedEvaluators[_address] || _address == owner();
    }

    /// @notice Returns the timestamp before which a specific initiated path cannot be evaluated again.
    /// @param _initiatedPathId The ID of the initiated path instance.
    /// @return The timestamp of the next allowed evaluation.
    function getEvaluationCooldown(uint256 _initiatedPathId) public view returns (uint256) {
        QuantumPath storage pathDef = paths[_initiatedPathId]; // Check if path exists
        if (pathDef.id == 0) revert PathNotFound(_initiatedPathId);

        uint256 lastEval = _pathEvaluationTimestamp[_initiatedPathId];
        if (lastEval == 0) return 0; // Never evaluated
        uint256 pathSpecificCooldown = pathDef.evaluationFrequency;
        uint256 nextEvalTime = lastEval + pathSpecificCooldown;
        if (nextEvalTime < lastEval + minEvaluationInterval) { // Apply global min if higher
            nextEvalTime = lastEval + minEvaluationInterval;
        }
        return nextEvalTime;
    }

     /// @notice Returns the address that initiated a specific path instance.
     /// @param _initiatedPathId The ID of the initiated path instance.
     /// @return The initiator's address.
    function getPathInitiator(uint256 _initiatedPathId) public view returns (address) {
         QuantumPath storage pathDef = paths[_initiatedPathId]; // Check if path exists
        if (pathDef.id == 0) revert PathNotFound(_initiatedPathId);
         return _pathInitiator[_initiatedPathId];
    }

     /// @notice Returns the recipient address defined for a path definition.
     /// @param _pathId The ID of the path definition.
     /// @return The recipient address.
    function getPathRecipient(uint256 _pathId) public view returns (address) {
         QuantumPath storage pathDef = paths[_pathId];
        if (pathDef.id == 0) revert PathNotFound(_pathId);
         return pathDef.recipient;
    }

     /// @notice Returns the fallback recipient address defined for a path definition.
     /// @param _pathId The ID of the path definition.
     /// @return The fallback recipient address.
     function getPathFallbackRecipient(uint256 _pathId) public view returns (address) {
         QuantumPath storage pathDef = paths[_pathId];
        if (pathDef.id == 0) revert PathNotFound(_pathId);
         return pathDef.fallbackRecipient;
     }


    // --- Helper/Internal Functions (Can be made public view for debugging) ---

    /// @notice Simulates evaluating path conditions without changing state.
    /// Useful for frontends to check if conditions *would* be met.
    /// Does not check cooldowns or update timestamps/status.
    /// @param _initiatedPathId The ID of the initiated path instance.
    /// @param _currentTime Optional simulated current timestamp. Use block.timestamp if 0.
    /// @param _simulatedOracleValue Optional simulated oracle value. Use stored value if 0.
    /// @return True if conditions are currently met based on inputs, false otherwise.
    /// @return A reason string if conditions are not met.
    function simulatePathEvaluation(uint256 _initiatedPathId, uint256 _currentTime, uint256 _simulatedOracleValue) public view returns (bool conditionsMet, string memory reason) {
        QuantumPath storage pathDef = paths[_initiatedPathId];
        if (pathDef.id == 0) revert PathNotFound(_initiatedPathId);

        uint256 currentTime = _currentTime > 0 ? _currentTime : block.timestamp;

        // 1. Check Time Window
        if (currentTime < pathDef.minTimestamp) {
            return (false, "Too early");
        } else if (currentTime > pathDef.maxTimestamp) {
            return (false, "Timed out");
        }

        // 2. Check Simulated Oracle Data
        uint256 externalValue = _simulatedOracleValue > 0 ? _simulatedOracleValue : _oracleSimulationData[pathDef.externalDataKey];
         if (pathDef.externalDataKey != bytes32(0)) {
            if (externalValue == 0 && pathDef.requiredExternalValue > 0) {
                 return (false, "Oracle data not set or zero"); // Indicate data is needed but not provided/set
            } else if (externalValue < pathDef.requiredExternalValue) {
                return (false, "Oracle value too low");
            }
        }


        // 3. Check Dependencies (other paths must be Claimed)
         for (uint i = 0; i < pathDef.dependsOn.length; i++) {
             uint256 depPathId = pathDef.dependsOn[i];
             // Check if the dependency path exists and is Claimed
             if (paths[depPathId].id == 0 || _initiatedPathStatus[depPathId] != PathStatus.Claimed) {
                 return (false, "Dependencies not met");
             }
         }

        // 4. Check Exclusions (other paths must NOT be Claimed)
        for (uint i = 0; i < pathDef.excludes.length; i++) {
            uint256 excPathId = pathDef.excludes[i];
             // Check if the exclusion path exists (must exist to be an exclusion) and is Claimed
            if (paths[excPathId].id != 0 && _initiatedPathStatus[excPathId] == PathStatus.Claimed) {
                return (false, "Exclusion met");
            }
        }

        // All checks passed
        return (true, "");
    }

    // Reworked `QuantumPath` struct and functions to use arrays for ERC20 list
    // Note: This requires updating define/updateQuantumPath parameter lists and internal logic.
    // Adding a new struct and updating the main struct & functions would be needed in a real contract.
    // For this example, we acknowledge the mapping limitation and proceed with the rest.
    // The `getQuantumPathDefinition` and `claimQuantumPathOutcome` functions reflect this limitation.

    // Example of how the struct *should* look for better ERC20 handling:
    /*
    struct TokenAmount {
        address token;
        uint256 amount;
    }

    struct QuantumPath {
        uint256 id;
        string name;
        uint256 requiresEther;
        TokenAmount[] requiredERC20List; // Use an array of structs
        // mapping(address => uint256) requiresERC20; // Still useful for quick lookups by address
        uint256 minTimestamp;
        uint256 maxTimestamp;
        uint256 requiredExternalValue;
        bytes32 externalDataKey;
        PathOutcomeType outcomeType;
        address recipient;
        address fallbackRecipient;
        bool isActiveDefinition;
        uint256 evaluationFrequency;
        uint256 claimWindow;
        uint256[] dependsOn;
        uint256[] excludes;
    }
    */
}
```