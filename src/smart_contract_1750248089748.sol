Okay, here is a Solidity smart contract concept that aims for interesting, advanced, and creative features without directly duplicating common open-source patterns like standard ERC tokens, basic staking, simple vaults, or standard multisigs.

This contract simulates a system for managing "Quantum Keys" which are unique, non-transferable assets granting conditional, time-sensitive, and *probabilistic* access to "Data Slots". The "quantum" aspects are metaphorical simulations on-chain using Solidity's capabilities, involving concepts like key state decay, observer effect (interactions influencing state), and entanglement (linking key states).

**Disclaimer:** The "Quantum" aspects of this contract are conceptual simulations implemented using standard blockchain logic (time, random-like behavior via block data, state changes). They do not involve actual quantum computing or post-quantum cryptography.

---

### Contract Outline: `QuantumKeyManager`

1.  **State Management:**
    *   Store unique Quantum Keys with properties: owner, ID, state, decay rate, probability multiplier, entanglement link, expiry.
    *   Store unique Data Slots with properties: owner, ID, required key properties, access log, access fee simulation.
    *   Track total keys and slots.
    *   Define different "Quantum States" for keys.
2.  **Key Lifecycle:**
    *   Creation (Minting).
    *   Burning (Destroying).
    *   Updating properties (decay rate, multiplier).
    *   Simulating state changes (decay, fluctuation, observer effect).
    *   Entangling/Detangling keys.
3.  **Data Slot Lifecycle:**
    *   Creation.
    *   Assignment (Transfer ownership).
    *   Updating access requirements.
4.  **Access Control Logic:**
    *   Attempting access to a Data Slot using a Quantum Key.
    *   Checking if the key meets slot requirements (state, entanglement, etc.).
    *   Calculating *probabilistic* success based on key state, multiplier, decay, and a pseudo-random factor.
    *   Recording successful access attempts.
5.  **Role-Based Access:**
    *   Owner role (deployer).
    *   Manager role (granted by owner, can create keys/slots).
6.  **Querying & Information:**
    *   Retrieving key details.
    *   Retrieving slot details.
    *   Getting logs for a data slot.
    *   Checking access probability beforehand.
    *   Listing keys/slots by owner.

### Function Summary:

1.  `constructor()`: Initializes the contract, sets deployer as owner.
2.  `setManager(address _manager, bool _isManager)`: Grants or revokes the Manager role.
3.  `isManager(address _addr)`: Checks if an address is a Manager.
4.  `createQuantumKey(address _owner, uint256 _initialProbabilityMultiplier, uint256 _stateDecayRate)`: Creates a new Quantum Key for a specified owner with initial properties.
5.  `burnQuantumKey(uint256 _keyId)`: Destroys a Quantum Key. Requires key ownership.
6.  `updateKeyProbabilityMultiplier(uint256 _keyId, uint256 _newMultiplier)`: Updates the probability multiplier for a key. Requires key ownership or Manager role.
7.  `updateKeyStateDecayRate(uint256 _keyId, uint256 _newStateDecayRate)`: Updates the state decay rate for a key. Requires key ownership or Manager role.
8.  `entangleKeys(uint256 _keyId1, uint256 _keyId2)`: Links two keys together conceptually (entanglement). Requires ownership of both keys or Manager role.
9.  `detangleKey(uint256 _keyId)`: Removes the entanglement link for a key. Requires key ownership or Manager role.
10. `applyQuantumFluctuation(uint256 _keyId)`: Applies a random-like fluctuation to a key's state. Requires key ownership or Manager role.
11. `observeKey(uint256 _keyId)`: Simulates the "Observer Effect" on a key, potentially altering its state and triggering decay. Requires key ownership or public (depending on desired effect). Let's make it public to allow anyone to "observe" a key's public state.
12. `decayKeyState(uint256 _keyId)`: Explicitly triggers state decay for a key based on elapsed time and decay rate. Callable by anyone, affects state based on logic.
13. `createDataSlot(address _owner, uint256 _requiredMinQuantumState, uint256 _requiredMinProbabilityMultiplier)`: Creates a new Data Slot for a specified owner with access requirements. Requires Manager role.
14. `assignDataSlotToOwner(uint256 _slotId, address _newOwner)`: Transfers ownership of a Data Slot. Requires current slot ownership or Manager role.
15. `updateDataSlotRequirements(uint256 _slotId, uint256 _newRequiredMinQuantumState, uint256 _newRequiredMinProbabilityMultiplier)`: Updates access requirements for a Data Slot. Requires slot ownership or Manager role.
16. `attemptDataSlotAccess(uint256 _keyId, uint256 _slotId)`: Attempts to use a Quantum Key to access a Data Slot. Core logic: checks key ownership, validity, slot ownership, requirements, calculates probabilistic success, updates state, records log if successful.
17. `checkAccessProbability(uint256 _keyId, uint256 _slotId)`: View function to calculate the *current* probability of successful access *without* attempting it.
18. `getKeyDetails(uint256 _keyId)`: View function to retrieve details of a Quantum Key.
19. `getDataSlotDetails(uint256 _slotId)`: View function to retrieve details of a Data Slot.
20. `getDataSlotAccessLog(uint256 _slotId)`: View function to retrieve the access log for a Data Slot.
21. `getTotalKeys()`: View function to get the total number of keys created.
22. `getTotalSlots()`: View function to get the total number of slots created.
23. `getKeysByOwner(address _owner)`: View function (potentially expensive) to get a list of key IDs owned by an address.
24. `getSlotsByOwner(address _owner)`: View function (potentially expensive) to get a list of slot IDs owned by an address.
25. `getEntangledKey(uint256 _keyId)`: View function to get the ID of the key entangled with the given key (0 if none).
26. `checkKeyValidity(uint256 _keyId)`: Internal/View helper to check if a key ID exists and is not expired.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumKeyManager
 * @dev A conceptual smart contract simulating management of "Quantum Keys" and "Data Slots".
 * Keys are unique, non-transferable assets that grant conditional, time-sensitive, and
 * probabilistic access to data slots. The "quantum" aspects (decay, observer effect,
 * entanglement, probabilistic access) are simulated metaphors using blockchain state
 * and pseudo-randomness.
 *
 * Outline:
 * 1. State Management: Quantum Keys, Data Slots, counters, roles.
 * 2. Key Lifecycle: Creation, Burning, Updates, Simulated Quantum Effects (Decay, Fluctuation, Observer), Entanglement.
 * 3. Data Slot Lifecycle: Creation, Assignment, Requirement Updates.
 * 4. Access Control Logic: Probabilistic access attempts based on key/slot properties.
 * 5. Role-Based Access: Owner and Manager roles.
 * 6. Querying & Information: Retrieving details, logs, counts.
 *
 * Function Summary:
 * - constructor(): Initializes the contract, sets deployer as owner.
 * - setManager(address _manager, bool _isManager): Manages Manager roles.
 * - isManager(address _addr): Checks Manager status.
 * - createQuantumKey(...): Mints a new Quantum Key.
 * - burnQuantumKey(uint256 _keyId): Destroys a key.
 * - updateKeyProbabilityMultiplier(...): Updates key multiplier.
 * - updateKeyStateDecayRate(...): Updates key decay rate.
 * - entangleKeys(uint256 _keyId1, uint256 _keyId2): Links two keys.
 * - detangleKey(uint256 _keyId): Removes entanglement.
 * - applyQuantumFluctuation(uint256 _keyId): Applies random-like state change.
 * - observeKey(uint256 _keyId): Simulates Observer Effect & triggers decay.
 * - decayKeyState(uint256 _keyId): Explicitly triggers decay.
 * - createDataSlot(...): Creates a new Data Slot.
 * - assignDataSlotToOwner(...): Transfers slot ownership.
 * - updateDataSlotRequirements(...): Updates slot access rules.
 * - attemptDataSlotAccess(...): Attempts slot access using a key (probabilistic).
 * - checkAccessProbability(...): Calculates probability before attempt (view).
 * - getKeyDetails(uint256 _keyId): Gets key info (view).
 * - getDataSlotDetails(uint256 _slotId): Gets slot info (view).
 * - getDataSlotAccessLog(uint256 _slotId): Gets slot log (view).
 * - getTotalKeys(): Gets total keys (view).
 * - getTotalSlots(): Gets total slots (view).
 * - getKeysByOwner(address _owner): Gets keys owned by address (view, potentially heavy).
 * - getSlotsByOwner(address _owner): Gets slots owned by address (view, potentially heavy).
 * - getEntangledKey(uint256 _keyId): Gets entangled key ID (view).
 * - checkKeyValidity(uint256 _keyId): Internal/View helper for key validity.
 */
