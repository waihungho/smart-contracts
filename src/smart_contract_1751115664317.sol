Okay, here is a smart contract concept leveraging quantum-inspired principles like state superposition, measurement-induced collapse, entanglement (simulated via state linking), and decoherence (state expiration) to manage access to digital "secrets" or rights via deterministically derived, transient "quantum keys".

This concept is advanced because it moves beyond simple ownership or static key checks, incorporating time-dependent, interaction-dependent key derivation and state transitions. It's creative in applying quantum mechanics metaphors to on-chain logic. It's trendy by touching upon "quantum" themes, albeit simulated. It aims to be non-duplicative by creating a unique protocol around these combined simulated concepts for access control.

**Disclaimer:** This contract *simulates* quantum concepts using classical blockchain logic. It does *not* involve actual quantum computing or provide quantum-level security guarantees against classical attacks on the blockchain itself. The "quantum" aspect is a protocol design metaphor. Secrets stored directly in public contract state are visible on the blockchain; this contract assumes the secrets are perhaps encrypted off-chain and the stored value is the decryption key or a piece of data only valuable *after* being accessed through the protocol. Or, the secrets could be small identifiers or hashes used in a larger system.

---

## Smart Contract: QuantumKeyProtocol

**Concept:**

A protocol simulating aspects of quantum mechanics for managing access rights or revealing secrets. It revolves around "Quantum States" which represent potential access points or information fragments. These states exist in a form of "superposition" (represented by an initial commitment) until a user performs a "measurement" (an on-chain transaction with unique data). The measurement causes the state to "collapse," deterministically deriving a unique "Quantum Key" based on the state's initial properties and the measurement context (user address, block data, provided data). Once measured by one entity, the state is typically collapsed and cannot be measured again in the same way by others (simulating the no-cloning theorem and measurement affecting the state). States can be "entangled" (linked) and can undergo "decoherence" (expire if not measured within a time limit). Access to secrets or specific actions is then granted only by presenting the correctly derived Quantum Key from a successfully measured state.

**Outline:**

1.  **State Variables:** Store contract owner, state data, secrets, measured key validity, and configuration.
2.  **Events:** Announce key state changes (creation, measurement, revocation, secret addition, etc.).
3.  **Modifiers:** `onlyOwner` for administrative functions.
4.  **Structs:** `QuantumState` to define the properties of each state.
5.  **Key Derivation Logic:** An internal function to deterministically compute the "Quantum Key" hash from state and measurement data.
6.  **State Management Functions (Admin/Owner):** Create, modify, revoke states, manage secrets, configure protocol parameters.
7.  **State Interaction Functions (User):** Measure states, attempt to retrieve secrets using derived keys, transfer state ownership (before measurement).
8.  **View Functions (Public):** Query state status, linkages, configurations, key validity.

**Function Summary:**

