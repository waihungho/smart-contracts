Okay, let's design a smart contract centered around a "Quantum Vault" concept. This concept uses metaphors from quantum mechanics to represent complex, multi-factor conditional access to assets, state transitions that aren't immediately certain, and unique state identifiers.

It will feature functionalities like:
1.  Depositing/Withdrawing assets into standard vaults.
2.  Putting a vault into a "Superposition" state, locking assets under complex conditions.
3.  Defining multiple types of conditions (time-based, value-based, entangled state-based, quantum signature-based) that must be met to "Collapse" the superposition and release assets.
4.  Evaluating the superposition state based on current circumstances and potentially external input.
5.  Simulating "Temporal Coherence Decay" where conditions might change or become harder over time.
6.  Generating a unique "Quantum Signature" for a vault based on its state and history.
7.  "Entangling" the release conditions of one vault with the state of another.
8.  Pre-configuring future state transitions.
9.  Delegating specific control over a vault's quantum state.
10. Owner-level emergency controls and configuration.

This design aims for novelty by creating a complex state machine driven by multiple, configurable condition types and introducing unique concepts like entanglement and temporal decay within a vault/access control context.

---

**Smart Contract: QuantumVault**

**Outline:**

1.  **License & Pragma**
2.  **Imports:** IERC20 interface.
3.  **Error Handling:** Custom errors.
4.  **Enums:** `VaultState`, `ConditionType`, `TransitionType`.
5.  **Structs:**
    *   `Condition`: Defines a single requirement for collapse.
    *   `Vault`: Represents a single vault instance and its state.
    *   `PreconfiguredTransition`: Defines a future state change trigger.
6.  **State Variables:**
    *   Vaults mapping (`vaults`).
    *   Vault counter.
    *   Mapping from user address to list of vault IDs they own.
    *   Entanglement mapping (`vaultEntanglements`).
    *   Quantum Signature mapping (`vaultSignatures`).
    *   Preconfigured Transitions mapping (`vaultPreconfiguredTransitions`).
    *   Contract owner.
    *   Pause state.
    *   Fee configuration (`feePercentage`, `feeRecipient`).
7.  **Events:** Log significant actions (creation, deposit, state change, collapse, entanglement, etc.).
8.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
9.  **Constructor:** Sets initial owner, fees, fee recipient.
10. **Core Logic Functions:**
    *   Vault Creation.
    *   Deposits (ETH, ERC20).
    *   Withdrawals (Standard, Conditional after collapse, Emergency).
    *   Setting Vault Access Controller.
    *   Configuring Superposition Conditions.
    *   Adding specific condition types (Time, Value, Entanglement, Signature).
    *   Putting Vault into Superposition.
    *   Evaluating Superposition Conditions (Attempting Collapse).
    *   Initiating Temporal Decay.
    *   Generating Quantum Signature.
    *   Linking/Breaking Vault Entanglement.
    *   Pre-configuring State Transitions.
    *   Triggering Pre-configured Transitions.
11. **Owner/Admin Functions:**
    *   Updating Fees/Recipient.
    *   Pausing/Unpausing.
    *   Emergency Withdrawals.
12. **View Functions:**
    *   Get Vault Info (State, Balances, Owner, Controller).
    *   Get Vault Conditions.
    *   Get Vault Quantum Signature.
    *   Check Entanglement Status.
    *   Get Pre-configured Transition Info.

**Function Summary (List of >= 20 Functions):**

