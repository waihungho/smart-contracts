Okay, let's create a smart contract that embodies an advanced, creative, and less common concept. We'll simulate a "Quantum Vault" where secrets are stored in a "superimposed" state, requiring a specific "measurement" process triggered by time and conditions to reveal the underlying data. It includes concepts like time-based state transitions, conditional access, and a form of "quantum decay" if not accessed in time.

This contract is complex for illustrative purposes, demonstrating multiple states, access controls, and time-dependent logic. It is **not** a production-ready security solution and should be audited thoroughly if considered for real deployment. The "quantum" aspect is a metaphor implemented with classical blockchain logic.

---

### Contract Outline:

1.  **SPDX License and Pragma**
2.  **Imports:** OpenZeppelin's `Ownable` and `Pausable`.
3.  **Error Definitions:** Custom errors for clarity.
4.  **Enums:** `SecretState` (Superimposed, Measured, Retrieved, Rejected, Expired).
5.  **Structs:** `QuantumSecret` (details of each stored secret).
6.  **State Variables:**
    *   `secrets`: Mapping from unique ID to `QuantumSecret`.
    *   `nextSecretId`: Counter for generating unique IDs.
    *   `measurementCost`: Fee required to "measure" a secret.
    *   `ownerFees`: Accumulated contract balance from measurement fees.
    *   Constants for time durations (e.g., decay period).
7.  **Events:** Log key actions and state changes.
8.  **Modifiers:** (None beyond imported `onlyOwner`, `whenNotPaused`, `whenPaused`)
9.  **Constructor:** Initializes the contract owner and sets initial measurement cost.
10. **Admin/Owner Functions (Require `onlyOwner`):**
    *   `setMeasurementCost`: Update the fee for measuring.
    *   `withdrawFees`: Withdraw accumulated fees.
    *   `transferOwnership`: Transfer ownership.
    *   `renounceOwnership`: Renounce ownership.
    *   `pauseContract`: Pause core functionality.
    *   `unpauseContract`: Unpause the contract.
11. **Secret Creator Functions (Require specific conditions, often `msg.sender == creator`):**
    *   `createSuperimposedSecret`: Store new data in a superimposed state.
    *   `updateSuperimposedSecretParameters`: Modify certain parameters before measurement.
    *   `cancelSuperimposedSecret`: Creator destroys secret before measurement.
    *   `changeAllowedMeasurer`: Creator changes the address allowed to measure.
    *   `setPreMeasurementConditionHash`: Creator sets a hash for an external data condition.
12. **Measurer/Interaction Functions (Require specific conditions, e.g., `allowedMeasurer`, time checks, payment):**
    *   `measureSecret`: Pay fee and trigger measurement, changing state. Requires optional pre-measurement data.
    *   `retrieveMeasuredSecret`: Retrieve the encrypted data after measurement.
    *   `rejectMeasurement`: Allowed measurer explicitly rejects responsibility before unlock.
    *   `triggerQuantumDecay`: Anyone can call to mark an unmeasured/unretrieved secret as expired after decay time.
13. **Public/View Functions:**
    *   `getSecretState`: Get the current state of a secret.
    *   `getSecretParameters`: Get non-sensitive details of a secret.
    *   `getMeasurementCost`: Get the current measurement fee.
    *   `getOwnerBalance`: Get the contract's withdrawable balance.
    *   `checkMeasurementEligibility`: Check if an address can measure a specific secret *now*.
    *   `getEntanglementKey`: Get the entanglement key.
    *   `isSecretActive`: Check if a secret exists and is not expired/cancelled/rejected.
    *   `getSecretCreationTime`: Get creation timestamp.
    *   `getSecretMeasurementTime`: Get measurement timestamp.
    *   `getSecretDecayTime`: Get the calculated decay timestamp.
    *   `getPreMeasurementConditionHash`: Get the pre-measurement condition hash.

### Function Summary:

