Okay, let's design a smart contract that acts as a "Quantum Vault". The "Quantum" aspect is purely metaphorical, inspired by the idea that the state of assets (accessible or locked) depends on the "observation" or fulfillment of multiple, potentially complex, and time-sensitive conditions – the "Observation Gates".

This contract will allow users to deposit ETH, ERC20, and ERC721 tokens under custom, programmable conditions defined by these "Observation Gates".

**Concept:**

*   **Quantum Vault:** A secure smart contract holding various assets.
*   **Observation Gates:** Customizable, on-chain logic defining when assets become available for withdrawal. These gates can combine multiple condition types (time, multi-signature approvals, interaction triggers, potentially external data via trusted oracle patterns - though direct oracle calls are simplified for this example).
*   **State-Dependent Release:** Funds are locked until the associated Observation Gate's conditions are met (`checkGateStatus`).
*   **Programmable Conditions:** Users can define their own complex gates (within the contract's supported parameters).

---

**QuantumVault Smart Contract Outline:**

1.  **License and Version Pragma**
2.  **Imports:** IERC20, IERC721, ReentrancyGuard (optional but good practice).
3.  **Errors:** Custom errors for clarity.
4.  **Enums:** `AssetType` (ETH, ERC20, ERC721).
5.  **Structs:**
    *   `ObservationGateConfig`: Defines the parameters for a gate (timestamps, required approvals, flags for condition types, linked data/hashes).
    *   `ObservationGateState`: Tracks the current state of a gate (e.g., multi-sig approvals received, condition signaled).
    *   `Deposit`: Tracks deposited assets (amount/token IDs, asset type, token address, linked gate ID).
6.  **State Variables:**
    *   Owner/Admin addresses.
    *   Counters for unique Gate IDs.
    *   Mappings for `gateId => ObservationGateConfig`.
    *   Mappings for `gateId => ObservationGateState`.
    *   Mappings for `depositorAddress => gateId => assetType => tokenAddress => Deposit`. (Complex structure to track deposits per user, per gate, per asset type).
    *   Protocol fee configuration.
    *   Collected fees.
    *   Mapping to track if a gate ID exists.
    *   Mapping to track if a gate is deactivated.
7.  **Events:** For important actions (Gate Created, Deposit, Withdrawal, Gate State Updated, Fees Collected, etc.).
8.  **Modifiers:** `onlyOwner`, `whenGateActive`.
9.  **Constructor:** Sets initial owner.
10. **Core Logic Functions:**
    *   Gate Creation & Management.
    *   Deposit Functions (ETH, ERC20, ERC721).
    *   Withdrawal Functions (ETH, ERC20, ERC721).
    *   Gate State Interaction Functions (e.g., signaling conditions, approvals).
    *   Condition Checking Function (`checkGateStatus`).
11. **Admin & Protocol Functions:**
    *   Ownership Transfer.
    *   Fee Management.
    *   Emergency/Shutdown.
12. **View Functions:** To query contract state (gate details, deposit details, status checks).
13. **ERC721 Receiver Hook:** `onERC721Received` for safe transfers.

---

**Function Summary (Min 20 Functions):**

1.  `constructor()`: Initializes the contract owner.
2.  `createObservationGate(ObservationGateConfig _config)`: Creates a new gate with specified conditions, returns a unique gate ID. Charges a fee.
3.  `updateGateConfiguration(uint256 _gateId, ObservationGateConfig _newConfig)`: Allows the gate creator (or owner?) to update gate parameters *before* any deposits or only certain parameters.
4.  `deactivateGate(uint256 _gateId)`: Marks a gate as inactive, preventing *new* deposits, but allowing withdrawals for existing ones if conditions met. Only creator or owner.
5.  `checkGateStatus(uint256 _gateId)`: Pure view function returning `true` if all conditions for the gate are currently met, `false` otherwise.
6.  `signalGateConditionMet(uint256 _gateId, bytes32 _signalData)`: A function for external entities or logic to signal a specific condition is met (e.g., providing a hash preimage, proof of an event). Updates gate state. Requires specific gate config.
7.  `approveMultiSigGate(uint256 _gateId)`: For gates requiring multi-party approval, a designated address can signal their approval. Updates gate state.
8.  `depositETHWithGate(uint256 _gateId) payable`: Deposits ETH linked to a specific gate ID.
9.  `depositERC20WithGate(uint256 _gateId, address _token, uint256 _amount)`: Deposits ERC20 tokens linked to a specific gate ID (requires prior approval).
10. `depositERC721WithGate(uint256 _gateId, address _token, uint256[] _tokenIds)`: Deposits ERC721 tokens linked to a specific gate ID (requires prior approval/transfer from).
11. `withdrawETHViaGate(uint256 _gateId)`: Attempts to withdraw ETH deposited by the caller under this gate ID. Fails if `checkGateStatus` is false.
12. `withdrawERC20ViaGate(uint256 _gateId, address _token)`: Attempts to withdraw ERC20 tokens deposited by the caller under this gate ID. Fails if `checkGateStatus` is false.
13. `withdrawERC721ViaGate(uint256 _gateId, address _token, uint256[] _tokenIds)`: Attempts to withdraw *specified* ERC721 tokens deposited by the caller under this gate ID. Fails if `checkGateStatus` is false or if specific token IDs weren't part of the deposit record. (Alternative: withdraw *all* ERC721s for that user/gate/token). Let's allow specifying IDs for flexibility.
14. `transferOwnership(address _newOwner)`: Transfers contract ownership.
15. `setFeeParameters(uint256 _gateCreationFee, address _feeReceiver)`: Sets the fee for creating gates and where fees go.
16. `collectProtocolFees()`: Owner collects accumulated protocol fees.
17. `emergencyShutdownAndWithdraw(address _token, uint256[] calldata _tokenIds, bool isERC721)`: Owner function to withdraw specific assets in an emergency (bypasses gates). Use with caution.
18. `onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)`: ERC721 receiver hook, necessary for safe transfers.
19. `getGateDetails(uint256 _gateId)`: View function to get configuration details of a gate.
20. `getGateState(uint256 _gateId)`: View function to get the current state variables of a gate.
21. `getDepositDetails(address _depositor, uint256 _gateId, AssetType _assetType, address _token)`: View function to get details of a specific deposit.
22. `canWithdraw(address _depositor, uint256 _gateId, AssetType _assetType, address _token, uint256[] memory _tokenIds)`: Helper view function checking if withdrawal is *possible* for a specific deposit (checks gate status + existence of deposit).
23. `getGateCreator(uint256 _gateId)`: View function to get the creator of a gate.
24. `isGateDeactivated(uint256 _gateId)`: View function checking if a gate is deactivated.
25. `getProtocolFeeParameters()`: View function getting current fee settings.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // Using Context for _msgSender()
import "@openzeppelin/contracts/utils/Counters.sol";


/**
 * @title QuantumVault
 * @dev A smart contract acting as a non-custodial, state-dependent asset vault.
 * Assets (ETH, ERC20, ERC721) are locked until specific, programmable "Observation Gates" are fulfilled.
 * Gates can combine multiple conditions like time-locks, multi-party approvals, or external signals.
 *
 * Key Concepts:
 * - Observation Gates: Define unlock conditions. Can be composed of multiple checks.
 * - State-Dependent Release: Withdrawal is only possible when the associated gate's checkGateStatus() returns true.
 * - Programmable Conditions: Users create gates by specifying parameters in a config struct.
 * - Multi-Asset Support: Handles ETH, ERC20, and ERC721 deposits/withdrawals.
 * - Protocol Fees: Configurable fee for creating gates.
 */

// --- Outline ---
// 1. License and Version Pragma
// 2. Imports (IERC20, IERC721, ERC721Holder, ReentrancyGuard, Ownable, Context, Counters)
// 3. Custom Errors
// 4. Enums (AssetType)
// 5. Structs (ObservationGateConfig, ObservationGateState, Deposit)
// 6. State Variables (owner, gate counter, mappings for gates, state, deposits, fees)
// 7. Events
// 8. Modifiers (none custom, using Ownable)
// 9. Constructor
// 10. Core Logic Functions
//    - Gate Creation & Management (createObservationGate, updateGateConfiguration, deactivateGate)
//    - Gate State Interaction (signalGateConditionMet, approveMultiSigGate)
//    - Deposit Functions (depositETHWithGate, depositERC20WithGate, depositERC721WithGate)
//    - Withdrawal Functions (withdrawETHViaGate, withdrawERC20ViaGate, withdrawERC721ViaGate)
//    - Condition Checking (checkGateStatus)
// 11. Admin & Protocol Functions (transferOwnership, setFeeParameters, collectProtocolFees, emergencyShutdownAndWithdraw)
// 12. View Functions (getGateDetails, getGateState, getDepositDetails, canWithdraw, getGateCreator, isGateDeactivated, getProtocolFeeParameters, getGateApprovedCount)
// 13. ERC721 Receiver Hook (onERC721Received)

contract QuantumVault is Ownable, ERC721Holder, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _gateIds;

    // --- Custom Errors ---
    error GateDoesNotExist(uint256 gateId);
    error GateAlreadyExists(uint256 gateId); // Should not happen with counter
    error GateNotActive(uint256 gateId);
    error ConditionsNotMet(uint256 gateId);
    error InsufficientAmount();
    error ZeroAddress();
    error DepositNotFound(address depositor, uint256 gateId, AssetType assetType, address token);
    error ERC721TokenNotFoundInDeposit(uint256 gateId, address token, uint256 tokenId);
    error InvalidAssetType();
    error UnauthorizedGateAction();
    error FeeCollectionFailed();
    error InvalidGateConfig();
    error OnlyGateCreatorOrOwner();
    error GateAlreadyDeactivated();
    error CannotSignalCondition(uint256 gateId, uint8 conditionType);
    error NotAuthorizedToApprove(uint256 gateId, address approver);
    error AlreadyApproved(uint256 gateId, address approver);


    // --- Enums ---
    enum AssetType { ETH, ERC20, ERC721 }

    // --- Structs ---

    /**
     * @dev Configuration for an Observation Gate. Defines the unlock conditions.
     * Multiple flags/parameters can be combined.
     */
    struct ObservationGateConfig {
        address creator;             // The address that created this gate
        uint64 creationTime;         // Timestamp when the gate was created
        uint64 startTime;            // Gate conditions can only start being met after this time
        uint64 endTime;              // Gate conditions must be met before this time (0 for no end)
        uint256 minAmount;           // Minimum total value/amount threshold (conceptually, could use oracle prices) - simple uint for now
        uint256 requiredApprovals;   // For multi-sig style gates
        address[] approvers;         // List of addresses required to approve for multi-sig gate type
        bytes32 requiredSignalHash;  // A hash preimage required to be signaled (e.g., hash of a secret)
        bool requiresTimeLock;       // Requires current time >= startTime AND (endTime == 0 || currentTime <= endTime)
        bool requiresMultiSig;       // Requires state.approvalsReceived >= requiredApprovals from approvers list
        bool requiresSignal;         // Requires state.signalReceived to be true and match state.signalDataHash
        bool requiresMinAmount;      // Requires total deposited amount >= minAmount (complex to track per gate, maybe just a config flag) - simplified notion
        bool isPublic;               // If true, anyone can use this gate for deposit, otherwise only creator/owner/whitelisted.
        bool isReusable;             // If true, gate can be checked multiple times for different withdrawals. If false, state resets or gate closes after first successful withdrawal? (Let's make it reusable by default unless specific state changes it).
    }

    /**
     * @dev State tracking for an Observation Gate. Updated as conditions are interacted with.
     */
    struct ObservationGateState {
        uint256 approvalsReceived;          // Current count of approvals for multi-sig
        mapping(address => bool) hasApproved; // Tracks which approvers have approved for multi-sig
        bool signalReceived;                // True if a signal has been successfully processed
        bytes32 signalDataHash;             // Hash of the data received via signalGateConditionMet
        // Note: Time and amount checks are done directly against config/deposits
    }

    /**
     * @dev Details of a single deposit.
     */
    struct Deposit {
        AssetType assetType;         // Type of asset deposited
        address tokenAddress;        // Address of the token (0x0 for ETH)
        uint256 amount;              // Amount for ETH/ERC20
        uint256[] tokenIds;          // Array of token IDs for ERC721
        uint256 gateId;              // The gate this deposit is linked to
        uint64 depositTime;          // Timestamp of the deposit
    }

    // --- State Variables ---

    // Mapping from gate ID to its configuration
    mapping(uint256 => ObservationGateConfig) public observationGatesConfig;
    // Mapping from gate ID to its current state
    mapping(uint256 => ObservationGateState) private observationGatesState; // State is private, use getter
    // Mapping to track if a gate ID exists
    mapping(uint256 => bool) private gateExists;
    // Mapping to track if a gate is deactivated (prevents new deposits)
    mapping(uint256 => bool) public isGateDeactivated;

    // Mapping from depositor => gateId => assetType => tokenAddress => Deposit struct
    mapping(address => mapping(uint256 => mapping(AssetType => mapping(address => Deposit)))) public userGateAssetDeposits;

    // Protocol fee configuration
    uint256 public gateCreationFee;
    address public feeReceiver;
    uint256 private protocolFeesCollected;

    // --- Events ---
    event GateCreated(uint256 gateId, address indexed creator, ObservationGateConfig config);
    event GateConfigurationUpdated(uint256 gateId, address indexed updater, ObservationGateConfig newConfig);
    event GateDeactivated(uint256 gateId, address indexed deactivatedBy);
    event GateStatusSignaled(uint256 gateId, address indexed signaler, bytes32 signalDataHash);
    event MultiSigApproval(uint256 gateId, address indexed approver, uint256 approvalsReceived);
    event ETHDeposited(address indexed depositor, uint256 gateId, uint256 amount);
    event ERC20Deposited(address indexed depositor, uint256 gateId, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed depositor, uint256 gateId, address indexed token, uint256[] tokenIds);
    event ETHWithdrawn(address indexed recipient, uint256 gateId, uint256 amount);
    event ERC20Withdrawn(address indexed recipient, uint256 gateId, address indexed token, uint256 amount);
    event ERC721Withdrawn(address indexed recipient, uint256 gateId, address indexed token, uint256[] tokenIds);
    event FeeParametersUpdated(uint256 newGateCreationFee, address newFeeReceiver);
    event ProtocolFeesCollected(address indexed collector, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, address token, uint256 amountOrId, bool isERC721, uint256 count);


    // --- Constructor ---
    constructor(address _feeReceiver) Ownable(Context.msgSender()) {
        if (_feeReceiver == address(0)) revert ZeroAddress();
        feeReceiver = _feeReceiver;
        gateCreationFee = 0.01 ether; // Default fee, can be changed by owner
    }

    // --- Core Logic Functions ---

    /**
     * @dev Creates a new Observation Gate with specified configuration.
     * @param _config The configuration struct for the new gate.
     * @return The unique ID of the newly created gate.
     */
    function createObservationGate(ObservationGateConfig calldata _config) external payable nonReentrant returns (uint256) {
        // Validate configuration basics
        if (_config.requiresMultiSig && _config.requiredApprovals > _config.approvers.length) revert InvalidGateConfig();
        if (_config.requiresSignal && _config.requiredSignalHash == bytes32(0)) revert InvalidGateConfig();
        if (_config.requiresTimeLock && _config.startTime == 0) revert InvalidGateConfig(); // Start time must be set if timelock required

        // Pay gate creation fee
        if (msg.value < gateCreationFee) revert InsufficientAmount();
        if (gateCreationFee > 0) {
             // Send excess back
            if (msg.value > gateCreationFee) {
                 (bool success, ) = payable(msg.sender).call{value: msg.value - gateCreationFee}("");
                 require(success, "ETH transfer failed"); // Should not fail if called by EOA
            }
            protocolFeesCollected += gateCreationFee;
        } else {
             // If fee is 0, refund any sent ETH
            if (msg.value > 0) {
                (bool success, ) = payable(msg.sender).call{value: msg.value}("");
                require(success, "ETH refund failed");
            }
        }

        _gateIds.increment();
        uint256 newGateId = _gateIds.current();

        observationGatesConfig[newGateId] = _config;
        observationGatesConfig[newGateId].creator = msg.sender; // Ensure creator is msg.sender
        observationGatesConfig[newGateId].creationTime = uint64(block.timestamp);
        gateExists[newGateId] = true;
        isGateDeactivated[newGateId] = false; // Initially active

        emit GateCreated(newGateId, msg.sender, observationGatesConfig[newGateId]);

        return newGateId;
    }

    /**
     * @dev Allows the gate creator to update certain configuration parameters before deposits are made.
     * Only allows updating parameters that don't affect ongoing state tracking significantly.
     * For simplicity, let's restrict this or be very careful. Maybe allow only creator/owner.
     * Let's allow creator or owner to update limited parameters.
     * @param _gateId The ID of the gate to update.
     * @param _newConfig The new configuration struct.
     */
    function updateGateConfiguration(uint256 _gateId, ObservationGateConfig calldata _newConfig) external nonReentrant {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        if (observationGatesConfig[_gateId].creator != msg.sender && owner() != msg.sender) revert OnlyGateCreatorOrOwner();

        // Restrict which parameters can be updated. For example, maybe startTime, endTime, isPublic.
        // Changing multi-sig requirements or signal requirements after creation is complex due to existing state.
        // Let's allow updating time parameters and public flag.
        ObservationGateConfig storage currentConfig = observationGatesConfig[_gateId];
        currentConfig.startTime = _newConfig.startTime;
        currentConfig.endTime = _newConfig.endTime;
        currentConfig.isPublic = _newConfig.isPublic;
        // Maybe allow adding approvers, but not removing if approvals were given? Too complex. Let's keep it simple for this example.

        emit GateConfigurationUpdated(_gateId, msg.sender, currentConfig);
    }

    /**
     * @dev Deactivates a gate, preventing any new deposits from being linked to it.
     * Existing deposits remain, and can be withdrawn if the gate conditions are met.
     * @param _gateId The ID of the gate to deactivate.
     */
    function deactivateGate(uint256 _gateId) external {
         if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
         if (observationGatesConfig[_gateId].creator != msg.sender && owner() != msg.sender) revert OnlyGateCreatorOrOwner();
         if (isGateDeactivated[_gateId]) revert GateAlreadyDeactivated();

         isGateDeactivated[_gateId] = true;
         emit GateDeactivated(_gateId, msg.sender);
    }


    /**
     * @dev Checks if all conditions for a given gate ID are met.
     * This is the core "observation" function.
     * @param _gateId The ID of the gate to check.
     * @return bool True if conditions are met, false otherwise.
     */
    function checkGateStatus(uint256 _gateId) public view returns (bool) {
        if (!gateExists[_gateId]) return false;

        ObservationGateConfig storage config = observationGatesConfig[_gateId];
        ObservationGateState storage state = observationGatesState[_gateId];

        bool conditionsMet = true;

        // 1. Time Lock Check
        if (config.requiresTimeLock) {
            if (block.timestamp < config.startTime) {
                conditionsMet = false;
            }
            if (config.endTime != 0 && block.timestamp > config.endTime) {
                conditionsMet = false;
            }
        }

        // 2. Multi-Sig Check
        if (config.requiresMultiSig) {
            if (state.approvalsReceived < config.requiredApprovals) {
                conditionsMet = false;
            }
        }

        // 3. Signal Check
        if (config.requiresSignal) {
            if (!state.signalReceived || state.signalDataHash != config.requiredSignalHash) {
                 conditionsMet = false;
            }
        }

        // 4. Minimum Amount Check (Simplified: just a flag, requires external monitoring or complex internal tracking)
        // This is illustrative; true implementation would require iterating deposits or tracking total per gate.
        // For this example, we'll assume this check relies on state updated by signalGateConditionMet or similar.
        // if (config.requiresMinAmount) { ... check actual total deposited ... }
        // Let's assume `signalGateConditionMet` or another mechanism is used to 'confirm' min amount if required.
        // So if requiresMinAmount is true, maybe state.signalReceived must also be true? Or add a specific state flag.
        // Let's make it require `state.signalReceived` is true if `requiresMinAmount` is true, assuming the signal includes amount verification off-chain.
        if (config.requiresMinAmount && !state.signalReceived) {
             conditionsMet = false;
        }


        // Other potential conditions could be added here (e.g., oracle price check - would need oracle integration)

        return conditionsMet;
    }

    /**
     * @dev Allows signaling a specific condition for a gate, like providing a hash preimage.
     * Requires the signalData to hash to the requiredSignalHash in the config.
     * @param _gateId The ID of the gate.
     * @param _signalData The data being signaled (e.g., hash preimage).
     */
    function signalGateConditionMet(uint256 _gateId, bytes calldata _signalData) external nonReentrant {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        ObservationGateConfig storage config = observationGatesConfig[_gateId];
        ObservationGateState storage state = observationGatesState[_gateId];

        // Only process signal if the gate *requires* a signal based on config
        if (!config.requiresSignal && !config.requiresMinAmount) revert CannotSignalCondition(_gateId, 0); // 0 indicates general signal error

        // Check if the provided signal matches the required hash (or is just a general signal if requiresMinAmount uses it)
        // If requiresSignal, signal must match the specific hash
        if (config.requiresSignal && keccak256(_signalData) != config.requiredSignalHash) {
             revert CannotSignalCondition(_gateId, 1); // 1 indicates hash mismatch
        }

        // If requiresMinAmount but not requiresSignal, any signal sets the flag? Or maybe specific data required?
        // Let's simplify: if requiresMinAmount is true and requiresSignal is false, *any* call to signalGateConditionMet by the creator/owner sets the flag.
         if (config.requiresMinAmount && !config.requiresSignal) {
             if (config.creator != msg.sender && owner() != msg.sender) revert OnlyGateCreatorOrOwner();
         }


        // Update gate state
        state.signalReceived = true;
        state.signalDataHash = keccak256(_signalData); // Store the hash of the received signal data

        emit GateStatusSignaled(_gateId, msg.sender, state.signalDataHash);
    }


    /**
     * @dev Allows an authorized address to approve a multi-sig gate condition.
     * @param _gateId The ID of the gate.
     */
    function approveMultiSigGate(uint256 _gateId) external nonReentrant {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        ObservationGateConfig storage config = observationGatesConfig[_gateId];
        ObservationGateState storage state = observationGatesState[_gateId];

        if (!config.requiresMultiSig) revert CannotSignalCondition(_gateId, 2); // 2 indicates not a multi-sig gate

        bool isApprover = false;
        for (uint i = 0; i < config.approvers.length; i++) {
            if (config.approvers[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }
        if (!isApprover) revert NotAuthorizedToApprove(_gateId, msg.sender);

        if (state.hasApproved[msg.sender]) revert AlreadyApproved(_gateId, msg.sender);

        state.hasApproved[msg.sender] = true;
        state.approvalsReceived++;

        emit MultiSigApproval(_gateId, msg.sender, state.approvalsReceived);
    }


    /**
     * @dev Deposits ETH into the vault linked to a specific gate.
     * @param _gateId The ID of the observation gate.
     */
    function depositETHWithGate(uint256 _gateId) external payable nonReentrant {
        if (msg.value == 0) revert InsufficientAmount();
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        if (isGateDeactivated[_gateId]) revert GateNotActive(_gateId);
        if (!observationGatesConfig[_gateId].isPublic && observationGatesConfig[_gateId].creator != msg.sender && owner() != msg.sender) revert UnauthorizedGateAction();

        // Check if deposit already exists for this user/gate/asset type (ETH has address 0x0)
        Deposit storage existingDeposit = userGateAssetDeposits[msg.sender][_gateId][AssetType.ETH][address(0)];

        if (existingDeposit.amount > 0) {
             // If deposit exists, add to it
             existingDeposit.amount += msg.value;
             // Update deposit time? Or keep original? Let's keep original for simplicity.
        } else {
            // New deposit
             userGateAssetDeposits[msg.sender][_gateId][AssetType.ETH][address(0)] = Deposit({
                 assetType: AssetType.ETH,
                 tokenAddress: address(0),
                 amount: msg.value,
                 tokenIds: new uint256[](0), // Not applicable for ETH
                 gateId: _gateId,
                 depositTime: uint64(block.timestamp)
             });
        }


        emit ETHDeposited(msg.sender, _gateId, msg.value);
    }

    /**
     * @dev Deposits ERC20 tokens into the vault linked to a specific gate.
     * Requires prior approval from the depositor for the contract to spend the tokens.
     * @param _gateId The ID of the observation gate.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositERC20WithGate(uint256 _gateId, address _token, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert InsufficientAmount();
        if (_token == address(0)) revert ZeroAddress(); // Use depositETHWithGate for ETH
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        if (isGateDeactivated[_gateId]) revert GateNotActive(_gateId);
         if (!observationGatesConfig[_gateId].isPublic && observationGatesConfig[_gateId].creator != msg.sender && owner() != msg.sender) revert UnauthorizedGateAction();


        // Transfer tokens to the vault
        bool success = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "ERC20 transfer failed");

        // Check if deposit already exists for this user/gate/asset type/token
        Deposit storage existingDeposit = userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC20][_token];

        if (existingDeposit.amount > 0) {
             existingDeposit.amount += _amount;
             // Keep original deposit time
        } else {
            userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC20][_token] = Deposit({
                assetType: AssetType.ERC20,
                tokenAddress: _token,
                amount: _amount,
                tokenIds: new uint256[](0), // Not applicable for ERC20
                gateId: _gateId,
                depositTime: uint64(block.timestamp)
            });
        }


        emit ERC20Deposited(msg.sender, _gateId, _token, _amount);
    }

    /**
     * @dev Deposits ERC721 tokens into the vault linked to a specific gate.
     * Requires prior approval or `setApprovalForAll`. Uses safeTransferFrom which calls onERC721Received.
     * @param _gateId The ID of the observation gate.
     * @param _token The address of the ERC721 token.
     * @param _tokenIds An array of token IDs to deposit.
     */
    function depositERC721WithGate(uint256 _gateId, address _token, uint256[] calldata _tokenIds) external nonReentrant {
        if (_tokenIds.length == 0) revert InsufficientAmount(); // Using InsufficientAmount error conceptually for zero items
        if (_token == address(0)) revert ZeroAddress();
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        if (isGateDeactivated[_gateId]) revert GateNotActive(_gateId);
        if (!observationGatesConfig[_gateId].isPublic && observationGatesConfig[_gateId].creator != msg.sender && owner() != msg.sender) revert UnauthorizedGateAction();


        // Use safeTransferFrom which calls onERC721Received hook
        IERC721 tokenContract = IERC721(_token);
        for (uint i = 0; i < _tokenIds.length; i++) {
            tokenContract.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }

         // Check if deposit already exists for this user/gate/asset type/token
        Deposit storage existingDeposit = userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC721][_token];

        if (existingDeposit.tokenIds.length > 0) {
             // Append new token IDs to existing array
             uint existingLength = existingDeposit.tokenIds.length;
             uint newLength = existingLength + _tokenIds.length;
             uint256[] memory newTokenIds = new uint256[](newLength);
             for(uint i = 0; i < existingLength; i++) {
                 newTokenIds[i] = existingDeposit.tokenIds[i];
             }
             for(uint i = 0; i < _tokenIds.length; i++) {
                 newTokenIds[existingLength + i] = _tokenIds[i];
             }
             existingDeposit.tokenIds = newTokenIds; // Replace the array
              // Keep original deposit time
        } else {
            userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC721][_token] = Deposit({
                assetType: AssetType.ERC721,
                tokenAddress: _token,
                amount: 0, // Not applicable for ERC721
                tokenIds: _tokenIds,
                gateId: _gateId,
                depositTime: uint64(block.timestamp)
            });
        }


        emit ERC721Deposited(msg.sender, _gateId, _token, _tokenIds);
    }

    /**
     * @dev Withdraws deposited ETH if the linked gate conditions are met.
     * Withdraws the full amount for the user for this specific gate.
     * @param _gateId The ID of the observation gate.
     */
    function withdrawETHViaGate(uint256 _gateId) external nonReentrant {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);

        // Check if gate conditions are met
        if (!checkGateStatus(_gateId)) revert ConditionsNotMet(_gateId);

        // Get deposit details for the caller and this gate/asset
        address tokenAddress = address(0); // ETH uses zero address
        Deposit storage deposit = userGateAssetDeposits[msg.sender][_gateId][AssetType.ETH][tokenAddress];

        if (deposit.amount == 0) revert DepositNotFound(msg.sender, _gateId, AssetType.ETH, tokenAddress);

        uint256 amountToWithdraw = deposit.amount;

        // Clear the deposit record *before* transferring
        delete userGateAssetDeposits[msg.sender][_gateId][AssetType.ETH][tokenAddress];

        // Transfer ETH
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "ETH withdrawal failed"); // Should not fail for EOA

        emit ETHWithdrawn(msg.sender, _gateId, amountToWithdraw);
    }

    /**
     * @dev Withdraws deposited ERC20 tokens if the linked gate conditions are met.
     * Withdraws the full amount for the user for this specific gate and token.
     * @param _gateId The ID of the observation gate.
     * @param _token The address of the ERC20 token.
     */
    function withdrawERC20ViaGate(uint256 _gateId, address _token) external nonReentrant {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        if (_token == address(0)) revert ZeroAddress();

        // Check if gate conditions are met
        if (!checkGateStatus(_gateId)) revert ConditionsNotMet(_gateId);

        // Get deposit details for the caller and this gate/asset
        Deposit storage deposit = userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC20][_token];

        if (deposit.amount == 0) revert DepositNotFound(msg.sender, _gateId, AssetType.ERC20, _token);

        uint256 amountToWithdraw = deposit.amount;

        // Clear the deposit record *before* transferring
        delete userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC20][_token];

        // Transfer tokens
        bool success = IERC20(_token).transfer(msg.sender, amountToWithdraw);
        require(success, "ERC20 withdrawal failed");

        emit ERC20Withdrawn(msg.sender, _gateId, _token, amountToWithdraw);
    }

     /**
     * @dev Withdraws specified ERC721 tokens if the linked gate conditions are met.
     * User must specify which token IDs from their deposit they want to withdraw.
     * Allows partial withdrawal if the gate is reusable.
     * @param _gateId The ID of the observation gate.
     * @param _token The address of the ERC721 token.
     * @param _tokenIds An array of token IDs to withdraw.
     */
    function withdrawERC721ViaGate(uint256 _gateId, address _token, uint256[] calldata _tokenIds) external nonReentrant {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        if (_token == address(0)) revert ZeroAddress();
        if (_tokenIds.length == 0) revert InsufficientAmount(); // No token IDs specified

        // Check if gate conditions are met
        if (!checkGateStatus(_gateId)) revert ConditionsNotMet(_gateId);

        // Get deposit details for the caller and this gate/asset
        Deposit storage deposit = userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC721][_token];

        if (deposit.tokenIds.length == 0) revert DepositNotFound(msg.sender, _gateId, AssetType.ERC721, _token);

        IERC721 tokenContract = IERC721(_token);
        uint256[] memory remainingTokenIds = new uint256[](0); // Prepare array for tokens not withdrawn
        bool[] memory withdrawnFlags = new bool[_tokenIds.length]; // Track which requested tokens were withdrawn

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenIdToWithdraw = _tokenIds[i];
            bool foundInDeposit = false;
            uint foundIndex = 0;

            // Find the token ID in the depositor's stored IDs for this gate/asset
            for (uint j = 0; j < deposit.tokenIds.length; j++) {
                if (deposit.tokenIds[j] == tokenIdToWithdraw) {
                    foundInDeposit = true;
                    foundIndex = j;
                    break;
                }
            }

            if (foundInDeposit) {
                // Perform the transfer
                // Use `transferFrom` as the contract *holds* the tokens.
                // This requires the contract itself to be approved or be the owner, which it is.
                 tokenContract.transferFrom(address(this), msg.sender, tokenIdToWithdraw);
                 withdrawnFlags[i] = true; // Mark this requested token as withdrawn
                 // Note: We don't modify deposit.tokenIds array inside this loop to avoid storage manipulation issues.
                 // We rebuild the array of *remaining* tokens after the loop.
            } else {
                // Requested token ID was not found in this specific deposit record
                // Add it to the list of tokens that remain in the vault under this deposit entry
                // This handles cases where the user requested a token not in their deposit for this gate
                // Or if a token was already withdrawn previously (if gates were single-use, this wouldn't happen)
                 revert ERC721TokenNotFoundInDeposit(_gateId, _token, tokenIdToWithdraw); // Revert entire transaction if any requested token isn't found
            }
        }

        // If we reach here, all requested tokens were found and transferred.
        // Now, rebuild the deposit.tokenIds array excluding the ones just withdrawn.
        // This part is gas-intensive if deposit.tokenIds is large.

        uint currentDepositLength = deposit.tokenIds.length;
        uint withdrawalCount = _tokenIds.length; // Assuming all requested were found

        // Efficiently build the new array by only copying tokens that were NOT withdrawn
        // This approach is still O(N*M) where N is deposit tokens, M is requested tokens if we checked existence inside the loop.
        // A better approach is to iterate through deposit tokens and check if each was requested for withdrawal.

        uint256[] memory tempTokenIds = new uint256[](currentDepositLength);
        uint tempIndex = 0;

        for(uint i = 0; i < currentDepositLength; i++) {
            uint256 currentDepositTokenId = deposit.tokenIds[i];
            bool wasRequestedForWithdrawal = false;
            for(uint j = 0; j < _tokenIds.length; j++) {
                if (currentDepositTokenId == _tokenIds[j]) {
                    wasRequestedForWithdrawal = true;
                    break;
                }
            }
            if (!wasRequestedForWithdrawal) {
                 tempTokenIds[tempIndex] = currentDepositTokenId;
                 tempIndex++;
            }
        }

        // Resize the temporary array to actual remaining count and update storage
        if (tempIndex > 0) {
            uint256[] memory finalRemaining = new uint256[](tempIndex);
            for(uint i = 0; i < tempIndex; i++) {
                finalRemaining[i] = tempTokenIds[i];
            }
            deposit.tokenIds = finalRemaining; // Overwrite the storage array
        } else {
            // All tokens for this entry were withdrawn
            delete userGateAssetDeposits[msg.sender][_gateId][AssetType.ERC721][_token];
        }


        emit ERC721Withdrawn(msg.sender, _gateId, _token, _tokenIds);
    }


    // --- Admin & Protocol Functions ---

    /**
     * @dev Sets the fee parameters for the protocol. Only callable by the owner.
     * @param _newGateCreationFee The new fee amount for creating a gate.
     * @param _newFeeReceiver The address to send fees to.
     */
    function setFeeParameters(uint256 _newGateCreationFee, address _newFeeReceiver) external onlyOwner {
        if (_newFeeReceiver == address(0)) revert ZeroAddress();
        gateCreationFee = _newGateCreationFee;
        feeReceiver = _newFeeReceiver;
        emit FeeParametersUpdated(gateCreationFee, feeReceiver);
    }

    /**
     * @dev Allows the fee receiver to collect accumulated protocol fees.
     */
    function collectProtocolFees() external nonReentrant {
        if (msg.sender != feeReceiver) revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable error for clarity, though not onlyOwner
        if (protocolFeesCollected == 0) revert InsufficientAmount(); // No fees to collect

        uint256 amountToCollect = protocolFeesCollected;
        protocolFeesCollected = 0; // Reset before transfer

        (bool success, ) = payable(feeReceiver).call{value: amountToCollect}("");
        if (!success) {
            // Revert the state change if transfer fails
            protocolFeesCollected += amountToCollect;
            revert FeeCollectionFailed();
        }

        emit ProtocolFeesCollected(feeReceiver, amountToCollect);
    }

     /**
     * @dev Allows the owner to perform emergency withdrawals of specific assets.
     * This bypasses the gate conditions. Use with extreme caution.
     * Intended for critical situations (e.g., severe bug found, contract upgrade).
     * @param _assetType The type of asset (ETH, ERC20, ERC721).
     * @param _tokenAddress The token address (address(0) for ETH).
     * @param _amountOrTokenId A single amount for ETH/ERC20, or a single tokenId for ERC721.
     * @param _recipient The address to send assets to.
     */
    function emergencyWithdraw(AssetType _assetType, address _tokenAddress, uint256 _amountOrTokenId, address _recipient) external onlyOwner nonReentrant {
        if (_recipient == address(0)) revert ZeroAddress();

        uint256 amountTransferred = 0;
        uint256 tokensTransferredCount = 0;
        uint256[] memory tokenIdsTransferred = new uint256[](0);

        if (_assetType == AssetType.ETH) {
            if (_tokenAddress != address(0)) revert InvalidGateConfig(); // Should be zero address for ETH
            uint256 balance = address(this).balance;
            uint256 amountToWithdraw = _amountOrTokenId == 0 ? balance : _amountOrTokenId; // 0 means withdraw all ETH
            if (amountToWithdraw > balance) revert InsufficientAmount();

            (bool success, ) = payable(_recipient).call{value: amountToWithdraw}("");
            require(success, "Emergency ETH withdrawal failed");
            amountTransferred = amountToWithdraw;

        } else if (_assetType == AssetType.ERC20) {
             if (_tokenAddress == address(0)) revert ZeroAddress();
             uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
             uint256 amountToWithdraw = _amountOrTokenId == 0 ? balance : _amountOrTokenId; // 0 means withdraw all ERC20
             if (amountToWithdraw > balance) revert InsufficientAmount();

             bool success = IERC20(_tokenAddress).transfer(_recipient, amountToWithdraw);
             require(success, "Emergency ERC20 withdrawal failed");
             amountTransferred = amountToWithdraw;
             tokensTransferredCount = 1; // Conceptually, 1 transfer event

        } else if (_assetType == AssetType.ERC721) {
            if (_tokenAddress == address(0)) revert ZeroAddress();
            // For ERC721, _amountOrTokenId is a single tokenId
            // This function only supports withdrawing a single specified ERC721 ID at a time for safety/simplicity.
            uint256 tokenId = _amountOrTokenId;
            if (tokenId == 0) revert InsufficientAmount(); // Must specify a token ID

            IERC721 tokenContract = IERC721(_tokenAddress);
            address currentOwner = tokenContract.ownerOf(tokenId);
            if (currentOwner != address(this)) revert ERC721TokenNotFoundInDeposit(0, _tokenAddress, tokenId); // GateId 0 indicates emergency

            // Transfer using transferFrom which doesn't call onERC721Received on the recipient
            tokenContract.transferFrom(address(this), _recipient, tokenId);
            tokenIdsTransferred = new uint256[](1);
            tokenIdsTransferred[0] = tokenId;
            tokensTransferredCount = 1;

        } else {
            revert InvalidAssetType();
        }

        emit EmergencyWithdrawal(msg.sender, _tokenAddress, amountTransferred > 0 ? amountTransferred : (tokensTransferredCount > 0 ? tokenIdsTransferred[0] : 0), _assetType == AssetType.ERC721, tokensTransferredCount > 0 ? tokensTransferredCount : (amountTransferred > 0 ? 1 : 0));
    }


    // --- View Functions ---

    /**
     * @dev Gets the configuration details of a gate.
     * @param _gateId The ID of the gate.
     * @return The ObservationGateConfig struct.
     */
    function getGateDetails(uint256 _gateId) public view returns (ObservationGateConfig memory) {
         if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
         return observationGatesConfig[_gateId];
    }

    /**
     * @dev Gets the current state variables of a gate.
     * Note: Mapping values within a struct state variable cannot be returned directly.
     * We return the count of approvals and the signal state.
     * @param _gateId The ID of the gate.
     * @return approvalsReceived The current count of approvals.
     * @return signalReceived True if a signal has been processed.
     * @return signalDataHash The hash of the received signal data.
     */
     function getGateState(uint256 _gateId) public view returns (uint256 approvalsReceived, bool signalReceived, bytes32 signalDataHash) {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        ObservationGateState storage state = observationGatesState[_gateId];
        return (state.approvalsReceived, state.signalReceived, state.signalDataHash);
     }

    /**
     * @dev Gets the details of a specific deposit.
     * @param _depositor The address of the depositor.
     * @param _gateId The ID of the gate.
     * @param _assetType The type of asset (ETH, ERC20, ERC721).
     * @param _token The token address (address(0) for ETH).
     * @return The Deposit struct.
     */
    function getDepositDetails(address _depositor, uint256 _gateId, AssetType _assetType, address _token) public view returns (Deposit memory) {
        // No need to check gateExists here, as retrieving from mapping is safe even if it doesn't exist (returns zero struct)
        // However, let's check if the deposit entry itself is non-zero to indicate existence.
        Deposit memory deposit = userGateAssetDeposits[_depositor][_gateId][_assetType][_token];
        if ((_assetType == AssetType.ETH || _assetType == AssetType.ERC20) && deposit.amount == 0) {
            // Revert if amount is zero for fungible tokens, indicating no deposit entry
             revert DepositNotFound(_depositor, _gateId, _assetType, _token);
        }
         if (_assetType == AssetType.ERC721 && deposit.tokenIds.length == 0) {
            // Revert if tokenIds array is empty for ERC721, indicating no deposit entry
             revert DepositNotFound(_depositor, _gateId, _assetType, _token);
         }
        // Note: A deposit could technically exist with zero amount/empty array if cleared, but this check avoids returning empty struct.
        return deposit;
    }

    /**
     * @dev Checks if withdrawal is possible for a specific deposit entry based on gate status.
     * Does NOT check if the deposit entry actually has tokens/ETH in it. Use getDepositDetails first.
     * @param _depositor The address of the depositor.
     * @param _gateId The ID of the gate.
     * @param _assetType The type of asset (ETH, ERC20, ERC721).
     * @param _token The token address (address(0) for ETH).
     * @param _tokenIds Optional: Token IDs for ERC721 withdrawal check (ignored for ETH/ERC20).
     * @return bool True if conditions are met AND the deposit entry exists, false otherwise.
     */
    function canWithdraw(address _depositor, uint256 _gateId, AssetType _assetType, address _token, uint256[] memory _tokenIds) public view returns (bool) {
        // First, check if the gate conditions are met
        if (!checkGateStatus(_gateId)) return false;

        // Second, check if a deposit entry exists for this user/gate/asset/token
         Deposit memory deposit = userGateAssetDeposits[_depositor][_gateId][_assetType][_token];

        if (_assetType == AssetType.ETH || _assetType == AssetType.ERC20) {
            return deposit.amount > 0;
        } else if (_assetType == AssetType.ERC721) {
             if (deposit.tokenIds.length == 0) return false; // No deposit entry

             // If specific token IDs are requested, check if *all* of them are in the deposit entry's list
             if (_tokenIds.length > 0) {
                for (uint i = 0; i < _tokenIds.length; i++) {
                    bool found = false;
                    for (uint j = 0; j < deposit.tokenIds.length; j++) {
                        if (deposit.tokenIds[j] == _tokenIds[i]) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) return false; // One of the requested tokens is not in the deposit
                }
                return true; // All requested tokens were found and gate is open
             } else {
                 // If no specific token IDs are requested, check if *any* ERC721s are in the deposit entry
                 return deposit.tokenIds.length > 0; // Should already be true due to outer check, but good for clarity
             }
        } else {
             revert InvalidAssetType(); // Should not happen with enum input
        }
    }


    /**
     * @dev Gets the creator address of a specific gate.
     * @param _gateId The ID of the gate.
     * @return The creator's address.
     */
    function getGateCreator(uint256 _gateId) public view returns (address) {
        if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
        return observationGatesConfig[_gateId].creator;
    }

    /**
     * @dev Gets the current gate creation fee.
     * @return The fee amount in wei.
     */
    function getGateCreationFee() public view returns (uint256) {
        return gateCreationFee;
    }

     /**
     * @dev Gets the number of approvals received for a multi-sig gate.
     * @param _gateId The ID of the gate.
     * @return The current approval count.
     */
    function getGateApprovedCount(uint256 _gateId) public view returns (uint256) {
         if (!gateExists[_gateId]) revert GateDoesNotExist(_gateId);
         return observationGatesState[_gateId].approvalsReceived;
    }


    /**
     * @dev Gets the current protocol fee parameters.
     * @return currentGateCreationFee The current fee for creating gates.
     * @return currentFeeReceiver The address fees are sent to.
     * @return currentFeesCollected The total fees collected but not yet withdrawn.
     */
    function getProtocolFeeParameters() public view returns (uint256 currentGateCreationFee, address currentFeeReceiver, uint256 currentFeesCollected) {
        return (gateCreationFee, feeReceiver, protocolFeesCollected);
    }

    // --- ERC721 Receiver Hook ---

    /**
     * @dev See IERC721Receiver.onERC721Received
     * This is necessary for ERC721 safe transfers into the contract.
     * Accepts all ERC721 transfers directed to it.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4) {
        // Ensure it's coming from the token itself
        // require(msg.sender == IERC721(msg.sender).address, "Not called by ERC721 token"); // Not always reliable

        // Accept the transfer. No specific logic needed here as deposit logic is handled in depositERC721WithGate.
        // We just need to return the magic value.
        return this.onERC721Received.selector;
    }

     // Optional: Implement supportsInterface for ERC165 compliance, standard with ERC721Holder
    // function supportsInterface(bytes4 interfaceId) public view override(ERC721Holder, Ownable) returns (bool) {
    //     return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    // }

    // Fallback function to receive ETH not associated with a deposit (e.g., accidental send, or fees)
    // This ETH would accumulate in the contract balance and could only be retrieved via emergencyWithdraw or fee collection (if routed there).
    receive() external payable {
        // Optional: emit an event for received ETH that wasn't part of a deposit
        // emit ReceivedAccidentalETH(msg.sender, msg.value);
    }
}
```