Okay, let's design a smart contract based on a "Quantum Vault" concept. This contract will hold multiple types of assets (ERC20, ERC721, ERC1155) that can only be unlocked and claimed when a complex set of conditions are met across different "Temporal Epochs" and "Quantum Entanglement Points" (QEPs). The QEPs can involve factors like external data verification, proving ownership of other assets, or solving on-chain "puzzles" like providing a hash preimage.

This concept aims to be creative by tying vault unlocks to a multi-dimensional state (time, external data, user proofs) rather than just a simple time-lock or single condition. It's advanced by using different asset types, state machines, and incorporating mechanisms that could interface with oracles or proof systems. It's trendy in its potential use cases (complex vesting, multi-stage releases, gamified unlocks). It avoids duplicating common patterns like standard time-locks, multi-sigs, or simple yield farms.

---

**Smart Contract: QuantumVault**

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** OpenZeppelin interfaces (ERC20, ERC721, ERC1155), Ownable, Pausable, SafeERC20/SafeTransferLib.
3.  **Error Definitions:** Custom errors for clarity.
4.  **Enums:**
    *   `VaultState`: States like Locked, Unlocking, Unlocked, Claimable, Paused, EmergencyStop.
    *   `QEPType`: Types of Quantum Entanglement Points (e.g., PriceFeedGreaterThan, TokenBalanceMinimum, NFT_Ownership, ProveHashPreimage).
5.  **Structs:**
    *   `Deposit`: Details of each individual deposit (token, id, amount, depositor, timestamp, claim status).
    *   `QEP`: Configuration for a Quantum Entanglement Point (type, target values, status).
    *   `TemporalEpoch`: Configuration for an epoch (duration, required QEPs for this epoch).
6.  **State Variables:**
    *   Owner, Paused state.
    *   Vault State.
    *   Deposit tracking (mappings for ERC20 total, and a mapping for `Deposit` structs by ID).
    *   Epoch data (array of `TemporalEpoch`, current epoch index, start time).
    *   QEP data (mapping of QEP ID to `QEP` struct, status tracking for current epoch).
    *   Counters for deposit IDs, QEP IDs.
