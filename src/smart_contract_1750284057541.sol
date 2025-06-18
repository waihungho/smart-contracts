Okay, here is a smart contract called `QuantumVault`. It attempts to simulate some concepts inspired by quantum mechanics (superposition, collapse, entanglement) in a deterministic, blockchain-compatible way.

It functions as a vault that holds assets (ETH or a single ERC-20 token). Before a specific "collapse" event, the vault is in a "superposition" state, meaning there are multiple predefined potential ways the assets *could* be distributed. A `triggerCollapse` function, influenced by external factors (provided entropy) and an internal "entangled" value, deterministically selects one of these potential distribution states. Only after this collapse can recipients of the selected state withdraw their share.

It's important to note this is a *simulation* using classical computation and blockchain determinism, not actual quantum effects. The "quantum" aspects are metaphorical for the complex, state-dependent, and uncertainty-resolving nature of the vault's unlock mechanism.

---

## Smart Contract: QuantumVault

**Outline:**

1.  **State Variables:**
    *   Owner, Vault State, Asset Type & Amount
    *   Timing Parameters (lock, collapse window)
    *   Potential States (definitions, recipients, shares)
    *   Collapsed State Information
    *   Observer Permissions
    *   Simulated "Entangled" Value
    *   Withdrawal Tracking
    *   Recipient Share Sums per state
2.  **Enums:**
    *   `VaultState`: Represents the contract's lifecycle state.
    *   `AssetType`: ETH or ERC20 Token.
    *   `CollapseTriggerType`: Differentiates entropy sources.
3.  **Structs:**
    *   `PotentialState`: Defines a possible outcome state (release percentage, minimum time condition).
    *   `RecipientShare`: Defines a recipient and their share percentage within a potential state.
    *   `ObserverPermission`: Defines permissions for a specific observer address.
4.  **Modifiers:**
    *   `onlyOwner`: Restricts function calls to the contract owner.
    *   `whenState`: Restricts function calls based on the current `VaultState`.
    *   `beforeCollapseWindow`: Checks if the current time is before the collapse window starts.
    *   `inCollapseWindow`: Checks if the current time is within the collapse window.
    *   `afterCollapseWindow`: Checks if the current time is after the collapse window ends.
    *   `isValidStateIndex`: Checks if a provided state index is within the bounds.
    *   `isObserver`: Checks if an address is a registered observer.
    *   `canTriggerCollapse`: Checks if an observer has permission to trigger collapse.
    *   `canPerturbEntangledValue`: Checks if an observer has permission to perturb the entangled value.
5.  **Events:**
    *   `VaultSetup`: Initial configuration.
    *   `Deposited`: Assets received.
    *   `PotentialStateDefined`: A potential outcome state was added.
    *   `RecipientAddedToState`: A recipient was added to a potential state.
    *   `RecipientShareUpdated`: A recipient's share was modified.
    *   `SuperpositionFinalized`: Setup complete, vault is ready for collapse.
    *   `EntangledValuePerturbed`: The simulated entangled value was changed.
    *   `ObserverPermissionsUpdated`: An observer's permissions were changed.
    *   `StateCollapsed`: The "measurement" happened, one state was selected.
    *   `FundsWithdrawn`: Assets were successfully withdrawn by a recipient.
    *   `VaultSettled`: All expected funds for the collapsed state have been withdrawn.
