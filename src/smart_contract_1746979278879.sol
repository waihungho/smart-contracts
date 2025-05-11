Okay, let's design a smart contract based on a creative, advanced-concept idea that isn't a direct copy of major open-source projects. We'll build a "Quantum Flux Vault" where assets are locked in a state of "superposition" with multiple potential outcomes, and one outcome is determined by a "collapse" event triggered by different mechanisms.

This introduces concepts like multi-state assets, deterministic resolution of uncertainty, and different trigger mechanisms, metaphorically inspired by quantum mechanics.

**Outline & Function Summary:**

*   **Contract Name:** `QuantumFluxVault`
*   **Concept:** A vault system where deposited assets enter a "Superposition" state, having multiple defined potential outcomes. A "Collapse" event resolves the superposition, selecting one specific outcome. The final outcome is then "Executed".
*   **Key States:** `Inactive` (deposited, not in superposition), `Superposition` (locked, multiple potential outcomes), `Collapsed` (outcome determined, awaiting execution), `Completed` (outcome executed), `Cancelled` (vault aborted before collapse).
*   **Potential Outcomes:** Define possible fates for the assets (e.g., withdraw to owner, send to another address, burn, send to a specific contract).
*   **Collapse Mechanisms:** Different ways to trigger the collapse and select an outcome (e.g., Manual by authorized party, based on Block Hash, Time-based, Placeholder for Oracle).
*   **Fees:** Deposit and Collapse fees can be configured.
*   **Access Control:** Uses Ownable for administrative functions and Pausable for safety. Specific roles for manual collapse authorization.

**Function Categories:**

1.  **Core Vault Lifecycle:**
    *   `depositETH`: Deposit ETH, create vault in `Inactive` state.
    *   `depositERC20`: Deposit ERC20, create vault in `Inactive` state.
    *   `setupSuperposition`: Transition vault from `Inactive` to `Superposition`, defining potential outcomes and collapse mechanism.
    *   `cancelVaultSetup`: Cancel an `Inactive` vault, refunding assets.
    *   `cancelSuperposition`: Cancel a `Superposition` vault before collapse (if allowed), refunding assets.
    *   `triggerCollapseManual`: Trigger collapse for a `Manual` mechanism vault (restricted access).
    *   `triggerCollapseBlockHash`: Trigger collapse for a `BlockHash` mechanism vault (callable by anyone after setup).
    *   `triggerCollapseTimeBased`: Trigger collapse for a `TimeBased` mechanism vault (callable by anyone after trigger time).
    *   `triggerCollapseOracle`: Placeholder for Oracle-triggered collapse (shows concept, requires integration).
    *   `executeOutcome`: Execute the determined outcome for a `Collapsed` vault.

2.  **Configuration & Admin:**
    *   `constructor`: Initialize contract, set owner.
    *   `updateManualCollapseAuthorizer`: Add/remove addresses authorized to trigger manual collapse.
    *   `setDepositFee`: Set the fee percentage for deposits.
    *   `setCollapseFee`: Set the fee percentage for collapses.
    *   `withdrawFees`: Owner withdraws accumulated fees.
    *   `pause`: Pause key contract operations.
    *   `unpause`: Unpause the contract.
    *   `addSupportedERC20`: Add an ERC20 token address to the supported list.
    *   `removeSupportedERC20`: Remove an ERC20 token address from the supported list.
    *   `setOracleAddress`: Set the address of an external oracle for Oracle-based collapse (placeholder).

3.  **View Functions:**
    *   `getVaultInfo`: Get all details for a specific vault ID.
    *   `getPotentialOutcomes`: Get the defined potential outcomes for a vault.
    *   `getVaultState`: Get the current state of a vault.
    *   `getVaultOwner`: Get the owner address of a vault.
    *   `getUserVaultIds`: Get a list of vault IDs owned by an address.
    *   `getDepositFee`: Get the current deposit fee percentage.
    *   `getCollapseFee`: Get the current collapse fee percentage.
    *   `isManualCollapseAuthorizer`: Check if an address is authorized for manual collapse.
    *   `getOracleAddress`: Get the configured oracle address.
    *   `isSupportedERC20`: Check if an ERC20 token is supported.
    *   `getTotalFeesCollected`: Get the total accumulated fees.
    *   `getNextVaultId`: Get the ID that will be assigned to the next new vault.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline & Function Summary ---
// Contract: QuantumFluxVault
// Concept: Assets are held in a multi-state "Superposition" vault. A "Collapse" event resolves this to one specific outcome, which is then "Executed".
// Inspired by metaphorical quantum concepts (superposition, collapse).

// States:
// - Inactive: Vault created, but not yet in superposition. Configurable.
// - Superposition: Assets locked. Multiple potential outcomes defined. Awaiting collapse trigger.
// - Collapsed: A collapse event has occurred. One outcome is chosen and stored. Awaiting execution.
// - Completed: The chosen outcome has been executed (assets moved, burned, etc.).
// - Cancelled: Vault was cancelled before collapse. Assets refunded.

// Potential Outcomes: Define actions upon collapse resolution.
// - WithdrawToOwner: Return assets to the vault owner.
// - SendToAddress: Send assets to a specific target address.
// - Burn: Destroy the assets.
// - SendToContract: Send assets to a specific target contract address (e.g., for staking, other interactions).