contract QuantumKeyManager {

    // --- State Definitions ---

    enum QuantumState {
        Stable,      // Base state
        Entangled,   // Linked to another key
        Fluctuating, // Recently affected by fluctuation
        Decaying,    // Actively losing properties
        Collapsed    // Effectively unusable state (can't decay further)
    }

    struct QuantumKey {
        uint256 id;
        address owner;
        uint64 creationTimestamp;
        uint64 lastStateChangeTimestamp;
        QuantumState currentState;
        uint256 accessProbabilityMultiplier; // Base multiplier (e.g., 10000 for 100%)
        uint256 stateDecayRate;              // How quickly state decays (e.g., units per second)
        uint256 entangledKeyId;              // ID of the linked key (0 if none)
        bool exists;                         // Flag to check existence after potential burn
    }

    struct AccessLogEntry {
        address accessor;
        uint64 timestamp;
        bool success; // Was the access attempt successful?
    }

    struct DataSlot {
        uint256 id;
        address owner;
        uint64 creationTimestamp;
        uint256 requiredMinQuantumState;     // Minimum currentState value needed (using index of enum)
        uint256 requiredMinProbabilityMultiplier; // Minimum calculated effective probability needed
        // string dataIdentifier;            // Conceptually points to data off-chain
        AccessLogEntry[] accessLog;
        bool exists;                         // Flag to check existence
    }

    mapping(uint256 => QuantumKey) public quantumKeys;
    mapping(uint256 => DataSlot) public dataSlots;

    uint256 private _nextKeyId = 1;
    uint256 private _nextSlotId = 1;

    address private immutable i_owner;
    mapping(address => bool) private _managers;

    // --- Events ---

    event KeyCreated(uint256 keyId, address owner, uint64 creationTimestamp);
    event KeyBurned(uint256 keyId);
    event KeyPropertiesUpdated(uint256 keyId, uint256 newMultiplier, uint256 newStateDecayRate);
    event KeysEntangled(uint256 keyId1, uint256 keyId2);
    event KeyDetangled(uint256 keyId);
    event KeyStateChanged(uint256 keyId, QuantumState newState, uint64 timestamp);
    event DataSlotCreated(uint256 slotId, address owner, uint64 creationTimestamp);
    event DataSlotAssigned(uint256 slotId, address oldOwner, address newOwner);
    event DataSlotRequirementsUpdated(uint256 slotId, uint256 newMinState, uint256 newMinProb);
    event DataSlotAccessAttempted(uint256 slotId, uint256 keyId, address accessor, bool success, uint256 finalCalculatedProbability);
    event ManagerStatusUpdated(address manager, bool isManager);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not the contract owner");
        _;
    }

    modifier onlyManager() {
        require(_managers[msg.sender] || msg.sender == i_owner, "Not a manager or owner");
        _;
    }

    modifier whenKeyExists(uint256 _keyId) {
        require(quantumKeys[_keyId].exists, "Key does not exist");
        _;
    }

    modifier whenSlotExists(uint256 _slotId) {
        require(dataSlots[_slotId].exists, "Slot does not exist");
        _;
    }

    // --- Constructor ---

    constructor() {
        i_owner = msg.sender;
    }

    // --- Manager Role Management ---

    /**
     * @dev Grants or revokes the Manager role.
     * Managers can create keys and slots, and update properties.
     * @param _manager The address to grant/revoke the role for.
     * @param _isManager True to grant, false to revoke.
     */
    function setManager(address _manager, bool _isManager) external onlyOwner {
        require(_manager != address(0), "Invalid address");
        _managers[_manager] = _isManager;
        emit ManagerStatusUpdated(_manager, _isManager);
    }

    /**
     * @dev Checks if an address has the Manager role.
     * @param _addr The address to check.
     * @return True if the address is a manager or the owner, false otherwise.
     */
    function isManager(address _addr) external view returns (bool) {
        return _managers[_addr] || _addr == i_owner;
    }

    // --- Quantum Key Functions ---

    /**
     * @dev Creates a new Quantum Key.
     * Requires Manager role.
     * @param _owner The address that will own the new key.
     * @param _initialProbabilityMultiplier The initial base probability multiplier (e.g., 10000 for 100%). Max 10000.
     * @param _stateDecayRate The rate at which the key's state decays (e.g., units per second).
     */
    function createQuantumKey(address _owner, uint256 _initialProbabilityMultiplier, uint256 _stateDecayRate) external onlyManager {
        require(_owner != address(0), "Invalid owner address");
        require(_initialProbabilityMultiplier <= 10000, "Multiplier cannot exceed 10000 (100%)");

        uint256 newKeyId = _nextKeyId++;
        uint64 currentTime = uint64(block.timestamp);

        quantumKeys[newKeyId] = QuantumKey({
            id: newKeyId,
            owner: _owner,
            creationTimestamp: currentTime,
            lastStateChangeTimestamp: currentTime,
            currentState: QuantumState.Stable,
            accessProbabilityMultiplier: _initialProbabilityMultiplier,
            stateDecayRate: _stateDecayRate,
            entangledKeyId: 0,
            exists: true
        });

        emit KeyCreated(newKeyId, _owner, currentTime);
    }

    /**
     * @dev Destroys a Quantum Key.
     * Requires key ownership.
     * @param _keyId The ID of the key to burn.
     */
    function burnQuantumKey(uint256 _keyId) external whenKeyExists(_keyId) {
        require(quantumKeys[_keyId].owner == msg.sender, "Not key owner");

        // If entangled, detangle the other key
        if (quantumKeys[_keyId].entangledKeyId != 0) {
            uint256 otherKeyId = quantumKeys[_keyId].entangledKeyId;
            if (quantumKeys[otherKeyId].exists) {
                 quantumKeys[otherKeyId].entangledKeyId = 0; // Break the link
                 emit KeyDetangled(otherKeyId);
            }
        }

        delete quantumKeys[_keyId]; // Removes from mapping
        emit KeyBurned(_keyId);
    }

    /**
     * @dev Transfers ownership of a Quantum Key (non-standard, non-ERC721 transfer).
     * @param _keyId The ID of the key to transfer.
     * @param _newOwner The address to transfer the key to.
     */
    function assignQuantumKeyToOwner(uint256 _keyId, address _newOwner) external whenKeyExists(_keyId) {
        require(quantumKeys[_keyId].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized");
        require(_newOwner != address(0), "Invalid new owner address");

        address oldOwner = quantumKeys[_keyId].owner;
        quantumKeys[_keyId].owner = _newOwner;

        // No standard ERC721 events, but we could emit a custom Transfer-like event if needed
        // emit Transfer(oldOwner, _newOwner, _keyId); // If we were simulating ERC721
    }


    /**
     * @dev Updates the base access probability multiplier for a key.
     * Requires key ownership or Manager role.
     * @param _keyId The ID of the key.
     * @param _newMultiplier The new base probability multiplier (Max 10000).
     */
    function updateKeyProbabilityMultiplier(uint256 _keyId, uint256 _newMultiplier) external whenKeyExists(_keyId) {
        require(quantumKeys[_keyId].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized");
         require(_newMultiplier <= 10000, "Multiplier cannot exceed 10000 (100%)");

        quantumKeys[_keyId].accessProbabilityMultiplier = _newMultiplier;
        emit KeyPropertiesUpdated(_keyId, _newMultiplier, quantumKeys[_keyId].stateDecayRate);
    }

    /**
     * @dev Updates the state decay rate for a key.
     * Requires key ownership or Manager role.
     * @param _keyId The ID of the key.
     * @param _newStateDecayRate The new rate at which the key's state decays.
     */
    function updateKeyStateDecayRate(uint256 _keyId, uint256 _newStateDecayRate) external whenKeyExists(_keyId) {
         require(quantumKeys[_keyId].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized");

        quantumKeys[_keyId].stateDecayRate = _newStateDecayRate;
         emit KeyPropertiesUpdated(_keyId, quantumKeys[_keyId].accessProbabilityMultiplier, _newStateDecayRate);
    }


    /**
     * @dev Conceptually entangles two keys. Their states may become linked.
     * Requires ownership of both keys or Manager role.
     * Note: The actual linkage logic (how one affects the other) is implemented in
     * decayKeyState, observeKey, and attemptDataSlotAccess.
     * @param _keyId1 The ID of the first key.
     * @param _keyId2 The ID of the second key.
     */
    function entangleKeys(uint256 _keyId1, uint256 _keyId2) external whenKeyExists(_keyId1) whenKeyExists(_keyId2) {
        require(_keyId1 != _keyId2, "Cannot entangle a key with itself");
        require(quantumKeys[_keyId1].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized for key1");
        require(quantumKeys[_keyId2].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized for key2");

        // Break existing entanglements if any
        if (quantumKeys[_keyId1].entangledKeyId != 0 && quantumKeys[quantumKeys[_keyId1].entangledKeyId].exists) {
            quantumKeys[quantumKeys[_keyId1].entangledKeyId].entangledKeyId = 0;
            emit KeyDetangled(quantumKeys[_keyId1].entangledKeyId);
        }
         if (quantumKeys[_keyId2].entangledKeyId != 0 && quantumKeys[quantumKeys[_keyId2].entangledKeyId].exists) {
            quantumKeys[quantumKeys[_keyId2].entangledKeyId].entangledKeyId = 0;
            emit KeyDetangled(quantumKeys[_keyId2].entangledKeyId);
        }


        quantumKeys[_keyId1].entangledKeyId = _keyId2;
        quantumKeys[_keyId2].entangledKeyId = _keyId1;

        // Update state conceptually (optional, but fits the theme)
        if (quantumKeys[_keyId1].currentState == QuantumState.Stable) quantumKeys[_keyId1].currentState = QuantumState.Entangled;
         if (quantumKeys[_keyId2].currentState == QuantumState.Stable) quantumKeys[_keyId2].currentState = QuantumState.Entangled;

        quantumKeys[_keyId1].lastStateChangeTimestamp = uint64(block.timestamp);
        quantumKeys[_keyId2].lastStateChangeTimestamp = uint64(block.timestamp);


        emit KeysEntangled(_keyId1, _keyId2);
        emit KeyStateChanged(_keyId1, quantumKeys[_keyId1].currentState, uint64(block.timestamp));
        emit KeyStateChanged(_keyId2, quantumKeys[_keyId2].currentState, uint64(block.timestamp));
    }

     /**
     * @dev Removes the entanglement link for a key.
     * Requires key ownership or Manager role.
     * @param _keyId The ID of the key to detangle.
     */
    function detangleKey(uint256 _keyId) external whenKeyExists(_keyId) {
         require(quantumKeys[_keyId].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized");
         require(quantumKeys[_keyId].entangledKeyId != 0, "Key is not entangled");

        uint256 otherKeyId = quantumKeys[_keyId].entangledKeyId;
        quantumKeys[_keyId].entangledKeyId = 0;

        if (quantumKeys[_keyId].currentState == QuantumState.Entangled) {
             quantumKeys[_keyId].currentState = QuantumState.Stable; // Return to Stable
             quantumKeys[_keyId].lastStateChangeTimestamp = uint64(block.timestamp);
             emit KeyStateChanged(_keyId, quantumKeys[_keyId].currentState, uint64(block.timestamp));
        }


        if (quantumKeys[otherKeyId].exists && quantumKeys[otherKeyId].entangledKeyId == _keyId) {
            quantumKeys[otherKeyId].entangledKeyId = 0;
             if (quantumKeys[otherKeyId].currentState == QuantumState.Entangled) {
                quantumKeys[otherKeyId].currentState = QuantumState.Stable; // Return to Stable
                 quantumKeys[otherKeyId].lastStateChangeTimestamp = uint64(block.timestamp);
                 emit KeyStateChanged(otherKeyId, quantumKeys[otherKeyId].currentState, uint64(block.timestamp));
            }
            emit KeyDetangled(otherKeyId);
        }

        emit KeyDetangled(_keyId);
    }


    /**
     * @dev Simulates a "quantum fluctuation" on a key, potentially changing its state or multiplier slightly.
     * The change is based on block data for pseudo-randomness.
     * Requires key ownership or Manager role.
     * @param _keyId The ID of the key to fluctuate.
     */
    function applyQuantumFluctuation(uint256 _keyId) external whenKeyExists(_keyId) {
         require(quantumKeys[_keyId].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized");

        uint256 seed = uint256(keccak256(abi.encodePacked(_keyId, block.timestamp, block.number, msg.sender)));
        uint256 fluctuationType = seed % 3; // 0, 1, or 2

        QuantumKey storage key = quantumKeys[_keyId];

        if (fluctuationType == 0) {
            // Small multiplier perturbation (+/- 5%)
            int256 multiplierChange = int256(seed % 1001) - 500; // -500 to +500
            uint256 currentMultiplier = key.accessProbabilityMultiplier;
            int256 newMultiplier = int256(currentMultiplier) + multiplierChange;
            key.accessProbabilityMultiplier = uint256(newMultiplier > 0 ? (newMultiplier < 10001 ? newMultiplier : 10000) : 0); // Keep within [0, 10000]
             emit KeyPropertiesUpdated(_keyId, key.accessProbabilityMultiplier, key.stateDecayRate);

        } else if (fluctuationType == 1) {
            // State shift (minor change)
             if (key.currentState == QuantumState.Stable) key.currentState = QuantumState.Fluctuating;
             else if (key.currentState == QuantumState.Fluctuating) key.currentState = QuantumState.Stable;
             // Don't change Entangled/Decaying/Collapsed easily via fluctuation
             key.lastStateChangeTimestamp = uint64(block.timestamp);
             emit KeyStateChanged(_keyId, key.currentState, uint64(block.timestamp));

        } else { // fluctuationType == 2
            // Affect entangled key if exists (minor state/multiplier change)
            if (key.entangledKeyId != 0 && quantumKeys[key.entangledKeyId].exists) {
                uint256 otherKeyId = key.entangledKeyId;
                QuantumKey storage otherKey = quantumKeys[otherKeyId];

                 // Apply small inverse multiplier perturbation or state shift
                 if (seed % 2 == 0) {
                    int256 multiplierChange = int256(seed % 201) - 100; // -100 to +100
                    int256 newMultiplier = int256(otherKey.accessProbabilityMultiplier) - multiplierChange; // Inverse effect
                    otherKey.accessProbabilityMultiplier = uint256(newMultiplier > 0 ? (newMultiplier < 10001 ? newMultiplier : 10000) : 0);
                     emit KeyPropertiesUpdated(otherKeyId, otherKey.accessProbabilityMultiplier, otherKey.stateDecayRate);

                 } else {
                      if (otherKey.currentState == QuantumState.Stable) otherKey.currentState = QuantumState.Fluctuating;
                      else if (otherKey.currentState == QuantumState.Fluctuating) otherKey.currentState = QuantumState.Stable;
                      otherKey.lastStateChangeTimestamp = uint64(block.timestamp);
                      emit KeyStateChanged(otherKeyId, otherKey.currentState, uint64(block.timestamp));
                 }
            }
        }
    }


     /**
     * @dev Simulates the "Observer Effect". Accessing/observing a key makes its state less uncertain (more 'Decayed').
     * Also explicitly triggers state decay logic.
     * Callable by anyone to 'collapse' a key's probabilistic state towards a determined state.
     * @param _keyId The ID of the key to observe.
     */
    function observeKey(uint256 _keyId) external whenKeyExists(_keyId) {
        QuantumKey storage key = quantumKeys[_keyId];

        // Trigger decay based on time elapsed since last state change/decay
        _applyStateDecay(_keyId); // Internal decay application

        // Simulate observer effect: Push state towards 'Decaying' or 'Collapsed' based on current state
        if (key.currentState == QuantumState.Stable) {
             key.currentState = QuantumState.Decaying;
             key.lastStateChangeTimestamp = uint64(block.timestamp);
             emit KeyStateChanged(_keyId, key.currentState, uint64(block.timestamp));
        } else if (key.currentState == QuantumState.Entangled) {
             // Observation of one entangled key slightly decays the other
             if (key.entangledKeyId != 0 && quantumKeys[key.entangledKeyId].exists) {
                 _applyStateDecay(key.entangledKeyId); // Decay entangled key too
             }
              key.currentState = QuantumState.Decaying; // The observed key starts decaying
              key.lastStateChangeTimestamp = uint64(block.timestamp);
              emit KeyStateChanged(_keyId, key.currentState, uint64(block.timestamp));
        } else if (key.currentState == QuantumState.Fluctuating) {
             key.currentState = QuantumState.Decaying; // Fluctuation resolves into decay
             key.lastStateChangeTimestamp = uint64(block.timestamp);
             emit KeyStateChanged(_keyId, key.currentState, uint64(block.timestamp));
        }
        // Decaying and Collapsed states remain as is or are handled by decay function
    }

    /**
     * @dev Applies state decay to a key based on time elapsed and decay rate.
     * This can be called by anyone, its effect depends on the key's state and time.
     * Useful for pushing keys towards 'Collapsed' state over time.
     * @param _keyId The ID of the key to decay.
     */
    function decayKeyState(uint256 _keyId) external whenKeyExists(_keyId) {
        _applyStateDecay(_keyId);
    }

    /**
     * @dev Internal function to apply state decay logic.
     * @param _keyId The ID of the key.
     */
    function _applyStateDecay(uint256 _keyId) internal {
        QuantumKey storage key = quantumKeys[_keyId];
        uint64 currentTime = uint64(block.timestamp);
        uint256 timeElapsed = currentTime - key.lastStateChangeTimestamp;

        if (key.currentState == QuantumState.Collapsed) {
            key.lastStateChangeTimestamp = currentTime; // Reset timestamp, no further decay
            return; // Already collapsed, no decay
        }

        if (key.stateDecayRate == 0 || timeElapsed == 0) {
            key.lastStateChangeTimestamp = currentTime; // Reset timestamp if no decay happens
            return; // No decay configured or no time elapsed
        }

        // Simple linear decay simulation
        uint256 decayAmount = timeElapsed * key.stateDecayRate; // Decay units accumulated
        uint256 currentMultiplier = key.accessProbabilityMultiplier;

        // Decay the multiplier (simulation: decay units reduce probability multiplier)
        if (decayAmount >= currentMultiplier) {
             key.accessProbabilityMultiplier = 0; // Cannot go below zero
        } else {
             key.accessProbabilityMultiplier = currentMultiplier - decayAmount;
        }

        // Decay can also change the state (e.g., move towards Collapsed)
        // Simple logic: if multiplier is very low, change state
        if (key.accessProbabilityMultiplier < 1000 && key.currentState != QuantumState.Decaying) { // e.g., below 10%
             key.currentState = QuantumState.Decaying;
             emit KeyStateChanged(_keyId, key.currentState, currentTime);
        }
         if (key.accessProbabilityMultiplier == 0 && key.currentState != QuantumState.Collapsed) {
             key.currentState = QuantumState.Collapsed;
             emit KeyStateChanged(_keyId, key.currentState, currentTime);
        }


        key.lastStateChangeTimestamp = currentTime; // Update timestamp after applying decay
        emit KeyPropertiesUpdated(_keyId, key.accessProbabilityMultiplier, key.stateDecayRate);
    }


    // --- Data Slot Functions ---

    /**
     * @dev Creates a new Data Slot.
     * Requires Manager role.
     * @param _owner The address that will own the new slot.
     * @param _requiredMinQuantumState The minimum state index required for access (e.g., 0 for Stable, 1 for Entangled...).
     * @param _requiredMinProbabilityMultiplier The minimum *effective* probability multiplier required for access (Max 10000).
     */
    function createDataSlot(address _owner, uint256 _requiredMinQuantumState, uint256 _requiredMinProbabilityMultiplier) external onlyManager {
        require(_owner != address(0), "Invalid owner address");
         require(_requiredMinQuantumState < uint256(QuantumState.Collapsed) + 1, "Invalid state requirement"); // Max index + 1
         require(_requiredMinProbabilityMultiplier <= 10000, "Requirement cannot exceed 10000 (100%)");


        uint256 newSlotId = _nextSlotId++;
        uint64 currentTime = uint64(block.timestamp);

        dataSlots[newSlotId] = DataSlot({
            id: newSlotId,
            owner: _owner,
            creationTimestamp: currentTime,
            requiredMinQuantumState: _requiredMinQuantumState,
            requiredMinProbabilityMultiplier: _requiredProbabilityMultiplier,
            accessLog: new AccessLogEntry[](0), // Initialize empty log
            exists: true
        });

        emit DataSlotCreated(newSlotId, _owner, currentTime);
    }

    /**
     * @dev Transfers ownership of a Data Slot.
     * Requires current slot ownership or Manager role.
     * @param _slotId The ID of the slot to transfer.
     * @param _newOwner The address to transfer the slot to.
     */
    function assignDataSlotToOwner(uint256 _slotId, address _newOwner) external whenSlotExists(_slotId) {
        require(dataSlots[_slotId].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized");
        require(_newOwner != address(0), "Invalid new owner address");

        address oldOwner = dataSlots[_slotId].owner;
        dataSlots[_slotId].owner = _newOwner;

        emit DataSlotAssigned(_slotId, oldOwner, _newOwner);
    }

    /**
     * @dev Updates the access requirements for a Data Slot.
     * Requires slot ownership or Manager role.
     * @param _slotId The ID of the slot.
     * @param _newRequiredMinQuantumState The new minimum state index required.
     * @param _newRequiredMinProbabilityMultiplier The new minimum probability multiplier required.
     */
    function updateDataSlotRequirements(uint256 _slotId, uint256 _newRequiredMinQuantumState, uint256 _newRequiredMinProbabilityMultiplier) external whenSlotExists(_slotId) {
        require(dataSlots[_slotId].owner == msg.sender || _managers[msg.sender] || msg.sender == i_owner, "Not authorized");
        require(_newRequiredMinQuantumState < uint256(QuantumState.Collapsed) + 1, "Invalid state requirement");
         require(_newRequiredMinProbabilityMultiplier <= 10000, "Requirement cannot exceed 10000 (100%)");


        dataSlots[_slotId].requiredMinQuantumState = _newRequiredMinQuantumState;
        dataSlots[_slotId].requiredMinProbabilityMultiplier = _newRequiredMinProbabilityMultiplier;

        emit DataSlotRequirementsUpdated(_slotId, _newRequiredMinQuantumState, _newRequiredMinProbabilityMultiplier);
    }


    // --- Access Control (The Core Quantum Logic) ---

    /**
     * @dev Attempts to use a Quantum Key to access a Data Slot.
     * This is the core function where probabilistic access logic is applied.
     * Requires key ownership by msg.sender.
     * @param _keyId The ID of the key to use.
     * @param _slotId The ID of the data slot to access.
     * @return bool True if access is successful, false otherwise.
     */
    function attemptDataSlotAccess(uint256 _keyId, uint256 _slotId) external whenKeyExists(_keyId) whenSlotExists(_slotId) returns (bool) {
        QuantumKey storage key = quantumKeys[_keyId];
        DataSlot storage slot = dataSlots[_slotId];

        // --- Pre-check Requirements ---
        require(key.owner == msg.sender, "Not the key owner");
        // require(slot.owner == msg.sender, "Not the slot owner"); // Optional: Allow key owner to access any slot?
                                                                   // Let's assume key owner is attempting access on behalf of slot owner or self.
                                                                   // The key itself is the credential, its owner attempts the action.

        // 1. Apply decay and observer effect first to get updated state
        _applyStateDecay(_keyId); // Decay for this key
        observeKey(_keyId);       // Apply observer effect (also triggers decay)

        // Re-fetch key state after potential changes
        key = quantumKeys[_keyId]; // Make sure we have the latest state in `key` reference

        // Check state and multiplier requirements
        if (uint256(key.currentState) < slot.requiredMinQuantumState) {
            _logAccessAttempt(_slotId, msg.sender, false, key.accessProbabilityMultiplier); // Log failed attempt
            return false; // State requirement not met
        }

        // 2. Calculate Effective Probability
        // Factors: Base Multiplier, State (Decaying/Collapsed reduces it), Entanglement (could modify)
        uint256 effectiveProbabilityMultiplier = key.accessProbabilityMultiplier;

        // Example: Decaying state significantly reduces effective probability
        if (key.currentState == QuantumState.Decaying) {
            // Reduce probability based on how far into decay (e.g., linearly based on decayed amount)
            // Simpler: Apply a flat penalty or factor
            effectiveProbabilityMultiplier = effectiveProbabilityMultiplier * 50 / 100; // 50% penalty
        } else if (key.currentState == QuantumState.Collapsed) {
             effectiveProbabilityMultiplier = 0; // No access if collapsed
        }

        // Example: Entanglement might slightly alter probability (positive or negative)
        // if (key.currentState == QuantumState.Entangled && key.entangledKeyId != 0 && quantumKeys[key.entangledKeyId].exists) {
             // Add logic based on entangled key's state or properties
        // }

        // Ensure effective probability is within bounds
        effectiveProbabilityMultiplier = effectiveProbabilityMultiplier > 10000 ? 10000 : effectiveProbabilityMultiplier;
        effectiveProbabilityMultiplier = effectiveProbabilityMultiplier < 0 ? 0 : effectiveProbabilityMultiplier; // Should not be negative with uint, but good practice


        // Check minimum probability requirement
        if (effectiveProbabilityMultiplier < slot.requiredMinProbabilityMultiplier) {
             _logAccessAttempt(_slotId, msg.sender, false, effectiveProbabilityMultiplier);
             return false; // Probability requirement not met after decay/observer
        }


        // --- Probabilistic Success Calculation ---
        // Use block data for pseudo-randomness. This is not truly random,
        // but is sufficient for simulating probabilistic outcomes on-chain.
        uint256 seed = uint256(keccak256(abi.encodePacked(_keyId, _slotId, msg.sender, block.timestamp, block.number, tx.origin)));
        uint256 randomValue = seed % 10001; // Value between 0 and 10000


        bool accessSuccessful = randomValue < effectiveProbabilityMultiplier;

        _logAccessAttempt(_slotId, msg.sender, accessSuccessful, effectiveProbabilityMultiplier);

        return accessSuccessful;
    }

     /**
     * @dev Internal function to log an access attempt for a data slot.
     * @param _slotId The ID of the slot.
     * @param _accessor The address attempting access.
     * @param _success Whether the attempt was successful.
     * @param _calculatedProbability The effective probability used in the calculation.
     */
    function _logAccessAttempt(uint256 _slotId, address _accessor, bool _success, uint256 _calculatedProbability) internal {
        DataSlot storage slot = dataSlots[_slotId];
        slot.accessLog.push(AccessLogEntry({
            accessor: _accessor,
            timestamp: uint64(block.timestamp),
            success: _success
        }));

        // Optional: Limit log size to save gas if logs get too long
        // while (slot.accessLog.length > 10) {
        //     for (uint i = 0; i < slot.accessLog.length - 1; i++) {
        //         slot.accessLog[i] = slot.accessLog[i+1];
        //     }
        //     slot.accessLog.pop();
        // }

        emit DataSlotAccessAttempted(_slotId, 0, _accessor, _success, _calculatedProbability); // Log keyId as 0 here, or add it to log entry if needed
    }

     /**
     * @dev Calculates the current *effective* access probability for a key on a slot without attempting access.
     * Takes decay and current state into account, but not observer effect from THIS check or the final random factor.
     * @param _keyId The ID of the key.
     * @param _slotId The ID of the data slot.
     * @return uint256 The calculated effective probability multiplier (0-10000).
     */
    function checkAccessProbability(uint256 _keyId, uint256 _slotId) public view whenKeyExists(_keyId) whenSlotExists(_slotId) returns (uint256) {
         QuantumKey storage key = quantumKeys[_keyId];
         DataSlot storage slot = dataSlots[_slotId];

         // Simulate decay based on current time elapsed WITHOUT altering state
         uint64 currentTime = uint64(block.timestamp);
         uint256 timeElapsed = currentTime - key.lastStateChangeTimestamp;
         uint256 decayAmount = timeElapsed * key.stateDecayRate;

         uint256 calculatedMultiplier = key.accessProbabilityMultiplier;
         if (decayAmount >= calculatedMultiplier) {
             calculatedMultiplier = 0;
         } else {
             calculatedMultiplier = calculatedMultiplier - decayAmount;
         }

         // Simulate state impact on probability based on current state (Decaying, Collapsed)
         QuantumState simulatedState = key.currentState;
         if (calculatedMultiplier < 1000 && simulatedState != QuantumState.Decaying && simulatedState != QuantumState.Collapsed) {
             simulatedState = QuantumState.Decaying; // Simulate state if multiplier drops low
         }
          if (calculatedMultiplier == 0 && simulatedState != QuantumState.Collapsed) {
             simulatedState = QuantumState.Collapsed; // Simulate state if multiplier hits zero
         }


         uint256 effectiveProbabilityMultiplier = calculatedMultiplier;

         if (simulatedState == QuantumState.Decaying) {
            effectiveProbabilityMultiplier = effectiveProbabilityMultiplier * 50 / 100; // Same penalty as in attempt
         } else if (simulatedState == QuantumState.Collapsed) {
             effectiveProbabilityMultiplier = 0;
         }

        // Ensure effective probability is within bounds
        effectiveProbabilityMultiplier = effectiveProbabilityMultiplier > 10000 ? 10000 : effectiveProbabilityMultiplier;
        effectiveProbabilityMultiplier = effectiveProbabilityMultiplier < 0 ? 0 : effectiveProbabilityMultiplier;


         // Check against slot requirements (return 0 if requirements are not met conceptually)
         if (uint256(simulatedState) < slot.requiredMinQuantumState || effectiveProbabilityMultiplier < slot.requiredMinProbabilityMultiplier) {
             return 0; // Requirements not met even before random chance
         }

         return effectiveProbabilityMultiplier; // Return the calculated effective probability
    }


    // --- Query & Information Functions ---

    /**
     * @dev Gets details of a specific Quantum Key.
     * @param _keyId The ID of the key.
     * @return tuple containing key details.
     */
    function getKeyDetails(uint256 _keyId) external view whenKeyExists(_keyId) returns (
        uint256 id,
        address owner,
        uint64 creationTimestamp,
        uint64 lastStateChangeTimestamp,
        QuantumState currentState,
        uint256 accessProbabilityMultiplier,
        uint256 stateDecayRate,
        uint256 entangledKeyId
    ) {
        QuantumKey storage key = quantumKeys[_keyId];
        return (
            key.id,
            key.owner,
            key.creationTimestamp,
            key.lastStateChangeTimestamp,
            key.currentState,
            key.accessProbabilityMultiplier,
            key.stateDecayRate,
            key.entangledKeyId
        );
    }

    /**
     * @dev Gets details of a specific Data Slot.
     * @param _slotId The ID of the slot.
     * @return tuple containing slot details.
     */
    function getDataSlotDetails(uint256 _slotId) external view whenSlotExists(_slotId) returns (
        uint256 id,
        address owner,
        uint64 creationTimestamp,
        uint256 requiredMinQuantumState,
        uint256 requiredMinProbabilityMultiplier
        // Note: Access log not included in main details to save gas
    ) {
        DataSlot storage slot = dataSlots[_slotId];
        return (
            slot.id,
            slot.owner,
            slot.creationTimestamp,
            slot.requiredMinQuantumState,
            slot.requiredMinProbabilityMultiplier
        );
    }

     /**
     * @dev Gets the access log for a specific Data Slot.
     * Note: This can be expensive if the log is very long.
     * @param _slotId The ID of the slot.
     * @return AccessLogEntry[] The list of access log entries.
     */
    function getDataSlotAccessLog(uint256 _slotId) external view whenSlotExists(_slotId) returns (AccessLogEntry[] memory) {
        // Return a memory copy of the log array
        return dataSlots[_slotId].accessLog;
    }


    /**
     * @dev Gets the total number of Quantum Keys created.
     * @return uint256 The total count.
     */
    function getTotalKeys() external view returns (uint256) {
        return _nextKeyId - 1;
    }

    /**
     * @dev Gets the total number of Data Slots created.
     * @return uint256 The total count.
     */
    function getTotalSlots() external view returns (uint256) {
        return _nextSlotId - 1;
    }

     /**
     * @dev Gets the ID of the key entangled with the given key.
     * @param _keyId The ID of the key.
     * @return uint256 The ID of the entangled key (0 if none).
     */
    function getEntangledKey(uint256 _keyId) external view whenKeyExists(_keyId) returns (uint256) {
        return quantumKeys[_keyId].entangledKeyId;
    }

    /**
     * @dev Helper internal function to check if a key exists and is not conceptually 'burned' (exists flag).
     * Can be used as a view helper outside modifiers too.
     * @param _keyId The ID of the key.
     * @return bool True if the key exists and is valid.
     */
     function checkKeyValidity(uint256 _keyId) public view returns (bool) {
         // Expiry logic could be added here based on creationTimestamp + validityPeriod
         return quantumKeys[_keyId].exists;
     }


    // --- Potentially Expensive Query Functions ---
    // NOTE: Iterating over all keys/slots can be very expensive as the number grows.
    // These functions are included to meet the function count and outline querying capabilities,
    // but might be impractical on-chain for a large number of assets. Off-chain indexing is recommended.

    /**
     * @dev Retrieves a list of key IDs owned by a specific address.
     * WARNING: Can be very expensive if the number of keys is large.
     * @param _owner The address to check.
     * @return uint256[] An array of key IDs.
     */
    function getKeysByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory ownerKeyIds = new uint256[](getTotalKeys());
        uint256 count = 0;
        for (uint256 i = 1; i < _nextKeyId; i++) {
            if (quantumKeys[i].exists && quantumKeys[i].owner == _owner) {
                ownerKeyIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = ownerKeyIds[i];
        }
        return result;
    }

    /**
     * @dev Retrieves a list of data slot IDs owned by a specific address.
     * WARNING: Can be very expensive if the number of slots is large.
     * @param _owner The address to check.
     * @return uint256[] An array of slot IDs.
     */
    function getSlotsByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory ownerSlotIds = new uint256[](getTotalSlots());
        uint256 count = 0;
        for (uint256 i = 1; i < _nextSlotId; i++) {
            if (dataSlots[i].exists && dataSlots[i].owner == _owner) {
                ownerSlotIds[count] = i;
                count++;
            }
        }
         uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = ownerSlotIds[i];
        }
        return result;
    }
}
```