6.  **Functions (25+):**
    *   **Setup (State: Setup):**
        *   `constructor`: Initializes contract owner.
        *   `setupVault`: Sets basic vault parameters (asset type, timing).
        *   `definePotentialState`: Adds a new potential outcome state definition.
        *   `addStateRecipient`: Adds a recipient and their share to a potential state.
        *   `updateStateRecipientShare`: Modifies a recipient's share in a state.
        *   `removeStateRecipient`: Removes a recipient from a state.
        *   `finalizePotentialState`: Marks a specific state definition as complete (checks total shares).
        *   `finalizeSuperpositionSetup`: Marks the overall vault setup as complete, transitions to `Superposition`.
    *   **Deposit (State: Setup -> Superposition):**
        *   `depositETH`: Receives ETH into the vault.
        *   `depositToken`: Receives specified ERC-20 tokens into the vault (requires prior approval).
    *   **State Management (State: Setup, Superposition):**
        *   `setObserver`: Grants/modifies permissions for an observer address.
        *   `removeObserver`: Revokes observer permissions.
        *   `perturbEntangledValue`: Modifies the simulated `entangledValue` (influences collapse).
    *   **Collapse (State: Superposition):**
        *   `triggerCollapse`: Executes the "measurement", selecting one state based on entropy, trigger type, time, and `entangledValue`. Transitions to `Collapsed`.
    *   **Withdrawal (State: Collapsed):**
        *   `withdrawRecipientShare`: Allows a designated recipient from the *collapsed* state to withdraw their share, provided the minimum time condition is met.
        *   `settleVault`: Allows the owner/observer to mark the vault as settled after all funds for the collapsed state *should* have been claimed.
    *   **Query/View (Any State, Restricted based on info visibility):**
        *   `getVaultState`: Returns the current state enum.
        *   `getAssetInfo`: Returns the asset type and deposited amount.
        *   `getTimingParameters`: Returns lock and collapse window times.
        *   `getPotentialStateCount`: Returns the number of potential states defined.
        *   `getPotentialStateDetails`: Returns details for a specific potential state.
        *   `getStateRecipientCount`: Returns the number of recipients for a specific potential state.
        *   `getStateRecipientDetails`: Returns details (address, share) for a specific recipient in a state by index.
        *   `getRecipientShareInState`: Returns a recipient's share for a specific potential state (by address).
        *   `getTotalSharesInState`: Returns the sum of shares for a specific potential state.
        *   `getCollapsedStateIndex`: Returns the index of the state selected after collapse.
        *   `getEntangledValue`: Returns the current simulated entangled value.
        *   `getObserverPermissions`: Returns permissions for a specific observer.
        *   `getRecipientWithdrawnStatus`: Checks if a recipient has withdrawn from the collapsed state.
        *   `isRecipientInCollapsedState`: Checks if an address is a recipient in the collapsed state.
        *   `getRemainingBalance`: Returns the current balance of the vault asset.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Note: This contract uses basic ERC20 transfer which might not be compatible with all tokens.
// For production use, OpenZeppelin's SafeERC20 would be recommended for safe transfers.
// Also, Chainlink VRF or similar oracle is needed for truly unpredictable entropy in triggerCollapse
// if relying on external factors beyond block data and user input. This example uses a simple hash.

