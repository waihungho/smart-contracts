Okay, let's create a smart contract that incorporates concepts inspired by quantum mechanics (metaphorically, of course, as actual quantum computation isn't possible on-chain) combined with complex state management, time decay, and multi-party interactions, moving beyond standard tokens or vaults.

We'll call it `QuantumVault`. It will manage "Quantum Keys" which have different states (Superposed, Entangled, Decoherent) and properties, and control access to "Quantum Energy" (represented by a simple uint256). Actions on one key can affect others based on simulated "entanglement." Keys can decay over time or require "measurement" to collapse their state.

---

## QuantumVault Smart Contract

**Outline:**

1.  **License and Pragma:** SPDX License Identifier and Solidity version.
2.  **Errors:** Custom errors for specific failure conditions.
3.  **Events:** Signals for key actions, state changes, energy transfers, etc.
4.  **Data Structures:**
    *   `KeyState`: Enum for key states (Decoherent, Superposed, Entangled).
    *   `QuantumKey`: Struct holding key properties (components, state, owner, timestamps, entangled partner).
    *   `UserQuantumState`: Struct tracking user's energy balance and held keys.
5.  **State Variables:**
    *   Owner address.
    *   Mappings for user states and quantum keys.
    *   Counters for key IDs.
    *   Global parameters (decoherence rate, entanglement probability).
    *   Placeholder for a potential 'Quantum Oracle' address (for external influence concept).
6.  **Modifiers:** `onlyOwner`.
7.  **Constructor:** Initializes owner and basic parameters.
8.  **Core Vault Functions:** Deposit and withdraw 'Quantum Energy'.
9.  **Quantum Key Management Functions:**
    *   Create, transfer, destroy keys.
    *   Get key details, list user keys.
10. **Quantum State Interaction Functions:**
    *   Explicitly update key state.
    *   Measure a superposed key (simulated state collapse).
    *   Entangle and disentangle keys.
    *   Apply time-based decoherence.
    *   Perform complex operations based on key state.
11. **Advanced/Experimental Functions:**
    *   Split and combine key components (simulating threshold access).
    *   Trigger entangled effects.
    *   Decay user's overall quantum state.
12. **Owner/Parameter Functions:**
    *   Set global parameters (decoherence, entanglement chance).
    *   Register/update oracle address.
13. **Getter Functions:** For state variables and derived information.

**Function Summary:**

1.  `constructor()`: Initializes contract, sets owner.
2.  `depositQuantumEnergy()`: Users deposit energy into their vault.
3.  `withdrawQuantumEnergy()`: Users withdraw energy from their vault. Requires specific key state.
4.  `createQuantumKey()`: Mints a new Quantum Key with initial components and Superposed state.
5.  `transferQuantumKey()`: Transfers ownership of a key to another address.
6.  `destroyQuantumKey()`: Burns a key.
7.  `updateKeyState()`: Allows explicit state change of a key under certain conditions.
8.  `measureSuperposedKey()`: Attempts to collapse a Superposed key to Decoherent state. Outcome can be probabilistic or state-dependent.
9.  `entangleKeys()`: Creates an entanglement link between two keys. Requires keys to be in specific states.
10. `disentangleKeys()`: Breaks the entanglement link between two keys.
11. `applyDecoherence()`: Explicitly applies time decay logic to a key, potentially changing its state to Decoherent.
12. `splitKeyComponents()`: Divides a key's components into multiple new keys (shares). The original key might become unusable.
13. `combineKeyComponents()`: Reconstructs an original key from a set of component keys. Requires a threshold number of components.
14. `performStateDependentOperation()`: A flexible function where the executed logic depends entirely on the state and properties of a provided key and the user's state.
15. `triggerEntangledEffect()`: Performing this on one entangled key *might* cause a state change or effect on its entangled partner based on probability and state.
16. `decayUserQuantumState()`: Applies time decay effects to a user's overall state, potentially reducing stored energy or changing key properties.
17. `setDecoherenceRate()`: Owner function to set the rate at which keys decay.
18. `setEntanglementProbability()`: Owner function to set the likelihood of entangled effects propagating.
19. `registerQuantumOracle()`: Owner function to set an address representing an external source of "quantum" influence or randomness.
20. `getUserKeyIds()`: Returns a list of Key IDs owned by a user.
21. `getKeyDetails()`: Returns the full struct details for a specific Quantum Key.
22. `getTotalKeysCreated()`: Returns the total number of keys ever created.
23. `getDecoherenceRate()`: Getter for the decoherence rate parameter.
24. `getEntanglementProbability()`: Getter for the entanglement probability parameter.
25. `getQuantumOracleAddress()`: Getter for the oracle address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A metaphorical smart contract simulating concepts inspired by quantum mechanics,
 *      managing 'Quantum Energy' and complex-state 'Quantum Keys'.
 *      Features state superposition, entanglement simulation, time-based decoherence,
 *      and operations dependent on key/user states.
 */