1.  `constructor(uint256 initialMeasurementCost)`: Deploys the contract, setting initial owner and measurement fee.
2.  `setMeasurementCost(uint256 _newCost)`: Allows the owner to change the fee required for measuring a secret.
3.  `withdrawFees()`: Allows the owner to withdraw accumulated measurement fees.
4.  `transferOwnership(address newOwner)`: Transfers contract ownership.
5.  `renounceOwnership()`: Renounces contract ownership (becomes unowned).
6.  `pauseContract()`: Pauses core secret interaction functions (`create`, `measure`, `retrieve`).
7.  `unpauseContract()`: Unpauses the contract.
8.  `createSuperimposedSecret(bytes memory _encryptedData, uint256 _unlockTimestamp, address payable _allowedMeasurer, bytes32 _entanglementKey, bytes32 _preMeasurementConditionHash, uint256 _decayDuration)`: Creates a new secret entry. Stores encrypted data, sets unlock time, designates a measurer, assigns an entanglement key (for off-chain correlation), sets a pre-measurement condition hash, and defines the decay period after unlock if not measured. State is `Superimposed`. Requires `whenNotPaused`.
9.  `updateSuperimposedSecretParameters(uint256 _secretId, uint256 _newUnlockTimestamp, address payable _newAllowedMeasurer, bytes32 _newPreMeasurementConditionHash, uint256 _newDecayDuration)`: Allows the creator of a `Superimposed` secret to update its unlock time, allowed measurer, pre-measurement condition hash, and decay duration before it's measured or expired. Requires `whenNotPaused` and `msg.sender == creator`.
10. `cancelSuperimposedSecret(uint256 _secretId)`: Allows the creator to cancel and remove a secret if it is still in the `Superimposed` state. Requires `whenNotPaused`.
11. `measureSecret(uint256 _secretId, bytes memory _preMeasurementConditionData)`: Triggers the "measurement" process for a secret. Requires the secret to be `Superimposed`, unlock time to have passed, sender to be the `allowedMeasurer` (or zero address if anyone allowed), requires payment of `measurementCost`, and optionally checks the hash of provided `_preMeasurementConditionData`. Changes state to `Measured`. Requires `whenNotPaused` and `payable`.
12. `retrieveMeasuredSecret(uint256 _secretId)`: Allows the `allowedMeasurer` to retrieve the `encryptedData` for a secret that is in the `Measured` state. Changes state to `Retrieved`. Requires `whenNotPaused`.
13. `rejectMeasurement(uint256 _secretId)`: Allows the designated `allowedMeasurer` to explicitly reject the responsibility of measuring a secret if it is `Superimposed` and before the unlock time has passed. Changes state to `Rejected`. Requires `whenNotPaused`.
14. `triggerQuantumDecay(uint256 _secretId)`: Can be called by anyone. If a secret is in the `Superimposed` state *after* its decay timestamp has passed (calculated from unlock time + decay duration), this function marks its state as `Expired` and potentially cleans up data (though data remains on-chain, this logically invalidates it). Requires `whenNotPaused`.
15. `getSecretState(uint256 _secretId)`: View function. Returns the current `SecretState` of a given secret ID.
16. `getSecretParameters(uint256 _secretId)`: View function. Returns non-sensitive parameters of a secret: creator, unlockTimestamp, allowedMeasurer, entanglementKey, preMeasurementConditionHash, decayTimestamp.
17. `getMeasurementCost()`: View function. Returns the current cost to measure a secret.
18. `getOwnerBalance()`: View function. Returns the total amount of Ether available for the owner to withdraw.
19. `checkMeasurementEligibility(uint256 _secretId, address _measurer)`: View function. Checks if a given `_measurer` address is currently eligible to call `measureSecret` for `_secretId` (checks state, unlock time, and allowed measurer). Does *not* check payment or pre-measurement data.
20. `getEntanglementKey(uint256 _secretId)`: View function. Returns the entanglement key associated with a secret. Useful for off-chain tools to link related secrets.
21. `isSecretActive(uint256 _secretId)`: View function. Returns true if the secret exists and its state is `Superimposed`, `Measured`, or `Retrieved`.
22. `getSecretCreationTime(uint256 _secretId)`: View function. Returns the block timestamp when the secret was created. (Stored implicitly via block.timestamp in `createSuperimposedSecret`).
23. `getSecretMeasurementTime(uint256 _secretId)`: View function. Returns the block timestamp when the secret was successfully measured. Returns 0 if not yet measured.
24. `getSecretDecayTime(uint256 _secretId)`: View function. Returns the calculated timestamp when the secret will decay if not measured/retrieved.
25. `getPreMeasurementConditionHash(uint256 _secretId)`: View function. Returns the hash set by the creator that must be matched during measurement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title QuantumVault
 * @dev A creative smart contract simulating a time-locked, state-dependent vault.
 * Secrets are stored in a "Superimposed" state, requiring a paid "Measurement"
 * after a specific time and potentially meeting a condition to become "Measured".
 * Once "Measured", the designated measurer can "Retrieve" the data.
 * Secrets can also be "Rejected" by the allowed measurer or "Expired" via "Quantum Decay"
 * if not measured/retrieved within defined timeframes.
 * The "quantum" concept is a metaphor for the state-dependent and time-sensitive access control.
 */