1.  `constructor()`: Deploys the contract, sets initial owner, fees, fee recipient.
2.  `createVault()`: Creates a new, empty vault instance for the caller.
3.  `depositETH(uint256 _vaultId)`: Deposits sending ETH into a specific vault owned by the caller.
4.  `depositToken(uint256 _vaultId, address _token, uint256 _amount)`: Deposits a specified amount of an ERC20 token into a specific vault owned by the caller (requires prior approval).
5.  `setVaultAccessController(uint256 _vaultId, address _controller)`: Allows the vault owner to delegate control over specific quantum operations (like `evaluateSuperposition`) to another address.
6.  `configureSuperpositionConditions(uint256 _vaultId)`: Initializes or clears the condition set for a vault, preparing it to be put into superposition.
7.  `addTimeCondition(uint256 _vaultId, uint256 _unlockTimestamp, bool _mustBeBefore)`: Adds a condition based on block timestamp (must be before/after a specific time).
8.  `addValueCondition(uint256 _vaultId, bytes32 _oracleValueHash, uint256 _threshold, bool _isGreaterThan)`: Adds a condition comparing a hashed external value (simulated oracle) against a threshold. Requires proving the value matches the hash upon evaluation.
9.  `addEntanglementCondition(uint256 _vaultId, uint256 _entangledVaultId, VaultState _requiredState)`: Adds a condition requiring another specific vault (`_entangledVaultId`) to be in a particular `VaultState`.
10. `addQuantumSignatureCondition(uint256 _vaultId, bytes32 _requiredSignature)`: Adds a condition requiring the vault's generated Quantum Signature to match a specific value.
11. `putIntoSuperposition(uint256 _vaultId)`: Changes the vault's state to `Superposition`, activating the defined conditions. Requires conditions to be set.
12. `evaluateSuperposition(uint256 _vaultId, bytes calldata _oracleValueProof)`: Attempts to collapse the superposition. Checks if ALL defined conditions are met. Requires proving external values for `ValueCondition` types. If successful, changes state to `Decohered` (unlocked).
13. `initiateTemporalDecay(uint256 _vaultId, uint256 _decayStartTime, uint256 _decayRate)`: Starts a decay timer. Affects `evaluateSuperposition` results (e.g., making time windows narrower, requiring more "proof"). (Simulated complexity).
14. `generateQuantumSignature(uint256 _vaultId)`: Generates a unique `bytes32` signature based on the vault's current state, configuration, block data, etc., and stores it. Can only be done once per state transition or specific trigger.
15. `linkVaultsEntanglement(uint256 _vaultAId, uint256 _vaultBId)`: Explicitly links two vaults, enabling the `EntanglementCondition`.
16. `breakEntanglementLink(uint256 _vaultAId)`: Removes an entanglement link initiated from `_vaultAId`.
17. `preConfigureStateTransition(uint256 _vaultId, TransitionType _type, uint256 _triggerValue, uint256 _targetState)`: Sets up a simple state change trigger for the future (e.g., change state after a specific block, or if ETH balance reaches a value).
18. `triggerPreConfiguredTransition(uint256 _vaultId)`: Allows the access controller (or owner) to attempt triggering a pre-configured state transition if its conditions are met.
19. `withdrawCollateralETH(uint256 _vaultId)`: Allows the owner or access controller to withdraw ETH from a vault ONLY if its state is `Decohered`.
20. `withdrawCollateralToken(uint256 _vaultId, address _token)`: Allows the owner or access controller to withdraw ERC20 tokens from a vault ONLY if its state is `Decohered`.
21. `ownerWithdrawFees(address _token)`: Allows the contract owner to withdraw accumulated fees (in ETH or a specific token) to the fee recipient address.
22. `ownerEmergencyWithdrawVaultETH(uint256 _vaultId, uint256 _amount)`: Owner function to withdraw ETH from *any* vault regardless of state in an emergency.
23. `ownerEmergencyWithdrawVaultToken(uint256 _vaultId, address _token, uint256 _amount)`: Owner function to withdraw ERC20 from *any* vault regardless of state in an emergency.
24. `pause()`: Owner function to pause core contract operations (deposits, state changes, withdrawals).
25. `unpause()`: Owner function to unpause the contract.
26. `getVaultInfo(uint256 _vaultId)`: View function returning core information about a vault (state, owner, controller).
27. `getVaultConditions(uint256 _vaultId)`: View function returning the list of conditions configured for a vault.
28. `getVaultBalances(uint256 _vaultId, address[] calldata _tokens)`: View function returning the ETH and specified ERC20 token balances of a vault.
29. `getVaultQuantumSignature(uint256 _vaultId)`: View function returning the last generated quantum signature for a vault.
30. `isVaultEntangledWith(uint256 _vaultAId, uint256 _vaultBId)`: View function checking if vault `_vaultAId` is explicitly linked to `_vaultBId`.
31. `getVaultAccessController(uint256 _vaultId)`: View function returning the delegated access controller address for a vault.
32. `getPreConfiguredTransition(uint256 _vaultId)`: View function returning the details of any pending pre-configured state transition for a vault.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Custom Errors
error VaultNotFound(uint256 vaultId);
error NotVaultOwner(uint256 vaultId, address caller);
error NotVaultOwnerOrController(uint256 vaultId, address caller);
error InvalidVaultState(uint256 vaultId, VaultState currentState, VaultState requiredState);
error ConditionsNotSet(uint256 vaultId);
error ConditionsAlreadySet(uint256 vaultId);
error DepositFailed(uint256 vaultId);
error TransferFailed(address token, address to, uint256 amount);
error ValueConditionProofInvalid(uint256 conditionIndex);
error EntanglementConditionNotMet(uint256 conditionIndex, uint256 entangledVaultId, VaultState requiredState, VaultState currentState);
error QuantumSignatureConditionNotMet(uint256 conditionIndex, bytes32 requiredSignature, bytes32 currentSignature);
error TemporalDecayNotInitiated(uint256 vaultId);
error TemporalDecayInvalidate(uint256 vaultId, uint256 decayTime);
error SignatureAlreadyGenerated(uint256 vaultId);
error VaultAlreadyEntangled(uint256 vaultId, uint256 existingEntanglementId);
error VaultNotEntangled(uint256 vaultId);
error NotEntangledWithTarget(uint256 vaultId, uint256 targetVaultId);
error NoPreconfiguredTransition(uint256 vaultId);
error PreconfiguredTransitionNotReady(uint256 vaultId);
error InsufficientBalance(uint256 vaultId, address token, uint256 required, uint256 current);
error CannotWithdrawInCurrentState(uint256 vaultId, VaultState currentState);
error CannotChangeStateFromCurrentState(uint256 vaultId, VaultState currentState);
error PreconfiguredTransitionAlreadyTriggered(uint256 vaultId);


/**
 * @title QuantumVault
 * @dev A smart contract implementing a complex, conditional vault system using quantum mechanics metaphors.
 * Assets can be held in various states, including 'Superposition', requiring multiple conditions
 * to be met to 'Collapse' the state and allow withdrawal. Features include time locks,
 * external data influence (simulated), vault entanglement, quantum signatures, and temporal decay.
 */