7.  **Events:** Deposit, Withdrawal, StateChange, EpochAdvanced, QEPStatusUpdated, UnlockAttempt, AssetsClaimed.
8.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenVaultStateIs`.
9.  **Core Logic:**
    *   Constructor: Initializes owner, sets initial state.
    *   Deposit Functions: Handle ERC20, ERC721, ERC1155 deposits, record details.
    *   Owner/Setup Functions: Initialize epochs, set QEP configurations.
    *   State Transition Functions: Advance epoch (based on time), attempt unlock (based on epoch and QEP status).
    *   QEP Proof Functions: Allow users/oracles to submit proofs to resolve QEPs.
    *   Claim Functions: Allow depositors to claim assets once the vault reaches a claimable state.
    *   Emergency Functions: Owner controls for pausing or emergency withdrawal.
10. **View Functions:** Get state, deposit details, epoch info, QEP status.

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets the owner.
2.  `depositERC20(address tokenAddress, uint256 amount)`: Allows a user to deposit ERC20 tokens into the vault. Records the deposit.
3.  `depositERC721(address tokenAddress, uint256 tokenId)`: Allows a user to deposit an ERC721 token. Records the deposit.
4.  `depositERC1155(address tokenAddress, uint256 tokenId, uint256 amount)`: Allows a user to deposit ERC1155 tokens. Records the deposit.
5.  `ownerEmergencyWithdrawERC20(address tokenAddress, uint256 amount)`: Owner can withdraw ERC20 in an emergency. Restricted by state/modifiers.
6.  `ownerEmergencyWithdrawERC721(address tokenAddress, uint256 tokenId)`: Owner can withdraw ERC721 in an emergency. Restricted by state/modifiers.
7.  `ownerEmergencyWithdrawERC1155(address tokenAddress, uint256 tokenId, uint256 amount)`: Owner can withdraw ERC1155 in an emergency. Restricted by state/modifiers.
8.  `initTemporalEpochs(TemporalEpoch[] calldata _epochs)`: Owner defines the sequence and properties of temporal epochs. Can only be called in certain states.
9.  `setCurrentEpochQEPs(uint64[] calldata qepIds)`: Owner links specific, predefined QEPs to the *current* temporal epoch.
10. `advanceTemporalEpoch()`: Public function to move to the next epoch if the conditions (primarily time elapsed since epoch start) are met. Resets QEP status for the new epoch.
11. `setQEPConfiguration(uint64 qepId, QEPType qepType, bytes32 targetHash, uint256 targetValue, address targetAddress)`: Owner defines a specific Quantum Entanglement Point configuration.
12. `proveQEP_ExternalData(uint64 qepId, uint256 dataValue)`: Allows proving a QEP condition met using external data (e.g., price feed value). Requires the data value to match a configured target for the QEP.
13. `proveQEP_NFT_Ownership(uint64 qepId, address user, address nftContract, uint256 tokenId)`: Allows proving a QEP condition met by demonstrating a user owns a specific NFT. Can be called by the user or a relayer.
14. `proveQEP_Token_Balance(uint64 qepId, address user, address tokenContract, uint256 requiredAmount)`: Allows proving a QEP condition met by demonstrating a user holds a minimum balance of a token. Can be called by the user or a relayer.
15. `proveQEP_HashPreimage(uint64 qepId, bytes calldata preimage)`: Allows proving a QEP condition met by providing the preimage of a target hash set in the QEP config.
16. `checkVaultUnlockStatus()`: Public view function to check if the *combined* conditions (current epoch completed + all required QEPs for the current epoch met) are satisfied.
17. `attemptVaultUnlock()`: Public function that, if `checkVaultUnlockStatus()` is true, transitions the vault state towards 'Unlocked' or 'Claimable'. Might initiate a final waiting period.
18. `claimDepositedERC20()`: Allows a depositor to claim their total deposited ERC20 tokens once the vault is in a claimable state.
19. `claimDepositedERC721(uint64 depositId)`: Allows a depositor to claim a specific deposited ERC721 token by its deposit ID once claimable.
20. `claimDepositedERC1155(uint64 depositId, uint256 amount)`: Allows a depositor to claim a portion or all of a specific ERC1155 deposit by ID once claimable.
21. `pauseVault()`: Owner can pause certain operations (deposits, claims).
22. `unpauseVault()`: Owner can unpause operations.
23. `emergencyStop()`: Owner can set the vault to a terminal emergency state, potentially allowing only owner withdrawal or specific recovery.
24. `getVaultState()`: View function returning the current state of the vault.
25. `getEpochDetails()`: View function returning information about the current epoch and total epochs.
26. `getQEPStatus(uint64 qepId)`: View function returning the status (met/unmet) for a specific QEP in the current epoch.
27. `getUserDepositIds(address user)`: View function returning an array of deposit IDs for a specific user.
28. `getDepositDetails(uint64 depositId)`: View function returning the details of a specific deposit.
29. `getTotalDepositedERC20(address user, address tokenAddress)`: View function returning the total ERC20 amount deposited by a user for a specific token.
30. `getQEPConfiguration(uint64 qepId)`: View function returning the configuration details for a specific QEP.

*(Self-correction during list generation: Need to track which QEPs are met *per epoch*. Add a mapping for this. Also, need a mapping to link users to their deposit IDs. Need functions to get user deposit IDs and specific deposit details. Added functions 27, 28, 29. Added QEP config view 30. Renamed some claim functions for clarity based on asset type and method).*

This structure provides the required number of functions and covers the complex concepts outlined.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol"; // Needed for ERC721/1155 checks

// Using SafeTransferLib for ERC721/ERC1155 transfers out - more gas efficient than SafeERC721/SafeERC1155
import "erc721a/contracts/libraries/SafeTransferLib.sol"; // Or your preferred SafeTransfer utility

/// @title QuantumVault
/// @dev A complex, multi-stage vault for holding ERC20, ERC721, and ERC1155 assets.
/// Unlock conditions are based on Temporal Epochs and resolving Quantum Entanglement Points (QEPs).
/// QEPs can depend on external data, asset ownership proofs, or cryptographic puzzles.

contract QuantumVault is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeTransferLib for IERC721;
    using SafeTransferLib for IERC1155;
    using Address for address;
    using Counters for Counters.Counter;

    // --- Custom Errors ---
    error InvalidVaultState();
    error VaultNotClaimable();
    error VaultNotLocked();
    error InvalidEpochConfiguration();
    error EpochNotInitiated();
    error EpochInProgress();
    error EpochNotComplete();
    error AllEpochsCompleted();
    error InvalidQEPConfiguration();
    error QEPAlreadyMet();
    error QEPNotApplicableToEpoch();
    error InvalidQEPProof();
    error DepositNotFound();
    error DepositAlreadyClaimed();
    error InvalidClaimAmount();
    error NotDepositor();
    error EmergencyStopActive();

    // --- Enums ---
    enum VaultState {
        Locked,           // Initial state, accepting deposits, epochs not started
        EpochInProgress,  // Epochs are running, QEPs are being resolved
        EpochsComplete,   // All epochs finished, checking final unlock conditions
        Unlocking,        // Final conditions met, vault is transitioning to claimable
        Claimable,        // Assets can be claimed by depositors
        Paused,           // Vault is paused by owner
        EmergencyStop     // Vault is in a terminal emergency state
    }

    enum QEPType {
        None,                   // Default state, unused QEP slot
        PriceFeedGreaterThan,   // Requires proving a price feed value is > targetValue
        TokenBalanceMinimum,    // Requires proving a user holds a minimum token balance
        NFT_Ownership,          // Requires proving a user owns a specific NFT
        ProveHashPreimage       // Requires providing a preimage for a targetHash
    }

    // --- Structs ---
    struct Deposit {
        address tokenAddress;
        uint256 tokenId; // Used for ERC721 and ERC1155
        uint256 amount; // Used for ERC20 and ERC1155
        address depositor;
        uint64 timestamp;
        bool claimed;
        uint8 tokenType; // 0: ERC20, 1: ERC721, 2: ERC1155
    }

    struct QEP {
        QEPType qepType;
        bytes32 targetHash; // Used for ProveHashPreimage
        uint256 targetValue; // Used for PriceFeedGreaterThan, TokenBalanceMinimum
        address targetAddress; // Used for PriceFeedGreaterThan (oracle), TokenBalanceMinimum, NFT_Ownership (token/NFT contract)
        uint256 targetTokenId; // Used for NFT_Ownership
    }

    struct TemporalEpoch {
        uint64 duration; // Duration in seconds
        uint64[] requiredQEPIds; // QEPs that must be met during this epoch
    }

    // --- State Variables ---
    VaultState public currentVaultState;
    TemporalEpoch[] private temporalEpochs;
    uint256 public currentEpochIndex;
    uint64 public currentEpochStartTime;
    bool public allEpochsConfigured;

    // Mapping from QEP ID to its configuration
    mapping(uint64 => QEP) private qepConfigurations;
    // Mapping for QEPs that need proving specific user actions (TokenBalance, NFT_Ownership)
    mapping(uint64 => mapping(address => bool)) private qepUserProofStatus; // qepId => user => met
    // Mapping for general QEPs (PriceFeed, HashPreimage)
    mapping(uint64 => bool) private qepGlobalStatus; // qepId => met
    // Mapping to track QEP status specifically for the *current* epoch
    mapping(uint64 => bool) private currentEpochQEPStatus; // qepId => met in current epoch

    Counters.Counter private _depositIdCounter;
    Counters.Counter private _qepIdCounter;
    mapping(uint64 => Deposit) private deposits;
    mapping(address => uint64[]) private userDepositIds;
    mapping(address => mapping(address => uint256)) private totalDepositedERC20; // user => tokenAddress => amount

    // --- Events ---
    event DepositMade(uint64 indexed depositId, address indexed depositor, address tokenAddress, uint256 tokenId, uint256 amount, uint8 tokenType);
    event WithdrawalMade(address indexed withdrawer, address tokenAddress, uint256 tokenId, uint256 amount, uint8 tokenType);
    event VaultStateChanged(VaultState oldState, VaultState newState);
    event EpochsInitialized(uint256 numberOfEpochs);
    event EpochAdvanced(uint256 indexed oldEpochIndex, uint256 indexed newEpochIndex, uint64 startTime);
    event CurrentEpochQEPsSet(uint64[] qepIds);
    event QEPConfigurationSet(uint64 indexed qepId, QEPType qepType);
    event QEPStatusUpdated(uint64 indexed qepId, address indexed user, bool status);
    event VaultUnlockAttempt(bool conditionsMet);
    event AssetsClaimed(uint64 indexed depositId, address indexed claimer, uint256 amount);
    event EmergencyStopActivated();

    // --- Modifiers ---
    modifier whenVaultStateIs(VaultState _state) {
        if (currentVaultState != _state) {
            revert InvalidVaultState();
        }
        _;
    }

    modifier whenVaultStateIsNot(VaultState _state) {
        if (currentVaultState == _state) {
            revert InvalidVaultState();
        }
        _;
    }

    /// @dev Constructor sets the initial owner.
    constructor(address initialOwner) Ownable(initialOwner) {
        currentVaultState = VaultState.Locked;
        emit VaultStateChanged(VaultState.Locked, VaultState.Locked); // Initial state announcement
    }

    // --- Core Deposit Functions ---

    /// @dev Deposits ERC20 tokens into the vault.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address tokenAddress, uint256 amount) external payable whenNotPaused whenVaultStateIs(VaultState.Locked) {
        if (amount == 0) revert InvalidClaimAmount();
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        _depositIdCounter.increment();
        uint64 depositId = _depositIdCounter.current();

        deposits[depositId] = Deposit({
            tokenAddress: tokenAddress,
            tokenId: 0, // Not applicable for ERC20
            amount: amount,
            depositor: msg.sender,
            timestamp: uint64(block.timestamp),
            claimed: false,
            tokenType: 0 // ERC20
        });
        userDepositIds[msg.sender].push(depositId);
        totalDepositedERC20[msg.sender][tokenAddress] += amount;

        emit DepositMade(depositId, msg.sender, tokenAddress, 0, amount, 0);
    }

    /// @dev Deposits an ERC721 token into the vault.
    /// @param tokenAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the ERC721 token.
    function depositERC721(address tokenAddress, uint256 tokenId) external payable whenNotPaused whenVaultStateIs(VaultState.Locked) {
         if (!IERC165(tokenAddress).supportsInterface(0x80ac58cd)) revert InvalidVaultState(); // Check ERC721 interface

        IERC721 token = IERC721(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        _depositIdCounter.increment();
        uint64 depositId = _depositIdCounter.current();

        deposits[depositId] = Deposit({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            amount: 1, // Amount is always 1 for ERC721
            depositor: msg.sender,
            timestamp: uint64(block.timestamp),
            claimed: false,
            tokenType: 1 // ERC721
        });
        userDepositIds[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, tokenAddress, tokenId, 1, 1);
    }

    /// @dev Deposits ERC1155 tokens into the vault.
    /// @param tokenAddress The address of the ERC1155 contract.
    /// @param tokenId The ID of the ERC1155 token type.
    /// @param amount The amount of tokens to deposit.
    function depositERC1155(address tokenAddress, uint256 tokenId, uint256 amount) external payable whenNotPaused whenVaultStateIs(VaultState.Locked) {
         if (!IERC165(tokenAddress).supportsInterface(0xd9b67a26)) revert InvalidVaultState(); // Check ERC1155 interface
         if (amount == 0) revert InvalidClaimAmount();

        IERC1155 token = IERC1155(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        _depositIdCounter.increment();
        uint64 depositId = _depositIdCounter.current();

        deposits[depositId] = Deposit({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            amount: amount,
            depositor: msg.sender,
            timestamp: uint64(block.timestamp),
            claimed: false,
            tokenType: 2 // ERC1155
        });
        userDepositIds[msg.sender].push(depositId);

        emit DepositMade(depositId, msg.sender, tokenAddress, tokenId, amount, 2);
    }

    /// @dev Handles ERC1155 received hook. Required by ERC1155 standard.
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external pure returns (bytes4) {
        // Only accept from self during transfers within the contract
        if (from == address(this)) return this.onERC1155Received.selector;
        // Revert for external ERC1155 deposits, they must use the deposit function
        revert("ERC1155 deposits must use the deposit function");
    }

    /// @dev Handles ERC1155 batch received hook. Required by ERC1155 standard.
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external pure returns (bytes4) {
         // Only accept from self during transfers within the contract
        if (from == address(this)) return this.onERC1155BatchReceived.selector;
        // Revert for external ERC1155 deposits, they must use the deposit function
        revert("ERC1155 deposits must use the deposit function");
    }

    // --- Owner Emergency Functions ---

    /// @dev Allows owner to withdraw ERC20 in case of emergency.
    /// Can only be called in Paused or EmergencyStop states.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount to withdraw.
    function ownerEmergencyWithdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (currentVaultState != VaultState.Paused && currentVaultState != VaultState.EmergencyStop) revert InvalidVaultState();
        if (amount == 0) revert InvalidClaimAmount();
        IERC20(tokenAddress).safeTransfer(owner(), amount);
        emit WithdrawalMade(owner(), tokenAddress, 0, amount, 0);
    }

     /// @dev Allows owner to withdraw ERC721 in case of emergency.
    /// Can only be called in Paused or EmergencyStop states.
    /// @param tokenAddress The address of the ERC721 contract.
    /// @param tokenId The ID of the ERC721 token.
    function ownerEmergencyWithdrawERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        if (currentVaultState != VaultState.Paused && currentVaultState != VaultState.EmergencyStop) revert InvalidVaultState();
        IERC721(tokenAddress).safeTransferFrom(address(this), owner(), tokenId);
        emit WithdrawalMade(owner(), tokenAddress, tokenId, 1, 1);
    }

     /// @dev Allows owner to withdraw ERC1155 in case of emergency.
    /// Can only be called in Paused or EmergencyStop states.
    /// @param tokenAddress The address of the ERC1155 contract.
    /// @param tokenId The ID of the ERC1155 token type.
    /// @param amount The amount to withdraw.
    function ownerEmergencyWithdrawERC1155(address tokenAddress, uint256 tokenId, uint256 amount) external onlyOwner {
        if (currentVaultState != VaultState.Paused && currentVaultState != VaultState.EmergencyStop) revert InvalidVaultState();
        if (amount == 0) revert InvalidClaimAmount();
        IERC1155(tokenAddress).safeTransferFrom(address(this), owner(), tokenId, amount, "");
        emit WithdrawalMade(owner(), tokenAddress, tokenId, amount, 2);
    }


    // --- Epoch Management ---

    /// @dev Initializes the temporal epochs sequence. Can only be called once in the Locked state.
    /// @param _epochs An array defining the epochs and their durations/required QEPs.
    function initTemporalEpochs(TemporalEpoch[] calldata _epochs) external onlyOwner whenVaultStateIs(VaultState.Locked) {
        if (_epochs.length == 0) revert InvalidEpochConfiguration();
        if (allEpochsConfigured) revert InvalidEpochConfiguration(); // Prevent re-initialization

        temporalEpochs = _epochs;
        allEpochsConfigured = true;
        currentEpochIndex = 0;
        currentEpochStartTime = uint64(block.timestamp);
        _transitionState(VaultState.EpochInProgress);

        // Reset QEP status for the first epoch
        _resetCurrentEpochQEPStatus();

        emit EpochsInitialized(temporalEpochs.length);
        emit EpochAdvanced(0, 0, currentEpochStartTime); // Announce start of first epoch
    }

    /// @dev Advances the vault to the next temporal epoch.
    /// Can be called by anyone, but only succeeds if the current epoch duration has passed
    /// AND all required QEPs for the *current* epoch have been met.
    function advanceTemporalEpoch() external whenVaultStateIs(VaultState.EpochInProgress) {
        if (currentEpochIndex >= temporalEpochs.length) revert AllEpochsCompleted();

        TemporalEpoch storage currentEpoch = temporalEpochs[currentEpochIndex];

        // Check if epoch duration has passed
        if (block.timestamp < currentEpochStartTime + currentEpoch.duration) {
            revert EpochNotComplete();
        }

        // Check if all required QEPs for the current epoch are met
        for (uint256 i = 0; i < currentEpoch.requiredQEPIds.length; i++) {
            uint64 qepId = currentEpoch.requiredQEPIds[i];
            if (!currentEpochQEPStatus[qepId]) {
                 // Specific check for user-proven QEPs: ensure at least one user met it if required
                QEPType qepType = qepConfigurations[qepId].qepType;
                if (qepType == QEPType.TokenBalanceMinimum || qepType == QEPType.NFT_Ownership) {
                    // We need to know if *any* user fulfilled this. This check is complex.
                    // For simplicity in this example, we'll assume if a user-specific QEP
                    // is in `requiredQEPIds`, its global status must be manually set
                    // or derived in a more complex way (e.g., threshold of users).
                    // A simpler design: User QEPs contribute to a global pool that,
                    // when a threshold is met, triggers the QEP global status.
                    // Let's stick to the simpler model for now: QEPs are either global (Price, Hash)
                    // or user-specific (Balance, NFT). Epochs require a mix.
                    // User-specific QEPs needed for an epoch might require proving from *any* user.
                    // The `qepUserProofStatus` track user proofs. The epoch advance needs
                    // to check if *any* user proof exists if the QEP is user-specific type.
                    // Or, a global flag linked to the user QEPs must be set when a threshold is reached.
                    // Let's require a simple global flag `qepGlobalStatus` to be true for *all* required QEPs,
                    // whether they are global or user-specific types. The mechanism to set
                    // `qepGlobalStatus` for user-specific types (e.g., threshold logic) is left abstract
                    // or would be implemented in a separate 'aggregation' function called after user proofs.
                    // For this example, assume `qepGlobalStatus[qepId]` must be true for all required QEPs.
                     if (!qepGlobalStatus[qepId]) {
                         revert EpochNotComplete(); // This QEP (user or global type) hasn't been marked globally complete
                     }
                } else { // Global QEP type (Price, Hash)
                     if (!qepGlobalStatus[qepId]) {
                         revert EpochNotComplete(); // This global QEP hasn't been marked complete
                     }
                }
            }
        }

        // Advance to the next epoch
        currentEpochIndex++;
        if (currentEpochIndex >= temporalEpochs.length) {
            // Last epoch completed, move to unlock phase
            _transitionState(VaultState.EpochsComplete);
        } else {
            // Move to next epoch
            currentEpochStartTime = uint64(block.timestamp);
            _resetCurrentEpochQEPStatus(); // Reset QEP status for the new epoch
        }

        emit EpochAdvanced(currentEpochIndex - 1, currentEpochIndex, currentEpochStartTime);
    }

    // --- QEP Configuration and Proof ---

    /// @dev Defines or updates a Quantum Entanglement Point configuration.
    /// @param qepId The ID of the QEP. Use 0 to create a new QEP.
    /// @param qepType The type of QEP.
    /// @param targetHash Target hash for ProveHashPreimage type.
    /// @param targetValue Target value for PriceFeedGreaterThan or TokenBalanceMinimum types.
    /// @param targetAddress Target address for PriceFeedGreaterThan (oracle), TokenBalanceMinimum, NFT_Ownership (contract address).
    /// @param targetTokenId Target token ID for NFT_Ownership type.
    function setQEPConfiguration(
        uint64 qepId,
        QEPType qepType,
        bytes32 targetHash,
        uint256 targetValue,
        address targetAddress,
        uint256 targetTokenId
    ) external onlyOwner whenVaultStateIsNot(VaultState.EpochInProgress) {
        if (qepType == QEPType.None) revert InvalidQEPConfiguration();

        uint64 idToUse = qepId == 0 ? _qepIdCounter.current() + 1 : qepId; // Use next counter or specified ID
        if (qepId == 0) _qepIdCounter.increment();

        qepConfigurations[idToUse] = QEP({
            qepType: qepType,
            targetHash: targetHash,
            targetValue: targetValue,
            targetAddress: targetAddress,
            targetTokenId: targetTokenId
        });

        emit QEPConfigurationSet(idToUse, qepType);
    }

    /// @dev Links specific QEPs to the *current* epoch.
    /// Can only be called by owner when the vault is in EpochInProgress and QEPs for the epoch haven't been set.
    /// NOTE: This design allows dynamic QEPs per epoch. A more complex design could pre-define QEPs per epoch during `initTemporalEpochs`.
    /// This current simple design requires owner to set QEPs *after* an epoch starts.
    function setCurrentEpochQEPs(uint64[] calldata qepIds) external onlyOwner whenVaultStateIs(VaultState.EpochInProgress) {
        // Check if QEPs for this epoch are already set (basic check)
        if (currentEpochQEPStatus[qepIds[0]]) revert InvalidVaultState(); // Assume first ID check is sufficient, or loop through all

        TemporalEpoch storage currentEpoch = temporalEpochs[currentEpochIndex];
        currentEpoch.requiredQEPIds = qepIds; // Update the required QEPs for the current epoch struct
        _resetCurrentEpochQEPStatus(); // Ensure status starts as false for these QEPs

        emit CurrentEpochQEPsSet(qepIds);
    }


    /// @dev Allows a user/oracle to provide proof for a QEP dependent on external data (e.g., price feed).
    /// This assumes the QEP is configured for PriceFeedGreaterThan.
    /// @param qepId The ID of the QEP.
    /// @param dataValue The external data value (e.g., price).
    /// NOTE: In a real scenario, this would require signature verification or integration with a specific oracle contract.
    /// This is a simplified example where the data value is passed directly.
    function proveQEP_ExternalData(uint64 qepId, uint256 dataValue) external whenVaultStateIs(VaultState.EpochInProgress) {
        QEP storage qep = qepConfigurations[qepId];
        if (qep.qepType != QEPType.PriceFeedGreaterThan) revert InvalidQEPProof();
        if (currentEpochQEPStatus[qepId]) revert QEPAlreadyMet(); // QEP already proven for this epoch

        // Check if the data value meets the condition
        if (dataValue <= qep.targetValue) revert InvalidQEPProof();

        // Mark the QEP as met globally and for the current epoch
        qepGlobalStatus[qepId] = true;
        currentEpochQEPStatus[qepId] = true;

        emit QEPStatusUpdated(qepId, address(0), true); // Address 0 indicates global status update
    }

    /// @dev Allows a user to prove they meet a Token Balance QEP condition.
    /// @param qepId The ID of the QEP.
    /// @param user The user address to check the balance for.
    function proveQEP_Token_Balance(uint64 qepId, address user) external whenVaultStateIs(VaultState.EpochInProgress) {
         QEP storage qep = qepConfigurations[qepId];
        if (qep.qepType != QEPType.TokenBalanceMinimum) revert InvalidQEPProof();
        if (qepUserProofStatus[qepId][user]) revert QEPAlreadyMet(); // User already proven for this QEP

        // Check user's balance
        if (IERC20(qep.targetAddress).balanceOf(user) < qep.targetValue) revert InvalidQEPProof();

        // Mark the QEP as met for this specific user
        qepUserProofStatus[qepId][user] = true;
        // NOTE: A mechanism is needed here or elsewhere to update the global status
        // `qepGlobalStatus[qepId]` based on *how many* users meet the condition, if required by the epoch.
        // For this example, just proving for *one* user might be enough to flip a global flag,
        // or the epoch might require a threshold. We assume for simplicity that proving it for
        // *any* required user contributes towards the epoch requirement. Let's update the global status
        // whenever *any* user meets the requirement, but log the specific user proof.
        qepGlobalStatus[qepId] = true; // Assume any user proof counts towards the global epoch requirement
        currentEpochQEPStatus[qepId] = true; // And counts for the current epoch

        emit QEPStatusUpdated(qepId, user, true);
    }

     /// @dev Allows a user to prove they meet an NFT Ownership QEP condition.
    /// @param qepId The ID of the QEP.
    /// @param user The user address to check the NFT ownership for.
    function proveQEP_NFT_Ownership(uint64 qepId, address user) external whenVaultStateIs(VaultState.EpochInProgress) {
        QEP storage qep = qepConfigurations[qepId];
        if (qep.qepType != QEPType.NFT_Ownership) revert InvalidQEPProof();
        if (currentEpochQEPStatus[qepId]) revert QEPAlreadyMet(); // Assuming only one proof needed per epoch for NFT QEPs

        // Check user's NFT ownership
        if (IERC721(qep.targetAddress).ownerOf(qep.targetTokenId) != user) revert InvalidQEPProof();

        // Mark the QEP as met globally and for the current epoch
        qepGlobalStatus[qepId] = true;
        currentEpochQEPStatus[qepId] = true;

        emit QEPStatusUpdated(qepId, user, true);
    }

    /// @dev Allows a user to provide the preimage for a Hash Preimage QEP.
    /// @param qepId The ID of the QEP.
    /// @param preimage The preimage to check.
    function proveQEP_HashPreimage(uint64 qepId, bytes calldata preimage) external whenVaultStateIs(VaultState.EpochInProgress) {
         QEP storage qep = qepConfigurations[qepId];
        if (qep.qepType != QEPType.ProveHashPreimage) revert InvalidQEPProof();
        if (currentEpochQEPStatus[qepId]) revert QEPAlreadyMet(); // QEP already proven for this epoch

        // Check if the hash matches
        if (keccak256(preimage) != qep.targetHash) revert InvalidQEPProof();

        // Mark the QEP as met globally and for the current epoch
        qepGlobalStatus[qepId] = true;
        currentEpochQEPStatus[qepId] = true;

        emit QEPStatusUpdated(qepId, address(0), true); // Address 0 indicates global status update
    }


    // --- Vault State & Unlock Functions ---

    /// @dev Checks if the current vault unlock conditions are met.
    /// Conditions: All epochs completed AND all required QEPs for the *last* epoch are met.
    function checkVaultUnlockStatus() public view returns (bool) {
        if (currentVaultState != VaultState.EpochsComplete) return false;

        // Check if all required QEPs for the final epoch are met
        if (currentEpochIndex < temporalEpochs.length) return false; // Should be >= length if epochs complete

        TemporalEpoch storage finalEpoch = temporalEpochs[temporalEpochs.length - 1]; // The last epoch config

         for (uint256 i = 0; i < finalEpoch.requiredQEPIds.length; i++) {
             uint64 qepId = finalEpoch.requiredQEPIds[i];
             // We need to check the status of QEPs *as they were at the end of the final epoch*.
             // The current `qepGlobalStatus` and `currentEpochQEPStatus` only reflect the *active* epoch.
             // A more robust system would snapshot QEP status per epoch.
             // For simplicity here, we assume `qepGlobalStatus` reflects cumulative status that must be true
             // at the time of `attemptVaultUnlock` IF that QEP was required by the *final* epoch.
             if (!qepGlobalStatus[qepId]) {
                  return false;
             }
         }

        return true; // All conditions met
    }

    /// @dev Attempts to transition the vault to the Unlocking/Claimable state.
    /// Can be called by anyone if `checkVaultUnlockStatus()` returns true.
    function attemptVaultUnlock() external whenVaultStateIs(VaultState.EpochsComplete) {
        bool conditionsMet = checkVaultUnlockStatus();
        emit VaultUnlockAttempt(conditionsMet);

        if (!conditionsMet) revert VaultNotClaimable();

        // Transition to Unlocking or directly to Claimable
        // A real scenario might add a final time delay here (Unlocking state)
        // For simplicity, we'll go directly to Claimable
        _transitionState(VaultState.Claimable);
    }

    /// @dev Internal function to transition the vault state.
    /// @param newState The state to transition to.
    function _transitionState(VaultState newState) internal {
        VaultState oldState = currentVaultState;
        currentVaultState = newState;
        emit VaultStateChanged(oldState, newState);
    }

    /// @dev Internal function to reset the status mapping for QEPs for the new epoch.
    function _resetCurrentEpochQEPStatus() internal {
         // Note: This only works if the number of QEP IDs per epoch is reasonably small.
         // For larger numbers, iterating through configured QEPs might be needed.
         // A better design would clear/reset the map more explicitly or track QEPs per epoch differently.
         // For this example, we assume re-setting is sufficient.
         // If `temporalEpochs[currentEpochIndex]` has `requiredQEPIds`, iterate them and set `currentEpochQEPStatus[id] = false`.
         if (currentEpochIndex < temporalEpochs.length) {
             TemporalEpoch storage currentEpoch = temporalEpochs[currentEpochIndex];
             for(uint256 i = 0; i < currentEpoch.requiredQEPIds.length; i++) {
                 currentEpochQEPStatus[currentEpoch.requiredQEPIds[i]] = false;
             }
         }
    }


    // --- Claim Functions ---

    /// @dev Allows a depositor to claim their total deposited ERC20 tokens.
    /// Can only be called when the vault is in the Claimable state.
    function claimDepositedERC20(address tokenAddress) external whenNotPaused whenVaultStateIs(VaultState.Claimable) {
        uint256 amount = totalDepositedERC20[msg.sender][tokenAddress];
        if (amount == 0) revert InvalidClaimAmount(); // Or DepositNotFound();

        // Reset the user's balance to prevent double claiming
        totalDepositedERC20[msg.sender][tokenAddress] = 0;

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);

        // Note: ERC20 claims don't have a specific DepositId in this model,
        // as we track total balance per user per token.
        emit AssetsClaimed(0, msg.sender, amount); // Use 0 for depositId for ERC20 total claim
    }

     /// @dev Allows a depositor to claim a specific deposited ERC721 token by deposit ID.
    /// Can only be called when the vault is in the Claimable state.
    /// @param depositId The ID of the deposit.
    function claimDepositedERC721(uint64 depositId) external whenNotPaused whenVaultStateIs(VaultState.Claimable) {
        Deposit storage deposit = deposits[depositId];

        if (deposit.depositor == address(0)) revert DepositNotFound(); // Check if deposit exists
        if (deposit.claimed) revert DepositAlreadyClaimed();
        if (deposit.depositor != msg.sender) revert NotDepositor();
        if (deposit.tokenType != 1) revert InvalidVaultState(); // Ensure it's ERC721

        deposit.claimed = true;
        IERC721(deposit.tokenAddress).safeTransferFrom(address(this), msg.sender, deposit.tokenId);

        emit AssetsClaimed(depositId, msg.sender, 1); // Amount is 1 for ERC721
    }

     /// @dev Allows a depositor to claim a specific deposited ERC1155 token by deposit ID.
    /// Can only be called when the vault is in the Claimable state.
    /// @param depositId The ID of the deposit.
    /// @param amount The amount to claim (must be <= deposited amount).
    function claimDepositedERC1155(uint64 depositId, uint256 amount) external whenNotPaused whenVaultStateIs(VaultState.Claimable) {
         Deposit storage deposit = deposits[depositId];

        if (deposit.depositor == address(0)) revert DepositNotFound(); // Check if deposit exists
        if (deposit.claimed) revert DepositAlreadyClaimed(); // This might need refinement for partial claims
        if (deposit.depositor != msg.sender) revert NotDepositor();
        if (deposit.tokenType != 2) revert InvalidVaultState(); // Ensure it's ERC1155
        if (amount == 0 || amount > deposit.amount) revert InvalidClaimAmount();

        // Handle partial claim: Update amount or mark as claimed if full amount
        if (amount == deposit.amount) {
            deposit.claimed = true;
        } else {
            deposit.amount -= amount; // Reduce remaining claimable amount in the deposit struct
            // Note: This models the deposit entry as the *remaining* claimable amount.
            // An alternative is to create a new 'claim' record. This simplifies state.
        }

        IERC1155(deposit.tokenAddress).safeTransferFrom(address(this), msg.sender, deposit.tokenId, amount, "");

        emit AssetsClaimed(depositId, msg.sender, amount);
    }


    // --- Owner Control & Emergency ---

    /// @dev Pauses all sensitive operations (deposits, claims).
    function pauseVault() external onlyOwner whenNotPaused whenVaultStateIsNot(VaultState.EmergencyStop) {
        _pause();
        _transitionState(VaultState.Paused);
    }

    /// @dev Unpauses operations.
    function unpauseVault() external onlyOwner whenVaultStateIs(VaultState.Paused) {
        _unpause();
        // Return to the state it was in before pausing (excluding EmergencyStop)
        if (allEpochsConfigured) {
             _transitionState(VaultState.EpochInProgress); // Or check epoch progress more granularly
        } else {
             _transitionState(VaultState.Locked);
        }
    }

    /// @dev Sets the vault to a terminal Emergency Stop state.
    /// Most operations become unavailable, potentially only owner recovery is possible.
    function emergencyStop() external onlyOwner whenVaultStateIsNot(VaultState.EmergencyStop) {
        _transitionState(VaultState.EmergencyStop);
        emit EmergencyStopActivated();
    }

    // --- View Functions ---

    /// @dev Returns the current state of the vault.
    function getVaultState() external view returns (VaultState) {
        return currentVaultState;
    }

    /// @dev Returns details about the current and total epochs.
    function getEpochDetails() external view returns (uint256 current, uint256 total, uint64 startTime) {
        return (currentEpochIndex, temporalEpochs.length, currentEpochStartTime);
    }

    /// @dev Returns the status of a specific QEP in the current epoch (true if met).
    /// @param qepId The ID of the QEP.
    function getQEPStatus(uint64 qepId) external view returns (bool metForEpoch, bool metGlobally) {
        // Check if this QEP is relevant for the current epoch
        bool isRequiredInEpoch = false;
        if (currentEpochIndex < temporalEpochs.length) {
            TemporalEpoch storage currentEpoch = temporalEpochs[currentEpochIndex];
            for(uint256 i = 0; i < currentEpoch.requiredQEPIds.length; i++) {
                if (currentEpoch.requiredQEPIds[i] == qepId) {
                    isRequiredInEpoch = true;
                    break;
                }
            }
        }

        if (!isRequiredInEpoch) return (false, qepGlobalStatus[qepId]); // QEP not required this epoch, just return global status

        // Return status specific to the current epoch and the global status
        return (currentEpochQEPStatus[qepId], qepGlobalStatus[qepId]);
    }

    /// @dev Returns the QEP configuration details for a specific QEP ID.
    /// @param qepId The ID of the QEP.
    function getQEPConfiguration(uint64 qepId) external view returns (QEPType qepType, bytes32 targetHash, uint256 targetValue, address targetAddress, uint256 targetTokenId) {
        QEP storage qep = qepConfigurations[qepId];
        return (qep.qepType, qep.targetHash, qep.targetValue, qep.targetAddress, qep.targetTokenId);
    }


    /// @dev Returns the list of deposit IDs for a specific user.
    /// @param user The address of the user.
    function getUserDepositIds(address user) external view returns (uint64[] memory) {
        return userDepositIds[user];
    }

    /// @dev Returns the details of a specific deposit.
    /// @param depositId The ID of the deposit.
    function getDepositDetails(uint64 depositId) external view returns (Deposit memory) {
         Deposit storage deposit = deposits[depositId];
         if (deposit.depositor == address(0)) revert DepositNotFound();
         return deposit;
    }

    /// @dev Returns the total amount of a specific ERC20 token deposited by a user.
    /// @param user The address of the user.
    /// @param tokenAddress The address of the ERC20 token.
    function getTotalDepositedERC20(address user, address tokenAddress) external view returns (uint256) {
        return totalDepositedERC20[user][tokenAddress];
    }

    /// @dev Returns the total number of ERC721 deposits recorded.
    /// Note: This doesn't mean they are still in the vault if claimed/withdrawn.
    function getTotalDepositedERC721Count() external view returns (uint256) {
         uint256 count = 0;
         // Iterating mappings is inefficient/impossible directly for total count.
         // A dedicated counter would be needed for exact total active deposits.
         // This view will return the *number of deposit IDs assigned* up to the last deposit
         // that was an ERC721 or ERC1155 (as ERC20 don't increment a token ID specific counter here).
         // A better approach for total count would be to track it separately per type or overall.
         // For simplicity, let's just return the total deposit ID counter value.
         // This counts *all* deposits (ERC20, 721, 1155).
         return _depositIdCounter.current();
    }

    /// @dev Returns the number of distinct ERC1155 token types deposited.
     function getTotalDepositedERC1155Types() external view returns (uint256) {
        // Similar to ERC721, tracking unique types requires iterating or a separate state variable/mapping.
        // This is complex for a view function without iteration.
        // Returning a placeholder or requiring off-chain indexing is more practical.
        // Let's return the total number of deposit IDs as a proxy, acknowledging its limitation.
        return _depositIdCounter.current();
     }

    /// @dev Returns the current version of the contract (simple example).
    function getVersion() external pure returns (string memory) {
        return "QuantumVault V1.0";
    }

     // --- Fallback/Receive ---
     // Optional: Add if you want to accept ETH deposits, but not core to this design.
     // receive() external payable {}
     // fallback() external payable {}
}
```