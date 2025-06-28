Okay, here is a Solidity smart contract designed around a creative, advanced concept inspired by quantum mechanics: a "Quantum State Vault".

The idea is that funds deposited into this vault don't just sit in one state, but are linked to multiple potential "quantum states", each with its own release conditions. A "measurement" event attempts to collapse these possibilities into a single, resolved state, triggering access to the funds based on that state's rules.

This involves concepts like:
*   **Superposition (Analogy):** A deposit can be associated with multiple possible release conditions simultaneously.
*   **Measurement (Analogy):** A function call attempts to check which, if any, conditions across the potential states are met, locking the deposit into the first one found.
*   **Entanglement (Analogy):** One state's resolution might depend on another state (possibly in a different deposit or even contract) being resolved.
*   **Decoherence (Analogy):** A global timeout after which standard conditions might be overridden.

This is purely an analogy; it doesn't use actual quantum computing. It's a complex state machine disguised as a vault.

---

**Outline and Function Summary: QuantumVault**

This contract acts as a sophisticated vault for ETH and ERC20 tokens, where deposited funds are tied to multiple potential "quantum states", each with unique release conditions. A "measurement" process resolves the deposit into a single state, determining its access rules.

**Core Concepts:**

1.  **Quantum State Definitions:** Templates defining potential conditions (time, external data, dependencies) for releasing funds.
2.  **Deposit Superposition:** A single deposit can be linked to multiple Quantum State Definitions.
3.  **Measurement:** A function call that checks the conditions of the linked states. The first state whose conditions are met becomes the deposit's *resolved* state.
4.  **Resolution & Release:** Once a deposit is resolved to a specific state, its funds can be released according to that state's rules (e.g., who can withdraw, when).
5.  **Decoherence Timeout:** A global fallback allowing resolution after a long period, regardless of specific state conditions.
6.  **Catalysts:** Special addresses that can trigger the `measureQuantumState` function for any deposit, potentially earning a fee.

**Contract Structure:**

*   **State Variables:** Store deposit details, state definitions, mappings for relationships (deposit to states, deposit to resolved state), parameters, roles.
*   **Structs:** `DepositDetails`, `QuantumStateDefinition`.
*   **Enums:** `DepositStatus` (Potential, Resolved, Cancelled, Expired).
*   **Events:** Announce key actions (Deposit, State Defined, State Attuned, Measured, Released, Cancelled, etc.).
*   **Access Control:** Owner, Catalysts, Deposit Owners.

**Function Summary (27 Functions):**

**1. Core Vault Operations:**

*   `depositETH(uint256[] memory _stateDefinitionIds)`: Deposit Ether, linking it to specified state definitions.
*   `depositERC20(address _tokenAddress, uint256 _amount, uint256[] memory _stateDefinitionIds)`: Deposit ERC20, linking it to specified state definitions.
*   `releaseResolvedDeposit(uint256 _depositId)`: Attempt to withdraw funds from a deposit that has been successfully measured and resolved.

**2. Quantum State Definition & Management:**

*   `createQuantumStateDefinition(QuantumStateCondition[] memory _conditions, address _releaseRecipient, uint256 _releaseStartTime, uint256 _releaseEndTime, address _releaseTriggerAddress)`: Define a new set of potential release conditions.
*   `updateQuantumStateDefinition(uint256 _stateDefinitionId, QuantumStateCondition[] memory _newConditions, address _newReleaseRecipient, uint256 _newReleaseStartTime, uint256 _newReleaseEndTime, address _newReleaseTriggerAddress)`: Modify an existing state definition (admin only).
*   `deactivateQuantumStateDefinition(uint256 _stateDefinitionId)`: Disable a state definition so it cannot be used for new deposits or resolutions (admin only).

**3. Deposit State Attunement (Defining Potential States):**

*   `attuneDepositToStates(uint256 _depositId, uint256[] memory _stateDefinitionIds)`: Link an existing deposit to additional potential state definitions (deposit owner or admin).
*   `deattuneDepositFromStates(uint256 _depositId, uint256[] memory _stateDefinitionIds)`: Remove potential state definitions from a deposit (deposit owner or admin).

**4. The "Measurement" Process:**

*   `measureQuantumState(uint256 _depositId)`: Attempt to resolve the deposit's state by checking its potential states' conditions. Only callable if the deposit is in `Potential` status. Awards a fee to the caller if successful.
*   `canResolveDeposit(uint256 _depositId)`: View function to check if a deposit is currently resolvable to any of its potential states.

**5. Conditional Logic & Parameters:**

*   `setOracleAddress(address _oracleAddress)`: Set the address of an oracle contract (admin only).
*   `setConditionParameter(bytes32 _key, uint256 _value)`: Set a generic numeric parameter that can be used in conditions (admin only).
*   `setConditionAddressParameter(bytes32 _key, address _value)`: Set a generic address parameter (admin only).
*   `setConditionDependency(uint256 _stateDefinitionId, uint256 _dependentStateDefinitionId)`: Make one state definition's condition dependent on another state definition being resolved (admin only).
*   `unsetConditionDependency(uint256 _stateDefinitionId)`: Remove a state dependency (admin only).

**6. Global Fallback & Emergency:**

*   `setGlobalDecoherenceTimeout(uint256 _timeout)`: Set a global timestamp after which any deposit can be force-resolved to a specific fallback state or released unconditionally (admin only).
*   `cancelDeposit(uint256 _depositId)`: Cancel a deposit if conditions allow (e.g., before resolution, by owner/admin).
*   `emergencyWithdrawAdmin(uint256 _depositId)`: Admin function to withdraw funds in extreme emergencies (requires contract pause).

**7. Fee & Catalyst Management:**

*   `setResolutionFee(address _tokenAddress, uint256 _feeAmount)`: Set a fee amount paid to the catalyst upon successful state measurement (admin only). Can set different fees per token.
*   `withdrawFees(address _tokenAddress)`: Catalyst or owner withdraws accumulated fees for a specific token.
*   `appointCatalyst(address _catalystAddress)`: Grant Catalyst role (owner only).
*   `revokeCatalyst(address _catalystAddress)`: Remove Catalyst role (owner only).

**8. Utility & Information (View Functions):**