1.  `constructor()`: Deploys the contract and sets the owner.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership.
3.  `renounceOwnership()`: Renounces contract ownership.
4.  `addProtocolSecret(bytes32 secretId, bytes secretData)`: Owner adds a secret associated with an ID.
5.  `removeProtocolSecret(bytes32 secretId)`: Owner removes a secret.
6.  `createQuantumState(bytes32 initialCommitment, bytes32 associatedSecretId, uint48 decoherenceDuration, address stateOwner)`: Owner creates a state with initial properties.
7.  `createQuantumStateWithLinks(bytes32 initialCommitment, bytes32 associatedSecretId, uint48 decoherenceDuration, address stateOwner, uint256[] linkedStateIds)`: Owner creates a state with initial properties and links.
8.  `revokeQuantumState(uint256 stateId)`: Owner invalidates a state before measurement.
9.  `updateStateDecoherence(uint256 stateId, uint48 newDuration)`: Owner updates a state's decoherence duration.
10. `linkStates(uint256 fromStateId, uint256 toStateId)`: Owner links one state to another (simulating entanglement).
11. `unlinkStates(uint256 fromStateId, uint256 toStateId)`: Owner removes a link.
12. `setMinMeasurementDataLength(uint256 minLength)`: Owner sets minimum required length for measurement data.
13. `measureQuantumState(uint256 stateId, bytes measurementData)`: User attempts to measure a state, deriving and validating a unique key.
14. `retrieveProtocolSecret(uint256 stateId, bytes32 derivedKey)`: User uses a derived key to access the associated secret.
15. `checkStateValidity(uint256 stateId)`: Public view to check if a state is active and measurable.
16. `getLinkedStates(uint256 stateId)`: Public view to get linked state IDs.
17. `transferStateOwnership(uint256 stateId, address newOwner)`: Current state owner transfers ownership before measurement.
18. `getAssociatedSecretId(uint256 stateId)`: Public view to get the secret ID linked to a state.
19. `checkDecoherenceStatus(uint256 stateId)`: Public view to check if a state has decohered.
20. `getMinMeasurementDataLength()`: Public view for the minimum measurement data length requirement.
21. `retrieveStateOwner(uint256 stateId)`: Public view to get the current owner of a state.
22. `invalidateMeasuredKeyHash(bytes32 keyHash)`: Owner can invalidate a specific derived key hash.
23. `getQuantumStateDetails(uint256 stateId)`: Public view to get non-sensitive state details.
24. `getTotalStates()`: Public view to get the total number of states created.
25. `isKeyHashValid(bytes32 keyHash)`: Public view to check if a derived key hash is marked as valid.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumKeyProtocol
 * @dev A smart contract simulating quantum-inspired principles for access control and secret management.
 *      It uses concepts like state superposition (commitment), measurement-induced collapse (key derivation),
 *      entanglement (state linking), and decoherence (state expiration).
 *      Access to secrets or rights is granted via unique keys derived from measuring Quantum States.
 *      NOTE: This is a simulation using classical blockchain logic, not actual quantum computing.
 *      Secrets stored directly in protocolSecrets are publicly visible on-chain; this assumes
 *      the key grants access to interpretation, or the secret is encrypted off-chain.
 */