contract QuantumVault is Ownable, Pausable {

    // --- Error Definitions ---
    error SecretNotFound(uint256 secretId);
    error InvalidSecretState(uint256 secretId, SecretState currentState, SecretState requiredState);
    error UnlockTimeNotReached(uint256 secretId, uint256 unlockTime);
    error DecayTimeNotReached(uint256 secretId, uint256 decayTime);
    error NotAllowedMeasurer(uint256 secretId, address caller);
    error IncorrectPayment(uint256 requiredCost, uint256 sentAmount);
    error PreMeasurementConditionMismatch(bytes32 providedHash, bytes32 requiredHash);
    error NotSecretCreator(uint256 secretId, address caller);
    error AlreadyMeasuredOrExpired(uint256 secretId);
    error SecretStillSuperimposed(uint256 secretId);
    error SecretNotMeasured(uint256 secretId);


    // --- Enums ---
    enum SecretState {
        Initialized,      // Should not be reachable after creation
        Superimposed,     // Secret is created and waiting for unlock time & measurement
        Measured,         // Unlock time passed, measurement cost paid, condition met, data available for retrieval
        Retrieved,        // Data has been successfully retrieved by the allowed measurer
        Rejected,         // Allowed measurer explicitly rejected the measurement responsibility
        Expired           // Secret expired due to quantum decay (not measured/retrieved in time)
    }

    // --- Structs ---
    struct QuantumSecret {
        uint256 id;                       // Unique identifier for the secret
        address creator;                  // Address that created the secret
        bytes encryptedData;              // The actual encrypted data (only retrievable when state is Measured)
        uint256 creationTimestamp;        // Timestamp when the secret was created
        uint256 unlockTimestamp;          // Timestamp after which measurement is possible
        uint256 decayTimestamp;           // Timestamp after which the secret can decay if not measured/retrieved
        address payable allowedMeasurer;  // Address allowed to perform the measurement (zero address means anyone)
        bytes32 entanglementKey;          // A unique key for off-chain correlation/grouping
        SecretState state;                // Current state of the secret
        uint256 measurementTimestamp;     // Timestamp when the secret was measured (0 if not measured)
        bytes32 preMeasurementConditionHash; // Hash of external data required for measurement (bytes32(0) if no condition)
    }

    // --- State Variables ---
    mapping(uint256 => QuantumSecret) private secrets;
    uint256 private nextSecretId = 1;
    uint256 public measurementCost;
    uint256 public ownerFees;

    // --- Constants ---
    uint256 private constant MIN_DECAY_DURATION = 1 days; // Minimum decay duration after unlock

    // --- Events ---
    event SecretCreated(uint256 indexed secretId, address indexed creator, address indexed allowedMeasurer, uint256 unlockTimestamp, uint256 decayTimestamp, bytes32 entanglementKey);
    event SecretStateChanged(uint256 indexed secretId, SecretState newState, uint256 timestamp);
    event SecretMeasured(uint256 indexed secretId, address indexed measurer, uint256 paymentAmount);
    event SecretRetrieved(uint256 indexed secretId, address indexed measurer);
    event SecretRejected(uint256 indexed secretId, address indexed measurer);
    event SecretExpired(uint256 indexed secretId);
    event CostUpdated(uint256 newCost);
    event FeesWithdrawn(uint256 amount);
    // OwnershipTransferred and Paused/Unpaused events inherited from Ownable/Pausable


    // --- Constructor ---
    /**
     * @dev Initializes the contract and sets the initial measurement cost.
     * @param initialMeasurementCost The initial Ether amount required to measure a secret.
     */
    constructor(uint256 initialMeasurementCost) Ownable(msg.sender) {
        measurementCost = initialMeasurementCost;
    }

    // --- Admin/Owner Functions ---
    /**
     * @dev Allows the owner to set the cost for measuring a secret.
     * @param _newCost The new measurement cost in wei.
     */
    function setMeasurementCost(uint256 _newCost) external onlyOwner {
        measurementCost = _newCost;
        emit CostUpdated(_newCost);
    }

    /**
     * @dev Allows the owner to withdraw accumulated measurement fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = ownerFees;
        ownerFees = 0;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit FeesWithdrawn(amount);
    }

    // transferOwnership and renounceOwnership are inherited from Ownable

    // pause and unpause are inherited from Pausable

    // --- Secret Creator Functions ---

    /**
     * @dev Creates a new secret entry in the vault in a "Superimposed" state.
     * @param _encryptedData The encrypted data to store.
     * @param _unlockTimestamp The timestamp after which the secret can be measured.
     * @param _allowedMeasurer The address allowed to measure the secret (0x0 for anyone).
     * @param _entanglementKey A unique key for off-chain correlation/grouping.
     * @param _preMeasurementConditionHash Optional hash representing a condition to be met during measurement (bytes32(0) if none).
     * @param _decayDuration The duration after unlockTimestamp when the secret expires if not measured. Must be >= MIN_DECAY_DURATION.
     */
    function createSuperimposedSecret(
        bytes memory _encryptedData,
        uint256 _unlockTimestamp,
        address payable _allowedMeasurer,
        bytes32 _entanglementKey,
        bytes32 _preMeasurementConditionHash,
        uint256 _decayDuration
    ) external whenNotPaused returns (uint256 secretId) {
        require(_unlockTimestamp > block.timestamp, "Unlock time must be in the future");
        require(_decayDuration >= MIN_DECAY_DURATION, "Decay duration must meet minimum");

        secretId = nextSecretId++;
        uint256 creationTime = block.timestamp;
        uint256 decayTime = _unlockTimestamp + _decayDuration;

        secrets[secretId] = QuantumSecret({
            id: secretId,
            creator: msg.sender,
            encryptedData: _encryptedData,
            creationTimestamp: creationTime,
            unlockTimestamp: _unlockTimestamp,
            decayTimestamp: decayTime,
            allowedMeasurer: _allowedMeasurer,
            entanglementKey: _entanglementKey,
            state: SecretState.Superimposed,
            measurementTimestamp: 0,
            preMeasurementConditionHash: _preMeasurementConditionHash
        });

        emit SecretCreated(secretId, msg.sender, _allowedMeasurer, _unlockTimestamp, decayTime, _entanglementKey);
        emit SecretStateChanged(secretId, SecretState.Superimposed, creationTime);
    }

    /**
     * @dev Allows the creator to update certain parameters of a Superimposed secret.
     * Cannot change the encrypted data or entanglement key.
     * @param _secretId The ID of the secret to update.
     * @param _newUnlockTimestamp The new unlock timestamp.
     * @param _newAllowedMeasurer The new allowed measurer address.
     * @param _newPreMeasurementConditionHash The new pre-measurement condition hash.
     * @param _newDecayDuration The new decay duration after unlock.
     */
    function updateSuperimposedSecretParameters(
        uint256 _secretId,
        uint256 _newUnlockTimestamp,
        address payable _newAllowedMeasurer,
        bytes32 _newPreMeasurementConditionHash,
        uint256 _newDecayDuration
    ) external whenNotPaused {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.creator != msg.sender) revert NotSecretCreator(_secretId, msg.sender);
        if (secret.state != SecretState.Superimposed) revert InvalidSecretState(_secretId, secret.state, SecretState.Superimposed);
        if (_newUnlockTimestamp <= block.timestamp) revert("New unlock time must be in the future");
         if (_newDecayDuration < MIN_DECAY_DURATION) revert("New decay duration must meet minimum");

        secret.unlockTimestamp = _newUnlockTimestamp;
        secret.allowedMeasurer = _newAllowedMeasurer;
        secret.preMeasurementConditionHash = _newPreMeasurementConditionHash;
        secret.decayTimestamp = _newUnlockTimestamp + _newDecayDuration; // Recalculate decay time
        // encryptedData and entanglementKey are immutable after creation
    }


    /**
     * @dev Allows the creator to cancel a secret if it is still Superimposed.
     * Removes the secret entry and prevents future interaction.
     * @param _secretId The ID of the secret to cancel.
     */
    function cancelSuperimposedSecret(uint256 _secretId) external whenNotPaused {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.creator != msg.sender) revert NotSecretCreator(_secretId, msg.sender);
        if (secret.state != SecretState.Superimposed) revert InvalidSecretState(_secretId, secret.state, SecretState.Superimposed);

        // Mark as expired (logical deletion)
        secret.state = SecretState.Expired;
        // Note: Data remains on chain history but is inaccessible via the mapping.
        // Explicitly clearing sensitive data might be gas prohibitive or ineffective due to storage history.
        // secrets[_secretId] = QuantumSecret(0, address(0), "", 0, 0, 0, payable(address(0)), bytes32(0), SecretState.Expired, 0, bytes32(0)); // Option for explicit clear, but mapping delete is simpler
        delete secrets[_secretId]; // Using delete frees up storage gas

        emit SecretStateChanged(_secretId, SecretState.Expired, block.timestamp);
        emit SecretExpired(_secretId); // Using Expired event for cancellation too
    }

    /**
     * @dev Allows the creator to change the address allowed to measure the secret,
     * but only if it's in the Superimposed state.
     * @param _secretId The ID of the secret.
     * @param _newAllowedMeasurer The new address allowed to measure.
     */
    function changeAllowedMeasurer(uint256 _secretId, address payable _newAllowedMeasurer) external whenNotPaused {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.creator != msg.sender) revert NotSecretCreator(_secretId, msg.sender);
        if (secret.state != SecretState.Superimposed) revert InvalidSecretState(_secretId, secret.state, SecretState.Superimposed);

        secret.allowedMeasurer = _newAllowedMeasurer;
    }

    /**
     * @dev Allows the creator to set or update the pre-measurement condition hash
     * for a secret in the Superimposed state.
     * @param _secretId The ID of the secret.
     * @param _newHash The new condition hash (bytes32(0) to remove condition).
     */
    function setPreMeasurementConditionHash(uint256 _secretId, bytes32 _newHash) external whenNotPaused {
         QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.creator != msg.sender) revert NotSecretCreator(_secretId, msg.sender);
        if (secret.state != SecretState.Superimposed) revert InvalidSecretState(_secretId, secret.state, SecretState.Superimposed);

        secret.preMeasurementConditionHash = _newHash;
    }


    // --- Measurer/Interaction Functions ---

    /**
     * @dev Performs the "measurement" of a secret.
     * Requires the secret to be Superimposed, unlock time passed, correct measurer (or anyone),
     * requires payment of measurementCost, and requires the hash of provided data to match
     * the pre-measurement condition hash if one is set.
     * Transitions the secret state to Measured.
     * @param _secretId The ID of the secret to measure.
     * @param _preMeasurementConditionData Optional data whose hash must match the stored hash.
     */
    function measureSecret(uint256 _secretId, bytes memory _preMeasurementConditionData) external payable whenNotPaused {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.state != SecretState.Superimposed) revert InvalidSecretState(_secretId, secret.state, SecretState.Superimposed);
        if (block.timestamp < secret.unlockTimestamp) revert UnlockTimeNotReached(_secretId, secret.unlockTimestamp);
        if (secret.allowedMeasurer != address(0) && secret.allowedMeasurer != msg.sender) revert NotAllowedMeasurer(_secretId, msg.sender);
        if (msg.value < measurementCost) revert IncorrectPayment(measurementCost, msg.value);

        // Check pre-measurement condition hash if set
        if (secret.preMeasurementConditionHash != bytes32(0)) {
            bytes32 dataHash = keccak256(_preMeasurementConditionData);
            if (dataHash != secret.preMeasurementConditionHash) {
                revert PreMeasurementConditionMismatch(dataHash, secret.preMeasurementConditionHash);
            }
        }

        // Transition state
        secret.state = SecretState.Measured;
        secret.measurementTimestamp = block.timestamp;
        ownerFees += msg.value; // Accumulate fees

        emit SecretStateChanged(_secretId, SecretState.Measured, block.timestamp);
        emit SecretMeasured(_secretId, msg.sender, msg.value);

        // Return excess Ether if any (shouldn't happen if using exact value, but good practice)
        if (msg.value > measurementCost) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - measurementCost}("");
             require(success, "Refund failed"); // Refund should not fail user tx
        }
    }

    /**
     * @dev Allows the allowed measurer to retrieve the encrypted data for a secret
     * that is in the "Measured" state.
     * Transitions the state to "Retrieved".
     * @param _secretId The ID of the secret to retrieve.
     * @return bytes The encrypted data.
     */
    function retrieveMeasuredSecret(uint256 _secretId) external whenNotPaused returns (bytes memory) {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.state != SecretState.Measured) revert InvalidSecretState(_secretId, secret.state, SecretState.Measured);
        // The allowed measurer is set during creation and can be updated before measurement.
        // They are the only ones who can transition from Measured -> Retrieved.
        if (secret.allowedMeasurer != address(0) && secret.allowedMeasurer != msg.sender) revert NotAllowedMeasurer(_secretId, msg.sender);

        // Transition state
        secret.state = SecretState.Retrieved;

        emit SecretStateChanged(_secretId, SecretState.Retrieved, block.timestamp);
        emit SecretRetrieved(_secretId, msg.sender);

        return secret.encryptedData;
    }

    /**
     * @dev Allows the designated allowed measurer to explicitly reject the responsibility
     * of measuring a secret. This can only be done if the secret is Superimposed
     * and the unlock time has NOT yet passed.
     * Transitions the state to "Rejected". Creator may then change the measurer or cancel.
     * @param _secretId The ID of the secret to reject.
     */
    function rejectMeasurement(uint256 _secretId) external whenNotPaused {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.state != SecretState.Superimposed) revert InvalidSecretState(_secretId, secret.state, SecretState.Superimposed);
        if (secret.allowedMeasurer == address(0)) revert("Secret allows anyone to measure"); // Cannot reject if anyone can measure
        if (secret.allowedMeasurer != msg.sender) revert NotAllowedMeasurer(_secretId, msg.sender);
        if (block.timestamp >= secret.unlockTimestamp) revert("Cannot reject after unlock time");

        // Transition state
        secret.state = SecretState.Rejected;

        emit SecretStateChanged(_secretId, SecretState.Rejected, block.timestamp);
        emit SecretRejected(_secretId, msg.sender);
    }


    /**
     * @dev Triggers the "Quantum Decay" process for a secret.
     * Can be called by anyone if the secret is Superimposed and the decay timestamp has passed.
     * Marks the secret as "Expired" and logically removes it.
     * @param _secretId The ID of the secret to decay.
     */
    function triggerQuantumDecay(uint256 _secretId) external whenNotPaused {
        QuantumSecret storage secret = secrets[_secretId];
         if (secret.id == 0) revert SecretNotFound(_secretId);
        if (secret.state != SecretState.Superimposed) revert InvalidSecretState(_secretId, secret.state, SecretState.Superimposed);
        if (block.timestamp < secret.decayTimestamp) revert DecayTimeNotReached(_secretId, secret.decayTimestamp);

        // Transition state to Expired
        secret.state = SecretState.Expired;
        // Delete from mapping to save gas on future lookups and storage cost
        delete secrets[_secretId]; // Frees up storage slot

        emit SecretStateChanged(_secretId, SecretState.Expired, block.timestamp);
        emit SecretExpired(_secretId);
    }


    // --- Public/View Functions ---

    /**
     * @dev Returns the current state of a secret.
     * @param _secretId The ID of the secret.
     * @return SecretState The current state.
     */
    function getSecretState(uint256 _secretId) external view returns (SecretState) {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        return secret.state;
    }

    /**
     * @dev Returns non-sensitive parameters of a secret.
     * @param _secretId The ID of the secret.
     * @return creator, unlockTimestamp, allowedMeasurer, entanglementKey, preMeasurementConditionHash, decayTimestamp
     */
    function getSecretParameters(uint256 _secretId) external view returns (
        address creator,
        uint256 unlockTimestamp,
        address allowedMeasurer,
        bytes32 entanglementKey,
        bytes32 preMeasurementConditionHash,
        uint256 decayTimestamp
    ) {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) revert SecretNotFound(_secretId);
        return (
            secret.creator,
            secret.unlockTimestamp,
            secret.allowedMeasurer,
            secret.entanglementKey,
            secret.preMeasurementConditionHash,
            secret.decayTimestamp
        );
    }

    /**
     * @dev Returns the current measurement cost.
     */
    function getMeasurementCost() external view returns (uint256) {
        return measurementCost;
    }

    /**
     * @dev Returns the contract's accumulated fees balance.
     */
    function getOwnerBalance() external view returns (uint256) {
        return ownerFees;
    }

    /**
     * @dev Checks if a given address is currently eligible to measure a secret.
     * Checks state, unlock time, and allowed measurer, but not payment or condition data.
     * @param _secretId The ID of the secret.
     * @param _measurer The address to check eligibility for.
     * @return bool True if eligible, false otherwise.
     */
    function checkMeasurementEligibility(uint256 _secretId, address _measurer) external view returns (bool) {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0 || secret.state != SecretState.Superimposed || block.timestamp < secret.unlockTimestamp) {
            return false;
        }
        if (secret.allowedMeasurer != address(0) && secret.allowedMeasurer != _measurer) {
            return false;
        }
        return true;
    }

     /**
     * @dev Returns the entanglement key associated with a secret.
     * @param _secretId The ID of the secret.
     * @return bytes32 The entanglement key.
     */
    function getEntanglementKey(uint256 _secretId) external view returns (bytes32) {
        QuantumSecret storage secret = secrets[_secretId];
         if (secret.id == 0) revert SecretNotFound(_secretId);
        return secret.entanglementKey;
    }

    /**
     * @dev Checks if a secret exists and is in an active state (Superimposed, Measured, Retrieved).
     * @param _secretId The ID of the secret.
     * @return bool True if active, false otherwise.
     */
    function isSecretActive(uint256 _secretId) external view returns (bool) {
        QuantumSecret storage secret = secrets[_secretId];
        if (secret.id == 0) { // Check if struct exists (ID would be non-zero if created)
            return false;
        }
        return secret.state == SecretState.Superimposed || secret.state == SecretState.Measured || secret.state == SecretState.Retrieved;
    }

    /**
     * @dev Returns the creation timestamp of a secret.
     * @param _secretId The ID of the secret.
     * @return uint256 The creation timestamp.
     */
    function getSecretCreationTime(uint256 _secretId) external view returns (uint256) {
        QuantumSecret storage secret = secrets[_secretId];
         if (secret.id == 0) revert SecretNotFound(_secretId);
        return secret.creationTimestamp;
    }

    /**
     * @dev Returns the measurement timestamp of a secret.
     * Returns 0 if the secret has not been measured.
     * @param _secretId The ID of the secret.
     * @return uint256 The measurement timestamp.
     */
    function getSecretMeasurementTime(uint256 _secretId) external view returns (uint256) {
        QuantumSecret storage secret = secrets[_secretId];
         if (secret.id == 0) revert SecretNotFound(_secretId);
        return secret.measurementTimestamp;
    }

     /**
     * @dev Returns the timestamp when a secret will decay if not measured/retrieved.
     * @param _secretId The ID of the secret.
     * @return uint256 The decay timestamp.
     */
    function getSecretDecayTime(uint256 _secretId) external view returns (uint256) {
        QuantumSecret storage secret = secrets[_secretId];
         if (secret.id == 0) revert SecretNotFound(_secretId);
        return secret.decayTimestamp;
    }

     /**
     * @dev Returns the pre-measurement condition hash for a secret.
     * Returns bytes32(0) if no condition is set.
     * @param _secretId The ID of the secret.
     * @return bytes32 The pre-measurement condition hash.
     */
    function getPreMeasurementConditionHash(uint256 _secretId) external view returns (bytes32) {
         QuantumSecret storage secret = secrets[_secretId];
         if (secret.id == 0) revert SecretNotFound(_secretId);
        return secret.preMeasurementConditionHash;
    }

    // --- Fallback function to reject direct Ether payments ---
    // receive() external payable {
    //     revert("Direct payments not allowed, use measureSecret");
    // }
}
```