/// @title QuantumVault
/// @notice A smart contract simulating quantum superposition and collapse for asset distribution.
/// The vault holds assets, enters a 'superposition' of potential distribution states,
/// and one state is deterministically selected ('collapsed') by a triggering function,
/// influenced by external factors and an internal 'entangled' value.
contract QuantumVault is Ownable {

    // --- Enums ---

    enum VaultState {
        Setup,         // Initial state: defining parameters and potential outcomes
        Superposition, // Setup finalized: ready for deposit and collapse
        Collapsed,     // Collapse triggered: one state is chosen, assets unlockable per state rules
        Settled        // Funds for the collapsed state are fully withdrawn or marked as settled
    }

    enum AssetType {
        ETH,
        ERC20
    }

    enum CollapseTriggerType {
        ManualObserver, // Triggered by a permitted observer
        TimedFallback,  // Triggered automatically after collapse window ends (less ideal entropy)
        ExternalOracle  // Placeholder for triggering based on external oracle data (requires integration)
    }

    // --- Structs ---

    struct PotentialState {
        uint256 releasePercentageBP; // Percentage of deposited amount (in basis points, 10000 = 100%) for this state
        uint256 minTimeBeforeCollapse; // Minimum duration after deposit before assets for THIS state can be withdrawn (seconds)
        RecipientShare[] recipients; // List of recipients and their shares within THIS state
        mapping(address => uint256) recipientShareMapping; // Helper for quick lookup of shares
        bool setupFinalized; // True if recipient shares for this state sum to 100%BP
    }

    struct RecipientShare {
        address recipient;
        uint256 sharePercentageBP; // Share percentage within THIS state (in basis points)
    }

    struct ObserverPermission {
        bool isObserver;
        bool canTriggerCollapse;
        bool canPerturbEntangledValue;
    }

    // --- State Variables ---

    VaultState public currentVaultState;
    AssetType public assetType;
    IERC20 public depositToken; // Address of the ERC20 token if assetType is ERC20
    uint256 public depositedAmount; // Total amount deposited

    uint256 public vaultLockUntil; // Overall lock time for the vault
    uint256 public collapseWindowStart; // Time when collapse can first be triggered
    uint256 public collapseWindowEnd;   // Time when collapse must be triggered (or fallback occurs)
    uint256 public collapseTime;        // Actual timestamp when collapse occurred

    PotentialState[] public potentialStates;
    mapping(uint256 => mapping(address => bool)) public hasRecipientWithdrawn; // [stateIndex][recipient] => bool

    int256 public entangledValue; // A simulated value that influences the collapse outcome

    mapping(address => ObserverPermission) public observerPermissions;

    uint256 public collapsedStateIndex = type(uint256).max; // Index of the state selected after collapse

    // --- Modifiers ---

    modifier whenState(VaultState _state) {
        require(currentVaultState == _state, "QV: Invalid state");
        _;
    }

    modifier beforeCollapseWindow() {
        require(block.timestamp < collapseWindowStart, "QV: Collapse window has started");
        _;
    }

    modifier inCollapseWindow() {
        require(block.timestamp >= collapseWindowStart && block.timestamp < collapseWindowEnd, "QV: Not in collapse window");
        _;
    }

    modifier afterCollapseWindow() {
         require(block.timestamp >= collapseWindowEnd, "QV: Collapse window has ended");
         _;
    }

    modifier isValidStateIndex(uint256 _stateIndex) {
        require(_stateIndex < potentialStates.length, "QV: Invalid state index");
        _;
    }

     modifier isObserver(address _address) {
        require(observerPermissions[_address].isObserver, "QV: Not a registered observer");
        _;
        }

     modifier canTriggerCollapse(address _address) {
        require(observerPermissions[_address].isObserver && observerPermissions[_address].canTriggerCollapse, "QV: Observer cannot trigger collapse");
        _;
     }

    modifier canPerturbEntangledValue(address _address) {
        require(observerPermissions[_address].isObserver && observerPermissions[_address].canPerturbEntangledValue, "QV: Observer cannot perturb entangled value");
        _;
    }


    // --- Events ---

    event VaultSetup(AssetType _assetType, address _tokenAddress, uint256 _vaultLockUntil, uint256 _collapseWindowStart, uint256 _collapseWindowEnd);
    event Deposited(address indexed sender, uint256 amount);
    event PotentialStateDefined(uint256 indexed stateIndex, uint256 releasePercentageBP, uint256 minTimeBeforeCollapse);
    event RecipientAddedToState(uint256 indexed stateIndex, address indexed recipient, uint256 sharePercentageBP);
    event RecipientShareUpdated(uint256 indexed stateIndex, address indexed recipient, uint256 newSharePercentageBP);
    event SuperpositionFinalized();
    event EntangledValuePerturbed(int256 oldValue, int256 newValue);
    event ObserverPermissionsUpdated(address indexed observer, bool isObserver, bool canTriggerCollapse, bool canPerturb);
    event StateCollapsed(uint256 indexed collapsedStateIndex, bytes32 indexed collapseEntropy, CollapseTriggerType triggerType);
    event FundsWithdrawn(uint256 indexed stateIndex, address indexed recipient, uint256 amount);
    event VaultSettled();

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        currentVaultState = VaultState.Setup;
    }

    // --- Setup Functions (State: Setup) ---

    /// @notice Sets the fundamental parameters for the vault. Can only be called in Setup state by owner.
    /// @param _assetType The type of asset (ETH or ERC20).
    /// @param _tokenAddress The address of the ERC20 token if _assetType is ERC20. Ignored if ETH.
    /// @param _lockDuration The duration the vault is locked from the moment of deposit (in seconds).
    /// @param _collapseDuration The duration of the collapse window after the lock ends (in seconds).
    /// @param _initialEntangledValue The starting value for the simulated 'entangled' state.
    function setupVault(
        AssetType _assetType,
        address _tokenAddress,
        uint256 _lockDuration,
        uint256 _collapseDuration,
        int256 _initialEntangledValue
    ) external onlyOwner whenState(VaultState.Setup) {
        require(_lockDuration > 0, "QV: Lock duration must be > 0");
        require(_collapseDuration > 0, "QV: Collapse duration must be > 0");
        if (_assetType == AssetType.ERC20) {
            require(_tokenAddress != address(0), "QV: ERC20 address cannot be zero");
            depositToken = IERC20(_tokenAddress);
        }
        assetType = _assetType;
        vaultLockUntil = block.timestamp + _lockDuration;
        collapseWindowStart = vaultLockUntil; // Collapse window starts right after lock ends
        collapseWindowEnd = collapseWindowStart + _collapseDuration;
        entangledValue = _initialEntangledValue;

        emit VaultSetup(assetType, _tokenAddress, vaultLockUntil, collapseWindowStart, collapseWindowEnd);
    }

    /// @notice Defines a potential outcome state for the vault. Can only be called in Setup state by owner.
    /// Shares within this state must sum to 10000 (100%BP) using addStateRecipient and finalizePotentialState.
    /// @param _releasePercentageBP Percentage of the *total deposited amount* allocated to this specific state (in basis points).
    /// @param _minTimeBeforeCollapse Minimum time AFTER DEPOSIT required before funds from this state can be withdrawn, even if collapsed (in seconds).
    /// @return The index of the newly created potential state.
    function definePotentialState(uint256 _releasePercentageBP, uint256 _minTimeBeforeCollapse)
        external onlyOwner whenState(VaultState.Setup) returns (uint256)
    {
        require(_releasePercentageBP > 0 && _releasePercentageBP <= 10000, "QV: Release percentage must be between 1 and 10000 BP");
        potentialStates.push(PotentialState({
            releasePercentageBP: _releasePercentageBP,
            minTimeBeforeCollapse: _minTimeBeforeCollapse,
            recipients: new RecipientShare[](0),
            recipientShareMapping: new mapping(address => uint256)(),
            setupFinalized: false
        }));
        uint256 newStateIndex = potentialStates.length - 1;
        emit PotentialStateDefined(newStateIndex, _releasePercentageBP, _minTimeBeforeCollapse);
        return newStateIndex;
    }

    /// @notice Adds a recipient and their share within a specific potential state. Can only be called in Setup state by owner.
    /// Shares are relative to the amount allocated to this specific state.
    /// @param _stateIndex The index of the potential state to add the recipient to.
    /// @param _recipient The address of the recipient.
    /// @param _sharePercentageBP The share percentage for this recipient within this state (in basis points).
    function addStateRecipient(uint256 _stateIndex, address _recipient, uint256 _sharePercentageBP)
        external onlyOwner whenState(VaultState.Setup) isValidStateIndex(_stateIndex)
    {
        require(_recipient != address(0), "QV: Recipient address cannot be zero");
        require(_sharePercentageBP > 0 && _sharePercentageBP <= 10000, "QV: Share percentage must be between 1 and 10000 BP");
        PotentialState storage state = potentialStates[_stateIndex];
        require(!state.setupFinalized, "QV: State setup already finalized");
        require(state.recipientShareMapping[_recipient] == 0, "QV: Recipient already exists in this state");

        state.recipients.push(RecipientShare({
            recipient: _recipient,
            sharePercentageBP: _sharePercentageBP
        }));
        state.recipientShareMapping[_recipient] = _sharePercentageBP;
        emit RecipientAddedToState(_stateIndex, _recipient, _sharePercentageBP);
    }

     /// @notice Updates the share percentage for an existing recipient within a specific potential state. Can only be called in Setup state by owner.
     /// @param _stateIndex The index of the potential state.
     /// @param _recipient The address of the recipient.
     /// @param _newSharePercentageBP The new share percentage for this recipient (in basis points).
    function updateStateRecipientShare(uint256 _stateIndex, address _recipient, uint256 _newSharePercentageBP)
        external onlyOwner whenState(VaultState.Setup) isValidStateIndex(_stateIndex)
    {
        PotentialState storage state = potentialStates[_stateIndex];
        require(!state.setupFinalized, "QV: State setup already finalized");
        require(state.recipientShareMapping[_recipient] > 0, "QV: Recipient does not exist in this state");
        require(_newSharePercentageBP > 0 && _newSharePercentageBP <= 10000, "QV: New share percentage must be between 1 and 10000 BP");

        uint256 oldShare = state.recipientShareMapping[_recipient];
        state.recipientShareMapping[_recipient] = _newSharePercentageBP;

        // Update in the dynamic array (less efficient, but needed for iteration if recipientShareMapping isn't enough)
        for (uint i = 0; i < state.recipients.length; i++) {
            if (state.recipients[i].recipient == _recipient) {
                state.recipients[i].sharePercentageBP = _newSharePercentageBP;
                break;
            }
        }
        emit RecipientShareUpdated(_stateIndex, _recipient, _newSharePercentageBP);
    }

     /// @notice Removes a recipient from a specific potential state. Can only be called in Setup state by owner.
     /// @param _stateIndex The index of the potential state.
     /// @param _recipient The address of the recipient to remove.
    function removeStateRecipient(uint256 _stateIndex, address _recipient)
        external onlyOwner whenState(VaultState.Setup) isValidStateIndex(_stateIndex)
    {
        PotentialState storage state = potentialStates[_stateIndex];
        require(!state.setupFinalized, "QV: State setup already finalized");
        require(state.recipientShareMapping[_recipient] > 0, "QV: Recipient does not exist in this state");

        state.recipientShareMapping[_recipient] = 0; // Mark as removed in mapping

        // Remove from dynamic array (simple swap and pop - order doesn't matter here)
        uint256 indexToRemove = type(uint256).max;
         for (uint i = 0; i < state.recipients.length; i++) {
            if (state.recipients[i].recipient == _recipient) {
                indexToRemove = i;
                break;
            }
        }
        if (indexToRemove != type(uint256).max) {
             state.recipients[indexToRemove] = state.recipients[state.recipients.length - 1];
             state.recipients.pop();
        }
        // Event not strictly needed for removal, but could be added.
    }


     /// @notice Finalizes the setup for a specific potential state. Checks if recipient shares sum to 10000 (100%BP).
     /// Can only be called in Setup state by owner.
     /// @param _stateIndex The index of the potential state to finalize.
    function finalizePotentialState(uint256 _stateIndex)
        external onlyOwner whenState(VaultState.Setup) isValidStateIndex(_stateIndex)
    {
        PotentialState storage state = potentialStates[_stateIndex];
        require(!state.setupFinalized, "QV: State setup already finalized");

        uint256 totalShares = 0;
        for (uint i = 0; i < state.recipients.length; i++) {
            totalShares += state.recipients[i].sharePercentageBP;
        }
        require(totalShares == 10000, "QV: Recipient shares must sum to 10000 BP");

        state.setupFinalized = true;
    }


    /// @notice Marks the overall vault setup as complete and transitions to Superposition state.
    /// Requires at least one potential state to be defined and finalized. Can only be called in Setup state by owner.
    function finalizeSuperpositionSetup()
        external onlyOwner whenState(VaultState.Setup)
    {
        require(potentialStates.length > 0, "QV: At least one potential state must be defined");
        for (uint i = 0; i < potentialStates.length; i++) {
            require(potentialStates[i].setupFinalized, "QV: All potential states must be finalized");
        }
        currentVaultState = VaultState.Superposition;
        emit SuperpositionFinalized();
    }

    // --- Deposit Functions (State: Setup -> Superposition) ---
    // Note: Deposit moves state from Setup to Superposition if done after setup is finalized.
    // Otherwise, it requires finalizeSuperpositionSetup AFTER deposit.
    // Let's enforce deposit happens *after* finalizeSuperpositionSetup.

     /// @notice Receives ETH into the vault. Can only be called in Superposition state.
     /// @dev Note: This contract does NOT handle deposits if the state is Setup.
     /// Finalize setup BEFORE depositing.
    receive() external payable whenState(VaultState.Superposition) {
        require(assetType == AssetType.ETH, "QV: Vault is for ERC20, not ETH");
        require(depositedAmount == 0, "QV: Only one deposit allowed"); // Simple example: single deposit
        depositedAmount = msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Receives ERC20 tokens into the vault. Can only be called in Superposition state.
    /// Requires prior approval from the sender for the contract to spend the tokens.
    /// @dev Note: This contract does NOT handle deposits if the state is Setup.
    /// Finalize setup BEFORE depositing.
    /// @param amount The amount of tokens to deposit.
    function depositToken(uint256 amount) external whenState(VaultState.Superposition) {
        require(assetType == AssetType.ERC20, "QV: Vault is for ETH, not ERC20");
        require(depositedAmount == 0, "QV: Only one deposit allowed"); // Simple example: single deposit
        require(amount > 0, "QV: Deposit amount must be > 0");
        require(address(depositToken) != address(0), "QV: Token contract not set");

        // This requires the sender to have called approve() on the ERC20 token contract first
        bool success = depositToken.transferFrom(msg.sender, address(this), amount);
        require(success, "QV: Token transfer failed");

        depositedAmount = amount;
        emit Deposited(msg.sender, amount);
    }

    // --- State Management Functions (State: Setup, Superposition) ---

    /// @notice Sets or updates permissions for an observer address. Can be called in Setup or Superposition by owner.
    /// Observers can be granted permission to trigger collapse or perturb the entangled value.
    /// @param _observer The address to set permissions for.
    /// @param _isObserver Whether the address is a registered observer.
    /// @param _canTriggerCollapse Whether the observer can trigger collapse during the window.
    /// @param _canPerturb Whether the observer can change the entangled value.
    function setObserver(address _observer, bool _isObserver, bool _canTriggerCollapse, bool _canPerturb)
        external onlyOwner whenState(VaultState.Setup) whenState(VaultState.Superposition)
    {
        require(_observer != address(0), "QV: Observer address cannot be zero");
        observerPermissions[_observer] = ObserverPermission({
            isObserver: _isObserver,
            canTriggerCollapse: _canTriggerCollapse,
            canPerturbEntangledValue: _canPerturb
        });
        emit ObserverPermissionsUpdated(_observer, _isObserver, _canTriggerCollapse, _canPerturb);
    }

    /// @notice Removes an observer's permissions. Can be called in Setup or Superposition by owner.
    /// @param _observer The address to remove permissions from.
    function removeObserver(address _observer)
        external onlyOwner whenState(VaultState.Setup) whenState(VaultState.Superposition)
    {
         require(_observer != address(0), "QV: Observer address cannot be zero");
         delete observerPermissions[_observer];
         emit ObserverPermissionsUpdated(_observer, false, false, false); // Emit event showing permissions revoked
    }


    /// @notice Perturbs the simulated entangled value. Can be called in Superposition state by owner or permitted observer.
    /// This value directly influences the outcome of the collapse function.
    /// @param _newValue The new value for the entangled state.
    function perturbEntangledValue(int256 _newValue)
        external whenState(VaultState.Superposition)
    {
        require(msg.sender == owner() || (observerPermissions[msg.sender].isObserver && observerPermissions[msg.sender].canPerturbEntangledValue), "QV: Not authorized to perturb");
        int256 oldValue = entangledValue;
        entangledValue = _newValue;
        emit EntangledValuePerturbed(oldValue, newValue);
    }

    // --- Collapse Function (State: Superposition) ---

    /// @notice Triggers the 'collapse' of the superposition state. Deterministically selects one potential state.
    /// Can be called in Superposition state within the collapse window by owner or permitted observer.
    /// If the collapse window ends and collapse hasn't occurred, owner can trigger fallback.
    /// @param _externalEntropy An external bytes32 value provided by the caller (simulating external input).
    /// @param _triggerType The type of trigger being used.
    function triggerCollapse(bytes32 _externalEntropy, CollapseTriggerType _triggerType)
        external whenState(VaultState.Superposition)
    {
        // Determine who can trigger collapse
        bool authorized = false;
        if (_triggerType == CollapseTriggerType.ManualObserver) {
            authorized = msg.sender == owner() || (observerPermissions[msg.sender].isObserver && observerPermissions[msg.sender].canTriggerCollapse);
            require(inCollapseWindow(), "QV: Manual collapse must be within the window");
        } else if (_triggerType == CollapseTriggerType.TimedFallback) {
             authorized = msg.sender == owner(); // Only owner can trigger fallback for safety
             require(afterCollapseWindow(), "QV: Timed fallback only after window ends");
        }
        // Add more trigger types (e.g., ExternalOracle) with corresponding checks if needed
        require(authorized, "QV: Not authorized to trigger collapse");

        require(potentialStates.length > 0, "QV: No potential states defined to collapse into");
        require(depositedAmount > 0, "QV: No funds deposited to collapse distribution for");

        // Deterministic collapse logic:
        // Mix various sources of entropy/state
        bytes32 combinedEntropy = keccak256(
            abi.encodePacked(
                _externalEntropy,
                block.timestamp,
                block.difficulty, // Or block.prevrandao in PoS
                msg.sender,
                tx.origin,
                entangledValue,
                depositedAmount,
                address(this)
            )
        );

        // Use modulo to map hash to state index.
        // This is deterministic based on the inputs at the time of the transaction.
        collapsedStateIndex = uint256(combinedEntropy) % potentialStates.length;

        collapseTime = block.timestamp;
        currentVaultState = VaultState.Collapsed;

        emit StateCollapsed(collapsedStateIndex, combinedEntropy, _triggerType);
    }

    // --- Withdrawal Functions (State: Collapsed) ---

    /// @notice Allows a recipient of the collapsed state to withdraw their calculated share.
    /// Can only be called in Collapsed state by a recipient of the collapsed state.
    /// Requires the minTimeBeforeCollapse for the selected state to have passed relative to the deposit time.
    function withdrawRecipientShare() external whenState(VaultState.Collapsed) {
        uint256 stateIndex = collapsedStateIndex; // Get the determined state index
        PotentialState storage collapsedState = potentialStates[stateIndex]; // Access the collapsed state details

        require(collapsedState.recipientShareMapping[msg.sender] > 0, "QV: Not a recipient in the collapsed state");
        require(!hasRecipientWithdrawn[stateIndex][msg.sender], "QV: Funds already withdrawn for this recipient in this state");

        // Check the minimum time condition for the *collapsed* state relative to the deposit time
        require(block.timestamp >= collapseTime + collapsedState.minTimeBeforeCollapse, "QV: Minimum time condition not met for withdrawal"); // Use collapseTime for timing

        uint256 stateAllocatedAmount = (depositedAmount * collapsedState.releasePercentageBP) / 10000; // Amount allocated to THIS specific collapsed state
        uint256 recipientShareBP = collapsedState.recipientShareMapping[msg.sender];
        uint256 recipientAmount = (stateAllocatedAmount * recipientShareBP) / 10000; // Recipient's share of THAT amount

        require(recipientAmount > 0, "QV: Calculated withdrawal amount is zero");

        hasRecipientWithdrawn[stateIndex][msg.sender] = true;

        // Perform withdrawal
        if (assetType == AssetType.ETH) {
            (bool success, ) = payable(msg.sender).call{value: recipientAmount}("");
            require(success, "QV: ETH transfer failed");
        } else { // ERC20
            require(address(depositToken) != address(0), "QV: Token contract not set for withdrawal");
            bool success = depositToken.transfer(msg.sender, recipientAmount);
            require(success, "QV: Token transfer failed");
        }

        emit FundsWithdrawn(stateIndex, msg.sender, recipientAmount);
    }

    /// @notice Allows the owner to mark the vault as settled, even if some funds for the collapsed state haven't been withdrawn.
    /// Use with caution. This changes the state but does not force withdrawals.
    /// Can only be called in Collapsed state by owner.
    function settleVault() external onlyOwner whenState(VaultState.Collapsed) {
        currentVaultState = VaultState.Settled;
        emit VaultSettled();
    }


    // --- Query/View Functions (Any State) ---

    /// @notice Returns the current state of the vault.
    function getVaultState() external view returns (VaultState) {
        return currentVaultState;
    }

     /// @notice Returns information about the deposited asset.
    function getAssetInfo() external view returns (AssetType, address, uint256) {
        return (assetType, address(depositToken), depositedAmount);
    }

    /// @notice Returns the vault's timing parameters.
    function getTimingParameters() external view returns (uint256, uint256, uint256, uint256) {
        return (vaultLockUntil, collapseWindowStart, collapseWindowEnd, collapseTime);
    }

    /// @notice Returns the total number of potential states defined.
    function getPotentialStateCount() external view returns (uint256) {
        return potentialStates.length;
    }

    /// @notice Returns details for a specific potential state.
    /// @param _stateIndex The index of the potential state.
    /// @return releasePercentageBP_ The percentage of total funds allocated to this state.
    /// @return minTimeBeforeCollapse_ The minimum time condition for this state.
    /// @return setupFinalized_ Whether the setup for this state is finalized.
    function getPotentialStateDetails(uint256 _stateIndex)
        external view isValidStateIndex(_stateIndex) returns (uint256 releasePercentageBP_, uint256 minTimeBeforeCollapse_, bool setupFinalized_)
    {
        PotentialState storage state = potentialStates[_stateIndex];
        return (state.releasePercentageBP, state.minTimeBeforeCollapse, state.setupFinalized);
    }

     /// @notice Returns the number of recipients defined for a specific potential state.
     /// @param _stateIndex The index of the potential state.
     /// @return The number of recipients.
    function getStateRecipientCount(uint256 _stateIndex)
        external view isValidStateIndex(_stateIndex) returns (uint256)
    {
         return potentialStates[_stateIndex].recipients.length;
    }

    /// @notice Returns the recipient address and their share percentage by index within a state.
    /// @param _stateIndex The index of the potential state.
    /// @param _recipientIndex The index of the recipient within the state's recipients array.
    /// @return recipient_ The recipient's address.
    /// @return sharePercentageBP_ The recipient's share within this state.
    function getStateRecipientDetails(uint256 _stateIndex, uint256 _recipientIndex)
         external view isValidStateIndex(_stateIndex) returns (address recipient_, uint256 sharePercentageBP_)
    {
         PotentialState storage state = potentialStates[_stateIndex];
         require(_recipientIndex < state.recipients.length, "QV: Invalid recipient index");
         RecipientShare storage recipient = state.recipients[_recipientIndex];
         return (recipient.recipient, recipient.sharePercentageBP);
    }


    /// @notice Returns the share percentage for a specific recipient within a specific potential state.
    /// @param _stateIndex The index of the potential state.
    /// @param _recipient The address of the recipient.
    /// @return The recipient's share percentage (in basis points). Returns 0 if not a recipient or state invalid.
    function getRecipientShareInState(uint256 _stateIndex, address _recipient)
        external view returns (uint256)
    {
        if (_stateIndex >= potentialStates.length) return 0;
        return potentialStates[_stateIndex].recipientShareMapping[_recipient];
    }

    /// @notice Calculates the total sum of recipient shares defined for a specific potential state.
    /// @param _stateIndex The index of the potential state.
    /// @return The sum of shares (in basis points).
    function getTotalSharesInState(uint256 _stateIndex)
        external view isValidStateIndex(_stateIndex) returns (uint256)
    {
        uint256 total = 0;
        // Iterate through the dynamic array as mapping doesn't store total or allow easy iteration
        RecipientShare[] memory recipients = potentialStates[_stateIndex].recipients;
        for (uint i = 0; i < recipients.length; i++) {
            total += recipients[i].sharePercentageBP;
        }
        return total;
    }


    /// @notice Returns the index of the state that was selected during collapse.
    /// Returns type(uint256).max if collapse hasn't occurred.
    function getCollapsedStateIndex() external view returns (uint256) {
        return collapsedStateIndex;
    }

    /// @notice Returns the current value of the simulated entangled state parameter.
    function getEntangledValue() external view returns (int256) {
        return entangledValue;
    }

    /// @notice Returns the permissions for a specific observer address.
    /// @param _observer The address to check permissions for.
    /// @return isObserver_ Whether the address is a registered observer.
    /// @return canTriggerCollapse_ Whether the observer can trigger collapse.
    /// @return canPerturbEntangledValue_ Whether the observer can perturb the entangled value.
    function getObserverPermissions(address _observer)
        external view returns (bool isObserver_, bool canTriggerCollapse_, bool canPerturbEntangledValue_)
    {
        ObserverPermission storage perm = observerPermissions[_observer];
        return (perm.isObserver, perm.canTriggerCollapse, perm.canPerturbEntangledValue);
    }

    /// @notice Checks if a recipient has already withdrawn their share from the collapsed state.
    /// @param _stateIndex The state index (should be the collapsed index).
    /// @param _recipient The recipient's address.
    /// @return True if the recipient has withdrawn from this state, false otherwise.
    function hasRecipientWithdrawn(uint256 _stateIndex, address _recipient)
        external view returns (bool)
    {
         if (_stateIndex >= potentialStates.length) return false; // Defensive check
         return hasRecipientWithdrawn[_stateIndex][_recipient];
    }

     /// @notice Checks if an address is a recipient in the currently collapsed state.
     /// @param _recipient The address to check.
     /// @return True if the address is a recipient in the collapsed state and has a share > 0.
    function isRecipientInCollapsedState(address _recipient)
        external view returns (bool)
    {
        if (currentVaultState != VaultState.Collapsed) return false;
        return potentialStates[collapsedStateIndex].recipientShareMapping[_recipient] > 0;
    }

    /// @notice Returns the current balance of the vault for the asset it holds.
    function getRemainingBalance() external view returns (uint256) {
        if (assetType == AssetType.ETH) {
            return address(this).balance;
        } else if (address(depositToken) != address(0)) {
            return depositToken.balanceOf(address(this));
        }
        return 0; // Should not happen if vault is setup
    }

    // --- Total Functions Count Check ---
    // Counted functions:
    // 1. constructor
    // 2. setupVault
    // 3. definePotentialState
    // 4. addStateRecipient
    // 5. updateStateRecipientShare
    // 6. removeStateRecipient
    // 7. finalizePotentialState
    // 8. finalizeSuperpositionSetup
    // 9. receive (payable fallback) - counts as a function
    // 10. depositToken
    // 11. setObserver
    // 12. removeObserver
    // 13. perturbEntangledValue
    // 14. triggerCollapse
    // 15. withdrawRecipientShare
    // 16. settleVault
    // 17. getVaultState (view)
    // 18. getAssetInfo (view)
    // 19. getTimingParameters (view)
    // 20. getPotentialStateCount (view)
    // 21. getPotentialStateDetails (view)
    // 22. getStateRecipientCount (view)
    // 23. getStateRecipientDetails (view)
    // 24. getRecipientShareInState (view)
    // 25. getTotalSharesInState (view)
    // 26. getCollapsedStateIndex (view)
    // 27. getEntangledValue (view)
    // 28. getObserverPermissions (view)
    // 29. hasRecipientWithdrawn (view)
    // 30. isRecipientInCollapsedState (view)
    // 31. getRemainingBalance (view)

    // Total functions = 31. Meets the >= 20 requirement.
}
```