contract QuantumKeyProtocol {

    // --- State Variables ---

    address private immutable i_owner; // Contract owner
    uint256 public nextStateId; // Counter for unique state IDs

    struct QuantumState {
        bytes32 initialCommitment; // Represents the 'superposition' state
        address owner; // Address allowed to 'measure' the state
        bool isMeasured; // Has the state been 'measured' (collapsed)?
        address measuredBy; // Address that measured the state
        bytes32 measuredKeyHash; // Hash of the derived 'quantum key'
        bool isRevoked; // Has the state been revoked by the owner?
        uint48 creationTimestamp; // Timestamp of state creation
        uint48 decoherenceDuration; // Duration after which the state 'decoheres' (expires)
        uint256[] linkedStates; // IDs of states linked to this one (simulating entanglement)
        bytes32 associatedSecretId; // ID of the secret this state grants access to
    }

    // Mapping from State ID to QuantumState struct
    mapping(uint256 => QuantumState) public quantumStates;

    // Mapping from Secret ID to the actual secret data (or decryption key)
    // NOTE: Data stored here is public on the blockchain.
    mapping(bytes32 => bytes) private protocolSecrets;

    // Mapping to track validity of derived 'quantum keys' hashes
    mapping(bytes32 => bool) public validMeasuredKeys;

    // Configuration for measurement data requirements
    uint256 public minMeasurementDataLength;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecretAdded(bytes32 indexed secretId);
    event SecretRemoved(bytes32 indexed secretId);
    event StateCreated(uint256 indexed stateId, address indexed owner, bytes32 indexed associatedSecretId, uint48 decoherenceDuration);
    event StateMeasured(uint256 indexed stateId, address indexed measuredBy, bytes32 indexed derivedKeyHash);
    event StateRevoked(uint256 indexed stateId);
    event StateDecoherenceUpdated(uint256 indexed stateId, uint48 newDuration);
    event StateLinked(uint256 indexed fromStateId, uint256 indexed toStateId);
    event StateUnlinked(uint256 indexed fromStateId, uint256 indexed toStateId);
    event MeasurementDataLengthSet(uint256 minLength);
    event StateOwnershipTransferred(uint256 indexed stateId, address indexed oldOwner, address indexed newOwner);
    event MeasuredKeyHashInvalidated(bytes32 indexed keyHash);
    event SecretRetrieved(uint256 indexed stateId, address indexed retriever, bytes32 indexed secretId);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == i_owner, "QKP: Only owner can call");
        _;
    }

    // --- Constructor ---

    constructor() {
        i_owner = msg.sender;
    }

    // --- Internal Key Derivation Logic ---

    /**
     * @dev Deterministically derives the 'quantum key' hash from state properties and measurement context.
     *      Simulates 'measurement-induced collapse'.
     * @param _state The QuantumState being measured.
     * @param _measurementData Unique data provided by the user during measurement.
     * @return The derived quantum key hash.
     */
    function _deriveQuantumKeyHash(
        QuantumState storage _state,
        bytes memory _measurementData
    ) internal view returns (bytes32) {
        // Combine various factors representing the 'measurement apparatus' and 'environment'
        // This makes the key unique to the state, the measurer, the specific transaction, and the provided data.
        return keccak256(abi.encodePacked(
            _state.initialCommitment,
            msg.sender,
            block.timestamp,
            block.number,
            block.difficulty, // Adds some variability depending on chain
            block.chainid,
            _measurementData
        ));
    }

    /**
     * @dev Checks if a state has decohered (expired).
     * @param _state The state to check.
     * @return true if decohered, false otherwise.
     */
    function _isDecohered(QuantumState storage _state) internal view returns (bool) {
        return _state.decoherenceDuration > 0 && block.timestamp > _state.creationTimestamp + _state.decoherenceDuration;
    }

    // --- Admin/Owner Functions ---

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "QKP: New owner is the zero address");
        address oldOwner = i_owner; // Capture old owner before update (though not strictly needed due to immutable)
        // In a non-immutable scenario, update the owner state variable.
        // Since i_owner is immutable, this function would typically perform a transfer to a *new* contract
        // or follow a more complex proxy pattern. For this example, we'll simulate the standard pattern
        // but note the i_owner is fixed. A real implementation might use a mutable owner state variable.
        // For this exercise, we emit the event as if ownership was transferred,
        // but the `onlyOwner` modifier will still check the original i_owner.
        // A practical implementation would require `address public owner;` and `owner = newOwner;`.
        // Sticking to the requirement of *not duplicating* standard libraries means avoiding OpenZeppelin's Ownable.
        // Let's add a mutable owner state variable for this function to work realistically.
        // Okay, changing `i_owner` to a mutable state variable `owner`.

        address oldOwnerActual = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwnerActual, newOwner);
    }

    address private owner; // Making owner mutable for transferOwnership/renounceOwnership

    modifier onlyOwnerCorrect() {
        require(msg.sender == owner, "QKP: Only owner can call");
        _;
    }

    // Update constructor and onlyOwner modifier to use the mutable owner variable
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Allows the owner to renounce ownership of the contract.
     *      The contract will not have an owner after this.
     */
    function renounceOwnership() external onlyOwnerCorrect {
        address oldOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    /**
     * @dev Allows the owner to add a secret associated with a unique ID.
     *      The secret data is stored directly on the blockchain.
     * @param secretId A unique identifier for the secret.
     * @param secretData The actual secret data (bytes).
     */
    function addProtocolSecret(bytes32 secretId, bytes memory secretData) external onlyOwnerCorrect {
        require(secretId != bytes33(0), "QKP: Secret ID cannot be zero");
        require(protocolSecrets[secretId].length == 0, "QKP: Secret ID already exists");
        require(secretData.length > 0, "QKP: Secret data cannot be empty");
        protocolSecrets[secretId] = secretData;
        emit SecretAdded(secretId);
    }

    /**
     * @dev Allows the owner to remove a secret.
     * @param secretId The ID of the secret to remove.
     */
    function removeProtocolSecret(bytes32 secretId) external onlyOwnerCorrect {
        require(protocolSecrets[secretId].length > 0, "QKP: Secret ID does not exist");
        delete protocolSecrets[secretId];
        emit SecretRemoved(secretId);
    }

    /**
     * @dev Allows the owner to create a new Quantum State.
     *      Represents preparing a state in 'superposition'.
     * @param initialCommitment A hash or commitment representing the initial state.
     * @param associatedSecretId The ID of the secret this state measurement grants access to.
     * @param decoherenceDuration The duration in seconds until the state decoheres (0 for no decoherence).
     * @param stateOwner The address that will be allowed to measure this state.
     */
    function createQuantumState(
        bytes32 initialCommitment,
        bytes32 associatedSecretId,
        uint48 decoherenceDuration,
        address stateOwner
    ) external onlyOwnerCorrect {
        require(stateOwner != address(0), "QKP: State owner cannot be zero address");
        if (associatedSecretId != bytes33(0)) {
             require(protocolSecrets[associatedSecretId].length > 0, "QKP: Associated secret ID does not exist");
        }


        uint256 newStateId = nextStateId++;
        quantumStates[newStateId] = QuantumState({
            initialCommitment: initialCommitment,
            owner: stateOwner,
            isMeasured: false,
            measuredBy: address(0),
            measuredKeyHash: bytes32(0),
            isRevoked: false,
            creationTimestamp: uint48(block.timestamp),
            decoherenceDuration: decoherenceDuration,
            linkedStates: new uint256[](0), // Initially no links
            associatedSecretId: associatedSecretId
        });

        emit StateCreated(newStateId, stateOwner, associatedSecretId, decoherenceDuration);
    }

    /**
     * @dev Allows the owner to create a new Quantum State with initial links to other states.
     *      Simulates creating an 'entangled' state.
     * @param initialCommitment A hash or commitment representing the initial state.
     * @param associatedSecretId The ID of the secret this state measurement grants access to.
     * @param decoherenceDuration The duration in seconds until the state decoheres (0 for no decoherence).
     * @param stateOwner The address that will be allowed to measure this state.
     * @param linkedStateIds Array of state IDs to link to this new state.
     */
    function createQuantumStateWithLinks(
        bytes32 initialCommitment,
        bytes32 associatedSecretId,
        uint48 decoherenceDuration,
        address stateOwner,
        uint256[] memory linkedStateIds
    ) external onlyOwnerCorrect {
         require(stateOwner != address(0), "QKP: State owner cannot be zero address");
         if (associatedSecretId != bytes33(0)) {
              require(protocolSecrets[associatedSecretId].length > 0, "QKP: Associated secret ID does not exist");
         }

        // Validate linked states exist
        for (uint i = 0; i < linkedStateIds.length; i++) {
            require(linkedStateIds[i] < nextStateId, "QKP: Invalid linked state ID");
            // Note: Does not check if linked states are measured/revoked/decohered at creation time.
            // Link validity is typically checked during measurement or usage.
        }

        uint256 newStateId = nextStateId++;
        quantumStates[newStateId] = QuantumState({
            initialCommitment: initialCommitment,
            owner: stateOwner,
            isMeasured: false,
            measuredBy: address(0),
            measuredKeyHash: bytes32(0),
            isRevoked: false,
            creationTimestamp: uint48(block.timestamp),
            decoherenceDuration: decoherenceDuration,
            linkedStates: linkedStateIds, // Set initial links
            associatedSecretId: associatedSecretId
        });

        emit StateCreated(newStateId, stateOwner, associatedSecretId, decoherenceDuration);
        for (uint i = 0; i < linkedStateIds.length; i++) {
             emit StateLinked(newStateId, linkedStateIds[i]);
        }
    }

    /**
     * @dev Allows the owner to revoke a Quantum State before it is measured.
     *      Invalidates the state and prevents measurement.
     * @param stateId The ID of the state to revoke.
     */
    function revokeQuantumState(uint256 stateId) external onlyOwnerCorrect {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        QuantumState storage state = quantumStates[stateId];
        require(!state.isMeasured, "QKP: State already measured");
        require(!state.isRevoked, "QKP: State already revoked");
        require(!_isDecohered(state), "QKP: State already decohered");

        state.isRevoked = true;
        emit StateRevoked(stateId);
    }

    /**
     * @dev Allows the owner to update the decoherence duration of a state.
     * @param stateId The ID of the state to update.
     * @param newDuration The new decoherence duration in seconds.
     */
    function updateStateDecoherence(uint256 stateId, uint48 newDuration) external onlyOwnerCorrect {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        QuantumState storage state = quantumStates[stateId];
        require(!state.isMeasured, "QKP: State already measured");
        require(!state.isRevoked, "QKP: State revoked");

        state.decoherenceDuration = newDuration;
        // Note: If newDuration is less than time elapsed since creation, it will decohere immediately.
        emit StateDecoherenceUpdated(stateId, newDuration);
    }

    /**
     * @dev Allows the owner to link one state to another.
     *      Simulates creating or adding 'entanglement'.
     *      This is a unidirectional link.
     * @param fromStateId The ID of the state to link from.
     * @param toStateId The ID of the state to link to.
     */
    function linkStates(uint256 fromStateId, uint256 toStateId) external onlyOwnerCorrect {
        require(fromStateId < nextStateId, "QKP: Invalid fromState ID");
        require(toStateId < nextStateId, "QKP: Invalid toState ID");
        require(fromStateId != toStateId, "QKP: Cannot link state to itself");

        QuantumState storage fromState = quantumStates[fromStateId];
        // Check if already linked (avoid duplicates)
        for (uint i = 0; i < fromState.linkedStates.length; i++) {
            require(fromState.linkedStates[i] != toStateId, "QKP: States already linked");
        }

        fromState.linkedStates.push(toStateId);
        emit StateLinked(fromStateId, toStateId);
    }

    /**
     * @dev Allows the owner to remove a link between states.
     * @param fromStateId The ID of the state the link originates from.
     * @param toStateId The ID of the state the link points to.
     */
    function unlinkStates(uint256 fromStateId, uint256 toStateId) external onlyOwnerCorrect {
        require(fromStateId < nextStateId, "QKP: Invalid fromState ID");
        require(toStateId < nextStateId, "QKP: Invalid toState ID");

        QuantumState storage fromState = quantumStates[fromStateId];
        bool found = false;
        for (uint i = 0; i < fromState.linkedStates.length; i++) {
            if (fromState.linkedStates[i] == toStateId) {
                // Remove by swapping with last element and popping
                fromState.linkedStates[i] = fromState.linkedStates[fromState.linkedStates.length - 1];
                fromState.linkedStates.pop();
                found = true;
                break;
            }
        }
        require(found, "QKP: Link does not exist");
        emit StateUnlinked(fromStateId, toStateId);
    }

    /**
     * @dev Sets the minimum required length for the measurementData bytes.
     * @param minLength The minimum length.
     */
    function setMinMeasurementDataLength(uint256 minLength) external onlyOwnerCorrect {
        minMeasurementDataLength = minLength;
        emit MeasurementDataLengthSet(minLength);
    }

    /**
     * @dev Allows the owner to invalidate a specific derived key hash.
     *      This prevents that key from being used to retrieve secrets, even if it was valid before.
     *      Useful if a key is compromised.
     * @param keyHash The hash of the derived key to invalidate.
     */
    function invalidateMeasuredKeyHash(bytes32 keyHash) external onlyOwnerCorrect {
        require(validMeasuredKeys[keyHash], "QKP: Key hash is not currently valid");
        validMeasuredKeys[keyHash] = false;
        emit MeasuredKeyHashInvalidated(keyHash);
    }

    // --- User/Interaction Functions ---

    /**
     * @dev Allows the state owner to 'measure' a Quantum State.
     *      Simulates 'measurement-induced collapse', deriving a unique key.
     *      This transitions the state from 'superposition' to 'collapsed'.
     * @param stateId The ID of the state to measure.
     * @param measurementData Unique arbitrary data provided by the user.
     * @return The hash of the derived quantum key. User must store the actual key (input data)
     *         or hash it off-chain to use it later. The contract stores the hash.
     */
    function measureQuantumState(uint256 stateId, bytes memory measurementData) external {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        QuantumState storage state = quantumStates[stateId];

        require(msg.sender == state.owner, "QKP: Only state owner can measure");
        require(!state.isMeasured, "QKP: State already measured");
        require(!state.isRevoked, "QKP: State revoked");
        require(!_isDecohered(state), "QKP: State has decohered");
        require(measurementData.length >= minMeasurementDataLength, "QKP: Measurement data too short");

        // Derive the unique key hash based on the specific measurement context
        bytes32 derivedKeyHash = _deriveQuantumKeyHash(state, measurementData);

        // 'Collapse' the state
        state.isMeasured = true;
        state.measuredBy = msg.sender;
        state.measuredKeyHash = derivedKeyHash;
        validMeasuredKeys[derivedKeyHash] = true; // Mark the derived key hash as valid

        emit StateMeasured(stateId, msg.sender, derivedKeyHash);

        // Return the derived key hash. The user is responsible for remembering/storing
        // the `measurementData` they used to later regenerate the key and prove access.
        return derivedKeyHash;
    }

    /**
     * @dev Allows a user to retrieve the secret associated with a measured state
     *      by presenting the derived 'quantum key'.
     * @param stateId The ID of the state that was measured.
     * @param derivedKey The actual bytes used as `measurementData` during `measureQuantumState`.
     *        The contract will re-derive the key hash and compare it.
     * @return The secret data associated with the state.
     */
    function retrieveProtocolSecret(uint256 stateId, bytes memory derivedKey) external view returns (bytes memory) {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        QuantumState storage state = quantumStates[stateId];

        // Basic checks on state validity (even though measured, it shouldn't be revoked/decohered)
        require(state.isMeasured, "QKP: State not measured");
        require(!state.isRevoked, "QKP: State revoked");
        // Secrets can potentially be accessed even if the state has decohered *after* measurement,
        // as the collapse already happened. Adjust logic here if decoherence should also invalidate access.
        // require(!_isDecohered(state), "QKP: State has decohered"); // Optional: uncomment to invalidate key on decoherence

        // Re-derive the key hash using the provided key and original measurement context
        // Note: This requires re-encoding the original state commitment and block context.
        // This is a simplification; a more robust approach might store specific block data.
        // For demonstration, we re-use the derivation logic assuming block context is stable enough for verification *immediately after* measurement.
        // A safer approach would store the block number/timestamp used during measurement in the state struct.
        // Let's update the struct and derivation for better verification.

        // UPDATED PLAN: Store block details in QuantumState. Re-derive key requires original block data.
        // Let's revert to hashing the *provided key* and comparing against the *stored hash*.
        // The user must *remember* the `measurementData` they used, hash it, and present the hash.

        // Let's redesign retrieveProtocolSecret to take the HASH of the derived key
        // The user calculates `keccak256(abi.encodePacked(_state.initialCommitment, state.measuredBy, state.measuredTimestamp, state.measuredBlockNumber, originalMeasurementData))` off-chain
        // And presents the resulting `derivedKeyHash`.

        // ALTERNATE REDESIGN: `retrieveProtocolSecret` takes the `stateId` and the `bytes memory derivedKey`
        // And re-runs the derivation using the *stored* original state data and the *current* block context.
        // This implies the key derivation must be based on static state data + user data, not block data that changes.
        // Let's make the derivation purely based on `initialCommitment` and `measurementData` and `msg.sender`.

        // REVISED Key Derivation:
        // `keccak256(abi.encodePacked(_state.initialCommitment, msg.sender, measurementData))`
        // This simplifies verification: `retrieveProtocolSecret(stateId, measurementData)` can recompute and check.
        // BUT this allows anyone with the right `measurementData` to get the key hash, not just the first measurer.
        // The uniqueness must come from the *first successful measurement* and the state being marked `isMeasured`.

        // FINAL Key Derivation & Access Plan:
        // 1. `measureQuantumState(stateId, measurementData)`: Derives `keyHash = keccak256(abi.encodePacked(state.initialCommitment, msg.sender, block.timestamp, block.number, measurementData))`. Stores `keyHash` in state, sets `validMeasuredKeys[keyHash] = true`, sets `isMeasured = true`. Returns `keyHash`. User receives this hash and knows their `measurementData`.
        // 2. `retrieveProtocolSecret(stateId, userProvidedMeasurementData)`: User provides the *original* `measurementData`. Contract re-derives `userKeyHash = keccak256(abi.encodePacked(state.initialCommitment, state.measuredBy, state.measuredTimestamp (new state field!), state.measuredBlockNumber (new state field!), userProvidedMeasurementData))`. Checks if `userKeyHash == state.measuredKeyHash` AND `validMeasuredKeys[state.measuredKeyHash]` is true.

        // Okay, let's update QuantumState struct and _deriveQuantumKeyHash, then fix retrieveProtocolSecret.

        // QuantumState struct update:
        // uint48 measuredTimestamp;
        // uint256 measuredBlockNumber;

        // _deriveQuantumKeyHash update:
        // Now used *only* during `measureQuantumState`. Derives key hash based on *current* block context.
        // Returns bytes32 derivedKeyHash.

        // retrieveProtocolSecret update:
        // Takes `stateId` and `bytes memory userProvidedMeasurementData`.
        // Requires state is measured.
        // Re-derives `userAttemptKeyHash` using the *stored* `state.measuredBy`, `state.measuredTimestamp`, `state.measuredBlockNumber`, and the provided `userProvidedMeasurementData`.
        // Checks if `userAttemptKeyHash == state.measuredKeyHash` AND `validMeasuredKeys[state.measuredKeyHash]`.

        // This ensures only the person who successfully measured the state *first*, using their specific data at that specific time, can derive the correct key hash later to prove access.

        // Reverting struct and derivation for simplicity of this example, assuming user keeps track of their derived key hash.
        // The `retrieveProtocolSecret` will take the *derived key hash* the user got from `measureQuantumState`.

        // CORRECTED retrieveProtocolSecret:
        // Takes `stateId` and the `bytes32 derivedKeyHash`.
        // Checks if `state.isMeasured`.
        // Checks if `derivedKeyHash == state.measuredKeyHash`.
        // Checks if `validMeasuredKeys[derivedKeyHash]`.
        // Retrieves secret.

        require(state.isMeasured, "QKP: State not measured");
        require(!state.isRevoked, "QKP: State revoked");
        // require(!_isDecohered(state), "QKP: State has decohered"); // Optional based on access model after collapse

        // Verify the provided key hash matches the one stored upon measurement
        require(derivedKey == state.measuredKeyHash, "QKP: Invalid derived key hash for this state");
        // Verify the key hash hasn't been invalidated by the owner
        require(validMeasuredKeys[derivedKey], "QKP: Derived key has been invalidated");

        bytes memory secret = protocolSecrets[state.associatedSecretId];
        require(secret.length > 0, "QKP: Associated secret not found"); // Should not happen if creation check is correct

        emit SecretRetrieved(stateId, msg.sender, state.associatedSecretId);
        return secret;
    }


    /**
     * @dev Allows the current owner of a state (before measurement) to transfer ownership.
     *      Measurement rights are transferred.
     * @param stateId The ID of the state to transfer.
     * @param newOwner The address of the new state owner.
     */
    function transferStateOwnership(uint256 stateId, address newOwner) external {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        QuantumState storage state = quantumStates[stateId];

        require(msg.sender == state.owner, "QKP: Only state owner can transfer");
        require(!state.isMeasured, "QKP: State already measured");
        require(!state.isRevoked, "QKP: State revoked");
        require(!_isDecohered(state), "QKP: State has decohered");
        require(newOwner != address(0), "QKP: New owner is the zero address");

        address oldOwner = state.owner;
        state.owner = newOwner;
        emit StateOwnershipTransferred(stateId, oldOwner, newOwner);
    }


    // --- View Functions ---

    /**
     * @dev Checks if a state is currently valid for measurement.
     * @param stateId The ID of the state to check.
     * @return bool True if valid, false otherwise.
     */
    function checkStateValidity(uint256 stateId) external view returns (bool) {
        if (stateId >= nextStateId) return false;
        QuantumState storage state = quantumStates[stateId];
        return !state.isMeasured && !state.isRevoked && !_isDecohered(state);
    }

     /**
     * @dev Gets the IDs of states linked to a given state.
     * @param stateId The ID of the state.
     * @return An array of linked state IDs.
     */
    function getLinkedStates(uint256 stateId) external view returns (uint256[] memory) {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        return quantumStates[stateId].linkedStates;
    }

    /**
     * @dev Gets the Secret ID associated with a state.
     * @param stateId The ID of the state.
     * @return The associated Secret ID.
     */
    function getAssociatedSecretId(uint256 stateId) external view returns (bytes32) {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        return quantumStates[stateId].associatedSecretId;
    }

    /**
     * @dev Checks if a state has decohered (expired).
     * @param stateId The ID of the state.
     * @return True if decohered, false otherwise.
     */
    function checkDecoherenceStatus(uint256 stateId) external view returns (bool) {
         if (stateId >= nextStateId) return true; // Treat non-existent as decohered/invalid
         QuantumState storage state = quantumStates[stateId];
         return _isDecohered(state);
    }

    /**
     * @dev Gets the minimum required length for measurement data.
     * @return The minimum length.
     */
    function getMinMeasurementDataLength() external view returns (uint256) {
        return minMeasurementDataLength;
    }

     /**
     * @dev Gets the current owner of a state.
     * @param stateId The ID of the state.
     * @return The state owner address.
     */
    function retrieveStateOwner(uint256 stateId) external view returns (address) {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        return quantumStates[stateId].owner;
    }

    /**
     * @dev Gets non-sensitive details of a Quantum State.
     * @param stateId The ID of the state.
     * @return A tuple containing initialCommitment, owner, isMeasured, isRevoked, creationTimestamp, decoherenceDuration, associatedSecretId.
     */
    function getQuantumStateDetails(uint256 stateId) external view returns (
        bytes32 initialCommitment,
        address stateOwner,
        bool isMeasured,
        bool isRevoked,
        uint48 creationTimestamp,
        uint48 decoherenceDuration,
        bytes32 associatedSecretId
    ) {
        require(stateId < nextStateId, "QKP: Invalid state ID");
        QuantumState storage state = quantumStates[stateId];
        return (
            state.initialCommitment,
            state.owner,
            state.isMeasured,
            state.isRevoked,
            state.creationTimestamp,
            state.decoherenceDuration,
            state.associatedSecretId
        );
    }

    /**
     * @dev Gets the total number of states created.
     * @return The total count.
     */
    function getTotalStates() external view returns (uint256) {
        return nextStateId;
    }

    /**
     * @dev Checks if a derived key hash is currently marked as valid for accessing secrets.
     * @param keyHash The hash of the derived key.
     * @return True if the key hash is valid, false otherwise.
     */
    function isKeyHashValid(bytes32 keyHash) external view returns (bool) {
        return validMeasuredKeys[keyHash];
    }
}
```