contract QuantumVault {

    // --- Custom Errors ---
    error NotOwner();
    error ZeroAddressNotAllowed();
    error KeyNotFound(uint256 keyId);
    error NotKeyOwner(uint256 keyId);
    error InvalidKeyComponents();
    error InvalidKeyStateForOperation(uint256 keyId, KeyState requiredState);
    error InvalidKeyStateTransition(uint256 keyId, KeyState currentState, KeyState newState);
    error KeysAlreadyEntangled(uint256 keyId1, uint256 keyId2);
    error KeysNotEntangled(uint256 keyId1, uint256 keyId2);
    error CannotEntangleKeyToItself(uint256 keyId);
    error NotEnoughEnergy(address user, uint256 required, uint256 available);
    error OperationFailedDueToQuantumState(uint256 keyId, KeyState currentState);
    error InsufficientKeyComponents(uint256 required, uint256 provided);
    error CannotSplitEntangledKey(uint256 keyId);
    error CannotCombineEntangledComponents();
    error InvalidComponentKeys();
    error KeyComponentsNotDecoherent();


    // --- Events ---
    event QuantumEnergyDeposited(address indexed user, uint256 amount);
    event QuantumEnergyWithdrawn(address indexed user, uint256 amount);
    event QuantumKeyCreated(uint256 indexed keyId, address indexed owner, KeyState initialState);
    event QuantumKeyTransferred(uint256 indexed keyId, address indexed from, address indexed to);
    event QuantumKeyDestroyed(uint256 indexed keyId, address indexed owner);
    event KeyStateUpdated(uint256 indexed keyId, KeyState oldState, KeyState newState, string reason);
    event KeyMeasured(uint256 indexed keyId, bool success, KeyState finalState);
    event KeysEntangled(uint256 indexed keyId1, uint256 indexed keyId2);
    event KeysDisentangled(uint256 indexed keyId1, uint256 indexed keyId2);
    event DecoherenceApplied(uint256 indexed keyId, uint256 decayAmount, KeyState finalState);
    event KeyComponentsSplit(uint256 indexed originalKeyId, address indexed owner, uint256[] componentKeyIds);
    event KeyComponentsCombined(uint256 indexed reconstructedKeyId, address indexed owner, uint256[] componentKeyIds);
    event StateDependentOperationPerformed(address indexed user, uint256 indexed keyId, uint256 operationCode, bool success);
    event EntangledEffectTriggered(uint256 indexed sourceKeyId, uint256 indexed targetKeyId, string effectDescription);
    event UserQuantumStateDecayed(address indexed user, uint256 energyLost);
    event DecoherenceRateUpdated(uint256 newRate);
    event EntanglementProbabilityUpdated(uint256 newProbability);
    event QuantumOracleRegistered(address indexed oracleAddress);


    // --- Data Structures ---
    enum KeyState {
        Decoherent,  // Fixed, stable state
        Superposed,  // Potential multiple states until 'measured'
        Entangled    // State linked to another key
    }

    struct QuantumKey {
        uint256[] components;       // Represents complex properties of the key
        KeyState state;             // Current quantum state
        address owner;              // Current owner address
        uint62 creationTime;        // Timestamp of creation (uint62 saves gas vs uint256)
        uint62 lastInteractionTime; // Timestamp of last major interaction
        uint256 entangledKeyId;     // ID of the key it's entangled with (0 if none)
        bool isComponent;           // True if this key is a piece of a split key
    }

    struct UserQuantumState {
        uint256 storedEnergy;                       // User's energy balance
        mapping(uint256 => bool) heldKeys;          // Map of key IDs owned by user
        uint62 lastQuantumOpTime;                   // Timestamp of last complex operation for user
        uint256[] ownedKeyIds;                      // Array of key IDs owned by user (simpler to iterate)
    }


    // --- State Variables ---
    address private immutable i_owner;
    mapping(address => UserQuantumState) private userStates;
    mapping(uint256 => QuantumKey) private quantumKeys;
    uint256 private nextKeyId = 1; // Start key IDs from 1

    // Global Parameters (simulating environmental factors)
    uint256 private decoherenceRate = 100; // Energy/unit of time lost due to decoherence (higher means faster decay)
    uint256 private entanglementProbability = 50; // % chance an entangled effect propagates (0-100)
    uint256 private keyDecayThreshold = 3600; // Time in seconds after which a key is subject to decay checks
    uint256 private keyDecayEnergyEffect = 10; // Energy lost from user state per decaying key
    uint256 private constant KEY_COMPONENT_THRESHOLD = 3; // Minimum components needed to combine

    address private quantumOracleAddress; // Address of a hypothetical oracle influencing outcomes

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        i_owner = msg.sender;
    }

    // --- Core Vault Functions ---

    /**
     * @dev Allows users to deposit Quantum Energy.
     * @param amount The amount of energy to deposit.
     */
    function depositQuantumEnergy(uint256 amount) external {
        userStates[msg.sender].storedEnergy += amount;
        emit QuantumEnergyDeposited(msg.sender, amount);
    }

    /**
     * @dev Allows users to withdraw Quantum Energy.
     *      Requires the user's overall quantum state to be sufficiently "decoherent".
     *      Also triggers a check for key decoherence.
     * @param amount The amount of energy to withdraw.
     */
    function withdrawQuantumEnergy(uint256 amount) external {
        // Simulate needing a stable state to withdraw
        _decayUserQuantumState(msg.sender); // Implicit decay check

        if (userStates[msg.sender].storedEnergy < amount) {
            revert NotEnoughEnergy(msg.sender, amount, userStates[msg.sender].storedEnergy);
        }
        // In a real scenario, potentially check states of owned keys for withdrawal eligibility
        // For this example, we just apply user state decay as the 'cost'

        userStates[msg.sender].storedEnergy -= amount;
        emit QuantumEnergyWithdrawn(msg.sender, amount);
    }

    // --- Quantum Key Management Functions ---

    /**
     * @dev Creates a new Quantum Key.
     *      Initial state is Superposed. Components are generated based on block data (simplified).
     * @return The ID of the newly created key.
     */
    function createQuantumKey() external returns (uint256) {
        uint256 keyId = nextKeyId++;
        uint256 timestamp = block.timestamp;

        // Simulate unique components based on recent block data and key ID
        uint256[] memory components = new uint256[](3); // Example: 3 components
        components[0] = uint256(keccak256(abi.encodePacked(block.number, timestamp, keyId, msg.sender))) % 1000;
        components[1] = uint256(keccak256(abi.encodePacked(block.difficulty, timestamp, keyId, msg.sender))) % 1000;
        components[2] = uint256(keccak256(abi.encodePacked(block.basefee, timestamp, keyId, msg.sender))) % 1000;


        quantumKeys[keyId] = QuantumKey({
            components: components,
            state: KeyState.Superposed, // New keys start Superposed
            owner: msg.sender,
            creationTime: uint62(timestamp),
            lastInteractionTime: uint62(timestamp),
            entangledKeyId: 0, // Not entangled initially
            isComponent: false
        });

        userStates[msg.sender].heldKeys[keyId] = true;
        userStates[msg.sender].ownedKeyIds.push(keyId);

        emit QuantumKeyCreated(keyId, msg.sender, KeyState.Superposed);
        return keyId;
    }

    /**
     * @dev Transfers ownership of a Quantum Key.
     *      Requires the key to be in a Decoherent state for stable transfer.
     * @param keyId The ID of the key to transfer.
     * @param to The recipient address.
     */
    function transferQuantumKey(uint256 keyId, address to) external {
        QuantumKey storage key = quantumKeys[keyId];
        if (key.owner == address(0)) revert KeyNotFound(keyId);
        if (key.owner != msg.sender) revert NotKeyOwner(keyId);
        if (to == address(0)) revert ZeroAddressNotAllowed();

        // Keys must be Decoherent for stable transfer
        if (key.state != KeyState.Decoherent) {
            revert InvalidKeyStateForOperation(keyId, KeyState.Decoherent);
        }
        if (key.entangledKeyId != 0) {
             revert CannotTransferEntangledKey(keyId);
        }

        // Remove from old owner's list/map
        userStates[msg.sender].heldKeys[keyId] = false;
        _removeKeyIdFromOwnedList(msg.sender, keyId); // Helper to keep array clean

        // Update key ownership
        key.owner = to;
        key.lastInteractionTime = uint62(block.timestamp);

        // Add to new owner's list/map
        userStates[to].heldKeys[keyId] = true;
        userStates[to].ownedKeyIds.push(keyId);

        emit QuantumKeyTransferred(keyId, msg.sender, to);
    }

     /**
     * @dev Internal helper to remove a key ID from the ownedKeyIds array.
     *      Maintains array integrity.
     * @param user The address whose list to update.
     * @param keyId The key ID to remove.
     */
    function _removeKeyIdFromOwnedList(address user, uint256 keyId) internal {
        uint256[] storage ownedKeys = userStates[user].ownedKeyIds;
        for (uint i = 0; i < ownedKeys.length; i++) {
            if (ownedKeys[i] == keyId) {
                // Replace with last element and pop
                ownedKeys[i] = ownedKeys[ownedKeys.length - 1];
                ownedKeys.pop();
                return; // Assuming each key ID appears only once
            }
        }
    }


    /**
     * @dev Destroys a Quantum Key, effectively burning it.
     *      Only Decoherent keys can be safely destroyed.
     * @param keyId The ID of the key to destroy.
     */
    function destroyQuantumKey(uint256 keyId) external {
        QuantumKey storage key = quantumKeys[keyId];
        if (key.owner == address(0)) revert KeyNotFound(keyId);
        if (key.owner != msg.sender) revert NotKeyOwner(keyId);

        // Only Decoherent keys can be destroyed
        if (key.state != KeyState.Decoherent) {
            revert InvalidKeyStateForOperation(keyId, KeyState.Decoherent);
        }
        if (key.entangledKeyId != 0) {
             revert CannotDestroyEntangledKey(keyId);
        }
         if (key.isComponent) {
             revert CannotDestroyComponentKey(keyId);
         }


        // Remove from owner's list/map
        userStates[msg.sender].heldKeys[keyId] = false;
         _removeKeyIdFromOwnedList(msg.sender, keyId);


        // Delete key data
        delete quantumKeys[keyId];

        emit QuantumKeyDestroyed(keyId, msg.sender);
    }

     /**
     * @dev Gets the details of a specific Quantum Key.
     * @param keyId The ID of the key.
     * @return The QuantumKey struct.
     */
    function getKeyDetails(uint256 keyId) external view returns (QuantumKey memory) {
        QuantumKey storage key = quantumKeys[keyId];
        if (key.owner == address(0) && keyId != 0) revert KeyNotFound(keyId); // Allow checking for 0 key

        // Return a memory copy
        return quantumKeys[keyId];
    }

     /**
     * @dev Gets the list of Key IDs owned by a user.
     * @param user The address of the user.
     * @return An array of key IDs.
     */
    function getUserKeyIds(address user) external view returns (uint256[] memory) {
        return userStates[user].ownedKeyIds;
    }


    // --- Quantum State Interaction Functions ---

    /**
     * @dev Allows updating the state of a key.
     *      State transitions might be restricted based on current state.
     *      (e.g., cannot go from Decoherent back to Superposed directly).
     * @param keyId The ID of the key.
     * @param newState The desired new state.
     */
    function updateKeyState(uint256 keyId, KeyState newState) external {
        QuantumKey storage key = quantumKeys[keyId];
        if (key.owner == address(0)) revert KeyNotFound(keyId);
        if (key.owner != msg.sender) revert NotKeyOwner(keyId);
        if (key.isComponent) revert CannotUpdateComponentKeyState(keyId);

        KeyState oldState = key.state;

        // Define valid state transitions (simplified)
        bool isValidTransition = false;
        if (oldState == newState) isValidTransition = true; // No change
        else if (oldState == KeyState.Superposed && newState == KeyState.Decoherent) isValidTransition = true; // Measurement-like collapse
        else if (oldState == KeyState.Decoherent && newState == KeyState.Entangled) isValidTransition = true; // Explicit entanglement (requires another key)
        else if (oldState == KeyState.Entangled && newState == KeyState.Decoherent) isValidTransition = true; // Explicit disentanglement

        if (!isValidTransition) {
            revert InvalidKeyStateTransition(keyId, oldState, newState);
        }

        key.state = newState;
        key.lastInteractionTime = uint62(block.timestamp);
        emit KeyStateUpdated(keyId, oldState, newState, "Manual Update");
    }

    /**
     * @dev Attempts to 'measure' a Superposed key.
     *      This operation collapses the state to Decoherent.
     *      The outcome might be influenced by environmental factors (oracle) or internal state.
     *      Simulated probabilistic failure or side effects could be added here.
     * @param keyId The ID of the key to measure.
     */
    function measureSuperposedKey(uint256 keyId) external {
        QuantumKey storage key = quantumKeys[keyId];
        if (key.owner == address(0)) revert KeyNotFound(keyId);
        if (key.owner != msg.sender) revert NotKeyOwner(keyId);
         if (key.isComponent) revert CannotMeasureComponentKey(keyId);

        if (key.state != KeyState.Superposed) {
            revert InvalidKeyStateForOperation(keyId, KeyState.Superposed);
        }

        // Simulate "measurement": Always collapses to Decoherent in this simple version
        // Advanced: Add probabilistic failure or side effects based on components, oracle, etc.
        // Example: if (quantumOracleAddress != address(0)) { ... } or check hash of components/block data

        key.state = KeyState.Decoherent;
        key.lastInteractionTime = uint62(block.timestamp);

        // Potentially modify components slightly based on "measurement"
        // key.components[0] = (key.components[0] + 1) % 1000; // Example side effect

        emit KeyMeasured(keyId, true, KeyState.Decoherent);
        emit KeyStateUpdated(keyId, KeyState.Superposed, KeyState.Decoherent, "Measurement");
    }

    /**
     * @dev Attempts to entangle two Decoherent keys.
     *      Links their states such that operations on one can affect the other.
     * @param keyId1 The ID of the first key.
     * @param keyId2 The ID of the second key.
     */
    function entangleKeys(uint256 keyId1, uint256 keyId2) external {
        if (keyId1 == keyId2) revert CannotEntangleKeyToItself(keyId1);

        QuantumKey storage key1 = quantumKeys[keyId1];
        QuantumKey storage key2 = quantumKeys[keyId2];

        if (key1.owner == address(0)) revert KeyNotFound(keyId1);
        if (key2.owner == address(0)) revert KeyNotFound(keyId2);

        // Both keys must be owned by the sender to entangle them
        if (key1.owner != msg.sender) revert NotKeyOwner(keyId1);
        if (key2.owner != msg.sender) revert NotKeyOwner(keyId2);

         if (key1.isComponent || key2.isComponent) revert CannotEntangleComponentKeys();


        // Keys must be Decoherent to initiate entanglement (stable state)
        if (key1.state != KeyState.Decoherent) revert InvalidKeyStateForOperation(keyId1, KeyState.Decoherent);
        if (key2.state != KeyState.Decoherent) revert InvalidKeyStateForOperation(keyId2, KeyState.Decoherent);

        // Cannot entangle keys that are already entangled
        if (key1.entangledKeyId != 0 || key2.entangledKeyId != 0) revert KeysAlreadyEntangled(keyId1, keyId2);

        // Create the entanglement link
        key1.entangledKeyId = keyId2;
        key2.entangledKeyId = keyId1;

        // Change states to Entangled
        key1.state = KeyState.Entangled;
        key2.state = KeyState.Entangled;

        key1.lastInteractionTime = uint62(block.timestamp);
        key2.lastInteractionTime = uint62(block.timestamp);

        emit KeysEntangled(keyId1, keyId2);
        emit KeyStateUpdated(keyId1, KeyState.Decoherent, KeyState.Entangled, "Entanglement");
        emit KeyStateUpdated(keyId2, KeyState.Decoherent, KeyState.Entangled, "Entanglement");
    }

    /**
     * @dev Attempts to disentangle two entangled keys.
     *      Breaks their state link and returns them to Decoherent state.
     * @param keyId1 The ID of the first key.
     * @param keyId2 The ID of the second key.
     */
    function disentangleKeys(uint256 keyId1, uint256 keyId2) external {
         if (keyId1 == keyId2) revert CannotDisentangleKeyToItself(keyId1);

        QuantumKey storage key1 = quantumKeys[keyId1];
        QuantumKey storage key2 = quantumKeys[keyId2];

        if (key1.owner == address(0)) revert KeyNotFound(keyId1);
        if (key2.owner == address(0)) revert KeyNotFound(keyId2);

        // Both keys must be owned by the sender to disentangle them
        if (key1.owner != msg.sender) revert NotKeyOwner(keyId1);
        if (key2.owner != msg.sender) revert NotKeyOwner(keyId2);

        // Keys must be Entangled with each other
        if (key1.state != KeyState.Entangled || key2.state != KeyState.Entangled || key1.entangledKeyId != keyId2 || key2.entangledKeyId != keyId1) {
            revert KeysNotEntangled(keyId1, keyId2);
        }

        // Break the entanglement link
        key1.entangledKeyId = 0;
        key2.entangledKeyId = 0;

        // Change states back to Decoherent
        key1.state = KeyState.Decoherent;
        key2.state = KeyState.Decoherent;

        key1.lastInteractionTime = uint62(block.timestamp);
        key2.lastInteractionTime = uint62(block.timestamp);

        emit KeysDisentangled(keyId1, keyId2);
        emit KeyStateUpdated(keyId1, KeyState.Entangled, KeyState.Decoherent, "Disentanglement");
        emit KeyStateUpdated(keyId2, KeyState.Entangled, KeyState.Decoherent, "Disentanglement");
    }

    /**
     * @dev Explicitly applies time-based decoherence logic to a key.
     *      If a key hasn't been interacted with for a threshold period,
     *      its state might automatically collapse to Decoherent,
     *      and potentially decay its components or affect user energy.
     * @param keyId The ID of the key to apply decoherence to.
     */
    function applyDecoherence(uint256 keyId) external {
        QuantumKey storage key = quantumKeys[keyId];
        if (key.owner == address(0)) revert KeyNotFound(keyId);
        // Anyone can trigger decoherence for a key that meets criteria, but owner pays gas
        // if (key.owner != msg.sender) revert NotKeyOwner(keyId); // Decided against this for more public decay

        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastInteraction = currentTime - key.lastInteractionTime;

        // Only apply if past threshold and not already Decoherent
        if (timeSinceLastInteraction >= keyDecayThreshold && key.state != KeyState.Decoherent) {

            KeyState oldState = key.state;
            key.state = KeyState.Decoherent; // Collapse to Decoherent

            // Simulate decay effect: reduce component values or user energy
            uint256 decayAmount = (timeSinceLastInteraction / keyDecayThreshold) * decoherenceRate;
            decayAmount = decayAmount > userStates[key.owner].storedEnergy ? userStates[key.owner].storedEnergy : decayAmount; // Cap decay

            userStates[key.owner].storedEnergy -= decayAmount;

            // Optionally decay key components (e.g., reduce values or number)
             for(uint i = 0; i < key.components.length; i++) {
                 key.components[i] = key.components[i] > (decayAmount/key.components.length) ? key.components[i] - (decayAmount/key.components.length) : 0;
             }


            key.lastInteractionTime = uint62(currentTime); // Decay counts as interaction

            emit DecoherenceApplied(keyId, decayAmount, KeyState.Decoherent);
            emit KeyStateUpdated(keyId, oldState, KeyState.Decoherent, "Decoherence");
            if (decayAmount > 0) {
                 emit UserQuantumStateDecayed(key.owner, decayAmount);
            }
        } else {
             // Event for no decay applied? Or just silent return. Let's be silent.
        }
    }

    /**
     * @dev Performs a generic operation whose outcome depends on the provided key's state
     *      and potentially other factors (user state, oracle, components).
     *      This function serves as a pattern for state-dependent logic.
     * @param keyId The ID of the key to use for the operation.
     * @param operationCode A code specifying the type of operation (defined application-side).
     * @param data An arbitrary bytes payload for operation-specific data.
     * @return success True if the operation succeeded based on state.
     */
    function performStateDependentOperation(uint256 keyId, uint256 operationCode, bytes calldata data) external returns (bool success) {
        QuantumKey storage key = quantumKeys[keyId];
        if (key.owner == address(0)) revert KeyNotFound(keyId);
        if (key.owner != msg.sender) revert NotKeyOwner(keyId);
         if (key.isComponent) revert CannotUseComponentKeyForOperation(keyId);

        // Apply implicit decoherence check before using the key
        uint256 currentTime = block.timestamp;
        if (currentTime - key.lastInteractionTime >= keyDecayThreshold && key.state != KeyState.Decoherent) {
             applyDecoherence(keyId); // Apply decay if due
        }


        // Logic branches based on key state
        success = false;
        string memory effect = "No effect";

        if (key.state == KeyState.Decoherent) {
            // Decoherent state: Predictable outcomes.
            // Example: If operationCode is 1, perform action A; if 2, action B.
            // Logic here would be stable and deterministic based on operationCode and component values.
             if (operationCode == 1) {
                 // Example: Use component values to calculate a result
                 uint256 result = key.components[0] + key.components[1];
                 // Do something with result... maybe modify user state or emit a specific event
                 if (result > 500) success = true; // Example success condition
                 effect = "Decoherent outcome based on components";
             } else if (operationCode == 2) {
                 // Example: Stable state allows complex interaction with user energy
                 if (userStates[msg.sender].storedEnergy >= 100) {
                     userStates[msg.sender].storedEnergy -= 100; // Stable cost
                     success = true;
                     effect = "Decoherent energy interaction";
                     emit QuantumEnergyWithdrawn(msg.sender, 100);
                 } else {
                     revert NotEnoughEnergy(msg.sender, 100, userStates[msg.sender].storedEnergy);
                 }
             } else {
                 // Unknown operation code for this state
                 revert OperationFailedDueToQuantumState(keyId, key.state);
             }


        } else if (key.state == KeyState.Superposed) {
            // Superposed state: Outcome is uncertain until "observed" (this operation counts as observation).
            // Can use a pseudo-random factor (like block hash) or oracle to influence outcome.
            // This operation might also trigger an implicit measurement/collapse.

            // Simulate uncertainty - outcome depends on a hash of various factors
            uint256 influence = uint256(keccak256(abi.encodePacked(block.timestamp, tx.origin, data, key.components, quantumOracleAddress)));
            uint256 outcomeFactor = influence % 100;

            if (operationCode == 1) {
                // Operation 1 in Superposed state has probabilistic success
                if (outcomeFactor < 70) { // 70% chance of success
                    success = true;
                    effect = "Superposed operation succeeded probabilistically";
                    // It *might* collapse the state upon successful operation
                     if (outcomeFactor < 30) { // 30% chance of collapse on success
                         key.state = KeyState.Decoherent;
                         emit KeyMeasured(keyId, true, KeyState.Decoherent);
                         emit KeyStateUpdated(keyId, KeyState.Superposed, KeyState.Decoherent, "Implicit Measurement");
                     }
                } else {
                    success = false;
                    effect = "Superposed operation failed probabilistically";
                    // It *might* collapse state upon failure
                    if (outcomeFactor >= 90) { // 10% chance of collapse on failure
                         key.state = KeyState.Decoherent;
                         emit KeyMeasured(keyId, false, KeyState.Decoherent);
                         emit KeyStateUpdated(keyId, KeyState.Superposed, KeyState.Decoherent, "Implicit Measurement");
                    }
                }
            } else if (operationCode == 2) {
                 // Operation 2 in Superposed state might cost variable energy
                 uint256 cost = 50 + (outcomeFactor); // Cost is somewhat uncertain
                 if (userStates[msg.sender].storedEnergy >= cost) {
                     userStates[msg.sender].storedEnergy -= cost;
                     success = true;
                     effect = string(abi.encodePacked("Superposed energy interaction, cost: ", Strings.toString(cost))); // Need Strings util or manual itoa
                     emit QuantumEnergyWithdrawn(msg.sender, cost);
                 } else {
                     revert NotEnoughEnergy(msg.sender, cost, userStates[msg.sender].storedEnergy);
                 }
            } else {
                // Unknown operation code for this state
                revert OperationFailedDueToQuantumState(keyId, key.state);
            }

        } else if (key.state == KeyState.Entangled) {
            // Entangled state: Operation might trigger effects on the entangled partner.
            // Outcome might depend on *both* key states and potentially the oracle.

            uint256 partnerKeyId = key.entangledKeyId;
            if (partnerKeyId == 0) { // Should not happen if state is Entangled, but safety check
                 revert OperationFailedDueDueToQuantumState(keyId, key.state); // Or a specific error
            }
            QuantumKey storage partnerKey = quantumKeys[partnerKeyId];
             if (partnerKey.owner == address(0) || partnerKey.entangledKeyId != keyId) {
                  // Entangled partner is missing or link is broken unexpectedly
                 revert OperationFailedDueDueToQuantumState(keyId, key.state); // Indicates a broken link
             }


            // Example logic for Entangled state operations
            if (operationCode == 1) {
                // Operation 1 in Entangled state: Success depends on BOTH key states and perhaps entanglement probability
                 if (partnerKey.state == KeyState.Entangled) { // Both must be stable in entanglement
                    uint256 influence = uint256(keccak256(abi.encodePacked(block.timestamp, key.components, partnerKey.components, entanglementProbability, quantumOracleAddress)));
                     if (influence % 100 < entanglementProbability) { // Check probability
                         success = true;
                         effect = "Entangled operation successful, triggering partner effect?";
                         // Automatically try to trigger entangled effect
                         _triggerEntangledEffect(keyId, partnerKeyId);
                     } else {
                         success = false;
                         effect = "Entangled operation failed probability check.";
                     }
                 } else {
                    // Partner key not in correct state for this operation
                    revert OperationFailedDueDueToQuantumState(partnerKeyId, partnerKey.state);
                 }
            } else {
                 // Unknown operation code for this state
                 revert OperationFailedDueDueToQuantumState(keyId, key.state);
            }
        }

        key.lastInteractionTime = uint62(block.timestamp); // Update interaction time
        userStates[msg.sender].lastQuantumOpTime = uint62(block.timestamp); // Update user interaction time

        emit StateDependentOperationPerformed(msg.sender, keyId, operationCode, success);
        // Consider emitting specific events for successful/failed effects within the branches

        return success;
    }


    // --- Advanced/Experimental Functions ---

    /**
     * @dev Internal function to trigger an effect on an entangled partner key.
     *      Called from `performStateDependentOperation` or similar.
     *      The effect depends on the entanglement probability and current states.
     * @param sourceKeyId The key initiating the effect.
     * @param targetKeyId The key that might be affected.
     */
    function _triggerEntangledEffect(uint256 sourceKeyId, uint256 targetKeyId) internal {
         QuantumKey storage sourceKey = quantumKeys[sourceKeyId];
         QuantumKey storage targetKey = quantumKeys[targetKeyId];

         // Ensure they are still entangled with each other
         if (sourceKey.entangledKeyId != targetKeyId || targetKey.entangledKeyId != sourceKeyId || sourceKey.state != KeyState.Entangled || targetKey.state != KeyState.Entangled) {
             // Link broken or state changed during operation - emit warning or revert? Let's just exit.
             return;
         }

         // Simulate probabilistic effect propagation
         uint256 probabilitySeed = uint256(keccak256(abi.encodePacked(block.timestamp, tx.gasprice, sourceKey.components, targetKey.components, entanglementProbability, quantumOracleAddress)));

         if (probabilitySeed % 100 < entanglementProbability) {
             // Effect propagates! Simulate a state change on the target key.
             // Example: Force target key to Decoherent state, regardless of its owner
             targetKey.state = KeyState.Decoherent;
             targetKey.entangledKeyId = 0; // Disentangle upon state collapse
             sourceKey.entangledKeyId = 0; // Also disentangle the source

             targetKey.lastInteractionTime = uint62(block.timestamp);
             sourceKey.lastInteractionTime = uint62(block.timestamp);


             emit EntangledEffectTriggered(sourceKeyId, targetKeyId, "Forced Decoherence and Disentanglement");
             emit KeyStateUpdated(targetKeyId, KeyState.Entangled, KeyState.Decoherent, "Entangled Effect");
              emit KeyStateUpdated(sourceKeyId, KeyState.Entangled, KeyState.Decoherent, "Entangled Effect");
             emit KeysDisentangled(sourceKeyId, targetKeyId);

         } else {
             // Effect did not propagate
             emit EntangledEffectTriggered(sourceKeyId, targetKeyId, "No effect propagation");
         }
    }

    /**
     * @dev Simulates splitting a key into multiple component keys.
     *      Requires the key to be Decoherent and not Entangled.
     *      The original key is marked as 'isComponent' and becomes unusable for most ops.
     * @param keyId The ID of the key to split.
     * @return An array of the new component key IDs.
     */
    function splitKeyComponents(uint256 keyId) external returns (uint256[] memory) {
        QuantumKey storage originalKey = quantumKeys[keyId];
        if (originalKey.owner == address(0)) revert KeyNotFound(keyId);
        if (originalKey.owner != msg.sender) revert NotKeyOwner(keyId);
        if (originalKey.state != KeyState.Decoherent) revert InvalidKeyStateForOperation(keyId, KeyState.Decoherent);
        if (originalKey.entangledKeyId != 0) revert CannotSplitEntangledKey(keyId);
        if (originalKey.isComponent) revert KeyAlreadySplitOrIsComponent(keyId); // Cannot split a component or already split key
        if (originalKey.components.length == 0) revert InvalidKeyComponents(); // Needs components to split

        uint256 numComponents = originalKey.components.length;
        uint256[] memory componentKeyIds = new uint256[](numComponents);

        originalKey.isComponent = true; // Original key becomes just a marker, no longer usable directly

        for (uint i = 0; i < numComponents; i++) {
            uint256 componentId = nextKeyId++;
            // Each new key gets only one component from the original
            uint256[] memory singleComponent = new uint256[](1);
            singleComponent[0] = originalKey.components[i];

            quantumKeys[componentId] = QuantumKey({
                components: singleComponent,
                state: KeyState.Decoherent, // Components are Decoherent by default
                owner: msg.sender,
                creationTime: uint62(block.timestamp),
                lastInteractionTime: uint62(block.timestamp),
                entangledKeyId: 0,
                isComponent: true // Mark as a component key
            });

            userStates[msg.sender].heldKeys[componentId] = true;
             userStates[msg.sender].ownedKeyIds.push(componentId); // Add to owner's list

            componentKeyIds[i] = componentId;
            emit QuantumKeyCreated(componentId, msg.sender, KeyState.Decoherent);
        }

        emit KeyComponentsSplit(keyId, msg.sender, componentKeyIds);
        // Remove the original key from the owner's list of usable keys (optional, depending on desired behavior)
         _removeKeyIdFromOwnedList(msg.sender, keyId);


        return componentKeyIds;
    }

    /**
     * @dev Simulates combining component keys to reconstruct a key or access its power.
     *      Requires a threshold number of component keys.
     *      The component keys are consumed (destroyed).
     * @param componentKeyIds An array of the IDs of the component keys to combine.
     * @return The ID of the newly created/reconstructed key (or 0 if just for access).
     */
    function combineKeyComponents(uint256[] calldata componentKeyIds) external returns (uint256) {
        if (componentKeyIds.length < KEY_COMPONENT_THRESHOLD) {
            revert InsufficientKeyComponents(KEY_COMPONENT_THRESHOLD, componentKeyIds.length);
        }

        uint256[] memory combinedComponents = new uint256[](componentKeyIds.length);
        bool[] memory usedKeys = new bool[](nextKeyId); // Track used keys to prevent reuse

        // Validate and collect components
        for (uint i = 0; i < componentKeyIds.length; i++) {
            uint256 componentId = componentKeyIds[i];
            if (componentId == 0) revert InvalidComponentKeys();
            if (usedKeys[componentId]) revert DuplicateComponentKey(componentId); // Prevent using same key twice
            usedKeys[componentId] = true;

            QuantumKey storage componentKey = quantumKeys[componentId];
            if (componentKey.owner == address(0)) revert KeyNotFound(componentId);
            if (componentKey.owner != msg.sender) revert NotKeyOwner(componentId);
            if (!componentKey.isComponent) revert InvalidComponentKeys(); // Must be a component key
            if (componentKey.components.length != 1) revert InvalidComponentKeys(); // Component keys should have 1 element
            if (componentKey.state != KeyState.Decoherent) revert KeyComponentsNotDecoherent(); // Components must be stable
             if (componentKey.entangledKeyId != 0) revert CannotCombineEntangledComponents(); // Entangled components cannot be combined


            combinedComponents[i] = componentKey.components[0];
        }

        // In a real system, you might need to verify the components match a specific original key,
        // maybe by hashing or checking relationships. For simplicity, we just combine their values.
        // Example simple check: Do component counts match a known original? Or sum matches?

        // Simulate reconstructing a key or gaining temporary access
        uint256 newKeyId = nextKeyId++; // Create a new key ID
        uint256 timestamp = block.timestamp;

        // Create a new key from combined components
        quantumKeys[newKeyId] = QuantumKey({
            components: combinedComponents, // The combined components form the new key's components
            state: KeyState.Decoherent, // Reconstructed key starts Decoherent (stable state from stable components)
            owner: msg.sender,
            creationTime: uint62(timestamp),
            lastInteractionTime: uint62(timestamp),
            entangledKeyId: 0,
            isComponent: false // This is a new, full key
        });

         userStates[msg.sender].heldKeys[newKeyId] = true;
         userStates[msg.sender].ownedKeyIds.push(newKeyId);


        // Consume the component keys
        for (uint i = 0; i < componentKeyIds.length; i++) {
             uint256 componentId = componentKeyIds[i];
             userStates[msg.sender].heldKeys[componentId] = false;
             _removeKeyIdFromOwnedList(msg.sender, componentId);
             delete quantumKeys[componentId]; // Burn the component key
             emit QuantumKeyDestroyed(componentId, msg.sender);
        }

        emit KeyComponentsCombined(newKeyId, msg.sender, componentKeyIds);
        emit QuantumKeyCreated(newKeyId, msg.sender, KeyState.Decoherent);


        return newKeyId; // Return the ID of the newly formed key
    }


    /**
     * @dev Applies time decay effects to a user's overall quantum state.
     *      Simulates environmental influence degrading unused energy or state coherence.
     *      Called implicitly by some functions (like withdraw) or explicitly.
     * @param user The address of the user whose state is decaying.
     */
    function decayUserQuantumState(address user) external {
         // Make this function callable by anyone to trigger decay, similar to applyDecoherence
         // if (msg.sender != user && msg.sender != i_owner) revert Unauthorized(); // Decide access


        _decayUserQuantumState(user);
    }

    /**
     * @dev Internal logic for decaying user state.
     * @param user The address of the user.
     */
    function _decayUserQuantumState(address user) internal {
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastOp = currentTime - userStates[user].lastQuantumOpTime;

        // Apply decay if threshold passed (example logic)
        uint256 decayPeriods = timeSinceLastOp / (keyDecayThreshold * 2); // Decay threshold for user state is longer
        if (decayPeriods > 0) {
            uint256 energyLost = decayPeriods * (decoherenceRate / 5); // Less energy lost than per-key decay

            if (userStates[user].storedEnergy > 0) {
                 energyLost = energyLost > userStates[user].storedEnergy ? userStates[user].storedEnergy : energyLost;
                 userStates[user].storedEnergy -= energyLost;
                 emit UserQuantumStateDecayed(user, energyLost);
            }


            userStates[user].lastQuantumOpTime = uint62(currentTime); // Reset timer
        }
    }


    // --- Owner/Parameter Functions ---

    /**
     * @dev Owner sets the decoherence rate.
     * @param newRate The new rate (energy lost per decay period).
     */
    function setDecoherenceRate(uint256 newRate) external onlyOwner {
        decoherenceRate = newRate;
        emit DecoherenceRateUpdated(newRate);
    }

    /**
     * @dev Owner sets the entanglement probability.
     * @param newProbability The new probability (0-100).
     */
    function setEntanglementProbability(uint256 newProbability) external onlyOwner {
        if (newProbability > 100) revert InvalidProbability();
        entanglementProbability = newProbability;
        emit EntanglementProbabilityUpdated(newProbability);
    }

    /**
     * @dev Owner registers/updates the address of a hypothetical Quantum Oracle.
     *      This address could be used in future logic to introduce external factors.
     * @param oracleAddress The address of the oracle contract.
     */
    function registerQuantumOracle(address oracleAddress) external onlyOwner {
        // Optional: Add validation if oracleAddress must be a contract, or implement an interface
        quantumOracleAddress = oracleAddress;
        emit QuantumOracleRegistered(oracleAddress);
    }

    // --- Getter Functions ---

    /**
     * @dev Returns the total number of keys created.
     */
    function getTotalKeysCreated() external view returns (uint256) {
        return nextKeyId - 1; // nextKeyId is always one greater than the last created ID
    }

    /**
     * @dev Returns the current decoherence rate.
     */
    function getDecoherenceRate() external view returns (uint256) {
        return decoherenceRate;
    }

    /**
     * @dev Returns the current entanglement probability.
     */
    function getEntanglementProbability() external view returns (uint256) {
        return entanglementProbability;
    }

     /**
     * @dev Returns the address of the registered Quantum Oracle.
     */
    function getQuantumOracleAddress() external view returns (address) {
        return quantumOracleAddress;
    }

    /**
     * @dev Returns a user's stored energy balance.
     * @param user The address of the user.
     */
    function getUserEnergy(address user) external view returns (uint256) {
        return userStates[user].storedEnergy;
    }

    // Adding missing helper errors found during implementation
     error CannotTransferEntangledKey(uint256 keyId);
     error CannotDestroyEntangledKey(uint256 keyId);
     error CannotDestroyComponentKey(uint256 keyId);
     error CannotMeasureComponentKey(uint256 keyId);
     error CannotUpdateComponentKeyState(uint256 keyId);
     error CannotEntangleComponentKeys();
     error CannotDisentangleKeyToItself(uint256 keyId); // Although handled by logic, having error is good
     error KeyAlreadySplitOrIsComponent(uint256 keyId);
     error DuplicateComponentKey(uint256 keyId);
     error CannotUseComponentKeyForOperation(uint256 keyId);
     error OperationFailedDueDueToQuantumState(uint256 keyId, KeyState currentState);
     error CannotCombineEntangledComponents();
     error InvalidProbability(); // For setEntanglementProbability

      // Need Strings utility for event logging number
      // Adding a simple internal itoa for event
     library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
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
                digits--;
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
            return string(buffer);
        }
     }
}
```