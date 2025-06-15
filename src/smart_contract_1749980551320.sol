Okay, here is a Solidity smart contract proposal for a "Quantum Key Vault".

This contract goes beyond simple ownership or time locks. It introduces a multi-faceted, condition-based unlocking mechanism that requires meeting several criteria simultaneously, inspired by the idea of a "quantum key" needing specific environmental conditions ("measurements") to reveal its state (unlock the vault). It incorporates concepts like simulated ZK proof verification, on-chain state checks, time dependencies, randomness (via Chainlink VRF placeholder), and delegation.

**Important Considerations:**

*   **ZK Proof Verification:** On-chain ZK verification is complex and gas-intensive. The `_verifyZKProof` function in this example is a *placeholder*. A real implementation would integrate with libraries like `zokrates`, `snarkjs`, or utilize precompiled contracts depending on the proof system (groth16, plonk, etc.).
*   **Oracle Integration:** The `_getOracleData` and `_checkOracleCondition` are placeholders. Real oracle integration (like Chainlink Price Feeds or custom AnyAPI) would involve different patterns (pull vs. push) and security considerations.
*   **Encrypted Data:** Smart contracts cannot perform strong encryption/decryption. The contract stores `bytes` which are *assumed* to be encrypted off-chain by the user. The contract *manages access* to these encrypted bytes. Decryption must happen off-chain after successful retrieval.
*   **Randomness:** Uses a simplified Chainlink VRF integration pattern.
*   **Gas Costs:** Complex logic, especially verifying multiple conditions and potential future ZK integration, will have significant gas costs.
*   **Non-Duplication:** While individual concepts (timelocks, access control, basic data storage) exist, the *combination* into a single, complex conditional unlocking mechanism with the "quantum key" metaphor and the specific set of required checks aims for originality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal interface for Chainlink VRF V2 - for demonstrating the pattern
interface VRFCoordinatorV2Interface {
    function requestRandomWords(
        bytes32 keyHash,
        uint32 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}

abstract contract VRFConsumerBaseV2 {
    constructor(address vrfCoordinator) {}

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual;
}


/**
 * @title QuantumKeyVault
 * @notice A smart contract implementing a complex, multi-faceted access control mechanism for sensitive data,
 * inspired by the concept of a "Quantum Key" requiring specific conditions ("measurements") to unlock.
 * Access to encrypted data is granted only when multiple, potentially disparate conditions are met simultaneously,
 * including time locks, simulated Zero-Knowledge proofs, on-chain state checks, and oracle data requirements.
 * Includes features for vault management, configuration, delegation, and emergency access.
 * The contract stores encrypted data and manages the *conditions* required to retrieve it.
 * Actual encryption/decryption happens off-chain.
 * ZK Proof and Oracle integration are simplified placeholders for demonstration.
 */
contract QuantumKeyVault is VRFConsumerBaseV2 {

    // --- OUTLINE ---
    // 1. State Variables & Constants
    // 2. Enums & Structs
    // 3. Events
    // 4. Modifiers
    // 5. VRF V2 related state & constructor (simplified)
    // 6. Core Vault Management Functions (Create, Configure, Update, Cancel)
    // 7. Conditional Unlock Mechanism Functions (Attempt, Check Conditions, Retrieve)
    // 8. Configuration Update Functions (Time, State Checks, ZK Verifier)
    // 9. Delegation Functions
    // 10. Emergency Functions
    // 11. View Functions (Get State, Config, Owner, Delegation, etc.)
    // 12. Internal/Helper Functions (Condition Checks, ZK/Oracle Simulation)
    // 13. VRF V2 Callback

    // --- FUNCTION SUMMARY ---

    // 1. State Variables & Constants
    // - _vaults: Mapping from vault ID (uint256) to VaultData struct. Stores all vault information.
    // - _vaultOwner: Mapping from vault ID to owner address. Allows independent vault ownership.
    // - _nextVaultId: Counter for generating unique vault IDs.
    // - _unlockDelegations: Mapping from vault ID to delegated address allowed to attempt unlock.
    // - VRF related state: Coordinator address, keyhash, subId, request mapping for VRF.

    // 2. Enums & Structs
    // - VaultState: Enum for vault status (Locked, UnlockingAttempted, Unlocked, Expired, Cancelled).
    // - StateCheck: Struct defining a required on-chain state check (target address, function selector, expected value hash).
    // - UnlockConfig: Struct bundling all conditions needed to unlock (time bounds, ZK proof type/verifier, required state checks, oracle checks, randomness seed/request ID).
    // - VaultData: Struct holding encrypted data, current state, and unlock configuration.

    // 3. Events
    // - VaultCreated(vaultId, owner, initialDataHash): Emitted when a new vault is created.
    // - VaultConfigured(vaultId, configHash): Emitted when unlock conditions are set/updated.
    // - VaultDataUpdated(vaultId, newDataHash): Emitted when vault data is updated.
    // - UnlockAttempted(vaultId, caller, success, reason): Emitted on every unlock attempt.
    // - VaultUnlocked(vaultId, unlocker): Emitted when a vault is successfully unlocked.
    // - VaultRelocked(vaultId, relocker): Emitted when a vault is relocked.
    // - VaultDataRetrieved(vaultId, retriever): Emitted when encrypted data is successfully retrieved.
    // - VaultOwnershipTransferred(vaultId, oldOwner, newOwner): Emitted on ownership transfer.
    // - UnlockDelegationSet(vaultId, delegatee): Emitted when delegation is set.
    // - UnlockDelegationRevoked(vaultId, delegatee): Emitted when delegation is revoked.
    // - EmergencyUnlocked(vaultId, emergencyTrigger): Emitted on emergency unlock.
    // - VaultCancelled(vaultId, canceller): Emitted when a vault is cancelled.
    // - VRFRandomnessRequested(vaultId, requestId): Emitted when VRF randomness is requested for a vault key.
    // - VRFRandomnessReceived(vaultId, requestId, randomWord): Emitted when VRF callback provides randomness.

    // 4. Modifiers
    // - vaultExists(vaultId): Checks if a vault with the given ID exists.
    // - isVaultOwner(vaultId): Checks if the caller is the owner of the specific vault.
    // - onlyVaultOwnerOrDelegate(vaultId): Checks if caller is owner OR delegated address.
    // - vaultInState(vaultId, state): Checks if the vault is in a specific state.

    // 5. VRF V2 related state & constructor
    // - VRFCoordinatorV2Interface coordinator: Chainlink VRF coordinator contract instance.
    // - bytes32 s_keyHash: Key hash for VRF requests.
    // - uint64 s_subscriptionId: Subscription ID for VRF requests.
    // - mapping(uint256 => uint256) s_vaultIdToRequestId: Maps vault ID to VRF request ID.
    // - mapping(uint256 => uint256) s_requestIdToVaultId: Maps VRF request ID back to vault ID.
    // - mapping(uint256 => uint256[]) s_vaultIdToRandomWords: Stores received random words for a vault.
    // - Constructor: Initializes owner, VRF coordinator address, keyhash, and subscription ID.

    // 6. Core Vault Management Functions
    // - createVault(encryptedData): Creates a new vault, stores encrypted data, assigns owner and ID. Returns vault ID.
    // - configureUnlockKey(vaultId, config): Sets/updates the UnlockConfig for a vault. Callable by owner.
    // - updateVaultData(vaultId, newEncryptedData): Updates the encrypted data stored in the vault. Callable by owner when locked.
    // - cancelVault(vaultId): Cancels the vault, effectively destroying access and data reference. Callable by owner.

    // 7. Conditional Unlock Mechanism Functions
    // - requestKeyRandomness(vaultId): Requests random words via VRF to potentially influence unlock conditions (e.g., threshold, specific state index). Callable by owner before configuring key.
    // - checkUnlockConditions(vaultId, zkProofBytes, oracleDataBytes): Public view function. Checks if all conditions *currently* seem met based on provided dynamic data (ZK proof, oracle data). Does NOT change vault state. Returns bool and a status code/reason.
    // - attemptUnlock(vaultId, zkProofBytes, oracleDataBytes): The core function. Attempts to unlock the vault. Verifies all conditions using internal helpers. If successful, changes state to Unlocked and emits event. Requires vault owner or delegate.
    // - retrieveVaultData(vaultId): Retrieves the stored encrypted data. Only allowed if vault is in Unlocked state and caller is owner.
    // - relockVault(vaultId): Changes vault state back to Locked. Callable by owner after unlocking.

    // 8. Configuration Update Functions
    // - extendUnlockTime(vaultId, newUnlockAfter, newUnlockBefore): Extends or modifies the time boundaries for unlocking. Callable by owner.
    // - addRequiredStateCheck(vaultId, targetAddress, functionSelector, expectedValueHash): Adds another on-chain state check requirement to the key configuration. Callable by owner.
    // - removeRequiredStateCheck(vaultId, index): Removes a state check requirement by index. Callable by owner.
    // - setZKProofVerifier(vaultId, verifierType, verifierAddress): Sets/updates the parameters for ZK proof verification. Callable by owner.
    // - updateOracleCondition(vaultId, oracleAddress, checkType, thresholdHash): Updates the oracle data check requirement. Callable by owner. (Placeholder)

    // 9. Delegation Functions
    // - delegateUnlockAttempt(vaultId, delegatee): Delegates the right to call `attemptUnlock` for this vault to another address. Callable by owner.
    // - revokeUnlockDelegation(vaultId): Revokes any existing unlock delegation for the vault. Callable by owner.

    // 10. Emergency Functions
    // - emergencyUnlock(vaultId): Allows the contract owner (or a designated emergency role, simplified here to owner) to bypass all conditions and unlock the vault. Callable by contract owner.

    // 11. View Functions
    // - getVaultState(vaultId): Returns the current state of a vault.
    // - getVaultOwner(vaultId): Returns the owner address of a vault.
    // - getUnlockConfig(vaultId): Returns the UnlockConfig struct for a vault.
    // - getVaultDataHash(vaultId): Returns the hash of the stored encrypted data (to avoid revealing data in a view function).
    // - isUnlockDelegated(vaultId): Returns true if unlock is delegated for this vault.
    // - getDelegatedAddress(vaultId): Returns the delegated address for a vault.
    // - getRequiredStateChecks(vaultId): Returns the array of StateCheck structs for a vault.
    // - getVaultRandomness(vaultId): Returns the received random words for a vault's key configuration.

    // 12. Internal/Helper Functions
    // - _checkUnlockConditionsInternal(vaultId, zkProofBytes, oracleDataBytes): Internal helper combining all checks.
    // - _checkTimeCondition(vaultId): Checks if the current time is within the configured time bounds.
    // - _checkZKCondition(vaultId, zkProofBytes): Placeholder for verifying ZK proof bytes against the configuration.
    // - _checkStateConditions(vaultId): Iterates through required StateCheck structs and performs on-chain calls/checks. (Placeholder for dynamic calls)
    // - _checkOracleCondition(vaultId, oracleDataBytes): Placeholder for verifying oracle data proof/signature against configuration.
    // - _verifyZKProof(verifierType, verifierAddress, proofBytes): Placeholder simulating ZK proof verification logic. Returns bool.
    // - _performStateCheck(targetAddress, functionSelector, expectedValueHash): Placeholder for making an external call and verifying the result's hash. Returns bool.
    // - _getOracleData(oracleAddress, checkType, thresholdHash, oracleDataBytes): Placeholder simulating oracle data verification. Returns bool.

    // 13. VRF V2 Callback
    // - fulfillRandomWords(requestId, randomWords): VRF callback function to receive and store randomness.


    // --- State Variables ---
    mapping(uint252 => VaultData) private _vaults; // Using uint252 to save a tiny bit of gas on mapping keys
    mapping(uint252 => address) private _vaultOwner;
    uint252 private _nextVaultId = 1;
    mapping(uint252 => address) private _unlockDelegations; // Vault ID to delegated address

    // VRF V2 variables (Simplified integration)
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    bytes32 immutable i_keyHash;
    uint64 immutable i_subscriptionId;

    // Mapping from VRF request ID to vault ID
    mapping(uint256 => uint252) private s_requestIdToVaultId;
    // Mapping from vault ID to received random words
    mapping(uint252 => uint256[]) private s_vaultIdToRandomWords;

    // --- Enums ---
    enum VaultState {
        Locked,              // Default state, conditions must be met
        UnlockingAttempted,  // Intermediate state during attempt (less useful for this sync model, more for async)
        Unlocked,            // Successfully unlocked, data retrievable
        Expired,             // Timelock expired (if beforeTime is set and passed)
        Cancelled            // Vault has been cancelled by owner
    }

    // --- Structs ---
    struct StateCheck {
        address targetContract;    // Address of the contract to query
        bytes4 functionSelector;   // The first 4 bytes of the function's signature (e.g., bytes4(keccak256("getValue(uint256)")))
        bytes expectedValueHash;   // Hash of the value expected from the function call result (or encoded result). Using hash to avoid storing sensitive 'expectedValue' directly.
                                   // In a real scenario, this might involve complex encoding/decoding or specific proof formats.
    }

     struct OracleCheck {
        address oracleAddress; // Address of the oracle contract
        bytes checkDataHash;   // Hash of specific data/parameters for the oracle query/check
        bytes expectedResultHash; // Hash of the expected result from the oracle
        // More fields might be needed depending on oracle type (e.g., proof type, timestamp tolerance)
     }


    struct UnlockConfig {
        uint64 unlockAfter;      // Unix timestamp: cannot unlock before this time
        uint64 unlockBefore;     // Unix timestamp: cannot unlock after this time (0 for no upper limit)
        bytes zkProofVerifierType; // Identifier for the type of ZK proof system/verifier
        address zkProofVerifierAddress; // Address of the verifier contract/precompile (placeholder)
        StateCheck[] requiredStateChecks; // Array of on-chain state conditions that must be true
        OracleCheck[] requiredOracleChecks; // Array of off-chain data conditions verified via oracle/proof (placeholder)
        uint256 vrfRequestId;    // The ID of the VRF request associated with this key configuration (0 if none)
        uint256 randomnessThreshold; // A threshold derived from VRF randomness, used in some condition
        bytes32 configHash;      // Hash of this configuration struct for integrity checks
    }

    struct VaultData {
        bytes encryptedData;     // The actual encrypted data payload
        VaultState currentState;   // Current state of the vault
        UnlockConfig unlockKey;    // Configuration required to unlock
        uint64 lastUnlockAttempt;  // Timestamp of the last unlock attempt
        address lastUnlocker;      // Address of the last address that attempted unlock
    }

    // --- Events ---
    event VaultCreated(uint252 indexed vaultId, address indexed owner, bytes32 initialDataHash);
    event VaultConfigured(uint252 indexed vaultId, bytes32 configHash);
    event VaultDataUpdated(uint252 indexed vaultId, bytes32 newDataHash);
    event UnlockAttempted(uint252 indexed vaultId, address indexed caller, bool success, string reason);
    event VaultUnlocked(uint252 indexed vaultId, address indexed unlocker);
    event VaultRelocked(uint252 indexed vaultId, address indexed relocker);
    event VaultDataRetrieved(uint252 indexed vaultId, address indexed retriever);
    event VaultOwnershipTransferred(uint252 indexed vaultId, address indexed oldOwner, address indexed newOwner);
    event UnlockDelegationSet(uint252 indexed vaultId, address indexed delegatee);
    event UnlockDelegationRevoked(uint252 indexed vaultId, address indexed delegatee);
    event EmergencyUnlocked(uint252 indexed vaultId, address indexed emergencyTrigger);
    event VaultCancelled(uint252 indexed vaultId, address indexed canceller);
    event VRFRandomnessRequested(uint252 indexed vaultId, uint256 indexed requestId);
    event VRFRandomnessReceived(uint252 indexed vaultId, uint256 indexed requestId, uint256 randomWord);

    // --- Modifiers ---
    modifier vaultExists(uint252 _vaultId) {
        require(_vaultOwner[_vaultId] != address(0), "Vault does not exist");
        _;
    }

    modifier isVaultOwner(uint252 _vaultId) {
        require(_vaultOwner[_vaultId] == msg.sender, "Caller is not the vault owner");
        _;
    }

     modifier onlyVaultOwnerOrDelegate(uint252 _vaultId) {
        require(
            _vaultOwner[_vaultId] == msg.sender || _unlockDelegations[_vaultId] == msg.sender,
            "Caller is not vault owner or delegated address"
        );
        _;
    }

    modifier vaultInState(uint252 _vaultId, VaultState _state) {
        require(_vaults[_vaultId].currentState == _state, "Vault is not in the required state");
        _;
    }

    // --- Constructor ---
    // @dev _vrfCoordinator, _keyHash, _subId are for simplified Chainlink VRF integration
    constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subId)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        require(_vrfCoordinator != address(0), "Invalid VRF coordinator address");
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subId;
    }

    // --- Core Vault Management ---

    /**
     * @notice Creates a new vault to store encrypted data.
     * @param _encryptedData The data to store, assumed to be encrypted off-chain.
     * @return vaultId The unique ID of the newly created vault.
     */
    function createVault(bytes calldata _encryptedData) external returns (uint252 vaultId) {
        vaultId = _nextVaultId++;
        _vaultOwner[vaultId] = msg.sender;
        _vaults[vaultId] = VaultData({
            encryptedData: _encryptedData,
            currentState: VaultState.Locked,
            unlockKey: UnlockConfig({
                unlockAfter: 0,
                unlockBefore: 0,
                zkProofVerifierType: "", // Default empty
                zkProofVerifierAddress: address(0), // Default empty
                requiredStateChecks: new StateCheck[](0),
                requiredOracleChecks: new OracleCheck[](0),
                vrfRequestId: 0, // No VRF requested yet
                randomnessThreshold: 0, // No randomness yet
                configHash: bytes32(0) // Not configured yet
            }),
            lastUnlockAttempt: 0,
            lastUnlocker: address(0)
        });

        emit VaultCreated(vaultId, msg.sender, keccak256(_encryptedData));
    }

    /**
     * @notice Configures or updates the complex unlock key (conditions) for a vault.
     * @param _vaultId The ID of the vault.
     * @param _config The UnlockConfig struct containing all conditions.
     */
    function configureUnlockKey(uint252 _vaultId, UnlockConfig memory _config)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Locked) // Can only configure key when locked
    {
        // Basic validation for time bounds
        require(_config.unlockAfter <= _config.unlockBefore || _config.unlockBefore == 0, "Invalid time bounds");

        // Calculate a hash of the config for integrity/tracking
        // Hashing complex structs directly is tricky, do it manually or use helper.
        // For simplicity here, we'll just use a placeholder or a hash of key fields.
        // A robust implementation would hash all relevant fields deterministically.
        _config.configHash = keccak256(abi.encode(_config.unlockAfter, _config.unlockBefore, _config.zkProofVerifierType, _config.zkProofVerifierAddress, _config.requiredStateChecks, _config.requiredOracleChecks, _config.vrfRequestId, _config.randomnessThreshold));

        _vaults[_vaultId].unlockKey = _config;

        emit VaultConfigured(_vaultId, _config.configHash);
    }

    /**
     * @notice Updates the encrypted data stored in the vault.
     * @param _vaultId The ID of the vault.
     * @param _newEncryptedData The new encrypted data.
     */
    function updateVaultData(uint252 _vaultId, bytes calldata _newEncryptedData)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Locked) // Data can only be updated when locked
    {
        _vaults[_vaultId].encryptedData = _newEncryptedData;
        emit VaultDataUpdated(_vaultId, keccak256(_newEncryptedData));
    }

    /**
     * @notice Cancels a vault, making it inaccessible.
     * @param _vaultId The ID of the vault.
     */
    function cancelVault(uint252 _vaultId)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
    {
        // Reset sensitive data and mark as cancelled
        delete _vaults[_vaultId].encryptedData; // Attempt to remove data reference
        _vaults[_vaultId].currentState = VaultState.Cancelled;
        // Clear delegations and config might also be desirable depending on desired final state
        delete _unlockDelegations[_vaultId];
        delete _vaults[_vaultId].unlockKey; // Clear config

        emit VaultCancelled(_vaultId, msg.sender);
    }

    // --- Conditional Unlock Mechanism ---

    /**
     * @notice Requests randomness from Chainlink VRF for key configuration.
     * @dev The received randomness can be used when configuring the UnlockKey later,
     *      e.g., to determine thresholds or indices for checks probabilistically.
     * @param _vaultId The ID of the vault for which randomness is requested.
     */
    function requestKeyRandomness(uint252 _vaultId)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
        returns (uint256 requestId)
    {
        // Prevent requesting multiple times for the same key config process if needed.
        // Or allow requesting, but only the last one before config is used.
        // Simplification: Allow request, associate with vault. Config uses the *last* received.
        requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            // Adjust these parameters based on Chainlink VRF best practices and costs
            1, // requestConfirmations
            300000, // callbackGasLimit
            1 // numWords - request just one word for simplicity
        );
        s_requestIdToVaultId[requestId] = _vaultId;
        emit VRFRandomnessRequested(_vaultId, requestId);
    }

    /**
     * @notice Checks if the conditions for unlocking a vault are currently met.
     * @dev This is a view function and does NOT change the vault state.
     * Useful for users/applications to check unlock possibility beforehand.
     * @param _vaultId The ID of the vault.
     * @param _zkProofBytes Placeholder bytes for ZK proof data.
     * @param _oracleDataBytes Placeholder bytes for oracle data proof/signature.
     * @return isMet True if all conditions are met.
     * @return reason A string indicating which condition failed if isMet is false.
     */
    function checkUnlockConditions(
        uint252 _vaultId,
        bytes calldata _zkProofBytes,
        bytes calldata _oracleDataBytes
    )
        external
        view
        vaultExists(_vaultId)
        returns (bool isMet, string memory reason)
    {
        // Cannot check conditions if vault is not configured or is in a final state
         VaultData storage vault = _vaults[_vaultId];
         if (vault.currentState != VaultState.Locked) {
             return (false, "Vault is not in Locked state");
         }
         if (vault.unlockKey.configHash == bytes32(0)) {
              return (false, "Vault unlock key is not configured");
         }

        // Perform all checks
        (bool timeOk, string memory timeReason) = _checkTimeCondition(_vaultId);
        if (!timeOk) return (false, timeReason);

        (bool zkOk, string memory zkReason) = _checkZKCondition(_vaultId, _zkProofBytes);
        if (!zkOk) return (false, zkReason);

        (bool stateOk, string memory stateReason) = _checkStateConditions(_vaultId);
        if (!stateOk) return (false, stateReason);

        (bool oracleOk, string memory oracleReason) = _checkOracleCondition(_vaultId, _oracleDataBytes);
        if (!oracleOk) return (false, oracleReason);

        // All checks passed
        return (true, "All conditions met");
    }


    /**
     * @notice Attempts to unlock the vault by verifying all required conditions.
     * @param _vaultId The ID of the vault.
     * @param _zkProofBytes Placeholder bytes for ZK proof data.
     * @param _oracleDataBytes Placeholder bytes for oracle data proof/signature.
     */
    function attemptUnlock(
        uint252 _vaultId,
        bytes calldata _zkProofBytes,
        bytes calldata _oracleDataBytes
    )
        external
        onlyVaultOwnerOrDelegate(_vaultId)
        vaultExists(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
        _vaults[_vaultId].currentState = VaultState.UnlockingAttempted; // Set intermediate state
        _vaults[_vaultId].lastUnlockAttempt = uint64(block.timestamp);
        _vaults[_vaultId].lastUnlocker = msg.sender;

        (bool allConditionsMet, string memory reason) = _checkUnlockConditionsInternal(_vaultId, _zkProofBytes, _oracleDataBytes);

        if (allConditionsMet) {
            _vaults[_vaultId].currentState = VaultState.Unlocked;
            emit UnlockAttempted(_vaultId, msg.sender, true, "Success");
            emit VaultUnlocked(_vaultId, msg.sender);
        } else {
            _vaults[_vaultId].currentState = VaultState.Locked; // Revert to locked if attempt failed
            emit UnlockAttempted(_vaultId, msg.sender, false, reason);
            revert(string(abi.encodePacked("Unlock failed: ", reason)));
        }
    }

    /**
     * @notice Retrieves the encrypted data from an unlocked vault.
     * @param _vaultId The ID of the vault.
     * @return encryptedData The stored encrypted data.
     */
    function retrieveVaultData(uint252 _vaultId)
        external
        view
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Unlocked) // Only retrieve when unlocked
        returns (bytes memory encryptedData)
    {
        // IMPORTANT: This returns the *encrypted* data. Decryption happens off-chain.
        emit VaultDataRetrieved(_vaultId, msg.sender); // Event for tracking retrieval, even from view
        return _vaults[_vaultId].encryptedData;
    }

    /**
     * @notice Relocks an unlocked vault.
     * @param _vaultId The ID of the vault.
     */
    function relockVault(uint252 _vaultId)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Unlocked)
    {
        _vaults[_vaultId].currentState = VaultState.Locked;
        emit VaultRelocked(_vaultId, msg.sender);
    }

    // --- Configuration Update Functions ---

    /**
     * @notice Updates the time window for unlocking.
     * @param _vaultId The ID of the vault.
     * @param _newUnlockAfter The new start timestamp.
     * @param _newUnlockBefore The new end timestamp (0 for no end).
     */
    function extendUnlockTime(uint252 _vaultId, uint64 _newUnlockAfter, uint64 _newUnlockBefore)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
        require(_newUnlockAfter <= _newUnlockBefore || _newUnlockBefore == 0, "Invalid new time bounds");
        _vaults[_vaultId].unlockKey.unlockAfter = _newUnlockAfter;
        _vaults[_vaultId].unlockKey.unlockBefore = _newUnlockBefore;
        // Optionally re-calculate configHash
        emit VaultConfigured(_vaultId, keccak256(abi.encode(_vaults[_vaultId].unlockKey))); // Re-emit config event
    }

    /**
     * @notice Adds a required on-chain state check to the unlock conditions.
     * @param _vaultId The ID of the vault.
     * @param _targetAddress The address of the contract to check.
     * @param _functionSelector The bytes4 selector of the view function to call.
     * @param _expectedValueHash The hash of the expected return value.
     */
    function addRequiredStateCheck(uint252 _vaultId, address _targetAddress, bytes4 _functionSelector, bytes calldata _expectedValueHash)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
        require(_targetAddress != address(0), "Invalid target address");
        require(_functionSelector != bytes4(0), "Invalid function selector");
        require(_expectedValueHash.length > 0, "Invalid expected value hash");

        _vaults[_vaultId].unlockKey.requiredStateChecks.push(StateCheck({
            targetContract: _targetAddress,
            functionSelector: _functionSelector,
            expectedValueHash: _expectedValueHash
        }));
        // Optionally re-calculate configHash
        emit VaultConfigured(_vaultId, keccak256(abi.encode(_vaults[_vaultId].unlockKey))); // Re-emit config event
    }

     /**
     * @notice Removes a required on-chain state check from the unlock conditions by index.
     * @param _vaultId The ID of the vault.
     * @param _index The index of the state check to remove.
     */
    function removeRequiredStateCheck(uint252 _vaultId, uint256 _index)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
        StateCheck[] storage checks = _vaults[_vaultId].unlockKey.requiredStateChecks;
        require(_index < checks.length, "Invalid index");

        // Shift elements to fill the gap (common pattern for removing from dynamic array)
        for (uint256 i = _index; i < checks.length - 1; i++) {
            checks[i] = checks[i + 1];
        }
        checks.pop();

        // Optionally re-calculate configHash
        emit VaultConfigured(_vaultId, keccak256(abi.encode(_vaults[_vaultId].unlockKey))); // Re-emit config event
    }


    /**
     * @notice Sets or updates the parameters for ZK proof verification.
     * @dev This is a placeholder; a real implementation needs a verifiable system.
     * @param _vaultId The ID of the vault.
     * @param _verifierType Identifier for the ZK proof system/verifier.
     * @param _verifierAddress Address of the verifier contract/precompile.
     */
    function setZKProofVerifier(uint252 _vaultId, bytes calldata _verifierType, address _verifierAddress)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
        vaultInState(_vaultId, VaultState.Locked)
    {
         _vaults[_vaultId].unlockKey.zkProofVerifierType = _verifierType;
         _vaults[_vaultId].unlockKey.zkProofVerifierAddress = _verifierAddress;
         // Optionally re-calculate configHash
         emit VaultConfigured(_vaultId, keccak256(abi.encode(_vaults[_vaultId].unlockKey))); // Re-emit config event
    }

     /**
     * @notice Updates the oracle data check requirement.
     * @dev This is a placeholder; a real implementation needs a verifiable oracle feed.
     * @param _vaultId The ID of the vault.
     * @param _oracleAddress Address of the oracle contract.
     * @param _checkDataHash Hash of specific data/parameters for the oracle query/check.
     * @param _expectedResultHash Hash of the expected result.
     */
    function updateOracleCondition(uint252 _vaultId, address _oracleAddress, bytes calldata _checkDataHash, bytes calldata _expectedResultHash)
         external
         vaultExists(_vaultId)
         isVaultOwner(_vaultId)
         vaultInState(_vaultId, VaultState.Locked)
    {
         // Simplified: Just replaces any existing oracle checks with this single one
         _vaults[_vaultId].unlockKey.requiredOracleChecks = new OracleCheck[](1);
         _vaults[_vaultId].unlockKey.requiredOracleChecks[0] = OracleCheck({
              oracleAddress: _oracleAddress,
              checkDataHash: _checkDataHash,
              expectedResultHash: _expectedResultHash
         });
          // Optionally re-calculate configHash
         emit VaultConfigured(_vaultId, keccak256(abi.encode(_vaults[_vaultId].unlockKey))); // Re-emit config event
    }


    // --- Delegation Functions ---

    /**
     * @notice Delegates the right to call `attemptUnlock` for this vault.
     * @param _vaultId The ID of the vault.
     * @param _delegatee The address to delegate unlock attempts to. Address(0) to revoke existing delegation.
     */
    function delegateUnlockAttempt(uint252 _vaultId, address _delegatee)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
    {
        require(_delegatee != msg.sender, "Cannot delegate to yourself");
        _unlockDelegations[_vaultId] = _delegatee;
        emit UnlockDelegationSet(_vaultId, _delegatee);
    }

    /**
     * @notice Revokes any existing unlock delegation for a vault.
     * @param _vaultId The ID of the vault.
     */
    function revokeUnlockDelegation(uint252 _vaultId)
        external
        vaultExists(_vaultId)
        isVaultOwner(_vaultId)
    {
        address delegatee = _unlockDelegations[_vaultId];
        delete _unlockDelegations[_vaultId];
        emit UnlockDelegationRevoked(_vaultId, delegatee);
    }


    // --- Emergency Functions ---

    /**
     * @notice Allows the contract owner (or a designated emergency role) to bypass all conditions and unlock a vault.
     * @dev This is a powerful function and should be used with caution.
     * @param _vaultId The ID of the vault.
     */
    function emergencyUnlock(uint252 _vaultId)
         external
         vaultExists(_vaultId)
         onlyOwner // Assuming the contract itself has an Ownable pattern, using a placeholder here.
                  // A more robust system might have a separate emergency role.
         vaultInState(_vaultId, VaultState.Locked)
    {
         _vaults[_vaultId].currentState = VaultState.Unlocked;
         emit EmergencyUnlocked(_vaultId, msg.sender);
         emit VaultUnlocked(_vaultId, msg.sender); // Also emit standard unlock event
    }


    // --- View Functions ---

    /**
     * @notice Gets the current state of a vault.
     * @param _vaultId The ID of the vault.
     * @return state The current VaultState.
     */
    function getVaultState(uint252 _vaultId) external view vaultExists(_vaultId) returns (VaultState state) {
        return _vaults[_vaultId].currentState;
    }

     /**
     * @notice Gets the owner address of a vault.
     * @param _vaultId The ID of the vault.
     * @return ownerAddress The owner's address.
     */
    function getVaultOwner(uint252 _vaultId) external view vaultExists(_vaultId) returns (address ownerAddress) {
        return _vaultOwner[_vaultId];
    }

    /**
     * @notice Gets the unlock configuration for a vault.
     * @param _vaultId The ID of the vault.
     * @return config The UnlockConfig struct.
     */
    function getUnlockConfig(uint252 _vaultId) external view vaultExists(_vaultId) returns (UnlockConfig memory config) {
        return _vaults[_vaultId].unlockKey;
    }

     /**
     * @notice Gets the hash of the stored encrypted data.
     * @dev Returns bytes32(0) if data is deleted (e.g., after cancel).
     * @param _vaultId The ID of the vault.
     * @return dataHash The keccak256 hash of the encrypted data.
     */
    function getVaultDataHash(uint252 _vaultId) external view vaultExists(_vaultId) returns (bytes32 dataHash) {
        // Return hash 0 if data was cleared (e.g., cancelled vault)
        if (_vaults[_vaultId].encryptedData.length == 0 && _vaults[_vaultId].currentState == VaultState.Cancelled) {
            return bytes32(0);
        }
        return keccak256(_vaults[_vaultId].encryptedData);
    }

    /**
     * @notice Checks if unlock attempts are delegated for a vault.
     * @param _vaultId The ID of the vault.
     * @return isDelegated True if delegated.
     */
    function isUnlockDelegated(uint252 _vaultId) external view vaultExists(_vaultId) returns (bool isDelegated) {
         return _unlockDelegations[_vaultId] != address(0);
    }

    /**
     * @notice Gets the delegated address for a vault, if any.
     * @param _vaultId The ID of the vault.
     * @return delegatee The delegated address (address(0) if none).
     */
    function getDelegatedAddress(uint252 _vaultId) external view vaultExists(_vaultId) returns (address delegatee) {
         return _unlockDelegations[_vaultId];
    }

    /**
     * @notice Gets the array of required on-chain state checks for a vault.
     * @param _vaultId The ID of the vault.
     * @return checks The array of StateCheck structs.
     */
    function getRequiredStateChecks(uint252 _vaultId) external view vaultExists(_vaultId) returns (StateCheck[] memory checks) {
         return _vaults[_vaultId].unlockKey.requiredStateChecks;
    }

     /**
     * @notice Gets the random words received via VRF for a vault's key configuration.
     * @param _vaultId The ID of the vault.
     * @return randomWords The array of random words.
     */
    function getVaultRandomness(uint252 _vaultId) external view vaultExists(_vaultId) returns (uint256[] memory randomWords) {
         return s_vaultIdToRandomWords[_vaultId];
    }

     /**
     * @notice Gets the timestamp of the last unlock attempt for a vault.
     * @param _vaultId The ID of the vault.
     * @return timestamp The timestamp (0 if no attempts).
     */
    function getLastUnlockAttemptTime(uint252 _vaultId) external view vaultExists(_vaultId) returns (uint64 timestamp) {
        return _vaults[_vaultId].lastUnlockAttempt;
    }

     /**
     * @notice Gets the address that last attempted to unlock a vault.
     * @param _vaultId The ID of the vault.
     * @return unlocker The address (address(0) if no attempts).
     */
    function getLastUnlocker(uint252 _vaultId) external view vaultExists(_vaultId) returns (address unlocker) {
        return _vaults[_vaultId].lastUnlocker;
    }


    // --- Internal/Helper Functions ---

    /**
     * @notice Internal helper to perform all unlock condition checks.
     * @param _vaultId The ID of the vault.
     * @param _zkProofBytes Placeholder bytes for ZK proof data.
     * @param _oracleDataBytes Placeholder bytes for oracle data proof/signature.
     * @return isMet True if all conditions are met.
     * @return reason A string indicating which condition failed if isMet is false.
     */
    function _checkUnlockConditionsInternal(
        uint252 _vaultId,
        bytes calldata _zkProofBytes,
        bytes calldata _oracleDataBytes
    )
        internal
        view
        returns (bool isMet, string memory reason)
    {
        VaultData storage vault = _vaults[_vaultId];
        UnlockConfig storage key = vault.unlockKey;

        // 1. Time Condition
        (bool timeOk, string memory timeReason) = _checkTimeCondition(_vaultId);
        if (!timeOk) return (false, timeReason);

        // 2. ZK Proof Condition (if configured)
        if (key.zkProofVerifierAddress != address(0)) {
             (bool zkOk, string memory zkReason) = _checkZKCondition(_vaultId, _zkProofBytes);
             if (!zkOk) return (false, zkReason);
        }

        // 3. On-chain State Conditions
        (bool stateOk, string memory stateReason) = _checkStateConditions(_vaultId);
        if (!stateOk) return (false, stateReason);

        // 4. Oracle Data Conditions
        (bool oracleOk, string memory oracleReason) = _checkOracleCondition(_vaultId, _oracleDataBytes);
        if (!oracleOk) return (false, oracleReason);

        // 5. Randomness-based Condition (Example: check if a random threshold was met)
        // This is a simplified example. Randomness might influence other checks.
        if (key.vrfRequestId != 0) {
             uint256[] storage randomWords = s_vaultIdToRandomWords[_vaultId];
             // Ensure randomness has been received
             if (randomWords.length == 0 || s_requestIdToVaultId[key.vrfRequestId] != _vaultId) {
                  return (false, "Randomness not received for key configuration");
             }
             // Example: Check if the first random word is above a set threshold derived from config
             // The actual check using randomness would be defined by the UnlockConfig
             // require(key.randomnessThreshold > 0, "Random threshold not set for VRF key"); // Ensure threshold is set if VRF is used
             // if (randomWords[0] < key.randomnessThreshold) {
             //     return (false, "Randomness threshold condition not met");
             // }
             // Simplified example: require random word is even
              if (randomWords[0] % 2 != 0) {
                 return (false, "Randomness parity condition not met (example)");
              }

        }


        // All checks passed
        return (true, "Success");
    }

    /**
     * @notice Checks if the current time is within the configured window.
     * @param _vaultId The ID of the vault.
     * @return isMet True if time condition is met.
     * @return reason A string indicating failure reason.
     */
    function _checkTimeCondition(uint252 _vaultId)
        internal
        view
        returns (bool isMet, string memory reason)
    {
        uint64 currentTime = uint64(block.timestamp);
        UnlockConfig storage key = _vaults[_vaultId].unlockKey;

        if (key.unlockAfter > 0 && currentTime < key.unlockAfter) {
            return (false, "Timelock: Unlock time not reached");
        }
        if (key.unlockBefore > 0 && currentTime > key.unlockBefore) {
             // Optionally set state to Expired here if it's a non-view function
            return (false, "Timelock: Vault expired");
        }
        return (true, "Time condition met");
    }

    /**
     * @notice Placeholder for ZK proof verification.
     * @dev This function needs to be replaced with a real ZK verifier integration.
     * Assumes the proofBytes, verifierType, and verifierAddress are sufficient.
     * @param _vaultId The ID of the vault.
     * @param _zkProofBytes The raw bytes of the ZK proof.
     * @return isMet True if ZK proof is valid.
     * @return reason A string indicating failure reason.
     */
    function _checkZKCondition(uint252 _vaultId, bytes calldata _zkProofBytes)
        internal
        view
        returns (bool isMet, string memory reason)
    {
        UnlockConfig storage key = _vaults[_vaultId].unlockKey;
        if (key.zkProofVerifierAddress == address(0)) {
             // No ZK check configured, condition is met
             return (true, "No ZK check configured");
        }

        // --- ZK VERIFICATION PLACEHOLDER ---
        // In a real contract, this would involve:
        // 1. Calling a precompiled contract (e.g., BN254/BLS12_381 pairings)
        // 2. Calling an external verifier contract
        // 3. Using an off-chain prover and on-chain verifier library
        // The structure of _zkProofBytes depends entirely on the ZK system used.

        if (_zkProofBytes.length == 0) {
            return (false, "ZK Proof required but not provided");
        }

        // Simplified check: Assume proofBytes simply needs to match a stored hash or satisfy a simple property
        // e.g. keccak256(_zkProofBytes) == storedProofHash
        // or call a placeholder verifier contract
        bool proofIsValid = _verifyZKProof(key.zkProofVerifierType, key.zkProofVerifierAddress, _zkProofBytes);
        // ---------------------------------

        if (!proofIsValid) {
            return (false, "ZK Proof verification failed");
        }

        return (true, "ZK condition met");
    }

    /**
     * @notice Placeholder simulation of calling a ZK verifier.
     * @dev Replace with actual ZK verification logic.
     * @param _verifierType Identifier for the ZK proof system/verifier.
     * @param _verifierAddress Address of the verifier contract/precompile.
     * @param _proofBytes The raw bytes of the ZK proof.
     * @return True if the proof is considered valid by this placeholder.
     */
    function _verifyZKProof(bytes memory _verifierType, address _verifierAddress, bytes memory _proofBytes)
         internal
         pure // Using pure as it's a placeholder, real one would interact
         returns (bool)
    {
         // This is a MOCK function. Replace with actual ZK verification.
         // Example: require(_verifierAddress != address(0), "ZK verifier address not set");
         // Example: bool verified = MyZKVerifier(_verifierAddress).verify(_proofBytes, publicInputs);
         // For this example, we just check if proofBytes has *some* data.
         return _proofBytes.length > 10; // Arbitrary check for demo
    }


    /**
     * @notice Checks all required on-chain state conditions.
     * @dev Placeholder using static checks. Real implementation needs dynamic calls.
     * @param _vaultId The ID of the vault.
     * @return isMet True if all state conditions are met.
     * @return reason A string indicating failure reason.
     */
    function _checkStateConditions(uint252 _vaultId)
        internal
        view
        returns (bool isMet, string memory reason)
    {
        StateCheck[] storage checks = _vaults[_vaultId].unlockKey.requiredStateChecks;
        if (checks.length == 0) {
            return (true, "No state checks configured");
        }

        for (uint256 i = 0; i < checks.length; i++) {
            StateCheck storage check = checks[i];
            // --- STATE CHECK PLACEHOLDER ---
            // In a real contract, this requires dynamic contract calls.
            // Example using low-level call (careful with reentrancy, although less risk for view calls):
            // (bool success, bytes memory returnData) = check.targetContract.staticcall(check.functionSelector);
            // if (!success) return (false, string(abi.encodePacked("State check failed (call failed) at index ", Strings.toString(i))));
            // if (keccak256(returnData) != keccak256(check.expectedValueHash)) { // Compare hash of actual return data
            //     return (false, string(abi.encodePacked("State check failed (value mismatch) at index ", Strings.toString(i))));
            // }

            // Simplified check: Call a placeholder function that simulates checking
            bool stateOk = _performStateCheck(check.targetContract, check.functionSelector, check.expectedValueHash);
            if (!stateOk) {
                 return (false, string(abi.encodePacked("State check failed at index ", i.toString()))); // Need to import Strings or similar
            }
            // -------------------------------
        }

        return (true, "All state conditions met");
    }

    /**
     * @notice Placeholder simulation of performing an on-chain state check.
     * @dev Replace with actual dynamic call and verification.
     * @param _targetAddress The address of the contract to check.
     * @param _functionSelector The bytes4 selector of the view function to call.
     * @param _expectedValueHash The hash of the expected return value.
     * @return True if the state check is considered successful by this placeholder.
     */
    function _performStateCheck(address _targetAddress, bytes4 _functionSelector, bytes memory _expectedValueHash)
        internal
        pure // Using pure as it's a placeholder
        returns (bool)
    {
        // This is a MOCK function. Replace with actual call logic.
        // Example: (bool success, bytes memory returnData) = _targetAddress.staticcall(_functionSelector);
        // return success && keccak256(returnData) == keccak256(_expectedValueHash);

        // For this example, we simulate success if targetAddress is non-zero and hash is non-empty
        return _targetAddress != address(0) && _expectedValueHash.length > 0;
    }

     /**
     * @notice Checks all required oracle data conditions.
     * @dev Placeholder using static checks. Real implementation needs oracle integration.
     * @param _vaultId The ID of the vault.
     * @param _oracleDataBytes Placeholder bytes for oracle data proof/signature.
     * @return isMet True if all oracle conditions are met.
     * @return reason A string indicating failure reason.
     */
    function _checkOracleCondition(uint252 _vaultId, bytes calldata _oracleDataBytes)
         internal
         view
         returns (bool isMet, string memory reason)
    {
         OracleCheck[] storage checks = _vaults[_vaultId].unlockKey.requiredOracleChecks;
         if (checks.length == 0) {
             return (true, "No oracle checks configured");
         }

         // For this simple example, we just check the *first* oracle check configured.
         // A real scenario would iterate or have complex logic.
         OracleCheck storage check = checks[0]; // Check only the first one

         // --- ORACLE CHECK PLACEHOLDER ---
         // In a real contract, this involves verifying data signed by an oracle or fetched via a secure feed.
         // Example: bool dataIsValid = ChainlinkPriceFeed(check.oracleAddress).isValidData(_oracleDataBytes, check.checkDataHash, check.expectedResultHash);
         // Example: Using a custom oracle pattern where _oracleDataBytes is a signed payload.
         // (bytes32 dataHash, uint256 value, uint256 timestamp, bytes signature) = abi.decode(_oracleDataBytes, (bytes32, uint256, uint256, bytes));
         // require(keccak256(abi.encode(dataHash, value, timestamp)) == check.checkDataHash, "Oracle data hash mismatch");
         // address signer = ECDSA.recover(dataHash, signature); // Need ECDSA library
         // require(signer == check.oracleAddress, "Invalid oracle signature");
         // require(keccak256(abi.encode(value)) == keccak256(check.expectedResultHash), "Oracle value mismatch"); // Example check

         // Simplified check: Call a placeholder function that simulates checking
         bool oracleOk = _getOracleData(check.oracleAddress, check.checkDataHash, check.expectedResultHash, _oracleDataBytes);
         if (!oracleOk) {
             return (false, "Oracle check failed");
         }
         // -------------------------------

         return (true, "Oracle condition met");
    }

     /**
     * @notice Placeholder simulation of verifying oracle data.
     * @dev Replace with actual oracle verification logic.
     * @param _oracleAddress Address of the oracle contract/signer.
     * @param _checkDataHash Hash of specific data/parameters.
     * @param _expectedResultHash Hash of the expected result.
     * @param _oracleDataBytes Provided oracle data proof/signature.
     * @return True if the oracle data is considered valid by this placeholder.
     */
    function _getOracleData(address _oracleAddress, bytes memory _checkDataHash, bytes memory _expectedResultHash, bytes memory _oracleDataBytes)
        internal
        pure // Using pure as it's a placeholder
        returns (bool)
    {
        // This is a MOCK function. Replace with actual oracle verification.
        // Example: Verify signature of _oracleAddress on _oracleDataBytes containing expected data.
        // For this example, simulate success if _oracleAddress is non-zero and _oracleDataBytes has some data.
        return _oracleAddress != address(0) && _oracleDataBytes.length > 10;
    }


    // Using imported `toString` for error messages
    // This requires installing openzeppelin-contracts and importing Strings
    // import "@openzeppelin/contracts/utils/Strings.sol";
    // using Strings for uint256;

    // Simplified internal toString if not using OpenZeppelin
    function i_toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }


    // --- VRF V2 Callback ---

    /**
     * @notice VRF callback function to receive random words.
     * @dev Called by the VRF Coordinator contract.
     * @param requestId The ID of the VRF request.
     * @param randomWords The received random words.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    )
        internal
        override
    {
        uint252 vaultId = s_requestIdToVaultId[requestId];
        require(vaultId != 0, "VRF callback for unknown vaultId");

        // Store the received random words for the vault
        s_vaultIdToRandomWords[vaultId] = randomWords;

        // Optionally associate this requestId with the vault's key config if it wasn't already set
        // VaultData storage vault = _vaults[vaultId];
        // if (vault.unlockKey.vrfRequestId == 0) {
        //    vault.unlockKey.vrfRequestId = requestId;
             // Can also set a randomnessThreshold here based on randomWords[0]
        //    if (randomWords.length > 0) {
        //        vault.unlockKey.randomnessThreshold = randomWords[0] % 100; // Example: threshold 0-99
        //    }
        // }


        emit VRFRandomnessReceived(vaultId, requestId, randomWords.length > 0 ? randomWords[0] : 0);
        // Clear the mapping after fulfillment if not needed anymore, but keeping it allows lookup
        // delete s_requestIdToVaultId[requestId];
    }

    // Placeholder for Ownable pattern if emergencyUnlock uses onlyOwner
    address private _contractOwner;

    modifier onlyOwner() {
        require(msg.sender == _contractOwner, "Only contract owner");
        _;
    }

    // Assuming contract owner is set in constructor for this demo
    constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subId)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        _contractOwner = msg.sender;
        require(_vrfCoordinator != address(0), "Invalid VRF coordinator address");
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _keyHash;
        i_subscriptionId = _subId;
    }

    function getContractOwner() external view returns (address) {
        return _contractOwner;
    }

    // Need this internal function for state check error message if not using OpenZeppelin Strings
    function i_toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}
```