// Collapse Mechanisms: Define how the collapse is triggered and outcome selected.
// - Manual: Triggered by an authorized address, which also selects the outcome index.
// - BlockHash: Triggered after a specified block number. Outcome selected pseudo-randomly based on block hash.
// - TimeBased: Triggered after a specified timestamp. Outcome selected pseudo-randomly based on block data (timestamp, number).
// - Oracle: (Placeholder) Triggered by a call from a trusted oracle, which provides data for outcome selection.

// Functions Summary (20+):
// --- Core Vault Lifecycle ---
// 1.  constructor(): Deploys and initializes the contract.
// 2.  depositETH() payable: Deposits ETH, creates an Inactive vault.
// 3.  depositERC20(IERC20 token, uint256 amount): Deposits ERC20, creates an Inactive vault (requires prior approval).
// 4.  setupSuperposition(uint256 vaultId, Outcome[] memory outcomes, CollapseMechanism mechanism, bytes32 collapseTriggerData): Configures and transitions an Inactive vault to Superposition.
// 5.  cancelVaultSetup(uint256 vaultId): Cancels an Inactive vault and refunds assets.
// 6.  cancelSuperposition(uint256 vaultId): Attempts to cancel a Superposition vault and refunds assets (may have conditions).
// 7.  triggerCollapseManual(uint256 vaultId, uint256 chosenOutcomeIndex): Triggers collapse for Manual mechanism, selecting a specific outcome index.
// 8.  triggerCollapseBlockHash(uint256 vaultId): Triggers collapse for BlockHash mechanism if conditions met.
// 9.  triggerCollapseTimeBased(uint256 vaultId): Triggers collapse for TimeBased mechanism if conditions met.
// 10. triggerCollapseOracle(uint256 vaultId, bytes calldata oracleData): Placeholder for Oracle-triggered collapse.
// 11. executeOutcome(uint256 vaultId): Executes the determined outcome for a Collapsed vault.

// --- Configuration & Admin (Ownable/Access Controlled) ---
// 12. updateManualCollapseAuthorizer(address authorizer, bool authorized): Adds or removes an address as a manual collapse authorizer.
// 13. setDepositFee(uint16 feeBasisPoints): Sets the deposit fee percentage (in basis points).
// 14. setCollapseFee(uint16 feeBasisPoints): Sets the collapse fee percentage (in basis points).
// 15. withdrawFees(address token, uint256 amount): Allows owner to withdraw accumulated fees (ETH or specific ERC20).
// 16. pause(): Pauses sensitive contract operations.
// 17. unpause(): Unpauses the contract.
// 18. addSupportedERC20(IERC20 token): Adds an ERC20 token to the list of supported tokens.
// 19. removeSupportedERC20(IERC20 token): Removes an ERC20 token from the list (carefully).
// 20. setOracleAddress(address oracle): Sets the address for the Oracle collapse mechanism.

// --- View Functions (Public) ---
// 21. getVaultInfo(uint256 vaultId): Returns detailed information about a vault.
// 22. getPotentialOutcomes(uint256 vaultId): Returns the potential outcomes defined for a vault.
// 23. getVaultState(uint256 vaultId): Returns the current state of a vault.
// 24. getVaultOwner(uint256 vaultId): Returns the owner of a vault.
// 25. getUserVaultIds(address user): Returns the list of vault IDs owned by a user.
// 26. getDepositFee(): Returns the current deposit fee.
// 27. getCollapseFee(): Returns the current collapse fee.
// 28. isManualCollapseAuthorizer(address authorizer): Checks if an address is authorized for manual collapse.
// 29. getOracleAddress(): Returns the configured oracle address.
// 30. isSupportedERC20(IERC20 token): Checks if an ERC20 token is supported.
// 31. getTotalFeesCollected(address token): Returns the total fees collected for a specific token (0x0 for ETH).
// 32. getNextVaultId(): Returns the next available vault ID.