contract QuantumVault is Pausable {
    using SafeMath for uint256;

    enum VaultState {
        Locked,        // Standard locked state, requires simple owner withdrawal (not yet implemented as standard)
        Open,          // Standard open state, owner can deposit/withdraw freely (Default initial state)
        Superposition, // Assets locked under complex, configurable conditions
        Collapsing,    // Conditions are being evaluated (internal/transient state) - maybe not needed, evaluate can be atomic
        Decohered,     // Conditions were met, assets can be withdrawn conditionally
        Decayed,       // Temporal decay invalidated the state (assets permanently locked or owner emergency accessible?) Let's make them owner emergency accessible.
        Entangled      // Not a primary state, but potentially indicates participation in entanglement logic
    }

    enum ConditionType {
        TimeBefore,      // Timestamp must be BEFORE a value
        TimeAfter,       // Timestamp must be AFTER a value
        ValueGreaterThan, // Hashed external value must be > threshold
        ValueLessThan,    // Hashed external value must be < threshold
        EntangledVaultState, // Another vault must be in a specific state
        QuantumSignatureMatch // Vault's quantum signature must match a value
    }

    enum TransitionType {
        TriggerAtBlock,      // Transition happens at a specific block number
        TriggerAtTimestamp,  // Transition happens at a specific timestamp
        TriggerWhenBalanceGT // Transition happens when a specific token balance is greater than a value
    }

    struct Condition {
        ConditionType conditionType;
        uint256 value;           // Timestamp, threshold, or target state (as uint)
        bytes32 data;            // Hashed oracle value, required signature, or target vault ID (as bytes32)
        bool met;                // Tracks if this specific condition has been met during an evaluation
    }

    struct Vault {
        address owner;
        address accessController; // Can trigger certain quantum ops (like evaluateSuperposition)
        VaultState currentState;
        uint256 creationBlock;
        uint256 lastStateChangeBlock;
        Condition[] conditions;
        uint256 temporalDecayStartTime; // 0 if decay not initiated
        uint256 temporalDecayRate;      // Rate per block (higher = faster decay)
        bool conditionsSet; // Flag to track if conditions have been configured
    }

    struct PreconfiguredTransition {
        TransitionType transitionType;
        uint256 triggerValue; // Block number, timestamp, or token amount
        address tokenAddress; // Relevant for TriggerWhenBalanceGT
        VaultState targetState;
        bool triggered;
    }

    mapping(uint255 => Vault) public vaults; // Using uint255 to avoid collision with vaultCounter index 0
    mapping(address => uint255[]) private userVaults; // Mapping from owner to list of vault IDs
    mapping(uint255 => bytes32) private vaultSignatures; // Vault ID => Generated Signature
    mapping(uint255 => uint255) private vaultEntanglements; // Vault A ID => Vault B ID (unidirectional link for condition checking)
    mapping(uint255 => PreconfiguredTransition) private vaultPreconfiguredTransitions; // Vault ID => Transition

    uint255 private vaultCounter;

    uint256 public feePercentage; // In basis points (e.g., 100 = 1%)
    address payable public feeRecipient;

    event VaultCreated(uint255 indexed vaultId, address indexed owner);
    event ETHDeposited(uint255 indexed vaultId, address indexed depositor, uint256 amount);
    event TokenDeposited(uint255 indexed vaultId, address indexed depositor, address indexed token, uint256 amount);
    event ETHWithdrawn(uint255 indexed vaultId, address indexed recipient, uint256 amount);
    event TokenWithdrawn(uint255 indexed vaultId, address indexed recipient, address indexed token, uint256 amount);
    event VaultStateChanged(uint255 indexed vaultId, VaultState oldState, VaultState newState);
    event AccessControllerSet(uint255 indexed vaultId, address indexed controller);
    event ConditionsConfigured(uint255 indexed vaultId);
    event ConditionAdded(uint255 indexed vaultId, ConditionType conditionType, uint256 index);
    event SuperpositionPut(uint255 indexed vaultId);
    event SuperpositionEvaluated(uint255 indexed vaultId, bool success, uint256 timestamp);
    event TemporalDecayInitiated(uint255 indexed vaultId, uint256 startTime, uint256 rate);
    event QuantumSignatureGenerated(uint255 indexed vaultId, bytes32 signature);
    event VaultsEntangled(uint255 indexed vaultAId, uint255 indexed vaultBId);
    event EntanglementBroken(uint255 indexed vaultId);
    event PreconfiguredTransitionSet(uint255 indexed vaultId, TransitionType transitionType, uint256 triggerValue, VaultState targetState);
    event PreconfiguredTransitionTriggered(uint255 indexed vaultId);
    event FeesWithdrawn(address indexed token, uint256 amount, address indexed recipient);
    event EmergencyWithdrawal(uint255 indexed vaultId, address indexed owner, address indexed token, uint256 amount);


    /**
     * @dev Constructor sets initial owner, fee percentage, and recipient.
     * @param _feePercentage The percentage of withdrawal amount to take as fee (in basis points, 0-10000).
     * @param _feeRecipient The address to send fees to.
     */
    constructor(uint256 _feePercentage, address payable _feeRecipient) Pausable(false) {
        if (_feePercentage > 10000) revert("Invalid fee percentage"); // Max 100%
        feePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        vaultCounter = 0; // Start vault IDs from 1
    }

    modifier onlyVaultOwner(uint255 _vaultId) {
        if (vaults[_vaultId].owner != msg.sender) revert NotVaultOwner(_vaultId, msg.sender);
        _;
    }

    modifier onlyVaultOwnerOrController(uint255 _vaultId) {
        if (vaults[_vaultId].owner != msg.sender && vaults[_vaultId].accessController != msg.sender) revert NotVaultOwnerOrController(_vaultId, msg.sender);
        _;
    }

    function vaultExists(uint255 _vaultId) internal view returns (bool) {
         // Check if owner is non-zero (default value), indicating existence
        return vaults[_vaultId].owner != address(0);
    }

    /**
     * @dev Creates a new vault instance for the caller.
     * @return vaultId The ID of the newly created vault.
     */
    function createVault() external whenNotPaused returns (uint255) {
        vaultCounter = vaultCounter.add(1);
        uint255 newVaultId = vaultCounter;
        vaults[newVaultId] = Vault({
            owner: msg.sender,
            accessController: address(0),
            currentState: VaultState.Open,
            creationBlock: block.number,
            lastStateChangeBlock: block.number,
            conditions: new Condition[](0),
            temporalDecayStartTime: 0,
            temporalDecayRate: 0,
            conditionsSet: false
        });
        userVaults[msg.sender].push(newVaultId);
        emit VaultCreated(newVaultId, msg.sender);
        return newVaultId;
    }

    /**
     * @dev Deposits ETH into a specific vault.
     * @param _vaultId The ID of the target vault.
     */
    receive() external payable {
        // Allow receiving ETH directly, perhaps for deposits without specifying vault?
        // Or require calling depositETH with vaultId? Let's require calling depositETH.
        // Or make this a fallback that reverts? Let's revert unless depositETH is called.
        revert("Direct ETH transfers to contract not allowed. Use depositETH(vaultId).");
    }

    function depositETH(uint255 _vaultId) external payable whenNotPaused onlyVaultOwner(_vaultId) {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (msg.value == 0) return; // No deposit
        // ETH is implicitly added to the contract balance, associated with the vault ID via tracking

        // State check? Can deposit into any state that holds assets.
        // Open, Superposition, Decohered are fine. Decayed? Let's allow deposits but not withdrawals.
        if (vaults[_vaultId].currentState == VaultState.Decayed) {
             revert InvalidVaultState(_vaultId, vaults[_vaultId].currentState, VaultState.Open); // Can't deposit into decayed state for simplicity
        }

        // We don't track ETH balance *per vault* directly in the struct due to gas costs.
        // The contract holds the total ETH. Withdrawals check the contract's total balance
        // against expected vault balances calculated off-chain or via events.
        // This requires off-chain indexing or event tracking for users to know their ETH vault balance.
        // For this example, we assume off-chain tracking based on events.

        emit ETHDeposited(_vaultId, msg.sender, msg.value);
    }

    /**
     * @dev Deposits ERC20 tokens into a specific vault.
     * Requires caller to have approved this contract to spend the tokens.
     * @param _vaultId The ID of the target vault.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositToken(uint255 _vaultId, address _token, uint256 _amount) external whenNotPaused onlyVaultOwner(_vaultId) {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (_amount == 0) return;

         if (vaults[_vaultId].currentState == VaultState.Decayed) {
             revert InvalidVaultState(_vaultId, vaults[_vaultId].currentState, VaultState.Open); // Can't deposit into decayed state for simplicity
        }

        IERC20 tokenContract = IERC20(_token);
        uint256 contractBalanceBefore = tokenContract.balanceOf(address(this));
        bool success = tokenContract.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert DepositFailed(_vaultId);
        uint256 contractBalanceAfter = tokenContract.balanceOf(address(this));
        uint256 depositedAmount = contractBalanceAfter.sub(contractBalanceBefore);

        if (depositedAmount != _amount) {
             // Handle cases where transferFrom transfers less than requested (e.g., fee tokens)
             // For simplicity, revert if not exact amount transferred.
             revert DepositFailed(_vaultId);
        }

        // Similar to ETH, we don't track token balance per vault directly in struct.
        // Requires off-chain indexing based on events.

        emit TokenDeposited(_vaultId, msg.sender, _token, depositedAmount);
    }

    /**
     * @dev Sets the access controller for a vault. This address can trigger quantum operations.
     * @param _vaultId The ID of the target vault.
     * @param _controller The address to set as the controller. Use address(0) to remove.
     */
    function setVaultAccessController(uint255 _vaultId, address _controller) external whenNotPaused onlyVaultOwner(_vaultId) {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        vaults[_vaultId].accessController = _controller;
        emit AccessControllerSet(_vaultId, _controller);
    }

    /**
     * @dev Configures or resets the conditions for a vault to transition from Superposition.
     * Can only be done when the vault is in the `Open` state.
     * @param _vaultId The ID of the target vault.
     */
    function configureSuperpositionConditions(uint255 _vaultId) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Open) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Open);
        if (vault.conditionsSet) revert ConditionsAlreadySet(_vaultId);

        // Reset conditions array and flag
        delete vault.conditions; // Clears array
        vault.conditionsSet = true;

        emit ConditionsConfigured(_vaultId);
    }

     /**
     * @dev Adds a time-based condition to a vault's superposition configuration.
     * Requires `configureSuperpositionConditions` to have been called first.
     * @param _vaultId The ID of the target vault.
     * @param _timestamp The timestamp for the condition check.
     * @param _mustBeBefore If true, requires block.timestamp < _timestamp; if false, requires block.timestamp > _timestamp.
     */
    function addTimeCondition(uint255 _vaultId, uint256 _timestamp, bool _mustBeBefore) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Open) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Open);
        if (!vault.conditionsSet) revert ConditionsNotSet(_vaultId);

        ConditionType cType = _mustBeBefore ? ConditionType.TimeBefore : ConditionType.TimeAfter;

        vault.conditions.push(Condition({
            conditionType: cType,
            value: _timestamp,
            data: bytes32(0), // Not used for time conditions
            met: false
        }));
        emit ConditionAdded(_vaultId, cType, vault.conditions.length - 1);
    }

    /**
     * @dev Adds a value-based condition to a vault's superposition configuration.
     * Requires `configureSuperpositionConditions` to have been called first.
     * The actual value is not stored on-chain, only its hash. The value must be provided
     * upon evaluation (`evaluateSuperposition`) and match the stored hash.
     * @param _vaultId The ID of the target vault.
     * @param _oracleValueHash Keccak256 hash of the required external value.
     * @param _threshold The threshold to compare against the external value.
     * @param _isGreaterThan If true, requires oracleValue > _threshold; if false, requires oracleValue < _threshold.
     */
    function addValueCondition(uint255 _vaultId, bytes32 _oracleValueHash, uint256 _threshold, bool _isGreaterThan) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Open) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Open);
        if (!vault.conditionsSet) revert ConditionsNotSet(_vaultId);
        if (_oracleValueHash == bytes32(0)) revert("Invalid oracle value hash");

        ConditionType cType = _isGreaterThan ? ConditionType.ValueGreaterThan : ConditionType.ValueLessThan;

        vault.conditions.push(Condition({
            conditionType: cType,
            value: _threshold,
            data: _oracleValueHash,
            met: false
        }));
        emit ConditionAdded(_vaultId, cType, vault.conditions.length - 1);
    }

     /**
     * @dev Adds a condition requiring another vault to be in a specific state (Entanglement).
     * Requires `configureSuperpositionConditions` and `linkVaultsEntanglement` to have been used.
     * @param _vaultId The ID of the target vault having the condition.
     * @param _entangledVaultId The ID of the vault whose state is being checked.
     * @param _requiredState The required state of the entangled vault.
     */
    function addEntanglementCondition(uint255 _vaultId, uint255 _entangledVaultId, VaultState _requiredState) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
         if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
         if (!vaultExists(_entangledVaultId)) revert VaultNotFound(_entangledVaultId);
        if (vault.currentState != VaultState.Open) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Open);
        if (!vault.conditionsSet) revert ConditionsNotSet(_vaultId);
        if (vaultEntanglements[_vaultId] != _entangledVaultId) revert NotEntangledWithTarget(_vaultId, _entangledVaultId);

        vault.conditions.push(Condition({
            conditionType: ConditionType.EntangledVaultState,
            value: uint256(_requiredState), // Store enum as uint
            data: bytes32(_entangledVaultId), // Store entangled vault ID in data
            met: false
        }));
        emit ConditionAdded(_vaultId, ConditionType.EntangledVaultState, vault.conditions.length - 1);
    }

     /**
     * @dev Adds a condition requiring the vault's quantum signature to match a specific value.
     * Requires `configureSuperpositionConditions` to have been called first.
     * The signature must be generated via `generateQuantumSignature` at some point BEFORE evaluation.
     * @param _vaultId The ID of the target vault.
     * @param _requiredSignature The bytes32 signature that must be matched.
     */
    function addQuantumSignatureCondition(uint255 _vaultId, bytes32 _requiredSignature) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
         if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Open) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Open);
        if (!vault.conditionsSet) revert ConditionsNotSet(_vaultId);
        if (_requiredSignature == bytes32(0)) revert("Invalid required signature");

        vault.conditions.push(Condition({
            conditionType: ConditionType.QuantumSignatureMatch,
            value: 0, // Not used for signature conditions
            data: _requiredSignature,
            met: false
        }));
        emit ConditionAdded(_vaultId, ConditionType.QuantumSignatureMatch, vault.conditions.length - 1);
    }


    /**
     * @dev Transitions a vault from `Open` to `Superposition`.
     * Requires conditions to have been configured via `configureSuperpositionConditions`.
     * @param _vaultId The ID of the target vault.
     */
    function putIntoSuperposition(uint255 _vaultId) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Open) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Open);
        if (!vault.conditionsSet || vault.conditions.length == 0) revert("No conditions configured");

        VaultState oldState = vault.currentState;
        vault.currentState = VaultState.Superposition;
        vault.lastStateChangeBlock = block.number;
        emit VaultStateChanged(_vaultId, oldState, vault.currentState);
        emit SuperpositionPut(_vaultId);
    }

    /**
     * @dev Attempts to evaluate the conditions for a vault in `Superposition`.
     * If all conditions are met, the vault transitions to `Decohered` (unlocked).
     * Can be called by the vault owner or the designated access controller.
     * @param _vaultId The ID of the target vault.
     * @param _oracleValueProof Required for ValueCondition types: an array of bytes representing the actual values corresponding to the stored hashes.
     */
    function evaluateSuperposition(uint255 _vaultId, bytes calldata _oracleValueProof) external whenNotPaused onlyVaultOwnerOrController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Superposition) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Superposition);

        bool allConditionsMet = true;
        uint265 oracleProofIndex = 0; // Use uint265 to ensure it doesn't overflow bytes index

        // Check temporal decay
        if (vault.temporalDecayStartTime > 0) {
            uint256 decayTimeElapsed = block.timestamp.sub(vault.temporalDecayStartTime);
            // Simple decay logic: after decayRate seconds per condition, conditions become invalid
            // In a real system, decay could make conditions harder, or introduce randomness.
            // Here, simplify: decay makes the state Decayed after a total time based on rate and number of conditions.
            uint256 totalDecayThreshold = uint256(vault.conditions.length).mul(vault.temporalDecayRate);
            if (decayTimeElapsed >= totalDecayThreshold) {
                 vault.currentState = VaultState.Decayed;
                 vault.lastStateChangeBlock = block.number;
                 emit VaultStateChanged(_vaultId, VaultState.Superposition, vault.currentState);
                 emit TemporalDecayInvalidate(_vaultId, decayTimeElapsed);
                 emit SuperpositionEvaluated(_vaultId, false, block.timestamp);
                 return; // Cannot evaluate if decayed
            }
        }


        for (uint256 i = 0; i < vault.conditions.length; i++) {
            bool conditionMet = false;
            Condition storage cond = vault.conditions[i];

            if (cond.conditionType == ConditionType.TimeBefore) {
                conditionMet = block.timestamp < cond.value;
            } else if (cond.conditionType == ConditionType.TimeAfter) {
                conditionMet = block.timestamp > cond.value;
            } else if (cond.conditionType == ConditionType.ValueGreaterThan || cond.conditionType == ConditionType.ValueLessThan) {
                // Requires proof from calldata
                bytes32 provenValueHash;
                 // Safely extract bytes32 from calldata
                if (oracleProofIndex + 32 > _oracleValueProof.length) {
                    revert ValueConditionProofInvalid(i); // Not enough proof data
                }
                 assembly {
                     provenValueHash := calldataload(add(_oracleValueProof.offset, oracleProofIndex))
                 }
                 oracleProofIndex += 32;

                // Example: Assume proof is just the actual uint256 value, hashed
                // In a real system, this might involve cryptographic proofs (ZK) or signatures.
                // For simulation, we just require the hash to match.
                // A real oracle would provide (value, proof, timestamp) and contract verifies proof(value) == hash
                // Simplification: we check if the provided hash matches the expected hash *and* if the value itself matches its hash.
                // A slightly better simulation: require keccak256(provided_bytes) == stored_hash AND compare value derived from provided_bytes
                // Let's simplify further: Require the provided bytes in _oracleValueProof *are* the value as bytes32, and its hash matches, THEN compare the value.

                // If the proof is intended to be the actual uint256 value encoded as bytes32:
                 bytes32 expectedHash = keccak256(_oracleValueProof[oracleProofIndex-32:oracleProofIndex]);
                if (expectedHash != cond.data) {
                     revert ValueConditionProofInvalid(i); // Provided proof hash does not match stored hash
                }
                uint256 provenValue;
                 assembly {
                     provenValue := calldataload(add(_oracleValueProof.offset, oracleProofIndex-32)) // Load the value from proof bytes
                 }

                if (cond.conditionType == ConditionType.ValueGreaterThan) {
                    conditionMet = provenValue > cond.value; // cond.value is the threshold
                } else { // ValueLessThan
                    conditionMet = provenValue < cond.value; // cond.value is the threshold
                }

            } else if (cond.conditionType == ConditionType.EntangledVaultState) {
                uint255 entangledVaultId = uint255(uint160(cond.data)); // Data stores the entangled vault ID
                VaultState requiredState = VaultState(uint8(cond.value)); // Value stores the required state enum (as uint8)

                if (!vaultExists(entangledVaultId)) {
                    // Entangled vault doesn't exist? Condition fails or reverts? Let's make it fail.
                    conditionMet = false;
                } else {
                     VaultState actualState = vaults[entangledVaultId].currentState;
                    conditionMet = (actualState == requiredState);
                    if (!conditionMet) {
                         // Provide details on why it failed
                         revert EntanglementConditionNotMet(i, entangledVaultId, requiredState, actualState);
                    }
                }

            } else if (cond.conditionType == ConditionType.QuantumSignatureMatch) {
                bytes32 requiredSignature = cond.data;
                bytes32 currentSignature = vaultSignatures[_vaultId];

                conditionMet = (currentSignature != bytes32(0) && currentSignature == requiredSignature);
                if (!conditionMet && requiredSignature != bytes32(0)) {
                    // Revert with details if a specific signature was required but not met
                    revert QuantumSignatureConditionNotMet(i, requiredSignature, currentSignature);
                }
                 // If requiredSignature is bytes32(0), maybe any signature works? No, condition requires a *match*.
                 // If currentSignature is bytes32(0), condition fails.
            }

            cond.met = conditionMet; // Store the result of this evaluation
            if (!conditionMet) {
                allConditionsMet = false;
                // In a real system, you might stop here or continue to see which failed.
                // Let's continue for a full report (via stored 'met' flags or events).
                // For simplicity, break early if any fail to save gas.
                break;
            }
        }

        emit SuperpositionEvaluated(_vaultId, allConditionsMet, block.timestamp);

        if (allConditionsMet) {
            VaultState oldState = vault.currentState;
            vault.currentState = VaultState.Decohered;
            vault.lastStateChangeBlock = block.number;
             // Reset conditions 'met' status after successful collapse (optional, but cleaner)
             for(uint256 i = 0; i < vault.conditions.length; i++){
                 vault.conditions[i].met = false;
             }
            emit VaultStateChanged(_vaultId, oldState, vault.currentState);
        } else {
             // Optionally reset 'met' status if collapse failed, to require re-evaluation
             for(uint256 i = 0; i < vault.conditions.length; i++){
                 vault.conditions[i].met = false;
             }
        }
    }

    /**
     * @dev Initiates the temporal decay process for a vault.
     * Once initiated, conditions might become harder or the vault might transition to `Decayed` state over time.
     * Can only be called by the vault owner while in `Superposition`.
     * @param _vaultId The ID of the target vault.
     * @param _decayRate The rate of decay per second (e.g., seconds per condition validity).
     */
    function initiateTemporalDecay(uint255 _vaultId, uint256 _decayRate) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Superposition) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Superposition);
        if (_decayRate == 0) revert("Decay rate must be positive");
        if (vault.temporalDecayStartTime > 0) revert("Temporal decay already initiated");

        vault.temporalDecayStartTime = block.timestamp;
        vault.temporalDecayRate = _decayRate;
        emit TemporalDecayInitiated(_vaultId, vault.temporalDecayStartTime, _decayRate);
    }

    /**
     * @dev Generates and stores a unique "Quantum Signature" for a vault.
     * This signature is derived from various on-chain parameters and the vault's state.
     * It can be used in `QuantumSignatureMatch` conditions.
     * Can only be called once per vault, or perhaps once per state transition in a more complex design.
     * Let's simplify and allow only if no signature exists yet for this vault.
     * @param _vaultId The ID of the target vault.
     */
    function generateQuantumSignature(uint255 _vaultId) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vaultSignatures[_vaultId] != bytes32(0)) revert SignatureAlreadyGenerated(_vaultId);

        // Generate a signature based on unique contract/block/vault data
        bytes32 signature = keccak256(abi.encodePacked(
            address(this),
            _vaultId,
            vault.owner,
            vault.currentState,
            vault.creationBlock,
            block.number,
            block.timestamp,
            block.difficulty // Or block.basefee in PoS
        ));

        vaultSignatures[_vaultId] = signature;
        emit QuantumSignatureGenerated(_vaultId, signature);
    }

    /**
     * @dev Establishes a directed entanglement link from vaultA to vaultB.
     * This link is used by `EntanglementCondition`. A vault can only be entangled *with* one other vault at a time from its perspective.
     * Requires owner permission for both vaults in a more secure setup, but simplifying to owner of vaultA for this example.
     * @param _vaultAId The ID of the vault establishing the link (source).
     * @param _vaultBId The ID of the vault being linked to (target).
     */
    function linkVaultsEntanglement(uint255 _vaultAId, uint255 _vaultBId) external whenNotPaused onlyVaultOwner(_vaultAId) {
        if (!vaultExists(_vaultAId)) revert VaultNotFound(_vaultAId);
        if (!vaultExists(_vaultBId)) revert VaultNotFound(_vaultBId);
        if (_vaultAId == _vaultBId) revert("Cannot entangle a vault with itself");
        if (vaultEntanglements[_vaultAId] != 0) revert VaultAlreadyEntangled(_vaultAId, vaultEntanglements[_vaultAId]);
        // Maybe check state? Link can be established in Open or Superposition? Let's allow Open/Superposition.

        vaultEntanglements[_vaultAId] = _vaultBId;
        // Note: This creates a unidirectional link from A to B for A's conditions.
        // To make it bidirectional or require mutual consent, logic needs to be added.
        emit VaultsEntangled(_vaultAId, _vaultBId);
    }

    /**
     * @dev Breaks the entanglement link originating from the specified vault.
     * Can only be called by the owner of the originating vault.
     * @param _vaultId The ID of the vault whose outgoing link should be broken.
     */
    function breakEntanglementLink(uint255 _vaultId) external whenNotPaused onlyVaultOwner(_vaultId) {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vaultEntanglements[_vaultId] == 0) revert VaultNotEntangled(_vaultId);

        uint255 targetVaultId = vaultEntanglements[_vaultId];
        delete vaultEntanglements[_vaultId];
        emit EntanglementBroken(_vaultId);
    }

    /**
     * @dev Sets up a pre-configured state transition based on a future trigger.
     * Can be called by the vault owner when the vault is in the `Open` state.
     * @param _vaultId The ID of the target vault.
     * @param _type The type of trigger (Block, Timestamp, Balance).
     * @param _triggerValue The value for the trigger (block number, timestamp, or amount).
     * @param _targetState The state the vault should transition to when triggered.
     * @param _tokenAddress Relevant for TriggerWhenBalanceGT, otherwise address(0).
     */
    function preConfigureStateTransition(uint255 _vaultId, TransitionType _type, uint256 _triggerValue, VaultState _targetState, address _tokenAddress) external whenNotPaused onlyVaultOwner(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Open) revert InvalidVaultState(_vaultId, vault.currentState, VaultState.Open);
        if (vaultPreconfiguredTransitions[_vaultId].triggered) revert("Transition already exists or was triggered"); // Simple check

        // Basic validation for trigger type
        if (_type == TransitionType.TriggerAtBlock && _triggerValue <= block.number) revert("Trigger block must be in the future");
        if (_type == TransitionType.TriggerAtTimestamp && _triggerValue <= block.timestamp) revert("Trigger timestamp must be in the future");
        if (_type == TransitionType.TriggerWhenBalanceGT && _tokenAddress == address(0)) revert("Token address required for balance trigger");

        vaultPreconfiguredTransitions[_vaultId] = PreconfiguredTransition({
            transitionType: _type,
            triggerValue: _triggerValue,
            tokenAddress: _tokenAddress,
            targetState: _targetState,
            triggered: false
        });

        emit PreconfiguredTransitionSet(_vaultId, _type, _triggerValue, _targetState);
    }

    /**
     * @dev Attempts to trigger a pre-configured state transition if its conditions are met.
     * Can be called by the vault owner or access controller.
     * @param _vaultId The ID of the target vault.
     */
    function triggerPreConfiguredTransition(uint255 _vaultId) external whenNotPaused onlyVaultOwnerOrController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);

        PreconfiguredTransition storage transition = vaultPreconfiguredTransitions[_vaultId];
        if (transition.transitionType == TransitionType(0) && transition.triggerValue == 0 && transition.targetState == VaultState(0)) {
             revert NoPreconfiguredTransition(_vaultId); // Check if default struct value
        }
        if (transition.triggered) revert PreconfiguredTransitionAlreadyTriggered(_vaultId);


        bool triggerMet = false;
        if (transition.transitionType == TransitionType.TriggerAtBlock) {
            triggerMet = block.number >= transition.triggerValue;
        } else if (transition.transitionType == TransitionType.TriggerAtTimestamp) {
            triggerMet = block.timestamp >= transition.triggerValue;
        } else if (transition.transitionType == TransitionType.TriggerWhenBalanceGT) {
            uint256 balance;
            if (transition.tokenAddress == address(0) || transition.tokenAddress == address(1)) { // Use address(1) as placeholder for ETH
                 // ETH Balance check is tricky. Requires tracking balance changes or assuming off-chain knowledge.
                 // Let's skip ETH balance trigger for simplicity or require off-chain proof.
                 // For this sample, only support ERC20 balance trigger.
                 revert("ETH balance trigger not supported directly.");
            } else {
                 balance = IERC20(transition.tokenAddress).balanceOf(address(this));
                 // This check requires off-chain indexing of deposits/withdrawals per vault ID
                 // to know the *vault's* balance, not the *contract's* total balance.
                 // For simplicity, this function can only be reliably used if there's only one vault
                 // or if off-chain logic ensures the contract balance matches the vault's expected balance.
                 // In a real system, dedicated balance tracking per vault is needed.
                 // Let's assume simple total balance check for this example, knowing its limitation.
                 triggerMet = balance > transition.triggerValue;
            }
        }

        if (triggerMet) {
             VaultState oldState = vault.currentState;
            vault.currentState = transition.targetState;
            vault.lastStateChangeBlock = block.number;
            transition.triggered = true; // Mark as triggered

             emit VaultStateChanged(_vaultId, oldState, vault.currentState);
            emit PreconfiguredTransitionTriggered(_vaultId);
        } else {
            revert PreconfiguredTransitionNotReady(_vaultId);
        }
    }


    /**
     * @dev Allows withdrawal of ETH from a vault ONLY if its state is `Decohered`.
     * Applies configured fees. Can be called by owner or access controller.
     * Requires off-chain tracking of vault's ETH balance.
     * @param _vaultId The ID of the target vault.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawCollateralETH(uint255 _vaultId, uint256 _amount) external payable whenNotPaused onlyVaultOwnerOrController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Decohered) revert CannotWithdrawInCurrentState(_vaultId, vault.currentState);
        if (_amount == 0) return;

        // ETH balance check is tricky without on-chain tracking per vault.
        // This withdrawal relies on the contract having enough total ETH.
        // Users/callers *must* track their vault's balance off-chain via deposit/withdrawal events.
        // In a real system, a dedicated balance tracking mechanism is necessary.
        if (address(this).balance < _amount) revert InsufficientBalance(_vaultId, address(0), _amount, address(this).balance);


        uint256 feeAmount = _amount.mul(feePercentage).div(10000);
        uint256 payoutAmount = _amount.sub(feeAmount);

        if (feeAmount > 0) {
            (bool feeSuccess, ) = feeRecipient.call{value: feeAmount}("");
            if (!feeSuccess) revert TransferFailed(address(0), feeRecipient, feeAmount);
        }

        (bool payoutSuccess, ) = payable(msg.sender).call{value: payoutAmount}("");
        if (!payoutSuccess) revert TransferFailed(address(0), msg.sender, payoutAmount);

        emit ETHWithdrawn(_vaultId, msg.sender, _amount); // Emit total amount intended for withdrawal
    }

    /**
     * @dev Allows withdrawal of ERC20 tokens from a vault ONLY if its state is `Decohered`.
     * Applies configured fees. Requires off-chain tracking of vault's token balance.
     * @param _vaultId The ID of the target vault.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawCollateralToken(uint255 _vaultId, address _token, uint256 _amount) external whenNotPaused onlyVaultOwnerOrController(_vaultId) {
        Vault storage vault = vaults[_vaultId];
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (vault.currentState != VaultState.Decohered) revert CannotWithdrawInCurrentState(_vaultId, vault.currentState);
        if (_amount == 0) return;

        IERC20 tokenContract = IERC20(_token);
         // Token balance check is tricky without on-chain tracking per vault.
        // This withdrawal relies on the contract having enough total token balance.
        // Users/callers *must* track their vault's balance off-chain via deposit/withdrawal events.
        // In a real system, a dedicated balance tracking mechanism is necessary.
        uint256 contractTokenBalance = tokenContract.balanceOf(address(this));
        if (contractTokenBalance < _amount) revert InsufficientBalance(_vaultId, _token, _amount, contractTokenBalance);


        uint256 feeAmount = _amount.mul(feePercentage).div(10000);
        uint256 payoutAmount = _amount.sub(feeAmount);

        if (feeAmount > 0) {
             bool feeSuccess = tokenContract.transfer(feeRecipient, feeAmount);
            if (!feeSuccess) revert TransferFailed(_token, feeRecipient, feeAmount);
        }

        bool payoutSuccess = tokenContract.transfer(msg.sender, payoutAmount);
        if (!payoutSuccess) revert TransferFailed(_token, msg.sender, payoutAmount);

        emit TokenWithdrawn(_vaultId, msg.sender, _token, _amount); // Emit total amount intended for withdrawal
    }


    // --- Owner / Admin Functions ---

    /**
     * @dev Allows the owner to withdraw accumulated fees.
     * @param _token Address of the token to withdraw fees in (address(0) for ETH).
     */
    function ownerWithdrawFees(address _token) external onlyOwner {
        if (_token == address(0)) {
            uint256 feeBalance = address(this).balance; // This is *total* ETH balance, requires separate fee tracking for accuracy
             // Assuming simple model where owner can withdraw any balance not associated with an Open/Superposition/Decohered/Decayed vault state.
             // A robust fee system would require dedicated fee balance tracking.
             // Let's assume for this simplified example that the owner withdrawing total ETH/Token balance implies fees IF no vaults are expected to hold it.
             // THIS IS A SIMPLIFICATION. A real contract needs explicit fee tracking.
             // For now, this function is primarily symbolic for demonstrating owner withdrawal.
             // A safer version would rely on the feeRecipient receiving fees immediately upon user withdrawal.
            uint256 amount = address(this).balance; // Placeholder: needs proper fee tracking
             if (amount > 0) {
                (bool success, ) = feeRecipient.call{value: amount}("");
                if (!success) revert TransferFailed(address(0), feeRecipient, amount);
                emit FeesWithdrawn(address(0), amount, feeRecipient);
             }
        } else {
            IERC20 tokenContract = IERC20(_token);
            uint256 amount = tokenContract.balanceOf(address(this)); // Placeholder: needs proper fee tracking
             if (amount > 0) {
                bool success = tokenContract.transfer(feeRecipient, amount);
                if (!success) revert TransferFailed(_token, feeRecipient, amount);
                emit FeesWithdrawn(_token, amount, feeRecipient);
             }
        }
    }


    /**
     * @dev Owner emergency function to withdraw ETH from any vault regardless of state.
     * Use with extreme caution.
     * @param _vaultId The ID of the target vault.
     * @param _amount The amount of ETH to withdraw.
     */
    function ownerEmergencyWithdrawVaultETH(uint255 _vaultId, uint256 _amount) external onlyOwner {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (_amount == 0) return;

        // Again, relies on contract having balance. Owner needs off-chain data.
        uint256 contractBalance = address(this).balance;
         if (contractBalance < _amount) revert InsufficientBalance(_vaultId, address(0), _amount, contractBalance);


        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert TransferFailed(address(0), msg.sender, _amount);

        emit EmergencyWithdrawal(_vaultId, msg.sender, address(0), _amount);
    }

    /**
     * @dev Owner emergency function to withdraw ERC20 from any vault regardless of state.
     * Use with extreme caution.
     * @param _vaultId The ID of the target vault.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to withdraw.
     */
    function ownerEmergencyWithdrawVaultToken(uint255 _vaultId, address _token, uint256 _amount) external onlyOwner {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        if (_amount == 0) return;

        IERC20 tokenContract = IERC20(_token);
        uint256 contractTokenBalance = tokenContract.balanceOf(address(this));
        if (contractTokenBalance < _amount) revert InsufficientBalance(_vaultId, _token, _amount, contractTokenBalance);

        bool success = tokenContract.transfer(msg.sender, _amount);
        if (!success) revert TransferFailed(_token, msg.sender, _amount);

        emit EmergencyWithdrawal(_vaultId, msg.sender, _token, _amount);
    }

     /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * Can only be called by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Can only be called by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }


    // --- View Functions ---

    /**
     * @dev Gets core information about a vault.
     * @param _vaultId The ID of the target vault.
     * @return Vault struct containing state, owner, controller.
     */
    function getVaultInfo(uint255 _vaultId) external view returns (VaultState currentState, address owner, address accessController) {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        Vault storage vault = vaults[_vaultId];
        return (vault.currentState, vault.owner, vault.accessController);
    }

    /**
     * @dev Gets the list of conditions configured for a vault.
     * @param _vaultId The ID of the target vault.
     * @return An array of Condition structs.
     */
    function getVaultConditions(uint255 _vaultId) external view returns (Condition[] memory) {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        Vault storage vault = vaults[_vaultId];
        return vault.conditions;
    }

    /**
     * @dev Gets the ETH and specified ERC20 token balances held by the contract conceptually belonging to a vault.
     * NOTE: This function returns the *contract's total balance*. Off-chain tracking is required
     * to determine the balance *per vault* accurately based on deposit/withdrawal events.
     * @param _vaultId The ID of the target vault (used for validation, not balance lookup).
     * @param _tokens Array of ERC20 token addresses to check.
     * @return ethBalance The total ETH balance of the contract.
     * @return tokenBalances Array of total balances for the specified tokens held by the contract.
     */
    function getVaultBalances(uint255 _vaultId, address[] calldata _tokens) external view returns (uint256 ethBalance, uint256[] memory tokenBalances) {
         if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId); // Validate vault exists

        ethBalance = address(this).balance;
        tokenBalances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] != address(0)) {
                tokenBalances[i] = IERC20(_tokens[i]).balanceOf(address(this));
            } else {
                 // Handle ETH if passed in tokens array, though separate return is better
                 // tokenBalances[i] = ethBalance; // Or indicate error/skip
            }
        }
    }

    /**
     * @dev Gets the quantum signature generated for a vault.
     * Returns bytes32(0) if no signature has been generated.
     * @param _vaultId The ID of the target vault.
     * @return The quantum signature.
     */
    function getVaultQuantumSignature(uint255 _vaultId) external view returns (bytes32) {
        if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        return vaultSignatures[_vaultId];
    }

    /**
     * @dev Checks if a vault is entangled with another specific vault.
     * @param _vaultAId The ID of the vault to check the outgoing link from.
     * @param _vaultBId The ID of the potential target vault.
     * @return True if vaultA is entangled with vaultB, false otherwise.
     */
    function isVaultEntangledWith(uint255 _vaultAId, uint255 _vaultBId) external view returns (bool) {
        if (!vaultExists(_vaultAId)) return false; // Or revert? Let's return false for view functions
        if (!vaultExists(_vaultBId)) return false;
        return vaultEntanglements[_vaultAId] == _vaultBId;
    }

    /**
     * @dev Gets the address currently set as the access controller for a vault.
     * Returns address(0) if no controller is set.
     * @param _vaultId The ID of the target vault.
     * @return The access controller address.
     */
    function getVaultAccessController(uint255 _vaultId) external view returns (address) {
         if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        return vaults[_vaultId].accessController;
    }

    /**
     * @dev Gets details about a pending pre-configured state transition for a vault.
     * @param _vaultId The ID of the target vault.
     * @return transitionType The type of trigger.
     * @return triggerValue The value for the trigger.
     * @return tokenAddress The token address for balance triggers (address(0) otherwise).
     * @return targetState The state the vault will transition to.
     * @return triggered Whether the transition has already been triggered.
     */
    function getPreConfiguredTransition(uint255 _vaultId) external view returns (
        TransitionType transitionType,
        uint256 triggerValue,
        address tokenAddress,
        VaultState targetState,
        bool triggered
    ) {
         if (!vaultExists(_vaultId)) revert VaultNotFound(_vaultId);
        PreconfiguredTransition storage transition = vaultPreconfiguredTransitions[_vaultId];
        return (
            transition.transitionType,
            transition.triggerValue,
            transition.tokenAddress,
            transition.targetState,
            transition.triggered
        );
    }

     /**
     * @dev Get a list of vault IDs owned by a specific address.
     * Note: This mapping is append-only. Vaults are not removed from the list if ownership changes or vault is emergency withdrawn.
     * Requires off-chain indexing for accurate ownership lists.
     * @param _owner The address whose vaults to retrieve.
     * @return An array of vault IDs.
     */
    function getUserVaults(address _owner) external view returns (uint255[] memory) {
        return userVaults[_owner];
    }

     /**
     * @dev Gets the total number of vaults created.
     * @return The current vault counter.
     */
    function getTotalVaultCount() external view returns (uint255) {
        return vaultCounter;
    }
}
```