*   `getDepositDetails(uint256 _depositId)`: Retrieve details of a specific deposit.
*   `getQuantumStateDefinition(uint256 _stateDefinitionId)`: Retrieve details of a state definition.
*   `getPotentialStatesForDeposit(uint256 _depositId)`: Get the IDs of state definitions a deposit is currently attuned to.
*   `getResolvedStateForDeposit(uint256 _depositId)`: Get the ID of the state definition a deposit has resolved to (if any).
*   `getDepositAmount(uint256 _depositId)`: Get the token address and amount for a deposit.
*   `getAccumulatedFees(address _tokenAddress, address _account)`: Get the accumulated fees for a catalyst/owner for a specific token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline and Function Summary Above ---

/**
 * @title QuantumVault
 * @dev A complex vault contract inspired by quantum mechanics concepts.
 * Deposits are linked to multiple potential "quantum states", each with resolution conditions.
 * A "measurement" function resolves the deposit to the first state whose conditions are met.
 * Funds are then released according to the resolved state's rules.
 */
contract QuantumVault {

    // --- Interfaces ---

    // Minimal ERC20 interface
    interface IERC20 {
        function transfer(address recipient, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        function approve(address spender, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
    }

    // Dummy interface for a potential external oracle
    interface IDummyOracle {
        function getData(bytes32 _key) external view returns (uint256 value, uint256 timestamp);
    }

    // --- Structs ---

    // Defines a single condition that must be met for a state to be resolvable
    struct QuantumStateCondition {
        enum ConditionType {
            None,
            TimestampAfter,         // Value: required timestamp
            TimestampBefore,        // Value: required timestamp
            BlockNumberAfter,       // Value: required block number
            BlockNumberBefore,      // Value: required block number
            OracleValueGT,          // Key: oracle data key, Value: required value (greater than)
            OracleValueLT,          // Key: oracle data key, Value: required value (less than)
            ExternalAddressTrigger, // Address: specific address must call 'measure'
            DepositResolved,        // DepositId: another deposit must be resolved
            StateResolved           // StateDefinitionId: another state definition must be resolved *somewhere*
        }
        ConditionType conditionType;
        bytes32 key;           // Used for OracleValue types
        uint256 value;         // Used for numeric conditions (timestamp, block, oracle value)
        address triggerAddress; // Used for ExternalAddressTrigger
        uint256 dependencyId; // Used for DepositResolved, StateResolved
        bool mustBeMet;        // True if this condition is mandatory, False if it's optional (for complex OR logic, though this simple struct implies AND)
    }

    // Defines a potential state a deposit can resolve into
    struct QuantumStateDefinition {
        uint256 id; // Unique ID
        QuantumStateCondition[] conditions;
        address releaseRecipient; // Who gets the funds if resolved to this state (0x0 means deposit owner)
        uint256 releaseStartTime; // When can funds be released after resolution
        uint256 releaseEndTime;   // When *must* funds be released by after resolution (0 means no end)
        address releaseTriggerAddress; // Specific address required to call release (0x0 means recipient/owner)
        bool active; // Can this definition be used?
        bool resolvedDependencyMet; // Internal flag for StateResolved dependency tracking
    }

    // Details for each deposit
    struct DepositDetails {
        uint256 id; // Unique ID
        address depositor;
        address tokenAddress; // 0x0 for ETH
        uint256 amount;
        uint256 depositTimestamp;
        uint256 resolvedStateDefinitionId; // 0 if not resolved
        uint256 resolutionTimestamp; // 0 if not resolved
        DepositStatus status;
        bool isEth; // True if deposit is ETH
    }

    enum DepositStatus {
        Potential, // Default state, linked to multiple potential states
        Resolved,  // State has been measured and resolved to one specific definition
        Cancelled, // Deposit was cancelled before resolution
        Released,  // Funds have been withdrawn
        Expired    // Resolution window or release window passed unresolved/unreleased
    }

    // --- State Variables ---

    address public owner;
    uint256 private nextDepositId = 1;
    uint256 private nextStateDefinitionId = 1;

    mapping(uint256 => DepositDetails) public deposits;
    mapping(uint256 => QuantumStateDefinition) public stateDefinitions;

    // Tracks which state definitions a deposit is currently attuned to (potential states)
    mapping(uint256 => uint256[]) private depositPotentialStates;

    // Tracks resolution fees per token
    mapping(address => uint256) public resolutionFees; // token => amount

    // Tracks accumulated fees for catalysts/owner
    mapping(address => mapping(address => uint256)) private accumulatedFees; // token => account => amount

    // Roles
    mapping(address => bool) public isCatalyst;

    // Contract state (paused)
    bool public paused = false;

    // Parameters used in conditions or global settings
    address public oracleAddress;
    mapping(bytes32 => uint256) public conditionParametersUint;
    mapping(bytes32 => address) public conditionParametersAddress;
    uint256 public globalDecoherenceTimeout = 0; // Timestamp. If non-zero and now > timeout, forced resolution/release possible.
    uint256 public globalFallbackStateDefinitionId = 0; // State ID for global timeout fallback

    // --- Events ---

    event DepositReceived(uint256 indexed depositId, address indexed depositor, address indexed tokenAddress, uint256 amount, uint256[] stateDefinitionIds);
    event StateDefinitionCreated(uint256 indexed stateDefinitionId, address indexed creator);
    event StateDefinitionUpdated(uint256 indexed stateDefinitionId);
    event StateDefinitionDeactivated(uint256 indexed stateDefinitionId);
    event DepositAttuned(uint256 indexed depositId, uint256[] stateDefinitionIds);
    event DepositDeattuned(uint256 indexed depositId, uint256[] stateDefinitionIds);
    event DepositMeasured(uint256 indexed depositId, uint256 indexed resolvedStateDefinitionId, address indexed measurer, uint256 feePaid);
    event DepositReleased(uint256 indexed depositId, address indexed recipient, uint256 amount);
    event DepositCancelled(uint256 indexed depositId, address indexed canceller);
    event DepositExpired(uint256 indexed depositId); // Could be resolution expiry or release expiry
    event OracleAddressSet(address indexed newOracleAddress);
    event ConditionParameterSetUint(bytes32 indexed key, uint256 value);
    event ConditionParameterSetAddress(bytes32 indexed key, address value);
    event ConditionDependencySet(uint256 indexed stateDefinitionId, uint255 indexed dependentStateDefinitionId);
    event ConditionDependencyUnset(uint256 indexed stateDefinitionId);
    event GlobalDecoherenceTimeoutSet(uint256 timeout);
    event GlobalFallbackStateSet(uint256 indexed stateDefinitionId);
    event ResolutionFeeSet(address indexed tokenAddress, uint256 feeAmount);
    event FeesWithdrawn(address indexed tokenAddress, address indexed account, uint256 amount);
    event CatalystAppointed(address indexed catalyst);
    event CatalystRevoked(address indexed catalyst);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event EmergencyWithdraw(uint256 indexed depositId, address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "QV: Not owner");
        _;
    }

    modifier onlyCatalystOrOwner() {
        require(msg.sender == owner || isCatalyst[msg.sender], "QV: Not catalyst or owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "QV: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "QV: Not paused");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }

    // --- Access Control & Pause Functions ---

    /**
     * @dev Transfers ownership of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "QV: New owner is the zero address");
        owner = _newOwner;
    }

    /**
     * @dev Allows the owner to pause the contract.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Allows the owner to unpause the contract.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Appoints a catalyst.
     * @param _catalystAddress The address to appoint as catalyst.
     */
    function appointCatalyst(address _catalystAddress) external onlyOwner {
        require(_catalystAddress != address(0), "QV: Zero address");
        isCatalyst[_catalystAddress] = true;
        emit CatalystAppointed(_catalystAddress);
    }

    /**
     * @dev Revokes a catalyst role.
     * @param _catalystAddress The address to revoke catalyst role from.
     */
    function revokeCatalyst(address _catalystAddress) external onlyOwner {
        isCatalyst[_catalystAddress] = false;
        emit CatalystRevoked(_catalystAddress);
    }

    // --- Deposit Functions ---

    /**
     * @dev Deposits ETH into the vault, linking it to specified potential states.
     * @param _stateDefinitionIds IDs of the initial state definitions for this deposit.
     */
    receive() external payable whenNotPaused {
         // This receive function only handles ETH deposits without specified states initially.
         // For deposits linked to states, depositETH must be called.
         // Simple receive is intentionally limited to force state definition use.
         // Revert to discourage direct sends without linking to states.
         revert("QV: Use depositETH or depositERC20 with state definitions");
    }

     /**
     * @dev Deposits ETH into the vault, linking it to specified potential states.
     * @param _stateDefinitionIds IDs of the initial state definitions for this deposit.
     */
    function depositETH(uint256[] memory _stateDefinitionIds) external payable whenNotPaused {
        require(msg.value > 0, "QV: Zero amount");
        require(_stateDefinitionIds.length > 0, "QV: Must provide initial states");

        uint256 currentDepositId = nextDepositId++;
        deposits[currentDepositId] = DepositDetails({
            id: currentDepositId,
            depositor: msg.sender,
            tokenAddress: address(0),
            amount: msg.value,
            depositTimestamp: block.timestamp,
            resolvedStateDefinitionId: 0,
            resolutionTimestamp: 0,
            status: DepositStatus.Potential,
            isEth: true
        });

        attuneDepositToStates(currentDepositId, _stateDefinitionIds); // Reuse attune logic for initial states

        emit DepositReceived(currentDepositId, msg.sender, address(0), msg.value, _stateDefinitionIds);
    }

    /**
     * @dev Deposits ERC20 tokens into the vault, linking it to specified potential states.
     * Requires prior approval of the token amount for this contract.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     * @param _stateDefinitionIds IDs of the initial state definitions for this deposit.
     */
    function depositERC20(address _tokenAddress, uint256 _amount, uint256[] memory _stateDefinitionIds) external whenNotPaused {
        require(_tokenAddress != address(0), "QV: Zero token address");
        require(_amount > 0, "QV: Zero amount");
        require(_stateDefinitionIds.length > 0, "QV: Must provide initial states");

        IERC20 token = IERC20(_tokenAddress);
        // Use transferFrom as recommended practice for pulling tokens
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "QV: ERC20 transfer failed");

        uint256 currentDepositId = nextDepositId++;
        deposits[currentDepositId] = DepositDetails({
            id: currentDepositId,
            depositor: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount,
            depositTimestamp: block.timestamp,
            resolvedStateDefinitionId: 0,
            resolutionTimestamp: 0,
            status: DepositStatus.Potential,
            isEth: false
        });

        attuneDepositToStates(currentDepositId, _stateDefinitionIds); // Reuse attune logic

        emit DepositReceived(currentDepositId, msg.sender, _tokenAddress, _amount, _stateDefinitionIds);
    }

    // --- Quantum State Definition Management ---

    /**
     * @dev Creates a new quantum state definition with specified conditions and release rules.
     * @param _conditions Array of conditions for this state.
     * @param _releaseRecipient The address to receive funds upon release (0x0 for deposit owner).
     * @param _releaseStartTime Timestamp when funds can be released *after* resolution.
     * @param _releaseEndTime Timestamp when funds *must* be released by after resolution (0 for no end).
     * @param _releaseTriggerAddress Specific address required to trigger release (0x0 for recipient/owner).
     * @return The ID of the newly created state definition.
     */
    function createQuantumStateDefinition(
        QuantumStateCondition[] memory _conditions,
        address _releaseRecipient,
        uint256 _releaseStartTime,
        uint256 _releaseEndTime,
        address _releaseTriggerAddress
    ) external onlyOwner returns (uint256) {
        uint256 stateId = nextStateDefinitionId++;
        stateDefinitions[stateId] = QuantumStateDefinition({
            id: stateId,
            conditions: _conditions,
            releaseRecipient: _releaseRecipient,
            releaseStartTime: _releaseStartTime,
            releaseEndTime: _releaseEndTime,
            releaseTriggerAddress: _releaseTriggerAddress,
            active: true,
            resolvedDependencyMet: false // Reset for new definition
        });
        emit StateDefinitionCreated(stateId, msg.sender);
        return stateId;
    }

     /**
     * @dev Updates an existing quantum state definition. Can break existing deposit links if conditions change drastically.
     * Only active states can be updated.
     * @param _stateDefinitionId The ID of the state definition to update.
     * @param _newConditions New array of conditions.
     * @param _newReleaseRecipient New release recipient.
     * @param _newReleaseStartTime New release start time.
     * @param _newReleaseEndTime New release end time.
     * @param _newReleaseTriggerAddress New release trigger address.
     */
    function updateQuantumStateDefinition(
        uint256 _stateDefinitionId,
        QuantumStateCondition[] memory _newConditions,
        address _newReleaseRecipient,
        uint256 _newReleaseStartTime,
        uint256 _newReleaseEndTime,
        address _newReleaseTriggerAddress
    ) external onlyOwner {
        QuantumStateDefinition storage stateDef = stateDefinitions[_stateDefinitionId];
        require(stateDef.id != 0, "QV: State definition not found");
        require(stateDef.active, "QV: State definition is inactive");

        stateDef.conditions = _newConditions;
        stateDef.releaseRecipient = _newReleaseRecipient;
        stateDef.releaseStartTime = _newReleaseStartTime;
        stateDef.releaseEndTime = _newReleaseEndTime;
        stateDef.releaseTriggerAddress = _newReleaseTriggerAddress;

        emit StateDefinitionUpdated(_stateDefinitionId);
    }

    /**
     * @dev Deactivates a quantum state definition. Existing deposits linked to it remain linked,
     * but it cannot be used for new deposits or successfully resolve until reactivated.
     * @param _stateDefinitionId The ID of the state definition to deactivate.
     */
    function deactivateQuantumStateDefinition(uint256 _stateDefinitionId) external onlyOwner {
        QuantumStateDefinition storage stateDef = stateDefinitions[_stateDefinitionId];
        require(stateDef.id != 0, "QV: State definition not found");
        require(stateDef.active, "QV: State definition already inactive");

        stateDef.active = false;
        emit StateDefinitionDeactivated(_stateDefinitionId);
    }

    // --- Deposit State Attunement ---

    /**
     * @dev Attunes a deposit to additional potential state definitions.
     * Callable by the deposit owner or contract owner.
     * @param _depositId The ID of the deposit.
     * @param _stateDefinitionIds IDs of the state definitions to add.
     */
    function attuneDepositToStates(uint256 _depositId, uint256[] memory _stateDefinitionIds) public whenNotPaused {
        DepositDetails storage deposit = deposits[_depositId];
        require(deposit.id != 0, "QV: Deposit not found");
        require(msg.sender == deposit.depositor || msg.sender == owner, "QV: Not deposit owner or contract owner");
        require(deposit.status == DepositStatus.Potential, "QV: Deposit not in potential state");

        uint256[] storage potentialStates = depositPotentialStates[_depositId];
        for (uint i = 0; i < _stateDefinitionIds.length; i++) {
            uint256 stateId = _stateDefinitionIds[i];
            QuantumStateDefinition storage stateDef = stateDefinitions[stateId];
            require(stateDef.id != 0 && stateDef.active, "QV: Invalid or inactive state definition ID");

            // Check if already attuned (simple check, can be optimized for large arrays)
            bool alreadyAttuned = false;
            for (uint j = 0; j < potentialStates.length; j++) {
                if (potentialStates[j] == stateId) {
                    alreadyAttuned = true;
                    break;
                }
            }
            if (!alreadyAttuned) {
                potentialStates.push(stateId);
            }
        }
        emit DepositAttuned(_depositId, _stateDefinitionIds);
    }

    /**
     * @dev De-attunes a deposit from potential state definitions.
     * Callable by the deposit owner or contract owner.
     * @param _depositId The ID of the deposit.
     * @param _stateDefinitionIds IDs of the state definitions to remove.
     */
    function deattuneDepositFromStates(uint256 _depositId, uint256[] memory _stateDefinitionIds) public whenNotPaused {
        DepositDetails storage deposit = deposits[_depositId];
        require(deposit.id != 0, "QV: Deposit not found");
        require(msg.sender == deposit.depositor || msg.sender == owner, "QV: Not deposit owner or contract owner");
        require(deposit.status == DepositStatus.Potential, "QV: Deposit not in potential state");

        uint256[] storage potentialStates = depositPotentialStates[_depositId];
        for (uint i = 0; i < _stateDefinitionIds.length; i++) {
            uint256 stateIdToRemove = _stateDefinitionIds[i];
            for (uint j = 0; j < potentialStates.length; j++) {
                if (potentialStates[j] == stateIdToRemove) {
                    // Remove by swapping with last element and popping
                    potentialStates[j] = potentialStates[potentialStates.length - 1];
                    potentialStates.pop();
                    // Decrement j to re-check the swapped element in its new position
                    j--;
                }
            }
        }
        emit DepositDeattuned(_depositId, _stateDefinitionIds);
    }


    // --- The "Measurement" Function ---

    /**
     * @dev Attempts to measure and resolve the state of a deposit.
     * Checks all potential states for the deposit in order. The first state
     * whose conditions are met becomes the resolved state.
     * Callable by anyone, or only catalysts/owner if configured? Let's allow anyone to trigger.
     * Awards a resolution fee to the caller if successful and fee is set.
     * @param _depositId The ID of the deposit to measure.
     */
    function measureQuantumState(uint256 _depositId) external whenNotPaused {
        DepositDetails storage deposit = deposits[_depositId];
        require(deposit.id != 0, "QV: Deposit not found");
        require(deposit.status == DepositStatus.Potential, "QV: Deposit not in potential state");
        require(depositPotentialStates[_depositId].length > 0, "QV: Deposit has no potential states");

        uint256[] memory potentialStateIds = depositPotentialStates[_depositId];
        uint256 resolvedStateId = 0;

        // Iterate through potential states to find the first one whose conditions are met
        for (uint i = 0; i < potentialStateIds.length; i++) {
            uint256 stateId = potentialStateIds[i];
            QuantumStateDefinition storage stateDef = stateDefinitions[stateId];

            // Only consider active states
            if (!stateDef.active) {
                continue;
            }

            // Check all conditions for this state definition
            bool allConditionsMet = true;
            for (uint j = 0; j < stateDef.conditions.length; j++) {
                if (!checkCondition(stateDef.conditions[j], _depositId)) {
                    allConditionsMet = false;
                    break; // If any condition isn't met, this state isn't resolvable *yet*
                }
            }

            if (allConditionsMet) {
                resolvedStateId = stateId;
                break; // Found the first resolvable state, collapse to this one
            }
        }

        // --- Handle Resolution or Expiry ---

        if (resolvedStateId != 0) {
            // State successfully resolved
            deposit.resolvedStateDefinitionId = resolvedStateId;
            deposit.resolutionTimestamp = block.timestamp;
            deposit.status = DepositStatus.Resolved;

            // Clear potential states once resolved
            delete depositPotentialStates[_depositId];

            // Pay resolution fee if set
            uint256 feeAmount = resolutionFees[deposit.tokenAddress];
            if (feeAmount > 0) {
                 // Ensure contract has enough balance or allowance (for ERC20)
                 if (deposit.isEth) {
                     require(address(this).balance >= feeAmount, "QV: Insufficient ETH for fee");
                     // Use call for robust ETH transfer
                     (bool success, ) = payable(msg.sender).call{value: feeAmount}("");
                     require(success, "QV: Fee payment failed");
                 } else {
                     IERC20 token = IERC20(deposit.tokenAddress);
                      // Contract needs allowance from itself to transfer *its own* tokens? No.
                      // Contract simply transfers its balance.
                      require(token.balanceOf(address(this)) >= feeAmount, "QV: Insufficient ERC20 for fee");
                      bool success = token.transfer(msg.sender, feeAmount);
                      require(success, "QV: Fee payment failed");
                 }
                 // Accumulate fee for tracking, even if paid directly
                 accumulatedFees[deposit.tokenAddress][msg.sender] += feeAmount;
            }


            emit DepositMeasured(_depositId, resolvedStateId, msg.sender, feeAmount);

        } else {
            // No state resolved. Check for global decoherence timeout.
            if (globalDecoherenceTimeout > 0 && block.timestamp >= globalDecoherenceTimeout) {
                 // Global timeout reached, check for fallback state
                if (globalFallbackStateDefinitionId != 0) {
                    QuantumStateDefinition storage fallbackStateDef = stateDefinitions[globalFallbackStateDefinitionId];
                    if (fallbackStateDef.id != 0 && fallbackStateDef.active) {
                         // Resolve to the fallback state
                         deposit.resolvedStateDefinitionId = globalFallbackStateDefinitionId;
                         deposit.resolutionTimestamp = block.timestamp;
                         deposit.status = DepositStatus.Resolved;
                         delete depositPotentialStates[_depositId];
                         // No fee paid for fallback resolution unless specifically implemented
                         emit DepositMeasured(_depositId, globalFallbackStateDefinitionId, msg.sender, 0);
                    } else {
                         // Fallback state invalid or inactive, deposit expires unresolved
                         deposit.status = DepositStatus.Expired;
                         delete depositPotentialStates[_depositId];
                         emit DepositExpired(_depositId);
                    }
                } else {
                    // No fallback state defined, deposit expires unresolved
                    deposit.status = DepositStatus.Expired;
                    delete depositPotentialStates[_depositId];
                    emit DepositExpired(_depositId);
                }
            }
            // If no state resolved and no global timeout, deposit remains in Potential status.
        }
    }

    /**
     * @dev Helper function to check if a single QuantumStateCondition is met.
     * Internal visibility.
     * @param _condition The condition struct to check.
     * @param _depositId The ID of the deposit being measured (for context).
     * @return True if the condition is met, false otherwise.
     */
    function checkCondition(QuantumStateCondition memory _condition, uint256 _depositId) internal view returns (bool) {
        // Note: The `mustBeMet` flag in QuantumStateCondition struct is currently
        // ignored by this simple AND logic. A more complex OR logic would require
        // grouping conditions or a different structure.
        DepositDetails storage deposit = deposits[_depositId];

        if (_condition.conditionType == QuantumStateCondition.ConditionType.None) {
            return true; // No condition specified
        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.TimestampAfter) {
            return block.timestamp >= _condition.value;
        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.TimestampBefore) {
            return block.timestamp < _condition.value;
        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.BlockNumberAfter) {
            return block.number >= _condition.value;
        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.BlockNumberBefore) {
            return block.number < _condition.value;
        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.OracleValueGT) {
            require(oracleAddress != address(0), "QV: Oracle address not set for condition");
            (uint256 oracleValue, ) = IDummyOracle(oracleAddress).getData(_condition.key);
            return oracleValue > _condition.value;
        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.OracleValueLT) {
             require(oracleAddress != address(0), "QV: Oracle address not set for condition");
            (uint256 oracleValue, ) = IDummyOracle(oracleAddress).getData(_condition.key);
            return oracleValue < _condition.value;
        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.ExternalAddressTrigger) {
             // This condition means the *specific* address in `triggerAddress` must be the one
             // calling `measureQuantumState`.
             // This check happens *within* measureQuantumState before calling checkCondition.
             // If we are here, it means the caller check passed or this condition isn't being evaluated this way.
             // Let's adjust the logic: ExternalAddressTrigger condition makes the *state* only resolvable
             // IF measure is called by that address. The check happens in measureQuantumState itself.
             // If we reach this condition check *from* measureQuantumState, it means the caller was already validated,
             // or this type isn't part of the state's conditions being evaluated by `checkCondition`.
             // To simplify, let's assume ExternalAddressTrigger is a *state-level* requirement checked *before*
             // calling `checkCondition` for that state's other conditions. Or, it implies `msg.sender == triggerAddress`
             // needs to be true *during* the `measureQuantumState` call for *this specific state* to be considered.
             // Let's implement the latter:
            return msg.sender == _condition.triggerAddress;

        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.DepositResolved) {
            // Requires another specific deposit to be resolved.
            uint256 dependentDepositId = _condition.dependencyId;
            DepositDetails storage dependentDeposit = deposits[dependentDepositId];
            return dependentDeposit.id != 0 && dependentDeposit.status == DepositStatus.Resolved;

        } else if (_condition.conditionType == QuantumStateCondition.ConditionType.StateResolved) {
            // Requires ANY deposit to have resolved to a specific state definition.
            // This needs a state variable tracking which state definitions have been resolved *at least once*.
            // Let's add a mapping: `mapping(uint256 => bool) public stateDefinitionEverResolved;`
            // and update it in `measureQuantumState`.
            // For now, let's skip implementing `stateDefinitionEverResolved` to keep it shorter,
            // or simplify this condition to just depend on another *specific* deposit resolving to that state.
            // Let's go with the simple version for now: `dependencyId` is the StateDefinitionId,
            // and this condition is met if *any* deposit is currently resolved to that state.
            // This requires iterating through all deposits, which is inefficient.
            // A better approach is to track state definition resolutions globally.
            // Let's assume `dependencyId` points to a StateDefinitionId, and it requires that specific definition
            // has been resolved *at least once* somewhere in the system. This uses the `stateDefinitionEverResolved` idea.
            // Need to add `mapping(uint256 => bool) public stateDefinitionEverResolved;`
            // And in `measureQuantumState`, inside the `if (resolvedStateId != 0)` block: `stateDefinitionEverResolved[resolvedStateId] = true;`
            // Then this check becomes:
             require(stateDefinitions[_condition.dependencyId].id != 0, "QV: Dependent state definition not found");
             return stateDefinitions[_condition.dependencyId].resolvedDependencyMet; // Use the flag set when *any* deposit resolves to this state

        }
        return false; // Unknown condition type
    }

     /**
      * @dev Helper function to check if a deposit *can* resolve to any of its potential states currently.
      * Similar logic to `measureQuantumState` but without state changes or fees.
      * @param _depositId The ID of the deposit.
      * @return True if the deposit can be resolved, false otherwise.
      */
    function canResolveDeposit(uint256 _depositId) public view returns (bool) {
        DepositDetails storage deposit = deposits[_depositId];
        if (deposit.id == 0 || deposit.status != DepositStatus.Potential || depositPotentialStates[_depositId].length == 0) {
             // Also check for global timeout fallback
             if (globalDecoherenceTimeout > 0 && block.timestamp >= globalDecoherenceTimeout) {
                 if (globalFallbackStateDefinitionId != 0) {
                     QuantumStateDefinition storage fallbackStateDef = stateDefinitions[globalFallbackStateDefinitionId];
                     return fallbackStateDef.id != 0 && fallbackStateDef.active;
                 }
             }
             return false;
        }

        uint256[] memory potentialStateIds = depositPotentialStates[_depositId];

        // Iterate through potential states to find the first one whose conditions are met
        for (uint i = 0; i < potentialStateIds.length; i++) {
            uint256 stateId = potentialStateIds[i];
            QuantumStateDefinition storage stateDef = stateDefinitions[stateId];

            if (!stateDef.active) {
                continue;
            }

            bool allConditionsMet = true;
            for (uint j = 0; j < stateDef.conditions.length; j++) {
                 // When checking for `canResolve`, the `ExternalAddressTrigger` condition
                 // should evaluate based on `msg.sender`. If it requires a *specific* address
                 // other than the current caller, it won't resolve *for this caller*.
                 // However, `canResolve` should ideally tell us if *any* caller could resolve it.
                 // Let's make a simplifying assumption: `ExternalAddressTrigger` only blocks if
                 // it requires an address *other than the current caller*. For `canResolve`,
                 // we'll assume the *potential* caller is the trigger address if required.
                 // A cleaner way is to require the potential trigger address as a parameter to `canResolve`.
                 // Let's simplify: `canResolve` just checks non-caller specific conditions.
                 // Or better, pass the *potential* trigger address. Let's make it simple for now and
                 // say `canResolve` only checks time/block/oracle/dependency conditions.

                QuantumStateCondition memory condition = stateDef.conditions[j];
                if (condition.conditionType == QuantumStateCondition.ConditionType.ExternalAddressTrigger) {
                    // Skip caller-specific check in a general 'canResolve' check
                    continue;
                }

                if (!checkCondition(condition, _depositId)) {
                    allConditionsMet = false;
                    break;
                }
            }

            if (allConditionsMet) {
                return true; // Found a resolvable state
            }
        }

        // Check for global timeout fallback if no state resolved by standard means
         if (globalDecoherenceTimeout > 0 && block.timestamp >= globalDecoherenceTimeout) {
             if (globalFallbackStateDefinitionId != 0) {
                 QuantumStateDefinition storage fallbackStateDef = stateDefinitions[globalFallbackStateDefinitionId];
                 return fallbackStateDef.id != 0 && fallbackStateDef.active;
             }
         }


        return false; // No resolvable state found
    }


    // --- Release Functions ---

    /**
     * @dev Releases funds from a deposit that has been successfully resolved.
     * Must meet the release criteria of the resolved state definition.
     * Callable by the release recipient, release trigger address, deposit owner, or contract owner.
     * @param _depositId The ID of the deposit to release.
     */
    function releaseResolvedDeposit(uint256 _depositId) external whenNotPaused {
        DepositDetails storage deposit = deposits[_depositId];
        require(deposit.id != 0, "QV: Deposit not found");
        require(deposit.status == DepositStatus.Resolved, "QV: Deposit not in resolved state");

        QuantumStateDefinition storage stateDef = stateDefinitions[deposit.resolvedStateDefinitionId];
        require(stateDef.id != 0, "QV: Resolved state definition not found (corruption?)"); // Should not happen if status is Resolved

        address recipient = stateDef.releaseRecipient == address(0) ? deposit.depositor : stateDef.releaseRecipient;
        address trigger = stateDef.releaseTriggerAddress == address(0) ? recipient : stateDef.releaseTriggerAddress;

        // Check caller permission
        require(
            msg.sender == recipient ||
            msg.sender == trigger ||
            msg.sender == deposit.depositor || // Allow original depositor as a fallback? Or only recipient/trigger? Let's allow original depositor.
            msg.sender == owner,
            "QV: Not authorized to release"
        );

        // Check release time windows
        require(block.timestamp >= stateDef.releaseStartTime, "QV: Release time not reached");
        if (stateDef.releaseEndTime != 0) {
            require(block.timestamp < stateDef.releaseEndTime, "QV: Release window expired");
        }

        // Perform the transfer
        uint256 amountToRelease = deposit.amount; // Release the full resolved amount

        if (deposit.isEth) {
            // Use call for robust ETH transfer
            (bool success, ) = payable(recipient).call{value: amountToRelease}("");
            require(success, "QV: ETH transfer failed");
        } else {
            // ERC20 transfer
            IERC20 token = IERC20(deposit.tokenAddress);
            bool success = token.transfer(recipient, amountToRelease);
            require(success, "QV: ERC20 transfer failed");
        }

        deposit.status = DepositStatus.Released;
        deposit.amount = 0; // Clear amount to prevent double spend
        emit DepositReleased(_depositId, recipient, amountToRelease);
    }

    /**
     * @dev Allows the owner or deposit owner to cancel a deposit IF it has not yet been resolved.
     * Funds are returned to the original depositor.
     * @param _depositId The ID of the deposit to cancel.
     */
    function cancelDeposit(uint256 _depositId) external whenNotPaused {
        DepositDetails storage deposit = deposits[_depositId];
        require(deposit.id != 0, "QV: Deposit not found");
        require(deposit.status == DepositStatus.Potential, "QV: Deposit not in potential state");
        require(msg.sender == deposit.depositor || msg.sender == owner, "QV: Not deposit owner or contract owner");

        uint256 amountToReturn = deposit.amount;
        address depositor = deposit.depositor;

        // Clear potential states
        delete depositPotentialStates[_depositId];

        // Update deposit status
        deposit.status = DepositStatus.Cancelled;
        deposit.amount = 0; // Clear amount

        // Return funds
        if (deposit.isEth) {
            (bool success, ) = payable(depositor).call{value: amountToReturn}("");
            require(success, "QV: ETH transfer failed");
        } else {
            IERC20 token = IERC20(deposit.tokenAddress);
            bool success = token.transfer(depositor, amountToReturn);
            require(success, "QV: ERC20 transfer failed");
        }

        emit DepositCancelled(_depositId, msg.sender);
    }

    /**
     * @dev Admin function to withdraw funds from any deposit in an emergency.
     * Requires the contract to be paused. Transfers funds to the owner.
     * This bypasses all state, condition, and release checks. Use with extreme caution.
     * @param _depositId The ID of the deposit.
     */
    function emergencyWithdrawAdmin(uint256 _depositId) external onlyOwner whenPaused {
        DepositDetails storage deposit = deposits[_depositId];
        require(deposit.id != 0, "QV: Deposit not found");
        require(deposit.status != DepositStatus.Released, "QV: Deposit already released");
        require(deposit.amount > 0, "QV: Deposit amount is zero"); // Should be covered by !Released, but sanity check

        uint256 amountToWithdraw = deposit.amount;
        address recipient = owner; // Emergency funds go to owner

        // Update deposit status
        deposit.status = DepositStatus.Released; // Mark as released to prevent double withdrawal
        deposit.amount = 0; // Clear amount

        // Clear potential states if any
        delete depositPotentialStates[_depositId];

        // Perform transfer
        if (deposit.isEth) {
            (bool success, ) = payable(recipient).call{value: amountToWithdraw}("");
            require(success, "QV: ETH transfer failed");
        } else {
            IERC20 token = IERC20(deposit.tokenAddress);
            bool success = token.transfer(recipient, amountToWithdraw);
            require(success, "QV: ERC20 transfer failed");
        }

        emit EmergencyWithdraw(_depositId, recipient, amountToWithdraw);
    }


    // --- Parameter and Dependency Management ---

    /**
     * @dev Sets the address of the oracle contract used in conditions.
     * @param _oracleAddress The address of the oracle.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "QV: Zero address");
        oracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Sets a generic unsigned integer parameter that can be used in conditions.
     * @param _key The key identifier for the parameter.
     * @param _value The value for the parameter.
     */
    function setConditionParameter(bytes32 _key, uint256 _value) external onlyOwner {
        require(_key != bytes32(0), "QV: Zero key");
        conditionParametersUint[_key] = _value;
        emit ConditionParameterSetUint(_key, _value);
    }

     /**
     * @dev Sets a generic address parameter that can be used in conditions (less likely for this contract, but included).
     * @param _key The key identifier for the parameter.
     * @param _value The value for the parameter.
     */
    function setConditionAddressParameter(bytes32 _key, address _value) external onlyOwner {
        require(_key != bytes32(0), "QV: Zero key");
         require(_value != address(0), "QV: Zero address value");
        conditionParametersAddress[_key] = _value;
        emit ConditionParameterSetAddress(_key, _value);
    }

    /**
     * @dev Sets a dependency: one state definition can only resolve if another specific state definition has *ever* been resolved (on any deposit).
     * This updates the internal `resolvedDependencyMet` flag when a state resolves.
     * @param _stateDefinitionId The ID of the state definition that *depends* on another.
     * @param _dependentStateDefinitionId The ID of the state definition it depends on resolving.
     */
    function setConditionDependency(uint256 _stateDefinitionId, uint256 _dependentStateDefinitionId) external onlyOwner {
        require(_stateDefinitionId != 0 && stateDefinitions[_stateDefinitionId].id != 0, "QV: Dependent state definition not found");
        require(_dependentStateDefinitionId != 0 && stateDefinitions[_dependentStateDefinitionId].id != 0, "QV: Required state definition not found");
        // Internal tracking for StateResolved type dependency.
        // The checkCondition function for type StateResolved will look at stateDefinitions[dependentStateDefinitionId].resolvedDependencyMet
        // This function only validates the IDs exist. The linking is implicit via the ConditionType and dependencyId.
        // Let's use the `stateDefinitionEverResolved` mapping idea after all, it's cleaner.
        // Adding mapping(uint256 => bool) public stateDefinitionEverResolved;
        revert("QV: Use conditionType StateResolved with dependencyId set in state definition");
        // Rationale: The dependency is part of the state's *definition*, not a global setting.
        // You add a condition of type `StateResolved` to a state, pointing to the ID of the state it depends on.
        // This function is removed as it's redundant with creating/updating state definitions.
    }

    /**
     * @dev Removes a state dependency. (This function is removed, see setConditionDependency rationale).
     * @param _stateDefinitionId The ID of the state definition.
     */
    function unsetConditionDependency(uint256 _stateDefinitionId) external onlyOwner {
         revert("QV: Remove dependency condition via updateQuantumStateDefinition");
         // Rationale: Dependency is a condition within a state definition. Update the definition to remove it.
         // This function is removed.
    }

    /**
     * @dev Sets the global decoherence timeout timestamp. After this time, any deposit in Potential status
     * that hasn't resolved can potentially use a fallback state or be force-released (if fallback=0).
     * Set to 0 to disable.
     * @param _timeout The timestamp for the global timeout.
     */
    function setGlobalDecoherenceTimeout(uint256 _timeout) external onlyOwner {
        globalDecoherenceTimeout = _timeout;
        emit GlobalDecoherenceTimeoutSet(_timeout);
    }

     /**
      * @dev Sets the state definition ID used as a fallback when the global decoherence timeout is reached.
      * @param _stateDefinitionId The ID of the fallback state definition (0 to disable fallback).
      */
    function setGlobalFallbackState(uint256 _stateDefinitionId) external onlyOwner {
        if (_stateDefinitionId != 0) {
            require(stateDefinitions[_stateDefinitionId].id != 0, "QV: Fallback state definition not found");
            require(stateDefinitions[_stateDefinitionId].active, "QV: Fallback state definition must be active");
        }
        globalFallbackStateDefinitionId = _stateDefinitionId;
        emit GlobalFallbackStateSet(_stateDefinitionId);
    }


    // --- Fee Management ---

    /**
     * @dev Sets the fee amount paid to the caller of `measureQuantumState` upon successful resolution.
     * Can be set per token address (0x0 for ETH).
     * @param _tokenAddress The address of the token for which to set the fee (0x0 for ETH).
     * @param _feeAmount The amount of the fee.
     */
    function setResolutionFee(address _tokenAddress, uint256 _feeAmount) external onlyOwner {
        resolutionFees[_tokenAddress] = _feeAmount;
        emit ResolutionFeeSet(_tokenAddress, _feeAmount);
    }

    /**
     * @dev Allows a catalyst or the owner to withdraw accumulated fees for a specific token.
     * Fees are accumulated when `measureQuantumState` is called successfully and fees are set.
     * @param _tokenAddress The address of the token for which to withdraw fees (0x0 for ETH).
     */
    function withdrawFees(address _tokenAddress) external onlyCatalystOrOwner {
        uint256 amount = accumulatedFees[_tokenAddress][msg.sender];
        require(amount > 0, "QV: No fees accumulated for this token");

        accumulatedFees[_tokenAddress][msg.sender] = 0; // Reset balance before transfer

        if (_tokenAddress == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "QV: ETH fee withdrawal failed");
        } else {
            IERC20 token = IERC20(_tokenAddress);
            bool success = token.transfer(msg.sender, amount);
            require(success, "QV: ERC20 fee withdrawal failed");
        }

        emit FeesWithdrawn(_tokenAddress, msg.sender, amount);
    }

     /**
      * @dev Allows the owner to recover ERC20 tokens accidentally sent directly to the contract,
      * not via deposit functions.
      * @param _tokenAddress The address of the stuck token.
      * @param _amount The amount to recover.
      */
     function withdrawStuckERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
         require(_tokenAddress != address(0), "QV: Cannot withdraw ETH via this function");
         IERC20 token = IERC20(_tokenAddress);
         require(token.balanceOf(address(this)) >= _amount, "QV: Not enough tokens");
         bool success = token.transfer(owner, _amount);
         require(success, "QV: Stuck ERC20 withdrawal failed");
     }


    // --- View Functions ---

    /**
     * @dev Gets the details of a deposit.
     * @param _depositId The ID of the deposit.
     * @return DepositDetails struct.
     */
    function getDepositDetails(uint256 _depositId) external view returns (DepositDetails memory) {
        require(deposits[_depositId].id != 0, "QV: Deposit not found");
        return deposits[_depositId];
    }

    /**
     * @dev Gets the details of a quantum state definition.
     * @param _stateDefinitionId The ID of the state definition.
     * @return QuantumStateDefinition struct.
     */
    function getQuantumStateDefinition(uint256 _stateDefinitionId) external view returns (QuantumStateDefinition memory) {
        require(stateDefinitions[_stateDefinitionId].id != 0, "QV: State definition not found");
        return stateDefinitions[_stateDefinitionId];
    }

    /**
     * @dev Gets the IDs of the state definitions a deposit is currently attuned to.
     * @param _depositId The ID of the deposit.
     * @return Array of state definition IDs.
     */
    function getPotentialStatesForDeposit(uint256 _depositId) external view returns (uint256[] memory) {
        require(deposits[_depositId].id != 0, "QV: Deposit not found");
        return depositPotentialStates[_depositId];
    }

    /**
     * @dev Gets the ID of the state definition a deposit has been resolved to.
     * @param _depositId The ID of the deposit.
     * @return The resolved state definition ID (0 if not resolved).
     */
    function getResolvedStateForDeposit(uint256 _depositId) external view returns (uint256) {
        require(deposits[_depositId].id != 0, "QV: Deposit not found");
        return deposits[_depositId].resolvedStateDefinitionId;
    }

    /**
     * @dev Gets the token address and amount for a specific deposit.
     * @param _depositId The ID of the deposit.
     * @return tokenAddress, amount, isEth.
     */
    function getDepositAmount(uint256 _depositId) external view returns (address tokenAddress, uint256 amount, bool isEth) {
         require(deposits[_depositId].id != 0, "QV: Deposit not found");
         DepositDetails storage deposit = deposits[_depositId];
         return (deposit.tokenAddress, deposit.amount, deposit.isEth);
    }

    /**
     * @dev Gets the accumulated fees for a specific account and token.
     * @param _tokenAddress The token address (0x0 for ETH).
     * @param _account The account (catalyst or owner).
     * @return Accumulated fee amount.
     */
    function getAccumulatedFees(address _tokenAddress, address _account) external view returns (uint256) {
        return accumulatedFees[_tokenAddress][_account];
    }

    // --- Internal/Private Helpers ---
    // (None explicitly added beyond checkCondition, keep it simple)

}
```