contract QuantumFluxVault is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Definitions ---
    enum VaultState {
        Inactive, // Vault created, assets deposited, but superposition not configured yet.
        Superposition, // Assets locked, potential outcomes defined, awaiting collapse.
        Collapsed, // Superposition resolved, outcome chosen, awaiting execution.
        Completed, // Outcome executed, vault lifecycle finished.
        Cancelled // Vault cancelled before collapse, assets refunded.
    }

    enum OutcomeType {
        WithdrawToOwner, // Assets returned to the vault owner.
        SendToAddress, // Assets sent to a specified address.
        Burn, // Assets are destroyed.
        SendToContract // Assets sent to a specified contract address (e.g., for interaction).
    }

    struct Outcome {
        OutcomeType outcomeType;
        address targetAddress; // Used for SendToAddress and SendToContract
    }

    enum CollapseMechanism {
        Manual, // Triggered by an authorized address.
        BlockHash, // Triggered based on block hash properties.
        TimeBased, // Triggered based on timestamp.
        Oracle // (Placeholder) Triggered by external oracle data.
    }

    struct Vault {
        uint256 id;
        address owner; // The original depositor or current owner.
        address assetAddress; // Address of the ERC20 token (0x0 for ETH).
        uint256 amount; // Original deposited amount.
        VaultState currentState;
        Outcome[] potentialOutcomes; // The possible states/outcomes of the superposition.
        int256 chosenOutcomeIndex; // -1 before collapse, index >= 0 after collapse.
        CollapseMechanism collapseMechanism;
        bytes32 collapseTriggerData; // Data relevant to the collapse mechanism (e.g., block number, timestamp, oracle ID).
        uint256 depositTime;
        uint256 collapseTime; // Timestamp when collapse occurred (0 before collapse).
    }

    // --- State Variables ---
    uint256 private _nextVaultId;
    mapping(uint256 => Vault) private _vaults;
    mapping(address => uint256[]) private _ownerToVaultIds;
    mapping(address => bool) private _manualCollapseAuthorizers;
    mapping(address => bool) private _supportedERC20s;
    uint16 private _depositFeeBasisPoints; // Fee applied on deposit, in basis points (e.g., 100 = 1%)
    uint16 private _collapseFeeBasisPoints; // Fee applied on collapse, in basis points.
    mapping(address => uint256) private _totalFeesCollected; // 0x0 address for ETH fees.
    address private _oracleAddress; // Address of the trusted oracle contract/EOA.

    // --- Events ---
    event VaultCreated(uint256 indexed vaultId, address indexed owner, address indexed assetAddress, uint256 amount, VaultState initialState);
    event SuperpositionSetup(uint256 indexed vaultId, CollapseMechanism mechanism, bytes32 triggerData);
    event VaultCancelled(uint256 indexed vaultId, VaultState stateBeforeCancel);
    event CollapseTriggered(uint256 indexed vaultId, CollapseMechanism mechanism, uint256 chosenOutcomeIndex, uint256 collapseTime);
    event OutcomeExecuted(uint256 indexed vaultId, OutcomeType outcomeType, address targetAddress, uint256 executedAmount);
    event FeeCollected(address indexed token, uint256 amount, string feeType);
    event AuthorizerUpdated(address indexed authorizer, bool authorized);
    event SupportedERC20Updated(address indexed token, bool supported);
    event OracleAddressUpdated(address indexed oracleAddress);
    event VaultOwnershipTransferred(uint256 indexed vaultId, address indexed oldOwner, address indexed newOwner);

    // --- Errors (Solidity 0.8+) ---
    error InvalidVaultId();
    error NotVaultOwner();
    error VaultNotInState(VaultState expectedState);
    error VaultNotReadyForState(VaultState targetState);
    error InvalidOutcomeIndex();
    error InvalidOutcomeDefinition();
    error InvalidCollapseMechanism();
    error NotManualCollapseAuthorizer();
    error CollapseTriggerConditionNotMet();
    error OracleNotConfigured();
    error ExecutionFailed(address target);
    error AmountExceedsVaultBalance(); // Should not happen if state transitions are correct, but good guard.
    error ZeroAddressTarget();
    error ERC20NotSupported();
    error OutcomeNotChosen();
    error FeePercentageTooHigh(uint16 maxBasisPoints);

    // --- Constants ---
    uint16 constant private MAX_FEE_BASIS_POINTS = 1000; // 10% max fee

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {
        _nextVaultId = 1;
        // Default fees or set later by owner
        _depositFeeBasisPoints = 0;
        _collapseFeeBasisPoints = 0;
        // Owner is by default a manual authorizer
        _manualCollapseAuthorizers[_owner] = true;
    }

    // --- Modifiers ---
    modifier onlyVaultOwner(uint256 vaultId) {
        if (_vaults[vaultId].owner != msg.sender) revert NotVaultOwner();
        _;
    }

    modifier whenVaultIsInState(uint256 vaultId, VaultState expectedState) {
        if (_vaults[vaultId].currentState != expectedState) revert VaultNotInState(expectedState);
        _;
    }

    // --- Core Vault Lifecycle Functions ---

    /**
     * @notice Deposits ETH and creates a new vault in the Inactive state.
     */
    receive() external payable {
        if (msg.data.length > 0) {
            revert("Cannot send ETH with data without calling a function");
        }
        // Allow bare ETH sends to create vaults, but use depositETH for explicit creation
        // Or, strictly require calling depositETH. Let's require depositETH for clarity.
        revert("Call depositETH to create a vault with ETH");
    }

    /**
     * @notice Deposits ETH and creates a new vault in the Inactive state.
     */
    function depositETH() external payable whenNotPaused returns (uint256 vaultId) {
        uint256 grossAmount = msg.value;
        if (grossAmount == 0) revert("Cannot deposit zero amount");

        uint256 fee = grossAmount.mul(_depositFeeBasisPoints).div(10000);
        uint256 netAmount = grossAmount.sub(fee);

        if (fee > 0) {
            _totalFeesCollected[address(0)] = _totalFeesCollected[address(0)].add(fee);
            emit FeeCollected(address(0), fee, "Deposit");
        }

        vaultId = _nextVaultId++;
        _vaults[vaultId] = Vault({
            id: vaultId,
            owner: msg.sender,
            assetAddress: address(0), // 0x0 for ETH
            amount: netAmount, // Store net amount in the vault
            currentState: VaultState.Inactive,
            potentialOutcomes: new Outcome[](0), // Empty initially
            chosenOutcomeIndex: -1,
            collapseMechanism: CollapseMechanism.Manual, // Default, must be set in setup
            collapseTriggerData: "",
            depositTime: block.timestamp,
            collapseTime: 0
        });
        _ownerToVaultIds[msg.sender].push(vaultId);

        emit VaultCreated(vaultId, msg.sender, address(0), netAmount, VaultState.Inactive);
    }

    /**
     * @notice Deposits ERC20 tokens and creates a new vault in the Inactive state. Requires prior approval.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(IERC20 token, uint256 amount) external whenNotPaused returns (uint256 vaultId) {
        if (!_supportedERC20s[address(token)]) revert ERC20NotSupported();
        if (amount == 0) revert("Cannot deposit zero amount");

        uint256 fee = amount.mul(_depositFeeBasisPoints).div(10000);
        uint256 netAmount = amount.sub(fee);

        // Transfer tokens to the contract
        token.safeTransferFrom(msg.sender, address(this), amount);

        if (fee > 0) {
            _totalFeesCollected[address(token)] = _totalFeesCollected[address(token)].add(fee);
            emit FeeCollected(address(token), fee, "Deposit");
        }

        vaultId = _nextVaultId++;
        _vaults[vaultId] = Vault({
            id: vaultId,
            owner: msg.sender,
            assetAddress: address(token),
            amount: netAmount, // Store net amount
            currentState: VaultState.Inactive,
            potentialOutcomes: new Outcome[](0),
            chosenOutcomeIndex: -1,
            collapseMechanism: CollapseMechanism.Manual, // Default
            collapseTriggerData: "",
            depositTime: block.timestamp,
            collapseTime: 0
        });
        _ownerToVaultIds[msg.sender].push(vaultId);

        emit VaultCreated(vaultId, msg.sender, address(token), netAmount, VaultState.Inactive);
    }

    /**
     * @notice Configures potential outcomes and collapse mechanism, moving the vault to Superposition.
     * @param vaultId The ID of the vault.
     * @param outcomes An array of potential outcomes. Max 10 outcomes allowed.
     * @param mechanism The mechanism to trigger collapse.
     * @param collapseTriggerData Data relevant to the mechanism (e.g., block number, timestamp).
     */
    function setupSuperposition(
        uint256 vaultId,
        Outcome[] memory outcomes,
        CollapseMechanism mechanism,
        bytes32 collapseTriggerData
    ) external onlyVaultOwner(vaultId) whenVaultIsInState(vaultId, VaultState.Inactive) whenNotPaused {
        Vault storage vault = _vaults[vaultId];

        if (outcomes.length == 0 || outcomes.length > 10) revert InvalidOutcomeDefinition();

        // Basic validation for outcome definitions
        for (uint i = 0; i < outcomes.length; i++) {
            if (outcomes[i].outcomeType == OutcomeType.SendToAddress && !outcomes[i].targetAddress.isᎬOA()) revert InvalidOutcomeDefinition();
            if (outcomes[i].outcomeType == OutcomeType.SendToContract && !outcomes[i].targetAddress.isContract()) revert InvalidOutcomeDefinition();
            if (outcomes[i].outcomeType != OutcomeType.Burn && outcomes[i].targetAddress == address(0)) revert ZeroAddressTarget();
        }

        vault.potentialOutcomes = outcomes;
        vault.collapseMechanism = mechanism;
        vault.collapseTriggerData = collapseTriggerData; // Interpretation depends on mechanism

        vault.currentState = VaultState.Superposition;
        emit SuperpositionSetup(vaultId, mechanism, collapseTriggerData);
    }

    /**
     * @notice Cancels a vault that is still in the Inactive state, refunding assets.
     * @param vaultId The ID of the vault.
     */
    function cancelVaultSetup(uint256 vaultId) external onlyVaultOwner(vaultId) whenVaultIsInState(vaultId, VaultState.Inactive) {
        Vault storage vault = _vaults[vaultId];
        VaultState stateBefore = vault.currentState;

        // Refund assets
        if (vault.assetAddress == address(0)) {
            // ETH
            (bool success, ) = payable(vault.owner).call{value: vault.amount}("");
            if (!success) revert ExecutionFailed(vault.owner);
        } else {
            // ERC20
            IERC20 token = IERC20(vault.assetAddress);
            token.safeTransfer(vault.owner, vault.amount);
        }

        vault.currentState = VaultState.Cancelled;
        // Note: Vault struct remains, marked as Cancelled. Cannot be reused.
        emit VaultCancelled(vaultId, stateBefore);
    }

    /**
     * @notice Attempts to cancel a vault that is in the Superposition state.
     *         This function can have conditions (e.g., only if no collapse trigger data set).
     *         Let's implement a simple condition: only if collapseTriggerData is still default (0x0).
     * @param vaultId The ID of the vault.
     */
    function cancelSuperposition(uint256 vaultId) external onlyVaultOwner(vaultId) whenVaultIsInState(vaultId, VaultState.Superposition) {
        Vault storage vault = _vaults[vaultId];

        // Example condition: Allow cancel only if the collapse mechanism hasn't been "armed" yet.
        // This is a design choice. Could also be time-limited, require multi-sig, etc.
        // Here, we use a simple check on collapseTriggerData existence.
        if (vault.collapseTriggerData != bytes32(0)) {
            // If trigger data is set, it's considered "armed", cancellation is no longer possible.
            revert("Superposition is armed, cannot cancel");
        }
        
        VaultState stateBefore = vault.currentState;

        // Refund assets
        if (vault.assetAddress == address(0)) {
            // ETH
            (bool success, ) = payable(vault.owner).call{value: vault.amount}("");
            if (!success) revert ExecutionFailed(vault.owner);
        } else {
            // ERC20
            IERC20 token = IERC20(vault.assetAddress);
            token.safeTransfer(vault.owner, vault.amount);
        }

        vault.currentState = VaultState.Cancelled;
        emit VaultCancelled(vaultId, stateBefore);
    }


    /**
     * @notice Triggers the collapse for a vault with the Manual mechanism.
     * @param vaultId The ID of the vault.
     * @param chosenOutcomeIndex The index of the outcome to choose from the potential outcomes array.
     */
    function triggerCollapseManual(uint256 vaultId, uint256 chosenOutcomeIndex) external whenNotPaused {
        if (!_manualCollapseAuthorizers[msg.sender]) revert NotManualCollapseAuthorizer();

        Vault storage vault = _vaults[vaultId];
        if (vault.currentState != VaultState.Superposition) revert VaultNotInState(VaultState.Superposition);
        if (vault.collapseMechanism != CollapseMechanism.Manual) revert InvalidCollapseMechanism();

        if (chosenOutcomeIndex >= vault.potentialOutcomes.length) revert InvalidOutcomeIndex();

        _processCollapse(vault, chosenOutcomeIndex);
    }

    /**
     * @notice Triggers the collapse for a vault with the BlockHash mechanism if the trigger block is reached.
     * @param vaultId The ID of the vault.
     */
    function triggerCollapseBlockHash(uint256 vaultId) external whenNotPaused {
        Vault storage vault = _vaults[vaultId];
        if (vault.currentState != VaultState.Superposition) revert VaultNotInState(VaultState.Superposition);
        if (vault.collapseMechanism != CollapseMechanism.BlockHash) revert InvalidCollapseMechanism();

        uint256 triggerBlock = uint256(vault.collapseTriggerData);
        // blockhash(n) only works for the last 256 blocks.
        // Ensure triggerBlock is within the valid range (current - 256 to current - 1)
        if (block.number <= triggerBlock || block.number > triggerBlock + 256) {
            revert CollapseTriggerConditionNotMet();
        }

        // Use blockhash as pseudo-randomness source
        bytes32 randomHash = blockhash(triggerBlock);
        if (randomHash == bytes32(0)) {
            // Should not happen if block.number > triggerBlock, but check defensive
             revert("Block hash not available");
        }

        // Deterministically choose an outcome based on the block hash and vault data
        uint256 chosenOutcomeIndex = uint256(keccak256(abi.encodePacked(randomHash, vaultId, block.number))) % vault.potentialOutcomes.length;

        _processCollapse(vault, chosenOutcomeIndex);
    }

    /**
     * @notice Triggers the collapse for a vault with the TimeBased mechanism if the trigger time is reached.
     * @param vaultId The ID of the vault.
     */
    function triggerCollapseTimeBased(uint256 vaultId) external whenNotPaused {
         Vault storage vault = _vaults[vaultId];
        if (vault.currentState != VaultState.Superposition) revert VaultNotInState(VaultState.Superposition);
        if (vault.collapseMechanism != CollapseMechanism.TimeBased) revert InvalidCollapseMechanism();

        uint256 triggerTime = uint256(vault.collapseTriggerData);
        if (block.timestamp < triggerTime) {
            revert CollapseTriggerConditionNotMet();
        }

        // Deterministically choose an outcome based on time and vault data
        // Using block.timestamp and block.number for pseudo-randomness within the collapse transaction context
        uint256 chosenOutcomeIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, vaultId))) % vault.potentialOutcomes.length;

        _processCollapse(vault, chosenOutcomeIndex);
    }

    /**
     * @notice Placeholder for triggering collapse via an Oracle mechanism.
     *         This function would typically be called by a trusted oracle address,
     *         and the oracleData would be used to determine the outcome.
     *         Implementation details would depend heavily on the oracle system used.
     * @param vaultId The ID of the vault.
     * @param oracleData Data provided by the oracle to help determine the outcome.
     */
    function triggerCollapseOracle(uint256 vaultId, bytes calldata oracleData) external whenNotPaused {
         Vault storage vault = _vaults[vaultId];
        if (vault.currentState != VaultState.Superposition) revert VaultNotInState(VaultState.Superposition);
        if (vault.collapseMechanism != CollapseMechanism.Oracle) revert InvalidCollapseMechanism();
        if (msg.sender != _oracleAddress || _oracleAddress == address(0)) revert OracleNotConfigured();

        // --- Oracle-based outcome selection logic goes here ---
        // This is a placeholder. Real implementation would parse oracleData
        // and map it deterministically to an outcome index.
        // Example: Use a hash of oracleData and vaultId
        uint224 pseudoRandomFromOracle = uint224(keccak256(abi.encodePacked(oracleData, vaultId)));
        uint256 chosenOutcomeIndex = pseudoRandomFromOracle % vault.potentialOutcomes.length;
        // --- End Oracle logic placeholder ---


        _processCollapse(vault, chosenOutcomeIndex);
    }


    /**
     * @notice Internal helper to handle the common logic of processing collapse.
     * @param vault The storage pointer to the vault.
     * @param chosenOutcomeIndex The index of the chosen outcome.
     */
    function _processCollapse(Vault storage vault, uint256 chosenOutcomeIndex) internal {
         if (chosenOutcomeIndex >= vault.potentialOutcomes.length) revert InvalidOutcomeIndex(); // Double check

        uint256 fee = vault.amount.mul(_collapseFeeBasisPoints).div(10000);
        uint256 amountAfterFee = vault.amount.sub(fee);

        vault.amount = amountAfterFee; // Update vault amount after fee deduction

         if (fee > 0) {
            _totalFeesCollected[vault.assetAddress] = _totalFeesCollected[vault.assetAddress].add(fee);
            emit FeeCollected(vault.assetAddress, fee, "Collapse");
        }

        vault.chosenOutcomeIndex = int256(chosenOutcomeIndex);
        vault.collapseTime = block.timestamp;
        vault.currentState = VaultState.Collapsed;

        emit CollapseTriggered(vault.id, vault.collapseMechanism, uint256(vault.chosenOutcomeIndex), vault.collapseTime);
    }

    /**
     * @notice Executes the determined outcome for a collapsed vault. Callable by anyone.
     * @param vaultId The ID of the vault.
     */
    function executeOutcome(uint256 vaultId) external whenNotPaused {
        Vault storage vault = _vaults[vaultId];
        if (vault.currentState != VaultState.Collapsed) revert VaultNotInState(VaultState.Collapsed);
        if (vault.chosenOutcomeIndex < 0) revert OutcomeNotChosen(); // Should not happen if state is Collapsed

        Outcome memory chosenOutcome = vault.potentialOutcomes[uint256(vault.chosenOutcomeIndex)];
        uint256 amountToExecute = vault.amount;
        address assetAddr = vault.assetAddress;
        VaultState stateBefore = vault.currentState;

        // Clear potential outcomes to save gas/storage after selection (optional, but good practice)
        // vault.potentialOutcomes = new Outcome[](0); // This changes storage

        if (assetAddr == address(0)) {
            // Handle ETH
            if (chosenOutcome.outcomeType == OutcomeType.WithdrawToOwner) {
                (bool success, ) = payable(vault.owner).call{value: amountToExecute}("");
                 if (!success) revert ExecutionFailed(vault.owner);
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, vault.owner, amountToExecute);

            } else if (chosenOutcome.outcomeType == OutcomeType.SendToAddress) {
                 if (chosenOutcome.targetAddress == address(0)) revert ZeroAddressTarget(); // Defensive
                (bool success, ) = payable(chosenOutcome.targetAddress).call{value: amountToExecute}("");
                 if (!success) revert ExecutionFailed(chosenOutcome.targetAddress);
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, chosenOutcome.targetAddress, amountToExecute);

            } else if (chosenOutcome.outcomeType == OutcomeType.Burn) {
                // Burning ETH means sending it to the zero address.
                // This is effectively transferring it out of the contract without anyone receiving it.
                // The call to address(0) is generally unsafe/reserved,
                // so we'll just mark it as burned internally and the ETH stays in the contract fees or gets stuck.
                // A safer "burn" mechanism for ETH might be to send to a documented burn address like 0x...dead
                 address burnAddress = 0x000000000000000000000000000000000000dEaD; // Common burn address
                 (bool success, ) = payable(burnAddress).call{value: amountToExecute}("");
                 if (!success) revert ExecutionFailed(burnAddress); // Or decide if failed burn should revert or just log
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, burnAddress, amountToExecute);

            } else if (chosenOutcome.outcomeType == OutcomeType.SendToContract) {
                 if (chosenOutcome.targetAddress == address(0) || !chosenOutcome.targetAddress.isContract()) revert InvalidOutcomeDefinition(); // Defensive
                 (bool success, ) = chosenOutcome.targetAddress.call{value: amountToExecute}("");
                 if (!success) revert ExecutionFailed(chosenOutcome.targetAddress);
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, chosenOutcome.targetAddress, amountToExecute);
            }

        } else {
            // Handle ERC20
            IERC20 token = IERC20(assetAddr);
             if (chosenOutcome.outcomeType == OutcomeType.WithdrawToOwner) {
                token.safeTransfer(vault.owner, amountToExecute);
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, vault.owner, amountToExecute);

            } else if (chosenOutcome.outcomeType == OutcomeType.SendToAddress) {
                 if (chosenOutcome.targetAddress == address(0)) revert ZeroAddressTarget(); // Defensive
                 token.safeTransfer(chosenOutcome.targetAddress, amountToExecute);
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, chosenOutcome.targetAddress, amountToExecute);

            } else if (chosenOutcome.outcomeType == OutcomeType.Burn) {
                 // Burning ERC20 typically means sending to 0x...dead or relying on token's burn function if available
                 // Standard ERC20 doesn't have burn. Sending to 0x...dead is common practice.
                 address burnAddress = 0x000000000000000000000000000000000000dEaD; // Common burn address
                 token.safeTransfer(burnAddress, amountToExecute);
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, burnAddress, amountToExecute);

            } else if (chosenOutcome.outcomeType == OutcomeType.SendToContract) {
                 if (chosenOutcome.targetAddress == address(0) || !chosenOutcome.targetAddress.isContract()) revert InvalidOutcomeDefinition(); // Defensive
                 token.safeTransfer(chosenOutcome.targetAddress, amountToExecute);
                 emit OutcomeExecuted(vaultId, chosenOutcome.outcomeType, chosenOutcome.targetAddress, amountToExecute);
            }
        }

        vault.amount = 0; // Set amount to zero after execution
        vault.currentState = VaultState.Completed;
    }

    // --- Configuration & Admin Functions ---

    /**
     * @notice Adds or removes an address from the list of authorized manual collapse authorizers.
     * @param authorizer The address to update.
     * @param authorized True to authorize, false to deauthorize.
     */
    function updateManualCollapseAuthorizer(address authorizer, bool authorized) external onlyOwner {
        _manualCollapseAuthorizers[authorizer] = authorized;
        emit AuthorizerUpdated(authorizer, authorized);
    }

    /**
     * @notice Sets the fee percentage for deposits.
     * @param feeBasisPoints Fee in basis points (1/100 of a percent). Max 1000 (10%).
     */
    function setDepositFee(uint16 feeBasisPoints) external onlyOwner {
        if (feeBasisPoints > MAX_FEE_BASIS_POINTS) revert FeePercentageTooHigh(MAX_FEE_BASIS_POINTS);
        _depositFeeBasisPoints = feeBasisPoints;
    }

    /**
     * @notice Sets the fee percentage for collapse.
     * @param feeBasisPoints Fee in basis points (1/100 of a percent). Max 1000 (10%).
     */
    function setCollapseFee(uint16 feeBasisPoints) external onlyOwner {
        if (feeBasisPoints > MAX_FEE_BASIS_POINTS) revert FeePercentageTooHigh(MAX_FEE_BASIS_POINTS);
        _collapseFeeBasisPoints = feeBasisPoints;
    }

    /**
     * @notice Allows the owner to withdraw accumulated fees for a specific token or ETH (address(0)).
     * @param token The address of the token (0x0 for ETH).
     * @param amount The amount of fees to withdraw.
     */
    function withdrawFees(address token, uint256 amount) external onlyOwner {
        if (amount == 0) revert("Cannot withdraw zero");
        if (_totalFeesCollected[token] < amount) revert("Insufficient fees collected");

        _totalFeesCollected[token] = _totalFeesCollected[token].sub(amount);

        if (token == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(owner()).call{value: amount}("");
            if (!success) revert ExecutionFailed(owner());
        } else {
            // Withdraw ERC20
            IERC20 erc20Token = IERC20(token);
            erc20Token.safeTransfer(owner(), amount);
        }
    }

    /**
     * @notice Pauses the contract, preventing sensitive operations like deposits, setups, and collapses.
     *         Execution of already collapsed vaults might still be allowed depending on design.
     *         Let's make executeOutcome also pausable for simplicity and safety.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Adds an ERC20 token to the list of supported tokens for deposit.
     * @param token The address of the ERC20 token.
     */
    function addSupportedERC20(IERC20 token) external onlyOwner {
        _supportedERC20s[address(token)] = true;
        emit SupportedERC20Updated(address(token), true);
    }

    /**
     * @notice Removes an ERC20 token from the list of supported tokens.
     *         Existing vaults with this token are unaffected, but new deposits are prevented.
     * @param token The address of the ERC20 token.
     */
    function removeSupportedERC20(IERC20 token) external onlyOwner {
        _supportedERC20s[address(token)] = false;
        emit SupportedERC20Updated(address(token), false);
    }

    /**
     * @notice Sets the address of the trusted oracle for the Oracle collapse mechanism.
     * @param oracle The address of the oracle.
     */
    function setOracleAddress(address oracle) external onlyOwner {
        _oracleAddress = oracle;
        emit OracleAddressUpdated(oracle);
    }

    /**
     * @notice Allows the owner of an Inactive or Superposition vault to transfer ownership.
     * @param vaultId The ID of the vault.
     * @param newOwner The address of the new owner.
     */
    function transferVaultOwnership(uint256 vaultId, address newOwner) external onlyVaultOwner(vaultId) {
        Vault storage vault = _vaults[vaultId];
        // Only allow transfer in states where the vault is not yet Collapsed or Completed
        if (vault.currentState == VaultState.Collapsed || vault.currentState == VaultState.Completed || vault.currentState == VaultState.Cancelled) {
             revert VaultNotReadyForState(VaultState.Inactive); // Using Inactive state error as a proxy for "transfer not allowed now"
        }
        if (newOwner == address(0)) revert ZeroAddressTarget();

        address oldOwner = vault.owner;
        vault.owner = newOwner;

        // Update ownerToVaultIds mappings (more complex, requires removing from old array and adding to new)
        // For simplicity in this example, we won't update the _ownerToVaultIds mapping.
        // A production system would need to handle this by finding and removing the ID from the old owner's array.
        // For now, getUserVaultIds might show vault under old owner if transferred.
        // Correct approach requires iteration or a different data structure. Let's add a simplified version.
        // Find and remove vaultId from old owner's array.
        uint256[] storage oldOwnerVaults = _ownerToVaultIds[oldOwner];
        for(uint i = 0; i < oldOwnerVaults.length; i++) {
            if (oldOwnerVaults[i] == vaultId) {
                // Swap with last element and pop to remove without gaps
                oldOwnerVaults[i] = oldOwnerVaults[oldOwnerVaults.length - 1];
                oldOwnerVaults.pop();
                break; // Assume vaultId is unique per owner list (should be)
            }
        }
        // Add to new owner's array
        _ownerToVaultIds[newOwner].push(vaultId);


        emit VaultOwnershipTransferred(vaultId, oldOwner, newOwner);
    }


    // --- View Functions ---

    /**
     * @notice Gets detailed information about a vault.
     * @param vaultId The ID of the vault.
     * @return Vault struct details. Note: potentialOutcomes array is large, separate view function recommended.
     */
    function getVaultInfo(uint256 vaultId) external view returns (
        uint256 id,
        address owner,
        address assetAddress,
        uint256 amount,
        VaultState currentState,
        int256 chosenOutcomeIndex,
        CollapseMechanism collapseMechanism,
        bytes32 collapseTriggerData,
        uint256 depositTime,
        uint256 collapseTime
    ) {
        Vault storage vault = _vaults[vaultId];
        if (vault.id == 0 && vaultId != 0) revert InvalidVaultId(); // Check for uninitialized vault

        return (
            vault.id,
            vault.owner,
            vault.assetAddress,
            vault.amount,
            vault.currentState,
            vault.chosenOutcomeIndex,
            vault.collapseMechanism,
            vault.collapseTriggerData,
            vault.depositTime,
            vault.collapseTime
        );
    }

    /**
     * @notice Gets the potential outcomes defined for a vault. Separate from getVaultInfo to avoid large return data.
     * @param vaultId The ID of the vault.
     * @return An array of Outcome structs.
     */
    function getPotentialOutcomes(uint256 vaultId) external view returns (Outcome[] memory) {
         Vault storage vault = _vaults[vaultId];
        if (vault.id == 0 && vaultId != 0) revert InvalidVaultId();
        return vault.potentialOutcomes;
    }


    /**
     * @notice Gets the current state of a vault.
     * @param vaultId The ID of the vault.
     * @return The VaultState enum value.
     */
    function getVaultState(uint256 vaultId) external view returns (VaultState) {
        Vault storage vault = _vaults[vaultId];
        if (vault.id == 0 && vaultId != 0) revert InvalidVaultId();
        return vault.currentState;
    }

     /**
     * @notice Gets the owner address of a vault.
     * @param vaultId The ID of the vault.
     * @return The owner address.
     */
    function getVaultOwner(uint256 vaultId) external view returns (address) {
        Vault storage vault = _vaults[vaultId];
        if (vault.id == 0 && vaultId != 0) revert InvalidVaultId();
        return vault.owner;
    }


    /**
     * @notice Gets the list of vault IDs owned by a specific user.
     * @param user The address of the user.
     * @return An array of vault IDs.
     */
    function getUserVaultIds(address user) external view returns (uint256[] memory) {
        return _ownerToVaultIds[user];
    }

    /**
     * @notice Gets the current deposit fee percentage.
     * @return Fee in basis points.
     */
    function getDepositFee() external view returns (uint16) {
        return _depositFeeBasisPoints;
    }

    /**
     * @notice Gets the current collapse fee percentage.
     * @return Fee in basis points.
     */
    function getCollapseFee() external view returns (uint16) {
        return _collapseFeeBasisPoints;
    }

    /**
     * @notice Checks if an address is authorized for manual collapse.
     * @param authorizer The address to check.
     * @return True if authorized, false otherwise.
     */
    function isManualCollapseAuthorizer(address authorizer) external view returns (bool) {
        return _manualCollapseAuthorizers[authorizer];
    }

    /**
     * @notice Gets the configured oracle address.
     * @return The oracle address.
     */
    function getOracleAddress() external view returns (address) {
        return _oracleAddress;
    }

    /**
     * @notice Checks if an ERC20 token is supported for deposit.
     * @param token The address of the ERC20 token.
     * @return True if supported, false otherwise.
     */
    function isSupportedERC20(IERC20 token) external view returns (bool) {
        return _supportedERC20s[address(token)];
    }

    /**
     * @notice Gets the total accumulated fees for a specific token or ETH (address(0)).
     * @param token The address of the token (0x0 for ETH).
     * @return The total collected fee amount.
     */
    function getTotalFeesCollected(address token) external view returns (uint256) {
        return _totalFeesCollected[token];
    }

    /**
     * @notice Gets the ID that will be assigned to the next new vault.
     * @return The next available vault ID.
     */
    function getNextVaultId() external view returns (uint256) {
        return _nextVaultId;
    }

    // Fallback function to prevent accidental ETH sends without calling depositETH
    fallback() external payable {
        revert("Cannot send bare ETH, use depositETH");
    }
}
```